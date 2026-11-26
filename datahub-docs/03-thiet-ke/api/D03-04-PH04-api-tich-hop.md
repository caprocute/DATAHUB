---
ma_tai_lieu: D03-04-PH04
ten: Đặc tả API và sự kiện phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kiến trúc sư, lập trình viên L-INT và frontend console, kiểm thử viên, vận hành
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
mo_ta: Đặc tả 70 operation REST, 14 sự kiện Kafka và bảng mã lỗi ERR-04 của phân hệ Lõi tích hợp và trình thiết kế luồng, sinh từ OpenAPI và AsyncAPI đã kiểm khớp ví dụ, dùng để hiện thực, kiểm thử và thẩm định giao diện lập trình.
tai_lieu_lien_quan: D02-03-PH04 FRS; D02-04-PH04 Use case; D03-02-PH04 SDD; D03-03-PH04 CSDL; D03-06-PH04 Màn hình; D04-01 Quy ước mã
---

# D03-04-PH04 · Đặc tả API và sự kiện phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

PH-04 có hai loại giao diện lập trình, phục vụ hai đối tượng khác nhau:

1. **API điều khiển** của `dh-integration` (module `flow`). Chỉ giao diện Datahub gọi API này, cho người thiết kế, người duyệt và người vận hành luồng. Nó bao gồm không gian làm việc, luồng, phiên bản, kiểm tra hợp lệ, chạy thử, duyệt bốn mắt, triển khai GitOps, lệnh tạm dừng và dừng khẩn, catalog thành phần, khuôn mẫu.
2. **Sự kiện Kafka** báo các mốc vòng đời luồng cho phân hệ khác (PH-02, PH-13, PH-18). Ngoài ra có ba topic hệ thống giữa control plane và runtime: lệnh có ký, nhịp tim, xác nhận lệnh.

HTTT thành viên **không** gọi API điều khiển. Chúng gọi chính các luồng đã phát hành qua APISIX. Hợp đồng của từng luồng đối ngoại được công bố ở PH-02. Lỗi do runtime trả cho bên gọi luồng (ERR-04-101…112) được chuẩn hóa ở §6.2.

So với Bus cũ, API mới bỏ hẳn các điểm yếu sau:

- Không còn thao tác Start/Stop qua JMX-Jolokia. Thay bằng lệnh có ký, hạn 60 giây, xác nhận theo từng bản sao.
- Không còn sửa XML trực tiếp trên máy chủ chạy. Mọi thay đổi đi qua phiên bản bất biến, chạy thử đạt, duyệt bốn mắt, rồi mới vào Git.
- Mọi thao tác có lý do, có kiểm toán và có mã lỗi tiếng Việt.

Tài liệu này là văn xuôi giải thích hai tệp hợp đồng. Khi văn xuôi và tệp hợp đồng khác nhau, **tệp hợp đồng là nguồn sự thật**:

| Tệp | Nội dung | Quy mô |
|---|---|---|
| [`ph04/openapi-integration.yaml`](ph04/openapi-integration.yaml) | API REST điều khiển (OpenAPI 3.1) | 70 operation, 51 mã API-04, 105 lược đồ |
| [`ph04/asyncapi-integration.yaml`](ph04/asyncapi-integration.yaml) | Sự kiện Kafka (AsyncAPI 3.0) | 14 kênh EVT-04-01…14 |
| [`ph04/tools/`](ph04/tools/) | `gen_openapi.py` (nhập `bo_sung.py`: mô tả, ví dụ), `gen_asyncapi.py` sinh hai tệp trên; `gen_md.py` sinh bảng §3 và đặc tả sự kiện §4.2; `check_contracts.py` kiểm hợp đồng (§7) | 70 ví dụ yêu cầu, 70 ví dụ phản hồi, 14 ví dụ sự kiện |

: Tệp hợp đồng và công cụ sinh

Hai tệp YAML do script sinh ra, không sửa tay. Mọi tên miền, máy chủ, định danh và dữ liệu trong hợp đồng là giả lập. Tenant ví dụ là `T68` (giả lập), topic dùng chữ thường `t68`.

Bản 0.2 giữ nguyên mọi quy ước, mã và bảng của bản 0.1, và thêm: chương Giới thiệu kèm sơ đồ kiến trúc và sơ đồ trình tự (chương 0), đặc tả từng sự kiện (§4.2), câu hiển thị cho từng mã lỗi (§6), đặc tả từng endpoint sinh từ OpenAPI kèm ví dụ yêu cầu và phản hồi (chương 10), các đề nghị đồng bộ với tập khác (chương 11).

Căn cứ: FRS [D02-03-PH04](../../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md) §8, SDD [D03-02-PH04](../sdd/D03-02-PH04-sdd-tich-hop.md) §3, §10, §12, CSDL [D03-03-PH04](../csdl/D03-03-PH04-csdl-tich-hop.md), màn hình [D03-06-PH04](../uiux/D03-06-PH04-man-hinh-tich-hop.md) §2.4, §5.3.

## 0. Giới thiệu

Chương này cho biết tài liệu dùng để làm gì, ai đọc phần nào, các thuật ngữ cần biết và vị trí của giao diện lập trình PH-04 trong kiến trúc. Hai sơ đồ ở cuối chương (kiến trúc thành phần, trình tự luồng chính) là khung để đọc các chương đặc tả phía sau.

### 0.1. Mục đích

Tài liệu đặc tả toàn bộ giao diện lập trình của PH-04 Lõi tích hợp và trình thiết kế luồng: API điều khiển REST của module `flow` trong `dh-integration`, các sự kiện Kafka trao đổi với phân hệ khác và với runtime, hợp đồng gọi sang phân hệ khác, bảng mã lỗi ERR-04. Lập trình viên dùng tài liệu để hiện thực máy chủ và client sinh mã; kiểm thử viên dùng để viết ca kiểm thử hợp đồng; hội đồng thẩm định dùng để đánh giá tính an toàn, nhất quán và khả năng thay thế Bus cũ.

### 0.2. Phạm vi

Trong phạm vi: 70 operation dưới `/api/integration/v1` (51 mã API-04), 14 sự kiện EVT-04-01…14, mã lỗi ERR-04-001…049 (control plane) và ERR-04-101…112 (runtime trả bên gọi luồng), hợp đồng gọi PH-01, PH-02, PH-05, PH-10, PH-13, PH-18, Git, OpenBao và sandbox.

Ngoài phạm vi: hợp đồng của từng luồng đối ngoại mà HTTT thành viên gọi (PH-02 công bố), API của PH-05 về kết nối và bí mật (D03-04-PH05), giao diện người dùng (D03-06-PH04), lược đồ CSDL (D03-03-PH04). Hai API nội bộ giữa sandbox và `dh-integration` mà SDD §8.2 nêu chưa có mã; xem §5 và chương 11.

### 0.3. Người đọc

| Người đọc | Mục tiêu | Phần cần đọc |
|---|---|---|
| Hội đồng thẩm định | Đánh giá an toàn, nhất quán, khả năng thay Bus cũ | Tóm tắt, chương 0, 2, 6, 8 |
| Kiến trúc sư | Kiểm biên giữa control plane, runtime, phân hệ khác | Chương 0, 4, 5 |
| Lập trình viên L-INT (máy chủ) | Hiện thực controller, dịch vụ, outbox, lệnh runtime | Chương 1, 2, 3, 4, 6, 10 |
| Lập trình viên frontend console | Gọi API qua BFF, hiển thị lỗi, `allowedActions` | Chương 1, 3, 6, 10 |
| Kiểm thử viên | Viết ca kiểm thử hợp đồng, ca lỗi | Chương 6, 7, 10 |
| Vận hành | Hiểu lệnh runtime, nhịp tim, mã lỗi runtime | Chương 4, 6.2 |

: Người đọc và phần cần đọc

### 0.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01 và FRS D02-03-PH04 §1.4. Bảng dưới chỉ liệt kê những từ dùng nhiều trong tài liệu này.

| Thuật ngữ | Giải thích |
|---|---|
| Control plane | Mặt phẳng điều khiển: `dh-integration` quản lý luồng, phiên bản, duyệt, phát hành; không xử lý bản tin nghiệp vụ |
| Data plane, runtime | Mặt phẳng dữ liệu: `dh-runtime` (Camel Quarkus) chạy luồng đã phát hành |
| Sandbox | `dh-runtime-sandbox`, môi trường chạy thử định nghĩa chưa phát hành bằng Camel thật, cách ly mạng |
| Luồng (flow) | Một tài nguyên tích hợp (route, Kamelet, Pipe) có mã `flowCode`, nhiều phiên bản bất biến |
| Phiên bản (version) | Bản định nghĩa YAML có số `versionNo`, băm `contentHash`, đi qua vòng `DRAFT` → `PENDING_REVIEW` → `APPROVED` |
| BFF | Backend for Frontend: lớp máy chủ của console giữ token và gọi API thay trình duyệt |
| ETag, `If-Match` | Thẻ phiên bản của tài nguyên và tiêu đề gửi kèm khi sửa để phát hiện ghi đè (khóa lạc quan) |
| `Idempotency-Key` | Khóa chống trùng: gửi lại cùng khóa không tạo thêm tài nguyên |
| SSE | Server-Sent Events: máy chủ đẩy tiến trình qua một kết nối HTTP một chiều |
| Outbox | Bảng `ph04.outbox` ghi sự kiện trong cùng giao dịch với thay đổi; Debezium đọc và đưa lên Kafka |
| CloudEvents | Chuẩn mô tả sự kiện; dùng chế độ nhị phân, siêu dữ liệu ở tiêu đề `ce_*` |
| RFC 9457 | Chuẩn thân lỗi `application/problem+json` (ProblemDetails) |
| GitOps | Phát hành bằng cách ghi trạng thái mong muốn vào kho Git; Argo CD đồng bộ xuống cụm |
| Bốn mắt | Người duyệt phải khác người tạo, người đóng góp và người gửi (BR-04-005) |
| JCS | JSON Canonicalization Scheme (RFC 8785), dạng chuẩn hóa JSON để ký |

: Thuật ngữ và viết tắt

### 0.5. Tài liệu tham chiếu

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D02-03-PH04 | [FRS PH-04](../../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md) | FR, BR, quyền `PERM-04-*`, tham số `04.*` |
| D02-04-PH04 | [Use case PH-04](../../02-yeu-cau/use-case/D02-04-PH04-use-case-tich-hop.md) | Luồng nghiệp vụ gọi API |
| D03-02-PH04 | [SDD PH-04](../sdd/D03-02-PH04-sdd-tich-hop.md) | Thành phần, sandbox (§8), lệnh runtime (§10), lỗi (§12) |
| D03-03-PH04 | [CSDL PH-04](../csdl/D03-03-PH04-csdl-tich-hop.md) | Bảng `flow`, `flow_version`, `test_run`, `deployment`, `runtime_command`, `outbox` |
| D03-06-PH04 | [Màn hình PH-04](../uiux/D03-06-PH04-man-hinh-tich-hop.md) | `allowedActions` (§2.4), câu hiển thị lỗi (§5.3) |
| D03-04-PH05 | [API PH-05](D03-04-PH05-api-bo-dieu-hop.md) | Kiểm tra kết nối (API-05-031), catalog Kamelet |
| D04-01, D04-02 | [Quy ước mã](../../04-lap-trinh/D04-01-coding-convention.md), [quy trình kỹ thuật](../../04-lap-trinh/D04-02-quy-trinh-ky-thuat.md) | RFC 9457, cổng CI-1…CI-6 |
| RFC 9457, 9470, 8785; OpenAPI 3.1; AsyncAPI 3.0; CloudEvents 1.0 | Chuẩn ngoài | Lỗi, xác thực lại, ký lệnh, hợp đồng |

: Tài liệu tham chiếu

### 0.6. Cấu trúc tài liệu

| Chương | Nội dung |
|---|---|
| 0 | Giới thiệu, kiến trúc thành phần, sơ đồ trình tự luồng chính |
| 1, 2 | Quy ước chung; xác thực và phân quyền |
| 3 | Danh mục endpoint (sinh từ OpenAPI) và ghi chú hiện thực |
| 4 | Danh mục sự kiện và đặc tả từng sự kiện (sinh từ AsyncAPI) |
| 5 | Hợp đồng với phân hệ khác và bên ngoài |
| 6 | Bảng mã lỗi ERR-04 kèm câu hiển thị |
| 7 | Kiểm tra hợp đồng trong CI và kết quả kiểm |
| 8, 9 | Ánh xạ hệ cũ; câu hỏi mở |
| 10 | Đặc tả từng endpoint, mỗi endpoint một bảng 10 mục kèm ví dụ yêu cầu và phản hồi (sinh từ OpenAPI) |
| 11 | Đề nghị đồng bộ với tập khác |

: Cấu trúc tài liệu

### 0.7. Kiến trúc thành phần

API điều khiển chỉ có một bên gọi là console qua BFF; mọi trao đổi khác giữa control plane và runtime đi qua Kafka hoặc Git, không có lời gọi đồng bộ từ `dh-integration` vào pod runtime. Hình dưới đặt các tệp hợp đồng của tài liệu này vào đúng chỗ của chúng trong kiến trúc SDD §2.2.

```{.mermaid caption="Kiến trúc thành phần và vị trí các giao diện lập trình PH-04"}
flowchart TB
    U[Người dùng IE, IA, TA, SO] --> CON[dh-console<br/>trình thiết kế, UI-04]
    CON -->|OIDC + PKCE| BFF[BFF console]
    BFF -->|REST, SSE /api/integration/v1<br/>API-04-001…091| APX[apisix-int]
    APX --> CTL[dh-integration · module flow]
    CTL --> PG[(pg-core · ph04<br/>outbox)]
    CTL -->|Valkey Stream<br/>dh:int:testrun:queue| SB[dh-runtime-sandbox]
    SB -->|/internal/v1/testruns/…<br/>bundle, steps| CTL
    CTL -->|commit env/*| GIT[(dh-flows-tenant)]
    GIT --> ARGO[Argo CD] --> RT[dh-runtime]
    PG -->|Debezium<br/>EVT-04-01…10| K[(Kafka)]
    CTL -->|EVT-04-11 lệnh có ký| K
    K --> RT
    RT -->|EVT-04-12 nhịp tim<br/>EVT-04-13 xác nhận| K
    K --> CTL
    RT -->|EVT-04-14 nhật ký kết nối| K
    K --> PHX[PH-02, PH-10, PH-13, PH-18]
    CTL -->|REST nội bộ, mTLS| DEP[PH-05, PH-02, PH-10, PH-13, OpenBao]
    HTTT[HTTT thành viên] -->|gọi luồng, ERR-04-101…112| APE[APISIX biên] --> RT
```

Người đọc cần thấy ba đường tách biệt. Đường điều khiển (trái trên) là REST từ console qua BFF và `apisix-int`, được đặc tả ở chương 3 và 10. Đường phát hành và vận hành đi qua Git (trạng thái mong muốn) và Kafka (sự kiện, lệnh, nhịp tim), được đặc tả ở chương 4. Đường dữ liệu nghiệp vụ (dưới) là HTTT thành viên gọi thẳng luồng qua APISIX biên, không chạm API điều khiển; lỗi trên đường này dùng dải ERR-04-101…112 (§6.2). Hai API nội bộ của sandbox (`bundle`, `steps`) nằm trong cụm, không qua APISIX và chưa có mã API (chương 11).

### 0.8. Trình tự luồng chính

Luồng chính của PH-04 là đưa một phiên bản luồng từ bản nháp tới chạy thật ở một môi trường. Sơ đồ ghi đúng mã API và mã sự kiện ở mỗi bước để lập trình viên và kiểm thử viên lần theo.

```{.mermaid caption="Trình tự soạn, chạy thử, duyệt bốn mắt và phát hành một phiên bản luồng"}
sequenceDiagram
    autonumber
    actor IE as Người thiết kế (IE)
    actor IA as Người duyệt (IA)
    participant C as Console + BFF
    participant I as dh-integration
    participant S as Sandbox
    participant G as Git + Argo CD
    participant R as dh-runtime
    participant K as Kafka
    IE->>C: Sửa sơ đồ
    C->>I: PUT …/versions/3/draft (API-04-022, If-Match)
    I-->>C: 200 DraftSaved, kiểm tra mức DESIGN
    IE->>C: Bấm "Chạy thử"
    C->>I: POST …/versions/3/test-runs (API-04-040)
    I->>S: Đưa việc vào hàng đợi
    S-->>I: Kết quả từng chặng
    I-->>C: SSE step, completed (API-04-042)
    C->>I: POST …/versions/3:submit (API-04-050)
    I->>K: EVT-04-03 qua outbox
    IA->>C: Xem khác biệt (API-04-025) rồi duyệt
    C->>I: POST …/versions/3:review (API-04-052)
    I->>I: Kiểm bốn mắt BR-04-005, xác thực lại
    I->>K: EVT-04-04
    C->>I: POST …/deployments (API-04-054)
    I->>G: Commit env/test
    I->>K: EVT-04-06
    G->>R: Đồng bộ định nghĩa
    R->>K: EVT-04-12 nhịp tim có contentHash
    K->>I: So băm, triển khai SYNCED
    I->>K: EVT-04-07 status-changed
```

Sơ đồ cho thấy bốn cổng kiểm soát nằm ở máy chủ, không ở giao diện: kiểm tra hợp lệ mỗi lần lưu (bước 2–3), điều kiện có lần chạy thử đạt trên đúng `contentHash` khi gửi duyệt (bước 9, ERR-04-014), bốn mắt và xác thực lại khi duyệt (bước 12–13, ERR-04-015), và trạng thái `SYNCED` chỉ đặt khi runtime báo đúng băm qua nhịp tim (bước 19–20). Mọi bước có tác dụng ngoài đều trả 202 và có SSE hoặc tài nguyên theo dõi.

```{.mermaid caption="Trình tự lệnh tạm dừng hoặc dừng khẩn và xác nhận theo bản sao"}
sequenceDiagram
    autonumber
    actor TO as Người vận hành (TO, SO)
    participant I as dh-integration
    participant B as OpenBao transit
    participant K as Kafka
    participant R as dh-runtime (mỗi bản sao)
    TO->>I: POST …/runtime/commands (API-04-061, lý do)
    I->>I: Ghi runtime_command ISSUED
    I->>B: Ký Ed25519 trên JCS
    I->>K: EVT-04-11 (hạn 60 giây)
    I-->>TO: 202 Command, Location
    K->>R: Lệnh
    R->>R: Kiểm chữ ký, hạn, tenant, luồng, trùng
    R->>K: EVT-04-13 APPLIED hoặc REJECTED
    K->>I: Đếm xác nhận
    TO->>I: GET …/commands/{id}
    I-->>TO: ACKNOWLEDGED, hoặc PARTIAL sau 30 giây
    I->>K: EVT-04-08 khi đủ xác nhận
```

Lệnh runtime không đi qua Git và không qua outbox để giữ độ trễ dưới 5 giây (NFR-04-010); trạng thái mong muốn được tiến trình đối soát đưa vào Git trong 5 phút (ADR-065). Khi một bản sao từ chối, lý do nằm ở `acks[].reason` (ERR-04-024), không phải mã HTTP; người vận hành gửi lại bằng `:resend`.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi endpoint của PH-04, kế thừa SAD §7.2 và mẫu D03-04-PH07 §1. Mỗi quy ước có chỗ thể hiện trong hợp đồng để lập trình viên tra.

| Chủ đề | Quy ước | Trong hợp đồng |
|---|---|---|
| Đường dẫn gốc | `/api/integration/v1` (GAP-04-13). Không có API nền tảng riêng; chính sách thành phần nền đi cùng API, phân biệt bằng quyền | `servers` |
| Người gọi | Chỉ console qua BFF (token Authorization Code + PKCE). APISIX nội bộ `apisix-int` chặn client máy gọi tới đường dẫn này | `security` |
| Phiên bản API | Số chính trong đường dẫn. Trong `v1` chỉ thêm trường tùy chọn và endpoint mới; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng | `info.version` |
| Tenant | Lấy từ token, không lấy từ tham số. Đối tượng của tenant khác, hoặc của không gian làm việc người gọi không có quyền xem, trả 404 như không tồn tại | Mô tả từng endpoint |
| Định danh trong đường dẫn | Dùng mã nghiệp vụ `flowCode` và số `versionNo`, không dùng UUID, để URL đọc được và khớp kho Git `flows/{flowCode}/`. Tài nguyên con (lần chạy, triển khai, lệnh) dùng UUID v7 | `FlowCodePath`, `VersionNoPath` |
| Đặt tên | Danh từ số nhiều, chữ thường, gạch nối. Hành động đổi trạng thái dùng hậu tố `:{hành-động}` (`:submit`, `:review`, `:retire`, `:rollback`) | `paths` |
| Phân trang | Con trỏ mờ `cursor`, `limit` ≤ 100 (vượt trả ERR-04-026), trả `page.next`, `page.hasMore`. Danh sách nhỏ có giới hạn tự nhiên (phiên bản, triển khai, ca kiểm thử) trả trọn | `CursorMeta` |
| Chống trùng | `Idempotency-Key` 16…128 ký tự trên mọi lệnh tạo và lệnh có tác dụng ngoài (chạy thử, phát hành, lệnh runtime). Lưu 24 giờ ở Valkey, so băm SHA-256 thân yêu cầu; khác nội dung trả ERR-04-018 | `IdempotencyKey`, `x-datahub-idempotent` |
| Khóa lạc quan | `ETag` dạng `W/"{version}-{contentHash[0..8]}"` (SDD §6.4). Lệnh sửa và đổi trạng thái bắt buộc `If-Match`; thiếu trả ERR-04-007 (428), lệch trả ERR-04-006 (412) kèm `currentEtag`, `savedBy`, `savedAt` để giao diện mở hộp xung đột ba bên | `IfMatch`, `ETag` |
| Hành động được phép | Luồng, phiên bản, triển khai, lần chạy thử trả `allowedActions` và `disabledReasons` (D03-06-PH04 §2.4). Giao diện không tự suy luận quyền và trạng thái | `AllowedActions` |
| Xử lý nền | Thao tác có tác dụng ngoài chưa xong ngay (chạy thử, phát hành, quay lui, nâng môi trường, gỡ luồng, lệnh runtime, chuyển XML cũ) trả `202 Accepted` kèm `Location` | `Location` |
| Tiến trình thời gian thực | SSE (`text/event-stream`) cho một lần chạy thử và một lần triển khai, có nhịp `heartbeat` 15 giây. Mất kết nối thì hỏi lại mỗi 2 giây. Không dùng WebSocket | `streamTestRun`, `streamDeployment` |
| Lỗi | RFC 9457 `application/problem+json`, có `code` (ERR-04-nnn), `traceId`, `errors[]` theo trường, `findings[]` theo quy tắc kiểm tra. `title`, `detail` tiếng Việt và không bao giờ lặp giá trị bí mật | `ProblemDetails`, `Finding` |
| Truy vết | `traceparent` (W3C Trace Context) truyền xuyên suốt tới Git commit message, outbox và lệnh runtime | `Traceparent` |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` | `AcceptLanguage` |
| Kích thước | Định nghĩa luồng ≤ 512 KiB (ERR-04-033); bản tin mẫu, thân chạy thử ≤ 256 KiB (ERR-04-021); tài liệu mẫu cho trình ánh xạ ≤ 1 MiB; tệp XML cũ ≤ 2 MiB | `maxLength` |
| Kiểu dữ liệu | Theo D00-01 §5: UUID v7, thời điểm ISO 8601 có múi giờ, mã tenant `^T[0-9]{2}$`, băm `sha256:{64 hex}` | `TenantId`, `ContentHash` |

: Quy ước chung của API điều khiển PH-04

## 2. Xác thực và phân quyền

Người dùng đăng nhập bằng Authorization Code + PKCE tại realm Keycloak `dh-{tenant}` (ví dụ `dh-t68`). BFF của console giữ token và gọi `dh-integration` qua `apisix-int`. APISIX kiểm tra chữ ký, hạn và giới hạn tần suất. `dh-integration` kiểm tra lại tenant, quyền `PERM-04-*` và mức truy cập không gian làm việc. Lớp kiểm tra thứ hai này giữ an toàn kể cả khi cấu hình gateway sai.

Quyền chức năng theo FRS §3.2 và D02-08:

| Quyền | Dùng cho | Vai trò mặc định |
|---|---|---|
| `PERM-04-read` | Mọi API đọc; tạo đề xuất thành phần | PA, PO, TA, TO, SO, IE, IA, VW, AU |
| `PERM-04-create` | Tạo, nhân bản luồng; chuyển XML cũ; kiểm tra YAML chưa lưu | IE |
| `PERM-04-update` | Lưu nháp, nhập YAML, biểu thức, ánh xạ, chạy thử, ca kiểm thử, phiên soạn | IE |
| `PERM-04-submit` | Gửi duyệt, rút lại | IE |
| `PERM-04-publish` | Duyệt, yêu cầu sửa, phát hành, quay lui, hàng đợi duyệt | IA |
| `PERM-04-promote` | Nâng phiên bản lên môi trường kế tiếp | IA, TA |
| `PERM-04-operate` | Tạm dừng, tiếp tục luồng và route; gửi lại lệnh | TA, TO, SO, IA |
| `PERM-04-emergency-stop` | Lệnh `EMERGENCY_STOP` | SO, TA |
| `PERM-04-delete` | Gỡ luồng | IE (bản nháp của mình), TA; luồng đã phát hành cần thêm `PERM-04-publish` |
| `PERM-04-admin` | Không gian làm việc, thành viên, khuôn của tỉnh, biến môi trường, thu hẹp chính sách thành phần cho tỉnh | TA, PA |
| `PERM-04-catalog-admin` | Chính sách thành phần nền, quyết định đề xuất | PA (SO duyệt) |
| `PERM-04-sample-data` | Bỏ qua cảnh báo dữ liệu cá nhân thật trong bản tin mẫu (cờ trong thân yêu cầu, không phải endpoint riêng) | IE được TA cấp theo luồng |

: Quyền chức năng PERM-04 và vai trò mặc định

Mức không gian làm việc (`VIEW`, `EDIT`, `MAINTAIN`, FR-04-007) ghi ở `x-datahub-permission.workspaceLevel`. Chỉ áp dụng khi tham số `04.workspace.enforce` bật; TA và PA không bị giới hạn. Người duyệt cần mức `MAINTAIN` khi tham số bật.

Hai kiểm tra đặc biệt:

- **Bốn mắt (BR-04-005).** `:review` từ chối người đã tạo phiên bản, người trong `flow_version_contributor` và người gửi duyệt (ERR-04-015, 403). Kiểm tra ở máy chủ, giao diện chỉ ẩn nút.
- **Xác thực lại khi duyệt.** Khi `04.review.require-reauth` bật thì `:review` cần token có `auth_time` trong 5 phút; phát hành và nâng lên PROD luôn cần, bất kể tham số (FRS §7.1). Nếu không, máy chủ trả 401 kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", max_age=300` (RFC 9470), giao diện mở cửa sổ đăng nhập lại.

## 3. Danh mục endpoint

Chương này liệt kê mọi operation theo nhóm chức năng để người đọc tra nhanh mã, đường dẫn, FR và quyền; đặc tả đầy đủ từng operation, kèm ví dụ yêu cầu và phản hồi, ở chương 10. Bảng dưới đây sinh từ `ph04/tools/gen_openapi.py` (cùng nguồn với hợp đồng) bằng `gen_md.py`. Cột "FR" ghi số FR-04 được hiện thực, bỏ tiền tố. Mọi operation đều có thể trả 401 (ERR-04-044); mọi lệnh ghi có thể trả 403 (ERR-04-045). Hai mã này không nhắc lại trong bảng.

<!-- gen:endpoints:start -->
**Không gian làm việc**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-001 | `GET /workspaces` | Danh sách không gian làm việc | 007 | `PERM-04-read` |  | 200 |
| API-04-002 | `POST /workspaces` | Tạo không gian làm việc | 007 | `PERM-04-admin` | có | 201 |
| API-04-002 | `PATCH /workspaces/{workspaceCode}` | Sửa không gian làm việc | 007 | `PERM-04-admin` (MAINTAIN) |  | 200 |
| API-04-003 | `POST /workspaces/{workspaceCode}:archive` | Lưu trữ không gian làm việc | 007 | `PERM-04-admin` |  | 200 |
| API-04-004 | `GET /workspaces/{workspaceCode}/members` | Danh sách thành viên | 007 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-004 | `PUT /workspaces/{workspaceCode}/members` | Thay danh sách thành viên | 007 | `PERM-04-admin` (MAINTAIN) |  | 200 |

: Endpoint nhóm Không gian làm việc

**Luồng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-010 | `GET /flows` | Danh sách luồng | 001 | `PERM-04-read` |  | 200 |
| API-04-011 | `POST /flows` | Tạo luồng và phiên bản 1 | 003, 025 | `PERM-04-create` (EDIT) | có | 201 |
| API-04-012 | `GET /flows/{flowCode}` | Chi tiết luồng | 002 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-013 | `PATCH /flows/{flowCode}` | Sửa thông tin luồng | 004 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-014 | `POST /flows/{flowCode}:clone` | Nhân bản luồng | 005 | `PERM-04-create` (EDIT) | có | 201 |
| API-04-015 | `POST /flows/{flowCode}:retire` | Gỡ luồng | 006 | `PERM-04-delete` |  | 202 |
| API-04-016 | `GET /flows/{flowCode}/dependencies` | Phụ thuộc của luồng | 006, 002 | `PERM-04-read` (VIEW) |  | 200 |

: Endpoint nhóm Luồng

**Phiên bản**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-024 | `GET /flows/{flowCode}/versions` | Danh sách phiên bản | 011 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-021 | `POST /flows/{flowCode}/versions` | Tạo phiên bản mới từ phiên bản có sẵn | 011 | `PERM-04-update` (EDIT) | có | 201 |
| API-04-020 | `GET /flows/{flowCode}/versions/{versionNo}` | Lấy phiên bản (định nghĩa, bố cục, bản tin mẫu) | 010 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-022 | `PUT /flows/{flowCode}/versions/{versionNo}/draft` | Lưu nháp | 024, 010, 022 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-023 | `POST /flows/{flowCode}/versions/{versionNo}:discard` | Hủy bản nháp | 006 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-025 | `GET /flows/{flowCode}/versions/{versionNo}/diff` | So sánh với phiên bản khác | 043 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-026 | `GET /flows/{flowCode}/versions/{versionNo}/download` | Tải định nghĩa | 027 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-027 | `POST /flows/{flowCode}/versions/{versionNo}:import-yaml` | Nhập YAML thay định nghĩa | 027 | `PERM-04-update` (EDIT) |  | 200 |

: Endpoint nhóm Phiên bản

**Di trú**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-028 | `POST /legacy-imports` | Chuyển Camel XML của Bus cũ | 082 | `PERM-04-create` (EDIT) | có | 202 |
| API-04-028 | `GET /legacy-imports/{jobId}` | Kết quả chuyển đổi | 082 | `PERM-04-read` |  | 200 |

: Endpoint nhóm Di trú

**Phiên bản**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-034 | `PUT /flows/{flowCode}/versions/{versionNo}/session` | Nhịp phiên soạn | 024 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-034 | `DELETE /flows/{flowCode}/versions/{versionNo}/session` | Kết thúc phiên soạn | 024 | `PERM-04-update` |  | 204 |

: Endpoint nhóm Phiên bản

**Kiểm tra hợp lệ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-030 | `POST /flows/{flowCode}/versions/{versionNo}:validate` | Kiểm tra hợp lệ phiên bản | 023 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-031 | `POST /validation:check` | Kiểm tra YAML chưa lưu | 023, 003 | `PERM-04-create` |  | 200 |
| API-04-032 | `POST /expressions:check` | Biên dịch, xem trước biểu thức | 015 | `PERM-04-update` |  | 200 |
| API-04-033 | `POST /mappings:preview` | Xem trước ánh xạ (JQ) trên bản tin mẫu | 020 | `PERM-04-update` |  | 200 |

: Endpoint nhóm Kiểm tra hợp lệ

**Chạy thử**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-040 | `POST /flows/{flowCode}/versions/{versionNo}/test-runs` | Bắt đầu chạy thử | 030, 032 | `PERM-04-update` (EDIT) | có | 202 |
| API-04-041 | `GET /flows/{flowCode}/test-runs` | Lịch sử chạy thử | 030 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-042 | `GET /flows/{flowCode}/test-runs/{runId}` | Kết quả lần chạy thử | 030 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-042 | `GET /flows/{flowCode}/test-runs/{runId}/events` | Luồng sự kiện lần chạy thử (SSE) | 030 | `PERM-04-read` (VIEW) |  | 200 SSE |
| API-04-042 | `GET /flows/{flowCode}/test-runs/{runId}/steps/{seqNo}/body` | Thân bản tin đầy đủ của một chặng | 030 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-043 | `POST /flows/{flowCode}/test-runs/{runId}:cancel` | Hủy lần chạy thử | 030 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-044 | `GET /flows/{flowCode}/test-cases` | Danh sách ca kiểm thử | 031 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-044 | `POST /flows/{flowCode}/test-cases` | Tạo ca kiểm thử | 031 | `PERM-04-update` (EDIT) | có | 201 |
| API-04-044 | `PUT /flows/{flowCode}/test-cases/{caseId}` | Sửa ca kiểm thử | 031 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-044 | `DELETE /flows/{flowCode}/test-cases/{caseId}` | Xóa (ngừng dùng) ca kiểm thử | 031 | `PERM-04-update` (EDIT) |  | 204 |

: Endpoint nhóm Chạy thử

**Duyệt**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-050 | `POST /flows/{flowCode}/versions/{versionNo}:submit` | Gửi duyệt | 040 | `PERM-04-submit` (EDIT) |  | 200 |
| API-04-051 | `POST /flows/{flowCode}/versions/{versionNo}:withdraw` | Rút lại yêu cầu duyệt | 040 | `PERM-04-submit` (EDIT) |  | 200 |
| API-04-052 | `POST /flows/{flowCode}/versions/{versionNo}:review` | Quyết định duyệt | 041, 043 | `PERM-04-publish` (VIEW) |  | 200 |
| API-04-053 | `GET /reviews` | Hàng đợi duyệt | 041 | `PERM-04-publish` |  | 200 |

: Endpoint nhóm Duyệt

**Triển khai**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-054 | `GET /flows/{flowCode}/deployments` | Lịch sử triển khai | 042 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-054 | `POST /flows/{flowCode}/deployments` | Phát hành phiên bản lên môi trường | 042, 075 | `PERM-04-publish` (VIEW) | có | 202 |
| API-04-054 | `GET /flows/{flowCode}/deployments/{deploymentId}` | Chi tiết triển khai | 042 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-054 | `GET /flows/{flowCode}/deployments/{deploymentId}/events` | Tiến trình triển khai (SSE) | 042 | `PERM-04-read` (VIEW) |  | 200 SSE |
| API-04-055 | `POST /flows/{flowCode}/deployments:rollback` | Quay lui về phiên bản đã duyệt trước | 044 | `PERM-04-publish` | có | 202 |
| API-04-056 | `POST /flows/{flowCode}/deployments:promote` | Nâng phiên bản lên môi trường kế tiếp | 045 | `PERM-04-promote` | có | 202 |

: Endpoint nhóm Triển khai

**Vận hành**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-060 | `GET /flows/{flowCode}/runtime` | Tình trạng runtime theo môi trường | 051 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-061 | `POST /flows/{flowCode}/runtime/commands` | Tạm dừng, tiếp tục, dừng khẩn | 050 | `PERM-04-operate` | có | 202 |
| API-04-061 | `GET /flows/{flowCode}/runtime/commands/{commandId}` | Trạng thái lệnh | 050 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-061 | `POST /flows/{flowCode}/runtime/commands/{commandId}:resend` | Gửi lại lệnh chưa đủ xác nhận | 050 | `PERM-04-operate` |  | 202 |
| API-04-062 | `GET /flows/{flowCode}/endpoints` | Điểm kết nối và số liệu | 052 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-063 | `GET /flows/{flowCode}/metrics` | Số liệu theo luồng (từ PH-13) | 053 | `PERM-04-read` (VIEW) |  | 200 |

: Endpoint nhóm Vận hành

**Danh mục thành phần**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-070 | `GET /catalog` | Chỉ mục catalog đã lọc chính sách | 012, 080 | `PERM-04-read` |  | 200 |
| API-04-071 | `GET /catalog/{kind}/{name}` | Lược đồ thuộc tính của thành phần | 014, 080 | `PERM-04-read` |  | 200 |
| API-04-072 | `GET /catalog/policies` | Chính sách thành phần (nền + tỉnh) | 080 | `PERM-04-read` |  | 200 |
| API-04-072 | `PATCH /catalog/policies` | Sửa chính sách thành phần | 080 | `PERM-04-catalog-admin` |  | 200 |
| API-04-073 | `GET /catalog/versions` | Phiên bản catalog và hồ sơ runtime | 081, 075 | `PERM-04-read` |  | 200 |
| API-04-074 | `GET /catalog/proposals` | Đề xuất thành phần | 080 | `PERM-04-read` |  | 200 |
| API-04-074 | `POST /catalog/proposals` | Đề xuất cho phép hoặc bổ sung thành phần | 080 | `PERM-04-read` | có | 201 |
| API-04-074 | `POST /catalog/proposals/{proposalId}:decide` | Quyết định đề xuất | 080 | `PERM-04-catalog-admin` |  | 200 |

: Endpoint nhóm Danh mục thành phần

**Khuôn mẫu**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-080 | `GET /templates` | Danh sách khuôn mẫu | 025 | `PERM-04-read` |  | 200 |
| API-04-081 | `GET /templates/{templateCode}` | Chi tiết khuôn và lược đồ tham số | 025 | `PERM-04-read` |  | 200 |
| API-04-082 | `POST /templates` | Tạo khuôn của tỉnh từ phiên bản đã duyệt | 025 | `PERM-04-admin` | có | 201 |
| API-04-082 | `POST /templates/{templateCode}:deprecate` | Ngừng dùng khuôn của tỉnh | 025 | `PERM-04-admin` |  | 200 |

: Endpoint nhóm Khuôn mẫu

**Tham số**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-090 | `GET /settings` | Tham số 04.*, khoảng đóng băng, biến môi trường | 084 | `PERM-04-read` |  | 200 |
| API-04-090 | `PUT /settings/env-vars` | Thay biến môi trường {{dh.env.*}} | 084 | `PERM-04-admin` |  | 200 |
| API-04-091 | `GET /flows/{flowCode}/history` | Lịch sử thao tác của luồng (từ PH-13) | 083 | `PERM-04-read` (VIEW) |  | 200 |

: Endpoint nhóm Tham số
<!-- gen:endpoints:end -->

Ghi chú cho lập trình viên:

1. **Lưu nháp (API-04-022)** là endpoint gọi nhiều nhất. Giao diện tự lưu sau 2 giây ngừng gõ (D03-06-PH04 §10.16). Máy chủ ghi `definitionYaml`, `canvasLayout`, `samples`, `mappings` trong một giao dịch, tính lại `contentHash` trên YAML chuẩn hóa (SDD §6.2), dựng lại chỉ mục route và endpoint, chạy kiểm tra mức `DESIGN`. Kết quả kiểm tra trả kèm và không chặn lưu, trừ hai trường hợp: cú pháp YAML (ERR-04-008) và giá trị giống bí mật (ERR-04-010). Bí mật không bao giờ được ghi xuống, kể cả ở bản nháp.
2. **Bản tin mẫu và bố cục** (`samples`, `canvasLayout`) lưu cột riêng và không vào YAML triển khai (BR-04-007). `contentHash` chỉ tính trên YAML, nên kéo chặng trên canvas không làm mất kết quả chạy thử đạt.
3. **Gửi duyệt (API-04-050)** kiểm tra theo thứ tự rẻ đến đắt và trả lỗi đầu tiên gặp:
   - trạng thái (ERR-04-005);
   - ghi chú thay đổi (ERR-04-025);
   - catalog hiện hành (ERR-04-042);
   - kiểm tra mức `SUBMIT` (ERR-04-009, kèm `findings`);
   - lần chạy thử không mô phỏng đạt trên đúng `contentHash` và mọi ca kiểm thử đang dùng đều đạt (ERR-04-014, BR-04-004).
4. **Phát hành (API-04-054)** ghi bản ghi `deployment` và outbox trong giao dịch, rồi `GitOpsWriter` commit vào `env/{environment}` của kho `dh-flows-{tenant}` (với PROD là merge request, ADR-068). Lỗi Git đưa triển khai sang `FAILED` với ERR-04-022, không cuộn lại phiên bản. Trạng thái `SYNCED` đến khi mọi bản sao báo đúng `contentHash` qua nhịp tim EVT-04-12.
5. **Lệnh runtime (API-04-061)** trả 202 ngay khi đã ký và gửi. Giao diện theo dõi `GET .../commands/{id}`: `ACKNOWLEDGED` khi đủ bản sao, `PARTIAL` sau 30 giây, `REJECTED` khi có bản sao từ chối (ERR-04-024 nằm trong `acks[].reason`, không phải mã HTTP). `EMERGENCY_STOP` đi trước Git; tiến trình đối soát đưa trạng thái mong muốn vào Git trong 5 phút (ADR-065, BR-04-018).
6. **Catalog (API-04-070)** trả chỉ mục đã lọc theo chính sách nền và chính sách tỉnh, kèm nhóm bảng thành phần. ETag ghép `catalogVersion`, `policyVersion`, `paletteRulesVersion`; trình duyệt giữ bản đệm và gửi `If-None-Match`.
7. **Đọc lịch sử, số liệu** (API-04-063, 091) chỉ là lớp chuyển tiếp tới PH-13, lọc sẵn theo tenant và luồng. PH-13 không sẵn sàng thì trả 503 ERR-04-047; các màn hình khác vẫn dùng được.

## 4. Danh mục sự kiện

PH-04 dùng sự kiện để báo mốc vòng đời luồng cho phân hệ khác và để điều khiển runtime mà không gọi đồng bộ vào pod. Mục 4.1 nêu quy tắc chung và danh mục; mục 4.2 đặc tả từng sự kiện bằng khối đặc tả sinh từ AsyncAPI, kèm ví dụ payload đã kiểm khớp lược đồ.

### 4.1. Quy tắc chung và danh mục

Hợp đồng ở `ph04/asyncapi-integration.yaml`. Có ba nhóm sự kiện:

- **EVT-04-01…10** ghi vào `ph04.outbox` trong cùng giao dịch với thay đổi, Debezium đưa lên Kafka. Theo CloudEvents 1.0 chế độ nhị phân (tiêu đề `ce_*`). Khóa bản tin `{tenant}:{flowId}` giữ thứ tự theo luồng.
- **EVT-04-11…13** là topic hệ thống `dh.*`. ACL chỉ cho `dh-integration` và `dh-runtime` (theo CN chứng thư mTLS). EVT-04-11 không qua outbox: `dh-integration` ghi `runtime_command` rồi gửi trực tiếp, vì độ trễ lệnh khẩn phải dưới 5 giây (NFR-04-010).
- **EVT-04-14** do chặng `audit` của runtime phát. Chủ quản topic là PH-13.

Sự kiện không mang định nghĩa luồng, bản tin mẫu hay thân bản tin nghiệp vụ.

| Mã | Topic | Bên phát → bên nhận chính | Khóa | Giữ |
|---|---|---|---|---|
| EVT-04-01 | `{tenant}.integration.flow.created.v1` | dh-integration → PH-13, PH-18 | `{tenant}:{flowId}` | 7 ngày |
| EVT-04-02 | `{tenant}.integration.flow.updated.v1` | dh-integration → PH-02 (đồng bộ nhãn, chủ quản) | 〃 | 7 ngày |
| EVT-04-03 | `{tenant}.integration.version.submitted.v1` | dh-integration → PH-18 (thông báo người duyệt) | 〃 | 7 ngày |
| EVT-04-04 | `{tenant}.integration.version.approved.v1` | dh-integration → PH-18, PH-02 | 〃 | 7 ngày |
| EVT-04-05 | `{tenant}.integration.version.changes-requested.v1` | dh-integration → PH-18 (thông báo người soạn) | 〃 | 7 ngày |
| EVT-04-06 | `{tenant}.integration.deployment.requested.v1` | dh-integration → PH-13 | 〃 | 7 ngày |
| EVT-04-07 | `{tenant}.integration.deployment.status-changed.v1` | dh-integration → PH-02 (bật, tắt API công bố), PH-13, PH-18 | 〃 | 7 ngày |
| EVT-04-08 | `{tenant}.integration.flow.runtime-state-changed.v1` | dh-integration → PH-02, PH-13 | 〃 | 7 ngày |
| EVT-04-09 | `{tenant}.integration.flow.retired.v1` | dh-integration → PH-02, PH-10 (thu hồi nhóm tiêu thụ) | 〃 | 7 ngày |
| EVT-04-10 | `{tenant}.integration.testrun.completed.v1` | dh-integration → PH-18 (thông báo người chạy khi rời trang) | 〃 | 7 ngày |
| EVT-04-11 | `dh.integration.runtime.command.v1` | dh-integration → dh-runtime | `{tenant}:{environment}` | 1 ngày |
| EVT-04-12 | `dh.integration.runtime.heartbeat.v1` | dh-runtime → dh-integration | `{replica}` | 1 ngày |
| EVT-04-13 | `dh.integration.runtime.command-ack.v1` | dh-runtime → dh-integration | `{commandId}` | 1 ngày |
| EVT-04-14 | `{tenant}.audit.connection-log.v1` | dh-runtime → PH-13 | `{tenant}:{flowCode}` | 30 ngày trên Kafka; PH-13 giữ online 12 tháng, WORM 5 năm |

: Danh mục sự kiện EVT-04

Lệnh EVT-04-11 có chữ ký Ed25519 qua OpenBao transit, ký trên JCS (RFC 8785) của mọi trường trừ `signature`. Runtime từ chối lệnh trong năm trường hợp: chữ ký sai, quá `expiresAt` (60 giây), `tenantId` khác tenant của namespace, luồng hoặc route không có, `commandId` đã xử lý. Mỗi lần từ chối có xác nhận `REJECTED` với lý do tương ứng (SDD §10).

Tham số PH-04 đổi (FR-04-084) dùng sự kiện tham số chung của PH-18, không tạo EVT-04-15 (SDD §5.6).

Chính sách tương thích giống PH-07: trong `v1` chỉ thêm trường tùy chọn; lược đồ đăng ký ở Apicurio, chế độ BACKWARD; CI chặn thay đổi không tương thích.

### 4.2. Đặc tả từng sự kiện

Mục này sinh bằng `ph04/tools/gen_md.py` từ `gen_asyncapi.py` (cùng nguồn với `asyncapi-integration.yaml`); sửa nguồn rồi chạy lại, không sửa tay. Mỗi sự kiện một khối đặc tả: mục đích, kênh, khóa phân vùng, lược đồ, tiêu đề, phân vùng và thời gian giữ, bên phát, bên nhận, FR, ví dụ payload. Lược đồ nằm trong `asyncapi-integration.yaml`; `{tenant}` trong topic là mã tenant chữ thường (ví dụ `t68`). Ví dụ là dữ liệu giả lập của T68; thời điểm trong sự kiện theo UTC.

<!-- gen:dac-ta-evt:start -->
#### EVT-04-01 · Tạo luồng

::: dac-ta
**Mục đích.** Tạo luồng (FR-04-003, FR-04-005).

**Kênh, topic.** `{tenant}.integration.flow.created.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `FlowCreated`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `name`, `resourceKind`; tổng 10 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.flowCreated.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-13 (ghi kiểm toán, mở bảng theo dõi luồng); PH-18 (thông báo chủ quản không gian).

**FR.** FR-04-003, FR-04-005.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "name": "Tra cứu hộ tịch qua NDXP", "resourceKind": "ROUTE",
 "origin": "TEMPLATE", "transport": "SYNC",
 "exposure": "EXTERNAL",
 "actor": {"userId": "an.nv", "type": "USER"}}
```
:::

#### EVT-04-02 · Sửa thông tin luồng

::: dac-ta
**Mục đích.** Sửa thông tin luồng (FR-04-004).

**Kênh, topic.** `{tenant}.integration.flow.updated.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `FlowUpdated`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `changedFields`; tổng 6 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.flowUpdated.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-02 (đồng bộ nhãn, chủ quản của API công bố).

**FR.** FR-04-004.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "changedFields": ["labels", "targetSystems"],
 "actor": {"userId": "an.nv", "type": "USER"}}
```
:::

#### EVT-04-03 · Gửi duyệt

::: dac-ta
**Mục đích.** Gửi duyệt (FR-04-040).

**Kênh, topic.** `{tenant}.integration.version.submitted.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `VersionEvent`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `versionNo`, `contentHash`, `status`; tổng 12 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.versionSubmitted.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-18 (thông báo người duyệt được gợi ý và hàng đợi duyệt).

**FR.** FR-04-040.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "versionNo": 3,
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "status": "PENDING_REVIEW",
 "changeNote": "Thêm chặng che số định danh.",
 "actor": {"userId": "an.nv", "type": "USER"}}
```
:::

#### EVT-04-04 · Duyệt

::: dac-ta
**Mục đích.** Duyệt (FR-04-041).

**Kênh, topic.** `{tenant}.integration.version.approved.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `VersionEvent`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `versionNo`, `contentHash`, `status`; tổng 12 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.versionApproved.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-18 (thông báo người soạn); PH-02 (chuẩn bị bản API công bố mới).

**FR.** FR-04-041.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "versionNo": 3,
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "status": "APPROVED", "comment": "Đạt.",
 "contributors": ["an.nv"],
 "actor": {"userId": "binh.tt", "type": "USER"}}
```
:::

#### EVT-04-05 · Yêu cầu sửa

::: dac-ta
**Mục đích.** Yêu cầu sửa (FR-04-041).

**Kênh, topic.** `{tenant}.integration.version.changes-requested.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `VersionEvent`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `versionNo`, `contentHash`, `status`; tổng 12 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.versionChangesRequested.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-18 (thông báo người soạn kèm số bình luận).

**FR.** FR-04-041.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "versionNo": 3,
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "status": "CHANGES_REQUESTED",
 "comment": "Thiếu ca lỗi hệ đích.", "nodeCommentCount": 2,
 "actor": {"userId": "binh.tt", "type": "USER"}}
```
:::

#### EVT-04-06 · Yêu cầu phát hành, nâng, quay lui, gỡ

::: dac-ta
**Mục đích.** Yêu cầu phát hành, nâng, quay lui, gỡ (FR-04-042, 044, 045, 006).

**Kênh, topic.** `{tenant}.integration.deployment.requested.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `DeploymentRequested`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `deploymentId`, `versionNo`, `environment`, `kind`; tổng 11 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.deploymentRequested.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-13 (ghi mốc triển khai lên biểu đồ giám sát).

**FR.** FR-04-042, FR-04-044, FR-04-045, FR-04-006.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "deploymentId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54",
 "versionNo": 3, "environment": "TEST", "kind": "RELEASE",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "runtimeProfile": "core-native",
 "actor": {"userId": "binh.tt", "type": "USER"}}
```
:::

#### EVT-04-07 · Trạng thái triển khai đổi

::: dac-ta
**Mục đích.** Trạng thái triển khai đổi.

**Kênh, topic.** `{tenant}.integration.deployment.status-changed.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `DeploymentStatusChanged`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `deploymentId`, `environment`, `to`; tổng 12 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.deploymentStatusChanged.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-02 (bật, tắt API công bố theo trạng thái); PH-13 (cảnh báo triển khai lỗi); PH-18 (thông báo người phát hành).

**FR.** FR-04-042.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "deploymentId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54",
 "versionNo": 3, "environment": "TEST", "from": "SYNCING",
 "to": "SYNCED", "healthStatus": "HEALTHY",
 "gitCommit": "9c1e4b7"}
```
:::

#### EVT-04-08 · Tạm dừng, tiếp tục, dừng khẩn đã được xác nhận

::: dac-ta
**Mục đích.** Tạm dừng, tiếp tục, dừng khẩn đã được xác nhận (FR-04-050).

**Kênh, topic.** `{tenant}.integration.flow.runtime-state-changed.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `RuntimeStateChanged`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `environment`, `action`, `state`; tổng 11 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.flowRuntimeStateChanged.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-02 (đánh dấu API tạm ngừng); PH-13 (ghi sự cố, mốc vận hành).

**FR.** FR-04-050.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "environment": "PROD",
 "commandId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61",
 "action": "PAUSE", "state": "PAUSED",
 "reason": "Hệ đích NDXP bảo trì.",
 "actor": {"userId": "cuong.lv", "type": "USER"}}
```
:::

#### EVT-04-09 · Luồng đã gỡ

::: dac-ta
**Mục đích.** Luồng đã gỡ (FR-04-006).

**Kênh, topic.** `{tenant}.integration.flow.retired.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `FlowRetired`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `reason`; tổng 6 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.flowRetired.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-02 (gỡ API công bố); PH-10 (thu hồi nhóm tiêu thụ của luồng).

**FR.** FR-04-006.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "reason": "Thay bằng luồng tra-cuu-ho-tich-v2.",
 "actor": {"userId": "ta.t68", "type": "USER"}}
```
:::

#### EVT-04-10 · Lần chạy thử kết thúc

::: dac-ta
**Mục đích.** Lần chạy thử kết thúc (FR-04-030).

**Kênh, topic.** `{tenant}.integration.testrun.completed.v1`.

**Khóa phân vùng.** `{tenant}:{flowId}` để giữ thứ tự theo luồng.

**Lược đồ.** `TestRunCompleted`; trường bắt buộc: `tenantId`, `flowId`, `flowCode`, `runId`, `versionNo`, `definitionHash`, `status`; tổng 11 trường.

**Tiêu đề.** CloudEvents 1.0 nhị phân (`ce_*`, §4.1), `ce_type = vn.datahub.integration.testRunCompleted.v1`.

**Phân vùng, thời gian giữ.** 6 phân vùng, 3 bản sao; giữ 7 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; qua outbox `ph04.outbox`, Debezium đưa lên Kafka.

**Bên nhận.** PH-18 (thông báo người chạy khi đã rời trang).

**FR.** FR-04-030.

**Ví dụ payload.**

```json
{"tenantId": "T68",
 "flowId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10",
 "flowCode": "tra-cuu-ho-tich", "workspaceCode": "ho-tich",
 "runId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41",
 "versionNo": 3,
 "definitionHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "mode": "MOCK", "status": "PASSED", "testCaseId": null,
 "durationMs": 412}
```
:::

#### EVT-04-11 · Lệnh điều khiển runtime có ký

::: dac-ta
**Mục đích.** Lệnh điều khiển runtime có ký (ADR-065). Không qua outbox: dh-integration ghi trực tiếp sau khi lưu runtime_command.

**Kênh, topic.** `dh.integration.runtime.command.v1` (topic hệ thống, ACL chỉ `dh-integration`, `dh-runtime`).

**Khóa phân vùng.** `{tenant}:{environment}`.

**Lược đồ.** `RuntimeCommand`; trường bắt buộc: `commandId`, `tenantId`, `environment`, `flowCode`, `action`, `issuedAt`, `expiresAt`, `keyId`, `signature`; tổng 13 trường.

**Tiêu đề.** `traceparent`, `ce_id` (không qua outbox, không theo CloudEvents đầy đủ).

**Phân vùng, thời gian giữ.** 12 phân vùng, 3 bản sao; giữ 1 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-integration`; ghi trực tiếp sau khi lưu `runtime_command` (độ trễ < 5 giây, NFR-04-010).

**Bên nhận.** dh-runtime (mọi bản sao của tenant và môi trường, kiểm chữ ký rồi thi hành).

**FR.** FR-04-050.

**Ví dụ payload.**

```json
{"commandId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61",
 "tenantId": "T68", "environment": "PROD",
 "flowCode": "tra-cuu-ho-tich", "action": "PAUSE",
 "routeIds": [], "drain": true, "issuedBy": "cuong.lv",
 "issuedAt": "2026-11-26T14:55:00Z",
 "expiresAt": "2026-11-26T14:56:00Z", "resendOf": null,
 "keyId": "dh-runtime-cmd:3", "signature": "MEUCIQ…giả-lập"}
```
:::

#### EVT-04-12 · Nhịp tim mỗi 30 giây của bản sao runtime

::: dac-ta
**Mục đích.** Nhịp tim mỗi 30 giây của bản sao runtime.

**Kênh, topic.** `dh.integration.runtime.heartbeat.v1` (topic hệ thống, ACL chỉ `dh-integration`, `dh-runtime`).

**Khóa phân vùng.** `{replica}`.

**Lược đồ.** `Heartbeat`; trường bắt buộc: `replica`, `tenantId`, `environment`, `sentAt`, `flows`; tổng 8 trường.

**Tiêu đề.** `traceparent`, `ce_id` (không qua outbox, không theo CloudEvents đầy đủ).

**Phân vùng, thời gian giữ.** 12 phân vùng, 3 bản sao; giữ 1 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-runtime`; phát trực tiếp từ runtime.

**Bên nhận.** dh-integration (Reconciler: so băm, cập nhật SYNCED, trạng thái route).

**FR.** FR-04-051, FR-04-042.

**Ví dụ payload.**

```json
{"replica": "dh-rt-t68-core-7c9d-x2k4p", "tenantId": "T68",
 "environment": "PROD", "profile": "core-native",
 "catalogVersion": "camel-quarkus-3.33.2",
 "libVersion": "1.4.0", "sentAt": "2026-11-26T14:55:30Z",
 "flows": [{"flowCode": "tra-cuu-ho-tich", "versionNo": 2,
   "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
   "loaded": true,
   "routes": [{"routeId": "tra-cuu", "state": "Started", "inflight": 1}]}]}
```
:::

#### EVT-04-13 · Xác nhận lệnh của từng bản sao

::: dac-ta
**Mục đích.** Xác nhận lệnh của từng bản sao.

**Kênh, topic.** `dh.integration.runtime.command-ack.v1` (topic hệ thống, ACL chỉ `dh-integration`, `dh-runtime`).

**Khóa phân vùng.** `{commandId}`.

**Lược đồ.** `CommandAck`; trường bắt buộc: `commandId`, `replica`, `result`, `ackedAt`; tổng 7 trường.

**Tiêu đề.** `traceparent`, `ce_id` (không qua outbox, không theo CloudEvents đầy đủ).

**Phân vùng, thời gian giữ.** 12 phân vùng, 3 bản sao; giữ 1 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-runtime`; phát trực tiếp từ runtime.

**Bên nhận.** dh-integration (Reconciler: đếm xác nhận, đặt ACKNOWLEDGED, PARTIAL, REJECTED).

**FR.** FR-04-050.

**Ví dụ payload.**

```json
{"commandId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61",
 "replica": "dh-rt-t68-core-7c9d-x2k4p", "tenantId": "T68",
 "environment": "PROD", "result": "APPLIED",
 "ackedAt": "2026-11-26T14:55:02Z"}
```
:::

#### EVT-04-14 · Nhật ký kết nối từ chặng audit

::: dac-ta
**Mục đích.** Nhật ký kết nối từ chặng audit (BR-04-002). Chủ quản topic: PH-13; giữ online 12 tháng, WORM 5 năm ở PH-13.

**Kênh, topic.** `{tenant}.audit.connection-log.v1`.

**Khóa phân vùng.** `{tenant}:{flowCode}`.

**Lược đồ.** `ConnectionLog`; trường bắt buộc: `tenantId`, `flowCode`, `traceId`, `outcome`, `receivedAt`; tổng 22 trường.

**Tiêu đề.** `traceparent`, `ce_id` (không qua outbox, không theo CloudEvents đầy đủ).

**Phân vùng, thời gian giữ.** 12 phân vùng, 3 bản sao; giữ 30 ngày; `cleanup.policy = delete`.

**Bên phát.** `dh-runtime`; phát trực tiếp từ runtime.

**Bên nhận.** PH-13 (lưu nhật ký kết nối theo NĐ 278/2025, online 12 tháng, WORM 5 năm).

**FR.** FR-04-074.

**Ví dụ payload.**

```json
{"tenantId": "T68", "flowCode": "tra-cuu-ho-tich",
 "versionNo": 2, "routeId": "tra-cuu", "environment": "PROD",
 "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "sourceSystem": "DVC-T68", "targetSystem": "NDXP",
 "httpStatus": 200, "outcome": "SUCCESS",
 "receivedAt": "2026-11-26T14:40:11Z", "durationMs": 184,
 "legalBasisRef": "ND-278-2025",
 "maskedFields": ["soDinhDanh"]}
```
:::
<!-- gen:dac-ta-evt:end -->

## 5. Hợp đồng với phân hệ khác và bên ngoài

Chương này nêu những gì PH-04 cần từ phân hệ khác và từ hệ ngoài, kèm thời gian chờ và cách xử lý khi bên kia lỗi, để khi một phụ thuộc gián đoạn thì phần còn lại của PH-04 vẫn dùng được. `dh-integration` gọi đồng bộ các phân hệ sau. Mọi lệnh gọi qua mesh mTLS với token dịch vụ, client sinh từ hợp đồng của phân hệ chủ quản.

| Bên được gọi | Thao tác | PH-04 dùng ở | Thời gian chờ, thử lại | Khi lỗi |
|---|---|---|---|---|
| PH-05 Kết nối | Kiểm tra mã kết nối tồn tại, loại, đã cấp cho không gian, có giá trị cho môi trường | VR-07 khi lưu, gửi duyệt, phát hành | 2 giây; 1 lần | Kiểm tra trả cảnh báo "chưa xác minh" ở `DESIGN`; chặn ở `SUBMIT` với ERR-04-047 |
| PH-02 API | Lấy OpenAPI của API công bố khi tạo luồng `OPENAPI`; liệt kê API dùng luồng (phụ thuộc cứng) | API-04-011, 016 | 5 giây; 2 lần | ERR-04-047 (503) |
| PH-10 Hub | Kiểm tra topic đã đăng ký (BR-04-009) | VR-08 | 2 giây; 1 lần | Như PH-05 |
| PH-01 HTTT | Bản sao đọc HTTT đã kết nạp (EN-04-22), qua sự kiện, không gọi đồng bộ | VR-10, ERR-04-043 | — | Dùng bản sao gần nhất |
| PH-13 Giám sát | Số liệu theo luồng, lịch sử kiểm toán | API-04-063, 091 | 5 giây; không thử lại | ERR-04-047 |
| PH-18 Tham số | Đọc `04.*`, khoảng đóng băng | Mọi lệnh ghi | Bản đệm 60 giây | Dùng bản đệm; hết bản đệm thì giá trị mặc định an toàn (đóng băng = không) |
| Git (GitHub khi phát triển, GitLab on-prem khi bàn giao, Q353) | Commit `env/test`, `env/staging`; merge request `env/prod` | API-04-054, 055, 056, 015 | 15 giây; 3 lần giãn cách lũy thừa | ERR-04-022 (502), triển khai `FAILED` |
| OpenBao transit | Ký lệnh | API-04-061 | 1 giây; 2 lần | ERR-04-047; lệnh không được gửi |
| Sandbox `dh-runtime-sandbox` | Chạy thử, biên dịch biểu thức, chạy JQ ánh xạ (Valkey Stream `dh:int:testrun:queue`) | API-04-032, 033, 040 | Theo `timeoutSeconds`, ≤ 120 giây | ERR-04-019 (503), hoặc ERR-04-020 khi quá giờ |

: Phân hệ và hệ ngoài mà dh-integration gọi

Chiều ngược lại, sandbox gọi hai API nội bộ của `dh-integration` (SDD §8.2 bước 2 và 4). Hai API này nằm dưới `/internal/v1`, chỉ trong cụm, xác thực bằng mTLS và tài khoản dịch vụ của sandbox, không qua `apisix-int` và không có trong `openapi-integration.yaml`. Bản 0.2 chưa cấp mã API cho chúng; đề nghị ở chương 11.

| Bên gọi | Thao tác | Nội dung | Ghi chú |
|---|---|---|---|
| Sandbox | `GET /internal/v1/testruns/{id}/bundle` | Lấy YAML chuẩn hóa, `*.jq`, bản tin, ca kiểm thử, cấu hình mô phỏng, giá trị kết nối TEST (chỉ `SANDBOX_LIVE`) | Chỉ khi lần chạy ở `QUEUED` hoặc `RUNNING`; không trả bí mật PROD |
| Sandbox | `POST /internal/v1/testruns/{id}/steps` | Gửi kết quả từng chặng theo lô 200 ms (`nodeId`, `status`, `startOffsetMs`, `durationMs`, tiêu đề đã lọc, thân đã che ≤ 64 KiB) và kết quả cuối | `dh-integration` ghi `test_run_step`, đẩy SSE API-04-042, phát EVT-04-10 |

: API nội bộ sandbox gọi dh-integration (chưa có mã)

Trong giai đoạn chạy song song với Bus cũ (D06-01), PH-04 không gọi Bus. Chuyển luồng cũ dùng tệp XML do người vận hành xuất từ Bus và tải lên (API-04-028).

## 6. Bảng mã lỗi ERR-04

Đây là bảng chính thức mà FRS §8.1 dẫn tới. Cột "Câu hiển thị" ghi câu tiếng Việt người dùng nhìn thấy, lấy đúng từ D03-06-PH04 §5.3 và FRS D02-03-PH04 §9.2 (bản 0.2); tham số trong `{}` lấy từ trường mở rộng của lỗi RFC 9457, và mọi thông điệp kèm "Mã lỗi {code} · Mã truy vết {traceId}". Câu ghi "(mới, chương 11)" do tài liệu này viết, chưa có ở hai tập kia. Mã không có câu riêng thì hiển thị `title`. Mỗi mã có một nghĩa duy nhất. Một tình huống có thể trả mã HTTP khác tùy ngữ cảnh: ERR-04-019 là 429 khi hết hạn mức và 503 khi sandbox không sẵn sàng.

### 6.1. Lỗi API điều khiển (ERR-04-001…049)

| Mã | HTTP | Nghĩa | Trả ở | Câu hiển thị |
|---|---|---|---|---|
| ERR-04-001 | 404 | Không tìm thấy luồng, hoặc không có quyền xem (không phân biệt hai trường hợp) | Mọi `/flows/{flowCode}…` | "Không tìm thấy luồng, hoặc bạn không có quyền xem luồng này." |
| ERR-04-002 | 409 | Mã luồng đã dùng trong tenant, kể cả mã của luồng gỡ chưa quá 30 ngày (BR-04-001) | API-04-011, 014 | "Mã luồng "{code}" đã được dùng trong tỉnh." |
| ERR-04-003 | 403 | Không có mức `EDIT` (hoặc `MAINTAIN` khi duyệt) trên không gian làm việc | Lệnh ghi theo luồng | "Bạn chưa có quyền sửa trong không gian làm việc "{workspace}"." |
| ERR-04-004 | 404 | Không tìm thấy phiên bản | `/versions/{versionNo}…` | "Không tìm thấy phiên bản v{n} của luồng này." |
| ERR-04-005 | 409 | Trạng thái hiện tại không cho phép thao tác (gồm duyệt khi chưa xem so sánh, gỡ khi đang có lần chạy thử) | Lệnh đổi trạng thái | "Phiên bản đang ở trạng thái "{status}" nên không thể {action}." |
| ERR-04-006 | 412 | ETag không khớp; kèm `currentEtag`, `savedBy`, `savedAt` | Lệnh có `If-Match` | "{user} đã lưu phiên bản này lúc {time}. Thay đổi của bạn chưa được lưu." |
| ERR-04-007 | 428 | Thiếu `If-Match` | Lệnh có `If-Match` | "Thiếu thông tin phiên bản dữ liệu. Tải lại trang rồi thử lại." |
| ERR-04-008 | 422 | YAML không phân tích được; `errors[]` có dòng, cột | API-04-011, 022, 027, 031 | "YAML có lỗi cú pháp ở dòng {line}, cột {column}: {message}" |
| ERR-04-009 | 422 | Định nghĩa còn lỗi kiểm tra ở mức yêu cầu, hoặc loại tài nguyên không khớp nội dung; kèm `findings[]` | API-04-011, 040, 050, 054, 055, 056 | "Luồng còn {n} lỗi cần sửa trước khi {action}." |
| ERR-04-010 | 422 | Phát hiện giá trị giống bí mật (BR-04-003); `findings[]` chỉ có đường dẫn và loại, không lặp giá trị | API-04-022, 027, 090 | "Phát hiện giá trị giống bí mật ở chặng "{node}", trường "{field}". Không được ghi bí mật vào luồng." |
| ERR-04-011 | 422 | Thành phần, EIP, dataformat, ngôn ngữ hoặc lớp bean không được phép (BR-04-014) | Kiểm tra `SUBMIT`, `PUBLISH` | "Thành phần "{component}" không được phép dùng trong tỉnh." |
| ERR-04-012 | 422 | Luồng đối ngoại thiếu chặng chuẩn (BR-04-002); `findings[].args.stages` | Kiểm tra `SUBMIT` | "Luồng đối ngoại phải có đủ chín chặng chuẩn. Đang thiếu: {stages}." |
| ERR-04-013 | 422 | Kết nối không tồn tại, sai loại, chưa cấp cho không gian, thiếu giá trị cho môi trường, hoặc không phải loại chỉ đọc cho chặng SQL | Kiểm tra; API-04-040 `SANDBOX_LIVE` | "Kết nối "{connection}" không tồn tại, sai loại hoặc chưa được cấp cho không gian làm việc." |
| ERR-04-014 | 409 | Chưa có lần chạy thử không mô phỏng đạt trên đúng `contentHash`, hoặc còn ca kiểm thử chưa đạt (BR-04-004) | API-04-050 | "Chưa có lần chạy thử đạt (không mô phỏng) cho đúng nội dung đang gửi, hoặc còn ca kiểm thử chưa đạt." |
| ERR-04-015 | 403 | Người duyệt là người tạo, người đóng góp hoặc người gửi (BR-04-005) | API-04-052 | "Bạn đã tạo, đóng góp hoặc gửi duyệt phiên bản này nên không thể tự duyệt. Cần một người duyệt khác." |
| ERR-04-016 | 409 | Luồng đã có phiên bản mở (BR-04-016); kèm `versionNo`, người tạo | API-04-021 | "Luồng đã có bản nháp v{n} do {user} tạo." |
| ERR-04-017 | 409 | Còn phụ thuộc cứng; kèm `dependencies[]` | API-04-015; xóa không gian còn luồng | "Luồng đang được dùng bởi {n} đối tượng. Gỡ các phụ thuộc trước." |
| ERR-04-018 | 409 | `Idempotency-Key` đã dùng với nội dung khác | Lệnh có chống trùng | "Yêu cầu này đã được gửi với nội dung khác. Tải lại trang rồi thử lại." |
| ERR-04-019 | 429 / 503 | Hết hạn mức chạy thử đồng thời của tenant (429, kèm `retryAfterSeconds`), hoặc sandbox không sẵn sàng (503) | API-04-032, 033, 040 | "Môi trường chạy thử đang bận hoặc chưa sẵn sàng (tỉnh đang có {n}/{max} lần chạy thử đồng thời). Thử lại sau ít phút." |
| ERR-04-020 | — | Lần chạy thử quá thời gian; không phải mã HTTP mà là `errorCode` của `TestRun` ở trạng thái `TIMED_OUT`, kèm `hungNodeId` | API-04-042 | "Lần chạy thử quá {n} giây và đã dừng ở chặng "{node}"." |
| ERR-04-021 | 413 | Bản tin mẫu, thân chạy thử hoặc tài liệu mẫu ánh xạ vượt giới hạn | API-04-022, 033, 040, 044 | "Bản tin mẫu vượt {limit}." |
| ERR-04-022 | 502 | Không ghi được kho cấu hình Git; triển khai `FAILED` | API-04-015, 054, 055, 056 | "Không ghi được vào kho cấu hình. Luồng chưa được phát hành." |
| ERR-04-023 | 409 | Sai thứ tự môi trường, môi trường trước chưa `SYNCED`/`HEALTHY`/đủ thời gian ổn định (BR-04-019), hoặc luồng chưa triển khai ở môi trường của lệnh | API-04-054, 056, 061 | "Phiên bản phải đồng bộ, khỏe ở {previousEnv} (và chạy ổn định đủ {minutes} phút) trước khi lên {env}, hoặc luồng chưa triển khai ở {env}." |
| ERR-04-024 | — | Runtime từ chối hoặc không xác nhận lệnh; là trạng thái `REJECTED`, `PARTIAL` của `Command`, không phải mã HTTP | API-04-061 | "Runtime chưa xác nhận lệnh ({k}/{n} bản sao) hoặc đã từ chối lệnh." |
| ERR-04-025 | 400 | Thiếu hoặc quá ngắn: lý do, ghi chú thay đổi, ý kiến duyệt, mục checklist bắt buộc (BR-04-017) | API-04-015, 050, 051, 052, 055, 061 | "Vui lòng nhập lý do (ít nhất {min} ký tự)." |
| ERR-04-026 | 400 | `limit` vượt 100 | Danh sách có phân trang | "Mỗi trang tối đa 100 dòng." |
| ERR-04-027 | 404 | Không tìm thấy không gian làm việc | API-04-002…004, 011, 013 | "Không tìm thấy không gian làm việc "{workspace}"." |
| ERR-04-028 | 409 | Mã không gian làm việc đã dùng | API-04-002 | "Mã không gian làm việc "{code}" đã được dùng." |
| ERR-04-029 | 422 | Không hồ sơ runtime nào có đủ thành phần luồng dùng, hoặc hồ sơ JVM không được phép cho tenant | Kiểm tra `PUBLISH`; API-04-054 | "Không hồ sơ runtime nào có đủ thành phần: {components}." |
| ERR-04-030 | 404 | Không tìm thấy lần chạy thử, ca kiểm thử, triển khai, lệnh, đề xuất hoặc tác vụ chuyển đổi | Tài nguyên con | "Không tìm thấy đối tượng được yêu cầu (lần chạy thử, ca kiểm thử, triển khai hoặc lệnh)." |
| ERR-04-031 | 422 | Câu SQL vi phạm chính sách Q359 (không phải `SELECT` một câu, dùng hàm bị cấm, thiếu tham số hóa) | Kiểm tra mọi mức | "Câu lệnh SQL ở chặng "{node}" không được phép: {reason}. Luồng chỉ được đọc dữ liệu." |
| ERR-04-032 | 422 | Tệp không phải Camel XML hợp lệ của Bus cũ | API-04-028 | "Tệp không phải Camel XML hợp lệ của hệ cũ hoặc vượt 2 MiB." |
| ERR-04-033 | 413 | Định nghĩa luồng vượt 512 KiB | API-04-011, 022, 027, 031 | "Định nghĩa luồng vượt {limit}. Tách thành nhiều luồng hoặc luồng con." |
| ERR-04-034 | 409 | Luồng đã gỡ, chỉ đọc | Lệnh ghi theo luồng | "Luồng đã gỡ và chỉ còn để xem." |
| ERR-04-035 | 404 | Thành phần không có trong catalog của phiên bản yêu cầu | API-04-071 | "Thành phần "{component}" không có trong danh mục của phiên bản {version}." |
| ERR-04-036 | 409 | Tên Kamelet trùng Kamelet nền hoặc Kamelet khác trong tenant | API-04-011, 022 với `resourceKind = KAMELET` | "Đã có Kamelet tên "{name}"." |
| ERR-04-037 | 422 | Biểu thức không biên dịch được (chế độ chặt); chế độ thường trả 200 `valid = false` | API-04-032; kiểm tra `SUBMIT` | "Biểu thức {language} có lỗi ở vị trí {pos}: {message}" |
| ERR-04-038 | 422 | Ánh xạ tới trường đích không tồn tại, vòng tham chiếu, hàm không hỗ trợ | API-04-033; kiểm tra `SUBMIT` | "Ánh xạ tới trường "{target}" không hợp lệ: {reason}" |
| ERR-04-039 | 404 | Khuôn mẫu không tồn tại hoặc không được phép | API-04-011, 081 | "Khuôn mẫu "{template}" không tồn tại hoặc không được phép dùng trong tỉnh." |
| ERR-04-040 | 409 | Phiên bản đích của quay lui dùng thành phần nay bị cấm | API-04-055 | "Không quay lui được về v{n} vì phiên bản đó dùng thành phần "{component}" nay không còn được phép." |
| ERR-04-041 | 423 | Đang trong khoảng đóng băng thay đổi (BR-04-022); chỉ quay lui và tạm dừng khẩn được phép | API-04-054, 056; API-04-022 khi tỉnh đóng băng cả việc soạn | "Đang trong khoảng đóng băng thay đổi tới {until}. Chỉ được quay lui hoặc tạm dừng khẩn." |
| ERR-04-042 | 409 | Phiên bản soạn trên catalog cũ hơn catalog hiện hành của tenant; cần mở lại để nâng | API-04-050, 054 | "Luồng được soạn trên danh mục thành phần {old}, cũ hơn danh mục hiện hành {new}. Mở lại luồng để kiểm tra lại." |
| ERR-04-043 | 422 | HTTT nguồn hoặc đích chưa kết nạp ở PH-01 (luồng đối ngoại) | Kiểm tra `SUBMIT` | "HTTT "{system}" chưa được kết nạp hoặc chưa hoạt động ở danh mục HTTT." |
| ERR-04-044 | 401 | Thiếu token, token hết hạn, hoặc cần xác thực lại | Mọi API | "Phiên làm việc đã hết hạn hoặc cần đăng nhập lại để tiếp tục." (mới, chương 11) |
| ERR-04-045 | 403 | Thiếu quyền chức năng `PERM-04-*` | Mọi API | "Bạn chưa có quyền thực hiện thao tác này." |
| ERR-04-046 | 415 | Kiểu nội dung không hỗ trợ | Lệnh có thân | "Định dạng tệp hoặc nội dung gửi lên không được hỗ trợ." (mới, chương 11) |
| ERR-04-047 | 503 | Phân hệ phụ thuộc chưa sẵn sàng (PH-05, PH-02, PH-13, OpenBao) | Xem §5 | "Chưa lấy được dữ liệu từ {phân hệ}. Thử lại sau." |
| ERR-04-048 | 429 | Vượt giới hạn tần suất của người dùng | Mọi API | "Bạn thao tác quá nhanh. Vui lòng thử lại sau {retryAfterSeconds} giây." (mới, chương 11) |
| ERR-04-049 | 400 | Tham số truy vấn hoặc thân yêu cầu sai lược đồ | Mọi API | "Giá trị của {tham số} không hợp lệ." |

: Lỗi API điều khiển (ERR-04-001…049)

### 6.2. Lỗi runtime trả cho bên gọi luồng (ERR-04-101…112)

`dh-runtime` trả các lỗi này cho HTTT gọi luồng đồng bộ, theo RFC 9457, qua APISIX. Với luồng bất đồng bộ, mã lỗi ghi vào tiêu đề `dh-error-code` của bản tin DLQ (BR-04-008). Cả hai trường hợp đều ghi vào nhật ký kết nối EVT-04-14. Thân lỗi không chứa dữ liệu nghiệp vụ, chi tiết hệ đích hay stack trace. Dải ERR-04-113…120 để dành.

| Mã | HTTP | Nghĩa | Chặng | DLQ (bất đồng bộ) | Câu trả bên gọi (`title`), nơi người vận hành thấy |
|---|---|---|---|---|---|
| ERR-04-101 | 400 | Bản tin sai lược đồ; ≤ 20 lỗi theo đường dẫn trường, không lặp giá trị | `schema` (hoặc `receive` khi không giải tuần tự được) | Ngay | "Bản tin không đúng lược đồ {schemaRef}: {n} lỗi."; trả trong thân lỗi, bản tin vào DLQ (PH-18) |
| ERR-04-102 | 403 | OPA từ chối, hoặc không trả lời trong 200 ms | `authz` | Không (bỏ, ghi nhật ký) | "Bên gọi không được phép dùng dịch vụ này cho mục đích đã khai."; nhật ký kết nối |
| ERR-04-103 | 504 | Hệ đích quá thời gian chờ | `deliver` | Sau khi hết lượt thử lại | "Hệ thống cung cấp dữ liệu không phản hồi kịp. Thử lại sau."; PH-13 |
| ERR-04-104 | 502 | Hệ đích trả lỗi sau khi hết lượt thử lại | `deliver` | Sau khi hết lượt thử lại | "Hệ thống cung cấp dữ liệu trả lỗi. Thử lại sau."; DLQ |
| ERR-04-105 | 503 | Mạch ngắt đang mở với hệ đích, hoặc luồng không có nhánh dự phòng | `deliver` | Giữ để thử lại theo lịch | "Hệ thống cung cấp dữ liệu đang tạm gián đoạn. Thử lại sau."; chỉ số mạch ngắt ở PH-13 |
| ERR-04-106 | 409 | Trùng `Idempotency-Key` khi kết quả cũ không còn | `receive` | Không (bỏ trùng) | "Yêu cầu này đã được xử lý trước đó."; chỉ thân lỗi |
| ERR-04-107 | 413 | Thân vượt giới hạn của luồng | `receive` | Ngay | "Bản tin vượt kích thước tối đa {limit} của dịch vụ."; DLQ |
| ERR-04-108 | 422 | Lỗi chuyển đổi, mã không có trong bảng (cấu hình `FAIL`), SQL quá thời gian hoặc vượt số dòng | `transform`, `enrich` | Ngay | "Không chuyển đổi được dữ liệu: {lý do ngắn}."; DLQ |
| ERR-04-109 | 500 | Lỗi nội bộ của luồng không thuộc nhóm trên | Bất kỳ | Ngay | "Lỗi nội bộ khi xử lý yêu cầu. Mã truy vết {traceId}."; DLQ, cảnh báo PH-13 |
| ERR-04-110 | 503 | Luồng hoặc route đang tạm dừng | `receive` | Không nhận (consumer dừng) | "Dịch vụ đang tạm dừng. Thử lại sau."; chỉ thân lỗi |
| ERR-04-111 | 404 | Đường dẫn không khớp route nào của luồng | `receive` | — | "Không có dịch vụ tại đường dẫn này."; chỉ thân lỗi |
| ERR-04-112 | 500 | Tiêu đề tenant khác tenant của runtime (`TenantGuard`); cảnh báo an ninh mức cao ở PH-13 | `receive` | Không (bỏ, cảnh báo) | "Lỗi nội bộ khi xử lý yêu cầu. Mã truy vết {traceId}."; cảnh báo an ninh mức cao ở PH-13 |

: Lỗi runtime trả cho bên gọi luồng (ERR-04-101…112)

## 7. Kiểm tra hợp đồng trong CI

Chương này nêu các kiểm tra tự động bảo đảm hợp đồng, tài liệu và mã nguồn không lệch nhau, và kết quả chạy ở bản 0.2. Hai tệp hợp đồng được kiểm tra ở cổng CI-5 của D04-02:

- Lint OpenAPI và AsyncAPI bằng Spectral với bộ luật dự án.
- Mọi `$ref` phải phân giải được; mọi ví dụ phải khớp lược đồ.
- Mỗi operation phải có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`.
- Lệnh ghi phải có `If-Match` hoặc `Idempotency-Key`.
- `oasdiff` so với nhánh `main`, chặn thay đổi phá vỡ trong `v1`.
- Lược đồ sự kiện được kiểm tra tương thích ngược ở Apicurio.

Kiểm thử contract phía máy chủ (sinh từ hợp đồng) chạy ở CI-3 trên `dh-integration` với Testcontainers. Client TypeScript của console sinh từ OpenAPI (`openapi-typescript`) ở CI-6. Thêm hai kiểm tra riêng của PH-04:

- Mọi mã `ERR-04-nnn` xuất hiện trong mã nguồn phải có trong §6 và trong bảng câu hiển thị D03-06-PH04 §5.3, nếu không phải mã chỉ dùng `title`.
- Danh sách `allowedActions` mà máy chủ trả phải nằm trong tập hành động giao diện biết.

Tại thời điểm viết, `openapi-integration.yaml` đã qua `openapi-spec-validator` (OpenAPI 3.1), `asyncapi-integration.yaml` đã qua `@asyncapi/parser` 3 không lỗi. Lint Spectral sẽ chạy khi bộ luật dự án được đưa vào repo.

Bản 0.2 thêm công cụ [`ph04/tools/check_contracts.py`](ph04/tools/check_contracts.py), chép từ PH-05 và chỉnh cho PH-04:

| Kiểm | Cách kiểm | Kết quả 26/11/2026 |
|---|---|---|
| OpenAPI 3.1 hợp lệ | `openapi-spec-validator` 0.9 | Đạt |
| Mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, `summary`, `description` | Duyệt `paths` | Đạt, 70/70 |
| Lệnh ghi có `If-Match` hoặc `Idempotency-Key` (trừ 9 lệnh chỉ tính toán hoặc không đổi tài nguyên, danh sách `MIEN` trong công cụ) | Duyệt tham số | Đạt |
| Mỗi operation có ví dụ yêu cầu (thân hoặc tham số) và ví dụ phản hồi thành công; tiêu đề `ETag`, `Location` có ví dụ | Duyệt `example` | Đạt, 70/70 |
| Mọi ví dụ khớp lược đồ (thân yêu cầu, tham số, phản hồi, ProblemDetails) | `jsonschema` 4 Draft 2020-12 | Đạt, 234 ví dụ |
| AsyncAPI 3.0 hợp lệ; mỗi message có `x-datahub-fr`, `x-datahub-receivers`, ví dụ payload khớp lược đồ; đủ EVT-04-01…14 | `@asyncapi/parser` 3.4 (biến `DH_ASYNCAPI_PARSER`), `jsonschema` | Đạt, 0 lỗi, 0 cảnh báo, 14 ví dụ |

: Kết quả kiểm hợp đồng bản 0.2

Khi viết ví dụ, công cụ phát hiện một lỗi của hợp đồng bản 0.1: các lược đồ ghép bằng `allOf` từ những phần cùng đóng (`additionalProperties: false`), ví dụ `FlowDetail`, `VersionDetail`, `TestRun`, `Deployment`, nên không bản ghi hợp lệ nào qua được kiểm tra. Bản 0.2 sửa ở nguồn sinh: `gen_openapi.py` gộp `allOf` thành một đối tượng phẳng giữ `additionalProperties: false`. Tên và trường của mọi lược đồ không đổi.

Trình tự chạy lại sau khi sửa nguồn: `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py`, `build/tools/sinh_dac_ta_api.py ph04/openapi-integration.yaml D03-04-PH04-api-tich-hop.md --vi-du`, rồi `check_contracts.py`.

## 8. Ánh xạ từ hệ cũ và mã đang chạy

Chương này cho người đang vận hành Bus cũ và mã W2 biết thao tác quen thuộc của họ chuyển sang API nào, và điểm yếu nào được bỏ trên đường chuyển.

| Hệ cũ hoặc mã W2 | API mới | Ghi chú |
|---|---|---|
| Bus: danh sách chương trình, tìm theo endpoint, nguồn, tên, host (LGC-BUS-001…005) | API-04-010 | `endpoint` dùng chỉ mục EN-04-04b; host thay bằng `environment` |
| Bus: Start/Stop agent, route qua JMX-Jolokia (LGC-BUS-009, 012) | API-04-061 | Lệnh có ký, xác nhận theo bản sao, có lý do |
| Bus: xóa chương trình (LGC-BUS-010) | API-04-015 | Kiểm tra phụ thuộc, rút theo môi trường qua Git |
| Tooling: lưu XML kéo thả, sinh mã | API-04-022, 027 | YAML DSL; bố cục tách khỏi định nghĩa |
| Tooling: nhập, xuất tệp | API-04-026, 027, 028 | XML cũ qua bộ chuyển đổi, có báo cáo |
| W2 `apps/control` `RoutesController` `/api/routes…` | `/api/integration/v1/flows…` | Đường dẫn cũ giữ một bản phát hành, trả `Deprecation` và `Link` tới đường dẫn mới, sau đó gỡ (SDD §2.5) |
| W2 chạy thử giả lập | API-04-040 `MOCK`, `SANDBOX_LIVE` | Lần chạy cũ chuyển thành `SIMULATED`, không tính cho BR-04-004 |

: Ánh xạ từ Bus cũ và mã W2 sang API mới

## 9. Câu hỏi mở

Các câu hỏi dưới đây chưa chốt nhưng đã có đề xuất tạm để không chặn hiện thực; dải mã Q04-55…59 dành cho tập API.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q04-55 | Tên miền chính thức cho `type` của ProblemDetails (`https://datahub.gov.vn/problems/integration/…` là giả định, cùng kiểu Q07-100) | Chốt cùng D03-09 |
| Q04-56 | Đường dẫn W2 `/api/routes` cần giữ bao lâu, có client nào ngoài console cũ gọi không | Giữ một bản phát hành; kiểm tra log APISIX trước khi gỡ |
| Q04-57 | SSE qua BFF và APISIX có bị cắt ở 60 giây do thời gian chờ mặc định không | Đặt `proxy_read_timeout` 300 giây cho hai đường dẫn SSE; nhịp `heartbeat` 15 giây |
| Q04-58 | Có cần API công khai cho đội HTTT xem trạng thái luồng mình dùng (chỉ đọc) không, hay để PH-02 cung cấp | Để PH-02 cung cấp qua trạng thái API công bố, PH-04 không mở thêm |
| Q04-59 | Giữ topic hệ thống 1 ngày có đủ cho phân tích sự cố lệnh khẩn | Đủ vì `runtime_command`, `command_ack` lưu ở CSDL; PH-13 giữ log |

: Câu hỏi mở của tập API PH-04

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py --vi-du`; sửa nguồn (`ph04/tools/gen_openapi.py`, `bo_sung.py`) rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục (mục đích, phương thức và đường dẫn, quyền, FR, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú), theo sau là ví dụ yêu cầu và ví dụ phản hồi dạng HTTP. Đường dẫn trong bảng tính từ gốc `/api/integration/v1`; ví dụ ghi đường đầy đủ.

Bản 0.1 dùng chung một mã API cho một số operation cùng tài nguyên (ví dụ API-04-054 cho sáu operation triển khai). Bản 0.2 giữ nguyên mã: mã đó nằm ở một tiêu đề, mỗi operation là một tiêu đề con theo phương thức và đường dẫn. Đề nghị tách mã ở chương 11. Mọi operation có thể trả 401 và mọi lệnh ghi có thể trả 403, như đã nói ở chương 3; câu hiển thị của từng mã lỗi ở chương 6.

<!-- gen:dac-ta-api:start -->

### Không gian làm việc

#### API-04-001 · Danh sách không gian làm việc

::: dac-ta
**Mục đích.** Danh sách không gian làm việc.

**Phương thức, đường dẫn.** `GET /workspaces`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-007.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WorkspaceList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Trả mọi không gian làm việc của tenant mà người gọi thấy được, kèm `myAccess` (mức của người gọi) và `flowCount`. Danh sách nhỏ nên trả trọn, không phân trang.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/workspaces
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a01", "code": "ho-tich", "name": "Hộ tịch",
   "ownerOrgCode": "STP-T68", "status": "ACTIVE", "flowCount": 12, "myAccess": "MAINTAIN",
   "allowedActions": ["update", "archive"]}]}
```

#### API-04-002 · Sửa không gian làm việc

::: dac-ta
**Mục đích.** Sửa không gian làm việc.

**Phương thức, đường dẫn.** `PATCH /workspaces/{workspaceCode}`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-007.

**Tham số.** `workspaceCode` (path, WorkspaceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WorkspaceUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Workspace`; trường bắt buộc: `id`, `code`, `name`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `412` ETag lệch (ERR-04-006); `428` Thiếu If-Match (ERR-04-007).

**Ghi chú.** Đổi tên, mô tả, đơn vị chủ quản. Mã không gian không đổi được. Không gian không tồn tại ERR-04-027.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/integration/v1/workspaces/ho-tich
If-Match: W/"3-3f9a1c2e"

{"name": "Hộ tịch và chứng thực"}
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a01", "code": "ho-tich",
 "name": "Hộ tịch và chứng thực", "ownerOrgCode": "STP-T68", "status": "ACTIVE",
 "flowCount": 12, "myAccess": "MAINTAIN", "allowedActions": ["update", "archive"]}
```

#### Tạo không gian làm việc (API-04-002, POST)

::: dac-ta
**Mục đích.** Tạo không gian làm việc.

**Phương thức, đường dẫn.** `POST /workspaces`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-007.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WorkspaceCreate`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Workspace`; trường bắt buộc: `id`, `code`, `name`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** Mã trùng trả ERR-04-028.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/workspaces
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"code": "dat-dai", "name": "Đất đai", "ownerOrgCode": "STNMT-T68"}
```

```http
HTTP/1.1 201 Created

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a02", "code": "dat-dai", "name": "Đất đai",
 "ownerOrgCode": "STNMT-T68", "status": "ACTIVE", "flowCount": 0, "myAccess": "MAINTAIN",
 "allowedActions": ["update", "archive"]}
```

#### API-04-003 · Lưu trữ không gian làm việc

::: dac-ta
**Mục đích.** Lưu trữ không gian làm việc.

**Phương thức, đường dẫn.** `POST /workspaces/{workspaceCode}:archive`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-007.

**Tham số.** `workspaceCode` (path, WorkspaceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Workspace`; trường bắt buộc: `id`, `code`, `name`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006).

**Ghi chú.** Không gian còn luồng chưa gỡ vẫn lưu trữ được (ẩn khỏi ô chọn khi tạo luồng). Xóa hẳn không có API; xóa khi còn luồng trả ERR-04-017.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/workspaces/ho-tich:archive
If-Match: W/"3-3f9a1c2e"
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a01", "code": "ho-tich", "name": "Hộ tịch",
 "ownerOrgCode": "STP-T68", "status": "ARCHIVED", "flowCount": 12, "myAccess": "MAINTAIN",
 "allowedActions": []}
```

#### API-04-004 · Danh sách thành viên

::: dac-ta
**Mục đích.** Danh sách thành viên.

**Phương thức, đường dẫn.** `GET /workspaces/{workspaceCode}/members`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-007.

**Tham số.** `workspaceCode` (path, WorkspaceCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WorkspaceMembers`; trường bắt buộc: `members`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả danh sách người dùng và nhóm cùng mức truy cập VIEW, EDIT, MAINTAIN (FR-04-007).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/workspaces/ho-tich/members
```

```http
HTTP/1.1 200 OK

{"members": [{"principalType": "USER", "principalId": "an.nv", "displayName": "Nguyễn Văn An",
   "accessLevel": "MAINTAIN"},
  {"principalType": "GROUP", "principalId": "tt-cntt-t68", "accessLevel": "EDIT"}]}
```

#### Thay danh sách thành viên (API-04-004, PUT)

::: dac-ta
**Mục đích.** Thay danh sách thành viên.

**Phương thức, đường dẫn.** `PUT /workspaces/{workspaceCode}/members`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-007.

**Tham số.** `workspaceCode` (path, WorkspaceCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WorkspaceMembers`; trường bắt buộc: `members`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WorkspaceMembers`; trường bắt buộc: `members`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `412` ETag lệch (ERR-04-006); `428` Thiếu If-Match (ERR-04-007).

**Ghi chú.** TA hoặc thành viên mức MAINTAIN. Kiểm toán ghi danh sách thêm, bớt.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/integration/v1/workspaces/ho-tich/members
If-Match: W/"3-3f9a1c2e"

{"members": [{"principalType": "USER", "principalId": "an.nv", "accessLevel": "MAINTAIN"},
  {"principalType": "USER", "principalId": "binh.tt", "accessLevel": "EDIT"}]}
```

```http
HTTP/1.1 200 OK

{"members": [{"principalType": "USER", "principalId": "an.nv", "accessLevel": "MAINTAIN"},
  {"principalType": "USER", "principalId": "binh.tt", "accessLevel": "EDIT"}]}
```

### Luồng

#### API-04-010 · Danh sách luồng

::: dac-ta
**Mục đích.** Danh sách luồng.

**Phương thức, đường dẫn.** `GET /flows`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-001.

**Tham số.** `q` (query, string, tùy chọn); `workspace` (query, array, tùy chọn); `status` (query, array, tùy chọn); `environment` (query, Environment, tùy chọn); `health` (query, array, tùy chọn); `resourceKind` (query, array, tùy chọn); `exposure` (query, Exposure, tùy chọn); `endpoint` (query, string, tùy chọn); `label` (query, array, tùy chọn); `sourceSystem` (query, array, tùy chọn); `targetSystem` (query, array, tùy chọn); `transport` (query, array, tùy chọn); `namespace` (query, string, tùy chọn); `hasOpenVersion` (query, boolean, tùy chọn); `pendingMyReview` (query, boolean, tùy chọn); `updatedFrom` (query, string, tùy chọn); `updatedTo` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026); `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Lọc theo phạm vi không gian làm việc ở SQL khi `04.workspace.enforce` bật. Kèm `facets` đếm theo trạng thái, môi trường.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows?status=ACTIVE&environment=PROD
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10", "code": "tra-cuu-ho-tich",
   "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
   "transport": "SYNC", "exposure": "EXTERNAL", "status": "ACTIVE",
   "sourceSystem": "DVC-T68", "targetSystems": ["NDXP"],
   "environments": [{"environment": "PROD", "versionNo": 2, "syncStatus": "SYNCED", "healthStatus": "HEALTHY"}],
   "allowedActions": ["update", "clone", "retire"]}],
 "page": {"next": "eyJrIjoyNX0", "hasMore": true}, "facets": {"status": {"ACTIVE": 18}}}
```

#### API-04-011 · Tạo luồng và phiên bản 1

::: dac-ta
**Mục đích.** Tạo luồng và phiên bản 1.

**Phương thức, đường dẫn.** `POST /flows`.

**Quyền.** `PERM-04-create`.

**FR hiện thực.** FR-04-003, FR-04-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FlowCreate`; trường bắt buộc: `code`, `name`, `workspaceCode`, `resourceKind`, `origin`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `FlowDetail`; trường bắt buộc: `id`, `code`, `name`, `status`, `resourceKind`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** Ghi luồng, phiên bản 1 `DRAFT`, chỉ mục, outbox EVT-04-01 trong một giao dịch. Mã trùng ERR-04-002; không gian không tồn tại ERR-04-027; khuôn không tồn tại ERR-04-039; YAML lỗi ERR-04-008; loại tài nguyên không khớp ERR-04-009; vượt kích thước ERR-04-033.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"code": "tra-cuu-ho-tich", "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich",
 "resourceKind": "ROUTE", "origin": "TEMPLATE", "templateCode": "tpl-rest-proxy",
 "templateParams": {"upstream": "ndxp-ho-tich"}, "sourceSystem": "DVC-T68",
 "targetSystems": ["NDXP"]}
```

```http
HTTP/1.1 201 Created
ETag: W/"3-3f9a1c2e"

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10", "code": "tra-cuu-ho-tich",
 "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
 "transport": "SYNC", "exposure": "EXTERNAL", "status": "DRAFT", "sourceSystem": "DVC-T68",
 "targetSystems": ["NDXP"], "environments": [], "allowedActions": ["update", "retire"],
 "origin": "TEMPLATE", "routes": [{"routeId": "tra-cuu", "stepCount": 9}],
 "openVersionNo": 1}
```

#### API-04-012 · Chi tiết luồng

::: dac-ta
**Mục đích.** Chi tiết luồng.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-002.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowDetail`; trường bắt buộc: `id`, `code`, `name`, `status`, `resourceKind`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả thông tin luồng, route, trạng thái theo môi trường và `allowedActions`. Luồng của tenant khác hoặc ngoài phạm vi không gian trả ERR-04-001 (404).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10", "code": "tra-cuu-ho-tich",
 "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
 "transport": "SYNC", "exposure": "EXTERNAL", "status": "ACTIVE",
 "sourceSystem": "DVC-T68", "targetSystems": ["NDXP"],
 "environments": [{"environment": "PROD", "versionNo": 2, "syncStatus": "SYNCED", "healthStatus": "HEALTHY"}],
 "allowedActions": ["update", "clone", "retire"], "origin": "TEMPLATE",
 "routes": [{"routeId": "tra-cuu", "stepCount": 9}]}
```

#### API-04-013 · Sửa thông tin luồng

::: dac-ta
**Mục đích.** Sửa thông tin luồng.

**Phương thức, đường dẫn.** `PATCH /flows/{flowCode}`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-004.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FlowUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowDetail`; trường bắt buộc: `id`, `code`, `name`, `status`, `resourceKind`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006); `428` Thiếu If-Match (ERR-04-007).

**Ghi chú.** Chuyển không gian cần mức EDIT ở cả hai nơi. Luồng đã gỡ ERR-04-034.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/integration/v1/flows/tra-cuu-ho-tich
If-Match: W/"3-3f9a1c2e"

{"labels": {"linh-vuc": "ho-tich"}}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10", "code": "tra-cuu-ho-tich",
 "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
 "transport": "SYNC", "exposure": "EXTERNAL", "status": "ACTIVE",
 "sourceSystem": "DVC-T68", "targetSystems": ["NDXP"],
 "environments": [{"environment": "PROD", "versionNo": 2, "syncStatus": "SYNCED", "healthStatus": "HEALTHY"}],
 "allowedActions": ["update", "clone", "retire"], "origin": "TEMPLATE",
 "routes": [{"routeId": "tra-cuu", "stepCount": 9}], "labels": {"linh-vuc": "ho-tich"}}
```

#### API-04-014 · Nhân bản luồng

::: dac-ta
**Mục đích.** Nhân bản luồng.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}:clone`.

**Quyền.** `PERM-04-create`.

**FR hiện thực.** FR-04-005.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CloneRequest`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `FlowDetail`; trường bắt buộc: `id`, `code`, `name`, `status`, `resourceKind`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** Tạo luồng mới với phiên bản 1 `DRAFT` sao từ phiên bản nguồn (mặc định mới nhất), kèm ca kiểm thử nếu chọn. Mã trùng ERR-04-002. Phát EVT-04-01 với `origin = CLONE`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich:clone
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"code": "tra-cuu-ho-tich-v2", "name": "Tra cứu hộ tịch (bản 2)", "sourceVersionNo": 2}
```

```http
HTTP/1.1 201 Created

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a11", "code": "tra-cuu-ho-tich-v2",
 "name": "Tra cứu hộ tịch (bản 2)", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
 "transport": "SYNC", "exposure": "EXTERNAL", "status": "DRAFT", "sourceSystem": "DVC-T68",
 "targetSystems": ["NDXP"], "environments": [],
 "allowedActions": ["update", "clone", "retire"], "origin": "CLONE",
 "routes": [{"routeId": "tra-cuu", "stepCount": 9}], "clonedFrom": "tra-cuu-ho-tich",
 "openVersionNo": 1}
```

#### API-04-015 · Gỡ luồng

::: dac-ta
**Mục đích.** Gỡ luồng.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}:retire`.

**Quyền.** `PERM-04-delete`.

**FR hiện thực.** FR-04-006.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RetireRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `FlowDetail`; trường bắt buộc: `id`, `code`, `name`, `status`, `resourceKind`; tiêu đề `Location`.

**Lỗi.** `400` Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026); `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006).

**Ghi chú.** Rút luồng khỏi các môi trường theo thứ tự PROD → TEST qua Git rồi chuyển RETIRED. Còn phụ thuộc cứng ERR-04-017 kèm `dependencies`; thiếu lý do ERR-04-025.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich:retire
If-Match: W/"3-3f9a1c2e"

{"reason": "Thay bằng luồng tra-cuu-ho-tich-v2 theo kế hoạch của Sở Tư pháp."}
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/deployments/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a55

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a10", "code": "tra-cuu-ho-tich",
 "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
 "transport": "SYNC", "exposure": "EXTERNAL", "status": "ACTIVE",
 "sourceSystem": "DVC-T68", "targetSystems": ["NDXP"],
 "environments": [{"environment": "PROD", "versionNo": 2, "syncStatus": "SYNCED", "healthStatus": "HEALTHY"}],
 "allowedActions": [], "origin": "TEMPLATE",
 "routes": [{"routeId": "tra-cuu", "stepCount": 9}],
 "disabledReasons": {"update": "Luồng đang được gỡ."}}
```

#### API-04-016 · Phụ thuộc của luồng

::: dac-ta
**Mục đích.** Phụ thuộc của luồng.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/dependencies`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-006, FR-04-002.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dependencies`; trường bắt buộc: `hard`, `soft`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Liệt kê phụ thuộc cứng (API công bố PH-02, luồng gọi luồng con) và mềm (ca kiểm thử, bản nháp, topic, kết nối). Phụ thuộc cứng chặn gỡ (ERR-04-017).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/dependencies
```

```http
HTTP/1.1 200 OK

{"hard": [{"type": "API", "hard": true, "ref": "api-ho-tich-tra-cuu", "label": "API tra cứu hộ tịch",
   "environment": "PROD"}],
 "soft": [{"type": "TEST_CASE", "hard": false, "ref": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a44",
   "label": "Tra cứu thành công"}]}
```

### Phiên bản

#### API-04-020 · Lấy phiên bản (định nghĩa, bố cục, bản tin mẫu)

::: dac-ta
**Mục đích.** Lấy phiên bản (định nghĩa, bố cục, bản tin mẫu).

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/versions/{versionNo}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-010.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; trường bắt buộc: `versionNo`, `status`, `definitionYaml`, `canvasLayout`, `samples`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả ETag để lưu nháp. ERR-04-004 khi phiên bản không tồn tại.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/versions/3
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"versionNo": 3, "status": "DRAFT",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "createdBy": "an.nv",
 "definitionYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "canvasLayout": {}, "samples": {}, "allowedActions": ["saveDraft", "submit"]}
```

#### API-04-021 · Tạo phiên bản mới từ phiên bản có sẵn

::: dac-ta
**Mục đích.** Tạo phiên bản mới từ phiên bản có sẵn.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-011.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NewVersionRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `VersionDetail`; trường bắt buộc: `versionNo`, `status`, `definitionYaml`, `canvasLayout`, `samples`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** Sao chép định nghĩa, bố cục, bản tin mẫu, ánh xạ. Đã có phiên bản mở ERR-04-016.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"baseVersionNo": 2}
```

```http
HTTP/1.1 201 Created
ETag: W/"3-3f9a1c2e"

{"versionNo": 3, "status": "DRAFT",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "createdBy": "an.nv",
 "definitionYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "canvasLayout": {}, "samples": {}, "allowedActions": ["saveDraft", "submit"]}
```

#### API-04-022 · Lưu nháp

::: dac-ta
**Mục đích.** Lưu nháp.

**Phương thức, đường dẫn.** `PUT /flows/{flowCode}/versions/{versionNo}/draft`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-024, FR-04-010, FR-04-022.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DraftUpdate`; trường bắt buộc: `definitionYaml`, `canvasLayout`, `samples`, `catalogVersion`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DraftSaved`; trường bắt buộc: `versionNo`, `contentHash`, `validation`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `423` Đóng băng thay đổi (ERR-04-041); `428` Thiếu If-Match (ERR-04-007).

**Ghi chú.** Chỉ ở DRAFT, CHANGES_REQUESTED (ERR-04-005). Chạy kiểm tra mức DESIGN (không chặn lưu) trừ VR-01 cú pháp (ERR-04-008) và VR-03 bí mật (ERR-04-010). Thêm người gọi vào danh sách người đóng góp. ERR-04-041 chỉ khi tỉnh đóng băng cả việc soạn.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/integration/v1/flows/tra-cuu-ho-tich/versions/3/draft
If-Match: W/"3-3f9a1c2e"

{"definitionYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "canvasLayout": {"n1": {"x": 120, "y": 80}}, "samples": {},
 "catalogVersion": "camel-quarkus-3.33.2"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"versionNo": 3,
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "savedAt": "2026-11-26T09:03:00+07:00",
 "validation": {"level": "DESIGN", "errorCount": 0, "warnCount": 1,
  "findings": [{"rule": "VR-12", "severity": "WARN", "nodeId": "n7",
    "message": "Chặng gọi hệ đích chưa đặt thời gian chờ; mặc định 30 giây."}]}}
```

#### API-04-023 · Hủy bản nháp

::: dac-ta
**Mục đích.** Hủy bản nháp.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}:discard`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-006.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionSummary`; trường bắt buộc: `versionNo`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006).

**Ghi chú.** Hủy phiên bản đang `DRAFT` hoặc `CHANGES_REQUESTED`; phiên bản chuyển `DISCARDED`, giải phóng chỗ cho phiên bản mở mới (BR-04-016). Trạng thái khác ERR-04-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3:discard
If-Match: W/"3-3f9a1c2e"
```

```http
HTTP/1.1 200 OK

{"versionNo": 3, "status": "DISCARDED",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "createdBy": "an.nv"}
```

#### API-04-024 · Danh sách phiên bản

::: dac-ta
**Mục đích.** Danh sách phiên bản.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/versions`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-011.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả mọi phiên bản của luồng, mới nhất trước, kèm môi trường đang chạy từng phiên bản. Không phân trang vì số phiên bản có giới hạn tự nhiên.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/versions
```

```http
HTTP/1.1 200 OK

{"items": [{"versionNo": 3, "status": "DRAFT",
   "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
   "createdBy": "an.nv"}, {"versionNo": 2, "status": "APPROVED",
   "contentHash": "sha256:8b04d7e18b04d7e18b04d7e18b04d7e18b04d7e18b04d7e18b04d7e18b04d7e1",
   "approvedBy": "binh.tt", "environments": ["TEST", "STAGING", "PROD"]}]}
```

#### API-04-025 · So sánh với phiên bản khác

::: dac-ta
**Mục đích.** So sánh với phiên bản khác.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/versions/{versionNo}/diff`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-043.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `base` (query, integer, tùy chọn); `markViewed` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiffResult`; trường bắt buộc: `nodes`, `summary`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** So sánh theo chặng (`nodes`) và theo dòng YAML (`yamlUnifiedDiff`) với phiên bản gốc. Người duyệt gọi với `markViewed = true` để thỏa điều kiện đã xem khác biệt trước khi duyệt.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/versions/3/diff?base=2&markViewed=true
```

```http
HTTP/1.1 200 OK

{"baseVersionNo": 2, "versionNo": 3, "nodes": [{"nodeId": "n5", "change": "ADDED"},
  {"nodeId": "n7", "change": "MODIFIED", "fields": ["parameters.timeout"]}],
 "summary": {"added": 1, "removed": 0, "modified": 1}}
```

#### API-04-026 · Tải định nghĩa

::: dac-ta
**Mục đích.** Tải định nghĩa.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/versions/{versionNo}/download`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-027.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `format` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Tải YAML triển khai (`yaml`), YAML kèm bố cục (`yaml+layout`) hoặc gói ZIP gồm YAML, ánh xạ, ca kiểm thử (`bundle`). Không bao giờ chứa giá trị bí mật.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/versions/3/download?format=yaml
```

```http
HTTP/1.1 200 OK
Content-Type: application/yaml

- route:
    id: tra-cuu
    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}
```

#### API-04-027 · Nhập YAML thay định nghĩa

::: dac-ta
**Mục đích.** Nhập YAML thay định nghĩa.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}:import-yaml`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-027.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ImportYamlRequest`; trường bắt buộc: `yaml`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DraftSaved`; trường bắt buộc: `versionNo`, `contentHash`, `validation`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** Thay định nghĩa của bản nháp bằng YAML tải lên; giữ bố cục cho chặng có `id` trùng khi `keepLayout`. Cú pháp lỗi ERR-04-008, bí mật ERR-04-010, vượt 512 KiB ERR-04-033.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3:import-yaml
If-Match: W/"3-3f9a1c2e"

{"yaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "keepLayout": true}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"versionNo": 3,
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "savedAt": "2026-11-26T09:03:00+07:00",
 "validation": {"level": "DESIGN", "errorCount": 0, "warnCount": 1,
  "findings": [{"rule": "VR-12", "severity": "WARN", "nodeId": "n7",
    "message": "Chặng gọi hệ đích chưa đặt thời gian chờ; mặc định 30 giây."}]}}
```

#### API-04-034 · Kết thúc phiên soạn

::: dac-ta
**Mục đích.** Kết thúc phiên soạn.

**Phương thức, đường dẫn.** `DELETE /flows/{flowCode}/versions/{versionNo}/session`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-024.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Rời trình thiết kế: xóa người gọi khỏi danh sách phiên soạn để người khác không còn thấy cảnh báo.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
DELETE /api/integration/v1/flows/tra-cuu-ho-tich/versions/3/session
```

```http
HTTP/1.1 204 No Content
```

#### Nhịp phiên soạn (API-04-034, PUT)

::: dac-ta
**Mục đích.** Nhịp phiên soạn.

**Phương thức, đường dẫn.** `PUT /flows/{flowCode}/versions/{versionNo}/session`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-024.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SessionState`; trường bắt buộc: `others`, `catalogVersion`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Gọi mỗi 30 giây khi tab đang hiện; hết hạn sau 120 giây. Không khóa; chỉ thông tin người khác đang mở và catalogVersion hiện hành.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/integration/v1/flows/tra-cuu-ho-tich/versions/3/session
```

```http
HTTP/1.1 200 OK

{"others": [{"userId": "binh.tt", "displayName": "Trần Thị Bình", "since": "2026-11-26T09:00:00+07:00"}],
 "catalogVersion": "camel-quarkus-3.33.2", "expiresInSeconds": 120,
 "freeze": {"active": false}}
```

### Di trú

#### API-04-028 · Kết quả chuyển đổi

::: dac-ta
**Mục đích.** Kết quả chuyển đổi.

**Phương thức, đường dẫn.** `GET /legacy-imports/{jobId}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-082.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `id`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả trạng thái tác vụ chuyển XML cũ và báo cáo: số route, số chặng chuyển được, chặng cần làm tay, thành phần bị cấm, kết nối cần khai ở PH-05, luồng đã tạo.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/legacy-imports/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a28
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a28", "status": "COMPLETED",
 "fileName": "context-hotich.xml",
 "report": {"routes": 3, "stepsConverted": 41, "stepsManual": 2, "forbiddenComponents": ["exec"],
  "connectionsToDeclare": ["pg-ho-tich"]}, "createdFlows": ["ht-dong-bo-khai-sinh"]}
```

#### Chuyển Camel XML của Bus cũ (API-04-028, POST)

::: dac-ta
**Mục đích.** Chuyển Camel XML của Bus cũ.

**Phương thức, đường dẫn.** `POST /legacy-imports`.

**Quyền.** `PERM-04-create`.

**FR hiện thực.** FR-04-082.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: object.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `LegacyImportJob`; trường bắt buộc: `id`, `status`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `415` Kiểu nội dung không hỗ trợ (ERR-04-046); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** multipart/form-data: `file` (≤ 2 MiB, XML hoặc ZIP gói xuất Context), `workspaceCode`, `connectionMap` (JSON). Tệp không hợp lệ ERR-04-032.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/legacy-imports
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10
Content-Type: multipart/form-data; boundary=ranh-gioi

--ranh-gioi
Content-Disposition: form-data; name="file"

(nội dung tệp context-hotich.xml)
--ranh-gioi
Content-Disposition: form-data; name="workspaceCode"

ho-tich
--ranh-gioi
Content-Disposition: form-data; name="connectionMap"

{"dsHoTich": "pg-ho-tich"}
--ranh-gioi--
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/legacy-imports/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a28

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a28", "status": "RUNNING",
 "fileName": "context-hotich.xml"}
```

### Kiểm tra hợp lệ

#### API-04-030 · Kiểm tra hợp lệ phiên bản

::: dac-ta
**Mục đích.** Kiểm tra hợp lệ phiên bản.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}:validate`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-023.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc).

**Thân yêu cầu.** application/json: `ValidateRequest`; trường bắt buộc: `level`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValidationResult`; trường bắt buộc: `level`, `findings`, `errorCount`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Chạy kiểm tra hợp lệ ở mức yêu cầu (`DESIGN`, `SUBMIT`, `PUBLISH`) trên phiên bản đã lưu và ghi kết quả vào `lastValidation`. Không đổi trạng thái phiên bản.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3:validate

{"level": "SUBMIT", "targetEnvironment": "PROD"}
```

```http
HTTP/1.1 200 OK

{"level": "SUBMIT", "errorCount": 1, "warnCount": 0,
 "findings": [{"rule": "VR-05", "severity": "ERROR", "nodeId": "n6",
   "message": "Luồng đối ngoại thiếu chặng chuẩn: audit."}]}
```

#### API-04-031 · Kiểm tra YAML chưa lưu

::: dac-ta
**Mục đích.** Kiểm tra YAML chưa lưu.

**Phương thức, đường dẫn.** `POST /validation:check`.

**Quyền.** `PERM-04-create`.

**FR hiện thực.** FR-04-023, FR-04-003.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `StatelessValidateRequest`; trường bắt buộc: `yaml`, `resourceKind`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValidationResult`; trường bắt buộc: `level`, `findings`, `errorCount`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021).

**Ghi chú.** Dùng ở UI-04-03 bước 3 và khi nhập YAML; không ghi gì.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/validation:check

{"yaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "resourceKind": "ROUTE", "exposure": "EXTERNAL"}
```

```http
HTTP/1.1 200 OK

{"level": "DESIGN", "errorCount": 0, "warnCount": 1,
 "findings": [{"rule": "VR-12", "severity": "WARN", "nodeId": "n7",
   "message": "Chặng gọi hệ đích chưa đặt thời gian chờ; mặc định 30 giây."}]}
```

#### API-04-032 · Biên dịch, xem trước biểu thức

::: dac-ta
**Mục đích.** Biên dịch, xem trước biểu thức.

**Phương thức, đường dẫn.** `POST /expressions:check`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-015.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ExpressionCheckRequest`; trường bắt buộc: `language`, `expression`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExpressionCheckResult`; trường bắt buộc: `valid`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `503` Phụ thuộc chưa sẵn sàng (ERR-04-047; sandbox ERR-04-019).

**Ghi chú.** Biên dịch bằng engine Camel đúng phiên bản; `evaluate = true` chạy trên sandbox. Lỗi biên dịch trả 200 với `valid = false` (giao diện tô vị trí); ERR-04-037 chỉ khi gọi ở chế độ chặt. Sandbox không sẵn sàng ERR-04-019 (503).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/expressions:check

{"language": "simple", "expression": "${header.dh-tenant} == 'T68'", "predicate": true,
 "evaluate": true, "sample": {"headers": {"dh-tenant": "T68"}}}
```

```http
HTTP/1.1 200 OK

{"valid": true, "result": true, "resultType": "java.lang.Boolean", "simulated": false}
```

#### API-04-033 · Xem trước ánh xạ (JQ) trên bản tin mẫu

::: dac-ta
**Mục đích.** Xem trước ánh xạ (JQ) trên bản tin mẫu.

**Phương thức, đường dẫn.** `POST /mappings:preview`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-020.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `MappingPreviewRequest`; trường bắt buộc: `mapping`, `sample`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MappingPreviewResult`; trường bắt buộc: `jq`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `503` Phụ thuộc chưa sẵn sàng (ERR-04-047; sandbox ERR-04-019).

**Ghi chú.** Sinh JQ từ dhmap ở máy chủ, chạy trên sandbox có hàm dh_map. ERR-04-038 khi ánh xạ không hợp lệ; tài liệu mẫu ≤ 1 MiB (ERR-04-021).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/mappings:preview

{"mapping": {"name": "ket-qua-tra-cuu",
  "dhmap": {"format": "dhmap/1", "fields": [{"to": "hoTen", "from": "$.fullName"}]}},
 "sample": {"body": "{\"fullName\": \"Nguyễn Văn A\"}"}}
```

```http
HTTP/1.1 200 OK

{"jq": "{hoTen: .fullName}", "output": {"hoTen": "Nguyễn Văn A"}, "targetValid": true,
 "findings": [], "simulated": false}
```

### Chạy thử

#### API-04-040 · Bắt đầu chạy thử

::: dac-ta
**Mục đích.** Bắt đầu chạy thử.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}/test-runs`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-030, FR-04-032.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TestRunRequest`; trường bắt buộc: `mode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `TestRun`; trường bắt buộc: `id`, `status`, `mode`, `definitionHash`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `429` Vượt tần suất (ERR-04-048) hoặc hạn mức chạy thử (ERR-04-019); `503` Phụ thuộc chưa sẵn sàng (ERR-04-047; sandbox ERR-04-019).

**Ghi chú.** Kiểm tra mức DESIGN (ERR-04-009). Hạn mức `04.test.max-concurrent` (ERR-04-019, 429). SANDBOX_LIVE cần kết nối có giá trị TEST (ERR-04-013). Trả `Location` tới API-04-042.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3/test-runs
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"mode": "MOCK", "body": "{\"soDinhDanh\": \"068000000001\"}", "timeoutSeconds": 30,
 "assertions": [{"kind": "STATUS", "expected": 200}]}
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/test-runs/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "versionNo": 3,
 "definitionHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "mode": "MOCK", "status": "QUEUED", "matchesCurrentHash": true,
 "allowedActions": ["cancel"]}
```

#### API-04-041 · Lịch sử chạy thử

::: dac-ta
**Mục đích.** Lịch sử chạy thử.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/test-runs`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-030.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (query, integer, tùy chọn); `status` (query, array, tùy chọn); `testCaseId` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TestRunPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Lịch sử chạy thử của luồng, lọc theo phiên bản, trạng thái, ca kiểm thử; mỗi lần chạy có `matchesCurrentHash` để biết còn dùng được cho BR-04-004 không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/test-runs?versionNo=3
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "versionNo": 3,
   "definitionHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
   "mode": "MOCK", "status": "PASSED", "durationMs": 412, "matchesCurrentHash": true,
   "allowedActions": ["rerun"]}], "page": {"next": null, "hasMore": false}}
```

#### API-04-042 · Kết quả lần chạy thử

::: dac-ta
**Mục đích.** Kết quả lần chạy thử.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/test-runs/{runId}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-030.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TestRun`; trường bắt buộc: `id`, `status`, `mode`, `definitionHash`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả kết quả lần chạy: trạng thái, khẳng định, danh sách chặng (thân đã che, xem trước ≤ 64 KiB). Dùng để hỏi lại khi SSE mất kết nối.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/test-runs/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "versionNo": 3,
 "definitionHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "mode": "MOCK", "status": "PASSED", "durationMs": 412, "matchesCurrentHash": true,
 "allowedActions": ["rerun"],
 "steps": [{"seqNo": 4, "nodeId": "n4", "routeId": "tra-cuu", "stage": "transform", "status": "OK",
   "offsetMs": 96, "durationMs": 12}]}
```

#### Luồng sự kiện lần chạy thử (SSE) (API-04-042, GET)

::: dac-ta
**Mục đích.** Luồng sự kiện lần chạy thử (SSE).

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/test-runs/{runId}/events`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-030.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Sự kiện `status` (TestRun rút gọn), `step` (TestRunStep), `completed` (TestRun đầy đủ), `heartbeat` mỗi 15 giây. Đóng sau `completed`. Mất kết nối thì client hỏi API-04-042 mỗi 2 giây.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/test-runs/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41/events
Accept: text/event-stream
```

```http
HTTP/1.1 200 OK
Content-Type: text/event-stream

event: status
data: {"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "status": "RUNNING"}

event: step
data: {"seqNo": 4, "nodeId": "n4", "status": "OK", "durationMs": 12}

event: completed
data: {"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "status": "PASSED", "durationMs": 412}
```

#### Thân bản tin đầy đủ của một chặng (API-04-042, GET)

::: dac-ta
**Mục đích.** Thân bản tin đầy đủ của một chặng.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/test-runs/{runId}/steps/{seqNo}/body`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-030.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `runId` (path, string, bắt buộc); `seqNo` (path, integer, bắt buộc); `side` (query, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Chỉ khi lần chạy bật captureBodies và chưa quá 04.test.body-retention-days; trả 404 khi đã xóa. Nội dung đã che theo BR-04-013.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/test-runs/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41/steps/4/body?side=out
```

```http
HTTP/1.1 200 OK

{"hoTen": "Nguyễn Văn A", "soDinhDanh": "068******001"}
```

#### API-04-043 · Hủy lần chạy thử

::: dac-ta
**Mục đích.** Hủy lần chạy thử.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/test-runs/{runId}:cancel`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-030.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `runId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TestRun`; trường bắt buộc: `id`, `status`, `mode`, `definitionHash`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** Hủy lần chạy đang `QUEUED` hoặc `RUNNING`; sandbox đóng `CamelContext` của lần chạy. Lần chạy đã kết thúc ERR-04-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/test-runs/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41:cancel
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "versionNo": 3,
 "definitionHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "mode": "MOCK", "status": "CANCELLED", "durationMs": 412, "matchesCurrentHash": true,
 "allowedActions": ["rerun"]}
```

#### API-04-044 · Xóa (ngừng dùng) ca kiểm thử

::: dac-ta
**Mục đích.** Xóa (ngừng dùng) ca kiểm thử.

**Phương thức, đường dẫn.** `DELETE /flows/{flowCode}/test-cases/{caseId}`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-031.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `caseId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `412` ETag lệch (ERR-04-006).

**Ghi chú.** Ngừng dùng ca kiểm thử (`active = false`); lịch sử lần chạy theo ca vẫn giữ.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
DELETE /api/integration/v1/flows/tra-cuu-ho-tich/test-cases/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a44
If-Match: W/"3-3f9a1c2e"
```

```http
HTTP/1.1 204 No Content
```

#### Danh sách ca kiểm thử (API-04-044, GET)

::: dac-ta
**Mục đích.** Danh sách ca kiểm thử.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/test-cases`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-031.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TestCaseList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Danh sách ca kiểm thử của luồng kèm kết quả lần chạy gần nhất và cờ `onCurrentHash`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/test-cases
```

```http
HTTP/1.1 200 OK

{"items": [{"name": "Tra cứu thành công", "mode": "MOCK",
   "body": "{\"soDinhDanh\": \"068000000001\"}",
   "assertions": [{"kind": "STATUS", "expected": 200}, {"kind": "STEP_VISITED", "nodeId": "n7"}],
   "timeoutSeconds": 30, "active": true, "id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a44",
   "lastResult": {"status": "PASSED", "runId": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a41", "onCurrentHash": true}}]}
```

#### Tạo ca kiểm thử (API-04-044, POST)

::: dac-ta
**Mục đích.** Tạo ca kiểm thử.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/test-cases`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-031.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TestCase`; trường bắt buộc: `name`, `mode`, `assertions`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TestCase`; trường bắt buộc: `name`, `mode`, `assertions`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `413` Thân quá lớn (ERR-04-033; bản tin ERR-04-021); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** Tạo ca kiểm thử (1…20 khẳng định, thân ≤ 256 KiB). Ca mới làm điều kiện gửi duyệt cần thêm một lần chạy đạt của ca này (BR-04-004).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/test-cases
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"name": "Tra cứu thành công", "mode": "MOCK",
 "body": "{\"soDinhDanh\": \"068000000001\"}",
 "assertions": [{"kind": "STATUS", "expected": 200}, {"kind": "STEP_VISITED", "nodeId": "n7"}],
 "timeoutSeconds": 30, "active": true}
```

```http
HTTP/1.1 201 Created
ETag: W/"3-3f9a1c2e"

{"name": "Tra cứu thành công", "mode": "MOCK",
 "body": "{\"soDinhDanh\": \"068000000001\"}",
 "assertions": [{"kind": "STATUS", "expected": 200}, {"kind": "STEP_VISITED", "nodeId": "n7"}],
 "timeoutSeconds": 30, "active": true, "id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a44"}
```

#### Sửa ca kiểm thử (API-04-044, PUT)

::: dac-ta
**Mục đích.** Sửa ca kiểm thử.

**Phương thức, đường dẫn.** `PUT /flows/{flowCode}/test-cases/{caseId}`.

**Quyền.** `PERM-04-update`.

**FR hiện thực.** FR-04-031.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `caseId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TestCase`; trường bắt buộc: `name`, `mode`, `assertions`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TestCase`; trường bắt buộc: `name`, `mode`, `assertions`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `412` ETag lệch (ERR-04-006); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** Sửa ca kiểm thử; kết quả cũ của ca không còn tính cho BR-04-004 cho tới khi chạy lại.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/integration/v1/flows/tra-cuu-ho-tich/test-cases/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a44
If-Match: W/"3-3f9a1c2e"

{"name": "Tra cứu thành công", "mode": "MOCK",
 "body": "{\"soDinhDanh\": \"068000000001\"}",
 "assertions": [{"kind": "STATUS", "expected": 200}, {"kind": "STEP_VISITED", "nodeId": "n7"}],
 "timeoutSeconds": 20, "active": true}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"name": "Tra cứu thành công", "mode": "MOCK",
 "body": "{\"soDinhDanh\": \"068000000001\"}",
 "assertions": [{"kind": "STATUS", "expected": 200}, {"kind": "STEP_VISITED", "nodeId": "n7"}],
 "timeoutSeconds": 20, "active": true, "id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a44"}
```

### Duyệt

#### API-04-050 · Gửi duyệt

::: dac-ta
**Mục đích.** Gửi duyệt.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}:submit`.

**Quyền.** `PERM-04-submit`.

**FR hiện thực.** FR-04-040.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubmitRequest`; trường bắt buộc: `changeNote`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; trường bắt buộc: `versionNo`, `status`, `definitionYaml`, `canvasLayout`, `samples`; tiêu đề `ETag`.

**Lỗi.** `400` Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026); `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `428` Thiếu If-Match (ERR-04-007).

**Ghi chú.** Kiểm tra mức SUBMIT (ERR-04-009), lần chạy thử đạt trên đúng băm và mọi ca đạt (ERR-04-014), catalog hiện hành (ERR-04-042), ghi chú (ERR-04-025). Phát EVT-04-03.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3:submit
If-Match: W/"3-3f9a1c2e"

{"changeNote": "Thêm chặng che số định danh theo yêu cầu ATTT.",
 "suggestedReviewers": ["binh.tt"]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"versionNo": 3, "status": "PENDING_REVIEW",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "createdBy": "an.nv",
 "definitionYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "canvasLayout": {}, "samples": {}, "allowedActions": ["withdraw"], "submittedBy": "an.nv",
 "submittedAt": "2026-11-26T09:30:00+07:00"}
```

#### API-04-051 · Rút lại yêu cầu duyệt

::: dac-ta
**Mục đích.** Rút lại yêu cầu duyệt.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}:withdraw`.

**Quyền.** `PERM-04-submit`.

**FR hiện thực.** FR-04-040.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WithdrawRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; trường bắt buộc: `versionNo`, `status`, `definitionYaml`, `canvasLayout`, `samples`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006).

**Ghi chú.** Người gửi rút yêu cầu duyệt khi chưa có quyết định; phiên bản về `DRAFT`. Thiếu lý do ERR-04-025.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3:withdraw
If-Match: W/"3-3f9a1c2e"

{"reason": "Cần bổ sung ca kiểm thử lỗi hệ đích."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"versionNo": 3, "status": "DRAFT",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "createdBy": "an.nv",
 "definitionYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "canvasLayout": {}, "samples": {}, "allowedActions": ["saveDraft", "submit"]}
```

#### API-04-052 · Quyết định duyệt

::: dac-ta
**Mục đích.** Quyết định duyệt.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/versions/{versionNo}:review`.

**Quyền.** `PERM-04-publish`.

**FR hiện thực.** FR-04-041, FR-04-043.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `versionNo` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReviewDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionDetail`; trường bắt buộc: `versionNo`, `status`, `definitionYaml`, `canvasLayout`, `samples`; tiêu đề `ETag`.

**Lỗi.** `400` Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026); `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `412` ETag lệch (ERR-04-006).

**Ghi chú.** Bốn mắt (ERR-04-015, 403); thiếu ý kiến hoặc checklist ERR-04-025. Khi `04.review.require-reauth` bật cần token có `auth_time` ≤ 5 phút (acr theo PH-12), nếu không trả 401 kèm `WWW-Authenticate: ... max_age=300`. Phát EVT-04-04 hoặc EVT-04-05.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/versions/3:review
If-Match: W/"3-3f9a1c2e"

{"decision": "APPROVE", "comment": "Đã xem khác biệt, che dữ liệu đúng.",
 "checklist": {"diff-viewed": true, "pii-purpose": true}, "publishTo": "TEST"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3-3f9a1c2e"

{"versionNo": 3, "status": "APPROVED",
 "contentHash": "sha256:3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e3f9a1c2e",
 "createdBy": "an.nv",
 "definitionYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "canvasLayout": {}, "samples": {}, "allowedActions": ["release"], "approvedBy": "binh.tt",
 "approvedAt": "2026-11-26T10:00:00+07:00"}
```

#### API-04-053 · Hàng đợi duyệt

::: dac-ta
**Mục đích.** Hàng đợi duyệt.

**Phương thức, đường dẫn.** `GET /reviews`.

**Quyền.** `PERM-04-publish`.

**FR hiện thực.** FR-04-041.

**Tham số.** `workspace` (query, array, tùy chọn); `overdue` (query, boolean, tùy chọn); `mine` (query, boolean, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReviewQueue`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Hàng đợi phiên bản `PENDING_REVIEW` mà người gọi được duyệt, kèm số giờ chờ, cờ quá hạn và `canDecide` (sai khi người gọi là người tạo, đóng góp hoặc gửi).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/reviews?mine=true
```

```http
HTTP/1.1 200 OK

{"items": [{"flowCode": "tra-cuu-ho-tich", "flowName": "Tra cứu hộ tịch qua NDXP",
   "workspaceCode": "ho-tich", "versionNo": 3, "submittedBy": "an.nv",
   "submittedAt": "2026-11-26T09:30:00+07:00", "waitingHours": 2.5, "overdue": false,
   "exposure": "EXTERNAL", "canDecide": true}], "page": {"next": null, "hasMore": false}}
```

### Triển khai

#### API-04-054 · Lịch sử triển khai

::: dac-ta
**Mục đích.** Lịch sử triển khai.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/deployments`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-042.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `environment` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DeploymentList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Lịch sử triển khai của luồng theo môi trường, mới nhất trước; bản ghi `current = true` là triển khai đang có hiệu lực.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/deployments?environment=PROD
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a53", "versionNo": 2, "environment": "PROD",
   "kind": "RELEASE", "desiredState": "RUNNING", "syncStatus": "SYNCED",
   "requestedBy": "binh.tt", "requestedAt": "2026-11-26T10:00:00+07:00",
   "allowedActions": [], "healthStatus": "HEALTHY", "current": true}]}
```

#### Chi tiết triển khai (API-04-054, GET)

::: dac-ta
**Mục đích.** Chi tiết triển khai.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/deployments/{deploymentId}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-042.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `deploymentId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Deployment`; trường bắt buộc: `id`, `versionNo`, `environment`, `syncStatus`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả trạng thái đồng bộ, sức khỏe, commit Git và mã lỗi (nếu có) của một lần triển khai. Dùng để hỏi lại khi SSE mất kết nối.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/deployments/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54", "versionNo": 3, "environment": "TEST",
 "kind": "RELEASE", "desiredState": "RUNNING", "syncStatus": "SYNCED",
 "requestedBy": "binh.tt", "requestedAt": "2026-11-26T10:00:00+07:00",
 "allowedActions": [], "healthStatus": "HEALTHY", "gitCommit": "9c1e4b7",
 "syncedAt": "2026-11-26T10:03:00+07:00", "current": true}
```

#### Tiến trình triển khai (SSE) (API-04-054, GET)

::: dac-ta
**Mục đích.** Tiến trình triển khai (SSE).

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/deployments/{deploymentId}/events`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-042.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `deploymentId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Sự kiện `status` (Deployment), `replica` (bản sao báo phiên bản), `completed`. Đóng khi SYNCED, FAILED hoặc sau 04.deploy.timeout-minutes.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/deployments/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54/events
Accept: text/event-stream
```

```http
HTTP/1.1 200 OK
Content-Type: text/event-stream

event: status
data: {"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54", "syncStatus": "SYNCING"}

event: replica
data: {"replica": "dh-rt-t68-core-7c9d-x2k4p", "contentHash": "sha256:3f9a1c2e…"}

event: completed
data: {"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54", "syncStatus": "SYNCED"}
```

#### Phát hành phiên bản lên môi trường (API-04-054, POST)

::: dac-ta
**Mục đích.** Phát hành phiên bản lên môi trường.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/deployments`.

**Quyền.** `PERM-04-publish`.

**FR hiện thực.** FR-04-042, FR-04-075.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReleaseRequest`; trường bắt buộc: `versionNo`, `environment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Deployment`; trường bắt buộc: `id`, `versionNo`, `environment`, `syncStatus`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `423` Đóng băng thay đổi (ERR-04-041); `502` Không ghi được kho cấu hình (ERR-04-022).

**Ghi chú.** Chỉ APPROVED (BR-04-012). Kiểm tra mức PUBLISH (ERR-04-009), thứ tự môi trường (ERR-04-023), đóng băng với PROD (ERR-04-041), hồ sơ runtime (ERR-04-029). Ghi Git sau giao dịch; lỗi ghi Git thành triển khai FAILED ERR-04-022. Phát EVT-04-06.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/deployments
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"versionNo": 3, "environment": "TEST", "note": "Phát hành thử nghiệm chặng che dữ liệu."}
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/deployments/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a54", "versionNo": 3, "environment": "TEST",
 "kind": "RELEASE", "desiredState": "RUNNING", "syncStatus": "PENDING",
 "requestedBy": "binh.tt", "requestedAt": "2026-11-26T10:00:00+07:00", "allowedActions": []}
```

#### API-04-055 · Quay lui về phiên bản đã duyệt trước

::: dac-ta
**Mục đích.** Quay lui về phiên bản đã duyệt trước.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/deployments:rollback`.

**Quyền.** `PERM-04-publish`.

**FR hiện thực.** FR-04-044.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RollbackRequest`; trường bắt buộc: `environment`, `targetVersionNo`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Deployment`; trường bắt buộc: `id`, `versionNo`, `environment`, `syncStatus`; tiêu đề `Location`.

**Lỗi.** `400` Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026); `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `502` Không ghi được kho cấu hình (ERR-04-022).

**Ghi chú.** Không cần duyệt lại; vẫn kiểm tra mức PUBLISH. Được phép khi đóng băng. Thành phần nay bị cấm ERR-04-040.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/deployments:rollback
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"environment": "PROD", "targetVersionNo": 2,
 "reason": "Phiên bản 3 tăng lỗi 504 khi gọi NDXP."}
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/deployments/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a56

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a56", "versionNo": 2, "environment": "PROD",
 "kind": "ROLLBACK", "desiredState": "RUNNING", "syncStatus": "PENDING",
 "requestedBy": "binh.tt", "requestedAt": "2026-11-26T10:00:00+07:00", "allowedActions": []}
```

#### API-04-056 · Nâng phiên bản lên môi trường kế tiếp

::: dac-ta
**Mục đích.** Nâng phiên bản lên môi trường kế tiếp.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/deployments:promote`.

**Quyền.** `PERM-04-promote`.

**FR hiện thực.** FR-04-045.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PromoteRequest`; trường bắt buộc: `versionNo`, `toEnvironment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Deployment`; trường bắt buộc: `id`, `versionNo`, `environment`, `syncStatus`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009); `423` Đóng băng thay đổi (ERR-04-041); `502` Không ghi được kho cấu hình (ERR-04-022).

**Ghi chú.** Môi trường trước phải SYNCED, HEALTHY và đủ thời gian ổn định (ERR-04-023).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/deployments:promote
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"versionNo": 3, "fromEnvironment": "STAGING", "toEnvironment": "PROD"}
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/deployments/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a57

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a57", "versionNo": 3, "environment": "PROD",
 "kind": "PROMOTE", "desiredState": "RUNNING", "syncStatus": "PENDING",
 "requestedBy": "binh.tt", "requestedAt": "2026-11-26T10:00:00+07:00", "allowedActions": []}
```

### Vận hành

#### API-04-060 · Tình trạng runtime theo môi trường

::: dac-ta
**Mục đích.** Tình trạng runtime theo môi trường.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/runtime`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-051.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuntimeStatus`; trường bắt buộc: `environments`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Tình trạng runtime theo môi trường: phiên bản đang chạy, bản sao sẵn sàng, trạng thái từng route và số liệu một phút, tính từ nhịp tim EVT-04-12.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/runtime
```

```http
HTTP/1.1 200 OK

{"environments": [{"environment": "PROD", "versionNo": 2, "syncStatus": "SYNCED", "healthStatus": "HEALTHY",
   "desiredState": "RUNNING", "readyReplicas": 3, "replicas": 3,
   "runtimeProfile": "core-native",
   "routes": [{"routeId": "tra-cuu", "state": "Started", "exchanges1m": 42, "failures1m": 0, "p95ms": 180}]}]}
```

#### API-04-061 · Trạng thái lệnh

::: dac-ta
**Mục đích.** Trạng thái lệnh.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/runtime/commands/{commandId}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-050.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `commandId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Command`; trường bắt buộc: `id`, `status`, `action`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Trả trạng thái lệnh và xác nhận theo từng bản sao (`acks`). `PARTIAL` sau 30 giây khi chưa đủ xác nhận; lý do từ chối nằm ở `acks[].reason`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/runtime/commands/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61", "environment": "PROD", "action": "PAUSE",
 "scope": "FLOW", "status": "ACKNOWLEDGED", "expectedReplicas": 3, "ackedReplicas": 3,
 "issuedBy": "cuong.lv", "issuedAt": "2026-11-26T21:55:00+07:00",
 "expiresAt": "2026-11-26T21:56:00+07:00",
 "acks": [{"replica": "dh-rt-t68-core-7c9d-x2k4p", "result": "APPLIED",
   "ackedAt": "2026-11-26T21:55:02+07:00"}]}
```

#### Tạm dừng, tiếp tục, dừng khẩn (API-04-061, POST)

::: dac-ta
**Mục đích.** Tạm dừng, tiếp tục, dừng khẩn.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/runtime/commands`.

**Quyền.** `PERM-04-operate`.

**FR hiện thực.** FR-04-050.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CommandRequest`; trường bắt buộc: `environment`, `action`, `scope`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Command`; trường bắt buộc: `id`, `status`, `action`; tiêu đề `Location`.

**Lỗi.** `400` Tham số hoặc thân sai (ERR-04-049; thiếu lý do ERR-04-025; trang quá 100 ERR-04-026); `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** EMERGENCY_STOP cần PERM-04-emergency-stop. Thiếu lý do ERR-04-025; chưa triển khai ở môi trường ERR-04-023. Lệnh khẩn đi trước Git (ADR-065).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/runtime/commands
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"environment": "PROD", "action": "PAUSE", "scope": "FLOW",
 "reason": "Hệ đích NDXP bảo trì từ 22 giờ đến 23 giờ ngày 26/11.", "drain": true}
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/runtime/commands/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61", "environment": "PROD", "action": "PAUSE",
 "scope": "FLOW", "status": "ISSUED", "expectedReplicas": 3, "ackedReplicas": 0,
 "issuedBy": "cuong.lv", "issuedAt": "2026-11-26T21:55:00+07:00",
 "expiresAt": "2026-11-26T21:56:00+07:00"}
```

#### Gửi lại lệnh chưa đủ xác nhận (API-04-061, POST)

::: dac-ta
**Mục đích.** Gửi lại lệnh chưa đủ xác nhận.

**Phương thức, đường dẫn.** `POST /flows/{flowCode}/runtime/commands/{commandId}:resend`.

**Quyền.** `PERM-04-operate`.

**FR hiện thực.** FR-04-050.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `commandId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Command`; trường bắt buộc: `id`, `status`, `action`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** Chỉ với PARTIAL; ký lại với hạn mới, cùng commandId gốc trong `resendOf`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/flows/tra-cuu-ho-tich/runtime/commands/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a61:resend
```

```http
HTTP/1.1 202 Accepted
Location: /api/integration/v1/flows/tra-cuu-ho-tich/runtime/commands/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a62

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a62", "environment": "PROD", "action": "PAUSE",
 "scope": "FLOW", "status": "ISSUED", "expectedReplicas": 3, "ackedReplicas": 0,
 "issuedBy": "cuong.lv", "issuedAt": "2026-11-26T21:55:00+07:00",
 "expiresAt": "2026-11-26T21:56:00+07:00"}
```

#### API-04-062 · Điểm kết nối và số liệu

::: dac-ta
**Mục đích.** Điểm kết nối và số liệu.

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/endpoints`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-052.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `environment` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EndpointList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Liệt kê điểm vào, điểm ra của luồng (URI đã che tham số nhạy cảm, kết nối, topic) kèm số liệu một giờ.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/endpoints?environment=PROD
```

```http
HTTP/1.1 200 OK

{"items": [{"nodeId": "n1", "direction": "IN", "scheme": "platform-http", "httpMethod": "POST",
   "httpPath": "/ho-tich/tra-cuu",
   "metrics": {"exchanges1h": 2480, "failures1h": 3, "p95ms": 190}}]}
```

#### API-04-063 · Số liệu theo luồng (từ PH-13)

::: dac-ta
**Mục đích.** Số liệu theo luồng (từ PH-13).

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/metrics`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-053.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `environment` (query, Environment, bắt buộc); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `step` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowMetrics`; trường bắt buộc: `series`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `503` Phụ thuộc chưa sẵn sàng (ERR-04-047; sandbox ERR-04-019).

**Ghi chú.** Chuỗi số liệu (số trao đổi, lỗi, p95, DLQ) của luồng ở một môi trường, đọc từ PH-13 và lọc sẵn theo tenant. PH-13 không sẵn sàng ERR-04-047.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/metrics?environment=PROD&from=2026-11-26T09:00:00+07:00&to=2026-11-26T10:00:00+07:00&step=30m
```

```http
HTTP/1.1 200 OK

{"environment": "PROD", "step": "30m",
 "series": [{"name": "exchanges", "points": [[1795744800, 1210], [1795746600, 1270]]}]}
```

### Danh mục thành phần

#### API-04-070 · Chỉ mục catalog đã lọc chính sách

::: dac-ta
**Mục đích.** Chỉ mục catalog đã lọc chính sách.

**Phương thức, đường dẫn.** `GET /catalog`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-012, FR-04-080.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogIndex`; trường bắt buộc: `catalogVersion`, `entries`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** ETag theo catalogVersion + policyVersion + paletteRulesVersion; hỗ trợ 304.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/catalog
If-None-Match: W/"camel-quarkus-3.33.2.p17.r4"
```

```http
HTTP/1.1 200 OK
ETag: W/"camel-quarkus-3.33.2.p17.r4"

{"catalogVersion": "camel-quarkus-3.33.2", "runtime": "quarkus", "paletteRulesVersion": 4,
 "entries": [{"kind": "COMPONENT", "name": "http", "titleVi": "Gọi HTTP", "groups": ["deliver"],
   "policy": "ALLOWED", "needsConnection": true}]}
```

#### API-04-071 · Lược đồ thuộc tính của thành phần

::: dac-ta
**Mục đích.** Lược đồ thuộc tính của thành phần.

**Phương thức, đường dẫn.** `GET /catalog/{kind}/{name}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-014, FR-04-080.

**Tham số.** `kind` (path, string, bắt buộc); `name` (path, string, bắt buộc); `catalogVersion` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ComponentSchema`; trường bắt buộc: `entry`, `properties`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** ERR-04-035 khi không có trong catalog của phiên bản yêu cầu.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/catalog/components/http?catalogVersion=camel-quarkus-3.33.2
```

```http
HTTP/1.1 200 OK

{"entry": {"kind": "COMPONENT", "name": "http", "policy": "ALLOWED"},
 "syntax": "http:httpUri",
 "properties": [{"name": "connectTimeout", "kind": "parameter", "type": "duration", "required": false,
   "default": "30s", "secret": false}], "flowsUsing": 14}
```

#### API-04-072 · Chính sách thành phần (nền + tỉnh)

::: dac-ta
**Mục đích.** Chính sách thành phần (nền + tỉnh).

**Phương thức, đường dẫn.** `GET /catalog/policies`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-080.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Chính sách thành phần hiệu lực: tầng nền (PLATFORM) và tầng tỉnh (TENANT) kèm `policyVersion`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/catalog/policies
```

```http
HTTP/1.1 200 OK

{"items": [{"kind": "components", "name": "exec", "decision": "DENIED", "scope": "PLATFORM",
   "policyVersion": 7}], "policyVersion": 7}
```

#### Sửa chính sách thành phần (API-04-072, PATCH)

::: dac-ta
**Mục đích.** Sửa chính sách thành phần.

**Phương thức, đường dẫn.** `PATCH /catalog/policies`.

**Quyền.** `PERM-04-catalog-admin`.

**FR hiện thực.** FR-04-080.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PolicyUpdate`; trường bắt buộc: `changes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `412` ETag lệch (ERR-04-006); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** PA sửa chính sách nền (phiên PLATFORM); TA (PERM-04-admin) chỉ thu hẹp cho tỉnh: ALLOWED từ tỉnh bị từ chối (403). Luồng dùng thành phần vừa cấm được đánh dấu.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/integration/v1/catalog/policies
If-Match: W/"3-3f9a1c2e"

{"changes": [{"kind": "components", "name": "ftp", "decision": "PER_FLOW",
   "reason": "Chỉ cho luồng nhận tệp từ hệ thống hộ tịch cũ."}]}
```

```http
HTTP/1.1 200 OK

{"items": [{"kind": "components", "name": "exec", "decision": "DENIED", "scope": "PLATFORM",
   "policyVersion": 7},
  {"kind": "components", "name": "ftp", "decision": "PER_FLOW", "scope": "TENANT",
   "policyVersion": 8}], "policyVersion": 8}
```

#### API-04-073 · Phiên bản catalog và hồ sơ runtime

::: dac-ta
**Mục đích.** Phiên bản catalog và hồ sơ runtime.

**Phương thức, đường dẫn.** `GET /catalog/versions`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-081, FR-04-075.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersions`; trường bắt buộc: `tenantCatalogVersion`, `profiles`, `match`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Phiên bản catalog của tenant, các hồ sơ runtime (Quarkus, Camel Quarkus, thư viện nền, ảnh) và đợt nâng cấp đang chờ.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/catalog/versions
```

```http
HTTP/1.1 200 OK

{"tenantCatalogVersion": "camel-quarkus-3.33.2", "match": true,
 "profiles": [{"profile": "core-native", "quarkusVersion": "3.28.4", "camelQuarkusVersion": "3.33.2",
   "libVersion": "dh-lib 1.4.0"}]}
```

#### API-04-074 · Đề xuất thành phần

::: dac-ta
**Mục đích.** Đề xuất thành phần.

**Phương thức, đường dẫn.** `GET /catalog/proposals`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-080.

**Tham số.** `status` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProposalList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Danh sách đề xuất cho phép hoặc bổ sung thành phần, lọc theo trạng thái.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/catalog/proposals?status=OPEN
```

```http
HTTP/1.1 200 OK

{"items": [{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a74", "kind": "components", "name": "jt400",
   "type": "NEW_COMPONENT", "status": "OPEN", "createdBy": "an.nv",
   "createdAt": "2026-11-26T08:00:00+07:00"}]}
```

#### Đề xuất cho phép hoặc bổ sung thành phần (API-04-074, POST)

::: dac-ta
**Mục đích.** Đề xuất cho phép hoặc bổ sung thành phần.

**Phương thức, đường dẫn.** `POST /catalog/proposals`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-080.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProposalCreate`; trường bắt buộc: `kind`, `name`, `type`, `justification`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Proposal`; trường bắt buộc: `id`, `kind`, `name`, `type`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** Người thiết kế đề xuất cho phép thành phần đang bị cấm hoặc bổ sung thành phần mới, kèm lý do ≥ 20 ký tự. Đề xuất mở trùng thành phần ERR-04-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/catalog/proposals
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"kind": "components", "name": "jt400", "type": "NEW_COMPONENT",
 "justification": "Hệ thống hộ tịch cũ chạy trên IBM i, cần đọc hàng đợi dữ liệu."}
```

```http
HTTP/1.1 201 Created

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a74", "kind": "components", "name": "jt400",
 "type": "NEW_COMPONENT", "status": "OPEN", "createdBy": "an.nv",
 "createdAt": "2026-11-26T08:00:00+07:00"}
```

#### Quyết định đề xuất (API-04-074, POST)

::: dac-ta
**Mục đích.** Quyết định đề xuất.

**Phương thức, đường dẫn.** `POST /catalog/proposals/{proposalId}:decide`.

**Quyền.** `PERM-04-catalog-admin`.

**FR hiện thực.** FR-04-080.

**Tham số.** `proposalId` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProposalDecision`; trường bắt buộc: `decision`, `note`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Proposal`; trường bắt buộc: `id`, `kind`, `name`, `type`, `status`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005).

**Ghi chú.** PA quyết định đề xuất (cần ý kiến SO theo FR-04-080); chấp nhận kèm mức chính sách `ALLOWED` hoặc `PER_FLOW`. Đề xuất đã đóng ERR-04-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/catalog/proposals/0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a74:decide

{"decision": "ACCEPTED", "note": "Đồng ý, chỉ cho từng luồng có SO duyệt.",
 "policyDecision": "PER_FLOW"}
```

```http
HTTP/1.1 200 OK

{"id": "0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a74", "kind": "components", "name": "jt400",
 "type": "NEW_COMPONENT", "status": "ACCEPTED", "createdBy": "an.nv",
 "createdAt": "2026-11-26T08:00:00+07:00", "decidedBy": "pa.admin",
 "decisionNote": "Đồng ý, chỉ cho từng luồng có SO duyệt."}
```

### Khuôn mẫu

#### API-04-080 · Danh sách khuôn mẫu

::: dac-ta
**Mục đích.** Danh sách khuôn mẫu.

**Phương thức, đường dẫn.** `GET /templates`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-025.

**Tham số.** `resourceKind` (query, ResourceKind, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplateList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Khuôn mẫu nền và khuôn của tỉnh đang dùng được, lọc theo loại tài nguyên.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/templates?resourceKind=ROUTE
```

```http
HTTP/1.1 200 OK

{"items": [{"code": "tpl-rest-proxy", "name": "Chuyển tiếp REST chín chặng", "category": "rest",
   "resourceKind": "ROUTE", "scope": "PLATFORM", "status": "ACTIVE",
   "catalogVersion": "camel-quarkus-3.33.2"}]}
```

#### API-04-081 · Chi tiết khuôn và lược đồ tham số

::: dac-ta
**Mục đích.** Chi tiết khuôn và lược đồ tham số.

**Phương thức, đường dẫn.** `GET /templates/{templateCode}`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-025.

**Tham số.** `templateCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TemplateDetail`; trường bắt buộc: `code`, `name`, `scope`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Chi tiết khuôn: YAML thân, lược đồ tham số (JSON Schema) để dựng biểu mẫu tạo luồng, bố cục xem trước. Khuôn không tồn tại ERR-04-039.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/templates/tpl-rest-proxy
```

```http
HTTP/1.1 200 OK

{"code": "tpl-rest-proxy", "name": "Chuyển tiếp REST chín chặng", "category": "rest",
 "resourceKind": "ROUTE", "scope": "PLATFORM", "status": "ACTIVE",
 "catalogVersion": "camel-quarkus-3.33.2",
 "bodyYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n",
 "paramSchema": {"type": "object", "required": ["upstream"]}}
```

#### API-04-082 · Tạo khuôn của tỉnh từ phiên bản đã duyệt

::: dac-ta
**Mục đích.** Tạo khuôn của tỉnh từ phiên bản đã duyệt.

**Phương thức, đường dẫn.** `POST /templates`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-025.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateCreate`; trường bắt buộc: `code`, `name`, `fromFlow`, `fromVersionNo`, `paramSchema`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TemplateDetail`; trường bắt buộc: `code`, `name`, `scope`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `409` Xung đột trạng thái hoặc nghiệp vụ, mã cụ thể trong `code` (ERR-04-005); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** Tạo khuôn của tỉnh từ phiên bản luồng đã duyệt, kèm lược đồ tham số. Mã khuôn trùng ERR-04-005; phiên bản chưa duyệt ERR-04-005.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/templates
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10

{"code": "tpl-t68-tra-cuu", "name": "Tra cứu qua NDXP của tỉnh",
 "fromFlow": "tra-cuu-ho-tich", "fromVersionNo": 2,
 "paramSchema": {"type": "object", "required": ["upstream"]}}
```

```http
HTTP/1.1 201 Created

{"code": "tpl-t68-tra-cuu", "name": "Tra cứu qua NDXP của tỉnh", "category": "rest",
 "resourceKind": "ROUTE", "scope": "TENANT", "status": "ACTIVE",
 "catalogVersion": "camel-quarkus-3.33.2",
 "bodyYaml": "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n"}
```

#### Ngừng dùng khuôn của tỉnh (API-04-082, POST)

::: dac-ta
**Mục đích.** Ngừng dùng khuôn của tỉnh.

**Phương thức, đường dẫn.** `POST /templates/{templateCode}:deprecate`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-025.

**Tham số.** `templateCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Template`; trường bắt buộc: `code`, `name`, `scope`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `404` Không tìm thấy hoặc không được xem (ERR-04-001).

**Ghi chú.** Ngừng dùng khuôn của tỉnh; luồng đã tạo từ khuôn không bị ảnh hưởng. Khuôn nền không ngừng được ở đây (403).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/integration/v1/templates/tpl-rest-proxy:deprecate
If-Match: W/"3-3f9a1c2e"
```

```http
HTTP/1.1 200 OK

{"code": "tpl-t68-tra-cuu", "name": "Tra cứu qua NDXP của tỉnh", "category": "rest",
 "resourceKind": "ROUTE", "scope": "TENANT", "status": "DEPRECATED",
 "catalogVersion": "camel-quarkus-3.33.2"}
```

### Tham số

#### API-04-090 · Tham số 04.*, khoảng đóng băng, biến môi trường

::: dac-ta
**Mục đích.** Tham số 04.*, khoảng đóng băng, biến môi trường.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-084.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `params`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044).

**Ghi chú.** Chỉ đọc; sửa tham số qua màn tham số chung của PH-18 (UI-04-20 nhúng).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/settings
```

```http
HTTP/1.1 200 OK

{"params": [{"key": "04.test.max-concurrent", "value": 5, "default": 5}],
 "envVars": [{"name": "ndxp-base-path", "description": "Đường gốc API NDXP theo môi trường.",
   "values": {"TEST": "/sandbox/v1", "STAGING": "/uat/v1", "PROD": "/v1"}, "usedBy": 4}]}
```

#### Thay biến môi trường {{dh.env.*}} (API-04-090, PUT)

::: dac-ta
**Mục đích.** Thay biến môi trường {{dh.env.*}}.

**Phương thức, đường dẫn.** `PUT /settings/env-vars`.

**Quyền.** `PERM-04-admin`.

**FR hiện thực.** FR-04-084.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EnvVarList`; trường bắt buộc: `items`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EnvVarList`; trường bắt buộc: `items`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `403` Thiếu quyền (ERR-04-045; mức không gian ERR-04-003; bốn mắt ERR-04-015); `412` ETag lệch (ERR-04-006); `422` Định nghĩa hoặc dữ liệu không hợp lệ, kèm `findings` (ERR-04-009).

**Ghi chú.** Giá trị giống bí mật bị từ chối (ERR-04-010); bí mật dùng {{vault:}}.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/integration/v1/settings/env-vars
If-Match: W/"3-3f9a1c2e"

{"items": [{"name": "ndxp-base-path", "description": "Đường gốc API NDXP theo môi trường.",
   "values": {"TEST": "/sandbox/v1", "STAGING": "/uat/v1", "PROD": "/v1"}, "usedBy": 4}]}
```

```http
HTTP/1.1 200 OK

{"items": [{"name": "ndxp-base-path", "description": "Đường gốc API NDXP theo môi trường.",
   "values": {"TEST": "/sandbox/v1", "STAGING": "/uat/v1", "PROD": "/v1"}, "usedBy": 4}]}
```

#### API-04-091 · Lịch sử thao tác của luồng (từ PH-13)

::: dac-ta
**Mục đích.** Lịch sử thao tác của luồng (từ PH-13).

**Phương thức, đường dẫn.** `GET /flows/{flowCode}/history`.

**Quyền.** `PERM-04-read`.

**FR hiện thực.** FR-04-083.

**Tham số.** `flowCode` (path, FlowCode, bắt buộc); `action` (query, array, tùy chọn); `actor` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu hoặc hết hạn token (ERR-04-044); `404` Không tìm thấy hoặc không được xem (ERR-04-001); `503` Phụ thuộc chưa sẵn sàng (ERR-04-047; sandbox ERR-04-019).

**Ghi chú.** `before`, `after` chỉ trả cho AU, SO, TA.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/integration/v1/flows/tra-cuu-ho-tich/history?action=INT_VERSION_APPROVE
```

```http
HTTP/1.1 200 OK

{"items": [{"at": "2026-11-26T10:00:00+07:00", "action": "INT_VERSION_APPROVE", "actor": "binh.tt",
   "versionNo": 3, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}],
 "page": {"next": null, "hasMore": false}}
```

<!-- gen:dac-ta-api:end -->

## 11. Đề nghị đồng bộ

Các mục dưới đây là thay đổi tài liệu này đề nghị cho tập khác hoặc cho bản hợp đồng sau. Tài liệu này không tự sửa tập khác; các đề nghị được gom một đợt cuối.

| Số | Tập nhận | Đề nghị | Lý do | Trạng thái |
|---|---|---|---|---|
| 1 | D03-06-PH04 §5.3 | Thêm câu hiển thị cho ERR-04-004, 007, 018, 026, 027, 028, 030, 032, 034, 035, 039, 042, 043, 045, 047, 049 đúng như FRS D02-03-PH04 §9.2 (bản 0.2) và §6.1 ở đây | Bảng màn hình chưa có các mã này; câu đã thống nhất ở FRS | Đã hấp thụ (0.2): MH §5.3 có đủ các câu này |
| 2 | D03-06-PH04 §5.3; D02-03-PH04 §9.2 | Thêm ba câu mới: ERR-04-044 "Phiên làm việc đã hết hạn hoặc cần đăng nhập lại để tiếp tục."; ERR-04-046 "Định dạng tệp hoặc nội dung gửi lên không được hỗ trợ."; ERR-04-048 "Bạn thao tác quá nhanh. Vui lòng thử lại sau {retryAfterSeconds} giây." | Ba mã chưa có câu ở cả FRS và màn hình | Đã hấp thụ (0.2): ERR-04-044, 046, 048 có câu ở FRS §9.2 và MH §5.3 |
| 3 | D03-06-PH04 §5.3 (mục lỗi runtime cho người vận hành) | Dẫn câu `title` của ERR-04-101…112 (§6.2) cho màn vận hành và DLQ | Người vận hành thấy cùng câu với bên gọi | Đã hấp thụ (0.2): MH §5.3 có bảng câu ERR-04-101…112 cho người vận hành |
| 4 | D03-02-PH04 §8.2; bản hợp đồng sau | Cấp mã cho hai API nội bộ của sandbox, đánh số tiếp sau mã lớn nhất API-04-091 (dự kiến số 092 cho `GET /internal/v1/testruns/{id}/bundle`, số 093 cho `POST /internal/v1/testruns/{id}/steps`), đặc tả trong một tệp OpenAPI nội bộ riêng `ph04/openapi-integration-internal.yaml` | Hai DU khác nhau trao đổi qua hai API này nên cần hợp đồng có kiểm CI; bản 0.2 chưa thêm mã vì chưa có quyết định ở SDD | Chờ bản hợp đồng sau (cần mã API mới và tệp OpenAPI nội bộ) |
| 5 | D04-01; bản hợp đồng `v1` sau | Tách mã cho operation đang dùng chung (API-04-002, 004, 028, 034, 042, 044, 054, 061, 072, 074, 082, 090) theo K-API §3 "mỗi operation một mã", đánh số mới tiếp sau mã lớn nhất; giữ mã cũ cho operation đầu của nhóm | Bản 0.1 trái K-API; đổi mã cần đồng bộ FRS §9.4, màn hình, ca kiểm thử nên để một đợt riêng | Chờ đợt đồng bộ cuối (D04-01 ngoài PH-04, đổi mã kéo theo FRS, MH, TC) |
| 6 | D05-02-PH04 | Dùng ví dụ yêu cầu và phản hồi ở chương 10 (đã kiểm khớp lược đồ) làm dữ liệu cho ca kiểm thử hợp đồng; chạy `check_contracts.py` ở CI-5 | Tránh mỗi tập tự viết ví dụ khác nhau | Còn mở: D05-02-PH04 (Schemathesis trên `openapi-integration.yaml`, TS-04-28) chưa dẫn ví dụ chương 10 làm dữ liệu ca; xử lý ở bản sau |
| 7 | D04-02 (CI-5) | Thêm `ph04/tools/check_contracts.py` vào cổng CI-5 bên cạnh công cụ của PH-05 | Hiện CI chỉ ghi kiểm tra bằng lời | Chờ đợt đồng bộ cuối (D04-02 ngoài PH-04) |

: Đề nghị đồng bộ với tập khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-25 | Bản đầu: 70 operation, 14 sự kiện, bảng ERR-04 đầy đủ, ánh xạ hệ cũ và W2 |
| 0.2 | 2026-11-26 | Lên chuẩn trình bày kết hợp, giữ mọi nội dung 0.1: chương Giới thiệu với sơ đồ kiến trúc và hai sơ đồ trình tự; đặc tả 14 sự kiện kèm ví dụ payload; cột câu hiển thị cho ERR-04-001…049 và câu trả bên gọi cho ERR-04-101…112; đặc tả 70 operation sinh từ OpenAPI kèm ví dụ yêu cầu và phản hồi; mô tả và ví dụ bổ sung ở nguồn sinh; sửa lược đồ `allOf`; công cụ `check_contracts.py`; đề nghị đồng bộ |

: Lịch sử phiên bản
