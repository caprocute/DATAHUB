---
ma_tai_lieu: D03-04-PH03
ten: Đặc tả API và sự kiện phân hệ PH-03 Cổng API
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, gateway, giao diện; đơn vị kết nối (PH-01, PH-12, PH-13); ATTT; kiểm thử viên; hội đồng thẩm định
phan_he: PH-03
mo_ta: Đặc tả 96 endpoint REST của mặt phẳng điều khiển cổng API, 12 sự kiện Kafka, 57 mã lỗi và hợp đồng giữa cổng với bên gọi, sinh từ OpenAPI 3.1 và AsyncAPI 3.0 đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH03 FRS; D02-04-PH03 Use case; D03-02-PH03 SDD; D03-03-PH03 CSDL; D03-06-PH03 Màn hình; D05-02-PH03 Test case; D02-08 Ma trận phân quyền
---

# D03-04-PH03 · Đặc tả API và sự kiện Cổng API

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chốt hợp đồng giao diện của PH-03 để các nhóm viết mã cùng lúc mà không lệch nhau: giao diện quản trị gọi gì, PH-01, PH-12, PH-13 gọi gì, cổng phát những sự kiện nào, và khi có lỗi thì bên gọi nhận được gì. Nguồn chuẩn là hai tệp máy đọc được, bảng và đặc tả trong tài liệu này đều sinh từ chúng nên không thể lệch nhau.

**Phạm vi.** Ba loại hợp đồng. (1) **API quản trị** của mặt phẳng điều khiển `dh-connect` dưới `/api/gateway/v1`: 96 operation chia 24 nhóm, từ route, consumer, hạn mức, WAF đến ảnh chụp cấu hình, nút, nhật ký lượt gọi và tham số. (2) **Sự kiện** 12 loại trên Kafka. (3) **Hợp đồng của cổng với bên gọi API**: 30 mã lỗi `ERR-03-101…130` mà APISIX trả cho HTTT, cùng các tiêu đề giới hạn tần suất và ngừng dùng. API mà HTTT công bố để trao đổi dữ liệu (ví dụ tra cứu hộ tịch) do PH-02 quản lý và không nằm trong tập này; chúng đi qua cổng chứ không phải API của cổng.

**Căn cứ pháp lý.** CMP-LAW-09 (Công văn 631/THH-THHT: quản lý API, xác thực OAuth, giới hạn tần suất); CMP-LAW-08 (TCVN 14423:2026: kiểm soát truy cập, nhật ký); CMP-LAW-05 (Luật BVDLCN 91/2025: không ghi dữ liệu cá nhân vào nhật ký lượt gọi); CMP-LAW-16 (Luật An ninh mạng 116/2025: nhật ký, bảo vệ hệ thống).

**Những điểm hội đồng cần lưu ý.**

1. **API quản trị không nằm trên đường đi của lượt gọi.** APISIX chỉ đọc ảnh chụp cấu hình đã ký, không gọi vào `dh-connect`; khi `dh-connect` ngừng, cổng vẫn phục vụ đúng cấu hình đang chạy (NFR-03-007). Vì vậy độ sẵn sàng của API quản trị không làm giảm độ sẵn sàng của dịch vụ công.
2. **Không API nào nhận hoặc trả bí mật.** Consumer chỉ nhận phần công khai (vân tay SHA-256 của chứng thư, băm khóa API); thân chứa trường dạng bí mật bị từ chối bằng ERR-03-003. Kiểm tra hợp đồng trong CI chặn mọi lược đồ có thuộc tính dạng bí mật.
3. **Bốn mắt được cưỡng chế ở máy chủ, không ở giao diện.** Bốn nhóm thay đổi rủi ro cao (ngoại lệ WAF, đổi chế độ WAF, route ra cửa Internet, hạ hạn mức tenant) trả `202` kèm yêu cầu thay đổi; người duyệt phải là tài khoản khác người đề nghị (ERR-03-008).
4. **Thu hồi có hiệu lực nhanh.** Thu hồi token (API-03-053, do PH-12 gọi) có hiệu lực trong 60 giây; tạm ngừng khẩn cấp route hoặc consumer (API-03-017, 019) trong 30 giây, không chờ ảnh chụp mới và không cần người duyệt.
5. **Hợp đồng lỗi có hai tầng.** `ERR-03-001…027` cho người quản trị và hệ thống gọi `dh-connect`; `ERR-03-101…130` cho HTTT gọi API qua cổng. Cả hai theo RFC 9457 với `code` và `traceId`, nên đơn vị kết nối chỉ cần một bộ xử lý lỗi.
6. **Điểm cần ý kiến.** Năm câu hỏi mở Q03-55…59 ở chương 9, đáng chú ý là phân trang nhật ký lượt gọi trên kho ClickHouse (Q03-56) và mã lỗi cho `401` ở mặt phẳng điều khiển (Q03-55).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Operation REST | 96 (API-03-001…096): 47 GET, 33 POST, 12 PUT, 4 DELETE; 80 đường dẫn; 24 nhóm |
| Operation có `If-Match` (khóa lạc quan) | 33; có `Idempotency-Key` bắt buộc: 17 |
| Operation gọi bằng token dịch vụ | 4 (API-03-013, 014, 015 scope `gateway:sync`; API-03-053 scope `gateway:revoke`) |
| Operation có hai nhánh thành công (200 hoặc 202, 200 hoặc 201) | 6 |
| Sự kiện Kafka | 12 (EVT-03-01…12), 12 kênh AsyncAPI 3.0 |
| Mã lỗi | 57: 27 control plane (ERR-03-001…027), 30 gateway trả cho bên gọi (ERR-03-101…130) |
| Lược đồ OpenAPI | 125 lược đồ; 35 ví dụ OpenAPI, 15 khối JSON trong tài liệu và 9 ví dụ sự kiện đã kiểm khớp lược đồ |
| Phủ yêu cầu | 59 FR: 57 FR có ít nhất một API; FR-03-013 (xác định tenant) và FR-03-032 (định danh truy vết) thuần ở mặt phẳng dữ liệu, ghi rõ ở §3.2 |
| Kiểm tra hợp đồng | OpenAPI qua `openapi-spec-validator`; Spectral với `spectral:oas` và OWASP API Security: 0 lỗi, 270 cảnh báo mức thấp; AsyncAPI qua `@asyncapi/parser` 3: 0 lỗi |

: Con số chính của API PH-03

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả giao diện lập trình của PH-03 theo khuôn K-API: quy ước chung, xác thực và phân quyền, danh mục và đặc tả từng endpoint, danh mục sự kiện, hợp đồng với phân hệ khác, bảng mã lỗi, kiểm tra hợp đồng trong CI, ánh xạ từ hệ cũ và câu hỏi mở. Nguồn chuẩn là [`ph03/openapi-gateway.yaml`](ph03/openapi-gateway.yaml) (OpenAPI 3.1) và [`ph03/asyncapi-gateway.yaml`](ph03/asyncapi-gateway.yaml) (AsyncAPI 3.0). Hai tệp này sinh từ [`ph03/tools/spec.py`](ph03/tools/spec.py) (danh mục operation, mã lỗi, sự kiện) bằng `gen_openapi.py`, `gen_asyncapi.py`; các bảng ở chương 2, 3, 4, 6 sinh bằng `gen_md.py`; chương 10 sinh bằng `build/tools/sinh_dac_ta_api.py`. Sửa nguồn rồi sinh lại, không sửa tay phần sinh.

Phân hệ chạy trên hai đơn vị triển khai. `apisix` là mặt phẳng dữ liệu, nhận lượt gọi từ ngoài và từ giao diện; `dh-connect` là mặt phẳng điều khiển, tổng hợp, kiểm tra, ký và phát cấu hình xuống APISIX. Tài liệu này đặc tả giao diện của `dh-connect` (module `gateway`) và các hợp đồng đi qua cổng; hành vi bên trong từng plugin APISIX nằm ở [D03-02-PH03](../sdd/D03-02-PH03-sdd-cong-api.md).

```{.mermaid caption="Vị trí của API quản trị PH-03 trong kiến trúc"}
flowchart TB
  CON["Console qua BFF<br/>quyền PERM-03"] --> CP
  P1["PH-01 saga kết nạp<br/>scope gateway:sync"] --> CP
  P12["PH-12 thu hồi token<br/>scope gateway:revoke"] --> CP
  P13["PH-13 giám sát<br/>scope gateway:read-state"] --> CP
  CP["dh-connect, module gateway<br/>/api/gateway/v1"] --> DB[("pg-core<br/>schema ph03_gateway")]
  CP --> VK[("Valkey<br/>khóa chặn nhanh")]
  CP --> BK[("Bucket và Git<br/>ảnh chụp đã ký")]
  CP --> KF["Kafka<br/>EVT-03-01 đến 12"]
  BK --> AX["APISIX apisix-ext, apisix-int"]
  VK --> AX
  HT["HTTT bên gọi"] -->|"lượt gọi API"| AX
  AX -->|"chuyển tiếp"| BE["Backend của HTTT"]
```

Hình cho thấy hai đường tách biệt: đường quản trị đi vào `dh-connect` và đường lượt gọi đi vào APISIX. Hai đường chỉ gặp nhau ở ba kho dữ liệu (ảnh chụp ở bucket và Git, khóa chặn ở Valkey, chỉ số), do đó API quản trị ngừng thì lượt gọi vẫn đi.

### 0.2. Người đọc

Tài liệu có mười chương cho nhiều nhóm người đọc nên không ai cần đọc hết; bảng dưới chỉ ra mỗi nhóm cần đọc phần nào.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect`, giao diện | Chương 1, 2, 3, 10 |
| Kỹ sư gateway (plugin APISIX, `dh-sync`) | Chương 4, 5.4, 5.5, 6.2 |
| Kỹ sư PH-01, PH-12, PH-13, PH-02, PH-20 | Chương 2, 5, và các API ở bảng chương 3 mà phân hệ mình gọi |
| Đơn vị kết nối (HTTT gọi API qua cổng) | Mục 5.4 và 6.2 |
| Kiểm thử viên | Chương 3, 6, 7, 10 |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5, 7 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng chung theo [D00-01](../../00-chung/D00-01-thuat-ngu-quy-uoc.md) và [D02-03-PH03](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md) §1.4. Bảng dưới chỉ nhắc những từ gắn với giao diện.

| Thuật ngữ | Giải thích |
|---|---|
| Control plane, data plane | Mặt phẳng điều khiển (`dh-connect`, API trong tài liệu này) và mặt phẳng dữ liệu (APISIX, OPA, Valkey) |
| Ảnh chụp cấu hình | Tệp khai báo đầy đủ route, upstream, consumer, plugin của một tenant, có số phiên bản tăng đơn điệu và chữ ký ECDSA P-256 |
| Route, upstream, consumer | Quy tắc định tuyến; nhóm backend nhận lượt gọi; hình chiếu của một client (HTTT) trên gateway |
| Cửa vào `INT`, `EXT` | `apisix-int` (mạng nội bộ, TSLCD) và `apisix-ext` (Internet) |
| Bốn mắt | Việc quan trọng cần hai tài khoản khác nhau: một người đề nghị, một người duyệt |
| Yêu cầu thay đổi (`ChangeRequest`) | Bản ghi chờ duyệt do thao tác bốn mắt tạo ra; trả `202` |
| `ETag`, `If-Match` | Số phiên bản bản ghi dùng làm khóa lạc quan: `GET` trả `ETag`, lệnh ghi gửi lại ở `If-Match` |
| `Idempotency-Key` | Khóa do bên gọi sinh để gọi lại an toàn: cùng khóa cùng thân trả đúng kết quả cũ |
| RFC 9457 | Chuẩn thân lỗi HTTP `application/problem+json` (kế thừa RFC 7807) |
| Outbox | Bảng ghi sự kiện cùng giao dịch với thay đổi dữ liệu, rồi Debezium đưa lên Kafka |
| CloudEvents | Chuẩn khung sự kiện (`ce_id`, `ce_type`, `ce_time`…), dùng chế độ nhị phân qua tiêu đề Kafka |
| BFF | Máy chủ trung gian của giao diện; giữ token, trình duyệt không cầm token |
| PA, PO, TA, TO, SO, AU | Vai trò: quản trị nền tảng, vận hành nền tảng, quản trị tenant, vận hành tenant, Cán bộ ATTT, kiểm toán viên |
| CRS, Coraza | Bộ luật cốt lõi của OWASP; bộ máy WAF chạy trong APISIX |
| JWKS, OPA, Valkey | Tập khóa công khai để kiểm token; bộ ra quyết định ủy quyền; kho khóa–giá trị cho bộ đếm và khóa chặn |

: Thuật ngữ và chữ viết tắt dùng ở tài liệu này

### 0.4. Tài liệu tham chiếu

Hợp đồng này dựa vào ba tập cùng phân hệ và một số tài liệu chung. Khi có chỗ lệch, tài liệu này là gốc của mã `API-03`, `EVT-03`, `ERR-03`; FRS là gốc của `FR-03`, `BR-03`; SDD và CSDL là gốc của thiết kế bên trong.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D02-03-PH03 | [FRS Cổng API](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md) | 59 FR, danh mục 96 API (§9.4), 57 mã lỗi (§9.1), 12 sự kiện (§9.3), thông báo (§9.2) |
| D02-04-PH03 | [Use case Cổng API](../../02-yeu-cau/use-case/D02-04-PH03-use-case-cong-api.md) | Luồng người dùng và hệ thống gọi API |
| D03-02-PH03 | [SDD Cổng API](../sdd/D03-02-PH03-sdd-cong-api.md) | DTO (§3.4), khóa Valkey, outbox (§8.2), ánh xạ ngoại lệ sang mã lỗi (§8.4) |
| D03-03-PH03 | [CSDL Cổng API](../csdl/D03-03-PH03-csdl-cong-api.md) | Bảng `idempotency_key`, `outbox`, RLS |
| D02-08 | Ma trận phân quyền | `PERM-03-*`, vai trò, cặp bốn mắt |
| D03-01 §4.3 | SAD | Đơn vị `apisix`, `dh-connect`, vùng mạng Z1, Z2 |
| D03-07 | Thiết kế ATTT | SEC-24 (xác thực), SEC-25 (thu hồi), SEC-26 (OPA), SEC-32 (che dữ liệu), SEC-80 (tenant) |
| ADR-005, ADR-033, ADR-042, ADR-070 | Quyết định về APISIX, lớp biên, outbox, tương thích lược đồ | Lý do của các lựa chọn |
| CMP-LAW-05, 08, 09, 16 | Văn bản pháp lý (D00-01 §7) | Căn cứ pháp lý ở phần Tóm tắt |
| `docs/07-srs/SRS-PH-03-gateway.md` | SRS PH-03 của repo | Nguồn kế thừa, ánh xạ ở chương 8 |

: Tài liệu tham chiếu

### 0.5. Cấu trúc tài liệu

Mười chương theo thứ tự người đọc cần: quy ước và quyền trước, danh mục và sự kiện sau, rồi hợp đồng với bên khác, mã lỗi, kiểm tra, ánh xạ, câu hỏi mở và đặc tả chi tiết.

| Chương | Nội dung |
|---|---|
| 1 | Quy ước chung: đường gốc, phiên bản, khóa lạc quan, chống trùng, phân trang, lỗi |
| 2 | Xác thực và phân quyền: bên gọi, quyền theo operation, bốn mắt, đa tenant |
| 3 | Danh mục 96 endpoint, phủ FR, luồng chính, ví dụ yêu cầu và phản hồi |
| 4 | Danh mục 12 sự kiện, khung sự kiện, tương thích, kênh nhanh Valkey |
| 5 | Hợp đồng với PH-01, 02, 12, 13, 20, với bên gọi qua cổng và với nút gateway |
| 6 | Bảng mã lỗi ERR-03 và thông điệp |
| 7 | Kiểm tra hợp đồng trong CI |
| 8 | Ánh xạ từ hệ cũ |
| 9 | Câu hỏi mở |
| 10 | Đặc tả từng endpoint (sinh từ OpenAPI) |

: Cấu trúc tài liệu

## 1. Quy ước chung

Chương này chốt những quy tắc áp cho mọi operation để các chương sau không phải lặp lại. Quy ước giống PH-04, PH-05 và PH-19 để giao diện quản trị dùng chung một lớp gọi API; điểm khác là PH-03 phân trang theo `page`, `size` (D00-04 §4) vì dữ liệu nằm ở PostgreSQL với số bản ghi vừa phải, riêng nhật ký lượt gọi đọc từ ClickHouse nên có câu hỏi riêng (Q03-56).

### 1.1. Bảng quy ước

Bảng gom các quy ước áp cho mọi operation; mỗi dòng là một quy tắc mà kiểm thử viên có thể dựng thành ca kiểm thử và kỹ sư có thể kiểm bằng bộ luật Spectral.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/gateway/v1`. Người dùng qua BFF console của tenant; PH-01, PH-12, PH-13 qua dịch vụ `dh-connect.dh-control.svc` trong cụm |
| Phiên bản | Đường dẫn `v1`. Thay đổi phá vỡ sang `v2`, chạy song song ít nhất 6 tháng; `oasdiff` ở CI-5 chặn thay đổi phá vỡ trong `v1` |
| Tenant | Lấy từ claim `tenant` của token, không bao giờ từ đường dẫn hay thân. Đối tượng của tenant khác trả `404` ERR-03-001, không phân biệt với "không tồn tại" |
| Mã đối tượng | `routeCode` (`^[a-z][a-z0-9.-]{2,126}$`, ví dụ `tra-cuu-ho-tich.v1`), `consumerCode` (`^[a-z][a-z0-9-]{2,62}$`, trùng `clientId`); bất biến, không dùng lại kể cả sau khi gỡ |
| Hành động | Hậu tố `:{động-từ}` trên tài nguyên theo AIP-136: `:stop`, `:start`, `:suspend`, `:resume`, `:approve`, `:reject`, `:revoke`, `:retire`, `:renew`, `:acknowledge`, `:validate`, `:build`, `:publish`, `:rollback`, `:export`, `:import`, `:apply`, `:end` |
| Khóa lạc quan | `GET` trả `ETag` (số `version` của bản ghi). Mọi `PUT`, `PATCH`, `DELETE` và hành động đổi trạng thái bắt buộc `If-Match`; lệch trả ERR-03-004 (`412`) kèm `currentEtag`. Ngoại lệ có `If-Match` tùy chọn: API-03-013, 014 (PH-01 gọi lại trong saga) và API-03-017, 019 (tạm ngừng khẩn cấp không được chậm vì tranh chấp phiên bản) |
| Chống trùng | 17 operation tạo, phát, xuất, đẩy thu hồi bắt buộc `Idempotency-Key` (16 đến 128 ký tự, giữ 24 giờ ở bảng `idempotency_key`). Cùng khóa cùng thân trả đúng phản hồi cũ; cùng khóa khác thân trả ERR-03-003 (SDD §4.13) |
| Phân trang | `page` (từ 1, mặc định 1), `size` (1 đến 100, mặc định 20); phản hồi `items`, `page`, `size`, `totalElements` |
| Lọc, sắp xếp | Tham số truy vấn tên tiếng Anh; giá trị lặp dạng `state=ACTIVE,STOPPED`; tìm tự do `q` (không dấu, tối thiểu 2 ký tự); sắp xếp `sort=-updatedAt` (dấu `-` là giảm dần) |
| Thời gian | ISO 8601 có múi giờ (`2026-11-26T09:14:03+07:00`), lưu UTC. Ranh giới chu kỳ hạn ngạch theo `Asia/Ho_Chi_Minh` |
| Tiến trình dài | Xuất nhật ký, xuất báo cáo, nhập hệ cũ, gia hạn chứng thư trả `202` kèm `Location`; tổng hợp, ký, phát ảnh chụp chạy đồng bộ trong thời hạn của yêu cầu (giả định 1.000 route trong 5 giây, GĐ-03-07) |
| Hai nhánh thành công | Thao tác có bốn mắt trả `200` nếu áp ngay, `202` kèm `ChangeRequest` nếu chờ duyệt (API-03-008, 024, 041, 087); `PUT /consumers/{code}` trả `201` khi tạo mới (API-03-013); tổng hợp thử trả `200` thay `201` (API-03-059 với `dryRun`) |
| Lỗi | RFC 9457 `application/problem+json`; `type` = `https://datahub.gov.vn/errors/ERR-03-nnn`; `code`, `traceId` luôn có |
| Hành động được phép | Route và consumer trả `allowedActions`, `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm (D03-06-PH03) |
| Xóa | Xóa mềm (BR-03-029); `DELETE` trả `204`. Không có thao tác khôi phục |
| Truy vết | `traceparent` (W3C) xuyên BFF, `dh-connect`, Kafka; `traceId` trong mọi lỗi |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail` |
| Bí mật | Không operation nào nhận hay trả bí mật; nhật ký, sự kiện, tệp xuất không chứa thân bản tin, tiêu đề xác thực, giá trị tham số truy vấn (BR-03-007) |

: Quy ước chung của API PH-03

### 1.2. Khóa lạc quan và chống trùng

Hai cơ chế giải hai vấn đề khác nhau và không thay nhau. `If-Match` ngăn hai người sửa đè lên nhau: người thứ hai nhận ERR-03-004 và phải tải lại. `Idempotency-Key` ngăn một lệnh chạy hai lần khi bên gọi gửi lại sau lỗi mạng, điều xảy ra thường xuyên với saga kết nạp của PH-01.

```{.mermaid caption="Trình tự gọi lại an toàn bằng Idempotency-Key (saga PH-01 tạo consumer)"}
sequenceDiagram
  participant P1 as PH-01 saga
  participant CP as dh-connect
  participant DB as pg-core
  P1->>CP: PUT /consumers/ht-qlvb, Idempotency-Key K1
  CP->>DB: Tra idempotency_key theo tenant, operation, K1
  DB-->>CP: Chưa có
  CP->>DB: Lưu consumer, ghi khóa K1 cùng băm thân và phản hồi
  CP-->>P1: 201 Created
  Note over P1,CP: Mất kết nối, PH-01 không nhận được 201
  P1->>CP: PUT /consumers/ht-qlvb, Idempotency-Key K1, cùng thân
  CP->>DB: Tra khóa K1
  DB-->>CP: Có, băm thân trùng
  CP-->>P1: 201 Created, phản hồi cũ, không tạo bản sao
  P1->>CP: PUT /consumers/ht-qlvb, Idempotency-Key K1, thân khác
  CP-->>P1: 400 ERR-03-003
```

Hình cho thấy lần gọi lại cùng khóa và cùng thân không sinh bản sao mà nhận đúng phản hồi cũ; chỉ khi thân khác thì mới bị từ chối. Khóa tính theo bộ ba (tenant, operation, khóa) nên hai tenant dùng cùng một chuỗi khóa không đụng nhau.

### 1.3. Tiêu đề dùng chung

Các tiêu đề HTTP dưới đây có cùng ý nghĩa ở mọi operation nên chỉ liệt kê một lần; tiêu đề riêng của từng operation nằm ở chương 10.

| Tiêu đề | Chiều | Ý nghĩa |
|---|---|---|
| `Authorization: Bearer` | Yêu cầu | Token từ Keycloak (người dùng qua BFF không thấy tiêu đề này) |
| `traceparent` | Yêu cầu, phản hồi | W3C Trace Context; sinh mới nếu thiếu |
| `Accept-Language` | Yêu cầu | `vi` hoặc `en` |
| `If-Match` | Yêu cầu | ETag của bản ghi (mục 1.1) |
| `Idempotency-Key` | Yêu cầu | Khóa chống trùng (mục 1.1) |
| `ETag` | Phản hồi | Phiên bản bản ghi, trả ở `GET` chi tiết |
| `Location` | Phản hồi | Tài nguyên mới tạo (`201`) hoặc tài nguyên theo dõi tiến trình (`202`) |
| `Retry-After` | Phản hồi | Giây chờ, có ở `429` và `503` |
| `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` | Phản hồi | Do cổng đặt: API quản trị là một route của chính cổng nên chịu hạn mức như mọi API (FR-03-025); vượt thì `429` ERR-03-116 hoặc 118 |

: Tiêu đề dùng chung

### 1.4. Thân lỗi

Ví dụ lỗi khi `If-Match` sai:

```json
{
  "type": "https://datahub.gov.vn/errors/ERR-03-004",
  "title": "Xung đột phiên bản bản ghi",
  "status": 412,
  "detail": "Consumer ht-qlvb đã được sửa bởi người khác. Tải lại rồi thử lại.",
  "code": "ERR-03-004",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "currentEtag": "\"4\""
}
```

Ví dụ lỗi nhiều trường (ERR-03-003):

```json
{
  "type": "https://datahub.gov.vn/errors/ERR-03-003",
  "title": "Dữ liệu không hợp lệ",
  "status": 400,
  "code": "ERR-03-003",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [
    {"field": "certThumbprints[0]", "rule": "pattern", "message": "Phải là SHA-256 dạng hex 64 ký tự."},
    {"field": "certNotAfter", "rule": "required", "message": "Bắt buộc khi authMethod là MTLS."}
  ]
}
```

Lược đồ đầy đủ là `ProblemDetails` trong OpenAPI. Hai trường hợp chưa có mã ERR-03: `401` do lớp xác thực và `500` do lỗi nội bộ dùng lược đồ `GenericProblem` (có `type`, `title`, `status`, `traceId`, không có `code`; Q03-55); `429` do cổng trả theo `GatewayProblem` (ERR-03-116, 118). Trường mở rộng có điều kiện: `errors[]` (ERR-03-003), `findings[]` (ERR-03-005, 012, 013), `currentEtag` (ERR-03-004), `ceiling` (ERR-03-018), `ruleId`, `existingExpiresAt` (ERR-03-010), `activeSubscriptions` (ERR-03-017), `detectDays`, `requiredDays` (ERR-03-027), `retryAfterSeconds` (503).

## 2. Xác thực và phân quyền

Có bốn loại bên gọi, mỗi loại dùng một cách xác thực riêng và một tập quyền riêng. Quyền chức năng của người dùng là `PERM-03-*` (D02-08); tài khoản máy dùng scope dịch vụ `gateway:*`, cấp theo dịch vụ chứ không cấp cho người.

### 2.1. Bên gọi và cách xác thực

Mỗi loại bên gọi dùng một cách xác thực và một tập operation riêng; bảng dưới ghép ba thứ đó với nhau.

| Bên gọi | Luồng OAuth | Kiểm quyền | API-03- |
|---|---|---|---|
| Người dùng console (PA, PO, TA, TO, SO, AU) | OIDC Authorization Code + PKCE qua BFF; token ở BFF, không ra trình duyệt | `PERM-03-*` theo vai trò; bốn mắt kiểm ở máy chủ | Mọi operation trừ API-03-013, 014, 015, 053 |
| PH-01 (module `onboarding`, saga kết nạp) | `client_credentials` + `private_key_jwt`, scope `gateway:sync`; hỏi trạng thái đồng bộ trong tiến trình qua `GatewaySyncStatusApi` (cùng DU `dh-connect`) | Scope | 013, 014, 015 |
| PH-12 | `client_credentials`, scope `gateway:revoke` | Scope | 053 |
| PH-13 | `client_credentials`, scope `gateway:read-state` | Scope | Các `GET` ở bảng dưới (Q03-58) |

: Bên gọi và cách xác thực

Scope `gateway:read-state` dành cho PH-13 đọc cấu hình và trạng thái nút: API-03-001, 002, 011, 012, 056, 057, 063, 064. Các `GET` còn lại cần `PERM-03-read` của người dùng. Phạm vi chính xác chờ PH-13 xác nhận (Q03-58). Token dịch vụ gắn một tenant; gọi sang tenant khác trả `404` ERR-03-001. Gọi thiếu scope trả `403` ERR-03-022.

### 2.2. Quyền theo operation

Bảng dưới đếm theo quyền; cột "Cho phép" tóm tắt D02-08 và FRS §3.2. Quyền theo từng operation nằm ở cột "Quyền" của chương 3 và mục "Quyền" của chương 10.

<!-- gen:perm:start -->
| Quyền hoặc scope | Cho phép | Người giữ | API-03- | Số API |
|---|---|---|---|---|
| `PERM-03-read` | Xem cấu hình, route, consumer, hạn mức, nút, tổng quan | PA, PO, TA, TO, SO, AU | 001, 002, 005, 006, 007, 011, 012, 016, 021, 022, 023, 025 và 29 API khác | 41 |
| `PERM-03-admin` | Chính sách gateway: tham số, mẫu chính sách, chứng thư biên, CORS, chạy thử, nhập hệ cũ, chuyển tiếp tenant | PA, TA, SO | 008, 009, 010, 033, 034, 051, 067, 081, 082, 083, 087, 088 và 5 API khác | 17 |
| `PERM-03-limit` | Hạn mức toàn tenant, ghi đè hạn mức | PA, TA | 024, 026, 027, 028 | 4 |
| `PERM-03-waf-request` | Đề nghị ngoại lệ WAF, xem sự kiện chặn của WAF | PA, TA, TO, SO | 039, 042, 043, 047 | 4 |
| `PERM-03-waf-approve` | Duyệt, từ chối ngoại lệ WAF | SO | 044, 045 | 2 |
| `PERM-03-waf` | Đổi chế độ WAF, luật vá ảo, chặn và bỏ chặn địa chỉ, thu hồi ngoại lệ | PA, SO | 037, 038, 041, 046, 048, 049 | 6 |
| `PERM-03-operate` | Dừng, mở, tạm ngừng khẩn cấp, quay lui, gia hạn chứng thư, xác nhận cảnh báo | PA, TA, TO, SO | 003, 004, 017, 018, 019, 020, 061, 070 và 1 API khác | 9 |
| `PERM-03-publish` | Kiểm tra, xây, phát ảnh chụp cấu hình | PA, TA | 058, 059, 060 | 3 |
| `PERM-03-approve` | Duyệt yêu cầu thay đổi bốn mắt | TA, SO | 072, 073 | 2 |
| `PERM-03-log-read` | Nhật ký lượt gọi chi tiết, xuất nhật ký và báo cáo | PA, TA, TO, SO, AU | 074, 075, 076, 090 | 4 |
| `gateway:sync` | Tạo, cập nhật, gỡ consumer (PH-01, saga kết nạp) | Tài khoản dịch vụ PH-01 | 013, 014, 015 | 3 |
| `gateway:revoke` | Đẩy danh sách chặn token (PH-12) | Tài khoản dịch vụ PH-12 | 053 | 1 |

: Quyền và scope theo số API
<!-- gen:perm:end -->

Tám quyền `PERM-03-limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read` chưa có ở D02-08 §3.1 (mới có `read`, `admin`); đã ghi vào đề nghị đồng bộ của FRS và nhắc lại ở cuối tài liệu này.

### 2.3. Quy tắc vượt quyền chức năng

Có quyền chức năng là điều kiện cần, chưa đủ. Máy chủ còn kiểm các quy tắc sau trước khi thực hiện.

1. **Bốn mắt (BR-03-019).** Bốn nhóm thay đổi chỉ có hiệu lực sau khi tài khoản thứ hai duyệt: ngoại lệ WAF (đề nghị API-03-043, duyệt API-03-044 hoặc 045 bởi SO); đổi chế độ WAF (đề nghị API-03-041, duyệt API-03-072 hoặc 073); route ra cửa Internet (đề nghị API-03-008, duyệt API-03-072 hoặc 073); hạ hạn mức tenant hoặc đổi khóa `gw.*` có bốn mắt (đề nghị API-03-024, 087, duyệt API-03-072 hoặc 073). So người duyệt với người đề nghị theo **tài khoản**, không theo vai trò; trùng trả `403` ERR-03-008. Hai đường duyệt khác nhau vì ngoại lệ WAF chỉ SO duyệt (`PERM-03-waf-approve`), còn ba nhóm kia TA hoặc SO duyệt (`PERM-03-approve`).
2. **Tenant nhỏ.** Tenant chỉ có một SO thì khi bật cờ `gw.approval.substitute` PA duyệt thay và kiểm toán ghi "duyệt thay" (Q03-02 của FRS).
3. **Tạm ngừng khẩn cấp (API-03-017, 019).** Có hiệu lực ngay, không cần người duyệt, nhưng bắt buộc có lý do 10 đến 500 ký tự; sinh kiểm toán, EVT-03-03 hoặc EVT-03-04 và EVT-03-09. Mở lại (API-03-018, 020) cũng cần `PERM-03-operate` và ghi lý do.
4. **Phạm vi `PLATFORM`.** `scope=PLATFORM` ở API-03-058, 059, 061 (ảnh chụp phần dùng chung của nền tảng) chỉ PA ở phiên `PLATFORM`; vai trò khác trả `403` ERR-03-022.
5. **Địa chỉ nguồn.** `srcIp` trong nhật ký lượt gọi (API-03-074, 075) và trong sự kiện chặn WAF (API-03-039) chỉ trả cho người có `PERM-03-log-read` hoặc `PERM-03-waf-request`; xem chi tiết hoặc xuất đều ghi kiểm toán (Q03-48 của tập use case).
6. **Địa chỉ được bảo vệ.** Không chặn được địa chỉ thuộc danh sách tin cậy hoặc hạ tầng (`gw.ip.trustedCidrs`, dải NDXP, bộ giám sát): ERR-03-024.
7. **Mẫu chính sách.** Chỉ bật được plugin và mẫu trong danh mục được duyệt (ERR-03-013); tenant không tự đưa plugin mới.

### 2.4. Đa tenant

Mỗi truy vấn của `dh-connect` chạy với `app.tenant_id` lấy từ token và bị ràng buộc bởi RLS (`FORCE ROW LEVEL SECURITY`, D03-03-PH03 §1.2). Hệ quả cho hợp đồng:

- Không có tham số tenant ở đường dẫn hay thân; gửi `tenantId` trong thân bị bỏ qua (và bị kiểm thử rò rỉ chéo tenant dò tìm).
- Đối tượng thuộc tenant khác không phân biệt được với đối tượng không tồn tại: cùng `404` ERR-03-001, cùng thời gian đáp ứng.
- `COMMON` là tenant toàn quốc giữ phần dùng chung (tham số `gw.*` mặc định, chứng thư dùng chung, CA của HTTT, luật vá WAF phạm vi nền tảng). Tenant tỉnh chỉ đọc; ghi vào `COMMON` chỉ phiên `PLATFORM` của PA. `GET /settings` trả giá trị hiệu lực đã hợp `COMMON` và phần ghi đè của tenant.
- Tenant ở lượt gọi qua cổng cũng chỉ lấy từ token đã xác minh; mọi tiêu đề `X-DH-*` do khách gửi bị xóa (mục 5.4).
- Ánh xạ trường với cột (D03-03-PH03): `If-Match` ứng với cột `version`; `Idempotency-Key` ứng với `idempotency_key.idem_key`; lỗi `unique_violation` của `uq_edge_host_pattern` được ánh xạ về ERR-03-002 với thân chung, không nêu host thuộc tenant nào (BR-03-028).

## 3. Danh mục endpoint

Mỗi operation có đúng một mã `API-03-nnn` (không dùng chung mã cho hai operation) và khớp từng dòng với danh mục ở FRS §9.4; script kiểm tra hợp đồng so hai bên và báo lỗi khi lệch. Chương này gồm danh mục theo nhóm (3.1), bảng phủ 59 FR (3.2), hai luồng chính qua API (3.3) và ví dụ yêu cầu, phản hồi của các operation quan trọng (3.4). Tham số, lược đồ và mô tả lỗi của từng operation nằm ở OpenAPI và ở chương 10.

### 3.1. Danh mục theo nhóm

Cột "Quyền" là `PERM-03-…` của người dùng hoặc scope dịch vụ. Cột "Thành công" ghi mã mặc định; mã trong ngoặc là nhánh thành công thứ hai (mục 1.1).

<!-- gen:endpoints:start -->
**Route và upstream**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-001 | `GET /routes` | Danh sách route | 028 | `PERM-03-read` |  | 200 |
| API-03-002 | `GET /routes/{routeCode}` | Chi tiết route | 009, 017, 028, 033, 034, 035 | `PERM-03-read` |  | 200 |
| API-03-003 | `POST /routes/{routeCode}:stop` | Dừng API | 036 | `PERM-03-operate` |  | 200 |
| API-03-004 | `POST /routes/{routeCode}:start` | Mở API | 036 | `PERM-03-operate` |  | 200 |
| API-03-005 | `GET /upstreams` | Danh sách upstream | 029 | `PERM-03-read` |  | 200 |
| API-03-006 | `GET /upstreams/{upstreamCode}` | Chi tiết upstream | 029, 030 | `PERM-03-read` |  | 200 |
| API-03-007 | `GET /routes/{routeCode}/versions` | Các phiên bản API song song của route | 035 | `PERM-03-read` |  | 200 |
| API-03-008 | `PUT /routes/{routeCode}/exposure` | Đặt cửa vào của route (EXT cần bốn mắt) | 038 | `PERM-03-admin` |  | 200 (202) |
| API-03-009 | `PUT /routes/{routeCode}/request-limits` | Đặt giới hạn kích thước và cấu trúc yêu cầu | 009 | `PERM-03-admin` |  | 200 |
| API-03-010 | `PUT /routes/{routeCode}/timeouts` | Đặt thời hạn chờ của route | 031 | `PERM-03-admin` |  | 200 |

: Danh mục endpoint · Route và upstream

**Consumer**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-011 | `GET /consumers` | Danh sách consumer | 046 | `PERM-03-read` |  | 200 |
| API-03-012 | `GET /consumers/{consumerCode}` | Chi tiết consumer | 014, 016, 046 | `PERM-03-read` |  | 200 |
| API-03-013 | `PUT /consumers/{consumerCode}` | Tạo hoặc cập nhật consumer | 046 | `gateway:sync` (dịch vụ) | có | 200 (201) |
| API-03-014 | `PUT /consumers/{consumerCode}/credentials` | Cập nhật thông tin xác thực công khai của consumer | 046 | `gateway:sync` (dịch vụ) | có | 200 |
| API-03-015 | `DELETE /consumers/{consumerCode}` | Gỡ consumer | 046 | `gateway:sync` (dịch vụ) | có | 204 |
| API-03-016 | `GET /consumers/{consumerCode}/credentials` | Thông tin xác thực công khai của consumer | 002, 014 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Consumer

**Tạm ngừng khẩn cấp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-017 | `POST /consumers/{consumerCode}:suspend` | Tạm ngừng khẩn cấp consumer | 047 | `PERM-03-operate` |  | 200 |
| API-03-018 | `POST /consumers/{consumerCode}:resume` | Mở lại consumer | 047 | `PERM-03-operate` |  | 200 |
| API-03-019 | `POST /routes/{routeCode}:suspend` | Tạm ngừng khẩn cấp route | 047 | `PERM-03-operate` |  | 200 |
| API-03-020 | `POST /routes/{routeCode}:resume` | Mở lại route | 047 | `PERM-03-operate` |  | 200 |

: Danh mục endpoint · Tạm ngừng khẩn cấp

**Chính sách chiếu từ gói**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-021 | `GET /plan-policies` | Danh sách chính sách chiếu từ gói | 015, 016, 020, 021 | `PERM-03-read` |  | 200 |
| API-03-022 | `GET /plan-policies/{policyCode}` | Chi tiết chính sách chiếu từ gói | 015, 017, 020, 021 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Chính sách chiếu từ gói

**Hạn mức và hạn ngạch**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-023 | `GET /tenant-limits` | Hạn mức toàn tenant | 023 | `PERM-03-read` |  | 200 |
| API-03-024 | `PUT /tenant-limits` | Đặt hạn mức toàn tenant (hạ cần bốn mắt) | 023 | `PERM-03-limit` |  | 200 (202) |
| API-03-025 | `GET /rate-limit-overrides` | Danh sách ghi đè hạn mức | 024, 025 | `PERM-03-read` |  | 200 |
| API-03-026 | `POST /rate-limit-overrides` | Tạo ghi đè hạn mức | 024 | `PERM-03-limit` | có | 201 |
| API-03-027 | `PUT /rate-limit-overrides/{overrideId}` | Sửa ghi đè hạn mức | 024 | `PERM-03-limit` |  | 200 |
| API-03-028 | `DELETE /rate-limit-overrides/{overrideId}` | Xóa ghi đè hạn mức | 024 | `PERM-03-limit` |  | 204 |
| API-03-029 | `GET /consumers/{consumerCode}/usage` | Mức dùng hạn mức, hạn ngạch của consumer | 021, 022, 027 | `PERM-03-read` |  | 200 |
| API-03-030 | `GET /quota-alerts` | Cảnh báo ngưỡng hạn ngạch | 022 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Hạn mức và hạn ngạch

**Lớp biên và TLS**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-031 | `GET /edge/tls-profile` | Hồ sơ TLS đang áp dụng ở hai cửa vào | 001 | `PERM-03-read` |  | 200 |
| API-03-032 | `GET /tls-exceptions` | Danh sách ngoại lệ TLS 1.2 | 001 | `PERM-03-read` |  | 200 |
| API-03-033 | `POST /tls-exceptions` | Tạo ngoại lệ TLS 1.2 có thời hạn | 001 | `PERM-03-admin` | có | 201 |
| API-03-034 | `POST /tls-exceptions/{exceptionId}:revoke` | Thu hồi ngoại lệ TLS 1.2 | 001 | `PERM-03-admin` |  | 200 |
| API-03-035 | `GET /edge/client-ca-bundles` | Bộ CA tin cậy cho chứng thư khách mTLS | 002, 049 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Lớp biên và TLS

**Chặn địa chỉ nguồn**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-036 | `GET /ip-blocks` | Danh sách địa chỉ đang bị chặn | 003, 004 | `PERM-03-read` |  | 200 |
| API-03-037 | `POST /ip-blocks` | Chặn địa chỉ nguồn thủ công | 004 | `PERM-03-waf` | có | 201 |
| API-03-038 | `DELETE /ip-blocks/{blockId}` | Bỏ chặn địa chỉ nguồn | 004 | `PERM-03-waf` |  | 204 |

: Danh mục endpoint · Chặn địa chỉ nguồn

**WAF**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-039 | `GET /waf/events` | Sự kiện chặn của WAF | 005 | `PERM-03-waf-request` |  | 200 |
| API-03-040 | `GET /waf/mode` | Chế độ WAF và điều kiện chuyển sang chặn | 006 | `PERM-03-read` |  | 200 |
| API-03-041 | `PUT /waf/mode` | Đổi chế độ WAF (cần bốn mắt) | 006 | `PERM-03-waf` |  | 200 (202) |
| API-03-042 | `GET /waf/exceptions` | Danh sách ngoại lệ luật WAF | 007 | `PERM-03-waf-request` |  | 200 |
| API-03-043 | `POST /waf/exceptions` | Đề nghị ngoại lệ luật WAF | 007 | `PERM-03-waf-request` | có | 201 |
| API-03-044 | `POST /waf/exceptions/{exceptionId}:approve` | Duyệt ngoại lệ luật WAF | 007 | `PERM-03-waf-approve` |  | 200 |
| API-03-045 | `POST /waf/exceptions/{exceptionId}:reject` | Từ chối ngoại lệ luật WAF | 007 | `PERM-03-waf-approve` |  | 200 |
| API-03-046 | `POST /waf/exceptions/{exceptionId}:revoke` | Thu hồi ngoại lệ luật WAF | 007 | `PERM-03-waf` |  | 200 |
| API-03-047 | `GET /waf/virtual-patches` | Danh sách luật vá ảo | 008 | `PERM-03-waf-request` |  | 200 |
| API-03-048 | `POST /waf/virtual-patches` | Tạo luật vá ảo khẩn cấp | 008 | `PERM-03-waf` | có | 201 |
| API-03-049 | `POST /waf/virtual-patches/{patchId}:retire` | Gỡ luật vá ảo | 008 | `PERM-03-waf` |  | 200 |

: Danh mục endpoint · WAF

**CORS**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-050 | `GET /cors-policies` | Danh sách chính sách CORS theo route | 010 | `PERM-03-read` |  | 200 |
| API-03-051 | `PUT /cors-policies/{routeCode}` | Đặt chính sách CORS của route | 010 | `PERM-03-admin` |  | 200 |

: Danh mục endpoint · CORS

**Xác thực, thu hồi, ủy quyền**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-052 | `GET /auth/jwks-status` | Trạng thái bộ đệm JWKS của các nút | 012 | `PERM-03-read` |  | 200 |
| API-03-053 | `POST /revocations` | Thu hồi token (danh sách chặn) | 018 | `gateway:revoke` (dịch vụ) | có | 201 |
| API-03-054 | `GET /revocations` | Danh sách thu hồi token còn hiệu lực | 018 | `PERM-03-read` |  | 200 |
| API-03-055 | `GET /authorization-bindings` | Chính sách OPA gắn với từng route | 019 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Xác thực, thu hồi, ủy quyền

**Ảnh chụp cấu hình**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-056 | `GET /snapshots` | Danh sách ảnh chụp cấu hình | 039, 044 | `PERM-03-read` |  | 200 |
| API-03-057 | `GET /snapshots/{version}` | Chi tiết ảnh chụp cấu hình | 039, 041 | `PERM-03-read` |  | 200 |
| API-03-058 | `POST /snapshots:validate` | Kiểm tra hợp lệ cấu hình tổng hợp thử | 040 | `PERM-03-publish` |  | 200 |
| API-03-059 | `POST /snapshots:build` | Tổng hợp, kiểm tra và ký ảnh chụp cấu hình | 039, 040, 041 | `PERM-03-publish` | có | 201 (200) |
| API-03-060 | `POST /snapshots/{version}:publish` | Phát ảnh chụp cấu hình tới Git và bucket | 042 | `PERM-03-publish` | có | 200 |
| API-03-061 | `POST /snapshots/{version}:rollback` | Quay lui bằng ảnh chụp mới mang nội dung bản cũ | 044 | `PERM-03-operate` | có | 201 |
| API-03-062 | `GET /snapshots/{version}/diff` | So sánh ảnh chụp với bản đang chạy | 044 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Ảnh chụp cấu hình

**Nút gateway**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-063 | `GET /nodes` | Danh sách nút gateway và trạng thái đồng bộ | 043, 045 | `PERM-03-read` |  | 200 |
| API-03-064 | `GET /nodes/{nodeId}` | Chi tiết nút gateway | 043, 045 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Nút gateway

**Mẫu chính sách**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-065 | `GET /policy-templates` | Danh mục mẫu chính sách được duyệt | 020, 048 | `PERM-03-read` |  | 200 |
| API-03-066 | `GET /policy-templates/{templateCode}` | Chi tiết mẫu chính sách | 015, 048 | `PERM-03-read` |  | 200 |
| API-03-067 | `PUT /policy-templates/{templateCode}/enablement` | Bật, tắt mẫu chính sách cho tenant | 048 | `PERM-03-admin` |  | 200 |

: Danh mục endpoint · Mẫu chính sách

**Chứng thư biên**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-068 | `GET /certificates` | Danh sách chứng thư biên | 049 | `PERM-03-read` |  | 200 |
| API-03-069 | `GET /certificates/{certCode}` | Chi tiết chứng thư biên | 049 | `PERM-03-read` |  | 200 |
| API-03-070 | `POST /certificates/{certCode}:renew` | Gia hạn chứng thư biên thủ công | 049 | `PERM-03-operate` |  | 202 |

: Danh mục endpoint · Chứng thư biên

**Yêu cầu thay đổi bốn mắt**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-071 | `GET /change-requests` | Danh sách yêu cầu thay đổi chờ duyệt | 006, 023, 038 | `PERM-03-read` |  | 200 |
| API-03-072 | `POST /change-requests/{requestId}:approve` | Duyệt yêu cầu thay đổi | 006, 023, 038 | `PERM-03-approve` |  | 200 |
| API-03-073 | `POST /change-requests/{requestId}:reject` | Từ chối yêu cầu thay đổi | 006, 023, 038 | `PERM-03-approve` |  | 200 |

: Danh mục endpoint · Yêu cầu thay đổi bốn mắt

**Nhật ký lượt gọi**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-074 | `GET /access-logs` | Tra cứu nhật ký lượt gọi | 050, 051 | `PERM-03-log-read` |  | 200 |
| API-03-075 | `GET /access-logs/{logId}` | Chi tiết một lượt gọi | 051 | `PERM-03-log-read` |  | 200 |
| API-03-076 | `POST /access-logs:export` | Xuất nhật ký lượt gọi | 051 | `PERM-03-log-read` | có | 202 |

: Danh mục endpoint · Nhật ký lượt gọi

**Tổng quan**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-077 | `GET /overview` | Tổng quan lưu lượng và sức khỏe gateway | 026, 052, 055 | `PERM-03-read` |  | 200 |
| API-03-078 | `GET /overview/top-consumers` | HTTT gọi nhiều nhất | 055 | `PERM-03-read` |  | 200 |
| API-03-079 | `GET /overview/top-routes` | Route nhiều lượt gọi hoặc nhiều lỗi nhất | 055 | `PERM-03-read` |  | 200 |

: Danh mục endpoint · Tổng quan

**Kiểm tra tổng hợp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-080 | `GET /synthetic-checks` | Danh sách kiểm tra tổng hợp | 053 | `PERM-03-read` |  | 200 |
| API-03-081 | `POST /synthetic-checks` | Tạo kiểm tra tổng hợp | 053 | `PERM-03-admin` | có | 201 |
| API-03-082 | `PUT /synthetic-checks/{checkId}` | Sửa kiểm tra tổng hợp | 053 | `PERM-03-admin` |  | 200 |
| API-03-083 | `DELETE /synthetic-checks/{checkId}` | Xóa kiểm tra tổng hợp | 053 | `PERM-03-admin` |  | 204 |

: Danh mục endpoint · Kiểm tra tổng hợp

**Cảnh báo an ninh**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-084 | `GET /security-alerts` | Danh sách cảnh báo an ninh của gateway | 054 | `PERM-03-read` |  | 200 |
| API-03-085 | `POST /security-alerts/{alertId}:acknowledge` | Xác nhận đã xử lý cảnh báo | 054 | `PERM-03-operate` |  | 200 |

: Danh mục endpoint · Cảnh báo an ninh

**Tham số**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-086 | `GET /settings` | Tham số gateway của tenant | 003, 011, 056 | `PERM-03-read` |  | 200 |
| API-03-087 | `PUT /settings` | Đổi tham số gateway của tenant | 003, 011, 056 | `PERM-03-admin` |  | 200 (202) |

: Danh mục endpoint · Tham số

**Chạy thử chính sách**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-088 | `POST /simulations` | Chạy thử chính sách bằng mô phỏng | 057 | `PERM-03-admin` |  | 200 |

: Danh mục endpoint · Chạy thử chính sách

**Báo cáo sử dụng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-089 | `GET /reports/usage` | Báo cáo sử dụng API theo HTTT, route, gói | 058 | `PERM-03-read` |  | 200 |
| API-03-090 | `POST /reports/usage:export` | Xuất báo cáo sử dụng | 058 | `PERM-03-log-read` | có | 202 |

: Danh mục endpoint · Báo cáo sử dụng

**Nhập từ gateway cũ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-091 | `POST /migrations/legacy-gateway:import` | Tải gói cấu hình gateway cũ để phân tích | 059 | `PERM-03-admin` | có | 202 |
| API-03-092 | `GET /migrations/legacy-gateway/{importId}` | Kết quả phân tích gói gateway cũ | 059 | `PERM-03-admin` |  | 200 |
| API-03-093 | `POST /migrations/legacy-gateway/{importId}:apply` | Áp đề xuất nhập thành cấu hình nháp | 059 | `PERM-03-admin` |  | 200 |

: Danh mục endpoint · Nhập từ gateway cũ

**Chuyển tiếp tenant sáp nhập**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-03-094 | `GET /tenant-redirects` | Danh sách chuyển tiếp tenant sáp nhập | 037 | `PERM-03-read` |  | 200 |
| API-03-095 | `POST /tenant-redirects` | Tạo chuyển tiếp tenant sáp nhập | 037 | `PERM-03-admin` | có | 201 |
| API-03-096 | `POST /tenant-redirects/{redirectId}:end` | Kết thúc chuyển tiếp tenant sáp nhập | 037 | `PERM-03-admin` |  | 200 |

: Danh mục endpoint · Chuyển tiếp tenant sáp nhập
<!-- gen:endpoints:end -->

### 3.2. Phủ chức năng bằng API

Nguyên tắc: mỗi FR có ít nhất một API, hoặc được ghi rõ là chỉ ở mặt phẳng dữ liệu. PH-03 là cổng chuyển tiếp nên nhiều FR (xác minh JWT, hạn mức, WAF, định tuyến) chạy trong APISIX và không có API; phần cấu hình và quan sát của chúng vẫn có API ở chương này. FR "không có API quản trị" không phải thiếu sót mà là hành vi thuần của plugin, kiểm bằng ca kiểm thử qua cổng ở D05-02-PH03.

<!-- gen:frmap:start -->
| FR | Nhóm | Chức năng | API-03- |
|---|---|---|---|
| FR-03-001 | A | Kết thúc TLS tại hai cửa vào | 031, 032, 033, 034 |
| FR-03-002 | A | Xác minh chứng thư khách mTLS | 016, 035 |
| FR-03-003 | A | Giới hạn kết nối và tốc độ theo địa chỉ nguồn | 036, 086, 087 |
| FR-03-004 | A | Chặn tạm địa chỉ nguồn vi phạm liên tục | 036, 037, 038 |
| FR-03-005 | A | WAF Coraza với bộ luật OWASP CRS | 039 |
| FR-03-006 | A | Chế độ phát hiện, chặn của WAF và tự hạ khi quá tải | 040, 041, 071, 072, 073 |
| FR-03-007 | A | Ngoại lệ luật WAF có thời hạn | 042, 043, 044, 045, 046 |
| FR-03-008 | A | Luật vá ảo khẩn cấp | 047, 048, 049 |
| FR-03-009 | A | Kiểm tra lược đồ và giới hạn kích thước yêu cầu | 002, 009 |
| FR-03-010 | A | Xử lý CORS | 050, 051 |
| FR-03-011 | A | Tiêu đề bảo mật và che thông tin máy chủ | 086, 087 |
| FR-03-012 | B | Xác minh chữ ký JWT cục bộ | 052 |
| FR-03-013 | B | Xác định tenant của lượt gọi | Mặt phẳng dữ liệu, không có API quản trị |
| FR-03-014 | B | Ràng buộc token với chứng thư khách | 012, 016 |
| FR-03-015 | B | Áp phương thức bảo mật theo gói sử dụng | 021, 022, 066 |
| FR-03-016 | B | Kiểm tra đăng ký sử dụng và hiệu lực gói | 012, 021 |
| FR-03-017 | B | Kiểm tra phạm vi quyền thô | 002, 022 |
| FR-03-018 | B | Thu hồi token nhanh bằng danh sách chặn | 053, 054 |
| FR-03-019 | B | Ủy quyền chi tiết bằng OPA tại gateway | 055 |
| FR-03-020 | B | Danh sách cho phép và chặn đường dẫn | 021, 022, 065 |
| FR-03-021 | C | Giới hạn tần suất theo bên gọi | 021, 022, 029 |
| FR-03-022 | C | Hạn ngạch theo chu kỳ và cảnh báo ngưỡng | 029, 030 |
| FR-03-023 | C | Hạn mức toàn tenant | 023, 024, 071, 072, 073 |
| FR-03-024 | C | Hạn mức theo route và thứ tự ưu tiên chính sách | 025, 026, 027, 028 |
| FR-03-025 | C | Phản hồi vượt hạn mức và tiêu đề hạn mức | 025 |
| FR-03-026 | C | Suy giảm có kiểm soát khi Valkey mất | 077 |
| FR-03-027 | C | Điều tiết theo tình trạng backend | 029 |
| FR-03-028 | D | Định tuyến theo host, đường dẫn, phương thức | 001, 002 |
| FR-03-029 | D | Cân bằng tải giữa các backend | 005, 006 |
| FR-03-030 | D | Kiểm tra sức khỏe backend chủ động và thụ động | 006 |
| FR-03-031 | D | Thời hạn chờ, ngắt mạch và trả lỗi nhanh | 010 |
| FR-03-032 | D | Sinh và truyền định danh truy vết | Mặt phẳng dữ liệu, không có API quản trị |
| FR-03-033 | D | Chuyển tiếp WebSocket và nén nội dung | 002 |
| FR-03-034 | D | Chuyển đổi gRPC và REST | 002 |
| FR-03-035 | D | Phiên bản API song song và tiêu đề ngừng dùng | 002, 007 |
| FR-03-036 | D | Dừng và mở API tức thời | 003, 004 |
| FR-03-037 | D | Chuyển tiếp lượt gọi của tenant đã sáp nhập | 094, 095, 096 |
| FR-03-038 | D | Phân cửa vào Internet và mạng nội bộ | 008, 071, 072, 073 |
| FR-03-039 | E | Tổng hợp cấu hình gateway từ danh mục | 056, 057, 059 |
| FR-03-040 | E | Kiểm tra hợp lệ cấu hình trước khi phát | 058, 059 |
| FR-03-041 | E | Sinh ảnh chụp cấu hình có phiên bản và chữ ký | 057, 059 |
| FR-03-042 | E | Phát ảnh chụp tới Git và bucket | 060 |
| FR-03-043 | E | Nạp ảnh chụp ở nút gateway | 063, 064 |
| FR-03-044 | E | Quay lui về phiên bản cấu hình trước | 056, 061, 062 |
| FR-03-045 | E | Theo dõi nút và trạng thái đồng bộ | 063, 064 |
| FR-03-046 | E | Đồng bộ consumer và thông tin xác thực công khai | 011, 012, 013, 014, 015 |
| FR-03-047 | E | Tạm ngừng khẩn cấp route hoặc consumer | 017, 018, 019, 020 |
| FR-03-048 | E | Bộ mẫu chính sách gateway được duyệt sẵn | 065, 066, 067 |
| FR-03-049 | E | Quản lý chứng thư biên | 035, 068, 069, 070 |
| FR-03-050 | F | Ghi siêu dữ liệu lượt gọi có che dữ liệu | 074 |
| FR-03-051 | F | Tra cứu và xuất nhật ký lượt gọi | 074, 075, 076 |
| FR-03-052 | F | Phát chỉ số và vết OpenTelemetry | 077 |
| FR-03-053 | F | Kiểm tra tổng hợp cho API quan trọng | 080, 081, 082, 083 |
| FR-03-054 | F | Cảnh báo sự kiện an ninh tại gateway | 084, 085 |
| FR-03-055 | F | Bảng điều khiển lưu lượng gateway | 077, 078, 079 |
| FR-03-056 | G | Tham số gateway theo tenant | 086, 087 |
| FR-03-057 | G | Chạy thử chính sách bằng mô phỏng | 088 |
| FR-03-058 | G | Báo cáo sử dụng API theo HTTT và gói | 089, 090 |
| FR-03-059 | G | Nhập cấu hình từ gateway cũ | 091, 092, 093 |

: Phủ chức năng FR-03 bằng API
<!-- gen:frmap:end -->

### 3.3. Luồng chính qua API

**Luồng phát cấu hình.** Phần lớn thay đổi (PH-02 công bố API, PH-01 tạo consumer) tự kích hoạt tổng hợp sau 3 giây gom sự kiện (`gw.snapshot.debounceSeconds`) mà không cần gọi API. Người vận hành gọi API khi muốn tổng hợp thử, phát thủ công hoặc quay lui.

```{.mermaid caption="Trình tự tổng hợp, ký, phát và nút nạp ảnh chụp cấu hình"}
sequenceDiagram
  actor OP as Quản trị tenant
  participant CP as dh-connect
  participant SRC as PH-01, 02, 12, 20
  participant BAO as OpenBao
  participant BK as Bucket và Git
  participant AX as Nút APISIX
  OP->>CP: POST /snapshots:validate, scope TENANT
  CP->>SRC: Đọc API, gói, đăng ký, HTTT, host
  CP-->>OP: 200 ValidationReport, valid true
  OP->>CP: POST /snapshots:build, Idempotency-Key
  CP->>CP: Tổng hợp, kiểm tra CHK-01 đến CHK-18
  CP->>BAO: Ký băm manifest
  BAO-->>CP: Chữ ký ECDSA P-256
  CP-->>OP: 201 Snapshot, state SIGNED
  OP->>CP: POST /snapshots/48213:publish, If-Match
  CP->>BK: Ghi bucket, rồi Git
  CP-->>OP: 200 Snapshot, state PUBLISHED
  AX->>BK: Mỗi 5 giây đọc con trỏ current
  AX->>AX: Kiểm chữ ký, nạp, không nạp lùi
  OP->>CP: GET /nodes
  CP-->>OP: 200 Node, syncState IN_SYNC
```

Hình cho thấy ba điểm cần nhớ. Một, kiểm tra không đạt dừng ở bước build với ERR-03-005 và ảnh chụp không bao giờ tới nút (EVT-03-12). Hai, bước ký phụ thuộc OpenBao: không ký được thì trả ERR-03-015 và cấu hình đang chạy không đổi. Ba, nút tự kéo ảnh chụp (kéo, không đẩy) nên API không cần biết địa chỉ nút; `syncState` suy ra từ chỉ số của nút.

**Luồng bốn mắt cho route ra cửa Internet.**

```{.mermaid caption="Trình tự đề nghị và duyệt đặt route ra cửa Internet"}
sequenceDiagram
  actor TA as Quản trị tenant
  actor SO as Cán bộ ATTT
  participant CP as dh-connect
  participant IN as Hộp việc chung
  TA->>CP: PUT /routes/thanh-toan-callback.v1/exposure, EXT
  CP->>CP: Kiểm điều kiện cửa ngoài, ERR-03-011 nếu thiếu
  CP->>IN: Tạo việc duyệt cho SO
  CP-->>TA: 202 ChangeRequest, state PENDING
  SO->>CP: GET /change-requests, state PENDING
  CP-->>SO: 200 ChangeRequestPage
  SO->>CP: POST /change-requests/{requestId}:approve
  CP->>CP: So người duyệt với người đề nghị, ERR-03-008 nếu trùng
  CP->>CP: Đặt exposure EXT, kích hoạt tổng hợp
  CP-->>SO: 200 ChangeRequest, state APPLIED
```

Hình cho thấy người đề nghị nhận `202` chứ không nhận `200`: cấu hình chưa đổi cho tới khi SO duyệt. Nếu cùng một tài khoản gọi cả hai bước thì bước duyệt bị chặn ngay ở máy chủ. Yêu cầu quá 14 ngày không ai duyệt chuyển `EXPIRED` (`dh.gateway.changeRequest.expireDays`, giả định).

### 3.4. Ví dụ yêu cầu và phản hồi

Các khối JSON dưới đây là ví dụ cho các operation quan trọng; mỗi khối có nhãn lược đồ và được `check_contracts.py` kiểm khớp. Dữ liệu là giả lập.

**Tạo hoặc cập nhật consumer (API-03-013), do saga PH-01 gọi.**

```http
PUT /api/gateway/v1/consumers/ht-qlvb
Authorization: Bearer eyJ…  (token dịch vụ, scope gateway:sync)
Idempotency-Key: 6f1c2b7e-5d0a-4f3e-9a21-0c7b8d1e2f34
Content-Type: application/json
```

<!-- ex:ConsumerUpsert -->
```json
{
  "systemCode": "HT-QLVB",
  "state": "ACTIVE",
  "priorityGroup": "NORMAL",
  "trustedSource": false,
  "authMethod": "MTLS",
  "certThumbprints": ["9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a"],
  "certNotAfter": "2027-06-30T00:00:00+07:00"
}
```

Phản hồi `201 Created`, `Location: /api/gateway/v1/consumers/ht-qlvb`, `ETag: "1"`:

<!-- ex:ConsumerDetail -->
```json
{
  "consumerCode": "ht-qlvb",
  "systemCode": "HT-QLVB",
  "priorityGroup": "NORMAL",
  "trustedSource": false,
  "authMethod": "MTLS",
  "state": "ACTIVE",
  "syncState": "PENDING",
  "certNotAfter": "2027-06-30T00:00:00+07:00",
  "subscriptionCount": 0,
  "updatedAt": "2026-11-26T09:14:03+07:00",
  "createdAt": "2026-11-26T09:14:03+07:00",
  "version": 1,
  "allowedActions": ["suspend"],
  "disabledReasons": {"resume": "Consumer đang hoạt động."}
}
```

Saga hỏi `syncState` cho tới khi `IN_SYNC` (mọi nút của cả hai cửa đã nạp) rồi mới báo HTTT kết nạp xong (FR-03-046). Thân có `clientSecret` hoặc khóa riêng PEM bị từ chối `400` ERR-03-003.

**Dừng API (API-03-003).** `POST /api/gateway/v1/routes/tra-cuu-ho-tich.v1:stop` kèm `If-Match: "7"`:

<!-- ex:RouteStopRequest -->
```json
{
  "reason": "Backend tra cứu hộ tịch đang nâng cấp cơ sở dữ liệu",
  "message": "Dịch vụ tạm dừng để bảo trì, dự kiến mở lại 18:00."
}
```

Phản hồi `200` là `RouteDetail` với `state` bằng `STOPPED`; từ lúc ảnh chụp mới được nạp, lượt gọi tới route nhận `503` ERR-03-123 kèm `Retry-After` và `detail` lấy từ `message`.

**Đề nghị đặt route ra cửa Internet (API-03-008).** `PUT /api/gateway/v1/routes/thanh-toan-callback.v1/exposure` kèm `If-Match: "3"`:

<!-- ex:ExposureUpdate -->
```json
{
  "exposure": "EXT",
  "reason": "Nhà cung cấp thanh toán gọi callback từ Internet",
  "wafParanoia": 1,
  "ipAllowCidrs": ["203.0.113.0/28"]
}
```

Phản hồi `202 Accepted`, `Location: /api/gateway/v1/change-requests/0193a1f2-3c4d-7e5f-8a6b-7c8d9e0f1a2b`:

<!-- ex:ChangeRequest -->
```json
{
  "requestId": "0193a1f2-3c4d-7e5f-8a6b-7c8d9e0f1a2b",
  "changeType": "EXPOSURE_EXT",
  "targetCode": "thanh-toan-callback.v1",
  "payload": {"exposure": "EXT", "wafParanoia": 1, "ipAllowCidrs": ["203.0.113.0/28"]},
  "state": "PENDING",
  "reason": "Nhà cung cấp thanh toán gọi callback từ Internet",
  "requestedBy": "an.nv",
  "requestedAt": "2026-11-26T10:15:00+07:00",
  "expiresAt": "2026-12-10T10:15:00+07:00",
  "version": 1
}
```

**Đề nghị ngoại lệ luật WAF (API-03-043).** `POST /api/gateway/v1/waf/exceptions` kèm `Idempotency-Key`:

<!-- ex:WafExceptionCreate -->
```json
{
  "routeCode": "tra-cuu-ho-tich.v1",
  "ruleId": "942100",
  "reason": "Trường ghiChu chứa dấu nháy hợp lệ trong văn bản hành chính",
  "expiresAt": "2027-01-20T00:00:00+07:00",
  "evidenceEventId": "01JD7K2Q9XW4M3N5P6R8S0T1VA"
}
```

Phản hồi `201` là `WafException` với `state` bằng `REQUESTED`. Ngoại lệ chưa có hiệu lực ở gateway. Nếu chính người đề nghị gọi `POST /waf/exceptions/{exceptionId}:approve` thì nhận:

<!-- ex:ProblemDetails -->
```json
{
  "type": "https://datahub.gov.vn/errors/ERR-03-008",
  "title": "Người duyệt trùng người đề nghị",
  "status": 403,
  "detail": "Bạn đã đề nghị thay đổi này nên không thể tự duyệt.",
  "code": "ERR-03-008",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"
}
```

**Đổi chế độ WAF khi chưa đủ điều kiện (API-03-041).** Thân `{"mode": "BLOCK", "scope": "TENANT", "reason": "…"}` nhận `422`:

<!-- ex:ProblemDetails -->
```json
{
  "type": "https://datahub.gov.vn/errors/ERR-03-027",
  "title": "Chưa đủ điều kiện chuyển WAF sang chặn",
  "status": 422,
  "detail": "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy 9 ngày).",
  "code": "ERR-03-027",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "detectDays": 9,
  "requiredDays": 14
}
```

**Tổng hợp, kiểm tra và ký ảnh chụp (API-03-059).** `POST /api/gateway/v1/snapshots:build` kèm `Idempotency-Key`:

<!-- ex:BuildRequest -->
```json
{
  "scope": "TENANT",
  "tenant": "T68",
  "trigger": "MANUAL",
  "dryRun": false,
  "reason": "Phát thủ công sau đợt nhập hệ cũ"
}
```

Phản hồi `201 Created`, `Location: /api/gateway/v1/snapshots/48213`:

<!-- ex:Snapshot -->
```json
{
  "snapshotVersion": 48213,
  "site": "dc1",
  "scope": "T68",
  "state": "SIGNED",
  "contentHash": "9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a",
  "signatureKeyId": "dh-gateway-snapshot:3",
  "builtFrom": [{"source": "catalog", "cursor": "e-1204455"}, {"source": "onboarding", "cursor": "e-98812"}],
  "routeCount": 1042,
  "consumerCount": 187,
  "sizeBytes": 412880,
  "trigger": "MANUAL",
  "gitPending": false,
  "nodesApplied": 0,
  "nodesTotal": 6,
  "createdAt": "2026-11-26T09:14:03+07:00",
  "version": 1
}
```

Khi kiểm tra không đạt, phản hồi `422` ERR-03-005 kèm `findings`, ảnh chụp không được tạo và EVT-03-12 được phát:

<!-- ex:ProblemDetails -->
```json
{
  "type": "https://datahub.gov.vn/errors/ERR-03-005",
  "title": "Cấu hình không hợp lệ",
  "status": 422,
  "detail": "Cấu hình gateway không hợp lệ: 1 lỗi. Xem danh sách bên dưới.",
  "code": "ERR-03-005",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "findings": [
    {"checkId": "CHK-02", "severity": "ERROR", "objectType": "ROUTE", "objectCode": "tra-cuu-ho-tich.v2",
     "message": "Route tra-cuu-ho-tich.v2 thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền nên chưa được phát."}
  ]
}
```

**Quay lui cấu hình (API-03-061).** `POST /api/gateway/v1/snapshots/48100:rollback` (phiên bản đích trong đường dẫn):

<!-- ex:RollbackRequest -->
```json
{
  "scope": "TENANT",
  "reason": "Bản 48213 làm tăng lỗi 5xx ở ba route",
  "holdHours": 24
}
```

Phản hồi `201` là ảnh chụp **mới** (ví dụ phiên bản 48214, `trigger` bằng `ROLLBACK`, `rollbackOf` bằng 48100) mang nội dung của bản 48100. Số phiên bản luôn tăng nên nút không bao giờ nạp lùi (BR-03-018). Trong `holdHours` giờ, tổng hợp tự động bị giữ; thử tổng hợp trong lúc giữ trả `409` ERR-03-006.

**Tra cứu nhật ký lượt gọi (API-03-074).** `GET /api/gateway/v1/access-logs?from=2026-11-26T08:00:00%2B07:00&to=2026-11-26T09:00:00%2B07:00&consumerCode=ht-qlvb&statusClass=4xx&page=1&size=2&sort=-ts`:

<!-- ex:AccessLogPage -->
```json
{
  "items": [
    {
      "logId": "01JD7M3A5TQ8R2X9K4W6Y0Z1BC",
      "ts": "2026-11-26T08:41:17.904+07:00",
      "tenant": "T68",
      "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
      "routeCode": "tra-cuu-ho-tich.v1",
      "apiVersion": "v1",
      "consumerCode": "ht-qlvb",
      "method": "GET",
      "pathTemplate": "/ho-tich/v1/khai-sinh/{id}",
      "queryNames": ["tuNgay", "denNgay"],
      "status": 429,
      "errorCode": "ERR-03-116",
      "latencyMs": 2,
      "bytesIn": 312,
      "bytesOut": 410,
      "srcIp": "10.20.30.40",
      "authResult": "OK",
      "limitResult": "RATE_LIMITED",
      "wafResult": "PASS",
      "opaResult": "SKIPPED",
      "node": "apisix-int-2",
      "snapshotVersion": 48213,
      "synthetic": false
    },
    {
      "logId": "01JD7M3A5TQ8R2X9K4W6Y0Z1BD",
      "ts": "2026-11-26T08:41:17.611+07:00",
      "tenant": "T68",
      "traceId": "9a3c1e7b5d2f48a6b0c4e8f2a6d0b4c8",
      "routeCode": "tra-cuu-ho-tich.v1",
      "apiVersion": "v1",
      "consumerCode": "ht-qlvb",
      "method": "GET",
      "pathTemplate": "/ho-tich/v1/khai-sinh/{id}",
      "status": 429,
      "errorCode": "ERR-03-116",
      "latencyMs": 1,
      "srcIp": "10.20.30.40",
      "limitResult": "RATE_LIMITED",
      "node": "apisix-int-1",
      "snapshotVersion": 48213,
      "synthetic": false
    }
  ],
  "page": 1,
  "size": 2,
  "totalElements": 412
}
```

Bản ghi chỉ có siêu dữ liệu: `pathTemplate` theo mẫu route (không có giá trị tham số), `queryNames` chỉ có tên tham số. Không có trường nào chứa thân, tiêu đề `Authorization`, cookie hay giá trị truy vấn; kiểm thử canary `DH-CANARY-…` ở D05-02-PH03 bảo đảm điều này.

**Thu hồi token (API-03-053), do PH-12 gọi** bằng scope `gateway:revoke`:

<!-- ex:RevocationCreate -->
```json
{
  "kind": "SUBJECT",
  "sub": "9b1d2c3e-4f50-4a6b-8c7d-0e1f2a3b4c5d",
  "notBefore": "2026-11-26T09:20:00+07:00",
  "tokenExpiresAt": "2026-11-26T09:25:00+07:00",
  "reason": "Tài khoản dịch vụ nghi bị lộ khóa"
}
```

Phản hồi `201` là `Revocation` có `propagatedAt` khi khóa đã ghi Valkey. Mọi token của `sub` phát hành trước `notBefore` bị chặn tại gateway trong tối đa 60 giây (SEC-25); lượt gọi sau đó nhận `401` ERR-03-105.

## 4. Danh mục sự kiện

PH-03 phát 12 loại sự kiện để các phân hệ khác phản ứng khi cấu hình cổng, trạng thái route, consumer hay tình trạng an ninh đổi, mà không phải gọi hỏi liên tục. Sự kiện nghiệp vụ của `dh-connect` đi qua bảng outbox rồi Debezium đưa lên Kafka (ADR-042). Riêng EVT-03-09 có thêm một nguồn là APISIX, vì sự kiện như "chặn địa chỉ tự động" hay "truy cập chéo tenant" phát sinh ngay ở mặt phẳng dữ liệu và không đi qua `dh-connect`. Hợp đồng máy đọc được là [`ph03/asyncapi-gateway.yaml`](ph03/asyncapi-gateway.yaml) (AsyncAPI 3.0).

### 4.1. Danh mục

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Bên phát | Khóa phân vùng | Bên nhận |
|---|---|---|---|---|---|
| EVT-03-01 | `{tenant}.gateway.snapshot.published.v1` | Ảnh chụp cấu hình được phát (FR-03-042). | dh-connect | `scope` (mã tenant hoặc `COMMON`) | PH-02, PH-13 |
| EVT-03-02 | `{tenant}.gateway.snapshot.rolled-back.v1` | Quay lui cấu hình bằng ảnh chụp mới (FR-03-044). | dh-connect | `scope` | PH-02, PH-13 |
| EVT-03-03 | `{tenant}.gateway.route.state-changed.v1` | Route dừng, mở, tạm ngừng, SUNSET, RETIRED hoặc đổi cửa vào (FR-03-035, 036, 038, 047). | dh-connect | `{routeCode}` | PH-02, PH-13, PH-15 |
| EVT-03-04 | `{tenant}.gateway.consumer.state-changed.v1` | Consumer tạo, đổi, tạm ngừng, gỡ (FR-03-046, 047). | dh-connect | `{consumerCode}` | PH-01, PH-13 |
| EVT-03-05 | `{tenant}.gateway.waf-exception.changed.v1` | Ngoại lệ WAF được đề nghị, duyệt, từ chối, thu hồi, hết hạn (FR-03-007). | dh-connect | `{exceptionId}` | PH-13, thông báo SO |
| EVT-03-06 | `{tenant}.gateway.waf-exception.expiring.v1` | Ngoại lệ WAF còn 7 ngày hết hạn (FR-03-007). | dh-connect | `{exceptionId}` | Thông báo SO, TA |
| EVT-03-07 | `{tenant}.gateway.quota.threshold-reached.v1` | HTTT đạt 80% hoặc 100% hạn ngạch; tenant sắp chạm hạn mức (FR-03-022, 023). | dh-connect (đọc luồng sự kiện hạn ngạch ở Valkey) | `{consumerCode}` hoặc `TENANT` | PH-02, thông báo đầu mối HTTT, TA |
| EVT-03-08 | `{tenant}.gateway.certificate.expiring.v1` | Chứng thư biên còn dưới 30 ngày (FR-03-049). | dh-connect | `{certCode}` | PH-13, PA |
| EVT-03-09 | `{tenant}.gateway.security.alert-raised.v1` | Sự kiện an ninh, vận hành của gateway (FR-03-004, 005, 006, 013, 014, 026, 027, 031, 047, 053, 054). Hai nguồn phát: APISIX qua `kafka-logger` và `dh-connect` qua outbox. | apisix (kafka-logger), dh-connect | `routeCode`, nếu không gắn route thì `node` | PH-13 (SIEM) |
| EVT-03-10 | `{tenant}.gateway.tenant-redirect.changed.v1` | Chuyển tiếp tenant sáp nhập bắt đầu, kết thúc (FR-03-037). | dh-connect | `fromTenant` | PH-20, PH-13 |
| EVT-03-11 | `{tenant}.gateway.limit.changed.v1` | Hạn mức toàn tenant, ghi đè hạn mức hoặc tham số hạn mức đổi (FR-03-023, 024, 056). | dh-connect | `scopeKey` (mã đối tượng hoặc khóa `gw.*`) | PH-13, PH-20 |
| EVT-03-12 | `{tenant}.gateway.snapshot.rejected.v1` | Ảnh chụp bị từ chối khi kiểm tra hợp lệ, kèm danh sách lỗi (FR-03-040). | dh-connect | `scope` | PH-02, thông báo người phát hành |

: Danh mục sự kiện của PH-03
<!-- gen:events:end -->

Topic theo quy ước `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}`, chữ thường (D00-04 §4); `{tenant}` là mã tenant chữ thường (`t68`) hoặc `common` cho sự kiện của phần dùng chung toàn nền tảng.

### 4.2. Khung sự kiện và cấu hình topic

Mọi sự kiện của PH-03 dùng chung một khung và chung quy tắc giao nhận; bảng dưới là khung đó, theo CC-API-04 của D04-01.

| Mục | Quy ước |
|---|---|
| Khung | CloudEvents 1.0, chế độ nhị phân, theo CC-API-04 (D04-01): `ce_specversion`, `ce_id` (UUID v7, khóa lũy đẳng của người tiêu thụ), `ce_source` (`/datahub/dh-connect/gateway`), `ce_type` (`vn.datahub.gateway.{thực-thể}.{sự-kiện}.v1`), `ce_time`, `ce_subject` (mã đối tượng), `ce_dhtenant` (mã tenant), `ce_dataschema` (lược đồ ở Apicurio), `traceparent`. Thân là JSON `application/json` |
| Giao | Ít nhất một lần. Người tiêu thụ xử lý lũy đẳng theo `ce_id`; thứ tự giữ theo khóa phân vùng (mã đối tượng) nên sự kiện của cùng một route, consumer, ngoại lệ không đảo thứ tự |
| Ghi | `dh-connect` ghi sự kiện vào `ph03_gateway.outbox` **cùng giao dịch** với thay đổi trạng thái; Debezium outbox đưa lên Kafka. Hủy giao dịch thì không có sự kiện (SDD §8.2) |
| EVT-03-09 | Hai nguồn: APISIX qua plugin `kafka-logger` (không giao dịch, đủ cho cảnh báo, tiêu đề chỉ có `traceparent` và `ce_id`) và `dh-connect` qua outbox khi tạm ngừng khẩn cấp |
| Nội dung | Không có bí mật, thân yêu cầu, tiêu đề xác thực; `srcIp` chỉ có ở EVT-03-09 cho SIEM. Ràng buộc `ck_outbox_no_secret` và ca kiểm thử canary bảo đảm điều này |
| Tenant | Tiền tố topic là mã tenant; ACL Kafka theo principal và tiền tố, nên PH-02 của tỉnh A không đọc được sự kiện của tỉnh B |
| Bên ghi, bên đọc | Ghi: principal `dh-connect` (mọi topic `*.gateway.*`) và `apisix-kafka-logger` (chỉ `*.gateway.security.alert-raised.v1`). Đọc: theo cột "Bên nhận" ở mục 4.1 |

: Khung sự kiện của PH-03

Mọi topic dùng 3 phân vùng, 3 bản sao và giữ 7 ngày (giả định theo PH-05 và CSDL §6.4, chốt ở D03-09). Khóa phân vùng ở bảng 4.1 được chọn theo thứ tự cần giữ: ảnh chụp theo `scope` để bên nhận luôn thấy bản mới nhất của một tenant đến sau bản cũ; route, consumer, ngoại lệ theo mã đối tượng. Bảng khóa "đề xuất" ở CSDL §6.4 khác ở ba dòng (EVT-03-01, 02, 12 dùng `snapshotVersion` hay `snapshotId` sẽ rải các phiên bản của cùng một tenant sang nhiều phân vùng và mất thứ tự; EVT-03-11 dùng `scope` chỉ có năm giá trị nên dồn vào một phân vùng); đề nghị CSDL theo bảng này (mục "Đề nghị đồng bộ").

### 4.3. Trường chính của từng sự kiện

Lược đồ đầy đủ ở AsyncAPI. Mọi sự kiện có `tenantId` (mã `T68`, `COMMON`) và một mốc thời gian (`publishedAt`, `occurredAt`, `rejectedAt` hoặc mốc hết hạn tùy loại).

| Mã | Trường bắt buộc | Trường tùy chọn chính |
|---|---|---|
| EVT-03-01 | `tenantId`, `snapshotVersion`, `site`, `scope`, `contentHash`, `trigger`, `publishedAt` | `signatureKeyId`, `builtFrom[]`, `routes{added, changed, removed}`, `gitPending`, `actor` |
| EVT-03-02 | `tenantId`, `snapshotVersion` (bản mới), `targetVersion`, `scope`, `reason`, `rolledBackAt` | `site`, `holdUntil`, `actor` |
| EVT-03-03 | `tenantId`, `routeCode`, `to`, `occurredAt` | `apiCode`, `apiVersion`, `from`, `exposure`, `exposureChangedFrom`, `reason`, `sunsetAt`, `actor` |
| EVT-03-04 | `tenantId`, `consumerCode`, `change`, `state`, `occurredAt` | `systemCode`, `authMethod`, `reason`, `actor` |
| EVT-03-05 | `tenantId`, `exceptionId`, `routeCode`, `ruleId`, `change`, `occurredAt` | `expiresAt`, `requestedBy`, `decidedBy` |
| EVT-03-06 | `tenantId`, `exceptionId`, `routeCode`, `ruleId`, `expiresAt`, `daysLeft` | `requestedBy` |
| EVT-03-07 | `tenantId`, `kind`, `percent` (80 hoặc 100), `limit`, `used`, `occurredAt` | `consumerCode`, `routeCode`, `period`, `resetAt` |
| EVT-03-08 | `tenantId`, `certCode`, `hosts[]`, `notAfter`, `daysLeft`, `severity` | `autoRenew`, `renewalState` |
| EVT-03-09 | `tenantId`, `alertId`, `ruleCode` (GW-A01…A13), `severity`, `source`, `kind`, `occurredAt` | `routeCode`, `consumerCode`, `node`, `srcIp`, `count`, `windowSeconds`, `detail`, `traceId` |
| EVT-03-10 | `tenantId`, `redirectId`, `fromTenant`, `toTenant`, `change`, `occurredAt` | `startAt`, `endAt`, `routeCount`, `actor` |
| EVT-03-11 | `tenantId`, `scope`, `scopeKey`, `after`, `occurredAt` | `before`, `changeRequestId`, `actor` |
| EVT-03-12 | `tenantId`, `scope`, `triggeredBy`, `findings[]`, `rejectedAt` | `candidateVersion` |

: Trường chính của sự kiện PH-03

### 4.4. Ví dụ payload

EVT-03-01, ảnh chụp được phát (bên nhận: PH-02 cập nhật "đã áp dụng", PH-13 ghi nhật ký):

<!-- exa:SnapshotPublished -->
```json
{
  "tenantId": "T68",
  "snapshotVersion": 48213,
  "site": "dc1",
  "scope": "T68",
  "contentHash": "9f2c5a0e7d4b3c1a8e6f0b2d4c6a8e0f1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f0a",
  "signatureKeyId": "dh-gateway-snapshot:3",
  "trigger": "AUTO",
  "builtFrom": [{"source": "catalog", "cursor": "e-1204455"}],
  "routes": {"added": 2, "changed": 1, "removed": 0},
  "gitPending": false,
  "publishedAt": "2026-11-26T09:14:08+07:00",
  "actor": {"userId": "system:dh-connect", "type": "SYSTEM"}
}
```

EVT-03-09, cảnh báo an ninh do APISIX phát khi token của tenant khác gọi route của tenant này (luật GW-A03, mức Nghiêm trọng, bên nhận: PH-13 chuyển cho SIEM và gửi SO):

<!-- exa:SecurityAlertRaised -->
```json
{
  "tenantId": "T68",
  "alertId": "0193a1f2-8a77-7c0d-8e22-5b9d6e1f4a10",
  "ruleCode": "GW-A03",
  "severity": "CRITICAL",
  "source": "GATEWAY",
  "kind": "CROSS_TENANT",
  "routeCode": "tra-cuu-ho-tich.v1",
  "consumerCode": "ht-qlvb",
  "node": "apisix-int-2",
  "srcIp": "10.20.30.40",
  "count": 1,
  "windowSeconds": 60,
  "detail": "Token của tenant T71 gọi route của tenant T68",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "occurredAt": "2026-11-26T14:03:55+07:00"
}
```

### 4.5. Tương thích và đổi phiên bản

Sự kiện là hợp đồng với nhiều bên nhận độc lập, mỗi bên triển khai theo nhịp riêng, nên thay đổi phải tuân theo bốn quy tắc sau.

1. Lược đồ đăng ký ở Apicurio với chế độ tương thích BACKWARD (ADR-070): trong `v1` chỉ được thêm trường tùy chọn, không đổi tên, không đổi kiểu, không bỏ trường bắt buộc.
2. Người tiêu thụ **bỏ qua trường lạ** và coi giá trị liệt kê lạ là "không biết" (không lỗi), để PH-03 thêm giá trị mới (ví dụ thêm `kind` của EVT-03-09) mà không làm hỏng bên nhận.
3. Thay đổi phá vỡ phát ở topic `.v2` song song với `.v1` tối thiểu 6 tháng; CI-5 chặn thay đổi phá vỡ `v1` (chương 7).
4. Khi thêm sự kiện mới, lấy số kế tiếp sau mã cuối của dải (sau EVT-03-12) và thêm vào `spec.EVENTS`; danh mục FRS §9.3 cập nhật trong đợt đồng bộ.

### 4.6. Kênh nhanh Valkey, không phải sự kiện Kafka

Thu hồi token và tạm ngừng khẩn cấp phải có hiệu lực trong 60 giây và 30 giây, nhanh hơn vòng ảnh chụp, nên `dh-connect` ghi thẳng khóa vào Valkey sau khi đã commit cơ sở dữ liệu; plugin APISIX đọc khóa đó. Đây là hợp đồng giữa `dh-connect` và plugin, không phải API công khai và không có sự kiện Kafka; định dạng đầy đủ ở SDD §3.4.

| Khóa | Giá trị | Thời hạn | Ghi bởi API-03- | Đọc bởi |
|---|---|---|---|---|
| `{T68}:revoked:jti:{jti}` | `1` | Còn lại của token cộng 60 giây | 053 (`kind=JTI`) | `dh-revocation` |
| `{T68}:revoked:sub:{sub}` | `notBefore` (giây epoch) | Thời gian sống tối đa của token | 053 (`kind=SUBJECT`) | `dh-revocation` |
| `{T68}:kill:route:{routeCode}` | `SUSPENDED` | Tới khi mở lại | 019, 020 | `dh-kill-switch` |
| `{T68}:kill:consumer:{consumerCode}` | `SUSPENDED` | Tới khi mở lại | 017, 018 | `dh-kill-switch` |

: Khóa Valkey ghi từ API quản trị

Hai quy tắc giữ cho đường nhanh an toàn: cơ sở dữ liệu là nguồn sự thật, Valkey là bản phái sinh (ghi Valkey sau khi commit, `ValkeyRebuilder` dựng lại khi Valkey mất); đường nhanh chỉ **chặn thêm**, không bao giờ mở ra, nên không thể dùng nó để vượt cấu hình bền.

### 4.7. Sự kiện và dữ liệu PH-03 nhận vào

PH-03 không định nghĩa các sự kiện sau; bảng chỉ nêu cách nhận để kỹ sư biết phụ thuộc. Tên topic do phân hệ phát chốt, ghi vào đề nghị đồng bộ.

| Nguồn | Cách nhận | Dùng cho |
|---|---|---|
| PH-02 (module `catalog`, cùng DU) | Giao diện `PublishedApiQuery`, `PlanQuery`, `SubscriptionQuery` và sự kiện nội bộ Modulith | Nguồn route, gói, đăng ký cho bộ tổng hợp (FR-03-039) |
| PH-01 (module `onboarding`, cùng DU) | Gọi API-03-013…015 (mục 2.1); không có sự kiện vào | Tạo, gỡ consumer |
| PH-12 | Bucket `dh-platform-policy` (gói chính sách OPA, OPA tự tải), URL JWKS theo realm; gọi API-03-053 | Ủy quyền, xác minh token, thu hồi |
| PH-20 | Sự kiện và API đọc (tên topic do PH-20 chốt) | Host, hạn mức hợp đồng, trạng thái `MERGED` của tenant |
| PH-13 | Truy vấn Mimir, ClickHouse | Chỉ số, nhật ký, báo cáo cho API-03-029, 074, 077…079, 089 |

: Dữ liệu PH-03 nhận vào

## 5. Hợp đồng với phân hệ khác và bên ngoài

PH-03 đứng giữa nhiều bên: bốn phân hệ nội bộ gọi hoặc đọc API quản trị, các phân hệ khác nhận sự kiện, bên gọi API ngoài nhìn thấy hành vi của cổng, và nút APISIX đọc ảnh chụp cấu hình. Chương này chốt từng hợp đồng để mỗi bên biết mình được bảo đảm gì và phải làm gì. Hợp đồng với NDXP (PH-14) và PayGov (PH-19) không có giao diện riêng ở PH-03: chúng chỉ là bên gọi hoặc backend của route nên đi qua mục 5.4.

### 5.1. Bảng hợp đồng theo đối tác

Bảng nêu với từng đối tác: hướng và giao diện, điều PH-03 bảo đảm, điều PH-03 cần ngược lại và cách xử lý khi lỗi. Đọc theo hàng để biết trách nhiệm của cả hai phía.

| Đối tác | Hướng, giao diện | PH-03 bảo đảm | PH-03 cần ở đối tác | Khi lỗi |
|---|---|---|---|---|
| PH-01 Kết nạp HTTT | PH-01 gọi API-03-013, 014, 015 (scope `gateway:sync`); hỏi `GatewaySyncStatusApi.consumerStatus` trong tiến trình | Lũy đẳng theo `Idempotency-Key` 24 giờ; không lưu bí mật; `IN_SYNC` chỉ khi mọi nút của cả hai cửa đã nạp; xóa mềm, mã không dùng lại | `systemCode` ở trạng thái `ACTIVE`; gửi `Idempotency-Key` ổn định cho mỗi bước saga; chỉ gửi phần công khai | `409` ERR-03-017 khi gỡ consumer còn đăng ký: saga phải thu hồi đăng ký trước. `400` ERR-03-003: sửa thân, không thử lại |
| PH-02 Danh mục dịch vụ | PH-03 đọc `PublishedConfigApi`; nhận dữ liệu công bố từ API-02-080 (ndjson, `sinceConfigVersion`; `gap = true` thì nạp lại toàn bộ) bằng scope `catalog:gateway-read` và xác nhận đã nạp qua API-02-082 bằng scope `catalog:gateway-ack`; đặt tên route `{apiCode}:v{major}:{operationId}` để PH-13 gom số đo theo API; nhận EVT-03-01, 03, 07, 12 | Chỉ phát cấu hình đã qua kiểm tra hợp lệ; báo lại PH-02 khi từ chối (EVT-03-12); không duyệt lần hai nội dung đã duyệt ở PH-02 | Nguồn đủ: lược đồ OpenAPI đã duyệt, `policyPackage`, `critical`, `deprecatedAt`, `sunsetAt` | Nguồn cũ quá 24 giờ: dùng bản chiếu gần nhất và cảnh báo (`dh_gateway_source_stale_seconds`) |
| PH-12 Định danh và phân quyền | PH-12 gọi API-03-053 (scope `gateway:revoke`); PH-03 đọc JWKS theo realm và gói chính sách OPA ở bucket `dh-platform-policy` | Thu hồi token có hiệu lực tại gateway ≤ 60 giây (SEC-25); gói chính sách lưu bền nên OPA khởi động lại vẫn có chính sách gần nhất | JWKS có `kid`; gói chính sách ký; thu hồi gửi đủ `tokenExpiresAt` để PH-03 đặt thời hạn khóa | Keycloak ngừng: dùng JWKS đã đệm tới 24 giờ rồi ERR-03-124. OPA không phản hồi: đóng an toàn ERR-03-124 |
| PH-13 Giám sát và kiểm toán | PH-03 gửi chỉ số, vết, nhật ký (OTLP) và EVT-03-01…12; PH-13 đọc trạng thái bằng scope `gateway:read-state` | Nhật ký lượt gọi chỉ có siêu dữ liệu; chỉ số nhãn `consumer` giới hạn 500 giá trị (Q03-08 của FRS); bộ đệm đĩa 1 GiB mỗi pod khi PH-13 ngừng | Kho ClickHouse (nhãn `tenant` bắt buộc), Mimir, Alertmanager; luật cảnh báo GW-A01…A13 | PH-13 không trả số liệu: API đọc trả ERR-03-026 (503), giao diện hiện "chưa có số liệu", không hiện số 0 |
| PH-20 Quản trị tenant | PH-03 đọc host, hạn mức hợp đồng, trạng thái `MERGED`; PH-20 nhận EVT-03-10, 11 | Hạn mức tenant, ghi đè không vượt trần hợp đồng (ERR-03-018); chuyển tiếp chỉ cho tenant đã `MERGED` (ERR-03-025) | Trần hợp đồng và trạng thái sáp nhập đúng, kịp thời | Dùng giá trị đã lưu gần nhất |
| PH-19 Thanh toán, PH-15 Cổng nhà phát triển | Dùng route `EXT` (callback thanh toán, cổng nhà phát triển) | Route ra cửa Internet chỉ sau bốn mắt (API-03-008, 072); WAF mức hoang tưởng 1 cho API máy với máy | Khai báo dải địa chỉ cố định của nhà cung cấp nếu có (`ipAllowCidrs`) | ERR-03-011 nếu chưa đủ điều kiện |
| PH-14 Kết nối quốc gia (NDXP) | Bên gọi hoặc backend của route | Dải địa chỉ NDXP nằm trong danh sách tin cậy, miễn giới hạn theo IP (`gw.ip.trustedCidrs`, GĐ-03-09) | Dải địa chỉ cố định, khai báo được | Chặn nhầm: SO bỏ chặn bằng API-03-038 |
| Hộp việc chung (FR-00-070) | PH-03 gửi `TaskInboxApi` | Mỗi yêu cầu thay đổi chờ duyệt có một việc cho người duyệt | Phân phối đúng vai trò TA, SO | Yêu cầu hết hạn sau 14 ngày |

: Hợp đồng theo đối tác

### 5.2. Saga kết nạp HTTT tạo consumer

Saga kết nạp HTTT của PH-01 là luồng nội bộ dùng API quản trị nhiều nhất và đòi hỏi lũy đẳng nghiêm ngặt; hình dưới theo trình tự gọi.

```{.mermaid caption="Trình tự PH-01 tạo consumer ở gateway và chờ mọi nút nạp xong"}
sequenceDiagram
  participant P1 as PH-01 saga
  participant CP as dh-connect
  participant BC as BuildCoordinator
  participant AX as Nút APISIX
  P1->>CP: PUT /consumers/ht-qlvb, Idempotency-Key
  CP->>CP: SecretFieldGuard, lưu consumer, tăng consumerVersion
  CP-->>P1: 201 syncState PENDING
  P1->>CP: PUT /consumers/ht-qlvb/credentials, Idempotency-Key
  CP-->>P1: 200 vân tay cắt ngắn
  CP->>BC: Yêu cầu tổng hợp, gom 3 giây
  BC->>AX: Ảnh chụp mới qua bucket
  AX-->>CP: Chỉ số runningVersion
  P1->>CP: consumerStatus trong tiến trình
  CP-->>P1: IN_SYNC khi mọi nút của cả hai cửa đã nạp
  Note over P1,CP: Saga lỗi ở bước sau thì bù trừ
  P1->>CP: DELETE /consumers/ht-qlvb, Idempotency-Key
  CP-->>P1: 204, hoặc 409 ERR-03-017 nếu còn đăng ký
```

Hình cho thấy hai điều saga phải tuân theo: tạo consumer là hai lệnh ghi (danh tính rồi thông tin xác thực công khai), mỗi lệnh lũy đẳng riêng; và "xong" nghĩa là `IN_SYNC`, không phải "đã ghi". Mục tiêu từ lúc saga báo xong tới lúc HTTT gọi API thành công qua cổng là ≤ 10 giây, tạm ngừng HTTT có hiệu lực ≤ 30 giây (tiêu chí chấp nhận 9 của FRS). Tạm ngừng HTTT ở PH-01 gọi `PUT` với `state=SUSPENDED`; muốn tức thì ngay (sự cố) người vận hành dùng API-03-017.

### 5.3. Thu hồi token từ PH-12

Thu hồi token là luồng duy nhất bắt buộc có hiệu lực dưới một phút; hình dưới cho thấy đường ghi của `dh-connect` và đường đọc của plugin.

```{.mermaid caption="Trình tự PH-12 đẩy thu hồi token và gateway chặn trong 60 giây"}
sequenceDiagram
  participant P12 as PH-12
  participant CP as dh-connect
  participant DB as pg-core
  participant VK as Valkey
  participant AX as dh-revocation
  P12->>CP: POST /revocations, scope gateway:revoke
  CP->>DB: Ghi revoked_token
  CP->>VK: Ghi khóa revoked:sub sau khi commit
  CP-->>P12: 201 Revocation
  AX->>VK: Tra khóa khi có lượt gọi
  AX-->>AX: Token phát hành trước notBefore bị chặn
  Note over AX,VK: Valkey lỗi thì dùng bộ đệm cục bộ gần nhất, ValkeyRebuilder dựng lại
```

Hình cho thấy cơ sở dữ liệu được ghi trước, Valkey sau. Nếu Valkey không ghi được ngay, `ValkeyRebuilder` dựng lại từ bảng `revoked_token` khi Valkey trở lại, nên một thu hồi không bao giờ mất. Token ngắn hạn (tối đa 5 phút) nên khóa tự hết hạn cùng token.

### 5.4. Hợp đồng với bên gọi API qua cổng

Phần này là điều HTTT, đơn vị kết nối và giao diện nhìn thấy khi gọi một API qua cổng. Nó không phải API của `dh-connect` mà là hành vi của APISIX; cần ở đây vì PH-03 chịu trách nhiệm về nó (FR-03-025, 032, 035) và vì kiểm thử hợp đồng của đơn vị kết nối bám vào nó.

**Phương thức xác thực chấp nhận** theo gói sử dụng của API (`securityMode`):

| `securityMode` | Cách gọi | Ghi chú |
|---|---|---|
| `OAUTH2` | `Authorization: Bearer {JWT}` lấy từ Keycloak bằng `client_credentials` với `private_key_jwt` hoặc `client_secret` | Mặc định; gateway chỉ xác minh chữ ký cục bộ, không giữ bí mật của client |
| `MTLS` | Chứng thư khách (RFC 8705, `tls_client_auth`) kèm token ràng buộc `cnf.x5t#S256` | Bắt buộc cho hợp đồng mức Nhạy cảm; từ mức Hạn chế không dùng `client_secret` (SEC-24). Sai phương thức: ERR-03-130, chứng thư không khớp: ERR-03-108 |
| `API_KEY` | Tiêu đề `X-API-Key` | Chỉ giai đoạn chuyển đổi từ hệ cũ; có ngày hết hạn tối đa 180 ngày |
| `KEYLESS` | Không | Chỉ API dữ liệu mở (FR-03-015) |

: Phương thức xác thực bên gọi

**Tiêu đề gateway đặt ở phản hồi** (bên gọi dùng để tự điều tiết và truy vết):

| Tiêu đề | Khi nào | Ý nghĩa |
|---|---|---|
| `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` | Mọi phản hồi của route có hạn mức | Giới hạn chặt nhất đang áp, số lượt còn lại, thời điểm đặt lại (giây Unix) |
| `X-Quota-Remaining` | Route có hạn ngạch | Số lượt còn lại trong chu kỳ hạn ngạch |
| `Retry-After` | `429`, `503` | Số giây nên chờ |
| `X-RateLimit-Degraded: true` | Valkey không khả dụng | Hạn mức đang tính cục bộ theo số bản sao (FR-03-026); lượt gọi không bị từ chối vì lý do này |
| `X-DH-Throttled: true` | `429` do điều tiết theo backend | Bị giảm hạn mức vì backend đang yếu, không phải hết gói (FR-03-027) |
| `Deprecation`, `Sunset`, `Link` | Phiên bản API sắp ngừng dùng | Ngày bắt đầu ngừng khuyến nghị, ngày ngừng phục vụ, liên kết tới phiên bản kế nhiệm (FR-03-035) |
| `Strict-Transport-Security` và các tiêu đề bảo mật | Mọi phản hồi | Tiêu đề bảo mật chuẩn; không lộ phiên bản máy chủ (BR-03-013) |
| `X-Trace-Id` | Mọi phản hồi, kể cả lỗi do gateway sinh (FR-03-032) | Mã truy vết 32 ký tự hex, trùng `traceId` trong thân lỗi; bên gọi gửi kèm khi báo vận hành |
| `WWW-Authenticate` | `401` (ERR-03-102…106) | `Bearer realm="datahub"`, thêm `error="invalid_token"` khi token sai hoặc hết hạn (RFC 6750) |

: Tiêu đề phản hồi của gateway

**Tiêu đề gateway đặt khi chuyển tiếp tới backend.** Gateway **xóa mọi tiêu đề `X-DH-*`** do khách tự gửi rồi đặt lại `X-DH-Tenant`, `X-DH-Client` (`azp` của token), `X-DH-Consumer` và `traceparent`. Backend chỉ tin `X-DH-Tenant` khi lượt gọi đến từ APISIX qua mesh (kiểm danh tính SPIFFE, SEC-80) và vẫn đọc lại tenant từ token để đặt ngữ cảnh. Không có đường nào để khách giả mạo tenant bằng tiêu đề.

**Thân lỗi gateway trả.** Mọi lượt gọi bị gateway từ chối có thân RFC 9457 `application/problem+json` với `code` thuộc `ERR-03-101…130` (bảng ở mục 6.2). Ví dụ vượt tần suất:

<!-- ex:GatewayProblem -->
```json
{
  "type": "https://datahub.gov.vn/errors/ERR-03-116",
  "title": "Vượt tần suất của HTTT",
  "status": 429,
  "detail": "Bạn đã gọi vượt 20 lượt/giây. Thử lại sau 1 giây.",
  "code": "ERR-03-116",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "retryAfterSeconds": 1,
  "rateLimit": {"window": "1s", "limit": 20, "remaining": 0, "resetAt": "2026-11-26T09:14:04+07:00"}
}
```

Lỗi do **backend** (không phải do gateway) đi qua nguyên vẹn, trừ khi backend không trả phản hồi hợp lệ (ERR-03-122) hoặc quá hạn (ERR-03-121). Bên gọi phân biệt hai loại bằng `code`: có `ERR-03-1xx` là gateway, không có là backend.

**Thứ tự các chốt và mã lỗi trả về.** Một lượt gọi bị từ chối ở chốt đầu tiên không đạt, nên khi có nhiều lỗi cùng lúc bên gọi nhận lỗi của chốt xếp trước. Bảng dưới (nguồn: SDD §4.1) giúp kiểm thử viên dựng ca âm một lỗi mỗi lần.

| Thứ tự | Chốt (plugin) | Mã lỗi có thể trả |
|---|---|---|
| 0 | Bộ định tuyến | ERR-03-114 (không có route khớp), ERR-03-128 (sai SNI hoặc `Host`) |
| 1 | `client-control` | ERR-03-115 |
| 2 | `dh-edge` (TLS, mTLS) | ERR-03-108 (chứng thư khách không hợp lệ) |
| 3 | `dh-ip-block` | ERR-03-110, ERR-03-119 |
| 4 | Coraza WAF | ERR-03-109 |
| 7 | `dh-auth` | ERR-03-102, 103, 104, 106, 107, 108, 111, 124, 130 |
| 8 | `dh-revocation` | ERR-03-105 |
| 9 | `dh-kill-switch` | ERR-03-123, 126, 127 |
| 10 | `dh-path-acl` | ERR-03-113 |
| 11, 12 | `dh-limit`, `dh-adaptive-throttle` | ERR-03-116, 117, 118 |
| 13 | `request-validation` | ERR-03-101 |
| 15 | `opa` | ERR-03-112, ERR-03-124 (OPA không phản hồi) |
| 16 | `api-breaker`, upstream | ERR-03-120, 121, 122 |
| Bất kỳ | Lớp bao plugin | ERR-03-129 (lỗi bất ngờ, đóng an toàn) |

: Thứ tự chốt và mã lỗi gateway

Điểm đáng chú ý: xác thực (7) đứng **trước** hạn mức (11), nên lượt gọi không hợp lệ không làm tốn hạn mức của HTTT; và đăng ký sử dụng được kiểm trong `dh-auth` trước khi đếm hạn mức. Bộ định tuyến (0) trả `404` ERR-03-114 trước mọi chốt nên bên gọi không thể dùng phản hồi để dò xem route của tenant khác có tồn tại hay không.

### 5.5. Hợp đồng ảnh chụp cấu hình giữa `dh-connect` và nút gateway

Ảnh chụp là hợp đồng bền duy nhất giữa hai mặt phẳng; API không đưa nội dung ảnh chụp ra ngoài ngoại trừ siêu dữ liệu (`Snapshot`, `SnapshotDetail`) và so sánh (`SnapshotDiff`). Định dạng đầy đủ ở SDD §3.4; điểm hợp đồng cần chốt ở đây:

| Mục | Hợp đồng |
|---|---|
| Vị trí | Bucket `dh-platform-gateway`, thư mục `snapshots/{site}/{version}/`: `manifest.json`, `manifest.sig`, `int.yaml`, `ext.yaml`, `shards/{tenant}-{gate}.yaml`. Con trỏ `snapshots/{site}/current` (số phiên bản và băm manifest) ghi **sau cùng** |
| Chữ ký | ECDSA P-256 SHA-256 trên băm manifest chuẩn hóa; khóa ở OpenBao `transit/keys/dh-gateway-snapshot`, không xuất được; `signature.keyId` có số phiên bản khóa |
| Đọc | Nút (`dh-sync`) đọc con trỏ mỗi `gw.sync.pollSeconds` (5 giây), kiểm chữ ký và băm từng tệp rồi mới ghi cấu hình cục bộ |
| Từ chối | Nút **không nạp** ảnh chụp có chữ ký sai, băm sai hoặc số phiên bản không lớn hơn bản đang chạy; giữ cấu hình hiện tại và phát cảnh báo GW-A05 |
| Số phiên bản | Tăng đơn điệu theo site; quay lui sinh bản mới (BR-03-018), không đưa số cũ trở lại |
| Dự phòng | Bucket lỗi thì đường ConfigMap từ Git thay thế; cả hai lỗi: ERR-03-014 và cấu hình đang chạy không đổi |

: Hợp đồng ảnh chụp cấu hình

`syncState` của nút (API-03-063, 064) và của consumer suy ra từ chỉ số `dh_gateway_config_version` của từng nút, không do nút gọi về `dh-connect`; vì vậy nút không cần quyền gọi API quản trị.

## 6. Bảng mã lỗi ERR-03

PH-03 có 57 mã lỗi chia hai dải theo bên nhận (D00-04 §3): `ERR-03-001…099` cho mặt phẳng điều khiển, trả bởi `dh-connect` cho người quản trị và phân hệ gọi; `ERR-03-101…199` cho mặt phẳng dữ liệu, trả bởi APISIX cho bên gọi API (đang dùng 101…130, còn 131…199 để mở rộng). Mỗi mã có đúng một mã HTTP chính; riêng ERR-03-114 trả `404` khi không có route, `405` khi sai phương thức. Mỗi mã được dùng ở FRS, use case và màn hình đều có trong bảng dưới, và bảng lỗi sinh từ cùng `spec.py` với OpenAPI nên không lệch mã. Câu thông báo tiếng Việt người dùng nhìn thấy nằm ở FRS §9.2 và ở mục 6.3.

<!-- gen:errors:start -->
### 6.1. Lỗi API điều khiển (ERR-03-001…027)

Trả bởi `dh-connect`, thân `ProblemDetails`. Cột cuối nêu API phát sinh để kiểm thử viên chọn đúng ca âm.

| Mã | HTTP | Ý nghĩa | API phát sinh (API-03-) |
|---|---|---|---|
| ERR-03-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác (không phân biệt hai trường hợp) | Mọi API có mã trong đường dẫn |
| ERR-03-002 | 409 | Mã đã tồn tại, kể cả đối tượng đã gỡ | 013, 081 |
| ERR-03-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường; cũng là mã khi cùng `Idempotency-Key` nhưng khác thân và khi thân chứa trường dạng bí mật | Mọi API có thân hoặc tham số truy vấn |
| ERR-03-004 | 412 | `If-Match` không khớp `ETag` hiện tại | Mọi lệnh sửa, xóa, đổi trạng thái có `If-Match` |
| ERR-03-005 | 422 | Cấu hình không hợp lệ theo kiểm tra tĩnh, kèm danh sách lỗi `findings` | 059 |
| ERR-03-006 | 409 | Đang có lần tổng hợp, ký hoặc phát khác; hoặc tenant đang bị giữ sau quay lui | 059, 060, 061 |
| ERR-03-007 | 422 | Phiên bản đích tham chiếu đối tượng không còn hợp lệ | 061 |
| ERR-03-008 | 403 | Người duyệt trùng người đề nghị (bốn mắt) | 044, 045, 072, 073 |
| ERR-03-009 | 422 | Ngoại lệ hoặc luật vá WAF sai: thiếu lý do, quá hạn tối đa, mã luật không có | 043, 048 |
| ERR-03-010 | 409 | Đã có ngoại lệ WAF còn hiệu lực cho cặp route và mã luật | 043 |
| ERR-03-011 | 422 | Route chưa đủ điều kiện hoặc chưa được duyệt để mở ra cửa Internet | 008 |
| ERR-03-012 | 422 | Route thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền | 059 |
| ERR-03-013 | 422 | Plugin hoặc mẫu chính sách ngoài danh mục được duyệt | 059, 067 |
| ERR-03-014 | 502 | Không ghi được ảnh chụp tới Git hoặc bucket | 060 |
| ERR-03-015 | 503 | OpenBao, PKI hoặc dịch vụ ký không khả dụng | 059, 060, 061, 070 |
| ERR-03-016 | 422 | Chứng thư không hợp lệ (chuỗi, hạn, khóa, host) | 014, 070 |
| ERR-03-017 | 409 | Consumer còn đăng ký sử dụng đang hiệu lực | 015 |
| ERR-03-018 | 422 | Hạn mức hoặc tham số vượt trần hợp đồng hoặc dưới mức tối thiểu | 009, 010, 024, 026, 027, 033, 067, 087 |
| ERR-03-019 | 409 | Đối tượng đã ở trạng thái đích hoặc đang được dùng (đã dừng, đã tạm ngừng, mẫu đang dùng) | 003, 004, 017, 018, 019, 020, 034, 041 và 13 API khác |
| ERR-03-020 | 422 | Gói nhập từ gateway cũ không đọc được, thiếu trường hoặc bị bộ quét từ chối | 091, 093 |
| ERR-03-021 | 400 | Khoảng thời gian truy vấn, báo cáo hoặc số dòng xuất vượt giới hạn | 039, 074, 076, 089, 090 |
| ERR-03-022 | 403 | Thiếu quyền (`PERM`) hoặc thiếu scope dịch vụ | Mọi API |
| ERR-03-023 | 409 | Route không ở trạng thái cho phép thao tác | 003, 004, 008, 019, 020, 026 |
| ERR-03-024 | 422 | Địa chỉ thuộc danh sách tin cậy hoặc hạ tầng, không được chặn | 037 |
| ERR-03-025 | 409 | Tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp | 095 |
| ERR-03-026 | 503 | Không đọc được số liệu từ PH-13 | 029, 030, 039, 074, 075, 076, 077, 078 và 3 API khác |
| ERR-03-027 | 422 | Chưa chạy phát hiện đủ 14 ngày hoặc còn quá nhiều cảnh báo giả chưa xử lý | 041 |

: Mã lỗi control plane ERR-03-001…027

### 6.2. Lỗi gateway trả cho bên gọi (ERR-03-101…130)

Không trả qua API ở chương 3. Plugin APISIX dựng thân `GatewayProblem` (RFC 9457) ở `dh-problem`; bảng sinh từ cùng nguồn `spec.py` với `errors.json` của plugin (SDD §8.4).

| Mã | HTTP | Ý nghĩa | Bên gọi nên làm | Thử lại | Chốt phát sinh |
|---|---|---|---|---|---|
| ERR-03-101 | 400 | Yêu cầu sai cú pháp, lược đồ, kiểu nội dung hoặc vượt giới hạn cấu trúc | Sửa yêu cầu theo `errors[]` | không | `request-validation`, `client-control` |
| ERR-03-102 | 401 | Thiếu thông tin xác thực | Gửi token trong `Authorization` | không | `dh-auth` |
| ERR-03-103 | 401 | Token hoặc khóa API không hợp lệ (chữ ký, `kid`, `iss`, `aud`) | Lấy token mới | không | `dh-auth` |
| ERR-03-104 | 401 | Token đã hết hạn | Lấy token mới rồi gọi lại | không | `dh-auth` |
| ERR-03-105 | 401 | Token đã bị thu hồi | Liên hệ quản trị Datahub | không | `dh-revocation` |
| ERR-03-106 | 401 | Tenant của token không khớp realm hoặc tenant của API | Dùng token của đúng tỉnh | không | `dh-auth` (SEC-80) |
| ERR-03-107 | 403 | Thiếu phạm vi quyền (scope) | Xin cấp thêm phạm vi | không | `dh-auth` |
| ERR-03-108 | 403 | Chứng thư khách không hợp lệ hoặc không khớp token | Dùng đúng chứng thư đã đăng ký | không | `dh-auth`, `ssls` (mTLS) |
| ERR-03-109 | 403 | Bị WAF chặn | Gửi `traceId` cho quản trị nếu nhầm | không | Coraza, `dh-waf-guard` |
| ERR-03-110 | 403 | Địa chỉ nguồn bị chặn | Liên hệ quản trị | không | `dh-ip-block` |
| ERR-03-111 | 403 | HTTT chưa đăng ký sử dụng API hoặc đăng ký hết hiệu lực | Liên hệ chủ dịch vụ | không | `dh-auth` |
| ERR-03-112 | 403 | OPA từ chối theo chính sách truy cập | Xem lý do; liên hệ chủ quản dữ liệu | không | `opa` |
| ERR-03-113 | 403 | Đường dẫn bị chặn hoặc ngoài phạm vi gói | Gọi đúng đường dẫn của gói | không | `dh-path-acl` |
| ERR-03-114 | 404, 405 | Không có route khớp; host không thuộc tenant nào; phương thức không được phép | Kiểm tra địa chỉ, phương thức | không | Bộ định tuyến |
| ERR-03-115 | 413 | Thân yêu cầu quá lớn | Giảm kích thước hoặc dùng kênh tải tệp | không | `client-control` |
| ERR-03-116 | 429 | Vượt tần suất của HTTT (hoặc bị điều tiết, hoặc quá số kết nối WebSocket) | Chờ `Retry-After` rồi thử lại | có | `dh-limit`, `dh-adaptive-throttle` |
| ERR-03-117 | 429 | Vượt hạn ngạch theo chu kỳ | Chờ tới thời điểm đặt lại | có | `dh-limit` |
| ERR-03-118 | 429 | Vượt hạn mức toàn tenant | Chờ giây lát, thử lại | có | `dh-limit` |
| ERR-03-119 | 429 | Vượt giới hạn tốc độ hoặc kết nối theo địa chỉ nguồn | Giảm tốc độ, thử lại | có | `dh-ip-block` |
| ERR-03-120 | 503 | Không có backend khỏe hoặc mạch đang mở | Chờ `Retry-After` | có | `api-breaker`, upstream |
| ERR-03-121 | 504 | Backend quá hạn chờ | Thử lại; báo nếu lặp lại | có | Upstream |
| ERR-03-122 | 502 | Backend phản hồi không hợp lệ | Báo vận hành kèm `traceId` | không | Upstream |
| ERR-03-123 | 503 | API đang dừng hoặc route bị tạm ngừng | Thử lại sau | có | `dh-kill-switch` |
| ERR-03-124 | 503 | Dịch vụ định danh hoặc ủy quyền tạm không khả dụng (JWKS hết hạn đệm, OPA không phản hồi) | Thử lại sau | có | `dh-auth`, `opa` |
| ERR-03-125 | 501 | Không hỗ trợ kiểu chuyển đổi giao thức | Dùng giao thức được hỗ trợ | không | Plugin chuyển đổi (Đợt 3) |
| ERR-03-126 | 410 | Phiên bản API đã hết hạn phục vụ | Chuyển sang phiên bản mới | không | `dh-kill-switch` (phiên bản SUNSET) |
| ERR-03-127 | 403 | HTTT đang bị tạm ngừng truy cập | Liên hệ quản trị Datahub | không | `dh-kill-switch` |
| ERR-03-128 | 421 | SNI hoặc `Host` không khớp dịch vụ nào | Kiểm tra địa chỉ truy cập | không | `dh-edge` |
| ERR-03-129 | 500 | Lỗi nội bộ gateway | Báo vận hành kèm `traceId` | không | `dh-problem` |
| ERR-03-130 | 403 | Phương thức xác thực không đúng với gói của API | Dùng phương thức của gói | không | `dh-auth` |

: Mã lỗi gateway ERR-03-101…130 trả cho bên gọi
<!-- gen:errors:end -->

### 6.3. Thông điệp và trường bổ sung

`title` là tên ngắn cố định của mã; `detail` là câu cụ thể cho trường hợp xảy ra, viết cho người dùng quản trị và có chỗ thay `{…}`. Lỗi `ERR-03-101…130` có `title` ở bảng 6.2 và `detail` do plugin `dh-problem` điền từ `errors.json`, tiếng Việt mặc định, tiếng Anh khi `Accept-Language: en`. Khi giao diện không có câu riêng cho một mã, nó hiển thị `detail` kèm mã lỗi và nút "Sao chép mã truy vết" (FR-00-080).

| Mã | `title` | `detail` mẫu | Trường bổ sung |
|---|---|---|---|
| ERR-03-001 | Không tìm thấy | "Không tìm thấy {đối tượng} {mã}." Cùng câu cho "không tồn tại" và "thuộc tenant khác" | — |
| ERR-03-002 | Mã đã tồn tại | "Mã {mã} đã được dùng. Chọn mã khác." | — |
| ERR-03-003 | Dữ liệu không hợp lệ | "Dữ liệu không hợp lệ: {n} lỗi. Xem danh sách theo trường." | `errors[]` (`field`, `rule`, `message`) |
| ERR-03-004 | Xung đột phiên bản bản ghi | "{Đối tượng} đã được sửa bởi người khác. Tải lại rồi thử lại." | `currentEtag` |
| ERR-03-005 | Cấu hình không hợp lệ | "Cấu hình gateway không hợp lệ: {n} lỗi. Xem danh sách bên dưới." | `findings[]` (`checkId`, `severity`, `objectType`, `objectCode`, `message`) |
| ERR-03-006 | Đang có tổng hợp hoặc phát khác | "Đang có một lần tổng hợp hoặc phát cấu hình cho tỉnh này. Chờ lần đó hoàn tất." | `retryAfterSeconds` |
| ERR-03-007 | Không quay lui được | "Không thể quay lui về phiên bản {v}: {đối tượng} không còn hợp lệ." | `findings[]` |
| ERR-03-008 | Người duyệt trùng người đề nghị | "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." | — |
| ERR-03-009 | Ngoại lệ WAF không hợp lệ | "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày." | `errors[]` |
| ERR-03-010 | Đã có ngoại lệ WAF | "Route này đã có ngoại lệ cho luật {mã luật} đến {ngày}. Thu hồi ngoại lệ cũ hoặc chờ hết hạn." | `ruleId`, `existingExpiresAt` |
| ERR-03-011 | Route chưa đủ điều kiện ra cửa Internet | "Route chưa đủ điều kiện mở ra Internet: {lý do}." | `errors[]` |
| ERR-03-012 | Route thiếu lược đồ hoặc chính sách | "Route {mã} thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền nên chưa được phát." | `findings[]` |
| ERR-03-013 | Plugin hoặc mẫu ngoài danh mục | "Route {mã} dùng plugin {tên} không có trong danh mục được duyệt." | `findings[]` |
| ERR-03-014 | Không ghi được ảnh chụp | "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại." | `retryAfterSeconds` |
| ERR-03-015 | Dịch vụ ký không khả dụng | "Dịch vụ ký cấu hình tạm thời không khả dụng. Thử lại sau; cấu hình đang chạy không đổi." | `retryAfterSeconds` |
| ERR-03-016 | Chứng thư không hợp lệ | "Chứng thư không hợp lệ: {lý do}." | `errors[]` |
| ERR-03-017 | Consumer còn đăng ký hiệu lực | "HTTT còn {n} đăng ký sử dụng đang hiệu lực. Thu hồi đăng ký trước khi gỡ." | `activeSubscriptions` |
| ERR-03-018 | Vượt trần hoặc dưới mức tối thiểu | "Hạn mức phải nằm trong trần của tỉnh ({trần} lượt/giây)." | `ceiling`, `errors[]` |
| ERR-03-019 | Đối tượng đã ở trạng thái đích | "{Route, HTTT} {mã} đã ở trạng thái {trạng thái}." | — |
| ERR-03-020 | Gói nhập không đọc được | "Gói cấu hình hệ cũ không đọc được: {lý do}." | `errors[]` |
| ERR-03-021 | Khoảng truy vấn vượt giới hạn | "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất." | `errors[]` |
| ERR-03-022 | Không đủ quyền | "Bạn không có quyền thực hiện thao tác này." | — |
| ERR-03-023 | Route không ở trạng thái cho phép | "Route {mã} đang ở trạng thái {trạng thái}, không thực hiện được thao tác này." | — |
| ERR-03-024 | Địa chỉ không được chặn | "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn." | — |
| ERR-03-025 | Chuyển tiếp tenant xung đột | "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy." | — |
| ERR-03-026 | Không đọc được số liệu PH-13 | "Chưa lấy được số liệu từ hệ thống giám sát. Thử lại sau." | `retryAfterSeconds` |
| ERR-03-027 | Chưa đủ điều kiện chuyển WAF sang chặn | "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)." | `detectDays`, `requiredDays` |

: Thông điệp và trường bổ sung của mã lỗi control plane

Một mã HTTP ứng với nhiều mã lỗi, nên giao diện và bên gọi dựa vào `code` chứ không dựa vào mã HTTP: `409` có thể là bảy mã (ERR-03-002, 006, 010, 017, 019, 023, 025) và `422` có thể là mười một mã nghiệp vụ (ERR-03-005, 007, 009, 011, 012, 013, 016, 018, 020, 024, 027).

### 6.4. Cách bên gọi xử lý lỗi

Bảng dưới là hướng dẫn thống nhất cho giao diện, PH-01, PH-12 và PH-13. Nguyên tắc: chỉ thử lại lỗi tạm thời, và lệnh thử lại luôn mang cùng `Idempotency-Key` để không tạo bản sao.

| HTTP | Mã thường gặp | Xử lý |
|---|---|---|
| `400` | ERR-03-003, 021 | Sửa dữ liệu theo `errors[]`; không thử lại nguyên văn |
| `401` | Không có mã ERR-03 (Q03-55) | Làm mới token hoặc đăng nhập lại rồi gọi lại |
| `403` | ERR-03-008, 022 | Không thử lại; xin quyền, hoặc nhờ người thứ hai duyệt |
| `404` | ERR-03-001 | Kiểm tra mã; có thể đối tượng thuộc tenant khác |
| `409` | ERR-03-002, 006, 010, 017, 019, 023, 025 | Tải lại trạng thái; ERR-03-006 thử lại sau `retryAfterSeconds` |
| `412` | ERR-03-004 | Tải lại đối tượng (lấy `ETag` mới), áp lại thay đổi của mình rồi gửi |
| `422` | ERR-03-005, 007, 009, 011…013, 016, 018, 020, 024, 027 | Sửa theo `findings[]` hoặc `errors[]`; không thử lại nguyên văn |
| `502`, `503` | ERR-03-014, 015, 026 | Thử lại lũy thừa (bắt đầu từ `Retry-After`, tối đa 5 lần) với cùng `Idempotency-Key`; cấu hình đang chạy không đổi trong lúc đó |

: Cách bên gọi xử lý lỗi của API quản trị

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng chỉ là nguồn sự thật khi máy kiểm được nó. Cổng CI-5 "Hợp đồng" (D04-02) chạy mỗi khi PR đụng tệp hợp đồng hoặc controller; chương này nói PH-03 dùng cổng đó thế nào, kết quả đã chạy ở bản 0.1 và những chỗ lệch có chủ đích.

### 7.1. Vị trí hợp đồng và nguồn sinh

Theo CC-API-01 (D04-01), khi lập trình hợp đồng nằm ở kho mã nguồn: `contracts/openapi/gateway-v1.yaml` và `contracts/asyncapi/gateway-v1.yaml`. Hai tệp ở `datahub-docs/03-thiet-ke/api/ph03/` là bản thiết kế cùng nội dung, sinh từ `spec.py`; khi vào giai đoạn lập trình chép sang `contracts/` và để `spec.py` cùng bộ sinh đi theo. PR đổi hợp đồng phải được duyệt trước hoặc cùng lúc với PR hiện thực.

### 7.2. Các kiểm tra

Mười hai kiểm tra dưới đây chạy ở CI-5; cột cuối cho biết kiểm tra nào chặn merge.

| # | Kiểm tra | Công cụ | Điều kiện đạt | Chặn merge |
|---|---|---|---|---|
| 1 | OpenAPI hợp lệ 3.1 | `openapi-spec-validator`; `spectral:oas` | Không lỗi | Có |
| 2 | OWASP API Security và quy ước CC-API-02 | Spectral với `@stoplight/spectral-owasp-ruleset`, tệp [`ph03/.spectral.yaml`](ph03/.spectral.yaml) | Không lỗi mức `error` | Có |
| 3 | Nhãn `x-datahub-id`, `-fr`, `-permission`, `-errors`; `security` tường minh; `operationId` camelCase duy nhất; phản hồi `default` là `Problem`; thân yêu cầu đóng `additionalProperties` | `tools/check_contracts.py` | Không lỗi | Có |
| 4 | Lệnh ghi có `If-Match`; hành động đổi trạng thái có `If-Match`; operation `x-datahub-idempotent` có `Idempotency-Key` | `tools/check_contracts.py` | Không lỗi | Có |
| 5 | Không lược đồ nào có thuộc tính dạng bí mật (`secret`, `password`, `privateKey`, `apiKey`, `token`, `authorization`, `cookie`…); lược đồ nhật ký lượt gọi và sự kiện WAF không có thân, tiêu đề, giá trị truy vấn | `tools/check_contracts.py` | Không lỗi | Có |
| 6 | Mọi ví dụ (lược đồ, phản hồi lỗi, khối JSON trong tài liệu này) khớp lược đồ | `tools/check_contracts.py` (jsonschema 2020-12) | Không lỗi | Có |
| 7 | Danh mục khớp FRS: 96 API (mã, phương thức, đường dẫn), 57 mã lỗi, 12 sự kiện và topic | `tools/check_contracts.py` đọc FRS §9.1, 9.3, 9.4 | Không lệch | Có |
| 8 | Không thay đổi phá vỡ trong `v1` so với nhánh chính | `oasdiff breaking` | Không thay đổi phá vỡ khi chưa tăng phiên bản chính (CC-API-03, NFR-00-055) | Có |
| 9 | AsyncAPI 3.0 nạp được, mỗi sự kiện có kênh, thông điệp, lược đồ | `@asyncapi/parser` 3 | Không lỗi | Có |
| 10 | Lược đồ sự kiện tương thích `BACKWARD` với bản đã đăng ký | Apicurio (kiểm tương thích khi đăng ký, ADR-070) | Tương thích | Có |
| 11 | Tệp sinh khớp nguồn: chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` không đổi tệp | CI so sánh `git diff` | Không khác | Có |
| 12 | Kiểm thử hợp đồng hai phía: máy chủ thật khớp hợp đồng (sinh từ OpenAPI chạy trên `@SpringBootTest`); phía tiêu dùng (giao diện, PH-01, PH-12, PH-13) kiểm với máy chủ giả sinh từ hợp đồng (QT-CT-03) | D05-02-PH03 | Mọi operation ít nhất một ca dương và một ca âm | Có |

: Kiểm tra hợp đồng của PH-03 trong CI-5

### 7.3. Kết quả đã chạy ở bản 0.1

Bảng dưới ghi kết quả thật của lần chạy khi viết bản 0.1; các kiểm tra chưa chạy được nêu rõ lý do.

| Hạng mục | Kết quả |
|---|---|
| `openapi-gateway.yaml` | Hợp lệ OpenAPI 3.1; 96 operation, 125 lược đồ; `operationId` duy nhất |
| Spectral (`spectral:oas` kế thừa OWASP API Security, bỏ luật CORS có lý do ở 7.4) | 0 lỗi; 270 cảnh báo mức thấp: 265 `string-restricted` (trường văn bản tự do như lý do, mô tả, tên hiển thị không thể có `pattern`), 5 `define-error-validation` (năm `GET` không có tham số nên không có `400`) |
| Ví dụ khớp lược đồ | 35 ví dụ trong OpenAPI, 15 khối JSON trong tài liệu này, 9 ví dụ sự kiện (7 ở AsyncAPI, 2 ở tài liệu); 0 lệch |
| Đối chiếu FRS | 96 API, 57 mã lỗi, 12 sự kiện khớp từng dòng |
| `asyncapi-gateway.yaml` | `@asyncapi/parser` 3: 0 lỗi; một gợi ý mức thông tin (có bản 3.1.0), giữ 3.0 theo quy ước dự án |
| `oasdiff`, Apicurio, kiểm thử hợp đồng hai phía | Chưa chạy: cần nhánh chính có hợp đồng (bản đầu), kho Apicurio và mã `dh-connect`; thiết lập ở giai đoạn lập trình |

: Kết quả kiểm tra hợp đồng bản 0.1

### 7.4. Lệch có chủ đích khỏi bộ luật

Một số luật của bộ luật OWASP không áp dụng đúng cho API quản trị; các chỗ lệch được nêu cùng lý do để người duyệt hợp đồng biết và có thể phản biện.

| Điểm | Lý do |
|---|---|
| Tắt luật `define-cors-origin` | API quản trị gọi qua BFF cùng nguồn gốc, không có CORS; CORS theo route là chức năng của API dữ liệu (FR-03-010, Đợt 2) |
| `claims`, `params`, `payload`, `headers` là bản đồ tự do (`additionalProperties` mở) | Là dữ liệu do bên khác định nghĩa: khẳng định của token mô phỏng (API-03-088), khóa tham số `gw.*` (API-03-087, được kiểm theo bảng tham số ở máy chủ), tham số mẫu chính sách (API-03-067), tiêu đề mô phỏng. Máy chủ kiểm theo miền riêng, không theo lược đồ tĩnh |
| `401` và `500` dùng `GenericProblem` không có `code` | Chưa có mã ERR-03 tương ứng ở FRS §9.1 (Q03-55) |
| Không có operation `health` | Kiểm tra sức khỏe của `dh-connect` là điểm cuối quản trị hạ tầng của Spring Actuator, ngoài hợp đồng nghiệp vụ |

: Chỗ lệch có chủ đích

### 7.5. Lệnh chạy

Các lệnh dưới đây chạy từ thư mục `ph03` và là những gì CI thực hiện.

```bash
cd datahub-docs/03-thiet-ke/api/ph03
python3 tools/gen_openapi.py        # sinh openapi-gateway.yaml
python3 tools/gen_asyncapi.py       # sinh asyncapi-gateway.yaml
python3 tools/gen_md.py             # chèn bảng chương 2, 3, 4, 6 vào D03-04-PH03
python3 ../../../build/tools/sinh_dac_ta_api.py openapi-gateway.yaml ../D03-04-PH03-api-cong-api.md   # chương 10
python3 tools/check_contracts.py    # kiểm hợp đồng, ví dụ, đối chiếu FRS
npx spectral lint openapi-gateway.yaml --ruleset .spectral.yaml
```

## 8. Ánh xạ từ hệ cũ

Hệ cũ có hai nguồn: SRS PH-03 của repo (`docs/07-srs/SRS-PH-03-gateway.md`, mục M5 liệt kê 15 điểm cuối quản trị) và kiểm kê D00-03 phần A. Kiểm tra ngày 26/11/2026 trong `apps/` và `deploy/` không thấy mã hiện thực nào của các điểm cuối đó; mã đang chạy chỉ có `ApisixRouteWriter` ghi tệp route (SDD §2.4, GAP-03-04). Vì vậy không có hợp đồng cũ nào phải giữ tương thích; bảng dưới giúp người đã đọc SRS cũ tìm đúng chỗ.

### 8.1. 15 điểm cuối quản trị của SRS cũ sang API-03

Đường gốc đổi từ `/api/admin/v1/gateway` sang `/api/gateway/v1`.

| Điểm cuối cũ | Chức năng cũ | API-03 mới | Thay đổi |
|---|---|---|---|
| `GET /routes` | Danh sách route đang phục vụ | 001 (002 chi tiết) | Thêm lọc theo trạng thái, cửa vào; trả `allowedActions` |
| `POST /routes` | Tạo route | Không còn | Route do PH-02 sinh từ API đã công bố, không tạo tay; nhập từ gateway cũ: 091, 092, 093 |
| `PUT /routes/{code}` | Cập nhật route, nạp nóng | 008, 009, 010, 051 (thuộc tính riêng); 059, 060 (phát) | Không nạp nóng từng route: mọi thay đổi là ảnh chụp mới có kiểm tra và chữ ký |
| `DELETE /routes/{code}` | Gỡ route | 003 (dừng tạm) | Gỡ hẳn do PH-02 ngừng dùng API; route chuyển `RETIRED` |
| `POST /routes/validate` | Kiểm tra cấu hình không áp dụng | 058 | Kiểm 18 quy tắc CHK (15 mức lỗi, 3 mức cảnh báo), trả `ValidationReport` |
| `GET /upstreams` | Hạ nguồn kèm sức khỏe | 005, 006 | Thêm chi tiết nút, ngưỡng kiểm tra |
| `GET /consumers` | Danh sách bên gọi | 011 (012 chi tiết) | Thêm `syncState`, hạn chứng thư |
| `PUT /consumers/{clientId}/limits` | Đặt hạn mức | 026, 027 (ghi đè); 024 (toàn tenant) | Hạn mức gốc lấy từ gói ở PH-02; PH-03 chỉ ghi đè có thời hạn và lý do |
| `GET /consumers/{clientId}/usage` | Mức sử dụng, hạn ngạch | 029 (030 cảnh báo ngưỡng) | Thêm `degraded` khi Valkey mất |
| `POST /consumers/{clientId}/block` | Chặn tạm bên gọi | 017 (018 mở lại) | Có hiệu lực ≤ 30 giây qua đường nhanh; bắt buộc lý do |
| `GET /waf/blocked` | Nhật ký bị WAF chặn | 039 | Không có nội dung yêu cầu; lọc theo luật, route |
| `POST /waf/exceptions` | Ngoại lệ WAF có thời hạn | 043 (044, 045 duyệt; 046 thu hồi) | Thêm bốn mắt, trạng thái `REQUESTED` |
| `GET /certificates` | Chứng thư và ngày hết hạn | 068 (069 chi tiết) | Thêm gia hạn thủ công 070 |
| `POST /revocations` | Nhận danh sách thu hồi từ PH-12 | 053 (054 đọc) | Scope `gateway:revoke`; lũy đẳng |
| `GET /stats` | Thống kê lưu lượng | 077, 078, 079 | Đọc từ PH-13, không tính ở gateway |

: Điểm cuối quản trị cũ sang API-03

### 8.2. Chức năng hệ cũ (LGC) sang API-03

Bảng nối mỗi mục LGC mà PH-03 phủ (toàn phần hoặc một phần) với API-03 hiện thực nó; kết luận theo D00-03 phần A và FRS §11.1.

| Mã | Chức năng hệ cũ | API-03 | Kết luận |
|---|---|---|---|
| LGC-BUS-041 | Bảo mật route, mã hóa bản tin, bảo mật endpoint | 016, 035 (xác thực công khai, CA khách); 031, 032, 033, 034 (TLS); 014 | Nâng cấp: OAuth 2.1, mTLS |
| LGC-APIM-005 | Start / Stop API | 003, 004; 017…020 (tạm ngừng khẩn cấp) | Giữ nguyên, thêm tạm ngừng khẩn cấp |
| LGC-APIM-011 | Plan bước Secure | 021, 022, 016 | Nâng cấp: thêm OAuth 2.1, mTLS |
| LGC-APIM-012; 013 | Plan bước Restriction: tần suất, hạn ngạch | 021, 022, 025…030 | Giữ nguyên, thêm hạn mức toàn tenant |
| LGC-APIM-014 | Whitelist, blacklist đường dẫn | 021, 022 (`pathAllow`, `pathDeny` của gói); 002 | Giữ nguyên |
| LGC-APIM-015 | Plan bước Policies | 065, 066, 067 | Nâng cấp: mẫu chính sách được duyệt sẵn |
| LGC-APIM-017; 018 | Đường dẫn sử dụng API, endpoint backend | 002, 007; 005, 006 | PH-03 phủ phần thực thi |
| LGC-APIM-019; 020 | Application, Client ID | 011…016 | PH-03 phủ hình chiếu consumer |
| LGC-APIM-022 | Log toàn bộ request, xem chi tiết một log | 074, 075, 076 | Nâng cấp: che dữ liệu, chỉ siêu dữ liệu |
| LGC-APIM-023 | Danh sách gateway đang kết nối | 063, 064 | Thay thế bằng danh sách nút và trạng thái đồng bộ |
| LGC-APIM-024…026 | Chi tiết gateway, giám sát, dashboard | 064, 077, 078, 079 | PH-13 giữ phần giám sát chi tiết |
| LGC-APIM-027 | Audit tác động hệ thống | Mọi lệnh ghi | Kiểm toán ghi theo FR-00, không có API riêng |
| LGC-NFR-006 | Tự từ chối khi vượt ngưỡng, cô lập lỗi | 009, 010, 023, 024 (cấu hình) | Hành vi ở mặt phẳng dữ liệu |

: Chức năng hệ cũ sang API-03

### 8.3. FR cũ của repo sang API-03

Bảng nối 17 FR của SRS cũ với API-03, để người còn nhớ số FR cũ tìm được API mới.

| FR cũ | Tên | API-03 | Ghi chú |
|---|---|---|---|
| 001 | Chấm dứt TLS | 031…035 | |
| 002 | Giảm thiểu tấn công từ chối dịch vụ | 009, 023, 024, 036, 037, 038 | Cộng giới hạn theo IP ở `gw.ip.*` (API-03-087) |
| 003 | Tường lửa ứng dụng web | 039…049 | |
| 004 | Xác minh chữ ký JWT | 052 | Phần xác minh ở mặt phẳng dữ liệu |
| 005 | Kiểm tra token bị thu hồi | 053, 054 | |
| 006 | Kiểm tra phạm vi quyền thô | 002, 055 | |
| 007 | Xác thực chứng thư mTLS | 014, 016, 035 | |
| 008 | Giới hạn tần suất theo client | 021, 022, 025…029 | |
| 009 | Hạn ngạch theo chu kỳ | 029, 030 | |
| 010 | Điều tiết theo tình trạng hạ nguồn | 065…067, 087 (mẫu chính sách và `gw.throttle.*`) | Hành vi ở mặt phẳng dữ liệu, Đợt 2 |
| 011 | Định tuyến yêu cầu | 001, 002, 005, 006, 008 | |
| 012 | Sinh và gắn định danh truy vết | Không có API | Mặt phẳng dữ liệu |
| 013 | Chuyển đổi giao thức | 002 (cấu hình trong chi tiết route) | Mặt phẳng dữ liệu |
| 014 | Xử lý CORS | 050, 051 | |
| 015 | Nạp nóng cấu hình | 056…064 | Thay bằng ảnh chụp có chữ ký |
| 016 | Kiểm tra sức khỏe hạ nguồn | 006, 063, 064 | |
| 017 | Phát telemetry | 074…079, 084 | |

: FR cũ của repo sang API-03

### 8.4. Điều chỉnh hợp đồng so với SRS cũ

Một số quy ước của SRS cũ được thay vì đã chốt sau SRS đó (đa tenant, phân quyền mịn, mã lỗi ổn định); bảng nêu từng điểm và lý do.

| Mục | SRS cũ | Hợp đồng mới | Lý do |
|---|---|---|---|
| Xác thực quản trị | Bearer JWT, vai trò `PLATFORM_ADMIN` hoặc `SECURITY_OFFICER` | `PERM-03-*` theo vai trò (10 quyền), bốn mắt ở máy chủ, scope dịch vụ cho máy | Phân quyền mịn, tách nhiệm vụ (D02-08) |
| `type` của lỗi | `https://lgsp.local/errors/rate-limit-exceeded` | `https://datahub.gov.vn/errors/ERR-03-nnn` | Mã ổn định, tra được ở chương 6 |
| Thân `429` | `limit`, `windowSeconds` ở cấp trên cùng | Đối tượng `rateLimit` (`window`, `limit`, `remaining`, `resetAt`) | Gom nhóm, thêm `remaining`, `resetAt` |
| Tiêu đề truy vết | `X-Trace-Id` | `X-Trace-Id` ở cổng (giữ) cộng `traceparent` ở API quản trị | Cổng giữ để HTTT không phải đổi; API mới theo W3C |
| Route | Cấu hình JSON viết tay, trường tiếng Việt không dấu (`duongDan`, `phuongThuc`) | Sinh từ PH-02; trường tiếng Anh camelCase | D00-01 §6; xem 8.5 |
| Mã `404` | Không có route khớp | ERR-03-114 (404, 405) | Thêm phương thức không được phép |
| Điểm cuối `healthz`, `readyz` | Trong danh mục | Ngoài hợp đồng (Actuator) | Mục 7.4 |

: Điều chỉnh hợp đồng so với SRS cũ

### 8.5. Trường của cấu hình route cũ sang mới

Mẫu cấu hình route ở SRS cũ viết tay bằng trường tiếng Việt không dấu; bảng ánh xạ từng trường sang tên trong hợp đồng mới.

| Trường cũ (SRS §5.4) | Trường mới | Ghi chú |
|---|---|---|
| `routeCode` | `routeCode` | Mã = mã API kèm phiên bản |
| `duongDan` | `pathPattern` | |
| `phuongThuc` | `methods` | |
| `doUuTien` | `priority` | |
| `upstream` | `upstreamCode` | |
| `timeoutMs` | `timeouts.readMs` (API-03-010) | Thêm `connectMs`, `sendMs` |
| `maxBodyBytes` | `bodyMaxBytes`, `requestLimits` (API-03-009) | |
| `phamViYeuCau` | `requiredScopes` | |
| `batBuocMtls` | `requireMtls` | Suy ra từ `securityMode` của gói |
| `plugins` (từng plugin cấu hình tay) | `policySetCode` (mẫu chính sách được duyệt) | Tenant không đưa plugin mới (ERR-03-013) |

: Trường cấu hình route cũ sang mới

## 9. Câu hỏi mở

Năm câu hỏi dưới đây phát sinh khi chuyển FRS, SDD và CSDL thành hợp đồng giao diện. Dải `Q03-55…59` dành cho tập API (D00-04 §3.1); câu hỏi của FRS (Q03-01…12), SDD (Q03-20…27), màn hình, test, use case (Q03-45…49) và CSDL (Q03-50…54) nằm ở tập tương ứng.

> **Câu hỏi mở Q03-55:** FRS §9.1 chưa có mã lỗi cho hai tình huống ở mặt phẳng điều khiển: `401` (thiếu token, token hết hạn) và `500` (lỗi nội bộ của `dh-connect`). Hợp đồng hiện dùng `GenericProblem` không có `code` ERR-03 cho hai trường hợp này, trái với thông lệ "mọi lỗi có mã" của các phân hệ khác. Đề xuất: thêm hai mã mới ngay sau mã cuối của dải control plane (một cho `401`, một cho `500`) vào FRS §9.1 và bảng 6.1, rồi đổi `GenericProblem` thành `ProblemDetails`. Cần ý kiến nhóm viết FRS PH-03 và D00-01 (nếu mã `401`, `500` dùng chung toàn hệ thống thì chuyển về nhóm FR-00).

> **Câu hỏi mở Q03-56:** Phân trang `page`, `size`, `totalElements` (quy ước D00-04) phù hợp với dữ liệu ở PostgreSQL nhưng không phù hợp với nhật ký lượt gọi và sự kiện chặn WAF đọc từ ClickHouse: giả định 5 triệu bản ghi mỗi ngày mỗi tenant (GĐ-03-02) và khoảng tra cứu tới 31 ngày nên đếm tổng và bỏ qua `page × size` dòng đều đắt, p95 ≤ 3 giây (NFR-03-022) khó giữ khi `page` lớn. Đề xuất: API-03-039, 074 dùng phân trang con trỏ (`cursor`, `limit`, phản hồi `page.next`) như PH-05, không có `totalElements` chính xác (chỉ ước lượng `approxTotal`), các API còn lại giữ `page`, `size`. Cần ý kiến nhóm giao diện và PH-13; nếu chấp nhận thì đổi OpenAPI và FRS §9.4 (ghi chú) ở bản 0.2.

> **Câu hỏi mở Q03-57:** Hai điểm về hợp đồng với PH-01 ở API-03-013, 014. (a) `If-Match` đang tùy chọn để saga gọi lại không vướng ETag, nghĩa là ghi sau thắng. Với consumer, người vận hành có thể vừa tạm ngừng khẩn cấp (API-03-017) vừa bị saga `PUT state=ACTIVE` ghi đè. Đề xuất: trạng thái tạm ngừng khẩn cấp (`emergencyBlock`) độc lập với `state`; `PUT` của PH-01 không bao giờ gỡ nó, chỉ API-03-018 gỡ; phản hồi luôn trả `emergencyBlock` để saga biết. (b) `trustedSource=true` chỉ do SO duyệt (FR-03-046) nhưng lời gọi là token dịch vụ nên `dh-connect` không tự kiểm được người duyệt. Đề xuất: PH-01 ghi bằng chứng duyệt của SO ở hồ sơ kết nạp, `dh-connect` ghi kiểm toán cờ này và phát EVT-03-09 mức Trung bình khi cờ chuyển sang `true`. Cần ý kiến PH-01 và ATTT.

> **Câu hỏi mở Q03-58:** Phạm vi scope `gateway:read-state` cho PH-13. FRS §3.2 chỉ nói "đọc cấu hình, trạng thái nút". Hợp đồng này đề xuất 8 `GET`: API-03-001, 002, 011, 012, 056, 057, 063, 064; không gồm nhật ký lượt gọi (PH-13 đã có dữ liệu gốc ở ClickHouse) và không gồm cấu hình WAF, hạn mức. Cần PH-13 xác nhận có cần thêm API-03-023, 040, 077 hay không, và xác nhận tài khoản dịch vụ của PH-13 chỉ đọc, không có `PERM-03-*` của người dùng.

> **Câu hỏi mở Q03-59:** Tệp xuất nhật ký lượt gọi và báo cáo (API-03-076, 090) chứa địa chỉ nguồn nên là dữ liệu nhạy cảm vừa phải. Hợp đồng trả `downloadUrl` có chữ ký, hết hạn sau 24 giờ. Chưa chốt: tệp lưu ở đâu (đề xuất bucket riêng theo tenant ở Garage, mã hóa phía máy chủ), ai dọn (đề xuất `dh-connect` xóa sau 24 giờ), và có ghi kiểm toán khi tải xuống (đề xuất có, kèm địa chỉ người tải). Cần ý kiến ATTT và PH-13 (nếu PH-13 lưu tệp xuất thì API-03-076 chỉ chuyển tiếp).

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ [`ph03/openapi-gateway.yaml`](ph03/openapi-gateway.yaml) bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI (hoặc `spec.py`) rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục: mục đích, phương thức và đường dẫn, quyền, FR hiện thực, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú. Mục "Lỗi" liệt kê mã HTTP và mã `ERR-03-…` của riêng thao tác; ý nghĩa từng mã ở chương 6. Với API-03-013, 014, 015, 053, mục "Quyền" ghi "Token dịch vụ": scope cụ thể (`gateway:sync`, `gateway:revoke`) nằm ở mục "Ghi chú" và ở bảng 3.1.

<!-- gen:dac-ta-api:start -->

### Route và upstream

#### API-03-001 · Danh sách route

::: dac-ta
**Mục đích.** Danh sách route.

**Phương thức, đường dẫn.** `GET /routes`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-028.

**Tham số.** `q` (query, string, tùy chọn); `state` (query, array, tùy chọn); `exposure` (query, Exposure, tùy chọn); `apiCode` (query, string, tùy chọn); `upstreamCode` (query, UpstreamCode, tùy chọn); `sort` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RoutePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách route của tenant theo lọc; mặc định sắp theo `routeCode`.
:::

#### API-03-002 · Chi tiết route

::: dac-ta
**Mục đích.** Chi tiết route.

**Phương thức, đường dẫn.** `GET /routes/{routeCode}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-009, FR-03-017, FR-03-028, FR-03-033, FR-03-034, FR-03-035.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `eligibility` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm. Có `impact` (`consumersLast15m`, `routesAffected`) để nêu hậu quả bằng số trước khi xác nhận; có `eligibility` (danh sách điều kiện mở cửa Internet, đạt hoặc chưa) khi gọi với `eligibility=true`. Có `ETag`.
:::

#### API-03-003 · Dừng API

::: dac-ta
**Mục đích.** Dừng API.

**Phương thức, đường dẫn.** `POST /routes/{routeCode}:stop`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-036.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RouteStopRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022, ERR-03-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển `ACTIVE` sang `STOPPED`; lượt gọi nhận ERR-03-123 (503) kèm `Retry-After`. Phát EVT-03-03 và ghi kiểm toán.
:::

#### API-03-004 · Mở API

::: dac-ta
**Mục đích.** Mở API.

**Phương thức, đường dẫn.** `POST /routes/{routeCode}:start`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-036.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022, ERR-03-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển `STOPPED` sang `ACTIVE`. Route `SUSPENDED` không mở ở đây mà ở API-03-020.
:::

#### API-03-005 · Danh sách upstream

::: dac-ta
**Mục đích.** Danh sách upstream.

**Phương thức, đường dẫn.** `GET /upstreams`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-029.

**Tham số.** `q` (query, string, tùy chọn); `unhealthyOnly` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UpstreamPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách upstream.
:::

#### API-03-006 · Chi tiết upstream

::: dac-ta
**Mục đích.** Chi tiết upstream.

**Phương thức, đường dẫn.** `GET /upstreams/{upstreamCode}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-029, FR-03-030.

**Tham số.** `upstreamCode` (path, UpstreamCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UpstreamDetail`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trả danh sách nút kèm tình trạng kiểm tra sức khỏe mới nhất.
:::

#### API-03-007 · Các phiên bản API song song của route

::: dac-ta
**Mục đích.** Các phiên bản API song song của route.

**Phương thức, đường dẫn.** `GET /routes/{routeCode}/versions`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-035.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteVersionList`; trường bắt buộc: `items`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Các route cùng `apiCode` khác phiên bản đang phục vụ song song, kèm ngày ngừng dùng và route kế nhiệm.
:::

#### API-03-008 · Đặt cửa vào của route (EXT cần bốn mắt)

::: dac-ta
**Mục đích.** Đặt cửa vào của route (EXT cần bốn mắt).

**Phương thức, đường dẫn.** `PUT /routes/{routeCode}/exposure`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-038.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ExposureUpdate`; trường bắt buộc: `exposure`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; `202` đã nhận, xử lý bất đồng bộ, `ChangeRequest`; trường bắt buộc: `requestId`, `changeType`, `state`, `requestedBy`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-011, ERR-03-022, ERR-03-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đặt `INT` có hiệu lực ngay (200). Đặt `EXT` tạo yêu cầu thay đổi bốn mắt, trả 202 kèm `ChangeRequest`; SO duyệt ở API-03-072 (BR-03-015, 019).
:::

#### API-03-009 · Đặt giới hạn kích thước và cấu trúc yêu cầu

::: dac-ta
**Mục đích.** Đặt giới hạn kích thước và cấu trúc yêu cầu.

**Phương thức, đường dẫn.** `PUT /routes/{routeCode}/request-limits`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-009.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RequestLimits`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-018, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giới hạn kích thước thân và cấu trúc JSON theo route; vượt trần tenant (`gw.body.maxBytes`) trả ERR-03-018.
:::

#### API-03-010 · Đặt thời hạn chờ của route

::: dac-ta
**Mục đích.** Đặt thời hạn chờ của route.

**Phương thức, đường dẫn.** `PUT /routes/{routeCode}/timeouts`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-031.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TimeoutsUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-018, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thời hạn chờ và ngắt mạch; trần 30.000 ms theo CV 631 (ERR-03-018 khi vượt).
:::

### Consumer

#### API-03-011 · Danh sách consumer

::: dac-ta
**Mục đích.** Danh sách consumer.

**Phương thức, đường dẫn.** `GET /consumers`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-046.

**Tham số.** `q` (query, string, tùy chọn); `state` (query, array, tùy chọn); `authMethod` (query, array, tùy chọn); `syncState` (query, array, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `certExpiringDays` (query, integer, tùy chọn); `sort` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsumerPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-13 đọc bằng scope `gateway:read-state`.
:::

#### API-03-012 · Chi tiết consumer

::: dac-ta
**Mục đích.** Chi tiết consumer.

**Phương thức, đường dẫn.** `GET /consumers/{consumerCode}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-014, FR-03-016, FR-03-046.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsumerDetail`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không có bí mật. Có `impact` và `subscriptions` (API, gói, hiệu lực lấy từ bản chiếu PH-02, cho tab Đăng ký ở UI-03-05). Có `ETag`.
:::

#### API-03-013 · Tạo hoặc cập nhật consumer

::: dac-ta
**Mục đích.** Tạo hoặc cập nhật consumer.

**Phương thức, đường dẫn.** `PUT /consumers/{consumerCode}`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-03-046.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc); `If-Match` (header, string, tùy chọn); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConsumerUpsert`; trường bắt buộc: `systemCode`, `state`, `authMethod`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ConsumerDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; `201` đã tạo, `ConsumerDetail`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-002, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `gateway:sync` (PH-01 trong saga kết nạp). Tạo mới trả 201, cập nhật trả 200. Lũy đẳng theo `Idempotency-Key`. Thân chứa trường dạng bí mật bị từ chối bằng ERR-03-003.
:::

#### API-03-014 · Cập nhật thông tin xác thực công khai của consumer

::: dac-ta
**Mục đích.** Cập nhật thông tin xác thực công khai của consumer.

**Phương thức, đường dẫn.** `PUT /consumers/{consumerCode}/credentials`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-03-046.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc); `If-Match` (header, string, tùy chọn); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CredentialsUpsert`; trường bắt buộc: `authMethod`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `CredentialsPublic`; trường bắt buộc: `consumerCode`, `authMethod`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-016, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `gateway:sync`. Chỉ phần công khai: vân tay SHA-256 chứng thư, ngày hết hạn, băm khóa API. Gateway không lưu bí mật của client.
:::

#### API-03-015 · Gỡ consumer

::: dac-ta
**Mục đích.** Gỡ consumer.

**Phương thức, đường dẫn.** `DELETE /consumers/{consumerCode}`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-03-046.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-017, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `gateway:sync` (bù trừ saga). Còn đăng ký sử dụng hiệu lực: ERR-03-017 kèm `activeSubscriptions`. Xóa mềm (BR-03-029).
:::

#### API-03-016 · Thông tin xác thực công khai của consumer

::: dac-ta
**Mục đích.** Thông tin xác thực công khai của consumer.

**Phương thức, đường dẫn.** `GET /consumers/{consumerCode}/credentials`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-002, FR-03-014.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CredentialsPublic`; trường bắt buộc: `consumerCode`, `authMethod`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Vân tay cắt ngắn, không bao giờ trả khóa API hay bí mật.
:::

### Tạm ngừng khẩn cấp

#### API-03-017 · Tạm ngừng khẩn cấp consumer

::: dac-ta
**Mục đích.** Tạm ngừng khẩn cấp consumer.

**Phương thức, đường dẫn.** `POST /consumers/{consumerCode}:suspend`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-047.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc); `If-Match` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsumerDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Có hiệu lực qua đường nhanh Valkey ≤ 30 giây (`gw.emergency.propagateSeconds`), không chờ ảnh chụp và không cần người duyệt. `If-Match` tùy chọn để không chậm trong sự cố. Lượt gọi nhận ERR-03-127.
:::

#### API-03-018 · Mở lại consumer

::: dac-ta
**Mục đích.** Mở lại consumer.

**Phương thức, đường dẫn.** `POST /consumers/{consumerCode}:resume`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-047.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsumerDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mở lại consumer đã tạm ngừng; ghi lý do và kiểm toán.
:::

#### API-03-019 · Tạm ngừng khẩn cấp route

::: dac-ta
**Mục đích.** Tạm ngừng khẩn cấp route.

**Phương thức, đường dẫn.** `POST /routes/{routeCode}:suspend`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-047.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-019, ERR-03-022, ERR-03-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chuyển route sang `SUSPENDED` qua đường nhanh Valkey; lượt gọi nhận ERR-03-123. `If-Match` tùy chọn.
:::

#### API-03-020 · Mở lại route

::: dac-ta
**Mục đích.** Mở lại route.

**Phương thức, đường dẫn.** `POST /routes/{routeCode}:resume`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-047.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RouteDetail`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022, ERR-03-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mở lại route `SUSPENDED`.
:::

### Chính sách chiếu từ gói

#### API-03-021 · Danh sách chính sách chiếu từ gói

::: dac-ta
**Mục đích.** Danh sách chính sách chiếu từ gói.

**Phương thức, đường dẫn.** `GET /plan-policies`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-015, FR-03-016, FR-03-020, FR-03-021.

**Tham số.** `planCode` (query, string, tùy chọn); `apiCode` (query, string, tùy chọn); `securityMode` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlanPolicyPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bản chiếu từ gói của PH-02; PH-03 chỉ đọc.
:::

#### API-03-022 · Chi tiết chính sách chiếu từ gói

::: dac-ta
**Mục đích.** Chi tiết chính sách chiếu từ gói.

**Phương thức, đường dẫn.** `GET /plan-policies/{policyCode}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-015, FR-03-017, FR-03-020, FR-03-021.

**Tham số.** `policyCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PlanPolicy`; trường bắt buộc: `policyCode`, `planCode`, `securityMode`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết chính sách chiếu từ gói.
:::

### Hạn mức và hạn ngạch

#### API-03-023 · Hạn mức toàn tenant

::: dac-ta
**Mục đích.** Hạn mức toàn tenant.

**Phương thức, đường dẫn.** `GET /tenant-limits`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-023.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantLimits`; trường bắt buộc: `limitPerSecond`, `ceiling`, `version`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạn mức toàn tenant, mặc định 500 lượt/giây; nhóm `ESSENTIAL` không được miễn.
:::

#### API-03-024 · Đặt hạn mức toàn tenant (hạ cần bốn mắt)

::: dac-ta
**Mục đích.** Đặt hạn mức toàn tenant (hạ cần bốn mắt).

**Phương thức, đường dẫn.** `PUT /tenant-limits`.

**Quyền.** `PERM-03-limit`.

**FR hiện thực.** FR-03-023.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantLimitsUpdate`; trường bắt buộc: `limitPerSecond`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantLimits`; trường bắt buộc: `limitPerSecond`, `ceiling`, `version`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; `202` đã nhận, xử lý bất đồng bộ, `ChangeRequest`; trường bắt buộc: `requestId`, `changeType`, `state`, `requestedBy`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-004, ERR-03-018, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tăng hiệu lực ngay (200). Hạ cần bốn mắt: trả 202 kèm yêu cầu thay đổi. Vượt trần hợp đồng ERR-03-018 kèm `ceiling`. Phát EVT-03-11.
:::

#### API-03-025 · Danh sách ghi đè hạn mức

::: dac-ta
**Mục đích.** Danh sách ghi đè hạn mức.

**Phương thức, đường dẫn.** `GET /rate-limit-overrides`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-024, FR-03-025.

**Tham số.** `consumerCode` (query, ConsumerCode, tùy chọn); `routeCode` (query, RouteCode, tùy chọn); `scope` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RateLimitOverridePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách ghi đè hạn mức.
:::

#### API-03-026 · Tạo ghi đè hạn mức

::: dac-ta
**Mục đích.** Tạo ghi đè hạn mức.

**Phương thức, đường dẫn.** `POST /rate-limit-overrides`.

**Quyền.** `PERM-03-limit`.

**FR hiện thực.** FR-03-024.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RateLimitOverrideWrite`; trường bắt buộc: `scope`, `limit`, `windowSeconds`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RateLimitOverride`; trường bắt buộc: `overrideId`, `scope`, `limit`, `windowSeconds`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-018, ERR-03-022, ERR-03-023 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tính năng Đợt 2 (cờ `gateway.overrides.enabled`). Thứ tự ưu tiên ở FR-03-024. Phát EVT-03-11.
:::

#### API-03-027 · Sửa ghi đè hạn mức

::: dac-ta
**Mục đích.** Sửa ghi đè hạn mức.

**Phương thức, đường dẫn.** `PUT /rate-limit-overrides/{overrideId}`.

**Quyền.** `PERM-03-limit`.

**FR hiện thực.** FR-03-024.

**Tham số.** `overrideId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RateLimitOverrideWrite`; trường bắt buộc: `scope`, `limit`, `windowSeconds`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RateLimitOverride`; trường bắt buộc: `overrideId`, `scope`, `limit`, `windowSeconds`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-018, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa ghi đè hạn mức.
:::

#### API-03-028 · Xóa ghi đè hạn mức

::: dac-ta
**Mục đích.** Xóa ghi đè hạn mức.

**Phương thức, đường dẫn.** `DELETE /rate-limit-overrides/{overrideId}`.

**Quyền.** `PERM-03-limit`.

**FR hiện thực.** FR-03-024.

**Tham số.** `overrideId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xóa mềm; phát EVT-03-11.
:::

#### API-03-029 · Mức dùng hạn mức, hạn ngạch của consumer

::: dac-ta
**Mục đích.** Mức dùng hạn mức, hạn ngạch của consumer.

**Phương thức, đường dẫn.** `GET /consumers/{consumerCode}/usage`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-021, FR-03-022, FR-03-027.

**Tham số.** `consumerCode` (path, ConsumerCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConsumerUsage`; trường bắt buộc: `consumerCode`, `rates`, `quotas`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mức dùng đọc từ Valkey và ClickHouse; `degraded=true` khi bộ đếm đang suy giảm theo FR-03-026.
:::

#### API-03-030 · Cảnh báo ngưỡng hạn ngạch

::: dac-ta
**Mục đích.** Cảnh báo ngưỡng hạn ngạch.

**Phương thức, đường dẫn.** `GET /quota-alerts`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-022.

**Tham số.** `consumerCode` (query, ConsumerCode, tùy chọn); `percent` (query, integer, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QuotaAlertPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cảnh báo ngưỡng hạn ngạch.
:::

### Lớp biên và TLS

#### API-03-031 · Hồ sơ TLS đang áp dụng ở hai cửa vào

::: dac-ta
**Mục đích.** Hồ sơ TLS đang áp dụng ở hai cửa vào.

**Phương thức, đường dẫn.** `GET /edge/tls-profile`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-001.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TlsProfile`; trường bắt buộc: `gates`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hồ sơ TLS 1.3 mặc định, nhóm mã, HSTS, OCSP stapling cho `apisix-ext` và `apisix-int`.
:::

#### API-03-032 · Danh sách ngoại lệ TLS 1.2

::: dac-ta
**Mục đích.** Danh sách ngoại lệ TLS 1.2.

**Phương thức, đường dẫn.** `GET /tls-exceptions`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-001.

**Tham số.** `state` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TlsExceptionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách ngoại lệ TLS 1.2.
:::

#### API-03-033 · Tạo ngoại lệ TLS 1.2 có thời hạn

::: dac-ta
**Mục đích.** Tạo ngoại lệ TLS 1.2 có thời hạn.

**Phương thức, đường dẫn.** `POST /tls-exceptions`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-001.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TlsExceptionCreate`; trường bắt buộc: `hostPattern`, `reason`, `expiresAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TlsException`; trường bắt buộc: `exceptionId`, `hostPattern`, `state`, `expiresAt`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-018, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cho phép TLS 1.2 tạm thời cho một host; tối đa 180 ngày (`gw.tls.exceptionMaxDays`).
:::

#### API-03-034 · Thu hồi ngoại lệ TLS 1.2

::: dac-ta
**Mục đích.** Thu hồi ngoại lệ TLS 1.2.

**Phương thức, đường dẫn.** `POST /tls-exceptions/{exceptionId}:revoke`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-001.

**Tham số.** `exceptionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TlsException`; trường bắt buộc: `exceptionId`, `hostPattern`, `state`, `expiresAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Thu hồi ngoại lệ TLS 1.2.
:::

#### API-03-035 · Bộ CA tin cậy cho chứng thư khách mTLS

::: dac-ta
**Mục đích.** Bộ CA tin cậy cho chứng thư khách mTLS.

**Phương thức, đường dẫn.** `GET /edge/client-ca-bundles`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-002, FR-03-049.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClientCaBundle`; trường bắt buộc: `items`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bộ CA tin cậy và tuổi CRL (làm mới mỗi giờ).
:::

### Chặn địa chỉ nguồn

#### API-03-036 · Danh sách địa chỉ đang bị chặn

::: dac-ta
**Mục đích.** Danh sách địa chỉ đang bị chặn.

**Phương thức, đường dẫn.** `GET /ip-blocks`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-003, FR-03-004.

**Tham số.** `source` (query, string, tùy chọn); `cidr` (query, Cidr, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IpBlockPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách địa chỉ đang bị chặn.
:::

#### API-03-037 · Chặn địa chỉ nguồn thủ công

::: dac-ta
**Mục đích.** Chặn địa chỉ nguồn thủ công.

**Phương thức, đường dẫn.** `POST /ip-blocks`.

**Quyền.** `PERM-03-waf`.

**FR hiện thực.** FR-03-004.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IpBlockCreate`; trường bắt buộc: `cidr`, `durationMinutes`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `IpBlock`; trường bắt buộc: `blockId`, `cidr`, `source`, `expiresAt`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022, ERR-03-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi khóa chặn vào Valkey sau khi commit cơ sở dữ liệu; phát EVT-03-09.
:::

#### API-03-038 · Bỏ chặn địa chỉ nguồn

::: dac-ta
**Mục đích.** Bỏ chặn địa chỉ nguồn.

**Phương thức, đường dẫn.** `DELETE /ip-blocks/{blockId}`.

**Quyền.** `PERM-03-waf`.

**FR hiện thực.** FR-03-004.

**Tham số.** `blockId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bỏ chặn địa chỉ nguồn.
:::

### WAF

#### API-03-039 · Sự kiện chặn của WAF

::: dac-ta
**Mục đích.** Sự kiện chặn của WAF.

**Phương thức, đường dẫn.** `GET /waf/events`.

**Quyền.** `PERM-03-waf-request`.

**FR hiện thực.** FR-03-005.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `routeCode` (query, RouteCode, tùy chọn); `ruleId` (query, string, tùy chọn); `action` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafEventPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-021, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sự kiện chặn của WAF (đọc từ PH-13). Không có nội dung yêu cầu.
:::

#### API-03-040 · Chế độ WAF và điều kiện chuyển sang chặn

::: dac-ta
**Mục đích.** Chế độ WAF và điều kiện chuyển sang chặn.

**Phương thức, đường dẫn.** `GET /waf/mode`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-006.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafModeInfo`; trường bắt buộc: `scopes`, `eligibleForBlock`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kèm điều kiện chuyển sang `BLOCK`: 14 ngày phát hiện và số cảnh báo giả chưa xử lý dưới `gw.waf.fpReviewMax`.
:::

#### API-03-041 · Đổi chế độ WAF (cần bốn mắt)

::: dac-ta
**Mục đích.** Đổi chế độ WAF (cần bốn mắt).

**Phương thức, đường dẫn.** `PUT /waf/mode`.

**Quyền.** `PERM-03-waf`.

**FR hiện thực.** FR-03-006.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WafModeUpdate`; trường bắt buộc: `mode`, `scope`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafModeInfo`; trường bắt buộc: `scopes`, `eligibleForBlock`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; `202` đã nhận, xử lý bất đồng bộ, `ChangeRequest`; trường bắt buộc: `requestId`, `changeType`, `state`, `requestedBy`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022, ERR-03-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần bốn mắt: trả 202 kèm `ChangeRequest`; người duyệt (API-03-072) khác người đề nghị.
:::

#### API-03-042 · Danh sách ngoại lệ luật WAF

::: dac-ta
**Mục đích.** Danh sách ngoại lệ luật WAF.

**Phương thức, đường dẫn.** `GET /waf/exceptions`.

**Quyền.** `PERM-03-waf-request`.

**FR hiện thực.** FR-03-007.

**Tham số.** `state` (query, array, tùy chọn); `routeCode` (query, RouteCode, tùy chọn); `ruleId` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafExceptionPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách ngoại lệ luật WAF.
:::

#### API-03-043 · Đề nghị ngoại lệ luật WAF

::: dac-ta
**Mục đích.** Đề nghị ngoại lệ luật WAF.

**Phương thức, đường dẫn.** `POST /waf/exceptions`.

**Quyền.** `PERM-03-waf-request`.

**FR hiện thực.** FR-03-007.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WafExceptionCreate`; trường bắt buộc: `routeCode`, `ruleId`, `reason`, `expiresAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `WafException`; trường bắt buộc: `exceptionId`, `routeCode`, `ruleId`, `state`, `expiresAt`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-009, ERR-03-010, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái `REQUESTED`, chưa có hiệu lực ở gateway. TA, TO, SO đề nghị; chỉ SO duyệt. Phát EVT-03-05.
:::

#### API-03-044 · Duyệt ngoại lệ luật WAF

::: dac-ta
**Mục đích.** Duyệt ngoại lệ luật WAF.

**Phương thức, đường dẫn.** `POST /waf/exceptions/{exceptionId}:approve`.

**Quyền.** `PERM-03-waf-approve`.

**FR hiện thực.** FR-03-007.

**Tham số.** `exceptionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafException`; trường bắt buộc: `exceptionId`, `routeCode`, `ruleId`, `state`, `expiresAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-008, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người đề nghị (ERR-03-008). Chuyển `ACTIVE` và kích hoạt tổng hợp ảnh chụp mới.
:::

#### API-03-045 · Từ chối ngoại lệ luật WAF

::: dac-ta
**Mục đích.** Từ chối ngoại lệ luật WAF.

**Phương thức, đường dẫn.** `POST /waf/exceptions/{exceptionId}:reject`.

**Quyền.** `PERM-03-waf-approve`.

**FR hiện thực.** FR-03-007.

**Tham số.** `exceptionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafException`; trường bắt buộc: `exceptionId`, `routeCode`, `ruleId`, `state`, `expiresAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-008, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối ngoại lệ luật WAF.
:::

#### API-03-046 · Thu hồi ngoại lệ luật WAF

::: dac-ta
**Mục đích.** Thu hồi ngoại lệ luật WAF.

**Phương thức, đường dẫn.** `POST /waf/exceptions/{exceptionId}:revoke`.

**Quyền.** `PERM-03-waf`.

**FR hiện thực.** FR-03-007.

**Tham số.** `exceptionId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WafException`; trường bắt buộc: `exceptionId`, `routeCode`, `ruleId`, `state`, `expiresAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ khỏi ảnh chụp kế tiếp.
:::

#### API-03-047 · Danh sách luật vá ảo

::: dac-ta
**Mục đích.** Danh sách luật vá ảo.

**Phương thức, đường dẫn.** `GET /waf/virtual-patches`.

**Quyền.** `PERM-03-waf-request`.

**FR hiện thực.** FR-03-008.

**Tham số.** `state` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VirtualPatchPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tính năng Đợt 2 (cờ `gateway.virtualPatch.enabled`).
:::

#### API-03-048 · Tạo luật vá ảo khẩn cấp

::: dac-ta
**Mục đích.** Tạo luật vá ảo khẩn cấp.

**Phương thức, đường dẫn.** `POST /waf/virtual-patches`.

**Quyền.** `PERM-03-waf`.

**FR hiện thực.** FR-03-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VirtualPatchCreate`; trường bắt buộc: `ruleText`, `appliesTo`, `reason`, `expiresAt`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `VirtualPatch`; trường bắt buộc: `patchId`, `ruleText`, `state`, `expiresAt`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-009, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Luật SecLang tối đa 4 KiB, có lý do và hạn.
:::

#### API-03-049 · Gỡ luật vá ảo

::: dac-ta
**Mục đích.** Gỡ luật vá ảo.

**Phương thức, đường dẫn.** `POST /waf/virtual-patches/{patchId}:retire`.

**Quyền.** `PERM-03-waf`.

**FR hiện thực.** FR-03-008.

**Tham số.** `patchId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VirtualPatch`; trường bắt buộc: `patchId`, `ruleText`, `state`, `expiresAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gỡ luật vá ảo.
:::

### CORS

#### API-03-050 · Danh sách chính sách CORS theo route

::: dac-ta
**Mục đích.** Danh sách chính sách CORS theo route.

**Phương thức, đường dẫn.** `GET /cors-policies`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-010.

**Tham số.** `routeCode` (query, RouteCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CorsPolicyPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tính năng Đợt 2 (cờ `gateway.cors.enabled`).
:::

#### API-03-051 · Đặt chính sách CORS của route

::: dac-ta
**Mục đích.** Đặt chính sách CORS của route.

**Phương thức, đường dẫn.** `PUT /cors-policies/{routeCode}`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-010.

**Tham số.** `routeCode` (path, RouteCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CorsPolicyWrite`; trường bắt buộc: `allowedOrigins`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CorsPolicy`; trường bắt buộc: `routeCode`, `allowedOrigins`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không dùng ký tự đại diện cho nguồn gốc (BR-03-012).
:::

### Xác thực, thu hồi, ủy quyền

#### API-03-052 · Trạng thái bộ đệm JWKS của các nút

::: dac-ta
**Mục đích.** Trạng thái bộ đệm JWKS của các nút.

**Phương thức, đường dẫn.** `GET /auth/jwks-status`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-012.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `JwksStatus`; trường bắt buộc: `nodes`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Trạng thái bộ đệm JWKS của các nút.
:::

#### API-03-053 · Thu hồi token (danh sách chặn)

::: dac-ta
**Mục đích.** Thu hồi token (danh sách chặn).

**Phương thức, đường dẫn.** `POST /revocations`.

**Quyền.** Token dịch vụ.

**FR hiện thực.** FR-03-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RevocationCreate`; trường bắt buộc: `kind`, `tokenExpiresAt`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Revocation`; trường bắt buộc: `revocationId`, `kind`, `tokenExpiresAt`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `gateway:revoke` (PH-12). `dh-connect` ghi cơ sở dữ liệu rồi Valkey; hiệu lực ≤ 60 giây (SEC-25).
:::

#### API-03-054 · Danh sách thu hồi token còn hiệu lực

::: dac-ta
**Mục đích.** Danh sách thu hồi token còn hiệu lực.

**Phương thức, đường dẫn.** `GET /revocations`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-018.

**Tham số.** `sub` (query, string, tùy chọn); `jti` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RevocationPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách thu hồi token còn hiệu lực.
:::

#### API-03-055 · Chính sách OPA gắn với từng route

::: dac-ta
**Mục đích.** Chính sách OPA gắn với từng route.

**Phương thức, đường dẫn.** `GET /authorization-bindings`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-019.

**Tham số.** `routeCode` (query, RouteCode, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuthorizationBindingPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chính sách OPA gắn với từng route.
:::

### Ảnh chụp cấu hình

#### API-03-056 · Danh sách ảnh chụp cấu hình

::: dac-ta
**Mục đích.** Danh sách ảnh chụp cấu hình.

**Phương thức, đường dẫn.** `GET /snapshots`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-039, FR-03-044.

**Tham số.** `state` (query, array, tùy chọn); `scope` (query, TenantCode, tùy chọn); `sort` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SnapshotPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-13 đọc bằng scope `gateway:read-state`.
:::

#### API-03-057 · Chi tiết ảnh chụp cấu hình

::: dac-ta
**Mục đích.** Chi tiết ảnh chụp cấu hình.

**Phương thức, đường dẫn.** `GET /snapshots/{version}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-039, FR-03-041.

**Tham số.** `version` (path, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SnapshotDetail`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết ảnh chụp cấu hình.
:::

#### API-03-058 · Kiểm tra hợp lệ cấu hình tổng hợp thử

::: dac-ta
**Mục đích.** Kiểm tra hợp lệ cấu hình tổng hợp thử.

**Phương thức, đường dẫn.** `POST /snapshots:validate`.

**Quyền.** `PERM-03-publish`.

**FR hiện thực.** FR-03-040.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ValidateRequest`; trường bắt buộc: `scope`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValidationReport`; trường bắt buộc: `valid`, `findings`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổng hợp thử và kiểm tra 18 quy tắc CHK (CHK-01…15 mức lỗi, CHK-16…18 mức cảnh báo), không ký, không phát. Luôn trả 200; xem `valid` và `findings`.
:::

#### API-03-059 · Tổng hợp, kiểm tra và ký ảnh chụp cấu hình

::: dac-ta
**Mục đích.** Tổng hợp, kiểm tra và ký ảnh chụp cấu hình.

**Phương thức, đường dẫn.** `POST /snapshots:build`.

**Quyền.** `PERM-03-publish`.

**FR hiện thực.** FR-03-039, FR-03-040, FR-03-041.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BuildRequest`; trường bắt buộc: `scope`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `ValidationReport`; trường bắt buộc: `valid`, `findings`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; `201` đã tạo, `Snapshot`; trường bắt buộc: `snapshotVersion`, `scope`, `state`, `contentHash`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `422`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-005, ERR-03-006, ERR-03-012, ERR-03-013, ERR-03-015, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổng hợp, kiểm tra, ký. Kiểm tra không đạt: ERR-03-005 kèm `findings` và phát EVT-03-12. Với `dryRun=true` trả 200 `ValidationReport` thay cho 201.
:::

#### API-03-060 · Phát ảnh chụp cấu hình tới Git và bucket

::: dac-ta
**Mục đích.** Phát ảnh chụp cấu hình tới Git và bucket.

**Phương thức, đường dẫn.** `POST /snapshots/{version}:publish`.

**Quyền.** `PERM-03-publish`.

**FR hiện thực.** FR-03-042.

**Tham số.** `version` (path, integer, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `Snapshot`; trường bắt buộc: `snapshotVersion`, `scope`, `state`, `contentHash`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `502`, `503`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-006, ERR-03-014, ERR-03-015, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ ảnh chụp `SIGNED` mới phát được: ghi bucket rồi Git (Git lỗi thì xếp hàng, cờ `gitPending`). Phát EVT-03-01.
:::

#### API-03-061 · Quay lui bằng ảnh chụp mới mang nội dung bản cũ

::: dac-ta
**Mục đích.** Quay lui bằng ảnh chụp mới mang nội dung bản cũ.

**Phương thức, đường dẫn.** `POST /snapshots/{version}:rollback`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-044.

**Tham số.** `version` (path, integer, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RollbackRequest`; trường bắt buộc: `scope`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Snapshot`; trường bắt buộc: `snapshotVersion`, `scope`, `state`, `contentHash`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `422`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-006, ERR-03-007, ERR-03-015, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiên bản trong đường dẫn là đích. Sinh ảnh chụp mới mang nội dung bản đích nên số phiên bản vẫn tăng. Phát EVT-03-02 và EVT-03-01. `PLATFORM` chỉ PA.
:::

#### API-03-062 · So sánh ảnh chụp với bản đang chạy

::: dac-ta
**Mục đích.** So sánh ảnh chụp với bản đang chạy.

**Phương thức, đường dẫn.** `GET /snapshots/{version}/diff`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-044.

**Tham số.** `version` (path, integer, bắt buộc); `against` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SnapshotDiff`; trường bắt buộc: `fromVersion`, `toVersion`, `summary`, `changes`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** So với bản đang chạy hoặc bản chỉ định ở `against`.
:::

### Nút gateway

#### API-03-063 · Danh sách nút gateway và trạng thái đồng bộ

::: dac-ta
**Mục đích.** Danh sách nút gateway và trạng thái đồng bộ.

**Phương thức, đường dẫn.** `GET /nodes`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-043, FR-03-045.

**Tham số.** `gate` (query, string, tùy chọn); `site` (query, string, tùy chọn); `syncState` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NodePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** PH-13 đọc bằng scope `gateway:read-state`. Trạng thái suy ra từ chỉ số, không do nút gọi về.
:::

#### API-03-064 · Chi tiết nút gateway

::: dac-ta
**Mục đích.** Chi tiết nút gateway.

**Phương thức, đường dẫn.** `GET /nodes/{nodeId}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-043, FR-03-045.

**Tham số.** `nodeId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NodeDetail`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết nút gateway.
:::

### Mẫu chính sách

#### API-03-065 · Danh mục mẫu chính sách được duyệt

::: dac-ta
**Mục đích.** Danh mục mẫu chính sách được duyệt.

**Phương thức, đường dẫn.** `GET /policy-templates`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-020, FR-03-048.

**Tham số.** `enabled` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyTemplatePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh mục mẫu chính sách được duyệt.
:::

#### API-03-066 · Chi tiết mẫu chính sách

::: dac-ta
**Mục đích.** Chi tiết mẫu chính sách.

**Phương thức, đường dẫn.** `GET /policy-templates/{templateCode}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-015, FR-03-048.

**Tham số.** `templateCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyTemplate`; trường bắt buộc: `templateCode`, `title`, `enabled`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết mẫu chính sách.
:::

#### API-03-067 · Bật, tắt mẫu chính sách cho tenant

::: dac-ta
**Mục đích.** Bật, tắt mẫu chính sách cho tenant.

**Phương thức, đường dẫn.** `PUT /policy-templates/{templateCode}/enablement`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-048.

**Tham số.** `templateCode` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TemplateEnablement`; trường bắt buộc: `enabled`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PolicyTemplate`; trường bắt buộc: `templateCode`, `title`, `enabled`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-013, ERR-03-018, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tắt mẫu đang được route dùng trả ERR-03-019.
:::

### Chứng thư biên

#### API-03-068 · Danh sách chứng thư biên

::: dac-ta
**Mục đích.** Danh sách chứng thư biên.

**Phương thức, đường dẫn.** `GET /certificates`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-049.

**Tham số.** `state` (query, array, tùy chọn); `expiringDays` (query, integer, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CertificatePage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách chứng thư biên.
:::

#### API-03-069 · Chi tiết chứng thư biên

::: dac-ta
**Mục đích.** Chi tiết chứng thư biên.

**Phương thức, đường dẫn.** `GET /certificates/{certCode}`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-049.

**Tham số.** `certCode` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Certificate`; trường bắt buộc: `certCode`, `hosts`, `notAfter`, `state`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chi tiết chứng thư biên.
:::

#### API-03-070 · Gia hạn chứng thư biên thủ công

::: dac-ta
**Mục đích.** Gia hạn chứng thư biên thủ công.

**Phương thức, đường dẫn.** `POST /certificates/{certCode}:renew`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-049.

**Tham số.** `certCode` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Certificate`; trường bắt buộc: `certCode`, `hosts`, `notAfter`, `state`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `422`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-015, ERR-03-016, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Yêu cầu cert-manager cấp lại; trả 202 và theo dõi bằng API-03-069. Chứng thư hiện tại giữ nguyên tới khi cấp xong.
:::

### Yêu cầu thay đổi bốn mắt

#### API-03-071 · Danh sách yêu cầu thay đổi chờ duyệt

::: dac-ta
**Mục đích.** Danh sách yêu cầu thay đổi chờ duyệt.

**Phương thức, đường dẫn.** `GET /change-requests`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-006, FR-03-023, FR-03-038.

**Tham số.** `state` (query, array, tùy chọn); `changeType` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChangeRequestPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách yêu cầu thay đổi chờ duyệt.
:::

#### API-03-072 · Duyệt yêu cầu thay đổi

::: dac-ta
**Mục đích.** Duyệt yêu cầu thay đổi.

**Phương thức, đường dẫn.** `POST /change-requests/{requestId}:approve`.

**Quyền.** `PERM-03-approve`.

**FR hiện thực.** FR-03-006, FR-03-023, FR-03-038.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChangeRequest`; trường bắt buộc: `requestId`, `changeType`, `state`, `requestedBy`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-008, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người đề nghị, so theo tài khoản (ERR-03-008). Thay đổi được áp ngay khi duyệt.
:::

#### API-03-073 · Từ chối yêu cầu thay đổi

::: dac-ta
**Mục đích.** Từ chối yêu cầu thay đổi.

**Phương thức, đường dẫn.** `POST /change-requests/{requestId}:reject`.

**Quyền.** `PERM-03-approve`.

**FR hiện thực.** FR-03-006, FR-03-023, FR-03-038.

**Tham số.** `requestId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReasonRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChangeRequest`; trường bắt buộc: `requestId`, `changeType`, `state`, `requestedBy`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-008, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Từ chối yêu cầu thay đổi.
:::

### Nhật ký lượt gọi

#### API-03-074 · Tra cứu nhật ký lượt gọi

::: dac-ta
**Mục đích.** Tra cứu nhật ký lượt gọi.

**Phương thức, đường dẫn.** `GET /access-logs`.

**Quyền.** `PERM-03-log-read`.

**FR hiện thực.** FR-03-050, FR-03-051.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `consumerCode` (query, ConsumerCode, tùy chọn); `routeCode` (query, RouteCode, tùy chọn); `statusClass` (query, string, tùy chọn); `errorCode` (query, string, tùy chọn); `traceId` (query, string, tùy chọn); `srcIp` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessLogPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-021, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ siêu dữ liệu; đọc từ ClickHouse của PH-13, p95 ≤ 3 giây. Có `srcIp` nên cần `PERM-03-log-read`.
:::

#### API-03-075 · Chi tiết một lượt gọi

::: dac-ta
**Mục đích.** Chi tiết một lượt gọi.

**Phương thức, đường dẫn.** `GET /access-logs/{logId}`.

**Quyền.** `PERM-03-log-read`.

**FR hiện thực.** FR-03-051.

**Tham số.** `logId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessLogEntry`; trường bắt buộc: `logId`, `ts`, `tenant`, `traceId`, `status`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Ghi kiểm toán khi xem chi tiết có `srcIp`.
:::

#### API-03-076 · Xuất nhật ký lượt gọi

::: dac-ta
**Mục đích.** Xuất nhật ký lượt gọi.

**Phương thức, đường dẫn.** `POST /access-logs:export`.

**Quyền.** `PERM-03-log-read`.

**FR hiện thực.** FR-03-051.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AccessLogExportRequest`; trường bắt buộc: `from`, `to`, `format`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportJob`; trường bắt buộc: `exportId`, `status`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-021, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo tệp xuất bất đồng bộ; trả 202 kèm `Location` tới `exportId`. Ghi kiểm toán: người dùng, bộ lọc, số dòng.
:::

### Tổng quan

#### API-03-077 · Tổng quan lưu lượng và sức khỏe gateway

::: dac-ta
**Mục đích.** Tổng quan lưu lượng và sức khỏe gateway.

**Phương thức, đường dẫn.** `GET /overview`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-026, FR-03-052, FR-03-055.

**Tham số.** `window` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Overview`; trường bắt buộc: `window`, `dataAvailable`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tổng quan lưu lượng, độ trễ, nút, suy giảm, kèm `kpis[]` có `trend` so với kỳ liền trước. PH-13 không trả số liệu thì ERR-03-026, không trả số 0 giả.
:::

#### API-03-078 · HTTT gọi nhiều nhất

::: dac-ta
**Mục đích.** HTTT gọi nhiều nhất.

**Phương thức, đường dẫn.** `GET /overview/top-consumers`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-055.

**Tham số.** `window` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TopConsumers`; trường bắt buộc: `items`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** HTTT gọi nhiều nhất.
:::

#### API-03-079 · Route nhiều lượt gọi hoặc nhiều lỗi nhất

::: dac-ta
**Mục đích.** Route nhiều lượt gọi hoặc nhiều lỗi nhất.

**Phương thức, đường dẫn.** `GET /overview/top-routes`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-055.

**Tham số.** `window` (query, string, tùy chọn); `orderBy` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TopRoutes`; trường bắt buộc: `items`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Route nhiều lượt gọi hoặc nhiều lỗi nhất.
:::

### Kiểm tra tổng hợp

#### API-03-080 · Danh sách kiểm tra tổng hợp

::: dac-ta
**Mục đích.** Danh sách kiểm tra tổng hợp.

**Phương thức, đường dẫn.** `GET /synthetic-checks`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-053.

**Tham số.** `routeCode` (query, RouteCode, tùy chọn); `enabled` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyntheticCheckPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách kiểm tra tổng hợp.
:::

#### API-03-081 · Tạo kiểm tra tổng hợp

::: dac-ta
**Mục đích.** Tạo kiểm tra tổng hợp.

**Phương thức, đường dẫn.** `POST /synthetic-checks`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-053.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyntheticCheckWrite`; trường bắt buộc: `checkCode`, `routeCode`, `method`, `path`, `expectedStatus`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SyntheticCheck`; trường bắt buộc: `checkId`, `checkCode`, `routeCode`, `method`, `path`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-002, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cờ `gateway.syntheticChecks.enabled`.
:::

#### API-03-082 · Sửa kiểm tra tổng hợp

::: dac-ta
**Mục đích.** Sửa kiểm tra tổng hợp.

**Phương thức, đường dẫn.** `PUT /synthetic-checks/{checkId}`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-053.

**Tham số.** `checkId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyntheticCheckWrite`; trường bắt buộc: `checkCode`, `routeCode`, `method`, `path`, `expectedStatus`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyntheticCheck`; trường bắt buộc: `checkId`, `checkCode`, `routeCode`, `method`, `path`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Sửa kiểm tra tổng hợp.
:::

#### API-03-083 · Xóa kiểm tra tổng hợp

::: dac-ta
**Mục đích.** Xóa kiểm tra tổng hợp.

**Phương thức, đường dẫn.** `DELETE /synthetic-checks/{checkId}`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-053.

**Tham số.** `checkId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xóa kiểm tra tổng hợp.
:::

### Cảnh báo an ninh

#### API-03-084 · Danh sách cảnh báo an ninh của gateway

::: dac-ta
**Mục đích.** Danh sách cảnh báo an ninh của gateway.

**Phương thức, đường dẫn.** `GET /security-alerts`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-054.

**Tham số.** `state` (query, array, tùy chọn); `ruleCode` (query, string, tùy chọn); `severity` (query, Severity, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlertPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cảnh báo theo luật GW-A01…A13 (FR-03-054).
:::

#### API-03-085 · Xác nhận đã xử lý cảnh báo

::: dac-ta
**Mục đích.** Xác nhận đã xử lý cảnh báo.

**Phương thức, đường dẫn.** `POST /security-alerts/{alertId}:acknowledge`.

**Quyền.** `PERM-03-operate`.

**FR hiện thực.** FR-03-054.

**Tham số.** `alertId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SecurityAlert`; trường bắt buộc: `alertId`, `ruleCode`, `severity`, `state`, `raisedAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xác nhận đã xử lý cảnh báo.
:::

### Tham số

#### API-03-086 · Tham số gateway của tenant

::: dac-ta
**Mục đích.** Tham số gateway của tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-003, FR-03-011, FR-03-056.

**Tham số.** `prefix` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `items`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị hiệu lực, mặc định, miền và trần hợp đồng của từng khóa `gw.*`.
:::

#### API-03-087 · Đổi tham số gateway của tenant

::: dac-ta
**Mục đích.** Đổi tham số gateway của tenant.

**Phương thức, đường dẫn.** `PUT /settings`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-003, FR-03-011, FR-03-056.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SettingsUpdate`; trường bắt buộc: `params`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `items`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; `202` đã nhận, xử lý bất đồng bộ, `ChangeRequest`; trường bắt buộc: `requestId`, `changeType`, `state`, `requestedBy`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-004, ERR-03-018, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Có hiệu lực khi ảnh chụp mới được nạp. Khóa có bốn mắt trả 202 kèm `ChangeRequest`. Phát EVT-03-11 khi đổi tham số hạn mức.
:::

### Chạy thử chính sách

#### API-03-088 · Chạy thử chính sách bằng mô phỏng

::: dac-ta
**Mục đích.** Chạy thử chính sách bằng mô phỏng.

**Phương thức, đường dẫn.** `POST /simulations`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-057.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SimulationRequest`; trường bắt buộc: `host`, `method`, `path`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SimulationResult`; trường bắt buộc: `snapshotVersion`, `finalStatus`, `stages`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chạy mô phỏng trên ảnh chụp, không gọi backend, không ghi nhật ký lượt gọi. Cờ `gateway.simulation.enabled`.
:::

### Báo cáo sử dụng

#### API-03-089 · Báo cáo sử dụng API theo HTTT, route, gói

::: dac-ta
**Mục đích.** Báo cáo sử dụng API theo HTTT, route, gói.

**Phương thức, đường dẫn.** `GET /reports/usage`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-058.

**Tham số.** `groupBy` (query, string, tùy chọn); `period` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `consumerCode` (query, ConsumerCode, tùy chọn); `routeCode` (query, RouteCode, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageReport`; trường bắt buộc: `groupBy`, `rows`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-021, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cờ `gateway.usageReport.enabled`.
:::

#### API-03-090 · Xuất báo cáo sử dụng

::: dac-ta
**Mục đích.** Xuất báo cáo sử dụng.

**Phương thức, đường dẫn.** `POST /reports/usage:export`.

**Quyền.** `PERM-03-log-read`.

**FR hiện thực.** FR-03-058.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `UsageExportRequest`; trường bắt buộc: `period`, `from`, `to`, `groupBy`, `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportJob`; trường bắt buộc: `exportId`, `status`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `503`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-021, ERR-03-022, ERR-03-026 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Xuất báo cáo sử dụng.
:::

### Nhập từ gateway cũ

#### API-03-091 · Tải gói cấu hình gateway cũ để phân tích

::: dac-ta
**Mục đích.** Tải gói cấu hình gateway cũ để phân tích.

**Phương thức, đường dẫn.** `POST /migrations/legacy-gateway:import`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-059.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: object.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `LegacyImportJob`; trường bắt buộc: `importId`, `status`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-020, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tải tệp gói xuất của gateway cũ (≤ 50 MiB, multipart). Bộ quét loại bí mật; kết quả `PROPOSE_ONLY` để người duyệt từng đề xuất.
:::

#### API-03-092 · Kết quả phân tích gói gateway cũ

::: dac-ta
**Mục đích.** Kết quả phân tích gói gateway cũ.

**Phương thức, đường dẫn.** `GET /migrations/legacy-gateway/{importId}`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-059.

**Tham số.** `importId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `importId`, `status`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Kết quả phân tích gói gateway cũ.
:::

#### API-03-093 · Áp đề xuất nhập thành cấu hình nháp

::: dac-ta
**Mục đích.** Áp đề xuất nhập thành cấu hình nháp.

**Phương thức, đường dẫn.** `POST /migrations/legacy-gateway/{importId}:apply`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-059.

**Tham số.** `importId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegacyApplyRequest`; trường bắt buộc: `proposalIds`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `importId`, `status`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `422`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-020, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo cấu hình nháp từ các đề xuất đã chọn; không tự phát (phải qua API-03-059, 060).
:::

### Chuyển tiếp tenant sáp nhập

#### API-03-094 · Danh sách chuyển tiếp tenant sáp nhập

::: dac-ta
**Mục đích.** Danh sách chuyển tiếp tenant sáp nhập.

**Phương thức, đường dẫn.** `GET /tenant-redirects`.

**Quyền.** `PERM-03-read`.

**FR hiện thực.** FR-03-037.

**Tham số.** `state` (query, array, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantRedirectPage`; trường bắt buộc: `items`, `page`, `size`, `totalElements`; tiêu đề `ETag`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Danh sách chuyển tiếp tenant sáp nhập.
:::

#### API-03-095 · Tạo chuyển tiếp tenant sáp nhập

::: dac-ta
**Mục đích.** Tạo chuyển tiếp tenant sáp nhập.

**Phương thức, đường dẫn.** `POST /tenant-redirects`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-037.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TenantRedirectCreate`; trường bắt buộc: `fromTenant`, `toTenant`, `startAt`, `routeMap`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `TenantRedirect`; trường bắt buộc: `redirectId`, `fromTenant`, `toTenant`, `state`, `startAt`, `endAt`; tiêu đề `Location`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `409`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-003, ERR-03-022, ERR-03-025 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cờ `gateway.redirect.enabled`. Phát EVT-03-10 khi bắt đầu.
:::

#### API-03-096 · Kết thúc chuyển tiếp tenant sáp nhập

::: dac-ta
**Mục đích.** Kết thúc chuyển tiếp tenant sáp nhập.

**Phương thức, đường dẫn.** `POST /tenant-redirects/{redirectId}:end`.

**Quyền.** `PERM-03-admin`.

**FR hiện thực.** FR-03-037.

**Tham số.** `redirectId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `OptionalReason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantRedirect`; trường bắt buộc: `redirectId`, `fromTenant`, `toTenant`, `state`, `startAt`, `endAt`; tiêu đề `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

**Lỗi.** HTTP `400`, `401`, `403`, `404`, `409`, `412`, `429`, `500`, `default`; mã lỗi của thao tác: ERR-03-001, ERR-03-003, ERR-03-004, ERR-03-019, ERR-03-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phát EVT-03-10.
:::

<!-- gen:dac-ta-api:end -->

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu dùng chung hay tập khác của PH-03; các việc dưới đây để đợt đồng bộ cuối thực hiện.

| Tài liệu | Đề nghị |
|---|---|
| D02-08 §3.1, §4 | Bổ sung tám quyền `PERM-03-limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read` (vai trò theo bảng 2.2 của tài liệu này); thêm cặp bốn mắt: ngoại lệ WAF (đề nghị `waf-request`, duyệt `waf-approve`), đổi chế độ WAF và đặt route ra cửa Internet và hạ hạn mức tenant (duyệt `approve`). Ghi ba scope dịch vụ `gateway:sync` (PH-01), `gateway:revoke` (PH-12), `gateway:read-state` (PH-13) |
| D00-01 §6 | Thêm nhóm REST `gateway` (`/api/gateway/v1`); thêm quy ước mã lỗi gateway `ERR-03-101…199` trả cho bên gọi; chốt dạng `type` của lỗi `https://datahub.gov.vn/errors/ERR-{PH}-{nnn}` (PH-05 đang dùng dạng `…/problems/{nhóm}/…`) |
| D04-01 CC-API-02, CC-API-04 | Thêm tệp luật Spectral mẫu [`ph03/.spectral.yaml`](ph03/.spectral.yaml) làm gốc cho `@datahub/spectral-ruleset`; CC-API-04 nên nêu rõ `ce_source` là `/datahub/{du}/{module}` (tập này dùng `/datahub/dh-connect/gateway`) |
| D02-03-PH03 (FRS) | §9.4: thêm cột mã thành công, ghi các nhánh `200` hoặc `202` ở API-03-008, 024, 041, 087 và `201` ở API-03-013; §9.1: nội dung ERR-03-027 đã được bổ sung điều kiện cảnh báo giả ở đợt rà soát chéo; thêm mã 401 và 500 nếu Q03-55 được chấp nhận; ghi `X-Trace-Id` và `WWW-Authenticate` vào bảng 5.4 của tài liệu này nếu FRS muốn là nguồn |
| D03-02-PH03 (SDD) | Đã áp ở đợt rà soát chéo: `RollbackRequest` bỏ `targetVersion`. Còn lại: ghi `GenericProblem` cho 401, 500 (Q03-55); §8.2 và bảng khóa sự kiện theo bảng 4.1 |
| D03-03-PH03 (CSDL) | Đã áp ở đợt rà soát chéo: khóa phân vùng EVT-03-01, 02, 11, 12 khớp bảng 4.1 của tập API |
| D03-06-PH03 (màn hình, tập sau) | Mỗi màn UI-03-01…18 gắn mã API-03 theo bảng 3.2; bảng thông báo ở mục 6.3 là nguồn cho §5.2; giao diện dùng `allowedActions`, `disabledReasons` của API-03-002 và 012 |
| D05-02-PH03 (test case) | Mỗi operation ít nhất một ca dương và một ca âm từ hợp đồng; ca âm bắt buộc: thiếu quyền (ERR-03-022), tenant khác (ERR-03-001), `If-Match` sai (ERR-03-004), người duyệt trùng người đề nghị (ERR-03-008), bí mật trong thân (ERR-03-003), canary `DH-CANARY-…` ở nhật ký, thứ tự chốt (bảng 5.4) |
| D03-07 | SEC-25: đường đẩy thu hồi là PH-12 gọi API-03-053; SEC-32: ràng buộc `ck_outbox_no_secret` và kiểm tra lược đồ không có thuộc tính bí mật ở CI-5 |
| ADR (đề xuất, không tạo ở tập này) | ADR về phân trang con trỏ cho API đọc từ kho phân tích (ClickHouse) cho toàn hệ thống nếu Q03-56 được chấp nhận. Dải còn trống: ADR-014…019, 024…029, 039, 074 |
| Tập của PH-01, PH-02, PH-12, PH-13, PH-20 | PH-01: gọi API-03-013, 014, 015 theo mục 5.2, giữ `Idempotency-Key` ổn định (Q03-57). PH-12: gọi API-03-053 (mục 5.3). PH-13: dùng scope `gateway:read-state` (Q03-58), nhận EVT-03-01…12. PH-02: nhận EVT-03-01, 03, 07, 12. PH-20: chốt topic sự kiện gửi cho PH-03 (mục 4.7), nhận EVT-03-10, 11 |
| D00-04 §3.2 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi hợp nhất: API-03 (96), EVT-03 (12), ERR-03 (57 mã) |

: Đề nghị đồng bộ của tập API PH-03


## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-API và quy chuẩn K-TRINH-BAY: 96 operation REST (API-03-001…096) dưới `/api/gateway/v1`, 12 sự kiện (EVT-03-01…12), 57 mã lỗi (27 control plane, 30 gateway); OpenAPI 3.1 và AsyncAPI 3.0 sinh bằng script `ph03/tools`; 5 câu hỏi mở Q03-55…59 |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: hợp đồng với PH-02 (API-02-080, 082), ánh xạ trường với cột, impact, subscriptions, kpis, eligibility ở API-03-002, 012, 077; sinh lại OpenAPI |
