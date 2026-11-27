---
ma_tai_lieu: D03-04-PH01
ten: Đặc tả API và sự kiện phân hệ PH-01 Kết nạp hệ thống thông tin
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, giao diện, kỹ sư các phân hệ gọi PH-01; ATTT; kiểm thử viên; hội đồng thẩm định
phan_he: PH-01
mo_ta: Đặc tả 88 endpoint REST, 15 sự kiện Kafka và 54 mã lỗi ERR-01 của phân hệ Kết nạp hệ thống thông tin, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH01 FRS; D02-04-PH01 Use case; D03-02-PH01 SDD; D03-03-PH01 CSDL; D03-06-PH01 Màn hình; D04-01 Quy ước mã
---

# D03-04-PH01 · Đặc tả API và sự kiện Kết nạp hệ thống thông tin

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-01 là cửa vào của mọi hệ thống thông tin (HTTT) muốn dùng Datahub: đơn vị nộp hồ sơ, tỉnh thẩm định và phê duyệt, hệ thống cấp danh tính kỹ thuật, bàn giao bí mật một lần, rồi quản lý vòng đời thành viên đến khi chấm dứt. Tài liệu này chốt hợp đồng giao tiếp của phân hệ để kỹ sư giao diện, kỹ sư các phân hệ khác và kiểm thử viên làm việc song song mà không phải đọc mã.

**Phạm vi.** Phân hệ công bố 88 operation REST (API-01-001…088) dưới `/api/onboarding/v1`, 15 sự kiện Kafka (EVT-01-01…15) và 54 mã lỗi (ERR-01-001…054). 51 chức năng của [FRS](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) đều có API (không chức năng nào "chỉ giao diện"). Danh sách 86 API, 15 sự kiện và 50 mã lỗi đã chốt ở FRS §9; tập này thêm hai API (087 nhận kết quả bất đồng bộ của saga, 088 tra tác vụ nền xuất tệp) và bốn mã lỗi dùng chung (051…054), ghi ở chương 11.

**Hợp đồng máy đọc được.**

- [`ph01/openapi-onboarding.yaml`](ph01/openapi-onboarding.yaml): OpenAPI 3.1, 88 operation, 77 đường dẫn, 152 lược đồ; đã qua `openapi-spec-validator` và Spectral (bộ `spectral:oas`, 0 lỗi, 0 cảnh báo); 217 ví dụ đã kiểm khớp lược đồ bằng [`check_contracts.py`](ph01/tools/check_contracts.py).
- [`ph01/asyncapi-onboarding.yaml`](ph01/asyncapi-onboarding.yaml): AsyncAPI 3.0, 15 kênh, 30 operation (gửi, nhận); đã qua `@asyncapi/parser` 3, không lỗi, không cảnh báo (chỉ một gợi ý nâng lên bản 3.1).

Cả hai sinh từ bảng mã [`ph01/tools/spec.py`](ph01/tools/spec.py) bằng `gen_openapi.py`, `gen_asyncapi.py`; các bảng ở chương 2, 3, 4, 6 của tài liệu này sinh bằng `gen_md.py`; chương 10 sinh bằng `build/tools/sinh_dac_ta_api.py`. Vì thế bảng, ví dụ và đặc tả không lệch với hợp đồng.

**Căn cứ.** Yêu cầu: D02-03-PH01 (FRS), D02-04-PH01 (use case), D02-08 (quyền PERM-01). Thiết kế: D03-02-PH01 (SDD) và D03-03-PH01 (CSDL). An toàn: SEC-23, 24, 25, 26, 27, 32, 33, 43, 45, 60, 80 (D03-07). Quyết định kiến trúc: ADR-005 (APISIX), ADR-006 (Keycloak, OPA), ADR-012 (OpenBao), ADR-041 (lũy đẳng 24 giờ), ADR-042 (outbox), ADR-030 (cấp độ 3 sẵn sàng cấp độ 4). Pháp lý: Luật BVDLCN 91/2025 và NĐ 356/2025 (dữ liệu liên hệ của đầu mối), NĐ 278/2025 (đầu mối kết nối, chia sẻ dữ liệu), Luật ANM 116/2025, TCVN 14423:2026 (xác thực hai yếu tố, khóa phiên 15 phút).

**Năm nguyên tắc hợp đồng.**

1. **Chỉ một API trả giá trị bí mật.** API-01-040 (mở liên kết bàn giao) là nơi duy nhất `clientSecret` xuất hiện, một lần, kèm `Cache-Control: no-store`, chỉ cho đúng đầu mối đã xác thực hai yếu tố. Kiểm tra hợp đồng chặn trường bí mật ở mọi lược đồ khác, kể cả sự kiện.
2. **Người dùng và phân hệ khác dùng hai đường tách nhau.** Người dùng đi qua BFF với `PERM-01-*`, `PERM-18-*`; phân hệ khác dùng token dịch vụ với ba scope `onboarding:internal-read`, `onboarding:provision-callback`, `onboarding:reconcile` (4 API `/internal/*`), không dùng token của người.
3. **Sửa và đổi trạng thái hồ sơ, định danh đều có `If-Match`** (21 API, trong đó 3 thao tác khẩn của Cán bộ ATTT để tùy chọn) và **lệnh tạo, lệnh có tác dụng phụ đều có `Idempotency-Key`** (19 API; riêng mở bàn giao không dùng vì mã chỉ mở được một lần).
4. **Không lộ đối tượng ngoài phạm vi.** Đối tượng thuộc tenant khác hoặc ngoài phạm vi vai trò trả cùng một thân `404` (ERR-01-001) như đối tượng không tồn tại; liên kết đã dùng, hết hạn hay bị hủy trả cùng một thân `410`.
5. **Hiệu lực cắt quyền nhìn thấy được.** Lệnh thu hồi, tạm ngừng trả `enforcement` (`PENDING` rồi `DONE`) và phát EVT-01-03, EVT-01-07 qua outbox; mục tiêu cổng API từ chối HTTT trong ≤ 60 giây (NFR-01-008).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Operation REST | 88 (GET 33, POST 46, PUT 4, PATCH 2, DELETE 3) |
| Operation cho người dùng, cho phân hệ khác | 84, 4 |
| Chức năng FRS được phủ | 51 trên 51 |
| Sự kiện Kafka | 15 (3 phân vùng, giữ 7 ngày) |
| Mã lỗi | 54 (50 theo FRS, 4 do tập này thêm) |
| Lệnh có `Idempotency-Key`, có `If-Match` | 19, 21 |
| Câu hỏi mở | 5 (Q01-55…Q01-59) |

: Con số chính của hợp đồng API và sự kiện PH-01

**Những điểm hội đồng cần lưu ý.** (1) Hai API và bốn mã lỗi mới nằm ngoài danh sách đã chốt ở FRS nên cần FRS, UC đồng bộ ở đợt cuối (chương 11). (2) Cơ chế callback bất đồng bộ của saga (API-01-087) phụ thuộc quyết định của PH-12, PH-03 (Q01-56); mặc định tắt bằng cờ `onboarding.saga.async-callback`. (3) Hạn mức tốc độ gọi ở chương 1 là giả định có cơ sở, chốt ở D03-09. (4) Tên topic của ba loại sự kiện PH-01 tiêu thụ do phân hệ phát chốt (Q01-13 của FRS), nên tệp AsyncAPI chưa có kênh nhận cho chúng.

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả giao diện lập trình của PH-01 ở mặt phẳng điều khiển: các endpoint REST cho giao diện và cho phân hệ khác, các sự kiện Kafka, hợp đồng với phân hệ và hệ ngoài, bảng mã lỗi `ERR-01`. Nguồn chuẩn là hai tệp máy đọc được [`openapi-onboarding.yaml`](ph01/openapi-onboarding.yaml) và [`asyncapi-onboarding.yaml`](ph01/asyncapi-onboarding.yaml); bảng danh mục ở chương 3 và đặc tả từng endpoint ở chương 10 (mỗi endpoint một bảng 10 mục) đều sinh từ OpenAPI.

### 0.2. Phạm vi

Trong phạm vi: 88 operation của module `onboarding` trong `dh-connect`, 15 sự kiện EVT-01, mã lỗi ERR-01-001…054, giao diện PH-01 gọi sang phân hệ khác ở mức hợp đồng (chương 5). Ngoài phạm vi: API của PH-12, PH-03, OpenBao, PH-13, PH-14, PH-18, PH-20 (do tập của phân hệ đó đặc tả); đường dữ liệu nghiệp vụ của HTTT (PH-03, PH-04, PH-10); thiết kế bên trong (SDD) và bảng dữ liệu (CSDL).

### 0.3. Người đọc

Tài liệu có người đọc rất khác nhau: kỹ sư cần cả hợp đồng, kiểm thử viên cần mã lỗi và ví dụ, hội đồng thẩm định chỉ cần phần tổng quan. Bảng dưới chỉ ra chương nên đọc.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect`, kỹ sư giao diện | Chương 1, 2, 3, 6, 10 |
| Kỹ sư PH-02, 03, 04, 05, 10, 13, 14, 15 (bên gọi hoặc nghe PH-01) | Chương 4, 5 và API-01-062, 063, 064, 087 ở chương 10 |
| Kiểm thử viên | Chương 3, 6, 7, 10 |
| ATTT | Tóm tắt, chương 2 (xác thực lại, bí mật), chương 5 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 9 |

: Người đọc và phần cần đọc

### 0.4. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng chung theo D00-01 §2 và [FRS §1.4](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md). Riêng tài liệu này dùng thêm các thuật ngữ sau.

| Thuật ngữ | Nghĩa |
|---|---|
| HTTT thành viên | Hệ thống thông tin đã nộp hồ sơ kết nạp vào tenant (DD-03); `systemCode` là mã bất biến |
| Lũy đẳng (idempotent) | Gửi lại cùng một yêu cầu cho cùng kết quả, không tạo thêm tác dụng phụ; thực hiện bằng `Idempotency-Key` |
| Khóa lạc quan | Chống ghi đè do hai người sửa cùng lúc; `ETag` là `version`, bên sửa gửi lại bằng `If-Match` |
| Saga | Quy trình nhiều bước có bước bù trừ khi lỗi, dùng khi cấp định danh ở PH-12, PH-03 |
| Bàn giao | Liên kết dùng một lần để đầu mối nhận thông tin xác thực; bí mật được OpenBao bọc phản hồi |
| Trần phạm vi | Giới hạn trên của dữ liệu HTTT được đăng ký sử dụng, sinh từ mục nhu cầu được duyệt |
| Token dịch vụ | Token OAuth `client_credentials` do phân hệ gọi PH-01, không phải của người |
| BFF | Lớp trung gian của giao diện (backend for frontend), giữ phiên và gửi token tới API |
| OPA | Open Policy Agent, bộ chính sách phân quyền mịn (phạm vi tổ chức, phân công) |
| RFC 9457 | Chuẩn thân lỗi `application/problem+json` |
| EVT, ERR, API | Mã sự kiện, mã lỗi, mã endpoint của PH-01 (D00-01 §3) |

: Thuật ngữ và chữ viết tắt

### 0.5. Tài liệu tham chiếu

[D02-03-PH01](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) (FRS, 51 chức năng, §9 chốt danh sách API, sự kiện, mã lỗi); [D02-04-PH01](../../02-yeu-cau/use-case/D02-04-PH01-use-case-ket-nap-httt.md) (34 use case); [D03-02-PH01](../sdd/D03-02-PH01-sdd-ket-nap-httt.md) (SDD: lũy đẳng §8.2, phân loại lỗi §8.4, saga §4.6, bàn giao §4.7); [D03-03-PH01](../csdl/D03-03-PH01-csdl-ket-nap-httt.md) (CSDL: enum, ràng buộc, topic §6.2); D03-06-PH01 (màn hình, thông báo lỗi §5.2); D02-08 (quyền PERM-01, PERM-18); D03-07 (SEC); D04-01 (quy ước mã, RFC 9457); mẫu đối chiếu [D03-04-PH05](D03-04-PH05-api-bo-dieu-hop.md).

### 0.6. Cấu trúc tài liệu

Tài liệu gồm mười một chương theo thứ tự người đọc cần: quy ước, quyền, danh mục, sự kiện, hợp đồng với bên khác, lỗi, kiểm tra, hệ cũ, câu hỏi, đặc tả chi tiết và đề nghị đồng bộ.

| Chương | Nội dung |
|---|---|
| 1 | Quy ước chung: đường gốc, phiên bản, phân trang, khóa lạc quan, lũy đẳng, lỗi |
| 2 | Xác thực và phân quyền: người dùng, token dịch vụ, xác thực lại hai yếu tố |
| 3 | Danh mục 88 endpoint, ví dụ yêu cầu và phản hồi, bảng use case → API |
| 4 | Danh mục 15 sự kiện, cấu trúc nội dung, chính sách tương thích |
| 5 | Hợp đồng với phân hệ khác và bên ngoài |
| 6 | Bảng mã lỗi ERR-01, thông điệp, trường bổ sung của thân lỗi |
| 7 | Kiểm tra hợp đồng trong CI |
| 8 | Ánh xạ từ hệ cũ |
| 9 | Câu hỏi mở |
| 10 | Đặc tả từng endpoint (sinh từ OpenAPI) |
| 11 | Đề nghị đồng bộ |

: Cấu trúc chương của D03-04-PH01

## 1. Quy ước chung

Chương này chốt những quy ước áp dụng cho mọi endpoint để chương 3 và chương 10 không phải lặp lại. Quy ước theo D04-01 và theo mẫu PH-05, PH-07, PH-19; chỗ PH-01 khác mẫu được ghi rõ.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/onboarding/v1`. Người dùng qua BFF console của tenant; phân hệ khác gọi `/internal/*` ở `dh-connect.dh-control.svc` (mTLS của mesh, `NetworkPolicy`) |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2` chạy song song ≥ 6 tháng. `oasdiff` ở CI-5 chặn thay đổi phá vỡ trong `v1`; `v1` chỉ thêm trường tùy chọn (NFR-01-019) |
| Tenant | Lấy từ token (claim `tenant`), không bao giờ từ đường dẫn hay thân; thân có `tenantId` khác tenant của token bị từ chối ở lớp lược đồ (FR-00-010) |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:submit`, `:approve`, `:suspend`, `:rotate`…) theo AIP-136 |
| Khóa lạc quan | `GET` đối tượng có phiên bản trả `ETag` là `version`; `PUT`, `PATCH`, `DELETE` và lệnh đổi trạng thái của hồ sơ, định danh bắt buộc `If-Match`; lệch trả ERR-01-007 (412) kèm `currentEtag`. Việc của người thẩm định, phân công, tham vấn, quyết định đề nghị, xác nhận khẩn và xuất tệp không cần vì ghi vào đối tượng con hoặc không đổi dữ liệu Thao tác khẩn (API-01-047, 051, 054) để `If-Match` tùy chọn để Cán bộ ATTT không bị chặn bởi bản ghi cũ |
| Chống trùng | Lệnh tạo và lệnh có tác dụng phụ bắt buộc `Idempotency-Key` (16…128 ký tự, giữ 24 giờ, ADR-041); cùng khóa cùng thân trả lại phản hồi đã lưu; cùng khóa khác thân trả ERR-01-051; cùng khóa đang xử lý trả ERR-01-054 kèm `Retry-After`. Mở bàn giao (API-01-040) không dùng khóa vì mã chỉ mở được một lần và không thử lại |
| Phân trang | `page` (từ 0), `size` (mặc định 20, tối đa 100; riêng API đọc bản sao `size` ≤ 500); phản hồi có `page{number, size, totalElements, totalPages}`. Giao diện dùng `trang` từ 1, BFF đổi sang `page` |
| Lọc, sắp xếp | Tham số lặp dạng `status=SUBMITTED,APPROVED`; tìm `q` không dấu; `sort=trường:asc\|desc` với tập trường cố định; bộ lọc phạm vi tổ chức do OPA áp, không do tham số |
| Lỗi | RFC 9457 `application/problem+json`; `code` là `ERR-01-nnn`, `traceId`; thêm `errors` (theo trường), `issues` (ERR-01-008), `dependents` (ERR-01-034), `currentEtag` (ERR-01-007), `retryAfterSeconds` (ERR-01-026, 045, 054) |
| Hành động được phép | Đối tượng trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm (D03-06-PH01) |
| Truy vết | `traceparent` W3C xuyên BFF → `dh-connect` → Kafka; `traceId` có trong mọi thân lỗi |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail`; câu hiển thị cho người dùng lấy theo FRS §9.2 |
| Kiểu nội dung | `application/json`; `PATCH` dùng `application/merge-patch+json` (RFC 7396, chỉ trường được phép); tải tệp `multipart/form-data`; tải xuống tệp nhị phân |
| Kích thước | Thân JSON ≤ 1 MB, độ sâu ≤ 32 (SEC-43); tệp đính kèm ≤ `onboarding.attachment.maxSizeMb` (mặc định 20 MB, trần 50 MB); tệp nhập hệ cũ ≤ 5.000 dòng (`legacyImport.maxRows`) |
| Tiến trình dài | Xuất tệp, báo cáo, cấp lại định danh trả `202` kèm `Location` tới API-01-088 hoặc API-01-036; cấp định danh PRODUCTION chưa xong sau 10 giây trả `202` (API-01-044) |
| Giới hạn tốc độ | APISIX theo người dùng: **giả định** 300 yêu cầu mỗi phút (cơ sở: màn danh sách tự tải lại và gọi ≤ 5 API mỗi lần mở, NFR-01-014); tra danh bạ `directory.rateLimitPerMinute` (mặc định 60, ERR-01-045); mở bàn giao 10 lần mỗi phút mỗi địa chỉ IP (**giả định**, thêm vào giới hạn `handover.maxFailedOpens` theo liên kết); token dịch vụ 600 yêu cầu mỗi phút (**giả định**, cơ sở: bản sao toàn tenant ≤ 1.000 HTTT chỉ cần 2 trang 500 dòng mỗi lần đối chiếu) |

: Quy ước chung của API PH-01

Hai cơ chế chống ghi đè và chống lặp được áp theo bảng sau; bảng sinh từ OpenAPI nên luôn khớp với chương 10.

<!-- gen:conc:start -->
| Cơ chế | Số API | API-01- |
|---|---|---|
| `Idempotency-Key` bắt buộc | 19 | 004, 007, 015, 023, 035, 039, 041, 042, 045, 053, 054, 057, 060, 065, 069, 075, 079, 080, 085 |
| `If-Match` bắt buộc | 18 | 005, 009, 010, 012, 016, 017, 018, 019, 023, 031, 032, 033, 037, 044, 045, 052, 061, 084 |
| `If-Match` tùy chọn (thao tác khẩn) | 3 | 047, 051, 054 |
| Lệnh ghi không dùng cả hai (tính toán, việc của người thẩm định, mở một lần, phản hồi phiếu) | 16 | 022, 024, 025, 026, 028, 029, 030, 038, 040, 046, 055, 059, 071, 072, 073, 082 |

: Cơ chế khóa lạc quan và lũy đẳng theo API
<!-- gen:conc:end -->

Vì sao tách `If-Match` và `Idempotency-Key`: `If-Match` bảo vệ **nội dung** khỏi bị ghi đè khi hai người cùng sửa (hồ sơ, định danh, tham số); `Idempotency-Key` bảo vệ **tác dụng phụ** khỏi bị nhân đôi khi mạng chập chờn (tạo hồ sơ, nộp, tạo liên kết bàn giao, xuất tệp). Lệnh chuyển trạng thái lặp lại với cùng tác nhân và cùng đích trả lại kết quả hiện hành thay vì lỗi (SDD §8.2); khác đích trả ERR-01-005.

## 2. Xác thực và phân quyền

PH-01 có hai loại người gọi: người dùng của tenant (qua giao diện) và phân hệ khác (qua token dịch vụ). HTTT thành viên **không** gọi API của PH-01: HTTT chỉ nhận thông tin xác thực qua trang bàn giao, rồi gọi cổng API (PH-03) bằng định danh đã cấp. Nhờ vậy bề mặt tấn công từ Internet vào PH-01 chỉ còn đường của người dùng đã đăng nhập.

### 2.1. Xác thực

Mỗi loại người gọi có một cơ chế xác thực riêng, chọn theo mức rủi ro: người dùng đi qua đăng nhập có phiên và BFF, phân hệ khác dùng token dịch vụ ngắn hạn, đầu mối nhận bí mật phải qua hai yếu tố mới.

| Người gọi | Cơ chế | Chi tiết |
|---|---|---|
| Người dùng của tenant | OIDC Authorization Code + PKCE qua BFF (ADR-006) | Keycloak realm `dh-{tenant}`; token chứa `tenant`, `roles`, `acr`; khóa phiên 15 phút (TCVN 14423:2026); BFF gửi token tới API, trình duyệt không giữ token |
| Phân hệ khác (PH-02, 03, 04, 05, 10, 13, 14, 15) | OAuth 2.1 `client_credentials` + mTLS hoặc `private_key_jwt` | Scope `onboarding:internal-read`; token sống 5 phút; kiểm `azp` và `tenant`; không cấp cho người |
| PH-12, PH-03 (trả kết quả saga) | Như trên | Scope `onboarding:provision-callback` (API-01-087) |
| Tác vụ đối chiếu | Như trên | Scope `onboarding:reconcile` (API-01-062) |
| Đầu mối nhận liên kết (bàn giao, phiếu xác nhận) | Đăng nhập Keycloak của tenant + liên kết một lần | API-01-040 yêu cầu `acr` hai yếu tố mới đăng nhập; API-01-070, 071 yêu cầu đúng tổ chức |

: Xác thực theo loại người gọi

Khi PH-01 gọi PH-12, PH-03, PH-13, PH-14, PH-20, nó dùng tài khoản dịch vụ của `dh-connect`, không chuyển tiếp token của người dùng (FRS §3.3). Phản hồi lỗi xác thực dùng ERR-01-052 (401 khi thiếu hoặc hết hạn token; 403 khi thiếu quyền hoặc scope).

### 2.2. Quyền và API

PH-01 dùng sáu quyền đã có ở D02-08 và mượn hai quyền của PH-18; **không đề xuất mã quyền mới**. Bốn nhóm việc cần phân quyền mịn hơn mã quyền được hiện thực bằng quy tắc OPA (SEC-26): thẩm định theo phân công, phạm vi tổ chức của đơn vị nộp (OR chỉ tổ chức của mình), danh bạ đầu mối công khai, và quyền xuất toàn tenant (chỉ TA, AU, PA). Bảng sau cho biết mỗi quyền bảo vệ những API nào.

<!-- gen:perm:start -->
| Quyền hoặc điều kiện | Số API | API-01- |
|---|---|---|
| `PERM-01-read` | 29 | 001, 002, 003, 006, 008, 011, 013, 014, 027, 034, 036, 042, 043, 048, 049, 050, 056, 058, 066, 067, 068, 074, 075, 078, 079, 083, 085, 086, 088 |
| `PERM-01-create` | 11 | 004, 005, 007, 009, 010, 012, 015, 016, 017, 057, 060 |
| `PERM-01-submit` | 4 | 018, 019, 022, 023 |
| `PERM-01-approve` | 8 | 028, 030, 031, 032, 033, 044, 055, 059 |
| `PERM-01-credential` | 9 | 035, 037, 038, 039, 041, 045, 046, 047, 061 |
| `PERM-01-suspend` | 10 | 045, 047, 051, 052, 053, 054, 065, 069, 072, 073 |
| `PERM-18-config` | 1 | 084 |
| `PERM-18-migration` | 3 | 080, 081, 082 |
| Quyền cơ sở người dùng nội bộ tenant | 4 | 020, 021, 076, 077 |
| `PERM-01-read` kèm phân công bước thẩm định | 4 | 024, 025, 026, 029 |
| `PERM-01-read` (hoặc được phân công) | 2 | 030, 031 |
| Đầu mối nhận liên kết (đăng nhập, MFA) | 3 | 040, 070, 071 |
| Token dịch vụ `onboarding:reconcile` | 1 | 062 |
| Token dịch vụ `onboarding:internal-read` | 2 | 063, 064 |
| Token dịch vụ `onboarding:provision-callback` | 1 | 087 |

: Quyền và điều kiện của từng API
<!-- gen:perm:end -->

Máy chủ kiểm quyền hai lớp: `@PreAuthorize("hasAuthority('PERM-01-…')")` ở lớp web là lớp thô; lớp tinh do PEP gọi OPA với phạm vi tổ chức, phân công và aggregate kiểm lại bốn mắt, trạng thái (SDD §7). Giao diện ẩn nút chỉ là tiện ích, không là lớp bảo vệ.

Bốn mắt (FR-00-071) áp ở bốn điểm và máy chủ trả ERR-01-017 khi vi phạm: người lập hoặc nộp hồ sơ không thẩm định, phê duyệt hồ sơ đó; người đã thẩm định không phê duyệt chính hồ sơ ấy; thao tác khẩn của Cán bộ ATTT phải được TA khác xác nhận; người kích hoạt PRODUCTION không phải người nộp hồ sơ.

### 2.3. Xác thực lại hai yếu tố

Thao tác nhạy cảm yêu cầu xác thực hai yếu tố **mới** trong `mfa.stepUpMinutes` (mặc định 5 phút, NFR-01-012): người dùng gửi `authCode` hoặc token có `acr` đủ cao. Thiếu thì ERR-01-035 (403) và giao diện mở hộp xác thực lại rồi gửi lại cùng `Idempotency-Key` hoặc `If-Match`.

<!-- gen:stepup:start -->
| Cách xác thực lại | API-01- | Ghi chú |
|---|---|---|
| `authCode` trong thân hoặc `acr` hai yếu tố còn trong `mfa.stepUpMinutes` | 032, 033, 040, 044, 045, 047, 051, 052, 054, 055, 059, 072, 084 | Thiếu thì ERR-01-035 (403); giao diện mở hộp xác thực lại rồi gửi lại cùng `Idempotency-Key` hoặc `If-Match` |
| Đăng nhập mới có hai yếu tố, không dựa phiên cũ | 040 | Mở bàn giao; chưa đạt thì ERR-01-035 trước khi chiếm liên kết |

: Thao tác cần xác thực lại hai yếu tố
<!-- gen:stepup:end -->

### 2.4. Dữ liệu không bao giờ có trong phản hồi

Để bảo đảm NFR-01-009 (0 bí mật ngoài phản hồi mở bàn giao), bốn loại dữ liệu sau không xuất hiện ở bất kỳ phản hồi, sự kiện hay tệp xuất nào, và kiểm tra hợp đồng chặn trong CI (chương 7): (1) giá trị bí mật của client và tham chiếu `secret_ref` tới OpenBao; (2) liên kết bàn giao gốc và mã bọc (chỉ có băm trong CSDL); (3) khóa riêng (chỉ nhận khóa công khai, JWKS hoặc CSR); (4) dữ liệu liên hệ cá nhân của đầu mối trong sự kiện và trong bản sao đọc cho phân hệ khác (chỉ API danh bạ, API-01-014 và API-01-076…079 với quyền riêng trả liên hệ, đầu mối `SECURITY` chỉ TA, SO thấy).

## 3. Danh mục endpoint

Mỗi operation có đúng một mã `API-01-nnn`, không dùng chung mã cho hai operation. Mã 001…086 giữ nguyên theo [FRS §9.4](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md); mã 087, 088 do tập này thêm. Đường dẫn trong bảng bỏ tiền tố `/api/onboarding/v1`; `{systemCode}` là mã HTTT (chữ hoa, số, gạch ngang). Cột "FR" là số của `FR-01-nnn`; cột "Thành công" là mã HTTP khi thành công, `200/202` nghĩa là có thể đồng bộ hoặc bất đồng bộ.

Các endpoint chia mười một nhóm theo việc người dùng làm, không theo bảng dữ liệu:

| Nhóm | Số API | Việc chính |
|---|---|---|
| Hồ sơ HTTT | 8 | Liệt kê, xem, tạo nháp, sửa tự lưu, xóa nháp, rút hồ sơ, tiến độ |
| Tài liệu và mẫu | 6 | Tải lên, xem, xóa tài liệu; mẫu văn bản kết nạp |
| Hồ sơ kỹ thuật và nhu cầu | 4 | Năng lực kỹ thuật, nhóm HTTT, nhu cầu khai thác kèm căn cứ pháp lý |
| Đầu mối | 4 | Thêm, sửa, thay thế, bỏ đầu mối |
| Nộp, thẩm định, phê duyệt | 12 | Kiểm tra, nộp, ba bước thẩm định, phân công, tham vấn, trả bổ sung, duyệt, từ chối |
| Định danh và bàn giao | 16 | Saga cấp định danh, khóa công khai, CSR, bàn giao một lần, SANDBOX, xoay vòng, thu hồi |
| Vòng đời thành viên | 11 | Kích hoạt, tạm ngừng, khôi phục, chấm dứt, khẩn cấp, tác động, đề nghị thay đổi, mở rộng phạm vi |
| Nội bộ (phân hệ khác) | 4 | Bản sao đọc, đối chiếu, callback saga |
| Rà soát quyền định kỳ | 11 | Kỳ, mục, phiếu xác nhận, quyết định, báo cáo |
| Danh bạ đầu mối | 4 | Tra cứu, thiếu đầu mối, xuất |
| Di trú, tham số, thống kê | 8 | Nhập hệ cũ, tham số `onboarding.*`, xuất danh sách, thống kê, tác vụ nền |

: Nhóm endpoint của PH-01

<!-- gen:endpoints:start -->
**Hồ sơ HTTT**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-001 | `GET /systems` | Danh sách, tìm kiếm, lọc HTTT thành viên | 001 | `PERM-01-read` |  | 200 |
| API-01-002 | `GET /systems/{systemCode}` | Chi tiết HTTT thành viên | 002 | `PERM-01-read` |  | 200 |
| API-01-003 | `GET /systems/{systemCode}/history` | Lịch sử trạng thái và thay đổi của HTTT | 002 | `PERM-01-read` |  | 200 |
| API-01-004 | `POST /systems` | Tạo hồ sơ kết nạp nháp | 003 | `PERM-01-create` | có | 201 |
| API-01-005 | `PATCH /systems/{systemCode}` | Sửa hồ sơ nháp (tự lưu) | 004 | `PERM-01-create` |  | 200 |
| API-01-018 | `DELETE /systems/{systemCode}` | Xóa hồ sơ nháp chưa từng nộp | 009 | `PERM-01-submit` |  | 204 |
| API-01-019 | `POST /systems/{systemCode}:withdraw` | Rút hồ sơ đã nộp về nháp | 009 | `PERM-01-submit` |  | 200 |
| API-01-034 | `GET /systems/{systemCode}/progress` | Theo dõi tiến độ hồ sơ | 019 | `PERM-01-read` |  | 200 |

: Danh mục endpoint, nhóm Hồ sơ HTTT

**Tài liệu và mẫu**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-006 | `GET /systems/{systemCode}/attachments` | Danh sách tài liệu đính kèm | 005 | `PERM-01-read` |  | 200 |
| API-01-007 | `POST /systems/{systemCode}/attachments` | Tải tài liệu đính kèm | 005 | `PERM-01-create` | có | 201 |
| API-01-008 | `GET /systems/{systemCode}/attachments/{attachmentId}/content` | Tải nội dung tài liệu | 005 | `PERM-01-read` |  | 200 |
| API-01-009 | `DELETE /systems/{systemCode}/attachments/{attachmentId}` | Xóa tài liệu đính kèm | 005 | `PERM-01-create` |  | 204 |
| API-01-020 | `GET /templates` | Danh sách mẫu văn bản và hướng dẫn kết nạp | 010 | Quyền cơ sở (người dùng nội bộ) |  | 200 |
| API-01-021 | `GET /templates/{templateCode}/content` | Tải nội dung mẫu văn bản | 010 | Quyền cơ sở (người dùng nội bộ) |  | 200 |

: Danh mục endpoint, nhóm Tài liệu và mẫu

**Hồ sơ kỹ thuật và nhu cầu**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-010 | `PUT /systems/{systemCode}/technical-profile` | Khai hồ sơ năng lực kỹ thuật | 006 | `PERM-01-create` |  | 200 |
| API-01-011 | `GET /systems/{systemCode}/technical-profile` | Xem hồ sơ năng lực kỹ thuật và nhóm đề xuất | 006 | `PERM-01-read` |  | 200 |
| API-01-012 | `PUT /systems/{systemCode}/data-demands` | Khai danh sách nhu cầu khai thác | 007 | `PERM-01-create` |  | 200 |
| API-01-013 | `GET /systems/{systemCode}/data-demands` | Xem nhu cầu khai thác và trần phạm vi | 007 | `PERM-01-read` |  | 200 |

: Danh mục endpoint, nhóm Hồ sơ kỹ thuật và nhu cầu

**Đầu mối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-014 | `GET /systems/{systemCode}/contacts` | Danh sách đầu mối của HTTT | 008 | `PERM-01-read` |  | 200 |
| API-01-015 | `POST /systems/{systemCode}/contacts` | Thêm hoặc thay thế đầu mối | 008 | `PERM-01-create` | có | 201 |
| API-01-016 | `PATCH /systems/{systemCode}/contacts/{contactId}` | Sửa đầu mối | 008 | `PERM-01-create` |  | 200 |
| API-01-017 | `DELETE /systems/{systemCode}/contacts/{contactId}` | Bỏ đầu mối | 008 | `PERM-01-create` |  | 204 |

: Danh mục endpoint, nhóm Đầu mối

**Nộp, thẩm định, phê duyệt**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-022 | `POST /systems/{systemCode}:validate` | Kiểm tra hợp lệ hồ sơ trước khi nộp | 011 | `PERM-01-submit` |  | 200 |
| API-01-023 | `POST /systems/{systemCode}:submit` | Nộp hồ sơ kết nạp | 012 | `PERM-01-submit` | có | 200 |
| API-01-024 | `POST /systems/{systemCode}/reviews/technical` | Ghi kết luận thẩm định kỹ thuật | 013 | `PERM-01-read` + được phân công |  | 200 |
| API-01-025 | `POST /systems/{systemCode}/reviews/{reviewKind}` | Ghi kết luận thẩm định pháp lý hoặc ATTT | 014 | `PERM-01-read` + được phân công |  | 200 |
| API-01-026 | `POST /systems/{systemCode}/reviews/quota-impact` | Đánh giá tác động tới hạn mức dữ liệu quốc gia | 015 | `PERM-01-read` + được phân công |  | 200 |
| API-01-027 | `GET /review-queue` | Hàng đợi thẩm định | 016 | `PERM-01-read` |  | 200 |
| API-01-028 | `POST /systems/{systemCode}/reviews:assign` | Phân công người thẩm định | 016 | `PERM-01-approve` |  | 200 |
| API-01-029 | `POST /systems/{systemCode}/reviews:consult` | Gửi tham vấn, tạm dừng đồng hồ hạn | 016 | `PERM-01-read` + được phân công |  | 200 |
| API-01-030 | `POST /systems/{systemCode}/reviews:resume` | Kết thúc tham vấn, chạy lại đồng hồ hạn | 016 | `PERM-01-read` + được phân công |  | 200 |
| API-01-031 | `POST /systems/{systemCode}:return` | Trả bổ sung hồ sơ | 017 | `PERM-01-read` + được phân công |  | 200 |
| API-01-032 | `POST /systems/{systemCode}:approve` | Phê duyệt kết nạp | 018 | `PERM-01-approve` |  | 200 |
| API-01-033 | `POST /systems/{systemCode}:reject` | Từ chối kết nạp | 018 | `PERM-01-approve` |  | 200 |

: Danh mục endpoint, nhóm Nộp, thẩm định, phê duyệt

**Định danh và bàn giao**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-035 | `POST /systems/{systemCode}/credentials:provision` | Thử lại cấp định danh SANDBOX | 020 | `PERM-01-credential` | có | 202 |
| API-01-036 | `GET /systems/{systemCode}/provisioning` | Tiến độ saga cấp định danh | 020 | `PERM-01-read` |  | 200 |
| API-01-037 | `PUT /credentials/{credentialId}/public-key` | Đăng ký khóa công khai (JWKS) hoặc nộp CSR | 021 | `PERM-01-credential` |  | 200 |
| API-01-038 | `POST /credentials/{credentialId}:sign-csr` | Ký chứng thư cho CSR đã nộp | 021 | `PERM-01-credential` |  | 200 |
| API-01-039 | `POST /credentials/{credentialId}/handovers` | Tạo liên kết bàn giao một lần | 022 | `PERM-01-credential` | có | 201 |
| API-01-040 | `POST /handovers:open` | Mở liên kết bàn giao, nhận bí mật một lần | 022 | Người nhận liên kết (đăng nhập, MFA) |  | 200 |
| API-01-041 | `POST /handovers/{handoverId}:reissue` | Tạo lại liên kết bàn giao | 022 | `PERM-01-credential` | có | 201 |
| API-01-042 | `POST /systems/{systemCode}/sandbox-tests` | Làm mới kết quả kiểm thử SANDBOX | 023 | `PERM-01-read` | có | 200 |
| API-01-043 | `GET /systems/{systemCode}/sandbox-tests` | Kết quả kiểm thử SANDBOX | 023 | `PERM-01-read` |  | 200 |
| API-01-045 | `POST /credentials/{credentialId}:rotate` | Bắt đầu xoay vòng thông tin xác thực | 025 | `PERM-01-credential` hoặc `PERM-01-suspend` | có | 200 |
| API-01-046 | `POST /credentials/{credentialId}:finish-rotation` | Kết thúc thời gian chuyển tiếp xoay vòng | 025 | `PERM-01-credential` |  | 200 |
| API-01-047 | `POST /credentials/{credentialId}:revoke` | Thu hồi định danh ứng dụng | 026 | `PERM-01-credential` hoặc `PERM-01-suspend` |  | 200 |
| API-01-048 | `GET /credentials:expiring` | Định danh sắp hết hạn | 027 | `PERM-01-read` |  | 200 |
| API-01-049 | `GET /systems/{systemCode}/credentials` | Danh sách định danh của HTTT | 028 | `PERM-01-read` |  | 200 |
| API-01-050 | `GET /credentials/{credentialId}` | Chi tiết một định danh (không bí mật) | 028 | `PERM-01-read` |  | 200 |
| API-01-061 | `POST /credentials/{credentialId}:enable` | Bật lại định danh tự vô hiệu | 036 | `PERM-01-credential` |  | 200 |

: Danh mục endpoint, nhóm Định danh và bàn giao

**Vòng đời thành viên**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-044 | `POST /systems/{systemCode}:activate` | Kích hoạt môi trường thật (PRODUCTION) | 024 | `PERM-01-approve` |  | 200/202 |
| API-01-051 | `POST /systems/{systemCode}:suspend` | Tạm ngừng HTTT | 029 | `PERM-01-suspend` |  | 200 |
| API-01-052 | `POST /systems/{systemCode}:resume` | Khôi phục HTTT | 030 | `PERM-01-suspend` |  | 200 |
| API-01-053 | `POST /systems/{systemCode}:terminate` | Đề nghị chấm dứt tư cách thành viên | 031 | `PERM-01-suspend` | có | 201 |
| API-01-054 | `POST /systems/{systemCode}:emergency-action` | Tạm ngừng hoặc thu hồi khẩn của Cán bộ ATTT | 032 | `PERM-01-suspend` | có | 200 |
| API-01-055 | `POST /emergency-actions/{actionId}:confirm` | Xác nhận thao tác khẩn | 032 | `PERM-01-approve` |  | 200 |
| API-01-056 | `GET /systems/{systemCode}/impact` | Phân tích tác động phụ thuộc | 033 | `PERM-01-read` |  | 200 |
| API-01-057 | `POST /systems/{systemCode}/change-requests` | Đề nghị thay đổi hồ sơ HTTT đã kết nạp | 034 | `PERM-01-create` | có | 200/202 |
| API-01-058 | `GET /systems/{systemCode}/change-requests` | Danh sách đề nghị thay đổi | 034 | `PERM-01-read` |  | 200 |
| API-01-059 | `POST /change-requests/{changeRequestId}:decide` | Duyệt hoặc từ chối đề nghị thay đổi, chấm dứt | 031, 034 | `PERM-01-approve` |  | 200 |
| API-01-060 | `POST /systems/{systemCode}/scope-expansions` | Đề nghị mở rộng trần phạm vi khai thác | 035 | `PERM-01-create` | có | 202 |

: Danh mục endpoint, nhóm Vòng đời thành viên

**Nội bộ (phân hệ khác)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-062 | `POST /internal/reconciliations` | Chạy đối chiếu và phát ảnh chụp trạng thái | 037 | Token dịch vụ `onboarding:reconcile` |  | 202 |
| API-01-063 | `GET /internal/systems` | Bản sao đọc danh sách HTTT cho phân hệ khác | 038 | Token dịch vụ `onboarding:internal-read` |  | 200 |
| API-01-064 | `GET /internal/systems/{systemCode}` | Bản sao đọc một HTTT cho phân hệ khác | 038 | Token dịch vụ `onboarding:internal-read` |  | 200 |
| API-01-087 | `POST /internal/provisioning-callbacks` | Nhận kết quả bất đồng bộ của bước saga | 020 | Token dịch vụ `onboarding:provision-callback` |  | 200 |

: Danh mục endpoint, nhóm Nội bộ (phân hệ khác)

**Rà soát quyền định kỳ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-065 | `POST /access-reviews` | Mở kỳ rà soát quyền | 039 | `PERM-01-suspend` | có | 201 |
| API-01-066 | `GET /access-reviews` | Danh sách kỳ rà soát | 039 | `PERM-01-read` |  | 200 |
| API-01-067 | `GET /access-reviews/{cycleCode}` | Chi tiết kỳ rà soát | 039 | `PERM-01-read` |  | 200 |
| API-01-068 | `GET /access-reviews/{cycleCode}/items` | Mục rà soát và mức sử dụng | 040 | `PERM-01-read` |  | 200 |
| API-01-069 | `POST /access-reviews/{cycleCode}:send-confirmations` | Gửi phiếu xác nhận cho đơn vị chủ quản | 041 | `PERM-01-suspend` | có | 202 |
| API-01-070 | `GET /access-review-confirmations/{token}` | Xem phiếu xác nhận của đơn vị | 041 | Người nhận liên kết (đăng nhập, MFA) |  | 200 |
| API-01-071 | `POST /access-review-confirmations/{token}:respond` | Đơn vị trả lời phiếu xác nhận | 041 | Người nhận liên kết (đăng nhập, MFA) |  | 200 |
| API-01-072 | `POST /access-reviews/{cycleCode}/items:decide` | Quyết định thu hẹp hoặc thu hồi phạm vi | 042 | `PERM-01-suspend` |  | 200 |
| API-01-073 | `POST /scope-ceilings:mark-legal-expired` | Đánh dấu văn bản pháp lý hết hiệu lực | 043 | `PERM-01-suspend` |  | 200 |
| API-01-074 | `GET /access-reviews/{cycleCode}/report` | Báo cáo rà soát quyền | 044 | `PERM-01-read` |  | 200 |
| API-01-075 | `POST /access-reviews/{cycleCode}/report:export` | Xuất báo cáo rà soát quyền | 044 | `PERM-01-read` | có | 202 |

: Danh mục endpoint, nhóm Rà soát quyền định kỳ

**Danh bạ đầu mối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-076 | `GET /directory/contacts` | Tra cứu danh bạ đầu mối | 045 | Quyền cơ sở (người dùng nội bộ) |  | 200 |
| API-01-077 | `GET /directory/organizations/{orgId}/contacts` | Đầu mối của một tổ chức | 045 | Quyền cơ sở (người dùng nội bộ) |  | 200 |
| API-01-078 | `GET /directory/gaps` | Tổ chức thiếu đầu mối và đầu mối cần xác nhận | 046 | `PERM-01-read` |  | 200 |
| API-01-079 | `POST /directory/contacts:export` | Xuất danh bạ đầu mối | 047 | `PERM-01-read` | có | 200/202 |

: Danh mục endpoint, nhóm Danh bạ đầu mối

**Di trú, tham số, thống kê**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-01-080 | `POST /legacy-imports` | Tải tệp nhập HTTT từ hệ cũ | 048 | `PERM-18-migration` | có | 201 |
| API-01-081 | `GET /legacy-imports/{jobId}` | Kết quả xem trước và nhập hệ cũ | 048 | `PERM-18-migration` |  | 200 |
| API-01-082 | `POST /legacy-imports/{jobId}:confirm` | Xác nhận tạo hồ sơ nháp từ tệp nhập | 048 | `PERM-18-migration` |  | 200 |
| API-01-083 | `GET /settings` | Tham số `onboarding.*` của tenant | 049 | `PERM-01-read` |  | 200 |
| API-01-084 | `PUT /settings/{key}` | Sửa một tham số của tenant | 049 | `PERM-18-config` |  | 200 |
| API-01-085 | `POST /systems:export` | Xuất danh sách HTTT thành viên | 050 | `PERM-01-read` | có | 200/202 |
| API-01-086 | `GET /statistics` | Thống kê kết nạp và thời gian xử lý | 051 | `PERM-01-read` |  | 200 |
| API-01-088 | `GET /jobs/{jobId}` | Tra tác vụ nền xuất tệp hoặc báo cáo | 044, 047, 050 | `PERM-01-read` |  | 200 |

: Danh mục endpoint, nhóm Di trú, tham số, thống kê
<!-- gen:endpoints:end -->

Năm điểm cần biết khi đọc bảng. (1) API-01-025 dùng một đường dẫn cho hai bước (`reviewKind` là `legal` hoặc `security`) vì hai bước cùng cấu trúc, khác lược đồ thân (`oneOf`). (2) API-01-018 (xóa nháp) và API-01-019 (rút hồ sơ) dùng quyền `PERM-01-submit` vì cùng đối tượng với việc nộp. (3) API-01-044 trả `200` khi cấp định danh PRODUCTION xong trong 10 giây, `202` kèm `progressUrl` khi chưa xong (đề nghị Q01-28 của SDD). (4) API-01-057 trả `200` khi thay đổi mức `NONE` được áp ngay, `202` khi tạo đề nghị chờ duyệt. (5) Ba API trả tệp (008, 021, 074) có thể trả `302` tới liên kết ký của kho tệp tùy cấu hình.

### 3.1. Ví dụ yêu cầu và phản hồi

Ví dụ dưới lấy từ chính OpenAPI (nên khớp lược đồ, đã kiểm ở CI-5), dùng dữ liệu giả lập của tenant `T68`: HTTT `HT-TUPHAP` của Sở Tư pháp xin kết nối để cấp giấy khai sinh điện tử. Phản hồi cùng cấu trúc với ví dụ đã có ở API trước thì chỉ nêu tên lược đồ.

<!-- gen:examples:start -->
**Hồ sơ HTTT**

**API-01-001 · Danh sách, tìm kiếm, lọc HTTT thành viên**

```http
GET /api/onboarding/v1/systems?status=SUBMITTED&page=0&size=20
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "code": "HT-TUPHAP",
      "name": "Hệ thống quản lý hộ tịch",
      "ownerOrg": { "id": "SO-TUPHAP", "name": "Sở Tư pháp" },
      "status": "SUBMITTED",
      "reviewStage": "IN_REVIEW",
      "provisionStage": null,
      "group": 1,
      "roles": ["CONSUMER", "PROVIDER"],
      "securityLevel": "L3",
      "scopeCount": 0,
      "calls30d": null,
      "lastReviewAt": null,
      "flags": ["REVIEW_OVERDUE"],
      "updatedAt": "2026-11-26T09:10:00Z",
      "allowedActions": ["view"],
      "disabledReasons": {}
    }
  ],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 },
  "facets": {
    "status": { "SUBMITTED": 1 },
    "group": { "1": 1 }
  }
}
```

**API-01-002 · Chi tiết HTTT thành viên**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "code": "HT-TUPHAP",
  "name": "Hệ thống quản lý hộ tịch",
  "ownerOrg": { "id": "SO-TUPHAP", "name": "Sở Tư pháp" },
  "status": "DRAFT",
  "reviewStage": null,
  "provisionStage": null,
  "group": null,
  "roles": ["CONSUMER", "PROVIDER"],
  "securityLevel": "L3",
  "scopeCount": 0,
  "calls30d": null,
  "lastReviewAt": null,
  "flags": [],
  "updatedAt": "2026-11-26T08:30:00Z",
  "allowedActions": ["edit", "delete", "validate", "submit"],
  "disabledReasons": {},
  "description": "Cấp, quản lý giấy khai sinh, kết hôn, khai tử của sở Tư pháp.",
  "operatorName": "Công ty ABC",
  "systemType": "PROVINCIAL",
  "securityApprovalRef": "QĐ 1234/QĐ-UBND ngày 12/03/2026",
  "baseUrls": ["https://hotich.tinh.example.gov.vn/api"],
  "ipAllowlist": ["10.20.0.0/24"],
  "applicationNo": "KN-2026-000123",
  "revisionNo": 0,
  "returnReason": null,
  "statusReason": null,
  "enforcement": "NONE",
  "technicalProfile": null,
  "dataDemands": [],
  "ceiling": [],
  "contacts": [],
  "credentials": [],
  "legacyRef": "APIM-APP-0042",
  "submittedAt": null,
  "approvedAt": null,
  "activatedAt": null,
  "terminatedAt": null,
  "createdAt": "2026-11-26T08:30:00Z",
  "createdBy": "an.nv"
}
```

**API-01-003 · Lịch sử trạng thái và thay đổi của HTTT**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/history
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "fromStatus": "DRAFT",
      "toStatus": "SUBMITTED",
      "reason": null,
      "actor": "an.nv",
      "emergency": false,
      "at": "2026-11-26T09:00:00Z",
      "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"
    }
  ],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 }
}
```

**API-01-004 · Tạo hồ sơ kết nạp nháp**

```http
POST /api/onboarding/v1/systems
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "code": "HT-TUPHAP",
  "name": "Hệ thống quản lý hộ tịch",
  "description": "Cấp, quản lý giấy khai sinh, kết hôn, khai tử của sở Tư pháp.",
  "ownerOrgId": "SO-TUPHAP",
  "operatorName": "Công ty ABC",
  "systemType": "PROVINCIAL",
  "roles": ["CONSUMER", "PROVIDER"],
  "securityLevel": "L3",
  "securityApprovalRef": "QĐ 1234/QĐ-UBND ngày 12/03/2026",
  "baseUrls": ["https://hotich.tinh.example.gov.vn/api"],
  "ipAllowlist": ["10.20.0.0/24"],
  "legacyRef": "APIM-APP-0042"
}
```

Phản hồi `201`: cùng cấu trúc `SystemDetail` như ở API-01-002.

**API-01-005 · Sửa hồ sơ nháp (tự lưu)**

```http
PATCH /api/onboarding/v1/systems/HT-TUPHAP
Content-Type: application/merge-patch+json

{
  "description": "Cấp, quản lý giấy khai sinh, kết hôn, khai tử, nhận cha mẹ con.",
  "baseUrls": ["https://hotich.tinh.example.gov.vn/api/v2"]
}
```

Phản hồi `200`: cùng cấu trúc `SystemDetail` như ở API-01-002.

**API-01-018 · Xóa hồ sơ nháp chưa từng nộp**

```http
DELETE /api/onboarding/v1/systems/HT-TUPHAP
```

Phản hồi `204`: không có thân.

**API-01-019 · Rút hồ sơ đã nộp về nháp**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:withdraw
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "code": "HT-TUPHAP",
  "status": "SUBMITTED",
  "reviewStage": "IN_REVIEW",
  "provisionStage": null,
  "revisionNo": 1,
  "enforcement": "NONE",
  "steps": [
    { "stepType": "TECHNICAL", "dueAt": "2026-11-30T10:00:00Z" },
    { "stepType": "LEGAL", "dueAt": "2026-11-30T10:00:00Z" },
    { "stepType": "SECURITY", "dueAt": "2026-11-30T10:00:00Z" }
  ],
  "updatedAt": "2026-11-26T09:00:00Z"
}
```

**API-01-034 · Theo dõi tiến độ hồ sơ**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/progress
```

Phản hồi `200`:

```json
{
  "timeline": [
    { "event": "SUBMITTED", "at": "2026-11-26T09:00:00Z", "actor": "an.nv", "note": null }
  ],
  "waitingOn": { "role": "ROLE-INTEGRATION_ENGINEER", "dueAt": "2026-11-30T10:00:00Z", "overdue": false },
  "returnRequests": []
}
```

**Tài liệu và mẫu**

**API-01-006 · Danh sách tài liệu đính kèm**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/attachments
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d",
      "kind": "LEGAL_BASIS",
      "title": "Luật BVDLCN 91/2025",
      "fileName": "luat-91-2025.pdf",
      "sizeBytes": 1048576,
      "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
      "scanStatus": "CLEAN",
      "uploadedBy": "an.nv",
      "uploadedAt": "2026-11-26T08:45:00Z"
    }
  ]
}
```

**API-01-007 · Tải tài liệu đính kèm**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/attachments
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: multipart/form-data  (phần `file`, `kind`, `title`)
```

Phản hồi `201` (tiêu đề `Location`):

```json
{
  "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d",
  "kind": "LEGAL_BASIS",
  "title": "Luật BVDLCN 91/2025",
  "fileName": "luat-91-2025.pdf",
  "sizeBytes": 1048576,
  "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
  "scanStatus": "CLEAN",
  "uploadedBy": "an.nv",
  "uploadedAt": "2026-11-26T08:45:00Z"
}
```

**API-01-008 · Tải nội dung tài liệu**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/attachments/0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d/content
```

Phản hồi `200`: tệp nhị phân.

**API-01-009 · Xóa tài liệu đính kèm**

```http
DELETE /api/onboarding/v1/systems/HT-TUPHAP/attachments/0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d
```

Phản hồi `204`: không có thân.

**API-01-020 · Danh sách mẫu văn bản và hướng dẫn kết nạp**

```http
GET /api/onboarding/v1/templates
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "templateCode": "VAN-BAN-DE-NGHI-KET-NOI",
      "title": "Mẫu văn bản đề nghị kết nối",
      "version": "1.2",
      "updatedAt": "2026-10-01T00:00:00Z"
    }
  ]
}
```

**API-01-021 · Tải nội dung mẫu văn bản**

```http
GET /api/onboarding/v1/templates/VAN-BAN-DE-NGHI-KET-NOI/content
```

Phản hồi `200`: tệp nhị phân.

**Hồ sơ kỹ thuật và nhu cầu**

**API-01-010 · Khai hồ sơ năng lực kỹ thuật**

```http
PUT /api/onboarding/v1/systems/HT-TUPHAP/technical-profile
Content-Type: application/json

{
  "systemKind": "WEB",
  "technology": "Java 8, Spring 4",
  "hasApi": true,
  "apiSpecKind": "OPENAPI",
  "protocols": ["REST"],
  "underMaintenance": false,
  "replacementPlanned": false,
  "criticality": "NORMAL",
  "maxConcurrentConnections": 20,
  "expectedDailyCalls": 5000,
  "operatingHours": "24/7, bảo trì CN 22:00"
}
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "systemKind": "WEB",
  "technology": "Java 8, Spring 4",
  "hasApi": true,
  "apiSpecKind": "OPENAPI",
  "protocols": ["REST"],
  "underMaintenance": false,
  "replacementPlanned": false,
  "criticality": "NORMAL",
  "maxConcurrentConnections": 20,
  "expectedDailyCalls": 5000,
  "proposedGroup": 1,
  "confirmedGroup": null,
  "explanation": ["Có API OpenAPI và giao thức REST → nhóm 1 (điều hợp REST)"]
}
```

**API-01-011 · Xem hồ sơ năng lực kỹ thuật và nhóm đề xuất**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/technical-profile
```

Phản hồi `200`: cùng cấu trúc `TechnicalProfileView` như ở API-01-010.

**API-01-012 · Khai danh sách nhu cầu khai thác**

```http
PUT /api/onboarding/v1/systems/HT-TUPHAP/data-demands
Content-Type: application/json

{
  "demands": [
    {
      "direction": "CONSUME",
      "dataType": "THONG_TIN_CONG_DAN",
      "scopeRequested": "Tra cứu phục vụ giải quyết TTHC",
      "classification": "RESTRICTED",
      "purpose": "Xác minh nhân thân khi cấp giấy khai sinh",
      "legalBasis": {
        "docNo": "Luật 91/2025/QH15",
        "issuedOn": "2025-06-26",
        "issuer": "Quốc hội",
        "validUntil": "2028-12-31",
        "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d"
      }
    }
  ]
}
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "demands": [
    {
      "demandId": "0194f2c3-1b20-7d11-8a55-2e3f4a5b6c7d",
      "direction": "CONSUME",
      "dataType": "THONG_TIN_CONG_DAN",
      "scopeRequested": "Tra cứu phục vụ giải quyết TTHC",
      "classification": "RESTRICTED",
      "purpose": "Xác minh nhân thân khi cấp giấy khai sinh",
      "legalBasis": {
        "docNo": "Luật 91/2025/QH15",
        "issuedOn": "2025-06-26",
        "issuer": "Quốc hội",
        "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d"
      },
      "verdict": null,
      "scopeApproved": null,
      "opinion": null,
      "missingLegalBasis": false
    }
  ],
  "ceiling": []
}
```

**API-01-013 · Xem nhu cầu khai thác và trần phạm vi**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/data-demands
```

Phản hồi `200`: cùng cấu trúc `DataDemandList` như ở API-01-012.

**Đầu mối**

**API-01-014 · Danh sách đầu mối của HTTT**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/contacts
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e",
      "contactType": "TECHNICAL",
      "fullName": "Nguyễn Văn An",
      "position": "Chuyên viên CNTT",
      "email": "an.nv@tuphap.tinh.example.gov.vn",
      "phone": "+84912345678",
      "isPublic": true,
      "hasAccount": true,
      "lastConfirmedAt": null,
      "status": "ACTIVE"
    }
  ]
}
```

**API-01-015 · Thêm hoặc thay thế đầu mối**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/contacts
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "contactType": "TECHNICAL",
  "fullName": "Nguyễn Văn An",
  "position": "Chuyên viên CNTT",
  "email": "an.nv@tuphap.tinh.example.gov.vn",
  "phone": "+84912345678",
  "isPublic": true
}
```

Phản hồi `201`: cùng cấu trúc `ContactList` như ở API-01-014.

**API-01-016 · Sửa đầu mối**

```http
PATCH /api/onboarding/v1/systems/HT-TUPHAP/contacts/0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e
```

Phản hồi `200`: cùng cấu trúc `ContactList` như ở API-01-014.

**API-01-017 · Bỏ đầu mối**

```http
DELETE /api/onboarding/v1/systems/HT-TUPHAP/contacts/0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e
```

Phản hồi `204`: không có thân.

**Nộp, thẩm định, phê duyệt**

**API-01-022 · Kiểm tra hợp lệ hồ sơ trước khi nộp**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:validate
```

Phản hồi `200`:

```json
{
  "valid": false,
  "errorCount": 1,
  "warningCount": 1,
  "issues": [
    {
      "path": "dataDemands[1].legalBasis",
      "code": "ERR-01-015",
      "severity": "ERROR",
      "message": "Mục 'Thông tin thửa đất' chưa có căn cứ pháp lý",
      "guidance": "Bổ sung số, ngày, cơ quan ban hành văn bản cho phép khai thác dữ liệu."
    },
    {
      "path": "contacts",
      "code": "ERR-01-050",
      "severity": "WARNING",
      "message": "Nên có thêm một đầu mối kỹ thuật dự phòng",
      "guidance": "Thêm đầu mối thứ hai."
    }
  ]
}
```

**API-01-023 · Nộp hồ sơ kết nạp**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:submit
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{ "note": "Đề nghị kết nối để cấp giấy khai sinh điện tử." }
```

Phản hồi `200`: cùng cấu trúc `StateChangeResult` như ở API-01-019.

**API-01-024 · Ghi kết luận thẩm định kỹ thuật**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/reviews/technical
Content-Type: application/json

{
  "result": "PASS",
  "confirmedGroup": 1,
  "adapterTypes": [],
  "authMethod": "PRIVATE_KEY_JWT",
  "proposedQuota": { "limit": 5000, "period": "DAY" },
  "effortDays": 10
}
```

Phản hồi `200`:

```json
{
  "stepType": "LEGAL",
  "result": "PASS",
  "summary": { "approved": 0, "narrowed": 1, "rejected": 0 },
  "ceilingPreview": [
    { "dataType": "THONG_TIN_CONG_DAN", "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC" }
  ],
  "reviewStage": "WAITING_APPROVAL",
  "finishedAt": "2026-11-27T03:20:00Z"
}
```

**API-01-025 · Ghi kết luận thẩm định pháp lý hoặc ATTT**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/reviews/legal
```

Phản hồi `200`: cùng cấu trúc `ReviewStepResult` như ở API-01-024.

**API-01-026 · Đánh giá tác động tới hạn mức dữ liệu quốc gia**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/reviews/quota-impact
```

Phản hồi `200`:

```json
{
  "impact": [
    {
      "service": "CSDLQG-DANCU-TRACUU",
      "remaining": 120000,
      "projected": 5000,
      "level": "LOW",
      "suggestion": "Không cần xin thêm hạn mức"
    }
  ],
  "partial": false
}
```

**API-01-027 · Hàng đợi thẩm định**

```http
GET /api/onboarding/v1/review-queue?mine=true&overdue=false
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "systemCode": "HT-TUPHAP",
      "systemName": "Hệ thống quản lý hộ tịch",
      "applicationNo": "KN-2026-000123",
      "stepType": "TECHNICAL",
      "dueAt": "2026-11-30T10:00:00Z",
      "overdue": false,
      "assignee": { "userId": "ie.tranb", "displayName": "Trần Văn B" },
      "status": "OPEN"
    }
  ],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 }
}
```

**API-01-028 · Phân công người thẩm định**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/reviews:assign
Content-Type: application/json

{ "stepType": "TECHNICAL", "assigneeId": "ie.tranb" }
```

Phản hồi `200`:

```json
{
  "stepType": "TECHNICAL",
  "status": "OPEN",
  "assigneeId": "ie.tranb",
  "dueAt": "2026-11-30T10:00:00Z",
  "finishedAt": null,
  "pausedMillis": 0
}
```

**API-01-029 · Gửi tham vấn, tạm dừng đồng hồ hạn**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/reviews:consult
```

Phản hồi `200`: cùng cấu trúc `ReviewStep` như ở API-01-028.

**API-01-030 · Kết thúc tham vấn, chạy lại đồng hồ hạn**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/reviews:resume
```

Phản hồi `200`: cùng cấu trúc `ReviewStep` như ở API-01-028.

**API-01-031 · Trả bổ sung hồ sơ**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:return
Content-Type: application/json

{
  "requests": [
    {
      "path": "technicalProfile.protocols",
      "requirement": "Khai rõ giao thức; hệ thống có cả SOAP lẫn REST."
    }
  ],
  "note": "Bổ sung trong 5 ngày."
}
```

Phản hồi `200`: cùng cấu trúc `SystemDetail` như ở API-01-002.

**API-01-032 · Phê duyệt kết nạp**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:approve
Content-Type: application/json

{ "comment": "Đủ điều kiện, đã thẩm định ba bước.", "authCode": "482910" }
```

Phản hồi `200`: cùng cấu trúc `StateChangeResult` như ở API-01-019.

**API-01-033 · Từ chối kết nạp**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:reject
Content-Type: application/json

{ "comment": "Dữ liệu đề nghị thuộc danh mục bí mật nhà nước." }
```

Phản hồi `200`: cùng cấu trúc `StateChangeResult` như ở API-01-019.

**Định danh và bàn giao**

**API-01-035 · Thử lại cấp định danh SANDBOX**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/credentials:provision
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

Phản hồi `202` (tiêu đề `Location`):

```json
{
  "sagaId": "0194f2c5-3d40-7f33-8c77-4a5b6c7d8e9f",
  "stage": "PROVISIONING",
  "startedAt": "2026-11-27T04:00:00Z",
  "nextRetryAt": "2026-11-27T04:02:00Z",
  "attempt": 1,
  "steps": [
    { "name": "RECORD", "status": "DONE", "at": "2026-11-27T04:00:01Z", "errorCode": null },
    { "name": "CREATE_CLIENT", "status": "FAILED", "at": "2026-11-27T04:00:12Z", "errorCode": "ERR-01-021" }
  ]
}
```

**API-01-036 · Tiến độ saga cấp định danh**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/provisioning
```

Phản hồi `200`: cùng cấu trúc `SagaStatus` như ở API-01-035.

**API-01-037 · Đăng ký khóa công khai (JWKS) hoặc nộp CSR**

```http
PUT /api/onboarding/v1/credentials/cr-0194f2c6/public-key
Content-Type: application/json

{
  "kind": "JWKS",
  "kid": "2026-12-a",
  "payload": "{\"keys\":[{\"kty\":\"EC\",\"crv\":\"P-256\",\"x\":\"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU\",\"y\":\"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0\",\"use\":\"sig\",\"kid\":\"2026-12-a\"}]}"
}
```

Phản hồi `200`:

```json
{
  "credentialId": "cr-0194f2c6",
  "kid": "2026-12-a",
  "certFingerprint": null,
  "certificatePem": null,
  "expiresAt": "2027-11-26T00:00:00Z",
  "provisionStage": "SANDBOX_READY"
}
```

**API-01-038 · Ký chứng thư cho CSR đã nộp**

```http
POST /api/onboarding/v1/credentials/cr-0194f2c6:sign-csr
```

Phản hồi `200`: cùng cấu trúc `CredentialKeyResult` như ở API-01-037.

**API-01-039 · Tạo liên kết bàn giao một lần**

```http
POST /api/onboarding/v1/credentials/cr-0194f2c6/handovers
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{ "recipientContactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "ttlHours": 24 }
```

Phản hồi `201` (tiêu đề `Location`):

```json
{
  "handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0",
  "status": "PENDING",
  "expiresAt": "2026-11-28T04:05:00Z",
  "recipient": {
    "contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e",
    "fullName": "Nguyễn Văn An",
    "emailMasked": "a***@tuphap.tinh.example.gov.vn"
  }
}
```

**API-01-040 · Mở liên kết bàn giao, nhận bí mật một lần**

```http
POST /api/onboarding/v1/handovers:open
Content-Type: application/json

{ "token": "VIDU000000000000000000000000000000000000000" }
```

Phản hồi `200` (tiêu đề `Cache-Control`):

```json
{
  "maHeThong": "HT-TUPHAP",
  "thongTinKetNoi": {
    "clientId": "t68-ht-tuphap-sbx",
    "clientSecret": "DEMO-ONLY-NOT-A-SECRET",
    "tokenEndpoint": "https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token",
    "apiBaseUrl": "https://api-sandbox.t68.datahub.example.vn",
    "authMethod": "CLIENT_SECRET",
    "scopes": ["sandbox:invoke"],
    "quota": { "limit": 1000, "period": "DAY" }
  },
  "canhBao": "Thông tin này chỉ hiển thị MỘT LẦN. Lưu vào nơi an toàn ngay.",
  "huongDan": "https://docs.datahub.example.vn/ket-noi/sandbox"
}
```

**API-01-041 · Tạo lại liên kết bàn giao**

```http
POST /api/onboarding/v1/handovers/0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0:reissue
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

Phản hồi `201`: cùng cấu trúc `HandoverCreated` như ở API-01-039.

**API-01-042 · Làm mới kết quả kiểm thử SANDBOX**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/sandbox-tests
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

Phản hồi `200`:

```json
{
  "authOk": true,
  "apiOk": false,
  "callCount": 2,
  "successCount": 1,
  "required": 3,
  "errors": [
    { "code": "invalid_scope", "count": 4, "guidance": "Dùng scope môi trường thử, ví dụ sandbox:invoke." }
  ],
  "readyToActivate": false,
  "source": "PH03",
  "observedAt": "2026-11-27T05:00:00Z",
  "partial": false
}
```

**API-01-043 · Kết quả kiểm thử SANDBOX**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/sandbox-tests
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "authOk": true,
      "apiOk": false,
      "callCount": 2,
      "successCount": 1,
      "required": 3,
      "errors": [
        { "code": "invalid_scope", "count": 4, "guidance": "Dùng scope môi trường thử, ví dụ sandbox:invoke." }
      ],
      "readyToActivate": false,
      "source": "PH03",
      "observedAt": "2026-11-27T05:00:00Z",
      "partial": false
    }
  ],
  "readyToActivate": false
}
```

**API-01-045 · Bắt đầu xoay vòng thông tin xác thực**

```http
POST /api/onboarding/v1/credentials/cr-0194f2c6:rotate
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{ "reason": "Định kỳ 180 ngày", "overlapDays": 7 }
```

Phản hồi `200`:

```json
{
  "credentialId": "cr-0194f2c6",
  "status": "ROTATING",
  "rotationEndsAt": "2026-12-05T00:00:00Z",
  "handover": { "handoverId": "0194f2c8-5f60-7155-9e99-6c7d8e9fa0b1", "expiresAt": "2026-11-28T04:10:00Z" }
}
```

**API-01-046 · Kết thúc thời gian chuyển tiếp xoay vòng**

```http
POST /api/onboarding/v1/credentials/cr-0194f2c6:finish-rotation
```

Phản hồi `200`: cùng cấu trúc `RotateResult` như ở API-01-045.

**API-01-047 · Thu hồi định danh ứng dụng**

```http
POST /api/onboarding/v1/credentials/cr-0194f2c6:revoke
Content-Type: application/json

{ "reason": "Nghi lộ thông tin xác thực trên kho mã nguồn", "confirmImpact": true }
```

Phản hồi `200`:

```json
{
  "credentialId": "cr-0194f2c6",
  "status": "REVOKED",
  "enforcement": "DONE",
  "revokedAt": "2026-11-29T02:00:00Z"
}
```

**API-01-048 · Định danh sắp hết hạn**

```http
GET /api/onboarding/v1/credentials:expiring?withinDays=30
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "systemCode": "HT-TUPHAP",
      "credentialId": "cr-0194f2c6",
      "environment": "PRODUCTION",
      "expiresAt": "2027-01-05T00:00:00Z",
      "daysLeft": 29,
      "ownerOrg": { "id": "SO-TUPHAP", "name": "Sở Tư pháp" }
    }
  ],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 }
}
```

**API-01-049 · Danh sách định danh của HTTT**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/credentials
```

Phản hồi `200`:

```json
{
  "credentials": [
    {
      "credentialId": "cr-0194f2c6",
      "environment": "SANDBOX",
      "authMethod": "PRIVATE_KEY_JWT",
      "clientId": "t68-ht-tuphap-sbx",
      "certFingerprint": null,
      "status": "ACTIVE",
      "disabled": false,
      "disabledReason": null,
      "expiresAt": "2027-11-26T00:00:00Z",
      "lastUsedAt": null,
      "rotationEndsAt": null,
      "secretAgeDays": 0,
      "keyRegistered": true,
      "createdAt": "2026-11-27T04:00:20Z",
      "allowedActions": ["rotate", "revoke"],
      "disabledReasons": {}
    }
  ]
}
```

**API-01-050 · Chi tiết một định danh (không bí mật)**

```http
GET /api/onboarding/v1/credentials/cr-0194f2c6
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "credentialId": "cr-0194f2c6",
  "environment": "SANDBOX",
  "authMethod": "PRIVATE_KEY_JWT",
  "clientId": "t68-ht-tuphap-sbx",
  "certFingerprint": null,
  "status": "ACTIVE",
  "disabled": false,
  "disabledReason": null,
  "expiresAt": "2027-11-26T00:00:00Z",
  "lastUsedAt": null,
  "rotationEndsAt": null,
  "secretAgeDays": 0,
  "keyRegistered": true,
  "createdAt": "2026-11-27T04:00:20Z",
  "allowedActions": ["rotate", "revoke"],
  "disabledReasons": {}
}
```

**API-01-061 · Bật lại định danh tự vô hiệu**

```http
POST /api/onboarding/v1/credentials/cr-0194f2c6:enable
```

Phản hồi `200`: cùng cấu trúc `Credential` như ở API-01-050.

**Vòng đời thành viên**

**API-01-044 · Kích hoạt môi trường thật (PRODUCTION)**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:activate
Content-Type: application/json

{ "note": "Đã kiểm thử đạt, đề nghị bật PRODUCTION.", "authCode": "130557" }
```

Phản hồi `200`: cùng cấu trúc `StateChangeResult` như ở API-01-019.

**API-01-051 · Tạm ngừng HTTT**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:suspend
Content-Type: application/json

{
  "reasonCode": "OVERLOAD",
  "reason": "Tăng đột biến lưu lượng làm quá tải cổng",
  "expectedUntil": "2026-12-01",
  "confirmImpact": true
}
```

Phản hồi `200`: cùng cấu trúc `StateChangeResult` như ở API-01-019.

**API-01-052 · Khôi phục HTTT**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:resume
Content-Type: application/json

{ "reason": "Đã xử lý nguyên nhân quá tải và giảm hạn mức", "confirmCredentialsRotated": false }
```

Phản hồi `200`: cùng cấu trúc `StateChangeResult` như ở API-01-019.

**API-01-053 · Đề nghị chấm dứt tư cách thành viên**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:terminate
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "reason": "Hệ thống ngừng vận hành theo quyết định của sở",
  "legalBasis": "QĐ 88/QĐ-SO ngày 01/10/2026",
  "confirmImpact": true
}
```

Phản hồi `201` (tiêu đề `ETag`, `Location`):

```json
{
  "id": "0194f2ca-7180-7377-90bb-8e9fa0b1c2d3",
  "changeClass": "FULL",
  "status": "PENDING",
  "reason": "Nâng cấp độ ATTT theo quyết định mới",
  "diff": {
    "securityLevel": { "from": "L3", "to": "L4" }
  },
  "requestedBy": "an.nv",
  "requestedAt": "2026-11-26T11:00:00Z"
}
```

**API-01-054 · Tạm ngừng hoặc thu hồi khẩn của Cán bộ ATTT**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP:emergency-action
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "mode": "SUSPEND",
  "reason": "Phát hiện bí mật client lộ trên kho mã công khai",
  "incidentRef": "INC-2026-0412"
}
```

Phản hồi `200`:

```json
{
  "actionId": "0194f2c9-6070-7266-8faa-7d8e9fa0b1c2",
  "status": "PENDING_CONFIRM",
  "systemStatus": "SUSPENDED",
  "confirmBy": "2026-11-30T02:00:00Z",
  "enforcement": "PENDING"
}
```

**API-01-055 · Xác nhận thao tác khẩn**

```http
POST /api/onboarding/v1/emergency-actions/0194f2c9-6070-7266-8faa-7d8e9fa0b1c2:confirm
```

Phản hồi `200`: cùng cấu trúc `EmergencyResult` như ở API-01-054.

**API-01-056 · Phân tích tác động phụ thuộc**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/impact
```

Phản hồi `200`:

```json
{
  "impactLevel": "MEDIUM",
  "partial": false,
  "computedAt": "2026-11-26T10:00:00Z",
  "dependents": [
    {
      "type": "SUBSCRIPTION",
      "ref": "SUB-0099",
      "name": "Tra cứu hộ tịch cho dịch vụ công",
      "orgName": "Sở Thông tin và Truyền thông"
    }
  ]
}
```

**API-01-057 · Đề nghị thay đổi hồ sơ HTTT đã kết nạp**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/change-requests
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "changes": { "securityLevel": "L4", "securityApprovalRef": "QĐ 2210/QĐ-UBND ngày 05/11/2026" },
  "reason": "Nâng cấp độ ATTT theo quyết định mới"
}
```

Phản hồi `200`:

```json
{
  "applied": false,
  "changeRequest": {
    "id": "0194f2ca-7180-7377-90bb-8e9fa0b1c2d3",
    "changeClass": "FULL",
    "status": "PENDING",
    "reason": "Nâng cấp độ ATTT theo quyết định mới",
    "diff": {
      "securityLevel": { "from": "L3", "to": "L4" }
    },
    "requestedBy": "an.nv",
    "requestedAt": "2026-11-26T11:00:00Z"
  },
  "system": null
}
```

**API-01-058 · Danh sách đề nghị thay đổi**

```http
GET /api/onboarding/v1/systems/HT-TUPHAP/change-requests
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "id": "0194f2ca-7180-7377-90bb-8e9fa0b1c2d3",
      "changeClass": "FULL",
      "status": "PENDING",
      "reason": "Nâng cấp độ ATTT theo quyết định mới",
      "diff": {
        "securityLevel": { "from": "L3", "to": "L4" }
      },
      "requestedBy": "an.nv",
      "requestedAt": "2026-11-26T11:00:00Z"
    }
  ]
}
```

**API-01-059 · Duyệt hoặc từ chối đề nghị thay đổi, chấm dứt**

```http
POST /api/onboarding/v1/change-requests/0194f2ca-7180-7377-90bb-8e9fa0b1c2d3:decide
Content-Type: application/json

{ "decision": "APPROVE", "comment": "Đã đối chiếu quyết định phê duyệt cấp độ." }
```

Phản hồi `200`: cùng cấu trúc `ChangeRequestOutcome` như ở API-01-057.

**API-01-060 · Đề nghị mở rộng trần phạm vi khai thác**

```http
POST /api/onboarding/v1/systems/HT-TUPHAP/scope-expansions
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "demands": [
    {
      "direction": "CONSUME",
      "dataType": "THONG_TIN_DAT_DAI",
      "scopeRequested": "Tra cứu thửa đất phục vụ hộ tịch",
      "classification": "RESTRICTED",
      "purpose": "Xác minh nơi cư trú",
      "legalBasis": {
        "docNo": "NĐ 101/2024/NĐ-CP",
        "issuedOn": "2024-07-29",
        "issuer": "Chính phủ",
        "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d"
      }
    }
  ],
  "reason": "Bổ sung nhu cầu dữ liệu đất đai cho hộ tịch"
}
```

Phản hồi `202`: cùng cấu trúc `ChangeRequest` như ở API-01-053.

**Nội bộ (phân hệ khác)**

**API-01-062 · Chạy đối chiếu và phát ảnh chụp trạng thái**

```http
POST /api/onboarding/v1/internal/reconciliations
Content-Type: application/json

{
  "systemCodes": ["HT-TUPHAP"],
  "reason": "Đối chiếu sau sự cố Kafka"
}
```

Phản hồi `202` (tiêu đề `Location`):

```json
{
  "reconciliationId": "0194f2cb-8290-7488-91cc-9fa0b1c2d3e4",
  "batches": 1,
  "acceptedAt": "2026-11-26T12:00:00Z"
}
```

**API-01-063 · Bản sao đọc danh sách HTTT cho phân hệ khác**

```http
GET /api/onboarding/v1/internal/systems?updatedSince=2026-12-10T00:00:00Z&size=200
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "code": "HT-TUPHAP",
      "name": "Hệ thống quản lý hộ tịch",
      "ownerOrgId": "SO-TUPHAP",
      "status": "ACTIVE",
      "roles": ["CONSUMER", "PROVIDER"],
      "securityLevel": "L3",
      "group": 1,
      "baseUrls": ["https://hotich.tinh.example.gov.vn/api"],
      "clientIds": { "SANDBOX": "t68-ht-tuphap-sbx", "PRODUCTION": "t68-ht-tuphap-prd" },
      "activatedAt": "2026-12-10T03:00:00Z",
      "updatedAt": "2026-12-10T03:00:00Z",
      "ceilingDataTypes": ["THONG_TIN_CONG_DAN"]
    }
  ],
  "nextUpdatedSince": "2026-12-10T03:00:00Z",
  "page": { "number": 0, "size": 200, "totalElements": 1, "totalPages": 1 }
}
```

**API-01-064 · Bản sao đọc một HTTT cho phân hệ khác**

```http
GET /api/onboarding/v1/internal/systems/HT-TUPHAP
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "code": "HT-TUPHAP",
  "name": "Hệ thống quản lý hộ tịch",
  "ownerOrgId": "SO-TUPHAP",
  "status": "ACTIVE",
  "roles": ["CONSUMER", "PROVIDER"],
  "securityLevel": "L3",
  "group": 1,
  "baseUrls": ["https://hotich.tinh.example.gov.vn/api"],
  "clientIds": { "SANDBOX": "t68-ht-tuphap-sbx", "PRODUCTION": "t68-ht-tuphap-prd" },
  "activatedAt": "2026-12-10T03:00:00Z",
  "updatedAt": "2026-12-10T03:00:00Z",
  "ceilingDataTypes": ["THONG_TIN_CONG_DAN"]
}
```

**API-01-087 · Nhận kết quả bất đồng bộ của bước saga**

```http
POST /api/onboarding/v1/internal/provisioning-callbacks
Content-Type: application/json

{
  "sagaId": "0194f2c5-3d40-7f33-8c77-4a5b6c7d8e9f",
  "step": "CREATE_CLIENT",
  "outcome": "DONE",
  "externalRef": "kc-client-7f3a"
}
```

Phản hồi `200`:

```json
{
  "sagaId": "0194f2c5-3d40-7f33-8c77-4a5b6c7d8e9f",
  "step": "CREATE_CLIENT",
  "accepted": true,
  "duplicate": false
}
```

**Rà soát quyền định kỳ**

**API-01-065 · Mở kỳ rà soát quyền**

```http
POST /api/onboarding/v1/access-reviews
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "name": "Rà soát quyền định kỳ 6 tháng cuối 2026",
  "scope": "ALL_ACTIVE",
  "periodFrom": "2026-06-01",
  "periodTo": "2026-11-30"
}
```

Phản hồi `201` (tiêu đề `Location`):

```json
{
  "cycleCode": "RS-2026-02",
  "name": "Rà soát quyền định kỳ 6 tháng cuối 2026",
  "kind": "PERIODIC",
  "status": "OPEN",
  "periodFrom": "2026-06-01",
  "periodTo": "2026-11-30",
  "itemCount": 118,
  "confirmationsSent": 0,
  "confirmationsResponded": 0,
  "openedBy": "ta.lethi",
  "openedAt": "2026-12-01T01:00:00Z",
  "closedAt": null
}
```

**API-01-066 · Danh sách kỳ rà soát**

```http
GET /api/onboarding/v1/access-reviews
```

Phản hồi `200`: không có thân.

**API-01-067 · Chi tiết kỳ rà soát**

```http
GET /api/onboarding/v1/access-reviews/RS-2026-02
```

Phản hồi `200`: cùng cấu trúc `AccessReviewCycle` như ở API-01-065.

**API-01-068 · Mục rà soát và mức sử dụng**

```http
GET /api/onboarding/v1/access-reviews/RS-2026-02/items
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5",
      "systemCode": "HT-TUPHAP",
      "ownerOrgId": "SO-TUPHAP",
      "dataType": "THONG_TIN_CONG_DAN",
      "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC",
      "usageInPeriod": 0,
      "unusedDays": 210,
      "legalExpired": false,
      "flags": ["UNUSED"],
      "proposal": "NARROW",
      "ownerResponse": null,
      "decision": null,
      "usagePartial": false
    }
  ],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 },
  "usagePartial": false
}
```

**API-01-069 · Gửi phiếu xác nhận cho đơn vị chủ quản**

```http
POST /api/onboarding/v1/access-reviews/RS-2026-02:send-confirmations
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

Phản hồi `202` (tiêu đề `Location`):

```json
{
  "sent": 14,
  "skipped": 0,
  "orgsWithoutContact": []
}
```

**API-01-070 · Xem phiếu xác nhận của đơn vị**

```http
GET /api/onboarding/v1/access-review-confirmations/VIDU000000000000000000000000000000000000000
```

Phản hồi `200` (tiêu đề `Cache-Control`):

```json
{
  "orgId": "SO-TUPHAP",
  "orgName": "Sở Tư pháp",
  "cycleCode": "RS-2026-02",
  "expiresAt": "2027-01-02T00:00:00Z",
  "items": [
    {
      "itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5",
      "systemCode": "HT-TUPHAP",
      "dataType": "THONG_TIN_CONG_DAN",
      "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC",
      "usageInPeriod": 0,
      "unusedDays": 210
    }
  ]
}
```

**API-01-071 · Đơn vị trả lời phiếu xác nhận**

```http
POST /api/onboarding/v1/access-review-confirmations/VIDU000000000000000000000000000000000000000:respond
Content-Type: application/json

{
  "answers": [
    {
      "itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5",
      "answer": "REDUCE",
      "scopeReduced": "Chỉ tra cứu theo mã định danh",
      "note": "Chỉ còn dùng cho cấp giấy khai sinh"
    }
  ]
}
```

Phản hồi `200`:

```json
{ "answered": 1, "kept": 0, "reduced": 1, "released": 0 }
```

**API-01-072 · Quyết định thu hẹp hoặc thu hồi phạm vi**

```http
POST /api/onboarding/v1/access-reviews/RS-2026-02/items:decide
Content-Type: application/json

{
  "items": [
    {
      "itemId": "0194f2cc-93a0-7599-92dd-a0b1c2d3e4f5",
      "decision": "NARROW",
      "scopeNew": "Chỉ tra cứu theo mã định danh",
      "reason": "Đơn vị xác nhận thu hẹp, không dùng 210 ngày"
    }
  ]
}
```

Phản hồi `200`:

```json
{ "decided": 1, "kept": 0, "narrowed": 1, "revoked": 0, "cycleStatus": "DECIDING" }
```

**API-01-073 · Đánh dấu văn bản pháp lý hết hiệu lực**

```http
POST /api/onboarding/v1/scope-ceilings:mark-legal-expired
Content-Type: application/json

{ "docNo": "NĐ 47/2020/NĐ-CP", "repealedOn": "2026-01-01", "note": "Bị thay thế bởi NĐ 278/2025" }
```

Phản hồi `200`:

```json
{ "affectedCeilings": 3, "suspendedSystems": 1 }
```

**API-01-074 · Báo cáo rà soát quyền**

```http
GET /api/onboarding/v1/access-reviews/RS-2026-02/report
```

Phản hồi `200`:

```json
{
  "cycleCode": "RS-2026-02",
  "status": "CLOSED",
  "summary": { "items": 118, "kept": 90, "narrowed": 20, "revoked": 8, "noResponseOrgs": 2 },
  "evidenceHash": "4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce",
  "closedAt": "2026-12-20T09:00:00Z"
}
```

**API-01-075 · Xuất báo cáo rà soát quyền**

```http
POST /api/onboarding/v1/access-reviews/RS-2026-02/report:export
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
```

Phản hồi `202` (tiêu đề `Location`):

```json
{
  "jobId": "0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506",
  "status": "QUEUED",
  "statusUrl": "/api/onboarding/v1/jobs/0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506"
}
```

**Danh bạ đầu mối**

**API-01-076 · Tra cứu danh bạ đầu mối**

```http
GET /api/onboarding/v1/directory/contacts?q=nguyen&contactType=TECHNICAL
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e",
      "fullName": "Nguyễn Văn An",
      "position": "Chuyên viên CNTT",
      "phone": "+84912345678",
      "email": "an.nv@tuphap.tinh.example.gov.vn",
      "orgId": "SO-TUPHAP",
      "orgName": "Sở Tư pháp",
      "systemCode": "HT-TUPHAP",
      "systemName": "Hệ thống quản lý hộ tịch",
      "contactType": "TECHNICAL",
      "lastConfirmedAt": "2026-10-01T00:00:00Z"
    }
  ],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 }
}
```

**API-01-077 · Đầu mối của một tổ chức**

```http
GET /api/onboarding/v1/directory/organizations/SO-TUPHAP/contacts
```

Phản hồi `200`: cùng cấu trúc `DirectoryPage` như ở API-01-076.

**API-01-078 · Tổ chức thiếu đầu mối và đầu mối cần xác nhận**

```http
GET /api/onboarding/v1/directory/gaps
```

Phản hồi `200`:

```json
{
  "orgsWithoutTechnicalContact": [
    {
      "orgId": "UBND-XA-A",
      "orgName": "UBND xã A",
      "systemCodes": ["HT-XA-A"]
    }
  ],
  "staleContacts": [],
  "page": { "number": 0, "size": 20, "totalElements": 1, "totalPages": 1 }
}
```

**API-01-079 · Xuất danh bạ đầu mối**

```http
POST /api/onboarding/v1/directory/contacts:export
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "format": "XLSX",
  "purpose": "Báo cáo kiểm tra đầu mối quý IV",
  "filters": { "orgId": "SO-TUPHAP" }
}
```

Phản hồi `200`: cùng cấu trúc `JobAccepted` như ở API-01-075.

**Di trú, tham số, thống kê**

**API-01-080 · Tải tệp nhập HTTT từ hệ cũ**

```http
POST /api/onboarding/v1/legacy-imports
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: multipart/form-data  (phần `file`, `source`)
```

Phản hồi `201` (tiêu đề `Location`):

```json
{
  "jobId": "0194f2ce-b5c0-77bb-94ff-c2d3e4f50617",
  "source": "APIM_APPLICATION",
  "status": "PREVIEWED",
  "rowCount": 122,
  "created": 0,
  "skipped": 4,
  "warnings": 6,
  "secretsDropped": 120,
  "preview": [
    {
      "row": 2,
      "legacyRef": "APIM-APP-0042",
      "code": "HT-TUPHAP",
      "name": "Hệ thống quản lý hộ tịch",
      "matchedOrgId": "SO-TUPHAP",
      "action": "CREATE",
      "warning": null
    }
  ],
  "errorCode": null,
  "createdAt": "2026-12-03T02:00:00Z",
  "finishedAt": null
}
```

**API-01-081 · Kết quả xem trước và nhập hệ cũ**

```http
GET /api/onboarding/v1/legacy-imports/0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506
```

Phản hồi `200`: cùng cấu trúc `LegacyImportJob` như ở API-01-080.

**API-01-082 · Xác nhận tạo hồ sơ nháp từ tệp nhập**

```http
POST /api/onboarding/v1/legacy-imports/0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506:confirm
Content-Type: application/json

{
  "skipRows": [5, 9]
}
```

Phản hồi `200`: cùng cấu trúc `LegacyImportJob` như ở API-01-080.

**API-01-083 · Tham số `onboarding.*` của tenant**

```http
GET /api/onboarding/v1/settings
```

Phản hồi `200`:

```json
{
  "items": [
    {
      "key": "onboarding.review.slaWorkingDays",
      "value": 2,
      "default": 2,
      "min": 1,
      "max": 10,
      "platformCeiling": null,
      "description": "Hạn mỗi bước thẩm định (ngày làm việc)",
      "version": 3,
      "updatedAt": "2026-10-01T00:00:00Z",
      "updatedBy": "ta.lethi"
    }
  ]
}
```

**API-01-084 · Sửa một tham số của tenant**

```http
PUT /api/onboarding/v1/settings/onboarding.review.slaWorkingDays
Content-Type: application/json

{ "value": 3, "reason": "Quy chế tiếp nhận hồ sơ của tỉnh quy định 3 ngày" }
```

Phản hồi `200` (tiêu đề `ETag`):

```json
{
  "key": "onboarding.review.slaWorkingDays",
  "value": 3,
  "default": 2,
  "min": 1,
  "max": 10,
  "platformCeiling": null,
  "description": "Hạn mỗi bước thẩm định (ngày làm việc)",
  "version": 4,
  "updatedAt": "2026-12-03T03:00:00Z",
  "updatedBy": "ta.lethi"
}
```

**API-01-085 · Xuất danh sách HTTT thành viên**

```http
POST /api/onboarding/v1/systems:export
Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7
Content-Type: application/json

{
  "format": "XLSX",
  "purpose": "Báo cáo kiểm tra đầu mối quý IV",
  "filters": { "orgId": "SO-TUPHAP" }
}
```

Phản hồi `200`: cùng cấu trúc `JobAccepted` như ở API-01-075.

**API-01-086 · Thống kê kết nạp và thời gian xử lý**

```http
GET /api/onboarding/v1/statistics
```

Phản hồi `200`:

```json
{
  "from": "2026-09-01",
  "to": "2026-11-30",
  "byStatus": { "ACTIVE": 96, "SUBMITTED": 7, "DRAFT": 12 },
  "stageDurations": { "median": 9, "p90": 22 },
  "endToEnd": { "median": 40, "p90": 71, "kpi05Met": true },
  "returnRate": 0.18,
  "backlog": 7,
  "weekly": [
    { "week": "2026-W47", "submitted": 6, "approved": 4, "returned": 1, "rejected": 0 }
  ]
}
```

**API-01-088 · Tra tác vụ nền xuất tệp hoặc báo cáo**

```http
GET /api/onboarding/v1/jobs/0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506
```

Phản hồi `200`:

```json
{
  "jobId": "0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506",
  "kind": "EXPORT_CONTACTS",
  "status": "DONE",
  "createdAt": "2026-12-02T02:00:00Z",
  "finishedAt": "2026-12-02T02:00:09Z",
  "downloadUrl": "https://files.t68.datahub.example.vn/exports/0194f2cd.xlsx?sig=demo",
  "rowCount": 842,
  "errorCode": null
}
```
<!-- gen:examples:end -->

Ví dụ phản hồi lỗi theo RFC 9457 (xem thêm chương 6):

```json
{
  "type": "https://datahub.gov.vn/errors/ERR-01-008",
  "title": "Hồ sơ chưa đủ điều kiện nộp",
  "status": 422,
  "code": "ERR-01-008",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "detail": "Hồ sơ còn 1 thiếu sót.",
  "issues": [
    { "path": "dataDemands[1].legalBasis", "code": "ERR-01-015", "severity": "ERROR",
      "message": "Mục 'Thông tin thửa đất' chưa có căn cứ pháp lý",
      "guidance": "Bổ sung số, ngày, cơ quan ban hành văn bản cho phép khai thác dữ liệu." }
  ]
}
```

Ví dụ lệch `ETag` (API-01-005 gửi `If-Match: "13"` khi hồ sơ đã ở phiên bản 14):

```json
{
  "type": "https://datahub.gov.vn/errors/ERR-01-007",
  "title": "Hồ sơ đã bị sửa",
  "status": 412,
  "code": "ERR-01-007",
  "traceId": "00f067aa0ba902b79f5a3b1c2d3e4f50",
  "currentEtag": "\"14\""
}
```

### 3.2. Use case và API

Bảng nối 34 use case của [D02-04-PH01](../../02-yeu-cau/use-case/D02-04-PH01-use-case-ket-nap-httt.md) với API và sự kiện hiện thực; đây là bảng để kiểm thử viên chọn API cho từng ca.

| Use case | API hiện thực | Sự kiện |
|---|---|---|
| UC-01-01 | API-01-001, 002, 003, 085, 088 | Không |
| UC-01-02 | API-01-004, 005, 020, 021 | EVT-01-03 |
| UC-01-03 | API-01-010, 011 | Không |
| UC-01-04 | API-01-006, 007, 008, 009, 012, 013 | Không |
| UC-01-05 | API-01-014, 015, 016, 017 | EVT-01-13 |
| UC-01-06 | API-01-022, 023 | EVT-01-01, 03 |
| UC-01-07 | API-01-018, 019, 034 | EVT-01-03 |
| UC-01-08 | API-01-027, 028, 029, 030 | EVT-01-02 |
| UC-01-09 | API-01-024, 026 | EVT-01-02 |
| UC-01-10 | API-01-025 | EVT-01-02 |
| UC-01-11 | API-01-031, 023 | EVT-01-02, 03 |
| UC-01-12 | API-01-032, 033 | EVT-01-02, 03, 11 |
| UC-01-13 | API-01-035, 036, 087 | EVT-01-05 |
| UC-01-14 | API-01-037, 038 | EVT-01-05, 06 |
| UC-01-15 | API-01-039, 040, 041 | EVT-01-09, 10 |
| UC-01-16 | API-01-042, 043 | Không |
| UC-01-17 | API-01-044 | EVT-01-03, 05 |
| UC-01-18 | API-01-045, 046 | EVT-01-06 |
| UC-01-19 | API-01-047, 048, 049, 050 | EVT-01-07, 08 |
| UC-01-20 | API-01-051, 052, 056 | EVT-01-03, 07 |
| UC-01-21 | API-01-053, 056, 059 | EVT-01-03, 07, 11 |
| UC-01-22 | API-01-054, 055 | EVT-01-15, 03, 07 |
| UC-01-23 | API-01-057, 058, 059 | EVT-01-04 |
| UC-01-24 | API-01-060 | EVT-01-11 |
| UC-01-25 | API-01-061 | EVT-01-07 |
| UC-01-26 | API-01-062, 063, 064 | EVT-01-03, 04, 11 |
| UC-01-27 | API-01-065, 066, 067, 068, 073 | EVT-01-11 |
| UC-01-28 | API-01-069, 070, 071 | Không |
| UC-01-29 | API-01-072, 074, 075, 088 | EVT-01-11, 12 |
| UC-01-30 | API-01-076, 077, 079, 088 | Không |
| UC-01-31 | API-01-078 | EVT-01-14 |
| UC-01-32 | API-01-080, 081, 082 | Không |
| UC-01-33 | API-01-083, 084 | Không |
| UC-01-34 | API-01-086 | Không |

: Use case, API và sự kiện

API-01-088 (do tập này thêm) được ghi thêm vào UC-01-01, UC-01-29 và UC-01-30 vì cả ba có xuất tệp chạy nền; API-01-087 được ghi thêm vào UC-01-13. Hai thay đổi này cần UC đồng bộ ở đợt cuối (chương 11).

## 4. Danh mục sự kiện

PH-01 phát 15 sự kiện qua Kafka để các phân hệ khác biết trạng thái HTTT chỉ từ một nguồn, không đọc chéo cơ sở dữ liệu: PH-10 tạm ngừng bên phát, bên nhận; PH-02 tạm ngừng đăng ký sử dụng; PH-04, PH-05 cập nhật bản sao `external_system`; PH-03 cập nhật consumer; PH-13 theo dõi và kiểm toán. Cơ chế phát là **outbox**: sự kiện ghi vào bảng `ph01_onboarding.outbox` trong cùng giao dịch với thay đổi (ADR-042), Debezium đọc nhật ký ghi trước (hoặc `OutboxRelay` quét lô mỗi 500 ms ở quy mô `QM-NHO`) rồi đưa lên Kafka. Nhờ đó không mất sự kiện khi `dh-connect` hỏng giữa chừng, và p95 từ commit đến Kafka ≤ 5 giây (NFR-01-021).

Quy ước sự kiện:

| Mục | Quy ước |
|---|---|
| Topic | `{tenant}.connect.{thực-thể}.{sự-kiện}.v1`, chữ thường, tiền tố tenant (ví dụ `t68.connect.system.state-changed.v1`); ACL Kafka theo tenant |
| Khung | CloudEvents 1.0 chế độ nhị phân (tiêu đề `ce_*`), thân JSON; `ce_id` duy nhất, `traceparent` xuyên suốt |
| Khóa bản ghi | `systemCode` (EVT-01-12 là mã kỳ `RS-…`, EVT-01-14 là mã tổ chức) nên mọi thay đổi của một HTTT đến đúng thứ tự |
| Phân vùng, giữ | 3 phân vùng, giữ 7 ngày (giả định theo mẫu PH-05, chốt ở D03-09); 7 ngày đủ phát bù sau sự cố cuối tuần |
| Nội dung | Không có bí mật, `secret_ref`, liên kết bàn giao, dữ liệu liên hệ cá nhân; ca kiểm thử canary `DH-CANARY-…` quét (NFR-01-009) |
| Bên nhận | Xử lý lũy đẳng theo `(systemCode, updatedAt)` hoặc `version`, bỏ qua bản cũ hơn bản đang giữ |
| Ảnh chụp đối chiếu | Mỗi giờ phát EVT-01-03 với `snapshot = true` theo lô 200 bản ghi để bù sự kiện lỡ; bên nhận so với bản sao của mình và sửa lệch (API-01-062 để chạy theo yêu cầu) |

: Quy ước sự kiện của PH-01

### 4.1. Bảng sự kiện

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Khóa | Phân vùng, giữ | Bên tiêu thụ |
|---|---|---|---|---|---|
| EVT-01-01 | `{tenant}.connect.system.submitted.v1` | Hồ sơ được nộp hoặc nộp lại (FR-01-012). | `systemCode` | 3, 7 ngày | PH-13, PH-18 |
| EVT-01-02 | `{tenant}.connect.review.decided.v1` | Bước thẩm định hoàn tất, phân công, tham vấn, trả bổ sung, phê duyệt hoặc từ chối (FR-01-013…018). | `systemCode` | 3, 7 ngày | PH-13, PH-18 |
| EVT-01-03 | `{tenant}.connect.system.state-changed.v1` | Mọi chuyển trạng thái HTTT; ảnh chụp đối chiếu hằng giờ có `snapshot = true` (FR-01-037). Có hiệu lực ở bên nhận trong ≤ 60 giây (NFR-01-008). | `systemCode` | 3, 7 ngày | PH-10, PH-02, PH-04, PH-05, PH-03, PH-13 |
| EVT-01-04 | `{tenant}.connect.system.updated.v1` | Đổi thuộc tính: cấp độ ATTT, địa chỉ, IP, chủ quản, vai trò (FR-01-034). | `systemCode` | 3, 7 ngày | PH-10, PH-04, PH-05, PH-03 |
| EVT-01-05 | `{tenant}.connect.credential.issued.v1` | Cấp định danh SANDBOX, PRODUCTION (FR-01-020, 024). Không có `secret_ref`, không có bí mật. | `systemCode` | 3, 7 ngày | PH-03, PH-10, PH-13 |
| EVT-01-06 | `{tenant}.connect.credential.rotated.v1` | Bắt đầu, kết thúc xoay vòng; đăng ký khóa mới (FR-01-021, 025). | `systemCode` | 3, 7 ngày | PH-03, PH-10 |
| EVT-01-07 | `{tenant}.connect.credential.revoked.v1` | Thu hồi, hết hạn, tự vô hiệu (FR-01-026, 027, 029, 036). `reversible` cho biết có bật lại được không. | `systemCode` | 3, 7 ngày | PH-03, PH-10, PH-13 |
| EVT-01-08 | `{tenant}.connect.credential.expiring.v1` | Còn 30, 14, 7 ngày tới hạn (FR-01-027). | `systemCode` | 3, 7 ngày | PH-13, PH-18 |
| EVT-01-09 | `{tenant}.connect.handover.opened.v1` | Đầu mối mở liên kết bàn giao thành công (FR-01-022). | `systemCode` | 3, 7 ngày | PH-13 |
| EVT-01-10 | `{tenant}.connect.handover.security-alert.v1` | Sai người mở liên kết, mở sai nhiều lần, liên kết bị khóa (FR-01-022). | `systemCode` | 3, 7 ngày | PH-13, SO |
| EVT-01-11 | `{tenant}.connect.scope-ceiling.changed.v1` | Trần phạm vi tạo, mở rộng, thu hẹp, tạm ngừng, thu hồi (FR-01-018, 031, 035, 042, 043). PH-02 hủy đăng ký vượt trần rồi gọi API-12-068 thay tập scope. | `systemCode` | 3, 7 ngày | PH-02, PH-13 |
| EVT-01-12 | `{tenant}.connect.access-review.completed.v1` | Kỳ rà soát quyền đóng (FR-01-042). | Mã kỳ `RS-…` | 3, 7 ngày | PH-13, PH-18 |
| EVT-01-13 | `{tenant}.connect.contact.changed.v1` | Thêm, sửa, thay thế, vô hiệu đầu mối. **Không kèm dữ liệu liên hệ cá nhân**, chỉ mã HTTT, loại, mã đầu mối (FR-01-008). | `systemCode` | 3, 7 ngày | PH-18, PH-13 |
| EVT-01-14 | `{tenant}.connect.directory.gap-detected.v1` | Phát hiện tổ chức thiếu đầu mối kỹ thuật (FR-01-046). | Mã tổ chức | 3, 7 ngày | PH-13, PH-18 |
| EVT-01-15 | `{tenant}.connect.emergency-action.recorded.v1` | Thao tác khẩn của SO, xác nhận, quá hạn xác nhận (FR-01-032). Sự kiện an ninh. | `systemCode` | 3, 7 ngày | PH-13, TA, PO |

: Sự kiện phát ra của PH-01 (EVT-01-01…15)

### 4.2. Nội dung từng sự kiện

Bảng dưới liệt kê trường của từng sự kiện (dấu * là bắt buộc), lấy từ [`asyncapi-onboarding.yaml`](ph01/asyncapi-onboarding.yaml); ví dụ JSON dùng dữ liệu giả lập.

**EVT-01-01 · `system.submitted.v1`.** `tenantId`*, `systemCode`*, `applicationNo`*, `ownerOrgId`, `revisionNo`*, `resubmitted`, `submittedBy`, `submittedAt`*, `steps`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "applicationNo": "KN-2026-000123",
  "ownerOrgId": "SO-TUPHAP",
  "revisionNo": 1,
  "resubmitted": false,
  "submittedBy": "an.nv",
  "submittedAt": "2026-11-26T09:00:00Z",
  "steps": [
    { "stepType": "TECHNICAL", "dueAt": "2026-11-30T10:00:00Z" },
    { "stepType": "SECURITY", "dueAt": "2026-11-30T10:00:00Z" }
  ]
}
```

**EVT-01-02 · `review.decided.v1`.** `tenantId`*, `systemCode`*, `applicationNo`, `revisionNo`, `kind`*, `stepType`, `result`, `assigneeId`, `actor`*, `at`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "applicationNo": "KN-2026-000123",
  "revisionNo": 1,
  "kind": "STEP_DONE",
  "stepType": "TECHNICAL",
  "result": "PASS",
  "assigneeId": "ie.tranb",
  "actor": { "userId": "ie.tranb", "type": "USER" },
  "at": "2026-11-27T03:00:00Z"
}
```

**EVT-01-03 · `system.state-changed.v1`.** `tenantId`*, `systemCode`*, `name`, `ownerOrgId`, `from`, `to`*, `reviewStage`, `provisionStage`, `reasonCode`, `reason`, `emergency`, `snapshot`*, `roles`, `securityLevel`, `group`, `ceilingDataTypes`, `version`*, `updatedAt`*, `actor`.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "name": "Hệ thống quản lý hộ tịch",
  "ownerOrgId": "SO-TUPHAP",
  "from": "ACTIVE",
  "to": "SUSPENDED",
  "reviewStage": null,
  "provisionStage": null,
  "reasonCode": "OVERLOAD",
  "reason": "Tăng đột biến lưu lượng làm quá tải cổng",
  "emergency": false,
  "snapshot": false,
  "roles": ["CONSUMER", "PROVIDER"],
  "securityLevel": "L3",
  "group": 1,
  "ceilingDataTypes": ["THONG_TIN_CONG_DAN"],
  "version": 14,
  "updatedAt": "2026-12-12T02:00:00Z",
  "actor": { "userId": "an.nv", "type": "USER" }
}
```

**EVT-01-04 · `system.updated.v1`.** `tenantId`*, `systemCode`*, `changedFields`*, `securityLevel`, `ownerOrgId`, `roles`, `baseUrls`, `ipAllowlist`, `version`*, `updatedAt`*, `actor`.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "changedFields": ["baseUrls", "ipAllowlist"],
  "securityLevel": "L3",
  "ownerOrgId": "SO-TUPHAP",
  "roles": ["CONSUMER", "PROVIDER"],
  "baseUrls": ["https://hotich.tinh.example.gov.vn/api/v2"],
  "ipAllowlist": ["10.20.0.0/24", "10.20.1.0/24"],
  "version": 15,
  "updatedAt": "2026-12-13T02:00:00Z",
  "actor": { "userId": "an.nv", "type": "USER" }
}
```

**EVT-01-05 · `credential.issued.v1`.** `tenantId`*, `systemCode`*, `credentialId`*, `environment`*, `authMethod`*, `clientId`*, `expiresAt`, `issuedAt`*, `actor`.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "credentialId": "cr-0194f2c6",
  "environment": "SANDBOX",
  "authMethod": "PRIVATE_KEY_JWT",
  "clientId": "t68-ht-tuphap-sbx",
  "expiresAt": "2027-11-26T00:00:00Z",
  "issuedAt": "2026-11-27T04:00:20Z",
  "actor": { "userId": "system:onboarding", "type": "SYSTEM" }
}
```

**EVT-01-06 · `credential.rotated.v1`.** `tenantId`*, `systemCode`*, `credentialId`*, `environment`*, `phase`*, `rotationEndsAt`, `kid`, `certFingerprint`, `incident`, `at`*, `actor`.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "credentialId": "cr-0194f2c6",
  "environment": "PRODUCTION",
  "phase": "STARTED",
  "rotationEndsAt": "2026-12-05T00:00:00Z",
  "kid": null,
  "certFingerprint": null,
  "incident": false,
  "at": "2026-11-28T04:10:00Z",
  "actor": { "userId": "an.nv", "type": "USER" }
}
```

**EVT-01-07 · `credential.revoked.v1`.** `tenantId`*, `systemCode`*, `credentialId`*, `environment`*, `to`*, `reason`*, `reversible`*, `at`*, `actor`.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "credentialId": "cr-0194f2c6",
  "environment": "PRODUCTION",
  "to": "REVOKED",
  "reason": "EMERGENCY",
  "reversible": false,
  "at": "2026-11-29T02:00:00Z",
  "actor": { "userId": "an.nv", "type": "USER" }
}
```

**EVT-01-08 · `credential.expiring.v1`.** `tenantId`*, `systemCode`*, `credentialId`*, `environment`, `expiresAt`*, `daysLeft`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "credentialId": "cr-0194f2c6",
  "environment": "PRODUCTION",
  "expiresAt": "2027-01-05T00:00:00Z",
  "daysLeft": 30
}
```

**EVT-01-09 · `handover.opened.v1`.** `tenantId`*, `systemCode`*, `credentialId`, `handoverId`*, `openedBy`*, `openedAt`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "credentialId": "cr-0194f2c6",
  "handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0",
  "openedBy": "an.nv",
  "openedAt": "2026-11-27T05:30:00Z"
}
```

**EVT-01-10 · `handover.security-alert.v1`.** `tenantId`*, `systemCode`*, `credentialId`, `handoverId`*, `alertType`*, `failedAttempts`*, `attemptedBy`, `locked`*, `at`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "credentialId": "cr-0194f2c6",
  "handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0",
  "alertType": "WRONG_RECIPIENT",
  "failedAttempts": 1,
  "attemptedBy": "user.khac",
  "locked": false,
  "at": "2026-11-27T05:20:00Z"
}
```

**EVT-01-11 · `scope-ceiling.changed.v1`.** `tenantId`*, `systemCode`*, `change`*, `ceiling`*, `reason`, `version`*, `at`*, `actor`.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "change": "CREATED",
  "ceiling": [
    {
      "dataType": "THONG_TIN_CONG_DAN",
      "scopeApproved": "Chỉ tra cứu phục vụ giải quyết TTHC",
      "classification": "RESTRICTED",
      "validUntil": null
    }
  ],
  "reason": null,
  "version": 1,
  "at": "2026-11-27T04:00:00Z",
  "actor": { "userId": "an.nv", "type": "USER" }
}
```

**EVT-01-12 · `access-review.completed.v1`.** `tenantId`*, `cycleCode`*, `kind`, `itemCount`*, `kept`, `narrowed`, `revoked`, `noResponseOrgs`, `evidenceHash`*, `closedAt`*, `closedBy`.

```json
{
  "tenantId": "T68",
  "cycleCode": "RS-2026-02",
  "kind": "PERIODIC",
  "itemCount": 118,
  "kept": 90,
  "narrowed": 20,
  "revoked": 8,
  "noResponseOrgs": 2,
  "evidenceHash": "4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce",
  "closedAt": "2026-12-20T09:00:00Z",
  "closedBy": "ta.lethi"
}
```

**EVT-01-13 · `contact.changed.v1`.** `tenantId`*, `systemCode`*, `contactId`, `contactType`*, `change`*, `orgId`, `at`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e",
  "contactType": "TECHNICAL",
  "change": "ADDED",
  "orgId": "SO-TUPHAP",
  "at": "2026-11-26T09:00:00Z"
}
```

**EVT-01-14 · `directory.gap-detected.v1`.** `tenantId`*, `orgId`*, `systemCodes`*, `missing`*, `detectedAt`*.

```json
{
  "tenantId": "T68",
  "orgId": "UBND-XA-A",
  "systemCodes": ["HT-XA-A"],
  "missing": "TECHNICAL_CONTACT",
  "detectedAt": "2026-12-01T01:00:00Z"
}
```

**EVT-01-15 · `emergency-action.recorded.v1`.** `tenantId`*, `systemCode`*, `actionId`*, `stage`*, `mode`*, `performedBy`*, `confirmBy`*, `confirmedBy`, `incidentRef`, `at`*.

```json
{
  "tenantId": "T68",
  "systemCode": "HT-TUPHAP",
  "actionId": "0194f2c9-6070-7266-8faa-7d8e9fa0b1c2",
  "stage": "PERFORMED",
  "mode": "SUSPEND",
  "performedBy": "so.phamc",
  "confirmBy": "2026-11-30T02:00:00Z",
  "confirmedBy": null,
  "incidentRef": "INC-2026-0412",
  "at": "2026-11-29T02:00:00Z"
}
```
<!-- gen:events:end -->

### 4.3. Chính sách tương thích

Hợp đồng sự kiện đăng ký ở Apicurio với chế độ tương thích `BACKWARD` (NFR-01-019). Trong `v1` chỉ được thêm trường tùy chọn; đổi tên, xóa trường, đổi kiểu hay đổi ý nghĩa enum là thay đổi phá vỡ và phải sang `v2` với topic mới chạy song song ≥ 6 tháng. Bên nhận bỏ qua trường lạ và phải chịu được giá trị enum mới (xử lý như "không rõ", không hỏng). CI-5 chạy kiểm tương thích lược đồ so với `main` bằng chính tệp AsyncAPI.

Hai sự kiện có vai trò an ninh: EVT-01-10 (sai người mở liên kết bàn giao) và EVT-01-15 (thao tác khẩn) đi tới PH-13 và SIEM; Cán bộ ATTT nhận cảnh báo ở `SO`. EVT-01-03 là sự kiện bên nhận phải xử lý đáng tin nhất vì mang hiệu lực cắt quyền: tạm ngừng khẩn vẫn có hiệu lực ngay ở cổng nhờ danh sách chặn của PH-03 (chương 5) chứ không chờ sự kiện.

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-01 đứng giữa người dùng, các phân hệ nền (PH-12 định danh, PH-03 cổng API, OpenBao) và các phân hệ tiêu thụ (PH-02, 04, 05, 10, 13, 14, 15). Chương này nêu hợp đồng ở hai chiều: PH-01 cần gì ở phân hệ khác, và phân hệ khác gọi PH-01 những gì. Giao diện của phân hệ khác do tập của phân hệ đó đặc tả; tên gọi ở đây là **giao diện PH-01 cần** (Q01-03 của FRS, ghi ở chương 11 để các phân hệ cung cấp).

```{.mermaid caption="Các bên gọi và các hệ PH-01 gọi"}
flowchart TB
  U[Người dùng qua BFF console] -->|API-01-001 đến 086| C[dh-connect module onboarding]
  P[PH-02, 03, 04, 05, 10, 13, 14, 15] -->|API-01-062, 063, 064| C
  CB[PH-12 và PH-03 trả kết quả saga] -->|API-01-087| C
  C -->|client, token, khóa| P12[PH-12 Keycloak và OPA]
  C -->|consumer, chặn client| P03[PH-03 APISIX]
  C -->|bọc, mở bọc, ký CSR| OB[OpenBao]
  C -->|mức dùng, hạn mức, thông báo| X[PH-13, PH-14, PH-02, PH-18, PH-20]
  C -->|outbox EVT-01-01 đến 15| K[Kafka]
```

Hình trên cho thấy `dh-connect` chỉ có ba cửa vào (người dùng, phân hệ đọc bản sao, callback) và bốn nhóm cửa ra. Mọi lời gọi ra là lưu lượng đông–tây trong cụm qua mTLS của mesh (SEC-14, SEC-15); PH-01 không có đường ra Internet, thư thông báo đi qua PH-18.

### 5.1. PH-01 gọi phân hệ khác

Bảng nêu từng hệ PH-01 phụ thuộc, giao diện cần dùng, cách chống trùng khi thử lại, thời gian chờ và cách PH-01 xử lý khi hệ đó lỗi. Số liệu chờ, thử lại lấy từ SDD §8.3.

| Hệ | Giao diện PH-01 cần | Lũy đẳng | Chờ, thử lại, ngắt mạch | Khi lỗi |
|---|---|---|---|---|
| PH-12 (Keycloak, OPA) | Tạo client (API-12-058; `clientId = {tenant}-{systemCode}-sbx` hoặc `-prd`), sửa client (API-12-059), vô hiệu, tiếp tục, thu hồi client (API-12-060, 061, 062), thu hồi token, đăng ký khóa mTLS (API-12-064), bắt đầu xoay bí mật (PH-01 không gọi API-12-068: PH-02 nghe EVT-01-11 rồi thay tập scope) | `Idempotency-Key = {sagaId}:{bước}` hoặc `{enforcementId}:{loại}` | 10 giây (tạo), 5 giây (vô hiệu, thu hồi); saga lùi 1, 2, 4, 8, 15 phút tới 24 giờ; ngắt mạch 50% trên 20 lượt, **không** ngắt đường cắt quyền | ERR-01-021 (503) giữ hồ sơ `APPROVED` và thử lại; client trùng ERR-01-022 (409) dừng saga, cảnh báo TA |
| PH-03 (APISIX) | Tạo, xóa, vô hiệu consumer; chặn client ≤ 60 giây; bỏ chặn; hạn mức; danh sách IP | Như trên | 10, 5, 5 giây; chặn luôn thử, không ngắt mạch | Bước saga `FAILED` tạm thời rồi thử lại; cắt quyền thử tới khi xong, cảnh báo sau 60 giây |
| OpenBao | Bọc bí mật theo TTL, mở bọc (một lần), hủy phiên bản, ký CSR (`pki-clients`), transit mã hóa, giải mã | Bọc theo `secretRef`; mở bọc **không thử lại** | 2 giây, 2 lần (200 ms, 400 ms); mở bọc 5 giây; ngắt mạch 50% trên 10 lượt | ERR-01-023 (503), liên kết bàn giao chưa bị tiêu hao |
| PH-13 | `sandboxActivity`, `usageByCredential`, `usageByScope` | Đọc | 3 giây, 1 lần; ngắt mạch thì kết quả `partial` | `partial = true` ở API-01-042, 068; không chặn |
| PH-14 | `remainingQuota` theo dịch vụ quốc gia | Đọc | 3 giây, 1 lần | `partial = true` ở API-01-026 |
| PH-02 | `ServiceUsageApi`: đăng ký sử dụng, phụ thuộc theo HTTT | Đọc | 3 giây, 1 lần | `partial = true` ở API-01-056 |
| PH-18 | `NotificationApi` (thư, hộp việc), `WorkingCalendarApi` (lịch nghỉ), `ParameterApi` (`onboarding.*`, đệm 60 giây) | Thư theo `notify_outbox` | 3 giây, 3 lần (1, 2, 4 giây), còn lỗi thử tới 24 giờ | Không làm hỏng giao dịch nghiệp vụ; thư mang liên kết gửi đồng bộ, lỗi thì người dùng bấm "Tạo lại liên kết" (Q01-52 của CSDL) |
| PH-20 | Tra tổ chức (DD-02), `TenantRegistry`, sự kiện đổi tổ chức | Đọc | 3 giây, 1 lần, đệm 24 giờ | ERR-01-004 khi tổ chức không có; ERR-01-046 khi hết đệm |
| Garage (kho tệp) | Lưu tệp theo bucket tenant, liên kết ký | Theo `sha256` | 5 giây, 2 lần | ERR-01-046 |
| Dịch vụ quét mã độc | Quét tệp trước khi nhận | Không | 20 giây, không thử lại | Tệp `PENDING`, không nộp được; nhiễm thì ERR-01-014 |
| Danh mục `dataType` (PH-07 hoặc PH-09) | Kiểm `dataType` của nhu cầu | Đọc | 3 giây, đệm 24 giờ | Hết đệm thì không thêm mục mới (Q01-16 của FRS) |

: Hợp đồng PH-01 gọi phân hệ khác

Nguyên tắc chung: lời gọi ra từ saga và cắt quyền do bộ chạy thử lại chứ không do bộ chuyển (tránh nhân lượt thử); không bao giờ hoàn tác trạng thái cắt quyền, chỉ thử lại việc cắt; không tiêu hao liên kết bàn giao khi OpenBao lỗi (SDD §8.3, §8.4).

### 5.2. Phân hệ khác gọi PH-01

Phân hệ khác gọi PH-01 qua hai đường: trong tiến trình khi cùng đơn vị triển khai `dh-connect`, và REST với token dịch vụ khi ở đơn vị khác.

| Bên gọi | API | Scope | Mục đích | Tần suất (giả định) |
|---|---|---|---|---|
| PH-02, PH-03 (cùng DU `dh-connect`) | `MemberSystemQueryApi` trong tiến trình, cùng cấu trúc với API-01-063, 064; PH-02 còn `checkWithinCeiling` kiểm đăng ký sử dụng không vượt trần (Q01-02) | Không cần (cùng tiến trình) | Tra HTTT khi đăng ký sử dụng, khi tạo consumer | Theo lượt đăng ký, không đáng kể |
| PH-04, PH-05, PH-10, PH-13, PH-14, PH-15 | API-01-063, 064; PH-15 còn hai API đọc nội bộ về lược đồ biểu mẫu kết nạp và định danh production chỉ đọc (mã cấp số tiếp theo sau API-01-088, bổ sung hợp đồng ở Đợt 2 cùng PH-15; đã chốt 27/11/2026) | `onboarding:internal-read` | Khởi tạo và đối chiếu bản sao `external_system`; xác minh bên phát, bên nhận, bên gọi | Khởi tạo một lần, đối chiếu ≤ 1 lần mỗi giờ mỗi phân hệ; cơ sở: bản sao ≤ 1.000 HTTT, 2 trang 500 dòng |
| PH-12, PH-03 | API-01-087 | `onboarding:provision-callback` | Trả kết quả bước saga khi chọn kiểu bất đồng bộ | Mỗi bước một lần, chờ tối đa 5 phút (giả định) |
| Tác vụ đối chiếu, vận hành | API-01-062 | `onboarding:reconcile` | Phát ảnh chụp theo yêu cầu sau sự cố | Hiếm |

: Hợp đồng phân hệ khác gọi PH-01

Phân hệ nghe thay đổi dùng sự kiện (chương 4) thay vì gọi lại API; API đọc bản sao chỉ dùng khi khởi tạo và đối chiếu. Bản ghi trả về là bản rút gọn `ReplicaSystem` (cùng cấu trúc với `MemberSystemView` ở SDD §3.2): không có liên hệ cá nhân, bí mật, `secret_ref`, nội dung hồ sơ (BR-01-030).

### 5.3. Sự kiện PH-01 tiêu thụ

PH-01 tiêu thụ ba loại sự kiện và không đăng ký mã mới; tên topic do phân hệ phát chốt ở D03-04 của phân hệ đó (Q01-13). Xử lý lũy đẳng nhờ bảng `inbox(event_id)` duy nhất, giữ 30 ngày.

| Nguồn | Sự kiện | PH-01 làm gì |
|---|---|---|
| PH-12 | Tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức | Đặt `hasAccount = false` và đầu mối `INACTIVE` nếu đổi tổ chức; phát EVT-01-13; nhắc TA, và nếu đó là đầu mối kỹ thuật cuối cùng thì ghi vào danh sách thiếu đầu mối (API-01-078) |
| PH-18 | Thư thông báo bị trả lại | Đánh dấu đầu mối cần xác nhận lại thư điện tử; hiện ở API-01-078 (`staleContacts`) |
| PH-20 | Tenant bị tạm ngừng | Không đổi trạng thái từng HTTT (PH-03 chặn ở mức tenant); dừng tác vụ định kỳ của tenant |

: Sự kiện PH-01 tiêu thụ

### 5.4. Hợp đồng với bên ngoài

PH-01 **không có hợp đồng trực tiếp** với NDXP, NDOP, PayGov hay dịch vụ NGSP: kết nạp là việc nội bộ của tenant. Ba điểm liên quan:

- **HTTT loại `NATIONAL`, `MINISTRY`, `EXTERNAL`** (của bộ, ngành, nhà cung cấp ngoài tỉnh) không có tổ chức thuộc tenant nên không tự nộp được; TA nhập hộ qua API-01-004 với văn bản của bộ, ngành làm căn cứ (đề xuất Q01-11 của FRS).
- **HTTT thành viên** không gọi API của PH-01. Thông tin kết nối (điểm cuối token, địa chỉ API, phương thức xác thực, hạn mức) HTTT nhận qua trang bàn giao (API-01-040) và qua hướng dẫn kết nối `huongDan`; sau đó gọi cổng API (PH-03) bằng định danh đã cấp.
- **Chữ ký số của văn bản đề nghị** hiện chỉ tải lên dạng tệp và người thẩm định kiểm bằng mắt; kiểm chữ ký tự động phụ thuộc hạ tầng chữ ký số của tỉnh (Q01-04 của FRS).

### 5.5. Trình tự các luồng chính qua API

Luồng thứ nhất là luồng dài nhất của phân hệ: từ nộp hồ sơ tới khi đầu mối nhận được thông tin xác thực. Hình dưới gắn mỗi bước với mã API.

```{.mermaid caption="Trình tự nộp, thẩm định, phê duyệt, cấp định danh và bàn giao"}
sequenceDiagram
  autonumber
  participant OR as Đơn vị (OR)
  participant ON as dh-connect (onboarding)
  participant RV as IE, SO, TA
  participant S as Bộ chạy saga
  participant EX as PH-12, PH-03, OpenBao
  participant HT as Đầu mối kỹ thuật
  OR->>ON: API-01-023 nộp hồ sơ, If-Match, Idempotency-Key
  ON-->>OR: 200 SUBMITTED kèm ba bước thẩm định
  Note over ON: Cùng giao dịch ghi trạng thái, ba bước, outbox EVT-01-01 và 03
  RV->>ON: API-01-024, 025 kết luận thẩm định theo phân công
  RV->>ON: API-01-032 TA phê duyệt, không phải người đã thẩm định
  ON-->>RV: 200 APPROVED, provisionStage PROVISIONING
  S->>EX: tạo client, consumer, bọc bí mật, khóa lũy đẳng sagaId và bước
  EX-->>S: kết quả từng bước, lỗi thì bù trừ và thử lại
  S->>OR: thư chỉ có liên kết bàn giao, qua PH-18
  HT->>ON: API-01-040 mở liên kết, đăng nhập đúng tài khoản, hai yếu tố
  ON->>EX: mở bọc một lần rồi hủy bản sao
  ON-->>HT: 200 clientSecret một lần, Cache-Control no-store
  Note over ON: EVT-01-05 cấp định danh, EVT-01-09 đã mở bàn giao
```

Điều cần thấy ở hình: người gọi chỉ thấy các phản hồi `200` đồng bộ ở bước 2, 5 và 11; mọi bước nói chuyện với PH-12, PH-03, OpenBao nằm trong bộ chạy saga (bước 6, 7), nên PH-12 chậm hay lỗi không làm hỏng lệnh phê duyệt, chỉ làm `provisionStage` chậm lên `SANDBOX_READY` (người dùng xem tiến độ ở API-01-036). Bí mật chỉ xuất hiện ở bước 11 và không đi qua thư (bước 8).

Luồng thứ hai là đường cắt quyền khẩn cấp, nơi tốc độ quan trọng hơn thủ tục.

```{.mermaid caption="Trình tự thao tác khẩn cấp của Cán bộ ATTT và cắt quyền trong 60 giây"}
sequenceDiagram
  autonumber
  participant SO as Cán bộ ATTT
  participant ON as dh-connect (onboarding)
  participant GW as PH-03 APISIX
  participant ID as PH-12
  participant TA as Quản trị tỉnh
  SO->>ON: API-01-054 tạm ngừng khẩn, lý do, xác thực lại hai yếu tố
  Note over ON: Cùng giao dịch đặt SUSPENDED, bốn việc cắt quyền, outbox EVT-01-15, 03, 07
  ON-->>SO: 200 PENDING_CONFIRM, enforcement PENDING
  ON->>GW: chặn client vào danh sách chặn, hạn 5 giây
  ON->>ID: vô hiệu client, thu hồi token
  GW-->>ON: đã chặn, thử lại tới khi xong
  Note over GW: Cổng từ chối HTTT trong 60 giây, ACL Kafka trong 2 phút
  TA->>ON: API-01-055 xác nhận trong hạn emergency.confirmHours
  ON-->>TA: 200 CONFIRMED
```

Điều cần thấy: trạng thái `SUSPENDED` được đặt **trước**, rồi việc cắt chạy lặp tới khi xong (không hoàn tác, không chờ sự kiện); `If-Match` không bắt buộc để Cán bộ ATTT không bị chặn bởi bản ghi cũ. Nếu TA không xác nhận trong hạn, thao tác chuyển `OVERDUE` và phát cảnh báo (EVT-01-15 giai đoạn `OVERDUE`) nhưng HTTT vẫn bị tạm ngừng.

## 6. Bảng mã lỗi ERR-01

Mọi lỗi trả theo RFC 9457 (`application/problem+json`) với `type` là `https://datahub.gov.vn/errors/ERR-01-nnn`, `title` ngắn bằng tiếng Việt, `status`, `code` là mã `ERR-01-nnn`, `traceId` và (khi có) `detail`, `errors[]` theo trường. Chi tiết nội bộ như ngăn xếp gọi hay thông điệp của hệ ngoài **không bao giờ** vào thân phản hồi; lỗi không lường trước trả mã chung `ERR-00-500` của FR-00-080 (D04-01) kèm `traceId`. Toàn bộ dải 001…099 thuộc mặt phẳng điều khiển; PH-01 không có mã runtime (101…199) vì không nằm trên đường dữ liệu.

### 6.1. Bảng mã lỗi

Năm mươi mã đầu (001…050) giữ nguyên theo [FRS §9.1](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md): cùng mã, cùng mã HTTP, cùng ý nghĩa (kiểm tra tự động ở CI). Bốn mã 051…054 do tập này thêm. Cột cuối cho biết API nào phát sinh mã, lấy từ `x-datahub-errors` của OpenAPI và từ mô tả thao tác.

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | API phát sinh (API-01-) |
|---|---|---|---|
| ERR-01-001 | 404 | Không tìm thấy đối tượng, đối tượng thuộc tenant khác hoặc ngoài phạm vi vai trò | Mọi API có tham số đường dẫn |
| ERR-01-002 | 409 | Mã HTTT đã dùng (kể cả HTTT đã chấm dứt hoặc bị từ chối) | 004 |
| ERR-01-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường | Mọi API có thân hoặc tham số |
| ERR-01-004 | 422 | Tổ chức chủ quản không có hoặc không hoạt động ở danh mục tổ chức | 004, 022 |
| ERR-01-005 | 409 | Chuyển trạng thái, thao tác không hợp lệ với trạng thái hiện tại | 005, 007, 009, 010, 012, 018, 019, 022 và 10 API khác |
| ERR-01-006 | 403 | Người nộp không thuộc tổ chức đã khai báo | 004 |
| ERR-01-007 | 412 | Hồ sơ đã được người khác sửa (`If-Match` không khớp) | Mọi lệnh có `If-Match` |
| ERR-01-008 | 422 | Hồ sơ chưa đủ điều kiện nộp, kèm danh sách đầy đủ thiếu sót | 023 |
| ERR-01-009 | 409 | Đã có hồ sơ khác đang xử lý cho cùng HTTT | 023 |
| ERR-01-010 | 422 | Tổ chức còn HTTT thiếu đầu mối kỹ thuật đang hoạt động | 023 |
| ERR-01-011 | 422 | Thư điện tử đầu mối không thuộc miền công vụ được phép | 015, 016 |
| ERR-01-012 | 413 | Tệp vượt cỡ cho phép | 007 |
| ERR-01-013 | 415 | Định dạng tệp không được phép | 007 |
| ERR-01-014 | 422 | Tệp bị loại do quét mã độc | 007 |
| ERR-01-015 | 422 | Mục nhu cầu khai thác thiếu căn cứ pháp lý | 009, 012, 060 |
| ERR-01-016 | 422 | Dữ liệu thuộc danh mục bí mật nhà nước, không kết nối | 012, 025, 060 |
| ERR-01-017 | 403 | Vi phạm bốn mắt (người xử lý là người lập, nộp, thẩm định hoặc đề nghị) | 024, 025, 028, 031, 032, 033, 044, 053 và 2 API khác |
| ERR-01-018 | 422 | Còn mục nhu cầu chưa được đánh giá | 025 |
| ERR-01-019 | 422 | Thiếu ý kiến, phạm vi được duyệt hoặc nhóm xác nhận bắt buộc | 024, 025 |
| ERR-01-020 | 409 | Hồ sơ, bước hoặc kỳ không ở giai đoạn xử lý tương ứng | 024, 025, 028, 029, 030, 031, 032, 033 và 4 API khác |
| ERR-01-021 | 503 | PH-12 không khả dụng khi cấp, thu hồi định danh | 035, 037, 038, 044, 045 |
| ERR-01-022 | 409 | Client trùng ở PH-12 | 035 |
| ERR-01-023 | 503 | Kho bí mật không khả dụng | 035, 037, 038, 039, 040, 041, 045 |
| ERR-01-024 | 410 | Liên kết bàn giao đã dùng, hết hạn hoặc bị hủy | 040 |
| ERR-01-025 | 403 | Người mở liên kết không phải đối tượng được nhận (đầu mối, tổ chức) | 040, 070, 071 |
| ERR-01-026 | 429 | Mở liên kết sai quá số lần cho phép, liên kết bị khóa | 040 |
| ERR-01-027 | 422 | Khóa công khai không hợp lệ | 037 |
| ERR-01-028 | 422 | Yêu cầu chứng thư hoặc chứng thư không hợp lệ | 037, 038 |
| ERR-01-029 | 409 | Định danh đang trong thời gian chuyển tiếp xoay vòng | 045 |
| ERR-01-030 | 409 | Định danh không ở trạng thái cho phép thao tác | 037, 038, 039, 041, 045, 046, 047, 061 |
| ERR-01-031 | 422 | Chưa đủ kiểm thử SANDBOX đạt | 044 |
| ERR-01-032 | 422 | Chưa đủ điều kiện kích hoạt hoặc khôi phục | 044, 052 |
| ERR-01-033 | 400 | Thiếu lý do hoặc nội dung bắt buộc | 019, 031, 033, 045, 047, 051, 052, 053 và 5 API khác |
| ERR-01-034 | 409 | Cần xác nhận tác động phụ thuộc trước khi tiếp tục | 047, 051, 053 |
| ERR-01-035 | 403 | Cần xác thực lại hai yếu tố cho thao tác nhạy cảm | 032, 033, 040, 044, 045, 047, 051, 052 và 5 API khác |
| ERR-01-036 | 409 | Thao tác khẩn đã được xử lý, hoặc khôi phục khi chưa có đồng ý của Cán bộ ATTT | 052, 054, 055 |
| ERR-01-037 | 422 | Mở rộng phạm vi phải qua thẩm định pháp lý lại | 057 |
| ERR-01-038 | 409 | Đã có yêu cầu thay đổi chờ duyệt | 057, 060 |
| ERR-01-039 | 409 | Đã có kỳ rà soát đang mở | 065 |
| ERR-01-040 | 410 | Phiếu xác nhận rà soát hết hạn hoặc đã trả lời | 070, 071 |
| ERR-01-041 | 422 | Quyết định rà soát không hợp lệ | 072 |
| ERR-01-042 | 400 | Tệp nhập hệ cũ sai cấu trúc | 080 |
| ERR-01-043 | 409 | Bản ghi nhập trùng HTTT đã có | 082 |
| ERR-01-044 | 422 | Tham số hoặc dữ liệu vượt miền, vượt trần cho phép | 065, 080, 082, 084 |
| ERR-01-045 | 429 | Vượt giới hạn tốc độ tra cứu danh bạ | 076, 077, 079 |
| ERR-01-046 | 503 | Phụ thuộc không khả dụng (danh mục tổ chức, PH-02, PH-13, PH-14, kho tệp, quét mã độc) | 002, 007, 008, 023, 026, 042, 056, 068 |
| ERR-01-047 | 422 | Cấp độ ATTT hoặc phương thức xác thực thấp hơn yêu cầu của mức phân loại dữ liệu | 024, 060 |
| ERR-01-048 | 409 | HTTT đang tạm ngừng, không thực hiện được thao tác | 039, 040, 041 |
| ERR-01-049 | 422 | Địa chỉ cơ sở không phải `https` hoặc dải IP sai dạng | 004, 005, 057 |
| ERR-01-050 | 409 | HTTT phải còn ít nhất một đầu mối kỹ thuật | 015, 016, 017 |
| ERR-01-051 | 409 | `Idempotency-Key` đã dùng với thân yêu cầu khác (type `idempotency-mismatch`) | 004, 007, 015, 023, 035, 039, 041, 042 và 11 API khác |
| ERR-01-052 | 401, 403 | Thiếu hoặc hết hạn thông tin xác thực, hoặc người gọi, token dịch vụ không đủ quyền hay scope | Mọi API |
| ERR-01-053 | 409 | Bước saga không ở trạng thái chờ kết quả bất đồng bộ (không phải `ACCEPTED`) hoặc cờ `onboarding.saga.async-callback` đang tắt | 087 |
| ERR-01-054 | 409 | Yêu cầu cùng `Idempotency-Key` đang được xử lý, thử lại sau | 004, 007, 015, 023, 035, 039, 041, 042 và 11 API khác |

: Bảng mã lỗi ERR-01 (001…054)
<!-- gen:errors:end -->

Ba mã gắn với kết quả kiểm tra thay vì mã HTTP: ERR-01-010 (còn HTTT thiếu đầu mối kỹ thuật), ERR-01-011 (thư điện tử ngoài miền công vụ) và ERR-01-049 (địa chỉ sai dạng) xuất hiện trước hết trong `issues[]` của API-01-022 (luôn `200`), rồi mới là lỗi `422` khi nộp (API-01-023 trả ERR-01-008 kèm đủ `issues`). Giao diện chỉ cần đọc `issues[]` một lần để hiện toàn bộ thiếu sót cùng lúc.

### 6.2. Thông điệp hiển thị

Câu hiển thị cho người dùng lấy theo [FRS §9.2](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) (28 mã) và nguồn chuẩn D03-06-PH01 §5.2. Các mã chưa có câu ở FRS dùng câu đề nghị dưới đây (lấy từ luồng ngoại lệ của FRS chương 6 hoặc viết mới), ghi ở chương 11 để tập màn hình đồng bộ. Lỗi không có trong cả hai bảng hiển thị theo FR-00-080: câu từ `detail`, kèm mã lỗi và nút "Sao chép mã truy vết".

| Mã | Câu hiển thị đề nghị | Vị trí |
|---|---|---|
| ERR-01-001 | "Không tìm thấy hệ thống {mã}." | Trang lỗi hoặc thông báo nổi |
| ERR-01-003 | "Dữ liệu chưa hợp lệ. Sửa các trường được đánh dấu." | Dưới từng trường (`errors[].path`) |
| ERR-01-005 | "Hồ sơ đã nộp, không sửa được. Dùng Rút hồ sơ nếu cần sửa." | Hộp cảnh báo |
| ERR-01-009 | "Đã có hồ sơ khác đang xử lý cho hệ thống này. Chờ kết quả hoặc rút hồ sơ đó." | Hộp cảnh báo bước Rà soát |
| ERR-01-012 | "Tệp lớn hơn {n} MB. Nén hoặc chia nhỏ tệp." | Dưới ô tải tệp |
| ERR-01-013 | "Chỉ nhận PDF, DOCX, XLSX, PNG, JPG." | Dưới ô tải tệp |
| ERR-01-014 | "Tệp không qua kiểm tra an toàn và đã bị loại. Kiểm tra máy rồi tải lại." | Dưới ô tải tệp |
| ERR-01-019 | "Nhập nhóm HTTT đã xác nhận và ý kiến thẩm định." | Dưới nút Hoàn tất |
| ERR-01-020 | "Bước thẩm định này đã đóng hoặc hồ sơ đang ở trạng thái khác." | Thông báo nổi |
| ERR-01-022 | "Mã client đã tồn tại ở dịch vụ định danh, cần xử lý thủ công." | Khối tiến độ cấp định danh |
| ERR-01-026 | "Liên kết đã bị khóa do thử sai nhiều lần. Liên hệ quản trị tỉnh." | Trang bàn giao |
| ERR-01-028 | "Yêu cầu chứng thư không hợp lệ: {lý do}." | Dưới ô tải CSR |
| ERR-01-030 | "Định danh không còn dùng được. Cấp định danh mới." | Hộp xác nhận |
| ERR-01-032 | "Chưa đủ điều kiện kích hoạt: {danh sách}." | Hộp kích hoạt |
| ERR-01-038 | "Đã có thay đổi chờ duyệt. Chờ quyết định trước khi gửi thay đổi mới." | Hộp sửa hồ sơ |
| ERR-01-041 | "Không giữ được mục có căn cứ hết hiệu lực. Chọn thu hồi hoặc bổ sung căn cứ ở Đề nghị mở rộng." | Dòng mục rà soát |
| ERR-01-042 | "Tệp không đúng mẫu. Tải mẫu nhập và thử lại." | Màn nhập hệ cũ |
| ERR-01-043 | "{n} dòng trùng hệ thống đã có, đã bỏ qua." | Bản xem trước nhập |
| ERR-01-044 | "Giá trị {khóa} phải từ {min} đến {max}." | Dưới trường tham số |
| ERR-01-048 | "Hệ thống đang tạm ngừng, không tạo liên kết bàn giao mới. Chờ khôi phục hoặc xoay định danh." | Hộp cảnh báo |
| ERR-01-049 | "Địa chỉ {giá trị} không hợp lệ. Chỉ nhận https và dải CIDR hợp lệ." | Dưới trường địa chỉ |
| ERR-01-051 | "Yêu cầu này đã được gửi với nội dung khác. Tải lại trang rồi thử lại." | Thông báo nổi |
| ERR-01-052 | "Anh/chị không có quyền thực hiện thao tác này hoặc phiên đã hết hạn. Đăng nhập lại hoặc liên hệ quản trị tỉnh." | Thông báo nổi hoặc trang đăng nhập |
| ERR-01-053 | "Kết quả cấp định danh đến không khớp bước đang chờ. Sự việc đã được ghi nhận." | Nhật ký vận hành, không hiện cho người dùng |
| ERR-01-054 | "Yêu cầu đang được xử lý. Chờ vài giây rồi xem kết quả." | Thông báo nổi |

: Thông điệp đề nghị cho các mã chưa có câu ở FRS §9.2

### 6.3. Trường bổ sung của thân lỗi

Ngoài các trường chuẩn của RFC 9457, một số mã lỗi mang thêm dữ liệu để giao diện hiện đúng chỗ và bên gọi biết cách xử lý tiếp.

| Trường | Kiểu | Khi nào có | Ý nghĩa |
|---|---|---|---|
| `errors[]` | `{path, rule, message}` | ERR-01-003, 015, 049 | Lỗi theo từng trường; `path` là đường dẫn JSON tới trường |
| `issues[]` | `ValidationIssue` | ERR-01-008 | Danh sách đầy đủ thiếu sót của hồ sơ, mỗi mục có `code`, `severity`, `message`, `guidance` |
| `dependents[]` | `Dependent` | ERR-01-034 | Đối tượng đang phụ thuộc HTTT (đăng ký, luồng, dịch vụ, chủ đề), chỉ tên tổ chức, không liên hệ cá nhân |
| `currentEtag` | chuỗi | ERR-01-007 | `ETag` hiện hành để giao diện tải lại và hiện khác biệt |
| `retryAfterSeconds`, tiêu đề `Retry-After` | số giây | ERR-01-026, 045, 054; 503 | Bao lâu nữa nên thử lại |
| `lockedUntil` | thời điểm | ERR-01-026 | Thời điểm hết khóa, khi liên kết có hạn khóa |

: Trường bổ sung của thân lỗi

### 6.4. Cách bên gọi xử lý lỗi

Bảng gom mã theo lớp xử lý (khớp SDD §8.4) để bên gọi viết một chỗ xử lý chung thay vì xử lý từng mã.

| Lớp | HTTP | Mã | Bên gọi nên làm |
|---|---|---|---|
| Dữ liệu không hợp lệ | 400, 413, 415, 422 | 003, 004, 008, 010, 011, 012, 013, 014, 015, 016, 018, 019, 027, 028, 031, 032, 033, 037, 041, 042, 044, 047, 049 | Không thử lại; hiện lỗi theo trường hoặc `issues[]` |
| Trạng thái, đồng thời | 409, 412 | 002, 005, 007, 009, 020, 022, 029, 030, 034, 036, 038, 039, 043, 048, 050, 051, 053, 054 | Tải lại và xử lý điều kiện; 007 kèm `currentEtag`; 034 hỏi xác nhận tác động; 054 chờ rồi thử lại cùng khóa |
| Quyền, bốn mắt, xác thực lại | 401, 403 | 006, 017, 025, 035, 052 | Không thử lại; 035 mở hộp xác thực lại; 017 và 025 còn ghi sự kiện an ninh |
| Không thấy hoặc ngoài phạm vi | 404 | 001 | Cùng thân với "không tồn tại", không dò |
| Hết hạn, đã dùng | 410 | 024, 040 | Thân giống nhau cho mọi nguyên nhân; hướng dẫn liên hệ quản trị tỉnh |
| Giới hạn tốc độ, khóa | 429 | 026, 045 | Chờ `Retry-After`; 026 đã hủy liên kết |
| Phụ thuộc không khả dụng | 503 | 021, 023, 046 | Thử lại có lùi; trạng thái đã đặt không đổi; liên kết bàn giao không bị tiêu hao |

: Lớp lỗi và cách bên gọi xử lý

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng chỉ có giá trị khi máy kiểm được. Mọi kiểm tra dưới đây chạy ở cổng hợp đồng CI-5 (D04-02) mỗi khi tệp trong `api/ph01/` hoặc `FRS §9` thay đổi; cột "Kết quả bản 0.1" là kết quả đã chạy thật khi viết tài liệu này.

| Kiểm tra | Công cụ | Nội dung | Kết quả bản 0.1 |
|---|---|---|---|
| OpenAPI hợp lệ | `openapi-spec-validator` | Tệp đúng OpenAPI 3.1 | Đạt |
| Quy tắc thiết kế | Spectral, bộ `spectral:oas` (`ph01/.spectral.yaml`) | Mô tả, tham số, ví dụ, thành phần không dùng | 0 lỗi, 0 cảnh báo |
| Ví dụ khớp lược đồ | `tools/check_contracts.py` | 217 ví dụ (thân yêu cầu, phản hồi, lược đồ, ví dụ lỗi) khớp JSON Schema 2020-12 | Đạt |
| Đủ mã, không trùng | `tools/check_contracts.py` | 88 mã `API-01-001…088` liên tục, khớp `spec.py`; mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors` | Đạt |
| Lệnh ghi an toàn | `tools/check_contracts.py` | `PUT`, `PATCH`, `DELETE` có `If-Match`; lệnh đánh dấu lũy đẳng có `Idempotency-Key` | Đạt |
| Bảng lỗi khớp FRS | `tools/check_contracts.py` | 50 mã ERR-01 đầu có cùng mã HTTP với [FRS §9.1](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md); mã lỗi của mọi operation đều có trong bảng | Đạt |
| Không lộ bí mật | `tools/check_contracts.py` | `clientSecret` và các trường bí mật chỉ ở `HandoverOpenResult` (`readOnly`); không có `secret_ref`; sự kiện không có trường bí mật | Đạt |
| AsyncAPI hợp lệ | `@asyncapi/parser` 3 (`tools/validate_asyncapi.mjs`) | 15 kênh, 30 operation, ví dụ khớp lược đồ | 0 lỗi, 0 cảnh báo (một gợi ý nâng bản 3.1) |
| Đặc tả sinh đúng | `build/tools/sinh_dac_ta_api.py` | Chương 10 sinh lại từ OpenAPI không đổi nội dung | Đạt |
| Mã tài liệu | `build/tools/kiem_tra_ma.py` | Mã API, EVT, ERR của tập này đủ, không trùng, liên kết không hỏng | Đạt |
| Thay đổi phá vỡ | `oasdiff breaking` so với `main` | Chặn xóa, đổi tên, đổi kiểu, thêm trường bắt buộc, siết ràng buộc trong `v1` | Chưa chạy: chưa có bản nền; bắt đầu từ bản 0.2 |
| Tương thích sự kiện | Apicurio `BACKWARD` | Lược đồ sự kiện mới đọc được sự kiện cũ | Chưa chạy: chờ đăng ký lược đồ ở D03-09 |
| Kiểm thử hợp đồng | Schemathesis trên bản dựng `dh-connect` | Phản hồi thật khớp OpenAPI | Chưa chạy: chờ có mã nguồn |
| Rò rỉ bí mật | Ca canary `DH-CANARY-…` (D05-02) | Giá trị đánh dấu không xuất hiện trong CSDL, log, vết, phản hồi, tệp xuất, sự kiện | Chưa chạy: chờ có mã nguồn |

: Kiểm tra hợp đồng trong CI

Lệnh chạy lại từ thư mục `datahub-docs/03-thiet-ke/api/ph01`:

```bash
python3 tools/gen_openapi.py && python3 tools/gen_asyncapi.py       # sinh hai tệp hợp đồng
python3 tools/gen_md.py                                              # bảng ở chương 1, 2, 3, 4, 6
python3 ../../../build/tools/sinh_dac_ta_api.py openapi-onboarding.yaml ../D03-04-PH01-api-ket-nap-httt.md   # chương 10
python3 tools/check_contracts.py                                     # OpenAPI, ví dụ, mã, bí mật, AsyncAPI
npx @stoplight/spectral-cli lint openapi-onboarding.yaml -r .spectral.yaml
node tools/validate_asyncapi.mjs asyncapi-onboarding.yaml
oasdiff breaking origin/main:datahub-docs/03-thiet-ke/api/ph01/openapi-onboarding.yaml openapi-onboarding.yaml
```

Quy tắc đồng bộ: sửa nguồn (`spec.py`, `schemas.py`, `errors.py`, `gen_openapi.py`, `gen_asyncapi.py`) rồi sinh lại; không sửa tay hai tệp YAML hay các khối sinh trong tài liệu này. Khi thêm API mới phải thêm mã vào `spec.py`, mô tả vào bảng `X` của `gen_openapi.py` và ghi vào FRS §9.4.

## 8. Ánh xạ từ hệ cũ

PH-01 thay thế ba nguồn: mã hiện tại của repo (`apps/control`, module `onboarding`, đường dẫn `/api/v1/onboarding`), SRS cũ của repo (`docs/07-srs/SRS-PH-01-onboarding.md`) và các đối tượng của hệ LGSP cũ (Application của APIM, publisher và subscriber của Hub, LGC-APIM-019; 020, LGC-HUB-010, 011). Hai bảng đầu nối đường dẫn cũ với API mới; bảng thứ ba nối trạng thái và chủ quản.

### 8.1. Mã hiện tại của repo → API mới

Bảng nối từng đường dẫn của module `onboarding` trong `apps/control` với API mới và nêu thay đổi chính để nhóm di trú cập nhật bên gọi.

| Đường dẫn cũ (`/api/v1/onboarding`) | API mới | Thay đổi chính |
|---|---|---|
| `GET /status` | Bỏ | Trạng thái module do kiểm tra sức khỏe và chỉ số của PH-13 đảm nhận |
| `GET /applications` | API-01-001 | Đổi `applications` thành `systems`; phân trang `page`/`size`; thêm `facets`, cờ |
| `GET /applications/{id}` | API-01-002 | Khóa là `systemCode` thay cho `id`; thêm `allowedActions`, `ETag` |
| `GET /applications/{id}/audit` | API-01-003 | Lịch sử trạng thái kèm `traceId`; kiểm toán đầy đủ ở PH-13 |
| `POST /applications` | API-01-004 | Bắt buộc `Idempotency-Key`; `code` bất biến, không dùng lại |
| `POST /applications/{id}/review/legal` | API-01-025 (`reviewKind = legal`) | Kết luận từng mục (`APPROVED`, `NARROWED`, `REJECTED`); chỉ người được phân công |
| `POST /applications/{id}/review/technical` | API-01-024 | Thêm nhóm xác nhận, phương thức xác thực tối thiểu, hạn mức đề xuất |
| (chưa có) | API-01-025 (`reviewKind = security`) | Bước thẩm định ATTT mới |
| `POST /applications/{id}/approve` | API-01-032 | Bắt buộc `If-Match`; bốn mắt; sinh trần phạm vi và saga trong cùng giao dịch |
| `POST /applications/{id}/reject` | API-01-033 | Bắt buộc `comment` |
| `POST /applications/{id}/activate` | API-01-044 | Chỉ khi đủ kiểm thử SANDBOX, xác thực lại hai yếu tố; có thể `202` |
| `POST /applications/{id}/suspend` | API-01-051 | Cần xác nhận tác động; cắt quyền ≤ 60 giây |
| `POST /applications/{id}/resume` | API-01-052 | Tạm ngừng do nghi lộ bí mật cần đồng ý của Cán bộ ATTT |
| `POST /applications/{id}/revoke` | API-01-053, 054, 047 | Tách: chấm dứt tư cách (đề nghị, TA khác duyệt), thu hồi khẩn (SO), thu hồi định danh |
| `GET /applications/{id}/attachments` | API-01-006 | Thêm `scanStatus`, `sha256` |
| `GET /applications/{id}/attachments/{attachmentId}` | API-01-008 | Hoặc `302` tới liên kết ký; ghi kiểm toán lượt tải |
| `GET /applications/due-access-review` | API-01-065, 068 | Mở kỳ rà soát chụp toàn bộ mục rồi đọc mục kèm mức sử dụng |
| `POST /applications/{id}/access-review` | API-01-072 | Quyết định theo từng mục (cặp HTTT, phạm vi), không theo HTTT |
| `GET /applications/export` | API-01-085 | Xuất tệp bất đồng bộ kèm API-01-088; không có cột bí mật |

: Ánh xạ đường dẫn của mã hiện tại sang API mới

### 8.2. SRS cũ của repo → API mới

SRS cũ có thêm các đường dẫn quản trị và danh bạ chưa có trong mã; bảng dưới nối chúng với API mới.

| Đường dẫn trong SRS cũ | API mới | Ghi chú |
|---|---|---|
| `PUT /api/v1/onboarding/applications/{id}` | API-01-005 | Đổi `PUT` thành `PATCH` (Merge Patch, chỉ trường được phép) |
| `POST …/{id}/validate`, `…/submit` | API-01-022, 023 | Đổi dạng hành động `:validate`, `:submit` |
| `GET …/{id}/status` | API-01-034 | Thêm dòng thời gian, bên đang chờ, yêu cầu bổ sung |
| `POST …/{id}/attachments` | API-01-007 | Quét mã độc, giới hạn cỡ theo tham số |
| `GET /api/v1/onboarding/handover/{token}` | API-01-040 | **Đổi `GET` thành `POST`, `token` vào thân** để không vào log truy cập và đệm; thêm đăng nhập đúng đầu mối, hai yếu tố, `no-store` |
| `POST …/systems/{code}/test` | API-01-042, 043 | Kết quả đọc từ PH-03, PH-13 thay cho đơn vị tự ghi nhận (nguồn `MANUAL` chỉ để TA ghi hộ) |
| `GET /api/admin/v1/onboarding/queue` | API-01-027 | |
| `POST /api/admin/v1/onboarding/applications/{id}/provision` | API-01-035 | Cấp định danh chạy tự động sau phê duyệt; API này chỉ để thử lại khi saga lỗi |
| `POST /api/admin/v1/onboarding/applications/{id}/return` | API-01-031 | Trả theo từng trường, kèm yêu cầu cụ thể |
| `POST /api/admin/v1/onboarding/systems/{code}/revoke` | API-01-047 | Thu hồi định danh; chấm dứt cả HTTT dùng API-01-053 |
| `GET /api/admin/v1/onboarding/systems` | API-01-001 | Một danh sách chung, không tách đường dẫn quản trị |
| `POST /api/admin/v1/onboarding/access-review`, `GET …/{cycle}` | API-01-065, 067, 068, 074 | Kỳ có mã `RS-yyyy-nn`; báo cáo PDF, XLSX |
| `GET /api/v1/directory/contacts`, `…/{maDonVi}` | API-01-076, 077 | Chỉ đầu mối công khai; giới hạn tốc độ |
| `PUT /api/admin/v1/directory/contacts/{id}` | API-01-016 | Sửa đầu mối thuộc hồ sơ HTTT, không còn danh bạ riêng |

: Ánh xạ đường dẫn của SRS cũ sang API mới

Ba điểm khác biệt đáng chú ý so với hệ cũ: (1) đường dẫn quản trị `/api/admin/v1/…` được gộp vào một đường gốc, quyền khác nhau do `PERM-01-*` và OPA phân biệt; (2) lược đồ nhập hệ cũ **bỏ mọi cột bí mật**, chỉ đếm `secretsDropped` (API-01-080); (3) Application của APIM, publisher và subscriber của Hub trở thành HTTT thành viên có `roles` tương ứng (`CONSUMER`, `PROVIDER`, `PUBLISHER`, `SUBSCRIBER`) và được nhập qua API-01-080…082 với `source` là `APIM_APPLICATION`, `HUB_PUBLISHER`, `HUB_SUBSCRIBER`.

### 8.3. Trạng thái và chủ quản cũ → mới

Khi chạy song song và di trú dữ liệu W1 (D03-03-PH01 §8), trạng thái của repo đổi như bảng dưới; chi tiết và rủi ro ở Q01-53 của CSDL.

| Trạng thái cũ | Trạng thái mới | Ghi chú |
|---|---|---|
| `DRAFT` | `DRAFT` | Giữ |
| `SUBMITTED`, `REVIEWED` | `DRAFT` kèm `revisionNo = 1` và `returnReason` | Thiếu dữ liệu để duyệt tiếp; đơn vị khai lại rồi nộp lại |
| `APPROVED` | `APPROVED`, `provisionStage = PROVISION_FAILED` | TA bấm "Thử lại" (API-01-035) để cấp định danh bằng saga mới |
| (tên chủ quản dạng chữ) | `ownerOrgId = CHUA-GAN` | TA ghép tổ chức ở PH-20 rồi mới sửa tiếp hồ sơ (API-01-005) |
| `ACTIVE`, `SUSPENDED`, `REJECTED` | Giữ nguyên | `SUSPENDED` có lý do `OTHER` |
| `REVOKED` | `TERMINATED` | Mã không dùng lại |

: Ánh xạ trạng thái và chủ quản cũ sang mới

## 9. Câu hỏi mở

Năm câu hỏi dưới đây thuộc tập API (dải Q01-55…59); các câu hỏi của FRS (Q01-01…16), SDD (Q01-20…28), CSDL (Q01-50…54) không nhắc lại. Mỗi câu nêu đề xuất đang dùng để tài liệu không bị chặn.

> **Câu hỏi mở Q01-55:** Mã liên kết của phiếu xác nhận rà soát (API-01-070, 071) nằm trong **đường dẫn** theo FRS §9.4, trong khi bàn giao (API-01-040) đã đưa mã vào thân. Mã trong đường dẫn có thể lọt vào log truy cập, tiêu đề `Referer` và lịch sử trình duyệt. Đề xuất đang dùng: giữ đường dẫn theo FRS, cổng API và BFF che đoạn `{token}` trong log, mã 256 bit hết hạn 30 ngày, trả lời một lần, bắt buộc đăng nhập đúng tổ chức (ERR-01-025). Nếu Cán bộ ATTT yêu cầu thống nhất với bàn giao thì đổi sang `POST …:view` mang `token` trong thân (thay đổi FRS §9.4 và tập màn hình).

> **Câu hỏi mở Q01-56:** PH-12 và PH-03 trả kết quả saga đồng bộ hay bất đồng bộ (Q01-28 của SDD)? API-01-087 hỗ trợ kiểu bất đồng bộ nhưng cờ `onboarding.saga.async-callback` mặc định `false` nên bước saga chờ tối đa 10 giây rồi thử lại. Cần PH-12 và PH-03 xác nhận khi viết tập API của họ: nếu cả hai luôn đồng bộ thì bỏ API-01-087 và mã ERR-01-053 ở bản 0.2; nếu có bất đồng bộ thì chốt thời hạn chờ (giả định 5 phút) và cách xác thực lời gọi (token dịch vụ `azp` khớp tài khoản của phân hệ).

> **Đã chốt 27/11/2026 (Q01-57):** ở MVP xuất tệp (API-01-075, 079, 085) trả tệp đồng bộ, giới hạn 20.000 dòng, vượt thì yêu cầu thu hẹp bộ lọc; chưa thêm bảng `background_job`. Đường `202` kèm tác vụ nền tra bằng API-01-088 là hợp đồng của Đợt 2, khi thêm bảng `background_job` (id, `tenant_id`, `kind`, `status`, `requested_by`, `object_key`, `row_count`, `expires_at`; tệp ở bucket `dh-{tenant}-onboarding` mã hóa SSE-C, giữ 7 ngày; liên kết tải ký 15 phút).

> **Câu hỏi mở Q01-58:** Mã lỗi chung và mã riêng chồng nhau. D02-02 SRS và D04-01 nhắc `ERR-00-412` (lệch `If-Match`) và `ERR-00-500`, còn FRS PH-01 đã chốt `ERR-01-007` (412) cho cùng việc; thiếu quyền và xác thực dùng chung chưa có mã (tập này thêm ERR-01-052). Đề xuất: PH-01 giữ `ERR-01-007`, `ERR-01-052`; lỗi không lường trước dùng `ERR-00-500`. Cần D04-01 xác nhận có cho phép mã riêng của phân hệ thay mã chung hay buộc dùng `ERR-00-*`, để tập khác không tự đặt mã khác nhau cho cùng một lỗi.

> **Câu hỏi mở Q01-59:** Đợt 2 có cổng nhà phát triển PH-15 (Q01-15 của FRS): nếu cho đầu mối nhà thầu tự lấy thông tin xác thực trên cổng thì API-01-040 được gọi từ BFF của cổng chứ không chỉ BFF console. Cần chốt audience và `acr` của token cổng, tài khoản nhà thầu thuộc realm nào (Q01-05 của FRS), và giới hạn tốc độ riêng (10 lần mỗi phút mỗi địa chỉ IP đang là giả định). Tới khi chốt, API-01-040 chỉ nhận token của BFF console.

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục.

<!-- gen:dac-ta-api:start -->

### Hồ sơ HTTT

#### API-01-001 · Danh sách, tìm kiếm, lọc HTTT thành viên

::: dac-ta
**Mục đích.** Danh sách, tìm kiếm, lọc HTTT thành viên.

**Phương thức, đường dẫn.** `GET /systems`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-001.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `ownerOrgId` (query, OrgId, tùy chọn); `group` (query, integer, tùy chọn); `role` (query, array, tùy chọn); `securityLevel` (query, array, tùy chọn); `flag` (query, array, tùy chọn); `sort` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SystemPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** OR chỉ thấy HTTT của tổ chức mình; DO chỉ thấy HTTT có dữ liệu của tổ chức mình (OPA). Kèm `facets`. `calls30d` rỗng khi PH-13 không khả dụng.
:::

#### API-01-002 · Chi tiết HTTT thành viên

::: dac-ta
**Mục đích.** Chi tiết HTTT thành viên.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-002.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SystemDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-046, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả toàn bộ thuộc tính DD-03, hồ sơ kỹ thuật, nhu cầu, trần, đầu mối, định danh (không bí mật) và `allowedActions`. Có `ETag`. Đầu mối `SECURITY` chỉ TA, SO thấy.
:::

#### API-01-003 · Lịch sử trạng thái và thay đổi của HTTT

::: dac-ta
**Mục đích.** Lịch sử trạng thái và thay đổi của HTTT.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/history`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-002.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Lịch sử chuyển trạng thái, lý do, người thực hiện, `traceId`; giữ vĩnh viễn.
:::

#### API-01-004 · Tạo hồ sơ kết nạp nháp

::: dac-ta
**Mục đích.** Tạo hồ sơ kết nạp nháp.

**Phương thức, đường dẫn.** `POST /systems`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-003.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SystemCreate`; trường bắt buộc: `code`, `name`, `description`, `ownerOrgId`, `systemType`, `roles`, `securityLevel`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SystemDetail`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-01-002, ERR-01-003, ERR-01-004, ERR-01-006, ERR-01-049, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo hồ sơ `DRAFT`, sinh `applicationNo`, `revisionNo = 0`. Mã trùng (kể cả HTTT đã chấm dứt, bị từ chối) trả ERR-01-002; tổ chức không có hoặc không hoạt động ở PH-20 trả ERR-01-004; OR chỉ lập cho tổ chức của mình (ERR-01-006). Phát EVT-01-03 (`∅ → DRAFT`).
:::

#### API-01-005 · Sửa hồ sơ nháp (tự lưu)

::: dac-ta
**Mục đích.** Sửa hồ sơ nháp (tự lưu).

**Phương thức, đường dẫn.** `PATCH /systems/{systemCode}`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-004.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `SystemUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SystemDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-049, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** JSON Merge Patch, chỉ khi `DRAFT`; không đổi `code`. Tự lưu từng nhóm trường; trả `ETag` mới. HTTT đã kết nạp sửa qua API-01-057, không qua đây (ERR-01-005).
:::

#### API-01-018 · Xóa hồ sơ nháp chưa từng nộp

::: dac-ta
**Mục đích.** Xóa hồ sơ nháp chưa từng nộp.

**Phương thức, đường dẫn.** `DELETE /systems/{systemCode}`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-01-009.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-005, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xóa mềm hồ sơ `DRAFT` chưa từng nộp (`revisionNo = 0`); giữ 30 ngày để khôi phục, sau đó xóa cứng và giải phóng mã. Hồ sơ đã từng nộp không xóa được (ERR-01-005): dùng rút hồ sơ.
:::

#### API-01-019 · Rút hồ sơ đã nộp về nháp

::: dac-ta
**Mục đích.** Rút hồ sơ đã nộp về nháp.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:withdraw`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-01-009.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WithdrawRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-033, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đơn vị rút hồ sơ `SUBMITTED` về `DRAFT`; hủy các bước thẩm định đang mở (`WITHDRAWN`). Phát EVT-01-03.
:::

#### API-01-034 · Theo dõi tiến độ hồ sơ

::: dac-ta
**Mục đích.** Theo dõi tiến độ hồ sơ.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/progress`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-019.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProgressView`; trường bắt buộc: `timeline`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dòng thời gian, bên đang chờ và hạn, các yêu cầu bổ sung đang mở.
:::

### Tài liệu và mẫu

#### API-01-006 · Danh sách tài liệu đính kèm

::: dac-ta
**Mục đích.** Danh sách tài liệu đính kèm.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/attachments`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-005.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AttachmentList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mọi tài liệu của hồ sơ, kèm trạng thái quét mã độc (`scanStatus`).
:::

#### API-01-007 · Tải tài liệu đính kèm

::: dac-ta
**Mục đích.** Tải tài liệu đính kèm.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/attachments`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-005.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `AttachmentUpload`; trường bắt buộc: `file`, `kind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Attachment`; trường bắt buộc: `attachmentId`, `kind`, `fileName`, `sizeBytes`, `sha256`, `scanStatus`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `413`, `415`, `422`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-012, ERR-01-013, ERR-01-014, ERR-01-046, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kiểm kiểu theo nội dung (Tika), cỡ ≤ `onboarding.attachment.maxSizeMb`, quét mã độc đồng bộ ≤ 20 giây (quá hạn: `scanStatus = PENDING`, không nộp được tới khi sạch). Mã hóa SSE-C, bucket theo tenant.
:::

#### API-01-008 · Tải nội dung tài liệu

::: dac-ta
**Mục đích.** Tải nội dung tài liệu.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/attachments/{attachmentId}/content`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-005.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `attachmentId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; `302`; tiêu đề `Location`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-046, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tệp nhị phân (`Content-Disposition: attachment`), hoặc `302` tới liên kết ký 5 phút của kho tệp. Ghi kiểm toán lượt tải.
:::

#### API-01-009 · Xóa tài liệu đính kèm

::: dac-ta
**Mục đích.** Xóa tài liệu đính kèm.

**Phương thức, đường dẫn.** `DELETE /systems/{systemCode}/attachments/{attachmentId}`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-005.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `attachmentId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-005, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ khi `DRAFT`; tệp đang được dùng làm căn cứ pháp lý của nhu cầu thì gỡ liên kết trước (ERR-01-015 ở lần kiểm tra kế tiếp).
:::

#### API-01-020 · Danh sách mẫu văn bản và hướng dẫn kết nạp

::: dac-ta
**Mục đích.** Danh sách mẫu văn bản và hướng dẫn kết nạp.

**Phương thức, đường dẫn.** `GET /templates`.

**Quyền.** Quyền cơ sở người dùng nội bộ tenant (không cần mã quyền riêng).

**FR hiện thực.** FR-01-010.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplateList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mẫu của tenant và mẫu mặc định ở `COMMON`; mọi người dùng đã đăng nhập thuộc tenant.
:::

#### API-01-021 · Tải nội dung mẫu văn bản

::: dac-ta
**Mục đích.** Tải nội dung mẫu văn bản.

**Phương thức, đường dẫn.** `GET /templates/{templateCode}/content`.

**Quyền.** Quyền cơ sở người dùng nội bộ tenant (không cần mã quyền riêng).

**FR hiện thực.** FR-01-010.

**Tham số.** `templateCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tệp mẫu (DOCX, PDF).
:::

### Hồ sơ kỹ thuật và nhu cầu

#### API-01-010 · Khai hồ sơ năng lực kỹ thuật

::: dac-ta
**Mục đích.** Khai hồ sơ năng lực kỹ thuật.

**Phương thức, đường dẫn.** `PUT /systems/{systemCode}/technical-profile`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-006.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TechnicalProfile`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TechnicalProfileView`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi đè hồ sơ năng lực; hệ thống tính `proposedGroup` theo bảng quy tắc ưu tiên (FRS §6.2) và trả `explanation`. Chỉ khi `DRAFT`.
:::

#### API-01-011 · Xem hồ sơ năng lực kỹ thuật và nhóm đề xuất

::: dac-ta
**Mục đích.** Xem hồ sơ năng lực kỹ thuật và nhóm đề xuất.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/technical-profile`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-006.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TechnicalProfileView`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Có `ETag`; `confirmedGroup` chỉ có sau thẩm định kỹ thuật.
:::

#### API-01-012 · Khai danh sách nhu cầu khai thác

::: dac-ta
**Mục đích.** Khai danh sách nhu cầu khai thác.

**Phương thức, đường dẫn.** `PUT /systems/{systemCode}/data-demands`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-007.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DataDemandsPut`; trường bắt buộc: `demands`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataDemandList`; trường bắt buộc: `demands`, `ceiling`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-015, ERR-01-016, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thay cả danh sách. Mục `CONSUME` thiếu căn cứ pháp lý đầy đủ trả ERR-01-015 (kèm `errors[].path`); dữ liệu thuộc danh mục bí mật nhà nước trả ERR-01-016. Giữ `demandId` của dòng không đổi.
:::

#### API-01-013 · Xem nhu cầu khai thác và trần phạm vi

::: dac-ta
**Mục đích.** Xem nhu cầu khai thác và trần phạm vi.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/data-demands`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-007.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DataDemandList`; trường bắt buộc: `demands`, `ceiling`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm `ceiling` (trần phạm vi) sau khi duyệt.
:::

### Đầu mối

#### API-01-014 · Danh sách đầu mối của HTTT

::: dac-ta
**Mục đích.** Danh sách đầu mối của HTTT.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/contacts`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-008.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ContactList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đầu mối `SECURITY` chỉ TA, SO thấy.
:::

#### API-01-015 · Thêm hoặc thay thế đầu mối

::: dac-ta
**Mục đích.** Thêm hoặc thay thế đầu mối.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/contacts`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-008.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ContactInput`; trường bắt buộc: `contactType`, `fullName`, `position`, `email`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ContactList`; trường bắt buộc: `items`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-011, ERR-01-050, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thêm đầu mối; có `replaceContactId` thì thay thế đầu mối cũ (cũ chuyển `INACTIVE`, không xóa). Thư điện tử phải thuộc `onboarding.contact.allowedEmailDomains`. Phát EVT-01-13.
:::

#### API-01-016 · Sửa đầu mối

::: dac-ta
**Mục đích.** Sửa đầu mối.

**Phương thức, đường dẫn.** `PATCH /systems/{systemCode}/contacts/{contactId}`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-008.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `contactId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `ContactUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ContactList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-011, ERR-01-050, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Merge Patch. Đổi thư điện tử kiểm lại miền công vụ. Phát EVT-01-13.
:::

#### API-01-017 · Bỏ đầu mối

::: dac-ta
**Mục đích.** Bỏ đầu mối.

**Phương thức, đường dẫn.** `DELETE /systems/{systemCode}/contacts/{contactId}`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-008.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `contactId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-050, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Vô hiệu đầu mối (`INACTIVE`). Không bỏ được đầu mối kỹ thuật cuối cùng (ERR-01-050). Phát EVT-01-13.
:::

### Nộp, thẩm định, phê duyệt

#### API-01-022 · Kiểm tra hợp lệ hồ sơ trước khi nộp

::: dac-ta
**Mục đích.** Kiểm tra hợp lệ hồ sơ trước khi nộp.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:validate`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-01-011.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValidateResult`; trường bắt buộc: `valid`, `errorCount`, `warningCount`, `issues`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-005, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy toàn bộ danh sách kiểm tra trước khi nộp (FRS §6.3); luôn trả `200`, thiếu sót nằm ở `issues[]` với `code` là ERR-01-004, 008, 009, 010, 011, 015, 016, 047, 049, 050. Không đổi dữ liệu.
:::

#### API-01-023 · Nộp hồ sơ kết nạp

::: dac-ta
**Mục đích.** Nộp hồ sơ kết nạp.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:submit`.

**Quyền.** `PERM-01-submit`.

**FR hiện thực.** FR-01-012.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubmitRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-008, ERR-01-009, ERR-01-010, ERR-01-046, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `DRAFT → SUBMITTED`, `revisionNo + 1`, tạo ba bước `TECHNICAL`, `LEGAL`, `SECURITY` với hạn `onboarding.review.slaWorkingDays`. Chưa đủ điều kiện trả ERR-01-008 kèm `issues` đầy đủ. Cùng giao dịch ghi kiểm toán, outbox EVT-01-01, EVT-01-03 và việc cho hộp việc.
:::

#### API-01-024 · Ghi kết luận thẩm định kỹ thuật

::: dac-ta
**Mục đích.** Ghi kết luận thẩm định kỹ thuật.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/reviews/technical`.

**Quyền.** Người được phân công bước thẩm định (`PERM-01-read` kèm phân công của TA).

**FR hiện thực.** FR-01-013.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** application/json: `TechnicalReviewRequest`; trường bắt buộc: `result`, `confirmedGroup`, `authMethod`, `proposedQuota`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewStepResult`; trường bắt buộc: `stepType`, `result`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-017, ERR-01-019, ERR-01-020, ERR-01-047, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ người được TA phân công bước `TECHNICAL` (IE, SO). `authMethod` không được yếu hơn `minAuthMethod` suy từ mức phân loại cao nhất trong nhu cầu (ERR-01-047). Phát EVT-01-02.
:::

#### API-01-025 · Ghi kết luận thẩm định pháp lý hoặc ATTT

::: dac-ta
**Mục đích.** Ghi kết luận thẩm định pháp lý hoặc ATTT.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/reviews/{reviewKind}`.

**Quyền.** Người được phân công bước thẩm định (`PERM-01-read` kèm phân công của TA).

**FR hiện thực.** FR-01-014.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `reviewKind` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegalSecurityReviewRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewStepResult`; trường bắt buộc: `stepType`, `result`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-016, ERR-01-017, ERR-01-018, ERR-01-019, ERR-01-020, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `legal`: kết luận từng mục (phải đánh giá hết, ERR-01-018; thiếu ý kiến hoặc phạm vi duyệt trả ERR-01-019). `security`: xác nhận cấp độ ATTT. Người đã lập, nộp hay đề nghị bị loại (ERR-01-017). Phát EVT-01-02.
:::

#### API-01-026 · Đánh giá tác động tới hạn mức dữ liệu quốc gia

::: dac-ta
**Mục đích.** Đánh giá tác động tới hạn mức dữ liệu quốc gia.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/reviews/quota-impact`.

**Quyền.** Người được phân công bước thẩm định (`PERM-01-read` kèm phân công của TA).

**FR hiện thực.** FR-01-015.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** application/json: `QuotaImpactRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaImpactResult`; trường bắt buộc: `impact`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-046, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hỏi PH-14 hạn mức quốc gia còn lại; PH-14 không khả dụng thì trả `partial = true` thay vì lỗi. Không đổi dữ liệu.
:::

#### API-01-027 · Hàng đợi thẩm định

::: dac-ta
**Mục đích.** Hàng đợi thẩm định.

**Phương thức, đường dẫn.** `GET /review-queue`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-016.

**Tham số.** `stepType` (query, StepType, tùy chọn); `overdue` (query, boolean, tùy chọn); `mine` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewQueuePage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người thẩm định thấy việc của mình; TA thấy toàn bộ. Việc quá hạn xếp đầu.
:::

#### API-01-028 · Phân công người thẩm định

::: dac-ta
**Mục đích.** Phân công người thẩm định.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/reviews:assign`.

**Quyền.** `PERM-01-approve`.

**FR hiện thực.** FR-01-016.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** application/json: `AssignRequest`; trường bắt buộc: `stepType`, `assigneeId`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewStep`; trường bắt buộc: `stepType`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-017, ERR-01-020, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** TA phân công; người được phân công không được là người lập hoặc nộp (ERR-01-017). Phát EVT-01-02.
:::

#### API-01-029 · Gửi tham vấn, tạm dừng đồng hồ hạn

::: dac-ta
**Mục đích.** Gửi tham vấn, tạm dừng đồng hồ hạn.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/reviews:consult`.

**Quyền.** Người được phân công bước thẩm định (`PERM-01-read` kèm phân công của TA).

**FR hiện thực.** FR-01-016.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** application/json: `ConsultRequest`; trường bắt buộc: `stepType`, `consulteeId`, `question`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewStep`; trường bắt buộc: `stepType`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-020, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đưa bước sang `CONSULTING`, đồng hồ hạn dừng (`pausedMillis` cộng dồn).
:::

#### API-01-030 · Kết thúc tham vấn, chạy lại đồng hồ hạn

::: dac-ta
**Mục đích.** Kết thúc tham vấn, chạy lại đồng hồ hạn.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/reviews:resume`.

**Quyền.** `PERM-01-approve` hoặc `PERM-01-read` (được phân công).

**FR hiện thực.** FR-01-016.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** application/json: `ResumeConsultRequest`; trường bắt buộc: `stepType`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewStep`; trường bắt buộc: `stepType`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-020, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người được phân công hoặc TA kết thúc tham vấn; đồng hồ chạy lại.
:::

#### API-01-031 · Trả bổ sung hồ sơ

::: dac-ta
**Mục đích.** Trả bổ sung hồ sơ.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:return`.

**Quyền.** `PERM-01-approve` hoặc `PERM-01-read` (được phân công).

**FR hiện thực.** FR-01-017.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReturnRequest`; trường bắt buộc: `requests`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SystemDetail`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-017, ERR-01-020, ERR-01-033, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `SUBMITTED → DRAFT` kèm `returnReason` và danh sách yêu cầu theo từng trường; các bước đã `PASS` sao chép sang vòng sau (`CARRIED`). Phát EVT-01-02, EVT-01-03.
:::

#### API-01-032 · Phê duyệt kết nạp

::: dac-ta
**Mục đích.** Phê duyệt kết nạp.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:approve`.

**Quyền.** `PERM-01-approve`.

**FR hiện thực.** FR-01-018.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApproveRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-017, ERR-01-020, ERR-01-035, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `SUBMITTED → APPROVED`, `provisionStage = PROVISIONING`; sinh trần phạm vi từ mục được duyệt, đặt dòng saga `PENDING` trong cùng giao dịch. Người đã lập, nộp, thẩm định bị loại (ERR-01-017). Phát EVT-01-02, EVT-01-03, EVT-01-11.
:::

#### API-01-033 · Từ chối kết nạp

::: dac-ta
**Mục đích.** Từ chối kết nạp.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:reject`.

**Quyền.** `PERM-01-approve`.

**FR hiện thực.** FR-01-018.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-017, ERR-01-020, ERR-01-033, ERR-01-035, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `SUBMITTED → REJECTED` (cuối); mã HTTT không dùng lại. Bắt buộc `comment`.
:::

### Định danh và bàn giao

#### API-01-035 · Thử lại cấp định danh SANDBOX

::: dac-ta
**Mục đích.** Thử lại cấp định danh SANDBOX.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/credentials:provision`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-020.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProvisionRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SagaStatus`; trường bắt buộc: `sagaId`, `stage`, `steps`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-021, ERR-01-022, ERR-01-023, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** TA thử lại cấp định danh khi `provisionStage = PROVISION_FAILED`; tạo saga mới, bước đã `DONE` được bỏ qua. Trả `202` kèm `Location` tới API-01-036.
:::

#### API-01-036 · Tiến độ saga cấp định danh

::: dac-ta
**Mục đích.** Tiến độ saga cấp định danh.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/provisioning`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-020.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SagaStatus`; trường bắt buộc: `sagaId`, `stage`, `steps`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tiến độ từng bước (`RECORD`, `CREATE_CLIENT`, `STORE_SECRET`, `CREATE_CONSUMER`, `ACTIVATE`, `HANDOVER`, `NOTIFY`); không có `secret_ref` hay giá trị bí mật.
:::

#### API-01-037 · Đăng ký khóa công khai (JWKS) hoặc nộp CSR

::: dac-ta
**Mục đích.** Đăng ký khóa công khai (JWKS) hoặc nộp CSR.

**Phương thức, đường dẫn.** `PUT /credentials/{credentialId}/public-key`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-021.

**Tham số.** `credentialId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PublicKeyRequest`; trường bắt buộc: `kind`, `payload`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialKeyResult`; trường bắt buộc: `credentialId`, `expiresAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-021, ERR-01-023, ERR-01-027, ERR-01-028, ERR-01-030, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `JWKS`: chỉ khóa công khai, ES256 (P-256) hoặc PS256 (RSA ≥ 3072 bit), `kid` duy nhất trong client. `CSR`: nộp yêu cầu chứng thư (ký bằng API-01-038). `CERT`: nộp chứng thư do CA hợp lệ cấp. Với `AWAITING_KEY` chuyển `SANDBOX_READY`. Phát EVT-01-05, EVT-01-06.
:::

#### API-01-038 · Ký chứng thư cho CSR đã nộp

::: dac-ta
**Mục đích.** Ký chứng thư cho CSR đã nộp.

**Phương thức, đường dẫn.** `POST /credentials/{credentialId}:sign-csr`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-021.

**Tham số.** `credentialId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `SignCsrRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialKeyResult`; trường bắt buộc: `credentialId`, `expiresAt`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-021, ERR-01-023, ERR-01-028, ERR-01-030, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ký CSR đã nộp bằng `pki-clients` của OpenBao; hạn chứng thư không quá `credential.maxLifetimeDays`. Trả chứng thư PEM công khai.
:::

#### API-01-039 · Tạo liên kết bàn giao một lần

::: dac-ta
**Mục đích.** Tạo liên kết bàn giao một lần.

**Phương thức, đường dẫn.** `POST /credentials/{credentialId}/handovers`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-022.

**Tham số.** `credentialId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `HandoverCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `HandoverCreated`; trường bắt buộc: `handoverId`, `status`, `expiresAt`, `recipient`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-023, ERR-01-030, ERR-01-048, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo bản bọc phản hồi ở OpenBao, lưu băm SHA-256 của liên kết và `wrapAccessor`; thư chỉ chứa liên kết dạng `/ket-noi/ban-giao/{token}`. Người nhận phải là đầu mối `TECHNICAL` đang hoạt động có tài khoản (ERR-01-003). **Không có liên kết gốc trong phản hồi.**.
:::

#### API-01-040 · Mở liên kết bàn giao, nhận bí mật một lần

::: dac-ta
**Mục đích.** Mở liên kết bàn giao, nhận bí mật một lần.

**Phương thức, đường dẫn.** `POST /handovers:open`.

**Quyền.** Đầu mối nhận liên kết, đã đăng nhập và xác thực hai yếu tố.

**FR hiện thực.** FR-01-022.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `HandoverOpenRequest`; trường bắt buộc: `token`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HandoverOpenResult`; trường bắt buộc: `maHeThong`, `thongTinKetNoi`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `410`, `429`, `503`; mã lỗi của thao tác: ERR-01-003, ERR-01-023, ERR-01-024, ERR-01-025, ERR-01-026, ERR-01-035, ERR-01-048, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** API duy nhất của PH-01 trả giá trị bí mật. Người gọi phải là tài khoản của đúng đầu mối nhận, vừa xác thực hai yếu tố (`acr`); mở một lần (chiếm chỗ bằng `UPDATE` có điều kiện), thân phản hồi `Cache-Control: no-store`, không vào log, vết, đệm. Sai người: ERR-01-025 và EVT-01-10. Sai quá `handover.maxFailedOpens` lần: ERR-01-026. OpenBao lỗi: ERR-01-023, liên kết chưa tiêu hao. **Không áp dụng `Idempotency-Key`** vì mã chỉ dùng được một lần, không thử lại.
:::

#### API-01-041 · Tạo lại liên kết bàn giao

::: dac-ta
**Mục đích.** Tạo lại liên kết bàn giao.

**Phương thức, đường dẫn.** `POST /handovers/{handoverId}:reissue`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-022.

**Tham số.** `handoverId` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `HandoverCreated`; trường bắt buộc: `handoverId`, `status`, `expiresAt`, `recipient`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-023, ERR-01-030, ERR-01-048, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hủy bàn giao cũ (`CANCELLED`) và tạo bản bọc mới từ bí mật còn lưu; chỉ khi bí mật chưa từng được mở. Đã mở thì dùng xoay vòng (API-01-045).
:::

#### API-01-042 · Làm mới kết quả kiểm thử SANDBOX

::: dac-ta
**Mục đích.** Làm mới kết quả kiểm thử SANDBOX.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/sandbox-tests`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-023.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SandboxTestResult`; trường bắt buộc: `authOk`, `apiOk`, `callCount`, `required`, `readyToActivate`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-046, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hỏi PH-03, PH-13 nhật ký truy cập theo định danh SANDBOX và tổng hợp lượt gọi thành công. PH-13 không khả dụng: `partial = true`.
:::

#### API-01-043 · Kết quả kiểm thử SANDBOX

::: dac-ta
**Mục đích.** Kết quả kiểm thử SANDBOX.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/sandbox-tests`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-023.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SandboxTestList`; trường bắt buộc: `items`, `readyToActivate`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả các lần kiểm thử đã ghi (giữ 1 năm); `readyToActivate` khi đủ `sandbox.requiredSuccessfulCalls`.
:::

#### API-01-045 · Bắt đầu xoay vòng thông tin xác thực

::: dac-ta
**Mục đích.** Bắt đầu xoay vòng thông tin xác thực.

**Phương thức, đường dẫn.** `POST /credentials/{credentialId}:rotate`.

**Quyền.** `PERM-01-credential` hoặc `PERM-01-suspend`.

**FR hiện thực.** FR-01-025.

**Tham số.** `credentialId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RotateRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `RotateResult`; trường bắt buộc: `credentialId`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-021, ERR-01-023, ERR-01-029, ERR-01-030, ERR-01-033, ERR-01-035, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `ACTIVE → ROTATING`, hai bí mật cùng hiệu lực tới `rotationEndsAt`. `CLIENT_SECRET` tạo bàn giao mới. Do sự cố: `overlapDays = 0` vô hiệu bí mật cũ ngay, bắt buộc `reason`. SO được gọi với `PERM-01-suspend`. Phát EVT-01-06.
:::

#### API-01-046 · Kết thúc thời gian chuyển tiếp xoay vòng

::: dac-ta
**Mục đích.** Kết thúc thời gian chuyển tiếp xoay vòng.

**Phương thức, đường dẫn.** `POST /credentials/{credentialId}:finish-rotation`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-025.

**Tham số.** `credentialId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `FinishRotationRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RotateResult`; trường bắt buộc: `credentialId`, `status`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-030, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết thúc sớm thời gian chuyển tiếp: vô hiệu bí mật cũ, `ROTATING → ACTIVE`. Phát EVT-01-06.
:::

#### API-01-047 · Thu hồi định danh ứng dụng

::: dac-ta
**Mục đích.** Thu hồi định danh ứng dụng.

**Phương thức, đường dẫn.** `POST /credentials/{credentialId}:revoke`.

**Quyền.** `PERM-01-credential` hoặc `PERM-01-suspend`.

**FR hiện thực.** FR-01-026.

**Tham số.** `credentialId` (path, string, bắt buộc); `If-Match` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `RevokeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RevokeResult`; trường bắt buộc: `credentialId`, `status`, `enforcement`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-030, ERR-01-033, ERR-01-034, ERR-01-035, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `ACTIVE | ROTATING → REVOKED` (cuối). Chặn ở cổng trước, đặt trạng thái trước, thử lại cắt quyền tới khi xong (`enforcement` `PENDING` rồi `DONE`, mục tiêu ≤ 60 giây). Cần `confirmImpact = true` khi còn phụ thuộc. Phát EVT-01-07.
:::

#### API-01-048 · Định danh sắp hết hạn

::: dac-ta
**Mục đích.** Định danh sắp hết hạn.

**Phương thức, đường dẫn.** `GET /credentials:expiring`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-027.

**Tham số.** `withinDays` (query, integer, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExpiringPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Định danh còn tới `withinDays` ngày; mặc định mốc nhắc đầu (30 ngày).
:::

#### API-01-049 · Danh sách định danh của HTTT

::: dac-ta
**Mục đích.** Danh sách định danh của HTTT.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/credentials`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-028.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `environment` (query, CredentialEnv, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialList`; trường bắt buộc: `credentials`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không bí mật, không `secret_ref`; kèm `allowedActions`.
:::

#### API-01-050 · Chi tiết một định danh (không bí mật)

::: dac-ta
**Mục đích.** Chi tiết một định danh (không bí mật).

**Phương thức, đường dẫn.** `GET /credentials/{credentialId}`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-028.

**Tham số.** `credentialId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Credential`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Có `ETag`.
:::

#### API-01-061 · Bật lại định danh tự vô hiệu

::: dac-ta
**Mục đích.** Bật lại định danh tự vô hiệu.

**Phương thức, đường dẫn.** `POST /credentials/{credentialId}:enable`.

**Quyền.** `PERM-01-credential`.

**FR hiện thực.** FR-01-036.

**Tham số.** `credentialId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EnableCredentialRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Credential`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-030, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bật lại định danh bị tự vô hiệu vì không hoạt động (`disabledReason = INACTIVE`); không bật được định danh `REVOKED`, `EXPIRED`.
:::

### Vòng đời thành viên

#### API-01-044 · Kích hoạt môi trường thật (PRODUCTION)

::: dac-ta
**Mục đích.** Kích hoạt môi trường thật (PRODUCTION).

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:activate`.

**Quyền.** `PERM-01-approve`.

**FR hiện thực.** FR-01-024.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ActivateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`; `202` đã nhận, xử lý bất đồng bộ, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-017, ERR-01-021, ERR-01-031, ERR-01-032, ERR-01-035, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `APPROVED → ACTIVE`: kiểm đủ kiểm thử SANDBOX (ERR-01-031), yêu cầu xác thực lại hai yếu tố; người kích hoạt không là người nộp (ERR-01-017). Cấp định danh PRODUCTION qua saga: xong trong 10 giây trả `200`, chưa xong trả `202` kèm `progressUrl` (API-01-036). Phát EVT-01-03, EVT-01-05.
:::

#### API-01-051 · Tạm ngừng HTTT

::: dac-ta
**Mục đích.** Tạm ngừng HTTT.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:suspend`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-029.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `SuspendRequest`; trường bắt buộc: `reasonCode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-033, ERR-01-034, ERR-01-035, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `ACTIVE → SUSPENDED`. Cần `confirmImpact = true` khi còn phụ thuộc (ERR-01-034 kèm `dependents`). Chặn ở cổng trước rồi vô hiệu client; mục tiêu ≤ 60 giây (`enforcement`). `If-Match` tùy chọn để SO không bị chặn bởi bản ghi cũ. Phát EVT-01-03, EVT-01-07.
:::

#### API-01-052 · Khôi phục HTTT

::: dac-ta
**Mục đích.** Khôi phục HTTT.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:resume`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-030.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ResumeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StateChangeResult`; trường bắt buộc: `code`, `status`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-032, ERR-01-033, ERR-01-035, ERR-01-036, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `SUSPENDED → ACTIVE`. Tạm ngừng do `SECURITY_SUSPECT` phải có đồng ý của SO và `confirmCredentialsRotated` (ERR-01-036). Phát EVT-01-03.
:::

#### API-01-053 · Đề nghị chấm dứt tư cách thành viên

::: dac-ta
**Mục đích.** Đề nghị chấm dứt tư cách thành viên.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:terminate`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-031.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TerminateRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ChangeRequest`; trường bắt buộc: `id`, `changeClass`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-033, ERR-01-034, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo đề nghị `TERMINATE` chờ TA khác duyệt qua API-01-059 (bốn mắt, ERR-01-017). Chưa đổi trạng thái HTTT.
:::

#### API-01-054 · Tạm ngừng hoặc thu hồi khẩn của Cán bộ ATTT

::: dac-ta
**Mục đích.** Tạm ngừng hoặc thu hồi khẩn của Cán bộ ATTT.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}:emergency-action`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-032.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `If-Match` (header, string, tùy chọn); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EmergencyRequest`; trường bắt buộc: `mode`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `EmergencyResult`; trường bắt buộc: `actionId`, `status`, `confirmBy`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-033, ERR-01-035, ERR-01-036, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** SO tạm ngừng hoặc chấm dứt ngay, TA phải xác nhận trong `emergency.confirmHours` (API-01-055). Chặn cổng trước. `If-Match` tùy chọn. Phát EVT-01-15, EVT-01-03, EVT-01-07.
:::

#### API-01-055 · Xác nhận thao tác khẩn

::: dac-ta
**Mục đích.** Xác nhận thao tác khẩn.

**Phương thức, đường dẫn.** `POST /emergency-actions/{actionId}:confirm`.

**Quyền.** `PERM-01-approve`.

**FR hiện thực.** FR-01-032.

**Tham số.** `actionId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConfirmEmergencyRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EmergencyResult`; trường bắt buộc: `actionId`, `status`, `confirmBy`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-017, ERR-01-035, ERR-01-036, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** TA xác nhận thao tác khẩn của SO (không phải người đã thực hiện). Phát EVT-01-15.
:::

#### API-01-056 · Phân tích tác động phụ thuộc

::: dac-ta
**Mục đích.** Phân tích tác động phụ thuộc.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/impact`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-033.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImpactResult`; trường bắt buộc: `impactLevel`, `partial`, `dependents`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-046, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổng hợp phụ thuộc từ PH-02, PH-04, PH-05, PH-10, PH-14 (hạn 3 giây mỗi nơi); nơi nào lỗi thì `partial = true`. Không trả liên hệ cá nhân.
:::

#### API-01-057 · Đề nghị thay đổi hồ sơ HTTT đã kết nạp

::: dac-ta
**Mục đích.** Đề nghị thay đổi hồ sơ HTTT đã kết nạp.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/change-requests`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-034.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ChangeRequestCreate`; trường bắt buộc: `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ChangeRequestOutcome`; trường bắt buộc: `applied`; `202` đã nhận, xử lý bất đồng bộ, `ChangeRequestOutcome`; trường bắt buộc: `applied`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-037, ERR-01-038, ERR-01-049, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân loại thay đổi theo bảng mức duyệt (FRS §6.5): mức `NONE` áp dụng ngay (`200`, phát EVT-01-04); `TECHNICAL`, `OWNER_CHANGE`, `FULL` tạo đề nghị chờ duyệt (`202`). Thay đổi làm rộng trần phải đi qua API-01-060 (ERR-01-037).
:::

#### API-01-058 · Danh sách đề nghị thay đổi

::: dac-ta
**Mục đích.** Danh sách đề nghị thay đổi.

**Phương thức, đường dẫn.** `GET /systems/{systemCode}/change-requests`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-034.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `status` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChangeRequestList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Các đề nghị thay đổi của HTTT theo trạng thái, gồm đề nghị chấm dứt (`TERMINATE`) và mở rộng phạm vi (`FULL`).
:::

#### API-01-059 · Duyệt hoặc từ chối đề nghị thay đổi, chấm dứt

::: dac-ta
**Mục đích.** Duyệt hoặc từ chối đề nghị thay đổi, chấm dứt.

**Phương thức, đường dẫn.** `POST /change-requests/{changeRequestId}:decide`.

**Quyền.** `PERM-01-approve`.

**FR hiện thực.** FR-01-031, FR-01-034, FR-01-035.

**Tham số.** `changeRequestId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ChangeDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChangeRequestOutcome`; trường bắt buộc: `applied`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-005, ERR-01-017, ERR-01-033, ERR-01-035, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** TA khác người đề nghị duyệt hoặc từ chối (SO thêm khi thay đổi cấp độ ATTT). Duyệt `TERMINATE` thực hiện chấm dứt: thu hồi định danh, trần về rỗng. Phát EVT-01-03, 04, 07, 11 tùy loại.
:::

#### API-01-060 · Đề nghị mở rộng trần phạm vi khai thác

::: dac-ta
**Mục đích.** Đề nghị mở rộng trần phạm vi khai thác.

**Phương thức, đường dẫn.** `POST /systems/{systemCode}/scope-expansions`.

**Quyền.** `PERM-01-create`.

**FR hiện thực.** FR-01-035.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ScopeExpansionCreate`; trường bắt buộc: `demands`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ChangeRequest`; trường bắt buộc: `id`, `changeClass`, `status`, `requestedBy`, `requestedAt`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-015, ERR-01-016, ERR-01-038, ERR-01-047, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo đề nghị `FULL`: đi lại bước thẩm định pháp lý rồi TA duyệt. Duyệt xong trần mở rộng, phát EVT-01-11.
:::

### Nội bộ (phân hệ khác)

#### API-01-062 · Chạy đối chiếu và phát ảnh chụp trạng thái

::: dac-ta
**Mục đích.** Chạy đối chiếu và phát ảnh chụp trạng thái.

**Phương thức, đường dẫn.** `POST /internal/reconciliations`.

**Quyền.** Token dịch vụ, scope `onboarding:reconcile`.

**FR hiện thực.** FR-01-037.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReconcileRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ReconcileAccepted`; trường bắt buộc: `reconciliationId`, `batches`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát ảnh chụp trạng thái theo lô (`snapshot = true`, EVT-01-03) cho phân hệ tiêu thụ đối chiếu. Hằng giờ có tác vụ tự chạy; API này để chạy theo yêu cầu sau sự cố.
:::

#### API-01-063 · Bản sao đọc danh sách HTTT cho phân hệ khác

::: dac-ta
**Mục đích.** Bản sao đọc danh sách HTTT cho phân hệ khác.

**Phương thức, đường dẫn.** `GET /internal/systems`.

**Quyền.** Token dịch vụ, scope `onboarding:internal-read`.

**FR hiện thực.** FR-01-038.

**Tham số.** `updatedSince` (query, string, tùy chọn); `status` (query, array, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplicaPage`; trường bắt buộc: `items`, `nextUpdatedSince`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đồng bộ gia tăng bằng `updatedSince`; dùng khi khởi tạo bản sao và đối chiếu, còn lại nghe EVT-01-03. Không có liên hệ cá nhân, bí mật.
:::

#### API-01-064 · Bản sao đọc một HTTT cho phân hệ khác

::: dac-ta
**Mục đích.** Bản sao đọc một HTTT cho phân hệ khác.

**Phương thức, đường dẫn.** `GET /internal/systems/{systemCode}`.

**Quyền.** Token dịch vụ, scope `onboarding:internal-read`.

**FR hiện thực.** FR-01-038.

**Tham số.** `systemCode` (path, SystemCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReplicaSystem`; trường bắt buộc: `code`, `name`, `ownerOrgId`, `status`, `roles`, `securityLevel`, `updatedAt`; tiêu đề `ETag`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tra một HTTT (cùng trường rút gọn với API-01-063).
:::

#### API-01-087 · Nhận kết quả bất đồng bộ của bước saga

::: dac-ta
**Mục đích.** Nhận kết quả bất đồng bộ của bước saga.

**Phương thức, đường dẫn.** `POST /internal/provisioning-callbacks`.

**Quyền.** Token dịch vụ, scope `onboarding:provision-callback`.

**FR hiện thực.** FR-01-020.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ProvisioningCallback`; trường bắt buộc: `sagaId`, `step`, `outcome`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CallbackAck`; trường bắt buộc: `sagaId`, `step`, `accepted`, `duplicate`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-01-003, ERR-01-053, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-12, PH-03 trả kết quả bước saga ở trạng thái `ACCEPTED` khi `onboarding.saga.async-callback = true` (SDD §4.6). Kiểm token dịch vụ, `sagaId` và tenant của token; lũy đẳng theo `(sagaId, step)` (lặp trả `duplicate = true`). Quá 5 phút không có callback thì bước coi như thất bại.
:::

### Rà soát quyền định kỳ

#### API-01-065 · Mở kỳ rà soát quyền

::: dac-ta
**Mục đích.** Mở kỳ rà soát quyền.

**Phương thức, đường dẫn.** `POST /access-reviews`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-039.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AccessReviewCreate`; trường bắt buộc: `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AccessReviewCycle`; trường bắt buộc: `cycleCode`, `name`, `kind`, `status`, `itemCount`, `openedAt`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-01-003, ERR-01-039, ERR-01-044, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chụp danh sách mục (cặp HTTT, phạm vi) của HTTT `ACTIVE`; kỳ định kỳ cập nhật mốc rà soát toàn tenant. Chỉ một kỳ mở một lúc (ERR-01-039).
:::

#### API-01-066 · Danh sách kỳ rà soát

::: dac-ta
**Mục đích.** Danh sách kỳ rà soát.

**Phương thức, đường dẫn.** `GET /access-reviews`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-039.

**Tham số.** `status` (query, array, tùy chọn); `kind` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessReviewPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Các kỳ rà soát của tenant, kỳ mới nhất trước.
:::

#### API-01-067 · Chi tiết kỳ rà soát

::: dac-ta
**Mục đích.** Chi tiết kỳ rà soát.

**Phương thức, đường dẫn.** `GET /access-reviews/{cycleCode}`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-039.

**Tham số.** `cycleCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessReviewCycle`; trường bắt buộc: `cycleCode`, `name`, `kind`, `status`, `itemCount`, `openedAt`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết kỳ rà soát, số phiếu đã gửi và đã trả lời.
:::

#### API-01-068 · Mục rà soát và mức sử dụng

::: dac-ta
**Mục đích.** Mục rà soát và mức sử dụng.

**Phương thức, đường dẫn.** `GET /access-reviews/{cycleCode}/items`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-040.

**Tham số.** `cycleCode` (path, string, bắt buộc); `flag` (query, array, tùy chọn); `ownerOrgId` (query, OrgId, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `decided` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessReviewItemPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `401`, `403`, `404`, `503`; mã lỗi của thao tác: ERR-01-001, ERR-01-046, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mức sử dụng mỗi phạm vi lấy từ PH-13 (đồng thời ≤ `dh.onboarding.usage.concurrency`); PH-13 lỗi thì `usagePartial = true`.
:::

#### API-01-069 · Gửi phiếu xác nhận cho đơn vị chủ quản

::: dac-ta
**Mục đích.** Gửi phiếu xác nhận cho đơn vị chủ quản.

**Phương thức, đường dẫn.** `POST /access-reviews/{cycleCode}:send-confirmations`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-041.

**Tham số.** `cycleCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SendConfirmationsRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SendConfirmationsAccepted`; trường bắt buộc: `sent`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-020, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gửi phiếu xác nhận (liên kết 256 bit, hạn `accessReview.confirmLinkTtlDays`) tới đầu mối của từng tổ chức; kỳ `OPEN → WAITING`. Tổ chức không có đầu mối được liệt kê ở `orgsWithoutContact`.
:::

#### API-01-070 · Xem phiếu xác nhận của đơn vị

::: dac-ta
**Mục đích.** Xem phiếu xác nhận của đơn vị.

**Phương thức, đường dẫn.** `GET /access-review-confirmations/{token}`.

**Quyền.** Đầu mối nhận liên kết, đã đăng nhập và xác thực hai yếu tố.

**FR hiện thực.** FR-01-041.

**Tham số.** `token` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConfirmationView`; trường bắt buộc: `orgId`, `cycleCode`, `expiresAt`, `items`; tiêu đề `Cache-Control`.

**Lỗi.** HTTP `401`, `403`, `404`, `410`; mã lỗi của thao tác: ERR-01-001, ERR-01-025, ERR-01-040, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đầu mối của đúng tổ chức, đã đăng nhập, mở phiếu. Phiếu đã trả lời hoặc hết hạn trả ERR-01-040 (thân giống nhau cho mọi nguyên nhân). `Cache-Control: no-store`.
:::

#### API-01-071 · Đơn vị trả lời phiếu xác nhận

::: dac-ta
**Mục đích.** Đơn vị trả lời phiếu xác nhận.

**Phương thức, đường dẫn.** `POST /access-review-confirmations/{token}:respond`.

**Quyền.** Đầu mối nhận liên kết, đã đăng nhập và xác thực hai yếu tố.

**FR hiện thực.** FR-01-041.

**Tham số.** `token` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConfirmationRespond`; trường bắt buộc: `answers`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConfirmationRespondResult`; trường bắt buộc: `answered`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `410`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-025, ERR-01-040, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mỗi mục trả lời `KEEP`, `REDUCE` (kèm `scopeReduced`) hoặc `RELEASE`; trả lời một lần.
:::

#### API-01-072 · Quyết định thu hẹp hoặc thu hồi phạm vi

::: dac-ta
**Mục đích.** Quyết định thu hẹp hoặc thu hồi phạm vi.

**Phương thức, đường dẫn.** `POST /access-reviews/{cycleCode}/items:decide`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-042.

**Tham số.** `cycleCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ItemDecisionRequest`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ItemDecisionResult`; trường bắt buộc: `decided`, `cycleStatus`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-020, ERR-01-033, ERR-01-035, ERR-01-041, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Quyết định `KEEP`, `NARROW`, `REVOKE_SCOPE`; mục có văn bản hết hiệu lực không được `KEEP` (ERR-01-041). Đủ quyết định thì kỳ `CLOSED`, ghi băm bằng chứng, phát EVT-01-11, EVT-01-12.
:::

#### API-01-073 · Đánh dấu văn bản pháp lý hết hiệu lực

::: dac-ta
**Mục đích.** Đánh dấu văn bản pháp lý hết hiệu lực.

**Phương thức, đường dẫn.** `POST /scope-ceilings:mark-legal-expired`.

**Quyền.** `PERM-01-suspend`.

**FR hiện thực.** FR-01-043.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `MarkLegalExpiredRequest`; trường bắt buộc: `docNo`, `repealedOn`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MarkLegalExpiredResult`; trường bắt buộc: `affectedCeilings`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đánh dấu thủ công văn bản bị bãi bỏ: các trần dẫn văn bản đó chuyển `SUSPENDED`, HTTT bị ảnh hưởng nhận thông báo. Phát EVT-01-11.
:::

#### API-01-074 · Báo cáo rà soát quyền

::: dac-ta
**Mục đích.** Báo cáo rà soát quyền.

**Phương thức, đường dẫn.** `GET /access-reviews/{cycleCode}/report`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-044.

**Tham số.** `cycleCode` (path, string, bắt buộc); `format` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewReport`; trường bắt buộc: `cycleCode`, `status`, `summary`.

**Lỗi.** HTTP `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-020, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `Accept: application/pdf` hoặc XLSX để tải tệp; mặc định JSON tóm tắt.
:::

#### API-01-075 · Xuất báo cáo rà soát quyền

::: dac-ta
**Mục đích.** Xuất báo cáo rà soát quyền.

**Phương thức, đường dẫn.** `POST /access-reviews/{cycleCode}/report:export`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-044.

**Tham số.** `cycleCode` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReportExportRequest`; trường bắt buộc: `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-020, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy nền, trả `202` kèm `Location` tới API-01-088.
:::

### Danh bạ đầu mối

#### API-01-076 · Tra cứu danh bạ đầu mối

::: dac-ta
**Mục đích.** Tra cứu danh bạ đầu mối.

**Phương thức, đường dẫn.** `GET /directory/contacts`.

**Quyền.** Quyền cơ sở người dùng nội bộ tenant (không cần mã quyền riêng).

**FR hiện thực.** FR-01-045.

**Tham số.** `q` (query, string, tùy chọn); `orgId` (query, OrgId, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `contactType` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DirectoryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`; mã lỗi của thao tác: ERR-01-003, ERR-01-045, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ đầu mối công khai (BR-01-027); giới hạn `directory.rateLimitPerMinute` mỗi người dùng.
:::

#### API-01-077 · Đầu mối của một tổ chức

::: dac-ta
**Mục đích.** Đầu mối của một tổ chức.

**Phương thức, đường dẫn.** `GET /directory/organizations/{orgId}/contacts`.

**Quyền.** Quyền cơ sở người dùng nội bộ tenant (không cần mã quyền riêng).

**FR hiện thực.** FR-01-045.

**Tham số.** `orgId` (path, OrgId, bắt buộc); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DirectoryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** HTTP `401`, `403`, `404`, `429`; mã lỗi của thao tác: ERR-01-001, ERR-01-045, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đầu mối công khai của một tổ chức (BR-01-027); cùng giới hạn tốc độ với API-01-076.
:::

#### API-01-078 · Tổ chức thiếu đầu mối và đầu mối cần xác nhận

::: dac-ta
**Mục đích.** Tổ chức thiếu đầu mối và đầu mối cần xác nhận.

**Phương thức, đường dẫn.** `GET /directory/gaps`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-046.

**Tham số.** `kind` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DirectoryGaps`; trường bắt buộc: `orgsWithoutTechnicalContact`, `staleContacts`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổ chức có HTTT thiếu đầu mối kỹ thuật hoạt động, và đầu mối quá `directory.staleMonths` chưa xác nhận.
:::

#### API-01-079 · Xuất danh bạ đầu mối

::: dac-ta
**Mục đích.** Xuất danh bạ đầu mối.

**Phương thức, đường dẫn.** `POST /directory/contacts:export`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportRequest`; trường bắt buộc: `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `JobAccepted`; trường bắt buộc: `jobId`, `status`; `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`; mã lỗi của thao tác: ERR-01-003, ERR-01-033, ERR-01-045, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xuất toàn bộ danh bạ chỉ TA, AU; bắt buộc `purpose`, ghi kiểm toán xuất. Nhỏ: `200` tệp; lớn: `202` kèm `Location`.
:::

### Di trú, tham số, thống kê

#### API-01-080 · Tải tệp nhập HTTT từ hệ cũ

::: dac-ta
**Mục đích.** Tải tệp nhập HTTT từ hệ cũ.

**Phương thức, đường dẫn.** `POST /legacy-imports`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-01-048.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: `LegacyImportUpload`; trường bắt buộc: `file`, `source`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `LegacyImportJob`; trường bắt buộc: `jobId`, `status`, `rowCount`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`; mã lỗi của thao tác: ERR-01-003, ERR-01-042, ERR-01-044, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đọc tệp, bỏ mọi cột bí mật (chỉ đếm `secretsDropped`), đối chiếu tổ chức, trả bản xem trước. Chưa tạo hồ sơ nào.
:::

#### API-01-081 · Kết quả xem trước và nhập hệ cũ

::: dac-ta
**Mục đích.** Kết quả xem trước và nhập hệ cũ.

**Phương thức, đường dẫn.** `GET /legacy-imports/{jobId}`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-01-048.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `jobId`, `status`, `rowCount`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái tác vụ nhập, bản xem trước và số dòng tạo, bỏ qua, cảnh báo.
:::

#### API-01-082 · Xác nhận tạo hồ sơ nháp từ tệp nhập

::: dac-ta
**Mục đích.** Xác nhận tạo hồ sơ nháp từ tệp nhập.

**Phương thức, đường dẫn.** `POST /legacy-imports/{jobId}:confirm`.

**Quyền.** `PERM-18-migration`.

**FR hiện thực.** FR-01-048.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegacyImportConfirm`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `jobId`, `status`, `rowCount`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-043, ERR-01-044, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo hồ sơ `DRAFT` cho dòng `CREATE` (chỉ mục duy nhất `(tenant, legacy_ref)` chặn nhân đôi); HTTT cũ chưa có định danh mới phải được cấp lại qua quy trình thường.
:::

#### API-01-083 · Tham số `onboarding.*` của tenant

::: dac-ta
**Mục đích.** Tham số `onboarding.*` của tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-049.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SettingList`; trường bắt buộc: `items`.

**Lỗi.** HTTP `401`, `403`; mã lỗi của thao tác: ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** 30 khóa `onboarding.*` (FRS §8.2) kèm mặc định, miền, trần PA.
:::

#### API-01-084 · Sửa một tham số của tenant

::: dac-ta
**Mục đích.** Sửa một tham số của tenant.

**Phương thức, đường dẫn.** `PUT /settings/{key}`.

**Quyền.** `PERM-18-config`.

**FR hiện thực.** FR-01-049.

**Tham số.** `key` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingPut`; trường bắt buộc: `value`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Setting`; trường bắt buộc: `key`, `value`, `default`, `version`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`; mã lỗi của thao tác: ERR-01-001, ERR-01-003, ERR-01-007, ERR-01-033, ERR-01-035, ERR-01-044, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** TA, PA; vượt miền hoặc trần PA trả ERR-01-044. Chỉ áp cho thao tác mới.
:::

#### API-01-085 · Xuất danh sách HTTT thành viên

::: dac-ta
**Mục đích.** Xuất danh sách HTTT thành viên.

**Phương thức, đường dẫn.** `POST /systems:export`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-050.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExportRequest`; trường bắt buộc: `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `JobAccepted`; trường bắt buộc: `jobId`, `status`; `202` đã nhận, xử lý bất đồng bộ, `JobAccepted`; trường bắt buộc: `jobId`, `status`; tiêu đề `Location`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`; mã lỗi của thao tác: ERR-01-003, ERR-01-051, ERR-01-054, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xuất toàn bộ tenant chỉ TA, AU, PA; không có cột bí mật. Nhỏ: `200` tệp; lớn: `202` kèm `Location`.
:::

#### API-01-086 · Thống kê kết nạp và thời gian xử lý

::: dac-ta
**Mục đích.** Thống kê kết nạp và thời gian xử lý.

**Phương thức, đường dẫn.** `GET /statistics`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-051.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `ownerOrgId` (query, OrgId, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StatisticsView`; trường bắt buộc: `from`, `to`, `byStatus`.

**Lỗi.** HTTP `400`, `401`, `403`; mã lỗi của thao tác: ERR-01-003, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mặc định 90 ngày gần nhất.
:::

#### API-01-088 · Tra tác vụ nền xuất tệp hoặc báo cáo

::: dac-ta
**Mục đích.** Tra tác vụ nền xuất tệp hoặc báo cáo.

**Phương thức, đường dẫn.** `GET /jobs/{jobId}`.

**Quyền.** `PERM-01-read`.

**FR hiện thực.** FR-01-044, FR-01-047, FR-01-050.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Job`; trường bắt buộc: `jobId`, `kind`, `status`, `createdAt`.

**Lỗi.** HTTP `401`, `403`, `404`; mã lỗi của thao tác: ERR-01-001, ERR-01-052 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ người tạo tác vụ hoặc TA, AU. `downloadUrl` là liên kết ký, hết hạn 15 phút.
:::

<!-- gen:dac-ta-api:end -->

## 11. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây thuộc tài liệu dùng chung hoặc tập khác của PH-01 và phân hệ khác, nằm ngoài quyền sửa của tập này; ghi lại để đợt đồng bộ cuối thực hiện.

| # | Tài liệu | Đề nghị |
|---|---|---|
| 1 | D02-03-PH01 (FRS) | **Đã đồng bộ ở bản 0.2 (FRS: mã, bảng lỗi, thông báo, đầu ra 200 hoặc 202).** §9.4: thêm API-01-087 (`POST /internal/provisioning-callbacks`, FR-01-020) và API-01-088 (`GET /jobs/{jobId}`, FR-01-044, 047, 050), sửa câu "86 operation" thành 88. §9.1: thêm ERR-01-051 (409), 052 (401, 403), 053 (409), 054 (409). §6: FR-01-024 đầu ra `200` hoặc `202` kèm `progressUrl`; FR-01-034 đầu ra `200` hoặc `202`; FR-01-044, 047, 050 ghi `202` kèm tác vụ nền tra bằng API-01-088; FR-01-001 trả `page{number, size, totalElements, totalPages}` (phân trang từ 0); FR-01-022 mở bàn giao là `POST` mang `token` trong thân |
| 2 | D02-04-PH01 (use case) | **Đã đồng bộ ở bản 0.2 (UC).** Bảng UC → API: thêm API-01-087 vào UC-01-13; API-01-088 vào UC-01-01, UC-01-29, UC-01-30 |
| 3 | D03-02-PH01 (SDD) | **Đã đồng bộ ở bản 0.2 (SDD).** §8.2: đổi "ERR-01-003 kèm `type = idempotency-mismatch`" thành ERR-01-051, thêm ERR-01-054 cho yêu cầu cùng khóa đang xử lý; §4.6: callback saga là API-01-087 và ERR-01-053; §4.7: mở bàn giao là `POST /handovers:open`, không dùng `Idempotency-Key`; Q01-28: tham chiếu Q01-56 của tập này |
| 4 | D03-03-PH01 (CSDL) | **Một phần:** phần `idempotency_record` đã sửa; bảng `background_job` ghi ở đề nghị đồng bộ số 12 của CSDL, chờ Q01-57. Thêm bảng `background_job` cho tác vụ xuất tệp (Q01-57); `idempotency_record` ghi ERR-01-051 cho lệch thân; ghi `ETag` là `version` (đã có ở đề nghị đồng bộ #3 của CSDL) |
| 5 | D03-06-PH01 (màn hình) | **Đã đồng bộ ở bản 0.2 (MH §5.2 có 53 câu, ERR-01-053 chỉ ghi nhật ký).** §5.2: thêm các câu ở chương 6.2 của tập này (ERR-01-001, 003, 005, 009, 012, 013, 014, 019, 020, 022, 026, 028, 030, 032, 038, 041, 042, 043, 044, 048, 049, 051…054); hiển thị toàn bộ `issues[]` của API-01-022 một lần; hiển thị `enforcement` và `progressUrl` cho lệnh cắt quyền, kích hoạt; BFF đổi `trang` (từ 1) sang `page` (từ 0) |
| 6 | D04-01 (quy ước mã) | Chốt Q01-58: mã lỗi riêng của phân hệ (ERR-01-007 cho `If-Match` lệch) hay mã chung `ERR-00-412`; mẫu `type` của RFC 9457 là `https://datahub.gov.vn/errors/ERR-{PH}-nnn` (theo K-API; D03-04-PH05 đang dùng `…/problems/adapter/err-05-nnn`, cần thống nhất) |
| 7 | D03-07 | SEC-33: ghi API-01-040 là điểm duy nhất trả giá trị bí mật, kiểm bằng `check_contracts.py` ở CI-5; cổng API che đoạn `{token}` trong log truy cập (Q01-55); thêm giới hạn tốc độ mở bàn giao theo địa chỉ IP vào SEC-23 hoặc SEC-44 |
| 8 | D03-09 (hạ tầng) | Kafka: 15 topic `connect` (3 phân vùng, giữ 7 ngày); Apicurio đăng ký 15 lược đồ chế độ `BACKWARD`; APISIX: tuyến `/api/onboarding/v1` (người dùng, giới hạn 300 yêu cầu mỗi phút) và `/internal/*` (chỉ trong cụm, 600 yêu cầu mỗi phút); tên dịch vụ `dh-connect.dh-control.svc` |
| 9 | Tập PH-12, PH-03 | Cung cấp giao diện ở chương 5.1 (tạo, vô hiệu client lũy đẳng, thu hồi token, đăng ký khóa, xoay bí mật, gỡ scope; consumer, chặn client ≤ 60 giây); chốt đồng bộ hay bất đồng bộ (Q01-56); nếu bất đồng bộ thì gọi API-01-087 bằng token dịch vụ `onboarding:provision-callback`; PH-12 phát sự kiện tài khoản đầu mối vô hiệu, đổi tổ chức |
| 10 | Tập PH-02, PH-04, PH-05, PH-10, PH-13, PH-14, PH-15 | Gọi API-01-063, 064 bằng token `onboarding:internal-read` khi khởi tạo và đối chiếu, nghe EVT-01-03, 04, 11; PH-02 gọi `checkWithinCeiling` (Q01-02); PH-13 cung cấp `sandboxActivity`, `usageByCredential`, `usageByScope`; PH-14 cung cấp `remainingQuota` |
| 11 | Tập PH-18, PH-20 | PH-18: `NotificationApi` (có chế độ gửi đồng bộ cho thư mang liên kết), `WorkingCalendarApi`, `ParameterApi` cho 30 khóa `onboarding.*`, phát sự kiện thư bị trả lại; PH-20: tra tổ chức, sự kiện đổi tổ chức, tạm ngừng tenant; chốt tên topic của ba loại sự kiện PH-01 tiêu thụ (Q01-13) |
| 12 | D00-03 phần B | Ghi ánh xạ LGC → API: LGC-APIM-019 → API-01-001; LGC-APIM-020 → API-01-004, 032, 035; LGC-HUB-010, 011 → API-01-063, 064, 080 |
| 13 | D00-04 §2, §3.2 | §2: PH-01 cột "Tài liệu" thành "FRS 0.1, UC 0.1, SDD 0.1, CSDL 0.1, API 0.1"; §3.2: chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để thêm API 001…088, EVT 01…15, ERR 001…054 của PH-01 |
| 14 | D05-02-PH01 (kiểm thử) | Ca cho mỗi mã ERR-01 ở chương 6; ca canary quét phản hồi, sự kiện, tệp xuất; ca lũy đẳng (cùng khóa cùng thân, khác thân, đang xử lý); ca `If-Match` lệch và thao tác khẩn không cần `If-Match`; ca mở bàn giao hai lần đồng thời |
| 15 | `build/tools/sinh_dac_ta_api.py` | Cột "Quyền" chỉ đọc `x-datahub-permission.permission`; operation có `anyOf` hoặc chỉ có `serviceScope` (như API-05-039 của PH-05) bị in là "Token dịch vụ". Đề nghị script đọc `anyOf` (nối bằng "hoặc") và `serviceScope` (in kèm tên scope). Tập PH-01 đã đặt sẵn chuỗi `permission` cho mọi operation nên không bị lệch |
| 16 | D03-06-PH01 Phụ lục B (nội bộ PH-01) | Bảy đề nghị bổ sung API của tập màn hình chưa được tập này xử lý: (1) tự nhận việc thẩm định cho đúng vai trò (API-01-028 hiện chỉ `PERM-01-approve`); (2) API-01-069 nhận `organizationIds[]`; (3) `waitingFor`, `dueAt`, `flags[]` ở API-01-001, 002 (`allowedActions`, `disabledReasons` đã có); (4) API-01-008 hỗ trợ `Range` và `Content-Disposition: inline`; (5) cờ `stateSecret` ở API-01-013; (6) `handoverToken` ở API-01-045; (7) `platformMax`, `securityRelated` ở API-01-083, 084. Giao diện đã có xử lý tạm thời cho từng việc; cần chốt ở lần soát hợp đồng tới, riêng (1) cần quyết định quyền ở D02-08 trước (Q01-45, Q01-47) |
| 17 | Đề xuất ADR (chưa cấp số) | (a) **Hợp đồng API và sự kiện sinh từ bảng mã là nguồn chuẩn**, kiểm ở CI-5 (ví dụ khớp lược đồ, mã liên tục, bảng lỗi khớp FRS, chặn trường bí mật) và áp cho mọi phân hệ; (b) **một API duy nhất trả bí mật, một lần, qua `POST` mang mã trong thân**, mẫu cho PH-12, PH-19 (khóa webhook) khi có việc tương tự |

: Đề nghị đồng bộ với tài liệu dùng chung và phân hệ khác

Đề nghị 1, 2, 3, 5 đã làm ở lần rà soát chéo bản 0.2 của PH-01 (đề nghị 4 còn chờ Q01-57); các đề nghị còn lại gửi tài liệu dùng chung hoặc phân hệ khác. Đề nghị 9 và 10 chặn việc viết tập API của PH-12, PH-03, PH-02 nên cần chuyển sớm.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 88 endpoint REST, 15 sự kiện Kafka, 54 mã lỗi ERR-01, ánh xạ từ hệ cũ, 5 câu hỏi mở, đề nghị đồng bộ; OpenAPI 3.1 và AsyncAPI 3.0 sinh bằng script, đã kiểm trong CI |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: API-01-059 thêm FR-01-035; ghi trạng thái đồng bộ các đề nghị 1 đến 5; thêm đề nghị 16 về bảy đề nghị bổ sung API của tập màn hình (OpenAPI cập nhật x-datahub-fr của API-01-059) |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: mã API-12-058…068 ở bảng giao tiếp PH-12; chốt câu hỏi mở đợt đồng bộ: Q418 (Q01-57), Q380 (EVT-01-11 không còn bên nghe PH-12); Q395 |
