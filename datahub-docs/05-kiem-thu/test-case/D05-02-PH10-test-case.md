---
ma_tai_lieu: D05-02-PH10
ten: Kịch bản và test case phân hệ PH-10 Sự kiện
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-10
---

# D05-02-PH10 · Kịch bản và test case Sự kiện

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-10 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH10 bản 0.2.
- Không mất chức năng nào của Hub Apache Pulsar hệ cũ: dashboard đếm publisher, subscriber, project, topic; sơ đồ kết nối; quản lý project, topic, publisher, subscriber, publication, subscription; danh mục `type_of_comm`, `routing_mode` (LGC-HUB-001…004, 007…014), nhóm Message Broker của Tooling (LGC-TOOL-010) và event message của Bus (LGC-BUS-039). Hai mục LGC-HUB-005, 006 (biểu đồ CPU, bộ nhớ) chuyển sang PH-13 và chỉ được kiểm ở mức có liên kết dẫn chiếu.
- Không có đường nào để một tỉnh đọc, phát hay nhận sự kiện của tỉnh khác, để một bên phát, bên nhận chưa được duyệt dùng được topic, hay để một sự kiện đã ghi bền bị mất mà không có dấu vết trong DLQ.

**Phạm vi.** Gồm <!--gen:so-ts-->0<!--/gen--> kịch bản với <!--gen:so-tc-->0<!--/gen--> test case và 10 kịch bản nghiệm thu người dùng (UAT-01…10). Mỗi FR mức M (66 FR) có ít nhất một ca dương và một ca âm; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph10/tools/gen_matrix.py`, kèm bảng `.xlsx` theo mẫu nghiệm thu và tệp Gherkin.

**Căn cứ.** Tài liệu cùng bộ PH-10 bản 0.2 (FRS D02-03-PH10, use case D02-04-PH10, SDD D03-02-PH10, CSDL D03-03-PH10, API D03-04-PH10, màn hình D03-06-PH10); ma trận phân quyền D02-08 (dòng `PERM-10-*` đã tách theo FRS §3.3); kế hoạch kiểm thử D05-01; cổng CI D04-02; ADR-070…073; cấu trúc theo ISO/IEC/IEEE 29119-3; yêu cầu ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP và TCVN 14423:2026.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- cô lập tenant ở API, CSDL (RLS), ACL Kafka theo tiền tố, Apicurio và OPA, với tenant kiểm thử T90…T99 (TS-10-30);
- ma trận `PERM-10-*` và bốn mắt không có đường vòng, kể cả với TA có cả quyền tạo và duyệt (TS-10-31);
- chữ ký HMAC webhook đúng, không bao giờ gửi không ký, bí mật ký không lộ ra ngoài OpenBao (TS-10-14, 32);
- giao ít nhất một lần: offset chỉ commit sau khi giao thành công hoặc đã ghi chắc DLQ, 0 sự kiện mất khi mất một broker (TS-10-15, 34);
- tương thích lược đồ `BACKWARD` ở Apicurio chặn phiên bản phá vỡ, và thay đổi phá vỡ chỉ đi bằng topic `.v{n+1}` (TS-10-07);
- phát lại và đặt lại offset luôn có lý do và người duyệt khác người đề nghị (TS-10-21).

Mã hiện có của `dh-integration` chưa có mô-đun `event`; các ca ở đây là tiêu chí nghiệm thu của công việc mới ở W3, W4 theo kế hoạch phát triển. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT, 2 triệu sự kiện nghiệp vụ mỗi ngày) vì chưa có dữ liệu thật.

## 0. Giới thiệu

Tài liệu là tập 7 của bộ PH-10. Người đọc chính là kiểm thử viên (viết, chạy ca), kỹ sư (viết ca tự động), cán bộ ATTT (TS-10-14, 30…32) và chủ đầu tư (UAT mục 7). Ca được viết để chạy ngay trên môi trường SIT với bộ dữ liệu mục 2, không phải hỏi lại. Tên trường, enum, trạng thái, quyền, tham số và mã màn lấy đúng Phụ lục A của FRS; chỗ tập này cần mà FRS chưa có được ghi ở mục 10.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

| Đối tượng | Thành phần | Ghi chú |
|---|---|---|
| Control plane | Mô-đun `event` trong `dh-integration` (Spring Boot 4, Spring Modulith, package `vn.datahub.integration.event`) | API `/api/event/v1`, outbox, inbox, bộ đối soát, bộ thu lag, bộ ghi DLQ |
| Cổng sự kiện | Mô-đun `event-gateway` của `dh-runtime` | API phát, API kéo, tra cứu lược đồ `/event/v1` (ADR-071) |
| Bộ giao nhận | Mô-đun `event-delivery` của `dh-runtime` (StatefulSet) | Webhook ký HMAC, thử lại, ngắt mạch, phát lại, cầu nối Pulsar |
| Data plane | Kafka Strimzi KRaft ba broker, listener `internal` (mTLS), `external` (SASL OAUTHBEARER, mTLS), `replication`; Apicurio Registry 3 | ACL theo tiền tố tenant (D03-10 §4) |
| Cấp phát | Kho `dh-config-{tenant}`, Argo CD, toán tử Strimzi, Kyverno (ADR-072) | `KafkaTopic`, `KafkaUser` |
| Quyền | Keycloak (scope `topic:{topicName}:*`), OPA bundle `event/grants/{tenant}.json`, APISIX | BR-10-020 |
| CSDL | Schema `ph10_event` (28 bảng) trên `pg-core` | RLS chế độ P (riêng tenant) và S (đọc kèm `COMMON`) |
| Bộ nhớ đệm | Valkey: lease, cursor, chống trùng phát, khóa idempotency | Phụ lục A.8 |
| Giao diện | UI-10-01…20 | React + antd v6 |

### 1.2. Mức kiểm thử

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Chính sách tên topic, tổ hợp `partyType`/`commType`/`deliveryMode`, tính giãn cách thử lại, ký HMAC, mã hóa cursor, đánh giá `alertState` |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka 3 KRaft, Apicurio 3, Keycloak, OpenBao, Valkey, WireMock) | Control plane với CSDL, Apicurio, Git giả lập, outbox |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph10/test/ph10_isolation_test.sql` | RLS, ràng buộc enum, bất biến lược đồ, DLQ lũy đẳng |
| Runtime | RT | `@QuarkusTest`, Kafka thật | Cổng sự kiện, bộ giao nhận, bộ phát lại, cầu nối |
| Hợp đồng | CT | `03-thiet-ke/api/ph10/tools/check_contracts.py`, Spectral, `@asyncapi/parser`, oasdiff | OpenAPI, AsyncAPI, đối chiếu FRS |
| API | API | REST Assured | Mọi API-10 control plane và data plane |
| Kafka | KT | `kcat`, client Java với SASL OAUTHBEARER và mTLS | ACL, nhóm tiêu thụ, hạn mức principal |
| Đầu cuối | E2E | Playwright | UI-10-* |
| Hiệu năng | k6 | k6 (HTTP), `kafka-producer-perf-test`, JMH | NFR-10-001…005, 008…012, 014, 015, 018 |
| Chịu lỗi | Chaos | Chaos Mesh | Broker, `dh-integration`, `pg-core`, Valkey, OpenBao, đầu nhận |
| Bảo mật | ZAP | OWASP ZAP, Trivy, Semgrep, kiểm thử SSRF có chủ đích | ASVS 5.0 mức 2 |

### 1.3. Môi trường kiểm thử

| Môi trường | Mô tả | Dùng cho |
|---|---|---|
| SIT | K8s một cụm; tenant T68, T01, T90…T99; Kafka ba broker, Apicurio, Keycloak, OPA, OpenBao, Valkey, Argo CD thật; Pulsar 3 độc lập giả lập Hub cũ; HTTT giả lập mục 2.4 | API, KT, E2E, RT, Chaos |
| PERF | Cấu hình `QM-VUA` theo D03-09, dữ liệu GĐ-01…07; Kafka ba broker, đĩa NVMe | k6, chaos đo NFR-10-006 |
| UAT | Như SIT; dữ liệu sao từ bản xuất CSDL cấu hình Hub cũ của tỉnh thí điểm đã làm sạch | UAT mục 7 |

### 1.4. Tiêu chí vào và ra

| Loại | Tiêu chí |
|---|---|
| Vào | D02-03-PH10 bản 0.2 ở trạng thái duyệt; DDL `ph10_event.sql` áp được và `ph10_isolation_test.sql` đạt; hợp đồng OpenAPI, AsyncAPI qua CT; bộ dữ liệu mục 2 nạp xong |
| Ra | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt, ca còn lại có lỗi mở mức Thấp; 0 lỗi mở mức Nghiêm trọng, Cao; ma trận mục 8 không có FR mức M thiếu ca dương hoặc ca âm; TS-10-30, 31, 32 đạt 100 % |

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-10-nn`, test case `TC-10-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi test case là một khối thống nhất với D05-02-PH04, PH05:

- Tiêu đề: mã, tên ca, khóa `<!--k:…-->`.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, RT, CT, API, KT, E2E, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC, quyền.
- **Tiền điều kiện / dữ liệu**: mã dữ liệu ở mục 2.
- **Bước**: đánh số. Đường dẫn API control plane tương đối với `/api/event/v1`; đường data plane ghi đủ `/event/v1/…`.
- **Mong đợi**: mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-10-102 (thiếu quyền `PERM-10-*`, scope máy hoặc scope HTTT; API §2.2 dùng chung mã này cho control plane) |
| 403-TC | `403` với ERR-10-044 (đối tượng ngoài phạm vi tổ chức của OR, SV) |
| 404-ẩn | `404` với ERR-10-001 ở control plane, ERR-10-103 ở data plane; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` (BR-10-001) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa bí mật ký, nội dung sự kiện |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{thực-thể}.{sự-kiện}` | Đúng một bản tin trên topic `t68.event.{thực-thể}.{sự-kiện}.v1` (CloudEvents, `ce_type = vn.datahub.event.{thực-thể}.{sự-kiện}`, có `dhtenant`) |
| EVT: không | Sau 10 giây không có dòng mới trong `ph10_event.outbox_event` và không có bản tin trên topic `t68.event.*` liên quan |
| Mồi sạch | Tìm chuỗi `whsec_` của khóa ký thử và chuỗi `DH-CANARY-{ca}` trong phản hồi API, log 5 phút, vết OTel, bảng `ph10_event.*`, outbox, Kafka, tệp xuất, kiểm toán: không thấy |
| Cụm áp dụng | Argo CD đã đồng bộ commit tương ứng ở `dh-config-t68` và Strimzi báo `Ready` cho `KafkaTopic` hoặc `KafkaUser` |

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-10`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: một principal, token hay người dùng của tenant này đọc, phát hoặc nhận được trên topic của tenant khác; sự kiện đã được trả `202` bị mất mà không có mục DLQ; webhook gửi đi không có chữ ký hoặc ký bằng khóa đã thu hồi; bí mật ký xuất hiện ngoài OpenBao; người tự duyệt được yêu cầu của mình; Apicurio nhận phiên bản không tương thích mức đã đặt. Báo cáo hằng đêm từ JUnit, Playwright, k6, đối chiếu ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Nạp bằng `ph10/seed/` qua API (không chèn SQL trực tiếp), trừ khối dữ liệu RLS ở `ph10_isolation_test.sql` vốn chạy ở mức CSDL.

### 2.1. Tenant

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính (giả lập, topic `t68.`) | `10.external-kafka.enabled = true` (PA bật); `10.schema.pii-check-mode = WARN`; tham số khác mặc định A.5 |
| `T01` | Tỉnh đối chứng rò rỉ | Có dự án, topic, bên phát, subscription **trùng mã** với T68 (`dang-ky-kinh-doanh`, `t01.dkkd.doanh-nghiep.da-cap-phep.v1`, `ht-thue-dn-cap-phep`) để phát hiện trả nhầm; Kafka ngoài tắt |
| `T90`, `T91` | Cặp cô lập CSDL và Kafka | Khớp `ph10_isolation_test.sql`; principal nội bộ `User:CN=dh-runtime-t90`, `User:CN=dh-runtime-t91` |
| `T92` | Hạn mức nhỏ | `10.quota.max-topics = 3`, `10.quota.max-subscriptions = 2`, `10.quota.produce-bytes-per-second = 1048576` |
| `T93` | Chặn dữ liệu cá nhân | `10.schema.pii-check-mode = BLOCK` |
| `T94` | Tenant tạm ngừng | Đặt tạm ngừng ở PH-20 để kiểm ERR-10-039 |
| `T95` | Tự duyệt tắt | `10.approval.auto-approve-machine = false`, `10.replay.dlq-auto-approve-max = 10` |
| `T96` | Di trú Pulsar | Có tác vụ nhập kiểm kê đã áp dụng; cầu nối `brg-t96-cp` |
| `T97`…`T99` | Dự phòng cho ca hiệu năng, chaos chạy song song | Dữ liệu sinh bằng `ph10/seed/perf.py` |
| `COMMON` | Danh mục nền tảng `comm_type`, `routing_mode` | Chỉ PA ghi |

### 2.2. Người dùng

Tên nhân vật trùng D02-04-PH10. Mọi người dùng TA, IA, TO, SO, PA có TOTP thử để kiểm xác thực lại.

| Mã | Tenant | Vai trò | Nhân vật | Mục đích |
|---|---|---|---|---|
| U-PA | PLATFORM | PA | Hà | Trần hạn mức, bật Kafka ngoài, topic `dh.` |
| U-PO | PLATFORM | PO | — | Xem liên tenant có lý do (FR-00-012) |
| U-T68-TA | T68 | TA | Mai | Tham số, danh mục, di trú; có cả tạo và duyệt để kiểm bốn mắt |
| U-T68-IE1 | T68 | IE | An | Người khai báo chính |
| U-T68-IE2 | T68 | IE | Nguyễn Văn Khoa | Người thứ hai, xung đột đồng thời |
| U-T68-IA1 | T68 | IA | Bình | Người duyệt chính |
| U-T68-IA2 | T68 | IA + IE (cố ý cấu hình sai, chỉ có ở SIT) | Đặng Thị Lan | Vi phạm tách nhiệm D02-08 §4 có chủ đích để kiểm lớp bốn mắt độc lập; không tạo ở UAT, PROD |
| U-T68-TO | T68 | TO | Chi | Vận hành subscription, DLQ, phát lại, lag |
| U-T68-SO | T68 | SO | Dũng | Tạm ngừng khi sự cố ATTT |
| U-T68-OR | T68 | OR, tổ chức `SO-TC` (Sở Tài chính) | Thảo | Đề nghị subscription cho HTTT của tổ chức mình |
| U-T68-SV | T68 | SV, tổ chức `SO-KHDT` | — | Đề xuất topic, publication cho HTTT của tổ chức mình |
| U-T68-VW | T68 | VW | — | Chỉ đọc |
| U-T68-AU | T68 | AU | — | Kiểm toán |
| U-T01-IE, U-T01-TO | T01 | IE, TO | — | Đối chứng rò rỉ |
| U-T90-IE, U-T91-IE | T90, T91 | IE | — | Cặp cô lập |

Tài khoản dịch vụ (`client_credentials` + `private_key_jwt`):

| Mã | Chủ thể | Scope |
|---|---|---|
| S-PH05 | `dh-integration` mô-đun PH-05 | `event:topic-register` |
| S-PH04 | `dh-integration` mô-đun PH-04 | `event:permission-check` |
| S-DU-DATA | `dh-data` (PH-07) | `event:topic-register` |
| S-RT-T68, S-RT-T01 | `dh-runtime-t68`, `dh-runtime-t01` | `event:runtime-config`, `event:replay` |
| S-PH18 | PH-18 | `event:dlq-read`, `event:replay` |
| S-PH13 | PH-13 | `event:metrics-read` |

### 2.3. Đối tượng nạp sẵn ở T68

| Mã dữ liệu | Đối tượng | Trạng thái, cấu hình | Dùng cho |
|---|---|---|---|
| P-DKKD | Dự án `dang-ky-kinh-doanh`, chủ quản `SO-KHDT` | `ACTIVE`, 4 topic | Đa số ca |
| P-HT | Dự án `ho-tich`, chủ quản `SO-TP` | `ACTIVE`, 1 topic `SENSITIVE` | Phân loại dữ liệu |
| P-CU | Dự án `thu-nghiem-cu` | `ACTIVE`, không còn topic hoạt động | Lưu trữ |
| TP-CP | Topic `t68.dkkd.doanh-nghiep.da-cap-phep.v1` | `ACTIVE`, `BUSINESS`, 6 phân vùng, `KEY_HASH` theo `maDoanhNghiep`, `orderingRequired = true`, `INTERNAL`, 168 giờ, lược đồ Avro v1, v2, v3 `ENABLED`, mức `BACKWARD` | Phát, nhận, lược đồ |
| TP-GT | Topic `t68.dkkd.doanh-nghiep.giai-the.v1` | `ACTIVE`, `ROUND_ROBIN`, 3 phân vùng, `PUBLIC`, không subscription | Ngừng dùng, đổi cấu hình |
| TP-TD | Topic `t68.dkkd.doanh-nghiep.thay-doi.v1` | `DEPRECATED`, kế nhiệm `t68.dkkd.doanh-nghiep.thay-doi.v2` (`ACTIVE`) | Topic ngừng khuyến nghị |
| TP-KS | Topic `t68.hotich.khai-sinh.da-dang-ky.v1` | `ACTIVE`, `SENSITIVE`, `COMPACT_DELETE`, `KEY_HASH` | DLQ mã hóa, cấp độ ATTT |
| TP-CDC | Topic `t68.cdc.dkkd-cdc.public.dangky.v1` | `ACTIVE`, `CDC`, dự án `cdc-dkkd-cdc`, tự duyệt | Hợp đồng PH-05 |
| TP-RDM | Topic `t68.rdm.catalog.published.v1` | `ACTIVE`, `SYSTEM`, chủ quản `dh-data` | Hợp đồng PH-07, DU |
| PB-DKKD | Bên phát `ht-dkkd`: `SYSTEM`, `HT-DKKD`, `HTTP_PUBLISH`, `referenceKey = PUB_DKKD_01` | `ACTIVE`; publication `pub-…cp` trên TP-CP `ACTIVE` | API phát |
| PB-DKKD-K | Bên phát `ht-dkkd-kafka`: `SYSTEM`, `HT-DKKD`, `KAFKA_NATIVE`, principal `User:{clientId}` | `ACTIVE`; publication trên TP-GT `ACTIVE` | Phát Kafka trực tiếp |
| PB-FLOW | Bên phát `luong-tong-hop-dn`: `FLOW`, luồng `dkkd-tong-hop` | `ACTIVE`; publication trên TP-CP `ACTIVE` | Hợp đồng PH-04 |
| SB-THUE | Bên nhận `ht-thue`: `SYSTEM`, `HT-THUE`, `WEBHOOK_PUSH` | `ACTIVE` | Giao đẩy |
| SB-BHXH | Bên nhận `ht-bhxh`: `SYSTEM`, `HT-BHXH`, `HTTP_PULL` | `ACTIVE` | Kéo API |
| SB-KB | Bên nhận `ht-kho-bac`: `SYSTEM`, `HT-KBNN`, `KAFKA_NATIVE` | `ACTIVE` | Kéo Kafka |
| SB-FLOW | Bên nhận `luong-dong-bo-thue`: `FLOW`, luồng `dkkd-dong-bo-thue` | `ACTIVE` | Nội bộ |
| SB-TC | Bên nhận `ht-tai-chinh`: `SYSTEM`, `HT-QLTC` thuộc `SO-TC` | `ACTIVE` | Phạm vi tổ chức OR |
| SUB-PUSH | Subscription `ht-thue-dn-cap-phep`: SB-THUE, TP-CP, `PUSH`, `endpointUrl = https://thue.sim.test/hooks/dh`, `workerCount = 3`, `maxRetries = 3`, backoff 100 ms ×2 tối đa 2 s (giảm cho kiểm thử), `DEAD_LETTER` | `ACTIVE`, nhóm `dh-sub-t68-ht-thue-dn-cap-phep`, khóa ký `ACTIVE` | Giao đẩy, DLQ, phát lại |
| SUB-PULL | Subscription `ht-bhxh-dn-cap-phep`: SB-BHXH, TP-CP, `PULL_API`, `maxBatch = 100`, `leaseSeconds = 30` | `ACTIVE` | Kéo API |
| SUB-KAFKA | Subscription `ht-kho-bac-dn-cap-phep`: SB-KB, TP-CP, `PULL_KAFKA` | `ACTIVE`, nhóm `dh-ext-t68-ht-kho-bac-dn-cap-phep` | Kéo Kafka |
| SUB-FLOW | Subscription `luong-dong-bo-thue-dn-cap-phep`: SB-FLOW, TP-CP, `INTERNAL` | `ACTIVE`, nhóm `dh-flow-t68-dkkd-dong-bo-thue` | Nội bộ, lag |
| SUB-KS | Subscription `ht-thue-khai-sinh`: SB-THUE, TP-KS, `PUSH`, `BLOCK`, `legalBasis` có | `ACTIVE` | Chặn khi lỗi, DLQ mã hóa |
| DLQ-30 | 30 mục DLQ `NEW` của SUB-PUSH (ERR-10-112 × 20, ERR-10-113 × 10) | `NEW` | DLQ |

Ở T01 có bản sao trùng mã của P-DKKD, TP-CP (tên `t01.…`), PB-DKKD, SUB-PUSH để kiểm 404-ẩn.

### 2.4. Hệ thống giả lập

| Mã | Thành phần | Hành vi điều khiển được |
|---|---|---|
| SIM-WH | WireMock HTTPS `thue.sim.test`, `hooks.sim.test` (trong danh sách egress) | Trả 200, 204, 400, 410, 429 có `Retry-After`, 5xx, chậm n ms; ghi lại tiêu đề, thân; tự xác minh chữ ký với khóa nạp vào; trả `WebHook-Allowed-Origin` đúng, sai hoặc thiếu |
| SIM-WH-BAD | Các đích xấu | `http://plain.sim.test`, `https://selfsigned.sim.test` (chứng thư tự ký), `https://redirect.sim.test` (302 sang `10.0.0.5`), `https://rebind.sim.test` (DNS trả IP công cộng lần đầu, `10.96.0.10` lần sau), `https://ngoai-egress.example` |
| SIM-PH01 | Giả lập PH-01 | Danh sách HTTT `HT-DKKD`, `HT-THUE`, `HT-BHXH`, `HT-KBNN`, `HT-QLTC` `ACTIVE`, `HT-DUNG` `SUSPENDED`; phát sự kiện đổi trạng thái HTTT theo giả định Q10-17 |
| SIM-PH04 | Giả lập PH-04 | Luồng `dkkd-dong-bo-thue`, `dkkd-tong-hop` hợp lệ, `luong-cu` `RETIRED`; phát EVT-04-09 |
| SIM-PH05 | Giả lập PH-05 phía gọi | Gọi API-10-009, 023, 018 với S-PH05; phát EVT-05-11 |
| SIM-PULSAR | Apache Pulsar 3 độc lập | Tenant `lgsp`, namespace `dkkd`, topic `persistent://lgsp/dkkd/doanh-nghiep-cap-phep` có producer và subscriber cũ (`Shared`, 2 consumer) |
| SIM-GIT | Gitea trong SIT | Kho `dh-config-t68`; có thể đặt chỉ đọc hoặc dừng để kiểm ERR-10-029 |

### 2.5. Tệp mẫu

| Mã | Nội dung |
|---|---|
| F-AV1 | Lược đồ Avro `record DoanhNghiepCapPhep`, `namespace vn.datahub.t68.dkkd`, trường `maDoanhNghiep` (string), `loaiThayDoi` (enum), `phienBan` (int), mọi trường có `doc` |
| F-AV-ADD | F-AV1 thêm trường `nganhNghe` kiểu `["null","string"]`, `default: null` (tương thích `BACKWARD`) |
| F-AV-DEL | F-AV1 bỏ trường `phienBan` (tương thích `BACKWARD`, không tương thích `FORWARD` khi trường không có mặc định) |
| F-AV-BRK | F-AV1 thêm trường bắt buộc `ngayCap` (long) không mặc định và đổi `phienBan` sang string (không tương thích `BACKWARD`) |
| F-AV-NOKEY | F-AV1 bỏ `maDoanhNghiep` |
| F-AV-PII | F-AV1 thêm `soDinhDanh`, `hoTenNguoiDaiDien`, `soDienThoai` |
| F-AV-BAD | Avro sai cú pháp (thiếu `fields`) |
| F-JS1 | JSON Schema draft 2020-12 tương đương F-AV1 |
| F-CE-OK | 100 sự kiện CloudEvents hợp lệ theo F-AV1, khóa `0999000001…100`, mỗi sự kiện 2 KB |
| F-CE-BAD | Sự kiện thiếu `specversion`; `source` của HTTT khác; `data` thiếu `maDoanhNghiep`; lô 101 sự kiện; lô 1,2 MiB |
| F-MAN | Tệp `EventManifest` YAML xuất từ P-DKKD |
| F-PUL-INV | Tệp nén kiểm kê Hub cũ: 3 project, 8 topic, 5 publisher, 7 subscriber (2 "là luồng"), 6 publication, 9 subscription, `type_of_comm`, `routing_mode`; 1 subscription có mật khẩu Basic nhúng trong URI |
| F-PUL-BAD | Kiểm kê thiếu bảng `subscription`, sai tên cột |

### 2.6. Nguyên tắc dữ liệu

Không dùng mã số doanh nghiệp, số định danh, số điện thoại thật; khóa nghiệp vụ dùng dải giả `0999…`. Khóa ký thử có tiền tố `whsec_` và được đăng ký vào bộ dò mồi. Mỗi ca tạo đối tượng có tiền tố `tc-` (mã) hoặc miền `tc` (topic `t68.tc.….v1`) và tự dọn sau khi chạy, trừ ca cần giữ mã để kiểm BR-10-003.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

| Máy trạng thái (FRS §4) | Chuyển hợp lệ được kiểm | Chuyển cấm được kiểm |
|---|---|---|
| Dự án | ACTIVE → ARCHIVED → ACTIVE | Lưu trữ khi còn topic `ACTIVE`, `DEPRECATED`; sửa khi `ARCHIVED` |
| Topic | DRAFT → PENDING_APPROVAL → PROVISIONING → ACTIVE → DEPRECATED → RETIRED; PENDING_APPROVAL → DRAFT; PROVISIONING → FAILED → PROVISIONING; DRAFT → PROVISIONING (CDC, SYSTEM tự duyệt) | Subscription mới trên `DEPRECATED`; phát lên `RETIRED`; ngừng dùng khi còn subscription mà không qua duyệt |
| Phiên bản lược đồ | DRAFT → PENDING_APPROVAL → ENABLED → DEPRECATED → DISABLED; PENDING_APPROVAL → REJECTED | Sửa nội dung `ENABLED`; vô hiệu phiên bản mới nhất; hai phiên bản cùng `PENDING_APPROVAL` |
| Publication | PENDING_APPROVAL → ACTIVE → SUSPENDED → ACTIVE → REVOKED; PENDING_APPROVAL → REJECTED | Tiếp tục sau `REVOKED` |
| Subscription | PENDING_APPROVAL → PROVISIONING → ACTIVE → PAUSED → ACTIVE; ACTIVE → SUSPENDED (`CIRCUIT_BREAKER`, `DELIVERY_BLOCKED`, `SECURITY`, `PH01`) → ACTIVE; * → REVOKED | Tạm dừng `INTERNAL`; `RESET_OFFSET` khi không `PAUSED` |
| Lượt phát lại | PENDING_APPROVAL → APPROVED → RUNNING → COMPLETED; RUNNING → CANCELLED; PENDING_APPROVAL → REJECTED | Hai lượt cùng `APPROVED`, `RUNNING` cho một subscription |
| Mục DLQ | NEW → REPLAY_PENDING → REPLAYED → PURGED; NEW → DISCARDED → PURGED; REPLAY_PENDING → NEW | Loại bỏ mục đã `REPLAYED`; xóa nội dung mục `NEW` |
| Ánh xạ di trú, cầu nối | PROPOSED → PLANNED → BRIDGING → CUT_OVER → ROLLED_BACK → BRIDGING; cầu nối PENDING_APPROVAL → RUNNING → STOPPED → RUNNING; → EXPIRED | Hai cầu nối ngược chiều cùng cặp topic; cầu nối `REJECTED` chạy |
| Tác vụ nhập | VALIDATING → PREVIEW → APPLYING → APPLIED; VALIDATING → FAILED | Áp dụng tác vụ `FAILED` |

## 4. Kịch bản và test case chức năng

### TS-10-01 · Dự án tích hợp

**Mục tiêu.** Xác nhận quản lý dự án thay "Quản lý project" của Hub cũ: mã bất biến, không trùng từ dành riêng của route, lưu trữ thay xóa, đếm topic và bên tham gia đúng.

**Phủ.** FR-10-001…005, 065; UC-10-01; API-10-001…006; UI-10-02, 03, 04; BR-10-003; LGC-HUB-008.

#### TC-10-001 · Tạo dự án hợp lệ và xem chi tiết <!--k:prj-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-10-003, 002 · API-10-002, 003 · UI-10-04, 03 · UC-10-01 · LGC-HUB-008
- **Tiền điều kiện / dữ liệu** U-T68-IE1; tenant T68 còn dưới `10.quota.max-projects`.
- **Bước**
  1. Mở UI-10-04 (`/tich-hop/du-an/moi`), nhập mã `tc-lien-thong-thue`, tên "Liên thông thuế thử", tổ chức `SO-KHDT`, nhãn `doanh-nghiep`; bấm "Tạo".
  2. `GET /projects/tc-lien-thong-thue`.
- **Mong đợi** Bước 1 gọi `POST /projects` có `Idempotency-Key`, trả `201`, `Location`, `ETag`; màn chuyển sang UI-10-03. Bước 2: `status = ACTIVE`, `ownerUser` là người tạo, `topicCount = 0`, `publisherCount = 0`, `subscriberCount = 0`. KT: có (`PROJECT_CREATE`). EVT: không.

#### TC-10-002 · Tạo dự án sai mẫu, từ dành riêng, trùng mã, ngoài tổ chức, vượt hạn mức <!--k:prj-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-003 · API-10-002 · ERR-10-002, 003, 011, 044 · BR-10-003
- **Tiền điều kiện / dữ liệu** U-T68-IE1; U-T68-SV (tổ chức `SO-KHDT`); P-CU đã lưu trữ ở bước chuẩn bị; T92 đã có 200 dự án giả (đặt `10.quota.max-projects = 200`).
- **Bước**
  1. `POST /projects` với `projectCode = "Tc_Hoa"`.
  2. Lặp với `projectCode` lần lượt `moi`, `tong-quan`, `nhap`, `di-tru`, `ben-phat`, `ben-nhan`.
  3. Lặp với `dang-ky-kinh-doanh` và `thu-nghiem-cu` (đã `ARCHIVED`).
  4. U-T68-SV gửi `ownerOrgCode = SO-TC`.
  5. U-T90-IE trên T92 tạo dự án thứ 201.
- **Mong đợi** Bước 1, 2 `400` ERR-10-003 với `errors[0].field = projectCode`. Bước 3 `409` ERR-10-002 (mã đã lưu trữ cũng không dùng lại). Bước 4 403-TC. Bước 5 `422` ERR-10-011. KT: không.

#### TC-10-003 · Danh sách dự án lọc, sắp xếp, đếm và facets <!--k:prj-list-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-10-001 · API-10-001 · UI-10-02 · ERR-10-049
- **Tiền điều kiện / dữ liệu** U-T68-VW; P-DKKD, P-HT, P-CU.
- **Bước**
  1. `GET /projects?q=kinh doanh&status=ACTIVE&sort=topicCount,desc`.
  2. `GET /projects?size=201`.
  3. U-T68-OR gọi `GET /projects`.
- **Mong đợi** Bước 1 `200`, có `dang-ky-kinh-doanh` với `topicCount = 4`, `publisherCount`, `subscriberCount` đếm theo quan hệ `ACTIVE`, `maxLagSeconds` có giá trị; `facets.status` đếm đúng. Bước 2 `400` ERR-10-049. Bước 3 chỉ trả dự án có HTTT của `SO-TC` tham gia (P-DKKD qua SB-TC chưa có subscription thì không có). Tìm không dấu "kinh doanh" khớp tên có dấu.

#### TC-10-004 · Sửa dự án có If-Match; mã bất biến; dự án đã lưu trữ không sửa <!--k:prj-patch-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-10-004 · API-10-004 · ERR-10-003, 006, 007
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IE2; dự án `tc-lien-thong-thue` từ TC-10-001.
- **Bước**
  1. IE1 `PATCH /projects/tc-lien-thong-thue` đổi `name`, `If-Match` đúng.
  2. IE2 gửi `PATCH` với `ETag` cũ.
  3. IE1 gửi `PATCH` có `projectCode = "doi-ma"`.
  4. Lưu trữ dự án rồi `PATCH` tên.
- **Mong đợi** Bước 1 `200`, `ETag` mới. Bước 2 `412` ERR-10-007 có `currentEtag`. Bước 3 `400` ERR-10-003. Bước 4 `409` ERR-10-006. KT: có (`PROJECT_UPDATE`, giá trị trước và sau) chỉ cho bước 1.

#### TC-10-005 · Lưu trữ khi còn topic bị chặn; lưu trữ, khôi phục thành công <!--k:prj-archive-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-10-005 · API-10-005, 006 · UI-10-03 · ERR-10-009, 010 · BR-10-003 · LGC-HUB-008
- **Tiền điều kiện / dữ liệu** U-T68-IE1; P-DKKD (có topic `ACTIVE`); P-CU (chỉ có một topic `DRAFT`).
- **Bước**
  1. `POST /projects/dang-ky-kinh-doanh:archive` với lý do hợp lệ.
  2. `POST /projects/thu-nghiem-cu:archive` không có `reason`.
  3. Lặp bước 2 với lý do "Dự án thử nghiệm đã kết thúc".
  4. `POST /projects/thu-nghiem-cu:restore`.
  5. Ở UI-10-02 mở bộ lọc mặc định.
- **Mong đợi** Bước 1 `409` ERR-10-010 với `dependents[]` liệt kê 4 topic. Bước 2 `400` ERR-10-009. Bước 3 `200`, `status = ARCHIVED`, topic `DRAFT` bị xóa mềm, không có nút "Xóa" ở bất kỳ màn nào. Bước 4 `200`, `ACTIVE`. Bước 5 dự án `ARCHIVED` không hiện ở lọc mặc định, hiện khi chọn trạng thái "Đã lưu trữ". KT: có cho bước 3, 4.

### TS-10-02 · Tạo topic và gửi duyệt

**Mục tiêu.** Xác nhận "Quản lý topic: tên, mô tả, phân vùng, cấu trúc, chế độ định tuyến" của Hub cũ được thay bằng topic có tên theo quy ước tiền tố tenant, lược đồ bắt buộc, tham số trong trần và tổ hợp định tuyến hợp lệ.

**Phủ.** FR-10-006, 007, 008, 013; UC-10-02; API-10-008…012, 020; UI-10-05, 06, 07; BR-10-002, 004, 006, 011, 030; LGC-HUB-009, 014.

#### TC-10-006 · Tạo topic bằng trình hướng dẫn và gửi duyệt ngay <!--k:topic-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-10-008 · API-10-009 · UI-10-07 · UC-10-02 · BR-10-002, 004 · LGC-HUB-009
- **Tiền điều kiện / dữ liệu** U-T68-IE1; P-DKKD; F-AV1.
- **Bước**
  1. Ở UI-10-07 chọn dự án P-DKKD, miền `tc`, thực thể `doanh-nghiep`, sự kiện `da-tam-ngung`, mô tả 40 ký tự, phân loại `INTERNAL`, `KEY_HASH` với `partitionKeyField = maDoanhNghiep`, lược đồ F-AV1, đánh dấu "Gửi duyệt ngay".
  2. `GET /topics/t68.tc.doanh-nghiep.da-tam-ngung.v1`.
- **Mong đợi** Bước 1 `201` có `approvalRequestCode` dạng `apr-{ULID}`. Bước 2: `status = PENDING_APPROVAL`, `partitions = 6`, `retentionHours = 168`, `replicationFactor = 3`, `minInsyncReplicas = 2`, `cleanupPolicy = DELETE`, `majorVersion = 1`, `topicKind = BUSINESS`; lược đồ v1 `PENDING_APPROVAL`; chưa có `KafkaTopic` ở `dh-config-t68`. Trình hướng dẫn không có ô nhập hệ số nhân bản. KT: có (`TOPIC_CREATE`, băm lược đồ). EVT: không.

#### TC-10-007 · Tên topic sai quy ước, miền dành riêng, trùng tên đã ngừng dùng <!--k:topic-name-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-10-008 · API-10-009 · ERR-10-002, 003, 004 · BR-10-002, 003, 030
- **Tiền điều kiện / dữ liệu** U-T68-IE1; topic `t68.tc.cu.da-xoa.v1` đã `RETIRED`.
- **Bước**
  1. `POST /topics` với `domain = "DKKD"`, rồi `entity = "doanh_nghiep"`.
  2. Lặp với `domain` lần lượt `event`, `cdc`, `audit`, `obs`, `integration`, `adapter`, `rdm`.
  3. Ghép tên dài 201 ký tự.
  4. Tạo lại `t68.tc.cu.da-xoa.v1`.
  5. `POST /topics` có `topicKind = CDC` bằng U-T68-IE1.
- **Mong đợi** Bước 1, 2, 3 `422` ERR-10-004 với `errors[].field` đúng trường. Bước 4 `409` ERR-10-002. Bước 5 `422` ERR-10-004 hoặc ERR-10-003 theo API §3.3 (người dùng không đăng ký `CDC`); không có bản ghi topic nào được tạo.

#### TC-10-008 · Tham số vượt trần, tổ hợp định tuyến không hợp lệ, compaction không khóa <!--k:topic-param-neg-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-008, 013 · API-10-009 · ERR-10-011, 012, 046, 048 · BR-10-006
- **Tiền điều kiện / dữ liệu** U-T68-IE1; U-T90-IE trên T92 (đã có 3 topic).
- **Bước**
  1. `partitions = 49`; rồi `partitions = 48` (biên).
  2. `retentionHours = 721` khi trần 720.
  3. `KEY_HASH` không có `partitionKeyField`.
  4. `orderingRequired = true` với `ROUND_ROBIN`.
  5. `cleanupPolicy = COMPACT` với `ROUND_ROBIN`.
  6. `SINGLE_PARTITION` với `partitions = 6`.
  7. Trên T92 tạo topic thứ tư.
- **Mong đợi** Bước 1: 49 trả `422` ERR-10-012, 48 trả `201`. Bước 2 `422` ERR-10-012. Bước 3, 4, 6 `422` ERR-10-046. Bước 5 `422` ERR-10-048. Bước 7 `422` ERR-10-011 (hạn mức tính cả topic chờ duyệt).

#### TC-10-009 · Lược đồ không hợp lệ khi tạo topic <!--k:topic-schema-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-008, 017 · API-10-009, 012 · ERR-10-015, 017, 018, 020 · BR-10-011
- **Tiền điều kiện / dữ liệu** U-T68-IE1 ở T68; U-T90-IE ở T93 (`pii-check-mode = BLOCK`); F-AV-BAD, F-AV-NOKEY, F-AV-PII.
- **Bước**
  1. Tạo topic với F-AV-BAD.
  2. Tạo topic `KEY_HASH` theo `maDoanhNghiep` với F-AV-NOKEY.
  3. Ở T93 tạo topic `INTERNAL` với F-AV-PII.
  4. Tạo topic với `schemaFormat = PROTOBUF`.
- **Mong đợi** Bước 1 `422` ERR-10-015 kèm dòng, cột lỗi. Bước 2 `422` ERR-10-017 "Trường khóa phân vùng `maDoanhNghiep` không có trong lược đồ". Bước 3 `422` ERR-10-018 liệt kê `soDinhDanh`, `soDienThoai`. Bước 4 `422` ERR-10-020. Không ghi gì vào Apicurio (đếm artifact nhóm `t68`, `t93` không đổi).

#### TC-10-010 · Danh sách topic, chi tiết và thông tin kết nối <!--k:topic-list-detail-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-10-006, 007 · API-10-008, 010, 020 · UI-10-05, 06 · LGC-HUB-009
- **Tiền điều kiện / dữ liệu** U-T68-VW; TP-CP, TP-TD, TP-CDC; topic DLQ `t68.dkkd.doanh-nghiep.da-cap-phep.v1.dlq` có trên cụm.
- **Bước**
  1. `GET /topics?projectCode=dang-ky-kinh-doanh&sort=topicName,asc`.
  2. `GET /topics?topicKind=DLQ`.
  3. `GET /topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1` và `/connection-info`.
  4. Mở UI-10-06 với route `/tich-hop/topic/t68.dkkd.doanh-nghiep.da-cap-phep.v1`.
- **Mong đợi** Bước 1 không có topic `RETIRED`, không có topic `DLQ`; dòng TP-TD có `successorTopic`; `facets` theo `status`, `topicKind`, `dataClass`. Bước 2 trả topic DLQ khi lọc rõ. Bước 3 có `latestSchemaVersion = 3`, danh sách publication, subscription kèm `alertState`; `connection-info` có đường API phát, API kéo, địa chỉ listener `external` (T68 đã bật), URI artifact Apicurio `groups/t68/artifacts/{topicName}`. Bước 4 route có dấu chấm mở đúng màn, tab "Cách kết nối" có mã mẫu.

#### TC-10-011 · Rút yêu cầu tạo topic trước khi duyệt <!--k:topic-withdraw-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-10-008 · API-10-102, 011, 012 · ERR-10-006
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IE2; topic từ TC-10-006 ở `PENDING_APPROVAL`.
- **Bước**
  1. IE2 gọi `POST /approval-requests/{requestCode}:withdraw`.
  2. IE1 gọi `:withdraw`.
  3. IE1 `PATCH /topics/{topicName}` đổi `partitions = 3`, rồi `:submit`.
- **Mong đợi** Bước 1 403-PQ (chỉ người gửi được rút). Bước 2 `200`, yêu cầu `WITHDRAWN`, topic và lược đồ về `DRAFT`. Bước 3 sửa được khi `DRAFT`, gửi lại tạo yêu cầu mới `PENDING`.

### TS-10-03 · Duyệt topic và cấp phát qua GitOps

**Mục tiêu.** Xác nhận duyệt bốn mắt rồi cấp phát đúng: artifact Apicurio theo `groupId = {tenant}`, `KafkaTopic` sinh vào `dh-config-{tenant}`, topic DLQ tạo cùng lúc, lỗi cấp phát có đường thử lại, hủy.

**Phủ.** FR-10-009, 010; UC-10-03; API-10-057…059, 101, 013, 014; UI-10-13, 06; BR-10-004, 010, 023, 036; EVT-10-01, 05; ADR-072.

#### TC-10-012 · Duyệt tạo topic, cấp phát tới ACTIVE trong 3 phút <!--k:topic-approve-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-10-009 · API-10-057, 058, 059 · UI-10-13 · UC-10-03 · EVT-10-01, 05 · BR-10-004, 023 · NFR-10-008 · LGC-HUB-009
- **Tiền điều kiện / dữ liệu** U-T68-IA1; topic `t68.tc.doanh-nghiep.da-tam-ngung.v1` `PENDING_APPROVAL` do IE1 gửi.
- **Bước**
  1. Mở UI-10-13 (`/viec-cua-toi?phan-he=10`), mở yêu cầu `TOPIC_CREATE`, xem khác biệt và kết quả kiểm tra lược đồ; duyệt với ý kiến "Đồng ý cấp phát".
  2. Theo dõi `GET /topics/{topicName}` mỗi 10 giây.
  3. Đọc `dh-config-t68/kafka/topics/{topicName}.yaml` và artifact Apicurio.
- **Mong đợi** Bước 1 `200`, yêu cầu `APPROVED`. Bước 2 `PROVISIONING` rồi `ACTIVE` trong ≤ 3 phút. Bước 3: `replicas: 3`, `min.insync.replicas: 2`, `retention.ms = 604800000`, nhãn `dh.gov.vn/tenant: t68`; có thêm tệp topic `{topicName}.dlq`; Apicurio có artifact `groupId = t68`, `artifactId = {topicName}`, quy tắc tương thích `BACKWARD`, phiên bản 1 `ENABLED`. EVT: `topic.activated`, `schema.version-enabled`. KT: có (`TOPIC_APPROVE`, mã commit).

#### TC-10-013 · Người tạo tự duyệt, thiếu ý kiến, thiếu xác nhận dữ liệu cá nhân, từ chối <!--k:topic-approve-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-009 · API-10-059, 101 · ERR-10-008, 009 · BR-10-010, 014
- **Tiền điều kiện / dữ liệu** U-T68-TA tạo và gửi topic `t68.tc.nguoi-dai-dien.da-dang-ky.v1` với F-AV-PII (`WARN`); U-T68-IA2 là người gửi một yêu cầu khác; U-T68-IA1.
- **Bước**
  1. U-T68-TA duyệt chính yêu cầu của mình.
  2. U-T68-IA2 duyệt yêu cầu do chính mình gửi.
  3. U-T68-IA1 duyệt không có `comment`.
  4. U-T68-IA1 duyệt có `comment` nhưng thiếu `acknowledgePii`.
  5. U-T68-IA1 từ chối với `comment = "Không"` (dưới 10 ký tự), rồi với lý do đủ dài.
- **Mong đợi** Bước 1, 2 `403` ERR-10-008 (bốn mắt áp cả với TA). Bước 3, 4 `400` ERR-10-009. Bước 5 lần đầu `400` ERR-10-009; lần hai `200`, yêu cầu `REJECTED`, topic về `DRAFT`, người gửi nhận thông báo. Không có artifact Apicurio, không có commit Git.

#### TC-10-014 · Apicurio hoặc Git ngừng khi duyệt không để lại trạng thái dở <!--k:topic-approve-dep-->
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** API, Chaos
- **Truy vết** FR-10-009 · API-10-059 · ERR-10-029 · BR-10-036
- **Tiền điều kiện / dữ liệu** U-T68-IA1; hai topic `PENDING_APPROVAL`; SIM-GIT có thể dừng.
- **Bước**
  1. Dừng Apicurio; duyệt topic thứ nhất.
  2. Bật Apicurio, dừng SIM-GIT; duyệt topic thứ hai.
- **Mong đợi** Bước 1 `503` ERR-10-029 có `Retry-After`; yêu cầu vẫn `PENDING`. Bước 2 `503` ERR-10-029; artifact đã tạo ở Apicurio được xóa bù; yêu cầu vẫn `PENDING`, topic vẫn `PENDING_APPROVAL`. Sau khi bật lại và duyệt lần nữa thì `ACTIVE` bình thường.

#### TC-10-015 · Cấp phát thất bại, thử lại và hủy cấp phát <!--k:topic-provision-fail-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-10-010 · API-10-013, 014 · ERR-10-006, 038 · BR-10-036
- **Tiền điều kiện / dữ liệu** U-T68-IE1; chính sách Kyverno thử nghiệm từ chối `KafkaTopic` có nhãn `dh.gov.vn/project: tc-loi`; topic của dự án `tc-loi` được duyệt.
- **Bước**
  1. Chờ quá `10.provisioning.timeout-minutes` (đặt 3 phút ở SIT).
  2. Đề nghị publication trên topic đó.
  3. Gỡ chính sách, gọi `POST /topics/{topicName}:retry-provisioning`.
  4. Với topic `FAILED` thứ hai gọi `:cancel-provisioning`; gọi `:retry-provisioning` với topic `ACTIVE`.
- **Mong đợi** Bước 1 topic `FAILED`, `provisioningError` có thông điệp Kyverno, IE và TA nhận cảnh báo. Bước 2 `409` ERR-10-038. Bước 3 `202`, rồi `ACTIVE`. Bước 4: hủy trả `200`, topic về `DRAFT`, tệp YAML bị gỡ khỏi Git; thử lại với `ACTIVE` trả `409` ERR-10-006.

#### TC-10-016 · Phát hiện lệch giữa cụm và Git <!--k:topic-drift-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P2 · **Tự động** IT, Chaos
- **Truy vết** FR-10-010 · BR-10-036 · NFR-10-019
- **Tiền điều kiện / dữ liệu** TP-GT `ACTIVE`; quyền quản trị cụm ở SIT.
- **Bước**
  1. Sửa tay `retention.ms` của TP-GT bằng `kafka-configs`.
  2. Xóa tay tài nguyên `KafkaTopic` của một topic thử.
  3. Chờ một chu kỳ đối chiếu 10 phút.
- **Mong đợi** Cảnh báo lệch cho cả hai trường hợp, kèm giá trị Git và giá trị cụm; Argo CD khôi phục cấu hình theo Git; PH-10 không tự sửa cấu hình bằng Admin API; trạng thái topic ở UI-10-06 hiện dải "Lệch cấu hình".

### TS-10-04 · Thay đổi cấu hình topic đang hoạt động

**Mục tiêu.** Xác nhận tăng phân vùng, đổi lưu giữ, dọn, định tuyến và mức tương thích đi qua yêu cầu `TOPIC_CHANGE` có duyệt khi có rủi ro mất hay đảo thứ tự sự kiện.

**Phủ.** FR-10-011, 012, 013, 021; UC-10-04; API-10-015, 059; UI-10-06, 13; BR-10-005, 006, 012; EVT-10-02.

#### TC-10-017 · Tăng phân vùng có xác nhận tác động thứ tự <!--k:part-increase-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, KT
- **Truy vết** FR-10-011 · API-10-015, 059 · EVT-10-02 · BR-10-005 · UC-10-04
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; TP-CP 6 phân vùng, SUB-PUSH đang giao.
- **Bước**
  1. `POST /topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/change-requests` với `partitions = 12`, `reason`, `acknowledgeOrderingImpact = true`.
  2. IA1 duyệt.
  3. Phát 1.000 sự kiện trong lúc áp dụng.
- **Mong đợi** Bước 1 `201`, phản hồi có cảnh báo khóa ánh xạ sang phân vùng khác và gợi ý FR-10-015. Bước 2 Cụm áp dụng, `partitions = 12`. Bước 3 SUB-PUSH tự nhận phân vùng mới qua tái cân bằng, không mất sự kiện. EVT: `topic.changed`. KT: có (6 sang 12, người duyệt).

#### TC-10-018 · Giảm phân vùng, thiếu xác nhận, topic một phân vùng <!--k:part-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-011 · API-10-015 · ERR-10-012, 013, 014 · BR-10-005
- **Tiền điều kiện / dữ liệu** U-T68-IE1; TP-CP; topic `SINGLE_PARTITION` thử.
- **Bước**
  1. Đề nghị `partitions = 3` cho TP-CP.
  2. Đề nghị `partitions = 8` không có `acknowledgeOrderingImpact`.
  3. Đề nghị `partitions = 49`.
  4. Đề nghị tăng phân vùng cho topic `SINGLE_PARTITION`.
- **Mong đợi** Bước 1 `422` ERR-10-013. Bước 2 `409` ERR-10-014. Bước 3 `422` ERR-10-012. Bước 4 `422` ERR-10-046. Không có yêu cầu duyệt nào được tạo.

#### TC-10-019 · Tăng lưu giữ không cần duyệt; giảm lưu giữ chặn khi có subscription chậm <!--k:retention-change-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-012 · API-10-015, 059 · ERR-10-009, 012 · EVT-10-02
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; TP-CP; SUB-FLOW có `lagSeconds = 7200` (giả lập dừng luồng).
- **Bước**
  1. Đổi `retentionHours = 336`.
  2. Đổi `retentionHours = 1`.
  3. IA1 duyệt yêu cầu ở bước 2 không có `acknowledgeDataLoss`.
  4. IA1 duyệt có `acknowledgeDataLoss = true` và ý kiến.
- **Mong đợi** Bước 1 áp dụng ngay không qua duyệt, EVT: `topic.changed`. Bước 2 `201` tạo `TOPIC_CHANGE`, phản hồi liệt kê `luong-dong-bo-thue-dn-cap-phep` có lag lớn hơn lưu giữ mới. Bước 3 `400` ERR-10-009. Bước 4 `200`, `retention.ms = 3600000` sau khi cụm áp dụng.

#### TC-10-020 · Đổi chế độ định tuyến và khóa; chế độ bị tắt <!--k:routing-change-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-10-013 · API-10-015 · ERR-10-043, 046, 047 · BR-10-006 · LGC-HUB-014
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1, U-T68-TA; TP-GT (`ROUND_ROBIN`, không `orderingRequired`).
- **Bước**
  1. Đề nghị TP-GT sang `KEY_HASH` theo `maDoanhNghiep`; IA1 duyệt; phát 10 sự kiện cùng khóa.
  2. Đề nghị TP-CP (`orderingRequired`) sang `ROUND_ROBIN`.
  3. Đề nghị TP-CP đổi `partitionKeyField` sang `loaiThayDoi`.
  4. TA tắt `SINGLE_PARTITION` (không topic nào dùng) rồi IE1 đề nghị topic thử sang `SINGLE_PARTITION`.
- **Mong đợi** Bước 1 10 sự kiện cùng khóa vào cùng một phân vùng, đúng thứ tự offset; cổng áp dụng cấu hình mới ≤ 60 giây sau EVT `topic.changed`. Bước 2 `422` ERR-10-046. Bước 3 `409` ERR-10-047 kèm gợi ý tạo `.v2`. Bước 4 `422` ERR-10-043.

#### TC-10-021 · Đổi mức tương thích: nới lỏng, siết chặt, NONE <!--k:compat-level-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-10-021 · API-10-015 · ERR-10-016, 019 · BR-10-012 · ADR-070
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; TP-CP v1…v3 `ENABLED` (v3 bỏ một trường không mặc định so với v1); topic thử `DRAFT` chưa từng `ACTIVE`.
- **Bước**
  1. Đề nghị TP-CP sang `FULL_TRANSITIVE`.
  2. Đề nghị TP-CP sang `NONE`.
  3. Đề nghị TP-CP sang `BACKWARD_TRANSITIVE` có lý do; IA1 duyệt.
  4. Đặt `NONE` cho topic `DRAFT`.
- **Mong đợi** Bước 1 `409` ERR-10-016 kèm cặp phiên bản vi phạm (v1, v3). Bước 2 `422` ERR-10-019. Bước 3 duyệt xong, quy tắc tương thích của artifact ở Apicurio là `BACKWARD_TRANSITIVE`; bên phát, bên nhận nhận thông báo; EVT: `topic.changed`. Bước 4 được nhận.

### TS-10-05 · Ngừng topic và phiên bản chính mới

**Mục tiêu.** Xác nhận ngừng khuyến nghị giữ quan hệ cũ nhưng chặn subscription mới; ngừng dùng thu hồi hết quan hệ và giữ topic khi còn DLQ; thay đổi phá vỡ đi bằng topic `.v{n+1}` có theo dõi chuyển đổi.

**Phủ.** FR-10-014, 015, 016; UC-10-05; API-10-016…019; UI-10-06, 01; BR-10-013, 016, 024; EVT-10-01, 03, 04; ADR-070.

#### TC-10-022 · Ngừng khuyến nghị topic có kế nhiệm <!--k:topic-deprecate-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-014 · API-10-016 · EVT-10-03 · BR-10-016 · UC-10-05
- **Tiền điều kiện / dữ liệu** U-T68-IE1; topic thử `t68.tc.ho-so.da-nop.v1` `ACTIVE` có một subscription; kế nhiệm `t68.tc.ho-so.da-nop.v2` `ACTIVE`.
- **Bước**
  1. `POST /topics/t68.tc.ho-so.da-nop.v1:deprecate` với `reason`, `successorTopic`.
  2. HTTT phát lên topic cũ; bộ giao nhận giao cho subscription cũ.
  3. Đề nghị subscription mới trên topic cũ.
- **Mong đợi** Bước 1 `200`, `DEPRECATED`, `sunsetAt` = hôm nay + 90 ngày. Bước 2 vẫn phát và giao bình thường. Bước 3 `422` ERR-10-025. EVT: `topic.deprecated` có `successorTopic`, `sunsetAt`. Đầu mối các bên nhận được thông báo.

#### TC-10-023 · Ngừng dùng topic: còn subscription, qua duyệt, giữ khi còn DLQ <!--k:topic-retire-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, KT
- **Truy vết** FR-10-014 · API-10-017, 059 · ERR-10-009, 010 · EVT-10-04 · BR-10-016, 024
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; TP-GT không subscription; topic thử có subscription `ACTIVE` và 2 mục DLQ `NEW`.
- **Bước**
  1. `POST /topics/t68.dkkd.doanh-nghiep.giai-the.v1:retire` không có lý do, rồi có lý do.
  2. Phát lên TP-GT qua API và Kafka.
  3. `:retire` topic thử với `immediate = true`.
  4. Gửi yêu cầu `TOPIC_RETIRE`, IA1 duyệt; chờ quá `10.topic.delete-after-retire-days`.
- **Mong đợi** Bước 1 lần đầu `400` ERR-10-009; lần hai `200`, `RETIRED`, EVT: `topic.retired`. Bước 2 API trả 404-ẩn (ERR-10-103), Kafka từ chối do ACL bị xóa. Bước 3 `409` ERR-10-010. Bước 4 mọi publication, subscription thu hồi, ACL xóa, topic `RETIRED`; topic chưa bị xóa khỏi cụm vì còn mục DLQ `NEW`.

#### TC-10-024 · Tạo phiên bản chính v2 khi thay đổi phá vỡ <!--k:topic-major-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-10-015 · API-10-018 · EVT-10-01, 03 · BR-10-013 · ADR-070 · LGC-HUB-009
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; topic thử `t68.tc.doanh-nghiep.cap-moi.v1` `ACTIVE` có 2 publication, 2 subscription; F-AV-BRK.
- **Bước**
  1. `POST /topics/t68.tc.doanh-nghiep.cap-moi.v1:new-major-version` với F-AV-BRK, `migrationNote` 40 ký tự, `sunsetDays = 30`.
  2. IA1 duyệt yêu cầu `TOPIC_CREATE` của topic mới.
  3. Xem artifact Apicurio của hai topic.
- **Mong đợi** Bước 1 `201`, topic `t68.tc.doanh-nghiep.cap-moi.v2` `PENDING_APPROVAL`, `predecessorTopic` trỏ v1, yêu cầu kèm khác biệt lược đồ. Bước 2 v2 `ACTIVE`; v1 `DEPRECATED` với `successorTopic`, `sunsetAt` sau 30 ngày; có bản nháp publication trên v2 cho hai bên phát cũ. Bước 3 v2 là artifact mới, không chung lịch sử tương thích với v1. EVT: `topic.activated` (v2), `topic.deprecated` (v1).

#### TC-10-025 · Kế nhiệm đã tồn tại; nguồn không ACTIVE; ghi đè lược đồ ENABLED <!--k:topic-major-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-015, 019 · API-10-018, 025 · ERR-10-006, 047 · BR-10-013
- **Tiền điều kiện / dữ liệu** U-T68-IE1; v1, v2 từ TC-10-024.
- **Bước**
  1. Gọi lại `:new-major-version` trên v1.
  2. Gọi `:new-major-version` trên topic `DRAFT`.
  3. `PUT /topics/{v2}/schema/versions/1` với nội dung khác.
- **Mong đợi** Bước 1 `409` ERR-10-047. Bước 2 `409` ERR-10-006. Bước 3 `409` ERR-10-006 (phiên bản `ENABLED` bất biến); nội dung ở Apicurio không đổi (so `contentHash`).

#### TC-10-026 · Theo dõi chuyển đổi bên nhận sang v2 và nhắc trước hạn <!--k:topic-migration-status-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API, E2E
- **Truy vết** FR-10-016 · API-10-019 · UI-10-06, 01
- **Tiền điều kiện / dữ liệu** U-T68-VW; v1, v2 từ TC-10-024; một bên nhận đã có subscription trên v2, một chưa.
- **Bước**
  1. `GET /topics/{v1}/migration-status`.
  2. Đặt đồng hồ SIT tới `sunsetAt` − 14 ngày và − 3 ngày.
  3. Mở UI-10-01.
- **Mong đợi** Bước 1 liệt kê hai bên nhận với cờ đã chuyển, lag hai bên, số ngày còn lại; bên phát với số sự kiện 24 giờ trên v2. Bước 2 đầu mối bên chưa chuyển nhận thông báo hai lần. Bước 3 thẻ "Topic sắp hết hạn" đếm 1.

### TS-10-06 · Lược đồ sự kiện: soạn, kiểm tra, duyệt

**Mục tiêu.** Xác nhận "cấu trúc" của topic hệ cũ thành lược đồ bắt buộc ở Apicurio: soạn có kiểm tra cú pháp, quy ước, dữ liệu cá nhân, duyệt bốn mắt, lịch sử và so sánh, vòng đời phiên bản.

**Phủ.** FR-10-017, 019, 020, 022; UC-10-06; API-10-021…030; UI-10-08, 13; BR-10-010, 014, 015; EVT-10-05.

#### TC-10-027 · Soạn phiên bản lược đồ mới và kiểm tra <!--k:schema-draft-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-10-017, 018 · API-10-023, 026 · UI-10-08 · UC-10-06 · LGC-HUB-009
- **Tiền điều kiện / dữ liệu** U-T68-IE1; TP-CP; F-AV-ADD.
- **Bước**
  1. Ở UI-10-08 dán F-AV-ADD, ghi chú thay đổi "Thêm ngành nghề kinh doanh"; bấm "Kiểm tra".
  2. `GET /topics/{TP-CP}/schema/versions/4`.
- **Mong đợi** Bước 1 gọi `POST …/schema/versions` (`201`) rồi `:check` (`200`): cú pháp đạt, `compatibilityReport.compatible = true` theo `BACKWARD`, cảnh báo quy ước (nếu có) không chặn, `piiFindings` rỗng. Bước 2 `status = DRAFT`, `contentHash` là SHA-256 của nội dung. Apicurio chưa có phiên bản 4 (chạy thử `dryRun`). KT: có (băm, kết quả kiểm tra).

#### TC-10-028 · Phiên bản sai định dạng, quá lớn, thiếu ghi chú, đang có bản chờ duyệt <!--k:schema-draft-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-017 · API-10-023, 025 · ERR-10-003, 006, 015, 020
- **Tiền điều kiện / dữ liệu** U-T68-IE1; TP-CP định dạng Avro; phiên bản 4 từ TC-10-027 đã gửi duyệt.
- **Bước**
  1. Tạo phiên bản JSON Schema F-JS1 cho TP-CP.
  2. Tạo phiên bản Avro 300 KiB.
  3. Tạo phiên bản không có `changeNote`.
  4. Tạo phiên bản thứ hai khi v4 đang `PENDING_APPROVAL`.
- **Mong đợi** Bước 1 `422` ERR-10-020 (khác định dạng đã có). Bước 2 `422` ERR-10-015 hoặc ERR-10-003 theo giới hạn 256 KiB (API §3.3). Bước 3 `400` ERR-10-003. Bước 4 `409` ERR-10-006.

#### TC-10-029 · Gửi duyệt và duyệt phiên bản lược đồ <!--k:schema-approve-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, RT
- **Truy vết** FR-10-019 · API-10-027, 059 · UI-10-13 · EVT-10-05 · UC-10-06
- **Tiền điều kiện / dữ liệu** U-T68-IE1 gửi, U-T68-IA1 duyệt; v4 `DRAFT` đã kiểm tra trong 24 giờ.
- **Bước**
  1. `POST …/schema/versions/4:submit`.
  2. IA1 mở yêu cầu `SCHEMA_VERSION` ở UI-10-13: xem khác biệt, danh sách bên nhận hiện có; duyệt.
  3. PB-DKKD phát sự kiện có trường `nganhNghe` với `dataschema` trỏ v4.
- **Mong đợi** Bước 1 `200`, v4 `PENDING_APPROVAL`. Bước 2 v4 `ENABLED`, có `apicurioGlobalId`, `latestVersionNo = 4`; EVT: `schema.version-enabled`. Bước 3 cổng nhận sau ≤ 60 giây (đệm làm mới bằng EVT-10-05); SUB-PUSH vẫn giải tuần tự được sự kiện v1…v3 cũ. KT: có.

#### TC-10-030 · Bốn mắt, quá hạn kiểm tra, không tương thích khi duyệt <!--k:schema-approve-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-019 · API-10-027, 059 · ERR-10-008, 016 · BR-10-010
- **Tiền điều kiện / dữ liệu** U-T68-TA soạn v5; U-T68-IA1; F-AV-BRK.
- **Bước**
  1. U-T68-TA gửi duyệt rồi tự duyệt v5.
  2. Soạn v6 bằng F-AV-BRK, `:submit`.
  3. Soạn v7 hợp lệ, kiểm tra, đặt đồng hồ SIT +25 giờ rồi `:submit`.
- **Mong đợi** Bước 1 duyệt trả `403` ERR-10-008. Bước 2 `409` ERR-10-016 kèm báo cáo (trường `ngayCap` không mặc định, `phienBan` đổi kiểu). Bước 3 hệ thống chạy lại kiểm tra trước khi gửi (kết quả 24 giờ hết hạn), gửi thành công nếu vẫn tương thích. Apicurio không có v6.

#### TC-10-031 · Lịch sử phiên bản, so sánh, tải lược đồ <!--k:schema-history-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-10-020 · API-10-021, 022, 024, 030 · UI-10-08 · ERR-10-049 · LGC-HUB-009
- **Tiền điều kiện / dữ liệu** U-T68-VW; TP-CP v1…v4.
- **Bước**
  1. `GET …/schema/versions`.
  2. `GET …/schema/diff?from=1&to=4`.
  3. `GET …/schema/diff?from=1&to=99`.
  4. Ở UI-10-08 tải `.avsc` của v2, xem ví dụ sự kiện sinh từ lược đồ.
- **Mong đợi** Bước 1 bốn phiên bản kèm người duyệt, ngày, ghi chú. Bước 2 khác biệt cấu trúc liệt kê trường thêm `nganhNghe`. Bước 3 404-ẩn. Bước 4 tệp đúng nội dung v2 (so băm); ví dụ dùng giá trị giả lập, không có dữ liệu thật.

#### TC-10-032 · Ngừng khuyến nghị và vô hiệu phiên bản lược đồ <!--k:schema-deprecate-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API, RT
- **Truy vết** FR-10-022 · API-10-028, 029 · ERR-10-006, 009 · BR-10-015 · EVT-10-02
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-IA1; TP-CP v1…v4; bản tin cuối theo v1 ghi nhận 10 ngày trước, lưu giữ 7 ngày; bản tin theo v2 còn trong lưu giữ.
- **Bước**
  1. `:deprecate` v1; phát một sự kiện theo v1.
  2. `:deprecate` v4 (mới nhất).
  3. Đề nghị `:disable` v2.
  4. Đề nghị `:disable` v1, IA1 duyệt.
- **Mong đợi** Bước 1 v1 `DEPRECATED` ở cả PH-10 và Apicurio; phát được nhưng phản hồi có tiêu đề `Deprecation`. Bước 2 `409` ERR-10-006. Bước 3 `409` ERR-10-006 kèm thời điểm bản tin cuối dùng v2. Bước 4 v1 `DISABLED`; EVT: `topic.changed`.

### TS-10-07 · Tương thích lược đồ Apicurio và topic .v{n+1}

**Mục tiêu.** Chứng minh quy tắc ADR-070: mỗi topic một artifact `groupId = tenant`, `artifactId = topicName`; mức mặc định `BACKWARD` chặn ở Apicurio cả khi có người cố ghi thẳng; thay đổi phá vỡ chỉ đi bằng topic mới; bên nhận cũ đọc được dữ liệu mới.

**Phủ.** FR-10-018, 021, 015, 024; BR-10-008, 012, 013; ERR-10-016, 102; API-10-026, 084; ADR-070.

#### TC-10-033 · Ma trận tương thích theo từng mức <!--k:compat-matrix-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-10-018 · API-10-026 · ERR-10-016 · BR-10-012 · ADR-070
- **Tiền điều kiện / dữ liệu** Topic thử với v1 = F-AV1; F-AV-ADD, F-AV-DEL, F-AV-BRK.
- **Bước**
  1. Với từng mức `BACKWARD`, `FORWARD`, `FULL`, `BACKWARD_TRANSITIVE` chạy `:check` cho ba tệp.
- **Mong đợi** `BACKWARD`: ADD đạt, DEL đạt, BRK không đạt. `FORWARD`: ADD đạt, DEL không đạt (trường không mặc định), BRK không đạt. `FULL`: chỉ ADD đạt. `BACKWARD_TRANSITIVE` so với mọi phiên bản `ENABLED`, `DEPRECATED`. Báo cáo không đạt có đường dẫn trường và quy tắc vi phạm.

#### TC-10-034 · Ghi thẳng phiên bản phá vỡ vào Apicurio bị chặn <!--k:compat-registry-direct-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT, KT
- **Truy vết** FR-10-024, 034 · API-10-084 · ERR-10-102 · BR-10-008, 013
- **Tiền điều kiện / dữ liệu** Client C-DKKD có scope `topic:{TP-CP}:publish`; serde Apicurio với `auto.register = true` cố ý.
- **Bước**
  1. Gọi `POST /event/v1/registry/apis/registry/v3/groups/t68/artifacts/{TP-CP}/versions` với F-AV-BRK.
  2. Producer Kafka của PB-DKKD-K bật tự đăng ký lược đồ và gửi bản tin theo F-AV-BRK.
- **Mong đợi** Bước 1 bị từ chối (đường tra cứu chỉ đọc, `403` ERR-10-102). Bước 2 Apicurio từ chối đăng ký; producer nhận lỗi; không có phiên bản mới ở artifact.

#### TC-10-035 · Bên nhận cũ đọc dữ liệu theo lược đồ mới <!--k:compat-consumer-old-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** RT
- **Truy vết** FR-10-018, 019, 038 · ADR-070 · BR-10-012
- **Tiền điều kiện / dữ liệu** SUB-PUSH, SUB-KAFKA; TP-CP v4 `ENABLED` (thêm trường có mặc định).
- **Bước**
  1. Phát 50 sự kiện v3 và 50 sự kiện v4 xen kẽ.
  2. Consumer của HT-KBNN cấu hình đọc theo v3.
- **Mong đợi** SUB-PUSH giao đủ 100 sự kiện, `ce_dataschema` trỏ đúng phiên bản mỗi sự kiện. Consumer v3 giải tuần tự được cả 100 (trường mới bị bỏ qua). Không có mục DLQ ERR-10-116.

#### TC-10-036 · Thay đổi phá vỡ không có đường nào ngoài .v{n+1} <!--k:compat-break-path-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-015, 021 · API-10-015, 027 · ERR-10-016, 019, 047 · BR-10-013
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-TA; TP-CP; F-AV-BRK.
- **Bước**
  1. Đề nghị hạ mức tương thích TP-CP về `NONE` để đưa F-AV-BRK vào.
  2. Đề nghị đổi mức về `FORWARD` rồi gửi F-AV-BRK.
  3. Gọi `:new-major-version` với F-AV-BRK.
- **Mong đợi** Bước 1 `422` ERR-10-019 (topic đã từng `ACTIVE`). Bước 2 khi đổi mức, kiểm tra trước phát hiện v1…v4 vẫn thỏa `FORWARD` nên được duyệt; gửi F-AV-BRK vẫn `409` ERR-10-016 (không tương thích `FORWARD`). Bước 3 là đường duy nhất được nhận, tạo `.v2`.

### TS-10-08 · Bên phát và bên nhận

**Mục tiêu.** Xác nhận "Quản lý publisher, subscriber" của Hub cũ (tên, kiểu giao tiếp, khóa tham chiếu, đánh dấu là luồng) được giữ, với ràng buộc bên tham gia phải là HTTT thành viên, luồng hoặc DU có thật.

**Phủ.** FR-10-025…028; UC-10-07, 08; API-10-032…041, 092…095; UI-10-09, 10; BR-10-003, 017; LGC-HUB-010, 011.

#### TC-10-037 · Đăng ký bên phát HTTT và bên nhận là luồng <!--k:party-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-10-026, 027 · API-10-033, 038 · UI-10-09, 10 · UC-10-07 · BR-10-017 · LGC-HUB-010, 011
- **Tiền điều kiện / dữ liệu** U-T68-IE1; SIM-PH01 có `HT-QLDD` `ACTIVE`; SIM-PH04 có luồng `dkkd-tong-hop`.
- **Bước**
  1. `POST /publishers` với `publisherCode = tc-ht-qldd`, `partyType = SYSTEM`, `systemCode = HT-QLDD`, `commType = HTTP_PUBLISH`, `referenceKey = PUB_QLDD_01`.
  2. `POST /subscribers` với `subscriberCode = tc-luong-tong-hop`, `partyType = FLOW`, `flowCode = dkkd-tong-hop`, `commType = INTERNAL_KAFKA`.
  3. Mở UI-10-10.
- **Mong đợi** Bước 1 `201`, `status = ACTIVE`, `clientId` lấy từ PH-01, chưa có publication. Bước 2 `201`, `isFlow = true`, `kafkaPrincipal` là principal nội bộ của tenant. Bước 3 cột "Loại" của dòng mới hiện "Luồng tích hợp". KT: có.

#### TC-10-038 · Tổ hợp không hợp lệ, HTTT không hoạt động, luồng ngừng, DU lạ, trùng cặp <!--k:party-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-10-026, 027 · API-10-033, 038 · ERR-10-002, 003, 021, 022, 023, 024, 028, 044 · BR-10-017
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-SV; U-T01-IE (T01 tắt Kafka ngoài).
- **Bước**
  1. Bên phát `SYSTEM` với `commType = WEBHOOK_PUSH`; bên nhận `FLOW` với `commType = HTTP_PULL`; bên phát `LEGACY_BRIDGE`.
  2. `systemCode = HT-DUNG` (`SUSPENDED`).
  3. `flowCode = luong-cu` (`RETIRED`); `serviceCode = dh-khong-co`.
  4. Bên phát thứ hai cho cặp (`HT-DKKD`, `HTTP_PUBLISH`).
  5. U-T01-IE đăng ký bên phát `KAFKA_NATIVE`.
  6. U-T68-SV đăng ký bên phát cho HTTT của `SO-TC`.
- **Mong đợi** Bước 1 `400` ERR-10-003. Bước 2 `422` ERR-10-021. Bước 3 `422` ERR-10-022, ERR-10-023. Bước 4 `409` ERR-10-024. Bước 5 `422` ERR-10-028. Bước 6 403-TC. KT: không.

#### TC-10-039 · Danh sách và chi tiết bên tham gia <!--k:party-list-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-10-025 · API-10-032, 034, 037, 039 · UI-10-09, 10 · LGC-HUB-010, 011
- **Tiền điều kiện / dữ liệu** U-T68-VW; dữ liệu mục 2.3.
- **Bước**
  1. `GET /publishers?q=PUB_DKKD&partyType=SYSTEM`.
  2. `GET /subscribers?projectCode=dang-ky-kinh-doanh&status=ACTIVE`.
  3. `GET /subscribers/ht-thue`.
- **Mong đợi** Bước 1 tìm theo `referenceKey` ra `ht-dkkd`. Bước 2 có `ht-thue`, `ht-bhxh`, `ht-kho-bac`, `luong-dong-bo-thue` với số subscription theo trạng thái. Bước 3 có trạng thái HTTT ở PH-01, `commType`, `lastActiveAt`.

#### TC-10-040 · Sửa, tạm ngừng, tiếp tục, ngừng dùng bên phát <!--k:party-lifecycle-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, KT
- **Truy vết** FR-10-028 · API-10-035, 036, 092, 093 · EVT-10-07 · UC-10-08 · NFR-10-009 · LGC-HUB-010
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-SO; PB-DKKD có publication `ACTIVE`.
- **Bước**
  1. IE1 `PATCH /publishers/ht-dkkd` đổi `name`, `referenceKey`.
  2. SO `:suspend` với lý do "Nghi lộ khóa client"; HTTT phát ngay sau đó.
  3. SO `:resume`.
  4. Bên phát thử không còn quan hệ: IE1 `:retire`.
- **Mong đợi** Bước 1 `200`. Bước 2 bên phát `SUSPENDED` với `suspendSource = SECURITY`, publication `SUSPENDED`; lượt phát bị từ chối 403-PQ trong ≤ 60 giây; EVT: `publication.state-changed`. Bước 3 về `ACTIVE`, publication `ACTIVE` không cần duyệt lại. Bước 4 `RETIRED`, mã không dùng lại được (ERR-10-002 khi tạo lại). KT: có cho cả bốn bước.

#### TC-10-041 · Đổi trường bất biến; SO tiếp tục bên do người khác tạm ngừng; trạng thái sai <!--k:party-lifecycle-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-10-028 · API-10-035, 036, 094, 095 · ERR-10-003, 006, 009
- **Tiền điều kiện / dữ liệu** U-T68-IE1, U-T68-SO, U-T68-TO; SB-THUE.
- **Bước**
  1. `PATCH /subscribers/ht-thue` đổi `partyType`, `systemCode`, `commType`.
  2. TO `:suspend` SB-THUE; SO gọi `:resume`.
  3. `:resume` bên nhận đang `ACTIVE`; `:suspend` không lý do.
- **Mong đợi** Bước 1 `400` ERR-10-003 cho cả ba trường. Bước 2 SO nhận 403-PQ (SO chỉ tiếp tục đối tượng `suspendSource = SECURITY`). Bước 3 `409` ERR-10-006; `400` ERR-10-009.

