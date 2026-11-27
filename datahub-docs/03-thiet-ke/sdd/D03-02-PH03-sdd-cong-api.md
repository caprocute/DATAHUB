---
ma_tai_lieu: D03-02-PH03
ten: Thiết kế chi tiết phần mềm phân hệ PH-03 Cổng API
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect và gateway, kiến trúc sư, cán bộ ATTT, hội đồng thẩm định
phan_he: PH-03
mo_ta: Thiết kế chi tiết phần mềm của phân hệ Cổng API gồm chuỗi plugin APISIX do Datahub viết, bộ tổng hợp, kiểm tra, ký và phát cấu hình ở dh-connect, bộ đồng bộ nút, đường chặn nhanh qua Valkey, trình tự xử lý, máy trạng thái, bảo mật và quan sát, đủ để lập trình và kiểm thử.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH03 FRS; D02-04-PH03 Use case; D03-03-PH03 CSDL; D03-04-PH03 API; D03-07 ATTT; D03-09 Hạ tầng; D03-10 Đa tenant; D04-01 Quy ước mã
---

# D03-02-PH03 · Thiết kế chi tiết Cổng API

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 59 FR của [D02-03-PH03](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md) và 31 use case của [D02-04-PH03](../../02-yeu-cau/use-case/D02-04-PH03-use-case-cong-api.md). PH-03 gồm hai nửa chạy ở hai mặt phẳng khác nhau và chỉ nối với nhau bằng một tệp cấu hình có chữ ký. Nửa **mặt phẳng dữ liệu** là hai nhóm Apache APISIX 3.x (`apisix-ext` ở Z1, `apisix-int` ở Z2) mang mười plugin Datahub viết bằng Lua, WAF Coraza dạng proxy-wasm, OPA cạnh pod và bộ đồng bộ `dh-sync`. Nửa **mặt phẳng điều khiển** là module `gateway` của DU `dh-connect` (Spring Boot 4, Modulith) ở Z3, chuyên tổng hợp, kiểm tra, ký và phát cấu hình. Căn cứ pháp lý và an toàn thông tin là CMP-LAW-09 (quản lý API, OAuth, giới hạn tần suất, chống từ chối dịch vụ), CMP-LAW-06 và CMP-LAW-08 (cấp độ 3: TLS, WAF, kiểm soát truy cập, nhật ký), CMP-LAW-16 và CMP-LAW-05 (an ninh mạng, không ghi dữ liệu cá nhân vào nhật ký). Thiết kế dựa trên năm quyết định:

1. **Cấu hình là ảnh chụp bất biến, đã ký, nạp nguyên tử.** `dh-connect` đóng cấu hình của cả nền tảng thành một ảnh chụp có số phiên bản tăng đơn điệu, ký bằng khóa trong OpenBao (không xuất được). `dh-sync` cạnh mỗi pod APISIX kiểm chữ ký, kiểm phiên bản, ghi tệp `apisix.yaml` bằng đổi tên nguyên tử; nút từ chối mọi bản không hợp lệ hoặc không mới hơn bản đang chạy (BR-03-016, BR-03-018). Gateway phục vụ tiếp ít nhất 24 giờ khi toàn bộ control plane ngừng (NFR-03-007).
2. **Hai đường tới nút: đường bền và đường nhanh.** Mọi thay đổi đi đường bền (ảnh chụp, thường dưới 10 giây). Hai loại thay đổi khẩn, thu hồi token và tạm ngừng khẩn cấp, đi thêm đường nhanh là khóa Valkey mà plugin đọc với bộ đệm 5 giây, để có hiệu lực trong vài giây chứ không chờ quy trình phát hành (BR-03-021). Đường nhanh chỉ để thêm chặn; mất Valkey không làm mất chặn đã ghi ở ảnh chụp.
3. **Gateway hai chặng cho cửa Internet.** Vì vùng Z1 chỉ được chuyển tiếp sang Z2 (SEC-13), `apisix-ext` chỉ chạy các chốt biên không cần kho trạng thái (TLS, mTLS, chống tràn theo IP, giới hạn thân, WAF, CORS) rồi chuyển sang `apisix-int` chạy phần còn lại (xác thực, hạn mức, OPA, định tuyến). Lưu lượng TSLCD vào thẳng `apisix-int` và chạy đủ cả hai phần.
4. **Thứ tự chốt là một thuộc tính được kiểm thử, không phải thói quen cấu hình.** Mười plugin Datahub giữ đúng thứ tự "rẻ trước, đắt sau" của FRS, kể cả những chốt mà plugin dựng sẵn của APISIX theo mã nguồn chạy sai pha (giới hạn tần suất sau WAF, xác minh ở X1). Mọi từ chối do gateway sinh đi qua một bộ định dạng duy nhất (`dh-problem`) để luôn có thân RFC 9457, mã `ERR-03-1xx` và `X-Trace-Id` (BR-03-023).
5. **Control plane không nằm trên đường đi của lượt gọi.** Mọi quyết định (token, hạn mức, ủy quyền) dùng dữ liệu đã nạp ở APISIX, OPA, Valkey; không bước nào gọi `dh-connect`. Khi Valkey mất, hạn mức suy giảm có kiểm soát; khi OPA hoặc JWKS hết hạn đệm, gateway đóng an toàn bằng `503` (ERR-03-124).

**Điểm hội đồng cần lưu ý.** (1) Thiết kế **thêm bốn plugin** ngoài sáu plugin đã nêu ở FRS (`dh-auth`, `dh-limit`, `dh-edge`, `dh-problem`) và **thay** một số plugin dựng sẵn (`jwt-auth`, `openid-connect`, `limit-count`, `limit-conn`, `limit-req`, `consumer-restriction`) bằng logic của Datahub, với ba lý do: thứ tự pha, suy giảm có kiểm soát và mã lỗi thống nhất (mục 4.1). Việc này cần một ADR (đề xuất ở "Đề nghị đồng bộ") và chi phí bảo trì mã Lua là rủi ro chính (mục 13.2). (2) Bộ đồng bộ `dh-sync` viết bằng Go, nhỏ và tĩnh, vì cần ký, băm và ghi tệp nguyên tử mà không kéo JVM vào pod gateway (Q03-22). (3) Có bảy điều về APISIX 3.11 cần xác minh bằng thử nghiệm ở bước đầu của lộ trình (mục 13.1), vì thiết kế dựa vào hành vi của pha và ưu tiên plugin.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Thành phần được đặc tả ở chương 4 | 16 (6 ở mặt phẳng dữ liệu, 10 ở mặt phẳng điều khiển và bộ đồng bộ) |
| Plugin Datahub (Lua) | 10, trong đó 6 theo FRS và 4 bổ sung |
| Biểu đồ tuần tự | 11 (mục 5.1…5.11) |
| Máy trạng thái có bảng chuyển trạng thái | 11 (mục 8.1) |
| Chỉ số Prometheus phát ra | 46 chỉ số ở mặt phẳng dữ liệu và 25 chỉ số ở control plane |
| Câu hỏi mở mới | 8 (Q03-20…Q03-27) |
| Điều cần xác minh với APISIX 3.11 | 7 (X1…X7, mục 13.1) |
| Package chính | `vn.datahub.connect.gateway` |

: Con số chính của thiết kế PH-03

## 1. Giới thiệu

### 1.1. Mục đích, phạm vi và cách đọc

Tài liệu đi từ vị trí trong kiến trúc (chương 2), cấu trúc mã nguồn (chương 3), từng thành phần (chương 4), biểu đồ tuần tự của các FR phức tạp (chương 5) tới đa tenant, bảo mật, máy trạng thái, cấu hình, quan sát, hiệu năng, kiểm thử và lộ trình. Mã lỗi (ERR), quy tắc (BR), yêu cầu phi chức năng (NFR) là của [FRS](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md); mã API, sự kiện (EVT), lược đồ thân lỗi nằm ở D03-04-PH03; bảng CSDL ở D03-03-PH03. Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mới. Tham số `gw.*` dẫn theo FRS mục 8.2; tham số hạ tầng riêng của thiết kế (không chỉnh theo tenant) ở mục 9.1.

Tài liệu dùng hai cách gọi cần phân biệt. "Chốt" là một bước kiểm soát trong chuỗi xử lý một lượt gọi (FRS mục 2.4, bảng thứ tự). "Plugin" là mô-đun APISIX hiện thực một hoặc nhiều chốt. Một plugin có thể gộp nhiều chốt cùng pha (ví dụ `dh-auth` gộp xác minh JWT, xác định tenant, ràng buộc chứng thư, đăng ký sử dụng và phạm vi) để đọc ngữ cảnh một lần và đo từng chốt bằng nhãn chỉ số.

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| ADR-001 | Spring Boot 4, Modulith cho module `gateway` của `dh-connect` |
| ADR-003 | PostgreSQL, RLS theo `tenant_id` cho schema `ph03_gateway` |
| ADR-005 | APISIX standalone khai báo, không etcd; ảnh chụp cấu hình có phiên bản, chữ ký |
| ADR-006 | Keycloak (JWKS theo realm), OPA cạnh pod |
| ADR-009, ADR-068 | Argo CD, kho Git cấu hình; ảnh chụp gateway ghi ở thư mục nền tảng `gateway/{site}/` |
| ADR-011 | OpenTelemetry, LGTM cho vết, chỉ số, nhật ký |
| ADR-012 | OpenBao: khóa ký `transit/keys/dh-gateway-snapshot`, PKI, bí mật chứng thư |
| ADR-013 | Tách control plane và data plane |
| ADR-033 | Lớp biên do APISIX đảm nhận, WAF Coraza với OWASP CRS |
| ADR-042 | Outbox trong DU cho sự kiện của `dh-connect` |
| ADR-046 | Cơ chế duyệt bốn mắt (cùng tinh thần với yêu cầu thay đổi ở mục 4.14) |
| ADR-070 | Tương thích lược đồ sự kiện chế độ BACKWARD |

: ADR áp dụng cho PH-03

### 1.2. Người đọc, thuật ngữ và tài liệu tham chiếu

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư plugin APISIX (Lua) | Chương 3.2, 4.1…4.6, 5.1…5.3, 8, 10, 11 |
| Kỹ sư `dh-connect` | Chương 3.1, 4.7…4.16, 5.4…5.10, 6, 8, 9 |
| Kỹ sư nền tảng, vận hành | Chương 2.1, 4.11, 9, 10, 11 |
| Cán bộ ATTT | Chương 4.2, 4.3, 4.12, 4.14, 7 |
| Kiểm thử viên | Chương 5, 8, 12 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 7, 13 |

: Người đọc và phần cần đọc

Thuật ngữ chung theo [FRS mục 1.4](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md#14-thuật-ngữ-và-chữ-viết-tắt) và D00-01. Bảng dưới thêm các thuật ngữ riêng của thiết kế.

| Thuật ngữ | Giải thích |
|---|---|
| Pha (phase) | Giai đoạn xử lý yêu cầu trong APISIX theo thứ tự `rewrite`, `access`, `before_proxy`, `header_filter`, `body_filter`, `log`; trong cùng một pha, plugin có ưu tiên (priority) cao chạy trước |
| Global rule | Bộ plugin áp cho mọi route của một nhóm APISIX, chạy trước plugin của route trong cùng pha |
| Plugin config | Bộ plugin có tên, nhiều route cùng tham chiếu; mỗi mẫu chính sách (FR-03-048) sinh ra một plugin config |
| Shared dict | Vùng nhớ chia sẻ giữa các worker NGINX của một pod (`lua_shared_dict`), dùng cho bộ đệm và bộ đếm cục bộ |
| `dh-sync` | Tiến trình Go cạnh pod APISIX: tải, kiểm, ghi ảnh chụp cấu hình; cũng là initContainer khi pod khởi động |
| Bản ghép (merged bundle) | Tệp khai báo APISIX của một cửa vào, ghép từ mảnh từng tenant và mảnh dùng chung `COMMON` |
| Đường bền, đường nhanh | Hai đường đưa thay đổi tới nút: ảnh chụp (có lịch sử, có chữ ký) và khóa Valkey (tức thời, chỉ để chặn) |
| Hai chặng | Lượt gọi từ Internet đi qua `apisix-ext` rồi `apisix-int`; mỗi chặng chạy một phần chuỗi chốt |

: Thuật ngữ riêng của thiết kế PH-03

Tài liệu tham chiếu chính: D03-01 SAD §4.3 (khối `apisix`, `dh-connect`), D03-09 §6.1 (cấu hình gateway), §4.4 (cửa vào), §5 (định cỡ), D03-10 §3 (xác định tenant), §5.3 (hạn mức), §5.4 (sáp nhập), D03-07 (SEC-10…16, 24…26, 32, 36, 43, 52, 55…57, 61, 65, 80…87), D02-08 (quyền PERM-03), `docs/07-srs/SRS-PH-03-gateway.md` (nguồn kế thừa).

Mỗi thành phần ở chương 4 mở đầu bằng bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế. Nhóm quyền của PH-03 (`read`, `admin`, `limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read`) được dẫn theo tên ngắn; hai quyền `PERM-03-read` và `PERM-03-admin` đã có ở D02-08, tám quyền còn lại chờ đợt đồng bộ ghi ở FRS mục "Đề nghị đồng bộ".

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-03 trải trên bảy vùng triển khai. Bảng dưới liệt kê từng thành phần của phân hệ cùng những thành phần nền tảng mà nó dựa vào; điểm cần chú ý là chỉ có `apisix-int` và `dh-connect` đụng tới kho trạng thái, còn `apisix-ext` ở vùng DMZ không có đường tới Valkey, OPA hay Keycloak.

| Thành phần | DU | Namespace, vùng | Ghi chú |
|---|---|---|---|
| `apisix-ext` (APISIX, plugin Datahub, Coraza, `dh-sync`) | `apisix` | `dh-edge`, Z1 | Cửa Internet; tối thiểu 3 bản sao trải ≥ 2 vùng sẵn sàng; chỉ chạy chốt biên; chỉ có đường ra tới `apisix-int` (Z2) |
| `apisix-int` (APISIX, plugin Datahub, Coraza, OPA sidecar, `dh-sync`) | `apisix` | `dh-gateway`, Z2 | Cửa TSLCD, nội bộ tỉnh và chặng thứ hai của lưu lượng Internet; chạy đủ chuỗi chốt |
| Module `gateway` | `dh-connect` | `dh-control`, Z3 | Tổng hợp, kiểm tra, ký, phát; API `/api/gateway/v1`; hai bản sao, khóa ShedLock cho tác vụ định kỳ |
| Schema `ph03_gateway` | `pg-core` | `dh-db`, Z5 | Cụm CNPG chung control plane, RLS theo `tenant_id` |
| Valkey | Nền tảng | `dh-cache`, Z5 | Bộ đếm hạn mức, khóa chặn token, khóa tạm ngừng khẩn cấp; chỉ `apisix-int` và `dh-connect` truy cập |
| Bucket `dh-platform-gateway` | Garage | `dh-s3`, Z5 | `snapshots/{site}/{version}/`, con trỏ `current` |
| Kho Git cấu hình, Argo CD | Nền tảng | Z7 | Thư mục `gateway/{site}/`; ConfigMap `apisix-config` |
| OpenBao | Nền tảng | `dh-secrets`, Z6 | Khóa ký `transit/keys/dh-gateway-snapshot`, PKI của CA HTTT, bí mật chứng thư biên qua External Secrets |
| Keycloak | `keycloak` | `dh-iam`, Z6 | JWKS theo realm `dh-{tenant}`; chỉ `apisix-int` đọc |
| OTel Collector, Mimir, ClickHouse | LGTM, PH-13 | `dh-obs`, Z7 | Nhận nhật ký lượt gọi, chỉ số, vết; `dh-connect` đọc để phục vụ màn hình |

: Đơn vị triển khai và vùng mạng của PH-03

Hệ quả của việc `apisix-ext` ở Z1 chỉ được chuyển tới Z2 là: bộ đồng bộ ở `apisix-ext` không đọc được bucket ở Z5. Thiết kế giải quyết bằng cách cho `dh-sync` của `apisix-int` mở một điểm đọc chỉ-đọc (mTLS của mesh, `AuthorizationPolicy` chỉ cho service account của `apisix-ext`) để chuyển tiếp ảnh chụp đã xác minh; `dh-sync` của `apisix-ext` vẫn tự kiểm chữ ký nên không phải tin điểm chuyển tiếp (mục 4.11).

### 2.2. Sơ đồ thành phần

```{.mermaid caption="Sơ đồ thành phần PH-03 theo vùng mạng"}
flowchart TB
  subgraph Z1["Z1 · dh-edge · apisix-ext"]
    E1["dh-edge, dh-ip-block, dh-waf-guard<br/>Coraza, cors, dh-problem"]
    ES["dh-sync"]
  end
  subgraph Z2["Z2 · dh-gateway · apisix-int"]
    I1["dh-edge, dh-ip-block, dh-waf-guard, Coraza"]
    I2["dh-auth, dh-revocation, dh-kill-switch,<br/>dh-path-acl, dh-limit, dh-adaptive-throttle"]
    I3["request-validation, opa, api-breaker, dh-problem"]
    OPA["OPA sidecar"]
    IS["dh-sync, điểm chuyển tiếp ảnh chụp"]
  end
  subgraph Z3["Z3 · dh-connect · module gateway"]
    AS["assemble, validate"]
    SN["snapshot: ký, phát, quay lui"]
    FB["fastblock: thu hồi, tạm ngừng"]
    MG["consumer, waf, limits, edge, routing, change"]
    OB["observe, nodes, simulate, migration"]
  end
  PG[("pg-core<br/>ph03_gateway")]
  VK[("Valkey")]
  BK[("Garage<br/>dh-platform-gateway")]
  GT[("Git, Argo CD")]
  OBA[("OpenBao")]
  KC["Keycloak JWKS"]
  OBS["PH-13 · OTel, Mimir, ClickHouse"]
  E1 -->|"mesh mTLS"| I1
  I1 --> I2 --> I3
  I3 --> OPA
  I2 -->|"đường nhanh, bộ đếm"| VK
  I2 -.->|"JWKS đệm"| KC
  AS --> SN
  SN -->|"ký"| OBA
  SN -->|"ghi"| BK
  SN -->|"commit"| GT
  FB -->|"ghi khóa chặn"| VK
  MG --> PG
  SN --> PG
  IS -->|"theo dõi"| BK
  IS -.->|"chuyển tiếp chỉ đọc"| ES
  GT -.->|"ConfigMap dự phòng"| IS
  I3 -.->|"nhật ký, chỉ số, vết"| OBS
  OB -->|"truy vấn"| OBS
```

Hình cho thấy ba đường. Đường lượt gọi đi một chiều từ trái sang phải qua hai chặng APISIX và không có mũi tên nào về `dh-connect`. Đường cấu hình đi từ `assemble` qua `snapshot` tới bucket và Git rồi tới `dh-sync` của từng cửa; `apisix-ext` nhận qua điểm chuyển tiếp ở Z2. Đường nhanh là mũi tên duy nhất từ `fastblock` tới Valkey, và `dh-auth` cùng các plugin liền kề đọc Valkey qua bộ đệm cục bộ.

### 2.3. Phụ thuộc với module và phân hệ khác

Module `gateway` cùng DU với PH-01 và PH-02 nên gọi nhau trong tiến trình qua gói `api` công bố; với phân hệ ở DU khác, dùng REST nội bộ hoặc sự kiện.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| PH-02 (module `catalog`) | PH-03 đọc | `catalog.api.PublishedConfigApi` (phạm vi `catalog:gateway-read`, tên theo D03-02-PH02; trả dữ liệu công bố gồm API, gói, bên đăng ký) (Modulith) và sự kiện nội bộ | Nguồn route, gói, đăng ký cho FR-03-039; `critical`, `deprecatedAt`, `sunsetAt`, `policyPackage`. Chiều ngược lại, module `gateway` cài cổng `catalog.spi.GatewayApplyPort` (`requestApply`, `status`, `describe(env)` trả số phiên bản cấu hình từng pod và băm nguồn từng route, `rebuild`), đóng dấu `contentHash` của PH-02 vào route đã sinh, gọi `GatewayAckApi` (API-02-082) khi nạp xong và chấp nhận số phiên bản cấu hình nhảy vọt; tên route theo quy ước `{apiCode}:v{major}:{operationId}` để PH-13 gom số đo theo API |
| PH-02 | PH-03 → PH-02 | EVT-03-01, 03, 07, 12 | Kết quả phát, cảnh báo ngưỡng, ảnh chụp bị từ chối |
| PH-01 (module `onboarding`) | PH-01 → PH-03 | REST API-03-013…015, scope `gateway:sync` | Saga kết nạp tạo, gỡ consumer |
| PH-12 | PH-12 → PH-03 | REST API-03-053, scope `gateway:revoke` | Đẩy danh sách chặn token |
| PH-12 | PH-03 đọc | Bucket `dh-platform-policy`, JWKS | Gói chính sách OPA (OPA tự tải), URL JWKS theo realm |
| PH-20 | PH-03 đọc | Sự kiện và API đọc | Host, tiền tố, hạn mức hợp đồng, trạng thái `MERGED` |
| PH-13 | PH-03 gửi, đọc | Chỉ số, nhật ký, vết (OTLP); truy vấn Mimir, ClickHouse | Siêu dữ liệu lượt gọi; trạng thái nút; báo cáo |
| PH-19, PH-15 | Dùng route `EXT` | Mẫu route cửa ngoài | Callback thanh toán, cổng nhà phát triển |
| Hộp việc chung (FR-00-070) | PH-03 gửi | `TaskInboxApi` | Việc duyệt bốn mắt |

: Phụ thuộc với module và phân hệ khác

Luật Modulith của `dh-connect`: `gateway` chỉ import gói `api` của `catalog` và `onboarding`; không import `internal`. Các module đó không import `gateway` ngoại trừ gói `gateway.api` (chỉ có giao diện `GatewaySyncStatusApi` cho saga hỏi `syncState`). ArchUnit kiểm ở CI (CI-3).

### 2.4. Hiện trạng mã và đường chuyển

| Hiện trạng repo | Thiết kế | Khoảng cách |
|---|---|---|
| `deploy/apisix/Dockerfile` dựa trên `apache/apisix:3.11.0-debian`, thêm Coraza proxy-wasm 0.5.0 | Ảnh APISIX kèm 10 plugin Datahub, `coraza-block` và `coraza-detect`, ký cosign, quét Trivy | GAP-03-01: thêm plugin, đổi nguồn ảnh sang Harbor, ký ảnh (SEC-55…57) |
| `deploy/apisix/config.yaml` (`config_provider: yaml`, chỉ một plugin wasm) | `config.yaml` sinh từ khuôn: `lua_shared_dict`, hai plugin wasm, thuộc tính plugin, `ssl` | GAP-03-02 |
| `deploy/apisix/apisix.yaml` viết tay, route demo, CORS `*`, `limit-count` cố định 100/60 giây, `openid-connect` với `client_secret` trong tệp | Tệp do `dh-sync` ghi từ ảnh chụp; không có bí mật trong cấu hình | GAP-03-03: xóa route demo, bỏ bí mật khỏi cấu hình (BR-03-017, SEC-24) |
| `apps/control` có `ApisixRouteWriter` ghi từng route ra `deploy/apisix/routes/*.yaml`, không ký, không kiểm tra, không phiên bản | Module `gateway` của `dh-connect` với bộ tổng hợp, kiểm tra, ký, phát | GAP-03-04: thay `ApisixRouteWriter` bằng `SnapshotAssembler`; gói `vn.lgsp.control` đổi sang `vn.datahub.connect` theo D04-01 |
| Không có bộ đồng bộ, không có bucket cấu hình | `dh-sync` (initContainer và sidecar) | GAP-03-05 |
| Không có WAF chế độ chặn, không có ngoại lệ luật | `coraza-block`, `coraza-detect`, `dh-waf-guard`, quy trình ngoại lệ có bốn mắt | GAP-03-06 |
| Bảng `ph04.route` (W2) lưu route của luồng tích hợp, khác với route cổng API | Schema `ph03_gateway` riêng; route của PH-04 là một loại backend | GAP-03-07: giữ tách bạch, không dùng chung bảng |

: Hiện trạng mã và đường chuyển

## 3. Cấu trúc mã nguồn

### 3.1. Module `gateway` trong `dh-connect`

Module `gateway` theo cấu trúc Modulith của D00-04 §4: `api` là gói duy nhất module khác được import, `web` chứa lớp REST, `internal` chứa nghiệp vụ. Thư mục con của `internal` đặt theo trách nhiệm ở chương 4 để mỗi thành phần có đúng một thư mục.

```text
vn.datahub.connect.gateway
├── api/                       # GatewaySyncStatusApi (cho saga PH-01), DTO công bố
├── web/                       # @RestController theo nhóm API-03-xxx; ProblemDetail ERR-03-0xx
├── internal/
│   ├── model/                 # aggregate Route, Upstream, Consumer, PlanPolicy, RateLimitOverride
│   ├── assemble/              # SnapshotAssembler, SourceReader, TenantShardRenderer, PlatformMerger,
│   │                          # PluginChainComposer, PluginTemplateRegistry, CanonicalYaml
│   ├── validate/              # SnapshotValidator, ValidationRule (CHK-01…18), ApisixSchemaChecker
│   ├── snapshot/              # BuildCoordinator, SnapshotCounter, SnapshotSigner, SnapshotPublisher,
│   │                          # GitCommitter, RollbackService, HoldService
│   ├── consumer/              # ConsumerSyncService, CredentialPublicStore, SecretFieldGuard
│   ├── fastblock/             # RevocationService, KillSwitchService, FastKeyFactory, ValkeyRebuilder,
│   │                          # QuotaEventConsumer
│   ├── waf/                   # WafModeService, WafExceptionService, VirtualPatchService,
│   │                          # WafDirectiveRenderer, ExpiryScheduler
│   ├── limits/                # TenantLimitService, OverrideService, PolicyPrecedenceResolver
│   ├── edge/                  # TlsProfileService, TlsExceptionService, CertificateService,
│   │                          # ClientCaBundleService, IpBlockService
│   ├── routing/               # RouteStateService, ExposureService, SunsetService, TenantRedirectService
│   ├── change/                # ChangeRequestService (bốn mắt), ChangeHandlerRegistry
│   ├── nodes/                 # NodeStateEvaluator
│   ├── observe/               # AccessLogQueryService, OverviewService, UsageReportService,
│   │                          # SyntheticCheckService, SecurityAlertService
│   ├── simulate/              # PolicySimulator
│   ├── migration/             # LegacyGatewayImporter, LegacyBundleScanner (không thực thi)
│   └── settings/              # GatewayParameterService (tham số gw.*)
└── events/                    # EVT-03-xx record, OutboxPublisher
```

Quy tắc phụ thuộc kiểm bằng ArchUnit: `web` chỉ gọi `internal.*Service`, không gọi `repository` trực tiếp; `assemble` chỉ đọc nguồn qua `SourceReader` (một lớp duy nhất biết `catalog.api`, `onboarding.api`) để thay nguồn không động tới bộ kết xuất; `snapshot` là nơi duy nhất gọi OpenBao transit, Garage và Git; `fastblock` là nơi duy nhất ghi Valkey (khóa tên lập bởi `FastKeyFactory`, SEC-82); không lớp nào đọc tenant từ tham số yêu cầu (luật Semgrep của SEC-80).

### 3.2. Plugin, thư viện Lua và `dh-sync`

Phần mặt phẳng dữ liệu nằm trong kho ở thư mục `deploy/apisix/` (đã có), mở rộng như sau. Mã Lua và mã Go dùng chung một kho với ảnh để phiên bản plugin luôn khớp phiên bản APISIX và lược đồ cấu hình mà `dh-connect` kiểm tra.

```text
deploy/apisix/
├── Dockerfile                          # APISIX 3.11.x, Coraza, plugin Datahub; ký cosign
├── config.yaml.tmpl                    # lua_shared_dict, wasm, plugin_attr, ssl; sinh khi dựng ảnh
├── plugins/apisix/plugins/             # plugin Datahub (thư mục APISIX nạp theo tên)
│   ├── dh-edge.lua                     # FR-001, 002, 011, 032, 038 (phần cửa vào)
│   ├── dh-ip-block.lua                 # FR-003, 004
│   ├── dh-waf-guard.lua                # FR-006, 007, 008 (chế độ, tự hạ, đo)
│   ├── dh-auth.lua                     # FR-012…017
│   ├── dh-revocation.lua               # FR-018
│   ├── dh-kill-switch.lua              # FR-036, 047, 035 (SUNSET)
│   ├── dh-path-acl.lua                 # FR-020
│   ├── dh-limit.lua                    # FR-021…026
│   ├── dh-adaptive-throttle.lua        # FR-027
│   └── dh-problem.lua                  # BR-03-023
├── plugins/dh/                         # thư viện dùng chung, không phải plugin
│   ├── keys.lua                        # FastKeys: hàm tạo tên khóa Valkey (SEC-82)
│   ├── valkey.lua                      # client có thời hạn 50 ms, ngắt mạch 5 giây, EVALSHA
│   ├── shdict.lua                      # bộ đệm cục bộ có TTL, bộ đếm cục bộ
│   ├── problem.lua                     # dựng thân RFC 9457 từ danh mục ERR-03-1xx
│   ├── metrics.lua                     # đăng ký chỉ số dh_gateway_*
│   ├── jwks.lua, cert.lua, crl.lua     # JWKS theo realm, vân tay chứng thư, danh sách thu hồi
│   └── errors.json                     # danh mục mã lỗi ERR-03-101…130, sinh từ D03-04-PH03
├── lua/limit_script.lua                # kịch bản Lua chạy trong Valkey (EVALSHA)
├── sync/                               # dh-sync (Go): cmd/dh-sync, internal/{verify,fetch,apply,relay}
├── schema/                             # lược đồ JSON xuất từ APISIX và từ plugin Datahub (cho dh-connect, dh-sync)
└── tests/                              # busted (đơn vị), Test::Nginx (plugin), k6 (tải)
```

Sáu plugin (`dh-auth`, `dh-revocation`, `dh-kill-switch`, `dh-path-acl`, `dh-limit`, `dh-adaptive-throttle`) chỉ chạy ở `apisix-int`, bộ kết xuất không đưa chúng vào bản ghép của cửa ngoài; bốn plugin còn lại (`dh-edge`, `dh-ip-block`, `dh-waf-guard`, `dh-problem`) chạy ở cả hai cửa. Thư viện `plugins/dh/` không có trạng thái toàn cục ngoài `shared dict` đã khai báo.

### 3.3. Giao diện công bố và cổng nguồn

```java
package vn.datahub.connect.gateway.api;

public interface GatewaySyncStatusApi {
  /** FR-03-046 bước 6. Saga PH-01 hỏi consumer đã được mọi nút của cả hai cửa nạp chưa. */
  SyncStatus consumerStatus(TenantId tenant, String consumerCode);
}

public enum SyncStatus { PENDING, IN_SYNC, PARTIAL, FAILED }
```

```java
package vn.datahub.connect.gateway.internal.assemble;

/** Cổng duy nhất tới dữ liệu nguồn của bộ tổng hợp (FR-03-039). Không ném lỗi nghiệp vụ. */
interface SourceReader {
  SourceBatch read(TenantId tenant, SourceCursor since);      // API, gói, đăng ký, HTTT, host, hạn mức hợp đồng
  Instant lastSuccess(SourceKind kind);                       // cho chỉ số dh_gateway_source_stale_seconds
}

record SourceBatch(List<PublishedApi> apis, List<PlanPolicy> plans, List<Subscription> subs,
    List<ConsumerSource> consumers, TenantProfile profile, PolicyBundleRef policyBundle) {}
```

### 3.4. Hợp đồng dữ liệu giữa hai mặt phẳng

Mặt phẳng điều khiển và mặt phẳng dữ liệu chỉ chia sẻ ba loại dữ liệu: ảnh chụp cấu hình, khóa Valkey và chỉ số. Chương này chốt định dạng của chúng vì cả hai bên cùng đọc.

**Ảnh chụp cấu hình** là một thư mục ở bucket `dh-platform-gateway` tại `snapshots/{site}/{version}/`, gồm: `manifest.json`, `manifest.sig`, `int.yaml`, `ext.yaml` (bản ghép cho từng cửa), `shards/{tenant}-{gate}.yaml` (mảnh tenant, dùng để so sánh và quay lui theo tenant). Con trỏ `snapshots/{site}/current` là tệp nhỏ chứa số phiên bản và băm manifest, ghi sau cùng.

```json
{
  "snapshotVersion": 48213,
  "site": "dc1",
  "generatedAt": "2026-11-26T09:14:03+07:00",
  "apisixImage": "3.11.0",
  "bundles": [
    {"gate": "INT", "file": "int.yaml", "sha256": "9f2c…"},
    {"gate": "EXT", "file": "ext.yaml", "sha256": "41ab…"}
  ],
  "shards": [{"tenant": "T68", "gate": "INT", "sha256": "c07d…"}, {"tenant": "COMMON", "gate": "INT", "sha256": "5e11…"}],
  "builtFrom": [{"source": "catalog", "cursor": "e-1204455"}, {"source": "onboarding", "cursor": "e-98812"}],
  "signature": {"alg": "ECDSA-P256-SHA256", "keyId": "dh-gateway-snapshot:3"}
}
```

Chữ ký ký trên băm SHA-256 của `manifest.json` đã chuẩn hóa (JSON chính tắc, khóa sắp tăng dần); manifest chứa băm của từng tệp nên một chữ ký phủ toàn bộ nội dung.

**Cấu hình một route trong bản ghép `int.yaml`.** Route dùng `plugin_config_id` cho phần chung của mẫu chính sách và chỉ mang riêng phần khác biệt, để ảnh chụp tỉnh vừa (khoảng 1.000 route) còn vài trăm KiB và hồ sơ `QM-CHUNG` (khoảng 70.000 route) còn khoảng 17 MiB (Q03-24).

```yaml
routes:
  - id: t68.tra-cuu-ho-tich.v1
    labels: {tenant: T68, gate: INT, api: tra-cuu-ho-tich, version: v1, exposure: INT, class: RESTRICTED}
    hosts: ["t68.api.datahub.gov.vn"]
    uri: /ho-tich/v1/*
    methods: [GET]
    plugin_config_id: pc.oauth2-standard.v3
    plugins:
      dh-auth:
        tenant: T68
        mode: OAUTH2                       # OAUTH2, MTLS, API_KEY, KEYLESS
        requiredScopes: ["ho-tich.read"]
        audience: "grp-ho-tich"
        allowedConsumers: ["ht-qlvb", "ht-ubnd-xa"]   # đăng ký sử dụng đang hiệu lực
      dh-limit:
        rate: {second: 20, minute: 600}
        quota: {hour: 20000, day: 200000}
        overrides: {"ht-qlvb": {second: 40}}           # đã giải thứ tự ưu tiên ở bộ tổng hợp (FR-03-024)
      opa: {host: "http://127.0.0.1:8181", policy: "dh/authz/ho_tich/allow", with_route: true}
    upstream_id: up.t68.ho-tich
```

**Danh mục khóa Valkey** (hàm tạo tên `FastKeys`, dấu ngoặc nhọn quanh mã tenant là hash tag của Valkey cluster ở `QM-CHUNG` để kịch bản nhiều khóa rơi vào cùng một slot):

| Khóa | Giá trị | Thời hạn | Người ghi | Người đọc |
|---|---|---|---|---|
| `{T68}:revoked:jti:{jti}` | `1` | Còn lại của token cộng 60 giây | `dh-connect` | `dh-revocation` |
| `{T68}:revoked:sub:{sub}` | `notBefore` (giây epoch) | Thời gian sống tối đa của token | `dh-connect` | `dh-revocation` |
| `{T68}:kill:route:{routeCode}` | Mã lệnh (`SUSPENDED`) | Tới khi mở lại | `dh-connect` | `dh-kill-switch` |
| `{T68}:kill:consumer:{consumerCode}` | Mã lệnh | Tới khi mở lại | `dh-connect` | `dh-kill-switch` |
| `{T68}:rl:t` | Bộ đếm tenant (cửa sổ 1 giây) | 2 giây | `dh-limit` | `dh-limit` |
| `{T68}:rl:c:{consumer}:{route}:{s|m}` | Hai bộ đếm cửa sổ kề nhau | 2 chu kỳ | `dh-limit` | `dh-limit` |
| `{T68}:q:{consumer}:{route}:{h|d|mo}:{mốc}` | Bộ đếm hạn ngạch | Hết chu kỳ cộng 1 giờ | `dh-limit` | `dh-limit`, `dh-connect` (báo cáo) |
| `{T68}:evt:quota` | Stream sự kiện ngưỡng | 24 giờ (tối đa 10.000 mục) | `dh-limit` | `QuotaEventConsumer` |

: Danh mục khóa Valkey của PH-03

Hai quy ước giữ cho đường nhanh an toàn. Mọi lệnh Valkey của plugin có thời hạn 50 ms và đi qua ngắt mạch cục bộ của `plugins/dh/valkey.lua`; lỗi nghĩa là "không biết", và mỗi plugin tự quyết định mở hay đóng theo bảng ở mục 8.3. Khóa chặn (`revoked`, `kill`) luôn có bản ghi bền ở PostgreSQL để dựng lại khi Valkey mất (mục 4.12).

**DTO chính của control plane.**

```java
public record BuildRequest(@NotNull Scope scope, TenantId tenant, @NotNull Trigger trigger,
    boolean dryRun, @Size(max = 500) String reason) {}

// Phiên bản đích nằm ở đường dẫn /snapshots/{version}:rollback (API-03-061), không nằm trong thân.
public record RollbackRequest(@NotNull Scope scope,
    @Size(min = 10, max = 500) String reason, @Min(1) @Max(168) Integer holdHours) {}

public record EmergencyBlockRequest(@NotNull TargetType targetType, @NotBlank String targetCode,
    @Size(min = 10, max = 500) String reason) {}

public record RevocationRequest(@NotNull RevocationKind kind, String jti, String sub,
    Instant notBefore, @NotNull Instant tokenExpiresAt, @NotBlank String reason) {}

public record ConsumerUpsert(@Pattern(regexp = "^[a-z][a-z0-9-]{2,62}$") String consumerCode,
    @NotBlank String systemCode, @NotNull ConsumerState state, PriorityGroup priorityGroup,
    boolean trustedSource, @NotNull AuthMethod authMethod,
    @Size(max = 2) List<@Pattern(regexp = "^[0-9a-f]{64}$") String> certThumbprints,
    Instant certNotAfter, @Pattern(regexp = "^[0-9a-f]{64}$") String apiKeyHash, Instant apiKeyNotAfter) {}
```

`SecretFieldGuard` quét thân `ConsumerUpsert` trước khi vào dịch vụ và từ chối mọi trường có dạng bí mật (khóa riêng PEM, chuỗi dài giống `client_secret`, khóa API dạng rõ) bằng ERR-03-003, nên không có đường nào đưa bí mật vào bảng hay vào ảnh chụp (FR-03-046 bước 4).

## 4. Thiết kế chi tiết từng thành phần

Chương này có 16 thành phần. Sáu thành phần đầu (4.1…4.6) ở mặt phẳng dữ liệu, bảy thành phần tiếp (4.7…4.13) ở mặt phẳng điều khiển và `dh-sync`, ba thành phần cuối (4.14…4.16) là các dịch vụ quản trị quanh chúng. Mỗi thành phần có bảng đặc tả 10 mục rồi tới chi tiết thiết kế.

### 4.1. Chuỗi chốt kiểm soát và thư viện chung

::: dac-ta
**Mục đích.** Chốt thứ tự thực thi của các chốt trong một lượt gọi, chọn chốt nào dùng plugin dựng sẵn và chốt nào do Datahub viết, và cung cấp thư viện chung (khóa Valkey, ngắt mạch, bộ đệm, lỗi, chỉ số) để mười plugin cư xử thống nhất.

**Lớp chính.** `PluginChainComposer` (control plane, sinh `global_rules` và `plugin_configs`); thư viện `plugins/dh/*` (data plane).

**Đơn vị chạy.** `dh-connect` (bộ kết xuất); `apisix` (plugin).

**FR hiện thực.** FR-03-001…038 (xếp chuỗi), FR-03-048 (mẫu chính sách), BR-03-017 (chỉ plugin trong danh mục).

**Giao diện vào.** Tệp `apisix.yaml` do `dh-sync` ghi; lược đồ plugin ở `schema/`.

**Phụ thuộc ra.** Valkey, OPA, Keycloak (JWKS), các `lua_shared_dict`.

**Dữ liệu.** Không có CSDL. Bộ nhớ chia sẻ giữa các worker ở bảng "Vùng nhớ chia sẻ".

**Sự kiện.** Không.

**Lỗi và xử lý.** Plugin lỗi bất ngờ: bắt bằng `pcall` ở lớp bao của thư viện, ghi `dh_gateway_plugin_errors_total{plugin}`, trả ERR-03-129 (500). Với chốt bảo mật, lỗi bất ngờ đóng an toàn (từ chối), không bỏ qua.

**Quan sát.** `dh_gateway_requests_total`, `dh_gateway_request_duration_seconds`, `dh_gateway_added_latency_seconds`, `dh_gateway_plugin_duration_seconds{plugin}`.
:::

Chi tiết thiết kế:

**Thay plugin dựng sẵn ở đâu và vì sao.** FRS và ADR-005 liệt kê các plugin dựng sẵn của APISIX. Thiết kế giữ những plugin chỉ làm đúng một việc và không dính thứ tự pha, và thay ba nhóm bằng logic của Datahub, vì lý do thứ tự thực thi, suy giảm có kiểm soát và mã lỗi thống nhất.

| Chốt | FRS, ADR-005 ghi | Hiện thực ở thiết kế | Lý do |
|---|---|---|---|
| Xác minh JWT, tenant, ràng buộc chứng thư, đăng ký sử dụng, phạm vi | `openid-connect` hoặc `jwt-auth`, `consumer-restriction` | `dh-auth` | Cần danh sách thuật toán cho phép, làm mới JWKS giới hạn 30 giây theo `kid` lạ, dùng bộ đệm tới 24 giờ, đối chiếu realm với tenant, đối chiếu `cnf` với chứng thư; đăng ký phải kiểm trước khi đếm hạn mức; một lần giải mã token cho cả nhóm chốt; mã lỗi `ERR-03-102…108, 111, 130` |
| Hạn mức tần suất, hạn ngạch, hạn mức tenant | `limit-count` | `dh-limit` | Ba tầng đếm trong một lượt Valkey; cửa sổ trượt (đóng Q03-06); suy giảm cục bộ chia theo số bản sao; hệ số nới cho `ESSENTIAL`; tiêu đề `X-RateLimit-*` thống nhất (BR-03-024) |
| Chống tràn theo địa chỉ nguồn | `limit-conn`, `limit-req`, `ip-restriction` | Gộp trong `dh-ip-block` | Plugin dựng sẵn chạy ở pha `access`, sau Coraza ở pha `rewrite`, trái thứ tự FRS (chống tràn trước WAF); `dh-ip-block` dùng cùng thư viện `resty.limit.conn`, `resty.limit.req` nên cùng thuật toán |
| Định dạng lỗi | Không nêu | `dh-problem` | Mọi từ chối do gateway sinh có thân RFC 9457, mã `ERR-03-1xx`, `X-Trace-Id` (BR-03-023) |
| Biên: tin cậy chặng, chứng thư khách, CRL, tiêu đề bảo mật, tiêu đề ngừng dùng | Không nêu rõ | `dh-edge` | Gom các việc cùng pha, cùng đọc ngữ cảnh kết nối |

: Plugin dựng sẵn được thay bằng plugin Datahub

Các plugin sau vẫn dùng bản dựng sẵn: `client-control` (giới hạn thân theo route), `cors`, `request-validation`, `opa`, `api-breaker`, `proxy-rewrite`, `grpc-transcode`, `prometheus`, `opentelemetry`, `file-logger`. Nếu đo thấy plugin Datahub không đạt ngân sách NFR-03-002, đường lùi là quay về plugin dựng sẵn cho chốt đó kèm giảm tính năng (mục 13.2).

**Thứ tự thực thi.** APISIX sắp plugin theo pha rồi theo ưu tiên giảm dần, và `global_rules` chạy trước plugin của route trong cùng pha. Cả mười plugin Datahub ở pha `rewrite` (trừ `dh-problem` ở pha lọc) để chúng chen được vào giữa các plugin dựng sẵn; riêng ưu tiên của `request-validation` giữ mặc định. Bảng dưới là thứ tự thực thi đầy đủ, đồng thời là nguồn cho `PluginChainComposer` và cho kiểm thử thứ tự (mục 12).

| Thứ tự | Plugin | Loại | Cửa | Pha | Ưu tiên | Chốt FRS |
|---|---|---|---|---|---|---|
| 1 | `client-control` | Dựng sẵn | Ext, Int | rewrite | 22000 | 3 (giới hạn thân, FR-03-009) |
| 2 | `dh-edge` | Datahub | Ext, Int | rewrite, header_filter | 21000 | 1 (TLS, mTLS, FR-03-001, 002) |
| 3 | `dh-ip-block` | Datahub | Ext, Int | rewrite, log | 9500 | 2 (FR-03-003, 004) |
| 4 | `coraza-block`, `coraza-detect` | wasm | Ext, Int | rewrite | 7999, 7998 | 4 (FR-03-005…008) |
| 5 | `dh-waf-guard` | Datahub | Ext, Int | rewrite, log | 7990 | 4 (đo, tự hạ, FR-03-006) |
| 6 | `cors` | Dựng sẵn | Ext cho route `EXT`, Int | rewrite | 4000 | FR-03-010 |
| 7 | `dh-auth` | Datahub | Int | rewrite | 3000 | 5, 7 (FR-03-012…017) |
| 8 | `dh-revocation` | Datahub | Int | rewrite | 2950 | 6 (FR-03-018) |
| 9 | `dh-kill-switch` | Datahub | Int | rewrite | 2940 | FR-03-035, 036, 047 |
| 10 | `dh-path-acl` | Datahub | Int | rewrite | 2930 | 7 (FR-03-020) |
| 11 | `dh-limit` | Datahub | Int | rewrite | 2900 | 8 (FR-03-021…026) |
| 12 | `dh-adaptive-throttle` | Datahub | Int | rewrite, log | 2890 | 8 (FR-03-027) |
| 13 | `request-validation` | Dựng sẵn | Int | rewrite | 2800 | 10 (FR-03-009) |
| 14 | `proxy-rewrite` | Dựng sẵn | Int | rewrite | 1008 | FR-03-035, 037 |
| 15 | `opa` | Dựng sẵn | Int | access | 2001 | 9 (FR-03-019) |
| 16 | `api-breaker` | Dựng sẵn | Int | access, log | 1005 | 11 (FR-03-031) |
| 17 | `dh-problem` | Datahub | Ext, Int | header_filter, body_filter | 10 | BR-03-023 |
| 18 | `prometheus`, `opentelemetry`, `file-logger` | Dựng sẵn | Ext, Int | log | 500, 12, 399 | 12 (FR-03-050, 052) |

: Thứ tự thực thi các plugin của PH-03

Hai điều chỉnh so với bảng thứ tự ở FRS mục 2.4. Thứ nhất, chốt 9 (OPA) và chốt 10 (kiểm tra lược đồ) đổi chỗ: `request-validation` chạy ở pha `rewrite` nên đứng trước `opa` ở pha `access`; hai chốt cùng đứng sau chốt hạn mức nên không đổi ý nghĩa bảo vệ, chỉ đổi thứ tự giữa một lần phân tích thân và một lời gọi OPA cục bộ. Thứ hai, `client-control` chạy rất sớm vì chỉ đặt giới hạn đọc thân của NGINX, việc cưỡng chế xảy ra khi thân được đọc nên không làm sớm hơn chốt IP về mặt hiệu lực. Sự thật về pha và ưu tiên của từng plugin dựng sẵn cần xác minh với APISIX 3.11 trước khi chốt các giá trị ưu tiên (xác minh X1, mục 13.1).

```{.mermaid caption="Chuỗi chốt qua hai chặng của một lượt gọi từ Internet"}
flowchart TB
  C["Bên gọi Internet"] --> A1["apisix-ext<br/>1 client-control, 2 dh-edge<br/>3 dh-ip-block, 4 WAF, 6 cors"]
  A1 -->|"cổng 8444, mesh mTLS"| B1["apisix-int cổng edge-in<br/>dh-edge tin tiêu đề do ext đặt<br/>bỏ qua IP và WAF đã làm"]
  B1 --> B2["7 dh-auth<br/>8 dh-revocation, 9 dh-kill-switch<br/>10 dh-path-acl"]
  B2 --> B3["11 dh-limit, 12 dh-adaptive-throttle"]
  B3 --> B4["13 request-validation, 15 opa"]
  B4 --> B5["16 api-breaker, định tuyến"]
  B5 --> D["Backend"]
  T["Bên gọi TSLCD"] -->|"cổng 443"| B0["apisix-int cổng công khai<br/>chạy cả chốt 1 đến 6"]
  B0 --> B2
```

Hình cho thấy lưu lượng Internet chạy chốt biên ở `apisix-ext`, sang `apisix-int` qua cổng riêng 8444 rồi chạy nửa còn lại; lưu lượng TSLCD vào cổng 443 của `apisix-int` và chạy đủ chốt 1 đến 6 trước khi vào nửa còn lại. Cổng 8444 chỉ nhận lưu lượng từ service account của `apisix-ext` (chính sách `AuthorizationPolicy` của mesh), và là cổng duy nhất mà `dh-edge` tin tiêu đề `X-DH-Edge-*` (mục 4.2).

**Vùng nhớ chia sẻ.** Khai báo ở `config.yaml.tmpl` bằng `lua_shared_dict`; tổng khoảng 114 MiB mỗi pod, nằm trong 1 GiB của pod APISIX (D03-01 §4.3) cùng với bộ nhớ của Coraza.

| Vùng | Cỡ | Nội dung | Plugin dùng | Khi đầy |
|---|---|---|---|---|
| `dh_jwks` | 8 MiB | JWKS thô theo realm, thời điểm làm mới thành công cuối | `dh-auth` | Không đầy (số realm tối đa khoảng 50) |
| `dh_fast` | 32 MiB | Kết quả tra khóa chặn trong 5 giây, kể cả kết quả "không có" | `dh-revocation`, `dh-kill-switch` | Đẩy mục cũ nhất (LRU) |
| `dh_limit_local` | 16 MiB | Bộ đếm cục bộ khi Valkey mất; bộ đệm kết quả ngắn | `dh-limit` | Đẩy mục cũ nhất |
| `dh_ip` | 32 MiB | Đếm kết nối, tốc độ, khóa chặn theo IP | `dh-ip-block` | Không theo dõi IP mới, tăng `dh_gateway_ip_table_full_total`, cảnh báo Cao |
| `dh_throttle` | 4 MiB | Thống kê lỗi, độ trễ theo upstream, hệ số điều tiết | `dh-adaptive-throttle` | Đẩy mục cũ nhất |
| `dh_state` | 2 MiB | Cờ cả nút: Valkey mất, WAF tự hạ, số bản sao, phiên bản cấu hình | Nhiều plugin | Không đầy |
| `dh_crl` | 20 MiB | Tập số seri chứng thư bị thu hồi theo CA | `dh-edge` | Từ chối chứng thư của CA đó (đóng an toàn) |

: Vùng nhớ chia sẻ của một pod APISIX

**Quy tắc viết plugin** (kiểm bằng `luacheck`, `busted` và rà soát theo SEC-41): mọi lời gọi mạng trong đường lượt gọi có thời hạn khai báo (Valkey 50 ms, OPA `gw.opa.timeoutMs`, JWKS 2 giây ở tác vụ nền, không bao giờ ở đường lượt gọi); không đọc tệp, không gọi DNS đồng bộ ở đường lượt gọi; không ghi vào nhật ký giá trị tiêu đề xác thực, giá trị tham số truy vấn hay thân (BR-03-007), chỉ ghi tên và băm cắt ngắn; mỗi plugin khai `schema` để `dh-connect` và `dh-sync` kiểm cấu hình bằng chính lược đồ đó; không plugin nào đọc tenant từ tiêu đề do bên gọi gửi (BR-03-002).

### 4.2. Lớp biên: TLS, chứng thư khách, chống tràn, WAF

::: dac-ta
**Mục đích.** Kết thúc TLS 1.3, xác minh chứng thư khách và tình trạng thu hồi, loại lưu lượng độc hại sớm bằng giới hạn theo địa chỉ nguồn và WAF, và truyền ngữ cảnh kết nối đã xác minh từ `apisix-ext` sang `apisix-int`.

**Lớp chính.** `dh-edge`, `dh-ip-block`, `dh-waf-guard`, `coraza-block`, `coraza-detect`, `plugins/dh/cert.lua`, `crl.lua`; control plane: `WafDirectiveRenderer`, `TlsProfileService`.

**Đơn vị chạy.** `apisix` (cả hai cửa); `dh-connect` (kết xuất, quản trị).

**FR hiện thực.** FR-03-001…011, FR-03-038, FR-03-049.

**Giao diện vào.** HTTPS cổng 443 (cả hai cửa); cổng 8444 ở `apisix-int` (chỉ từ `apisix-ext`); API-03-031…051 (quản trị).

**Phụ thuộc ra.** Secret chứng thư (cert-manager, External Secrets); tệp CRL do `dh-sync` tải; `apisix-int:8444` (từ ext).

**Dữ liệu.** `dh_ip`, `dh_crl`, `dh_state` ở shared dict; ngoại lệ luật, danh sách chặn tay ở PostgreSQL và trong ảnh chụp.

**Sự kiện.** EVT-03-05, EVT-03-06 (ngoại lệ WAF), EVT-03-08 (chứng thư), EVT-03-09 (cảnh báo an ninh).

**Lỗi và xử lý.** ERR-03-108 (chứng thư), 109 (WAF), 110 (IP bị chặn), 115 (thân lớn), 119 (tràn theo IP), 128 (SNI không khớp). Kho CRL quá 24 giờ không làm mới được: từ chối chứng thư của CA đó, cảnh báo Nghiêm trọng.

**Quan sát.** `dh_gateway_tls_handshake_total{version,result}`, `dh_gateway_mtls_total{result}`, `dh_gateway_ip_limit_rejected_total{kind}`, `dh_gateway_waf_blocked_total{rule}`, `dh_gateway_waf_duration_seconds`, `dh_gateway_waf_mode`.
:::

Chi tiết thiết kế:

**Cổng nghe.** Mỗi cửa vào có cổng riêng để tách lưu lượng khách khỏi lưu lượng giữa các chặng.

| Cổng | Thuộc | Ai vào được | Ghi chú |
|---|---|---|---|
| `apisix-ext:443` | `dh-edge`, Z1 | Internet qua bộ cân bằng tải (`externalTrafficPolicy: Local` để giữ địa chỉ nguồn thật) | TLS 1.3, IPv4 và IPv6 ngăn xếp kép (NFR-03-025) |
| `apisix-int:443` | `dh-gateway`, Z2 | Mạng TSLCD, nội bộ tỉnh | Chạy chốt 1 đến 6 như `apisix-ext` |
| `apisix-int:8444` | `dh-gateway`, Z2 | Chỉ service account của `apisix-ext` (`AuthorizationPolicy`, SEC-15) | `dh-edge` tin tiêu đề `X-DH-Edge-*`; bỏ qua IP và WAF |
| `:9091`, `:9092` | Cả hai | Chỉ Prometheus và vận hành (SEC-14) | Chỉ số; Control API; Admin API tắt (`enable_admin: false`) |

: Cổng nghe của hai cửa vào

**`dh-edge`: chặng và chứng thư (FR-03-001, 002).** Bước đầu tiên của chuỗi, trước mọi plugin khác, `dh-edge` làm theo thứ tự sau.

1. Xóa mọi tiêu đề `X-DH-*` của yêu cầu, ngoại trừ khi yêu cầu tới cổng 8444 (chặng thứ hai); khi đó giữ lại đúng các tiêu đề `X-DH-Edge-Src-Ip`, `-Cert-Sha256`, `-Cert-Serial`, `-Tls`, `-Waf` mà `apisix-ext` đặt và xóa mọi tiêu đề `X-DH-*` khác (BR-03-002).
2. Xác định địa chỉ nguồn thật `dh_client_ip`: là địa chỉ socket ở cổng công khai, hoặc `X-DH-Edge-Src-Ip` ở cổng 8444.
3. Với `apisix-ext`: kiểm tra route (hoặc host) có nhãn `exposure: EXT`; không có thì trả ERR-03-114 như không tồn tại (BR-03-015, FR-03-038 bước 6 của luồng ngoại lệ). SNI không khớp host nào: ERR-03-128.
4. Với kết nối có chứng thư khách: lấy chứng thư từ `ssl_client_raw_cert`, tính vân tay SHA-256 trên DER một lần cho mỗi kết nối (bộ nhớ theo `connection` có TTL 60 giây, tối đa 5.000 mục), lấy số seri; tra số seri trong `dh_crl` của CA phát hành (đã nạp từ tệp CRL do `dh-sync` tải mỗi giờ); trong danh sách hoặc CRL quá 24 giờ: ERR-03-108.
5. Đặt `ctx.var.dh_cert_sha256`, `dh_cert_serial`, `dh_tls_version`. Ở `apisix-ext`, đặt các tiêu đề `X-DH-Edge-*` cho chặng sau.
6. Chọn chế độ WAF cho yêu cầu: `ctx.var.dh_waf_mode` bằng `BLOCK` hoặc `DETECT` theo cấu hình route, trừ khi cờ `waf_degraded` ở `dh_state` đang bật (mục `dh-waf-guard` dưới đây).
7. Ở pha `header_filter`: đặt `Strict-Transport-Security`, `X-Content-Type-Options`, `Cache-Control` cho phản hồi lỗi, xóa `Server`, `X-Powered-By` (FR-03-011, BR-03-013); đặt `X-Trace-Id` từ `traceparent` (FR-03-032); đặt `Deprecation`, `Sunset`, `Link` khi route khai báo ngừng dùng hoặc chuyển tiếp (FR-03-035, 037).

Khi `dh-edge` ở cổng 8444 nhận yêu cầu mà thiếu `X-DH-Edge-Src-Ip` hoặc có giá trị sai dạng, nó từ chối bằng ERR-03-129 và tăng `dh_gateway_edge_proof_invalid_total`, vì chỉ `apisix-ext` được vào cổng này và tình huống đó là lỗi cấu hình hoặc có kẻ đã chiếm một pod trong mạng.

**TLS theo SNI (FR-03-001).** Hồ sơ TLS toàn cục: `ssl_protocols TLSv1.3`, bộ mã TLS 1.3 theo FRS bảng "Hồ sơ TLS", nhóm khóa `X25519`, `secp256r1`, `ssl_session_tickets off`, OCSP stapling bật. Ngoại lệ TLS 1.2 là một đối tượng `ssls` riêng cho host chuyên dụng (`tls12.{tenant}.…`) với `ssl_protocols: [TLSv1.2, TLSv1.3]` và bộ mã TLS 1.2 cho phép; `TlsExceptionService` tạo, hết hạn và thu hồi đối tượng này qua ảnh chụp. Bộ CA khách của host mTLS khai ở `ssls[].client.ca` (bộ CA HTTT của OpenBao PKI và CA tỉnh chấp nhận, API-03-035). Host chấp nhận cả khách có và không có chứng thư không dùng chung một host với route bắt buộc mTLS: route `requireMtls` đặt trên host riêng (`mtls.{tenant}.…`), vì APISIX cấu hình xác minh chứng thư theo SNI (xác minh X3).

**`dh-ip-block`: chống tràn theo địa chỉ nguồn (FR-03-003, 004).** Plugin chạy trước WAF và hoàn toàn cục bộ trong pod (không dùng Valkey) để chống tràn không phụ thuộc kho nào. Thuật toán cho mỗi yêu cầu:

1. Nếu `dh_client_ip` thuộc `gw.ip.trustedCidrs` (so khớp bằng cây tiền tố `ipmatcher`, nạp khi cấu hình đổi) thì bỏ qua các bước 2 đến 4.
2. Tra `dh_ip` xem địa chỉ có đang bị chặn (tự động hoặc thủ công): có thì ERR-03-110 (403).
3. Đếm kết nối đồng thời bằng `resty.limit.conn` theo khóa IP; vượt `gw.ip.maxConnections` thì ERR-03-119 (429).
4. Đếm tốc độ bằng `resty.limit.req` (rò rỉ thùng), tốc độ `gw.ip.uiReqPerSecond` cho đường dẫn giao diện (route có nhãn `kind: ui`) và `gw.ip.apiReqPerSecond` cho API máy, dung sai `gw.ip.burst`; vượt thì ERR-03-119.
5. Mỗi lần ERR-03-119 tăng bộ đếm vi phạm của IP trong cửa sổ 60 giây; đạt `gw.ip.autoBlock.threshold` thì ghi khóa chặn có TTL `gw.ip.autoBlock.minutes` vào `dh_ip` và phát EVT-03-09 qua `kafka-logger` ở pha `log`.
6. Giữ `ctx.dh_stage = "ip"` khi qua.

Danh sách chặn thủ công và `trustedCidrs` đi theo ảnh chụp (siêu dữ liệu plugin `dh-ip-block`) nên có hiệu lực cùng nhịp với cấu hình, thường dưới 10 giây. Chặn tự động chỉ có hiệu lực trong pod phát hiện; lưu lượng tấn công trải qua `n` pod nên mỗi pod tự chặn khi đủ ngưỡng của nó, đạt mục tiêu chặn ≤ 60 giây (NFR-03-013) mà không cần chia sẻ trạng thái. Hệ quả chấp nhận được: một IP bị chặn ở pod A có thể còn qua được pod B tới khi B cũng phát hiện.

**WAF (FR-03-005…008).** Coraza 0.5.0 dạng proxy-wasm nạp hai lần dưới hai tên là `coraza-block` (ưu tiên 7999, `SecRuleEngine On`) và `coraza-detect` (7998, `SecRuleEngine DetectionOnly`), cùng một tệp `.wasm`. Mỗi plugin mang `_meta.filter` kiểm tra biến `dh_waf_mode`, nên với mỗi yêu cầu chỉ một trong hai chạy; cách này cho phép đổi chế độ theo route bằng ảnh chụp và cho phép `dh-edge` hạ nút về `DETECT` tức thì khi quá tải mà không cần nạp lại cấu hình (xác minh X2). Chỉ thị CRS do `WafDirectiveRenderer` sinh từ cấu hình tenant và route:

| Nội dung | Chỉ thị sinh ra | Nguồn |
|---|---|---|
| Mức hoang tưởng | `SecAction "id:900000,phase:1,pass,nolog,setvar:tx.blocking_paranoia_level={1|2}"` | `gw.waf.paranoia.ui` (đường dẫn giao diện), `.api` |
| Ngưỡng điểm bất thường | `setvar:tx.inbound_anomaly_score_threshold={n}` | `gw.waf.anomalyThreshold` |
| Phần thân được quét | `SecRequestBodyLimit`, `SecRequestBodyInMemoryLimit` | `gw.waf.bodyScanBytes` |
| Ngoại lệ có hạn | `SecRuleRemoveById {mã}` đặt trong chỉ thị của đúng route | Ngoại lệ `ACTIVE` (EN-03-07) |
| Luật vá ảo | Luật `SecRule … "id:{90000…99999},phase:2,deny,status:403"` thêm vào chỉ thị của route hoặc tenant | EN-03-08, dải mã dành cho luật cục bộ |
| Che dữ liệu trong nhật ký WAF | `SecAuditLogParts` không gồm thân; `SecAuditLog` tắt, dùng chỉ số | BR-03-007 |

: Chỉ thị Coraza do bộ kết xuất sinh

Không dùng `Include` tệp ngoài ảnh: bộ luật CRS 4.x nằm trong ảnh ở đường dẫn cố định `@owasp_crs` và được ký cùng ảnh, nên người dùng không đưa được luật vào runtime (BR-03-017). Ngoại lệ chỉ có hiệu lực sau khi ở trạng thái `ACTIVE` trong ảnh chụp đang chạy; hết hạn do `ExpiryScheduler` kích hoạt một lần tổng hợp đúng phút hết hạn (độ trễ tối đa 60 giây, Q03-27).

**`dh-waf-guard`: đo và tự hạ (FR-03-006).** Plugin đứng ngay sau hai plugin Coraza (ưu tiên 7990). `dh-ip-block` ghi `ctx.dh_t_pre_waf` ngay trước WAF; `dh-waf-guard` tính chênh lệch với đồng hồ tại chỗ của nó, đưa vào histogram `dh_gateway_waf_duration_seconds` và vào cửa sổ trượt 2 phút trong `dh_state`. Khi p99 cửa sổ vượt `gw.waf.degradeP99Ms` liên tục 2 phút, plugin đặt cờ `waf_degraded` (nút chạy `coraza-detect` cho mọi route, kể cả route đặt `BLOCK`), phát cảnh báo Nghiêm trọng; khi p99 dưới ngưỡng 5 phút liên tục thì xóa cờ. Yêu cầu bị Coraza chặn không tới được `dh-waf-guard`; chúng được nhận ra ở pha lọc nhờ `ctx.dh_stage` vẫn là `ip` kèm mã 403, để `dh-problem` trả ERR-03-109 và đếm đúng (mục 4.6).

**Sự kiện WAF.** Mã luật khớp, điểm bất thường, route và `traceId` của từng yêu cầu bị chặn hoặc bị ghi nhận ở `DETECT` (FR-03-005 bước 4) không do plugin Lua tạo, mà lấy từ nhật ký của Coraza: Coraza ghi mỗi luật khớp vào nhật ký lỗi của NGINX (không có thân), OTel Collector đọc dòng đó, tách `ruleId`, `score`, `uri`, giữ tối đa 40 ký tự đầu của đoạn khớp sau khi che theo mẫu (SEC-32) rồi ghép với `traceId` và ghi vào kho của PH-13 cùng bộ đếm `dh_gateway_waf_blocked_total{rule}`. `GET /waf/events` (API-03-039) đọc từ kho đó. Nếu bộ nhận không tách được dòng, sự kiện vẫn có `traceId` và mã ERR-03-109 ở nhật ký lượt gọi, chỉ thiếu mã luật (xác minh X5).

### 4.3. Xác thực, thu hồi, tạm ngừng và đường dẫn

::: dac-ta
**Mục đích.** Xác minh token hoặc chứng thư của bên gọi, xác định tenant không giả mạo được, kiểm tra đăng ký sử dụng và phạm vi, rồi áp thu hồi nhanh, tạm ngừng và danh sách cho phép, chặn đường dẫn, tất cả bằng dữ liệu đã nạp sẵn.

**Lớp chính.** `dh-auth`, `dh-revocation`, `dh-kill-switch`, `dh-path-acl`, `plugins/dh/jwks.lua`.

**Đơn vị chạy.** `apisix` (chỉ `apisix-int`).

**FR hiện thực.** FR-03-012…018, FR-03-020, FR-03-036 (phần thực thi dừng), FR-03-047 (phần thực thi), FR-03-035 (`SUNSET`).

**Giao diện vào.** Yêu cầu HTTP đã qua chốt biên; plugin_metadata `dh-auth` (danh sách realm), cấu hình consumer, cấu hình route.

**Phụ thuộc ra.** JWKS của Keycloak (tác vụ nền, đệm 10 phút, tối đa 24 giờ); Valkey (khóa chặn, qua bộ đệm 5 giây).

**Dữ liệu.** `dh_jwks`, `dh_fast`, `dh_state`; không CSDL.

**Sự kiện.** EVT-03-09 qua `kafka-logger` khi có truy cập chéo tenant, vân tay không khớp, token thu hồi lặp lại.

**Lỗi và xử lý.** ERR-03-102…108, 111, 113, 123, 124, 127, 130. JWKS quá 24 giờ không làm mới: ERR-03-124 (503), đóng an toàn. Valkey lỗi: `dh-revocation` và `dh-kill-switch` dùng bộ đệm gần nhất, không từ chối vì lý do Valkey.

**Quan sát.** `dh_gateway_jwt_verify_total{result}`, `dh_gateway_jwks_age_seconds{realm}`, `dh_gateway_auth_failed_total{reason}`, `dh_gateway_path_denied_total{kind}`, `dh_gateway_revocation_hits_total`, `dh_gateway_kill_hits_total{target}`.
:::

Chi tiết thiết kế:

**Dữ liệu cấu hình của `dh-auth`.** Danh sách realm nằm ở `plugin_metadata` toàn cục (một bản cho cả nền tảng, phân mảnh theo tenant ở ảnh chụp); thông tin từng consumer là đối tượng `consumers` của APISIX với plugin `dh-auth` mang phần công khai của thông tin xác thực; thông tin từng route nằm ở cấu hình plugin của route.

```yaml
plugin_metadata:
  dh-auth:
    issuers:
      "https://iam.datahub.gov.vn/realms/dh-t68": {tenant: T68, jwksUri: "https://keycloak.dh-iam.svc/realms/dh-t68/protocol/openid-connect/certs"}
    commonAccepts: "ANY_TENANT_REALM"        # route COMMON chấp nhận token của mọi realm tenant hợp lệ
consumers:
  - username: ht-qlvb                        # = consumerCode = clientId ở Keycloak
    plugins:
      dh-auth: {key: ht-qlvb, tenant: T68, state: ACTIVE, priority: NORMAL,
                certThumbprints: ["9f2c…"], certNotAfter: "2027-06-30T00:00:00+07:00"}
```

**Các bước của `dh-auth` ở mỗi lượt gọi.** Plugin đọc token một lần, giữ ngữ cảnh ở `ctx.var.dh_*` cho các plugin sau. Mỗi bước, khi không đạt, trả mã lỗi ở cột cuối và dừng chuỗi.

| Bước | Việc | FR | Mã lỗi khi không đạt |
|---|---|---|---|
| 1 | Route `KEYLESS` (chỉ API dữ liệu mở): bỏ qua, `consumer` rỗng, vào bước 9 | 015 | — |
| 2 | Lấy token ở `Authorization: Bearer`, đúng một token; thiếu: 401 kèm `WWW-Authenticate` | 012 | ERR-03-102 |
| 3 | Giải mã tiêu đề JWT; `alg` thuộc {`ES256`, `PS256`}; có `kid` | 012 | ERR-03-103 |
| 4 | Tìm khóa theo `kid` ở bộ đệm JWKS của realm thuộc `iss`; chưa có thì làm mới một lần nếu cách lần trước ≥ 30 giây | 012 | ERR-03-103 |
| 5 | Kiểm chữ ký; `iss` thuộc danh sách realm; `aud` có nhóm API của route; `exp`, `nbf` với dung sai `gw.jwt.clockSkewSeconds` | 012 | ERR-03-103, 104 |
| 6 | Tenant: `tenant` của token khớp tenant của realm `iss` và tenant của route (route `COMMON` thì lấy từ token); không khớp: ghi sự kiện an ninh | 013 | ERR-03-106 |
| 7 | Tra consumer theo `azp`; `state` `SUSPENDED` thì từ chối | 016, 046 | ERR-03-127 |
| 8 | Ràng buộc chứng thư: route hoặc token có `cnf` thì so `cnf.x5t#S256` với `dh_cert_sha256` và với vân tay đã đăng ký; lệch hoặc thiếu: ghi sự kiện an ninh | 014 | ERR-03-108 |
| 9 | Phương thức bảo mật khớp gói: `mode` của route so với cách bên gọi đã xác thực (OAuth2, mTLS, khóa API) | 015 | ERR-03-130 |
| 10 | Đăng ký sử dụng: `azp` thuộc `allowedConsumers` và chưa quá `until` của mục đó | 016 | ERR-03-111 |
| 11 | Phạm vi: `scope` của token chứa mọi `requiredScopes` của route | 017 | ERR-03-107 |
| 12 | Đặt `X-DH-Tenant`, `X-DH-Client`, `X-DH-Consumer`; `ctx.dh_stage = "auth"` | 013 | — |

: Các bước của dh-auth

Đối chiếu realm với tenant dùng bảng `issuers` chứ không đọc tên realm từ chuỗi `iss`, để đổi tên realm không làm hỏng quy tắc. Ba lỗi bảo mật (bước 6 khi route khác tenant, bước 8, và bước 5 khi `kid` lạ lặp lại) ghi sự kiện an ninh có nhãn `reason` vào luồng `kafka-logger` (EVT-03-09), không ghi token. Bước 10 dùng `until` ở từng mục để hết hiệu lực đăng ký có tác dụng ở plugin tức thì, không chờ ảnh chụp mới; `SubscriptionExpiryScheduler` vẫn kích hoạt tổng hợp lại để dọn mục đã quá hạn.

**Bộ đệm JWKS (`jwks.lua`).** Mỗi worker giữ `lrucache` các khóa đã phân tích (`resty.openssl.pkey`) theo `realm:kid`; `dh_jwks` giữ JWKS thô và thời điểm làm mới cuối. Một worker duy nhất (khóa `resty.lock`) làm mới tất cả realm mỗi `gw.jwks.refreshMinutes` kèm độ lệch ngẫu nhiên ±20% để các pod không cùng gọi Keycloak; thất bại không xóa bộ đệm cũ, chỉ ngừng đẩy `dh_gateway_jwks_age_seconds` về 0. Quá `gw.jwks.maxStaleHours` thì realm đó bị đánh dấu hết hạn đệm và bước 4 trả ERR-03-124.

**`dh-revocation` (FR-03-018).** Chạy sau khi chữ ký đã đúng. Tra `{T}:revoked:jti:{jti}` và `{T}:revoked:sub:{sub}` qua một lượt đường ống (pipeline) tới Valkey, mỗi kết quả (kể cả "không có") được giữ ở `dh_fast` 5 giây. Token bị chặn khi có khóa `jti`, hoặc khi `iat` của token nhỏ hơn `notBefore` của khóa `sub`. Khóa `sub` cho phép thu hồi cả client mà không biết từng `jti`. Valkey lỗi: dùng giá trị trong `dh_fast` nếu còn, nếu không thì cho qua và tăng `dh_gateway_revocation_unknown_total`; đây là quyết định mở có chủ đích vì token sống tối đa 5 phút (SEC-25), và cảnh báo ở FR-03-026 đã bật.

**`dh-kill-switch` (FR-03-047, 036, 035).** Một plugin cho ba nhu cầu, vì cả ba là "trả lỗi cố định cho route hoặc consumer". Chế độ `dynamic` tra `{T}:kill:route:{routeCode}` và `{T}:kill:consumer:{consumerCode}` (cùng bộ đệm 5 giây). Chế độ `static` do ảnh chụp bật cho route ở trạng thái `STOPPED` (ERR-03-123, `503` kèm `Retry-After`), `SUSPENDED` (ERR-03-123) và `SUNSET` (ERR-03-126, `410`): không tra Valkey nên hoạt động kể cả khi Valkey mất. Consumer bị tạm ngừng: ERR-03-127 (403).

**`dh-path-acl` (FR-03-020).** Danh sách cho phép (`pathAllow`) và chặn (`pathDeny`) của gói biên dịch ở bộ kết xuất thành một cây tiền tố và các biểu thức glob đã kiểm tra tĩnh (không biểu thức chính quy tùy ý, tránh ReDoS); plugin chuẩn hóa đường dẫn trước khi so (giải mã `%xx` một lần, loại `//`, `./`, `../`, chặn `%2e%2e`, `%00`), so khớp, và trả ERR-03-113 cho đường dẫn bị chặn hoặc ngoài danh sách cho phép. Chuẩn hóa có chủ đích cùng một hàm với `proxy-rewrite` để đường dẫn được kiểm và đường dẫn chuyển tiếp là một.

### 4.4. Hạn mức, hạn ngạch và điều tiết

::: dac-ta
**Mục đích.** Bảo vệ backend và các tenant khác khỏi một bên gọi hoặc một tỉnh dùng quá mức: giới hạn tần suất theo giây và phút, hạn ngạch theo giờ, ngày, tháng, hạn mức toàn tenant, và điều tiết khi backend yếu; vẫn phục vụ khi Valkey mất.

**Lớp chính.** `dh-limit`, `dh-adaptive-throttle`, `lua/limit_script.lua`, `PolicyPrecedenceResolver` (control plane).

**Đơn vị chạy.** `apisix` (chỉ `apisix-int`); `dh-connect` giải thứ tự ưu tiên.

**FR hiện thực.** FR-03-021…027.

**Giao diện vào.** Cấu hình `dh-limit` của route; tham số `gw.rate.*`, `gw.quota.*`, `gw.tenantRateLimit.*`, `gw.degrade.*`, `gw.throttle.*`.

**Phụ thuộc ra.** Valkey (EVALSHA); `dh_limit_local`, `dh_throttle`, `dh_state`.

**Dữ liệu.** Khóa `rl`, `q`, `evt:quota` ở Valkey (mục 3.4); ghi đè hạn mức ở PostgreSQL (EN-03-06).

**Sự kiện.** EVT-03-07 (ngưỡng hạn ngạch) qua stream `{T}:evt:quota` rồi `QuotaEventConsumer`; EVT-03-09 khi vào, ra suy giảm.

**Lỗi và xử lý.** ERR-03-116 (tần suất, điều tiết), 117 (hạn ngạch), 118 (tenant). Valkey lỗi: suy giảm có kiểm soát, không từ chối vì Valkey.

**Quan sát.** `dh_gateway_ratelimit_rejected_total{limit}`, `dh_gateway_valkey_up`, `dh_gateway_valkey_latency_seconds`, `dh_gateway_throttle_factor{upstream}`, `dh_gateway_degraded_requests_total`.
:::

Chi tiết thiết kế:

**Một lượt Valkey cho ba tầng.** `dh-limit` gọi một kịch bản Lua chạy trong Valkey bằng `EVALSHA` (nạp bằng `SCRIPT LOAD` khi worker khởi động, nạp lại khi gặp `NOSCRIPT`). Kịch bản nhận danh sách khóa cùng hash tag `{T}` nên chạy được ở chế độ cluster, và quyết định theo thứ tự rẻ tới đắt: hạn mức tenant, tần suất của consumer trên route (hai cửa sổ), hạn ngạch (ba chu kỳ). Nó chỉ tăng bộ đếm khi cả ba tầng cho qua, nên một lượt bị từ chối ở tầng sau không làm hao hạn mức tầng trước.

```text
-- lua/limit_script.lua (rút gọn). KEYS: tenant, sec, min, qh, qd, qmo.  ARGV: nowMs, các giới hạn, hệ số
local function sliding(key, windowMs, limit, now)             -- cửa sổ trượt dạng bộ đếm kề nhau
  local cur   = math.floor(now / windowMs)
  local prev  = tonumber(redis.call('GET', key..':'..(cur-1)) or 0)
  local c     = tonumber(redis.call('GET', key..':'..cur) or 0)
  local frac  = 1 - ((now % windowMs) / windowMs)
  return prev * frac + c, cur                                -- số lượt ước tính trong cửa sổ trượt
end
-- 1. tenant: est >= tenantLimit*burst -> return {0, 'TENANT', retryAfter}
-- 2. consumer giây rồi phút: est + 1 > limit*factor -> return {0, 'RATE', retryAfter}
-- 3. hạn ngạch giờ, ngày, tháng (cửa sổ cố định theo lịch Asia/Ho_Chi_Minh):
--      > limit*(1+overrun) -> {0,'QUOTA', resetAt};  >= warnPercent -> XADD evt:quota (một lần mỗi mốc, SET NX)
-- 4. cả ba qua: INCR các khóa cửa sổ hiện tại (EXPIRE 2 chu kỳ) -> return {1, remaining, resetAt, warnLevel}
```

Cửa sổ trượt kiểu "bộ đếm kề nhau" xấp xỉ số lượt trong cửa sổ trượt bằng hai bộ đếm cố định kề nhau, sai số tối đa vài phần trăm và không đột biến ở ranh giới cửa sổ như cửa sổ cố định; đó là cách thiết kế đóng Q03-06 mà không phụ thuộc phiên bản APISIX. Hạn ngạch dùng cửa sổ cố định theo lịch vì hạn ngạch là khái niệm theo chu kỳ có điểm đặt lại.

**Hệ số theo nhóm ưu tiên.** `factor` bằng 1 với `NORMAL`, `gw.rate.essentialFactor` với `ESSENTIAL`; `LOW` bằng 1 và chịu điều tiết trước (FR-03-027). `ESSENTIAL` vượt hạn ngạch chu kỳ không bị chặn mà phát cảnh báo, tới tối đa `gw.quota.essentialOverrunPercent` (BR-03-009). Nhóm `ESSENTIAL` không được miễn hạn mức toàn tenant (đề nghị ghi ở D03-10 §5.3).

**Giải thứ tự ưu tiên ở control plane.** `PolicyPrecedenceResolver` hợp các nguồn thành một cấu hình hiệu lực trước khi ghi vào route: ghi đè `CONSUMER_ROUTE` thắng `CONSUMER`, thắng `ROUTE`, thắng gói, thắng mặc định tenant (FR-03-024); chỉ phần khác với giá trị mặc định của route mới vào `overrides` theo từng consumer, để cấu hình không phình theo tích số consumer × route.

**Tiêu đề phản hồi (FR-03-025, BR-03-024).** Mọi phản hồi của route có hạn mức mang `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` của giới hạn **chặt nhất hiện tại** (khoảng cách còn lại nhỏ nhất so với giới hạn); `Retry-After` kèm `429`; `X-RateLimit-Degraded: true` khi đang suy giảm. Tiêu đề do `dh-limit` đặt ở pha `rewrite` qua `ctx.var` và `dh-edge` ghi ra ở pha `header_filter`.

**Suy giảm khi Valkey mất (FR-03-026).** `plugins/dh/valkey.lua` ngắt mạch phía Valkey: lệnh vượt 50 ms hoặc lỗi thì đặt cờ `valkey_down` ở `dh_state` trong 5 giây, trong thời gian đó mọi lượt gọi bỏ qua Valkey ngay (không chờ thêm 50 ms) rồi một lượt thăm dò thử lại. Trong trạng thái suy giảm `dh-limit` làm ba việc: đếm tần suất và hạn mức tenant ở `dh_limit_local` bằng `resty.limit.count` với giới hạn bằng giới hạn gốc chia cho số bản sao (làm tròn lên), mở hạn ngạch giờ, ngày, tháng (cho qua, không đếm), đặt `X-RateLimit-Degraded: true`. Số bản sao do `dh-sync` đọc từ `EndpointSlice` của Service của pod mình và ghi vào tệp `/run/dh/replicas`; một bộ định giờ của `dh-limit` đọc tệp mỗi 5 giây vào `dh_state`; mất tệp thì dùng giá trị cuối hoặc biến môi trường `DH_REPLICAS_HINT` (Q03-25).

**`dh-adaptive-throttle` (FR-03-027).** Ở pha `log`, plugin cập nhật cho từng upstream hai thống kê trượt trong `dh_throttle`: tỉ lệ lỗi `5xx` và độ trễ nền (trung vị 10 phút) so với độ trễ hiện tại. Khi tỉ lệ lỗi vượt `gw.throttle.errorRatePercent` hoặc độ trễ vượt `gw.throttle.latencyFactor` lần nền, plugin đặt hệ số `throttle_factor` nhỏ hơn 1 cho upstream; ở pha `rewrite` yêu cầu của consumer `LOW` và `NORMAL` bị từ chối ngẫu nhiên với xác suất `1 - factor` bằng ERR-03-116, còn `ESSENTIAL` không bao giờ bị điều tiết. Hệ số phục hồi dần (nhân 1,25 mỗi 10 giây) khi chỉ số tốt lại. Plugin này cũng thực thi BR-03-011: khi mọi nút của một upstream đang không khỏe theo bộ kiểm tra sức khỏe (đọc qua thư viện nội bộ của APISIX, xác minh X7) hoặc `api-breaker` đã mở mạch thì trả ERR-03-120 (503) kèm `Retry-After` thay vì dồn tải vào nút đã hỏng, vì APISIX mặc định dùng lại toàn bộ nút khi tất cả bị đánh dấu không khỏe.

**Sự kiện ngưỡng không đi qua control plane trên đường lượt gọi.** Khi kịch bản thấy vượt `gw.quota.warnPercent` hoặc 100% lần đầu trong chu kỳ, nó `XADD` vào `{T}:evt:quota` (khóa `SET NX` theo `consumer:route:chu kỳ:mốc` để mỗi mốc chỉ một lần). `QuotaEventConsumer` ở `dh-connect` đọc nhóm tiêu thụ của stream, ghi outbox EVT-03-07 và xác nhận; mất stream (mất Valkey) chỉ làm mất cảnh báo trong chu kỳ đó, số liệu đúng vẫn ở siêu dữ liệu lượt gọi (Q03-12).

### 4.5. Định tuyến, upstream, OPA và chuyển tiếp

::: dac-ta
**Mục đích.** Đưa lượt gọi đã qua mọi chốt tới đúng backend của đúng tenant, cân bằng tải, phát hiện backend hỏng, giới hạn thời gian chờ, hỏi OPA để ra quyết định chi tiết, và hỗ trợ WebSocket, gRPC, phiên bản API song song, chuyển tiếp tenant sáp nhập.

**Lớp chính.** `PluginChainComposer`, `TenantShardRenderer` (kết xuất route, upstream); plugin dựng sẵn `opa`, `api-breaker`, `proxy-rewrite`, `grpc-transcode`.

**Đơn vị chạy.** `apisix` (`apisix-int`); `dh-connect` (kết xuất).

**FR hiện thực.** FR-03-019, 028…038.

**Giao diện vào.** Route và upstream trong `int.yaml`; gói chính sách OPA do PH-12 ký.

**Phụ thuộc ra.** OPA sidecar `127.0.0.1:8181`; backend (HTTT, `dh-runtime`, PH-14) qua mesh mTLS.

**Dữ liệu.** Không CSDL; trạng thái kiểm tra sức khỏe ở bộ nhớ từng worker.

**Sự kiện.** EVT-03-03 khi route đổi trạng thái hoặc cửa vào (do control plane).

**Lỗi và xử lý.** ERR-03-112 (OPA từ chối), 114 (không có route), 120, 121, 122 (backend), 124 (OPA không phản hồi), 125 (chuyển đổi giao thức không hỗ trợ). OPA không phản hồi trong `gw.opa.timeoutMs`: đóng an toàn bằng ERR-03-124.

**Quan sát.** `dh_gateway_upstream_duration_seconds{upstream}`, `dh_gateway_upstream_node_healthy{upstream,node}`, `dh_gateway_breaker_state`, `dh_gateway_upstream_timeout_total`, `dh_gateway_opa_duration_seconds`, `dh_gateway_opa_decision_total{decision}`.
:::

Chi tiết thiết kế:

**Kết xuất route và upstream.** Bảng dưới là ánh xạ từ thực thể logic sang tài nguyên APISIX, nguồn của `TenantShardRenderer`.

| Thực thể (EN-03) | Tài nguyên APISIX | Quy tắc kết xuất |
|---|---|---|
| EN-03-01 Route | `routes[]` | `id = {tenant}.{routeCode}`; `hosts` hoặc `uri` mang host hoặc tiền tố của tenant (BR-03-026); nhãn `tenant`, `gate`, `exposure`, `version`, `class`; `enable_websocket` khi FR-03-033; `plugin_config_id` theo mẫu chính sách |
| EN-03-02 Upstream | `upstreams[]` | `id = up.{tenant}.{upstreamCode}`; `type` `roundrobin`, `least_conn` hoặc `chash`; `scheme`; `timeout`; `checks.active` và `checks.passive`; `retries` 0 cho phương thức không lũy đẳng |
| EN-03-03, EN-03-04 Consumer | `consumers[]` | `username = consumerCode`; chỉ phần công khai của thông tin xác thực |
| EN-03-05 Chính sách từ gói | Cấu hình `dh-auth`, `dh-limit`, `dh-path-acl` của route | Không có plugin_config riêng cho từng gói, vì gói là nguồn của giá trị chứ không phải của cấu trúc |
| Mẫu chính sách (FR-03-048) | `plugin_configs[]` | `id = pc.{templateCode}.v{n}`; chỉ plugin trong danh mục |
| EN-03-11 Chứng thư | `ssls[]` | Khóa riêng điền ở nút bởi `dh-sync` |
| EN-03-13 Chuyển tiếp tenant | Route bổ sung trên host nguồn | Nhãn `tenant` là tenant đích (token tenant nguồn bị ERR-03-106), `dh-edge` đặt `Deprecation`, `Sunset`, `Link` |

: Ánh xạ thực thể sang tài nguyên APISIX

**Định tuyến theo tenant.** Bộ kiểm tra CHK-05 bảo đảm hai tenant không có route trùng host và đường dẫn. Route của tenant dùng host `{tenant}.api.…` hoặc tiền tố đường dẫn `/t/{tenant}/…` theo cấu hình tenant (D03-10 §4); route `COMMON` dùng host dùng chung. APISIX so khớp host rồi đường dẫn bằng cây tiền tố nên thời gian so khớp tăng chậm theo số route (NFR-03-017, xác minh X4).

**OPA (FR-03-019).** Plugin `opa` gọi `http://127.0.0.1:8181/v1/data/dh/authz/{policyPackage}/allow` với `with_route: true` (route kèm nhãn `class`, `tenant`) và `with_consumer: true`; claim của token không đi qua tiêu đề mà OPA lấy bằng `io.jwt.decode` từ tiêu đề `Authorization` đã được APISIX xác minh chữ ký, nên không có đường nào để bên gọi tự khai vai trò, tenant hay mục đích (Q03-04 chọn nguồn của `purpose`). Thời hạn `gw.opa.timeoutMs` (50 ms), `keepalive` bật; từ chối trả ERR-03-112 kèm `reason` từ `decision` (chỉ chuỗi lý do chuẩn do PH-12 định nghĩa, không lộ nội dung chính sách). Gói chính sách OPA được nạp từ bucket `dh-platform-policy` bởi chính OPA, lưu bền ra đĩa tạm (D03-09 §6.6).

**Kiểm tra sức khỏe, thời hạn, ngắt mạch (FR-03-029…031).** Mỗi upstream có `checks.active` kiểm `GET /readyz` hoặc TCP mỗi `gw.upstream.healthcheck.intervalSeconds`, đưa nút ra sau `failThreshold` lần lỗi và đưa vào lại sau `successThreshold` lần đạt; `checks.passive` loại nút khi gặp `502`, `503`, `504` liên tiếp. Thời hạn mặc định `connect` 3.000 ms, `read` 10.000 ms, trần 30.000 ms (CHK-08). `api-breaker` mở mạch sau `gw.breaker.failures` lỗi liên tiếp trong `gw.breaker.openSeconds` và trả `503`. Ghép `api-breaker` với kiểm tra mọi nút không khỏe ở `dh-adaptive-throttle` (mục 4.4) thành hành vi BR-03-011: lỗi nhanh và có `Retry-After`.

**Phiên bản API song song và `SUNSET` (FR-03-035).** Mỗi phiên bản là một route riêng (`…v1`, `…v2`) nên cùng chạy đồng thời. Route có `deprecatedAt` được `dh-edge` thêm `Deprecation: true` và `Sunset` ở `header_filter`; khi tới `sunsetAt` ảnh chụp mới chuyển route sang `SUNSET`, `dh-kill-switch` (chế độ `static`) trả ERR-03-126 (410). CHK-11 bảo đảm khoảng tối thiểu 180 ngày.

**WebSocket và gRPC (FR-03-033, 034).** `enable_websocket` cho route có nhãn tương ứng; giới hạn số kết nối WebSocket mỗi consumer ở `dh-limit` (loại giới hạn `ws`, ERR-03-116), `idle_timeout` theo `gw.ws.idleTimeoutSeconds`; kích thước thông điệp tối đa do cấu hình NGINX của route. `grpc-transcode` chỉ nạp khi FR-03-034 được bật (Đợt 3, Q03-07); route yêu cầu chuyển đổi mà không có `proto` nạp trả ERR-03-125.

### 4.6. Quan sát và định dạng lỗi ở mặt phẳng dữ liệu

::: dac-ta
**Mục đích.** Ghi mỗi lượt gọi ở mức siêu dữ liệu không chứa dữ liệu nhạy cảm, phát chỉ số và vết, và bảo đảm mọi lỗi do gateway sinh có một dạng thân thống nhất.

**Lớp chính.** `dh-problem`, `plugins/dh/problem.lua`, `plugins/dh/metrics.lua`; plugin dựng sẵn `file-logger`, `prometheus`, `opentelemetry`, `kafka-logger`.

**Đơn vị chạy.** `apisix` (cả hai cửa); OTel Collector dạng DaemonSet.

**FR hiện thực.** FR-03-032, 050, 052, 054 (phần phát cảnh báo), BR-03-007, BR-03-023.

**Giao diện vào.** Pha `header_filter`, `body_filter`, `log` của APISIX.

**Phụ thuộc ra.** Đĩa cục bộ `emptyDir` (đệm nhật ký); OTel Collector; Prometheus; `kafka-logger` cho EVT-03-09 và, đã chốt 27/11/2026, cho nhật ký truy cập của mọi route: ghi `{tenant}.obs.access.logged.v1` theo lược đồ `AccessLogged` của PH-13 (FR-13-006), chỉ siêu dữ liệu, không thân bản tin, không cắt `traceparent`.

**Dữ liệu.** Tệp nhật ký xoay vòng `/var/log/dh/access.log` tối đa `gw.accessLog.bufferMiB`.

**Sự kiện.** EVT-03-09.

**Lỗi và xử lý.** Đệm đĩa đầy: bỏ bản ghi cũ nhất, `dh_gateway_accesslog_dropped_total`, cảnh báo Cao; không ảnh hưởng lượt gọi. Không định dạng được lỗi: trả thân tối giản `{"code":"ERR-03-129"}` kèm `X-Trace-Id`.

**Quan sát.** `dh_gateway_accesslog_sent_total`, `dh_gateway_accesslog_dropped_total`, `dh_gateway_trace_invalid_total`, `dh_gateway_problem_total{code}`, `dh_connect_config_revision` (phiên bản cấu hình đang chạy, xuất cho PH-13; đã chốt 27/11/2026).
:::

Chi tiết thiết kế:

**Đường đi của nhật ký lượt gọi (FR-03-050).** `file-logger` ghi một dòng JSON mỗi lượt gọi ở pha `log` vào `/var/log/dh/access.log` trên volume `emptyDir` (giới hạn `ephemeral-storage`), với `log_format` chỉ liệt kê các biến được phép: `ts`, `tenant`, `traceId`, `spanId`, `routeCode`, `apiVersion`, `consumerCode`, `method`, `pathTemplate`, `queryNames`, `status`, `errorCode`, `latencyMs`, `upstreamMs`, `bytesIn`, `bytesOut`, `srcIp`, `authResult`, `limitResult`, `wafResult`, `opaResult`. Các biến này lấy từ `ctx.var.dh_*` do plugin Datahub đặt, nên bản ghi không thể chứa thân, tiêu đề xác thực hay giá trị tham số, vì không có biến nào mang chúng được đưa vào định dạng (BR-03-007). `pathTemplate` là mẫu đường dẫn của route (`/ho-tich/{id}`), không phải đường dẫn thật. OTel Collector chạy ở DaemonSet đọc tệp bằng bộ nhận `filelog`, chạy bộ xử lý `redaction` kiểm lần hai (SEC-32), gắn nhãn `tenant`, từ chối bản ghi không nhãn (SEC-84), rồi ghi vào ClickHouse của PH-13; xoay vòng tệp theo kích thước (`logrotate` trong `dh-sync`) giữ tổng tối đa `gw.accessLog.bufferMiB`, bản ghi cũ nhất mất trước khi đĩa đầy.

**Chỉ số và vết (FR-03-052).** `prometheus` dựng sẵn xuất ở `:9091`; các chỉ số `dh_gateway_*` do thư viện `metrics.lua` đăng ký với nhãn có số giá trị bị chặn (`tenant`, `route`, `gate`, `result`); nhãn `consumer` chỉ có ở chỉ số tổng hợp và bị chặn `gw.metrics.maxConsumerLabels` giá trị (Q03-08), phần còn lại tra ở ClickHouse. `opentelemetry` lấy mẫu 100% vết lỗi và `gw.trace.successSampling` vết thành công, tuân theo `traceparent` của bên gọi hoặc sinh mới (FR-03-032), chuyển `traceparent` xuống backend.

**`dh-problem`: một đường duy nhất cho lỗi do gateway sinh (BR-03-023).** Plugin chạy ở `header_filter` và `body_filter` với ưu tiên thấp nhất để thấy kết quả cuối. Nó chỉ can thiệp khi phản hồi do gateway sinh (không có `upstream_status` hoặc đó là trang lỗi mặc định của NGINX cho `502`, `504`), thay thân bằng RFC 9457 `{type, title, status, detail, code, traceId, instance}`, đặt `Content-Type: application/problem+json` và `X-Trace-Id`. Plugin Datahub từ chối bằng cách gọi `problem.reject(code, extra)` nên mã đã biết. Với plugin dựng sẵn, `dh-problem` suy ra mã từ **điểm dừng cuối cùng** `ctx.dh_stage` (mỗi plugin Datahub đặt khi qua) kết hợp mã HTTP của phản hồi, theo bảng dưới.

| Điểm dừng cuối | Mã HTTP | Plugin dựng sẵn khả dĩ kế tiếp | Mã lỗi |
|---|---|---|---|
| bất kỳ | 413 | `client-control` | ERR-03-115 |
| `ip` (sau `dh-ip-block`) | 403 | Coraza (`coraza-block`) | ERR-03-109 |
| `throttle` (sau `dh-adaptive-throttle`) | 400 | `request-validation` | ERR-03-101 |
| `throttle` | 403 | `opa` từ chối | ERR-03-112 |
| `throttle` | 503 | `opa` không phản hồi | ERR-03-124 |
| bất kỳ, không có `upstream_status` | 404, 405 | Không có route khớp | ERR-03-114 |
| bất kỳ, có lỗi nginx | 502, 504 | Backend | ERR-03-122, 121 |
| bất kỳ | 503 kèm tiêu đề `X-DH-Reject` | `api-breaker` mở mạch (cấu hình `break_response_headers`) | ERR-03-120 |

: Suy ra mã lỗi gateway cho plugin dựng sẵn

Với `api-breaker`, cấu hình `break_response_headers` đặt tiêu đề đánh dấu `X-DH-Reject: ERR-03-120` để phân biệt với `503` do OPA không phản hồi (cùng điểm dừng `throttle`); `dh-problem` xóa tiêu đề đánh dấu trước khi trả ra ngoài. Mỗi mã `ERR-03-101…130` có ít nhất một ca kiểm thử chứng minh thân đúng dạng (mục 12). Nếu bảng suy ra không đủ chắc chắn ở một cặp (điểm dừng, mã HTTP) nào, đường lùi là bọc plugin dựng sẵn đó bằng một lớp mỏng đặt `ctx.dh_reject`; việc này nằm trong xác minh X1.

### 4.7. Mô hình miền của control plane

::: dac-ta
**Mục đích.** Chốt các aggregate, invariant và trạng thái của dữ liệu PH-03 ở `dh-connect`, để mọi dịch vụ ở 4.8…4.16 cùng dùng một mô hình và cùng kiểm các quy tắc trước khi ghi.

**Lớp chính.** `Route`, `Upstream`, `Consumer`, `PlanPolicy`, `RateLimitOverride`, `WafException`, `VirtualPatch`, `ConfigSnapshot`, `EdgeCertificate`, `EmergencyBlock`, `TenantRedirect`, `ChangeRequest` (gói `internal.model` và gói của từng thành phần).

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** Mọi FR của nhóm B (phần dữ liệu), C, D, E, G; BR-03-006, 015, 019, 026, 029.

**Giao diện vào.** Dịch vụ ở 4.8…4.16.

**Phụ thuộc ra.** `pg-core` schema `ph03_gateway`.

**Dữ liệu.** Thực thể EN-03-01…15 (bảng cụ thể ở D03-03-PH03); cột `id`, `tenant_id`, `created_at`, `updated_at`, `version` theo D00-01 §5.1.

**Sự kiện.** Phát qua outbox cùng giao dịch với thay đổi trạng thái (EVT-03-01…12).

**Lỗi và xử lý.** ERR-03-001 (không thấy hoặc tenant khác), 002 (mã trùng), 004 (`If-Match` sai), 019 (đã ở trạng thái đích), 023 (route không ở trạng thái cho phép thao tác).

**Quan sát.** `dh_gw_cp_aggregate_conflicts_total{type}`, nhật ký kiểm toán theo FR-00.
:::

Chi tiết thiết kế:

```{.mermaid caption="Mô hình miền PH-03 ở control plane"}
classDiagram
  class Route {
    +String routeCode
    +String apiCode
    +Exposure exposure
    +RouteState state
    +Policy policy
    +stop(reason)
    +start()
    +suspend(reason)
    +resume(reason)
    +sunset()
  }
  class Consumer {
    +String consumerCode
    +String systemCode
    +PriorityGroup priorityGroup
    +ConsumerState state
    +upsertCredentials(public)
    +suspend()
  }
  class WafException {
    +String routeCode
    +String ruleId
    +ExState state
    +Instant expiresAt
    +approve(by)
    +reject(by)
    +revoke(by)
  }
  class ConfigSnapshot {
    +long version
    +SnapState state
    +String contentHash
    +validate()
    +sign()
    +publish()
    +markApplied()
  }
  class ChangeRequest {
    +ChangeType type
    +CrState state
    +approve(by)
    +reject(by)
  }
  class EmergencyBlock {
    +TargetType targetType
    +String targetCode
    +lift(by)
  }
  class TenantRedirect {
    +String fromTenant
    +String toTenant
    +Instant endAt
    +end()
  }
  class EdgeCertificate {
    +String certCode
    +Instant notAfter
  }
  Route "1" --> "1" Upstream
  Route "*" --> "*" Consumer : đăng ký sử dụng
  Route "1" o-- "*" WafException
  Route "1" o-- "*" RateLimitOverride
  ConfigSnapshot "1" --> "*" Route : builtFrom
  Consumer "1" --> "0..*" EmergencyBlock
  Route "1" --> "0..*" EmergencyBlock
  ChangeRequest ..> WafMode : áp khi duyệt
```

Mô hình có bốn aggregate gốc: `Route` (kèm ngoại lệ WAF và ghi đè hạn mức), `Consumer`, `ConfigSnapshot` và `ChangeRequest`; các thực thể còn lại là bản ghi độc lập có vòng đời ngắn. Invariant kiểm trong aggregate trước khi ghi, rồi bộ kiểm tra ở 4.9 kiểm lại ở mức cả cấu hình.

| Aggregate | Invariant | BR |
|---|---|---|
| `Route` | `routeCode` duy nhất trong tenant kể cả đã gỡ; host và đường dẫn không trùng route của tenant khác; `exposure` `EXT` chỉ khi có `ChangeRequest` đã duyệt còn hiệu lực | 026, 029, 015 |
| `Route` | Chuyển trạng thái theo bảng ở mục 8.1; `STOPPED` và `SUSPENDED` không chuyển thẳng sang nhau | — |
| `Consumer` | `consumerCode` bằng `clientId` ở Keycloak và duy nhất; không có trường bí mật; tối đa 2 vân tay chứng thư cùng lúc | 022 |
| `WafException` | Có lý do, gắn một route và một mã luật tồn tại ở CRS đang dùng, `expiresAt` ≤ 90 ngày; không có hai ngoại lệ còn hiệu lực cho cùng cặp route và mã luật; `approvedBy` ≠ `requestedBy` | 006, 019 |
| `ConfigSnapshot` | `version` tăng đơn điệu theo site; chỉ `SIGNED` mới phát được; quay lui sinh bản mới | 016, 018 |
| `ChangeRequest` | `decidedBy` ≠ `requestedBy`, so theo tài khoản; chỉ một yêu cầu đang chờ cho cùng đối tượng | 019 |
| `EmergencyBlock` | Một khối đang hoạt động cho mỗi đối tượng; mở lại ghi `liftedAt` và lý do | 021 |

: Invariant của các aggregate

Mọi aggregate có cột `version` làm khóa lạc quan; lệnh từ API mang `If-Match` (sai: ERR-03-004), lệnh hệ thống (hết hạn, tổng hợp lại) thử lại tối đa 3 lần khi xung đột. Xóa là xóa mềm (BR-03-029).

### 4.8. Bộ tổng hợp cấu hình

::: dac-ta
**Mục đích.** Biến dữ liệu nguồn đã duyệt và dữ liệu riêng của PH-03 thành bản ghép cấu hình APISIX nhất quán, tái lập được, đủ nhanh để lan tới nút trong 10 giây, mà không ai phải viết tay cấu hình.

**Lớp chính.** `SnapshotAssembler`, `SourceReader`, `TenantShardRenderer`, `PlatformMerger`, `PluginChainComposer`, `PluginTemplateRegistry`, `CanonicalYaml`, `BuildCoordinator`.

**Đơn vị chạy.** `dh-connect` (module `gateway`).

**FR hiện thực.** FR-03-039, FR-03-048, FR-03-056 (đọc tham số), BR-03-014, BR-03-016, BR-03-026.

**Giao diện vào.** Sự kiện từ PH-01, 02, 12, 20; tác vụ đối chiếu 5 phút; thay đổi trong PH-03; API-03-059.

**Phụ thuộc ra.** `catalog.api`, `onboarding.api` (đọc), PH-12, PH-20; `pg-core`.

**Dữ liệu.** `ph03_gateway`: bản ghi snapshot, bản chiếu nguồn, nhật ký tổng hợp (EN-03-09).

**Sự kiện.** Không (EVT-03-01 phát ở bước phát).

**Lỗi và xử lý.** ERR-03-006 (đang tổng hợp hoặc đang giữ sau quay lui). Nguồn không trả: dùng bản chiếu gần nhất, `dh_gateway_source_stale_seconds{source}`, cảnh báo quá 24 giờ.

**Quan sát.** `dh_gw_cp_build_duration_seconds{phase}`, `dh_gw_cp_build_total{trigger,result}`, `dh_gateway_source_stale_seconds{source}`, `dh_gw_cp_hold_active{tenant}`.
:::

Chi tiết thiết kế:

**Các bước của một lần tổng hợp.** `BuildCoordinator` điều phối; mọi bước chạy trong một tác vụ nền, mỗi lần một tenant một lượt (khóa `pg_advisory_lock` theo `hash(site, tenant)`), nên hai người cùng bấm "Tổng hợp lại" thì một lần chạy, lần sau nhận ERR-03-006.

1. **Gom sự kiện.** Sự kiện của cùng tenant trong `gw.snapshot.debounceSeconds` (3 giây) gộp thành một lần; tác vụ đối chiếu (ShedLock, 5 phút) so con trỏ nguồn đã dùng với con trỏ hiện tại và kích hoạt khi lệch, để bắt sự kiện bị lỡ.
2. **Kiểm giữ.** Tenant đang ở trạng thái giữ sau quay lui thì xếp hàng sự kiện, không tổng hợp (mục 4.10).
3. **Đọc nguồn.** `SourceReader.read` trả `SourceBatch`; mỗi nguồn lỗi thì dùng bản chiếu gần nhất của nó.
4. **Dựng mô hình** trong bộ nhớ: nối route với upstream, gói, đăng ký, consumer, ngoại lệ WAF `ACTIVE`, ghi đè hạn mức, chứng thư, chuyển tiếp; giải thứ tự ưu tiên hạn mức (mục 4.4).
5. **Kết xuất mảnh tenant** cho từng cửa bằng `TenantShardRenderer` thành YAML chính tắc (khóa sắp tăng dần, danh sách sắp theo `id`, không dấu thời gian), nên cùng đầu vào cho cùng băm.
6. **Ghép nền tảng.** `PlatformMerger` ghép mảnh mới với mảnh hiện hành của các tenant khác (đọc từ bản đã kết xuất lần trước, giữ trong bộ nhớ đệm theo băm) và mảnh `COMMON`, thành `int.yaml` và `ext.yaml`, rồi thêm `global_rules`, `plugin_configs`, `plugin_metadata`, `ssls` của nền tảng.
7. **Ghi nhận.** Tạo `ConfigSnapshot` `BUILT` với `builtFrom` (con trỏ nguồn đã dùng), băm; chuyển sang kiểm tra (4.9).

Chi phí tỉ lệ với kích thước của tenant thay đổi chứ không phải của cả nền tảng, vì mảnh các tenant khác dùng lại từ bộ nhớ đệm; ngân sách GĐ-03-07 là ≤ 5 giây cho tenant 1.000 route (tổng hợp, kiểm tra, ký). Khi ghép, thứ tự route trong tệp cố định nên `diff` giữa hai phiên bản chỉ chứa thay đổi thật (API-03-062).

**Đóng góp của PH-03 vào cấu hình toàn nền tảng.** Ba phần không thuộc tenant nào do `PluginChainComposer` dựng từ mã phát hành chứ không từ dữ liệu người dùng: `global_rules` của mỗi cửa (xếp theo bảng thứ tự thực thi ở mục 4.1), `plugin_configs` của mẫu chính sách đã bật (FR-03-048, `PluginTemplateRegistry` đọc từ gói đi kèm bản phát hành, chỉ chứa plugin trong danh mục, BR-03-017), và `plugin_metadata` (danh sách realm, danh sách chặn tay, bộ CA khách, `trustedCidrs`).

**Hạng mục đi theo bản phát hành, không đi theo dữ liệu.** Phiên bản APISIX và phiên bản plugin được ghi trong manifest (`apisixImage`); `dh-sync` từ chối ảnh chụp có `apisixImage` khác phiên bản đang chạy để một ảnh chụp sinh cho bản APISIX mới không làm hỏng nút còn ở bản cũ trong lúc nâng cấp cuốn chiếu, và `ApisixSchemaChecker` kiểm theo lược đồ đúng phiên bản đó (mục 4.9). Trong thời gian nâng cấp, `dh-connect` sinh song song hai ảnh chụp cho hai phiên bản và `dh-sync` chọn theo `apisixImage` của mình (Q03-20).

### 4.9. Bộ kiểm tra hợp lệ cấu hình

::: dac-ta
**Mục đích.** Không bao giờ đưa tới gateway cấu hình sai hoặc không an toàn: mọi bản ghép qua bộ quy tắc tĩnh trước khi ký.

**Lớp chính.** `SnapshotValidator`, `ValidationRule` (một lớp mỗi quy tắc CHK), `ApisixSchemaChecker`, `ValidationReport`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-03-040; BR-03-014, BR-03-017, BR-03-026; SEC-24, SEC-26, SEC-43, SEC-65.

**Giao diện vào.** Bản ghép `BUILT`; API-03-058 (chạy thử không ghi).

**Phụ thuộc ra.** Lược đồ JSON xuất từ ảnh APISIX và từ plugin Datahub (`schema/`); danh sách gói chính sách OPA hiện hành (qua PH-12); tuổi chứng thư.

**Dữ liệu.** Kết quả kiểm tra gắn với `ConfigSnapshot`.

**Sự kiện.** EVT-03-12 khi `REJECTED`.

**Lỗi và xử lý.** ERR-03-005, 011, 012, 013, 016, 018 theo quy tắc; mức `LỖI` làm cả ảnh chụp bị từ chối, mức `CẢNH BÁO` không chặn.

**Quan sát.** `dh_gw_cp_validation_total{rule,level}`, `dh_gw_cp_validation_duration_seconds`.
:::

Chi tiết thiết kế:

`SnapshotValidator` chạy mọi `ValidationRule` trên bản ghép (song song theo tenant, tuần tự trong tenant), gom `Violation(ruleId, object, message, level)` vào `ValidationReport`. FRS FR-03-040 yêu cầu dùng "chính bộ kiểm tra của phiên bản APISIX đang chạy"; thiết kế hiện thực bằng lược đồ JSON được **xuất từ chính ảnh APISIX** lúc dựng ảnh (`make schema-export` đọc `apisix/schema_def.lua` và `schema` của từng plugin Datahub), đóng gói vào `dh-connect` theo phiên bản ảnh; Java kiểm bằng thư viện JSON Schema (không chạy Lua), và `dh-sync` kiểm lần nữa bằng cùng lược đồ trước khi nạp.

| Quy tắc | Lớp | Dữ liệu cần | Ghi chú |
|---|---|---|---|
| CHK-01 | `ApisixSchemaRule` | Lược đồ JSON của ảnh `apisixImage` | Cả plugin dựng sẵn và Datahub |
| CHK-02, 03 | `ContractPresenceRule` | `PublishedApi.openapiRef`, danh sách gói chính sách OPA hiện hành | Route thiếu thì `ERR-03-012` |
| CHK-04 | `PluginCatalogRule` | `PluginTemplateRegistry` | Plugin ngoài danh mục: `ERR-03-013` |
| CHK-05 | `HostPathUniquenessRule` | Chỉ mục (host, đường dẫn đã chuẩn hóa) toàn site | Hai tenant không trùng |
| CHK-06 | `SecurityModeRule` | `class` của route, `mode` của gói, danh sách client theo hợp đồng | Gồm kiểm "0 client dùng `client_secret` cho hợp đồng từ mức Hạn chế" (đề nghị bổ sung SEC-24) |
| CHK-07 | `CorsRule` | Danh sách nguồn gốc | Cấm `*` |
| CHK-08 | `TimeoutAndBodyRule` | Thời hạn, `bodyMaxBytes` | ≤ 30.000 ms, ≤ 10 MiB |
| CHK-09 | `ExposureApprovalRule` | `ChangeRequest` đã duyệt còn hiệu lực | `ERR-03-011` |
| CHK-10 | `UpstreamAddressRule` | Địa chỉ upstream | Cấm loopback, `169.254.0.0/16`, dải quản trị Z7 (chống SSRF, SEC-43) |
| CHK-11 | `SunsetWindowRule` | `deprecatedAt`, `sunsetAt` | ≥ 180 ngày |
| CHK-12 | `LimitCeilingRule` | Trần hợp đồng từ PH-20 | `ERR-03-018` |
| CHK-13 | `CertificateValidityRule` | `notAfter` các chứng thư của host | ≥ 7 ngày, `ERR-03-016` |
| CHK-14 | `ReferenceIntegrityRule` | Consumer, đăng ký, upstream được tham chiếu | |
| CHK-15 | `SizeRule` | Kích thước ảnh chụp | ≤ `gw.snapshot.maxBytes` |
| CHK-16…18 | `WarningRules` | Phạm vi, hạn chứng thư, số route | Mức `CẢNH BÁO` |

: Quy tắc kiểm tra tĩnh và lớp hiện thực

Khi `gw.snapshot.isolateBadRoute` bật, vi phạm mức `LỖI` chỉ gắn với một route thì bộ kiểm tra loại route đó khỏi bản ghép (đánh dấu `PENDING` kèm lỗi) và kiểm tra lại; vi phạm toàn cục (CHK-01 ở plugin_metadata, CHK-13 ở chứng thư) vẫn từ chối cả ảnh chụp.

### 4.10. Ký, phát và quay lui ảnh chụp

::: dac-ta
**Mục đích.** Đóng cấu hình đã kiểm tra thành ảnh chụp bất biến có số phiên bản tăng đơn điệu và chữ ký; phát tới bucket và Git; cho phép quay lui nhanh mà vẫn giữ phiên bản chỉ tăng.

**Lớp chính.** `SnapshotCounter`, `SnapshotSigner`, `SnapshotPublisher`, `GitCommitter`, `RollbackService`, `HoldService`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-03-041, 042, 044; BR-03-010, 016, 018.

**Giao diện vào.** Ảnh chụp `BUILT` đã qua 4.9; API-03-060, 061, 062, 098 (bỏ giữ sau quay lui, tách khỏi thao tác phát; đã chốt 27/11/2026).

**Phụ thuộc ra.** OpenBao transit (ký); Garage (bucket `dh-platform-gateway`); Git cấu hình (JGit, khóa triển khai ở OpenBao); Kafka (outbox).

**Dữ liệu.** `ConfigSnapshot`; bộ đếm phiên bản của từng site; bảng giữ (`tenant_hold`).

**Sự kiện.** EVT-03-01 (phát), EVT-03-02 (quay lui), EVT-03-12 (từ chối).

**Lỗi và xử lý.** ERR-03-006 (phát chen), 007 (quay lui không hợp lệ), 014 (không ghi được nơi lưu), 015 (không ký được).

**Quan sát.** `dh_gw_cp_snapshot_version{site}`, `dh_gw_cp_publish_duration_seconds{path}`, `dh_gw_cp_sign_failures_total`, `dh_gw_cp_publish_pending`.
:::

Chi tiết thiết kế:

**Cấp phiên bản.** `SnapshotCounter` giữ một dòng mỗi site; cấp số trong giao dịch `SELECT … FOR UPDATE` rồi tăng, bảo đảm không trùng, không lùi, kể cả khi hai bản sao `dh-connect` cùng chạy. Số được cấp ngay trước bước ký (không cấp cho ảnh chụp bị từ chối) nên khoảng trống số chỉ xuất hiện khi ký thất bại sau khi cấp; chấp nhận được vì nút chỉ yêu cầu "lớn hơn" (BR-03-018). Khi chuyển site (DR), site mới bắt đầu từ số lớn nhất đã biết cộng `gw.snapshot.drGap`.

**Ký.** `SnapshotSigner` chuẩn hóa `manifest.json`, tính SHA-256, gọi `transit/sign/dh-gateway-snapshot/sha2-256` của OpenBao (khóa ECDSA P-256 không xuất được, xoay 12 tháng), ghi `manifest.sig`. Khóa công khai của mọi phiên bản khóa còn hiệu lực được đưa vào ConfigMap để `dh-sync` chấp nhận nhiều khóa khi chuyển giao. OpenBao lỗi: ảnh chụp giữ `BUILT`, thử lại theo lũy thừa (1, 2, 4… tới 60 giây, tổng 1 giờ) rồi cảnh báo Cao.

**Phát: thứ tự ghi.** Thứ tự bảo đảm nút không bao giờ đọc bản dở.

1. Ghi `int.yaml`, `ext.yaml`, `shards/*`, `manifest.json`, `manifest.sig` vào `snapshots/{site}/{version}/`.
2. Đọc lại và so băm từng tệp.
3. Ghi con trỏ `snapshots/{site}/current` (một tệp nhỏ có số phiên bản và băm manifest) cuối cùng; điều kiện ghi `If-None-Match` trên đối tượng phiên bản để không ghi đè.
4. Commit vào Git cấu hình thư mục `gateway/{site}/` (một commit cho bản ghép và manifest; không có khóa riêng); Argo CD cập nhật ConfigMap `apisix-config`. Git lỗi thì xếp hàng thử lại tới 1 giờ, cảnh báo Cao, và ảnh chụp mang cờ `gitPending`.
5. Cả bucket và Git đều lỗi: ERR-03-014, ảnh chụp giữ `SIGNED`.
6. Chuyển `PUBLISHED`, ghi outbox EVT-03-01, dọn bucket giữ `gw.snapshot.retain` phiên bản gần nhất.

Ảnh chụp có phiên bản nhỏ hơn bản đã phát của cùng site bị bỏ (ERR-03-006): `SnapshotPublisher` kiểm `version > published(site)` trong cùng giao dịch cập nhật bộ đếm "đã phát".

**Quay lui (FR-03-044).** `RollbackService` làm bảy việc: kiểm quyền (`operate`, và PA cho phạm vi `PLATFORM`); kiểm không có lần phát đang chạy; đọc mảnh tenant của phiên bản đích từ bucket hoặc Git; kiểm các đối tượng tham chiếu của mảnh đó còn hợp lệ (consumer còn, upstream còn, chứng thư chưa hết hạn, ERR-03-007); dựng ảnh chụp **mới** mang nội dung mảnh đích (các tenant khác giữ nguyên), chạy 4.9, ký, phát theo đường ưu tiên (không debounce); đặt `HoldService` cho tenant trong `holdHours` (mặc định 24), trong thời gian giữ `BuildCoordinator` xếp hàng sự kiện chứ không tổng hợp; phát EVT-03-02. "Bỏ giữ" thực hiện một lần tổng hợp từ nguồn hiện tại; hết hạn giữ mà chưa bỏ thì cảnh báo, không tự bỏ.

### 4.11. Bộ đồng bộ nút `dh-sync`

::: dac-ta
**Mục đích.** Đưa ảnh chụp đã ký tới từng pod APISIX một cách nguyên tử, kiểm chứng, chống nạp lùi, và giữ pod chạy được khi mọi nguồn bên ngoài ngừng.

**Lớp chính.** Chương trình Go `dh-sync`: `internal/fetch`, `internal/verify`, `internal/apply`, `internal/relay`, `internal/crl`.

**Đơn vị chạy.** `apisix`: initContainer `dh-sync-init` và sidecar `dh-sync` trong mỗi pod; bản ở `apisix-int` thêm vai trò chuyển tiếp.

**FR hiện thực.** FR-03-043, FR-03-045 (phần phát chỉ số), FR-03-049 (điền chứng thư), FR-03-002 (tải CRL); BR-03-010, 016, 018; NFR-03-007, 008.

**Giao diện vào.** Con trỏ `current` ở bucket (hoặc điểm chuyển tiếp ở Z2); ConfigMap `apisix-config`; Secret chứng thư; `/healthz`, `/metrics` ở cổng 9093.

**Phụ thuộc ra.** Garage (chỉ ở `apisix-int`); điểm chuyển tiếp ở Z2 (từ `apisix-ext`); Kubernetes API (đọc `EndpointSlice`); máy chủ CRL của CA; chỉ số cục bộ của APISIX.

**Dữ liệu.** Thư mục `/run/dh/` (`emptyDir`): `apisix.yaml`, `apisix.prev.yaml`, `state.json`, `crl/`, `replicas`.

**Sự kiện.** Không; trạng thái đi qua chỉ số.

**Lỗi và xử lý.** Chữ ký sai, băm sai, phiên bản không lớn hơn, lược đồ sai, `apisixImage` khác: từ chối, giữ bản đang chạy. Nạp xong nhưng nút không báo đúng phiên bản trong 10 giây: khôi phục `apisix.prev.yaml`.

**Quan sát.** `dh_gateway_config_version`, `dh_gateway_config_applied_timestamp`, `dh_gateway_sync_total{result}` (`ok`, `bad_signature`, `stale`, `invalid`, `reverted`, `fetch_error`), `dh_gateway_sync_duration_seconds`.
:::

Chi tiết thiết kế:

**Vòng lặp của sidecar.** Mỗi `gw.sync.pollSeconds` (5 giây, nhận lệnh đánh thức tức thì từ thông báo ConfigMap đổi):

1. Đọc con trỏ `current`; nếu `version` ≤ `state.lastApplied` thì thôi.
2. Tải `manifest.json`, `manifest.sig` và bản ghép của cửa mình (`int.yaml` hoặc `ext.yaml`).
3. Kiểm chữ ký bằng khóa công khai tin cậy, kiểm băm tệp so với manifest, kiểm `apisixImage` khớp ảnh đang chạy và `version` > `lastApplied`; không đạt thì tăng `sync_total{result}` tương ứng, nếu là chữ ký hoặc băm sai thì phát cảnh báo Nghiêm trọng "nghi cấu hình giả mạo" (GW-A05).
4. Kiểm lược đồ bằng lược đồ JSON đóng gói cùng ảnh.
5. Điền chứng thư và khóa riêng của các `ssls` từ Secret đã gắn vào (chỗ giữ chỗ `{{cert:certCode}}`); khóa riêng không bao giờ ở tệp ảnh chụp.
6. Ghi `apisix.yaml.tmp`, đồng bộ đĩa, đổi tên đè `apisix.yaml` (nguyên tử), giữ bản trước thành `apisix.prev.yaml`.
7. Xác nhận: poll chỉ số cục bộ `dh_gateway_config_version` cho tới khi bằng `version` mới hoặc hết 10 giây. Hết hạn: khôi phục `apisix.prev.yaml`, ghi `result="reverted"`, cảnh báo Cao; bản đó được ghi vào danh sách từ chối để không thử lại vô hạn.
8. Ghi `state.json` (`lastApplied`, băm), cập nhật chỉ số.

`state.json` nằm trên `emptyDir` nên mất khi pod bị lập lịch lại; khi đó `lastApplied` lấy từ ảnh chụp ở bước init, nên chống nạp lùi được bảo đảm trong đời pod và tại thời điểm khởi động, không qua nhiều đời pod (rủi ro ghi ở mục 13.2).

**Khởi động.** initContainer `dh-sync-init` chọn bản có phiên bản lớn nhất trong số hợp lệ (đã ký, đúng băm, đúng `apisixImage`) từ bucket (hoặc điểm chuyển tiếp) và từ ConfigMap `apisix-config`, ghi `apisix.yaml`; không nguồn nào dùng được thì pod không khởi động (Ready sai) thay vì chạy cấu hình rỗng. Đây là đường bảo đảm NFR-03-007: pod bị lập lịch lại khi `dh-connect`, Git, bucket và Keycloak đều ngừng vẫn có cấu hình từ ConfigMap.

**Điểm chuyển tiếp ở Z2.** Ở `apisix-int`, `dh-sync` mở cổng 8443 phục vụ chỉ-đọc `GET /v1/snapshots/current` và các tệp đã xác minh; `AuthorizationPolicy` chỉ cho service account `apisix-ext`. Bên `apisix-ext` coi điểm này như một nguồn ghi bucket và vẫn xác minh chữ ký, nên điểm chuyển tiếp bị chiếm cũng không làm giả được cấu hình, chỉ có thể trì hoãn (Q03-21).

**Việc phụ của sidecar.** Tải CRL của từng CA khách mỗi giờ qua egress gateway (SEC-16, Q03-26), kiểm chữ ký CRL, chuyển thành tập số seri ghi `crl/{ca}.json` để `dh-edge` nạp; đọc `EndpointSlice` ghi `replicas` (cần quyền `get`, `list` ở namespace của mình, Q03-25); xoay vòng tệp `access.log`; phát `/healthz` (sống nếu vòng lặp chạy trong 60 giây gần nhất) và `/metrics`. Cấp tài nguyên: 50 mCPU, 32 MiB.

**Vì sao Go.** Sidecar cần kiểm ECDSA, băm, ghi nguyên tử và phục vụ HTTP với bộ nhớ vài chục MiB trong pod 1 GiB đã nhường cho NGINX và Coraza; JVM không phù hợp, còn Lua trong chính APISIX sẽ gộp lỗi của bộ đồng bộ vào tiến trình phục vụ lượt gọi. Đây là ngôn ngữ thứ hai ngoài Java và Lua trong dự án, cần ADR (Q03-22).

### 4.12. Đường chặn nhanh: thu hồi token và tạm ngừng khẩn cấp

::: dac-ta
**Mục đích.** Cho thu hồi token và tạm ngừng khẩn cấp có hiệu lực trong vài giây, song song với đường ảnh chụp bền, và dựng lại được khi Valkey mất.

**Lớp chính.** `RevocationService`, `KillSwitchService`, `FastKeyFactory`, `ValkeyRebuilder`, `QuotaEventConsumer`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-03-018, 047; FR-03-004 (chặn IP tay đi đường bền), FR-03-026 (dựng lại khi Valkey về); BR-03-021, 025.

**Giao diện vào.** API-03-053 (`gateway:revoke`), API-03-017…020 (`operate`). Đã chốt 27/11/2026: đường đẩy này là đường nhanh; plugin `dh-authz` ở mỗi nút kéo thêm API-12-079 của PH-12 mỗi 10 giây kèm `X-DH-Applied-Version`, xử lý `blockAll`, làm đường bù khi mất đẩy, và dùng chung bộ fixture quyết định của PH-12.

**Phụ thuộc ra.** Valkey; `pg-core`; `BuildCoordinator` (đường bền).

**Dữ liệu.** `revoked_token` (dựng lại Valkey), `EmergencyBlock` (EN-03-12).

**Sự kiện.** EVT-03-03, EVT-03-04, EVT-03-09 (khi tạm ngừng).

**Lỗi và xử lý.** ERR-03-019 (đối tượng đã tạm ngừng), 001 (không thấy), 022 (thiếu scope). Valkey lỗi khi ghi: ghi cơ sở và đường bền, trả `202` kèm "áp dụng qua ảnh chụp, dự kiến ≤ 60 giây".

**Quan sát.** `dh_gw_cp_fastblock_write_total{kind,result}`, `dh_gw_cp_valkey_rebuild_total`, `dh_gw_cp_fastblock_effective_seconds`.
:::

Chi tiết thiết kế:

**Thu hồi token.** `RevocationService.revoke` kiểm scope `gateway:revoke`, tenant lấy từ token dịch vụ, rồi trong một giao dịch ghi `revoked_token` (để dựng lại) và outbox kiểm toán; ngay sau giao dịch ghi khóa `FastKeys.revokedJti` hoặc `revokedSub` vào Valkey với TTL bằng thời gian sống còn lại của token cộng 60 giây; trả `202` `{revocationId, effectiveBy}` với `effectiveBy` bằng bây giờ cộng 15 giây (gọi API dưới 5 giây cộng bộ đệm 5 giây của plugin, dư dự phòng). Thu hồi theo `sub` đặt `notBefore = now` nên token mới sau khi xoay khóa client dùng lại được.

**Tạm ngừng khẩn cấp.** `KillSwitchService.suspend` là đường kép: (a) ghi `EmergencyBlock` `ACTIVE` và khóa `FastKeys.kill*` vào Valkey; (b) kích hoạt tổng hợp tức thì cho tenant (không debounce) để ảnh chụp mới đặt đối tượng ở `SUSPENDED` và cho `dh-kill-switch` chế độ `static` chạy. Đường (a) đạt trong tối đa 30 giây (bộ đệm 5 giây cộng dư), đường (b) là bản bền phòng khi Valkey mất. Mở lại xóa khóa, ghi `liftedAt`, và sinh ảnh chụp mới; cả hai chiều kiểm toán và phát sự kiện. Sau 4 giờ chưa mở lại, hệ thống nhắc SO và TA (đề xuất ở Q03-46 của UC).

**Dựng lại khi Valkey mất.** `ValkeyRebuilder` thăm dò `PING` mỗi 10 giây; khi chuyển từ mất sang lên, nó nạp lại mọi `revoked_token` chưa hết hạn và mọi `EmergencyBlock` đang `ACTIVE` bằng `SET` idempotent, rồi một lần quét đối chiếu (so tập khóa kỳ vọng với `SCAN` tiền tố `{T}:revoked:*`, `{T}:kill:*`) để xóa khóa mồ côi. Trong thời gian Valkey mất, chặn mới vẫn có hiệu lực qua đường bền (tạm ngừng) hoặc chờ Valkey về hoặc token hết hạn tối đa 5 phút (thu hồi, FRS FR-03-018 luồng ngoại lệ).

**Tiêu thụ sự kiện từ data plane.** `QuotaEventConsumer` là nhóm tiêu thụ `XREADGROUP` trên `{T}:evt:quota` cho mọi tenant đang hoạt động; mỗi mục ghi outbox EVT-03-07 trong một giao dịch rồi `XACK`; mục không xử lý được 5 lần chuyển sang danh sách chết `{T}:evt:quota:dead` kèm cảnh báo.

### 4.13. Đồng bộ consumer

::: dac-ta
**Mục đích.** Nhận từ PH-01 và PH-02 phần công khai của danh tính HTTT (không bao giờ bí mật), lưu, kích hoạt tổng hợp, và cho saga biết khi nào mọi nút đã nạp.

**Lớp chính.** `ConsumerSyncService`, `CredentialPublicStore`, `SecretFieldGuard`, `GatewaySyncStatusApi` (hiện thực).

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-03-046; BR-03-022, BR-03-021.

**Giao diện vào.** API-03-013, 014, 015 (`gateway:sync`); API-03-011, 012, 016 (đọc).

**Phụ thuộc ra.** `pg-core`; `BuildCoordinator`; module `catalog` (kiểm đăng ký còn hiệu lực khi xóa).

**Dữ liệu.** EN-03-03, EN-03-04, bảng khóa lũy đẳng (`Idempotency-Key`, giữ 24 giờ).

**Sự kiện.** EVT-03-04.

**Lỗi và xử lý.** ERR-03-002 (mã thuộc HTTT khác), 003 (trường bí mật hoặc sai dạng), 017 (còn đăng ký hiệu lực khi xóa), 022 (thiếu scope).

**Quan sát.** `dh_gw_cp_consumer_sync_total{op,result}`, `dh_gw_cp_consumer_sync_lag_seconds`.
:::

Chi tiết thiết kế:

**Lũy đẳng.** Mọi lệnh ghi consumer mang `Idempotency-Key`; `ConsumerSyncService` lưu khóa cùng băm của thân và phản hồi 24 giờ, gọi lại cùng khóa cùng thân trả đúng phản hồi cũ, cùng khóa khác thân trả ERR-03-003. Saga của PH-01 có thể thử lại bước "tạo consumer" mà không sinh bản sao.

**Không nhận bí mật.** `SecretFieldGuard` là bộ lọc `@RestControllerAdvice` chạy trước dịch vụ: từ chối thân có khóa JSON thuộc danh sách (`privateKey`, `clientSecret`, `secret`, `apiKey` dạng rõ), có chuỗi PEM `PRIVATE KEY`, hoặc có chuỗi base64 dài không đúng dạng băm 64 ký tự hex ở trường `apiKeyHash`. Nó ghi cảnh báo ATTT (không ghi giá trị) và trả ERR-03-003.

**Tính `syncState`.** Mỗi lần ghi consumer tăng `consumerVersion`; `NodeStateEvaluator` (4.16) biết nút nào chạy phiên bản ảnh chụp nào; `GatewaySyncStatusApi.consumerStatus` so phiên bản ảnh chụp đầu tiên có chứa `consumerVersion` đó (`builtFrom`) với `runningVersion` của mọi nút của cả hai cửa: `IN_SYNC` khi mọi nút ≥, `PARTIAL` khi một phần, `PENDING` khi chưa có ảnh chụp chứa nó, `FAILED` khi ảnh chụp chứa nó bị `REJECTED`. Saga theo dõi tới `IN_SYNC`; mục tiêu ≤ 10 giây (tiêu chí chấp nhận 9).

**Xóa và tạm ngừng.** Xóa kiểm `catalog.api` xem còn đăng ký hiệu lực (ERR-03-017); xóa mềm và giữ mã không dùng lại (BR-03-029). Tạm ngừng HTTT ở PH-01 gọi `PUT` với `state = SUSPENDED` cho mọi consumer của HTTT (BR-03-022); ngoài ra đường tạm ngừng khẩn cấp ở 4.12 cho hiệu lực nhanh hơn. Xoay chứng thư: nhận tối đa 2 vân tay cùng lúc; vân tay thứ ba bị từ chối.

### 4.14. Yêu cầu thay đổi bốn mắt, WAF và hạn mức

::: dac-ta
**Mục đích.** Đặt các thay đổi rủi ro cao của PH-03 sau cổng hai người, quản lý ngoại lệ và luật vá của WAF, hạn mức toàn tenant và ghi đè, đồng thời kích hoạt việc hết hạn đúng giờ.

**Lớp chính.** `ChangeRequestService`, `FourEyesGuard`, `ChangeHandlerRegistry`, `WafModeService`, `WafExceptionService`, `VirtualPatchService`, `TenantLimitService`, `OverrideService`, `ExpiryScheduler`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-03-005…008, 021…025, 056 (phần hạn mức); BR-03-006, 019.

**Giao diện vào.** API-03-039…049 (WAF), 097 (thử khô luật vá ảo, đã chốt 27/11/2026), 023…028 (hạn mức), 071…073 (yêu cầu thay đổi).

**Phụ thuộc ra.** `pg-core`; Hộp việc chung (`TaskInboxApi`); PH-20 (trần hợp đồng); `BuildCoordinator`.

**Dữ liệu.** EN-03-06, 07, 08, 15.

**Sự kiện.** EVT-03-05, 06 (ngoại lệ), EVT-03-11 (hạn mức), EVT-03-01 qua tổng hợp.

**Lỗi và xử lý.** ERR-03-008 (tự duyệt), 009 (ngoại lệ sai), 010 (trùng), 018 (vượt trần), 027 (chưa đủ 14 ngày phát hiện), 022.

**Quan sát.** `dh_gw_cp_change_requests{type,state}`, `dh_gw_cp_waf_exception_active`, `dh_gw_cp_expiry_jobs_total{kind}`.
:::

Chi tiết thiết kế:

**Bốn mắt theo tài khoản.** `FourEyesGuard.check(requestedBy, decidedBy)` so **tài khoản** (subject của token), không so vai trò, nên một người giữ hai vai trò vẫn không tự duyệt (BR-03-019, Q03-47 của UC). Người duyệt phải có quyền đúng loại: `waf-approve` cho ngoại lệ, `approve` cho đổi chế độ WAF, mở cửa ngoài, hạ hạn mức tenant. Ở tenant nhỏ chỉ có một SO, cấu hình `gw.approval.substitute` (mặc định tắt) cho PA duyệt thay, kiểm toán ghi "duyệt thay" (Q03-02 của FRS).

**`ChangeRequest` và bộ xử lý.** Ba loại do `ChangeRequestService` quản lý (`WAF_MODE`, `ROUTE_EXPOSURE_EXT`, `TENANT_LIMIT_DECREASE`); ngoại lệ và luật vá WAF có máy trạng thái riêng ở mục 8.1 nhưng dùng cùng `FourEyesGuard`. Khi duyệt, `ChangeHandlerRegistry` gọi bộ xử lý của loại (đổi chế độ, đổi `exposure`, đặt hạn mức), mỗi bộ xử lý ghi thay đổi, ghi outbox rồi kích hoạt tổng hợp; thay đổi không đi vào cấu hình đang chạy cho tới khi ảnh chụp mới được nạp. Yêu cầu đưa vào Hộp việc của người có quyền duyệt (FR-00-070).

**Đổi chế độ WAF (FR-03-006).** `WafModeService` kiểm điều kiện 14 ngày: đếm ngày liên tục ở `DETECT` của phạm vi (cột `detect_since`) và số cảnh báo giả chưa xử lý (sự kiện `DETECT` chưa gắn ngoại lệ hoặc đánh dấu "đúng") nhỏ hơn `gw.waf.fpReviewMax`; chưa đạt: ERR-03-027. Hạ về `DETECT` do sự cố cần cũng bốn mắt nhưng đánh dấu khẩn. Tự hạ ở nút (4.2) không đi qua dịch vụ này và không đổi cấu hình lưu.

**Ngoại lệ WAF (FR-03-007).** `WafExceptionService.request` kiểm lý do, mã luật tồn tại trong CRS đang dùng, `expiresAt` ≤ `gw.waf.exception.maxDays`, không trùng (ERR-03-009, 010); `approve` kiểm `FourEyesGuard`, chuyển `ACTIVE`, kích hoạt tổng hợp. `ExpiryScheduler` chuyển `ACTIVE` sang `EXPIRING` khi còn `gw.waf.exception.warnDays` (phát EVT-03-06) và sang `EXPIRED` khi hết hạn, rồi kích hoạt tổng hợp để gỡ ngoại lệ khỏi ảnh chụp.

**Hạn mức (FR-03-023, 024).** `TenantLimitService` kiểm giá trị trong miền cho phép và dưới trần hợp đồng của PH-20 (ERR-03-018); tăng hạn mức áp ngay, hạ thấp hơn mặc định hoặc hạ hạn mức đang chạy cần `ChangeRequest`. `OverrideService` lưu ghi đè theo phạm vi `CONSUMER`, `CONSUMER_ROUTE`, `ROUTE`, `TENANT`; bộ giải thứ tự ưu tiên ở mục 4.4 dùng chúng.

**Mọi thứ có hạn.** Một bộ lập lịch duy nhất (`ExpiryScheduler`, ShedLock, chạy mỗi phút) quét các mốc: hết hạn ngoại lệ và luật vá WAF, ngoại lệ TLS 1.2 (≤ 180 ngày), đăng ký sử dụng (`until`), chuyển tiếp tenant sáp nhập (`endAt`), giữ sau quay lui, chứng thư cảnh báo 30 và 7 ngày. Mỗi lần quét gom các mục đến hạn theo tenant rồi kích hoạt đúng một lần tổng hợp cho mỗi tenant, nên 100 ngoại lệ cùng hết hạn lúc nửa đêm không gây 100 ảnh chụp.

### 4.15. Cửa vào, chứng thư biên, trạng thái route và sáp nhập

::: dac-ta
**Mục đích.** Quản lý phần cấu hình hạ tầng biên (hồ sơ TLS, ngoại lệ TLS 1.2, chứng thư, bộ CA khách, địa chỉ bị chặn, cửa vào của route) và vòng đời thực thi của route (dừng, mở, `SUNSET`, chuyển tiếp tenant sáp nhập).

**Lớp chính.** `TlsProfileService`, `TlsExceptionService`, `CertificateService`, `ClientCaBundleService`, `IpBlockService`, `RouteStateService`, `ExposureService`, `SunsetService`, `TenantRedirectService`.

**Đơn vị chạy.** `dh-connect`.

**FR hiện thực.** FR-03-001, 002, 004, 035…038, 049.

**Giao diện vào.** API-03-003, 004, 008, 031…038, 068…070, 094…096.

**Phụ thuộc ra.** cert-manager (đọc tài nguyên `Certificate`, quyền chỉ đọc); OpenBao PKI; PH-20 (trạng thái `MERGED`, bảng ánh xạ); `ChangeRequestService`; `BuildCoordinator`.

**Dữ liệu.** EN-03-01, 11, 13, 14; ngoại lệ TLS.

**Sự kiện.** EVT-03-03, EVT-03-08, EVT-03-10.

**Lỗi và xử lý.** ERR-03-011 (chưa đủ điều kiện ra Internet), 016 (chứng thư sai), 019, 023 (route không ở trạng thái cho phép), 024 (không được chặn địa chỉ tin cậy), 025 (chuyển tiếp xung đột), 015.

**Quan sát.** `dh_gw_cp_cert_days_remaining{cert}`, `dh_gw_cp_route_state{state}`, `dh_gw_cp_redirect_active`.
:::

Chi tiết thiết kế:

**Chứng thư biên.** `CertificateService` không cấp chứng thư; nó đọc tài nguyên `Certificate` của cert-manager (quyền chỉ đọc) mỗi giờ, đối chiếu với host đang dùng trong ảnh chụp, tính ngày còn lại, phát EVT-03-08 ở 30 ngày (Cao) và 7 ngày (Nghiêm trọng), và để CHK-13 chặn ảnh chụp mới chứa host còn dưới 7 ngày. Chứng thư do PA nhập tay đi qua `CertificateService.import`: kiểm chuỗi tới CA cho phép, hạn, khớp khóa riêng và host trước khi ghi khóa riêng thẳng vào OpenBao (không qua bảng, không qua log) rồi để External Secrets đưa vào Secret; thất bại trả ERR-03-016. Gia hạn thủ công tạo `CertificateRequest` qua yêu cầu tới cert-manager và trả ERR-03-019 nếu đã có yêu cầu đang chạy.

**Địa chỉ bị chặn.** `IpBlockService` lưu danh sách chặn tay (EN-03-14) và đưa vào `plugin_metadata` của `dh-ip-block` ở ảnh chụp; từ chối chặn địa chỉ thuộc `trustedCidrs` hoặc dải hạ tầng của nền tảng (ERR-03-024).

**Dừng, mở, `SUNSET`.** `RouteStateService.stop` kiểm route ở `ACTIVE`, đặt `STOPPED`, ghi outbox EVT-03-03 và kích hoạt tổng hợp ưu tiên; ảnh chụp mới render route ở chế độ `static` của `dh-kill-switch` (ERR-03-123, `Retry-After`). Mở lại là chiều ngược. `SunsetService` đặt `SUNSET` ở `sunsetAt` qua `ExpiryScheduler` và `RETIRED` sau `gw.sunset.retainDays`. Lệnh khi route không ở trạng thái cho phép trả ERR-03-023.

**Cửa vào.** `ExposureService` thực hiện hai chiều bất đối xứng: `INT` sang `EXT` đi qua `ChangeRequest` (kiểm ERR-03-011: lược đồ, chính sách OPA, xác thực bắt buộc, WAF `BLOCK` ở PROD); `EXT` về `INT` có hiệu lực ngay, không cần duyệt (giảm bề mặt). `ipAllowCidrs` của route `EXT` đi vào cấu hình `dh-ip-block` của chính route đó ở `apisix-ext`.

**Chuyển tiếp tenant sáp nhập.** `TenantRedirectService.create` kiểm tenant nguồn `MERGED`, tenant đích `ACTIVE`, route đích tồn tại và chưa có chuyển tiếp đang chạy (ERR-03-025); `TenantShardRenderer` thêm route trên host nguồn với nhãn tenant là tenant đích; `dh-auth` vì thế từ chối token tenant nguồn bằng ERR-03-106 kèm hướng dẫn nhận thông tin xác thực mới, còn token tenant đích đi qua. Mỗi tuần một tác vụ thống kê consumer còn gọi host cũ từ ClickHouse và gửi đầu mối. Tới `endAt` chuyển tiếp kết thúc, host nguồn trả ERR-03-126 qua `dh-kill-switch` chế độ `static`.

### 4.16. Quan sát, nút, chạy thử, nhập hệ cũ và tham số

::: dac-ta
**Mục đích.** Cho vận hành và kiểm toán thấy được tình trạng gateway (nút, lưu lượng, nhật ký, cảnh báo), chạy thử chính sách, nhập cấu hình từ gateway cũ, và chỉnh tham số theo tenant.

**Lớp chính.** `NodeStateEvaluator`, `AccessLogQueryService`, `OverviewService`, `UsageReportService`, `SyntheticCheckService`, `SecurityAlertService`, `PolicySimulator`, `LegacyGatewayImporter`, `GatewayParameterService`.

**Đơn vị chạy.** `dh-connect`; bộ chạy kiểm tra tổng hợp ở `dh-runtime`.

**FR hiện thực.** FR-03-045, 051, 053…059.

**Giao diện vào.** API-03-056, 063, 064, 074…093. Đã chốt 27/11/2026: API-03-074 (và API-03-039) dùng phân trang con trỏ `cursor`, `limit`, `approxTotal` vì đọc từ ClickHouse (Q03-56). Khi PH-18 chốt Q18-25, PH-03 thêm tuyến bóng (mẫu `tpl-migration-shadow`) và API đổi trọng số tuyến đồng bộ có xác nhận cho cắt chuyển, quay lui di trú; API nhập riêng ở đây (API-03-091…093) giữ nguyên, khi PH-18 chốt khung API nhập chung thì nhận thêm `X-Datahub-Migration: true` và khóa lũy đẳng `legacySystem:objectType:legacyKey`.

**Phụ thuộc ra.** PH-13 (Mimir, ClickHouse, Alertmanager); `catalog.api` (API quan trọng); `pg-core`.

**Dữ liệu.** Kiểm tra tổng hợp, yêu cầu nhập, tham số; không giữ bản sao nhật ký (đọc từ ClickHouse).

**Sự kiện.** EVT-03-09 (cảnh báo), EVT-03-11 (tham số hạn mức).

**Lỗi và xử lý.** ERR-03-020 (gói nhập hỏng), 021 (khoảng thời gian quá lớn), 026 (PH-13 không trả số liệu), 003, 018.

**Quan sát.** `dh_gw_cp_node_sync_state{state}`, `dh_gw_cp_logquery_duration_seconds`, `dh_gw_cp_simulation_total{result}`.
:::

Chi tiết thiết kế:

**Trạng thái nút.** `NodeStateEvaluator` truy vấn Mimir mỗi 30 giây lấy `dh_gateway_config_version` và các chỉ số của từng pod theo `gate` và `site`, so với `desiredVersion` (ảnh chụp `PUBLISHED` mới nhất của site), gán `syncState`: `IN_SYNC`, `LAGGING` (lệch quá `gw.node.lagSeconds`), `FAILED` (nạp lỗi lần gần nhất, theo `dh_gateway_sync_total`), `UNKNOWN` (không số liệu quá `gw.node.unknownSeconds`). Ảnh chụp `APPLIED` khi mọi nút `IN_SYNC`, `PARTIAL` khi còn nút `LAGGING`. Trạng thái nút là chỉ số suy ra, không lưu bảng; PH-13 không trả lời thì màn hình hiển thị "không có số liệu" (ERR-03-026), không hiển thị số 0.

**Nhật ký lượt gọi (FR-03-051).** `AccessLogQueryService` dựng truy vấn ClickHouse có tham số (không ghép chuỗi), luôn thêm điều kiện `tenant = ?` từ token, giới hạn khoảng thời gian ≤ 31 ngày và trong 12 tháng (ERR-03-021), phân trang con trỏ; xuất tệp là tác vụ nền giới hạn `gw.accessLog.export.maxRows`. Cột `srcIp` chỉ trả cho người có `log-read` (Q03-48 của UC về che octet cuối).

**Kiểm tra tổng hợp (FR-03-053).** `SyntheticCheckService` lưu cấu hình và phát tới bộ chạy ở `dh-runtime` qua ảnh chụp riêng (không cùng ảnh chụp gateway, để bộ chạy không phụ thuộc `dh-connect` khi chạy); bộ chạy dùng consumer `dh-synthetic-{tenant}`, gói riêng, gọi qua địa chỉ thật của cửa vào, ghi `dh_gateway_synthetic_up`, `dh_gateway_synthetic_duration_seconds`. Lượt gọi mang tiêu đề đánh dấu để `dh-limit` không tính vào hạn mức của HTTT thật và báo cáo loại chúng (BR-03-027).

**Chạy thử chính sách (FR-03-057).** `PolicySimulator` không gọi gateway thật: nó dựng mô hình cấu hình hiện hành trong bộ nhớ và chạy lại thuật toán của từng chốt (so khớp route, kiểm tra phạm vi, so khớp đường dẫn, ước lượng hạn mức bằng bộ đếm tổng hợp riêng) cho một yêu cầu giả, trả `{route, quyết định từng chốt, mã lỗi sẽ trả}` mà không tăng bộ đếm thật (BR-03-027). Giới hạn: không mô phỏng WAF (chỉ liệt kê luật có thể khớp) và không gọi OPA thật (gọi OPA cục bộ với đầu vào giả nếu bật).

**Nhập hệ cũ (FR-03-059).** `LegacyGatewayImporter` đọc gói JSON xuất từ gateway cũ (Q03-49 của UC), phân tích bằng `LegacyBundleScanner` (chỉ đọc dữ liệu, không thực thi, từ chối trường chứa bí mật), ánh xạ API, plan, application, subscription sang cấu hình nháp (không phát), và báo cáo mục không ánh xạ được; áp dụng nháp là thao tác riêng (`:apply`) tạo dữ liệu nguồn ở PH-02, PH-01 chứ không ghi thẳng vào ảnh chụp.

**Tham số (FR-03-056).** `GatewayParameterService` lưu khóa `gw.*` với miền, mặc định, trần hợp đồng ở bảng mô tả tham số (nạp từ tài liệu FRS mục 8.2 thành dữ liệu), kiểm giá trị (ERR-03-003, 018), kiểm toán thay đổi, phát EVT-03-11 khi tham số hạn mức đổi, và kích hoạt tổng hợp; các tham số có bốn mắt (`gw.waf.mode`, `gw.tenantRateLimit.perSecond` khi hạ) không sửa được ở đây mà đi qua `ChangeRequest`.

## 5. Biểu đồ tuần tự

Mười một biểu đồ dưới đây phủ các FR có nhiều thành phần cùng tham gia, có tác vụ nền hoặc có duyệt bốn mắt. Năm biểu đồ đầu thuộc mặt phẳng dữ liệu (đường đi của một lượt gọi), sáu biểu đồ sau thuộc mặt phẳng điều khiển và nút.

### 5.1. Lượt gọi từ Internet qua hai chặng (FR-03-001…031, UC-03-01, 03, 05)

```{.mermaid caption="Lượt gọi từ Internet qua apisix-ext và apisix-int tới backend (FR-03-001…031)"}
sequenceDiagram
  autonumber
  actor H as HTTT bên ngoài
  participant EX as apisix-ext
  participant IN as apisix-int
  participant VK as Valkey
  participant OP as OPA sidecar
  participant BE as Backend
  participant OB as PH-13
  H->>EX: TLS 1.3, HTTPS, Bearer token, traceparent
  EX->>EX: dh-edge xóa X-DH-*, kiểm host, vân tay chứng thư
  EX->>EX: dh-ip-block đếm kết nối và tốc độ, Coraza quét
  alt Vi phạm ở biên
    EX-->>H: 403 ERR-03-109 hoặc 429 ERR-03-119, thân RFC 9457
  end
  EX->>IN: Cổng 8444, mesh mTLS, X-DH-Edge-Src-Ip và Cert-Sha256
  IN->>IN: dh-edge tin tiêu đề chặng, dh-auth kiểm JWT cục bộ
  IN->>IN: Tenant khớp realm và route, đăng ký, phạm vi, dh-revocation, dh-kill-switch
  IN->>VK: Một lượt EVALSHA hạn mức ba tầng
  VK-->>IN: Còn hạn mức, remaining
  IN->>IN: request-validation theo lược đồ OpenAPI
  IN->>OP: Hỏi quyết định, tối đa 50 ms
  OP-->>IN: allow
  IN->>BE: Chuyển tiếp qua mesh, traceparent, X-DH-Tenant
  BE-->>IN: Phản hồi
  IN-->>EX: Phản hồi
  EX-->>H: Phản hồi kèm X-Trace-Id, X-RateLimit-*
  IN-)OB: Siêu dữ liệu lượt gọi, chỉ số, vết, không có nội dung
```

Biểu đồ cho thấy điểm dừng sớm nhất ở biên (bước 4) loại lưu lượng xấu trước khi tốn bước mật mã ở `apisix-int`, và rằng mọi quyết định ở `apisix-int` dùng dữ liệu đã nạp sẵn hoặc một lượt gọi Valkey, không gọi `dh-connect`. Lượt gọi từ mạng TSLCD bỏ chặng `apisix-ext`: vào thẳng cổng 443 của `apisix-int`, nơi `dh-edge` chạy đủ chốt 1 đến 6 trước `dh-auth`. Mọi nhánh từ chối còn lại (ở `dh-auth`, `dh-limit`, OPA, backend) trả thân RFC 9457 qua `dh-problem`.

### 5.2. Xác minh JWT, tenant và ràng buộc chứng thư (FR-03-012…014, UC-03-02, 03)

```{.mermaid caption="Xác minh JWT, đối chiếu tenant và ràng buộc chứng thư ở dh-auth (FR-03-012…014)"}
sequenceDiagram
  autonumber
  actor H as HTTT dùng mTLS
  participant AX as apisix-int dh-edge và dh-auth
  participant SD as dh_jwks và dh_crl
  participant KC as Keycloak realm dh-t68
  participant SE as Sự kiện an ninh
  H->>AX: mTLS, Bearer token kid k2, cnf x5t S256
  AX->>SD: Tra số seri chứng thư trong CRL
  SD-->>AX: Không bị thu hồi, CRL còn mới
  AX->>AX: Vân tay SHA-256 của chứng thư kết nối
  AX->>SD: Tìm khóa k2 theo realm của iss
  SD-->>AX: Chưa có
  AX->>KC: Làm mới JWKS, tối thiểu cách nhau 30 giây
  KC-->>AX: JWKS có k1 và k2
  AX->>AX: Kiểm chữ ký ES256, iss, aud, exp, nbf
  AX->>AX: tenant của token khớp realm và tenant route
  AX->>AX: cnf khớp vân tay kết nối và vân tay đã đăng ký
  alt Lệch tenant hoặc lệch vân tay
    AX-)SE: EVT-03-09 chéo tenant hoặc token bị đánh cắp, không ghi token
    AX-->>H: 401 ERR-03-106 hoặc 403 ERR-03-108
  end
  AX->>AX: Đăng ký, phạm vi, đặt X-DH-Tenant X-DH-Client X-DH-Consumer
```

Hình cho thấy ba lớp độc lập cùng phải đạt: chuỗi và CRL của chứng thư, chữ ký và tenant của token, và ràng buộc giữa hai thứ. Làm mới JWKS chỉ xảy ra khi gặp `kid` lạ và bị giới hạn tần suất, nên kẻ gửi token có `kid` ngẫu nhiên không biến gateway thành công cụ tấn công Keycloak (FR-03-012 bước 3). Bước kiểm CRL đứng trước mọi bước mật mã token vì rẻ và loại sớm chứng thư đã thu hồi.

### 5.3. Hạn mức ba tầng và suy giảm khi Valkey mất (FR-03-021…026, UC-03-04, 08)

```{.mermaid caption="Hạn mức ba tầng một lượt Valkey và suy giảm có kiểm soát (FR-03-021…026)"}
sequenceDiagram
  autonumber
  actor H as HTTT gọi
  participant DL as dh-limit
  participant VK as Valkey
  participant LC as dh_limit_local
  participant PM as Prometheus và PH-13
  H->>DL: Yêu cầu đã qua dh-auth, consumer ht-qlvb
  DL->>VK: EVALSHA tenant, giây, phút, giờ, ngày, tháng
  alt Còn hạn mức
    VK-->>DL: allowed, remaining, reset, warnLevel
    DL-->>H: Chuyển tiếp, X-RateLimit-* của giới hạn chặt nhất
  else Vượt một tầng
    VK-->>DL: denied, tầng RATE hoặc QUOTA hoặc TENANT, resetAt
    DL-->>H: 429 ERR-03-116 hoặc 117 hoặc 118, Retry-After
  end
  Note over DL,VK: Valkey chậm quá 50 ms hoặc lỗi
  DL->>LC: Đếm cục bộ, giới hạn chia số bản sao
  LC-->>DL: Cho qua hoặc từ chối cục bộ
  DL-->>H: Phản hồi kèm X-RateLimit-Degraded true
  DL-)PM: dh_gateway_valkey_up bằng 0, cảnh báo Nghiêm trọng
  Note over DL,VK: Sau 5 giây thăm dò lại, Valkey về thì thoát suy giảm
```

Hình cho thấy cả ba tầng được quyết trong một lượt Valkey nên chi phí cố định, và nhánh suy giảm không chờ thêm cho các lượt sau (ngắt mạch 5 giây). Khi suy giảm, hạn ngạch dài hạn mở có cảnh báo còn tần suất và hạn mức tenant vẫn được giữ gần đúng theo số bản sao; sai lệch chấp nhận được và có hiệu lực ngay trong tiêu đề phản hồi để bên gọi và vận hành biết.

### 5.4. Tổng hợp, kiểm tra, ký và phát cấu hình (FR-03-039…042, UC-03-19)

```{.mermaid caption="Tổng hợp, kiểm tra, ký và phát ảnh chụp cấu hình (FR-03-039…042)"}
sequenceDiagram
  autonumber
  participant P2 as PH-02, PH-01
  participant BC as BuildCoordinator
  participant AS as Assembler và Validator
  participant OB as OpenBao transit
  participant BK as Garage dh-platform-gateway
  participant GT as Git và Argo CD
  participant OX as Outbox và Kafka
  P2-)BC: Sự kiện API công bố, gói, đăng ký, consumer
  BC->>BC: Gom 3 giây, khóa theo site và tenant
  BC->>AS: Đọc nguồn, dựng mảnh tenant, ghép với mảnh khác và COMMON
  AS->>AS: CHK-01 đến CHK-18, ApisixSchemaChecker
  alt Có lỗi mức LỖI
    AS-)OX: EVT-03-12 snapshot.rejected kèm danh sách lỗi
    BC->>BC: ảnh chụp REJECTED, cấu hình đang chạy không đổi
  end
  BC->>BC: Cấp phiên bản trong giao dịch FOR UPDATE
  BC->>OB: Ký băm manifest, ECDSA P-256
  OB-->>BC: Chữ ký
  BC->>BK: Ghi tệp bản ghép và manifest, rồi con trỏ current
  BC->>GT: Commit gateway/site, Argo CD cập nhật ConfigMap
  BC-)OX: EVT-03-01 snapshot.published
```

Hình cho thấy thứ tự ghi bảo đảm nút không đọc bản dở: con trỏ `current` ghi sau cùng. Ảnh chụp bị từ chối không tiêu thụ số phiên bản và không đụng gateway. Đường Git chậm hơn bucket và chỉ là đường dự phòng cộng lịch sử; nếu Git lỗi, ảnh chụp vẫn `PUBLISHED` với cờ `gitPending` và cảnh báo.

### 5.5. Nút nạp ảnh chụp và hoàn nguyên khi nạp lỗi (FR-03-043, UC-03-20)

```{.mermaid caption="dh-sync nạp ảnh chụp, xác nhận và hoàn nguyên khi nạp lỗi (FR-03-043)"}
sequenceDiagram
  autonumber
  participant SY as dh-sync
  participant BK as Bucket hoặc điểm chuyển tiếp
  participant FS as /run/dh/apisix.yaml
  participant AX as APISIX
  participant PM as Prometheus
  SY->>BK: Đọc con trỏ current, mỗi 5 giây
  BK-->>SY: version 48213
  SY->>BK: Tải manifest, chữ ký, bản ghép của cửa mình
  SY->>SY: Kiểm chữ ký, băm, apisixImage, version lớn hơn lastApplied, lược đồ
  alt Chữ ký, băm hoặc phiên bản sai
    SY-)PM: sync_total bad_signature hoặc stale, cảnh báo nếu nghi giả mạo
  end
  SY->>SY: Điền chứng thư và khóa riêng từ Secret vào chỗ giữ chỗ
  SY->>FS: Ghi tmp rồi đổi tên đè nguyên tử, giữ bản trước
  AX->>FS: Phát hiện tệp đổi, nạp lại không mất kết nối
  SY->>AX: Poll dh_gateway_config_version cục bộ, tối đa 10 giây
  alt Nút báo đúng version
    SY-)PM: sync_total ok, config_applied_timestamp
  else Quá 10 giây không đúng
    SY->>FS: Khôi phục apisix.prev.yaml
    SY-)PM: sync_total reverted, cảnh báo Cao
  end
```

Hình cho thấy nút chỉ coi việc nạp là xong sau khi chính APISIX xác nhận phiên bản mới, và có đường quay về bản trước một cách tự động; vì vậy cấu hình có lỗi mà bộ kiểm tra không bắt được chỉ làm hỏng cho tới hạn 10 giây trên từng nút, không làm hỏng cả cụm. Bản bị hoàn nguyên được nhớ để không thử lại liên tục, và `FR-03-045` hiển thị nút ở trạng thái `FAILED`.

### 5.6. Thu hồi token và tạm ngừng khẩn cấp qua hai đường (FR-03-018, 047, UC-03-10, 11)

```{.mermaid caption="Thu hồi token và tạm ngừng khẩn cấp qua đường nhanh và đường bền (FR-03-018, 047)"}
sequenceDiagram
  autonumber
  participant P12 as PH-12 hoặc Vận hành
  participant CP as dh-connect fastblock
  participant DB as ph03_gateway
  participant VK as Valkey
  participant BC as BuildCoordinator
  participant AX as apisix-int
  actor H as HTTT bị chặn
  P12->>CP: POST revocations hoặc consumers suspend, lý do
  CP->>DB: Ghi revoked_token hoặc EmergencyBlock, outbox kiểm toán
  CP->>VK: Ghi khóa revoked hoặc kill, TTL
  CP-->>P12: 202 effectiveBy
  CP->>BC: Tổng hợp tức thì, đối tượng SUSPENDED
  H->>AX: Gọi API bằng token cũ hoặc consumer bị tạm ngừng
  AX->>VK: Tra khóa chặn qua bộ đệm 5 giây
  VK-->>AX: Có khóa
  AX-->>H: 401 ERR-03-105 hoặc 403 ERR-03-127 hoặc 503 ERR-03-123
  BC-)AX: Ảnh chụp mới có SUSPENDED, chế độ static của dh-kill-switch
```

Hình cho thấy hai đường cùng chạy: đường nhanh có hiệu lực trong vài giây nhờ khóa Valkey, đường bền đưa trạng thái `SUSPENDED` vào ảnh chụp để không phụ thuộc Valkey và để chặn tồn tại sau khi khóa hết hạn hoặc Valkey được dựng lại. Với thu hồi token, đường bền là bản ghi `revoked_token` để `ValkeyRebuilder` nạp lại; token chỉ sống tối đa 5 phút nên không cần đưa vào ảnh chụp.

### 5.7. Saga kết nạp HTTT tạo consumer ở gateway (FR-03-046, UC-03-23)

```{.mermaid caption="Saga kết nạp HTTT tạo consumer và theo dõi tới khi mọi nút nạp (FR-03-046)"}
sequenceDiagram
  autonumber
  participant P1 as PH-01 saga
  participant CP as ConsumerSyncService
  participant DB as ph03_gateway
  participant BC as BuildCoordinator
  participant SY as dh-sync các nút
  participant NE as NodeStateEvaluator
  P1->>CP: PUT consumers và credentials, Idempotency-Key
  CP->>CP: SecretFieldGuard từ chối trường bí mật
  CP->>DB: Lưu consumer và phần công khai, consumerVersion tăng
  CP-->>P1: 202 effectiveBy 10 giây
  CP->>BC: Kích hoạt tổng hợp tenant
  BC->>SY: Ảnh chụp mới được ký và phát
  SY->>NE: Chỉ số config_version của từng nút
  P1->>CP: GET consumers, hỏi syncState
  CP->>NE: Mọi nút của cả hai cửa đã chạy bản chứa consumerVersion
  CP-->>P1: IN_SYNC
  Note over P1,CP: Bước sau của saga lỗi thì PH-01 gọi DELETE consumer để bù trừ
```

Hình cho thấy `IN_SYNC` chỉ báo khi **mọi nút của cả hai cửa** đã nạp, không phải khi ảnh chụp được phát, và rằng bí mật bị chặn ngay lớp đầu vào. Gọi lại cùng `Idempotency-Key` trả đúng phản hồi cũ nên saga thử lại an toàn.

### 5.8. Ngoại lệ luật WAF có bốn mắt và hết hạn (FR-03-007, UC-03-14)

```{.mermaid caption="Ngoại lệ luật WAF có bốn mắt, hiệu lực và hết hạn (FR-03-007)"}
sequenceDiagram
  autonumber
  actor TO as Vận hành tenant
  participant WX as WafExceptionService
  participant IB as Hộp việc chung
  actor SO as Cán bộ ATTT khác
  participant BC as BuildCoordinator
  participant ES as ExpiryScheduler
  TO->>WX: POST waf exceptions, route, mã luật, lý do, hạn tối đa 90 ngày
  WX->>WX: Kiểm lý do, mã luật tồn tại, không trùng
  WX->>IB: Việc duyệt cho SO, trạng thái REQUESTED
  SO->>WX: approve
  WX->>WX: FourEyesGuard so tài khoản, ACTIVE
  WX->>BC: Tổng hợp, ảnh chụp có SecRuleRemoveById cho route
  Note over WX,BC: Còn 7 ngày chuyển EXPIRING, phát EVT-03-06
  ES->>WX: Đến hạn, EXPIRED
  WX->>BC: Tổng hợp, ngoại lệ gỡ khỏi ảnh chụp
  WX-)IB: EVT-03-05 cho SO và TA
```

Hình cho thấy ngoại lệ không có hiệu lực ở gateway cho tới khi người thứ hai duyệt và ảnh chụp mới được nạp, và rằng hết hạn là việc của bộ lập lịch gom theo tenant chứ không phải của bên gọi nhớ gỡ. Không có đường gia hạn tự động: muốn kéo dài phải đề nghị lại, qua duyệt lần nữa.

### 5.9. Quay lui cấu hình và giữ (FR-03-044, UC-03-21)

```{.mermaid caption="Quay lui cấu hình bằng ảnh chụp mới và giữ tenant (FR-03-044)"}
sequenceDiagram
  autonumber
  actor OP as Vận hành
  participant RB as RollbackService
  participant BK as Bucket và Git
  participant BC as BuildCoordinator
  participant HS as HoldService
  OP->>RB: GET snapshots version diff, xem route và hạn mức sẽ đổi
  OP->>RB: POST snapshots/{version}:rollback, lý do, holdHours
  RB->>BK: Đọc mảnh tenant của phiên bản đích
  RB->>RB: Kiểm đối tượng tham chiếu còn hợp lệ, không lần phát khác
  RB->>BC: Dựng ảnh chụp mới có nội dung mảnh đích
  BC->>BC: Kiểm tra, ký, phát ưu tiên không debounce
  RB->>HS: Giữ tenant holdHours, sự kiện nguồn xếp hàng
  RB-)OP: 202 newSnapshotVersion, holdUntil, EVT-03-02
  OP->>HS: Bỏ giữ sau khi xử lý nguyên nhân
  HS->>BC: Tổng hợp lại từ dữ liệu nguồn mới nhất
```

Hình cho thấy quay lui không đưa số phiên bản cũ trở lại mà tạo bản mới mang nội dung cũ, nên các nút (vốn từ chối phiên bản không lớn hơn) nạp được. Giữ tenant chặn việc tổng hợp tự động hoàn tác quay lui ở lần đối chiếu 5 phút kế tiếp; việc bỏ giữ là hành động có chủ đích của người vận hành.

### 5.10. WAF tự hạ về chế độ phát hiện khi quá tải (FR-03-006, UC-03-13)

```{.mermaid caption="Nút tự hạ WAF về DETECT khi p99 quá ngưỡng và phục hồi (FR-03-006)"}
sequenceDiagram
  autonumber
  participant WG as dh-waf-guard
  participant ST as dh_state
  participant DE as dh-edge
  participant PM as Prometheus
  participant SO as Cán bộ ATTT
  loop Mỗi yêu cầu qua WAF
    WG->>WG: Đo thời gian từ dh-ip-block tới sau Coraza
    WG->>ST: Cập nhật cửa sổ trượt 2 phút, p99
  end
  WG->>ST: p99 vượt gw.waf.degradeP99Ms liên tục 2 phút, đặt waf_degraded
  WG-)PM: dh_gateway_waf_mode DETECT_DEGRADED, EVT-03-09 Nghiêm trọng
  PM-)SO: Cảnh báo GW-A06
  DE->>ST: Yêu cầu mới đọc cờ waf_degraded
  DE->>DE: dh_waf_mode bằng DETECT cho mọi route của nút
  WG->>ST: p99 dưới ngưỡng 5 phút liên tục, xóa cờ
  DE->>DE: Quay lại chế độ cấu hình theo route
```

Hình cho thấy tự hạ là quyết định cục bộ của từng nút, không đi qua `dh-connect` và không đổi cấu hình lưu (nên không cần bốn mắt, FRS FR-03-006 hậu điều kiện); nó chọn giữ dịch vụ rồi cảnh báo. Việc chọn chế độ ở `dh-edge` ngay từ đầu chuỗi là lý do cần hai plugin Coraza với `_meta.filter` thay vì đổi cấu hình Coraza lúc chạy.

### 5.11. Ghi siêu dữ liệu lượt gọi, che dữ liệu và tra cứu (FR-03-050, 051, UC-03-26)

```{.mermaid caption="Ghi siêu dữ liệu lượt gọi, che lần hai và tra cứu qua ClickHouse (FR-03-050, 051)"}
sequenceDiagram
  autonumber
  participant AX as APISIX file-logger
  participant DK as Đĩa cục bộ access.log
  participant OC as OTel Collector
  participant CH as ClickHouse PH-13
  actor U as Người có quyền log-read
  participant CP as AccessLogQueryService
  AX->>DK: Một dòng JSON mỗi lượt gọi, chỉ biến cho phép
  OC->>DK: filelog đọc dòng mới
  OC->>OC: redaction theo mẫu, từ chối bản ghi thiếu nhãn tenant
  OC->>CH: Ghi bản ghi có tenant
  alt PH-13 hoặc Collector ngừng
    OC->>DK: Giữ bản ghi, gửi lại sau, đầy thì bỏ cũ nhất
  end
  U->>CP: GET access-logs, khoảng thời gian, bộ lọc
  CP->>CP: Thêm điều kiện tenant từ token, kiểm khoảng tối đa 31 ngày
  CP->>CH: Truy vấn có tham số
  CH-->>CP: Dòng siêu dữ liệu
  CP-->>U: Kết quả phân trang, srcIp chỉ khi có log-read
```

Hình cho thấy nội dung không có đường nào vào nhật ký, vì định dạng chỉ liệt kê biến cho phép (không phải vì được che sau), và rằng điều kiện tenant do `dh-connect` tự thêm từ token chứ không nhận từ bộ lọc của người dùng (BR-03-028). Khi PH-13 ngừng, gateway không bị ảnh hưởng: đệm đĩa giữ bản ghi, đầy thì mất bản ghi cũ nhất kèm chỉ số và cảnh báo.

## 6. Đa tenant trong mã nguồn

PH-03 có hai kiểu dữ liệu đa tenant khác nhau và thiết kế xử lý riêng từng kiểu. Ở control plane, dữ liệu thuộc về từng tenant và được cách ly bằng RLS như mọi DU. Ở data plane, cấu hình của mọi tenant nằm chung một tệp trong cùng một tiến trình, nên sự cách ly dựa vào việc tenant của lượt gọi chỉ lấy từ token và mọi tài nguyên dùng chung (route, khóa Valkey, nhãn chỉ số) đều mang mã tenant.

| Điểm cách ly | Cách thực hiện | Kiểm bằng |
|---|---|---|
| Bảng `ph03_gateway` | Mọi bảng có `tenant_id` và `FORCE ROW LEVEL SECURITY`; `TenantContextFilter` đặt `SET LOCAL app.tenant_id` đầu mỗi giao dịch từ token (D03-10 §3, SEC-81); vai trò ứng dụng không `BYPASSRLS` | Ca kiểm thử RLS của CI (SEC-87) |
| Dữ liệu cấp nền tảng (bộ đếm phiên bản theo site, mẫu chính sách, `global_rules`) | Dùng giá trị `tenant_id = 'PLATFORM'`; chính sách RLS chỉ cho vai trò nền tảng ghi, mọi tenant đọc phần cần đọc | Ca kiểm thử quyền |
| Tác vụ nền (`BuildCoordinator`, `ExpiryScheduler`, `QuotaEventConsumer`) | Không dùng vai trò vượt RLS: mỗi đơn vị công việc chạy trong giao dịch có `SET LOCAL app.tenant_id` của tenant của nó; việc cấp nền tảng dùng vai trò `gateway_platform` chỉ có quyền trên bảng cấp nền tảng | Kiểm tra khi lấy kết nối từ pool (SEC-81) |
| API quản trị | Tenant lấy từ token, không có trong đường dẫn hay thân; đối tượng của tenant khác trả `404` cùng thân (ERR-03-001, BR-03-028); quay lui hoặc ghép phạm vi `PLATFORM` chỉ cho PA | Bộ kiểm thử rò rỉ chéo tenant (SEC-87) |
| Ảnh chụp cấu hình | Mảnh tenant `shards/{tenant}-{gate}.yaml` tách biệt; quay lui theo tenant chỉ thay mảnh đó; mảnh `COMMON` ghi bởi vai trò nền tảng | So băm mảnh ở manifest |
| Tenant của lượt gọi | Chỉ từ claim đã xác minh, đối chiếu với realm và với tenant của route (`dh-auth` bước 6); `X-DH-*` của khách bị xóa; backend tin `X-DH-Tenant` chỉ khi đến từ APISIX qua mesh | Ca `X-DH-*` giả, token tenant A gọi route tenant B (SEC-80) |
| Khóa Valkey | Mọi khóa lập bởi `FastKeys` với tiền tố `{tenant}`; không có chỗ nào ghép chuỗi tên khóa bằng tay (luật Semgrep cấm `"…:revoked:"` ngoài `FastKeys`) | Quy tắc CI (SEC-82) |
| Hạn mức | Hạn mức toàn tenant (`dh-limit` tầng 1) tách bộ đếm theo tenant; một tenant vượt hạn mức không tăng p95 của tenant khác quá 10% | Kiểm thử tải hai tenant (SEC-86) |
| Chỉ số, nhật ký, vết | Nhãn `tenant` bắt buộc ở nhật ký lượt gọi (Collector từ chối bản ghi thiếu, SEC-84); truy vấn ClickHouse luôn có điều kiện `tenant` từ token | Ca kiểm thử truy vấn |
| Sự kiện Kafka | Topic `{tenant}.gateway.*`; ACL theo tiền tố tenant (PH-10, SEC-82) | Kiểm thử ACL |
| Tenant sáp nhập | Route trên host nguồn mang nhãn tenant đích; token tenant nguồn bị ERR-03-106 | Ca UC-03-30 |

: Điểm cách ly tenant của PH-03

Một ràng buộc mã nguồn quan trọng ở data plane: không plugin nào được tạo đối tượng trạng thái toàn cục không có khóa tenant (bộ đếm, bộ đệm, danh sách). Thư viện `shdict.lua` chỉ cho phép tạo khóa qua hàm nhận `tenant` bắt buộc; thiếu tenant thì hàm ném lỗi lập trình và ca kiểm thử đơn vị bắt được.

## 7. Bảo mật

PH-03 là cửa vào duy nhất nên bảo mật là chức năng chính chứ không phải lớp phụ. Bảng dưới nêu biện pháp theo từng nguy cơ và dẫn `SEC-*` đã có ở D03-07; thiết kế không tạo mã mới.

| Nguy cơ | Biện pháp ở thiết kế | SEC |
|---|---|---|
| Nghe lén, hạ cấp giao thức | TLS 1.3 ở biên; TLS 1.2 chỉ ở host chuyên dụng có ngoại lệ ≤ 180 ngày; bộ mã theo hồ sơ; mTLS mesh giữa chặng và tới backend | SEC-12, SEC-15 |
| Tràn kết nối, tràn tốc độ tầng 7 | Giới hạn theo IP chạy đầu chuỗi, cục bộ pod, không phụ thuộc Valkey; tự chặn khi vi phạm lặp; chống DDoS tầng 3 và 4 ở hạ tầng | SEC-10 |
| Tấn công ứng dụng web | Coraza với OWASP CRS 4.x, hai mức hoang tưởng, chế độ `DETECT` 14 ngày trước `BLOCK`, ngoại lệ bốn mắt có hạn, vá ảo ≤ 4 giờ | SEC-11 |
| Bypass gateway | Chính sách mạng chỉ cho backend nhận từ APISIX; Admin API APISIX tắt; cổng 8444 chỉ từ `apisix-ext` | SEC-14, SEC-15 |
| Giả mạo tenant hoặc danh tính nội bộ | Tenant chỉ từ token; xóa `X-DH-*`; chỉ cổng 8444 được tin tiêu đề chặng; backend kiểm SPIFFE | SEC-80 |
| Token giả, đánh cắp, hết hạn | Xác minh cục bộ ES256 hoặc PS256 với danh sách thuật toán cố định; ràng buộc `cnf` với chứng thư; thu hồi dưới 60 giây | SEC-24, SEC-25 |
| Cấu hình giả hoặc bị sửa | Ảnh chụp ký ECDSA bằng khóa transit không xuất được; nút kiểm chữ ký, băm, phiên bản; cấm sửa trên pod (filesystem gốc chỉ đọc, `emptyDir` chỉ có `dh-sync` ghi); lệch Git phát hiện trong 1 giờ | SEC-36, SEC-65 |
| Mã tùy ý qua plugin | Chỉ plugin trong danh mục, ký cùng ảnh; không có đường tải plugin hay Lua của tenant; ảnh ký cosign, Kyverno `verifyImages`, Trivy 0 CRITICAL | SEC-52, SEC-55, SEC-56, SEC-57 |
| Lộ dữ liệu cá nhân trong nhật ký | Định dạng chỉ liệt kê biến cho phép; che lần hai ở Collector; kiểm thử canary `DH-CANARY-…` | SEC-32, SEC-61 |
| Lộ khóa riêng chứng thư | Khóa chỉ ở OpenBao và Secret `tmpfs`, `dh-sync` điền lúc chạy; không vào Git, bucket, bảng | SEC-33, SEC-35 |
| SSRF qua địa chỉ upstream | CHK-10 cấm loopback, `169.254.0.0/16`, dải quản trị; egress theo FQDN cho `dh-sync` | SEC-16, SEC-43 |
| Phá hoại ngoài ý muốn bởi quản trị | Bốn mắt cho bốn loại thay đổi; tạm ngừng khẩn cấp có kiểm toán và nhắc xem lại; quay lui có lý do | SEC-60 |
| Truy cập chéo tenant qua gateway | Ca kiểm thử chéo tenant bắt buộc cho mọi route mẫu; hạn mức theo tenant | SEC-87, SEC-86 |
| Khôi phục sau sự cố | Ảnh chụp ở Git (lịch sử vĩnh viễn) và bucket; khóa ký xoay 12 tháng; bucket nhân bản sang site DR | SEC-71 |

: Biện pháp bảo mật theo nguy cơ

**Kiểm quyền ở máy chủ.** Mỗi `@RestController` của `web` gắn `@PreAuthorize` theo quyền của PH-03 (`read`, `admin`, `limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read`) hoặc scope dịch vụ (`gateway:sync`, `gateway:revoke`, `gateway:read-state`); bốn mắt và trạng thái do aggregate kiểm. Ẩn nút ở giao diện chỉ là tiện ích. Tài khoản dịch vụ chỉ được cấp scope đúng việc, không cấp cho người (FRS mục 3.2).

**Quyền của thành phần chạy.** `dh-sync` có quyền đọc bucket (chỉ ở `apisix-int`), đọc Secret chứng thư của namespace mình, đọc `EndpointSlice` của Service mình; không có quyền ghi K8s, không có token OpenBao. `dh-connect` có quyền ký trên `transit/keys/dh-gateway-snapshot` nhưng không có quyền đọc khóa riêng của chứng thư biên (chỉ ghi khi nhập tay). Plugin Datahub chỉ có đường tới Valkey (không có tài khoản OpenBao). Tài khoản Valkey của plugin chỉ có quyền `GET`, `EVALSHA`, `XADD` trên tiền tố tenant (ACL Valkey), tài khoản của `dh-connect` có quyền ghi khóa chặn; hai tài khoản tách nhau.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Mười bốn máy trạng thái của PH-03 có bảng dưới. Mười một máy lưu ở PostgreSQL: tám máy (route, consumer, ngoại lệ WAF, ảnh chụp, yêu cầu thay đổi, tạm ngừng khẩn cấp, chuyển tiếp tenant, ngoại lệ TLS 1.2) cùng ba máy mà tập CSDL bổ sung là luật vá ảo (`WAF_PATCH`), giữ tổng hợp sau quay lui (`TENANT_HOLD`) và nhập hệ cũ (`IMPORT_JOB`). Cặp chuyển hợp lệ nằm ở bảng `state_transition` và trigger `tg_state_guard` chặn mọi cập nhật cột `state` ngoài bảng; nội dung ảnh chụp đã ký được giữ bất biến bằng trigger `tg_write_once` (D03-03-PH03 chương 1 và 5). Ba máy còn lại (chế độ WAF của nút, trạng thái nạp của `dh-sync`, trạng thái đồng bộ nút) là trạng thái suy ra hoặc cục bộ của nút, không có bản ghi. Cột cuối nêu nơi máy chủ kiểm chuyển trạng thái; giao diện không phải nơi bảo vệ.

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| Route | (mới) | Tổng hợp xong | `PENDING` | Nguồn PH-02 đã duyệt |
| Route | `PENDING` | Ảnh chụp chứa route được nạp | `ACTIVE` | `NodeStateEvaluator` thấy phiên bản đã chạy |
| Route | `ACTIVE` | `stop` | `STOPPED` | `operate`; route phải `ACTIVE` (ERR-03-023) |
| Route | `STOPPED` | `start` | `ACTIVE` | `operate` |
| Route | `ACTIVE` | `suspend` | `SUSPENDED` | `operate`, lý do 10…500 ký tự; chưa bị tạm ngừng (ERR-03-019) |
| Route | `SUSPENDED` | `resume` | `ACTIVE` | `operate`, lý do |
| Route | `ACTIVE` | `sunsetAt` đến | `SUNSET` | `ExpiryScheduler`; CHK-11 đã đảm bảo ≥ 180 ngày |
| Route | `STOPPED`, `SUNSET` | PH-02 ngừng dùng, hoặc quá `gw.sunset.retainDays` | `RETIRED` | Không còn đăng ký hiệu lực |
| Consumer | (mới) | `PUT` | `ACTIVE` | `gateway:sync`; không trường bí mật |
| Consumer | `ACTIVE` | `PUT state=SUSPENDED`, hoặc `suspend` khẩn cấp | `SUSPENDED` | `gateway:sync` hoặc `operate` |
| Consumer | `SUSPENDED` | `PUT state=ACTIVE`, hoặc `resume` | `ACTIVE` | Như trên |
| Consumer | `ACTIVE`, `SUSPENDED` | `DELETE` | `DELETED` (xóa mềm) | Không còn đăng ký hiệu lực (ERR-03-017) |
| Ngoại lệ WAF | (mới) | `request` | `REQUESTED` | `waf-request`; lý do, mã luật, ≤ 90 ngày |
| Ngoại lệ WAF | `REQUESTED` | `approve` | `ACTIVE` | `waf-approve`; người duyệt ≠ người đề nghị (ERR-03-008) |
| Ngoại lệ WAF | `REQUESTED` | `reject` | `REJECTED` | `waf-approve`, ý kiến |
| Ngoại lệ WAF | `ACTIVE` | còn `warnDays` | `EXPIRING` | `ExpiryScheduler` |
| Ngoại lệ WAF | `ACTIVE`, `EXPIRING` | đến hạn | `EXPIRED` | `ExpiryScheduler` |
| Ngoại lệ WAF | `ACTIVE`, `EXPIRING` | `revoke` | `REVOKED` | `waf` |
| Ảnh chụp | (mới) | Tổng hợp | `BUILT` | Khóa tổng hợp theo tenant |
| Ảnh chụp | `BUILT` | Kiểm tra không đạt | `REJECTED` | Có mức `LỖI` (CHK) |
| Ảnh chụp | `BUILT` | Đạt và ký | `SIGNED` | OpenBao khả dụng (ERR-03-015) |
| Ảnh chụp | `SIGNED` | Ghi bucket (và Git) | `PUBLISHED` | Phiên bản lớn hơn bản đã phát (ERR-03-006) |
| Ảnh chụp | `PUBLISHED` | Mọi nút `IN_SYNC` | `APPLIED` | `NodeStateEvaluator` |
| Ảnh chụp | `PUBLISHED` | Nút `LAGGING` quá `gw.node.lagSeconds` | `PARTIAL` | `NodeStateEvaluator` |
| Ảnh chụp | `PARTIAL` | Nút còn lại nạp xong | `APPLIED` | `NodeStateEvaluator` |
| Ảnh chụp | `APPLIED`, `PARTIAL` | Có bản mới hơn được nạp | `SUPERSEDED` | — |
| Yêu cầu thay đổi | (mới) | `request` | `PENDING` | Quyền đề nghị; không có yêu cầu đang chờ cho cùng đối tượng |
| Yêu cầu thay đổi | `PENDING` | `approve` | `APPROVED` | `approve`; `FourEyesGuard` (ERR-03-008) |
| Yêu cầu thay đổi | `PENDING` | `reject` | `REJECTED` | `approve`, ý kiến |
| Yêu cầu thay đổi | `PENDING` | Quá 14 ngày | `EXPIRED` | `ExpiryScheduler` (giả định, cơ sở: tránh việc treo vô hạn) |
| Tạm ngừng khẩn cấp | (mới) | `suspend` | `ACTIVE` | `operate`; chưa có khối đang hoạt động (ERR-03-019) |
| Tạm ngừng khẩn cấp | `ACTIVE` | `resume` | `LIFTED` | `operate`, lý do |
| Chuyển tiếp tenant | (mới) | Tạo | `ACTIVE` | Nguồn `MERGED`, đích `ACTIVE`, route đích tồn tại (ERR-03-025) |
| Chuyển tiếp tenant | `ACTIVE` | `endAt` đến, hoặc `end` | `ENDED` | `ExpiryScheduler` hoặc `admin` |
| Ngoại lệ TLS 1.2 | (mới) | Tạo | `ACTIVE` | `admin`; lý do, ≤ 180 ngày (ERR-03-003) |
| Ngoại lệ TLS 1.2 | `ACTIVE` | Đến hạn hoặc `revoke` | `ENDED` | `ExpiryScheduler` hoặc `admin` |
| Chế độ WAF của nút | `BLOCK` | p99 quá ngưỡng 2 phút | `DETECT_DEGRADED` | `dh-waf-guard` (cục bộ nút) |
| Chế độ WAF của nút | `DETECT_DEGRADED` | p99 dưới ngưỡng 5 phút | `BLOCK` | `dh-waf-guard` |
| `dh-sync` | `IDLE` | Con trỏ `current` đổi | `FETCHING` | `version` lớn hơn `lastApplied` |
| `dh-sync` | `FETCHING` | Tải xong | `VERIFYING` | — |
| `dh-sync` | `VERIFYING` | Chữ ký, băm, lược đồ đạt | `APPLYING` | Từ chối nếu một kiểm tra không đạt (về `IDLE`) |
| `dh-sync` | `APPLYING` | Ghi tệp | `CONFIRMING` | — |
| `dh-sync` | `CONFIRMING` | Nút báo đúng phiên bản | `IDLE` | Quá 10 giây: khôi phục bản trước, về `IDLE` |
| Đồng bộ nút (suy ra) | `IN_SYNC` | Lệch > `gw.node.lagSeconds` | `LAGGING` | `NodeStateEvaluator` |
| Đồng bộ nút (suy ra) | bất kỳ | `sync_total{result="invalid"}` mới nhất | `FAILED` | `NodeStateEvaluator` |
| Đồng bộ nút (suy ra) | bất kỳ | Không số liệu > `gw.node.unknownSeconds` | `UNKNOWN` | `NodeStateEvaluator` |

: Bảng chuyển trạng thái

Mọi lệnh chuyển trạng thái đi qua một phương thức của aggregate nên trạng thái không đổi nếu lệnh không hợp lệ; chuyển trạng thái và outbox cùng giao dịch. Lệnh từ API dùng `If-Match`; lệnh hệ thống dùng thử lại tối đa 3 lần khi xung đột phiên bản.

### 8.2. Outbox, sự kiện và nhất quán

Sự kiện EVT-03-01…08, 10…12 do `dh-connect` ghi vào bảng `outbox` cùng giao dịch với thay đổi trạng thái; bộ chuyển outbox sang Kafka (Debezium outbox của `pg-core`, dùng chung cơ chế với PH-04, ADR-042) đẩy lên topic `{tenant}.gateway.*` với khóa phân vùng là mã đối tượng, nên sự kiện của một đối tượng giữ thứ tự. Bên tiêu thụ xử lý lũy đẳng theo `eventId`. EVT-03-09 có hai nguồn: gateway phát qua `kafka-logger` (không giao dịch, giao ít nhất một lần, đủ cho cảnh báo) và `dh-connect` khi tạm ngừng khẩn cấp (qua outbox). Lược đồ tương thích BACKWARD ở Apicurio (ADR-070).

Ba quy tắc giữ nhất quán giữa PostgreSQL, Valkey, bucket và nút:

1. **Cơ sở dữ liệu là nguồn sự thật, Valkey và bucket là bản phái sinh.** Mọi ghi vào Valkey hoặc bucket xảy ra sau khi giao dịch cơ sở dữ liệu commit; nếu ghi phái sinh lỗi thì tác vụ đối chiếu (5 phút) và `ValkeyRebuilder` sửa; không bao giờ ghi phái sinh trước khi có bản ghi gốc.
2. **Nút luôn chạy đúng một ảnh chụp.** Không có cập nhật từng phần; thay đổi nhỏ cũng là ảnh chụp mới. Hai đường (nhanh, bền) chỉ cùng chiều (cùng chặn), không bao giờ đảo chiều (đường nhanh không mở).
3. **Tổng hợp là hàm thuần của dữ liệu nguồn.** Cùng đầu vào cho cùng băm nên tổng hợp lại là an toàn; tổng hợp trùng không tạo thay đổi vì băm bằng bản đang chạy thì không phát (bỏ qua, ghi nhận `NO_CHANGE`).

### 8.3. Thử lại, thời gian chờ, ngắt mạch và mở hay đóng

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch | Khi lỗi kéo dài |
|---|---|---|---|---|
| Plugin → Valkey | 50 ms | Không | 5 giây rồi thăm dò | Suy giảm có kiểm soát (4.4); `dh-revocation` dùng bộ đệm |
| Plugin → OPA | `gw.opa.timeoutMs` (50 ms) | Không | Không | Đóng an toàn, ERR-03-124 |
| Tác vụ nền → Keycloak JWKS | 2 giây | Chu kỳ làm mới kế tiếp | Không | Dùng bộ đệm tới 24 giờ rồi ERR-03-124 |
| `dh-connect` → Valkey | 200 ms | 2 lần, 100 ms, 200 ms | 50% trên 10 lượt, nửa mở 30 giây | Ghi cơ sở, đường bền, `ValkeyRebuilder` |
| `dh-connect` → OpenBao (ký) | 2 giây | Lũy thừa tới 60 giây, tổng 1 giờ | 50% trên 10 lượt | Ảnh chụp giữ `BUILT`, cảnh báo Cao |
| `dh-connect` → Garage | 5 giây | 3 lần | Không | Thử Git; cả hai lỗi: ERR-03-014 |
| `dh-connect` → Git | 10 giây | Hàng đợi tới 1 giờ | Không | Cờ `gitPending`, cảnh báo Cao |
| `dh-connect` → nguồn PH-01, 02, 12, 20 | 3 giây | 2 lần | Có, theo nguồn | Bản chiếu gần nhất; cảnh báo quá 24 giờ |
| `dh-connect` → Mimir, ClickHouse | 5 giây | 1 lần | Không | ERR-03-026, màn hình "không có số liệu" |
| `dh-connect` → cert-manager (đọc) | 5 giây | 2 lần | Không | Giữ trạng thái cũ, cảnh báo |
| `dh-sync` → bucket hoặc điểm chuyển tiếp | 3 giây | Vòng lặp 5 giây | Không | Giữ cấu hình đang chạy |
| `dh-sync` → CRL | 10 giây | Chu kỳ kế tiếp | Không | CRL quá 24 giờ: từ chối chứng thư của CA đó |
| APISIX → backend | `gw.upstream.timeout.*` | `retries` 0 cho phương thức không lũy đẳng | `api-breaker` | ERR-03-120, 121, 122 |

: Thử lại, thời gian chờ, ngắt mạch

Nguyên tắc mở hay đóng: **đóng** (từ chối) khi lỗi làm mất khả năng xác thực hoặc ủy quyền (JWKS hết hạn đệm, OPA không phản hồi, CRL quá hạn, chữ ký ảnh chụp sai); **mở có cảnh báo** khi lỗi chỉ làm mất độ chính xác của kiểm soát phụ (Valkey cho hạn ngạch dài hạn, Valkey cho danh sách thu hồi vì token sống tối đa 5 phút, PH-13 cho nhật ký). Mỗi quyết định mở có chỉ số riêng và cảnh báo ở FR-03-054.

### 8.4. Phân loại lỗi của control plane

`@RestControllerAdvice` của `web` chuyển ngoại lệ miền thành `ProblemDetail` (RFC 9457) với `code` là mã ERR; thân và trường bổ sung ở D03-04-PH03 §6.

| Mã | HTTP | Ngoại lệ miền | Phát sinh ở |
|---|---|---|---|
| ERR-03-001 | 404 | `NotFoundInTenantException` | Mọi tra cứu theo mã |
| ERR-03-002 | 409 | `DuplicateCodeException` | Tạo consumer, route, ngoại lệ |
| ERR-03-003 | 400 | `InvalidRequestException` | `SecretFieldGuard`, kiểm lược đồ đầu vào |
| ERR-03-004 | 412 | `OptimisticLockException` (chuyển đổi) | `If-Match` |
| ERR-03-005 | 422 | `SnapshotValidationException` | 4.9 |
| ERR-03-006 | 409 | `BuildBusyException` | 4.8, 4.10 |
| ERR-03-007 | 422 | `RollbackNotPossibleException` | 4.10 |
| ERR-03-008 | 403 | `FourEyesViolationException` | 4.14 |
| ERR-03-009 | 422 | `WafExceptionInvalidException` | 4.14 |
| ERR-03-010 | 409 | `WafExceptionConflictException` | 4.14 |
| ERR-03-011 | 422 | `ExposureNotEligibleException` | 4.15 |
| ERR-03-012 | 422 | `ContractMissingException` | CHK-02, 03 |
| ERR-03-013 | 422 | `PluginNotAllowedException` | CHK-04 |
| ERR-03-014 | 502 | `PublishStoreUnavailableException` | 4.10 |
| ERR-03-015 | 503 | `SigningUnavailableException` | 4.10, 4.15 |
| ERR-03-016 | 422 | `CertificateInvalidException` | 4.15, CHK-13 |
| ERR-03-017 | 409 | `ConsumerInUseException` | 4.13 |
| ERR-03-018 | 422 | `LimitCeilingException` | 4.14, CHK-12 |
| ERR-03-019 | 409 | `AlreadyInStateException` | 4.12, 4.15 |
| ERR-03-020 | 422 | `LegacyBundleInvalidException` | 4.16 |
| ERR-03-021 | 400 | `QueryRangeException` | 4.16 |
| ERR-03-022 | 403 | `AccessDeniedException` | `@PreAuthorize` |
| ERR-03-023 | 409 | `RouteStateException` | 4.15 |
| ERR-03-024 | 422 | `ProtectedAddressException` | 4.15 |
| ERR-03-025 | 409 | `RedirectConflictException` | 4.15 |
| ERR-03-026 | 503 | `ObservabilityUnavailableException` | 4.16 |
| ERR-03-027 | 422 | `WafBlockNotReadyException` | 4.14 |

: Ánh xạ ngoại lệ miền sang mã lỗi control plane

Mã lỗi gateway `ERR-03-101…130` do plugin sinh và dựng thân ở `dh-problem` (mục 4.6); danh mục `errors.json` ở `plugins/dh/` và bảng mã của D03-04-PH03 sinh từ cùng một nguồn để không lệch.

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số hạ tầng của thiết kế

Các tham số này thuộc triển khai, không chỉnh theo tenant, và nằm ở `application.yml` của `dh-connect`, biến môi trường của `dh-sync` hoặc `config.yaml.tmpl` của APISIX. Chúng khác với tham số `gw.*` của FRS mục 8.2 (theo tenant, có miền và trần hợp đồng).

| Khóa | Mặc định | Nơi dùng | Ý nghĩa |
|---|---|---|---|
| `dh.gateway.site` | `dc1` | `dh-connect` | Mã site cho bộ đếm phiên bản, đường dẫn bucket, thư mục Git |
| `dh.gateway.build.maxParallelTenants` | 4 | `dh-connect` | Số tenant tổng hợp song song trên một bản sao |
| `dh.gateway.build.sourceStaleAlertHours` | 24 | `dh-connect` | Ngưỡng cảnh báo nguồn cũ |
| `dh.gateway.sign.retryMaxMinutes` | 60 | `dh-connect` | Tổng thời gian thử lại ký |
| `dh.gateway.publish.gitRetryMaxMinutes` | 60 | `dh-connect` | Tổng thời gian thử lại Git |
| `dh.gateway.valkey.timeoutMs` | 200 | `dh-connect` | Thời hạn lệnh Valkey từ control plane |
| `dh.gateway.valkey.rebuildProbeSeconds` | 10 | `dh-connect` | Chu kỳ thăm dò để dựng lại khóa chặn |
| `dh.gateway.changeRequest.expireDays` | 14 | `dh-connect` | Hết hạn yêu cầu thay đổi chờ duyệt (giả định) |
| `dh.gateway.emergency.reminderHours` | 4 | `dh-connect` | Nhắc xem lại tạm ngừng khẩn cấp |
| `gw.approval.substitute` | `false` | `dh-connect` | PA duyệt thay khi tenant dưới hai SO (Q03-02 của FRS) |
| `DH_REPLICAS_HINT` | 3 | `dh-limit` | Số bản sao dự phòng khi không đọc được `replicas` |
| `DH_SYNC_ROLE` | `agent` | `dh-sync` | `init`, `agent`, `relay` |
| `DH_SYNC_CONFIRM_SECONDS` | 10 | `dh-sync` | Thời hạn xác nhận phiên bản sau khi ghi tệp |
| `lua_shared_dict dh_*` | Mục 4.1 | APISIX | Kích thước vùng nhớ chia sẻ |
| `gw.ip.headerTimeoutSeconds`, `gw.ip.bodyTimeoutSeconds` | 10, 30 | APISIX (nginx) | Áp ở mức nhóm cửa vào, không theo tenant, vì NGINX đọc tiêu đề trước khi biết tenant (đề nghị ghi vào FRS 8.2) |

: Tham số hạ tầng riêng của thiết kế

### 9.2. Tham số `gw.*` và nơi chúng có hiệu lực

Tham số theo tenant (FRS mục 8.2) lưu ở `ph03_gateway`, đổi qua FR-03-056; mọi thay đổi kích hoạt tổng hợp và có hiệu lực khi ảnh chụp mới được nạp, trừ ba tham số có bốn mắt. Bảng gom các họ khóa theo nơi tác động để kỹ sư biết sửa ở đâu.

| Họ khóa | Có hiệu lực ở | Cách tới nơi |
|---|---|---|
| `gw.ip.*` | `dh-ip-block` | Siêu dữ liệu plugin trong ảnh chụp |
| `gw.body.*`, `gw.json.*` | `client-control`, `request-validation` | Cấu hình plugin của route |
| `gw.waf.*` | Coraza, `dh-edge`, `dh-waf-guard` | Chỉ thị do `WafDirectiveRenderer` sinh; `degradeP99Ms` ở siêu dữ liệu `dh-waf-guard` |
| `gw.tls.*` | `ssls` | Ngoại lệ TLS render thành đối tượng `ssls` |
| `gw.jwks.*`, `gw.jwt.*` | `dh-auth` | Siêu dữ liệu plugin |
| `gw.opa.*` | `opa` | Cấu hình plugin của route |
| `gw.rate.*`, `gw.quota.*`, `gw.tenantRateLimit.*`, `gw.degrade.*` | `dh-limit` | Cấu hình plugin của route, đã giải thứ tự ưu tiên |
| `gw.throttle.*` | `dh-adaptive-throttle` | Cấu hình plugin của route |
| `gw.upstream.*`, `gw.breaker.*`, `gw.ws.*` | Upstream, `api-breaker`, route | Kết xuất `upstreams[]` |
| `gw.trace.*`, `gw.metrics.*`, `gw.accessLog.*` | `opentelemetry`, `metrics.lua`, `file-logger` | Siêu dữ liệu plugin |
| `gw.sunset.*`, `gw.redirect.*` | `dh-connect` | Đọc trực tiếp ở `ExpiryScheduler` |
| `gw.snapshot.*`, `gw.reconcile.*`, `gw.rollback.*` | `dh-connect` | Đọc trực tiếp ở 4.8, 4.10 |
| `gw.sync.*`, `gw.node.*` | `dh-sync`, `NodeStateEvaluator` | `pollSeconds` đi qua siêu dữ liệu ảnh chụp tới `dh-sync` |
| `gw.cert.*`, `gw.emergency.*` | `dh-connect` | Đọc trực tiếp |

: Nơi có hiệu lực của tham số gw

### 9.3. Cờ tính năng theo tenant

Cờ tính năng dùng OpenFeature với nhà cung cấp chung của nền tảng (cùng PH-04). Cờ điều khiển cả control plane (không nhận lệnh) lẫn ảnh chụp (không kết xuất cấu hình tương ứng), để tính năng tắt thì không có mã Lua của nó nằm trong cấu hình nút.

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `gateway.virtualPatch.enabled` | `false` | Luật vá ảo khẩn cấp (FR-03-008, Đợt 2) |
| `gateway.cors.enabled` | `false` | Chính sách CORS theo route (FR-03-010, Đợt 2) |
| `gateway.overrides.enabled` | `false` | Ghi đè hạn mức theo route và thứ tự ưu tiên (FR-03-024, Đợt 2) |
| `gateway.throttle.enabled` | `false` | Điều tiết theo tình trạng backend (FR-03-027, Đợt 2) |
| `gateway.redirect.enabled` | `false` | Chuyển tiếp tenant sáp nhập (FR-03-037, Đợt 2) |
| `gateway.simulation.enabled` | `false` | Chạy thử chính sách (FR-03-057, Đợt 2) |
| `gateway.usageReport.enabled` | `false` | Báo cáo sử dụng (FR-03-058, Đợt 2) |
| `gateway.grpc.enabled` | `false` | Chuyển đổi gRPC và REST (FR-03-034, Đợt 3) |
| `gateway.legacyImport.enabled` | `true` | Nhập từ gateway cũ trong giai đoạn thay dần (FR-03-059) |
| `gateway.syntheticChecks.enabled` | `true` | Kiểm tra tổng hợp cho API quan trọng (FR-03-053) |

: Cờ tính năng của PH-03

## 10. Quan sát

PH-03 phát chỉ số, vết và nhật ký theo ADR-011. Chỉ số ở mặt phẳng dữ liệu có tiền tố `dh_gateway_`, ở control plane có tiền tố `dh_gw_cp_`. Nhãn có số giá trị bị chặn để tránh bùng nổ chuỗi thời gian: `tenant` (tối đa 34 ở `QM-CHUNG`), `route` (chỉ ở chỉ số tổng hợp của từng route và bị chặn bởi bộ lọc route quan trọng, phần còn lại tra ở ClickHouse), `consumer` bị chặn `gw.metrics.maxConsumerLabels` (Q03-08).

**Chỉ số ở mặt phẳng dữ liệu.**

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `dh_gateway_requests_total` | counter | `tenant`, `gate`, `status_class` | `prometheus` |
| `dh_gateway_request_duration_seconds` | histogram | `tenant`, `gate` | `prometheus` |
| `dh_gateway_added_latency_seconds` | histogram | `gate` | `dh-edge` (log): thời gian yêu cầu trừ thời gian của backend |
| `dh_gateway_plugin_duration_seconds` | histogram | `plugin` | `plugins/dh/metrics.lua` |
| `dh_gateway_plugin_errors_total` | counter | `plugin` | Lớp bao `pcall` |
| `dh_gateway_problem_total` | counter | `code` | `dh-problem` |
| `dh_gateway_tls_handshake_total` | counter | `version`, `result` | `dh-edge`, nhật ký NGINX |
| `dh_gateway_mtls_total` | counter | `result` | `dh-edge` |
| `dh_gateway_edge_proof_invalid_total` | counter | — | `dh-edge` cổng 8444 |
| `dh_gateway_ip_limit_rejected_total` | counter | `kind` (`conn`, `rate`, `blocked`) | `dh-ip-block` |
| `dh_gateway_ip_table_full_total` | counter | — | `dh-ip-block` |
| `dh_gateway_slow_client_total` | counter | `kind` | NGINX |
| `dh_gateway_waf_blocked_total` | counter | `tenant`, `rule` | OTel Collector, từ nhật ký Coraza (mục 4.2) |
| `dh_gateway_waf_duration_seconds` | histogram | `gate` | `dh-waf-guard` |
| `dh_gateway_waf_mode` | gauge (0 `DETECT`, 1 `BLOCK`, 2 tự hạ) | `gate` | `dh-waf-guard` |
| `dh_gateway_validation_rejected_total` | counter | `tenant`, `route` | `dh-problem` (suy từ điểm dừng và mã 400) |
| `dh_gateway_cors_denied_total` | counter | `tenant` | `cors` (không từ chối, chỉ đếm nguồn gốc ngoài danh sách) |
| `dh_gateway_jwt_verify_total` | counter | `result` | `dh-auth` |
| `dh_gateway_jwks_age_seconds` | gauge | `realm` | `jwks.lua` |
| `dh_gateway_auth_failed_total` | counter | `tenant`, `reason` | `dh-auth` |
| `dh_gateway_revocation_hits_total` | counter | `tenant` | `dh-revocation` |
| `dh_gateway_revocation_unknown_total` | counter | — | `dh-revocation` (Valkey lỗi, không bộ đệm) |
| `dh_gateway_kill_hits_total` | counter | `tenant`, `target` | `dh-kill-switch` |
| `dh_gateway_path_denied_total` | counter | `tenant`, `kind` | `dh-path-acl` |
| `dh_gateway_ratelimit_rejected_total` | counter | `tenant`, `limit` (`rate`, `quota`, `tenant`, `throttle`, `ws`) | `dh-limit`, `dh-adaptive-throttle` |
| `dh_gateway_valkey_up` | gauge | — | `valkey.lua` |
| `dh_gateway_valkey_latency_seconds` | histogram | `op` | `valkey.lua` |
| `dh_gateway_degraded_requests_total` | counter | `tenant` | `dh-limit` |
| `dh_gateway_throttle_factor` | gauge | `upstream` | `dh-adaptive-throttle` |
| `dh_gateway_upstream_duration_seconds` | histogram | `tenant`, `upstream` | `prometheus` |
| `dh_gateway_upstream_node_healthy` | gauge | `upstream`, `node` | Bộ kiểm tra sức khỏe |
| `dh_gateway_upstream_timeout_total` | counter | `upstream` | `dh-problem` |
| `dh_gateway_breaker_state` | gauge | `route` | `api-breaker` |
| `dh_gateway_opa_duration_seconds` | histogram | — | `dh-problem` (log), đo từ khi `dh-adaptive-throttle` xong tới `before_proxy`, gồm cả `request-validation` và `opa`; tách riêng cần bọc `opa` (X1) |
| `dh_gateway_opa_decision_total` | counter | `decision` (`allow`, `deny`, `error`) | `dh-problem` (log), suy từ điểm dừng và mã phản hồi |
| `dh_gateway_transcode_total` | counter | `result` | `grpc-transcode` (Đợt 3) |
| `dh_gateway_active_connections` | gauge | `gate` | NGINX |
| `dh_gateway_trace_invalid_total` | counter | — | `dh-edge` (`traceparent` sai dạng) |
| `dh_gateway_synthetic_up` | gauge | `check` | Bộ chạy kiểm tra (FR-03-053) |
| `dh_gateway_synthetic_duration_seconds` | histogram | `check` | Bộ chạy kiểm tra |
| `dh_gateway_accesslog_sent_total` | counter | — | OTel Collector (đếm bản ghi đã gửi tới PH-13) |
| `dh_gateway_accesslog_dropped_total` | counter | — | `dh-sync` (xoay vòng tệp, đếm dòng bị xóa khi vượt giới hạn đệm) |
| `dh_gateway_config_version` | gauge | `gate`, `site` | `dh-edge` đọc siêu dữ liệu |
| `dh_gateway_config_applied_timestamp` | gauge | `gate`, `site` | `dh-sync` |
| `dh_gateway_sync_total` | counter | `result` | `dh-sync` |
| `dh_gateway_sync_duration_seconds` | histogram | — | `dh-sync` |

: Chỉ số của mặt phẳng dữ liệu PH-03

**Chỉ số ở control plane và nơi khác.** `dh_gateway_source_stale_seconds{source}` (do `dh-connect` xuất theo tên của FRS) cùng các chỉ số dưới đây.

| Chỉ số | Kiểu | Nhãn |
|---|---|---|
| `dh_gw_cp_aggregate_conflicts_total` | counter | `type` |
| `dh_gw_cp_build_duration_seconds` | histogram | `phase` (`assemble`, `validate`, `sign`, `publish`) |
| `dh_gw_cp_build_total` | counter | `trigger`, `result` |
| `dh_gw_cp_hold_active` | gauge | `tenant` |
| `dh_gw_cp_validation_total` | counter | `rule`, `level` |
| `dh_gw_cp_validation_duration_seconds` | histogram | — |
| `dh_gw_cp_snapshot_version` | gauge | `site` |
| `dh_gw_cp_publish_duration_seconds` | histogram | `path` (`bucket`, `git`) |
| `dh_gw_cp_sign_failures_total` | counter | — |
| `dh_gw_cp_publish_pending` | gauge | `path` |
| `dh_gw_cp_fastblock_write_total` | counter | `kind`, `result` |
| `dh_gw_cp_valkey_rebuild_total` | counter | `result` |
| `dh_gw_cp_fastblock_effective_seconds` | histogram | `kind` |
| `dh_gw_cp_consumer_sync_total` | counter | `op`, `result` |
| `dh_gw_cp_consumer_sync_lag_seconds` | histogram | — |
| `dh_gw_cp_change_requests` | gauge | `type`, `state` |
| `dh_gw_cp_waf_exception_active` | gauge | `tenant` |
| `dh_gw_cp_expiry_jobs_total` | counter | `kind` |
| `dh_gw_cp_cert_days_remaining` | gauge | `cert` |
| `dh_gw_cp_route_state` | gauge | `tenant`, `state` |
| `dh_gw_cp_redirect_active` | gauge | — |
| `dh_gw_cp_node_sync_state` | gauge | `gate`, `state` |
| `dh_gw_cp_logquery_duration_seconds` | histogram | — |
| `dh_gw_cp_simulation_total` | counter | `result` |

: Chỉ số của control plane PH-03

**Vết.** `opentelemetry` tạo span gốc `gw.request` có thuộc tính `dh.tenant`, `dh.route`, `dh.consumer`, `dh.gate`, `http.status_code`, `dh.stage` (điểm dừng cuối của chuỗi), và truyền `traceparent` xuống backend; thời gian từng plugin không thành span riêng (chi phí) mà vào histogram `dh_gateway_plugin_duration_seconds`. Control plane có span `gateway.build`, `gateway.validate`, `gateway.sign`, `gateway.publish`, mỗi span mang `dh.snapshot.version`. Vết lỗi giữ 100%, vết thành công lấy mẫu `gw.trace.successSampling`.

**Nhật ký.** Log ứng dụng của `dh-connect` là JSON có `tenant`, `traceId`, không có thân yêu cầu, không có giá trị bí mật. Log của APISIX và `dh-sync` là JSON, không có tiêu đề xác thực; plugin Datahub chỉ ghi tên tiêu đề và băm cắt ngắn của vân tay chứng thư. Log nút thành đối tượng kiểm toán an ninh (SEC-61) khi nạp ảnh chụp: nút, phiên bản trước và sau, kết quả.

**Cảnh báo.** Mười ba luật `GW-A01…A13` của FRS mục 6.7 (FR-03-054) được hiện thực ở Mimir và Alertmanager của PH-13 theo bảng dưới; mức độ, người nhận theo FRS.

| Luật | Biểu thức cảnh báo (dạng mô tả) |
|---|---|
| GW-A01 | `rate(dh_gateway_waf_blocked_total[1m]) * 60 > 100` theo route, hoặc gấp 10 lần trung bình 24 giờ |
| GW-A02 | `rate(dh_gateway_auth_failed_total[1m]) * 60 > 50` theo `tenant` hoặc nguồn (nhật ký ClickHouse theo `srcIp`) |
| GW-A03 | `increase(dh_gateway_auth_failed_total{reason="cross_tenant"}[1m]) > 0` |
| GW-A04 | `increase(dh_gateway_auth_failed_total{reason="cnf_mismatch"}[10m]) >= 3` |
| GW-A05 | `increase(dh_gateway_sync_total{result="bad_signature"}[5m]) > 0` |
| GW-A06 | `dh_gateway_waf_mode == 2` |
| GW-A07 | `dh_gateway_valkey_up == 0` kéo dài 1 phút |
| GW-A08 | `max(dh_gateway_jwks_age_seconds) > 3600`, hoặc `dh_gateway_opa_decision_total{decision="error"}` tăng liên tục |
| GW-A09 | `dh_gw_cp_node_sync_state{state=~"LAGGING|FAILED"} > 0` quá 2 phút |
| GW-A10 | `dh_gw_cp_cert_days_remaining < 7` |
| GW-A11 | `dh_gateway_synthetic_up == 0` hai chu kỳ liên tiếp |
| GW-A12 | Tỉ lệ dùng hạn mức tenant trên 80% liên tục 1 phút (từ `dh_gateway_requests_total` so `gw.tenantRateLimit.perSecond`) |
| GW-A13 | `increase(dh_gateway_accesslog_dropped_total[5m]) > 0` |

: Luật cảnh báo và biểu thức mô tả

## 11. Hiệu năng và vận hành

**Định cỡ** (GĐ-03-01, GĐ-03-06, theo D03-09 §5): tỉnh vừa 200 HTTT, khoảng 1.000 route mỗi tenant, cao điểm 300 lượt/giây; mỗi bản sao APISIX 1 vCPU và 1 GiB; Coraza chiếm thêm 30 đến 50% CPU; năng lực danh định 3.000 lượt/giây trên 3 bản sao mỗi cửa (NFR-03-003 chỉ đòi ≥ 1.000). `dh-sync` 50 mCPU, 32 MiB; OPA sidecar 0,1 vCPU, 128 MiB. `dh-connect` thêm khoảng 0,3 vCPU cho module `gateway` ở trạng thái ổn định và đột biến CPU khi tổng hợp.

**Ngân sách độ trễ thêm của một lượt gọi** (NFR-03-001: p95 ≤ 50 ms, p99 ≤ 100 ms ở 300 lượt/giây; NFR-03-002). Bảng dưới là phân bổ ngân sách để thiết kế plugin và kiểm thử đo từng chốt; con số là mục tiêu thiết kế, kiểm chứng ở mục 12 (giả định, cơ sở: NFR-03-002 và SRS cũ).

| Chốt | Ngân sách p99 | Ghi chú |
|---|---|---|
| `dh-edge`, `client-control` | 0,5 ms | Xóa tiêu đề, vân tay chứng thư có bộ nhớ theo kết nối |
| `dh-ip-block` | 0,5 ms | Bộ đếm cục bộ, không mạng |
| Coraza (yêu cầu ≤ 32 KB) | 5 ms | NFR-03-002; tự hạ khi p99 vượt 15 ms |
| `dh-auth` (đủ 12 bước) | 2 ms | Chữ ký ES256 bằng OpenSSL, khóa đã phân tích |
| `dh-revocation`, `dh-kill-switch`, `dh-path-acl` | 1 ms | Bộ đệm 5 giây, cây tiền tố |
| `dh-limit` (một lượt Valkey) | 3 ms | NFR-03-002; ngắt mạch 50 ms khi Valkey chậm |
| `request-validation` | 2 ms | Phụ thuộc kích thước thân và lược đồ |
| `opa` | 2 ms | NFR-03-002; hết hạn 50 ms |
| Chặng `apisix-ext` sang `apisix-int` (chỉ lưu lượng Internet) | 3 ms | Thêm một bước mesh mTLS (Q03-21) |
| Tổng, đường chính | khoảng 16 ms (19 ms qua hai chặng) | Cộng dồn p99 nên là cận trên, dư so với p95 50 ms |

: Ngân sách độ trễ thêm theo chốt

**Thời gian lan truyền cấu hình** (NFR-03-008: mục tiêu ≤ 10 giây, yêu cầu ≤ 60 giây). Thời gian từ khi có thay đổi tới khi nút chạy cấu hình mới là tổng các bước: gom sự kiện 3 giây (bỏ ở đường ưu tiên như quay lui, tạm ngừng khẩn cấp), tổng hợp, kiểm tra, ký khoảng 2 giây cho một tenant 1.000 route (trần giả định 5 giây, GĐ-03-07), ghi bucket 0,5 giây, chờ chu kỳ kiểm tra con trỏ trung bình 2,5 giây (tối đa 5 giây), tải, kiểm, ghi, xác nhận 1,5 giây. Trung bình khoảng 9,5 giây và tối đa khoảng 15 giây với mặc định `gw.sync.pollSeconds` bằng 5; đạt mục tiêu 10 giây ở mức trung bình và vượt xa yêu cầu 60 giây. Hồ sơ cần p95 ≤ 10 giây đặt `gw.sync.pollSeconds` bằng 2, đổi lấy mỗi pod đọc con trỏ mỗi 2 giây (đọc một tệp nhỏ). Đường nhanh Valkey độc lập với con số này: ≤ 30 giây cho tạm ngừng, ≤ 15 giây thực tế cho thu hồi.

**Kích thước ảnh chụp và nạp lại** (NFR-03-017, Q03-24). Một route tối giản (tham chiếu `plugin_config_id` và `upstream_id`, ghi đè chỉ khi khác mặc định) chiếm khoảng 250 byte, nên 1.000 route khoảng 250 KiB (giả định, cơ sở: cấu trúc ở mục 3.4); hồ sơ `QM-CHUNG` khoảng 70.000 route khoảng 17 MiB, sát trần `gw.snapshot.maxBytes` 20 MiB. APISIX nạp lại toàn tệp khi tệp đổi nên chi phí nạp tăng theo kích thước; đo ở 1.000 và 70.000 route là mục xác minh X4. Nếu ở `QM-CHUNG` thời gian nạp lại gây giật độ trễ, đường lùi là tách nhóm APISIX theo cụm tenant (mỗi nhóm một ảnh chụp riêng), phải có ADR (đề xuất 3 ở "Đề nghị đồng bộ").

**Mở rộng và tắt an toàn** (NFR-03-018, 024). HPA theo CPU ngưỡng 60%, 3 đến 10 bản sao; `maxUnavailable: 1`; `topologySpreadConstraints` trải ≥ 2 vùng sẵn sàng; `PodDisruptionBudget` bảo đảm ≥ 2 bản sao khả dụng. Pod tắt theo trình tự: `preStop` đánh dấu không Ready 5 giây để bộ cân bằng tải rút, NGINX `quit` hoàn tất yêu cầu đang xử lý trong ≤ 30 giây (`terminationGracePeriodSeconds: 45`). Gateway không giữ trạng thái phiên, nên mở rộng ngang không cần di chuyển dữ liệu; trạng thái chung chỉ ở Valkey và có thể mất mà không mất cấu hình.

**Vận hành.** Sổ tay ở D06-03 cần có các quy trình sau, do thiết kế này đặt ra: xử lý nút `FAILED` hoặc `LAGGING` (đọc `dh_gateway_sync_total`, nhật ký `dh-sync`, hoàn nguyên bằng tay); Valkey mất và dựng lại khóa chặn; quay lui và bỏ giữ; xoay khóa ký ảnh chụp (thêm khóa mới vào ConfigMap trước, ký bằng khóa mới sau 24 giờ, gỡ khóa cũ sau 7 ngày); cập nhật bộ luật CRS (ảnh mới, kiểm thử hồi quy WAF, phát cuốn chiếu); gia hạn bộ CA khách và kiểm tra CRL; nâng cấp APISIX cuốn chiếu với hai ảnh chụp song song (Q03-20); khôi phục khi cả `dh-connect` và bucket mất (nút chạy tiếp bằng ConfigMap tối đa 24 giờ rồi chuyển sang đường dựng lại từ Git).

**Khôi phục thảm họa** (ADR-034, SEC-71). Bucket `dh-platform-gateway` nhân bản sang site DR bằng cơ chế của Garage; Git cấu hình giữ toàn bộ lịch sử; khóa ký ở OpenBao DR. Khi chuyển site, bộ đếm phiên bản của site mới bắt đầu từ số lớn nhất đã biết cộng `gw.snapshot.drGap`; ảnh chụp đầu tiên ở site mới được tổng hợp lại từ nguồn (không dựa vào bucket nhân bản), kiểm tra, ký và phát trước khi mở lưu lượng, để không phụ thuộc vào độ mới của nhân bản. Valkey không sao chép sang DR (D03-09 §6.7); `ValkeyRebuilder` nạp lại khóa chặn từ PostgreSQL khi site mới lên.

## 12. Kiểm thử

Chiến lược kiểm thử theo ADR-038; mã ca kiểm thử (`TC-03-…`, `TS-03-…`) sẽ do D05-02-PH03 cấp. Bảng dưới là các mức và nội dung cần phủ, mỗi mức gắn với tiêu chí chấp nhận ở FRS mục 14 (số trong ngoặc).

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị Lua | Từng plugin Datahub: 12 bước của `dh-auth`, thuật toán cửa sổ trượt, bộ đếm cục bộ khi suy giảm, `dh-problem` suy ra mã, chuẩn hóa đường dẫn của `dh-path-acl`; thư viện `shdict`, `keys` | `busted`, `luacheck`; ngưỡng phủ dòng ≥ 80% (giả định, cơ sở: yêu cầu chung của D04-02) |
| Đơn vị Java | Invariant aggregate, `FourEyesGuard`, `PolicyPrecedenceResolver`, `CanonicalYaml` (cùng đầu vào cho cùng băm), mọi `ValidationRule`, `SecretFieldGuard` | JUnit 5, jqwik cho tính chất (băm không đổi khi đổi thứ tự đầu vào) |
| Đơn vị Go | `verify` (chữ ký, băm, phiên bản), `apply` (ghi nguyên tử, hoàn nguyên), `crl` | `go test`, bộ dữ liệu chữ ký sai |
| Kiến trúc | Luật Modulith của `gateway`; cấm tạo khóa Valkey ngoài `FastKeys`; cấm log `SecretPayload`-tương đương; cấm đọc tenant từ tham số | ArchUnit, Semgrep (CI-3) |
| Plugin trên NGINX | Từng plugin chạy trong APISIX thật với dữ liệu mẫu: thứ tự chốt, mã lỗi, tiêu đề; mỗi mã `ERR-03-101…130` có một ca chứng minh thân RFC 9457 | `Test::Nginx`, Docker |
| Thứ tự chốt | Với mỗi loại route (INT, EXT, `KEYLESS`, mTLS, `COMMON`), ghi lại thứ tự plugin thực chạy và so với bảng thứ tự thực thi ở mục 4.1 | Test::Nginx + khóa thử nghiệm ghi vết (X1) |
| Hợp đồng cấu hình | Mọi cấu hình plugin trong ảnh chụp mẫu qua lược đồ JSON xuất từ ảnh; ảnh chụp do `dh-connect` sinh được `dh-sync` và APISIX nạp thật (4) | Testcontainers APISIX + `dh-sync` |
| Tích hợp control plane | PostgreSQL 16 với RLS, Valkey 8 (cả chế độ cluster), OpenBao (transit), Garage, Kafka, Keycloak, Git cục bộ | Testcontainers |
| Hợp đồng OpenAPI, AsyncAPI | Tương thích ngược API, sự kiện | Spectral, oasdiff (CI-5) |
| Hỗn loạn | Tắt toàn bộ `dh-connect`, Argo CD, Git, bucket, Keycloak, giữ 24 giờ và lập lịch lại một pod (3); tắt Valkey giữa tải (6); tắt OPA; tắt một vùng sẵn sàng | Chaos Mesh trên môi trường thử; bản rút gọn 30 phút ở CI ban đêm |
| Tải | 300 lượt/giây cao điểm, 1.000 lượt/giây ≥ 30 phút, 900 lượt/giây có tràn 10 lần trong 30 giây; phát cấu hình dưới tải 2.000 lượt/giây có 0 lỗi (2); hai tenant song song (SEC-86); 1.000 và 70.000 route | k6, Gatling |
| WAF | Bộ payload OWASP (≥ 99% bị chặn ở mức đã chọn), lưu lượng sạch (< 0,1% chặn nhầm), hồi quy CRS, ngoại lệ và vá ảo (5) | `go-ftw`, bộ payload tự dựng |
| Bảo mật | Giá trị đánh dấu `DH-CANARY-…` ở thân, tham số, tiêu đề (7); chéo tenant; `X-DH-*` giả; `kid` lạ lặp lại; token `cnf` sai chứng thư; nạp ảnh chụp sai chữ ký, phiên bản lùi; ZAP; `testssl.sh` A+ (8) | D05-02-PH03, D05-04, ZAP, testssl.sh |
| Saga | Kết nạp HTTT, tạo consumer, gọi API ≤ 10 giây sau `IN_SYNC`, bù trừ (9) | Kịch bản liên PH-01 |
| Truy vết | Mỗi mục `LGC` ở FRS mục 11.1 có ca UAT (10) | D05-02-PH03 |

: Kiểm thử của PH-03

**Cổng phát hành.** Ảnh APISIX chỉ được phát hành khi: toàn bộ bộ kiểm thử plugin đạt, thứ tự chốt khớp bảng thứ tự thực thi ở mục 4.1, bộ payload WAF đạt ngưỡng, kiểm thử độ trễ đạt bảng ngân sách ở chương 11, ảnh ký cosign và quét Trivy sạch CRITICAL (SEC-55…57). `dh-connect` phát hành khi mọi `ValidationRule` có ca âm và dương, và ảnh chụp mẫu nạp được ở `Test::Nginx`.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình và các điều cần xác minh

Thiết kế dựa vào một số hành vi của APISIX 3.11 chưa được kiểm chứng ở repo. Vì vậy bước 0 là một đợt thử nghiệm ngắn (spike) trả lời bảy câu hỏi dưới đây trước khi viết plugin chính thức; nếu một câu trả lời khác dự kiến thì cập nhật bảng thứ tự 4.1 và, khi cần, ghi nhận vào ADR đề xuất.

| Mã | Điều cần xác minh với APISIX 3.11 | Nếu khác dự kiến |
|---|---|---|
| X1 | Pha và ưu tiên thực của từng plugin dựng sẵn; `_meta.priority` đổi được ưu tiên; `global_rules` chạy trước plugin của route; plugin Datahub ở pha `rewrite` chen được giữa plugin dựng sẵn; ngữ cảnh `dh_stage` dùng được ở pha lọc | Đổi vị trí chốt, bọc plugin dựng sẵn bằng lớp mỏng (mục 4.6) |
| X2 | `_meta.filter` điều khiển plugin wasm theo biến tự đăng ký `dh_waf_mode` | Dùng một plugin wasm và chỉ thị đổi theo `Host`; hoặc tự hạ bằng cách tắt route WAF |
| X3 | TLS theo SNI trong chế độ standalone: `ssl_protocols`, `client.ca`, `skip_mtls_uri_regex`, OCSP stapling | Dùng host riêng cho mTLS và TLS 1.2 (đã là mặc định thiết kế) và bỏ OCSP stapling |
| X4 | Nạp lại tệp standalone: thời gian, bộ nhớ, giữ kết nối với 1.000 và 70.000 route (Q338) | Tách nhóm APISIX theo cụm tenant |
| X5 | Coraza 0.5.0 với CRS 4.x: giới hạn thân quét, độ trễ ≤ 5 ms ở 32 KB, `SecRuleRemoveById` theo route | Nâng phiên bản Coraza, giảm `bodyScanBytes` |
| X6 | `file-logger` với `log_format` tùy biến và biến `ctx.var.dh_*`; `prometheus` với nhãn tùy biến | Ghi nhật ký bằng plugin Datahub riêng |
| X7 | Đọc tình trạng bộ kiểm tra sức khỏe từ plugin để trả lỗi nhanh khi mọi nút không khỏe (APISIX mặc định dùng lại toàn bộ nút) | Dùng `api-breaker` kết hợp `checks.passive` chặt và cấu hình `unhealthy.http_statuses` |

: Điều cần xác minh với APISIX 3.11

| Bước | Nội dung | Phụ thuộc |
|---|---|---|
| 0 | Spike xác minh X1…X7 trên ảnh APISIX 3.11; chốt thứ tự chốt; quyết định ADR đề xuất | `deploy/apisix` hiện có |
| 1 | Khung module `gateway`; mô hình miền; bộ tổng hợp, kiểm tra, ký, phát; `dh-sync` và điểm chuyển tiếp; thay `ApisixRouteWriter`; plugin `dh-edge`, `dh-problem`, `dh-auth`; chuyển consumer (FR-03-039…046, 012…017) | OpenBao transit, Garage, PH-01, PH-02 |
| 2 | `dh-limit` và đường Valkey; `dh-revocation`, `dh-kill-switch`, đường nhanh ở control plane; `dh-path-acl`; OPA (FR-03-018…027, 036, 047) | Valkey, PH-12 |
| 3 | `dh-ip-block`, Coraza hai chế độ, `dh-waf-guard`, ngoại lệ bốn mắt; chứng thư, CRL, ngoại lệ TLS (FR-03-001…007, 009, 011, 038, 049) | cert-manager, PH-13 |
| 4 | Định tuyến, upstream, kiểm tra sức khỏe, WebSocket, phiên bản song song; quan sát, nhật ký, nút, bảng điều khiển; tham số; nhập hệ cũ (FR-03-028…033, 035, 045, 050…056, 059) | PH-13 |
| 5 | Kiểm thử hỗn loạn 24 giờ, kiểm thử tải, kiểm thử bảo mật, thẩm định cấp độ 3 | Môi trường thử, D05-02-PH03 |
| 6 | Đợt 2: vá ảo, CORS, ghi đè hạn mức, điều tiết, chuyển tiếp tenant, chạy thử, báo cáo sử dụng (FR-03-008, 010, 024, 027, 037, 057, 058) | Bước 1 đến 5 |
| 7 | Đợt 3: gRPC (FR-03-034) nếu có nhu cầu (Q03-07) | |

: Lộ trình

### 13.2. Rủi ro

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Bốn plugin bổ sung và sáu plugin thay thế làm tăng khối lượng mã Lua phải bảo trì (ước tính khoảng 3.000 đến 4.000 dòng, giả định) và thiếu người rành Lua | Cao | Thư viện dùng chung `plugins/dh/`; bộ kiểm thử `busted` và `Test::Nginx` đủ dày; rà soát chéo; đường lùi về plugin dựng sẵn cho từng chốt (Q03-23) |
| Hành vi APISIX 3.11 khác giả định ở X1…X7 | Cao | Bước 0 spike trước khi viết plugin chính thức |
| Coraza cộng thêm độ trễ và CPU hơn dự kiến | Trung bình | Tự hạ về `DETECT` khi p99 quá ngưỡng; ngân sách đo ở bước 3; điều chỉnh mức hoang tưởng |
| Ảnh chụp quá lớn ở `QM-CHUNG`, nạp lại tệp gây giật | Trung bình | Đo ở X4; đường lùi tách nhóm APISIX theo cụm tenant |
| `dh-sync` là thành phần Go mới, có lỗi sẽ chặn nạp cấu hình | Trung bình | Chương trình nhỏ, kiểm thử với dữ liệu sai chữ ký và hỏng nửa chừng; nạp lại bằng ConfigMap khi sidecar chết (pod khởi động lại) |
| Điểm chuyển tiếp ảnh chụp ở Z2 mở thêm cổng | Thấp | Chỉ đọc, `AuthorizationPolicy` theo SPIFFE, `apisix-ext` vẫn tự xác minh chữ ký (Q03-21) |
| Mất `state.json` khi pod lập lịch lại làm mất chống nạp lùi qua nhiều đời pod | Thấp | Khởi động lấy số lớn nhất từ ConfigMap và bucket; kẻ tấn công không thể đưa bản cũ có chữ ký hợp lệ vào cả hai nơi mà không có quyền ghi bucket và Git |
| Valkey mất làm hạn ngạch dài hạn tạm kém chính xác và mất cảnh báo ngưỡng | Thấp | Suy giảm có kiểm soát; số liệu đúng lấy từ ClickHouse (Q03-12) |
| Một nút bị hạ WAF tự động rồi quên phục hồi | Thấp | Tự phục hồi sau 5 phút p99 tốt; cảnh báo GW-A06 và chỉ số `dh_gateway_waf_mode` hiển thị ở bảng điều khiển |
| Hạn mức cục bộ khi suy giảm sai lệch tới `số bản sao − 1` lượt do làm tròn lên | Thấp | Ghi rõ; chỉ tác động tần suất ngắn hạn |

: Rủi ro

### 13.3. Câu hỏi mở

> **Câu hỏi mở Q03-20:** Nâng cấp cuốn chiếu APISIX hoặc plugin cần ảnh chụp theo từng phiên bản ảnh (`apisixImage`); thiết kế sinh song song hai ảnh chụp trong thời gian chuyển giao (mục 4.8). Cần xác nhận với vận hành thời gian chuyển giao tối đa chấp nhận (đề xuất 24 giờ) và việc kiểm thử hai ảnh chụp song song có thành chi phí phát hành chính hay không.

> **Câu hỏi mở Q03-21:** Thiết kế chạy gateway hai chặng cho lưu lượng Internet (`apisix-ext` chỉ chạy chốt biên, chuyển sang `apisix-int` qua cổng 8444) vì vùng Z1 chỉ được chuyển tiếp sang Z2 (SEC-13), và dùng điểm chuyển tiếp ảnh chụp ở Z2 vì `apisix-ext` không với tới bucket Z5. D03-09 §4.4 và FR-03-038 nói `apisix-ext` áp chuỗi chốt đầy đủ. Cần kiến trúc sư hạ tầng và ATTT xác nhận hai điểm này, hoặc cho phép ngoại lệ mạng (Z1 tới Valkey, OPA, Keycloak, bucket) để chạy đủ chuỗi ở `apisix-ext`, và chấp nhận thêm khoảng 3 ms cho chặng thứ hai.

> **Câu hỏi mở Q03-22:** `dh-sync` viết bằng Go là ngôn ngữ thứ hai ngoài Java và Lua của dự án. Cần quyết định: giữ Go (nhỏ, tĩnh, bộ nhớ vài chục MiB), hay viết bằng Java Quarkus native (thống nhất ngôn ngữ, nặng hơn khoảng 3 đến 5 lần bộ nhớ), hay đặt bộ nạp trong chính APISIX bằng Lua (không thêm tiến trình, nhưng gộp lỗi vào tiến trình phục vụ). Đề xuất giữ Go và ghi ADR.

> **Câu hỏi mở Q03-23:** Thiết kế thay `jwt-auth`, `openid-connect`, `limit-count`, `limit-conn`, `limit-req`, `consumer-restriction` bằng `dh-auth`, `dh-limit`, `dh-ip-block` và thêm `dh-edge`, `dh-problem` (mục 4.1), viết bằng Lua trực tiếp (đóng một phần Q03-11 của FRS: không dùng Go plugin runner vì thêm IPC mỗi lượt gọi, không dùng proxy-wasm cho logic nghiệp vụ vì khó truy cập Valkey và shared dict). Cần hội đồng và kiến trúc sư xác nhận hướng này, người chịu trách nhiệm bảo trì mã Lua, và ngưỡng để quay về plugin dựng sẵn (đề xuất: nếu đo thấy p99 của chốt vượt gấp đôi ngân sách ở chương 11).

> **Câu hỏi mở Q03-24:** Ảnh chụp ở `QM-CHUNG` (khoảng 70.000 route) ước khoảng 17 MiB, sát trần 20 MiB của `gw.snapshot.maxBytes` (giả định), và APISIX nạp lại cả tệp khi đổi. Cần số đo ở bước 0 (X4) trước khi quyết định có tách nhóm APISIX theo cụm tenant hay không; liên quan Q338 của D03-09 và ADR đề xuất (3).

> **Câu hỏi mở Q03-25:** Số bản sao để chia hạn mức cục bộ khi Valkey mất lấy từ `EndpointSlice` của Service, cần cấp quyền `get`, `list` `endpointslices` cho service account của pod APISIX (SEC-53 chỉ cho phép khi có lý do). Cần ATTT chấp nhận, hoặc dùng số bản sao cố định theo hồ sơ (`QM-NHO` 3, `QM-VUA` 3, `QM-LON` 4, `QM-CHUNG` 8) cấp bằng biến môi trường, chấp nhận sai lệch khi HPA đổi số bản sao.

> **Câu hỏi mở Q03-26:** `dh-sync` tải CRL của CA khách mỗi giờ. Với CA do tỉnh chấp nhận, địa chỉ CRL có thể nằm ngoài mạng của Datahub, cần ghi vào danh sách egress (SEC-16). Cần ATTT và đầu mối tỉnh cung cấp danh sách CA và địa chỉ CRL (hoặc OCSP) khi khảo sát; nếu CA không có CRL công bố, mTLS với CA đó phải dựa vào vân tay đăng ký ở EN-03-04 chứ không dựa vào thu hồi theo CRL.

> **Câu hỏi mở Q03-27:** Hết hạn ngoại lệ WAF và hạn đăng ký sử dụng có hiệu lực qua ảnh chụp mới nên trễ tối đa khoảng 60 giây sau thời điểm hết hạn (`ExpiryScheduler` chạy mỗi phút, cộng thời gian lan truyền); riêng `until` của đăng ký được plugin kiểm tức thì. Cần ATTT xác nhận độ trễ này chấp nhận được với ngoại lệ WAF (mở lỗ hổng chậm tối đa 60 giây sau hạn), hoặc yêu cầu `dh-waf-guard` kiểm hạn ngay ở nút (cần chỉ thị Coraza có điều kiện thời gian, chưa chắc làm được ở X5).

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu dùng chung; các việc dưới đây để đợt đồng bộ cuối thực hiện hoặc để các luồng phân hệ khác tiếp nhận.

| Tài liệu | Đề nghị |
|---|---|
| ADR (đề xuất, không tạo ở tập này) | (1) ADR về plugin APISIX do Datahub viết bằng Lua: danh mục mười plugin (`dh-edge`, `dh-ip-block`, `dh-waf-guard`, `dh-auth`, `dh-revocation`, `dh-kill-switch`, `dh-path-acl`, `dh-limit`, `dh-adaptive-throttle`, `dh-problem`), nguyên tắc thay plugin dựng sẵn, thứ tự chốt, bổ sung ADR-005 và trả lời Q03-11 (Q03-23). (2) ADR về bộ đồng bộ `dh-sync` bằng Go, định dạng ảnh chụp, điểm chuyển tiếp và hoàn nguyên có xác nhận (Q03-22). (3) ADR về kênh nhanh Valkey cho thu hồi token và tạm ngừng khẩn cấp, và về mô hình hai chặng `apisix-ext`, `apisix-int` (Q03-21). (4) ADR về mô hình mảnh tenant và bản ghép nền tảng ở `QM-CHUNG` (Q03-24, Q338). Dải còn trống: ADR-014…019, 024…029, 039, 074 |
| D03-01 §4.3 | Khối `apisix`: ghi hai chặng (`apisix-ext` chỉ chạy chốt biên, `apisix-int` chạy phần còn lại), `dh-sync` là thành phần của pod APISIX, danh mục plugin do Datahub viết (kể cả `dh-auth`, `dh-limit`, `dh-edge`, `dh-problem` ngoài sáu plugin đã nêu ở FRS); khối `dh-connect`: module `gateway` và các lớp chính ở mục 3.1 |
| D03-09 §4.4, §6.1 | §4.4: làm rõ `apisix-ext` chỉ chuyển sang `apisix-int` cổng 8444 và không chạy phần xác thực, hạn mức, OPA (Q03-21). §6.1: ghi cấu trúc bucket `snapshots/{site}/{version}/` với `manifest.json`, `manifest.sig`, `int.yaml`, `ext.yaml`, `shards/`, con trỏ `current`; thư mục Git `gateway/{site}/`; khóa ký `transit/keys/dh-gateway-snapshot`; `dh-sync` điền chứng thư, khóa riêng từ Secret; điểm chuyển tiếp ảnh chụp ở Z2; `AuthorizationPolicy` cho cổng 8444 và điểm chuyển tiếp; thêm `lua_shared_dict` (~114 MiB) và `dh-sync` (50 mCPU, 32 MiB) vào bảng định cỡ §5 |
| D03-07 | SEC-14, SEC-15: thêm quy tắc cho cổng 8444 và điểm chuyển tiếp ảnh chụp; SEC-25: ghi đường đẩy danh sách chặn là PH-12 gọi API-03-053, `dh-connect` ghi Valkey, plugin tra với bộ đệm 5 giây; SEC-24: kiểm tra khi phát cấu hình (CHK-06) bảo đảm 0 client dùng `client_secret` cho hợp đồng từ mức Hạn chế; SEC-36: nêu khóa ký ảnh chụp cấu hình gateway cùng nhóm với khóa ký bundle OPA |
| D02-03-PH03 (FRS) | Mục 2.4 bảng thứ tự chốt: ghi chốt 9 (OPA) và 10 (lược đồ) đổi chỗ vì pha plugin; FR-03-038 bước 5: làm rõ `apisix-ext` áp phần chốt biên và `apisix-int` áp phần còn lại; mục 8.2: ghi `gw.ip.headerTimeoutSeconds`, `gw.ip.bodyTimeoutSeconds` có hiệu lực ở mức nhóm cửa vào; FR-03-026 bước 2: làm rõ số bản sao lấy từ `EndpointSlice` hoặc giá trị cấu hình (Q03-25) |
| D03-03-PH03 (tập CSDL) | Bảng cho EN-03-01…15; `snapshot_counter` theo site; `revoked_token`; `tenant_hold`; khóa lũy đẳng `Idempotency-Key`; chính sách RLS có giá trị `PLATFORM` cho dữ liệu cấp nền tảng (mục 6); cột `detect_since` của chế độ WAF |
| D03-04-PH03 (tập API) | Nguồn chung `errors.json` cho ERR-03-101…130 sinh bảng mã lỗi và danh mục của `dh-problem`; lược đồ EVT-03-09 có `reason` (`cross_tenant`, `cnf_mismatch`, `bad_signature`, `waf_degraded`, `valkey_down`, `ip_blocked`); điểm đọc chuyển tiếp ảnh chụp là API nội bộ, không công bố |
| D04-01 | Quy ước mã Lua: `luacheck`, `busted`, `Test::Nginx`, cấm đọc tệp và DNS đồng bộ ở đường lượt gọi, danh mục thư viện dùng chung `plugins/dh/`; quy ước mã Go cho `dh-sync`; luật Semgrep cấm ghép tên khóa Valkey ngoài `FastKeys` |
| D04-02 | Cổng CI cho ảnh APISIX: xây ảnh kèm plugin, `Test::Nginx`, kiểm thử thứ tự chốt, xuất lược đồ JSON (`make schema-export`), ký cosign, quét Trivy |
| D06-03 (sổ tay vận hành, chưa viết) | Các quy trình ở mục 11 (nút `FAILED`, Valkey mất, quay lui và bỏ giữ, xoay khóa ký, cập nhật CRS, CRL, nâng cấp song song hai ảnh chụp) |
| Tập của PH-02, PH-01, PH-12, PH-13, PH-20 | PH-02: `PublishedApiQuery`, `PlanQuery`, `SubscriptionQuery` ở gói `catalog.api` (mục 2.3). PH-01: gọi `GatewaySyncStatusApi` ở gói `gateway.api`. PH-12: gói chính sách OPA có `dh/authz/{policyPackage}/allow`, claim `purpose` (Q03-04), khóa `ES256` hoặc `PS256` ở realm. PH-13: bộ nhận `filelog` và `redaction` của Collector cho `access.log`, luật `GW-A01…A13`. PH-20: trần hợp đồng cho CHK-12 |
| D00-04 §3.2 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi hợp nhất tập này; không có mã truy vết mới nào ngoài `Q03-20…27` |

: Đề nghị đồng bộ của tập SDD PH-03

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-SDD và quy chuẩn trình bày: Tóm tắt cho hội đồng thẩm định, giới thiệu, vị trí kiến trúc (hai chặng, vùng mạng), cấu trúc mã nguồn (module `gateway`, plugin Lua, `dh-sync`), 16 thành phần với bảng đặc tả 10 mục, 11 biểu đồ tuần tự, 11 máy trạng thái, đa tenant, bảo mật theo SEC, thử lại và mở hay đóng, tham số và cờ, chỉ số và cảnh báo, ngân sách hiệu năng, kiểm thử, lộ trình kèm bảy điều cần xác minh, rủi ro, 8 câu hỏi mở Q03-20…27 và Đề nghị đồng bộ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: máy trạng thái ở CSDL (§8.1), GatewayApplyPort và PublishedConfigApi (§2.3); chốt câu hỏi mở đợt đồng bộ: Q391 (kafka-logger, dh_connect_config_revision), Q413 (dh-authz), Q428, Q429, Q438, Q439, Q441 |
