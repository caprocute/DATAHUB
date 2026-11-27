---
ma_tai_lieu: D05-02-PH18
ten: Kịch bản và test case phân hệ PH-18 Vận hành và xử lý lỗi
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-18
mo_ta: Kịch bản và test case chức năng, bốn mắt, lũy đẳng phát lại, cô lập tenant, chịu lỗi khi phân hệ phụ thuộc vắng, khôi phục tenant, di trú và cắt chuyển, hiệu năng, truy cập và nghiệm thu của phân hệ Vận hành và xử lý lỗi, mỗi ca một khối đặc tả, kèm ma trận truy vết, Gherkin và bảng tính sinh tự động.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH18 FRS; D02-04-PH18 Use case; D03-02-PH18 SDD; D03-03-PH18 CSDL; D03-04-PH18 API; D03-06-PH18 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH18 · Kịch bản và test case Vận hành và xử lý lỗi

## Tóm tắt cho hội đồng thẩm định

Phần này viết cho hội đồng thẩm định: tài liệu chứng minh điều gì, phủ đến đâu và nhóm ca nào bắt buộc đạt trước khi phát hành. Số kịch bản, số ca do công cụ sinh lại từ chính các ca nên luôn khớp với chương 4 và 5.

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-18 làm đúng mọi yêu cầu đã chốt ở D02-03-PH18 bản 0.1: 72 FR, 50 quy tắc BR-18, 22 yêu cầu phi chức năng, 96 mã lỗi (ERR-18-001…072 và 101…124), 180 API, 29 sự kiện phát ra, 24 màn hình.
- Bản tin lỗi không mất và không bị xử lý trùng: PH-18 chỉ commit offset sau khi chỉ mục bền, khử trùng theo `dlqKey`, phát lại luôn đi qua cổng của nguồn với khóa `dlqId:revision`, kết quả đến muộn chỉ ghi một lần; PH-18 vắng thì phân hệ khác vẫn chạy bằng bộ đệm và bản tin dồn ở Kafka.
- Mọi thao tác rủi ro có người thứ hai: tham số ★, gói tham số, bản sửa payload chạm dữ liệu Hạn chế, lượt phát lại lớn, mẫu thông báo, khôi phục tenant, chạy di trú thật, cắt chuyển; người đề nghị không bao giờ tự duyệt được; mọi thao tác ghi có kiểm toán ở PH-13 trước khi có hiệu lực.
- Không có dữ liệu của tenant khác ở API, CSDL, Kafka hay tác vụ nặng; payload chỉ xem được khi có quyền, lý do và kiểm toán; thông báo không mang dữ liệu Hạn chế; di trú không chuyển thông tin xác thực.

**Phạm vi.** Gồm <!--gen:so-ts-->46<!--/gen--> kịch bản (TS-18-01…40 ứng một một với UC-18-01…40 theo đề nghị ĐN-UC-15 của D02-04-PH18, TS-18-41…46 cho các tính chất xuyên suốt) với <!--gen:so-tc-->171 (TC-18-001…171; 123 ca P1)<!--/gen--> test case và 8 kịch bản nghiệm thu người dùng (UAT-18-01…08). Mọi FR có ít nhất một ca dương và một ca âm, mọi mã lỗi ERR-18 nêu ở FR có ca, mọi BR-18, NFR-18, sự kiện EVT-18 và màn hình UI-18 có ca. Ma trận ở chương 8 sinh bằng `ph18/tools/gen_matrix.py`.

**Căn cứ.** FRS D02-03-PH18, use case D02-04-PH18 (bảng use case và FR, luồng phụ LP-18-01…06), màn hình D03-06-PH18 (ma trận màn, FR và API ở chương 33), CSDL D03-03-PH18 cùng bộ kiểm cô lập `03-thiet-ke/csdl/ph18/test/ph18_isolation_test.sql`, API D03-04-PH18 và `openapi-ops.yaml`, ma trận phân quyền D02-08; ADR-180…184; kế hoạch kiểm thử D05-01 (cổng `RG-1…5`); Luật Bảo vệ dữ liệu cá nhân 91/2025, Nghị định 356/2025/NĐ-CP, Luật Dữ liệu 60/2024, TCVN 14423:2026 (mức sàn an ninh của trần tham số); cấu trúc theo ISO/IEC/IEEE 29119-3.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- không mất, không trùng bản tin lỗi khi giết bản sao, ngắt CSDL, ngắt Garage và khi PH-18 tắt 30 phút (TS-18-09, 40, 43);
- lũy đẳng phát lại: gọi lại cùng khóa, callback lặp, kết quả đến muộn (TS-18-16, 17);
- bốn mắt ở tám loại đối tượng, người đề nghị tự duyệt luôn bị từ chối (TS-18-42 và các kịch bản UC tương ứng);
- khôi phục tenant: lỗi ở bước 3 không đổi dữ liệu, lỗi ở bước 5 quay lui, số dòng lệch giữ tenant tạm ngừng, kiểm toán không bị khôi phục, tenant khác không bị chạm (TS-18-31, 41);
- cắt chuyển chỉ khi danh sách kiểm tra đạt, quay lui ở phút 14 được và ở phút 16 bị từ chối (TS-18-38);
- cô lập tenant ở API, CSDL, Kafka và trong Job của `dh-batch` (TS-18-41).

Mã nguồn `vn.datahub.platform.ops` và ảnh `dh-ops-worker` chưa có; các ca là tiêu chí nghiệm thu của công việc mới ở mốc W2. Tên trường JSON trong ca theo `openapi-ops.yaml` đang viết song song; chỗ chưa chốt ghi giả định và câu hỏi Q18-41.

## 0. Giới thiệu

Chương này nêu mục đích, người đọc, thuật ngữ, cấu trúc và tài liệu tham chiếu của tập kiểm thử.

### 0.1. Mục đích

Đặc tả kịch bản và test case của PH-18 để nghiệm thu chức năng kho tham số, tiếp nhận và xử lý DLQ, phát lại, thông báo, Việc của tôi, lịch, sự cố, sao lưu và khôi phục, di trú hệ cũ và cắt chuyển, cùng các tính chất bốn mắt, lũy đẳng, cô lập tenant, chịu lỗi, hiệu năng, truy cập và tương đương hệ cũ.

### 0.2. Người đọc

Kiểm thử viên chạy ca; kỹ sư `dh-platform`, `dh-ops-worker`, `dh-console` đối chiếu hành vi; cán bộ ATTT và SO kiểm các ca bảo mật và bốn mắt ở TS-18-41, 42; quản trị nền tảng dùng TS-18-31, 38 làm kịch bản diễn tập; chủ đầu tư dùng chương 7 và mục 9.2 để nghiệm thu.

### 0.3. Thuật ngữ

TS kịch bản; TC test case; UAT nghiệm thu người dùng; DLQ hàng bản tin lỗi (dead letter queue); payload nội dung bản tin; phát lại (replay) gửi lại bản tin qua lối vào của nguồn; lũy đẳng (idempotent) gọi lại nhiều lần cho cùng kết quả như một lần; bốn mắt nguyên tắc người duyệt khác người đề nghị; PITR khôi phục về một thời điểm (point-in-time recovery); chạy bóng (shadow) nhân bản lưu lượng sang hệ mới để so kết quả; cắt chuyển (cutover) chuyển lưu lượng của nhóm dịch vụ sang Datahub; DLCN dữ liệu cá nhân; MOCK-SMTP, MOCK-SMS máy chủ thư và cổng SMS giả lập; đồng hồ giả đồng hồ hệ thống điều khiển được của tenant T95. Vai trò viết tắt theo D02-08: PA, PO, TA, TO, SO, IE, DS, AU, VW.

### 0.4. Cấu trúc tài liệu

Chương 1 chiến lược; 2 dữ liệu; 3 danh sách kịch bản; 4 ca chức năng (TS-18-01…40 ứng một một với UC-18-01…40); 5 ca phi chức năng và xuyên suốt (TS-18-41…46); 6 thủ tục thủ công; 7 nghiệm thu; 8 ma trận truy vết; 9 tự động hóa và tiêu chí chấp nhận; 10 đề nghị đồng bộ và câu hỏi mở.

### 0.5. Tài liệu tham chiếu

D05-01 kế hoạch kiểm thử; D02-03-PH18 (mã FR, BR, NFR, ERR, EVT, API, UI, trạng thái, tham số `18.*`, tiêu chí AC-18-01…13); D02-04-PH18 (UC, LP-18-01…06, ĐN-UC-15); D03-06-PH18 (màn hình, chương 33); D03-03-PH18 và `csdl/ph18/` (DDL, bộ kiểm cô lập); D03-04-PH18 và `api/ph18/openapi-ops.yaml`, `asyncapi-ops.yaml`; D02-08 (ma trận quyền); D03-09 §8 (sao lưu, RBK-04); mẫu cùng loại D05-02-PH17.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

Chương này xác định đối tượng kiểm thử, các mức kiểm thử, môi trường, tiêu chí vào ra và quy ước trình bày ca. Chiến lược chung theo D05-01; mục 1.6 nêu các nguyên tắc riêng của phân hệ vận hành.

### 1.1. Đối tượng kiểm thử

Đối tượng là mô-đun `vn.datahub.platform.ops` của DU `dh-platform` (Spring Boot 4, Spring Modulith, 3 bản sao) gồm REST `/api/ops/v1` qua APISIX, API nội bộ `/ops/internal/v1` (mTLS, SPIFFE, scope máy `ops:*`), schema `ph18_ops` của cụm `pg-core` (RLS theo `tenant_id`, vai `ph18_app`, `ph18_readonly`, `ph18_worker`), bucket Garage `dh-{tenant}-ops`, 180 API (API-18-001…180), 29 topic `{tenant}.ops.*.v1` (EVT-18-01…29) và topic DLQ chung `{tenant}.ops.dlq.v1`, các Job `dh-tenant-restore`, `dh-tenant-export`, `dh-migrate` trong namespace `dh-batch`, và 24 màn hình (UI-18-01…24). Ngoài phạm vi: thử lại, circuit breaker, `errorHandler` của PH-04; DLQ tầng sự kiện và duyệt phát lại sự kiện của PH-10; luật cảnh báo, lịch trực, kiểm toán WORM của PH-13; khởi tạo, tạm ngừng, sáp nhập tenant của PH-20; đồng hồ 72 giờ của PH-09; nội dung xử lý của phân hệ đích khi nhận lô di trú. Các phân hệ này được giả lập ở chỗ gọi; ca của chúng thuộc tập của phân hệ đó.

### 1.2. Mức kiểm thử

Ký hiệu mức ghi ở trường "Tự động" của từng ca.

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, Vitest | Kiểm miền và trần tham số, tính `dlqKey`, kiểm trường cấm của mẫu Mustache, tính ngày làm việc |
| Tích hợp | IT | Testcontainers (PostgreSQL 16, Kafka KRaft, Garage, Keycloak, OpenBao dev, WireMock cho PH-01, 02, 04, 07, 09, 10, 12, 13, 17, 19, 20), MOCK-SMTP, MOCK-SMS | Dịch vụ với CSDL, outbox, inbox, consumer DLQ, cổng phát lại |
| CSDL | DB | `psql` với `03-thiet-ke/csdl/ph18/test/ph18_isolation_test.sql` | RLS, ràng buộc, bảng chỉ thêm, máy trạng thái, vai |
| Job | JOB | pytest, Job K8s trên kind | Khôi phục tám bước, xuất tenant, di trú, chuyển sáp nhập, tác vụ dọn và nhắc |
| Hợp đồng | CT | Spectral, oasdiff | `openapi-ops.yaml`, `asyncapi-ops.yaml` |
| API | API | REST Assured | Mọi API-18 |
| Kafka | KT | `kcat`, client OAUTHBEARER | ACL theo tiền tố tenant, nội dung sự kiện |
| Đầu cuối | E2E | Playwright, axe-core | UI-18-01…24 |
| Hiệu năng | k6 | k6, đồng hồ Job | NFR-18-001, 003…011, 013, 016, 022 |
| Chịu lỗi | Chaos | Chaos Mesh, `kubectl delete pod` | PH-13, PH-10, PH-04, PH-09, PH-20, CSDL, Garage, `dh-platform` |

: Mức kiểm thử, ký hiệu, công cụ và phạm vi

### 1.3. Môi trường kiểm thử

Ba môi trường phục vụ các mức ở mục 1.2.

| Môi trường | Dùng cho | Cấu hình |
|---|---|---|
| TEST | UT, IT, DB, CT, API, KT | `dh-platform` 1 bản sao; phân hệ phụ thuộc là WireMock; Kafka, Garage, Keycloak, OpenBao dev thật; MOCK-SMTP, MOCK-SMS; đồng hồ giả cho T95 |
| STAGING | E2E, Chaos, JOB khôi phục và sáp nhập, UAT dợt ở `T68` | Giống sản xuất về số bản sao, namespace `dh-batch`, chính sách mạng; CNPG có cửa sổ PITR 30 ngày |
| PERF | k6, JOB quy mô | `dh-platform` 3 bản sao, Kafka 3 broker; `pg-core` 8 vCPU, 32 GB; tenant T97…T99 theo mục 2.1 |

: Môi trường kiểm thử

### 1.4. Tiêu chí vào, ra và cổng phát hành

Tiêu chí vào và ra bám các cổng `RG-1…5` của D05-01.

- **Vào.** `openapi-ops.yaml`, `asyncapi-ops.yaml` và DDL `ph18_ops.sql` đã gắn phiên bản; bộ kiểm `ph18_isolation_test.sql` chạy đạt; dữ liệu mục 2 nạp được bằng `ph18/seed/` qua API (trừ ca DB và ca tiêm lỗi CSDL); WireMock của các phân hệ phụ thuộc có kịch bản theo bảng 2.3.
- **Ra.** `RG-1` mọi ca API, DB và rò rỉ chéo tenant đạt; `RG-2` toàn bộ hồi quy đạt, 0 lỗi S1, S2 mở; `RG-3` 100 % ca P1 đã chạy, ≥ 98 % đạt, đo xong NFR-18-001…022 ở PERF; `RG-4` UAT chương 7 ký và 13 tiêu chí AC-18-01…13 ở FRS §14 đạt (đối chiếu ở mục 9.2). Một ca bốn mắt có đường vòng, một bản tin mất hoặc một dòng của tenant khác lộ ra là lỗi S1 và chặn phát hành.

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-18-nn`, test case `TC-18-nnn`; mã không tái sử dụng, ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi ca là khối `::: dac-ta`, tiêu đề `#### TC-18-nnn · Tên ca <!--k:khóa-->`; khóa dùng cho `number_tcs.py` và tham chiếu `[[tc:khóa]]`, không in ra bản xuất. Đường dẫn trong bước tương đối với `/api/ops/v1`; API nội bộ ghi đủ `/ops/internal/v1/...`. Khóa tham số của phân hệ khác (ví dụ `04.retry.max-attempts`, `02.review.sla-days`) và tên trường JSON không có trong FRS là giả định, đối chiếu lại khi `openapi-ops.yaml` chốt (Q18-41).

| Trường | Nội dung |
|---|---|
| **Mục đích.** | Ca chứng minh điều gì, theo FR, BR hoặc NFR chính |
| **Loại.** | Dương, Âm, Biên, Bảo mật, Lũy đẳng, Hiệu năng, Chịu lỗi, Truy cập |
| **Ưu tiên.** | P1 chặn phát hành, P2 quan trọng, P3 bổ sung (FR mức C) |
| **Tự động.** | Mức ở mục 1.2 hoặc "Thủ công" |
| **Truy vết.** | FR, BR, API, UI, ERR, EVT, NFR, LGC, ngăn bằng dấu `·` |
| **Tiền điều kiện, dữ liệu.** | Trạng thái trước khi chạy và mã dữ liệu ở chương 2 |
| **Các bước.** | Danh sách đánh số |
| **Kết quả mong đợi.** | Mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán |
| **Thông báo hiển thị.** | Câu người dùng nhìn thấy theo FRS §9.1, chỉ ở ca có mã lỗi ERR-18; mã 101…124 hiện ở màn vận hành |

: Các trường của khối đặc tả test case

Lỗi thiếu quyền, chưa xác thực và thiếu `If-Match` dùng mã nền ERR-00-403, ERR-00-401, ERR-00-428. Trong kết quả mong đợi dùng các ký hiệu sau.

| Ký hiệu | Nghĩa |
|---|---|
| ERR-00-403 | `403` do thiếu quyền `PERM-18-*` hoặc scope máy; thân RFC 9457 có `code`, `traceId` |
| ERR-00-401, 428 | `401` thiếu hoặc sai token; `428` thiếu `If-Match` ở thao tác ghi |
| 404-ẩn | `404` ERR-18-001; thân giống hệt "không tồn tại" và "thuộc tenant khác" trừ `traceId` |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường theo FR-00-041, ghi trước khi thao tác có hiệu lực (trừ hủy, tạm dừng, quay lui khẩn theo BR-18-046) |
| EVT-18-nn | Đúng một bản tin trên topic `t90.ops.{tên}.v1` (tenant theo ca), chỉ mang mã, trạng thái, số đếm, thời điểm |
| Mồi sạch | Chuỗi `DH-CANARY-18` đặt trong payload mẫu không xuất hiện ở sự kiện, log, báo cáo, sổ tay, thư |

: Ký hiệu viết tắt trong kết quả mong đợi

### 1.6. Chiến lược riêng cho kiểm thử vận hành

Bốn nguyên tắc chi phối các ca của tập này.

1. **Lũy đẳng kiểm bằng đếm ở phía nguồn.** Mọi ca phát lại, gửi thông báo, tạo việc, di trú, chuyển sáp nhập đếm số lần xử lý ở WireMock của phía nhận, không chỉ đọc trạng thái trong PH-18; gọi lại cùng khóa phải cho số đếm không đổi.
2. **Bốn mắt kiểm bằng người có đủ quyền.** Người đề nghị trong ca âm luôn được cấp cả `PERM-18-approve` để chứng minh chặn là do tách nhiệm vụ chứ không do thiếu quyền; mỗi use case thuộc LP-18-01 có một ca người duyệt trùng người đề nghị.
3. **Thời gian dùng đồng hồ giả, chỉ tiêu giây dùng đồng hồ thật.** Hạn 72 giờ, 90 ngày, 7 ngày, cửa sổ quay lui 15 phút dùng đồng hồ giả của T95; lan truyền tham số ≤ 60 giây, sự kiện ≤ 5 giây, thông báo, khôi phục ≤ 4 giờ đo trên đồng hồ thật ở PERF hoặc STAGING.
4. **Phụ thuộc mềm kiểm ở cả hai phía.** Khi PH-13, PH-10, PH-04, PH-09, PH-20 vắng, ca kiểm phần PH-18 vẫn phục vụ được, phần phải từ chối (kiểm toán chưa ghi, dữ liệu chưa phân loại) và việc không có xử lý trùng khi phân hệ trở lại; khi PH-18 vắng, ca kiểm phân hệ khác không lỗi.

### 1.7. Quản lý lỗi và báo cáo

Lỗi ghi theo mức S1…S4 của D05-01; kết quả ghi ở cột "Kết quả" của `.xlsx`. Lỗi ở ca P1 chặn phát hành; lỗi S1, S2 sửa xong phải có thêm ca hồi quy tự động trong bộ IT hoặc DB.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập: tên là nhân vật hư cấu, số định danh ở dải giả không do cơ quan nào cấp, địa chỉ thư thuộc miền thử `example.vn`. Bí mật chỉ là tham chiếu OpenBao dạng `kv/dh/{tenant}/...` không có giá trị trong tài liệu, dữ liệu mẫu hay log. Nạp bằng `ph18/seed/` qua API, trừ khối CSDL.

### 2.1. Tenant

Tenant kiểm thử dùng dải `T90…T99`; `T68` dành cho UAT dợt và ca liên môi trường ở STAGING; không dùng tenant sản xuất.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T90` | Tenant chính | Tham số mặc định theo FRS §8.2; nguồn `SRC-PH04`, `SRC-PH19`, `SRC-PH08-DQ`; `DLQ-SET-A`; mẫu, lịch, sự cố mẫu |
| `T91` | Đối chứng rò rỉ | Cùng mã đối tượng, mã nguồn, mã mẫu, khóa tham số với T90; cùng ô `pg-core` với T90 ở STAGING |
| `T92` | Tham số nhỏ | `18.dlq.replay.batch-max = 100`, `18.dlq.threshold.depth = 50`, `18.egress.max-entries = 3`, trần `04.retry.max-attempts = 5` |
| `T93` | Mới | Chưa có giá trị tham số, dùng cho khởi tạo và xuất khi `DECOMMISSIONED` |
| `T94` | Chịu lỗi | Cho Chaos: ngắt PH-13, PH-10, PH-04, PH-09, PH-20, CSDL, Garage |
| `T95` | Đồng hồ | Đồng hồ giả: hạn đề nghị 72 giờ, lưu giữ 90 ngày, chạy thử 7 ngày, cửa sổ quay lui 15 phút, giờ yên lặng, nhắc việc |
| `T96` | Di trú | Nguồn giả lập `LEG-AITA`, `LEG-RW`, `LEG-DOWN`; kế hoạch `PLAN-AITA`; nhóm song song `PG-THUE`, `PG-DAT`, `PG-HT`, `PG-THUE2` |
| `T97`…`T99` | Hiệu năng | T97 1 triệu mục DLQ; T98 hồ sơ `QM-VUA` 200 GB cho khôi phục, xuất, sáp nhập; T99 10.000 thông báo mỗi giờ và 500.000 bản ghi di trú |

: Tenant kiểm thử

### 2.2. Người dùng và tài khoản máy

Người dùng mang tên nhân vật hư cấu, vai trò theo D02-08; mỗi vai có một tài khoản `U-{tenant}-{vai}`.

| Mã | Tenant | Vai trò | Ghi chú |
|---|---|---|---|
| U-PA1, U-PA2 | PLATFORM | PA | Hai quản trị nền tảng khác nhau, có `PERM-18-admin`, `PERM-18-approve`, `PERM-18-backup`, `PERM-18-calendar` |
| U-PO1 | PLATFORM | PO | `PERM-18-read`, `PERM-18-dlq` ở chế độ nền tảng, `PERM-18-backup` |
| U-T90-TA1, TA2 | T90 | TA | `PERM-18-config`, `-template`, `-calendar`, `-backup`, `-migration`, `-approve`; hai người khác nhau để kiểm bốn mắt; TA1 có cả quyền đề nghị và duyệt |
| U-T90-TO | T90 | TO | `PERM-18-dlq`, `-dlq-payload`, `-incident`; ở ca bốn mắt được cấp thêm `-approve` |
| U-T90-SO | T90 | SO | `PERM-18-dlq-payload`, `-approve`, `-incident` |
| U-T90-IE | T90 | IE | `PERM-18-dlq-payload` (sửa payload); ở ca tách nhiệm vụ được cấp thêm `-approve` |
| U-T90-DS, AU, VW | T90 | DS, AU, VW | DS sửa dữ liệu di trú lỗi; AU chỉ đọc nhật ký và báo cáo; VW chỉ thống kê và sức khỏe |
| U-T91-TA, TO | T91 | TA, TO | Đối chứng chéo tenant, vai mạnh nhất tenant |
| U-T9x-{vai} | T92…T96 | Theo ca | Tài khoản cùng vai của tenant khác, quyền như T90 |
| S-PH02, S-PH04, S-PH13, S-PH17, S-PH19, S-PH20, S-PH01 | T90 | Tài khoản máy | mTLS SPIFFE; scope theo FRS §3.3 (`ops:param-register`, `ops:dlq-write`, `ops:replay-callback`, `ops:notify`, `ops:task`, `ops:incident-write`, `ops:dlq-read`, `ops:param-write`, `ops:merge-transfer`) |
| S-BACKUP, S-SHADOW | T90, T96 | Tài khoản máy | `ops:backup-report`, `ops:shadow-ingest` |
| S-NOSCOPE, S-T91-PH04, S-T91-PH19 | T90, T91 | Tài khoản máy | Không scope; scope của tenant đối chứng |

: Người dùng và tài khoản máy

### 2.3. Bộ dữ liệu và hệ thống giả lập

Bộ dữ liệu có tên, sinh bằng hạt cố định để chạy lại được.

| Mã | Nội dung | Tenant |
|---|---|---|
| `DLQ-SET-A` | 200 mục DLQ của 5 nguồn, 4 lớp lỗi, 6 trạng thái, tuổi 1 giờ đến 40 ngày; mục có tên `DLQ-A-01…12` dùng trong ca | T90, T91 |
| `DLQ-POISON` | 5 bản tin thiếu header, tenant lệch topic, thân không giải mã được | T90 |
| `DLQ-BIG` | Payload 100 KB và 300 KB, có chuỗi mồi `DH-CANARY-18` | T90 |
| `DLQ-PH19-500` | Lô 500 mục của PH-19, 2 mục trùng `dlqKey`, 3 mục 300 KB | T90 |
| `DLQ-SET-PERF` | 1 triệu mục tồn và 100.000 bản tin nạp, 5 % lớn hơn 256 KB | T97 |
| `SCH-02-V1`, `SCH-02-V2` | Lược đồ không gian tên `02.` (6 khóa, một khóa ★) và bản thu miền | T90, T91 |
| `TPL-ONB-MAIL`, `TPL-API-DUYET`, `TPL-NHAC`, `TPL-BAO-TRI`, `TPL-DRAFT`, `TPL-OLD` | Mẫu thông báo thư, nhắc, bảo trì (bắt buộc), nháp, đã ngừng | T90, T93 |
| `CAL-2027` | Lịch năm 2027 giả định có nghỉ Tết và ngày làm bù | T90, COMMON |
| `LEG-AITA` | PostgreSQL giả lập hệ cũ: 12.000 danh mục, 180 HTTT, 900 API, 40 khóa API consumer, 12 chứng thư (giả định theo GĐ-01) | T96 |
| WireMock PH-01, 02, 04, 07, 09, 10, 12, 13, 17, 19, 20 | Kịch bản trả lời, đếm lời gọi, tiêm lỗi `503`, trễ | Mọi tenant |
| MOCK-SMTP, MOCK-SMS | Nhận thư, SMS; báo trả lại `HARD`, `SOFT`; tiêm lỗi `451`, `503` | Mọi tenant |

: Bộ dữ liệu và hệ thống giả lập

### 2.4. Nguyên tắc dữ liệu

Payload mẫu không chứa DLCN thật; số CCCD mẫu đặt trong nháy và thuộc dải giả. Mỗi ca tự tạo dữ liệu riêng hoặc dùng bản sao của bộ có tên để chạy song song được; ca CSDL chạy trên CSDL rỗng. Sau mỗi lần chạy hồi quy, tác vụ dọn của môi trường TEST xóa mọi đối tượng Garage của bucket `dh-t9x-ops`.

## 3. Tổng quan kịch bản kiểm thử

Bảng 3.1 do `fill_doc.py` sinh lại từ chương 4 và 5; mục tiêu đầy đủ ở đầu mỗi kịch bản. Chuyển trạng thái hợp lệ và bị cấm của từng đối tượng được kiểm theo máy trạng thái ở FRS chương 4 (mục DLQ `NEW → TRIAGED → REPLAY_PENDING → REPLAYING → RESOLVED`, lượt phát lại `DRAFT → PENDING_APPROVAL → APPROVED → RUNNING`, khôi phục tenant `DRAFT → PENDING_APPROVAL → APPROVED → RUNNING → SUCCEEDED | FAILED | ROLLED_BACK`, cắt chuyển `PARALLEL → SHADOW_OK → PARTIAL_CUTOVER → CUT_OVER | ROLLED_BACK`) và bằng bộ kiểm CSDL, không lặp lại ở đây.

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | UC | Số ca |
|---|---|---|---|
| TS-18-01 | Đăng ký lược đồ tham số và đọc tham số có bộ đệm | UC-18-01 | 5 |
| TS-18-02 | Sửa giá trị tham số trên màn tham số chung | UC-18-02 | 4 |
| TS-18-03 | Đề nghị và duyệt bốn mắt tham số bảo mật ★ | UC-18-03 | 4 |
| TS-18-04 | Xem lịch sử, so sánh và khôi phục phiên bản tham số | UC-18-04 | 2 |
| TS-18-05 | Xuất, nhập gói tham số giữa môi trường | UC-18-05 | 2 |
| TS-18-06 | Quản lý cờ tính năng và danh sách egress cho phép | UC-18-06 | 4 |
| TS-18-07 | Ghi tham số mặc định khi khởi tạo tenant | UC-18-07 | 2 |
| TS-18-08 | Đăng ký nguồn DLQ và cổng phát lại | UC-18-08 | 2 |
| TS-18-09 | Tiếp nhận bản tin lỗi từ topic, kiểm ngữ cảnh và đối soát với Kafka | UC-18-09 | 5 |
| TS-18-10 | Phân hệ ghi mục DLQ qua API | UC-18-10 | 3 |
| TS-18-11 | Xem và đề nghị phát lại DLQ tầng sự kiện của PH-10 | UC-18-11 | 2 |
| TS-18-12 | Lọc, gom nhóm, phân loại và gán người xử lý mục DLQ | UC-18-12 | 4 |
| TS-18-13 | Xem chi tiết, ngữ cảnh chẩn đoán và nội dung mục DLQ có lý do | UC-18-13 | 4 |
| TS-18-14 | Sửa payload có kiểm soát và duyệt bốn mắt | UC-18-14 | 4 |
| TS-18-15 | Biên soạn sổ tay xử lý theo mã lỗi và cấp API đọc cho PH-17 | UC-18-15 | 4 |
| TS-18-16 | Phát lại một mục DLQ và nhận kết quả lũy đẳng | UC-18-16 | 6 |
| TS-18-17 | Phát lại loạt có duyệt bốn mắt và điều khiển lượt | UC-18-17 | 5 |
| TS-18-18 | Bỏ qua và mở lại mục DLQ | UC-18-18 | 3 |
| TS-18-19 | Lưu giữ, dọn, thống kê DLQ và phát sự kiện vượt ngưỡng | UC-18-19 | 3 |
| TS-18-20 | Soạn, kiểm trường cấm và duyệt mẫu thông báo | UC-18-20 | 3 |
| TS-18-21 | Phân hệ gửi thông báo và phân giải người nhận | UC-18-21 | 5 |
| TS-18-22 | Đặt tùy chọn nhận, giờ yên lặng và đọc thông báo trong ứng dụng | UC-18-22 | 2 |
| TS-18-23 | Cấu hình quy tắc thông báo theo sự kiện | UC-18-23 | 2 |
| TS-18-24 | Xử lý thư trả lại, danh sách chặn và tra nhật ký gửi | UC-18-24 | 3 |
| TS-18-25 | Phân hệ đăng ký loại việc, tạo và đóng việc lũy đẳng | UC-18-25 | 3 |
| TS-18-26 | Xử lý Việc của tôi, nhắc và quá hạn | UC-18-26 | 4 |
| TS-18-27 | Quản lý lịch ngày làm việc, cửa sổ bảo trì và đóng băng | UC-18-27 | 4 |
| TS-18-28 | Mở, xử lý và đóng sự cố vận hành | UC-18-28 | 4 |
| TS-18-29 | Chuyển sự cố có dữ liệu cá nhân sang PH-09 | UC-18-29 | 2 |
| TS-18-30 | Theo dõi sao lưu, kiểm tra khôi phục và ghi nhận diễn tập DR | UC-18-30 | 4 |
| TS-18-31 | Yêu cầu, duyệt và chạy khôi phục tenant tám bước | UC-18-31 | 5 |
| TS-18-32 | Xuất dữ liệu tenant | UC-18-32 | 2 |
| TS-18-33 | Chuyển dữ liệu phân hệ khi sáp nhập tenant theo yêu cầu PH-20 | UC-18-33 | 2 |
| TS-18-34 | Khai báo nguồn hệ cũ và lập kế hoạch di trú | UC-18-34 | 3 |
| TS-18-35 | Chạy thử di trú, đối chiếu và xử lý bản ghi lỗi | UC-18-35 | 5 |
| TS-18-36 | Chạy thật di trú có duyệt bốn mắt và đánh dấu cấp lại xác thực | UC-18-36 | 6 |
| TS-18-37 | Theo dõi chạy song song và đối soát bóng | UC-18-37 | 3 |
| TS-18-38 | Cắt chuyển nhóm dịch vụ và quay lui | UC-18-38 | 5 |
| TS-18-39 | Tra nhật ký thao tác và lập báo cáo vận hành định kỳ | UC-18-39 | 3 |
| TS-18-40 | Theo dõi sức khỏe và chạy ở chế độ suy giảm | UC-18-40 | 4 |
| TS-18-41 | Cô lập tenant ở API, CSDL, Kafka và tác vụ nặng | — | 5 |
| TS-18-42 | Phân quyền theo ma trận PERM-18 và bốn mắt xuyên suốt | — | 4 |
| TS-18-43 | Đóng an toàn, chịu lỗi và phụ thuộc mềm | — | 5 |
| TS-18-44 | Hiệu năng, quy mô và sẵn sàng | — | 10 |
| TS-18-45 | Khả năng truy cập của các màn vận hành | — | 3 |
| TS-18-46 | Tương đương hệ cũ và chức năng cũ của SRS repo | — | 2 |
| **Tổng** | | | **171** (123 ca P1) |

: Danh sách 46 kịch bản kèm use case và số ca
<!--/gen-->

## 4. Kịch bản và test case chức năng

Mỗi kịch bản mở bằng mục tiêu và phạm vi phủ, sau đó là các ca theo mục 1.5. TS-18-01…40 cùng số thứ tự với UC-18-01…40.

### TS-18-01 · Đăng ký lược đồ tham số và đọc tham số có bộ đệm

**Mục tiêu.** Chứng minh phân hệ chủ chỉ đăng ký được lược đồ trong không gian tên của mình, phân hệ khác đọc lô có `ETag` và `304`, và mọi thay đổi phát EVT-18-01 để bộ đệm làm mới trong 60 giây.

**Phủ.** FR-18-001, 002, 006; API-18-001, 002, 003, 027, 028, 029; BR-18-001, 002, 006; ERR-18-001, 003, 010, 016, 017; EVT-18-01.

#### TC-18-001 · Phân hệ chủ đăng ký lược đồ `02.` rồi phân hệ khác đọc lô có ETag <!--k:ns-dang-ky-doc-lo-->

::: dac-ta
**Mục đích.** Chứng minh đăng ký lược đồ của không gian tên được cấp thành công, giá trị mặc định có hiệu lực ngay và đọc lô trả `ETag` để bên gọi dùng `304`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-001, 002 · API-18-027, 028, 029, 001, 002, 003 · BR-18-001, 002 · EVT-18-01 · UI-18-08.

**Tiền điều kiện, dữ liệu.** T90; S-PH02 có `ops:param-register`, `ops:param-read`; lược đồ `SCH-02-V1` gồm 6 khóa (`02.review.sla-days` kiểu INT miền 1…30 mặc định 5, có một khóa ★); U-T90-TA1.

**Các bước.**

1. S-PH02 `PUT /ops/internal/v1/param-namespaces/02./schema` với `SCH-02-V1`, kèm `Idempotency-Key`.
2. S-PH02 `POST /ops/internal/v1/params:batch-get` cho T90 với 6 khóa vừa đăng ký.
3. S-PH02 gọi lại bước 2 kèm `If-None-Match` bằng `ETag` vừa nhận.
4. S-PH02 `GET /ops/internal/v1/params/T90/02.` để lấy ảnh chụp không gian tên.
5. U-T90-TA1 `GET /param-definitions?ns=02.` và mở UI-18-08.

**Kết quả mong đợi.** Bước 1 `200`, không gian tên `02.` có 6 khóa, chủ sở hữu `PH-02`; EVT-18-01 phát với `scope = SCHEMA`, không mang giá trị. Bước 2 `200`, mỗi khóa có `value`, `source = DEFAULT`, `version`; có `ETag`. Bước 3 `304`, không có thân. Bước 4 `200` với cùng `ETag`. Bước 5 thấy 6 khóa, khóa ★ có biểu tượng khóa, cột mức `TENANT`.
:::

#### TC-18-002 · Đăng ký không gian tên không thuộc mình, lược đồ sai và lược đồ xung đột <!--k:ns-khong-so-huu-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-001 không có đường vòng: phân hệ không ghi được lược đồ của phân hệ khác, không lưu được `19.*` và lược đồ mới không làm hỏng giá trị đang dùng.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-001 · API-18-027 · BR-18-001, 002 · ERR-18-003, 016, 017.

**Tiền điều kiện, dữ liệu.** T90, T91 đã có `02.review.sla-days = 20` từ TC trước; S-PH02, S-PH04 (scope `ops:param-register`).

**Các bước.**

1. S-PH04 `PUT /ops/internal/v1/param-namespaces/02./schema`.
2. S-PH02 gửi lược đồ có khóa kiểu `INTEGER` (không có trong danh mục kiểu) và khóa thiếu `default`.
3. S-PH02 gửi `SCH-02-V2` thu miền `02.review.sla-days` về 1…10.
4. S-PH02 `PUT /ops/internal/v1/param-namespaces/19./schema`.

**Kết quả mong đợi.** Bước 1 `403` ERR-18-017. Bước 2 `400` ERR-18-003, thân nêu từng khóa lỗi. Bước 3 `409` ERR-18-016, chi tiết liệt kê 2 tenant (T90, T91) đang dùng giá trị ngoài miền mới; lược đồ giữ `SCH-02-V1`. Bước 4 `403` ERR-18-017 vì `19.*` do PH-19 tự giữ. Không có EVT-18-01 nào phát ở các bước.

**Thông báo hiển thị.** ERR-18-017: "Phân hệ không sở hữu {đối tượng} {mã}." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-016: "Lược đồ mới của {ns} xung đột với giá trị đang dùng ở {số} tenant. Xem danh sách trong chi tiết."
:::

#### TC-18-003 · Đọc khóa không tồn tại và vượt giới hạn tần suất đọc <!--k:doc-tham-so-khong-co-->

::: dac-ta
**Mục đích.** Chứng minh đọc tham số trả lỗi rõ khi khóa chưa có và giới hạn tần suất bảo vệ PH-18 mà không làm phân hệ gọi mất giá trị đệm.

**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-18-002 · API-18-005, 028 · BR-18-007 · ERR-18-001, 010.

**Tiền điều kiện, dữ liệu.** T90; S-PH02; giới hạn tần suất đọc giả định 50 yêu cầu mỗi giây cho mỗi danh tính ở môi trường TEST.

**Các bước.**

1. U-T90-TA1 `GET /params/02.khong-co`.
2. S-PH02 `POST /ops/internal/v1/params:batch-get` có một khóa lạ lẫn trong 5 khóa đúng.
3. S-PH02 gửi 80 yêu cầu đọc lô trong một giây.
4. Kiểm bộ đệm `dh-ops-client` của S-PH02 sau bước 3.

**Kết quả mong đợi.** Bước 1 `404` ERR-18-001. Bước 2 `200`, 5 khóa có giá trị, khóa lạ nằm ở `missing[]`. Bước 3 có yêu cầu nhận `429` ERR-18-010 kèm `Retry-After`. Bước 4 thư viện tiếp tục dùng bản đệm, không có lỗi ở phía PH-02.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}." ERR-18-010: "Quá nhiều yêu cầu. Thử lại sau {giây} giây."
:::

#### TC-18-004 · Đổi tham số phát EVT-18-01 trong 5 giây và mọi bản sao dùng giá trị mới trong 60 giây <!--k:doi-tham-so-lan-truyen-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-006: commit giá trị phát sự kiện ≤ 5 giây, bộ đệm phía phân hệ làm mới ≤ `18.param.cache-ttl-seconds`, sự kiện không mang giá trị khóa ★.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, KT.

**Truy vết.** FR-18-006, 003 · EVT-18-01, 03 · BR-18-006 · NFR-18-005 · UI-18-24.

**Tiền điều kiện, dữ liệu.** T90; ba bản sao của DU giả lập dùng `dh-ops-client` đọc `02.review.sla-days`; đồng hồ thật; consumer `kcat` trên `t90.ops.param.changed.v1`.

**Các bước.**

1. U-T90-TA1 `PUT /params/02.review.sla-days` giá trị 7, lý do 20 ký tự, `If-Match`.
2. Ghi thời điểm commit, thời điểm EVT-18-01 xuất hiện ở Kafka và thời điểm từng bản sao báo phiên bản đệm mới.
3. Đổi một khóa ★ đã duyệt (TC ở TS-18-03) và đọc thân EVT-18-01.
4. Bật cờ `ff.ph02.tim-kiem-moi` và đọc EVT-18-03.

**Kết quả mong đợi.** Bước 2 sự kiện ≤ 5 giây sau commit, cả ba bản sao dùng giá trị 7 ≤ 60 giây. Bước 3 thân sự kiện có `ns`, `key`, `version`, `scope`, `changedBy`, không có trường giá trị. Bước 4 EVT-18-03 có `flagKey`, `enabled`, `owner`, `retireBy`. Không bản sao nào cần khởi động lại.
:::

#### TC-18-005 · Kafka chậm thì EVT-18-01 nằm ở outbox, bộ đệm hết hạn tự đọc lại; bộ tiêu thụ lỗi vào DLQ PH-18 <!--k:doi-tham-so-outbox-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-006 không mất thay đổi khi đường sự kiện gián đoạn: giá trị đã commit vẫn tới mọi bản sao nhờ hết hạn đệm, sự kiện gửi bù từ outbox, lỗi xử lý sự kiện của chính PH-18 đi vào DLQ.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-18-006, 002 · BR-18-006, 007 · ERR-18-124 · EVT-18-01.

**Tiền điều kiện, dữ liệu.** T94; Chaos Mesh làm trễ Kafka 3 phút; ba bản sao DU giả lập dùng `dh-ops-client` với `18.param.cache-ttl-seconds = 60`.

**Các bước.**

1. Làm trễ Kafka, U-T94-TA1 đổi `02.review.sla-days` thành 9.
2. Đo thời điểm từng bản sao dùng giá trị 9.
3. Bỏ trễ Kafka, đọc topic `t94.ops.param.changed.v1`.
4. Làm bộ tiêu thụ EVT-18-01 nội bộ của PH-18 (làm mới đệm màn tham số) lỗi năm lần.

**Kết quả mong đợi.** Bước 2 mọi bản sao dùng giá trị 9 trong ≤ 60 giây nhờ hết hạn đệm và đọc lại có `ETag`. Bước 3 đúng một EVT-18-01 được gửi bù từ outbox, không trùng. Bước 4 inbox `FAILED`, ghi ERR-18-124, mục DLQ nguồn `PH18_INBOX`.

**Thông báo hiển thị.** ERR-18-124 (hiện ở màn vận hành, không trả qua HTTP): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
:::

### TS-18-02 · Sửa giá trị tham số trên màn tham số chung

**Mục tiêu.** Chứng minh mỗi lần ghi giá trị theo tenant được kiểm kiểu, miền, trần nền tảng và lý do, có `If-Match`, tạo phiên bản bất biến, và màn tham số chung nhúng đúng theo không gian tên và nhóm.

**Phủ.** FR-18-003, 007, 069; API-18-004…007, 016; BR-18-002, 003, 005, 049; ERR-18-004, 007, 011…015; ERR-00-428.

#### TC-18-006 · TA sửa giá trị tham số tenant có lý do và If-Match trên màn nhúng <!--k:ghi-tham-so-duong-->

::: dac-ta
**Mục đích.** Chứng minh đường ghi chuẩn: kiểm trước bằng `:validate`, ghi có lý do và `If-Match`, tạo phiên bản mới, nhật ký đổi tham số có người đổi và lý do.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-003, 007 · API-18-004, 005, 006, 007, 016 · BR-18-002, 005, 049 · EVT-18-01 · UI-18-08.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1 có `PERM-18-config`; `04.retry.max-attempts` (INT, miền 0…10, trần 8, mặc định 3) đang ở phiên bản 1.

**Các bước.**

1. U-T90-TA1 mở `/van-hanh/tham-so?ns=04.&nhom=thu-lai`.
2. Nhập giá trị 5 rồi bấm "Kiểm tra" (gọi `POST /params:validate`).
3. Nhập lý do "Tăng số lần thử cho luồng thuế ban đêm" và bấm "Lưu" (gửi `PUT /params/04.retry.max-attempts` kèm `If-Match`).
4. Mở `GET /param-changes?ns=04.`.

**Kết quả mong đợi.** Bước 1 màn chỉ hiện nhóm "thu-lai" của `04.`, có nguồn giá trị (mặc định, tenant). Bước 2 `200` hợp lệ, không ghi. Bước 3 `200`, `version = 2`, `ETag` mới, EVT-18-01 phát; KT: có (param-update) với giá trị cũ, mới, lý do. Bước 4 có dòng đổi với người đổi U-T90-TA1.
:::

#### TC-18-007 · Khóa chưa đăng ký, sai kiểu, ngoài miền, vượt trần, khóa PLATFORM và thiếu lý do <!--k:ghi-tham-so-mien-tran-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-002, 003: PH-18 chặn mọi giá trị sai ở thời điểm ghi với đúng mã lỗi, giá trị cũ giữ nguyên.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-003 · API-18-006, 007 · BR-18-002, 003 · ERR-18-007, 011, 012, 013, 014, 015.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; `04.retry.max-attempts` (miền 0…10, trần nền tảng 8); `onboarding.platform.max-tenants` mức `PLATFORM`.

**Các bước.**

1. `PUT /params/04.khong-dang-ky` giá trị 1.
2. `PUT /params/04.retry.max-attempts` giá trị `"năm"`.
3. Cùng khóa giá trị 12, rồi giá trị 9.
4. `PUT /params/onboarding.platform.max-tenants` giá trị 50.
5. Cùng khóa `04.retry.max-attempts` giá trị 6 nhưng lý do "sửa" (4 ký tự).

**Kết quả mong đợi.** Bước 1 `404` ERR-18-011. Bước 2 `422` ERR-18-012. Bước 3 lần đầu `422` ERR-18-013, lần sau `422` ERR-18-014. Bước 4 `403` ERR-18-015. Bước 5 `422` ERR-18-007. Không bước nào tạo phiên bản hay phát EVT-18-01; `:validate` cho cùng giá trị trả cùng mã.

**Thông báo hiển thị.** ERR-18-011: "Khóa {khóa} chưa được đăng ký." ERR-18-012: "Giá trị của {khóa} phải có kiểu {kiểu}." ERR-18-013: "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}." ERR-18-014: "Giá trị vượt giới hạn nền tảng của {khóa} ({trần}). Liên hệ quản trị nền tảng nếu cần nâng." ERR-18-015: "Tham số {khóa} do quản trị nền tảng đặt, tỉnh chỉ xem được." ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

#### TC-18-008 · Hai người sửa cùng lúc, thiếu If-Match và vai không có quyền <!--k:ghi-tham-so-if-match-->

::: dac-ta
**Mục đích.** Chứng minh khóa lạc quan và quyền trên thao tác ghi: người lưu sau nhận lỗi ETag lệch, thiếu `If-Match` bị từ chối, VW không ghi được.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-003 · API-18-006 · BR-18-049 · ERR-18-004 · ERR-00-428, 403 · UI-18-08.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1, U-T90-TA2 cùng mở khóa `04.retry.max-attempts` phiên bản 2; U-T90-VW.

**Các bước.**

1. TA1 lưu giá trị 4 với `If-Match` của phiên bản 2.
2. TA2 lưu giá trị 6 với `If-Match` của phiên bản 2.
3. TA2 gửi lại không có `If-Match`.
4. U-T90-VW gửi `PUT` hợp lệ.

**Kết quả mong đợi.** Bước 1 `200`, phiên bản 3. Bước 2 `412` ERR-18-004, UI-18-08 hiện câu thông báo và nút "Tải lại". Bước 3 `428` ERR-00-428. Bước 4 `403` ERR-00-403. Giá trị cuối là 4.

**Thông báo hiển thị.** ERR-18-004: "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu."
:::

#### TC-18-009 · PA chỉnh tham số `18.*` của chính phân hệ vận hành, TA chỉ chỉnh khóa được mở <!--k:tham-so-18-admin-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-069: tham số `18.*` dùng chính kho tham số, `PERM-18-admin` của PA ghi được, TA chỉ ghi khóa mức `TENANT` và bị chặn ở trần.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-069 · API-18-004, 006 · BR-18-002, 004 · ERR-18-012, 014, 015.

**Tiền điều kiện, dữ liệu.** T90; U-PA1 (`PERM-18-admin`); U-T90-TA1 (`PERM-18-admin` hạn chế); `18.dlq.retention.closed-days` miền 30…365.

**Các bước.**

1. U-PA1 `PUT /params/18.dlq.retention.closed-days` cho T90 giá trị 120, lý do.
2. U-T90-TA1 ghi cùng khóa giá trị 400.
3. U-T90-TA1 ghi `18.dlq.replay.rate-per-second` giá trị `true`.
4. U-T90-TA1 ghi `18.outbox.retention-days` (mức `PLATFORM`).

**Kết quả mong đợi.** Bước 1 `200`, tác vụ dọn của PH-18 đọc giá trị 120 ở lần chạy kế tiếp. Bước 2 `422` ERR-18-014. Bước 3 `422` ERR-18-012. Bước 4 `403` ERR-18-015.

**Thông báo hiển thị.** ERR-18-014: "Giá trị vượt giới hạn nền tảng của {khóa} ({trần}). Liên hệ quản trị nền tảng nếu cần nâng." ERR-18-012: "Giá trị của {khóa} phải có kiểu {kiểu}." ERR-18-015: "Tham số {khóa} do quản trị nền tảng đặt, tỉnh chỉ xem được."
:::

### TS-18-03 · Đề nghị và duyệt bốn mắt tham số bảo mật ★

**Mục tiêu.** Chứng minh khóa ★ chỉ có hiệu lực sau người duyệt thứ hai khác người đề nghị, đề nghị chờ duyệt hiện ở Việc của tôi, khóa do phân hệ khác giữ duyệt chỉ nhận giá trị đã duyệt từ danh tính dịch vụ của phân hệ đó.

**Phủ.** FR-18-004; API-18-006, 008…012; BR-18-004, 005, 046; ERR-18-005, 008, 013, 018, 019; EVT-18-01, 02; UI-18-09, 15.

#### TC-18-010 · Đề nghị đổi khóa ★ rồi SO duyệt, giá trị có hiệu lực sau duyệt <!--k:sao-bon-mat-duong-->

::: dac-ta
**Mục đích.** Chứng minh luồng bốn mắt chuẩn: đề nghị tạo `PENDING_APPROVAL`, việc duyệt hiện cho người có `PERM-18-approve` trừ người đề nghị, duyệt xong mới thành `ACTIVE`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-004 · API-18-006, 008, 009, 010 · BR-18-004, 005, 046 · EVT-18-01, 02 · UI-18-09, 15.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1 (đề nghị), U-T90-SO (`PERM-18-approve`); `18.dlq.replay.approval-threshold` ★ = 500.

**Các bước.**

1. TA1 `PUT /params/18.dlq.replay.approval-threshold` giá trị 200, lý do 30 ký tự.
2. TA1 `GET /params/18.dlq.replay.approval-threshold`.
3. SO mở `/viec-cua-toi`, mở việc `ph18.approve-param`, xem giá trị trước và sau ở UI-18-09.
4. SO `POST /param-change-requests/{requestId}:approve` kèm `If-Match`.

**Kết quả mong đợi.** Bước 1 `202`, đề nghị `PENDING_APPROVAL`, EVT-18-02 phát; KT: có (param-change-request). Bước 2 giá trị hiệu lực vẫn 500. Bước 3 việc chỉ hiện cho SO và TA2, không hiện cho TA1. Bước 4 `200`, phiên bản mới `ACTIVE`, phiên bản cũ `SUPERSEDED`, EVT-18-01 phát, việc đóng `DONE`; KT ghi trước khi giá trị có hiệu lực.
:::

#### TC-18-011 · Người đề nghị tự duyệt, đề nghị trùng, giá trị ngoài miền <!--k:sao-trung-nguoi-->

::: dac-ta
**Mục đích.** Chứng minh LP-18-01: người đề nghị không duyệt được dù có `PERM-18-approve`, mỗi khóa chỉ một đề nghị chờ duyệt.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-004 · API-18-006, 010 · BR-18-004 · ERR-18-005, 013, 018.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1 có cả `PERM-18-config` và `PERM-18-approve`; một đề nghị của TA1 đang `PENDING_APPROVAL` cho `18.dlq.reveal.ttl-minutes`.

**Các bước.**

1. TA1 `POST /param-change-requests/{requestId}:approve` cho đề nghị của mình.
2. U-T90-TA2 gửi đề nghị thứ hai cho cùng khóa.
3. TA2 gửi đề nghị cho `18.dlq.reveal.ttl-minutes` giá trị 90.

**Kết quả mong đợi.** Bước 1 `403` ERR-18-005, đề nghị vẫn `PENDING_APPROVAL`, nút "Duyệt" trên UI-18-09 bị khóa với TA1. Bước 2 `409` ERR-18-018 nêu tên người đề nghị. Bước 3 `422` ERR-18-013. KT: có cho lần duyệt bị từ chối.

**Thông báo hiển thị.** ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt." ERR-18-018: "Tham số {khóa} đang có đề nghị chờ duyệt của {người}. Chờ duyệt xong hoặc rút đề nghị." ERR-18-013: "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}."
:::

#### TC-18-012 · Khóa do phân hệ khác giữ duyệt, từ chối, rút và hết hạn đề nghị <!--k:sao-approval-owner-->

::: dac-ta
**Mục đích.** Chứng minh khóa có `approvalOwner` là PH-17 không đề nghị được ở PH-18, chỉ nhận giá trị đã duyệt từ danh tính PH-17 kèm `approvalRef`; đề nghị bị từ chối, rút hoặc quá `18.param.change-request-ttl-hours` không có hiệu lực.

**Loại.** Âm, Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-004 · API-18-006, 011, 012 · BR-18-004 · ERR-18-019.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); `17.external-model.enabled` ★ có `approvalOwner = PH-17`; S-PH17; U-T95-TA1, U-T95-SO.

**Các bước.**

1. U-T95-TA1 `PUT /params/17.external-model.enabled` giá trị `true`.
2. S-PH17 ghi cùng khóa kèm `approvalRef` của đề nghị đã duyệt ở PH-17.
3. TA1 đề nghị khóa ★ khác, SO `:reject` kèm lý do; TA1 đề nghị lại rồi `:withdraw`.
4. TA1 đề nghị lần ba, tua đồng hồ thêm 73 giờ.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-019, câu thông báo chỉ sang màn PH-17. Bước 2 `200`, phiên bản mới ghi `approvalRef`. Bước 3 đề nghị `REJECTED` rồi `CANCELLED`, giá trị không đổi. Bước 4 đề nghị chuyển `EXPIRED`, việc duyệt đóng `EXPIRED`, giá trị không đổi.

**Thông báo hiển thị.** ERR-18-019: "Tham số {khóa} được duyệt tại {phân hệ}. Mở màn {phân hệ} để đề nghị thay đổi."
:::

#### TC-18-013 · PH-13 không ghi được kiểm toán thì từ chối duyệt khóa ★ <!--k:sao-kiem-toan-loi-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-046: thao tác bốn mắt không có hiệu lực khi kiểm toán chưa ghi được.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-004 · API-18-010 · BR-18-046 · ERR-18-008.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-13 trả `503` cho API nhận kiểm toán; một đề nghị khóa ★ `PENDING_APPROVAL`.

**Các bước.**

1. U-T94-SO duyệt đề nghị.
2. Khôi phục PH-13 rồi SO duyệt lại.

**Kết quả mong đợi.** Bước 1 `503` ERR-18-008, giá trị không đổi, không có EVT-18-01. Bước 2 `200`, giá trị có hiệu lực, KT đủ.

**Thông báo hiển thị.** ERR-18-008: "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
:::

### TS-18-04 · Xem lịch sử, so sánh và khôi phục phiên bản tham số

**Mục tiêu.** Chứng minh mỗi lần ghi là một phiên bản bất biến, so sánh được hai phiên bản, khôi phục tạo phiên bản mới mang giá trị cũ và bị chặn khi phiên bản cũ không còn hợp lệ với lược đồ.

**Phủ.** FR-18-005; API-18-013, 014, 015, 016; BR-18-005; ERR-18-001, 007, 023.

#### TC-18-014 · Xem lịch sử, so sánh v1 với v3 và khôi phục v1 thành v4 <!--k:lich-su-khoi-phuc-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-005: khôi phục không xóa phiên bản trung gian, tạo phiên bản mới có ghi nguồn khôi phục.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-005 · API-18-013, 014, 015, 016 · BR-18-005 · EVT-18-01 · UI-18-09.

**Tiền điều kiện, dữ liệu.** T90; `04.retry.max-attempts` có ba phiên bản (3, 5, 4).

**Các bước.**

1. U-T90-TA1 mở `/van-hanh/tham-so/04.retry.max-attempts/lich-su`.
2. `GET /params/04.retry.max-attempts/versions:compare?from=1&to=3`.
3. `POST /params/04.retry.max-attempts/versions/1:restore` kèm lý do và `If-Match`.

**Kết quả mong đợi.** Bước 1 ba dòng có người đổi, lý do, thời điểm, phiên bản 3 đánh dấu hiện hành. Bước 2 `200` hiện giá trị trước và sau. Bước 3 `200`, phiên bản 4 giá trị 3, `restoredFrom = 1`, phiên bản 1 đến 3 còn nguyên, EVT-18-01 phát.
:::

#### TC-18-015 · Khôi phục phiên bản không tồn tại, không còn hợp lệ với lược đồ, thiếu lý do <!--k:khoi-phuc-khong-hop-le-->

::: dac-ta
**Mục đích.** Chứng minh khôi phục vẫn đi qua kiểm miền của lược đồ hiện hành và cần lý do.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-005 · API-18-015 · BR-18-002, 005 · ERR-18-001, 007, 023.

**Tiền điều kiện, dữ liệu.** T90; `02.review.sla-days` phiên bản 1 giá trị 20, lược đồ hiện hành đã thu miền về 1…15 (sau khi PH-02 di chuyển dữ liệu).

**Các bước.**

1. `POST /params/02.review.sla-days/versions/9:restore`.
2. `POST /params/02.review.sla-days/versions/1:restore` có lý do.
3. Khôi phục phiên bản 2 hợp lệ nhưng lý do rỗng.

**Kết quả mong đợi.** Bước 1 `404` ERR-18-001. Bước 2 `409` ERR-18-023 nêu miền mới. Bước 3 `422` ERR-18-007. Không phiên bản mới nào được tạo.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}." ERR-18-023: "Phiên bản {số} không còn hợp lệ với lược đồ hiện hành của {khóa}: {lý do}." ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

### TS-18-05 · Xuất, nhập gói tham số giữa môi trường

**Mục tiêu.** Chứng minh gói tham số có chữ ký và tổng kiểm tra, không chứa giá trị bí mật, nhập mặc định chạy thử, khóa ★ trong gói tạo đề nghị chờ duyệt bốn mắt.

**Phủ.** FR-18-008; API-18-017, 018, 019; BR-18-002, 004, 048; ERR-18-005, 013, 020; EVT-18-02.

#### TC-18-016 · Xuất gói từ STAGING, nhập chạy thử và áp vào TEST, khóa ★ chờ duyệt <!--k:goi-tham-so-duong-->

::: dac-ta
**Mục đích.** Chứng minh đường đi của gói: xuất có SHA-256, nhập `dryRun = true` chỉ so khớp, áp gói ghi khóa thường và tạo đề nghị cho khóa ★.

**Loại.** Dương.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-18-008 · API-18-017, 018, 019 · BR-18-004, 048 · EVT-18-01, 02 · UI-18-08.

**Tiền điều kiện, dữ liệu.** T68 ở STAGING có 12 khóa `04.` trong đó 2 khóa ★; T90 ở TEST; U-PA1, U-PA2 (`PERM-18-admin`, `PERM-18-approve`).

**Các bước.**

1. U-PA1 `POST /param-bundles:export` cho `ns = 04.` của T68.
2. Kiểm nội dung gói: không có giá trị bí mật, chỉ tham chiếu `kv/dh/t68/...`.
3. U-PA1 `POST /param-bundles:import` vào T90 (mặc định `dryRun = true`).
4. U-PA1 `POST /param-bundles/{bundleId}:apply`; U-PA2 duyệt hai đề nghị khóa ★.

**Kết quả mong đợi.** Bước 1 `200`, gói có `manifestSha256` và chữ ký. Bước 2 đạt. Bước 3 `200`, báo 10 khóa đổi, 2 khóa ★, không có giá trị nào ghi. Bước 4 10 khóa có phiên bản mới, EVT-18-01 phát; 2 đề nghị `PENDING_APPROVAL` (EVT-18-02), sau khi U-PA2 duyệt mới `ACTIVE`.
:::

#### TC-18-017 · Gói bị sửa, giá trị ngoài miền đích và người áp tự duyệt khóa ★ <!--k:goi-tham-so-sua-->

::: dac-ta
**Mục đích.** Chứng minh gói bị đổi một byte bị từ chối, so khớp chặn giá trị ngoài miền của môi trường đích, và bốn mắt của gói không có đường vòng.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-18-008 · API-18-018, 019, 010 · BR-18-002, 004, 048 · ERR-18-005, 013, 020.

**Tiền điều kiện, dữ liệu.** Gói `BUNDLE-T68-04` từ ca trước; bản sửa tay đổi một giá trị; gói có `04.retry.max-attempts = 9` trong khi trần của T92 là 5.

**Các bước.**

1. Nhập bản đã sửa tay vào T90.
2. Nhập gói gốc vào T92.
3. U-PA1 áp gói vào T90 rồi tự duyệt đề nghị khóa ★ vừa sinh.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-020 (tổng kiểm tra lệch). Bước 2 `422` ERR-18-013 liệt kê khóa ngoài miền, không ghi khóa nào. Bước 3 `403` ERR-18-005.

**Thông báo hiển thị.** ERR-18-020: "Gói tham số không hợp lệ hoặc đã bị sửa: {chi tiết}." ERR-18-013: "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}." ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

### TS-18-06 · Quản lý cờ tính năng và danh sách egress cho phép

**Mục tiêu.** Chứng minh cờ tính năng có chủ sở hữu và ngày gỡ trong 365 ngày, quá hạn chỉ nhắc không tự tắt; đích egress chỉ là FQDN công khai qua HTTPS có hạn dùng và mỗi thay đổi phát sự kiện cho PH-13.

**Phủ.** FR-18-009, 010; API-18-020…026; BR-18-008, 009; ERR-18-002, 013, 021, 022; EVT-18-03, 04.

#### TC-18-018 · Khai báo, bật theo tenant, gỡ cờ tính năng <!--k:co-tinh-nang-duong-->

::: dac-ta
**Mục đích.** Chứng minh vòng đời cờ `ff.{module}.{tính-năng}`: khai báo có chủ sở hữu, bật cho T90 không ảnh hưởng T91, gỡ sau khi mã bỏ nhánh cờ.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-009 · API-18-020, 021, 022, 023, 028 · BR-18-008 · EVT-18-03 · UI-18-10.

**Tiền điều kiện, dữ liệu.** U-PA1; U-T90-TA1 (`PERM-18-config`); chủ sở hữu `PH-02`.

**Các bước.**

1. U-PA1 `POST /feature-flags` `ff.ph02.tim-kiem-moi`, chủ sở hữu PH-02, ngày gỡ sau 120 ngày.
2. U-T90-TA1 `PATCH /feature-flags/ff.ph02.tim-kiem-moi` bật cho T90 kèm `If-Match`.
3. S-PH02 đọc lô cờ cho T90 và T91.
4. U-PA1 `POST /feature-flags/ff.ph02.tim-kiem-moi:retire`.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `200`, EVT-18-03 `enabled = true`. Bước 3 T90 `true`, T91 `false`. Bước 4 `200`, cờ `RETIRED`, đọc lô trả giá trị mặc định và cờ không còn hiện ở UI-18-10.
:::

#### TC-18-019 · Cờ thiếu chủ sở hữu, ngày gỡ quá 365 ngày, trùng mã và quá ngày gỡ <!--k:co-tinh-nang-loi-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-008: cờ không có chủ sở hữu và ngày gỡ hợp lệ bị từ chối; quá ngày gỡ chỉ nhắc chủ sở hữu, không tự tắt.

**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-009 · API-18-021 · BR-18-008 · ERR-18-002, 021 · EVT-18-03.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); cờ `ff.ph04.mo-phong` đã có, ngày gỡ sau 10 ngày, đang bật.

**Các bước.**

1. Khai báo cờ thiếu `owner`.
2. Khai báo cờ có ngày gỡ sau 400 ngày.
3. Khai báo lại `ff.ph04.mo-phong`.
4. Tua đồng hồ 11 ngày, chạy tác vụ nhắc.

**Kết quả mong đợi.** Bước 1 và 2 `422` ERR-18-021. Bước 3 `409` ERR-18-002. Bước 4 cờ vẫn bật, chủ sở hữu PH-04 nhận việc nhắc và thông báo; không có EVT-18-03 tắt cờ.

**Thông báo hiển thị.** ERR-18-021: "Cờ tính năng cần chủ sở hữu và ngày gỡ dự kiến trong vòng 365 ngày." ERR-18-002: "Mã {mã} đã được dùng. Chọn mã khác."
:::

#### TC-18-020 · Thêm và gỡ đích egress có hạn dùng, PH-13 nhận sự kiện <!--k:egress-duong-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-010: đích FQDN công khai qua HTTPS được thêm có mục đích, hạn dùng, kiểu `LIST<HOST>`; gỡ cần lý do; EVT-18-04 phát cho PH-13 cập nhật chính sách egress.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, KT.

**Truy vết.** FR-18-010 · API-18-024, 025, 026, 028 · BR-18-009 · EVT-18-04 · UI-18-10.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; `18.egress.max-entries = 200`.

**Các bước.**

1. `POST /egress-allowlist` `api.thuedientu.gdt.gov.vn:443`, mục đích `WEBHOOK`, hạn 180 ngày.
2. `POST /egress-allowlist` `*.vnpt.vn:443`.
3. S-PH04 đọc lô `18.egress.allowlist` của T90.
4. `DELETE /egress-allowlist/{entryId}` kèm lý do.

**Kết quả mong đợi.** Bước 1 và 2 `201`, mỗi lần một EVT-18-04 `action = ADD`. Bước 3 hai đích có `expiresAt`. Bước 4 `204`, EVT-18-04 `action = REMOVE`; KT: có.
:::

#### TC-18-021 · Đích là IP, dải nội bộ, HTTP thường, ký tự đại diện hai cấp, trùng và vượt số mục <!--k:egress-loi-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-009 chặn mọi đích không phải tên miền công khai qua HTTPS và giới hạn số mục.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-010 · API-18-025 · BR-18-009 · ERR-18-002, 013, 022.

**Tiền điều kiện, dữ liệu.** T92 có `18.egress.max-entries = 3` và đã có 3 mục; T90 trống.

**Các bước.**

1. Ở T90 thêm lần lượt `203.0.113.10:443`, `db.cluster.local:5432`, `http://example.vn`, `*.*.gov.vn:443`.
2. Thêm hai lần `api.example.vn:443`.
3. Ở T92 thêm mục thứ tư hợp lệ.

**Kết quả mong đợi.** Bước 1 mỗi đích `422` ERR-18-022. Bước 2 lần hai `409` ERR-18-002. Bước 3 `422` ERR-18-013. Không có EVT-18-04 cho mục bị từ chối.

**Thông báo hiển thị.** ERR-18-022: "Đích {đích} không được phép: chỉ chấp nhận tên miền công khai qua HTTPS." ERR-18-002: "Mã {mã} đã được dùng. Chọn mã khác." ERR-18-013: "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}."
:::

### TS-18-07 · Ghi tham số mặc định khi khởi tạo tenant

**Mục tiêu.** Chứng minh khi PH-20 khởi tạo tenant, PH-18 chỉ thêm khóa chưa có, không ghi đè, chạy lại không đổi gì, và xử lý sự kiện lỗi được đưa vào DLQ của chính PH-18.

**Phủ.** FR-18-011, 045; API-18-030; BR-18-010; ERR-18-001, 071, 124; EVT-18-15.

#### TC-18-022 · Sự kiện tenant mới ghi tham số, lịch mặc định; chạy lại không đổi <!--k:seed-mac-dinh-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-010: lần đầu ghi đủ mặc định của mọi không gian tên đã đăng ký và lịch `COMMON`, lần hai và gọi API trực tiếp không tạo phiên bản mới.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-18-011, 045 · API-18-030 · BR-18-010 · EVT-18-15 · UI-18-08.

**Tiền điều kiện, dữ liệu.** T93 mới, chưa có giá trị; S-PH20 (`ops:param-write`); WireMock PH-20 phát `platform.tenant.created.v1` cho T93.

**Các bước.**

1. Phát `platform.tenant.created.v1` cho T93.
2. S-PH20 `POST /ops/internal/v1/tenants/T93/params:seed-defaults`.
3. U-T93-TA1 sửa `04.retry.max-attempts` thành 5; phát lại sự kiện lần hai (cùng `eventId`) và một sự kiện mới `eventId` khác.

**Kết quả mong đợi.** Bước 1 mọi khóa mức `TENANT` có giá trị `source = DEFAULT`, lịch năm hiện tại tạo từ `COMMON`, EVT-18-15 phát một lần. Bước 2 `200`, `added = 0`. Bước 3 inbox bỏ sự kiện trùng; sự kiện mới không ghi đè giá trị 5, `added = 0`.
:::

#### TC-18-023 · Tenant không tồn tại, chế độ chỉ đọc và sự kiện lỗi năm lần vào DLQ PH-18 <!--k:seed-loi-->

::: dac-ta
**Mục đích.** Chứng minh lỗi khi ghi mặc định được báo rõ và sự kiện tiêu thụ lỗi đi vào DLQ của PH-18 thay vì mất (LP-18-06).

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-18-011, 072 · API-18-030 · BR-18-010 · ERR-18-001, 071, 124 · UI-18-24.

**Tiền điều kiện, dữ liệu.** T93; `18.degraded.read-only = true` ở bước 2; WireMock registry PH-20 không trả T99X.

**Các bước.**

1. S-PH20 `POST /ops/internal/v1/tenants/T99X/params:seed-defaults`.
2. Bật chế độ chỉ đọc, gọi lại cho T93.
3. Phát sự kiện `platform.tenant.created.v1` có thân hỏng làm bộ xử lý lỗi năm lần.

**Kết quả mong đợi.** Bước 1 `404` ERR-18-001. Bước 2 `503` ERR-18-071. Bước 3 inbox `FAILED`, ghi ERR-18-124, có mục DLQ nguồn `PH18_INBOX` hiện ở UI-18-24 và phát lại được như mục DLQ thường.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}." ERR-18-071: "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được." ERR-18-124 (hiện ở màn vận hành, không trả qua HTTP): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
:::

### TS-18-08 · Đăng ký nguồn DLQ và cổng phát lại

**Mục tiêu.** Chứng minh nguồn tự đăng ký hoặc được khai báo tay với kiểu cổng phát lại và trần tốc độ, nguồn tạm ngừng không ghi được DLQ và mục của nguồn không có cổng không phát lại được.

**Phủ.** FR-18-012; API-18-031…034; BR-18-019, 022; ERR-18-003, 026, 033.

#### TC-18-024 · Nguồn tự đăng ký khi khởi động và PA khai báo nguồn thủ công <!--k:nguon-dang-ky-->

::: dac-ta
**Mục đích.** Chứng minh `dh-runtime` (PH-04) tự đăng ký cổng `KAFKA_TOPIC`, PH-19 đăng ký cổng `HTTP_PORT`, PA khai báo nguồn không tự đăng ký; danh sách nguồn hiện trần tốc độ.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-012 · API-18-031, 032, 034 · BR-18-019, 022 · UI-18-06.

**Tiền điều kiện, dữ liệu.** T90; S-PH04, S-PH19 (`ops:dlq-write`); U-PA1 (`PERM-18-admin`).

**Các bước.**

1. S-PH04 `POST /ops/internal/v1/dlq-sources:register` `SRC-PH04`, cổng `KAFKA_TOPIC`, trần 50 mục mỗi giây.
2. S-PH19 đăng ký `SRC-PH19`, cổng `HTTP_PORT` `/payment/internal/v1/inbox:replay`.
3. S-PH04 gọi lại bước 1 với cùng nội dung.
4. U-PA1 `POST /dlq-sources` `SRC-PH08-DQ` cổng `NONE`; mở UI-18-06.

**Kết quả mong đợi.** Bước 1, 2 `200`, nguồn `ACTIVE`. Bước 3 `200` không tạo bản ghi mới. Bước 4 `201`; UI-18-06 hiện ba nguồn, kiểu cổng và trần tốc độ.
:::

#### TC-18-025 · Sửa cổng sai, tạm ngừng nguồn và ghi DLQ từ nguồn tạm ngừng <!--k:nguon-tam-ngung-->

::: dac-ta
**Mục đích.** Chứng minh nguồn tạm ngừng bị từ chối ghi, nguồn cổng `NONE` không phát lại được, cổng khai sai bị chặn.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-012, 014, 027 · API-18-033, 035, 064 · BR-18-019 · ERR-18-003, 026, 033.

**Tiền điều kiện, dữ liệu.** T90; `SRC-PH19` `ACTIVE`; `SRC-PH08-DQ` cổng `NONE` có mục `DLQ-PH08-1` `TRIAGED`.

**Các bước.**

1. U-PA1 `PATCH /dlq-sources/SRC-PH19` đặt cổng `HTTP_PORT` với đường dẫn tuyệt đối ra ngoài cụm.
2. U-PA1 tạm ngừng `SRC-PH19` kèm lý do và `If-Match`.
3. S-PH19 `POST /ops/internal/v1/dlq/messages` một mục hợp lệ.
4. U-T90-TO `POST /dlq/messages/DLQ-PH08-1:replay`.

**Kết quả mong đợi.** Bước 1 `400` ERR-18-003. Bước 2 `200`, `SUSPENDED`. Bước 3 `403` ERR-18-026; PH-19 giữ mục ở inbox `FAILED` của mình (LP-18-04). Bước 4 `409` ERR-18-033.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-026: "Nguồn {mã} chưa được đăng ký hoặc đang tạm ngừng ghi DLQ." ERR-18-033: "Nguồn {mã} chưa có cổng phát lại hoặc đang tạm ngừng."
:::

### TS-18-09 · Tiếp nhận bản tin lỗi từ topic, kiểm ngữ cảnh và đối soát với Kafka

**Mục tiêu.** Chứng minh PH-18 tiêu thụ `{tenant}.ops.dlq.v1`, chỉ commit offset sau khi chỉ mục bền, đánh dấu `POISON` khi thiếu ngữ cảnh, lưu payload lớn ở Garage, khử trùng theo `dlqKey` và đối soát chỉ mục với Kafka.

**Phủ.** FR-18-013, 015, 016, 018; BR-18-011, 013, 014, 015; ERR-18-006, 101…105; EVT-18-05, 06, 08; NFR-18-021.

#### TC-18-026 · Bản tin đủ header thành mục NEW, sự kiện gộp theo phút <!--k:tiep-nhan-du-ngu-canh-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-013: bản tin đủ hợp đồng ngữ cảnh (bảng 4.1b của FRS) thành mục `NEW` có lớp lỗi gợi ý, offset chỉ commit sau khi ghi bền, EVT-18-05 gộp theo phút.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, KT.

**Truy vết.** FR-18-013 · BR-18-011 · EVT-18-05 · UI-18-01, 24.

**Tiền điều kiện, dữ liệu.** T90; topic `t90.ops.dlq.v1` 6 phân vùng; `DLQ-SET-A` gồm 20 bản tin của `SRC-PH04` đủ header (`dh-tenant`, `dh-source-ph`, `dh-dlq-reason`, `dh-dlq-error-code`, `dh-dlq-stage`, `dh-dlq-attempts`, `dh-flow`, `dh-version`, `traceparent`, `dh-message-id`).

**Các bước.**

1. Đẩy 20 bản tin bằng `kcat`.
2. Giết bản sao `dh-platform` giữa lúc tiêu thụ bản tin thứ 10, chờ bản sao mới.
3. Mở UI-18-01 lọc `nguon=SRC-PH04`.
4. Đọc `t90.ops.dlq.received.v1`.

**Kết quả mong đợi.** Có đúng 20 mục `NEW`, không mất, không trùng (bản tin thứ 10 được xử lý lại nhờ offset chưa commit và khử trùng). Mục có `errorClass` gợi ý theo `dh-dlq-reason`, có `traceId`. EVT-18-05 có `count = 20`, `poisonCount = 0` gộp theo phút.
:::

#### TC-18-027 · Thiếu header bắt buộc thành POISON, tenant lệch topic, không giải mã được <!--k:poison-thieu-header-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-013 và các lỗi worker: mục thiếu ngữ cảnh là `POISON` kèm EVT-18-06, bản tin có tenant khác tiền tố topic không vào chỉ mục của tenant đó, thân không giải mã được lưu dạng nhị phân.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, KT.

**Truy vết.** FR-18-013, 015 · BR-18-013 · ERR-18-101, 102, 103 · EVT-18-06, 08 · UI-18-01, 03.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-POISON` gồm 3 bản tin thiếu lần lượt `dh-dlq-stage`, `dh-flow` (nguồn `KAFKA_TOPIC`), `dh-tenant`; 1 bản tin `dh-tenant = T91` ghi vào `t90.ops.dlq.v1`; 1 bản tin thân không phải UTF-8 cũng không phải Avro.

**Các bước.**

1. Đẩy 5 bản tin.
2. Mở UI-18-01 lọc `trang-thai=POISON`, mở một mục.
3. Đọc `t90.ops.dlq.poison-detected.v1`.
4. Đẩy thêm 10 bản tin thiếu header trong một giờ (vượt `18.dlq.threshold.poison-per-hour`).

**Kết quả mong đợi.** Ba mục `POISON` có `missingFields` đúng, ghi ERR-18-102. Bản tin tenant lệch bị ghi ERR-18-103, không có mục ở T90 hay T91, có chỉ số `dh_ops_errors_total{code="ERR-18-103"}`. Bản tin không giải mã được thành mục ghi ERR-18-101, payload lưu nhị phân. EVT-18-06 phát mỗi mục `POISON`; bước 4 phát EVT-18-08 `type = POISON_RATE`. UI-18-03 hiện nút "Sửa" và "Bỏ qua", không có "Phát lại".

**Thông báo hiển thị.** ERR-18-102 (hiện ở màn vận hành, không trả qua HTTP): "Thiếu thông tin ngữ cảnh: {trường}." ERR-18-103 (hiện ở màn vận hành, không trả qua HTTP): "Tenant của bản tin không khớp topic." ERR-18-101 (hiện ở màn vận hành, không trả qua HTTP): "Không đọc được nội dung bản tin; lưu dạng nhị phân."
:::

#### TC-18-028 · Payload 300 KB lưu ở Garage có SHA-256, tổng kiểm tra lệch bị phát hiện <!--k:payload-lon-garage-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-014: payload lớn hơn `18.dlq.payload.inline-max-kb` lưu ở bucket `dh-t90-ops`, chỉ mục giữ đường dẫn, kích thước, SHA-256; tổng kiểm tra lệch được báo khi đọc.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-016 · BR-18-014 · ERR-18-104 · UI-18-03.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-BIG` 300 KB và 100 KB; Garage dev; quyền ghi đối tượng cho kiểm thử viên để làm hỏng đối tượng ở bước 3.

**Các bước.**

1. Đẩy hai bản tin.
2. Kiểm bảng `dlq_payload_ref` và bucket.
3. Sửa một byte của đối tượng trong Garage, U-T90-SO xem payload có lý do.

**Kết quả mong đợi.** Bản tin 100 KB lưu nội tuyến; bản tin 300 KB có đối tượng ở `dh-t90-ops/dlq/...`, chỉ mục có `sizeBytes`, `sha256`. Bước 3 trả ERR-18-104 cho người xem, không trả nội dung, ghi chỉ số lỗi.

**Thông báo hiển thị.** ERR-18-104 (hiện ở màn vận hành, không trả qua HTTP): "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng."
:::

#### TC-18-029 · Bản tin cùng dlqKey chỉ tăng số lần gặp khi mục chưa đóng <!--k:khu-trung-dlqkey-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-015: `dlqKey = sourceCode:flow:messageId:stage`; mục chưa đóng cùng khóa tăng `occurrences`, mục đã đóng ngoài `18.dlq.dedup-window-days` tạo mục mới.

**Loại.** Biên, Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-016, 013 · BR-18-015 · ERR-18-105.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); mục `DLQ-A-01` `NEW` khóa `SRC-PH04:thue-dong-bo:m-001:transform`.

**Các bước.**

1. Đẩy lại bản tin `m-001` cùng bước ba lần.
2. Bỏ qua mục, tua 8 ngày, đẩy lại lần nữa.
3. Đẩy bản tin thiếu `dh-message-id` hai lần cùng thân.

**Kết quả mong đợi.** Bước 1 vẫn một mục, `occurrences = 4`, ghi ERR-18-105 ở nhật ký worker. Bước 2 tạo mục mới, mục cũ giữ `DISCARDED`. Bước 3 hai lần cùng băm SHA-256 thân nên chỉ một mục.

**Thông báo hiển thị.** ERR-18-105 (hiện ở màn vận hành, không trả qua HTTP): "Bản tin trùng mục đang mở; đã tăng số lần gặp."
:::

#### TC-18-030 · Đối soát chỉ mục với Kafka bù mục thiếu và không chạy chồng <!--k:doi-soat-kafka-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-018: đối soát theo phân vùng phát hiện mục thiếu, bù vào chỉ mục, phát EVT-18-08 `RECONCILE_MISSING`; lần chạy thứ hai khi lần đầu chưa xong bị từ chối.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT, API.

**Truy vết.** FR-18-018 · API-18-037, 038 · BR-18-011, 015 · ERR-18-006 · EVT-18-08 · NFR-18-021 · UI-18-06.

**Tiền điều kiện, dữ liệu.** T90; xóa cưỡng bức 3 dòng `dlq_message` bằng vai chủ ở CSDL TEST để giả lập thiếu; U-PA1.

**Các bước.**

1. U-PA1 `POST /dlq/reconciliation:run`.
2. Gọi lại ngay khi lần 1 đang chạy.
3. `GET /dlq/reconciliation`.

**Kết quả mong đợi.** Bước 1 `202`. Bước 2 `409` ERR-18-006. Bước 3 kết quả theo phân vùng có `missing = 3`, `backfilled = 3`; sau đối soát số mục thiếu bằng 0; EVT-18-08 `type = RECONCILE_MISSING` phát một lần.

**Thông báo hiển thị.** ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

### TS-18-10 · Phân hệ ghi mục DLQ qua API

**Mục tiêu.** Chứng minh phân hệ có `ops:dlq-write` ghi được một mục hoặc lô tới 500 mục kèm ngữ cảnh chuẩn, thiếu ngữ cảnh, payload quá lớn, nguồn chưa đăng ký hay tenant giả mạo đều bị chặn.

**Phủ.** FR-18-014, 015, 016; API-18-035, 036; BR-18-011, 013, 014, 015; ERR-18-024, 025, 026; EVT-18-05.

#### TC-18-031 · PH-19 ghi một mục và một lô 500 mục DLQ qua API <!--k:ghi-dlq-api-duong-->

::: dac-ta
**Mục đích.** Chứng minh đường ghi DLQ qua API cho nguồn không dùng Kafka: kết quả theo từng mục, khử trùng giống đường topic.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-014, 016 · API-18-035, 036 · BR-18-014, 015 · EVT-18-05 · UI-18-01.

**Tiền điều kiện, dữ liệu.** T90; S-PH19 (`ops:dlq-write`), `SRC-PH19` `ACTIVE`; lô `DLQ-PH19-500` có 2 mục trùng `dlqKey` và 3 mục payload 300 KB.

**Các bước.**

1. S-PH19 `POST /ops/internal/v1/dlq/messages` một mục `reason = TARGET_UNAVAILABLE`.
2. S-PH19 `POST /ops/internal/v1/dlq/messages:batch` với 500 mục.
3. Gọi lại bước 1 cùng `Idempotency-Key`.

**Kết quả mong đợi.** Bước 1 `201` `dlqId`, `status = NEW`. Bước 2 `200`, 499 mục `CREATED`, 1 mục `DEDUPLICATED`, 3 mục có payload ở Garage. Bước 3 `200` trả cùng `dlqId`. EVT-18-05 có số đếm đúng.
:::

#### TC-18-032 · Thiếu ngữ cảnh, payload quá 20 MB, nguồn chưa đăng ký, thiếu scope, tenant giả mạo <!--k:ghi-dlq-api-loi-->

::: dac-ta
**Mục đích.** Chứng minh API ghi DLQ kiểm đủ điều kiện trước khi nhận và không cho danh tính của tenant khác ghi vào T90.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-014, 015 · API-18-035 · BR-18-013, 014 · ERR-18-024, 025, 026 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** T90; S-PH19; S-NOSCOPE; S-T91-PH19 (SPIFFE của T91); `18.dlq.payload.max-mb = 20`.

**Các bước.**

1. S-PH19 ghi mục thiếu `stage`.
2. S-PH19 ghi mục payload 21 MB.
3. S-PH19 ghi với `sourceCode = SRC-LA`.
4. S-NOSCOPE ghi mục hợp lệ.
5. S-T91-PH19 ghi mục có `tenant = T90`.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-024 nêu trường `stage` (API khác topic: thiếu ngữ cảnh bị từ chối thay vì thành `POISON`). Bước 2 `413` ERR-18-025. Bước 3 `403` ERR-18-026. Bước 4 `403` ERR-00-403. Bước 5 `403` ERR-00-403, không có mục ở T90.

**Thông báo hiển thị.** ERR-18-024: "Thiếu trường ngữ cảnh bắt buộc: {trường}." ERR-18-025: "Nội dung bản tin vượt {MB} MB. Lưu nội dung ở nguồn và gửi tham chiếu." ERR-18-026: "Nguồn {mã} chưa được đăng ký hoặc đang tạm ngừng ghi DLQ."
:::

#### TC-18-033 · Lô có mục thiếu trường "nên có" vẫn nhận, mục thiếu trường bắt buộc trong lô bị báo theo mục <!--k:ghi-dlq-poison-api-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-015 trên đường API: thiếu `traceId` hoặc `messageId` vẫn nhận (dùng băm), mục thiếu trường bắt buộc trong lô bị từ chối riêng, các mục khác vẫn vào.

**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-015, 014 · API-18-036 · BR-18-013, 015 · ERR-18-024.

**Tiền điều kiện, dữ liệu.** T90; S-PH19; lô 10 mục: 2 thiếu `traceId`, 1 thiếu `messageId`, 1 thiếu `errorCode`.

**Các bước.**

1. S-PH19 gửi lô.
2. Mở chi tiết mục thiếu `traceId` ở UI-18-03.

**Kết quả mong đợi.** Bước 1 `200`; 9 mục `CREATED`, mục thiếu `errorCode` có `result = REJECTED` kèm ERR-18-024. Bước 2 mục hiện "Không có ngữ cảnh chẩn đoán" thay cho khung PH-13.

**Thông báo hiển thị.** ERR-18-024: "Thiếu trường ngữ cảnh bắt buộc: {trường}."
:::

### TS-18-11 · Xem và đề nghị phát lại DLQ tầng sự kiện của PH-10

**Mục tiêu.** Chứng minh PH-18 hiển thị chung mục DLQ tầng sự kiện của PH-10 qua API-10, không sao chép nội dung, đề nghị phát lại đi qua PH-10 và vẫn hoạt động khi PH-10 vắng.

**Phủ.** FR-18-017; API-18-039, 040; BR-18-016, 019; ERR-18-035.

#### TC-18-034 · Xem siêu dữ liệu DLQ tầng sự kiện và đề nghị PH-10 phát lại <!--k:dlq-ph10-duong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-016: chỉ siêu dữ liệu được hiển thị, nội dung không vào `ph18_ops`, đề nghị phát lại gọi API-10-061 bằng scope `event:replay`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-017 · API-18-039, 040 · BR-18-016, 019 · UI-18-01.

**Tiền điều kiện, dữ liệu.** T90; WireMock PH-10 trả 5 mục cho API-10-060; U-T90-TO.

**Các bước.**

1. U-T90-TO mở UI-18-01 tab "Tầng sự kiện".
2. `POST /dlq/event-dead-letters/{entryRef}:request-replay`.
3. Kiểm bảng `dlq_message` và Garage của T90.

**Kết quả mong đợi.** Bước 1 5 dòng có nhãn nguồn PH-10, chỉ siêu dữ liệu. Bước 2 `202`, WireMock nhận đúng một lời gọi tới API-10-061 với `entryRef`. Bước 3 không có dòng hay đối tượng nào mang nội dung của mục PH-10.
:::

#### TC-18-035 · PH-10 không phản hồi thì tab tầng sự kiện báo lỗi, danh sách DLQ của PH-18 vẫn dùng được <!--k:dlq-ph10-vang-->

::: dac-ta
**Mục đích.** Chứng minh fail-soft khi PH-10 vắng: lỗi chỉ ở phần liên thông, không chặn danh sách chính.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-18-017, 019 · API-18-039, 040, 041 · ERR-18-035 · UI-18-01.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-10 trễ 10 giây rồi ngắt.

**Các bước.**

1. `GET /dlq/event-dead-letters`.
2. Đề nghị phát lại một mục PH-10.
3. `GET /dlq/messages`.

**Kết quả mong đợi.** Bước 1 và 2 `503` ERR-18-035. Bước 3 `200` bình thường; UI-18-01 hiện dải cảnh báo ở tab tầng sự kiện, các tab khác không bị ảnh hưởng.

**Thông báo hiển thị.** ERR-18-035: "Chưa lấy được dữ liệu từ phân hệ sự kiện. Thử lại sau."
:::

### TS-18-12 · Lọc, gom nhóm, phân loại và gán người xử lý mục DLQ

**Mục tiêu.** Chứng minh người vận hành lọc, tìm, gom nhóm theo dấu hiệu lỗi, phân loại và gán người xử lý cho từng mục hoặc hàng loạt, có `If-Match`, kiểm toán và sự kiện đổi trạng thái; danh sách chỉ trả mục của tenant mình.

**Phủ.** FR-18-019, 020, 023; API-18-041…044, 049, 050, 051, 063; BR-18-032, 046, 047; ERR-18-003, 004, 006, 008; EVT-18-07.

#### TC-18-036 · Lọc theo nguồn, mã lỗi, lớp lỗi, tuổi; khối facets và xuất CSV chỉ siêu dữ liệu <!--k:dlq-loc-tim-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-019: bộ lọc kết hợp trả đúng tập, `facets` đếm theo từng chiều, xuất CSV không có cột payload.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-019 · API-18-041, 042 · BR-18-047 · UI-18-01.

**Tiền điều kiện, dữ liệu.** T90 với `DLQ-SET-A` (200 mục: 5 nguồn, 4 lớp lỗi, 6 trạng thái, tuổi 1 giờ đến 40 ngày); U-T90-TO.

**Các bước.**

1. `GET /dlq/messages?nguon=SRC-PH04&lopLoi=TRANSIENT&trangThai=NEW&tuoiTu=24h&page=0&size=50`.
2. Tìm theo `q=ERR-04-101` và theo `traceId`.
3. `GET /dlq/messages:export` với bộ lọc bước 1.
4. Mở `/van-hanh/dlq?nguon=SRC-PH04` trên UI-18-01, đổi bộ lọc và tải lại trang.

**Kết quả mong đợi.** Bước 1 `200`, đúng số mục theo bảng dữ liệu, sắp mặc định theo tuổi giảm dần, `facets` đủ các chiều. Bước 2 trả đúng mục. Bước 3 CSV có `dlqId`, nguồn, luồng, mã lỗi, lớp lỗi, trạng thái, thời điểm; không có cột nội dung. Bước 4 bộ lọc giữ trên URL, dải bốn thẻ số hiện đúng.
:::

#### TC-18-037 · Bộ lọc sai và mục của tenant khác không xuất hiện <!--k:dlq-loc-loi-cheo-tenant-->

::: dac-ta
**Mục đích.** Chứng minh lọc sai bị chặn rõ ràng và RLS bảo đảm không mục nào của T91 lọt vào kết quả, kể cả khi đoán `dlqId`.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-019, 021 · API-18-041, 045 · BR-18-047 · ERR-18-003, 001 · NFR-18-017.

**Tiền điều kiện, dữ liệu.** T90, T91 cùng có mục mã lỗi `ERR-04-101`; `DLQ-T91-07` thuộc T91; U-T90-TO.

**Các bước.**

1. `GET /dlq/messages?trangThai=KHONG_CO&size=500`.
2. `GET /dlq/messages?q=ERR-04-101`.
3. `GET /dlq/messages/DLQ-T91-07`.

**Kết quả mong đợi.** Bước 1 `400` ERR-18-003 nêu `trangThai` và `size`. Bước 2 chỉ mục của T90. Bước 3 `404` ERR-18-001, thân giống hệt mục không tồn tại trừ `traceId`.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

#### TC-18-038 · Gom nhóm theo dấu hiệu lỗi và gán người xử lý cho cả nhóm <!--k:dlq-gom-nhom-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-020: mục cùng nguồn, luồng, mã lỗi, bước trong `18.dlq.group.window-hours` gom một nhóm; gán nhóm áp cho mọi mục mở của nhóm.

**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API, E2E.

**Truy vết.** FR-18-020, 023 · API-18-043, 044 · ERR-18-006 · EVT-18-07 · UI-18-02.

**Tiền điều kiện, dữ liệu.** T90; 120 mục `ERR-04-101` của `SRC-PH04` trong 24 giờ, 15 mục `ERR-19-004` của `SRC-PH19`; nhóm `GRP-OLD` đã đóng.

**Các bước.**

1. U-T90-TO mở `/van-hanh/dlq?tab=nhom`.
2. `POST /dlq/groups/{groupId}:assign` người xử lý U-T90-IE, ưu tiên `HIGH`.
3. `POST /dlq/groups/GRP-OLD:assign`.

**Kết quả mong đợi.** Bước 1 hai nhóm, số mục 120 và 15, tuổi cũ nhất, nguồn. Bước 2 `200`, 120 mục có người xử lý và ưu tiên mới, mỗi mục một bản ghi kiểm toán. Bước 3 `409` ERR-18-006.

**Thông báo hiển thị.** ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

#### TC-18-039 · Phân loại, gán, nhận việc từng mục và hàng loạt 1.000 mục; lỗi trạng thái, ETag, kiểm toán <!--k:dlq-phan-loai-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-023: `NEW` sang `TRIAGED` có EVT-18-07 và kiểm toán trước; hàng loạt tối đa 1.000 mục; mục đã đóng không phân loại lại; PH-13 không ghi được kiểm toán thì từ chối.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-023 · API-18-049, 050, 051, 063 · BR-18-032, 046 · ERR-18-003, 004, 006, 008 · EVT-18-07 · UI-18-01, 03.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-02` `NEW`, `DLQ-A-03` `RESOLVED`; 1.001 mục `NEW`; U-T90-TO; WireMock PH-13 bật lỗi ở bước 6.

**Các bước.**

1. `POST /dlq/messages/DLQ-A-02:triage` lớp `BUSINESS`, ưu tiên `HIGH`, ghi chú, `If-Match`.
2. `POST /dlq/messages/DLQ-A-02:assign` cho chính mình.
3. `POST /dlq/messages:bulk-triage` 1.000 mục rồi 1.001 mục.
4. `POST /dlq/messages/DLQ-A-03:triage`.
5. Gửi lại bước 1 với `ETag` cũ.
6. Bật lỗi PH-13, phân loại một mục `NEW` khác.

**Kết quả mong đợi.** Bước 1 `200` `TRIAGED`, EVT-18-07 `from = NEW`, `to = TRIAGED`; `GET /dlq/messages/DLQ-A-02/audit` có dòng triage. Bước 2 `200`. Bước 3 lần đầu `200` 1.000 kết quả, lần hai `400` ERR-18-003. Bước 4 `409` ERR-18-006. Bước 5 `412` ERR-18-004. Bước 6 `503` ERR-18-008, mục vẫn `NEW`.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}." ERR-18-004: "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu." ERR-18-008: "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
:::

### TS-18-13 · Xem chi tiết, ngữ cảnh chẩn đoán và nội dung mục DLQ có lý do

**Mục tiêu.** Chứng minh chi tiết mục có ngữ cảnh chẩn đoán của PH-13 và trả một phần khi PH-13 vắng; xem payload cần quyền riêng, lý do, kiểm toán trước, phiếu xem có hạn và vẫn che trường đã mã hóa.

**Phủ.** FR-18-021, 022; API-18-045…048, 058; BR-18-017, 047; ERR-18-001, 007, 008, 027, 104, 106; ERR-00-403; LGC-NFR-004.

#### TC-18-040 · Chi tiết mục có ngữ cảnh chẩn đoán từ PH-13 và liên kết sổ tay <!--k:dlq-chi-tiet-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-021: chi tiết đủ ngữ cảnh, lịch sử trạng thái, bản sửa, lượt phát lại; khung chẩn đoán lấy từ API-13-069 theo `traceId`; mã lỗi có liên kết sổ tay.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-021, 025 · API-18-045, 046, 058 · LGC-NFR-004 · UI-18-03.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-02` có `traceId`; WireMock PH-13 trả log và vết đã che cho API-13-069; sổ tay có `ERR-04-101`.

**Các bước.**

1. U-T90-TO `GET /dlq/messages/DLQ-A-02`.
2. `GET /dlq/messages/DLQ-A-02/diagnostics`.
3. Mở `/van-hanh/dlq/DLQ-A-02`.

**Kết quả mong đợi.** Bước 1 `200` đủ khối ngữ cảnh, phân loại, lịch sử. Bước 2 `200` có log và vết, `partial = false`. Bước 3 ba cột ngữ cảnh, nội dung đã che, lịch sử; mã `ERR-04-101` là liên kết tới sổ tay; payload chưa hiện cho tới khi bấm "Xem nội dung".
:::

#### TC-18-041 · PH-13 quá thời gian thì chẩn đoán trả một phần, mục không tồn tại trả 404 <!--k:dlq-chan-doan-vang-->

::: dac-ta
**Mục đích.** Chứng minh fail-soft của chẩn đoán: quá `18.dlq.diagnostics.timeout-ms` thì chi tiết vẫn hiện, khung chẩn đoán báo chưa lấy được.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-18-021 · API-18-045, 046 · ERR-18-001, 106 · UI-18-03.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-13 trễ 5 giây; `18.dlq.diagnostics.timeout-ms = 3000`.

**Các bước.**

1. `GET /dlq/messages/DLQ-A-02/diagnostics`.
2. Mở UI-18-03 của mục.
3. `GET /dlq/messages/DLQ-KHONG-CO`.

**Kết quả mong đợi.** Bước 1 `200` sau ≤ 3,5 giây, `partial = true`, ghi ERR-18-106. Bước 2 màn hiện câu thông báo ở khung chẩn đoán, các cột khác đủ. Bước 3 `404` ERR-18-001.

**Thông báo hiển thị.** ERR-18-106 (hiện ở màn vận hành, không trả qua HTTP): "Chưa lấy được ngữ cảnh chẩn đoán." ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

#### TC-18-042 · Xem payload có lý do: kiểm toán trước, phiếu 15 phút, trường mã hóa vẫn che <!--k:dlq-xem-payload-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-017: người có `PERM-18-dlq-payload` nhập lý do ≥ 10 ký tự, kiểm toán ghi trước khi trả, phiếu xem hết hạn theo `18.dlq.reveal.ttl-minutes`, trường đã được nguồn mã hóa hiển thị `***`.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-022 · API-18-047, 048 · BR-18-017 · UI-18-03.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); `DLQ-A-04` có trường `soCccd` đã mã hóa ở nguồn và trường `tenDoanhNghiep` rõ; U-T95-SO.

**Các bước.**

1. `GET /dlq/messages/DLQ-A-04/payload/skeleton`.
2. `POST /dlq/messages/DLQ-A-04/payload:reveal` lý do "Đối chiếu hồ sơ lỗi của doanh nghiệp".
3. Tua đồng hồ 16 phút, mở lại nội dung bằng phiếu cũ.

**Kết quả mong đợi.** Bước 1 `200` chỉ tên trường và kiểu. Bước 2 `200` nội dung, `soCccd = "***"`, phiếu hết hạn sau 15 phút; KT: có (payload-reveal) với lý do, thời điểm ghi kiểm toán trước thời điểm trả. Bước 3 phiếu hết hạn, phải nhập lý do lại.
:::

#### TC-18-043 · Thiếu quyền, lý do ngắn, PH-13 không ghi kiểm toán, payload đã hết hạn <!--k:dlq-xem-payload-loi-->

::: dac-ta
**Mục đích.** Chứng minh không có đường xem payload khi thiếu một điều kiện của BR-18-017 hoặc payload đã dọn.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-022 · API-18-047 · BR-18-017, 025 · ERR-18-007, 008, 027 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** T90; U-T90-AU (không có `PERM-18-dlq-payload`), U-T90-SO; `DLQ-A-09` `EXPIRED`; WireMock PH-13 lỗi ở bước 3.

**Các bước.**

1. U-T90-AU gọi `:reveal` có lý do hợp lệ.
2. U-T90-SO gọi với lý do "xem" (4 ký tự).
3. Bật lỗi PH-13, SO gọi với lý do hợp lệ.
4. SO gọi `:reveal` cho `DLQ-A-09`.

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403. Bước 2 `422` ERR-18-007. Bước 3 `503` ERR-18-008, không trả nội dung. Bước 4 `409` ERR-18-027. Không bước nào trả nội dung payload.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)." ERR-18-008: "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau." ERR-18-027: "Nội dung bản tin đã bị xóa do hết hạn lưu giữ. Chỉ còn thông tin mô tả."
:::

### TS-18-14 · Sửa payload có kiểm soát và duyệt bốn mắt

**Mục tiêu.** Chứng minh payload gốc không bao giờ bị sửa, mỗi bản sửa có số thứ tự và khác biệt, bản sửa chạm trường Hạn chế hoặc Nhạy cảm cần người thứ hai duyệt, và phát lại dùng bản sửa đã duyệt với khóa lũy đẳng riêng.

**Phủ.** FR-18-024; API-18-052…056; BR-18-012, 018, 020; ERR-18-005, 007, 029, 030; EVT-18-07; UI-18-04, 15.

#### TC-18-044 · Sửa trường thường không cần duyệt, khác biệt rõ, bản gốc giữ nguyên <!--k:sua-payload-thuong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-012: bản sửa mới `APPROVED` ngay khi không chạm trường Hạn chế, bản gốc trong CSDL và Garage không đổi.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E, DB.

**Truy vết.** FR-18-024 · API-18-052, 053, 054 · BR-18-012 · UI-18-04.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-05` `TRIAGED` có trường `ngayHieuLuc` sai định dạng; U-T90-IE (`PERM-18-dlq-payload`); băm SHA-256 của bản gốc đã ghi lại.

**Các bước.**

1. IE mở `/van-hanh/dlq/DLQ-A-05/sua`, sửa `ngayHieuLuc` theo ISO 8601, lý do "Sửa định dạng ngày theo hợp đồng".
2. `GET /dlq/messages/DLQ-A-05/revisions/1/diff`.
3. Tính lại băm bản gốc.

**Kết quả mong đợi.** Bước 1 `201` bản sửa số 1 `APPROVED`, kiểm lược đồ đạt. Bước 2 khác biệt chỉ một trường. Bước 3 băm bản gốc không đổi; bảng `dlq_message` không có cột nào bị cập nhật nội dung (bộ kiểm `ph18_isolation_test.sql` khối bất biến chạy đạt).
:::

#### TC-18-045 · Bản sửa chạm trường Hạn chế cần TA duyệt, IE tự duyệt bị chặn, bản sửa thứ hai chờ <!--k:sua-payload-han-che-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-018 và LP-18-01: bản sửa chạm trường mức Hạn chế theo PH-09 vào `PENDING_APPROVAL`, việc duyệt hiện cho TA không hiện cho người sửa, người sửa không tự duyệt được.

**Loại.** Âm, Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-024 · API-18-053, 055, 056 · BR-18-018, 046 · ERR-18-005, 030 · EVT-18-07 · UI-18-04, 15.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-06` có trường `diaChiThuongTru` mức Hạn chế (WireMock PH-09); U-T90-IE có cả `PERM-18-approve` để kiểm tách nhiệm vụ; U-T90-TA2.

**Các bước.**

1. IE tạo bản sửa số 1 đổi `diaChiThuongTru`.
2. IE `POST .../revisions/1:approve`.
3. IE tạo bản sửa số 2 khi số 1 còn chờ.
4. TA2 mở việc `ph18.approve-revision` ở `/viec-cua-toi`, duyệt.

**Kết quả mong đợi.** Bước 1 `201` `PENDING_APPROVAL`. Bước 2 `403` ERR-18-005. Bước 3 `409` ERR-18-030. Bước 4 `200` `APPROVED`, mục sang `TRIAGED` nếu đang `POISON`, EVT-18-07; việc không hiện với IE.

**Thông báo hiển thị.** ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt." ERR-18-030: "Mục đã có bản sửa số {n} chờ duyệt. Chờ duyệt xong trước khi sửa tiếp."
:::

#### TC-18-046 · Bản sửa sai lược đồ, thiếu lý do và từ chối bản sửa <!--k:sua-payload-sai-luoc-do-->

::: dac-ta
**Mục đích.** Chứng minh bản sửa phải đúng lược đồ của luồng và có lý do; bản bị từ chối không phát lại được.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-024 · API-18-053, 056, 064 · BR-18-012 · ERR-18-007, 029.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-05`; lược đồ `thue-dong-bo` v3 yêu cầu `maSoThue` 10 hoặc 13 chữ số.

**Các bước.**

1. Tạo bản sửa có `maSoThue = "12AB"`.
2. Tạo bản sửa hợp lệ nhưng lý do rỗng.
3. Tạo bản sửa chạm trường Hạn chế, TA2 `:reject` kèm lý do, rồi `POST /dlq/messages/DLQ-A-05:replay` chọn bản sửa đó.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-029 nêu đường dẫn trường. Bước 2 `422` ERR-18-007. Bước 3 bản sửa `REJECTED`; phát lại chọn bản bị từ chối trả `409` ERR-18-006 và mục vẫn `TRIAGED`.

**Thông báo hiển thị.** ERR-18-029: "Nội dung sửa không đúng lược đồ {lược đồ}: {chi tiết}." ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)." ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

#### TC-18-047 · Sửa mục POISON bổ sung ngữ cảnh thành TRIAGED rồi phát lại được <!--k:sua-poison-->

::: dac-ta
**Mục đích.** Chứng minh mục `POISON` chỉ có hai lối ra: sửa (thành `TRIAGED`) hoặc bỏ qua.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-024, 015, 027 · API-18-053, 064 · BR-18-013, 023 · EVT-18-07.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-P-01` `POISON` thiếu `stage`.

**Các bước.**

1. IE tạo bản sửa bổ sung `stage = transform`, lý do.
2. TO phát lại mục dùng bản sửa 1.

**Kết quả mong đợi.** Bước 1 `201`, mục `TRIAGED`, EVT-18-07 `from = POISON`. Bước 2 `202`, khóa lũy đẳng `DLQ-P-01:1`.
:::

### TS-18-15 · Biên soạn sổ tay xử lý theo mã lỗi và cấp API đọc cho PH-17

**Mục tiêu.** Chứng minh PH-17 và PH-13 đọc được siêu dữ liệu DLQ và sổ tay bằng token đổi từ người dùng, không có thao tác ghi, payload chỉ khi người dùng có quyền xem payload và bị giới hạn tần suất.

**Phủ.** FR-18-025, 026; API-18-060, 061, 062; BR-18-016, 017, 050; ERR-18-010; ERR-00-403.

#### TC-18-048 · Soạn sổ tay xử lý theo mã lỗi có ETag và sự kiện cho PH-17 <!--k:so-tay-loi-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-025: hướng dẫn theo mã ERR có phiên bản, sửa có `If-Match`, phát EVT-18-11, không chứa payload hay dữ liệu cá nhân.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-18-025 · API-18-057, 058, 059 · BR-18-050 · ERR-18-003, 004 · EVT-18-11 · UI-18-07.

**Tiền điều kiện, dữ liệu.** T90; U-PA1 (`PERM-18-admin`); sổ tay `ERR-04-101` phiên bản 2.

**Các bước.**

1. `PUT /error-guides/ERR-04-101` nội dung mới, có `If-Match`.
2. Gửi lại với `ETag` cũ.
3. Gửi nội dung có chuỗi giống CCCD `"012345678901"`.
4. Mở `/van-hanh/dlq/so-tay`, tìm `ERR-04-101`.

**Kết quả mong đợi.** Bước 1 `200` phiên bản 3, EVT-18-11 có `errorCode`, `version`, `owner`. Bước 2 `412` ERR-18-004. Bước 3 `400` ERR-18-003 (bộ kiểm DLCN của sổ tay). Bước 4 hiện phiên bản 3 có nguyên nhân, bước xử lý, "có phát lại được".

**Thông báo hiển thị.** ERR-18-004: "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}."
:::

#### TC-18-049 · PH-17 đọc siêu dữ liệu DLQ và nguồn tri thức sổ tay <!--k:api-doc-ph17-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-026: scope `ops:dlq-read` với token đổi từ người dùng trả siêu dữ liệu trong phạm vi quyền của người đó, sổ tay đọc theo `updatedSince`.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-026, 025 · API-18-060, 061, 062 · BR-18-016, 050.

**Tiền điều kiện, dữ liệu.** T90; S-PH17 (`ops:dlq-read`); token đổi của U-T90-TO và U-T90-VW.

**Các bước.**

1. S-PH17 `GET /ops/internal/v1/dlq/messages?trangThai=NEW` với token của TO.
2. S-PH17 `GET /ops/internal/v1/dlq/messages/DLQ-A-02` với token của TO.
3. `GET /ops/internal/v1/error-guides:feed?updatedSince=...`.
4. Lặp bước 1 với token của VW.

**Kết quả mong đợi.** Bước 1, 2 `200` chỉ siêu dữ liệu, không có `payload`. Bước 3 `200` các mục sổ tay có `errorCode`, `version`, không chứa payload. Bước 4 `403` ERR-00-403 vì VW không xem danh sách mục.
:::

#### TC-18-050 · PH-17 thử ghi, đọc payload khi người dùng thiếu quyền, vượt tần suất <!--k:api-doc-ph17-loi-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-016, 017 trên API nội bộ: không có phương thức ghi, payload chỉ khi người dùng có `PERM-18-dlq-payload`, giới hạn tần suất bảo vệ PH-18.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-026 · API-18-061 · BR-18-016, 017 · ERR-18-010 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** T90; S-PH17; token của U-T90-TO (có `PERM-18-dlq-payload`) và U-T90-AU (không có).

**Các bước.**

1. S-PH17 gọi `POST /ops/internal/v1/dlq/messages/DLQ-A-02:discard`.
2. S-PH17 đọc chi tiết kèm `include=payload` với token AU.
3. Lặp với token TO.
4. S-PH17 gửi 200 yêu cầu trong một giây.

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403 (không có quyền ghi với scope này). Bước 2 `403` ERR-00-403. Bước 3 `200` có payload đã che, KT: có (payload-reveal) với `act = PH-17`. Bước 4 có `429` ERR-18-010.

**Thông báo hiển thị.** ERR-18-010: "Quá nhiều yêu cầu. Thử lại sau {giây} giây."
:::

#### TC-18-051 · Đổi sổ tay làm PH-17 cập nhật tri thức, sổ tay của mã lạ trả 404 <!--k:so-tay-feed-tri-thuc-->

::: dac-ta
**Mục đích.** Chứng minh EVT-18-11 dẫn tới feed trả bản mới và mã lỗi chưa có hướng dẫn trả lỗi rõ.

**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API, KT.

**Truy vết.** FR-18-025 · API-18-058, 062 · EVT-18-11 · ERR-18-001.

**Tiền điều kiện, dữ liệu.** T90; sổ tay `ERR-04-101` vừa lên phiên bản 3.

**Các bước.**

1. Đọc `t90.ops.error-guide.changed.v1`.
2. S-PH17 gọi feed với `updatedSince` trước thời điểm đổi.
3. `GET /error-guides/ERR-99-999`.

**Kết quả mong đợi.** Bước 1 có bản tin mã `ERR-04-101`, `version = 3`. Bước 2 có bản mới. Bước 3 `404` ERR-18-001.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

### TS-18-16 · Phát lại một mục DLQ và nhận kết quả lũy đẳng

**Mục tiêu.** Chứng minh phát lại luôn đi qua cổng của nguồn với khóa `dlqId:revision`, gọi lại cùng khóa không tạo xử lý trùng, kết quả đến muộn được ghi đúng một lần, và mọi lỗi của cổng nguồn được ghi vào trạng thái mục.

**Phủ.** FR-18-027, 030; API-18-064, 076, 188; BR-18-019, 020, 023; ERR-18-028, 031, 033, 038, 107, 108, 109; EVT-18-07, 09.

#### TC-18-052 · Phát lại một mục qua topic của PH-04 và nhận kết quả thành công <!--k:phat-lai-mot-muc-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-019: mục của nguồn `KAFKA_TOPIC` được phát lại bằng EVT-18-09 tới lối vào của PH-04, PH-18 không gọi hệ đích; kết quả callback đưa mục sang `RESOLVED`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT, KT.

**Truy vết.** FR-18-027, 030 · API-18-064, 076 · BR-18-019, 020 · EVT-18-07, 09 · UI-18-03.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-02` `TRIAGED` nguồn `SRC-PH04`; S-PH04 (`ops:replay-callback`); WireMock hệ đích của luồng đếm lời gọi.

**Các bước.**

1. U-T90-TO `POST /dlq/messages/DLQ-A-02:replay` (bản gốc), `Idempotency-Key`.
2. Đọc `t90.ops.replay.requested.v1`.
3. S-PH04 `POST /ops/internal/v1/replay-results` `idempotencyKey = DLQ-A-02:0`, `result = SUCCEEDED`.
4. Mở UI-18-03 của mục.

**Kết quả mong đợi.** Bước 1 `202`, mục `REPLAY_PENDING` rồi `REPLAYING`. Bước 2 một bản tin EVT-18-09 có `dlqId`, `revision = 0`, `idempotencyKey`, `payloadRef`. Bước 3 `200`, mục `RESOLVED`, EVT-18-07. WireMock hệ đích nhận 0 lời gọi từ PH-18 (chỉ PH-04 gọi). Bước 4 lịch sử có lượt phát lại và kết quả.
:::

#### TC-18-053 · Gọi phát lại hai lần, callback lặp và kết quả đến sau khi quá hạn <!--k:phat-lai-luy-dang-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-020 và ĐN-UC-15: cùng khóa `dlqId:revision` không tạo xử lý trùng ở nguồn; kết quả cuối của một khóa chỉ ghi một lần; kết quả đến muộn sau `18.dlq.replay.result-timeout-minutes` vẫn được nhận một lần.

**Loại.** Lũy đẳng, Biên.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-030, 027 · API-18-064, 076 · BR-18-020 · ERR-18-109 · EVT-18-07, 09.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); `DLQ-A-07` `TRIAGED`; WireMock PH-04 lưu khóa đã xử lý (giả lập 30 ngày); `18.dlq.replay.result-timeout-minutes = 30`.

**Các bước.**

1. TO phát lại `DLQ-A-07` hai lần liên tiếp cùng `Idempotency-Key`, rồi lần ba khóa khác khi mục đang `REPLAYING`.
2. Tua đồng hồ 31 phút không có callback.
3. S-PH04 gửi callback `SUCCEEDED` cho `DLQ-A-07:0`, rồi gửi lại `FAILED` cùng khóa.

**Kết quả mong đợi.** Bước 1 lần hai trả cùng kết quả `202`, chỉ một EVT-18-09; lần ba `409` ERR-18-031. Bước 2 mục `REPLAY_FAILED` ghi ERR-18-109, lượt có cờ `timedOut`. Bước 3 callback đầu ghi `RESOLVED` (kết quả muộn được nhận); callback hai `200` `duplicate = true`, trạng thái không đổi; nguồn chỉ xử lý một lần.

**Thông báo hiển thị.** ERR-18-031: "Mục đang được phát lại trong lượt {mã}." ERR-18-109 (hiện ở màn vận hành, không trả qua HTTP): "Chưa nhận kết quả phát lại sau {n} phút."
:::

#### TC-18-054 · Phát lại mục POISON, mục đang trong lượt khác, nguồn không có cổng <!--k:phat-lai-loi-->

::: dac-ta
**Mục đích.** Chứng minh các điều kiện chặn phát lại ở FR-18-027.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-027 · API-18-064 · BR-18-023, 019 · ERR-18-028, 031, 033.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-P-02` `POISON`; `DLQ-A-08` thuộc lượt `RJ-01` đang chạy; `DLQ-PH08-1` của nguồn cổng `NONE`.

**Các bước.**

1. Phát lại `DLQ-P-02`.
2. Phát lại `DLQ-A-08`.
3. Phát lại `DLQ-PH08-1`.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-028. Bước 2 `409` ERR-18-031 nêu mã lượt. Bước 3 `409` ERR-18-033. Không có EVT-18-09.

**Thông báo hiển thị.** ERR-18-028: "Bản tin thiếu ngữ cảnh nên không phát lại được. Sửa nội dung hoặc bỏ qua." ERR-18-031: "Mục đang được phát lại trong lượt {mã}." ERR-18-033: "Nguồn {mã} chưa có cổng phát lại hoặc đang tạm ngừng."
:::

#### TC-18-055 · Cổng HTTP của PH-19 từ chối, quá thời gian và callback sai danh tính <!--k:phat-lai-cong-nguon-->

::: dac-ta
**Mục đích.** Chứng minh lỗi của cổng nguồn được ghi vào trạng thái mục với mã worker, và chỉ nguồn của mục mới báo kết quả được.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-027, 030 · API-18-064, 076 · BR-18-019, 020 · ERR-18-038, 107, 108.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-PH19-1` nguồn `SRC-PH19` cổng `HTTP_PORT`; WireMock cổng PH-19 lần lượt trả `422`, trễ 40 giây; S-PH04 (khác nguồn).

**Các bước.**

1. TO phát lại `DLQ-PH19-1` khi cổng trả `422`.
2. TO đưa mục về hàng phát lại, cổng trễ 40 giây.
3. S-PH04 gửi callback cho `DLQ-PH19-1:0`.

**Kết quả mong đợi.** Bước 1 mục `REPLAY_FAILED`, ghi ERR-18-107 kèm lý do của nguồn. Bước 2 ghi ERR-18-108, mục được thử lại theo lịch thử của lượt. Bước 3 `403` ERR-18-038, trạng thái không đổi.

**Thông báo hiển thị.** ERR-18-107 (hiện ở màn vận hành, không trả qua HTTP): "Nguồn từ chối phát lại: {lý do}." ERR-18-108 (hiện ở màn vận hành, không trả qua HTTP): "Nguồn không phản hồi; mục sẽ được thử lại." ERR-18-038: "Danh tính gọi không khớp nguồn của mục."
:::

#### TC-18-056 · Phát lại bằng bản sửa đã duyệt dùng khóa dlqId:revision riêng <!--k:phat-lai-ban-sua-->

::: dac-ta
**Mục đích.** Chứng minh bản gốc và bản sửa có khóa lũy đẳng khác nhau nên nguồn xử lý bản sửa dù bản gốc đã từng phát lại thất bại.

**Loại.** Dương, Lũy đẳng.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-18-027, 024, 030 · API-18-064, 076 · BR-18-020 · EVT-18-09.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-05` có bản sửa 1 `APPROVED`, bản gốc đã `REPLAY_FAILED` với khóa `DLQ-A-05:0`.

**Các bước.**

1. TO phát lại chọn `useRevision = 1`.
2. S-PH04 callback `DLQ-A-05:1` `SUCCEEDED`.

**Kết quả mong đợi.** Bước 1 EVT-18-09 có `revision = 1`, `idempotencyKey = DLQ-A-05:1`. Bước 2 mục `RESOLVED`.
:::

#### TC-18-165 · Nguồn cổng KAFKA_TOPIC lấy nội dung phát lại theo payloadRef, danh tính sai bị từ chối <!--k:phat-lai-lay-noi-dung-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-027 bước 3: nguồn `KAFKA_TOPIC` lấy đúng bản cần phát lại qua API-18-188, bản gốc khi `revision = 0`, chỉ nguồn của mục được đọc.

**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-027, 028 · API-18-188 · BR-18-020 · ERR-18-038, 001 · EVT-18-09 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-02` `REPLAYING` nguồn `SRC-PH04` có bản sửa số 1 đã duyệt; S-PH04 (`ops:replay-callback`); S-PH06 (`ops:replay-callback`, nguồn khác); S-NOSCOPE.

**Các bước.**

1. S-PH04 đọc `payloadRef` trong EVT-18-09 rồi `GET /ops/internal/v1/replay-payloads/DLQ-A-02/1`.
2. S-PH04 `GET .../DLQ-A-02/0`.
3. S-PH06 `GET .../DLQ-A-02/1`.
4. S-NOSCOPE `GET .../DLQ-A-02/1`.
5. S-PH04 `GET .../DLQ-A-02/9`.

**Kết quả mong đợi.** Bước 1 `200` nội dung bản sửa số 1, băm khớp `payload_hash` của bản sửa; payload lớn trả `downloadUrl` có hạn thay cho `payload`. Bước 2 `200` bản gốc. Bước 3 `403` ERR-18-038. Bước 4 `403` ERR-00-403. Bước 5 `404` ERR-18-001. Không bước nào ghi nội dung vào nhật ký ứng dụng.

**Thông báo hiển thị.** ERR-18-038: "Danh tính gọi không khớp nguồn của mục." ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

### TS-18-17 · Phát lại loạt có duyệt bốn mắt và điều khiển lượt

**Mục tiêu.** Chứng minh lượt phát lại loạt dưới ngưỡng chạy ngay, vượt `18.dlq.replay.approval-threshold` cần bốn mắt, vượt `18.dlq.replay.batch-max` bị từ chối, tốc độ không vượt trần, tạm dừng, tiếp tục, hủy được và lượt tự dừng khi tỷ lệ lỗi vượt ngưỡng.

**Phủ.** FR-18-028, 029, 030; API-18-065…075; BR-18-021, 022; ERR-18-005, 006, 032, 036, 037; EVT-18-10; UI-18-05, 15.

#### TC-18-057 · Lượt 50 mục theo bộ lọc dưới ngưỡng chạy ngay và hoàn tất <!--k:luot-duoi-nguong-->

::: dac-ta
**Mục đích.** Chứng minh lượt dưới ngưỡng không cần duyệt, danh sách mục chốt lúc tạo, tiến độ theo từng mục, EVT-18-10 theo từng lần đổi trạng thái.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-028, 030 · API-18-065, 066, 067, 068, 069 · BR-18-021 · EVT-18-10 · UI-18-05.

**Tiền điều kiện, dữ liệu.** T90; 50 mục `TRIAGED` của `SRC-PH04` mã `ERR-04-101`; `18.dlq.replay.approval-threshold = 500`; WireMock PH-04 trả thành công.

**Các bước.**

1. TO `POST /replay-jobs` theo bộ lọc nguồn và mã lỗi.
2. `POST /replay-jobs/{jobId}:submit`.
3. Theo dõi `/van-hanh/dlq/phat-lai/{jobId}`.

**Kết quả mong đợi.** Bước 1 `201` `DRAFT`, `total = 50`. Bước 2 `200` `RUNNING`. Bước 3 tiến độ tăng, kết thúc `COMPLETED`, `succeeded = 50`; EVT-18-10 cho `DRAFT → RUNNING → COMPLETED`.
:::

#### TC-18-058 · Lượt 800 mục vượt ngưỡng chờ duyệt, người tạo tự duyệt bị chặn, danh sách kiểm lại khi duyệt <!--k:luot-bon-mat-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-021 và LP-18-01: lượt vượt ngưỡng vào `PENDING_APPROVAL`, người tạo không duyệt được, khi duyệt mục đã đổi trạng thái bị loại khỏi lượt.

**Loại.** Âm, Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-028 · API-18-069, 070, 071 · BR-18-021, 046 · ERR-18-005 · EVT-18-10 · UI-18-05, 15.

**Tiền điều kiện, dữ liệu.** T90; 800 mục `TRIAGED`; U-T90-TO có cả `PERM-18-approve` để kiểm tách nhiệm vụ; U-T90-TA2.

**Các bước.**

1. TO tạo lượt 800 mục và gửi.
2. TO `POST /replay-jobs/{jobId}:approve`.
3. Trong lúc chờ, bỏ qua 20 mục của lượt.
4. TA2 duyệt từ việc ở `/viec-cua-toi`.

**Kết quả mong đợi.** Bước 1 `200` `PENDING_APPROVAL`. Bước 2 `403` ERR-18-005. Bước 4 `200` `APPROVED` rồi `RUNNING`, `total = 780`, 20 mục ghi `SKIPPED`; việc duyệt không hiện cho TO.

**Thông báo hiển thị.** ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

#### TC-18-059 · Lượt vượt số mục tối đa, bộ lọc rỗng, tốc độ vượt trần <!--k:luot-gioi-han-->

::: dac-ta
**Mục đích.** Chứng minh giới hạn cứng của lượt phát lại.

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-028, 029 · API-18-065, 075 · BR-18-021, 022 · ERR-18-032, 036, 037.

**Tiền điều kiện, dữ liệu.** T92 với `18.dlq.replay.batch-max = 100`; 101 mục `TRIAGED`; trần nguồn `SRC-PH04` 50 mục mỗi giây.

**Các bước.**

1. Tạo lượt 101 mục.
2. Tạo lượt bộ lọc không khớp mục nào.
3. Tạo lượt 100 mục rồi `PATCH /replay-jobs/{jobId}` tốc độ 80.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-032. Bước 2 `422` ERR-18-036. Bước 3 `422` ERR-18-037.

**Thông báo hiển thị.** ERR-18-032: "Lượt có {n} mục, vượt giới hạn {tối đa}. Thu hẹp bộ lọc hoặc chia thành nhiều lượt." ERR-18-036: "Không có mục nào phù hợp để {thao tác}." ERR-18-037: "Tốc độ {n} mục mỗi giây vượt giới hạn {trần} của nguồn {mã}."
:::

#### TC-18-060 · Tạm dừng, tiếp tục, đổi tốc độ, hủy lượt; hủy lượt đã xong bị chặn <!--k:luot-dieu-khien-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-029: điều khiển lượt có hiệu lực trong lô kế tiếp, hủy đưa mục chưa chạy về `TRIAGED`, thao tác khẩn ghi kiểm toán trễ qua outbox.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-029 · API-18-072, 073, 074, 075 · BR-18-022, 046 · ERR-18-006 · EVT-18-10 · NFR-18-006.

**Tiền điều kiện, dữ liệu.** T90; lượt `RJ-02` 1.000 mục `RUNNING` tốc độ 10 mục mỗi giây; lượt `RJ-03` `COMPLETED`.

**Các bước.**

1. `:pause`, chờ 10 giây, đếm mục đã gửi.
2. `PATCH` tốc độ 20 kèm `If-Match`, `:resume`.
3. `:cancel` lượt `RJ-02`.
4. `:cancel` lượt `RJ-03`.

**Kết quả mong đợi.** Bước 1 `PAUSED`, số mục gửi không tăng sau lô hiện hành. Bước 2 tốc độ đo được 20 ± 10%. Bước 3 `CANCELLED`, mục chưa chạy về `TRIAGED`. Bước 4 `409` ERR-18-006. EVT-18-10 cho mỗi lần đổi.

**Thông báo hiển thị.** ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

#### TC-18-061 · Lượt tự dừng khi tỷ lệ lỗi vượt 20 % và kết thúc PARTIAL <!--k:luot-tu-dung-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-022: lượt dừng khi tỷ lệ lỗi vượt `18.dlq.threshold.replay-failure-percent`, phát EVT-18-08 `REPLAY_FAILURE_RATE`.

**Loại.** Biên, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-029, 030 · BR-18-022 · EVT-18-08, 10.

**Tiền điều kiện, dữ liệu.** T90; lượt 200 mục; WireMock PH-04 trả thất bại cho 30 % mục từ mục thứ 50.

**Các bước.**

1. Chạy lượt.
2. Tiếp tục lượt sau khi chỉnh WireMock thành công rồi để chạy xong.

**Kết quả mong đợi.** Bước 1 lượt `PAUSED` khi tỷ lệ lỗi cửa sổ trượt vượt 20 %, EVT-18-08 phát. Bước 2 kết thúc `PARTIAL` với số thành công, thất bại đúng; mục lỗi `REPLAY_FAILED`.
:::

### TS-18-18 · Bỏ qua và mở lại mục DLQ

**Mục tiêu.** Chứng minh bỏ qua cần mã lý do và mô tả từ 10 ký tự, có bỏ qua hàng loạt; mục `DISCARDED` mở lại được tới khi hết hạn lưu giữ.

**Phủ.** FR-18-031, 032; API-18-077, 078, 079; BR-18-023, 024; ERR-18-006, 007, 034; EVT-18-07.

#### TC-18-062 · Bỏ qua một mục, hàng loạt 300 mục, mở lại mục đã bỏ qua <!--k:bo-qua-mo-lai-->

::: dac-ta
**Mục đích.** Chứng minh đường bỏ qua và mở lại có sự kiện, kiểm toán, giữ lý do.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-031, 032 · API-18-077, 078, 079 · BR-18-023, 024 · EVT-18-07 · UI-18-01, 03.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-10` `TRIAGED`; 300 mục `TEST_MESSAGE`; U-T90-TO.

**Các bước.**

1. `POST /dlq/messages/DLQ-A-10:discard` mã `HANDLED_AT_SOURCE`, mô tả "Đã nhập tay ở hệ đích".
2. `POST /dlq/messages:bulk-discard` 300 mục mã `TEST_MESSAGE`.
3. `POST /dlq/messages/DLQ-A-10:reopen` kèm lý do.

**Kết quả mong đợi.** Bước 1 `200` `DISCARDED`, EVT-18-07. Bước 2 `200`, 300 mục `DISCARDED`, mỗi mục một bản ghi kiểm toán. Bước 3 `200` `TRIAGED`, lịch sử giữ cả lần bỏ qua.
:::

#### TC-18-063 · Bỏ qua thiếu mô tả, bỏ qua mục đã RESOLVED, mở lại mục không phải DISCARDED <!--k:bo-qua-loi-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện của bỏ qua và mở lại theo máy trạng thái DLQ.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-031, 032 · API-18-077, 079 · BR-18-023, 024 · ERR-18-006, 007.

**Tiền điều kiện, dữ liệu.** T90; `DLQ-A-11` `TRIAGED`, `DLQ-A-03` `RESOLVED`.

**Các bước.**

1. Bỏ qua `DLQ-A-11` mô tả "bỏ" (3 ký tự).
2. Bỏ qua `DLQ-A-03`.
3. Mở lại `DLQ-A-11` đang `TRIAGED`.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-007. Bước 2 `409` ERR-18-006. Bước 3 `409` ERR-18-006.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)." ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

#### TC-18-064 · Mở lại mục đã hết hạn lưu giữ bị từ chối <!--k:mo-lai-het-han-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-024: sau khi mục `EXPIRED` không mở lại được.

**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-032, 033 · API-18-079 · BR-18-024, 025 · ERR-18-034.

**Tiền điều kiện, dữ liệu.** T95; `DLQ-A-12` `DISCARDED` 89 ngày trước.

**Các bước.**

1. Tua đồng hồ 2 ngày, chạy tác vụ dọn.
2. Mở lại `DLQ-A-12`.

**Kết quả mong đợi.** Bước 1 mục `EXPIRED`. Bước 2 `409` ERR-18-034.

**Thông báo hiển thị.** ERR-18-034: "Mục đã hết hạn lưu giữ nên không thể mở lại."
:::

### TS-18-19 · Lưu giữ, dọn, thống kê DLQ và phát sự kiện vượt ngưỡng

**Mục tiêu.** Chứng minh mục đóng giữ payload 90 ngày rồi chỉ còn siêu dữ liệu, mục mở giữ tới khi đóng, mục gắn sự cố mở được hoãn dọn; thống kê và chỉ số Prometheus phát đúng, PH-18 chỉ phát EVT-18-08 chứ không tự làm luật cảnh báo.

**Phủ.** FR-18-033, 034; API-18-080, 081; BR-18-025, 026; ERR-18-003, 104; EVT-18-08; UI-18-06.

#### TC-18-065 · Dọn mục đóng quá 90 ngày, giữ mục mở và mục gắn sự cố mở <!--k:don-luu-giu-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-025: tác vụ dọn xóa payload ở CSDL và Garage của mục đóng quá `18.dlq.retention.closed-days`, giữ siêu dữ liệu, hoãn mục gắn sự cố mở.

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** JOB, DB.

**Truy vết.** FR-18-033 · API-18-080 · BR-18-025 · UI-18-06.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); 10 mục `RESOLVED` đóng 91 ngày trước (3 có payload ở Garage), 1 mục trong số đó liên kết sự cố `INC-T95-01` đang `INVESTIGATING`; 5 mục `NEW` 200 ngày tuổi.

**Các bước.**

1. Chạy tác vụ dọn.
2. `GET /dlq/retention`.
3. Đóng sự cố, chạy lại tác vụ dọn.

**Kết quả mong đợi.** Bước 1 9 mục `EXPIRED`, payload xóa, 2 đối tượng Garage bị xóa; mục gắn sự cố giữ nguyên; 5 mục `NEW` không đổi. Bước 2 số mục sắp hết hạn, lần dọn gần nhất, dung lượng. Bước 3 mục còn lại `EXPIRED`.
:::

#### TC-18-066 · Đối tượng Garage lệch tổng kiểm tra lúc dọn được báo, không xóa nhầm <!--k:don-tong-kiem-tra-lech-->

::: dac-ta
**Mục đích.** Chứng minh tác vụ dọn không im lặng khi đối tượng lệch tổng kiểm tra.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** FR-18-033 · BR-18-014, 025 · ERR-18-104.

**Tiền điều kiện, dữ liệu.** T95; một mục đóng quá hạn có đối tượng Garage bị sửa.

**Các bước.**

1. Chạy tác vụ dọn.

**Kết quả mong đợi.** Mục được dọn chỉ mục, ghi ERR-18-104 và chỉ số lỗi; UI-18-06 hiện số đối tượng lệch để PA xử lý.

**Thông báo hiển thị.** ERR-18-104 (hiện ở màn vận hành, không trả qua HTTP): "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng."
:::

#### TC-18-067 · Thống kê theo khoảng, chỉ số Prometheus và EVT-18-08 khi vượt độ sâu <!--k:thong-ke-nguong-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-034 và BR-18-026: số liệu đúng, chỉ số `dh_ops_dlq_depth` theo nguồn, sự kiện khi vượt `18.dlq.threshold.depth` và `age-hours`; không có luật cảnh báo trong PH-18.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-034 · API-18-081 · BR-18-026 · ERR-18-003 · EVT-18-08 · UI-18-06, 24.

**Tiền điều kiện, dữ liệu.** T92 với `18.dlq.threshold.depth = 50`; 49 mục mở; Prometheus của TEST.

**Các bước.**

1. `GET /dlq/stats?khoang=7d`.
2. Thêm 2 mục.
3. Đọc chỉ số `dh_ops_dlq_depth{source="SRC-PH04"}` và topic `t92.ops.dlq.threshold-crossed.v1`.
4. `GET /dlq/stats?khoang=abc`.

**Kết quả mong đợi.** Bước 1 `200` theo nguồn, luồng, lớp, trạng thái, xu hướng. Bước 3 chỉ số 51, đúng một EVT-18-08 `type = DEPTH`, `value = 51`, `threshold = 50`; cấu hình PH-18 không có luật cảnh báo. Bước 4 `400` ERR-18-003.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}."
:::

### TS-18-20 · Soạn, kiểm trường cấm và duyệt mẫu thông báo

**Mục tiêu.** Chứng minh mẫu thông báo có phiên bản, dựng thử với dữ liệu mẫu, kiểm cấm biến mức Hạn chế, Nhạy cảm hoặc chưa xác định mức, duyệt bằng người thứ hai và ngừng được.

**Phủ.** FR-18-035; API-18-082…090; BR-18-027; ERR-18-005, 039, 040; UI-18-11, 12, 15.

#### TC-18-068 · Tạo mẫu thư, soạn phiên bản, dựng thử, gửi duyệt và người thứ hai duyệt <!--k:mau-duong-->

::: dac-ta
**Mục đích.** Chứng minh vòng đời `DRAFT → IN_REVIEW → ACTIVE`, phiên bản cũ thành `RETIRED` khi phiên bản mới có hiệu lực, thư chỉ mang liên kết về hệ thống.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-035 · API-18-082, 083, 084, 085, 086, 087, 088 · BR-18-027 · UI-18-11, 12, 15.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1 (`PERM-18-template`), U-T90-TA2 (`PERM-18-approve`); biến khai báo `{{tenHttt}}` (Công khai), `{{lienKet}}`.

**Các bước.**

1. TA1 `POST /notification-templates` `TPL-ONB-MAIL` kênh `EMAIL`, chủ PH-01.
2. TA1 tạo phiên bản 1 có tiêu đề, thân dùng hai biến.
3. TA1 `:preview` với dữ liệu mẫu.
4. TA1 `:submit`; TA2 `:approve`.
5. TA1 tạo, gửi phiên bản 2; TA2 duyệt.

**Kết quả mong đợi.** Bước 3 `200` bản dựng, kiểm trường cấm đạt. Bước 4 phiên bản 1 `ACTIVE`. Bước 5 phiên bản 2 `ACTIVE`, phiên bản 1 `RETIRED`. Mỗi lần chuyển có kiểm toán; thân thư dựng thử chỉ có tên HTTT và liên kết.
:::

#### TC-18-069 · Mẫu dùng biến mức Hạn chế, biến chưa rõ mức, cú pháp sai, người soạn tự duyệt <!--k:mau-truong-cam-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-027 và FR-00-062: kiểm trường cấm chạy khi dựng thử và khi gửi duyệt; bốn mắt mẫu không có đường vòng.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-035 · API-18-085, 086, 087, 088 · BR-18-027 · ERR-18-005, 039, 040.

**Tiền điều kiện, dữ liệu.** T90; WireMock PH-09 xếp `{{soCccd}}` mức Nhạy cảm, `{{diaChi}}` mức Hạn chế, `{{ghiChuNoiBo}}` chưa xác định mức.

**Các bước.**

1. TA1 tạo phiên bản có `{{soCccd}}`, `:preview`.
2. TA1 tạo phiên bản có `{{ghiChuNoiBo}}`, `:submit`.
3. TA1 tạo phiên bản có `{{#ds}}` không đóng.
4. TA1 tạo phiên bản hợp lệ, gửi duyệt, tự `:approve`.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-039 nêu biến và mức. Bước 2 `422` ERR-18-039 (chưa xác định mức coi như cấm). Bước 3 `422` ERR-18-040 nêu dòng. Bước 4 `403` ERR-18-005.

**Thông báo hiển thị.** ERR-18-039: "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm." ERR-18-040: "Mẫu có lỗi tại dòng {dòng}: {chi tiết}." ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

#### TC-18-070 · Ngừng mẫu, trả phiên bản về nháp và gửi bằng mẫu đã ngừng <!--k:mau-ngung-->

::: dac-ta
**Mục đích.** Chứng minh `:reject` trả về `DRAFT` kèm lý do và mẫu `RETIRED` không gửi được.

**Loại.** Âm, Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-035, 036 · API-18-089, 090, 091 · ERR-18-041.

**Tiền điều kiện, dữ liệu.** T90; `TPL-OLD` `ACTIVE`; `TPL-ONB-MAIL` phiên bản 3 `IN_REVIEW`; S-PH01 (`ops:notify`).

**Các bước.**

1. TA2 `:reject` phiên bản 3 kèm lý do.
2. TA1 `POST /notification-templates/TPL-OLD:retire`.
3. S-PH01 gửi bằng `TPL-OLD`.

**Kết quả mong đợi.** Bước 1 phiên bản 3 `DRAFT`, lý do hiện ở UI-18-12. Bước 2 `RETIRED`. Bước 3 `409` ERR-18-041.

**Thông báo hiển thị.** ERR-18-041: "Mẫu {mã} chưa có phiên bản đang dùng."
:::

### TS-18-21 · Phân hệ gửi thông báo và phân giải người nhận

**Mục tiêu.** Chứng minh phân hệ gửi thông báo bất đồng bộ lũy đẳng hoặc đồng bộ cho thư mang liên kết, chỉ PH-18 phân giải địa chỉ người nhận, phân hệ gọi không bao giờ nhận địa chỉ, và lỗi kênh được thử lại.

**Phủ.** FR-18-036, 037; API-18-091…094; BR-18-027, 028, 029, 030; ERR-18-009, 039, 041, 042, 044, 110, 111; EVT-18-13; NFR-18-007.

#### TC-18-071 · PH-01 gửi thông báo bất đồng bộ tới vai trò và đầu mối HTTT, lũy đẳng theo khóa <!--k:gui-bat-dong-bo-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-028, 029: gửi qua outbox, người nhận phân giải từ `recipientRef`, phân hệ gọi chỉ nhận mã thông báo và số người nhận, gửi lại cùng khóa trả cùng kết quả.

**Loại.** Dương, Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-036, 037 · API-18-091, 093, 094 · BR-18-028, 029 · UI-18-13.

**Tiền điều kiện, dữ liệu.** T90; S-PH01 (`ops:notify`); `TPL-ONB-MAIL` `ACTIVE`; `recipientRef` gồm `ROLE:TA`, `SYSTEM_CONTACT:HTTT-THUE`; WireMock PH-01 trả đầu mối; máy chủ thư giả MOCK-SMTP.

**Các bước.**

1. S-PH01 `POST /ops/internal/v1/notifications` kèm `Idempotency-Key`.
2. Gửi lại cùng khóa, cùng thân.
3. S-PH01 `POST /ops/internal/v1/recipients:resolve` cùng `recipientRef`.
4. `GET /ops/internal/v1/notifications/{messageId}`.

**Kết quả mong đợi.** Bước 1 `202` `messageId`, `recipientCount = 3`. Bước 2 `202` cùng `messageId`, MOCK-SMTP chỉ nhận 3 thư. Bước 3 `200` danh sách mã người nhận, không có địa chỉ thư hay số điện thoại. Bước 4 `DELIVERED`, không có địa chỉ.
:::

#### TC-18-072 · Khóa lũy đẳng dùng lại với thân khác, không có mẫu ACTIVE, không phân giải được, biến cấm lúc gửi <!--k:gui-loi-->

::: dac-ta
**Mục đích.** Chứng minh các lỗi của `NotificationApi` trả đúng mã, không thư nào rời hệ thống.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-036, 037 · API-18-091 · BR-18-027, 028 · ERR-18-009, 039, 041, 042.

**Tiền điều kiện, dữ liệu.** T90; S-PH01; `TPL-DRAFT` chỉ có phiên bản nháp; MOCK-SMTP đếm thư.

**Các bước.**

1. Gửi lại khóa của ca trước với thân khác.
2. Gửi bằng `TPL-DRAFT`.
3. Gửi tới `USER:khong-ton-tai`.
4. Gửi `TPL-ONB-MAIL` kèm biến dữ liệu `soCccd`.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-009. Bước 2 `409` ERR-18-041. Bước 3 `422` ERR-18-042. Bước 4 `422` ERR-18-039. MOCK-SMTP nhận 0 thư.

**Thông báo hiển thị.** ERR-18-009: "Yêu cầu trùng khóa với một yêu cầu khác nội dung." ERR-18-041: "Mẫu {mã} chưa có phiên bản đang dùng." ERR-18-042: "Không xác định được người nhận {mã}." ERR-18-039: "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."
:::

#### TC-18-073 · Gửi đồng bộ thư mang liên kết trong 3 giây và máy chủ thư gián đoạn <!--k:gui-dong-bo-->

::: dac-ta
**Mục đích.** Chứng minh chế độ đồng bộ (Q01-52): trả kết quả khi máy chủ thư nhận, quá `18.notify.sync.timeout-ms` hoặc kênh gián đoạn trả `503` để bên gọi xử lý.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-036 · API-18-092 · ERR-18-044 · NFR-18-007.

**Tiền điều kiện, dữ liệu.** T90; S-PH01; MOCK-SMTP; ở bước 2 MOCK-SMTP ngắt cổng.

**Các bước.**

1. S-PH01 `POST /ops/internal/v1/notifications:send-sync` thư kích hoạt có liên kết.
2. Ngắt MOCK-SMTP, gửi lại khóa mới.

**Kết quả mong đợi.** Bước 1 `200` trong ≤ 3 giây, `status = SENT`. Bước 2 `503` ERR-18-044 sau ≤ 3 giây, không tạo bản ghi gửi lại tự động.

**Thông báo hiển thị.** ERR-18-044: "Kênh gửi đang gián đoạn. Thử lại sau."
:::

#### TC-18-074 · Máy chủ thư và SMS gateway lỗi thì thử lại tới 5 lần rồi FAILED có sự kiện <!--k:gui-thu-lai-kenh-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-040: lỗi tạm thời được thử lại theo `18.notify.retry.max-attempts` trong `retry.window-hours`, hết lượt thì `FAILED` và phát EVT-18-13 cho phân hệ gọi.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-036, 040 · BR-18-028 · ERR-18-110, 111 · EVT-18-13.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); `18.notify.sms.enabled = true` cho T95; MOCK-SMTP trả `451` mọi lần; MOCK-SMS trả `503`.

**Các bước.**

1. S-PH01 gửi một thư và một SMS bất đồng bộ.
2. Tua đồng hồ qua 5 lần thử.
3. Đọc `t95.ops.notification.failed.v1`.

**Kết quả mong đợi.** Mỗi lần thử ghi ERR-18-110 (thư) và ERR-18-111 (SMS) vào lần gửi; sau lần thứ 5 cả hai `FAILED`; EVT-18-13 có `notificationId`, `templateCode`, `channel`, `errorCode`, `callerPh`, không có địa chỉ.

**Thông báo hiển thị.** ERR-18-110 (hiện ở màn vận hành, không trả qua HTTP): "Gửi thư chưa thành công; đang thử lại." ERR-18-111 (hiện ở màn vận hành, không trả qua HTTP): "Gửi SMS chưa thành công; đang thử lại."
:::

#### TC-18-075 · Tenant SUSPENDED chỉ nhận thông báo nhóm bắt buộc <!--k:gui-tenant-tam-ngung-->

::: dac-ta
**Mục đích.** Chứng minh xử lý `platform.tenant.status-changed.v1`: khi tenant tạm ngừng, thông báo thường bị `SUPPRESSED`, nhóm bắt buộc vẫn gửi.

**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-18-036, 038 · BR-18-030.

**Tiền điều kiện, dữ liệu.** T93; WireMock PH-20 phát `platform.tenant.status-changed.v1` sang `SUSPENDED`; mẫu thường `TPL-NHAC` và mẫu bắt buộc `TPL-BAO-TRI`.

**Các bước.**

1. Phát sự kiện tạm ngừng.
2. S-PH01 gửi bằng `TPL-NHAC` và `TPL-BAO-TRI`.

**Kết quả mong đợi.** Thông báo `TPL-NHAC` `SUPPRESSED` có lý do `TENANT_SUSPENDED`; thông báo `TPL-BAO-TRI` `DELIVERED`.
:::

### TS-18-22 · Đặt tùy chọn nhận, giờ yên lặng và đọc thông báo trong ứng dụng

**Mục tiêu.** Chứng minh người dùng tắt được nhóm thông báo không bắt buộc, đặt giờ yên lặng giữ thông báo tối đa 12 giờ, thông báo `URGENT` và bắt buộc không bị chặn, và đọc thông báo trong ứng dụng.

**Phủ.** FR-18-038; API-18-095…098; BR-18-030; ERR-18-003, 004, 046; UI-18-14.

#### TC-18-076 · Tắt nhóm nhắc việc qua thư, đặt giờ yên lặng, URGENT vẫn gửi ngay <!--k:tuy-chon-gio-yen-lang-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-030: thông báo thường trong giờ yên lặng giữ tới hết giờ (≤ 12 giờ), `URGENT` gửi ngay, kênh trong ứng dụng vẫn nhận.

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-038, 036 · API-18-095, 096, 097, 098 · BR-18-030 · UI-18-14.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả, 21:50); U-T95-IE; `18.notify.quiet-hours = 22:00-06:00`.

**Các bước.**

1. IE mở `/ca-nhan/thong-bao`, tắt "Nhắc việc" ở kênh thư, đặt giờ yên lặng mặc định, lưu.
2. Tua đến 23:00, S-PH01 gửi cho IE một thông báo `NORMAL` và một `URGENT`.
3. Tua đến 06:01.
4. IE `GET /me/notifications`, `POST /me/notifications/{id}:read`.

**Kết quả mong đợi.** Bước 1 `200`, `ETag` mới. Bước 2 `URGENT` `DELIVERED` ngay; `NORMAL` giữ `QUEUED`. Bước 3 `NORMAL` được gửi. Bước 4 hai thông báo trong ứng dụng, số chưa đọc giảm 1.
:::

#### TC-18-077 · Tắt nhóm bắt buộc, giờ yên lặng sai định dạng, lưu với ETag cũ <!--k:tuy-chon-loi-->

::: dac-ta
**Mục đích.** Chứng minh người dùng không tắt được nhóm bắt buộc và tùy chọn có kiểm định dạng, khóa lạc quan.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-038 · API-18-096 · BR-18-030 · ERR-18-003, 004, 046.

**Tiền điều kiện, dữ liệu.** T90; U-T90-IE.

**Các bước.**

1. Tắt nhóm "Bảo trì hệ thống" (bắt buộc).
2. Đặt giờ yên lặng `25:00-06:00`.
3. Lưu với `ETag` cũ.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-046. Bước 2 `400` ERR-18-003. Bước 3 `412` ERR-18-004.

**Thông báo hiển thị.** ERR-18-046: "Không tắt được nhóm thông báo {nhóm} vì là thông báo bắt buộc." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-004: "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu."
:::

### TS-18-23 · Cấu hình quy tắc thông báo theo sự kiện

**Mục tiêu.** Chứng minh quy tắc nối sự kiện phân hệ khác với mẫu và người nhận, gửi lũy đẳng theo `eventId:ruleId`, và từ chối sự kiện chưa được tiêu thụ hoặc mẫu chưa có hiệu lực.

**Phủ.** FR-18-039; API-18-099, 100, 101; BR-18-028, 032; ERR-18-003, 041, 045, 124.

#### TC-18-078 · Quy tắc EVT-02-04 sang mẫu và vai TA, sự kiện lặp chỉ gửi một lần <!--k:quy-tac-su-kien-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-028: thông báo từ quy tắc dùng khóa `eventId:ruleId`, sự kiện trùng không gửi lại.

**Loại.** Dương, Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-039 · API-18-099, 100, 101 · BR-18-028 · UI-18-11.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1; `TPL-API-DUYET` `ACTIVE`; WireMock PH-02 phát EVT-02-04.

**Các bước.**

1. TA1 `POST /notification-rules` sự kiện EVT-02-04, điều kiện `visibility = PUBLIC`, mẫu `TPL-API-DUYET`, người nhận `ROLE:TA`.
2. Phát một EVT-02-04 hai lần cùng `eventId`.
3. TA1 `PATCH /notification-rules/{ruleId}` tắt quy tắc, phát sự kiện mới.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 đúng một thông báo mỗi người nhận. Bước 3 `200`, không thông báo mới.
:::

#### TC-18-079 · Sự kiện chưa tiêu thụ, mẫu chưa ACTIVE, điều kiện sai, bộ tiêu thụ lỗi <!--k:quy-tac-loi-->

::: dac-ta
**Mục đích.** Chứng minh quy tắc chỉ tạo cho sự kiện có trong bảng 9.3b của FRS và lỗi tiêu thụ đi vào DLQ của PH-18.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-18-039 · API-18-100 · ERR-18-003, 041, 045, 124.

**Tiền điều kiện, dữ liệu.** T90; `TPL-DRAFT` nháp.

**Các bước.**

1. Tạo quy tắc cho EVT-03-01.
2. Tạo quy tắc dùng `TPL-DRAFT`.
3. Tạo quy tắc có điều kiện `visibility ==`.
4. Làm bộ xử lý quy tắc lỗi năm lần với một EVT-02-04.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-045. Bước 2 `409` ERR-18-041. Bước 3 `400` ERR-18-003. Bước 4 inbox `FAILED`, ghi ERR-18-124, mục DLQ nguồn `PH18_INBOX`.

**Thông báo hiển thị.** ERR-18-045: "Sự kiện {sự kiện} chưa được phân hệ vận hành tiêu thụ nên không tạo được quy tắc." ERR-18-041: "Mẫu {mã} chưa có phiên bản đang dùng." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-124 (hiện ở màn vận hành, không trả qua HTTP): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
:::

### TS-18-24 · Xử lý thư trả lại, danh sách chặn và tra nhật ký gửi

**Mục tiêu.** Chứng minh thư trả lại cứng hoặc trả lại mềm quá ngưỡng đưa địa chỉ vào danh sách chặn và phát EVT-18-12, gửi tới người bị chặn bị chặn lại, nhật ký gửi chỉ hiện địa chỉ đã che và gửi lại được sau khi sửa.

**Phủ.** FR-18-040, 041; API-18-102…106; BR-18-029, 031; ERR-18-003, 006, 043, 112, 113; EVT-18-12, 13.

#### TC-18-080 · Thư trả lại cứng và ba lần trả lại mềm đưa vào danh sách chặn <!--k:thu-tra-lai-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-031: trả lại cứng chặn ngay, trả lại mềm quá `18.notify.bounce.soft-limit` trong 30 ngày thì chặn, mỗi lần chặn phát EVT-18-12.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT, KT.

**Truy vết.** FR-18-040 · API-18-104, 106 · BR-18-031 · ERR-18-112 · EVT-18-12.

**Tiền điều kiện, dữ liệu.** T90; MOCK-SMTP gọi `POST /ops/internal/v1/notifications/bounces` (scope `ops:notify`); người nhận R1, R2.

**Các bước.**

1. Báo trả lại `HARD` cho R1.
2. Báo trả lại `SOFT` cho R2 ba lần trong 10 ngày.
3. `GET /suppressions`.

**Kết quả mong đợi.** Lần gửi của R1 `BOUNCED` ghi ERR-18-112, R1 vào danh sách chặn, EVT-18-12 `bounceType = HARD`. R2 sau lần thứ ba vào danh sách chặn. Danh sách hiện địa chỉ đã che dạng `t***@***.vn`.

**Thông báo hiển thị.** ERR-18-112 (hiện ở màn vận hành, không trả qua HTTP): "Thư bị trả lại ({loại})."
:::

#### TC-18-081 · Gửi tới người bị chặn, gỡ chặn có lý do và gửi lại <!--k:gui-nguoi-bi-chan-->

::: dac-ta
**Mục đích.** Chứng minh người bị chặn không nhận thư (bất đồng bộ ghi ERR-18-113, đồng bộ trả ERR-18-043), gỡ chặn cần lý do, gửi lại thông báo `BOUNCED` sau khi sửa.

**Loại.** Âm, Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-040, 041 · API-18-091, 092, 103, 105 · ERR-18-006, 043, 113 · EVT-18-13.

**Tiền điều kiện, dữ liệu.** T90; R1 bị chặn; lần gửi `DLV-01` `BOUNCED`, `DLV-02` `DELIVERED`; U-T90-TA1 (`PERM-18-template`).

**Các bước.**

1. S-PH01 gửi bất đồng bộ cho R1.
2. S-PH01 gửi đồng bộ cho R1.
3. TA1 `DELETE /suppressions/{id}` kèm lý do.
4. TA1 `POST /notification-deliveries/DLV-01:resend`; rồi `:resend` cho `DLV-02`.

**Kết quả mong đợi.** Bước 1 lần gửi `SUPPRESSED` ghi ERR-18-113. Bước 2 `409` ERR-18-043. Bước 3 `204`, KT: có. Bước 4 `DLV-01` gửi lại `202`; `DLV-02` `409` ERR-18-006.

**Thông báo hiển thị.** ERR-18-113 (hiện ở màn vận hành, không trả qua HTTP): "Không gửi vì người nhận trong danh sách chặn." ERR-18-043: "Người nhận đang trong danh sách chặn." ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

#### TC-18-082 · Tra nhật ký gửi theo kênh, trạng thái, nguồn; địa chỉ đã che; kênh cho PH-13 <!--k:nhat-ky-gui-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-041: nhật ký lọc được, chỉ hiện địa chỉ đã che kể cả với AU, bộ lọc sai bị chặn; PH-13 gửi thư theo lịch trực qua cùng API.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-18-041, 036 · API-18-102, 093 · BR-18-029 · ERR-18-003 · UI-18-13.

**Tiền điều kiện, dữ liệu.** T90; 500 lần gửi mẫu; U-T90-AU; S-PH13 (`ops:notify`).

**Các bước.**

1. AU mở `/van-hanh/thong-bao/nhat-ky`, lọc kênh `EMAIL`, trạng thái `BOUNCED`.
2. `GET /notification-deliveries?trangThai=XYZ`.
3. S-PH13 gửi thư mức `URGENT` tới `ON_CALL:SO` rồi tra trạng thái.

**Kết quả mong đợi.** Bước 1 danh sách đúng, cột người nhận đã che. Bước 2 `400` ERR-18-003. Bước 3 `202` rồi `DELIVERED` trong ≤ 30 giây; nhật ký ghi `callerPh = PH-13`.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}."
:::

### TS-18-25 · Phân hệ đăng ký loại việc, tạo và đóng việc lũy đẳng

**Mục tiêu.** Chứng minh phân hệ đăng ký loại việc trong không gian tên của mình, tạo hoặc cập nhật việc lũy đẳng theo `sourceRef`, đóng việc lũy đẳng, và tiêu đề việc không mang dữ liệu mức Hạn chế.

**Phủ.** FR-18-042, 043; API-18-107…110; BR-18-032; ERR-18-003, 017, 039, 047, 048; EVT-18-14.

#### TC-18-083 · PH-02 đăng ký loại việc, tạo, cập nhật và đóng việc lũy đẳng <!--k:loai-viec-tao-dong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-032: `PUT` cùng `sourceRef` cập nhật thay vì tạo mới, đóng hai lần chỉ có một chuyển trạng thái, phân hệ nguồn là bên đóng việc.

**Loại.** Dương, Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-042, 043 · API-18-107, 108, 109, 110 · BR-18-032 · EVT-18-14 · UI-18-15.

**Tiền điều kiện, dữ liệu.** T90; S-PH02 (`ops:task`); người nhận là nhóm duyệt `ROLE:TA` trừ người tạo phiên bản API.

**Các bước.**

1. S-PH02 `POST /ops/internal/v1/task-types` `ph02.approve-version`, quyền xem `PERM-02-publish`, hạn 3 ngày làm việc, liên kết màn.
2. S-PH02 `PUT /ops/internal/v1/tasks/ph02:ver:svc-thue-v3` với `assignees`, `excludeUsers`.
3. Gọi lại bước 2 cùng thân, rồi đổi hạn.
4. S-PH02 `POST .../tasks/ph02:ver:svc-thue-v3:close` `DONE` hai lần.
5. `GET /task-types`.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `201` `OPEN`, EVT-18-14. Bước 3 `200` cùng `taskId`, hạn mới. Bước 4 lần đầu `200` `DONE`, lần hai `200` không đổi, chỉ một EVT-18-14 `to = DONE`. Bước 5 loại việc hiện với chủ PH-02.
:::

#### TC-18-084 · Loại việc ngoài không gian tên, loại chưa đăng ký, việc đã đóng, tiêu đề chứa biến cấm <!--k:loai-viec-loi-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện chặn của API việc.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-042, 043 · API-18-107, 109 · BR-18-032 · ERR-18-003, 017, 039, 047, 048.

**Tiền điều kiện, dữ liệu.** T90; S-PH02; việc `ph02:ver:svc-thue-v3` đã `DONE`.

**Các bước.**

1. S-PH02 đăng ký loại `ph04.approve-flow`.
2. S-PH02 đăng ký loại thiếu `name`.
3. S-PH02 `PUT` việc loại `ph02.khong-co`.
4. S-PH02 `PUT` lại việc đã `DONE` với hạn mới.
5. S-PH02 tạo việc có tiêu đề chứa `{{soCccd}}`.

**Kết quả mong đợi.** Bước 1 `403` ERR-18-017. Bước 2 `400` ERR-18-003. Bước 3 `422` ERR-18-047. Bước 4 `409` ERR-18-048. Bước 5 `422` ERR-18-039.

**Thông báo hiển thị.** ERR-18-017: "Phân hệ không sở hữu {đối tượng} {mã}." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-047: "Loại việc {loại} chưa được đăng ký." ERR-18-048: "Việc {mã} đã đóng." ERR-18-039: "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."
:::

#### TC-18-085 · Việc duyệt bốn mắt ẩn với người tạo đối tượng và người mất quyền <!--k:viec-bon-mat-an-->

::: dac-ta
**Mục đích.** Chứng minh AC-18-08: người dùng chỉ thấy việc được giao và còn quyền xem; việc bốn mắt có `excludeUsers` là người tạo.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-043, 044 · API-18-109, 111, 112 · BR-18-032 · ERR-18-001 · UI-18-15.

**Tiền điều kiện, dữ liệu.** T90; việc `ph02:ver:svc-dat-v2` giao `ROLE:TA`, `excludeUsers = [U-T90-TA1]`; U-T90-TA2; WireMock PH-12 thu hồi `PERM-02-publish` của TA2 ở bước 3.

**Các bước.**

1. TA1 `GET /me/tasks`.
2. TA2 `GET /me/tasks`.
3. Thu hồi quyền của TA2, TA2 `GET /me/tasks/{taskId}`.

**Kết quả mong đợi.** Bước 1 không có việc. Bước 2 có việc. Bước 3 danh sách không còn việc, chi tiết trả `404` ERR-18-001.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

### TS-18-26 · Xử lý Việc của tôi, nhắc và quá hạn

**Mục tiêu.** Chứng minh Việc của tôi lọc theo loại, hạn, trạng thái, thẻ trang chủ có số tóm tắt, nhắc trước hạn và báo quá hạn theo tham số `18.task.*`.

**Phủ.** FR-18-044; API-18-111, 112, 181; BR-18-032; ERR-18-001, 048; NFR-18-009; UI-18-15.

#### TC-18-086 · Danh sách Việc của tôi, thẻ tóm tắt và mở màn của phân hệ nguồn <!--k:viec-cua-toi-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-044: danh sách sắp theo hạn, `?summary=true` cho thẻ trang chủ, chi tiết có liên kết sang màn của phân hệ nguồn.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-044 · API-18-111, 112 · UI-18-15.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA2 có 12 việc mở thuộc 4 loại, 2 quá hạn.

**Các bước.**

1. `GET /me/tasks?summary=true`.
2. Mở `/viec-cua-toi`, lọc loại `ph18.approve-param`.
3. Bấm một việc.

**Kết quả mong đợi.** Bước 1 `200` `open = 12`, `overdue = 2`, theo loại. Bước 2 đúng việc, cột hạn và người giao. Bước 3 chuyển sang màn của phân hệ nguồn qua liên kết đã đăng ký.
:::

#### TC-18-087 · Nhắc trước hạn 24 giờ và báo quá hạn sau 48 giờ <!--k:viec-nhac-qua-han-->

::: dac-ta
**Mục đích.** Chứng minh `18.task.reminder.before-hours` và `18.task.overdue.escalate-hours`: nhắc đúng một lần, quá hạn chuyển cấp theo loại việc.

**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** FR-18-044, 036 · BR-18-032 · EVT-18-14.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); việc hạn sau 30 giờ.

**Các bước.**

1. Tua 7 giờ, chạy tác vụ nhắc hai lần.
2. Tua tới quá hạn 49 giờ.

**Kết quả mong đợi.** Bước 1 đúng một thông báo nhắc, bản ghi `task_reminder` có thời điểm. Bước 2 việc có cờ quá hạn, người giao ở cấp trên nhận thông báo chuyển cấp; EVT-18-14 không phát vì trạng thái không đổi.
:::

#### TC-18-088 · Mở việc không tồn tại và việc đã đóng từ liên kết cũ <!--k:viec-khong-con-->

::: dac-ta
**Mục đích.** Chứng minh liên kết cũ trong thư nhắc không mở được việc đã đóng.

**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-18-044 · API-18-112 · ERR-18-001, 048.

**Tiền điều kiện, dữ liệu.** T90; việc `TASK-DONE-01` đã `DONE`.

**Các bước.**

1. `GET /me/tasks/TASK-KHONG-CO`.
2. Mở liên kết `/viec-cua-toi/TASK-DONE-01`.

**Kết quả mong đợi.** Bước 1 `404` ERR-18-001. Bước 2 màn hiện câu thông báo ERR-18-048 và nút về danh sách.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}." ERR-18-048: "Việc {mã} đã đóng."
:::

#### TC-18-166 · Nhận việc chuyển IN_PROGRESS, gọi lại không đổi, việc đã đóng bị từ chối <!--k:viec-nhan-viec-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-044 bước 3 qua API-18-181: nhận việc ghi người nhận, phát EVT-18-14, lũy đẳng khi gọi lại và từ chối việc đã đóng.

**Loại.** Dương, Âm, Lũy đẳng.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-18-044 · API-18-181, 112 · EVT-18-14 · ERR-18-048, 001 · ERR-00-428 · UI-18-15.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA2 có việc `TASK-OPEN-01` `OPEN` cùng nhóm nhận với U-T90-TA1; việc `TASK-DONE-01` đã `DONE`.

**Các bước.**

1. TA2 `POST /me/tasks/TASK-OPEN-01:claim` kèm `If-Match`.
2. TA2 gửi lại bước 1 với ETag mới.
3. TA2 `POST /me/tasks/TASK-OPEN-01:claim` không có `If-Match`.
4. TA2 `POST /me/tasks/TASK-DONE-01:claim`.
5. TA1 mở UI-18-15.

**Kết quả mong đợi.** Bước 1 `200` việc `IN_PROGRESS`, `claimedBy = U-T90-TA2`, EVT-18-14 phát một lần. Bước 2 `200` không đổi, không phát sự kiện mới. Bước 3 `428` ERR-00-428. Bước 4 `409` ERR-18-048. Bước 5 TA1 thấy việc ghi "TA2 đã nhận".

**Thông báo hiển thị.** ERR-18-048: "Việc {mã} đã đóng."
:::

### TS-18-27 · Quản lý lịch ngày làm việc, cửa sổ bảo trì và đóng băng

**Mục tiêu.** Chứng minh lịch năm theo tenant, tính hạn bằng ngày làm việc có dự phòng `COMMON`, cửa sổ bảo trì và đóng băng không chồng lấn, phát sự kiện và phân hệ khác đọc được trạng thái đóng băng; PH-18 vắng thì phân hệ coi là không đóng băng.

**Phủ.** FR-18-045, 046; API-18-113…122; BR-18-033, 034, 035; ERR-18-049, 050; EVT-18-15, 16; UI-18-16.

#### TC-18-089 · Ghi lịch 2027 có ngày lễ, ngày làm bù và tính hạn cộng 5 ngày làm việc <!--k:lich-lam-viec-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-045: `add-working-days` bỏ cuối tuần, ngày lễ và tính ngày làm bù; EVT-18-15 phát khi lịch đổi.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-045 · API-18-113, 114, 115, 116, 117 · BR-18-033, 034 · EVT-18-15 · UI-18-16.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1 (`PERM-18-calendar`); `CAL-2027` (giả định: nghỉ Tết từ 05/02 đến 11/02/2027, làm bù thứ Bảy 20/02/2027); S-PH02 (`ops:calendar-read`).

**Các bước.**

1. TA1 `PUT /calendars/2027` với `CAL-2027`, `If-Match`.
2. TA1 `POST /calendars/2027/holidays` thêm một ngày nghỉ.
3. S-PH02 `POST /ops/internal/v1/calendar/T90:add-working-days` từ 04/02/2027 cộng 5.
4. S-PH02 `GET /ops/internal/v1/calendar/T90:working-days` tháng 2/2027.

**Kết quả mong đợi.** Bước 1 `200`, EVT-18-15 `year = 2027`. Bước 2 `201`, EVT-18-15 phiên bản mới. Bước 3 kết quả là ngày làm việc thứ năm sau Tết theo bảng dữ liệu, `calendarMissing = false`. Bước 4 số ngày khớp bảng.
:::

#### TC-18-090 · Thiếu lịch tenant dùng COMMON, thiếu cả hai chỉ bỏ cuối tuần, lịch sai <!--k:lich-du-phong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-034 và kiểm hợp lệ lịch.

**Loại.** Biên, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-045 · API-18-114, 117 · BR-18-034 · ERR-18-049.

**Tiền điều kiện, dữ liệu.** T92 không có lịch 2027, `COMMON` có lịch 2027; năm 2031 không có ở đâu.

**Các bước.**

1. Tính hạn cho T92 năm 2027.
2. Tính hạn cho T92 năm 2031.
3. TA ghi lịch 2027 có ngày 30/02.

**Kết quả mong đợi.** Bước 1 dùng lịch `COMMON`, `calendarSource = COMMON`. Bước 2 chỉ bỏ thứ Bảy, Chủ nhật, `calendarMissing = true`. Bước 3 `422` ERR-18-049.

**Thông báo hiển thị.** ERR-18-049: "Lịch năm {năm} không hợp lệ: {chi tiết}."
:::

#### TC-18-091 · Tạo cửa sổ bảo trì và đóng băng, đọc trạng thái, chồng lấn bị từ chối <!--k:cua-so-dong-bang-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-046: cửa sổ có môi trường, thời gian; EVT-18-16 phát cho PH-02, PH-04; API trạng thái đóng băng trả đúng; cửa sổ cùng loại chồng nhau bị từ chối.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, KT.

**Truy vết.** FR-18-046 · API-18-118, 119, 120, 121, 122 · BR-18-035 · ERR-18-050 · EVT-18-16 · UI-18-16.

**Tiền điều kiện, dữ liệu.** T90; U-PA1 (`PERM-18-calendar`); S-PH02.

**Các bước.**

1. U-PA1 `POST /maintenance-windows` `FREEZE` môi trường `PROD` từ 20/12 đến 05/01.
2. S-PH02 `GET /ops/internal/v1/freeze-status/T90` trong khoảng đó.
3. U-PA1 tạo cửa sổ `FREEZE` khác từ 01/01 đến 10/01.
4. U-PA1 `PATCH` cửa sổ đầu, rồi `:cancel` kèm lý do.

**Kết quả mong đợi.** Bước 1 `201`, EVT-18-16 `kind = FREEZE`. Bước 2 `frozen = true`, `windowId`. Bước 3 `409` ERR-18-050. Bước 4 `200` rồi `CANCELLED`, EVT-18-16 `state = CANCELLED`.

**Thông báo hiển thị.** ERR-18-050: "Cửa sổ {loại} chồng với cửa sổ {mã} từ {bắt đầu} đến {kết thúc}."
:::

#### TC-18-092 · PH-18 vắng thì PH-02 coi là không đóng băng và ghi cảnh báo <!--k:dong-bang-ph18-vang-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-035 và LP-18-04: phân hệ chủ quyết định chặn, PH-18 vắng không chặn phát hành.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-18-046, 072 · API-18-122 · BR-18-035, 007 · NFR-18-018.

**Tiền điều kiện, dữ liệu.** T94; thư viện `dh-ops-client` ở PH-02 giả lập; tắt `dh-platform`.

**Các bước.**

1. PH-02 kiểm trạng thái đóng băng khi tắt `dh-platform`.

**Kết quả mong đợi.** Thư viện trả `frozen = false`, `source = FALLBACK`, PH-02 ghi cảnh báo và chỉ số `dh_ops_client_fallback_total`; thao tác phát hành của PH-02 không bị chặn bởi lỗi kết nối.
:::

### TS-18-28 · Mở, xử lý và đóng sự cố vận hành

**Mục tiêu.** Chứng minh sự cố mở từ sự kiện lũy đẳng theo `sourceRef`, tạo tay có mức và người xử lý, mốc thời gian chỉ thêm, liên kết được mục DLQ và sao lưu, và chỉ đóng khi có nguyên nhân gốc và bài học.

**Phủ.** FR-18-047, 048, 049, 051; API-18-123…129, 131, 132; BR-18-036, 037, 046; ERR-18-001, 003, 006, 052, 124; EVT-18-17, 18.

#### TC-18-093 · EVT-13-04 mở sự cố một lần theo sourceRef, cập nhật lần sau <!--k:su-co-tu-su-kien-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-047 và BR-18-036: mỗi `sourceRef` có tối đa một sự cố mở; sự kiện lặp chỉ thêm mốc thời gian.

**Loại.** Dương, Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-18-047 · API-18-132, 123 · BR-18-036 · EVT-18-17 · UI-18-17.

**Tiền điều kiện, dữ liệu.** T90; WireMock PH-13 phát EVT-13-04 cảnh báo `ALR-77` mức `SEV2`; S-PH13 (`ops:incident-write`).

**Các bước.**

1. Phát EVT-13-04 cho `ALR-77`.
2. Phát lại EVT-13-04 `ALR-77` với `eventId` mới.
3. S-PH13 `POST /ops/internal/v1/incidents` `sourceRef = ALR-77`.
4. U-T90-TO mở `/van-hanh/su-co`.

**Kết quả mong đợi.** Bước 1 một sự cố `OPEN` mức `SEV2`, EVT-18-17. Bước 2, 3 cùng sự cố, thêm mốc thời gian, không tạo mới. Bước 4 cột nguồn hiện `PH-13 · ALR-77`.
:::

#### TC-18-094 · Tạo tay, phân mức, gán người xử lý, chuyển trạng thái, thêm mốc và liên kết <!--k:su-co-tao-tay-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-048, 049: vòng đời `OPEN → INVESTIGATING → MITIGATED → RESOLVED`, mốc thời gian chỉ thêm, liên kết mục DLQ và lượt phát lại.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-048, 049 · API-18-124, 125, 126, 127, 128, 129 · BR-18-037, 046 · EVT-18-17, 18 · UI-18-17, 18.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TO (`PERM-18-incident`); `DLQ-A-02`, lượt `RJ-02`.

**Các bước.**

1. TO `POST /incidents` mức `SEV1`, tóm tắt.
2. TO `PATCH` người xử lý U-T90-SO, `If-Match`.
3. TO chuyển `INVESTIGATING`, thêm hai mốc, liên kết `DLQ-A-02` và `RJ-02`.
4. Chuyển `MITIGATED`, `RESOLVED`.

**Kết quả mong đợi.** Bước 1 `201`, hạn xác nhận theo `18.incident.sev1-ack-minutes`. Mỗi chuyển trạng thái phát EVT-18-18 và có KT. Bước 3 mốc thời gian theo thứ tự, liên kết hiện ở UI-18-18.
:::

#### TC-18-095 · Dữ liệu sai, chuyển trạng thái sai, xóa mốc thời gian, liên kết đối tượng không có, bộ tiêu thụ lỗi <!--k:su-co-loi-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện chặn của sự cố và mốc thời gian chỉ thêm.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, DB.

**Truy vết.** FR-18-048, 049, 047 · API-18-124, 127, 128, 129 · BR-18-037 · ERR-18-001, 003, 006, 124.

**Tiền điều kiện, dữ liệu.** T90; sự cố `INC-T90-02` `OPEN`.

**Các bước.**

1. `POST /incidents` mức `SEV9`.
2. Chuyển `INC-T90-02` thẳng sang `CLOSED`.
3. Gọi `DELETE` trên một mốc thời gian (API không có) và thử `DELETE` bằng vai `ph18_app` ở CSDL.
4. Liên kết `DLQ-KHONG-CO`.
5. Làm bộ tiêu thụ EVT-13-05 lỗi năm lần.

**Kết quả mong đợi.** Bước 1 `400` ERR-18-003. Bước 2 `409` ERR-18-006. Bước 3 API `405`; CSDL báo SQLSTATE 55000 (bảng chỉ thêm). Bước 4 `404` ERR-18-001. Bước 5 inbox `FAILED`, ghi ERR-18-124, mục DLQ nguồn `PH18_INBOX`.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}." ERR-18-001: "Không tìm thấy {đối tượng} {mã}." ERR-18-124 (hiện ở màn vận hành, không trả qua HTTP): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
:::

#### TC-18-096 · Đóng sự cố cần nguyên nhân gốc và bài học từ 30 ký tự <!--k:su-co-dong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-037 và AC-18-09.

**Loại.** Âm, Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-051 · API-18-131 · BR-18-037 · ERR-18-052 · EVT-18-18.

**Tiền điều kiện, dữ liệu.** T90; `INC-T90-03` `RESOLVED`.

**Các bước.**

1. `POST /incidents/INC-T90-03:close` nguyên nhân "lỗi mạng", bài học rỗng.
2. Đóng với nguyên nhân 60 ký tự, bài học 45 ký tự, việc khắc phục.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-052. Bước 2 `200` `CLOSED`, EVT-18-18; sự cố hết liên kết giữ hoãn dọn mục DLQ.

**Thông báo hiển thị.** ERR-18-052: "Đóng sự cố cần nêu nguyên nhân gốc và bài học (mỗi phần ít nhất 30 ký tự)."
:::

### TS-18-29 · Chuyển sự cố có dữ liệu cá nhân sang PH-09

**Mục tiêu.** Chứng minh sự cố có dữ liệu cá nhân được chuyển PH-09 với `source = INCIDENT_PH18`, thiếu thông tin bắt buộc bị chặn, PH-09 vắng thì thử lại mỗi 5 phút và báo cán bộ ATTT.

**Phủ.** FR-18-050; API-18-130; BR-18-036; ERR-18-053, 054; EVT-18-17, 18.

#### TC-18-097 · SO chuyển sự cố có dữ liệu cá nhân sang PH-09 <!--k:su-co-ph09-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-050: gói chuyển có loại dữ liệu, số người ước tính, thời điểm phát hiện; đồng hồ 72 giờ do PH-09 giữ.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-18-050 · API-18-130 · BR-18-036 · EVT-18-18 · UI-18-18.

**Tiền điều kiện, dữ liệu.** T90; `INC-T90-04` `INVESTIGATING` có `hasPersonalData = true`; U-T90-SO; WireMock PH-09.

**Các bước.**

1. SO `POST /incidents/INC-T90-04:escalate-privacy` đủ trường.
2. Kiểm lời gọi tới PH-09.

**Kết quả mong đợi.** Bước 1 `202`, sự cố có `privacyRef`, mốc thời gian "Đã chuyển PH-09". Bước 2 PH-09 nhận đúng một lời gọi `source = INCIDENT_PH18`, không chứa payload.
:::

#### TC-18-098 · Thiếu thông tin chuyển PH-09 và PH-09 không nhận <!--k:su-co-ph09-loi-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện chuyển và cơ chế thử lại khi PH-09 vắng.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-18-050 · API-18-130 · ERR-18-053, 054.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-09 trả `503` ở bước 2.

**Các bước.**

1. SO chuyển nhưng thiếu số người ước tính.
2. SO chuyển đủ trường khi PH-09 vắng, tua đồng hồ 65 phút.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-053. Bước 2 `503` ERR-18-054, hệ thống thử lại mỗi 5 phút; sau 1 giờ SO nhận thông báo `URGENT`; khi PH-09 trở lại thì chuyển một lần.

**Thông báo hiển thị.** ERR-18-053: "Cần nêu loại dữ liệu cá nhân, số người ước tính và thời điểm phát hiện." ERR-18-054: "Chưa chuyển được sang phân hệ quyền riêng tư. Hệ thống sẽ thử lại mỗi 5 phút; báo ngay cán bộ ATTT nếu quá 1 giờ."
:::

### TS-18-30 · Theo dõi sao lưu, kiểm tra khôi phục và ghi nhận diễn tập DR

**Mục tiêu.** Chứng minh bảng điều khiển sao lưu thu trạng thái từ công cụ nguồn trong độ tươi cho phép, cảnh báo sao lưu lỗi hoặc trễ, ghi kết quả kiểm tra khôi phục và biên bản diễn tập có tổng kiểm tra.

**Phủ.** FR-18-052, 053, 058; API-18-133…137, 154, 155; BR-18-048; ERR-18-001, 003, 055, 122; EVT-18-19, 20; NFR-18-012; LGC-NFR-005.

#### TC-18-099 · Tác vụ thu thập báo bản sao lưu, bảng điều khiển hiện độ tươi <!--k:sao-luu-bang-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-052: đối tượng theo D03-09 §8.2 có lần chạy gần nhất, kết quả, dung lượng, độ tươi `FRESH`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-052 · API-18-133, 134, 135 · BR-18-048 · NFR-18-012 · LGC-NFR-005 · UI-18-19.

**Tiền điều kiện, dữ liệu.** T90; S-BACKUP (`ops:backup-report`); đối tượng `pg-core/T90`, `garage/dh-t90-*`, `openbao/T90`.

**Các bước.**

1. S-BACKUP `POST /ops/internal/v1/backup/runs` cho ba đối tượng (CNPG/Barman, rclone Garage, OpenBao).
2. U-PO1 mở `/van-hanh/sao-luu`.
3. `GET /backup/runs?doiTuong=pg-core/T90`.

**Kết quả mong đợi.** Bước 1 `201` mỗi lần, có `sha256` biên bản khi có. Bước 2 ba dòng `FRESH`, thời điểm lần chạy gần nhất trễ ≤ 15 phút so với nguồn. Bước 3 lịch sử đúng.
:::

#### TC-18-100 · Sao lưu trễ quá 26 giờ phát cảnh báo và mở sự cố, thu thập lỗi <!--k:sao-luu-tre-->

::: dac-ta
**Mục đích.** Chứng minh EVT-18-19 khi trễ quá `18.backup.stale-hours`, sự cố tự mở (FR-18-047), lỗi thu thập ghi rõ công cụ.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** JOB, IT.

**Truy vết.** FR-18-052, 047 · API-18-133 · ERR-18-055, 122 · EVT-18-19, 17.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả); `pg-core/T95` lần cuối 27 giờ trước; WireMock Velero trả `500`.

**Các bước.**

1. Chạy tác vụ kiểm độ tươi.
2. Chạy tác vụ thu thập Velero.
3. `GET /backup/objects` khi tác vụ thu thập không lấy được trạng thái.

**Kết quả mong đợi.** Bước 1 đối tượng `STALE`, EVT-18-19 `reason = STALE`, sự cố `SEV2` mở. Bước 2 ghi ERR-18-122. Bước 3 `200` có cờ `collectorError` và câu ERR-18-055 ở UI-18-19.

**Thông báo hiển thị.** ERR-18-122 (hiện ở màn vận hành, không trả qua HTTP): "Chưa thu được trạng thái của {đối tượng}." ERR-18-055: "Chưa thu được trạng thái sao lưu từ {công cụ}."
:::

#### TC-18-101 · CronJob báo kết quả kiểm tra khôi phục, đối tượng không có trả 404 <!--k:kiem-tra-khoi-phuc-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-053: kết quả có số dòng lệch, thời lượng; EVT-18-20 phát; kết quả thất bại làm đối tượng mất trạng thái "0 lỗi".

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-053 · API-18-136, 137 · ERR-18-001 · EVT-18-20 · UI-18-19.

**Tiền điều kiện, dữ liệu.** T90; S-BACKUP.

**Các bước.**

1. S-BACKUP `POST /ops/internal/v1/backup/verifications` `pg-core/T90` `PASSED`.
2. Gửi kết quả `FAILED` cho `garage/dh-t90-ops`.
3. Gửi cho đối tượng `khong-co`.

**Kết quả mong đợi.** Bước 1 `201`, EVT-18-20. Bước 2 `201`, UI-18-19 hiện đối tượng đỏ. Bước 3 `404` ERR-18-001.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

#### TC-18-102 · Ghi nhận diễn tập DR và PITR có RTO, RPO, biên bản SHA-256 <!--k:dien-tap-dr-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-058: chỉ ghi nhận, không chạy; thiếu biên bản hoặc RTO âm bị từ chối.

**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-18-058 · API-18-154, 155 · BR-18-048 · ERR-18-003 · UI-18-19.

**Tiền điều kiện, dữ liệu.** U-PA1; biên bản PDF đã tải lên Garage.

**Các bước.**

1. `POST /dr-drills` loại `PITR_CLUSTER`, RTO 95 phút, RPO 4 phút, biên bản kèm `sha256`.
2. Gửi lại thiếu biên bản và RTO -5.
3. `GET /dr-drills`.

**Kết quả mong đợi.** Bước 1 `201`. Bước 2 `400` ERR-18-003. Bước 3 danh sách có diễn tập vừa ghi.

**Thông báo hiển thị.** ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}."
:::

### TS-18-31 · Yêu cầu, duyệt và chạy khôi phục tenant tám bước

**Mục tiêu.** Chứng minh TA tạo yêu cầu khôi phục, PA khác người tạo duyệt, Job `dh-tenant-restore` chạy tám bước RBK-04 với tenant `SUSPENDED` từ bước 4 đến 8, không khôi phục kiểm toán, không chạm tenant khác, lỗi ở bước 2 đến 4 dừng không đổi dữ liệu và lỗi từ bước 5 quay lui.

**Phủ.** FR-18-054, 055; API-18-138…146; BR-18-038, 039, 047; ERR-18-005, 056, 057, 058, 114, 115; EVT-18-21, 22; NFR-18-010, 017.

#### TC-18-103 · Khôi phục T90 về thời điểm 3 ngày trước, đủ tám bước, tenant khác không đổi <!--k:khoi-phuc-duong-->

::: dac-ta
**Mục đích.** Chứng minh đường chính của RBK-04 và AC-18-10: dữ liệu về đúng thời điểm đích trong phạm vi, kiểm toán không bị khôi phục, T91 trên cùng ô CSDL không bị chạm.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB, API, E2E.

**Truy vết.** FR-18-054, 055 · API-18-138, 139, 140, 141, 142, 145 · BR-18-038, 039, 047 · EVT-18-21, 22 · NFR-18-017 · UI-18-20, 15.

**Tiền điều kiện, dữ liệu.** STAGING; T90 và T91 cùng ô `pg-core`; U-T90-TA1 (`PERM-18-backup`), U-PA2 (`PERM-18-approve`); bản băm số dòng mỗi bảng của T91 trước khi chạy.

**Các bước.**

1. TA1 `POST /tenant-restores` thời điểm đích 3 ngày trước, phạm vi toàn tenant; `:submit`.
2. PA2 mở việc `ph18.approve-restore`, `:approve` kèm `maintenanceNotice = true`.
3. Theo dõi `GET /tenant-restores/{requestId}/steps` tới khi xong.
4. So bản băm số dòng của T91 và kiểm bảng kiểm toán PH-13 của T90.

**Kết quả mong đợi.** Bước 1 `201` `DRAFT` rồi `PENDING_APPROVAL`. Bước 2 `200` `RUNNING` có `jobName`. Bước 3 tám bước `SUCCEEDED` theo thứ tự; tenant `SUSPENDED` ở bước 4 đến 8 rồi `ACTIVE`; EVT-18-21 mỗi bước, đúng một EVT-18-22; TA1 và PA2 nhận thông báo. Bước 4 T91 không đổi; bản ghi kiểm toán của T90 sau thời điểm đích vẫn còn, có thêm bản kiểm toán khôi phục với số dòng thay mỗi bảng.
:::

#### TC-18-104 · Thời điểm ngoài cửa sổ PITR, phạm vi sai, tác vụ nặng khác và người tạo tự duyệt <!--k:khoi-phuc-dieu-kien-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện chặn khi tạo và khi duyệt khôi phục (BR-18-038, 039).

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-054, 055 · API-18-138, 142, 143, 144 · BR-18-038, 039 · ERR-18-005, 056, 057, 058.

**Tiền điều kiện, dữ liệu.** T90; U-T90-TA1 có cả `PERM-18-approve` để kiểm tách nhiệm vụ; lệnh xuất `EXP-T90-01` đang `RUNNING` ở bước 3.

**Các bước.**

1. Tạo yêu cầu thời điểm 31 ngày trước.
2. Tạo yêu cầu phạm vi gồm phân hệ `PH-99`.
3. Tạo yêu cầu hợp lệ khi `EXP-T90-01` đang chạy.
4. Sau khi xuất xong, tạo, gửi, rồi TA1 tự `:approve`.
5. PA2 `:reject` kèm lý do; tạo yêu cầu khác rồi TA1 `:cancel`.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-056. Bước 2 `422` ERR-18-058. Bước 3 `409` ERR-18-057. Bước 4 `403` ERR-18-005. Bước 5 `REJECTED`, `CANCELLED`, không có Job.

**Thông báo hiển thị.** ERR-18-056: "Thời điểm {thời điểm} nằm ngoài cửa sổ khôi phục 30 ngày." ERR-18-058: "Phạm vi khôi phục không hợp lệ: {chi tiết}." ERR-18-057: "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục." ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

#### TC-18-105 · Lỗi ở bước 3 dừng khôi phục, dữ liệu không đổi, tenant trở về ACTIVE <!--k:khoi-phuc-loi-buoc-3-->

::: dac-ta
**Mục đích.** Chứng minh luồng thay thế của FR-18-055 và ĐN-UC-15: lỗi ở bước 2 đến 4 không đổi dữ liệu.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-18-055 · API-18-145 · BR-18-038 · ERR-18-114 · EVT-18-21.

**Tiền điều kiện, dữ liệu.** STAGING; T90; tiêm lỗi `COPY` ở bước 3 (đĩa tạm đầy); băm số dòng T90 trước khi chạy.

**Các bước.**

1. PA2 duyệt yêu cầu, Job chạy.
2. Đọc các bước và trạng thái tenant.

**Kết quả mong đợi.** Bước 3 `FAILED` ghi ERR-18-114; yêu cầu `FAILED`; tenant `ACTIVE` (chưa từng `SUSPENDED` vì lỗi trước bước 4); băm số dòng T90 không đổi; cụm tạm đã xóa.

**Thông báo hiển thị.** ERR-18-114 (hiện ở màn vận hành, không trả qua HTTP): "Bước {n} của khôi phục lỗi: {mô tả}. Hệ thống đang quay lui."
:::

#### TC-18-106 · Lỗi ở bước 5 tự quay lui từ bản trích, PA quay lui tay khi tự động thất bại <!--k:khoi-phuc-loi-buoc-5-->

::: dac-ta
**Mục đích.** Chứng minh ĐN-UC-15: lỗi từ bước 5 phải quay lui, yêu cầu `ROLLED_BACK`, dữ liệu như trước khi chạy.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** JOB, API.

**Truy vết.** FR-18-055 · API-18-145, 146 · BR-18-038 · ERR-18-114 · EVT-18-21.

**Tiền điều kiện, dữ liệu.** STAGING; T90; tiêm lỗi giao dịch thay dữ liệu PH-04 ở bước 5; lần hai tiêm thêm lỗi quay lui tự động.

**Các bước.**

1. Chạy khôi phục lần một.
2. Chạy lần hai, quay lui tự động thất bại, PA2 `POST /tenant-restores/{requestId}:rollback`.

**Kết quả mong đợi.** Lần một bước 5 ghi ERR-18-114, Job quay lui, yêu cầu `ROLLED_BACK`, tenant `ACTIVE`, băm số dòng như trước. Lần hai yêu cầu dừng chờ PA, `:rollback` `202`, kết thúc `ROLLED_BACK`; KT: có (restore-rollback).

**Thông báo hiển thị.** ERR-18-114 (hiện ở màn vận hành, không trả qua HTTP): "Bước {n} của khôi phục lỗi: {mô tả}. Hệ thống đang quay lui."
:::

#### TC-18-107 · Đối chiếu số dòng ở bước 8 lệch thì tenant giữ SUSPENDED chờ PA <!--k:khoi-phuc-lech-dong-->

::: dac-ta
**Mục đích.** Chứng minh ERR-18-115: không mở lại tenant khi số dòng lệch bản trích.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-18-055 · API-18-145 · BR-18-038 · ERR-18-115.

**Tiền điều kiện, dữ liệu.** STAGING; T90; xóa một dòng của bảng `ph02_catalog.api` trong cụm tạm sau bước 5 để giả lập lệch.

**Các bước.**

1. Chạy khôi phục.

**Kết quả mong đợi.** Bước 8 ghi ERR-18-115 nêu bảng; tenant giữ `SUSPENDED`; UI-18-20 hiện câu "Số dòng sau khôi phục lệch ở {bảng}."; PA nhận việc quyết định.

**Thông báo hiển thị.** ERR-18-115 (hiện ở màn vận hành, không trả qua HTTP): "Số dòng sau khôi phục lệch ở {bảng}."
:::

### TS-18-32 · Xuất dữ liệu tenant

**Mục tiêu.** Chứng minh xuất dữ liệu tenant tạo gói có manifest SHA-256, liên kết tải hạn 24 giờ có kiểm toán, chặn khi trạng thái tenant không phù hợp hoặc có tác vụ nặng khác.

**Phủ.** FR-18-056; API-18-147, 148, 149; BR-18-039, 048; ERR-18-057, 059, 116; EVT-18-23; NFR-18-011.

#### TC-18-108 · Xuất T93 khi DECOMMISSIONED, tải bằng liên kết 24 giờ <!--k:xuat-tenant-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-056: gói có manifest và tổng kiểm tra 100 % tệp, liên kết tải có hạn, EVT-18-23 cho PH-20.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB, API.

**Truy vết.** FR-18-056 · API-18-147, 148, 149 · BR-18-048 · EVT-18-23 · UI-18-20.

**Tiền điều kiện, dữ liệu.** T93 trạng thái `DECOMMISSIONED` (WireMock PH-20); U-PA1 (`PERM-18-backup`).

**Các bước.**

1. `POST /tenant-exports` mục đích `HANDOVER`.
2. Theo dõi `GET /tenant-exports/{exportId}`.
3. `POST /tenant-exports/{exportId}:download-link`.
4. Kiểm tổng kiểm tra từng tệp.

**Kết quả mong đợi.** Bước 2 `SUCCEEDED`, `sizeBytes`, `manifestSha256`; EVT-18-23. Bước 3 `200` liên kết hết hạn sau `18.export.link-ttl-hours`, KT: có. Bước 4 100 % tệp khớp manifest.
:::

#### TC-18-109 · Xuất với trạng thái tenant không phù hợp, tác vụ nặng khác và Job lỗi <!--k:xuat-tenant-loi-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện chặn của xuất tenant.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-18-056 · API-18-147 · BR-18-039 · ERR-18-057, 059, 116.

**Tiền điều kiện, dữ liệu.** T90 `ACTIVE`; khôi phục `RST-T90-02` đang chạy ở bước 2; tiêm lỗi Garage ở bước 3.

**Các bước.**

1. Xuất T90 mục đích `HANDOVER`.
2. Xuất T90 mục đích `CELL_MOVE` khi khôi phục đang chạy.
3. Xuất T93 khi Garage lỗi.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-059. Bước 2 `409` ERR-18-057. Bước 3 lệnh xuất `FAILED` ghi ERR-18-116, gói dở dang bị xóa.

**Thông báo hiển thị.** ERR-18-059: "Tỉnh đang ở trạng thái {trạng thái}, chưa xuất được với mục đích {mục đích}." ERR-18-057: "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục." ERR-18-116 (hiện ở màn vận hành, không trả qua HTTP): "Xuất dữ liệu chưa thành công: {lý do}."
:::

### TS-18-33 · Chuyển dữ liệu phân hệ khi sáp nhập tenant theo yêu cầu PH-20

**Mục tiêu.** Chứng minh PH-20 gọi PH-18 chuyển dữ liệu từng phân hệ với chạy thử trước, giữ `id` gốc, ghi `origin_tenant_id`, lũy đẳng theo `mergePlanId:module`, báo tiến độ về PH-20 và thử lại khi báo lỗi.

**Phủ.** FR-18-057; API-18-150…153; BR-18-039, 045, 047; ERR-18-060, 061, 123; EVT-18-24; NFR-18-022.

#### TC-18-110 · PH-20 yêu cầu chạy thử rồi chạy thật chuyển dữ liệu PH-04 từ T92 sang T90 <!--k:sap-nhap-duong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-045: bản ghi giữ `id` gốc, có `origin_tenant_id = T92`, chạy thử không ghi, tiến độ báo về PH-20.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, JOB.

**Truy vết.** FR-18-057 · API-18-150, 151, 152 · BR-18-045, 047 · EVT-18-24 · UI-18-20.

**Tiền điều kiện, dữ liệu.** STAGING; S-PH20 (`ops:merge-transfer`); `mergePlanId = MP-01`, `module = PH-04`, `mappingRef` hợp lệ; WireMock PH-20 nhận báo tiến độ.

**Các bước.**

1. S-PH20 `POST /merge-transfers` `dryRun = true`.
2. S-PH20 gửi lại với `dryRun = false`.
3. Theo dõi `GET /merge-transfers/{transferId}`.
4. Kiểm dòng ở T90.

**Kết quả mong đợi.** Bước 1 `202`, kết quả số bản ghi dự kiến, không ghi dòng nào. Bước 2 `202`. Bước 3 `SUCCEEDED`; EVT-18-24 theo trạng thái; PH-20 nhận báo cáo `:report`. Bước 4 mọi dòng chuyển có `origin_tenant_id = T92` và `id` như ở T92; 0 dòng mất `origin_tenant_id`.
:::

#### TC-18-111 · Yêu cầu sáp nhập sai, trùng khóa khác nội dung, báo tiến độ lỗi, hủy chuyển <!--k:sap-nhap-loi-->

::: dac-ta
**Mục đích.** Chứng minh điều kiện của API chuyển sáp nhập và thử lại khi báo PH-20 lỗi.

**Loại.** Âm, Lũy đẳng, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-057 · API-18-150, 153 · BR-18-045 · ERR-18-060, 061, 123.

**Tiền điều kiện, dữ liệu.** STAGING; S-PH20; `MP-01:PH-04` đã chạy; WireMock PH-20 trả `503` cho `:report` ở bước 3.

**Các bước.**

1. Gửi yêu cầu `sourceTenant = targetTenant`.
2. Gửi `MP-01:PH-04` với `mappingRef` khác.
3. Chạy `MP-01:PH-07`, PH-20 không nhận báo cáo trong 10 phút.
4. S-PH20 `POST /merge-transfers/{transferId}:cancel` cho một chuyển đang chạy; gửi lại `MP-01:PH-04` cùng nội dung.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-060. Bước 2 `409` ERR-18-061. Bước 3 ghi ERR-18-123 mỗi lần thử, báo cáo gửi được khi PH-20 trở lại, không mất trạng thái. Bước 4 chuyển dừng sau lô hiện hành `CANCELLED`; gửi lại cùng nội dung trả `200` bản ghi cũ.

**Thông báo hiển thị.** ERR-18-060: "Yêu cầu chuyển sáp nhập không hợp lệ: {lý do}." ERR-18-061: "Đã có yêu cầu chuyển dữ liệu {phân hệ} cho kế hoạch {mã} với nội dung khác." ERR-18-123 (hiện ở màn vận hành, không trả qua HTTP): "Chưa báo được tiến độ sáp nhập; đang thử lại."
:::

### TS-18-34 · Khai báo nguồn hệ cũ và lập kế hoạch di trú

**Mục tiêu.** Chứng minh nguồn hệ cũ chỉ khai bằng tham chiếu kho bí mật, tài khoản phải chỉ có quyền đọc, kế hoạch di trú có thứ tự phụ thuộc hợp lệ trước khi `READY`.

**Phủ.** FR-18-059, 060; API-18-156…163; BR-18-040, 048; ERR-18-003, 062, 063, 070; UI-18-21.

#### TC-18-112 · Khai báo nguồn Aita bằng tham chiếu OpenBao và thử kết nối chỉ đọc <!--k:nguon-he-cu-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-059: thông tin kết nối chỉ là tham chiếu `kv/dh/t96/legacy/aita`, thử kết nối kiểm quyền `SELECT` và đếm bảng.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-059 · API-18-156, 157, 158 · BR-18-040, 048 · UI-18-21.

**Tiền điều kiện, dữ liệu.** T96; PostgreSQL giả lập hệ cũ `LEG-AITA` có tài khoản chỉ đọc; OpenBao dev có khóa tại `kv/dh/t96/legacy/aita`; U-T96-TA1 (`PERM-18-migration`).

**Các bước.**

1. `POST /legacy-sources` `LEG-AITA`, JDBC, `credentialRef` trỏ tới `kv/dh/t96/legacy/aita`.
2. `POST /legacy-sources/LEG-AITA:test-connection`.
3. `GET /legacy-sources`.

**Kết quả mong đợi.** Bước 1 `201`, không lưu giá trị bí mật trong `ph18_ops`. Bước 2 `200` `readOnly = true`, số bảng. Bước 3 trạng thái kết nối `OK`.
:::

#### TC-18-113 · Nhập thẳng thông tin đăng nhập, tài khoản có quyền ghi, nguồn không kết nối được <!--k:nguon-he-cu-loi-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-040, 048: không nhận bí mật dạng rõ và không dùng tài khoản có quyền ghi.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-059 · API-18-157, 158 · BR-18-040, 048 · ERR-18-062, 070.

**Tiền điều kiện, dữ liệu.** T96; `LEG-RW` có tài khoản có quyền `INSERT`; `LEG-DOWN` địa chỉ không mở.

**Các bước.**

1. Khai nguồn với trường thông tin đăng nhập dạng chữ rõ thay cho tham chiếu kho bí mật.
2. Khai `LEG-RW` bằng tham chiếu, `:test-connection`.
3. `:test-connection` cho `LEG-DOWN`.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-070, không có bản ghi, log không chứa chuỗi đã gửi. Bước 2 `422` ERR-18-062 nêu quyền thừa. Bước 3 `422` ERR-18-062 nêu lỗi kết nối.

**Thông báo hiển thị.** ERR-18-070: "Thông tin kết nối phải là tham chiếu kho bí mật, không nhập mật khẩu trực tiếp." ERR-18-062: "Nguồn {mã} không kết nối được hoặc tài khoản không phải chỉ đọc: {chi tiết}."
:::

#### TC-18-114 · Lập kế hoạch theo thứ tự phụ thuộc, phụ thuộc vòng bị chặn <!--k:ke-hoach-di-tru-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-060: danh mục Aita → PH-07 đứng trước HTTT → PH-01 và API → PH-02; phụ thuộc vòng hoặc thiếu tiền đề bị từ chối khi `:mark-ready`.

**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-060 · API-18-159, 160, 161, 162, 163 · BR-18-040 · ERR-18-003, 063 · UI-18-21.

**Tiền điều kiện, dữ liệu.** T96; `LEG-AITA`; U-T96-TA1.

**Các bước.**

1. `POST /migration-plans` `PLAN-AITA`.
2. `PUT /migration-plans/PLAN-AITA/items` với `CATALOG → PH-07`, `APPLICATION → PH-01`, `API → PH-02` và phụ thuộc đúng.
3. `:mark-ready`.
4. Tạo `PLAN-VONG` có `API` phụ thuộc `APPLICATION` và ngược lại, `:mark-ready`; tạo kế hoạch có loại đối tượng `XYZ`.

**Kết quả mong đợi.** Bước 3 `200` `READY`, thứ tự chạy hiện ở UI-18-21. Bước 4 `422` ERR-18-063 liệt kê vòng; loại lạ `400` ERR-18-003.

**Thông báo hiển thị.** ERR-18-063: "Kế hoạch có phụ thuộc vòng hoặc thiếu đối tượng tiền đề: {danh sách}." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}."
:::

### TS-18-35 · Chạy thử di trú, đối chiếu và xử lý bản ghi lỗi

**Mục tiêu.** Chứng minh chạy thử không ghi vào phân hệ đích, bản ghi không chuyển đổi được có danh sách lỗi và lý do, báo cáo đối chiếu có số lượng và tổng kiểm tra, chạy lại chỉ bản ghi lỗi được.

**Phủ.** FR-18-061, 063, 064; API-18-164…166, 169, 170, 171, 182; BR-18-040, 041, 043; ERR-18-036, 065, 117, 118, 120; EVT-18-25.

#### TC-18-115 · Chạy thử kế hoạch READY không ghi vào phân hệ đích, có báo cáo đối chiếu <!--k:chay-thu-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-061 và BR-18-043: worker `dh-migrate` đọc nguồn chỉ đọc, gọi API nhập của đích ở chế độ kiểm (`dryRun`), không có bản ghi nào được ghi, không có sự kiện nghiệp vụ.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB, API.

**Truy vết.** FR-18-061, 064 · API-18-164, 165, 166, 171 · BR-18-040, 043 · EVT-18-25 · UI-18-21, 22.

**Tiền điều kiện, dữ liệu.** T96; `PLAN-AITA` `READY`; `LEG-AITA` có 12.000 danh mục, 180 HTTT, 900 API (giả định quy mô GĐ-01); WireMock API nhập PH-07, PH-01, PH-02 đếm lời gọi ghi.

**Các bước.**

1. `POST /migration-runs` `mode = DRY_RUN`.
2. Theo dõi `GET /migration-runs/{runId}` tới xong.
3. `GET /migration-runs/{runId}/reconciliation`.

**Kết quả mong đợi.** Bước 2 `SUCCEEDED`, đọc 13.080, hợp lệ 13.080; WireMock nhận 0 lời gọi ghi thật; không có sự kiện nghiệp vụ của PH-07, PH-01, PH-02; EVT-18-25 `mode = DRY_RUN`. Bước 3 báo cáo theo đối tượng có số nguồn, số đích dự kiến, tổng kiểm tra.
:::

#### TC-18-116 · Kế hoạch chưa READY, nguồn đọc lỗi, bộ chuyển đổi lỗi bản ghi <!--k:chay-thu-loi-->

::: dac-ta
**Mục đích.** Chứng minh lỗi di trú được ghi đúng mã ở mức lần chạy và bản ghi.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-18-061, 063 · API-18-164, 169, 170 · ERR-18-065, 117, 118.

**Tiền điều kiện, dữ liệu.** T96; `PLAN-NHAP` `DRAFT`; `LEG-AITA` có 15 danh mục thiếu mã cha; ngắt nguồn ở bước 3.

**Các bước.**

1. Chạy thử `PLAN-NHAP`.
2. Chạy thử `PLAN-AITA`, xem `GET /migration-runs/{runId}/errors`.
3. Chạy thử lần hai và ngắt nguồn giữa chừng; `:cancel` lần chạy còn lại.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-065. Bước 2 `SUCCEEDED_WITH_ERRORS`, 15 bản ghi lỗi ERR-18-118 có khóa hệ cũ và lý do, xuất CSV được. Bước 3 lần chạy `FAILED` ghi ERR-18-117; lần hủy dừng sau lô hiện hành `CANCELLED`.

**Thông báo hiển thị.** ERR-18-065: "Kế hoạch {mã} chưa ở trạng thái sẵn sàng." ERR-18-118 (hiện ở màn vận hành, không trả qua HTTP): "Bản ghi {khóa} không chuyển đổi được: {lý do}." ERR-18-117 (hiện ở màn vận hành, không trả qua HTTP): "Không đọc được nguồn hệ cũ ở bảng {bảng}: {chi tiết}."
:::

#### TC-18-117 · Sửa ở nguồn rồi chạy lại chỉ các bản ghi lỗi, không còn bản ghi để chạy <!--k:chay-lai-ban-ghi-loi-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-063: chạy lại theo danh sách lỗi, bản ghi đã sửa chuyển `FIXED_AT_SOURCE`, khi không còn bản ghi lỗi thì từ chối.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, JOB.

**Truy vết.** FR-18-063 · API-18-164, 170 · BR-18-041 · ERR-18-036.

**Tiền điều kiện, dữ liệu.** T96; lần chạy `RUN-DRY-02` có 15 bản ghi lỗi; DS sửa mã cha ở nguồn.

**Các bước.**

1. U-T96-DS `POST /migration-runs` `mode = DRY_RUN`, `retryOf = RUN-DRY-02`.
2. Gửi lại bước 1 khi không còn bản ghi `OPEN`.

**Kết quả mong đợi.** Bước 1 lần chạy chỉ đọc 15 bản ghi, 15 hợp lệ, danh sách lỗi cũ `FIXED_AT_SOURCE`. Bước 2 `422` ERR-18-036.

**Thông báo hiển thị.** ERR-18-036: "Không có mục nào phù hợp để {thao tác}."
:::

#### TC-18-118 · Tổng kiểm tra của một đối tượng lệch được báo trong đối chiếu <!--k:doi-chieu-tong-kiem-tra-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-064: lệch tổng kiểm tra không bị che, đối chiếu yêu cầu giải trình.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** JOB, API.

**Truy vết.** FR-18-064 · API-18-171 · BR-18-041 · ERR-18-120.

**Tiền điều kiện, dữ liệu.** T96; WireMock PH-07 trả tổng kiểm tra khác cho đối tượng `CATALOG` (giả lập một mã bị chuẩn hóa).

**Các bước.**

1. Chạy thử `PLAN-AITA`.
2. Tải báo cáo đối chiếu PDF và CSV.

**Kết quả mong đợi.** Lần chạy ghi ERR-18-120 cho `CATALOG`; báo cáo đánh dấu dòng lệch, trường "giải trình" bắt buộc trước khi chạy thật.

**Thông báo hiển thị.** ERR-18-120 (hiện ở màn vận hành, không trả qua HTTP): "Tổng kiểm tra của {đối tượng} lệch."
:::

#### TC-18-167 · Đánh dấu cách xử lý bản ghi lỗi di trú, WONT_MIGRATE cần lý do <!--k:di-tru-danh-dau-loi-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-063 bước 2 qua API-18-182: đánh dấu một hoặc nhiều bản ghi lỗi, `WONT_MIGRATE` có lý do và vào báo cáo đối chiếu như chênh lệch đã giải trình.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-18-063 · API-18-182, 170, 171 · BR-18-041 · ERR-18-007, 036 · UI-18-22.

**Tiền điều kiện, dữ liệu.** T96; lần chạy `RUN-DRY-02` có 29 bản ghi lỗi `OPEN`; U-T96-DS có `PERM-18-migration`.

**Các bước.**

1. DS `PATCH /migration-runs/RUN-DRY-02/errors` đặt 25 bản ghi `FIXED_AT_SOURCE`.
2. DS đặt 4 bản ghi `WONT_MIGRATE` kèm `reason` "HTTT đã ngừng từ 2024".
3. DS đặt 1 bản ghi `WONT_MIGRATE` với `reason` 5 ký tự.
4. DS gửi bộ lọc không khớp bản ghi nào.
5. Tải báo cáo đối chiếu (API-18-171).

**Kết quả mong đợi.** Bước 1, 2 `200` kết quả theo từng bản ghi, không bản ghi nào còn `OPEN`. Bước 3 `422` ERR-18-007, bản ghi giữ trạng thái cũ. Bước 4 `422` ERR-18-036. Bước 5 bốn bản ghi `WONT_MIGRATE` hiện ở dòng chênh lệch đã giải trình kèm lý do; kiểm toán ghi người, số bản ghi, cách xử lý.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

### TS-18-36 · Chạy thật di trú có duyệt bốn mắt và đánh dấu cấp lại xác thực

**Mục tiêu.** Chứng minh chạy thật cần chạy thử thành công gần đây và người duyệt khác người tạo, bị chặn trong cửa sổ đóng băng hoặc khi có tác vụ nặng khác, ghi vào phân hệ đích qua API nhập với cờ `migration = true`, chạy lại không tạo bản trùng, và thông tin xác thực không di trú mà được đánh dấu cấp lại.

**Phủ.** FR-18-062, 064, 065; API-18-164, 167, 168, 172, 183; BR-18-039, 041, 042, 043; ERR-18-005, 051, 057, 064, 069, 119, 124; EVT-18-25, 26; NFR-18-014.

#### TC-18-119 · Chạy thật sau chạy thử, PA duyệt, ghi qua API nhập với migration = true <!--k:chay-that-duong-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-062: chạy thật đi `PENDING_APPROVAL → QUEUED → RUNNING → SUCCEEDED`, ghi qua API nhập của PH-07, PH-01, PH-02, không phát sự kiện nghiệp vụ hàng loạt.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** JOB, API, E2E.

**Truy vết.** FR-18-062, 064 · API-18-164, 166, 167, 171 · BR-18-040, 041, 043 · EVT-18-25 · UI-18-15, 21, 22.

**Tiền điều kiện, dữ liệu.** T96; chạy thử `PLAN-AITA` thành công 2 ngày trước, đối chiếu đã giải trình; U-T96-TA1 tạo, U-PA2 duyệt.

**Các bước.**

1. TA1 `POST /migration-runs` `mode = REAL`.
2. PA2 mở việc, `:approve`.
3. Theo dõi lần chạy tới xong.
4. Đếm bản ghi ở WireMock đích và sự kiện nghiệp vụ.

**Kết quả mong đợi.** Bước 1 `201` `PENDING_APPROVAL`. Bước 2 `QUEUED` rồi `RUNNING`. Bước 3 `SUCCEEDED`, EVT-18-25 `mode = REAL`. Bước 4 mỗi lời gọi nhập có cờ `migration = true`; 0 sự kiện nghiệp vụ hàng loạt; số ghi khớp đối chiếu.
:::

#### TC-18-120 · Không có chạy thử gần đây, đang đóng băng, tác vụ nặng khác, người tạo tự duyệt <!--k:chay-that-dieu-kien-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-041, 039 và LP-18-01 cho chạy thật.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-062 · API-18-164, 167, 168 · BR-18-039, 041 · ERR-18-005, 051, 057, 064.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả) với bản sao `PLAN-AITA`; chạy thử thành công 8 ngày trước; U-T95-TA1 có cả `PERM-18-approve`.

**Các bước.**

1. Tạo chạy thật.
2. Chạy thử lại thành công, tạo cửa sổ `FREEZE` hiện hành, tạo chạy thật.
3. Hủy cửa sổ, tạo khôi phục chạy song song, tạo chạy thật.
4. Khi không còn tác vụ nặng, tạo chạy thật và TA1 tự `:approve`; PA2 `:reject`.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-064. Bước 2 `409` ERR-18-051. Bước 3 `409` ERR-18-057. Bước 4 `403` ERR-18-005; sau đó `REJECTED`.

**Thông báo hiển thị.** ERR-18-064: "Cần một lần chạy thử thành công trong {ngày} ngày gần nhất trước khi chạy thật." ERR-18-051: "Đang trong thời gian đóng băng thay đổi {cửa sổ} nên chưa chạy thật được." ERR-18-057: "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục." ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

#### TC-18-121 · Phân hệ đích không nhận lô thì tạm dừng, từ chối bản ghi thì ghi lỗi <!--k:chay-that-dich-loi-->

::: dac-ta
**Mục đích.** Chứng minh lỗi phía đích không làm mất bản ghi và lần chạy tiếp tục được.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-18-062, 063 · API-18-166, 170 · ERR-18-069, 119.

**Tiền điều kiện, dữ liệu.** T96; WireMock PH-01 trả `503` từ lô thứ 2, trả `422` cho 3 HTTT thiếu cơ quan chủ quản.

**Các bước.**

1. Chạy thật đã duyệt.
2. Khôi phục WireMock, tiếp tục lần chạy.

**Kết quả mong đợi.** Bước 1 lần chạy tạm dừng ghi ERR-18-069 ở UI-18-22. Bước 2 chạy tiếp từ lô dở, kết thúc `SUCCEEDED_WITH_ERRORS`, 3 bản ghi lỗi ERR-18-119 kèm mã lỗi của PH-01.

**Thông báo hiển thị.** ERR-18-069: "Phân hệ {ph} không nhận dữ liệu. Lần chạy tạm dừng và tự thử lại sau {phút} phút." ERR-18-119 (hiện ở màn vận hành, không trả qua HTTP): "Phân hệ đích từ chối bản ghi {khóa}: {mã lỗi}."
:::

#### TC-18-122 · Chạy lại toàn bộ lần chạy thật ba lần không tạo bản trùng <!--k:chay-that-luy-dang-->

::: dac-ta
**Mục đích.** Chứng minh NFR-18-014 và BR-18-041: khóa `legacySystem:objectType:legacyKey` bảo đảm 0 bản ghi trùng.

**Loại.** Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** FR-18-062 · BR-18-041 · NFR-18-014.

**Tiền điều kiện, dữ liệu.** T96 sau ca chạy thật; đếm bản ghi ở WireMock đích theo khóa.

**Các bước.**

1. Tạo và duyệt chạy thật lần 2, lần 3, lần 4 liên tiếp.

**Kết quả mong đợi.** Mỗi lần kết quả `written = 0`, `skipped = 13.080`; đích không có khóa trùng; báo cáo đối chiếu giữ nguyên.
:::

#### TC-18-123 · Thông tin xác thực không di trú, đánh dấu cấp lại và phát sự kiện cho PH-01, PH-03 <!--k:cap-lai-xac-thuc-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-042 và FR-18-065: không có giá trị xác thực nào rời nguồn, mỗi thông tin bỏ qua có dấu cấp lại; lỗi bộ tiêu thụ đi vào DLQ PH-18.

**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** JOB, API, KT.

**Truy vết.** FR-18-065, 062 · API-18-172 · BR-18-042 · EVT-18-26 · ERR-18-124 · UI-18-22, 23.

**Tiền điều kiện, dữ liệu.** T96; `LEG-AITA` có 40 khóa API của consumer và 12 chứng thư đối tác; lần chạy thật đã duyệt.

**Các bước.**

1. Chạy thật.
2. `GET /credential-reissues`.
3. Đọc `t96.ops.migration.credential-reissue-required.v1`.
4. Rà payload các lời gọi nhập và log của `dh-migrate`.
5. Làm bộ xử lý sự kiện cấp lại phía PH-18 lỗi năm lần.

**Kết quả mong đợi.** Bước 2 52 dấu cấp lại theo HTTT, trạng thái `REQUIRED`. Bước 3 EVT-18-26 theo `systemCode` có `credentialType`, `count`. Bước 4 không có giá trị xác thực nào. Bước 5 ghi ERR-18-124, mục DLQ `PH18_INBOX`.

**Thông báo hiển thị.** ERR-18-124 (hiện ở màn vận hành, không trả qua HTTP): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
:::

#### TC-18-168 · Đánh dấu WAIVED cho HTTT không còn dùng, dấu đã cấp lại bị từ chối <!--k:cap-lai-waive-->

::: dac-ta
**Mục đích.** Chứng minh luồng thay thế FR-18-065 qua API-18-183: dấu `PENDING` hoặc `NOTIFIED` chuyển `WAIVED` có lý do và được tính là đạt ở danh sách cắt chuyển.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-18-065, 068 · API-18-183, 172, 174 · ERR-18-006, 007 · UI-18-22.

**Tiền điều kiện, dữ liệu.** T96; dấu `MK-01` `NOTIFIED`, dấu `MK-02` `REISSUED` của nhóm `PG-THUE`; U-T96-TA1 có `PERM-18-migration`.

**Các bước.**

1. TA1 `POST /credential-reissues/MK-01:waive` kèm `reason` "HTTT dừng kết nối theo văn bản 12/STTTT".
2. TA1 `POST /credential-reissues/MK-01:waive` với `reason` rỗng.
3. TA1 `POST /credential-reissues/MK-02:waive` kèm lý do hợp lệ.
4. TA1 `GET /parallel-groups/PG-THUE` xem mục `CREDENTIALS_REISSUED`.

**Kết quả mong đợi.** Bước 1 `200` dấu `WAIVED`, ghi lý do và người đánh dấu; kiểm toán có. Bước 2 `422` ERR-18-007. Bước 3 `409` ERR-18-006, dấu giữ `REISSUED`. Bước 4 mục `CREDENTIALS_REISSUED` tính `MK-01` như đã đạt.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)." ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."
:::

### TS-18-37 · Theo dõi chạy song song và đối soát bóng

**Mục tiêu.** Chứng minh tình trạng chạy song song lấy từ cầu nối PH-10, mẫu so sánh chỉ là băm, mẫu lệch được ghi lại và chỉ danh tính bộ so sánh gửi được mẫu.

**Phủ.** FR-18-066, 067; API-18-173, 174, 176, 184; ERR-18-121, 124; ERR-00-403.

#### TC-18-124 · Theo dõi nhóm chạy song song, cầu nối PH-10 và tỷ lệ khớp mẫu bóng <!--k:song-song-duong-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-066, 067: trạng thái cầu nối từ EVT-10-15, EVT-10-16; bộ so sánh gửi cặp phản hồi đã băm; tỷ lệ khớp tính theo nhóm.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-18-066, 067 · API-18-173, 174, 176 · EVT-18-27 · UI-18-23.

**Tiền điều kiện, dữ liệu.** T96; nhóm `PG-THUE` 20 tuyến `PARALLEL`; S-SHADOW (`ops:shadow-ingest`); WireMock PH-10 phát EVT-10-15, EVT-10-16.

**Các bước.**

1. Phát EVT-10-15 (cầu nối hoạt động).
2. S-SHADOW gửi 1.000 cặp, 997 khớp băm.
3. `GET /parallel-groups/PG-THUE`.

**Kết quả mong đợi.** Bước 1 nhóm hiện cầu nối `ACTIVE`. Bước 2 `202`. Bước 3 tỷ lệ khớp 99,7 %, mẫu lệch có tuyến, thời điểm, không có nội dung phản hồi.
:::

#### TC-18-125 · Mẫu lệch, danh tính sai gửi mẫu và sự kiện cầu nối xử lý lỗi <!--k:song-song-lech-->

::: dac-ta
**Mục đích.** Chứng minh mẫu lệch được ghi ERR-18-121, scope `ops:shadow-ingest` là bắt buộc và lỗi tiêu thụ sự kiện PH-10 đi vào DLQ PH-18.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-18-067, 066 · API-18-176 · ERR-18-121, 124 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** T96; S-NOSCOPE; WireMock PH-10.

**Các bước.**

1. S-SHADOW gửi 100 cặp, 5 lệch ở tuyến `/thue/v1/to-khai`.
2. S-NOSCOPE gửi cặp.
3. Phát EVT-10-16 có thân hỏng làm bộ xử lý lỗi năm lần.

**Kết quả mong đợi.** Bước 1 5 mẫu lệch ghi ERR-18-121 nêu tuyến. Bước 2 `403` ERR-00-403. Bước 3 inbox `FAILED`, ghi ERR-18-124.

**Thông báo hiển thị.** ERR-18-121 (hiện ở màn vận hành, không trả qua HTTP): "Kết quả hệ mới khác hệ cũ ở {tuyến}." ERR-18-124 (hiện ở màn vận hành, không trả qua HTTP): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
:::

#### TC-18-169 · Thay bộ quy tắc chuẩn hóa so sánh, mẫu trong cửa sổ được tính lại <!--k:song-song-quy-tac-->

::: dac-ta
**Mục đích.** Chứng minh luồng thay thế FR-18-067 qua API-18-184: lệch đã biết được chấp nhận bằng quy tắc chuẩn hóa có `If-Match` và lý do, tỷ lệ khớp tính lại trên mẫu 7 ngày.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, JOB.

**Truy vết.** FR-18-067 · API-18-184, 174 · ERR-18-007 · ERR-00-428 · EVT-18-27 · UI-18-23.

**Tiền điều kiện, dữ liệu.** T96; nhóm `PG-HT` tỷ lệ khớp 98,9 % do định dạng ngày `dd/MM/yyyy` và `yyyy-MM-dd` lệch ở 1,2 % mẫu; U-T96-TA1 có `PERM-18-migration`.

**Các bước.**

1. TA1 `PUT /parallel-groups/PG-HT/normalization-rules` thêm quy tắc đổi trường `ngaySinh` về ISO 8601 kèm `If-Match` và lý do.
2. TA1 gửi lại bước 1 không có `If-Match`.
3. TA1 gửi bước 1 với lý do 3 ký tự.
4. Chờ bộ so sánh tính lại, `GET /parallel-groups/PG-HT`.

**Kết quả mong đợi.** Bước 1 `200` bộ quy tắc phiên bản mới, ETag mới. Bước 2 `428` ERR-00-428. Bước 3 `422` ERR-18-007. Bước 4 tỷ lệ khớp tính lại trên mẫu trong 7 ngày đạt ≥ 99,5 %; nhóm sang `SHADOW_OK` khi đủ điều kiện, EVT-18-27 phát.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

### TS-18-38 · Cắt chuyển nhóm dịch vụ và quay lui

**Mục tiêu.** Chứng minh cắt chuyển chỉ khi danh sách kiểm tra đạt và có người thứ hai duyệt, bị chặn khi tỷ lệ khớp dưới ngưỡng hoặc trong cửa sổ đóng băng, quay lui trong 15 phút không cần duyệt và quá 15 phút bị từ chối.

**Phủ.** FR-18-068; API-18-174, 175, 185; BR-18-044; ERR-18-005, 051, 066, 067, 068; EVT-18-27; NFR-18-015.

#### TC-18-126 · Danh sách kiểm tra đạt, đề nghị và người thứ hai duyệt cắt chuyển toàn phần <!--k:cat-chuyen-duong-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-044 và AC-18-12: `PARALLEL → SHADOW_OK → CUT_OVER`, EVT-18-27 cho PH-03 đổi tuyến APISIX, có `rollbackUntil`.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-068 · API-18-174, 175 · BR-18-044 · EVT-18-27 · UI-18-15, 23.

**Tiền điều kiện, dữ liệu.** T96; `PG-THUE` tỷ lệ khớp 99,7 %, DLQ của nhóm rỗng, 52 dấu cấp lại đã `REISSUED`, đối chiếu đã giải trình; U-T96-TA1 đề nghị, U-T96-TA2 duyệt.

**Các bước.**

1. TA1 mở UI-18-23, xem danh sách kiểm tra.
2. TA1 `:transition` `action = REQUEST`, `target = CUT_OVER`.
3. TA2 mở việc, `:transition` `action = APPROVE`.

**Kết quả mong đợi.** Bước 1 mọi mục `DLQ_EMPTY`, `MATCH_RATE`, `CREDENTIALS_REISSUED`, `RECONCILIATION_MATCHED` đạt. Bước 2 `202` chờ duyệt. Bước 3 `200` `CUT_OVER`, EVT-18-27 có `routes`, `rollbackUntil` = thời điểm + 15 phút; sổ cắt chuyển ghi người đề nghị, người duyệt.
:::

#### TC-18-127 · Danh sách kiểm tra chưa đạt, tỷ lệ khớp dưới ngưỡng, đóng băng, người đề nghị tự duyệt <!--k:cat-chuyen-chan-->

::: dac-ta
**Mục đích.** Chứng minh mọi điều kiện của BR-18-044 và LP-18-01.

**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-068 · API-18-175 · BR-18-044 · ERR-18-005, 051, 066, 067.

**Tiền điều kiện, dữ liệu.** T96; `PG-DAT` còn 3 mục DLQ mở; `PG-HT` tỷ lệ khớp 98,9 %; cửa sổ `FREEZE` ở bước 3; U-T96-TA1 có `PERM-18-approve`.

**Các bước.**

1. TA1 đề nghị cắt chuyển `PG-DAT`.
2. TA1 đề nghị cắt chuyển `PG-HT`.
3. Đề nghị `PG-THUE2` (đạt) khi đang đóng băng.
4. Hết đóng băng, TA1 đề nghị `PG-THUE2` rồi tự duyệt.

**Kết quả mong đợi.** Bước 1 `409` ERR-18-067 nêu số mục chưa đạt. Bước 2 `422` ERR-18-066. Bước 3 `409` ERR-18-051. Bước 4 `403` ERR-18-005.

**Thông báo hiển thị.** ERR-18-067: "Chưa cắt chuyển được nhóm {nhóm}: còn {n} mục kiểm tra chưa đạt." ERR-18-066: "Tỷ lệ khớp {tỷ lệ} thấp hơn ngưỡng {ngưỡng}." ERR-18-051: "Đang trong thời gian đóng băng thay đổi {cửa sổ} nên chưa chạy thật được." ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

#### TC-18-128 · Quay lui ở phút thứ 14 không cần duyệt, lưu lượng về hệ cũ trong 15 phút <!--k:quay-lui-phut-14-->

::: dac-ta
**Mục đích.** Chứng minh ĐN-UC-15 và NFR-18-015: quay lui trong `18.migration.rollback-window-minutes` không cần bốn mắt, ghi kiểm toán trễ qua outbox được.

**Loại.** Dương, Biên.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-068 · API-18-175 · BR-18-044, 046 · EVT-18-27 · NFR-18-015.

**Tiền điều kiện, dữ liệu.** T95 (đồng hồ giả) với nhóm `PG-THUE` vừa `CUT_OVER`; WireMock PH-03 xác nhận đổi tuyến.

**Các bước.**

1. Tua 14 phút, TA1 `:transition` `action = ROLLBACK`.
2. Đọc EVT-18-27 và xác nhận của PH-03.

**Kết quả mong đợi.** Bước 1 `200` `ROLLED_BACK`, không cần người duyệt. Bước 2 EVT-18-27 `to = ROLLED_BACK`; PH-03 xác nhận 100 % tuyến về hệ cũ; sổ cắt chuyển ghi lý do và thời điểm.
:::

#### TC-18-129 · Quay lui ở phút thứ 16 bị từ chối <!--k:quay-lui-phut-16-->

::: dac-ta
**Mục đích.** Chứng minh ĐN-UC-15: quá cửa sổ quay lui không quay lui tự động được.

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-068 · API-18-175 · BR-18-044 · ERR-18-068.

**Tiền điều kiện, dữ liệu.** T95; nhóm `PG-THUE` `CUT_OVER` lại.

**Các bước.**

1. Tua 16 phút, TA1 gửi `ROLLBACK`.

**Kết quả mong đợi.** `409` ERR-18-068; trạng thái giữ `CUT_OVER`; màn chỉ dẫn quy trình quay lui thủ công qua đề nghị bốn mắt mới.

**Thông báo hiển thị.** ERR-18-068: "Đã quá {phút} phút kể từ khi cắt chuyển nên không quay lui tự động được."
:::

#### TC-18-170 · Xác nhận mục kiểm tay, người duyệt từ chối đề nghị cắt chuyển <!--k:cat-chuyen-xac-nhan-tu-choi-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-068 bước 1 và thân `action` của API-18-175: mục tay chỉ đạt khi có người xác nhận qua API-18-185, mục tự động không xác nhận tay được, `REJECT` giữ nguyên trạng thái nhóm.

**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-068 · API-18-185, 175, 174 · BR-18-044 · ERR-18-006, 005, 067 · EVT-18-27 · UI-18-23.

**Tiền điều kiện, dữ liệu.** T96; `PG-THUE` mọi mục tự động đạt, hai mục tay `STAKEHOLDER_SIGNOFF`, `ROLLBACK_READY` `PENDING`; U-T96-TA1 đề nghị, U-T96-TA2 duyệt.

**Các bước.**

1. TA1 `POST /parallel-groups/PG-THUE/checklist/STAKEHOLDER_SIGNOFF:confirm` kèm bằng chứng (số công văn).
2. TA1 `:transition` `action = REQUEST` khi `ROLLBACK_READY` còn `PENDING`.
3. TA1 xác nhận `ROLLBACK_READY`, rồi `:transition` `action = REQUEST`, `target = CUT_OVER`.
4. TA1 `:confirm` mục tự động `MATCH_RATE`.
5. TA1 `:transition` `action = APPROVE` trên đề nghị của chính mình.
6. TA2 `:transition` `action = REJECT` kèm lý do.

**Kết quả mong đợi.** Bước 1 `200` mục `PASSED`, sổ cắt chuyển ghi người xác nhận. Bước 2 `409` ERR-18-067. Bước 3 `202` chờ duyệt. Bước 4 `409` ERR-18-006. Bước 5 `403` ERR-18-005. Bước 6 `200`, đề nghị đóng, nhóm giữ `SHADOW_OK`, sổ cắt chuyển ghi người từ chối và lý do, không gửi yêu cầu đổi tuyến cho PH-03.

**Thông báo hiển thị.** ERR-18-006: "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}." ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

### TS-18-39 · Tra nhật ký thao tác và lập báo cáo vận hành định kỳ

**Mục tiêu.** Chứng minh mọi thao tác ghi của PH-18 có bản ghi kiểm toán ở PH-13 trước khi có hiệu lực (trừ hủy, tạm dừng, quay lui khẩn ghi trễ qua outbox), AU tra được nhật ký, báo cáo định kỳ không chứa payload hay dữ liệu cá nhân.

**Phủ.** FR-18-070, 071; API-18-177, 178, 179, 081; BR-18-046, 050; ERR-18-008, 072; EVT-18-28; NFR-18-019.

#### TC-18-130 · AU tra nhật ký thao tác vận hành, đối chiếu đủ 100 % thao tác ghi <!--k:nhat-ky-thao-tac-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-070 và NFR-18-019: mọi thao tác ghi của các ca chương 4 có bản ghi kiểm toán; AU chỉ đọc.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, JOB.

**Truy vết.** FR-18-070 · API-18-177, 016, 063 · BR-18-046 · NFR-18-019 · UI-18-24.

**Tiền điều kiện, dữ liệu.** T90 sau khi chạy hết chương 4; U-T90-AU; nhật ký thao tác nội bộ của PH-18.

**Các bước.**

1. AU `GET /audit-log?tuNgay=...`.
2. Chạy tác vụ đối chiếu hằng ngày nhật ký thao tác với kiểm toán PH-13.
3. AU thử `DELETE /audit-log/{id}`.

**Kết quả mong đợi.** Bước 1 `200` danh sách có người, hành động, đối tượng, lý do, kết quả. Bước 2 tỷ lệ khớp 100 %. Bước 3 `405`.
:::

#### TC-18-131 · PH-13 không ghi được: thao tác thường bị từ chối, hủy và tạm dừng vẫn có hiệu lực, ghi bù <!--k:kiem-toan-truoc-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-046: kiểm toán trước khi có hiệu lực, ngoại lệ có kiểm soát cho thao tác khẩn.

**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-070, 029, 068 · BR-18-046 · ERR-18-008.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-13 trả `503`; lượt `RJ-T94` đang `RUNNING`.

**Các bước.**

1. TO bỏ qua một mục DLQ.
2. TO `:pause` lượt `RJ-T94`, rồi `:cancel`.
3. Khôi phục PH-13.

**Kết quả mong đợi.** Bước 1 `503` ERR-18-008. Bước 2 `200` cả hai, bản ghi kiểm toán nằm ở outbox. Bước 3 outbox gửi bù đủ, thứ tự đúng.

**Thông báo hiển thị.** ERR-18-008: "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
:::

#### TC-18-132 · Dựng báo cáo tháng cho PH-16, kỳ chưa kết thúc bị từ chối, sự kiện không có dữ liệu cá nhân <!--k:bao-cao-dinh-ky-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-071 và BR-18-050.

**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API, KT.

**Truy vết.** FR-18-071 · API-18-178, 179, 081 · BR-18-050 · ERR-18-072 · EVT-18-28 · UI-18-24.

**Tiền điều kiện, dữ liệu.** T90 với dữ liệu tháng 10/2026; U-PA1; ngày hiện tại 27/11/2026.

**Các bước.**

1. `POST /reports:generate` kỳ `2026-10`.
2. Đọc `t90.ops.report.published.v1`.
3. `POST /reports:generate` kỳ `2026-11`.
4. `GET /reports`.

**Kết quả mong đợi.** Bước 1 `202` rồi báo cáo có số mục DLQ, tỷ lệ phát lại, sao lưu, di trú, sự cố. Bước 2 EVT-18-28 chỉ có chỉ số tổng hợp, không có payload hay dữ liệu cá nhân. Bước 3 `422` ERR-18-072. Bước 4 có báo cáo 2026-10.

**Thông báo hiển thị.** ERR-18-072: "Kỳ báo cáo {kỳ} không hợp lệ hoặc chưa kết thúc."
:::

### TS-18-40 · Theo dõi sức khỏe và chạy ở chế độ suy giảm

**Mục tiêu.** Chứng minh PH-18 báo sức khỏe từng mô-đun, chế độ chỉ đọc chặn mọi API ghi với ERR-18-071 nhưng vẫn đọc được, và PH-18 vắng không chặn đường chính của phân hệ khác.

**Phủ.** FR-18-072, 002; API-18-180, 186, 187; BR-18-007, 011; ERR-18-071; EVT-18-29; NFR-18-016, 018; LGC-NFR-001, 006.

#### TC-18-133 · Sức khỏe mô-đun, độ trễ tiêu thụ và EVT-18-29 khi mô-đun đổi trạng thái <!--k:suc-khoe-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-072: `GET /health` trả trạng thái các mô-đun `param`, `dlq`, `notify`, `task`, `incident`, `backup`, `migration`, độ trễ tiêu thụ; đổi trạng thái phát EVT-18-29.

**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-18-072 · API-18-180 · EVT-18-29 · UI-18-24.

**Tiền điều kiện, dữ liệu.** T90; U-PO1; dừng consumer DLQ 2 phút để tạo độ trễ.

**Các bước.**

1. `GET /health`.
2. Dừng consumer DLQ, chờ 2 phút, `GET /health`.
3. Mở UI-18-24.

**Kết quả mong đợi.** Bước 1 mọi mô-đun `UP`. Bước 2 `dlq` `DEGRADED`, `consumerLagSeconds` > 0, EVT-18-29 `from = UP`, `to = DEGRADED`. Bước 3 thẻ sức khỏe hiện trạng thái và độ trễ.
:::

#### TC-18-134 · Chế độ chỉ đọc chặn mọi API ghi, vẫn đọc được và có dải cảnh báo <!--k:chi-doc-->

::: dac-ta
**Mục đích.** Chứng minh ERR-18-071 áp dụng cho mọi API ghi (FR-18-072) và việc bật, tắt chế độ đi qua API-18-187 (ca TC-18-171).

**Loại.** Âm, Biên.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-072, 007, 003 · API-18-006, 049, 091, 180, 187 · BR-18-007 · ERR-18-071 · EVT-18-29 · LGC-NFR-006 · UI-18-08, 24.

**Tiền điều kiện, dữ liệu.** T90; U-PA1 bật chế độ chỉ đọc qua API-18-187.

**Các bước.**

1. TA1 `PUT /params/04.retry.max-attempts`.
2. TO `:triage` một mục DLQ.
3. TA1 `GET /params`, TO `GET /dlq/messages`.
4. Mở `/van-hanh`.

**Kết quả mong đợi.** Bước 1, 2 `503` ERR-18-071. Bước 3 `200`. Bước 4 dải cảnh báo chỉ đọc trên mọi màn `/van-hanh`; EVT-18-29 `readOnly = true`. Gửi thông báo của phân hệ khác qua outbox vẫn nhận (không chặn đường chính).

**Thông báo hiển thị.** ERR-18-071: "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được."
:::

#### TC-18-135 · Tắt dh-platform 30 phút: phân hệ đọc tham số từ đệm, bản tin lỗi dồn ở Kafka và được nhận đủ <!--k:ph18-vang-->

::: dac-ta
**Mục đích.** Chứng minh AC-18-02 và BR-18-007, 011: PH-18 vắng không chặn đường chính; khi trở lại tiêu thụ đủ, không mất, không trùng.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-18-072, 002, 013 · BR-18-007, 011 · NFR-18-016, 018 · LGC-NFR-001.

**Tiền điều kiện, dữ liệu.** STAGING (T94); tải data plane giả lập 200 giao dịch mỗi giây qua PH-04; 5.000 bản tin lỗi được đẩy trong lúc PH-18 tắt.

**Các bước.**

1. Tắt `dh-platform` 30 phút trong khi chạy tải.
2. Bật lại, chờ tiêu thụ hết.

**Kết quả mong đợi.** Trong lúc tắt: 0 lỗi data plane do PH-18, p95 độ trễ giao dịch tăng không quá 5 %, PH-04 đọc tham số từ đệm. Sau khi bật: 5.000 mục, 0 mất, 0 trùng; độ trễ tiêu thụ về 0.
:::

#### TC-18-171 · Bật, tắt chế độ chỉ đọc qua API riêng và xem sự kiện inbox lỗi <!--k:chi-doc-bat-tat-->

::: dac-ta
**Mục đích.** Chứng minh FR-18-072 qua API-18-187 và API-18-186: chỉ PA bật, tắt được; API-18-187 không bị chặn khi đang chỉ đọc; khóa `18.degraded.read-only` không đổi được qua API-18-006; danh sách inbox `FAILED` chỉ có siêu dữ liệu.

**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-18-072 · API-18-187, 186, 006, 180 · BR-18-007 · ERR-18-071, 003, 007 · ERR-00-403 · EVT-18-29 · UI-18-24.

**Tiền điều kiện, dữ liệu.** T90; U-PA1 có `PERM-18-admin`; U-T90-TA1 có `PERM-18-config`; inbox mô-đun `notify` có 3 sự kiện `FAILED`.

**Các bước.**

1. TA1 `POST /degraded-mode` `readOnly = true`.
2. PA1 `POST /degraded-mode` `readOnly = true` kèm lý do "Bảo trì CSDL theo lịch".
3. TA1 `PUT /params/18.degraded.read-only` giá trị `false`.
4. PA1 `POST /degraded-mode` `readOnly = false` kèm lý do khi đang chỉ đọc.
5. PA1 `GET /inbox-failures?module=notify`.
6. PA1 `POST /degraded-mode` với lý do 3 ký tự.

**Kết quả mong đợi.** Bước 1 `403` ERR-00-403. Bước 2 `200`, `readOnly = true`, EVT-18-29 phát, kiểm toán có. Bước 3 `503` ERR-18-071 (chế độ đang bật); khi chế độ tắt, cùng lời gọi trả `400` ERR-18-003. Bước 4 `200`, chế độ tắt, EVT-18-29 `readOnly = false`, tiêu thụ DLQ đọc tiếp từ offset đã commit. Bước 5 `200` 3 dòng có mô-đun, người tiêu thụ, lỗi cuối, số lần thử; không có nội dung sự kiện. Bước 6 `422` ERR-18-007.

**Thông báo hiển thị.** ERR-18-071: "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được." ERR-18-003: "Dữ liệu không hợp lệ: {chi tiết}." ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Các kịch bản TS-18-41…46 kiểm các tính chất xuyên suốt: cô lập tenant, phân quyền và bốn mắt, đóng an toàn và chịu lỗi khi phân hệ phụ thuộc vắng, hiệu năng theo NFR-18, khả năng truy cập và tương đương hệ cũ. Ca hiệu năng và chịu lỗi chạy ở PERF hoặc STAGING theo mục 1.3; ngưỡng lấy nguyên văn FRS mục 8.1.

### TS-18-41 · Cô lập tenant ở API, CSDL, Kafka và tác vụ nặng

**Mục tiêu.** Chứng minh NFR-18-017 và BR-18-047: không bản ghi nào của tenant khác xuất hiện ở API, sự kiện, CSDL; chế độ nền tảng liên tenant cần lý do và kiểm toán; công cụ khôi phục, xuất, chuyển sáp nhập không chạm dòng của tenant khác.

**Phủ.** BR-18-047; NFR-18-017; ERR-18-001, 007; ERR-00-403; FR-18-019, 021, 052, 055, 057.

#### TC-18-136 · Người dùng T91 đọc đối tượng T90 ở mọi nhóm API nhận 404 giống hệt không tồn tại <!--k:cheo-tenant-api-->

::: dac-ta
**Mục đích.** Chứng minh chống dò tìm: mọi API đọc theo mã trả `404` ERR-18-001 với thân giống hệt đối tượng không tồn tại, danh sách không trả dòng của tenant khác.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-18-047 · NFR-18-017 · FR-18-005, 021, 044, 048, 054, 061 · API-18-005, 045, 112, 125, 140, 166, 041, 123 · ERR-18-001.

**Tiền điều kiện, dữ liệu.** T90, T91 cùng mã đối tượng (`DLQ-A-02`, `INC-T90-02`, `RST-T90-01`, `RUN-DRY-02`, khóa `04.retry.max-attempts`); U-T91-TA có quyền mạnh nhất tenant.

**Các bước.**

1. U-T91-TA gọi chi tiết từng đối tượng của T90 bằng mã của T90.
2. So thân lỗi với đối tượng không tồn tại.
3. U-T91-TA gọi danh sách DLQ, sự cố, khôi phục, lần chạy di trú có bộ lọc trùng giá trị của T90.

**Kết quả mong đợi.** Bước 1 mọi lời gọi `404` ERR-18-001. Bước 2 thân giống hệt trừ `traceId`. Bước 3 0 dòng của T90; giá trị `04.retry.max-attempts` của T91 không bị giá trị T90 ảnh hưởng.

**Thông báo hiển thị.** ERR-18-001: "Không tìm thấy {đối tượng} {mã}."
:::

#### TC-18-137 · Bộ kiểm RLS và quyền của CSDL ph18_ops chạy đạt <!--k:cheo-tenant-db-->

::: dac-ta
**Mục đích.** Chứng minh cô lập ở mức CSDL bằng bộ kiểm đã có của tập CSDL: RLS mọi bảng, dòng `COMMON` chỉ phiên `COMMON` ghi, vai `ph18_readonly` không đọc payload, vai `ph18_worker` chỉ bảng di trú và khôi phục.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** BR-18-047, 012 · NFR-18-017 · FR-18-019, 055, 057.

**Tiền điều kiện, dữ liệu.** `postgres:16` rỗng; `03-thiet-ke/csdl/ph18/ddl/ph18_ops.sql`; `03-thiet-ke/csdl/ph18/test/ph18_isolation_test.sql` (tenant T90, T91).

**Các bước.**

1. Chạy `psql -v ON_ERROR_STOP=1 -f ph18_ops.sql`.
2. Chạy `psql -v ON_ERROR_STOP=1 -f ph18_isolation_test.sql`.

**Kết quả mong đợi.** Mọi khối ghi `PASS`, tệp chạy hết không `RAISE`; các SQLSTATE mong đợi (23514, 23505, 23503, 42501, 55000) khớp. Bộ này chạy trong CI ở mỗi thay đổi DDL.
:::

#### TC-18-138 · Danh tính T91 không đọc, ghi được topic ops của T90; sự kiện không mang payload <!--k:cheo-tenant-kafka-->

::: dac-ta
**Mục đích.** Chứng minh ACL Kafka theo tiền tố tenant và quy tắc sự kiện chỉ mang mã, trạng thái, số đếm.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** KT.

**Truy vết.** BR-18-047, 050 · NFR-18-017 · EVT-18-01, 05, 07, 09, 13, 22, 28.

**Tiền điều kiện, dữ liệu.** T90, T91; client OAUTHBEARER của S-T91-PH04; consumer kiểm trên mọi topic `t90.ops.*.v1` trong lúc chạy chương 4.

**Các bước.**

1. S-T91-PH04 đọc `t90.ops.dlq.state-changed.v1`.
2. S-T91-PH04 ghi `t90.ops.dlq.v1`.
3. Quét mọi bản tin `t90.ops.*.v1` đã phát.

**Kết quả mong đợi.** Bước 1, 2 bị từ chối `TOPIC_AUTHORIZATION_FAILED`. Bước 3 không bản tin nào chứa payload DLQ, giá trị khóa ★, địa chỉ thư, số điện thoại hay chuỗi mồi `DH-CANARY-18`.
:::

#### TC-18-139 · PA, PO xem DLQ liên tenant ở chế độ nền tảng cần lý do và kiểm toán <!--k:che-do-nen-tang-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-047 và SEC-85: chế độ nền tảng không mặc định, mỗi lần bật có lý do, thời hạn và kiểm toán; PO không có quyền ghi.

**Loại.** Bảo mật, Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-18-047 · FR-18-019, 021 · API-18-041, 045, 049 · ERR-18-007 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** U-PO1 (`PERM-18-read`, `PERM-18-dlq`), U-PA1; T90, T91 có mục DLQ.

**Các bước.**

1. U-PO1 `GET /dlq/messages` không có tiêu đề chế độ nền tảng.
2. U-PO1 bật chế độ nền tảng với lý do 4 ký tự.
3. U-PO1 bật với lý do hợp lệ, liệt kê mục của T90 và T91.
4. U-PO1 xem payload của mục T91.

**Kết quả mong đợi.** Bước 1 `200` 0 dòng (PO không thuộc tenant). Bước 2 `422` ERR-18-007. Bước 3 `200` có cột tenant, KT: có (platform-mode) với lý do. Bước 4 `403` ERR-00-403 vì PO chỉ có quyền xem payload hạn chế theo ma trận FRS mục 3.2.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

#### TC-18-140 · Khôi phục, xuất và chuyển sáp nhập chạy với SET LOCAL app.tenant_id, không chạm tenant khác <!--k:tac-vu-nang-rls-->

::: dac-ta
**Mục đích.** Chứng minh công cụ trong `dh-batch` không có đường vòng RLS: thử ghi dòng của tenant khác trong phiên của Job bị chặn.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** JOB, DB.

**Truy vết.** BR-18-047, 038, 045 · NFR-18-017 · FR-18-055, 056, 057.

**Tiền điều kiện, dữ liệu.** STAGING; Job `dh-tenant-restore`, `dh-tenant-export` cho T90 với vai `ph18_worker`; dòng mồi của T91 ở cùng ô.

**Các bước.**

1. Trong phiên Job của T90, chạy câu cập nhật dòng mồi của T91.
2. Chạy xuất T90 và kiểm manifest.
3. Chạy chuyển sáp nhập T92 → T90 và kiểm T91.

**Kết quả mong đợi.** Bước 1 0 dòng bị đổi hoặc SQLSTATE 42501. Bước 2 manifest không có tệp hay dòng của tenant khác. Bước 3 T91 không đổi; mọi dòng mới ở T90 có `origin_tenant_id`.
:::

### TS-18-42 · Phân quyền theo ma trận PERM-18 và bốn mắt xuyên suốt

**Mục tiêu.** Chứng minh ma trận quyền ở FRS mục 3.2 được thực thi ở API, scope máy không dùng được cho người, mọi đối tượng bốn mắt từ chối người duyệt trùng người đề nghị, mọi thao tác ghi có `If-Match` hoặc `Idempotency-Key` theo BR-18-049.

**Phủ.** BR-18-004, 018, 021, 038, 041, 044, 049; ERR-18-005, 009, 004; ERR-00-401, 403, 428.

#### TC-18-141 · Mỗi vai trò chỉ làm được thao tác theo ma trận PERM-18 <!--k:ma-tran-quyen-->

::: dac-ta
**Mục đích.** Chứng minh 11 quyền PERM-18 với 9 vai trò: mỗi ô "—" trả `403`, mỗi ô "●" thực hiện được.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-18-019, 022, 023, 027, 035, 048, 054, 059, 069 · ERR-00-403.

**Tiền điều kiện, dữ liệu.** T90; tài khoản U-T90-{vai} cho PA, PO, TA, TO, SO, IE, DS, AU, VW; bảng thao tác mẫu một API cho mỗi quyền (`PERM-18-read`, `-dlq`, `-dlq-payload`, `-approve`, `-config`, `-template`, `-incident`, `-backup`, `-calendar`, `-migration`, `-admin`).

**Các bước.**

1. Chạy 99 lời gọi (11 quyền × 9 vai trò) theo bảng.
2. VW mở UI-18-01 và UI-18-06.

**Kết quả mong đợi.** Mọi kết quả khớp ma trận: ô "—" `403` ERR-00-403; ô "○" chỉ đạt trong phạm vi hạn chế ghi ở FRS (VW chỉ thống kê, PA ở chế độ nền tảng). Bước 2 VW thấy thống kê, không thấy danh sách mục.
:::

#### TC-18-142 · Thiếu token, token hết hạn, token người gọi API nội bộ, scope máy gọi API người dùng <!--k:xac-thuc-scope-->

::: dac-ta
**Mục đích.** Chứng minh xác thực và tách đường người với đường máy.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-18-016 · API-18-028, 035, 041, 091 · ERR-00-401, 403.

**Tiền điều kiện, dữ liệu.** T90; token hết hạn của U-T90-TO; S-PH19.

**Các bước.**

1. Gọi `GET /dlq/messages` không có token, rồi với token hết hạn.
2. U-T90-TA1 gọi `POST /ops/internal/v1/notifications` qua APISIX.
3. S-PH19 gọi `GET /dlq/messages`.

**Kết quả mong đợi.** Bước 1 `401` ERR-00-401. Bước 2 `403` hoặc bị APISIX chặn tuyến nội bộ. Bước 3 `403` ERR-00-403.
:::

#### TC-18-143 · Người đề nghị không duyệt được ở cả tám loại đối tượng bốn mắt <!--k:bon-mat-xuyen-suot-->

::: dac-ta
**Mục đích.** Chứng minh LP-18-01 nhất quán: tham số ★, gói tham số, bản sửa payload, lượt phát lại lớn, phiên bản mẫu, khôi phục tenant, chạy di trú thật, cắt chuyển đều trả ERR-18-005 và việc duyệt có `excludeUsers`.

**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** BR-18-004, 018, 021, 038, 041, 044 · FR-18-004, 008, 024, 028, 035, 055, 062, 068 · API-18-010, 019, 055, 070, 088, 142, 167, 175 · ERR-18-005 · UI-18-15.

**Tiền điều kiện, dữ liệu.** Tám đối tượng `PENDING_APPROVAL` do U-T90-TA1 tạo (TA1 có `PERM-18-approve`); dữ liệu theo các ca TS-18-03, 05, 14, 17, 20, 31, 36, 38.

**Các bước.**

1. TA1 gọi API duyệt của từng đối tượng.
2. TA1 mở `/viec-cua-toi`.
3. TA2 mở `/viec-cua-toi`.

**Kết quả mong đợi.** Bước 1 tám lần `403` ERR-18-005, không đối tượng nào đổi trạng thái. Bước 2 không có việc duyệt nào. Bước 3 có đủ tám việc; nút "Duyệt" trên màn đối tượng bị khóa với TA1.

**Thông báo hiển thị.** ERR-18-005: "Bạn là người tạo {đối tượng} này nên không được duyệt."
:::

#### TC-18-144 · Mọi PUT, PATCH, chuyển trạng thái cần If-Match; POST dùng lại khóa với thân khác bị từ chối <!--k:if-match-idempotency-->

::: dac-ta
**Mục đích.** Chứng minh BR-18-049 bằng mẫu đại diện của mỗi nhóm API ghi.

**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, CT.

**Truy vết.** BR-18-049 · API-18-006, 022, 033, 059, 096, 101, 114, 120, 126, 162, 065, 083, 124, 138 · ERR-18-004, 009 · ERR-00-428.

**Tiền điều kiện, dữ liệu.** T90; danh sách thao tác ghi sinh từ `openapi-ops.yaml` (tham số `IfMatch`, `IdempotencyKey`).

**Các bước.**

1. Gọi mỗi `PUT`, `PATCH`, chuyển trạng thái không có `If-Match`, rồi với `ETag` cũ.
2. Gọi mỗi `POST` tạo hai lần cùng `Idempotency-Key`, lần hai thân khác.
3. Chạy Spectral kiểm mọi thao tác ghi khai đủ tiêu đề.

**Kết quả mong đợi.** Bước 1 `428` ERR-00-428 rồi `412` ERR-18-004. Bước 2 lần hai `409` ERR-18-009. Bước 3 không có cảnh báo thiếu tiêu đề.

**Thông báo hiển thị.** ERR-18-004: "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu." ERR-18-009: "Yêu cầu trùng khóa với một yêu cầu khác nội dung."
:::

### TS-18-43 · Đóng an toàn, chịu lỗi và phụ thuộc mềm

**Mục tiêu.** Chứng minh PH-18 suy giảm có kiểm soát khi PH-13, PH-04, PH-09, PH-20 hoặc hạ tầng (CSDL, Garage) vắng: phần đọc vẫn dùng được, phần ghi có kiểm toán thì từ chối, phân loại dữ liệu chưa rõ thì đóng an toàn, tiếp nhận DLQ không mất bản tin.

**Phủ.** NFR-18-002, 016; BR-18-007, 011, 027, 046; ERR-18-008, 106, 108, 109.

#### TC-18-145 · PH-13 vắng: đọc và tiếp nhận vẫn chạy, chẩn đoán trả một phần, thao tác ghi cần kiểm toán bị từ chối <!--k:ph13-vang-->

::: dac-ta
**Mục đích.** Chứng minh LP-18-04 với PH-13: không có kiểm toán thì không có hiệu lực, nhưng màn đọc và tiếp nhận không bị chặn.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-18-013, 019, 021, 070 · BR-18-046, 011 · ERR-18-008, 106.

**Tiền điều kiện, dữ liệu.** T94; ngắt PH-13 (kiểm toán và API-13-069) 15 phút; đẩy 500 bản tin lỗi trong lúc ngắt.

**Các bước.**

1. TO mở danh sách và chi tiết mục.
2. TO phân loại một mục.
3. Kiểm số mục mới.

**Kết quả mong đợi.** Bước 1 `200`, khung chẩn đoán ghi ERR-18-106. Bước 2 `503` ERR-18-008. Bước 3 500 mục `NEW`, không mất.

**Thông báo hiển thị.** ERR-18-106 (hiện ở màn vận hành, không trả qua HTTP): "Chưa lấy được ngữ cảnh chẩn đoán." ERR-18-008: "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
:::

#### TC-18-146 · PH-04 runtime vắng khi phát lại: yêu cầu nằm ở topic, quá hạn rồi nhận kết quả một lần khi PH-04 trở lại <!--k:ph04-vang-phat-lai-->

::: dac-ta
**Mục đích.** Chứng minh phát lại không gọi thẳng hệ đích khi nguồn vắng và kết quả muộn được nhận lũy đẳng.

**Loại.** Chịu lỗi, Lũy đẳng.

**Ưu tiên.** P1.

**Tự động.** Chaos, IT.

**Truy vết.** FR-18-027, 030 · BR-18-019, 020 · ERR-18-108, 109 · EVT-18-09.

**Tiền điều kiện, dữ liệu.** T94; dừng consumer `dh-runtime` của `t94.ops.replay.requested.v1` 40 phút; lượt 20 mục; một nguồn `HTTP_PORT` khác cũng ngắt.

**Các bước.**

1. Chạy lượt khi PH-04 dừng.
2. Chờ quá `18.dlq.replay.result-timeout-minutes`.
3. Bật lại PH-04.

**Kết quả mong đợi.** Bước 1 20 EVT-18-09 nằm ở topic; nguồn `HTTP_PORT` ghi ERR-18-108. Bước 2 mục `REPLAY_FAILED` ghi ERR-18-109. Bước 3 PH-04 xử lý mỗi khóa đúng một lần, callback đưa mục về `RESOLVED`; hệ đích nhận 0 lời gọi từ PH-18.

**Thông báo hiển thị.** ERR-18-108 (hiện ở màn vận hành, không trả qua HTTP): "Nguồn không phản hồi; mục sẽ được thử lại." ERR-18-109 (hiện ở màn vận hành, không trả qua HTTP): "Chưa nhận kết quả phát lại sau {n} phút."
:::

#### TC-18-147 · PH-09 vắng: biến mẫu và trường payload chưa rõ mức được coi là cấm hoặc cần bốn mắt <!--k:ph09-vang-dong-an-toan-->

::: dac-ta
**Mục đích.** Chứng minh đóng an toàn khi không phân loại được dữ liệu (BR-18-027, Q18-45).

**Loại.** Chịu lỗi, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-18-035, 024 · BR-18-027, 018 · ERR-18-039.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-09 trả `503`.

**Các bước.**

1. TA1 gửi duyệt phiên bản mẫu có biến mới.
2. IE tạo bản sửa payload chạm trường mới.

**Kết quả mong đợi.** Bước 1 `422` ERR-18-039 (biến chưa xác định mức). Bước 2 bản sửa `PENDING_APPROVAL` thay vì `APPROVED` ngay.

**Thông báo hiển thị.** ERR-18-039: "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."
:::

#### TC-18-148 · Registry PH-20 vắng: tác vụ nền dùng danh sách tenant gần nhất, không dừng <!--k:ph20-vang-->

::: dac-ta
**Mục đích.** Chứng minh tác vụ dọn, nhắc, thu thập sao lưu không dừng toàn bộ khi `/internal/tenant/v1/tenants?status=ACTIVE` không trả lời.

**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-18-033, 044, 052, 072 · BR-18-007.

**Tiền điều kiện, dữ liệu.** T94; WireMock PH-20 ngắt 2 giờ; danh sách tenant gần nhất có 3 tenant.

**Các bước.**

1. Chạy tác vụ dọn và nhắc.
2. Xem `GET /health`.

**Kết quả mong đợi.** Tác vụ chạy cho 3 tenant đã biết; `health` báo phụ thuộc `PH-20` `DOWN`, mô-đun `task` `DEGRADED`; không lỗi lan sang API người dùng.
:::

#### TC-18-149 · Giết bản sao, ngắt CSDL 60 giây và Garage 60 giây khi nạp 100.000 bản tin lỗi <!--k:khong-mat-ban-tin-->

::: dac-ta
**Mục đích.** Chứng minh NFR-18-002: 0 mục mất, 0 mục trùng sau khử trùng.

**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** FR-18-013, 016 · BR-18-011, 015 · NFR-18-002, 016.

**Tiền điều kiện, dữ liệu.** PERF (T97); 100.000 bản tin `DLQ-SET-PERF` có `dh-message-id` duy nhất, 5 % lớn hơn 256 KB; Chaos Mesh.

**Các bước.**

1. Bắt đầu nạp; ở phút 2 giết một bản sao `dh-platform`; ở phút 4 ngắt CSDL 60 giây; ở phút 7 ngắt Garage 60 giây.
2. Chờ tiêu thụ hết, đếm theo `dh-message-id`.

**Kết quả mong đợi.** Số mục bằng 100.000, không khóa trùng; mọi payload lớn có đối tượng Garage khớp SHA-256; độ trễ tiêu thụ trở về 0 trong 10 phút sau sự cố cuối.
:::

### TS-18-44 · Hiệu năng, quy mô và sẵn sàng

**Mục tiêu.** Chứng minh các chỉ tiêu NFR-18 ở hồ sơ tỉnh vừa (GĐ-07, tỉnh T01, 200 HTTT) trên môi trường PERF; ca chạy bằng k6 tại APISIX và đồng hồ Job.

**Phủ.** NFR-18-001, 003…011, 013, 016, 022.

#### TC-18-150 · Tiếp nhận DLQ 200 bản tin mỗi giây mỗi phân vùng, trễ hiện trên màn p95 ≤ 5 giây <!--k:perf-tiep-nhan-->

::: dac-ta
**Mục đích.** Đo NFR-18-001.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-18-001 · FR-18-013, 016.

**Tiền điều kiện, dữ liệu.** PERF (T97); 6 phân vùng; payload trung bình 8 KB, 5 % lớn hơn 256 KB; `dh-platform` 3 bản sao.

**Các bước.**

1. Nạp 1.200 bản tin mỗi giây trong 15 phút.
2. Đo từ thời điểm ghi topic tới khi `GET /dlq/messages` trả mục.

**Kết quả mong đợi.** Thông lượng ≥ 200 bản tin mỗi giây mỗi phân vùng; p95 trễ ≤ 5 giây; không tăng độ trễ tiêu thụ kéo dài.
:::

#### TC-18-151 · Danh sách DLQ 1 triệu mục, 200 người dùng đồng thời <!--k:perf-danh-sach-->

::: dac-ta
**Mục đích.** Đo NFR-18-003.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-18-003 · FR-18-019 · API-18-041.

**Tiền điều kiện, dữ liệu.** PERF (T97) 1 triệu mục; 200 người dùng ảo với bộ lọc ngẫu nhiên.

**Các bước.**

1. Chạy 30 phút trang 50 dòng có `facets`.

**Kết quả mong đợi.** p95 ≤ 1,5 giây, p99 ≤ 3 giây, lỗi < 0,1 %.
:::

#### TC-18-152 · Đọc tham số lô 500 yêu cầu mỗi giây và lan truyền đổi tham số <!--k:perf-tham-so-->

::: dac-ta
**Mục đích.** Đo NFR-18-004 và NFR-18-005.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-18-004, 005 · FR-18-002, 006 · API-18-028.

**Tiền điều kiện, dữ liệu.** PERF; 100 khóa mỗi yêu cầu; 30 DU giả lập dùng `dh-ops-client`.

**Các bước.**

1. Chạy 500 yêu cầu mỗi giây trong 10 phút, 70 % kèm `If-None-Match`.
2. Đổi 20 khóa trong lúc chạy, đo phiên bản đệm của mọi bản sao.

**Kết quả mong đợi.** Đọc p95 ≤ 50 ms; `304` p95 ≤ 20 ms; lan truyền p95 ≤ 60 giây.
:::

#### TC-18-153 · Phát lại 10.000 mục ở tốc độ mặc định <!--k:perf-phat-lai-->

::: dac-ta
**Mục đích.** Đo NFR-18-006.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6, JOB.

**Truy vết.** NFR-18-006 · FR-18-028, 029.

**Tiền điều kiện, dữ liệu.** PERF; lượt 10.000 mục đã duyệt; cổng nguồn giả lập phản hồi 50 ms; tốc độ 10 mục mỗi giây (giả định áp trần nguồn 20 mục mỗi giây để lượt chạy đủ nhanh).

**Các bước.**

1. Chạy lượt, đo thời gian và tốc độ thực.

**Kết quả mong đợi.** Thời gian ≤ 20 phút với tốc độ đặt cho lượt; sai lệch tốc độ ≤ 10 %.
:::

#### TC-18-154 · Thông báo 10.000 mỗi giờ, thư đồng bộ và URGENT khi hàng đợi tồn <!--k:perf-thong-bao-->

::: dac-ta
**Mục đích.** Đo NFR-18-007 và NFR-18-008.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** k6.

**Truy vết.** NFR-18-007, 008 · FR-18-036 · API-18-091, 092.

**Tiền điều kiện, dữ liệu.** PERF (T99); MOCK-SMTP, MOCK-SMS; hàng đợi thường tồn 5.000 thông báo.

**Các bước.**

1. Gửi 10.000 thông báo trong một giờ.
2. Gửi 200 thư đồng bộ.
3. Gửi 100 thông báo `URGENT` khi hàng tồn.

**Kết quả mong đợi.** Bất đồng bộ p95 ≤ 60 giây; đồng bộ p95 ≤ 3 giây; `URGENT` p95 ≤ 30 giây.
:::

#### TC-18-155 · Việc của tôi 50 việc mở mỗi người, việc hiện trong 10 giây <!--k:perf-viec-->

::: dac-ta
**Mục đích.** Đo NFR-18-009.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** NFR-18-009 · FR-18-043, 044 · API-18-109, 111.

**Tiền điều kiện, dữ liệu.** PERF; 2.000 người dùng, mỗi người 50 việc mở.

**Các bước.**

1. 200 người dùng ảo gọi `GET /me/tasks` trong 15 phút.
2. Phân hệ giả lập tạo 1.000 việc, đo tới khi hiện.

**Kết quả mong đợi.** Danh sách p95 ≤ 800 ms; việc hiện ≤ 10 giây.
:::

#### TC-18-156 · Khôi phục tenant 200 GB trong 4 giờ <!--k:perf-khoi-phuc-->

::: dac-ta
**Mục đích.** Đo NFR-18-010 cùng AC-18-10 ở diễn tập.

**Loại.** Hiệu năng.

**Ưu tiên.** P1.

**Tự động.** JOB.

**Truy vết.** NFR-18-010, 017 · FR-18-055.

**Tiền điều kiện, dữ liệu.** PERF (T98) hồ sơ `QM-VUA` 200 GB theo D03-09 §8.5.

**Các bước.**

1. Duyệt yêu cầu khôi phục, đo từ lúc duyệt tới `SUCCEEDED` (Q18-46).

**Kết quả mong đợi.** Tổng thời gian ≤ 4 giờ, thời gian từng bước ghi ở `tenant_restore_step`; tenant khác cùng ô không đổi.
:::

#### TC-18-157 · Xuất tenant 200 GB và chuyển sáp nhập 50 GB một phân hệ <!--k:perf-xuat-sap-nhap-->

::: dac-ta
**Mục đích.** Đo NFR-18-011 và NFR-18-022.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** NFR-18-011, 022 · FR-18-056, 057.

**Tiền điều kiện, dữ liệu.** PERF (T98) `QM-VUA`.

**Các bước.**

1. Xuất 200 GB.
2. Chuyển sáp nhập 50 GB của PH-04 sang tenant `QM-VUA` thứ hai.

**Kết quả mong đợi.** Xuất ≤ 2 giờ, tổng kiểm tra 100 % tệp; chuyển ≤ 2 giờ, 0 bản ghi mất `origin_tenant_id`.
:::

#### TC-18-158 · Thông lượng di trú 300 bản ghi mỗi giây qua API nhập <!--k:perf-di-tru-->

::: dac-ta
**Mục đích.** Đo NFR-18-013.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** JOB.

**Truy vết.** NFR-18-013 · FR-18-062.

**Tiền điều kiện, dữ liệu.** PERF (T99); danh mục Aita giả lập 500.000 bản ghi; lô 500; API nhập PH-07 giả lập phản hồi 80 ms.

**Các bước.**

1. Chạy thật đã duyệt.

**Kết quả mong đợi.** Thông lượng trung bình ≥ 300 bản ghi mỗi giây; không lỗi ERR-18-069.

**Thông báo hiển thị.** ERR-18-069: "Phân hệ {ph} không nhận dữ liệu. Lần chạy tạm dừng và tự thử lại sau {phút} phút."
:::

#### TC-18-159 · Sẵn sàng 99,5 % và giữ bản tin khi PH-18 gián đoạn tới 7 ngày <!--k:perf-san-sang-->

::: dac-ta
**Mục đích.** Đo NFR-18-016 bằng giám sát tháng ở STAGING và kiểm cấu hình giữ topic.

**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** Thủ công, CI.

**Truy vết.** NFR-18-016 · FR-18-072.

**Tiền điều kiện, dữ liệu.** STAGING; Prometheus 30 ngày; cấu hình topic `{tenant}.ops.dlq.v1`.

**Các bước.**

1. Tính tỷ lệ sẵn sàng của API người dùng trong 30 ngày.
2. Kiểm `retention.ms` của topic DLQ.

**Kết quả mong đợi.** Tỷ lệ ≥ 99,5 %; thời hạn giữ topic ≥ 14 ngày.
:::

### TS-18-45 · Khả năng truy cập của các màn vận hành

**Mục tiêu.** Chứng minh 24 màn PH-18 đạt WCAG 2.2 AA (NFR-18-020): dùng được hoàn toàn bằng bàn phím, trình đọc màn hình đọc đúng bảng, trạng thái, hộp thoại duyệt và tiến độ.

**Phủ.** NFR-18-020; UI-18-01…24.

#### TC-18-160 · Danh sách, chi tiết, sửa payload, lượt phát lại dùng bằng bàn phím và trình đọc màn hình <!--k:a11y-dlq-->

::: dac-ta
**Mục đích.** Chứng minh màn dùng hằng ngày đạt WCAG 2.2 AA.

**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E, Thủ công.

**Truy vết.** NFR-18-020 · UI-18-01, 02, 03, 04, 05.

**Tiền điều kiện, dữ liệu.** STAGING; NVDA và VoiceOver; axe-core 4.x; `DLQ-SET-A`.

**Các bước.**

1. Dùng Tab, Shift+Tab, Space chọn nhiều mục ở UI-18-01, phát lại loạt.
2. Mở UI-18-03, đọc trạng thái và khác biệt ở UI-18-04 bằng trình đọc.
3. Theo dõi tiến độ lượt ở UI-18-05.
4. Chạy axe trên năm màn ở ba điểm ngắt.

**Kết quả mong đợi.** Thứ tự tiêu điểm hợp lý, có viền tiêu điểm; trạng thái có chữ không chỉ dựa màu; khác biệt đọc được "đã thêm", "đã xóa"; tiến độ thông báo qua `aria-live="polite"`; axe 0 lỗi mức nghiêm trọng.
:::

#### TC-18-161 · Hộp thoại duyệt bốn mắt, lý do bắt buộc và Việc của tôi <!--k:a11y-duyet-->

::: dac-ta
**Mục đích.** Chứng minh hộp thoại xác nhận giữ tiêu điểm, thông báo lỗi gắn với ô nhập.

**Loại.** Truy cập.

**Ưu tiên.** P1.

**Tự động.** E2E, Thủ công.

**Truy vết.** NFR-18-020 · UI-18-09, 15, 20, 23.

**Tiền điều kiện, dữ liệu.** STAGING; một đề nghị khóa ★, một khôi phục, một cắt chuyển chờ duyệt.

**Các bước.**

1. Mở việc duyệt bằng bàn phím, mở hộp thoại duyệt.
2. Gửi lý do 3 ký tự.
3. Nhấn Esc.

**Kết quả mong đợi.** Tiêu điểm nằm trong hộp thoại, tiêu đề được đọc; lỗi lý do gắn `aria-describedby`, đọc câu ERR-18-007; Esc đóng và trả tiêu điểm về nút mở.

**Thông báo hiển thị.** ERR-18-007: "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
:::

#### TC-18-162 · Quét axe và kiểm tay mọi màn PH-18 ở thu phóng 200 % <!--k:a11y-tat-ca-man-->

::: dac-ta
**Mục đích.** Chứng minh phủ đủ 24 màn.

**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E, Thủ công.

**Truy vết.** NFR-18-020 · UI-18-06, 07, 08, 10, 11, 12, 13, 14, 16, 17, 18, 19, 21, 22, 24.

**Tiền điều kiện, dữ liệu.** STAGING; dữ liệu mẫu cho từng màn.

**Các bước.**

1. Chạy axe trên các màn ở ba điểm ngắt.
2. Thu phóng 200 %, kiểm không cuộn ngang ở 320 px.
3. Kiểm độ tương phản biểu đồ thống kê, bảng sao lưu.

**Kết quả mong đợi.** axe 0 lỗi nghiêm trọng; không mất nội dung ở 200 %; tương phản ≥ 4,5:1 cho chữ, ≥ 3:1 cho thành phần đồ họa; biểu đồ có bảng số liệu thay thế.
:::

### TS-18-46 · Tương đương hệ cũ và chức năng cũ của SRS repo

**Mục tiêu.** Chứng minh hai chức năng hệ cũ LGC-BUS-031 (cấu hình hệ thống) và LGC-BUS-037 (thực hiện lại hoặc bỏ qua) vẫn làm được trên PH-18, và 20 chức năng cũ của `docs/07-srs/SRS-PH-18-ops.md` đều có ca.

**Phủ.** LGC-BUS-031, 037; FR-18-003, 027, 031.

#### TC-18-163 · Lấy và cập nhật thông số hệ thống như hệ cũ qua kho tham số <!--k:he-cu-cau-hinh-->

::: dac-ta
**Mục đích.** Chứng minh LGC-BUS-031: thao tác "lấy, cập nhật thông số" của hệ cũ làm được bằng API-18-004, 006 và màn UI-18-08, có thêm lý do, phiên bản, bốn mắt.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** LGC-BUS-031 · FR-18-003, 007, 005 · API-18-004, 006, 013 · UI-18-08.

**Tiền điều kiện, dữ liệu.** T68 ở STAGING; danh sách 15 thông số hệ cũ ánh xạ sang khóa mới (giả định theo kiểm kê D00-03).

**Các bước.**

1. Với từng thông số hệ cũ, đọc giá trị bằng khóa mới.
2. Cập nhật ba thông số, xem lịch sử.

**Kết quả mong đợi.** Mọi thông số có khóa tương ứng; cập nhật có phiên bản và lịch sử; khóa ★ đi qua bốn mắt.
:::

#### TC-18-164 · Thực hiện lại hoặc bỏ qua bản tin lỗi như hệ cũ, kèm chẩn đoán và lũy đẳng <!--k:he-cu-thuc-hien-lai-->

::: dac-ta
**Mục đích.** Chứng minh LGC-BUS-037 và đối chiếu 20 FR cũ ở mục 7.2.

**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** LGC-BUS-037 · FR-18-019, 027, 031, 034 · API-18-041, 064, 077 · UI-18-01, 03.

**Tiền điều kiện, dữ liệu.** T68; 30 bản tin lỗi của luồng thuế giả lập.

**Các bước.**

1. Người vận hành mở danh sách, chọn 10 mục "thực hiện lại", 5 mục "bỏ qua".
2. Mở thống kê.

**Kết quả mong đợi.** Mục phát lại qua nguồn, kết quả hiện từng mục; mục bỏ qua có lý do; thống kê và xu hướng hiện đúng như chức năng thống kê cũ.
:::

## 6. Thủ tục kiểm thử thủ công

Ba thủ tục dưới bổ sung cho ca tự động ở những chỗ cần người thật, thời gian thật hoặc quyết định vận hành; kết quả ghi biên bản và lưu làm bằng chứng nghiệm thu.

### 6.1. Kiểm thử khám phá theo phiên

Phiên 90 phút cho từng nhóm (DLQ và phát lại, thông báo, khôi phục, di trú) do một kiểm thử viên và một người vận hành của tỉnh thí điểm cùng làm: thử thao tác đồng thời trên cùng mục, đổi tab giữa chừng, mất kết nối khi đang gửi duyệt, mở liên kết cũ trong thư nhắc, dán nội dung lớn vào ô sửa payload. Mỗi cách làm hỏng lũy đẳng hoặc vượt bốn mắt là lỗi S1 và được thêm thành ca tự động trước phiên kế tiếp.

### 6.2. Diễn tập khôi phục tenant

Mỗi quý PA diễn tập RBK-04 ở STAGING với tenant `QM-VUA` 200 GB: TA tạo yêu cầu, PA khác duyệt, bấm đồng hồ từ lúc duyệt tới `SUCCEEDED`, đối chiếu số dòng và kiểm tenant cùng ô không đổi. Diễn tập có một lần tiêm lỗi ở bước 5 để kiểm quay lui. Kết quả là bằng chứng cho AC-18-10 và được ghi nhận bằng FR-18-058 (UI-18-19).

### 6.3. Diễn tập cắt chuyển và quay lui

Trước mỗi đợt cắt chuyển nhóm dịch vụ thật, TA cùng PA diễn tập ở STAGING với nhóm 20 tuyến: kiểm danh sách kiểm tra, cắt chuyển, quan sát lưu lượng qua APISIX, quay lui ở phút 10 và đo thời gian tới khi 100 % lưu lượng về hệ cũ. Thời gian không vượt 15 phút (NFR-18-015, AC-18-12).

## 7. Nghiệm thu người dùng tương đương hệ cũ

Hệ cũ có hai chức năng nằm trong phạm vi PH-18: cấu hình hệ thống (LGC-BUS-031) và thực hiện lại hoặc bỏ qua bản tin lỗi (LGC-BUS-037); giám sát sự cố để trống ở hệ cũ (LGC-NFR-004) nên phần sự cố là năng lực mới. Nghiệm thu theo vai trò: cán bộ của tỉnh thí điểm tự thực hiện các việc ở 7.1 trên UAT; đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng.

### 7.1. Kịch bản nghiệm thu theo vai trò

Tám việc dưới đây phủ các nhóm FR cốt lõi và các mã hệ cũ liên quan; cột cuối dẫn tới kịch bản tự động tương ứng.

| Mã | Việc cần làm | Liên quan hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-18-01 | TA sửa một thông số của luồng trên màn tham số, xem lịch sử và khôi phục giá trị cũ | LGC-BUS-031 | Lưu có lý do, có phiên bản, khôi phục tạo phiên bản mới; khóa ★ cần SO duyệt | FR-18-003, 004, 005 | TS-18-02, 03, 04 |
| UAT-18-02 | TO lọc bản tin lỗi của luồng thuế, xem chi tiết và nội dung có lý do, phân loại | LGC-BUS-037 | Lọc đúng, chi tiết có chẩn đoán, nội dung chỉ hiện sau khi nhập lý do | FR-18-019, 021, 022, 023 | TS-18-12, 13 |
| UAT-18-03 | TO thực hiện lại một bản tin và một loạt 800 bản tin, TA duyệt loạt lớn | LGC-BUS-037 | Bản tin phát lại qua nguồn, không xử lý trùng; loạt lớn chờ TA duyệt | FR-18-027, 028, 029, 030 | TS-18-16, 17 |
| UAT-18-04 | TO bỏ qua bản tin thử nghiệm và mở lại một bản tin bỏ nhầm | LGC-BUS-037 | Bỏ qua có lý do, mở lại được trong hạn | FR-18-031, 032 | TS-18-18 |
| UAT-18-05 | TA soạn mẫu thư kích hoạt HTTT, TA khác duyệt; người dùng đặt giờ yên lặng | — | Mẫu có biến cấm bị từ chối; thư chỉ có liên kết; giờ yên lặng giữ thư thường | FR-18-035, 038 | TS-18-20, 22 |
| UAT-18-06 | TO mở sự cố từ cảnh báo, thêm mốc, liên kết bản tin lỗi, đóng có nguyên nhân và bài học | LGC-NFR-004 | Sự cố có mốc thời gian, liên kết, chỉ đóng được khi đủ nguyên nhân và bài học | FR-18-047, 048, 049, 051 | TS-18-28 |
| UAT-18-07 | TA yêu cầu khôi phục tỉnh về thời điểm hôm qua, PA duyệt, theo dõi tám bước | — | Có người thứ hai duyệt, tỉnh tạm ngừng trong lúc thay dữ liệu, thông báo kết quả | FR-18-054, 055 | TS-18-31 |
| UAT-18-08 | TA chạy thử di trú danh mục Aita, xem đối chiếu, PA duyệt chạy thật, cắt chuyển nhóm thuế rồi quay lui | LGC-HUB-008, LGC-DMDC-001 | Chạy thử không ghi; chạy thật không trùng; cắt chuyển chỉ khi đạt danh sách kiểm tra, quay lui ≤ 15 phút | FR-18-061, 062, 064, 068 | TS-18-35, 36, 38 |

: Kịch bản nghiệm thu UAT-18-01…08 theo vai trò

### 7.2. Đối chiếu 20 chức năng cũ của SRS repo

SRS repo (`docs/07-srs/SRS-PH-18-ops.md`) có 20 chức năng tập trung vào DLQ; FRS 0.1 mục 11.3 ánh xạ chúng sang FR mới. Bảng nối từng chức năng cũ với FR mới và ca chứng minh.

| Số cũ | Nội dung cũ | FR mới | TC |
|---|---|---|---|
| 001 | Tiếp nhận bản tin lỗi từ topic | FR-18-013 | TC-18-026 |
| 002 | Lưu ngữ cảnh lỗi | FR-18-015 | TC-18-027 |
| 003 | Lưu payload | FR-18-016 | TC-18-028 |
| 004 | Đối soát với Kafka | FR-18-018 | TC-18-030 |
| 005 | Phân loại tự động | FR-18-015, 023 | TC-18-026, TC-18-039 |
| 006 | Phân loại tay | FR-18-023 | TC-18-039 |
| 007 | Danh sách và lọc | FR-18-019, 023 | TC-18-036 |
| 008 | Chi tiết mục | FR-18-021 | TC-18-040 |
| 009 | Phát lại một mục | FR-18-027 | TC-18-052 |
| 010 | Phát lại loạt | FR-18-028, 029 | TC-18-057, TC-18-060 |
| 011 | Kết quả phát lại | FR-18-030 | TC-18-052 |
| 012 | Lũy đẳng khi phát lại | FR-18-030 | TC-18-053 |
| 013 | Bỏ qua | FR-18-031 | TC-18-062 |
| 014 | Nhật ký thao tác | FR-18-070 | TC-18-130 |
| 015 | Mở lại | FR-18-032 | TC-18-062 |
| 016 | Thống kê | FR-18-034 | TC-18-067 |
| 017 | Biểu đồ xu hướng | FR-18-034 | TC-18-164 |
| 018 | Theo dõi lượt | FR-18-034, 029 | TC-18-060 |
| 019 | Ngưỡng cảnh báo | FR-18-015, 034 | TC-18-067 |
| 020 | Quy tắc tự động | FR-18-039, 023 | TC-18-078 |

: Đối chiếu chức năng cũ của SRS repo với FR mới và ca kiểm thử

## 8. Ma trận truy vết

Ma trận nối FR, BR, ERR, NFR, EVT, API, UI và mã hệ cũ với test case; toàn bộ do công cụ sinh từ chính các ca nên không sửa tay.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-18. FR mức M phải có ít nhất một ca ở mỗi cột. Bảng sinh tự động bằng `ph18/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | Dương | Âm | Đạt |
|---|---|---|---|---|---|
| FR-18-001 | Đăng ký không gian tên và lược đồ khóa tham  | M | 001 | 002 | Có |
| FR-18-002 | Đọc tham số có bộ đệm cho phân hệ khác | M | 001 | 003, 005 | Có |
| FR-18-003 | Ghi giá trị tham số theo tenant có kiểm miền | M | 004, 006, 163 | 007, 008, 134 | Có |
| FR-18-004 | Duyệt bốn mắt tham số bảo mật ★ | M | 010, 012 | 011, 012, 013 | Có |
| FR-18-005 | Xem lịch sử, so sánh và khôi phục phiên bản  | M | 014, 163 | 015 | Có |
| FR-18-006 | Phát sự kiện đổi tham số và làm mới bộ đệm | M | 004 | 005 | Có |
| FR-18-007 | Màn tham số chung nhúng theo không gian tên  | M | 006, 163 | 134 | Có |
| FR-18-008 | Xuất, nhập gói tham số giữa môi trường | C | 016 | 017 | Có |
| FR-18-009 | Quản lý cờ tính năng theo tenant | M | 018 | 019 | Có |
| FR-18-010 | Quản lý danh sách egress cho phép theo tenan | S | 020 | 021 | Có |
| FR-18-011 | Ghi tham số mặc định khi khởi tạo tenant | M | 022 | 023 | Có |
| FR-18-012 | Đăng ký nguồn DLQ và cổng phát lại | M | 024 | 025 | Có |
| FR-18-013 | Tiêu thụ topic DLQ và lập chỉ mục bền | M | 026 | 027 | Có |
| FR-18-014 | Nhận mục DLQ qua API ghi cho phân hệ khác | M | 031 | 025, 032 | Có |
| FR-18-015 | Kiểm hợp đồng ngữ cảnh và đánh dấu POISON | M | 047 | 027, 032 | Có |
| FR-18-016 | Lưu payload lớn ở Garage và khử trùng theo k | M | 028, 031 | 028 | Có |
| FR-18-017 | Liên thông DLQ tầng sự kiện của PH-10 | M | 034 | 035 | Có |
| FR-18-018 | Đối soát chỉ mục DLQ với Kafka | S | 030 | 030 | Có |
| FR-18-019 | Liệt kê, lọc và tìm mục DLQ | M | 036, 139, 164 | 035, 037, 139 | Có |
| FR-18-020 | Gom nhóm mục DLQ theo dấu hiệu lỗi | C | 038 | 038 | Có |
| FR-18-021 | Xem chi tiết mục DLQ và ngữ cảnh chẩn đoán | M | 040, 139 | 037, 041, 139 | Có |
| FR-18-022 | Xem payload có lý do | M | 042 | 043 | Có |
| FR-18-023 | Phân loại, ưu tiên và gán người xử lý | M | 038, 039 | 038, 039 | Có |
| FR-18-024 | Sửa payload có kiểm soát | M | 044, 045, 047, 056 | 045, 046 | Có |
| FR-18-025 | Quản lý sổ tay xử lý theo mã lỗi | S | 040, 048, 049, 051 | 048, 051 | Có |
| FR-18-026 | Cung cấp API đọc DLQ cho PH-17 và PH-13 | S | 049 | 050 | Có |
| FR-18-027 | Phát lại một mục DLQ | M | 047, 052, 056, 164, 165 | 025, 054, 055 | Có |
| FR-18-028 | Phát lại loạt theo bộ lọc hoặc danh sách | M | 057, 058, 165 | 058, 059 | Có |
| FR-18-029 | Điều khiển lượt phát lại: tốc độ, tạm dừng,  | M | 060 | 059, 060, 131 | Có |
| FR-18-030 | Nhận kết quả phát lại và bảo đảm lũy đẳng | M | 052, 056, 057 | 055 | Có |
| FR-18-031 | Bỏ qua mục DLQ có lý do | M | 062, 164 | 063 | Có |
| FR-18-032 | Mở lại mục đã bỏ qua | S | 062 | 063, 064 | Có |
| FR-18-033 | Lưu giữ và dọn mục DLQ | M | 065 | 064, 066 | Có |
| FR-18-034 | Thống kê DLQ, chỉ số và sự kiện vượt ngưỡng | M | 067, 164 | 067 | Có |
| FR-18-035 | Quản lý mẫu thông báo có phiên bản và kiểm t | M | 068, 070 | 069, 070 | Có |
| FR-18-036 | Gửi thông báo qua NotificationApi | M | 070, 071, 073, 076, 082 | 070, 072, 073, 082 | Có |
| FR-18-037 | Phân giải người nhận từ tham chiếu | M | 071 | 072 | Có |
| FR-18-038 | Quản lý tùy chọn nhận thông báo và giờ yên l | M | 076 | 077 | Có |
| FR-18-039 | Cấu hình quy tắc thông báo theo sự kiện | M | 078 | 079 | Có |
| FR-18-040 | Thử lại, xử lý thư trả lại và danh sách chặn | M | 080, 081 | 081 | Có |
| FR-18-041 | Tra cứu nhật ký gửi thông báo và kênh cho PH | S | 081, 082 | 081, 082 | Có |
| FR-18-042 | Đăng ký loại việc của phân hệ | M | 083 | 084 | Có |
| FR-18-043 | Tạo, cập nhật và đóng việc lũy đẳng | M | 083 | 084 | Có |
| FR-18-044 | Hiển thị Việc của tôi, nhắc và quá hạn | M | 086, 166 | 088, 166 | Có |
| FR-18-045 | Quản lý lịch ngày làm việc và tính hạn cho p | M | 022, 089 | 090 | Có |
| FR-18-046 | Quản lý cửa sổ bảo trì và đóng băng thay đổi | M | 091 | 091 | Có |
| FR-18-047 | Mở hồ sơ sự cố từ sự kiện | M | 093 | 095, 100 | Có |
| FR-18-048 | Tạo tay, phân mức và gán người xử lý sự cố | M | 094 | 095 | Có |
| FR-18-049 | Ghi mốc thời gian và liên kết sự cố | S | 094 | 095 | Có |
| FR-18-050 | Chuyển sự cố có dữ liệu cá nhân sang PH-09 | S | 097 | 098 | Có |
| FR-18-051 | Đóng sự cố có nguyên nhân gốc và bài học | M | 096 | 096 | Có |
| FR-18-052 | Theo dõi sao lưu theo đối tượng và cảnh báo  | M | 099 | 100 | Có |
| FR-18-053 | Ghi nhận kết quả kiểm tra khôi phục tự động | M | 101 | 101 | Có |
| FR-18-054 | Tạo yêu cầu khôi phục một tenant | M | 103 | 104 | Có |
| FR-18-055 | Duyệt và chạy khôi phục tenant tám bước | M | 103 | 104 | Có |
| FR-18-056 | Xuất dữ liệu tenant | M | 108 | 109 | Có |
| FR-18-057 | Chuyển dữ liệu phân hệ khi sáp nhập tenant | S | 110 | 111 | Có |
| FR-18-058 | Ghi nhận diễn tập DR và PITR toàn cụm | C | 102 | 102 | Có |
| FR-18-059 | Khai báo nguồn hệ cũ | M | 112 | 113 | Có |
| FR-18-060 | Lập kế hoạch di trú theo loại đối tượng và t | M | 114 | 114 | Có |
| FR-18-061 | Chạy thử di trú không ghi | M | 115 | 116 | Có |
| FR-18-062 | Chạy thật di trú có duyệt bốn mắt | M | 119, 123 | 120, 123 | Có |
| FR-18-063 | Quản lý bản ghi lỗi và chạy lại sau khi sửa | M | 117, 167 | 116, 117, 167 | Có |
| FR-18-064 | Lập báo cáo đối chiếu số lượng và tổng kiểm  | M | 115, 119 | 118 | Có |
| FR-18-065 | Đánh dấu thông tin xác thực cần cấp lại | M | 123, 168 | 123, 168 | Có |
| FR-18-066 | Theo dõi chạy song song và cầu nối PH-10 | S | 124 | 125 | Có |
| FR-18-067 | Đối soát kết quả hệ cũ và Datahub bằng lưu l | S | 124, 169 | 125, 169 | Có |
| FR-18-068 | Điều khiển cắt chuyển nhóm dịch vụ và quay l | M | 126, 128, 168, 170 | 127, 129, 131, 168, 170 | Có |
| FR-18-069 | Quản lý tham số của phân hệ vận hành | M | 009 | 009 | Có |
| FR-18-070 | Ghi và tra nhật ký thao tác vận hành | M | 130 | 131 | Có |
| FR-18-071 | Lập báo cáo vận hành định kỳ | S | 132 | 132 | Có |
| FR-18-072 | Theo dõi sức khỏe phân hệ và chế độ suy giảm | M | 133, 171 | 023, 134, 171 | Có |

: Yêu cầu chức năng tới ca dương, ca âm

### 8.2. Chức năng hệ cũ liên quan gián tiếp → test case

Bảng lấy các mã hệ cũ liên quan PH-18 ở FRS mục 11.1 (cột FR) và nối với ca dương của các FR đó cùng các ca ghi trực tiếp mã LGC; mã ghi "Gián tiếp" là đối tượng di trú, nối với khung di trú FR-18-059…068. Chức năng cũ của SRS repo xem ở mục 7.2.

| LGC | FR của PH-18 | TC | UAT |
|---|---|---|---|
| LGC-BUS-031 | 001, 002, 003, 005, 007, 008, 011, 069 | 001, 004, 006, 009, 014, 016, 022, 163 | UAT-18-01 |
| LGC-BUS-037 | 012, 013, 014, 015, 017, 019, 020, 021, 023, 024, 025, 027, 028, 030, 031 | 024, 026, 031, 034, 036, 038, 039, 040 (+14) | UAT-18-02, UAT-18-03, UAT-18-04 |
| LGC-NFR-001 | 072 | 133, 135, 171 | — |
| LGC-NFR-004 | 021, 047 | 040, 093, 139 | UAT-18-06 |
| LGC-NFR-005 | 052 | 099 | — |
| LGC-NFR-006 | 072 | 133, 134, 171 | — |
| LGC-HUB-008 | 059, 060, 061, 062, 063, 064, 065, 066, 067, 068 | 112, 114, 115, 117, 119, 123, 124, 126 (+5) | UAT-18-08 |
| LGC-HUB-010 | 059, 060, 061, 062, 063, 064, 065, 066, 067, 068 | 112, 114, 115, 117, 119, 123, 124, 126 (+5) | — |
| LGC-DMDC-001 | 059, 060, 061, 062, 063, 064, 065, 066, 067, 068 | 112, 114, 115, 117, 119, 123, 124, 126 (+5) | UAT-18-08 |

: Chức năng hệ cũ liên quan gián tiếp tới FR, ca và UAT

### 8.3. Quy tắc nghiệp vụ → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ quy tắc nghiệp vụ này.

| Mã | Test case |
|---|---|
| BR-18-001 | 001, 002 |
| BR-18-002 | 001, 002, 006, 007, 009, 015, 017 |
| BR-18-003 | 007 |
| BR-18-004 | 009, 010, 011, 012, 016, 017, 143 |
| BR-18-005 | 006, 010, 014, 015 |
| BR-18-006 | 004, 005 |
| BR-18-007 | 003, 005, 092, 134, 135, 148, 171 |
| BR-18-008 | 018, 019 |
| BR-18-009 | 020, 021 |
| BR-18-010 | 022, 023 |
| BR-18-011 | 026, 030, 135, 145, 149 |
| BR-18-012 | 044, 046, 137 |
| BR-18-013 | 027, 032, 033, 047 |
| BR-18-014 | 028, 031, 032, 066 |
| BR-18-015 | 029, 030, 031, 033, 149 |
| BR-18-016 | 034, 049, 050, 142 |
| BR-18-017 | 042, 043, 050 |
| BR-18-018 | 045, 143, 147 |
| BR-18-019 | 024, 025, 034, 052, 054, 055, 146 |
| BR-18-020 | 052, 053, 055, 056, 146, 165 |
| BR-18-021 | 057, 058, 059, 143 |
| BR-18-022 | 024, 059, 060, 061 |
| BR-18-023 | 047, 054, 062, 063 |
| BR-18-024 | 062, 063, 064 |
| BR-18-025 | 043, 064, 065, 066 |
| BR-18-026 | 067 |
| BR-18-027 | 068, 069, 072, 147 |
| BR-18-028 | 071, 072, 074, 078 |
| BR-18-029 | 071, 082 |
| BR-18-030 | 075, 076, 077 |
| BR-18-031 | 080 |
| BR-18-032 | 039, 083, 084, 085, 087 |
| BR-18-033 | 089 |
| BR-18-034 | 089, 090 |
| BR-18-035 | 091, 092 |
| BR-18-036 | 093, 097 |
| BR-18-037 | 094, 095, 096 |
| BR-18-038 | 103, 104, 105, 106, 107, 140, 143 |
| BR-18-039 | 103, 104, 109, 120 |
| BR-18-040 | 112, 113, 114, 115, 119 |
| BR-18-041 | 117, 118, 119, 120, 122, 143, 167 |
| BR-18-042 | 123 |
| BR-18-043 | 115, 119 |
| BR-18-044 | 126, 127, 128, 129, 143, 170 |
| BR-18-045 | 110, 111, 140 |
| BR-18-046 | 010, 013, 039, 045, 058, 060, 094, 128, 130, 131 (+1) |
| BR-18-047 | 036, 037, 103, 110, 136, 137, 138, 139, 140 |
| BR-18-048 | 016, 017, 099, 102, 108, 112, 113 |
| BR-18-049 | 006, 008, 144 |
| BR-18-050 | 048, 049, 132, 138 |

: Quy tắc nghiệp vụ tới test case

### 8.4. Mã lỗi → test case

Mã `ERR-18-001…072` là lỗi control plane trả cho người dùng hoặc phân hệ gọi, `ERR-18-101…124` là lỗi của worker, tiếp nhận DLQ và gửi thông báo ghi vào trạng thái đối tượng; lỗi `401`, `403`, `428` dùng ERR-00-401, ERR-00-403, ERR-00-428.

Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ mã lỗi này.

| Mã | Test case |
|---|---|
| ERR-18-001 | 003, 015, 023, 037, 041, 051, 085, 088, 095, 101 (+3) |
| ERR-18-002 | 019, 021 |
| ERR-18-003 | 002, 025, 037, 039, 048, 067, 077, 079, 082, 084 (+4) |
| ERR-18-004 | 008, 039, 048, 077, 144 |
| ERR-18-005 | 011, 017, 045, 058, 069, 104, 120, 127, 143, 170 |
| ERR-18-006 | 030, 038, 039, 046, 060, 063, 081, 095, 168, 170 |
| ERR-18-007 | 007, 015, 043, 046, 063, 139, 161, 167, 168, 169 (+1) |
| ERR-18-008 | 013, 039, 043, 131, 145 |
| ERR-18-009 | 072, 144 |
| ERR-18-010 | 003, 050 |
| ERR-18-011 | 007 |
| ERR-18-012 | 007, 009 |
| ERR-18-013 | 007, 011, 017, 021 |
| ERR-18-014…015 | 007, 009 |
| ERR-18-016 | 002 |
| ERR-18-017 | 002, 084 |
| ERR-18-018 | 011 |
| ERR-18-019 | 012 |
| ERR-18-020 | 017 |
| ERR-18-021 | 019 |
| ERR-18-022 | 021 |
| ERR-18-023 | 015 |
| ERR-18-024 | 032, 033 |
| ERR-18-025 | 032 |
| ERR-18-026 | 025, 032 |
| ERR-18-027 | 043 |
| ERR-18-028 | 054 |
| ERR-18-029 | 046 |
| ERR-18-030 | 045 |
| ERR-18-031 | 053, 054 |
| ERR-18-032 | 059 |
| ERR-18-033 | 025, 054 |
| ERR-18-034 | 064 |
| ERR-18-035 | 035 |
| ERR-18-036 | 059, 117, 167 |
| ERR-18-037 | 059 |
| ERR-18-038 | 055, 165 |
| ERR-18-039 | 069, 072, 084, 147 |
| ERR-18-040 | 069 |
| ERR-18-041 | 070, 072, 079 |
| ERR-18-042 | 072 |
| ERR-18-043 | 081 |
| ERR-18-044 | 073 |
| ERR-18-045 | 079 |
| ERR-18-046 | 077 |
| ERR-18-047 | 084 |
| ERR-18-048 | 084, 088, 166 |
| ERR-18-049 | 090 |
| ERR-18-050 | 091 |
| ERR-18-051 | 120, 127 |
| ERR-18-052 | 096 |
| ERR-18-053…054 | 098 |
| ERR-18-055 | 100 |
| ERR-18-056 | 104 |
| ERR-18-057 | 104, 109, 120 |
| ERR-18-058 | 104 |
| ERR-18-059 | 109 |
| ERR-18-060…061 | 111 |
| ERR-18-062 | 113 |
| ERR-18-063 | 114 |
| ERR-18-064 | 120 |
| ERR-18-065 | 116 |
| ERR-18-066 | 127 |
| ERR-18-067 | 127, 170 |
| ERR-18-068 | 129 |
| ERR-18-069 | 121, 158 |
| ERR-18-070 | 113 |
| ERR-18-071 | 023, 134, 171 |
| ERR-18-072 | 132 |
| ERR-18-101…103 | 027 |
| ERR-18-104 | 028, 066 |
| ERR-18-105 | 029 |
| ERR-18-106 | 041, 145 |
| ERR-18-107 | 055 |
| ERR-18-108 | 055, 146 |
| ERR-18-109 | 053, 146 |
| ERR-18-110…111 | 074 |
| ERR-18-112 | 080 |
| ERR-18-113 | 081 |
| ERR-18-114 | 105, 106 |
| ERR-18-115 | 107 |
| ERR-18-116 | 109 |
| ERR-18-117…118 | 116 |
| ERR-18-119 | 121 |
| ERR-18-120 | 118 |
| ERR-18-121 | 125 |
| ERR-18-122 | 100 |
| ERR-18-123 | 111 |
| ERR-18-124 | 005, 023, 079, 095, 123, 125 |

: Mã lỗi tới test case

### 8.5. Yêu cầu phi chức năng → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ yêu cầu phi chức năng này.

| Mã | Test case |
|---|---|
| NFR-18-001 | 150 |
| NFR-18-002 | 149 |
| NFR-18-003 | 151 |
| NFR-18-004 | 152 |
| NFR-18-005 | 004, 152 |
| NFR-18-006 | 060, 153 |
| NFR-18-007 | 073, 154 |
| NFR-18-008 | 154 |
| NFR-18-009 | 155 |
| NFR-18-010 | 156 |
| NFR-18-011 | 157 |
| NFR-18-012 | 099 |
| NFR-18-013 | 158 |
| NFR-18-014 | 122 |
| NFR-18-015 | 128 |
| NFR-18-016 | 135, 149, 159 |
| NFR-18-017 | 037, 103, 136, 137, 138, 140, 156 |
| NFR-18-018 | 092, 135 |
| NFR-18-019 | 130 |
| NFR-18-020 | 160, 161, 162 |
| NFR-18-021 | 030 |
| NFR-18-022 | 157 |

: Yêu cầu phi chức năng tới test case

### 8.6. Sự kiện → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ sự kiện này.

| Mã | Test case |
|---|---|
| EVT-18-01 | 001, 004, 005, 006, 010, 014, 016, 138 |
| EVT-18-02 | 010, 016 |
| EVT-18-03 | 004, 018, 019 |
| EVT-18-04 | 020 |
| EVT-18-05 | 026, 031, 138 |
| EVT-18-06 | 027 |
| EVT-18-07 | 038, 039, 045, 047, 052, 053, 062, 138 |
| EVT-18-08 | 027, 030, 061, 067 |
| EVT-18-09 | 052, 053, 056, 138, 146, 165 |
| EVT-18-10 | 057, 058, 060, 061 |
| EVT-18-11 | 048, 051 |
| EVT-18-12 | 080 |
| EVT-18-13 | 074, 081, 138 |
| EVT-18-14 | 083, 087, 166 |
| EVT-18-15 | 022, 089 |
| EVT-18-16 | 091 |
| EVT-18-17 | 093, 094, 100 |
| EVT-18-18 | 094, 096, 097 |
| EVT-18-19 | 100 |
| EVT-18-20 | 101 |
| EVT-18-21 | 103, 105, 106 |
| EVT-18-22 | 103, 138 |
| EVT-18-23 | 108 |
| EVT-18-24 | 110 |
| EVT-18-25 | 115, 119 |
| EVT-18-26 | 123 |
| EVT-18-27 | 124, 126, 128, 169, 170 |
| EVT-18-28 | 132, 138 |
| EVT-18-29 | 133, 134, 171 |

: Sự kiện tới test case

### 8.7. API → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ api này.

| Mã | Test case |
|---|---|
| API-18-001…003 | 001 |
| API-18-004 | 006, 009, 163 |
| API-18-005 | 003, 006, 136 |
| API-18-006 | 006, 007, 008, 009, 010, 011, 012, 134, 144, 163 (+1) |
| API-18-007 | 006, 007 |
| API-18-008…009 | 010 |
| API-18-010 | 010, 011, 013, 017, 143 |
| API-18-011…012 | 012 |
| API-18-013 | 014, 163 |
| API-18-014 | 014 |
| API-18-015 | 014, 015 |
| API-18-016 | 006, 014, 130 |
| API-18-017 | 016 |
| API-18-018 | 016, 017 |
| API-18-019 | 016, 017, 143 |
| API-18-020 | 018 |
| API-18-021 | 018, 019 |
| API-18-022 | 018, 144 |
| API-18-023 | 018 |
| API-18-024 | 020 |
| API-18-025 | 020, 021 |
| API-18-026 | 020 |
| API-18-027 | 001, 002 |
| API-18-028 | 001, 003, 018, 020, 142, 152 |
| API-18-029 | 001 |
| API-18-030 | 022, 023 |
| API-18-031…032 | 024 |
| API-18-033 | 025, 144 |
| API-18-034 | 024 |
| API-18-035 | 025, 031, 032, 142 |
| API-18-036 | 031, 033 |
| API-18-037…038 | 030 |
| API-18-039…040 | 034, 035 |
| API-18-041 | 035, 036, 037, 136, 139, 142, 151, 164 |
| API-18-042 | 036 |
| API-18-043…044 | 038 |
| API-18-045 | 037, 040, 041, 136, 139 |
| API-18-046 | 040, 041 |
| API-18-047 | 042, 043 |
| API-18-048 | 042 |
| API-18-049 | 039, 134, 139 |
| API-18-050…051 | 039 |
| API-18-052 | 044 |
| API-18-053 | 044, 045, 046, 047 |
| API-18-054 | 044 |
| API-18-055 | 045, 143 |
| API-18-056 | 045, 046 |
| API-18-057 | 048 |
| API-18-058 | 040, 048, 051 |
| API-18-059 | 048, 144 |
| API-18-060 | 049 |
| API-18-061 | 049, 050 |
| API-18-062 | 049, 051 |
| API-18-063 | 039, 130 |
| API-18-064 | 025, 046, 047, 052, 053, 054, 055, 056, 164 |
| API-18-065 | 057, 059, 144 |
| API-18-066…068 | 057 |
| API-18-069 | 057, 058 |
| API-18-070 | 058, 143 |
| API-18-071 | 058 |
| API-18-072…074 | 060 |
| API-18-075 | 059, 060 |
| API-18-076 | 052, 053, 055, 056 |
| API-18-077 | 062, 063, 164 |
| API-18-078 | 062 |
| API-18-079 | 062, 063, 064 |
| API-18-080 | 065 |
| API-18-081 | 067, 132 |
| API-18-082 | 068 |
| API-18-083 | 068, 144 |
| API-18-084 | 068 |
| API-18-085…087 | 068, 069 |
| API-18-088 | 068, 069, 143 |
| API-18-089…090 | 070 |
| API-18-091 | 070, 071, 072, 081, 134, 142, 154 |
| API-18-092 | 073, 081, 154 |
| API-18-093 | 071, 082 |
| API-18-094 | 071 |
| API-18-095 | 076 |
| API-18-096 | 076, 077, 144 |
| API-18-097…098 | 076 |
| API-18-099 | 078 |
| API-18-100 | 078, 079 |
| API-18-101 | 078, 144 |
| API-18-102 | 082 |
| API-18-103 | 081 |
| API-18-104 | 080 |
| API-18-105 | 081 |
| API-18-106 | 080 |
| API-18-107 | 083, 084 |
| API-18-108 | 083 |
| API-18-109 | 083, 084, 085, 155 |
| API-18-110 | 083 |
| API-18-111 | 085, 086, 155 |
| API-18-112 | 085, 086, 088, 136, 166 |
| API-18-113 | 089 |
| API-18-114 | 089, 090, 144 |
| API-18-115…116 | 089 |
| API-18-117 | 089, 090 |
| API-18-118…119 | 091 |
| API-18-120 | 091, 144 |
| API-18-121 | 091 |
| API-18-122 | 091, 092 |
| API-18-123 | 093, 136 |
| API-18-124 | 094, 095, 144 |
| API-18-125 | 094, 136 |
| API-18-126 | 094, 144 |
| API-18-127…129 | 094, 095 |
| API-18-130 | 097, 098 |
| API-18-131 | 096 |
| API-18-132 | 093 |
| API-18-133 | 099, 100 |
| API-18-134…135 | 099 |
| API-18-136…137 | 101 |
| API-18-138 | 103, 104, 144 |
| API-18-139 | 103 |
| API-18-140 | 103, 136 |
| API-18-141 | 103 |
| API-18-142 | 103, 104, 143 |
| API-18-143…144 | 104 |
| API-18-145 | 103, 105, 106, 107 |
| API-18-146 | 106 |
| API-18-147 | 108, 109 |
| API-18-148…149 | 108 |
| API-18-150 | 110, 111 |
| API-18-151…152 | 110 |
| API-18-153 | 111 |
| API-18-154…155 | 102 |
| API-18-156 | 112 |
| API-18-157…158 | 112, 113 |
| API-18-159…161 | 114 |
| API-18-162 | 114, 144 |
| API-18-163 | 114 |
| API-18-164 | 115, 116, 117, 119, 120 |
| API-18-165 | 115 |
| API-18-166 | 115, 119, 121, 136 |
| API-18-167 | 119, 120, 143 |
| API-18-168 | 120 |
| API-18-169 | 116 |
| API-18-170 | 116, 117, 121, 167 |
| API-18-171 | 115, 118, 119, 167 |
| API-18-172 | 123, 168 |
| API-18-173 | 124 |
| API-18-174 | 124, 126, 168, 169, 170 |
| API-18-175 | 126, 127, 128, 129, 143, 170 |
| API-18-176 | 124, 125 |
| API-18-177 | 130 |
| API-18-178…179 | 132 |
| API-18-180 | 133, 134, 171 |
| API-18-181 | 166 |
| API-18-182 | 167 |
| API-18-183 | 168 |
| API-18-184 | 169 |
| API-18-185 | 170 |
| API-18-186 | 171 |
| API-18-187 | 134, 171 |
| API-18-188 | 165 |

: API tới test case

### 8.8. Màn hình → test case

Cột "Test case" liệt kê ba chữ số cuối của mã TC-18 phủ màn hình này.

| Mã | Test case |
|---|---|
| UI-18-01 | 026, 027, 031, 034, 035, 036, 039, 062, 160, 164 |
| UI-18-02 | 038, 160 |
| UI-18-03 | 027, 028, 039, 040, 041, 042, 052, 062, 160, 164 |
| UI-18-04 | 044, 045, 160 |
| UI-18-05 | 057, 058, 160 |
| UI-18-06 | 024, 030, 065, 067, 162 |
| UI-18-07 | 048, 162 |
| UI-18-08 | 001, 006, 008, 016, 022, 134, 162, 163 |
| UI-18-09 | 010, 014, 161 |
| UI-18-10 | 018, 020, 162 |
| UI-18-11 | 068, 078, 162 |
| UI-18-12 | 068, 162 |
| UI-18-13 | 071, 082, 162 |
| UI-18-14 | 076, 162 |
| UI-18-15 | 010, 045, 058, 068, 083, 085, 086, 103, 119, 126 (+3) |
| UI-18-16 | 089, 091, 162 |
| UI-18-17 | 093, 094, 162 |
| UI-18-18 | 094, 097, 162 |
| UI-18-19 | 099, 101, 102, 162 |
| UI-18-20 | 103, 108, 110, 161 |
| UI-18-21 | 112, 114, 115, 119, 162 |
| UI-18-22 | 115, 119, 123, 162, 167, 168 |
| UI-18-23 | 123, 124, 126, 161, 169, 170 |
| UI-18-24 | 004, 023, 026, 067, 130, 132, 133, 134, 162, 171 |

: Màn hình tới test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

Chương này liệt kê chuỗi công cụ sinh phần tự động của tập và bảng đối chiếu tiêu chí chấp nhận cấp phân hệ.

### 9.1. Sinh ma trận, Gherkin, bảng tính

Chuỗi lệnh dưới chạy từ `05-kiem-thu/test-case/`; công cụ chép từ `ph17/tools/` và chỉnh cho PH-18. Tệp Gherkin kiểm bằng `build/tools/kiem_tra_gherkin.mjs` (mỗi Kịch bản đúng một thẻ `@TC-18-nnn` hoặc `@UAT-18-nn`).

| Lệnh | Kết quả |
|---|---|
| `python3 ph18/tools/number_tcs.py` | Cấp số `TC-18-nnn`, thay `[[tc:khóa]]` |
| `python3 ph18/tools/fill_doc.py` | Ghi bảng 3.1, số kịch bản, số ca và chương 8; in ra stderr các mã chưa có ca |
| `python3 ph18/tools/gen_gherkin.py` | `ph18/gherkin/ts-18-nn.feature`, `uat-van-hanh.feature` |
| `python3 ph18/tools/gen_xlsx.py` | `ph18/D05-02-PH18-test-case.xlsx` theo mẫu nghiệm thu |
| `python3 ph18/tools/check_refs.py` | Đối chiếu mã trong tập với FRS, UC, màn hình |
| `build/build-docx.sh 05-kiem-thu/test-case/D05-02-PH18-test-case.md` | Bản `.docx` ở `build/out/` |

: Chuỗi công cụ sinh phần tự động

### 9.2. Đối chiếu tiêu chí chấp nhận cấp phân hệ

Bảng nối 13 tiêu chí AC-18-01…13 ở FRS §14 với ca chứng minh.

| Tiêu chí FRS §14 | Ca |
|---|---|
| AC-18-01 Đổi tham số có hiệu lực ≤ 60 giây; khóa ★ chỉ có hiệu lực sau người duyệt thứ hai | TC-18-004, TC-18-010, TC-18-011, TC-18-152 |
| AC-18-02 Tắt `dh-platform` 30 phút không lỗi data plane, bản tin được nhận đủ | TC-18-135, TC-18-149 |
| AC-18-03 Bản tin thiếu header thành `POISON`, không phát lại được | TC-18-027, TC-18-054 |
| AC-18-04 Payload gốc không đổi sau sửa; trường Hạn chế cần bốn mắt | TC-18-044, TC-18-045 |
| AC-18-05 Xem payload ghi kiểm toán trước, trường mã hóa vẫn che | TC-18-042, TC-18-043 |
| AC-18-06 Phát lại hai lần không xử lý trùng; lượt vượt ngưỡng bốn mắt; tự dừng khi lỗi vượt ngưỡng | TC-18-053, TC-18-058, TC-18-061 |
| AC-18-07 Thông báo không chứa trường Hạn chế; thư chỉ mang liên kết; trả lại cứng vào danh sách chặn | TC-18-069, TC-18-072, TC-18-080 |
| AC-18-08 Việc chỉ hiện với người được giao còn quyền; việc bốn mắt ẩn với người tạo | TC-18-085, TC-18-143 |
| AC-18-09 Sự cố có DLCN chuyển PH-09; đóng cần nguyên nhân và bài học | TC-18-097, TC-18-096 |
| AC-18-10 Khôi phục 200 GB ≤ 4 giờ, không chạm tenant khác, không khôi phục kiểm toán | TC-18-103, TC-18-156, TC-18-140 |
| AC-18-11 Chạy lại di trú không trùng; đối chiếu khớp; không di trú thông tin xác thực | TC-18-122, TC-18-115, TC-18-123 |
| AC-18-12 Cắt chuyển chỉ khi danh sách kiểm tra đạt; quay lui ≤ 15 phút | TC-18-126, TC-18-127, TC-18-128, TC-18-129 |
| AC-18-13 100 % thao tác ghi có kiểm toán; mọi màn đạt WCAG 2.2 AA | TC-18-130, TC-18-162 |

: Đối chiếu tiêu chí chấp nhận cấp phân hệ với ca kiểm thử

## 10. Đề nghị đồng bộ và câu hỏi mở

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu khác. Các điểm dưới là chỗ ca phải giả định hoặc phát hiện lệch giữa các tập của PH-18, ghi để chủ tài liệu quyết định; FRS vẫn là nguồn chuẩn. Ở bản 0.2, tám đề nghị mục 10.1 đã được FRS 0.2 và D03-04-PH18 0.2 hấp thụ; mục 10.2 thuộc tài liệu dùng chung, giữ cho đợt đồng bộ liên phân hệ. Ca mới cho API-18-181…188: TC-18-165, TC-18-166, TC-18-167, TC-18-168, TC-18-169, TC-18-170, TC-18-171.

### 10.1. Đề nghị cho FRS và D03-04-PH18

Các điểm dưới cần FRS hoặc tập API chốt; cột "Cách ca đang xử lý" nêu cách ca xử lý ở bản 0.1, cột cuối ghi kết quả đợt đồng bộ nội bộ ở bản 0.2.

| Mã | Điểm cần chốt | Cách ca đang xử lý | Trạng thái |
|---|---|---|---|
| ĐN-TC-01 | Câu thông báo của ERR-18-001, 005, 006, 007 viết cho một ngữ cảnh (ĐN-UC-01) | Phần "Thông báo hiển thị" chép nguyên văn FRS §9.1; khi FRS nhận câu theo ngữ cảnh thì chạy lại công cụ để cập nhật | Đã hấp thụ ở 0.2: FRS §9.1 dùng câu chung có tham số; phần "Thông báo hiển thị" đã chép lại |
| ĐN-TC-02 | ERR-18-071 có câu hẹp hơn FR-18-072 (ĐN-UC-02) | TC-18-134 kỳ vọng mọi API ghi trả ERR-18-071, không chỉ API tham số | Đã hấp thụ ở 0.2: §9.1 dùng câu của FR-18-072 |
| ĐN-TC-03 | Ghi DLQ qua API thiếu trường bắt buộc: FR-18-014 trả ERR-18-024 còn BR-18-013 nói mục thiếu trường là `POISON` | TC-18-032 kỳ vọng API từ chối `422`, đường topic mới thành `POISON` | Đã hấp thụ ở 0.2: BR-18-013 nêu rõ hai đường vào, khớp TC-18-032 |
| ĐN-TC-04 | Đề nghị đổi tham số bị rút: FRS dùng "rút", enum `ChangeRequestStatus` dùng `CANCELLED`; hết hạn dùng `EXPIRED` | TC-18-012 kỳ vọng `CANCELLED` và `EXPIRED` theo `openapi-ops.yaml` | Đã hấp thụ ở 0.2: FRS §4.5 và FR-18-004 định nghĩa `CANCELLED`, `EXPIRED` |
| ĐN-TC-05 | Chưa có API nhận việc, đánh dấu cách xử lý bản ghi lỗi di trú, đánh dấu `NOT_NEEDED` cấp lại xác thực (ĐN-UC-03, 04, 05) | TC-18-117 dùng `retryErrorsOf` của API-18-164; chưa có ca cho các thao tác chưa có API | Đã hấp thụ ở 0.2: API-18-181, 182, 183 (trạng thái `WAIVED`); thêm ca TC-18-166, TC-18-167, TC-18-168 |
| ĐN-TC-06 | Cắt chuyển dùng một API `:transition` cho đề nghị, duyệt, quay lui (ĐN-UC-08) | TC-18-126 giả định thân `action = REQUEST`, `APPROVE`, `ROLLBACK` | Đã hấp thụ ở 0.2: API-18-175 nhận `action` (`REQUEST`, `APPROVE`, `REJECT`, `ROLLBACK`); thêm ca TC-18-170 |
| ĐN-TC-07 | Kiểm DLCN trong nội dung sổ tay xử lý (BR-18-050) chưa có mã lỗi riêng | TC-18-048 kỳ vọng ERR-18-003 | Đã hấp thụ ở 0.2: FR-18-025 bước 2 dùng ERR-18-003, khớp TC-18-048 |
| ĐN-TC-08 | Lượt phát lại có mục đã đổi trạng thái khi duyệt: trạng thái mục bị loại chưa nêu | TC-18-058 kỳ vọng mục ghi `SKIPPED` và `total` giảm | Đã hấp thụ ở 0.2: FRS §4.5 và FR-18-028 định nghĩa `SKIPPED` |

: Điểm cần chốt ở FRS, API và cách ca xử lý

### 10.2. Đề nghị đồng bộ tài liệu khác

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới thuộc tài liệu dùng chung hoặc tập của người khác; tập này không tự sửa.

| Tài liệu | Đề nghị |
|---|---|
| D05-01 | Thêm PH-18 vào bảng phân bổ tenant kiểm thử `T90…T99`; thêm tiêu chí "0 mục mất, 0 mục trùng" và "bốn mắt không đường vòng" vào cổng `RG-2` |
| D03-03-PH18, `csdl/ph18/test/` | Bộ kiểm `ph18_isolation_test.sql` dùng nguyên ở TC-18-137; giữ chạy được trên `postgres:16` trong CI |
| D03-04-PH18, `openapi-ops.yaml` | Đối chiếu tên trường giả định (giữ cho đợt cuối): `useRevision`, `retryErrorsOf`, `maintenanceNotice`, `excludeUsers`, `partial`, `calendarMissing`, `calendarSource`, `collectorError` |
| D03-06-PH18 | Đối chiếu nhãn nút, dải cảnh báo chỉ đọc và câu thông báo ở TC-18-035, TC-18-134, TC-18-161 |
| D02-08 | Cặp loại trừ người tạo và người duyệt của tám đối tượng bốn mắt (TC-18-143) cần có ở §4 |
| D02-04-PH18 | Đã thực hiện ĐN-UC-15: TS-18-01…40 ứng một một với UC-18-01…40, ca bốn mắt cho mọi UC thuộc LP-18-01, ca lũy đẳng, khôi phục lỗi bước 3 và 5, quay lui phút 14 và 16 |
| D00-04 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi nhận tập này (số TS, TC mới) |

: Đề nghị đồng bộ tài liệu khác

### 10.3. Câu hỏi mở

Năm câu hỏi dưới theo dải Q18-40…44 dành cho tập kiểm thử.

> **Câu hỏi mở Q18-40:** Môi trường PERF có đủ dung lượng cho hồ sơ `QM-VUA` 200 GB để đo NFR-18-010, 011, 022 không, hay chỉ đo ở STAGING với 50 GB rồi ngoại suy. Tạm giả định PERF có ô CSDL riêng 400 GB.

> **Câu hỏi mở Q18-41:** Tên trường JSON giả định ở mục 1.5 và 10.2, và khóa tham số của phân hệ khác dùng làm ví dụ (`04.retry.max-attempts`, `02.review.sla-days`, `17.external-model.enabled`) chưa chốt; tạm dùng như ghi ở ca, đối chiếu khi `openapi-ops.yaml` và FRS của PH-02, PH-04, PH-17 chốt.

> **Câu hỏi mở Q18-42:** Giới hạn tần suất của API đọc tham số và API nội bộ cho PH-17 chưa có số ở FRS; ca TC-18-003 và TC-18-050 giả định 50 và 100 yêu cầu mỗi giây mỗi danh tính ở TEST.

> **Câu hỏi mở Q18-43:** Thời gian 4 giờ của khôi phục tenant tính từ lúc duyệt (theo Q18-46 của tập use case); ca TC-18-156 đo từ lúc duyệt. Cần chủ đầu tư xác nhận để chốt cổng `RG-3`.

> **Câu hỏi mở Q18-44:** Dữ liệu nguồn giả lập `LEG-AITA` dựng theo lược đồ hệ cũ nào (bản Aita của Viettel 2021 hay bản trích của tỉnh thí điểm). Tạm dựng theo kiểm kê D00-03 với quy mô GĐ-01; cần tỉnh thí điểm cấp bản trích đã ẩn danh trước UAT-18-08.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-27 | Nhóm kiểm thử | Bản đầu: kịch bản TS-18-01…46, test case TC-18, UAT-18-01…08, ma trận truy vết, Gherkin, bảng tính theo FRS 0.1 |
| 0.2 | 2026-11-27 | Nhóm kiểm thử | Đồng bộ nội bộ theo FRS 0.2: chép lại câu thông báo ERR-18-001, 005, 006, 007, 013, 017, 036, 069, 071 theo §9.1; thêm bảy ca cho API-18-181…188; TC-18-126, 134 theo `action` và API-18-187; dấu cấp lại `REISSUED`; mục 10.1 thêm cột trạng thái, cả tám đề nghị đã hấp thụ |
| 0.3 | 2026-11-27 | Nhóm kiểm thử | Đồng bộ chéo cuối: route `/viec-cua-toi`, `retryOf` theo OpenAPI |

: Lịch sử phiên bản
