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
| ADR-060 … 069 | Lõi tích hợp, trình thiết kế luồng, bộ điều hợp (PH-04, PH-05) | Luồng PH-04 |

## 4. Danh sách ADR

Bảng dưới đây liệt kê các ADR đã ghi. Trạng thái `Đề xuất` nghĩa là chờ duyệt ở cổng G1; `Chấp nhận` sau khi được duyệt; ADR bị thay thế giữ nguyên file và ghi `Thay thế bởi ADR-xxx`. Các ADR của luồng khác được bổ sung vào bảng khi PR của luồng đó được gộp.

| Mã | Quyết định | Trạng thái | Nhóm |
|---|---|---|---|
| [ADR-001](adr/ADR-001-spring-boot-modulith.md) | Spring Boot 4 và Spring Modulith làm nền backend chung | Đề xuất | Lõi |
| [ADR-002](adr/ADR-002-camel-quarkus-data-plane.md) | Camel Quarkus native cho lõi tích hợp, bộ điều hợp và kết nối quốc gia | Đề xuất | Lõi |
| [ADR-003](adr/ADR-003-postgresql-rls-da-tenant.md) | PostgreSQL với Row-Level Security làm cơ chế cách ly tenant mặc định | Đề xuất | Lõi |
| [ADR-004](adr/ADR-004-kafka-thay-pulsar.md) | Kafka và Apicurio Registry thay Apache Pulsar cho trao đổi sự kiện | Chấp nhận (25/11/2026) | Lõi |
| [ADR-005](adr/ADR-005-apisix-gateway.md) | Apache APISIX làm cổng API | Chấp nhận (25/11/2026) | Lõi |
| [ADR-006](adr/ADR-006-keycloak-opa.md) | Keycloak cho định danh và OPA cho ủy quyền | Đề xuất | Lõi |
| [ADR-007](adr/ADR-007-flowable-bpm.md) | Flowable cho quy trình nghiệp vụ và luồng duyệt | Đề xuất | Lõi |
| [ADR-008](adr/ADR-008-garage-luu-tru-doi-tuong.md) | Garage làm kho lưu trữ đối tượng tương thích S3; Ceph RGW cho WORM | Đề xuất (phần WORM đã chốt 25/11/2026) | Lõi |
| [ADR-009](adr/ADR-009-gitops-argo-cd.md) | GitOps với Argo CD cho triển khai ứng dụng và luồng tích hợp | Đề xuất | Lõi |
| [ADR-010](adr/ADR-010-camel-yaml-dsl.md) | Camel YAML DSL thay Camel XML làm định dạng luồng tích hợp | Đề xuất | Lõi |
| [ADR-011](adr/ADR-011-opentelemetry-lgtm.md) | OpenTelemetry và bộ LGTM cho giám sát xuyên suốt | Đề xuất | Lõi |
| [ADR-012](adr/ADR-012-openbao-bi-mat.md) | OpenBao (hoặc Vault) làm kho bí mật, cấm bí mật trong mã và tài liệu | Đề xuất | Lõi |
| [ADR-013](adr/ADR-013-tach-control-data-plane.md) | Tách control plane và data plane | Đề xuất | Lõi |
| [ADR-020](adr/ADR-020-liquid-glass-tren-antd-v6.md) | Phong cách Liquid Glass trên Ant Design v6 làm ngôn ngữ thị giác của giao diện (thay ADR-016 của repo) | Đề xuất | Giao diện |
| [ADR-021](adr/ADR-021-font-chu-giao-dien.md) | Inter và JetBrains Mono làm phông chữ giao diện, tự lưu trữ | Đề xuất | Giao diện |
| [ADR-022](adr/ADR-022-bieu-tuong-lucide.md) | Lucide làm bộ biểu tượng ứng dụng | Đề xuất | Giao diện |
| [ADR-023](adr/ADR-023-bieu-do-echarts.md) | Apache ECharts làm thư viện biểu đồ | Đề xuất | Giao diện |
| [ADR-030](adr/ADR-030-attt-cap-do-3-san-sang-cap-do-4.md) | Thiết kế ATTT theo cấp độ 3, chừa điểm nâng cấp cấp độ 4 | Chấp nhận (25/11/2026) | ATTT và hạ tầng |
| [ADR-031](adr/ADR-031-nhat-ky-kiem-toan-chuoi-bam-worm.md) | Nhật ký kiểm toán chỉ-thêm, chuỗi băm, WORM; online 12 tháng, WORM 5 năm | Đề xuất | ATTT và hạ tầng |
| [ADR-032](adr/ADR-032-ma-hoa-truong-nhay-cam-envelope-openbao.md) | Mã hóa trường Nhạy cảm bằng envelope encryption qua OpenBao transit | Đề xuất | ATTT và hạ tầng |
| [ADR-033](adr/ADR-033-lop-bien-apisix-coraza.md) | Lớp biên do APISIX đảm nhận, WAF Coraza trong APISIX (bản 0.1 chọn Envoy Gateway đã bị thay) | Chấp nhận (25/11/2026) | ATTT và hạ tầng |
| [ADR-034](adr/ADR-034-dr-hai-site-active-standby.md) | DR hai site active–standby | Đề xuất | ATTT và hạ tầng |
| [ADR-035](adr/ADR-035-sao-luu-bat-bien-cnpg-velero.md) | Sao lưu CNPG (Barman Cloud) và Velero ra kho S3 bất biến ngoài site | Đề xuất | ATTT và hạ tầng |
| [ADR-036](adr/ADR-036-hai-ho-so-trien-khai-air-gapped.md) | Hai hồ sơ triển khai HT-A/HT-B và gói phân phối air-gapped | Đề xuất | ATTT và hạ tầng |
| [ADR-037](adr/ADR-037-quy-trinh-git-trunk-based-cong-chat-luong.md) | Trunk-based, Conventional Commits, review bắt buộc, cổng CI-1…9; GitHub khi phát triển, GitLab on-prem khi bàn giao | Đề xuất | ATTT và hạ tầng |
| [ADR-038](adr/ADR-038-chien-luoc-kiem-thu.md) | Chiến lược kiểm thử, gồm kiểm thử rò rỉ chéo tenant | Đề xuất | ATTT và hạ tầng |
| [ADR-040](adr/ADR-040-adapter-chong-nhiem-nha-cung-cap.md) | Cổng nhà cung cấp và adapter chống nhiễm cho PayGov | Đề xuất | PH-19 |
| [ADR-041](adr/ADR-041-idempotency-va-chong-trung.md) | Idempotency hai tầng và bảng chống trùng mã đơn hàng | Đề xuất | PH-19 |
| [ADR-042](adr/ADR-042-inbox-outbox-trong-du.md) | Hộp nhận, hộp gửi trong DU thanh toán; webhook không phụ thuộc Kafka | Đề xuất | PH-19 |
| [ADR-043](adr/ADR-043-mo-hinh-trang-thai-giao-dich.md) | Máy trạng thái giao dịch nội bộ, ánh xạ trạng thái NCC qua bảng | Đề xuất | PH-19 |
| [ADR-044](adr/ADR-044-ky-webhook-hmac.md) | Ký webhook HMAC-SHA256 kiểu t=,v1= và xoay bí mật có chuyển tiếp | Đề xuất | PH-19 |
| [ADR-045](adr/ADR-045-xac-dinh-tenant-callback.md) | Xác định tenant của callback bằng connectionKey trong đường dẫn | Đề xuất | PH-19 |
| [ADR-046](adr/ADR-046-phe-duyet-bon-mat.md) | Đề nghị phê duyệt bốn mắt dùng chung cho mọi thao tác ảnh hưởng tới tiền | Đề xuất | PH-19 |
| [ADR-047](adr/ADR-047-luu-tru-phan-vung.md) | Phân vùng theo tháng và lưu trữ dài hạn dữ liệu thanh toán | Đề xuất | PH-19 |
| [ADR-048](adr/ADR-048-ma-hoa-dlcn-nguoi-nop.md) | Mã hóa dữ liệu cá nhân người nộp và tìm kiếm bằng băm HMAC | Đề xuất | PH-19 |
| [ADR-049](adr/ADR-049-strangler-theo-doi-tac.md) | Chuyển đổi strangler theo từng đối tác | Đề xuất | PH-19 |
| [ADR-050](adr/ADR-050-jsonb-thuoc-tinh-dong.md) | Thuộc tính động của danh mục lưu bằng jsonb và kiểm tra bằng JSON Schema thay cho EAV | Đề xuất | PH-07 |
| [ADR-051](adr/ADR-051-phien-ban-anh-chup.md) | Phiên bản danh mục là ảnh chụp copy-on-write bất biến, hiệu lực theo khoảng ngày | Đề xuất | PH-07 |
| [ADR-052](adr/ADR-052-danh-muc-common-va-hybrid.md) | Danh mục toàn quốc lưu ở tenant COMMON, tenant tỉnh mở rộng bằng danh mục HYBRID dạng phủ lớp | Đề xuất | PH-07 |
| [ADR-053](adr/ADR-053-phan-phoi-bo-dem-hai-tang-anh-chup.md) | Phân phối danh mục bằng bộ đệm hai tầng Caffeine và Valkey, kèm ảnh chụp trên Garage cho data plane | Đề xuất | PH-07 |
| [ADR-054](adr/ADR-054-dsl-truy-van-co-cau-truc.md) | Truy vấn có cấu trúc trên danh mục bằng DSL lọc dạng JSON dịch sang SQL tham số hóa | Đề xuất | PH-07 |
| [ADR-055](adr/ADR-055-mo-hinh-dvhc-lich-su-ke-thua.md) | Mô hình đơn vị hành chính theo phiên bản, quan hệ kế thừa nhiều-nhiều và bảng chiếu admin_unit | Đề xuất | PH-07 |
| [ADR-056](adr/ADR-056-nhap-tep-hai-pha.md) | Nhập tệp danh mục bằng tác vụ nền hai pha, đọc luồng và quét mã độc trước khi phân tích | Đề xuất | PH-07 |
| [ADR-057](adr/ADR-057-dong-bo-quoc-gia-qua-ph14.md) | Đồng bộ danh mục quốc gia qua adapter PH-14, đối chiếu khác biệt và tự áp dụng có điều kiện | Đề xuất | PH-07 |
| [ADR-058](adr/ADR-058-may-trang-thai-duyet-noi-bo.md) | Luồng duyệt phiên bản danh mục dùng máy trạng thái nội bộ thay cho Flowable | Đề xuất | PH-07 |
| [ADR-059](adr/ADR-059-cdc-debezium-tren-kafka-connect.md) | CDC cho HTTT di sản bằng Debezium trên Kafka Connect (Strimzi), connector quản lý qua GitOps | Đề xuất | PH-05 |
| [ADR-060](adr/ADR-060-trinh-thiet-ke-tu-lam-mo-hinh-kaoto.md) | Trình thiết kế tự làm lại mô hình Kaoto bằng React 19 và XYFlow, dùng catalog Kaoto vendor | Đề xuất | PH-04 |
| [ADR-061](adr/ADR-061-catalog-khop-phien-ban-runtime.md) | Catalog trình thiết kế khớp đúng phiên bản runtime, CI chặn khi lệch | Chấp nhận (25/11/2026) | PH-04 |
| [ADR-062](adr/ADR-062-luong-nghiep-vu-yaml-dsl-java-cho-thu-vien-nen.md) | Luồng nghiệp vụ bằng YAML DSL; Java chỉ cho thư viện nền | Đề xuất | PH-04 |
| [ADR-063](adr/ADR-063-anh-runtime-theo-ho-so-nap-yaml-luc-chay.md) | Ảnh `dh-runtime` theo hồ sơ thành phần, nạp YAML lúc chạy qua Argo CD | Đề xuất | PH-04 |
| [ADR-064](adr/ADR-064-sandbox-chay-thu-camel-that.md) | Sandbox chạy thử Camel thật, đích mô phỏng | Đề xuất | PH-04 |
| [ADR-065](adr/ADR-065-dieu-khien-runtime-git-va-lenh-co-ky.md) | Điều khiển runtime bằng Git kèm lệnh có ký qua Kafka | Đề xuất | PH-04 |
| [ADR-066](adr/ADR-066-datamapper-sinh-jq.md) | Trình ánh xạ dữ liệu sinh JQ | Đề xuất | PH-04 |
| [ADR-067](adr/ADR-067-truy-cap-csdl-truc-tiep-co-kiem-soat.md) | Truy cập CSDL trực tiếp có kiểm soát (Q359) | Chấp nhận (25/11/2026) | PH-04, PH-05 |
| [ADR-068](adr/ADR-068-kho-cau-hinh-git-theo-tenant.md) | Kho cấu hình luồng theo tenant, nhánh theo môi trường | Đề xuất | PH-04 |
| [ADR-069](adr/ADR-069-may-trang-thai-phien-ban-va-bon-mat.md) | Máy trạng thái phiên bản luồng, bốn mắt chốt ở máy chủ | Đề xuất | PH-04 |

## 5. Nhật ký quyết định của chủ đầu tư

| Ngày | Nội dung | Ảnh hưởng |
|---|---|---|
| 21/11/2026 | Q1–Q13 về định vị, đa tenant, phạm vi, giao diện, pháp lý (ghi ở README và D00-03) | Toàn bộ bộ tài liệu |
| 25/11/2026 | Chấp nhận ADR-004 (Kafka thay Pulsar), ADR-005 (APISIX, chế độ standalone), ADR-030 (cấp độ 3 sẵn sàng cấp độ 4) | D03-07, D03-09 |
| 25/11/2026 | Giữ APISIX ở biên, không thêm Envoy Gateway (ADR-033 bản 0.2) | D03-07, D03-08, D03-09, SAD §6 |
| 25/11/2026 | Q300 hệ mới · Q306 Ceph RGW cho WORM · Q311/Q323(b) mỗi tỉnh chủ quản tenant · Q340 tách `pg-payment` · Q341, Q347 WORM và sao lưu chung hệ Ceph RGW, tách bucket · Q350 bản đồ DU theo SAD · Q353 GitHub khi phát triển, GitLab on-prem khi bàn giao · Q05 chủ quản CNTT là tham số theo tỉnh | Các tài liệu chứa câu hỏi tương ứng |
| 25/11/2026 | Q359: luồng Camel được truy cập trực tiếp CSDL có kiểm soát (tài khoản chỉ đọc, khai báo ở PH-05, ghi kiểm toán) · Catalog trình thiết kế phải khớp đúng phiên bản Camel Quarkus của runtime (hiện 3.33.2) | D04-01, PH-04, PH-05 |
