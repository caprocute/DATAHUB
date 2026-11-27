---
ma_tai_lieu: D03-02-PH12
ten: Thiết kế chi tiết phần mềm phân hệ PH-12 Định danh và phân quyền
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kỹ sư hạ tầng định danh, kiến trúc sư ATTT, kiểm thử viên, hội đồng thẩm định
phan_he: PH-12
mo_ta: Thiết kế chi tiết phần mềm của phân hệ định danh và phân quyền gồm thành phần, cấu trúc mã, trình tự xử lý, máy trạng thái, bảo mật, quan sát, đủ để lập trình và kiểm thử 62 chức năng.
tai_lieu_lien_quan: D03-01 SAD; D02-03-PH12 FRS; D02-04-PH12 Use case; D03-03-PH12 CSDL; D03-04-PH12 API; D03-07 ATTT; D03-10 Đa tenant; D02-08 Ma trận phân quyền
---

# D03-02-PH12 · Thiết kế chi tiết Định danh và phân quyền

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả cách hiện thực 62 chức năng (FR) của [D02-03-PH12](../../02-yeu-cau/frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) và 42 use case của [D02-04-PH12](../../02-yeu-cau/use-case/D02-04-PH12-use-case-dinh-danh-phan-quyen.md) thành phần mềm chạy được. PH-12 trả lời hai câu hỏi cho mọi truy cập vào Datahub: "người gọi là ai" (Keycloak xác thực) và "người gọi được làm gì" (Open Policy Agent, viết tắt OPA, quyết định ủy quyền). Thiết kế nói rõ phần nào là cấu hình Keycloak, phần nào là mã Java trong `dh-platform`, phần nào là chính sách Rego, và ranh giới giữa chúng.

**Phạm vi.** Phân hệ gồm ba đơn vị triển khai: `keycloak` (Keycloak 26 kèm bộ mở rộng nhỏ), `opa` (sidecar cạnh APISIX và cạnh mọi đơn vị triển khai khác, viết tắt DU) và module `iam` trong `dh-platform` (Spring Boot 4, Spring Modulith). Phân hệ là điểm quyết định chính sách (PDP) và nơi phát hành định danh; việc thực thi quyết định (PEP) nằm ở APISIX (PH-03) và ở thư viện PEP dùng chung trong từng DU, do PH-12 cung cấp.

**Căn cứ.** CMP-LAW-09 (Công văn 631: SSO bằng SAML 2 và OpenID Connect, xác thực nhiều yếu tố, XACML), CMP-LAW-08 (TCVN 14423:2026 cấp độ 3: mật khẩu 14 ký tự, khóa phiên 15 phút, vô hiệu tài khoản sau 45 ngày), CMP-LAW-05 (Luật BVDLCN 91/2025: ghi vết truy cập). Biện pháp ATTT dẫn từ SEC-20…29, SEC-36, SEC-60…62, SEC-80…88 ở D03-07.

**Những điểm hội đồng cần lưu ý.** Thiết kế dựa trên năm quyết định:

1. **Keycloak giữ danh tính, `ph12_iam` giữ nghiệp vụ.** Người dùng, mật khẩu, yếu tố xác thực, phiên và khóa ký chỉ nằm ở Keycloak (CSDL `pg-iam`, cụm riêng để Keycloak vẫn chạy khi control plane ngừng). Phần Keycloak không có (gán vai trò có phạm vi và thời hạn, quyền có thời hạn, ngoại lệ tách nhiệm vụ, chính sách, cảnh báo) nằm ở schema `ph12_iam`. Mọi lời gọi tới Keycloak đi qua một cổng duy nhất `KeycloakGateway` với tài khoản dịch vụ chỉ có vai trò `realm-user-admin` (SEC-20).
2. **OPA quyết định tại chỗ và từ chối khi lỗi.** OPA là sidecar trong cùng pod với bên thực thi, nên quyết định không đi qua mạng tới control plane. Thời gian chờ 50 ms; lỗi, hết giờ, chưa nạp gói đều thành từ chối (BR-12-006). Quyền hiệu lực là giao của vai trò trong token và dữ liệu của gói chính sách (BR-12-036).
3. **Chính sách và dữ liệu quyền chỉ đến OPA qua gói đã ký.** Gói được dựng từ ma trận D02-08, gán vai trò và chính sách Rego đã duyệt bốn mắt, ký bằng khóa không xuất được của OpenBao, tải mỗi 30 giây. Thay đổi chính sách đi theo trình tự: kiểm thử, chạy khô trên lưu lượng thật, duyệt bốn mắt, ký, nạp nóng (ADR-069).
4. **Thu hồi bằng mốc `notBefore` và danh sách chặn kéo.** Thu hồi vô hiệu đối tượng ở Keycloak và đẩy mốc thời gian tới APISIX; cổng từ chối mọi token cấp trước mốc trong không quá 60 giây, không chờ token hết hạn 5 phút.
5. **Cấu hình bảo mật realm do GitOps giữ.** Quản trị tỉnh không sửa được MFA, thời hạn token, grant cho phép; hằng giờ hệ thống so realm thực với mẫu Git và tự áp lại khi lệch.

Thiết kế thêm một bộ mở rộng Keycloak nhỏ (hai điểm mở rộng, mục 4.6), một dịch vụ chạy Rego cô lập `policy-runner` và đề xuất thêm ba ADR ngoài bốn ADR đã nêu ở FRS (mục "Đề nghị đồng bộ"); mười câu hỏi mở Q12-20…Q12-29 ở mục 13.3.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Chức năng hiện thực | 62 FR (52 M, 9 S, 1 C), 42 UC |
| Mục thiết kế chi tiết | Mô hình miền và 14 thành phần (mục 4.1…4.15) |
| Biểu đồ tuần tự | 14 (mục 5.1…5.14) |
| Máy trạng thái | 10 đối tượng (mục 8.1) |
| API, sự kiện, lỗi | 113 API (API-12-001…113), 16 sự kiện (EVT-12-01…16), 66 mã lỗi (ERR-12) |
| Biện pháp ATTT tham chiếu | 32 mã SEC dẫn đích danh, 11 mối đe dọa THR |
| Câu hỏi mở của tập | 10 (Q12-20…Q12-29) |

: Con số chính của thiết kế PH-12

## 1. Giới thiệu

### 1.1. Mục đích, phạm vi và cách đọc

Tài liệu đi từ vị trí trong kiến trúc (mục 2), cấu trúc mã (mục 3), từng thành phần (mục 4), biểu đồ tuần tự của các luồng chính (mục 5), tới đa tenant, bảo mật, máy trạng thái, cấu hình, quan sát, hiệu năng và kiểm thử. Hành vi từng chức năng, quy tắc BR, chỉ tiêu NFR và mã ERR là của FRS; sự kiện EVT và API ở `D03-04-PH12`; bảng và cột ở `D03-03-PH12`; màn hình ở `D03-06-PH12`. Tài liệu này không lặp lại các nội dung đó mà chỉ chỉ ra lớp, gói, giao dịch và cơ chế hiện thực. Biện pháp ATTT dẫn mã `SEC-*` đã có ở D03-07, không tạo mã mới.

Hai quy ước đọc. Thứ nhất, "bên thực thi" (PEP) là APISIX hoặc thư viện PEP trong DU; "bên quyết định" (PDP) là OPA. Thứ hai, "gói" là gói chính sách OPA (bundle), khác với "bó" bất kỳ nào khác; "tenant" viết thường trong tên topic và realm (`t68`), viết hoa trong tên hiển thị và dữ liệu (`T68`).

| ADR áp dụng | Nội dung dùng ở đây |
|---|---|
| [ADR-001](../../00-chung/adr/ADR-001-spring-boot-modulith.md) | Spring Boot 4 và Spring Modulith cho `dh-platform`; module `iam` |
| [ADR-003](../../00-chung/adr/ADR-003-postgresql-rls-da-tenant.md) | PostgreSQL, RLS theo `tenant_id` cho `ph12_iam` |
| [ADR-004](../../00-chung/adr/ADR-004-kafka-thay-pulsar.md) | Kafka cho EVT-12-* |
| [ADR-005](../../00-chung/adr/ADR-005-apisix-gateway.md), [ADR-033](../../00-chung/adr/ADR-033-lop-bien-apisix-coraza.md) | APISIX là PEP tại cổng; điểm cuối OIDC công bố qua APISIX |
| [ADR-006](../../00-chung/adr/ADR-006-keycloak-opa.md) | Keycloak xác thực, OPA quyết định, realm theo tenant, tắt grant `password` |
| [ADR-009](../../00-chung/adr/ADR-009-gitops-argo-cd.md), [ADR-068](../../00-chung/adr/ADR-068-kho-cau-hinh-git-theo-tenant.md) | Mẫu realm và chính sách giữ ở Git; cấu hình theo tenant |
| [ADR-012](../../00-chung/adr/ADR-012-openbao-bi-mat.md) | OpenBao: ký gói, bí mật bọc dùng một lần, bí mật liên kết LDAP |
| [ADR-013](../../00-chung/adr/ADR-013-tach-control-data-plane.md) | Keycloak và OPA ở data plane, quản trị ở control plane |
| [ADR-031](../../00-chung/adr/ADR-031-nhat-ky-kiem-toan-chuoi-bam-worm.md) | Quyết định từ chối và thay đổi quyền vào chuỗi băm kiểm toán |
| [ADR-041](../../00-chung/adr/ADR-041-idempotency-va-chong-trung.md), [ADR-042](../../00-chung/adr/ADR-042-inbox-outbox-trong-du.md) | `Idempotency-Key` và outbox cùng giao dịch |
| [ADR-069](../../00-chung/adr/ADR-069-may-trang-thai-phien-ban-va-bon-mat.md) | Máy trạng thái phiên bản chính sách, bốn mắt chốt ở máy chủ |
| ADR đề xuất (a)…(g) | Mục "Đề nghị đồng bộ": liên tenant, chính sách chỉ thêm luật chặt, dữ liệu quyền thành gói ký, thu hồi bằng `notBefore`, bộ mở rộng Keycloak, ký gói bằng khóa transit, chạy Rego cô lập |

: ADR áp dụng cho PH-12

### 1.2. Người đọc và tài liệu tham chiếu

Tài liệu có bốn nhóm người đọc với nhu cầu khác nhau; bảng đầu chỉ ra mỗi nhóm nên bắt đầu từ chương nào, bảng sau liệt kê các tài liệu gốc mà thiết kế dựa vào và phần được dùng.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-platform` (module `iam`) | Chương 3, 4.1…4.4, 4.7…4.10, 4.13…4.15, 6, 8, 9 |
| Kỹ sư hạ tầng định danh (Keycloak, SPI, GitOps realm) | Chương 4.5, 4.6, 4.10, 5.1, 5.8, 8.3, 11 |
| Kỹ sư chính sách, thư viện PEP, APISIX | Chương 4.11…4.13, 5.4, 5.5, 8.3 |
| Cán bộ ATTT, kiểm thử viên | Chương 7, 8, 12 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 5, 13 |

: Người đọc và phần cần đọc

| Tài liệu tham chiếu | Dùng ở đây |
|---|---|
| [D02-03-PH12](../../02-yeu-cau/frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) FRS | 62 FR, 45 BR, 33 NFR, 66 mã ERR, 16 EVT, 113 API, tham số `12.*`, máy trạng thái |
| [D02-04-PH12](../../02-yeu-cau/use-case/D02-04-PH12-use-case-dinh-danh-phan-quyen.md) Use case | 42 use case làm đầu vào cho các luồng ở chương 5 |
| [D02-08](../../02-yeu-cau/D02-08-ma-tran-phan-quyen.md) Ma trận phân quyền | 22 vai trò, quyền `PERM-*`, bảy cặp xung đột, scope của máy; nguồn của `roles.json` và `permissions.json` |
| [D03-01 SAD](../D03-01-sad.md) §4 | DU `keycloak`, `opa`, `dh-platform` và vùng mạng |
| [D03-07 ATTT](../attt/D03-07-thiet-ke-attt.md) | SEC-19…29, SEC-36, SEC-60…65, SEC-80…87; mối đe dọa THR |
| [D03-10 Đa tenant](../D03-10-thiet-ke-da-tenant.md) §3, §5 | Xác định tenant từ token, saga khởi tạo tenant, sáp nhập |
| [D03-09 Hạ tầng](../ha-tang/D03-09-ha-tang-trien-khai-dr.md) §5, §6 | Định cỡ, Keycloak, `pg-iam`, OPA, namespace |
| D03-03-PH12, D03-04-PH12, D03-06-PH12 | CSDL, API, màn hình của chính phân hệ (do các tập tương ứng viết) |

: Tài liệu tham chiếu của thiết kế PH-12

### 1.3. Thuật ngữ và chữ viết tắt

Thuật ngữ chung theo D00-01 và FRS §1.4. Bảng dưới chỉ liệt kê những từ có nghĩa riêng hoặc dễ hiểu nhầm trong thiết kế này.

| Thuật ngữ | Nghĩa dùng trong tài liệu |
|---|---|
| PEP, PDP | Điểm thực thi, điểm quyết định chính sách. PEP chuyển yêu cầu tới PDP và thi hành kết quả |
| Gói chính sách (bundle) | Tệp nén chứa Rego và dữ liệu JSON, có chữ ký, OPA tải theo chu kỳ |
| `bundleRevision` | Mã bản gói đang chạy, ghi vào mọi quyết định để truy vết và vô hiệu bộ đệm |
| `notBefore` | Mốc thời gian: token có `iat` trước mốc bị từ chối; mục thu hồi có thêm cờ `blockAll` khi Keycloak chưa xác nhận |
| SPI | Giao diện mở rộng của Keycloak (Service Provider Interface), chạy trong tiến trình Keycloak |
| JIT | Quyền có thời hạn (just-in-time), tối đa 4 giờ |
| `acr` | Claim mức xác thực trong token (1, 2, 3 theo FRS mục 4.8) |

: Thuật ngữ dùng riêng trong tài liệu

### 1.4. Cấu trúc tài liệu

Tài liệu có mười ba chương theo khuôn K-SDD. Mỗi thành phần ở chương 4 mở đầu bằng bảng đặc tả 10 mục (Mục đích, Lớp chính, Đơn vị chạy, FR hiện thực, Giao diện vào, Phụ thuộc ra, Dữ liệu, Sự kiện, Lỗi và xử lý, Quan sát), sau đó là chi tiết thiết kế.

Bảng dưới là bản đồ từ nhóm chức năng của FRS tới mục thiết kế, biểu đồ tuần tự và use case; mọi FR trong 62 FR đều được hiện thực ở ít nhất một mục chương 4.

| Nhóm FRS | FR | Mục thiết kế | Tuần tự | Use case |
|---|---|---|---|---|
| A Tài khoản người dùng | FR-12-001…010 | 4.2 (cùng 4.5) | 5.9, 5.11 | UC-12-01…07 |
| B Vai trò, nhóm, quyền | FR-12-011…016 | 4.3 | 5.6 | UC-12-08…12 |
| B Quyền có thời hạn, rà soát, sáp nhập | FR-12-017, 018, 019 | 4.4, 4.10 | 5.7 | UC-12-13…15 |
| C Xác thực người dùng | FR-12-020…024, 027, 029 | 4.6, 4.4 (FR-12-027), 4.2 (phiên) | 5.1, 5.7, 5.14 | UC-12-13 (FR-12-027), 16…18, 20 |
| C Liên kết định danh ngoài | FR-12-025, 026, 028 | 4.7 | 5.12 | UC-12-19 |
| D Danh tính HTTT | FR-12-030…037 | 4.8 | 5.2, 5.10 | UC-12-21…26 |
| D Token, khóa ký, thu hồi | FR-12-038…040 | 4.9 | 5.3 | UC-12-16, 27, 28 |
| E Realm theo tenant | FR-12-041…043 | 4.10 | 5.8 | UC-12-29, 30 |
| F Quyết định ủy quyền | FR-12-044…050 | 4.11 | 5.4 | UC-12-31, 32 |
| F Dữ liệu quyền và gói | FR-12-051 | 4.12 | 5.2, 5.5 | UC-12-33 |
| F Vòng đời chính sách | FR-12-052…055 | 4.13 | 5.5, 5.13 | UC-12-34…36 |
| G Ghi vết, giám sát | FR-12-056…060 | 4.14 | 5.4 | UC-12-37…40 |
| H Quản trị | FR-12-061, 062 | 4.15 | — | UC-12-41, 42 |

: Bản đồ nhóm chức năng tới mục thiết kế

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-12 trải trên ba vùng mạng vì mỗi phần có yêu cầu khác nhau: nơi giữ danh tính cần cách ly cao (Z6), nơi quản trị nghiệp vụ là control plane (Z3), nơi quyết định phải nằm cạnh lưu lượng (Z2, Z3, Z4). Bảng sau liệt kê từng thành phần với DU và vùng.

| Thành phần | DU | Vùng | Ghi chú |
|---|---|---|---|
| Keycloak 26 và bộ mở rộng `dh-keycloak-spi` | `keycloak` (namespace `dh-iam`) | Z6 | 3 bản sao (6 ở `QM-CHUNG`), phiên bền vào CSDL, Infinispan chỉ là bộ đệm; console quản trị chỉ từ Z7 (SEC-20); `TPH-0` |
| `pg-iam` | Nền tảng (`dh-db`) | Z6 | Cụm CNPG riêng 3 instance, RPO ≤ 15 phút, RTO ≤ 1 giờ (NFR-12-016); tách khỏi `pg-core` để Keycloak sống khi control plane ngừng (NFR-12-013) |
| Module `iam` (API quản trị, nghiệp vụ, bộ ghi chính sách, bộ phát hiện bất thường) | `dh-platform` (namespace `dh-control`) | Z3 | Chung DU với PH-11, 13, 16, 18, 20, khác module Modulith |
| `policy-runner` (chạy `opa test`, `opa build`, chạy khô) | `dh-platform`, vai trò `runner` | Z3 | Deployment 2 bản sao, không có thông tin xác thực CSDL, không có đường ra mạng (mục 4.13) |
| Job `keycloak-config-cli` | Ảnh `dh-iam-provisioner` | Z6 | Do `dh-platform` tạo theo yêu cầu bằng quyền K8s tối thiểu; giữ thông tin xác thực quản trị tạo realm (Q12-29) |
| OPA sidecar | `opa` | Z2 (pod APISIX), Z3 và Z4 (pod DU) | Không trạng thái dùng chung; gói lưu bền ra đĩa pod |
| Thư viện PEP `vn.datahub.common.authz` | Thư viện chung (`libs/common-java`) | Z3, Z4 | Do PH-12 sở hữu; có hai lớp vỏ: Spring Boot và Quarkus |
| Plugin APISIX `dh-authz` | `apisix` (PH-03 hiện thực theo hợp đồng PH-12) | Z2 | Dựng `input` từ JWT và siêu dữ liệu route, gọi OPA cục bộ |
| OpenBao | Nền tảng (`dh-secrets`) | Z6 | Khóa ký gói `transit/keys/dh-policy-signing`, bí mật bọc `sys/wrapping`, bí mật liên kết LDAP |
| Kho gói `dh-platform-policy` | Garage (`dh-s3`) | Z5 | Bucket chung nền tảng; OPA đọc, `dh-platform` ghi |
| Schema `ph12_iam` | Nền tảng (`pg-core`) | Z5 | Cụm CNPG chung control plane |
| Bộ thu nhật ký quyết định | OTel Collector, Fluent Bit (`dh-obs`) | Z7 | Hàng đợi bền trên nút 24 giờ; ra Loki và PH-13 |

: Đơn vị triển khai và vùng mạng

Hai điểm cần nhớ. Một là `dh-platform` ở control plane có thể ngừng bảo trì mà APISIX, Keycloak và OPA vẫn phục vụ nhờ gói đã nạp và JWKS đã đệm (NFR-12-013); chỉ các thao tác quản trị (cấp client, gán vai trò, soạn chính sách) dừng. Hai là Keycloak ở Z6 không nhận lưu lượng trực tiếp từ Internet: điểm cuối OIDC của realm được công bố qua APISIX ở Z2, có giới hạn tần suất theo client (`12.client.token-rate-limit`).

### 2.2. Sơ đồ thành phần

Sơ đồ chia các thành phần theo vùng mạng và vẽ hướng gọi giữa chúng, để thấy thành phần nào nằm trên đường dữ liệu (xác thực và quyết định) và thành phần nào chỉ là quản trị.

```{.mermaid caption="Sơ đồ thành phần của PH-12"}
flowchart TB
  subgraph Z2["Z2 · cổng"]
    BFF["BFF dh-console<br/>và dh-portal"]
    GW["APISIX<br/>plugin dh-authz"]
    OPA1["OPA sidecar"]
  end
  subgraph Z3["Z3 · dh-platform và các DU"]
    WEB["web<br/>/api/iam/v1<br/>/api/authz/v1"]
    SVC["Dịch vụ của module iam<br/>user, assignment, grant, recert,<br/>client, revocation, realm,<br/>policy, bundle, audit, alert"]
    KG["KeycloakGateway"]
    RUN["policy-runner"]
    OBX["Outbox"]
    DU["DU khác<br/>thư viện PEP"]
    OPA2["OPA sidecar"]
  end
  subgraph Z6["Z6 · định danh và bí mật"]
    KC["Keycloak<br/>dh-keycloak-spi"]
    PGI[("pg-iam")]
    JOB["Job<br/>keycloak-config-cli"]
    BAO[("OpenBao")]
  end
  PGC[("pg-core<br/>ph12_iam")]
  S3[("Garage<br/>dh-platform-policy")]
  KF[("Kafka")]
  OBS[("Loki, PH-13")]
  BFF -->|"OIDC, PKCE"| KC
  GW -->|"JWKS đệm"| KC
  GW --> OPA1
  DU --> OPA2
  WEB --> SVC
  SVC --> KG
  KG -->|"Admin API"| KC
  SVC -->|"tạo Job"| JOB
  JOB --> KC
  KC --> PGI
  SVC --> PGC
  SVC -->|"ký gói, bọc bí mật"| BAO
  SVC -->|"chạy Rego"| RUN
  SVC -->|"đặt gói"| S3
  S3 -->|"tải mỗi 30 giây"| OPA1
  S3 -->|"tải mỗi 30 giây"| OPA2
  SVC --> OBX
  OBX --> KF
  KC -.->|"sự kiện xác thực"| KF
  GW -->|"kéo mốc thu hồi, 10 giây"| WEB
  OPA1 -->|"nhật ký quyết định"| OBS
  OPA2 -->|"nhật ký quyết định"| OBS
```

Sơ đồ cho thấy ba đường. Đường xác thực: người dùng qua BFF tới Keycloak, máy qua APISIX tới Keycloak; APISIX chỉ dùng JWKS đã đệm nên không gọi Keycloak ở mỗi lượt. Đường quyết định: bên thực thi hỏi OPA trong cùng pod; OPA chỉ phụ thuộc gói trong Garage, không có mũi tên nào từ OPA tới `dh-platform`. Đường quản trị: giao diện gọi `web`, các dịch vụ của module `iam` ghi `ph12_iam`, thao tác Keycloak đi qua `KeycloakGateway`, thao tác bí mật đi qua OpenBao. Mũi tên "kéo mốc thu hồi" là đường duy nhất từ cổng quay về `dh-platform` ở chế độ chạy bình thường, và nó chỉ đọc một danh sách nhỏ có ETag.

### 2.3. Phụ thuộc với module và phân hệ khác

PH-12 vừa được mọi phân hệ gọi vừa gọi một số phân hệ để lấy dữ liệu nguồn. Bảng dưới nêu từng bên, hướng phụ thuộc và cách gọi.

| Bên | Hướng | Cách | Dùng cho |
|---|---|---|---|
| PH-01 kết nạp HTTT | PH-01 → PH-12 | REST `ClientProvisioningApi` (scope `iam:client-provision`), saga có bù trừ | Tạo, sửa scope, tạm ngừng, thu hồi client (API-12-058…062, 064, 068) |
| PH-02, PH-09, PH-10, PH-19 | PH-12 đọc | Sự kiện nguồn và REST có đệm | Sinh scope của client: đăng ký sử dụng, mục đích, publication, subscription (FR-12-036) |
| PH-07 danh mục đơn vị | PH-12 đọc | `OrgDirectoryApi` (Modulith khi cùng DU, REST khi khác) có đệm 24 giờ | Kiểm đơn vị khi tạo tài khoản, đồng bộ thuộc tính, cây đơn vị cho phạm vi `ORG` |
| PH-15 | PH-15 → PH-12 | REST (scope `iam:dev-client`) | Client sandbox (API-12-063) |
| PH-20 quản trị tenant | PH-20 → PH-12 | REST (scope `iam:realm-provision`), saga | Tạo realm, tạm ngừng, khôi phục, chuyển định danh khi sáp nhập (API-12-045, 046, 080, 084, 085) |
| PH-18 | PH-12 đọc | `ParameterApi` có đệm 60 giây | Tham số `12.*`, hạn mức `maxUsers` của tenant |
| PH-13 giám sát | PH-12 gửi | Sự kiện EVT-12-*, nhật ký quyết định, bản ghi kiểm toán | Cảnh báo, chuỗi băm kiểm toán, tra cứu |
| PH-03 | PH-03 → PH-12 | Plugin `dh-authz`; kéo `GET /revocations` (scope `iam:revocation-read`) | PEP tại cổng; danh sách chặn |
| Mọi DU | DU → PH-12 | Thư viện PEP; `GET /directory/users` (scope `iam:directory-read`) | Quyết định tại chỗ; danh bạ người dùng |
| Hộp việc chung (FR-00-070) | PH-12 gửi | `TaskInboxApi` | Việc duyệt: ngoại lệ tách nhiệm vụ, quyền có thời hạn, chính sách, rà soát |

: Phụ thuộc với module và phân hệ khác

Module `iam` chỉ phụ thuộc module khác của `dh-platform` qua gói `api` công bố: `tenant` (PH-20, bản ghi tenant và trạng thái), `settings` (PH-18), `audit` (PH-13). Luật Modulith: `iam` không import `*.internal` của module nào; các module khác chỉ import `iam.api`. ArchUnit kiểm ở CI (CI-3). Khác PH-05, mọi phân hệ khác gọi PH-12 qua REST hoặc thư viện PEP chứ không qua tiến trình, vì chúng nằm ở DU khác.

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện có một resource server Spring Security tối thiểu và một Keycloak chạy bằng docker compose; chưa có OPA, Rego, kho chính sách hay schema `ph12_iam`. Bảng dưới nêu khoảng cách và cách chuyển.

| Hiện trạng repo | Thiết kế | Khoảng cách |
|---|---|---|
| `apps/control/.../SecurityConfig.java`: `oauth2ResourceServer` JWT, đọc vai trò từ `realm_access.roles` thành `ROLE_*`, CSRF tắt, không kiểm tenant | Thư viện PEP `vn.datahub.common.authz`: kiểm `iss` theo realm, claim `tenant`, gọi OPA; quyền theo `PERM-*` | GAP-12-01: thay `extractAuthorities` bằng `DhAuthorizationManager`; bỏ vai trò thô khỏi `GrantedAuthority`; thêm bộ lọc `TenantContextFilter` (D03-10 §3) |
| `deploy/compose/docker-compose.yml`: Keycloak 26.2 nạp `realm-lgsp.json`, một realm `lgsp`, quản trị `admin/admin_dev_change_me` | Realm `dh-{tenant}` tạo từ mẫu `dh-realm-template` bằng `keycloak-config-cli`; mẫu ở Git | GAP-12-02: thêm mẫu realm và bản compose dev dùng chính mẫu đó; bỏ tệp realm cũ sau khi chuyển người dùng thử |
| `deploy/base/control-deployment.yaml`: issuer `http://keycloak:8080/realms/lgsp` | Issuer theo tenant, cấu hình `JwtDecoder` nhiều issuer (`JwtIssuerAuthenticationManagerResolver`) giới hạn theo danh sách realm | GAP-12-03 |
| SRS cũ `docs/07-srs/SRS-PH-12-iam.md`: đường dẫn `/api/admin/v1/iam`, vai trò `IAM_ADMIN`, `SECURITY_OFFICER` | `/api/iam/v1`, `PERM-12-*`, vai trò chuẩn D02-08 | GAP-12-04: ánh xạ ở FRS 11.4; không dùng lại đường dẫn cũ |
| `OnboardingService` (PH-01) dựng bí mật niêm phong tại chỗ cho môi trường DEV | PH-01 gọi API-12-058; bí mật bọc dùng một lần ở OpenBao | GAP-12-05: thay đoạn DEV bằng lời gọi `ClientProvisioningApi`, giữ bản giả lập cho CI |

: Hiện trạng mã và đường chuyển

## 3. Cấu trúc mã nguồn

PH-12 sinh ra bốn sản phẩm mã: module `iam` trong `dh-platform`, thư viện PEP dùng chung, bộ mở rộng Keycloak và kho chính sách Rego. Mỗi sản phẩm có gói, vòng phát hành và người kiểm tra riêng nên được tách rõ ở đây.

### 3.1. Module `iam` trong `dh-platform`

Module `iam` là phần mã Java của phân hệ, tổ chức thành các gói con theo năng lực nghiệp vụ; chỉ gói `api` được các module khác import.

```text
vn.datahub.platform.iam
    api/                       # công bố cho module và phân hệ khác: IamDirectoryApi, ClientProvisioningApi, RealmProvisioningApi, RevocationQueryApi, ScopeSourcePort, DTO
    web/                       # @RestController /api/iam/v1 và /api/authz/v1 (decide dự phòng), ProblemDetail ERR-12-*
    internal/
        keycloak/              # KeycloakGateway, AdminClient (resilience4j), ConfigCliJobRunner, SyncReconciler, KeycloakEventConsumer
        user/                  # UserAccount (bản chiếu), UserService, UserStateResolver, ImportService, InactivityJob, OrgSyncJob
        role/                  # RoleCatalog (nạp roles.json sinh từ D02-08), CustomRole, EffectivePermissionService
        assignment/            # RoleAssignment, AssignmentService, SodGuard, SodException, SodRuleSet
        group/                 # OrgGroup, GroupService, CycleChecker
        grant/                 # PrivilegedGrant, GrantService, GrantExpiryJob
        recert/                # RecertCampaign, RecertItem, RecertScheduler, RecertReminder
        federation/            # LdapFederation, SamlClient, VneidLink, FederationApprovalService
        client/                # Client, ClientService, ScopeSynchronizer, SecretHandover (OpenBao wrap), ServiceAccount, InactivityJob
        token/                 # KeyRotationMonitor, RefreshReuseConsumer, JwksProbe
        revocation/            # RevocationEntry, RevocationService, RevocationFeed, AppliedNodeTracker
        realm/                 # Realm, RealmProvisioner, DriftDetector, TenantIdentityMerge
        policy/                # Policy, PolicyVersion (máy trạng thái), TestCase, PolicyLinter, DryRunService, ApprovalService, GitMirror
        bundle/                # PolicyDataGenerator, BundleBuilder, BundleSigner (OpenBao transit), BundleRegistry (S3), BundleAckTracker
        runner/                # PolicyRunnerClient (gọi policy-runner qua mTLS)
        audit/                 # SecurityEventConsumer, DecisionQueryService (LogQL), AuditWriter (thư viện dh-audit)
        alert/                 # AlertEngine, RuleSet AN-01…09, AlertDeduplicator
        report/                # AccountReport, MfaCoverageReport (bảng tổng hợp hằng ngày)
        directory/             # DirectoryService
        settings/              # Tham số 12.*, SettingsGuard (trần nền tảng)
    events/                    # EVT-12-* record, OutboxPublisher
```

Tách `keycloak/` khỏi mọi gói khác là quy tắc cứng: chỉ gói này import thư viện `keycloak-admin-client`; ArchUnit cấm gói khác import `org.keycloak.*`. Nhờ vậy khi nâng cấp Keycloak (26.x) chỉ phải sửa một nơi, và kiểm thử đơn vị của các dịch vụ khác dùng được `FakeKeycloakGateway`.

### 3.2. Thư viện PEP, bộ mở rộng Keycloak, kho chính sách

Ba sản phẩm mã còn lại của phân hệ nằm ngoài module `iam` vì có vòng phát hành và nơi chạy riêng.

```text
vn.datahub.common.authz                    # thư viện PEP (libs/common-java), do PH-12 sở hữu
    core/        # DecisionRequest, DecisionResult, Obligation, FieldMask, Reason
    input/       # InputBuilder (từ Jwt và ResourceDescriptor), ResourceResolver (SPI do từng DU hiện thực)
    client/      # OpaClient (HTTP tới 127.0.0.1:8181, timeout 50 ms, không thử lại), AuditGate, DecisionCache
    revocation/  # BlocklistCache, RevocationListener (nghe EVT-12-05)
    spring/      # DhAuthorizationManager, @RequiresPermission, PepWebFilter, MaskingAdvice
    quarkus/     # PepJaxRsFilter (cho dh-runtime, ADR-002)
    test/        # FakeOpa, PolicyFixtures

vn.datahub.keycloak.spi                    # dh-keycloak-spi (JAR nạp vào ảnh Keycloak tùy biến)
    events/      # KafkaEventListenerProviderFactory   → EVT-12-16, sự kiện quản trị
    auth/        # UniformLoginFormAuthenticatorFactory → BR-12-017 (phản hồi không phân biệt tài khoản)

dh-policies/                               # kho Git chính sách (ADR-068), nhánh main bảo vệ
    rego/base/                 # gói gốc dh.authz.* của nền tảng
    rego/tenants/{tenant}/     # luật chặt hơn của tỉnh (chỉ deny, obligations)
    data/permissions.json      # sinh từ D02-08 bằng CI, không sửa tay
    tests/                     # *_test.rego: ca dương, ca âm, ca chéo tenant
    capabilities.json          # danh sách hàm được phép, loại http.send, net.lookup_ip_addr, opa.runtime
    .opa-coverage.yaml         # ngưỡng độ phủ 90%
```

Thư viện PEP có hai lớp vỏ cùng một lõi (`core`, `input`, `client`) để Spring Boot (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`, `dh-payment`) và Quarkus (`dh-runtime`) dùng đúng một hợp đồng. Bộ mở rộng Keycloak chỉ có hai điểm mở rộng vì mọi nhu cầu còn lại (ánh xạ claim, MFA có điều kiện, bước lên `acr`, phát hiện dò mật khẩu, chính sách mật khẩu) là cấu hình gốc của Keycloak 26 (mục 4.6).

### 3.3. Giao diện công bố

Các giao diện Java sau là phần công khai của module `iam` (gói `iam.api`); phân hệ cùng DU gọi trong tiến trình, phân hệ khác DU gọi qua bản REST tương ứng.

```java
package vn.datahub.platform.iam.api;

public interface IamDirectoryApi {
  /** FR-12-062. Chỉ thông tin tối thiểu, BR-12-042. Tenant lấy từ TenantContext, không từ tham số. */
  Page<DirectoryEntry> search(DirectoryQuery query, PageRequest page);
  Optional<DirectoryEntry> find(String userId);
}

public interface ClientProvisioningApi {
  /** FR-12-030. Lũy đẳng theo idempotencyKey. Không trả bí mật, chỉ trả tham chiếu bọc. */
  ClientView provision(ProvisionClientCommand cmd, String idempotencyKey);
  /** FR-12-036. Ghi đè tập scope theo nguồn, kiểm nguồn duyệt. */
  ClientView replaceScopes(String clientId, ScopeSource source, Set<ScopeGrant> scopes);
  void suspend(String clientId, String reason);   // FR-12-031
  void resume(String clientId, String reason);
  void revoke(String clientId, String reason);    // FR-12-031, 040
}

public interface RealmProvisioningApi {
  RealmView provision(ProvisionRealmCommand cmd, String idempotencyKey);   // FR-12-041
  void suspend(TenantCode tenant, String reason);                          // FR-12-043
  void resume(TenantCode tenant);
  MergePlan planIdentityMerge(MergeId id);                                 // FR-12-019
  MergeResult executeIdentityMerge(MergeId id, String idempotencyKey);
}

public interface RevocationQueryApi {
  /** FR-12-040. ETag là số phiên bản danh sách, trả 304 khi không đổi. */
  RevocationFeed feed(String ifNoneMatch);
}

/** Cho DU kiểm quyền `PERM-*` mà không dựng input thủ công (PH-13 dùng cho `PERM-13-*`). Bọc `DhAuthorizationManager.check`. */
public interface PermissionApi {
  Decision check(String permission, ResourceRef resource);      // FR-12-044, 045
}

/** Cho DU hỏi mức xác thực của phiên; trả `STEPUP_REQUIRED` kèm `acr_values` khi chưa đủ (RFC 9470, ERR-12-120). */
public interface StepUpApi {
  AuthLevel current();                                          // `acr` và `auth_time` lấy từ token đã xác minh
  void require(int minAcr, Duration maxAge);                    // FR-12-023
}

/** Cổng vào cho PH-02, 09, 10, 19 đẩy dữ liệu đã duyệt để sinh scope (FR-12-036). */
public interface ScopeSourcePort {
  void accept(ScopeSource source, String sourceRef, String clientId, Set<ScopeGrant> grants);
}

public record ProvisionClientCommand(String systemCode, String systemName, String orgCode,
    AuthMethod authMethod, ContractLevel contractLevel, Set<ScopeGrant> scopes,
    String publicJwksJson, String contactEmail) {}
public record ScopeGrant(String scope, ScopeSource source, String sourceRef) {}
```

### 3.4. Hợp đồng quyết định giữa bên thực thi và OPA

Đây là hợp đồng quan trọng nhất của phân hệ (FR-12-044): APISIX, thư viện PEP và API `POST /api/authz/v1/decide` cùng dùng một cấu trúc. Bảng sau ánh xạ từng trường của Java tới `input` của Rego và nêu nguồn của giá trị; nguyên tắc là mọi trường về chủ thể lấy từ token đã xác minh, không từ tham số của bên gọi (BR-12-004).

| Trường `input` | Java | Nguồn giá trị |
|---|---|---|
| `traceId` | `DecisionRequest.traceId` | Tiêu đề `traceparent` (W3C), khớp PH-04 và PH-13 |
| `tenant` | `tenant` | Claim `tenant` của token; không bao giờ từ tiêu đề `X-DH-Tenant` khi gọi từ ngoài mesh |
| `subject.type`, `id` | `Subject.type`, `id` | `USER` nếu có `preferred_username`, `CLIENT` nếu có `azp` và không có người dùng, `SERVICE` nếu client là tài khoản dịch vụ |
| `subject.roles`, `scopes` | `Subject.roles`, `scopes` | Claim vai trò của realm, claim `scope`; OPA lấy giao với dữ liệu gói (BR-12-036) |
| `subject.org`, `acr`, `authTime` | `Subject.org`, `acr`, `authTime` | Claim `org`, `acr`, `auth_time` |
| `subject.grantId` | `Subject.grantId` | Tùy chọn, từ tiêu đề `X-DH-Grant-Id` của API `/api/platform/`; chỉ để ghi vết, OPA không tin mà tra `data.dh.platform.grants` theo (chủ thể, tenant đích) |
| `resource.*` | `Resource` | `ResourceResolver` của DU hoặc siêu dữ liệu route ở APISIX: mã, loại, tenant, đơn vị chủ quản, `classification`, `state`, `createdBy`, `submittedBy` |
| `action`, `permission` | `action`, `permission` | Chú thích `@RequiresPermission("PERM-07-publish")` hoặc `x-datahub-permission` của route |
| `context.purpose`, `caseRef` | `Context.purpose`, `caseRef` | Tiêu đề `X-DH-Purpose`, `X-DH-Case-Ref` hoặc mục đích gắn với đăng ký sử dụng; thiếu thì để trống |
| `context.sourceIp`, `time` | `Context.sourceIp`, `time` | Địa chỉ nguồn thật (từ `X-Forwarded-For` do APISIX đặt), đồng hồ nút |

: Ánh xạ trường hợp đồng quyết định

```java
package vn.datahub.common.authz.core;

public record DecisionRequest(String traceId, String tenant, Subject subject, Resource resource,
                              String action, String permission, Context context) {}

public record DecisionResult(boolean allow, Reason reason, String matchedPolicy, String bundleRevision,
                             Map<String, MaskMode> fieldMask, PrivacyMode privacyMode,
                             List<Obligation> obligations, int evaluationTimeMs) {
  /** Kết quả khi PEP không có câu trả lời của OPA: luôn từ chối, BR-12-006. */
  public static DecisionResult failClosed(Reason cause) {
    return new DecisionResult(false, cause, null, null, Map.of(), PrivacyMode.NONE, List.of(), 0);
  }
}

public enum Reason { MATCHED_POLICY, NO_MATCHING_POLICY, TENANT_MISMATCH, DATA_CLASSIFIED_SECRET,
  PURPOSE_NOT_DECLARED, SCOPE_MISSING, ROLE_MISSING, ORG_SCOPE_MISMATCH, SELF_APPROVAL, STEPUP_REQUIRED,
  CLIENT_SUSPENDED, TENANT_SUSPENDED, GRANT_EXPIRED, AUDIT_UNAVAILABLE, POLICY_ERROR }
public enum MaskMode { FULL, MASKED, HIDDEN }
public record Obligation(ObligationType type, Map<String, Object> params) {} // AUDIT, STEPUP, MASK, TTL
```

Điểm vào OPA là `POST /v1/data/dh/authz/decision`; quy tắc `decision` gom `allow`, `reason`, `matchedPolicy`, `fieldMask`, `privacyMode`, `obligations` thành một tài liệu. Lõi PEP chỉ đọc đúng tài liệu này; giá trị lạ, thiếu trường bắt buộc hoặc `allow` không phải Boolean đều thành `failClosed(POLICY_ERROR)`.

### 3.5. DTO quản trị chính

Các bản ghi (record) dưới đây là DTO đầu vào của những API quản trị quan trọng; ràng buộc khai báo bằng Bean Validation và được kiểm lại ở aggregate.

```java
public record CreateUserRequest(
    @Pattern(regexp = "^[a-z][a-z0-9._-]{2,62}$") String username,
    @NotBlank @Size(max = 200) String fullName,
    @Email String email, @NotBlank String orgCode,
    @Size(max = 200) String title, String managerUserId) {}

public record AssignRoleRequest(@NotBlank String userId, @NotBlank String roleCode,
    @NotNull ScopeType scopeType, String scopeRef, LocalDate validFrom, LocalDate validTo,
    @Size(min = 10, max = 500) String reason) {}

public record SodExceptionRequest(@NotBlank String userId, @NotBlank String roleA, @NotBlank String roleB,
    @Size(min = 30, max = 1000) String reason, @NotNull LocalDate expiresAt) {}   // tối đa 12.sod.exception-max-days

public record PrivilegedGrantRequest(@NotBlank String roleCode, @NotBlank String targetTenant,
    @Min(1) @Max(4) int hours, @Size(min = 30, max = 1000) String reason,
    @Pattern(regexp = "^[A-Z]{2,10}-\\d{1,8}$") String ticketRef) {}

public record PolicyVersionRequest(@NotBlank String content, @Size(max = 2000) String changeNote) {}  // Rego, tối đa 256 KiB

public record RevokeAccessRequest(@NotNull SubjectKind kind, @NotBlank String subjectId,
    @Size(min = 10, max = 500) String reason, boolean revokeRefreshTokens) {}
```

`PolicyVersionRequest.content` bị giới hạn 256 KiB và kiểm tra bằng `PolicyLinter` trước khi chạm `policy-runner` (mục 4.13). `ticketRef` chỉ kiểm định dạng ở bản này (Q12-15 của FRS).

## 4. Thiết kế chi tiết từng thành phần

Chương này gồm mô hình miền (mục 4.1) và mười bốn thành phần (mục 4.2…4.15), theo thứ tự đi từ quản trị người dùng, danh tính máy, tới quyết định ủy quyền và ghi vết. Mỗi thành phần có bảng đặc tả 10 mục rồi phần "Chi tiết thiết kế" nêu lớp, giao dịch, thuật toán và điểm cần chú ý khi lập trình.

### 4.1. Mô hình miền

Miền của PH-12 có bảy aggregate. `UserAccount` giữ cả các gán vai trò, ngoại lệ tách nhiệm vụ của người đó vì invariant tách nhiệm vụ phải kiểm trên toàn bộ tập vai trò của một người trong một giao dịch. `Client` giữ tập scope theo nguồn. `Policy` giữ các phiên bản. `PrivilegedGrant`, `Realm`, `RecertCampaign` và `RevocationEntry` đứng riêng. Mọi aggregate có `tenant_id`, `version` (khóa lạc quan) và được nạp qua repository đã đặt `app.tenant_id` (mục 6).

```{.mermaid caption="Mô hình miền PH-12"}
classDiagram
  class UserAccount {
    +UUID id
    +String tenantId
    +String keycloakId
    +String username
    +String orgCode
    +UserState state
    +Instant lastLoginAt
    +int version
    +disable(reason, actor)
    +reactivate(actor)
  }
  class RoleAssignment {
    +String roleCode
    +ScopeType scopeType
    +String scopeRef
    +LocalDate validFrom
    +LocalDate validTo
    +AssignmentState state
  }
  class SodException {
    +String roleA
    +String roleB
    +LocalDate expiresAt
    +SodState state
    +approve(approver)
  }
  class PrivilegedGrant {
    +String roleCode
    +String targetTenant
    +Instant startsAt
    +Instant expiresAt
    +GrantState state
    +approve(approver)
    +revoke(actor)
  }
  class Client {
    +String clientId
    +String systemCode
    +AuthMethod authMethod
    +ContractLevel contractLevel
    +ClientState state
    +boolean credentialReady
    +suspend(reason)
    +resume(by)
    +revoke(reason)
  }
  class ClientScope {
    +ScopeSource source
    +String scope
    +String sourceRef
  }
  class Policy {
    +String policyCode
    +PolicyScope scope
  }
  class PolicyVersion {
    +int versionNo
    +String contentHash
    +PolicyState state
    +submit(actor)
    +approve(actor)
    +publish(bundleRevision)
  }
  class BundleRelease {
    +String bundleRevision
    +String digest
    +Instant signedAt
    +int ackedNodes
  }
  class RevocationEntry {
    +EntryKind kind
    +String value
    +Instant notBefore
    +Instant expiresAt
  }
  class Realm {
    +String tenantCode
    +RealmState state
    +String gitCommit
    +DriftStatus driftStatus
  }
  UserAccount "1" --> "*" RoleAssignment
  UserAccount "1" --> "*" SodException
  UserAccount "1" --> "*" PrivilegedGrant
  Client "1" --> "*" ClientScope
  Policy "1" --> "*" PolicyVersion
  PolicyVersion "*" --> "1" BundleRelease : nằm trong
```

Hình cho thấy ba nhóm gần như độc lập: nhóm người dùng (trái), nhóm danh tính máy (`Client`) và nhóm chính sách (`Policy` tới `BundleRelease`). Chúng chỉ gặp nhau ở gói chính sách: `PolicyDataGenerator` đọc cả ba nhóm để dựng dữ liệu cho OPA (mục 4.12). Bảng sau liệt kê invariant và nơi chốt; mọi invariant chốt ở máy chủ, giao diện chỉ hiển thị trước.

| Aggregate | Invariant | Mã | Chốt ở |
|---|---|---|---|
| `UserAccount` | Không xóa vật lý, kết thúc là `DISABLED` | BR-12-035 | Không có phương thức xóa; CSDL không có quyền `DELETE` trên `user_account` cho vai trò ứng dụng |
| `UserAccount` | Chuyển trạng thái đúng bảng ở mục 8.1; kích hoạt lại buộc đặt mật khẩu mới | ERR-12-006 | `UserAccount.transitionTo` |
| `UserAccount` | Không tự gán, gỡ vai trò, khóa, đặt lại yếu tố của chính mình | BR-12-033, ERR-12-013 | `UserService`, `AssignmentService` so `actor.id` với `target.id` |
| `UserAccount` | Tenant đã kích hoạt luôn có ít nhất hai `TENANT_ADMIN` hiệu lực (Q403, chốt 27/11/2026); ngoại lệ chỉ cho tự vô hiệu không dùng và khóa do sự cố ATTT | BR-12-033, ERR-12-046 | `AssignmentService.unassign`, `UserService.disable` và `UserService.lock` khóa hàng gán `TENANT_ADMIN` bằng `FOR UPDATE` rồi đếm TA hiệu lực khác; còn dưới hai thì ERR-12-046. `InactivityJob`, thao tác khóa kèm `incidentRef` và bộ tiêu thụ EVT-12-16 (khóa `BLOCKED`) đặt `SET LOCAL ph12.ta_floor_exception` để trigger `tg_user_account_last_admin` cho qua, rồi `AlertEngine` phát cảnh báo khẩn cho SO, PA và tạo việc bổ sung TA |
| `RoleAssignment` | Không giữ cặp vai trò xung đột trừ ngoại lệ còn hiệu lực | BR-12-030, ERR-12-009 | `SodGuard.check` trong giao dịch có khóa hàng người dùng |
| `RoleAssignment` | `PLATFORM_*` chỉ ở tenant `PLATFORM`; phạm vi `ORG` chỉ cho người thuộc đơn vị hoặc cấp dưới | BR-12-031, BR-12-037, ERR-12-010 | `AssignmentService.validate` |
| `SodException` | Tối đa 90 ngày, người đề nghị khác người duyệt; cặp có `AUDITOR` với quyền ghi PH-19 không có ngoại lệ | BR-12-030, ERR-12-008 | `SodException.approve` |
| `PrivilegedGrant` | Tối đa 4 giờ, có mã phiếu, người duyệt khác người đề nghị, tự hết hạn | BR-12-032, ERR-12-030 | `PrivilegedGrant.approve`; hạn còn được OPA kiểm ở mọi quyết định |
| `Client` | Một client cho mỗi HTTT; phương thức xác thực không thấp hơn mức hợp đồng và không hạ từ mức Hạn chế | BR-12-024, ERR-12-018, ERR-12-022 | `Client.create`, `Client.changeAuthMethod`; ràng buộc `UNIQUE (tenant_id, system_code)` |
| `Client` | Scope chỉ do nguồn duyệt sinh ra, mỗi nguồn chỉ đặt loại scope của mình | BR-12-025, ERR-12-019 | `ScopeSynchronizer` kiểm tiền tố theo `ScopeSource` |
| `PolicyVersion` | Gửi duyệt chỉ khi có ca kiểm thử đạt, độ phủ ≥ 90%, đã chạy khô trên đúng `contentHash` | BR-12-009, ERR-12-025, ERR-12-026 | `PolicyVersion.submit` so `contentHash` với kết quả đã lưu |
| `PolicyVersion` | Người duyệt khác người soạn, người đóng góp và người gửi | BR-12-008, ERR-12-008 | `PolicyVersion.approve` |
| `PolicyVersion` | Chính sách của tenant chỉ chứa luật `deny` và `obligations` | BR-12-007, ERR-12-028 | `PolicyLinter` (mục 4.13) |
| `Policy` | Mỗi mã có đúng một phiên bản `PUBLISHED` | BR-12-010 | Chỉ mục duy nhất từng phần `WHERE state = 'PUBLISHED'` |
| `Realm` | Cấu hình bảo mật chỉ đổi qua GitOps; quản trị tỉnh không có `manage-*` | BR-12-038 | `RealmProvisioner` là đường ghi duy nhất; vai trò Keycloak của `dh-platform-iam` |

: Invariant của các aggregate

**Đối chiếu với thiết kế CSDL (D03-03-PH12).** Schema `ph12_iam` có 43 bảng, gồm cả ba bảng không suy ra từ aggregate: `sod_pair` (cặp vai trò xung đột sinh từ D02-08 §4), `legacy_role_map` (ánh xạ vai trò hệ cũ sang vai trò chuẩn) và `shedlock` (khóa tác vụ nền). `SodGuard` kiểm trước để trả thông báo `ERR-12-009`, còn `sod_pair` cùng trigger là bản chốt ở CSDL; tệp `SodRuleSet` vẫn là nguồn sinh và CI so hai nguồn với nhau. `ExceptionTranslator` ánh xạ `SQLSTATE` `P12nn` do trigger ném sang `ERR-12-0nn` theo mục 3.44 của D03-03-PH12. Các bảng `realm_state`, `realm_provision_step`, `tenant_merge_step` và `service_account` mang `tenant_id = 'PLATFORM'`. `revocation_entry.keycloak_confirmed_at` ghi thời điểm Keycloak xác nhận vô hiệu để hạ cờ `blockAll`; mã nhóm `org_group.code` viết hoa; client cấp lại sau khi bị thu hồi mang hậu tố `-r{n}` vì mã cũ không dùng lại.

### 4.2. Quản trị người dùng và vòng đời tài khoản

::: dac-ta
**Mục đích.** Tạo, sửa, khóa, vô hiệu, nhập hàng loạt và tự vô hiệu tài khoản người dùng, giữ Keycloak và bản chiếu `ph12_iam` nhất quán, không bao giờ xóa vật lý.

**Lớp chính.** `UserService`, `UserStateResolver`, `ImportService`, `InactivityJob`, `OrgSyncJob`, `KeycloakEventConsumer`.

**Đơn vị chạy.** `dh-platform` (module `iam`, vai trò `api` và `worker`).

**FR hiện thực.** FR-12-001…010; FR-12-021 (phần khóa tạm); FR-12-029 (phiên).

**Giao diện vào.** API-12-001…012, 016, 017; tác vụ nền; sự kiện EVT-12-16 từ Keycloak.

**Phụ thuộc ra.** `KeycloakGateway`; PH-07 (`OrgDirectoryApi`); bộ quét mã độc DD-12; dịch vụ thư (qua Keycloak); `ParameterApi`.

**Dữ liệu.** `user_account`, `user_import`, `user_import_row`, `sync_task`, `outbox`; Keycloak (nguồn sự thật của thông tin đăng nhập).

**Sự kiện.** EVT-12-01, 02, 04.

**Lỗi và xử lý.** Keycloak lỗi: ERR-12-038, ý định giữ ở `sync_task` và phát lại; đơn vị không hợp lệ: ERR-12-004; thư ngoài miền: ERR-12-005; trùng: ERR-12-002; tệp sai: ERR-12-035.

**Quan sát.** `iam_users_total{state}`, `iam_inactive_disabled_total`, `iam_import_rows_total{result}`, `iam_keycloak_sync_pending`.
:::

Chi tiết thiết kế:

Tạo tài khoản dùng mẫu "ghi ý định trước, thực hiện sau" vì Keycloak và PostgreSQL không chung giao dịch. Giao dịch 1 ghi `user_account` (`sync_state = PENDING`, `id` là UUID v7) cùng một dòng `sync_task` mô tả lệnh `CREATE_USER` và bản ghi outbox, rồi commit. Sau commit, `UserService` gọi `KeycloakGateway.createUser` kèm thuộc tính `dh_user_id = id` để tra ngược được. Thành công thì giao dịch 2 điền `keycloak_id`, đặt `sync_state = SYNCED`. Nếu tiến trình chết giữa hai bước, `SyncReconciler` (mỗi phút) lấy `sync_task` quá 30 giây và phát lại: nó tra Keycloak theo `dh_user_id` trước khi tạo, nên không bao giờ tạo trùng. API trả `201` sau giao dịch 2; nếu Keycloak chậm quá 5 giây, API trả `202` kèm tình trạng `PENDING` thay vì treo.

`UserStateResolver` dựng trạng thái hiển thị từ ba nguồn vì Keycloak không có khái niệm `LOCKED` hay `BLOCKED` như FRS: `enabled` và thuộc tính `dh_disabled_reason` cho `DISABLED`, hành động bắt buộc `UPDATE_PASSWORD` còn treo cho `PENDING_ACTIVATION`, và kết quả `attack-detection/brute-force/users/{id}` cho `LOCKED` (khóa tạm) và `BLOCKED` (khóa hẳn do Keycloak đặt `enabled=false` kèm thuộc tính `dh_blocked=true` qua bộ lắng nghe sự kiện). Kết quả được lưu ở cột `state` của bản chiếu mỗi khi có sự kiện; màn hình danh sách (FR-12-001) đọc bản chiếu, màn chi tiết (FR-12-002) hỏi Keycloak để lấy trạng thái tươi.

Tự vô hiệu (FR-12-008) chạy 02:00 mỗi ngày theo từng tenant trong `TenantContext.runAs`. `InactivityJob` chọn tài khoản `ACTIVE` có `last_login_at` quá ngưỡng (`12.account.inactive-days`, quản trị `12.account.inactive-days-admin`) và `created_at` quá ngưỡng cho trường hợp chưa từng đăng nhập. Nguồn `last_login_at` là sự kiện đăng nhập của Keycloak (EVT-12-16), không phải API. Vì vậy trước khi vô hiệu hàng loạt, tác vụ kiểm `iam_auth_event_lag_seconds` của bộ tiêu thụ; nếu trễ quá 3.600 giây, tác vụ bỏ lượt chạy và phát cảnh báo thay vì vô hiệu nhầm người chỉ vì thiếu dữ liệu. Mỗi tài khoản bị vô hiệu đi qua đúng đường của FR-12-005 (đổi trạng thái, hủy phiên, thu hồi) với `actor = SYSTEM` và lý do `INACTIVE_45D` (hoặc `INACTIVE_30D_ADMIN` với vai trò quản trị); tài khoản TA được miễn ngưỡng hai TA của ERR-12-046 (đặt `ph12.ta_floor_exception = 'INACTIVITY'` trong giao dịch) và nếu tenant xuống dưới hai TA thì `AlertEngine` phát cảnh báo khẩn cho SO, PA và tạo việc "Bổ sung quản trị tỉnh" cho PA; sự kiện kiểm toán ghi rõ ngưỡng đã vượt.

Nhập hàng loạt (FR-12-009) theo hai pha (BR-12-043, ADR-056 làm mẫu). Pha 1: tệp qua bộ quét DD-12, đọc luồng bằng SAX (xlsx) hoặc bộ đọc CSV, kiểm từng dòng (miền thư, đơn vị, vai trò hệ cũ có ánh xạ, trùng), ghi `user_import_row` với kết quả `OK`, `WARN`, `ERROR`; tối đa `12.import.max-rows` = 5.000 dòng. Pha 2: khi người dùng xác nhận, các dòng `OK` được tạo bởi `ImportService` chạy nền (4 luồng song song, mỗi lượt tạo đi qua `UserService.create`), tiến độ qua SSE; kết thúc thì gỡ tệp gốc (S3 lifecycle 24 giờ). Mật khẩu không bao giờ có trong tệp; mọi tài khoản tạo ở `PENDING_ACTIVATION` và nhận liên kết kích hoạt.

Kích hoạt và quên mật khẩu (FR-12-006, 007) dùng luồng gốc của Keycloak: hành động bắt buộc `UPDATE_PASSWORD` và `execute-actions-email` với thời hạn `12.activation.ttl-hours`, không có API quản trị tương ứng. Thông báo và thời gian phản hồi không phân biệt tài khoản có tồn tại hay không nhờ bộ xác thực `UniformLoginFormAuthenticator` (mục 4.6, BR-12-017).

`OrgSyncJob` (FR-12-010) nghe sự kiện đổi đơn vị của PH-07; với mỗi người dùng đổi đơn vị, nó cập nhật thuộc tính `orgCode` ở Keycloak và gọi `AssignmentService.revalidateOrgScopes`: gán vai trò phạm vi `ORG` mà đơn vị mới không còn nằm trong cây thì chuyển `EXPIRED` kèm thông báo cho TA.

### 4.3. Gán vai trò, tách nhiệm vụ, nhóm và quyền hiệu lực

::: dac-ta
**Mục đích.** Gán, gỡ vai trò có phạm vi và thời hạn; chặn cặp vai trò xung đột; quản lý nhóm đơn vị và vai trò tùy biến; tính quyền hiệu lực đúng như OPA sẽ tính.

**Lớp chính.** `RoleCatalog`, `AssignmentService`, `SodGuard`, `SodRuleSet`, `GroupService`, `CycleChecker`, `CustomRoleService`, `EffectivePermissionService`.

**Đơn vị chạy.** `dh-platform` (module `iam`).

**FR hiện thực.** FR-12-011…016.

**Giao diện vào.** API-12-013, 019…035.

**Phụ thuộc ra.** `KeycloakGateway` (ánh xạ vai trò); `PolicyDataGenerator` (qua sự kiện nội bộ); OPA cục bộ của `dh-platform` (quyền hiệu lực); hộp việc chung.

**Dữ liệu.** `role_assignment`, `sod_exception`, `org_group`, `org_group_member`, `custom_role`, `custom_role_permission`, `outbox`.

**Sự kiện.** EVT-12-03, EVT-12-12.

**Lỗi và xử lý.** Cặp xung đột: ERR-12-009; vai trò hay phạm vi sai: ERR-12-010; còn dùng: ERR-12-011; vòng lặp: ERR-12-012; tự thao tác: ERR-12-013; thao tác làm tenant còn dưới hai quản trị tỉnh: ERR-12-046 (409), kể cả gỡ vai trò TA; gán `TENANT_ADMIN` sắp hết hạn mà việc hết hạn làm xuống dưới hai TA thì `AssignmentExpiryJob` không đặt `EXPIRED` (trigger chặn), giữ gán và gửi cảnh báo TA, SO, PA.

**Quan sát.** `iam_role_assignments_total{role}`, `iam_sod_blocked_total`, `iam_effective_permission_requests_total`.
:::

Chi tiết thiết kế:

`RoleCatalog` nạp từ `classpath:roles.json`, tệp do CI sinh từ D02-08 (22 vai trò chuẩn, mỗi vai trò có danh sách `PERM`, cờ `mfaRequired`, cờ `privileged`, loại phạm vi cho phép). Vì nó chỉ đọc nên không có API sửa vai trò chuẩn; vai trò tùy biến của tenant (Đợt 2) nằm ở bảng riêng và được hợp vào danh mục khi dựng gói dữ liệu. Cùng tệp `permissions.json` ở kho `dh-policies` là bản đã duyệt của gói gốc; nếu hai tệp lệch nhau thì CI của `dh-platform` đỏ (kiểm tra đồng nhất băm).

`AssignmentService.assign` chạy trong một giao dịch: (1) khóa hàng `user_account` bằng `SELECT … FOR UPDATE` để hai quản trị không gán đồng thời hai vai trò xung đột; (2) nạp các gán đang hiệu lực và ngoại lệ còn hạn của người đó; (3) kiểm vai trò tồn tại, phạm vi hợp lệ, `PLATFORM_*` chỉ ở tenant `PLATFORM`, người nhận thuộc đơn vị của phạm vi `ORG` (BR-12-037), người thao tác không phải người nhận (BR-12-033); (4) `SodGuard.check(existing + new)` so từng cặp ở `SodRuleSet` theo cả hai chiều; (5) ghi `role_assignment` và outbox EVT-12-03. Sau commit, một bộ xử lý đồng bộ tập vai trò vào Keycloak (`setRealmRoles`) và đánh dấu dữ liệu gói của tenant là "bẩn" để `PolicyDataGenerator` dựng lại.

Thời điểm có hiệu lực khác nhau theo chiều thay đổi, đúng BR-12-036. Gỡ hoặc thu hẹp quyền: Keycloak thu hồi phiên của người đó và OPA nhận dữ liệu mới trong ≤ 60 giây; trong khoảng đó token cũ vẫn mang vai trò cũ nhưng OPA lấy **giao** của vai trò trong token với gán trong dữ liệu gói, nên quyền đã gỡ hết hiệu lực ngay khi gói mới được nạp. Nâng quyền: gói mới có gán mới nhưng token cũ chưa mang vai trò, nên quyền chỉ có khi người dùng có token mới (tối đa 5 phút). Cách chọn giao thay vì hợp bảo đảm lỗi nghiêng về phía thiếu quyền, không bao giờ thừa quyền.

`AssignmentExpiryJob` (mỗi phút) tìm gán có `valid_to` đã qua, đặt `EXPIRED` (riêng gán `TENANT_ADMIN`, nếu trigger `tg_role_assignment_last_admin` trả `P1246` vì tenant sẽ còn dưới hai TA thì tác vụ bỏ qua gán đó, ghi cảnh báo cho TA, SO, PA và thử lại ở lượt sau; Rego `assignment_active` vẫn tước hiệu lực ở OPA ngay theo `valid_to`), gỡ vai trò khỏi Keycloak nếu người đó không còn gán nào mang vai trò ấy, rồi kích hoạt dựng gói. Việc hết hạn có hiệu lực ở OPA ngay lập tức vì quy tắc Rego `assignment_active` kiểm `valid_to` ở mọi quyết định; tác vụ nền chỉ dọn dữ liệu.

`SodGuard` đọc bảy cặp xung đột của D02-08 §4 từ `SodRuleSet`. Ngoại lệ (`SodException`) đi theo luồng: TA đề nghị với lý do ≥ 30 ký tự và ngày hết hạn ≤ 90 ngày, SO khác duyệt, hệ thống tự gỡ ngoại lệ và vai trò thứ hai khi hết hạn. Cặp `AUDITOR` với vai trò có quyền ghi của PH-19 được đánh dấu `noException` trong tệp luật và bị chặn ở bước đề nghị (BR-12-030).

Nhóm tổ chức (FR-12-014) lưu bằng kiểu `ltree` của PostgreSQL ở cột `path`; kiểm vòng lặp khi đổi cha bằng điều kiện `new_parent.path <@ node.path` (nếu đúng thì cha mới nằm trong cây con của chính nút, ERR-12-012). Phạm vi `ORG` của một gán được hiểu là mọi nhóm có `path <@ scope.path`; cây này đưa vào gói dữ liệu dưới dạng `org_tree` (mỗi nút kèm danh sách tổ tiên) để OPA không phải tính đệ quy. Vai trò chỉ gán cho người, không gán cho nhóm (BR-12-039).

`EffectivePermissionService` (FR-12-016) không tự cộng quyền bằng mã Java. Nó hỏi OPA sidecar của `dh-platform` quy tắc `data.dh.authz.effective_permissions` trên cùng gói với các DU khác, nên màn "quyền hiệu lực" và quyết định thực tế không thể lệch nhau. Kết quả kèm nguồn gốc từng quyền (vai trò, phạm vi, ngày hết hạn) và chú thích "token chưa phản ánh" khi gán mới hơn token hiện hành.

### 4.4. Quyền có thời hạn và rà soát quyền

::: dac-ta
**Mục đích.** Cấp quyền đặc quyền hoặc truy cập tenant khác trong tối đa 4 giờ với người duyệt thứ hai; rà soát định kỳ quyền của từng người bằng chiến dịch có hạn trả lời.

**Lớp chính.** `GrantService`, `GrantExpiryJob`, `RecertScheduler`, `RecertService`, `RecertReminder`.

**Đơn vị chạy.** `dh-platform` (module `iam`, vai trò `api` và `worker`).

**FR hiện thực.** FR-12-017, 018, 027 (phần liên tenant).

**Giao diện vào.** API-12-036…044; tác vụ nền.

**Phụ thuộc ra.** `PolicyDataGenerator`; hộp việc chung; `AuditWriter` (ghi vào chuỗi của tenant bị truy cập); `NotificationApi`.

**Dữ liệu.** `privileged_grant`, `recert_campaign`, `recert_item`, `outbox`.

**Sự kiện.** EVT-12-11, EVT-12-15.

**Lỗi và xử lý.** Quá 4 giờ hoặc thiếu mã phiếu: ERR-12-030; tự duyệt: ERR-12-008; chiến dịch đang mở: ERR-12-031.

**Quan sát.** `iam_privileged_grants_active`, `iam_recert_overdue_items`.
:::

Chi tiết thiết kế:

Quyền có thời hạn tách hai việc mà dễ gộp nhầm: gán vai trò đặc quyền trong tenant của chính người đó và truy cập sang tenant khác. Với truy cập liên tenant, người dùng nền tảng vẫn đăng nhập ở realm `dh-platform` và token mang `tenant = PLATFORM`; yêu cầu tới tenant đích có `resource.tenant = T68`. Luật `deny TENANT_MISMATCH` bị bỏ qua khi `valid_cross_tenant_grant` đúng, tức là trong `data.dh.platform.grants` có bản ghi `ACTIVE` khớp (chủ thể, tenant đích, vai trò) và `time.now_ns()` nằm giữa `startsAt` và `expiresAt`. Dữ liệu `grants` thuộc gói `platform` (nhỏ, chỉ quyền đang `ACTIVE`) và được mọi OPA nạp, nên APISIX của bất kỳ cụm nào cũng quyết định đúng. Người dùng đăng nhập lại ở tenant đích (FR-12-027) là trường hợp khác: đó là tài khoản riêng của họ ở realm đích, không dùng quyền có thời hạn.

`GrantService.approve` kiểm: người duyệt có `PERM-12-jit-approve`, khác người đề nghị (ERR-12-008), đã xác thực mức 3 trong 5 phút (BR-12-016), `hours ≤ 12.jit.max-hours`. Giao dịch ghi `startsAt = now`, `expiresAt = now + hours`, chuyển `ACTIVE`, ghi outbox EVT-12-11 và một bản ghi kiểm toán vào **chuỗi băm của tenant đích** (SEC-85) chứ không vào chuỗi của người đề nghị; thông báo cho TA của tenant đích đi qua EVT-12-11. Quyền có hiệu lực ở OPA sau khi gói `platform` mới được nạp (≤ 60 giây); giao diện hiển thị "đang chờ hiệu lực" và đếm theo `BundleAckTracker` thay vì báo thành công sớm. Hết hạn không phụ thuộc tác vụ nền: OPA kiểm `expiresAt` ở mọi quyết định (BR-12-032); `GrantExpiryJob` (30 giây) chỉ đổi trạng thái `EXPIRED`, phát sự kiện và dựng lại gói.

Rà soát quyền (FR-12-018, Đợt 2) là một máy trạng thái nhỏ. `RecertScheduler` mở chiến dịch theo chu kỳ (`12.recert.interval-days.admin` 90 ngày cho vai trò quản trị, `…other` 180 ngày cho vai trò khác); mỗi `recert_item` là một cặp (người dùng, gán vai trò) kèm người rà soát. Người rà soát là `managerUserId`; khi trống thì là TA hoặc SO của đơn vị (đề xuất ở Q12-08 của FRS). `RecertReminder` nhắc ở ngày 7 và 12; hết hạn `12.recert.deadline-days` mà không trả lời thì `RecertService.closeExpired` gọi `AssignmentService.unassign(actor = SYSTEM)` cho từng mục chưa trả lời và, với vai trò quản trị, phát cảnh báo mức cao (BR-12-044). Không ai được rà soát quyền của chính mình; việc này kiểm ở `RecertService.decide` bằng cách so `reviewer` với `target`.

### 4.5. Cổng Keycloak

::: dac-ta
**Mục đích.** Là chỗ duy nhất `dh-platform` nói chuyện với Keycloak: gọi Admin API với đúng quyền tối thiểu, chịu lỗi, ánh xạ lỗi, đối soát hai chiều và chạy cấu hình realm bằng công cụ GitOps.

**Lớp chính.** `KeycloakGateway` (giao diện), `AdminClient`, `KeycloakTokenProvider`, `ConfigCliJobRunner`, `SyncReconciler`, `KeycloakEventConsumer`.

**Đơn vị chạy.** `dh-platform`; Job `keycloak-config-cli` ở `dh-iam`.

**FR hiện thực.** Hạ tầng chung của FR-12-003…009, 012, 022…031, 034, 040…043.

**Giao diện vào.** Gọi nội bộ từ các dịch vụ của module `iam`.

**Phụ thuộc ra.** Keycloak Admin API; OpenBao (đọc thông tin xác thực của client quản trị); K8s API (tạo Job); Kafka (sự kiện của Keycloak).

**Dữ liệu.** `sync_task`, `realm_state`; Keycloak.

**Sự kiện.** Không tự phát; tiêu thụ EVT-12-16 của Keycloak.

**Lỗi và xử lý.** Keycloak không phản hồi: ERR-12-038, ngắt mạch; cấu hình đang áp: ERR-12-042; 409 của Keycloak ánh xạ ERR-12-002; 404 ánh xạ ERR-12-001.

**Quan sát.** `iam_keycloak_calls_total{op,result}`, `iam_keycloak_call_duration_seconds`, `iam_keycloak_sync_pending`, `iam_keycloak_circuit_state`.
:::

Chi tiết thiết kế:

Với mỗi realm tenant, `dh-platform` dùng một client `dh-platform-iam` (xác thực `client_credentials`) mang duy nhất vai trò tùy biến `realm-user-admin`, gồm quản lý người dùng, nhóm, ánh xạ vai trò realm và xem sự kiện; không có `manage-realm`, `manage-clients`, `manage-authorization` (SEC-20, BR-12-038). `KeycloakTokenProvider` giữ token theo tenant trong bộ nhớ, làm mới trước hạn 30 giây; thông tin xác thực đọc từ `kv/dh/{tenant}/iam/admin-client` ở OpenBao qua xác thực Kubernetes. Những thao tác cần quyền cao hơn (tạo realm, đổi cấu hình, tạo client) không dùng client này mà chạy qua Job `keycloak-config-cli` hoặc client `dh-client-provisioner` có vai trò `manage-clients` chỉ trong realm của tenant và chỉ `ClientService` được dùng (hai thông tin xác thực khác nhau, hai đường dẫn OpenBao khác nhau). Quyền `manage-clients` này được giới hạn bằng quyền quản trị chi tiết (fine-grained admin permissions v2, có từ Keycloak 26.2) vào các client mang thuộc tính `dh_managed=true`, nên không sửa được `dh-console`, `dh-portal` hay `dh-platform-iam`. Đây là chi tiết thiết kế bổ sung cho FR-12-041 bước 4, nơi FRS chỉ nêu tài khoản `realm-user-admin` (xem "Đề nghị đồng bộ").

Chịu lỗi (mục 8.3): thời gian chờ kết nối 2 giây, đọc 5 giây; `GET` và `PUT` thử lại hai lần với 200 ms rồi 400 ms; `POST` không tự thử lại vì có thể đã thành công, thay vào đó dùng ý định trong `sync_task` (mục 4.2); ngắt mạch mở khi ≥ 50% lỗi trên 10 lượt gần nhất, nửa mở sau 30 giây. Khi ngắt mạch mở, thao tác ghi trả ERR-12-038 ngay, còn thao tác thu hồi vẫn ghi vào danh sách chặn của `ph12_iam` trước (mục 4.9) để cổng chặn dù Keycloak chưa phản hồi.

`ConfigCliJobRunner` tạo một Job Kubernetes ở namespace `dh-iam` từ ảnh `dh-iam-provisioner` (gồm `keycloak-config-cli`, đặt cờ `--import.validate=true` và `--import.managed.*=full` cho mục cấu hình bảo mật để Keycloak xóa phần thừa so với mẫu). ConfigMap của Job ghép hai nguồn: mẫu `dh-realm-template` bản cố định theo `gitCommit` và tệp giá trị của tenant (ADR-068). Pod `dh-platform` chỉ có quyền RBAC `create/get/watch jobs` trong `dh-iam`; thông tin xác thực quản trị Keycloak không nằm trong pod `dh-platform` mà do Job lấy từ OpenBao bằng vai trò Kubernetes `iam-provisioner`. `ConfigCliJobRunner` chờ Job tối đa 4 phút (NFR-12-010 cho phép 5 phút cả khởi tạo realm), đọc kết quả từ nhật ký có cấu trúc của Job và hủy Job quá hạn.

`SyncReconciler` chạy mỗi 5 phút. Nó duyệt `sync_task` còn treo, so tổng số người dùng và client giữa `ph12_iam` và Keycloak theo từng tenant, và sửa lệch theo nguyên tắc: Keycloak đúng với thông tin đăng nhập, `ph12_iam` đúng với vai trò và phạm vi. `KeycloakEventConsumer` đọc EVT-12-16 để cập nhật `last_login_at`, trạng thái `LOCKED`/`BLOCKED`, sự kiện tự phục vụ (đổi mật khẩu, đăng ký yếu tố) và đưa các sự kiện đáng chú ý vào `AlertEngine`.

### 4.6. Mở rộng Keycloak và luồng xác thực

::: dac-ta
**Mục đích.** Hiện thực đăng nhập OIDC với PKCE, MFA có điều kiện, bước lên mức xác thực, chống dò mật khẩu, quản lý phiên và phát token ES256 chủ yếu bằng cấu hình gốc của Keycloak 26, chỉ viết mã cho hai việc cấu hình không làm được.

**Lớp chính.** Mẫu realm `dh-realm-template` (YAML); `KafkaEventListenerProvider`; `UniformLoginFormAuthenticator`.

**Đơn vị chạy.** `keycloak` (ảnh `dh-keycloak` gồm Keycloak 26 và `dh-keycloak-spi`, ký cosign).

**FR hiện thực.** FR-12-020…025, 027, 029, 038, 039.

**Giao diện vào.** Điểm cuối chuẩn OIDC của realm (API-12-072…078).

**Phụ thuộc ra.** `pg-iam`; Kafka (sự kiện xác thực); dịch vụ thư (SMTP); nhà môi giới `dh-platform` (đăng nhập liên tenant).

**Dữ liệu.** `pg-iam` (người dùng, thông tin đăng nhập, phiên, khóa ký); không ghi `ph12_iam`.

**Sự kiện.** EVT-12-16 (do bộ lắng nghe phát, không qua outbox).

**Lỗi và xử lý.** Lỗi OIDC theo RFC 6749 và ghi mã ERR-12-111…125 vào nhật ký; Kafka không nhận: bộ lắng nghe giữ đệm đĩa 64 MiB rồi bỏ sự kiện cũ nhất và tăng chỉ số mất.

**Quan sát.** `iam_login_total{result,method}`, `iam_token_issued_total{grant}`, `iam_active_sessions`, `iam_auth_event_lag_seconds`.
:::

Chi tiết thiết kế:

Bảng sau liệt kê cấu hình bảo mật của mẫu realm; mỗi dòng là thiết lập gốc của Keycloak (không cần mã) và nằm trong phần "quản bằng GitOps" nên quản trị tỉnh không đổi được (BR-12-038).

| Cấu hình realm | Giá trị trong mẫu | Căn cứ |
|---|---|---|
| Chính sách mật khẩu | `length(14) and maxLength(128) and notUsername and notEmail and passwordHistory(5) and passwordBlacklist(dh-breached.txt) and hashAlgorithm(argon2)` | SEC-22, BR-12-018 |
| Phát hiện dò mật khẩu | `failureFactor=5`, chờ 900 giây, `maxTemporaryLockouts=3`, `permanentLockout=true`, `failureResetTime=86400` giây | SEC-22, BR-12-019 |
| Thời hạn token | `accessTokenLifespan=300`; máy không có refresh | SEC-25, BR-12-026 |
| Refresh token | `revokeRefreshToken=true`, `refreshTokenMaxReuse=0` (xoay vòng, dùng lại thì hủy phiên) | SEC-25, FR-12-038 |
| Phiên | `ssoSessionIdleTimeout=900`, `ssoSessionMaxLifespan=36000`, phiên ngoại tuyến tắt | SEC-29, BR-12-022 |
| Grant | Chỉ `authorization_code` (PKCE `S256` bắt buộc), `client_credentials`, `refresh_token`; `directAccessGrantsEnabled=false`, `implicitFlowEnabled=false` | BR-12-021 |
| Đăng ký tự do, đăng nhập mạng xã hội | Tắt | SEC-20 |
| Sự kiện | Bật sự kiện đăng nhập và sự kiện quản trị (kèm chi tiết), bộ lắng nghe `dh-kafka` | SEC-20, SEC-61 |
| Khóa ký | `ecdsa-generated` ES256, xoay 90 ngày, khóa cũ ở trạng thái thụ động 24 giờ | SEC-25, BR-12-027 |
| Ánh xạ claim | `tenant` (giá trị cố định theo realm), `org` (thuộc tính `orgCode`), vai trò realm, `aud` theo nhóm API, `acr`, `auth_time` | SEC-25, BR-12-004 |
| Ánh xạ mức xác thực | `acr_loa_map = {"1":1,"2":2,"3":3}` | FRS mục 4.8 |

: Cấu hình bảo mật của mẫu realm

Luồng xác thực trình duyệt `dh-browser` ghép các bước gốc theo thứ tự: Cookie (SSO), nhà môi giới định danh theo `kc_idp_hint`, rồi biểu mẫu `UniformLoginFormAuthenticator`, sau đó nhánh con có điều kiện. Điều kiện MFA dùng "Condition - User Attribute" trên thuộc tính `dh_mfa_level` (giá trị `2` hoặc `3`), thuộc tính này do `AssignmentService` đặt lại mỗi khi tập vai trò của người dùng đổi (lấy mức cao nhất của các vai trò `mfaRequired` trong `roles.json`). Mức `2` cho phép TOTP hoặc WebAuthn, mức `3` chỉ WebAuthn với `userVerificationRequirement=required` (BR-12-015). Người dùng chưa đăng ký yếu tố thứ hai bị buộc đăng ký ngay ở lần đăng nhập đó bằng hành động bắt buộc `CONFIGURE_TOTP` hoặc `webauthn-register`. Cách dùng thuộc tính thay cho nhóm giữ cho điều kiện đơn giản và kiểm thử được: cả bảng ánh xạ vai trò sang mức nằm trong một tệp.

Bước lên mức xác thực dùng tính năng "Step-up authentication" gốc của Keycloak 26. Nhánh `dh-browser` có ba nhánh con "Condition - Level of Authentication" cho mức 1, 2, 3, và `max age` của mức 2, 3 đặt 300 giây (`12.mfa.stepup-minutes`). Khi OPA trả nghĩa vụ `STEPUP`, BFF chuyển người dùng tới điểm cuối `auth` với `acr_values=3` và `max_age=300`; Keycloak chỉ thử thách lại nếu `acr` hoặc `auth_time` hiện có không đủ, rồi cấp token mới có `acr` cao hơn; mã phiên sinh lại sau bước lên (SEC-29). Giao diện không tự quyết mức yêu cầu (BR-12-016); mức đến từ `obligations` do chính sách quyết định.

Hai điểm mở rộng viết mã:

1. **`UniformLoginFormAuthenticator`** kế thừa `UsernamePasswordForm`. Khi tên đăng nhập không tồn tại, nó vẫn băm một mật khẩu giả bằng đúng thuật toán và số vòng của realm trước khi trả thông báo "Tên đăng nhập hoặc mật khẩu không đúng", để thời gian phản hồi không lộ tài khoản có tồn tại (BR-12-017). Bộ xác thực này cũng dùng cho luồng đặt lại mật khẩu: trang xác nhận luôn nói "Nếu thư điện tử hợp lệ, liên kết đã được gửi" và việc gửi thư thật chạy bất đồng bộ.
2. **`KafkaEventListenerProvider`** chuyển sự kiện người dùng và sự kiện quản trị của Keycloak thành EVT-12-16 (CloudEvents) gửi Kafka bằng producer idempotent, khóa phân vùng là `sub`. Chỉ giữ trường cần thiết: loại sự kiện, `sub`, `client_id`, địa chỉ nguồn, mã lỗi; không bao giờ gửi mật khẩu, mã TOTP, token (BR-12-045). Sự kiện cấp token thành công được lấy mẫu theo `12.event.token-sample`; mọi lỗi và mọi sự kiện quản trị được giữ 100%. Khi Kafka không sẵn sàng, bộ lắng nghe đệm ra đĩa 64 MiB rồi bỏ sự kiện cũ nhất kèm chỉ số `iam_event_listener_dropped_total`; Keycloak không bao giờ dừng đăng nhập vì Kafka (Q12-21 hỏi về chi phí duy trì ảnh tùy biến).

Đăng nhập liên tenant (FR-12-027) là cấu hình, không là mã: mỗi realm tenant có một nhà môi giới OIDC ẩn trỏ tới realm `dh-platform`, bắt buộc `kc_idp_hint`; nhân sự nền tảng đăng nhập ở `dh-platform` rồi được môi giới vào realm tenant nếu có tài khoản hoặc quyền có thời hạn (mục 4.4). Người dùng thuộc nhiều tenant không phải nhân sự nền tảng có tài khoản riêng ở từng realm (Q12-01 của FRS).

### 4.7. Liên kết định danh ngoài

::: dac-ta
**Mục đích.** Cho tỉnh liên kết LDAP hoặc Active Directory, khai báo ứng dụng SAML 2 cũ và liên kết VNeID, mỗi liên kết phải qua kiểm tra và duyệt trước khi hoạt động.

**Lớp chính.** `FederationService`, `LdapFederation`, `SamlClient`, `VneidLink`, `FederationApprovalService`, `LdapSyncMonitor`.

**Đơn vị chạy.** `dh-platform` (module `iam`).

**FR hiện thực.** FR-12-025, 026, 028.

**Giao diện vào.** API-12-047…055.

**Phụ thuộc ra.** `KeycloakGateway`; OpenBao và External Secrets Operator (bí mật liên kết); LDAP/AD của tỉnh; VNeID.

**Dữ liệu.** `federation`, `saml_client`, `vneid_link`, `outbox`.

**Sự kiện.** EVT-12-04 (liên kết VNeID), EVT-12-13 (liên kết thay đổi).

**Lỗi và xử lý.** Không đạt kiểm tra LDAP: ERR-12-032; SAML sai: ERR-12-033; VNeID trùng: ERR-12-034; trường do LDAP quản lý: ERR-12-047.

**Quan sát.** `iam_federation_sync_users{federation}`, `iam_federation_sync_failures_total`.
:::

Chi tiết thiết kế:

Liên kết LDAP đi qua ba trạng thái `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`. Ở `DRAFT`, TA nhập địa chỉ LDAPS, cơ sở tìm kiếm, thuộc tính ánh xạ và bí mật bind (ghi một chiều vào OpenBao, `kv/dh/{tenant}/iam/ldap/{code}`). Bí mật không đi vào Keycloak dưới dạng văn bản: External Secrets Operator đồng bộ nó thành Secret Kubernetes ở `dh-iam` và cấu hình Keycloak dùng tham chiếu `${vault.ldap_{tenant}_{code}}` của nhà cung cấp vault gốc. `FederationService.test` chạy ba kiểm tra, mỗi kiểm tra có lỗi riêng: kết nối LDAPS (chỉ TLS 1.2 trở lên, kiểm chứng thư theo CA tỉnh nạp sẵn), bind, và tìm mẫu 5 người dùng trong cơ sở đã khai báo; kèm kiểm tra tương đương chính sách mật khẩu theo SEC-22 bằng bộ câu hỏi cấu hình (không thử mật khẩu thật). Chỉ khi ba kiểm tra đạt, nút "Gửi duyệt" mới bật; SO (`PERM-12-approve`, khác TA) duyệt thì mới chuyển `ACTIVE` và `ConfigCliJobRunner` áp cấu hình. Nếu chính sách mật khẩu của tỉnh yếu hơn, đề xuất của FRS là bật MFA bắt buộc cho mọi người dùng nguồn LDAP (Q12-11): hiện thực bằng cách đặt `dh_mfa_level >= 2` cho mọi người dùng có `authSource = LDAP`.

Liên kết ở chế độ chỉ-đọc (`READ_ONLY`): Keycloak kiểm mật khẩu tại LDAP, không ghi ngược; các trường do LDAP quản lý (họ tên, thư, đơn vị) là chỉ đọc ở giao diện (ERR-12-047). Chỉ người dùng nằm trong cơ sở tìm kiếm đã duyệt được nhập (BR-12-029); `FederationService` không bao giờ tự gán vai trò, và nếu bộ ánh xạ vai trò LDAP bị bật ở Keycloak thì kiểm tra khi áp cấu hình từ chối. Đồng bộ thay đổi mỗi 4 giờ, đồng bộ đầy đủ 03:30 hằng ngày; người dùng biến mất khỏi LDAP bị vô hiệu ở lượt đồng bộ kế tiếp (SEC-03). `LdapSyncMonitor` đọc kết quả mỗi lượt từ sự kiện quản trị và hạ chỉ số khi có lỗi.

Ứng dụng SAML 2 (FR-12-025) tạo một client giao thức `saml` ở Keycloak: chữ ký xác nhận (assertion) SHA-256 bắt buộc, `assertionLifespan` 5 phút, `Name ID` dạng `persistent`, `forceAuthentication=false` để dùng chung phiên SSO với OIDC (tiêu chí chấp nhận 3 của FRS). Siêu dữ liệu của nhà cung cấp dịch vụ nhận bằng tệp XML tải lên và đọc bằng bộ phân tích an toàn (`SecureXml`, tắt DTD và thực thể ngoài, SEC-45), không bao giờ để Keycloak tự tải URL siêu dữ liệu vì rủi ro SSRF; `redirectUris` phải khớp đúng, cấm ký tự đại diện.

Liên kết VNeID (Đợt 2, FR-12-028) là nhà môi giới OIDC ở Keycloak với luồng đăng nhập lần đầu tùy biến chỉ cho phép liên kết vào tài khoản có sẵn, không tạo mới (BR-12-029). Người dùng đã đăng nhập bằng mật khẩu và MFA bấm "Liên kết", chọn VNeID, rồi xác nhận qua API-12-054; thành công thì ghi `vneid_link` và EVT-12-04. Phụ thuộc: Keycloak lưu mã định danh liên kết của nhà môi giới ở bảng danh tính liên kết (`sub` của VNeID); yêu cầu "số định danh dưới dạng băm có khóa" của FRS chỉ đạt nếu VNeID cấp `sub` dạng đôi một (pairwise); nếu `sub` là số định danh cá nhân thì phải thêm bộ ánh xạ băm HMAC (Q12-02). Cờ `12.vneid.enabled` mặc định tắt.

### 4.8. Danh tính HTTT: client, scope, chứng thư, bí mật, tài khoản dịch vụ

::: dac-ta
**Mục đích.** Cấp, sửa, tạm ngừng, thu hồi client OAuth cho HTTT thành viên đúng mức hợp đồng; sinh scope từ dữ liệu đã duyệt; giao bí mật một lần; quản lý chứng thư và tài khoản dịch vụ của DU.

**Lớp chính.** `ClientService`, `ScopeSynchronizer`, `CertificateValidator`, `SecretHandover`, `ClientInactivityJob`, `ServiceAccountService`.

**Đơn vị chạy.** `dh-platform` (module `iam`).

**FR hiện thực.** FR-12-030…037; FR-12-008 (phần client).

**Giao diện vào.** API-12-056…071; cổng `ScopeSourcePort` cho PH-02, 07, 09, 10, 19.

**Phụ thuộc ra.** `KeycloakGateway`; OpenBao (`sys/wrapping`, PKI `pki-clients`); PH-01 (saga), PH-15.

**Dữ liệu.** `client`, `client_scope`, `client_credential`, `service_account`, `outbox`; Keycloak.

**Sự kiện.** EVT-12-06, 07, 08.

**Lỗi và xử lý.** Đã có client: ERR-12-018; scope không có nguồn: ERR-12-019; sai trạng thái: ERR-12-020; chứng thư sai: ERR-12-021; phương thức thấp: ERR-12-022; đang chuyển tiếp xoay: ERR-12-023; OpenBao lỗi: ERR-12-039.

**Quan sát.** `iam_clients_total{state,auth_method}`, `iam_client_secret_age_days`, `iam_scope_sync_total{source,result}`.
:::

Chi tiết thiết kế:

`ClientService.provision` chạy theo saga ngắn có bù trừ vì PH-01 gọi nó giữa saga kết nạp: (1) kiểm tra phương thức xác thực theo mức hợp đồng (Hạn chế trở lên cần mTLS hoặc `private_key_jwt`, Nhạy cảm cần mTLS, `client_secret` chỉ cho Công khai và Nội bộ; BR-12-024) và kiểm mọi scope có nguồn duyệt; (2) ghi `client` ở trạng thái `PROVISIONING` cùng khóa lũy đẳng; (3) gọi Keycloak tạo client bằng `dh-client-provisioner`: `clientId` là mã HTTT viết thường, `serviceAccountsEnabled=true`, `standardFlowEnabled=false`, `directAccessGrantsEnabled=false`, `implicitFlowEnabled=false`, `access.token.lifespan=300`, và bộ xác thực client `client-x509` (kèm `tls.client.certificate.bound.access.tokens=true`) hoặc `client-jwt` (kèm JWKS công khai, thuật toán ký ES256) hoặc `client-secret`; (4) gán scope; (5) nếu dùng bí mật chia sẻ thì bọc; (6) đặt `ENABLED`, ghi outbox EVT-12-06. Lỗi từ bước 3 trở đi chạy bù trừ: xóa client dở ở Keycloak rồi đặt `client` thành `FAILED`; gọi lại cùng khóa lũy đẳng bắt đầu lại sạch. Với `mTLS` và `private_key_jwt`, client `ENABLED` nhưng `credentialReady=false` cho tới khi có chứng thư hoặc khóa công khai (FR-12-033); token chưa cấp được vì Keycloak chưa có cách xác thực client.

`SecretHandover` hiện thực BR-12-023. `ClientService` yêu cầu Keycloak sinh bí mật mới (`POST clients/{id}/client-secret`), đọc ngay giá trị và gọi `sys/wrapping/wrap` của OpenBao với `wrap_ttl=24h`; biến chứa bí mật bị ghi đè bằng số 0 và không bao giờ vào log (kiểu `SecretValue` ghi đè `toString`, cấm log bằng ArchUnit như `SecretPayload` của PH-05). Khi PH-01 là bên gọi, phản hồi `201` chứa `secretHandover = {wrappingToken, expiresAt}` để PH-01 hiển thị cho đầu mối; khi người dùng bấm xoay ở UI-12-10 (mục 5.10), phản hồi chỉ có `handoverId` và `SecretHandover` đẩy `wrappingToken` thẳng tới PH-01 hoặc PH-15 qua API giao bí mật, nên người quản trị tỉnh không bao giờ thấy token hay bí mật. Chỉ `wrap_accessor` được lưu ở `client_credential` để tra tình trạng bằng `sys/wrapping/lookup` mà không mở được bí mật. Mã `wrappingToken` dùng được đúng một lần ở bên đầu mối (PH-01 hoặc PH-15 gọi `sys/wrapping/unwrap` và hiện cho đầu mối); nếu ai khác đã mở trước, lệnh của đầu mối thất bại và đó là dấu hiệu bị chặn giữa đường, kích hoạt xoay ngay. Bộ lọc nhật ký che trường `wrappingToken` (SEC-32).

`ScopeSynchronizer` là cửa vào duy nhất của scope. PH-02, 07, 09, 10, 19 gọi `ScopeSourcePort.accept` với **toàn bộ** tập scope của nguồn mình cho một client (thay thế theo nguồn, FR-12-036); bộ đồng bộ kiểm tiền tố đúng loại của nguồn (PH-02 `api:`, PH-09 `purpose:`, PH-10 `topic:`, PH-07 `rdm:`, PH-19 `payment:`), thay phần của nguồn đó và giữ phần của các nguồn khác. Scope được cụ thể hóa ở Keycloak thành "client scope" cấp realm tạo khi cần và gán làm scope tùy chọn cho client, nên token chỉ mang phần giao giữa scope được yêu cầu và scope được cấp (BR-12-025). Quyền quyết định cuối cùng vẫn là dữ liệu `client_scopes` trong gói chính sách: scope bị gỡ mất hiệu lực ở OPA trong ≤ 60 giây dù token cũ còn mang nó. Khi một client có hơn 50 scope, token mang scope gom theo tiền tố và OPA đối chiếu chi tiết bằng dữ liệu gói. Scope nội bộ `iam:*`, `event:*` không có nguồn nào ngoài khai báo tài khoản dịch vụ được đặt (ERR-12-019).

Chứng thư (FR-12-033): `CertificateValidator` phân tích X.509 bằng BouncyCastle, kiểm chuỗi tới CA `pki-clients` của OpenBao hoặc CA tỉnh đã được chấp nhận, `keyUsage` có `digitalSignature`, `extendedKeyUsage` có `clientAuth`, còn hạn, RSA ≥ 2048 hoặc EC P-256 trở lên; ghi dấu vân tay SHA-256 và đặt `x509.subjectdn` ở Keycloak. EVT-12-08 mang dấu vân tay để APISIX đối chiếu với `cnf.x5t#S256` của token. Xoay bí mật (FR-12-034) dùng chính sách xoay bí mật gốc của Keycloak (bí mật hiện hành cộng một bí mật đã xoay còn hạn `12.client.secret-rotation-overlap-hours`), xoay khẩn xóa bí mật đã xoay ngay và gọi `RevocationService` cho token đang lưu hành.

Tài khoản dịch vụ của DU (FR-12-037) khai báo ở kho cấu hình, qua yêu cầu hợp nhất có người duyệt thứ hai, rồi `ServiceAccountService` đối chiếu và tạo ở realm `dh-platform`. DU xác thực bằng `private_key_jwt` nhưng khóa riêng không nằm trong pod: `ServiceTokenProvider` của thư viện PEP ký JWT xác nhận qua `transit/sign/dh-svc-{account}` của OpenBao bằng danh tính Kubernetes của pod; khóa công khai nằm ở JWKS của client, xoay 90 ngày với hai khóa cùng hiệu lực trong chuyển tiếp.

### 4.9. Token, JWKS và thu hồi tức thời

::: dac-ta
**Mục đích.** Bảo đảm token chỉ sống 5 phút, khóa ký xoay đúng hạn, và một lệnh thu hồi chặn được người dùng hoặc client ở mọi cổng trong không quá 60 giây.

**Lớp chính.** `RevocationService`, `RevocationFeed`, `AppliedNodeTracker`, `KeyRotationMonitor`, `RefreshReuseConsumer`, `BlocklistCache` (PEP).

**Đơn vị chạy.** `dh-platform` (module `iam`); `BlocklistCache` ở mọi DU.

**FR hiện thực.** FR-12-038, 039, 040; FR-12-005, 024, 031 (gọi thu hồi).

**Giao diện vào.** API-12-018, 062, 077, 079; EVT-12-05.

**Phụ thuộc ra.** `KeycloakGateway`; Kafka; APISIX (kéo).

**Dữ liệu.** `revocation_entry`, `revocation_feed_version` (chuỗi số), `node_heartbeat`.

**Sự kiện.** EVT-12-05, EVT-12-13 (khóa xoay).

**Lỗi và xử lý.** Thiếu lý do: ERR-12-014; tự thu hồi: ERR-12-013; Keycloak lỗi: ERR-12-038, danh sách chặn vẫn ghi; nút cổng chưa áp dụng quá 60 giây: cảnh báo nghiêm trọng.

**Quan sát.** `iam_revocations_total{kind}`, `iam_revocation_applied_nodes{version}`, `iam_revocation_apply_seconds`, `iam_key_age_days{realm}`.
:::

Chi tiết thiết kế:

`RevocationService.revoke` đặt danh sách chặn **trước** khi chạm Keycloak. Giao dịch: kiểm lý do (ERR-12-014) và chủ thể không là người thao tác (ERR-12-013), chèn `revocation_entry(kind, value, not_before = now, block_all = true, expires_at = null)`, tăng `revocation_feed_version`, ghi outbox EVT-12-05, commit. Cờ `block_all` nghĩa là bên thực thi từ chối **mọi** token của chủ thể bất kể `iat`; nó cần vì khi Keycloak chưa xác nhận vô hiệu thì chủ thể vẫn xin được token mới, mà token mới có `iat` sau mốc nên một mục chỉ dựa trên `notBefore` không chặn được. Khi Keycloak xác nhận (người dùng đã `enabled=false`, client đã tạm ngừng), `RevocationService` hạ `block_all = false` và đặt `expires_at = now + 330 giây`: từ đó mục chỉ còn chặn token cấp trước mốc, và hạn 330 giây là token truy cập sống tối đa 300 giây cộng dung sai 30 giây, sau hạn đó mọi token cũ đã hết hạn nên không cần giữ. Sau commit mới gọi Keycloak: vô hiệu người dùng hoặc tạm ngừng client, hủy mọi phiên, thu hồi refresh token. Thứ tự này có chủ đích: nếu Keycloak lỗi hoặc ngắt mạch, cổng vẫn chặn được ngay và lệnh Keycloak được thử lại từ `sync_task`. Mục thu hồi dùng khóa `kind` là `SUB` (người dùng, mọi token có `iat < notBefore`), `CLIENT` (theo `azp`) hoặc `JTI` (một token, RFC 7009).

Hai đường phân phối cho hai loại bên nhận, cộng một đường đẩy sang PH-03: ngay khi ghi mục, `RevocationService` gọi API-03-053 (`POST /revocations`, scope `gateway:revoke`, `Idempotency-Key` theo `revocationId`) để `dh-connect` ghi vào Valkey, còn đường kéo bên dưới là đường bù khi mất đẩy, đồng thời là đường đối chiếu (đã chốt 27/11/2026). APISIX và `dh-runtime` kéo `GET /api/iam/v1/revocations` (API-12-079) mỗi 10 giây với `If-None-Match`; phản hồi là `{version, entries[{kind, value, notBefore, blockAll}], serverTime}`, ETag là `version`, trả `304` khi không đổi, nên chi phí thường trực rất thấp và danh sách luôn nhỏ (mục chỉ sống 330 giây). Các DU Spring Boot nhận EVT-12-05 qua Kafka vào `BlocklistCache` (bản đồ trong bộ nhớ theo `sub`, `azp`, `jti`) và vẫn kéo API mỗi 30 giây làm đường dự phòng khi Kafka chậm. Nhờ vậy thu hồi không phụ thuộc một đường duy nhất; ngay cả khi Kafka ngừng, 10 giây kéo của cổng cộng thời gian lan nằm trong 60 giây của NFR-12-005.

Bên thực thi áp mục sau khi xác minh chữ ký và `exp`: token bị từ chối ERR-12-116 (`401`) nếu một mục `SUB` hoặc `CLIENT` khớp có `blockAll`, hoặc có `iat < notBefore`, hoặc nếu `jti` nằm trong danh sách. Mỗi nút gửi kèm tiêu đề `X-DH-Applied-Version` ở lần kéo kế tiếp; `AppliedNodeTracker` ghi phiên bản đã áp theo nút (nhận diện bằng danh tính mTLS) và tính `iam_revocation_applied_nodes`, cho giao diện câu "Đã áp dụng ở n/m nút cổng". Nút im lặng quá 60 giây kể từ khi có phiên bản mới thì phát cảnh báo nghiêm trọng cho SO; token còn hiệu lực tối đa 5 phút như FRS ghi nhận.

Khóa ký (FR-12-039): `KeyRotationMonitor` đo `iam_key_age_days` từ siêu dữ liệu khóa; ngày thứ 85 nó thêm một nhà cung cấp khóa `ecdsa-generated` mới có ưu tiên cao hơn qua `ConfigCliJobRunner`, ngày thứ 90 đặt khóa cũ thành thụ động (vẫn xác minh), và sau 24 giờ xóa. Thay đổi `kid` mới xuất hiện ở JWKS ngay; APISIX làm mới khi gặp `kid` lạ (SEC-25), nên không có khoảng gián đoạn. Xoay khẩn đòi người duyệt thứ hai (BR-12-027), xóa khóa cũ ngay và chạy thu hồi hàng loạt theo realm. Dùng lại refresh token (FR-12-038): Keycloak tự hủy cả phiên khi vượt `refreshTokenMaxReuse=0`; `RefreshReuseConsumer` nhận sự kiện `REFRESH_TOKEN_ERROR` loại dùng lại, gọi `RevocationService.revoke(SUB)` để cổng cũng chặn token truy cập đang sống, và tạo cảnh báo AN-05 mức nghiêm trọng.

### 4.10. Realm theo tenant và chuyển định danh khi sáp nhập

::: dac-ta
**Mục đích.** Tạo realm cho tenant mới từ mẫu trong vài phút, giữ cấu hình bảo mật khớp Git, theo vòng đời tenant và chuyển người dùng khi sáp nhập.

**Lớp chính.** `RealmProvisioner`, `DriftDetector`, `RealmSnapshotNormalizer`, `RealmLifecycleService`, `TenantIdentityMerge`.

**Đơn vị chạy.** `dh-platform` (module `iam`); Job `keycloak-config-cli`.

**FR hiện thực.** FR-12-041, 042, 043, 019.

**Giao diện vào.** API-12-045, 046, 080…085, 113 (danh sách realm, lọc `driftStatus=DRIFTED`, chỉ đọc trên bản chiếu `realm`).

**Phụ thuộc ra.** `ConfigCliJobRunner`; kho cấu hình Git; OpenBao; PH-20 (saga); PH-18.

**Dữ liệu.** `realm_state`, `realm_provision_step`, `tenant_merge_step`, `outbox`.

**Sự kiện.** EVT-12-13, EVT-12-14 (khi lệch), EVT-12-01 (quản trị đầu tiên).

**Lỗi và xử lý.** Realm đã có: ERR-12-041; Keycloak hoặc Git lỗi: ERR-12-038, 040 (saga PH-20 dừng ở `FAILED`, thử lại); đang đối chiếu: ERR-12-042.

**Quan sát.** `iam_realm_state{tenant,state}`, `iam_realm_drift{tenant}`, `iam_realm_provision_seconds`.
:::

Chi tiết thiết kế:

`RealmProvisioner.provision` là một dãy bước lũy đẳng, mỗi bước ghi vào `realm_provision_step` để gọi lại cùng khóa lũy đẳng tiếp tục từ bước dở (FR-12-041, luồng thay thế): `TEMPLATE_APPLIED` (Job config-cli áp mẫu, realm ở `PROVISIONING`), `KEYS_AND_CLIENTS` (khóa ES256, client `dh-console`, `dh-portal`), `SECRETS_WRITTEN` (bí mật client ghi một chiều vào OpenBao), `ROLES` (22 vai trò chuẩn trừ `PLATFORM_*`, vai trò `realm-user-admin`, client `dh-platform-iam` và `dh-client-provisioner`), `BROKER` (nhà môi giới nền tảng ẩn), `FIRST_ADMIN` (quản trị tỉnh đầu tiên ở `PENDING_ACTIVATION` với `dh_mfa_level = 3`), `BUNDLE_SEEDED` (gói dữ liệu tenant đầu tiên, mục 4.12) và `ACTIVE` (đặt realm hoạt động sau kiểm tra khói của saga PH-20). Thời gian mục tiêu ≤ 5 phút (NFR-12-010) chủ yếu là Job config-cli (khoảng 60–90 giây, giả định đo ở môi trường thử) cộng ghi OpenBao và dựng gói. Bù trừ do PH-20 gọi xóa realm đang ở `PROVISIONING`; từ `ACTIVE` trở đi không xóa được ngoài vòng đời tenant.

Phát hiện lệch (FR-12-042) tránh phải dựng lại toàn bộ cấu hình để so sánh. Ngay sau mỗi lần áp mẫu thành công, `RealmSnapshotNormalizer` đọc lại realm qua Admin API, chỉ giữ danh sách trường bảo mật cho phép (chính sách mật khẩu, phát hiện dò, thời hạn token, phiên, grant, luồng xác thực dưới dạng băm cấu trúc, thuộc tính client hệ thống, nhà môi giới, nhà cung cấp khóa) và lưu băm cùng bản chụp thành "mức chuẩn" của realm cho `gitCommit` đó. `DriftDetector` chạy hằng giờ, chuẩn hóa lại và so với mức chuẩn; khác thì đặt `driftStatus = DRIFTED`, nêu trường lệch và lấy người thay đổi từ sự kiện quản trị của Keycloak. Đường nhanh hơn: bất kỳ sự kiện quản trị `UPDATE` trên realm, luồng xác thực hoặc client hệ thống do chủ thể khác `dh-platform-iam`, `dh-client-provisioner` và tài khoản dịch vụ của Job `dh-iam-provisioner` thực hiện kích hoạt đối chiếu ngay, không đợi giờ kế tiếp. Với `12.realm.auto-reconcile` bật, sau 15 phút hệ thống tự áp lại mẫu trừ khi SO xác nhận "giữ tạm" kèm lý do; mọi lần lệch, áp lại, giữ tạm đều vào kiểm toán và EVT-12-13. Thay đổi mẫu đi theo yêu cầu hợp nhất ở Git (PA soạn, SO duyệt), CI chạy kiểm thử cấu hình trên realm thử rồi áp dần từng tenant; mức chuẩn được lập lại sau mỗi lần áp.

Vòng đời (FR-12-043) tách hai cơ chế để có hiệu lực nhanh và an toàn. Khi tenant `SUSPENDED`, quyết định từ chối nằm ở OPA: dữ liệu `tenant_state` của gói tenant đổi nên luật `deny TENANT_SUSPENDED` chặn mọi yêu cầu trừ thao tác đọc của quản trị tỉnh, có hiệu lực trong ≤ 60 giây. Song song, `RealmLifecycleService` vô hiệu tất cả client máy của tenant (gắn thuộc tính `dh_suspended_by_realm=true` để khôi phục đúng tập đã bị vô hiệu), nên không còn token mới. `READ_ONLY` (tenant đã sáp nhập) chỉ đổi dữ liệu `tenant_state`: luật Rego từ chối mọi hành động khác `read`. `DELETED` xóa realm bằng Job config-cli sau thời hạn bàn giao. Khôi phục thao tác ngược, không khôi phục client đã bị vô hiệu thủ công trước đó.

Chuyển định danh khi sáp nhập (FR-12-019, Đợt 2) do `TenantIdentityMerge` điều phối theo `tenant_merge_step`. `plan` đọc bản chiếu người dùng của tenant nguồn, so với tenant đích và liệt kê xung đột (trùng tên đăng nhập, thư, vai trò không tồn tại ở đích, đơn vị chưa ánh xạ). `execute` tạo lại từng người ở realm đích với thuộc tính `origin_tenant_id` và `origin_user_id`, ánh xạ vai trò và đơn vị theo bảng đã duyệt, gửi liên kết kích hoạt (mật khẩu không chuyển được, trừ người dùng LDAP giữ liên kết); client của HTTT được cấp song song ở đích trong thời gian chuyển tiếp (BP-09). Mỗi người là một bước lũy đẳng nên thất bại giữa chừng chạy lại không tạo trùng.

### 4.11. Quyết định ủy quyền: thư viện PEP và chính sách gốc

::: dac-ta
**Mục đích.** Cho mọi bên thực thi hỏi OPA theo một hợp đồng, nhận quyết định kèm mặt nạ trường và nghĩa vụ, và luôn từ chối khi không có câu trả lời đáng tin; chính sách gốc bảo đảm từ chối mặc định, từ chối thắng cho phép và cách ly tenant.

**Lớp chính.** `DhAuthorizationManager`, `InputBuilder`, `OpaClient`, `DecisionCache`, `AuditGate`, `MaskingAdvice`, `XacmlAdapter`, `BatchDecisionHandler`; gói Rego `dh.authz`.

**Đơn vị chạy.** Thư viện trong mọi DU và plugin APISIX; OPA sidecar; `XacmlAdapter` và API `decide` ở `dh-platform`.

**FR hiện thực.** FR-12-044…050.

**Giao diện vào.** Gọi hàm (`@RequiresPermission`), plugin APISIX, API-12-086…088.

**Phụ thuộc ra.** OPA cục bộ `127.0.0.1:8181`; trạng thái bộ ghi nhật ký quyết định (`AuditGate`).

**Dữ liệu.** `data.dh.platform.*` và `data.dh.tenants[t].*` trong OPA (từ gói); bộ đệm trong tiến trình.

**Sự kiện.** Không; ghi vết theo mục 4.14.

**Lỗi và xử lý.** Thiếu trường: ERR-12-101; thiếu scope `iam:decide`: ERR-12-102; lỗi đánh giá: ERR-12-103; OPA quá tải hoặc chưa nạp gói: ERR-12-104; XACML sai lược đồ: ERR-12-123; không ghi được vết mức Nhạy cảm: ERR-12-124. Mọi trường hợp là từ chối.

**Quan sát.** `iam_decisions_total{result,policy}`, `iam_decision_duration_seconds`, `iam_cache_hits_total`, `iam_cache_misses_total`, `iam_pep_failclosed_total{cause}`.
:::

Chi tiết thiết kế:

**Thư viện PEP.** `DhAuthorizationManager.check` là điểm vào duy nhất của DU Spring Boot, gắn vào `@RequiresPermission("PERM-07-publish")` qua `AuthorizationManager`. Các bước theo thứ tự: (1) Spring Security đã xác minh chữ ký, `iss` thuộc danh sách realm cho phép và `exp`; (2) `BlocklistCache` kiểm mốc thu hồi (ERR-12-116); (3) `InputBuilder` dựng `input` từ token và `ResourceResolver` của DU (bảng ở mục 3.4); (4) `DecisionCache` tra khóa; (5) nếu tài nguyên là Nhạy cảm, `AuditGate` phải báo đường ghi vết khỏe, nếu không thì từ chối `AUDIT_UNAVAILABLE` ngay, không hỏi OPA; (6) `OpaClient` gọi OPA với thời gian chờ `12.pep.timeout-ms` (50 ms), **không thử lại**; (7) mọi ngoại lệ, hết giờ, mã HTTP khác `200`, phản hồi sai cấu trúc thành `DecisionResult.failClosed(POLICY_ERROR)`; (8) từ chối được dịch thành `403`, `404` hoặc `401` theo bảng bên dưới; từ chối `STEPUP_REQUIRED` mang nghĩa vụ `STEPUP{acr, maxAgeSeconds}` để PEP ném `StepUpRequiredException` cho BFF chuyển hướng; (9) cho phép thì thi hành nghĩa vụ: `MASK` (`MaskingAdvice` áp `fieldMask` lên thân phản hồi), `AUDIT` (mức ghi vết), `TTL` (hạn đệm). Không có nhánh nào "thử lại rồi cho qua".

| Lý do trả về | Trạng thái ở bên thực thi | Cơ sở |
|---|---|---|
| `TENANT_MISMATCH`, `ORG_SCOPE_MISMATCH` | `404` cùng thân với "không tìm thấy" | BR-12-041: không lộ sự tồn tại của đối tượng ngoài phạm vi |
| `NO_MATCHING_POLICY`, `ROLE_MISSING`, `SCOPE_MISSING`, `PURPOSE_NOT_DECLARED`, `SELF_APPROVAL`, `CLIENT_SUSPENDED`, `TENANT_SUSPENDED`, `GRANT_EXPIRED`, `DATA_CLASSIFIED_SECRET`, `AUDIT_UNAVAILABLE`, `POLICY_ERROR` | `403`; `NO_MATCHING_POLICY` trả `404` nếu `resource.org` khác `subject.org` | D02-08 §7 |
| `STEPUP_REQUIRED` | `401` kèm tiêu đề `WWW-Authenticate: Bearer error="insufficient_user_authentication", acr_values="3"` | RFC 9470, ERR-12-120 |

: Dịch lý do từ chối sang trạng thái HTTP

**Bộ đệm quyết định** (FR-12-050) là bộ nhớ Caffeine theo tiến trình với khóa gồm băm của (tenant, chủ thể, tập vai trò hoặc scope, quyền, mã tài nguyên, hành động, mục đích, `bundleRevision`). Vì `bundleRevision` nằm trong khóa nên mọi gói mới tự vô hiệu bộ đệm cũ. Không đệm tài nguyên mức Nhạy cảm, nghĩa vụ `STEPUP`, và quyết định `AUDIT` mức `FULL` (BR-12-012); thời gian sống là nhỏ nhất của `12.cache.ttl-seconds`, `maxCacheSeconds` của nghĩa vụ `TTL`, và 10 giây cho quyết định từ chối. Một đánh đổi cần biết: quyết định đệm không sinh bản ghi ở OPA, nên một chuỗi từ chối lặp trong 10 giây chỉ để lại một bản ghi; `iam_cache_hits_total` đếm phần còn lại và `AN-03` dùng số đếm của PEP chứ không chỉ nhật ký OPA.

**Chính sách gốc.** Gói `dh.authz` ở `rego/base` gồm các tệp: `main.rego` (điểm vào `decision`), `deny.rego` (luật từ chối của nền tảng), `rbac.rego` (vai trò và quyền), `org.rego` (phạm vi tổ chức), `scope.rego` (quyền của máy), `mask.rego` (mặt nạ trường), `obligations.rego`, `effective.rego`. Khung của `main.rego`:

```rego
package dh.authz

import rego.v1

default allow := false

# luật từ chối của gói gốc và của gói tenant, hợp thành một tập
deny contains r if some r in base_deny
deny contains r if some r in data.dh.tenant_rules[input.tenant].deny

allow if {
    count(deny) == 0
    subject_permits
    org_scope_permits
}

subject_permits if { input.subject.type == "USER"; role_permits }
subject_permits if { input.subject.type in {"CLIENT", "SERVICE"}; scope_permits }

# giao của vai trò trong token với gán trong dữ liệu gói (BR-12-036)
role_permits if {
    some a in active_assignments
    a.role in input.subject.roles
    input.permission in data.dh.platform.role_perms[a.role]
}

active_assignments contains a if {
    some a in data.dh.tenants[input.tenant].assignments[input.subject.id]
    now := time.now_ns()
    a.from_ns <= now
    a.to_ns == 0 
}
active_assignments contains a if {
    some a in data.dh.tenants[input.tenant].assignments[input.subject.id]
    now := time.now_ns()
    a.from_ns <= now
    now < a.to_ns
}

decision := {
    "allow": allow,
    "reason": reason,
    "matchedPolicy": matched,
    "bundleRevision": data.dh.tenants[input.tenant].revision,
    "fieldMask": field_mask,
    "privacyMode": privacy_mode,
    "obligations": obligations,
}
```

Ba điểm của khung. Một là `deny` hợp từ hai nguồn nên gói tenant chỉ có thể làm tập này lớn thêm; không có cách nào gói tenant làm một lý do từ chối của gói gốc biến mất. Hai là `allow` đòi `count(deny) == 0` rồi mới xét luật cho phép, nên "từ chối thắng" là cấu trúc của chương trình chứ không là thứ tự đánh giá. Ba là hạn của gán vai trò (`to_ns`) được kiểm bằng `time.now_ns()` ở mọi quyết định, nên hết hạn có hiệu lực ngay cả khi tác vụ dọn dữ liệu chưa chạy. Luật `deny` mẫu và quy tắc cách ly tenant đã có ở FRS FR-12-045 và không lặp lại.

`scope_permits` tra bảng `data.dh.platform.scope_rules` (sinh từ D02-08 §5) để biết loại tài nguyên cần scope nào (ví dụ `api` cần `api:{mã API}:*`, `topic` cần `topic:{tên}:{hành động}`, `rdm` cần `rdm:read`, `payment` cần `payment:create`), rồi đối chiếu với `data.dh.tenants[t].client_scopes[clientId]` và trạng thái client. `mask.rego` đi theo FR-12-047: bắt đầu từ tập trường của thực thể trong `data...entities` (mỗi trường có mức phân loại và danh sách mục đích cho phép), đặt `hidden` cho trường Nhạy cảm trừ khi có `PERM-09-unmask` kèm mục đích và `acr` đủ, đặt `masked` cho trường Hạn chế khi mục đích không nằm trong danh sách; thực thể chưa khai báo tập trường thì `fieldMask` rỗng kèm cảnh báo cấu hình (BR-12-040). Nhãn "bí mật nhà nước" bị từ chối không điều kiện và không có luật cho phép nào cho nhãn này (BR-12-005, Q12-13 của FRS).

**Bộ chuyển đổi XACML** (FR-12-048) nằm ở `dh-platform`, không ở OPA. `XacmlAdapter` nhận JSON profile của XACML 3.0 (và XML, qua bộ phân tích `SecureXml`), chuyển yêu cầu 2.0 sang 3.0 nội bộ, ánh xạ bốn loại thuộc tính sang `input` bằng bảng `xacml-attribute-map.json` (ví dụ `urn:oasis:names:tc:xacml:1.0:subject:subject-id` sang `subject.id`, `…:resource:resource-id` sang `resource.id`, `…:action:action-id` sang `action`), gọi OPA sidecar của `dh-platform` và dựng `Response`: `Permit` khi `allow`, `Deny` khi có lý do từ chối xác định, `NotApplicable` khi `NO_MATCHING_POLICY`, `Indeterminate` kèm `Status` khi lỗi đánh giá hoặc thiếu thuộc tính. Nghĩa vụ OPA thành `Obligations` XACML. Lớp này chỉ đáp ứng giao diện yêu cầu và phản hồi, không chạy chính sách viết bằng ngôn ngữ XACML (Q12-03 của FRS).

**Quyết định theo lô** (FR-12-049): `BatchDecisionHandler` nhận tối đa 100 phần tử có chung `subject`, `action`, `context`; gọi OPA một lần với `POST /v1/data/dh/authz/decision_batch` (luật `decision_batch` lặp trên `input.items`) để tránh 100 vòng mạng cục bộ; phần tử lỗi trả từ chối `POLICY_ERROR` mà không hỏng lô. Nếu một DU không có OPA cạnh (ngoài danh sách), nó gọi `POST /api/authz/v1/decide` bằng scope `iam:decide`; API này luôn trả `200` với `allow` đúng, và lỗi của chính API được thư viện máy khách hiểu là từ chối.

**APISIX.** Plugin `dh-authz` do PH-03 hiện thực theo đúng bảng ánh xạ ở mục 3.4: lấy claim từ JWT đã xác minh, siêu dữ liệu route (`x-datahub-permission`, loại tài nguyên) từ OpenAPI đã duyệt, gọi OPA cục bộ với thời gian chờ 50 ms và trả `403`, `404`, `401` hoặc `503` theo cùng bảng dịch ở trên. Trạng thái lỗi của plugin (không gọi được OPA) là từ chối. Tiêu đề `X-DH-Tenant` được đặt từ claim, `fieldMask` đi tiếp tới backend bằng tiêu đề `X-DH-Field-Mask` để DU áp dụng nếu cần.

### 4.12. Dữ liệu vai trò–quyền và gói chính sách

::: dac-ta
**Mục đích.** Sinh tự động dữ liệu cho OPA từ ma trận D02-08, gán vai trò, quyền có thời hạn, đơn vị và scope; đóng gói, ký, đặt vào kho và theo dõi từng OPA nạp xong bản nào.

**Lớp chính.** `PolicyDataGenerator`, `ConsistencyChecker`, `BundleBuilder`, `BundleSigner`, `BundleRegistry`, `BundleAckTracker`.

**Đơn vị chạy.** `dh-platform` (module `iam`, vai trò `worker`).

**FR hiện thực.** FR-12-051; phần phát hành của FR-12-054, 055.

**Giao diện vào.** Sự kiện nội bộ "dữ liệu thay đổi"; đồng hồ 30 giây; API-12-101, 102; điểm cuối nội bộ nhận trạng thái OPA.

**Phụ thuộc ra.** OpenBao `transit/sign/dh-policy-signing`; Garage (`dh-platform-policy`); `policy-runner`; PH-07 (cây đơn vị).

**Dữ liệu.** `bundle_release`, `bundle_ack`; bucket `dh-platform-policy`.

**Sự kiện.** EVT-12-09 khi gói mới có hiệu lực.

**Lỗi và xử lý.** Dữ liệu không nhất quán: ERR-12-040, giữ gói cũ; không ký được: ERR-12-039, giữ gói cũ; gói quá 20 MiB: chia theo đơn vị và cảnh báo.

**Quan sát.** `iam_policy_reload_seconds`, `iam_bundle_size_bytes{tenant}`, `iam_bundle_build_total{result}`, `iam_bundle_acked_nodes{revision}`.
:::

Chi tiết thiết kế:

Hai loại gói để giữ kích thước nhỏ và phạm vi hiệu lực đúng. Gói `platform` chứa Rego gốc, `permissions` (`role_perms`, `scope_rules`, `sod_pairs`) sinh từ D02-08 và `grants` của quyền có thời hạn đang hiệu lực; mọi OPA nạp. Gói `tenant/{tenant}` chứa Rego riêng của tỉnh (chỉ `deny`, nghĩa vụ) và dữ liệu `assignments`, `org_tree`, `client_scopes`, `tenant_state`, `entities`, `custom_roles`. OPA của APISIX nạp gói `platform` và gói của mọi tenant nó phục vụ; OPA trong DU của một tenant riêng nạp gói `platform` và gói tenant đó; danh sách do **gói khám phá** (OPA discovery) quy định để thêm tenant không phải khởi động lại sidecar.

Bộ phát sinh theo hướng sự kiện có hãm: mỗi thay đổi nguồn (EVT-12-03, 06, 07, 08, 11, 12, 13) đánh dấu tenant là "bẩn"; `PolicyDataGenerator` gom thay đổi trong cửa sổ 5 giây rồi dựng dữ liệu, và một đồng hồ 30 giây làm lưới an toàn khi mất sự kiện. Dựng gói có tính tất định: khóa JSON sắp xếp, `mtime` cố định trong tar, nên cùng dữ liệu cho cùng băm và `BundleBuilder` bỏ qua phát hành khi `digest` không đổi. `ConsistencyChecker` kiểm trước khi đóng gói: mọi vai trò trong `assignments` có trong `role_perms`, không quyền nào ngoài danh mục D02-08, không người dùng nào mang cặp xung đột không ngoại lệ; lỗi thì không phát hành, giữ gói cũ và báo PA (ERR-12-040). Mã bản gói `bundleRevision` có dạng `{tenant}-{yyyyMMdd}-{seq}`, ví dụ `t68-20261126-0153`, đặt trong `.manifest` và đi vào mọi quyết định.

Ký gói dùng khóa transit không xuất được (SEC-36, ADR-012). OPA kiểm chữ ký theo tệp `.signatures.json` là một JWT ký ES256 có phần tải `{files:[{name, hash, algorithm}]}`. Vì khóa riêng không rời OpenBao, `BundleSigner` không dùng cờ `opa build --signing-key` mà tự ghép JWT: tiêu đề `{alg: ES256, kid}`, phần tải gồm băm SHA-256 của từng tệp trong gói, chữ ký lấy từ `transit/sign/dh-policy-signing` với `marshaling_algorithm=jws` và `prehashed=false`. Khóa công khai đặt trong cấu hình OPA (`keys`, `signing.keyid`), phân phối bằng GitOps; hai khóa cùng hiệu lực trong giai đoạn xoay 12 tháng (Q12-24). Kết quả đặt ở `tenants/{tenant}/bundle.tar.gz` và bản bất biến `releases/{revision}.tar.gz`; kho dùng ETag của Garage nên OPA chỉ tải khi có bản mới.

`BundleAckTracker` biết từng OPA đang chạy bản nào nhờ trạng thái do OPA báo (plugin `status` của OPA gửi `bundles.{name}.active_revision` tới một điểm cuối nội bộ của `dh-platform`, kiểm danh tính mTLS của pod). Từ đó có chỉ số `iam_policy_reload_seconds` (từ lúc ký tới lúc OPA đầu tiên và OPA cuối cùng xác nhận), tiến độ "n/m nút" ở giao diện và điều kiện chuyển `APPROVED` sang `PUBLISHED`. Nếu sau 5 phút còn OPA chưa nạp, hệ thống phát cảnh báo nghiêm trọng và đề xuất quay lui (FR-12-055). OPA không tải được gói mới vẫn dùng gói cuối lưu bền trên đĩa ít nhất 24 giờ (NFR-12-013).

Kích thước: giả định tỉnh vừa 3.000 người dùng, mỗi người trung bình 4 gán, 200 client mỗi client 10 scope thì dữ liệu tenant khoảng 1,6 MiB JSON; bộ nhớ OPA khoảng 8 lần kích thước dữ liệu, tức khoảng 13 MiB mỗi tenant. Ở `QM-CHUNG` với 34 tenant, sidecar APISIX nạp tới 34 gói cần khoảng 450 MiB, vượt mức 0,5 GiB mà D03-01 đang ghi cho sidecar OPA; Q12-28 đề nghị nâng sidecar của APISIX lên 1 GiB ở `QM-CHUNG` hoặc đo lại bằng bộ thử của NFR-12-024.

### 4.13. Vòng đời chính sách

::: dac-ta
**Mục đích.** Cho kỹ sư chính sách soạn, kiểm thử, chạy khô và gửi duyệt chính sách Rego; cho người duyệt thứ hai phê duyệt, phát hành, thu hồi, quay lui, tất cả có kiểm soát và lưu vết.

**Lớp chính.** `PolicyService`, `PolicyVersion`, `PolicyLinter`, `TestSuiteService`, `DryRunService`, `ApprovalService`, `PolicyRunnerClient`, `GitMirror`; dịch vụ `policy-runner`.

**Đơn vị chạy.** `dh-platform` (module `iam`); `policy-runner` (Deployment riêng, không có thông tin xác thực CSDL).

**FR hiện thực.** FR-12-052…055.

**Giao diện vào.** API-12-089…102, 112 (ghi đè bản nháp để tự lưu, chỉ phiên bản `DRAFT` của chính người soạn, kèm `If-Match`).

**Phụ thuộc ra.** `policy-runner`; Loki (mẫu cho chạy khô); `BundleBuilder`; hộp việc chung; kho Git `dh-policies`.

**Dữ liệu.** `policy`, `policy_version`, `policy_version_contributor`, `policy_test_case`, `policy_test_run`, `policy_dryrun_report`, `outbox`.

**Sự kiện.** EVT-12-09, EVT-12-10.

**Lỗi và xử lý.** Biên dịch lỗi: ERR-12-024; ca không đạt: ERR-12-025; chưa chạy khô: ERR-12-026; chuyển trạng thái sai: ERR-12-027; tenant nới luật: ERR-12-028; thiếu xác nhận: ERR-12-029; vi phạm bốn mắt: ERR-12-008.

**Quan sát.** `iam_policy_versions{state}`, `iam_policy_test_seconds`, `iam_policy_dryrun_changed_ratio`, `iam_policy_approvals_total{result}`.
:::

Chi tiết thiết kế:

`PolicyVersion` là máy trạng thái chốt ở máy chủ theo ADR-069 (bảng ở mục 8.1). "Đã kiểm thử và chạy khô" không là trạng thái mà là điều kiện gắn với `contentHash`: các bản ghi `policy_test_run` và `policy_dryrun_report` lưu `contentHash` và `bundleRevision` mà chúng đã chạy; `submit` chỉ qua khi cả hai khớp với phiên bản hiện tại và bản gói đang chạy, nên sửa một ký tự hay đổi gói gốc là mất hiệu lực (BR-12-009). Người đóng góp được ghi ở `policy_version_contributor` mỗi lần lưu nháp; `approve` so người duyệt với người soạn, mọi người đóng góp và người gửi (BR-12-008).

`policy-runner` chạy mã Rego do người dùng soạn, tức là thực thi mã không tin cậy, nên bị cô lập chặt. Nó là một dịch vụ Spring Boot mỏng điều phối tiến trình `opa` (ảnh ký cosign, SEC-36); chỉ nhận lời gọi mTLS từ `dh-platform`, không có đường ra mạng (`CiliumNetworkPolicy` từ chối mọi egress), không có thông tin xác thực CSDL hay OpenBao, hệ thống tệp chỉ đọc cộng thư mục tạm `tmpfs`, giới hạn 2 vCPU, 1 GiB, thời gian chờ mỗi việc 60 giây cho kiểm thử và 10 phút cho chạy khô. Mọi lệnh `opa` dùng `--capabilities capabilities.json` loại `http.send`, `net.lookup_ip_addr`, `opa.runtime`, nên một chính sách không đọc được mạng hay cấu hình của pod dù có lỗ hổng kiểm tra tĩnh (đề xuất ADR (g)).

`PolicyLinter` chạy trước khi tới runner: giới hạn 256 KiB, `opa parse` lấy cây cú pháp rồi kiểm các quy tắc tĩnh. Với chính sách phạm vi `TENANT`: gói phải đúng `dh.tenant_rules.{tenant}`; chỉ cho phép đầu luật `deny` và `obligations` (cộng hàm phụ trợ bắt đầu bằng `_`); cấm đầu luật `allow`, `default`, từ khóa `with` tác động lên `data.dh.*`, và mọi hàm dựng sẵn ngoài danh sách cho phép; chỉ đọc `input` và `data.dh.tenants[input.tenant]`. Vi phạm là ERR-12-028 và là lớp phòng thủ thứ nhất của BR-12-007; lớp thứ hai là cấu trúc Rego (tập `deny` hợp, `allow` luôn đòi `count(deny) == 0`).

Kiểm thử (FR-12-052): người soạn viết ca bằng JSON (`input`, kết quả mong đợi `allow`, `reason`) hoặc tệp `*_test.rego`; `TestSuiteService` đưa phiên bản, gói gốc, dữ liệu mẫu và ca vào runner chạy `opa test --coverage`. Điều kiện đạt: mọi ca đạt, tối thiểu một ca dương và một ca âm cho mỗi luật mới, độ phủ dòng ≥ 90% (SEC-26, NFR-12-033). Chạy khô (FR-12-053): `DryRunService` lấy mẫu yêu cầu quyết định từ Loki (nhật ký đã che; lấy toàn bộ từ chối và quyết định Nhạy cảm, lấy mẫu phần còn lại, tối đa `12.policy.dryrun.max-samples`), nhờ runner khởi hai tiến trình `opa` cô lập (gói đang `PUBLISHED` và gói thay phiên bản nháp) và đẩy mẫu qua 16 luồng để so kết quả từng yêu cầu. Báo cáo tính tỷ lệ đổi, số ca từ chối sang cho phép (đánh dấu "nới quyền"), nhóm theo chủ thể, tài nguyên, chính sách và 20 ví dụ tiêu biểu. Mẫu dưới 100 yêu cầu thì báo "mẫu quá ít" nhưng vẫn cho gửi duyệt. Vì nhật ký quyết định đã che giá trị Nhạy cảm nên mẫu chỉ còn thuộc tính, không còn dữ liệu cá nhân (SEC-32, SEC-37).

Duyệt và phát hành (FR-12-054): `ApprovalService.approve` kiểm người duyệt đã xác thực mức 3 trong 5 phút, kiểm bốn mắt, và với báo cáo chạy khô có tỷ lệ đổi vượt ngưỡng hoặc có "nới quyền" thì đòi `confirmHighImpact` cùng ý kiến (ERR-12-029). Giao dịch ghi `APPROVED` và một việc phát hành vào hàng đợi; `BundleBuilder` dựng gói gồm mọi phiên bản `PUBLISHED` cộng phiên bản này, chạy lại toàn bộ bộ kiểm thử gộp (với chính sách nền tảng thì cho mọi tenant có luật riêng, chạy song song), ký và đặt vào kho. Khi OPA đầu tiên xác nhận `bundleRevision` mới, `BundleAckTracker` báo, phiên bản chuyển `PUBLISHED`, phiên bản cũ `SUPERSEDED` trong cùng một giao dịch (chỉ mục duy nhất từng phần bảo đảm đúng một `PUBLISHED` cho mỗi mã), rồi phát EVT-12-09. Không ký được thì phiên bản ở lại `APPROVED` và việc được thử lại.

Thu hồi và quay lui (FR-12-055): thu hồi đặt `REVOKED` và dựng gói không chứa phiên bản đó. Quay lui chọn một bản phát hành trước làm nội dung; vì OPA nhận gói theo ETag nên bản quay lui được dựng thành một bản phát hành **mới** có `bundleRevision` mới nhưng nội dung và dữ liệu của bản cũ, ký lại; cách này giữ chuỗi revision đơn điệu cho mọi nhật ký và khóa đệm. Không thu hồi được chính sách gốc `base-authz` (ERR-12-027). `GitMirror` ghi mỗi phiên bản `PUBLISHED` vào kho `dh-policies` (một commit có trailer `Policy-Version`) để người đọc có so sánh và nhật ký Git; `ph12_iam` vẫn là nguồn sự thật, kho Git là bản sao để đọc và khôi phục.

### 4.14. Ghi vết, tra cứu, phát hiện bất thường và báo cáo

::: dac-ta
**Mục đích.** Ghi mọi sự kiện xác thực và quyết định ủy quyền với đúng mức che và mức lưu, cho cán bộ tra cứu, phát hiện hành vi bất thường trong 60 giây, báo cáo tình trạng tài khoản và MFA.

**Lớp chính.** `SecurityEventConsumer`, `AuditWriter`, `DecisionQueryService`, `AlertEngine`, `AlertRule` (AN-01…09), `AlertDeduplicator`, `AccountReport`, `MfaCoverageReport`.

**Đơn vị chạy.** `dh-platform` (module `iam`); đường nhật ký ở OPA, Fluent Bit và OTel Collector.

**FR hiện thực.** FR-12-056…060.

**Giao diện vào.** API-12-103…109; EVT-12-16.

**Phụ thuộc ra.** Loki (`X-Scope-OrgID` theo tenant); Mimir (PromQL); PH-13 (chuỗi băm kiểm toán); Valkey (bộ đếm cửa sổ trượt); hộp việc và kênh thông báo.

**Dữ liệu.** `alert`, `alert_ack`, `account_report_daily`, `mfa_coverage_daily`; Loki; chuỗi kiểm toán PH-13.

**Sự kiện.** EVT-12-14, EVT-12-16 (tiêu thụ).

**Lỗi và xử lý.** Loki không đọc được: ERR-12-040; ngưỡng ngoài miền: ERR-12-043; không ghi được vết mức Nhạy cảm: ERR-12-124.

**Quan sát.** `iam_alerts_total{rule,severity}`, `iam_alert_latency_seconds`, `iam_decision_log_dropped_total`, `iam_auth_event_lag_seconds`.
:::

Chi tiết thiết kế:

Nhật ký quyết định đi qua ba chặng. OPA ghi quyết định (kèm `decision_id`, `req_id` lấy từ `X-Request-ID` do PEP đặt bằng `traceId`, `bundles[].revision`, `input`, `result`, `metrics`) bằng plugin `decision_logs` với bộ che `mask_decision` loại giá trị trường Nhạy cảm, băm có khóa mã tài nguyên mức Nhạy cảm và bỏ tiêu đề; chặng hai là bộ thu cục bộ trên nút (Fluent Bit) với hàng đợi tệp bền tối đa 24 giờ; chặng ba là Loki, nhãn `tenant` bắt buộc, giữ 12 tháng trực tuyến. Quyết định từ chối và mức Nhạy cảm còn đi vào chuỗi băm kiểm toán của PH-13 (WORM 5 năm, ADR-031) qua thư viện `dh-audit`. `AuditGate` của PEP hỏi `GET /health?plugins` của OPA mỗi giây và coi đường ghi là hỏng nếu plugin `decision_logs` không ở trạng thái `OK` hoặc bộ đệm của OPA đã bỏ bản ghi; khi đó tài nguyên Nhạy cảm bị từ chối `AUDIT_UNAVAILABLE` (BR-12-013), tài nguyên thường vẫn phục vụ và bộ thu giữ hàng đợi 24 giờ. Tỷ lệ lấy mẫu cho quyết định cho phép mức Công khai, Nội bộ là `12.decision.sample-ratio` (0,1) do bộ che áp bằng băm xác định theo `decision_id`, không lấy mẫu từ chối hay mức Hạn chế, Nhạy cảm.

`SecurityEventConsumer` đọc EVT-12-16 theo nhóm tiêu thụ riêng, ghi sự kiện đã che vào Loki, cập nhật bản chiếu (`last_login_at`, trạng thái, loại yếu tố đã đăng ký) và đẩy sự kiện vào `AlertEngine`. Sự kiện quản trị Keycloak thay đổi quyền, yếu tố, cấu hình vào chuỗi kiểm toán của tenant. `AlertEngine` có chín luật AN-01…AN-09 ở FRS, mỗi luật là một `AlertRule` với `evaluate`. Luật theo luồng sự kiện (AN-01, 02, 05, 06, 07, 09) dùng bộ đếm cửa sổ trượt ở Valkey với khóa tạo bằng hàm có tiền tố tenant (`{tenant}:iam:an01:{ip}`); luật theo nhật ký (AN-03, AN-04) truy vấn Mimir hoặc Loki mỗi phút; AN-08 do `DriftDetector` phát trực tiếp. Mọi ngưỡng đọc từ tham số `12.alert.*` trong miền cho phép (ERR-12-043 khi vượt trần). `AlertDeduplicator` gộp cảnh báo cùng (luật, đối tượng) trong 30 phút. Cảnh báo mới tạo bản ghi `alert`, phát EVT-12-14 và gửi cán bộ ATTT qua kênh trong ứng dụng và thư (nội dung chỉ có liên kết, không có dữ liệu, FR-00-062) trong tối đa 60 giây; mức nghiêm trọng gửi thêm cho TA và PA. Nếu nhật ký đến chậm quá 5 phút, `AlertEngine` phát chính cảnh báo "dữ liệu giám sát chậm" thay vì im lặng.

`DecisionQueryService` dịch bộ lọc API-12-103 thành LogQL trên Loki với `X-Scope-OrgID` của tenant người gọi, nên cô lập theo SEC-84; không có tham số nào cho phép đổi tenant. PO (vận hành nền tảng) có `PERM-12-decision-read` nhưng bị giới hạn: truy vấn được cắt theo tenant đích và khoảng thời gian của các quyền có thời hạn đang hoặc đã hiệu lực của người đó, và mỗi truy vấn vào dữ liệu tenant khác tự sinh bản ghi kiểm toán ở chuỗi của tenant đó. Báo cáo (FR-12-060) chạy 01:30 hằng ngày: `AccountReport` đếm tài khoản theo trạng thái và nhóm ngày không đăng nhập; `MfaCoverageReport` tính tỷ lệ tài khoản nhóm `mfa-required` đã đăng ký yếu tố thứ hai từ bản chiếu, đối chiếu mẫu hằng tuần với Keycloak để chống lệch; kết quả lưu 24 tháng.

### 4.15. Danh bạ người dùng và tham số phân hệ

::: dac-ta
**Mục đích.** Cho phân hệ khác tra cứu thông tin tối thiểu về người dùng; cho TA, PA chỉnh tham số `12.*` trong trần của nền tảng, tách tham số bảo mật realm đi qua GitOps khỏi tham số có hiệu lực tức thời.

**Lớp chính.** `DirectoryService`, `SettingsService`, `SettingsGuard`, `GitConfigWriter`.

**Đơn vị chạy.** `dh-platform` (module `iam`).

**FR hiện thực.** FR-12-061, 062.

**Giao diện vào.** API-12-014, 110, 111.

**Phụ thuộc ra.** `ParameterApi` (PH-18); kho cấu hình Git; `RealmProvisioner`.

**Dữ liệu.** `user_account` (đọc, qua RLS); tham số `12.*` ở kho PH-18; tệp giá trị tenant ở Git.

**Sự kiện.** EVT-12-13 khi đổi tham số bảo mật realm.

**Lỗi và xử lý.** Vượt trần: ERR-12-043; thiếu quyền: ERR-12-007; `If-Match` cũ: ERR-12-044.

**Quan sát.** `iam_directory_requests_total{caller}`, `iam_settings_changes_total{key}`.
:::

Chi tiết thiết kế:

`DirectoryService` chỉ trả `{userId, username, displayName, orgCode, title, state}` (BR-12-042) và nhận bên gọi qua scope `iam:directory-read`; tenant lấy từ token dịch vụ của bên gọi, nên một DU không thể tra danh bạ của tenant khác. Truy vấn đọc bản chiếu `user_account` với RLS, phân trang theo con trỏ, giới hạn 100 dòng mỗi trang và tần suất theo client để tránh bị khai thác thành danh sách thư.

`SettingsService` đọc và ghi tham số `12.*` theo `settings-schema.json` (kiểu, miền, mặc định, cờ "bảo mật realm") sinh từ FRS mục 8.2; `SettingsGuard` chặn giá trị ngoài miền hoặc yếu hơn mức bắt buộc của TCVN 14423:2026 (ERR-12-043). Tham số có hiệu lực tức thời (ví dụ `12.pep.timeout-ms`, `12.cache.ttl-seconds`, ngưỡng cảnh báo) lưu ở kho tham số PH-18 và được các thành phần đọc lại trong tối đa 60 giây (NFR-00-052). Tham số bảo mật của realm (`12.password.min-length`, `12.lockout.*`, `12.session.*`, `12.token.access-seconds`, `12.mfa.stepup-minutes`) không áp trực tiếp: `GitConfigWriter` ghi giá trị vào tệp giá trị của tenant ở kho cấu hình dưới dạng yêu cầu hợp nhất tự động; CI kiểm chỉ có siết chặt, không nới so với mức nền, rồi job áp bằng `ConfigCliJobRunner` trong khoảng 15 phút và `RealmSnapshotNormalizer` lập lại mức chuẩn. Giao diện hiển thị rõ hai loại: "có hiệu lực ngay" và "áp dụng trong khoảng 15 phút".

## 5. Biểu đồ tuần tự

Mười bốn luồng dưới đây là những luồng nhiều bước, nhiều thành phần hoặc có duyệt bốn mắt. Với mỗi luồng, đoạn thuyết minh sau hình nói điều cần thấy: thứ tự thật của các bước, chỗ nào chốt ở máy chủ, chỗ nào có thể dừng giữa chừng và dừng thì còn lại trạng thái gì.

### 5.1. Đăng nhập OIDC qua BFF, MFA và bước lên mức xác thực (FR-12-020, 021, 022, 023)

Luồng đầu tiên cho thấy một quản trị tỉnh đăng nhập bằng khóa FIDO2 và, nửa giờ sau, bị yêu cầu xác thực lại khi phát hành luồng lên PROD.

```{.mermaid caption="Đăng nhập OIDC với PKCE, WebAuthn và bước lên mức 3 khi phát hành luồng PROD"}
sequenceDiagram
  autonumber
  actor U as Bình (TA)
  participant B as BFF dh-console
  participant K as Keycloak realm dh-t68
  participant KF as Kafka
  participant G as APISIX
  participant O as OPA sidecar
  participant D as dh-integration
  U->>B: Mở dh-console
  B-->>U: 302 tới auth với code_challenge S256, state, nonce
  U->>K: GET auth
  K-->>U: Biểu mẫu đăng nhập
  U->>K: Tên đăng nhập và mật khẩu
  K->>K: Băm mật khẩu, kiểm dò mật khẩu, dh_mfa_level là 3
  K-->>U: Thử thách WebAuthn
  U->>K: Xác nhận khóa FIDO2
  K--)KF: EVT-12-16 LOGIN, acr 3
  K-->>U: 302 về redirect_uri kèm code
  U->>B: Callback với code và state
  B->>K: POST token với code_verifier
  K-->>B: Access 5 phút, refresh, acr 3, auth_time
  B-->>U: Cookie __Host-dh-sid, không có token ở trình duyệt
  Note over U,B: 20 phút sau, người dùng phát hành luồng lên PROD
  U->>B: Phát hành luồng
  B->>G: Bearer access token
  G->>O: input với acr 3, auth_time cũ hơn 5 phút
  O-->>G: Từ chối STEPUP_REQUIRED kèm nghĩa vụ STEPUP acr 3 max_age 300
  G-->>B: 401 insufficient_user_authentication
  B-->>U: 302 tới auth với acr_values 3 và max_age 300
  U->>K: Xác nhận lại WebAuthn
  K-->>B: Token mới có auth_time mới, mã phiên sinh lại
  B->>G: Gọi lại với token mới
  G->>O: input với auth_time mới
  O-->>G: allow
  G->>D: Chuyển tiếp kèm X-DH-Tenant
```

Điểm cần thấy: trình duyệt không bao giờ giữ token (SEC-21); mức xác thực của thao tác nhạy cảm do OPA quyết định chứ không do giao diện (BR-12-016), nên gọi API trực tiếp cũng không bỏ qua được. Sai mật khẩu (bước 6) đi qua cùng đường tính toán dù tài khoản có tồn tại hay không, và sau 5 lần sai liên tiếp Keycloak khóa tạm 15 phút, ghi LOGIN_ERROR vào cùng luồng EVT-12-16 để AN-01 theo dõi. Nếu Kafka ngừng, bước 9 không chặn đăng nhập: bộ lắng nghe đệm ra đĩa.

### 5.2. Cấp client cho HTTT, đăng ký chứng thư và đưa scope vào gói chính sách (FR-12-030, 033, 036, 051)

Luồng thứ hai là đường từ hồ sơ kết nạp đã duyệt tới một client dùng được: cấp client, đăng ký chứng thư, nhận scope từ phân hệ nguồn và đưa vào dữ liệu của OPA.

```{.mermaid caption="PH-01 cấp client, đăng ký chứng thư mTLS, scope vào gói chính sách"}
sequenceDiagram
  autonumber
  participant P1 as PH-01 saga
  participant C as ClientService
  participant KC as Keycloak
  participant DB as ph12_iam
  participant G as PolicyDataGenerator
  participant S3 as Garage
  participant O as OPA APISIX
  participant PH2 as PH-02
  P1->>C: POST clients với Idempotency-Key, mTLS, mức Hạn chế
  C->>C: Kiểm phương thức theo mức hợp đồng, scope có nguồn duyệt
  C->>DB: Ghi client PROVISIONING, khóa lũy đẳng
  C->>KC: Tạo client x509, tắt grant cấm, token 300 giây
  KC-->>C: clientId ht-qlvb
  C->>DB: ENABLED, credentialReady false, outbox EVT-12-06
  C-->>P1: 201 không có bí mật
  P1->>C: PUT certificate
  C->>C: CertificateValidator kiểm chuỗi, keyUsage, hạn, độ mạnh khóa
  C->>KC: Đặt subject DN, bật token ràng buộc chứng thư
  C->>DB: credentialReady true, dấu vân tay, outbox EVT-12-08
  PH2->>C: accept scope api ho-tich goi-1, nguồn PH-02
  C->>C: Kiểm tiền tố đúng loại của nguồn PH-02
  C->>KC: Tạo client scope nếu chưa có, gán tùy chọn
  C->>DB: Thay tập scope của nguồn PH-02, đánh dấu bẩn
  G->>DB: Đọc dữ liệu tenant sau cửa sổ 5 giây
  G->>G: Kiểm nhất quán, đóng gói tất định, ký bằng OpenBao
  G->>S3: Đặt bundle.tar.gz của tenant
  O->>S3: Tải mỗi 30 giây, kiểm chữ ký
  O-->>G: Báo bundleRevision đã nạp
```

Điểm cần thấy: client có thể tồn tại ở `ENABLED` mà chưa dùng được (`credentialReady=false`) vì Keycloak chưa có cách xác thực nó; token chỉ cấp được sau khi có chứng thư. Quyền của máy đến từ hai nơi cùng lúc, scope ở Keycloak (để token mang đúng giao) và dữ liệu trong gói (để OPA quyết định cuối và để gỡ scope có hiệu lực trong 60 giây). Nếu tiến trình chết giữa bước 4 và 6, khóa lũy đẳng ở `ph12_iam` cho phép PH-01 gọi lại và `ClientService` tìm client theo `clientId` thay vì tạo trùng; bước bù trừ xóa client dở khi saga PH-01 hủy.

### 5.3. Thu hồi truy cập tức thời và phân phối danh sách chặn (FR-12-040)

Luồng thứ ba chấm dứt truy cập của một HTTT đang có token còn hạn, với yêu cầu hiệu lực tại cổng trong không quá 60 giây.

```{.mermaid caption="Thu hồi truy cập một client, hiệu lực tại cổng trong 60 giây"}
sequenceDiagram
  autonumber
  actor SO as An (SO)
  participant R as RevocationService
  participant DB as ph12_iam
  participant KC as Keycloak
  participant KF as Kafka
  participant G as APISIX nút 1
  participant H as HTTT
  participant D as DU và thư viện PEP
  SO->>R: POST clients ht-qlvb revoke với lý do
  R->>R: Kiểm lý do, không tự thu hồi mình
  R->>DB: Ghi mục CLIENT với blockAll và notBefore bây giờ, outbox EVT-12-05
  R-->>SO: 202 revocationId
  R->>KC: Tạm ngừng client, hủy phiên, thu hồi token
  Note over R,KC: Keycloak lỗi thì thử lại từ sync_task, cổng đã chặn
  loop mỗi 10 giây
    G->>R: GET revocations với If-None-Match và X-DH-Applied-Version
    R-->>G: 200 phiên bản mới hoặc 304
  end
  H->>G: Gọi API bằng token cấp 2 phút trước
  G->>G: iat nhỏ hơn notBefore của mục CLIENT
  G-->>H: 401 ERR-12-116
  DB--)KF: EVT-12-05 qua outbox
  KF--)D: BlocklistCache cập nhật
  G->>R: Lần kéo kế tiếp báo phiên bản đã áp
  R->>R: AppliedNodeTracker tính n trên m nút
  R-->>SO: Đã áp dụng ở n trên m nút cổng
```

Điểm cần thấy: danh sách chặn được ghi **trước** khi gọi Keycloak (bước 3 rồi bước 5), nên Keycloak chậm hay đang ngắt mạch cũng không làm chậm việc chặn. Hai đường phân phối độc lập (APISIX kéo, DU nghe Kafka có kéo dự phòng) nên mất một đường không làm mất thu hồi. Nút cổng nào im lặng quá 60 giây sau khi có phiên bản mới bị cảnh báo nghiêm trọng; trong trường hợp xấu nhất token còn hiệu lực tối đa 5 phút, đúng như FRS ghi nhận.

### 5.4. Quyết định ủy quyền khi HTTT gọi API, kèm fail-closed và ghi vết (FR-12-044, 045, 057)

Luồng thứ tư là đường nóng của cả hệ thống: mỗi lượt gọi API đi qua một quyết định ủy quyền ở cổng.

```{.mermaid caption="APISIX hỏi OPA cục bộ, lỗi thì từ chối, quyết định được ghi vết"}
sequenceDiagram
  autonumber
  participant H as HTTT
  participant G as APISIX plugin dh-authz
  participant O as OPA sidecar
  participant F as Fluent Bit trên nút
  participant L as Loki và PH-13
  participant B as Backend của API
  H->>G: Gọi API với Bearer và mTLS
  G->>G: Xác minh chữ ký bằng JWKS đệm, iss, aud, exp, cnf, danh sách chặn
  G->>G: Dựng input từ token và siêu dữ liệu route
  G->>O: POST decision, thời gian chờ 50 ms
  alt OPA trả lời kịp
    O->>O: Hợp deny của gói gốc và gói tenant
    alt count deny bằng 0 và có luật cho phép khớp
      O-->>G: allow, fieldMask, obligations, bundleRevision
      G->>B: Chuyển tiếp kèm X-DH-Tenant và X-DH-Field-Mask
      B-->>H: 200
    else có deny hoặc không khớp
      O-->>G: allow false, reason
      G-->>H: 403 hoặc 404 theo reason
    end
  else hết giờ, lỗi hoặc chưa nạp gói
    G-->>H: 403 POLICY_ERROR, không chuyển tiếp
  end
  O--)F: Nhật ký quyết định đã che, có req_id
  F--)L: Hàng đợi bền 24 giờ, từ chối và mức Nhạy cảm vào chuỗi băm kiểm toán
```

Điểm cần thấy: nhánh cuối cùng của `alt` là chỗ NFR-12-014 kiểm: không có đường nào chuyển yêu cầu tới backend khi OPA không trả lời hợp lệ. Việc ghi vết (hai bước cuối) không nằm trên đường trả lời, nên độ trễ ghi không cộng vào độ trễ API; đổi lại, với tài nguyên Nhạy cảm, plugin kiểm `AuditGate` trước bước 4 và từ chối `AUDIT_UNAVAILABLE` nếu đường ghi hỏng. Ở DU Spring Boot luồng giống hệt, chỉ khác bên thực thi là `DhAuthorizationManager` thay cho plugin.

### 5.5. Soạn, chạy khô, duyệt bốn mắt và phát hành gói chính sách (FR-12-052, 053, 054, 051)

Luồng thứ năm mô tả một thay đổi chính sách đi từ bản nháp của người soạn tới gói đã ký đang chạy ở mọi OPA, qua các cổng kiểm thử, chạy khô và duyệt.

```{.mermaid caption="Chính sách đi từ bản nháp tới gói đã ký đang chạy ở mọi OPA"}
sequenceDiagram
  autonumber
  actor PA as Minh (người soạn)
  participant P as PolicyService
  participant R as policy-runner
  participant LK as Loki
  participant A as ApprovalService
  actor SO as An (người duyệt)
  participant BB as BundleBuilder
  participant BAO as OpenBao
  participant S3 as Garage
  participant O as OPA các nút
  PA->>P: POST versions với nội dung Rego
  P->>P: PolicyLinter, giới hạn 256 KiB, kiểm luật tenant
  P-->>PA: 201 DRAFT, contentHash
  PA->>P: POST test
  P->>R: opa test kèm độ phủ, capabilities không có http.send
  R-->>P: Đạt, độ phủ 93 phần trăm
  PA->>P: POST dry-run
  P->>LK: Lấy mẫu quyết định đã che, tối đa 100.000
  P->>R: Hai OPA cô lập, gói hiện hành và gói nháp
  R-->>P: Tỷ lệ đổi, từ chối sang cho phép, ví dụ tiêu biểu
  PA->>P: POST submit
  P->>P: So contentHash với kết quả test và chạy khô
  P-->>PA: PENDING_REVIEW, việc vào hộp việc của SO
  SO->>A: POST approve với ý kiến, đã xác thực mức 3
  A->>A: Khác người soạn, người gửi, người đóng góp
  A->>A: Nếu đổi hơn 20 phần trăm cần confirmHighImpact
  A->>BB: APPROVED, yêu cầu dựng gói
  BB->>R: Chạy lại bộ kiểm thử gộp toàn gói
  BB->>BAO: transit sign dh-policy-signing
  BAO-->>BB: Chữ ký JWS
  BB->>S3: Đặt bundle và bản bất biến theo revision
  O->>S3: Tải mỗi 30 giây, xác minh chữ ký, nạp nóng
  O-->>BB: Báo bundleRevision qua plugin status
  BB->>P: OPA đầu tiên xác nhận
  P->>P: PUBLISHED, bản cũ SUPERSEDED, EVT-12-09
```

Điểm cần thấy: hai điều kiện "đã kiểm thử" và "đã chạy khô" gắn với `contentHash`, không phải trạng thái, nên sửa nội dung sau bước 10 làm bước 12 từ chối (ERR-12-026). Bốn mắt được kiểm ở bước 15 bằng cách so người duyệt với cả ba nhóm người (người soạn, người gửi, người đóng góp), không chỉ người tạo. Phiên bản chỉ thành `PUBLISHED` khi có OPA thật xác nhận đã nạp, nên giao diện không bao giờ báo "đã phát hành" cho một gói chưa chạy; nếu không có OPA nào xác nhận trong 5 phút thì phiên bản ở lại `APPROVED` và hệ thống đề xuất quay lui.

### 5.6. Gán vai trò, chặn xung đột và hiệu lực ở OPA (FR-12-012, 013, 051)

Luồng thứ sáu cho thấy một lần gán vai trò bị chặn vì xung đột, được mở bằng ngoại lệ do SO duyệt, rồi có hiệu lực ở OPA.

```{.mermaid caption="Gán vai trò có kiểm tra tách nhiệm vụ, ngoại lệ do SO duyệt, hiệu lực ≤ 60 giây"}
sequenceDiagram
  autonumber
  actor TA as Bình (TA)
  participant S as AssignmentService
  participant DB as ph12_iam
  participant KC as Keycloak
  participant G as PolicyDataGenerator
  participant O as OPA các nút
  actor SO as An (SO)
  TA->>S: POST role-assignments INTEGRATION_APPROVER cho Lan
  S->>DB: BEGIN, SELECT user FOR UPDATE
  S->>S: SodGuard thấy Lan đang có INTEGRATION_ENGINEER
  S-->>TA: 409 ERR-12-009
  TA->>S: POST sod-exceptions với lý do và hạn 30 ngày
  S->>DB: Ghi ngoại lệ REQUESTED, việc cho SO
  SO->>S: POST sod-exceptions decide, đã xác thực mức 3
  S->>S: So người duyệt với người đề nghị
  S->>DB: Ngoại lệ ACTIVE, outbox EVT-12-12
  TA->>S: POST role-assignments lần hai
  S->>DB: BEGIN, SELECT user FOR UPDATE, SodGuard cho phép do ngoại lệ
  S->>DB: Ghi gán, outbox EVT-12-03, COMMIT
  S-->>TA: 201
  S->>KC: Đặt vai trò realm và dh_mfa_level, thu hồi phiên nếu là hạ quyền
  G->>DB: Đọc thay đổi sau cửa sổ 5 giây
  G->>O: Gói tenant mới qua kho, trong 30 giây
  Note over O: Quyền mới có hiệu lực khi Lan có token mới, tối đa 5 phút
```

Điểm cần thấy: khóa hàng người dùng ở bước 2 và 11 là thứ ngăn hai quản trị gán đồng thời hai vai trò xung đột. Chiều hạ quyền khác chiều nâng quyền (ghi chú cuối): gỡ vai trò có hiệu lực ngay khi gói mới nạp vì OPA lấy giao của token và dữ liệu, còn thêm vai trò chỉ có tác dụng khi token mới có vai trò (BR-12-036). Ngoại lệ tự gỡ khi hết hạn bởi tác vụ nền và, độc lập, bởi luật kiểm hạn trong Rego.

### 5.7. Quyền có thời hạn để nhân sự nền tảng vào tenant khác (FR-12-017, 027)

Luồng thứ bảy là đường duy nhất để nhân sự nền tảng chạm dữ liệu của một tỉnh: đề nghị, duyệt bởi người thứ hai, thông báo cho tỉnh, dùng và tự hết hạn.

```{.mermaid caption="Đề nghị, duyệt và dùng quyền có thời hạn, thông báo tỉnh bị truy cập"}
sequenceDiagram
  autonumber
  actor PO as Hùng (PO nền tảng)
  participant GS as GrantService
  actor SO as An (SO nền tảng)
  participant AW as AuditWriter
  participant PH13 as Chuỗi kiểm toán T68
  participant G as PolicyDataGenerator
  participant GW as APISIX
  participant O as OPA
  actor TA as Bình (TA T68)
  PO->>GS: POST privileged-grants tenant T68, 2 giờ, mã phiếu HT-4821
  GS->>GS: Kiểm 4 giờ tối đa, định dạng mã phiếu, vai trò cho phép
  GS-->>PO: 201 REQUESTED
  SO->>GS: POST approve với xác thực mức 3
  GS->>GS: Khác người đề nghị
  GS->>GS: ACTIVE, startsAt bây giờ, expiresAt cộng 2 giờ, outbox EVT-12-11
  GS->>AW: Bản ghi kiểm toán cho tenant T68
  AW->>PH13: Ghi vào chuỗi băm của T68
  GS-->>TA: EVT-12-11, thông báo Hùng được vào T68 tới 16:30
  G->>O: Gói platform có grants, trong tối đa 60 giây
  PO->>GW: Gọi API platform với token realm dh-platform
  GW->>O: input tenant PLATFORM, resource.tenant T68
  O->>O: valid_cross_tenant_grant khớp và chưa hết hạn
  O-->>GW: allow kèm AUDIT FULL
  GW-->>PO: 200 và ghi vết vào chuỗi của T68
  Note over O: Sau expiresAt mỗi quyết định bị từ chối GRANT_EXPIRED mà không cần tác vụ nền
```

Điểm cần thấy: bản ghi kiểm toán và thông báo đi tới **tenant bị truy cập** (SEC-85), không phải tới tenant của người đề nghị. Người dùng chỉ dùng được quyền sau khi gói `platform` mới được nạp, nên giao diện hiển thị "đang chờ hiệu lực" thay vì báo thành công ngay. Hết hạn là thuộc tính của dữ liệu được OPA kiểm ở mọi quyết định (BR-12-032), nên không có khoảng thời gian "quyền đã hết nhưng chưa dọn".

### 5.8. Khởi tạo realm cho tenant mới và phát hiện lệch cấu hình (FR-12-041, 042)

Luồng thứ tám là bước `S03_REALM` của saga khởi tạo tenant do PH-20 gọi, kèm vòng đối chiếu cấu hình hằng giờ sau khi realm hoạt động.

```{.mermaid caption="Saga tạo realm từ mẫu Git, phát hiện lệch hằng giờ"}
sequenceDiagram
  autonumber
  participant P20 as PH-20 saga
  participant RP as RealmProvisioner
  participant GIT as Kho cấu hình Git
  participant J as Job keycloak-config-cli
  participant KC as Keycloak
  participant BAO as OpenBao
  participant G as PolicyDataGenerator
  participant DD as DriftDetector
  P20->>RP: POST realms tenant T68 với Idempotency-Key
  RP->>RP: Kiểm scope iam:realm-provision, mã tenant, realm chưa có
  RP->>GIT: Đọc mẫu dh-realm-template bản cố định
  RP->>J: Tạo Job, ConfigMap gồm mẫu và giá trị tenant
  J->>KC: Áp mẫu, realm PROVISIONING
  KC-->>J: Khóa ES256, client dh-console và dh-portal
  J-->>RP: Hoàn tất, nhật ký có cấu trúc
  RP->>BAO: Ghi bí mật client, một chiều
  RP->>KC: 22 vai trò, realm-user-admin, nhà môi giới nền tảng
  RP->>KC: Quản trị đầu tiên PENDING_ACTIVATION, dh_mfa_level 3
  RP->>G: Dựng gói tenant đầu tiên
  RP->>RP: Đọc lại realm, lập mức chuẩn, ACTIVE
  RP-->>P20: 201 realm, client không bí mật, quản trị đầu tiên
  loop mỗi giờ và khi có sự kiện quản trị lạ
    DD->>KC: Xuất cấu hình bảo mật, chuẩn hóa
    DD->>DD: So với mức chuẩn
    alt khác biệt
      DD->>DD: DRIFTED, cảnh báo AN-08, sau 15 phút tự áp lại mẫu
    end
  end
```

Điểm cần thấy: mỗi bước ghi vào `realm_provision_step` nên PH-20 gọi lại cùng khóa lũy đẳng sẽ tiếp tục từ bước dở và không tạo trùng. Thông tin xác thực quản trị tạo realm nằm ở Job, không ở pod `dh-platform`. Phát hiện lệch so với **mức chuẩn lập ngay sau khi áp mẫu**, nên nó đo đúng điều quan trọng: có ai đổi cấu hình bảo mật sau đó hay không; nếu thay đổi mẫu hợp lệ ở Git thì mức chuẩn được lập lại sau lần áp.

### 5.9. Tác vụ định kỳ tự vô hiệu tài khoản không hoạt động (FR-12-008)

Luồng cuối là tác vụ nền thực thi quy định vô hiệu tài khoản sau 45 ngày của TCVN 14423:2026.

```{.mermaid caption="Tác vụ 02:00 vô hiệu tài khoản quá 45 ngày, quản trị quá 30 ngày"}
sequenceDiagram
  autonumber
  participant SC as Scheduler 02:00
  participant IJ as InactivityJob
  participant DB as ph12_iam
  participant US as UserService
  participant R as RevocationService
  participant KC as Keycloak
  participant AW as AuditWriter
  participant AL as AlertEngine
  SC->>IJ: Chạy cho từng tenant trong TenantContext.runAs
  IJ->>IJ: Kiểm iam_auth_event_lag_seconds
  alt trễ hơn 3600 giây
    IJ->>AL: Bỏ lượt, cảnh báo thiếu dữ liệu đăng nhập
  else dữ liệu khỏe
    IJ->>DB: Chọn ACTIVE có last_login_at quá ngưỡng
    loop mỗi tài khoản
      IJ->>US: disable với actor SYSTEM, lý do INACTIVE_45D
      US->>DB: DISABLED (ngoại lệ INACTIVITY của ngưỡng hai TA), outbox EVT-12-02
      US->>R: revoke SUB
      R->>DB: Mục SUB notBefore bây giờ
      US->>KC: Vô hiệu, hủy phiên, thu hồi refresh token
      US->>AW: Kiểm toán kèm ngưỡng đã vượt
      US->>AL: Nếu là TA và tenant xuống dưới hai TA: cảnh báo khẩn SO, PA, việc bổ sung TA
    end
  end
```

Điểm cần thấy: nhánh `alt` đầu là biện pháp an toàn đặc thù của thiết kế này. Thời điểm đăng nhập cuối lấy từ luồng sự kiện chứ không từ Keycloak, nên nếu luồng sự kiện bị chậm thì tài khoản đang hoạt động có thể trông như bỏ quên; tác vụ thà bỏ một lượt (và báo) còn hơn vô hiệu nhầm cán bộ đang làm việc. Quản trị tỉnh cuối cùng không bị vô hiệu (ERR-12-046): tác vụ ghi cảnh báo thay vì thực hiện.

### 5.10. Xoay bí mật client và giao bí mật bọc một lần (FR-12-034, 030)

Luồng thứ mười là xoay bí mật của một client dùng bí mật chia sẻ (mức Công khai hoặc Nội bộ), nhấn mạnh rằng người bấm xoay không bao giờ thấy bí mật mới.

```{.mermaid caption="Xoay bí mật client, bí mật mới giao một lần cho đầu mối qua bản bọc của OpenBao"}
sequenceDiagram
  autonumber
  actor TA as Bình (TA)
  participant C as ClientService
  participant KC as Keycloak
  participant BAO as OpenBao
  participant DB as ph12_iam
  participant P1 as PH-01 hoặc PH-15
  actor DM as Đầu mối HTTT
  participant H as HTTT
  TA->>C: POST clients ht-qlvb credentials secret rotate
  C->>C: Kiểm client dùng bí mật chia sẻ, không có lần xoay đang chuyển tiếp
  C->>KC: Xoay bí mật, giữ bí mật cũ thêm 24 giờ
  KC-->>C: Bí mật mới
  C->>BAO: sys wrapping wrap, TTL 24 giờ
  BAO-->>C: wrappingToken và wrap_accessor
  C->>DB: Lưu wrap_accessor và hạn bí mật cũ, outbox EVT-12-08
  C-->>TA: 202 handoverId và hạn bí mật cũ, không có bí mật
  C->>P1: Đẩy wrappingToken qua API giao bí mật
  P1-->>DM: Thông báo có bí mật mới
  DM->>P1: Mở bí mật ở BFF của PH-01
  P1->>BAO: sys wrapping unwrap bằng wrappingToken
  BAO-->>P1: Bí mật mới, mở được đúng một lần
  P1-->>DM: Hiển thị một lần
  H->>KC: Xin token bằng bí mật mới
  Note over KC: 24 giờ sau bí mật cũ hết hiệu lực
  alt xoay khẩn với invalidateOld
    C->>KC: Xóa bí mật cũ ngay
    C->>C: RevocationService thu hồi CLIENT cho token đang lưu hành
  end
```

Điểm cần thấy: TA nhận `202` với `handoverId`, không có bí mật và không có `wrappingToken` (bước 8); token bọc đi thẳng từ `ClientService` tới phân hệ đầu mối (bước 9), nên bí mật không đi qua tay người quản trị tỉnh. Nếu đầu mối thấy lệnh mở bị OpenBao từ chối vì token đã dùng, đó là bằng chứng có người mở trước và quy trình đòi xoay lại ngay. Trong 24 giờ chuyển tiếp hai bí mật cùng dùng được để HTTT kịp đổi; xoay khẩn bỏ giai đoạn này và chặn cả token đang lưu hành.

### 5.11. Nhập người dùng hàng loạt hai pha (FR-12-009)

Luồng thứ mười một là nhập tệp tối đa 5.000 dòng theo hai pha: xem trước rồi xác nhận, để lỗi dữ liệu không tạo tài khoản dở.

```{.mermaid caption="Nhập người dùng hàng loạt: quét, kiểm tra, xem trước, xác nhận và tạo nền"}
sequenceDiagram
  autonumber
  actor TA as Bình (TA)
  participant I as ImportService
  participant AV as Bộ quét DD-12
  participant S3 as Kho tệp tạm
  participant DB as ph12_iam
  participant US as UserService
  participant KC as Keycloak
  TA->>I: POST user-imports với tệp csv
  I->>AV: Quét mã độc
  AV-->>I: Sạch
  I->>S3: Lưu tệp, hạn xóa 24 giờ
  I->>I: Đọc luồng, kiểm miền thư, đơn vị, vai trò hệ cũ, trùng
  I->>DB: Ghi user_import_row với OK, WARN hoặc ERROR
  I-->>TA: 202 importId
  TA->>I: GET user-imports importId
  I-->>TA: Tổng hợp và lỗi theo từng dòng
  TA->>I: POST commit với Idempotency-Key
  I->>DB: Đặt COMMITTING, giữ các dòng OK
  loop mỗi dòng OK, 4 luồng song song
    I->>US: create PENDING_ACTIVATION
    US->>KC: Tạo người dùng, gửi liên kết kích hoạt
    US->>DB: Ghi tài khoản, outbox EVT-12-01
  end
  I-->>TA: SSE tiến độ và kết quả cuối
  I->>S3: Xóa tệp gốc
```

Điểm cần thấy: không có mật khẩu trong tệp và mọi tài khoản sinh ra ở `PENDING_ACTIVATION` (BR-12-043). Việc tạo thật chỉ bắt đầu ở bước 12, sau khi người dùng đã xem lỗi; mỗi dòng đi qua đúng `UserService.create` của tạo tay nên có cùng kiểm tra, cùng hạn mức và cùng sự kiện. Nếu tiến trình chết giữa chừng, gọi lại `commit` cùng khóa lũy đẳng chỉ xử lý các dòng chưa `DONE`.

### 5.12. Liên kết LDAP hoặc Active Directory: kiểm tra, duyệt, áp cấu hình (FR-12-026)

Luồng thứ mười hai cho thấy một liên kết định danh ngoài chỉ hoạt động sau ba kiểm tra và sự duyệt của cán bộ ATTT.

```{.mermaid caption="Khai báo, kiểm tra, duyệt và áp cấu hình liên kết LDAP của tỉnh"}
sequenceDiagram
  autonumber
  actor TA as Bình (TA)
  participant F as FederationService
  participant BAO as OpenBao
  participant LD as LDAP của tỉnh
  actor SO as An (SO)
  participant J as Job keycloak-config-cli
  participant KC as Keycloak
  TA->>F: PUT ldap-federations với LDAPS, cơ sở tìm kiếm, ánh xạ thuộc tính
  F->>BAO: Ghi bí mật bind, một chiều
  F-->>TA: 200 DRAFT
  TA->>F: POST ldap-federations test
  F->>LD: Kết nối LDAPS, kiểm chứng thư theo CA tỉnh
  F->>LD: Bind
  F->>LD: Tìm mẫu 5 người dùng trong cơ sở đã khai báo
  LD-->>F: Kết quả
  F-->>TA: Đạt ba kiểm tra
  TA->>F: Gửi duyệt
  F-->>SO: Việc duyệt, PENDING_APPROVAL
  SO->>F: Duyệt, đã xác thực mức 3
  F->>F: Khác TA, không có bộ ánh xạ vai trò LDAP
  F->>J: Áp cấu hình, bí mật qua tham chiếu vault
  J->>KC: Tạo user storage provider ở chế độ READ_ONLY
  F->>F: ACTIVE, outbox EVT-12-13
  loop mỗi 4 giờ và 03:30 hằng ngày
    KC->>LD: Đồng bộ thay đổi hoặc đầy đủ
  end
```

Điểm cần thấy: bí mật bind đi một chiều vào OpenBao và tới Keycloak chỉ bằng tham chiếu vault (SEC-33). Nút "Gửi duyệt" chỉ bật khi cả ba kiểm tra ở bước 5 đến 7 đạt, và việc duyệt kiểm bốn mắt ở bước 13 trước khi cấu hình thật chạm Keycloak. Người dùng nguồn LDAP không bao giờ được tự gán vai trò (BR-12-029); chế độ chỉ-đọc nghĩa là Keycloak kiểm mật khẩu tại LDAP và không ghi ngược.

### 5.13. Quay lui chính sách về một gói đã từng chạy (FR-12-055)

Luồng thứ mười ba là đường thoát khi một chính sách vừa phát hành gây hại: quay về bản đã chạy tốt trong một lệnh, không cần chạy khô vì bản đích đã được duyệt.

```{.mermaid caption="Quay lui gói chính sách bằng một bản phát hành mới có nội dung của bản cũ"}
sequenceDiagram
  autonumber
  actor SO as An (SO)
  participant P as PolicyService
  participant BB as BundleBuilder
  participant BAO as OpenBao
  participant S3 as Garage
  participant O as OPA các nút
  participant AW as AuditWriter
  SO->>P: POST policy-bundles rollback tới t68-20261126-0153 kèm lý do
  P->>P: Kiểm bản đích đã từng PUBLISHED và chữ ký còn hợp lệ
  P->>BB: Dựng bản phát hành mới từ nội dung bản đích
  BB->>BAO: Ký manifest với revision mới t68-20261126-0155
  BAO-->>BB: Chữ ký JWS
  BB->>S3: Đặt bundle và bản bất biến theo revision
  P->>P: Phiên bản lỗi REVOKED, phiên bản SUPERSEDED liền trước thành PUBLISHED
  O->>S3: Tải mỗi 30 giây, kiểm chữ ký, nạp nóng
  O-->>BB: Báo revision 0155
  P->>AW: Kiểm toán kèm lý do, outbox EVT-12-10
  P-->>SO: Thông báo PA, TA và người duyệt phiên bản bị thu hồi
```

Điểm cần thấy: thay vì phát lại nguyên bản cũ (revision 0153), hệ thống ký một bản phát hành mới 0155 có nội dung của 0153, để chuỗi revision luôn tăng và khóa bộ đệm quyết định (chứa `bundleRevision`) không bao giờ trùng với khóa của giai đoạn có lỗi. Bộ đệm cũ tự mất hiệu lực vì khóa đổi. Chính sách gốc `base-authz` không thu hồi được, chỉ quay lui được (ERR-12-027).

### 5.14. Đặt lại yếu tố thứ hai của tài khoản quản trị (FR-12-024)

Luồng cuối là việc nhạy cảm nhất của khôi phục tài khoản: quản trị mất khóa FIDO2, cần người cao hơn một cấp đặt lại và cán bộ ATTT duyệt.

```{.mermaid caption="Đặt lại yếu tố thứ hai của quản trị tỉnh, cấp trên thực hiện và SO duyệt"}
sequenceDiagram
  autonumber
  actor PA as Minh (PA nền tảng)
  participant S as UserService
  actor SO as An (SO)
  participant KC as Keycloak
  participant R as RevocationService
  participant AL as AlertEngine
  actor TA as Bình (TA, người bị đặt lại)
  PA->>S: POST users userId reset-mfa kèm cách xác minh và lý do
  S->>S: Kiểm cao hơn một cấp, không phải chính mình, tài khoản quản trị cần duyệt
  S-->>PA: 202 việc duyệt cho SO
  SO->>S: Duyệt, đã xác thực mức 3
  S->>S: Khác người đặt lại
  S->>KC: Xóa mọi yếu tố thứ hai, đặt hành động bắt buộc đăng ký lại
  S->>R: Thu hồi SUB của người bị đặt lại
  R->>KC: Hủy phiên và refresh token
  S->>AL: Cảnh báo AN-06 mức Nghiêm trọng
  S-->>TA: Thư yếu tố xác thực đã được đặt lại, cùng thư tới TA và SO khác
  S->>S: Kiểm toán, outbox EVT-12-04
  Note over TA,KC: Lần đăng nhập kế tiếp buộc đăng ký WebAuthn mới
```

Điểm cần thấy: người đặt lại và người duyệt là hai người khác nhau (bước 5), và người bị đặt lại không thể tự làm việc này cho mình (ERR-12-013). Thu hồi phiên đi theo đường thu hồi chuẩn nên cổng chặn token đang sống trong 60 giây. Cảnh báo mức Nghiêm trọng gửi ngay vì đây là thao tác mà kẻ chiếm tài khoản cũng muốn làm; thư báo tới chính người dùng là cơ hội để họ phát hiện nếu họ không yêu cầu.

## 6. Đa tenant trong mã nguồn

PH-12 vừa là phân hệ đa tenant như mọi phân hệ khác, vừa là nơi tạo ra ranh giới tenant cho phần còn lại (claim `tenant`, realm, gói chính sách). Vì vậy quy tắc ở đây chặt hơn các phân hệ khác.

Mọi bảng của `ph12_iam` có `tenant_id` và `FORCE ROW LEVEL SECURITY` (D03-03-PH12). `TenantContextFilter` của `dh-platform` đặt `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch từ claim `tenant` của token (D03-10 §3). Dữ liệu của chính nền tảng (chính sách gốc, bản phát hành gói `platform`, tài khoản dịch vụ) mang `tenant_id = 'PLATFORM'` và chỉ nhân sự nền tảng thấy; nhân sự nền tảng xem dữ liệu tenant khác chỉ qua nhóm API `/api/platform/` kèm quyền có thời hạn (mục 4.4), không bằng cách đổi `app.tenant_id`.

Ranh giới realm được kiểm ba lần. Một là `JwtIssuerAuthenticationManagerResolver` của thư viện PEP chỉ chấp nhận `iss` thuộc danh sách realm `dh-{tenant}` và `dh-platform` đã đăng ký, không cho cấu hình ký tự đại diện. Hai là claim `tenant` phải bằng hậu tố của `iss`; không khớp thì từ chối và phát sự kiện an ninh (UC-SEC-06). Ba là OPA lặp lại điều kiện `input.tenant == resource.tenant` (BR-12-003). `KeycloakGateway` nhận `TenantCode` từ `TenantContext`, không bao giờ từ tham số của hàm công khai, nên một bug ở tầng dịch vụ không thể trỏ lời gọi tới realm khác; mỗi realm có token quản trị riêng (mục 4.5).

Các tài nguyên ngoài CSDL đều mang tenant trong tên: đường dẫn OpenBao `kv/dh/{tenant}/iam/*` và chính sách OpenBao theo đường dẫn; topic `{tenant}.iam.*` (tiền tố `platform` cho tenant nền tảng) với ACL theo tiền tố; khóa Valkey qua hàm `TenantKeys.of(tenant, …)`; đường dẫn gói `tenants/{tenant}/` trong bucket với khóa truy cập Garage theo tenant; nhãn `tenant` bắt buộc trên chỉ số và log, `X-Scope-OrgID` theo tenant khi gọi Loki. Tác vụ nền (vô hiệu tài khoản, đối soát, đo lệch, hết hạn quyền) lặp theo từng tenant trong `TenantContext.runAs`; ArchUnit cấm `@Scheduled` không bọc bằng `runAs` trừ tác vụ của tenant `PLATFORM`.

Có hai đặc điểm riêng của PH-12. Thứ nhất, dữ liệu trong gói chính sách của một tenant không bao giờ chứa dữ liệu của tenant khác; ngoại lệ duy nhất là gói `platform` chứa `grants` của nhân sự nền tảng, là dữ liệu của chính nền tảng. Thứ hai, người dùng thuộc nhiều tenant có tài khoản riêng ở từng realm (FR-12-027, Q12-01 của FRS), nên không có bản ghi người dùng nào dùng chung giữa tenant và không có khóa ngoại liên tenant. Hạn mức số người dùng của tenant do PH-20 đặt và PH-12 kiểm khi tạo tài khoản (ERR-12-043); giá trị mặc định ở D03-10 §5.3 là 2.000, thấp hơn quy mô thiết kế 10.000 của NFR-12-023 (Q12-27). Kiểm thử rò rỉ chéo tenant (SEC-87) là bắt buộc cho từng API của phân hệ: hai tenant giả, gọi mọi API bằng token tenant này với mã đối tượng của tenant kia, kỳ vọng `404` cùng thân với "không tồn tại" (BR-12-041).

## 7. Bảo mật

Phân hệ định danh là mục tiêu có giá trị cao nhất của toàn hệ thống (tài sản AS-10, AS-11, AS-12 ở D03-07), nên bảng dưới đây đi từ mối đe dọa tới biện pháp và vị trí hiện thực. Mã `SEC-*` và `THR-*` lấy từ D03-07, không tạo mới.

| Mối đe dọa | Biện pháp trong thiết kế | SEC | THR |
|---|---|---|---|
| Lừa đảo, chiếm tài khoản quản trị | WebAuthn bắt buộc cho quản trị tỉnh và nền tảng (`dh_mfa_level = 3`); bộ xác thực đồng nhất thông báo; AN-02 theo dõi đăng nhập hai vùng | SEC-23, SEC-22, SEC-64 | THR-09 |
| Nhồi thông tin xác thực, dò mật khẩu | Phát hiện dò của Keycloak (5 lần, 15 phút, khóa hẳn sau 3 lần), danh sách mật khẩu lộ, giới hạn tần suất token ở APISIX, AN-01 | SEC-22, SEC-10 | THR-12 |
| Phiên bị bỏ quên | Nhàn rỗi 15 phút, tối đa 10 giờ, 3 phiên đồng thời (quản trị 1), đổi mật khẩu hoặc yếu tố thì hủy mọi phiên | SEC-29, SEC-23 | THR-13 |
| Đánh cắp token qua XSS hoặc nghe lén | BFF giữ token phía máy chủ, token 5 phút, token máy ràng buộc chứng thư `cnf`, thu hồi ≤ 60 giây | SEC-21, SEC-24, SEC-25 | THR-10 |
| Quản trị tỉnh tự nâng quyền, tắt MFA, tạo client rộng | `realm-user-admin` không có `manage-*`; vai trò `PLATFORM_*` không tồn tại ngoài `dh-platform`; cấu hình realm giữ bằng GitOps, đối chiếu hằng giờ và khi có sự kiện quản trị lạ; scope client chỉ do dữ liệu đã duyệt | SEC-20, SEC-65, SEC-60 | THR-38 |
| Sửa gói chính sách để mở quyền | Gói ký bằng khóa transit không xuất được, OPA kiểm chữ ký; duyệt bốn mắt; Rego chạy trong `policy-runner` cô lập, không có `http.send`; tenant chỉ thêm luật chặt | SEC-26, SEC-36, SEC-07 | THR-39 |
| Keycloak hoặc OPA ngừng làm API dừng | JWKS đệm tới 24 giờ, OPA sidecar với gói lưu bền, `pg-iam` riêng, Keycloak 3 bản sao; nhưng khi OPA lỗi thì từ chối chứ không cho qua | SEC-25, SEC-26, SEC-71 | THR-40 |
| Giả header tenant | Tenant chỉ từ token đã xác minh; PEP bỏ qua `X-DH-Tenant` khi gọi từ ngoài mesh | SEC-80 | THR-06 |
| Lỗi ủy quyền mức đối tượng (BOLA) | Luật `org_scope_permits` và thuộc tính chủ sở hữu trong `input`; ca kiểm thử sinh từ ma trận | SEC-26, SEC-42 | THR-03 |
| Suy ra sự tồn tại qua `403` và `404` | Đối tượng ngoài phạm vi luôn `404` cùng thân; thời gian phản hồi đồng nhất | SEC-85, SEC-87 | THR-35 |
| Lộ bí mật client hoặc LDAP | Bí mật bọc một lần, không lưu ở `ph12_iam`, chính sách OpenBao theo đường dẫn tenant, bộ lọc che log, ca canary `DH-CANARY-…` | SEC-24, SEC-32, SEC-33 | THR-37 |
| Đặc quyền thường trực | Quyền cao cấp theo yêu cầu tối đa 4 giờ, người duyệt thứ hai, ghi vào chuỗi của tenant bị truy cập | SEC-28, SEC-85 | THR-38 |
| SSRF, XXE qua siêu dữ liệu SAML và tệp nhập | Siêu dữ liệu nhận bằng tệp, không tải URL; bộ phân tích `SecureXml`; tệp nhập qua bộ quét DD-12 và đọc luồng | SEC-43, SEC-45 | — |
| Bí mật hoặc dữ liệu cá nhân trong log, vết, thông báo lỗi | Kiểu `SecretValue` ghi đè `toString`; bộ che `@Classified` và `mask_decision`; ProblemDetail không có stack trace | SEC-32, SEC-43 | — |
| Truy cập console quản trị Keycloak từ ngoài | Console chỉ từ Z7 qua VPN và bastion có MFA | SEC-19, SEC-20 | — |
| Tài khoản bỏ quên, nhân sự đã nghỉ | Vô hiệu 45 ngày (quản trị 30), rà soát quyền định kỳ, thu hồi ≤ 24 giờ khi nghỉ việc | SEC-27, SEC-03 | — |
| Thiếu vết hoặc vết bị sửa | Chuỗi băm kiểm toán, WORM 5 năm; không có vết thì không phục vụ dữ liệu Nhạy cảm | SEC-60, SEC-61, SEC-62 | — |

: Mối đe dọa và biện pháp của PH-12

**Kiểm tra quyền ở máy chủ.** API quản trị của PH-12 tự dùng thư viện PEP như mọi DU: mỗi `@RestController` gắn `@RequiresPermission("PERM-12-…")` sinh từ chú thích `x-datahub-permission` trong OpenAPI (D03-04-PH12), nên không có endpoint nào không qua OPA, và ca kiểm thử phân quyền sinh từ ma trận D02-08 chạy trên chính OPA thật. Hai nhóm endpoint không có `PERM` được xử lý bằng thuộc tính của chủ thể thay vì vai trò: "người rà soát được giao" của API-12-043 (`resource.reviewerId == subject.id`) và "chính chủ tài khoản" của API-12-054, 055 (`resource.userId == subject.id`); luật `owner_permits` của gói gốc hiện thực cả hai và vẫn chịu `count(deny) == 0`. Nút ẩn ở giao diện chỉ là tiện ích, không là lớp bảo vệ. Giá trị bí mật không bao giờ là trường của DTO trả về; `SecretValue` bị cấm log bằng ArchUnit (CC-SEC của D04-01).

**Mô hình mối đe dọa riêng của phân hệ (theo SEC-40).** Ba điểm chiếm lĩnh có hậu quả lớn nhất là: (1) kẻ tấn công có chỗ ghi vào kho gói `dh-platform-policy` hoặc bucket Garage; phòng bằng chữ ký (OPA từ chối gói không ký đúng, khóa ký chỉ ở OpenBao) nên ghi được kho vẫn không đổi được chính sách; (2) kẻ tấn công điều khiển được `dh-platform`; phòng bằng việc `dh-platform` không giữ thông tin xác thực tạo realm (ở Job), không đọc được bí mật client (chỉ ghi và bọc), chỉ có `realm-user-admin` ở từng realm, và mọi thay đổi chính sách vẫn cần người duyệt thứ hai ở hộp việc; (3) kẻ tấn công điều khiển được một DU và gọi `decide` với tenant khác; phòng bằng việc tenant của `decide` lấy từ token dịch vụ và OPA kiểm cách ly. Rủi ro tồn dư lớn nhất là chính sách Rego sai hợp lệ đã qua hai người duyệt, được chạy khô để lộ tác động nhưng không loại trừ hết.

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

Mỗi đối tượng có vòng đời ở FRS mục 4.3…4.7 hoặc ở thiết kế này. Cột cuối cho biết điều kiện mà **máy chủ** kiểm; giao diện chỉ hiển thị trước.

| Đối tượng | Từ | Lệnh | Sang | Kiểm ở máy chủ |
|---|---|---|---|---|
| UserAccount | (mới) | tạo | PENDING_ACTIVATION | Miền thư, đơn vị còn hiệu lực, hạn mức người dùng (ERR-12-004, 005, 043) |
| UserAccount | PENDING_ACTIVATION | kích hoạt | ACTIVE | Liên kết còn hạn 24 giờ (ERR-12-016), mật khẩu đạt chính sách (ERR-12-015) |
| UserAccount | PENDING_ACTIVATION | hệ thống | DISABLED | Quá 30 ngày chưa kích hoạt |
| UserAccount | ACTIVE | hệ thống | LOCKED | 5 lần sai liên tiếp (Keycloak) |
| UserAccount | LOCKED | hết hạn, mở khóa | ACTIVE | 15 phút hoặc TA, SO; không tự mở khóa mình (ERR-12-013) |
| UserAccount | LOCKED | hệ thống | BLOCKED | 3 lần khóa tạm trong 24 giờ |
| UserAccount | BLOCKED | mở khóa | ACTIVE | TA hoặc SO khác người bị khóa |
| UserAccount | ACTIVE | vô hiệu, hệ thống | DISABLED | Lý do; tenant đã kích hoạt còn ít nhất hai TA hiệu lực sau thao tác (ERR-12-046), trừ ngoại lệ không dùng quá ngưỡng (`INACTIVE_45D`, `INACTIVE_30D_ADMIN`) và sự cố ATTT, kèm cảnh báo khẩn và việc bổ sung TA; không tự vô hiệu mình |
| UserAccount | DISABLED | kích hoạt lại | ACTIVE | Buộc đặt mật khẩu mới; đăng ký lại yếu tố nếu thuộc nhóm bắt buộc |
| Client | (mới) | cấp | PROVISIONING | Không trùng HTTT (ERR-12-018), phương thức theo mức hợp đồng (ERR-12-022) |
| Client | PROVISIONING | hệ thống | ENABLED, FAILED | Keycloak tạo thành công; lỗi thì bù trừ |
| Client | ENABLED | tạm ngừng, hệ thống | SUSPENDED | Lý do; hoặc 90 ngày không gọi |
| Client | SUSPENDED | tiếp tục | ENABLED | Đầu mối xác nhận nếu tạm ngừng tự động (ERR-12-020) |
| Client | ENABLED, SUSPENDED | thu hồi | REVOKED | Lý do; không đảo ngược, mã không dùng lại |
| PolicyVersion | DRAFT | gửi duyệt | PENDING_REVIEW | Kiểm thử đạt, chạy khô đúng `contentHash` (ERR-12-025, 026) |
| PolicyVersion | PENDING_REVIEW | từ chối | CHANGES_REQUESTED | Ý kiến bắt buộc |
| PolicyVersion | CHANGES_REQUESTED | sửa | DRAFT | Kết quả cũ mất hiệu lực |
| PolicyVersion | PENDING_REVIEW | duyệt | APPROVED | Bốn mắt, xác thực mức 3, xác nhận khi tác động lớn (ERR-12-008, 029) |
| PolicyVersion | APPROVED | hệ thống | PUBLISHED | OPA đầu tiên xác nhận `bundleRevision` |
| PolicyVersion | PUBLISHED | hệ thống | SUPERSEDED | Phiên bản mới cùng mã được phát hành |
| PolicyVersion | PUBLISHED | thu hồi, quay lui | REVOKED | Không phải chính sách gốc (ERR-12-027) |
| PolicyVersion | DRAFT | bỏ | DISCARDED | Chỉ người soạn hoặc đóng góp |
| PolicyVersion | DRAFT | tự lưu (API-12-112) | DRAFT | Chỉ người soạn, kèm `If-Match`; kết quả kiểm thử và chạy khô cũ mất hiệu lực; phiên bản không ở `DRAFT` trả ERR-12-027 |
| PrivilegedGrant | (mới) | đề nghị | REQUESTED | Tối đa 4 giờ, mã phiếu (ERR-12-030) |
| PrivilegedGrant | REQUESTED | duyệt | ACTIVE | Khác người đề nghị, xác thực mức 3 (ERR-12-008) |
| PrivilegedGrant | REQUESTED | từ chối, rút, quá hạn chờ | REJECTED, CANCELLED | Quá 4 giờ chờ duyệt (giả định, bằng thời hạn tối đa của quyền) |
| PrivilegedGrant | ACTIVE | hệ thống, thu hồi | EXPIRED, REVOKED | `expiresAt` hoặc người có quyền thu hồi sớm |
| SodException | (mới) | đề nghị | REQUESTED | TA; lý do ≥ 30 ký tự; hạn ≤ 90 ngày; cặp cho phép ngoại lệ |
| SodException | REQUESTED | duyệt, từ chối | ACTIVE, REJECTED | SO khác người đề nghị |
| SodException | REQUESTED | rút đề nghị | CANCELLED | TA rút trước khi SO duyệt (FR-12-013) |
| SodException | ACTIVE | hệ thống, thu hồi | EXPIRED, REVOKED | Hết hạn tự gỡ vai trò thứ hai |
| Realm | (mới) | tạo | PROVISIONING | Scope `iam:realm-provision`; chưa có realm (ERR-12-041) |
| Realm | PROVISIONING | hệ thống | ACTIVE | Kiểm tra khói của saga PH-20 đạt |
| Realm | ACTIVE | tạm ngừng | SUSPENDED | Tenant bị tạm ngừng; lý do |
| Realm | SUSPENDED | khôi phục | ACTIVE | Tenant được khôi phục |
| Realm | ACTIVE | sáp nhập | READ_ONLY | Tenant đã sáp nhập |
| Realm | READ_ONLY, SUSPENDED | chấm dứt | DELETED | Hết thời gian bàn giao |
| Federation | DRAFT | gửi duyệt | PENDING_APPROVAL | Ba kiểm tra (kết nối, bind, mẫu người dùng) đạt (ERR-12-032) |
| Federation | PENDING_APPROVAL | duyệt, từ chối | ACTIVE, DRAFT | SO khác TA (`PERM-12-approve`) |
| Federation | ACTIVE | tắt | DISABLED | Lý do; người dùng nguồn này giữ tài khoản ở trạng thái hiện tại |
| RecertCampaign | OPEN | đóng, hạn | CLOSED | Mục chưa trả lời bị gỡ quyền (BR-12-044) |
| Alert | OPEN | xác nhận | ACKNOWLEDGED | `PERM-12-alert`; ghi người xác nhận |
| BundleRelease | BUILDING | hệ thống | SIGNED, FAILED | Nhất quán đạt, ký được |
| BundleRelease | SIGNED | hệ thống | PUBLISHED, SUPERSEDED | OPA đầu tiên xác nhận; bản mới hơn thay thế |

: Bảng chuyển trạng thái

Mỗi aggregate có cột `version` làm khóa lạc quan; lệnh từ API mang `If-Match` (không khớp thì ERR-12-044, `412`), lệnh hệ thống (khóa tạm, hết hạn, vô hiệu 45 ngày) thử lại tối đa 3 lần khi xung đột. Chuyển trạng thái nằm trong phương thức của aggregate, không ở controller; ArchUnit cấm gán trực tiếp trường `state` ngoài aggregate.

### 8.2. Outbox và sự kiện

Mười lăm sự kiện EVT-12-01…15 ghi vào bảng `outbox` **cùng giao dịch** với thay đổi trạng thái (ADR-042); `OutboxPublisher` (Debezium outbox router hoặc bộ quét 500 ms, dùng chung cơ chế với các module khác của `dh-platform`) đẩy lên Kafka định dạng CloudEvents 1.0. Khóa phân vùng chọn để giữ thứ tự theo đối tượng: `userId` cho EVT-12-01…04, `clientId` cho 06…08, `policyCode` cho 09, 10, `grantId` cho 11, `exceptionId` cho 12, `tenantCode` cho 05, 13, 15, `alertId` cho 14. Bên tiêu thụ lũy đẳng theo `id` sự kiện; bản chiếu và bộ ghi chính sách bỏ qua sự kiện có `version` thấp hơn trạng thái đang giữ. EVT-12-16 không đi qua outbox vì không có giao dịch control plane: Keycloak phát trực tiếp bằng producer idempotent. Sự kiện của tenant `PLATFORM` dùng tiền tố `platform`. Header `dhtenant` và tên topic phải khớp, không khớp thì chuyển DLQ và phát cảnh báo (D03-10 §3).

API ghi dùng `Idempotency-Key` (ADR-041): bảng `idempotency_key` giữ khóa, băm thân và phản hồi 24 giờ; cùng khóa khác thân là ERR-12-045 (`422`). Riêng các lời gọi của saga (PH-01, PH-20) khóa lũy đẳng còn là khóa tìm lại tiến trình dở (mục 4.8, 4.10).

### 8.3. Thử lại, thời gian chờ, ngắt mạch

Bảng dưới đặt thời gian chờ, số lần thử lại và hành vi khi lỗi cho từng lời gọi ra ngoài; điểm đáng chú ý là hai nơi cố ý không thử lại.

| Lời gọi | Thời gian chờ | Thử lại | Ngắt mạch hoặc xử lý khi lỗi |
|---|---|---|---|
| PEP tới OPA cục bộ | 50 ms (`12.pep.timeout-ms`, 10…200) | Không bao giờ | Không có: lỗi là từ chối, `iam_pep_failclosed_total{cause}` |
| `dh-platform` tới Keycloak Admin API (GET, PUT) | 2 giây kết nối, 5 giây đọc | 2 lần, 200 ms rồi 400 ms | 50% trên 10 lượt, nửa mở 30 giây; ERR-12-038 |
| `dh-platform` tới Keycloak Admin API (POST tạo) | Như trên | Không tự thử lại | Ý định ở `sync_task`, `SyncReconciler` phát lại lũy đẳng |
| OpenBao (ký, bọc, đọc) | 2 giây | 2 lần, 200 ms rồi 400 ms | 50% trên 10 lượt, nửa mở 30 giây; ERR-12-039; không phát hành gói, không cấp bí mật |
| Garage (đặt gói) | 10 giây | 3 lần | Việc phát hành ở lại hàng đợi, cảnh báo sau 3 phút |
| `policy-runner` | 60 giây (test), 10 phút (chạy khô) | Không | Báo lỗi cho người soạn, ERR-12-040 |
| Loki (mẫu chạy khô, tra cứu) | 10 giây | 1 lần | ERR-12-040 |
| Job `keycloak-config-cli` | 4 phút | Saga bên gọi thử lại cả bước | ERR-12-038, 040; hủy Job quá hạn |
| PH-07 (danh mục đơn vị) | 3 giây | 2 lần | Dùng bản đệm; bản đệm cũ quá 24 giờ thì chặn tạo tài khoản mới (ERR-12-040) |
| Kafka producer (outbox) | 5 giây | Vô hạn có hãm | Outbox giữ sự kiện; thu hồi vẫn có hiệu lực qua API kéo |
| LDAP (kiểm tra, đồng bộ) | 10 giây | 1 lần | ERR-12-032; đồng bộ lỗi không đổi tài khoản hiện có |
| Dịch vụ thư | 10 giây | Hàng đợi, 3 lần trong 1 giờ | TA gửi lại thủ công (API-12-009) |

: Thử lại, thời gian chờ, ngắt mạch

Nguyên tắc: không thử lại ở nơi thử lại có thể biến lỗi thành quyền (PEP), và không thử lại tự động ở nơi thử lại có thể tạo trùng (tạo người dùng, tạo client); những chỗ đó dùng ý định bền vững cộng khả năng tìm lại bằng thuộc tính.

### 8.4. Nhất quán giữa Keycloak, OpenBao, `ph12_iam` và kho gói

Bốn kho không chung giao dịch, nên thiết kế chấp nhận trạng thái trung gian nhưng bảo đảm từng trạng thái trung gian có thể phát hiện và sửa được. Bảng sau liệt kê tình huống chết giữa chừng và cách khôi phục.

| Tình huống | Trạng thái còn lại | Khôi phục |
|---|---|---|
| Tiến trình chết sau khi ghi ý định, trước khi tạo người dùng ở Keycloak | `user_account` `sync_state=PENDING`, chưa có `keycloak_id` | `SyncReconciler` phát lại, tra Keycloak theo `dh_user_id` rồi mới tạo |
| Keycloak đã tạo, ghi `keycloak_id` thất bại | Người dùng có ở Keycloak với `dh_user_id` | Cùng bộ đối soát gắn lại theo thuộc tính, không tạo trùng |
| OpenBao đã bọc bí mật, giao dịch client thất bại | Bí mật bọc mồ côi | Hết hạn sau 24 giờ; lần gọi lại sinh bí mật mới |
| Gói đã ký, đặt vào Garage thất bại | `BundleRelease` ở `SIGNED`, chưa `PUBLISHED` | Việc phát hành thử lại; `digest` bảo đảm lũy đẳng |
| Gói đã đặt, không OPA nào xác nhận trong 5 phút | Phiên bản chính sách ở `APPROVED` | Cảnh báo nghiêm trọng, đề xuất quay lui; OPA tiếp tục dùng gói cũ |
| Danh sách chặn đã ghi, Keycloak chưa vô hiệu | Mục thu hồi mang `blockAll` | Cổng từ chối mọi token của chủ thể; `sync_task` thử lại Keycloak, khi xác nhận mới hạ cờ và đặt hạn 330 giây |
| Job config-cli chết giữa chừng khi tạo realm | Realm `PROVISIONING`, `realm_provision_step` ghi bước cuối thành công | PH-20 gọi lại cùng khóa lũy đẳng, tiếp tục từ bước dở; hoặc gọi xóa realm đang `PROVISIONING` |
| Keycloak và `ph12_iam` lệch số người dùng hoặc client | Chênh lệch ở báo cáo đối soát | Keycloak đúng với thông tin đăng nhập, `ph12_iam` đúng với vai trò, phạm vi; sửa theo nguyên tắc đó và ghi cảnh báo |
| Bộ ghi nhật ký quyết định ngừng | Hàng đợi bền trên nút, tài nguyên Nhạy cảm bị từ chối | Gửi lại khi khôi phục; đã mất tối đa vài giây bộ đệm của OPA (chấp nhận với mức thấp) |

: Tình huống chết giữa chừng và cách khôi phục

### 8.5. Mã lỗi

Mã ERR-12 là của FRS (47 mã điều khiển 001…047, 19 mã runtime 101…125); thiết kế quy định lớp nào ném mã nào và ánh xạ sang lời đáp.

| Nhóm | Mã | Lớp ném | Ghi chú |
|---|---|---|---|
| Quản trị người dùng, vai trò, client, chính sách | ERR-12-001…047 | Aggregate hoặc dịch vụ trong `internal/*`; `web/` chuyển thành `ProblemDetail` RFC 9457 kèm `type`, `code`, `traceId` | Thân `404` của đối tượng ngoài phạm vi giống hệt thân "không tồn tại" |
| Quyết định ủy quyền | ERR-12-101…104, 123, 124 | `DhAuthorizationManager`, `XacmlAdapter`, `web` của `decide` | Từ chối ở API `decide` vẫn là `200`; mã chỉ cho lỗi hệ thống |
| Xác thực và cấp token | ERR-12-111…122, 125 | `KafkaEventListenerProvider` gán `err` từ mã lỗi RFC 6749 của Keycloak | Hiển thị cho người dùng theo trang Keycloak, ghi vào EVT-12-16 |

: Mã lỗi theo nhóm và lớp ném

Ánh xạ lỗi OIDC của Keycloak sang mã ERR trong sự kiện: `invalid_grant` thành ERR-12-111 (sai thông tin) hoặc ERR-12-115 (refresh dùng lại); `invalid_client` thành ERR-12-117; `unauthorized_client` thành ERR-12-118; `invalid_scope` thành ERR-12-119; `insufficient_user_authentication` thành ERR-12-120; `unsupported_grant_type` thành ERR-12-122; khóa tạm thành ERR-12-112 và khóa hẳn thành ERR-12-113.

## 9. Cấu hình và cờ tính năng theo tenant

Cấu hình có ba lớp. Lớp một là 38 tham số nghiệp vụ `12.*` ở FRS mục 8.2, lưu ở kho tham số của PH-18 theo tenant, miền giá trị do nền tảng đặt, có hiệu lực trong 60 giây (riêng nhóm bảo mật realm qua GitOps trong khoảng 15 phút, mục 4.15). Lớp hai là cấu hình triển khai `dh.iam.*` trong `application.yml`, do nền tảng đặt, không thay đổi theo tenant. Lớp ba là cờ tính năng. Khi một tham số `12.*` và một khóa `dh.iam.*` cùng nghĩa (ví dụ thời gian chờ PEP), tham số `12.*` thắng và khóa `dh.iam.*` chỉ là giá trị mặc định khi không đọc được PH-18.

| Khóa `dh.iam.*` | Mặc định | Ý nghĩa |
|---|---|---|
| `keycloak.connect-timeout`, `keycloak.read-timeout` | 2 s, 5 s | Thời gian chờ Admin API |
| `keycloak.token-refresh-margin` | 30 s | Làm mới token quản trị trước hạn |
| `reconciler.interval` | 5 m | Chu kỳ `SyncReconciler` |
| `opa.url` | `http://127.0.0.1:8181` | Địa chỉ OPA cục bộ |
| `bundle.debounce`, `bundle.safety-tick` | 5 s, 30 s | Gom thay đổi và lưới an toàn dựng gói |
| `bundle.max-size` | 20 MiB | Quá ngưỡng thì chia theo đơn vị và cảnh báo |
| `bundle.ack-timeout` | 5 m | Quá hạn chưa OPA nào nạp thì cảnh báo, đề xuất quay lui |
| `revocation.feed-poll`, `revocation.entry-ttl` | 10 s, 330 s | Chu kỳ kéo của cổng, hạn giữ mục sau khi Keycloak xác nhận |
| `inactivity.cron`, `inactivity.lag-guard` | `0 0 2 * * *`, 3600 s | Giờ chạy và ngưỡng trễ sự kiện để bỏ lượt |
| `grant.expiry-scan`, `assignment.expiry-scan` | 30 s, 60 s | Chu kỳ dọn quyền hết hạn |
| `runner.test-timeout`, `runner.dryrun-timeout` | 60 s, 10 m | Thời gian chờ `policy-runner` |
| `realm.config-job-timeout` | 4 m | Thời gian chờ Job config-cli |
| `realm.drift-cron` | `0 5 * * * *` | Đối chiếu cấu hình realm hằng giờ |
| `alert.eval-interval` | 60 s | Chu kỳ chấm điểm luật theo nhật ký |
| `directory.max-page-size` | 100 | Trang tối đa của API danh bạ |

: Cấu hình triển khai của module `iam`

Cờ tính năng (OpenFeature, cùng nhà cung cấp với các module khác của `dh-platform`, giá trị theo tenant):

| Cờ | Mặc định | Ý nghĩa |
|---|---|---|
| `iam.role.custom` | `false` | Vai trò tùy biến của tenant (FR-12-015, Đợt 2); đồng bộ với `12.role.custom-enabled` |
| `iam.recert.enabled` | `false` | Chiến dịch rà soát quyền (FR-12-018, Đợt 2) |
| `iam.merge.enabled` | `false` | Chuyển định danh khi sáp nhập (FR-12-019, Đợt 2) |
| `iam.vneid.enabled` | `false` | Liên kết VNeID (FR-12-028, Đợt 2); đồng bộ với `12.vneid.enabled` |
| `iam.devclient.enabled` | `false` | Client sandbox cho PH-15 (FR-12-032, Đợt 2) |
| `iam.decision.cache` | `true` | Bộ đệm quyết định ở thư viện PEP; tắt bằng `12.cache.ttl-seconds = 0` |
| `iam.realm.auto-reconcile` | `true` | Tự áp lại mẫu khi lệch; đồng bộ với `12.realm.auto-reconcile` |

: Cờ tính năng theo tenant

Năm cờ đầu ứng với năm FR sang Đợt 2; ở MVP các API tương ứng (API-12-022…024, 041…046, 054, 055, 063) trả `404` khi cờ tắt, đúng như một tính năng chưa tồn tại, thay vì `403`.

## 10. Quan sát

Phân hệ phát chỉ số theo chuẩn Prometheus có tiền tố `iam_`, nhãn `tenant` bắt buộc (OTel Collector từ chối dữ liệu thiếu nhãn, SEC-84). Bảng dưới gồm chín chỉ số NFR-12-026 yêu cầu và các chỉ số phục vụ vận hành từng thành phần.

| Chỉ số | Kiểu | Nhãn | Nguồn |
|---|---|---|---|
| `iam_decisions_total` | counter | `tenant`, `result` (`allow`, `deny`, `error`), `policy`, `reason` | Thư viện PEP, plugin APISIX |
| `iam_client_decisions_total` | counter | `tenant`, `client`, `result` | PEP (phục vụ AN-03; 200 client mỗi tenant nên số chuỗi vẫn nhỏ) |
| `iam_decision_duration_seconds` | histogram | `tenant`, `source` (`opa`, `cache`) | PEP (đo thêm `evaluationTimeMs` của OPA) |
| `iam_cache_hits_total`, `iam_cache_misses_total` | counter | `tenant` | `DecisionCache` |
| `iam_pep_failclosed_total` | counter | `tenant`, `cause` (`timeout`, `error`, `not_loaded`, `bad_response`, `audit_unavailable`) | `OpaClient`, `AuditGate` |
| `iam_login_total` | counter | `tenant`, `result`, `method` (`password`, `ldap`, `saml`, `vneid`, `webauthn`) | Keycloak (qua `KafkaEventListener`) |
| `iam_token_issued_total` | counter | `tenant`, `grant` | Keycloak |
| `iam_active_sessions` | gauge | `tenant` | Keycloak |
| `iam_auth_event_lag_seconds` | gauge | `tenant` | `SecurityEventConsumer` |
| `iam_event_listener_dropped_total` | counter | `tenant` | `KafkaEventListenerProvider` |
| `iam_users_total` | gauge | `tenant`, `state` | `UserService` (bản chiếu) |
| `iam_inactive_disabled_total` | counter | `tenant`, `kind` (`user`, `client`) | `InactivityJob` |
| `iam_import_rows_total` | counter | `tenant`, `result` | `ImportService` |
| `iam_role_assignments_total`, `iam_sod_blocked_total` | counter | `tenant`, `role` | `AssignmentService`, `SodGuard` |
| `iam_privileged_grants_active`, `iam_recert_overdue_items` | gauge | `tenant` | `GrantService`, `RecertService` |
| `iam_clients_total` | gauge | `tenant`, `state`, `auth_method` | `ClientService` |
| `iam_client_secret_age_days` | gauge | `tenant`, `client` | `ClientService` |
| `iam_scope_sync_total` | counter | `tenant`, `source`, `result` | `ScopeSynchronizer` |
| `iam_revocations_total`, `iam_revocation_apply_seconds` | counter, histogram | `tenant`, `kind` | `RevocationService` |
| `iam_revocation_applied_nodes` | gauge | `tenant`, `version` | `AppliedNodeTracker` |
| `iam_key_age_days` | gauge | `tenant` (realm) | `KeyRotationMonitor` |
| `iam_policy_versions` | gauge | `tenant`, `state` | `PolicyService` |
| `iam_policy_test_seconds`, `iam_policy_dryrun_changed_ratio` | histogram, gauge | `tenant`, `policy` | `TestSuiteService`, `DryRunService` |
| `iam_policy_approvals_total` | counter | `tenant`, `result` | `ApprovalService` |
| `iam_policy_reload_seconds` | histogram | `tenant`, `stage` (`first`, `last`) | `BundleAckTracker` |
| `iam_bundle_size_bytes`, `iam_bundle_build_total`, `iam_bundle_acked_nodes` | gauge, counter, gauge | `tenant`, `revision`, `result` | `BundleBuilder`, `BundleAckTracker` |
| `iam_realm_state`, `iam_realm_drift`, `iam_realm_provision_seconds` | gauge, gauge, histogram | `tenant`, `state` | `RealmProvisioner`, `DriftDetector` |
| `iam_keycloak_calls_total`, `iam_keycloak_call_duration_seconds` | counter, histogram | `tenant`, `op`, `result` | `AdminClient` |
| `iam_keycloak_circuit_state`, `iam_keycloak_sync_pending` | gauge | `tenant` | `AdminClient`, `SyncReconciler` |
| `iam_alerts_total`, `iam_alert_latency_seconds` | counter, histogram | `tenant`, `rule`, `severity` | `AlertEngine` |
| `iam_federation_sync_users`, `iam_federation_sync_failures_total` | gauge, counter | `tenant`, `federation` | `LdapSyncMonitor` |
| `iam_directory_requests_total`, `iam_settings_changes_total` | counter | `tenant`, `caller`, `key` | `DirectoryService`, `SettingsService` |

: Chỉ số do PH-12 phát ra

Nhãn không bao giờ chứa mã người dùng, địa chỉ IP hay giá trị tài nguyên (tránh bùng nổ chuỗi và lộ dữ liệu); `client` chỉ có ở hai chỉ số cần cho AN-03 và tuổi bí mật. Vết (OpenTelemetry): span `iam.decide` (thuộc tính `dh.permission`, `dh.result`, `dh.reason`, `dh.bundle_revision`), `iam.keycloak.call` (`op`, `status`), `iam.bundle.build` (`revision`, `digest`), `iam.policy.dryrun` (`samples`, `changed_ratio`); mọi span mang `tenant_id` và `trace_id` khớp PH-04, PH-13 (NFR-12-027). Không ghi giá trị `input` đầy đủ, không ghi token, chỉ ghi băm mã chủ thể. Log JSON có `tenant`, `traceId`, `actor`, `action`; không có mật khẩu, mã TOTP, bí mật, token đầy đủ, số định danh rõ (BR-12-045), và được kiểm tự động bằng ca canary.

Cảnh báo vận hành tối thiểu do nền tảng cài sẵn (ngoài AN-01…09 là cảnh báo nghiệp vụ gửi cán bộ ATTT):

| Cảnh báo | Điều kiện | Mức |
|---|---|---|
| `IamPepFailClosedHigh` | `iam_pep_failclosed_total` vượt 1% số quyết định trong 5 phút | Cao |
| `IamBundleNotApplied` | `iam_bundle_acked_nodes` thấp hơn số nút OPA sau 5 phút kể từ khi ký | Nghiêm trọng |
| `IamRevocationLag` | `iam_revocation_applied_nodes` thấp hơn số nút cổng sau 60 giây | Nghiêm trọng |
| `IamKeyAgeHigh` | `iam_key_age_days` ≥ 85 mà chưa có khóa mới | Cao |
| `IamAuthEventLag` | `iam_auth_event_lag_seconds` > 600 | Trung bình |
| `IamKeycloakCircuitOpen` | `iam_keycloak_circuit_state` mở quá 2 phút | Cao |
| `IamRealmDrift` | `iam_realm_drift` bằng 1 | Nghiêm trọng |
| `IamDecisionLogDropped` | `iam_decision_log_dropped_total` tăng | Cao |

: Cảnh báo vận hành của PH-12

## 11. Hiệu năng và vận hành

Phần này nêu định cỡ, các ước lượng tải kèm giả định, và các việc vận hành cần có sổ tay; số liệu thật sẽ thay giả định sau khảo sát tỉnh thí điểm.

- **Định cỡ** (giả định theo hồ sơ "tỉnh vừa", GĐ-12-02, D03-09 §5.3): Keycloak 3 bản sao 1/2 vCPU, 2 GiB (6 bản sao ở `QM-CHUNG`), `pg-iam` 3 instance, 50 GB. Module `iam` thêm khoảng 0,3 vCPU và 400 MiB bộ nhớ vào `dh-platform`. `policy-runner` 2 bản sao, mỗi bản 2 vCPU và 1 GiB khi chạy khô. OPA sidecar 0,25/0,5 vCPU, 0,5 GiB mỗi pod (xem Q12-28 về APISIX ở `QM-CHUNG`).
- **Quyết định**: giả định 300 lượt gọi mỗi giây ở cổng và khoảng 3 quyết định mỗi lượt, tức 900 quyết định mỗi giây ở đỉnh, phân tán trên các pod APISIX và DU. Mục tiêu p99 ≤ 2 ms mỗi lần OPA đánh giá (NFR-12-001) đạt được vì `input` nhỏ và luật có chỉ mục; kiểm bằng `opa bench` với 500 phiên bản chính sách và dữ liệu 10.000 người dùng. Tải thiết kế 10.000 quyết định mỗi giây toàn cụm (NFR-12-003).
- **Cấp token**: Keycloak xử lý khoảng 150 token mỗi giây mỗi vCPU (D03-09), tức khoảng 450 mỗi giây với 3 bản sao, trên yêu cầu NFR-12-006 là 100 yêu cầu mỗi giây. HTTT đệm token nên tải thực thấp: 200 HTTT với token 5 phút khoảng 1 token mỗi giây ở trạng thái ổn định; đột biến chỉ khi nhiều HTTT làm mới cùng lúc sau sự cố, nên thư viện máy khách của PH-15 có độ trễ ngẫu nhiên. Băm mật khẩu `argon2` là chi phí CPU chính của đăng nhập; 200 đăng nhập đồng thời (NFR-12-007) dùng khoảng 20 vCPU-giây phân tán trong cửa sổ vài chục giây.
- **Hiệu lực chính sách và thu hồi**: gói mới tới OPA trong tối đa 5 giây gom thay đổi, cộng 1 giây dựng và ký, cộng chu kỳ tải 30 giây, cộng nạp khoảng 1 giây: tối đa khoảng 40 giây, nằm trong 60 giây của NFR-12-004. Thu hồi: chu kỳ kéo 10 giây cộng xử lý, thường dưới 15 giây, nếu lỡ một lần kéo vẫn dưới 30 giây.
- **Nhật ký quyết định** (giả định): 270 quyết định mỗi giây ở mức trung bình (hệ số tải trung bình trên đỉnh 0,3), trong đó 5% thuộc mức Hạn chế hoặc Nhạy cảm (ghi 100%), 1% từ chối (ghi 100%) và phần còn lại lấy mẫu 10%, tức khoảng 42 bản ghi mỗi giây, 3,6 triệu bản ghi mỗi ngày. Mỗi bản ghi khoảng 700 B thì thô khoảng 2,5 GB mỗi ngày, nén 8:1 ở Loki còn khoảng 0,3 GB mỗi ngày, tức khoảng 110 GB cho 12 tháng mỗi tenant vừa. Ghi 100% mọi quyết định (Q12-12 của FRS) nhân khoảng 6,5 lần, tức khoảng 0,7 TB mỗi năm mỗi tenant.
- **Khởi động**: pod APISIX và DU chỉ báo sẵn sàng khi OPA đã nạp xong mọi gói trong danh sách (`/health?bundles`); không có gói thì pod không nhận lưu lượng, nhất quán với fail-closed. Nạp 34 gói mất khoảng 20 giây.
- **Sổ tay vận hành** (D06-03) gồm: (1) OPA không nạp gói (kiểm chữ ký, khóa công khai, kích thước); (2) quay lui chính sách; (3) thu hồi khẩn và xoay khóa ký khẩn; (4) realm lệch cấu hình, giữ tạm hay áp lại; (5) Keycloak ngừng: JWKS đệm cho phép token hiện có dùng tới 24 giờ, đăng nhập mới dừng; (6) khôi phục `pg-iam` (RPO ≤ 15 phút, RTO ≤ 1 giờ, diễn tập quý, ADR-034); (7) **đường phát hành chính sách khẩn khi `dh-platform` ngừng**: yêu cầu hợp nhất vào `dh-policies` có hai người duyệt, CI `emergency-publish` ký bằng `transit/sign` rồi đặt vào Garage, dùng cùng định dạng gói; (8) quản trị tỉnh cuối cùng mất yếu tố thứ hai: PA đặt lại với SO duyệt (FR-12-024); (9) xoay khóa công khai ký gói hằng năm với hai khóa cùng hiệu lực; (10) cập nhật danh sách mật khẩu lộ mỗi quý.
- **Đồng bộ D03-09**: các thay đổi cần ghi vào D03-09 nêu ở mục "Đề nghị đồng bộ" (tài nguyên `policy-runner` và Job, bộ nhớ sidecar, lấy mẫu nhật ký quyết định).

## 12. Kiểm thử

Kiểm thử PH-12 nhắm vào hai loại sai nguy hiểm nhất: sai nghiêng về phía cho phép và sai im lặng (chính sách, cấu hình lệch mà không ai biết). Bảng dưới liệt kê theo mức.

| Mức | Nội dung | Công cụ |
|---|---|---|
| Đơn vị | Invariant aggregate; `SodGuard` (kiểm tính chất: không dãy gán nào tạo cặp xung đột không ngoại lệ); `UserStateResolver`; `PolicyLinter` (từng quy tắc cấm); `BundleSigner` (JWS hợp lệ với OPA); `RealmSnapshotNormalizer`; `AlertRule` AN-01…09 với đồng hồ giả | JUnit 5, jqwik |
| Chính sách Rego | `opa test` độ phủ ≥ 90% cho gói gốc; bộ ca dương, âm sinh từ ma trận D02-08 (mỗi quyền × mỗi vai trò, kèm ca ○ với tổ chức khác); ca chéo tenant; thử đột biến: lần lượt xóa từng luật `deny` và xác nhận ít nhất một ca thất bại | `opa test`, `opa bench`, kịch bản đột biến |
| Kiến trúc | Luật Modulith; `org.keycloak.*` chỉ trong `internal/keycloak`; cấm log `SecretValue`; cấm gán `state` ngoài aggregate; `@Scheduled` phải bọc `runAs`; cấm `nativeQuery` ngoài danh sách | ArchUnit |
| Tích hợp | Keycloak 26 với mẫu realm áp bằng chính `keycloak-config-cli`; PostgreSQL 16 với RLS; OpenBao dev (transit ký, bọc bí mật); Kafka; OPA nạp gói ký thật; OpenLDAP; Garage | Testcontainers |
| Hợp đồng PEP | Bộ tệp `input` và kết quả mẫu dùng chung cho thư viện Java, plugin Lua của APISIX và Rego để ba nơi dựng cùng một `input` | Fixture chung `contract/authz/*.json` |
| Hợp đồng API, sự kiện | OpenAPI, AsyncAPI (EVT-12-*) | Spectral, oasdiff (CI-5), Apicurio chế độ BACKWARD |
| Hỗn loạn | Tắt OPA: 1.000 yêu cầu hợp lệ, đếm lọt (kỳ vọng 0, NFR-12-014); tắt toàn bộ DU control plane 24 giờ (NFR-12-013); tắt Kafka rồi thu hồi (kỳ vọng ≤ 60 giây); mất Garage; mất một bản sao Keycloak; xóa gói trên đĩa OPA rồi khởi động lại | Chaos Mesh, kịch bản k6 |
| Hiệu năng | 10.000 quyết định mỗi giây 30 phút; token 100 yêu cầu mỗi giây trên 500 client; gói 20 MiB; 500 phiên bản chính sách và 10.000 người dùng | k6, Gatling, JMH cho `DecisionCache` |
| Bảo mật | Canary `DH-CANARY-…` ở log, vết, phản hồi, tệp xuất; 1.000 lần dò mật khẩu từ một địa chỉ (chặn sau ≤ 20 lần); kiểm thời gian phản hồi đồng nhất giữa tài khoản có và không (thống kê 1.000 lần mỗi loại); chéo tenant; SSRF và XXE ở nhập SAML; ASVS 5.0 mức 2; kiểm thử xâm nhập luồng xác thực và ủy quyền | Schemathesis, ZAP, Playwright, D05-02-PH12, D05-04 |
| Kết thúc đầu cuối | Đăng nhập OIDC không có token ở trình duyệt; grant `password` bị từ chối; SSO SAML dùng chung phiên OIDC; thu hồi client có token còn hạn nhận `401` ≤ 60 giây; chính sách đi hết quy trình và quay lui; khởi tạo realm ≤ 5 phút | Playwright, Gatling, tiêu chí chấp nhận FRS mục 14 |

: Kiểm thử

Bộ kiểm thử phân quyền dương, âm của mọi phân hệ khác (D05-01 §7) chạy trên OPA thật nạp gói được sinh từ chính ma trận D02-08, nên PH-12 là phân hệ đầu tiên có chế độ lỗi "ma trận đúng, OPA sai" và "OPA đúng, ma trận lệch" đều bị bắt ở CI.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

Bước 1 và 2 nằm trên đường găng của toàn dự án vì mọi phân hệ khác cần thư viện PEP và OPA để thực thi quyền; nên được giao sớm và chạy song song với PH-03.

| Bước | Nội dung | Phụ thuộc |
|---|---|---|
| 1 | Khung module `iam`, `KeycloakGateway`, mẫu realm và compose dev bằng chính mẫu, thư viện PEP lõi với `FakeOpa`; thay `SecurityConfig` hiện tại (GAP-12-01…03) | ADR-006, D03-10 |
| 2 | Gói chính sách gốc Rego, `PolicyDataGenerator`, `BundleSigner`, OPA sidecar ở APISIX và DU, plugin `dh-authz`, thu hồi và danh sách chặn | OpenBao, Garage, PH-03 |
| 3 | Người dùng: tạo, kích hoạt, vai trò, tách nhiệm vụ, nhóm, nhập, tự vô hiệu; MFA và bước lên (hai SPI) | Bước 1, 2 |
| 4 | Danh tính máy: client, scope, chứng thư, bí mật bọc, tài khoản dịch vụ; `ScopeSourcePort` cho PH-02, 09, 10, 19 | Bước 2, PH-01 |
| 5 | Realm theo tenant: `RealmProvisioner`, GitOps, phát hiện lệch, vòng đời; tích hợp saga PH-20 | Bước 1, PH-20 |
| 6 | Vòng đời chính sách (`policy-runner`, kiểm thử, chạy khô, duyệt, quay lui), quyền có thời hạn, ghi vết, tra cứu, cảnh báo, báo cáo, XACML | Bước 2, 3, PH-13 |
| 7 | Đợt 2: vai trò tùy biến, rà soát quyền, sáp nhập tenant, VNeID, client sandbox | Bước 3…6, PH-15, PH-20 |

: Lộ trình

### 13.2. Rủi ro

Bảng rủi ro xếp theo mức tác động tới an toàn và tính sẵn sàng; mỗi dòng nêu cách giảm thiểu đã có trong thiết kế hoặc câu hỏi mở tương ứng.

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Gói chính sách sai hoặc ký sai làm OPA từ chối mọi yêu cầu (fail-closed lan rộng) | Cao | Kiểm nhất quán trước khi ký, chạy khô trên lưu lượng thật, OPA giữ gói cũ nếu gói mới sai chữ ký, quay lui một lệnh, đường khẩn cấp ở sổ tay |
| Plugin `dh-authz` của PH-03 dựng `input` lệch hợp đồng | Cao | Bộ fixture chung ba nơi (mục 12); đưa vào cổng CI của cả hai phân hệ |
| Chuyển chứng thư mTLS tới Keycloak qua tiêu đề bị giả mạo | Cao | Chỉ tin tiêu đề từ APISIX (SPIFFE), APISIX xóa tiêu đề do client gửi; Q12-22 |
| `dh-platform` ngừng thì không thu hồi được qua giao diện | Trung bình | Thu hồi trực tiếp ở Keycloak theo sổ tay (token ≤ 5 phút); Q12-23 |
| Sidecar OPA thiếu bộ nhớ khi nạp nhiều gói ở `QM-CHUNG` | Trung bình | Đo sớm bằng bộ thử NFR-12-024; Q12-28 |
| Nâng cấp Keycloak làm hỏng SPI hoặc Admin API | Trung bình | Mọi lời gọi qua `KeycloakGateway`; ảnh tùy biến kiểm thử trên từng bản vá; Q12-21 |
| Gói gốc đổi làm luật riêng của một tỉnh hỏng | Trung bình | Bộ kiểm thử gộp cho mọi tenant có luật riêng chạy trước khi ký |
| Tỉnh chỉ có một cán bộ ATTT nên không bốn mắt được | Trung bình | SO của tenant `PLATFORM` duyệt qua quyền có thời hạn (Q12-14 của FRS) |
| Khối lượng nhật ký quyết định lớn hơn giả định | Trung bình | Lấy mẫu mức thấp theo tham số; không bao giờ lấy mẫu từ chối hoặc mức Hạn chế, Nhạy cảm; Q12-12 của FRS |
| Thời gian phản hồi đăng nhập vẫn lộ tài khoản tồn tại qua kênh phụ | Thấp | Băm giả, kiểm thử thống kê ở CI, ngưỡng chấp nhận do ATTT đặt |
| Quản trị mất khóa FIDO2 | Thấp | Đặt lại yếu tố bởi cấp trên với SO duyệt; hai khóa cho mỗi quản trị (Q12-09 của FRS) |

: Rủi ro

### 13.3. Câu hỏi mở

> **Câu hỏi mở Q12-20:** Gói dữ liệu tenant dùng chế độ đẩy (bundle 30 giây) và ước khoảng 1,6 MiB cho tỉnh vừa. Cần xác định ngưỡng chuyển sang chế độ kéo theo `iam:policy-data-read` hoặc chia dữ liệu `assignments` theo đơn vị (ví dụ khi tenant vượt 10.000 người dùng hoặc gói gần 20 MiB), và ai quyết định đặt ngưỡng.

> **Câu hỏi mở Q12-21:** Bộ mở rộng Keycloak có hai điểm (bộ lắng nghe sự kiện gửi Kafka, bộ xác thực phản hồi đồng nhất) buộc phải duy trì ảnh `dh-keycloak` tùy biến, ký và quét như ảnh runtime, và theo kịp bản vá 26.x. Phương án thay thế là bỏ bộ lắng nghe (dùng nhật ký JSON của Keycloak qua Fluent Bit) và chấp nhận chênh thời gian phản hồi nhỏ. Cần kiến trúc sư ATTT và hạ tầng chọn; chọn xong nên ghi thành một ADR.

> **Câu hỏi mở Q12-22:** Để dùng mTLS (RFC 8705) với Keycloak, APISIX phải kết thúc mTLS rồi chuyển chứng thư tới Keycloak bằng tiêu đề (nhà cung cấp tra cứu `x509cert-lookup`). Cần PH-03 và ATTT xác nhận mô hình tin cậy (Keycloak chỉ nhận tiêu đề từ APISIX qua mesh) hoặc chọn phương án thay thế là cổng mTLS riêng của Keycloak ở Z6 với bộ cân bằng tải TCP trong suốt.

> **Câu hỏi mở Q12-23:** Danh sách chặn được kéo từ API của `dh-platform`; khi `dh-platform` ngừng thì giao diện thu hồi không dùng được và chỉ còn thu hồi trực tiếp ở Keycloak (token cũ còn tối đa 5 phút). Cần xác nhận chấp nhận khoảng hở này hay đặt nguồn danh sách chặn ở data plane (ví dụ một bản chỉ-đọc cạnh Keycloak trong `pg-iam`).

> **Câu hỏi mở Q12-24:** Khóa công khai ký gói chính sách đặt trong cấu hình OPA, phân phối bằng GitOps; xoay 12 tháng cần hai khóa cùng hiệu lực trong chuyển tiếp. Cần xác nhận quy trình xoay (ai duyệt, thời gian song song, cách xử lý nút OPA chưa nhận cấu hình mới) và việc tự ghép JWS từ chữ ký transit thay cho `opa build --signing-key`.

> **Câu hỏi mở Q12-25:** Thời điểm đăng nhập cuối lấy từ luồng EVT-12-16 và có thể mất khi bộ đệm đĩa của bộ lắng nghe đầy. Cần xác nhận bật lưu sự kiện ở `pg-iam` với hạn 7 ngày làm nguồn dự phòng cho đối soát (tăng dung lượng `pg-iam`), hay chấp nhận tác vụ bỏ lượt như thiết kế hiện tại.

> **Câu hỏi mở Q12-26:** `dh-runtime` dùng Quarkus (ADR-002) nên cần lớp vỏ Quarkus của thư viện PEP. Cần xác định đội nào bảo trì và kiểm thử lớp vỏ này, hay `dh-runtime` gọi API `decide` (độ trễ cao hơn OPA cục bộ, NFR-12-002) trong giai đoạn đầu.

> **Câu hỏi mở Q12-27:** Hạn mức người dùng mặc định của tenant ở D03-10 §5.3 là 2.000, trong khi NFR-12-023 thiết kế cho 10.000 người dùng mỗi tenant và giả định tỉnh vừa có khoảng 3.000 cán bộ. Cần xác nhận 2.000 là hạn mức thương mại mặc định (PH-20 điều chỉnh theo hợp đồng) còn 10.000 là năng lực hạ tầng, hay phải nâng mặc định.

> **Câu hỏi mở Q12-28:** Sidecar OPA ở APISIX nạp gói của mọi tenant nên ở `QM-CHUNG` (34 tenant) cần khoảng 450 MiB theo ước lượng, sát mức 0,5 GiB của D03-01. Cần đo bằng bộ thử của NFR-12-024 và quyết định nâng lên 1 GiB hay chia APISIX theo nhóm tenant.

> **Câu hỏi mở Q12-29:** Job `keycloak-config-cli` hiện do `dh-platform` tạo bằng quyền Kubernetes tối thiểu trong `dh-iam` để đạt NFR-12-010 (≤ 5 phút). Phương án thay thế là Argo CD chạy Job từ Git (không cấp quyền tạo Job cho `dh-platform`) nhưng chậm hơn theo chu kỳ đồng bộ. Cần ATTT và hạ tầng chọn.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây ở tài liệu dùng chung hoặc phân hệ khác do luồng khác chịu trách nhiệm; tập này chỉ ghi lại để đợt đồng bộ cuối xử lý.

| Tài liệu | Đề nghị |
|---|---|
| D03-01 SAD §4 (`opa`, `keycloak`, `dh-platform`) | `opa`: sửa "lấy mẫu 1% quyết định cho phép" thành "100% từ chối và mức Hạn chế, Nhạy cảm, 10% mức Công khai, Nội bộ" theo FR-12-057; bộ nhớ sidecar theo Q12-28. `keycloak`: ghi ảnh tùy biến `dh-keycloak` có `dh-keycloak-spi` và Job `dh-iam-provisioner`. `dh-platform`: ghi `policy-runner` là vai trò `runner` không có thông tin xác thực CSDL |
| D03-09 §4.2, §5.3, §6.6 | Thêm `policy-runner` và Job `dh-iam-provisioner` vào danh mục tài nguyên; §6.6 sửa lấy mẫu nhật ký quyết định từ 1% thành theo FR-12-057; §5.3 ghi sidecar OPA của APISIX 1 GiB ở `QM-CHUNG` nếu Q12-28 xác nhận; ghi lưu sự kiện `pg-iam` 7 ngày nếu Q12-25 chọn |
| D03-07 SEC-25, SEC-26, SEC-36 | SEC-25: thêm cờ `blockAll` cho mục thu hồi khi Keycloak chưa xác nhận; SEC-26: lấy mẫu như trên; SEC-36: ghi bundle OPA ký bằng JWS ghép từ chữ ký transit |
| D03-03-PH12 (CSDL) | Các bảng suy ra từ thiết kế: `user_account`, `user_import`, `user_import_row`, `role_assignment`, `sod_exception`, `org_group`, `org_group_member`, `custom_role`, `custom_role_permission`, `privileged_grant`, `recert_campaign`, `recert_item`, `federation`, `saml_client`, `vneid_link`, `client`, `client_scope`, `client_credential`, `service_account`, `revocation_entry` (có `block_all`), `revocation_feed_version`, `node_heartbeat`, `realm_state`, `realm_provision_step`, `tenant_merge_step`, `policy`, `policy_version`, `policy_version_contributor`, `policy_test_case`, `policy_test_run`, `policy_dryrun_report`, `bundle_release`, `bundle_ack`, `alert`, `alert_ack`, `account_report_daily`, `mfa_coverage_daily`, `sync_task`, `idempotency_key`, `outbox` |
| D03-04-PH12 (API) | Ghi điểm cuối nội bộ nhận trạng thái OPA (plugin `status`) ngoài danh mục API-12-*; ghi `revocations` có `blockAll` và tiêu đề `X-DH-Applied-Version`; ghi `decide:batch` tối đa 100 phần tử; ghi tiêu đề `X-DH-Grant-Id` tùy chọn của `/api/platform/` |
| D02-03-PH12 (FRS) | FR-12-041 bước 4: ghi thêm client `dh-client-provisioner` (`manage-clients` giới hạn theo thuộc tính `dh_managed`) dùng cho cấp client HTTT, còn `dh-platform-iam` vẫn chỉ có `realm-user-admin`; FR-12-044: `subject.grantId` chỉ để ghi vết (OPA tra theo dữ liệu); FR-12-040: danh sách chặn có cờ `blockAll` tới khi Keycloak xác nhận; FR-12-057: nêu `AuditGate` kiểm trạng thái plugin `decision_logs` của OPA |
| PH-03 | Hiện thực plugin `dh-authz` theo bảng ánh xạ mục 3.4 và bộ fixture chung; kéo `GET /revocations` mỗi 10 giây kèm `X-DH-Applied-Version`; xử lý `blockAll`; mô hình mTLS với Keycloak (Q12-22) |
| PH-01, PH-15 | Cung cấp API nhận `wrappingToken` do PH-12 đẩy khi cấp mới hoặc xoay bí mật (mục 5.10); mở bí mật bọc (`sys/wrapping/unwrap`) ở BFF của mình, hiển thị một lần, không lưu `wrappingToken`; PH-15 thêm độ trễ ngẫu nhiên khi làm mới token |
| PH-13 | Nhận bản ghi kiểm toán quyết định từ chối và mức Nhạy cảm, bản ghi thay đổi quyền vào chuỗi băm theo tenant bị truy cập; xác định hợp đồng tiếp nhận |
| PH-20 | Bước 2 của saga gọi API-12-080 và chờ tối đa 4 phút; hạn mức `maxUsers` (Q12-27); gọi API-12-084, 085 khi đổi trạng thái tenant |
| D00-04 §2, §3.2 | PH-12 "đủ tập sdd 0.1"; chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` |
| ADR đề xuất (chưa tạo, dải 014–019 còn trống) | Ngoài bốn ADR (a)…(d) đã nêu ở FRS: (e) bộ mở rộng Keycloak tối thiểu và ảnh tùy biến (Q12-21); (f) ký gói OPA bằng khóa transit và tự ghép JWS (Q12-24); (g) chạy Rego do người dùng soạn trong `policy-runner` cô lập, loại hàm mạng khỏi `capabilities` (mục 4.13) |

: Đề nghị đồng bộ cho tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-SDD và K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu; vị trí trong kiến trúc và hiện trạng mã; cấu trúc mã (module `iam`, thư viện PEP, bộ mở rộng Keycloak, kho `dh-policies`) và hợp đồng quyết định; mô hình miền và 14 thành phần với bảng đặc tả 10 mục; 14 biểu đồ tuần tự; đa tenant; bảo mật dẫn SEC và THR; bảng chuyển trạng thái 10 đối tượng; chịu lỗi và nhất quán; cấu hình và cờ; quan sát; hiệu năng và vận hành; kiểm thử; lộ trình, rủi ro; 10 câu hỏi mở (Q12-20…Q12-29); đề nghị đồng bộ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: giao diện PermissionApi, StepUpApi, đường đẩy API-03-053, đối chiếu CSDL, bước S03_REALM; chốt câu hỏi mở đợt đồng bộ: Q413, Q445, Q446 |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Theo Q403: bất biến tối thiểu hai TA (ERR-12-046) cho gỡ, khóa, vô hiệu, hết hạn gán TA; ngoại lệ InactivityJob và khóa do sự cố ATTT qua `ph12.ta_floor_exception`, cảnh báo khẩn và việc bổ sung TA |
