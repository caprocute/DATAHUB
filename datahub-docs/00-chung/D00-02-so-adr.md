---
ma_tai_lieu: D00-02
ten: Sổ quyết định kiến trúc (ADR)
phien_ban: 0.5
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư, Đội kỹ thuật, Hội đồng thẩm định
mo_ta: Sổ chỉ mục các quyết định kiến trúc của Datahub, gồm dải số cấp theo nhóm, danh sách 70 ADR với trạng thái và nhật ký quyết định của chủ đầu tư.
tai_lieu_lien_quan: D00-01 Thuật ngữ và quy ước §9.2; D03-01 SAD; D03-07 Thiết kế ATTT; D03-09 Hạ tầng và DR; thư mục adr/
---

# D00-02 · Sổ quyết định kiến trúc (ADR)

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Sổ ADR là chỉ mục của mọi quyết định kiến trúc có ảnh hưởng lâu dài của Datahub: công nghệ, mô hình dữ liệu, cách cách ly tenant, cách triển khai. Mỗi quyết định nêu bối cảnh, phương án đã cân nhắc, lý do chọn và hệ quả, để hội đồng thẩm định đánh giá được tính hợp lý của lựa chọn và đội kỹ thuật không phải tranh luận lại.

**Phạm vi.** Tài liệu gồm quan hệ với 22 ADR cũ trong `docs/05-adr` của repo, bảng dải số cấp trước cho các luồng viết song song, danh sách 70 ADR kèm trạng thái và nhóm phụ trách, bảng đề xuất ADR chưa có tệp, và nhật ký quyết định của chủ đầu tư. Nội dung từng ADR nằm ở file riêng trong thư mục `adr/`, không lặp lại ở đây.

**Căn cứ.** Khung MADR rút gọn theo D00-01 §9.2. Các ADR về an toàn thông tin viện dẫn CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026/NĐ-CP, TCVN 14423:2026), ví dụ ADR-030 chọn cấp độ 3 sẵn sàng cấp độ 4; các ADR về dữ liệu cá nhân viện dẫn CMP-LAW-04 và CMP-LAW-05.

**Những điểm hội đồng cần lưu ý.** (1) Trong 70 ADR, 6 ADR đã được chấp nhận ngày 25/11/2026 (ADR-004, 005, 030, 033, 061, 067) và 64 ADR ở trạng thái đề xuất, chờ duyệt ở cổng G1. (2) Bộ tài liệu độc lập với repo (quyết định Q11) nên đánh số lại, nhưng mỗi ADR ghi ADR tương ứng của repo trong mục Truy vết. (3) ADR-020 (Liquid Glass) thay ADR-016 của repo; ADR-003 bổ sung mô hình đa tenant; Backstage chưa được chọn làm cổng nhà phát triển. (4) Mỗi ADR một file, nên mọi thay đổi quyết định để lại dấu vết riêng và bảng này chỉ cần cập nhật trạng thái.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| ADR đã ghi | 70 |
| ADR đã chấp nhận | 6 (ngày 25/11/2026) |
| ADR đề xuất | 64 |
| Dải số cấp trước | 17 |
| ADR cũ của repo được đối chiếu | 22 |
| Dòng nhật ký quyết định chủ đầu tư | 5 |

: Con số chính của sổ quyết định kiến trúc

Các con số trên được đếm từ bảng ở mục 3, 4 và 5; trạng thái cập nhật tới ngày 27/11/2026.

## 1. Mục đích

Sổ ADR ghi lại mọi quyết định kiến trúc có ảnh hưởng lâu dài: chọn công nghệ, chọn mô hình dữ liệu, chọn cách cách ly, chọn cách triển khai. Mỗi quyết định nêu bối cảnh, các phương án đã cân nhắc, lý do chọn và hệ quả, để hội đồng thẩm định đánh giá được tính hợp lý của lựa chọn và để đội kỹ thuật về sau không phải tranh luận lại. Mỗi ADR nằm trong một file riêng ở thư mục `adr/`, theo khung MADR rút gọn (D00-01 §9.2).

### 1.1. Phạm vi

Sổ này chỉ là chỉ mục và nhật ký; phần lập luận của từng quyết định nằm ở file ADR. Bảng dưới phân định phần thuộc sổ này và phần thuộc tài liệu khác.

| Thuộc tài liệu này | Nằm ở tài liệu khác |
|---|---|
| Dải số ADR, danh sách và trạng thái | Nội dung từng ADR: `adr/ADR-{nnn}-*.md` |
| Nhật ký quyết định của chủ đầu tư | Khung MADR, cách đặt tên file: D00-01 §9.2 |
| Quan hệ với ADR của repo | Hiện thực kiến trúc theo quyết định: D03-01 SAD và các tài liệu thiết kế |

: Phân định phạm vi giữa D00-02 và các tài liệu khác

### 1.2. Người đọc

Bảng dưới gợi ý phần cần đọc theo vai trò.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, mục 4, 5 | Đánh giá các quyết định đã chốt và đang đề xuất |
| Kiến trúc sư | Mục 3, 4 và các file ADR | Tra quyết định, xin số ADR mới trong dải của luồng mình |
| Đội kỹ thuật, người viết tài liệu phân hệ | Mục 4 | Biết quyết định nào ràng buộc thiết kế của mình |

: Người đọc D00-02 và phần cần đọc theo vai trò

### 1.3. Thuật ngữ và chữ viết tắt

Sổ này không có thuật ngữ riêng. Thuật ngữ chung theo D00-01 §2; riêng ADR (Architecture Decision Record) là bản ghi một quyết định kiến trúc và MADR (Markdown Architectural Decision Records) là khung trình bày của bản ghi đó.

### 1.4. Tài liệu tham chiếu

Các tài liệu dưới đây được dẫn chiếu trong D00-02.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| D00-01 | Thuật ngữ và quy ước chung | Mục 9.2: khung MADR rút gọn và cách đặt tên file |
| D03-01 | Thiết kế kiến trúc tổng thể (SAD) | Nơi các quyết định được hiện thực |
| D03-07, D03-09 | Thiết kế ATTT, hạ tầng và DR | Nhận các quyết định ADR-030 đến ADR-038 |
| `docs/05-adr` | 22 ADR của repo DATAHUB | Nguồn đối chiếu, ghi ở mục Truy vết từng ADR |

: Tài liệu tham chiếu của D00-02

### 1.5. Cấu trúc tài liệu

Bảng dưới tóm tắt từng chương.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 2 | Quan hệ với ADR của repo | Hội đồng, kiến trúc sư |
| 3 | Dải số cấp trước theo nhóm | Kiến trúc sư, người viết |
| 4 | Danh sách ADR, trạng thái, nhóm; mục 4.1 đề xuất ADR chưa có tệp | Mọi người đọc |
| 5 | Nhật ký quyết định của chủ đầu tư | Hội đồng, quản lý dự án |

: Cấu trúc chương của D00-02

## 2. Quan hệ với ADR trong `docs/05-adr` của repo

Repo DATAHUB đã có 22 ADR trong `docs/05-adr`. Bộ tài liệu này độc lập (quyết định Q11) nên đánh số lại, nhưng mỗi ADR ở đây ghi rõ ADR tương ứng của repo trong mục Truy vết. Những điểm khác biệt có chủ đích so với repo: ADR-003 bổ sung mô hình đa tenant; ADR-020 (luồng giao diện) thay ADR-016 của repo, đổi phong cách shadcn sang Liquid Glass; Backstage (ADR-006 của repo) chưa được chọn làm cổng nhà phát triển, sẽ quyết định ở dải 050–059 khi viết PH-15.

## 3. Dải số

Bảng dưới cấp trước dải số ADR cho từng luồng viết, để các nhóm viết song song không trùng số.

| Dải | Chủ đề | Nhóm phụ trách |
|---|---|---|
| ADR-001 … 019 | Kiến trúc nền, stack, dữ liệu, tích hợp, đa tenant | Luồng lõi |
| ADR-020 … 029 | Giao diện, design system | Luồng giao diện |
| ADR-030 … 039 | ATTT, hạ tầng, DR, kiểm thử | Luồng ATTT và hạ tầng |
| ADR-040 … 049 | Thanh toán | Luồng PH-19 |
| ADR-050 … 059 | Danh mục dùng chung và các phân hệ khác | Luồng PH-07 và các phân hệ |
| ADR-060 … 069 | Lõi tích hợp, trình thiết kế luồng, bộ điều hợp (PH-04, PH-05) | Luồng PH-04 |
| ADR-070 … 074 | Sự kiện (PH-10) | Luồng PH-10 |
| ADR-075 … 079 | Kết nối quốc gia (PH-14) | Luồng PH-14 |
| ADR-080 … 084 | Dữ liệu chủ (PH-06) | Luồng PH-06 |
| ADR-085 … 089 | Chất lượng dữ liệu (PH-08) | Luồng PH-08 |
| ADR-090 … 094 | Quyền riêng tư (PH-09), đã dùng 090 … 093 | Luồng PH-09 |
| ADR-095 … 099 | Cổng nhà phát triển (PH-15) | Luồng PH-15 |
| ADR-110 … 114 | Quy trình liên thông (PH-11) | Luồng PH-11 |
| ADR-160 … 164 | Báo cáo chỉ tiêu và sổ kiến trúc (PH-16) | Luồng PH-16 |
| ADR-170 … 174 | Trợ lý AI (PH-17) | Luồng PH-17 |
| ADR-180 … 184 | Vận hành và xử lý lỗi (PH-18) | Luồng PH-18 |
| ADR-200 … 204 | Quản trị tenant (PH-20) | Luồng PH-20 |

: Dải số ADR cấp trước cho từng luồng viết

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
| [ADR-070](adr/ADR-070-tuong-thich-luoc-do-va-phien-ban-topic.md) | Tương thích lược đồ sự kiện mặc định BACKWARD, PH-10 duy nhất ghi Apicurio, thay đổi phá vỡ tạo topic `.v{n+1}` | Đề xuất | PH-10 |
| [ADR-071](adr/ADR-071-giao-nhan-day-keo-qua-dh-runtime.md) | Giao nhận đẩy (webhook ký HMAC) và kéo (API, Kafka ngoài) qua mô-đun của dh-runtime | Đề xuất | PH-10 |
| [ADR-072](adr/ADR-072-cap-phat-topic-acl-qua-gitops.md) | Cấp phát topic, ACL, hạn mức Kafka bằng tài nguyên Strimzi trong kho GitOps của tenant | Đề xuất | PH-10 |
| [ADR-073](adr/ADR-073-cau-noi-di-tru-pulsar.md) | Di trú Hub Pulsar bằng cầu nối hai chiều tạm thời trên dh-runtime | Đề xuất | PH-10 |
| [ADR-170](adr/ADR-170-spring-ai-pgvector-pg-core.md) | Spring AI và pgvector trên pg-core cho tri thức của trợ lý AI, truy hồi lai vector và từ khóa không dấu | Đề xuất | PH-17 |
| [ADR-171](adr/ADR-171-cong-mo-hinh-apisix-ai-proxy.md) | Cổng mô hình qua APISIX ai-proxy, mô hình nội bộ mặc định, mô hình ngoài theo danh sách trắng và phiên bản đã duyệt | Đề xuất | PH-17 |
| [ADR-172](adr/ADR-172-cong-cu-token-nguoi-dung-chi-doc.md) | Công cụ của trợ lý chạy bằng token người dùng, chỉ đọc; hành động ghi chỉ qua thẻ đề xuất người dùng xác nhận | Đề xuất | PH-17 |
| [ADR-173](adr/ADR-173-phong-thu-tiem-lenh-ca-do.md) | Phòng thủ tiêm lệnh nhiều lớp và bộ ca đỏ chạy trong CI làm cổng phát hành mô hình và chỉ dẫn hệ thống | Đề xuất | PH-17 |
| [ADR-174](adr/ADR-174-chi-muc-theo-su-kien-xoa-lan-truyen.md) | Lập chỉ mục tri thức theo sự kiện nguồn, chỉ dữ liệu Công khai và Nội bộ, xóa lan truyền hai pha | Đề xuất | PH-17 |
| [ADR-180](adr/ADR-180-kho-tham-so-tap-trung-theo-tenant.md) | Kho tham số tập trung theo tenant trên PostgreSQL, lược đồ khóa do phân hệ đăng ký, làm mới bằng sự kiện | Đề xuất | PH-18 |
| [ADR-181](adr/ADR-181-dlq-hop-nhat-chi-muc-postgresql.md) | Hàng đợi lỗi hợp nhất: chỉ mục trên PostgreSQL, payload gốc bất biến, payload lớn ở Garage, liên thông DLQ sự kiện của PH-10 | Đề xuất | PH-18 |
| [ADR-182](adr/ADR-182-phat-lai-qua-loi-vao-nguon.md) | Phát lại bản tin lỗi luôn qua lối vào của nguồn, khóa lũy đẳng theo bản sửa, loạt lớn duyệt bốn mắt | Đề xuất | PH-18 |
| [ADR-183](adr/ADR-183-khung-di-tru-dh-migrate.md) | Khung di trú hệ cũ: worker dh-migrate đọc JDBC chỉ đọc, ghi vào phân hệ đích qua API nhập, có chạy thử và báo cáo đối chiếu | Đề xuất | PH-18 |
| [ADR-184](adr/ADR-184-thong-bao-outbox-smtp-sms.md) | Thông báo qua outbox, SMTP/TLS và SMS gateway REST, mẫu Mustache không logic có kiểm tra cấm dữ liệu Hạn chế | Đề xuất | PH-18 |
| [ADR-200](adr/ADR-200-saga-khoi-tao-tu-xay-tren-postgresql.md) | Saga khởi tạo tenant tự xây trên PostgreSQL | Đề xuất | PH-20 |
| [ADR-201](adr/ADR-201-git-la-trang-thai-mong-muon-csdl-la-ban-chieu.md) | Git là trạng thái mong muốn của tenant, CSDL là bản chiếu | Đề xuất | PH-20 |
| [ADR-202](adr/ADR-202-sap-nhap-qua-hop-dong-ben-tham-gia.md) | Sáp nhập tenant qua hợp đồng bên tham gia, PH-18 chạy chuyển dữ liệu | Đề xuất | PH-20 |
| [ADR-203](adr/ADR-203-kenh-stable-preview-nang-cap-theo-song.md) | Kênh STABLE và PREVIEW, nâng cấp theo sóng, ngưỡng lỗi 2% | Đề xuất | PH-20 |
| [ADR-204](adr/ADR-204-anh-chup-su-dung-hang-gio-han-muc-hieu-luc.md) | Ảnh chụp sử dụng hằng giờ, hạn mức hiệu lực là min của trần và max của hợp đồng, ghi đè | Đề xuất | PH-20 |

: Danh sách 70 ADR kèm trạng thái và nhóm phụ trách

### 4.1. Đề xuất ADR chưa có tệp

Bảng dưới gom các quyết định kiến trúc mà tập phân hệ đã nêu là "đề xuất ADR" nhưng chưa tạo tệp trong `adr/`. Dải đã cấp ở mục 3 được giữ cho đúng phân hệ; quyết định chưa cấp số sẽ lấy số trong dải còn trống 014 … 019 và 024 … 029 khi đưa vào duyệt ở cổng G1. Các ADR 170 … 174 và 180 … 184 đã có tệp và nằm ở bảng mục 4; số ADR-171 là cổng mô hình và ADR-173 là phòng thủ tiêm lệnh theo đúng tệp, nên dòng ghi ADR-171 là truy hồi lai và ADR-173 là chỉ dẫn hệ thống ở Phụ lục B của FRS PH-17 cần đổi theo tệp. Số 075 mà tập PH-15 đề xuất cho cổng nhà phát triển trùng dải PH-14, nên chuyển sang 095 (các tập PH-15 và PH-16 cần đổi dòng "ADR 075").

| Số hoặc dải | Phân hệ | Nội dung đề xuất |
|---|---|---|
| 075 … 078 | PH-14 | (A) Ký số bản tin quốc gia bằng OpenBao `transit` qua nhà cung cấp JCA không có vật liệu khóa, kiểm khớp khóa hai lớp; (B) kiểm soát mục đích ở cổng quốc gia vì tài khoản NDXP dùng chung, đóng an toàn; (C) phân bổ hạn mức, ưu tiên dịch vụ thiết yếu, đệm gộp lượt trùng bằng script nguyên tử ở Valkey; (D) mặt phẳng dữ liệu không nối PostgreSQL, ghi bền qua spool đĩa và Kafka, cấu hình bằng ảnh chụp có chữ ký |
| 080 … 084 | PH-06 | Đối sánh theo lô bằng Splink chạy Job K8s đọc staging; đối sánh trực tuyến bằng quy tắc xác định và `pg_trgm`; ảnh chụp đầy đủ cho lịch sử và hoàn tác bản ghi vàng; nguồn gốc ở cấp thuộc tính; sự kiện dữ liệu chủ không chứa DLCN, bên nhận tra lại theo mục đích |
| 085 … 089 | PH-08 | Thực thi quy tắc tập hợp bằng SQL đẩy xuống và quy tắc mức bản ghi bằng CEL; bản ghi lỗi có dấu vân tay, che HMAC theo tenant, phân vùng tháng; truy cập dữ liệu đo qua khung nhìn hợp đồng PH-06 và kết nối PH-05 chỉ đọc; kiểm tra trực tuyến với bộ đệm quy tắc trong bộ nhớ; 089 dự phòng cho dựng PDF và ký số báo cáo |
| 090 … 093 | PH-09 | Điểm quyết định chính sách tập trung (PH-09 là PAP và PIP, OPA là PDP); giả danh hóa HMAC và token, không bảng ánh xạ; ẩn danh hóa bằng ARX với k tối thiểu 10; phát hiện DLCN bằng mẫu và kiểm tổng, không dùng ML |
| 095 | PH-15 | Cổng nhà phát triển tự xây trên `@datahub/ui` thay Backstage (đề xuất số 075 ở tập PH-15) |
| 110 … 114 | PH-11 | Một engine Flowable nhúng đa tenant; trình thiết kế bpmn-js nhúng React; service task bất đồng bộ qua lệnh Kafka và outbox; Saga bằng sự kiện bù trừ BPMN cộng `saga_log`; lịch làm việc theo tenant |
| 160 … 164 | PH-16 | Chỉ tiêu trên PostgreSQL phân vùng, không ClickHouse; công thức bằng CEL; báo cáo chính thức bất biến, ký số, lưu WORM; gói gửi quốc gia theo mẫu cấu hình qua PH-14; sổ kiến trúc tự xây, không dùng Backstage |
| 200 … 204 | PH-20 | Saga khởi tạo tenant trên PostgreSQL; GitOps cấu hình tenant qua `dh-tenant-config`; hợp đồng bên tham gia sáp nhập; kênh phát hành và nâng cấp theo sóng; đo sử dụng hằng giờ và hạn mức hiệu lực |
| Chưa cấp số | PH-01 | (a) Bàn giao thông tin xác thực một lần bằng response wrapping của OpenBao và đăng nhập đúng đầu mối; (b) mở rộng ADR-058 cho quy trình kết nạp HTTT nhiều bước, giữ đường nâng lên Flowable; (c) trần phạm vi (`ScopeCeiling`) là giới hạn trên của đăng ký sử dụng |
| Chưa cấp số | PH-03 | (1) Plugin APISIX do Datahub viết bằng Lua và danh mục mười plugin được duyệt, bổ sung ADR-005; (2) bộ đồng bộ `dh-sync` bằng Go, định dạng ảnh chụp và hoàn nguyên có xác nhận; (3) kênh nhanh Valkey cho thu hồi token và tạm ngừng khẩn cấp, mô hình hai chặng `apisix-ext`, `apisix-int`; (4) mô hình mảnh tenant và bản ghép nền tảng của ảnh chụp cấu hình ở `QM-CHUNG`; (5) có điều kiện: phân trang con trỏ cho API đọc từ kho phân tích ClickHouse trên toàn hệ thống, nếu câu hỏi Q03-56 được chấp nhận |
| Chưa cấp số | PH-12 | (a) Đăng nhập liên tenant qua nhà môi giới `dh-platform` và quyền có thời hạn; (b) chính sách của tenant chỉ thêm luật chặt hơn; (c) dữ liệu vai trò và quyền sinh thành gói ký; (d) thu hồi bằng `notBefore`, API kéo và Kafka; (e) bộ mở rộng Keycloak tối thiểu và ảnh tùy biến; (f) ký gói OPA bằng khóa transit; (g) chạy Rego cô lập trong `policy-runner`; (h) chốt tách nhiệm vụ, bốn mắt và máy trạng thái ở CSDL bằng trigger kèm khóa tư vấn, bổ sung ADR-069; (i) mẫu RLS G cho quyền có thời hạn vào tenant khác |
| Chưa cấp số (dải 050 … 059 dùng chung PH-07 và khác) | PH-02 | Công bố có xác nhận từ cổng, hạn chế ghi ngay: `:publish` trả `202` khi cổng chưa xác nhận, trạng thái cuối (`PUBLISHED`) chỉ ghi sau API-02-082; không tạo tệp ADR cho tới khi đưa vào duyệt ở cổng G1 |

: Đề xuất ADR chưa có tệp, theo dải hoặc phân hệ

## 5. Nhật ký quyết định của chủ đầu tư

Bảng dưới ghi các quyết định của chủ đầu tư ảnh hưởng tới kiến trúc theo thứ tự ngày, kèm tài liệu chịu ảnh hưởng.

| Ngày | Nội dung | Ảnh hưởng |
|---|---|---|
| 21/11/2026 | Q1–Q13 về định vị, đa tenant, phạm vi, giao diện, pháp lý (ghi ở README và D00-03) | Toàn bộ bộ tài liệu |
| 25/11/2026 | Chấp nhận ADR-004 (Kafka thay Pulsar), ADR-005 (APISIX, chế độ standalone), ADR-030 (cấp độ 3 sẵn sàng cấp độ 4) | D03-07, D03-09 |
| 25/11/2026 | Giữ APISIX ở biên, không thêm Envoy Gateway (ADR-033 bản 0.2) | D03-07, D03-08, D03-09, SAD §6 |
| 25/11/2026 | Q300 hệ mới · Q306 Ceph RGW cho WORM · Q311/Q323(b) mỗi tỉnh chủ quản tenant · Q340 tách `pg-payment` · Q341, Q347 WORM và sao lưu chung hệ Ceph RGW, tách bucket · Q350 bản đồ DU theo SAD · Q353 GitHub khi phát triển, GitLab on-prem khi bàn giao · Q05 chủ quản CNTT là tham số theo tỉnh | Các tài liệu chứa câu hỏi tương ứng |
| 25/11/2026 | Q359: luồng Camel được truy cập trực tiếp CSDL có kiểm soát (tài khoản chỉ đọc, khai báo ở PH-05, ghi kiểm toán) · Catalog trình thiết kế phải khớp đúng phiên bản Camel Quarkus của runtime (hiện 3.33.2) | D04-01, PH-04, PH-05 |

: Nhật ký quyết định của chủ đầu tư theo ngày

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: quan hệ với ADR của repo, dải số, danh sách ADR, nhật ký quyết định của chủ đầu tư |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định; thêm mục 1.1 đến 1.5 (phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); thêm đoạn mở cho mục 3 và 5; viết lại chú thích bảng cho cụ thể |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: thêm vào mục 3 các dải 075 đến 099, 110 đến 114, 160 đến 204 của PH-14, 06, 08, 09, 15, 11, 16, 17, 18, 20; thêm ADR-170 đến 174 và ADR-180 đến 184 vào danh sách (70 ADR); thêm mục 4.1 đề xuất ADR chưa có tệp |
| 0.4 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: mục 4.1 thêm đề xuất ADR của PH-02 (công bố có xác nhận từ cổng) |
| 0.5 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: lập tệp ADR-200 đến ADR-204 của PH-20 (saga khởi tạo, Git và bản chiếu, sáp nhập, nâng cấp theo sóng, ảnh chụp sử dụng) |
