---
ma_tai_lieu: D05-02-PH10
ten: Kịch bản và test case phân hệ PH-10 Sự kiện
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-10
mo_ta: Kịch bản và 158 test case chức năng, phi chức năng, nghiệm thu tương đương Hub Pulsar của phân hệ Sự kiện, mỗi ca một khối đặc tả có mục đích, các bước, kết quả mong đợi kèm câu thông báo và hậu điều kiện, cùng ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH10 FRS; D02-04-PH10 Use case; D03-02-PH10 SDD; D03-03-PH10 CSDL; D03-04-PH10 API; D03-06-PH10 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH10 · Kịch bản và test case Sự kiện

## Tóm tắt cho hội đồng thẩm định

Phần này viết cho hội đồng thẩm định: tài liệu chứng minh điều gì, phạm vi và độ phủ ra sao, dựa trên căn cứ nào và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản và số ca được công cụ sinh lại từ chính các ca nên luôn khớp với chương 4 và chương 5.

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-10 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH10 bản 0.2.
- Không mất chức năng nào của Hub Apache Pulsar hệ cũ: dashboard đếm publisher, subscriber, project, topic; sơ đồ kết nối; quản lý project, topic, publisher, subscriber, publication, subscription; danh mục `type_of_comm`, `routing_mode` (LGC-HUB-001…004, 007…014), nhóm Message Broker của Tooling (LGC-TOOL-010) và event message của Bus (LGC-BUS-039). Hai mục LGC-HUB-005, 006 (biểu đồ CPU, bộ nhớ) chuyển sang PH-13 và chỉ được kiểm ở mức có liên kết dẫn chiếu.
- Không có đường nào để một tỉnh đọc, phát hay nhận sự kiện của tỉnh khác, để một bên phát, bên nhận chưa được duyệt dùng được topic, hay để một sự kiện đã ghi bền bị mất mà không có dấu vết trong DLQ.

**Phạm vi.** Gồm <!--gen:so-ts-->35<!--/gen--> kịch bản với <!--gen:so-tc-->158 (TC-10-001…158; 110 ca P1)<!--/gen--> test case và 10 kịch bản nghiệm thu người dùng (UAT-01…10). Mỗi FR mức M (66 FR) có ít nhất một ca dương và một ca âm; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph10/tools/gen_matrix.py`, kèm bảng `.xlsx` theo mẫu nghiệm thu và tệp Gherkin.

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

Chương này nói tài liệu dùng để làm gì, kiểm những gì của PH-10, ai đọc phần nào, thuật ngữ riêng của kiểm thử sự kiện, tài liệu được dẫn chiếu và cách sắp xếp các chương. Người đọc lần đầu nên đọc hết chương này trước khi vào chương 4 và 5.

### 0.1. Mục đích

Tài liệu là tập 7 của bộ PH-10: đặc tả kiểm thử (test specification) của phân hệ Sự kiện, lập theo ISO/IEC/IEEE 29119-3. Đặc tả thiết kế kiểm thử thể hiện qua các kịch bản `TS-10-nn`, đặc tả ca kiểm thử qua các khối đặc tả `TC-10-nnn`, đặc tả thủ tục qua các bước của từng ca, thủ tục thủ công ở chương 6 và mẫu mã tự động ở chương 9. Kế hoạch kiểm thử tổng thể của Datahub ở D05-01; tài liệu này chỉ đi sâu vào PH-10 và kế thừa mọi quy định chung từ đó.

Tài liệu phục vụ ba việc. Thứ nhất, kiểm thử viên chạy và ghi kết quả từng ca ngay trên SIT với bộ dữ liệu chương 2, không phải hỏi lại; lập trình viên viết ca tự động cùng lúc với mã ở W3, W4. Thứ hai, hội đồng thẩm định có bằng chứng rằng mọi FR mức M có ca dương và ca âm, mọi quy tắc nghiệp vụ, mã lỗi và yêu cầu phi chức năng đều được kiểm. Thứ ba, cán bộ vận hành Hub cũ có bộ nghiệm thu (chương 7) để xác nhận hệ mới không làm mất chức năng của Hub Apache Pulsar.

### 0.2. Phạm vi

Tài liệu phủ toàn bộ phạm vi chức năng của PH-10 đã chốt ở FRS D02-03-PH10: dự án tích hợp, topic và cấp phát qua GitOps, lược đồ sự kiện và tương thích ở Apicurio, bên phát và bên nhận, publication, subscription, phát qua API và Kafka, giao nhận ĐẨY có ký HMAC, giao nhận KÉO qua API và Kafka ngoài, thử lại và DLQ, phát lại có duyệt bốn mắt, độ trễ tiêu thụ và cảnh báo, dashboard và sơ đồ kết nối, danh mục và hạn mức, hợp đồng với PH-04, PH-05, xuất nhập khai báo và di trú từ Pulsar. Yêu cầu phi chức năng (cô lập tenant, phân quyền, kiểm toán và bí mật, hiệu năng, chịu lỗi, truy cập) được kiểm ở chương 5.

Ngoài phạm vi là phần riêng của PH-01 (HTTT), PH-03 (APISIX), PH-04 (luồng), PH-12 (cấp token) và PH-13 (lưu kiểm toán, chỉ số cụm); các phân hệ này được kiểm ở tài liệu của chúng, ở đây chỉ kiểm phần PH-10 gọi tới hoặc nhận từ chúng.

### 0.3. Người đọc

| Người đọc | Đọc | Dùng để |
|---|---|---|
| Kiểm thử viên | Chương 1, 2, kịch bản được giao ở chương 4, 5 | Chạy ca, ghi kết quả vào `ph10/D05-02-PH10-test-case.xlsx` |
| Kỹ sư | Chương 4 theo FR mình làm, chương 9 | Viết ca tự động (UT, IT, RT, API, KT, E2E) cùng lúc với mã |
| Cán bộ ATTT | TS-10-14, 30…32, mục 1.6 | Kiểm chứng cô lập tenant, phân quyền, chữ ký webhook, an toàn bí mật |
| Cán bộ vận hành Hub cũ, chủ đầu tư | Chương 7 | Nghiệm thu người dùng tương đương hệ cũ |
| Hội đồng thẩm định | Tóm tắt, chương 3, 8 | Kiểm tra độ phủ |

: Người đọc và phần tài liệu nên đọc

### 0.4. Thuật ngữ và viết tắt

Thuật ngữ chung của bộ tài liệu ở D00-01 và FRS D02-03-PH10 §1.4; ký hiệu viết tắt trong kết quả mong đợi (403-PQ, 401-XT, 403-TC, 404-ẩn, KT, EVT, Mồi sạch) ở mục 1.5. Bảng dưới chỉ nêu thuật ngữ dùng nhiều trong tài liệu này.

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| Topic | Kênh sự kiện Kafka có lược đồ, tên theo quy ước `{tenant}.{miền}.{thực thể}.{sự kiện}.v{n}` |
| Publication, subscription | Quan hệ được duyệt cho phép một bên phát ghi lên topic, một bên nhận đọc từ topic |
| ĐẨY, KÉO | Hai chế độ giao nhận: Datahub gọi webhook của bên nhận (push), hoặc bên nhận tự lấy qua API hay Kafka (pull) |
| DLQ | Hàng sự kiện chết (dead letter queue): nơi giữ sự kiện không giao được để tra cứu, loại bỏ hoặc phát lại |
| Control plane, data plane | Phần quản trị khai báo (`/api/event/v1`) và phần chuyển sự kiện (`/event/v1`, Kafka) |
| Lease, cursor | Lượt thuê một lô sự kiện khi kéo và mã vị trí đọc có ký để xác nhận lô đó |
| Lag | Độ trễ tiêu thụ: số bản tin hoặc số giây bên nhận chậm so với đầu topic |
| Bốn mắt | Người tạo hoặc gửi yêu cầu không được tự duyệt yêu cầu đó |
| Cụm áp dụng | Argo CD đã đồng bộ và Strimzi báo `Ready` (mục 1.5) |
| TS, TC, UAT | Kịch bản kiểm thử, ca kiểm thử (test case), kịch bản nghiệm thu người dùng |
| Ca dương, ca âm | Ca kiểm luồng đúng và ca kiểm luồng sai, bị từ chối hoặc tấn công |
| P1, P2, P3 | Mức ưu tiên ca: chặn phát hành, quan trọng, bổ sung |
| GĐ | Giả định về quy mô và bối cảnh, dùng khi chưa có số liệu thật |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 0.5. Tài liệu tham chiếu

Tên trường, enum, trạng thái, quyền, tham số và mã màn lấy đúng Phụ lục A của FRS; câu thông báo theo mã lỗi lấy từ D03-06-PH10 §5.3 và §18.4. Chỗ tập này cần mà nguồn chưa có được ghi ở chương 10.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D02-03-PH10 | [FRS Sự kiện](../../02-yeu-cau/frs/D02-03-PH10-frs-su-kien.md) | FR, BR, NFR, ERR, enum, máy trạng thái (§4), Phụ lục A |
| D02-04-PH10 | [Use case Sự kiện](../../02-yeu-cau/use-case/D02-04-PH10-use-case-su-kien.md) | Luồng của kịch bản TS-10-01…29 |
| D03-02-PH10 | [SDD Sự kiện](../../03-thiet-ke/sdd/D03-02-PH10-sdd-su-kien.md) | Thành phần, bộ giao nhận, cầu nối |
| D03-03-PH10 | [CSDL Sự kiện](../../03-thiet-ke/csdl/D03-03-PH10-csdl-su-kien.md) | Bảng, RLS, `ph10_isolation_test.sql` |
| D03-04-PH10 | [API Sự kiện](../../03-thiet-ke/api/D03-04-PH10-api-su-kien.md) | API-10, EVT-10, bảng mã lỗi ERR-10 (§6) |
| D03-06-PH10 | [Màn hình Sự kiện](../../03-thiet-ke/uiux/D03-06-PH10-man-hinh-su-kien.md) | UI-10, câu thông báo theo mã lỗi |
| D02-08 | [Ma trận phân quyền](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md) | Vai trò, quyền `PERM-10-*` |
| D03-10 | [Thiết kế đa tenant](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md) | Cô lập tenant, ACL Kafka theo tiền tố |
| D05-01 | [Kế hoạch kiểm thử tổng thể](../D05-01-master-test-plan.md) | Chiến lược, mẫu báo cáo, cổng phát hành |
| D04-02 | [Quy trình kỹ thuật](../../04-lap-trinh/D04-02-quy-trinh-ky-thuat.md) | Cổng CI chạy ca tự động |
| ISO/IEC/IEEE 29119-3; OWASP ASVS 5.0; WCAG 2.2 | Tiêu chuẩn | Cấu trúc tài liệu kiểm thử, ca bảo mật, ca truy cập |

: Tài liệu tham chiếu

### 0.6. Cấu trúc tài liệu

| Chương | Nội dung |
|---|---|
| Tóm tắt | Mục tiêu, phạm vi, căn cứ, sáu nhóm ca bắt buộc đạt 100 % |
| 0. Giới thiệu | Mục đích, phạm vi, người đọc, thuật ngữ, tham chiếu, cấu trúc |
| 1. Phạm vi, chiến lược và tổ chức | Đối tượng, mức, môi trường, tiêu chí vào ra, quy ước khối đặc tả ca, quản lý lỗi |
| 2. Dữ liệu kiểm thử | Tenant, người dùng, đối tượng nạp sẵn, hệ thống giả lập, tệp mẫu |
| 3. Tổng quan kịch bản | Bảng danh sách 35 kịch bản kèm UC và số ca (trước phần chi tiết), máy trạng thái được kiểm |
| 4. Kịch bản và test case chức năng | TS-10-01…29, mỗi ca một khối đặc tả |
| 5. Kịch bản phi chức năng và xuyên suốt | TS-10-30…35, mỗi ca một khối đặc tả |
| 6. Thủ tục kiểm thử thủ công | Khám phá, diễn tập chuyển từ Pulsar, diễn tập sự cố, truy cập |
| 7. Nghiệm thu người dùng | UAT-01…10 tương đương Hub cũ |
| 8. Ma trận truy vết | FR, LGC, BR, ERR, NFR tới TC, sinh bằng công cụ |
| 9. Tự động hóa | Tổ chức mã kiểm thử, mẫu mã, chuỗi công cụ sinh ma trận, Gherkin, bảng tính |
| 10. Đề nghị bổ sung và câu hỏi mở | Đề nghị cho FRS, đề nghị đồng bộ câu thông báo, câu hỏi mở |

: Cấu trúc tài liệu

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

Chương này viết cho trưởng nhóm kiểm thử và kỹ sư: kiểm thành phần nào, ở mức nào, trên môi trường nào, khi nào bắt đầu và khi nào coi là xong, cách trình bày một ca và cách quản lý lỗi. Quy định chung (vai trò trong đội kiểm thử, mẫu báo cáo) kế thừa D05-01.

### 1.1. Đối tượng kiểm thử

Đối tượng kiểm thử là control plane, cổng sự kiện, bộ giao nhận, data plane Kafka, chuỗi cấp phát, lớp quyền, CSDL, bộ nhớ đệm và giao diện của PH-10.

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

: Thành phần của PH-10 là đối tượng kiểm thử

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca.

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

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường được dùng, khác nhau ở cấu hình cụm và bộ dữ liệu.

| Môi trường | Mô tả | Dùng cho |
|---|---|---|
| SIT | K8s một cụm; tenant T68, T01, T90…T99; Kafka ba broker, Apicurio, Keycloak, OPA, OpenBao, Valkey, Argo CD thật; Pulsar 3 độc lập giả lập Hub cũ; HTTT giả lập mục 2.4 | API, KT, E2E, RT, Chaos |
| PERF | Cấu hình `QM-VUA` theo D03-09, dữ liệu GĐ-01…07; Kafka ba broker, đĩa NVMe | k6, chaos đo NFR-10-006 |
| UAT | Như SIT; dữ liệu sao từ bản xuất CSDL cấu hình Hub cũ của tỉnh thí điểm đã làm sạch | UAT mục 7 |

: Môi trường kiểm thử và mục đích dùng

### 1.4. Tiêu chí vào và ra

Tiêu chí vào bảo đảm nguồn, môi trường và dữ liệu sẵn sàng; tiêu chí ra là điều kiện để đợt kiểm thử đạt và cho phép phát hành.

| Loại | Tiêu chí |
|---|---|
| Vào | D02-03-PH10 bản 0.2 ở trạng thái duyệt; DDL `ph10_event.sql` áp được và `ph10_isolation_test.sql` đạt; hợp đồng OpenAPI, AsyncAPI qua CT; bộ dữ liệu mục 2 nạp xong |
| Ra | 100 % ca P1 đạt; ≥ 95 % ca P2 đạt, ca còn lại có lỗi mở mức Thấp; 0 lỗi mở mức Nghiêm trọng, Cao; ma trận mục 8 không có FR mức M thiếu ca dương hoặc ca âm; TS-10-30, 31, 32 đạt 100 % |

: Tiêu chí vào và ra của đợt kiểm thử

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-10-nn`, test case `TC-10-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Từ bản 0.2, mỗi test case là một khối đặc tả `::: dac-ta` (bộ xuất dựng thành bảng hai cột), thống nhất với D05-02-PH05, PH19. Tiêu đề ca có dạng `#### TC-10-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và tham chiếu chéo `[[tc:khóa]]`, không in ra bản xuất. Khối có các trường theo thứ tự trong bảng dưới.

| Trường | Nội dung |
|---|---|
| **Mục đích.** | Ca chứng minh điều gì, theo FR (hoặc NFR) chính |
| **Loại.** | Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập; loại chính ghi trước |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung |
| **Tự động.** | Mức kiểm thử ở mục 1.2: UT, IT, DB, RT, CT, API, KT, E2E, k6, Chaos, ZAP, hoặc "Thủ công" |
| **Truy vết.** | FR, BR, API, UI, ERR, EVT, UC, NFR, LGC, quyền, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu kiểm thử ở chương 2 |
| **Các bước.** | Danh sách đánh số. Đường dẫn control plane tương đối với `/api/event/v1`; data plane ghi đủ `/event/v1/…` |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán, theo từng bước khi khác nhau |
| **Thông báo hiển thị.** | Câu người dùng hoặc bên gọi nhìn thấy cho từng mã lỗi của ca (chỉ có ở ca có mã lỗi) |
| **Hậu điều kiện.** | Trạng thái dữ liệu sau khi chạy; ca nào dùng lại dữ liệu của ca này |

: Các trường của khối đặc tả test case

Câu ở trường "Thông báo hiển thị" lấy từ D03-06-PH10 §5.3 cho mã control plane (001…054), từ §18.4 (nhãn ở cột "Mã lỗi" của bảng lượt lỗi và DLQ) cho mã giao nhận 111…120. Với mã data plane 101…110 và 121, câu là `detail` của thân lỗi RFC 9457 trả cho bên gọi máy; các câu này và câu của ERR-10-053, 054 do tập này viết mới, chờ đồng bộ về D03-04-PH10, D03-06-PH10 (mục 10.1). Kiểm thử viên đối chiếu mã lỗi và mã HTTP là bắt buộc; câu hiển thị kiểm ở ca E2E, ở ca API chỉ kiểm `detail` khi máy chủ không thay tham số.

Ví dụ một khối (rút từ TC-10-004; trong ví dụ mã ca viết `TC-10-nnn` để công cụ không đọc nhầm thành ca thật):

```markdown
#### TC-10-nnn · Sửa dự án có If-Match; mã bất biến <!--k:khoa-ca-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-004 (Sửa dự án).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-004 · API-10-004 · ERR-10-003, 007.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IE2; dự án `tc-lien-thong-thue`.

**Các bước.**

1. IE1 `PATCH /projects/tc-lien-thong-thue` đổi `name`, `If-Match` đúng.
2. IE2 gửi `PATCH` với `ETag` cũ.

**Kết quả mong đợi.** Bước 1 `200`, `ETag` mới. Bước 2 `412` ERR-10-007 có `currentEtag`.

**Thông báo hiển thị.** ERR-10-007 hộp xung đột phiên bản ST-13 "Đối tượng đã được {người} cập nhật lúc {giờ}".

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::
```

Trong kết quả mong đợi, các ký hiệu viết tắt sau được dùng để câu ngắn mà vẫn kiểm chứng được.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-10-054 ở control plane (thiếu quyền `PERM-10-*` hoặc scope máy `event:*`), ERR-10-102 ở data plane (thiếu scope `topic:{topicName}:*` hoặc quan hệ không `ACTIVE`); theo FRS 0.3 |
| 401-XT | `401` với ERR-10-053 ở control plane, ERR-10-101 ở data plane |
| 403-TC | `403` với ERR-10-044 (đối tượng ngoài phạm vi tổ chức của OR, SV) |
| 404-ẩn | `404` với ERR-10-001 ở control plane, ERR-10-103 ở data plane; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` (BR-10-001) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa bí mật ký, nội dung sự kiện |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{thực-thể}.{sự-kiện}` | Đúng một bản tin trên topic `t68.event.{thực-thể}.{sự-kiện}.v1` (CloudEvents, `ce_type = vn.datahub.event.{thực-thể}.{sự-kiện}`, có `dhtenant`) |
| EVT: không | Sau 10 giây không có dòng mới trong `ph10_event.outbox_event` và không có bản tin trên topic `t68.event.*` liên quan |
| Mồi sạch | Tìm chuỗi `whsec_` của khóa ký thử và chuỗi `DH-CANARY-{ca}` trong phản hồi API, log 5 phút, vết OTel, bảng `ph10_event.*`, outbox, Kafka, tệp xuất, kiểm toán: không thấy |
| Cụm áp dụng | Argo CD đã đồng bộ commit tương ứng ở `dh-config-t68` và Strimzi báo `Ready` cho `KafkaTopic` hoặc `KafkaUser` |

: Ký hiệu viết tắt trong kết quả mong đợi

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

: Tenant kiểm thử

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

: Người dùng kiểm thử

Tài khoản dịch vụ (`client_credentials` + `private_key_jwt`):

| Mã | Chủ thể | Scope |
|---|---|---|
| S-PH05 | `dh-integration` mô-đun PH-05 | `event:topic-register` |
| S-PH04 | `dh-integration` mô-đun PH-04 | `event:permission-check` |
| S-DU-DATA | `dh-data` (PH-07) | `event:topic-register` |
| S-RT-T68, S-RT-T01 | `dh-runtime-t68`, `dh-runtime-t01` | `event:runtime-config`, `event:replay` |
| S-PH18 | PH-18 | `event:dlq-read`, `event:replay` |
| S-PH13 | PH-13 | `event:metrics-read` |

: Tài khoản dịch vụ kiểm thử

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
| SUB-PUSH | Subscription `ht-thue-dn-cap-phep`: SB-THUE, TP-CP, `PUSH`, `endpointUrl = https://thue.sim.test/hooks/dh`, `workerCount = 3`, `maxRetries = 3`, backoff 100 ms ×2 tối đa 2 s (giảm cho kiểm thử), `DEAD_LETTER` đặt rõ (mặc định FRS 0.3 cho topic có thứ tự là `BLOCK`) | `ACTIVE`, nhóm `dh-sub-t68-ht-thue-dn-cap-phep`, khóa ký `ACTIVE` | Giao đẩy, DLQ, phát lại |
| SUB-PULL | Subscription `ht-bhxh-dn-cap-phep`: SB-BHXH, TP-CP, `PULL_API`, `maxBatch = 100`, `leaseSeconds = 30` | `ACTIVE` | Kéo API |
| SUB-KAFKA | Subscription `ht-kho-bac-dn-cap-phep`: SB-KB, TP-CP, `PULL_KAFKA` | `ACTIVE`, nhóm `dh-ext-t68-ht-kho-bac-dn-cap-phep` | Kéo Kafka |
| SUB-FLOW | Subscription `luong-dong-bo-thue-dn-cap-phep`: SB-FLOW, TP-CP, `INTERNAL` | `ACTIVE`, nhóm `dh-flow-t68-dkkd-dong-bo-thue` | Nội bộ, lag |
| SUB-KS | Subscription `ht-thue-khai-sinh`: SB-THUE, TP-KS, `PUSH`, `BLOCK`, `legalBasis` có | `ACTIVE` | Chặn khi lỗi, DLQ mã hóa |
| DLQ-30 | 30 mục DLQ `NEW` của SUB-PUSH (ERR-10-112 × 20, ERR-10-113 × 10) | `NEW` | DLQ |

: Đối tượng nạp sẵn ở T68

Ở T01 có bản sao trùng mã của P-DKKD, TP-CP (tên `t01.…`), PB-DKKD, SUB-PUSH để kiểm 404-ẩn.

### 2.4. Hệ thống giả lập

| Mã | Thành phần | Hành vi điều khiển được |
|---|---|---|
| SIM-WH | WireMock HTTPS `thue.sim.test`, `hooks.sim.test` (trong danh sách egress) | Trả 200, 204, 400, 410, 429 có `Retry-After`, 5xx, chậm n ms; ghi lại tiêu đề, thân; tự xác minh chữ ký với khóa nạp vào; trả `WebHook-Allowed-Origin` đúng, sai hoặc thiếu |
| SIM-WH-BAD | Các đích xấu | `http://plain.sim.test`, `https://selfsigned.sim.test` (chứng thư tự ký), `https://redirect.sim.test` (302 sang `10.0.0.5`), `https://rebind.sim.test` (DNS trả IP công cộng lần đầu, `10.96.0.10` lần sau), `https://ngoai-egress.example` |
| SIM-PH01 | Giả lập PH-01 | Danh sách HTTT `HT-DKKD`, `HT-THUE`, `HT-BHXH`, `HT-KBNN`, `HT-QLTC` `ACTIVE`, `HT-DUNG` `SUSPENDED`; phát EVT-01-03 `{tenant}.connect.system.state-changed.v1` khi đổi trạng thái HTTT |
| SIM-PH04 | Giả lập PH-04 | Luồng `dkkd-dong-bo-thue`, `dkkd-tong-hop` hợp lệ, `luong-cu` `RETIRED`; phát EVT-04-09 |
| SIM-PH05 | Giả lập PH-05 phía gọi | Gọi API-10-009, 023, 018 với S-PH05; phát EVT-05-11 |
| SIM-PULSAR | Apache Pulsar 3 độc lập | Tenant `lgsp`, namespace `dkkd`, topic `persistent://lgsp/dkkd/doanh-nghiep-cap-phep` có producer và subscriber cũ (`Shared`, 2 consumer) |
| SIM-GIT | Gitea trong SIT | Kho `dh-config-t68`; có thể đặt chỉ đọc hoặc dừng để kiểm ERR-10-029 |

: Hệ thống giả lập dùng trong kiểm thử

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

: Tệp mẫu dùng trong các ca

### 2.6. Nguyên tắc dữ liệu

Không dùng mã số doanh nghiệp, số định danh, số điện thoại thật; khóa nghiệp vụ dùng dải giả `0999…`. Khóa ký thử có tiền tố `whsec_` và được đăng ký vào bộ dò mồi. Mỗi ca tạo đối tượng có tiền tố `tc-` (mã) hoặc miền `tc` (topic `t68.tc.….v1`) và tự dọn sau khi chạy, trừ ca cần giữ mã để kiểm BR-10-003.

## 3. Tổng quan kịch bản kiểm thử

Chương này là bảng danh sách phần tử trước phần chi tiết: mỗi kịch bản kèm use case được phủ và số ca, sau đó là các máy trạng thái được kiểm. Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-10-01 | Dự án tích hợp | UC-10-01 | 5 |
| TS-10-02 | Tạo topic và gửi duyệt | UC-10-02 | 6 |
| TS-10-03 | Duyệt topic và cấp phát qua GitOps | UC-10-03 | 5 |
| TS-10-04 | Thay đổi cấu hình topic đang hoạt động | UC-10-04 | 5 |
| TS-10-05 | Ngừng topic và phiên bản chính mới | UC-10-05 | 5 |
| TS-10-06 | Lược đồ sự kiện: soạn, kiểm tra, duyệt | UC-10-06 | 6 |
| TS-10-07 | Tương thích lược đồ Apicurio và topic .v{n+1} | — | 4 |
| TS-10-08 | Bên phát và bên nhận | UC-10-07, 08 | 5 |
| TS-10-09 | Đồng bộ trạng thái với PH-01 và PH-04 | UC-10-08 | 2 |
| TS-10-10 | Publication: đề nghị, duyệt, cấp scope và ACL | UC-10-09 | 3 |
| TS-10-11 | Phát sự kiện qua API phát | UC-10-10 | 6 |
| TS-10-12 | Phát trực tiếp qua Kafka và giám sát tuân thủ | UC-10-11 | 3 |
| TS-10-13 | Subscription: đề nghị, xác minh endpoint, duyệt | UC-10-12, 13 | 5 |
| TS-10-14 | Giao nhận ĐẨY: webhook ký HMAC và khóa ký | UC-10-14, 17 | 6 |
| TS-10-15 | Thử lại giãn dần, ngắt mạch và DLQ | UC-10-14 | 5 |
| TS-10-16 | Vận hành subscription: tạm dừng, sửa, thu hồi, thống kê | UC-10-16 | 5 |
| TS-10-17 | Giao nhận KÉO qua API: lease và cursor | UC-10-15 | 5 |
| TS-10-18 | Giao nhận KÉO qua Kafka ngoài: SASL OAUTHBEARER | UC-10-15 | 3 |
| TS-10-19 | Giao nhận nội bộ và hợp đồng PH-04 | UC-10-25 | 4 |
| TS-10-20 | DLQ tầng sự kiện: tra cứu, loại bỏ, phát lại mục DLQ | UC-10-18 | 4 |
| TS-10-21 | Phát lại theo khoảng có duyệt bốn mắt | UC-10-19 | 5 |
| TS-10-22 | Độ trễ tiêu thụ và cảnh báo | UC-10-20 | 4 |
| TS-10-23 | Dashboard và sơ đồ kết nối | UC-10-21 | 3 |
| TS-10-24 | Danh mục, hạn mức và tham số | UC-10-22 | 3 |
| TS-10-25 | Hợp đồng PH-05: topic CDC tự duyệt và thay đổi lược đồ | UC-10-23 | 4 |
| TS-10-26 | DU nội bộ đăng ký topic SYSTEM và topic nền tảng | UC-10-24 | 2 |
| TS-10-27 | Xuất và nhập khai báo | UC-10-28 | 2 |
| TS-10-28 | Di trú từ Pulsar: kiểm kê và ánh xạ | UC-10-26 | 2 |
| TS-10-29 | Cầu nối Pulsar, đối chiếu, chuyển hẳn và quay lui | UC-10-27 | 5 |
| TS-10-30 | Cô lập tenant: RLS, ACL Kafka theo tiền tố, Apicurio, OPA | — | 6 |
| TS-10-31 | Phân quyền theo ma trận PERM-10 và bốn mắt | — | 5 |
| TS-10-32 | Kiểm toán và an toàn bí mật | — | 3 |
| TS-10-33 | Hiệu năng, tải và quy mô | — | 13 |
| TS-10-34 | Chịu lỗi, hỗn loạn và phục hồi | — | 5 |
| TS-10-35 | Truy cập và giao diện | — | 4 |
| **Tổng** | | | **158** (110 ca P1) |

: Danh sách 35 kịch bản kèm use case và số ca
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

: Chuyển trạng thái hợp lệ và bị cấm được kiểm thử

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ (FR, UC, API, UI, BR, LGC), sau đó là các ca, mỗi ca một khối đặc tả theo mục 1.5. Kịch bản TS-10-01…29 cùng số thứ tự với nhóm use case ở cột UC của bảng 3.1.

### TS-10-01 · Dự án tích hợp

**Mục tiêu.** Xác nhận quản lý dự án thay "Quản lý project" của Hub cũ: mã bất biến, không trùng từ dành riêng của route, lưu trữ thay xóa, đếm topic và bên tham gia đúng.

**Phủ.** FR-10-001…005, 065; UC-10-01; API-10-001…006; UI-10-02, 03, 04; BR-10-003; LGC-HUB-008.

#### TC-10-001 · Tạo dự án hợp lệ và xem chi tiết <!--k:prj-create-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-003 (Tạo dự án tích hợp).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-003, 002 · API-10-002, 003 · UI-10-04, 03 · UC-10-01 · LGC-HUB-008.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; tenant T68 còn dưới `10.quota.max-projects`.

**Các bước.**

1. Mở UI-10-04 (`/tich-hop/du-an/moi`), nhập mã `tc-lien-thong-thue`, tên "Liên thông thuế thử", tổ chức `SO-KHDT`, nhãn `doanh-nghiep`; bấm "Tạo".
2. `GET /projects/tc-lien-thong-thue`.

**Kết quả mong đợi.** Bước 1 gọi `POST /projects` có `Idempotency-Key`, trả `201`, `Location`, `ETag`; màn chuyển sang UI-10-03. Bước 2: `status = ACTIVE`, `ownerUser` là người tạo, `topicCount = 0`, `publisherCount = 0`, `subscriberCount = 0`. KT: có (tạo dự án). EVT: không.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-004.
:::

#### TC-10-002 · Tạo dự án sai mẫu, từ dành riêng, trùng mã, ngoài tổ chức, vượt hạn mức <!--k:prj-create-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-003 (Tạo dự án tích hợp).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-003 · API-10-002 · ERR-10-002, 003, 011, 039, 044 · BR-10-003.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; U-T68-SV (tổ chức `SO-KHDT`); P-CU đã lưu trữ ở bước chuẩn bị; T92 đã có 200 dự án giả (đặt `10.quota.max-projects = 200`).

**Các bước.**

1. `POST /projects` với `projectCode = "Tc_Hoa"`.
2. Lặp với `projectCode` lần lượt `moi`, `tong-quan`, `nhap`, `di-tru`, `ben-phat`, `ben-nhan`.
3. Lặp với `dang-ky-kinh-doanh` và `thu-nghiem-cu` (đã `ARCHIVED`).
4. U-T68-SV gửi `ownerOrgCode = SO-TC`.
5. U-T90-IE trên T92 tạo dự án thứ 201.
6. Người dùng IE của T94 (tenant tạm ngừng) tạo dự án.

**Kết quả mong đợi.** Bước 1, 2 `400` ERR-10-003 với `errors[0].field = projectCode`. Bước 3 `409` ERR-10-002 (mã đã lưu trữ cũng không dùng lại). Bước 4 403-TC. Bước 5 `422` ERR-10-011. Bước 6 `423` ERR-10-039. KT: không.

**Thông báo hiển thị.** ERR-10-002 "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."; ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-011 "Vượt hạn mức của tenant: {tên hạn mức} đang dùng {đã dùng}/{trần}."; ERR-10-039 "Tenant đang tạm ngừng hoặc đóng băng thay đổi tới {thời điểm}."; ERR-10-044 ST-07 "Đối tượng ngoài phạm vi tổ chức của bạn."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-003 · Danh sách dự án lọc, sắp xếp, đếm và facets <!--k:prj-list-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-001 (Liệt kê, tìm kiếm và lọc dự án tích hợp).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-10-001 · API-10-001 · UI-10-02 · ERR-10-049.

**Tiền điều kiện, dữ liệu.** U-T68-VW; P-DKKD, P-HT, P-CU.

**Các bước.**

1. `GET /projects?q=kinh doanh&status=ACTIVE&sort=topicCount,desc`.
2. `GET /projects?size=201`.
3. U-T68-OR gọi `GET /projects`.

**Kết quả mong đợi.** Bước 1 `200`, có `dang-ky-kinh-doanh` với `topicCount = 4`, `publisherCount`, `subscriberCount` đếm theo quan hệ `ACTIVE`, `maxLagSeconds` có giá trị; `facets.status` đếm đúng. Bước 2 `400` ERR-10-049. Bước 3 chỉ trả dự án có HTTT của `SO-TC` tham gia (P-DKKD qua SB-TC chưa có subscription thì không có). Tìm không dấu "kinh doanh" khớp tên có dấu.

**Thông báo hiển thị.** ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-004 · Sửa dự án có If-Match; mã bất biến; dự án đã lưu trữ không sửa <!--k:prj-patch-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-004 (Sửa dự án).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-004 · API-10-004 · ERR-10-003, 006, 007.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IE2; dự án `tc-lien-thong-thue` từ TC-10-001.

**Các bước.**

1. IE1 `PATCH /projects/tc-lien-thong-thue` đổi `name`, `If-Match` đúng.
2. IE2 gửi `PATCH` với `ETag` cũ.
3. IE1 gửi `PATCH` có `projectCode = "doi-ma"`.
4. Lưu trữ dự án rồi `PATCH` tên.

**Kết quả mong đợi.** Bước 1 `200`, `ETag` mới. Bước 2 `412` ERR-10-007 có `currentEtag`. Bước 3 `400` ERR-10-003. Bước 4 `409` ERR-10-006. KT: có (sửa dự án, giá trị trước và sau) chỉ cho bước 1.

**Thông báo hiển thị.** ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-007 hộp xung đột phiên bản ST-13 "Đối tượng đã được {người} cập nhật lúc {giờ}".

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-005 · Lưu trữ khi còn topic bị chặn; lưu trữ, khôi phục thành công <!--k:prj-archive-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-005 (Lưu trữ và khôi phục dự án).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-005 · API-10-005, 006 · UI-10-03 · ERR-10-009, 010 · BR-10-003 · LGC-HUB-008.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; P-DKKD (có topic `ACTIVE`); P-CU (chỉ có một topic `DRAFT`).

**Các bước.**

1. `POST /projects/dang-ky-kinh-doanh:archive` với lý do hợp lệ.
2. `POST /projects/thu-nghiem-cu:archive` không có `reason`.
3. Lặp bước 2 với lý do "Dự án thử nghiệm đã kết thúc".
4. `POST /projects/thu-nghiem-cu:restore`.
5. Ở UI-10-02 mở bộ lọc mặc định.

**Kết quả mong đợi.** Bước 1 `409` ERR-10-010 với `dependents[]` liệt kê 4 topic. Bước 2 `400` ERR-10-009. Bước 3 `200`, `status = ARCHIVED`, topic `DRAFT` bị xóa mềm, không có nút "Xóa" ở bất kỳ màn nào. Bước 4 `200`, `ACTIVE`. Bước 5 dự án `ARCHIVED` không hiện ở lọc mặc định, hiện khi chọn trạng thái "Đã lưu trữ". KT: có cho bước 3, 4.

**Thông báo hiển thị.** ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-010 "Còn {n} đối tượng phụ thuộc."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-02 · Tạo topic và gửi duyệt

**Mục tiêu.** Xác nhận "Quản lý topic: tên, mô tả, phân vùng, cấu trúc, chế độ định tuyến" của Hub cũ được thay bằng topic có tên theo quy ước tiền tố tenant, lược đồ bắt buộc, tham số trong trần và tổ hợp định tuyến hợp lệ.

**Phủ.** FR-10-006, 007, 008, 013; UC-10-02; API-10-008…012, 020; UI-10-05, 06, 07; BR-10-002, 004, 006, 011, 030; LGC-HUB-009, 014.

#### TC-10-006 · Tạo topic bằng trình hướng dẫn và gửi duyệt ngay <!--k:topic-create-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-008 (Tạo topic và gửi duyệt).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-008 · API-10-009 · UI-10-07 · UC-10-02 · BR-10-002, 004 · LGC-HUB-009.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; P-DKKD; F-AV1.

**Các bước.**

1. Ở UI-10-07 chọn dự án P-DKKD, miền `tc`, thực thể `doanh-nghiep`, sự kiện `da-tam-ngung`, mô tả 40 ký tự, phân loại `INTERNAL`, `KEY_HASH` với `partitionKeyField = maDoanhNghiep`, lược đồ F-AV1, đánh dấu "Gửi duyệt ngay".
2. `GET /topics/t68.tc.doanh-nghiep.da-tam-ngung.v1`.

**Kết quả mong đợi.** Bước 1 `201` có `approvalRequestCode` dạng `apr-{ULID}`. Bước 2: `status = PENDING_APPROVAL`, `partitions = 6`, `retentionHours = 168`, `replicationFactor = 3`, `minInsyncReplicas = 2`, `cleanupPolicy = DELETE`, `majorVersion = 1`, `topicKind = BUSINESS`; lược đồ v1 `PENDING_APPROVAL`; chưa có `KafkaTopic` ở `dh-config-t68`. Trình hướng dẫn không có ô nhập hệ số nhân bản. KT: có (`TOPIC_CREATE`, băm lược đồ). EVT: không.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-011.
:::

#### TC-10-007 · Tên topic sai quy ước, miền dành riêng, trùng tên đã ngừng dùng <!--k:topic-name-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-008 (Tạo topic và gửi duyệt).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** FR-10-008 · API-10-009 · ERR-10-002, 003, 004 · BR-10-002, 003, 030.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; topic `t68.tc.cu.da-xoa.v1` đã `RETIRED`.

**Các bước.**

1. `POST /topics` với `domain = "DKKD"`, rồi `entity = "doanh_nghiep"`.
2. Lặp với `domain` lần lượt `event`, `cdc`, `audit`, `obs`, `integration`, `adapter`, `rdm`, `connect`, `payment`, `platform`, `mdm`, `dq`, `bpm`, `kpi`, `portal`.
3. Ghép tên dài 201 ký tự.
4. Tạo lại `t68.tc.cu.da-xoa.v1`.
5. `POST /topics` có `topicKind = CDC` bằng U-T68-IE1.

**Kết quả mong đợi.** Bước 1, 2, 3 `422` ERR-10-004 với `errors[].field` đúng trường. Bước 4 `409` ERR-10-002. Bước 5 `400` ERR-10-003 theo FR-10-008 và API §3.3 (người dùng không gửi `topicKind` khác `BUSINESS`); không có bản ghi topic nào được tạo.

**Thông báo hiển thị.** ERR-10-002 "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."; ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-004 "Tên topic không đúng quy ước hoặc dùng miền dành riêng ({miền}). Miền này chỉ do hệ thống đăng ký."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-008 · Tham số vượt trần, tổ hợp định tuyến không hợp lệ, compaction không khóa <!--k:topic-param-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-008 (Tạo topic và gửi duyệt).

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-008, 013 · API-10-009 · ERR-10-011, 012, 046, 048 · BR-10-006.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; U-T90-IE trên T92 (đã có 3 topic).

**Các bước.**

1. `partitions = 49`; rồi `partitions = 48` (biên).
2. `retentionHours = 721` khi trần 720.
3. `KEY_HASH` không có `partitionKeyField`.
4. `orderingRequired = true` với `ROUND_ROBIN`.
5. `cleanupPolicy = COMPACT` với `ROUND_ROBIN`.
6. `SINGLE_PARTITION` với `partitions = 6`.
7. Trên T92 tạo topic thứ tư.

**Kết quả mong đợi.** Bước 1: 49 trả `422` ERR-10-012, 48 trả `201`. Bước 2 `422` ERR-10-012. Bước 3, 4, 6 `422` ERR-10-046. Bước 5 `422` ERR-10-048. Bước 7 `422` ERR-10-011 (hạn mức tính cả topic chờ duyệt).

**Thông báo hiển thị.** ERR-10-011 "Vượt hạn mức của tenant: {tên hạn mức} đang dùng {đã dùng}/{trần}."; ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."; ERR-10-046 "Chế độ định tuyến này cần trường khóa phân vùng, hoặc không giữ được thứ tự."; ERR-10-048 "Nén theo khóa cần topic có khóa (chế độ Theo khóa)."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-009 · Lược đồ không hợp lệ khi tạo topic <!--k:topic-schema-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-008 (Tạo topic và gửi duyệt).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-008, 017 · API-10-009, 012 · ERR-10-015, 017, 018, 020 · BR-10-011.

**Tiền điều kiện, dữ liệu.** U-T68-IE1 ở T68; U-T90-IE ở T93 (`pii-check-mode = BLOCK`); F-AV-BAD, F-AV-NOKEY, F-AV-PII.

**Các bước.**

1. Tạo topic với F-AV-BAD.
2. Tạo topic `KEY_HASH` theo `maDoanhNghiep` với F-AV-NOKEY.
3. Ở T93 tạo topic `INTERNAL` với F-AV-PII.
4. Tạo topic với `schemaFormat = PROTOBUF`.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-015 kèm dòng, cột lỗi. Bước 2 `422` ERR-10-017 "Trường khóa phân vùng `maDoanhNghiep` không có trong lược đồ". Bước 3 `422` ERR-10-018 liệt kê `soDinhDanh`, `soDienThoai`. Bước 4 `422` ERR-10-020. Không ghi gì vào Apicurio (đếm artifact nhóm `t68`, `t93` không đổi).

**Thông báo hiển thị.** ERR-10-015 "Lược đồ sai cú pháp ở dòng {d}, cột {c}: {thông điệp}."; ERR-10-017 "Lược đồ thiếu trường khóa phân vùng '{trường}' hoặc trường này không phải chuỗi, số, hoặc cho phép null."; ERR-10-018 "Lược đồ có trường nghi dữ liệu cá nhân ({trường}) trên topic {phân loại}; chính sách của tenant đang chặn."; ERR-10-020 "Định dạng {định dạng} không được phép hoặc khác định dạng đã có của topic."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-010 · Danh sách topic, chi tiết và thông tin kết nối <!--k:topic-list-detail-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-006 (Liệt kê, tìm kiếm và lọc topic).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-10-006, 007 · API-10-008, 010, 020 · UI-10-05, 06 · ERR-10-049 · LGC-HUB-009.

**Tiền điều kiện, dữ liệu.** U-T68-VW; TP-CP, TP-TD, TP-CDC; topic DLQ `t68.dkkd.doanh-nghiep.da-cap-phep.v1.dlq` có trên cụm.

**Các bước.**

1. `GET /topics?projectCode=dang-ky-kinh-doanh&sort=topicName,asc`.
2. `GET /topics?topicKind=DLQ`.
3. `GET /topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1` và `/connection-info`.
4. `GET /topics?status=XYZ&sort=khongco,asc`.
5. Mở UI-10-06 với route `/tich-hop/topic/t68.dkkd.doanh-nghiep.da-cap-phep.v1`.

**Kết quả mong đợi.** Bước 1 không có topic `RETIRED`, không có topic `DLQ`; dòng TP-TD có `successorTopic`; `facets` theo `status`, `topicKind`, `dataClass`. Bước 2 trả topic DLQ khi lọc rõ. Bước 3 có `latestSchemaVersion = 3`, danh sách publication, subscription kèm `alertState`; `connection-info` có đường API phát, API kéo, địa chỉ listener `external` (T68 đã bật), URI artifact Apicurio `groups/t68/artifacts/{topicName}`. Bước 4 `400` ERR-10-049. Bước 5 route có dấu chấm mở đúng màn, tab "Cách kết nối" có mã mẫu.

**Thông báo hiển thị.** ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-011 · Rút yêu cầu tạo topic trước khi duyệt <!--k:topic-withdraw-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-008 (Tạo topic và gửi duyệt).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-008 · API-10-102, 011, 012 · ERR-10-006.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IE2; topic từ TC-10-006 ở `PENDING_APPROVAL`.

**Các bước.**

1. IE2 gọi `POST /approval-requests/{requestCode}:withdraw`.
2. IE1 gọi `:withdraw`.
3. IE1 `PATCH /topics/{topicName}` đổi `partitions = 3`, rồi `:submit`.

**Kết quả mong đợi.** Bước 1 403-PQ (chỉ người gửi được rút). Bước 2 `200`, yêu cầu `WITHDRAWN`, topic và lược đồ về `DRAFT`. Bước 3 sửa được khi `DRAFT`, gửi lại tạo yêu cầu mới `PENDING`.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-03 · Duyệt topic và cấp phát qua GitOps

**Mục tiêu.** Xác nhận duyệt bốn mắt rồi cấp phát đúng: artifact Apicurio theo `groupId = {tenant}`, `KafkaTopic` sinh vào `dh-config-{tenant}`, topic DLQ tạo cùng lúc, lỗi cấp phát có đường thử lại, hủy.

**Phủ.** FR-10-009, 010; UC-10-03; API-10-057…059, 101, 013, 014; UI-10-13, 06; BR-10-004, 010, 023, 036; EVT-10-01, 05; ADR-072.

#### TC-10-012 · Duyệt tạo topic, cấp phát tới ACTIVE trong 3 phút <!--k:topic-approve-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-009 · API-10-057, 058, 059 · UI-10-13 · UC-10-03 · EVT-10-01, 05 · BR-10-004, 023 · NFR-10-008 · LGC-HUB-009.

**Tiền điều kiện, dữ liệu.** U-T68-IA1; topic `t68.tc.doanh-nghiep.da-tam-ngung.v1` `PENDING_APPROVAL` do IE1 gửi.

**Các bước.**

1. Mở UI-10-13 (`/viec-cua-toi?phan-he=10`), mở yêu cầu `TOPIC_CREATE`, xem khác biệt và kết quả kiểm tra lược đồ; duyệt với ý kiến "Đồng ý cấp phát".
2. Theo dõi `GET /topics/{topicName}` mỗi 10 giây.
3. Đọc `dh-config-t68/kafka/topics/{topicName}.yaml` và artifact Apicurio.

**Kết quả mong đợi.** Bước 1 `200`, yêu cầu `APPROVED`. Bước 2 `PROVISIONING` rồi `ACTIVE` trong ≤ 3 phút. Bước 3: `replicas: 3`, `min.insync.replicas: 2`, `retention.ms = 604800000`, nhãn `dh.gov.vn/tenant: t68`; có thêm tệp topic `{topicName}.dlq`; Apicurio có artifact `groupId = t68`, `artifactId = {topicName}`, quy tắc tương thích `BACKWARD`, phiên bản 1 `ENABLED`. EVT: `topic.activated`, `schema.version-enabled`. KT: có (duyệt topic, mã commit).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-013 · Người tạo tự duyệt, thiếu ý kiến, thiếu xác nhận dữ liệu cá nhân, từ chối <!--k:topic-approve-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-009 · API-10-059, 101 · ERR-10-008, 009 · BR-10-010, 014.

**Tiền điều kiện, dữ liệu.** U-T68-TA tạo và gửi topic `t68.tc.nguoi-dai-dien.da-dang-ky.v1` với F-AV-PII (`WARN`); U-T68-IA2 là người gửi một yêu cầu khác; U-T68-IA1.

**Các bước.**

1. U-T68-TA duyệt chính yêu cầu của mình.
2. U-T68-IA2 duyệt yêu cầu do chính mình gửi.
3. U-T68-IA1 duyệt không có `comment`.
4. U-T68-IA1 duyệt có `comment` nhưng thiếu `acknowledgePii`.
5. U-T68-IA1 từ chối với `comment = "Không"` (dưới 10 ký tự), rồi với lý do đủ dài.

**Kết quả mong đợi.** Bước 1, 2 `403` ERR-10-008 (bốn mắt áp cả với TA). Bước 3, 4 `400` ERR-10-009. Bước 5 lần đầu `400` ERR-10-009; lần hai `200`, yêu cầu `REJECTED`, topic về `DRAFT`, người gửi nhận thông báo. Không có artifact Apicurio, không có commit Git.

**Thông báo hiển thị.** ERR-10-008 "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-014 · Apicurio hoặc Git ngừng khi duyệt không để lại trạng thái dở <!--k:topic-approve-dep-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).

**Loại.** Âm, Khả dụng.

**Ưu tiên.** P1.

**Tự động.** API, Chaos.

**Truy vết.** FR-10-009 · API-10-059 · ERR-10-029 · BR-10-036.

**Tiền điều kiện, dữ liệu.** U-T68-IA1; hai topic `PENDING_APPROVAL`; SIM-GIT có thể dừng.

**Các bước.**

1. Dừng Apicurio; duyệt topic thứ nhất.
2. Bật Apicurio, dừng SIM-GIT; duyệt topic thứ hai.

**Kết quả mong đợi.** Bước 1 `503` ERR-10-029 có `Retry-After`; yêu cầu vẫn `PENDING`. Bước 2 `503` ERR-10-029; artifact đã tạo ở Apicurio được xóa bù; yêu cầu vẫn `PENDING`, topic vẫn `PENDING_APPROVAL`. Sau khi bật lại và duyệt lần nữa thì `ACTIVE` bình thường.

**Thông báo hiển thị.** ERR-10-029 "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

#### TC-10-015 · Cấp phát thất bại, thử lại và hủy cấp phát <!--k:topic-provision-fail-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-010 (Theo dõi cấp phát và xử lý cấp phát thất bại).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-10-010 · API-10-013, 014 · ERR-10-006, 038 · BR-10-036.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; chính sách Kyverno thử nghiệm từ chối `KafkaTopic` có nhãn `dh.gov.vn/project: tc-loi`; topic của dự án `tc-loi` được duyệt.

**Các bước.**

1. Chờ quá `10.provisioning.timeout-minutes` (đặt 3 phút ở SIT).
2. Đề nghị publication trên topic đó.
3. Gỡ chính sách, gọi `POST /topics/{topicName}:retry-provisioning`.
4. Với topic `FAILED` thứ hai gọi `:cancel-provisioning`; gọi `:retry-provisioning` với topic `ACTIVE`.

**Kết quả mong đợi.** Bước 1 topic `FAILED`, `provisioningError` có thông điệp Kyverno, IE và TA nhận cảnh báo. Bước 2 `409` ERR-10-038. Bước 3 `202`, rồi `ACTIVE`. Bước 4: hủy trả `200`, topic về `DRAFT`, tệp YAML bị gỡ khỏi Git; thử lại với `ACTIVE` trả `409` ERR-10-006.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-038 "Đối tượng đang cấp phát hoặc cấp phát lỗi."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-016 · Phát hiện lệch giữa cụm và Git <!--k:topic-drift-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-010 (Theo dõi cấp phát và xử lý cấp phát thất bại).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** IT, Chaos.

**Truy vết.** FR-10-010 · BR-10-036 · NFR-10-019.

**Tiền điều kiện, dữ liệu.** TP-GT `ACTIVE`; quyền quản trị cụm ở SIT.

**Các bước.**

1. Sửa tay `retention.ms` của TP-GT bằng `kafka-configs`.
2. Xóa tay tài nguyên `KafkaTopic` của một topic thử.
3. Chờ một chu kỳ đối chiếu 10 phút.

**Kết quả mong đợi.** Cảnh báo lệch cho cả hai trường hợp, kèm giá trị Git và giá trị cụm; Argo CD khôi phục cấu hình theo Git; PH-10 không tự sửa cấu hình bằng Admin API; trạng thái topic ở UI-10-06 hiện dải "Lệch cấu hình".

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-04 · Thay đổi cấu hình topic đang hoạt động

**Mục tiêu.** Xác nhận tăng phân vùng, đổi lưu giữ, dọn, định tuyến và mức tương thích đi qua yêu cầu `TOPIC_CHANGE` có duyệt khi có rủi ro mất hay đảo thứ tự sự kiện.

**Phủ.** FR-10-011, 012, 013, 021; UC-10-04; API-10-015, 059; UI-10-06, 13; BR-10-005, 006, 012; EVT-10-02.

#### TC-10-017 · Tăng phân vùng có xác nhận tác động thứ tự <!--k:part-increase-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-011 (Tăng số phân vùng của topic đang hoạt động).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-011 · API-10-015, 059 · EVT-10-02 · BR-10-005 · UC-10-04.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; TP-CP 6 phân vùng, SUB-PUSH đang giao.

**Các bước.**

1. `POST /topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/change-requests` với `partitions = 12`, `reason`, `acknowledgeOrderingImpact = true`.
2. IA1 duyệt.
3. Phát 1.000 sự kiện trong lúc áp dụng.

**Kết quả mong đợi.** Bước 1 `201`, phản hồi có cảnh báo khóa ánh xạ sang phân vùng khác và gợi ý FR-10-015. Bước 2 Cụm áp dụng, `partitions = 12`. Bước 3 SUB-PUSH tự nhận phân vùng mới qua tái cân bằng, không mất sự kiện. EVT: `topic.changed`. KT: có (6 sang 12, người duyệt).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-018 · Giảm phân vùng, thiếu xác nhận, topic một phân vùng <!--k:part-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-011 (Tăng số phân vùng của topic đang hoạt động).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-011 · API-10-015 · ERR-10-012, 013, 014 · BR-10-005.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; TP-CP; topic `SINGLE_PARTITION` thử.

**Các bước.**

1. Đề nghị `partitions = 3` cho TP-CP.
2. Đề nghị `partitions = 8` không có `acknowledgeOrderingImpact`.
3. Đề nghị `partitions = 49`.
4. Đề nghị tăng phân vùng cho topic `SINGLE_PARTITION`.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-013. Bước 2 `409` ERR-10-014. Bước 3 `422` ERR-10-012. Bước 4 `422` ERR-10-046. Không có yêu cầu duyệt nào được tạo.

**Thông báo hiển thị.** ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."; ERR-10-013 "Không giảm được số phân vùng. Chỉ được tăng."; ERR-10-014 "Tăng phân vùng làm đổi phân vùng của khóa; thứ tự giữa sự kiện cũ và mới của cùng khóa không còn bảo đảm. Đánh dấu xác nhận để tiếp tục."; ERR-10-046 "Chế độ định tuyến này cần trường khóa phân vùng, hoặc không giữ được thứ tự."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-019 · Tăng lưu giữ không cần duyệt; giảm lưu giữ chặn khi có subscription chậm <!--k:retention-change-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-012 (Thay đổi lưu giữ và chính sách dọn (compaction)).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-012 · API-10-015, 059 · ERR-10-009, 012 · EVT-10-02.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; TP-CP; SUB-FLOW có `lagSeconds = 7200` (giả lập dừng luồng).

**Các bước.**

1. Đổi `retentionHours = 336`.
2. Đổi `retentionHours = 1`.
3. IA1 duyệt yêu cầu ở bước 2 không có `acknowledgeDataLoss`.
4. IA1 duyệt có `acknowledgeDataLoss = true` và ý kiến.

**Kết quả mong đợi.** Bước 1 áp dụng ngay không qua duyệt, EVT: `topic.changed`. Bước 2 `201` tạo `TOPIC_CHANGE`, phản hồi liệt kê `luong-dong-bo-thue-dn-cap-phep` có lag lớn hơn lưu giữ mới. Bước 3 `400` ERR-10-009. Bước 4 `200`, `retention.ms = 3600000` sau khi cụm áp dụng.

**Thông báo hiển thị.** ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-020 · Đổi chế độ định tuyến và khóa; chế độ bị tắt <!--k:routing-change-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-013 (Chế độ định tuyến và khóa phân vùng).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-013 · API-10-015 · ERR-10-043, 046, 047 · BR-10-006 · LGC-HUB-014.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1, U-T68-TA; TP-GT (`ROUND_ROBIN`, không `orderingRequired`).

**Các bước.**

1. Đề nghị TP-GT sang `KEY_HASH` theo `maDoanhNghiep`; IA1 duyệt; phát 10 sự kiện cùng khóa.
2. Đề nghị TP-CP (`orderingRequired`) sang `ROUND_ROBIN`.
3. Đề nghị TP-CP đổi `partitionKeyField` sang `loaiThayDoi`.
4. TA tắt `SINGLE_PARTITION` (không topic nào dùng) rồi IE1 đề nghị topic thử sang `SINGLE_PARTITION`.

**Kết quả mong đợi.** Bước 1 10 sự kiện cùng khóa vào cùng một phân vùng, đúng thứ tự offset; cổng áp dụng cấu hình mới ≤ 60 giây sau EVT `topic.changed`. Bước 2 `422` ERR-10-046. Bước 3 `409` ERR-10-047 kèm gợi ý tạo `.v2`. Bước 4 `422` ERR-10-043.

**Thông báo hiển thị.** ERR-10-043 "Không tắt được mục đang có {n} bên tham gia hoặc topic dùng."; ERR-10-046 "Chế độ định tuyến này cần trường khóa phân vùng, hoặc không giữ được thứ tự."; ERR-10-047 "Thay đổi này phá vỡ bên nhận hiện có; cần tạo phiên bản topic mới, hoặc topic kế nhiệm đã tồn tại."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-021 · Đổi mức tương thích: nới lỏng, siết chặt, NONE <!--k:compat-level-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-021 (Đặt mức tương thích của lược đồ).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-10-021 · API-10-015 · ERR-10-016, 019 · BR-10-012 · ADR-070.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; TP-CP v1…v3 `ENABLED` (v3 bỏ một trường không mặc định so với v1); topic thử `DRAFT` chưa từng `ACTIVE`.

**Các bước.**

1. Đề nghị TP-CP sang `FULL_TRANSITIVE`.
2. Đề nghị TP-CP sang `NONE`.
3. Đề nghị TP-CP sang `BACKWARD_TRANSITIVE` có lý do; IA1 duyệt.
4. Đặt `NONE` cho topic `DRAFT`.

**Kết quả mong đợi.** Bước 1 `409` ERR-10-016 kèm cặp phiên bản vi phạm (v1, v3). Bước 2 `422` ERR-10-019. Bước 3 duyệt xong, quy tắc tương thích của artifact ở Apicurio là `BACKWARD_TRANSITIVE`; bên phát, bên nhận nhận thông báo; EVT: `topic.changed`. Bước 4 được nhận.

**Thông báo hiển thị.** ERR-10-016 "Lược đồ không tương thích theo mức {mức}."; ERR-10-019 "Mức 'Không kiểm tra' chỉ dùng cho topic chưa từng hoạt động."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-05 · Ngừng topic và phiên bản chính mới

**Mục tiêu.** Xác nhận ngừng khuyến nghị giữ quan hệ cũ nhưng chặn subscription mới; ngừng dùng thu hồi hết quan hệ và giữ topic khi còn DLQ; thay đổi phá vỡ đi bằng topic `.v{n+1}` có theo dõi chuyển đổi.

**Phủ.** FR-10-014, 015, 016; UC-10-05; API-10-016…019; UI-10-06, 01; BR-10-013, 016, 024; EVT-10-01, 03, 04; ADR-070.

#### TC-10-022 · Ngừng khuyến nghị topic có kế nhiệm <!--k:topic-deprecate-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-014 (Ngừng khuyến nghị và ngừng dùng topic).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-014 · API-10-016 · EVT-10-03 · BR-10-016 · UC-10-05.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; topic thử `t68.tc.ho-so.da-nop.v1` `ACTIVE` có một subscription; kế nhiệm `t68.tc.ho-so.da-nop.v2` `ACTIVE`.

**Các bước.**

1. `POST /topics/t68.tc.ho-so.da-nop.v1:deprecate` với `reason`, `successorTopic`.
2. HTTT phát lên topic cũ; bộ giao nhận giao cho subscription cũ.
3. Đề nghị subscription mới trên topic cũ.

**Kết quả mong đợi.** Bước 1 `200`, `DEPRECATED`, `sunsetAt` = hôm nay + 90 ngày. Bước 2 vẫn phát và giao bình thường. Bước 3 `422` ERR-10-025. EVT: `topic.deprecated` có `successorTopic`, `sunsetAt`. Đầu mối các bên nhận được thông báo.

**Thông báo hiển thị.** ERR-10-025 "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-023 · Ngừng dùng topic: còn subscription, qua duyệt, giữ khi còn DLQ <!--k:topic-retire-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-014 (Ngừng khuyến nghị và ngừng dùng topic).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-014 · API-10-017, 059 · ERR-10-009, 010 · EVT-10-04 · BR-10-016, 024.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; TP-GT không subscription; topic thử có subscription `ACTIVE` và 2 mục DLQ `NEW`.

**Các bước.**

1. `POST /topics/t68.dkkd.doanh-nghiep.giai-the.v1:retire` không có lý do, rồi có lý do.
2. Phát lên TP-GT qua API và Kafka.
3. `:retire` topic thử với `immediate = true`.
4. Gửi yêu cầu `TOPIC_RETIRE`, IA1 duyệt; chờ quá `10.topic.delete-after-retire-days`.

**Kết quả mong đợi.** Bước 1 lần đầu `400` ERR-10-009; lần hai `200`, `RETIRED`, EVT: `topic.retired`. Bước 2 API trả 404-ẩn (ERR-10-103), Kafka từ chối do ACL bị xóa. Bước 3 `409` ERR-10-010. Bước 4 mọi publication, subscription thu hồi, ACL xóa, topic `RETIRED`; topic chưa bị xóa khỏi cụm vì còn mục DLQ `NEW`.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-010 "Còn {n} đối tượng phụ thuộc."; ERR-10-103 "Topic {tên} không tồn tại, không nhận sự kiện ở trạng thái hiện tại hoặc thuộc tenant khác."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu. Giữ dữ liệu cho TC-10-049.
:::

#### TC-10-024 · Tạo phiên bản chính v2 khi thay đổi phá vỡ <!--k:topic-major-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-015 (Tạo phiên bản chính mới của topic khi thay đổi phá vỡ).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-10-015 · API-10-018 · EVT-10-01, 03 · BR-10-013 · ADR-070 · LGC-HUB-009.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; topic thử `t68.tc.doanh-nghiep.cap-moi.v1` `ACTIVE` có 2 publication, 2 subscription; F-AV-BRK.

**Các bước.**

1. `POST /topics/t68.tc.doanh-nghiep.cap-moi.v1:new-major-version` với F-AV-BRK, `migrationNote` 40 ký tự, `sunsetDays = 30`.
2. IA1 duyệt yêu cầu `TOPIC_CREATE` của topic mới.
3. Xem artifact Apicurio của hai topic.

**Kết quả mong đợi.** Bước 1 `201`, topic `t68.tc.doanh-nghiep.cap-moi.v2` `PENDING_APPROVAL`, `predecessorTopic` trỏ v1, yêu cầu kèm khác biệt lược đồ. Bước 2 v2 `ACTIVE`; v1 `DEPRECATED` với `successorTopic`, `sunsetAt` sau 30 ngày; có bản nháp publication trên v2 cho hai bên phát cũ. Bước 3 v2 là artifact mới, không chung lịch sử tương thích với v1. EVT: `topic.activated` (v2), `topic.deprecated` (v1).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-025, TC-10-026.
:::

#### TC-10-025 · Kế nhiệm đã tồn tại; nguồn không ACTIVE; ghi đè lược đồ ENABLED <!--k:topic-major-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-015 (Tạo phiên bản chính mới của topic khi thay đổi phá vỡ).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-015, 019 · API-10-018, 025 · ERR-10-006, 047 · BR-10-013.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; v1, v2 từ TC-10-024.

**Các bước.**

1. Gọi lại `:new-major-version` trên v1.
2. Gọi `:new-major-version` trên topic `DRAFT`.
3. `PUT /topics/{v2}/schema/versions/1` với nội dung khác.

**Kết quả mong đợi.** Bước 1 `409` ERR-10-047. Bước 2 `409` ERR-10-006. Bước 3 `409` ERR-10-006 (phiên bản `ENABLED` bất biến); nội dung ở Apicurio không đổi (so `contentHash`).

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-047 "Thay đổi này phá vỡ bên nhận hiện có; cần tạo phiên bản topic mới, hoặc topic kế nhiệm đã tồn tại."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-026 · Theo dõi chuyển đổi bên nhận sang v2 và nhắc trước hạn <!--k:topic-migration-status-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-016 (Theo dõi chuyển đổi bên nhận sang phiên bản topic mới).

**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-10-016 · API-10-019 · UI-10-06, 01.

**Tiền điều kiện, dữ liệu.** U-T68-VW; v1, v2 từ TC-10-024; một bên nhận đã có subscription trên v2, một chưa.

**Các bước.**

1. `GET /topics/{v1}/migration-status`.
2. Đặt đồng hồ SIT tới `sunsetAt` − 14 ngày và − 3 ngày.
3. Mở UI-10-01.

**Kết quả mong đợi.** Bước 1 liệt kê hai bên nhận với cờ đã chuyển, lag hai bên, số ngày còn lại; bên phát với số sự kiện 24 giờ trên v2. Bước 2 đầu mối bên chưa chuyển nhận thông báo hai lần. Bước 3 thẻ "Topic sắp hết hạn" đếm 1.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

### TS-10-06 · Lược đồ sự kiện: soạn, kiểm tra, duyệt

**Mục tiêu.** Xác nhận "cấu trúc" của topic hệ cũ thành lược đồ bắt buộc ở Apicurio: soạn có kiểm tra cú pháp, quy ước, dữ liệu cá nhân, duyệt bốn mắt, lịch sử và so sánh, vòng đời phiên bản.

**Phủ.** FR-10-017, 019, 020, 022; UC-10-06; API-10-021…030; UI-10-08, 13; BR-10-010, 014, 015; EVT-10-05.

#### TC-10-027 · Soạn phiên bản lược đồ mới và kiểm tra <!--k:schema-draft-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-017 (Soạn và kiểm tra lược đồ).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-017, 018 · API-10-023, 026 · UI-10-08 · UC-10-06 · LGC-HUB-009.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; TP-CP; F-AV-ADD.

**Các bước.**

1. Ở UI-10-08 dán F-AV-ADD, ghi chú thay đổi "Thêm ngành nghề kinh doanh"; bấm "Kiểm tra".
2. `GET /topics/{TP-CP}/schema/versions/4`.

**Kết quả mong đợi.** Bước 1 gọi `POST …/schema/versions` (`201`) rồi `:check` (`200`): cú pháp đạt, `compatibilityReport.compatible = true` theo `BACKWARD`, cảnh báo quy ước (nếu có) không chặn, `piiFindings` rỗng. Bước 2 `status = DRAFT`, `contentHash` là SHA-256 của nội dung. Apicurio chưa có phiên bản 4 (chạy thử `dryRun`). KT: có (băm, kết quả kiểm tra).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-028.
:::

#### TC-10-028 · Phiên bản sai định dạng, quá lớn, thiếu ghi chú, đang có bản chờ duyệt <!--k:schema-draft-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-017 (Soạn và kiểm tra lược đồ).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-017 · API-10-023, 025 · ERR-10-003, 006, 015, 020.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; TP-CP định dạng Avro; phiên bản 4 từ TC-10-027 đã gửi duyệt.

**Các bước.**

1. Tạo phiên bản JSON Schema F-JS1 cho TP-CP.
2. Tạo phiên bản Avro 300 KiB.
3. Tạo phiên bản không có `changeNote`.
4. Tạo phiên bản thứ hai khi v4 đang `PENDING_APPROVAL`.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-020 (khác định dạng đã có). Bước 2 `400` ERR-10-003 với `errors[].field = content` (vượt 256 KiB, FR-10-017). Bước 3 `400` ERR-10-003. Bước 4 `409` ERR-10-006.

**Thông báo hiển thị.** ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-015 "Lược đồ sai cú pháp ở dòng {d}, cột {c}: {thông điệp}."; ERR-10-020 "Định dạng {định dạng} không được phép hoặc khác định dạng đã có của topic."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-029 · Gửi duyệt và duyệt phiên bản lược đồ <!--k:schema-approve-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-019 (Gửi duyệt và duyệt phiên bản lược đồ).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-019 · API-10-027, 059 · UI-10-13 · EVT-10-05 · UC-10-06.

**Tiền điều kiện, dữ liệu.** U-T68-IE1 gửi, U-T68-IA1 duyệt; v4 `DRAFT` đã kiểm tra trong 24 giờ.

**Các bước.**

1. `POST …/schema/versions/4:submit`.
2. IA1 mở yêu cầu `SCHEMA_VERSION` ở UI-10-13: xem khác biệt, danh sách bên nhận hiện có; duyệt.
3. PB-DKKD phát sự kiện có trường `nganhNghe` với `dataschema` trỏ v4.

**Kết quả mong đợi.** Bước 1 `200`, v4 `PENDING_APPROVAL`. Bước 2 v4 `ENABLED`, có `apicurioGlobalId`, `latestVersionNo = 4`; EVT: `schema.version-enabled`. Bước 3 cổng nhận sau ≤ 60 giây (đệm làm mới bằng EVT-10-05); SUB-PUSH vẫn giải tuần tự được sự kiện v1…v3 cũ. KT: có.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-030 · Bốn mắt, quá hạn kiểm tra, không tương thích khi duyệt <!--k:schema-approve-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-019 (Gửi duyệt và duyệt phiên bản lược đồ).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-019 · API-10-027, 059 · ERR-10-008, 016 · BR-10-010.

**Tiền điều kiện, dữ liệu.** U-T68-TA soạn v5; U-T68-IA1; F-AV-BRK.

**Các bước.**

1. U-T68-TA gửi duyệt rồi tự duyệt v5.
2. Soạn v6 bằng F-AV-BRK, `:submit`.
3. Soạn v7 hợp lệ, kiểm tra, đặt đồng hồ SIT +25 giờ rồi `:submit`.

**Kết quả mong đợi.** Bước 1 duyệt trả `403` ERR-10-008. Bước 2 `409` ERR-10-016 kèm báo cáo (trường `ngayCap` không mặc định, `phienBan` đổi kiểu). Bước 3 hệ thống chạy lại kiểm tra trước khi gửi (kết quả 24 giờ hết hạn), gửi thành công nếu vẫn tương thích. Apicurio không có v6.

**Thông báo hiển thị.** ERR-10-008 "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."; ERR-10-016 "Lược đồ không tương thích theo mức {mức}."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-031 · Lịch sử phiên bản, so sánh, tải lược đồ <!--k:schema-history-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-020 (Xem lịch sử phiên bản, so sánh và tải lược đồ).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-10-020 · API-10-021, 022, 024, 030 · UI-10-08 · ERR-10-049 · LGC-HUB-009.

**Tiền điều kiện, dữ liệu.** U-T68-VW; TP-CP v1…v4.

**Các bước.**

1. `GET …/schema/versions`.
2. `GET …/schema/diff?from=1&to=4`.
3. `GET …/schema/diff?from=1&to=99`.
4. Ở UI-10-08 tải `.avsc` của v2, xem ví dụ sự kiện sinh từ lược đồ.

**Kết quả mong đợi.** Bước 1 bốn phiên bản kèm người duyệt, ngày, ghi chú. Bước 2 khác biệt cấu trúc liệt kê trường thêm `nganhNghe`. Bước 3 404-ẩn. Bước 4 tệp đúng nội dung v2 (so băm); ví dụ dùng giá trị giả lập, không có dữ liệu thật.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-032 · Ngừng khuyến nghị và vô hiệu phiên bản lược đồ <!--k:schema-deprecate-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-022 (Ngừng khuyến nghị và vô hiệu phiên bản lược đồ).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, RT.

**Truy vết.** FR-10-022 · API-10-028, 029 · ERR-10-006, 009 · BR-10-015 · EVT-10-02.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; TP-CP v1…v4; bản tin cuối theo v1 ghi nhận 10 ngày trước, lưu giữ 7 ngày; bản tin theo v2 còn trong lưu giữ.

**Các bước.**

1. `:deprecate` v1; phát một sự kiện theo v1.
2. `:deprecate` v4 (mới nhất).
3. Đề nghị `:disable` v2.
4. Đề nghị `:disable` v1, IA1 duyệt.

**Kết quả mong đợi.** Bước 1 v1 `DEPRECATED` ở cả PH-10 và Apicurio; phát được nhưng phản hồi có tiêu đề `Deprecation`. Bước 2 `409` ERR-10-006. Bước 3 `409` ERR-10-006 kèm thời điểm bản tin cuối dùng v2. Bước 4 v1 `DISABLED`; EVT: `topic.changed`.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-07 · Tương thích lược đồ Apicurio và topic .v{n+1}

**Mục tiêu.** Chứng minh quy tắc ADR-070: mỗi topic một artifact `groupId = tenant`, `artifactId = topicName`; mức mặc định `BACKWARD` chặn ở Apicurio cả khi có người cố ghi thẳng; thay đổi phá vỡ chỉ đi bằng topic mới; bên nhận cũ đọc được dữ liệu mới.

**Phủ.** FR-10-018, 021, 015, 024; BR-10-008, 012, 013; ERR-10-016, 102; API-10-026, 084; ADR-070.

#### TC-10-033 · Ma trận tương thích theo từng mức <!--k:compat-matrix-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-018 (Kiểm tra tương thích với các phiên bản đã có).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-10-018 · API-10-026 · ERR-10-016 · BR-10-012 · ADR-070.

**Tiền điều kiện, dữ liệu.** Topic thử với v1 = F-AV1; F-AV-ADD, F-AV-DEL, F-AV-BRK.

**Các bước.**

1. Với từng mức `BACKWARD`, `FORWARD`, `FULL`, `BACKWARD_TRANSITIVE` chạy `:check` cho ba tệp.

**Kết quả mong đợi.** `BACKWARD`: ADD đạt, DEL đạt, BRK không đạt. `FORWARD`: ADD đạt, DEL không đạt (trường không mặc định), BRK không đạt. `FULL`: chỉ ADD đạt. `BACKWARD_TRANSITIVE` so với mọi phiên bản `ENABLED`, `DEPRECATED`. Báo cáo không đạt có đường dẫn trường và quy tắc vi phạm.

**Thông báo hiển thị.** ERR-10-016 "Lược đồ không tương thích theo mức {mức}."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-034 · Ghi thẳng phiên bản phá vỡ vào Apicurio bị chặn <!--k:compat-registry-direct-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-024 (Cung cấp tra cứu lược đồ cho bên ngoài).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, KT.

**Truy vết.** FR-10-024, 034 · API-10-084 · ERR-10-102 · BR-10-008, 013.

**Tiền điều kiện, dữ liệu.** Client C-DKKD có scope `topic:{TP-CP}:publish`; serde Apicurio với `auto.register = true` cố ý.

**Các bước.**

1. Gọi `POST /event/v1/registry/apis/registry/v3/groups/t68/artifacts/{TP-CP}/versions` với F-AV-BRK.
2. Producer Kafka của PB-DKKD-K bật tự đăng ký lược đồ và gửi bản tin theo F-AV-BRK.

**Kết quả mong đợi.** Bước 1 bị từ chối (đường tra cứu chỉ đọc, `403` ERR-10-102). Bước 2 Apicurio từ chối đăng ký; producer nhận lỗi; không có phiên bản mới ở artifact.

**Thông báo hiển thị.** ERR-10-102 "Token chưa có quyền {publish hoặc subscribe} trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-035 · Bên nhận cũ đọc dữ liệu theo lược đồ mới <!--k:compat-consumer-old-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-018 (Kiểm tra tương thích với các phiên bản đã có).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** RT.

**Truy vết.** FR-10-018, 019, 038 · ADR-070 · BR-10-012.

**Tiền điều kiện, dữ liệu.** SUB-PUSH, SUB-KAFKA; TP-CP v4 `ENABLED` (thêm trường có mặc định).

**Các bước.**

1. Phát 50 sự kiện v3 và 50 sự kiện v4 xen kẽ.
2. Consumer của HT-KBNN cấu hình đọc theo v3.

**Kết quả mong đợi.** SUB-PUSH giao đủ 100 sự kiện, `ce_dataschema` trỏ đúng phiên bản mỗi sự kiện. Consumer v3 giải tuần tự được cả 100 (trường mới bị bỏ qua). Không có mục DLQ ERR-10-116.

**Thông báo hiển thị.** ERR-10-116 nhãn "Không giải được bản tin".

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-036 · Thay đổi phá vỡ không có đường nào ngoài .v{n+1} <!--k:compat-break-path-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-015 (Tạo phiên bản chính mới của topic khi thay đổi phá vỡ).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-015, 021 · API-10-015, 027 · ERR-10-016, 019, 047 · BR-10-013.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-TA; TP-CP; F-AV-BRK.

**Các bước.**

1. Đề nghị hạ mức tương thích TP-CP về `NONE` để đưa F-AV-BRK vào.
2. Đề nghị đổi mức về `FORWARD` rồi gửi F-AV-BRK.
3. Gọi `:new-major-version` với F-AV-BRK.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-019 (topic đã từng `ACTIVE`). Bước 2 khi đổi mức, kiểm tra trước phát hiện v1…v4 vẫn thỏa `FORWARD` nên được duyệt; gửi F-AV-BRK vẫn `409` ERR-10-016 (không tương thích `FORWARD`). Bước 3 là đường duy nhất được nhận, tạo `.v2`.

**Thông báo hiển thị.** ERR-10-016 "Lược đồ không tương thích theo mức {mức}."; ERR-10-019 "Mức 'Không kiểm tra' chỉ dùng cho topic chưa từng hoạt động."; ERR-10-047 "Thay đổi này phá vỡ bên nhận hiện có; cần tạo phiên bản topic mới, hoặc topic kế nhiệm đã tồn tại."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-08 · Bên phát và bên nhận

**Mục tiêu.** Xác nhận "Quản lý publisher, subscriber" của Hub cũ (tên, kiểu giao tiếp, khóa tham chiếu, đánh dấu là luồng) được giữ, với ràng buộc bên tham gia phải là HTTT thành viên, luồng hoặc DU có thật.

**Phủ.** FR-10-025…028; UC-10-07, 08; API-10-032…041, 092…095; UI-10-09, 10; BR-10-003, 017; LGC-HUB-010, 011.

#### TC-10-037 · Đăng ký bên phát HTTT và bên nhận là luồng <!--k:party-create-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-026 (Đăng ký bên phát).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-026, 027 · API-10-033, 038 · UI-10-09, 10 · UC-10-07 · BR-10-017 · LGC-HUB-010, 011.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; SIM-PH01 có `HT-QLDD` `ACTIVE`; SIM-PH04 có luồng `dkkd-tong-hop`.

**Các bước.**

1. `POST /publishers` với `publisherCode = tc-ht-qldd`, `partyType = SYSTEM`, `systemCode = HT-QLDD`, `commType = HTTP_PUBLISH`, `referenceKey = PUB_QLDD_01`.
2. `POST /subscribers` với `subscriberCode = tc-luong-tong-hop`, `partyType = FLOW`, `flowCode = dkkd-tong-hop`, `commType = INTERNAL_KAFKA`.
3. Mở UI-10-10.

**Kết quả mong đợi.** Bước 1 `201`, `status = ACTIVE`, `clientId` lấy từ PH-01, chưa có publication. Bước 2 `201`, `isFlow = true`, `kafkaPrincipal` là principal nội bộ của tenant. Bước 3 cột "Loại" của dòng mới hiện "Luồng tích hợp". KT: có.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-044.
:::

#### TC-10-038 · Tổ hợp không hợp lệ, HTTT không hoạt động, luồng ngừng, DU lạ, trùng cặp <!--k:party-create-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-026 (Đăng ký bên phát).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-026, 027 · API-10-033, 038 · ERR-10-002, 003, 021, 022, 023, 024, 028, 044 · BR-10-017.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-SV; U-T01-IE (T01 tắt Kafka ngoài).

**Các bước.**

1. Bên phát `SYSTEM` với `commType = WEBHOOK_PUSH`; bên nhận `FLOW` với `commType = HTTP_PULL`; bên phát `LEGACY_BRIDGE`.
2. `systemCode = HT-DUNG` (`SUSPENDED`).
3. `flowCode = luong-cu` (`RETIRED`); `serviceCode = dh-khong-co`.
4. Bên phát thứ hai cho cặp (`HT-DKKD`, `HTTP_PUBLISH`).
5. U-T01-IE đăng ký bên phát `KAFKA_NATIVE`.
6. U-T68-SV đăng ký bên phát cho HTTT của `SO-TC`.

**Kết quả mong đợi.** Bước 1 `400` ERR-10-003. Bước 2 `422` ERR-10-021. Bước 3 `422` ERR-10-022, ERR-10-023. Bước 4 `409` ERR-10-024. Bước 5 `422` ERR-10-028. Bước 6 403-TC. KT: không.

**Thông báo hiển thị.** ERR-10-002 "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."; ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-021 "HTTT {mã} không tồn tại hoặc chưa ở trạng thái hoạt động ở PH-01."; ERR-10-022 "Luồng {mã} không tồn tại hoặc đã ngừng ở PH-04."; ERR-10-023 "Dịch vụ nội bộ {mã} không có trong danh sách."; ERR-10-024 "Đã có quan hệ cho cặp này: {mô tả}."; ERR-10-028 "Tenant chưa bật Kafka ngoài. Đề nghị quản trị nền tảng bật trước khi dùng chế độ này."; ERR-10-044 ST-07 "Đối tượng ngoài phạm vi tổ chức của bạn."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-039 · Danh sách và chi tiết bên tham gia <!--k:party-list-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-025 (Liệt kê bên phát và bên nhận).

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-025 · API-10-032, 034, 037, 039 · UI-10-09, 10 · LGC-HUB-010, 011.

**Tiền điều kiện, dữ liệu.** U-T68-VW; dữ liệu mục 2.3.

**Các bước.**

1. `GET /publishers?q=PUB_DKKD&partyType=SYSTEM`.
2. `GET /subscribers?projectCode=dang-ky-kinh-doanh&status=ACTIVE`.
3. `GET /subscribers/ht-thue`.

**Kết quả mong đợi.** Bước 1 tìm theo `referenceKey` ra `ht-dkkd`. Bước 2 có `ht-thue`, `ht-bhxh`, `ht-kho-bac`, `luong-dong-bo-thue` với số subscription theo trạng thái. Bước 3 có trạng thái HTTT ở PH-01, `commType`, `lastActiveAt`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-040 · Sửa, tạm ngừng, tiếp tục, ngừng dùng bên phát <!--k:party-lifecycle-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-028 (Sửa, tạm ngừng, tiếp tục và ngừng dùng bên phát, bên nhận).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-028 · API-10-035, 036, 092, 093 · EVT-10-07 · UC-10-08 · NFR-10-009 · LGC-HUB-010.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-SO; PB-DKKD có publication `ACTIVE`.

**Các bước.**

1. IE1 `PATCH /publishers/ht-dkkd` đổi `name`, `referenceKey`.
2. SO `:suspend` với lý do "Nghi lộ khóa client"; HTTT phát ngay sau đó.
3. SO `:resume`.
4. Bên phát thử không còn quan hệ: IE1 `:retire`.

**Kết quả mong đợi.** Bước 1 `200`. Bước 2 bên phát `SUSPENDED` với `suspendSource = SECURITY`, publication `SUSPENDED`; lượt phát bị từ chối 403-PQ trong ≤ 60 giây; EVT: `publication.state-changed`. Bước 3 về `ACTIVE`, publication `ACTIVE` không cần duyệt lại. Bước 4 `RETIRED`, mã không dùng lại được (ERR-10-002 khi tạo lại). KT: có cho cả bốn bước.

**Thông báo hiển thị.** ERR-10-002 "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-041 · Đổi trường bất biến; SO tiếp tục bên do người khác tạm ngừng; trạng thái sai <!--k:party-lifecycle-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-028 (Sửa, tạm ngừng, tiếp tục và ngừng dùng bên phát, bên nhận).

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-028 · API-10-035, 036, 094, 095 · ERR-10-003, 006, 009.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-SO, U-T68-TO; SB-THUE.

**Các bước.**

1. `PATCH /subscribers/ht-thue` đổi `partyType`, `systemCode`, `commType`.
2. TO `:suspend` SB-THUE; SO gọi `:resume`.
3. `:resume` bên nhận đang `ACTIVE`; `:suspend` không lý do.

**Kết quả mong đợi.** Bước 1 `400` ERR-10-003 cho cả ba trường. Bước 2 SO nhận 403-PQ (SO chỉ tiếp tục đối tượng `suspendSource = SECURITY`). Bước 3 `409` ERR-10-006; `400` ERR-10-009.

**Thông báo hiển thị.** ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-09 · Đồng bộ trạng thái với PH-01 và PH-04

**Mục tiêu.** Xác nhận HTTT tạm ngừng ở PH-01 hay luồng ngừng ở PH-04 kéo theo bên tham gia và quan hệ của nó trong ≤ 60 giây, và chỉ tiếp tục những gì do PH-01 tạm ngừng.

**Phủ.** FR-10-029; UC-10-08; EVT-10-07, 09; EVT-04-09; NFR-10-009; LGC-HUB-010, 011.

#### TC-10-042 · HTTT tạm ngừng ở PH-01 rồi hoạt động lại <!--k:sync-ph01-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-029 (Đồng bộ trạng thái với PH-01 và PH-04).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-10-029 · EVT-10-07, 09 · NFR-10-009 · LGC-HUB-010, 011.

**Tiền điều kiện, dữ liệu.** SIM-PH01; `HT-DKKD` có PB-DKKD, PB-DKKD-K; `HT-THUE` có SB-THUE (SB-THUE đã bị SO tạm ngừng trước đó với `suspendSource = SECURITY`).

**Các bước.**

1. SIM-PH01 phát sự kiện `HT-DKKD` sang `SUSPENDED`; đo thời gian tới khi lượt phát bị từ chối.
2. SIM-PH01 phát `HT-DKKD` và `HT-THUE` về `ACTIVE`.

**Kết quả mong đợi.** Bước 1 PB-DKKD, PB-DKKD-K và publication của chúng `SUSPENDED` với `suspendSource = PH01`; API phát trả 403-PQ trong ≤ 60 giây; ACL `WRITE` bị gỡ trong ≤ 2 phút. Bước 2 chỉ đối tượng có `suspendSource = PH01` tiếp tục; SB-THUE vẫn `SUSPENDED`. EVT: `publication.state-changed`. KT: có, chủ thể `system:dh-integration`.

**Thông báo hiển thị.** ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-043 · Luồng ngừng ở PH-04; sự kiện lặp và sự kiện lỡ <!--k:sync-ph04-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-029 (Đồng bộ trạng thái với PH-01 và PH-04).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-10-029 · EVT-04-09 · EVT-10-09.

**Tiền điều kiện, dữ liệu.** SIM-PH04; SB-FLOW có SUB-FLOW `ACTIVE`; PB-FLOW có publication `ACTIVE`.

**Các bước.**

1. SIM-PH04 phát EVT-04-09 cho `dkkd-dong-bo-thue` hai lần cùng `id`.
2. Đổi trực tiếp trạng thái luồng `dkkd-tong-hop` ở SIM-PH04 mà không phát sự kiện; chờ bộ đối soát mỗi giờ.

**Kết quả mong đợi.** Bước 1 SUB-FLOW `REVOKED`, SB-FLOW `RETIRED`; lần nhận thứ hai bị inbox bỏ qua (một dòng `inbox_event`, một EVT `subscription.state-changed`). Bước 2 bộ đối soát phát hiện và thu hồi publication của PB-FLOW.

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-10 · Publication: đề nghị, duyệt, cấp scope và ACL

**Mục tiêu.** Xác nhận "Quản lý publication" của Hub cũ có thêm duyệt bốn mắt, cấp đúng scope `topic:{topicName}:publish` và ACL literal, có hiệu lực trong ≤ 2 phút, tạm ngừng và thu hồi có hiệu lực không đợi token hết hạn.

**Phủ.** FR-10-030, 031, 032; UC-10-09; API-10-042…045, 096, 097, 059; UI-10-06, 09, 13; BR-10-016, 019, 020, 029; EVT-10-06, 07; LGC-HUB-012.

#### TC-10-044 · Đề nghị và duyệt publication HTTP, phát được trong 2 phút <!--k:pub-approve-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-030 (Đề nghị publication).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-030, 031 · API-10-043, 059 · UI-10-06, 13 · EVT-10-06 · NFR-10-008 · UC-10-09 · LGC-HUB-012.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; bên phát `tc-ht-qldd` từ TC-10-037; TP-GT `ACTIVE`.

**Các bước.**

1. IE1 `POST /publications` với `publisherCode = tc-ht-qldd`, `topicName = TP-GT`, `purpose` 30 ký tự, `expectedRatePerMinute = 60`.
2. IA1 duyệt ở UI-10-13.
3. Client của `HT-QLDD` xin token mới, phát một sự kiện.

**Kết quả mong đợi.** Bước 1 `201`, `publicationCode = pub-{ULID chữ thường}`, `PENDING_APPROVAL`. Bước 2 `ACTIVE`, `grantedScope = topic:t68.dkkd.doanh-nghiep.giai-the.v1:publish`; Keycloak có client scope tùy chọn; bundle OPA có cặp (client, topic). Bước 3 `202` trong ≤ 2 phút sau duyệt. EVT: `publication.activated`. KT: có (scope, hạn mức).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-045 · Publication trên topic ngừng khuyến nghị, trùng cặp, topic nhạy cảm, vượt hạn mức, tự duyệt <!--k:pub-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-030 (Đề nghị publication).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-030, 031 · API-10-043, 059 · ERR-10-008, 011, 024, 025, 051 · BR-10-016, 019, 029.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-TA; TP-TD `DEPRECATED`; TP-KS `SENSITIVE`; `HT-QLDD` chưa đạt cấp độ ATTT tenant yêu cầu; T92 hạn mức sản xuất 1 MiB/s đã phân bổ hết.

**Các bước.**

1. Đề nghị publication `tc-ht-qldd` trên TP-TD.
2. Đề nghị lần hai cho cặp (`ht-dkkd`, TP-CP).
3. Đề nghị `tc-ht-qldd` trên TP-KS.
4. Ở T92 duyệt publication có `quotaBytesPerSecond = 524288`.
5. TA đề nghị rồi tự duyệt.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-025. Bước 2 `409` ERR-10-024. Bước 3 `422` ERR-10-051. Bước 4 `422` ERR-10-011. Bước 5 `403` ERR-10-008.

**Thông báo hiển thị.** ERR-10-008 "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."; ERR-10-011 "Vượt hạn mức của tenant: {tên hạn mức} đang dùng {đã dùng}/{trần}."; ERR-10-024 "Đã có quan hệ cho cặp này: {mô tả}."; ERR-10-025 "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."; ERR-10-051 "Bên {mã} chưa đạt cấp độ ATTT yêu cầu cho topic {phân loại}."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-046 · Tạm ngừng có hiệu lực trước khi token hết hạn; tiếp tục; thu hồi <!--k:pub-suspend-revoke-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-032 (Tạm ngừng, tiếp tục và thu hồi publication).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-032 · API-10-045, 096, 097 · ERR-10-006, 102 · EVT-10-07 · BR-10-020 · NFR-10-009.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-IE1; publication của PB-DKKD trên TP-CP; token của C-DKKD còn hạn 5 phút; publication của PB-DKKD-K trên TP-GT.

**Các bước.**

1. TO `:suspend` publication HTTP; C-DKKD phát liên tục bằng token cũ.
2. TO `:suspend` publication Kafka; producer đang mở kết nối tiếp tục gửi.
3. TO `:resume` cả hai.
4. IE1 `:revoke` publication HTTP; TO gọi `:resume` publication đã thu hồi.

**Kết quả mong đợi.** Bước 1 lượt phát bị từ chối 403-PQ trong ≤ 60 giây dù token còn hạn. Bước 2 producer nhận `TopicAuthorizationException` trong ≤ 2 phút. Bước 3 phát lại được, không cần duyệt. Bước 4 `REVOKED`, scope gỡ khỏi client; `:resume` trả `409` ERR-10-006. EVT: `publication.state-changed` cho mỗi lần đổi.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."; ERR-10-102 "Token chưa có quyền {publish hoặc subscribe} trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-11 · Phát sự kiện qua API phát

**Mục tiêu.** Xác nhận event message của Bus cũ được thay bằng API phát CloudEvents có kiểm tra lược đồ, khóa phân vùng, `acks=all`, chống trùng và cô lập tenant theo tiền tố topic.

**Phủ.** FR-10-033, 024; UC-10-10; API-10-079, 084; BR-10-001, 006, 007, 009, 011, 021; ERR-10-101…108, 121; LGC-BUS-039.

#### TC-10-047 · Phát một sự kiện và một lô, đúng phân vùng theo khóa <!--k:publish-ok-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-033 (Phát sự kiện qua API phát).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-033, 013 · API-10-079 · UC-10-10 · BR-10-006, 007 · LGC-BUS-039.

**Tiền điều kiện, dữ liệu.** C-DKKD có scope `topic:{TP-CP}:publish`; F-CE-OK.

**Các bước.**

1. `POST /event/v1/topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/events` với một sự kiện `application/cloudevents+json`, không có `time`.
2. Gửi lô 100 sự kiện `application/cloudevents-batch+json`, mỗi khóa xuất hiện 2 lần.
3. Đọc bản tin trên Kafka bằng `kcat`.

**Kết quả mong đợi.** Bước 1 `202`, `results[0]` có `partition`, `offset`, `schemaVersion = 4`. Bước 2 `202`, 100 kết quả. Bước 3 tiêu đề `ce_*` đủ theo FRS §4.9, `time` được bổ sung, `dhtenant = T68`, khóa bản tin là `maDoanhNghiep`; hai sự kiện cùng khóa cùng phân vùng, đúng thứ tự; giá trị có tiền tố định danh lược đồ (byte 0 và `contentId`).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-048 · Phong bì sai, nguồn giả, dữ liệu sai lược đồ, thiếu khóa, quá cỡ <!--k:publish-invalid-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-033 (Phát sự kiện qua API phát).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-033 · API-10-079 · ERR-10-104, 105, 106 · BR-10-006, 011, 021.

**Tiền điều kiện, dữ liệu.** C-DKKD; F-CE-BAD.

**Các bước.**

1. Sự kiện thiếu `specversion`.
2. `source = /t68/systems/HT-THUE` (HTTT khác client).
3. `data` thiếu `maDoanhNghiep` (TP-CP `orderingRequired`).
4. Lô 100 sự kiện trong đó sự kiện thứ 3 sai lược đồ.
5. Lô 101 sự kiện; lô 1,2 MiB.
6. Gửi `dhtenant = T01` trong thân.

**Kết quả mong đợi.** Bước 1, 2 `400` ERR-10-104. Bước 3 `422` ERR-10-105. Bước 4 `422` ERR-10-105 `failedIndex = 2`; không bản tin nào của lô được ghi (giao dịch Kafka). Bước 5 `413` ERR-10-106. Bước 6 `202` nhưng `dhtenant` trên Kafka bị ghi đè thành `T68`.

**Thông báo hiển thị.** ERR-10-104 "Sự kiện không đúng CloudEvents 1.0 ({thuộc tính}) hoặc source không thuộc hệ thống của token."; ERR-10-105 "Dữ liệu sự kiện không khớp lược đồ phiên bản {n} ở trường {đường dẫn}, hoặc thiếu khóa phân vùng bắt buộc."; ERR-10-106 "Sự kiện hoặc lô vượt kích thước cho phép ({giới hạn})."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-049 · Token sai, thiếu scope, topic khác tenant, topic không hoạt động <!--k:publish-authz-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-033 (Phát sự kiện qua API phát).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-033, 064 · API-10-079 · ERR-10-101, 102, 103 · BR-10-001, 016.

**Tiền điều kiện, dữ liệu.** C-DKKD (T68), C-DKKD-T01 (T01, có scope trên topic T01 cùng tên trừ tiền tố); TP-GT `RETIRED` từ TC-10-023.

**Các bước.**

1. Không có token; token hết hạn.
2. C-THUE (không có publication) phát lên TP-CP.
3. C-DKKD phát lên `t01.dkkd.doanh-nghiep.da-cap-phep.v1`.
4. C-DKKD-T01 phát lên `t68.dkkd.doanh-nghiep.da-cap-phep.v1`.
5. Phát lên `t68.dkkd.khong-co.su-kien.v1` và lên TP-GT.

**Kết quả mong đợi.** Bước 1 `401` ERR-10-101. Bước 2 403-PQ. Bước 3, 4, 5 404-ẩn ERR-10-103 với thân giống hệt nhau trừ `traceId`. Không có bản tin nào trên topic của T01 hay T68.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."; ERR-10-101 "Token truy cập không hợp lệ hoặc đã hết hạn. Lấy token mới rồi gửi lại."; ERR-10-102 "Token chưa có quyền {publish hoặc subscribe} trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động."; ERR-10-103 "Topic {tên} không tồn tại, không nhận sự kiện ở trạng thái hiện tại hoặc thuộc tenant khác."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-050 · Chống trùng phát theo id và Idempotency-Key <!--k:publish-dedup-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-033 (Phát sự kiện qua API phát).

**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API, RT.

**Truy vết.** FR-10-033 · API-10-079 · BR-10-009.

**Tiền điều kiện, dữ liệu.** C-DKKD; sự kiện `id = 01JDTC0000000000000000DUP1`.

**Các bước.**

1. Gửi cùng sự kiện ba lần liên tiếp.
2. Gửi hai lượt song song cùng `id`.
3. Dừng Valkey, gửi một sự kiện mới hai lần.

**Kết quả mong đợi.** Bước 1, 2 mọi lượt `202` cùng `partition`, `offset`; trên Kafka chỉ một bản tin. Bước 3 cả hai lượt `202`, có hai bản tin (chống trùng bị bỏ qua), chỉ số `dh_event_dedup_bypass_total` tăng 2.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-051 · Hạn mức phát và không đủ bản sao đồng bộ <!--k:publish-quota-isr-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-033 (Phát sự kiện qua API phát).

**Loại.** Âm, Khả dụng.

**Ưu tiên.** P1.

**Tự động.** k6, Chaos.

**Truy vết.** FR-10-033, 062 · API-10-079 · ERR-10-107, 108 · BR-10-007.

**Tiền điều kiện, dữ liệu.** C-DKKD với hạn mức `limit-count` 100 lượt/phút ở SIT; TP-CP.

**Các bước.**

1. Phát 150 lượt trong một phút.
2. Dừng hai trong ba broker, phát một sự kiện.

**Kết quả mong đợi.** Bước 1 lượt vượt trả `429` ERR-10-107 có `Retry-After`. Bước 2 `503` ERR-10-108, không hạ `acks`; sau khi broker trở lại lượt phát kế tiếp `202`. Không có sự kiện nào được trả `202` mà không có trên Kafka.

**Thông báo hiển thị.** ERR-10-107 "Vượt hạn mức phát hoặc kéo. Thử lại sau {Retry-After} giây."; ERR-10-108 "Cụm sự kiện tạm thời không đủ bản sao để ghi an toàn; sự kiện chưa được nhận. Thử lại sau."

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

#### TC-10-052 · Tra cứu lược đồ chỉ đọc theo scope <!--k:registry-lookup-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-024 (Cung cấp tra cứu lược đồ cho bên ngoài).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-024 · API-10-084 · ERR-10-102, 103.

**Tiền điều kiện, dữ liệu.** C-DKKD (publish TP-CP), C-THUE (không scope trên TP-GT).

**Các bước.**

1. C-DKKD `GET /event/v1/registry/apis/ccompat/v7/subjects/{TP-CP}-value/versions/latest`.
2. C-THUE đọc artifact của TP-GT.
3. C-DKKD đọc artifact nhóm `t01`.

**Kết quả mong đợi.** Bước 1 `200` lược đồ v4. Bước 2 403-PQ. Bước 3 404-ẩn ERR-10-103.

**Thông báo hiển thị.** ERR-10-102 "Token chưa có quyền {publish hoặc subscribe} trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động."; ERR-10-103 "Topic {tên} không tồn tại, không nhận sự kiện ở trạng thái hiện tại hoặc thuộc tenant khác."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-12 · Phát trực tiếp qua Kafka và giám sát tuân thủ

**Mục tiêu.** Xác nhận nhóm Message Broker của Tooling được thay bằng phát Kafka trực tiếp có điều kiện bắt buộc (idempotent, serde Apicurio, tiêu đề CloudEvents) và giám sát tuân thủ phát hiện bên phát vi phạm.

**Phủ.** FR-10-034, 023; UC-10-11; BR-10-007, 008; ERR-10-119, 120; EVT-10-14; LGC-TOOL-010.

#### TC-10-053 · Bên phát Kafka ngoài ghi đúng chuẩn qua SASL OAUTHBEARER <!--k:kafka-produce-ok-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-034 (Phát sự kiện trực tiếp qua Kafka).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** FR-10-034 · BR-10-008 · LGC-TOOL-010.

**Tiền điều kiện, dữ liệu.** PB-DKKD-K có publication trên TP-GT; client Java `acks=all`, `enable.idempotence=true`, serde Apicurio `auto.register=false`, token Keycloak `client_credentials`.

**Các bước.**

1. Kết nối listener `external` cổng 9093 với `sasl.mechanism=OAUTHBEARER`; gửi 1.000 bản tin có tiêu đề `ce_*`.
2. Đọc lại bằng consumer của SUB-KAFKA.

**Kết quả mong đợi.** Ghi thành công; principal theo `azp`; bản tin có tiền tố lược đồ hợp lệ; giám sát tuân thủ không ghi vi phạm.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-054 · Ghi ngoài ACL, ghi topic khác, bản tin không có định danh lược đồ <!--k:kafka-produce-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-034 (Phát sự kiện trực tiếp qua Kafka).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT, RT.

**Truy vết.** FR-10-034, 023 · ERR-10-119, 120 · EVT-10-14 · BR-10-008.

**Tiền điều kiện, dữ liệu.** PB-DKKD-K; `10.compliance.sample-ratio = 1` ở SIT, ngưỡng 10.

**Các bước.**

1. Ghi lên TP-CP (không có publication cho PB-DKKD-K).
2. Ghi lên `t01.dkkd.doanh-nghiep.da-cap-phep.v1`.
3. Ghi 20 bản tin JSON thô không tiền tố lược đồ lên TP-GT trong 15 phút.

**Kết quả mong đợi.** Bước 1, 2 `TopicAuthorizationException`; chỉ số ERR-10-120 theo principal. Bước 3 ghi được (Kafka không kiểm lược đồ) nhưng giám sát ghi 20 vi phạm ERR-10-119, `GET /topics/{TP-GT}/compliance` liệt kê publication vi phạm; EVT: `compliance.violated` một lần khi vượt ngưỡng; PH-18 nhận việc.

**Thông báo hiển thị.** ERR-10-119 nhãn "Bản tin không có định danh lược đồ"; ERR-10-120 nhãn "Kafka từ chối do ACL, hạn mức".

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-055.
:::

#### TC-10-055 · SO tạm ngừng publication vi phạm lược đồ <!--k:kafka-compliance-suspend-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-023 (Giám sát tuân thủ lược đồ của bên phát Kafka trực tiếp).

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-10-023, 032 · API-10-031, 045 · UI-10-06 · UC-10-11.

**Tiền điều kiện, dữ liệu.** U-T68-SO; vi phạm từ TC-10-054.

**Các bước.**

1. Mở tab "Tuân thủ" ở UI-10-06; bấm "Tạm ngừng publication" với lý do.

**Kết quả mong đợi.** Publication `SUSPENDED` với `suspendSource = SECURITY`; ACL `WRITE` gỡ trong ≤ 2 phút; producer nhận lỗi quyền.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

### TS-10-13 · Subscription: đề nghị, xác minh endpoint, duyệt

**Mục tiêu.** Xác nhận "Quản lý subscription: URI nhận, số worker, số lần thử lại, thời điểm bắt đầu" của Hub cũ có thêm xác minh endpoint chống lạm dụng, kiểm SSRF, duyệt bốn mắt và cấp phát đúng theo chế độ giao nhận.

**Phủ.** FR-10-035, 036, 037, 040; UC-10-12, 13; API-10-046…048, 051, 091, 120, 059; UI-10-11, 12, 13; BR-10-017, 019, 022, 025, 026; EVT-10-08; LGC-HUB-013.

#### TC-10-056 · Đề nghị subscription PUSH, xác minh endpoint, duyệt, giao trong 2 phút <!--k:sub-push-approve-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-035 (Đề nghị subscription).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-035, 036, 037 · API-10-047, 051, 059, 120 · UI-10-11, 13 · EVT-10-08 · NFR-10-008 · UC-10-12, 13 · LGC-HUB-013.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; bên nhận thử `tc-ht-thue2` (`WEBHOOK_PUSH`); SIM-WH `https://hooks.sim.test/tc` trả `WebHook-Allowed-Origin: event.t68.datahub`.

**Các bước.**

1. Ở UI-10-11 chọn TP-CP, chế độ ĐẨY, URI, `workerCount = 3`, `maxRetries = 5`, `startPosition = LATEST`; bấm "Xác minh endpoint" rồi "Gửi đề nghị".
2. IA1 duyệt.
3. IE1 gọi `POST /subscriptions/{subscriptionCode}/signing-keys:claim` hai lần.
4. Phát một sự kiện lên TP-CP.

**Kết quả mong đợi.** Bước 1 `POST /endpoint-verifications` trả `result = PASSED` (SIM-WH nhận `OPTIONS` có `WebHook-Request-Origin`); `POST /subscriptions` trả `201`, mã mặc định `tc-ht-thue2-doanh-nghiep-da-cap-phep` khi không nhập. Bước 2 `PROVISIONING` rồi `ACTIVE`, `consumerGroup = dh-sub-t68-{subscriptionCode}`, nhóm khởi tạo ở cuối topic. Bước 3 lần đầu trả khóa `whsec_…` một lần, lần hai `409` ERR-10-006. Bước 4 SIM-WH nhận trong ≤ 2 phút sau duyệt. EVT: `subscription.activated`.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-057 · Endpoint không hợp lệ: HTTP, tự ký, chuyển hướng, IP riêng, ngoài egress, bắt tay sai <!--k:sub-endpoint-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-035 (Đề nghị subscription).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, ZAP.

**Truy vết.** FR-10-035, 036 · API-10-047, 051 · ERR-10-026, 027 · BR-10-026.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; SIM-WH-BAD; `https://hooks.sim.test/no-origin` không trả `WebHook-Allowed-Origin`.

**Các bước.**

1. Xác minh lần lượt `http://plain.sim.test`, `https://10.96.0.10/h`, `https://ngoai-egress.example/h`.
2. Xác minh `https://selfsigned.sim.test/h`, `https://redirect.sim.test/h`, `https://hooks.sim.test/no-origin`.
3. Đề nghị subscription với endpoint đã xác minh cách đây 25 giờ.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-026. Bước 2 `422` ERR-10-027 với lý do TLS, chuyển hướng (không theo), thiếu tiêu đề. Bước 3 hệ thống chạy lại xác minh; thất bại thì `422` ERR-10-027. Không có lượt kết nối nào tới `10.0.0.5` hay `10.96.0.10` ở nhật ký egress gateway.

**Thông báo hiển thị.** ERR-10-026 "Địa chỉ nhận không hợp lệ: chỉ nhận HTTPS, tên miền trong danh sách egress, không trỏ địa chỉ nội bộ."; ERR-10-027 "Xác minh địa chỉ nhận chưa đạt hoặc đã quá 24 giờ."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-058 · Tổ hợp chế độ, worker vượt phân vùng, thời điểm ngoài lưu giữ, trùng cặp, topic nhạy cảm <!--k:sub-create-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-035 (Đề nghị subscription).

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-035, 040 · API-10-047 · ERR-10-011, 024, 025, 028, 030, 031, 051 · BR-10-017, 019, 025.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; U-T01-IE; T92 đã có 2 subscription.

**Các bước.**

1. SB-THUE (`WEBHOOK_PUSH`) với `deliveryMode = PULL_API`; SB-THUE với `INTERNAL`.
2. `workerCount = 7` trên TP-CP 6 phân vùng; `workerCount = 6` (biên).
3. `startPosition = TIMESTAMP`, `startAt` 10 ngày trước (lưu giữ 7 ngày).
4. Đề nghị lần hai cặp (SB-THUE, TP-CP).
5. Bên nhận chưa đạt cấp độ ATTT trên TP-KS; subscription TP-KS thiếu `legalBasis`.
6. U-T01-IE đề nghị `PULL_KAFKA`; T92 đề nghị subscription thứ ba.

**Kết quả mong đợi.** Bước 1 `400` ERR-10-003. Bước 2: 7 trả `422` ERR-10-030; 6 được nhận. Bước 3 `422` ERR-10-031 có `availableRange[]`. Bước 4 `409` ERR-10-024. Bước 5 `422` ERR-10-051; `400` ERR-10-003. Bước 6 `422` ERR-10-028; `422` ERR-10-011.

**Thông báo hiển thị.** ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-011 "Vượt hạn mức của tenant: {tên hạn mức} đang dùng {đã dùng}/{trần}."; ERR-10-024 "Đã có quan hệ cho cặp này: {mô tả}."; ERR-10-025 "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."; ERR-10-028 "Tenant chưa bật Kafka ngoài. Đề nghị quản trị nền tảng bật trước khi dùng chế độ này."; ERR-10-030 "Số worker tối đa {n} (bằng số phân vùng của topic hoặc trần của tenant)."; ERR-10-031 "Thời điểm bắt đầu phải trong khoảng lưu giữ của topic: từ {thời điểm sớm nhất}."; ERR-10-051 "Bên {mã} chưa đạt cấp độ ATTT yêu cầu cho topic {phân loại}."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-059 · Điểm bắt đầu EARLIEST và TIMESTAMP <!--k:sub-start-position-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-040 (Điểm bắt đầu và offset bắt đầu).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-040 · API-10-047 · BR-10-022 · LGC-HUB-013.

**Tiền điều kiện, dữ liệu.** TP-CP có 5.000 bản tin trong 3 ngày gần nhất; hai bên nhận thử.

**Các bước.**

1. Subscription A `EARLIEST`; subscription B `TIMESTAMP` tại đầu ngày hôm qua; duyệt cả hai.
2. Đọc offset đã commit ban đầu của hai nhóm.

**Kết quả mong đợi.** Phản hồi đề nghị A có cảnh báo số bản tin ước lượng và thời gian giao hết. A bắt đầu từ offset sớm nhất còn trên cụm; B từ offset trả bởi `offsetsForTimes` theo từng phân vùng. Nhóm do PH-10 khởi tạo vị trí, bộ giao nhận chạy với `auto.offset.reset=none`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-060 · OR đề nghị cho HTTT của tổ chức mình; ngoài tổ chức; bốn mắt; ngoại lệ xác minh <!--k:sub-or-waive-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-035 (Đề nghị subscription).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-035, 036, 037 · API-10-047, 059, 091 · ERR-10-008, 044, 012.

**Tiền điều kiện, dữ liệu.** U-T68-OR (`SO-TC`); SB-TC; SB-THUE (`SO-CT`); U-T68-TA; U-T68-IA1.

**Các bước.**

1. OR đề nghị subscription SB-TC trên TP-CP.
2. OR đề nghị subscription SB-THUE.
3. TA đề nghị rồi tự duyệt một subscription.
4. TA cấp ngoại lệ xác minh 7 ngày cho endpoint nội mạng của tỉnh; cấp 400 ngày.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 403-TC. Bước 3 `403` ERR-10-008. Bước 4: 7 ngày `200`, `lastVerification.result = WAIVED` có hạn; 400 ngày `422` ERR-10-012. KT: có cho ngoại lệ.

**Thông báo hiển thị.** ERR-10-008 "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."; ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."; ERR-10-044 ST-07 "Đối tượng ngoài phạm vi tổ chức của bạn."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-14 · Giao nhận ĐẨY: webhook ký HMAC và khóa ký

**Mục tiêu.** Chứng minh mọi lượt giao đẩy có chữ ký HMAC đúng ADR-044, có thể xác minh ở đầu nhận, không bao giờ gửi không ký, và xoay, thu hồi khóa không làm gián đoạn.

**Phủ.** FR-10-038, 042; UC-10-14, 17; API-10-054, 100, 120; BR-10-009, 025, 026, 027; ERR-10-115, 117; EVT-10-13; NFR-10-003, 016; ADR-071.

#### TC-10-061 · Chữ ký HMAC và tiêu đề webhook đúng đặc tả <!--k:hmac-sign-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** RT, UT.

**Truy vết.** FR-10-038 · BR-10-009 · UC-10-14 · ADR-071 · LGC-HUB-013.

**Tiền điều kiện, dữ liệu.** SUB-PUSH `CLOUDEVENTS_STRUCTURED`; SIM-WH nạp khóa ký hiện hành.

**Các bước.**

1. Phát một sự kiện lên TP-CP.
2. Ở SIM-WH tính lại `HMAC-SHA256(secret, "{Webhook-Id}.{Webhook-Timestamp}.{body}")`.
3. Lặp với subscription thử `CLOUDEVENTS_BINARY`.

**Kết quả mong đợi.** Yêu cầu `POST` có `Webhook-Id` bằng `ce_id`, `Webhook-Timestamp` trong 5 giây so với giờ chuẩn, `X-Datahub-Signature: t={ts},v1={hex}`, `X-Datahub-Subscription`, `X-Datahub-Attempt: 1`, `X-Datahub-Key-Id`, `traceparent`; thân `application/cloudevents+json`. Chữ ký tính lại khớp. Bước 3 tiêu đề `ce-*`, thân là `data` JSON, chữ ký tính trên thân đó.

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-062.
:::

#### TC-10-062 · Đầu nhận từ chối chữ ký sửa, dấu thời gian lệch, phát lại cùng Webhook-Id <!--k:hmac-verify-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** UT, RT.

**Truy vết.** FR-10-038 · BR-10-009 · NFR-10-007.

**Tiền điều kiện, dữ liệu.** Thư viện xác minh mẫu (Java, .NET, Python, Node.js, PHP) ở tài liệu hướng dẫn tích hợp; bản ghi yêu cầu thật từ TC-10-061.

**Các bước.**

1. Sửa một byte thân rồi xác minh.
2. Lùi `Webhook-Timestamp` 400 giây (dung sai 300 giây).
3. Gửi lại nguyên yêu cầu lần hai.

**Kết quả mong đợi.** Bước 1, 2 cả năm thư viện mẫu từ chối. Bước 3 thư viện mẫu nhận diện trùng theo `Webhook-Id` và không xử lý lại. Ca chứng minh mã mẫu đúng hướng dẫn.

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-063 · Không đọc được khóa ký thì không gửi <!--k:hmac-no-key-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** Chaos, RT.

**Truy vết.** FR-10-038 · ERR-10-117 · BR-10-024, 027.

**Tiền điều kiện, dữ liệu.** SUB-PUSH; đệm khóa 10 phút.

**Các bước.**

1. Dừng OpenBao; phát 10 sự kiện ngay; chờ 11 phút; phát 10 sự kiện nữa.
2. Bật lại OpenBao.

**Kết quả mong đợi.** 10 sự kiện đầu giao bình thường bằng khóa trong đệm. Sau khi đệm hết hạn, phân vùng tạm dừng với ERR-10-117, cảnh báo; SIM-WH không nhận yêu cầu nào thiếu chữ ký; offset không commit. Bước 2 giao tiếp 10 sự kiện còn lại, không mất.

**Thông báo hiển thị.** ERR-10-117 nhãn "Không đọc được khóa ký".

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-064 · Xoay khóa có thời gian chồng lấn hai chữ ký <!--k:key-rotate-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-042 (Xoay khóa ký webhook).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-042 · API-10-054 · EVT-10-13 · UC-10-17 · BR-10-027.

**Tiền điều kiện, dữ liệu.** U-T68-TO; SUB-PUSH; `10.push.key-rotation-overlap-days = 7`.

**Các bước.**

1. `POST /subscriptions/ht-thue-dn-cap-phep/signing-keys:rotate` có `Idempotency-Key`.
2. Phát sự kiện; đặt đồng hồ +8 ngày, phát tiếp.

**Kết quả mong đợi.** Bước 1 `200`, khóa mới `whsec_…` hiển thị một lần, khóa cũ `PREVIOUS` với `previousUntil`. Bước 2 trong 7 ngày tiêu đề có hai giá trị `v1=`, đầu nhận dùng khóa cũ hay mới đều xác minh được; sau 7 ngày chỉ còn chữ ký khóa mới. EVT: `signing-key.rotated`. Mồi sạch với cả hai khóa.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-065 · Thu hồi khẩn khóa ký; quyền xoay; SO không thu hồi ngoài sự cố <!--k:key-revoke-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-042 (Xoay khóa ký webhook).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-042 · API-10-054, 100 · ERR-10-009 · EVT-10-13.

**Tiền điều kiện, dữ liệu.** U-T68-SO, U-T68-IE1, U-T68-VW; SUB-PUSH.

**Các bước.**

1. SO `:revoke` có lý do "Khóa bị lộ trong nhật ký đầu nhận".
2. Phát sự kiện.
3. IE1 `:rotate`; U-T68-VW `:rotate`; SO `:revoke` không có lý do.

**Kết quả mong đợi.** Bước 1 `200`, khóa cũ `REVOKED` ngay, không có thời gian chồng lấn, khóa mới sinh và hiển thị một lần. Bước 2 chỉ có chữ ký khóa mới. Bước 3 IE1 `200` (có `PERM-10-subscribe`); VW 403-PQ; SO không lý do `400` ERR-10-009.

**Thông báo hiển thị.** ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-066 · Chặn DNS rebinding và đổi IP giữa các lượt <!--k:push-ssrf-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** RT, ZAP.

**Truy vết.** FR-10-038 · ERR-10-114, 115 · BR-10-026.

**Tiền điều kiện, dữ liệu.** Subscription thử tới `https://rebind.sim.test/h` đã xác minh khi DNS trả IP công cộng.

**Các bước.**

1. Đổi DNS sang `10.96.0.10`; phát sự kiện.
2. Đổi đầu nhận của subscription thử khác sang chứng thư hết hạn; phát sự kiện.

**Kết quả mong đợi.** Bộ giao nhận kiểm lại IP trước lượt, không gửi; lượt lỗi ERR-10-115 `failureClass = SECURITY`; sau hết lượt thử vào DLQ; không có kết nối tới `10.96.0.10`. Bước 2 lượt lỗi ERR-10-114, không gửi thân qua kết nối TLS không tin cậy.

**Thông báo hiển thị.** ERR-10-114 nhãn "Lỗi TLS, chứng thư"; ERR-10-115 nhãn "Địa chỉ đích bị chặn".

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-15 · Thử lại giãn dần, ngắt mạch và DLQ

**Mục tiêu.** Chứng minh giao ít nhất một lần: lỗi tạm thời thử lại giãn dần giữ thứ tự trong phân vùng; hết lượt thì vào DLQ hoặc chặn theo `failurePolicy`; offset chỉ commit sau khi giao xong hoặc đã ghi chắc DLQ.

**Phủ.** FR-10-039, 049; UC-10-14; API-10-086, 119; BR-10-009, 023, 024, 025; ERR-10-111…113, 116; EVT-10-11.

#### TC-10-067 · Thử lại giãn dần có nhiễu, tôn trọng Retry-After, giữ thứ tự <!--k:retry-backoff-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-039 (Thử lại giãn dần và chính sách khi thất bại).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** RT, UT.

**Truy vết.** FR-10-039 · BR-10-025 · ERR-10-112 · LGC-HUB-013.

**Tiền điều kiện, dữ liệu.** SUB-PUSH (`maxRetries = 3`, 100 ms ×2); SIM-WH trả `503` hai lần rồi `200` cho khóa `0999000001`; trả `429` `Retry-After: 1` cho khóa `0999000002`.

**Các bước.**

1. Phát 3 sự kiện khóa `0999000001` liên tiếp và 1 sự kiện khóa `0999000002`.

**Kết quả mong đợi.** Khóa 1: khoảng chờ lần 1, 2 trong 80…120 ms và 160…240 ms; `X-Datahub-Attempt` tăng 1, 2, 3; sự kiện thứ hai cùng khóa chỉ gửi sau khi sự kiện đầu thành công. Khóa 2 chờ 1 giây theo `Retry-After`. Các phân vùng khác không bị chặn. Không có mục DLQ.

**Thông báo hiển thị.** ERR-10-112 nhãn "Đầu nhận lỗi tạm thời (5xx, 408, 425, 429)".

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-068 · Hết lượt thử với DEAD_LETTER: ghi DLQ rồi đi tiếp <!--k:retry-dead-letter-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-039 (Thử lại giãn dần và chính sách khi thất bại).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** RT, API.

**Truy vết.** FR-10-039, 049 · ERR-10-111, 112, 113 · EVT-10-11 · BR-10-023, 024.

**Tiền điều kiện, dữ liệu.** SUB-PUSH; SIM-WH luôn `500` cho khóa `0999000010`, trả `410` cho khóa `0999000011`, chậm 15 giây (quá `timeoutMs`) cho khóa `0999000012`.

**Các bước.**

1. Phát một sự kiện mỗi khóa, rồi 5 sự kiện khóa khác.
2. Đọc topic `{TP-CP}.dlq` và `GET /dlq-entries?subscriptionCode=ht-thue-dn-cap-phep`.

**Kết quả mong đợi.** Khóa `…10` thử 4 lần rồi vào DLQ ERR-10-112, `attempts = 4`; khóa `…11` vào DLQ ngay ERR-10-113 (lỗi vĩnh viễn, không thử lại); khóa `…12` mỗi lượt ghi ERR-10-111 rồi vào DLQ sau hết lượt. 5 sự kiện sau được giao. Bản tin DLQ giữ nguyên khóa, tiêu đề, giá trị và có đủ tiêu đề `dh_dlq_*`, `dh_dlq_origin = PUSH`. Hai mục `NEW` ở `dlq_entry`. EVT: `delivery.dead-lettered` gộp trong 1 phút.

**Thông báo hiển thị.** ERR-10-111 nhãn "Quá thời gian chờ"; ERR-10-112 nhãn "Đầu nhận lỗi tạm thời (5xx, 408, 425, 429)"; ERR-10-113 nhãn "Đầu nhận từ chối".

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu. Giữ dữ liệu cho TC-10-076.
:::

#### TC-10-069 · Hết lượt thử với BLOCK: tạm ngừng, không commit, TO tiếp tục <!--k:retry-block-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-039 (Thử lại giãn dần và chính sách khi thất bại).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** RT, API.

**Truy vết.** FR-10-039, 041 · API-10-086, 098 · ERR-10-006 · EVT-10-09.

**Tiền điều kiện, dữ liệu.** SUB-KS (`BLOCK`); SIM-WH luôn `500`; U-T68-TO.

**Các bước.**

1. Phát 3 sự kiện lên TP-KS.
2. Gọi API nội bộ `POST /runtime/subscriptions/ht-thue-khai-sinh:resume` bằng S-RT-T68.
3. Sửa SIM-WH về `200`; TO `:resume` với lý do.

**Kết quả mong đợi.** Bước 1 sau hết lượt, subscription `SUSPENDED` với `suspendSource = DELIVERY_BLOCKED`, không có mục DLQ, offset không tiến, lag tăng. Bước 2 `409` ERR-10-006 (tự tiếp tục chỉ cho `CIRCUIT_BREAKER`). Bước 3 `ACTIVE`, 3 sự kiện được giao đúng thứ tự. EVT: `subscription.state-changed` hai lần.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-070 · Ngắt mạch khi lỗi kéo dài và tự tiếp tục khi thăm dò thành công <!--k:circuit-breaker-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-039 (Thử lại giãn dần và chính sách khi thất bại).

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** RT.

**Truy vết.** FR-10-039 · API-10-086, 119 · EVT-10-09.

**Tiền điều kiện, dữ liệu.** SUB-PUSH; `10.push.suspend-after-failures-minutes = 5` ở SIT; SIM-WH lỗi 60 %.

**Các bước.**

1. Phát 10 sự kiện/giây trong 6 phút.
2. Đưa SIM-WH về `200`; chờ 5 phút.

**Kết quả mong đợi.** Bước 1 subscription `SUSPENDED`, `suspendSource = CIRCUIT_BREAKER`; một worker thăm dò gửi bản tin đầu chưa commit mỗi 5 phút. Bước 2 lượt thăm dò thành công, subscription tự về `ACTIVE`, giao tiếp không mất.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-071 · Không giải tuần tự được vào DLQ ngay; ghi DLQ lỗi thì không commit <!--k:dlq-deser-write-fail-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-049 (Chuyển sự kiện giao thất bại vào DLQ tầng sự kiện).

**Loại.** Âm, Khả dụng.

**Ưu tiên.** P1.

**Tự động.** RT, Chaos.

**Truy vết.** FR-10-049, 038 · ERR-10-116, 029 · BR-10-024.

**Tiền điều kiện, dữ liệu.** SUB-PUSH; bản tin rác ghi thẳng lên TP-CP bằng principal kiểm thử; ACL ghi `{TP-CP}.dlq` của `dh-runtime-t68` có thể gỡ.

**Các bước.**

1. Ghi một bản tin có tiền tố `contentId` không tồn tại.
2. Gỡ ACL ghi DLQ, cho SIM-WH trả `410` cho một sự kiện hợp lệ.
3. Khôi phục ACL.

**Kết quả mong đợi.** Bước 1 vào DLQ ngay ERR-10-116, `failureClass = DESERIALIZATION`, không thử lại. Bước 2 phân vùng tạm dừng, thử ghi DLQ mỗi 5 giây, cảnh báo nghiêm trọng, offset không commit. Bước 3 mục DLQ được ghi, phân vùng chạy tiếp. Không sự kiện nào bị bỏ qua mà không có mục DLQ.

**Thông báo hiển thị.** ERR-10-029 "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."; ERR-10-116 nhãn "Không giải được bản tin".

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

### TS-10-16 · Vận hành subscription: tạm dừng, sửa, thu hồi, thống kê

**Mục tiêu.** Xác nhận người vận hành tạm dừng, tiếp tục, sửa và thu hồi subscription có hiệu lực nhanh, không mất vị trí đọc, và xem được thống kê giao nhận thay phần theo dõi của Hub cũ.

**Phủ.** FR-10-041, 046, 047, 056; UC-10-16; API-10-048…050, 052, 053, 098, 099; UI-10-12; BR-10-020, 025; EVT-10-09; NFR-10-011; LGC-HUB-013.

#### TC-10-072 · Tạm dừng dừng giao trong 10 giây, tiếp tục từ vị trí cũ <!--k:sub-pause-resume-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-041 (Tạm dừng, tiếp tục subscription).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, RT, E2E.

**Truy vết.** FR-10-041 · API-10-050, 098 · UI-10-12 · EVT-10-09 · NFR-10-011 · UC-10-16.

**Tiền điều kiện, dữ liệu.** U-T68-TO; SUB-PUSH, SUB-PULL, SUB-KAFKA; phát nền 20 sự kiện/giây.

**Các bước.**

1. TO tạm dừng SUB-PUSH ở UI-10-12 với lý do "HTTT thuế bảo trì".
2. Tạm dừng SUB-PULL; HTTT kéo. Tạm dừng SUB-KAFKA; consumer ngoài đọc.
3. Sau 5 phút tiếp tục cả ba.

**Kết quả mong đợi.** Bước 1 `PAUSED`; SIM-WH không nhận lượt mới sau ≤ 10 giây. Bước 2 API kéo trả `409` ERR-10-110; consumer ngoài mất quyền đọc nhóm. Bước 3 giao tiếp từ offset đã commit, đủ 6.000 sự kiện, không trùng ngoài lượt đang bay lúc dừng. EVT: `subscription.state-changed`.

**Thông báo hiển thị.** ERR-10-110 "Đăng ký nhận {mã} đang không hoạt động ({trạng thái}); chưa kéo được sự kiện."

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-073 · Tạm dừng INTERNAL, thiếu lý do, sai trạng thái, sai quyền <!--k:sub-pause-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-041 (Tạm dừng, tiếp tục subscription).

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-041 · API-10-050, 098 · ERR-10-006, 009, 052, 054.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-IE1; SUB-FLOW, SUB-PUSH.

**Các bước.**

1. `:pause` SUB-FLOW.
2. `:pause` SUB-PUSH không lý do; `:resume` khi đang `ACTIVE`.
3. IE1 `:pause` SUB-PUSH.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-052. Bước 2 `400` ERR-10-009; `409` ERR-10-006. Bước 3 403-PQ (IE không có `PERM-10-operate`).

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-052 "Thao tác không áp dụng cho đăng ký nhận nội bộ; điều khiển ở luồng PH-04."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-074 · Sửa tham số không cần duyệt và cần duyệt lại <!--k:sub-patch-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-046 (Sửa tham số subscription).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-046 · API-10-049 · ERR-10-012, 026, 030 · BR-10-025.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; SUB-PUSH `workerCount = 3`.

**Các bước.**

1. `PATCH` `workerCount = 6`, `timeoutMs = 5000`.
2. `PATCH` `endpointUrl = https://hooks.sim.test/moi` (đã xác minh).
3. `PATCH` `workerCount = 7`; `timeoutMs = 40000`; `endpointUrl = http://plain.sim.test`.

**Kết quả mong đợi.** Bước 1 `200`, áp dụng ≤ 60 giây, tái cân bằng hợp tác không mất bản tin. Bước 2 tạo yêu cầu `SUBSCRIPTION` với khác biệt; giao tiếp tục về URI cũ tới khi IA1 duyệt. Bước 3 `422` ERR-10-030, `422` ERR-10-012, `422` ERR-10-026.

**Thông báo hiển thị.** ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."; ERR-10-026 "Địa chỉ nhận không hợp lệ: chỉ nhận HTTPS, tên miền trong danh sách egress, không trỏ địa chỉ nội bộ."; ERR-10-030 "Số worker tối đa {n} (bằng số phân vùng của topic hoặc trần của tenant)."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-075 · Thu hồi subscription; DLQ còn xem được nhưng không phát lại <!--k:sub-revoke-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-047 (Thu hồi subscription).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-047 · API-10-099, 064 · ERR-10-006, 009, 044 · EVT-10-09 · BR-10-020.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-OR; subscription thử có 3 mục DLQ `NEW` và khóa ký `ACTIVE`; SB-THUE (ngoài tổ chức OR).

**Các bước.**

1. OR `:revoke` subscription của SB-THUE.
2. IE1 `:revoke` không lý do, rồi có lý do.
3. Đề nghị phát lại 3 mục DLQ của subscription đã thu hồi.

**Kết quả mong đợi.** Bước 1 403-TC. Bước 2 `400` ERR-10-009; rồi `200`, `REVOKED`, khóa ký xóa khỏi OpenBao, nhóm tiêu thụ còn tới hết `10.subscription.group-delete-delay-hours`. Bước 3 `409` ERR-10-006; mục DLQ vẫn xem và loại bỏ được.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-044 ST-07 "Đối tượng ngoài phạm vi tổ chức của bạn."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-076 · Thống kê giao nhận và lượt lỗi gần đây <!--k:sub-stats-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-056 (Thống kê giao nhận và lượt giao gần đây).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-10-056 · API-10-052, 053, 085 · UI-10-12 · ERR-10-049 · LGC-HUB-013.

**Tiền điều kiện, dữ liệu.** U-T68-VW; SUB-PUSH sau TC-10-068; SIM-WH trả thân lỗi có chuỗi `Bearer abc.def`.

**Các bước.**

1. `GET /subscriptions/ht-thue-dn-cap-phep/stats?from=…&to=…` 1 giờ.
2. `GET …/failures`.
3. `GET …/stats` khoảng 8 ngày ở độ phân giải phút.

**Kết quả mong đợi.** Bước 1 số thành công, lỗi tạm thời, thử lại, vào DLQ, p50, p95 theo phút khớp số sự kiện đã phát. Bước 2 mỗi dòng có `offset`, `eventId`, `httpStatus`, `errorCode`, `attempt`, `responseSnippet` ≤ 512 byte đã che (`Bearer ***`); không có thân sự kiện. Bước 3 `400` ERR-10-049.

**Thông báo hiển thị.** ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-17 · Giao nhận KÉO qua API: lease và cursor

**Mục tiêu.** Chứng minh API kéo an toàn khi bên nhận chết giữa chừng: một lease mỗi subscription, kéo lặp trả đúng lô cũ, cursor có HMAC không giả được, ack sai lease bị từ chối, nack đưa vào DLQ.

**Phủ.** FR-10-043, 049; UC-10-15; API-10-080…082; BR-10-009, 022; ERR-10-101, 102, 107, 109, 110, 121; ADR-071.

#### TC-10-077 · Kéo, xác nhận, kéo tiếp; chờ dài khi rỗng <!--k:pull-ok-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-043 (Giao nhận KÉO qua API).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-043 · API-10-080, 081 · UC-10-15 · LGC-HUB-013.

**Tiền điều kiện, dữ liệu.** C-BHXH có scope `topic:{TP-CP}:subscribe`; SUB-PULL; 250 sự kiện mới.

**Các bước.**

1. `GET /event/v1/subscriptions/ht-bhxh-dn-cap-phep/events?max=100&waitSeconds=0`.
2. `POST …/events:ack` với `cursor`.
3. Lặp tới hết; gọi `waitSeconds=10` khi rỗng, phát một sự kiện sau 3 giây.

**Kết quả mong đợi.** Bước 1 `200`, 100 sự kiện CloudEvents JSON, `cursor`, `leaseExpiresAt` sau 30 giây. Bước 2 `204`, offset nhóm `dh-sub-t68-ht-bhxh-dn-cap-phep` tiến đúng 100. Bước 3 đủ 250 sự kiện không trùng; lượt chờ dài trả sự kiện mới sau khoảng 3 giây; hết giờ không có sự kiện trả `204`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-078 · Kéo lặp khi chưa ack trả đúng lô cũ; lease hết hạn <!--k:pull-lease-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-043 (Giao nhận KÉO qua API).

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-043 · API-10-080, 081 · ERR-10-109 · BR-10-009.

**Tiền điều kiện, dữ liệu.** C-BHXH; SUB-PULL; ba bản sao cổng sự kiện.

**Các bước.**

1. Kéo lô A, không ack; kéo lại ngay qua bản sao cổng khác.
2. Chờ 31 giây; ack bằng cursor của lô A.
3. Kéo lại.

**Kết quả mong đợi.** Bước 1 trả lại đúng lô A (cùng `id`, cùng `cursor` vị trí). Bước 2 `409` ERR-10-109. Bước 3 lô mới bắt đầu từ cùng vị trí lô A (ít nhất một lần), `leaseId` khác.

**Thông báo hiển thị.** ERR-10-109 "Con trỏ xác nhận đã hết hiệu lực hoặc không khớp lượt kéo hiện tại. Kéo lại rồi xác nhận."

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-079 · Cursor giả, cursor của subscription khác, client không phải bên nhận <!--k:pull-cursor-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-043 (Giao nhận KÉO qua API).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, ZAP.

**Truy vết.** FR-10-043, 064 · API-10-080, 081 · ERR-10-101, 102, 103, 109.

**Tiền điều kiện, dữ liệu.** C-BHXH, C-THUE; cursor hợp lệ của SUB-PULL; subscription kéo thử thứ hai của `HT-BHXH`.

**Các bước.**

1. Sửa phần `offsets` của cursor (base64url) rồi ack.
2. Dùng cursor SUB-PULL để ack subscription thứ hai.
3. C-THUE kéo SUB-PULL; token hết hạn kéo SUB-PULL.
4. C-BHXH kéo `ht-bhxh-dn-cap-phep` ở đường T01 (subscription trùng mã ở T01).

**Kết quả mong đợi.** Bước 1, 2 `409` ERR-10-109 (HMAC sai), offset không đổi. Bước 3 403-PQ (ERR-10-102); `401` ERR-10-101. Bước 4 404-ẩn, không lộ sự kiện T01.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."; ERR-10-101 "Token truy cập không hợp lệ hoặc đã hết hạn. Lấy token mới rồi gửi lại."; ERR-10-102 "Token chưa có quyền {publish hoặc subscribe} trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động."; ERR-10-103 "Topic {tên} không tồn tại, không nhận sự kiện ở trạng thái hiện tại hoặc thuộc tenant khác."; ERR-10-109 "Con trỏ xác nhận đã hết hiệu lực hoặc không khớp lượt kéo hiện tại. Kéo lại rồi xác nhận."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-080 · Nack đưa sự kiện vào DLQ, phần còn lại được xác nhận <!--k:pull-nack-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-043 (Giao nhận KÉO qua API).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-043, 049 · API-10-082 · ERR-10-113 · EVT-10-11.

**Tiền điều kiện, dữ liệu.** C-BHXH; lô 100 sự kiện chưa ack.

**Các bước.**

1. `POST …/events:nack` với `cursor`, `eventIds` gồm 2 sự kiện, `reason`.

**Kết quả mong đợi.** `204`; 2 mục DLQ `NEW` với `origin = PULL_NACK`, `errorCode = ERR-10-113`; offset tiến 100; lượt kéo sau không trả lại 2 sự kiện đó. EVT: `delivery.dead-lettered`.

**Thông báo hiển thị.** ERR-10-113 nhãn "Đầu nhận từ chối".

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-081 · Hạn mức kéo và Valkey ngừng <!--k:pull-quota-valkey-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-043 (Giao nhận KÉO qua API).

**Loại.** Âm, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** API, Chaos.

**Truy vết.** FR-10-043 · API-10-080 · ERR-10-107, 121.

**Tiền điều kiện, dữ liệu.** C-BHXH với hạn mức 60 lượt/phút ở SIT.

**Các bước.**

1. Kéo 80 lượt/phút.
2. Dừng Valkey; kéo; phát qua API phát.

**Kết quả mong đợi.** Bước 1 lượt vượt `429` ERR-10-107 có `Retry-After`. Bước 2 kéo trả `503` ERR-10-121 `Retry-After: 5`; API phát vẫn `202` (chống trùng bị bỏ qua).

**Thông báo hiển thị.** ERR-10-107 "Vượt hạn mức phát hoặc kéo. Thử lại sau {Retry-After} giây."; ERR-10-121 "Dịch vụ phụ trợ của cổng sự kiện ({tên}) tạm thời không khả dụng. Thử lại sau {Retry-After} giây."

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

### TS-10-18 · Giao nhận KÉO qua Kafka ngoài: SASL OAUTHBEARER

**Mục tiêu.** Xác nhận HTTT đọc thẳng Kafka qua listener `external` chỉ khi tenant được bật, chỉ với nhóm tiêu thụ đúng tên được cấp, chỉ trên topic có subscription, và tự báo bản tin lỗi vào DLQ.

**Phủ.** FR-10-044, 037, 063; UC-10-15; API-10-083; BR-10-035; ERR-10-028, 120; LGC-TOOL-010.

#### TC-10-082 · Consumer ngoài đọc bằng token Keycloak và nhóm được cấp <!--k:kafka-consume-ok-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-044 (Giao nhận KÉO qua Kafka listener ngoài).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** FR-10-044, 037 · BR-10-035 · LGC-TOOL-010.

**Tiền điều kiện, dữ liệu.** SUB-KAFKA `ACTIVE`; client C-KBNN; consumer Java `sasl.mechanism=OAUTHBEARER`, serde Apicurio đọc lược đồ qua API-10-084.

**Các bước.**

1. Kết nối cổng 9093, `group.id = dh-ext-t68-ht-kho-bac-dn-cap-phep`; đọc 500 sự kiện; tự commit.
2. Đọc `GET /subscriptions/ht-kho-bac-dn-cap-phep/lag`.

**Kết quả mong đợi.** Đọc được, giải tuần tự được; lag về 0 sau commit; principal là `User:{clientId}` theo `azp`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-083 · Nhóm khác tên, topic không subscription, tenant chưa bật, token giả <!--k:kafka-consume-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-044 (Giao nhận KÉO qua Kafka listener ngoài).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** FR-10-044, 064 · ERR-10-028, 120 · BR-10-035.

**Tiền điều kiện, dữ liệu.** C-KBNN; C-KBNN-T01 ở T01 (Kafka ngoài tắt).

**Các bước.**

1. C-KBNN dùng `group.id = nhom-tu-dat`.
2. C-KBNN đọc TP-GT; đọc `t01.dkkd.doanh-nghiep.da-cap-phep.v1`.
3. C-KBNN-T01 kết nối listener `external`.
4. Dùng token ký bằng khóa tự sinh.

**Kết quả mong đợi.** Bước 1 `GroupAuthorizationException`. Bước 2 `TopicAuthorizationException`; chỉ số ERR-10-120 theo principal. Bước 3 bị từ chối (không có `KafkaUser` ngoài cho T01; đề nghị subscription `PULL_KAFKA` ở T01 trả ERR-10-028). Bước 4 xác thực thất bại.

**Thông báo hiển thị.** ERR-10-028 "Tenant chưa bật Kafka ngoài. Đề nghị quản trị nền tảng bật trước khi dùng chế độ này."; ERR-10-120 nhãn "Kafka từ chối do ACL, hạn mức".

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-084 · Bên nhận Kafka ngoài báo bản tin lỗi vào DLQ <!--k:kafka-dead-letter-report-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-044 (Giao nhận KÉO qua Kafka listener ngoài).

**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-10-044, 049 · API-10-083 · ERR-10-106, 110.

**Tiền điều kiện, dữ liệu.** C-KBNN; SUB-KAFKA.

**Các bước.**

1. `POST /event/v1/subscriptions/ht-kho-bac-dn-cap-phep/dead-letters` với phân vùng, offset, mã lỗi của 2 bản tin.
2. Gửi báo cáo 2 MiB; gửi khi SUB-KAFKA `PAUSED`.

**Kết quả mong đợi.** Bước 1 `202`, 2 mục DLQ `origin = EXTERNAL_REPORT`. Bước 2 `413` ERR-10-106; `409` ERR-10-110.

**Thông báo hiển thị.** ERR-10-106 "Sự kiện hoặc lô vượt kích thước cho phép ({giới hạn})."; ERR-10-110 "Đăng ký nhận {mã} đang không hoạt động ({trạng thái}); chưa kéo được sự kiện."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-19 · Giao nhận nội bộ và hợp đồng PH-04

**Mục tiêu.** Xác nhận hợp đồng với PH-04: luồng chỉ gửi, nhận trên topic đã đăng ký và có quyền (BR-04-009), nhóm tiêu thụ `dh-flow-{tenant}-{flow}`, kiểm tra quyền trả `ALLOWED`, `PENDING`, `DENIED` có lý do, phụ thuộc cho API-04-016.

**Phủ.** FR-10-045, 069; UC-10-25; API-10-008, 071, 072, 109; BR-10-018, 022; BR-04-009; FR-04-062; API-04-016.

#### TC-10-085 · Kiểm tra quyền phát, nhận của luồng: ALLOWED, PENDING, DENIED <!--k:ph04-check-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-069 (Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, CT.

**Truy vết.** FR-10-069 · API-10-071 · UC-10-25 · BR-04-009.

**Tiền điều kiện, dữ liệu.** S-PH04; PB-FLOW có publication `ACTIVE` trên TP-CP; luồng `dkkd-tong-hop` có đề nghị subscription TP-GT đang chờ; TP-TD `DEPRECATED`.

**Các bước.**

1. `POST /permissions:check` với bốn bộ: (`dkkd-tong-hop`, TP-CP, `PUBLISH`), (`dkkd-tong-hop`, TP-GT, `SUBSCRIBE`), (`dkkd-tong-hop`, TP-RDM, `SUBSCRIBE`), (`dkkd-tong-hop`, `t68.khong.co.gi.v1`, `PUBLISH`).
2. Thêm bộ (`dkkd-tong-hop`, TP-TD, `SUBSCRIBE`) khi luồng chưa có subscription trên TP-TD.
3. U-T68-IE1 gọi `POST /permissions:check`.

**Kết quả mong đợi.** Bước 1 `200`: `ALLOWED`; `PENDING`; `DENIED` `NO_GRANT`; `DENIED` `TOPIC_NOT_FOUND`. Bước 2 `DENIED` `TOPIC_NOT_ACTIVE`. Bước 3 403-PQ (chỉ scope `event:permission-check`). Không ghi kiểm toán.

**Thông báo hiển thị.** ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-086 · ensure-party, tra cứu topic dùng được và phụ thuộc của luồng <!--k:ph04-ensure-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-069 (Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-069, 027 · API-10-072, 008, 109 · ERR-10-022, 025 · API-04-016.

**Tiền điều kiện, dữ liệu.** S-PH04; luồng mới `tc-luong-moi` ở SIM-PH04; luồng `luong-cu` `RETIRED`.

**Các bước.**

1. `POST /flows/tc-luong-moi:ensure-party` với topic đầu ra TP-CP, topic đầu vào TP-GT; gọi lại lần hai cùng thân.
2. `GET /topics?usableBy=flow:tc-luong-moi&action=SUBSCRIBE`.
3. `GET /flows/tc-luong-moi/dependencies`.
4. `ensure-party` cho `luong-cu`; cho topic `RETIRED`.

**Kết quả mong đợi.** Bước 1 tạo bên phát, bên nhận `FLOW` và đề nghị publication, subscription `PENDING_APPROVAL`; lần hai không tạo trùng. Bước 2 danh sách kèm lược đồ hiện hành cho DataMapper. Bước 3 trả publication, subscription của luồng. Bước 4 `422` ERR-10-022; `422` ERR-10-025. KT: có cho `ensure-party`.

**Thông báo hiển thị.** ERR-10-022 "Luồng {mã} không tồn tại hoặc đã ngừng ở PH-04."; ERR-10-025 "Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới (topic cần Đang hoạt động, bên tham gia cần Đang hoạt động)."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-087 · Luồng tiêu thụ nội bộ đúng nhóm, lag được tính, không cấp scope OAuth <!--k:internal-consume-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-045 (Giao nhận nội bộ cho luồng và DU).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** RT, KT.

**Truy vết.** FR-10-045 · BR-10-018, 022 · FR-04-062.

**Tiền điều kiện, dữ liệu.** SUB-FLOW `ACTIVE`; Kamelet `dh-kafka-source` của luồng `dkkd-dong-bo-thue` trên `dh-runtime-t68`.

**Các bước.**

1. Phát 100 sự kiện lên TP-CP; luồng tiêu thụ.
2. Luồng dùng `group.id = dh-flow-t68-luong-khac`; principal nội bộ T68 đọc topic `t01.*`.
3. Kiểm tra client OAuth của bên `FLOW`.

**Kết quả mong đợi.** Bước 1 nhóm `dh-flow-t68-dkkd-dong-bo-thue` commit 100; lag ở UI-10-17 về 0. Bước 2 nhóm khác tên đọc được trong tiền tố tenant nhưng PH-10 không ghi nhận subscription nên VR-10 cảnh báo; đọc `t01.*` bị ACL từ chối. Bước 3 không có scope `topic:*` nào được cấp (BR-10-018).

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-088 · PH-10 ngừng khi PH-04 kiểm tra quyền <!--k:ph04-dep-down-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-069 (Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế).

**Loại.** Âm, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Chaos, API.

**Truy vết.** FR-10-069 · API-10-071 · ERR-10-029.

**Tiền điều kiện, dữ liệu.** S-PH04; `pg-core` của `ph10_event` dừng.

**Các bước.**

1. `POST /permissions:check`.

**Kết quả mong đợi.** `503` ERR-10-029 có `Retry-After`; PH-04 chặn gửi duyệt luồng theo D02-03-PH04 §10; luồng đang chạy không bị ảnh hưởng.

**Thông báo hiển thị.** ERR-10-029 "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

### TS-10-20 · DLQ tầng sự kiện: tra cứu, loại bỏ, phát lại mục DLQ

**Mục tiêu.** Xác nhận DLQ theo topic giữ mọi sự kiện không giao được tới khi xử lý, nội dung nhạy cảm mã hóa và chỉ xem được có lý do, loại bỏ và phát lại mục DLQ có kiểm soát, API cho PH-18.

**Phủ.** FR-10-050, 053; UC-10-18; API-10-060…062, 103, 064, 087…089; UI-10-15; BR-10-024, 028; ERR-10-036; EVT-10-12.

#### TC-10-089 · Tra cứu mục DLQ và xem nội dung có lý do <!--k:dlq-browse-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-050 (Tra cứu, xem và loại bỏ mục DLQ).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-050 · API-10-060, 061, 103 · UI-10-15 · ERR-10-009, 054 · UC-10-18.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-VW; DLQ-30; 2 mục DLQ của SUB-KS (`SENSITIVE`); S-PH18.

**Các bước.**

1. Mở UI-10-15 của TP-CP, lọc `errorCode = ERR-10-112`, `status = NEW`.
2. VW `GET /dlq-entries/{id}/payload`.
3. TO xem nội dung một mục SUB-KS không lý do, rồi có lý do.
4. S-PH18 `GET /dlq-entries?status=NEW`.

**Kết quả mong đợi.** Bước 1 20 mục, đủ `sourcePartition`, `sourceOffset`, `eventId`, `attempts`. Bước 2 403-PQ. Bước 3 `400` ERR-10-009; rồi `200`, nội dung giải mã qua OpenBao transit, đã che theo chính sách khi có; KT: có (xem dữ liệu Nhạy cảm). Bước 4 `200` chỉ siêu dữ liệu, không có nội dung.

**Thông báo hiển thị.** ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-090 · Loại bỏ mục DLQ; mục đã xử lý; quá giới hạn <!--k:dlq-discard-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-050 (Tra cứu, xem và loại bỏ mục DLQ).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, DB.

**Truy vết.** FR-10-050 · API-10-062 · ERR-10-009, 036 · BR-10-024.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-SO; DLQ-30.

**Các bước.**

1. TO `POST /dlq-entries:discard` với 10 mục ERR-10-113 và lý do.
2. Loại bỏ lại một trong 10 mục.
3. Gửi 1.001 mã mục; SO loại bỏ một mục.
4. Đặt đồng hồ +31 ngày; chạy bộ dọn đêm.

**Kết quả mong đợi.** Bước 1 `200`, 10 mục `DISCARDED`. Bước 2 `409` ERR-10-036. Bước 3 `400` ERR-10-003 (MVP tối đa 1.000 mục, loại bỏ theo bộ lọc thuộc Đợt sau theo FRS 0.3); SO 403-PQ. Bước 4 10 mục sang `PURGED`, `dlq_payload` bị xóa, siêu dữ liệu còn; 20 mục `NEW` giữ nguyên nội dung.

**Thông báo hiển thị.** ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-036 "Mục DLQ đã được xử lý bởi {người} lúc {giờ}."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-091 · Phát lại mục DLQ có duyệt từ nội dung đã lưu <!--k:dlq-replay-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-053 (Phát lại mục DLQ).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-053, 052 · API-10-064, 059, 087, 088, 089 · EVT-10-12 · BR-10-028 · UC-10-18.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-IA1; 20 mục `NEW` ERR-10-112; SIM-WH đã sửa về `200`; topic gốc đã hết lưu giữ cho 5 mục.

**Các bước.**

1. TO đề nghị `replayMode = DLQ_ENTRIES` với 20 mục, lý do, `acknowledgeDuplicates = true`.
2. IA1 duyệt.

**Kết quả mong đợi.** Bước 1 `201`, `PENDING_APPROVAL`. Bước 2 mục sang `REPLAY_PENDING` rồi `REPLAYED`; cả 5 mục hết lưu giữ vẫn giao được (từ `dlq_payload`); SIM-WH nhận `X-Datahub-Replay`, cùng `Webhook-Id` lần đầu. Lượt `COMPLETED`, `deliveredRecords = 20`. EVT: `replay.completed`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-092 · Tự duyệt phát lại DLQ dưới ngưỡng; giao lại vẫn lỗi <!--k:dlq-replay-auto-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-053 (Phát lại mục DLQ).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, RT.

**Truy vết.** FR-10-053 · API-10-064 · BR-10-028.

**Tiền điều kiện, dữ liệu.** T95 (`10.replay.dlq-auto-approve-max = 10`); 15 mục `NEW`; SIM-WH vẫn `500`.

**Các bước.**

1. Đề nghị phát lại 8 mục; đề nghị phát lại 15 mục.

**Kết quả mong đợi.** 8 mục được tự duyệt (yêu cầu `APPROVED`, `autoApproved = true`, `decidedBy = system:auto`); giao lại lỗi nên mục về `NEW`, `attempts` tăng. 15 mục cần người duyệt. Ở T68 (ngưỡng 0) mọi đề nghị đều cần duyệt.

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-21 · Phát lại theo khoảng có duyệt bốn mắt

**Mục tiêu.** Chứng minh phát lại theo khoảng offset, thời gian và đặt lại offset luôn có lý do, người duyệt khác người đề nghị, ước lượng trước, giới hạn tốc độ, hủy được, và không chạy song song hai lượt cho một subscription.

**Phủ.** FR-10-051, 052; UC-10-19; API-10-063…065, 104, 087, 088, 059, 101; UI-10-16, 13; BR-10-010, 028; ERR-10-032…035; EVT-10-12; NFR-10-012.

#### TC-10-093 · Phát lại theo khoảng thời gian không đổi vị trí subscription <!--k:replay-range-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-051 (Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, RT, E2E.

**Truy vết.** FR-10-051, 052 · API-10-064, 059, 104 · UI-10-16 · EVT-10-12 · UC-10-19.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-IA1; SUB-PUSH đã giao 20.000 sự kiện trong 2 ngày.

**Các bước.**

1. Ở UI-10-16 chọn SUB-PUSH, `REDELIVER_RANGE`, `rangeType = TIME`, khoảng 1 giờ, `ratePerSecond = 500`, lý do, đánh dấu xác nhận nhận trùng.
2. IA1 duyệt; theo dõi tiến độ.

**Kết quả mong đợi.** Bước 1 `201` có `estimatedRecords` và thời gian chạy ước lượng. Bước 2 `APPROVED`, `RUNNING`, `COMPLETED`; tốc độ thực ≤ 500/giây; nhóm `dh-sub-t68-ht-thue-dn-cap-phep` không đổi offset; SIM-WH nhận lượt có `X-Datahub-Replay`. EVT: `replay.completed`. KT: có (phạm vi, ước lượng, người duyệt).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-094 · Người đề nghị tự duyệt, TA tự duyệt, thiếu xác nhận <!--k:replay-4eyes-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-051 (Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-051 · API-10-064, 059 · ERR-10-008, 009 · BR-10-010, 028.

**Tiền điều kiện, dữ liệu.** U-T68-TA (có `operate` và `approve`); U-T68-TO; U-T68-SO.

**Các bước.**

1. TA đề nghị rồi tự duyệt.
2. TO đề nghị không có `reason`; `acknowledgeDuplicates = false`.
3. SO đề nghị phát lại.

**Kết quả mong đợi.** Bước 1 duyệt `403` ERR-10-008. Bước 2 `400` ERR-10-009. Bước 3 403-PQ (SO không phát lại). Không có lượt nào chạy.

**Thông báo hiển thị.** ERR-10-008 "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-095 · Khoảng ngoài lưu giữ, vượt trần, trùng lượt, đặt lại offset khi chưa tạm dừng <!--k:replay-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-051 (Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian).

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-051 · API-10-064 · ERR-10-032, 033, 034, 035.

**Tiền điều kiện, dữ liệu.** U-T68-TO; SUB-PUSH `ACTIVE` có một lượt `APPROVED` chờ chạy; `10.replay.max-records = 1000000`.

**Các bước.**

1. `rangeType = TIME` từ 10 ngày trước.
2. `rangeType = OFFSET` khoảng 1.500.000 bản tin.
3. Lượt thứ hai cho SUB-PUSH.
4. `RESET_OFFSET` khi SUB-PUSH `ACTIVE`.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-033 có `availableRange[]`. Bước 2 `422` ERR-10-034. Bước 3 `409` ERR-10-035. Bước 4 `409` ERR-10-032.

**Thông báo hiển thị.** ERR-10-032 "Cần tạm dừng đăng ký nhận trước khi đặt lại vị trí đọc."; ERR-10-033 "Khoảng phát lại ngoài dữ liệu còn giữ. Khoảng còn dữ liệu: {từ} đến {đến}."; ERR-10-034 "Khoảng phát lại có khoảng {n} bản tin, vượt trần {trần}. Thu hẹp khoảng."; ERR-10-035 "Đang có lượt phát lại {mã} cho đăng ký nhận này."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-096 · Đặt lại offset có duyệt, lưu vị trí trước <!--k:replay-reset-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-051 (Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-051, 052, 040 · API-10-050, 064, 059, 098.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-IA1; SUB-PULL.

**Các bước.**

1. TO tạm dừng SUB-PULL; đề nghị `RESET_OFFSET` về `fromTime` hôm qua, `acknowledgeDuplicates = true`.
2. IA1 duyệt; TO tiếp tục; HTTT kéo.

**Kết quả mong đợi.** Lượt `COMPLETED` do control plane chạy; `previousOffsets` ghi vị trí cũ theo phân vùng; offset nhóm khớp `offsetsForTimes`; lượt kéo đầu trả sự kiện từ hôm qua.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-097 · Hủy lượt đang chạy; lượt duyệt quá 24 giờ hết hạn <!--k:replay-cancel-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-052 (Thực thi, theo dõi và hủy lượt phát lại).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, RT.

**Truy vết.** FR-10-052 · API-10-065, 087 · ERR-10-006, 009 · EVT-10-12.

**Tiền điều kiện, dữ liệu.** U-T68-TO; lượt `RUNNING` 100.000 bản tin ở 100/giây; lượt `APPROVED` khác chưa chạy.

**Các bước.**

1. `:cancel` có lý do khi đã giao khoảng 3.000.
2. `:cancel` lượt `COMPLETED`.
3. Đặt đồng hồ +25 giờ cho lượt `APPROVED`.

**Kết quả mong đợi.** Bước 1 dừng sau bản tin đang giao, `CANCELLED`, `deliveredRecords` khớp số SIM-WH nhận. Bước 2 `409` ERR-10-006. Bước 3 lượt tự chuyển `CANCELLED`. EVT: `replay.completed` với trạng thái cuối.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-22 · Độ trễ tiêu thụ và cảnh báo

**Mục tiêu.** Xác nhận phủ consumer lag cho mọi nhóm tiêu thụ của tenant (đẩy, kéo, Kafka ngoài, luồng), cảnh báo đúng mức gồm cả nguy cơ hết lưu giữ và nhóm ngừng tiến, xác nhận cảnh báo và xuất chỉ số sang PH-13.

**Phủ.** FR-10-054, 055, 059; UC-10-20; API-10-055, 056; UI-10-17, 12; EVT-10-10; NFR-10-010; LGC-HUB-007.

#### TC-10-098 · Thu lag theo phân vùng cho mọi chế độ <!--k:lag-collect-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-054 (Thu thập consumer lag).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-10-054 · API-10-055 · UI-10-17 · ERR-10-001, 049 · LGC-HUB-007.

**Tiền điều kiện, dữ liệu.** SUB-PUSH, SUB-PULL, SUB-KAFKA, SUB-FLOW; dừng HTTT BHXH kéo; phát 600 sự kiện.

**Các bước.**

1. Chờ hai chu kỳ 30 giây; `GET /subscriptions/ht-bhxh-dn-cap-phep/lag`.
2. S-PH13 gọi cùng API; mở UI-10-17.
3. `GET /subscriptions/khong-co/lag`; `GET …/lag?from=…&to=…` khoảng 100 ngày.

**Kết quả mong đợi.** `lagRecords` theo phân vùng tổng bằng 600; `lagSeconds` bằng tuổi bản tin đầu chưa commit; phân vùng không lag có `lagSeconds = 0`. SUB-KAFKA và SUB-FLOW có mẫu lag. S-PH13 `200`. Bảng `lag_sample` có mẫu mỗi 30 giây. Bước 3 404-ẩn; `400` ERR-10-049 (mẫu gộp chỉ giữ 90 ngày).

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-099 · Cảnh báo WARNING, CRITICAL, STALLED và về OK <!--k:lag-alert-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-055 (Cảnh báo lag và nhóm tiêu thụ ngừng tiến).

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** IT, RT.

**Truy vết.** FR-10-055 · EVT-10-10 · NFR-10-010 · UC-10-20.

**Tiền điều kiện, dữ liệu.** SUB-PULL `lagWarnSeconds = 60`, `lagCriticalSeconds = 300`; topic thử lưu giữ 25 giờ.

**Các bước.**

1. Ngừng kéo 70 giây (một chu kỳ vượt), rồi 2 chu kỳ.
2. Ngừng tới 310 giây.
3. Kéo lại hết.
4. Ở topic thử, để bản tin đầu chưa commit sắp quá 1 giờ tuổi trong lưu giữ 25 giờ.
5. Cho bộ giao nhận một subscription `ACTIVE` treo không commit 6 phút khi có lag.

**Kết quả mong đợi.** Bước 1 một chu kỳ chưa đổi; hai chu kỳ `WARNING` trong ≤ 2 phút. Bước 2 `CRITICAL`. Bước 3 `OK`. Bước 4 `CRITICAL` do thời gian còn lại dưới 24 giờ. Bước 5 `STALLED`. Mỗi lần đổi mức một EVT `subscription.lag-alerted` (cả khi về `OK`), TO và đầu mối HTTT nhận thông báo.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-100 · Xác nhận cảnh báo lag <!--k:lag-ack-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-055 (Cảnh báo lag và nhóm tiêu thụ ngừng tiến).

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-10-055 · API-10-056 · UI-10-17 · ERR-10-006, 054.

**Tiền điều kiện, dữ liệu.** U-T68-TO, U-T68-VW; SUB-PULL `CRITICAL`.

**Các bước.**

1. TO xác nhận với ghi chú "Đã liên hệ BHXH".
2. VW xác nhận; TO xác nhận subscription `OK`.

**Kết quả mong đợi.** Bước 1 `200`, `alertAcknowledgedBy`, `alertAckNote`; thông báo lặp dừng tới khi đổi mức. Bước 2 403-PQ; `409` ERR-10-006.

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-101 · Chỉ số xuất sang PH-13 có nhãn tenant, không có dữ liệu nghiệp vụ <!--k:metrics-export-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-059 (Xuất số liệu sang PH-13).

**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-10-059 · NFR-10-017.

**Tiền điều kiện, dữ liệu.** Mimir của PH-13 ở SIT; tải nền ở T68, T01.

**Các bước.**

1. Truy vấn `dh_event_consumer_lag_seconds`, `dh_event_published_total`, `dh_event_delivery_total`, `dh_event_dlq_entries`, `dh_event_quota_usage_ratio`.
2. Liệt kê mọi nhãn của chuỗi `dh_event_*`.

**Kết quả mong đợi.** Mọi chuỗi có nhãn `tenant`; không có nhãn `ce_subject`, khóa nghiệp vụ hay mã doanh nghiệp; số `published_total` của T68 khớp số `202` của API phát.

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-23 · Dashboard và sơ đồ kết nối

**Mục tiêu.** Xác nhận bốn thẻ đếm dashboard và sơ đồ "Integration Project Connections" của Hub cũ được giữ, sơ đồ lọc theo dự án, có phủ lag, lưu lượng, DLQ; biểu đồ CPU, bộ nhớ chỉ còn liên kết sang PH-13.

**Phủ.** FR-10-057, 058; UC-10-21; API-10-066, 007; UI-10-01, 14, 03; ERR-10-049; NFR-10-015; LGC-HUB-001…007.

#### TC-10-102 · Bốn thẻ đếm và khối lag, DLQ trên dashboard <!--k:dashboard-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-057 (Dashboard sự kiện).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-057 · API-10-066 · UI-10-01 · ERR-10-001, 049 · UC-10-21 · LGC-HUB-001, 002, 003, 004, 005, 006.

**Tiền điều kiện, dữ liệu.** U-T68-VW; dữ liệu mục 2.3.

**Các bước.**

1. `GET /dashboard`; `GET /dashboard?projectCode=dang-ky-kinh-doanh`.
2. Mở UI-10-01, bấm thẻ "Bên phát"; bấm liên kết "Tài nguyên cụm Kafka (PH-13)".
3. Dừng PH-13.
4. `GET /dashboard?projectCode=khong-co`; `GET /dashboard?projectCode=dang-ky-kinh-doanh` bằng U-T01-IE.

**Kết quả mong đợi.** Bước 1 số publisher, subscriber, project, topic khớp đếm trực tiếp ở CSDL, có phân rã theo trạng thái; khối lag theo `alertState`, DLQ `NEW`. Bước 2 mở UI-10-09 đã lọc; liên kết mở bảng chỉ số cụm của PH-13. Bước 3 khối lưu lượng ẩn kèm thông báo, các khối khác vẫn hiện. Bước 4 404-ẩn cả hai (không lộ dự án T68).

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-103 · Sơ đồ kết nối lọc theo dự án và phủ trạng thái <!--k:graph-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-058 (Sơ đồ kết nối tương tác).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-058 · API-10-007 · UI-10-14, 03 · UC-10-21 · LGC-HUB-007.

**Tiền điều kiện, dữ liệu.** U-T68-VW; P-DKKD.

**Các bước.**

1. `GET /graph?projectCode=dang-ky-kinh-doanh&overlay=LAG`.
2. Mở UI-10-14 `?du-an=dang-ky-kinh-doanh`, đổi `overlay` sang `DLQ`, `TRAFFIC`; bấm một cạnh.
3. `GET /graph?systemCode=HT-DKKD`.

**Kết quả mong đợi.** Bước 1 `nodes[]` ba lớp (bên phát, topic, bên nhận), `edges[]` có `deliveryMode`, `lagSeconds`; `HT-DKKD` vừa phát vừa nhận hiện một nút có liên kết đánh dấu. Bước 2 cạnh SUB-PUSH có huy hiệu số mục DLQ `NEW`; bấm cạnh mở UI-10-12; không có thao tác sửa nào trên sơ đồ (PTN-07 chỉ xem). Bước 3 chỉ lân cận một bước quanh `HT-DKKD`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-104 · Sơ đồ quá số nút, tham số sai, không lộ tenant khác <!--k:graph-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-058 (Sơ đồ kết nối tương tác).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-058, 064 · API-10-007 · ERR-10-049.

**Tiền điều kiện, dữ liệu.** T97 có 400 nút; U-T68-VW; T01 có bên nhận nhận từ topic trùng tên.

**Các bước.**

1. Ở T97 `GET /graph` không lọc.
2. `overlay=CPU`.
3. U-T68-VW `GET /graph?systemCode=HT-THUE`.

**Kết quả mong đợi.** Bước 1, 2 `400` ERR-10-049, gợi ý lọc theo dự án. Bước 3 không có nút, cạnh nào của T01.

**Thông báo hiển thị.** ERR-10-049 "Điều kiện truy vấn không hợp lệ."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-24 · Danh mục, hạn mức và tham số

**Mục tiêu.** Xác nhận danh mục `type_of_comm`, `routing_mode` của Hub cũ giữ `legacyCode` để di trú, tenant bật tắt trong giới hạn, hạn mức tenant do PA đặt trần và TA phân bổ, tham số `10.*` trong miền.

**Phủ.** FR-10-060…063; UC-10-22; API-10-067…070, 105…108; UI-10-18; BR-10-029, 035; ERR-10-011, 012, 043; LGC-HUB-014.

#### TC-10-105 · Danh mục kiểu giao tiếp và chế độ định tuyến có mã hệ cũ <!--k:catalog-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-060 (Danh mục kiểu giao tiếp).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-060, 061 · API-10-067, 068, 105, 106 · UI-10-18 · ERR-10-043 · LGC-HUB-014.

**Tiền điều kiện, dữ liệu.** U-T68-TA; PB-DKKD-K dùng `KAFKA_NATIVE`.

**Các bước.**

1. `GET /comm-types`; `GET /routing-modes`.
2. TA tắt `PULSAR_BRIDGE` (không ai dùng); tắt `KAFKA_NATIVE`; tắt `KEY_HASH`.

**Kết quả mong đợi.** Bước 1 đủ 8 mã A.2.8 với chiều, `partyType`, `deliveryMode`, `legacyCode` (`REST`, `PULSAR_CLIENT`, `ROUTE`, `HTTP_PUSH`); ba chế độ với `legacyCode` `CustomPartition`, `RoundRobinPartition`, `SinglePartition`. Bước 2 tắt `PULSAR_BRIDGE` `200`, KT: có; `KAFKA_NATIVE`, `KEY_HASH` `422` ERR-10-043.

**Thông báo hiển thị.** ERR-10-043 "Không tắt được mục đang có {n} bên tham gia hoặc topic dùng."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-106 · Hạn mức: PA đặt trần, TA phân bổ, vượt trần <!--k:quota-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-062 (Hạn mức theo tenant và phân bổ cho bên tham gia).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-062 · API-10-069, 107 · ERR-10-011, 012 · BR-10-029, 036.

**Tiền điều kiện, dữ liệu.** U-PA, U-T68-TA; T68 trần sản xuất 10 MiB/s.

**Các bước.**

1. `GET /quota` ở T68.
2. TA đặt `produceBytesPerSecond = 20971520` (vượt trần).
3. TA phân bổ `quotaBytesPerSecond` cho PB-DKKD-K 2 MiB/s.
4. PA nâng trần lên 20 MiB/s.

**Kết quả mong đợi.** Bước 1 trả trần, mức dùng, phần dự trữ nội bộ 30 %. Bước 2 `422` ERR-10-012. Bước 3 `KafkaUser` của principal có `producerByteRate = 2097152` sau khi cụm áp dụng; tổng phân bổ không vượt trần. Bước 4 `200`, `ceilingSetBy` là PA. KT: có.

**Thông báo hiển thị.** ERR-10-011 "Vượt hạn mức của tenant: {tên hạn mức} đang dùng {đã dùng}/{trần}."; ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-107 · Tham số 10.* trong miền; tham số nền tảng chỉ PA <!--k:settings-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-063 (Tham số phân hệ theo tenant).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-063 · API-10-070, 108 · UI-10-18 · ERR-10-009, 012, 054 · BR-10-035.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-PA, U-T68-IE1.

**Các bước.**

1. TA đặt `10.lag.warn-seconds = 120` có lý do.
2. TA đặt `10.push.max-retries = 21`; không lý do.
3. TA đặt `10.external-kafka.enabled = false`; `10.graph.max-nodes = 500`.
4. IE1 sửa tham số.

**Kết quả mong đợi.** Bước 1 `200`, áp dụng ngay cho subscription dùng mặc định. Bước 2 `422` ERR-10-012; `400` ERR-10-009. Bước 3 403-PQ (tham số phạm vi N chỉ PA). Bước 4 403-PQ.

**Thông báo hiển thị.** ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."; ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-25 · Hợp đồng PH-05: topic CDC tự duyệt và thay đổi lược đồ

**Mục tiêu.** Xác nhận hợp đồng với PH-05: CDC đăng ký topic `{topicPrefix}.{schema}.{table}.v1` một topic mỗi bảng, lược đồ Avro ở Apicurio, tự duyệt và trả `202`; thông báo EVT-05-11 dẫn tới phiên bản lược đồ mới hoặc topic `.v{n+1}`; PH-10 ngừng thì PH-05 không khai báo CDC mới.

**Phủ.** FR-10-066, 068; UC-10-23; API-10-009, 023, 018; BR-10-002, 030, 031; EVT-05-11; ERR-05-029; FR-05-048, 051.

#### TC-10-108 · PH-05 đăng ký topic CDC, tự duyệt, trả 202 rồi ACTIVE <!--k:cdc-register-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, CT.

**Truy vết.** FR-10-066 · API-10-009 · EVT-10-01 · BR-10-031 · UC-10-23 · FR-05-048 · LGC-TOOL-010.

**Tiền điều kiện, dữ liệu.** S-PH05; bộ điều hợp `dkkd-cdc` mới thêm bảng `public.nganhnghe`; `onBehalfOf = an`.

**Các bước.**

1. `POST /topics` với `topicKind = CDC`, `topicName = t68.cdc.dkkd-cdc.public.nganhnghe.v1`, lược đồ Avro sinh từ bảng, `partitionKeyField` là khóa chính, `sourceRef`.
2. Gọi lại cùng thân.
3. Theo dõi tới `ACTIVE`.

**Kết quả mong đợi.** Bước 1 `202`, `Location`; dự án hệ thống `cdc-dkkd-cdc` có sẵn; yêu cầu `TOPIC_CREATE` `APPROVED`, `autoApproved = true`, `decidedBy = system:auto`, `requestedBy` là tài khoản dịch vụ; publication `ACTIVE` cho bên phát `INTERNAL_SERVICE` của `dh-cdc`. Bước 2 `200`, trạng thái hiện tại. Bước 3 `ACTIVE` ≤ 3 phút. EVT: `topic.activated`. KT: có (`onBehalfOf`, `sourceRef`).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-109 · CDC sai tên, sai tiền tố, cấu hình khác, người dùng sửa topic CDC, tự duyệt tắt <!--k:cdc-register-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-066 · API-10-009, 011 · ERR-10-002, 004, 005, 045 · BR-10-002, 030.

**Tiền điều kiện, dữ liệu.** S-PH05; U-T68-IE1; TP-CDC; T95 (tự duyệt tắt).

**Các bước.**

1. `topicName = t68.cdc.a.b.c.d.v1` (5 đoạn giữa).
2. `topicName = t01.cdc.dkkd-cdc.public.dangky.v1` bằng token T68.
3. Đăng ký lại TP-CDC với `partitions` khác.
4. IE1 `PATCH` cấu hình TP-CDC; IE1 sửa mô tả.
5. Ở T95 đăng ký topic CDC.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-004. Bước 2 `422` ERR-10-005. Bước 3 `409` ERR-10-002. Bước 4 cấu hình `422` ERR-10-045; mô tả `200`. Bước 5 `202` nhưng yêu cầu `PENDING`, chờ người duyệt.

**Thông báo hiển thị.** ERR-10-002 "Mã {mã} đã được dùng, kể cả cho đối tượng đã lưu trữ hoặc ngừng dùng. Chọn mã khác."; ERR-10-004 "Tên topic không đúng quy ước hoặc dùng miền dành riêng ({miền}). Miền này chỉ do hệ thống đăng ký."; ERR-10-005 "Tiền tố tenant của topic không khớp tenant đang làm việc."; ERR-10-045 "Topic CDC, hệ thống chỉ do dịch vụ chủ quản ({dịch vụ}) sửa."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-110 · Thay đổi lược đồ tương thích và phá vỡ theo EVT-05-11 <!--k:cdc-schema-change-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-068 (Xử lý thông báo thay đổi lược đồ CDC).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-10-068, 015 · API-10-023, 018 · EVT-05-11 · EVT-10-03, 05 · ERR-10-016.

**Tiền điều kiện, dữ liệu.** SIM-PH05; TP-CDC v1; F-AV-ADD, F-AV-BRK dạng Avro CDC.

**Các bước.**

1. SIM-PH05 phát EVT-05-11 `COMPATIBLE` rồi gửi phiên bản thêm cột có mặc định.
2. Gửi phiên bản đổi kiểu cột theo nhánh `COMPATIBLE`.
3. Phát EVT-05-11 `BREAKING` đã `ACCEPT`; gọi `:new-major-version`.
4. Phát lại EVT-05-11 ở bước 3 cùng `id`.

**Kết quả mong đợi.** Bước 1 phiên bản tự duyệt `ENABLED`, EVT: `schema.version-enabled`. Bước 2 `409` ERR-10-016. Bước 3 topic `.v2` tự duyệt, `.v1` `DEPRECATED` với `successorTopic`, EVT: `topic.deprecated`, đầu mối subscription nhận thông báo. Bước 4 inbox bỏ qua.

**Thông báo hiển thị.** ERR-10-016 "Lược đồ không tương thích theo mức {mức}."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-111 · PH-10 ngừng thì PH-05 không khai báo CDC mới, CDC đang chạy không ảnh hưởng <!--k:cdc-dep-down-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).

**Loại.** Âm, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-10-066 · ERR-10-029 · ERR-05-029 · NFR-10-013.

**Tiền điều kiện, dữ liệu.** S-PH05; `dh-integration` mô-đun `event` ngừng; CDC TP-CDC đang ghi.

**Các bước.**

1. PH-05 đăng ký topic CDC mới.
2. Đếm bản tin CDC trên TP-CDC trong 5 phút.

**Kết quả mong đợi.** Bước 1 PH-05 nhận ERR-10-029 và trả ERR-05-029 cho người dùng. Bước 2 CDC tiếp tục ghi (chỉ phụ thuộc Kafka, Apicurio).

**Thông báo hiển thị.** ERR-10-029 "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

### TS-10-26 · DU nội bộ đăng ký topic SYSTEM và topic nền tảng

**Mục tiêu.** Xác nhận DU nội bộ đăng ký topic sự kiện miền của mình (ví dụ `{tenant}.rdm.catalog.published.v1` cho PH-07, `{tenant}.integration.{đối tượng}.{động từ}.v1` cho PH-04) bằng scope máy, tự duyệt, và HTTT đăng ký nhận `*.rdm.*` như bình thường.

**Phủ.** FR-10-067; UC-10-24; API-10-009; BR-10-030, 031; LGC-BUS-039.

#### TC-10-112 · DU đăng ký topic SYSTEM khi khởi tạo tenant; HTTT đăng ký nhận <!--k:du-register-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-067 (Đăng ký topic cho DU nội bộ và topic nền tảng).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-067, 035 · API-10-009, 047 · UC-10-24 · BR-10-031 · LGC-BUS-039.

**Tiền điều kiện, dữ liệu.** S-DU-DATA; tenant T98 vừa khởi tạo; U-T68-IE1.

**Các bước.**

1. S-DU-DATA đăng ký `t98.rdm.catalog.published.v1` `SYSTEM`.
2. Ở T68, IE1 đề nghị subscription PUSH cho SB-THUE trên TP-RDM.

**Kết quả mong đợi.** Bước 1 `202`, tự duyệt, publication `INTERNAL_SERVICE` của `dh-data` tự duyệt theo `10.approval.auto-approve-internal`. Bước 2 đi quy trình bình thường, cần IA duyệt, khi `ACTIVE` HTTT có scope phù hợp theo chế độ.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-113 · Người dùng đăng ký miền dành riêng; DU đăng ký topic nền tảng hoặc tenant khác <!--k:du-register-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-067 (Đăng ký topic cho DU nội bộ và topic nền tảng).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-067 · API-10-009 · ERR-10-004, 005, 054 · BR-10-030.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; S-DU-DATA; U-PA.

**Các bước.**

1. IE1 tạo topic `BUSINESS` miền `rdm`.
2. S-DU-DATA đăng ký `platform.tenant.created.v1`.
3. S-DU-DATA với token T68 đăng ký `t01.rdm.catalog.published.v1`.
4. U-PA đăng ký `platform.tenant.created.v1`.

**Kết quả mong đợi.** Bước 1 `422` ERR-10-004. Bước 2 403-PQ (tiền tố `platform.` của topic cấp nền tảng chỉ PA và tài khoản dịch vụ nền tảng). Bước 3 `422` ERR-10-005. Bước 4 thành công, topic thuộc tenant `COMMON`, artifact `groupId = platform`.

**Thông báo hiển thị.** ERR-10-004 "Tên topic không đúng quy ước hoặc dùng miền dành riêng ({miền}). Miền này chỉ do hệ thống đăng ký."; ERR-10-005 "Tiền tố tenant của topic không khớp tenant đang làm việc."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-27 · Xuất và nhập khai báo

**Mục tiêu.** Xác nhận khai báo sự kiện xuất được ra `EventManifest` không có bí mật để rà soát và đưa sang môi trường khác; nhập (Đợt sau) có xem trước và không tạo đối tượng `ACTIVE` trực tiếp.

**Phủ.** FR-10-070, 071; UC-10-28; API-10-074, 075, 110, 111; UI-10-02, 19; BR-10-027, 032; ERR-10-040, 050.

#### TC-10-114 · Xuất khai báo dự án không chứa bí mật <!--k:export-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-070 (Xuất khai báo).

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-070 · API-10-074 · BR-10-027 · NFR-10-016 · UC-10-28.

**Tiền điều kiện, dữ liệu.** U-T68-VW; P-DKKD; khóa ký thử có mồi.

**Các bước.**

1. `POST /exports` với `projectCode = dang-ky-kinh-doanh`.

**Kết quả mong đợi.** `200` tệp YAML `kind: EventManifest`, `apiVersion: event.datahub.vn/v1` gồm dự án, 4 topic, lược đồ `ENABLED`, `DEPRECATED`, bên phát, bên nhận, publication, subscription; không có khóa ký, `clientId` nội bộ. Mồi sạch.

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-115 · Nhập khai báo có xem trước, viết lại tiền tố, không tạo ACTIVE <!--k:import-manifest-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-071 (Nhập khai báo có xem trước).

**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-10-071 · API-10-075, 110, 111 · UI-10-19 · ERR-10-040, 050 · BR-10-032.

**Tiền điều kiện, dữ liệu.** U-T90-IE ở T90; F-MAN; tệp hỏng; T90 không có `HT-THUE`.

**Các bước.**

1. Tải F-MAN với `rewriteTenantPrefix = true`; xem `GET /imports/{jobCode}`.
2. `:apply`.
3. Tải tệp sai `apiVersion`; tải lại F-MAN khi T90 không có `HT-THUE`.
4. Tạo tác vụ mới rồi hủy bằng `POST /imports/{jobCode}:cancel` (API-10-121 theo FRS 0.3).

**Kết quả mong đợi.** Bước 1 `202`, tác vụ `PREVIEW`, tên topic viết thành `t90.…`, mỗi dòng có `changeKind`. Bước 2 topic `DRAFT`, `PENDING_APPROVAL`; không đối tượng nào `ACTIVE`. Bước 3 `422` ERR-10-040; `422` ERR-10-050. Bước 4 tác vụ `CANCELLED`.

**Thông báo hiển thị.** ERR-10-040 "Tệp sai cấu trúc hoặc phiên bản định dạng."; ERR-10-050 "Đối tượng tham chiếu {mã} không có ở tenant đích."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

### TS-10-28 · Di trú từ Pulsar: kiểm kê và ánh xạ

**Mục tiêu.** Xác nhận đọc được kiểm kê Hub cũ (project, topic, publisher, subscriber, publication, subscription, `type_of_comm`, `routing_mode`) thành đề xuất ánh xạ sang khái niệm Datahub, không di trú thông tin xác thực cũ.

**Phủ.** FR-10-072; UC-10-26; API-10-075, 076, 110, 111, 112; UI-10-20; BR-10-032, 034; ERR-10-040, 041; LGC-HUB-008…014; ADR-073.

#### TC-10-116 · Nhập kiểm kê Hub cũ, đề xuất ánh xạ đủ loại <!--k:pulsar-inventory-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-072 (Nhập kiểm kê Pulsar và lập ánh xạ).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-072 · API-10-075, 076, 110 · UI-10-20 · UC-10-26 · LGC-HUB-008, 009, 010, 011, 012, 013, 014.

**Tiền điều kiện, dữ liệu.** U-T68-TA ở T96; F-PUL-INV.

**Các bước.**

1. Tải F-PUL-INV (`sourceKind = PULSAR_HUB`).
2. `GET /migrations/mappings`.

**Kết quả mong đợi.** 3 dự án, 8 topic (tên đề xuất `t96.{miền}.{thực-thể}.{sự-kiện}.v1` chữ thường), 5 bên phát, 7 bên nhận (2 có `partyType = FLOW`), 6 publication, 9 subscription; mỗi ánh xạ `PROPOSED` có `confidence`; `routing_mode` `CustomPartition` ánh xạ `KEY_HASH` kèm cờ "cần khai báo trường khóa"; subscription `Shared` 2 consumer thành `workerCount = 2`, `DEAD_LETTER`; `type_of_comm` ánh xạ theo `legacyCode`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-117.
:::

#### TC-10-117 · Không di trú mật khẩu cũ; sửa ánh xạ; tệp sai; đích không hợp lệ <!--k:pulsar-inventory-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-072 (Nhập kiểm kê Pulsar và lập ánh xạ).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-072 · API-10-075, 111, 112 · ERR-10-040, 041 · BR-10-032, 034.

**Tiền điều kiện, dữ liệu.** Tác vụ từ TC-10-116; F-PUL-BAD.

**Các bước.**

1. Xem ánh xạ subscription có mật khẩu Basic trong URI.
2. `PATCH /migrations/mappings/{id}` đặt `targetCode` là topic không theo quy ước; đặt `SKIPPED` cho một ánh xạ.
3. `:apply` tác vụ.
4. Tải F-PUL-BAD.

**Kết quả mong đợi.** Bước 1 URI đích đã bỏ thông tin xác thực, có vấn đề "cấp lại thông tin xác thực"; mật khẩu không có trong CSDL, log, báo cáo (mồi sạch). Bước 2 `422` ERR-10-041; `SKIPPED` `200`. Bước 3 đối tượng đích tạo ở `DRAFT`, `PENDING_APPROVAL`; không `ACTIVE`. Bước 4 `422` ERR-10-040.

**Thông báo hiển thị.** ERR-10-040 "Tệp sai cấu trúc hoặc phiên bản định dạng."; ERR-10-041 "Ánh xạ không hợp lệ: {lý do}."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-29 · Cầu nối Pulsar, đối chiếu, chuyển hẳn và quay lui

**Mục tiêu.** Chứng minh di trú song song theo ADR-073: cầu nối Pulsar sang Kafka có duyệt và hạn dùng, không ảnh hưởng subscriber cũ; cầu nối ngược cho bên nhận cũ; đối chiếu chênh lệch 0; chuyển hẳn có điều kiện và quay lui trong cửa sổ.

**Phủ.** FR-10-073…076; UC-10-27; API-10-077, 078, 113…118, 090; UI-10-20, 13; BR-10-033; ERR-10-041, 042, 118; EVT-10-15, 16; NFR-10-018; ADR-073.

#### TC-10-118 · Cầu nối Pulsar sang Kafka có duyệt, không ảnh hưởng subscriber cũ <!--k:bridge-p2k-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-073 (Cầu nối Pulsar sang Kafka tạm thời).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** RT, API.

**Truy vết.** FR-10-073 · API-10-113, 059, 077, 090 · EVT-10-16 · NFR-10-018 · UC-10-27.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-IA1 ở T96; ánh xạ topic `PLANNED`; topic Kafka đích `ACTIVE`; SIM-PULSAR có producer 200 bản tin/giây và subscriber cũ.

**Các bước.**

1. TA `POST /migrations/bridges` `PULSAR_TO_KAFKA`, `startFrom = LATEST`, `expiresAt` sau 90 ngày; IA1 duyệt.
2. Chạy 30 phút.

**Kết quả mong đợi.** Bước 1 bên phát `LEGACY_BRIDGE` và publication tự duyệt; cầu nối `RUNNING`, ánh xạ `BRIDGING`; EVT: `bridge.state-changed`. Bước 2 bản tin xuất hiện trên Kafka với `id` từ `messageId`, `source = /legacy-hub/{pulsarTopic}`; độ trễ p95 ≤ 60 giây; subscriber cũ vẫn nhận đủ (subscription `Failover` riêng `dh-bridge`).

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-119 · Cầu nối trùng, ngược chiều cùng cặp, quá hạn dùng, bản tin không chuyển được <!--k:bridge-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-073 (Cầu nối Pulsar sang Kafka tạm thời).

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-073, 074 · API-10-113, 115 · ERR-10-012, 042, 118 · BR-10-033.

**Tiền điều kiện, dữ liệu.** U-T68-TA ở T96; cầu nối `brg-t96-cp` `RUNNING`.

**Các bước.**

1. Tạo cầu nối thứ hai cho cùng topic; tạo cầu nối `KAFKA_TO_PULSAR` cùng cặp.
2. `expiresAt` sau 200 ngày.
3. SIM-PULSAR phát bản tin không chuyển được theo lược đồ đích.
4. Đặt đồng hồ quá `expiresAt`.

**Kết quả mong đợi.** Bước 1 `409` ERR-10-042 cả hai. Bước 2 `422` ERR-10-012. Bước 3 bản tin vào DLQ của cầu nối, `origin = BRIDGE`, `bridgeCode`, ERR-10-118; cầu nối vẫn chạy. Bước 4 cầu nối `EXPIRED`, EVT: `bridge.state-changed`.

**Thông báo hiển thị.** ERR-10-012 "Giá trị ngoài miền cho phép ({min} đến {max})."; ERR-10-042 "Đã có cầu nối cho topic này hoặc cầu nối ngược chiều đang chạy."; ERR-10-118 nhãn "Cầu nối không chuyển được.".

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-120 · Cầu nối ngược Kafka sang Pulsar cho bên nhận cũ <!--k:bridge-k2p-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-074 (Cầu nối ngược Kafka sang Pulsar cho bên nhận cũ chưa chuyển).

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** RT.

**Truy vết.** FR-10-074 · API-10-113 · EVT-10-16.

**Tiền điều kiện, dữ liệu.** Bên phát đã chuyển sang phát thẳng Datahub; cầu nối chiều cũ đã `STOPPED`; subscriber cũ còn trên Pulsar.

**Các bước.**

1. TA tạo cầu nối `KAFKA_TO_PULSAR`; IA1 duyệt; phát 100 sự kiện qua API.

**Kết quả mong đợi.** Subscriber cũ nhận 100 bản tin định dạng cũ (không phong bì CloudEvents); nhóm `dh-bridge-t96-{bridgeCode}`.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-121 · Đối chiếu, chuyển hẳn có điều kiện và quay lui trong cửa sổ <!--k:cutover-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-075 (Đối chiếu, chuyển hẳn và quay lui).

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, RT.

**Truy vết.** FR-10-075 · API-10-117, 078, 116, 059 · EVT-10-15 · ERR-10-006, 042 · UC-10-27.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-IA1 ở T96; ánh xạ `BRIDGING` 3 ngày (dưới `10.migration.min-parallel-days`), ánh xạ khác 15 ngày đủ điều kiện.

**Các bước.**

1. `GET /migrations/reconciliations`.
2. Đề nghị chuyển hẳn ánh xạ 3 ngày.
3. Đề nghị chuyển hẳn ánh xạ 15 ngày; IA1 duyệt.
4. Trong cửa sổ 30 ngày gọi `:rollback`.

**Kết quả mong đợi.** Bước 1 chênh lệch 0 sau khi trừ lag. Bước 2 `409` ERR-10-006 kèm điều kiện chưa đạt. Bước 3 ánh xạ `CUT_OVER`, cầu nối dừng; EVT: `migration.cut-over`. Bước 4 ánh xạ `ROLLED_BACK` rồi `BRIDGING` khi cầu nối chạy lại; EVT: `migration.cut-over` (quay lui).

**Thông báo hiển thị.** ERR-10-006 "Không thực hiện được khi {đối tượng} đang ở trạng thái {nhãn trạng thái}."; ERR-10-042 "Đã có cầu nối cho topic này hoặc cầu nối ngược chiều đang chạy."

**Hậu điều kiện.** Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
:::

#### TC-10-122 · Báo cáo tiến độ di trú <!--k:migration-progress-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-076 (Báo cáo tiến độ di trú).

**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-10-076 · API-10-118 · UI-10-20.

**Tiền điều kiện, dữ liệu.** U-T68-TA ở T96.

**Các bước.**

1. `GET /migrations/progress`; xuất Excel ở UI-10-20.

**Kết quả mong đợi.** Số ánh xạ theo trạng thái theo loại, HTTT còn dùng Pulsar, cầu nối đang chạy và lag, đối chiếu gần nhất; tệp Excel khớp.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Các kịch bản dưới đây chạy lại ở mỗi đợt phát hành; TS-10-30, 31, 32 là điều kiện bắt buộc đạt 100 %. Bộ rò rỉ TS-10-30 chạy mỗi đêm (NFR-10-017).

### TS-10-30 · Cô lập tenant: RLS, ACL Kafka theo tiền tố, Apicurio, OPA

**Mục tiêu.** Chứng minh không có đường đọc, ghi, phát, nhận chéo tenant ở API control plane, API data plane, CSDL, Kafka, Apicurio và dữ liệu OPA, dùng cặp T90, T91 và tenant đối chứng T01 có mã trùng.

**Phủ.** FR-10-064; BR-10-001, 002, 022; NFR-10-017; ERR-10-001, 005, 103, 120; D03-10 §4; SEC-82, SEC-87.

#### TC-10-123 · RLS của ph10_event chặn đọc, ghi chéo tenant <!--k:iso-rls-->

::: dac-ta
**Mục đích.** Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** FR-10-064 · NFR-10-017 · BR-10-001.

**Tiền điều kiện, dữ liệu.** CSDL rỗng đã áp `ph10_event.sql`; vai trò `dh_integration_app`, `dh_report_ro` (`NOBYPASSRLS`).

**Các bước.**

1. Chạy `psql -v ON_ERROR_STOP=1 -f 03-thiet-ke/csdl/ph10/test/ph10_isolation_test.sql`.
2. Với `app.tenant_id = 'T90'`, `SELECT` và `UPDATE` mọi bảng có `tenant_id` nhắm dòng của T91; `INSERT` dòng `tenant_id = 'T91'`.
3. Đặt `app.tenant_id` rỗng, rồi `'COMMON'`, rồi `'PLATFORM'`.

**Kết quả mong đợi.** Mọi khối kiểm in PASS. Bước 2 đọc 0 dòng, cập nhật 0 dòng, chèn bị chặn bởi `WITH CHECK`. Bước 3 không đọc được dòng tenant nào; `COMMON` chỉ ghi được khi `PLATFORM` (bảng chế độ S); 28 bảng đều `FORCE ROW LEVEL SECURITY`.

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-124 · API control plane không lộ đối tượng tenant khác <!--k:iso-api-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-064, 002, 006, 007, 025, 035, 050, 052 · API-10-003, 010, 034, 039, 044, 048, 061, 104, 058 · ERR-10-001, 005.

**Tiền điều kiện, dữ liệu.** U-T68-IE1; T01 có đối tượng trùng mã mục 2.3.

**Các bước.**

1. Với mỗi API đọc có tham số đường dẫn (API-10-003, 010, 021, 024, 034, 039, 044, 048, 052, 053, 055, 058, 061, 104, 110), gọi bằng mã của đối tượng chỉ có ở T01, rồi bằng mã không tồn tại.
2. Gọi `GET /topics/t01.dkkd.doanh-nghiep.da-cap-phep.v1` bằng token T68.
3. Thử đặt tiêu đề `X-Dh-Tenant: T01`, tham số `tenant=T01`, trường `tenantId` trong thân.

**Kết quả mong đợi.** Bước 1 mọi cặp trả 404-ẩn giống hệt nhau trừ `traceId`. Bước 2 404-ẩn. Bước 3 bị bỏ qua, tenant luôn lấy từ token; ghi mới đều thuộc T68 hoặc bị `422` ERR-10-005 với tên topic tiền tố khác.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-005 "Tiền tố tenant của topic không khớp tenant đang làm việc."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-125 · ACL Kafka theo tiền tố tenant cho principal nội bộ, literal cho HTTT <!--k:iso-kafka-acl-->

::: dac-ta
**Mục đích.** Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** FR-10-064, 031, 037 · ERR-10-120 · BR-10-018, 022 · ADR-072.

**Tiền điều kiện, dữ liệu.** Principal `User:CN=dh-runtime-t90`, `User:CN=dh-runtime-t91`; HTTT T90 có ACL literal trên một topic.

**Các bước.**

1. Liệt kê ACL của cụm (`kafka-acls --list`).
2. `dh-runtime-t90` đọc, ghi topic `t91.*`; tham gia nhóm `dh-sub-t91-*`.
3. HTTT T90 đọc topic khác của T90 không có subscription; mô tả danh sách topic của cụm.
4. Kyverno: commit `KafkaTopic` tên `t91.x.y.z.v1` vào kho `dh-config-t90`.

**Kết quả mong đợi.** Bước 1 không principal nào của tenant A có ACL trên tiền tố hay nhóm của tenant B; ACL nội bộ là `PREFIXED` `t90.`, của HTTT là `LITERAL`. Bước 2, 3 bị từ chối, liệt kê topic chỉ trả topic được phép. Bước 4 Kyverno từ chối, không có topic nào được tạo.

**Thông báo hiển thị.** ERR-10-120 nhãn "Kafka từ chối do ACL, hạn mức".

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-126 · Apicurio, OPA và Valkey theo tenant <!--k:iso-registry-opa-->

::: dac-ta
**Mục đích.** Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-10-064, 024 · API-10-084 · ERR-10-103.

**Tiền điều kiện, dữ liệu.** Client HTTT T90 có scope subscribe một topic T90; bundle OPA `event/grants/t90.json`, `t91.json`.

**Các bước.**

1. Tra artifact nhóm `t91` qua API-10-084; liệt kê nhóm.
2. Sửa thủ công token T90 thêm scope `topic:t91.….v1:subscribe` (ký bằng khóa Keycloak thử của T90) rồi kéo.
3. Đọc khóa Valkey `dh:t91:evt:*` bằng thông tin của cổng T90.

**Kết quả mong đợi.** Bước 1 404-ẩn; liệt kê chỉ có `t90`. Bước 2 bị từ chối vì không có cặp cấp quyền trong dữ liệu OPA của T90 và tiền tố khác tenant (404-ẩn ERR-10-103). Bước 3 ACL Valkey từ chối.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-103 "Topic {tên} không tồn tại, không nhận sự kiện ở trạng thái hiện tại hoặc thuộc tenant khác."

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-127 · Bộ rò rỉ đầu cuối T90…T99 <!--k:iso-sweep-->

::: dac-ta
**Mục đích.** Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-10-064 · NFR-10-017.

**Tiền điều kiện, dữ liệu.** T90…T99 mỗi tenant một bộ dữ liệu mục 2.3 sinh bằng `ph10/seed/perf.py`, mã trùng nhau.

**Các bước.**

1. Với mỗi cặp (A, B) chạy kịch bản: đọc mọi API của B bằng người dùng A; phát lên topic B bằng client A; kéo subscription B bằng client A; đọc Kafka B bằng principal A; tra lược đồ B.
2. Tìm chuỗi mồi `DH-CANARY-T9n` của B trong mọi phản hồi, log, vết của A.

**Kết quả mong đợi.** 0 lượt thành công trên 90 cặp; 0 lần thấy mồi khác tenant. Kết quả ghi vào báo cáo đêm.

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-128 · PO xem liên tenant có lý do và kiểm toán <!--k:iso-po-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-064 (Cách ly đa tenant trên trục sự kiện).

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-064, 065 · ERR-10-009.

**Tiền điều kiện, dữ liệu.** U-PO.

**Các bước.**

1. U-PO xem dashboard T68 không lý do; có lý do "Hỗ trợ sự cố lag cụm".

**Kết quả mong đợi.** Không lý do bị chặn (`400` ERR-10-009); có lý do xem được chỉ đọc; KT: có (truy cập liên tenant, lý do).

**Thông báo hiển thị.** ERR-10-009 "Cần nhập lý do hoặc xác nhận trước khi tiếp tục."

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-31 · Phân quyền theo ma trận PERM-10 và bốn mắt

**Mục tiêu.** Chứng minh ma trận `PERM-10-*` ở D02-08 (dòng 105–111) và FRS §3.2 được áp ở mọi API control plane cho cả 11 vai trò, scope máy `event:*` chỉ mở đúng operation, và bốn mắt không có đường vòng.

**Phủ.** FR-10-065, 009, 019, 031, 037, 051; BR-10-010; ERR-10-008, 044, 053, 054; NFR-10-020.

Bảng ca phân quyền tham số hóa (một dòng một vai trò, chạy mọi operation đại diện của quyền; ● phải thành công, — phải trả 403-PQ, ○ thành công với đối tượng của tổ chức mình và 403-TC ngoài tổ chức):

| Quyền | Operation đại diện | PA | PO | TA | TO | SO | IE | IA | SV | OR | VW | AU |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `PERM-10-read` | API-10-001, 010, 048, 066, 007, 074 | ● | ● | ● | ● | ● | ● | ● | ● | ○ | ● | ● |
| `PERM-10-create` | API-10-002, 009, 023, 033, 043 | — | — | ● | — | — | ● | — | ○ | — | — | — |
| `PERM-10-update` | API-10-004, 005, 011, 015, 016, 093, 097 | — | — | ● | — | — | ● | — | ○ | — | — | — |
| `PERM-10-subscribe` | API-10-047, 049, 051, 099, 120 | — | — | ● | — | — | ● | — | — | ○ | — | — |
| `PERM-10-approve` | API-10-059, 101 | — | — | ● | — | — | — | ● | — | — | — | — |
| `PERM-10-operate` | API-10-036, 045, 050, 054, 062, 064, 103, 056 | — | — | ● | ● | ● (chỉ tạm ngừng) | — | — | — | — | — | — |
| `PERM-10-admin` | API-10-105, 107, 108, 091, 113, 078 | ● | — | ● | — | — | — | — | — | — | — | — |

: Ma trận ca phân quyền tham số hóa theo quyền và vai trò

#### TC-10-129 · Vai trò được phép thực hiện đúng operation của quyền <!--k:perm-pos-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-065 (Kiểm toán và lịch sử thay đổi).

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-065 · API-10-001, 002, 004, 047, 059, 050, 108 · NFR-10-020.

**Tiền điều kiện, dữ liệu.** Một người dùng mỗi vai trò ở T68 (mục 2.2); đối tượng `tc-` riêng cho mỗi dòng.

**Các bước.**

1. Với mỗi ô ● của bảng, gọi mọi operation đại diện với thân hợp lệ.
2. Với ô ○, gọi trên đối tượng của tổ chức mình.

**Kết quả mong đợi.** Mọi lượt trả mã thành công của API §3; mọi lượt ghi có bản ghi kiểm toán (đối chiếu 100 %).

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-130.
:::

#### TC-10-130 · Vai trò không được phép bị chặn ở máy chủ, không chỉ ẩn nút <!--k:perm-neg-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-065 (Kiểm toán và lịch sử thay đổi).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-10-065 · ERR-10-044, 053, 054.

**Tiền điều kiện, dữ liệu.** Như TC-10-129.

**Các bước.**

1. Với mỗi ô — gọi mọi operation đại diện.
2. Với ô ○ gọi trên đối tượng ngoài tổ chức.
3. Gọi không token; với token hết hạn.
4. Mở màn tương ứng bằng vai trò không có quyền.

**Kết quả mong đợi.** Bước 1 403-PQ (ERR-10-054), không có thay đổi dữ liệu. Bước 2 403-TC. Bước 3 `401` ERR-10-053. Bước 4 nút hành động không hiện hoặc bị vô hiệu kèm lý do (`allowedActions`, `disabledReasons`), và gọi trực tiếp vẫn bị chặn.

**Thông báo hiển thị.** ERR-10-044 ST-07 "Đối tượng ngoài phạm vi tổ chức của bạn."; ERR-10-053 "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Đăng nhập lại để tiếp tục."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-131 · Scope máy chỉ mở operation được cấp <!--k:perm-machine-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-066, 069, 038, 050, 053 · API-10-071, 073, 060, 064, 009 · ERR-10-054.

**Tiền điều kiện, dữ liệu.** S-PH05, S-PH04, S-RT-T68, S-PH18, S-PH13.

**Các bước.**

1. Mỗi tài khoản gọi operation của scope mình (API §2.2) và một operation của scope khác (S-PH05 gọi API-10-071; S-PH04 gọi API-10-009; S-PH13 gọi API-10-064; S-PH18 gọi API-10-059; S-RT-T68 gọi API-10-047).
2. S-RT-T68 gọi API-10-073 với tenant T01.

**Kết quả mong đợi.** Bước 1 operation của mình thành công; operation khác 403-PQ. Bước 2 404-ẩn hoặc 403-PQ, không trả cấu hình T01.

**Thông báo hiển thị.** ERR-10-001 "Không tìm thấy {loại đối tượng} {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."; ERR-10-054 ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-132 · Bốn mắt cho mọi loại yêu cầu duyệt, kể cả TA và người có hai vai trò <!--k:perm-4eyes-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-10-009, 019, 031, 037, 051, 075 · API-10-059 · ERR-10-008 · BR-10-010.

**Tiền điều kiện, dữ liệu.** U-T68-TA, U-T68-IA2 (IA + IE).

**Các bước.**

1. Với 9 `requestType` (`TOPIC_CREATE`, `TOPIC_CHANGE`, `TOPIC_RETIRE`, `SCHEMA_VERSION`, `PUBLICATION`, `SUBSCRIPTION`, `REPLAY`, `BRIDGE`, `CUTOVER`): TA tạo hoặc gửi rồi tự duyệt.
2. IA2 soạn phiên bản lược đồ, IE1 gửi duyệt, IA2 duyệt.
3. IE1 tạo topic, IA2 gửi duyệt hộ (rút rồi gửi lại), IA2 duyệt.

**Kết quả mong đợi.** Bước 1 mọi lượt `403` ERR-10-008. Bước 2, 3 `403` ERR-10-008 (người soạn, người gửi đều không được duyệt). Không có yêu cầu nào đổi trạng thái.

**Thông báo hiển thị.** ERR-10-008 "Bạn đã tạo hoặc gửi yêu cầu này nên không được duyệt. Cần người duyệt khác."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-133 · Yêu cầu duyệt hết hạn trả đối tượng về trạng thái trước <!--k:perm-expire-->

::: dac-ta
**Mục đích.** Chứng minh hành vi đúng tại mốc hết hạn của yêu cầu duyệt, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).

**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-10-009, 019 · API-10-057.

**Tiền điều kiện, dữ liệu.** Topic `PENDING_APPROVAL`, phiên bản lược đồ `PENDING_APPROVAL`; `10.approval.expire-days = 30`.

**Các bước.**

1. Đặt đồng hồ +31 ngày.

**Kết quả mong đợi.** Hai yêu cầu `EXPIRED`; topic, phiên bản về `DRAFT`; người gửi nhận thông báo; "Việc của tôi" của IA không còn hai mục.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

### TS-10-32 · Kiểm toán và an toàn bí mật

**Mục tiêu.** Chứng minh 100 % thao tác ghi có kiểm toán đủ trường, không chứa bí mật ký hay nội dung sự kiện, và bí mật ký chỉ ở OpenBao.

**Phủ.** FR-10-065, 042; BR-10-027; NFR-10-016, 020; ERR-10-037.

#### TC-10-134 · Đối chiếu kiểm toán với mọi lệnh ghi <!--k:audit-all-->

::: dac-ta
**Mục đích.** Chứng minh luồng thành công, theo FR-10-065 (Kiểm toán và lịch sử thay đổi).

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-10-065 · NFR-10-020.

**Tiền điều kiện, dữ liệu.** Toàn bộ ca API của TS-10-01…29 trong một lần chạy SIT.

**Các bước.**

1. Lấy danh sách lệnh ghi thành công từ nhật ký APISIX; lấy bản ghi kiểm toán PH-13 theo `traceId`.
2. Mở tab Lịch sử ở UI-10-03, 06, 12.

**Kết quả mong đợi.** Mỗi lệnh ghi có đúng một bản ghi với chủ thể, hành động, đối tượng, giá trị trước và sau, lý do, mã yêu cầu duyệt, mã commit khi có; thao tác hệ thống có chủ thể `system:dh-…`. Tab Lịch sử hiển thị đúng.

**Hậu điều kiện.** Đối tượng ở trạng thái nêu ở kết quả mong đợi.
:::

#### TC-10-135 · Mồi khóa ký qua toàn bộ vòng đời subscription <!--k:audit-canary-->

::: dac-ta
**Mục đích.** Chứng minh yêu cầu an toàn nêu ở tên ca không có đường vòng, theo FR-10-042 (Xoay khóa ký webhook).

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** E2E, API.

**Truy vết.** FR-10-042, 037, 047, 070 · NFR-10-016 · BR-10-027 · API-10-120, 054, 100, 074.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-TO; subscription PUSH thử.

**Các bước.**

1. Duyệt, nhận khóa, xoay, thu hồi khẩn, xuất khai báo, thu hồi subscription; ghi lại mọi giá trị `whsec_…` đã thấy.
2. Tìm các giá trị đó trong HAR của Playwright, `localStorage`, `sessionStorage`, log mọi pod 1 giờ, vết, bảng `ph10_event.*`, outbox, Kafka `t68.*`, DLQ, tệp xuất, kiểm toán, thư thông báo.

**Kết quả mong đợi.** Mồi sạch; giá trị chỉ có ở OpenBao `kv/dh/t68/event/subscriptions/{subscriptionCode}/signing`; khóa ≥ 256 bit ngẫu nhiên; `signing_key` chỉ có `keyId`, `secretRef`.

**Hậu điều kiện.** Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi.
:::

#### TC-10-136 · Idempotency-Key dùng lại với thân khác <!--k:idem-->

::: dac-ta
**Mục đích.** Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-003 (Tạo dự án tích hợp).

**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-10-003, 008, 035 · API-10-002, 009, 047 · ERR-10-037.

**Tiền điều kiện, dữ liệu.** U-T68-IE1.

**Các bước.**

1. `POST /projects` hai lần cùng khóa cùng thân; lần ba cùng khóa khác tên.
2. Khóa 15 ký tự; sau 25 giờ dùng lại khóa.

**Kết quả mong đợi.** Bước 1 lần hai trả lại phản hồi cũ (`201`, cùng `Location`), lần ba `422` ERR-10-037. Bước 2 khóa ngắn `400` ERR-10-003; sau 25 giờ xử lý như mới.

**Thông báo hiển thị.** ERR-10-003 câu theo `errors[]` của từng trường, ví dụ "Mã chỉ gồm chữ thường, số và dấu gạch ngang, bắt đầu bằng chữ, 3 đến 63 ký tự."; ERR-10-037 "Yêu cầu trùng khóa chống gửi lặp nhưng nội dung khác. Tải lại trang rồi thử lại."

**Hậu điều kiện.** Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
:::

### TS-10-33 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-10-001…005, 008…012, 014, 015, 018 ở cấu hình `QM-VUA` với dữ liệu GĐ.

**Phủ.** NFR-10-001…005, 008…012, 014, 015, 018.

| Ca | Tên | Ngưỡng đạt | Yêu cầu phi chức năng |
|---|---|---|---|
| TC-10-137 | API control plane | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | NFR-10-001 |
| TC-10-138 | Độ trễ API phát | p99 ≤ 50 ms tới `202`, gồm kiểm lược đồ và `acks=all` | NFR-10-002 |
| TC-10-139 | Độ trễ đầu cuối khi đẩy | p95 ≤ 1 giây từ ghi Kafka tới gửi | NFR-10-003 |
| TC-10-140 | Thông lượng cổng sự kiện | ≥ 2.000 sự kiện/giây mỗi bản sao, tuyến tính tới 3 | NFR-10-004 |
| TC-10-141 | Thông lượng bộ giao nhận | ≥ 200 lượt/giây mỗi bản sao | NFR-10-005 |
| TC-10-142 | Thời gian cấp phát | Topic `ACTIVE` p95 ≤ 3 phút; quan hệ ≤ 2 phút | NFR-10-008 |
| TC-10-143 | Hiệu lực tạm ngừng, thu hồi | API từ chối ≤ 60 giây; ACL ≤ 2 phút | NFR-10-009 |
| TC-10-144 | Phát hiện lag | Cảnh báo ≤ 2 phút | NFR-10-010 |
| TC-10-145 | Hiệu lực tạm dừng subscription | Không lượt mới sau ≤ 10 giây | NFR-10-011 |
| TC-10-146 | Tốc độ phát lại | ≥ 2.000 sự kiện/giây; tôn trọng `ratePerSecond` ±5 % | NFR-10-012 |
| TC-10-147 | Quy mô cụm | Control plane, bộ thu lag, đối soát hết chu kỳ trong thời hạn | NFR-10-014 |
| TC-10-148 | Hiển thị sơ đồ | ≤ 2 giây; kéo 60 khung hình/giây | NFR-10-015 |
| TC-10-149 | Cầu nối di trú | p95 ≤ 60 giây; đối chiếu chênh 0 | NFR-10-018 |

: Tóm tắt ngưỡng của 13 ca hiệu năng TS-10-33

Mỗi ca dưới đây có loại Hiệu năng, tự động bằng k6, chạy trên PERF với bộ dữ liệu quy mô theo GĐ ở tenant T97…T99. Ca đo NFR-10-002, 003, 009, 010 có ưu tiên P1 vì chặn phát hành; các ca còn lại ưu tiên P2.

#### TC-10-137 · API control plane <!--k:perf-api-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-001 (Thời gian phản hồi API control plane).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-001 · FR-10-001, 006, 035.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 500 topic, 2.000 subscription mỗi tenant; 50 người dùng đồng thời, 30 phút.

**Kết quả mong đợi.** Đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-138 · Độ trễ API phát <!--k:perf-publish-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-002 (Độ trễ API phát).

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-10-002 · FR-10-033.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 500 sự kiện/giây, 2 KB, Avro, 30 phút.

**Kết quả mong đợi.** Đạt ngưỡng: p99 ≤ 50 ms tới `202`, gồm kiểm lược đồ và `acks=all`.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-139 · Độ trễ đầu cuối khi đẩy <!--k:perf-push-latency-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-003 (Độ trễ đầu cuối khi đẩy).

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-10-003 · FR-10-038.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 200 sự kiện/giây, endpoint 50 ms, không tồn đọng.

**Kết quả mong đợi.** Đạt ngưỡng: p95 ≤ 1 giây từ ghi Kafka tới gửi.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-140 · Thông lượng cổng sự kiện <!--k:perf-gateway-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-004 (Thông lượng cổng sự kiện).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-004 · FR-10-033.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: Tăng dần tới bão hòa, 1, 2, 3 bản sao 1 vCPU.

**Kết quả mong đợi.** Đạt ngưỡng: ≥ 2.000 sự kiện/giây mỗi bản sao, tuyến tính tới 3.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-141 · Thông lượng bộ giao nhận <!--k:perf-delivery-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-005 (Thông lượng bộ giao nhận).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-005 · FR-10-038.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 2.000 subscription đẩy, endpoint 50 ms, 3 bản sao.

**Kết quả mong đợi.** Đạt ngưỡng: ≥ 200 lượt/giây mỗi bản sao.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-142 · Thời gian cấp phát <!--k:perf-provision-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-008 (Thời gian cấp phát).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-008 · FR-10-009, 031, 037.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 50 topic, 100 subscription duyệt liên tiếp, Argo CD 30 giây.

**Kết quả mong đợi.** Đạt ngưỡng: Topic `ACTIVE` p95 ≤ 3 phút; quan hệ ≤ 2 phút.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-143 · Hiệu lực tạm ngừng, thu hồi <!--k:perf-suspend-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-009 (Hiệu lực tạm ngừng, thu hồi).

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-10-009 · FR-10-032, 029.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 100 lượt phát/giây, 3 bản sao cổng.

**Kết quả mong đợi.** Đạt ngưỡng: API từ chối ≤ 60 giây; ACL ≤ 2 phút.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-144 · Phát hiện lag <!--k:perf-lag-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-010 (Phát hiện lag).

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-10-010 · FR-10-054, 055.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 5.000 nhóm tiêu thụ, 200 vượt ngưỡng ngẫu nhiên.

**Kết quả mong đợi.** Đạt ngưỡng: Cảnh báo ≤ 2 phút.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-145 · Hiệu lực tạm dừng subscription <!--k:perf-pause-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-011 (Hiệu lực tạm dừng subscription).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-011 · FR-10-041.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 100 subscription đẩy đang giao.

**Kết quả mong đợi.** Đạt ngưỡng: Không lượt mới sau ≤ 10 giây.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-146 · Tốc độ phát lại <!--k:perf-replay-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-012 (Tốc độ phát lại).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-012 · FR-10-052.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 1 triệu sự kiện, endpoint 20 ms.

**Kết quả mong đợi.** Đạt ngưỡng: ≥ 2.000 sự kiện/giây; tôn trọng `ratePerSecond` ±5 %.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-147 · Quy mô cụm <!--k:perf-scale-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-014 (Quy mô).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-014 · FR-10-010, 054.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 1.000 topic, 10.000 phân vùng, 5.000 nhóm; 500 topic một tenant.

**Kết quả mong đợi.** Đạt ngưỡng: Control plane, bộ thu lag, đối soát hết chu kỳ trong thời hạn.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-148 · Hiển thị sơ đồ <!--k:perf-graph-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-015 (Hiển thị sơ đồ).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-015 · FR-10-058.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 300 nút, 600 cạnh, máy văn phòng chuẩn.

**Kết quả mong đợi.** Đạt ngưỡng: ≤ 2 giây; kéo 60 khung hình/giây.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

#### TC-10-149 · Cầu nối di trú <!--k:perf-bridge-->

::: dac-ta
**Mục đích.** Đo trên PERF và chứng minh đạt ngưỡng, theo NFR-10-018 (Cầu nối di trú).

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-018 · FR-10-073, 075.

**Tiền điều kiện, dữ liệu.** Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99.

**Các bước.**

1. Chạy tải: 200 sự kiện/giây mỗi cầu nối, 24 giờ.

**Kết quả mong đợi.** Đạt ngưỡng: p95 ≤ 60 giây; đối chiếu chênh 0.

**Hậu điều kiện.** Kết quả đo ghi vào báo cáo đợt; hệ thống về tải nền.
:::

### TS-10-34 · Chịu lỗi, hỗn loạn và phục hồi

**Mục tiêu.** Chứng minh NFR-10-006, 007, 013, 019: không mất sự kiện khi mất broker hay khởi động lại bộ giao nhận, tỷ lệ trùng thấp, data plane chạy khi control plane ngừng, cấu hình sao sang site DR.

**Phủ.** NFR-10-006, 007, 013, 019; FR-10-038, 043, 049, 033.

#### TC-10-150 · Không mất sự kiện khi mất một broker và khởi động lại bộ giao nhận <!--k:chaos-no-loss-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo NFR-10-006 (Không mất sự kiện).

**Loại.** Khả dụng.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-10-006 · FR-10-033, 038, 049 · BR-10-007, 024.

**Tiền điều kiện, dữ liệu.** PERF; 1 triệu sự kiện qua API phát vào TP-CP; SUB-PUSH tới SIM-WH đếm theo `Webhook-Id`.

**Các bước.**

1. Trong lúc phát và giao: giết một broker; xóa ngẫu nhiên pod cổng sự kiện và bộ giao nhận 10 lần; ngắt mạng SIM-WH 2 phút.
2. Đối chiếu số `202`, số bản tin Kafka, số `Webhook-Id` duy nhất SIM-WH nhận cộng mục DLQ.

**Kết quả mong đợi.** 0 sự kiện mất: mọi `id` được `202` có trên Kafka và hoặc được SIM-WH nhận, hoặc có mục DLQ.

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

#### TC-10-151 · Tỷ lệ giao trùng trong vận hành bình thường <!--k:chaos-dup-rate-->

::: dac-ta
**Mục đích.** Đo tỷ lệ giao trùng ở tải nền và chứng minh đạt ngưỡng, theo NFR-10-007 (Tỷ lệ giao trùng).

**Loại.** Khả dụng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-10-007 · BR-10-009.

**Tiền điều kiện, dữ liệu.** PERF; tải nền 24 giờ.

**Các bước.**

1. Đếm lượt SIM-WH nhận có `Webhook-Id` lặp.

**Kết quả mong đợi.** ≤ 0,1 % lượt giao; mọi lượt trùng cùng `Webhook-Id`.

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

#### TC-10-152 · Data plane chạy khi control plane và pg-core ngừng <!--k:chaos-cp-down-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo NFR-10-013 (Sẵn sàng data plane sự kiện).

**Loại.** Khả dụng.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-10-013 · FR-10-033, 038, 043 · ERR-10-029.

**Tiền điều kiện, dữ liệu.** SIT; tải nền phát, đẩy, kéo.

**Các bước.**

1. Dừng `dh-integration` và `pg-core` 30 phút.
2. Gọi một lệnh control plane bất kỳ.
3. Khởi động lại.

**Kết quả mong đợi.** Bước 1 API phát, API kéo, bộ giao nhận tiếp tục với ảnh chụp cấu hình ở Valkey; `dh_event_runtime_config_age_seconds` tăng, cảnh báo sau 10 phút; mục DLQ chờ trên topic `.dlq`. Bước 2 `503` ERR-10-029. Bước 3 bộ ghi DLQ tạo đủ mục từ topic `.dlq`; số liệu giao nhận đệm ≤ 15 phút được gửi bù.

**Thông báo hiển thị.** ERR-10-029 "Dịch vụ {tên} tạm thời không khả dụng; thay đổi chưa được ghi. Thử lại sau."

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

#### TC-10-153 · Outbox không mất sự kiện PH-10 khi Kafka ngừng <!--k:chaos-outbox-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-009 (Duyệt tạo topic và cấp phát trên cụm).

**Loại.** Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-10-009, 037 · EVT-10-01, 08.

**Tiền điều kiện, dữ liệu.** SIT; 20 lệnh duyệt trong lúc Kafka ngừng 5 phút.

**Các bước.**

1. Dừng Kafka, duyệt topic và subscription; bật lại.

**Kết quả mong đợi.** Mọi EVT `topic.activated`, `subscription.activated` được phát sau khi Kafka trở lại, đúng thứ tự theo khóa, không trùng ngoài ngữ nghĩa ít nhất một lần.

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

#### TC-10-154 · Sao cấu hình sang site DR <!--k:chaos-dr-->

::: dac-ta
**Mục đích.** Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo NFR-10-019 (Phục hồi thảm họa).

**Loại.** Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Chaos, Thủ công.

**Truy vết.** NFR-10-019.

**Tiền điều kiện, dữ liệu.** Hai site SIT với MirrorMaker 2 qua listener `replication`.

**Các bước.**

1. Tạo topic, ACL, nhóm tiêu thụ ở site chính; cắt site chính; chuyển sang site DR.

**Kết quả mong đợi.** Cấu hình topic, ACL, offset nhóm có ở site DR với RPO < 30 giây; subscription tiếp tục từ offset đã dịch.

**Hậu điều kiện.** Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
:::

### TS-10-35 · Truy cập và giao diện

**Mục tiêu.** Chứng minh UI-10-* đạt WCAG 2.2 AA, các màn chính (danh sách topic, chi tiết topic, đăng ký nhận, chi tiết subscription, DLQ, duyệt, sơ đồ) dùng được bằng bàn phím và trình đọc màn hình.

**Phủ.** UI-10-01…20; FR-10-058, 035, 050.

#### TC-10-155 · Quét tự động truy cập mọi màn <!--k:a11y-axe-->

::: dac-ta
**Mục đích.** Chứng minh mọi màn UI-10 không có vi phạm truy cập khi quét tự động.

**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E.

**Truy vết.** UI-10-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20.

**Tiền điều kiện, dữ liệu.** U-T68-TA; dữ liệu mục 2.

**Các bước.**

1. Chạy axe-core trên mọi màn, mọi trạng thái chính (rỗng, có dữ liệu, lỗi, đang tải), chế độ sáng, tối, giảm trong suốt.

**Kết quả mong đợi.** 0 vi phạm mức nghiêm trọng và nghiêm trọng vừa; tương phản chữ ≥ 4,5:1, tên topic, mã ≥ 7:1 trên nền đặc.

**Hậu điều kiện.** Dữ liệu không đổi.
:::

#### TC-10-156 · Đăng ký nhận sự kiện và duyệt chỉ bằng bàn phím <!--k:a11y-keyboard-->

::: dac-ta
**Mục đích.** Chứng minh màn dùng được bằng bàn phím và trình đọc màn hình, theo FR-10-035 (Đề nghị subscription).

**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E, Thủ công.

**Truy vết.** UI-10-11, 13 · FR-10-035, 037.

**Tiền điều kiện, dữ liệu.** U-T68-IE1, U-T68-IA1; NVDA trên Windows (thủ công).

**Các bước.**

1. Đi hết trình hướng dẫn UI-10-11 (chọn topic, chế độ, URI, xác minh, tham số, gửi), rồi duyệt ở UI-10-13 không dùng chuột.

**Kết quả mong đợi.** Hoàn thành được; tiêu điểm luôn thấy; kết quả xác minh endpoint, lỗi trường được đọc qua vùng `aria-live`; không bẫy tiêu điểm trong khung soạn lược đồ.

**Hậu điều kiện.** Dữ liệu không đổi.
:::

#### TC-10-157 · Sơ đồ kết nối có phương án thay thế dạng bảng <!--k:a11y-graph-->

::: dac-ta
**Mục đích.** Chứng minh sơ đồ kết nối có phương án thay thế dạng bảng cho người dùng trình đọc màn hình, theo FR-10-058 (Sơ đồ kết nối tương tác).

**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-10-14 · FR-10-058.

**Tiền điều kiện, dữ liệu.** U-T68-VW; P-DKKD.

**Các bước.**

1. Dùng Tab và phím mũi tên đi qua các nút; bật chế độ "Xem dạng bảng".

**Kết quả mong đợi.** Mỗi nút, cạnh có nhãn đọc được (loại, mã, trạng thái, lag); bảng thay thế liệt kê đủ cạnh với cùng thông tin; trạng thái lag không chỉ bằng màu.

**Hậu điều kiện.** Dữ liệu không đổi.
:::

#### TC-10-158 · Thu phóng 200 % và trạng thái không chỉ bằng màu <!--k:a11y-zoom-->

::: dac-ta
**Mục đích.** Chứng minh giao diện dùng được khi thu phóng 200 % và trạng thái không chỉ truyền bằng màu.

**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-10-05, 12, 15, 17.

**Tiền điều kiện, dữ liệu.** U-T68-TO.

**Các bước.**

1. Bật mô phỏng mù màu; thu phóng 200 % ở 1280 px và ở 390 px.

**Kết quả mong đợi.** Mọi `alertState`, trạng thái topic, mục DLQ có chữ hoặc ký hiệu; bảng chuyển dạng thẻ ở 390 px, không cuộn ngang trang.

**Hậu điều kiện.** Dữ liệu không đổi.
:::

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Ba phiên 90 phút: (1) khai báo dự án, topic, lược đồ cho một nghiệp vụ thật của tỉnh thí điểm (đăng ký kinh doanh sang thuế); (2) tích hợp webhook với một HTTT thật ở TEST, xác minh chữ ký bằng mã mẫu của chính HTTT; (3) di trú một project Hub cũ qua cầu nối. Ghi theo mẫu SBTM, lỗi chuyển thành ca tự động.

### 6.2. Diễn tập chuyển từ Hub Pulsar

Dùng bản xuất CSDL cấu hình Hub cũ thật (đã làm sạch): nhập kiểm kê, rà ánh xạ, duyệt khai báo đích, chạy cầu nối 14 ngày ở UAT, đối chiếu mỗi giờ, chuyển hẳn một ánh xạ và quay lui một ánh xạ. Đạt khi chênh lệch đối chiếu 0, không subscriber cũ nào mất bản tin, và cán bộ vận hành làm hết không cần hỗ trợ ngoài tài liệu.

### 6.3. Diễn tập sự cố

Ba tình huống, có SO, TO tham gia: (1) khóa ký webhook bị lộ: thu hồi khẩn, HTTT cập nhật khóa, đối chiếu kiểm toán; (2) HTTT nhận ngừng 4 giờ: cảnh báo lag, tạm dừng, phát lại theo khoảng; (3) bên phát Kafka trực tiếp phát sai lược đồ: phát hiện tuân thủ, tạm ngừng publication.

### 6.4. Kiểm thử truy cập thủ công

Với NVDA + Firefox và VoiceOver + Safari trên UI-10-06, 11, 12, 14, 15: đi hết luồng chính, ghi lỗi theo WCAG 2.2.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ vận hành Hub cũ tự thực hiện trên UAT. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem tổng số publisher, subscriber, project, topic | LGC-HUB-001…004 | Bốn thẻ đếm ngay trên màn tổng quan, bấm vào ra danh sách đã lọc | FR-10-057 | TS-10-23 |
| UAT-02 | Xem tài nguyên CPU, bộ nhớ của cụm | LGC-HUB-005, 006 | Một thao tác từ màn tổng quan sang bảng chỉ số cụm PH-13 | FR-10-057 | TS-10-23 |
| UAT-03 | Xem sơ đồ kết nối của một dự án | LGC-HUB-007 | Sơ đồ ba lớp lọc theo dự án, thấy cạnh đang lag, có DLQ | FR-10-058 | TS-10-23 |
| UAT-04 | Tạo, sửa, lưu trữ dự án tích hợp | LGC-HUB-008 | Làm được như hệ cũ; thay "xóa" bằng lưu trữ có lý do | FR-10-003, 004, 005 | TS-10-01 |
| UAT-05 | Tạo topic với phân vùng, cấu trúc, chế độ định tuyến | LGC-HUB-009 | Tạo được trong 5 phút; cấu trúc thành lược đồ có kiểm tra | FR-10-008, 017 | TS-10-02, 06 |
| UAT-06 | Thêm publisher, subscriber, đánh dấu subscriber là luồng | LGC-HUB-010, 011 | Chọn HTTT, luồng từ danh sách, giữ khóa tham chiếu cũ | FR-10-026, 027 | TS-10-08 |
| UAT-07 | Cho một publisher phát lên topic | LGC-HUB-012 | Đề nghị, được duyệt và phát được trong ngày | FR-10-030, 031 | TS-10-10 |
| UAT-08 | Khai báo subscription với URI, số worker, số lần thử lại, thời điểm bắt đầu | LGC-HUB-013 | Đủ bốn tham số cũ; thêm xác minh endpoint, khóa ký | FR-10-035, 036, 040 | TS-10-13 |
| UAT-09 | Xem, sửa danh mục kiểu giao tiếp, chế độ định tuyến | LGC-HUB-014 | Thấy mã hệ cũ bên cạnh mã mới | FR-10-060, 061 | TS-10-24 |
| UAT-10 | Chuyển một project từ Hub cũ sang Datahub | LGC-HUB-008…014, LGC-TOOL-010 | Có đề xuất ánh xạ từ kiểm kê, cầu nối chạy, subscriber cũ không gián đoạn | FR-10-072, 073, 075 | TS-10-28, 29 |

: Kịch bản nghiệm thu UAT-01…10 tương đương Hub cũ

## 8. Ma trận truy vết

Chương này là bằng chứng độ phủ: FR, chức năng hệ cũ, quy tắc nghiệp vụ, mã lỗi và yêu cầu phi chức năng tới các ca. Toàn bộ chương do `ph10/tools/gen_matrix.py` sinh từ trường "Truy vết" và mã lỗi ghi trong "Kết quả mong đợi" của từng ca; không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-10. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph10/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-10-001 | Liệt kê, tìm kiếm và lọc dự án tích hợp | M | LGC-HUB-008 | 003 | 003 | 137 | Có |
| FR-10-002 | Xem chi tiết dự án | M | LGC-HUB-008 | 001 | 124 | — | Có |
| FR-10-003 | Tạo dự án tích hợp | M | LGC-HUB-008 | 001 | 002, 136 | — | Có |
| FR-10-004 | Sửa dự án | M | LGC-HUB-008 | 004 | 004 | — | Có |
| FR-10-005 | Lưu trữ và khôi phục dự án | M | LGC-HUB-008 | 005 | 005 | — | Có |
| FR-10-006 | Liệt kê, tìm kiếm và lọc topic | M | LGC-HUB-009 | 010 | 010, 124 | 137 | Có |
| FR-10-007 | Xem chi tiết topic | M | LGC-HUB-009 | 010 | 010, 124 | — | Có |
| FR-10-008 | Tạo topic và gửi duyệt | M | LGC-HUB-009, LGC-HUB-014 | 006, 011 | 007, 008, 009, 011, 136 | — | Có |
| FR-10-009 | Duyệt tạo topic và cấp phát trên cụm | M | LGC-HUB-009 | 012 | 013, 014, 132 | 133, 142, 153 | Có |
| FR-10-010 | Theo dõi cấp phát và xử lý cấp phát thất bại | M | LGC-HUB-009 | 015 | 015, 016 | 147 | Có |
| FR-10-011 | Tăng số phân vùng của topic đang hoạt động | M | LGC-HUB-009 | 017 | 018 | — | Có |
| FR-10-012 | Thay đổi lưu giữ và chính sách dọn (compaction) | M | LGC-HUB-009 | 019 | 019 | — | Có |
| FR-10-013 | Chế độ định tuyến và khóa phân vùng | M | LGC-HUB-009, LGC-HUB-014 | 020, 047 | 008, 020 | — | Có |
| FR-10-014 | Ngừng khuyến nghị và ngừng dùng topic | M | LGC-HUB-009 | 022, 023 | 023 | — | Có |
| FR-10-015 | Tạo phiên bản chính mới của topic khi thay đổi phá vỡ | M | LGC-HUB-009 | 024, 110 | 025, 036, 110 | — | Có |
| FR-10-016 | Theo dõi chuyển đổi bên nhận sang phiên bản topic mới | S | LGC-HUB-009 | 026 | — | — | Có |
| FR-10-017 | Soạn và kiểm tra lược đồ | M | LGC-HUB-009 | 027 | 009, 028 | — | Có |
| FR-10-018 | Kiểm tra tương thích với các phiên bản đã có | M | mới | 027, 033, 035 | 033 | — | Có |
| FR-10-019 | Gửi duyệt và duyệt phiên bản lược đồ | M | mới | 029, 035 | 025, 030, 132 | 133 | Có |
| FR-10-020 | Xem lịch sử phiên bản, so sánh và tải lược đồ | M | LGC-HUB-009 | 031 | 031 | — | Có |
| FR-10-021 | Đặt mức tương thích của lược đồ | M | mới | 021 | 021, 036 | — | Có |
| FR-10-022 | Ngừng khuyến nghị và vô hiệu phiên bản lược đồ | S | mới | 032 | 032 | — | Có |
| FR-10-023 | Giám sát tuân thủ lược đồ của bên phát Kafka trực tiếp | S | mới | 055 | 054 | — | Có |
| FR-10-024 | Cung cấp tra cứu lược đồ cho bên ngoài | S | mới | 052 | 034, 052 | 126 | Có |
| FR-10-025 | Liệt kê bên phát và bên nhận | M | LGC-HUB-010, LGC-HUB-011 | 039 | 124 | — | Có |
| FR-10-026 | Đăng ký bên phát | M | LGC-HUB-010 | 037 | 038 | — | Có |
| FR-10-027 | Đăng ký bên nhận | M | LGC-HUB-011 | 037, 086 | 038, 086 | — | Có |
| FR-10-028 | Sửa, tạm ngừng, tiếp tục và ngừng dùng bên phát, bên nhận | M | LGC-HUB-010, LGC-HUB-011 | 040 | 041 | — | Có |
| FR-10-029 | Đồng bộ trạng thái với PH-01 và PH-04 | M | LGC-HUB-010, LGC-HUB-011 | 042, 043 | 043 | 143 | Có |
| FR-10-030 | Đề nghị publication | M | LGC-HUB-012 | 044 | 045 | — | Có |
| FR-10-031 | Duyệt publication, cấp scope OAuth và ACL Kafka | M | LGC-HUB-012 | 044 | 045, 132 | 125, 142 | Có |
| FR-10-032 | Tạm ngừng, tiếp tục và thu hồi publication | M | LGC-HUB-012 | 046, 055 | 046 | 143 | Có |
| FR-10-033 | Phát sự kiện qua API phát | M | LGC-BUS-039 | 047, 050 | 048, 049, 051 | 138, 140, 150, 152 | Có |
| FR-10-034 | Phát sự kiện trực tiếp qua Kafka | M | LGC-TOOL-010 | 053 | 034, 054 | — | Có |
| FR-10-035 | Đề nghị subscription | M | LGC-HUB-013 | 056, 060, 112 | 057, 058, 060, 124, 136 | 137, 156 | Có |
| FR-10-036 | Xác minh endpoint webhook | M | LGC-HUB-013 | 056, 060 | 057, 060 | — | Có |
| FR-10-037 | Duyệt subscription và cấp phát nhóm tiêu thụ | M | LGC-HUB-013 | 056, 060, 082 | 060, 132 | 125, 135, 142, 153, 156 | Có |
| FR-10-038 | Giao nhận ĐẨY: webhook ký HMAC | M | LGC-HUB-013 | 035, 061 | 062, 063, 066, 071, 131 | 139, 141, 150, 152 | Có |
| FR-10-039 | Thử lại giãn dần và chính sách khi thất bại | M | LGC-HUB-013 | 067, 068, 069, 070 | 068, 069 | — | Có |
| FR-10-040 | Điểm bắt đầu và offset bắt đầu | M | LGC-HUB-013 | 059, 096 | 058 | — | Có |
| FR-10-041 | Tạm dừng, tiếp tục subscription | M | LGC-HUB-013 | 069, 072 | 069, 073 | 145 | Có |
| FR-10-042 | Xoay khóa ký webhook | M | mới | 064, 065 | 065 | 135 | Có |
| FR-10-043 | Giao nhận KÉO qua API | M | LGC-HUB-013 | 077, 078, 080 | 079, 081 | 152 | Có |
| FR-10-044 | Giao nhận KÉO qua Kafka listener ngoài | S | LGC-TOOL-010 | 082, 084 | 083, 084 | — | Có |
| FR-10-045 | Giao nhận nội bộ cho luồng và DU | M | LGC-HUB-011 | 087 | 087 | — | Có |
| FR-10-046 | Sửa tham số subscription | M | LGC-HUB-013 | 074 | 074 | — | Có |
| FR-10-047 | Thu hồi subscription | M | LGC-HUB-013 | 075 | 075 | 135 | Có |
| FR-10-048 | Lọc sự kiện và gộp lô khi đẩy | C | LGC-HUB-013 | — | — | — | Có |
| FR-10-049 | Chuyển sự kiện giao thất bại vào DLQ tầng sự kiện | M | mới | 068, 080, 084 | 068, 071, 084 | 150 | Có |
| FR-10-050 | Tra cứu, xem và loại bỏ mục DLQ | M | mới | 089, 090 | 089, 090, 124, 131 | — | Có |
| FR-10-051 | Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian | M | mới | 093, 096 | 094, 095, 132 | — | Có |
| FR-10-052 | Thực thi, theo dõi và hủy lượt phát lại | M | mới | 091, 093, 096, 097 | 097, 124 | 146 | Có |
| FR-10-053 | Phát lại mục DLQ | M | mới | 091, 092 | 092, 131 | — | Có |
| FR-10-054 | Thu thập consumer lag | M | LGC-HUB-007 | 098 | 098 | 144, 147 | Có |
| FR-10-055 | Cảnh báo lag và nhóm tiêu thụ ngừng tiến | M | mới | 099, 100 | 100 | 144 | Có |
| FR-10-056 | Thống kê giao nhận và lượt giao gần đây | M | LGC-HUB-013 | 076 | 076 | — | Có |
| FR-10-057 | Dashboard sự kiện | M | LGC-HUB-001, LGC-HUB-002, LGC-HUB-003… | 102 | 102 | — | Có |
| FR-10-058 | Sơ đồ kết nối tương tác | M | LGC-HUB-007 | 103 | 104 | 148, 157 | Có |
| FR-10-059 | Xuất số liệu sang PH-13 | M | mới | 101 | 101 | — | Có |
| FR-10-060 | Danh mục kiểu giao tiếp | M | LGC-HUB-014 | 105 | 105 | — | Có |
| FR-10-061 | Danh mục chế độ định tuyến | M | LGC-HUB-014 | 105 | 105 | — | Có |
| FR-10-062 | Hạn mức theo tenant và phân bổ cho bên tham gia | M | mới | 106 | 051, 106 | — | Có |
| FR-10-063 | Tham số phân hệ theo tenant | M | mới | 107 | 107 | — | Có |
| FR-10-064 | Cách ly đa tenant trên trục sự kiện | M | mới | 128 | 049, 079, 083, 104, 124 | 123, 125, 126, 127 | Có |
| FR-10-065 | Kiểm toán và lịch sử thay đổi | M | mới | 128, 129, 134 | 130 | — | Có |
| FR-10-066 | Đăng ký topic hộ PH-05 cho CDC | M | LGC-TOOL-010 | 108 | 109, 111, 131 | — | Có |
| FR-10-067 | Đăng ký topic cho DU nội bộ và topic nền tảng | M | LGC-BUS-039 | 112 | 113 | — | Có |
| FR-10-068 | Xử lý thông báo thay đổi lược đồ CDC | M | mới | 110 | 110 | — | Có |
| FR-10-069 | Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trì | M | mới | 085, 086 | 085, 086, 088, 131 | — | Có |
| FR-10-070 | Xuất khai báo | S | mới | 114 | — | 135 | Có |
| FR-10-071 | Nhập khai báo có xem trước | C | mới | 115 | 115 | — | Có |
| FR-10-072 | Nhập kiểm kê Pulsar và lập ánh xạ | M | LGC-HUB-008, LGC-HUB-009, LGC-HUB-010… | 116 | 117 | — | Có |
| FR-10-073 | Cầu nối Pulsar sang Kafka tạm thời | M | mới | 118 | 119 | 149 | Có |
| FR-10-074 | Cầu nối ngược Kafka sang Pulsar cho bên nhận cũ chưa chuyển | S | mới | 120 | 119 | — | Có |
| FR-10-075 | Đối chiếu, chuyển hẳn và quay lui | M | mới | 121 | 121, 132 | 149 | Có |
| FR-10-076 | Báo cáo tiến độ di trú | S | mới | 122 | — | — | Có |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng của Hub Pulsar (`LGC-HUB`), nhóm Message Broker của Tooling (`LGC-TOOL-010`) và event message của Bus (`LGC-BUS-039`) được truy tới FR mới và tới ca tự động, ca nghiệm thu; LGC-HUB-005, 006 chuyển PH-13. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-BUS-039 | 033, 067 | 047, 050, 112 | — |
| LGC-HUB-001 | 057 | 102 | UAT-01 |
| LGC-HUB-002 | 057 | 102 | UAT-01 |
| LGC-HUB-003 | 057 | 102 | UAT-01 |
| LGC-HUB-004 | 057 | 102 | UAT-01 |
| LGC-HUB-005 | — | 102 | UAT-02 |
| LGC-HUB-006 | — | 102 | UAT-02 |
| LGC-HUB-007 | 054, 058 | 098, 103 | UAT-03 |
| LGC-HUB-008 | 001, 002, 003, 004, 005, 072 | 001, 003, 004, 005, 116 | UAT-04, UAT-10 |
| LGC-HUB-009 | 006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 017, 020, 072 | 006, 010, 011, 012, 015, 017, 019, 020 (+9) | UAT-05, UAT-10 |
| LGC-HUB-010 | 025, 026, 028, 029, 072 | 037, 039, 040, 042, 043, 116 | UAT-06, UAT-10 |
| LGC-HUB-011 | 025, 027, 028, 029, 045, 072 | 037, 039, 040, 042, 043, 086, 087, 116 | UAT-06, UAT-10 |
| LGC-HUB-012 | 030, 031, 032, 072 | 044, 046, 055, 116 | UAT-07, UAT-10 |
| LGC-HUB-013 | 035, 036, 037, 038, 039, 040, 041, 043, 046, 047, 048, 056, 072 | 035, 056, 059, 060, 061, 067, 068, 069 (+12) | UAT-08, UAT-10 |
| LGC-HUB-014 | 008, 013, 060, 061, 072 | 006, 011, 020, 047, 105, 116 | UAT-09, UAT-10 |
| LGC-TOOL-010 | 034, 044, 066 | 053, 082, 084, 108 | UAT-10 |

: Chức năng hệ cũ tới FR, ca tự động và UAT

### 8.3. Quy tắc nghiệp vụ → test case

| Mã | Test case |
|---|---|
| BR-10-001 | 049, 123 |
| BR-10-002 | 006, 007, 109 |
| BR-10-003 | 002, 005, 007 |
| BR-10-004 | 006, 012 |
| BR-10-005 | 017, 018 |
| BR-10-006 | 008, 020, 047, 048 |
| BR-10-007 | 047, 051, 150 |
| BR-10-008 | 034, 053, 054 |
| BR-10-009 | 050, 061, 062, 078, 151 |
| BR-10-010 | 013, 030, 094, 132 |
| BR-10-011 | 009, 048 |
| BR-10-012 | 021, 033, 035 |
| BR-10-013 | 024, 025, 034, 036 |
| BR-10-014 | 013 |
| BR-10-015 | 032 |
| BR-10-016 | 022, 023, 045, 049 |
| BR-10-017 | 037, 038, 058 |
| BR-10-018 | 087, 125 |
| BR-10-019 | 045, 058 |
| BR-10-020 | 046, 075 |
| BR-10-021 | 048 |
| BR-10-022 | 059, 087, 125 |
| BR-10-023 | 012, 068 |
| BR-10-024 | 023, 063, 068, 071, 090, 150 |
| BR-10-025 | 058, 067, 074 |
| BR-10-026 | 057, 066 |
| BR-10-027 | 063, 064, 114, 135 |
| BR-10-028 | 091, 092, 094 |
| BR-10-029 | 045, 106 |
| BR-10-030 | 007, 109, 113 |
| BR-10-031 | 108, 112 |
| BR-10-032 | 115, 117 |
| BR-10-033 | 119 |
| BR-10-034 | 117 |
| BR-10-035 | 082, 083, 107 |
| BR-10-036 | 014, 015, 016, 106 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

| Mã | Test case |
|---|---|
| ERR-10-001 | 098, 102, 124 |
| ERR-10-002 | 002, 007, 038, 040, 109 |
| ERR-10-003 | 002, 004, 007, 028, 038, 041, 058, 090, 136 |
| ERR-10-004 | 007, 109, 113 |
| ERR-10-005 | 109, 113, 124 |
| ERR-10-006 | 004, 011, 015, 025, 028, 032, 041, 046, 056, 069 (+5) |
| ERR-10-007 | 004 |
| ERR-10-008 | 013, 030, 045, 060, 094, 132 |
| ERR-10-009 | 005, 013, 019, 023, 032, 041, 065, 073, 075, 089 (+5) |
| ERR-10-010 | 005, 023 |
| ERR-10-011 | 002, 008, 045, 058, 106 |
| ERR-10-012 | 008, 018, 019, 060, 074, 106, 107, 119 |
| ERR-10-013 | 018 |
| ERR-10-014 | 018 |
| ERR-10-015 | 009, 028 |
| ERR-10-016 | 021, 030, 033, 036, 110 |
| ERR-10-017 | 009 |
| ERR-10-018 | 009 |
| ERR-10-019 | 021, 036 |
| ERR-10-020 | 009, 028 |
| ERR-10-021 | 038 |
| ERR-10-022 | 038, 086 |
| ERR-10-023 | 038 |
| ERR-10-024 | 038, 045, 058 |
| ERR-10-025 | 022, 045, 058, 086 |
| ERR-10-026 | 057, 074 |
| ERR-10-027 | 057 |
| ERR-10-028 | 038, 058, 083 |
| ERR-10-029 | 014, 071, 088, 111, 152 |
| ERR-10-030 | 058, 074 |
| ERR-10-031 | 058 |
| ERR-10-032 | 095 |
| ERR-10-033 | 095 |
| ERR-10-034 | 095 |
| ERR-10-035 | 095 |
| ERR-10-036 | 090 |
| ERR-10-037 | 136 |
| ERR-10-038 | 015 |
| ERR-10-039 | 002 |
| ERR-10-040 | 115, 117 |
| ERR-10-041 | 117 |
| ERR-10-042 | 119, 121 |
| ERR-10-043 | 020, 105 |
| ERR-10-044 | 002, 038, 060, 075, 130 |
| ERR-10-045 | 109 |
| ERR-10-046 | 008, 018, 020 |
| ERR-10-047 | 020, 025, 036 |
| ERR-10-048 | 008 |
| ERR-10-049 | 003, 010, 031, 076, 098, 102, 104 |
| ERR-10-050 | 115 |
| ERR-10-051 | 045, 058 |
| ERR-10-052 | 073 |
| ERR-10-053 | 130 |
| ERR-10-054 | 073, 089, 100, 107, 113, 130, 131 |
| ERR-10-101 | 049, 079 |
| ERR-10-102 | 034, 046, 049, 052, 079 |
| ERR-10-103 | 023, 049, 052, 079, 126 |
| ERR-10-104 | 048 |
| ERR-10-105 | 048 |
| ERR-10-106 | 048, 084 |
| ERR-10-107 | 051, 081 |
| ERR-10-108 | 051 |
| ERR-10-109 | 078, 079 |
| ERR-10-110 | 072, 084 |
| ERR-10-111 | 068 |
| ERR-10-112 | 067, 068 |
| ERR-10-113 | 068, 080 |
| ERR-10-114 | 066 |
| ERR-10-115 | 066 |
| ERR-10-116 | 035, 071 |
| ERR-10-117 | 063 |
| ERR-10-118 | 119 |
| ERR-10-119 | 054 |
| ERR-10-120 | 054, 083, 125 |
| ERR-10-121 | 081 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

| Mã | Test case |
|---|---|
| NFR-10-001 | 137 |
| NFR-10-002 | 138 |
| NFR-10-003 | 139 |
| NFR-10-004 | 140 |
| NFR-10-005 | 141 |
| NFR-10-006 | 150 |
| NFR-10-007 | 062, 151 |
| NFR-10-008 | 012, 044, 056, 142 |
| NFR-10-009 | 040, 042, 046, 143 |
| NFR-10-010 | 099, 144 |
| NFR-10-011 | 072, 145 |
| NFR-10-012 | 146 |
| NFR-10-013 | 111, 152 |
| NFR-10-014 | 147 |
| NFR-10-015 | 148 |
| NFR-10-016 | 114, 135 |
| NFR-10-017 | 101, 123, 127 |
| NFR-10-018 | 118, 149 |
| NFR-10-019 | 016, 154 |
| NFR-10-020 | 129, 134 |

: Yêu cầu phi chức năng tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

Chương này cho kỹ sư biết đặt mã kiểm thử ở đâu, mẫu mã cho ba loại ca khó, và chuỗi công cụ sinh ma trận, Gherkin, bảng tính từ chính tài liệu.

### 9.1. Tổ chức mã kiểm thử

| Thư mục | Nội dung |
|---|---|
| `apps/integration/src/test/java/vn/datahub/integration/event/` | UT, IT; lớp cơ sở `EventTestBase` (Testcontainers PostgreSQL 16, Kafka, Apicurio, Keycloak, OpenBao, Valkey) |
| `apps/runtime/src/test/java/vn/datahub/runtime/event/` | RT cho cổng sự kiện, bộ giao nhận, bộ phát lại, cầu nối |
| `apps/console/src/features/event/**/*.test.ts` | UT frontend |
| `e2e/event/ts-10-nn.spec.ts` | Playwright |
| `perf/event/*.js` | k6 |
| `datahub-docs/03-thiet-ke/csdl/ph10/test/` | Bài kiểm cô lập CSDL |
| `datahub-docs/05-kiem-thu/test-case/ph10/gherkin/` | Gherkin sinh từ tài liệu này |

: Thư mục mã kiểm thử của PH-10

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-10-nnn")`, `test('TC-10-nnn …')`).

### 9.2. Mẫu ca xác minh chữ ký webhook (JUnit)

```java
@Tag("hmac")
@Test void webhookSignatureMatchesSpec() {
  var sub = fixtures.pushSubscription("tc-hmac", "https://hooks.sim.test/tc");
  var secret = api.as(U_T68_IE1).post(sub.url() + "/signing-keys:claim").then()
      .statusCode(200).extract().path("secret");
  publisher.publish("t68.dkkd.doanh-nghiep.da-cap-phep.v1", Events.capPhep("0999000001"));
  var req = simWh.awaitRequest(Duration.ofSeconds(5));
  var id = req.header("Webhook-Id"); var ts = req.header("Webhook-Timestamp");
  var expected = Hex.encode(Hmac.sha256(secret, id + "." + ts + "." + req.body()));
  assertThat(req.header("X-Datahub-Signature")).contains("v1=" + expected);
  assertThat(Math.abs(Instant.now().getEpochSecond() - Long.parseLong(ts))).isLessThan(5);
}
```

### 9.3. Mẫu ca cô lập Kafka (tham số hóa)

```java
@ParameterizedTest @Tag("isolation")
@CsvSource({"dh-runtime-t90,t91.dkkd.doanh-nghiep.da-cap-phep.v1,READ",
            "dh-runtime-t90,t91.dkkd.doanh-nghiep.da-cap-phep.v1,WRITE",
            "dh-runtime-t90,dh-sub-t91-ht-thue-dn-cap-phep,GROUP"})
void crossTenantDenied(String principal, String resource, String op) {
  var client = kafka.clientFor(principal);
  assertThatThrownBy(() -> client.attempt(op, resource))
      .isInstanceOfAny(TopicAuthorizationException.class, GroupAuthorizationException.class);
}
```

### 9.4. Mẫu ca đăng ký nhận (Playwright)

```ts
test('đăng ký nhận đẩy có xác minh endpoint', async ({ page }) => {
  await page.goto('/tich-hop/topic/t68.dkkd.doanh-nghiep.da-cap-phep.v1/dang-ky-nhan');
  await page.getByLabel('Bên nhận').fill('tc-ht-thue2');
  await page.getByRole('radio', { name: 'Đẩy (webhook)' }).check();
  await page.getByLabel('Địa chỉ nhận').fill('https://hooks.sim.test/tc');
  await page.getByRole('button', { name: 'Xác minh endpoint' }).click();
  await expect(page.getByRole('status')).toContainText('Xác minh đạt');
  await page.getByRole('button', { name: 'Gửi đề nghị' }).click();
  await expect(page.getByText('Chờ duyệt')).toBeVisible();
});
```

### 9.5. Sinh ma trận, Gherkin, bảng tính

| Lệnh | Kết quả |
|---|---|
| `python3 ph10/tools/number_tcs.py` | Cấp số `TC-10-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph10/tools/fill_doc.py` | Ghi bảng mục 3.1, số kịch bản, số ca và mục 8 (gọi `gen_matrix.py`); in ra stderr BR, ERR, NFR chưa có ca và FR mức M thiếu ca dương hoặc âm |
| `python3 ph10/tools/gen_gherkin.py` | `ph10/gherkin/ts-10-nn.feature`, `uat-tuong-duong-hub.feature` |
| `python3 ph10/tools/gen_xlsx.py` | `ph10/D05-02-PH10-test-case.xlsx` theo mẫu nghiệm thu, có cột Mục đích, Thông báo hiển thị, Hậu điều kiện |
| `python3 ph10/tools/check_refs.py` | Đối chiếu mọi FR, UC, API, UI, ERR, EVT, quyền, enum trong tập với FRS, UC, API, màn hình |

: Chuỗi công cụ sinh phần tự động

`tc_parse.py` đọc được cả khối đặc tả `::: dac-ta` (bản 0.2) lẫn dạng danh sách cũ (bản 0.1), và đọc FRS ở cả dạng bảng "Trường | Nội dung" lẫn khối đặc tả 17 mục, nên chuỗi công cụ không phụ thuộc thứ tự nâng bản của các tập.

## 10. Đề nghị bổ sung cho FRS và câu hỏi mở

Chương này ghi những chỗ tập kiểm thử cần mà nguồn chưa có, để nhóm FRS, API, màn hình đồng bộ ở bản kế tiếp, và các câu hỏi còn mở.

### 10.1. Đề nghị bổ sung cho FRS

| Đề nghị | Lý do |
|---|---|
| Ghi rõ giới hạn kích thước `content` lược đồ (256 KiB) trả ERR-10-015 hay ERR-10-003 | TC TC-10-028 chấp nhận cả hai theo API §3.3; nên chốt một mã |
| Nêu mã lỗi khi người dùng gửi `topicKind = CDC`, `SYSTEM` qua API-10-009 | TC TC-10-007 bước 5 |
| Nêu hành vi khi luồng PH-04 dùng nhóm tiêu thụ khác `dh-flow-{tenant}-{flow}` trong tiền tố tenant (ACL tiền tố cho phép) | TC TC-10-087 bước 2 chỉ kiểm được cảnh báo VR-10 |
| Tham số thời gian thử lại tối thiểu cho môi trường kiểm thử (`10.push.backoff-initial-ms` = 100 đã trong miền) và đồng hồ giả lập cho ca theo ngày | Ca hết hạn yêu cầu, khóa ký, cầu nối cần đặt đồng hồ SIT |

: Đề nghị bổ sung cho FRS

### 10.2. Đề nghị đồng bộ câu thông báo

Các câu dưới đây được dùng ở trường "Thông báo hiển thị" của tập này. Sau đợt đồng bộ ngày 26/11/2026, câu đã thống nhất với D02-03-PH10 FRS §9.2 (nguồn chuẩn câu mới) và D03-06-PH10 §5.3 đã nhận câu ERR-10-053, 054; bảng giữ lại để truy vết đề nghị.

| Mã | HTTP | Câu đề nghị | Đưa vào |
|---|---|---|---|
| ERR-10-053 | 401 | "Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Đăng nhập lại để tiếp tục." | D03-06-PH10 §5.3 |
| ERR-10-054 | 403 | ST-07 "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tenant nếu cần được cấp quyền." | D03-06-PH10 §5.3 |
| ERR-10-101 | 401 | "Token truy cập không hợp lệ hoặc đã hết hạn. Lấy token mới rồi gửi lại." | D03-04-PH10 §6 (`detail`) |
| ERR-10-102 | 403 | "Token chưa có quyền {publish hoặc subscribe} trên topic {tên}, hoặc publication, subscription không ở trạng thái hoạt động." | D03-04-PH10 §6 |
| ERR-10-103 | 404 | "Topic {tên} không tồn tại, không nhận sự kiện ở trạng thái hiện tại hoặc thuộc tenant khác." | D03-04-PH10 §6 |
| ERR-10-104 | 400 | "Sự kiện không đúng CloudEvents 1.0 ({thuộc tính}) hoặc source không thuộc hệ thống của token." | D03-04-PH10 §6 |
| ERR-10-105 | 422 | "Dữ liệu sự kiện không khớp lược đồ phiên bản {n} ở trường {đường dẫn}, hoặc thiếu khóa phân vùng bắt buộc." | D03-04-PH10 §6 |
| ERR-10-106 | 413 | "Sự kiện hoặc lô vượt kích thước cho phép ({giới hạn})." | D03-04-PH10 §6 |
| ERR-10-107 | 429 | "Vượt hạn mức phát hoặc kéo. Thử lại sau {Retry-After} giây." | D03-04-PH10 §6 |
| ERR-10-108 | 503 | "Cụm sự kiện tạm thời không đủ bản sao để ghi an toàn; sự kiện chưa được nhận. Thử lại sau." | D03-04-PH10 §6 |
| ERR-10-109 | 409 | "Con trỏ xác nhận đã hết hiệu lực hoặc không khớp lượt kéo hiện tại. Kéo lại rồi xác nhận." | D03-04-PH10 §6 |
| ERR-10-110 | 409 | "Đăng ký nhận {mã} đang không hoạt động ({trạng thái}); chưa kéo được sự kiện." | D03-04-PH10 §6 |
| ERR-10-121 | 503 | "Dịch vụ phụ trợ của cổng sự kiện ({tên}) tạm thời không khả dụng. Thử lại sau {Retry-After} giây." | D03-04-PH10 §6 |

: Câu thông báo đề nghị đồng bộ cho mã lỗi chưa có câu

### 10.3. Câu hỏi mở

> **Câu hỏi mở Q10-40:** Bộ rò rỉ đầu cuối T90…T99 chạy mỗi đêm trên SIT dùng chung cụm Kafka với tenant khác; có cần cụm Kafka riêng cho kiểm thử cô lập để tránh ảnh hưởng hạn mức của T68 không?

> **Câu hỏi mở Q10-41:** Ca NFR-10-006 cần 1 triệu sự kiện qua API phát và chaos broker; môi trường PERF có được phép giết broker ở giờ hành chính không, hay chỉ chạy đêm?

> **Câu hỏi mở Q10-42:** Mã mẫu xác minh chữ ký cho PHP và .NET (TC TC-10-062) do nhóm Datahub bảo trì hay chỉ là tài liệu tham khảo; nếu bảo trì thì ca thuộc CI của dự án nào?

> **Câu hỏi mở Q10-43:** UAT di trú cần bản xuất CSDL cấu hình Hub cũ thật của tỉnh thí điểm; ai cung cấp và quy trình làm sạch mật khẩu nhúng trong URI subscription trước khi đưa vào UAT?

> **Câu hỏi mở Q10-44:** Ngưỡng NFR-10-007 (≤ 0,1 % giao trùng) đo trong 24 giờ tải nền; có cần đo thêm khi tái cân bằng do KEDA đổi số bản sao bộ giao nhận không?

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm tài liệu | Bản đầu theo FRS 0.2 (và mã control plane ERR-10-053, 054, API-10-121 của FRS 0.3): 35 kịch bản, 10 UAT, ma trận sinh tự động, Gherkin, bảng tính; câu hỏi mở Q10-40…44 |
| 0.2 | 26/11/2026 | Nhóm tài liệu | Theo chuẩn kết hợp K-TC, K-TRINH-BAY: giữ nguyên mọi bước, dữ liệu, kết quả mong đợi của 158 ca; chuyển mỗi ca sang khối đặc tả `::: dac-ta`, thêm Mục đích, Thông báo hiển thị (theo D03-06-PH10 §5.3, §18.4), Hậu điều kiện; tách 13 ca hiệu năng thành khối riêng kèm bảng tóm tắt ngưỡng; Giới thiệu đủ 0.1…0.6, đoạn mở chương, chú thích bảng; mục 10.2 đề nghị đồng bộ câu thông báo cho ERR-10-053, 054, 101…110, 121; vá `tc_parse.py` đọc khối mới, `gen_xlsx.py`, `gen_gherkin.py` thêm trường mới |
| 0.3 | 27/11/2026 | Nhóm tài liệu | Đồng bộ chéo cuối: topic cấp nền tảng `platform.tenant.created.v1` thay `dh.platform.tenant.created.v1` (QĐ-2) ở TC-10-113; thêm miền dành riêng `mdm`, `dq`, `bpm`, `kpi`, `portal` ở TC-10-007; ERR-10-003 cho `topicKind` khác `BUSINESS` và `content` vượt 256 KiB; SIM-PH01 dùng EVT-01-03 |
