# LGSP Platform — Wiki Index

> **Điểm vào duy nhất của dự án.** Đọc file này trước; chỉ mở tài liệu chi tiết khi thực sự cần.
> Mục đích: giảm token bằng cách tra cứu có định hướng thay vì quét toàn bộ tài liệu.

## 1. Định vị dự án

Xây dựng **LGSP** (Local Government Service Platform) — nền tảng tích hợp, chia sẻ dữ liệu cấp bộ/tỉnh, đóng vai trò trục tích hợp **nội bộ**, tuân thủ quy định Việt Nam, lõi **Apache Camel**, toàn bộ stack open-source, chạy trên Kubernetes.

## 2. Bản đồ tài liệu

| # | Tài liệu | Nội dung | Khi nào đọc |
|---|---|---|---|
| 01 | [Cơ sở pháp lý & tuân thủ](../docs/01-legal/README.md) | NĐ 47/2020, CV 631, QĐ 2568/1729, Luật Dữ liệu 2024; ma trận truy vết yêu cầu | Khi cần chứng minh tuân thủ hoặc tra điều khoản |
| 02 | [Thiết kế kiến trúc](../docs/02-architecture/README.md) | Kiến trúc tổng thể, phân rã thành phần, dữ liệu, bảo mật, hạ tầng | Tài liệu chính — thiết kế hệ thống |
| 03 | [Luồng nghiệp vụ](../docs/03-flows/README.md) | Các luồng chính kèm sequence diagram + thuyết minh | Khi triển khai/kiểm thử một luồng cụ thể |
| 04 | [Kế hoạch triển khai](../docs/04-deployment/README.md) | Các bước tiến hành (không phải timeline) | Khi thực thi dự án |
| 05 | [ADR](../docs/05-adr/README.md) | Quyết định kiến trúc & lý do chọn công nghệ | Khi cần biết "vì sao chọn X" |
| 06 | [Tác động TTQGS & nâng cấp](../docs/06-impact/README.md) | Phân tích Khung Kiến trúc tổng thể quốc gia số → 6 năng lực bổ sung, 13 bước nâng cấp | Khi rà soát tuân thủ khung mới |
| 07 | [Danh mục phân hệ & SRS](../docs/07-srs/README.md) · [**CHECKLIST**](../docs/07-srs/CHECKLIST.md) · [**SRS-00 Từ điển dữ liệu**](../docs/07-srs/SRS-00-data-dictionary.md) · [**SRS-19 Ma trận RBAC**](../docs/07-srs/SRS-19-rbac-matrix.md) · [Rà soát GĐ7](../docs/07-srs/REVIEW-GIAI-DOAN-7.md) | 18 phân hệ runtime + SRS-00 (thực thể chia sẻ `DD-01…12`, kiểu chuẩn, quy ước đặt tên) + SRS-19 (ma trận Role×Permission×PH) | **Trước khi định nghĩa bất kỳ thực thể/trường nào → SRS-00**; phân quyền → SRS-19; tiến độ → CHECKLIST |
| 08 | [**Triển khai lập trình**](../docs/08-implementation/README.md) · [**IP-04 Kế hoạch**](../docs/08-implementation/04-ke-hoach-phat-trien.md) · [IP-03 Stack](../docs/08-implementation/03-stack-cong-nghe.md) · [IP-01](../docs/08-implementation/01-mo-hinh-phat-trien.md) · [IP-02](../docs/08-implementation/02-huong-dan-lap-trinh.md) | Kế hoạch W0–W6 đa agent · stack · DU | **IP-04 khi giao agent** · IP-03 khi chọn lib |

## 3. Tra cứu nhanh — Quyết định cốt lõi

| Hạng mục | Lựa chọn | ADR |
|---|---|---|
| Integration engine | Apache Camel (Camel Quarkus) | ADR-001 |
| Trình thiết kế luồng | Kaoto làm mẫu catalog/YAML; canvas XYFlow trong console PH-04 | ADR-015, ADR-017 |
| Runtime Camel (PH-04) | Camel Quarkus native trên K8s | ADR-002 |
| Runtime DU ứng dụng | Spring Boot 4 + Spring Modulith | ADR-019 |
| API Gateway | Apache APISIX | ADR-003 |
| IAM / SSO | Keycloak (OIDC, SAML2, OAuth2) + OPA; ma trận quyền toàn hệ thống | ADR-004 · [SRS-19](../docs/07-srs/SRS-19-rbac-matrix.md) |
| Messaging | Apache Kafka (Strimzi) | ADR-005 |
| API Portal / Catalog | Backstage + OpenAPI registry | ADR-006 |
| Observability | OpenTelemetry + Prometheus + Loki + Tempo + Grafana | ADR-007 |
| Data store | PostgreSQL (CloudNativePG) + MinIO | ADR-008 |
| Workflow/BPM | Camunda 8 hoặc Flowable (BPMN 2.0) | ADR-009 |
| GitOps | Argo CD + Kustomize | ADR-010 |
| Service mesh | Istio (mTLS nội bộ) | ADR-011 |
| Secrets | HashiCorp Vault + External Secrets | ADR-012 |
| Bộ thành phần giao diện | Ant Design v6, tinh chỉnh token theo phong cách shadcn, có chế độ sáng/tối | ADR-016 |
| Mô hình phát triển mã | Hybrid DU production-first (tách biên cứng ngay); Boot 4 + Modulith; Camel Quarkus | ADR-018 · ADR-019 · [08-implementation](../docs/08-implementation/README.md) |

## 4. Thuật ngữ

| Viết tắt | Nghĩa |
|---|---|
| LGSP | Nền tảng tích hợp, chia sẻ dữ liệu cấp bộ/tỉnh (trục nội bộ) |
| NDXP/NGSP | Nền tảng tích hợp chia sẻ dữ liệu quốc gia (trục quốc gia) |
| CSDLQG | Cơ sở dữ liệu quốc gia |
| HTTT | Hệ thống thông tin |
| CQNN | Cơ quan nhà nước |
| EIP | Enterprise Integration Patterns |
| DVCTT | Dịch vụ công trực tuyến |

## 5. Quy ước làm việc (token-efficient)

1. **Index-first**: mọi phiên làm việc bắt đầu từ file này.
2. **Mỗi tài liệu một trách nhiệm**: không lặp nội dung giữa các file; liên kết chéo thay vì copy.
3. **ADR là nguồn sự thật** cho mọi lựa chọn công nghệ — tài liệu khác chỉ tham chiếu mã ADR.
4. **Ma trận truy vết** trong `01-legal` là nơi duy nhất ánh xạ điều khoản pháp lý → thành phần kiến trúc.
5. Sơ đồ dùng **Mermaid** (text-based, diff được trong git, không cần binary).
