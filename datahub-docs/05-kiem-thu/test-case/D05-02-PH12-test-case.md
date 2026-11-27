---
ma_tai_lieu: D05-02-PH12
ten: Kịch bản và test case phân hệ PH-12 Định danh và phân quyền
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT)
phan_he: PH-12
mo_ta: Kịch bản và test case của phân hệ Định danh và phân quyền, chạy được trên SIT với bộ dữ liệu mẫu, kèm nghiệm thu người dùng tương đương hệ IAM cũ và ma trận truy vết tới FR, UC, API, UI, ERR.
tai_lieu_lien_quan: D05-01 Kế hoạch kiểm thử tổng thể; D02-03-PH12 FRS; D02-04-PH12 Use case; D03-02-PH12 SDD; D03-04-PH12 API; D03-06-PH12 Màn hình; D02-08 Ma trận phân quyền
---

# D05-02-PH12 · Kịch bản và test case Định danh và phân quyền

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-12 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH12 (62 FR, 45 BR, 33 NFR), qua 42 use case, 111 API và 19 màn hình.
- Không mất chức năng của hệ IAM cũ: SSO Keycloak, tạo realm, client, vai trò, người dùng, TOTP, LDAP/AD, quản lý phiên (LGC-IAM-001…006, 008), cùng quản lý group của Bus và tạo Application của APIM (LGC-BUS-032, LGC-APIM-020). Chức năng bị loại có chủ đích (đăng nhập mạng xã hội LGC-IAM-007, grant `password` LGC-IAM-006) được kiểm là **không còn** hoạt động.
- Mặc định từ chối, từ chối thắng cho phép, cách ly tenant và không lộ bí mật là bất biến hệ thống: không có đường nào để quyết định ủy quyền sai theo hướng cho phép, và không có đường nào để tỉnh này thấy hay dùng định danh, client, chính sách của tỉnh khác.

**Phạm vi.** Gồm <!--gen:so-ts-->37<!--/gen--> kịch bản (TS-12-01…) với <!--gen:so-tc-->127 (TC-12-001…127; 99 ca P1)<!--/gen--> test case và 10 kịch bản nghiệm thu người dùng (UAT-01…10). Mỗi FR mức M có ít nhất một ca dương và một ca âm; mọi FR, UC, API, UI và mã lỗi `ERR-12-*` có ít nhất một ca; ma trận mục 8 sinh tự động từ chính tài liệu này bằng `ph12/tools/gen_matrix.py`.

**Căn cứ.** Tài liệu cùng bộ PH-12 (FRS D02-03-PH12, use case D02-04-PH12, SDD D03-02-PH12, CSDL D03-03-PH12, API D03-04-PH12, màn hình D03-06-PH12); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP, TCVN 14423:2026 (mật khẩu ≥ 14 ký tự, khóa phiên 15 phút, vô hiệu tài khoản sau 45 ngày); Luật BVDLCN 91/2025 và Nghị định 356/2025 cho dữ liệu cá nhân trong danh bạ.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- fail-closed: OPA ngừng, hết thời gian chờ, chưa nạp gói thì mọi yêu cầu bị từ chối, 0 yêu cầu lọt (TS-12-26, TS-12-35);
- từ chối thắng cho phép và chính sách tenant không được nới quyền (TS-12-26, TS-12-29);
- cách ly tenant ở API, token, realm, RLS (TS-12-34);
- bốn mắt cho chính sách, vai trò tùy biến, quyền có thời hạn, ngoại lệ tách nhiệm vụ, và không ai tự nâng quyền của mình (TS-12-08, 11, 29);
- không lộ mật khẩu, mã TOTP, bí mật client, token đầy đủ (TS-12-33);
- thu hồi truy cập có hiệu lực không quá 60 giây (TS-12-24, TS-12-36).

Mã W1 hiện có chưa có schema `ph12_iam` đầy đủ; các ca ở đây là tiêu chí nghiệm thu của công việc mới. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT) vì chưa có dữ liệu thật.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu này là bộ kịch bản và test case chạy được của phân hệ PH-12 Định danh và phân quyền trên môi trường SIT với bộ dữ liệu mẫu ở mục 2. Phạm vi gồm kiểm thử chức năng, bảo mật, hiệu năng, chịu lỗi và nghiệm thu người dùng tương đương hệ IAM cũ, như nêu ở phần Tóm tắt.

### 0.2. Người đọc

Tài liệu dành cho kiểm thử viên viết và chạy ca, kỹ sư tự động hóa, cán bộ ATTT xem nhóm ca bảo mật, và đại diện chủ đầu tư xem mục 7.

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ theo D00-01 §2. Viết tắt vai trò theo D02-08: PA (PLATFORM_ADMIN), PO (PLATFORM_OPERATOR), TA (TENANT_ADMIN), SO (SECURITY_OFFICER), AU (AUDITOR), IE (INTEGRATION_ENGINEER), IA (INTEGRATION_APPROVER), VW (VIEWER). PEP là điểm thực thi chính sách (APISIX, thư viện trong DU), PDP là điểm quyết định (OPA), JWKS là bộ khóa công khai để xác minh chữ ký token.

### 0.4. Tài liệu tham chiếu

Nguồn chuẩn của các mã được kiểm thử là D02-03-PH12 (FR, BR, NFR), D02-04-PH12 (UC), D03-04-PH12 (API, ERR) và D03-06-PH12 (UI), cùng ma trận phân quyền D02-08 và kế hoạch kiểm thử tổng thể D05-01.

### 0.5. Cấu trúc tài liệu

Mục 1 nêu chiến lược và tổ chức kiểm thử, mục 2 dữ liệu kiểm thử, mục 3 tổng quan kịch bản, mục 4 các kịch bản chức năng, mục 5 các kịch bản phi chức năng và xuyên suốt, mục 6 thủ tục kiểm thử thủ công, mục 7 nghiệm thu người dùng, mục 8 ma trận truy vết sinh tự động, mục 9 công cụ đi kèm và mục 10 các đề nghị đồng bộ.

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

Đối tượng là toàn bộ PH-12 ở ba lớp: (1) API quản trị `/api/iam/v1` của `dh-platform` (API-12-001…071, 080…085, 089…111); (2) Keycloak (điểm cuối OIDC, API-12-072…078) cùng theme đăng nhập UI-12-18; (3) OPA, bộ chuyển đổi và API quyết định `/api/authz/v1` (API-12-086…088). Ngoài phạm vi: nội dung chính sách của phân hệ khác (kiểm ở tập của phân hệ đó), tích hợp VNeID thật (dùng giả lập `SIM-VNEID`, Đợt 2), hiệu năng toàn hệ thống (D05-01).

### 1.2. Mức kiểm thử

Bảng sau nêu các mức kiểm thử áp dụng cho PH-12, công cụ dùng ở từng mức và các ca tiêu biểu.

| Mức | Công cụ | Ca tiêu biểu |
|---|---|---|
| UT (đơn vị) | JUnit 5, `opa test` | Quy tắc mật khẩu BR-12-018, sinh khóa đệm, luật Rego gốc (≥ 90 % dòng, SEC-26) |
| IT (tích hợp) | Testcontainers: PostgreSQL 16, Keycloak, OPA, OpenBao, Kafka | Gán vai trò, bốn mắt, sinh gói chính sách ký |
| DB | `psql` với `ph12_isolation_test.sql` (24 nhóm kiểm), pgTAP; `TenantIsolationIT` cho ca đồng thời | RLS ba mẫu P, S, G của `ph12_iam`, `tenant_id` mọi bảng, bất biến, tách nhiệm vụ, bốn mắt, không lưu bí mật |
| API | REST Assured, k6 | Hợp đồng RFC 9457, `If-Match`, `Idempotency-Key` |
| E2E | Playwright, axe-core | UI-12-01…19, đăng nhập với PKCE, WebAuthn ảo |
| ZAP, Chaos | OWASP ZAP, Chaos Mesh | Quét ASVS 5.0 mức 2, tắt OPA, tắt Keycloak |
| Thủ công | Theo mục 6 | NVDA, diễn tập mất thiết bị, diễn tập sự cố khóa ký |

: Mức kiểm thử và công cụ

### 1.3. Môi trường kiểm thử

SIT dùng cấu hình `QM-NHO` (Keycloak 3 bản sao, OPA sidecar, `pg-iam` 3 instance); ca hiệu năng chạy trên môi trường PERF cấu hình `QM-VUA` với dữ liệu quy mô GĐ (10.000 người dùng, 1.000 client mỗi tenant, 500 phiên bản chính sách). UAT chạy trên bản sao dữ liệu hệ cũ đã ẩn danh. Đồng hồ hệ thống được điều khiển được ở SIT (ca 45 ngày, 90 ngày, 14 ngày dùng `clock-skew` của môi trường kiểm thử, không đổi giờ thật).

### 1.4. Tiêu chí vào và ra

Bảng sau nêu điều kiện để bắt đầu kiểm thử và điều kiện để coi một đợt kiểm thử là hoàn tất.

| Tiêu chí | Nội dung |
|---|---|
| Vào | Bản dựng qua cổng CI-1…6; bộ dữ liệu mục 2 nạp qua API (không chèn SQL trực tiếp, trừ dữ liệu LDAP giả lập); realm `dh-t68` khởi tạo từ mẫu |
| Ra (RG-3) | 100 % ca P1 đạt; 100 % ca nhóm sáu điểm lưu ý; ≥ 95 % ca P2; 0 lỗi Nghiêm trọng, Cao còn mở; mọi FR mức M phủ dương và âm (mục 8.1) |
| Dừng | Một lỗi lộ bí mật hoặc cho phép chéo tenant dừng toàn bộ đợt chạy cho tới khi sửa |

: Tiêu chí vào và ra

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-12-nn`, test case `TC-12-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi test case thống nhất với D05-02-PH04, PH05:

- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, API, E2E, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, NFR, UC, LGC.
- **Tiền điều kiện / dữ liệu**: mã dữ liệu ở mục 2. Đường dẫn API tương đối với `/api/iam/v1` trừ khi nêu khác.
- **Bước** và **Mong đợi**: mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` ERR-12-007 (thiếu quyền `PERM-12-*`) |
| 404-ẩn | `404` ERR-12-001, thân giống hệt "không tồn tại" và "thuộc tenant, tổ chức khác" trừ `traceId` (BR-12-041) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa bí mật |
| SK: `{tên}` | Đúng một sự kiện nghiệp vụ trên topic `t68.iam.{tên}.v1` (CloudEvents, có `dhtenant`) |
| Mồi sạch | Tìm chuỗi `DH-CANARY-{ca}` ở phản hồi API, log 5 phút, vết OTel, bảng `ph12_iam.*`, Kafka, tệp xuất: không thấy |

: Quy ước mã và cách trình bày

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-12`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: quyết định cho phép khi đáng ra từ chối (kể cả khi OPA lỗi); đọc hay ghi được đối tượng của tenant khác; lộ mật khẩu, mã TOTP, bí mật client, token đầy đủ; người tự duyệt hoặc tự nâng quyền của mình; chính sách tenant nới được quyền của gói gốc; thu hồi quá 60 giây. Báo cáo hằng đêm từ JUnit, `opa test`, Playwright, k6, đối chiếu ma trận mục 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập. Nạp bằng `ph12/seed/` qua API quản trị; tài khoản người dùng có mật khẩu ngẫu nhiên 20 ký tự lưu ở OpenBao của môi trường kiểm thử.

### 2.1. Tenant và realm

Bảng sau định nghĩa các tenant và realm mẫu dùng trong mọi ca, kèm tham số mặc định của từng tenant.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính (giả lập), realm `dh-t68` | Tham số mặc định: nhàn rỗi 15 phút, tối đa 3 phiên, miền thư `*.t68.test` |
| `T01` | Tỉnh đối chứng rò rỉ | Có người dùng `ha.nguyen`, nhóm `phong-cntt` **trùng mã** với T68 để phát hiện trả nhầm |
| `PLATFORM` | Tenant nền tảng | Chỉ vai trò `PLATFORM_*` |
| `T90` | Tenant để khởi tạo, tạm ngừng, khôi phục realm | Chưa có realm lúc đầu |
| `T91`, `T92` | Tenant nguồn và đích của ca sáp nhập | T91 có 12 người dùng, 3 client |

: Tenant và realm kiểm thử

### 2.2. Người dùng

Tên nhân vật trùng D02-04-PH12. Mọi người dùng vai trò TA, SO, PA, PO có WebAuthn ảo (Playwright virtual authenticator); người dùng khác có TOTP thử.

| Mã | Tenant | Vai trò | Mục đích |
|---|---|---|---|
| U-PA, U-PA2 | PLATFORM | PA | Quản trị nền tảng; người thứ hai cho bốn mắt |
| U-PO | PLATFORM | PO | Vận hành, xin quyền có thời hạn |
| U-T68-TA1, U-T68-TA2 | T68 | TA | Quản trị tỉnh; TA2 để kiểm "không tự thao tác" và "tenant luôn còn một TA" |
| U-T68-SO, U-T68-SO2 | T68 | SO | Cán bộ ATTT, người duyệt thứ hai |
| U-T68-AU | T68 | AU | Kiểm toán, chỉ đọc |
| U-T68-IE, U-T68-IA | T68 | IE, IA | Vai trò kết nối; xung đột tách nhiệm khi gán cả hai |
| U-T68-VW | T68 | VW | Chỉ `PERM-12-read` |
| U-T68-MGR | T68 | Người quản lý trực tiếp | Rà soát quyền |
| U-T68-NEW | T68 | Chưa có | Tài khoản `PENDING_ACTIVATION` |
| U-T68-OLD | T68 | VW | Không đăng nhập 44 ngày, dùng cho ca 45 ngày |
| U-T68-PH07 | T68 | VW thuộc đơn vị `DV-A` | Ca phạm vi tổ chức (BR-12-037) |
| U-T01-TA, U-T01-SO | T01 | TA, SO | Đối chứng rò rỉ |
| U-MULTI | T68 và T01 | VW | Người thuộc hai tenant (FR-12-027) |

: Người dùng kiểm thử

### 2.3. Client, tài khoản dịch vụ, chính sách

Bảng sau định nghĩa các client, tài khoản dịch vụ và chính sách mẫu, để các ca tham chiếu theo mã thay vì mô tả lại.

| Mã | Ý nghĩa |
|---|---|
| C-T68-A | Client của HTTT `HT-A`, hợp đồng mức Hạn chế, mTLS, có scope `catalog:read` |
| C-T68-B | Client của HTTT `HT-B`, mức Công khai, `client_secret` |
| C-T68-N | Client của HTTT `HT-N`, hợp đồng mức Nhạy cảm, mTLS bắt buộc |
| C-DEV | Client sandbox của ứng dụng nhà phát triển (PH-15) |
| S-PEP, S-PH04, S-PH20 | Tài khoản dịch vụ có scope `iam:decide`, `iam:realm-provision` |
| POL-GOC | Gói gốc nền tảng (deny cách ly tenant, mặc định từ chối) |
| POL-T68-OK | Chính sách tenant hợp lệ: chỉ thêm luật từ chối và nghĩa vụ |
| POL-T68-ALLOW | Chính sách tenant **vi phạm**: có luật `allow` |

: Client, tài khoản dịch vụ và chính sách

### 2.4. Hệ giả lập và tệp mẫu

Bảng sau liệt kê các hệ giả lập và tệp mẫu dùng thay cho hệ thật (LDAP, SAML, VNeID, Kafka và các tệp nhập), kèm đặc điểm của từng thứ.

| Mã | Ý nghĩa |
|---|---|
| SIM-LDAP | OpenLDAP 3 cây, 300 người dùng, 5 nhóm; một người dùng trùng thư với tài khoản có sẵn |
| SIM-SAML-SP | Ứng dụng cũ giả lập (Service Provider SAML 2) |
| SIM-VNEID | Nhà cung cấp VNeID giả lập (OIDC) |
| SIM-SMTP | Máy chủ thư giả lập đọc được thư kích hoạt, đặt lại mật khẩu |
| SIM-PH07 | Danh mục đơn vị giả lập `DV-A`, `DV-B`, `DV-HET` (hết hiệu lực) |
| SIM-OPA-DOWN | Công tắc Chaos Mesh tắt OPA hoặc làm chậm quá 50 ms |
| F-USR-OK | Tệp CSV 20 người dùng hợp lệ |
| F-USR-BAD | Tệp 20 dòng, 3 dòng lỗi (thư ngoài miền, đơn vị hết hiệu lực, trùng tên đăng nhập) |
| F-USR-PWD | Tệp có cột `password` |
| F-USR-BIG | Tệp quá giới hạn kích thước hoặc số dòng |
| F-USR-LGC | Tệp xuất từ IAM cũ, 2 vai trò chưa có ánh xạ |
| F-CERT-OK, F-CERT-BAD | Chứng thư X.509 hợp lệ, hết hạn; JWKS hợp lệ và sai |

: Hệ giả lập và tệp mẫu

### 2.5. Nguyên tắc dữ liệu

Mỗi kịch bản tự tạo đối tượng có tiền tố `tc-` và dọn khi xong; ca âm không dùng đối tượng của ca dương khác. Dữ liệu định danh cá nhân chỉ giả lập (tên, số định danh sinh ngẫu nhiên có cờ `test`). Ca hiệu năng nạp quy mô GĐ bằng `ph12/seed/perf`.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-12-01 | Danh sách, chi tiết và danh bạ người dùng | Xác nhận tra cứu người dùng theo tenant và tổ chức, không rò rỉ chéo tenant, danh bạ chỉ trả thông tin tối thiểu | UC-12-01, 42 | 6 |
| TS-12-02 | Tạo tài khoản, kích hoạt lần đầu và sửa thông tin | Xác nhận tạo tài khoản qua danh bạ đơn vị, kích hoạt một lần với mật khẩu đạt chuẩn, chuyển đơn vị có kiểm tra | UC-12-02, 03 | 7 |
| TS-12-03 | Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản | Xác nhận máy trạng thái tài khoản, bắt buộc có lý do, cấm tự thao tác, giữ tenant luôn có quản trị | UC-12-04 | 4 |
| TS-12-04 | Đặt lại mật khẩu, tác vụ định kỳ và đồng bộ đơn vị | Xác nhận quên mật khẩu không lộ sự tồn tại của tài khoản, tự vô hiệu sau 45 ngày, đồng bộ thuộc tính từ danh mục đơn vị | UC-12-06, 07 | 5 |
| TS-12-05 | Nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ | Xác nhận nhập hai pha, không nhận mật khẩu qua tệp, ánh xạ vai trò hệ cũ có kiểm soát | UC-12-05 | 4 |
| TS-12-06 | Danh mục vai trò chuẩn và quyền hiệu lực | Xác nhận danh mục vai trò, quyền khớp D02-08, quyền hiệu lực tính đúng ba lớp | UC-12-08 | 3 |
| TS-12-07 | Gán và gỡ vai trò cho người dùng | Xác nhận gán, gỡ vai trò có phạm vi, có hiệu lực đúng hạn, cấm tự gán và gán vai trò nền tảng ở tenant thường | UC-12-09 | 2 |
| TS-12-08 | Tách nhiệm vụ và ngoại lệ có thời hạn | Xác nhận cặp vai trò xung đột bị chặn và ngoại lệ do TA đề nghị, SO duyệt, tối đa 90 ngày | UC-12-10 | 3 |
| TS-12-09 | Nhóm và đơn vị tổ chức | Xác nhận nhóm theo cây, phạm vi kế thừa, cấm vòng lặp, không gán vai trò cho nhóm | UC-12-11 | 2 |
| TS-12-10 | Vai trò tùy biến của tenant (Đợt 2) | Xác nhận tenant mở rộng quyền chỉ bằng dữ liệu vai trò tùy biến giới hạn, có bốn mắt | UC-12-12 | 2 |
| TS-12-11 | Quyền có thời hạn và truy cập liên tenant | Xác nhận quyền cao không thường trực: tối đa 4 giờ, có phiếu, người duyệt thứ hai, thông báo tỉnh bị truy cập | UC-12-13 | 2 |
| TS-12-12 | Rà soát quyền định kỳ | Xác nhận người quản lý rà từng quyền, không tự rà mình, quyền không phản hồi sau 14 ngày bị gỡ | UC-12-14 | 2 |
| TS-12-13 | Chuyển định danh khi sáp nhập tenant | Xác nhận kế hoạch và thực hiện chuyển người dùng, vai trò từ T91 sang T92 không mất vết, không lẫn tenant | UC-12-15 | 2 |
| TS-12-14 | Đăng nhập OIDC Authorization Code với PKCE | Xác nhận đăng nhập đúng chuẩn OAuth 2.1, cấm grant `password` và `implicit`, đăng xuất, discovery, JWKS | UC-12-16 | 4 |
| TS-12-15 | Chống dò mật khẩu và khóa tài khoản | Xác nhận khóa tạm, khóa hẳn, chặn theo địa chỉ, không lộ sự tồn tại tài khoản | UC-12-16 | 2 |
| TS-12-16 | Yếu tố thứ hai và xác thực lại bước lên | Xác nhận TOTP, WebAuthn, bắt buộc theo nhóm, bước lên khi thao tác nhạy cảm do OPA quyết định | UC-12-17 | 2 |
| TS-12-17 | Đặt lại yếu tố thứ hai khi mất thiết bị | Xác nhận chỉ quản trị cao hơn một cấp đặt lại, có xác minh kênh khác, tài khoản quản trị cần SO duyệt | UC-12-18 | 2 |
| TS-12-18 | Đăng nhập một lần SAML 2 và liên kết LDAP, AD | Xác nhận SSO cho ứng dụng cũ bằng SAML 2 và nhập người dùng từ LDAP trong cơ sở tìm kiếm đã duyệt | UC-12-19 | 4 |
| TS-12-19 | Đăng nhập liên tenant và liên kết VNeID | Xác nhận người thuộc nhiều tenant chọn nguồn đăng nhập đúng và VNeID chỉ liên kết, không tự tạo tài khoản | UC-12-13, 19 | 2 |
| TS-12-20 | Quản lý phiên | Xác nhận xem phiên, buộc đăng xuất một người và hạ quyền thu phiên | UC-12-20 | 1 |
| TS-12-21 | Cấp client OAuth và vòng đời client của HTTT | Xác nhận client do PH-01 hoặc PH-15 yêu cầu, một HTTT một client, tạm ngừng, tiếp tục, thu hồi một chiều | UC-12-21, 23 | 4 |
| TS-12-22 | Chứng thư, khóa công khai và xoay bí mật client | Xác nhận đăng ký mTLS, JWKS, xoay bí mật có giai đoạn chuyển tiếp, bí mật chỉ giao một lần | UC-12-24 | 2 |
| TS-12-23 | Token máy, scope và tài khoản dịch vụ | Xác nhận `client_credentials`, scope sinh từ dữ liệu đã duyệt, tài khoản dịch vụ gắn một DU | UC-12-22, 25, 26 | 4 |
| TS-12-24 | Vòng đời token, JWKS và thu hồi truy cập tức thời | Xác nhận refresh token xoay vòng, phát hiện dùng lại, xoay khóa ký 90 ngày, thu hồi ≤ 60 giây | UC-12-27, 28 | 4 |
| TS-12-25 | Realm của tenant: khởi tạo, GitOps, vòng đời | Xác nhận realm khởi tạo ≤ 5 phút từ mẫu, phát hiện lệch cấu hình, tạm ngừng, khôi phục, chỉ đọc | UC-12-29, 30 | 3 |
| TS-12-26 | Quyết định ủy quyền: hợp đồng PEP–PDP và quy tắc gốc | Xác nhận từ chối mặc định, từ chối thắng, cách ly tenant, mặt nạ trường và fail-closed | UC-12-31 | 7 |
| TS-12-27 | Chuyển đổi XACML, quyết định theo lô và bộ đệm | Xác nhận XACML 3.0 JSON, lô tối đa 100, bộ đệm không làm sai quyết định | UC-12-32 | 3 |
| TS-12-28 | Dữ liệu vai trò–quyền, soạn, kiểm thử, chạy khô chính sách | Xác nhận dữ liệu OPA sinh từ ma trận D02-08, soạn Rego, bộ ca kiểm thử và chạy khô trên lưu lượng thật | UC-12-33, 34 | 4 |
| TS-12-29 | Duyệt bốn mắt, phát hành, thu hồi và quay lui chính sách | Xác nhận duyệt người khác người soạn, ca kiểm thử và chạy khô là điều kiện bắt buộc, quay lui về gói cũ | UC-12-35, 36 | 4 |
| TS-12-30 | Ghi vết, nhật ký quyết định, cảnh báo và báo cáo | Xác nhận mọi sự kiện xác thực, quản trị và quyết định quan trọng được ghi vết, tra cứu theo tenant, cảnh báo ≤ 60 giây | UC-12-37, 38, 39, 40 | 4 |
| TS-12-31 | Tham số phân hệ theo tenant | Xác nhận tham số chỉ đổi trong trần nền tảng (nhàn rỗi 5 đến 15 phút, v.v.) | UC-12-41 | 1 |
| TS-12-32 | Hành vi chung của API quản trị | Xác nhận hợp đồng lỗi RFC 9457, `Idempotency-Key`, giới hạn tần suất và phản ứng khi dịch vụ phụ thuộc ngừng | UC-12-02, 21 | 3 |
| TS-12-33 | Không lộ bí mật | Chứng minh mật khẩu, mã TOTP, bí mật client, token đầy đủ không xuất hiện ở bất kỳ đâu ngoài nơi lưu được phép, bằng giá trị mồi `DH-CANARY` | — | 2 |
| TS-12-34 | Cách ly tenant và RLS | Chứng minh tỉnh này không đọc, ghi, thu hồi được định danh, client, chính sách của tỉnh khác ở API, token, CSDL, realm | — | 3 |
| TS-12-35 | Chịu lỗi, độc lập control plane và phục hồi | Chứng minh Keycloak và OPA vẫn phục vụ khi control plane ngừng, sẵn sàng theo SLO, phục hồi `pg-iam` trong RPO, RTO | — | 3 |
| TS-12-36 | Hiệu năng, tải và quy mô | Chứng minh NFR-12-001…009 và 023…025 ở cấu hình `QM-VUA` với dữ liệu GĐ | — | 11 |
| TS-12-37 | Bảo mật ứng dụng, giám sát và truy cập | Chứng minh mật khẩu băm đúng chuẩn, TLS, quét ASVS, chỉ số vận hành, truy cập WCAG 2.2 AA, tương thích hợp đồng | — | 4 |
| **Tổng** | | | | **127** (99 ca P1) |

: Danh sách kịch bản và số ca
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Bảng sau nêu các máy trạng thái mà bộ ca phải đi qua đủ các chuyển hợp lệ và thử các chuyển bị cấm, theo FRS §4.

| Đối tượng | Trạng thái và chuyển |
|---|---|
| Tài khoản | `PENDING_ACTIVATION` → `ACTIVE` ⇄ `LOCKED`; `LOCKED` → `BLOCKED` → `ACTIVE`; `PENDING_ACTIVATION`/`ACTIVE` → `DISABLED` → `ACTIVE`; không xóa vật lý (BR-12-035) |
| Client | `ENABLED` ⇄ `SUSPENDED`; `ENABLED`/`SUSPENDED` → `REVOKED` (một chiều) |
| Phiên bản chính sách | `DRAFT` → `PENDING_REVIEW` → `APPROVED` → `PUBLISHED`; `PENDING_REVIEW` → `CHANGES_REQUESTED` → `DRAFT`; `DRAFT` → `DISCARDED`; `PUBLISHED` → `REVOKED` hoặc `SUPERSEDED` |
| Realm | `PROVISIONING` → `ACTIVE` ⇄ `SUSPENDED`; `ACTIVE` → `READ_ONLY`; `READ_ONLY`/`SUSPENDED` → `DELETED` |
| Quyền có thời hạn | `REQUESTED` → `ACTIVE` → `EXPIRED`/`REVOKED`; `REQUESTED` → `REJECTED`/`CANCELLED` |

: Máy trạng thái được kiểm thử

## 4. Kịch bản và test case chức năng

### TS-12-01 · Danh sách, chi tiết và danh bạ người dùng

**Mục tiêu.** Xác nhận tra cứu người dùng theo tenant và tổ chức, không rò rỉ chéo tenant, danh bạ chỉ trả thông tin tối thiểu.

**Phủ.** FR-12-001, 002, 062; BR-12-037, 041, 042; UC-12-01, 42; UI-12-01, 02; API-12-001, 002, 014; ERR-12-001, 007.

#### TC-12-001 · Danh sách người dùng có lọc, tìm kiếm, phân trang <!--k:usr-list-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-001 · UC-12-01 · UI-12-01 · API-12-001 · NFR-12-008
- **Tiền điều kiện / dữ liệu** U-T68-TA1; 120 người dùng T68 (nạp seed), `ha.nguyen` có ở T01.
- **Bước**
  1. `GET /users?q=ha&trang-thai=ACTIVE&size=20&page=0`.
  2. Mở UI-12-01, lọc `mfa=false`, sắp `sap-xep=ngay-tao:giam`, sang trang 2.
- **Mong đợi** `200`, chỉ người dùng T68, tổng khớp bộ lọc, không có `ha.nguyen` của T01; UI giữ bộ lọc ở URL; p95 ≤ 300 ms.

#### TC-12-002 · Người dùng chỉ đọc không thấy nút thao tác <!--k:usr-list-viewer-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** E2E
- **Truy vết** FR-12-001 · UI-12-01 · API-12-001 · ERR-12-007 · BR-12-014
- **Tiền điều kiện / dữ liệu** U-T68-VW (chỉ `PERM-12-read`).
- **Bước**
  1. Mở UI-12-01.
  2. `POST /users` bằng token của VW.
- **Mong đợi** Danh sách xem được, không có nút "Tạo", "Khóa"; bước 2 trả 403-PQ.

#### TC-12-003 · Chi tiết người dùng đủ tab và quyền hiệu lực <!--k:usr-detail-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-002 · UC-12-01 · UI-12-02 · API-12-002 · LGC-IAM-002
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-IE.
- **Bước**
  1. `GET /users/{userId}` của IE.
  2. Mở UI-12-02, xem các tab Vai trò, Phiên, Yếu tố xác thực, Lịch sử.
- **Mong đợi** `200`, có `ETag`; trường `mfa` cho biết loại yếu tố, không có giá trị bí mật; mỗi tab tải được.

#### TC-12-004 · Chi tiết người dùng của tenant khác hoặc không có <!--k:usr-detail-404-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-002 · API-12-002 · ERR-12-001 · BR-12-041, BR-12-004
- **Tiền điều kiện / dữ liệu** U-T68-TA1; người dùng `tc-chi-t01` chỉ có ở T01.
- **Bước**
  1. `GET /users/khong-co`.
  2. `GET /users/{id-cua-tc-chi-t01}` bằng token T68.
  3. Gửi tiêu đề `X-Tenant: T01`.
- **Mong đợi** Cả ba trả `404` ERR-12-001, thân giống nhau trừ `traceId`; tiêu đề tenant bị bỏ qua.

#### TC-12-005 · Vai trò phạm vi tổ chức chỉ thấy người cùng đơn vị <!--k:usr-org-scope-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-001 · BR-12-037 · API-12-001, API-12-002 · ERR-12-001
- **Tiền điều kiện / dữ liệu** U-T68-PH07 (vai trò quyền ○, đơn vị `DV-A`); một người dùng ở `DV-B`.
- **Bước**
  1. `GET /users` bằng token PH07.
  2. `GET /users/{id-DV-B}`.
- **Mong đợi** Danh sách chỉ người `DV-A` và đơn vị cấp dưới; bước 2 trả 404-ẩn.

#### TC-12-006 · Danh bạ người dùng trả thông tin tối thiểu <!--k:directory-min-->
- **Loại** Dương, Âm, Bảo mật  · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-062 · UC-12-42 · API-12-014 · BR-12-042, BR-12-004 · CMP-LAW-05
- **Tiền điều kiện / dữ liệu** S-PH04 (scope `iam:directory-read`); người dùng có thư, điện thoại.
- **Bước**
  1. `GET /directory/users?q=nguyen` bằng token S-PH04.
  2. Lặp với token người dùng T01 và với token thiếu scope.
- **Mong đợi** Chỉ có `code`, tên hiển thị, đơn vị, chức danh, trạng thái; không có thư, điện thoại, số định danh; chỉ người dùng tenant của token; token thiếu scope bị `403`.

### TS-12-02 · Tạo tài khoản, kích hoạt lần đầu và sửa thông tin

**Mục tiêu.** Xác nhận tạo tài khoản qua danh bạ đơn vị, kích hoạt một lần với mật khẩu đạt chuẩn, chuyển đơn vị có kiểm tra.

**Phủ.** FR-12-003, 004, 006; BR-12-018, 043; UC-12-02, 03; UI-12-03; API-12-003, 004, 009; ERR-12-002, 003, 004, 005, 015, 016, 044.

#### TC-12-007 · Tạo tài khoản và kích hoạt lần đầu <!--k:usr-create-activate-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-003, 006 · UC-12-02 · UI-12-03, UI-12-18 · API-12-003 · LGC-IAM-002 · BR-12-018
- **Tiền điều kiện / dữ liệu** U-T68-TA1; SIM-PH07 `DV-A`; SIM-SMTP.
- **Bước**
  1. `POST /users` với `username=tc-an`, thư `an@dv.t68.test`, `unit=DV-A`, `Idempotency-Key`.
  2. Đọc thư ở SIM-SMTP, mở liên kết, đặt mật khẩu 14 ký tự đạt chuẩn, đăng ký TOTP.
- **Mong đợi** `201`, trạng thái `PENDING_ACTIVATION`; sau bước 2 là `ACTIVE`; liên kết dùng một lần; KT: có (user.create, user.activate); không có mật khẩu trong log.

#### TC-12-008 · Tạo tài khoản trùng tên, thư, hoặc sai lược đồ <!--k:usr-create-invalid-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-003 · API-12-003 · ERR-12-002, ERR-12-003 · BR-12-014
- **Tiền điều kiện / dữ liệu** U-T68-TA1; tài khoản `tc-an` đã có.
- **Bước**
  1. `POST /users` lại cùng `username`.
  2. `POST /users` cùng thư, khác tên.
  3. `POST /users` thiếu `unit`, tên có ký tự cấm.
- **Mong đợi** Bước 1 và 2 `409` ERR-12-002; bước 3 `400` ERR-12-003 kèm danh sách lỗi theo trường.

#### TC-12-009 · Đơn vị hết hiệu lực hoặc thư ngoài miền công vụ <!--k:usr-create-unit-mail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-003 · API-12-003 · ERR-12-004, ERR-12-005
- **Tiền điều kiện / dữ liệu** U-T68-TA1; SIM-PH07 `DV-HET`.
- **Bước**
  1. `POST /users` với `unit=DV-HET`.
  2. `POST /users` với thư `x@gmail.com`.
- **Mong đợi** Bước 1 `422` ERR-12-004; bước 2 `422` ERR-12-005; không tạo bản ghi nào.

#### TC-12-010 · Mật khẩu kích hoạt không đạt chính sách <!--k:activate-weak-pwd-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-12-006 · BR-12-018 · UI-12-18 · ERR-12-015 · SEC-22
- **Tiền điều kiện / dữ liệu** U-T68-NEW, liên kết kích hoạt còn hạn.
- **Bước**
  1. Đặt mật khẩu 13 ký tự, rồi 14 ký tự trùng danh sách đã lộ, rồi chứa tên đăng nhập.
  2. Đặt mật khẩu 14 ký tự đạt chuẩn; sau đó đặt lại bằng mật khẩu trùng 1 trong 5 gần nhất.
- **Mong đợi** Ba mật khẩu đầu bị từ chối với ERR-12-015 và thông báo tiếng Việt nêu quy tắc; mật khẩu 14 ký tự đạt chuẩn được nhận; mật khẩu trùng lịch sử bị từ chối.

#### TC-12-011 · Liên kết kích hoạt hết hạn hoặc đã dùng <!--k:activate-link-expired-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-12-006, FR-12-003 · API-12-009 · ERR-12-016 · UI-12-03
- **Tiền điều kiện / dữ liệu** U-T68-NEW; đồng hồ nhảy qua hạn liên kết.
- **Bước**
  1. Mở liên kết cũ; xác nhận trang báo hết hạn.
  2. TA bấm "Gửi lại" ở UI-12-03 (`POST /users/{id}:resend-activation`).
  3. Dùng liên kết mới hai lần.
- **Mong đợi** Bước 1 ERR-12-016 (410); bước 2 `202`, liên kết cũ vô hiệu; lần dùng thứ hai ERR-12-016.

#### TC-12-012 · Sửa thông tin và chuyển đơn vị <!--k:usr-update-unit-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-004 · UC-12-03 · UI-12-02, 03 · API-12-004 · BR-12-036, BR-12-037
- **Tiền điều kiện / dữ liệu** U-T68-TA1; U-T68-PH07 có vai trò phạm vi `DV-A`.
- **Bước**
  1. `GET` lấy `ETag`; `PATCH /users/{id}` với `If-Match`, đổi `unit=DV-B`.
- **Mong đợi** `200`; vai trò phạm vi `DV-A` bị thu và hiệu lực ở OPA ≤ 60 giây; phiên của người đó bị thu; KT: có (user.update); SK: `user.updated`.

#### TC-12-013 · Sửa với phiên bản cũ hoặc trường do LDAP quản lý <!--k:usr-update-conflict-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-004 · API-12-004 · ERR-12-044 · ERR-12-047 · ERR-12-001
- **Tiền điều kiện / dữ liệu** U-T68-TA1; một người dùng nhập từ SIM-LDAP.
- **Bước**
  1. `PATCH` hai lần với cùng `If-Match` cũ.
  2. `PATCH` tên hiển thị của người dùng LDAP.
- **Mong đợi** Lần hai bước 1 `412` ERR-12-044; bước 2 `422` ERR-12-047.

### TS-12-03 · Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản

**Mục tiêu.** Xác nhận máy trạng thái tài khoản, bắt buộc có lý do, cấm tự thao tác, giữ tenant luôn có quản trị.

**Phủ.** FR-12-005; BR-12-033, 035; UC-12-04; UI-12-02, 03; API-12-005, 006, 007, 008; ERR-12-006, 013, 014, 046.

#### TC-12-014 · Khóa rồi mở khóa tài khoản thu phiên ngay <!--k:usr-lock-unlock-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-005 · UC-12-04 · UI-12-02 · API-12-005, 006 · LGC-IAM-005 · BR-12-036
- **Tiền điều kiện / dữ liệu** U-T68-TA1; U-T68-IE đang có hai phiên.
- **Bước**
  1. `POST /users/{id}:lock` kèm `reason`.
  2. IE gọi API bằng access token cũ.
  3. `POST …:unlock`.
- **Mong đợi** Sau bước 1 trạng thái `LOCKED`, hai phiên bị thu, token cũ bị từ chối ≤ 60 giây; sau bước 3 `ACTIVE`; KT: có (user.lock, user.unlock).

#### TC-12-015 · Vô hiệu và kích hoạt lại, không xóa vật lý <!--k:usr-disable-enable-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, DB
- **Truy vết** FR-12-005 · API-12-007, 008 · BR-12-035 · UI-12-03
- **Tiền điều kiện / dữ liệu** U-T68-TA1; `tc-an` đã `ACTIVE`.
- **Bước**
  1. `POST …:disable`; truy vấn bảng người dùng bằng DB.
  2. `POST …:enable`.
- **Mong đợi** Bản ghi còn nguyên với `DISABLED`; lịch sử truy vết giữ; sau bước 2 `ACTIVE`; không có `DELETE /users`.

#### TC-12-016 · Chuyển trạng thái sai và thiếu lý do <!--k:usr-state-invalid-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-005 · API-12-005, 006, 008 · ERR-12-006 · ERR-12-014
- **Tiền điều kiện / dữ liệu** U-T68-TA1; `tc-an` đang `ACTIVE`.
- **Bước**
  1. `POST …:unlock` khi đang `ACTIVE`.
  2. `POST …:enable` khi đang `ACTIVE`.
  3. `POST …:lock` thiếu `reason`.
- **Mong đợi** Bước 1, 2 `409` ERR-12-006; bước 3 `400` ERR-12-014.

#### TC-12-017 · Không tự khóa, không bỏ TA cuối cùng <!--k:usr-self-last-ta-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-005 · BR-12-033 · API-12-005, 007 · ERR-12-013 · ERR-12-046
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-TA2 (hai TA duy nhất của T68).
- **Bước**
  1. TA1 khóa chính mình.
  2. TA1 vô hiệu TA2 (thành công), rồi TA1 vô hiệu chính mình khi là TA cuối.
  3. Khôi phục TA2 bằng U-PA.
- **Mong đợi** Bước 1 `403` ERR-12-013; lần vô hiệu cuối ở bước 2 `409` ERR-12-046; tenant còn ít nhất một TA.

### TS-12-04 · Đặt lại mật khẩu, tác vụ định kỳ và đồng bộ đơn vị

**Mục tiêu.** Xác nhận quên mật khẩu không lộ sự tồn tại của tài khoản, tự vô hiệu sau 45 ngày, đồng bộ thuộc tính từ danh mục đơn vị.

**Phủ.** FR-12-007, 008, 010; BR-12-017, 020; UC-12-06, 07; UI-12-15, 18; ERR-12-016.

#### TC-12-018 · Quên mật khẩu không phân biệt tài khoản có hay không <!--k:pwd-reset-enum-->
- **Loại** Bảo mật, Âm · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-12-007 · UC-12-06 · UI-12-18 · BR-12-017 · SEC-22 · LGC-IAM-002
- **Tiền điều kiện / dữ liệu** `tc-an` có thật; `khong-co` không có; SIM-SMTP.
- **Bước**
  1. Gửi yêu cầu quên mật khẩu cho cả hai, đo thời gian phản hồi 50 lần.
- **Mong đợi** Thông báo giống hệt; chênh lệch thời gian trung vị < 50 ms; chỉ `tc-an` nhận thư; liên kết hết hạn thì ERR-12-016.

#### TC-12-019 · Đặt lại mật khẩu thu phiên và áp chính sách lịch sử <!--k:pwd-reset-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-12-007 · UI-12-18 · BR-12-018, BR-12-022 · ERR-12-015
- **Tiền điều kiện / dữ liệu** `tc-an` có hai phiên.
- **Bước**
  1. Đặt lại bằng mật khẩu mới đạt chuẩn qua liên kết.
- **Mong đợi** Mọi phiên cũ bị thu; đăng nhập bằng mật khẩu cũ thất bại; KT: có (user.password-reset); không ghi mật khẩu vào log.

#### TC-12-020 · Tự vô hiệu tài khoản không đăng nhập 45 ngày <!--k:auto-disable-45-->
- **Loại** Dương, Âm, Biên  · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-12-008 · UC-12-07 · UI-12-15 · BR-12-020 · BR-12-035 · CMP-LAW-08
- **Tiền điều kiện / dữ liệu** U-T68-OLD (44 ngày), một VW khác 46 ngày, một PA 31 ngày.
- **Bước**
  1. Chạy tác vụ ở ngày 45; chạy lại ở ngày 46.
- **Mong đợi** VW 46 ngày và PA 31 ngày (ngưỡng quản trị 30) thành `DISABLED` không quá 24 giờ sau ngưỡng; U-T68-OLD còn `ACTIVE` ở ngày 44; báo cáo lượt chạy ở UI-12-15; chạy lại không đổi thêm.

#### TC-12-021 · Tạm ngừng client không gọi 90 ngày <!--k:auto-suspend-client-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-12-008 · BR-12-020 · UC-12-07 · API-12-060
- **Tiền điều kiện / dữ liệu** C-T68-B; đồng hồ nhảy 91 ngày không lượt gọi.
- **Bước**
  1. Chạy tác vụ.
- **Mong đợi** C-T68-B `SUSPENDED`, token đang có bị từ chối ≤ 60 giây; thông báo tới đầu mối HTTT; KT: có.

#### TC-12-022 · Đồng bộ thuộc tính người dùng từ danh mục đơn vị <!--k:unit-sync-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-12-010 · UC-12-07 · UI-12-07 · ADR-055
- **Tiền điều kiện / dữ liệu** SIM-PH07; U-T68-PH07 ở `DV-A`.
- **Bước**
  1. Đổi tên `DV-A` và đóng `DV-B` ở SIM-PH07; chạy tác vụ đồng bộ.
  2. Cho SIM-PH07 lỗi `503`; chạy lại.
- **Mong đợi** Tên đơn vị cập nhật, người dùng ở đơn vị đóng được đánh dấu cần chuyển đơn vị; bước 2 giữ nguyên dữ liệu cũ, ghi cảnh báo, không xóa gì.

### TS-12-05 · Nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ

**Mục tiêu.** Xác nhận nhập hai pha, không nhận mật khẩu qua tệp, ánh xạ vai trò hệ cũ có kiểm soát.

**Phủ.** FR-12-009; BR-12-043; UC-12-05; UI-12-04; API-12-010, 011, 012; ERR-12-035, 036.

#### TC-12-023 · Nhập tệp hợp lệ qua hai pha <!--k:import-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-009 · UC-12-05 · UI-12-04 · API-12-010, 011, 012 · BR-12-043 · LGC-IAM-002
- **Tiền điều kiện / dữ liệu** U-T68-TA1; F-USR-OK.
- **Bước**
  1. Tải tệp ở bước 1 UI-12-04; xem kết quả kiểm tra.
  2. `POST /user-imports/{id}:commit`.
- **Mong đợi** Sau kiểm tra chưa có tài khoản nào; sau commit 20 tài khoản `PENDING_ACTIVATION` và thư kích hoạt gửi đi; KT: có (user.import).

#### TC-12-024 · Tệp có dòng lỗi: báo từng dòng, chỉ nhập dòng đạt <!--k:import-bad-rows-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-009 · API-12-011, 012 · BR-12-043 · ERR-12-002, ERR-12-004, ERR-12-005
- **Tiền điều kiện / dữ liệu** F-USR-BAD.
- **Bước**
  1. Tải tệp; đọc kết quả; commit.
- **Mong đợi** Ba dòng lỗi có số dòng và mã lỗi (trùng tên, đơn vị hết hiệu lực, thư ngoài miền); commit chỉ tạo 17 tài khoản (hoặc từ chối nếu tham số "tất cả hoặc không" bật).

#### TC-12-025 · Tệp có cột mật khẩu, quá lớn, sai định dạng <!--k:import-reject-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-009 · API-12-010 · BR-12-043 · ERR-12-035 · BR-12-045
- **Tiền điều kiện / dữ liệu** F-USR-PWD, F-USR-BIG, tệp `.exe` đổi đuôi `.csv`.
- **Bước**
  1. Tải lần lượt ba tệp.
- **Mong đợi** F-USR-PWD bị từ chối vì có mật khẩu; F-USR-BIG `413`; tệp sai định dạng `400` ERR-12-035; giá trị mật khẩu trong tệp không xuất hiện ở log.

#### TC-12-026 · Vai trò hệ cũ chưa có ánh xạ <!--k:import-legacy-role-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-009 · API-12-011 · ERR-12-036 · LGC-IAM-002 · BR-12-029
- **Tiền điều kiện / dữ liệu** F-USR-LGC (2 vai trò lạ).
- **Bước**
  1. Tải tệp; xem kết quả; bổ sung ánh xạ ở bước 3 của UI-12-04; tải lại.
- **Mong đợi** Lần đầu ERR-12-036 nêu vai trò chưa ánh xạ; sau khi ánh xạ, vai trò hệ cũ được đề xuất, không tự gán vai trò đặc quyền.

### TS-12-06 · Danh mục vai trò chuẩn và quyền hiệu lực

**Mục tiêu.** Xác nhận danh mục vai trò, quyền khớp D02-08, quyền hiệu lực tính đúng ba lớp.

**Phủ.** FR-12-011, 016, 046; UC-12-08; UI-12-05, 02; API-12-013, 019, 020, 021; ERR-12-001.

#### TC-12-027 · Danh mục vai trò, quyền khớp ma trận D02-08 <!--k:role-catalog-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-011 · UC-12-08 · UI-12-05 · API-12-019, 020, 021 · LGC-IAM-002
- **Tiền điều kiện / dữ liệu** U-T68-AU; ma trận D02-08 dạng máy đọc.
- **Bước**
  1. `GET /roles`, `GET /roles/TENANT_ADMIN`, `GET /permissions`.
  2. Đối chiếu tự động với ma trận D02-08.
- **Mong đợi** Đủ 22 vai trò chuẩn, tập quyền từng vai trò trùng ma trận (ký hiệu ●/○/—); vai trò `PLATFORM_*` không hiện ở tenant thường.

#### TC-12-028 · Quyền hiệu lực của người dùng <!--k:effective-perms-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-016, 046 · UC-12-08 · UI-12-02 · API-12-013 · BR-12-037
- **Tiền điều kiện / dữ liệu** U-T68-PH07 (vai trò + phạm vi `DV-A`), một quyền có thời hạn còn hiệu lực.
- **Bước**
  1. `GET /users/{id}/effective-permissions`.
- **Mong đợi** Danh sách quyền kèm nguồn (vai trò, nhóm, quyền có thời hạn), phạm vi `DV-A`, hạn của quyền tạm; khớp quyết định của `/decide` cho 10 quyền mẫu.

#### TC-12-029 · Quyền hiệu lực của người dùng tenant khác <!--k:effective-perms-404-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-016 · API-12-013 · ERR-12-001 · BR-12-041
- **Tiền điều kiện / dữ liệu** U-T68-TA1; người dùng của T01.
- **Bước**
  1. `GET /users/{id-T01}/effective-permissions`.
- **Mong đợi** 404-ẩn.

### TS-12-07 · Gán và gỡ vai trò cho người dùng

**Mục tiêu.** Xác nhận gán, gỡ vai trò có phạm vi, có hiệu lực đúng hạn, cấm tự gán và gán vai trò nền tảng ở tenant thường.

**Phủ.** FR-12-012; BR-12-031, 033, 036, 037; UC-12-09; UI-12-02, 06; API-12-025, 026, 027; ERR-12-010, 013.

#### TC-12-030 · Gán vai trò rồi gỡ, hiệu lực ≤ 60 giây <!--k:role-assign-revoke-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-012 · UC-12-09 · UI-12-06 · API-12-025, 026, 027 · BR-12-036 · LGC-IAM-002, LGC-BUS-032
- **Tiền điều kiện / dữ liệu** U-T68-TA1; U-T68-VW.
- **Bước**
  1. `POST /role-assignments` gán `INTEGRATION_ENGINEER` cho VW; xác nhận quyền ghi dùng được sau khi có token mới.
  2. `DELETE /role-assignments/{id}`.
- **Mong đợi** Bước 1 `201`, nâng quyền có hiệu lực khi có token mới; bước 2 `204`, phiên bị thu, OPA từ chối ≤ 60 giây; KT: có (role.assign, role.revoke); SK: `role.changed`.

#### TC-12-031 · Không tự gán vai trò, không gán vai trò nền tảng <!--k:role-self-platform-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-012 · BR-12-033, BR-12-031 · API-12-026 · ERR-12-013 · ERR-12-010
- **Tiền điều kiện / dữ liệu** U-T68-TA1.
- **Bước**
  1. TA1 gán `TENANT_ADMIN` cho chính mình; rồi gỡ vai trò của chính mình.
  2. TA1 gán `PLATFORM_ADMIN` cho VW ở T68.
  3. Gán vai trò phạm vi `DV-B` cho người thuộc `DV-A` không cấp dưới.
- **Mong đợi** Bước 1 `403` ERR-12-013; bước 2, 3 `422` ERR-12-010; không có thay đổi.

### TS-12-08 · Tách nhiệm vụ và ngoại lệ có thời hạn

**Mục tiêu.** Xác nhận cặp vai trò xung đột bị chặn và ngoại lệ do TA đề nghị, SO duyệt, tối đa 90 ngày.

**Phủ.** FR-12-013; BR-12-030, 008; UC-12-10; UI-12-06, 17; API-12-028, 029, 030, 031; ERR-12-008, 009, 014.

#### TC-12-032 · Gán cặp vai trò xung đột bị chặn <!--k:sod-block-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-013 · UC-12-10 · API-12-026, 028 · ERR-12-009 · BR-12-030 · UI-12-06
- **Tiền điều kiện / dữ liệu** U-T68-IE đang có `INTEGRATION_ENGINEER`; U-T68-TA1.
- **Bước**
  1. `GET /sod-rules` lấy cặp IE–IA.
  2. Gán `INTEGRATION_APPROVER` cho IE.
- **Mong đợi** Bước 2 `409` ERR-12-009, thân nêu cặp xung đột; UI-12-06 hiện cảnh báo và lối đề nghị ngoại lệ.

#### TC-12-033 · Ngoại lệ tách nhiệm vụ: đề nghị, duyệt, tự hết hạn <!--k:sod-exception-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-013 · UC-12-10 · UI-12-17 · API-12-029, 030, 031 · BR-12-030 · SEC-27
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-SO, U-T68-IE; đồng hồ điều khiển được.
- **Bước**
  1. TA1 `POST /sod-exceptions` có lý do, hạn 30 ngày.
  2. SO `:decide` chấp thuận; gán vai trò xung đột thành công.
  3. Nhảy 31 ngày; xem gán vai trò.
- **Mong đợi** Sau bước 2 gán được; bước 3 vai trò xung đột tự gỡ; KT: có; thu hồi tay bằng `:revoke` cũng gỡ.

#### TC-12-034 · Ngoại lệ vi phạm bốn mắt, vượt hạn hoặc thiếu lý do <!--k:sod-exception-invalid-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-013 · BR-12-030, BR-12-033 · API-12-029, 030 · ERR-12-008 · ERR-12-014
- **Tiền điều kiện / dữ liệu** U-T68-TA1 vừa là người đề nghị; cặp vai trò "cấm tuyệt đối" ở D02-08 §4.
- **Bước**
  1. TA1 tự `:decide` ngoại lệ mình đề nghị.
  2. Đề nghị thiếu lý do; đề nghị hạn 120 ngày.
  3. Đề nghị ngoại lệ cho cặp cấm tuyệt đối.
- **Mong đợi** Bước 1 `403` ERR-12-008; bước 2 `400` ERR-12-014 (thiếu lý do) và `422` (vượt 90 ngày); bước 3 bị từ chối.

### TS-12-09 · Nhóm và đơn vị tổ chức

**Mục tiêu.** Xác nhận nhóm theo cây, phạm vi kế thừa, cấm vòng lặp, không gán vai trò cho nhóm.

**Phủ.** FR-12-014; BR-12-039; UC-12-11; UI-12-07; API-12-032, 033, 034, 035; ERR-12-011, 012.

#### TC-12-035 · Tạo cây nhóm và đặt thành viên <!--k:group-tree-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-014 · UC-12-11 · UI-12-07 · API-12-032, 033, 034, 035 · LGC-BUS-032 · BR-12-039
- **Tiền điều kiện / dữ liệu** U-T68-TA1; nhóm `phong-cntt` có ở cả T68 và T01.
- **Bước**
  1. Tạo `so-a` → `phong-a1`; `PUT /groups/{id}/members` 3 người.
  2. `GET /groups` ở T68 và T01.
- **Mong đợi** Cây đúng, phạm vi kế thừa xuống nhóm con; mỗi tenant chỉ thấy `phong-cntt` của mình; KT: có (group.create, group.members).

#### TC-12-036 · Vòng lặp nhóm và nhóm đang được dùng <!--k:group-cycle-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-014 · BR-12-039 · API-12-034 · ERR-12-012 · ERR-12-011
- **Tiền điều kiện / dữ liệu** Cây `so-a` → `phong-a1`; một vai trò phạm vi gắn `phong-a1`.
- **Bước**
  1. `PATCH` đặt cha của `so-a` là `phong-a1`.
  2. Gỡ nhóm `phong-a1` khi còn được dùng.
- **Mong đợi** Bước 1 `422` ERR-12-012; bước 2 `409` ERR-12-011.

### TS-12-10 · Vai trò tùy biến của tenant (Đợt 2)

**Mục tiêu.** Xác nhận tenant mở rộng quyền chỉ bằng dữ liệu vai trò tùy biến giới hạn, có bốn mắt.

**Phủ.** FR-12-015; BR-12-007, 008; UC-12-12; UI-12-05; API-12-022, 023, 024; ERR-12-008, 010, 011.

#### TC-12-037 · Tạo, sửa, ngừng dùng vai trò tùy biến <!--k:custom-role-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-015 · UC-12-12 · UI-12-05 · API-12-022, 023, 024 · BR-12-008
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-SO.
- **Bước**
  1. `POST /roles` gói 3 quyền đọc; SO duyệt.
  2. `PATCH`; sau đó `:retire` khi chưa có ai dùng.
- **Mong đợi** Vai trò chỉ gán được sau khi duyệt; ngừng dùng khi không còn gán; KT: có.

#### TC-12-038 · Vai trò tùy biến vượt trần quyền, tự duyệt, đang được dùng <!--k:custom-role-invalid-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-015 · BR-12-007, BR-12-008 · API-12-022, 024 · ERR-12-008, ERR-12-010, ERR-12-011
- **Tiền điều kiện / dữ liệu** U-T68-TA1; vai trò tùy biến đã gán cho một người.
- **Bước**
  1. Tạo vai trò chứa quyền `PERM-12-user-admin` ngoài trần của tenant.
  2. Người soạn tự duyệt.
  3. `:retire` vai trò đang được gán.
- **Mong đợi** Bước 1 `422` ERR-12-010; bước 2 `403` ERR-12-008; bước 3 `409` ERR-12-011.

### TS-12-11 · Quyền có thời hạn và truy cập liên tenant

**Mục tiêu.** Xác nhận quyền cao không thường trực: tối đa 4 giờ, có phiếu, người duyệt thứ hai, thông báo tỉnh bị truy cập.

**Phủ.** FR-12-017, 027; BR-12-031, 032; UC-12-13; UI-12-08, 17; API-12-036, 037, 038, 039, 040; ERR-12-008, 030.

#### TC-12-039 · Xin, duyệt, dùng và tự hết quyền vào tenant khác <!--k:grant-lifecycle-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-017 · UC-12-13 · UI-12-08, 17 · API-12-036, 037, 038, 040 · BR-12-032 · SEC-28
- **Tiền điều kiện / dữ liệu** U-PO xin vào T68 4 giờ, phiếu `HT-1001`; U-T68-SO duyệt.
- **Bước**
  1. U-PO `POST /privileged-grants`; SO `:approve`.
  2. U-PO truy cập API của T68; sau 4 giờ (đồng hồ nhảy) thử lại.
  3. Lần khác, SO `:revoke` giữa chừng.
- **Mong đợi** Bước 2 dùng được rồi bị từ chối khi hết hạn; thu hồi có hiệu lực ≤ 60 giây; thông báo tới TA T68; KT: có (grant.request, approve, expire, revoke).

#### TC-12-040 · Quyền thời hạn vượt 4 giờ, thiếu phiếu, tự duyệt, bị từ chối <!--k:grant-invalid-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-017 · BR-12-032, BR-12-031, BR-12-033 · API-12-036, 038, 039 · ERR-12-030 · ERR-12-008
- **Tiền điều kiện / dữ liệu** U-PO, U-PA.
- **Bước**
  1. Xin 5 giờ; xin không có mã phiếu.
  2. U-PO tự `:approve` yêu cầu của mình.
  3. SO `:reject` một yêu cầu rồi thử dùng.
- **Mong đợi** Bước 1 `422` ERR-12-030; bước 2 `403` ERR-12-008; bước 3 không có quyền nào được cấp.

### TS-12-12 · Rà soát quyền định kỳ

**Mục tiêu.** Xác nhận người quản lý rà từng quyền, không tự rà mình, quyền không phản hồi sau 14 ngày bị gỡ.

**Phủ.** FR-12-018; BR-12-044; UC-12-14; UI-12-09, 17; API-12-041, 042, 043, 044; ERR-12-013, 031.

#### TC-12-041 · Chiến dịch rà soát: mở, quyết định, đóng, hết hạn 14 ngày <!--k:recert-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-12-018 · UC-12-14 · UI-12-09 · API-12-041, 042, 043, 044 · BR-12-044
- **Tiền điều kiện / dữ liệu** U-T68-SO mở chiến dịch; U-T68-MGR rà 5 quyền.
- **Bước**
  1. MGR giữ 3, gỡ 1 và bỏ qua 1; SO `:close`.
  2. Chiến dịch khác: không phản hồi, nhảy 15 ngày.
- **Mong đợi** Quyền "gỡ" có hiệu lực ≤ 60 giây; quyền không phản hồi bị gỡ (vai trò đặc quyền) ở lần 2; KT: có.

#### TC-12-042 · Tự rà quyền của mình và mở chiến dịch trùng <!--k:recert-invalid-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-018 · BR-12-044, BR-12-033 · API-12-041, 043 · ERR-12-013 · ERR-12-031
- **Tiền điều kiện / dữ liệu** Chiến dịch đang mở; MGR có quyền trong danh sách rà.
- **Bước**
  1. MGR quyết định quyền của chính mình.
  2. `POST /recertification-campaigns` khi đã có chiến dịch mở; quyết định trên chiến dịch đã đóng.
- **Mong đợi** Bước 1 `403` ERR-12-013; bước 2 `409` ERR-12-031.

### TS-12-13 · Chuyển định danh khi sáp nhập tenant

**Mục tiêu.** Xác nhận kế hoạch và thực hiện chuyển người dùng, vai trò từ T91 sang T92 không mất vết, không lẫn tenant.

**Phủ.** FR-12-019; UC-12-15; UI-12-19; API-12-045, 046; ERR-12-040, 041.

#### TC-12-043 · Lập kế hoạch và thực hiện chuyển định danh <!--k:merge-identity-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-019 · UC-12-15 · UI-12-19 · API-12-045, 046 · SEC-80
- **Tiền điều kiện / dữ liệu** S-PH20; T91 (12 người dùng, 3 client) và T92; một tên đăng nhập trùng.
- **Bước**
  1. `:plan` rồi đọc xung đột; `:execute`.
- **Mong đợi** Kế hoạch nêu tên trùng cần đổi mã; sau thực hiện người dùng ở T92 với vai trò ánh xạ, vết kiểm toán giữ `tenant_id` cũ ở bản ghi lịch sử; client chuyển, realm T91 chuyển `READ_ONLY`.

#### TC-12-044 · Chuyển định danh khi tenant không ở trạng thái cho phép <!--k:merge-identity-state-->
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-12-019 · API-12-046 · ERR-12-041 · ERR-12-040
- **Tiền điều kiện / dữ liệu** T92 `SUSPENDED`; hoặc PH-20 không sẵn sàng.
- **Bước**
  1. `:execute` khi T92 tạm ngừng; lặp khi dịch vụ phụ thuộc tắt.
- **Mong đợi** `409` ERR-12-041; khi phụ thuộc tắt `503` ERR-12-040; không có thay đổi nửa chừng.

### TS-12-14 · Đăng nhập OIDC Authorization Code với PKCE

**Mục tiêu.** Xác nhận đăng nhập đúng chuẩn OAuth 2.1, cấm grant `password` và `implicit`, đăng xuất, discovery, JWKS.

**Phủ.** FR-12-020; BR-12-021, 022; UC-12-16; UI-12-18; API-12-072, 073, 074, 075, 076, 077, 078; ERR-12-111, 114, 116, 121, 122.

#### TC-12-045 · Đăng nhập PKCE, userinfo, đăng xuất <!--k:oidc-login-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-12-020 · UC-12-16 · UI-12-18 · API-12-072, 073, 074, 075, 076, 078 · LGC-IAM-001 · NFR-12-007
- **Tiền điều kiện / dữ liệu** U-T68-TA1 (WebAuthn ảo); client `dh-console` ở realm `dh-t68`.
- **Bước**
  1. `GET …/openid-configuration`; chạy luồng auth với `code_challenge` S256.
  2. Đổi code lấy token; gọi `userinfo`; `logout`.
- **Mong đợi** Có `access_token` ≤ 5 phút, `refresh_token`, claim `tenant` đúng; sau logout token dùng được tới hết hạn nhưng phiên bị đóng và refresh bị từ chối; p95 đăng nhập ≤ 2 giây; SK: `auth.login`.

#### TC-12-046 · PKCE sai, grant bị cấm, token sai đối tượng <!--k:oidc-reject-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-020 · BR-12-021 · API-12-073, 074, 077 · ERR-12-114, ERR-12-122, ERR-12-116 · LGC-IAM-006
- **Tiền điều kiện / dữ liệu** C-T68-B; U-T68-VW.
- **Bước**
  1. Đổi code với `code_verifier` sai; dùng lại `code`; `redirect_uri` lạ.
  2. `grant_type=password`; `response_type=token`.
  3. Dùng token hết hạn, token của realm T01 ở API T68.
- **Mong đợi** Bước 1 ERR-12-114; bước 2 ERR-12-122 (`unsupported_grant_type`); bước 3 ERR-12-116 (401); không có đường lấy token bằng mật khẩu.

#### TC-12-047 · Realm của tenant tạm ngừng không cấp token <!--k:oidc-suspended-realm-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-020, FR-12-043 · API-12-073, 074 · ERR-12-121
- **Tiền điều kiện / dữ liệu** T90 realm `SUSPENDED`; một người dùng T90.
- **Bước**
  1. Đăng nhập và `client_credentials` ở T90.
- **Mong đợi** `403` ERR-12-121; T68 không bị ảnh hưởng.

#### TC-12-048 · Phiên nhàn rỗi, tối đa và hạn mức đồng thời <!--k:session-limits-->
- **Loại** Dương, Âm, Biên  · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-12-020, FR-12-029 · BR-12-022 · UI-12-18 · SEC-29 · API-12-016
- **Tiền điều kiện / dữ liệu** U-T68-VW (3 phiên), U-T68-TA1 (quản trị, 1 phiên); đồng hồ điều khiển được.
- **Bước**
  1. Mở phiên thứ 4 của VW; phiên thứ 2 của TA1.
  2. Để nhàn rỗi 15 phút; để dùng liên tục 10 giờ.
- **Mong đợi** Phiên cũ nhất bị đóng khi vượt hạn mức (quản trị chỉ 1 phiên); nhàn rỗi 15 phút bị khóa phiên; quá 10 giờ buộc đăng nhập lại.

### TS-12-15 · Chống dò mật khẩu và khóa tài khoản

**Mục tiêu.** Xác nhận khóa tạm, khóa hẳn, chặn theo địa chỉ, không lộ sự tồn tại tài khoản.

**Phủ.** FR-12-021; BR-12-017, 019; NFR-12-021; UC-12-16; UI-12-18; ERR-12-111, 112, 113, 125.

#### TC-12-049 · 5 lần sai khóa tạm 15 phút, 3 lần khóa tạm thì khóa hẳn <!--k:bruteforce-lock-->
- **Loại** Dương, Âm, Biên, Bảo mật  · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-12-021 · UC-12-16 · UI-12-18 · BR-12-019 · ERR-12-111, 112, 113 · NFR-00-025
- **Tiền điều kiện / dữ liệu** U-T68-VW; U-T68-TA1 để mở khóa; đồng hồ điều khiển được.
- **Bước**
  1. Đăng nhập sai 4 lần, rồi lần 5; thử đúng mật khẩu ngay sau đó.
  2. Hết 15 phút, lặp để có 3 lần khóa tạm trong 24 giờ.
  3. TA mở khóa hẳn.
- **Mong đợi** Lần 1–4 ERR-12-111; lần 5 và đúng mật khẩu ngay sau đó ERR-12-112 (423); sau lần khóa thứ 3 ERR-12-113 (403), chỉ TA hoặc SO mở được; KT: có.

#### TC-12-050 · Tên không tồn tại cho phản hồi giống tên có thật, chặn theo địa chỉ <!--k:bruteforce-enum-ip-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API, k6
- **Truy vết** FR-12-021 · BR-12-017 · NFR-12-021 · ERR-12-111, ERR-12-125 · SEC-22
- **Tiền điều kiện / dữ liệu** Một địa chỉ thử; 1.000 cặp tên và mật khẩu sai.
- **Bước**
  1. Đăng nhập sai tên có thật và tên không có, so thân và thời gian.
  2. Bắn 1.000 lần từ một địa chỉ.
- **Mong đợi** Thân và thời gian giống nhau; bị chặn `429` ERR-12-125 sau ≤ 20 lần; cảnh báo tới SO ≤ 60 giây.

### TS-12-16 · Yếu tố thứ hai và xác thực lại bước lên

**Mục tiêu.** Xác nhận TOTP, WebAuthn, bắt buộc theo nhóm, bước lên khi thao tác nhạy cảm do OPA quyết định.

**Phủ.** FR-12-022, 023; BR-12-015, 016; UC-12-17; UI-12-18; API-12-073, 074; ERR-12-120, ERR-12-111.

#### TC-12-051 · Đăng ký TOTP và WebAuthn, quản trị chỉ nhận WebAuthn <!--k:mfa-enroll-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-12-022 · UC-12-17 · UI-12-18, UI-12-02 · BR-12-015 · LGC-IAM-003 · SEC-23
- **Tiền điều kiện / dữ liệu** U-T68-NEW (nhóm `mfa-required`); U-T68-TA1 mới.
- **Bước**
  1. Người thường đăng ký TOTP; nhập mã sai, rồi đúng.
  2. TA1 thử đăng ký TOTP; sau đó đăng ký WebAuthn ảo.
- **Mong đợi** TOTP đúng mới kích hoạt; mã sai ERR-12-111; quản trị bị từ chối TOTP, chỉ WebAuthn được nhận; UI-12-02 hiện loại yếu tố, không hiện bí mật.

#### TC-12-052 · Bước lên khi lần xác thực cuối quá 5 phút <!--k:stepup-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-12-023 · UC-12-17 · UI-12-18 · API-12-073, 074 · BR-12-016 · ERR-12-120
- **Tiền điều kiện / dữ liệu** U-T68-TA1 đăng nhập 6 phút trước; thao tác `:revoke-access`.
- **Bước**
  1. Gọi thao tác nhạy cảm bằng token cũ.
  2. Xác thực lại bằng WebAuthn; gọi lại.
- **Mong đợi** Bước 1 `401` ERR-12-120 (`insufficient_user_authentication`); bước 2 thành công; mức yêu cầu lấy từ OPA, đổi chính sách thì đổi mức mà không sửa mã.

### TS-12-17 · Đặt lại yếu tố thứ hai khi mất thiết bị

**Mục tiêu.** Xác nhận chỉ quản trị cao hơn một cấp đặt lại, có xác minh kênh khác, tài khoản quản trị cần SO duyệt.

**Phủ.** FR-12-024; BR-12-033, 034; UC-12-18; UI-12-02, 17; API-12-015; ERR-12-013, 014, 017.

#### TC-12-053 · Đặt lại yếu tố thứ hai đúng quy trình <!--k:mfa-reset-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, Thủ công
- **Truy vết** FR-12-024 · UC-12-18 · UI-12-02, 17 · API-12-015 · BR-12-034 · LGC-IAM-003
- **Tiền điều kiện / dữ liệu** U-T68-VW mất thiết bị; U-T68-TA1; TA2 là người cần đặt lại (quản trị) và U-T68-SO duyệt.
- **Bước**
  1. TA1 `:reset-mfa` cho VW kèm mã xác minh qua điện thoại.
  2. PA đặt lại cho TA2, SO duyệt.
- **Mong đợi** Phiên của người bị đặt lại bị thu; lần đăng nhập kế buộc đăng ký lại; KT: có (user.reset-mfa).

#### TC-12-054 · Đặt lại sai cấp, thiếu xác minh, tự đặt lại <!--k:mfa-reset-invalid-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-024 · BR-12-033, BR-12-034 · API-12-015 · ERR-12-017 · ERR-12-014 · ERR-12-013
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-TA2, U-T68-VW.
- **Bước**
  1. TA1 đặt lại cho TA2 (cùng cấp).
  2. TA1 đặt lại cho VW không có thông tin xác minh.
  3. TA1 đặt lại cho chính mình.
- **Mong đợi** Bước 1 `403` ERR-12-017; bước 2 `400` ERR-12-014; bước 3 `403` ERR-12-013.

### TS-12-18 · Đăng nhập một lần SAML 2 và liên kết LDAP, AD

**Mục tiêu.** Xác nhận SSO cho ứng dụng cũ bằng SAML 2 và nhập người dùng từ LDAP trong cơ sở tìm kiếm đã duyệt.

**Phủ.** FR-12-025, 026; BR-12-029; UC-12-19; UI-12-11; API-12-047, 048, 049, 050, 051, 052, 053; ERR-12-032, 033, 047.

#### TC-12-055 · Đăng ký ứng dụng SAML và đăng nhập một lần <!--k:saml-sso-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-025 · UC-12-19 · UI-12-11 · API-12-051, 052, 053 · LGC-IAM-001, LGC-IAM-008 · SEC-20
- **Tiền điều kiện / dữ liệu** U-T68-TA1; SIM-SAML-SP.
- **Bước**
  1. `POST /saml-clients` với metadata hợp lệ; `PATCH` đổi URL ACS.
  2. Người dùng mở SIM-SAML-SP và đăng nhập bằng Keycloak.
- **Mong đợi** Assertion có chữ ký, `NameID` và thuộc tính đúng, đích khớp ACS; `GET /saml-clients` thấy ứng dụng.

#### TC-12-056 · Cấu hình SAML sai <!--k:saml-invalid-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-025 · API-12-052 · ERR-12-033
- **Tiền điều kiện / dữ liệu** U-T68-TA1; metadata thiếu chứng thư; ACS không HTTPS.
- **Bước**
  1. `POST /saml-clients` hai lần với hai cấu hình sai.
- **Mong đợi** `422` ERR-12-033 kèm lý do từng trường.

#### TC-12-057 · Liên kết LDAP: khai báo, kiểm tra, đồng bộ <!--k:ldap-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-026 · UC-12-19 · UI-12-11 · API-12-047, 048, 049, 050 · LGC-IAM-004 · BR-12-029
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-SO duyệt; SIM-LDAP.
- **Bước**
  1. `PUT /ldap-federations/ldap-t68` với cơ sở tìm kiếm `ou=cntt`; `:test`.
  2. SO duyệt; `:sync`; xem báo cáo.
- **Mong đợi** Chỉ người dùng thuộc cơ sở đã duyệt được nhập, không tự gán vai trò đặc quyền; người trùng thư không tạo bản trùng mà được báo cáo; mật khẩu bind ở OpenBao.

#### TC-12-058 · LDAP kiểm tra hỏng, trường chỉ đọc <!--k:ldap-invalid-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-026 · API-12-048, 049 · ERR-12-032 · ERR-12-047
- **Tiền điều kiện / dữ liệu** SIM-LDAP tắt hoặc sai mật khẩu bind.
- **Bước**
  1. `:test` liên kết sai; `PUT` với cơ sở tìm kiếm ngoài phạm vi.
  2. Sửa trường do LDAP quản lý trên tài khoản đã đồng bộ.
- **Mong đợi** `422` ERR-12-032 nêu nguyên nhân, không kèm mật khẩu; bước 2 `422` ERR-12-047.

### TS-12-19 · Đăng nhập liên tenant và liên kết VNeID

**Mục tiêu.** Xác nhận người thuộc nhiều tenant chọn nguồn đăng nhập đúng và VNeID chỉ liên kết, không tự tạo tài khoản.

**Phủ.** FR-12-027, 028; BR-12-029, 031; UC-12-13, 19; UI-12-11, 18; API-12-054, 055; ERR-12-034.

#### TC-12-059 · Người dùng hai tenant chọn tenant khi đăng nhập <!--k:multi-tenant-login-->
- **Loại** Dương, Âm, Bảo mật  · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-12-027 · UC-12-13 · UI-12-18 · API-12-073, 074 · BR-12-031 · SEC-80
- **Tiền điều kiện / dữ liệu** U-MULTI; U-PO.
- **Bước**
  1. U-MULTI chọn T68 rồi chọn T01.
  2. Dùng token T68 gọi API T01.
  3. U-PO thử chọn tenant T68 khi chưa có quyền có thời hạn.
- **Mong đợi** Mỗi token mang đúng một `tenant`; bước 2 trả 404-ẩn; bước 3 bị từ chối.

#### TC-12-060 · Liên kết, gỡ VNeID, trùng số định danh <!--k:vneid-link-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-12-028 · UI-12-11 · API-12-054, 055 · ERR-12-034 · BR-12-029 · CMP-LAW-10
- **Tiền điều kiện / dữ liệu** SIM-VNEID; hai người dùng T68; loại bỏ mạng xã hội theo LGC-IAM-007.
- **Bước**
  1. Người dùng A xác nhận liên kết VNeID; người dùng B liên kết cùng số định danh.
  2. A gỡ liên kết; thử đăng nhập bằng VNeID khi chưa có tài khoản.
  3. Tìm nút đăng nhập Google, Facebook ở UI-12-18.
- **Mong đợi** Bước 1 B nhận `409` ERR-12-034; bước 2 không tự tạo tài khoản; bước 3 không có nút mạng xã hội (LGC-IAM-007 bị loại); số định danh không ở log.

### TS-12-20 · Quản lý phiên

**Mục tiêu.** Xác nhận xem phiên, buộc đăng xuất một người và hạ quyền thu phiên.

**Phủ.** FR-12-029; BR-12-022, 036; UC-12-20; UI-12-02; API-12-016, 017.

#### TC-12-061 · Xem phiên và buộc đăng xuất mọi phiên <!--k:session-signout-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-029 · UC-12-20 · UI-12-02 · API-12-016, 017 · LGC-IAM-005 · BR-12-036
- **Tiền điều kiện / dữ liệu** U-T68-TA1; U-T68-IE hai phiên; U-T01-TA.
- **Bước**
  1. `GET /users/{id}/sessions`; `POST …:sign-out`.
  2. U-T01-TA gọi cùng đường dẫn với `userId` của IE.
- **Mong đợi** Bước 1 liệt kê đủ hai phiên (địa chỉ, thiết bị, lần cuối); sau buộc đăng xuất mọi token bị từ chối ≤ 60 giây; bước 2 trả 404-ẩn; KT: có.

### TS-12-21 · Cấp client OAuth và vòng đời client của HTTT

**Mục tiêu.** Xác nhận client do PH-01 hoặc PH-15 yêu cầu, một HTTT một client, tạm ngừng, tiếp tục, thu hồi một chiều.

**Phủ.** FR-12-030, 031, 032; BR-12-024; UC-12-21, 23; UI-12-10; API-12-056, 057, 058, 059, 060, 061, 062, 063; ERR-12-018, 020, 022.

#### TC-12-062 · Cấp client cho HTTT, xem danh sách và chi tiết <!--k:client-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-030 · UC-12-21 · UI-12-10 · API-12-056, 057, 058 · LGC-APIM-020 · BR-12-023, BR-12-024
- **Tiền điều kiện / dữ liệu** U-T68-TA1; HTTT `HT-A` mức Hạn chế `ACTIVE` ở PH-01.
- **Bước**
  1. `POST /clients` kèm hợp đồng, chứng thư mTLS; đọc `GET /clients`, `GET /clients/{id}`.
- **Mong đợi** `201`, `clientId` theo tenant; không có bí mật trong thân; KT: có (client.create); SK: `client.created`.

#### TC-12-063 · HTTT đã có client; phương thức không đạt mức hợp đồng <!--k:client-create-invalid-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-030 · BR-12-024 · API-12-058 · ERR-12-018 · ERR-12-022
- **Tiền điều kiện / dữ liệu** `HT-A` đã có client; `HT-N` mức Nhạy cảm.
- **Bước**
  1. `POST /clients` lần hai cho `HT-A`.
  2. `POST /clients` cho `HT-N` bằng `client_secret`; cho mức Hạn chế bằng `client_secret`.
- **Mong đợi** Bước 1 `409` ERR-12-018; bước 2 `422` ERR-12-022.

#### TC-12-064 · Sửa, tạm ngừng, tiếp tục, thu hồi client <!--k:client-lifecycle-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-031 · UC-12-23 · UI-12-10 · API-12-059, 060, 061, 062 · ERR-12-020 · BR-12-028
- **Tiền điều kiện / dữ liệu** C-T68-B có token hiệu lực; U-T68-SO.
- **Bước**
  1. `:suspend`; gọi bằng token cũ; `:resume`.
  2. `:revoke` kèm lý do; `:resume` và `PATCH` sau thu hồi.
- **Mong đợi** Tạm ngừng chặn token ≤ 60 giây; tiếp tục dùng lại được; thu hồi là một chiều, các thao tác sau trả `409` ERR-12-020.

#### TC-12-065 · Cấp client cho ứng dụng nhà phát triển ở sandbox <!--k:client-dev-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-032 · UC-12-21 · UI-12-10 · API-12-063 · LGC-IAM-006 · BR-12-024
- **Tiền điều kiện / dữ liệu** Yêu cầu từ PH-15; tenant sandbox.
- **Bước**
  1. `POST /dev-clients`; dùng C-DEV lấy token ở sandbox rồi ở T68 chính.
- **Mong đợi** Token sandbox dùng được ở sandbox, bị từ chối ở T68; scope chỉ dữ liệu giả lập.

### TS-12-22 · Chứng thư, khóa công khai và xoay bí mật client

**Mục tiêu.** Xác nhận đăng ký mTLS, JWKS, xoay bí mật có giai đoạn chuyển tiếp, bí mật chỉ giao một lần.

**Phủ.** FR-12-033, 034; BR-12-023, 024; UC-12-24; UI-12-10; API-12-064, 065, 066; ERR-12-021, 023, 039.

#### TC-12-066 · Đăng ký chứng thư và JWKS hợp lệ, không hợp lệ <!--k:cred-cert-jwks-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-033 · UC-12-24 · UI-12-10 · API-12-064, 065 · ERR-12-021 · BR-12-024 · LGC-BUS-041
- **Tiền điều kiện / dữ liệu** C-T68-A; F-CERT-OK, F-CERT-BAD.
- **Bước**
  1. `PUT …/credentials/certificate` bằng F-CERT-OK rồi F-CERT-BAD (hết hạn).
  2. `PUT …/credentials/jwks` hợp lệ rồi chứa khóa riêng.
- **Mong đợi** Hợp lệ `200`; F-CERT-BAD và JWKS có khóa riêng bị `422` ERR-12-021; KT: có.

#### TC-12-067 · Xoay bí mật: giao một lần, chuyển tiếp, không lộ <!--k:cred-secret-rotate-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-034 · UC-12-24 · UI-12-10 · API-12-066 · BR-12-023 · ERR-12-023 · ERR-12-039 · NFR-12-020
- **Tiền điều kiện / dữ liệu** C-T68-B; mồi `DH-CANARY-rot`; OpenBao.
- **Bước**
  1. `:rotate` lấy liên kết bọc dùng một lần; mở hai lần.
  2. Trong thời gian chuyển tiếp gọi lại `:rotate`; dùng cả bí mật cũ và mới.
  3. Tắt OpenBao; gọi `:rotate`.
- **Mong đợi** Lần mở thứ hai thất bại; bước 2 `409` ERR-12-023, cả hai bí mật dùng được trong chuyển tiếp rồi bí mật cũ hết hiệu lực; bước 3 `503` ERR-12-039; bí mật không có trong phản hồi API, log, CSDL (mồi sạch).

### TS-12-23 · Token máy, scope và tài khoản dịch vụ

**Mục tiêu.** Xác nhận `client_credentials`, scope sinh từ dữ liệu đã duyệt, tài khoản dịch vụ gắn một DU.

**Phủ.** FR-12-035, 036, 037; BR-12-014, 021, 024, 025, 026; UC-12-22, 25, 26; UI-12-10; API-12-067, 068, 069, 070, 071, 074; ERR-12-019, 117, 118, 119.

#### TC-12-068 · Lấy token bằng client_credentials, TTL 5 phút, không refresh <!--k:cc-token-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-035 · UC-12-25 · API-12-074 · BR-12-026 · LGC-IAM-006 · NFR-12-006 · SEC-24
- **Tiền điều kiện / dữ liệu** C-T68-A (mTLS), C-T68-B (secret, mức Công khai).
- **Bước**
  1. Lấy token bằng mTLS và bằng `client_secret`; giải mã token.
- **Mong đợi** `expires_in` ≤ 300, không có `refresh_token`, claim `tenant`, `scope` đúng phần giao; SK: `auth.token-issued`.

#### TC-12-069 · Xác thực client sai, bị tạm ngừng, scope rỗng, grant bị cấm <!--k:cc-token-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-035 · API-12-074 · ERR-12-117, 118, 119 · BR-12-021, BR-12-024
- **Tiền điều kiện / dữ liệu** C-T68-A; một client tạm ngừng; một client chưa có scope.
- **Bước**
  1. Bí mật sai; chứng thư của client khác; client tạm ngừng; client scope rỗng.
  2. `client_credentials` của C-T68-N bằng bí mật.
- **Mong đợi** ERR-12-117 (401), ERR-12-118 (403), ERR-12-119 (400); bước 2 bị từ chối vì mức Nhạy cảm bắt buộc mTLS.

#### TC-12-070 · Scope chỉ sinh từ nguồn đã duyệt <!--k:scope-source-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-036 · UC-12-22 · UI-12-10 · API-12-067, 068 · BR-12-025 · ERR-12-019
- **Tiền điều kiện / dữ liệu** Giả lập PH-02, PH-07 duyệt scope `catalog:read`; U-T68-TA1.
- **Bước**
  1. Nguồn PH-07 ghi scope `catalog:read`; `GET /clients/{id}/scopes`.
  2. TA `PUT …/scopes` thêm scope `payment:approve` không có nguồn; thêm scope loại của nguồn khác.
- **Mong đợi** Bước 1 scope xuất hiện, token chỉ mang phần giao với hợp đồng; bước 2 `422` ERR-12-019; không có đường ghi tay.

#### TC-12-071 · Tài khoản dịch vụ nội bộ của đơn vị triển khai <!--k:service-account-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-037 · UC-12-26 · UI-12-10 · API-12-069, 070, 071 · BR-12-014 · ERR-12-010
- **Tiền điều kiện / dữ liệu** U-PA, U-PA2 (SO duyệt).
- **Bước**
  1. `POST /service-accounts` cho DU `dh-runtime`; `:rotate`.
  2. Tạo tài khoản dịch vụ "dùng chung" không gắn DU.
- **Mong đợi** Bước 1 thành công, thông tin xác thực giao một lần; bước 2 `422` ERR-12-010; danh sách thấy đúng một chủ DU mỗi tài khoản.

### TS-12-24 · Vòng đời token, JWKS và thu hồi truy cập tức thời

**Mục tiêu.** Xác nhận refresh token xoay vòng, phát hiện dùng lại, xoay khóa ký 90 ngày, thu hồi ≤ 60 giây.

**Phủ.** FR-12-038, 039, 040; BR-12-026, 027, 028; NFR-12-005; UC-12-27, 28; UI-12-02, 10, 19; API-12-018, 075, 077, 079; ERR-12-013, 014, 115, 116.

#### TC-12-072 · Refresh xoay vòng, dùng lại thì thu cả họ token <!--k:refresh-reuse-->
- **Loại** Dương, Âm, Bảo mật  · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-038 · UC-12-16 · API-12-074, 077 · BR-12-026 · ERR-12-115 · SEC-29 · LGC-IAM-005
- **Tiền điều kiện / dữ liệu** U-T68-VW đã đăng nhập, `RT1`.
- **Bước**
  1. Đổi `RT1` lấy `RT2`; dùng lại `RT1`.
  2. Dùng `RT2`.
- **Mong đợi** Dùng lại `RT1` ERR-12-115; `RT2` cũng vô hiệu (thu cả họ); cảnh báo `refresh-reuse` tới SO ≤ 60 giây.

#### TC-12-073 · Xoay khóa ký 90 ngày không gián đoạn <!--k:jwks-rotate-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-12-039 · UC-12-27 · UI-12-19 · API-12-075 · BR-12-027 · NFR-12-018 · SEC-25
- **Tiền điều kiện / dữ liệu** Realm `dh-t68`; token ký bằng khóa cũ; đồng hồ nhảy 90 ngày.
- **Bước**
  1. Chạy xoay; `GET …/certs`; xác minh token cũ và token mới.
  2. Sau 1 ngày xem JWKS; thử xoay khẩn một người.
- **Mong đợi** JWKS có cả khóa cũ và mới, token cũ vẫn xác minh được; sau 1 ngày khóa cũ rút; xoay khẩn cần người duyệt thứ hai (từ chối nếu thiếu); không có khóa riêng trong log.

#### TC-12-074 · Thu hồi truy cập tức thời ≤ 60 giây tại cổng <!--k:revoke-access-60s-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-040 · UC-12-28 · UI-12-02 · API-12-018, 079 · BR-12-028 · NFR-12-005 · ERR-12-116 · LGC-IAM-005
- **Tiền điều kiện / dữ liệu** U-T68-IE gọi API mỗi giây; U-T68-SO; APISIX 3 bản sao.
- **Bước**
  1. SO `POST /users/{id}:revoke-access` kèm lý do (đã bước lên).
  2. Gọi đến khi bị từ chối; `GET /revocations`.
- **Mong đợi** Từ chối ở mọi bản sao ≤ 60 giây (ERR-12-116); mục thu hồi xuất hiện ở danh sách chặn; KT: có.

#### TC-12-075 · Thu hồi thiếu lý do, tự thu hồi mình <!--k:revoke-access-invalid-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-040 · BR-12-028, BR-12-033 · API-12-018 · ERR-12-014 · ERR-12-013
- **Tiền điều kiện / dữ liệu** U-T68-SO.
- **Bước**
  1. `:revoke-access` thiếu `reason`.
  2. SO thu hồi chính mình.
- **Mong đợi** Bước 1 `400` ERR-12-014; bước 2 `403` ERR-12-013.

### TS-12-25 · Realm của tenant: khởi tạo, GitOps, vòng đời

**Mục tiêu.** Xác nhận realm khởi tạo ≤ 5 phút từ mẫu, phát hiện lệch cấu hình, tạm ngừng, khôi phục, chỉ đọc.

**Phủ.** FR-12-041, 042, 043; BR-12-038; NFR-12-010, 017; UC-12-29, 30; UI-12-19; API-12-080, 081, 082, 083, 084, 085; ERR-12-041, 042.

#### TC-12-076 · Khởi tạo realm T90 từ mẫu <!--k:realm-create-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-041 · UC-12-29 · UI-12-19 · API-12-080, 081 · ERR-12-041 · NFR-12-010 · LGC-IAM-002 · SEC-20
- **Tiền điều kiện / dữ liệu** S-PH20; tenant T90 chưa có realm.
- **Bước**
  1. `POST /realms` cho T90; theo dõi đến `ACTIVE`; gọi lại lần hai cùng khóa.
  2. `POST /realms` cho tenant đã có realm hoặc tenant `SUSPENDED`.
- **Mong đợi** `ACTIVE` ≤ 5 phút; có vai trò chuẩn, client `dh-console`, chính sách mật khẩu `argon2id` hoặc `pbkdf2-sha512` ≥ 210.000 vòng; lần hai không tạo bản sao; bước 2 `409` ERR-12-041.

#### TC-12-077 · Phát hiện lệch cấu hình và áp lại, TA không sửa được cấu hình bảo mật <!--k:realm-drift-->
- **Loại** Dương, Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-042 · UC-12-29 · UI-12-19 · API-12-082, 083 · BR-12-038 · ERR-12-042 · THR-38
- **Tiền điều kiện / dữ liệu** Realm T90; sửa tay `password-min-length=8` bằng quản trị Keycloak; U-T68-TA1.
- **Bước**
  1. `GET …/drift`; `:reconcile`; gọi `:reconcile` thứ hai khi đang chạy.
  2. TA tìm quyền `manage-realm`, `manage-clients` trong Keycloak.
- **Mong đợi** Drift báo trường lệch; sau áp lại giá trị về mẫu; lần gọi chồng `409` ERR-12-042; TA không có ba quyền quản trị Keycloak.

#### TC-12-078 · Tạm ngừng, khôi phục, chỉ đọc; thao tác sai trạng thái <!--k:realm-lifecycle-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-043 · UC-12-30 · UI-12-19 · API-12-084, 085 · ERR-12-041 · ERR-12-121
- **Tiền điều kiện / dữ liệu** S-PH20; realm T90 `ACTIVE`.
- **Bước**
  1. `:suspend`; đăng nhập người dùng T90; `:resume`.
  2. `:resume` khi đang `ACTIVE`; `:suspend` realm đang `PROVISIONING`.
- **Mong đợi** Bước 1 đăng nhập bị từ chối ERR-12-121, sau khôi phục dùng lại được, dữ liệu nguyên vẹn; bước 2 `409` ERR-12-041.

### TS-12-26 · Quyết định ủy quyền: hợp đồng PEP–PDP và quy tắc gốc

**Mục tiêu.** Xác nhận từ chối mặc định, từ chối thắng, cách ly tenant, mặt nạ trường và fail-closed.

**Phủ.** FR-12-044, 045, 046, 047; BR-12-001, 002, 003, 004, 005, 006, 012, 013, 040; NFR-12-001, 002, 014; UC-12-31; API-12-086; ERR-12-101, 102, 103, 104, 124.

#### TC-12-079 · Quyết định cho phép theo vai trò, phạm vi và thuộc tính <!--k:decide-allow-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-12-044, 046 · UC-12-31 · API-12-086 · BR-12-037 · LGC-BUS-041 · NFR-12-002
- **Tiền điều kiện / dữ liệu** S-PEP; U-T68-IE, U-T68-PH07; bộ 30 yêu cầu mẫu.
- **Bước**
  1. `POST /api/authz/v1/decide` cho 30 bộ (chủ thể, hành động, tài nguyên, bối cảnh), trong đó 10 bộ vượt vai trò hoặc phạm vi tổ chức.
- **Mong đợi** `200`, kết quả khớp bảng đúng (10 bộ vượt quyền `deny`); có `obligations`, `fieldMask`, `decisionId`; p95 ≤ 10 ms.

#### TC-12-080 · Không có luật cho phép thì từ chối; quên viết chính sách không lộ dữ liệu <!--k:decide-default-deny-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** UT, API
- **Truy vết** FR-12-045 · BR-12-001 · API-12-086 · ADR-006 · SEC-26
- **Tiền điều kiện / dữ liệu** Hành động mới `x.moi` chưa có luật nào.
- **Bước**
  1. Gọi `decide` cho `x.moi` với PA.
- **Mong đợi** `deny` kèm lý do `no-matching-allow`; kể cả PA không có quyền ngầm.

#### TC-12-081 · Từ chối thắng cho phép, chính sách tenant không gỡ được luật gốc <!--k:decide-deny-wins-->
- **Loại** Âm, Bảo mật  · **Ưu tiên** P1 · **Tự động** UT, IT
- **Truy vết** FR-12-045 · BR-12-002, BR-12-005 · API-12-086 · ADR-006
- **Tiền điều kiện / dữ liệu** POL-GOC; POL-T68-OK có luật `deny` bổ sung; dữ liệu nhãn bí mật nhà nước.
- **Bước**
  1. Yêu cầu có đồng thời luật cho phép và luật `deny` của gói gốc.
  2. Yêu cầu truy cập dữ liệu nhãn bí mật nhà nước bằng PA.
- **Mong đợi** Cả hai `deny`; luật `deny` của gói gốc không bị gói tenant vô hiệu; không có luật cho phép nào cho nhãn bí mật nhà nước.

#### TC-12-082 · Cách ly tenant ở quyết định, ngoại lệ chỉ bằng quyền thời hạn <!--k:decide-tenant-iso-->
- **Loại** Dương, Bảo mật  · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-12-045 · BR-12-003, BR-12-004, BR-12-031 · API-12-086 · SEC-80, SEC-85 · NFR-12-014
- **Tiền điều kiện / dữ liệu** U-T68-TA1; tài nguyên của T01; quyền có thời hạn còn hiệu lực của U-PO.
- **Bước**
  1. TA T68 hỏi quyền với tài nguyên T01.
  2. Gửi `tenant` trong thân khác với token.
  3. U-PO có quyền có thời hạn hỏi cùng tài nguyên; sau khi hết hạn hỏi lại.
- **Mong đợi** Bước 1, 2 `deny`; `tenant` lấy từ token đã xác minh, không từ thân; bước 3 `allow` trong hạn rồi `deny`.

#### TC-12-083 · Mặt nạ trường và chế độ bảo vệ theo mục đích <!--k:decide-fieldmask-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-047 · BR-12-040, BR-12-012 · API-12-086 · CMP-LAW-05 · SEC-31
- **Tiền điều kiện / dữ liệu** Thực thể `hoso` có tập trường khai báo; thực thể `moi` chưa khai báo.
- **Bước**
  1. Hỏi quyền đọc `hoso` với mục đích khác nhau.
  2. Hỏi quyền đọc `moi`.
- **Mong đợi** `fieldMask` đổi theo mục đích; `moi` có `fieldMask` rỗng kèm cảnh báo cấu hình; tài nguyên Nhạy cảm không đệm.

#### TC-12-084 · Yêu cầu thiếu trường, thiếu scope `iam:decide` <!--k:decide-bad-request-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-044 · API-12-086 · ERR-12-101 · ERR-12-102
- **Tiền điều kiện / dữ liệu** S-PEP; token không có scope.
- **Bước**
  1. Gọi thiếu `resource`; gọi bằng token thiếu scope; gọi không token.
- **Mong đợi** `400` ERR-12-101; hai trường hợp sau `401` ERR-12-102.

#### TC-12-085 · Fail-closed: OPA lỗi, quá 50 ms, chưa nạp gói <!--k:decide-fail-closed-->
- **Loại** Bảo mật, Chaos · **Ưu tiên** P1 · **Tự động** Chaos, IT
- **Truy vết** FR-12-044 · BR-12-006, BR-12-013 · NFR-12-014 · API-12-086 · ERR-12-103, ERR-12-104, ERR-12-124 · SEC-26
- **Tiền điều kiện / dữ liệu** SIM-OPA-DOWN; 1.000 yêu cầu hợp lệ; tài nguyên Nhạy cảm; Kafka ghi vết tắt.
- **Bước**
  1. Tắt OPA, bắn 1.000 yêu cầu; làm OPA chậm > 50 ms; khởi động pod chưa nạp gói.
  2. Tắt đường ghi vết, truy cập tài nguyên Nhạy cảm.
- **Mong đợi** 100 % bị từ chối (0 lọt) và ERR-12-103 (500) hoặc ERR-12-104 (503) được bên gọi xử lý như từ chối; bước 2 ERR-12-124 (403): không có vết thì không được truy cập.

### TS-12-27 · Chuyển đổi XACML, quyết định theo lô và bộ đệm

**Mục tiêu.** Xác nhận XACML 3.0 JSON, lô tối đa 100, bộ đệm không làm sai quyết định.

**Phủ.** FR-12-048, 049, 050; BR-12-012; NFR-12-009; UC-12-32; API-12-087, 088; ERR-12-101, 123.

#### TC-12-086 · XACML hợp lệ và sai lược đồ <!--k:xacml-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-048 · UC-12-32 · API-12-088 · ERR-12-123 · CMP-LAW-09
- **Tiền điều kiện / dữ liệu** HTTT thẩm định cũ gọi XACML; thân hợp lệ và thân sai.
- **Bước**
  1. `POST /api/authz/v1/xacml` với thân hợp lệ, rồi thân sai lược đồ.
- **Mong đợi** Kết quả `Permit` hoặc `Deny` khớp `decide` cùng dữ liệu; thân sai `400` ERR-12-123 với `Indeterminate`, bên gọi xử lý như từ chối.

#### TC-12-087 · Quyết định theo lô 100 và vượt 100 <!--k:decide-batch-->
- **Loại** Dương, Biên · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-12-049 · UC-12-32 · API-12-087 · ERR-12-101
- **Tiền điều kiện / dữ liệu** S-PEP; 100 và 101 yêu cầu.
- **Bước**
  1. `POST …/decide:batch` với 100 rồi 101 yêu cầu.
- **Mong đợi** 100 yêu cầu trả đủ 100 kết quả cùng thứ tự; 101 `400` ERR-12-101.

#### TC-12-088 · Bộ đệm: mất hiệu lực khi đổi gói, không đệm mức Nhạy cảm <!--k:decide-cache-->
- **Loại** Dương, Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-12-050 · BR-12-012 · NFR-12-009 · UC-12-32
- **Tiền điều kiện / dữ liệu** PEP có bộ đệm; tài nguyên thường và Nhạy cảm.
- **Bước**
  1. Hỏi hai lần; đổi gói chính sách (đổi `bundleRevision`); hỏi lại.
  2. Hỏi hai lần tài nguyên Nhạy cảm và tài nguyên có nghĩa vụ `STEPUP`.
- **Mong đợi** Lần hai trúng đệm; sau đổi gói không dùng kết quả cũ; mức Nhạy cảm không đệm; trúng đệm ≥ 60 % sau 1 giờ (PERF).

### TS-12-28 · Dữ liệu vai trò–quyền, soạn, kiểm thử, chạy khô chính sách

**Mục tiêu.** Xác nhận dữ liệu OPA sinh từ ma trận D02-08, soạn Rego, bộ ca kiểm thử và chạy khô trên lưu lượng thật.

**Phủ.** FR-12-051, 052, 053; BR-12-007, 009, 010, 011; UC-12-33, 34; UI-12-12, 13; API-12-089, 090, 091, 092, 093, 094, 095, 101, 102; ERR-12-024, 028.

#### TC-12-089 · Sinh lại dữ liệu vai trò–quyền cho OPA <!--k:policy-data-regen-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-051 · UC-12-33 · UI-12-12 · API-12-101, 102 · ADR-068 · BR-12-010
- **Tiền điều kiện / dữ liệu** U-PA; ma trận D02-08 đổi một ô.
- **Bước**
  1. `POST /policy-data:regenerate`; `GET /policy-bundles`.
  2. Đo từ lúc duyệt đến mọi OPA nạp.
- **Mong đợi** Gói mới có chữ ký, `bundleRevision` tăng; mọi OPA nạp ≤ 60 giây; OPA từ chối gói không chữ ký.

#### TC-12-090 · Soạn chính sách, tạo phiên bản, chạy bộ ca kiểm thử <!--k:policy-author-test-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-052 · UC-12-34 · UI-12-12 · API-12-089, 090, 091, 092, 093, 094 · BR-12-009
- **Tiền điều kiện / dữ liệu** U-T68-SO; POL-T68-OK; bộ ca có 1 dương, 1 âm.
- **Bước**
  1. `POST /policies`; `POST …/versions`; `GET` danh sách, chi tiết, phiên bản.
  2. `:test`.
- **Mong đợi** Phiên bản `DRAFT`, `contentHash` cố định; kết quả test có độ phủ; KT: có (policy.create).

#### TC-12-091 · Chính sách sai cú pháp hoặc có luật cho phép của tenant <!--k:policy-invalid-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-12-052 · BR-12-007 · API-12-091, 092, 094 · ERR-12-024 · ERR-12-028 · SEC-26
- **Tiền điều kiện / dữ liệu** U-T68-SO; POL-T68-ALLOW; một Rego sai cú pháp.
- **Bước**
  1. Tạo phiên bản với Rego sai cú pháp.
  2. Tạo phiên bản POL-T68-ALLOW (có `allow` hoặc nới quyền).
- **Mong đợi** Bước 1 `422` ERR-12-024 kèm dòng lỗi; bước 2 `422` ERR-12-028; không phiên bản nào chuyển được đi tiếp.

#### TC-12-092 · Chạy khô trên lưu lượng thật, báo cáo thay đổi quyết định <!--k:policy-dryrun-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-053 · UC-12-34 · UI-12-13 · API-12-095 · BR-12-011 · BR-12-009
- **Tiền điều kiện / dữ liệu** Phiên bản đạt test; 10.000 quyết định mẫu từ nhật ký.
- **Bước**
  1. `:dry-run`; xem số quyết định đổi và các trường hợp từ chối chuyển sang cho phép.
  2. `:dry-run` phiên bản `DRAFT` chưa đạt kiểm thử.
- **Mong đợi** Báo cáo gắn đúng `contentHash`; đổi quá 20 % hoặc có từ chối→cho phép thì đánh dấu cần xác nhận bổ sung; bước 2 `409` ERR-12-025.

### TS-12-29 · Duyệt bốn mắt, phát hành, thu hồi và quay lui chính sách

**Mục tiêu.** Xác nhận duyệt người khác người soạn, ca kiểm thử và chạy khô là điều kiện bắt buộc, quay lui về gói cũ.

**Phủ.** FR-12-054, 055; BR-12-008, 009, 010, 011; UC-12-35, 36; UI-12-12, 13, 17; API-12-096, 097, 098, 099, 100, 101; ERR-12-008, 025, 026, 027, 029.

#### TC-12-093 · Gửi duyệt, duyệt và phát hành gói ký <!--k:policy-approve-publish-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-12-054 · UC-12-35 · UI-12-13, 17 · API-12-096, 097, 101 · BR-12-008, BR-12-010 · ADR-069
- **Tiền điều kiện / dữ liệu** Soạn bởi U-T68-SO; người duyệt U-T68-SO2.
- **Bước**
  1. `:submit`; SO2 `:approve`; xem `GET /policy-bundles`.
- **Mong đợi** `PUBLISHED`, gói ký mới, hiệu lực ≤ 60 giây; KT: có (policy.approve); SK: `policy.published`.

#### TC-12-094 · Tự duyệt, người đóng góp duyệt, thiếu test hoặc chạy khô <!--k:policy-approve-invalid-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-054 · BR-12-008, BR-12-009 · API-12-097, 098 · ERR-12-008 · ERR-12-025 · ERR-12-026
- **Tiền điều kiện / dữ liệu** Người soạn, một người sửa thêm, phiên bản chưa đủ ca âm, phiên bản chưa chạy khô đúng hash.
- **Bước**
  1. Người soạn tự `:approve`; người đóng góp `:approve`.
  2. Duyệt phiên bản thiếu ca âm; duyệt phiên bản sửa sau khi chạy khô.
- **Mong đợi** Bước 1 `403` ERR-12-008; ca thiếu `409` ERR-12-025; chưa chạy khô đúng nội dung `409` ERR-12-026.

#### TC-12-095 · Chạy khô đổi quá 20 % cần xác nhận bổ sung; trạng thái sai <!--k:policy-approve-confirm-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-054 · BR-12-011 · UI-12-13 · API-12-097, 098 · ERR-12-029 · ERR-12-027
- **Tiền điều kiện / dữ liệu** Phiên bản chạy khô đổi 25 %; một phiên bản đã `PUBLISHED`.
- **Bước**
  1. `:approve` không có xác nhận bổ sung; rồi có xác nhận kèm ý kiến.
  2. `:approve` phiên bản đã `PUBLISHED`; `:reject` phiên bản `DRAFT`.
- **Mong đợi** Bước 1 lần đầu `409` ERR-12-029, lần hai thành công; bước 2 `409` ERR-12-027.

#### TC-12-096 · Thu hồi phiên bản và quay lui về gói đã chạy <!--k:policy-revoke-rollback-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-055 · UC-12-36 · UI-12-12 · API-12-099, 100, 101 · BR-12-010 · ERR-12-027
- **Tiền điều kiện / dữ liệu** Hai phiên bản đã phát hành liên tiếp; U-T68-SO, U-PA.
- **Bước**
  1. `:revoke` phiên bản mới nhất kèm lý do.
  2. `POST /policy-bundles:rollback` về gói trước; thử quay lui về gói chưa từng chạy.
- **Mong đợi** Hiệu lực ≤ 60 giây; quay lui về gói chưa từng chạy bị từ chối; quyết định sau quay lui khớp gói cũ; KT: có.

### TS-12-30 · Ghi vết, nhật ký quyết định, cảnh báo và báo cáo

**Mục tiêu.** Xác nhận mọi sự kiện xác thực, quản trị và quyết định quan trọng được ghi vết, tra cứu theo tenant, cảnh báo ≤ 60 giây.

**Phủ.** FR-12-056, 057, 058, 059, 060; BR-12-013, 045; NFR-12-026, 027, 028, 029, 030; UC-12-37, 38, 39, 40; UI-12-14, 15; API-12-103, 104, 105, 106, 107, 108, 109; ERR-12-001.

#### TC-12-097 · Ghi vết sự kiện xác thực và quản trị <!--k:audit-auth-admin-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-12-056 · UC-12-37 · UI-12-15 · API-12-105 · FR-00-041 · NFR-12-027 · SEC-61
- **Tiền điều kiện / dữ liệu** U-T68-AU; đăng nhập đúng, sai, đổi vai trò, thu hồi.
- **Bước**
  1. Thực hiện 10 sự kiện; `GET /security-events?loai=...`.
- **Mong đợi** Đủ sự kiện, mỗi dòng có `trace_id`, `tenant_id`, chủ thể, kết quả, không có mật khẩu, mã TOTP, token (BR-12-045); sự kiện tới PH-13.

#### TC-12-098 · Ghi vết quyết định: từ chối, mức Nhạy cảm, lấy mẫu <!--k:audit-decisions-->
- **Loại** Dương, Âm  · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-12-057, 058 · UC-12-37, 38 · UI-12-14 · API-12-103, 104 · NFR-12-029, 030 · BR-12-013 · CMP-LAW-05
- **Tiền điều kiện / dữ liệu** 1.000 quyết định hỗn hợp; U-T68-AU; AU của T01.
- **Bước**
  1. Chạy 1.000 quyết định; so số bản ghi với bộ đếm `iam_decisions_total`.
  2. `GET /decisions?ket-qua=deny`; `GET /decisions/{id}`; AU T01 gọi id của T68.
- **Mong đợi** 100 % từ chối và mức Hạn chế, Nhạy cảm có vết; cho phép mức thấp lấy mẫu ~10 %; sai lệch tới bộ đếm ≤ ngưỡng; AU T01 nhận 404-ẩn ERR-12-001; cấu hình lưu giữ đúng NFR-12-030 (log xác thực 12 tháng, kiểm toán 12 tháng và WORM 5 năm).

#### TC-12-099 · Phát hiện bất thường và xác nhận cảnh báo <!--k:anomaly-alert-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, IT
- **Truy vết** FR-12-059 · UC-12-39 · UI-12-15 · API-12-106, 107 · NFR-12-028 · SEC-64
- **Tiền điều kiện / dữ liệu** U-T68-SO; hành vi giả lập: đăng nhập từ hai quốc gia trong 5 phút, 30 lần bị từ chối liên tiếp.
- **Bước**
  1. Chạy hành vi giả lập; `GET /alerts`; `POST /alerts/{id}:acknowledge`.
- **Mong đợi** Cảnh báo tới SO ≤ 60 giây; xác nhận ghi người xác nhận và thời điểm; KT: có.

#### TC-12-100 · Báo cáo tình trạng tài khoản và phủ xác thực hai yếu tố <!--k:reports-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-12-060 · UC-12-40 · UI-12-15 · API-12-108, 109 · CMP-LAW-08 · BR-12-015
- **Tiền điều kiện / dữ liệu** U-T68-AU; 120 người dùng trong đó 20 thiếu yếu tố thứ hai.
- **Bước**
  1. `GET /reports/accounts`; `GET /reports/mfa-coverage`.
- **Mong đợi** Số tài khoản theo trạng thái, số quá 45 ngày, tỷ lệ phủ yếu tố thứ hai khớp dữ liệu nạp; chỉ dữ liệu T68.

### TS-12-31 · Tham số phân hệ theo tenant

**Mục tiêu.** Xác nhận tham số chỉ đổi trong trần nền tảng (nhàn rỗi 5 đến 15 phút, v.v.).

**Phủ.** FR-12-061; BR-12-022; UC-12-41; UI-12-16; API-12-110, 111; ERR-12-043.

#### TC-12-101 · Đọc và sửa tham số trong trần, vượt trần <!--k:settings-->
- **Loại** Dương, Âm, Biên · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-12-061 · UC-12-41 · UI-12-16 · API-12-110, 111 · BR-12-022 · ERR-12-043 · ERR-12-044
- **Tiền điều kiện / dữ liệu** U-T68-TA1; tham số `idleMinutes` = 15.
- **Bước**
  1. `GET /settings`; `PUT /settings` đặt `idleMinutes=10`, rồi 4, rồi 16.
  2. `PUT` với `If-Match` cũ.
- **Mong đợi** 10 được nhận và áp cho phiên mới; 4 và 16 `422` ERR-12-043; `If-Match` cũ `412` ERR-12-044; KT: có.

### TS-12-32 · Hành vi chung của API quản trị

**Mục tiêu.** Xác nhận hợp đồng lỗi RFC 9457, `Idempotency-Key`, giới hạn tần suất và phản ứng khi dịch vụ phụ thuộc ngừng.

**Phủ.** FR-12-001, 003, 030; NFR-12-032; UC-12-02, 21; API-12-003, 058, 066; ERR-12-007, 037, 038, 039, 040, 043, 044, 045.

#### TC-12-102 · Idempotency-Key và hợp đồng lỗi RFC 9457 <!--k:api-idempotency-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-12-003 · UC-12-02 · API-12-003, 058 · ERR-12-045 · ERR-12-007 · NFR-12-032
- **Tiền điều kiện / dữ liệu** U-T68-TA1, U-T68-VW.
- **Bước**
  1. `POST /users` hai lần cùng `Idempotency-Key` cùng thân; rồi cùng khóa khác thân.
  2. Gọi thao tác thiếu quyền; kiểm thân lỗi.
- **Mong đợi** Lần hai cùng thân trả lại kết quả cũ, không tạo thêm; khác thân `422` ERR-12-045; lỗi có `type`, `title`, `status`, `code`, `traceId` (RFC 9457) và ERR-12-007 cho thiếu quyền.

#### TC-12-103 · Giới hạn tần suất thao tác quản trị <!--k:api-rate-limit-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** k6
- **Truy vết** FR-12-003 · API-12-003 · ERR-12-037 · ERR-12-043
- **Tiền điều kiện / dữ liệu** U-T68-TA1; vượt ngưỡng tần suất của tenant.
- **Bước**
  1. Bắn yêu cầu tạo người dùng vượt ngưỡng; tạo vượt giới hạn số lượng (10.000 người dùng).
- **Mong đợi** `429` ERR-12-037 kèm `Retry-After`; vượt giới hạn số lượng `422` ERR-12-043.

#### TC-12-104 · Keycloak, OpenBao hoặc phân hệ phụ thuộc không khả dụng <!--k:api-dependency-down-->
- **Loại** Âm, Chaos · **Ưu tiên** P1 · **Tự động** Chaos, API
- **Truy vết** FR-12-003, 030, 034 · API-12-003, 058, 066 · ERR-12-038 · ERR-12-039 · ERR-12-040 · NFR-12-013
- **Tiền điều kiện / dữ liệu** Chaos Mesh tắt lần lượt Keycloak, OpenBao, PH-01, PH-07.
- **Bước**
  1. Tạo người dùng khi Keycloak tắt; xoay bí mật khi OpenBao tắt; cấp client khi PH-01 tắt.
- **Mong đợi** `503` với ERR-12-038, ERR-12-039, ERR-12-040 tương ứng; không có dữ liệu nửa chừng; sau khi phục hồi gọi lại thành công.

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Nhóm này là điều kiện chặn phát hành của PH-12. Ca chạy trên môi trường PERF hoặc SIT bật Chaos Mesh; mỗi ca có ngưỡng cụ thể lấy từ NFR-12.

### TS-12-33 · Không lộ bí mật

**Mục tiêu.** Chứng minh mật khẩu, mã TOTP, bí mật client, token đầy đủ không xuất hiện ở bất kỳ đâu ngoài nơi lưu được phép, bằng giá trị mồi `DH-CANARY`.

**Phủ.** BR-12-023, 045; NFR-12-020, 018; FR-12-006, 022, 034, 035.

#### TC-12-105 · Mồi bí mật qua toàn bộ vòng đời định danh <!--k:canary-lifecycle-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** NFR-12-020 · BR-12-045, BR-12-023 · FR-12-006, 022, 034, 035 · API-12-003, 066, 074
- **Tiền điều kiện / dữ liệu** Mật khẩu `DH-CANARY-pw`, bí mật client `DH-CANARY-cs`, token mồi; mọi loại lỗi.
- **Bước**
  1. Tạo người dùng, kích hoạt bằng mật khẩu mồi, đăng ký TOTP, đăng nhập sai và đúng, tạo client, xoay bí mật, lấy token, xuất báo cáo.
  2. Tìm mồi ở phản hồi API (HAR Playwright), `localStorage`, `sessionStorage`, log mọi pod 1 giờ (Loki), vết (Tempo), mọi bảng `ph12_iam.*`, Kafka `t68.*`, tệp xuất, kiểm toán PH-13, thông báo lỗi.
- **Mong đợi** Mồi sạch ở mọi nơi; mật khẩu chỉ ở dạng băm trong Keycloak; bí mật client chỉ ở OpenBao; khóa ký riêng không có trong log, ảnh container, kho mã.

#### TC-12-106 · Mồi trong lỗi và trong khi hệ phụ thuộc hỏng <!--k:canary-errors-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API, Chaos
- **Truy vết** NFR-12-020 · BR-12-045 · ERR-12-003, ERR-12-015, ERR-12-111, ERR-12-039 · API-12-003, 074
- **Tiền điều kiện / dữ liệu** Mồi trong mật khẩu, thân sai lược đồ, JWKS sai; OpenBao tắt.
- **Bước**
  1. Gây lỗi 400, 422, 401, 503 với thân chứa mồi; xem log và thân lỗi.
- **Mong đợi** Thân lỗi và log không chứa mồi; thông báo lỗi chỉ nêu tên trường.

### TS-12-34 · Cách ly tenant và RLS

**Mục tiêu.** Chứng minh tỉnh này không đọc, ghi, thu hồi được định danh, client, chính sách của tỉnh khác ở API, token, CSDL, realm.

**Phủ.** BR-12-003, 004, 041; NFR-12-023; FR-12-001, 002, 030, 044, 058; API-12-001, 002, 025, 032, 056, 089, 103.

#### TC-12-107 · Quét mọi API đọc: tenant khác trả 404-ẩn, danh sách không lẫn <!--k:iso-api-sweep-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-12-041, BR-12-004 · FR-12-001, 002, 030 · API-12-001, 002, 025, 032, 056, 057, 089, 090, 103, 104 · ERR-12-001
- **Tiền điều kiện / dữ liệu** U-T01-TA; đối tượng cùng mã ở T01 và T68; U-T68-TA1.
- **Bước**
  1. Với mỗi API đọc `GET` có `{id}`, gọi id của T68 bằng token T01.
  2. Gọi danh sách của từng tài nguyên bằng cả hai token; thêm `X-Tenant`, tham số `tenant`.
- **Mong đợi** Mọi trường hợp chéo tenant `404` ERR-12-001 thân giống "không có" trừ `traceId`; danh sách chỉ có đối tượng của tenant token; tham số, tiêu đề tenant bị bỏ qua.

#### TC-12-108 · Ghi chéo tenant và RLS ở CSDL <!--k:iso-write-rls-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API, DB
- **Truy vết** BR-12-003, BR-12-041 · NFR-12-023 · API-12-026, 058, 060, 062 · ERR-12-001 · SEC-80
- **Tiền điều kiện / dữ liệu** U-T01-TA; pgTAP với vai trò ứng dụng.
- **Bước**
  1. Bằng token T01 gán vai trò, `:suspend`, `:revoke` client của T68.
  2. pgTAP: đặt `app.tenant_id=T01`, `SELECT`, `UPDATE` bảng `ph12_iam.*` của T68; bỏ đặt biến tenant.
- **Mong đợi** Bước 1 trả 404-ẩn, dữ liệu T68 nguyên vẹn; bước 2 không thấy hàng nào, không ghi được; thiếu biến tenant thì 0 hàng.

#### TC-12-109 · Token của tenant này không dùng được ở realm hay gói chính sách tenant khác <!--k:iso-token-realm-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** BR-12-003, BR-12-004 · FR-12-044, 058 · API-12-074, 086, 103 · ERR-12-116 · SEC-85
- **Tiền điều kiện / dữ liệu** Token T01; gói chính sách POL-T68-OK chỉ của T68.
- **Bước**
  1. Dùng token T01 gọi API T68; thử đổi `iss` của token.
  2. Gọi `decide` với token T01 nhưng tài nguyên T68; xem nhật ký quyết định của T68 bằng AU T01.
- **Mong đợi** ERR-12-116 (401) hoặc 404-ẩn; quyết định `deny`; luật tenant T68 không ảnh hưởng quyết định của T01.

### TS-12-35 · Chịu lỗi, độc lập control plane và phục hồi

**Mục tiêu.** Chứng minh Keycloak và OPA vẫn phục vụ khi control plane ngừng, sẵn sàng theo SLO, phục hồi `pg-iam` trong RPO, RTO.

**Phủ.** NFR-12-011, 012, 013, 014, 015, 016; FR-12-020, 044.

#### TC-12-110 · Control plane ngừng: vẫn đăng nhập, vẫn quyết định ≥ 24 giờ <!--k:resil-independence-->
- **Loại** Chaos · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** NFR-12-013 · FR-12-020, 044 · API-12-074, 086 · ERR-12-103
- **Tiền điều kiện / dữ liệu** PERF; tắt mọi DU control plane (`dh-platform`, `dh-connect`, `dh-integration`).
- **Bước**
  1. Đăng nhập, lấy token, gọi `decide` mỗi giây trong 24 giờ (rút gọn bằng đồng hồ nhanh ở SIT).
- **Mong đợi** Keycloak vẫn cấp token, OPA vẫn quyết định bằng gói đã nạp; thay đổi chính sách mới thì chờ (không áp), không từ chối nhầm.

#### TC-12-111 · Mất một bản sao Keycloak, một pod OPA, một instance `pg-iam` <!--k:resil-ha-->
- **Loại** Chaos, Khả dụng · **Ưu tiên** P1 · **Tự động** Chaos
- **Truy vết** NFR-12-011, 012, 015 · FR-12-020, 044
- **Tiền điều kiện / dữ liệu** Keycloak 3 bản sao; OPA sidecar; `pg-iam` 3 instance.
- **Bước**
  1. Xóa lần lượt từng thành phần dưới tải 100 đăng nhập/phút và 300 quyết định/giây.
- **Mong đợi** Tỷ lệ lỗi < 0,01 % ngoài cửa sổ chuyển; không mất phiên có sẵn; cấu hình đủ bản sao theo NFR-12-015; thang sẵn sàng đo bằng kiểm tra tổng hợp mỗi phút.

#### TC-12-112 · Diễn tập khôi phục `pg-iam` <!--k:resil-dr-->
- **Loại** Chaos · **Ưu tiên** P2 · **Tự động** Thủ công
- **Truy vết** NFR-12-016 · NFR-12-011
- **Tiền điều kiện / dữ liệu** Sao lưu và WAL đang chạy; ADR-034 DR hai site.
- **Bước**
  1. Hủy `pg-iam` primary, chuyển sang site standby; đo thời gian và dữ liệu mất.
- **Mong đợi** RPO ≤ 15 phút, RTO ≤ 1 giờ; đăng nhập và quyết định chạy lại, khóa ký không đổi.

### TS-12-36 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-12-001…009 và 023…025 ở cấu hình `QM-VUA` với dữ liệu GĐ.

**Phủ.** NFR-12-001…009, 023, 024, 025; FR-12-040, 044, 035, 020.

| Mã | Tên | Tải | Ngưỡng | Truy vết |
|---|---|---|---|---|
| TC-12-113 | Độ trễ quyết định OPA cục bộ <!--k:perf-opa-local--> | 300 lượt/giây, 500 phiên bản chính sách, 30 phút | p50 ≤ 0,5 ms, p99 ≤ 2 ms | NFR-12-001 · FR-12-044 |
| TC-12-114 | Độ trễ `/decide` qua API <!--k:perf-decide-api--> | Trượt bộ đệm, trong cụm, 15 phút | p95 ≤ 10 ms, p99 ≤ 30 ms | NFR-12-002 · API-12-086 |
| TC-12-115 | Thông lượng quyết định <!--k:perf-throughput--> | 10.000 quyết định/giây toàn cụm, 15 phút | Lỗi < 0,01 % | NFR-12-003 · FR-12-044 |
| TC-12-116 | Hiệu lực chính sách và dữ liệu mới <!--k:perf-policy-effect--> | 6 pod OPA, 20 lần phát hành | ≤ 60 giây tới mọi OPA | NFR-12-004 · FR-12-054, 051 |
| TC-12-117 | Hiệu lực thu hồi <!--k:perf-revoke--> | Client có token, gọi mỗi giây, 20 lần | ≤ 60 giây tại APISIX và DU | NFR-12-005 · FR-12-040 |
| TC-12-118 | Độ trễ cấp token máy <!--k:perf-cc-token--> | 100 yêu cầu/giây, 500 client, 15 phút | p95 ≤ 150 ms, p99 ≤ 300 ms | NFR-12-006 · FR-12-035 |
| TC-12-119 | Thời gian đăng nhập <!--k:perf-login--> | 200 đăng nhập đồng thời | p95 ≤ 2 giây (không tính yếu tố thứ hai) | NFR-12-007 · FR-12-020 |
| TC-12-120 | API quản trị ở quy mô tenant <!--k:perf-admin-api--> | 10.000 người dùng, 1.000 client, 30 phút | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | NFR-12-008 · FR-12-001, 030 |
| TC-12-121 | Tỷ lệ trúng bộ đệm quyết định <!--k:perf-cache-hit--> | Lưu lượng mô phỏng 1 giờ | ≥ 60 % | NFR-12-009 · FR-12-050 |
| TC-12-122 | Quy mô chính sách <!--k:perf-policy-scale--> | 500 phiên bản `PUBLISHED`, gói 20 MiB | Độ trễ tăng ≤ 20 % | NFR-12-024 · FR-12-052 |
| TC-12-123 | Quy mô định danh và phiên <!--k:perf-scale-id--> | 34 realm; 2.000 phiên mỗi tenant; 20.000 phiên toàn cụm | Đăng nhập và quyết định đạt ngưỡng trên | NFR-12-023, 025 · FR-12-041 |

: TS-12-36 · Hiệu năng, tải và quy mô

### TS-12-37 · Bảo mật ứng dụng, giám sát và truy cập

**Mục tiêu.** Chứng minh mật khẩu băm đúng chuẩn, TLS, quét ASVS, chỉ số vận hành, truy cập WCAG 2.2 AA, tương thích hợp đồng.

**Phủ.** NFR-12-017, 019, 022, 026, 031, 032, 033; UI-12-01…19.

#### TC-12-124 · Quét ASVS 5.0 mức 2 và TLS <!--k:sec-zap-tls-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** ZAP
- **Truy vết** NFR-12-022, 019, 017 · API-12-001, 058, 074, 086 · UI-12-18 · SEC-20
- **Tiền điều kiện / dữ liệu** SIT; ZAP với hợp đồng OpenAPI của PH-12; quét TLS mọi điểm cuối.
- **Bước**
  1. Chạy ZAP active scan có xác thực cho UI-12-01…19 và API; quét TLS; kiểm tra cấu hình băm mật khẩu của realm.
- **Mong đợi** 0 lỗ hổng CRITICAL, HIGH; TLS 1.3 ở biên mức A, mTLS nội bộ; băm `argon2id` hoặc `pbkdf2-sha512` ≥ 210.000 vòng.

#### TC-12-125 · Chỉ số vận hành và truy vết xuyên suốt <!--k:obs-metrics-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** NFR-12-026, 027 · FR-12-056, 057 · API-12-086
- **Tiền điều kiện / dữ liệu** Prometheus, Tempo.
- **Bước**
  1. Chạy 100 quyết định và 50 đăng nhập; đọc chỉ số, truy vết một yêu cầu qua PH-04.
- **Mong đợi** Có `iam_decisions_total{result,policy}`, `iam_decision_duration_seconds`, `iam_login_total{result,method}`; `trace_id` và `tenant_id` nhất quán.

#### TC-12-126 · Truy cập WCAG 2.2 AA mọi màn hình <!--k:a11y-all-->
- **Loại** Truy cập · **Ưu tiên** P2 · **Tự động** E2E, Thủ công
- **Truy vết** NFR-12-031 · UI-12-01…19 · UC-12-01, 02, 09, 35
- **Tiền điều kiện / dữ liệu** axe-core; NVDA.
- **Bước**
  1. Chạy axe-core trên 19 màn; dùng NVDA hoàn thành tạo người dùng, gán vai trò, duyệt chính sách bằng bàn phím.
- **Mong đợi** 0 lỗi mức nghiêm trọng; mọi thao tác dùng được bằng bàn phím, nhãn đọc đúng tiếng Việt, tương phản đạt AA ở nền kính.

#### TC-12-127 · Độ phủ kiểm thử và tương thích hợp đồng <!--k:ci-coverage-compat-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** UT, API
- **Truy vết** NFR-12-033, 032 · API-12-086, 087
- **Tiền điều kiện / dữ liệu** CI; PEP phiên bản cũ.
- **Bước**
  1. Đọc báo cáo `opa test` và JaCoCo; gọi `decide` bằng PEP bản cũ ≥ 6 tháng.
- **Mong đợi** `opa test` ≥ 90 % dòng, mã `ph12_iam` ≥ 80 %; PEP cũ vẫn dùng được, API `v1` chỉ thêm trường tùy chọn.

## 6. Thủ tục kiểm thử thủ công

Ba thủ tục dưới đây bổ sung cho ca tự động, mỗi thủ tục có biên bản ký của kiểm thử viên và cán bộ ATTT.

### 6.1. Kiểm thử khám phá theo phiên

Mỗi phiên 90 phút, hai kiểm thử viên, mục tiêu: UI-12-12 (soạn chính sách) và UI-12-17 (duyệt). Ghi lại mọi trường hợp người dùng có thể tự duyệt, tự nâng quyền, hay thấy dữ liệu tenant khác; mọi phát hiện thành ca TC-12 mới ở bản kế tiếp.

### 6.2. Diễn tập mất thiết bị yếu tố thứ hai và sự cố khóa ký

Diễn tập hằng quý trên UAT: (1) cán bộ mất khóa WebAuthn, TA đặt lại theo FR-12-024 với xác minh qua điện thoại; (2) giả định khóa ký realm bị lộ, PA và SO thực hiện xoay khẩn có người duyệt thứ hai rồi thu hồi truy cập toàn tenant (FR-12-039, 040) và đo thời gian từ lúc phát hiện đến lúc token cũ bị từ chối ở APISIX.

### 6.3. Kiểm thử truy cập thủ công

Dùng NVDA và bàn phím cho UI-12-02, 06, 12, 13, 18; xác nhận thứ tự tab, nhãn tiếng Việt, thông báo lỗi và hộp thoại bước lên đọc được; trang theme Keycloak (UI-12-18) kiểm cả khi phóng to 200 %.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Quản trị viên của tỉnh đang dùng bảng quản trị Keycloak cũ tự thực hiện trên UAT. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Tạo người dùng mới và gán vai trò | LGC-IAM-002 | Làm trong 3 phút, có kiểm tra xung đột vai trò trước khi lưu, người dùng nhận thư kích hoạt | FR-12-003, 012, 013 | TS-12-02, 07, 08 |
| UAT-02 | Đăng nhập một lần vào console và ứng dụng khác | LGC-IAM-001 | Đăng nhập một lần cho mọi khối, đăng xuất một nơi thì thoát mọi nơi | FR-12-020 | TS-12-14 |
| UAT-03 | Cấu hình xác thực hai yếu tố | LGC-IAM-003 | Làm được TOTP như cũ, thêm WebAuthn; đặt lại khi mất thiết bị có duyệt | FR-12-022, 024 | TS-12-16, 17 |
| UAT-04 | Liên kết LDAP hoặc AD của tỉnh | LGC-IAM-004 | Kiểm tra liên kết trước khi lưu, đồng bộ có báo cáo người nhập | FR-12-026 | TS-12-18 |
| UAT-05 | Xem phiên và buộc một người đăng xuất | LGC-IAM-005 | Thấy phiên, buộc thoát có hiệu lực trong 60 giây | FR-12-029, 040 | TS-12-20, 24 |
| UAT-06 | Lấy token để thử gọi API (thay grant `password`) | LGC-IAM-006 | Người dùng dùng PKCE, hệ thống dùng `client_credentials`; hướng dẫn rõ ràng khi thử grant cũ | FR-12-020, 035 | TS-12-14, 23 |
| UAT-07 | Đăng nhập một lần cho màn quản trị Bus bằng SAML | LGC-IAM-008 | Màn quản trị đăng nhập qua Keycloak, không cần midPoint | FR-12-025 | TS-12-18 |
| UAT-08 | Tìm đăng nhập bằng mạng xã hội | LGC-IAM-007 | Không còn; có VNeID thay thế khi tỉnh yêu cầu | FR-12-028 | TS-12-19 |
| UAT-09 | Quản lý nhóm và gán quyền theo nhóm, đơn vị | LGC-BUS-032 | Cây nhóm, phạm vi kế thừa, không gán vai trò cho nhóm | FR-12-014, 012 | TS-12-09, 07 |
| UAT-10 | Cấp client cho một HTTT và đổi chứng thư | LGC-APIM-020; LGC-NGSP-008, LGC-BUS-041 | Cấp trong 5 phút, bí mật giao một lần, mTLS theo hợp đồng | FR-12-030, 033, 034 | TS-12-21, 22 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-12. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph12/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-12-001 | Liệt kê, tìm kiếm và lọc người dùng | M | LGC-IAM-002 | 001 | 002, 005 | 107, 120 | Có |
| FR-12-002 | Xem chi tiết người dùng | M | LGC-IAM-002; LGC-IAM-005 | 003 | 004 | 107 | Có |
| FR-12-003 | Tạo tài khoản người dùng | M | LGC-IAM-002 | 007, 102 | 008, 009, 011, 102, 104 | 103 | Có |
| FR-12-004 | Sửa thông tin và chuyển đơn vị của người dùng | M | LGC-IAM-002 | 012 | 013 | — | Có |
| FR-12-005 | Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản | M | LGC-IAM-005 | 014, 015 | 016, 017 | — | Có |
| FR-12-006 | Kích hoạt tài khoản lần đầu | M | LGC-IAM-002 | 007 | 010, 011 | 105 | Có |
| FR-12-007 | Đặt lại mật khẩu khi quên | M | LGC-IAM-002 | 019 | 018 | — | Có |
| FR-12-008 | Tự vô hiệu tài khoản và tạm ngừng client không hoạt động | M | mới | 020 | 020 | 021 | Có |
| FR-12-009 | Nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ | M | LGC-IAM-002 | 023 | 024, 025, 026 | — | Có |
| FR-12-010 | Đồng bộ thuộc tính người dùng từ danh mục đơn vị | S | mới | 022 | 022 | — | Có |
| FR-12-011 | Xem danh mục vai trò chuẩn và quyền | M | LGC-IAM-002 | 027 | 027 | — | Có |
| FR-12-012 | Gán và gỡ vai trò cho người dùng | M | LGC-BUS-032; LGC-IAM-002 | 030 | 031 | — | Có |
| FR-12-013 | Chặn cặp vai trò xung đột và duyệt ngoại lệ có thời hạn | M | mới | 033 | 032, 034 | — | Có |
| FR-12-014 | Quản lý nhóm và đơn vị tổ chức | M | LGC-BUS-032; LGC-IAM-002 | 035 | 036 | — | Có |
| FR-12-015 | Tạo vai trò tùy biến của tenant | S | LGC-IAM-002 | 037 | 038 | — | Có |
| FR-12-016 | Xem quyền hiệu lực của người dùng | M | LGC-IAM-002 | 028 | 029 | — | Có |
| FR-12-017 | Cấp quyền có thời hạn cho vai trò đặc quyền và truy cập liên | M | mới | 039 | 040 | — | Có |
| FR-12-018 | Rà soát quyền định kỳ | S | mới | 041 | 042 | — | Có |
| FR-12-019 | Chuyển định danh và vai trò khi sáp nhập tenant | S | mới | 043 | 044 | — | Có |
| FR-12-020 | Xác thực người dùng theo OIDC Authorization Code và PKCE | M | LGC-IAM-001; LGC-IAM-006; LGC-IAM-008 | 045, 048 | 046, 047, 048 | 110, 111, 119 | Có |
| FR-12-021 | Chống dò mật khẩu và khóa tài khoản | M | mới | 049 | 049 | 050 | Có |
| FR-12-022 | Đăng ký và dùng yếu tố thứ hai TOTP, WebAuthn | M | LGC-IAM-003 | 051 | 051 | 105 | Có |
| FR-12-023 | Xác thực lại bước lên cho thao tác nhạy cảm | M | mới | 052 | 052 | — | Có |
| FR-12-024 | Đặt lại yếu tố thứ hai khi mất thiết bị | M | LGC-IAM-003 | 053 | 054 | — | Có |
| FR-12-025 | Đăng nhập một lần bằng SAML 2 cho ứng dụng cũ | M | LGC-IAM-001; LGC-IAM-008 | 055 | 056 | — | Có |
| FR-12-026 | Liên kết LDAP, Active Directory của tỉnh | M | LGC-IAM-004 | 057 | 058 | — | Có |
| FR-12-027 | Đăng nhập liên tenant cho người dùng thuộc nhiều tenant | M | mới | 059 | 059 | — | Có |
| FR-12-028 | Liên kết đăng nhập VNeID | C | LGC-IAM-007 | 060 | 060 | — | Có |
| FR-12-029 | Quản lý phiên: xem, buộc đăng xuất, hạn mức phiên | M | LGC-IAM-005 | 048, 061 | 048 | — | Có |
| FR-12-030 | Cấp client OAuth cho HTTT thành viên | M | LGC-APIM-020; LGC-NGSP-008 | 062 | 063, 104 | 107, 120 | Có |
| FR-12-031 | Quản lý vòng đời client: sửa, tạm ngừng, tiếp tục, thu hồi | M | LGC-APIM-020 | 064 | 064 | — | Có |
| FR-12-032 | Cấp client cho ứng dụng nhà phát triển ở sandbox | S | LGC-APIM-020; LGC-IAM-006 | 065 | — | — | Có |
| FR-12-033 | Đăng ký chứng thư mTLS và khóa công khai của client | M | LGC-BUS-041 | 066 | 066 | — | Có |
| FR-12-034 | Xoay bí mật client | M | LGC-NGSP-008 | 067 | 104 | 105 | Có |
| FR-12-035 | Phát token cho HTTT bằng `client_credentials` | M | LGC-BUS-041; LGC-IAM-006; LGC-NGSP-008 | 068 | 069 | 105, 118 | Có |
| FR-12-036 | Sinh scope của client từ dữ liệu đã duyệt | M | mới | 070 | 070 | — | Có |
| FR-12-037 | Tài khoản dịch vụ nội bộ của đơn vị triển khai | M | mới | 071 | 071 | — | Có |
| FR-12-038 | Vòng đời token: làm mới xoay vòng, phát hiện dùng lại | M | LGC-IAM-005 | 072 | 072 | — | Có |
| FR-12-039 | Công bố JWKS và xoay khóa ký 90 ngày | M | mới | 073 | 073 | — | Có |
| FR-12-040 | Thu hồi truy cập tức thời và phân phối danh sách chặn | M | LGC-IAM-005 | 074 | 075 | 117 | Có |
| FR-12-041 | Khởi tạo realm của tenant từ mẫu | M | LGC-IAM-002 | 076 | 076 | 123 | Có |
| FR-12-042 | Cấu hình bảo mật realm bằng GitOps, phát hiện lệch | M | mới | 077 | 077 | — | Có |
| FR-12-043 | Tạm ngừng, khôi phục, chuyển chỉ-đọc realm theo vòng đời ten | M | mới | 078 | 047, 078 | — | Có |
| FR-12-044 | Quyết định ủy quyền theo hợp đồng PEP và PDP | M | LGC-BUS-041 | 079 | 079, 084 | 085, 109, 110, 111, 113, 115 | Có |
| FR-12-045 | Quy tắc gốc: từ chối mặc định, từ chối thắng, cách ly tenant | M | mới | 082 | 080, 081 | — | Có |
| FR-12-046 | Phân quyền ba lớp: vai trò, phạm vi tổ chức, thuộc tính dữ l | M | mới | 028, 079 | 079 | — | Có |
| FR-12-047 | Tính mặt nạ trường và chế độ bảo vệ theo mục đích | M | mới | 083 | 083 | — | Có |
| FR-12-048 | Bộ chuyển đổi XACML 3.0 | M | mới | 086 | 086 | — | Có |
| FR-12-049 | Quyết định theo lô | S | mới | 087 | — | — | Có |
| FR-12-050 | Bộ đệm quyết định | S | mới | 088 | — | 121 | Có |
| FR-12-051 | Sinh dữ liệu vai trò–quyền cho OPA từ ma trận D02-08 | M | mới | 089 | 089 | 116 | Có |
| FR-12-052 | Soạn và kiểm thử chính sách | M | mới | 090 | 091 | 122 | Có |
| FR-12-053 | Chạy khô chính sách trên lưu lượng thật | M | mới | 092 | 092 | — | Có |
| FR-12-054 | Duyệt bốn mắt và phát hành gói chính sách ký | M | mới | 093 | 094, 095 | 116 | Có |
| FR-12-055 | Thu hồi và quay lui chính sách | M | mới | 096 | 096 | — | Có |
| FR-12-056 | Ghi vết sự kiện xác thực và quản trị định danh | M | LGC-IAM-005 | 097, 125 | 097 | — | Có |
| FR-12-057 | Ghi vết quyết định ủy quyền | M | mới | 098, 125 | 098 | — | Có |
| FR-12-058 | Tra cứu nhật ký quyết định | M | mới | 098 | 098 | 109 | Có |
| FR-12-059 | Phát hiện hành vi bất thường và cảnh báo | S | mới | 099 | — | — | Có |
| FR-12-060 | Báo cáo tình trạng tài khoản và xác thực hai yếu tố | S | mới | 100 | — | — | Có |
| FR-12-061 | Tham số phân hệ theo tenant | M | mới | 101 | 101 | — | Có |
| FR-12-062 | Tra cứu danh bạ người dùng cho phân hệ khác | M | mới | 006 | 006 | — | Có |

: Truy vết yêu cầu chức năng tới test case

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng của IAM cũ (`LGC-IAM`) và các chức năng quản lý group, application của Bus, APIM, NGSP có dùng định danh được truy tới FR mới, ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-APIM-020 | 030, 031, 032 | 062, 064, 065 | UAT-10 |
| LGC-BUS-032 | 012, 014 | 030, 035 | UAT-09 |
| LGC-BUS-041 | 033, 035, 044 | 066, 068, 079 | UAT-10 |
| LGC-IAM-001 | 020, 025 | 045, 048, 055 | UAT-02 |
| LGC-IAM-002 | 001, 002, 003, 004, 006, 007, 009, 011, 012, 014, 015, 016, 041 | 001, 003, 007, 012, 018, 019, 023, 026 (+7) | UAT-01 |
| LGC-IAM-003 | 022, 024 | 051, 053 | UAT-03 |
| LGC-IAM-004 | 026 | 057 | UAT-04 |
| LGC-IAM-005 | 002, 005, 029, 038, 040, 056 | 003, 014, 015, 048, 061, 072, 074, 097 (+1) | UAT-05 |
| LGC-IAM-006 | 020, 032, 035 | 045, 046, 048, 065, 068 | UAT-06 |
| LGC-IAM-007 | 028 | 060 | UAT-08 |
| LGC-IAM-008 | 020, 025 | 045, 048, 055 | UAT-07 |
| LGC-NGSP-008 | 030, 034, 035 | 062, 067, 068 | UAT-10 |

: Truy vết chức năng hệ cũ tới yêu cầu và test case

### 8.3. Quy tắc nghiệp vụ → test case

Bảng sau cho biết mỗi quy tắc nghiệp vụ BR-12 được kiểm bởi những test case nào, ghi ba chữ số cuối của mã TC-12.

| Mã | Test case |
|---|---|
| BR-12-001 | 080 |
| BR-12-002 | 081 |
| BR-12-003 | 082, 108, 109 |
| BR-12-004 | 004, 006, 082, 107, 109 |
| BR-12-005 | 081 |
| BR-12-006 | 085 |
| BR-12-007 | 038, 091 |
| BR-12-008 | 037, 038, 093, 094 |
| BR-12-009 | 090, 092, 094 |
| BR-12-010 | 089, 093, 096 |
| BR-12-011 | 092, 095 |
| BR-12-012 | 083, 088 |
| BR-12-013 | 085, 098 |
| BR-12-014 | 002, 008, 071 |
| BR-12-015 | 051, 100 |
| BR-12-016 | 052 |
| BR-12-017 | 018, 050 |
| BR-12-018 | 007, 010, 019 |
| BR-12-019 | 049 |
| BR-12-020 | 020, 021 |
| BR-12-021 | 046, 069 |
| BR-12-022 | 019, 048, 101 |
| BR-12-023 | 062, 067, 105 |
| BR-12-024 | 062, 063, 065, 066, 069 |
| BR-12-025 | 070 |
| BR-12-026 | 068, 072 |
| BR-12-027 | 073 |
| BR-12-028 | 064, 074, 075 |
| BR-12-029 | 026, 057, 060 |
| BR-12-030 | 032, 033, 034 |
| BR-12-031 | 031, 040, 059, 082 |
| BR-12-032 | 039, 040 |
| BR-12-033 | 017, 031, 034, 040, 042, 054, 075 |
| BR-12-034 | 053, 054 |
| BR-12-035 | 015, 020 |
| BR-12-036 | 012, 014, 030, 061 |
| BR-12-037 | 005, 012, 028, 079 |
| BR-12-038 | 077 |
| BR-12-039 | 035, 036 |
| BR-12-040 | 083 |
| BR-12-041 | 004, 029, 107, 108 |
| BR-12-042 | 006 |
| BR-12-043 | 023, 024, 025 |
| BR-12-044 | 041, 042 |
| BR-12-045 | 025, 105, 106 |

: Quy tắc nghiệp vụ và test case

### 8.4. Mã lỗi → test case

Bảng sau cho biết mỗi mã lỗi ERR-12 được kích hoạt và kiểm tra thông báo ở những test case nào; danh sách mã lấy từ D03-04-PH12 mục 6.

| Mã | Test case |
|---|---|
| ERR-12-001 | 004, 005, 013, 029, 107, 108 |
| ERR-12-002 | 008, 024 |
| ERR-12-003 | 008, 106 |
| ERR-12-004 | 009, 024 |
| ERR-12-005 | 009, 024 |
| ERR-12-006 | 016 |
| ERR-12-007 | 002, 102 |
| ERR-12-008 | 034, 038, 040, 094 |
| ERR-12-009 | 032 |
| ERR-12-010 | 031, 038, 071 |
| ERR-12-011 | 036, 038 |
| ERR-12-012 | 036 |
| ERR-12-013 | 017, 031, 042, 054, 075 |
| ERR-12-014 | 016, 034, 054, 075 |
| ERR-12-015 | 010, 019, 106 |
| ERR-12-016 | 011 |
| ERR-12-017 | 054 |
| ERR-12-018 | 063 |
| ERR-12-019 | 070 |
| ERR-12-020 | 064 |
| ERR-12-021 | 066 |
| ERR-12-022 | 063 |
| ERR-12-023 | 067 |
| ERR-12-024 | 091 |
| ERR-12-025 | 094 |
| ERR-12-026 | 094 |
| ERR-12-027 | 095, 096 |
| ERR-12-028 | 091 |
| ERR-12-029 | 095 |
| ERR-12-030 | 040 |
| ERR-12-031 | 042 |
| ERR-12-032 | 058 |
| ERR-12-033 | 056 |
| ERR-12-034 | 060 |
| ERR-12-035 | 025 |
| ERR-12-036 | 026 |
| ERR-12-037 | 103 |
| ERR-12-038 | 104 |
| ERR-12-039 | 067, 104, 106 |
| ERR-12-040 | 044, 104 |
| ERR-12-041 | 044, 076, 078 |
| ERR-12-042 | 077 |
| ERR-12-043 | 101, 103 |
| ERR-12-044 | 013, 101 |
| ERR-12-045 | 102 |
| ERR-12-046 | 017 |
| ERR-12-047 | 013, 058 |
| ERR-12-101 | 084, 087 |
| ERR-12-102 | 084 |
| ERR-12-103 | 085, 110 |
| ERR-12-104 | 085 |
| ERR-12-111 | 049, 050, 106 |
| ERR-12-112 | 049 |
| ERR-12-113 | 049 |
| ERR-12-114 | 046 |
| ERR-12-115 | 072 |
| ERR-12-116 | 046, 074, 109 |
| ERR-12-117 | 069 |
| ERR-12-118 | 069 |
| ERR-12-119 | 069 |
| ERR-12-120 | 052 |
| ERR-12-121 | 047, 078 |
| ERR-12-122 | 046 |
| ERR-12-123 | 086 |
| ERR-12-124 | 085 |
| ERR-12-125 | 050 |

: Mã lỗi và test case

### 8.5. Yêu cầu phi chức năng → test case

Bảng sau cho biết mỗi yêu cầu phi chức năng NFR-12 được chứng minh bởi những test case nào ở mục 5.

| Mã | Test case |
|---|---|
| NFR-12-001 | 113 |
| NFR-12-002 | 079, 114 |
| NFR-12-003 | 115 |
| NFR-12-004 | 116 |
| NFR-12-005 | 074, 117 |
| NFR-12-006 | 068, 118 |
| NFR-12-007 | 045, 119 |
| NFR-12-008 | 001, 120 |
| NFR-12-009 | 088, 121 |
| NFR-12-010 | 076 |
| NFR-12-011 | 111, 112 |
| NFR-12-012 | 111 |
| NFR-12-013 | 104, 110 |
| NFR-12-014 | 082, 085 |
| NFR-12-015 | 111 |
| NFR-12-016 | 112 |
| NFR-12-017 | 124 |
| NFR-12-018 | 073 |
| NFR-12-019 | 124 |
| NFR-12-020 | 067, 105, 106 |
| NFR-12-021 | 050 |
| NFR-12-022 | 124 |
| NFR-12-023 | 108, 123 |
| NFR-12-024 | 122 |
| NFR-12-025 | 123 |
| NFR-12-026 | 125 |
| NFR-12-027 | 097, 125 |
| NFR-12-028 | 099 |
| NFR-12-029 | 098 |
| NFR-12-030 | 098 |
| NFR-12-031 | 126 |
| NFR-12-032 | 102, 127 |
| NFR-12-033 | 127 |

: Yêu cầu phi chức năng và test case

### 8.6. API → test case

Bảng sau cho biết mỗi API-12 được gọi trong những test case nào, để mọi điểm cuối của D03-04-PH12 có ít nhất một ca.

| Mã | Test case |
|---|---|
| API-12-001 | 001, 002, 005, 107, 124 |
| API-12-002 | 003, 004, 005, 107 |
| API-12-003 | 007, 008, 009, 102, 103, 104, 105, 106 |
| API-12-004 | 012, 013 |
| API-12-005 | 014, 016, 017 |
| API-12-006 | 014, 016 |
| API-12-007 | 015, 017 |
| API-12-008 | 015, 016 |
| API-12-009 | 011 |
| API-12-010 | 023, 025 |
| API-12-011 | 023, 024, 026 |
| API-12-012 | 023, 024 |
| API-12-013 | 028, 029 |
| API-12-014 | 006 |
| API-12-015 | 053, 054 |
| API-12-016 | 048, 061 |
| API-12-017 | 061 |
| API-12-018 | 074, 075 |
| API-12-019 | 027 |
| API-12-020 | 027 |
| API-12-021 | 027 |
| API-12-022 | 037, 038 |
| API-12-023 | 037 |
| API-12-024 | 037, 038 |
| API-12-025 | 030, 107 |
| API-12-026 | 030, 031, 032, 108 |
| API-12-027 | 030 |
| API-12-028 | 032 |
| API-12-029 | 033, 034 |
| API-12-030 | 033, 034 |
| API-12-031 | 033 |
| API-12-032 | 035, 107 |
| API-12-033 | 035 |
| API-12-034 | 035, 036 |
| API-12-035 | 035 |
| API-12-036 | 039, 040 |
| API-12-037 | 039 |
| API-12-038 | 039, 040 |
| API-12-039 | 040 |
| API-12-040 | 039 |
| API-12-041 | 041, 042 |
| API-12-042 | 041 |
| API-12-043 | 041, 042 |
| API-12-044 | 041 |
| API-12-045 | 043 |
| API-12-046 | 043, 044 |
| API-12-047 | 057 |
| API-12-048 | 057, 058 |
| API-12-049 | 057, 058 |
| API-12-050 | 057 |
| API-12-051 | 055 |
| API-12-052 | 055, 056 |
| API-12-053 | 055 |
| API-12-054 | 060 |
| API-12-055 | 060 |
| API-12-056 | 062, 107 |
| API-12-057 | 062, 107 |
| API-12-058 | 062, 063, 102, 104, 108, 124 |
| API-12-059 | 064 |
| API-12-060 | 021, 064, 108 |
| API-12-061 | 064 |
| API-12-062 | 064, 108 |
| API-12-063 | 065 |
| API-12-064 | 066 |
| API-12-065 | 066 |
| API-12-066 | 067, 104, 105 |
| API-12-067 | 070 |
| API-12-068 | 070 |
| API-12-069 | 071 |
| API-12-070 | 071 |
| API-12-071 | 071 |
| API-12-072 | 045 |
| API-12-073 | 045, 046, 047, 052, 059 |
| API-12-074 | 045, 046, 047, 052, 059, 068, 069, 072, 105, 106 (+3) |
| API-12-075 | 045, 073 |
| API-12-076 | 045 |
| API-12-077 | 046, 072 |
| API-12-078 | 045 |
| API-12-079 | 074 |
| API-12-080 | 076 |
| API-12-081 | 076 |
| API-12-082 | 077 |
| API-12-083 | 077 |
| API-12-084 | 078 |
| API-12-085 | 078 |
| API-12-086 | 079, 080, 081, 082, 083, 084, 085, 109, 110, 114 (+3) |
| API-12-087 | 087, 127 |
| API-12-088 | 086 |
| API-12-089 | 090, 107 |
| API-12-090 | 090, 107 |
| API-12-091 | 090, 091 |
| API-12-092 | 090, 091 |
| API-12-093 | 090 |
| API-12-094 | 090, 091 |
| API-12-095 | 092 |
| API-12-096 | 093 |
| API-12-097 | 093, 094, 095 |
| API-12-098 | 094, 095 |
| API-12-099 | 096 |
| API-12-100 | 096 |
| API-12-101 | 089, 093, 096 |
| API-12-102 | 089 |
| API-12-103 | 098, 107, 109 |
| API-12-104 | 098, 107 |
| API-12-105 | 097 |
| API-12-106 | 099 |
| API-12-107 | 099 |
| API-12-108 | 100 |
| API-12-109 | 100 |
| API-12-110 | 101 |
| API-12-111 | 101 |

: API và test case

### 8.7. Use case → test case

Bảng sau cho biết mỗi use case UC-12 được phủ bởi những test case nào, để mọi luồng của D02-04-PH12 có ca kiểm thử.

| Mã | Test case |
|---|---|
| UC-12-01 | 001, 003, 126 |
| UC-12-02 | 007, 102, 126 |
| UC-12-03 | 012 |
| UC-12-04 | 014 |
| UC-12-05 | 023 |
| UC-12-06 | 018 |
| UC-12-07 | 020, 021, 022 |
| UC-12-08 | 027, 028 |
| UC-12-09 | 030, 126 |
| UC-12-10 | 032, 033 |
| UC-12-11 | 035 |
| UC-12-12 | 037 |
| UC-12-13 | 039, 059 |
| UC-12-14 | 041 |
| UC-12-15 | 043 |
| UC-12-16 | 045, 049, 072 |
| UC-12-17 | 051, 052 |
| UC-12-18 | 053 |
| UC-12-19 | 055, 057 |
| UC-12-20 | 061 |
| UC-12-21 | 062, 065 |
| UC-12-22 | 070 |
| UC-12-23 | 064 |
| UC-12-24 | 066, 067 |
| UC-12-25 | 068 |
| UC-12-26 | 071 |
| UC-12-27 | 073 |
| UC-12-28 | 074 |
| UC-12-29 | 076, 077 |
| UC-12-30 | 078 |
| UC-12-31 | 079 |
| UC-12-32 | 086, 087, 088 |
| UC-12-33 | 089 |
| UC-12-34 | 090, 092 |
| UC-12-35 | 093, 126 |
| UC-12-36 | 096 |
| UC-12-37 | 097, 098 |
| UC-12-38 | 098 |
| UC-12-39 | 099 |
| UC-12-40 | 100 |
| UC-12-41 | 101 |
| UC-12-42 | 006 |

: Use case và test case

### 8.8. Màn hình → test case

Bảng sau cho biết mỗi màn UI-12 được kiểm bởi những test case nào, để mọi màn của D03-06-PH12 có ít nhất một ca.

| Mã | Test case |
|---|---|
| UI-12-01 | 001, 002, 126 |
| UI-12-02 | 003, 012, 014, 028, 051, 053, 061, 074, 126 |
| UI-12-03 | 007, 011, 012, 015, 126 |
| UI-12-04 | 023, 126 |
| UI-12-05 | 027, 037, 126 |
| UI-12-06 | 030, 032, 126 |
| UI-12-07 | 022, 035, 126 |
| UI-12-08 | 039, 126 |
| UI-12-09 | 041, 126 |
| UI-12-10 | 062, 064, 065, 066, 067, 070, 071, 126 |
| UI-12-11 | 055, 057, 060, 126 |
| UI-12-12 | 089, 090, 096, 126 |
| UI-12-13 | 092, 093, 095, 126 |
| UI-12-14 | 098, 126 |
| UI-12-15 | 020, 097, 099, 100, 126 |
| UI-12-16 | 101, 126 |
| UI-12-17 | 033, 039, 053, 093, 126 |
| UI-12-18 | 007, 010, 018, 019, 045, 048, 049, 051, 052, 059 (+2) |
| UI-12-19 | 043, 073, 076, 077, 078, 126 |

: Màn hình và test case
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Bảng sau cho biết mã kiểm thử nằm ở thư mục nào trong kho và chứa loại ca nào.

| Thư mục | Nội dung |
|---|---|
| `apps/platform/src/test/java/vn/datahub/platform/iam/` | UT, IT; lớp cơ sở `IamTestBase` (Testcontainers PostgreSQL 16, Keycloak, OPA, OpenBao, Kafka) |
| `policies/**/*_test.rego` | `opa test`, bộ ca dương, âm cho từng chính sách |
| `apps/console/src/features/iam/**/*.test.ts` | UT frontend |
| `e2e/iam/ts-12-nn.spec.ts` | Playwright (WebAuthn ảo) |
| `perf/iam/*.js` | k6 |
| `datahub-docs/03-thiet-ke/csdl/ph12/test/` | Bài kiểm cô lập RLS (pgTAP) |
| `datahub-docs/05-kiem-thu/test-case/ph12/gherkin/` | Gherkin sinh từ tài liệu này |

: Tổ chức mã kiểm thử

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-12-nnn")`, `test('TC-12-nnn …')`).

### 9.2. Mẫu ca từ chối mặc định (opa test)

Mẫu sau là ca `opa test` mặc định mà mọi bộ chính sách phải có, nhằm chứng minh nguyên tắc từ chối mặc định (fail-closed) của PDP.

```rego
test_default_deny_unknown_action {
    not data.dh.authz.allow with input as {"subject": {"role": "PLATFORM_ADMIN", "tenant": "T68"},
        "action": "x.moi", "resource": {"tenant": "T68"}}
}
test_deny_wins {
    not data.dh.authz.allow with input as {"subject": {"role": "TENANT_ADMIN", "tenant": "T68"},
        "action": "user.read", "resource": {"tenant": "T01"}}
}
```

Đoạn mã minh họa TC-12 của TS-12-26: yêu cầu hành động chưa có luật và yêu cầu chéo tenant đều không được cho phép.

### 9.3. Sinh ma trận, Gherkin, bảng tính

Bảng sau nêu các lệnh sinh số ca, ma trận truy vết, kịch bản Gherkin và bảng tính, theo thứ tự phải chạy sau mỗi lần sửa ca.

| Lệnh | Kết quả |
|---|---|
| `python3 ph12/tools/number_tcs.py` | Cấp số `TC-12-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph12/tools/fill_doc.py` | Ghi bảng kịch bản (3.1), số kịch bản, số ca, ma trận mục 8 |
| `python3 ph12/tools/gen_matrix.py` | In mục 8; stderr liệt kê BR, ERR, NFR, API, UC, UI chưa có ca |
| `python3 ph12/tools/gen_gherkin.py` | `ph12/gherkin/ts-12-nn.feature` |
| `python3 ph12/tools/gen_xlsx.py` | `ph12/D05-02-PH12-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

## 10. Đề nghị đồng bộ

Danh sách sau gom các đề nghị với tài liệu chung và các tập khác để đợt đồng bộ cuối xử lý, vì tập này không sửa tài liệu chung.

- D05-01: thêm nhóm "fail-closed và cách ly tenant của PH-12" vào cổng RG-3 như điều kiện chặn.
- D03-04-PH12: bổ sung đường dẫn riêng cho ca đo `iam_decisions_total` nếu chưa có API đọc bộ đếm.
- D02-08: bổ sung định nghĩa các quyền `PERM-12-*` mà FRS D02-03-PH12 đã dùng (`client`, `decision-read`, `jit-request`, `jit-approve`, `mfa-reset`, `policy-edit`, `policy-approve`, `realm-admin`, `recert`, `sod-exception`, `user-lock`…); ca TC-12 dùng tên quyền theo FRS.
- Đồng hồ điều khiển được ở SIT (`clock-skew`) cần được D04 ghi thành yêu cầu môi trường kiểm thử.

## Câu hỏi mở

> **Câu hỏi mở Q12-40:** Có cần thử nghiệm xâm nhập độc lập cho PH-12 trước RG-3 (NFR-12-022 nêu "chậm nhất trước phát hành")? Giả định: có, chạy song song UAT.

> **Câu hỏi mở Q12-41:** Bộ dữ liệu LDAP, SAML giả lập (`SIM-LDAP`, `SIM-SAML-SP`) có đại diện cho thiết bị của tỉnh thí điểm thật không? Giả định: đại diện cho OpenLDAP và Keycloak SAML; tỉnh dùng Active Directory cần ca bổ sung khi có dữ liệu.

> **Câu hỏi mở Q12-42:** Có chạy ca VNeID (TC-12 của FR-12-028) ở RG-3 khi tính năng là Đợt 2 mức C? Giả định: chỉ kiểm bằng `SIM-VNEID`, không chặn phát hành MVP.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: kịch bản và test case chức năng, phi chức năng, UAT tương đương hệ IAM cũ, ma trận truy vết sinh tự động |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: tầng kiểm thử CSDL ghi ph12_isolation_test.sql và TenantIsolationIT |
