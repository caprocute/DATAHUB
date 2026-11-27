---
ma_tai_lieu: D03-02-PH04
ten: Thiết kế chi tiết phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-04, lập trình viên L-INT và L-RT, lập trình viên giao diện, kiểm thử viên, nhóm vận hành
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
mo_ta: Thiết kế chi tiết phần mềm phân hệ Lõi tích hợp và trình thiết kế luồng gồm kiến trúc, cấu trúc mã, đặc tả 28 thành phần, trình tự, máy trạng thái, bảo mật, quan sát, đủ để lập trình và kiểm thử.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH04 FRS; D02-04-PH04 Use case; D03-03-PH04 CSDL; D03-04-PH04 API; D03-06-PH04 Màn hình; D03-07 ATTT; D03-10 Đa tenant; ADR-060…069
---

# D03-02-PH04 · Thiết kế chi tiết phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

PH-04 là nơi kỹ sư tích hợp của tỉnh thiết kế, chạy thử, duyệt và phát hành các luồng tích hợp Apache Camel nối các hệ thống thông tin với nhau và với Nền tảng chia sẻ, điều phối dữ liệu quốc gia (NDXP). Phân hệ thay Bus (Camel agent quản lý qua JMX) và Productivity Tooling (trình kéo thả sinh XML) của hệ cũ. Tài liệu này mô tả cách phần mềm được xây để đáp ứng FRS D02-03-PH04 và mười quyết định ADR-060…069.

Bốn điểm thiết kế quyết định chất lượng của phân hệ:

1. **Một nguồn sự thật cho luồng đang chạy.** Luồng chỉ vào runtime qua kho cấu hình Git của tenant và Argo CD. Không có kênh nào khác nạp định nghĩa vào `dh-runtime` (BR-04-012). Lệnh tạm dừng, dừng khẩn đi qua kênh lệnh có ký Ed25519 và được đối soát về Git trong 5 phút (ADR-065). Nhờ vậy mọi luồng chạy ở PROD đều truy được về một phiên bản đã duyệt bốn mắt, một commit có chữ ký và một người phát hành.
2. **Trình thiết kế dùng đúng catalog của runtime.** Bảng thành phần, Inspector, trình kiểm tra hợp lệ đọc catalog sinh cho đúng phiên bản Camel Quarkus của ảnh runtime (ADR-061). Lệch bản phụ bị CI chặn. Người thiết kế không thể lưu một tham số mà runtime không hiểu.
3. **Chạy thử bằng Camel thật trong sandbox cô lập.** Lần chạy thử nạp đúng định nghĩa (theo băm) vào `dh-runtime-sandbox` cùng phiên bản Camel, thay điểm gọi ra ngoài bằng mô phỏng, ghi vết từng chặng đã che dữ liệu. Gửi duyệt đòi một lần chạy đạt trên đúng băm (BR-04-004). Điều này thay lần chạy thử giả của mã hiện tại (GAP-04-04).
4. **Khung chín chặng là thư viện, không phải quy ước.** Tiếp nhận, kiểm tra lược đồ, ủy quyền, chuyển đổi, làm giàu, định tuyến, gửi đích, ghi vết, phản hồi được hiện thực bằng Kamelet nền và processor Java có kiểm thử (ADR-062). Tenant của bản tin được đặt một lần và khóa (`TenantGuard`). Truy cập CSDL trực tiếp chỉ qua Kamelet nền chỉ đọc theo Q359 (ADR-067).

Về an toàn thông tin: định nghĩa luồng không chứa bí mật (VR-03, chỉ tham chiếu kết nối PH-05 và OpenBao); thành phần nguy hiểm (`exec`, `ssh`, kịch bản) bị cấm theo chính sách; sandbox chạy trong namespace có chính sách mạng chỉ ra WireMock và môi trường TEST; log, vết không chứa dữ liệu Hạn chế, Nhạy cảm (BR-04-013); mọi thay đổi có kiểm toán qua PH-13. Thiết kế đáp ứng nhóm quản lý thay đổi và nhật ký của TCVN 14423:2026 cấp độ 3 (D03-07).

Phạm vi: module `flow` trong đơn vị triển khai `dh-integration` (control plane), thư viện nền và bộ nạp luồng của `dh-runtime` (data plane), DU mới `dh-runtime-sandbox`, phần trình thiết kế của `dh-console`. Ngoài phạm vi: DDL chi tiết (D03-03-PH04), hợp đồng API (D03-04-PH04), màn hình (D03-06-PH04). Câu hỏi mở ở §16.

## 1. Giới thiệu

Chương này nói mục đích, phạm vi, người đọc, tài liệu căn cứ, thuật ngữ và cấu trúc của tài liệu.

### 1.1. Mục đích và phạm vi

Tài liệu là thiết kế chi tiết phần mềm (SDD) của PH-04. Tài liệu chuyển các yêu cầu đã chốt ở FRS D02-03-PH04, use case D02-04-PH04 và ADR-060…069 thành cấu trúc mã nguồn, giao diện Java và TypeScript, thuật toán, máy trạng thái, biểu đồ tuần tự, cấu hình, quan sát và kiểm thử, ở mức đủ để đội L-INT (control plane), L-RT (runtime) và L-FE (giao diện) bắt đầu viết mã mà không phải tự quyết điểm kiến trúc.

Tài liệu không lặp lại đặc tả từng FR, không viết DDL đầy đủ và không viết OpenAPI. Khi nhắc tới bảng, cột, API, sự kiện, mã lỗi, tài liệu dùng đúng tên trong FRS và D03-03-PH04, D03-04-PH04.

Phạm vi như phần tóm tắt; PH-05, PH-10, PH-02, PH-13 chỉ được mô tả ở mức giao diện PH-04 gọi tới. Mục 2.6 liệt kê 28 thành phần; mỗi thành phần có bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát) ở đầu mục thiết kế của nó.

### 1.2. Đối tượng đọc

Bảng dưới chỉ phần cần đọc cho từng nhóm; danh sách thành phần ở mục 2.6 là điểm vào nhanh cho lập trình viên.

| Người đọc | Mục nên đọc |
|---|---|
| Lập trình viên L-INT | §2, §3, §5, §6.2, §7, §8, §9, §10, §11 |
| Lập trình viên L-RT | §4, §5.3, §5.4, §8.2, §10, §12 |
| Lập trình viên L-FE | §6, §7.1, §8.4, §9 (trạng thái), D03-06-PH04 §27 |
| Kiểm thử viên | §4.4, §7, §9, §14 |
| Vận hành | §5, §10, §12, §13 |
| Kiến trúc sư thẩm định | Tóm tắt, §2, §4, §5, §11, §15, §16 |

: Người đọc và mục nên đọc

### 1.3. Tài liệu liên quan

Yêu cầu đến từ FRS và use case; dữ liệu, API, màn hình, ca kiểm thử ở tập riêng, tài liệu này chỉ dẫn chiếu tên và mã.

| Mã | Tên | Đường dẫn | Quan hệ |
|---|---|---|---|
| D00-01 | Thuật ngữ, quy ước | `../../00-chung/D00-01-thuat-ngu-quy-uoc.md` | Đặt tên, kiểu dữ liệu |
| D02-02 | SRS tổng thể | `../../02-yeu-cau/D02-02-srs.md` | NFR-00 |
| D02-08 | Ma trận phân quyền | `../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md` | PERM-04-* |
| D02-03-PH04 | FRS PH-04 | `../../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md` | FR-04, BR-04, VR, tham số |
| D02-04-PH04 | Use case PH-04 | `../../02-yeu-cau/use-case/D02-04-PH04-use-case-tich-hop.md` | UC-04 |
| D03-01 | SAD | `../D03-01-sad.md` | DU, luồng phát hành §4 |
| D03-07 | Thiết kế ATTT | `../attt/D03-07-thiet-ke-attt.md` | SEC-*, kịch bản sự cố |
| D03-09 | Hạ tầng, DR | `../ha-tang/D03-09-ha-tang-trien-khai-dr.md` | Namespace, vùng mạng, Argo CD |
| D03-10 | Đa tenant | `../D03-10-thiet-ke-da-tenant.md` | RLS, ngưỡng tách namespace |
| D03-03-PH04 | CSDL PH-04 | `../csdl/D03-03-PH04-csdl-tich-hop.md` | DDL, RLS chi tiết |
| D03-04-PH04 | API PH-04 | `../api/D03-04-PH04-api-tich-hop.md` | API-04, EVT-04, ERR-04 |
| D03-06-PH04 | Màn hình PH-04 | `../uiux/D03-06-PH04-man-hinh-tich-hop.md` | UI-04, kiến trúc giao diện §27 |
| D05-02-PH04 | Ca kiểm thử PH-04 | `../../05-kiem-thu/test-case/D05-02-PH04-test-case.md` | TS-04 |
| D03-02-PH07 | SDD PH-07 | `./D03-02-PH07-sdd-danh-muc.md` | Mẫu `TenantSession`, outbox, bảng ánh xạ cho `dh_map` |
| D03-02-PH05 | SDD PH-05 | `./D03-02-PH05-sdd-bo-dieu-hop.md` | `ConnectionDirectory`, Kamelet giao thức, tài khoản CSDL theo luồng |
| D00-04-KTB | Quy chuẩn trình bày | `../../00-chung/khuon/K-TRINH-BAY.md` | Bảng, hình, khối đặc tả |

: Tài liệu tham chiếu

### 1.4. Quyết định kiến trúc áp dụng

Mọi lựa chọn lớn dựa trên ADR đã có; bảng dưới nối ADR với mục chịu tác động.

| ADR | Quyết định | Tác động trong SDD |
|---|---|---|
| ADR-001 | Spring Boot 4 + Spring Modulith, gom phân hệ thành DU | §2, §3: module `flow` trong `dh-integration` |
| ADR-002 | Camel Quarkus native cho data plane, JVM khi cần | §4, §5.4: hồ sơ runtime |
| ADR-003 | PostgreSQL RLS cách ly tenant | §3.6, §11.3 |
| ADR-004 | Kafka, outbox + Debezium | §5.6, §10 |
| ADR-006 | Keycloak + OPA | §11 |
| ADR-009 | Argo CD GitOps | §5 |
| ADR-010 | Luồng mô tả bằng Camel YAML DSL | §4, §6.2 |
| ADR-012 | OpenBao quản lý bí mật | §4.3, §10.2 |
| ADR-013 | Tách control và data plane | §2 |
| [ADR-060](../../00-chung/adr/ADR-060-trinh-thiet-ke-tu-lam-mo-hinh-kaoto.md) | Trình thiết kế tự làm theo mô hình Kaoto, `@xyflow/react`, dagre | §6 |
| [ADR-061](../../00-chung/adr/ADR-061-catalog-khop-phien-ban-runtime.md) | Catalog khớp phiên bản runtime | §6.6 |
| [ADR-062](../../00-chung/adr/ADR-062-luong-nghiep-vu-yaml-dsl-java-cho-thu-vien-nen.md) | Luồng nghiệp vụ YAML, Java cho thư viện nền | §4 |
| [ADR-063](../../00-chung/adr/ADR-063-anh-runtime-theo-ho-so-nap-yaml-luc-chay.md) | Ảnh runtime theo hồ sơ, nạp YAML lúc chạy | §5.3, §5.4 |
| [ADR-064](../../00-chung/adr/ADR-064-sandbox-chay-thu-camel-that.md) | Sandbox chạy thử Camel thật | §8 |
| [ADR-065](../../00-chung/adr/ADR-065-dieu-khien-runtime-git-va-lenh-co-ky.md) | Điều khiển runtime: Git + lệnh có ký | §10 |
| [ADR-066](../../00-chung/adr/ADR-066-datamapper-sinh-jq.md) | Trình ánh xạ sinh JQ, `*.dhmap.json` | §6.7 |
| [ADR-067](../../00-chung/adr/ADR-067-truy-cap-csdl-truc-tiep-co-kiem-soat.md) | Truy cập CSDL trực tiếp có kiểm soát | §4.6, §7.4 |
| [ADR-068](../../00-chung/adr/ADR-068-kho-cau-hinh-git-theo-tenant.md) | Kho cấu hình Git theo tenant | §5.1, §5.2 |
| [ADR-069](../../00-chung/adr/ADR-069-may-trang-thai-phien-ban-va-bon-mat.md) | Máy trạng thái phiên bản, bốn mắt | §9 |

: ADR áp dụng và mục chịu tác động

### 1.5. Quy ước trong tài liệu

Mã Java là Java 21 (`record`, `sealed interface`, `switch` theo mẫu). Mã TypeScript là TS 5.x, React 19. Mã SQL là PostgreSQL 18. Ví dụ dùng tenant `T68`, không gian `so-tu-phap`, luồng `ho-tich-khai-sinh`, kết nối `ndxp-ho-tich`, `pg-ho-tich-ro`, người dùng giả `u.ie01` (IE), `u.ia01` (IA), `u.to01` (TO), `u.so01` (SO). Các đoạn mã là mẫu thiết kế: chữ ký công khai, tên lớp, tên bảng, thứ tự thao tác là ràng buộc; chi tiết bên trong có thể đổi miễn giữ đúng hành vi. Phiên bản thành phần: Spring Boot 4.0.x, Camel Quarkus 3.33.2 (Camel 4.18 LTS) cho runtime, catalog trình thiết kế 3.33.1 (Camel 4.18.2) theo PR #5.

### 1.6. Thuật ngữ và viết tắt

Thuật ngữ chung (DU, EIP, outbox, RLS, ETag, SSE, VR, bốn mắt) dùng theo D00-01 và FRS D02-03-PH04 §1. Bảng dưới chỉ giải thích thuật ngữ riêng của thiết kế này.

| Thuật ngữ | Giải thích |
|---|---|
| Control plane, data plane | Mặt điều khiển (`dh-integration`) và mặt dữ liệu (`dh-runtime`) |
| Luồng, route | Luồng là đơn vị quản lý của PH-04 (có mã, phiên bản, triển khai); một luồng gồm một hoặc nhiều route Camel |
| Kamelet, Kamelet nền | Khối Camel đóng gói có tham số; Kamelet nền `dh-*` là Kamelet do nền tảng viết, ký cùng ảnh runtime |
| Chặng chuẩn | Một trong chín chặng `receive`…`respond`, nhận diện bằng `id` `dh-stage-*` |
| Catalog | Mô tả máy đọc được của thành phần, EIP, Kamelet cho một phiên bản Camel Quarkus |
| Hồ sơ runtime | Biến thể ảnh `dh-runtime` với tập extension cố định (`core-native`…) |
| Sandbox | `dh-runtime-sandbox`, chạy thử bằng Camel thật, cô lập mạng |
| Băm nội dung | `contentHash`, SHA-256 của YAML chuẩn hóa và `*.jq` |
| Nhịp tim | EVT-04-12, runtime gửi mỗi 30 giây |
| Lệnh có ký | Lệnh điều khiển ký Ed25519 trên dạng chuẩn JCS (RFC 8785) |
| DLQ | Hàng đợi bản tin lỗi, topic `{tenant}.ops.dlq.v1` |

: Thuật ngữ riêng của SDD PH-04

### 1.7. Cấu trúc tài liệu

Chương 2, 3 đặt phân hệ vào kiến trúc và cấu trúc mã (mục 2.6 là danh sách thành phần); chương 4 tới 10 là thiết kế chi tiết theo khối chức năng (khung chín chặng, GitOps, trình thiết kế, kiểm tra hợp lệ, chạy thử, máy trạng thái, điều khiển runtime), mỗi khối mở bằng bảng đặc tả thành phần; chương 11 tới 14 là bảo mật, xử lý lỗi, cấu hình, quan sát, kiểm thử; chương 15, 16 là lộ trình, câu hỏi mở và đề nghị đồng bộ.

## 2. Vị trí trong kiến trúc

Chương này đặt PH-04 vào kiến trúc của SAD: đơn vị triển khai, quan hệ thành phần, phụ thuộc, đường chuyển mã hiện có, và danh sách thành phần (mục 2.6).

### 2.1. Ba đơn vị triển khai

PH-04 được hiện thực ở ba DU và một phần giao diện:

| DU | Vai trò | Công nghệ | Namespace, vùng | Bản sao |
|---|---|---|---|---|
| `dh-integration` (module `flow`) | Control plane: luồng, phiên bản, kiểm tra hợp lệ, duyệt, phát hành, lệnh điều khiển, catalog, khuôn mẫu | Spring Boot 4, Modulith | `dh-control`, Z3 | 2 (HPA tới 4) |
| `dh-runtime` | Data plane: chạy luồng đã phát hành, khung chín chặng, nhịp tim, nhận lệnh | Camel Quarkus native (hồ sơ JVM khi cần) | `dh-runtime` hoặc `dh-rt-{tenant}`, Z4 | ≥ 3 mỗi hồ sơ |
| `dh-runtime-sandbox` | Chạy thử định nghĩa chưa phát hành bằng Camel thật | Camel Quarkus JVM cùng phiên bản | `dh-sandbox` (đề xuất, Q04-20), Z4 | 2 (KEDA theo hàng đợi) |
| `dh-console` (phần `features/integration`) | Trình thiết kế, các màn UI-04 | React 19, antd v6, `@xyflow/react` | `dh-control`, Z3 (tệp tĩnh qua BFF) | theo console |

: Đơn vị triển khai của PH-04

Module `flow` chung DU `dh-integration` với `adapter` (PH-05 phần control), `event` (PH-10) và `national` (PH-14 phần control) theo SAD §4. Lý do gom: cùng miền tích hợp, cùng hồ sơ tải (ghi ít, đọc vừa), dùng chung danh sách kết nối và topic. Module có package gốc `vn.datahub.integration.flow` và sở hữu schema PostgreSQL `ph04` trên `pg-core`.

### 2.2. Sơ đồ thành phần

```{.mermaid caption="Sơ đồ thành phần PH-04 và các hệ phụ trợ"}
flowchart TB
    subgraph Console["dh-console (trình duyệt)"]
      DES[Trình thiết kế<br/>model, canvas, YAML]
      VW[Web Worker<br/>VR phía trình duyệt]
      IDB[(IndexedDB<br/>bản nháp cục bộ)]
    end
    subgraph Ctl["dh-integration / module flow"]
      API[REST controller<br/>API-04-*]
      SVC[FlowService<br/>VersionService]
      VAL[ValidationEngine<br/>VR-01…20]
      TST[TestRunService]
      REL[ReleaseService<br/>GitOps writer]
      CMD[CommandService<br/>ký Ed25519]
      REC[Reconciler<br/>heartbeat, ack]
      CAT[CatalogService<br/>policy, templates]
      OBX[(outbox ph04)]
    end
    subgraph Data["Data plane"]
      RT[dh-runtime<br/>FlowLoader, TenantGuard,<br/>Kamelet nền]
      SB[dh-runtime-sandbox]
    end
    GIT[(dh-flows-tenant<br/>env/test, env/prod)]
    ARGO[Argo CD]
    K[(Kafka)]
    PG[(pg-core ph04)]
    BAO[OpenBao]
    S3[(Ceph RGW<br/>dh-int-testrun)]
    DES -->|REST, SSE| API
    DES --- VW
    DES --- IDB
    API --> SVC --> VAL
    SVC --> PG
    TST --> SB
    SB --> S3
    REL --> GIT
    ARGO --> GIT
    ARGO --> RT
    CMD --> BAO
    CMD --> K
    K --> RT
    RT --> K
    K --> REC
    OBX --> K
    SVC --> OBX
    CAT --> PG
```

Hình cho thấy `dh-integration` không đẩy định nghĩa thẳng vào runtime mà ghi Git để Argo CD đưa xuống; runtime và control plane chỉ trao đổi qua Kafka (lệnh có ký, nhịp tim, xác nhận); sandbox ghi thân bản tin chạy thử vào Ceph RGW, không vào CSDL.

### 2.3. Phụ thuộc với module và phân hệ khác

Module `flow` gọi hai module cùng DU bằng Java API, gọi các phân hệ khác bằng REST hoặc sự kiện. Cột cuối nói hành vi khi bên kia chưa sẵn sàng, để thiết kế không có điểm hỏng âm thầm.

| Phụ thuộc | Hướng | Cơ chế | Khi không sẵn sàng |
|---|---|---|---|
| Module `adapter` (PH-05) | `flow` gọi | Java API `ConnectionDirectory` trong cùng DU: liệt kê kết nối, kiểm tra loại, có giá trị theo môi trường | Không có: bắt buộc cùng DU |
| Module `event` (PH-10) | `flow` gọi | Java API `TopicDirectory`: topic, quyền publish, subscribe của luồng (VR-10) | Cùng DU |
| PH-01 | Sự kiện vào | Bảng sao `ph04.external_system` cập nhật từ sự kiện kết nạp HTTT | Xem như nội bộ, cảnh báo (FRS §10.1) |
| PH-02 | Hai chiều | REST tới `dh-connect` lấy OpenAPI; PH-02 nghe EVT-04-07 | Không tạo được luồng từ API |
| PH-06 | `flow` gọi | REST tới `dh-data` lấy JSON Schema cho trình ánh xạ | Trình ánh xạ chỉ dùng tài liệu mẫu |
| PH-07 | Runtime gọi | Thư viện `dh_map` tải ảnh chụp bảng ánh xạ, nghe EVT-07 thay đổi | Dùng ảnh chụp gần nhất |
| PH-09 | Runtime gọi | Chính sách che theo phân loại trường | Chính sách đệm; không có thì đóng an toàn |
| PH-12 | `flow` gọi | Keycloak (người dùng, nhóm), OPA (quyết định) | Không đăng nhập được |
| PH-13 | `flow` ghi, đọc | Kiểm toán qua outbox; đọc lịch sử (API-04-091); bảng điều khiển nhúng | Kiểm toán giữ ở outbox |
| PH-15 | `flow` phát | Sự kiện EVT-04 để PH-15 gửi thông báo | Không có thông báo, luồng nghiệp vụ không ảnh hưởng |
| PH-18 | `flow` đọc, runtime ghi | Tham số `04.*`, DLQ `{tenant}.ops.dlq.v1` | Dùng tham số đệm |
| PH-20 | Sự kiện vào | Tenant mới: tạo không gian `DEFAULT`, kho `dh-flows-{tenant}`, ApplicationSet | Không áp dụng |

: Phụ thuộc của module `flow` với module và phân hệ khác

### 2.4. Luật Spring Modulith

1. Module `flow` chỉ công bố package `vn.datahub.integration.flow.api` (giao diện `FlowQueryApi`, DTO, sự kiện miền). Mọi package khác là `internal`.
2. `flow` được phép phụ thuộc `adapter.api`, `event.api`, `shared.*`. `adapter`, `event` không phụ thuộc ngược lại `flow` (tránh vòng); nếu `event` cần biết luồng nào dùng topic thì nghe sự kiện miền `FlowVersionApproved`.
3. Bài kiểm thử `ApplicationModules.of(IntegrationApplication.class).verify()` bắt buộc trong CI.
4. Sự kiện miền giữa module dùng `@ApplicationModuleListener` (giao dịch riêng, ghi bảng `event_publication` của Modulith); sự kiện ra ngoài DU luôn qua outbox `ph04.outbox`.

### 2.5. Hiện trạng mã và đường chuyển

Mã hiện có ở `apps/control/src/main/java/vn/lgsp/control/routes` (module `routes` của DU `lgsp-control`). Bảng dưới cho biết mỗi lớp hiện có đi đâu trong thiết kế đích và khoảng lệch nào (FRS §2.4) được đóng.

| Lớp hiện có | Đích | GAP đóng |
|---|---|---|
| `RoutesController` (301 dòng) | Tách thành `FlowController`, `VersionController`, `TestRunController`, `ReleaseController`, `RuntimeController` | GAP-04-13 (đổi gói `vn.datahub`) |
| `RoutesService` (754 dòng) | Tách thành `FlowService`, `VersionService`, `ReviewService`, `ReleaseService`; `testRun` mô phỏng bị bỏ | GAP-04-04, 05, 06 |
| `CamelYamlValidator` | `ValidationEngine` với từng quy tắc VR là một lớp; tìm chuỗi con được thay bằng duyệt cây | GAP-04-08 |
| `GitOpsPublisher` (ghi `routes/<mã>/route.camel.yaml` trong repo mã) | `GitConfigRepository` ghi kho `dh-flows-{tenant}` qua JGit HTTP | GAP-04-03 |
| `ExternalSystemRegistry` | `ExternalSystemProjection` đọc bảng sao `ph04.external_system` | — |
| `TestRunRetentionJob` | `TestRunRetentionJob` giữ tên, thêm xóa đối tượng trên Ceph RGW | — |
| Bảng `ph04.route`, `route_version`, `route_test_run`, `route_test_run_stage` | Bảng mới của D03-03-PH04 (`flow`, `flow_version`, `test_run`, `test_run_step`…), có `tenant_id`, RLS | GAP-04-07 |
| `setPaused` chỉ đổi cột `status` | `CommandService` + `Reconciler` | GAP-04-11 |
| Java DSL `TraCuuRoute`, `StandardPipelineRoute`, `CdmMapRoute` ở `camel/dancu`, `camel/datdai` | YAML dùng Kamelet nền (§4) | GAP-04-02, 12 |
| Datasource chung tài khoản `lgsp` ở `camel/dancu` | Kamelet `dh-sql-ro-source`, tài khoản theo luồng | GAP-04-10 |

: Lớp hiện có và đích trong thiết kế mới

Đường chuyển theo thứ tự ở §15.

### 2.6. Danh sách thành phần

Bảng dưới liệt kê 28 thành phần theo khối chức năng. Bảng đặc tả 10 mục của mỗi thành phần đứng đầu mục ghi ở cột cuối, sau nó là thiết kế chi tiết.

| TT | Thành phần | Lớp, khối chính | Mục |
|---|---|---|---|
| 1 | Không gian làm việc và luồng | `FlowService`, `WorkspaceAccess` | 3.7.1 |
| 2 | Phiên bản và lưu nháp phía máy chủ | `VersionService` | 3.7.2 |
| 3 | Duyệt bốn mắt | `ReviewService`, `FourEyesGuard` | 3.7.3 |
| 4 | Khuôn mẫu và chuyển XML hệ cũ | `TemplateService`, `LegacyXmlImporter` | 3.7.4 |
| 5 | Ngữ cảnh tenant trên bản tin | `TenantGuard`, `TenantHeaders` | 4.1 |
| 6 | Kamelet nền chín chặng và chỉ số chặng | `dh-*-action`, `StageMarker`, `StageMetrics` | 4.2 |
| 7 | Xử lý lỗi chuẩn và DLQ | `dh-default-config`, `ErrorClassifier`, `dhDlqEnvelope` | 4.3 |
| 8 | Phân giải tham chiếu bí mật | `ConnPropertiesFunction`, `VaultPropertiesFunction` | 4.3 |
| 9 | Truy cập CSDL chỉ đọc | `dh-sql-ro-*`, `TenantScopedSqlProcessor` | 4.6 |
| 10 | Ghi kho cấu hình Git | `GitConfigRepository`, `FlowManifestWriter` | 5.1 |
| 11 | Nạp luồng ở runtime | `FlowLoader` | 5.4 |
| 12 | Phát hành, nâng môi trường, quay lui | `ReleaseService`, `ProfileResolver` | 5.5 |
| 13 | Kiểm toán và outbox | `AuditWriter`, `OutboxWriter` | 5.6 |
| 14 | Mô hình tài nguyên và lệnh soạn | `ResourceTree`, `Command` | 6.1 |
| 15 | Quay vòng YAML và băm | bộ ghi `yaml`, `YamlCanonicalizer` | 6.2 |
| 16 | Bảng thành phần và bố cục sơ đồ | `palette-groups.json`, dagre worker | 6.3 |
| 17 | Lưu nháp, gộp ba bên, phiên soạn | `ThreeWayMerge`, `EditSession` | 6.5 |
| 18 | Catalog khớp runtime | `catalog-gen`, `CatalogService`, `CatalogUpgradeJob` | 6.6 |
| 19 | Trình ánh xạ dữ liệu | bộ sinh `dhmap → jq` | 6.7 |
| 20 | Bộ kiểm tra hợp lệ | `ValidationEngine`, `ValidationRule` | 7.1 |
| 21 | Phát hiện bí mật | `SecretDetector` | 7.3 |
| 22 | Chính sách SQL | `SqlPolicy` | 7.4 |
| 23 | Sandbox chạy thử | `dh-runtime-sandbox`, `StepTracer` | 8.1 |
| 24 | Điều phối chạy thử và khẳng định | `TestRunService`, `SandboxClient` | 8.2 |
| 25 | Phát lệnh có ký | `CommandService`, `CommandSigner` | 10.1 |
| 26 | Nhận lệnh và nhịp tim ở runtime | `CommandListener`, `CommandVerifier`, `HeartbeatPublisher` | 10.2 |
| 27 | Đối soát trạng thái | `Reconciler`, `HeartbeatProjector` | 10.3 |
| 28 | Tham số và đóng băng | `FlowParams`, `FreezeWindowGuard` | 13.1 |

: Danh sách thành phần thiết kế PH-04

## 3. Cấu trúc mã nguồn

Chương này cố định cách tổ chức mã để các nhóm viết song song: cây gói, lớp chính, giao diện công bố, DTO, thư viện runtime, truy cập dữ liệu. Mục 3.7 đặc tả bốn thành phần quản lý luồng.

### 3.1. Cây package của module `flow`

```text
vn.datahub.integration.flow
├── api/                         # công bố cho module khác
│   ├── FlowQueryApi.java        # tra luồng theo mã, luồng dùng topic, dùng kết nối
│   ├── FlowRef.java, FlowVersionRef.java
│   └── events/                  # sự kiện miền: FlowCreated, FlowVersionApproved, DeploymentSynced…
├── internal/
│   ├── web/                     # controller REST, ánh xạ lỗi ProblemDetail, SSE
│   ├── workspace/               # Workspace, WorkspaceMember, WorkspaceAccess
│   ├── flow/                    # Flow, FlowService, dependency graph, clone, retire
│   ├── version/                 # FlowVersion, VersionService, contributors, ETag, canonicalizer
│   ├── session/                 # EditSession (nhịp mềm, Valkey)
│   ├── validation/              # ValidationEngine, rules/VR01…VR20, SecretDetector, SqlPolicy
│   ├── testrun/                 # TestRunService, SandboxClient, TestCase, assertions
│   ├── review/                  # ReviewService, FourEyesGuard, checklist
│   ├── release/                 # ReleaseService, GitConfigRepository, FlowManifestWriter, ProfileResolver
│   ├── runtime/                 # CommandService, CommandSigner, Reconciler, HeartbeatProjector
│   ├── catalog/                 # CatalogService, ComponentPolicy, CatalogIndexLoader
│   ├── template/                # TemplateService, khuôn tpl-*
│   ├── legacy/                  # LegacyXmlImporter (camel-xml-io → YAML)
│   ├── mapping/                 # lưu, kiểm tra *.dhmap.json, sinh JQ phía máy chủ
│   ├── params/                  # FlowParams đọc 04.* từ PH-18, FreezeWindowGuard
│   ├── audit/                   # AuditWriter (outbox → PH-13)
│   └── outbox/                  # OutboxWriter, bảng ph04.outbox
└── FlowModuleConfiguration.java
```

### 3.2. Trách nhiệm các lớp chính

| Lớp | Trách nhiệm | FR |
|---|---|---|
| `FlowService` | Tạo (từ khuôn, trống, API PH-02, YAML), sửa thông tin, nhân bản, gỡ; tính `transport`, `exposure` | FR-04-001…006 |
| `VersionService` | Mở phiên bản mới, lưu nháp với `If-Match`, hủy, tải xuống, nhập YAML; thêm người đóng góp; tính băm | FR-04-010, 011, 024, 027 |
| `YamlCanonicalizer` | Chuẩn hóa YAML, bỏ chú thích bố cục, tính SHA-256 (§6.2) | BR-04-006 |
| `ValidationEngine` | Chạy VR theo mức `DESIGN`, `SUBMIT`, `PUBLISH`, trả `Finding` | FR-04-023 |
| `TestRunService` | Hàng đợi chạy thử theo hạn mức tenant, gọi sandbox, nhận vết, khẳng định, SSE | FR-04-030…033 |
| `ReviewService` | Gửi, rút, quyết định duyệt; `FourEyesGuard` | FR-04-040, 041, 043 |
| `ReleaseService` | Phát hành, nâng môi trường, quay lui; điều kiện thứ tự, đóng băng; ghi Git | FR-04-042, 044, 045 |
| `ProfileResolver` | Chọn hồ sơ runtime nhỏ nhất chứa đủ thành phần | FR-04-075 |
| `CommandService` | Tạo, ký, gửi lệnh `PAUSE`, `RESUME`, `EMERGENCY_STOP` | FR-04-050 |
| `Reconciler` | Nghe nhịp tim, xác nhận lệnh; tính `syncStatus`, `healthStatus`; đối soát Git | FR-04-051, BR-04-018 |
| `CatalogService` | Phục vụ chỉ mục, lược đồ thành phần theo `catalogVersion`; chính sách | FR-04-080, 081 |
| `LegacyXmlImporter` | Chuyển Camel XML của Bus cũ | FR-04-082 |

: Trách nhiệm các lớp chính của module `flow`

### 3.3. Giao diện công bố `FlowQueryApi`

```java
package vn.datahub.integration.flow.api;

public interface FlowQueryApi {
  Optional<FlowRef> findByCode(TenantId tenant, String flowCode);
  /** Luồng (đã phát hành ở bất kỳ môi trường) dùng topic; PH-10 dùng khi gỡ topic. */
  List<FlowVersionRef> flowsUsingTopic(TenantId tenant, String topic);
  /** Luồng dùng kết nối; PH-05 dùng khi gỡ hoặc xoay kết nối. */
  List<FlowVersionRef> flowsUsingConnection(TenantId tenant, String connectionCode);
  /** Điểm vào HTTP đang chạy; PH-02 dùng khi công bố API có backend là luồng. */
  List<FlowEndpointRef> httpEndpoints(TenantId tenant, Environment env);
}

public record FlowRef(UUID flowId, String code, String name, FlowStatus status, String workspaceCode) {}
public record FlowVersionRef(UUID flowId, String flowCode, int versionNo, Environment env) {}
public record FlowEndpointRef(String flowCode, int versionNo, String method, String path, String routeId) {}
```

Sự kiện miền công bố (trong `api.events`): `FlowCreated`, `FlowVersionSubmitted`, `FlowVersionApproved`, `DeploymentStatusChanged`, `FlowRuntimeStateChanged`, `FlowRetired`. Mỗi sự kiện miền có một bản ra ngoài tương ứng EVT-04-01…10 qua outbox.

### 3.4. DTO và record chính

```java
public record FlowCreateRequest(
    @NotNull @Pattern(regexp = "^[a-z][a-z0-9-]{2,62}$") String code,
    @NotBlank @Size(max = 255) String name,
    @Size(max = 4000) String description,
    @NotNull String workspaceCode,
    @NotNull ResourceKind resourceKind,                // ROUTE, KAMELET, PIPE, TEST
    @NotNull FlowOrigin origin,                        // BLANK, TEMPLATE, OPENAPI, YAML_FILE, CLONE, LEGACY_XML
    String templateCode, Map<String, Object> templateParams,
    String apiRef,                                     // PH-02 khi origin = OPENAPI
    @Size(max = 524_288) String yaml,                  // khi origin = YAML_FILE
    String sourceSystem, @Size(max = 20) List<String> targetSystems,
    @Size(max = 20) Map<@Size(max = 63) String, @Size(max = 63) String> labels,
    String legalBasisRef) {}

public record VersionDraftUpdate(
    @NotNull @Size(max = 524_288) String definitionYaml,
    @NotNull JsonNode canvasLayout,                    // vị trí, ghim, ghi chú dán, nhóm
    @NotNull JsonNode samples,                         // bản tin mẫu theo id chặng, mỗi bản ≤ 256 KiB
    @NotNull @Size(max = 64) String catalogVersion,
    @Size(max = 50) List<@Valid MappingDoc> mappings) {}

public record Finding(String rule, Severity severity, String path, String nodeId,
                      String messageKey, Map<String, Object> args) {}

public record TestRunRequest(
    @NotNull TestMode mode,                            // MOCK, SANDBOX_LIVE
    UUID testCaseId,
    @Size(max = 262_144) String body,
    @Size(max = 50) Map<String, String> headers,
    String fromNodeId,
    @Min(1) @Max(120) int timeoutSeconds,
    boolean captureBodies,
    @Size(max = 20) List<@Valid Assertion> assertions) {}

public sealed interface Assertion permits StatusIs, BodyJq, HeaderIs, StepVisited, StepNotVisited,
    EndpointCalled, DurationLt, ErrorCodeIs, DlqSent {}

public record ReleaseRequest(@NotNull Environment target, @Size(max = 1000) String note,
                             Integer replicas) {}

public record RuntimeCommandRequest(@NotNull Environment environment, @NotNull CommandScope scope,
    @Size(max = 100) List<String> routeIds, @NotNull CommandAction action,
    @NotBlank @Size(min = 10, max = 1000) String reason, boolean drain) {}
```

### 3.5. Thư viện nền của runtime

```text
dh-runtime/
├── dh-runtime-lib/                      # Java, phát hành theo vòng đời mã (ADR-062)
│   ├── vn.datahub.runtime.tenant        # TenantGuard, TenantHeaders, TenantMismatchException
│   ├── vn.datahub.runtime.stage         # StageMarker, StageMetrics (Micrometer, OTel span)
│   ├── vn.datahub.runtime.authz         # OpaClient (200 ms, đóng an toàn), Obligations
│   ├── vn.datahub.runtime.mask          # MaskingProcessor theo PH-09
│   ├── vn.datahub.runtime.jq            # hàm JQ dh_map, dh_now, dh_tenant
│   ├── vn.datahub.runtime.audit         # ConnectionLogWriter (EVT-04-14)
│   ├── vn.datahub.runtime.error         # ErrorClassifier, DlqEnvelope, field encryption
│   ├── vn.datahub.runtime.sql           # TenantScopedSqlProcessor (SET LOCAL app.tenant_id)
│   ├── vn.datahub.runtime.secret        # ConnPropertiesFunction {{conn:}}, VaultPropertiesFunction {{vault:}}
│   └── vn.datahub.runtime.control       # CommandListener, CommandVerifier, HeartbeatPublisher
├── dh-runtime-kamelets/                 # Kamelet nền YAML (§4.2), đóng vào mọi hồ sơ
├── dh-runtime-loader/                   # FlowLoader: theo dõi ConfigMap theo nhãn, nạp, gỡ (§5.4)
└── profiles/
    ├── core-native/pom.xml              # camel-quarkus-* + dh-runtime-lib, native
    ├── files-native/pom.xml
    ├── soap-jvm/pom.xml
    └── legacy-jvm/pom.xml
```

Mỗi hồ sơ sinh `runtime-manifest.json` lúc build (FR-04-081): `profile`, `quarkusVersion`, `camelQuarkusVersion`, `camelVersion`, `extensions[]`, `kamelets[]`, `libVersion`, `imageDigest`. `dh-integration` đọc manifest của mọi hồ sơ (ConfigMap `dh-runtime-manifests`) để chọn hồ sơ và kiểm VR-12.

### 3.6. Truy cập dữ liệu

| Cơ chế | Dùng cho | Lý do |
|---|---|---|
| Spring Data JDBC | `workspace`, `workspace_member`, `flow`, `flow_version`, `review`, `deployment`, `runtime_command`, `test_case`, `template`, `component_policy` | Aggregate nhỏ, khóa lạc quan qua cột `version` khớp `If-Match`; không cần lazy loading của JPA |
| `JdbcClient` | `flow_route_index`, `flow_endpoint_index`, `test_run`, `test_run_step`, `command_ack`, `heartbeat_latest`, truy vấn danh sách có `facets` | Ghi hàng loạt, `INSERT … ON CONFLICT`, truy vấn động |
| Valkey | Phiên soạn, khóa lũy đẳng API (24 giờ), hàng đợi chạy thử theo tenant, bộ đệm catalog đã lọc | Dữ liệu ngắn hạn |
| Ceph RGW bucket `dh-int-testrun` | Thân bản tin chạy thử khi `captureBodies` | Không làm phình CSDL; xóa theo vòng đời 7 ngày |

: Cơ chế truy cập dữ liệu theo bảng

Mọi đường ghi CSDL đi qua `TenantAwareTransactionManager` của thư viện chung (mẫu ở D03-02-PH07 §6.2), đặt `app.tenant_id` đầu mỗi giao dịch, nên RLS luôn có hiệu lực. Cột `definition_yaml` (≤ 512 KiB), `canvas_layout`, `samples` (`jsonb`) nằm ở bảng `flow_version`; truy vấn danh sách không chọn các cột này.

### 3.7. Đặc tả thành phần quản lý luồng

Bốn thành phần lõi nghiệp vụ của control plane; thuật toán chi tiết ở chương 6, 9, 12 nên mục này chỉ có bảng đặc tả. Gỡ luồng dựng đồ thị phụ thuộc từ `flow_reference` và chỉ cho gỡ khi không còn phụ thuộc cứng.

#### 3.7.1. Không gian làm việc và luồng

::: dac-ta
**Mục đích.** Quản lý không gian làm việc, thành viên và vòng đời luồng: tạo từ sáu nguồn, sửa, nhân bản, gỡ có kiểm tra phụ thuộc.

**Lớp chính.** `FlowService`, `WorkspaceService`, `WorkspaceAccess`, `DependencyGraph`, `ExternalSystemProjection`.

**Đơn vị chạy.** `dh-integration`, gói `internal.flow`, `internal.workspace`.

**FR hiện thực.** FR-04-001…007.

**Giao diện vào.** API-04-001…004, 010…016; sự kiện HTTT của PH-01, tenant mới của PH-20.

**Phụ thuộc ra.** `TemplateService`, `VersionService`, `ConnectionDirectory`, `TopicDirectory`, REST PH-02.

**Dữ liệu.** `workspace`, `workspace_member`, `flow`, `flow_reference`, `external_system`.

**Sự kiện.** EVT-04-01, 02, 09.

**Lỗi và xử lý.** ERR-04-002 (mã trùng), 003 (thiếu `EDIT`), 017 (còn phụ thuộc), 018 (khóa lũy đẳng), 027, 028 (không gian), 034 (luồng đã gỡ), 043 (HTTT chưa kết nạp).

**Quan sát.** Kiểm toán qua `AuditWriter`; `http_server_requests_seconds{uri}`.
:::


#### 3.7.2. Phiên bản và lưu nháp phía máy chủ

::: dac-ta
**Mục đích.** Giữ định nghĩa theo phiên bản: mở, lưu nháp có khóa lạc quan, hủy, tải, nhập YAML, ghi người đóng góp, tính băm.

**Lớp chính.** `VersionService`, `YamlCanonicalizer`, `ContributorRecorder`, `EtagCodec`.

**Đơn vị chạy.** `dh-integration`, gói `internal.version`.

**FR hiện thực.** FR-04-010, 011, 017, 022, 024, 027.

**Giao diện vào.** API-04-020…027.

**Phụ thuộc ra.** `ValidationEngine` mức `DESIGN`; `MappingService`; Valkey.

**Dữ liệu.** `flow_version`, `flow_version_contributor`, `flow_mapping`, `flow_route_index`, `flow_endpoint_index`.

**Sự kiện.** Không phát khi lưu nháp.

**Lỗi và xử lý.** ERR-04-005, 006 (412, kèm `currentEtag`, `savedBy`, `savedAt`), 007, 008, 016, 021, 033.

**Quan sát.** `dh_int_validation_seconds{level="DESIGN"}`.
:::


#### 3.7.3. Duyệt bốn mắt

::: dac-ta
**Mục đích.** Không phiên bản nào lên môi trường khi chưa qua người duyệt độc lập, trên đúng băm đã chạy thử đạt (§8.4, §9.1).

**Lớp chính.** `ReviewService`, `FourEyesGuard`, `ReviewChecklist`, `SubmitGate`.

**Đơn vị chạy.** `dh-integration`, gói `internal.review`.

**FR hiện thực.** FR-04-040, 041, 043.

**Giao diện vào.** API-04-025, 050…053.

**Phụ thuộc ra.** `ValidationEngine` mức `SUBMIT`; `TestRunService`; Keycloak (xác thực lại).

**Dữ liệu.** `review`, `flow_version`, `flow_version_contributor`, `test_run`, `test_case`.

**Sự kiện.** EVT-04-03, 04, 05.

**Lỗi và xử lý.** ERR-04-005, 009 (còn lỗi), 014 (chưa chạy đạt), 015 (vi phạm bốn mắt), 025 (thiếu ý kiến, checklist), 042 (catalog cũ).

**Quan sát.** Kiểm toán người duyệt, băm, checklist; thời gian chờ duyệt ở PH-13.
:::


#### 3.7.4. Khuôn mẫu và chuyển XML hệ cũ

::: dac-ta
**Mục đích.** Tạo luồng từ khuôn chuẩn (mặc định `tpl-standard-9`) và chuyển Camel XML của Bus cũ sang YAML không mang theo bí mật.

**Lớp chính.** `TemplateService`, `TemplateRenderer`, `LegacyXmlImporter`, `LegacySecretStripper`.

**Đơn vị chạy.** `dh-integration`, gói `internal.template`, `internal.legacy`; chuyển XML chạy nền.

**FR hiện thực.** FR-04-025, 082.

**Giao diện vào.** API-04-028, 080…082.

**Phụ thuộc ra.** `VersionService`, `ValidationEngine`.

**Dữ liệu.** `template`, `legacy_import_job`.

**Sự kiện.** EVT-04-01 khi tạo luồng.

**Lỗi và xử lý.** ERR-04-032 (XML không hợp lệ), 039 (khuôn không có); XML tắt DTD, thực thể ngoài; mật khẩu bị gỡ trước khi lưu, không vào log.

**Quan sát.** Số tệp đạt, lỗi theo lô trong `legacy_import_job`.
:::


## 4. Khung chín chặng chuẩn trong runtime

Chương này mô tả thư viện mọi luồng ở `dh-runtime` dựa vào, để an toàn tenant, che dữ liệu, thử lại, DLQ không phụ thuộc việc người thiết kế nhớ quy ước.

### 4.1. Hợp đồng tiêu đề nội bộ

::: dac-ta
**Mục đích.** Khóa tenant của bản tin ở chặng tiếp nhận và chặn mọi thay đổi về sau.

**Lớp chính.** `TenantGuard` (`InterceptStrategy`), `TenantHeaders`, `TenantMismatchException`.

**Đơn vị chạy.** `dh-runtime`, `dh-runtime-sandbox`; gói `vn.datahub.runtime.tenant`.

**FR hiện thực.** FR-04-073.

**Giao diện vào.** Mọi processor sau `receive`.

**Phụ thuộc ra.** Nhãn `dh.gov.vn/tenant` của ConfigMap; cảnh báo ATTT PH-13.

**Dữ liệu.** Thuộc tính exchange `dh.tenant.locked`.

**Sự kiện.** Cảnh báo ATTT mức cao.

**Lỗi và xử lý.** ERR-04-112 (500), không thử lại, không đưa thân vào DLQ.

**Quan sát.** `dh_flow_failures_total{error_code="ERR-04-112"}`.
:::

Mọi exchange trong `dh-runtime` mang bộ tiêu đề dưới đây. Tiêu đề bắt đầu bằng `dh-` do runtime đặt; tiêu đề cùng tên do bên gọi gửi vào bị `dh-receive-action` xóa trước khi đặt lại (chống giả mạo).

| Tiêu đề | Đặt ở | Nguồn | Bất biến |
|---|---|---|---|
| `dh-tenant` | `receive` | `X-Dh-Tenant` của APISIX (đồng bộ), tiền tố topic (Kafka), `flow.dh.yaml` (lập lịch) | Có, `TenantGuard` |
| `dh-caller` | `receive` | `X-Dh-Consumer` của APISIX; mã HTTT nguồn với Kafka | Có |
| `dh-subscription` | `receive` | `X-Dh-Subscription` | Có |
| `dh-flow`, `dh-flow-version` | `receive` | Nhãn ConfigMap do Argo CD áp | Có |
| `dh-stage` | Mỗi chặng | `StageMarker` | Không (đổi theo chặng) |
| `dh-data-classes` | `schema` | Ánh xạ đường dẫn trường sang mức `DataClass` (bốn mức DD-08) theo phân loại trường của lược đồ (PH-09) | Không |
| `dh-obligations` | `authz` | Kết quả OPA | Không |
| `dh-enrich-partial` | `enrich` | Khi làm giàu lỗi với `CONTINUE` | Không |
| `traceparent` | `receive` | W3C; tạo mới nếu thiếu | Không |

: Hợp đồng tiêu đề nội bộ của exchange

`TenantGuard` là `InterceptStrategy` gắn vào mọi route của luồng đã nạp: trước mỗi processor sau `receive`, nó so `dh-tenant` với giá trị chụp lúc `receive` (lưu trong thuộc tính exchange `dh.tenant.locked`, không phải tiêu đề) và so với tenant sở hữu luồng (nhãn `dh.gov.vn/tenant` của ConfigMap). Lệch thì ném `TenantMismatchException`, exchange dừng với lỗi nội bộ, phát cảnh báo ATTT (FR-04-073, E6 của UC-04-17).

```java
public final class TenantGuard implements InterceptStrategy {
  @Override
  public Processor wrapProcessorInInterceptors(CamelContext ctx, NamedNode def, Processor target, Processor next) {
    return exchange -> {
      String locked = exchange.getProperty(TenantHeaders.LOCKED, String.class);
      if (locked != null) {
        String now = exchange.getMessage().getHeader(TenantHeaders.TENANT, String.class);
        if (!locked.equals(now) || !locked.equals(owningTenant(exchange))) {
          throw new TenantMismatchException(locked, now, def.getId());
        }
      }
      target.process(exchange);
    };
  }
}
```

### 4.2. Kamelet nền

::: dac-ta
**Mục đích.** Hiện thực chín chặng chuẩn và chỉ số chặng thành khối dùng lại có kiểm thử; luồng chỉ khai tham số.

**Lớp chính.** Kamelet `dh-receive-action`…`dh-respond-action`; `OpaClient`, `MaskingProcessor`, `dh_map`, `ConnectionLogWriter`, `StageMarker`, `StageMetrics`.

**Đơn vị chạy.** `dh-runtime` mọi hồ sơ, sandbox; mô-đun `dh-runtime-kamelets`, `dh-runtime-lib`.

**FR hiện thực.** FR-04-060…069, 071, 074.

**Giao diện vào.** Bước `kamelet` trong khối `dh-stage-*`.

**Phụ thuộc ra.** APISIX, Apicurio hoặc PH-06, OPA (200 ms), PH-07, PH-09, hệ đích qua PH-05, Prometheus, OTel.

**Dữ liệu.** Bộ đệm lược đồ, ảnh chụp bảng mã; khóa chống trùng ở Valkey.

**Sự kiện.** EVT-04-14.

**Lỗi và xử lý.** ERR-04-101…108 theo chặng (§4.2).

**Quan sát.** Tám tín hiệu ở §4.5; log không có thân bản tin.
:::

Mỗi chặng chuẩn có một Kamelet nền loại `action` trong `dh-runtime-kamelets`. Kamelet nền có tham số tối thiểu; phần biến thiên của luồng nằm ở bước con mà người thiết kế thêm bên trong khối chặng.

| Chặng | Kamelet nền | Tham số | Hành vi |
|---|---|---|---|
| receive | `dh-receive-action` | `maxBodyKb` (mặc định từ `04.runtime.max-body-kb`), `idempotencyKey` (biểu thức, tùy chọn) | Xóa tiêu đề `dh-*` vào, đặt tiêu đề §4.1, khóa tenant, đo kích thước (ERR-04-107), chống trùng khi có khóa (FR-04-071) |
| schema | `dh-schema-action` | `schemaRef` (mã lược đồ Apicurio hoặc PH-06), `format` (`json`, `xml`, `avro`) | Kiểm tra, trả ≤ 20 lỗi theo đường dẫn (ERR-04-101); đặt `dh-data-classes` |
| authz | `dh-authz-action` | `operation`, `purpose` | Gọi OPA, đặt `dh-obligations`, từ chối ERR-04-102 |
| transform | `dh-transform-action` | `jq` hoặc `mappingRef`, `unknownCode` (`FAIL`, `PASS_THROUGH`, `DEFAULT:<mã>`) | Chạy JQ có `dh_map` (ERR-04-108) |
| enrich | `dh-enrich-action` | `uri` hoặc `direct`, `timeoutMs` (5000), `onError` (`FAIL`, `CONTINUE`) | `enrich` với chiến lược gộp JSON |
| route | `dh-route-action` | không | Đánh dấu chặng; nội dung là `choice`, `split`, `multicast` do người thiết kế đặt |
| deliver | `dh-deliver-action` | `connection`, `path`, `method`, `timeoutMs` | Gọi đích trong `circuitBreaker` (Resilience4j: 50% trên 20 lượt, nửa mở sau 30 giây) |
| audit | `dh-audit-action` | `serviceCode`, `providerSystem` | Ghi nhật ký kết nối lên EVT-04-14 |
| respond | `dh-respond-action` | `contentType` | Áp nghĩa vụ che của OPA và chính sách PH-09; đặt mã HTTP |

: Kamelet nền theo chặng

Kamelet nền tham chiếu processor Java bằng `#class:` không được phép trong luồng của người dùng; Kamelet nền nằm ngoài kiểm tra VR-04 vì được ký cùng ảnh runtime. Danh sách Kamelet nền và phiên bản ghi trong `runtime-manifest.json` (`kamelets[]`).

### 4.3. `routeConfiguration` nền và xử lý lỗi

::: dac-ta
**Mục đích.** Một chính sách lỗi cho mọi luồng: phân loại, thử lại lũy thừa, trả lỗi bên gọi, DLQ đã mã hóa trường nhạy cảm.

**Lớp chính.** `dh-default-config`, `ErrorClassifier`, `dhDlqEnvelope`, `dhSyncErrorResponse`, `dhRouteBusinessError`.

**Đơn vị chạy.** `dh-runtime`; gói `vn.datahub.runtime.error`.

**FR hiện thực.** FR-04-070.

**Giao diện vào.** `routeConfigurationId: dh-default-config` (VR-11).

**Phụ thuộc ra.** Kafka `{tenant}.ops.dlq.v1`; OpenBao transit (DEK tenant).

**Dữ liệu.** Tiêu đề `dh-dlq-*` trên bản tin DLQ.

**Sự kiện.** Bản tin DLQ cho PH-18.

**Lỗi và xử lý.** Tạm thời: 3 lần, 1 s, hệ số 4, rồi DLQ (ERR-04-103, 104); nghiệp vụ, dữ liệu: trả bên gọi hoặc DLQ; OPA từ chối: không DLQ; chưa phân loại: thử 1 lần, DLQ, ERR-04-109.

**Quan sát.** `dh_flow_failures_total`, `dh_flow_dlq_total`.
:::

`dh-default-config` được nạp sẵn ở mọi hồ sơ; luồng tham chiếu bằng `routeConfigurationId: dh-default-config` (khuôn mẫu đặt sẵn, VR-11 kiểm tra).

```yaml
- routeConfiguration:
    id: dh-default-config
    onException:
      - onException:
          exception: [vn.datahub.runtime.error.TransientException]
          redeliveryPolicy:
            maximumRedeliveries: 3
            redeliveryDelay: 1000
            backOffMultiplier: 4
            collisionAvoidanceFactor: 0.2
            useExponentialBackOff: true
            retryAttemptedLogLevel: WARN
          handled: { constant: true }
          steps:
            - process: { ref: dhDlqEnvelope }
            - to: { uri: "kafka:{{dh.tenant}}.ops.dlq.v1" }
            - process: { ref: dhSyncErrorResponse }
      - onException:
          exception: [vn.datahub.runtime.error.BusinessException, vn.datahub.runtime.error.DataException]
          handled: { constant: true }
          steps:
            - process: { ref: dhRouteBusinessError }   # đồng bộ: trả bên gọi; bất đồng bộ: DLQ
      - onException:
          exception: [vn.datahub.runtime.error.AuthzDeniedException]
          handled: { constant: true }
          steps:
            - process: { ref: dhSyncErrorResponse }    # không đưa DLQ
    onCompletion:
      - onCompletion:
          steps:
            - process: { ref: dhStageMetricsFlush }
```

`ErrorClassifier` ánh xạ ngoại lệ Camel và mã HTTP của đích sang bốn lớp ở FR-04-070: `TransientException` (502, 503, 504, quá thời gian, mất kết nối; 429 theo `Retry-After`), `BusinessException` (400, 404, 409, 422 từ đích), `DataException` (lược đồ, chuyển đổi), `AuthzDeniedException`. Ngoại lệ không phân loại thử lại một lần rồi DLQ và cảnh báo. `dhDlqEnvelope` mã hóa trường phân loại Hạn chế, Nhạy cảm bằng khóa DEK của tenant (OpenBao transit) trước khi đưa DLQ, thêm tiêu đề `dh-dlq-reason`, `dh-dlq-attempts`, `dh-dlq-stage`, `dh-dlq-error-code`.


::: dac-ta
**Mục đích.** Cho luồng tham chiếu tham số, bí mật của kết nối PH-05 bằng tên; định nghĩa và Git không chứa bí mật.

**Lớp chính.** `ConnPropertiesFunction`, `VaultPropertiesFunction`.

**Đơn vị chạy.** `dh-runtime`, sandbox; gói `vn.datahub.runtime.secret`.

**FR hiện thực.** FR-04-016; VR-03, VR-15.

**Giao diện vào.** `{{conn:…}}`, `{{vault:…}}`; sự kiện xoay kết nối PH-05.

**Phụ thuộc ra.** OpenBao KV `kv/dh/{tenant}/conn/`, `kv/dh/{tenant}/flow/`.

**Dữ liệu.** Chỉ trong bộ nhớ, không ghi đĩa, không log.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** Đường dẫn ngoài phạm vi hoặc OpenBao lỗi lúc khởi động: route không khởi động, giữ bản cũ, báo `loadError`.

**Quan sát.** `loadError` trong EVT-04-12.
:::

Phân giải bí mật: `ConnPropertiesFunction` đăng ký tiền tố `conn` cho properties placeholder; `{{conn:ndxp-ho-tich.host}}` đọc giá trị của kết nối PH-05 ở môi trường hiện tại từ OpenBao đường dẫn `kv/dh/{tenant}/conn/{mã}/{env}` lúc khởi động route, giữ trong bộ nhớ, làm mới khi nhận sự kiện xoay kết nối. `{{vault:<path>#<key>}}` chỉ nhận đường dẫn dưới `kv/dh/{tenant}/flow/`.

### 4.4. Luồng mẫu chín chặng

Luồng `ho-tich-khai-sinh` rút gọn dưới đây là đầu ra của khuôn `tpl-standard-9` sau khi điền tham số; cũng là ca quay vòng chuẩn của bộ kiểm thử (§14).

```yaml
- route:
    id: ho-tich-khai-sinh-main
    routeConfigurationId: dh-default-config
    from:
      uri: platform-http:/ho-tich/khai-sinh
      parameters: { httpMethodRestrict: POST }
      steps:
        - step:
            id: dh-stage-receive
            steps:
              - kamelet: { name: dh-receive-action, parameters: { idempotencyKey: "${header.Idempotency-Key}" } }
        - step:
            id: dh-stage-schema
            steps:
              - kamelet: { name: dh-schema-action, parameters: { schemaRef: ho-tich-ks, format: json } }
        - step:
            id: dh-stage-authz
            steps:
              - kamelet: { name: dh-authz-action, parameters: { operation: khai-sinh.dang-ky, purpose: dvc } }
        - step:
            id: dh-stage-transform
            steps:
              - kamelet: { name: dh-transform-action, parameters: { mappingRef: ho-tich-ks-to-ndxp } }
        - step:
            id: dh-stage-enrich
            steps:
              - enrich: { expression: { constant: "direct:lay-ma-dvhc" } }
        - step:
            id: dh-stage-route
            steps:
              - choice:
                  when:
                    - simple: "${body[request][type]} == 'KS'"
                      steps:
                        - kamelet:
                            name: dh-deliver-action
                            id: dh-stage-deliver
                            parameters: { connection: ndxp-ho-tich, path: /api/v1/khai-sinh, method: POST, timeoutMs: 15000 }
                  otherwise:
                    steps:
                      - log: { message: "Loại hồ sơ không hỗ trợ: ${body[request][type]}" }
        - step:
            id: dh-stage-audit
            steps:
              - kamelet: { name: dh-audit-action, parameters: { serviceCode: ho-tich.khai-sinh, providerSystem: ndxp } }
        - step:
            id: dh-stage-respond
            steps:
              - kamelet: { name: dh-respond-action, parameters: { contentType: application/json } }
```

Quy tắc nhận diện chặng (thay GAP-04-08): một phần tử EIP có `id` khớp `^dh-stage-(receive|schema|authz|transform|enrich|route|deliver|audit|respond)$` là đầu khối chặng. Chặng `deliver` được phép nằm lồng trong `route` (như trên) vì định tuyến chọn đích; VR-05 kiểm thứ tự theo lần duyệt cây theo chiều sâu, lấy lần xuất hiện đầu của mỗi mã.

### 4.5. Chỉ số, vết, log

Tín hiệu dưới đây do `StageMarker`, `StageMetrics` và route policy phát (thành phần 6, bảng đặc tả ở §4.2), cùng bộ tên cho mọi luồng để PH-13 dựng bảng điều khiển chung.

| Tín hiệu | Tên | Nhãn | Nguồn |
|---|---|---|---|
| Đếm | `dh_flow_exchanges_total` | `tenant`, `flow`, `version`, `route`, `outcome` | `onCompletion` |
| Đếm | `dh_flow_failures_total` | trên + `stage`, `error_class`, `error_code` | `ErrorClassifier` |
| Histogram | `dh_flow_duration_seconds` | `tenant`, `flow`, `version`, `route` | Micrometer route policy |
| Histogram | `dh_flow_stage_duration_seconds` | trên + `stage` | `StageMarker` |
| Gauge | `dh_flow_circuit_state` | `tenant`, `flow`, `target` | Resilience4j |
| Đếm | `dh_flow_dlq_total` | `tenant`, `flow`, `reason` | `dhDlqEnvelope` |
| Đếm | `dh_flow_duplicates_total` | `tenant`, `flow` | `dh-receive-action` |
| Span | `dh.stage.{mã}` | thuộc tính `dh.tenant`, `dh.flow`, `dh.flow.version` | OTel |

: Chỉ số, vết của runtime

Nhãn `tenant`, `flow` có lực lượng giới hạn (≤ 1.000 luồng hoạt động toàn nền tảng theo D03-10) nên chấp nhận được trong Prometheus. Log JSON có `traceId`, `spanId`, `tenant`, `flow`, `version`, `stage`, không có thân bản tin, không có giá trị tiêu đề ngoài danh sách cho phép (`Content-Type`, `Content-Length`, `dh-*`).

### 4.6. Truy cập CSDL trực tiếp

::: dac-ta
**Mục đích.** Đọc CSDL nghiệp vụ trực tiếp theo Q359: chỉ đọc, đúng tenant, có giới hạn và kiểm toán.

**Lớp chính.** Kamelet `dh-sql-ro-source`, `dh-sql-ro-action`; `TenantScopedSqlProcessor`.

**Đơn vị chạy.** `dh-runtime` (PostgreSQL ở native, CSDL khác ở `legacy-jvm`); gói `vn.datahub.runtime.sql`.

**FR hiện thực.** FR-04-072.

**Giao diện vào.** Bước Kamelet có câu lệnh đã qua VR-13.

**Phụ thuộc ra.** OpenBao database engine (TTL 1 giờ); CSDL nguồn qua kết nối PH-05.

**Dữ liệu.** Kiểm toán runtime: `sha256` câu lệnh, `rows`, `durationMs`.

**Sự kiện.** EVT-04-14.

**Lỗi và xử lý.** Vượt `04.sql.max-rows` hoặc quá thời gian: ERR-04-108; không gia hạn được tài khoản: lỗi tạm thời.

**Quan sát.** `dh_flow_stage_duration_seconds` của chặng chứa SQL.
:::

Kamelet `dh-sql-ro-source` (nguồn định kỳ) và `dh-sql-ro-action` (tra cứu trong luồng) bọc `camel-sql` với `TenantScopedSqlProcessor`:

1. Lấy `DataSource` của kết nối PH-05 loại "CSDL cho luồng"; tài khoản cấp động từ OpenBao database engine (`database/creds/flow-{tenant}-{flow}`), TTL 1 giờ, gia hạn trước khi hết 10 phút.
2. Mở giao dịch `READ ONLY`, `SET LOCAL statement_timeout = '{04.sql.statement-timeout-seconds}s'`.
3. Nếu kết nối khai báo `rls: true`: `SELECT set_config('app.tenant_id', :tenant, true)` với `:tenant` từ thuộc tính khóa (§4.1), không từ tiêu đề có thể sửa.
4. Chạy câu lệnh đã kiểm tra (VR-13) với tham số ràng buộc; đọc tối đa `04.sql.max-rows` + 1 dòng; vượt thì ném `DataException` ERR-04-108.
5. Ghi bản ghi kiểm toán runtime: `flow`, `version`, `tenant`, `sha256(câu lệnh)`, `rows`, `durationMs`, `traceId`.

Hồ sơ native chỉ đóng gói driver PostgreSQL; CSDL khác (Oracle, SQL Server của HTTT cũ) chạy ở hồ sơ `legacy-jvm`.

## 5. Kho cấu hình và phát hành GitOps

Chương này mô tả con đường duy nhất để phiên bản đã duyệt tới pod runtime; mục 5.5 có sơ đồ trình tự từ nút "Phát hành" tới `SYNCED`.

### 5.1. Bố cục kho `dh-flows-{tenant}`

::: dac-ta
**Mục đích.** Ghi phiên bản đã duyệt vào kho tenant thành commit nguyên tử có chữ ký; Git là nguồn sự thật duy nhất.

**Lớp chính.** `GitConfigRepository` (JGit), `FlowManifestWriter`, `FileSigner`.

**Đơn vị chạy.** `dh-integration`, gói `internal.release`; tác vụ nền sau commit CSDL.

**FR hiện thực.** FR-04-042, 044, 045, 050.

**Giao diện vào.** `ReleaseService`, `CommandService`.

**Phụ thuộc ra.** Máy chủ Git; OpenBao `transit/dh-integration-git`.

**Dữ liệu.** Thư mục đệm clone; `deployment` sau khi push.

**Sự kiện.** Gián tiếp EVT-04-07.

**Lỗi và xử lý.** Thử lại 3 lần (2 s, 8 s, 30 s), rồi `FAILED`, ERR-04-022 (502).

**Quan sát.** `dh_int_git_write_failures_total`.
:::

PH-20 tạo kho khi khởi tạo tenant (ADR-068). Mỗi nhánh môi trường có cùng bố cục:

```text
dh-flows-t68/                  # nhánh env/test | env/staging | env/prod
├── README.md                       # sinh tự động, không sửa tay
├── tenant.dh.yaml                  # tenant, namespace đích, hồ sơ được phép, phiên bản lib
├── flows/
│   └── ho-tich-khai-sinh/
│       ├── flow.dh.yaml            # mô tả triển khai (§5.2)
│       ├── route.camel.yaml        # YAML chuẩn hóa, không có bố cục
│       ├── mappings/
│       │   └── ho-tich-ks-to-ndxp.jq
│       └── tests/                  # ca kiểm thử, chỉ CI kho cấu hình dùng
│           └── cases.dh.yaml
├── kamelets/
│   └── ho-tich-chuan-hoa-action.kamelet.yaml
└── .dh/
    └── signatures/                 # chữ ký tách rời của từng tệp do dh-integration ký
```

Tệp `*.dhmap.json` và bố cục sơ đồ không vào kho (BR-04-007); chỉ có `*.jq` sinh ra. Ca kiểm thử đi vào kho để CI kho cấu hình chạy lại trước khi gộp vào `env/prod` (ADR-068).

### 5.2. `flow.dh.yaml`

```yaml
apiVersion: dh.gov.vn/v1
kind: FlowDeployment
metadata:
  tenant: T68
  flow: ho-tich-khai-sinh
  version: 8
  contentHash: sha256:3f1c…
  approvedBy: u.ia01
  approvedAt: 2026-11-25T09:12:44+07:00
  publishedBy: u.ia01
  catalogVersion: camel-quarkus-3.33.2
spec:
  desiredState: RUNNING            # RUNNING | PAUSED | REMOVED
  pausedRoutes: []                 # route bị tạm dừng có chủ đích
  profile: core-native
  replicas: 3
  resources: { cpu: 250m, memory: 256Mi }
  exposure:
    http: [{ method: POST, path: /ho-tich/khai-sinh, routeId: ho-tich-khai-sinh-main }]
    kafka: { consume: [], produce: [] }
  connections: [ndxp-ho-tich]
  kamelets: [{ name: dh-receive-action, source: base }, { name: ho-tich-chuan-hoa-action, source: tenant, version: 2 }]
  env:
    ndxp-ma-don-vi: "{{dh.env.ndxp-ma-don-vi}}"
```

`dh-integration` sinh tệp bằng `FlowManifestWriter`; khóa xếp cố định để diff Git ổn định. Trường `desiredState`, `pausedRoutes` là nơi duy nhất ghi trạng thái mong muốn của lệnh điều khiển (§10).

### 5.3. Từ Git tới pod

ApplicationSet `dh-flows` (bộ sinh Git, mỗi tenant một Application mỗi môi trường) dựng từ mỗi thư mục `flows/*`:

1. Một `ConfigMap` `flow-{flow}` chứa `route.camel.yaml`, `*.jq`, `flow.dh.yaml`, nhãn `dh.gov.vn/tenant`, `dh.gov.vn/flow`, `dh.gov.vn/flow-version`, `dh.gov.vn/profile`.
2. Namespace đích: `dh-runtime` (dùng chung) hoặc `dh-rt-{tenant}` khi `tenant.dh.yaml` đặt `dedicatedNamespace: true` (ngưỡng 50 luồng, D03-10).
3. Mỗi hồ sơ trong namespace là một Deployment `dh-runtime-{profile}` (≥ 3 bản sao, HPA, KEDA theo độ trễ nhóm tiêu thụ). Luồng đi vào Deployment của hồ sơ ghi trong `flow.dh.yaml`.
4. Với điểm vào HTTP, Argo CD áp `ApisixRoute` cho `apisix-int` trỏ tới Service của hồ sơ, tiền tố đường dẫn theo tenant.

Argo CD không khởi động lại pod khi ConfigMap luồng đổi; việc nạp do `FlowLoader` làm (§5.4).

### 5.4. `FlowLoader` trong `dh-runtime`

::: dac-ta
**Mục đích.** Nạp, thay, tạm dừng, gỡ luồng theo ConfigMap mà không khởi động lại pod, cô lập lỗi theo luồng.

**Lớp chính.** `FlowLoader` (informer Fabric8), `SignatureVerifier`, `YamlRoutesBuilderLoader`, `RouteController`.

**Đơn vị chạy.** `dh-runtime`, mô-đun `dh-runtime-loader`.

**FR hiện thực.** FR-04-042, 050, 075.

**Giao diện vào.** ConfigMap có nhãn `dh.gov.vn/profile` của pod.

**Phụ thuộc ra.** Kubernetes API; ConfigMap `dh-runtime-trust`.

**Dữ liệu.** Nhóm route trong `CamelContext`; trạng thái ghi đè của lệnh khẩn.

**Sự kiện.** Kích hoạt EVT-04-12 sau mỗi lần nạp.

**Lỗi và xử lý.** Sai chữ ký, YAML lỗi: giữ nhóm cũ, báo `loadError`, triển khai `FAILED`.

**Quan sát.** Số lần nạp, lỗi nạp; gián đoạn HTTP ≤ 200 ms.
:::

`FlowLoader` là bộ điều khiển nhỏ dùng Kubernetes informer (Fabric8) theo dõi ConfigMap có nhãn `dh.gov.vn/profile = {hồ sơ của pod}` trong namespace của pod.

| Sự kiện ConfigMap | Hành động |
|---|---|
| Thêm | Kiểm chữ ký tách rời (khóa công khai của `dh-integration`), phân tích YAML bằng `YamlRoutesBuilderLoader`, nạp vào context với `routeGroup = {flow}`, áp `TenantGuard`, khởi động route trừ route trong `pausedRoutes` hoặc khi `desiredState = PAUSED` |
| Sửa, đổi `flow-version` | Nạp phiên bản mới song song dưới `routeGroup` tạm; khởi động thành công thì dừng, gỡ nhóm cũ (graceful 30 giây); lỗi thì giữ nhóm cũ, báo `loadError` trong nhịp tim |
| Sửa, chỉ đổi `desiredState`, `pausedRoutes` | Gọi `RouteController.suspendRoute`, `resumeRoute` |
| Xóa | Dừng, gỡ nhóm route |

: Hành động của `FlowLoader` theo sự kiện ConfigMap

Cô lập lỗi: mỗi luồng nạp riêng; lỗi nạp một luồng không chạm luồng khác (ADR-063). Điểm vào `platform-http` của hai phiên bản không cùng lúc nhận lưu lượng: phiên bản mới chỉ đăng ký đường dẫn sau khi phiên bản cũ ngừng nhận (khoảng gián đoạn ≤ 200 ms, lượt đang xử lý của bản cũ chạy hết). Luồng Kafka dùng cùng nhóm tiêu thụ nên chuyển giao qua tái cân bằng.

`HeartbeatPublisher` phát EVT-04-12 mỗi 30 giây và ngay sau mỗi lần nạp:

```json
{
  "replica": "dh-runtime-core-native-7c9f-2xk8p",
  "profile": "core-native",
  "namespace": "dh-runtime",
  "imageDigest": "sha256:…",
  "libVersion": "1.4.0",
  "at": "2026-11-25T22:00:30+07:00",
  "flows": [{
    "tenant": "T68", "flow": "ho-tich-khai-sinh", "version": 8, "contentHash": "sha256:3f1c…",
    "state": "STARTED", "loadError": null,
    "routes": [{ "id": "ho-tich-khai-sinh-main", "state": "Started", "inflight": 2,
                 "exchanges1m": 412, "failures1m": 3, "p95ms": 220 }]
  }]
}
```

### 5.5. Phát hành và nâng môi trường

::: dac-ta
**Mục đích.** Đưa phiên bản `APPROVED` lên môi trường đúng thứ tự, ngoài đóng băng, trên hồ sơ phù hợp; nâng và quay lui cùng cơ chế.

**Lớp chính.** `ReleaseService`, `ProfileResolver`, `EnvironmentOrderGuard`, `DeploymentTracker`.

**Đơn vị chạy.** `dh-integration`, gói `internal.release`.

**FR hiện thực.** FR-04-042, 044, 045, 075.

**Giao diện vào.** API-04-054, 055, 056; Argo CD; nhịp tim.

**Phụ thuộc ra.** `ValidationEngine` mức `PUBLISH`, `FreezeWindowGuard`, `GitConfigRepository`, ConfigMap `dh-runtime-manifests`.

**Dữ liệu.** `deployment`, `flow_version`, `outbox`.

**Sự kiện.** EVT-04-06, 07.

**Lỗi và xử lý.** ERR-04-005, 009, 022, 023 (thứ tự), 029 (hồ sơ), 040 (quay lui có thành phần cấm), 041 (423, đóng băng).

**Quan sát.** `dh_int_release_seconds{env}` (p95 PROD ≤ 3 phút, NFR-04-009).
:::

```java
@Transactional
public DeploymentView release(FlowVersionKey key, ReleaseRequest req, Actor actor, String idemKey) {
  var v = versions.lockForRelease(key);                         // SELECT … FOR UPDATE
  guard.requireStatus(v, APPROVED);                             // ERR-04-005
  freeze.requireOpen(req.target(), actor);                      // ERR-04-041 (BR-04-022)
  order.requirePreviousStageHealthy(v, req.target());           // ERR-04-023 (BR-04-019)
  var findings = validation.run(v, Level.PUBLISH, req.target());
  if (findings.hasErrors()) throw new ValidationFailed(findings); // ERR-04-009
  var profile = profiles.resolve(v.components());               // ERR-04-029
  var dep = deployments.createPending(v, req.target(), profile, actor);
  outbox.add(Evt.deploymentRequested(dep));                     // EVT-04-06
  afterCommit(() -> gitWriter.write(dep));                      // ngoài giao dịch CSDL
  return dep.view();
}
```

`GitConfigRepository.write(dep)` chạy ở tác vụ nền có thử lại (3 lần, 2 s, 8 s, 30 s): clone nông nhánh đích vào thư mục tạm (bộ đệm cục bộ theo tenant), ghi tệp, ký từng tệp (Ed25519, khóa `transit/dh-integration-git`), commit có chữ ký với tác giả `dh-integration[bot]` và trailer `Dh-Published-By: u.ia01`, `Dh-Deployment: {id}`, push. Với `env/test`: push thẳng. Với `env/prod` (nhánh bảo vệ): push nhánh `release/{flow}-v{n}`, mở yêu cầu gộp, CI kho cấu hình chạy lại VR mức `PUBLISH` và ca kiểm thử, tự gộp khi đạt (ADR-068). Lỗi sau 3 lần: triển khai `FAILED` với ERR-04-022, thông báo người phát hành.

```{.mermaid caption="Trình tự phát hành một phiên bản lên PROD tới trạng thái SYNCED"}
sequenceDiagram
    autonumber
    actor IA as Người phát hành (IA)
    participant API as dh-integration REST
    participant REL as ReleaseService
    participant PG as pg-core ph04
    participant GIT as GitConfigRepository
    participant REPO as Kho dh-flows-t68
    participant ARGO as Argo CD
    participant RT as dh-runtime FlowLoader
    participant REC as Reconciler
    IA->>API: POST deployments, target PROD, Idempotency-Key
    API->>REL: release(key, req)
    REL->>PG: Khóa phiên bản, kiểm trạng thái, đóng băng, thứ tự, VR PUBLISH
    REL->>PG: Ghi deployment PENDING và outbox EVT-04-06
    REL-->>IA: 202 với deploymentId
    REL->>GIT: Sau commit, ghi tệp và ký
    GIT->>REPO: Push nhánh release, mở yêu cầu gộp vào env/prod
    REPO-->>REPO: CI kho chạy VR PUBLISH và ca kiểm thử, tự gộp
    ARGO->>REPO: Phát hiện commit mới
    ARGO->>RT: Áp ConfigMap flow-ho-tich-khai-sinh
    ARGO-->>REC: Application Progressing, deployment SYNCING
    RT->>RT: Kiểm chữ ký, nạp song song, thay nhóm route cũ
    RT-->>REC: Nhịp tim EVT-04-12 có version 8 và contentHash
    REC->>PG: Đủ bản sao, deployment SYNCED, outbox EVT-04-07
```

Hình cho thấy ghi Git chạy sau commit CSDL nên lỗi Git chỉ chuyển triển khai sang `FAILED`, và triển khai chỉ `SYNCED` khi chính runtime báo đúng phiên bản, băm qua nhịp tim chứ không phải khi Argo CD báo đồng bộ.

Từ `PENDING` sang `SYNCING` khi Argo CD báo Application `Progressing` (webhook Argo CD hoặc hỏi API mỗi 10 giây); `SYNCED` khi đủ số bản sao báo `version`, `contentHash` mới qua nhịp tim; `OUT_OF_SYNC` khi quá `04.runtime.sync-timeout-seconds` mà chưa đủ; `FAILED` khi quá `04.deploy.timeout-minutes` hoặc có `loadError`.

### 5.6. Outbox và sự kiện

::: dac-ta
**Mục đích.** Phát sự kiện miền và kiểm toán ra ngoài DU tin cậy, cùng giao dịch với thay đổi dữ liệu.

**Lớp chính.** `OutboxWriter`, `AuditWriter`.

**Đơn vị chạy.** `dh-integration`, gói `internal.outbox`, `internal.audit`; Debezium.

**FR hiện thực.** FR-04-083 và mọi FR có sự kiện.

**Giao diện vào.** Sự kiện miền ở §3.3.

**Phụ thuộc ra.** Kafka qua Debezium; PH-13.

**Dữ liệu.** `outbox`.

**Sự kiện.** EVT-04-01…10, kiểm toán.

**Lỗi và xử lý.** Kafka, PH-13 không nhận: giữ ở outbox, gửi lại; không mất khi khởi động lại.

**Quan sát.** Số dòng outbox chưa chuyển.
:::

Bảng `ph04.outbox` (DD-11) ghi cùng giao dịch với thay đổi miền; Debezium đọc WAL, định tuyến theo cột `topic` (EVT-04-01…10). Topic hệ thống EVT-04-11 (lệnh) không qua outbox vì lệnh khẩn phải đi trước mọi ghi khác (§10.2); `CommandService` gửi trực tiếp bằng nhà sản xuất Kafka lũy đẳng `acks=all` và ghi bảng `runtime_command` trong cùng luồng xử lý (gửi trước, ghi sau với lệnh khẩn; ghi trước, gửi sau với lệnh thường).

## 6. Trình thiết kế

Phần này bổ sung D03-06-PH04 §27 ở mức thuật toán. Mã nằm ở `apps/console/src/features/integration/designer/`.

### 6.1. Mô hình tài nguyên

::: dac-ta
**Mục đích.** Một nguồn sự thật trong trình duyệt cho định nghĩa đang soạn; sơ đồ, Inspector, YAML luôn khớp, mọi thao tác hoàn tác được.

**Lớp chính.** `ResourceTree`, `StepNode`, `Command`, `UndoStack`.

**Đơn vị chạy.** `dh-console`, `features/integration/designer/model/`.

**FR hiện thực.** FR-04-013, 014, 017, 018, 019, 021, 026.

**Giao diện vào.** Thao tác trên sơ đồ, Inspector, YAML.

**Phụ thuộc ra.** Catalog (§6.6), bộ ghi YAML (§6.2), worker kiểm tra (§7.1).

**Dữ liệu.** Bộ nhớ trình duyệt; IndexedDB.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** Phần tử lạ giữ ở `raw`; YAML sửa tay lỗi: giữ cây cũ, báo dòng, cột.

**Quan sát.** Thời gian vẽ lại, sinh YAML (≤ 100 ms, NFR-04-005).
:::

Trình thiết kế không thao tác trực tiếp trên YAML hay trên nút XYFlow. Nguồn sự thật trong trình duyệt là **cây tài nguyên** (`ResourceTree`) theo mô hình của Kaoto (ADR-060):

```ts
type NodeId = string;                     // ổn định: lấy từ `id` Camel; thiếu thì sinh `{loại}-{8 ký tự}` và ghi vào YAML
interface StepNode {
  id: NodeId;
  kind: 'from' | 'eip' | 'component' | 'kamelet' | 'unknown';
  name: string;                           // 'choice', 'to', 'kamelet:dh-deliver-action', 'http'…
  props: Record<string, unknown>;         // chỉ giá trị khác mặc định hoặc được ghim "luôn ghi"
  uri?: { scheme: string; path: string; params: Record<string, string> };
  branches?: { key: 'when' | 'otherwise' | 'doTry' | 'doCatch' | 'doFinally' | 'steps'; cond?: Expr; steps: StepNode[] }[];
  raw?: unknown;                          // phần tử không biểu diễn được, giữ nguyên để ghi lại
  comments?: { before?: string[]; inline?: string };
}
interface ResourceTree { kind: 'ROUTE' | 'KAMELET' | 'PIPE' | 'TEST'; items: TopLevel[]; beans: BeanDef[]; }
```

Mọi thay đổi là một `Command` (`InsertStep`, `MoveStep`, `RemoveStep`, `SetProp`, `WrapInStage`, `ExtractSubroute`, `ReplaceDefinition`…) có `apply` và `invert`; ngăn hoàn tác ≥ 100 lệnh, gộp lệnh cùng trường trong 1 giây (D03-06-PH04 §10.20). Sơ đồ (XYFlow) và YAML đều là **hình chiếu** của cây: đổi cây thì vẽ lại sơ đồ và sinh lại YAML (≤ 100 ms, NFR-04-005); sửa YAML thì phân tích lại thành cây sau 500 ms ngừng gõ, rồi đối chiếu `id` để giữ vùng chọn.

### 6.2. Quay vòng YAML và băm nội dung

::: dac-ta
**Mục đích.** Đọc rồi ghi YAML không đổi nội dung (BR-04-006); mọi bên cùng một băm.

**Lớp chính.** Bộ ghi `yaml` (eemeli) chế độ `Document`; `YamlCanonicalizer` (SnakeYAML Engine).

**Đơn vị chạy.** `dh-console`; `dh-integration` gói `internal.version`.

**FR hiện thực.** FR-04-017, 027.

**Giao diện vào.** Cây tài nguyên; văn bản YAML; API-04-022, 027.

**Phụ thuộc ra.** `yaml-key-order.json` của catalog.

**Dữ liệu.** `flow_version.definition_yaml`, `content_hash`.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** Khác biệt quay vòng chặn CI; băm chỉ lấy từ máy chủ.

**Quan sát.** Bộ ngữ liệu quay vòng ở CI-2, CI-6.
:::

Bộ đọc, ghi dùng `yaml` (eemeli) chế độ `Document` để giữ chú thích và thứ tự khóa của phần không bị sửa. Quy trình ghi:

1. Duyệt cây, phát `Document` theo thứ tự khóa của lược đồ Camel YAML DSL cho phiên bản catalog (bảng thứ tự sinh cùng catalog).
2. Phần tử `unknown` ghi lại `raw` nguyên dạng.
3. Bỏ thuộc tính bằng mặc định của catalog, trừ thuộc tính ghim.
4. Thụt lề 2, chuỗi nhiều dòng dùng `|`, kết thúc một dòng trống.

**YAML chuẩn hóa** (để băm, để ghi Git) do máy chủ tính bằng `YamlCanonicalizer` (Java, SnakeYAML Engine): bỏ mọi chú thích, sắp khóa theo bảng thứ tự của catalog, chuẩn hóa vô hướng (`true`, số không ngoặc), thụt lề 2, một dòng trống cuối. `contentHash = sha256(canonicalYaml ‖ 0x00 ‖ sha256(*.jq theo tên))`. Trình duyệt không tự tính băm dùng cho điều kiện duyệt; băm chỉ lấy từ máy chủ.

Kiểm thử quay vòng (BR-04-006, ADR-060): bộ ngữ liệu gồm 9 luồng mẫu, 41 tệp XML Bus cũ đã chuyển, toàn bộ ví dụ YAML trong tài liệu Camel 4.18; với mỗi tệp: đọc → ghi không sửa → so byte (phía trình duyệt) và so băm chuẩn hóa (phía máy chủ). Một khác biệt là lỗi chặn CI.

### 6.3. Ánh xạ nhóm nghiệp vụ của bảng thành phần

::: dac-ta
**Mục đích.** Bảng thành phần theo nhóm nghiệp vụ tiếng Việt, tìm không dấu và theo từ đồng nghĩa; tự bố cục giữ nút đã ghim.

**Lớp chính.** `palette-groups.json`, `PaletteIndex` (`minisearch`), `LayoutWorker` (dagre).

**Đơn vị chạy.** `dh-console` (Web Worker); luật nhóm phục vụ từ `dh-integration`.

**FR hiện thực.** FR-04-012, 013, 026.

**Giao diện vào.** API-04-070; UI-04-17.

**Phụ thuộc ra.** `CatalogService`, chính sách thành phần.

**Dữ liệu.** `palette_group_rule`; `flow_version.canvas_layout`.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** Không khớp luật: nhóm `other`; luật hỏng: dùng bản `active` trước.

**Quan sát.** Thời gian bố cục (lấy mẫu).
:::

Tệp `palette-groups.json` (vendor cùng catalog, PA sửa được qua UI-04-17, lưu ở `ph04.palette_group_rule`, phục vụ qua API-04-070) gồm danh sách luật xét theo thứ tự; một thành phần thuộc mọi nhóm có luật khớp:

```json
{
  "version": 3,
  "groups": [
    { "code": "entry",     "label": "Điểm vào",          "icon": "LogIn",        "color": "color-chart-1",
      "match": [{ "role": "consumer", "names": ["platform-http","rest","kafka","timer","cron","scheduler"] },
                { "kameletType": "source" }] },
    { "code": "routing",   "label": "Định tuyến",        "icon": "GitBranch",    "color": "color-chart-2",
      "match": [{ "eipLabel": "routing" }, { "names": ["choice","filter","split","aggregate","multicast","recipientList","loadBalance"] }] },
    { "code": "transform", "label": "Chuyển đổi dữ liệu", "icon": "Shuffle",     "color": "color-chart-3",
      "match": [{ "eipLabel": "transformation" }, { "kind": ["dataformat","language"] }, { "names": ["jq","setBody","marshal","unmarshal"] }] },
    { "code": "database",  "label": "Kết nối CSDL",      "icon": "Database",     "color": "color-chart-4",
      "match": [{ "componentLabel": ["database","sql"] }, { "names": ["dh-sql-ro-source","dh-sql-ro-action"] }] },
    { "code": "network",   "label": "Mạng",              "icon": "Globe",        "color": "color-chart-5",
      "match": [{ "names": ["http","https","rest","file","ftp","sftp","ftps","cxf","soap"] }] },
    { "code": "messaging", "label": "Hàng đợi bản tin",  "icon": "Mail",         "color": "color-chart-6",
      "match": [{ "componentLabel": ["messaging"] }, { "names": ["kafka","jms","amqp","mqtt"] }] },
    { "code": "schedule",  "label": "Lập lịch",          "icon": "CalendarClock","color": "color-chart-7",
      "match": [{ "componentLabel": ["scheduling"] }, { "names": ["timer","quartz","cron","scheduler"] }] },
    { "code": "security",  "label": "Bảo mật",           "icon": "ShieldCheck",  "color": "color-chart-8",
      "match": [{ "componentLabel": ["security"] }, { "names": ["crypto","jasypt"] }, { "kameletLabel": "dh-mask" }] },
    { "code": "dh-stage",  "label": "Chặng chuẩn Datahub","icon": "Hexagon",     "color": "color-accent",
      "match": [{ "kameletPrefix": "dh-" }] },
    { "code": "other",     "label": "Khác",              "icon": "Box",          "color": "color-neutral-solid",
      "match": [{ "fallback": true }] }
  ],
  "synonyms": { "gọi api": ["http","rest"], "csdl": ["sql","jdbc"], "tệp": ["file","ftp","sftp"], "hẹn giờ": ["timer","cron"] }
}
```

Nhóm `other` chỉ nhận thành phần không khớp nhóm nào khác. Từ đồng nghĩa tiếng Việt dùng cho tìm kiếm (tìm mờ không dấu, `minisearch` trong Web Worker).

### 6.4. Bố cục sơ đồ

Bố cục tự động: dagre trong Web Worker, hướng trái sang phải, `ranksep` 64, `nodesep` 24, khối chặng chuẩn là nút nhóm có thể thu gọn. Người dùng kéo chặng thì vị trí được ghim (`pinned: true`) và lưu ở `canvasLayout.nodes[id]`; lần bố cục sau giữ nút ghim, xếp nút còn lại quanh chúng. `canvasLayout` gồm `nodes{ id → {x, y, pinned, collapsed} }`, `notes[]` (ghi chú dán: văn bản ≤ 2.000 ký tự, màu, vị trí, gắn với `id` chặng tùy chọn), `viewport`. Chặng bị xóa thì mục bố cục của nó bị dọn khi lưu.

### 6.5. Lưu nháp, phiên soạn và gộp ba bên

::: dac-ta
**Mục đích.** Không mất công soạn khi mất mạng, đóng tab hay hai người cùng sửa; báo người khác đang sửa.

**Lớp chính.** `DraftStore` (IndexedDB), `AutoSaver`, `ThreeWayMerge`, `EditSession`.

**Đơn vị chạy.** `dh-console`; `dh-integration` gói `internal.session`.

**FR hiện thực.** FR-04-010, 024.

**Giao diện vào.** API-04-022 (`If-Match`), API-04-034.

**Phụ thuộc ra.** Valkey `HEXPIRE` 120 giây.

**Dữ liệu.** IndexedDB; `flow_version` (`version`, `content_hash`).

**Sự kiện.** Không phát.

**Lỗi và xử lý.** ERR-04-006 (412) mở gộp ba bên; xung đột cùng trường do người dùng chọn; không có `HEXPIRE` xem Q04-23.

**Quan sát.** Số lần xung đột, khôi phục bản nháp.
:::

Trình tự lưu: (1) ghi bản nháp vào IndexedDB khóa `dh.int.draft.{tenant}.{flow}.{version}` sau mỗi lệnh (gộp 1 giây); (2) 30 giây sau thay đổi cuối hoặc `Ctrl+S`, gửi API-04-022 với `If-Match: "{etag}"`, thân `VersionDraftUpdate`; (3) máy chủ trả ETag mới và kết quả mức `DESIGN`; (4) xóa bản IndexedDB tương ứng ETag đã xác nhận.

ETag = `W/"{version}-{contentHash[0..8]}"` của `flow_version`. Máy chủ cập nhật bằng `UPDATE … WHERE id = ? AND version = ?`; 0 dòng thì trả ERR-04-006 kèm `currentEtag`, `savedBy`, `savedAt`.

Gộp ba bên (`ThreeWayMerge` trong worker): đầu vào là cây gốc (lần tải cuối), cây của mình, cây máy chủ. So theo `id` nút:

| Trường hợp | Kết quả |
|---|---|
| Nút chỉ một bên sửa | Lấy bên sửa |
| Nút hai bên sửa khác trường | Gộp theo trường |
| Cùng trường hai bên khác giá trị | Xung đột, người dùng chọn |
| Một bên xóa, bên kia sửa | Xung đột |
| Hai bên chèn nút mới cùng vị trí | Giữ cả hai, nút của mình sau |
| `canvasLayout` | Lấy của mình |
| `samples` theo `id` chặng | Như trường |

: Quy tắc gộp ba bên theo nút

Phiên soạn (API-04-034): khóa Valkey `dh:int:edit:{tenant}:{flowId}:{versionNo}` là hash `userId → {lastSeen, displayName}`, mỗi trường hết hạn sau 120 giây (Valkey 8 hỗ trợ TTL theo trường `HEXPIRE`). Phản hồi nhịp trả danh sách người khác và `catalogVersion` hiện hành của tenant.

### 6.6. Đường sinh catalog

::: dac-ta
**Mục đích.** Trình thiết kế, kiểm tra hợp lệ và runtime dùng một catalog cho đúng phiên bản Camel Quarkus.

**Lớp chính.** `catalog-gen`, `catalog:check`, `catalog-diff`, `CatalogService`, `ComponentPolicy`, `CatalogUpgradeJob`.

**Đơn vị chạy.** CI; `dh-integration` gói `internal.catalog`.

**FR hiện thực.** FR-04-080, 081; UC-04-22.

**Giao diện vào.** API-04-070…074; `runtime-manifest.json`.

**Phụ thuộc ra.** `@kaoto/camel-catalog`; ConfigMap `dh-runtime-manifests`; Valkey.

**Dữ liệu.** `component_policy`, `component_proposal`, `catalog_change`.

**Sự kiện.** Thông báo người đóng góp qua PH-15 khi nâng.

**Lỗi và xử lý.** Lệch bản phụ: CI đỏ; ERR-04-011 (bị cấm), 035 (không có), 042 (catalog cũ).

**Quan sát.** Phiên bản catalog theo tenant (API-04-073).
:::

```text
camel/*/pom.xml  ──đọc phiên bản──►  tools/catalog-gen (Node)
                                       │  @kaoto/camel-catalog 0.7.0 (camel-quarkus 3.33.1)
                                       │  hoặc camel-catalog 4.18.x khi không có gói Kaoto
                                       ▼
apps/console/src/features/integration/designer/catalog/generated/
  ├── index.json        # runtime, runtimeVersion, camelVersion, generatedAt, sha256
  ├── components/*.json # lược đồ thuộc tính theo nhóm
  ├── eips.json, languages.json, dataformats.json, kamelets/*.json
  ├── yaml-key-order.json
  └── i18n/vi.json      # bản dịch tiêu đề, mô tả
```

`npm run catalog:check` (cổng CI, PR #5) so `runtimeVersion` với `camel-quarkus.version` của từng hồ sơ trong `dh-runtime/profiles/*/pom.xml`; lệch bản phụ thì đỏ; lệch bản vá thì chạy `catalog-diff` và chỉ xanh khi danh sách thành phần, lược đồ không đổi. `dh-integration` nạp cùng thư mục sinh (đóng vào ảnh) để phục vụ API-04-070, 071 và cho `ValidationEngine` phía máy chủ, nên hai phía luôn cùng một catalog.

Nâng runtime (UC-04-22): `CatalogUpgradeJob` so catalog cũ, mới, ghi `ph04.catalog_change` (thành phần, thuộc tính bị bỏ, đổi tên), đánh dấu `flow_version.needs_revalidation = true` cho phiên bản mở và phiên bản đang chạy của tenant được nâng, phát thông báo cho người đóng góp.

### 6.7. Trình ánh xạ dữ liệu

::: dac-ta
**Mục đích.** Ánh xạ trường bằng kéo nối, sinh JQ như nhau ở trình duyệt và máy chủ, xem trước trên bản tin mẫu.

**Lớp chính.** `DhmapToJq` (TypeScript và Java), `MappingService`, `MappingPreview`.

**Đơn vị chạy.** `dh-console`; `dh-integration` gói `internal.mapping`; sandbox.

**FR hiện thực.** FR-04-020, 065.

**Giao diện vào.** API-04-022, 033.

**Phụ thuộc ra.** PH-06 (lược đồ), PH-07 (`dh_map`), sandbox; `jq-web` khi sandbox vắng.

**Dữ liệu.** `flow_mapping`; Git chỉ nhận `*.jq`.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** ERR-04-021, 038; JQ hai bên khác: dùng bản máy chủ, ghi cảnh báo.

**Quan sát.** Số lần JQ lệch (bằng 0 ở CI).
:::

`*.dhmap.json` (ADR-066):

```json
{
  "format": "dhmap/1",
  "source": { "type": "jsonschema", "ref": "ho-tich-ks", "version": 4 },
  "target": { "type": "jsonschema", "ref": "ndxp-khai-sinh-req", "version": 3 },
  "rules": [
    { "to": "/request/sex",       "from": "/hoSo/gioiTinh", "fn": { "name": "dh_map", "args": ["gioi-tinh-ht-ndxp"] } },
    { "to": "/request/birthDate", "from": "/hoSo/ngaySinh", "fn": { "name": "date", "args": ["dd/MM/yyyy", "iso"] } },
    { "to": "/documents",         "from": "/giayTo", "each": [
        { "to": "type", "from": "loai" }, { "to": "number", "from": "so" } ] },
    { "to": "/request/province",  "const": { "var": "$tenant" } },
    { "to": "/requestedAt",       "fn": { "name": "now" } }
  ],
  "customJq": null
}
```

Bộ sinh JQ (`dhmap → jq`) có hai bản cùng hành vi: TypeScript ở trình duyệt (để xem ngay) và Java ở máy chủ (nguồn chuẩn khi lưu). Bộ kiểm thử dùng chung ngữ liệu `*.dhmap.json → *.jq` mong đợi để hai bản không lệch. Khi lưu, máy chủ sinh lại JQ, so với JQ trình duyệt gửi; khác thì dùng bản máy chủ và ghi cảnh báo. Xem trước gọi API-04-033 trên sandbox (`camel-quarkus-jq` có hàm `dh_map`); sandbox không sẵn sàng thì dùng `jq-web` trong trình duyệt với nhãn mô phỏng (GAP-04-09).

## 7. Kiểm tra hợp lệ

Chương này mô tả cách hiện thực 20 quy tắc VR và 6 quy tắc LINT: chạy ở trình duyệt để phản hồi tức thì và ở máy chủ làm nguồn chuẩn.

### 7.1. Kiến trúc

::: dac-ta
**Mục đích.** Kiểm định nghĩa ở ba mức `DESIGN`, `SUBMIT`, `PUBLISH`, trả phát hiện có vị trí nút.

**Lớp chính.** `ValidationEngine`, `ValidationRule` (`Vr01Parse`…`Vr20TestAssertions`), `ValidationContext`; worker `validation/`.

**Đơn vị chạy.** `dh-integration` gói `internal.validation`; worker trình duyệt.

**FR hiện thực.** FR-04-023; VR-01…20, LINT-04-01…06.

**Giao diện vào.** API-04-030, 031, 032; `VersionService`, `ReviewService`, `ReleaseService`.

**Phụ thuộc ra.** Catalog, chính sách, `ConnectionDirectory`, `TopicDirectory`, `PublishedRouteIndex`.

**Dữ liệu.** `flow_version.last_validation`.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** ERR-04-009 kèm `findings[]`; mã riêng 010, 011, 012, 013, 031, 037, 042.

**Quan sát.** `dh_int_validation_seconds{level}` (p95 ≤ 2 s, NFR-04-007).
:::

Quy tắc VR là các lớp độc lập, cài ở hai nơi:

| Nơi | Quy tắc | Mục đích |
|---|---|---|
| Trình duyệt (worker `validation/`) | VR-01…09, 15, 18, 20 và LINT-04-01…06 | Phản hồi tức thì khi soạn |
| Máy chủ (`ValidationEngine`) | VR-01…20 | Nguồn chuẩn ở mọi mức; mức `SUBMIT`, `PUBLISH` chỉ tính kết quả máy chủ |

: Nơi cài quy tắc kiểm tra

```java
public sealed interface ValidationRule permits Vr01Parse, Vr02Schema, Vr03Secret, /* … */ Vr20TestAssertions {
  String code();
  Severity severity(Level level);                // bảng mức của FRS §5.2 FR-04-023
  void check(ValidationContext ctx, FindingSink sink);
}

public record ValidationContext(TenantId tenant, ResourceTree tree, Exposure exposure,
    CatalogSnapshot catalog, ComponentPolicyView policy, ConnectionDirectory connections,
    TopicDirectory topics, PublishedRouteIndex routes, Environment targetEnv, Level level) {}
```

`ValidationEngine.run` chạy song song các quy tắc độc lập trên cây đã phân tích một lần, thời hạn tổng 2 giây ở p95 cho luồng 200 chặng (NFR-04-007). Kết quả lưu vào `flow_version.last_validation` (`jsonb`: mức, thời điểm, `catalogVersion`, danh sách `Finding`). Mức `DESIGN` không chặn lưu; `SUBMIT`, `PUBLISH` chặn khi có `ERROR`.

### 7.2. Ghi chú hiện thực từng quy tắc

Bảng dưới nói thư viện hoặc nguồn dữ liệu mà mỗi quy tắc dùng; định nghĩa và mức nghiêm trọng của quy tắc ở FRS FR-04-023.

| VR | Hiện thực |
|---|---|
| VR-01 | SnakeYAML Engine `LoadSettings` giới hạn độ sâu 64, bí danh 50, kích thước 512 KiB (chống "billion laughs") |
| VR-02 | Duyệt cây, mỗi nút đối chiếu lược đồ JSON của thành phần (networknt json-schema-validator), thông báo theo `messageKey` tiếng Việt |
| VR-03 | `SecretDetector` (§7.3) |
| VR-04, 12, 19 | Tra `ComponentPolicyView` hợp nhất chính sách nền + tenant, kèm `runtime-manifest.json` để biết native |
| VR-05, 06 | Thứ tự `dh-stage-*` theo §4.4; `exposure` lấy từ luồng |
| VR-07 | `ConnectionDirectory.resolve(tenant, workspace, code, env)`; ở `PUBLISH` bắt buộc có giá trị ở `targetEnv` |
| VR-08, 18 | `PublishedRouteIndex` (bảng `flow_route_index`, `flow_endpoint_index`) trừ chính luồng đó |
| VR-09 | Tập `direct:`, `seda:` định nghĩa trong tệp ∪ `PublishedRouteIndex` cùng tenant |
| VR-10 | `TopicDirectory.canPublish/canSubscribe(flow, topic)` |
| VR-11 | Có `routeConfigurationId: dh-default-config` hoặc `errorHandler` dạng `deadLetterChannel` tới `kafka:{tenant}.ops.dlq.v1` |
| VR-13 | `SqlPolicy` (§7.4) |
| VR-14 | Có `dh-receive-action` trong khối `dh-stage-receive`; không có `setHeader` tên `dh-tenant` ở bất kỳ đâu |
| VR-15 | Thuộc tính Kamelet có `x-descriptors: [urn:camel:group:credentials]` hoặc `format: password` phải là tham chiếu bí mật; Pipe kiểm loại `source`, `action`, `sink` |
| VR-16 | Biên dịch biểu thức bằng `Language.createPredicate/createExpression` của Camel 4.18 nhúng trong `dh-integration` (chỉ thư viện ngôn ngữ, không có component) |
| VR-17 | So `definition.catalogVersion` với catalog hiện hành của tenant |
| VR-20 | Mỗi ca trong tài nguyên `TEST` có ≥ 1 khẳng định |

: Ghi chú hiện thực từng quy tắc VR

### 7.3. Phát hiện bí mật

::: dac-ta
**Mục đích.** Phát hiện giá trị giống bí mật, dữ liệu cá nhân giống thật trong định nghĩa, bản tin mẫu, ca kiểm thử.

**Lớp chính.** `SecretDetector`, `EntropyScorer`, `PiiLikePatterns`.

**Đơn vị chạy.** `dh-integration`; worker trình duyệt; bước che của sandbox.

**FR hiện thực.** FR-04-016, 022, 023 (VR-03, LINT-04-06).

**Giao diện vào.** `Vr03Secret`, `TestRunService`, `StepTracer`.

**Phụ thuộc ra.** Không.

**Dữ liệu.** Không lưu giá trị; `Finding.args` chỉ có `node`, `field`, `pattern`.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** ERR-04-010 (422), chỉ đường dẫn.

**Quan sát.** Số phát hiện theo mẫu.
:::

`SecretDetector` kiểm mọi giá trị vô hướng trong cây (kể cả tham số URI, tiêu đề đặt bằng `setHeader`, giá trị bean):

1. Tên khóa khớp `(?i)(pass(word)?|secret|token|api[-_]?key|private[-_]?key|credential|authorization)` mà giá trị không phải `{{conn:…}}`, `{{vault:…}}`, `#bean:…`, `{{dh.env.…}}` hay rỗng.
2. Giá trị khớp mẫu: khóa PEM (`-----BEGIN`), JWT (`eyJ…\.…\.…`), `Basic [A-Za-z0-9+/=]{12,}`, `Bearer \S{20,}`, URI có `user:pass@`.
3. Chuỗi dài ≥ 24 ký tự có entropy Shannon ≥ 4,0 bit/ký tự ở trường kiểu chuỗi không thuộc danh sách trường được miễn (biểu thức, đường dẫn, mô tả).

Kết quả không bao giờ lặp lại giá trị; `Finding.args` chỉ có `node`, `field`, `pattern`. Cùng bộ phát hiện chạy trên bản tin mẫu và ca kiểm thử (LINT-04-06 cho dữ liệu giống thật: 12 chữ số dạng số định danh, số điện thoại di động Việt Nam).

### 7.4. Chính sách SQL

::: dac-ta
**Mục đích.** Chặn tĩnh SQL không phải một câu đọc, đụng schema cấm hoặc ghép chuỗi; lớp phụ trước quyền CSDL.

**Lớp chính.** `SqlPolicy` (JSqlParser 5.x), `TablesNamesFinder`.

**Đơn vị chạy.** `dh-integration` gói `internal.validation`.

**FR hiện thực.** FR-04-072 (VR-13).

**Giao diện vào.** `Vr13SqlPolicy`.

**Phụ thuộc ra.** Schema được phép của kết nối (`ConnectionDirectory`).

**Dữ liệu.** Không.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** ERR-04-031 (422) với `reason`, không trích câu lệnh.

**Quan sát.** Số vi phạm theo `reason`.
:::

`SqlPolicy` dùng JSqlParser 5.x:

1. Tách câu lệnh; hơn một câu → lỗi.
2. Câu lệnh phải là `PlainSelect`, `SetOperationList` hoặc `WithItem … Select`; mọi `Insert`, `Update`, `Delete`, `Merge`, `Upsert`, DDL, `Execute`, `Copy`, `SELECT … INTO`, `FOR UPDATE` → lỗi.
3. Duyệt bảng tham chiếu (`TablesNamesFinder`): schema phải thuộc danh sách được phép của kết nối; `ph01…ph20`, `public` của `pg-core`, mọi đối tượng của `pg-payment` → lỗi.
4. Hàm gọi trong danh sách cấm (`pg_read_file`, `pg_sleep`, `dblink*`, `lo_*`, `set_config`, `nextval`…) → lỗi.
5. Giá trị vào chỉ là tham số `:#tên`; phát hiện `${…}` của Camel simple ghép vào chuỗi SQL → lỗi.

Lỗi trả ERR-04-031 với `reason` mô tả (không trích câu lệnh đầy đủ). Kiểm tra tĩnh là lớp phụ; chốt chặn là quyền CSDL của tài khoản (ADR-067).

## 8. Chạy thử

Chương này mô tả chạy thử bằng Camel thật trong sandbox cô lập, khẳng định và điều kiện "đã chạy thử đạt" khi gửi duyệt.

### 8.1. Kiến trúc sandbox

::: dac-ta
**Mục đích.** Chạy thử đúng định nghĩa theo băm bằng cùng phiên bản Camel, đích mô phỏng, không chạm hệ thật.

**Lớp chính.** `SandboxWorker`, `DefinitionRewriter`, `StepTracer`, `AssertionEvaluator`.

**Đơn vị chạy.** `dh-runtime-sandbox`, một Deployment mỗi hồ sơ, namespace `dh-sandbox` (Q04-20).

**FR hiện thực.** FR-04-030, 031, 033; ADR-064.

**Giao diện vào.** Valkey Stream `dh:int:testrun:queue`; `GET /internal/v1/testruns/{id}/bundle`.

**Phụ thuộc ra.** `POST /internal/v1/testruns/{id}/steps`; WireMock, OPA, Kafka sandbox; kết nối TEST; Ceph RGW.

**Dữ liệu.** `CamelContext` riêng mỗi lần; thân đầy đủ ở `dh-int-testrun`.

**Sự kiện.** Không phát trực tiếp.

**Lỗi và xử lý.** Việc chưa `XACK` nhận lại sau 60 giây; quá thời hạn: `TIMED_OUT`, ERR-04-020.

**Quan sát.** `dh_int_testrun_queue_depth`, `dh_int_testrun_duration_seconds`.
:::

`dh-runtime-sandbox` là Quarkus JVM cùng phiên bản Camel Quarkus với hồ sơ đích (một Deployment cho mỗi hồ sơ: `sandbox-core`, `sandbox-files`, `sandbox-soap`, `sandbox-legacy`). Mỗi lần chạy tạo một `CamelContext` riêng trong tiến trình (khởi tạo ≈ 300–800 ms), không dùng chung trạng thái giữa các lần, đóng ngay khi xong. Một pod chạy tối đa 4 lần đồng thời; KEDA mở rộng theo độ dài hàng đợi `dh:int:testrun:queue`.

Cô lập:

| Lớp | Biện pháp |
|---|---|
| Mạng | `NetworkPolicy` ra chỉ tới WireMock nội bộ, Kafka sandbox, OPA sandbox; với `SANDBOX_LIVE` thêm danh sách đích của kết nối có giá trị TEST (egress gateway kiểm FQDN) |
| Thành phần | Chính sách thành phần của sandbox cấm thêm `file`, `exec`, `ssh`, `docker`, `kubernetes-*`; `platform-http` được thay bằng `direct:` gọi trực tiếp |
| Tài nguyên | Giới hạn CPU, bộ nhớ theo pod; thời hạn mỗi lần 1–120 giây; thân ≤ 256 KiB |
| Bí mật | Chỉ giá trị TEST của kết nối, cấp qua OpenBao với chính sách `sandbox-{tenant}` |
| Dữ liệu | Không có quyền đọc CSDL nghiệp vụ; chặng SQL ở `MOCK` trả dữ liệu mẫu ghim của chặng |

: Các lớp cô lập của sandbox

### 8.2. Giao thức chạy

::: dac-ta
**Mục đích.** Xếp hàng chạy thử theo hạn mức tenant, nhận vết, đẩy SSE, lưu lịch sử cho điều kiện gửi duyệt.

**Lớp chính.** `TestRunService`, `SandboxClient`, `TestCaseService`, `TestRunRetentionJob`.

**Đơn vị chạy.** `dh-integration` gói `internal.testrun`.

**FR hiện thực.** FR-04-030, 031, 032; BR-04-004.

**Giao diện vào.** API-04-040…044; API nội bộ `bundle`, `steps`.

**Phụ thuộc ra.** Valkey; `ValidationEngine`; Ceph RGW.

**Dữ liệu.** `test_run`, `test_run_step`, `test_case`.

**Sự kiện.** EVT-04-10.

**Lỗi và xử lý.** ERR-04-009, 019 (429 hoặc 503), 021, 030; sandbox không nhận sau 60 giây: `FAILED`.

**Quan sát.** p95 `MOCK` ≤ 5 s.
:::

1. `TestRunService.start` kiểm mức `DESIGN` (ERR-04-009), hạn mức tenant (`04.test.max-concurrent`, đếm bằng `ZCARD dh:int:testrun:active:{tenant}`), ghi `test_run` `QUEUED` với `definition_hash`, đưa việc vào hàng đợi Valkey Stream `dh:int:testrun:queue` (nhóm tiêu thụ theo hồ sơ).
2. Pod sandbox nhận việc, gọi `GET /internal/v1/testruns/{id}/bundle` của `dh-integration` (mTLS, tài khoản dịch vụ) lấy YAML chuẩn hóa, `*.jq`, bản tin, ca, cấu hình mô phỏng, giá trị kết nối TEST (chỉ với `SANDBOX_LIVE`).
3. Sandbox biến đổi cây trước khi nạp:
   - điểm vào (`from`) thay bằng `direct:dh-test-entry`;
   - ở `MOCK`: mọi endpoint ra ngoài (`http`, `kafka`, `sql`, `ftp`, Kamelet `sink`, `dh-deliver-action`) thay bằng `mock:` có trả lời theo `samples[nodeId].response` hoặc 200 rỗng; `dh-authz-action` dùng OPA sandbox với chính sách cho phép trừ khi ca kiểm thử đặt `authz: deny`;
   - `fromNodeId`: các chặng trước đánh dấu `SKIPPED`, bản tin đặt tại chặng đó.
4. `StepTracer` (Camel `Tracer` tùy biến, `BacklogTracer` tắt) phát sự kiện mỗi chặng: `nodeId`, `status`, `startOffsetMs`, `durationMs`, tiêu đề đã lọc, thân đã che (≤ 64 KiB mỗi lần, cắt có đánh dấu); gửi về `POST /internal/v1/testruns/{id}/steps` theo lô 200 ms.
5. Hết luồng hoặc hết thời hạn: chạy khẳng định (§8.3), gửi kết quả cuối; thân đầy đủ (khi `captureBodies`) ghi `s3://dh-int-testrun/{tenant}/{runId}/{nodeId}-{in|out}.json` có khóa mã hóa phía máy chủ, vòng đời xóa sau `04.test.body-retention-days`.
6. `dh-integration` ghi `test_run_step`, cập nhật trạng thái, đẩy SSE (API-04-042: sự kiện `step`, `status`, `completed`), phát EVT-04-10.

```{.mermaid caption="Trình tự một lần chạy thử ở chế độ MOCK"}
sequenceDiagram
    autonumber
    actor IE as Kỹ sư tích hợp
    participant UI as Trình thiết kế
    participant TRS as TestRunService
    participant VK as Valkey Stream
    participant SB as dh-runtime-sandbox
    participant S3 as Ceph RGW
    IE->>UI: Bấm Chạy thử với bản tin mẫu
    UI->>TRS: POST test-runs, mode MOCK
    TRS->>TRS: Kiểm DESIGN, hạn mức tenant
    TRS->>VK: Ghi test_run QUEUED, đưa việc vào hàng đợi
    TRS-->>UI: 202 với runId, mở SSE
    SB->>VK: Nhận việc theo hồ sơ
    SB->>TRS: GET bundle qua mTLS
    SB->>SB: Thay from, endpoint ra bằng mock, nạp CamelContext riêng
    loop Mỗi chặng
        SB->>TRS: POST steps theo lô 200 ms, thân đã che
        TRS-->>UI: SSE step
    end
    SB->>SB: Chạy khẳng định
    SB->>S3: Ghi thân đầy đủ khi captureBodies
    SB->>TRS: Kết quả cuối PASSED hoặc FAILED
    TRS-->>UI: SSE completed, phát EVT-04-10
```

Hình cho thấy sandbox tự kéo việc và gói chạy nên chỉ cần quyền gọi hai API nội bộ; vết về theo lô, đã che trước khi rời sandbox.

Che dữ liệu ở bước 4 dùng phân loại trường của lược đồ (PH-09) và bộ phát hiện §7.3; khi không có lược đồ, mọi giá trị chuỗi khớp mẫu số định danh, điện thoại, email bị che.

### 8.3. Khẳng định

Khẳng định là điều kiện kiểm chứng được trên kết quả lần chạy. `AssertionEvaluator` của sandbox đánh giá chúng sau khi luồng kết thúc; kết quả từng khẳng định đi kèm kết quả cuối.

| Loại | Đánh giá |
|---|---|
| `STATUS` | Mã HTTP cuối (luồng đồng bộ) |
| `BODY_JQ` | Biểu thức JQ trên thân cuối trả `true` |
| `HEADER` | Tiêu đề cuối bằng hoặc khớp mẫu |
| `STEP_VISITED`, `STEP_NOT_VISITED` | Theo vết |
| `ENDPOINT_CALLED` | Số lần gọi `mock:` của nút ≥ n (hoặc = n) |
| `DURATION_LT` | Tổng thời lượng < ms |
| `ERROR_CODE` | `dh-dlq-error-code` hoặc mã ERR trong phản hồi |
| `DLQ_SENT` | Có bản tin vào `mock:` thay cho DLQ |

: Loại khẳng định của ca kiểm thử

Một lần chạy `PASSED` khi mọi khẳng định đạt và không có ngoại lệ không xử lý. Lần chạy mô phỏng phía trình duyệt (`04.test.allow-simulation`) ghi `SIMULATED` và không bao giờ thỏa BR-04-004 (ADR-064).

### 8.4. Điều kiện gửi duyệt

```sql
-- BR-04-004: đúng băm hiện tại, không mô phỏng, mọi ca đạt
SELECT bool_and(ok) FROM (
  SELECT EXISTS (SELECT 1 FROM ph04.test_run r
                 WHERE r.flow_version_id = :v AND r.definition_hash = :hash
                   AND r.status = 'PASSED' AND r.mode <> 'SIMULATED') AS ok
  UNION ALL
  SELECT EXISTS (SELECT 1 FROM ph04.test_run r
                 WHERE r.flow_version_id = :v AND r.definition_hash = :hash
                   AND r.test_case_id = c.test_case_id AND r.status = 'PASSED')
  FROM ph04.test_case c WHERE c.flow_id = :flow AND c.active
) t;
```

Lần chạy theo ca cũng tính là "một lần chạy đạt" (điều kiện thứ nhất không lọc `test_case_id`). Lần chạy `SIMULATED` có `status = 'SIMULATED'` nên tự loại; điều kiện `mode` là lớp phòng thủ thêm. Tham số `04.review.require-test = false` (chỉ áp cho luồng nội bộ) bỏ điều kiện thứ nhất.

## 9. Máy trạng thái

Mọi chuyển trạng thái hiện thực bằng một lớp `Transitions` có bảng tường minh; chuyển không có trong bảng ném `IllegalTransition` → ERR-04-005. Cập nhật trạng thái luôn kèm điều kiện trạng thái cũ trong câu `UPDATE` để hai yêu cầu đồng thời không cùng thắng.

### 9.1. Phiên bản

Bảng dưới là máy trạng thái phiên bản, hiện thực trong `VersionService` và `ReviewService`. Sơ đồ trình tự sau bảng cho thấy luồng gửi duyệt và duyệt bốn mắt.

| Từ | Sự kiện | Tới | Điều kiện chốt ở máy chủ | Quyền |
|---|---|---|---|---|
| — | Tạo luồng, tạo phiên bản mới | `DRAFT` | Không có phiên bản mở khác (BR-04-016, ERR-04-016) | create, update |
| `DRAFT`, `CHANGES_REQUESTED` | Lưu nháp | (giữ) | `If-Match` khớp | update |
| `DRAFT`, `CHANGES_REQUESTED` | Gửi duyệt | `PENDING_REVIEW` | VR mức `SUBMIT` không `ERROR`; BR-04-004; ghi chú; `catalogVersion` hiện hành (VR-17) | submit |
| `PENDING_REVIEW` | Rút lại | `DRAFT` | Người gửi hoặc TA; lý do | submit |
| `PENDING_REVIEW` | `REQUEST_CHANGES` | `CHANGES_REQUESTED` | Bốn mắt; ý kiến | publish |
| `PENDING_REVIEW` | `APPROVE` | `APPROVED` | Bốn mắt; checklist; băm bằng `submitted_hash`; xác thực lại khi bật | publish |
| `DRAFT`, `CHANGES_REQUESTED` | Hủy | `DISCARDED` | Người tạo, người đóng góp hoặc TA | update |
| `APPROVED` | Phiên bản khác lên PROD `SYNCED` | `SUPERSEDED` | Tự động | — |
| `APPROVED` | Bị quay lui khỏi PROD | `ROLLED_BACK` | Tự động | — |
| `SUPERSEDED` | Quay lui về phiên bản này | `APPROVED` | Tự động khi đích quay lui | — |

: Bảng chuyển trạng thái phiên bản

```{.mermaid caption="Trình tự gửi duyệt và duyệt bốn mắt một phiên bản"}
sequenceDiagram
    autonumber
    actor IE as Người soạn u.ie01
    actor IA as Người duyệt u.ia01
    participant RS as ReviewService
    participant VE as ValidationEngine
    participant DB as pg-core ph04
    IE->>RS: POST submit với ghi chú
    RS->>VE: Kiểm mức SUBMIT
    RS->>DB: Có lần chạy đạt trên contentHash, mọi ca đạt
    RS->>DB: PENDING_REVIEW, submitted_hash, outbox EVT-04-03
    RS-->>IE: 200
    IA->>RS: Mở so sánh, POST review APPROVE với checklist
    RS->>RS: FourEyesGuard loại người tạo, người đóng góp, người gửi
    RS->>DB: So băm hiện tại với submitted_hash
    RS->>DB: UPDATE where status = PENDING_REVIEW, ghi review, outbox EVT-04-04
    RS-->>IA: 200, phiên bản APPROVED
```

Hình cho thấy ba chốt ở máy chủ: lần chạy đạt gắn đúng băm, người duyệt ngoài tập người đã chạm phiên bản, băm lúc duyệt bằng băm lúc gửi.

`FourEyesGuard`: người quyết định ∉ {`created_by`} ∪ `flow_version_contributor` ∪ {`submitted_by`} (GAP-04-06). Người đóng góp được thêm khi lưu nháp thành công, khi nhập YAML, khi gộp xung đột. Hiện thực ở máy chủ, không dựa vào giao diện ẩn nút.

### 9.2. Luồng

Trạng thái luồng là trạng thái tổng hợp, tính lại sau mỗi sự kiện phiên bản, triển khai, lệnh:

| Trạng thái | Điều kiện |
|---|---|
| `DRAFT` | Chưa có phiên bản nào từng `APPROVED` |
| `IN_REVIEW` | Có phiên bản `PENDING_REVIEW` và chưa có triển khai PROD |
| `APPROVED` | Có phiên bản `APPROVED` nhưng chưa có triển khai PROD `SYNCED` |
| `ACTIVE` | Triển khai PROD `SYNCED`, `desiredState = RUNNING`, sức khỏe `HEALTHY` |
| `DEGRADED` | Triển khai PROD `SYNCED` nhưng sức khỏe `DEGRADED` hoặc `DOWN`, hoặc `OUT_OF_SYNC` |
| `PAUSED` | `desiredState = PAUSED` ở PROD (cờ `emergency` nếu do dừng khẩn) |
| `RETIRED` | Đã gỡ; trạng thái cuối |

: Trạng thái tổng hợp của luồng

### 9.3. Triển khai

```{.mermaid caption="Máy trạng thái triển khai"}
stateDiagram-v2
    [*] --> PENDING: release, promote, rollback
    PENDING --> SYNCING: Argo CD Progressing
    PENDING --> FAILED: Ghi Git lỗi sau 3 lần (ERR-04-022)
    SYNCING --> SYNCED: Đủ bản sao báo version + contentHash
    SYNCING --> OUT_OF_SYNC: Quá sync-timeout
    SYNCING --> FAILED: loadError hoặc quá deploy.timeout
    OUT_OF_SYNC --> SYNCED: Đủ bản sao về sau
    SYNCED --> OUT_OF_SYNC: Nhịp tim lệch Git
    SYNCED --> [*]: Bị thay bởi triển khai mới
```

Hình cho thấy `SYNCED` có thể quay về `OUT_OF_SYNC` khi nhịp tim lệch Git; `FAILED` chỉ đến từ `PENDING` hoặc `SYNCING`.

Sức khỏe tính mỗi nhịp tim, độc lập trạng thái đồng bộ: `HEALTHY` khi mọi bản sao có route `Started` và tỷ lệ lỗi 5 phút < 5%; `DEGRADED` khi một phần bản sao lỗi, route `Suspended` ngoài chủ đích, hoặc tỷ lệ lỗi 5–50%; `DOWN` khi không bản sao nào chạy hoặc tỷ lệ lỗi > 50%; `UNKNOWN` khi quá 90 giây không có nhịp tim.

### 9.4. Lần chạy thử và lệnh điều khiển

| Lần chạy thử | Tới |
|---|---|
| `QUEUED` | `RUNNING` (sandbox nhận), `CANCELLED` (người dùng hủy), `FAILED` (sandbox không nhận sau 60 giây) |
| `RUNNING` | `PASSED`, `FAILED`, `TIMED_OUT`, `CANCELLED` |
| (trình duyệt) | `SIMULATED` ghi trực tiếp, trạng thái cuối |

: Chuyển trạng thái lần chạy thử

| Lệnh | Tới |
|---|---|
| `ISSUED` | `DELIVERED` (có xác nhận đầu tiên), `REJECTED` (mọi bản sao từ chối) |
| `DELIVERED` | `ACKNOWLEDGED` (đủ bản sao), `PARTIAL` (sau 30 giây chưa đủ), `REJECTED` |
| `ACKNOWLEDGED`, `PARTIAL` | `RECONCILED` (Git và nhịp tim khớp trạng thái mong muốn) |

: Chuyển trạng thái lệnh điều khiển

## 10. Điều khiển runtime

Chương này mô tả tạm dừng, tiếp tục, dừng khẩn mà vẫn giữ Git là nguồn sự thật: lệnh có ký đi nhanh qua Kafka, trạng thái mong muốn ghi Git, bộ đối soát bảo đảm hai bên hội tụ.

### 10.1. Định dạng lệnh

::: dac-ta
**Mục đích.** Ký và gửi lệnh `PAUSE`, `RESUME`, `EMERGENCY_STOP` trong vài giây, không giả được, hạn ngắn.

**Lớp chính.** `CommandService`, `CommandSigner` (JCS, `transit/sign`).

**Đơn vị chạy.** `dh-integration` gói `internal.runtime`.

**FR hiện thực.** FR-04-050; BR-04-018.

**Giao diện vào.** API-04-061.

**Phụ thuộc ra.** OpenBao `transit/keys/dh-integration-cmd`; Kafka; `GitConfigRepository`.

**Dữ liệu.** `runtime_command`, `deployment.desired_state`.

**Sự kiện.** EVT-04-11 (không qua outbox).

**Lỗi và xử lý.** ERR-04-005, 025, 024 (`REJECTED`, `PARTIAL`); Kafka lỗi: thử lại 5 giây, lệnh khẩn báo SO ngay.

**Quan sát.** `dh_int_command_ack_seconds{action}` (NFR-04-010).
:::

```json
{
  "commandId": "0193a8e2-6b1f-7c3e-9a51-6f0f2c1d9e44",
  "tenant": "T68",
  "flow": "ho-tich-khai-sinh",
  "version": 8,
  "environment": "PROD",
  "action": "PAUSE",
  "scope": { "type": "ROUTES", "routeIds": ["goi-ndxp"] },
  "drain": true,
  "issuedBy": "u.to01",
  "issuedAt": "2026-11-25T22:00:04+07:00",
  "expiresAt": "2026-11-25T22:01:04+07:00",
  "keyId": "dh-integration-cmd-2026q4",
  "sig": "base64url(Ed25519(JCS(payload không có sig)))"
}
```

Chữ ký tính trên dạng chuẩn JSON Canonicalization Scheme (RFC 8785) của toàn bộ trường trừ `sig`. Khóa riêng nằm ở OpenBao transit (`transit/keys/dh-integration-cmd`, loại `ed25519`, không xuất được); `CommandSigner` gọi `transit/sign`. Runtime nhận khóa công khai qua ConfigMap `dh-runtime-trust` (gồm khóa hiện hành và khóa kế tiếp khi xoay vòng 90 ngày). Lý do lệnh không nằm trong thông điệp (chỉ ở CSDL và kiểm toán) để topic hệ thống không chứa văn bản tự do.

### 10.2. Gửi, xác nhận, đối soát

::: dac-ta
**Mục đích.** Thi hành lệnh có ký ở mọi bản sao, xác nhận về, giữ dừng khẩn trước commit cũ.

**Lớp chính.** `CommandListener`, `CommandVerifier`, `HeartbeatPublisher`.

**Đơn vị chạy.** `dh-runtime`; gói `vn.datahub.runtime.control`.

**FR hiện thực.** FR-04-050, 051.

**Giao diện vào.** Kafka EVT-04-11; ConfigMap `dh-runtime-trust`.

**Phụ thuộc ra.** Kafka; `RouteController`; DLQ khi dừng khẩn.

**Dữ liệu.** Tập `commandId` 10 phút; trạng thái ghi đè cục bộ.

**Sự kiện.** EVT-04-12, 13.

**Lỗi và xử lý.** `REJECTED` với `EXPIRED`, `BAD_SIGNATURE` (cảnh báo ATTT), `TENANT_MISMATCH`, `UNKNOWN_FLOW`; lệnh trùng bị bỏ.

**Quan sát.** Nội dung nhịp tim (§5.4).
:::

| Bước | Lệnh thường (`PAUSE`, `RESUME`) | Lệnh khẩn (`EMERGENCY_STOP`) |
|---|---|---|
| 1 | Ghi `runtime_command` `ISSUED` + cập nhật `deployment.desired_state` trong một giao dịch | Ký, gửi Kafka ngay |
| 2 | Ký, gửi Kafka (khóa phân vùng `tenant/flow`) | Ghi `runtime_command` `ISSUED` |
| 3 | Ghi `flow.dh.yaml` (`desiredState`, `pausedRoutes`) vào Git | Ghi Git (tác vụ nền, thử lại) |
| 4 | Runtime kiểm chữ ký, hạn, tenant (nhãn ConfigMap); thi hành; phát EVT-04-13 | Như trái, không xả bản tin; bản tin đang xử lý → DLQ "dừng khẩn" |
| 5 | `Reconciler` gom xác nhận theo `commandId`; đủ bản sao (theo nhịp tim gần nhất) → `ACKNOWLEDGED`; 30 giây chưa đủ → `PARTIAL` | Như trái |
| 6 | Khi commit Git đã đồng bộ và nhịp tim khớp → `RECONCILED`, phát EVT-04-08 | Như trái; quá 5 phút chưa khớp → cảnh báo TA, SO (BR-04-018) |

: Các bước gửi, xác nhận, đối soát lệnh

Runtime giữ tập `commandId` đã thi hành 10 phút để bỏ lệnh trùng. Lệnh hết hạn hoặc sai chữ ký trả xác nhận `REJECTED` với `reason` (`EXPIRED`, `BAD_SIGNATURE`, `TENANT_MISMATCH`, `UNKNOWN_FLOW`); `BAD_SIGNATURE` sinh cảnh báo ATTT.

```{.mermaid caption="Trình tự dừng khẩn một luồng ở PROD"}
sequenceDiagram
    autonumber
    actor SO as Cán bộ ATTT u.so01
    participant CS as CommandService
    participant BAO as OpenBao transit
    participant K as Kafka
    participant RT as dh-runtime các bản sao
    participant REC as Reconciler
    participant GIT as Kho dh-flows-t68
    SO->>CS: POST runtime/commands EMERGENCY_STOP với lý do
    CS->>BAO: transit/sign trên JCS của lệnh
    CS->>K: Gửi EVT-04-11 ngay, acks=all
    CS->>CS: Ghi runtime_command ISSUED
    CS-->>SO: 202 với commandId
    K->>RT: Lệnh tới mọi bản sao
    RT->>RT: Kiểm chữ ký, hạn, tenant, dừng route, bản tin dở vào DLQ
    RT->>K: EVT-04-13 xác nhận từng bản sao
    K->>REC: Gom xác nhận, ACKNOWLEDGED
    CS->>GIT: Tác vụ nền ghi desiredState PAUSED
    GIT-->>RT: Argo CD áp ConfigMap mới
    RT->>K: Nhịp tim khớp trạng thái mong muốn
    K->>REC: RECONCILED, phát EVT-04-08
```

Hình cho thấy lệnh khẩn gửi Kafka trước, ghi CSDL và Git sau, nên thời gian dừng không phụ thuộc Git; runtime giữ trạng thái ghi đè tới khi Git bắt kịp.

Khi Argo CD đồng bộ một commit cũ hơn lệnh khẩn chưa được ghi Git (ví dụ Git lỗi), `FlowLoader` không bật lại route: nó giữ "trạng thái ghi đè cục bộ" theo lệnh khẩn đã thi hành cho tới khi thấy `flow.dh.yaml` có `desiredState` tương ứng hoặc nhận lệnh `RESUME` có ký mới hơn. Đây là điểm bảo đảm dừng khẩn không bị GitOps vô hiệu.

### 10.3. Đối soát định kỳ

::: dac-ta
**Mục đích.** Tính đồng bộ, sức khỏe từ nhịp tim, gom xác nhận lệnh, phát hiện lệch Git và băm lạ.

**Lớp chính.** `Reconciler` (ShedLock, 60 giây), `HeartbeatProjector`, `HealthCalculator`, `CommandAckAggregator`.

**Đơn vị chạy.** `dh-integration` gói `internal.runtime`.

**FR hiện thực.** FR-04-051, 052; BR-04-012, 018.

**Giao diện vào.** Kafka EVT-04-12, 13; Argo CD; API-04-060, 062.

**Phụ thuộc ra.** PH-13 (cảnh báo); `FlowService`.

**Dữ liệu.** `heartbeat_latest`, `command_ack`, `runtime_command`, `deployment`, `shedlock`.

**Sự kiện.** EVT-04-07, 08.

**Lỗi và xử lý.** Lệch quá 5 phút: `OUT_OF_SYNC`, cảnh báo; băm lạ: cảnh báo ATTT cao; 90 giây không nhịp tim: `UNKNOWN`.

**Quan sát.** `dh_int_reconcile_drift`, `dh_int_unknown_hash_total`.
:::

`Reconciler` chạy mỗi 60 giây theo tenant (ShedLock): so `deployment` (mong muốn theo Git đã ghi) với `heartbeat_latest` (thực tế). Lệch quá 5 phút: phát `DeploymentStatusChanged(OUT_OF_SYNC)`, cảnh báo PH-13 `dh_int_reconcile_drift`. Lệch do bản sao chạy phiên bản lạ (băm không có trong CSDL): cảnh báo ATTT mức cao, vì có thể có kênh nạp ngoài GitOps (vi phạm BR-04-012).

## 11. Bảo mật

Chương này gom biện pháp an toàn của chương 4 tới 10 cho ATTT thẩm định; dẫn `SEC-*` của D03-07, không tạo mã mới.

### 11.1. Phân quyền

Hai lớp quyết định cho mỗi API:

1. **Quyền chức năng** `PERM-04-*` từ token Keycloak (vai trò ánh xạ theo D02-08), kiểm bằng `@PreAuthorize("hasAuthority('PERM-04-submit')")`.
2. **Phạm vi không gian làm việc** khi `04.workspace.enforce` bật: `WorkspaceAccess.require(user, workspace, level)` với `level` theo thao tác (`VIEW` đọc, `EDIT` sửa, chạy thử, gửi; `MAINTAIN` quản lý thành viên). Duyệt yêu cầu `PERM-04-publish` và mức ≥ `VIEW` trên không gian. TA, PA bỏ qua kiểm tra phạm vi (BR-04-021).

Truy vấn danh sách lọc theo phạm vi ở SQL (`flow.workspace_id = ANY(:allowed)`) chứ không lọc sau khi đọc. Không tồn tại và không có quyền trả cùng ERR-04-001.

OPA chỉ dùng ở data plane (`dh-authz-action`) và cho quyết định có chính sách phức tạp ở control plane (xem giá trị trước, sau của kiểm toán theo vai trò AU, SO, TA).

### 11.2. Các mối đe dọa chính

| Đe dọa | Biện pháp |
|---|---|
| Kỹ sư đưa mã tùy ý vào runtime | Cấm `exec`, kịch bản, `bean` ngoài danh sách lớp (VR-04, 19); bốn mắt; ảnh runtime không chứa trình biên dịch Groovy, JS |
| Nạp luồng ngoài GitOps | Chữ ký tách rời từng tệp trong kho, `FlowLoader` kiểm chữ ký; đối soát băm lạ (§10.3) |
| Giả lệnh điều khiển | Ed25519, hết hạn 60 giây, chỉ `dh-integration` có ACL ghi topic |
| Lộ bí mật qua định nghĩa, bản tin mẫu | VR-03, LINT-04-06, `SecretDetector` trên ca kiểm thử; bí mật chỉ ở OpenBao |
| SSRF qua chạy thử | Chính sách mạng sandbox, egress gateway theo FQDN của kết nối TEST |
| Đọc lệch tenant ở CSDL | RLS + `SET LOCAL app.tenant_id` từ thuộc tính khóa; tài khoản theo luồng |
| Lệch tenant trong bản tin | `TenantGuard`; tenant không bao giờ lấy từ thân |
| Gói XML hệ cũ chứa mật khẩu | `LegacyXmlImporter` gỡ trước khi lưu, không ghi log giá trị; tệp tải lên xóa sau khi chuyển |
| Tấn công phân tích YAML, XML | Giới hạn độ sâu, bí danh, kích thước; XML tắt DTD, thực thể ngoài |

: Mối đe dọa chính và biện pháp

### 11.3. Cách ly tenant ở control plane

Mọi bảng `ph04.*` có `tenant_id` và RLS (D03-03-PH04). Tác vụ nền liên tenant (`Reconciler`, `TestRunRetentionJob`, `CatalogUpgradeJob`) lặp từng tenant theo danh sách PH-20 và `runAs(tenant)`, theo mẫu D03-02-PH07 §6.3. Bảng `heartbeat_latest` được `HeartbeatProjector` ghi theo tenant trong từng nhịp tim (một nhịp tim có nhiều tenant được tách thành nhiều giao dịch).

## 12. Xử lý lỗi, thử lại và nhất quán

Bảng dưới tập hợp xử lý lỗi xuyên thành phần ở control plane (lỗi trong luồng theo §4.3): ghi có khóa lũy đẳng, qua ranh giới hệ thống thì thử lại giới hạn rồi chuyển trạng thái rõ ràng.

| Tình huống | Cách xử lý |
|---|---|
| Lưu nháp đồng thời | ETag, ERR-04-006, gộp ba bên (§6.5) |
| Tạo, phát hành, chạy thử gửi lại | `Idempotency-Key` lưu Valkey 24 giờ: cùng khóa cùng băm thân trả kết quả cũ; khác thân ERR-04-018 |
| Ghi Git lỗi | Triển khai `PENDING` giữ, thử lại 3 lần; vẫn lỗi thì `FAILED`, ERR-04-022, không có trạng thái nửa vời ở Git (commit nguyên tử) |
| Argo CD không đồng bộ | `OUT_OF_SYNC` sau `04.runtime.sync-timeout-seconds`; `FAILED` sau `04.deploy.timeout-minutes` |
| Kafka không ghi được lệnh | `CommandService` thử lại 5 giây; lệnh khẩn báo lỗi ngay cho SO kèm hướng dẫn chặn ở APISIX (D03-07) |
| Sandbox chết giữa chừng | Việc trong Valkey Stream không được `XACK` sẽ được nhận lại sau 60 giây; lần chạy quá 2 × thời hạn thì `FAILED` "Sandbox mất kết nối" |
| PH-13 không nhận kiểm toán | Giữ ở outbox; Debezium gửi lại |
| PH-05, PH-10 chưa có dữ liệu | VR-07, VR-10 lỗi ở `SUBMIT` (FRS §10.1) |
| Ánh xạ lỗi | `ProblemDetail` RFC 9457: `type` = `https://datahub.gov.vn/errors/ERR-04-xxx`, `title`, `status`, `detail`, `code`, `traceId`, trường mở rộng theo mã (D03-04-PH04 §6) |

: Xử lý lỗi và nhất quán ở control plane

## 13. Cấu hình, quan sát, dung lượng

Chương này liệt kê khóa cấu hình, chỉ số control plane và ước tính dung lượng cho D03-09; chỉ số runtime ở §4.5.

### 13.1. Cấu hình ứng dụng

::: dac-ta
**Mục đích.** Đọc tham số `04.*` của tenant nhất quán và chặn thay đổi trong khoảng đóng băng.

**Lớp chính.** `FlowParams`, `FreezeWindowGuard`.

**Đơn vị chạy.** `dh-integration` gói `internal.params`.

**FR hiện thực.** FR-04-084; BR-04-022.

**Giao diện vào.** API-04-090; `ReleaseService`, `CommandService`, `TestRunService`.

**Phụ thuộc ra.** PH-18.

**Dữ liệu.** Đệm 60 giây; biến `{{dh.env.*}}`.

**Sự kiện.** Không phát.

**Lỗi và xử lý.** ERR-04-041 (423), trừ quay lui, tạm dừng; PH-18 vắng: dùng giá trị đệm.

**Quan sát.** Số lần chặn do đóng băng.
:::

Bảng dưới là khóa cấu hình kỹ thuật của `dh-integration`; tham số nghiệp vụ theo tenant do `FlowParams` đọc được nói ở đoạn sau bảng.

| Khóa (`dh-integration`) | Mặc định | Ý nghĩa |
|---|---|---|
| `dh.flow.git.base-url` | (theo môi trường) | Gốc kho cấu hình (GitHub khi phát triển, GitLab on-prem khi bàn giao, Q353) |
| `dh.flow.git.repo-pattern` | `dh-flows-{tenant}` | Tên kho |
| `dh.flow.git.cache-dir` | `/var/cache/dh-flows` | Bộ đệm clone nông |
| `dh.flow.git.signing-key` | `transit/dh-integration-git` | Khóa ký commit, tệp |
| `dh.flow.command.signing-key` | `transit/dh-integration-cmd` | Khóa ký lệnh |
| `dh.flow.command.ttl-seconds` | 60 | Hạn lệnh |
| `dh.flow.command.partial-after-seconds` | 30 | Mốc `PARTIAL` |
| `dh.flow.reconcile.drift-alert-minutes` | 5 | BR-04-018 |
| `dh.flow.heartbeat.unknown-after-seconds` | 90 | Sức khỏe `UNKNOWN` |
| `dh.flow.sandbox.queue` | `dh:int:testrun:queue` | Hàng đợi chạy thử |
| `dh.flow.catalog.dir` | `classpath:catalog/` | Catalog sinh cùng ảnh |

: Khóa cấu hình của `dh-integration`

Tham số nghiệp vụ theo tenant đọc từ PH-18 (`04.*`, FRS §7.1) qua `FlowParams`, đệm 60 giây, làm mới theo sự kiện thay đổi tham số của PH-18 (đề xuất mã ở D02-04-PH04 §8.2; SDD chọn dùng sự kiện tham số chung của PH-18 thay vì EVT-04 riêng).

### 13.2. Quan sát control plane

| Chỉ số | Ý nghĩa | Cảnh báo |
|---|---|---|
| `dh_int_validation_seconds{level}` | Thời gian kiểm tra | p95 `SUBMIT` > 2 s trong 15 phút |
| `dh_int_testrun_queue_depth{profile}` | Độ dài hàng đợi chạy thử | > 20 trong 10 phút |
| `dh_int_testrun_duration_seconds{mode,outcome}` | Thời gian chạy thử | p95 `MOCK` > 5 s |
| `dh_int_release_seconds{env}` | Từ phát hành tới `SYNCED` | p95 PROD > 3 phút (NFR-04-009) |
| `dh_int_command_ack_seconds{action}` | Từ lệnh tới đủ xác nhận | p95 > 10 s, khẩn > 5 s (NFR-04-010) |
| `dh_int_reconcile_drift{tenant}` | Số luồng lệch Git | > 0 trong 5 phút |
| `dh_int_git_write_failures_total` | Ghi Git lỗi | > 0 |
| `dh_int_unknown_hash_total` | Bản sao chạy băm lạ | > 0 (ATTT) |

: Chỉ số control plane và ngưỡng cảnh báo

### 13.3. Dung lượng ước tính

Giả định GĐ: tỉnh QM-VUA 120 luồng năm đầu, 300 năm thứ ba; 35 tenant. Mỗi phiên bản trung bình 40 KiB YAML + 20 KiB bố cục + 50 KiB bản tin mẫu; 12 phiên bản mỗi luồng mỗi năm → khoảng 0,5 GiB mỗi năm toàn nền tảng cho `flow_version`. Lần chạy thử 30 mỗi phiên bản, vết 20 bước × 2 KiB → khoảng 15 GiB mỗi năm `test_run_step`, giữ 90 ngày (`04.test.retention-days`) nên ổn định quanh 4 GiB. Nhịp tim: 35 tenant × 300 luồng × 3 bản sao mỗi 30 giây, chỉ giữ bản mới nhất (`heartbeat_latest`); lịch sử nằm ở Prometheus.

## 14. Kiểm thử

Kiểm thử đi từ đơn vị tới đầu cuối; cổng ghi "chặn" là điều kiện bắt buộc để gộp mã.

| Mức | Phạm vi | Công cụ | Cổng |
|---|---|---|---|
| Đơn vị | Quy tắc VR, `YamlCanonicalizer`, `SecretDetector`, `SqlPolicy`, máy trạng thái, `FourEyesGuard`, bộ sinh JQ | JUnit 5, Vitest | CI-2, CI-6 |
| Quay vòng YAML | Ngữ liệu §6.2 | Vitest + JUnit | CI-2, CI-6, chặn |
| Hai bộ sinh JQ khớp nhau | Ngữ liệu `*.dhmap.json` | Vitest + JUnit | CI-2, CI-6 |
| Catalog khớp runtime | `catalog:check`, `catalog-diff` | Node | CI-6 (job console) |
| Modulith | `ApplicationModules.verify()` | JUnit | CI-2 |
| Tích hợp control plane | API với PostgreSQL, Valkey, Kafka, Gitea (giả kho) | Testcontainers | CI-3 |
| Cách ly tenant | `TenantIsolationIT` cho mọi bảng `ph04`, lấy 23 khối của `ph04/test/ph04_isolation_test.sql` (D03-03-PH04 §4.2) làm ca tối thiểu | Testcontainers | CI-3, chặn |
| Runtime | Kamelet nền, `TenantGuard`, `dh-default-config`, `dh_map` | `@QuarkusTest`, Camel test | CI-3 |
| Native | Ảnh `core-native` chạy bộ luồng mẫu | Quarkus native IT | CI-8 |
| Đầu cuối | Thiết kế → chạy thử → duyệt → phát hành TEST → gọi qua APISIX | Playwright + kind cluster + Argo CD | CI-9 |
| Hiệu năng | NFR-04-001…013 | k6, Lighthouse, Gatling | Trước RG-2 |
| Hợp đồng API | OpenAPI, AsyncAPI của D03-04-PH04 | Spectral, oasdiff, schemathesis | CI-5 |

: Mức kiểm thử, công cụ và cổng CI

Ca kiểm thử chi tiết ở D05-02-PH04.

## 15. Lộ trình hiện thực và MVP

Thứ tự đóng khoảng lệch, mỗi bước là một hoặc vài PR nhỏ có kiểm thử:

| Bước | Nội dung | GAP | Phụ thuộc |
|---|---|---|---|
| 1 | Đổi gói `vn.datahub`, tách module `flow`, DDL mới có `tenant_id`, RLS, di trú dữ liệu bảng cũ | 07, 13 | D03-03-PH04 |
| 2 | Máy trạng thái phiên bản mới, bốn mắt đầy đủ, băm, người đóng góp; chặn phát hành `DRAFT` | 05, 06 | Bước 1 |
| 3 | `ValidationEngine` theo cây, nhận diện chặng bằng `dh-stage-*` | 08 | Catalog PR #5 |
| 4 | Thư viện nền và Kamelet nền; viết lại `TraCuuRoute`, `StandardPipelineRoute`, `CdmMapRoute` bằng YAML; `dh-default-config` | 02, 12 | Không |
| 5 | Kho `dh-flows-{tenant}`, `GitConfigRepository`, ApplicationSet, `FlowLoader`, nhịp tim | 03 | Argo CD (ADR-009) |
| 6 | Sandbox chạy thử thật, bỏ `testRun` mô phỏng | 04, 09 | Bước 4 |
| 7 | Kênh lệnh có ký, `Reconciler` | 11 | Bước 5 |
| 8 | `dh-sql-ro-*`, tài khoản theo luồng | 10 | PH-05 loại kết nối mới |
| 9 | Trình thiết kế theo D03-06-PH04 (mô hình cây, gộp ba bên, bảng thành phần nhóm nghiệp vụ, Inspector) | Không | Bước 2, 3 |
| 10 | Chuyển XML Bus cũ | Không | Bước 4 |

: Thứ tự hiện thực và khoảng lệch được đóng

MVP (FRS §9.3) gồm bước 1–7 và 9 với hồ sơ `core-native`, `files-native`; `soap-jvm`, `legacy-jvm`, Kamelet tự viết, Pipe và bước 8 cho hệ ngoài PostgreSQL đi đợt sau.

## 16. Câu hỏi mở

Các câu hỏi dưới đây đã có đề xuất tạm nên không chặn việc viết mã.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q04-20 | Namespace của sandbox: `dh-sandbox` riêng hay trong `dh-runtime` với nhãn? | `dh-sandbox` riêng, vùng Z4, chính sách mạng riêng; đề nghị bổ sung D03-09 |
| Q04-21 | Có cần `STAGING` ở tỉnh thí điểm? | Không (mặc định `TEST,PROD`) |
| Q04-22 | Nhánh `env/prod` bảo vệ bằng yêu cầu gộp có làm chậm quá NFR-04-009 (3 phút)? | Đo ở môi trường thử; nếu vượt thì CI kho cấu hình chỉ chạy VR, ca kiểm thử chạy song song sau gộp |
| Q04-23 | Valkey 8 `HEXPIRE` có trong bản Valkey của nền tảng? | Có từ Valkey 8.0; nếu không, mỗi người một khóa riêng TTL 120 giây |
| Q04-24 | Một pod runtime nạp tối đa bao nhiêu luồng trước khi phải tách hồ sơ, namespace? | 50 luồng (D03-10), đo lại với NFR-04-013 |
| Q04-25 | Có dùng `BacklogTracer` của Camel thay `StepTracer` tự viết? | Tự viết để kiểm soát che dữ liệu và kích thước |
| Q04-26 | Sandbox có dùng Kafka sandbox thật cho luồng bất đồng bộ ở `MOCK`? | Không; thay bằng `mock:`; `SANDBOX_LIVE` mới dùng Kafka TEST |
| Q04-27 | Ký từng tệp trong kho cấu hình có cần khi commit đã ký? | Có: `FlowLoader` kiểm được chữ ký mà không cần lịch sử Git |
| Q04-28 | Lưu `heartbeat_latest` ở PostgreSQL hay Valkey? | PostgreSQL (cần cho đối soát có RLS); Valkey nếu tải ghi vượt 200 dòng/giây |
| Q04-29 | Chọn Spring Data JDBC thay JPA cho PH-04 có lệch quy ước PH-07? | Chấp nhận: PH-04 không có aggregate cần lazy loading; giữ chung `TenantAwareTransactionManager` |

: Câu hỏi mở của SDD PH-04

### 16.1. Đề nghị đồng bộ

Các điểm dưới cần tập khác đối chiếu; tài liệu này không sửa chéo.

| Tập | Đề nghị | Trạng thái |
|---|---|---|
| D03-09 Hạ tầng | Bổ sung namespace `dh-sandbox` vùng Z4 và chính sách mạng riêng (Q04-20) | Chờ đợt đồng bộ cuối (tập ngoài PH-04) |
| D03-04-PH04 API | Đối chiếu tên API nội bộ `GET /internal/v1/testruns/{id}/bundle`, `POST …/steps` (chưa có mã API vì không công bố) | Đã hấp thụ (0.2): API §5 nêu đúng hai đường dẫn nội bộ; mã API và tệp OpenAPI nội bộ còn là đề nghị 4 của API §11 |
| D05-02-PH04 Ca kiểm thử | Mỗi sơ đồ trình tự mới (phát hành, chạy thử, duyệt bốn mắt, dừng khẩn) nên có ít nhất một ca đầu cuối tương ứng | Đã hấp thụ (0.2): TC-04-192 (chạy thử), 193 (duyệt bốn mắt), 196 (phát hành), 197 (dừng khẩn) |

: Đề nghị đồng bộ với tập khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 25/11/2026 | Bản đầu | Nhóm phân hệ PH-04 |
| 0.2 | 26/11/2026 | Áp K-TRINH-BAY, K-SDD: chương Giới thiệu, danh sách và bảng đặc tả 10 mục cho 28 thành phần, bốn sơ đồ trình tự, chú thích bảng và hình, đề nghị đồng bộ; giữ nguyên nội dung kỹ thuật bản 0.1 | Nhóm viết tài liệu (Claude) |
| 0.3 | 27/11/2026 | Đồng bộ chéo cuối: mức phân loại Hạn chế, dh-data-classes | Nhóm viết tài liệu (Claude) |
