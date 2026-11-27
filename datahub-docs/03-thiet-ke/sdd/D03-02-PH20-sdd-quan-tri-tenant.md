---
ma_tai_lieu: D03-02-PH20
ten: Thiết kế chi tiết phần mềm phân hệ PH-20 Quản trị tenant và phát hành sản phẩm
phien_ban: 0.4
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kiến trúc sư, ATTT, SRE, kiểm thử viên, hội đồng thẩm định
phan_he: PH-20
mo_ta: Thiết kế chi tiết hiện thực 70 FR của PH-20 gồm hai mô-đun Modulith tenant và release trong dh-platform với 19 thành phần có khối đặc tả 10 mục, saga khởi tạo tenant 17 bước tự xây trên PostgreSQL có sổ bước, lũy đẳng và bù trừ, cấu hình GitOps, hạn mức và đo sử dụng phân vùng, vòng đời tạm ngừng và chấm dứt có bốn mắt, sáp nhập theo hợp đồng bên tham gia, phát hành nâng cấp theo sóng, registry có đệm cho phân hệ khác, chín sơ đồ trình tự, bảo mật, quan sát, hiệu năng và năm ADR đề xuất.
tai_lieu_lien_quan: D02-03-PH20 FRS; D02-04-PH20 Use case; D03-03-PH20 CSDL; D03-04-PH20 API; D03-06-PH20 Màn hình; D03-09 Hạ tầng triển khai; D03-10 Thiết kế đa tenant; D03-02-PH12; D03-02-PH13; D03-02-PH16
---

# D03-02-PH20 · Thiết kế chi tiết Quản trị tenant và phát hành sản phẩm

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 70 FR của [D02-03-PH20](../../02-yeu-cau/frs/D02-03-PH20-frs-quan-tri-tenant.md). PH-20 là phân hệ làm cho Datahub từ "một bản cài cho một tỉnh" thành "một sản phẩm dùng chung cho nhiều tỉnh": khởi tạo tỉnh mới bằng saga tự động mười bảy bước trong không quá một giờ, giữ hạn mức và đo sử dụng của từng tỉnh, tạm ngừng, chấm dứt và sáp nhập tỉnh có kiểm soát, quản lý danh mục tổ chức, và đưa bản phát hành mới tới từng tỉnh theo sóng. Phân hệ là control plane của control plane: không nằm trên đường gọi API của HTTT nhưng mọi phân hệ khác đọc registry của nó. Hệ cũ không có khái niệm tenant nên toàn bộ là thiết kế mới. Sáu quyết định chi phối thiết kế:

1. **Hai mô-đun Modulith trong `dh-platform`, một schema.** `vn.datahub.platform.tenant` (15 thành phần) và `vn.datahub.platform.release` (hai thành phần), cộng hai thành phần dùng chung ở `platform.shared`, cùng ghi schema `ph20_tenant` của `pg-core` và dùng chung hạ tầng outbox, inbox, kiểm toán ở `platform.shared`. Mô-đun khác chỉ import gói công bố `tenant.api`; `release` đọc `tenant.api`, còn `tenant` không bao giờ import `release` (chiều ngược đi qua sự kiện ứng dụng và giao diện mở rộng, mục 3.3).
2. **Saga khởi tạo tự xây trên PostgreSQL, không dùng bộ điều phối ngoài.** Lần chạy và sổ bước nằm ở bảng `provisioning_run`, `provisioning_step`; mỗi bước lũy đẳng theo `Idempotency-Key = {runId}:{stepCode}`, có thao tác bù ngược, chạy dưới khóa ShedLock và hết hạn khi chờ báo (ADR 200). Temporal, Camunda, Flowable bị loại cho saga hạ tầng vì thêm một hệ phải vận hành cho một dãy 17 bước đã biết trước; Flowable của PH-11 giữ cho quy trình nghiệp vụ có người.
3. **Git là trạng thái mong muốn, CSDL là bản chiếu.** Cấu hình tenant ghi thành tệp YAML có ký trong kho `dh-tenant-config` (thư mục `tenants/{ma-tenant}/`), Argo CD áp xuống, bộ phát hiện lệch đối chiếu hằng giờ (ADR 201). Nhờ đó khác biệt giữa các tỉnh chỉ là cấu hình có phiên bản, không bao giờ là nhánh mã riêng.
4. **PH-20 điều phối, không thực thi.** Hạn mức đẩy xuống APISIX, Kafka, Kubernetes, PH-12 (ADR 204); chuyển dữ liệu sáp nhập do PH-18 chạy theo hợp đồng "bên tham gia sáp nhập" của từng phân hệ (ADR 202); trạng thái tạm ngừng do PH-03, PH-12 thực thi ở data plane. PH-20 dừng thì data plane vẫn phục vụ nhờ bộ đệm registry (BR-20-036).
5. **Thao tác không đảo ngược được cần hai người và lưới an toàn.** Chấm dứt, sáp nhập, đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng cần hai quản trị nền tảng khác nhau, kiểm ở dịch vụ và ở ràng buộc CSDL. Chấm dứt phải qua tạm ngừng, bàn giao dữ liệu, thời gian nguội 30 ngày rồi mới xóa mật mã.
6. **Phát hành an toàn cho nhiều tỉnh.** Hai kênh `STABLE`, `PREVIEW`; bản `STABLE` chỉ nhận sau 14 ngày chạy ở tenant thí điểm; nâng cấp theo sóng trong cửa sổ bảo trì của từng tỉnh, sóng tự dừng khi tỷ lệ lỗi vượt 2% (ADR 203).

Tập nêu năm ADR đề xuất (200 đến 204, chưa có tệp), mười câu hỏi mở Q20-20…29 (mục 13.5), ma trận thành phần với FR (mục 13.3) và Phụ lục A đề nghị đồng bộ, gồm các điểm lệch giữa FRS, CSDL và brief mà SDD đã chọn phương án.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Mô-đun Modulith | 2 (`tenant`, `release`), một schema `ph20_tenant` (45 bảng) |
| Thành phần có khối đặc tả 10 mục | 19 (mục 4.2 đến 4.20) |
| Sơ đồ Mermaid | 15 (1 thành phần C4, 1 phụ thuộc mô-đun, 1 lớp miền, 9 tuần tự, 2 trạng thái, 1 triển khai) |
| FR hiện thực | 70 (51 mức M, 19 mức S), ma trận ở mục 13.3 |
| Bước saga | 17 (`S01_RECORD` … `S17_ACTIVATE`), mỗi bước một `StepExecutor` |
| Mã lỗi | 86 (ERR-20-001…068, ERR-20-101…118), bảng ở mục 8.5 |
| Sự kiện phát, tiêu thụ | 16 phát (EVT-20-01…16), 6 tiêu thụ |
| Tham số `20.*` | 29 khóa, bảng ở mục 9.1 |
| Chỉ tiêu thời gian | Saga ≤ 60 phút p95, registry p99 ≤ 50 ms, tạm ngừng có hiệu lực ≤ 60 giây, ≥ 34 tenant (thiết kế 40) |
| ADR đề xuất, câu hỏi mở | 5 (200…204); 10 (Q20-20…29) |

: Con số chính của SDD PH-20

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Tài liệu là thiết kế phần mềm đủ để kỹ sư viết mã và kiểm thử viên viết ca kiểm thử mà không phải đoán: cấu trúc gói, lớp chính, thuật toán, giao dịch, khóa, thời gian chờ, tên chỉ số. Phạm vi gồm 19 thành phần của hai mô-đun `tenant` và `release` cùng hồ sơ triển khai. Ngoài phạm vi: lược đồ bảng (D03-03-PH20), đặc tả API (D03-04-PH20), màn hình (D03-06-PH20), ca kiểm thử (D05-02-PH20). PH-20 không tự thực thi hạn mức, không tạo realm hay chính sách OPA (PH-12), không dựng quan sát (PH-13), không chạy công cụ chuyển dữ liệu sáp nhập (PH-18), không gieo danh mục (PH-07), không cấp phát topic và ACL (PH-10). PH-20 gọi các phân hệ đó theo hợp đồng ở mục 2.4.

### 1.2. Người đọc

Kỹ sư `dh-platform` đọc chương 3, 4, 5, 8; kỹ sư hạ tầng và SRE đọc 2, 9 đến 11; kiến trúc sư, ATTT đọc 2, 6, 7; kiểm thử viên đọc 8, 12; hội đồng thẩm định đọc Tóm tắt và chương 13.

### 1.3. Quy ước trong tài liệu

Mã `FR-20-nnn`, `BR-20-nnn`, `NFR-20-nnn`, `ERR-20-nnn`, `EVT-20-nn`, `API-20-nnn` lấy từ FRS; tên bảng và cột lấy từ DDL `ph20_tenant.sql`; mã bước saga theo bảng 4.4 của FRS. Enum theo Phụ lục A của FRS; chỗ CSDL hoặc brief lệch FRS thì SDD theo FRS và ghi lệch ở Phụ lục A. Chỉ số quan sát có tiền tố `dh_tenant_` và `dh_release_` (NFR-20-021). Trong văn bản, "ADR 200…204" viết có dấu cách vì chưa có tệp ADR. Số liệu giả định ghi "giả định": tỉnh `T01` quy mô vừa theo GĐ-01 (khoảng 200 HTTT, 500 tổ chức), tenant ví dụ `T68`, tenant kiểm thử `T90…T99`.

### 1.4. Thuật ngữ và chữ viết tắt

Tập dùng nhiều thuật ngữ về điều phối, cấu hình mong muốn và nâng cấp theo sóng; bảng dưới giải thích từng thuật ngữ kèm bảng CSDL hoặc lớp khi có.

| Thuật ngữ | Giải thích |
|---|---|
| Tenant | Một tỉnh hoặc thành phố trực thuộc trung ương, mã `^T\d{2}$`, hoặc tenant đặc biệt `PLATFORM`, `COMMON` (`tenant`) |
| Control plane, data plane | Mặt phẳng điều khiển (quản trị, cấu hình, vòng đời) và mặt phẳng dữ liệu (đường gọi API, luồng, sự kiện của HTTT); PH-20 thuộc control plane |
| Saga (orchestration) | Chuỗi bước có bù trừ do một bộ điều phối trung tâm chạy tuần tự hoặc song song; ở đây là 17 bước `S01…S17` (`provisioning_run`, `provisioning_step`) |
| Sổ bước | Bản ghi trạng thái từng bước của một lần chạy, ghi trước khi bước chạy để chạy lại đúng chỗ dở |
| Lũy đẳng (idempotent) | Gọi lại cùng khóa cho cùng kết quả, không tạo trùng; khóa bước là `{runId}:{stepCode}` |
| Bù trừ (compensation) | Thao tác hoàn tác một bước đã xong, chạy theo thứ tự ngược |
| ShedLock | Thư viện khóa phân tán trên bảng CSDL để chỉ một bản sao chạy một tác vụ nền |
| Bước bất đồng bộ | Bước do phân hệ đích tự xử lý sau sự kiện và báo kết quả qua API-20-166 (`S06`, `S09`, `S10`, `S12`, `S15`) |
| Trạng thái mong muốn (desired state) | Cấu hình ghi trong Git `dh-tenant-config`; Argo CD đưa hệ thống thực tế về khớp với nó |
| Lệch cấu hình (drift) | Khác biệt giữa Git, bản chiếu CSDL và trạng thái đang chạy (`config_drift`) |
| Hạn mức hiệu lực | Lớn hơn của hạn mức hợp đồng và ghi đè còn hạn, không vượt trần nền tảng của hồ sơ quy mô (BR-20-013) |
| Ảnh chụp sử dụng | Giá trị sử dụng một tài nguyên của một tenant tại một giờ (`usage_snapshot`, phân vùng tháng) |
| Bên tham gia sáp nhập (`MergeParticipant`) | Hợp đồng mỗi phân hệ có dữ liệu cung cấp để xuất, nhập, kiểm đếm theo gói khi sáp nhập tenant |
| Cutover | Khoảnh khắc tenant nguồn sang `MERGED` và gateway bắt đầu chuyển tiếp lượt gọi sang tenant đích |
| Kênh phát hành | `STABLE` hoặc `PREVIEW`; mỗi tenant đăng ký một kênh cho mỗi môi trường |
| Sóng (wave) | Nhóm tenant nâng cấp cùng lúc trong một kế hoạch; sóng dừng khi tỷ lệ lỗi vượt ngưỡng |
| Bốn mắt | Người duyệt khác người lập và người gửi (ADR-046) |
| PA, PO, PAU, TA, TO, SO, AU, DS, VW | Vai trò của D02-08 dùng ở PH-20: quản trị nền tảng, vận hành nền tảng, kiểm toán nền tảng, quản trị tỉnh, vận hành tỉnh, an toàn thông tin, kiểm toán, cán bộ dữ liệu, người xem |

: Thuật ngữ và chữ viết tắt

### 1.5. Cấu trúc tài liệu

Chương 2, 3: vị trí trong kiến trúc, bối cảnh, cấu trúc mã và luật phụ thuộc; chương 4: mô hình miền và 19 thành phần cùng các thuật toán; chương 5: chín sơ đồ trình tự; chương 6, 7: đa tenant và bảo mật; chương 8: máy trạng thái, lỗi, thử lại, nhất quán; chương 9, 10: cấu hình, quan sát; chương 11: hiệu năng và triển khai; chương 12: kiểm thử; chương 13: lộ trình, rủi ro, ADR, câu hỏi mở; Phụ lục A: đề nghị đồng bộ.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Thiết kế dựa trên FRS, thiết kế CSDL, thiết kế đa tenant, kiến trúc tổng thể và các quyết định kiến trúc đã có; bảng dưới ghi từng tài liệu và phần nội dung mà tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH20 FRS 0.2 | 70 FR, 42 BR, 24 NFR, 29 tham số, 16 sự kiện, 86 mã lỗi, 171 API, Phụ lục A enum |
| D03-03-PH20 CSDL 0.2 | Schema `ph20_tenant`: 45 bảng, RLS năm chế độ, bốn vai kết nối, phân vùng `usage_snapshot`, DDL chạy thử |
| D03-10 Thiết kế đa tenant | Máy trạng thái tenant (§5.1), saga 17 bước `S01`…`S17` (§5.2), hạn mức (§5.3), sáp nhập (§5.4) |
| D03-01 SAD khối `dh-platform` | Vùng Z3, hai hồ sơ triển khai, phụ thuộc hạ tầng |
| D03-02-PH12, PH13, PH16, PH07, PH10, PH03 | Hợp đồng phía phân hệ được gọi: API-12-080, API-13-072, API-16-030, API-07-073, FR-10-064, FR-03-037 |
| ADR-001, 003, 004, 009, 012, 013, 031, 034, 036, 041, 042, 046, 047, 059, 068, 072 | Spring Boot 4 và Modulith, RLS, Kafka, Argo CD, OpenBao, tách control và data plane, kiểm toán chuỗi băm, DR, air-gapped, lũy đẳng, outbox và inbox, bốn mắt, phân vùng, CDC Debezium, kho Git theo tenant, cấp phát topic qua GitOps |
| ADR đề xuất 200…204 | Mục 13.4 |

: Tài liệu liên quan và ADR

## 2. Vị trí trong kiến trúc

### 2.1. Bối cảnh và ràng buộc

PH-20 thuộc DU `dh-platform`, vùng ứng dụng nội bộ Z3 (giả định namespace `dh-control`, D03-09). Bảng dưới liệt kê các ràng buộc làm hình dạng thiết kế; mỗi ràng buộc ghi nguồn để người đọc biết đâu là quyết định đã chốt, đâu là tự do của SDD.

| Ràng buộc | Hệ quả cho thiết kế | Nguồn |
|---|---|---|
| Java 21, Spring Boot 4, Spring Modulith, một DU `dh-platform` dùng chung với PH-11, 12, 13, 16, 18 | Hai mô-đun `tenant`, `release`; hạ tầng dùng chung ở `platform.shared`; không tách dịch vụ mới | ADR-001, D03-01 |
| PostgreSQL với RLS `FORCE`, vai kết nối không `BYPASSRLS` | Mọi truy cập qua `TenantSession` đặt `app.tenant_id`; hai bể kết nối `ph20_app` và `ph20_platform_app`; bảng `tenant` có chính sách riêng | ADR-003, D03-03-PH20 §4 |
| Control plane tách khỏi data plane | PH-20 không nằm trên đường gọi API; phân hệ khác đọc registry có đệm; PH-20 dừng không làm data plane ngừng | ADR-013, BR-20-036 |
| Bí mật chỉ ở OpenBao | `ph20_tenant` và Git chỉ giữ tham chiếu (`kv/dh/{ma}/...`, `db_route_ref`, `cluster_ref`); tài khoản gọi ra lấy thông tin xác thực ngắn hạn | ADR-012, NFR-20-024 |
| Hai hồ sơ triển khai, có `HT-A` on-prem air-gapped | Không phụ thuộc Internet; kho Git, kho ảnh, Argo CD đều trong mạng; kho `dh-tenant-config` là GitLab hoặc Gitea nội bộ | ADR-036, D03-09 |
| Cấu hình luồng tích hợp tách kho theo tenant (`dh-flows-{tenant}`) | PH-20 chỉ tạo kho này ở bước `S10_INTEGRATION` (PH-04 làm), không ghi vào đó; `dh-tenant-config` là kho riêng, chủ PH-20 | ADR-068 |
| Sự kiện qua outbox, tiền tố nền tảng cho vòng đời tenant | Topic `platform.tenant.*.v1` vì tenant mới chưa có tiền tố Kafka riêng; sự kiện tổ chức dùng `{tenant}.tenant.org.changed.v1` | ADR-042, ADR-059, brief §1 |
| Saga ≤ 1 giờ ở `SHARED`, ≥ 34 tenant | Bước độc lập chạy song song; thiết kế dung lượng cho 40 tenant; bước chờ phân hệ có hạn riêng | NFR-00-057, NFR-00-060 |
| Bốn mắt cho thao tác không đảo ngược | Ràng buộc `ck_*_four_eyes` ở CSDL cộng kiểm ở dịch vụ | ADR-046, BR-20-008 |
| Hạ tầng hiện chưa có mã nguồn PH-20 | Thiết kế mới; không có đường chuyển dữ liệu cũ | mục 2.5 |

: Ràng buộc nền của PH-20

### 2.2. Đơn vị triển khai và vùng mạng

PH-20 chạy cùng ảnh container `dh-platform` ở hai hồ sơ Spring. Hồ sơ `api` (Deployment `dh-platform-api`) phục vụ `/api/platform/v1`, `/api/tenant/v1`, `/internal/tenant/v1` và luồng SSE tiến độ saga. Hồ sơ `worker` (Deployment `dh-platform-worker`) chạy bộ thực thi saga, bộ thu sử dụng, bộ phát hiện lệch, bộ điều phối nâng cấp, kiểm thử rò rỉ và các tác vụ nền; mỗi Deployment tối thiểu hai bản sao để đạt sẵn sàng control plane ≥ 99,5% và registry ≥ 99,9% (NFR-20-017). Tác vụ nền chạy dưới ShedLock nên chỉ một bản sao chạy mỗi lần.

`NetworkPolicy` chỉ cho `dh-platform` đi ra tới: PgBouncer của `pg-core`; Kafka (Z5); Valkey; OpenBao; Ceph RGW (S3 và Admin Ops cho hạn mức bucket); máy chủ Git `dh-tenant-config`; API của Argo CD (chỉ đọc trạng thái Application); API Kubernetes ở chế độ chỉ đọc (theo dõi cụm CloudNativePG); Mimir (truy vấn số liệu sử dụng); các phân hệ khác trong mesh (PH-12, 13, 07, 16, 18, 09) qua mTLS và scope dịch vụ. PH-20 không gọi Keycloak trực tiếp (việc đó là của PH-12) và không ra Internet. Lưu lượng vào đi qua APISIX (Z2) với OIDC và OPA; nhóm `/api/platform/` không mở ra cổng công khai (chỉ vai trò nền tảng và tài khoản dịch vụ); nhóm `/internal/tenant/v1` chỉ nhận lời gọi trong mesh có SPIFFE ID hợp lệ.

### 2.3. Sơ đồ thành phần

Sơ đồ dưới (C4 mức thành phần) cho thấy 19 thành phần của hai mô-đun, ba nhóm đường vào (REST nền tảng và tỉnh, REST nội bộ từ phân hệ khác, sự kiện Kafka), hai kho trạng thái (PostgreSQL và Git) và các hệ được gọi ra. Để chữ đọc được trên trang A4, sơ đồ vẽ theo chiều dọc và nhóm thành phần theo mô-đun.

```{.mermaid caption="Sơ đồ thành phần C4 mức 3 của PH-20 trong dh-platform và các hệ lân cận"}
flowchart TB
  subgraph UI["Biên và giao diện"]
    CON["dh-console<br/>/nen-tang, /quan-tri"]
    AX["APISIX Z2<br/>OIDC, OPA"]
    PX["Phân hệ khác<br/>PH-01, 03, 04, 10, 12, 18"]
  end
  subgraph TEN["Mô-đun tenant · hồ sơ api và worker"]
    TS["TenantService<br/>hồ sơ, sẵn sàng"]
    PO["ProvisioningOrchestrator<br/>saga ADR 200"]
    SE["StepExecutor S01..S17"]
    SM["SmokeTestRunner"]
    GW["GitOpsConfigWriter<br/>DriftDetector"]
    QS["QuotaService<br/>QuotaPublisher"]
    UC["UsageCollector<br/>QuotaAlertEvaluator"]
    MT["ModuleCatalog<br/>ModuleToggleService"]
    LS["LifecycleService"]
    DX["DataExportService"]
    MC["MergeCoordinator<br/>MergeParticipant"]
    OS["OrganizationService<br/>OrgImport"]
    CT["CrossTenantPolicyService"]
    LT["LeakTestScheduler"]
    RA["TenantRegistryApi<br/>RegistryCache"]
  end
  subgraph REL["Mô-đun release"]
    RS["ReleaseService<br/>kênh, phiên bản"]
    UO["UpgradeOrchestrator<br/>sóng, cửa sổ, ngưỡng"]
  end
  subgraph SHR["platform.shared"]
    OB["Outbox, Inbox<br/>Idempotency"]
    XA["ExternalCallAdapter<br/>thời gian chờ, thử lại, ngắt mạch"]
  end
  subgraph DATA["Trạng thái"]
    PG[("pg-core<br/>ph20_tenant")]
    GIT[("Git dh-tenant-config")]
    KF[("Kafka<br/>platform.tenant.*")]
    VK[("Valkey")]
  end
  subgraph EXT["Hệ được gọi"]
    P12["PH-12 realm"]
    P13["PH-13 quan sát"]
    P07["PH-07 danh mục nền"]
    P16["PH-16 KPI-12"]
    P18["PH-18 merge-transfers, thông báo"]
    INF["OpenBao, Ceph RGW, Argo CD, Mimir, CNPG"]
  end
  CON --> AX --> TS
  PX -->|"REST nội bộ"| RA
  PX -->|"API-20-166, 167, 168"| PO
  TS --> PO
  PO --> SE --> SM
  SE --> XA
  PO --> OB
  TS --> GW
  QS --> GW
  MT --> GW
  GW --> GIT
  GW --> XA
  UC --> QS
  LS --> DX
  LS --> MC
  MC --> XA
  RS --> UO
  UO --> GW
  LT --> SM
  RA --> VK
  OB --> PG
  OB --> KF
  KF --> OS
  XA --> P12
  XA --> P13
  XA --> P07
  XA --> P16
  XA --> P18
  XA --> INF
  TS --> PG
  PO --> PG
  UO --> PG
```

Hình cho thấy ba điểm. Thứ nhất, mọi lời gọi ra ngoài đi qua `ExternalCallAdapter` nên thời gian chờ, thử lại và ngắt mạch nằm ở một chỗ. Thứ hai, mọi thay đổi cấu hình tenant đi một đường: dịch vụ ghi CSDL rồi `GitOpsConfigWriter` commit vào Git, không thành phần nào tự ghi Git. Thứ ba, `release` chỉ đi qua `UpgradeOrchestrator` tới `GitOpsConfigWriter` (qua `tenant.api`) để đổi thẻ phiên bản, và `tenant` không có mũi tên nào tới `release`.

### 2.4. Phụ thuộc với phân hệ và hạ tầng khác

Bảng ghi loại phụ thuộc cứng hay mềm và ứng xử khi không khả dụng, theo nguyên tắc: đường đọc của phân hệ khác (registry) không bao giờ phụ thuộc vào hệ ngoài; thao tác ghi fail-closed; số đo fail-soft.

| Phụ thuộc | Hướng | Loại | Dùng cho | Khi không khả dụng |
|---|---|---|---|---|
| PostgreSQL `pg-core` | Ra | Cứng | Mọi trạng thái | `readiness` sai, không nhận yêu cầu; registry vẫn trả từ bộ đệm Valkey và bộ đệm cục bộ của phân hệ gọi |
| Kafka (Z5) | Ra, vào | Cứng cho phát, mềm cho nhận | Phát EVT-20, nhận EVT-07-10, 12-13, 09-21, 13-14, 03-10, 03-11 | Outbox giữ sự kiện; không có sự kiện mới tới khi Kafka về; bước chờ báo hết hạn bình thường |
| Git `dh-tenant-config`, Argo CD | Ra | Cứng cho ghi cấu hình | Commit cấu hình, theo dõi áp dụng | ERR-20-024 (502); thao tác cấu hình thất bại, CSDL giữ ý định `PENDING`, `GitOpsConfigWriter` thử lại; không mất dữ liệu |
| OpenBao | Ra | Cứng cho `S04`, ký commit, xóa KEK | Đường dẫn bí mật, KEK `dh-{ma}-pii`, khóa ký | Bước `S04` thử lại; chấm dứt tạm hoãn ở bước xóa mật mã |
| Ceph RGW | Ra | Cứng cho `S05`, gói bàn giao | Bucket, hạn mức bucket, gói bàn giao | Bước thử lại; gói `FAILED` |
| PH-12 | Ra | Cứng cho `S03`, tạm ngừng, sáp nhập | API-12-080, 084, 085, 045, 046 | Saga dừng `FAILED` sau lần thử; tạm ngừng vẫn có hiệu lực ở APISIX qua PH-03 trong khi chờ PH-12 |
| PH-13 | Ra | Cứng cho `S08`, mềm cho kiểm toán | API-13-072, 073; Mimir | `S08` thử lại; số liệu sử dụng thiếu thì không có dòng, không có cảnh báo giả |
| PH-07, PH-16, PH-18 | Ra | `S11` cứng; `S14`, thông báo mềm | API-07-073, API-16-030, merge-transfers, thông báo | `S11` thử lại; `S14` bỏ qua được; thông báo xếp hàng thử lại |
| PH-03, PH-04, PH-10, PH-06, PH-19, PH-17 | Vào qua sự kiện và API đọc | Mềm cho PH-20 | Nghe EVT-20, đọc API-20-164, báo tiến độ API-20-166 | Phân hệ không báo thì bước hết hạn, `FAILED`, thử lại được |
| PH-01, 06, 07, 08, 12, 16 | Vào | Cứng cho phân hệ gọi | Đọc tổ chức (API-20-169…171), registry | Bộ đệm phía phân hệ gọi (24 giờ cho tổ chức) |
| Mimir | Ra | Mềm | Số đo sử dụng | Dòng ảnh chụp thiếu, đọc bù ≤ 24 giờ |

: Phụ thuộc của PH-20

### 2.5. Hiện trạng mã và đường chuyển

Repo hiện chưa có mã nguồn PH-20 và không có `docs/07-srs/SRS-PH-20-*.md`: REQ-20 là năng lực mới nên không có dữ liệu cũ cần chuyển. Hai chức năng của hệ cũ mà PH-20 tham gia gián tiếp là `LGC-IAM-002` (tạo realm, client, vai trò: PH-12 làm chính, PH-20 khởi tạo tự động ở bước `S03_REALM`) và `LGC-BUS-031` (cấu hình hệ thống: PH-18 làm chính, PH-20 giữ cấu hình theo tenant ở Git). Tenant đầu tiên của nền tảng (`PLATFORM`, `COMMON`) và tỉnh thí điểm không đi qua saga mà do bản nạp dữ liệu nền của CSDL (`p_seed_platform`) tạo, rồi tỉnh thí điểm đầu tiên chạy saga trên môi trường `STAGING` làm nghiệm thu (tiêu chí chấp nhận 1 của FRS).

## 3. Cấu trúc mã nguồn

### 3.1. Kiến trúc mô-đun Modulith

Hai mô-đun theo khuôn `api / internal / events` của K-SDD. Mô-đun `tenant` giữ toàn bộ miền tenant (hồ sơ, saga, cấu hình, hạn mức, sử dụng, phân hệ, vòng đời, sáp nhập, tổ chức, liên tenant, kiểm thử rò rỉ, registry); mô-đun `release` giữ phiên bản sản phẩm, kênh, cửa sổ bảo trì và nâng cấp theo sóng. Lý do tách `release`: nó có chu kỳ thay đổi riêng (nhóm CI và vận hành), có đường vào riêng (CI đăng ký phiên bản) và chỉ cần đọc `tenant`, nên tách mô-đun giữ đồ thị phụ thuộc không chu trình. Mô-đun khác của `dh-platform` (PH-12 `iam`, PH-13 `observability`, `audit`, PH-16 `kpi`, PH-18 `settings`, `ops`) chỉ import `tenant.api`.

### 3.2. Cây package

Mỗi thành phần ở chương 4 là một gói con của `internal`. Chỉ `api` và `events` được mô-đun khác import. Hạ tầng dùng chung (outbox, inbox, kiểm toán, đọc tham số, bộ thích ứng gọi ra) nằm ở `vn.datahub.platform.shared`.

```text
vn.datahub.platform.tenant
  api/            # TenantRegistry, OrganizationQuery, ModuleStateQuery, TenantConfigApi,
                  # TenantSmokeApi, TenantStatusChanged (sự kiện ứng dụng), TenantListFilter (SPI)
  events/         # lược đồ EVT-20-01…13, 16 ghi qua outbox
  internal/
    profile/      # TenantService, ReadinessChecker, ContactService, ContractService, TenantTransitions (FR-001…007)
    provisioning/ # ProvisioningOrchestrator, ProvisioningWorker, StepWatchdog, RunCompensator,
                  # ProvisioningReportController, KpiLeadTimeReporter, TemplateService (FR-008…011, 014…017)
      step/       # StepExecutor, S01RecordStep … S17ActivateStep, StepRegistry
      smoke/      # SmokeTestRunner, SmokeCase (FR-012, 013)
    config/       # GitOpsConfigWriter, ConfigProjector, DriftDetector, ArgoStatusPoller, SettingsService (FR-018…022, 025)
    crosstenant/  # CrossTenantPolicyService (FR-023, 024)
    quota/        # QuotaService, QuotaCalculator, QuotaPublisher, OverrideExpiryJob (FR-026, 027, 032)
    usage/        # UsageCollector, UsageSource, ThresholdProbe, QuotaAlertEvaluator, UsageReportService (FR-028…031)
    modules/      # ModuleCatalog, ModuleToggleService, FeatureFlagService, ModuleWatchdog (FR-033…037)
    lifecycle/    # LifecycleService, ApprovalGuard, SuspendExecutor, TerminateExecutor, StatusNotifier (FR-038…044)
    export/       # DataExportService, ExportManifestBuilder (FR-041)
    merge/        # MergeCoordinator, MergePlanService, MappingService, ConflictService, MergeParticipantClient, CutoverService (FR-045…052)
    org/          # OrganizationService, OrgImportService, OrgSyncProposalService (FR-053…058)
    leaktest/     # LeakTestScheduler, LeakProbeCatalog (FR-070)
    registry/     # TenantRegistryApi, RegistryCache, EnforcementView, DashboardQuery (FR-065…067)
vn.datahub.platform.release
  api/            # RunningVersionQuery
  events/         # EVT-20-14, EVT-20-15
  internal/
    catalog/      # ReleaseService, ChannelService, ReleaseRegistrar (FR-059, 060)
    upgrade/      # UpgradeOrchestrator, WavePlanner, WaveGuard, UpgradeVerifier, RollbackService,
                  # MaintenanceWindowService, AnnouncementService (FR-061…064)
vn.datahub.platform.shared
  messaging/      # OutboxWriter, InboxGuard, IdempotencyFilter
  outbound/       # ExternalCallAdapter, IamClient, ObsClient, RdmClient, KpiClient, OpsClient,
                  # BaoClient, ObjectStoreClient, GitClient, ArgoClient, MimirClient, ClusterClient
  support/        # AuditWriter, TenantSession, TenantSettingReader, ParameterReader
```

### 3.3. Quy tắc phụ thuộc

Quy tắc kiểm bằng ArchUnit và `ApplicationModules.verify()` của Spring Modulith (CC-MOD-01…05 ở D04-01). Tám quy tắc đặc thù của PH-20:

1. `release` import `tenant::api` và không import `tenant::internal`; `tenant` không import `release` ở bất kỳ gói nào. Ba chiều ngược cần thiết đi bằng cơ chế không tạo phụ thuộc biên dịch: (a) sự kiện ứng dụng `TenantStatusChanged` đặt ở `tenant.api`, `release` lắng nghe bằng `@ApplicationModuleListener` để đặt nâng cấp của tenant tạm ngừng thành `SKIPPED`; (b) giao diện mở rộng `TenantListFilter` đặt ở `tenant.api`, `release` hiện thực để API-20-001 lọc được theo kênh phát hành mà `tenant` không biết bảng đăng ký kênh; (c) giao diện `ModuleAvailabilityCheck.isAvailable(tenant, module)` đặt ở `tenant.api`, `release` hiện thực, để `ModuleToggleService` biết phân hệ có trong phiên bản đang chạy mà không import `release`.
2. Chỉ `provisioning` ghi `provisioning_run`, `provisioning_step`, `smoke_test_result`; chỉ `quota` ghi `tenant_quota`, `quota_override`, `quota_change_request`; chỉ `usage` ghi `usage_snapshot`, `quota_alert`, `usage_report`; chỉ `config` ghi `tenant_config_version`, `config_drift`, `tenant_platform_config`, `tenant_settings`; chỉ `lifecycle` ghi `lifecycle_request` và `tenant_status_history`; chỉ `merge` ghi `merge_*`; chỉ `org` ghi `organization`, `org_import_*`; chỉ `modules` ghi `tenant_module`, `tenant_feature_flag`. Trạng thái `tenant.status` chỉ đổi qua `TenantTransitions` (gói `profile`). ArchUnit cấm `INSERT`, `UPDATE` vào các bảng đó ở gói khác.
3. Mọi lời gọi ra ngoài đi qua `shared.outbound.ExternalCallAdapter`; mã nghiệp vụ không tạo `RestClient`, `S3Client` hay `JGit` trực tiếp. ArchUnit cấm import các thư viện đó ngoài `shared.outbound`.
4. Chỉ `shared.messaging.OutboxWriter` ghi `outbox` và chỉ `shared.support.AuditWriter` gọi kiểm toán sang PH-13; gói nghiệp vụ gọi qua interface, ghi cùng giao dịch.
5. Chỉ `config.GitOpsConfigWriter` ghi vào kho `dh-tenant-config`. `quota`, `modules`, `upgrade` yêu cầu ghi qua `TenantConfigApi`, không tự commit.
6. `StepExecutor` không gọi `StepExecutor` khác và không đọc sổ bước của bước khác ngoài `StepContext.outputOf(stepCode)`; thứ tự và song song do `ProvisioningOrchestrator` quyết.
7. Gói `tenant.api` chỉ chứa interface, bản ghi DTO bất biến và sự kiện ứng dụng; không chứa thực thể JPA. Phân hệ khác trong `dh-platform` không đọc bảng `ph20_tenant` bằng SQL (D03-01 §7.3).
8. Mã nguồn PH-20 không đọc bảng của phân hệ khác; chỉ dùng sự kiện, API trong hợp đồng ở mục 2.4 và `*.api` công bố.

```{.mermaid caption="Đồ thị phụ thuộc mô-đun của PH-20 và các mô-đun cùng dh-platform"}
flowchart TB
  IAM["iam (PH-12)"] -->|"tenant.api"| TEN["tenant"]
  OBS["observability, audit (PH-13)"] -->|"tenant.api"| TEN
  KPI["kpi (PH-16)"] -->|"tenant.api"| TEN
  SET["settings, ops (PH-18)"] -->|"tenant.api"| TEN
  REL["release"] -->|"tenant.api"| TEN
  TEN -.->|"sự kiện ứng dụng TenantStatusChanged"| REL
  REL -.->|"hiện thực TenantListFilter"| TEN
  TEN -->|"shared"| SHR["platform.shared"]
  REL -->|"shared"| SHR
```

Hình cho thấy mọi mũi tên liền đi vào `tenant` hoặc xuống `shared`, nên `tenant` là lá của đồ thị phụ thuộc biên dịch. Hai mũi tên đứt giữa `tenant` và `release` không phải phụ thuộc biên dịch: một là sự kiện ứng dụng do `tenant` phát, một là bean do `release` đăng ký vào giao diện mở rộng của `tenant`.

### 3.4. Giao diện công bố

Gói `tenant.api` công bố cho mô-đun cùng DU: `TenantRegistry` (`get(code)`, `listActive()`, `statusOf(code)`; trả DTO bất biến `TenantView` gồm trạng thái, chế độ cách ly, realm, host, tiền tố API; có bộ đệm), `OrganizationQuery` (`byCode`, `lookup(codes)`, `tree(asOf)`; phục vụ PH-01, 06, 08, 16 cùng DU qua gọi trong tiến trình thay cho REST), `ModuleStateQuery` (`isEnabled(tenant, module)`, `states(tenant)`; menu và bộ lọc data plane), `TenantConfigApi` (`requestReleasePin(tenant, version, reason)`, `argoStatus(tenant)`), `TenantSmokeApi` (`runLite(tenant)` cho kiểm tra sau nâng cấp) và sự kiện ứng dụng `TenantStatusChanged`. Gói `release.api` công bố `RunningVersionQuery.versionOf(tenant)`. Phân hệ khác DU (PH-01, 03, 04, 07, 10 ở các DU khác) dùng REST `/internal/tenant/v1` có cùng nội dung.

### 3.5. Danh sách thành phần được đặc tả

Bảng liệt kê 19 thành phần của chương 4 (mục 4.2 đến 4.20), gói chứa và lớp chính; FR hiện thực nằm ở khối đặc tả từng mục và ma trận 13.3. Mục 4.1 là mô hình miền; 4.21 là các thuật toán.

| Mục | Thành phần | Mô-đun, gói | Lớp chính |
|---|---|---|---|
| 4.2 | TenantService · hồ sơ và kiểm tra sẵn sàng | `tenant.profile` | `TenantService`, `ReadinessChecker`, `ContactService`, `ContractService`, `TenantTransitions` |
| 4.3 | ProvisioningOrchestrator · saga (ADR 200) | `tenant.provisioning` | `ProvisioningOrchestrator`, `ProvisioningWorker`, `StepWatchdog`, `RunCompensator`, `ProvisioningReportController`, `KpiLeadTimeReporter` |
| 4.4 | StepExecutor · 17 bước `S01…S17` | `tenant.provisioning.step` | `StepExecutor`, `StepRegistry`, `S01RecordStep` … `S17ActivateStep` |
| 4.5 | SmokeTestRunner · kiểm tra khói | `tenant.provisioning.smoke` | `SmokeTestRunner`, `SmokeCase` |
| 4.6 | GitOpsConfigWriter và DriftDetector (ADR 201) | `tenant.config` | `GitOpsConfigWriter`, `ConfigProjector`, `ArgoStatusPoller`, `DriftDetector`, `SettingsService` |
| 4.7 | QuotaService và QuotaPublisher | `tenant.quota` | `QuotaService`, `QuotaCalculator`, `QuotaPublisher`, `OverrideExpiryJob` |
| 4.8 | UsageCollector (ADR 204) | `tenant.usage` | `UsageCollector`, `UsageSource`, `ThresholdProbe`, `QuotaAlertEvaluator`, `UsageReportService` |
| 4.9 | ModuleCatalog và ModuleToggleService | `tenant.modules` | `ModuleCatalog`, `ModuleToggleService`, `FeatureFlagService`, `ModuleWatchdog` |
| 4.10 | LifecycleService · tạm ngừng, khôi phục, chấm dứt | `tenant.lifecycle` | `LifecycleService`, `ApprovalGuard`, `SuspendExecutor`, `TerminateExecutor`, `StatusNotifier` |
| 4.11 | DataExportService · gói bàn giao | `tenant.export` | `DataExportService`, `ExportManifestBuilder` |
| 4.12 | MergeCoordinator (ADR 202) | `tenant.merge` | `MergeCoordinator`, `MergePlanService`, `MappingService`, `ConflictService`, `MergeParticipantClient`, `CutoverService` |
| 4.13 | OrganizationService và OrgImport | `tenant.org` | `OrganizationService`, `OrgImportService`, `OrgSyncProposalService` |
| 4.14 | ReleaseService · phiên bản và kênh (ADR 203) | `release.catalog` | `ReleaseService`, `ChannelService`, `ReleaseRegistrar` |
| 4.15 | UpgradeOrchestrator · sóng và cửa sổ bảo trì | `release.upgrade` | `UpgradeOrchestrator`, `WavePlanner`, `WaveGuard`, `UpgradeVerifier`, `RollbackService`, `MaintenanceWindowService` |
| 4.16 | TenantRegistryApi và bộ đệm | `tenant.registry` | `TenantRegistryApi`, `RegistryCache`, `EnforcementView`, `DashboardQuery` |
| 4.17 | CrossTenantPolicyService | `tenant.crosstenant` | `CrossTenantPolicyService` |
| 4.18 | LeakTestScheduler · kiểm thử rò rỉ chéo | `tenant.leaktest` | `LeakTestScheduler`, `LeakProbeCatalog` |
| 4.19 | Outbox, Inbox, Idempotency | `shared.messaging` | `OutboxWriter`, `InboxGuard`, `IdempotencyFilter` |
| 4.20 | Bộ thích ứng gọi ra ngoài | `shared.outbound` | `ExternalCallAdapter` và 11 client |

: Danh sách thành phần được đặc tả của PH-20

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền có mười một aggregate, mỗi aggregate có một lối ghi duy nhất (một thành phần sở hữu). `Tenant` (kèm đầu mối, hợp đồng, cấu hình nền tảng, cài đặt, hạn mức) là gốc; `ProvisioningRun` (kèm bước và kết quả kiểm tra khói) điều khiển vòng đời `PROVISIONING`; `LifecycleRequest` điều khiển các chuyển trạng thái có duyệt; `MergePlan`, `ExportPackage`, `Organization`, `ProductRelease` và `UpgradePlan` là các aggregate độc lập tham chiếu tenant bằng mã. Hình dưới là sơ đồ lớp rút gọn; bất biến nằm ở bảng liền sau.

```{.mermaid caption="Sơ đồ lớp rút gọn của mô hình miền PH-20"}
classDiagram
  Tenant "1" --> "*" TenantContact
  Tenant "1" --> "*" TenantContract
  Tenant "1" --> "1" PlatformConfig
  Tenant "1" --> "1" TenantSettings
  Tenant "1" --> "*" TenantQuota
  Tenant "1" --> "*" TenantModule
  Tenant "1" --> "*" StatusHistory
  Tenant "1" --> "*" ProvisioningRun
  ProvisioningRun "1" --> "17" ProvisioningStep
  ProvisioningRun "1" --> "*" SmokeResult
  ProvisioningRun ..> ProvisioningTemplate : ghim phiên bản mẫu
  Tenant "1" --> "*" LifecycleRequest
  LifecycleRequest "1" --> "0..1" ExportPackage
  ExportPackage "1" --> "*" ExportItem
  TenantQuota "1" --> "*" QuotaOverride
  TenantQuota "1" --> "*" UsageSnapshot
  UsageSnapshot ..> QuotaAlert : vượt ngưỡng
  MergePlan "1" --> "*" MergeMapping
  MergePlan "1" --> "*" ParticipantRun
  MergePlan "1" --> "*" MergeConflict
  MergePlan ..> Tenant : nguồn và đích
  Organization "0..1" --> "*" Organization : cấp dưới
  ProductRelease "1" --> "*" ReleaseComponent
  UpgradePlan "1" --> "*" UpgradeWave
  UpgradeWave "1" --> "*" TenantUpgrade
  UpgradePlan ..> ProductRelease : nâng lên
  TenantUpgrade ..> Tenant : áp cho
```

Hình cho thấy ba điều. `ProvisioningRun` ghim phiên bản mẫu khởi tạo nên đổi mẫu không làm đổi lần chạy đã bắt đầu (BR-20-042). `LifecycleRequest` và `ExportPackage` tách nhau để gói bàn giao dùng lại được cho nhiều đề nghị. Các aggregate nền tảng (`MergePlan`, `UpgradePlan`, `ProductRelease`, `ProvisioningTemplate`) tham chiếu tenant bằng mã chứ không nằm dưới `Tenant`, vì vòng đời của chúng dài hơn hoặc rộng hơn một tenant.

| Aggregate | Bất biến chính | Chỗ bảo đảm |
|---|---|---|
| `Tenant` | Mã `^T\d{2}$` hoặc `PLATFORM`, `COMMON`; mã và realm bất biến và không tái cấp (BR-20-001); một ĐVHC cấp tỉnh chỉ một tenant chưa ở trạng thái cuối (BR-20-002); `PLATFORM`, `COMMON` luôn `ACTIVE`, `SHARED`, không tạm ngừng, chấm dứt, sáp nhập (BR-20-003) | `TenantService`, `TenantTransitions`; `uq_tenant_admin_unit_active`, `ck_tenant_special`, `tg_tenant_transition`, `tg_tenant_no_delete` |
| `ProvisioningRun` | Mỗi tenant tối đa một lần chạy chưa kết thúc (BR-20-006); mỗi bước có khóa lũy đẳng `{runId}:{stepCode}` (BR-20-005); `S16`, `S17` không bỏ qua được; `ACTIVE` chỉ khi `S16` đạt (BR-20-004) | `ProvisioningOrchestrator`; `uq_provisioning_run_active`, `ck_provisioning_step_idem`, `tg_transition` |
| `LifecycleRequest` | Chấm dứt cần tenant `SUSPENDED`, gói `DELIVERED`, hết thời gian nguội, hai PA khác nhau (BR-20-008, 019); tạm ngừng, khôi phục không cần duyệt (BR-20-021); mỗi (tenant, loại) một đề nghị mở | `LifecycleService`, `ApprovalGuard`; `ck_lifecycle_request_four_eyes`, `uq_lifecycle_request_open` |
| `TenantQuota`, `QuotaOverride` | Hạn mức hiệu lực không vượt trần nền tảng (BR-20-013); ghi đè ≤ `20.quota.override-max-days` ngày (BR-20-015); hạ cần duyệt, không cắt tài nguyên đã cấp (BR-20-014) | `QuotaCalculator`, `QuotaService`; `uq_tenant_quota_resource`, `ck_quota_override_four_eyes` |
| `UsageSnapshot`, `QuotaAlert` | Một ảnh chụp cho (tenant, tài nguyên, giờ); mỗi (tenant, tài nguyên, mức) một cảnh báo mở, khử lặp (BR-20-016) | `UsageCollector`, `QuotaAlertEvaluator`; `uq_usage_snapshot_point`, `uq_quota_alert_open` |
| `TenantModule` | Phân hệ lõi PH-03, 10, 12, 13, 18, 20 không tắt; bật cần phụ thuộc `REQUIRED` đã bật; tắt không xóa dữ liệu (BR-20-017, 018) | `ModuleToggleService`; `uq_tenant_module_module` |
| `MergePlan` | Nguồn và đích `ACTIVE`, `PROVINCE`; mỗi tenant nguồn một kế hoạch mở; xung đột không tự ghi đè (BR-20-023); cutover cần mọi phân hệ `SUCCEEDED`, không xung đột mở, định danh đã chuyển (BR-20-024) | `MergeCoordinator`, `CutoverService`; `uq_merge_plan_open_source`, `ck_merge_plan_four_eyes` |
| `Organization` | Mã duy nhất trong tenant; cây không chu trình; giải thể còn tham chiếu phải có tổ chức kế thừa; không xóa cứng (BR-20-027) | `OrganizationService`; `tg_organization_cycle`, `ck_organization_closed`, `ck_organization_merged` |
| `ProductRelease` | SemVer; bất biến từ `PREVIEW`; `STABLE` sau ≥ 14 ngày `PREVIEW` không sự cố mức 1 (BR-20-030, 031); mọi ảnh có chữ ký cosign | `ReleaseService`; `tg_product_release_transition`, `ck_product_release_stable` |
| `UpgradePlan` | Mỗi tenant một kế hoạch mở; nâng cấp trong cửa sổ bảo trì; sóng dừng khi lỗi vượt ngưỡng (BR-20-032, 033) | `UpgradeOrchestrator`, `WaveGuard` |
| `ExportPackage` | Gói có `manifest.json` ký, băm SHA-256 từng tệp; người xác nhận bàn giao khác người duyệt chấm dứt (BR-20-008) | `DataExportService`; `sha256` ở `data_export_package` |

: Aggregate và bất biến của PH-20

### 4.2. Hồ sơ tenant và kiểm tra sẵn sàng (`profile`)

::: dac-ta
**Mục đích.** Giữ hồ sơ tenant (mã, tên, ĐVHC, chế độ cách ly, quy mô, đầu mối, hợp đồng), kiểm tra tenant có đủ điều kiện khởi tạo trước khi chạy saga, bảo vệ hai tenant đặc biệt và là nơi duy nhất đổi trạng thái tenant.

**Lớp chính.** `TenantService`, `ReadinessChecker`, `ContactService`, `ContractService`, `TenantTransitions`, `TenantGuard`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-20-001…007; BR-20-001, 002, 003, 009.

**Giao diện vào.** API-20-001…012 (liệt kê, khai báo, chi tiết, sửa hồ sơ, kiểm tra sẵn sàng, đầu mối, hợp đồng); quyền `PERM-20-provision`, `PERM-20-admin`, `PERM-20-read`.

**Phụ thuộc ra.** PH-07 (đọc ĐVHC `COMMON`, bộ đệm 24 giờ), Kubernetes API (sức chứa cụm, chỉ đọc), Valkey (bộ đệm registry), `outbox`.

**Dữ liệu.** `tenant`, `tenant_contact`, `tenant_contract`, `provisioning_template` (đọc), `file_object` (tệp hợp đồng), `tenant_status_history`.

**Sự kiện.** EVT-20-04 mỗi lần đổi trạng thái (do `TenantTransitions` phát); EVT-20-09 khi sửa hồ sơ ảnh hưởng cấu hình.

**Lỗi và xử lý.** ERR-20-002, 003, 004, 005, 010, 011, 012, 013, 014, 015, 017, 021, 022, 067, 068.

**Quan sát.** `dh_tenant_total{status,isolation}`, `dh_tenant_readiness_blockers_total{code}`, `dh_tenant_transition_total{from,to}`.
:::

Chi tiết thiết kế:

Khai báo tenant (API-20-002) là một giao dịch: kiểm trùng mã (kể cả tenant `DECOMMISSIONED`, `MERGED`, vì mã không tái cấp, ERR-20-003), kiểm ĐVHC cấp tỉnh có trong danh mục `COMMON` còn hiệu lực (ERR-20-012) và chưa có tenant hoạt động (ERR-20-011, chỉ mục duy nhất từng phần là lớp bảo vệ thứ hai), rồi chèn dòng `tenant` ở `PROVISIONING` với `declared_at`, cùng `tenant_platform_config` và `tenant_settings` mặc định, ghi kiểm toán. Dòng `tenant` phải có từ lúc khai báo vì lần chạy saga tham chiếu nó bằng khóa ngoại; việc "ghi bản ghi" của bước `S01_RECORD` do đó là hoàn tất khởi tạo hồ sơ (hạn mức từ mẫu qua `p_init_tenant_quota`, dòng `tenant_module` theo mẫu, mốc lịch sử trạng thái) và lũy đẳng theo mã tenant.

`ReadinessChecker` chạy bảy kiểm tra, mỗi kiểm tra trả `BLOCKER` hoặc `WARN` kèm mã và lời nhắc. Mã trùng và ĐVHC đã có tenant là `BLOCKER`; sức chứa nền tảng là `BLOCKER` khi số tenant chưa ở trạng thái cuối cộng một vượt 40 (con số thiết kế của NFR-20-005, ERR-20-013) và `WARN` từ tenant thứ 34; tài nguyên cụm so yêu cầu của hồ sơ quy mô `QM-*` với phần còn trống đọc từ API Kubernetes và cảnh báo công suất EVT-13-14 gần nhất (ERR-20-014); mẫu khởi tạo phải `ACTIVE` và mọi phân hệ trong mẫu có trong phiên bản đang chạy (ERR-20-015); `DEDICATED_CLUSTER` đòi `20.dedicated-cluster.enabled` (BR-20-035); đầu mối bắt buộc (ERR-20-021) là kiểm tra kích hoạt, không chặn khởi tạo. Có `BLOCKER` thì `POST provisioning-runs` trả ERR-20-017.

`TenantTransitions` là cửa duy nhất đổi `tenant.status`. Mỗi chuyển là `UPDATE tenant SET status = :to WHERE code = :code AND status = :from` kèm số dòng trả về; 0 dòng nghĩa là trạng thái đã đổi (ERR-20-006). Cùng giao dịch ghi `tenant_status_history` (chỉ thêm), ghi outbox EVT-20-04 và phát sự kiện ứng dụng `TenantStatusChanged`; sau commit, bộ đệm registry được vô hiệu (mục 4.16). Trigger `tg_tenant_transition` là lớp bảo vệ thứ hai. `TenantGuard.assertNotSpecial` chặn tạm ngừng, chấm dứt, sáp nhập, đổi cách ly và tắt phân hệ với `PLATFORM`, `COMMON` (ERR-20-010).

### 4.3. Điều phối saga khởi tạo (`ProvisioningOrchestrator`, ADR 200)

::: dac-ta
**Mục đích.** Chạy 17 bước khởi tạo tenant tuần tự và song song theo đồ thị phụ thuộc, bảo đảm mỗi bước lũy đẳng, có thể thử lại từ bước lỗi, bù trừ ngược khi hủy, và không để tenant sang `ACTIVE` khi chưa qua kiểm tra khói.

**Lớp chính.** `ProvisioningOrchestrator`, `ProvisioningWorker`, `StepWatchdog`, `RunCompensator`, `ProvisioningReportController`, `KpiLeadTimeReporter`, `TemplateService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (bộ chạy, bộ canh hết hạn); hồ sơ `api` (API chạy, thử lại, báo tiến độ, SSE).

**FR hiện thực.** FR-20-008…011, 014…016; BR-20-004…007, 041, 042.

**Giao diện vào.** API-20-013…024, 033, 034 (chạy, theo dõi, thử lại, bỏ qua, bù trừ, hủy, kích hoạt, số đo); API-20-166 (phân hệ báo tiến độ); `PERM-20-provision`, scope `tenant:provision-report`.

**Phụ thuộc ra.** Mọi bên thực hiện bước qua `ExternalCallAdapter` (mục 4.4), `GitOpsConfigWriter`, `KpiClient`, `OpsClient` (thông báo), Valkey (kênh SSE).

**Dữ liệu.** `provisioning_run`, `provisioning_step`, `provisioning_template`, `smoke_test_result`, `tenant`, `outbox`, `shedlock` (bảng của hạ tầng dùng chung).

**Sự kiện.** EVT-20-01 sau `S05`; EVT-20-02 khi `FAILED`; EVT-20-03 ở `S17`; EVT-20-04 khi tenant đổi trạng thái; nhận báo cáo từ các phân hệ qua API-20-166.

**Lỗi và xử lý.** ERR-20-006, 009, 016, 017, 018, 019, 020, 062, 104, 105, 106, 107, 108, 117.

**Quan sát.** `dh_tenant_provision_duration_seconds{step}`, `dh_tenant_provision_runs_total{kind,status}`, `dh_tenant_provision_step_attempts_total{step,result}`, `dh_tenant_provision_waiting_steps`.
:::

Chi tiết thiết kế:

**Đồ thị bước.** Thứ tự và phụ thuộc là hằng của `SagaPlan` (cùng phiên bản với mã, không đọc từ cấu hình để tránh một mẫu làm đổi thứ tự): `S01` đến `S05` tuần tự; sau `S05` là điểm rẽ nhánh gồm bốn bước bất đồng bộ `S06`, `S09`, `S10`, `S12` bắt đầu cùng lúc, và hai bước đồng bộ `S07`, `S08` chạy trên hai luồng của bộ chạy; điểm hội tụ B1 chờ cả sáu bước xong hoặc `SKIPPED`; sau đó `S11`, `S13`, `S14` tuần tự, rồi `S15` (bất đồng bộ nhiều phân hệ), rồi `S16`, `S17`. `step_order` bằng số trong mã bước. Bước không áp dụng được đánh `SKIPPED` ngay lúc tạo lần chạy: `S07` khi `SHARED`; `S12` khi PH-06 không bật theo mẫu; `S14` khi PH-16 không bật.

**Vòng chạy.** `ProvisioningWorker` quét mỗi 5 giây các lần chạy `PENDING`, `RUNNING`, `WAITING` (tối đa vài chục dòng), và cũng được đánh thức ngay khi nhận báo cáo hay sau commit của một bước. Với mỗi lần chạy, worker giành khóa ShedLock `provision:{tenantCode}` (`lockAtMostFor` 10 phút, gia hạn nền mỗi 30 giây nên bước dài không mất khóa, nhưng worker chết thì khóa nhả sau tối đa 10 phút), đọc trạng thái từ CSDL (không tin bộ nhớ), tính các bước chạy được từ đồ thị và trạng thái, rồi chạy. Mỗi bước theo ba pha ngắn: (1) giao dịch đặt bước `RUNNING`, `attempt + 1`, `started_at`, `timeout_at` và commit trước khi gọi ngoài, để mọi dấu vết nằm ở sổ bước; (2) gọi bên thực hiện ngoài giao dịch với `Idempotency-Key = {runId}:{stepCode}`; (3) giao dịch ghi kết quả (`SUCCEEDED` kèm `detail` là tham chiếu đầu ra, hoặc `WAITING_REPORT`, hoặc lỗi). Vì pha (2) lũy đẳng, worker chết giữa chừng chỉ làm bước bị chạy lại cùng khóa. `StepWatchdog` mỗi 30 giây tìm bước `RUNNING` quá `timeout_at` (kết quả không rõ) và đưa về `PENDING` để chạy lại cùng khóa, và tìm bước `WAITING_REPORT` quá hạn để đặt `FAILED` với ERR-20-106.

**Thử lại.** Lỗi được phân loại ở `ExternalCallAdapter`: tạm thời (hết giờ, `5xx`, ngắt mạch mở, ERR-20-062) hay vĩnh viễn (`4xx` do dữ liệu). Lỗi tạm thời tự thử lại tối đa `20.provision.step-retry-max` (3) lần với giãn cách 10, 30, 90 giây; lỗi vĩnh viễn thì bước `FAILED` ngay. Hết lần thử, bước `FAILED`, lần chạy `FAILED`, tenant `PROVISIONING → FAILED` và phát EVT-20-02, gửi thông báo cho PA qua `OpsClient`. Tổng thời gian vượt `20.provision.timeout-minutes` (60) tính từ `started_at` của lần thử hiện tại thì lần chạy `FAILED` với ERR-20-108. Thử lại thủ công (API-20-017, 018) chỉ khi lần chạy `FAILED` và tenant `FAILED` (ERR-20-018): đặt `started_at` mới, cộng dồn thời lượng vào `duration_seconds`, đưa tenant về `PROVISIONING` và chạy từ bước lỗi đầu tiên; bước `SUCCEEDED` không chạy lại. KPI-12 không dùng các cột này mà tính từ `declared_at` đến `activated_at` của tenant (BR-20-041).

**Bù trừ.** `RunCompensator` chạy khi PA gọi API-20-020 hoặc API-20-021: lần chạy `FAILED → COMPENSATING`; các bước `SUCCEEDED` và `FAILED` có tác động dở được bù theo thứ tự ngược `step_order`, mỗi bước gọi `compensate` của executor với cùng khóa lũy đẳng cộng hậu tố `:undo`. Với bước bất đồng bộ, bù trừ là một lần phát EVT-20-04 (đích `DECOMMISSIONED`) để PH-10, PH-03, PH-04 gỡ phần của mình, và `S15` bù bằng EVT-20-08 cho từng phân hệ đã bật. Bù xong thì `COMPENSATED`, với lần chạy `INITIAL` thì tiếp `CANCELLED` và tenant `FAILED → DECOMMISSIONED`; với `SUPPLEMENT`, `ISOLATION_CHANGE` thì tenant vẫn `ACTIVE`. Bù trừ lỗi (ví dụ bucket chưa rỗng) làm lần chạy quay về `FAILED` và trả ERR-20-019 cho yêu cầu; PA xử lý tay rồi gọi lại.

**Báo tiến độ.** `ProvisioningReportController` xử lý API-20-166: kiểm scope (ERR-20-104), kiểm người gọi khớp bên thực hiện của bước (`S06` là PH-10, `S09` là PH-03, `S10` là PH-04, `S12` là PH-06, `S15` là phân hệ nêu trong thân), kiểm bước đang `WAITING_REPORT` (ERR-20-105), ghi `reported_at`, đặt `SUCCEEDED`, `FAILED` hoặc `SKIPPED`, lũy đẳng theo `reportId`; báo trùng cùng trạng thái trả `200` không đổi gì. Khi bước cuối của điểm hội tụ xong, controller đánh thức worker. Báo `FAILED` có ERR-20-107 mang mã lỗi của phân hệ.

**Đo KPI-12.** Sau `S17`, `KpiLeadTimeReporter` đẩy chỉ tiêu `thoi-gian-khoi-tao-tenant` qua API-16-030 (`kpi.ingest`); giá trị là số giờ làm việc giữa `declared_at` và `activated_at` theo lịch ngày làm việc do PH-18 quản (Q20-19). Đẩy lỗi không làm hỏng saga; `kpi_reported_at` còn rỗng thì tác vụ hằng giờ thử lại, khóa lũy đẳng theo `tenantCode`.

### 4.4. Bộ thực thi bước (`StepExecutor`, 17 bước)

::: dac-ta
**Mục đích.** Mỗi bước saga là một lớp `StepExecutor` nhỏ, cùng một giao diện: biết mình áp dụng khi nào, thực hiện thế nào, bù trừ thế nào và báo kết quả ra sao, để `ProvisioningOrchestrator` không chứa logic hạ tầng.

**Lớp chính.** `StepExecutor` (`code()`, `mode()`, `applicable(RunContext)`, `execute(StepContext)`, `compensate(StepContext)`), `StepRegistry`, `StepContext`, `S01RecordStep` … `S17ActivateStep`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker`.

**FR hiện thực.** FR-20-008 (toàn bộ), FR-20-013 (`S17`), FR-20-014 (`S17`), FR-20-016 (chạy bổ sung); BR-20-005, 007.

**Giao diện vào.** Không có đường vào ngoài; do `ProvisioningOrchestrator` gọi. Bước bất đồng bộ nhận báo cáo qua API-20-166.

**Phụ thuộc ra.** PH-12 (`IamClient`, API-12-080, 084, 085), PH-13 (`ObsClient`, API-13-072, 073), PH-07 (`RdmClient`, API-07-073), PH-16 (`KpiClient`, FR-16-008), OpenBao (`BaoClient`), Ceph RGW (`ObjectStoreClient`), Git (`GitOpsConfigWriter`), cụm Kubernetes (`ClusterClient`), `OrganizationService`, `ModuleToggleService`.

**Dữ liệu.** `provisioning_step` (`detail` giữ tham chiếu đầu ra, không giữ bí mật), `tenant`, `tenant_module`, `organization`.

**Sự kiện.** EVT-20-01 (do bước điểm rẽ sau `S05`), EVT-20-07 và EVT-20-08 (`S15`), EVT-20-03 (`S17`).

**Lỗi và xử lý.** ERR-20-062 (hạ tầng không sẵn sàng), 106, 107; lỗi riêng của bên thực hiện được bọc thành ERR-20-107 kèm mã gốc (ví dụ ERR-12-041, ERR-13-014).

**Quan sát.** `dh_tenant_provision_step_duration_seconds{step,result}`, `dh_tenant_provision_step_compensations_total{step,result}`.
:::

Chi tiết thiết kế:

Bảng dưới là hợp đồng của 17 executor: ai thực hiện, gọi bằng gì, cách bảo đảm lũy đẳng, thao tác bù và thời gian chờ tối đa của bước (mặc định `20.provision.step-timeout-minutes` = 15 phút; số khác ghi rõ). Thời gian chờ của bước đồng bộ là thời gian chờ của lời gọi; của bước bất đồng bộ là thời gian chờ báo.

| Bước | Chế độ | Cách gọi (qua adapter) | Cách lũy đẳng | Bù trừ | Chờ tối đa |
|---|---|---|---|---|---|
| `S01_RECORD` | Đồng bộ | Nội bộ: `p_init_tenant_quota`, dòng cấu hình, `tenant_module` theo mẫu | Upsert theo (tenant, tài nguyên) và (tenant, phân hệ) | Xóa hạn mức, cấu hình, phân hệ mặc định; giữ dòng `tenant` (mã không tái cấp) | 30 giây |
| `S02_CONFIG_REPO` | Đồng bộ | `GitOpsConfigWriter`: tạo `tenants/{ma}/` gồm `tenant.yaml`, `settings.yaml`, `quota.yaml`, `modules.yaml`, `release.yaml`; chế độ `DEDICATED_DB` thêm khối `database` (tên cụm, bản CloudNativePG, kích thước, không chứa bí mật) vào `tenant.yaml` thay vì thêm tệp riêng, nên `ConfigScope` vẫn năm giá trị | Tìm commit có trailer `Dh-Idempotency: {runId}:S02` trước khi commit | Revert commit bằng commit mới có ký | 2 phút |
| `S03_REALM` | Đồng bộ | `IamClient` POST API-12-080, `Idempotency-Key` | PH-12 tiếp tục từ bước dở của `realm_provision_step` | Xóa realm còn `PROVISIONING` | 10 phút |
| `S04_SECRETS` | Đồng bộ | `BaoClient`: đường dẫn `kv/dh/{ma}/...`, chính sách theo đường dẫn, khóa transit `dh-{ma}-pii` (SEC-88) | Kiểm tồn tại rồi tạo; tên xác định theo mã tenant | Xóa đường dẫn, chính sách, KEK chưa dùng (KEK đã dùng thì chỉ chặn xóa) | 1 phút |
| `S05_BUCKETS` | Đồng bộ | `ObjectStoreClient`: `dh-{ma}-files`, `-exports`, `-backup`, `-audit`; khóa SSE riêng, hạn mức bucket | Tên bucket xác định; tạo nếu chưa có | Xóa bucket rỗng; bucket có dữ liệu thì ERR-20-019 | 2 phút |
| `S06_EVENTING` | Bất đồng bộ | EVT-20-01; PH-10 báo API-20-166 | `eventId` cố định theo lần chạy; PH-10 inbox khử trùng (FR-10-064, 067) | EVT-20-04 `DECOMMISSIONED` | 15 phút |
| `S07_DATABASE` | Đồng bộ (chỉ `DEDICATED_DB`) | `GitOpsConfigWriter` commit manifest cụm CloudNativePG; `ClusterClient` đọc trạng thái `Ready`; Job migration | Tên cụm xác định theo tenant; Argo CD áp lại không đổi | Gỡ manifest, xóa cụm | 30 phút (giả định) |
| `S08_OBSERVABILITY` | Đồng bộ | `ObsClient` POST API-13-072 | PH-13 ghi sổ bước S1…S6, gọi lại tiếp tục từ chỗ dở | `ObsClient` POST API-13-073 đóng chuỗi kiểm toán | 10 phút |
| `S09_GATEWAY` | Bất đồng bộ | EVT-20-01 và EVT-20-05; PH-03 đọc API-20-164 | PH-03 áp theo phiên bản cấu hình của tenant | PH-03 gỡ khi nhận EVT-20-04 | 15 phút |
| `S10_INTEGRATION` | Bất đồng bộ | EVT-20-01; PH-04 tạo `DEFAULT`, `dh-flows-{ma}`, ApplicationSet | PH-04 kiểm tồn tại | PH-04 gỡ khi nhận EVT-20-04 | 15 phút |
| `S11_SEED_RDM` | Đồng bộ | `RdmClient` POST API-07-073 | PH-07 nạp từng danh mục một giao dịch, gọi lại tiếp tục | PH-07 xóa danh mục nền | 10 phút |
| `S12_SEED_MDM` | Bất đồng bộ (nếu PH-06 bật) | EVT-20-01; PH-06 báo | PH-06 khử trùng bằng inbox | Không | 15 phút |
| `S13_ORG_SEED` | Đồng bộ | `OrganizationService.seed`: UBND tỉnh, các sở theo mẫu từ ĐVHC `COMMON` | Upsert theo mã tổ chức | Đánh `DISSOLVED` các tổ chức gieo (không xóa cứng) | 1 phút |
| `S14_KPI` | Đồng bộ (nếu PH-16 bật) | `KpiClient` gọi FR-16-008 kế thừa bộ chỉ tiêu mẫu | PH-16 kiểm đã kế thừa | Không | 2 phút |
| `S15_MODULES` | Bất đồng bộ | `ModuleToggleService.enableForSaga`: EVT-20-07 từng phân hệ không lõi theo mẫu; phân hệ lõi đặt `ENABLED` ngay | Sự kiện mang `eventId` theo (lần chạy, phân hệ); `tenant_module` đổi trạng thái có điều kiện | EVT-20-08 cho từng phân hệ đã bật | 15 phút mỗi phân hệ |
| `S16_SMOKE` | Đồng bộ | `SmokeTestRunner` (mục 4.5) | Ca ghi theo (lần chạy, ca); chạy lại ghi bản mới | Không | 5 phút |
| `S17_ACTIVATE` | Đồng bộ | `TenantTransitions` `PROVISIONING → ACTIVE`, EVT-20-03, thông báo đầu mối (PH-18), `KpiLeadTimeReporter` | Chuyển có điều kiện theo trạng thái | Không | 30 giây |

: Hợp đồng của 17 bước saga

Ba chi tiết cần nhấn mạnh. Thứ nhất, `S02` chạy trước mọi bước khác sau hồ sơ vì Argo CD cần thư mục tenant để dựng `ApplicationSet` của tenant; `S04`, `S05` ghi tham chiếu tới `tenant.yaml` chứ không ghi bí mật. Thứ hai, EVT-20-01 chỉ phát một lần sau `S05` bởi "bước điểm rẽ", không phải bởi `S06`: bước điểm rẽ ghi outbox một sự kiện và đặt cùng giao dịch `S06`, `S09`, `S10`, `S12` sang `WAITING_REPORT` (hoặc `SKIPPED`) với `timeout_at = now + 15 phút`. Thứ ba, `S15` cho nhiều phân hệ nên bước giữ `detail.modules[]` là danh sách (phân hệ, trạng thái, hạn); bước chỉ `SUCCEEDED` khi mọi phân hệ đã `ENABLED`, và một phân hệ báo `SKIPPED` (ví dụ PH-17 mặc định tắt) không chặn.

### 4.5. Kiểm tra khói (`SmokeTestRunner`)

::: dac-ta
**Mục đích.** Chứng minh tenant mới thực sự phục vụ được trước khi sang `ACTIVE`: đăng nhập được, gọi API được, phát nhận sự kiện được và không rò rỉ sang tenant khác. Đây là cửa bắt buộc của BR-20-004.

**Lớp chính.** `SmokeTestRunner`, `SmokeCase` (`LoginAdminCase`, `ApiSampleCase`, `EventSampleCase`, `CrossTenantLeakCase`), `SmokeFixture`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker`.

**FR hiện thực.** FR-20-012, 013; BR-20-004, 038.

**Giao diện vào.** API-20-022 (chạy lại); do `S16_SMOKE` và `UpgradeVerifier` gọi qua `TenantSmokeApi`; `PERM-20-provision`.

**Phụ thuộc ra.** PH-12 (tài khoản máy tạm `smoke-{runId}`, hạn 30 phút), APISIX (gọi qua host của tenant), Kafka (topic `{ma}.platform.smoke.v1`), tenant kiểm thử `T99` (tài nguyên mồi).

**Dữ liệu.** `smoke_test_result` (chỉ thêm), `provisioning_step`.

**Sự kiện.** Không; ca rò rỉ thất bại mở sự cố mức 1 ở PH-13 và phát EVT-20-02.

**Lỗi và xử lý.** ERR-20-020 (chưa đạt khi kích hoạt), ERR-20-111 (rò rỉ), ERR-20-117 (ca lỗi), ERR-20-062.

**Quan sát.** `dh_tenant_smoke_case_total{case,result}`, `dh_tenant_smoke_duration_seconds`.
:::

Chi tiết thiết kế:

Bốn ca chạy tuần tự và cô lập: mỗi ca có thời gian chờ riêng, một ca lỗi không chặn ca sau nhưng làm bước `FAILED`. Giá trị cột `check_code` theo DDL: `LOGIN_ADMIN` (lấy token của quản trị tỉnh đầu tiên bằng luồng kiểm thử, kiểm claim `tenant` đúng mã, 20 giây), `API_SAMPLE` (gọi `GET /api/tenant/v1/context` qua APISIX bằng host của tenant, kỳ vọng `200`, 10 giây), `EVENT_SAMPLE` (phát một sự kiện lên `{ma}.platform.smoke.v1` và đọc lại bằng nhóm consumer tạm, 30 giây), `CROSS_TENANT_LEAK` (dùng token của tenant mới đọc tài nguyên mồi cài sẵn ở `T99`, kỳ vọng `404` đúng như SEC-87, 10 giây). Tổng ≤ 3 phút ở điều kiện bình thường. Tài khoản máy tạm và HTTT giả lập luôn được dọn trong khối `finally`, kể cả khi ca lỗi.

Ca `CROSS_TENANT_LEAK` trả khác `404` là sự kiện nghiêm trọng: `ERR-20-111`, mở sự cố mức 1 ở PH-13, chặn kích hoạt và phát EVT-20-02 chứ không chỉ đánh dấu bước lỗi. Cờ `20.smoke.enabled = false` chỉ có hiệu lực với tenant kiểm thử `T90…T98` (bước `SKIPPED` kèm cảnh báo); `TenantService` từ chối tắt khi nền tảng có tenant tỉnh thật (BR-20-004). Chế độ rút gọn `runLite` chỉ chạy `LOGIN_ADMIN` và `API_SAMPLE` cho kiểm tra sau nâng cấp (mục 4.15). Kết quả mỗi ca chèn một dòng `smoke_test_result`; trigger chặn sửa và xóa nên kết quả là bằng chứng nghiệm thu. Kích hoạt tay (API-20-023) chỉ chạy khi lần chạy `SUCCEEDED` nhưng tenant còn `PROVISIONING` (trường hợp sau sự cố), và kiểm lại lần kiểm tra khói gần nhất còn trong 24 giờ (ERR-20-020).

### 4.6. Ghi cấu hình GitOps và phát hiện lệch (`GitOpsConfigWriter`, `DriftDetector`, ADR 201)

::: dac-ta
**Mục đích.** Làm cho Git `dh-tenant-config` là trạng thái mong muốn của từng tenant: mọi thay đổi cấu hình, hạn mức, phân hệ, phiên bản được sinh thành tệp YAML, commit có ký, Argo CD áp; CSDL giữ bản chiếu, lịch sử phiên bản; bộ phát hiện lệch báo khi ba nơi không khớp.

**Lớp chính.** `GitOpsConfigWriter`, `ConfigRenderer`, `ConfigProjector`, `ArgoStatusPoller`, `DriftDetector`, `SettingsService`, `ConfigRestoreService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (sửa cài đặt, khôi phục); hồ sơ `worker` (ghi, theo dõi Argo CD, phát hiện lệch).

**FR hiện thực.** FR-20-018…022, 025; BR-20-010, 011, 040.

**Giao diện vào.** API-20-039…046, 135, 136, 160 (cấu hình nền tảng, phiên bản, lệch, cài đặt tỉnh); `TenantConfigApi`; `PERM-20-admin`, `PERM-20-settings`.

**Phụ thuộc ra.** Git (`GitClient` dùng JGit, khóa ký lấy từ OpenBao transit), Argo CD (`ArgoClient`, chỉ đọc), OpenBao.

**Dữ liệu.** `tenant_platform_config`, `tenant_settings`, `tenant_config_version`, `config_drift`.

**Sự kiện.** EVT-20-09 sau khi `APPLIED` (kèm `configVersionNo`, `commitSha`).

**Lỗi và xử lý.** ERR-20-004, 005, 023, 024, 025, 026, 028, 067, 068, 109.

**Quan sát.** `dh_tenant_config_apply_seconds`, `dh_tenant_config_versions_total{scope,source}`, `dh_tenant_config_drift{status}`, `dh_tenant_git_push_retries_total`.
:::

Chi tiết thiết kế:

**Đường ghi một chiều.** Dịch vụ nghiệp vụ (cài đặt tỉnh, cấu hình nền tảng, hạn mức, phân hệ, cờ tính năng, ghim phiên bản) lưu thay đổi vào CSDL trong giao dịch của nó rồi gọi `GitOpsConfigWriter.write(tenant, scope, reason, ticket)`. Writer chạy dưới ShedLock `config:{tenantCode}` để mỗi tenant có tối đa một commit đang bay, sinh lại tệp từ CSDL bằng `ConfigRenderer` (khóa sắp xếp, định dạng chuẩn để so băm ổn định), kiểm lược đồ JSON Schema của từng tệp (sai lược đồ là lỗi lập trình, ERR-20-004), tính `content_hash`, bỏ qua nếu băm bằng nội dung đầu nhánh. Nếu có thay đổi thì giao dịch ngắn chèn `tenant_config_version` với `apply_status = PENDING` và `version_no` kế tiếp; commit lên nhánh chính tại `tenants/{ma}/` với thông điệp `ph20({ma}): {loại} [{phiếu}]`, trailer `Dh-Idempotency`, `Dh-Version-No`, `Dh-Reason`, ký bằng khóa của tài khoản dịch vụ `svc-ph20-gitops` (khóa riêng không rời OpenBao: chữ ký tạo qua API transit); cập nhật `git_commit_sha`.

**Xung đột đẩy.** Đẩy bị từ chối vì không fast-forward (commit khác vào cùng thư mục, thường do PA sửa tay qua yêu cầu gộp) thì writer kéo lại, sinh lại tệp từ CSDL và thử tối đa 3 lần với giãn cách ngẫu nhiên 1 đến 3 giây; CSDL là nguồn sinh trong luồng ghi, Git là trạng thái mong muốn có ký. Hết lần thử: ERR-20-024 (502), bản ghi phiên bản `FAILED`, thao tác nghiệp vụ báo lỗi cho người dùng nhưng dữ liệu CSDL vẫn nhất quán vì bản chiếu có `apply_status`. Sự cố giữa "chèn phiên bản `PENDING`" và "có commit" được khôi phục bởi tác vụ quét mỗi phút: bản ghi `PENDING` không có commit thì tìm theo trailer rồi commit nếu chưa có.

**Theo dõi áp dụng.** `ArgoStatusPoller` hỏi Application của tenant mỗi 10 giây cho tới khi `Synced` và `Healthy` hoặc quá 5 phút (NFR-20-011): đạt thì `apply_status = APPLIED`, `applied_at`, phát EVT-20-09; quá hạn hoặc `Degraded` thì `FAILED` với ERR-20-109 và cảnh báo PO. Đường vào qua API tỉnh (`PUT /settings`) chỉ chặt hơn giới hạn nền tảng (BR-20-011, ERR-20-023): `SettingsService` kiểm từng trường với bảng giới hạn trước khi lưu.

**Bản chiếu ngược.** Commit không phải của `svc-ph20-gitops` (sửa tay hợp lệ qua yêu cầu gộp có duyệt) được `ConfigProjector` phát hiện bằng polling 60 giây (hoặc webhook nếu có) và chiếu vào CSDL, `change_source = DRIFT_FIX` hoặc `API` tùy trường hợp, có kiểm lược đồ; không qua được lược đồ thì ghi `config_drift` với `status = DRIFTED` thay vì chiếu.

**Phát hiện lệch.** `DriftDetector` chạy mỗi `20.drift.check-interval` (1 giờ, ShedLock toàn cục) và duyệt từng tenant: so `desired_hash` của đầu nhánh Git với băm của bản chiếu CSDL, và đọc trạng thái Argo CD (`OutOfSync` là lệch giữa Git và cụm). Khác biệt tạo dòng `config_drift` `DRIFTED` kèm `differences` (danh sách trường, không có giá trị nhạy cảm); không đọc được Git hoặc Argo CD thì `UNKNOWN`, không báo giả. PA xử lý một lệch (API-20-046): "áp lại" (ghi lại từ Git vào cụm bằng đồng bộ Argo CD hoặc chiếu Git vào CSDL, `RECONCILED`) hoặc "nhận vào Git" (chấp nhận trạng thái thực, commit, `ACCEPTED`). `config:reconcile` (API-20-045) chạy ngay cho một tenant. Phát hiện lệch ≤ 1 giờ (NFR-20-010). Khôi phục một phiên bản (API-20-043) không sửa lịch sử: sinh phiên bản mới từ ảnh chụp cũ, kiểm hợp lệ với giới hạn hiện hành (ERR-20-026), `change_source = RESTORE`.

### 4.7. Hạn mức hợp đồng và đẩy xuống nơi thực thi (`QuotaService`, `QuotaPublisher`)

::: dac-ta
**Mục đích.** Giữ hạn mức hợp đồng của từng tenant theo 12 loại tài nguyên, tính hạn mức hiệu lực (cộng ghi đè tạm thời, trong trần nền tảng), duyệt bốn mắt khi hạ, và đẩy giá trị hiệu lực xuống nơi thực thi: PH-20 không tự chặn lượt gọi nào.

**Lớp chính.** `QuotaService`, `QuotaCalculator`, `QuotaChangeWorkflow`, `OverrideService`, `QuotaPublisher`, `RgwQuotaPusher`, `OverrideExpiryJob`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `OverrideExpiryJob` và `QuotaPublisher` ở hồ sơ `worker`.

**FR hiện thực.** FR-20-026, 027, 032; BR-20-013, 014, 015.

**Giao diện vào.** API-20-048…055; API-20-141 (hạn mức hiệu lực của tỉnh); API-20-164 (nơi thực thi đọc hạn mức hiệu lực); `PERM-20-quota`, `PERM-20-approve`.

**Phụ thuộc ra.** `GitOpsConfigWriter` (`quota.yaml`), `ObjectStoreClient` (hạn mức bucket), Kubernetes qua Argo CD (`ResourceQuota`); nơi thực thi PH-03, 04, 10, 12, 01, 02 nhận qua EVT-20-05 và xác nhận bằng EVT-03-11.

**Dữ liệu.** `tenant_quota`, `quota_change_request`, `quota_override`, `lifecycle_request` (loại `QUOTA_DECREASE`).

**Sự kiện.** EVT-20-05 khi hạn mức hợp đồng hoặc ghi đè đổi; nhận EVT-03-11.

**Lỗi và xử lý.** ERR-20-006, 007, 008, 022, 029, 030, 031, 062.

**Quan sát.** `dh_tenant_quota_effective{resource}`, `dh_tenant_quota_push_total{resource,result}`, `dh_tenant_quota_push_pending`, `dh_tenant_quota_override_active`.
:::

Chi tiết thiết kế:

**Hạn mức hiệu lực.** `QuotaCalculator.effective(tenant, resource, at)` bằng nhỏ hơn của trần nền tảng của hồ sơ quy mô và lớn hơn của hạn mức hợp đồng và mọi ghi đè `ACTIVE` tại thời điểm `at` (BR-20-013); hai ghi đè chồng thời gian thì giá trị lớn hơn thắng. Hàm thuần, kiểm thử đơn vị đầy đủ, được dùng cho cả đẩy xuống lẫn hiển thị.

**Đổi hạn mức.** Đặt ban đầu và tăng trong trần (API-20-049) do một PA có `PERM-20-quota` làm được ngay, có lý do và mã phiếu (BR-20-009). Hạ, hoặc đổi vượt trần, đi qua đề nghị: `quota_change_request` `DRAFT → PENDING_APPROVAL → APPROVED → EXECUTING → DONE`; người duyệt khác người lập và người gửi (ERR-20-007, ràng buộc `ck_quota_change_request_four_eyes`); hạ dưới mức đang dùng (đọc từ ảnh chụp mới nhất) vẫn cho phép sau duyệt nhưng ghi `belowUsage` và chỉ chặn cấp mới, không cắt tài nguyên đã cấp (BR-20-014, ERR-20-030 khi chưa duyệt). Ghi đè tạm thời (API-20-054) có `validFrom`, `validTo`, số ngày ≤ `20.quota.override-max-days` (ERR-20-031), giá trị trên hạn mức hợp đồng và trong trần (ERR-20-029); `OverrideExpiryJob` mỗi 5 phút đặt `EXPIRED` các ghi đè quá hạn, tính lại hạn mức hiệu lực, phát EVT-20-05 và báo đầu mối trước 24 giờ.

**Đẩy xuống.** Khi hạn mức hiệu lực đổi, trong cùng giao dịch `QuotaService` cập nhật `tenant_quota` (`push_status = PENDING`) và ghi outbox EVT-20-05 gồm tenant, danh sách (tài nguyên, giá trị hiệu lực, `effectiveFrom`, `version`); `GitOpsConfigWriter` cập nhật `quota.yaml` để Argo CD áp `ResourceQuota`. `QuotaPublisher` xử lý các đích PH-20 trực tiếp áp: `RgwQuotaPusher` đặt hạn mức bucket cho `OBJECT_STORAGE_GB`. Các đích PH-03 (`API_RPS`), PH-04 (`ACTIVE_FLOWS`), PH-10 (Kafka và `TOPICS`), PH-12 (`USERS`), PH-01 (`MEMBER_SYSTEMS`), PH-02 (`PUBLISHED_APIS`) tự áp khi nhận sự kiện hoặc đọc API-20-164 và xác nhận bằng sự kiện của mình (EVT-03-11 cho gateway); khi xác nhận tới thì `push_status = PUSHED`, `pushed_at`. Quá 10 phút không xác nhận thì `QuotaPublisher` phát lại sự kiện (cùng `eventId`, phía nhận khử trùng) với giãn cách 1, 5, 15 phút, tối đa sáu lần, rồi `FAILED` và cảnh báo PO. `DATABASE_GB` ở chế độ `SHARED` chỉ giám sát và cảnh báo, không cắt (Q20-07).

### 4.8. Thu thập sử dụng và cảnh báo ngưỡng (`UsageCollector`, ADR 204)

::: dac-ta
**Mục đích.** Đo mức dùng thực tế của từng tenant theo 12 tài nguyên mỗi giờ, lưu thành ảnh chụp phân vùng theo tháng, cảnh báo ở 80% và 100% hạn mức hiệu lực (SEC-86) và dựng báo cáo sử dụng theo kỳ.

**Lớp chính.** `UsageCollector`, `UsageSource` (và các hiện thực `MimirUsageSource`, `ObjectStoreUsageSource`, `IamUsageSource`, `CatalogUsageSource`, `DatabaseUsageEstimator`), `ThresholdProbe`, `QuotaAlertEvaluator`, `UsageReportService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker`; truy vấn đọc ở hồ sơ `api`.

**FR hiện thực.** FR-20-028…031; BR-20-016; NFR-20-008, 009.

**Giao diện vào.** API-20-056…062 (sử dụng toàn nền tảng, của một tenant, cảnh báo, báo cáo), API-20-140 (sử dụng của tỉnh); `PERM-20-read`, `PERM-20-usage-read`, `PERM-20-quota`.

**Phụ thuộc ra.** Mimir (`MimirClient`, PromQL), Ceph RGW (thống kê dung lượng bucket), PH-12 (số người dùng), PH-01, PH-02, PH-04, PH-10 (API thống kê nơi thực thi), PH-18 (thông báo), `QuotaCalculator`.

**Dữ liệu.** `usage_snapshot` (phân vùng tháng theo `captured_at`), `quota_alert`, `usage_report`, `tenant_quota` (đọc), `file_object`.

**Sự kiện.** EVT-20-06 khi chạm 80% hoặc 100%; nhận EVT-13-14 (cảnh báo công suất).

**Lỗi và xử lý.** ERR-20-006, 032, 062, 066, 110; nguồn thiếu không báo cảnh báo giả.

**Quan sát.** `dh_tenant_usage_percent{resource}`, `dh_tenant_usage_collect_seconds{source}`, `dh_tenant_usage_missing_total{resource}`, `dh_tenant_quota_alert_open{level}`, `dh_tenant_usage_partition_default_rows`.
:::

Chi tiết thiết kế:

**Nguồn số đo.** Mỗi tài nguyên có đúng một `UsageSource` quyết định cách đo; bảng dưới là ánh xạ từ `QuotaResource` sang nguồn (cột `source` của `usage_snapshot`) và đại lượng lấy. Số đo là đỉnh trong giờ với tài nguyên tốc độ, là giá trị cuối giờ với tài nguyên tồn kho.

| Tài nguyên | `source` | Đại lượng |
|---|---|---|
| `API_RPS` | `MIMIR` | Đỉnh lượt gọi mỗi giây theo nhãn `tenant` ở APISIX trong giờ |
| `KAFKA_PRODUCE_MBPS`, `KAFKA_CONSUME_MBPS` | `KAFKA` (qua Mimir) | Đỉnh thông lượng theo tiền tố topic `{ma}.` |
| `TOPICS` | `KAFKA` | Số topic có tiền tố của tenant |
| `OBJECT_STORAGE_GB` | `OBJECT_STORE` | Tổng dung lượng các bucket `dh-{ma}-*` từ thống kê RGW |
| `DATABASE_GB` | `DATABASE` | Ước theo `tenant_id` ở `SHARED` (lấy mẫu số dòng nhân kích thước dòng trung bình của các bảng chính, giả định, Q20-07, Q20-23); kích thước thật ở `DEDICATED_DB` |
| `USERS` | `IAM` | Số người dùng `ACTIVE` ở realm (API thống kê của PH-12) |
| `MEMBER_SYSTEMS`, `PUBLISHED_APIS` | `CATALOG` | Số HTTT `ACTIVE` (PH-01), số API đã công bố (PH-02) |
| `ACTIVE_FLOWS` | `RUNTIME` | Số luồng đang phát hành (PH-04) |
| `RUNTIME_CPU`, `RUNTIME_MEMORY_GB` | `RUNTIME` (qua Mimir) | Đỉnh sử dụng theo nhãn tenant của namespace runtime |

: Nguồn số đo của 12 tài nguyên

**Chu kỳ giờ.** `UsageCollector` chạy mỗi `20.usage.snapshot-interval` (PT1H) dưới ShedLock toàn cục `usage:collect`, căn tại đầu giờ. Với mỗi nguồn nó chạy một truy vấn gộp mọi tenant (nhóm theo nhãn `tenant`), nên mỗi giờ chỉ có khoảng 12 truy vấn thay vì 34 nhân 12; kết quả được chèn theo lô bằng `INSERT … ON CONFLICT (tenant_id, resource_code, captured_at) DO NOTHING`, nên chạy lại không nhân bản (`uq_usage_snapshot_point`). Mỗi dòng ghi cả `limit_value` hiệu lực tại giờ đó để lịch sử không phụ thuộc hạn mức hiện hành. Nguồn không trả lời thì không ghi dòng (CSDL không có cờ thiếu), đếm `dh_tenant_usage_missing_total` và giờ sau đọc bù tối đa 24 giờ bằng truy vấn khoảng của Mimir; thiếu quá 3 giờ liên tiếp phát ERR-20-110 cho PO (UI-20-06). Mimir không khả dụng là ERR-20-062 và tuyệt đối không tạo cảnh báo hạn mức giả. Tenant `DEDICATED_CLUSTER` không đẩy số về Mimir trung tâm được thì nhận gói số đo hằng ngày, `is_estimate = true`. Phân vùng do `PartitionMaintenanceJob` của PH-18 tạo trước ba tháng; `captured_at` ngoài biên rơi vào phân vùng mặc định, và chỉ số `dh_tenant_usage_partition_default_rows` > 0 sinh cảnh báo.

**Cảnh báo.** `QuotaAlertEvaluator` chạy cho từng dòng mới: `percent_used` bằng hoặc vượt `20.quota.warn-percent` (80) tạo cảnh báo `WARN_80`, bằng hoặc vượt 100 tạo `LIMIT_100`; chỉ mục `uq_quota_alert_open` bảo đảm mỗi (tenant, tài nguyên, mức) một cảnh báo mở nên số đo lặp lại không gửi lặp (BR-20-016). Tạo mới thì ghi outbox EVT-20-06 và gửi thông báo qua PH-18 tới PO và các đầu mối `TECHNICAL`, `TENANT_ADMIN`; cảnh báo mở được cập nhật `used_value`. Khi mức dùng xuống dưới `20.quota.alert-reset-percent` (75) liên tục 24 giờ thì cảnh báo `RESOLVED` (FRS 0.2 đã đổi `CLEARED` thành `RESOLVED`). PA xác nhận (API-20-059) đặt `ACKNOWLEDGED`, vẫn hiện tới khi giải quyết.

**Chu kỳ nhanh.** Cảnh báo ≤ 5 phút sau khi chạm ngưỡng (NFR-20-009) không đạt được nếu chỉ dựa vào chu kỳ giờ. Vì vậy `ThresholdProbe` chạy mỗi 5 phút, chỉ cho nhóm đo bằng Mimir (`API_RPS`, Kafka, runtime), lấy giá trị tức thời một truy vấn gộp, và chỉ gọi `QuotaAlertEvaluator` chứ không ghi ảnh chụp; nhóm còn lại đo bằng API thống kê nên có độ trễ tối đa một giờ cộng năm phút. Chu kỳ 5 phút là tham số `20.usage.probe-interval` đề xuất thêm (Phụ lục A). Ngoài ra EVT-13-14 do PH-13 phát khi công suất chung nguy cấp được đưa vào kiểm tra sẵn sàng và bảng điều khiển, không dùng để tạo cảnh báo hạn mức.

**Báo cáo.** `UsageReportService` dựng báo cáo theo kỳ (API-20-060) bất đồng bộ: đọc `usage_snapshot` theo khoảng (≤ 25 tháng, ERR-20-032), tổng hợp trung bình, đỉnh, số giờ vượt 80% và 100%, ghi XLSX, CSV hoặc PDF vào `file_object` (hạn theo `expires_at`), trạng thái `REQUESTED → GENERATING → READY`. Báo cáo có nhiều tenant chỉ cho PA, PO; tỉnh chỉ xem tenant mình (API-20-140). Không tính cước (Q20-06, ngoài v1.0).

### 4.9. Danh mục phân hệ, bật tắt và cờ tính năng (`ModuleCatalog`, `ModuleToggleService`)

::: dac-ta
**Mục đích.** Cho biết nền tảng có những phân hệ nào, phụ thuộc nhau ra sao, tenant nào đang bật phân hệ nào, và bật, tắt, tạm ngừng từng phân hệ cho một tenant theo cách an toàn; cung cấp trạng thái phân hệ cho menu và data plane.

**Lớp chính.** `ModuleCatalog`, `DependencyGraph`, `ModuleToggleService`, `FeatureFlagService`, `ModuleWatchdog`, `ModuleStateProjection`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `ModuleWatchdog` ở hồ sơ `worker`.

**FR hiện thực.** FR-20-033…037; BR-20-017, 018.

**Giao diện vào.** API-20-063…070, API-20-142 (`context` cho `dh-console`); `ModuleStateQuery`; `PERM-20-admin`, `PERM-20-read`.

**Phụ thuộc ra.** `GitOpsConfigWriter` (`modules.yaml`), `ProvisioningOrchestrator` (lần chạy `SUPPLEMENT` một bước `S15`), `outbox`.

**Dữ liệu.** `platform_module`, `module_dependency` (dữ liệu nền tảng, mọi tenant đọc được), `tenant_module`, `tenant_feature_flag`.

**Sự kiện.** EVT-20-07 (bật, tiếp tục), EVT-20-08 (tắt, tạm ngừng), EVT-20-09 với `changeKind = FEATURE_FLAG`.

**Lỗi và xử lý.** ERR-20-033, 034, 035, 036, 055, 103, 106, 107; ERR-20-062.

**Quan sát.** `dh_tenant_module_state{module,state}`, `dh_tenant_module_enable_seconds{module}`, `dh_tenant_feature_flag_total`.
:::

Chi tiết thiết kế:

`ModuleCatalog` nạp `platform_module` và `module_dependency` vào bộ nhớ (làm mới 5 phút và khi nhận sự kiện đổi danh mục), dựng đồ thị có hướng và kiểm không chu trình khi nạp (sắp xếp tô-pô; chu trình là lỗi dữ liệu nền, ngăn khởi động). Phụ thuộc có hai loại: `REQUIRED` chặn bật, `OPTIONAL` chỉ cảnh báo (Q20-52). Phân hệ lõi PH-03, 10, 12, 13, 18, 20 có cờ `core` và luôn `ENABLED` với tenant tỉnh `ACTIVE`.

**Bật.** `ModuleToggleService.enable(tenant, module)` kiểm tenant `ACTIVE`, mọi phụ thuộc `REQUIRED` đang `ENABLED` (ERR-20-033) và phân hệ có trong phiên bản đang chạy của tenant (ERR-20-055, hỏi SPI `ModuleAvailabilityCheck` đặt ở `tenant.api` do `release` hiện thực, không import `release`); phân hệ không có bước khởi tạo riêng (`asyncProvision = false`) thì `ENABLED` ngay. Ngược lại, giao dịch chuyển `DISABLED` (hoặc `FAILED`) sang `ENABLING` bằng cập nhật có điều kiện, tạo lần chạy `SUPPLEMENT` chỉ có bước `S15`, ghi outbox EVT-20-07 với `eventId` xác định theo (lần chạy, phân hệ). Phân hệ báo qua API-20-166: `SUCCEEDED` thì `ENABLED`, ghi `modules.yaml`, vô hiệu bộ đệm registry; `FAILED` hoặc quá `20.provision.step-timeout-minutes` thì `FAILED` (`ModuleWatchdog`, ERR-20-106, 107), PA thử lại hoặc tắt.

**Tắt, tạm ngừng, tiếp tục.** Từ chối phân hệ lõi (ERR-20-035) và phân hệ là phụ thuộc `REQUIRED` của phân hệ khác đang bật (ERR-20-034). Tạm ngừng chuyển `SUSPENDED` và phát EVT-20-08 `mode = SUSPEND` (phân hệ trả ERR-20-103 ở data plane, menu hiện ở chế độ chỉ đọc); tắt chuyển `DISABLING`, phát `mode = DISABLE`, phân hệ dừng tác vụ nền của tenant rồi báo xong để `DISABLED`; tiếp tục phát EVT-20-07 `mode = RESUME`. Tắt không xóa dữ liệu của phân hệ (BR-20-018): thời hạn lưu theo chính sách của phân hệ.

**Cờ tính năng.** `FeatureFlagService` lưu cờ theo (tenant, `flag_code`) với phạm vi áp dụng và giá trị; cờ chỉ áp được khi phân hệ đích `ENABLED` (ERR-20-036). Ghi cờ đi cùng đường GitOps (`modules.yaml`) và phát EVT-20-09. Giá trị hiệu lực của cờ cho người dùng cuối là cờ của tenant nếu có, ngược lại mặc định của phân hệ; không có logic cờ nào ở `dh-console`, nó chỉ nhận kết quả.

**Cung cấp trạng thái cho giao diện.** API-20-142 đọc tenant từ token, trả trạng thái tenant, danh sách phân hệ kèm `state`, cờ áp dụng, `banner` (`MERGING`, `SUSPENDED`, `MAINTENANCE`, `UPGRADE_SCHEDULED`) và `readOnly`; phản hồi có `ETag` và `Cache-Control: private, max-age=60`. Tenant `SUSPENDED` vẫn nhận `200` với `readOnly = true` (không trả ERR-20-001 ở API này) để người dùng hiểu lý do.

### 4.10. Vòng đời tenant (`LifecycleService`)

::: dac-ta
**Mục đích.** Điều khiển tạm ngừng, khôi phục và chấm dứt tenant: chuyển trạng thái đúng máy trạng thái, bảo đảm bốn mắt, lý do, mã phiếu và lưới an toàn của chấm dứt, và lan hiệu lực tới các phân hệ thực thi ở data plane.

**Lớp chính.** `LifecycleService`, `ApprovalGuard`, `SuspendExecutor`, `ResumeExecutor`, `TerminateExecutor`, `StatusNotifier`, `StatusHistoryWriter`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (lập, duyệt, thực hiện); hồ sơ `worker` (thực hiện theo lịch, thử lại, thông báo).

**FR hiện thực.** FR-20-038…040, 042…044, 025 (đổi cách ly đi qua cùng máy duyệt); BR-20-003, 008, 009, 019…021.

**Giao diện vào.** API-20-071…079, API-20-085 (đề nghị, duyệt, thực hiện, lịch sử); `PERM-20-lifecycle`, `PERM-20-approve`.

**Phụ thuộc ra.** PH-12 (API-12-084 chỉ đọc, API-12-085 khôi phục, xóa realm), PH-13 (API-13-073 đóng chuỗi), PH-09 (FR-09-043 xóa mật mã), `DataExportService`, `OpsClient` (thông báo, mở việc), `GitOpsConfigWriter`, `ObjectStoreClient`, `BaoClient`.

**Dữ liệu.** `lifecycle_request`, `tenant_status_history`, `tenant`, `data_export_package`.

**Sự kiện.** EVT-20-04 (mọi đổi trạng thái); nhận EVT-09-21 (hoàn tất xóa mật mã).

**Lỗi và xử lý.** ERR-20-001, 004, 006, 007, 008, 010, 028, 037, 038, 102, 116.

**Quan sát.** `dh_tenant_lifecycle_requests_total{type,status}`, `dh_tenant_suspend_apply_seconds`, `dh_tenant_terminate_stage{stage}`.
:::

Chi tiết thiết kế:

**Tạm ngừng.** `LifecycleService` kiểm trạng thái `ACTIVE` (ERR-20-006), không phải tenant đặc biệt (ERR-20-010), lý do ≥ `20.lifecycle.reason-min-length` ký tự và mã phiếu (ERR-20-008), văn bản căn cứ khi lý do là `MANAGEMENT_DECISION` (ERR-20-004; `SECURITY_INCIDENT` không cần ngay, hệ thống mở việc ở PH-18 đòi bổ sung trong 3 ngày làm việc). Đề nghị `SUSPEND` đi thẳng từ `DRAFT` sang `APPROVED` rồi `EXECUTING` khi người lập bấm "Thực hiện" vì cần phản ứng nhanh (BR-20-021). Giao dịch thực hiện gồm: chuyển tenant `ACTIVE → SUSPENDED` qua `TenantTransitions`, ghi `tenant_status_history`, outbox EVT-20-04 kèm `essentialApiAllowed` (từ `20.suspend.essential-api-allowed` hoặc quyết định riêng) và vô hiệu bộ đệm registry. Hiệu lực ở data plane do PH-03 nhận EVT-20-04 (và thăm dò API-20-164) trả ERR-20-001; PH-04 dừng luồng theo lịch; PH-10 chặn sản xuất sự kiện từ HTTT. Sau commit, `SuspendExecutor` gọi API-12-084 để realm chỉ cho đăng nhập xem và chặn token máy; PH-12 lỗi thì tenant vẫn `SUSPENDED` (hướng an toàn: chặn data plane không phụ thuộc PH-12), đề nghị giữ `EXECUTING` và tác vụ thử lại tới khi PH-12 nhận (1, 5, 15 phút, lặp). Mục tiêu hiệu lực ≤ 60 giây (NFR-20-004) đạt nhờ vô hiệu bộ đệm bằng sự kiện cộng thăm dò 15 giây, không nhờ hết hạn bộ đệm (mục 4.16).

**Khôi phục.** Điều kiện tenant `SUSPENDED` không có đề nghị chấm dứt đã duyệt đang chờ; chuyển `ACTIVE`, gọi API-12-085, phát EVT-20-04; ERR-20-037 khi chưa đủ điều kiện.

**Chấm dứt.** Chuỗi điều kiện là lưới an toàn: tenant `SUSPENDED`, gói bàn giao `DELIVERED` (hoặc `exportRequired = false` có văn bản từ chối nhận), đã hết `20.terminate.cooling-days` (30) kể từ lúc tạm ngừng (`cooling_until`), và hai PA khác nhau (người duyệt khác người lập, người gửi, và khác người xác nhận bàn giao, BR-20-008). `ApprovalGuard` kiểm ở dịch vụ và `ck_lifecycle_request_four_eyes` kiểm ở CSDL. Khi đủ điều kiện và PA gõ mã xác nhận, `TerminateExecutor` chạy các giai đoạn, mỗi giai đoạn lưu vào `lifecycle_request` để chạy lại được: (1) đặt tenant `DECOMMISSIONED` cùng EVT-20-04 để data plane trả ERR-20-102 ngay và các phân hệ gỡ tài nguyên, xóa dữ liệu theo chính sách của mình; (2) PH-12 xóa realm, PH-13 đóng chuỗi kiểm toán (chuỗi WORM giữ theo thời hạn quy định); (3) gỡ bucket, đường dẫn OpenBao, thư mục Git (commit xóa có ký, lịch sử Git giữ); (4) gọi FR-09-043 xóa mật mã KEK `dh-{ma}-pii`; (5) nhận EVT-09-21 thì đóng đề nghị `DONE`. Xóa mật mã là bước cuối và không đảo ngược (BR-20-020): chỉ chạy khi các giai đoạn trước xong và gói bàn giao đã xác nhận; chưa nhận EVT-09-21 thì đề nghị còn `EXECUTING` với ERR-20-116 ở bảng điều khiển. Một phân hệ chưa báo gỡ xong sau 24 giờ không chặn: việc dọn riêng được mở ở PH-18. SDD đặt chuyển `DECOMMISSIONED` ở giai đoạn 1 (cùng sự kiện) thay vì sau EVT-09-21 như FRS FR-20-042 bước 5, để data plane ngừng ngay; lệch ghi ở Phụ lục A.

**Thông báo.** `StatusNotifier` chọn người nhận theo trạng thái (đầu mối `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY` cho tạm ngừng, chấm dứt, sáp nhập; PO cho mọi chuyển; người dùng tỉnh qua thông báo trong ứng dụng khi `SUSPENDED`, `MERGING`) và gọi `NotificationApi` của PH-18 với `Idempotency-Key = {historyId}:{kênh}`; lỗi thì thử lại 6 lần trong 1 giờ rồi cảnh báo PO ở UI-20-20. Lý do `SECURITY_INCIDENT` chỉ ghi "sự cố an toàn thông tin" trong thư.

### 4.11. Gói bàn giao dữ liệu (`DataExportService`)

::: dac-ta
**Mục đích.** Tập hợp dữ liệu của tenant do từng phân hệ xuất, dựng bản kê có ký và băm, và bàn giao có biên bản cho tỉnh trước khi chấm dứt.

**Lớp chính.** `DataExportService`, `ExportManifestBuilder`, `ExportParticipantClient`, `ExportLinkIssuer`, `ExportExpiryJob`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (thu thập, dựng bản kê, hết hạn); hồ sơ `api` (yêu cầu, cấp liên kết, xác nhận).

**FR hiện thực.** FR-20-041; BR-20-008, 019; NFR-20-023.

**Giao diện vào.** API-20-080…084, API-20-168 (phân hệ báo đã xuất); `PERM-20-lifecycle`, scope `tenant:provision-report`.

**Phụ thuộc ra.** Mọi phân hệ có dữ liệu (lệnh xuất qua sự kiện nội bộ), Ceph RGW (bucket `dh-{ma}-exports`, liên kết có hạn), OpenBao transit (ký bản kê), PH-18 (thông báo).

**Dữ liệu.** `data_export_package`, `data_export_item`, `file_object`, `lifecycle_request`.

**Sự kiện.** EVT-20-16 khi gói `READY`.

**Lỗi và xử lý.** ERR-20-006, 007, 039, 062; phân hệ báo lỗi thì mục `FAILED`.

**Quan sát.** `dh_tenant_export_package_total{status}`, `dh_tenant_export_bytes`, `dh_tenant_export_duration_seconds`.
:::

Chi tiết thiết kế:

Gói không phải một tệp nén mà là một thư mục đối tượng `packages/{packageId}/{module}/` trong bucket `dh-{ma}-exports`, do từng phân hệ ghi trực tiếp vào phần của mình (Parquet và JSON, Q20-02) rồi báo số bản ghi, kích thước, SHA-256 qua API-20-168; nhờ vậy không có bước gom lại 500 GB và mục tiêu 24 giờ (NFR-20-023, giả định) chỉ cần thông lượng gộp khoảng 6 MB mỗi giây. Dòng `data_export_item` cho mỗi phân hệ có `item_type` do phân hệ khai báo (Q20-53). Khi đủ báo, `ExportManifestBuilder` dựng `manifest.json` (phân hệ, tệp, băm, số bản ghi), ký bằng khóa nền tảng ở OpenBao, tính `sha256` toàn gói, gói `READY` và phát EVT-20-16. Phân hệ chưa bật cho tenant không tham gia và được ghi "không có dữ liệu" trong bản kê.

PA cấp liên kết tải có thời hạn (24 giờ, giả định) tới đầu mối tỉnh; tải xong, PA tải biên bản bàn giao lên và xác nhận để gói `DELIVERED`, kèm `delivered_to`; người xác nhận không được là người duyệt chấm dứt (ERR-20-007). Gói tự `EXPIRED` sau `20.export.retention-days` (90) và tệp bị xóa theo `expires_at` (ERR-20-039 khi dùng liên kết quá hạn). Cách mã hóa gói và cách giao khóa cho tỉnh là Q20-29.

### 4.12. Sáp nhập tenant (`MergeCoordinator`, ADR 202)

::: dac-ta
**Mục đích.** Điều phối việc gộp tenant nguồn vào tenant đích khi sắp xếp đơn vị hành chính: lập kế hoạch, ánh xạ, chạy thử, chuyển dữ liệu theo phân hệ, xử lý xung đột, chuyển định danh, cutover, chuyển tiếp và kết thúc, mà không ghi đè dữ liệu và không gián đoạn HTTT.

**Lớp chính.** `MergeCoordinator`, `MergePlanService`, `MappingService`, `ConflictService`, `MergeParticipantClient`, `IdentityTransferService`, `CutoverService`, `TransitionWatcher`, `OrgMergeParticipant`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (lập, duyệt, quyết định xung đột); hồ sơ `worker` (điều phối chuyển, theo dõi, cutover, kết thúc).

**FR hiện thực.** FR-20-045…052; BR-20-022…026.

**Giao diện vào.** API-20-086…108, API-20-167 (phân hệ báo tiến độ); `PERM-20-merge`, `PERM-20-approve`, scope `tenant:provision-report`.

**Phụ thuộc ra.** PH-18 `POST /api/ops/v1/merge-transfers` (API-18-150…153, tài khoản máy qua `apisix-int`, scope `ops:merge-transfer`; khóa lũy đẳng `{mergePlanId}:{module}`, thêm `:DELTA` cho lượt bù cuối và `:DRYRUN` cho chạy thử; thân có `mode` (`FULL`, `DELTA`) và `since`), PH-12 (API-12-045, 046), PH-03 (qua API-20-164 và EVT-20-11), PH-01 (cấp song song thông tin xác thực HTTT), PH-13 (đóng chuỗi), `OpsClient`.

**Dữ liệu.** `merge_plan`, `merge_mapping`, `merge_participant_run`, `merge_conflict`, `tenant`, `tenant_status_history`.

**Sự kiện.** EVT-20-10 (bắt đầu chuyển), EVT-20-11 (cutover), EVT-20-12 (kết thúc), EVT-20-04; nhận EVT-03-10 (xác nhận chuyển tiếp).

**Lỗi và xử lý.** ERR-20-006, 007, 040, 041, 042, 043, 044, 045, 046, 059, 062, 107, 113, 114, 115.

**Quan sát.** `dh_tenant_merge_plans{status}`, `dh_tenant_merge_participant_seconds{module,phase}`, `dh_tenant_merge_conflicts_open`, `dh_tenant_merge_count_mismatch_total{module}`, `dh_tenant_merge_redirect_error_ratio`.
:::

Chi tiết thiết kế:

**Hợp đồng bên tham gia (`MergeParticipant`).** PH-20 không biết dữ liệu của phân hệ khác; mỗi phân hệ có dữ liệu cung cấp một hợp đồng gồm ba năng lực theo gói: xuất phần dữ liệu của tenant nguồn, nhập vào tenant đích theo bảng ánh xạ (giữ `id` gốc, ghi `origin_tenant_id`, BR-20-023), và kiểm đếm. PH-18 chạy công cụ chuyển dữ liệu gọi các năng lực này; PH-20 chỉ gọi PH-18 `POST /api/ops/v1/merge-transfers` với thân `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`, `phase`, lũy đẳng theo `{mergePlanId}:{module}`, và nhận tiến độ qua API-20-167. Ánh xạ `mappingRef` là tham chiếu tới bộ `merge_mapping` đã xác nhận, kèm `mappingHash`. Chính PH-20 cũng là một bên tham gia cho dữ liệu của mình (tổ chức): `OrgMergeParticipant` hiện thực cùng hợp đồng trong tiến trình.

**Kế hoạch và ánh xạ.** `MergePlanService` kiểm nguồn và đích `ACTIVE`, loại `PROVINCE`, nguồn chưa thuộc kế hoạch mở khác (ERR-20-040, 041), thời gian chuyển tiếp ≤ `20.merge.transition-max-months` (ERR-20-045). `MappingService` sinh gợi ý (API-20-095) cho sáu loại ánh xạ: tổ chức theo ĐVHC và tên, HTTT theo mã, mã danh mục trùng, `contextPath` API trùng tiền tố, người dùng theo tên đăng nhập hoặc thư điện tử hoặc liên kết LDAP, topic theo tên cộng tiền tố tenant đích; mỗi dòng có hành động `MAP`, `CREATE` hoặc `SKIP`. Dòng bắt buộc chưa quyết định chặn chạy thử (ERR-20-042).

**Chạy thử và chuyển.** Chạy thử (API-20-097) gọi PH-18 với `dryRun = true` trên bản sao không ghi, nhận số bản ghi, số xung đột dự kiến, thời gian ước tính; kết quả `PASSED` kèm `mappingHash`, và chạy thử chỉ còn giá trị khi `mappingHash` không đổi (ERR-20-043). Sau duyệt bốn mắt, `start` đặt nguồn `MERGING`, kế hoạch `TRANSFERRING`, phát EVT-20-10, EVT-20-04, rồi `MergeCoordinator` chạy các phân hệ theo đồ thị phụ thuộc: tổ chức (PH-20), PH-07, PH-01, PH-02, PH-10, PH-04 và PH-05, PH-03, rồi các phân hệ khác; phân hệ không phụ thuộc nhau chạy song song (tối đa 4 phân hệ cùng lúc). Mỗi báo tiến độ cập nhật `merge_participant_run`; khi phân hệ báo `SUCCEEDED`, PH-20 so `exported_count` với `imported_count` cộng `SKIP`: lệch là ERR-20-113 và phân hệ `FAILED` (NFR-20-014, kiểm đếm 100%). Có xung đột thì kế hoạch sang `CONFLICT_REVIEW`; phân hệ dính xung đột tạm dừng phần đó, quyết định từng xung đột hoặc hàng loạt với `KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP`, không bao giờ ghi đè tự động. Phân hệ lỗi có thể chạy lại riêng (API-20-100).

**Định danh.** Khi mọi phân hệ `SUCCEEDED` và hết xung đột, `IdentityTransferService` gọi API-12-045 lập kế hoạch từ ánh xạ `USER`, rồi API-12-046 thực hiện: PH-12 tạo người dùng ở realm đích (buộc đặt lại mật khẩu, Q20-13) và cấp song song thông tin xác thực mới cho từng HTTT với hạn bằng `transitionEndsAt`; PH-20 ghi trạng thái `ISSUED`, `IN_USE_NEW`, `OLD_ONLY` và gửi thư hướng dẫn tới đầu mối kỹ thuật qua PH-18.

**Cutover và chuyển tiếp.** `CutoverService` kiểm điều kiện (không xung đột, trong cửa sổ bảo trì nếu có, ERR-20-044, 059), đặt nguồn chỉ đọc, yêu cầu mỗi phân hệ chạy lượt bù cuối theo `updated_at`, chờ báo, rồi trong một giao dịch chuyển nguồn `MERGING → MERGED`, đặt `merged_into_id`, kế hoạch `TRANSITION`, `transition_until = now + transition_months`, và ghi bảng chuyển tiếp (ánh xạ `API_CONTEXT_PATH`) vào `EnforcementView` để PH-03 đọc qua API-20-164. Cùng giao dịch ghi outbox EVT-20-11, EVT-20-04. PH-03 bật chuyển tiếp kèm header `Deprecation`, `Sunset` và phát EVT-03-10; không nhận sau 15 phút thì cảnh báo PO. `TransitionWatcher` theo dõi tỷ lệ lỗi của lượt gọi chuyển tiếp trong 60 phút đầu, vượt 1% thì cảnh báo PA (không tự quay lui vì dữ liệu đã chuyển). Ghi vào tenant `MERGED` trả ERR-20-115. Mục tiêu cutover không có lượt lỗi do chuyển tiếp, thêm trễ ≤ 10 ms (NFR-20-015).

**Kết thúc và hủy.** Khi đến `transition_until` (hoặc PA gia hạn, `extend-transition`, không quá mức tối đa), PA gọi `complete`: nguồn `MERGED → DECOMMISSIONED`, thu hồi thông tin xác thực cũ qua PH-12, đóng chuỗi kiểm toán, phát EVT-20-12; dữ liệu nguồn giữ chỉ đọc theo thời hạn lưu (10 năm, tạm dùng, Q20-01). Hủy chỉ được trước cutover (BR-20-024): nguồn `MERGING → ACTIVE` (bổ sung của D03-10) và dữ liệu đã chuyển sang đích được gỡ theo `origin_tenant_id` qua PH-18; ERR-20-044 nếu đã cutover.

### 4.13. Tổ chức và nhập tổ chức (`OrganizationService`, `OrgImportService`)

::: dac-ta
**Mục đích.** Giữ danh mục tổ chức (DD-02) của từng tỉnh: cây cơ quan, hiệu lực theo thời gian, giải thể và sáp nhập có tổ chức kế thừa, chủ quản dữ liệu, nhập xuất tệp; cung cấp API đọc cho phân hệ khác và đề xuất đồng bộ khi sắp xếp đơn vị hành chính.

**Lớp chính.** `OrganizationService`, `OrganizationTree`, `OrgReferenceCounter`, `OrgImportService`, `OrgFileParser`, `OrgSyncProposalService`, `OrganizationReadApi`, `OrgMergeParticipant`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `OrgImportService` và `OrgSyncProposalService` ở hồ sơ `worker`.

**FR hiện thực.** FR-20-053…058; BR-20-027…029; NFR-20-012, 013.

**Giao diện vào.** API-20-143…158, API-20-169…171 (đọc nội bộ); `OrganizationQuery`; `PERM-20-org`, `PERM-20-org-read`, scope `tenant:org-read`.

**Phụ thuộc ra.** PH-01, PH-12, PH-06 (API thống kê tham chiếu), PH-07 (ĐVHC `COMMON`), Apache POI, bộ quét mã độc, `outbox`.

**Dữ liệu.** `organization`, `org_import_job`, `org_import_row`, `file_object`.

**Sự kiện.** EVT-20-13 trên `{tenant}.tenant.org.changed.v1` (`change` là `CREATED`, `UPDATED`, `INACTIVE`, `DISSOLVED`, `MERGED`, `BULK_IMPORT`); nhận EVT-07-10.

**Lỗi và xử lý.** ERR-20-002, 003, 012, 047, 048, 049, 050, 051, 052.

**Quan sát.** `dh_tenant_org_total{status}`, `dh_tenant_org_import_rows_total{result}`, `dh_tenant_org_read_seconds`.
:::

Chi tiết thiết kế:

**Cây và hiệu lực.** Mỗi tổ chức có `effective_from`, `effective_to` (BR-20-028); truy vấn có tham số `asOf`. Cây là quan hệ cha con trong cùng bảng; đọc cây dùng truy vấn đệ quy (CTE) giới hạn độ sâu 12. Chống chu trình hai lớp: `OrganizationTree` kiểm trước khi lưu (ERR-20-047) và trigger `tg_organization_cycle`. Mã duy nhất trong tenant; tổ chức không bị xóa cứng, chỉ đổi trạng thái (BR-20-027). Mã định danh điện tử của cơ quan lưu ở trường riêng, không làm khóa (Q20-11).

**Giải thể và sáp nhập tổ chức.** `OrgReferenceCounter` đếm tham chiếu đang hoạt động qua API thống kê của từng phân hệ (HTTT ở PH-01, người dùng ở PH-12, chủ quản dữ liệu ở PH-06 và các phân hệ khác) với thời gian chờ 3 giây; phân hệ không trả lời thì kết quả "không rõ" và giải thể đòi kế thừa như khi còn tham chiếu. Còn tham chiếu mà thiếu tổ chức kế thừa là ERR-20-049; kế thừa phải `ACTIVE`, khác chính nó, cùng tenant (ERR-20-048). Giải thể hoặc sáp nhập đặt `DISSOLVED` hoặc `MERGED`, `effective_to`, `successor_id`, chuyển cha của tổ chức con sang tổ chức kế thừa (TA xác nhận danh sách), phát EVT-20-13 để PH-01 tạo đề nghị đổi chủ quản chờ TA duyệt hàng loạt (đề xuất Q01-10).

**Nhập xuất.** `OrgImportService` hai pha (ADR-056): tải tệp Excel hoặc CSV (tối đa `20.org.import-max-rows` = 5000 dòng, ERR-20-050), quét mã độc, phân tích bằng Apache POI dạng luồng; mỗi dòng kiểm như tạo tay (kể cả cha nằm trong cùng tệp) rồi gán hành động `CREATE`, `UPDATE`, `SKIP` hoặc `ERROR` ghi vào `org_import_row`; xem trước 5.000 dòng trong ≤ 30 giây (NFR-20-012) nhờ kiểm tra theo lô, tra mã bằng tập băm trong bộ nhớ. Còn dòng lỗi thì "Xác nhận nhập" bị từ chối (ERR-20-051); không còn thì ghi tất cả trong một giao dịch theo thứ tự cha trước con và phát một EVT-20-13 gộp. Xuất ra XLSX hoặc CSV theo bộ lọc hiện hành.

**Đồng bộ theo sắp xếp ĐVHC.** `OrgSyncProposalService` nhận EVT-07-10 qua inbox (khử trùng theo `eventId`), tìm tổ chức của mọi tenant tỉnh có ĐVHC liên quan và tạo đề xuất cho TA: tạo tổ chức mới cho ĐVHC mới, giải thể tổ chức cũ với kế thừa là tổ chức mới. Đề xuất chỉ áp khi TA bấm "Áp" (BR-20-029), tự đánh `ALREADY_APPLIED` khi tỉnh đã làm trước.

**API đọc cho phân hệ khác.** API-20-169…171 và `OrganizationQuery` trả tổ chức kèm `status`, `successorCode` và `resolvedSuccessor` (chuỗi kế thừa tới tổ chức `ACTIVE` cuối); tra hàng loạt tối đa 500 mã. Đọc là truy vấn chỉ mục theo (tenant, mã), p95 ≤ 100 ms (NFR-20-013); phản hồi có `ETag`, phân hệ gọi đệm tối đa 24 giờ và làm mới khi nhận EVT-20-13. Tenant `MERGED` trả tổ chức nguồn chỉ đọc kèm `migratedTo`.

### 4.14. Phiên bản sản phẩm và kênh phát hành (`ReleaseService`, ADR 203)

::: dac-ta
**Mục đích.** Giữ danh mục phiên bản của sản phẩm Datahub (ảnh container của mọi DU, chart, migration), đưa phiên bản qua hai kênh `PREVIEW` và `STABLE` với điều kiện thí điểm, và quản lý kênh đăng ký của từng tenant.

**Lớp chính.** `ReleaseService`, `ReleaseRegistrar`, `ChannelService`, `PromotionGuard`, `ReleaseAnnouncementService`, `SubscriptionListFilter` (hiện thực `TenantListFilter`).

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `ReleaseRegistrar` nhận đăng ký từ CI qua tài khoản dịch vụ.

**FR hiện thực.** FR-20-059, 060, 063, 064; BR-20-030, 031, 034.

**Giao diện vào.** API-20-109…117, API-20-128 (thông báo), API-20-159 (`release-info` của tỉnh), API-20-160 (`maintenance-window`); `PERM-20-release`, `PERM-20-org-read`.

**Phụ thuộc ra.** Kho ảnh (kiểm chữ ký cosign và digest), `tenant.api` (`TenantRegistry`), `UpgradeOrchestrator`, `OpsClient` (thông báo).

**Dữ liệu.** `product_release`, `release_component`, `tenant_release_subscription`, `maintenance_window`.

**Sự kiện.** EVT-20-14 khi phiên bản sang `PREVIEW` hoặc `STABLE`.

**Lỗi và xử lý.** ERR-20-003, 005, 006, 053, 054, 055, 061.

**Quan sát.** `dh_release_total{status}`, `dh_release_soak_days{version}`, `dh_release_tenants_by_version{version,channel}`.
:::

Chi tiết thiết kế:

CI đăng ký phiên bản qua API-20-110 với danh sách thành phần (`release_component`: loại `SERVICE`, `CONSOLE`, `CHART`, `SCHEMA`, `CONFIG`; tên ảnh, digest, chart, migration) và ghi chú phát hành. `ReleaseService` kiểm SemVer `MAJOR.MINOR.PATCH` không trùng (ERR-20-053, ERR-20-003), kiểm mọi ảnh tồn tại theo digest và có chữ ký cosign hợp lệ trước khi nhận (BR-20-030). Máy trạng thái `DRAFT → PREVIEW → STABLE → DEPRECATED`, nhánh `WITHDRAWN`, bảo vệ bằng cập nhật có điều kiện và trigger `tg_product_release_transition`; từ `PREVIEW` nội dung bất biến.

`PromotionGuard` kiểm điều kiện sang `STABLE` (BR-20-031): `now − preview_at ≥ 20.release.stable-soak-days` (14), không sự cố mức 1 mở liên quan phiên bản (truy vấn PH-18), và có ít nhất một tenant thí điểm chạy phiên bản ở `PREVIEW` ổn định (ERR-20-054 khi chưa đủ). `DEPRECATED` đến tự động khi có `20.release.supported-minors` (2) bản phụ mới hơn (BR-20-034); `WITHDRAWN` do PA gọi, đề xuất kế hoạch quay lui hoặc vá cho tenant đang chạy.

Mỗi tenant đăng ký một kênh cho mỗi môi trường (`tenant_release_subscription`); đổi kênh bị chặn khi tenant đang trong kế hoạch nâng cấp (ERR-20-061) và ghi `release.yaml` qua `TenantConfigApi`; không cho tenant `PROD` theo `PREVIEW` (Q20-09). `SubscriptionListFilter` là bean đăng ký vào giao diện `TenantListFilter` của `tenant.api` để API-20-001 lọc theo kênh. `release-info` (API-20-159) trả phiên bản đang chạy của tỉnh (từ `RunningVersionQuery`), ghi chú phát hành và lịch bảo trì. Thông báo phát hành và lịch bảo trì (API-20-128) gửi tới TA qua PH-18, khẩn thì thông báo trước ≥ `20.upgrade.emergency-notice-hours` giờ.

### 4.15. Nâng cấp theo sóng (`UpgradeOrchestrator`, ADR 203)

::: dac-ta
**Mục đích.** Đưa một phiên bản sản phẩm tới nhiều tenant theo từng sóng, đúng cửa sổ bảo trì của từng tỉnh, kiểm tra sau khi nâng cấp, tự dừng sóng khi lỗi vượt ngưỡng và quay lui được khi chưa qua bước không đảo ngược.

**Lớp chính.** `UpgradeOrchestrator`, `WavePlanner`, `UpgradeTicker`, `WaveGuard`, `UpgradeVerifier`, `RollbackService`, `MaintenanceWindowService`, `TenantStatusListener` (nghe `TenantStatusChanged`).

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (vòng nâng cấp, canh sóng); hồ sơ `api` (lập kế hoạch, dừng, tiếp tục, quay lui).

**FR hiện thực.** FR-20-061…064, FR-20-025 (đổi cách ly dùng cùng cửa sổ); BR-20-032, 033, 040.

**Giao diện vào.** API-20-118…127, API-20-160; `PERM-20-release` (PO chỉ theo dõi và dừng sóng), `PERM-20-settings` (cửa sổ của tỉnh).

**Phụ thuộc ra.** `tenant.api.TenantConfigApi` (ghi `release.yaml`, đọc trạng thái Argo CD), `TenantSmokeApi.runLite`, Mimir (tỷ lệ lỗi 5xx theo tenant), `OpsClient` (thông báo, cảnh báo).

**Dữ liệu.** `upgrade_plan`, `upgrade_wave`, `tenant_upgrade`, `maintenance_window`, `tenant_release_subscription`, `product_release` (đọc).

**Sự kiện.** EVT-20-15 mỗi lần một nâng cấp tenant đổi trạng thái; nhận `TenantStatusChanged` (sự kiện ứng dụng).

**Lỗi và xử lý.** ERR-20-055, 056, 057, 058, 059, 112, 118; ERR-20-109 khi Argo CD lỗi.

**Quan sát.** `dh_release_upgrade_total{status}`, `dh_release_wave_error_ratio{plan,wave}`, `dh_release_upgrade_duration_seconds`, `dh_release_plan_paused_total{reason}`.
:::

Chi tiết thiết kế:

**Lập kế hoạch.** `WavePlanner` gợi ý ba sóng: sóng 1 là tenant kênh `PREVIEW` (thí điểm), sóng 2 tối đa 5 tenant nhỏ (hồ sơ `QM-NHO`), sóng 3 phần còn lại. Mỗi tenant phải đủ điều kiện: `ACTIVE`, kênh khớp trạng thái phiên bản (`STABLE` cho kênh `STABLE`), không ghim phiên bản, chưa thuộc kế hoạch mở khác (ERR-20-056), phiên bản không `DEPRECATED` hay `WITHDRAWN` (ERR-20-055). Lên lịch (`schedule`) tính `scheduled_for` của từng tenant là thời điểm mở cửa sổ bảo trì đầu tiên sau khi sóng trước đã qua thời gian theo dõi (`20.release.wave-soak-hours-minor` 48 giờ cho bản phụ, `-patch` 24 giờ cho bản vá), và gửi thông báo tới TA qua `AnnouncementService`. Cửa sổ bảo trì do TA đặt (API-20-160, loại `RECURRING` hoặc `ONE_OFF`), dài 2 đến 6 giờ, ngoài giờ cao điểm 7:00 đến 17:00 ngày làm việc (ERR-20-059); mặc định thứ Bảy 22:00, 4 giờ (Q20-10). Nâng cấp khẩn bỏ chờ cửa sổ nhưng phải thông báo trước ≥ `20.upgrade.emergency-notice-hours` giờ (BR-20-033).

**Vòng nâng cấp.** `UpgradeTicker` chạy mỗi phút dưới ShedLock `upgrade:tick`, duyệt kế hoạch `RUNNING`. Với `tenant_upgrade` `PENDING` đến hạn và sóng `RUNNING` (tối đa 5 tenant cùng lúc để giới hạn tải Argo CD): đặt `IN_WINDOW`, bật dải `MAINTENANCE` ở `EnforcementView` (ghi bị chặn với ERR-20-118) và phát EVT-20-15; chuyển `UPGRADING` rồi gọi `TenantConfigApi.requestReleasePin` để `GitOpsConfigWriter` commit `release.yaml` mới (thẻ phiên bản và digest ảnh trong overlay Kustomize của tenant); `ArgoStatusPoller` theo dõi tới `Synced` và `Healthy`, lỗi đồng bộ thì `FAILED` với ERR-20-109. Sau đó `VERIFYING` trong `20.release.verify-minutes` (30): `UpgradeVerifier` chạy `runLite` (đăng nhập và API mẫu), rồi theo dõi tỷ lệ 5xx của tenant; đạt thì `DONE`, bỏ dải bảo trì, phát EVT-20-15; không đạt thì `FAILED` với ERR-20-112. Thử lại một tenant (API-20-127) chỉ từ `FAILED`.

**Canh sóng.** `WaveGuard` chạy mỗi phút cho sóng `RUNNING`: nếu có tenant `FAILED`, hoặc tỷ lệ 5xx gộp của các tenant trong sóng (từ khi sang `IN_WINDOW`) vượt `20.release.wave-error-threshold-percent` (2%) với mẫu tối thiểu 200 lượt gọi (Q20-24), thì kế hoạch và sóng `PAUSED` kèm `pause_reason`, ghi `error_percent`, cảnh báo PA và PO. Độ trễ từ vượt ngưỡng tới dừng ≤ 5 phút (NFR-20-016): chu kỳ một phút cộng độ trễ Mimir. Tiếp tục khi sóng dừng do ngưỡng cần PA xác nhận đã xử lý (ERR-20-057). Tenant chuyển `SUSPENDED` hoặc `MERGING` trong lúc chờ thì `TenantStatusListener` đặt nâng cấp `SKIPPED` (bỏ khỏi sóng).

**Quay lui.** `RollbackService` quay lui một tenant (từ `FAILED`) hoặc cả sóng (từ `DONE`) bằng cách ghi lại phiên bản trước vào `release.yaml`, theo dõi Argo CD như nâng cấp, kết quả `ROLLED_BACK`. Phiên bản có thành phần `SCHEMA` đã chạy pha thu hẹp (`CONTRACT`) của migration mở rộng rồi thu hẹp thì không quay lui được (ERR-20-058); các thay đổi lược đồ trước đó chỉ ở pha mở rộng (`EXPAND`), tương thích ngược, nên quay lui thường an toàn. Hủy kế hoạch chưa chạy (API-20-125) chỉ đặt `CANCELLED`.

### 4.16. Registry tenant cho phân hệ khác (`TenantRegistryApi`)

::: dac-ta
**Mục đích.** Trả lời nhanh và ổn định cho mọi phân hệ câu hỏi "tenant nào tồn tại, đang ở trạng thái nào, bật phân hệ nào, hạn mức hiệu lực và cách định tuyến ra sao", sao cho PH-20 dừng hay chậm cũng không làm data plane ngừng.

**Lớp chính.** `TenantRegistryApi` (REST nội bộ), `TenantRegistry` (giao diện trong tiến trình), `RegistryCache`, `EnforcementView`, `RegistryInvalidator`, `DashboardQuery`, thư viện khách `tenant-registry-client`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (tối thiểu hai bản sao); thư viện khách chạy trong các DU khác.

**FR hiện thực.** FR-20-037, 065, 066, 067; BR-20-021, 026, 036; NFR-20-003, 004, 017.

**Giao diện vào.** API-20-162…165 (`/internal/tenant/v1`), API-20-142, API-20-129 (bảng điều khiển); scope `tenant:registry-read`.

**Phụ thuộc ra.** Valkey (bộ đệm và kênh vô hiệu), `pg-core`.

**Dữ liệu.** `tenant`, `tenant_module`, `tenant_quota`, `tenant_platform_config`, `merge_plan` (bảng chuyển tiếp), `tenant_upgrade` (cờ bảo trì).

**Sự kiện.** Nghe nội bộ `TenantStatusChanged`, EVT-20-07, 08, 09 để vô hiệu bộ đệm; phân hệ khác nghe EVT-20-04.

**Lỗi và xử lý.** ERR-20-002, 104; và các mã data plane `ERR-20-001`, 101, 102, 103, 115, 118 do phân hệ thực thi dựa trên bản ghi registry.

**Quan sát.** `dh_tenant_registry_requests_total{endpoint,result}`, `dh_tenant_registry_latency_seconds`, `dh_tenant_registry_cache_hit_ratio`, `dh_tenant_registry_invalidations_total`.
:::

Chi tiết thiết kế:

**Bốn lớp đệm.** Registry được thiết kế để phục vụ ≥ 500 lượt mỗi giây ở p99 ≤ 50 ms (NFR-20-003) và để sống sót khi PH-20 hỏng. Lớp 1 là bộ nhớ cục bộ của PH-20 (Caffeine, 60 giây, theo mã tenant); lớp 2 là Valkey với khóa `PLATFORM:ph20:registry:{tenant}`; lớp 3 là thư viện khách trong mỗi DU gọi, đệm theo `ETag` và `Cache-Control: max-age = 20.registry.cache-seconds` (60 giây), gửi `If-None-Match` nên đa số lượt trả `304`; lớp 4 là chế độ "dùng bản cũ khi lỗi" (`stale-if-error`) của thư viện khách: PH-20 không trả lời thì giữ bản đã đệm (tối đa 15 phút) và đánh dấu quá hạn bằng chỉ số, vì tenant đã biết thường không đổi trạng thái; tenant lạ (chưa từng thấy) bị từ chối. Bản ghi registry nhỏ (trạng thái, chế độ cách ly, realm, host, tiền tố, cờ bảo trì, danh sách phân hệ kèm trạng thái, `version`), nên phục vụ 40 tenant chỉ cần vài chục KB.

**Vô hiệu bộ đệm.** Mọi thay đổi trạng thái, phân hệ, cấu hình, hạn mức làm tăng `version` của bản ghi trong cùng giao dịch; sau commit, `RegistryInvalidator` xóa khóa Valkey và phát lên kênh Pub/Sub `PLATFORM:ph20:registry:inval` để các bản sao `api` xóa lớp 1. Phân hệ khác nhận EVT-20-04, 07, 08, 09 và xóa lớp 3 của mình. Nếu sự kiện thất lạc, lớp 3 vẫn tự làm mới sau tối đa 60 giây. Để hiệu lực tạm ngừng ≤ 60 giây (NFR-20-004) không phụ thuộc giá trị `20.registry.cache-seconds` (miền 10…60 giây), PH-03 và thư viện khách giữ giới hạn cứng 60 giây cho trường `status` và thăm dò lại sau 15 giây khi nhận cờ "đang chuyển trạng thái"; ghi nhận ở rủi ro R-06 và Phụ lục A.

**Enforcement.** API-20-164 trả `EnforcementView` cho PH-03, 04, 10: hạn mức hiệu lực từng tài nguyên, host và tiền tố API công bố, bảng chuyển tiếp sau sáp nhập (`API_CONTEXT_PATH`), cờ `maintenance`, `readOnly`, `status`. Dữ liệu dựng từ `tenant_quota`, `tenant_platform_config`, `merge_participant_run`, `tenant_upgrade` bằng một truy vấn có chỉ mục, không tính lại hạn mức (đã lưu ở `tenant_quota`).

**Thực thi trạng thái.** PH-20 không chặn lượt gọi: PH-03 và các phân hệ dùng bản ghi registry để trả `ERR-20-001` (tạm ngừng, trừ API thiết yếu chỉ đọc khi `20.suspend.essential-api-allowed` bật), `ERR-20-101` (`PROVISIONING`, `FAILED`), `ERR-20-102` (`DECOMMISSIONED`), `ERR-20-103` (phân hệ chưa bật), `ERR-20-115` (ghi vào `MERGED`) và `ERR-20-118` (đang bảo trì nâng cấp). Tài khoản PA, PO được qua để hỗ trợ và mọi lượt đó có kiểm toán.

**Bảng điều khiển nền tảng.** `DashboardQuery` (API-20-129) tổng hợp số tenant theo trạng thái, lần chạy saga đang mở, cảnh báo hạn mức mở, lệch cấu hình, kế hoạch nâng cấp, kết quả kiểm thử rò rỉ gần nhất, công suất; truy vấn chỉ đọc qua `ph20_ro` hoặc phiên `PLATFORM`, bộ đệm 30 giây, p95 ≤ 1,5 giây (NFR-20-006).

### 4.17. Chính sách tiếp nhận truy cập liên tenant (`CrossTenantPolicyService`)

::: dac-ta
**Mục đích.** Cho phép mỗi tỉnh quy định điều kiện để vai trò nền tảng vào dữ liệu của tỉnh (cho ghi hay không, có cần chấp thuận trước không, thời hạn tối đa, ai được báo), và cho phép PH-12 đọc chính sách đó khi cấp quyền; PH-20 không cấp quyền truy cập.

**Lớp chính.** `CrossTenantPolicyService`, `CrossTenantPolicyValidator`, `CrossTenantAccessLogQuery`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-20-023, 024; BR-20-012; SEC-85.

**Giao diện vào.** API-20-137…139 (tỉnh), API-20-165 (PH-12 đọc); `PERM-20-settings`, vai SO và AU đọc, scope `tenant:registry-read`.

**Phụ thuộc ra.** PH-13 (truy vấn chuỗi kiểm toán của tenant cho nhật ký truy cập), `GitOpsConfigWriter` (chính sách vào cài đặt tỉnh), `OpsClient`.

**Dữ liệu.** `cross_tenant_policy` (phiên bản có `version`), `tenant_config_version`.

**Sự kiện.** EVT-20-09 với `changeKind = CROSS_TENANT_POLICY` để PH-12 vô hiệu bộ đệm chính sách.

**Lỗi và xử lý.** ERR-20-004, 005, 027.

**Quan sát.** `dh_tenant_cross_tenant_policy_changes_total`, `dh_tenant_cross_tenant_policy_require_approval`.
:::

Chi tiết thiết kế:

Chính sách gồm `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours`, người nhận thông báo. `CrossTenantPolicyValidator` kiểm `maxHours` ≤ `min(20.cross-tenant.max-hours, 4)` (trần BR-12-032, ERR-20-027) và người nhận thông báo là đầu mối hoặc người dùng `ACTIVE` của tỉnh (ERR-20-004). Chỉ TA có `PERM-20-settings` sửa; mỗi lần lưu là phiên bản mới có `If-Match` (ERR-20-005 khi lệch) và đi qua đường GitOps như cài đặt tỉnh. Từ lần cấp quyền kế tiếp PH-12 áp chính sách: `requirePriorApproval = true` thì yêu cầu truy cập cần thêm TA của tỉnh chấp thuận ngoài người duyệt nền tảng; `allowWrite = false` thì chỉ cấp quyền đọc. Ngoại lệ sự cố an ninh mức 1 (nền tảng vào đọc tối đa 1 giờ kèm thông báo tức thời dù `allowRead = false`) là hằng của mã, không tắt được, kèm kiểm toán đầy đủ; xác nhận ở Q20-18. Nhật ký truy cập (API-20-139) đọc từ chuỗi kiểm toán của chính tenant ở PH-13, nơi PH-12 ghi mỗi truy cập liên tenant với lý do và mã phiếu (SEC-85); lỗi tìm thấy hay không đều trả `404` thống nhất khi người gọi không thuộc tỉnh.

### 4.18. Kiểm thử rò rỉ chéo tenant định kỳ (`LeakTestScheduler`)

::: dac-ta
**Mục đích.** Mỗi đêm chứng minh rằng không API công bố nào của nền tảng để lộ dữ liệu giữa hai tenant, và chứng minh trước khi một tenant mới được kích hoạt (SEC-87).

**Lớp chính.** `LeakTestScheduler`, `LeakProbeCatalog`, `LeakFixtureSeeder`, `LeakProbeRunner`, `LeakReportWriter`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker`.

**FR hiện thực.** FR-20-070, FR-20-012 (ca rò rỉ của `S16`), FR-20-067; BR-20-038; NFR-20-019.

**Giao diện vào.** API-20-132…134; `PERM-20-admin`, `PERM-20-read`; lịch `20.leak-test.schedule`.

**Phụ thuộc ra.** PH-03 (danh mục API công bố), PH-12 (tài khoản kiểm thử `leak-{runId}`), APISIX, PH-13 và PH-18 (mở sự cố mức 1), tenant kiểm thử `T90…T99`.

**Dữ liệu.** `leak_test_run`, `file_object` (báo cáo), `smoke_test_result`.

**Sự kiện.** Không riêng; phát hiện rò rỉ phát EVT-20-02 ở ngữ cảnh khởi tạo hoặc mở sự cố ở PH-18.

**Lỗi và xử lý.** ERR-20-065, 111, 062.

**Quan sát.** `dh_tenant_leak_test_cases_total{result}`, `dh_tenant_leak_coverage_ratio`, `dh_tenant_leak_test_duration_seconds`.
:::

Chi tiết thiết kế:

Lịch mặc định 01:00 hằng đêm (`20.leak-test.schedule`), ShedLock `leak:nightly`. `LeakFixtureSeeder` gieo dữ liệu đánh dấu (một tài nguyên mồi cho mỗi loại đối tượng) ở từng cặp tenant kiểm thử trong `T90…T99` (BR-20-038; tenant khác là ERR-20-065). `LeakProbeCatalog` lấy danh mục API công bố từ PH-03 và OpenAPI đã duyệt của các API nội bộ, gắn mỗi API với ít nhất một ca (kỳ vọng `404` đúng SEC-87 để không lộ sự tồn tại, kể cả khi gọi với tham số `tenantId` giả). `LeakProbeRunner` gọi mọi API bằng danh tính tenant nguồn với tài nguyên của tenant đích, tối đa 8 luồng, để toàn bộ ≤ 60 phút (NFR-20-019); API chỉ nền tảng ghi `SKIPPED` kèm lý do. Kiểm thêm ACL âm tính của Kafka, bucket và đường dẫn OpenBao (SEC-82). Phủ 100% API công bố; tỷ lệ phủ thấp hơn là cảnh báo `dh_tenant_leak_coverage_ratio` < 1.

Bất kỳ phản hồi nào chứa dữ liệu đánh dấu là ERR-20-111: `leak_test_run` `FAILED` kèm danh sách ca, mở sự cố mức 1 ở PH-18 và PH-13, thông báo PO; không có đường bỏ qua tự động. Kết quả ghi `leak_test_run` (`trigger_type` là `SCHEDULE`, `MANUAL` hoặc `PRE_ACTIVATION`) và báo cáo chi tiết ở `file_object`. Không chạy trên `PROD` có dữ liệu thật (Q20-18); ca rò rỉ của `S16` chỉ dùng một tài nguyên mồi ở `T99` nên an toàn cho môi trường thật.

### 4.19. Outbox, Inbox và Idempotency (`shared.messaging`)

::: dac-ta
**Mục đích.** Bảo đảm mọi sự kiện đã phát đều có thay đổi nghiệp vụ tương ứng và ngược lại, mọi sự kiện nhận về xử lý đúng một lần, và mọi yêu cầu ghi có `Idempotency-Key` an toàn khi gửi lại.

**Lớp chính.** `OutboxWriter`, `InboxGuard`, `IdempotencyFilter`, `EventSchemaRegistry`, các consumer `OrgSyncConsumer`, `RealmChangedConsumer`, `CryptoShredConsumer`, `CapacityWarningConsumer`, `RedirectConfirmConsumer`, `LimitConfirmConsumer`.

**Đơn vị chạy.** `dh-platform` cả hai hồ sơ; consumer ở hồ sơ `worker`.

**FR hiện thực.** Mọi FR phát sự kiện; FR-20-056 (inbox); BR-20-039; NFR-20-020.

**Giao diện vào.** Header `Idempotency-Key` của mọi `POST`; topic tiêu thụ EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11.

**Phụ thuộc ra.** Debezium Outbox Event Router (ADR-059), Kafka, Apicurio Registry, Valkey.

**Dữ liệu.** `outbox`, `inbox_event`, `idempotency_key`.

**Sự kiện.** EVT-20-01…16 (phát); sáu sự kiện tiêu thụ ở trên.

**Lỗi và xử lý.** ERR-20-009 (khóa dùng cho yêu cầu khác), ERR-20-062; tin hỏng vào DLQ.

**Quan sát.** `dh_tenant_outbox_lag_seconds`, `dh_tenant_outbox_pending`, `dh_tenant_inbox_duplicates_total{consumer}`, `dh_tenant_idempotency_replays_total`.
:::

Chi tiết thiết kế:

**Outbox.** `OutboxWriter.write` yêu cầu giao dịch đang mở (`Propagation.MANDATORY`) và chèn một dòng `outbox` gồm `tenant_id`, `event_id`, `topic`, `aggregate_type`, `aggregate_id` (khóa thông điệp, giữ thứ tự theo đối tượng), `payload` Avro, `trace_id`. Ràng buộc `ck_outbox_topic` chỉ nhận 16 topic của EVT-20, topic kiểm toán `platform.obs.audit.recorded.v1` và `{tenant}.tenant.org.changed.v1` đúng tiền tố. Debezium chuyển lên Kafka với khóa phân vùng `tenantCode` và header CloudEvents `dhtenant`; mục tiêu p95 ≤ 5 giây (NFR-20-020). Sự kiện mang mã, trạng thái, số liệu tổng hợp, không mang dữ liệu cá nhân hay nội dung hợp đồng (BR-20-039). Bản ghi kiểm toán dùng cùng đường nhưng mang `tenant_id` của tenant bị tác động (SEC-85), nên vào đúng chuỗi băm của tỉnh.

**Inbox.** `InboxGuard.once(tenant, consumer, eventId, handler)` chèn `(tenant_id, consumer, event_id)` bằng `ON CONFLICT DO NOTHING` và chạy `handler` trong cùng giao dịch; trùng thì bỏ qua và đếm. Consumer lấy tenant từ tiền tố topic và đối chiếu với header `dhtenant`; lệch thì chuyển DLQ và cảnh báo an ninh (D03-10 §3). Offset chỉ commit sau khi giao dịch xong, nên dừng PH-20 không mất tin.

**Idempotency.** `IdempotencyFilter` hai tầng (ADR-041): Valkey 24 giờ cho đường nóng và bảng `idempotency_key` làm nguồn đúng, khóa `(tenant_id, client_id, request_method, request_path, idempotency_ref)`. Cùng khóa cùng băm thân thì trả lại phản hồi đã lưu; cùng khóa khác thân là ERR-20-009 (409); khóa đang `IN_PROGRESS` trả `409` kèm `Retry-After`. Bước saga dùng khóa lũy đẳng riêng `{runId}:{stepCode}` ở sổ bước, không đi qua bộ lọc này. Bảng dọn mỗi giờ theo hạn (outbox 3 ngày, inbox 14 ngày, khóa 24 giờ) bằng công việc của PH-18.

### 4.20. Bộ thích ứng gọi ra ngoài (`ExternalCallAdapter`)

::: dac-ta
**Mục đích.** Đặt thời gian chờ, thử lại, ngắt mạch, cách ly luồng và truyền dấu vết cho mọi lời gọi từ PH-20 sang hệ khác ở một chỗ, để mã nghiệp vụ không tự quyết và không có lời gọi nào chờ vô hạn.

**Lớp chính.** `ExternalCallAdapter` (bọc Resilience4j `TimeLimiter`, `Retry`, `CircuitBreaker`, `Bulkhead`), `CallClassifier`, và 11 client: `IamClient`, `ObsClient`, `RdmClient`, `KpiClient`, `OpsClient`, `BaoClient`, `ObjectStoreClient`, `GitClient`, `ArgoClient`, `MimirClient`, `ClusterClient`.

**Đơn vị chạy.** `dh-platform` cả hai hồ sơ.

**FR hiện thực.** Mọi FR gọi phân hệ hoặc hạ tầng khác; NFR-20-017.

**Giao diện vào.** Trong tiến trình; không có API.

**Phụ thuộc ra.** PH-12, 13, 07, 16, 18; OpenBao; Ceph RGW; Git; Argo CD; Mimir; Kubernetes API.

**Dữ liệu.** Không (trạng thái ngắt mạch trong bộ nhớ, đẩy ra chỉ số).

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-20-062 (phụ thuộc không khả dụng), ERR-20-024 (Git), ERR-20-109 (Argo CD); lỗi nghiệp vụ của bên gọi được chuyển nguyên mã.

**Quan sát.** `dh_tenant_outbound_calls_total{target,op,result}`, `dh_tenant_outbound_latency_seconds{target}`, `dh_tenant_outbound_breaker_state{target}`, `dh_tenant_outbound_retries_total{target}`.
:::

Chi tiết thiết kế:

Mỗi lời gọi khai báo loại: `READ` (thử lại tự do), `WRITE_IDEMPOTENT` (thử lại được vì có khóa lũy đẳng, ví dụ API-12-080 với `Idempotency-Key`) hoặc `WRITE_NON_IDEMPOTENT` (không tự thử lại, hệ gọi quyết định). `CallClassifier` đổi lỗi kỹ thuật thành `TRANSIENT` hoặc `PERMANENT` cho saga. Thông tin xác thực không nằm ở cấu hình: token máy lấy từ Keycloak realm `PLATFORM` bằng `client_credentials` với scope hẹp cho từng đích (`iam:realm-provision`, `obs:tenant-provision`, `platform.tenant.provision`, `kpi.ingest`, `event:topic-register`) và đệm tới gần hết hạn; thông tin xác thực S3, Argo CD, khóa ký là hợp đồng thuê ngắn hạn từ OpenBao. Mọi lời gọi mang `traceparent`, `Idempotency-Key` khi có, và đo thời gian theo đích. Bảng thời gian chờ và chính sách từng đích nằm ở mục 8.4. Mỗi client là một cổng (interface) kèm bản giả cho kiểm thử, để kiểm thử saga không cần PH-12 hay OpenBao thật.

### 4.21. Thuật toán

Năm thuật toán nhỏ mà cách hiện thực quyết định tính đúng. Mô tả ở dạng bước để kỹ sư và kiểm thử viên dựng ca kiểm thử.

#### 4.21.1. Chọn các bước chạy được

`SagaPlan.runnable(run)` nhận lần chạy với trạng thái từng bước và trả danh sách bước chạy được. Bước chạy được khi trạng thái `PENDING` và mọi bước tiền nhiệm ở `SUCCEEDED` hoặc `SKIPPED`. Tiền nhiệm cố định: `S02` sau `S01`; `S03` sau `S02`; `S04` sau `S03`; `S05` sau `S04`; `S06`, `S07`, `S08`, `S09`, `S10`, `S12` sau `S05`; `S11` sau cả sáu bước ấy; `S13` sau `S11`; `S14` sau `S13`; `S15` sau `S14`; `S16` sau `S15`; `S17` sau `S16`. Hàm thuần, không đọc ngoài tham số. Lần chạy chuyển `WAITING` khi không còn bước chạy được và còn bước `WAITING_REPORT`; chuyển `RUNNING` khi có bước chạy được; `SUCCEEDED` khi `S17` `SUCCEEDED` và mọi bước khác `SUCCEEDED` hoặc `SKIPPED`.

#### 4.21.2. Phân loại lỗi và giãn cách thử lại

Lỗi tạm thời gồm hết giờ, ngắt mạch mở, `502`, `503`, `504`, `429` và ERR-20-062. Lỗi vĩnh viễn gồm `400`, `403`, `404`, `409` do dữ liệu, `422`. Với lỗi tạm thời, lần thử thứ n dùng giãn cách 10 giây nhân 3 mũ (n trừ 1), tức 10, 30, 90 giây, cộng ngẫu nhiên ±20% để nhiều tenant cùng lỗi không dội cùng lúc; số lần tối đa là `20.provision.step-retry-max`. Hết lần thử hoặc quá `20.provision.timeout-minutes` thì lỗi trở thành quyết định của con người.

#### 4.21.3. Hạn mức hiệu lực và so ngưỡng

`effective = min(ceiling, max(contract, max(override đang ACTIVE tại thời điểm)))`, trong đó `ceiling` là trần của hồ sơ quy mô và ghi đè không có thì bỏ qua. Phần trăm sử dụng bằng `used / effective × 100`, làm tròn một chữ số thập phân; hạn mức hiệu lực bằng 0 (tài nguyên chưa cấp) thì không tính phần trăm và không cảnh báo. Cảnh báo mới khi `percent ≥ warn` hoặc `percent ≥ 100` mà chưa có cảnh báo mở cùng mức; đặt lại khi `percent < alert-reset` suốt 24 giờ liên tục.

#### 4.21.4. Tỷ lệ lỗi sóng

Với sóng w gồm các tenant t đã `IN_WINDOW` hoặc sau đó, tính `err(w) = Σ 5xx(t) / Σ total(t)` trên khoảng từ lúc `IN_WINDOW` của t đến hiện tại. Chỉ xét khi `Σ total(t) ≥ 200`. Dừng khi `err(w) × 100 > threshold` hoặc có `tenant_upgrade` `FAILED` trong sóng. Số 5xx và tổng lượt lấy từ Mimir theo nhãn `tenant` của APISIX, loại lượt từ chính kiểm tra khói và lượt trả `ERR-20-118` (bảo trì có chủ ý).

#### 4.21.5. Giờ làm việc của KPI-12

`leadWorkingHours = Σ` số giờ nằm trong khung làm việc (7:00 đến 17:00 ngày làm việc, trừ ngày nghỉ lễ do PH-18 cung cấp) giữa `declared_at` và `activated_at`, tính theo múi giờ Việt Nam. Mục tiêu KPI-12 là ≤ 1 ngày làm việc (tám giờ trong khung). Nếu PH-18 không cung cấp lịch thì dùng khung mặc định không có ngày lễ và gắn cờ `calendarFallback` vào số đo gửi PH-16 (Q20-19).

## 5. Biểu đồ tuần tự

Chín sơ đồ phủ các luồng nhiều bước hoặc nhiều thành phần của FRS: khởi tạo đủ 17 bước, thử lại và bù trừ, báo tiến độ bước bất đồng bộ, tạm ngừng lan xuống data plane, chấm dứt, sáp nhập đầu cuối, đổi hạn mức, nâng cấp theo sóng và ghi cấu hình GitOps kèm phát hiện lệch. Mỗi sơ đồ ghi FR liên quan và một đoạn nói điểm cần chú ý. Tên người tham gia là tên thành phần ở chương 4; thông điệp không dùng dấu chấm phẩy.

### 5.1. Khởi tạo tenant đủ 17 bước (FR-20-008, 012, 013, 014)

Sơ đồ cho thấy lần chạy `INITIAL` của tenant `T68` ở chế độ `SHARED` từ lúc PA bấm chạy tới lúc tenant `ACTIVE`, gồm một nhánh thử lại tự động ở `S03`, điểm rẽ nhánh sau `S05`, hai bước đồng bộ chạy song song với bốn bước chờ báo, và điểm hội tụ trước `S11`.

```{.mermaid caption="Khởi tạo tenant T68 đủ 17 bước với nhánh thử lại tự động (FR-20-008)"}
sequenceDiagram
  autonumber
  actor PA as Quản trị nền tảng
  participant API as API nền tảng
  participant W as ProvisioningWorker
  participant PG as ph20_tenant
  participant GIT as Git dh-tenant-config
  participant P12 as PH-12
  participant BAO as OpenBao
  participant S3 as Ceph RGW
  participant K as Kafka
  participant PX as PH-10, 03, 04, 06
  participant P13 as PH-13
  participant P07 as PH-07
  participant P16 as PH-16
  participant SM as SmokeTestRunner
  PA->>API: POST provisioning-runs cho T68 kèm Idempotency-Key
  API->>PG: kiểm sẵn sàng, tạo run PENDING và 17 bước, đánh SKIPPED bước không áp dụng
  API-->>PA: 202 runId
  W->>PG: giành ShedLock provision T68, run RUNNING
  W->>PG: S01 hồ sơ, hạn mức từ mẫu
  W->>GIT: S02 commit tenants/T68 có ký
  W->>P12: S03 API-12-080 tạo realm dh-t68
  alt PH-12 trả 503 ở lần đầu
    W->>W: chờ 10 giây, bước vẫn RUNNING, attempt 2
    W->>P12: S03 gọi lại cùng Idempotency-Key
  end
  P12-->>W: realm, client, quản trị tỉnh đầu tiên
  W->>BAO: S04 đường dẫn kv/dh/t68, chính sách, KEK dh-t68-pii
  W->>S3: S05 bucket dh-t68-files, exports, backup, audit
  W->>PG: bước điểm rẽ, S06 S09 S10 S12 sang WAITING_REPORT, ghi outbox EVT-20-01
  PG-->>K: EVT-20-01 qua Debezium
  par bước đồng bộ trong lúc chờ báo
    W->>PG: S07 SKIPPED vì SHARED
    W->>P13: S08 API-13-072 dựng quan sát và chuỗi kiểm toán
  and phân hệ tự khởi tạo
    K-->>PX: EVT-20-01
    PX->>API: API-20-166 báo S06 S09 S10 S12
    API->>PG: ghi báo cáo, đánh thức worker
  end
  Note over W,PG: điểm hội tụ, S06 đến S12 đều SUCCEEDED hoặc SKIPPED
  W->>P07: S11 API-07-073 gói danh mục nền
  W->>PG: S13 tổ chức cấp tỉnh từ ĐVHC COMMON
  W->>P16: S14 kế thừa bộ chỉ tiêu mẫu
  W->>PG: S15 EVT-20-07 cho từng phân hệ không lõi
  PX->>API: API-20-166 báo S15 từng phân hệ
  W->>SM: S16 kiểm tra khói bốn ca
  SM-->>W: LOGIN_ADMIN, API_SAMPLE, EVENT_SAMPLE, CROSS_TENANT_LEAK đạt
  W->>PG: S17 tenant ACTIVE, ghi outbox EVT-20-03
  W->>P16: API-16-030 thời gian khởi tạo KPI-12
  W-->>PA: SSE run-changed SUCCEEDED
```

Điểm cần chú ý: mọi dấu vết nằm ở sổ bước trước khi bước chạy nên worker chết ở bất kỳ điểm nào cũng chạy lại được; EVT-20-01 chỉ phát một lần, sau khi realm, bí mật và bucket đã có, nên phân hệ nhận sự kiện có đủ nền để tự khởi tạo; điểm hội tụ nằm trước `S11` nên danh mục nền chỉ được nạp khi quan sát, cổng và tích hợp đã sẵn sàng. Tổng thời gian mục tiêu ≤ 60 phút p95 (NFR-20-001); ngân sách từng đoạn ở mục 11.2.

### 5.2. Thử lại và bù trừ khi một bước lỗi (FR-20-010, 011)

Sơ đồ cho thấy lần chạy dừng ở `S09` vì PH-03 không báo kịp, PA có hai lựa chọn: thử lại từ bước lỗi hoặc hủy khởi tạo và bù trừ ngược, kể cả nhánh bù trừ lỗi.

```{.mermaid caption="Bước S09 quá hạn, thử lại hoặc hủy khởi tạo và bù trừ ngược (FR-20-010, 011)"}
sequenceDiagram
  autonumber
  actor PA as Quản trị nền tảng
  participant API as API nền tảng
  participant W as ProvisioningWorker
  participant C as RunCompensator
  participant PG as ph20_tenant
  participant K as Kafka
  participant P03 as PH-03
  participant X as Bên thực hiện các bước đã xong
  Note over W,PG: S09 đang WAITING_REPORT, timeout_at là 15 phút
  W->>PG: StepWatchdog thấy S09 quá hạn
  W->>PG: S09 FAILED ERR-20-106, run FAILED, tenant PROVISIONING sang FAILED
  PG-->>K: EVT-20-02 provisioning-failed
  W-->>PA: thông báo PH-18 và SSE run-changed FAILED
  alt PA chọn thử lại
    PA->>API: POST runs retry
    API->>PG: kiểm run FAILED và tenant FAILED, nếu sai ERR-20-018
    API->>PG: tenant sang PROVISIONING, run sang RUNNING, S09 sang PENDING attempt 2
    W->>PG: S09 WAITING_REPORT, ghi lại outbox EVT-20-05 cùng eventId
    PG-->>K: EVT-20-05 quota-changed
    K-->>P03: EVT-20-05
    P03->>API: đọc API-20-164 rồi báo API-20-166 S09 SUCCEEDED
    W->>PG: tiếp tục S11 đến S17 như mục 5.1
  else PA chọn hủy khởi tạo
    PA->>API: POST runs cancel
    API->>PG: run FAILED sang COMPENSATING
    C->>X: bù ngược theo step_order, S15 EVT-20-08, S08 API-13-073, S05 xóa bucket rỗng
    C->>X: S04 xóa đường dẫn và KEK chưa dùng, S03 xóa realm, S02 revert commit, S01 xóa mặc định
    alt bù trừ lỗi, ví dụ bucket chưa rỗng
      X-->>C: lỗi ở S05
      C->>PG: run về FAILED, trả ERR-20-019 cho yêu cầu
    else bù trừ xong
      C->>PG: phát EVT-20-04 DECOMMISSIONED cho PH-10, 03, 04 gỡ phần của mình
      C->>PG: run COMPENSATED rồi CANCELLED, tenant FAILED sang DECOMMISSIONED
    end
  end
```

Điểm cần chú ý: thử lại không chạy lại bước `SUCCEEDED`; với bước bất đồng bộ, thử lại phát lại sự kiện cùng `eventId` để phía nhận khử trùng, nên PH-03 không áp hai lần. Bù trừ ngược thứ tự thực hiện và phần bất đồng bộ được bù bằng một sự kiện chứ không bằng lời gọi từng phân hệ. Bù trừ lỗi không xóa tenant mà đưa lần chạy về `FAILED` để PA xử lý tay; dòng `tenant` không bao giờ bị xóa vì mã không được tái cấp.

### 5.3. Phân hệ báo tiến độ bước bất đồng bộ và hết hạn chờ (FR-20-008, 009)

Sơ đồ lấy bước `S06_EVENTING` làm ví dụ: PH-10 nhận sự kiện, tự khởi tạo phần của mình rồi báo về; nhánh báo trùng, báo sai trạng thái và PH-10 không báo đều được xử lý.

```{.mermaid caption="Báo tiến độ bước bất đồng bộ S06 qua API-20-166 và nhánh hết hạn (FR-20-008, 009)"}
sequenceDiagram
  autonumber
  participant K as Kafka
  participant P10 as PH-10
  participant RC as ProvisioningReportController
  participant PG as ph20_tenant
  participant W as ProvisioningWorker
  participant V as Valkey kênh SSE
  participant UI as dh-console UI-20-04
  K-->>P10: EVT-20-01 qua inbox khử trùng
  P10->>P10: FR-10-064 hạn mức, principal, ACL tiền tố, topic hệ thống, nhóm Apicurio
  P10->>RC: POST steps S06_EVENTING report SUCCEEDED kèm reportId
  RC->>RC: kiểm scope tenant:provision-report, ERR-20-104 nếu thiếu
  RC->>RC: kiểm người gọi đúng là PH-10 cho S06
  RC->>PG: đọc bước S06
  alt bước đang WAITING_REPORT
    RC->>PG: ghi reported_at, S06 SUCCEEDED, lũy đẳng theo reportId
    RC->>W: đánh thức worker
    RC->>V: đẩy step-changed và report-received
    V-->>UI: sự kiện SSE
    RC-->>P10: 200
  else báo trùng cùng trạng thái
    RC-->>P10: 200 không đổi gì
  else bước không còn WAITING_REPORT
    RC-->>P10: 409 ERR-20-105
  end
  Note over W,PG: nếu PH-10 không báo trong 15 phút
  W->>PG: StepWatchdog đặt S06 FAILED ERR-20-106
  W->>V: đẩy run-changed FAILED
```

Điểm cần chú ý: báo cáo là lũy đẳng theo `reportId` nên PH-10 gửi lại khi mất mạng không gây lỗi; người gọi được kiểm theo bước nên một phân hệ không báo thay phân hệ khác. SSE là kênh phụ: nếu trình duyệt không giữ được kết nối, giao diện chuyển sang kéo API-20-015 mỗi 5 giây.

### 5.4. Tạm ngừng tenant lan xuống PH-12 và PH-03 (FR-20-038, 066)

Sơ đồ cho thấy tạm ngừng có hiệu lực ở data plane trong 60 giây bằng ba đường song song, và PH-12 chậm không làm chậm hiệu lực.

```{.mermaid caption="Tạm ngừng tenant có hiệu lực ở APISIX trước khi PH-12 hoàn tất (FR-20-038)"}
sequenceDiagram
  autonumber
  actor PA as Quản trị nền tảng
  participant API as API nền tảng
  participant LS as LifecycleService
  participant PG as ph20_tenant
  participant RG as RegistryInvalidator
  participant K as Kafka
  participant P03 as PH-03 APISIX
  participant P04 as PH-04
  participant P10 as PH-10
  participant P12 as PH-12
  participant OPS as PH-18
  PA->>API: POST lifecycle-requests SUSPEND, lý do, mã phiếu, văn bản căn cứ
  API->>LS: kiểm trạng thái ACTIVE, không phải PLATFORM hay COMMON, lý do đủ dài
  LS->>PG: một giao dịch, đề nghị APPROVED rồi EXECUTING, tenant ACTIVE sang SUSPENDED
  LS->>PG: ghi tenant_status_history, outbox EVT-20-04, tăng version registry
  PG-->>LS: commit
  LS->>RG: xóa khóa Valkey, phát kênh vô hiệu
  par ba đường có hiệu lực
    PG-->>K: EVT-20-04 status-changed qua Debezium
    K-->>P03: EVT-20-04
    P03->>P03: xóa đệm, trả ERR-20-001 cho mọi API của tỉnh
  and
    K-->>P04: EVT-20-04
    P04->>P04: dừng luồng theo lịch của tenant
    K-->>P10: EVT-20-04
    P10->>P10: chặn sản xuất sự kiện từ HTTT
  and
    P03->>API: thăm dò API-20-164 mỗi 15 giây nếu mất sự kiện
  end
  LS->>P12: API-12-084 realm chỉ cho đăng nhập xem, chặn token máy
  alt PH-12 lỗi hoặc chậm
    LS->>PG: đề nghị giữ EXECUTING, tác vụ thử lại 1, 5, 15 phút
  else PH-12 nhận
    LS->>PG: đề nghị DONE
  end
  LS->>OPS: thông báo đầu mối và người dùng tỉnh, Idempotency-Key historyId và kênh
  LS-->>API: 200 kèm tenant SUSPENDED
```

Điểm cần chú ý: hiệu lực ở data plane không chờ PH-12 (hướng an toàn là chặn trước), nhờ ba đường độc lập: sự kiện, vô hiệu bộ đệm, thăm dò. Đo hiệu lực bằng ca kiểm thử từ lúc commit tới lúc lượt gọi đầu tiên nhận `ERR-20-001`, mục tiêu ≤ 60 giây (NFR-20-004). Khôi phục đi ngược lại với API-12-085 và không cần bốn mắt.

### 5.5. Chấm dứt tenant có bàn giao dữ liệu và xóa mật mã (FR-20-040, 041, 042)

Sơ đồ cho thấy lưới an toàn của chấm dứt: hai PA khác nhau, gói bàn giao đã giao, thời gian nguội, rồi các giai đoạn dọn dẹp, và xóa mật mã là bước cuối.

```{.mermaid caption="Chấm dứt tenant qua bốn mắt, bàn giao, thời gian nguội và xóa mật mã (FR-20-040 đến 042)"}
sequenceDiagram
  autonumber
  actor PA1 as PA lập đề nghị
  actor PA2 as PA duyệt
  participant API as API nền tảng
  participant LS as LifecycleService
  participant DX as DataExportService
  participant PG as ph20_tenant
  participant PH as Các phân hệ có dữ liệu
  participant TE as TerminateExecutor
  participant P12 as PH-12
  participant P13 as PH-13
  participant INF as OpenBao, Ceph RGW, Git
  participant P09 as PH-09
  participant K as Kafka
  PA1->>API: lập đề nghị TERMINATE, tenant đã SUSPENDED
  API->>LS: kiểm SUSPENDED, văn bản đủ, ERR-20-037 nếu không
  PA1->>API: gửi duyệt
  PA2->>API: duyệt, ERR-20-007 nếu là người lập hoặc người gửi
  LS->>PG: APPROVED, tự yêu cầu gói bàn giao nếu chưa có
  LS->>DX: tạo gói REQUESTED, phát lệnh xuất
  DX->>PH: lệnh xuất từng phân hệ
  PH->>DX: API-20-168 báo số bản ghi, kích thước, SHA-256
  DX->>PG: manifest ký, gói READY, EVT-20-16
  PA1->>API: cấp liên kết tải, xác nhận bàn giao kèm biên bản
  DX->>PG: gói DELIVERED, kiểm người xác nhận khác người duyệt
  Note over LS,PG: chờ hết 30 ngày nguội kể từ lúc tạm ngừng
  PA1->>API: execute kèm mã xác nhận
  API->>TE: kiểm đủ ba điều kiện, ERR-20-037 hoặc ERR-20-038 nếu chưa
  TE->>PG: giai đoạn 1, tenant DECOMMISSIONED, EVT-20-04
  PG-->>K: EVT-20-04, phân hệ gỡ tài nguyên, data plane trả ERR-20-102
  TE->>P12: giai đoạn 2, xóa realm
  TE->>P13: API-13-073 đóng chuỗi kiểm toán
  TE->>INF: giai đoạn 3, gỡ bucket, đường dẫn OpenBao, thư mục Git có ký
  TE->>P09: giai đoạn 4, FR-09-043 xóa mật mã KEK dh-t68-pii
  P09-->>K: EVT-09-21 crypto-shred completed
  K-->>TE: EVT-09-21
  TE->>PG: giai đoạn 5, đề nghị DONE
```

Điểm cần chú ý: mỗi giai đoạn lưu vào đề nghị để chạy lại được sau sự cố; chỉ giai đoạn 4 không đảo ngược và nó chỉ chạy khi gói đã `DELIVERED` và đã hết thời gian nguội. Chưa nhận EVT-09-21 thì đề nghị còn `EXECUTING` và bảng điều khiển hiện ERR-20-116. Phân hệ chưa báo gỡ xong sau 24 giờ không chặn mà sinh việc dọn ở PH-18.

### 5.6. Sáp nhập tenant đầu cuối (FR-20-045 đến 052)

Sơ đồ cho thấy sáp nhập tenant nguồn `T91` vào tenant đích `T90` từ chạy thử tới kết thúc chuyển tiếp, gồm vòng xử lý xung đột và điểm cutover.

```{.mermaid caption="Sáp nhập T91 vào T90 từ chạy thử, chuyển, xung đột, định danh, cutover tới kết thúc (FR-20-045 đến 052)"}
sequenceDiagram
  autonumber
  actor PA1 as PA lập kế hoạch
  actor PA2 as PA duyệt
  participant MC as MergeCoordinator
  participant PG as ph20_tenant
  participant P18 as PH-18 merge-transfers
  participant PM as Phân hệ tham gia
  participant P12 as PH-12
  participant P03 as PH-03
  participant K as Kafka
  PA1->>MC: lập kế hoạch T91 vào T90, ánh xạ, gợi ý tự động
  MC->>PG: merge_plan DRAFT, merge_mapping, mappingHash
  PA1->>MC: chạy thử dryRun
  MC->>P18: merge-transfers dryRun true cho từng phân hệ
  P18->>PM: xuất và kiểm nhập trên bản sao không ghi
  P18->>MC: API-20-167 báo số bản ghi và xung đột dự kiến
  MC->>PG: dryRunResult PASSED kèm mappingHash
  PA1->>MC: gửi duyệt
  PA2->>MC: duyệt, ERR-20-007 nếu cùng người, ERR-20-043 nếu chạy thử đã cũ
  PA1->>MC: start
  MC->>PG: T91 sang MERGING, kế hoạch TRANSFERRING
  PG-->>K: EVT-20-10 và EVT-20-04
  loop từng phân hệ theo thứ tự phụ thuộc, tối đa 4 song song
    MC->>P18: merge-transfers module, khóa mergePlanId, module, transfer
    P18->>PM: xuất, nhập có origin_tenant_id, kiểm đếm
    P18->>MC: API-20-167 báo tiến độ và số đếm
    MC->>MC: so xuất với nhập cộng bỏ qua, lệch thì ERR-20-113
  end
  opt có xung đột
    MC->>PG: kế hoạch CONFLICT_REVIEW
    PA1->>MC: quyết định từng xung đột, KEEP_TARGET, RENAME_SOURCE và các cách khác
    MC->>PG: kế hoạch về TRANSFERRING
  end
  MC->>PG: mọi phân hệ SUCCEEDED, kế hoạch IDENTITY_TRANSFER
  MC->>P12: API-12-045 kế hoạch rồi API-12-046 chuyển người dùng, cấp song song thông tin xác thực HTTT
  PA1->>MC: cutover
  MC->>PM: đặt T91 chỉ đọc, chạy lượt bù cuối theo updated_at
  MC->>PG: một giao dịch, T91 sang MERGED, merged_into_id T90, kế hoạch TRANSITION
  PG-->>K: EVT-20-11 và EVT-20-04
  K-->>P03: EVT-20-11
  P03->>P03: bật chuyển tiếp kèm header Deprecation và Sunset
  P03-->>K: EVT-03-10 xác nhận
  K-->>MC: EVT-03-10, ghi redirectActiveAt
  Note over MC,P03: chuyển tiếp 6 tháng, theo dõi 60 phút đầu tỷ lệ lỗi
  PA1->>MC: complete sau transition_until
  MC->>P12: thu hồi thông tin xác thực cũ
  MC->>PG: T91 sang DECOMMISSIONED, kế hoạch COMPLETED
  PG-->>K: EVT-20-12
```

Điểm cần chú ý: PH-20 chỉ điều phối và so đếm, không chạm dữ liệu của phân hệ khác; mọi bước chạy lại được vì khóa lũy đẳng là `{mergePlanId}:{module}`. Cutover là một giao dịch ngắn sau lượt bù cuối nên khoảng không nhất quán rất nhỏ; trước cutover kế hoạch hủy được và nguồn về `ACTIVE`, sau cutover thì không. Xung đột không bao giờ ghi đè tự động mà chờ quyết định của con người.

### 5.7. Đổi hạn mức có duyệt, đẩy xuống nơi thực thi và cảnh báo (FR-20-027, 028, 029)

Sơ đồ cho thấy đề nghị hạ `API_RPS` cần bốn mắt, cách hạn mức hiệu lực tới được APISIX, và nhánh cảnh báo khi sử dụng chạm ngưỡng.

```{.mermaid caption="Đổi hạn mức API_RPS có duyệt bốn mắt, đẩy xuống APISIX và cảnh báo ngưỡng (FR-20-027 đến 029)"}
sequenceDiagram
  autonumber
  actor PA1 as PA đề nghị
  actor PA2 as PA duyệt
  participant QS as QuotaService
  participant PG as ph20_tenant
  participant GW as GitOpsConfigWriter
  participant QP as QuotaPublisher
  participant K as Kafka
  participant P03 as PH-03 APISIX
  participant UC as UsageCollector
  participant MI as Mimir
  participant OPS as PH-18
  PA1->>QS: đề nghị API_RPS của T68 từ 500 xuống 300, lý do và mã phiếu
  QS->>PG: đọc ảnh chụp mới nhất, đánh dấu belowUsage nếu dưới mức đang dùng
  QS->>PG: quota_change_request PENDING_APPROVAL
  PA2->>QS: duyệt, ERR-20-007 nếu là người đề nghị
  QS->>PG: một giao dịch, APPROVED, cập nhật tenant_quota push_status PENDING, outbox EVT-20-05
  QS->>GW: ghi quota.yaml qua GitOps
  PG-->>K: EVT-20-05 quota-changed
  K-->>P03: EVT-20-05
  P03->>QS: đọc API-20-164 hạn mức hiệu lực
  P03->>P03: áp limit-count theo nhãn tenant
  P03-->>K: EVT-03-11 gateway limit changed
  K-->>QP: EVT-03-11
  QP->>PG: push_status PUSHED, đề nghị DONE
  Note over QP,PG: quá 10 phút không xác nhận thì phát lại cùng eventId theo 1, 5, 15 phút
  loop mỗi giờ và mỗi 5 phút cho nhóm đo bằng Mimir
    UC->>MI: truy vấn gộp mọi tenant
    UC->>PG: chèn usage_snapshot ON CONFLICT DO NOTHING
    UC->>QS: đánh giá phần trăm so hạn mức hiệu lực
    alt từ 80 phần trăm và chưa có cảnh báo mở
      UC->>PG: quota_alert WARN_80 OPEN, outbox EVT-20-06
      UC->>OPS: thông báo PO và đầu mối TECHNICAL, TENANT_ADMIN
    end
  end
```

Điểm cần chú ý: PH-20 không bao giờ chặn lượt gọi; nó ghi giá trị hiệu lực, phát sự kiện, ghi Git và chờ nơi thực thi xác nhận. Hạ dưới mức đang dùng được cho phép sau duyệt nhưng chỉ chặn cấp mới, không cắt tài nguyên đã có (BR-20-014). Cảnh báo khử lặp bằng chỉ mục duy nhất nên số đo lặp lại không gửi thư lặp.

### 5.8. Nâng cấp theo sóng, dừng sóng và quay lui (FR-20-061, 062)

Sơ đồ cho thấy một tenant trong sóng 2 đi qua cửa sổ bảo trì, commit thẻ phiên bản, Argo CD áp, kiểm tra sau nâng cấp, và nhánh sóng tự dừng khi lỗi vượt ngưỡng rồi quay lui.

```{.mermaid caption="Nâng cấp tenant trong sóng 2 qua cửa sổ bảo trì, dừng sóng khi lỗi vượt ngưỡng và quay lui (FR-20-061, 062)"}
sequenceDiagram
  autonumber
  actor PA as Quản trị nền tảng
  actor TA as Quản trị tỉnh
  participant UO as UpgradeOrchestrator
  participant PG as ph20_tenant
  participant GW as GitOpsConfigWriter
  participant AR as Argo CD
  participant UV as UpgradeVerifier
  participant WG as WaveGuard
  participant MI as Mimir
  participant OPS as PH-18
  PA->>UO: lập kế hoạch cho phiên bản STABLE 1.4.0, ba sóng gợi ý
  UO->>PG: kiểm điều kiện từng tenant, ERR-20-056 nếu có kế hoạch khác
  PA->>UO: lên lịch
  UO->>OPS: thông báo TA lịch bảo trì và phiên bản
  TA->>UO: đặt cửa sổ thứ Bảy 22 giờ, 4 giờ, ERR-20-059 nếu trùng giờ cao điểm
  loop mỗi phút UpgradeTicker
    UO->>PG: tenant_upgrade PENDING đến hạn, sóng RUNNING
    UO->>PG: IN_WINDOW, dải MAINTENANCE, EVT-20-15
    UO->>GW: requestReleasePin ghi release.yaml
    GW->>AR: commit có ký, Argo CD đồng bộ
    UO->>PG: UPGRADING rồi VERIFYING
    UO->>UV: runLite đăng nhập và API mẫu, theo dõi 5xx trong 30 phút
    alt đạt
      UV-->>UO: đạt
      UO->>PG: DONE, bỏ dải bảo trì, EVT-20-15
    else không đạt
      UV-->>UO: ERR-20-112
      UO->>PG: FAILED
    end
  end
  WG->>MI: tỷ lệ 5xx gộp của sóng mỗi phút
  alt lỗi trên 2 phần trăm với mẫu từ 200 lượt, hoặc có tenant FAILED
    WG->>PG: kế hoạch và sóng PAUSED kèm pause_reason, error_percent
    WG->>OPS: cảnh báo PA và PO trong 5 phút
    PA->>UO: quay lui tenant đã nâng cấp
    UO->>GW: ghi lại release.yaml phiên bản trước
    UO->>PG: ROLLED_BACK
    Note over UO,PG: có thành phần SCHEMA đã qua pha CONTRACT thì ERR-20-058
  end
```

Điểm cần chú ý: việc áp phiên bản do Argo CD làm, PH-20 chỉ đổi thẻ trong Git và theo dõi; nhờ vậy nâng cấp và quay lui đều là một commit có ký, có lịch sử. Sóng dừng tự động và con người quyết định tiếp tục (ERR-20-057), không có chế độ tự tiếp tục. Tenant tạm ngừng hoặc đang sáp nhập bị bỏ khỏi sóng (`SKIPPED`).

### 5.9. Ghi cấu hình GitOps và phát hiện lệch (FR-20-018, 020, 022)

Sơ đồ cho thấy đường một chiều từ giao diện tới Git và Argo CD, nhánh đẩy bị từ chối, và vòng phát hiện lệch hằng giờ.

```{.mermaid caption="Ghi cài đặt tỉnh vào Git, Argo CD áp và phát hiện lệch hằng giờ (FR-20-018, 020, 022)"}
sequenceDiagram
  autonumber
  actor TA as Quản trị tỉnh
  participant API as API tỉnh
  participant SS as SettingsService
  participant PG as ph20_tenant
  participant GW as GitOpsConfigWriter
  participant G as Git dh-tenant-config
  participant AP as ArgoStatusPoller
  participant AR as Argo CD
  participant K as Kafka
  participant DD as DriftDetector
  participant PA as Quản trị nền tảng
  TA->>API: PUT settings kèm If-Match
  API->>SS: kiểm chặt hơn giới hạn nền tảng, ERR-20-023 nếu nới
  SS->>PG: lưu tenant_settings, tenant_config_version PENDING
  SS->>GW: write T68 SETTINGS lý do, mã phiếu
  GW->>GW: ShedLock config T68, sinh YAML, tính băm, bỏ qua nếu không đổi
  GW->>G: commit ph20 T68 có ký, trailer Dh-Idempotency
  alt đẩy bị từ chối vì không fast-forward
    G-->>GW: từ chối
    GW->>G: kéo lại, sinh lại từ CSDL, thử tối đa 3 lần
  end
  GW->>PG: git_commit_sha
  AP->>AR: hỏi Application tenant mỗi 10 giây
  AR-->>AP: Synced và Healthy
  AP->>PG: apply_status APPLIED
  AP->>K: outbox EVT-20-09 kèm configVersionNo và commitSha
  SS-->>API: 200 kèm phiên bản
  loop mỗi giờ DriftDetector cho từng tenant
    DD->>G: băm đầu nhánh tenants T68
    DD->>PG: băm bản chiếu CSDL
    DD->>AR: trạng thái Application
    alt có khác biệt
      DD->>PG: config_drift DRIFTED kèm differences
      PA->>API: resolve áp lại hoặc nhận vào Git
    else không đọc được Git hoặc Argo CD
      DD->>PG: config_drift UNKNOWN, không báo giả
    end
  end
```

Điểm cần chú ý: CSDL là nguồn sinh trong luồng ghi nhưng Git là trạng thái mong muốn có ký, nên khi đẩy xung đột thì sinh lại rồi thử lại thay vì ghi đè lịch sử. EVT-20-09 chỉ phát sau khi `APPLIED`, nên PH-03, PH-12 và `dh-console` không bao giờ thấy cấu hình chưa áp. Lệch không đọc được là `UNKNOWN`, không phải `DRIFTED`, để không sinh cảnh báo giả khi Git hoặc Argo CD tạm gián đoạn.

## 6. Đa tenant

PH-20 vừa là chủ của khái niệm tenant vừa là một phân hệ phải cô lập dữ liệu của tenant, nên chương này tách hai việc: PH-20 giữ ranh giới cho dữ liệu của chính nó (mục 6.1 đến 6.3) và PH-20 cấp ranh giới cho phân hệ khác (mục 6.4, 6.5).

### 6.1. Phiên làm việc theo tenant và năm chế độ RLS

Mọi truy cập `ph20_tenant` đi qua `TenantSession` do `platform.shared` cung cấp. Lớp này lấy tenant từ token đã xác thực (SEC-80), không bao giờ từ tham số đường dẫn hay thân yêu cầu, mở giao dịch rồi chạy `SET LOCAL app.tenant_id`, `app.actor_mode` và `app.actor_id`. Nhờ `SET LOCAL`, giá trị chết cùng giao dịch nên kết nối trả về bể không mang tenant cũ (kiểm bằng ca kiểm thử mục 12.3).

| Chế độ | Ai dùng | Điều kiện hàng thấy được | Bảng điển hình |
|---|---|---|---|
| `OWN` | Quản trị tỉnh, người dùng tỉnh | `tenant_id = current_setting('app.tenant_id')` | `tenant_settings`, `tenant_contact`, `organization` |
| `CTL` | Quản trị nền tảng trên API control plane | Mọi hàng của tenant được chọn rõ trong yêu cầu, có bản ghi kiểm toán | `tenant_contract`, `quota_change_request` |
| `TECH` | Tác vụ nền theo từng tenant | Tenant của tác vụ, vai `ph20_app` | `usage_snapshot`, `config_drift` |
| `PLAT` | Saga, bộ lập lịch, quét toàn nền tảng | Mọi tenant, chỉ vai `ph20_platform_app` | `provisioning_run`, `provisioning_step` |
| `PLATR` | Báo cáo toàn nền tảng, chỉ đọc | Mọi tenant, vai `ph20_ro` | Khung nhìn tổng hợp, ảnh chụp sử dụng |
| Riêng cho `tenant` | Mọi vai | Hàng của chính tenant, hoặc `PLAT`, hoặc `PLATR` | `tenant` |

: Chế độ RLS và bảng áp dụng (theo DDL `ph20_tenant.sql`)

Bảng `tenant` có chính sách riêng vì nó chính là danh sách tenant: người dùng tỉnh chỉ thấy hàng của tỉnh mình, quản trị nền tảng thấy tất cả qua `PLAT` hoặc `PLATR`. Dòng `PLATFORM` và `COMMON` thuộc dải tenant đặc biệt, không bao giờ trả cho API của tỉnh (BR-20-003).

### 6.2. Hai bể kết nối và ranh giới saga

`dh-platform-api` giữ bể `ph20_app` cho yêu cầu có tenant và bể `ph20_platform_app` cho thao tác toàn nền tảng; `dh-platform-worker` chỉ giữ bể thứ hai cộng bể `ph20_ro` cho báo cáo. Không vai nào có `BYPASSRLS`, và `ph20_owner` (chủ bảng, chạy di trú) không có đường kết nối từ ứng dụng. Saga chạy với phiên `PLATFORM` nhưng mỗi lệnh gọi ra ngoài mang tenant đích trong tiêu đề `X-Dh-Tenant` và trong khóa lũy đẳng, nên phân hệ nhận biết được tenant đang được khởi tạo mà không cần quyền đọc dữ liệu của tenant khác.

### 6.3. Tài nguyên ngoài CSDL

| Tài nguyên | Quy tắc cô lập | Nơi kiểm |
|---|---|---|
| Khóa Valkey | Tiền tố `{ma-tenant}:` cho đệm theo tenant, tiền tố `ph20:` cho khóa nền tảng; thư viện bao ngoài từ chối khóa không có tiền tố | `RegistryCache`, `IdempotencyFilter` |
| Kafka | Sự kiện vòng đời dùng topic `platform.tenant.*.v1`; sự kiện của tenant dùng `{ma}.tenant.*`; tiêu đề `dhtenant` phải khớp tenant của khóa thông điệp | `OutboxWriter`, `InboxGuard` |
| Ceph RGW | Bucket `dh-{ma}-files`, `-exports`, `-backup`, `-audit`; chính sách bucket chỉ cho danh tính của tenant đó | `S05` |
| OpenBao | Đường dẫn `kv/dh/{ma}/...`, chính sách theo tenant, KEK `dh-{ma}-pii` (SEC-88) | `S04` |
| Git | Thư mục `tenants/{ma}/` trong `dh-tenant-config`; trình ghi từ chối đường dẫn ngoài thư mục tenant và tự kiểm khi khởi động | `GitOpsConfigWriter` |
| Kubernetes | Namespace `dh-{ma}` ở `SHARED`, cụm riêng ở `DEDICATED_CLUSTER` | `S07` (Argo CD áp) |

: Cô lập tài nguyên ngoài CSDL theo tenant

### 6.4. Registry là nguồn sự thật về tenant

Phân hệ khác không lưu danh sách tenant riêng mà đọc `TenantRegistry` qua `tenant.api` (cùng một DU) hoặc API-20-164 (khác DU), với scope `tenant:registry-read`. Bộ đệm bốn lớp, hiệu lực tạm ngừng ≤ 60 giây và stale-if-error 15 phút ở mục 4.16; rủi ro đệm so với tạm ngừng ở R-06.

### 6.5. Truy cập liên tenant

Mặc định cấm. `CrossTenantPolicyService` (mục 4.17) tiếp nhận đề nghị truy cập liên tenant có thời hạn ≤ 4 giờ (`20.cross-tenant.max-hours`, trần BR-12-032), ghi chính sách vào OPA qua PH-12 và kiểm toán hai chiều. Hết hạn thì chính sách tự gỡ; không có truy cập liên tenant vĩnh viễn trong PH-20.

## 7. An toàn thông tin

### 7.1. Đối chiếu SEC-80 đến SEC-88

| SEC | Yêu cầu | Biện pháp trong PH-20 | Thành phần |
|---|---|---|---|
| SEC-80 | Tenant lấy từ token | `TenantSession` đọc claim, bỏ qua mọi trường tenant do khách gửi; API control plane chọn tenant đích qua đường dẫn nhưng phải qua kiểm quyền `PERM-20-*` | `TenantSession`, bộ lọc xác thực |
| SEC-81 | RLS `FORCE` | 45 bảng bật `FORCE ROW LEVEL SECURITY`, vai ứng dụng không `BYPASSRLS`, kiểm khi khởi động | DDL, `ReadinessChecker` |
| SEC-82 | Cô lập Kafka, S3, Valkey, OpenBao | Bảng 6.3, mỗi bước `S04`, `S05` tạo chính sách chỉ cho tenant đó | `StepExecutor` |
| SEC-83 | Cô lập runtime | Namespace hoặc cụm riêng, NetworkPolicy mặc định chặn, do Argo CD áp | `S07` |
| SEC-84 | Cô lập quan sát | Nhãn `tenant` bắt buộc trên chỉ số, log và trace; Grafana tách thư mục theo tenant | mục 10 |
| SEC-85 | Liên tenant chỉ qua chính sách | Mục 6.5, bí mật chỉ tham chiếu OpenBao (NFR-20-024) | `CrossTenantPolicyService` |
| SEC-86 | Hạn mức | `QuotaService` tính hiệu lực, nơi thực thi áp; PH-20 không tin giá trị khách gửi | mục 4.7 |
| SEC-87 | Kiểm thử rò rỉ | Hằng đêm, phủ 100% API công bố, bắt được là `ERR-20-111` | `LeakTestScheduler` |
| SEC-88 | KEK theo tenant | `dh-{ma}-pii` tạo ở `S04`, xóa mật mã ở bước chấm dứt giai đoạn 4 | `TerminateExecutor` |

: Đối chiếu SEC-80…88 với biện pháp hiện thực

### 7.2. Phân quyền, scope và tách nhiệm vụ

Quyền `PERM-20-*` theo ma trận FRS 3.2; vai `PLATFORM_ADMIN` (PA), `PRODUCT_OWNER` (PO), `PLATFORM_OPS`, `TENANT_ADMIN`. Ba scope cho tài khoản máy: `tenant:registry-read` (phân hệ đọc registry), `tenant:org-read` (đọc tổ chức), `tenant:provision-report` (báo tiến độ saga, chỉ cấp cho phân hệ có bước). Kiểm bốn mắt ở hai lớp: dịch vụ (`ApprovalGuard`) và ràng buộc `ck_*_four_eyes` của CSDL, nên đường tắt qua SQL cũng không qua được. Người lập, người gửi và người duyệt phải khác nhau; người xác nhận bàn giao khác người duyệt chấm dứt.

Khi người gọi không có quyền với tenant, API trả 404 thay vì 403 để không lộ sự tồn tại của tenant; riêng `ERR-20-001` (tenant tạm ngừng) trả 403 vì người gọi đã biết tenant của mình.

### 7.3. Bí mật, ký và mật mã

| Chủ đề | Quy tắc |
|---|---|
| Bí mật | Không nằm trong `ph20_tenant`, Git, log hay biến môi trường; chỉ có tham chiếu `kv/dh/{ma}/...`, `db_route_ref`, `cluster_ref`. Tài khoản gọi ra lấy thông tin xác thực ngắn hạn từ OpenBao khi cần |
| Ký commit | `svc-ph20-gitops` ký qua OpenBao transit, khóa không rời OpenBao (Q20-21 về kỹ thuật ký); kho từ chối commit không ký |
| Kênh nội bộ | mTLS giữa DU và các phân hệ; API-20-166, 167, 168 chỉ nhận scope đúng và người gọi đúng bước |
| Dữ liệu cá nhân | Cột nhạy cảm của hợp đồng và đầu mối mã hóa bằng KEK của tenant ở tầng ứng dụng; log che số điện thoại và thư điện tử |
| Gói bàn giao | Manifest ký, băm SHA-256 từng tệp, liên kết tải hết hạn 24 giờ, mã hóa (Q20-29) |
| Xóa mật mã | Chỉ sau gói `DELIVERED` và hết 30 ngày nguội; không đảo ngược |

: Bí mật, ký và mật mã

### 7.4. Kiểm toán và tải tệp

Mọi thao tác thay đổi ghi `audit_event` cùng giao dịch với dữ liệu, kèm lý do (≥ `20.lifecycle.reason-min-length` ký tự), mã phiếu, người thực hiện và giá trị trước sau đã che; chuỗi băm do PH-13 giữ (NFR-20-018). Tệp nhập tổ chức: tối đa 10 MB và `20.org.import-max-rows` dòng, quét mã độc trước khi đọc, ô bắt đầu bằng `=`, `+`, `-`, `@` được thêm tiền tố `'` khi xuất để chống chèn công thức CSV. Thao tác nguy hiểm trên giao diện (chấm dứt, sáp nhập, đổi cách ly) yêu cầu xác thực bước hai (step-up) theo giả định GĐ-05 do PH-12 thực hiện.

### 7.5. Các mối đe dọa chính

| Mối đe dọa | Biện pháp | Dư lượng |
|---|---|---|
| Quản trị nền tảng đơn lẻ xóa tenant | Bốn mắt, tạm ngừng trước, bàn giao, nguội 30 ngày | Hai PA thông đồng, giảm bằng cảnh báo cho PO |
| Commit cấu hình giả mạo vào Git | Kho chỉ nhận commit ký, DriftDetector so băm | Khóa ký lộ, giảm bằng luân chuyển khóa |
| Phân hệ báo giả tiến độ saga | Kiểm scope và người gọi đúng bước, lũy đẳng theo `reportId` | Phân hệ bị chiếm quyền, ghi kiểm toán |
| Rò rỉ chéo do thiếu `tenant_id` ở truy vấn mới | RLS cưỡng chế, kiểm thử rò rỉ hằng đêm, kiểm tra kiến trúc ArchUnit | Chậm tới đêm kế |
| Tải tệp độc hại | Giới hạn kích thước, quét mã độc, không thực thi nội dung | Mã độc chưa có chữ ký |
| Lộ sự tồn tại tenant | 404 cho tenant không có quyền | Dò qua thời gian phản hồi, giảm bằng phản hồi đồng đều |

: Mối đe dọa chính và biện pháp

## 8. Máy trạng thái, lỗi, thử lại và nhất quán

### 8.1. Máy trạng thái tenant

Máy trạng thái hiện thực mở rộng sáu trạng thái của D03-10 mục 5.1 bằng hai chuyển `FAILED → DECOMMISSIONED` (hủy khởi tạo) và `MERGING → ACTIVE` (hủy sáp nhập trước cutover); cả hai ghi ở Phụ lục A. Mọi chuyển đi qua một cổng duy nhất `TenantTransitions.apply(tenant, event, actor)` ở gói `tenant.profile`: kiểm bảng 8.3, đổi trạng thái, ghi `tenant_status_history`, ghi outbox EVT-20-04 trong cùng giao dịch, tăng phiên bản registry. Không lớp nào khác được `UPDATE tenant SET status`; ArchUnit kiểm điều này (mục 12.2).

```{.mermaid caption="Máy trạng thái tenant và thành phần thực hiện chuyển (DD-01)"}
stateDiagram-v2
  [*] --> PROVISIONING: TenantService tạo, FR-001
  PROVISIONING --> ACTIVE: S17ActivateStep, kiểm tra khói đạt
  PROVISIONING --> FAILED: StepWatchdog hoặc StepExecutor hết lần thử
  FAILED --> PROVISIONING: ProvisioningOrchestrator thử lại
  FAILED --> DECOMMISSIONED: RunCompensator bù xong
  ACTIVE --> SUSPENDED: SuspendExecutor
  SUSPENDED --> ACTIVE: LifecycleService khôi phục
  ACTIVE --> MERGING: MergeCoordinator bắt đầu chuyển
  MERGING --> ACTIVE: Hủy kế hoạch trước cutover
  MERGING --> MERGED: CutoverService
  SUSPENDED --> DECOMMISSIONED: TerminateExecutor giai đoạn 1
  MERGED --> DECOMMISSIONED: MergeCoordinator kết thúc chuyển tiếp
  DECOMMISSIONED --> [*]
```

Điểm cần chú ý: `DECOMMISSIONED` là trạng thái cuối, dòng `tenant` không bao giờ bị xóa và mã không được tái cấp. Ở chấm dứt, trạng thái này đặt ở giai đoạn 1 để data plane dừng ngay; các giai đoạn sau dọn tài nguyên (FRS FR-20-042 đã khớp).

### 8.2. Máy trạng thái bước saga và lần chạy

Hai máy lồng nhau: lần chạy tóm tắt các bước, bước giữ chi tiết. Lần chạy `WAITING` khi mọi bước còn lại đều `WAITING_REPORT`; `FAILED` khi một bước hết lần thử hoặc quá hạn. Bù trừ đi theo `step_order` giảm dần và chỉ chạm bước `SUCCEEDED` hoặc `FAILED` có phần đã làm.

```{.mermaid caption="Máy trạng thái bước saga theo StepExecutor"}
stateDiagram-v2
  [*] --> PENDING
  PENDING --> RUNNING: Worker nhận, ghi started_at
  PENDING --> SKIPPED: Không áp dụng cho chế độ cách ly
  RUNNING --> SUCCEEDED: Đồng bộ trả thành công
  RUNNING --> WAITING_REPORT: Bước bất đồng bộ đã phát sự kiện
  WAITING_REPORT --> SUCCEEDED: API-20-166 báo SUCCEEDED
  WAITING_REPORT --> FAILED: Báo FAILED hoặc quá hạn 15 phút
  RUNNING --> FAILED: Hết lần thử tự động
  FAILED --> RUNNING: Quản trị nền tảng thử lại
  FAILED --> SKIPPED: Bỏ qua có lý do cho bước không bắt buộc
  SUCCEEDED --> COMPENSATING: Hủy khởi tạo
  FAILED --> COMPENSATING: Bù phần đã làm
  COMPENSATING --> COMPENSATED: Bù xong
  COMPENSATING --> FAILED: Bù lỗi
```

Điểm cần chú ý: chuyển `RUNNING → FAILED` chỉ xảy ra sau khi thử lại tự động 3 lần; chuyển `FAILED → SKIPPED` chỉ cho bước không bắt buộc và cần lý do (`S06`, `S09`, `S10`, `S12` không được bỏ qua vì phân hệ lõi nhận). Bước đã `SUCCEEDED` không bao giờ chạy lại khi thử lại cả lần chạy.

### 8.3. Bảng chuyển trạng thái hiện thực

Bảng liệt kê điều kiện kiểm (guard) và tác dụng phụ của từng máy. Mọi tác dụng phụ ghi sự kiện qua outbox trong cùng giao dịch chuyển; lỗi guard trả `ERR-20-006` trừ khi ghi khác.

| Máy | Chuyển | Guard | Tác dụng phụ | Thành phần |
|---|---|---|---|---|
| Tenant | `PROVISIONING → ACTIVE` | `S01…S16` thành công hoặc bỏ qua, kiểm tra khói đạt (`20.smoke.enabled`), có đủ hai đầu mối | EVT-20-03, KPI-12, mở API cho tỉnh | `S17ActivateStep` |
| Tenant | `PROVISIONING → FAILED` | Bước lỗi hết lần thử hoặc quá `20.provision.timeout-minutes` | EVT-20-02, thông báo PH-18 | `StepWatchdog` |
| Tenant | `FAILED → PROVISIONING` | Lần chạy `FAILED`, không còn lần chạy mở khác | Lần chạy về `RUNNING` | `ProvisioningOrchestrator` |
| Tenant | `FAILED → DECOMMISSIONED` | Bù trừ xong | EVT-20-04 | `RunCompensator` |
| Tenant | `ACTIVE → SUSPENDED` | Không phải `PLATFORM`, `COMMON`; lý do và phiếu đủ | EVT-20-04, vô hiệu bộ đệm, gọi PH-12 | `SuspendExecutor` |
| Tenant | `SUSPENDED → ACTIVE` | Không có đề nghị chấm dứt `EXECUTING` | EVT-20-04, PH-12 khôi phục | `LifecycleService` |
| Tenant | `ACTIVE → MERGING` | Kế hoạch `APPROVED`, tenant không ở kế hoạch khác (`ERR-20-041`) | EVT-20-10, EVT-20-04 | `MergeCoordinator` |
| Tenant | `MERGING → MERGED` | Mọi phân hệ `SUCCEEDED`, hết xung đột, định danh xong | EVT-20-11, ghi `merged_into_id` | `CutoverService` |
| Tenant | `SUSPENDED → DECOMMISSIONED` | Bốn mắt, gói `DELIVERED`, hết nguội | EVT-20-04, EVT-20-13 | `TerminateExecutor` |
| Run | `PENDING → RUNNING` | Giành khóa `provision:{tenantCode}` | Ghi `started_at` | `ProvisioningWorker` |
| Run | `FAILED → COMPENSATING` | Quản trị nền tảng hủy, `ERR-20-019` nếu đang bù | Bù ngược | `RunCompensator` |
| Đề nghị | `PENDING_APPROVAL → APPROVED` | Người duyệt khác người lập và người gửi (`ERR-20-007`) | Kích hoạt thực hiện | `ApprovalGuard` |
| Đề nghị | `EXECUTING → APPROVED` | Lỗi thử lại được | Tác vụ thử 1, 5, 15 phút | `LifecycleService` |
| Phân hệ | `DISABLED → ENABLING` | Phụ thuộc `REQUIRED` đã bật (`ERR-20-033`) | EVT-20-07 | `ModuleToggleService` |
| Phân hệ | `ENABLED → DISABLING` | Không phải lõi (`ERR-20-035`), không bị phụ thuộc (`ERR-20-034`) | EVT-20-08 | `ModuleToggleService` |
| Sáp nhập | `DRAFT → PENDING_APPROVAL` | Chạy thử `PASSED` còn mới (`ERR-20-043`) | Khóa ánh xạ | `MergePlanService` |
| Sáp nhập | `TRANSFERRING → IDENTITY_TRANSFER` | Kiểm đếm khớp (`ERR-20-113` nếu lệch) | Gọi PH-12 chuyển người dùng | `MergeCoordinator` |
| Sáp nhập | `TRANSITION → COMPLETED` | Qua `transition_until`, không còn lượt gọi cũ | EVT-20-12 | `MergeCoordinator` |
| Tổ chức | `ACTIVE → DISSOLVED` | Có tổ chức kế thừa nếu còn tham chiếu (`ERR-20-049`) | `{tenant}.tenant.org.changed` | `OrganizationService` |
| Phát hành | `PREVIEW → STABLE` | Đủ `20.release.stable-soak-days` không sự cố mức 1 (`ERR-20-054`) | EVT-20-14 | `ChannelService` |
| Nâng cấp | `PENDING → IN_WINDOW` | Tới cửa sổ, tenant `ACTIVE`, không `MERGING` | EVT-20-15, dải bảo trì | `UpgradeOrchestrator` |
| Nâng cấp | `VERIFYING → DONE` | Đăng nhập và API mẫu đạt, 5xx dưới ngưỡng trong `20.release.verify-minutes` | EVT-20-15 | `UpgradeVerifier` |

: Bảng chuyển trạng thái, điều kiện kiểm và tác dụng phụ

### 8.4. Thời gian chờ và thử lại theo đích gọi

Thử lại luôn có khóa lũy đẳng. Tự động thử lại chỉ cho lỗi tạm (HTTP 429, 502, 503, 504, hết thời gian); lỗi 4xx khác là lỗi vĩnh viễn, đưa ngay vào `FAILED`. Mỗi đích có bộ ngắt mạch `Resilience4j` riêng (mở sau 50% lỗi trên 20 lượt, nửa mở sau 30 giây), nên PH-12 hỏng không làm cạn luồng gọi PH-13.

| Đích | Lệnh gọi | Hết thời gian | Thử lại | Lũy đẳng | Khi hết thử |
|---|---|---|---|---|---|
| PH-12 | API-12-080 tạo realm (`S03`, trả `202`, chờ hoàn tất bằng EVT-12-13 hoặc thăm dò API-12-081) | 15 giây nhận `202`, rồi chờ tối đa 4 phút | 10, 30, 90 giây ±20%, tối đa `20.provision.step-retry-max` | `{runId}:S03_REALM` | Bước `FAILED`, `ERR-20-062` |
| PH-12 | API-12-084, 085 tạm ngừng, khôi phục | 15 giây | 1, 5, 15 phút | `{historyId}:iam` | Đề nghị giữ `EXECUTING`, hiệu lực data plane không chờ |
| PH-12 | API-12-045, 046 định danh sáp nhập | 120 giây | 3 lần | `{mergePlanId}:identity` | Kế hoạch `FAILED` |
| PH-13 | API-13-072 dựng quan sát (`S08`) | 60 giây | 3 lần, `ERR-13-014` cũng thử lại | `{runId}:S08_OBSERVE` | Bước `FAILED` |
| PH-13 | API-13-073 đóng chuỗi | 30 giây | 3 lần | `{tenantId}:close-audit` | Giai đoạn chấm dứt chờ, thử tiếp |
| PH-07 | API-07-073 danh mục nền (`S11`) | 120 giây | 3 lần | `{runId}:S11_CATALOG` | Bước `FAILED` |
| PH-16 | API-16-030 KPI thời gian khởi tạo | 15 giây | 3 lần, không chặn kích hoạt | `{runId}:kpi` | Ghi cảnh báo, không `FAILED` |
| PH-18 | Thông báo, merge-transfers | 15 giây, 600 giây (chuyển dữ liệu) | 3 lần, 1 phút giữa các lần | `{mergePlanId}:{module}` | Chuyển sang `FAILED` hoặc việc dọn |
| Git | Đẩy commit | 30 giây | Kéo lại, sinh lại, tối đa 3 lần | `Dh-Idempotency` | `ERR-20-024` |
| Argo CD | Hỏi trạng thái | 10 giây | Hỏi mỗi 10 giây tới 5 phút | không cần | `ERR-20-109` |
| OpenBao | `S04` và ký commit | 10 giây | 3 lần | tên đường dẫn cố định | Bước `FAILED` |
| Ceph RGW | `S05` | 30 giây | 3 lần | tên bucket cố định | Bước `FAILED` |
| Mimir | Truy vấn sử dụng | 20 giây | Bỏ qua lượt, lượt sau bù | khóa chỉ mục duy nhất | `ERR-20-110`, đánh dấu ước lượng |

: Thời gian chờ và thử lại theo đích gọi

Bước bất đồng bộ có hạn chờ báo riêng `20.provision.step-timeout-minutes` (15 phút) và tổng hạn `20.provision.timeout-minutes` (60 phút); quá hạn tổng thì lần chạy `FAILED` với `ERR-20-108`. Thử lại bằng tay của quản trị nền tảng đặt lại bộ đếm `attempt` về 1 của bước lỗi, không đặt lại tổng hạn mà cộng thêm quỹ 30 phút cho lần thử lại (giả định GĐ-06).

### 8.5. Mã lỗi, nơi phát sinh và xử lý

Lỗi trả theo D00-04 (`application/problem+json`, trường `code`, `traceId`). Bảng nhóm theo vùng mã; cột xử lý là hành vi của PH-20, không phải của người gọi.

| Mã | HTTP | Nơi phát sinh (thành phần) | Xử lý |
|---|---|---|---|
| 001 | 403 | Bộ lọc yêu cầu, `TenantRegistryApi` | Từ chối mọi API của tỉnh tạm ngừng, ghi đếm `dh_tenant_requests_blocked_total` |
| 002, 004 | 404, 400 | Mọi controller | Trả ngay, không ghi kiểm toán thay đổi |
| 003, 011, 067 | 409 | `TenantService`, `OrganizationService`, `ReleaseService` | Từ chối, gợi ý bản ghi đang giữ mã |
| 005 | 412 | Mọi thao tác sửa | Trả phiên bản hiện hành, người dùng tải lại |
| 006 | 409 | `TenantTransitions` và các máy khác | Không đổi trạng thái, ghi cảnh báo nếu lặp |
| 007 | 403 | `ApprovalGuard` | Từ chối, ghi kiểm toán thử vượt quyền |
| 008 | 422 | Bộ kiểm lý do | Trả danh sách trường thiếu |
| 009 | 409 | `IdempotencyFilter` | Từ chối, khóa chỉ dùng lại cho cùng yêu cầu |
| 010, 035, 068 | 403, 422 | `TenantService`, `ModuleToggleService` | Bảo vệ tenant đặc biệt, phân hệ lõi, thuộc tính bất biến |
| 012, 013, 014, 015, 017, 063, 064 | 422 | `ReadinessChecker`, `TemplateService` | Chặn tạo hoặc chạy, trả điều kiện chưa đạt |
| 016, 041 | 409 | `ProvisioningOrchestrator`, `MergePlanService` | Chặn lần chạy hoặc kế hoạch thứ hai (kiểm cả bằng khóa dòng tenant) |
| 018, 019 | 409 | `ProvisioningOrchestrator`, `RunCompensator` | Không thử lại hoặc không bù được, giữ run `FAILED` cho xử lý tay |
| 020, 117 | 422, — | `SmokeTestRunner` | Tenant giữ `PROVISIONING`, bước `S16` `FAILED`, báo kèm ca lỗi |
| 021, 022 | 422 | `ContactService`, `ContractService` | Chặn kích hoạt và chặn lưu hợp đồng |
| 023, 025, 026, 027, 028, 060 | 422, 409 | `SettingsService`, `GitOpsConfigWriter`, `CrossTenantPolicyService` | Từ chối cấu hình ngoài giới hạn, không ghi Git |
| 024, 109 | 502, — | `GitOpsConfigWriter`, `ArgoStatusPoller` | Giữ `tenant_config_version` `PENDING`, thử lại, cảnh báo |
| 029, 030, 031 | 422 | `QuotaService` | Từ chối ngoài miền, hạ dưới mức đang dùng cần cờ xác nhận, ghi đè quá hạn |
| 032, 066 | 400, 422 | `UsageReportService` | Từ chối khoảng thời gian quá dài |
| 033, 034, 036 | 422, 409 | `ModuleToggleService`, `FeatureFlagService` | Chặn bật, tắt, cờ không áp dụng |
| 037, 038, 039 | 422, 410 | `LifecycleService`, `DataExportService` | Chặn chấm dứt, khôi phục khi chưa đủ điều kiện, gói hết hạn |
| 040, 042, 043, 044, 045, 046 | 422, 409 | `MergePlanService`, `MappingService`, `CutoverService` | Chặn từng bước sáp nhập, trả điều kiện thiếu |
| 047, 048, 049, 052 | 422, 409 | `OrganizationService` | Chặn chu trình, kế thừa sai, còn tham chiếu |
| 050, 051 | 422 | `OrgImportService` | Trả báo cáo dòng lỗi, không nhập lô còn lỗi |
| 053, 054, 055, 056, 059, 061 | 422, 409 | `ReleaseService`, `ChannelService`, `UpgradeOrchestrator` | Chặn phát hành, lên lịch không hợp lệ |
| 057, 058 | 409, 422 | `WaveGuard`, `RollbackService` | Sóng dừng chờ con người; không quay lui được vì đã qua pha CONTRACT |
| 062 | 503 | `ExternalCallAdapter` | Ngắt mạch, trả `Retry-After`, không ghi dở |
| 065 | 422 | `LeakTestScheduler` | Chỉ chạy trên tenant kiểm thử `T90…T99` |
| 101 | 503 | Registry, cổng | `PROVISIONING`, `FAILED`, trả `Retry-After` |
| 102 | 410 | Registry, cổng | `DECOMMISSIONED`, không thử lại |
| 103 | 503 | Registry, cổng | Phân hệ chưa bật cho tenant |
| 104 | 403 | Bộ lọc scope | Từ chối, ghi kiểm toán |
| 105 | 409 | `ProvisioningReportController` | Báo sai bước hoặc trạng thái, người gọi đọc lại API-20-015 |
| 106, 107, 108 | — | `StepWatchdog`, `ProvisioningWorker` | Bước hoặc run `FAILED`, thông báo PH-18 |
| 110 | — | `UsageCollector` | Ghi ước lượng, đánh dấu `is_estimate`, không ghi dòng thiếu |
| 111 | — | `LeakTestScheduler` | Cảnh báo mức cao, mở sự cố ATTT |
| 112, 118 | —, 503 | `UpgradeVerifier`, bộ lọc bảo trì | Nâng cấp `FAILED`, dải bảo trì trả 503 có `Retry-After` |
| 113, 114, 115 | —, 409 | `MergeCoordinator`, `ProvisioningReportController` | Không cutover khi lệch; tenant `MERGED` chỉ đọc |
| 116 | — | `TerminateExecutor` | Đề nghị giữ `EXECUTING`, chờ EVT-09-21 |

: Mã lỗi ERR-20 (viết gọn ba chữ số), nơi phát sinh và xử lý

### 8.6. Nhất quán dữ liệu giữa CSDL, Kafka, Git và nơi thực thi

| Cặp | Cơ chế | Điểm hội tụ |
|---|---|---|
| CSDL và Kafka | Outbox cùng giao dịch, Debezium phát, p95 ≤ 5 giây (NFR-20-020) | Sự kiện phát ít nhất một lần, phía nhận khử trùng bằng inbox theo `eventId` |
| CSDL và Git | CSDL sinh YAML, Git là mong muốn, `tenant_config_version` ghi `PENDING`, `APPLIED` | DriftDetector hằng giờ, lệch thì `DRIFTED` cho xử lý tay |
| Git và cụm | Argo CD áp ≤ 5 phút | `ArgoStatusPoller` ghi `apply_status`, EVT-20-09 chỉ sau `APPLIED` |
| PH-20 và phân hệ | Sự kiện lệnh rồi báo tiến độ qua API-20-166 | Hết hạn chờ thì bước `FAILED` và thử lại cùng `eventId` |
| PH-20 và nơi thực thi hạn mức | `push_status` `PENDING`, `PUSHED` theo xác nhận EVT-03-11 | Phát lại sau 10 phút, tối đa ba lần |
| Registry và người đọc | Phiên bản registry tăng cùng giao dịch, vô hiệu bằng sự kiện và thăm dò 15 giây | Hiệu lực ≤ 60 giây, đệm cũ tối đa 15 phút khi PH-20 mất kết nối (R-06) |

: Cơ chế nhất quán giữa các kho

Không có giao dịch phân tán. Ranh giới nhất quán mạnh chỉ là một giao dịch PostgreSQL; mọi thứ ngoài đó là nhất quán cuối cùng có điểm hội tụ và bộ đo độ trễ.

## 9. Cấu hình và tham số

### 9.1. Tham số `20.*`

Hai mươi chín khóa của FRS 8.2. Giá trị gốc đăng ký với PH-18; đổi có kiểm toán và có hiệu lực ≤ 60 giây không cần khởi động lại. Cột "Đọc ở" là thành phần chương 4 tiêu thụ khóa; cột "Cách áp" là cách thành phần nhận giá trị mới.

| Khóa | Mặc định | Miền | Đọc ở | Cách áp |
|---|---|---|---|---|
| `20.provision.timeout-minutes` | 60 | 30…240 | `StepWatchdog` | Lần chạy mới, run đang chạy giữ giá trị lúc tạo |
| `20.provision.step-timeout-minutes` | 15 | 5…60 | `StepWatchdog` | Bước mới |
| `20.provision.step-retry-max` | 3 | 0…10 | `StepExecutor` | Lần thử kế tiếp |
| `20.smoke.enabled` | true | true, false | `SmokeTestRunner` | Lần chạy mới; tắt thì ghi kiểm toán và cờ trên tenant |
| `20.quota.warn-percent` | 80 | 50…95 | `QuotaAlertEvaluator` | Lượt đánh giá kế |
| `20.quota.alert-reset-percent` | 75 | 40…90, nhỏ hơn ngưỡng cảnh báo | `QuotaAlertEvaluator` | Lượt đánh giá kế |
| `20.quota.override-max-days` | 30 | 1…90 | `QuotaService` | Đề nghị mới |
| `20.usage.snapshot-interval` | PT1H | PT15M…PT6H | `UsageCollector` | Lịch kế |
| `20.usage.retention-months` | 25 | 13…60 | `UsageCollector` (dọn phân vùng) | Lượt dọn kế |
| `20.suspend.essential-api-allowed` | false | true, false | `TenantRegistryApi`, bộ lọc | Vô hiệu bộ đệm ngay |
| `20.terminate.cooling-days` | 30 | 7…180 | `TerminateExecutor` | Đề nghị mới |
| `20.export.retention-days` | 90 | 30…365 | `DataExportService` | Gói mới |
| `20.merge.transition-months` | 6 | 1…12 | `MergePlanService` | Kế hoạch mới |
| `20.merge.transition-max-months` | 12 | 6…24 | `MergeCoordinator` | Lúc kéo dài |
| `20.release.stable-soak-days` | 14 | 3…60 | `ChannelService` | Lần chuyển kênh kế |
| `20.release.wave-error-threshold-percent` | 2 | 0,5…10 | `WaveGuard` | Mỗi phút, sóng đang chạy dùng giá trị mới |
| `20.release.wave-soak-hours-minor` | 48 | 12…168 | `WavePlanner` | Kế hoạch mới |
| `20.release.wave-soak-hours-patch` | 24 | 4…72 | `WavePlanner` | Kế hoạch mới |
| `20.release.verify-minutes` | 30 | 10…120 | `UpgradeVerifier` | Lần nâng cấp kế |
| `20.release.supported-minors` | 2 | 1…4 | `ReleaseService` | Lượt tính lại hằng ngày |
| `20.upgrade.emergency-notice-hours` | 2 | 1…24 | `MaintenanceWindowService` | Kế hoạch khẩn kế |
| `20.drift.check-interval` | PT1H | PT15M…PT24H | `DriftDetector` | Lịch kế |
| `20.org.import-max-rows` | 5000 | 100…20000 | `OrgImportService` | Tệp kế |
| `20.leak-test.schedule` | 01:00 hằng đêm | Biểu thức lịch | `LeakTestScheduler` | Lịch kế |
| `20.cross-tenant.max-hours` | 4 | 1…4 (trần BR-12-032) | `CrossTenantPolicyService` | Đề nghị mới |
| `20.dedicated-cluster.enabled` | false | true, false | `TemplateService`, `ReadinessChecker` | Tức thì |
| `20.registry.cache-seconds` | 60 | 10…60 (trần NFR-20-004) | `RegistryCache` | Vô hiệu bộ đệm |
| `20.lifecycle.reason-min-length` | 20 | 10…200 | Bộ kiểm lý do | Yêu cầu kế |
| `20.usage.probe-interval` | PT5M | PT1M…PT15M | `ThresholdProbe` | Lịch kế |

: Tham số 20.* và cách áp (29 khóa của FRS 8.2, đăng ký ở PH-18)

Các khóa đều là tham số vận hành, không phải bí mật. Khóa `20.registry.cache-seconds` có miền 10…60 giây (FRS 0.2 đã đưa trần về NFR-20-004, tạm ngừng có hiệu lực ≤ 60 giây); SDD thêm thăm dò 15 giây cho phần còn lại ngoài dữ liệu `status`. Khóa `20.usage.probe-interval` đã vào FRS 8.2 cho `ThresholdProbe` (NFR-20-009).

### 9.2. Nạp và kiểm tham số

`ParameterGateway` (một lớp mỏng trong `platform.shared`) nạp bản chụp tham số từ PH-18 lúc khởi động và làm mới theo sự kiện đổi tham số; nếu PH-18 chưa sẵn sàng thì dùng giá trị mặc định đã nhúng trong mã, ghi cảnh báo và tiếp tục chạy (control plane không chặn khởi động vì tham số). Mọi giá trị ngoài miền bị từ chối ở PH-18 (PH-18 trả `ERR-18-012` khi sai kiểu, `ERR-18-013` khi ngoài miền; màn tham số của PH-20 hiển thị lại thành `ERR-20-060`, và `ERR-20-060` không có operation OpenAPI riêng của PH-20 vì tham số đổi qua API của PH-18, thay đổi được đẩy xuống bằng EVT-18-01) và bị bỏ qua ở PH-20 (giữ giá trị cũ, ghi log cảnh báo), nên một giá trị hỏng không làm sai hành vi.

### 9.3. Cấu hình triển khai

| Nhóm | Nội dung | Nguồn |
|---|---|---|
| Kết nối | Địa chỉ PostgreSQL, Kafka, Valkey, OpenBao, Ceph RGW, Git, Argo CD, Mimir | ConfigMap theo môi trường do Argo CD áp |
| Danh tính | Tên tài khoản dịch vụ `svc-ph20-gitops`, `svc-ph20-saga` | ConfigMap, thông tin xác thực lấy từ OpenBao ngắn hạn |
| Bể kết nối | `ph20_app` tối đa 20, `ph20_platform_app` tối đa 10 mỗi pod | ConfigMap |
| Lập lịch | ShedLock bảng `shedlock`, tên khóa `provision:{tenantCode}`, `config:{tenant}`, `usage:snapshot`, `drift:check`, `leaktest:nightly` | Mã và ConfigMap |
| Kho Git | Địa chỉ `dh-tenant-config`, nhánh `main`, thư mục `tenants/` | ConfigMap |
| Bí mật | Không có trong cấu hình; chỉ tham chiếu đường dẫn OpenBao | OpenBao |

: Cấu hình triển khai (không chứa bí mật)

## 10. Quan sát

### 10.1. Chỉ số

Tiền tố `dh_tenant_` và `dh_release_`, nhãn `tenant` bắt buộc ở chỉ số theo tenant (NFR-20-021); nhãn `module`, `step`, `outcome` có số giá trị hữu hạn để không phình số chuỗi (≤ 40 tenant nhân 17 bước).

| Chỉ số | Loại | Nhãn | Dùng cho |
|---|---|---|---|
| `dh_tenant_provision_duration_seconds` | Histogram | `tenant`, `mode` | NFR-20-001, KPI-12 |
| `dh_tenant_provision_step_duration_seconds` | Histogram | `step`, `outcome` | Tìm bước chậm |
| `dh_tenant_provision_runs_total` | Counter | `outcome` | Tỷ lệ thành công |
| `dh_tenant_step_waiting_report` | Gauge | `step` | Bước đang chờ báo |
| `dh_tenant_registry_request_duration_seconds` | Histogram | `cache_layer` | NFR-20-003 |
| `dh_tenant_registry_cache_hit_ratio` | Gauge | `layer` | Hiệu quả bộ đệm |
| `dh_tenant_status_propagation_seconds` | Histogram | `tenant` | NFR-20-004, đo từ commit tới lượt gọi bị chặn |
| `dh_tenant_requests_blocked_total` | Counter | `tenant`, `code` | Lượt bị `ERR-20-001`, 101, 102, 103 |
| `dh_tenant_outbox_lag_seconds` | Gauge | không | NFR-20-020 |
| `dh_tenant_config_apply_seconds` | Histogram | `tenant` | NFR-20-011 |
| `dh_tenant_config_drift` | Gauge | `tenant`, `status` | NFR-20-010 |
| `dh_tenant_usage_snapshot_age_seconds` | Gauge | `resource` | NFR-20-008 |
| `dh_tenant_quota_alerts_open` | Gauge | `tenant`, `level` | NFR-20-009 |
| `dh_tenant_leaktest_failures_total` | Counter | `api` | SEC-87 |
| `dh_tenant_merge_records_total` | Counter | `module`, `result` | NFR-20-014 |
| `dh_tenant_external_call_duration_seconds` | Histogram | `target`, `outcome` | Bảng 8.4 |
| `dh_release_upgrade_total` | Counter | `outcome` | Tỷ lệ nâng cấp |
| `dh_release_wave_error_percent` | Gauge | `wave` | NFR-20-016 |
| `dh_release_wave_paused` | Gauge | `wave` | Cảnh báo sóng dừng |

: Chỉ số quan sát của PH-20

### 10.2. Log, trace và kiểm toán

Log JSON một dòng, trường bắt buộc `ts`, `level`, `service`, `traceId`, `tenant`, `runId` hoặc `planId` khi có, `component`, `code` khi lỗi. Không ghi bí mật, nội dung hợp đồng, thư điện tử hay số điện thoại. Trace OpenTelemetry: một trace gốc cho mỗi lần chạy saga, mỗi bước là một span con, lệnh gọi ra ngoài là span con của bước; với bước bất đồng bộ, `traceparent` đi theo tiêu đề sự kiện nên báo cáo của phân hệ nối lại vào cùng trace. Bản ghi kiểm toán tách khỏi log (mục 7.4) vì chuỗi băm có yêu cầu bảo toàn riêng.

### 10.3. Cảnh báo

| Cảnh báo | Điều kiện | Mức | Người nhận |
|---|---|---|---|
| Saga chậm | Lần chạy quá 45 phút chưa xong | Cao | PA, PO |
| Bước chờ báo lâu | `WAITING_REPORT` quá 10 phút | Trung bình | PA |
| Hiệu lực tạm ngừng chậm | `dh_tenant_status_propagation_seconds` p95 > 45 giây | Cao | SRE |
| Registry chậm | p99 > 50 ms trong 5 phút | Cao | SRE |
| Outbox ùn | `dh_tenant_outbox_lag_seconds` > 30 giây trong 5 phút | Cao | SRE |
| Cấu hình lệch | `config_drift` `DRIFTED` quá 1 giờ | Trung bình | PA |
| Số đo sử dụng cũ | Ảnh chụp cũ hơn 2 giờ | Trung bình | SRE |
| Rò rỉ chéo tenant | `dh_tenant_leaktest_failures_total` tăng | Nghiêm trọng | ATTT, PA |
| Sóng nâng cấp dừng | `dh_release_wave_paused` bằng 1 | Cao | PA, PO |
| Chấm dứt chờ xóa mật mã | Đề nghị `EXECUTING` quá 24 giờ, `ERR-20-116` | Trung bình | PA |

: Cảnh báo vận hành của PH-20

## 11. Hiệu năng, triển khai và mở rộng

### 11.1. Giả định số liệu

| Mã | Giả định | Cơ sở |
|---|---|---|
| GĐ-01 | Tỉnh quy mô vừa có khoảng 200 HTTT, 500 tổ chức; bộ chỉ tiêu mẫu 120 chỉ tiêu | Số liệu kịch bản trong FRS và D01 |
| GĐ-02 | Lưu lượng registry 500 lượt mỗi giây ở đỉnh, 90% trúng đệm trong bộ nhớ | NFR-20-003 và đặc tính đọc nhiều ghi ít |
| GĐ-03 | Một lần chạy saga ghi khoảng 60 dòng `provisioning_step` và sự kiện | 17 bước nhân số lần thử và báo cáo |
| GĐ-04 | Ảnh chụp sử dụng 12 tài nguyên nhân 40 tenant nhân 24 giờ nhân 30 ngày, khoảng 345.600 dòng mỗi tháng | Bảng 4.8 và `20.usage.snapshot-interval` |
| GĐ-05 | Xác thực bước hai cho thao tác nguy hiểm do PH-12 cung cấp | Chưa có API ở PH-12, ghi ở Phụ lục A |
| GĐ-06 | Quỹ thời gian thêm 30 phút cho thử lại bằng tay | Cân đối với step-timeout 15 phút |
| GĐ-07 | Gói bàn giao trung bình 50 GB mỗi tenant, tối đa 500 GB (Q20-02) | NFR-20-023 |

: Giả định và cơ sở

### 11.2. Ngân sách thời gian của saga

Mục tiêu tổng ≤ 60 phút p95 ở `SHARED` (NFR-20-001). Ngân sách phân bổ theo đường găng; đoạn song song tính theo bước chậm nhất.

| Đoạn | Bước | Ngân sách | Ghi chú |
|---|---|---|---|
| Nền tảng tuần tự | `S01…S05` | 8 phút | `S03` realm 3 phút, `S05` bucket 2 phút |
| Điểm rẽ nhánh | `S06, S09, S10, S12` và `S07, S08` | 20 phút | Bước chậm nhất quyết định, `S10` tạo kho luồng 10 đến 15 phút |
| Danh mục và tổ chức | `S11, S13, S14` | 8 phút | Gọi PH-07, PH-16 |
| Kích hoạt phân hệ | `S15` | 10 phút | Phân hệ không lõi báo song song |
| Kiểm tra khói và kích hoạt | `S16, S17` | 6 phút | Bốn ca khói |
| Dự phòng | | 8 phút | Thử lại tự động 10, 30, 90 giây |

: Ngân sách thời gian saga ở chế độ SHARED

Chế độ `DEDICATED_CLUSTER` chờ cụm Kubernetes nên không nằm trong cam kết 60 phút (ghi ở D03-10), `DEDICATED_DB` cộng thời gian tạo cơ sở dữ liệu theo `S07`.

### 11.3. Dung lượng và mở rộng

| Chỉ tiêu | Mục tiêu | Cách đạt |
|---|---|---|
| Registry | p99 ≤ 50 ms, ≥ 500 lượt mỗi giây | Caffeine 60 giây trong bộ nhớ, Valkey, thư viện khách theo ETag; trượt đệm thì đọc PostgreSQL bằng chỉ mục `tenant_code` |
| Số tenant | ≥ 34, thiết kế 40 | Hạn mức nền tảng kiểm ở `ReadinessChecker` (`ERR-20-013`), bảng phân vùng theo tháng, nhãn có số giá trị hữu hạn |
| Lần chạy đồng thời | Tối đa 3 saga | ShedLock theo tenant, bể `ph20_platform_app` dành riêng; khởi tạo hàng loạt xếp hàng |
| Ảnh chụp sử dụng | 345.600 dòng mỗi tháng, giữ 25 tháng | Phân vùng theo tháng, chèn `ON CONFLICT DO NOTHING`, gỡ phân vùng cũ thay vì xóa dòng |
| Dung lượng CSDL | ≤ 4 GB sau 25 tháng | Ảnh chụp chiếm chủ yếu, khoảng 100 byte mỗi dòng sau nén |
| Nhập tổ chức | 5.000 dòng ≤ 30 giây xem trước | Đọc luồng, kiểm theo lô 500, không giữ cả tệp trong bộ nhớ |
| Sẵn sàng | Control plane ≥ 99,5%, registry ≥ 99,9% | Hai bản `dh-platform-api` trải hai nút, registry sống nhờ đệm khi PH-20 dừng |

: Dung lượng và mở rộng

### 11.4. Triển khai

```{.mermaid caption="Triển khai PH-20 trong vùng control plane Z3"}
flowchart LR
  subgraph Z3["Vùng Z3 control plane"]
    API["dh-platform-api<br/>2 bản, tenant, release"]
    WK["dh-platform-worker<br/>1 đến 2 bản, saga, lập lịch"]
    PG[("PostgreSQL ph20_tenant<br/>chính và dự phòng")]
    VK[("Valkey")]
    DBZ["Debezium"]
  end
  subgraph Z2["Hạ tầng dùng chung"]
    KF["Kafka"]
    BAO["OpenBao"]
    S3["Ceph RGW"]
    GIT["Git dh-tenant-config"]
    ARGO["Argo CD"]
    MIM["Mimir"]
  end
  subgraph Z1["Vùng data plane"]
    GW["APISIX PH-03"]
    PHM["Phân hệ nghiệp vụ"]
  end
  API --> PG
  WK --> PG
  API --> VK
  PG --> DBZ --> KF
  WK --> GIT
  GIT --> ARGO
  WK --> BAO
  WK --> S3
  WK --> MIM
  KF --> GW
  KF --> PHM
  GW -. đọc registry .-> API
  PHM -. đọc registry .-> API
```

Điểm cần chú ý: `api` phục vụ yêu cầu người dùng và registry, `worker` chạy saga và việc nền nên saga dài không chiếm luồng phục vụ (Q20-20 xác nhận tách `worker` thành Deployment riêng). Nét đứt là đường đọc có đệm của data plane vào control plane; nếu mũi tên này đứt, data plane vẫn chạy bằng đệm tới 15 phút. Cả hai Deployment dùng chung ảnh `dh-platform`, khác nhau ở hồ sơ Spring (`api`, `worker`).

### 11.5. Khôi phục sau sự cố

PostgreSQL đồng bộ sang dự phòng trong cùng vùng, sao lưu hằng ngày và lưu WAL theo D03-09; RPO 5 phút, RTO 1 giờ cho control plane. Sau khôi phục, worker chạy `RecoveryScan`: run `RUNNING` hoặc `WAITING` có `locked_until` quá hạn được nhận lại, bước đang `RUNNING` chạy lại nhờ khóa lũy đẳng, sự kiện outbox chưa phát được Debezium phát tiếp. Mất Git thì dựng lại từ CSDL (CSDL là bản chiếu đầy đủ), mất CSDL thì dựng lại từ Git cho cấu hình nhưng không cho lịch sử, nên hai nguồn sao lưu độc lập.

## 12. Kiểm thử ở mức thiết kế

### 12.1. Chiến lược

| Tầng | Công cụ | Đối tượng | Tiêu chí |
|---|---|---|---|
| Đơn vị | JUnit 5, AssertJ | `QuotaCalculator`, `TenantTransitions`, `WavePlanner`, `MappingService`, thuật toán 4.21 | Phủ nhánh ≥ 85% ở các lớp quyết định |
| Mô-đun | Spring Modulith `@ApplicationModuleTest`, Testcontainers PostgreSQL, Kafka | Từng mô-đun cô lập, sự kiện qua outbox | Mọi FR mức M có ca |
| Kiến trúc | ArchUnit, `ApplicationModules.verify()` | Tám luật phụ thuộc mục 3.3, cấm `UPDATE tenant SET status` ngoài `TenantTransitions` | Không vi phạm |
| Hợp đồng | Pact hoặc Spring Cloud Contract, WireMock | Mục 12.4 | Chạy trong CI cả hai phía |
| Saga | Testcontainers, tiêm lỗi bằng Toxiproxy | 17 bước, mỗi bước lỗi một lần, worker chết giữa bước | Run luôn hội tụ về `SUCCEEDED`, `FAILED` hoặc `CANCELLED` |
| Rò rỉ chéo | Bộ kiểm riêng mục 12.3 | RLS, API, Kafka, Valkey, Git | 0 rò rỉ |
| Hiệu năng | Gatling | Registry, nhập 5.000 tổ chức | Đạt NFR-20-003, 012, 013 |
| Giao diện | Playwright, axe | 22 màn hình | WCAG 2.2 AA, luồng chính |

: Chiến lược kiểm thử theo tầng

### 12.2. Kiểm thử kiến trúc

Ba quy tắc ArchUnit riêng cho PH-20: (a) lớp ngoài `tenant.profile.TenantTransitions` không được gọi `TenantRepository.updateStatus`; (b) gói `tenant` không import gói `release` và ngược lại chỉ qua `tenant.api`; (c) không lớp nào ngoài `shared.outbound` import thư viện HTTP khách. Quy tắc (a) bảo vệ bất biến "mọi chuyển trạng thái có lịch sử và sự kiện".

### 12.3. Ca rò rỉ chéo tenant

| Mã | Ca | Cách chạy | Kỳ vọng |
|---|---|---|---|
| LK-01 | Truy vấn trực tiếp bảng của tenant khác bằng vai `ph20_app` với `app.tenant_id` của tenant A | SQL | 0 hàng |
| LK-02 | `app.tenant_id` không đặt | SQL | 0 hàng, không lỗi lộ dữ liệu |
| LK-03 | Hai yêu cầu liên tiếp qua cùng kết nối, tenant A rồi B | Kiểm tra bể | Không mang tenant cũ (`SET LOCAL`) |
| LK-04 | Gọi API tỉnh A với mã tenant B trong đường dẫn | HTTP | 404, không phải 403 |
| LK-05 | Token tỉnh A gọi API control plane | HTTP | 403 |
| LK-06 | Báo cáo tiến độ saga của tenant B bằng token phân hệ không có scope | HTTP | `ERR-20-104` |
| LK-07 | Sự kiện có tiêu đề `dhtenant` khác khóa thông điệp | Kafka | Bị loại, đếm lỗi |
| LK-08 | Khóa Valkey không có tiền tố | Mã | Thư viện từ chối |
| LK-09 | Ghi `tenants/B/` bằng yêu cầu của tenant A | Mã | `GitOpsConfigWriter` từ chối |
| LK-10 | Registry trả dữ liệu tenant `SUSPENDED` cho API tỉnh | HTTP | Chỉ trả trạng thái, không trả nội dung |
| LK-11 | Tìm kiếm danh sách tenant bằng tài khoản người dùng tỉnh | HTTP | Chỉ thấy tenant của mình |
| LK-12 | Người dùng tỉnh đọc `usage_snapshot` của tỉnh khác | SQL, HTTP | 0 hàng |

: Ca kiểm thử rò rỉ chéo tenant (SEC-87)

`LeakTestScheduler` chạy hằng đêm 01:00 trên tenant kiểm thử `T90…T99`, quét mọi API công bố trong danh mục `LeakProbeCatalog` (mục tiêu 100%, Q20-28 hỏi cách bảo đảm danh mục đủ). Tenant `PROD` không bao giờ là đích (`ERR-20-065`).

### 12.4. Kiểm thử hợp đồng với phân hệ khác

| Phân hệ | Hợp đồng kiểm | Phía kiểm |
|---|---|---|
| PH-12 | API-12-080 lũy đẳng, 084, 085, 045, 046; scope `iam:realm-provision` | PH-20 là khách, PH-12 là nhà cung cấp |
| PH-13 | API-13-072, 073; `ERR-13-014` thử lại; nhận EVT-20-12 | Hai phía |
| PH-07 | API-07-073 gói danh mục nền | PH-20 khách |
| PH-10 | Sự kiện EVT-20-01, 05, 07 và báo `S06` qua API-20-166 | Hai phía |
| PH-03 | API-20-164 đọc hạn mức, EVT-03-10, EVT-03-11 | PH-20 nhà cung cấp và người nhận |
| PH-16 | API-16-030 `metricCode` `thoi-gian-khoi-tao-tenant` | PH-20 khách |
| PH-18 | `merge-transfers`, API-20-167, thông báo, đăng ký tham số | Hai phía |
| PH-09 | FR-09-043 xóa mật mã và EVT-09-21 | PH-20 khách và người nhận |

: Kiểm thử hợp đồng với phân hệ khác

Bộ kiểm này chạy trong CI của mỗi bên; hợp đồng đổi mà không cập nhật làm hỏng bản dựng của bên kia trước khi vào nhánh chính.

### 12.5. Hỗn loạn và khôi phục

Ca bắt buộc trước khi ra W2: giết worker giữa `S05` và bước điểm rẽ (EVT-20-01 chỉ phát một lần), mất Kafka 10 phút trong lúc tạm ngừng (hiệu lực nhờ thăm dò), Git không đẩy được (`ERR-20-024`, cấu hình `PENDING`), PH-12 trả 503 liên tục (bước `FAILED`, thử lại bằng tay), Argo CD không đồng bộ (`ERR-20-109`), sóng nâng cấp vượt 2% lỗi (dừng ≤ 5 phút).

## 13. Kế hoạch hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình trong W2

W2 kéo dài 4 tháng (khoảng 17 tuần). WBS 1.20 gồm 13 người-tháng: SDD 1, CSDL và API 1, giao diện 2,5, lập trình 4,5, kiểm thử 2, hướng dẫn sử dụng 0,5. PH-20 thuộc đội B của W2 cùng PH-07, PH-18 (L-CTRL, L-DATA, L-PROC). Phần lập trình 4,5 người-tháng phân theo các cột mốc dưới đây; giao diện và kiểm thử chạy song song theo từng cột mốc.

| Mốc | Tuần W2 | Nội dung | Thành phần | Điều kiện xong |
|---|---|---|---|---|
| M1 | 1 đến 3 | Khung hai mô-đun, di trú schema 45 bảng, `TenantSession`, outbox, inbox, `TenantService`, registry bản đầu | 4.2, 4.16, 4.19 | `ApplicationModules.verify()` xanh, LK-01…03 |
| M2 | 3 đến 7 | Saga: `ProvisioningOrchestrator`, `StepExecutor` 17 bước (giả lập ngoài), `SmokeTestRunner`, API-20-166 | 4.3, 4.4, 4.5, 4.20 | Khởi tạo `T90` đủ 17 bước trên môi trường thử, ca chaos 12.5 |
| M3 | 6 đến 9 | GitOps, hạn mức, đo sử dụng, cảnh báo | 4.6, 4.7, 4.8 | Hạn mức tới APISIX ≤ 5 phút, `DriftDetector` chạy |
| M4 | 8 đến 11 | Phân hệ, vòng đời, gói bàn giao | 4.9, 4.10, 4.11 | Tạm ngừng ≤ 60 giây, chấm dứt thử trên `T91` |
| M5 | 10 đến 13 | Sáp nhập, tổ chức | 4.12, 4.13 | Sáp nhập `T91` vào `T90` đầu cuối, nhập 5.000 dòng ≤ 30 giây |
| M6 | 12 đến 15 | Phát hành, nâng cấp theo sóng | 4.14, 4.15 | Một sóng thử, dừng khi vượt ngưỡng |
| M7 | 14 đến 17 | Kiểm thử rò rỉ, chính sách liên tenant, hiệu năng, tài liệu, hợp đồng với PH khác | 4.17, 4.18 | Mục 12.4 xanh, NFR-20-001, 003 đạt, tài liệu hướng dẫn |

: Lộ trình hiện thực trong W2

Các điểm phụ thuộc ngoài: M2 cần PH-12 (API-12-080) và PH-13 (API-13-072) ở bản giả lập từ tuần 3, bản thật từ tuần 9; M3 cần PH-03 đọc API-20-164; M5 dùng API-18-150…153 của PH-18 (`merge-transfers`, hợp đồng đã chốt). Nếu PH khác trễ, M2 và M5 chạy trên bản giả lập (WireMock) và đổi sang bản thật khi sẵn sàng; không làm trễ hiện thực nội bộ.

### 13.2. Truy vết hệ cũ

| Mã hệ cũ | Nội dung | Thiết kế mới |
|---|---|---|
| LGC-IAM-002 | Quản trị đơn vị, cấu hình theo đơn vị | Tổ chức DD-02 (mục 4.13), cài đặt tỉnh qua GitOps (mục 4.6) |
| LGC-BUS-031 | Cấu hình kết nối theo tỉnh, triển khai tỉnh mới thủ công | Saga 17 bước (mục 4.3, 4.4), cấu hình GitOps (mục 4.6) |

: Truy vết chức năng hệ cũ

### 13.3. Ma trận thành phần và FR

| Mục | Thành phần | FR hiện thực |
|---|---|---|
| 4.2 | Hồ sơ tenant | FR-20-001…007 |
| 4.3, 4.4 | Saga và 17 bước | FR-20-008…011, 014…017 |
| 4.5 | Kiểm tra khói | FR-20-012, 013 |
| 4.6 | GitOps và drift | FR-20-018…022, 025 |
| 4.17 | Liên tenant | FR-20-023, 024 |
| 4.7 | Hạn mức | FR-20-026, 027, 032 |
| 4.8 | Sử dụng | FR-20-028…031 |
| 4.9 | Phân hệ, cờ | FR-20-033…037 |
| 4.10, 4.11 | Vòng đời, bàn giao | FR-20-038…044 |
| 4.12 | Sáp nhập | FR-20-045…052 |
| 4.13 | Tổ chức | FR-20-053…058 |
| 4.14 | Phát hành | FR-20-059, 060 |
| 4.15 | Nâng cấp | FR-20-061…064 |
| 4.16 | Registry | FR-20-065…067 |
| 4.19, 4.20 | Hạ tầng dùng chung | FR-20-068 (kiểm toán), FR-20-069 (tham số) |
| 4.18 | Kiểm thử rò rỉ | FR-20-070 |

: Ma trận thành phần và 70 FR (đủ 001…070)

### 13.4. Rủi ro

| Mã | Rủi ro | Xác suất, tác động | Giảm thiểu |
|---|---|---|---|
| R-01 | Saga vượt 60 phút do `S10` tạo kho luồng chậm | Trung bình, cao | Chạy song song từ điểm rẽ, đo từng bước, ngân sách mục 11.2 |
| R-02 | PH khác chưa sẵn sàng hợp đồng khi tích hợp | Cao, trung bình | Bản giả lập, kiểm thử hợp đồng hai phía, mục 13.1 |
| R-03 | Tự xây saga có lỗi nhất quán khó thấy | Trung bình, cao | Khóa lũy đẳng, chaos 12.5, `RecoveryScan`, đánh giá lại nếu số loại saga tăng |
| R-04 | Kho Git trở thành điểm nghẽn hoặc hỏng | Thấp, cao | Sao lưu độc lập, dựng lại từ CSDL, ShedLock theo tenant |
| R-05 | Sáp nhập tenant lệch số đếm giữa phân hệ | Trung bình, cao | So đếm từng phân hệ, lượt bù cuối, `ERR-20-113` chặn cutover |
| R-06 | Bộ đệm registry làm tạm ngừng có hiệu lực chậm hơn 60 giây | Trung bình, cao | Giới hạn cứng 60 giây, sự kiện, thăm dò 15 giây, đo `dh_tenant_status_propagation_seconds` |
| R-07 | Ngưỡng 2% của sóng nâng cấp nhiễu với tenant nhỏ | Cao, thấp | Mẫu tối thiểu 200 lượt, định nghĩa tỷ lệ ở Q20-24 |
| R-08 | Ước lượng `DATABASE_GB` ở chế độ chung sai | Trung bình, thấp | Đánh dấu `is_estimate`, Q20-23 |
| R-09 | Xóa mật mã sai tenant | Rất thấp, rất cao | Bốn mắt, `DELIVERED`, nguội 30 ngày, xác nhận mã tenant gõ lại |
| R-10 | Lệch giữa FRS, CSDL và brief làm hiểu sai khi hiện thực | Trung bình, trung bình | Phụ lục A, đồng bộ trước M1 |

: Rủi ro và giảm thiểu

### 13.5. Câu hỏi mở

| Mã | Câu hỏi | Ảnh hưởng | Đề xuất tạm |
|---|---|---|---|
| Q20-20 | Saga có chạy ở Deployment `worker` riêng, tách khỏi `api` | 2.2, 11.4 | Có, hai Deployment cùng ảnh |
| Q20-21 | Kỹ thuật ký commit: OpenBao transit hay khóa cấp phát ngắn hạn | 4.6, 7.3 | Transit, khóa không rời OpenBao |
| Q20-22 | `merge-transfers` đồng bộ hay bất đồng bộ, lũy đẳng theo khóa nào | 4.12 | Bất đồng bộ, khóa `{mergePlanId}:{module}` |
| Q20-23 | Cách ước `DATABASE_GB` ở `SHARED` | 4.8 | Tổng kích thước theo `tenant_id` mỗi giờ, đánh dấu ước lượng |
| Q20-24 | Định nghĩa tỷ lệ lỗi sóng: theo lượt gọi hay theo tenant | 4.15 | 5xx trên tổng lượt gọi gộp, mẫu ≥ 200 |
| Q20-25 | `RUNTIME_CPU` khi nhiều tenant dùng chung namespace | 4.8 | Tính theo nhãn `tenant` của pod, không tách được thì chia theo lưu lượng |
| Q20-26 | PH-03 có cung cấp thăm dò `enforcement` | 4.7 | Có, qua EVT-03-11 và thăm dò |
| Q20-27 | Có chặn nâng cấp tenant đang `MERGING` hoặc có lần chạy mở | 4.15 | Chặn, bỏ khỏi sóng `SKIPPED` |
| Q20-28 | Cách bảo đảm kiểm thử rò rỉ phủ 100% API | 4.18, 12.3 | Sinh `LeakProbeCatalog` từ đặc tả OpenAPI, CI chặn API mới thiếu ca |
| Q20-29 | Mã hóa gói bàn giao và thứ tự xóa KEK so với gói | 4.11, 7.3 | Mã hóa bằng khóa riêng của gói, KEK xóa sau khi gói `DELIVERED` |

: Câu hỏi mở Q20-20…29 (nối tiếp Q20-01…19 của FRS)

### 13.6. Quyết định kiến trúc đề xuất

| Mã | Quyết định | Phương án loại | Hệ quả |
|---|---|---|---|
| ADR 200 | Saga khởi tạo tự xây trên PostgreSQL | Temporal, Camunda, Flowable | Không thêm hạ tầng, phải tự bảo đảm lũy đẳng và bù trừ |
| ADR 201 | Git là trạng thái mong muốn, CSDL là bản chiếu | Chỉ CSDL, chỉ Git | Có lịch sử ký, cần DriftDetector |
| ADR 202 | Sáp nhập qua hợp đồng bên tham gia, PH-18 chạy chuyển | PH-20 chạm dữ liệu từng phân hệ | PH-20 không biết schema phân hệ khác |
| ADR 203 | Kênh STABLE, PREVIEW, nâng cấp theo sóng, ngưỡng lỗi 2% | Nâng cấp đồng loạt | Cần cửa sổ bảo trì, WaveGuard |
| ADR 204 | Ảnh chụp sử dụng hằng giờ, hạn mức hiệu lực là min của trần và max của hợp đồng, ghi đè | Đo thời gian thực | Cảnh báo có độ trễ, thêm ThresholdProbe 5 phút |

: Quyết định kiến trúc đề xuất (tệp ADR-200 đến ADR-204 ở 00-chung/adr)

## Phụ lục A. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

### A.1. Lệch giữa SDD với FRS, CSDL và brief

| Mã | Điểm lệch | Phương án của SDD | Cần làm |
|---|---|---|---|
| L-01 | Chỉ mục `uq_provisioning_run_active` thiếu trạng thái `PENDING` so với BR-20-006 | Dịch vụ kiểm thêm bằng khóa dòng tenant | Đã xử lý ở 0.2: CSDL thêm `PENDING` vào chỉ mục |
| L-02 | Số tham số `20.*` lệch giữa FRS, brief và CSDL | Theo FRS, thêm một khóa đề xuất | Đã xử lý ở 0.2: FRS 8.2 thêm `20.usage.probe-interval` (29 khóa), CSDL sửa câu 19 tham số |
| L-03 | Tên ca khói: FRS `LOGIN`, `API_CALL`, `EVENT_ROUNDTRIP`; DDL, OpenAPI `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE` | Theo DDL và OpenAPI | Đã xử lý ở 0.2: FRS, use case, màn hình, test case dùng tên của OpenAPI |
| L-04 | `usage_snapshot`: FRS `quality`, `hour_start`; CSDL `is_estimate`, `captured_at`, không lưu dòng thiếu | Theo CSDL | Sửa FRS |
| L-05 | Trạng thái cảnh báo FRS `CLEARED`, CSDL `RESOLVED` | Theo CSDL | Đã xử lý ở 0.2: FRS, use case, test case dùng `RESOLVED` |
| L-06 | `metricCode` KPI-12: FRS 0.1 ghi mã riêng của PH-20, PH-16 ghi `thoi-gian-khoi-tao-tenant` | Theo PH-16 | Đã xử lý ở 0.2: mọi tập PH-20 dùng `thoi-gian-khoi-tao-tenant` |
| L-07 | FRS 12.1 ghi `S03_IDENTITY` | Dùng `S03_REALM` | Đã xử lý ở 0.2: FRS dùng `S03_REALM` |
| L-08 | EVT-20-01: FRS 9.3 "khai báo xong", FR-008 "sau S05" | Theo FR-008 | Sửa FRS 9.3 |
| L-09 | Bù trừ `S01` ghi "xóa bản ghi" nhưng trigger CSDL chặn xóa `tenant` | Giữ dòng, chuyển `DECOMMISSIONED`, chỉ xóa phần mặc định | Sửa FRS |
| L-10 | Chấm dứt: FRS đặt `DECOMMISSIONED` ở bước 5 sau EVT-09-21 | Đặt ở giai đoạn 1, bước 5 chỉ đóng đề nghị | Sửa FR-042 |
| L-11 | BR-20-022 một kế hoạch sáp nhập mỗi tenant, FRS cho nhiều nguồn, CSDL một nguồn | Một nguồn mỗi kế hoạch, nhiều kế hoạch cùng đích | Chốt Q20-22 và sửa FRS |
| L-12 | NFR-20-009 cảnh báo ≤ 5 phút so với thu hằng giờ | Thêm `ThresholdProbe` 5 phút cho nhóm đo bằng Mimir | Đã xử lý ở 0.2: `20.usage.probe-interval` vào FRS 8.2 và FR-20-029 |
| L-13 | `20.registry.cache-seconds` miền tới 300 giây so với NFR-20-004 | Giới hạn cứng 60 giây cho `status` | Đã xử lý ở 0.2: FRS 8.2 đặt miền 10…60 |
| L-14 | Lệnh xuất gói bàn giao tới phân hệ cần sự kiện lệnh, không có trong 16 EVT | Dùng sự kiện lệnh chưa gán mã | Đăng ký EVT mới |
| L-15 | Chế độ `DEDICATED_DB` cần cấu hình cơ sở dữ liệu | Thêm tệp `database.yaml` | Cập nhật ADR 201 |

: Lệch giữa SDD và tài liệu nguồn

### A.2. Đề nghị đồng bộ với tài liệu khác

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

| Tài liệu | Đề nghị |
|---|---|
| D03-01 | Khối `dh-platform` ghi hai Deployment `api` và `worker`, hai mô-đun `tenant`, `release` và các SPI ở `tenant.api` (`TenantListFilter`, `ModuleAvailabilityCheck`) |
| D03-09 | Thêm vai CSDL `ph20_owner`, `ph20_app`, `ph20_platform_app`, `ph20_ro`; cụm Valkey cho đệm registry; sao lưu `ph20_tenant` với RPO 5 phút |
| D03-10 | Thay 10 bước ở mục 5.2 bằng 17 bước; thêm hai chuyển `FAILED → DECOMMISSIONED`, `MERGING → ACTIVE`; ghi năm chế độ RLS |
| D02-08 | Thêm 10 quyền `PERM-20-*` và ba scope `tenant:registry-read`, `tenant:org-read`, `tenant:provision-report` |
| D02-01 | Thêm BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp |
| D03-06-00 | Thêm menu `/quan-tri/to-chuc`, `/nen-tang/sap-nhap`, `/nen-tang/phat-hanh`, `/nen-tang/tong-quan`, `/nen-tang/su-dung`, `/nen-tang/mau-khoi-tao` |
| D00-04 | Đăng ký mã lỗi `ERR-20-001…068`, `ERR-20-101…118` |
| ADR 200…204 | Đã xử lý ở 0.4: tệp ADR-200 đến ADR-204 đã lập ở 00-chung/adr theo mục 13.6 |
| PH-12 | Scope `iam:realm-provision` cho PH-20, API xác thực bước hai (GĐ-05), đọc API-20-165 khi cấp truy cập liên tenant |
| PH-13 | Nhận EVT-20-12, nhãn `tenant` cho `dh_tenant_*`, thử lại `ERR-13-014` |
| PH-03 | Đọc API-20-164, phát EVT-03-10 và EVT-03-11, thăm dò `enforcement` (Q20-26) |
| PH-07 | Scope `platform.tenant.provision` cho PH-20 gọi API-07-073 |
| PH-10 | Đổi tên topic kiểm thử `dh.platform.tenant.created.v1` thành `platform.tenant.created.v1`; xử lý EVT-20-01 qua inbox |
| PH-19 | Đổi tên topic nghe sang `platform.tenant.module-enabled.v1` |
| PH-16 | Nhận KPI qua API-16-030, `metricCode` `thoi-gian-khoi-tao-tenant` |
| PH-18 | Chốt `POST /api/ops/v1/merge-transfers` (Q20-22), thông báo đầu mối, đăng ký 29 khóa `20.*`, việc dọn khi phân hệ không gỡ xong |
| PH-01 | Q01-10: đổi chủ quản HTTT theo EVT-20-13 qua đề nghị chờ quản trị tỉnh duyệt hàng loạt |
| PH-09 | Cung cấp FR-09-043 xóa mật mã theo tenant và phát EVT-09-21 |

: Đề nghị đồng bộ với tài liệu khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người thực hiện | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-27 | Kiến trúc sư phần mềm | Bản đầu: 19 thành phần, 15 sơ đồ, bảng lỗi, tham số, rủi ro, câu hỏi mở Q20-20…29, Phụ lục A |
| 0.2 | 2026-11-27 | Kiến trúc sư phần mềm | Đồng bộ với FRS 0.2: 29 khóa `20.*`, miền `20.registry.cache-seconds`, cửa sổ bảo trì 2 đến 6 giờ, mã KPI-12; đánh dấu L-01, 02, 03, 05, 06, 07, 12, 13 đã xử lý |
| 0.3 | 2026-11-27 | Kiến trúc sư phần mềm | Đồng bộ chéo cuối: merge-transfers theo API-18-150…153, chờ API-12-080 tối đa 4 phút, `database` trong `tenant.yaml` |
| 0.4 | 27/11/2026 | Kiến trúc sư phần mềm | Đồng bộ chéo cuối: mục 13.6 và Phụ lục A.2: tệp ADR-200 đến ADR-204 đã lập ở 00-chung/adr; mục ParameterGateway ghi nơi trả ERR-20-060 và hợp đồng đẩy thay đổi; chốt Q430: mã BP-15, BP-16 cho sáp nhập tenant và phát hành sản phẩm |

: Lịch sử phiên bản
