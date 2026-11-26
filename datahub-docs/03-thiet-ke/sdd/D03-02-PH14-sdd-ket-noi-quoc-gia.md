---
ma_tai_lieu: D03-02-PH14
ten: Thiết kế chi tiết phần mềm phân hệ PH-14 Kết nối quốc gia
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration và dh-runtime, kiến trúc sư, cán bộ ATTT, vận hành, hội đồng thẩm định
phan_he: PH-14
mo_ta: Thiết kế chi tiết phần mềm của phân hệ Kết nối quốc gia gồm thành phần, cấu trúc mã, đường gọi chín chặng, ký số, hạn mức, đệm, chiều vào, đồng bộ, máy trạng thái, xử lý lỗi, bảo mật, quan sát, đủ để lập trình và kiểm thử.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH14 FRS; D02-04-PH14 Use case; D03-03-PH14 CSDL; D03-04-PH14 API; D03-07 ATTT; D03-10 Đa tenant; D04-01 Quy ước mã
---

# D03-02-PH14 · Thiết kế chi tiết Kết nối quốc gia

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả cách hiện thực 57 yêu cầu chức năng của [D02-03-PH14](../../02-yeu-cau/frs/D02-03-PH14-frs-ket-noi-quoc-gia.md): cổng ra duy nhất của tỉnh tới Nền tảng trao đổi dữ liệu quốc gia (NDXP), Nền tảng dữ liệu mở quốc gia (NDOP) và hệ thống đăng ký danh mục dịch vụ chia sẻ của Bộ. Thiết kế phải giữ được năm cam kết của FRS: không lộ thông tin xác thực quốc gia, không để hạn mức của trung ương làm ngưng dịch vụ công, mọi lượt khai thác truy vết được, chỉ tin dữ liệu quốc gia đã xác minh chữ ký, và đổi đặc tả của trung ương chỉ phải sửa bộ điều hợp.

**Phạm vi.** Phân hệ gồm module `national` của `dh-integration` (mặt phẳng điều khiển, Spring Boot 4 và Spring Modulith, schema `ph14_national`) và hồ sơ `national-gateway` của `dh-runtime` (mặt phẳng dữ liệu, Camel Quarkus 3.33.x) chạy hai vai trò từ cùng một ảnh: `gateway` nhận lưu lượng và `worker` chạy kiểm tra, đồng bộ, hàng chờ, làm mới chuỗi tin cậy. Tài liệu đặc tả 18 thành phần cùng mô hình miền, 10 sơ đồ trình tự, 12 máy trạng thái và các cơ chế nhất quán, thử lại, suy giảm khi phụ thuộc sự cố.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-03 và CMP-LAW-19 (Nghị định 278/2025/NĐ-CP, kết nối và chia sẻ dữ liệu), CMP-LAW-12 (Thông tư 13/2017, chờ đối chiếu), CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025), CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026, TCVN 14423:2026 cấp độ 3), CMP-LAW-16 (Luật An ninh mạng 116/2025), CMP-LAW-01 (Luật Dữ liệu số).

**Những điểm hội đồng cần lưu ý.**

1. **Mặt phẳng dữ liệu không nối PostgreSQL.** Cổng quốc gia chạy bằng ảnh chụp cấu hình có phiên bản, lưu ra đĩa nên sống được khi `dh-integration` hoặc `pg-core` ngừng; mọi bản ghi bền (giao dịch, mức dùng hạn mức, trạng thái hàng chờ) đi qua bộ đệm đĩa và Kafka tới các bộ tiêu thụ ở `dh-integration` ghi lũy đẳng theo mã giao dịch. Cấu hình có hiệu lực trong 30 giây không khởi động lại (NFR-14-026).
2. **Một đường gọi chín chặng cho mọi lượt.** HTTT, luồng PH-04, PH-07, hàng chờ bất đồng bộ và chiều vào cùng đi qua một chuỗi xử lý có thứ tự cố định: định danh, phân giải, mục đích, kiểm tra tham số, đệm, điều phối ra ngoài (định tuyến, hạn mức, token, ký, gửi), xác minh, chuẩn hóa, kết thúc. Kiểm tra mục đích luôn đứng trước đọc đệm nên đệm không là đường vòng qua kiểm soát (BR-14-015).
3. **Khóa riêng không rời OpenBao.** Ký số là gửi giá trị băm tới `transit/sign`; thông tin xác thực nền tảng chỉ ghi một chiều (cơ chế của PH-05) và cổng đọc bằng danh tính Kubernetes của đúng tenant; token nền tảng chỉ nằm trong bộ nhớ. Không ký được thì không gửi (BR-14-001).
4. **Hạn mức, đệm, ngắt mạch dùng Valkey với script nguyên tử.** Một script Lua kiểm nhiều bộ đếm rồi mới trừ, hoàn lại khi chưa gửi; ưu tiên dịch vụ thiết yếu và hoãn tác vụ nền theo mức dùng. Khi Valkey mất, cổng chuyển sang đếm cục bộ chia đều theo số bản sao, vẫn không bỏ kiểm tra.
5. **Chữ ký sai là sự cố an ninh, được cưỡng chế ngay ở cổng.** Đủ ngưỡng sự cố trong 10 phút thì cờ `SECURITY_HOLD` đặt ở Valkey và bộ nhớ cổng, chặn mọi lượt cần dữ liệu mới trước cả khi bản ghi sự cố kịp ghi vào PostgreSQL.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Yêu cầu chức năng hiện thực | 57 (FR-14-001…057) |
| Thành phần đặc tả khối 10 mục | 18 (mục 4.2 đến 4.19), cùng mô hình miền ở mục 4.1 |
| Sơ đồ trình tự | 10 (mục 5.1 đến 5.10) |
| Máy trạng thái có bảng chuyển | 12 (nền tảng, dịch vụ, đặc tả, cung cấp lại, chứng thư, sự cố chữ ký, giữ an ninh, xoay thông tin xác thực, giao dịch, yêu cầu bất đồng bộ, ngắt mạch, phiên đồng bộ) |
| Đơn vị triển khai | 2 (`dh-integration` module `national`, `dh-runtime` hồ sơ `national-gateway`) |
| Chỉ tiêu hiệu năng chủ đạo | chi phí thêm p99 ≤ 80 ms ở 500 lượt/giây (NFR-14-001); ký p99 ≤ 50 ms (NFR-14-002) |
| Câu hỏi mở của tập | 8 (Q14-20…27) |

: Con số chính của thiết kế chi tiết PH-14

## 1. Giới thiệu

### 1.1. Phạm vi và cách đọc

Tài liệu đi từ vị trí trong kiến trúc (chương 2), cấu trúc mã (chương 3), từng thành phần (chương 4), trình tự của các chức năng phức tạp (chương 5) tới đa tenant, bảo mật, máy trạng thái, cấu hình, quan sát, hiệu năng, kiểm thử và lộ trình (chương 6 đến 13). Mã ERR, BR, NFR là của [D02-03-PH14](../../02-yeu-cau/frs/D02-03-PH14-frs-ket-noi-quoc-gia.md); mã EVT, API và định nghĩa đầy đủ của lỗi thuộc D03-04-PH14; bảng CSDL thuộc D03-03-PH14 (hai tập này do luồng khác viết, tài liệu này chỉ dùng mã đã chốt ở FRS §9). Biện pháp ATTT dẫn mã `SEC-*` đã có ở [D03-07](../attt/D03-07-thiet-ke-attt.md), không tạo mới.

Quy ước về quyền: FRS §3.2 dùng mười hai động từ quyền `PERM-14-{động từ}`; D02-08 hiện mới có `PERM-14-read` và `PERM-14-admin`, mười quyền còn lại đã đề nghị bổ sung (xem "Đề nghị đồng bộ"). Ở các bảng dưới đây, cột quyền ghi riêng động từ (`service`, `route`, `approve`, `cert`, `quota`, `operate`, `sync`, `audit-read`, `audit-reveal`, `invoke`) với tiền tố `PERM-14-` được hiểu ngầm.

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| [ADR-001](../../00-chung/adr/ADR-001-spring-boot-modulith.md) | Spring Boot 4 và Modulith cho module `national` |
| ADR-002, ADR-010 | Camel Quarkus và YAML DSL; ở PH-14 chỉ dùng Java DSL cho thư viện nền |
| ADR-003 | PostgreSQL, RLS theo `tenant_id` |
| ADR-004 | Kafka cho sự kiện, hàng chờ và sổ giao dịch |
| ADR-005, ADR-033 | APISIX và WAF Coraza ở biên, điểm vào của chiều vào |
| ADR-006 | Keycloak và OPA cho xác thực, kiểm tra mục đích |
| ADR-012 | OpenBao: `kv` thông tin xác thực, `transit` ký và mã hóa, `pki` chứng thư mTLS |
| ADR-013 | Tách mặt phẳng điều khiển và mặt phẳng dữ liệu |
| ADR-030, ADR-031, ADR-032 | ATTT cấp độ 3, nhật ký chuỗi băm WORM, mã hóa trường bằng khóa theo tenant |
| ADR-041, ADR-042 | Mẫu chống trùng hai tầng và hộp gửi trong DU, dùng lại tinh thần cho hàng chờ và sổ giao dịch |
| ADR-046 | Mẫu duyệt bốn mắt chốt ở máy chủ (PH-14 dùng `FourEyesGuard` của thư viện chung) |
| [ADR-057](../../00-chung/adr/ADR-057-dong-bo-quoc-gia-qua-ph14.md) | PH-07 kéo danh mục quốc gia qua bốn thao tác của cổng tiếp hợp |
| ADR-061, ADR-062, ADR-063, ADR-066 | Catalog khớp runtime, thư viện nền Java, ảnh theo hồ sơ, DataMapper ở PH-04 |
| ADR-067, ADR-068 | Truy cập CSDL có kiểm soát, kho cấu hình Git theo tenant (PH-14 không dùng, nêu để loại trừ) |
| ADR đề xuất A, B, C, D | Chưa có số; nội dung ở mục "Đề nghị đồng bộ" (ký số bằng `transit`, kiểm soát mục đích ở cổng, phân bổ hạn mức kèm đệm gộp lượt trùng, mặt phẳng dữ liệu không nối PostgreSQL) |

: ADR áp dụng cho PH-14

### 1.2. Người đọc, thuật ngữ và tài liệu tham chiếu

Bảng đầu chỉ ra mỗi nhóm người đọc nên mở chương nào; các bảng sau giải thích thuật ngữ kỹ thuật mới và dẫn các tài liệu tham chiếu.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-integration` | Chương 3, 4.1 đến 4.3, 4.9, 4.10, 4.15 đến 4.19, 6, 8, 9 |
| Kỹ sư `dh-runtime` (cổng quốc gia) | Chương 3, 4.3 đến 4.14, 5, 8.3 đến 8.6, 10 |
| Cán bộ ATTT | Chương 4.7 đến 4.9, 4.16, 7 |
| Vận hành | Chương 8.6, 9, 10, 11 |
| Kiểm thử viên | Chương 4 (bảng đặc tả), 5, 8, 12 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 7, 13 |

: Người đọc và phần cần đọc

Thuật ngữ và chữ viết tắt dùng chung với FRS §1.4 và D00-01. Thêm các thuật ngữ kỹ thuật dưới đây.

| Thuật ngữ | Giải thích |
|---|---|
| Chặng | Một bước của đường gọi chung `InvocationPipeline`; có tên cố định, có chỉ số và span riêng |
| Ảnh chụp cấu hình (`ConfigSnapshot`) | Đối tượng bất biến chứa toàn bộ cấu hình PH-14 của một tenant ở một phiên bản; cổng thay nguyên khối, không sửa từng phần |
| Bộ đệm đĩa (`LedgerSpool`) | Tệp nhật ký ghi trước ở đĩa tạm của pod, giữ sự kiện và bản ghi giao dịch chưa gửi được lên Kafka |
| Single-flight | Gộp các lượt trùng khóa đệm đến cùng lúc thành một lượt gọi thật |
| `SECURITY_HOLD` | Cờ giữ an ninh của nền tảng: từ chối mọi lượt cần dữ liệu mới tới khi Cán bộ ATTT giải trừ |
| Vai trò `gateway`, `worker` | Hai cách chạy cùng một ảnh `national-gateway`; chọn bằng cấu hình `dh.national.role` |

: Thuật ngữ kỹ thuật dùng trong tài liệu

Tài liệu tham chiếu: [D03-01 SAD](../D03-01-sad.md) §4 và §7; [D03-07 ATTT](../attt/D03-07-thiet-ke-attt.md); [D03-10 Đa tenant](../D03-10-thiet-ke-da-tenant.md); [D03-09 Hạ tầng](../ha-tang/D03-09-ha-tang-trien-khai-dr.md); [D02-04-PH14 Use case](../../02-yeu-cau/use-case/D02-04-PH14-use-case-ket-noi-quoc-gia.md); mẫu cùng loại [D03-02-PH05](D03-02-PH05-sdd-bo-dieu-hop.md) và [D03-02-PH04](D03-02-PH04-sdd-tich-hop.md), nơi định nghĩa thư viện nền, bí mật một chiều và khung chín chặng của luồng.

### 1.3. Cấu trúc tài liệu

Tài liệu gồm mười ba chương theo thứ tự người đọc cần: từ vị trí trong kiến trúc, cấu trúc mã, thành phần, trình tự tới vận hành và lộ trình.

| Chương | Nội dung |
|---|---|
| 2 | Vị trí trong kiến trúc: đơn vị triển khai, sơ đồ thành phần, phụ thuộc, hiện trạng mã |
| 3 | Cấu trúc mã nguồn: gói, luật phụ thuộc, giao diện công bố, DTO |
| 4 | Thiết kế chi tiết mô hình miền và 18 thành phần, mỗi thành phần một bảng đặc tả 10 mục |
| 5 | Mười sơ đồ trình tự của chức năng phức tạp |
| 6 | Đa tenant trong mã nguồn |
| 7 | Bảo mật, đối chiếu `SEC-*` và mô hình đe dọa |
| 8 | Máy trạng thái, nhất quán, thử lại, phân loại lỗi, suy giảm |
| 9 | Tham số và cờ tính năng theo tenant |
| 10 | Quan sát: chỉ số, log, vết |
| 11 | Hiệu năng và vận hành |
| 12 | Kiểm thử |
| 13 | Lộ trình, rủi ro, câu hỏi mở |

: Cấu trúc tài liệu

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-14 có mặt ở hai đơn vị triển khai theo SAD §4: phần quản trị ở `dh-integration`, phần xử lý lưu lượng ở `dh-runtime`. Hai phần không gọi nhau trên đường đi của một lượt gọi; chúng giao tiếp bằng ảnh chụp cấu hình (control tới data) và bằng Kafka (data tới control).

| Thành phần | DU | Vùng | Ghi chú |
|---|---|---|---|
| Module `national` (API, nghiệp vụ, bộ tiêu thụ sổ giao dịch, bộ phát hiện bất thường) | `dh-integration` | Z3 | Chung DU với module `flow` (PH-04), `adapter` (PH-05), `event` (PH-10); khác module Modulith |
| Cổng quốc gia, vai trò `gateway` | `dh-runtime`, hồ sơ `national-gateway` | Z4 | Một Deployment mỗi tenant, ≥ 3 bản sao trải ≥ 2 nút (NFR-14-012), JVM (mục 3.2) |
| Cổng quốc gia, vai trò `worker` | `dh-runtime`, hồ sơ `national-gateway` | Z4 | Một Deployment mỗi tenant, 2 bản sao, không nhận lưu lượng người dùng; chạy kiểm tra, đồng bộ, hàng chờ, chuỗi tin cậy |
| Egress gateway Istio | Hạ tầng | Z4 | `ServiceEntry` theo FQDN của NDXP, NDOP, hệ thống đăng ký (SEC-16); chỉ hai Deployment trên được ra |
| APISIX | `apisix-int` (Z2) cho HTTT, `apisix-ext` (Z1) cho chiều vào | Z1, Z2 | Chấm dứt mTLS của chiều vào, WAF, giới hạn tần suất |
| OpenBao | Nền tảng | Z6 | `kv/dh/{tenant}/conn/*` (PH-05), `transit/keys/dh-{tenant}-nat-*`, `transit/keys/dh-{tenant}-pii`, `pki-tenant-{tenant}` |
| Valkey | Nền tảng | Z5 | Đệm, bộ đếm hạn mức, chống phát lại, khóa chống trùng, cờ `SECURITY_HOLD`; khóa có tiền tố `{tenant}:nat:` (SEC-82) |
| Kafka | Nền tảng | Z5 | EVT-14-*, topic nội bộ của PH-14 (mục 4.3, 4.13, 4.16) |
| Ceph RGW, bucket `dh-nat-payload` | Nền tảng | Z5 | Nội dung bản tin mã hóa theo khóa tenant, vòng đời theo `14.txn.payload-retention-days` |
| `pg-core`, schema `ph14_national` | Nền tảng | Z5 | Do `dh-integration` sở hữu; mặt phẳng dữ liệu không nối |

: Đơn vị triển khai và vùng mạng của PH-14

Lưu lượng ra NDXP, NDOP và hệ thống đăng ký đi từ Z4 qua egress gateway; chính sách mạng Cilium chỉ cho pod mang nhãn `app.kubernetes.io/name=national-gateway` của đúng tenant ra các FQDN đó (BR-14-006). Kiểm thử hồi quy mạng (mục 12) chứng minh luồng PH-04 và `probe-jvm` của PH-05 không ra được các đích này.

### 2.2. Sơ đồ thành phần

Sơ đồ nhóm thành phần theo hai đơn vị triển khai và các kho dữ liệu. Mũi tên nét liền là lời gọi đồng bộ; đường ghi bền từ cổng về `dh-integration` luôn đi qua Kafka.

```{.mermaid caption="Sơ đồ thành phần PH-14"}
flowchart TB
  subgraph DI["dh-integration · module national · Z3"]
    WEB["web<br/>REST /api/national/v1"]
    CAT["catalog<br/>Platform, Service, Spec, Exposure"]
    RCF["runtimeconfig<br/>SnapshotBuilder"]
    CER["cert<br/>CertificateService, TrustAnchors"]
    QPO["quota<br/>QuotaPolicyService"]
    INB["inbound<br/>EndpointService"]
    SYP["sync<br/>SyncPlanner"]
    LED["ledger<br/>LedgerConsumer, RevealService"]
    ANO["anomaly<br/>AnomalyDetector"]
    MIG["migration<br/>ParallelRunService"]
    OBX["events<br/>Outbox"]
    WEB --> CAT & CER & QPO & INB & SYP & LED & MIG
    CAT --> RCF
    CER --> RCF
    QPO --> RCF
    INB --> RCF
    CAT --> OBX
    LED --> ANO
  end
  subgraph GW["dh-runtime · national-gateway · Z4"]
    subgraph G1["vai trò gateway"]
      PIPE["pipeline<br/>InvocationPipeline"]
      INBD["inbound<br/>InboundGateway"]
      ADP["adapter + translate"]
      SGN["sign<br/>Signer, Verifier"]
      QG["quota, cache, resilience"]
    end
    subgraph G2["vai trò worker"]
      ASY["async<br/>AsyncWorker"]
      SYW["sync<br/>SyncRunner"]
      HLT["health<br/>PlatformProbe"]
      TRS["trust<br/>CrlRefresher"]
    end
    CFG["config<br/>ConfigSyncer"]
    SPL["ledger<br/>LedgerSpool"]
  end
  APX["APISIX"] --> PIPE
  APX --> INBD
  PIPE --> ADP --> SGN
  PIPE --> QG
  RCF -->|"runtime-config có ETag"| CFG
  PIPE --> SPL
  SPL -->|"EVT-14-11 qua Kafka"| LED
  VK[("Valkey")]
  OB[("OpenBao")]
  PG[("pg-core<br/>ph14_national")]
  KF[("Kafka")]
  EG["Egress gateway"] --> NAT["NDXP, NDOP,<br/>hệ thống đăng ký"]
  QG --> VK
  SGN -->|"băm cần ký"| OB
  ADP --> EG
  CAT & CER & QPO & INB & LED --> PG
  CER -->|"đọc khóa công khai"| OB
  OBX --> KF
  SPL --> KF
  SYP -->|"lệnh worker"| KF
  KF --> ASY & SYW & HLT
```

Hình cho thấy ba đường. Đường cấu hình đi một chiều: các dịch vụ ở `dh-integration` ghi `ph14_national`, `SnapshotBuilder` dựng ảnh chụp có ETag, `ConfigSyncer` của cổng kéo về. Đường lưu lượng không đi qua `dh-integration`: APISIX tới `InvocationPipeline`, ra egress, về lại. Đường bền đi ngược: `LedgerSpool` đẩy sự kiện giao dịch lên Kafka, `LedgerConsumer` ghi PostgreSQL. `dh-integration` không có mũi tên ra NDXP và không có quyền `sign` ở OpenBao; nó chỉ đọc khóa công khai của chứng thư để kiểm tra khớp khóa.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng dưới liệt kê các module cùng đơn vị triển khai và các phân hệ khác mà PH-14 gọi hoặc được gọi, kèm cách gọi và mục đích; đây là căn cứ của luật phụ thuộc ở mục 3.5.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| Module `adapter` (PH-05), cùng DU | `national` gọi `adapter.api` | `AdapterReferenceApi.verify` (Modulith, trong tiến trình) | Kiểm tra kết nối `oauth2-client`, `mtls-client` của nền tảng (ERR-14-005) |
| Thư viện `vn.datahub.runtime.secret` (PH-05) | Cổng dùng | `ConnPropertiesFunction`, `ConnManifestCache`, `SecretVersionSelector` | Địa chỉ và thông tin xác thực nền tảng; xoay có giá trị chờ (FR-14-025) |
| PH-04 | PH-04 tới cổng; cổng tới PH-04 | Kamelet `dh-national-invoke`; chiều vào chuyển cho luồng qua mesh | Chiều ra của luồng; xử lý chiều vào (FR-14-041) |
| PH-02 | `national` gọi | REST nội bộ (hợp đồng chờ D03-04-PH02), sự kiện đã công bố | Cung cấp lại, danh sách dịch vụ chia sẻ (Q14-26) |
| PH-03 | PH-03 gắn tuyến | APISIX theo sự kiện của PH-02 | Tuyến API cung cấp lại; tuyến chiều vào theo EVT-14-13 |
| PH-07 | PH-07 gọi cổng; cổng đọc PH-07 | REST nội bộ API-14-079…083; `CatalogLookupApi` (đệm 5 phút) | Danh mục dùng chung quốc gia; danh mục mục đích, mã thủ tục hành chính |
| PH-09 | Cổng gọi | REST kiểm tra mục đích, kiểm tra lô; thời hạn 200 ms, đóng an toàn | FR-14-011, 044, 045 |
| PH-12 | Cổng đọc | JWKS Keycloak (làm mới 10 phút), bó OPA `national/*` | Xác thực token, kiểm tra mục đích |
| PH-13 | PH-14 phát | Chỉ số Prometheus `national_*`, EVT-14-* | Cảnh báo, SIEM |
| PH-18 | `national` đọc | `ParameterApi` có đệm 60 giây; ảnh chụp cấu hình mang giá trị đã giải | Tham số `14.*` |
| Hộp việc chung (FR-00-070) | `national` gửi | `TaskInboxApi` | Việc duyệt bốn mắt |
| PH-06 | `national` gọi (Đợt 3) | REST nội bộ | Cầu nối dữ liệu chủ (FR-14-044) |

: Phụ thuộc với module và phân hệ khác

Luật Modulith: `national` chỉ import `adapter.api`, `flow.api`; không import `*.internal` của module khác. Mặt phẳng dữ liệu không import gói nào của `dh-integration`; hợp đồng giữa hai phía là JSON của ảnh chụp cấu hình và lược đồ Apicurio của sự kiện, kiểm ở CI-5.

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện chưa có mã nào của PH-14, nên bảng dưới nêu những gì đã có ở phần liền kề và khoảng cách tới thiết kế, để kỹ sư biết phải xây mới chỗ nào và phụ thuộc kết quả của phân hệ nào.

| Hiện trạng repo | Thiết kế | Khoảng cách |
|---|---|---|
| Không có mã PH-14: tìm `NGSP`, `ndxp` trong mã Java, YAML, XML của `camel/`, `apps/control`, `apps/data` không có kết quả; phụ lục kết nối NGSP của hệ cũ chỉ là tài liệu | Module `national` và hồ sơ `national-gateway` xây mới | GAP-14-01: xây mới hoàn toàn, không có mã để di trú; chỉ nhập được cấu hình dịch vụ từ phụ lục (FR-14-056) |
| `apps/adapter-mgr` (PH-05) chỉ có loại `HTTP_MOCK` | Loại `oauth2-client`, `mtls-client` có chế độ `private_key_jwt` và giá trị chờ khi xoay | GAP-14-02: phụ thuộc kết quả PH-05 (đề nghị đồng bộ PH-05) |
| `camel/dancu`, `camel/datdai` gọi dịch vụ dân cư, đất đai trực tiếp, chưa có đệm, hạn mức, ký số | Gọi qua Kamelet `dh-national-invoke` khi dịch vụ là của quốc gia | GAP-14-03: luồng thật được chuyển ở đợt strangler, không thuộc PH-14 |
| Hệ cũ lưu Consumer Key, Secret dạng văn bản | Cấp lại khóa mới, không di trú (BR-14-034) | GAP-14-04: quy trình ở FR-14-025 và FR-14-055 |

: Hiện trạng mã và đường chuyển

## 3. Cấu trúc mã nguồn

### 3.1. Module `national` trong `dh-integration`

Module theo quy ước `vn.datahub.{du}.{module}`: chỉ gói `api` được module khác import; `internal` không lộ ra ngoài; `events` chứa bản ghi sự kiện và `OutboxPublisher`.

```text
vn.datahub.integration.national
├── api/                      # công bố cho module khác: NationalServiceQueryApi, NationalHealthQueryApi, DTO
├── web/                      # @RestController theo nhóm API-14-*, ProblemDetail ERR-14-*, @PreAuthorize PERM-14-*
├── internal/
│   ├── platform/             # aggregate NationalPlatform, PlatformStateMachine, CredentialRotationService
│   ├── service/              # aggregate NationalService, ServiceContract, SpecService, Reconciler
│   ├── exposure/             # ServiceExposure, ExposureService (gọi PH-02)
│   ├── routing/              # RoutingRule, RoutingSimulator, RoutingRuleService
│   ├── cert/                 # NationalCertificate, CertificateService, KeyMatchChecker, TrustAnchorService, SignatureIncidentService
│   ├── quota/                # QuotaPolicy, QuotaAllocation, QuotaPolicyService, UsageConsumer
│   ├── inbound/              # InboundEndpoint, AllowedSender, EndpointService
│   ├── sync/                 # SyncRun, SyncPlanner, SyncResultConsumer, OpenDatasetService
│   ├── ledger/               # LedgerConsumer, TransactionQuery, RevealService, EvidenceExporter, UsageAggregator
│   ├── health/               # HealthStateStore (nhận EVT-14-15 từ worker), DashboardService
│   ├── anomaly/              # AnomalyDetector (lịch 15 phút), AnomalyAlertService
│   ├── migration/            # ParallelRunService, LegacyImporter (nhập phụ lục NGSP, không thực thi)
│   ├── runtimeconfig/        # SnapshotBuilder, ConfigRevision, RuntimeConfigController (scope national.runtime-config)
│   ├── approval/             # FourEyesGuard dùng cho tám loại thay đổi (BR-14-022)
│   └── settings/             # Tham số 14.*, cờ bảo mật ★
└── events/                   # EVT-14-* record, OutboxPublisher
```

### 3.2. Hồ sơ `national-gateway` ở `dh-runtime`

Hồ sơ này là một ảnh Quarkus ở chế độ JVM (quyết định ở Q14-20), gom thư viện nền `vn.datahub.runtime.national` với các thư viện chung của PH-04 và PH-05. Cùng ảnh chạy hai vai trò; chọn bằng `dh.national.role=gateway|worker`, vai trò quyết định tuyến nào được nạp, tuyến còn lại không được đăng ký.

```text
dh-runtime/
├── dh-runtime-lib/
│   ├── vn.datahub.runtime.secret        # (PH-04, PH-05) ConnPropertiesFunction, SecretVersionSelector
│   ├── vn.datahub.runtime.tenant        # (PH-04) TenantGuard
│   ├── vn.datahub.runtime.authz         # (PH-04) OpaClient
│   └── vn.datahub.runtime.national
│       ├── config/                      # ConfigSnapshot, ConfigSyncer (ETag, đĩa), SnapshotHolder (AtomicReference)
│       ├── pipeline/                    # InvocationPipeline, Stage, InvocationContext, StageMarker
│       │   └── stage/                   # IdentifyStage, ResolveStage, PurposeStage, ValidateStage, CacheStage,
│       │                                #   DispatchStage, VerifyStage, NormalizeStage, FinalizeStage
│       ├── purpose/                     # PurposeGuard (OPA, PH-09, danh mục mục đích, mã thủ tục)
│       ├── route/                       # FederationRouter, RuleMatcher
│       ├── adapter/                     # NationalAdapter (SPI) và bảy bộ: lltp, hotich, bhxh, dvqhns, dkdn, vbqppl, dmdc
│       ├── translate/                   # MessageTranslator: RestTranslator, SoapTranslator, XsdValidator, ErrorClassifier
│       ├── auth/                        # TokenManager, AssertionSigner (private_key_jwt), TlsClientAuth
│       ├── sign/                        # TransitSigner, Canonicalizer, XmlDsigWriter, WsseWriter, JwsWriter,
│       │                                #   SignatureVerifier, TrustStore, CrlRefresher, ReplayGuard
│       ├── quota/                       # QuotaGate (script Lua), AllocationPolicy, PriorityGate, UsageSnapshotter
│       ├── cache/                       # ResponseCache, CacheKey, SingleFlight, StaleServer, GenerationCounter
│       ├── resilience/                  # BreakerRegistry, RetryPolicy, HoldFlag (SECURITY_HOLD)
│       ├── async/                       # AsyncAcceptor (gateway), AsyncWorker, UnknownResultReconciler (worker)
│       ├── inbound/                     # InboundGateway, SenderVerifier, InboundDispatcher, ReceiptSigner
│       ├── sync/                        # SyncRunner, CatalogSyncJob, MasterDataSyncJob, OpenDataSyncJob
│       ├── health/                      # PlatformProbe, HealthEvaluator, ProbeStep
│       ├── ledger/                      # LedgerWriter, LedgerSpool (tệp nhật ký ghi trước), PayloadVault, EventPublisher
│       └── error/                       # NationalErrorMapper → ERR-14-1xx
├── dh-runtime-kamelets/protocol/        # dh-national-invoke (Kamelet mỏng gọi cổng, PH-04 dùng)
└── profiles/
    └── national-gateway/                # camel-quarkus-platform-http, -kafka, -xmlsecurity, -cxf-soap, -jq; Santuario; Valkey client
```

Ảnh không chứa driver CSDL: thiếu `quarkus-jdbc-*` là một chốt chặn cấu trúc để mặt phẳng dữ liệu không nối PostgreSQL (kiểm bằng ArchUnit và bằng bước `jdeps` ở CI-3). Hồ sơ ghi `runtime-manifest.json` như mọi hồ sơ (FR-04-081), có thêm `role` ở phần cấu hình.

### 3.3. Giao diện công bố

Module `national` công bố hai giao diện cho PH-04 (gọi trong tiến trình), không công bố giao diện ghi. Hợp đồng REST cho phân hệ ở DU khác (PH-02, PH-07, PH-09) do D03-04-PH14 định nghĩa.

```java
package vn.datahub.integration.national.api;

public interface NationalServiceQueryApi {
  /** Dịch vụ quốc gia ACTIVE đã cung cấp lại, để PH-04 gợi ý khi thiết kế luồng. Chỉ trả mã và mô tả, không trả cấu hình. */
  List<NationalServiceOption> activeServices(TenantId tenant, ServiceGroup group);
}

public interface NationalHealthQueryApi {
  /** Mức sức khỏe hiện tại của nền tảng (đọc từ HealthStateStore). UNKNOWN nếu chưa có dữ liệu. */
  PlatformHealth health(TenantId tenant, String platformCode);
}

public record NationalServiceOption(String serviceCode, ServiceGroup group, OperationType operationType,
    Sensitivity sensitivity, boolean purposeRequired, boolean procedureCodeRequired, String contractVersion) {}
public record PlatformHealth(HealthLevel level, Instant checkedAt, Duration unhealthyFor) {}
```

Ở mặt phẳng dữ liệu, giao diện công bố cho Kamelet `dh-national-invoke` là một `Processor` duy nhất, `NationalInvokeProcessor`, nhận các header nội bộ của khung chín chặng (PH-04 §4.1) và gọi `/internal/national/v1/invocations` qua mesh với token dịch vụ; Kamelet không biết nền tảng, token hay chữ ký.

### 3.4. DTO chính

Các bản ghi và lớp dưới đây là hợp đồng giữa các chặng và giữa hai mặt phẳng; tên trường theo FRS §4.2 và các bảng dữ liệu vào ở chương 6 của FRS.

```java
public record InvocationRequest(
    @NotBlank @Pattern(regexp = "^[a-z][a-z0-9-]{2,62}$") String serviceCode,
    @Pattern(regexp = "^[a-z][a-zA-Z0-9]{1,40}$") String operation,
    @NotNull JsonNode params,
    @Pattern(regexp = "^[A-Z][A-Z0-9_]{2,40}$") String purposeCode,
    String procedureCode,
    @Size(min = 1, max = 64) String caseCode,
    boolean freshData) {}

public record InvocationResult(
    String transactionCode, String platformCode, JsonNode data, ResultMeta meta) {}
public record ResultMeta(boolean fromCache, Integer cacheAgeSeconds, boolean stale,
    boolean signatureVerified, Instant dataTime, long durationMs) {}

/** Tạo ở chặng identify, mang qua mọi chặng. Không chứa bí mật, token, nội dung bản tin dạng rõ ngoài vùng xử lý. */
public final class InvocationContext {
  TenantId tenant; String systemCode;          // từ token: claim tenant, azp
  String traceId; String transactionCode;
  ServiceView service; PlatformView platform;  // từ ConfigSnapshot
  Purpose purpose; Instant startedAt;
  TxnState state = TxnState.RECEIVED;
  QuotaTicket quotaTicket;                     // dùng để hoàn lại khi chưa gửi
  CacheOutcome cache;                          // HIT, MISS, STALE, BYPASS
  SigningOutcome signing; VerifyOutcome verify;
}

public record QuotaDecision(boolean allowed, String scope, double ratio, Instant resetAt,
    DeferReason deferReason, List<Integer> crossedLevels) {}
```

Bản ghi giao dịch gửi lên Kafka (EVT-14-11) dùng `TransactionRecord` với `payloadRef`, `payloadHash`, không có nội dung; lược đồ Avro ở Apicurio, chế độ BACKWARD (NFR-14-022).

Ảnh chụp cấu hình là JSON một tệp mỗi tenant, không chứa bí mật:

```json
{
  "tenant": "T68", "configVersion": 1842, "generatedAt": "2026-11-26T08:15:00Z",
  "platforms": [{ "platformCode": "ndxp-t68", "type": "NDXP", "state": "ACTIVE", "securityHold": false,
    "connectionCode": "ndxp-t68-oauth", "authMode": "PRIVATE_KEY_JWT", "specStatus": "OFFICIAL" }],
  "services": [{ "serviceCode": "lltp-tra-trang-thai", "platformCode": "ndxp-t68", "nationalServiceCode": "TP.LLTP.001",
    "group": "LLTP", "direction": "OUTBOUND", "operationType": "READ", "sensitivity": "SENSITIVE",
    "cacheable": false, "priority": "ESSENTIAL", "signingMode": "XMLDSIG", "verifyMode": "XMLDSIG",
    "purposeRequired": true, "procedureCodeRequired": true, "timeoutMs": 15000, "contract": { "version": "1.2", "schemaRef": "…" } }],
  "routingRules": [], "certificates": [{ "certCode": "ky-so-t68-2026", "purpose": "SIGNING", "state": "ACTIVE", "keyRef": "dh-T68-nat-sign-2026", "notAfter": "2027-09-30T00:00:00Z", "publicChain": "MIIC…" }],
  "trustAnchors": [], "quotas": [], "allocations": [], "inboundEndpoints": [], "settings": { "14.timeout.default-ms": 15000 }
}
```

### 3.5. Luật phụ thuộc và kiểm tra kiến trúc

ArchUnit chạy ở CI-3 và chặn hợp nhất khi vi phạm. Các luật dưới đây là chốt chặn cấu trúc cho bốn cam kết an toàn của phân hệ.

| Luật | Nội dung | Bảo vệ điều gì |
|---|---|---|
| AR-14-01 | Gói `vn.datahub.runtime.national` không import `vn.datahub.integration.*`, `java.sql`, `javax.sql`, Spring Data | Mặt phẳng dữ liệu không nối PostgreSQL |
| AR-14-02 | Chỉ gói `…national.sign` và `…national.auth.AssertionSigner` gọi đường dẫn `transit/sign` của OpenBao | Khóa ký chỉ dùng ở một nơi (BR-14-004) |
| AR-14-03 | Mọi kết nối HTTP, SOAP ra nền tảng quốc gia đi qua `OutboundClient`, chỉ `DispatchStage` được gọi `OutboundClient` | Không đường vòng qua hạn mức, ngắt mạch, ký, ghi giao dịch |
| AR-14-04 | `ResponseCache.get` chỉ gọi được từ `CacheStage`, và `CacheStage` đứng sau `PurposeStage` trong danh sách chặng (kiểm bằng kiểm thử cấu hình pipeline) | Đệm không là đường vòng qua ủy quyền (BR-14-015) |
| AR-14-05 | Lớp có hậu tố `Token`, `Credential`, `SignedMessage`, `PrivateKeyRef` không được là tham số của lời gọi `Logger.*`, `Span.setAttribute` | Không lộ bí mật qua log, vết (CC-SEC của D04-01) |
| AR-14-06 | Mọi `@RestController` của `national.web` có `@PreAuthorize("hasAuthority('PERM-14-…')")` hoặc `@PreAuthorize("hasScope('national.…')")` | Kiểm tra quyền ở máy chủ |
| AR-14-07 | Truy cập CSDL của `national.internal.*` chỉ qua `TenantAwareTransactionManager` | RLS luôn có hiệu lực (SEC-81) |
| AR-14-08 | Không gọi trực tiếp `Instant.now()`, `System.currentTimeMillis()`; dùng `Clock` được bơm | Kiểm thử được cửa sổ ký, hạn chứng thư, hạn mức theo giờ |
| AR-14-09 | `national.internal.*` không import `adapter.internal`, `flow.internal`, `event.internal` | Luật Modulith |

: Luật kiến trúc kiểm bằng ArchUnit

## 4. Thiết kế chi tiết từng thành phần

Mỗi thành phần mở đầu bằng bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế. Mã API, EVT, ERR lấy từ FRS §9; tên bảng CSDL dùng tên logic của FRS §4.2 (cột, kiểu, chỉ mục ở D03-03-PH14).

### 4.1. Mô hình miền

Mô hình miền chia hai nhóm. Nhóm cấu hình (nền tảng, dịch vụ, đặc tả, luật, chứng thư, hạn mức, điểm cuối) do `dh-integration` sở hữu và là nguồn của ảnh chụp cấu hình. Nhóm vận hành (giao dịch, phiên đồng bộ, sự cố, cảnh báo) do cổng sinh ra, `dh-integration` ghi lại. Sơ đồ chỉ nêu thuộc tính cần cho invariant.

```{.mermaid caption="Mô hình miền PH-14"}
classDiagram
  class NationalPlatform {
    +String platformCode
    +PlatformType type
    +Scope scope
    +String connectionCode
    +AuthMode authMode
    +SpecStatus specStatus
    +PlatformState state
    +boolean securityHold
    +activate(approver)
    +suspend(reason)
    +retire(reason)
  }
  class NationalService {
    +String serviceCode
    +String nationalServiceCode
    +ServiceGroup group
    +OperationType operationType
    +Sensitivity sensitivity
    +boolean cacheable
    +int cacheTtlSeconds
    +Priority priority
    +SigningMode signingMode
    +VerifyMode verifyMode
    +ReconcileLabel label
    +ServiceState state
    +changeControl(newPolicy)
  }
  class ServiceSpec {
    +String specVersion
    +SpecKind kind
    +String checksum
    +boolean breaking
    +SpecState state
  }
  class ServiceExposure {
    +String apiCode
    +String path
    +String contractVersion
    +Set responseFields
    +ExposureState state
  }
  class RoutingRule {
    +String matchServiceCode
    +ServiceGroup matchGroup
    +String primaryServiceCode
    +String fallbackServiceCode
    +boolean allowFallback
    +int priority
    +RuleState state
  }
  class NationalCertificate {
    +String certCode
    +CertPurpose purpose
    +String keyRef
    +Instant notAfter
    +CertState state
  }
  class QuotaPolicy {
    +Period period
    +long limit
    +String basisDocument
  }
  class QuotaAllocation {
    +String systemCode
    +long limit
    +double shareOfReserve
  }
  class InboundEndpoint {
    +String endpointCode
    +String path
    +String clientCertFingerprint
    +EndpointState state
  }
  class AllowedSender {
    +String senderCode
    +Set serviceCodes
  }
  class SyncRun {
    +SyncKind kind
    +SyncState state
    +int sent
    +int accepted
    +int rejected
  }
  class SignatureIncident {
    +IncidentKind kind
    +String transactionCode
    +IncidentState state
  }
  NationalPlatform "1" o-- "*" NationalService
  NationalService "1" *-- "*" ServiceSpec
  NationalService "1" o-- "0..1" ServiceExposure
  NationalService "*" <-- "*" RoutingRule
  NationalPlatform "1" o-- "*" NationalCertificate
  NationalPlatform "1" *-- "*" QuotaPolicy
  QuotaPolicy "1" *-- "*" QuotaAllocation
  NationalPlatform "1" o-- "*" InboundEndpoint
  InboundEndpoint "1" *-- "*" AllowedSender
  NationalPlatform "1" o-- "*" SyncRun
  NationalPlatform "1" o-- "*" SignatureIncident
```

Ba aggregate gốc là `NationalPlatform`, `NationalService`, `NationalCertificate`; các thực thể còn lại thuộc một trong ba hoặc đứng riêng với khóa ngoài. Invariant được kiểm trong aggregate trước khi ghi, không chỉ ở lớp `web`:

| Aggregate | Invariant | BR, ERR |
|---|---|---|
| `NationalPlatform` | Mã duy nhất trong tenant kể cả `RETIRED`; `ACTIVE` chỉ khi có kiểm tra kết nối đạt trong 24 giờ khớp phiên bản kết nối PH-05 và, nếu có dịch vụ yêu cầu ký, có chứng thư `ACTIVE` hoặc `EXPIRING` đúng mục đích | BR-14-022, ERR-14-002, 008, 037 |
| `NationalPlatform` | Duyệt bật bởi người khác người đề nghị và người sửa gần nhất; so sánh theo mã người dùng | BR-14-022, ERR-14-007 |
| `NationalPlatform` | `securityHold` chỉ đặt bởi cổng hoặc `SO`, chỉ giải trừ bởi `SO` khi không còn sự cố chữ ký `OPEN` | BR-14-003, ERR-14-004 |
| `NationalService` | `cacheable` không đi cùng `sensitivity = SENSITIVE` hoặc `operationType = WRITE`; `cacheTtlSeconds` ≤ `14.cache.max-ttl-seconds` | BR-14-014, ERR-14-038, 036 |
| `NationalService` | `ACTIVE` chỉ khi có `ServiceSpec` `ACTIVE` và nền tảng `ACTIVE`; `RETIRED` không chuyển đi đâu | BR-14-024, ERR-14-009 |
| `NationalService` | Đổi chính sách theo hướng giảm kiểm soát (mục 4.2) qua `FourEyesGuard`; các thay đổi khác áp ngay | BR-14-022 |
| `ServiceSpec` | Phiên bản `ACTIVE` bất biến; cùng `specVersion` khác `checksum` bị từ chối | ERR-14-010 |
| `RoutingRule` | Không trùng (điều kiện, `priority`) trong cùng trạng thái hoạt động; dự phòng chỉ cho `READ` và cùng nhóm dữ liệu; dịch vụ đích `ACTIVE` | BR-14-023, ERR-14-013, 014, 015 |
| `NationalCertificate` | Mỗi (nền tảng, mục đích) có tối đa một chứng thư `ACTIVE`; khóa riêng không có trong bảng, chỉ `keyRef`; kích hoạt qua người thứ hai | BR-14-004, 018, ERR-14-020 |
| `QuotaPolicy` | Có `basisDocument`; tổng `QuotaAllocation.limit` không vượt `limit` | BR-14-011, ERR-14-016, 018 |
| `InboundEndpoint` | Tenant xác định từ điểm cuối; bật chỉ khi có ít nhất một nguồn được phép và luồng PH-04 ánh xạ đã phát hành | BR-14-027, ERR-14-024, 039 |

: Invariant của các aggregate

### 4.2. Danh mục nền tảng, dịch vụ, đặc tả và cung cấp lại

::: dac-ta
**Mục đích.** Giữ nguồn sự thật cho nền tảng quốc gia, dịch vụ, hợp đồng, đặc tả có phiên bản, nhãn đối chiếu và việc cung cấp lại dịch vụ thành API của Datahub, để đổi đặc tả của trung ương chỉ phải sửa bộ điều hợp.

**Lớp chính.** `PlatformService`, `PlatformStateMachine`, `ServiceCatalogService`, `ControlReductionDetector`, `SpecService`, `SpecDiffer`, `Reconciler`, `ExposureService`.

**Đơn vị chạy.** `dh-integration` (module `national`); lấy đặc tả từ xa chạy ở `worker`.

**FR hiện thực.** FR-14-001…009.

**Giao diện vào.** API-14-001…023.

**Phụ thuộc ra.** Module `adapter` (`AdapterReferenceApi`), PH-02 (tạo API nháp), dịch vụ quét mã độc, Kafka (lệnh `spec.fetch` cho `worker`).

**Dữ liệu.** `national_platform`, `national_service`, `service_spec`, `service_exposure`, `reconcile_run`.

**Sự kiện.** EVT-14-01, EVT-14-02, EVT-14-14.

**Lỗi và xử lý.** Kết nối PH-05 sai loại: ERR-14-005; đặc tả không đọc được hoặc không an toàn: ERR-14-011; thay đổi phá vỡ: ERR-14-012; PH-02 ngừng: ERR-14-027 (không ghi nửa chừng, xem 5.10).

**Quan sát.** `national_platform_state`, `national_service_total{state,label}`, `national_spec_breaking_total`.
:::

Chi tiết thiết kế:

**Nền tảng.** `PlatformStateMachine` hiện thực máy trạng thái FRS §4.3 và nằm trong aggregate, mỗi lệnh có điều kiện kiểm ở máy chủ (bảng ở 8.1). `request-activation` chỉ chạy khi `ProbeResultStore` (cập nhật từ kết quả của `worker`) có lần kiểm tra `PASSED` trong 24 giờ khớp `connectionVersion` của PH-05 và `KeyMatch` của chứng thư ký còn hợp lệ nếu nền tảng có dịch vụ cần ký; `approve-activation` tạo lại các kiểm tra đó trong cùng giao dịch để chặn trường hợp điều kiện mất hiệu lực trong lúc chờ duyệt. Tạm ngừng ghi `state = SUSPENDED` và tăng `config_revision`; hiệu lực tại cổng ≤ 30 giây nhờ cơ chế ở 4.3.

**Dịch vụ và hướng giảm kiểm soát.** `ControlReductionDetector` so chính sách cũ và mới theo thứ tự "mức kiểm soát", một thay đổi theo hướng bên phải của bảng là giảm kiểm soát và phải qua duyệt bốn mắt trước khi vào ảnh chụp cấu hình.

| Thuộc tính | Chặt hơn | Lỏng hơn (cần duyệt) |
|---|---|---|
| `purposeRequired`, `procedureCodeRequired` | `true` | `false` |
| `signingMode`, `verifyMode` | khác `NONE` | `NONE` |
| `sensitivity` | `SENSITIVE` > `RESTRICTED` > `INTERNAL` > `PUBLIC` | hạ một bậc trở lên |
| `cacheable` | `false` | `true` |
| `cacheTtlSeconds`, `staleAllowed` | nhỏ hơn, `false` | lớn hơn, `true` |

: Hướng giảm kiểm soát của chính sách dịch vụ

**Đặc tả.** `SpecService` nhận OpenAPI 3.x, WSDL 1.1, XSD, JSON Schema. Quy trình gồm năm bước: quét mã độc (ERR-14-011 nếu không qua), phân tích trong `SecureXml` (cấm thực thể ngoài, cấm `xs:import` ra mạng, giới hạn độ sâu 50 và kích thước 5 MiB), chuẩn hóa rồi băm SHA-256 thành `checksum`, so khác biệt với bản `ACTIVE` bằng `SpecDiffer`, lưu `DRAFT`. `SpecDiffer` coi là phá vỡ khi bỏ phần tử, đổi kiểu, thêm trường bắt buộc, tăng `minOccurs`, đổi `xs:enumeration` theo hướng bỏ giá trị; trường hợp phá vỡ đòi duyệt bốn mắt và tăng số chính của hợp đồng (ERR-14-012). Kích hoạt đặc tả mới chuyển bản cũ sang `SUPERSEDED` và tăng `config_revision`; dịch vụ ở `DEPRECATED` trở về `ACTIVE` nếu đặc tả mới tương thích. Tải đặc tả từ xa (WSDL ở địa chỉ nền tảng) đi qua lệnh `spec.fetch` cho `worker` vì `dh-integration` không có đường ra; kết quả hỏng trả ERR-14-131 và giữ bản đã lưu.

**Đối chiếu.** `Reconciler` nhận danh mục hiện hành của NDXP từ tệp tải lên hoặc từ lệnh `catalog.fetch` của `worker`, ghép theo `nationalServiceCode` rồi sinh đề xuất `STILL`, `SPEC_CHANGED`, `DISCONTINUED`, `NEW`. Đề xuất chỉ có hiệu lực khi người dùng `apply`; áp `DISCONTINUED` đòi xác nhận riêng vì chuyển dịch vụ sang `RETIRED` và chặn gọi mới (BR-14-024).

**Cung cấp lại.** `ExposureService` kiểm điều kiện, kiểm `responseFields` chỉ gồm trường có trong đặc tả, rồi gọi PH-02 tạo API nháp; kết quả hiện thực qua sự kiện đã công bố của PH-02, không qua lời gọi đồng bộ (5.10). Danh sách `responseFields` được đưa vào ảnh chụp cấu hình dưới dạng danh sách cho phép JSONPath để `NormalizeStage` ở cổng lọc phản hồi, hiện thực tối thiểu hóa dữ liệu (BR-14-009).

### 4.3. Ảnh chụp cấu hình và nạp nóng

::: dac-ta
**Mục đích.** Đưa cấu hình, chứng thư công khai, luật định tuyến, hạn mức, tham số từ `dh-integration` tới mọi bản sao cổng trong 30 giây mà không khởi động lại, và giữ cổng chạy được khi mặt phẳng điều khiển ngừng.

**Lớp chính.** `ConfigRevisionService`, `SnapshotBuilder`, `RuntimeConfigController` (control); `ConfigSyncer`, `SnapshotHolder`, `SnapshotValidator` (cổng).

**Đơn vị chạy.** `dh-integration`; `dh-runtime` (cả hai vai trò).

**FR hiện thực.** FR-14-054; NFR-14-026, NFR-14-017.

**Giao diện vào.** API cấu hình runtime (đề xuất mã API-14-091, D03-04-PH14 xác nhận), scope `national.runtime-config`; EVT-14-01, 02, 03, 04, 08, 13 làm tín hiệu.

**Phụ thuộc ra.** OpenBao `transit` (ký ảnh chụp bằng khóa `dh-{tenant}-nat-config`), Kafka, đĩa tạm của pod.

**Dữ liệu.** `config_revision` (mỗi tenant và môi trường một dòng), tệp `/var/lib/dh/national/snapshot.json` ở pod.

**Sự kiện.** Nhận EVT-14-01…04, 08, 13; không phát sự kiện riêng.

**Lỗi và xử lý.** Ảnh chụp sai lược đồ hoặc sai chữ ký: giữ bản cũ, tăng `national_config_load_errors_total`, cảnh báo; control plane ngừng: dùng bản đĩa.

**Quan sát.** `national_config_version{tenant}`, `national_config_age_seconds`, `national_config_load_errors_total`.
:::

Chi tiết thiết kế:

`ConfigRevisionService.bump(tenant, env)` được gọi trong cùng giao dịch với mọi thay đổi của bảng có mặt trong ảnh chụp; một công việc đêm dựng lại ảnh chụp và so băm với bản đã phát để phát hiện chỗ quên `bump`. `SnapshotBuilder` dựng JSON (mẫu ở 3.4) theo cặp (tenant, môi trường) và ký tách rời bằng khóa `transit` riêng cho cấu hình; khóa này khác khóa chứng thư nên không vi phạm BR-14-004. Ảnh chụp không chứa bí mật: chỉ mã kết nối PH-05, `keyRef`, chứng thư công khai và neo tin cậy.

`ConfigSyncer` của cổng có hai đường kích hoạt: nhận bất kỳ sự kiện nào trong sáu chủ đề thay đổi (mỗi bản sao một nhóm tiêu thụ riêng, bắt đầu từ cuối) thì chờ 500 ms gom rồi kéo; và thăm dò mỗi 15 giây bằng `If-None-Match`. Hai đường cùng đảm bảo thời gian lan truyền xấu nhất khoảng 15 giây cộng thời gian kéo (< 3 giây ở quy mô 300 dịch vụ, 1.000 luật, nén gzip), trong ngưỡng 30 giây của NFR-14-026 kể cả khi Kafka chậm. Quy trình áp:

1. Kéo, kiểm tra chữ ký bằng khóa công khai đệm từ OpenBao, kiểm lược đồ JSON.
2. `SnapshotValidator` kiểm nhất quán chéo: mọi `platformCode`, `serviceCode`, `certCode` được tham chiếu đều có mặt; luật không trỏ tới dịch vụ không `ACTIVE`; không có hai chứng thư `ACTIVE` cùng mục đích.
3. Dựng chỉ mục (dịch vụ theo mã, `RuleMatcher`, bảng hạn mức) rồi thay `SnapshotHolder` bằng một lần gán `AtomicReference`; lượt đang chạy giữ tham chiếu bản cũ tới hết, nên một lượt không bao giờ thấy hai phiên bản.
4. Ghi ra đĩa bằng tệp tạm rồi đổi tên nguyên tử; thất bại ở bước 1 hoặc 2 giữ nguyên bản cũ.

Số phiên bản chỉ tăng: bản có `configVersion` nhỏ hơn bản đang giữ bị bỏ, trừ khi có lệnh đặt lại của `dh-integration` kèm số thế hệ mới (dùng khi khôi phục từ bản sao lưu). Khi khởi động, pod chỉ báo `ready` sau khi có ảnh chụp, từ control plane hoặc từ đĩa; bản đĩa cũ hơn 24 giờ vẫn được dùng nhưng bật cảnh báo `national_config_age_seconds` và hiện ở UI-14-01, vì dừng cổng quốc gia nặng hơn chạy bằng cấu hình cũ. Cờ `SECURITY_HOLD` do chính cổng đặt có đường riêng qua Valkey và bộ nhớ, không chờ ảnh chụp (mục 4.9).

### 4.4. Đường gọi chung chín chặng

::: dac-ta
**Mục đích.** Một chuỗi xử lý duy nhất, có thứ tự cố định, cho mọi lượt gọi ra quốc gia (HTTT, luồng PH-04, PH-07, hàng chờ bất đồng bộ, đồng bộ), để kiểm tra mục đích, đệm, hạn mức, ký, xác minh, ghi giao dịch không bao giờ bị bỏ qua hay đảo thứ tự.

**Lớp chính.** `InvocationPipeline`, `Stage` và chín lớp `IdentifyStage`, `ResolveStage`, `PurposeStage`, `ValidateStage`, `CacheStage`, `DispatchStage`, `VerifyStage`, `NormalizeStage`, `FinalizeStage`; `InvocationContext`, `IdempotencyStore`, `NationalErrorMapper`.

**Đơn vị chạy.** `dh-runtime`, hồ sơ `national-gateway`, vai trò `gateway` (và `worker` khi chạy yêu cầu từ hàng chờ, đồng bộ).

**FR hiện thực.** FR-14-010, 014, 015, và các bước gọi FR-14-011, 012, 024, 026, 027, 033, 035, 037, 038.

**Giao diện vào.** API-14-075 (`/internal/national/v1/invocations`); API cung cấp lại của PH-02 qua APISIX; Kamelet `dh-national-invoke`.

**Phụ thuộc ra.** OPA, PH-09, Valkey, OpenBao, egress gateway, Kafka (qua `LedgerSpool`).

**Dữ liệu.** Không ghi CSDL; đọc `SnapshotHolder`; ghi Valkey (đệm, bộ đếm, khóa chống trùng) và `LedgerSpool`.

**Sự kiện.** EVT-14-11 mỗi lượt kết thúc; EVT-14-07, 10, 06 tùy tình huống (4.9, 4.10, 4.12).

**Lỗi và xử lý.** Mọi ngoại lệ đi qua `NationalErrorMapper` thành `ProblemDetail` với ERR-14-*; chặng nào lỗi thì giao dịch ghi trạng thái cuối tương ứng (8.1) và hoàn lại hạn mức nếu chưa gửi.

**Quan sát.** `national_invocations_total{service,result}`, `national_stage_duration_seconds{stage}`, span `national.invoke` và `national.stage`.
:::

Chi tiết thiết kế:

`InvocationPipeline` là một danh sách chặng bất biến dựng khi khởi động; kiểm thử cấu hình khẳng định thứ tự và luật AR-14-04. Mỗi chặng nhận `InvocationContext` và trả `Continue`, `ShortCircuit(result)` hoặc ném `NationalException`. Hạn chót toàn lượt là `service.timeoutMs` (mặc định `14.timeout.default-ms`); mỗi lời gọi ra ngoài dùng phần thời gian còn lại, không đặt thời hạn độc lập.

| Chặng | Việc làm | Mã lỗi chính | Trạng thái giao dịch |
|---|---|---|---|
| 1 `identify` | Xác minh JWT bằng JWKS đệm (không gọi mạng trên đường đi), đối chiếu claim `tenant` với tenant của Deployment (`TenantGuard`), lấy `systemCode` từ `azp`, so tiêu đề `X-DH-Tenant` do APISIX gắn với claim (lệch: 403 và sự kiện an ninh), sinh `transactionCode`, nhận `traceparent` | 401, 403 theo FR-00 | `RECEIVED` |
| 2 `resolve` | Tra dịch vụ và nền tảng ở `SnapshotHolder`; kiểm `ACTIVE` và chưa `securityHold`; kiểm scope `national.invoke.{group}`; với `WRITE` mở bản ghi chống trùng ở `IdempotencyStore` | ERR-14-001, 117, 003, 116 | `RECEIVED` |
| 3 `purpose` | `PurposeGuard` (4.5): OPA, PH-09 với mức từ `RESTRICTED`, mã thủ tục và mã hồ sơ | ERR-14-106, 107, 132 | `REJECTED` nếu từ chối |
| 4 `validate` | Kiểm `params` theo JSON Schema của hợp đồng (đã biên dịch và đệm theo phiên bản); khoảng thời gian tối đa 31 ngày | ERR-14-108 | `REJECTED` |
| 5 `cache` | Với `READ`, `cacheable`, `freshData = false`: tra đệm (4.11); trúng thì rút gọn tới chặng 9 | — | `COMPLETED_CACHE` |
| 6 `dispatch` | Định tuyến, cổng ngắt mạch, hạn mức, token, dựng bản tin, ký, gửi, thử lại (vòng lặp mục 4.12) | ERR-14-105, 103, 104, 112, 113, 114, 101, 115 | `SENT`, `QUOTA_EXCEEDED`, `TIMEOUT` |
| 7 `verify` | Xác minh chữ ký phản hồi, chuỗi tin cậy, thời điểm ký, lặp (4.8) | ERR-14-109, 110, 111 | `SIGNATURE_FAILED` |
| 8 `normalize` | Phân loại lỗi nghiệp vụ, kiểm cấu trúc theo lược đồ đầu ra, chuyển về JSON chuẩn, lọc theo `responseFields` | ERR-14-102, 128 | `SUCCEEDED`, `FAILED` |
| 9 `finalize` | Lưu đệm, ghi bản ghi giao dịch vào `LedgerSpool`, đẩy nội dung mã hóa vào `PayloadVault` nếu bật, cập nhật chỉ số, đóng bản ghi chống trùng, trả kết quả | ERR-14-127 | giữ trạng thái cuối |

: Chín chặng của đường gọi chung

Có bốn điểm thiết kế cần nêu.

1. **Đệm sau mục đích, đệm trước hạn mức.** Chặng 3 luôn đứng trước chặng 5, nên một HTTT không được phép không thể đọc dữ liệu của người khác qua đệm (BR-14-015); chặng 5 đứng trước chặng 6 nên lượt trúng đệm không tiêu hạn mức (NFR-14-005). Khi nền tảng đang `securityHold`, chặng 2 vẫn cho lượt trúng đệm còn hạn đi tiếp nhưng không cho đọc đệm quá hạn, vì dữ liệu quá hạn chỉ được phép khi quốc gia lỗi, không khi nghi bị tấn công.
2. **Gộp lượt trùng (single-flight) bao quanh chặng 5 đến 8.** Lượt đầu tiên không trúng đệm giữ khóa `SingleFlight` theo khóa đệm và đi tiếp; các lượt cùng khóa chờ kết quả trong tối đa `timeoutMs` rồi đọc đệm. Khóa gồm một `CompletableFuture` cục bộ trong bản sao và một khóa Valkey `SET NX PX` cho các bản sao khác; người chờ ở bản sao khác thăm dò đệm mỗi 50 ms. Lượt dẫn đầu lỗi thì người chờ không kế thừa lỗi mà tự đi tiếp, tối đa một lượt tiếp quản mỗi khóa.
3. **Bản ghi chống trùng cho thao tác ghi.** `IdempotencyStore.begin` đặt `SET NX` với giá trị `{hash chuẩn hóa JCS của yêu cầu, trạng thái IN_PROGRESS}` trong 24 giờ. Cùng khóa, cùng nội dung, đang chạy: trả `202` với `transactionCode` cũ và `Retry-After`. Đã xong: trả lại đúng kết quả đã lưu (giữ mã hóa 24 giờ, không phải nội dung gốc ở nhật ký). Khác nội dung: ERR-14-116. Khi Valkey không khả dụng, thao tác ghi bị chặn với ERR-14-127 thay vì chạy không có bảo đảm chống trùng (Q14-27).
4. **Hoàn lại hạn mức.** `QuotaTicket` trong `InvocationContext` ghi các bộ đếm đã trừ; chặng 6 hoàn lại khi lỗi xảy ra trước lúc gửi (không ký được, không lấy được token, ngắt mạch, hết hạn mức ở bộ đếm khác trong cùng script); sau khi bản tin đã rời egress, lượt kể cả lỗi vẫn được tính (BR-14-012, FR-14-033 bước 4).

`transactionCode` có dạng `{TENANT}-{yyyyMMdd}-{10 ký tự}` (ví dụ `T68-20261126-0000184320`). Dãy số lấy từ `INCR` Valkey mỗi tenant mỗi ngày; khi Valkey mất, dùng 10 ký tự cuối của ULID để không trùng giữa các bản sao. Mã này làm mã đối soát với trung ương (BR-14-020).

Lỗi trả theo RFC 9457 `application/problem+json`: `type` là `urn:dh:err:ERR-14-104`, `title`, `status`, `detail` (câu tiếng Việt có thể hiển thị cho cán bộ HTTT), `traceId`, `transactionCode`, và trường riêng của mã (ví dụ `resetAt`, `cache.available` với ERR-14-104). `detail` không bao giờ chứa nội dung kỹ thuật của trung ương hay thông tin cấu hình nội bộ.

### 4.5. Kiểm tra mục đích và định tuyến

::: dac-ta
**Mục đích.** Vì cả tỉnh dùng chung một tài khoản NDXP, cổng phải là nơi duy nhất quyết định HTTT nào được tra gì vì mục đích gì (chặng 3), và nơi duy nhất quyết định lượt đi tới nền tảng, dịch vụ nào (chặng 6).

**Lớp chính.** `PurposeGuard`, `OpaPurposeClient`, `PrivacyCheckClient`, `ProcedureCatalogCache`, `FederationRouter`, `RuleMatcher`; ở control: `RoutingRuleService`, `RoutingSimulator`.

**Đơn vị chạy.** `dh-runtime` (`gateway`); `dh-integration` cho quản lý luật.

**FR hiện thực.** FR-14-011, 012, 013.

**Giao diện vào.** Chặng 3 và 6 của đường gọi; API-14-024…028.

**Phụ thuộc ra.** OPA (sidecar, 200 ms), PH-09, PH-07 (`CatalogLookupApi`), `ConfigSnapshot`.

**Dữ liệu.** `routing_rule`; bản đệm danh mục mục đích và mã thủ tục trong bộ nhớ.

**Sự kiện.** EVT-14-03 khi luật đổi; chuyển hướng dự phòng ghi trong EVT-14-11.

**Lỗi và xử lý.** OPA hoặc PH-09 không khả dụng: ERR-14-132, từ chối an toàn; không luật khớp: ERR-14-105; luật trùng: ERR-14-013.

**Quan sát.** `national_purpose_decisions_total{decision,reason}`, `national_fallback_total`, `national_purpose_check_duration_seconds`.
:::

Chi tiết thiết kế:

**`PurposeGuard`.** Đầu vào gồm `tenant`, `systemCode`, `serviceCode`, `group`, `sensitivity`, `purposeCode`, `procedureCode`, `caseCode`, giờ gọi. Các bước theo thứ tự rẻ trước, đắt sau: (1) kiểm định dạng `procedureCode` theo mẫu của dịch vụ và `caseCode` (1 đến 64 ký tự) khi `procedureCodeRequired`; (2) gọi OPA sidecar với dữ liệu đăng ký sử dụng của HTTT (bó dữ liệu do PH-12 dựng từ PH-02, làm mới theo sự kiện) và khung giờ `14.purpose.allowed-hours`; (3) với `sensitivity` từ `RESTRICTED`, gọi PH-09 hỏi "mục đích có trong sổ hoạt động xử lý và có cơ sở pháp lý hoặc chấp thuận không"; kết quả cho phép được đệm 60 giây theo (tenant, hệ thống, dịch vụ, mục đích) để giữ chi phí dưới ngưỡng 80 ms của NFR-14-001, kết quả từ chối không đệm; (4) kiểm `procedureCode` thuộc danh mục thủ tục của PH-07 bằng bản đệm bộ nhớ 5 phút, PH-07 ngừng thì dùng bản đệm tối đa 24 giờ. OPA hoặc PH-09 quá 200 ms hoặc lỗi thì ném ERR-14-132; không có chế độ "mở khi lỗi". Quyết định và lý do được ghi vào giao dịch dù cho phép hay từ chối (BR-14-008).

**`FederationRouter`.** `RuleMatcher` dựng chỉ mục từ ảnh chụp cấu hình: bảng băm theo `serviceCode` và theo (`group`, `operationType`), mỗi ô là danh sách luật xếp theo `priority` giảm dần (số lớn hơn ưu tiên hơn; giả định, D03-03-PH14 xác nhận). Lượt gọi lấy luật đầu tiên của ô `serviceCode`, nếu không có thì ô (`group`, `operationType`). Ba trạng thái của đích chính được kiểm theo thứ tự: dịch vụ `ACTIVE` hoặc `DEPRECATED`, nền tảng `ACTIVE` và không `securityHold`, bộ ngắt mạch không `OPEN`. Chỉ khi đích chính không dùng được, luật có `allowFallback`, thao tác `READ` và đích dự phòng cùng nhóm dữ liệu thì chuyển hướng; lượt chuyển hướng ghi `routedVia = FALLBACK`, tăng `national_fallback_total` và phát cảnh báo cấu hình `routing.fallback`. Nếu cả hai không dùng được, `StaleServer` thử đệm quá hạn (4.11) rồi mới ERR-14-103. Thao tác `WRITE` không bao giờ chuyển hướng (BR-14-023), kiểm cả ở lúc lưu luật (ERR-14-015) và ở lúc chạy.

**Quản lý luật.** `RoutingRuleService` kiểm trùng (ERR-14-013), kiểm đích `ACTIVE` (ERR-14-014) và đòi căn cứ văn bản `basis` khi thêm luật mới; luật qua `FourEyesGuard` mới vào ảnh chụp. `RoutingSimulator` dùng đúng `RuleMatcher` của cổng (đóng gói thành thư viện dùng chung `national-routing-core`, không sao chép mã) chạy trên ảnh chụp hiện hành cộng luật nháp, để kết quả mô phỏng trùng kết quả chạy thật (API-14-028).

### 4.6. Bộ điều hợp theo nhóm dịch vụ và chuyển đổi bản tin

::: dac-ta
**Mục đích.** Cô lập đặc thù giao thức và lược đồ của từng nhóm dịch vụ quốc gia vào bảy bộ điều hợp, và chuyển bản tin kỹ thuật (giao thức, phong bì, lược đồ, định dạng) mà không đụng ngữ nghĩa nghiệp vụ.

**Lớp chính.** `NationalAdapter` (SPI) và bảy lớp `LlTpAdapter`, `HoTichAdapter`, `BhxhAdapter`, `DvqhnsAdapter`, `DkdnAdapter`, `VbqpplAdapter`, `DmdcAdapter`; `RestTranslator`, `SoapTranslator`, `XsdValidator`, `Paginator`, `ErrorClassifier`.

**Đơn vị chạy.** `dh-runtime` (`gateway`, `worker`).

**FR hiện thực.** FR-14-014, 015, 017…023.

**Giao diện vào.** Chặng 6 và 8 của đường gọi; API-14-075, API-14-079…083 (DMDC).

**Phụ thuộc ra.** `OutboundClient` (egress), `ConfigSnapshot` (hợp đồng, lược đồ, WSDL đệm), PH-07 (qua phía gọi).

**Dữ liệu.** WSDL, XSD, JSON Schema đệm trong bộ nhớ và đĩa tạm theo `checksum`.

**Sự kiện.** Không riêng.

**Lỗi và xử lý.** Sai lược đồ vào: ERR-14-108; sai cấu trúc ra: ERR-14-128; không tải được WSDL: ERR-14-131, dùng bản đã lưu; lỗi nghiệp vụ của trung ương: ERR-14-102.

**Quan sát.** `national_adapter_calls_total{group,operation,result}`, `national_invalid_response_total`, `national_pages_total`.
:::

Chi tiết thiết kế:

`NationalAdapter` là SPI đăng ký theo `group`; thêm nhóm dịch vụ mới là thêm một lớp và một mục cấu hình, không sửa đường gọi chung.

```java
public interface NationalAdapter {
  ServiceGroup group();
  Map<String, OperationSpec> operations();                       // mã operation → READ|WRITE, idempotent, phân trang, lược đồ
  OutboundRequest build(InvocationContext ctx, OperationSpec op, JsonNode params);
  AdapterResponse parse(InvocationContext ctx, OperationSpec op, RawResponse raw);   // raw đã được xác minh chữ ký
  default Optional<OperationSpec> reconcileOperation(OperationSpec writeOp) { return Optional.empty(); } // thao tác tra trạng thái
}
```

Bộ chuyển đổi chọn theo `service.protocol`: REST dựng đường dẫn, truy vấn, thân JSON; SOAP dựng phong bì từ WSDL đã nạp bằng CXF, đặt tiêu đề `Service-code` bằng `nationalServiceCode`, `Authorization: Bearer` từ `TokenManager`, `X-Transaction-Code`, `X-Unit-Code` (mã đơn vị gửi, lấy từ cấu hình nền tảng). Phản hồi XML được đọc bằng `SecureXml` (cấm thực thể ngoài, giới hạn độ sâu) rồi chuyển sang JSON chuẩn: định danh giữ dạng chuỗi, ngày giờ ISO 8601 múi giờ +07:00, trường rỗng thành `null`. Phản hồi lớn được đọc theo luồng và dừng khi vượt `14.adapter.max-response-mb`; `Paginator` theo con trỏ hoặc số trang của nền tảng tới `14.adapter.max-pages`, vượt thì ném ERR-14-108 kèm cờ `partial` chứ không cắt im lặng.

Bảy bộ điều hợp dùng chung khung trên và khác nhau ở đặc thù ghi ở bảng dưới (mã `operation` và tham số theo bảng thao tác của từng FR; danh sách thao tác là giả định lấy từ phụ lục NGSP cho tới khi có Q14-01).

| Nhóm | FR | Thao tác ghi | Đặc thù hiện thực |
|---|---|---|---|
| `LLTP` | 017 | `markDossierSuccess` (idempotent), `submitRegistration` | Không đệm (`SENSITIVE`); thao tác tra trạng thái `getDossierStatus` là `reconcileOperation` của hai thao tác ghi; tệp đính kèm trả bằng liên kết tải tạm có hạn |
| `HO_TICH` | 018 | `registerBirth` và các đăng ký hộ tịch | Không đệm; ghi quá hạn chờ chuyển `UNKNOWN_RESULT`, đối soát bằng thao tác tra trạng thái đăng ký trước khi cho gửi lại |
| `BHXH` | 019 | Không | Đệm 300 giây có điều kiện (Q14-08), mã hóa giá trị đệm theo khóa tenant vì `RESTRICTED`; số thành viên hộ trả về tối đa `14.bhxh.max-members` |
| `DVQHNS` | 020 | Không | Thao tác `listDossiersByRange` chạy ở ưu tiên `BACKGROUND`, trả kèm `watermark` (thời điểm cập nhật lớn nhất) để lần đồng bộ sau bắt đầu từ đó; chỉ chi tiết hồ sơ được đệm 300 giây |
| `DKDN` | 021 | Không | Đệm hai mức: 3.600 giây dữ liệu doanh nghiệp, 300 giây hồ sơ trong ngày |
| `VBQPPL` | 022 | Không | Đệm 86.400 giây danh mục, 3.600 giây tìm kiếm và chi tiết; toàn văn lớn trả theo luồng |
| `DMDC` | 023 | `proposeEntries` | Chỉ PH-07 gọi (BR-14-036); bốn thao tác ở API-14-079…083; `getCatalogData` phân trang phía nguồn 1.000 bản ghi mỗi trang và hiểu `ifVersionNot` để trả `304`; không lưu dữ liệu danh mục |

: Đặc thù của bảy bộ điều hợp

Cổng tiếp hợp `DMDC` chọn kết nối `NDXP_DMDC` của tenant, nếu không có thì của `COMMON` (FR-14-012); chứng thư và thông tin xác thực của `COMMON` do tenant `COMMON` quản, vì vậy tenant tỉnh chỉ gọi, không đọc được bí mật đó (Q14-14 của FRS còn mở về việc dùng chung tài khoản). Mọi lỗi sau khi hết thử lại được `ErrorClassifier` che nội dung kỹ thuật của trung ương và trả mã ERR-14-1xx để PH-07 ánh xạ sang ERR-07-028.

### 4.7. Xác thực với nền tảng và xoay thông tin xác thực

::: dac-ta
**Mục đích.** Cổng tự lấy và làm mới token OAuth 2.1 `client_credentials` của nền tảng, không để ai thấy token hay bí mật, và cho phép xoay thông tin xác thực không gián đoạn kèm xác nhận khóa cũ đã bị thu hồi ở trung ương.

**Lớp chính.** `TokenManager`, `TokenHolder`, `AssertionSigner`, `TlsClientAuth`, `AuthBackoff` (cổng); `CredentialRotationService`, `RotationStateMachine` (control).

**Đơn vị chạy.** `dh-runtime` (`gateway`, `worker` khi thử token); `dh-integration`.

**FR hiện thực.** FR-14-024, 025.

**Giao diện vào.** Chặng 6 của đường gọi; API-14-039 (xoay), API-14-040 (thử token).

**Phụ thuộc ra.** Module `adapter` PH-05 (kết nối, giá trị chờ), OpenBao (`kv` đọc ở cổng, `transit/sign` cho `private_key_jwt`), egress tới địa chỉ token.

**Dữ liệu.** Token ở bộ nhớ của từng bản sao, không ghi đĩa; `credential_rotation` (trạng thái xoay, thời điểm, `revocationReceipt`).

**Sự kiện.** EVT-14-15 khi lỗi xác thực đổi sức khỏe; EVT-14-01 khi đổi bước xoay.

**Lỗi và xử lý.** Chưa đặt thông tin xác thực: ERR-14-034; nền tảng từ chối: ERR-14-114, không thử lại quá một lần trong 5 phút; không tới được địa chỉ token: ERR-14-101.

**Quan sát.** `national_token_errors_total{platform,reason}`, `national_token_refresh_seconds`, `national_secret_fallback_total`, `national_secret_age_days`.
:::

Chi tiết thiết kế:

**`TokenManager`.** Mỗi (nền tảng, bản sao) có một `TokenHolder` bất biến chứa `SecretBytes` của token (mảng byte được xóa khi bị thay), `expiresAt`, `scope`. `get()` trả token nếu còn hơn `14.token.refresh-before-seconds`; ngược lại gọi `refresh()` được bảo vệ bởi một khóa mỗi nền tảng mỗi bản sao (single-flight): người đến sau chờ tối đa 2 giây hoặc dùng token còn hạn nếu có. Ngoài ra bộ hẹn giờ làm mới chủ động ở thời điểm `expiresAt` trừ hai lần ngưỡng làm mới, lệch ngẫu nhiên ±10% để các bản sao không cùng xin token một lúc. Token không đi qua Valkey: mỗi bản sao tự giữ token riêng, đổi lại số lượt xin token bằng số bản sao (Q14-23 hỏi NDXP có giới hạn).

Ba chế độ xác thực, chọn theo `authMode` của nền tảng:

| `authMode` | Cách xác thực với điểm cấp token | Khóa nằm ở đâu |
|---|---|---|
| `CLIENT_SECRET` | `client_id` và `client_secret` trong tiêu đề Basic, grant `client_credentials`; chỉ giai đoạn chuyển đổi, bí mật ≤ 180 ngày (SEC-24) | `kv` của kết nối PH-05, đọc bằng `ConnPropertiesFunction` |
| `PRIVATE_KEY_JWT` (mặc định) | Gửi `client_assertion` là JWT (`iss` và `sub` là `client_id`, `aud` là điểm cấp token, `jti` ULID, sống 60 giây) ký bằng `transit/sign` | Khóa `transit/keys/dh-{tenant}-nat-auth`, không xuất được |
| `TLS_CLIENT_AUTH` | mTLS với chứng thư khách của tenant (RFC 8705) | Khóa của chứng thư khách ở OpenBao `pki` hoặc `kv`, nạp vào bộ nhớ khi dựng kho khóa TLS của Vert.x và nạp lại khi chứng thư đổi |

: Chế độ xác thực với nền tảng quốc gia

Chế độ `TLS_CLIENT_AUTH` là chỗ duy nhất khóa riêng phải vào bộ nhớ cổng, vì ngăn xếp TLS cần khóa để bắt tay; khóa này không phải khóa ký bản tin và có vòng đời ngắn (chứng thư PKI ≤ 90 ngày, SEC-35). Rủi ro còn lại ghi ở 13.2.

**Lỗi xác thực.** Điểm cấp token trả `invalid_client` hoặc 401: `AuthBackoff` đặt nền tảng `DEGRADED`, cấm thử lại cùng nền tảng trong 5 phút (BR-14-031), các lượt cần token mới trả ngay ERR-14-114; lượt đang có token còn hạn không bị ảnh hưởng. Lỗi mạng tới điểm cấp token trả ERR-14-101 và cho phép thử lại theo `14.retry.max-attempts` vì không phải lỗi xác thực.

**Xoay thông tin xác thực.** `CredentialRotationService` điều khiển máy trạng thái ở 8.1 (bảng "Xoay thông tin xác thực"). Giá trị mới được người dùng đặt ở kết nối PH-05 dưới dạng giá trị chờ (FR-05-012); PH-14 không bao giờ nhận giá trị bí mật. Bước thử: lệnh `token.test` cho `worker` lấy token bằng giá trị chờ qua `SecretVersionSelector` ở chế độ `PENDING`, trả `OK` hoặc lỗi cùng `expiresInSeconds`, `scope`, không trả token. Khi người dùng xác nhận chuyển, cửa sổ chuyển tiếp (`14.secret.overlap-hours`, mặc định 24 giờ) bắt đầu: `SecretVersionSelector` thử phiên bản mới trước, bị nền tảng từ chối xác thực thì dùng phiên bản cũ và tăng `national_secret_fallback_total`. Hết cửa sổ, hệ thống chặn việc đóng xoay cho tới khi nhập `revocationReceipt` (xác nhận trung ương đã hủy khóa cũ); chỉ khi đó phiên bản cũ mới được PH-05 hủy. Khi cắt chuyển khỏi NGSP cũ, `ParallelRunService` (4.19) từ chối đóng phiên chạy song song nếu bước này chưa xong (ERR-14-004), hiện thực BR-14-034.

### 4.8. Ký số và xác minh chữ ký

::: dac-ta
**Mục đích.** Ký mọi bản tin gửi tới dịch vụ yêu cầu chữ ký bằng khóa không rời OpenBao, và xác minh mọi phản hồi, bản tin chiều vào trước khi dùng; chữ ký sai không bao giờ tới HTTT.

**Lớp chính.** `TransitJcaProvider` (nhà cung cấp JCA gọi `transit/sign`), `TransitSigner`, `XmlDsigWriter`, `WsseWriter`, `JwsWriter`, `Canonicalizer`, `CertSelector`, `SignatureVerifier`, `TrustStore`, `ReplayGuard`, `SignatureFailureHandler`.

**Đơn vị chạy.** `dh-runtime` (`gateway`, `worker`).

**FR hiện thực.** FR-14-026, 027 (và 040, 041 cho chiều vào).

**Giao diện vào.** Chặng 6 (ký) và 7 (xác minh) của đường gọi; chặng xác minh của `InboundGateway`.

**Phụ thuộc ra.** OpenBao `transit/sign` (ký số), `ConfigSnapshot` (chứng thư công khai, neo tin cậy), `CrlStore`, Valkey (chống phát lại), NTP của nút.

**Dữ liệu.** Không ghi CSDL; kết quả ký, xác minh nằm trong bản ghi giao dịch (`certCode`, băm, kết quả).

**Sự kiện.** EVT-14-04 khi chặn ký do chứng thư; EVT-14-06 qua sự cố chữ ký (4.9); EVT-14-11 qua giao dịch.

**Lỗi và xử lý.** Không ký được: ERR-14-112, không gửi; chứng thư hết hạn hoặc thu hồi: ERR-14-113; chữ ký sai: ERR-14-109; chuỗi tin cậy, thu hồi: ERR-14-110; thời điểm ký hoặc lặp: ERR-14-111.

**Quan sát.** `national_sign_total{platform,mode,result}`, `national_sign_duration_seconds`, `national_verify_total{platform,mode,result}`, `national_verify_failed_total{kind}`.
:::

Chi tiết thiết kế:

**Ký qua nhà cung cấp JCA.** Thay vì viết lại ba chuẩn chữ ký, `TransitJcaProvider` đăng ký thuật toán `SHA256withRSA`, `SHA256withECDSA` với một `SignatureSpi` tự tính băm SHA-256 ở cổng rồi chỉ gửi **giá trị băm** tới `transit/sign/{key}` với `prehashed=true`, `hash_algorithm=sha2-256`, `signature_algorithm=pkcs1v15` cho RSA và `marshaling_algorithm=jws` cho ECDSA (chữ ký dạng r‖s mà XML Signature và JWS yêu cầu). "Khóa riêng" mà Santuario, WSS4J hay thư viện JOSE nhìn thấy là `TransitPrivateKey`, một tay cầm chỉ chứa tên khóa và phiên bản, không có vật liệu khóa; một `KeyStoreSpi` đi kèm (`TransitKeyStore`) trả tay cầm này theo `keyRef` cho những thư viện đòi kho khóa (WSS4J). Nhờ vậy ba chế độ dùng nguyên thư viện chuẩn:

| `signingMode` | Cách dựng | Chuẩn hóa | Chữ ký đặt ở |
|---|---|---|---|
| `XMLDSIG` | Santuario `XMLSignature`, tham chiếu toàn bộ phần tử thân | Exclusive C14N 1.0, băm SHA-256 | Phần tử `ds:Signature` trong bản tin, kèm `X509Data` của chứng thư công khai |
| `WSSE` | WSS4J qua CXF: `wsse:BinarySecurityToken`, `wsu:Timestamp`, ký thân và `Timestamp` | Exclusive C14N | Tiêu đề SOAP `wsse:Security` |
| `JWS` | JOSE `JWSObject` với `JWSSigner` tùy biến gọi `TransitSigner`, `alg` là `RS256`, `PS256` hoặc `ES256` theo khóa | Chuỗi `base64url(header).base64url(payload)` | Tiêu đề `X-DH-Signature` (JWS tách rời) hoặc trường trong thân theo đặc tả dịch vụ |

: Ba chế độ ký

`TransitSigner` giữ một nhóm kết nối HTTP/2 tới OpenBao (16 kết nối, giữ sống), xác thực bằng token Kubernetes tự làm mới, thời hạn 1 giây và một lần thử lại trong phạm vi ngân sách NFR-14-002 (p99 ≤ 50 ms). Ngắt mạch riêng cho OpenBao mở sau 5 lỗi trong 10 giây và nửa mở sau 5 giây; khi mở, mọi lượt cần ký trả ngay ERR-14-112 và thao tác bất đồng bộ ở lại hàng chờ (BR-14-001). Chọn chứng thư: `CertSelector` lấy chứng thư `ACTIVE`, nếu không có thì `EXPIRING` có `notAfter` xa nhất cùng mục đích `SIGNING` hoặc `BOTH`; không có thì ERR-14-112, chứng thư duy nhất đã hết hạn hoặc bị thu hồi thì ERR-14-113 kèm sự kiện EVT-14-04 (BR-14-017). Việc ký luôn làm ở thời điểm gửi, kể cả khi lượt đã chờ trong hàng đợi hay đã thử lại, nên bản tin thử lại có `Timestamp` và `messageId` mới.

**Xác minh.** `SignatureVerifier` thực hiện theo thứ tự, dừng ở lỗi đầu tiên:

1. Trích chữ ký và chứng thư theo `verifyMode`; bật xác thực an toàn của Santuario (`secureValidation`, cấm SHA-1, giới hạn số tham chiếu và phép biến đổi) và kiểm chữ ký phủ **toàn bộ** phần tử thân, tránh tấn công bọc chữ ký.
2. Xây và kiểm đường dẫn chứng thư bằng PKIX tới neo trong `TrustStore`, kiểm khoảng hiệu lực tại thời điểm ký (sai: ERR-14-110).
3. Kiểm thu hồi bằng `CrlStore` (CRL đã xác minh chữ ký) hoặc OCSP có đệm; CRL quá `14.crl.max-age-days` thì theo `14.crl.fail-mode`: `SOFT` xác minh tiếp và ghi cảnh báo, `HARD` ném ERR-14-110.
4. Tính lại băm phần được ký và kiểm giá trị chữ ký bằng khóa công khai của chứng thư (không khớp: ERR-14-109).
5. Kiểm thời điểm ký nằm trong `14.sign.max-skew-seconds` so với giờ nút đã đồng bộ NTP, và `messageId` chưa gặp: `ReplayGuard` đặt `SET NX EX` 600 giây ở Valkey (trùng: ERR-14-111); khi Valkey mất dùng bộ đệm trong bản sao, ghi nhận giảm bảo đảm ở 8.6.

Mọi XML đi qua `SecureXml` (CC-SEC-13 của D04-01), cấm thực thể ngoài và truy cập mạng khi giải tham chiếu. Khi bất kỳ bước nào ném lỗi chữ ký, `SignatureFailureHandler` không trả dữ liệu, ghi giao dịch `SIGNATURE_FAILED`, đẩy bản tin lỗi vào chủ đề nội bộ `{tenant}.national.signature.failed.v1` (siêu dữ liệu: loại lỗi, số sê-ri và tổ chức cấp của chứng thư đối tác, `transactionCode`, không nội dung) và cập nhật bộ đếm trượt 10 phút của nền tảng (4.9).

### 4.9. Chứng thư, chuỗi tin cậy và sự cố chữ ký

::: dac-ta
**Mục đích.** Quản lý vòng đời chứng thư số của tỉnh (nạp, kích hoạt qua hai người, theo dõi hạn, thu hồi), giữ chuỗi tin cậy và danh sách thu hồi mới, và biến mọi lỗi chữ ký thành sự cố an ninh có hồ sơ, kèm cưỡng chế `SECURITY_HOLD` tức thời ở cổng.

**Lớp chính.** `CertificateService`, `CertificateParser`, `KeyMatchChecker`, `CertificateExpiryJob`, `TrustAnchorService`, `SignatureIncidentService` (control); `CrlRefresher`, `CrlStore`, `HoldFlag`, `SelfTestRunner` (cổng).

**Đơn vị chạy.** `dh-integration`; `dh-runtime` (`worker` làm mới CRL và ký thử, `gateway` áp cờ giữ).

**FR hiện thực.** FR-14-028, 029, 030, 031.

**Giao diện vào.** API-14-029…038; chủ đề lệnh `{tenant}.national.worker.command.v1`.

**Phụ thuộc ra.** OpenBao (đọc khóa công khai của `transit/keys`), `worker`, Ceph RGW (CRL), PH-12 (xác thực nhiều yếu tố, hộp việc), PH-13 (SIEM).

**Dữ liệu.** `national_certificate`, `trust_anchor`, `signature_incident`; CRL ở bucket `dh-nat-trust`.

**Sự kiện.** EVT-14-04, EVT-14-05, EVT-14-06, EVT-14-01 (vào hoặc ra `SECURITY_HOLD`).

**Lỗi và xử lý.** Chứng thư sai định dạng hoặc chuỗi: ERR-14-019; không khớp khóa: ERR-14-020; ngoài hiệu lực: ERR-14-021; còn dùng xác minh: ERR-14-022; OpenBao ngừng: ERR-14-035.

**Quan sát.** `national_cert_days_remaining{cert}`, `national_signature_incidents_open`, `national_security_hold{platform}`, `national_incident_alert_latency_seconds`.
:::

Chi tiết thiết kế:

**Nạp và kiểm khớp khóa.** `CertificateParser` (BouncyCastle) đọc PEM, CER, P7B, kiểm chuỗi tới một neo đã cấu hình, khoảng hiệu lực và `KeyUsage` có `digitalSignature` (ERR-14-019, ERR-14-021). `KeyMatchChecker` có hai lớp. Lớp một ở `dh-integration`: đọc khóa công khai của `transit/keys/{keyRef}` (chính sách OpenBao của `dh-integration` chỉ có quyền đọc khóa công khai ở tiền tố `dh-{tenant}-nat-sign-*`, không có `sign`) và so băm SPKI với chứng thư. Lớp hai ở cổng: lệnh `cert.selftest` gửi qua `{tenant}.national.worker.command.v1`, `SelfTestRunner` của `worker` ký thử một băm ngẫu nhiên bằng `TransitSigner` rồi xác minh bằng khóa công khai của chứng thư, trả kết quả trong 10 giây trên `{tenant}.national.worker.result.v1`. Chỉ có hai lớp cùng đạt mới `UPLOADED` (ERR-14-020 nếu không). Cách chia này giữ BR-14-004 (chỉ cổng của đúng tenant được ký) và chỉnh nhẹ FR-14-028 bước 3, nơi FRS mô tả "hệ thống ký thử" mà không nêu chủ thể (Q14-25).

**Kích hoạt và chuyển tiếp.** `request-activation` đòi xác thực nhiều yếu tố (SEC-23), tạo việc cho người có quyền `approve`; `approve-activation` qua `FourEyesGuard`, đặt `ACTIVE`, đặt chứng thư cũ cùng mục đích sang `SUPERSEDED` sau `14.cert.overlap-hours` (mặc định 72 giờ), tăng `config_revision`; cổng nạp trong 30 giây. Chứng thư công khai và chuỗi đi vào ảnh chụp cấu hình để cổng gắn vào bản tin; chứng thư ở `SUPERSEDED` vẫn nằm trong ảnh chụp trong thời gian chuyển tiếp để đối chiếu bằng chứng giao dịch đã ký bằng nó (BR-14-019).

**Theo dõi hạn.** `CertificateExpiryJob` chạy 06:00 giờ Việt Nam hằng ngày và khi khởi động, dưới khóa ShedLock của `dh-integration`: tính số ngày còn lại, đặt `EXPIRING` khi ≤ 60 ngày, phát EVT-14-05 với mức `INFO` (60), `WARNING` (30), `CRITICAL` (7) một lần mỗi mốc nhờ cột `last_warned_level`, đặt `EXPIRED` khi quá `notAfter`. Khi không còn chứng thư dùng được cùng mục đích, trạng thái này vào ảnh chụp và `CertSelector` trả ERR-14-113. Xóa chỉ được với chứng thư chưa từng `ACTIVE`; chứng thư còn bản ghi giao dịch trong thời hạn lưu không xóa được (ERR-14-022).

**Chuỗi tin cậy và CRL.** `CrlRefresher` ở `worker` mỗi `14.trust.refresh-hours` (mặc định 24 giờ) tải CRL hoặc truy vấn OCSP qua egress, kiểm chữ ký CRL bằng chứng thư của cơ quan cấp (sai: bỏ bản tải, cảnh báo), lưu đối tượng vào bucket `dh-nat-trust` và phát chủ đề nén `{tenant}.national.trust.crl.v1` mang con trỏ (khóa đối tượng, SHA-256, `thisUpdate`, `nextUpdate`). Mỗi bản sao `gateway` có nhóm tiêu thụ riêng, tải đối tượng, kiểm băm rồi thay `CrlStore` nguyên khối. Tải lỗi thì thử lại 3 lần cách 5 phút rồi cảnh báo; thêm hoặc bớt neo tin cậy qua `TrustAnchorService` và `FourEyesGuard` (BR-14-018), sau đó vào ảnh chụp.

**Sự cố chữ ký và `SECURITY_HOLD`.** Có hai đường chạy song song để đạt NFR-14-018 (cảnh báo ≤ 1 phút) mà không phụ thuộc PostgreSQL:

1. Đường cưỡng chế, ở cổng: `HoldFlag` giữ ZSET Valkey `{tenant}:nat:sigfail:{platform}` (cửa sổ trượt 10 phút). Khi số phần tử đạt `14.signature.hold-threshold` (mặc định 5), cổng `SET {tenant}:nat:hold:{platform}` và đặt cờ cục bộ; chặng 2 của mọi bản sao đọc cờ này (bộ nhớ, đối chiếu Valkey mỗi giây) nên hiệu lực tức thì. Nếu Valkey không khả dụng, mỗi bản sao tự đếm trong bộ nhớ và tự đặt cờ cục bộ.
2. Đường hồ sơ, ở `dh-integration`: `SignatureIncidentService` tiêu thụ `signature.failed`, tạo `signature_incident` `OPEN`, gửi thông báo cho SO và TA, phát EVT-14-06 cho PH-13 đẩy SIEM (SEC-63), và khi nhận tín hiệu `hold-entered` từ cổng thì ghi `securityHold = true` vào nền tảng, phát EVT-14-01 và đưa vào ảnh chụp để cờ sống qua khởi động lại.

Giải trừ chỉ qua API của SO: `SignatureIncidentService` kiểm không còn sự cố `OPEN` (ERR-14-004), xóa cờ Valkey, ghi `securityHold = false`, tăng `config_revision`. Kết thúc sự cố đòi kết luận (ERR-14-003). Độ trễ thực tế từ lỗi tới thông báo là một lượt Kafka cộng xử lý bộ tiêu thụ, mục tiêu p99 ≤ 10 giây, đo bằng `national_incident_alert_latency_seconds`.

### 4.10. Hạn mức và phân bổ

::: dac-ta
**Mục đích.** Đếm chính xác lượt gọi ra quốc gia theo từng chu kỳ, chặn trước khi vượt, ưu tiên dịch vụ thiết yếu khi hạn mức khan hiếm và chia hạn mức cho từng HTTT, để tỉnh không bị trung ương từ chối phục vụ mà không biết trước.

**Lớp chính.** `QuotaGate`, `QuotaScripts` (hai script Lua), `AllocationPolicy`, `PriorityGate`, `LocalQuotaCounter`, `UsageSnapshotter`, `QuotaRestorer` (cổng); `QuotaPolicyService`, `UsageConsumer`, `QuotaForecaster` (control).

**Đơn vị chạy.** `dh-runtime` (`gateway` đếm, `worker` đồng bộ số liệu); `dh-integration`.

**FR hiện thực.** FR-14-032, 033, 034, 057.

**Giao diện vào.** Chặng 6 của đường gọi; API-14-041…045, API-14-069.

**Phụ thuộc ra.** Valkey, Kafka (`{tenant}.national.quota.usage.v1`), PH-13 (thông báo ngưỡng).

**Dữ liệu.** `quota_policy`, `quota_allocation`, `quota_usage` (giữ 2 năm); bộ đếm ở Valkey.

**Sự kiện.** EVT-14-07 (chạm 70%, 85%, 95%), EVT-14-08 (đổi hạn mức hoặc phân bổ).

**Lỗi và xử lý.** Hết hạn mức: ERR-14-104 kèm `scope`, `reason`, `resetAt`; tổng phân bổ vượt: ERR-14-018; thiếu căn cứ: ERR-14-016; Valkey mất: đếm cục bộ suy giảm có cảnh báo.

**Quan sát.** `national_quota_used_ratio{platform,service,period}`, `national_quota_denied_total{reason}`, `national_quota_degraded` (gauge 0 hoặc 1).
:::

Chi tiết thiết kế:

**Khóa và script nguyên tử.** Mọi khóa của một tenant dùng thẻ băm `{tenant}` (ví dụ `{t68}:nat:q:s:lltp-tra-trang-thai:DAY:20261126`) để nhiều khóa nằm cùng một slot và script Lua chạy trên một nút. `quota_try.lua` nhận danh sách bộ đếm áp cho lượt gọi (hạn mức dịch vụ và hạn mức nền tảng ở mọi chu kỳ, cộng bộ đếm phân bổ của HTTT), giới hạn tương ứng, lớp ưu tiên của dịch vụ và hai ngưỡng `14.quota.background-defer-ratio`, `14.quota.essential-only-ratio`. Script làm hai lượt: lượt một đọc mọi bộ đếm và quyết định, lượt hai `INCR` tất cả chỉ khi mọi bộ đếm cho phép; nhờ vậy không cần hoàn lại bộ đếm khác khi một bộ đếm vượt. Kết quả trả `allowed`, chỉ số bộ đếm gây từ chối, tỷ lệ dùng sau khi trừ của từng bộ đếm, lý do (`OVER_LIMIT`, `BACKGROUND_DEFERRED`, `ESSENTIAL_ONLY`, `ALLOCATION_EXCEEDED`). Một lượt gọi tốn đúng một vòng đi về tới Valkey.

| Quy tắc ưu tiên (BR-14-013) | Điều kiện theo tỷ lệ dùng của bộ đếm chặt nhất | Kết quả |
|---|---|---|
| Dịch vụ `BACKGROUND` | ≥ `14.quota.background-defer-ratio` (0,7) | Từ chối `BACKGROUND_DEFERRED`; thao tác của hàng chờ ở lại hàng chờ |
| Dịch vụ `NORMAL` | ≥ `14.quota.essential-only-ratio` (0,95) | Từ chối `ESSENTIAL_ONLY` |
| Dịch vụ `ESSENTIAL` | < 1,0 ở bộ đếm toàn cục | Cho phép, bỏ qua trần phân bổ của HTTT |
| Mọi dịch vụ | ≥ 1,0 | Từ chối `OVER_LIMIT` |

: Quy tắc ưu tiên khi hạn mức khan hiếm

**Phân bổ.** `AllocationPolicy` tính giới hạn hiệu dụng của HTTT cho một dịch vụ bằng `limit` của phân bổ cộng `shareOfReserve` nhân phần dự trữ (`limit` của hạn mức trừ tổng phân bổ). Dịch vụ `ESSENTIAL` vẫn đếm vào bộ đếm của HTTT nhưng không bị chặn bởi trần này, vì một hồ sơ người dân đang chờ không bị từ chối do HTTT đã dùng hết phần mình (giả định thiết kế, ghi ở Q14-24 cùng việc đối chiếu cách đếm với trung ương).

**Hai cách đếm chu kỳ** (`14.quota.window-mode`). `CALENDAR`: khóa theo mốc lịch giờ Việt Nam (`yyyyMMddHH`, `yyyyMMdd`, `yyyyMM`), `resetAt` là mốc tiếp theo, khóa hết hạn sau chu kỳ cộng 1 giờ. `SLIDING`: một hash `{t68}:nat:qs:…` gồm 60 ô, mỗi ô là một phần sáu mươi chu kỳ (1 phút với giờ, 24 phút với ngày, 12 giờ với tháng); script cộng các ô trong cửa sổ và xóa ô cũ; `resetAt` là hết ô sớm nhất còn đếm. Cửa sổ trượt theo ô nên bảo thủ: lượng còn lại có thể nhỏ hơn lượng tính chính xác tối đa một ô.

**Hoàn lại.** `QuotaTicket` ghi các bộ đếm đã trừ; `quota_refund.lua` `DECR` không xuống dưới 0 khi lượt chưa rời egress. Lượt đã gửi, kể cả bị nền tảng trả lỗi, giữ nguyên (BR-14-012).

**Ngưỡng cảnh báo.** Từ tỷ lệ dùng do script trả, `QuotaGate` so với `14.quota.warn-levels` (mặc định 70%, 85%, 95%); với mỗi ngưỡng vừa vượt, cổng `SET NX` cờ `{t68}:nat:qw:{scope}:{period}:{bucket}:{level}` và chỉ khi đặt được mới phát EVT-14-07, nên mỗi ngưỡng mỗi chu kỳ chỉ một sự kiện dù nhiều bản sao cùng thấy.

**Đồng bộ về PostgreSQL.** `UsageSnapshotter` ở `worker` mỗi 60 giây quét bộ đếm theo thẻ tenant và phát bản chụp lên chủ đề nội bộ `{tenant}.national.quota.usage.v1`; `UsageConsumer` ở `dh-integration` ghi `quota_usage` bằng `INSERT … ON CONFLICT DO UPDATE` lấy giá trị lớn hơn. Khi Valkey khởi động lại và bộ đếm của chu kỳ hiện tại biến mất, `QuotaRestorer` gọi API-14-043 (phạm vi nội bộ) lấy `used` cuối cùng và `SET NX` lại; có thể thiếu tối đa số lượt của một phút, thiên về an toàn vì đếm thiếu tối đa bằng khoảng 60 giây lưu lượng.

**Suy giảm khi Valkey mất.** `LocalQuotaCounter` đếm trong bộ nhớ từng bản sao với giới hạn bằng giới hạn toàn cục chia cho số bản sao đang `Ready` (đọc từ `EndpointSlice` của Deployment, làm mới 30 giây); gauge `national_quota_degraded` bật và cảnh báo hiện ở UI-14-01. Không bao giờ bỏ kiểm tra hạn mức (FR-14-033 luồng thay thế). Dự báo cạn ở UI-14-01 và UI-14-09 do `QuotaForecaster` tính theo FR-14-048: ngoại suy từ nhịp dùng của 7 ngày gần nhất cùng khung giờ trên `quota_usage` và `usage_hourly`, rồi so với phần còn lại của chu kỳ; báo cáo hiệu quả đệm và hạn mức (FR-14-057, Đợt 3) dựng từ `quota_usage` và `usage_hourly`.

### 4.11. Đệm phản hồi và dữ liệu quá hạn

::: dac-ta
**Mục đích.** Giảm lượt gọi ra quốc gia bằng đệm theo thời hạn riêng của từng dịch vụ, gộp lượt trùng và dùng dữ liệu quá hạn có cờ khi quốc gia lỗi, mà không đệm dữ liệu nhạy cảm cao và không đệm chéo tenant.

**Lớp chính.** `ResponseCache`, `CacheKey`, `CacheEnvelope`, `SingleFlight`, `StaleServer`, `GenerationCounter`, `DekProvider`; ở control: `CacheAdminService`.

**Đơn vị chạy.** `dh-runtime` (`gateway`); `dh-integration` cho vô hiệu đệm.

**FR hiện thực.** FR-14-035, 036, 037.

**Giao diện vào.** Chặng 5 (đọc), chặng 9 (ghi) và đường lỗi của chặng 6; API-14-046, 047.

**Phụ thuộc ra.** Valkey, OpenBao `transit` (mở khóa DEK của tenant một lần mỗi giờ).

**Dữ liệu.** Chỉ ở Valkey; thống kê `cache_stats` tổng hợp theo giờ ở PostgreSQL qua EVT-14-11.

**Sự kiện.** EVT-14-09 khi vô hiệu đệm.

**Lỗi và xử lý.** Valkey mất: bỏ qua đệm, gọi thật, không lỗi cho người dùng; cấu hình đệm mâu thuẫn: ERR-14-038; vượt trần thời hạn: ERR-14-036.

**Quan sát.** `national_cache_requests_total{service,outcome}` (`hit`, `miss`, `stale`, `bypass`), `national_cache_hit_ratio{service}`, `national_cache_singleflight_waiters`.
:::

Chi tiết thiết kế:

**Khóa và giá trị.** Khóa `{t68}:nat:c:{gen}:{service}:{operation}:{băm}`, trong đó `băm` là SHA-256 của `params` chuẩn hóa theo JCS (sắp khóa, bỏ trường rỗng) và `gen` là số thế hệ của dịch vụ ở `{t68}:nat:gen:{service}`. Vô hiệu đệm là `INCR` số thế hệ nên mọi mục cũ không còn truy cập được và tự hết hạn theo TTL; `GenerationCounter` giữ bản sao cục bộ, cập nhật bằng thông báo khóa Valkey và thăm dò 1 giây, nên vô hiệu có hiệu lực ≤ 1 giây. `dh-integration` được quyền `INCR` đúng tiền tố `*:nat:gen:*` bằng ACL Valkey, không có quyền khác ở khóa đệm. Giá trị là `CacheEnvelope` gồm `storedAt`, `softExpiresAt`, `hardExpiresAt`, `platformCode`, `specVersion`, `signatureVerified` và `payload`. TTL Valkey bằng thời hạn mềm cộng `14.cache.stale-max-seconds`.

**Quy tắc ghi.** Chỉ ghi phản hồi thành công đã xác minh chữ ký; không ghi lỗi (kể cả lỗi nghiệp vụ); không ghi khi dịch vụ `SENSITIVE`, thao tác `WRITE` hay `cacheable = false` (kiểm hai lần: lúc lưu cấu hình ở ERR-14-038 và lúc chạy ở chặng 9, bảo vệ chống cấu hình đã lưu bị sửa tay); không ghi mục lớn hơn 512 KiB. Thời hạn lấy từ `contract.operations[op].cacheTtlSeconds` nếu có, nếu không từ `cacheTtlSeconds` của dịch vụ, luôn bị chặn trần bởi `14.cache.max-ttl-seconds` ★ (đó là cách DKDN có hai mức 3.600 giây và 300 giây). Dịch vụ `RESTRICTED` mã hóa `payload` bằng AES-256-GCM với khóa dữ liệu (DEK) của tenant, DEK mở từ khóa `transit/keys/dh-{tenant}-pii` (ADR-032) và giữ trong bộ nhớ tối đa 1 giờ; AAD là chính khóa đệm để mục không thể bị chép sang khóa khác.

**Đọc, quá hạn.** `HIT` khi còn trong thời hạn mềm. Quá hạn mềm mà nền tảng bình thường thì coi như `MISS` và làm mới. `StaleServer` chỉ cho phép trả mục quá hạn mềm nhưng còn trong thời hạn cứng khi đủ cả năm điều kiện: dịch vụ `staleAllowed`; thao tác `READ`; `14.cache.stale-max-seconds` > 0; nguyên nhân là nền tảng lỗi, ngắt mạch hoặc hết hạn mức (ERR-14-101, 103, 104, 115); nền tảng không `securityHold`. Phản hồi mang `stale = true`, tiêu đề `X-DH-Cache: STALE` và `X-DH-Cache-Age`; bên gọi gửi `X-DH-Accept-Stale: false` thì bị trả lỗi gốc, hiện thực quyền từ chối của BR-14-016.

**Gộp lượt trùng.** Mô tả ở 4.4; số người chờ đo bằng `national_cache_singleflight_waiters`. Tỷ lệ trúng `national_cache_hit_ratio` tính theo cửa sổ 5 phút và theo ngày để đối chiếu NFR-14-005 (≥ 60%).

### 4.12. Ngắt mạch, thử lại và dồn tải

::: dac-ta
**Mục đích.** Ngừng gọi nền tảng khi nó đang lỗi để không dồn thêm tải và không làm chậm mọi HTTT, và thử lại đúng chỗ (chỉ thao tác an toàn) để hấp thụ lỗi thoáng qua mà không lãng phí hạn mức.

**Lớp chính.** `BreakerRegistry`, `PlatformBreaker`, `RetryPolicy`, `OutboundClient`, `Bulkhead`, `UnknownResultReconciler`.

**Đơn vị chạy.** `dh-runtime` (`gateway`, `worker` cho đối soát).

**FR hiện thực.** FR-14-038 (và nền cho FR-14-015, 016).

**Giao diện vào.** Chặng 6 của đường gọi; API-14-086 (ép mở, ép đóng).

**Phụ thuộc ra.** Valkey (cờ chia sẻ), `ConfigSnapshot` (cờ ép), egress.

**Dữ liệu.** Trạng thái ở bộ nhớ và cờ Valkey `{t68}:nat:brk:{platform}:{group}`; cờ ép nằm trong ảnh chụp cấu hình.

**Sự kiện.** EVT-14-10 khi ngắt mạch đổi trạng thái hoặc hàng chờ tích lũy; EVT-14-15 khi mức sức khỏe đổi.

**Lỗi và xử lý.** Ngắt mạch mở và không có đệm hay dự phòng: ERR-14-103; quá hạn: ERR-14-115; ghi chưa rõ kết quả: `UNKNOWN_RESULT`, không gửi lại.

**Quan sát.** `national_breaker_state{platform,group}` (0 đóng, 1 nửa mở, 2 mở), `national_retry_total{service,outcome}`, `national_outbound_in_flight{platform}`, `national_unknown_result_open`.
:::

Chi tiết thiết kế:

**Ngắt mạch.** Mỗi (nền tảng, nhóm dịch vụ) có một `PlatformBreaker` với cửa sổ trượt 60 giây theo thời gian. Lượt được tính là lỗi khi gặp lỗi kết nối, quá hạn chờ, phản hồi 5xx hoặc 429 từ nền tảng; không tính lỗi nghiệp vụ 4xx, lỗi xác thực (xử lý riêng ở 4.7), lỗi chữ ký (xử lý ở 4.9). Khi cửa sổ có ≥ `14.breaker.min-calls` lượt và tỷ lệ lỗi > `14.breaker.failure-ratio`, bản sao đó mở trong `14.breaker.open-seconds`, đồng thời đặt cờ Valkey có TTL bằng thời gian mở để các bản sao khác cũng coi là mở ngay (mỗi bản sao tự quyết định mở từ số liệu của chính nó, nên với 3 bản sao ngưỡng 20 lượt có thể tương ứng 60 lượt toàn cụm). Hết thời gian mở, trạng thái `HALF_OPEN` cho 3 lượt thăm dò toàn cụm (phát vé bằng `INCR` Valkey; khi Valkey mất, mỗi bản sao một lượt): đạt thì đóng, không thì mở lại. `FORCE_OPEN` và `FORCE_CLOSED` đặt qua API-14-086 nằm trong ảnh chụp cấu hình và có hiệu lực ≤ 30 giây (NFR-14-017); người thao tác phải nêu lý do và bị ghi kiểm toán.

**Thử lại.** `RetryPolicy` cho thử lại khi đồng thời: thao tác `READ` hoặc `WRITE` có `idempotent = true`; lỗi thuộc lớp có thể thử lại (`retryable` của `ErrorClassifier`: kết nối, 502, 503, 504, quá hạn chờ); chưa quá `14.retry.max-attempts`. Độ trễ là lùi theo hàm mũ có nhiễu hoàn toàn (`random(0, 200 ms × 2^n)`); không thử lại nếu tổng thời gian đã dùng cộng độ trễ tiếp theo vượt `timeoutMs`. Mỗi lần thử lại quay lại bước hạn mức nên chịu cả cổng ưu tiên: từ mức `essential-only`, dịch vụ không thiết yếu bị dừng thử lại. Lỗi xác thực không thử lại (BR-14-031). Mỗi lần thử ký lại bản tin (4.8).

**Kết quả chưa rõ của thao tác ghi.** Thao tác ghi không idempotent quá hạn chờ chuyển `TIMEOUT` rồi `UNKNOWN_RESULT`, không gửi lại (BR-14-030). `UnknownResultReconciler` ở `worker` lập lịch tra trạng thái bằng `reconcileOperation` của bộ điều hợp sau 30 giây, 2 phút, 10 phút, 1 giờ rồi mỗi 6 giờ tới 72 giờ: thấy đã nhận thì `SUCCEEDED`, thấy chưa nhận thì `FAILED` (cho phép bên gọi gửi lại với `Idempotency-Key` mới). Bộ điều hợp không có thao tác tra trạng thái thì giao dịch giữ `UNKNOWN_RESULT` và cảnh báo TO xử lý tay; quá 72 giờ vẫn chưa rõ thì cảnh báo mức cao.

**Dồn tải.** `Bulkhead` giới hạn số lượt đang bay tới mỗi nền tảng ở mỗi bản sao (`14.dispatch.max-in-flight`, mặc định 256, tham số đề nghị thêm ở "Đề nghị đồng bộ"); vượt thì lượt chờ tối đa 200 ms rồi nhận ERR-14-103, để một nền tảng chậm không chiếm hết luồng của bản sao và kéo chậm nền tảng khác. Cổng dùng luồng ảo của Java 21 cho lời gọi chặn tới OpenBao, Valkey và egress, nên giới hạn này là chặn tải chứ không là chặn tài nguyên luồng.

### 4.13. Hàng chờ gọi bất đồng bộ

::: dac-ta
**Mục đích.** Cho HTTT gửi thao tác ghi hoặc lô tra cứu mà không phải chờ, và giữ yêu cầu an toàn khi nền tảng quốc gia gián đoạn: không mất, không gửi trùng, ưu tiên dịch vụ thiết yếu.

**Lớp chính.** `AsyncAcceptor` (`gateway`); `AsyncWorker`, `PriorityPoller`, `RetryScheduler`, `AsyncStateWriter` (`worker`); `AsyncStatusController` (cổng); `AsyncStateConsumer` (control).

**Đơn vị chạy.** `dh-runtime` (cả hai vai trò); `dh-integration` (ghi trạng thái bền).

**FR hiện thực.** FR-14-016.

**Giao diện vào.** API-14-076 (gửi), API-14-077 (tra), API-14-078 (hủy).

**Phụ thuộc ra.** Kafka (chủ đề hàng chờ), Valkey (trạng thái nóng, bộ đếm kích thước), Ceph RGW (kết quả mã hóa 72 giờ), đường gọi chung.

**Dữ liệu.** `async_request` ở PostgreSQL (qua `AsyncStateConsumer`); trạng thái nóng ở Valkey `{t68}:nat:as:{requestId}`.

**Sự kiện.** EVT-14-11 khi hoàn tất; EVT-14-10 khi hàng chờ tích lũy.

**Lỗi và xử lý.** Hàng chờ đầy hoặc Kafka không nhận: ERR-14-118; trùng khóa khác nội dung: ERR-14-116; không thấy yêu cầu: ERR-14-129; hủy yêu cầu đã gửi: ERR-14-130.

**Quan sát.** `national_async_queue_depth{priority}`, `national_async_oldest_age_seconds`, `national_async_requests_total{state}`, `national_unknown_result_open`.
:::

Chi tiết thiết kế:

**Nhận.** `AsyncAcceptor` chạy chặng 1 đến 4 của đường gọi (định danh, phân giải, mục đích, kiểm tra tham số), lấy bản ghi chống trùng, kiểm tra kích thước hàng chờ của tenant bằng bộ đếm Valkey so với `14.queue.max-size` (đầy: ERR-14-118), rồi phát thông điệp vào chủ đề theo ưu tiên của dịch vụ: `{tenant}.national.asyncqueue.essential.v1`, `…normal.v1`, `…background.v1`. Khóa Kafka là `requestId`; thân thông điệp là phong bì có `payload` đã mã hóa theo khóa tenant (ADR-032) vì Kafka giữ tới 96 giờ. Cổng chỉ trả `202` sau khi Kafka xác nhận `acks=all` với `min.insync.replicas=2`, nên "chấp nhận" đồng nghĩa với "đã bền"; Kafka không nhận được thì ERR-14-118, không bao giờ nhận rồi mất. Trạng thái `QUEUED` ghi vào Valkey (giữ 96 giờ) và phát bản ghi trạng thái lên `{tenant}.national.async.state.v1` để `AsyncStateConsumer` ghi `async_request`. Đây là thay thế cho việc "ghi bảng cùng giao dịch với đặt hàng chờ" của FRS: khi Kafka là nguồn sự thật thì trạng thái là bản dẫn xuất tái dựng được, và mặt phẳng dữ liệu không cần nối PostgreSQL.

**Lấy việc.** `PriorityPoller` của `worker` đọc ba chủ đề theo trọng số 8 : 3 : 1 mỗi nhịp 100 ms (dịch vụ thiết yếu luôn đi trước nhưng hai lớp còn lại không bị bỏ đói), dưới một nhóm tiêu thụ chung `national-async-{tenant}`. Với mỗi thông điệp, `AsyncWorker`:

1. Kiểm quá hạn (`14.queue.max-age-hours`, quá thì `FAILED` lý do `EXPIRED`) và cờ hủy (`CANCELLED` ghi ở Valkey bởi API-14-078 chỉ khi còn `QUEUED`).
2. Kiểm bản ghi chống trùng: đã `DONE` thì không chạy lại; `IN_PROGRESS` quá `timeoutMs` cộng 30 giây (nghĩa là bản sao trước đó chết giữa chừng) thì coi là `UNKNOWN_RESULT`, không gửi lại.
3. Đặt `SENDING`, chạy chặng 5 đến 9 của đường gọi bằng danh tính và mục đích đã lưu trong phong bì.
4. Kết quả: `SUCCEEDED` hoặc `FAILED`, lưu kết quả mã hóa vào `dh-nat-payload/async/` 72 giờ, phát EVT-14-11 để HTTT đăng ký nhận qua PH-10 hoặc tự tra bằng API-14-077.

Khi cổng hạn mức hoãn (`BACKGROUND_DEFERRED`, `ESSENTIAL_ONLY`) hoặc nền tảng ngắt mạch, thông điệp không bị hỏng mà được đẩy sang chủ đề trễ `{tenant}.national.asyncqueue.retry-1m.v1`, `retry-5m`, `retry-30m` kèm tiêu đề `not-before` rồi xác nhận bản gốc; `RetryScheduler` giữ thông điệp tới đúng hạn bằng `pause` và `resume`. Cách này không dừng cả chủ đề vì một nền tảng lỗi. Khi hàng chờ vượt 1.000 thông điệp hoặc tuổi thông điệp cũ nhất vượt 5 phút do ngắt mạch, `worker` phát EVT-14-10 (loại `QUEUE_ACCUMULATING`).

**Tra, hủy.** API-14-077 đọc trạng thái nóng ở Valkey; khi Valkey không khả dụng, cổng chuyển tiếp qua mesh tới `dh-integration` đọc `async_request` (độ trễ đồng bộ ≤ 10 giây, chấp nhận vì đây không phải đường gọi chính). Hủy chỉ thực hiện khi `QUEUED` (ERR-14-130 nếu khác). Máy trạng thái ở 8.1.

**Sức chứa.** NFR-14-011 yêu cầu giữ ≥ 100.000 bản tin ≥ 72 giờ không mất, không gửi trùng: chủ đề hàng chờ dùng 6 phân vùng, 3 bản sao, giữ 96 giờ; 100.000 thông điệp trung bình 4 KiB (giả định, gồm phong bì và mã hóa) tương đương khoảng 400 MiB mỗi tenant, nằm trong định cỡ Kafka của D03-09.

### 4.14. Chiều vào

::: dac-ta
**Mục đích.** Nhận yêu cầu do nền tảng quốc gia gọi vào tỉnh qua điểm cuối đã đăng ký: xác thực nguồn bằng mTLS và chữ ký, chống phát lại, chuyển cho luồng PH-04 và trả phản hồi có ký; chặn mọi yêu cầu không hợp lệ ở biên trước khi chạm lõi tích hợp.

**Lớp chính.** `EndpointService`, `AllowedSenderService` (control); `InboundGateway`, `SenderVerifier`, `InboundReplayStore`, `InboundDispatcher`, `ReceiptSigner`, `InboundErrorRenderer`, `InboundRateLimiter` (cổng).

**Đơn vị chạy.** `apisix-ext` (biên); `dh-runtime` (`gateway`); `dh-integration`.

**FR hiện thực.** FR-14-039, 040, 041, 042.

**Giao diện vào.** API-14-084 (`POST /inbound/v1/{endpointCode}/{serviceCode}`), API-14-085 (thông báo); API-14-048…052, 090 (quản lý).

**Phụ thuộc ra.** APISIX (tuyến tạo từ EVT-14-13 bởi PH-03), luồng PH-04 (qua mesh), `SignatureVerifier`, `ReceiptSigner`, Valkey, Kafka.

**Dữ liệu.** `inbound_endpoint`, `allowed_sender`; bản đệm kết quả chống phát lại ở Valkey.

**Sự kiện.** EVT-14-13 (đổi điểm cuối), EVT-14-17 (nhận thông báo), EVT-14-06 khi chữ ký sai.

**Lỗi và xử lý.** ERR-14-119 (nguồn không được phép), 120 (chứng thư mTLS sai), 121 (bản tin sai), 122 (lặp), 123 (vượt tần suất), 124 (luồng PH-04 lỗi), 039 (luồng chưa phát hành, lúc đăng ký).

**Quan sát.** `national_inbound_requests_total{endpoint,service,result}`, `national_inbound_duration_seconds`, `national_inbound_rejected_total{reason}`.
:::

Chi tiết thiết kế:

**Hai lớp chặn.** Lớp biên ở `apisix-ext`: chấm dứt mTLS với danh sách CA của đối tác, bộ lọc vân tay chứng thư (do PH-03 cung cấp, nhận danh sách từ EVT-14-13) từ chối nguồn lạ với ERR-14-120 trước khi chạm backend (NFR-14-016: từ chối ≤ 50 ms p99), WAF Coraza, giới hạn tần suất `limit-req` theo điểm cuối, kích thước thân tối đa 5 MiB (giả định, đủ cho hồ sơ có đính kèm nhỏ), rồi gắn `X-DH-Endpoint`, `X-DH-Client-Fingerprint` và tenant của điểm cuối vào tiêu đề nội bộ (BR-14-027). Lớp cổng ở `InboundGateway`: tin tiêu đề đó chỉ khi lời gọi tới từ danh tính SPIFFE của `apisix-ext` (SEC-15), tra điểm cuối trong ảnh chụp cấu hình và đối chiếu tenant của điểm cuối với tenant của Deployment (lệch: 404, không lộ tồn tại), không bao giờ lấy tenant từ thân bản tin. Lớp cổng còn có bộ giới hạn tần suất thứ hai theo `14.inbound.rate-limit-per-second` (ERR-14-123) để một APISIX cấu hình sai không làm tràn luồng.

**Xử lý một yêu cầu** theo thứ tự rẻ trước, đắt sau:

1. Điểm cuối `ACTIVE`; vân tay thuộc một `AllowedSender` có `serviceCode` này (ERR-14-119, cảnh báo SO).
2. Kích thước, định dạng, loại thông báo theo hợp đồng chiều vào (ERR-14-121).
3. Xác minh chữ ký khi `signatureRequired` bằng chính `SignatureVerifier` của chiều ra; sai thì mở sự cố chữ ký như ở 4.9.
4. Chống phát lại: `SET NX EX {14.inbound.replay-window-seconds}` theo `messageId` và kiểm thời điểm ký trong cửa sổ. Trùng `messageId` mà lượt trước đã xong thì trả lại đúng kết quả đã lưu (mã hóa, giữ trong cửa sổ) thay vì xử lý lại; lượt trước còn chạy thì ERR-14-122 kèm `Retry-After`.
5. Ghi giao dịch `INBOUND` ở `RECEIVED` rồi chuyển cho `InboundDispatcher`.

**Chuyển cho luồng PH-04.** Ánh xạ (điểm cuối, dịch vụ) → luồng nằm trong ảnh chụp (`flowMap`), do người dùng khai ở UI-14-10 và kiểm luồng đã phát hành khi lưu (ERR-14-039). `InboundDispatcher` gọi điểm vào HTTP của luồng qua mesh với mTLS, tiêu đề `dhtenant`, `traceparent`, `X-DH-Transaction`, thời hạn `14.inbound.timeout-ms` (mặc định 10 giây); luồng không biết mTLS hay chữ ký. Phản hồi của luồng được kiểm theo hợp đồng chiều vào, ký bởi `ReceiptSigner` (dùng `TransitSigner` như 4.8) rồi trả cho nền tảng. Dịch vụ xử lý lâu: cổng trả ngay `202` kèm biên nhận ký, kết quả gửi sau bằng chiều ra qua `AsyncAcceptor` (4.13). Luồng trả lỗi nghiệp vụ có chủ ý (ví dụ không tìm thấy) được dịch sang lỗi theo định dạng của trung ương chứ không là ERR-14-124; luồng lỗi, quá hạn hay chưa phát hành là ERR-14-124 với nội dung đã che. `InboundErrorRenderer` chọn định dạng lỗi theo cấu hình điểm cuối (mặc định RFC 9457, Q14-06 của FRS còn mở).

**Cô lập tải.** `InboundGateway` dùng nhóm luồng và `Bulkhead` riêng, độc lập với chiều ra, để tải của quốc gia không làm nghẽn luồng nội bộ và ngược lại, giữ mục tiêu sẵn sàng 99,95% (NFR-14-008). Thông báo thay đổi từ quốc gia (API-14-085, Đợt 2) qua cùng các bước xác minh, rồi phát EVT-14-17 cho PH-07 và trả xác nhận; cổng không tự áp dụng thay đổi.

**Đăng ký điểm cuối.** `EndpointService` quản lý vòng đời `DRAFT` → `PENDING_ACTIVATION` → `ACTIVE` → `DISABLED`; bật cần ít nhất một nguồn được phép, luồng ánh xạ đã phát hành và duyệt bốn mắt (BR-14-022); API-14-090 ghi nhận người dùng đã xác nhận vân tay chứng thư của nguồn sau khi tỉnh đăng ký địa chỉ với trung ương (việc ngoài hệ thống). Mọi thay đổi phát EVT-14-13 để PH-03 cập nhật tuyến APISIX.

### 4.15. Đồng bộ danh mục dịch vụ, dữ liệu chủ và dữ liệu mở

::: dac-ta
**Mục đích.** Thực hiện nghĩa vụ đăng ký danh mục dịch vụ chia sẻ lên hệ thống của Bộ một cách tự động và chứng minh được, và (Đợt 3) cầu nối dữ liệu chủ cùng công bố dữ liệu mở lên NDOP, với biên nhận và đối soát từng bản ghi.

**Lớp chính.** `SyncPlanner`, `SyncBatchBuilder`, `SyncScheduler`, `SyncResultConsumer`, `ComplianceWatcher`, `OpenDatasetService`, `MasterDataBridge` (control); `SyncRunner`, `CatalogSyncJob`, `MasterDataSyncJob`, `OpenDataSyncJob`, `ReceiptPoller` (worker).

**Đơn vị chạy.** `dh-integration` lập kế hoạch và ghi kết quả; `dh-runtime` vai trò `worker` gửi (vì cần egress, chữ ký, thông tin xác thực).

**FR hiện thực.** FR-14-043, 044, 045, 046.

**Giao diện vào.** API-14-053…057, 087, 088; sự kiện PH-02 "đã công bố".

**Phụ thuộc ra.** PH-02 (danh sách dịch vụ chia sẻ), PH-07 (ánh xạ), PH-09 (kiểm lô), PH-06 (Đợt 3), Ceph RGW (lô đồng bộ), Kafka (lệnh và kết quả), nền tảng `REGISTRY`, NDOP.

**Dữ liệu.** `sync_run`, `sync_record` (giữ 3 năm); lô ở bucket `dh-nat-sync`.

**Sự kiện.** EVT-14-12 khi phiên kết thúc.

**Lỗi và xử lý.** Phiên đang chạy: ERR-14-026; bên nhận từ chối: ERR-14-028; PH-02 hay PH-06, PH-07, PH-09 ngừng: ERR-14-027; thiếu ánh xạ lô dữ liệu chủ: ERR-14-125; PH-09 chặn: ERR-14-126.

**Quan sát.** `national_sync_runs_total{kind,state}`, `national_sync_last_success_timestamp{kind}`, `national_sync_records_total{kind,outcome}`, `national_sync_lag_days`.
:::

Chi tiết thiết kế:

**Tách việc lập kế hoạch và việc gửi.** Vì `dh-integration` không có đường ra, `SyncPlanner` làm phần cần PostgreSQL và các phân hệ nội bộ: lấy danh sách dịch vụ chia sẻ `PUBLISHED` của đúng tenant từ PH-02 (BR-14-035; PH-02 ngừng: ERR-14-027), so băm mô tả với lần thành công trước để chọn bản ghi mới hoặc đổi (`onlyChanged`), ghi `sync_run` `PLANNED` và lô bản ghi vào `dh-nat-sync/{runId}.jsonl`. Sau đó phát lệnh `sync.run` (mã phiên, loại, tham chiếu lô, `dryRun`) lên `{tenant}.national.worker.command.v1`. `SyncRunner` của `worker` chuyển từng bản ghi sang định dạng của hệ thống nhận, kiểm theo lược đồ (sai: `REJECTED_LOCAL`, bản ghi khác vẫn đi), gửi qua `DispatchStage` (ký nếu nền tảng yêu cầu) với khóa chống trùng (mã dịch vụ, phiên bản), nhịp `14.sync.rate-per-minute` khi bên nhận không hỗ trợ lô, thử lại tối đa `14.sync.max-retries` với độ trễ tăng dần. Cứ 100 bản ghi hoặc 5 giây, `worker` trả tiến độ và kết quả từng bản ghi (`ACCEPTED`, `REJECTED` kèm lý do, `PENDING`) lên `{tenant}.national.worker.result.v1`; `SyncResultConsumer` cập nhật `sync_run`, `sync_record` và khi xong phát EVT-14-12. Bản ghi `PENDING` được `ReceiptPoller` hỏi lại mỗi 15 phút tới 24 giờ.

**Chống chạy chồng.** Mỗi (tenant, loại) có tối đa một phiên chưa kết thúc, bảo đảm bằng chỉ mục duy nhất từng phần trên `sync_run` (ERR-14-026) và khóa ShedLock cho bộ lập lịch. Ba cách kích hoạt dùng chung một đường: lịch `14.sync.catalog-cron` (mặc định `0 0 2 * * *` giờ Việt Nam, không dày hơn 1 giờ), sự kiện PH-02 có dịch vụ chia sẻ mới `PUBLISHED` (gom 60 giây), và API-14-054 chạy tay.

**Nghĩa vụ tuân thủ.** `ComplianceWatcher` hằng ngày tính số ngày từ lần thành công gần nhất; quá `14.sync.stale-alert-days` thì đặt `national_sync_lag_days`, gửi thông báo cho TA, SO và lãnh đạo (BR-14-026). Phiên thất vì hệ thống của Bộ không phản hồi được thử lại theo độ trễ tăng dần trong 24 giờ; người dùng chạy tay trong lúc đó nhận ERR-14-103.

**Dữ liệu chủ và dữ liệu mở (Đợt 3).** `MasterDataBridge` và `OpenDatasetService` tái dùng đường trên, thêm hai cổng trước khi lập lô: kiểm đủ ánh xạ ở PH-07 (thiếu: ERR-14-125) và kiểm PH-09 lô không chứa trường cấm gửi ra ngoài tỉnh hay công bố (chặn: ERR-14-126), tương ứng BR-14-010. Lần công bố đầu của một tập dữ liệu mở qua `FourEyesGuard` (BR-14-022); rút công bố qua API-14-088. Định dạng, kênh và tần suất đồng bộ dữ liệu chủ chưa được trung ương công bố (Q14-13 của FRS), nên phần này mới thiết kế ở mức khung, chưa chốt lược đồ lô.

### 4.16. Sổ giao dịch, nội dung bản tin, đối soát và nhật ký khai thác

::: dac-ta
**Mục đích.** Mọi lượt gọi ra và nhận vào đều để lại một giao dịch có mã đối soát, trạng thái cuối và bằng chứng; nội dung bản tin chỉ lưu mã hóa, ngắn hạn, và chỉ Cán bộ ATTT xem được có lý do; nhật ký khai thác theo HTTT phục vụ thanh tra.

**Lớp chính.** `LedgerWriter`, `LedgerSpool`, `EventPublisher`, `PayloadVault`, `SubjectKeyHasher` (cổng); `LedgerConsumer`, `UsageAggregator`, `LedgerArchiver`, `TransactionQuery`, `RevealService`, `EvidenceExporter`, `UsageReportService`, `PayloadRetentionApplier` (control).

**Đơn vị chạy.** `dh-runtime` (ghi); `dh-integration` (lưu, tra cứu, xem, xuất).

**FR hiện thực.** FR-14-049, 050, 051, 052 (và nền cho FR-14-010).

**Giao diện vào.** API-14-061…066.

**Phụ thuộc ra.** Kafka (EVT-14-11), Ceph RGW (`dh-nat-payload`, WORM), OpenBao `transit` (mã hóa, giải mã bằng khóa `dh-{tenant}-pii`, ký bằng chứng), PH-12 (xác thực lại nhiều yếu tố), PH-13 (SIEM).

**Dữ liệu.** `national_transaction` (phân vùng theo tháng, 12 tháng trực tuyến rồi WORM 5 năm), `usage_hourly`; nội dung mã hóa ở Ceph RGW.

**Sự kiện.** EVT-14-11 (mỗi giao dịch), EVT-14-16 (xem nội dung vượt ngưỡng).

**Lỗi và xử lý.** Chưa xác thực lại: ERR-14-030; nội dung hết hạn hoặc không lưu: ERR-14-031; khoảng tra quá rộng hoặc thiếu lý do: ERR-14-003; bộ đệm đĩa đầy: ERR-14-127.

**Quan sát.** `national_ledger_spool_bytes`, `national_ledger_lag_seconds`, `national_payload_dropped_total`, `national_reveal_total{result}`.
:::

Chi tiết thiết kế:

**Đường ghi bền từ cổng.** `LedgerWriter.record` thêm một dòng vào `LedgerSpool`, tệp nhật ký ghi trước ở đĩa tạm của pod (đoạn 16 MiB, `fsync` mỗi 100 ms hoặc 64 bản ghi, kích thước tối đa `14.spool.max-mb`, mặc định 512). `EventPublisher` đọc từ spool và gửi lên chủ đề EVT-14-11 bằng nhà sản xuất lũy đẳng `acks=all`, khóa là `transactionCode`, rồi dịch điểm kiểm; khởi động lại thì phát lại từ điểm kiểm (ít nhất một lần). Mọi sự kiện phát từ mặt phẳng dữ liệu (EVT-14-07, 10, 11, 15, 17 và chủ đề nội bộ) dùng chung spool này. Spool đầy, nghĩa là Kafka đã ngừng rất lâu, thì cổng ngừng nhận lượt cần gọi ra mới với ERR-14-127 thay vì bỏ bản ghi: toàn vẹn nhật ký khai thác (KPI-07) được đặt trên khả dụng. Với tải giả định GĐ-14-03 (9 lượt/giây cao điểm, mỗi bản ghi khoảng 1,5 KiB) 512 MiB đủ cho hơn 10 giờ; rủi ro còn lại khi mất đồng thời Kafka và pod ghi ở 13.2.

**Bản ghi giao dịch.** `TransactionRecord` mang `transactionCode`, hướng, dịch vụ, nền tảng, `systemCode`, `purposeCode`, `procedureCode`, `caseCode`, trạng thái cuối, `fromCache`, `stale`, `routedVia`, `durationMs`, `certCode`, `traceId`, `payloadRef`, `payloadHash` và `lookupKeyHash`. `lookupKeyHash` là HMAC-SHA256 của định danh đối tượng được tra (đường dẫn trong `params` do `subjectKeyPaths` của thao tác khai báo, ví dụ `$.citizenId`) bằng khóa riêng của tenant; nhờ đó bộ phát hiện bất thường đếm được "bao nhiêu đối tượng khác nhau được tra" mà không lưu định danh (SEC-60, THR-54). Nhật ký thường và chỉ số không bao giờ chứa nội dung hay định danh thô (BR-14-021).

**Nội dung mã hóa.** Khi `14.txn.payload-retention-days` > 0 (mặc định 30, tối đa 180, đổi cần duyệt vì ★), `PayloadVault` mã hóa thân yêu cầu và thân phản hồi bằng AES-256-GCM với DEK của tenant (AAD gồm tenant, `transactionCode`, loại) rồi ghi bất đồng bộ vào `dh-nat-payload/{tenant}/{yyyy}/{MM}/{transactionCode}.{req|res}.enc` sau khi đã trả lời bên gọi, qua hàng đệm trong bộ nhớ 10.000 mục; hàng đầy thì bỏ mục, tăng `national_payload_dropped_total` và để `payloadRef` rỗng (việc xem nội dung khi đó trả ERR-14-031), không bao giờ chặn đường gọi. Tham số bằng 0 thì không ghi. `PayloadRetentionApplier` đặt luật vòng đời của bucket theo tiền tố tenant mỗi khi tham số đổi.

**Đường ghi vào PostgreSQL.** `LedgerConsumer` tiêu thụ EVT-14-11 theo lô 500 bản ghi hoặc 200 ms, chèn `national_transaction` bằng `INSERT … ON CONFLICT DO NOTHING RETURNING`; chỉ các dòng chèn mới được `UsageAggregator` cộng vào `usage_hourly` theo (giờ, HTTT, dịch vụ, mục đích, kết quả, nguồn đệm) trong cùng giao dịch. Cách này giữ `usage_hourly` đúng dù Kafka giao lại thông điệp. Độ trễ từ lúc giao dịch kết thúc tới lúc tra cứu được là một chuyến Kafka cộng một lô ghi, mục tiêu p99 ≤ 5 giây (giả định) và đo bằng `national_ledger_lag_seconds`. Phân vùng quá 12 tháng được `LedgerArchiver` xuất sang kho WORM của Ceph RGW kèm chuỗi băm theo ADR-031 trước khi tháo phân vùng (SEC-62).

**Tra cứu và đối soát.** `TransactionQuery` tra theo mã (khóa b-tree, O(1)) hoặc bộ lọc (thời gian, HTTT, dịch vụ, trạng thái, mã hồ sơ) với phân trang keyset và khoảng thời gian tối đa 31 ngày (vượt: ERR-14-003); `PERM-14-audit-read` chỉ thấy siêu dữ liệu đã che. Hàng đợi bất đồng bộ và `UNKNOWN_RESULT` cùng hiện ở UI-14-12.

**Xem nội dung đầy đủ.** `RevealService` thực hiện theo thứ tự: kiểm quyền `audit-reveal`; kiểm phiên đã xác thực lại nhiều yếu tố trong 5 phút (claim `acr` và `auth_time`, nếu không thì ERR-14-030); kiểm lý do 10 đến 500 ký tự; kiểm `payloadRef`; **ghi kiểm toán trước** (người, giao dịch, lý do, mã phiếu, thời điểm) và chỉ khi bản ghi kiểm toán đã bền mới đọc đối tượng, giải mã bằng `transit/decrypt` của khóa tenant (lỗi OpenBao: ERR-14-035) và trả cho BFF để hiển thị 60 giây kèm hình mờ tên người xem. Đếm lượt xem mỗi người mỗi ngày; vượt `14.reveal.max-per-day` thì phát EVT-14-16 (loại `REVEAL_EXCESS`). Ghi kiểm toán thất bại thì từ chối xem, không bao giờ xem mà không để lại vết (BR-14-021).

**Xuất bằng chứng (Đợt 2).** `EvidenceExporter` dựng gói gồm siêu dữ liệu giao dịch, băm, kết quả ký và xác minh, đường chuỗi băm của nhật ký, ký bằng khóa `transit` `dh-{tenant}-nat-evidence` của `dh-integration` (đề nghị thêm vào SEC-36), chạy bất đồng bộ và để tệp ở Ceph RGW với liên kết tải 24 giờ. Kiểm toán viên nhận bằng chứng này thay vì xem nội dung thô.

### 4.17. Kiểm tra kết nối, sức khỏe và tổng quan

::: dac-ta
**Mục đích.** Phát hiện sớm khi một nền tảng mất kết nối hay suy giảm bằng kiểm tra chủ động nhẹ kết hợp tỷ lệ lỗi thật, và dựng màn tổng quan một chỗ cho vận hành, Cán bộ ATTT và lãnh đạo.

**Lớp chính.** `PlatformProbe`, `ProbeStep` (DNS, TCP, TLS, token, deep), `HealthEvaluator`, `PassiveStats` (cổng); `HealthStateStore`, `DashboardService`, `OutageRecorder` (control).

**Đơn vị chạy.** `dh-runtime` vai trò `worker`; `dh-integration`.

**FR hiện thực.** FR-14-047, 048.

**Giao diện vào.** API-14-058 (sức khỏe), API-14-059 (kiểm tra tay), API-14-060 (tổng quan).

**Phụ thuộc ra.** Egress (kiểm tra), `TokenManager`, Valkey (thống kê thụ động theo phút), kho chỉ số LGTM (đọc cho tổng quan).

**Dữ liệu.** `health_sample` (90 ngày, gộp theo giờ sau 7 ngày), `platform_outage`.

**Sự kiện.** EVT-14-15 khi mức sức khỏe đổi.

**Lỗi và xử lý.** Kiểm tay quá số lần mỗi giờ: ERR-14-029; địa chỉ ngoài danh sách egress: kết quả `EGRESS_DENIED` (không phải lỗi HTTP); worker ngừng: mức `UNKNOWN`.

**Quan sát.** `national_connectivity_status{platform}` (0 đến 3), `national_probe_duration_seconds{step}`, `national_outage_seconds_total{platform}`.
:::

Chi tiết thiết kế:

`PlatformProbe` chạy ở `worker` mỗi `14.health.interval-seconds` (60 giây ở môi trường thật, 300 giây ở môi trường khác) qua lịch có độ lệch ngẫu nhiên theo nền tảng; các bước DNS, TCP, TLS (ghi hạn và chuỗi chứng thư máy chủ nền tảng), lấy token mỗi bước hạn 5 giây, tổng ≤ 20 giây. Bước `deep` (theo yêu cầu) gọi `healthOperation` của nền tảng qua `DispatchStage` ở ưu tiên `BACKGROUND` nên tính hạn mức nhưng không cạnh tranh với dịch vụ thiết yếu. Kiểm tra tay chạy bằng lệnh `probe` gửi qua `{tenant}.national.worker.command.v1`, kết quả từng bước trả về qua chủ đề kết quả và hiển thị theo thời gian thực ở UI-14-03; giới hạn `14.test.max-per-hour` kiểm ở `dh-integration` trước khi phát lệnh (ERR-14-029).

`HealthEvaluator` kết hợp kết quả chủ động với thống kê thụ động: mỗi bản sao `gateway` cộng dồn theo phút vào Valkey (`{t68}:nat:hs:{platform}:{minute}`: số lượt tốt, số lượt lỗi, các thùng độ trễ), `worker` đọc 5 phút gần nhất. Bảng ngưỡng của FRS (`HEALTHY`, `DEGRADED`, `UNHEALTHY`, `UNKNOWN`) hiện thực nguyên văn; chống dao động bằng hai chu kỳ liên tiếp trước khi xuống `UNHEALTHY` và một chu kỳ khi lên (NFR-14-007: phát hiện ≤ 3 phút ở chu kỳ 60 giây). Khi mức đổi, `worker` phát EVT-14-15 và đặt `national_connectivity_status`; `HealthStateStore` ghi trạng thái hiện hành, mẫu và khoảng gián đoạn (`OutageRecorder`) từ chủ đề kết quả. `UNHEALTHY` quá 5 phút thì `dh-integration` gửi cảnh báo mức cao cho TO và TA, và nếu `14.health.notify-platform-contact` bật thì báo đầu mối kỹ thuật của nền tảng.

`DashboardService` dựng UI-14-01 từ bốn nguồn: thẻ nền tảng và hạn mức, chứng thư, sự cố từ PostgreSQL; chỉ số lưu lượng (số lượt, tỷ lệ thành công, độ trễ p95, tỷ lệ trúng đệm, lượt phục vụ dữ liệu cũ) từ kho chỉ số LGTM; hàng chờ từ Valkey; dự báo cạn từ `QuotaForecaster`. Kho chỉ số không khả dụng thì màn vẫn hiện phần PostgreSQL kèm ghi chú "Số liệu lưu lượng tạm thời chưa có" (FR-14-048 luồng thay thế). Biểu ngữ đỏ sự cố chữ ký chưa xác nhận lấy từ `national_signature_incidents_open` và không ẩn được.

### 4.18. Cảnh báo bất thường khai thác

::: dac-ta
**Mục đích.** Phát hiện sớm HTTT tra cứu dữ liệu quốc gia bất thường (hàng loạt, ngoài giờ, tăng đột biến, một mã hồ sơ tra nhiều người) vì cả tỉnh dùng chung một tài khoản NDXP và rủi ro lạm dụng nằm ở đây (THR-51).

**Lớp chính.** `AnomalyDetector`, `AnomalyRules` (bốn luật), `BaselineCalculator`, `AnomalyAlertService`, `WaiverService`.

**Đơn vị chạy.** `dh-integration`.

**FR hiện thực.** FR-14-053 (và FR-14-057 phần báo cáo).

**Giao diện vào.** Lịch 15 phút; API-14-067, 068.

**Phụ thuộc ra.** PH-02 (đề nghị thu hồi quyền gọi), PH-13 (SIEM), thông báo PH-12.

**Dữ liệu.** `usage_hourly`, `national_transaction` (cột `lookup_key_hash`), `anomaly_alert` (giữ 5 năm), `anomaly_waiver`.

**Sự kiện.** EVT-14-16.

**Lỗi và xử lý.** Kết thúc cảnh báo thiếu lý do: ERR-14-003; PH-02 ngừng khi đề nghị thu hồi: ERR-14-027.

**Quan sát.** `national_anomaly_alerts_open`, `national_anomaly_detect_duration_seconds`, `national_anomaly_alerts_total{rule}`.
:::

Chi tiết thiết kế:

`AnomalyDetector` chạy mỗi 15 phút dưới ShedLock, mỗi tenant một lượt, chỉ xét dịch vụ chứa dữ liệu cá nhân (`sensitivity` từ `RESTRICTED`) và chỉ khi có đủ 7 ngày `usage_hourly` để dựng đường chuẩn. Bốn luật theo tham số `14.anomaly.*`:

| Luật | Điều kiện | Nguồn |
|---|---|---|
| `MASS_LOOKUP` | Số `lookup_key_hash` khác nhau của một HTTT trong giờ > `14.anomaly.lookups-per-hour` | `national_transaction`, 60 phút gần nhất |
| `OFF_HOURS` | Số lượt ngoài khung giờ làm việc của tenant > `14.anomaly.off-hours-calls` | `usage_hourly` |
| `SPIKE` | Lượt trong giờ > `14.anomaly.spike-factor` lần trung bình 7 ngày cùng giờ | `usage_hourly`, đường chuẩn |
| `CASE_FANOUT` | Một `caseCode` gắn với > `14.anomaly.subjects-per-case` đối tượng khác nhau | `national_transaction` |

: Bốn luật phát hiện bất thường

Khi một luật vượt, `AnomalyAlertService` tạo `anomaly_alert` `OPEN` kèm bằng chứng tóm tắt (số liệu và danh sách mã giao dịch mẫu, không có định danh), gửi SO và TA trong 15 phút (SEC-67) và phát EVT-14-16. `WaiverService` cho TA khai trước "cửa sổ đã báo" (HTTT, dịch vụ, từ, đến, lý do) để luật bỏ qua trong thời gian đó, ví dụ đợt đối chiếu cuối tháng. SO xử lý bằng một trong ba quyết định: xác nhận hợp lệ (kèm lý do), đề nghị thu hồi quyền gọi (chuyển sang PH-02), hoặc tạm dừng dịch vụ cho HTTT đó. Quyết định thứ ba ghi một mục vào danh sách chặn `blocks[]` (`systemCode`, `serviceCode`, lý do, hết hạn) trong ảnh chụp cấu hình, và `PurposeStage` từ chối lượt khớp danh sách này với ERR-14-106 sau tối đa 30 giây. Mỗi cảnh báo phải kết thúc với lý do (ERR-14-003 nếu thiếu).

### 4.19. Tham số theo tenant và chuyển đổi từ hệ cũ

::: dac-ta
**Mục đích.** Quản lý tham số `14.*` theo tenant với kiểm tra miền và duyệt bốn mắt cho tham số bảo mật, và đưa kết nối quốc gia từ hệ cũ sang hệ mới một cách có đối chiếu: nhập cấu hình từ phụ lục NGSP, chạy song song phần đọc, chỉ cắt chuyển khi đủ khớp và khóa cũ đã thu hồi.

**Lớp chính.** `SettingsService`, `ParameterRegistry`, `ParameterDescriptor`; `LegacyImporter`, `LegacyAppendixParser`, `SecretColumnGuard`; `ParallelRunService`, `ParallelComparator`, `FieldHashMap`.

**Đơn vị chạy.** `dh-integration`; phần quan sát chạy song song nhận từ luồng PH-04.

**FR hiện thực.** FR-14-054, 055, 056.

**Giao diện vào.** API-14-070, 071; API-14-072, 073, 089; API-14-074.

**Phụ thuộc ra.** PH-18 (`ParameterApi`), PH-04 (luồng cắt chuyển), module `adapter` (kiểm tra kết nối).

**Dữ liệu.** Giá trị tham số ở PH-18; `parallel_run`, `parallel_sample` (giữ mẫu 90 ngày), `legacy_import`.

**Sự kiện.** EVT-14-02 khi nhập dịch vụ từ hệ cũ; EVT-14-01 khi đổi tham số ảnh hưởng nền tảng.

**Lỗi và xử lý.** Giá trị ngoài miền: ERR-14-036; tệp nhập sai: ERR-14-032 (không áp dụng gì); chạy song song cho thao tác ghi hoặc trùng phiên: ERR-14-033; đóng khi chưa thu hồi khóa cũ: ERR-14-004.

**Quan sát.** `national_parallel_match_ratio{service}`, `national_parallel_samples_total{outcome}`, `national_legacy_import_total{result}`.
:::

Chi tiết thiết kế:

**Tham số.** `ParameterRegistry` giữ mô tả của 46 tham số `14.*` (khóa, kiểu, mặc định, miền, nhãn ★) lấy nguyên từ FRS §8.2; `SettingsService` kiểm miền và các ràng buộc chéo (ví dụ `14.quota.background-defer-ratio` < `14.quota.essential-only-ratio`, `14.cache.stale-max-seconds` không dài hơn 3 ngày) trước khi gọi `ParameterApi` của PH-18 ghi giá trị. Tham số ★ không ghi ngay mà tạo yêu cầu qua `FourEyesGuard` (BR-14-022). Giá trị hiệu lực đi vào ảnh chụp cấu hình nên cổng áp trong 30 giây (NFR-14-026); `dh-integration` đọc tham số qua `ParameterApi` với bộ đệm 60 giây.

**Nhập từ hệ cũ.** `LegacyAppendixParser` đọc phụ lục NGSP (CSV, XLSX, JSON) như dữ liệu, không thực thi gì. Mỗi dòng thành một dịch vụ `DRAFT` với chính sách mặc định của nhóm (bảng ở 4.6) và `reconcileLabel = UNKNOWN`. `SecretColumnGuard` loại mọi cột có tên giống khóa, bí mật, mật khẩu và quét giá trị bằng `SecretDetector` của PH-04; nếu thấy thì bỏ cột, báo "đã bỏ qua cột chứa bí mật" và không lưu, hiện thực BR-14-034 ở cửa nhập. Việc nhập là tất cả hoặc không: một dòng sai thì ERR-14-032 kèm bảng lỗi theo dòng, cột và không dịch vụ nào được tạo.

**Chạy song song phần đọc.** `ParallelRunService` kiểm dịch vụ là `READ` và chưa có phiên (ERR-14-033), đặt tỷ lệ lấy mẫu (tự giảm khi hạn mức thấp, kèm cảnh báo). Luồng cắt chuyển của PH-04 sao yêu cầu đọc sang cổng với tiêu đề `X-DH-Parallel-Run` và ưu tiên `BACKGROUND`; cổng trả thêm `fieldHashes` (băm SHA-256 của từng trường mức một và hai sau khi bỏ trường biến động như thời điểm, mã giao dịch theo `ignorePaths`). Luồng PH-04 gửi băm tương ứng của kết quả đường cũ tới API-14-089. `ParallelComparator` so hai bản đồ băm nên **không bao giờ cần nội dung dữ liệu cá nhân**; cặp khớp, khác ở trường nào, hoặc lỗi một bên được ghi vào `parallel_sample`. Tỷ lệ khớp theo ngày tính từ đó; đạt `14.parallel.match-ratio` liên tục `14.parallel.min-days` ngày với ít nhất `14.parallel.min-samples` mẫu thì đặt `readyForCutover`. Hệ thống không bao giờ tự sửa kết quả (BR-14-033) và chặn đóng phiên khi bước thu hồi khóa cũ của 4.7 chưa xong.

## 5. Biểu đồ tuần tự

Mười sơ đồ dưới đây phủ các chức năng có từ ba thành phần tương tác trở lên hoặc có duyệt bốn mắt. Thông điệp không dùng dấu chấm phẩy; mã lỗi nêu theo FRS §9.1.

### 5.1. Gọi dịch vụ quốc gia: mục đích, đệm, hạn mức, ký, xác minh (FR-14-010, 011, 012, 033, 035, 026, 027)

Sơ đồ dưới theo dõi một lượt tra cứu từ HTTT tỉnh tới NDXP qua đường chín chặng, gồm cả nhánh trúng đệm và nhánh gọi thật.

```{.mermaid caption="Gọi dịch vụ quốc gia qua đường chín chặng (FR-14-010, 011, 012, 033, 035, 026, 027)"}
sequenceDiagram
  autonumber
  participant H as HTTT HT-TUPHAP
  participant A as APISIX
  participant G as Cổng quốc gia gateway
  participant O as OPA
  participant V as Valkey
  participant B as OpenBao
  participant N as NDXP
  participant K as Kafka
  H->>A: POST invocations kèm token Datahub, mục đích, mã hồ sơ
  A->>G: chuyển tiếp, tiêu đề tenant do APISIX gắn
  G->>G: chặng 1 và 2: xác minh JWT, tra dịch vụ, nền tảng ACTIVE
  G->>O: chặng 3: kiểm tra HTTT, dịch vụ, mục đích, khung giờ
  O-->>G: cho phép
  G->>V: chặng 5: GET khóa đệm tenant, dịch vụ, băm tham số
  alt trúng đệm còn hạn
    V-->>G: mục đệm
    G->>K: EVT-14-11 giao dịch COMPLETED_CACHE qua spool
    G-->>H: 200 fromCache true, X-DH-Cache HIT
  else không trúng
    V-->>G: không có
    G->>V: chặng 6: script quota_try trừ các bộ đếm
    V-->>G: allowed, tỷ lệ dùng
    G->>G: định tuyến theo luật, lấy token trong bộ nhớ
    G->>B: gửi băm cần ký tới transit/sign
    B-->>G: chữ ký
    G->>N: gửi bản tin đã ký qua egress, mTLS
    N-->>G: phản hồi kèm chữ ký
    G->>G: chặng 7: xác minh chữ ký, chuỗi tin cậy, thời điểm, messageId
    G->>G: chặng 8: chuẩn hóa JSON, lọc trường theo hợp đồng
    G->>V: chặng 9: SET đệm với thời hạn của dịch vụ
    G->>K: EVT-14-11 giao dịch SUCCEEDED qua spool
    G-->>H: 200 fromCache false, signatureVerified true
  end
```

Hình cho thấy hai điều. Kiểm tra mục đích (bước 4) đứng trước đọc đệm (bước 6) nên đệm không là đường vòng qua ủy quyền. Chỉ nhánh không trúng đệm mới tốn hạn mức, gọi OpenBao và gọi ra ngoài; nhánh trúng đệm hoàn tất không rời cổng, đúng ngân sách p99 ≤ 15 ms của NFR-14-004. Ở mọi nhánh, bản ghi giao dịch đi qua `LedgerSpool` tới Kafka, không có mũi tên nào tới PostgreSQL.

### 5.2. Chữ ký phản hồi sai, sự cố chữ ký và giữ an ninh (FR-14-027, 031)

Sơ đồ dưới cho thấy một phản hồi có chữ ký sai đi từ lúc bị từ chối ở cổng tới lúc Cán bộ ATTT giải trừ giữ an ninh, với hai đường chạy song song.

```{.mermaid caption="Chữ ký phản hồi sai, mở sự cố và giữ an ninh (FR-14-027, 031)"}
sequenceDiagram
  autonumber
  participant N as NDXP
  participant G as Cổng gateway
  participant V as Valkey
  participant K as Kafka
  participant S as SignatureIncidentService
  participant P13 as PH-13 SIEM
  actor SO as Dũng (SO)
  N-->>G: phản hồi có chữ ký không khớp
  G->>G: chặng 7: SignatureVerifier ném ERR-14-109
  G->>V: ZADD sigfail nền tảng, đếm trong 10 phút
  V-->>G: số sự cố đạt ngưỡng 5
  G->>V: SET hold nền tảng, đặt cờ cục bộ
  G->>K: signature.failed và hold-entered qua spool
  G-->>G: giao dịch SIGNATURE_FAILED, không trả dữ liệu
  K->>S: signature.failed
  S->>S: tạo signature_incident OPEN, outbox EVT-14-06
  S->>S: ghi securityHold true, outbox EVT-14-01
  S-->>SO: thông báo trong 1 phút, biểu ngữ đỏ ở UI-14-01
  S->>P13: sự kiện an ninh qua EVT-14-06
  SO->>S: xác nhận, phân loại, nhập kết luận
  SO->>S: giải trừ giữ an ninh có lý do
  S->>S: kiểm không còn sự cố OPEN, securityHold false
  S->>V: DEL hold nền tảng
  S->>K: EVT-14-01 ra khỏi SECURITY_HOLD
```

Có hai đường chạy song song: đường cưỡng chế (bước 3 đến 5) dùng Valkey và bộ nhớ nên chặn ngay các lượt tiếp theo, đường hồ sơ (bước 8 đến 12) qua Kafka và PostgreSQL nên có thể chậm vài giây mà không làm hở cưỡng chế. Giải trừ chỉ đi qua `SignatureIncidentService` của `dh-integration` và bị chặn khi còn sự cố `OPEN`, nên cổng không tự giải trừ.

### 5.3. Làm mới token và xoay thông tin xác thực có chuyển tiếp (FR-14-024, 025)

Sơ đồ dưới mô tả việc kiểm tra giá trị chờ, cửa sổ chuyển tiếp và xác nhận thu hồi khóa cũ khi xoay thông tin xác thực.

```{.mermaid caption="Làm mới token và xoay thông tin xác thực có chuyển tiếp (FR-14-024, 025)"}
sequenceDiagram
  autonumber
  actor TO as Chi (TO)
  participant CP as CredentialRotationService
  participant PH5 as PH-05 adapter
  participant K as Kafka
  participant W as Cổng worker
  participant G as Cổng gateway
  participant B as OpenBao
  participant N as NDXP
  TO->>PH5: đặt giá trị chờ ở kết nối ndxp-t68-oauth
  PH5->>B: ghi kv phiên bản chờ, chỉ ghi một chiều
  TO->>CP: bắt đầu xoay, kiểm tra
  CP->>K: lệnh token.test, phiên bản chờ
  K->>W: lệnh
  W->>B: đọc phiên bản chờ bằng danh tính Kubernetes
  W->>N: xin token bằng giá trị chờ
  N-->>W: token, hạn, scope
  W->>K: kết quả OK, hạn, scope, không có token
  K->>CP: kết quả
  CP-->>TO: Đạt, hạn 3600 giây
  TO->>CP: xác nhận chuyển
  CP->>CP: cửa sổ chuyển tiếp 24 giờ, EVT-14-01
  G->>B: SecretVersionSelector đọc phiên bản mới và cũ
  G->>N: xin token bằng phiên bản mới
  alt nền tảng chấp nhận
    N-->>G: token mới
  else bị từ chối invalid_client
    N-->>G: 401
    G->>N: xin token bằng phiên bản cũ
    N-->>G: token
    G->>G: tăng national_secret_fallback_total
  end
  CP-->>TO: hết cửa sổ, yêu cầu nhập revocationReceipt
  TO->>CP: nhập xác nhận trung ương đã hủy khóa cũ
  CP->>PH5: đề nghị hủy phiên bản cũ
  CP->>CP: đóng xoay, đặt lại tuổi bí mật
```

Giá trị bí mật không đi qua PH-14 ở bước nào: người dùng đặt giá trị chờ ở PH-05, cổng đọc thẳng OpenBao. Kết quả kiểm tra chỉ mang `OK`, hạn và phạm vi, không mang token. Nhánh `else` cho thấy vì sao cửa sổ chuyển tiếp cần giữ phiên bản cũ: nền tảng có thể chưa kích hoạt khóa mới ở mọi nút; chỉ số dự phòng tăng báo cho vận hành trước khi phiên bản cũ bị hủy.

### 5.4. Khai báo, kiểm tra và bật nền tảng bốn mắt (FR-14-002, 003, 047)

Sơ đồ dưới cho thấy các bước từ khai báo tới bật nền tảng ở môi trường thật, trong đó điều kiện duyệt được kiểm hai lần.

```{.mermaid caption="Khai báo, kiểm tra kết nối và bật nền tảng bốn mắt (FR-14-002, 003, 047)"}
sequenceDiagram
  autonumber
  actor TA as Lan (TA)
  actor IA as Bình (IA)
  participant CP as PlatformService
  participant PH5 as PH-05 adapter
  participant K as Kafka
  participant W as Cổng worker
  participant N as NDXP
  participant G as Cổng gateway
  TA->>CP: POST platforms, loại NDXP, kết nối PH-05
  CP->>PH5: verify kết nối oauth2-client đúng loại
  PH5-->>CP: hợp lệ
  CP->>CP: lưu DRAFT, outbox EVT-14-01
  TA->>CP: POST platforms:probe
  CP->>K: lệnh probe
  K->>W: lệnh
  W->>N: DNS, TCP, TLS, lấy token
  N-->>W: kết quả từng bước
  W->>K: kết quả PASSED từng bước
  K->>CP: lưu kết quả, TESTED
  TA->>CP: request-activation
  CP->>CP: kiểm kiểm tra đạt 24 giờ, chứng thư ký ACTIVE
  CP->>CP: PENDING_ACTIVATION, tạo việc cho người duyệt
  IA->>CP: approve-activation
  CP->>CP: FourEyesGuard, kiểm lại điều kiện, ACTIVE
  CP->>K: outbox EVT-14-01 và tăng config_revision
  K->>G: tín hiệu thay đổi
  G->>CP: GET runtime-config If-None-Match
  CP-->>G: ảnh chụp mới có chữ ký
  G->>G: kiểm tra, thay SnapshotHolder, nền tảng nhận lưu lượng
```

Điều kiện duyệt được kiểm hai lần, ở lúc gửi duyệt và ở lúc duyệt (bước 13 và 16), vì lần kiểm tra kết nối đạt 24 giờ hay chứng thư có thể hết hiệu lực trong lúc chờ người thứ hai. Hiệu lực tại cổng đến bằng ảnh chụp cấu hình (bước 19 đến 21), không bằng lời gọi trực tiếp, nên ≤ 30 giây theo NFR-14-026.

### 5.5. Nạp và kích hoạt chứng thư số (FR-14-028, 029)

Sơ đồ dưới mô tả việc nạp chứng thư, kiểm khớp khóa bằng hai chủ thể và kích hoạt qua người thứ hai.

```{.mermaid caption="Nạp, kiểm khớp khóa và kích hoạt chứng thư số (FR-14-028, 029)"}
sequenceDiagram
  autonumber
  actor SO as Dũng (SO)
  actor IA as Bình (IA)
  participant CP as CertificateService
  participant B as OpenBao
  participant K as Kafka
  participant W as Cổng worker
  participant G as Cổng gateway
  SO->>CP: POST certificates, tệp PEM, mục đích SIGNING, keyRef
  CP->>CP: phân tích, kiểm chuỗi, hiệu lực, KeyUsage
  CP->>B: đọc khóa công khai transit keyRef
  B-->>CP: khóa công khai
  CP->>CP: so băm SPKI với chứng thư
  CP->>K: lệnh cert.selftest
  K->>W: lệnh
  W->>B: transit/sign băm ngẫu nhiên
  B-->>W: chữ ký
  W->>W: xác minh bằng khóa công khai của chứng thư
  W->>K: kết quả đạt
  K->>CP: kết quả
  CP->>CP: lưu UPLOADED, outbox EVT-14-04
  SO->>CP: request-activation sau xác thực nhiều yếu tố
  CP->>CP: PENDING_ACTIVATION, tạo việc duyệt
  IA->>CP: approve-activation
  CP->>CP: ACTIVE, chứng thư cũ sang SUPERSEDED sau 72 giờ
  CP->>K: outbox EVT-14-04, tăng config_revision
  G->>CP: kéo ảnh chụp mới
  G->>G: CertSelector dùng chứng thư mới cho lượt ký tiếp theo
```

Khóa riêng không xuất hiện ở bước nào. Hai lớp kiểm khớp khóa dùng hai chủ thể khác nhau (bước 3 đến 5 ở `dh-integration` chỉ đọc khóa công khai, bước 7 đến 11 ở cổng mới ký thử) để giữ nguyên BR-14-004. Từ bước 20, lượt ký mới dùng chứng thư mới; chứng thư cũ ở lại ảnh chụp trong thời gian chuyển tiếp để đối chiếu bằng chứng đã ký bằng nó.

### 5.6. Gọi bất đồng bộ, ngắt mạch và kết quả chưa rõ (FR-14-016, 038)

Sơ đồ dưới mô tả vòng đời một yêu cầu bất đồng bộ, gồm ba nhánh: nền tảng ngắt mạch, quá hạn chờ với thao tác ghi, và thành công.

```{.mermaid caption="Gọi bất đồng bộ, ngắt mạch và kết quả chưa rõ (FR-14-016, 038)"}
sequenceDiagram
  autonumber
  participant H as HTTT HT-DVC
  participant G as Cổng gateway
  participant K as Kafka
  participant V as Valkey
  participant W as AsyncWorker
  participant N as NDXP
  participant R as UnknownResultReconciler
  H->>G: POST async-invocations, Idempotency-Key
  G->>G: chặng 1 đến 4, kiểm kích thước hàng chờ
  G->>V: SET NX bản ghi chống trùng IN_PROGRESS
  G->>K: phát vào asyncqueue.essential, acks all
  K-->>G: xác nhận
  G->>V: trạng thái QUEUED
  G-->>H: 202 requestId, statusUrl
  K->>W: thông điệp theo trọng số 8 3 1
  W->>V: trạng thái SENDING
  W->>N: gửi bản tin đã ký
  alt nền tảng ngắt mạch
    W->>K: chuyển sang asyncqueue.retry-1m, not-before
  else quá hạn chờ, thao tác ghi không idempotent
    N--xW: không trả lời trong timeoutMs
    W->>V: trạng thái UNKNOWN_RESULT
    W->>K: EVT-14-11 kèm UNKNOWN_RESULT
    R->>N: getDossierStatus sau 30 giây
    N-->>R: chưa có hồ sơ
    R->>V: trạng thái FAILED, cho phép gửi lại
  else thành công
    N-->>W: phản hồi
    W->>V: trạng thái SUCCEEDED
    W->>K: EVT-14-11
  end
  H->>G: GET async-invocations requestId
  G->>V: đọc trạng thái nóng
  G-->>H: 200 state
```

Kafka là nguồn sự thật của việc chấp nhận (bước 4 và 5), nên 202 nghĩa là đã bền. Nhánh quá hạn chờ của thao tác ghi không idempotent là điểm mấu chốt của BR-14-030: hệ thống không gửi lại mà hỏi trạng thái trước, và chỉ cho phép gửi lại khi trung ương xác nhận chưa nhận.

### 5.7. Chiều vào: xác minh trước, xử lý sau (FR-14-040, 041)

Sơ đồ dưới cho thấy thứ tự xác minh ở chiều vào, từ biên APISIX tới cổng rồi luồng PH-04, và nhánh từ chối ngay ở biên.

```{.mermaid caption="Chiều vào từ nền tảng quốc gia (FR-14-040, 041)"}
sequenceDiagram
  autonumber
  participant N as NDXP
  participant A as APISIX ext
  participant G as InboundGateway
  participant V as Valkey
  participant F as Luồng PH-04
  participant B as OpenBao
  participant K as Kafka
  N->>A: POST inbound endpoint dịch vụ, mTLS, bản tin ký
  A->>A: kiểm vân tay chứng thư, WAF, giới hạn tần suất
  alt nguồn không hợp lệ
    A-->>N: 401 ERR-14-120, không chạm backend
  else hợp lệ
    A->>G: chuyển tiếp, tiêu đề điểm cuối và vân tay
    G->>G: điểm cuối ACTIVE, nguồn được phép với dịch vụ
    G->>G: kiểm định dạng theo hợp đồng chiều vào
    G->>G: SignatureVerifier xác minh bản tin
    G->>V: SET NX messageId trong cửa sổ chống phát lại
    G->>F: chuyển bản tin kèm tenant, traceparent, mã giao dịch
    F-->>G: kết quả nghiệp vụ trong 10 giây
    G->>G: dựng phản hồi theo hợp đồng, kiểm lược đồ
    G->>B: băm cần ký tới transit/sign
    B-->>G: chữ ký
    G->>K: EVT-14-11 giao dịch INBOUND qua spool
    G-->>A: 200 phản hồi có chữ ký
    A-->>N: 200
  end
```

Bản tin chưa xác minh không bao giờ tới luồng PH-04 (BR-14-028): bước 5 đến 8 đứng trước bước 9. Nhánh từ chối ở biên (bước 3) không chạm backend nên giữ ngân sách ≤ 50 ms của NFR-14-016 và không tiêu tài nguyên của cổng khi bị quét.

### 5.8. Đồng bộ danh mục dịch vụ lên Bộ (FR-14-043, 046)

Sơ đồ dưới mô tả một phiên đồng bộ danh mục dịch vụ, từ lập kế hoạch ở `dh-integration` tới gửi bởi `worker` và ghi kết quả.

```{.mermaid caption="Đồng bộ danh mục dịch vụ chia sẻ lên hệ thống của Bộ (FR-14-043, 046)"}
sequenceDiagram
  autonumber
  participant S as SyncScheduler
  participant P as SyncPlanner
  participant P2 as PH-02
  participant R as Ceph RGW
  participant K as Kafka
  participant W as SyncRunner worker
  participant D as Hệ thống đăng ký của Bộ
  participant C as SyncResultConsumer
  S->>P: lịch 02:00 hoặc sự kiện PH-02 hoặc người dùng
  P->>P2: lấy dịch vụ chia sẻ PUBLISHED của tenant
  P2-->>P: danh sách
  P->>P: so băm mô tả, chọn bản ghi mới hoặc đổi
  P->>R: ghi lô runId.jsonl
  P->>K: lệnh sync.run, tham chiếu lô
  K->>W: lệnh
  W->>R: đọc lô
  loop từng bản ghi hoặc từng lô nhỏ
    W->>W: chuyển định dạng, kiểm lược đồ
    W->>D: gửi có chống trùng mã dịch vụ và phiên bản
    D-->>W: ACCEPTED, REJECTED hoặc PENDING
    W->>K: tiến độ và kết quả mỗi 100 bản ghi
  end
  K->>C: kết quả
  C->>C: cập nhật sync_run, sync_record, lần thành công gần nhất
  C->>K: outbox EVT-14-12
```

Việc gửi nằm ở `worker` vì chỉ cổng quốc gia có egress, chữ ký và thông tin xác thực; `dh-integration` chỉ lập kế hoạch và ghi kết quả. Lô lớn đi qua Ceph RGW thay vì Kafka để không vượt cỡ thông điệp. Bản ghi `PENDING` được `ReceiptPoller` hỏi lại sau, nên đối soát đủ số gửi bằng tổng ba loại kết quả.

### 5.9. Cổng tiếp hợp danh mục dùng chung cho PH-07 (FR-14-023)

Sơ đồ dưới mô tả PH-07 kéo một danh mục quốc gia qua cổng tiếp hợp, với nhánh hoãn theo hạn mức và nhánh không đổi phiên bản.

```{.mermaid caption="PH-07 kéo danh mục quốc gia qua cổng tiếp hợp NDXP_DMDC (FR-14-023)"}
sequenceDiagram
  autonumber
  participant P7 as PH-07 NdxpCatalogClient
  participant G as Cổng gateway
  participant V as Valkey
  participant N as NDXP
  P7->>G: GET national-catalogs, remoteCode, data, ifVersionNot
  G->>G: kiểm token dịch vụ, người gọi là PH-07
  G->>G: chọn kết nối NDXP_DMDC của tenant hoặc COMMON
  G->>V: script quota_try, ưu tiên BACKGROUND
  alt hạn mức từ 70 phần trăm
    V-->>G: BACKGROUND_DEFERRED
    G-->>P7: 429 ERR-14-104, resetAt
  else còn hạn mức
    V-->>G: allowed
    G->>N: lấy phiên bản danh mục
    N-->>G: remoteVersion
    alt khớp ifVersionNot
      G-->>P7: 304 không đổi
    else khác
      loop từng trang 1000 bản ghi
        G->>N: lấy trang
        N-->>G: dữ liệu
        G-->>P7: luồng trang đã xác minh
      end
    end
  end
```

Cổng không lưu dữ liệu danh mục (BR-14-036): trang được chuyển tiếp theo luồng tới PH-07. `304` giúp PH-07 bỏ qua danh mục không đổi, trả lời Q07-40 của PH-07. Ở ưu tiên `BACKGROUND`, đồng bộ danh mục nhường hạn mức cho dịch vụ công khi mức dùng từ 70% (BR-14-013).

### 5.10. Cung cấp lại dịch vụ quốc gia thành API (FR-14-009)

Sơ đồ dưới mô tả việc đóng gói dịch vụ quốc gia thành API của Datahub, với trạng thái chỉ chuyển `ACTIVE` khi PH-02 đã công bố.

```{.mermaid caption="Cung cấp lại dịch vụ quốc gia thành API của Datahub (FR-14-009)"}
sequenceDiagram
  autonumber
  actor IE as An (IE)
  participant CP as ExposureService
  participant P2 as PH-02 danh mục dịch vụ
  actor AP as Người duyệt công bố
  participant P3 as PH-03 cổng API
  participant G as Cổng gateway
  IE->>CP: PUT exposure, đường dẫn, responseFields, hạn mức mặc định
  CP->>CP: dịch vụ ACTIVE, trường thuộc đặc tả, đường dẫn không xung đột
  CP->>P2: tạo API nháp loại dịch vụ quốc gia
  P2-->>CP: apiCode, DRAFT
  CP->>CP: service_exposure PENDING_PUBLISH
  AP->>P2: duyệt công bố
  P2->>P3: sự kiện đã công bố
  P3->>P3: thêm tuyến APISIX tới cổng quốc gia
  P2->>CP: sự kiện đã công bố
  CP->>CP: service_exposure ACTIVE, outbox EVT-14-14
  CP->>CP: tăng config_revision, responseFields vào ảnh chụp
  G->>CP: kéo ảnh chụp mới
  G->>G: NormalizeStage lọc phản hồi theo danh sách trường cho phép
```

Trạng thái `ACTIVE` chỉ đặt khi nhận sự kiện đã công bố của PH-02, không đặt ngay khi gọi tạo nháp, nên PH-02 ngừng giữa chừng không để lại cung cấp lại nửa vời (ERR-14-027 ở bước 3 thì không có gì được ghi). Danh sách trường được phép đi vào ảnh chụp cấu hình ở bước 11 nên việc lọc phản hồi ở cổng có hiệu lực trước khi HTTT đầu tiên gọi.

## 6. Đa tenant trong mã nguồn

Cách ly tenant của PH-14 dựa trên ba lớp, theo D03-10: lớp dữ liệu (RLS), lớp danh tính (tenant chỉ lấy từ token hoặc điểm cuối đã đăng ký) và lớp tài nguyên dùng chung (khóa có tiền tố, ACL theo tenant). Mỗi lớp có kiểm thử rò rỉ chéo tenant chạy ở CI (SEC-87, NFR-14-024).

**Mặt phẳng điều khiển.** Mọi bảng của `ph14_national` có `tenant_id` và `FORCE ROW LEVEL SECURITY` (D03-03-PH14). `TenantContextFilter` của `dh-integration` đặt `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch từ token đã xác minh, qua `TenantAwareTransactionManager` (AR-14-07). Bộ tiêu thụ Kafka (`LedgerConsumer`, `UsageConsumer`, `AsyncStateConsumer`, `SyncResultConsumer`, `SignatureIncidentService`) lấy tenant từ tiền tố chủ đề và đối chiếu với tiêu đề thông điệp qua `TenantGuard`; lệch thì bỏ thông điệp và ghi sự kiện an ninh, không ghi CSDL (THR-29, THR-30). Các tác vụ nền (`CertificateExpiryJob`, `AnomalyDetector`, `SyncScheduler`, `ComplianceWatcher`) đi qua `TenantJobRunner` duyệt từng tenant và đặt ngữ cảnh tường minh; ArchUnit cấm `@Scheduled` gọi trực tiếp repository.

**Tenant `COMMON`.** Nền tảng và dịch vụ dùng chung toàn quốc (kết nối `NDXP_DMDC` của danh mục dùng chung, ADR-057) thuộc tenant `COMMON`. Chính sách RLS của `national_platform`, `national_service`, `service_spec` cho đọc khi `tenant_id IN (current, 'COMMON')` và chỉ cho ghi khi bằng tenant hiện tại, nên tenant tỉnh không sửa được đối tượng `COMMON` (BR-14-029); đối tượng của tenant khác trả ERR-14-001 như không tồn tại. Thông tin xác thực và chứng thư của `COMMON` chỉ đọc được bởi cổng của tenant `COMMON`. Khi tenant tỉnh không có kết nối `NDXP_DMDC` riêng, `CommonForwarder` trong cổng của tỉnh chuyển lời gọi qua mesh tới cổng của `COMMON` bằng token dịch vụ có scope `national.catalog.read`, kèm tiêu đề `X-DH-On-Behalf-Of`; cổng `COMMON` thực hiện, tính hạn mức của nền tảng `COMMON` và ghi giao dịch dưới `COMMON` với `onBehalfOf` là tỉnh gọi (truy cập liên tenant có kiểm soát, ghi vết hai phía, SEC-85). Như vậy tỉnh không bao giờ đọc được bí mật của `COMMON`; việc `COMMON` dùng một tài khoản cho cả nước hay của tỉnh đại diện là Q14-14 của FRS.

**Mặt phẳng dữ liệu.** Mỗi tenant một Deployment `national-gateway` và một `national-worker` với ServiceAccount riêng gắn vai trò xác thực Kubernetes của OpenBao theo namespace (SEC-21, SEC-80). Bảng dưới liệt kê các tài nguyên dùng chung và cách chặn ở từng nơi.

| Tài nguyên | Quy ước cách ly | Cơ chế chặn |
|---|---|---|
| OpenBao `kv` | `kv/dh/{tenant}/conn/*` | Chính sách chỉ cho SA của tenant đọc đúng tiền tố (SEC-82) |
| OpenBao `transit` | `dh-{tenant}-nat-sign-*`, `-nat-auth`, `-nat-config`, `-nat-evidence`, `dh-{tenant}-pii` | Chính sách theo vai trò: cổng được `sign` với `nat-sign`, `nat-auth`; `dh-integration` chỉ đọc khóa công khai `nat-sign` và `sign` với `nat-config`, `nat-evidence` (SEC-88) |
| Valkey | `{tenant}:nat:*` | Người dùng ACL theo tenant, mẫu khóa `~{tenant}:nat:*`; `dh-integration` chỉ `INCR` `*:nat:gen:*` |
| Kafka | `{tenant}.national.*` | ACL theo principal và tiền tố (SEC-82); cổng chỉ ghi chủ đề của mình, chỉ đọc chủ đề cấu hình và hàng chờ của mình |
| Ceph RGW | `dh-nat-payload/{tenant}/`, `dh-nat-trust/{tenant}/`, `dh-nat-sync/{tenant}/` | Chính sách IAM theo tiền tố; khóa mã hóa theo tenant |
| Chỉ số, log, vết | Nhãn `tenant` | Cách ly quan sát (SEC-84) |

: Cách ly tài nguyên dùng chung theo tenant

**Danh tính trong lượt gọi.** `IdentifyStage` đặt `tenant` từ claim đã xác minh, đối chiếu với tenant của Deployment (mỗi cổng chỉ phục vụ tenant của nó, nên token của tenant khác bị từ chối ngay cả khi hợp lệ). `systemCode` luôn lấy từ `azp`, không bao giờ từ thân yêu cầu (BR-14-007). Ngữ cảnh tenant đi theo `InvocationContext` và theo thuộc tính của Camel `Exchange`; mọi chỗ sinh khóa Valkey, tên chủ đề, đường dẫn OpenBao đều qua hàm dựng khóa bắt buộc nhận `TenantId` (không có phương án nhận chuỗi tự do), hiện thực SEC-82 và triệt THR-31 ở cấp mã.

## 7. Bảo mật

### 7.1. Biện pháp và tham chiếu SEC

PH-14 không tạo mã `SEC-*` mới. Bảng dưới nối từng rủi ro đặc thù của phân hệ với biện pháp thiết kế và mã đã có ở D03-07.

| Rủi ro | Biện pháp trong thiết kế | SEC, THR |
|---|---|---|
| Lộ thông tin xác thực NDXP | Ghi một chiều qua PH-05, cổng đọc bằng danh tính Kubernetes, token chỉ ở bộ nhớ, `SecretBytes` xóa khi thay, ArchUnit cấm log (AR-14-05), kiểm thử canary `DH-CANARY-…` (NFR-14-015) | SEC-24, SEC-32, SEC-33, THR-52 |
| Lộ hay lạm dụng khóa ký | Khóa `transit` không xuất, chỉ gửi băm, chỉ cổng của đúng tenant được `sign`, kiểm khớp khóa hai lớp, ký bằng nhà cung cấp JCA không có vật liệu khóa | SEC-34, SEC-36, SEC-88 |
| Giả mạo NDXP, người ở giữa | TLS ≥ 1.2 (ưu tiên 1.3), ghim CA, xác minh chữ ký phủ toàn bộ thân, chuỗi tin cậy và CRL, kiểm thời điểm ký theo NTP, chống phát lại | SEC-12, SEC-17, THR-53 |
| Đi ra đích không được phép (SSRF qua địa chỉ nền tảng, URL đặc tả, WSDL) | Chỉ hồ sơ `national-gateway` ra được; đích theo FQDN ở `ServiceEntry`; địa chỉ nền tảng phải thuộc kết nối PH-05 đã duyệt; lấy đặc tả từ xa chỉ tới máy chủ của nền tảng, qua `worker`; chặn dải nội bộ | SEC-16, SEC-46, THR-15 |
| Tra cứu hàng loạt, ngoài mục đích (tài khoản dùng chung) | `PurposeGuard` đóng an toàn, OPA, PH-09, ghi mục đích và mã hồ sơ mỗi lượt, `AnomalyDetector`, danh sách chặn theo HTTT | SEC-26, SEC-37, SEC-67, THR-51 |
| Không chứng minh được ai đã tra gì | Nhật ký khai thác đủ HTTT, mục đích, mã hồ sơ, `lookupKeyHash`; chuỗi băm WORM 5 năm | SEC-60, SEC-62, THR-54 |
| Giả mạo nguồn gọi vào, phát lại bản tin | mTLS với vân tay đã đăng ký, bộ lọc ở `apisix-ext`, WAF, hai lớp giới hạn tần suất, `messageId` trong cửa sổ, tenant từ điểm cuối | SEC-10, SEC-11, SEC-12, SEC-80 |
| Lộ dữ liệu cá nhân qua đệm hoặc nội dung lưu | Không đệm `SENSITIVE`, mã hóa đệm `RESTRICTED` bằng DEK tenant, nội dung lưu mã hóa tối đa 180 ngày, xem đầy đủ cần quyền, xác thực lại, lý do và ghi vết trước | SEC-31, SEC-32, SEC-39 |
| Rò chéo tenant | RLS `FORCE`, khóa có tiền tố bắt buộc ở cấp mã, ACL Valkey và Kafka, Deployment riêng mỗi tenant | SEC-80, SEC-81, SEC-82, SEC-87 |
| XXE, bom XML, đặc tả độc hại | `SecureXml`, giới hạn độ sâu và kích thước, quét mã độc trước khi phân tích | SEC-45 |
| Lạm dụng quyền quản trị, một người nắm cả khóa lẫn quyết định | Bốn mắt cho tám loại thay đổi, xác thực nhiều yếu tố, SO không có quyền sửa dịch vụ hay luật, IE và IA loại trừ nhau | SEC-23, SEC-27, SEC-28 |
| Ảnh chụp cấu hình bị sửa ở đĩa hay trên đường | Ký tách rời bằng khóa `transit`, mTLS trong mesh, tệp đĩa quyền 0600 trên hệ tệp gốc chỉ đọc | SEC-15, SEC-36 |
| Quá tải chiều vào hoặc hàng xóm ồn ào | Hai lớp giới hạn tần suất, `Bulkhead` riêng cho chiều vào, hạn mức theo tenant | SEC-10, SEC-86, THR-07 |
| Sự cố an ninh không tới được SOC | EVT-14-06 và EVT-14-16 sang PH-13 rồi SIEM, `SECURITY_HOLD`, playbook | SEC-63, SEC-64, SEC-72, SEC-74 |
| Ảnh runtime bị thay | Ký ảnh và quét lỗ hổng ở CI, hồ sơ `national-gateway` không có driver CSDL | SEC-55, SEC-56, SEC-57 |

: Bảo mật của PH-14

### 7.2. Kiểm tra quyền ở máy chủ

Giao diện ẩn nút chỉ là tiện ích, không là lớp bảo vệ. Quyền kiểm ở ba tầng: `@PreAuthorize` ở `national.web`, kiểm trạng thái và bốn mắt trong aggregate, và OPA ở những quyết định theo ngữ cảnh (mục đích, khung giờ).

| Quyền (tiền tố `PERM-14-`) | Điểm kiểm | Ràng buộc thêm ở máy chủ |
|---|---|---|
| `read` | Mọi `GET` của `national.web` | Chỉ trả cấu hình của tenant; chứng thư không bao giờ trả khóa; tham số ★ che giá trị khi không có `admin` |
| `admin` | Tạo, sửa nền tảng; xoay thông tin xác thực; điểm cuối chiều vào; `PUT /settings` | Tham số ★ qua `FourEyesGuard` |
| `service` | Dịch vụ, đặc tả, cung cấp lại, đối chiếu, nhập hệ cũ | Hướng giảm kiểm soát qua `FourEyesGuard` |
| `route` | Tạo, sửa luật định tuyến | Luật chỉ có hiệu lực sau `approve` |
| `approve` | Mọi `:approve`, `:approve-activation` | Người duyệt ≠ người đề nghị và ≠ người sửa gần nhất (ERR-14-007); IE và IA loại trừ ở D02-08 |
| `cert` | Nạp, yêu cầu kích hoạt, thu hồi chứng thư; làm mới chuỗi tin cậy | Xác thực nhiều yếu tố (SEC-23); chỉ SO và PA |
| `quota` | Khai báo hạn mức, phân bổ | PROD qua `FourEyesGuard`; chỉ TA |
| `operate` | Tạm ngừng, tiếp tục, kiểm tra tay, ép ngắt mạch, vô hiệu đệm, xoay, sự cố chữ ký | Lý do bắt buộc với ép ngắt mạch và giải trừ giữ an ninh |
| `sync` | Phiên đồng bộ, công bố dữ liệu mở | Lần công bố đầu của tập qua `FourEyesGuard` |
| `audit-read` | Giao dịch, nhật ký khai thác, báo cáo, cảnh báo | Chỉ siêu dữ liệu đã che |
| `audit-reveal` | `POST …:reveal` | Chỉ SO; xác thực lại, lý do, ghi vết trước khi đọc |
| `invoke` | Không gán cho người; scope `national.invoke.{group}` của client máy kiểm ở `IdentifyStage` | OPA kiểm thêm mục đích; đăng ký sử dụng còn hiệu lực |

: Quyền và điểm kiểm ở máy chủ

Các scope máy khác: `national.runtime-config` (chỉ cổng của đúng tenant đọc ảnh chụp), `national.health-read` (PH-13), `national.catalog.read` và `national.catalog.propose` (chỉ PH-07, BR-14-036), `national.sync.trigger` (PH-02, PH-06). Kiểm toán các thao tác quản trị đi qua `AuditWriter` của thư viện chung (SEC-60) với tác nhân, đối tượng, giá trị trước và sau (tham số ★ chỉ ghi băm), lý do; không có đường sửa đối tượng nào không để lại bản ghi.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Mười hai máy trạng thái của phân hệ, chia ba bảng. Bốn máy (nền tảng, dịch vụ, chứng thư, giao dịch chiều ra) có sơ đồ ở FRS §4.3 đến §4.6; các bảng dưới ghi điều kiện và nơi kiểm ở máy chủ. Mỗi aggregate ở `dh-integration` có cột `version` (khóa lạc quan khớp `If-Match`); lệnh của hệ thống (hết hạn, sự cố) thử lại tối đa 3 lần khi xung đột.

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| Nền tảng | `DRAFT` | Kiểm tra kết nối đạt | `TESTED` | Kết quả `PASSED` của `worker`, khớp phiên bản kết nối PH-05 |
| Nền tảng | `TESTED` | `request-activation` | `PENDING_ACTIVATION` | Đạt 24 giờ; có chứng thư ký đúng mục đích nếu có dịch vụ cần ký (ERR-14-008, 037) |
| Nền tảng | `PENDING_ACTIVATION` | `approve-activation` hoặc từ chối | `ACTIVE` hoặc `TESTED` | Bốn mắt; kiểm lại điều kiện trong cùng giao dịch |
| Nền tảng | `ACTIVE` | `suspend` | `SUSPENDED` | Lý do; hiệu lực tại cổng ≤ 30 giây |
| Nền tảng | `SUSPENDED` | `resume` | `ACTIVE` | Kết nối PH-05 còn hợp lệ |
| Nền tảng | `ACTIVE`, `SUSPENDED` | `retire` | `RETIRED` | Không còn dịch vụ `ACTIVE`; không đảo ngược, mã không dùng lại |
| Dịch vụ | `DRAFT` | `activate` | `ACTIVE` | Đặc tả `ACTIVE` và nền tảng `ACTIVE` (ERR-14-009) |
| Dịch vụ | `ACTIVE` | Nhãn `SPEC_CHANGED` không tương thích hoặc quyết định ngừng khuyến nghị | `DEPRECATED` | `DEPRECATED` vẫn phục vụ nhưng chặn đăng ký mới |
| Dịch vụ | `DEPRECATED` | Kích hoạt đặc tả mới tương thích | `ACTIVE` | Đặc tả `ACTIVE` mới |
| Dịch vụ | `ACTIVE`, `DEPRECATED` | Nhãn `DISCONTINUED` được áp | `RETIRED` | Xác nhận riêng; chặn gọi mới (ERR-14-117) |
| Đặc tả | `DRAFT` | `activate` | `ACTIVE` | Không phá vỡ, hoặc phá vỡ đã duyệt và tăng số chính (ERR-14-012) |
| Đặc tả | `ACTIVE` | Đặc tả mới `ACTIVE` | `SUPERSEDED` | Bất biến sau khi `ACTIVE` |
| Cung cấp lại | `DRAFT` | Gửi PH-02 | `PENDING_PUBLISH` | Điều kiện FR-14-009 |
| Cung cấp lại | `PENDING_PUBLISH` | Sự kiện đã công bố của PH-02 | `ACTIVE` | Chỉ nhận từ PH-02 |
| Cung cấp lại | `ACTIVE` | Gỡ | `DEPRECATED` | API chuyển `DEPRECATED` ở PH-02 |

: Bảng chuyển trạng thái của nền tảng, dịch vụ, đặc tả, cung cấp lại

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| Chứng thư | (mới) | Nạp | `UPLOADED` | Định dạng, chuỗi, hiệu lực, khớp khóa hai lớp |
| Chứng thư | `UPLOADED` | `request-activation` | `PENDING_ACTIVATION` | Xác thực nhiều yếu tố; chỉ người có `cert` |
| Chứng thư | `PENDING_ACTIVATION` | Duyệt hoặc từ chối | `ACTIVE` hoặc `UPLOADED` | Bốn mắt |
| Chứng thư | `ACTIVE` | (job) còn ≤ 60 ngày | `EXPIRING` | `CertificateExpiryJob` |
| Chứng thư | `ACTIVE`, `EXPIRING` | Chứng thư mới cùng mục đích `ACTIVE` | `SUPERSEDED` | Sau `14.cert.overlap-hours` |
| Chứng thư | `EXPIRING` | (job) quá `notAfter` | `EXPIRED` | Chặn ký nếu không còn chứng thư thay |
| Chứng thư | `ACTIVE`, `EXPIRING` | `revoke` | `REVOKED` | Lý do và xác nhận |
| Sự cố chữ ký | `OPEN` | `acknowledge` | `ACKNOWLEDGED` | Chỉ SO |
| Sự cố chữ ký | `ACKNOWLEDGED` | `resolve` | `RESOLVED` | Có kết luận (ERR-14-003) |
| Giữ an ninh | bật | Giải trừ | tắt | Không còn sự cố `OPEN` (ERR-14-004) |
| Xoay thông tin xác thực | `IDLE` | Bắt đầu | `AWAITING_PENDING_VALUE` | Nền tảng `ACTIVE` hoặc `TESTED` |
| Xoay thông tin xác thực | `AWAITING_PENDING_VALUE` | Giá trị chờ đặt | `TESTING` | PH-05 có phiên bản chờ (ERR-14-034) |
| Xoay thông tin xác thực | `TESTING` | Đạt rồi xác nhận chuyển | `OVERLAP` | Token thử đạt (ERR-14-114 nếu không) |
| Xoay thông tin xác thực | `OVERLAP` | Hết cửa sổ | `AWAITING_REVOCATION` | `14.secret.overlap-hours` |
| Xoay thông tin xác thực | `AWAITING_REVOCATION` | Nhập `revocationReceipt` | `DONE` | Hủy phiên bản cũ ở PH-05 |

: Bảng chuyển trạng thái của chứng thư, sự cố chữ ký, giữ an ninh và xoay thông tin xác thực

| Đối tượng | Từ | Sự kiện | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| Giao dịch chiều ra | `RECEIVED` | Không qua mục đích hoặc tham số | `REJECTED` | Chặng 3, 4 |
| Giao dịch chiều ra | `RECEIVED` | Trúng đệm | `COMPLETED_CACHE` | Chặng 5 |
| Giao dịch chiều ra | `RECEIVED` | Hết hạn mức | `QUOTA_EXCEEDED` | Chặng 6 |
| Giao dịch chiều ra | `RECEIVED` | Đã ký, đã gửi | `SENT` | Sau khi bản tin rời egress |
| Giao dịch chiều ra | `SENT` | Phản hồi hợp lệ | `SUCCEEDED` | Chặng 7, 8 đạt |
| Giao dịch chiều ra | `SENT` | Lỗi nghiệp vụ hoặc mạng | `FAILED` | `ErrorClassifier` |
| Giao dịch chiều ra | `SENT` | Quá hạn chờ | `TIMEOUT` | Thao tác đọc: trạng thái cuối; thao tác ghi: chuyển tiếp |
| Giao dịch chiều ra | `SENT` | Chữ ký phản hồi sai | `SIGNATURE_FAILED` | Luôn mở sự cố chữ ký |
| Giao dịch chiều ra | `TIMEOUT` | Thao tác ghi, kết quả chưa rõ | `UNKNOWN_RESULT` | Không gửi lại tự động |
| Giao dịch chiều ra | `UNKNOWN_RESULT` | Đối soát | `SUCCEEDED` hoặc `FAILED` | `UnknownResultReconciler` |
| Yêu cầu bất đồng bộ | (mới) | Chấp nhận | `QUEUED` | Kafka đã xác nhận |
| Yêu cầu bất đồng bộ | `QUEUED` | Lấy việc | `SENDING` | Chưa quá hạn, chưa hủy |
| Yêu cầu bất đồng bộ | `QUEUED` | Hủy hoặc quá `14.queue.max-age-hours` | `CANCELLED` hoặc `FAILED` | Hủy chỉ khi `QUEUED` (ERR-14-130) |
| Yêu cầu bất đồng bộ | `SENDING` | Xong | `SUCCEEDED`, `FAILED` hoặc `UNKNOWN_RESULT` | Như giao dịch chiều ra |
| Ngắt mạch | `CLOSED` | Đủ `min-calls` và vượt tỷ lệ lỗi | `OPEN` | Cửa sổ 60 giây |
| Ngắt mạch | `OPEN` | Hết `14.breaker.open-seconds` | `HALF_OPEN` | 3 lượt thăm dò toàn cụm |
| Ngắt mạch | `HALF_OPEN` | Thăm dò đạt hoặc không | `CLOSED` hoặc `OPEN` | Cờ ép (`FORCE_*`) thắng trạng thái tự động |
| Phiên đồng bộ | `PLANNED` | Worker nhận lệnh | `RUNNING` | Chưa có phiên cùng loại đang chạy (ERR-14-026) |
| Phiên đồng bộ | `RUNNING` | Xong | `COMPLETED`, `COMPLETED_WITH_ERRORS` hoặc `FAILED` | Đối soát gửi = nhận + từ chối + chờ |
| Phiên đồng bộ | `FAILED`, `COMPLETED_WITH_ERRORS` | Thử lại | `RUNNING` | Chỉ bản ghi lỗi; tối đa `14.sync.max-retries` |

: Bảng chuyển trạng thái của giao dịch, yêu cầu bất đồng bộ, ngắt mạch và phiên đồng bộ

Chuyển trạng thái của giao dịch chiều ra chỉ đi tiến; bản ghi cuối cùng trên Kafka thắng, `LedgerConsumer` bỏ qua bản ghi có hạng thấp hơn bản đã lưu của cùng `transactionCode`, với hạng tăng dần `RECEIVED` < `SENT` < `TIMEOUT` < `UNKNOWN_RESULT` < các trạng thái cuối; nhờ vậy bản ghi đến trễ hay bị Kafka giao lại không kéo giao dịch lùi.

### 8.2. Nhất quán, sự kiện và hộp gửi

PH-14 không dùng giao dịch phân tán. Mỗi thao tác chạm nhiều hệ được chia thành "ghi ý định trong giao dịch cục bộ, phát lệnh hoặc sự kiện qua cơ chế bền, nhận kết quả lũy đẳng", với thời hạn chờ và trạng thái `TIMED_OUT` rõ ràng.

**Mặt phẳng điều khiển.** Bảng `ph14_national.outbox` được ghi cùng giao dịch với thay đổi miền; Debezium của `pg-core` hoặc bộ quét 500 ms (cùng cơ chế PH-04, PH-05) đẩy lên Kafka, khóa phân vùng là mã đối tượng (`platformCode`, `serviceCode`, `certCode`) để giữ thứ tự theo đối tượng. Lệnh cho `worker` (`probe`, `cert.selftest`, `token.test`, `sync.run`, `spec.fetch`, `catalog.fetch`) cũng đi qua outbox để ý định không mất, mang `commandId`; kết quả đến trên `{tenant}.national.worker.result.v1` được xử lý lũy đẳng theo `commandId`, lệnh không có kết quả sau thời hạn (15 giây cộng tổng thời hạn các bước) chuyển `TIMED_OUT` và giao diện hiện "Chưa có kết quả". Cung cấp lại (mục 5.10) lưu `service_exposure` kèm `requestId` trước khi gọi PH-02 và dùng chính `requestId` làm khóa chống trùng của lời gọi, nên thử lại không tạo hai API nháp; việc gọi PH-02 lỗi để lại `FAILED_CREATE` chứ không để bản nháp mồ côi.

**Mặt phẳng dữ liệu.** Mọi sự kiện phát từ cổng đi qua `LedgerSpool` (4.16), ít nhất một lần, với khóa phân vùng ổn định; bên tiêu thụ ghi lũy đẳng theo khóa tự nhiên (`transactionCode`, `requestId`, `commandId`). Bảng sau cho biết sự kiện nào phát từ đâu.

| EVT-14 | Chủ đề | Phát từ | Qua |
|---|---|---|---|
| 01, 02, 03, 04, 05, 08, 09, 13, 14 | Theo FRS §9.3 | `dh-integration` | Outbox |
| 06, 12, 16 | Theo FRS §9.3 | `dh-integration` (nhận kết quả từ cổng rồi phát) | Outbox |
| 07, 10, 11, 17 | Theo FRS §9.3 | Cổng `gateway` | `LedgerSpool` và Kafka |
| 15 | Theo FRS §9.3 | Cổng `worker` | `LedgerSpool` và Kafka |

: Nguồn phát của các sự kiện EVT-14

Bên tiêu thụ cổng (cấu hình) xử lý lũy đẳng theo phiên bản: bỏ sự kiện có `configVersion` nhỏ hơn trạng thái đang giữ. Các chủ đề nội bộ không là EVT công bố gồm `{tenant}.national.worker.command.v1`, `{tenant}.national.worker.result.v1`, `{tenant}.national.quota.usage.v1`, `signature.failed`, `async.state`, `asyncqueue.*` và `trust.crl` (cùng tiền tố `{tenant}.national.`); lược đồ của chúng ở Apicurio, chế độ BACKWARD.

**Chống trùng và phát lại, tóm tắt.** Thao tác ghi ra quốc gia dùng `IdempotencyStore` 24 giờ ở Valkey (4.4); API quản trị của `dh-integration` dùng `Idempotency-Key` chung của FR-00; chiều vào dùng `messageId` trong cửa sổ 10 phút; bộ tiêu thụ dùng khóa tự nhiên với `ON CONFLICT`; cấu hình dùng số phiên bản chỉ tăng.

### 8.3. Thời gian chờ, thử lại, ngắt mạch

Bảng dưới cố định thời gian chờ, số lần thử lại và cách suy giảm của từng lời gọi để kỹ sư cấu hình client đúng ngay từ đầu và kiểm thử viên biết giá trị cần kiểm.

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch hoặc suy giảm |
|---|---|---|---|
| Cổng tới dịch vụ quốc gia | `timeoutMs` của dịch vụ (mặc định `14.timeout.default-ms` = 15 giây) | Theo `RetryPolicy` (4.12), chỉ `READ` và `WRITE` idempotent | `PlatformBreaker`, đệm quá hạn, hàng chờ |
| Cổng tới điểm cấp token | 5 giây | Một lần khi lỗi mạng; không thử lại lỗi xác thực trong 5 phút | `AuthBackoff` |
| Cổng tới OpenBao `transit/sign` | 1 giây | Một lần trong ngân sách NFR-14-002 | 5 lỗi trong 10 giây mở 5 giây, ERR-14-112 |
| Cổng tới OPA | 200 ms | Không | Đóng an toàn, ERR-14-132 |
| Cổng tới PH-09 | 200 ms | Không | Đóng an toàn, ERR-14-132; kết quả cho phép đệm 60 giây |
| Cổng tới PH-07 (`CatalogLookupApi`) | 500 ms | Một lần | Dùng bản đệm tới 24 giờ |
| Cổng tới Valkey | 20 ms lệnh, 50 ms script | Không | Bỏ qua đệm, đếm hạn mức cục bộ, bỏ chống phát lại ngoài bản sao |
| Cổng tới luồng PH-04 (chiều vào) | `14.inbound.timeout-ms` = 10 giây | Không (nền tảng gọi vào tự quyết gửi lại) | ERR-14-124 |
| Cổng tới Kafka (phát) | 5 giây mỗi lô | Tới khi spool đầy | Spool đĩa, ERR-14-127 khi đầy |
| Kéo ảnh chụp cấu hình | 5 giây | Mỗi 15 giây, không dừng | Giữ bản cũ |
| `dh-integration` tới PH-02 | 5 giây | 2 lần, 200 ms và 400 ms | ERR-14-027 |
| `dh-integration` tới OpenBao (đọc khóa công khai, ký ảnh chụp) | 2 giây | 2 lần | 50% trên 10 lượt mở, nửa mở 30 giây, ERR-14-035 |
| Lệnh tới `worker` | 15 giây cộng tổng bước | Không | `TIMED_OUT` |
| Bên tiêu thụ ghi PostgreSQL | 5 giây mỗi lô | Lùi theo hàm mũ tới 60 giây, không bỏ lô | Kafka giữ thông điệp (7 ngày) |

: Thời gian chờ, thử lại, ngắt mạch

Kamelet `dh-national-invoke` của PH-04 không tự thử lại lời gọi tới cổng, để tránh nhân số lượt thử với `RetryPolicy` và hạn mức; chính sách thử lại của luồng áp ở chặng `deliver` của PH-04 trên cơ sở mã lỗi trả về.

### 8.4. Phân loại lỗi runtime

`NationalErrorMapper` đổi mọi ngoại lệ thành ERR-14-1xx, mã HTTP và lớp lỗi. Cột "Vào ngắt mạch" cho biết lỗi có được tính vào cửa sổ lỗi của `PlatformBreaker` hay không; "Thử lại" là thử lại tự động ở cổng.

| ERR-14 | HTTP | Lớp | Vào ngắt mạch | Thử lại | Hành động thêm |
|---|---|---|---|---|---|
| 101 | 502 | Tạm thời | Có | Có (đọc, ghi idempotent) | Chỉ số `national_errors_total` |
| 102 | 404, 422 | Nghiệp vụ | Không | Không | Che nội dung kỹ thuật |
| 103 | 503 | Dẫn xuất | Không | Không | Thử đệm quá hạn trước |
| 104 | 429 | Hạn mức | Không | Không (chờ `resetAt`) | Kèm `cache.available` |
| 105 | 422 | Cấu hình | Không | Không | Cảnh báo thiếu luật |
| 106, 107 | 403, 422 | Ủy quyền | Không | Không | Giao dịch `REJECTED`, tính vào bất thường |
| 108 | 422 | Dữ liệu | Không | Không | Kèm danh sách trường, cờ `partial` khi vượt trang |
| 109, 110, 111 | 502 | An ninh | Không | Không | Sự cố chữ ký, đếm vào `SECURITY_HOLD` |
| 112 | 503 | Phụ thuộc | Không (tính ngắt mạch OpenBao) | Hàng chờ giữ lại | Cảnh báo OpenBao |
| 113 | 503 | An ninh | Không | Không | Cảnh báo mức cao nhất cho SO, EVT-14-04 |
| 114 | 502 | Xác thực | Không | Không quá một lần trong 5 phút | `AuthBackoff`, nền tảng `DEGRADED` |
| 115 | 504 | Tạm thời | Có | Có (đọc, ghi idempotent) | Ghi: `UNKNOWN_RESULT` nếu không idempotent |
| 116 | 409 | Chống trùng | Không | Không | — |
| 117 | 503 | Trạng thái | Không | Không | Từ chối trong 30 giây sau lệnh |
| 118 | 503 | Hàng chờ | Không | Không | Cảnh báo hàng chờ đầy |
| 119, 120 | 403, 401 | Chiều vào | Không | Không | Cảnh báo SO |
| 121, 122, 123 | 400, 409, 429 | Chiều vào | Không | Không | Đếm `national_inbound_rejected_total` |
| 124 | 502 | Phụ thuộc | Không | Không | Cảnh báo TO ở UI-14-10 |
| 125, 126 | 422, 403 | Đồng bộ | Không | Không | Không gửi lô |
| 127 | 500 | Nội bộ | Không | Không | Log kèm `traceId`; spool đầy hay Valkey mất với thao tác ghi |
| 128 | 502 | Dữ liệu | Có | Không | `national_invalid_response_total` |
| 129, 130 | 404, 409 | Hàng chờ | Không | Không | — |
| 131 | 502 | Phụ thuộc | Không | Có | Dùng đặc tả đã lưu, cảnh báo IE |
| 132 | 503 | Ủy quyền | Không | Không | Từ chối an toàn, cảnh báo OPA hay PH-09 |

: Phân loại lỗi runtime

### 8.5. Suy giảm khi phụ thuộc sự cố

Bảng dưới cụ thể hóa FRS §12.1 thành hành vi của mã, và nêu thẳng mức bảo đảm bị giảm. Nguyên tắc: thiếu kiểm soát an ninh thì từ chối, thiếu tối ưu hóa thì bỏ tối ưu hóa, không có chiều ngược lại.

| Phụ thuộc ngừng | Hành vi của PH-14 | Bảo đảm bị giảm | Phát hiện |
|---|---|---|---|
| OpenBao | Không ký, không gửi (ERR-14-112); token đang giữ dùng tới hết hạn; không nạp chứng thư mới, không xem nội dung đầy đủ (ERR-14-035); đệm `RESTRICTED` đã có DEK trong bộ nhớ vẫn đọc được tới 1 giờ | Không gọi ra được dịch vụ yêu cầu ký; 0 bản tin mất vì hàng chờ giữ | Ngắt mạch OpenBao, cảnh báo ≤ 30 giây (NFR-14-010) |
| NDXP, NDOP, hệ thống đăng ký | Ngắt mạch, đệm quá hạn có cờ, hàng chờ bất đồng bộ, đồng bộ thử lại 24 giờ | Dữ liệu có thể cũ tới `14.cache.stale-max-seconds` | `national_connectivity_status`, ≤ 3 phút (NFR-14-007) |
| OPA hoặc PH-09 | Từ chối lượt (ERR-14-132); lượt trúng kết quả PH-09 đã đệm 60 giây vẫn đi | Không có; chọn khả dụng thấp hơn an toàn | `national_purpose_decisions_total{reason="UNAVAILABLE"}` |
| `dh-integration` hoặc `pg-core` | Cổng chạy tiếp bằng ảnh chụp cấu hình đã nạp (đĩa); giao dịch, hạn mức, sự kiện chờ ở Kafka và `LedgerSpool`; bộ tiêu thụ ghi bù khi trở lại | Không đổi cấu hình, không duyệt, không tra cứu giao dịch trong lúc ngừng; cấu hình có thể cũ | `national_config_age_seconds`, `national_ledger_lag_seconds` |
| Valkey | Bỏ đệm; đếm hạn mức cục bộ chia đều theo số bản sao; chống phát lại chỉ trong bản sao; gộp lượt trùng chỉ cục bộ; thao tác ghi bị chặn (ERR-14-127, Q14-27); `SECURITY_HOLD` đếm cục bộ | Hạn mức xấp xỉ, nguy cơ phát lại giữa các bản sao, ghi tạm dừng | `national_quota_degraded`, cảnh báo ngay |
| Kafka | Cổng ghi `LedgerSpool` rồi phát lại; hàng chờ bất đồng bộ không nhận mới (ERR-14-118); cấu hình đã nạp vẫn chạy, thăm dò 15 giây | Trễ nhật ký khai thác và sự cố chữ ký; spool đầy thì cổng ngừng nhận lượt gọi ra | `national_ledger_spool_bytes` |
| PH-05 | Không khai báo nền tảng mới (ERR-14-005); cổng dùng tệp kê khai kết nối đã nạp | Không xoay thông tin xác thực trong lúc ngừng | Chỉ số PH-05 |
| PH-04 | Chiều ra không ảnh hưởng; chiều vào ERR-14-124 | Không nhận được chiều vào | `national_inbound_requests_total{result="flow_error"}` |
| APISIX | HTTT và nền tảng quốc gia không gọi tới được | Chiều vào và đường HTTT ngừng | Cảnh báo PH-13 |
| PH-02 | Không cung cấp lại, đồng bộ danh mục dịch vụ thử lại theo lịch (ERR-14-027) | Chậm đăng ký dịch vụ | `national_sync_lag_days` |
| PH-07 | Kiểm tra mã thủ tục dùng bản đệm tới 24 giờ; lô dữ liệu chủ không gửi (ERR-14-125) | Danh mục thủ tục có thể cũ | Log cảnh báo |
| Ceph RGW (nội dung mã hóa) | Không lưu nội dung (`payloadRef` rỗng), đường gọi vẫn chạy; không xem nội dung đầy đủ | Mất khả năng đối soát bằng nội dung với lượt đó, vẫn còn băm | `national_payload_dropped_total` |
| NTP | Cảnh báo lệch giờ (SEC-17); từ chối bản tin có thời điểm ngoài khoảng, nghi phát lại | Có thể từ chối nhầm khi đồng hồ nút lệch | `node_timex_offset_seconds` |
| PH-13, PH-18 | Đệm telemetry cục bộ, tham số dùng bản đệm 60 giây rồi mặc định | Cảnh báo ở PH-13 trễ; UI-14-01 vẫn hiện | — |

: Suy giảm khi phụ thuộc sự cố

## 9. Cấu hình và cờ tính năng theo tenant

Tham số `14.*` theo FRS §8.2 (46 khóa; khóa ★ cần duyệt bốn mắt), đọc qua `ParameterApi` của PH-18 có bộ đệm 60 giây ở `dh-integration` và đi vào ảnh chụp cấu hình cho cổng (hiệu lực ≤ 30 giây). Bảng dưới nhóm theo thành phần dùng để người đọc biết đổi tham số nào thì ảnh hưởng chỗ nào của mã; giá trị mặc định và miền ở FRS §8.2.

| Nhóm | Khóa | Thành phần dùng |
|---|---|---|
| Thời hạn, thử lại | `14.timeout.default-ms`, `14.retry.max-attempts` | `DispatchStage`, `RetryPolicy` |
| Ngắt mạch | `14.breaker.min-calls`, `.failure-ratio`, `.open-seconds` | `PlatformBreaker` |
| Xác thực, bí mật | `14.token.refresh-before-seconds`, `14.secret.max-age-days`, `14.secret.overlap-hours` | `TokenManager`, `CredentialRotationService` |
| Đệm | `14.cache.max-ttl-seconds` ★, `14.cache.stale-max-seconds` | `ResponseCache`, `StaleServer`, `ServiceCatalogService` |
| Hạn mức | `14.quota.warn-levels`, `.background-defer-ratio`, `.essential-only-ratio`, `.window-mode` | `QuotaGate`, `PriorityGate` |
| Chứng thư, tin cậy | `14.cert.warn-days`, `.overlap-hours`, `14.trust.refresh-hours`, `14.crl.max-age-days`, `14.crl.fail-mode` ★, `14.sign.max-skew-seconds` ★, `14.signature.hold-threshold` ★ | `CertificateExpiryJob`, `CrlRefresher`, `SignatureVerifier`, `HoldFlag` |
| Mục đích, nội dung | `14.purpose.allowed-hours`, `14.txn.payload-retention-days` ★, `14.reveal.max-per-day` | `PurposeGuard`, `PayloadVault`, `RevealService` |
| Hàng chờ | `14.queue.max-size`, `14.queue.max-age-hours` | `AsyncAcceptor`, `AsyncWorker` |
| Chiều vào | `14.inbound.rate-limit-per-second`, `.timeout-ms`, `.replay-window-seconds` | `InboundGateway` |
| Bộ điều hợp | `14.adapter.max-pages`, `.max-response-mb`, `14.bhxh.max-members` | `Paginator`, `BhxhAdapter` |
| Đồng bộ | `14.sync.catalog-cron`, `.stale-alert-days`, `.rate-per-minute`, `.max-retries` | `SyncScheduler`, `SyncRunner`, `ComplianceWatcher` |
| Sức khỏe, bất thường, song song | `14.health.*`, `14.test.max-per-hour`, `14.anomaly.*`, `14.parallel.*` | `PlatformProbe`, `AnomalyDetector`, `ParallelRunService` |

: Nhóm tham số theo thành phần dùng

Thiết kế cần thêm năm tham số mà FRS chưa có, đề nghị bổ sung vào FRS §8.2 (xem "Đề nghị đồng bộ"). Mặc định và miền dưới đây là giả định thiết kế, cơ sở nêu ở cột cuối.

| Khóa | Mặc định | Miền | Cơ sở |
|---|---|---|---|
| `14.dispatch.max-in-flight` | 256 | 8…2.048 | 500 lượt/giây chia 3 bản sao, thời hạn trung bình dưới 1,5 giây cho lượt thật (NFR-14-006) |
| `14.spool.max-mb` | 512 | 128…4.096 | GĐ-14-03: 9 lượt/giây cao điểm, 1,5 KiB mỗi bản ghi, đủ hơn 10 giờ |
| `14.config.poll-seconds` | 15 | 5…60 | Bảo đảm NFR-14-026 (≤ 30 giây) khi Kafka chậm |
| `14.inbound.max-body-mb` | 5 | 1…20 | Hồ sơ có đính kèm nhỏ; vượt thì ERR-14-121 |
| `14.cache.max-entry-kb` | 512 | 64…2.048 | Mục đệm lớn hơn bị bỏ, bảo vệ bộ nhớ Valkey |

: Tham số bổ sung do thiết kế đề nghị

Cờ tính năng dùng OpenFeature, cùng nhà cung cấp với PH-04. Cờ tắt thì chức năng không đăng ký tuyến, không chạy lịch, giao diện ẩn mục tương ứng.

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `national.inbound.notifications.enabled` | `false` | Bật tiếp nhận thông báo thay đổi từ quốc gia (FR-14-042, Đợt 2) |
| `national.anomaly.enabled` | `false` | Bật bộ phát hiện bất thường (FR-14-053, Đợt 2); bật khi có đủ 7 ngày dữ liệu |
| `national.evidence-export.enabled` | `false` | Bật xuất bằng chứng giao dịch (FR-14-051, Đợt 2) |
| `national.masterdata-bridge.enabled` | `false` | Bật cầu nối dữ liệu chủ (FR-14-044, Đợt 3, cần PH-06) |
| `national.opendata.enabled` | `false` | Bật công bố dữ liệu mở lên NDOP (FR-14-045, Đợt 3) |
| `national.quota-report.enabled` | `false` | Bật báo cáo hạn mức và hiệu quả đệm (FR-14-057, Đợt 3) |
| `national.parallel-run.enabled` | `true` | Bật chạy song song với hệ cũ trong giai đoạn thay dần (FR-14-055, 056) |
| `national.cache.stale.enabled` | `true` | Cho phép phục vụ đệm quá hạn; tắt để ép lỗi thay vì dữ liệu cũ |
| `national.common-forwarder.enabled` | `true` | Cho cổng của tỉnh chuyển lời gọi danh mục dùng chung tới cổng `COMMON` |

: Cờ tính năng theo tenant

Cấu hình hạ tầng không theo tenant (Helm values, không qua PH-18) gồm vai trò, môi trường, đường dẫn spool và nơi lưu ảnh chụp:

```yaml
dh:
  national:
    role: gateway               # gateway hoặc worker
    environment: PROD           # chọn ảnh chụp cấu hình theo (tenant, môi trường)
    snapshot-path: /var/lib/dh/national/snapshot.json
    spool-path: /var/lib/dh/national/spool
    openbao:
      auth: kubernetes
      sign-timeout-ms: 1000
    valkey:
      command-timeout-ms: 20
      script-timeout-ms: 50
    kafka:
      producer:
        acks: all
        enable-idempotence: true
        linger-ms: 5
```

## 10. Quan sát

Chỉ số dùng tiền tố `national_`, nhãn luôn có `tenant`. Nhãn có số giá trị lớn (`service`, `system`) giới hạn theo cấu hình của tenant (tối đa 300 dịch vụ, GĐ-14-08); không bao giờ dùng mã giao dịch, mã hồ sơ hay định danh đối tượng làm nhãn.

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `national_invocations_total` | counter | `service`, `result` | `FinalizeStage` |
| `national_stage_duration_seconds` | histogram | `stage` | `StageMarker` |
| `national_cache_requests_total`, `national_cache_hit_ratio` | counter, gauge | `service`, `outcome` | `ResponseCache` |
| `national_quota_used_ratio`, `national_quota_denied_total`, `national_quota_degraded` | gauge, counter, gauge | `platform`, `service`, `period`, `reason` | `QuotaGate` |
| `national_sign_total`, `national_sign_duration_seconds` | counter, histogram | `platform`, `mode`, `result` | `TransitSigner` |
| `national_verify_total`, `national_verify_failed_total` | counter | `platform`, `mode`, `result`, `kind` | `SignatureVerifier` |
| `national_token_errors_total`, `national_token_refresh_seconds`, `national_secret_fallback_total`, `national_secret_age_days` | counter, histogram, counter, gauge | `platform`, `reason` | `TokenManager` |
| `national_breaker_state`, `national_retry_total`, `national_outbound_in_flight` | gauge, counter, gauge | `platform`, `group`, `service`, `outcome` | `BreakerRegistry` |
| `national_fallback_total`, `national_purpose_decisions_total` | counter | `service`, `decision`, `reason` | `FederationRouter`, `PurposeGuard` |
| `national_async_queue_depth`, `national_async_oldest_age_seconds`, `national_unknown_result_open` | gauge | `priority` | `AsyncWorker` |
| `national_inbound_requests_total`, `national_inbound_rejected_total`, `national_inbound_duration_seconds` | counter, histogram | `endpoint`, `service`, `result`, `reason` | `InboundGateway` |
| `national_connectivity_status`, `national_probe_duration_seconds`, `national_outage_seconds_total` | gauge, histogram, counter | `platform`, `step` | `PlatformProbe` |
| `national_cert_days_remaining`, `national_signature_incidents_open`, `national_security_hold`, `national_incident_alert_latency_seconds` | gauge, histogram | `cert`, `platform` | `dh-integration` |
| `national_config_version`, `national_config_age_seconds`, `national_config_load_errors_total` | gauge, counter | — | `ConfigSyncer` |
| `national_ledger_spool_bytes`, `national_ledger_lag_seconds`, `national_payload_dropped_total` | gauge, histogram, counter | — | `LedgerSpool`, `LedgerConsumer` |
| `national_sync_runs_total`, `national_sync_last_success_timestamp`, `national_sync_lag_days`, `national_sync_records_total` | counter, gauge | `kind`, `state`, `outcome` | `SyncRunner` |
| `national_anomaly_alerts_open`, `national_anomaly_alerts_total`, `national_parallel_match_ratio`, `national_invalid_response_total` | gauge, counter | `rule`, `service` | `AnomalyDetector`, `ParallelRunService`, `RestTranslator` |

: Chỉ số quan sát của PH-14

Các cảnh báo gắn với mục tiêu phi chức năng được dựng sẵn trong bộ luật của PH-13 để kiểm đạt NFR-14-018 và NFR-14-007.

| Cảnh báo | Điều kiện | Mức | Căn cứ |
|---|---|---|---|
| Sự cố chữ ký | `national_signature_incidents_open` tăng, độ trễ ≤ 1 phút | Cao | NFR-14-018 |
| Hạn mức | `national_quota_used_ratio` ≥ 0,70, 0,85, 0,95 | Thông tin, cảnh báo, nghiêm trọng | NFR-14-018, BR-14-013 |
| Chứng thư | `national_cert_days_remaining` ≤ 60, 30, 7 | Thông tin, cảnh báo, nghiêm trọng | FR-14-029 |
| Nền tảng mất kết nối | `national_connectivity_status` = `UNHEALTHY` quá 5 phút | Cao | NFR-14-007 |
| Đếm hạn mức suy giảm | `national_quota_degraded` = 1 quá 2 phút | Cảnh báo | FR-14-033 |
| Cấu hình cũ | `national_config_age_seconds` > 86.400 | Cảnh báo | NFR-14-026 |
| Spool gần đầy | `national_ledger_spool_bytes` > 70% của `14.spool.max-mb` | Cao | KPI-07 |
| Trễ sổ giao dịch | `national_ledger_lag_seconds` p99 > 60 | Cảnh báo | NFR-14-020 |
| Đồng bộ danh mục | `national_sync_lag_days` > `14.sync.stale-alert-days` | Cảnh báo tuân thủ | BR-14-026 |
| Kết quả ghi chưa rõ | `national_unknown_result_open` > 0 quá 1 giờ | Cảnh báo | BR-14-030 |
| Egress bị chặn | Hubble ghi lượt ra ngoài danh sách từ pod PH-14 | Cao, ≤ 5 phút | NFR-14-014 |

: Cảnh báo của PH-14

**Vết.** Span gốc `national.invoke` (nối `traceparent` từ APISIX hoặc luồng PH-04) với span con theo chặng `national.stage` (thuộc tính `dh.stage`), `national.sign` (`dh.cert`, không băm), `national.outbound` (`net.peer.name`, `http.status_code`), `national.cache`. `transactionCode` là thuộc tính của span gốc, nên từ một mã giao dịch ở UI-14-12 dò được toàn bộ vết sang PH-13 (NFR-14-020). Không ghi thân bản tin, tham số tra cứu, token, chữ ký hay `Authorization` vào thuộc tính span.

**Log.** JSON có `tenant`, `traceId`, `transactionCode`, `service`, `stage`, `errorCode`; không có thân bản tin, định danh đối tượng hay bí mật (che theo `@Classified` và mẫu, SEC-32). Log an ninh (sự cố chữ ký, từ chối chiều vào, nguồn không được phép, `SECURITY_HOLD`) đi riêng về SIEM và giữ 12 tháng (SEC-61).

## 11. Hiệu năng và vận hành

### 11.1. Định cỡ và ngân sách độ trễ

Định cỡ theo hồ sơ "tỉnh vừa" (GĐ-07 của D02-02, GĐ-14-03 của FRS): khoảng 150.000 lượt gọi quốc gia mỗi ngày, 9 lượt/giây ở cao điểm; chỉ tiêu thông lượng của NFR-14-006 (≥ 300 lượt/giây mỗi tenant, ≥ 500 lượt/giây toàn cụm) là dư địa chứ không là tải thường. Số liệu dưới đây là giả định thiết kế, cơ sở ghi ở cột cuối, và sẽ đối chiếu ở kiểm thử tải.

| Thành phần | Định cỡ mỗi tenant (`QM-VUA`) | Cơ sở |
|---|---|---|
| `national-gateway`, vai trò `gateway` | 3 bản sao trải ≥ 2 nút, 0,5 vCPU yêu cầu và 1 vCPU giới hạn, 768 MiB (heap 384 MiB), KEDA mở rộng tới 12 theo CPU và độ trễ p95 | NFR-14-012; JVM kèm Santuario, CXF |
| `national-gateway`, vai trò `worker` | 2 bản sao, 0,25 vCPU yêu cầu và 0,5 vCPU giới hạn, 512 MiB | Kiểm tra mỗi 60 giây cho ≤ 10 nền tảng, đồng bộ nền |
| `dh-integration` module `national` | Thêm khoảng 0,3 vCPU và 256 MiB vào DU hiện có | Tải quản trị nhẹ, bộ tiêu thụ lô |
| Valkey | Khoảng 128 MiB cho khóa `{tenant}:nat:*` | 20.000 mục đệm hoạt động × 4 KiB, cộng bộ đếm, khóa chống trùng |
| Kafka | Chủ đề hàng chờ 6 phân vùng, 3 bản sao, giữ 96 giờ; chủ đề còn lại 3 phân vùng, giữ 7 ngày | NFR-14-011 |
| Ceph RGW `dh-nat-payload` | Khoảng 27 GB ở 30 ngày, tối đa khoảng 162 GB ở 180 ngày | 150.000 giao dịch × khoảng 6 KiB mã hóa mỗi ngày |
| `pg-core` `ph14_national` | Khoảng 40 GB mỗi năm (gồm chỉ mục), 12 tháng trực tuyến | 150.000 giao dịch × khoảng 0,7 KiB mỗi dòng, cộng 50% chỉ mục |

: Định cỡ giả định của PH-14

Chi phí xử lý thêm của PH-14 (NFR-14-001: p99 ≤ 80 ms, không tính thời gian chờ quốc gia, ở 500 lượt/giây, 3 bản sao, đã gồm mục đích, hạn mức, ký) được chia thành ngân sách theo chặng. Tổng các p99 là cận trên bảo thủ vì p99 của tổng nhỏ hơn tổng các p99.

| Chặng hoặc bước | Ngân sách p99 (ms) | Ghi chú |
|---|---|---|
| `identify` | 2 | Xác minh JWT bằng JWKS đã đệm, không gọi mạng |
| `resolve` | 2 | Tra chỉ mục trong bộ nhớ, một lệnh Valkey cho bản ghi chống trùng khi ghi |
| `purpose` | 9 | OPA sidecar cục bộ; kết quả PH-09 cho phép đã đệm 60 giây |
| `validate` | 3 | JSON Schema đã biên dịch và đệm theo phiên bản hợp đồng |
| `cache` | 4 | Một vòng đi về Valkey |
| `dispatch` ngoài mạng (định tuyến, token, dựng bản tin) | 7 | Hạn mức là một vòng đi về Valkey (5 ms) tính riêng ở dòng dưới |
| Hạn mức (script) | 5 | Một vòng đi về, `EVALSHA` |
| Ký số | 30 | Mục tiêu điển hình; ngưỡng cứng 50 ms theo NFR-14-002 |
| `verify` | 10 | Mục tiêu điển hình; ngưỡng cứng 30 ms theo NFR-14-003 |
| `normalize` | 4 | Lọc trường, chuyển JSON |
| `finalize` | 4 | Ghi spool, đệm Valkey không chờ |
| **Tổng** | **80** | Khớp NFR-14-001 |

: Ngân sách độ trễ theo chặng

Đo ở hai mức: JMH cho từng chặng với bộ giả lập nhanh, và Gatling cho đường đầy đủ với WireMock giả lập NDXP trả ngay, 30 phút ở 500 lượt/giây (NFR-14-006). Trúng đệm (NFR-14-004, p99 ≤ 15 ms) chỉ đi qua `identify`, `resolve`, `purpose`, `cache`, `finalize`, nên có dư địa so với tổng của các chặng này (khoảng 21 ms nếu cộng p99, thực tế thấp hơn nhờ kết quả mục đích đã đệm); nếu đo không đạt, bước tối ưu đầu tiên là đệm quyết định OPA theo (HTTT, dịch vụ, mục đích) 5 giây.

Các biện pháp giữ ngân sách: JWKS và chỉ mục cấu hình ở bộ nhớ; `EVALSHA` và một vòng đi về cho mỗi quyết định hạn mức; kết nối HTTP/2 giữ sống tới OpenBao; luồng ảo cho lời gọi chặn; JSON Schema biên dịch một lần. Cổng chỉ báo `ready` sau bước khởi động nóng: chạy 200 lượt giả lập qua toàn bộ chặng với nền tảng giả cục bộ, để lượt thật đầu tiên sau triển khai không gánh chi phí JIT, biên dịch lược đồ và dựng nhóm kết nối.

### 11.2. Vận hành

Phần này nêu cách giữ khả dụng, triển khai, khôi phục thảm họa và các quy trình vận hành chính mà sổ tay D06-03 cần mô tả.

- **Khả dụng.** Đường gọi ra ≥ 99,9% mỗi tháng, chiều vào ≥ 99,95% (NFR-14-008): bản sao trải ba vùng lỗi, `PodDisruptionBudget` `minAvailable: 2`, dừng êm 30 giây để lượt đang chạy kết thúc, spool và offset Kafka được xả trước khi thoát. Tầng phục hồi `TPH-0` như `dh-runtime`; khi `dh-integration` ngừng, cổng chạy tiếp (mục 8.5).
- **Triển khai.** Ảnh ký bằng cosign và triển khai bằng Argo CD cùng chu trình với `dh-runtime` (SEC-55, SEC-56); khi nâng phiên bản, `maxUnavailable: 0` và `maxSurge: 1`, bản sao mới phải qua khởi động nóng mới nhận lưu lượng.
- **Khôi phục thảm họa.** Hai site active–standby (ADR-034): `pg-core` và Ceph WORM theo D03-09; Valkey không sao lưu vì mọi dữ liệu tái dựng được (bộ đếm từ `quota_usage`, đệm tự đầy lại, cờ `SECURITY_HOLD` từ `national_platform`); ảnh chụp cấu hình dựng lại từ PostgreSQL. Điểm cần chuẩn bị riêng: địa chỉ IP nguồn của site dự phòng có thể phải đăng ký với trung ương (Q334 của D03-09), và chứng thư mTLS cùng khóa `transit` phải có bản ở site dự phòng.
- **Sổ tay** (D06-03), các quy trình chính: (1) xử lý `SECURITY_HOLD` và sự cố chữ ký; (2) thay chứng thư trước hạn: tạo khóa `transit`, xin chứng thư, nạp, duyệt, theo dõi chuyển tiếp; (3) khi hạn mức chạm 85%: tăng thời hạn đệm, hoãn tác vụ nền, đề nghị nâng hạn mức; (4) Kafka ngừng kéo dài: theo dõi spool, thời gian còn lại, quyết định tạm ngừng nhận lượt; (5) Valkey khôi phục: kiểm `QuotaRestorer` đã nạp bộ đếm, kiểm số thế hệ đệm; (6) xoay khóa `dh-{tenant}-pii` và `nat-config`, nạp lại DEK và khóa công khai; (7) NDXP đổi địa chỉ: đề nghị đổi `ServiceEntry` qua GitOps trước khi đổi cấu hình kết nối; (8) kiểm tra mồ côi định kỳ: khóa `transit` không có chứng thư, bản nháp ở PH-02 không có cung cấp lại, đối tượng RGW quá hạn.
- **Đối soát với trung ương.** Hằng ngày `national_transaction` được so với báo cáo lượt do trung ương cung cấp (nếu có, Q14-24) để phát hiện chênh lệch đếm hạn mức; khoảng lệch dùng hiệu chỉnh `quota_allocation`.
- **Đồng bộ D03-09.** Cần thêm vào D03-09: namespace `dh-nat-{tenant}` (hoặc nhãn trong namespace runtime), hai dòng định cỡ `national-gateway` và `national-worker`, ba bucket Ceph, danh sách FQDN đích ở egress; chưa sửa ở tập này (xem "Đề nghị đồng bộ").

## 12. Kiểm thử

Kiểm thử chia theo mức; mỗi mức nêu nội dung đặc thù của PH-14 thay vì lặp lại chiến lược chung ở ADR-038.

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | `PurposeGuard` (các nhánh cho phép, từ chối, đóng an toàn), `RuleMatcher` (đặc hiệu, ưu tiên, dự phòng), `ControlReductionDetector`, `SpecDiffer` (phá vỡ và tương thích cho OpenAPI, XSD), `CacheKey` (ổn định theo JCS), `StaleServer` (năm điều kiện), `AllocationPolicy`, `FieldHashMap`, hạng trạng thái giao dịch, `TransitJcaProvider` với OpenBao dev | JUnit 5, jqwik |
| Tính chất | Dưới tải đồng thời, bộ đếm hạn mức không bao giờ vượt giới hạn và hoàn lại đúng; hoàn lại lặp không làm âm; hai lần chuẩn hóa JCS cho cùng kết quả; không có thứ tự chặng nào cho đọc đệm trước mục đích | jqwik, Testcontainers Valkey |
| Kiến trúc | AR-14-01…09, luật Modulith, cấu hình pipeline đúng thứ tự | ArchUnit, `jdeps` |
| Chữ ký | Ký bằng `transit` rồi xác minh bằng `xmlsec1` và `openssl` độc lập cho XMLDSIG, WSSE, JWS (RS256, PS256, ES256, r‖s); xác minh các bản tin bị sửa, thiếu tham chiếu thân (tấn công bọc chữ ký), SHA-1, chứng thư bị thu hồi, hết hạn, thời điểm lệch 10 phút, `messageId` lặp | JUnit, bộ vectơ riêng |
| Tích hợp | PostgreSQL 16 với RLS, Valkey, Kafka, OpenBao (database, transit), Keycloak, OPA, Ceph RGW (MinIO tương đương), WireMock giả lập NDXP (REST và SOAP, có ký, có ngắt mạch, có trễ) | Testcontainers |
| Chiều vào | Đối tác giả có mTLS đúng và sai, nguồn không đăng ký, bản tin lặp, vượt tần suất, luồng PH-04 lỗi và quá hạn | Testcontainers, APISIX thật |
| Hỗn loạn | Dừng OpenBao giữa lượt tải (không ký, không gửi, 0 bản tin mất); dừng Valkey (đếm suy giảm, không bỏ kiểm tra); dừng Kafka (spool, sau đó phát bù); `kill -9` pod khi spool còn bản ghi; dừng `dh-integration` 24 giờ | Chaos Mesh trên kind |
| Tải | 500 lượt/giây trong 30 phút, đo từng chặng; hàng chờ ≥ 100.000 bản tin trong 72 giờ giả lập nhanh | Gatling, JMH, k6 |
| Bảo mật | Canary `DH-CANARY-…` ở nhật ký, vết, phản hồi, tệp xuất, CSDL, đệm (NFR-14-015); rò rỉ chéo tenant cho mọi API đọc và chủ đề, khóa (NFR-14-024); SSRF qua địa chỉ nền tảng và URL đặc tả; XXE, bom XML; giả tiêu đề `X-DH-Tenant`; xem nội dung không đủ xác thực | D05-02-PH14, D05-04 |
| Hợp đồng | OpenAPI và AsyncAPI của API-14-*, EVT-14-*; lược đồ Avro BACKWARD | Spectral, oasdiff (CI-5), Apicurio |
| Chấp nhận | Gọi thật hoặc môi trường thử của NDXP cho mỗi nhóm đã xác nhận ở Q14-01; chạy song song với hệ cũ một dịch vụ đọc | Theo chương 14 của FRS |

: Kiểm thử

Mỗi FR mức M có ít nhất một ca dương và một ca âm ở D05-02-PH14; các ca ở bảng trên là khung thiết kế, ca cụ thể và mã `TC-14-*` do tập kiểm thử xác định.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Lộ trình chia mười bước theo phụ thuộc kỹ thuật chứ không theo nhóm FR, để mỗi bước chạy và kiểm thử được độc lập.

| Bước | Nội dung | FR chính | Phụ thuộc |
|---|---|---|---|
| 1 | Khung: module `national`, schema, `ConfigRevisionService`, `SnapshotBuilder`, hồ sơ `national-gateway` khung với `ConfigSyncer`, `LedgerSpool`, `LedgerConsumer`, chặng `identify` và `resolve` | FR-14-054 (khung), nền | Kafka, OpenBao, PH-05 loại `oauth2-client` |
| 2 | Danh mục nền tảng, dịch vụ, đặc tả; `TokenManager`; kiểm tra kết nối; bật bốn mắt | FR-14-001…008, 024, 047, 048 | Bước 1, PH-05 |
| 3 | Đường gọi: `PurposeGuard`, `ResponseCache`, `QuotaGate`, `PlatformBreaker`, bộ chuyển đổi, bộ điều hợp LLTP và BHXH trên WireMock | FR-14-010…015, 017, 019, 032…038 | Bước 2, OPA, PH-09, Valkey |
| 4 | Ký, xác minh, chứng thư, chuỗi tin cậy, sự cố chữ ký, `SECURITY_HOLD` | FR-14-026…031 | Bước 3, OpenBao `transit`; kết quả Q14-02, Q14-03 |
| 5 | Năm bộ điều hợp còn lại, cổng tiếp hợp danh mục dùng chung, cung cấp lại | FR-14-009, 018, 020…023 | Bước 3, 4; PH-02, PH-07, PH-03 |
| 6 | Hàng chờ bất đồng bộ; chiều vào | FR-14-016, 039…041 | Bước 4; PH-03 (bộ lọc vân tay), PH-04 |
| 7 | Đồng bộ danh mục dịch vụ; sổ giao dịch, đối soát, xem nội dung; nhật ký khai thác | FR-14-043, 046, 049, 050, 052 | Bước 5, 6; PH-02 |
| 8 | Chuyển đổi: nhập từ hệ cũ, chạy song song, xoay và cấp lại thông tin xác thực, cắt chuyển | FR-14-025, 055, 056 | Bước 7; PH-04 luồng cắt chuyển |
| 9 | Đợt 2: thông báo từ quốc gia, xuất bằng chứng, cảnh báo bất thường | FR-14-042, 051, 053 | Bước 6, 7 |
| 10 | Đợt 3: cầu nối dữ liệu chủ, dữ liệu mở, báo cáo hạn mức | FR-14-044, 045, 057 | PH-06, PH-09, đặc tả NDOP |

: Lộ trình hiện thực

Bước 1 đến 8 phủ 51 FR của MVP; bước 9 phủ 3 FR của Đợt 2; bước 10 phủ 3 FR của Đợt 3 (theo FRS: 51, 3, 3).

### 13.2. Rủi ro

Bảng dưới ghi các rủi ro riêng của PH-14 kèm mức và biện pháp giảm thiểu; rủi ro kiến trúc chung ở SAD §12.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Đặc tả NDXP, NDOP chưa có hoặc đổi (Q14-01…04) | Cao | SPI `NationalAdapter` cô lập; hợp đồng và đặc tả có phiên bản; WireMock theo hợp đồng; nền tảng `PROVISIONAL`; kiểm thử hợp đồng định kỳ với môi trường thử (RSK-A04 của SAD) |
| Cơ quan cấp chứng thư bắt buộc khóa nằm trong HSM hoặc thẻ (Q14-03) | Cao | `TransitJcaProvider` là điểm thay duy nhất: thêm nhà cung cấp PKCS#11 cùng giao diện `Signature`, không đổi `XmlDsigWriter`, `WsseWriter`, `JwsWriter`; kiểm khớp khóa đổi sang ký thử qua PKCS#11 (SEC-90 ở cấp độ 4) |
| Chữ ký sai hàng loạt do trung ương đổi chứng thư, làm `SECURITY_HOLD` nhầm | Trung bình | CRL ở `SOFT`; đề xuất neo mới tự động chờ duyệt (FR-14-030); ngưỡng `14.signature.hold-threshold` chỉnh theo tenant; playbook giải trừ |
| Mất đồng thời Kafka và pod trong lúc spool còn bản ghi | Trung bình | `fsync` theo lô 100 ms, `PodDisruptionBudget`, anti-affinity, cảnh báo spool 70%; đối soát cuối ngày với nhật ký của trung ương; Q14-22 hỏi về PVC cục bộ |
| Valkey mất làm tạm dừng thao tác ghi (không còn chống trùng) | Trung bình | Valkey HA có Sentinel hoặc cụm; chỉ chặn thao tác ghi, đọc vẫn chạy; Q14-27 hỏi phương án chống trùng bền |
| Khóa riêng của chứng thư mTLS khách phải vào bộ nhớ cổng (`TLS_CLIENT_AUTH`) | Thấp | Chứng thư PKI ≤ 90 ngày, namespace và ServiceAccount riêng, ưu tiên `PRIVATE_KEY_JWT` làm mặc định, kho khóa nạp lại khi đổi |
| Bộ đếm của Datahub lệch với bộ đếm của trung ương (thử lại, lượt lỗi, đồng hồ) | Trung bình | Hạn mức đặt có biên an toàn 5% so với văn bản; đối soát hằng ngày; Q14-24 |
| Tải ký lên OpenBao khi nhiều tenant dùng chung (hồ sơ `QM-CHUNG`) | Trung bình | Ký chỉ cho dịch vụ yêu cầu; OpenBao dự phòng hiệu năng; ngân sách NFR-14-002 đo ở kiểm thử tải 34 tenant |
| Địa chỉ IP nguồn hay kênh riêng của site dự phòng chưa đăng ký với trung ương (Q334) | Trung bình | Đưa vào danh mục việc chuẩn bị DR; kiểm tra chuyển site có gọi thử NDXP |
| 34 tenant × 5 pod JVM tốn bộ nhớ ở hồ sơ dùng chung (Q14-20, Q14-21) | Trung bình | Đo thực tế; thử native sau Đợt 1; cân nhắc cổng đa tenant có cách ly danh tính OpenBao theo tenant |

: Rủi ro

### 13.3. Câu hỏi mở

> **Câu hỏi mở Q14-20:** Hồ sơ `national-gateway` chạy JVM (Santuario, CXF, WSS4J) cho MVP; có chấp nhận đánh giá native ở Đợt 2 sau khi kiểm chứng `camel-quarkus-xmlsecurity` và CXF native trên bộ vectơ chữ ký ở mục 12, hay cần native ngay để giảm bộ nhớ ở hồ sơ 34 tenant? Cần kiến trúc sư của `dh-runtime` và nhóm vận hành quyết.

> **Câu hỏi mở Q14-21:** Mô hình một Deployment `gateway` và một `worker` cho mỗi tenant (5 pod mỗi tenant, khoảng 85 GiB bộ nhớ cho 34 tenant) có phù hợp hồ sơ `QM-CHUNG` không, hay cho phép một cổng đa tenant dùng chung với xác thực OpenBao theo claim `tenant` của từng lượt? Phương án sau tiết kiệm tài nguyên nhưng cần ATTT xác nhận không vi phạm SEC-88 (cách ly mật mã theo tenant) và BR-14-007.

> **Câu hỏi mở Q14-22:** `LedgerSpool` nằm trên `emptyDir` nên mất nếu pod bị xóa đúng lúc Kafka đang ngừng; có cần PVC cục bộ (StorageClass `local`) cho vai trò `gateway` để đạt KPI-07 (100% giao dịch có nhật ký) ngay cả khi mất đồng thời hai thành phần, hay chấp nhận rủi ro dư kèm đối soát với trung ương?

> **Câu hỏi mở Q14-23:** NDXP có giới hạn số lần cấp token hoặc số token đồng thời cho một client không? Thiết kế để mỗi bản sao tự giữ token (số lượt xin token bằng số bản sao); nếu bị giới hạn, cần chuyển sang dùng chung token qua Valkey (mã hóa bằng khóa tenant) và chấp nhận Valkey nắm thêm một loại bí mật ngắn hạn.

> **Câu hỏi mở Q14-24:** Trung ương đếm hạn mức theo lượt gửi (kể cả thử lại và lượt bị trả lỗi) hay theo lượt thành công, và chu kỳ theo lịch hay cửa sổ trượt (liên quan Q14-07)? Ngoài ra thiết kế cho dịch vụ `ESSENTIAL` vượt trần phân bổ của một HTTT nhưng không vượt hạn mức toàn cục; cần chủ đầu tư xác nhận quy tắc này và có báo cáo lượt của trung ương để đối soát hằng ngày.

> **Câu hỏi mở Q14-25:** FR-14-028 bước 3 viết "hệ thống ký thử qua `transit/sign`", trong khi BR-14-004 chỉ cho cổng của đúng tenant gọi `sign`. Thiết kế tách hai lớp (đọc khóa công khai ở `dh-integration`, ký thử ở `worker`); cần xác nhận chỉnh lời FR-14-028 và cho `dh-integration` quyền đọc khóa công khai của `transit/keys/dh-{tenant}-nat-sign-*`.

> **Câu hỏi mở Q14-26:** Hợp đồng nội bộ với PH-02 (tạo API nháp loại dịch vụ quốc gia, sự kiện đã công bố, danh sách dịch vụ chia sẻ), PH-07 (`CatalogLookupApi` cho danh mục mục đích khai thác và danh mục thủ tục), PH-09 (kiểm tra mục đích, kiểm lô, thời hạn 200 ms) chưa có tập API tương ứng; tập này giả định tên và thời hạn ở mục 2.3 và 8.3. Cần ba nhóm phân hệ đó xác nhận.

> **Câu hỏi mở Q14-27:** Khi Valkey không khả dụng, thao tác ghi ra quốc gia bị chặn vì mặt phẳng dữ liệu không có kho chống trùng bền (ERR-14-127 làm mã tạm). Có chấp nhận khả dụng thấp hơn này, hay chuyển chống trùng sang chủ đề Kafka nén theo khóa (đủ bền, chậm hơn) hoặc sang `dh-integration` qua PostgreSQL; và có cần mã lỗi 503 riêng ở D03-04-PH14?

## Đề nghị đồng bộ

Các việc dưới đây cần sửa ở tài liệu dùng chung hoặc tài liệu của phân hệ khác; tập này không sửa trực tiếp vì các luồng viết chạy song song. Đề nghị thực hiện trong đợt đồng bộ cuối. Việc đã nêu ở mục "Đề nghị đồng bộ" của FRS (quyền `PERM-14-*`, scope máy, REQ-14, D00-01, D00-03 phần B, ba ADR đầu) không lặp lại ở đây.

| Tài liệu | Nội dung đề nghị | Lý do |
|---|---|---|
| D00-02 (sổ ADR) | Cấp dải ADR 075…079 (khớp đề nghị của FRS) và bốn ADR: (A) ký số bản tin quốc gia bằng `transit` qua nhà cung cấp JCA không có vật liệu khóa, kiểm khớp khóa hai lớp; (B) kiểm soát mục đích ở cổng vì tài khoản NDXP dùng chung, đóng an toàn; (C) phân bổ hạn mức, ưu tiên dịch vụ thiết yếu, đệm gộp lượt trùng bằng script nguyên tử ở Valkey; (D) mặt phẳng dữ liệu không nối PostgreSQL, ghi bền qua spool đĩa và Kafka, cấu hình bằng ảnh chụp có chữ ký | Bốn quyết định kiến trúc đặc thù của PH-14 chưa có ADR |
| D03-01 §4.3 | Ghi hồ sơ `national-gateway` chạy JVM, hai vai trò `gateway` và `worker`, một Deployment mỗi tenant (Q14-20, Q14-21); thêm Valkey, bucket Ceph `dh-nat-payload`, `dh-nat-trust`, `dh-nat-sync` vào phụ thuộc | Kiến trúc triển khai PH-14 |
| D03-09 §4.2, §5.3 | Thêm namespace hoặc nhãn `dh-nat-{tenant}`, hai dòng định cỡ (gateway 3 × 0,5/1 vCPU 768 MiB, worker 2 × 0,25/0,5 vCPU 512 MiB), Valkey 128 MiB mỗi tenant, FQDN đích ở egress, việc chuẩn bị IP nguồn cho site dự phòng (Q334) | Định cỡ và triển khai |
| D03-07 | SEC-36: thêm bốn nhóm khóa `transit` (`nat-sign-*`, `nat-auth`, `nat-config`, `nat-evidence`); SEC-82: ACL Valkey, Kafka, Ceph theo tiền tố tenant cho PH-14; thêm THR cho giả mạo nguồn chiều vào, phát lại bản tin, ảnh chụp cấu hình bị sửa | Khớp mục 6 và 7 |
| D03-04-PH14 (API) | Cấp mã cho API cấu hình runtime (đề xuất API-14-091, scope `national.runtime-config`, `ETag`); định nghĩa tiêu đề `X-DH-Accept-Stale`, `X-DH-Parallel-Run`, `X-DH-On-Behalf-Of`, `X-DH-Service`, `X-DH-Operation`; mã lỗi 503 riêng cho kho chống trùng không khả dụng (Q14-27); lược đồ các chủ đề nội bộ (`worker.command`, `worker.result`, `quota.usage`, `signature.failed`, `async.state`, `asyncqueue.*`, `trust.crl`) | Hợp đồng giữa hai mặt phẳng |
| D03-03-PH14 (CSDL) | Bảng `config_revision`, `credential_rotation`, `reconcile_run`, `sync_record`, `health_sample`, `platform_outage`, `anomaly_waiver`, `parallel_run`, `parallel_sample`, `legacy_import`, `outbox`; cột `lookup_key_hash`, `last_warned_level`, `breaker_override`, `security_hold`; chỉ mục duy nhất từng phần trên `sync_run`; phân vùng tháng cho `national_transaction`; `priority` của luật theo quy ước số lớn là ưu tiên cao; hợp đồng dịch vụ có `subjectKeyPaths`, `operations[].cacheTtlSeconds`, `exposedFields` | Khớp mô hình miền mục 4.1 |
| D02-03-PH14 (FRS) | Thêm năm tham số (`14.dispatch.max-in-flight`, `14.spool.max-mb`, `14.config.poll-seconds`, `14.inbound.max-body-mb`, `14.cache.max-entry-kb`) vào §8.2; làm rõ FR-14-028 bước 3 (Q14-25); làm rõ FR-14-016 bước 2 (Kafka là nguồn chấp nhận, trạng thái là bản dẫn xuất); nêu trạng thái cung cấp lại `PENDING_PUBLISH` ở §4.2 | Thiết kế phát hiện chỗ cần cụ thể hóa |
| D04-01 | Thêm AR-14-01…09 vào danh mục luật ArchUnit; thêm `SecretBytes`, `TransitPrivateKey` vào danh sách lớp cấm log (CC-SEC) | Chốt chặn cấu trúc |
| PH-02 | API nhận bản nháp "dịch vụ quốc gia" với `Idempotency-Key`, sự kiện đã công bố mang `apiCode`, cách lấy danh sách dịch vụ chia sẻ `PUBLISHED` theo tenant | Mục 4.2, 4.15, 5.10 |
| PH-03 | Bộ lọc vân tay chứng thư mTLS ở `apisix-ext` nhận danh sách từ EVT-14-13; tuyến cung cấp lại viết lại sang API-14-075 kèm `X-DH-Service`, `X-DH-Operation` | Mục 4.14, 4.2 |
| PH-04 | Processor của Kamelet `dh-national-invoke`; luồng cắt chuyển sao yêu cầu đọc, gửi `X-DH-Parallel-Run` và băm trường tới API-14-089; ánh xạ chiều vào tới luồng; Kamelet không tự thử lại | Mục 3.3, 4.14, 4.19 |
| PH-05 | Thư viện `SecretVersionSelector`, `ConnPropertiesFunction` dùng chung với PH-14; loại `oauth2-client` có `private_key_jwt`; đảm bảo `probe-jvm` không có đường ra tới đích quốc gia | Mục 2.3, 4.7 |
| PH-07, PH-09 | PH-07: `CatalogLookupApi` cho danh mục mục đích và thủ tục; PH-09: API kiểm tra mục đích và kiểm lô, thời hạn 200 ms (Q14-26) | Mục 4.5, 4.15 |
| PH-12, PH-13, PH-18 | PH-12: bó OPA `national/*`, claim `acr` và `auth_time` cho xác thực lại; PH-13: bộ luật cảnh báo mục 10; PH-18: 46 cộng 5 tham số `14.*` kèm nhãn ★ | Mục 4.5, 4.16, 10 |
| D05-02-PH14 | Ca kiểm thử theo khung ở mục 12: chữ ký đối chứng độc lập, hỗn loạn OpenBao, Valkey, Kafka, spool, chiều vào, rò rỉ chéo tenant, canary | Tiêu chí chấp nhận chương 14 của FRS |

: Đề nghị đồng bộ cho tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu của tập SDD PH-14 theo khuôn K-SDD và chuẩn trình bày K-TRINH-BAY: vị trí trong kiến trúc, cấu trúc mã hai đơn vị triển khai, mô hình miền và 18 thành phần (khối 10 mục), 10 sơ đồ trình tự, 12 máy trạng thái, nhất quán và suy giảm, bảo mật đối chiếu SEC, cấu hình, quan sát, hiệu năng, kiểm thử, lộ trình, 10 rủi ro, 8 câu hỏi mở (Q14-20…27) và mục Đề nghị đồng bộ. Căn cứ: FRS và use case PH-14, SAD §4, ADR-057, D03-07, D03-10 |


