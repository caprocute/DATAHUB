---
ma_tai_lieu: D00-02
ten: Sổ quyết định kiến trúc (ADR)
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư, Đội kỹ thuật, Hội đồng thẩm định
---

# D00-02 · Sổ quyết định kiến trúc (ADR)

## 1. Mục đích

Sổ ADR ghi lại mọi quyết định kiến trúc có ảnh hưởng lâu dài: chọn công nghệ, chọn mô hình dữ liệu, chọn cách cách ly, chọn cách triển khai. Mỗi quyết định nêu bối cảnh, các phương án đã cân nhắc, lý do chọn và hệ quả, để hội đồng thẩm định đánh giá được tính hợp lý của lựa chọn và để đội kỹ thuật về sau không phải tranh luận lại. Mỗi ADR nằm trong một file riêng ở thư mục `adr/`, theo khung MADR rút gọn (D00-01 §9.2).

## 2. Quan hệ với ADR trong `docs/05-adr` của repo

Repo DATAHUB đã có 22 ADR trong `docs/05-adr`. Bộ tài liệu này độc lập (quyết định Q11) nên đánh số lại, nhưng mỗi ADR ở đây ghi rõ ADR tương ứng của repo trong mục Truy vết. Những điểm khác biệt có chủ đích so với repo: ADR-003 bổ sung mô hình đa tenant; ADR-020 (luồng giao diện) thay ADR-016 của repo, đổi phong cách shadcn sang Liquid Glass; Backstage (ADR-006 của repo) chưa được chọn làm cổng nhà phát triển, sẽ quyết định ở dải 050–059 khi viết PH-15.

## 3. Dải số

| Dải | Chủ đề | Nhóm phụ trách |
|---|---|---|
| ADR-001 … 019 | Kiến trúc nền, stack, dữ liệu, tích hợp, đa tenant | Luồng lõi |
| ADR-020 … 029 | Giao diện, design system | Luồng giao diện |
| ADR-030 … 039 | ATTT, hạ tầng, DR, kiểm thử | Luồng ATTT và hạ tầng |
| ADR-040 … 049 | Thanh toán | Luồng PH-19 |
| ADR-050 … 059 | Danh mục dùng chung và các phân hệ khác | Luồng PH-07 và các phân hệ |

## 4. Danh sách ADR

Bảng dưới đây liệt kê các ADR đã ghi. Trạng thái `Đề xuất` nghĩa là chờ duyệt ở cổng G1; `Chấp nhận` sau khi được duyệt; ADR bị thay thế giữ nguyên file và ghi `Thay thế bởi ADR-xxx`. Các ADR của luồng khác được bổ sung vào bảng khi PR của luồng đó được gộp.

| Mã | Quyết định | Trạng thái | Nhóm |
|---|---|---|---|
| [ADR-001](adr/ADR-001-spring-boot-modulith.md) | Spring Boot 4 và Spring Modulith làm nền backend chung | Đề xuất | Lõi |
| [ADR-002](adr/ADR-002-camel-quarkus-data-plane.md) | Camel Quarkus native cho lõi tích hợp, bộ điều hợp và kết nối quốc gia | Đề xuất | Lõi |
| [ADR-003](adr/ADR-003-postgresql-rls-da-tenant.md) | PostgreSQL với Row-Level Security làm cơ chế cách ly tenant mặc định | Đề xuất | Lõi |
| [ADR-004](adr/ADR-004-kafka-thay-pulsar.md) | Kafka và Apicurio Registry thay Apache Pulsar cho trao đổi sự kiện | Đề xuất | Lõi |
| [ADR-005](adr/ADR-005-apisix-gateway.md) | Apache APISIX làm cổng API | Đề xuất | Lõi |
| [ADR-006](adr/ADR-006-keycloak-opa.md) | Keycloak cho định danh và OPA cho ủy quyền | Đề xuất | Lõi |
| [ADR-007](adr/ADR-007-flowable-bpm.md) | Flowable cho quy trình nghiệp vụ và luồng duyệt | Đề xuất | Lõi |
| [ADR-008](adr/ADR-008-garage-luu-tru-doi-tuong.md) | Garage làm kho lưu trữ đối tượng tương thích S3 | Đề xuất | Lõi |
| [ADR-009](adr/ADR-009-gitops-argo-cd.md) | GitOps với Argo CD cho triển khai ứng dụng và luồng tích hợp | Đề xuất | Lõi |
| [ADR-010](adr/ADR-010-camel-yaml-dsl.md) | Camel YAML DSL thay Camel XML làm định dạng luồng tích hợp | Đề xuất | Lõi |
| [ADR-011](adr/ADR-011-opentelemetry-lgtm.md) | OpenTelemetry và bộ LGTM cho giám sát xuyên suốt | Đề xuất | Lõi |
| [ADR-012](adr/ADR-012-openbao-bi-mat.md) | OpenBao (hoặc Vault) làm kho bí mật, cấm bí mật trong mã và tài liệu | Đề xuất | Lõi |
| [ADR-013](adr/ADR-013-tach-control-data-plane.md) | Tách control plane và data plane | Đề xuất | Lõi |
| ADR-020 | Liquid Glass trên antd v6 (thay ADR-016 của repo) | Đang viết | Giao diện |
| ADR-021 | Font chữ giao diện | Đang viết | Giao diện |
