---
ma_tai_lieu: D02-03-PH20
ten: Đặc tả yêu cầu chức năng phân hệ PH-20 Quản trị tenant và phát hành sản phẩm
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, quản trị nền tảng, vận hành nền tảng, quản trị tỉnh, kỹ sư dh-platform, kiểm thử viên
phan_he: PH-20
mo_ta: Đặc tả hành vi của phân hệ quản trị tenant gồm hồ sơ tenant, saga khởi tạo tự động mười bảy bước, cấu hình GitOps, hạn mức và sử dụng tài nguyên, bật tắt phân hệ, vòng đời tạm ngừng và chấm dứt, sáp nhập tenant khi sắp xếp đơn vị hành chính, danh mục tổ chức, kênh phát hành và nâng cấp theo sóng, registry cho phân hệ khác, làm căn cứ thiết kế, lập trình và kiểm thử.
tai_lieu_lien_quan: D02-01 BRD; D02-02 SRS; D03-10 Thiết kế đa tenant; D02-04-PH20 Use case; D03-02-PH20 Thiết kế chi tiết; D03-03-PH20 CSDL; D03-04-PH20 API; D03-06-PH20 Màn hình; D05-02-PH20 Test case
---

# D02-03-PH20 · Đặc tả yêu cầu chức năng Quản trị tenant và phát hành sản phẩm

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** PH-20 biến Datahub từ "một bản cài cho một tỉnh" thành "một sản phẩm dùng chung cho nhiều tỉnh" (BO-06). Phân hệ trả lời bốn câu hỏi: đưa một tỉnh mới lên nền tảng mất bao lâu, có lặp lại được không; mỗi tỉnh dùng bao nhiêu tài nguyên so với hợp đồng; khi tỉnh tạm ngừng, chấm dứt hay sáp nhập thì dữ liệu, người dùng, HTTT được xử lý ra sao; bản phát hành mới đến từng tỉnh theo thứ tự nào. Trọng tâm là **saga khởi tạo tự động mười bảy bước** ≤ 1 giờ ở chế độ `SHARED` (NFR-00-057) để đạt KPI-12, và **sáp nhập tenant có chạy thử, xử lý xung đột, chuyển tiếp 6 tháng**.

**Phạm vi.** 70 yêu cầu chức năng chia mười nhóm A…J. Phân hệ chạy trong DU `dh-platform` (Spring Boot 4, Modulith; mô-đun `vn.datahub.platform.tenant` và `vn.datahub.platform.release`), schema `ph20_tenant` trên `pg-core`, cấu hình tenant ở kho Git `dh-tenant-config` do Argo CD áp. Đợt 1 (MVP), lane L-CTRL, đội B, 13 tuần-người (D01-02 dòng 1.20); FR-20-017, FR-20-025 thuộc Đợt 2.

**Căn cứ pháp lý.** CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026 về kiểm soát truy cập, phân tách dữ liệu, nhật ký ở cấp độ 3); CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, dữ liệu cá nhân của tỉnh này không lộ sang tỉnh khác, xóa và bàn giao khi chấm dứt); CMP-LAW-03 (Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu); CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15, lưu trữ trong nước). Văn bản về sắp xếp đơn vị hành chính cấp tỉnh và thời hạn lưu dữ liệu của tỉnh cũ chưa có mã trong D00-01, ghi ở Q20-01.

**Những điểm hội đồng cần lưu ý.**

1. **Khởi tạo tỉnh mới là cấu hình, không phải phát triển.** Mọi khác biệt giữa các tỉnh chỉ được biểu diễn bằng cấu hình tenant có phiên bản trong Git, mẫu khởi tạo và tham số, không bao giờ bằng nhánh mã riêng (D01-02 §10.8). Mỗi bước saga lũy đẳng, có bù trừ, thử lại được (BR-20-005).
2. **Tách nhiệm vụ cho thao tác không đảo ngược được.** Chấm dứt tenant, sáp nhập, đổi chế độ cách ly và hạ hạn mức dưới mức đang dùng cần hai quản trị nền tảng khác nhau; thao tác vào tenant tỉnh cần lý do, mã phiếu, ghi kiểm toán vào chuỗi của tỉnh (BR-20-008, BR-20-009).
3. **Chấm dứt có lưới an toàn.** Phải tạm ngừng, bàn giao gói dữ liệu, chờ 30 ngày nguội rồi mới xóa mật mã qua PH-09 (BR-20-019, BR-20-020).
4. **PH-20 điều phối, không tự thực thi.** Hạn mức được đẩy xuống APISIX, Kafka, Kubernetes, PH-12; chuyển dữ liệu sáp nhập do PH-18 chạy theo hợp đồng "bên tham gia sáp nhập" của từng phân hệ; trạng thái tạm ngừng được PH-03, PH-12 thực thi ở data plane (ERR-20-001). PH-20 dừng thì data plane vẫn phục vụ nhờ đệm registry (BR-20-036).
5. **Phát hành an toàn cho nhiều tỉnh.** Hai kênh `STABLE` và `PREVIEW`; bản `STABLE` chỉ nhận sau ≥ 14 ngày chạy ở tenant thí điểm; nâng cấp theo sóng trong cửa sổ bảo trì của từng tỉnh, sóng tự dừng khi tỷ lệ lỗi vượt 2% (BR-20-031, BR-20-032, ADR 203 đề xuất).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Yêu cầu chức năng | 70 (M: 51, S: 19, C: 0), chia mười nhóm A…J |
| Quy tắc nghiệp vụ | 42 (BR-20-001…042) |
| Yêu cầu phi chức năng | 24 (NFR-20-001…024) |
| Màn hình | 22 (UI-20-01…22) |
| API | 171 operation (API-20-001…171): 134 ở `/api/platform/v1`, 27 ở `/api/tenant/v1`, 10 ở `/internal/tenant/v1` |
| Sự kiện | 16 phát (EVT-20-01…16); tiêu thụ EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11 |
| Mã lỗi | 68 control (ERR-20-001…068), 18 data plane, registry, runtime (ERR-20-101…118); `401`, `403` thiếu quyền chức năng, `428` dùng ERR-00-401, ERR-00-403, ERR-00-428 |
| Thực thể mức logic | 37 (EN-20-01…37) |
| Bước saga khởi tạo | 17 (`S01_RECORD`…`S17_ACTIVATE`), mở rộng 10 bước của D03-10 §5.2 |
| Máy trạng thái | 9 |
| Tham số | 29 khóa `20.*` đăng ký với PH-18 |
| Chức năng hệ cũ được phủ | Không có `LGC` do PH-20 làm chính; 2 mục liên quan gián tiếp (LGC-IAM-002, LGC-BUS-031) |
| FR của SRS cũ | Không có SRS cũ cho PH-20 (REQ-20 năng lực mới); nguồn thay thế ở mục 11.3 |

: Con số chính của PH-20

## 1. Giới thiệu

### 1.1. Mục đích của tài liệu

Tài liệu đặc tả đầy đủ hành vi của PH-20 Quản trị tenant và phát hành sản phẩm cho ba nhóm người đọc. Hội đồng thẩm định dùng tài liệu để đánh giá khả năng đáp ứng mô hình một nền tảng cho nhiều tỉnh (BO-06, REQ-20), mức bảo đảm cách ly khi khởi tạo, tạm ngừng, chấm dứt, sáp nhập và các rủi ro còn mở. Kỹ sư dùng tài liệu làm đầu vào cho D03-02-PH20 (thiết kế chi tiết), D03-03-PH20 (CSDL), D03-04-PH20 (API) và D03-06-PH20 (màn hình). Kiểm thử viên dùng luồng xử lý, ngoại lệ, quy tắc và tiêu chí chấp nhận để viết ca ở D05-02-PH20.

Mỗi chức năng đặc tả theo khung 17 mục của K-TRINH-BAY §4. D03-10 là nguồn chuẩn về nguyên tắc đa tenant mà tập này hiện thực; tài liệu không mô tả lại cơ chế cách ly theo tầng mà chỉ đặc tả các chức năng quản trị tạo ra, duy trì và kiểm chứng cơ chế ấy. Phụ lục A là nguồn chuẩn mọi giá trị liệt kê của bộ bảy tập PH-20; mục 9.4 là nguồn chuẩn danh mục API mà tập API phải dùng đúng mã; Phụ lục B ghi các đề nghị sửa tài liệu chung và tài liệu phân hệ khác.

### 1.2. Phạm vi

PH-20 chịu trách nhiệm mười nhóm việc, mỗi nhóm ứng với một mục ở chương 6: A hồ sơ tenant (FR-20-001…007); B saga khởi tạo (008…017); C cấu hình (018…025); D hạn mức, sử dụng (026…032); E phân hệ, tính năng (033…037); F vòng đời (038…044); G sáp nhập (045…052); H tổ chức (053…058); I phát hành (059…064); J dịch vụ cho phân hệ khác và quản trị (065…070). Danh sách đầy đủ ở chương 5.

Ngoài phạm vi PH-20: realm, người dùng, cấp quyền liên tenant (PH-12); chuỗi kiểm toán, số liệu Mimir (PH-13); thực thi hạn mức, host, tiền tố, chuyển tiếp lượt gọi (PH-03); ACL, topic Kafka (PH-10); danh mục ĐVHC (PH-07); tham số, thông báo, công cụ chuyển dữ liệu sáp nhập, sao lưu (PH-18); xóa mật mã (PH-09); kết nạp HTTT (PH-01); chỉ tiêu KPI-12 (PH-16); hạ tầng Kubernetes, Argo CD, Ceph RGW, OpenBao (D03-09); tính cước (ngoài v1.0, Q20-06). Tài liệu chỉ đặc tả phần giao tiếp, liệt kê ở bảng 12.1.

### 1.3. Đối tượng sử dụng và cách đọc

Hội đồng thẩm định đọc Tóm tắt, chương 1, 2, 4.3, 11, 13, 14. Quản trị, vận hành nền tảng đọc chương 2.5, 4, 6.3, 6.7, 6.8, 6.10, 10. Quản trị tỉnh đọc mục 6.4 (FR-20-018, 023, 024), 6.9, 6.10 (FR-20-064), 10. Kỹ sư `dh-platform` đọc chương 2.3–2.4, 4, 6, 8, 9, Phụ lục A. Kỹ sư phân hệ khác đọc mục 4.4, 6.3, 6.8, 9.3, 9.4 (nhóm `/internal`), 12, Phụ lục B. Kiểm thử viên đọc chương 6–9, 14 và dùng tenant `T90…T99`.

### 1.4. Thuật ngữ và chữ viết tắt

Bảng chỉ gồm thuật ngữ dùng trong tập này; thuật ngữ đa tenant chung (tenant, `PLATFORM`, `COMMON`, chế độ cách ly, `TenantContext`, `app.tenant_id`, tenant nguồn, tenant đích, thời gian chuyển tiếp) theo D03-10 §1.4.

| Thuật ngữ | Giải thích |
|---|---|
| Saga | Chuỗi bước giao dịch cục bộ trên nhiều hệ, mỗi bước có thao tác bù trừ; khi một bước lỗi, các bước đã xong được bù ngược thay cho giao dịch phân tán |
| Kiểm tra khói (smoke test) | Bộ ca kiểm tra nhanh sau khởi tạo: đăng nhập quản trị, gọi API mẫu, phát nhận sự kiện mẫu, một ca rò rỉ chéo |
| Mẫu khởi tạo (`provisioning_template`) | Gói cấu hình có phiên bản quyết định phân hệ bật sẵn, hạn mức mặc định, tổ chức gieo, bộ chỉ tiêu, danh mục nền cho tenant mới |
| Lệch cấu hình (drift) | Khác biệt giữa trạng thái mong muốn trong Git và trạng thái thực ở cụm hoặc ở phân hệ đích |
| Hạn mức hợp đồng | Mức tài nguyên tối đa theo hợp đồng dịch vụ của tỉnh, một giá trị cho mỗi `QuotaResource` |
| Hạn mức hiệu lực | Giá trị nơi thực thi áp dụng: hạn mức hợp đồng, hoặc ghi đè còn hạn nếu lớn hơn, không vượt trần nền tảng |
| Gói bàn giao | Gói dữ liệu của tenant xuất theo từng phân hệ, có bản kê và chữ ký, giao cho tỉnh trước khi chấm dứt |
| Thời gian nguội | Số ngày tối thiểu giữa tạm ngừng có quyết định chấm dứt và thực hiện chấm dứt (`20.terminate.cooling-days`) |
| Xóa mật mã (crypto-shred) | Hủy KEK của tenant để dữ liệu mã hóa còn sót không giải mã được (SEC-88, FR-09-043) |
| Bên tham gia sáp nhập (`MergeParticipant`) | Hợp đồng mỗi phân hệ có dữ liệu cung cấp để xuất, nhập, kiểm đếm dữ liệu khi sáp nhập (ADR 202 đề xuất) |
| PA, PO, PAU, TA, TO, SO, AU, VW, DS | Viết tắt vai trò, xem mục 3.1 |

: Thuật ngữ và chữ viết tắt của FRS PH-20

### 1.5. Tài liệu tham chiếu

Tài liệu pháp lý dùng mã CMP-LAW của D00-01 §7; ADR có tệp được dẫn mã đầy đủ, ADR đề xuất của tập này viết dạng "ADR 200" vì chưa có tệp (nội dung ở mục 12.3).

| Loại | Tài liệu |
|---|---|
| Pháp lý | CMP-LAW-03, CMP-LAW-05, CMP-LAW-06, CMP-LAW-08, CMP-LAW-16 |
| Dự án | D01-02 Kế hoạch dự án (dòng 1.20, §10.8 kênh phát hành, §10.3 cấu hình tenant); D02-01 BRD (BO-06, KPI-12, REQ-20, BP-08); D02-02 SRS (FR-00-010…012, FR-00-071, NFR-00-057, NFR-00-060); D02-07 Từ điển dữ liệu (DD-01, DD-02); D02-08 Ma trận phân quyền; D03-07 Thiết kế ATTT (SEC-80…88); D03-09 Hạ tầng và DR; D03-10 Thiết kế đa tenant; D03-06-00 IA và mẫu màn hình; D00-04 Sổ tra cứu gọn |
| FRS phân hệ liên quan | D02-03-PH01, PH03, PH04, PH06, PH07, PH09, PH10, PH12, PH13, PH16, PH19 |
| ADR có tệp | ADR-001 (Spring Boot Modulith), ADR-003 (PostgreSQL RLS), ADR-004 (Kafka), ADR-006 (Keycloak, OPA), ADR-009 (GitOps Argo CD), ADR-012 (OpenBao), ADR-020 (Liquid Glass), ADR-031 (kiểm toán chuỗi băm, WORM), ADR-032 (KEK theo tenant), ADR-042 (inbox, outbox), ADR-046 (phê duyệt bốn mắt), ADR-047 (lưu trữ phân vùng) |
| ADR đề xuất | ADR 200 (saga trên PostgreSQL), ADR 201 (cấu hình tenant trên Git), ADR 202 (hợp đồng bên tham gia sáp nhập), ADR 203 (kênh phát hành và nâng cấp theo sóng), ADR 204 (đo sử dụng bằng ảnh chụp hằng giờ) |
| SRS cũ | Không có `docs/07-srs/SRS-PH-20-*.md`; nguồn thay thế ở mục 11.3 |

: Tài liệu tham chiếu của FRS PH-20

### 1.6. Cấu trúc tài liệu

Tài liệu theo khung K-FRS: chương 1–5 giới thiệu, tổng quan, tác nhân, mô hình nghiệp vụ, danh sách chức năng; chương 6 đặc tả 70 chức năng; chương 7–9 quy tắc, yêu cầu phi chức năng, tham số, mã lỗi, sự kiện, API; chương 10–14 giao diện, truy vết, phụ thuộc, câu hỏi mở, tiêu chí chấp nhận; Phụ lục A là nguồn chuẩn enum, Phụ lục B đề nghị đồng bộ, Phụ lục C nhật ký hấp thụ đề nghị.

## 2. Tổng quan phân hệ

### 2.1. Bối cảnh và vấn đề cần giải quyết

Hệ LGSP cũ là một bản cài cho một tỉnh. Muốn có tỉnh thứ hai thì cài lại từ đầu: dựng cụm, tạo realm, khai báo bucket, tạo topic, nhập danh mục, cấu hình gateway, mỗi bước làm tay theo sổ tay, mất nhiều tuần (BO-06 ghi hiện trạng "triển khai riêng, nhiều tuần"). Cấu hình hệ thống (LGC-BUS-031) nằm trong bảng của từng bản cài, không có lịch sử, không so sánh được giữa các tỉnh. Hệ cũ cũng không có khái niệm sáp nhập: khi hai tỉnh hợp nhất theo sắp xếp đơn vị hành chính, dữ liệu, tài khoản và HTTT phải chuyển tay, HTTT phải đổi địa chỉ cùng lúc. Việc nâng cấp từng bản cài do nhà thầu làm theo lịch riêng, nên các tỉnh chạy nhiều phiên bản khác nhau và lỗi của một bản vá có thể lan khắp nơi.

| Hạn chế hiện tại | Cách PH-20 khắc phục |
|---|---|
| Mỗi tỉnh cài riêng, các bước làm tay | Saga mười bảy bước tự động, lũy đẳng, có bù trừ; mục tiêu ≤ 1 giờ (FR-20-008, NFR-20-001) |
| Cấu hình trong bảng của từng bản cài | Cấu hình tenant trong Git, mỗi lần đổi là một commit ký; đối chiếu lệch hằng giờ (FR-20-020, 021, 022) |
| Không đo được tỉnh dùng bao nhiêu tài nguyên | Hạn mức hợp đồng đẩy xuống nơi thực thi, ảnh chụp sử dụng hằng giờ, cảnh báo 80% và 100% (FR-20-026…032) |
| Không có thủ tục tạm ngừng, chấm dứt | Tạm ngừng có lý do, chấm dứt bốn mắt sau bàn giao gói dữ liệu và thời gian nguội, xóa mật mã (FR-20-038…042) |
| Sáp nhập tỉnh phải chuyển tay | Kế hoạch sáp nhập có ánh xạ, chạy thử, xung đột, chuyển định danh, chuyển tiếp 6 tháng, giữ `origin_tenant_id` (FR-20-045…052) |
| Danh mục tổ chức nằm rải rác ở từng phân hệ | Một danh mục tổ chức DD-02 có hiệu lực và tổ chức kế thừa, phát sự kiện cho mọi phân hệ (FR-20-053…058) |
| Nâng cấp theo lịch riêng từng bản cài | Kênh phát hành, sóng nâng cấp theo cửa sổ bảo trì, tự dừng khi lỗi vượt ngưỡng, quay lui (FR-20-059…064) |

: Hạn chế hiện tại và cách PH-20 khắc phục

### 2.2. Mục tiêu của phân hệ

Năm mục tiêu dưới đo được và gắn với yêu cầu phi chức năng ở mục 8.1.

| # | Mục tiêu | Đo bằng |
|---|---|---|
| 1 | Tỉnh mới sẵn sàng nhanh: saga `SHARED` xong ≤ 60 phút p95; từ khai báo tới `ACTIVE` kèm cấu hình ≤ 1 ngày làm việc (KPI-12) | NFR-20-001, NFR-20-002 |
| 2 | Nền tảng đủ sức chứa: ≥ 34 tenant tỉnh (NFR-00-060) trên một nền tảng dùng chung, registry đáp ứng mọi DU | NFR-20-003, NFR-20-005 |
| 3 | Không có tenant chạy ngoài hợp đồng: 100% tenant có hạn mức hiệu lực ở nơi thực thi, cảnh báo ≤ 5 phút sau ảnh chụp chạm ngưỡng | NFR-20-008, NFR-20-009 |
| 4 | Sáp nhập không mất dữ liệu: kiểm đếm khớp 100% theo phân hệ, 0 lượt gọi thất bại do cutover | NFR-20-014, NFR-20-015 |
| 5 | Phát hành an toàn: sóng tự dừng ≤ 5 phút khi tỷ lệ lỗi vượt ngưỡng; 0 tenant nâng cấp ngoài cửa sổ bảo trì (trừ đường khẩn) | NFR-20-016, BR-20-033 |

: Mục tiêu đo được của PH-20

### 2.3. Vị trí trong kiến trúc

PH-20 nằm trong DU `dh-platform` ở vùng ứng dụng nội bộ Z3 (giả định namespace `dh-control`, D03-09), cùng PH-11, PH-12 (phần quản trị), PH-13, PH-16, PH-18. Phân hệ là **control plane của control plane**: không nằm trên đường gọi API của HTTT, nhưng mọi phân hệ khác đọc registry của nó để biết tenant nào tồn tại, đang ở trạng thái nào, được bật phân hệ nào. Quản trị nền tảng dùng nhóm API `/api/platform/v1` (chỉ vai trò nền tảng, không mở ra cổng công khai); quản trị tỉnh dùng `/api/tenant/v1`; phân hệ khác dùng `/internal/tenant/v1` trong mesh.

```{.mermaid caption="Vị trí PH-20 trong kiến trúc Datahub"}
flowchart TB
  subgraph UI["dh-console"]
    NT["/nen-tang/* quản trị nền tảng"]
    QT["/quan-tri/cai-dat-tinh, /quan-tri/to-chuc"]
  end
  subgraph PLT["DU dh-platform (Z3)"]
    TEN["PH-20 mô-đun tenant<br/>vn.datahub.platform.tenant"]
    REL["PH-20 mô-đun release<br/>vn.datahub.platform.release"]
    P12A["PH-12 quản trị"]
    P13["PH-13 Giám sát"]
    P16["PH-16 Chỉ tiêu"]
    P18["PH-18 Vận hành"]
  end
  PG[("pg-core<br/>schema ph20_tenant")]
  GIT[("Git dh-tenant-config<br/>tenants/{ma-tenant}/")]
  ARGO["Argo CD"]
  K["Kafka<br/>platform.tenant.*.v1"]
  subgraph INFRA["Hạ tầng"]
    KC["Keycloak"]
    BAO["OpenBao"]
    S3["Ceph RGW"]
    CNPG["CloudNativePG"]
  end
  subgraph DP["Phân hệ khác"]
    P03["PH-03 APISIX"]
    P04["PH-04 Tích hợp"]
    P07["PH-07 Danh mục"]
    P10["PH-10 Sự kiện"]
    P01["PH-01, 06, 09, 17, 19"]
  end
  NT --> TEN
  NT --> REL
  QT --> TEN
  TEN --> PG
  REL --> PG
  TEN -->|"commit ký"| GIT
  GIT --> ARGO
  ARGO --> DP
  TEN -->|"API-12-080"| P12A
  P12A --> KC
  TEN -->|"API-13-072"| P13
  TEN -->|"API-07-073"| P07
  TEN --> BAO
  TEN --> S3
  TEN --> CNPG
  TEN -->|"EVT-20"| K
  K --> DP
  DP -->|"registry, báo tiến độ"| TEN
  TEN -->|"API-16-030"| P16
  TEN -->|"tham số, thông báo, merge-transfers"| P18
  P13 -->|"Mimir: số liệu sử dụng"| TEN
```

Hình cho thấy PH-20 có ba đường ra: gọi đồng bộ phân hệ có API khởi tạo (PH-12, PH-13, PH-07, PH-16) và hạ tầng; phát sự kiện `platform.tenant.*.v1` cho phân hệ tự khởi tạo; ghi trạng thái mong muốn vào Git để Argo CD áp. Phân hệ khác giữ đệm registry nên PH-20 dừng không làm data plane ngừng.

### 2.4. Kiến trúc thành phần và công nghệ

Mô-đun `tenant` gồm tám thành phần nội bộ. **Hồ sơ** (`tenant-registry`) giữ bản ghi tenant, đầu mối, hợp đồng, phục vụ registry đọc có đệm Valkey 60 giây. **Điều phối saga** (`tenant-provisioning`) giữ lần chạy và sổ bước trong PostgreSQL, chạy bằng bộ thực thi nội bộ dưới khóa ShedLock, mỗi bước gọi bên thực hiện với `Idempotency-Key = {runId}:{stepCode}`, bù trừ ngược khi hủy (ADR 200 đề xuất; không dùng Temporal, Camunda, Flowable). **Cấu hình** (`tenant-config`) commit YAML có ký vào `dh-tenant-config` qua JGit, theo dõi Argo CD, đối chiếu lệch (ADR 201 đề xuất). **Hạn mức, sử dụng** (`tenant-quota`) tính hạn mức hiệu lực, đẩy qua sự kiện EVT-20-05, thu ảnh chụp sử dụng hằng giờ từ Mimir và nơi thực thi vào bảng phân vùng theo tháng (ADR 204 đề xuất, ADR-047). **Vòng đời** (`tenant-lifecycle`) giữ đề nghị có duyệt, thực thi tạm ngừng, khôi phục, chấm dứt, gói bàn giao. **Sáp nhập** (`tenant-merge`) giữ kế hoạch, ánh xạ, lần chuyển theo phân hệ, xung đột, điều phối PH-18 và phân hệ tham gia (ADR 202 đề xuất). **Tổ chức** (`tenant-org`) giữ danh mục DD-02, nhập xuất tệp bằng Apache POI. **Kiểm thử rò rỉ** (`tenant-leaktest`) chạy bộ ca rò rỉ chéo hằng đêm trên tenant kiểm thử. Mô-đun `release` giữ phiên bản sản phẩm, kênh, kế hoạch nâng cấp theo sóng; nâng cấp một tenant là đổi thẻ phiên bản trong overlay Kustomize của tenant ở `dh-tenant-config` rồi để Argo CD áp (ADR 203 đề xuất).

Sự kiện phát qua outbox (ADR-042). Gói công bố `tenant.api` là điểm phụ thuộc duy nhất của mô-đun khác trong `dh-platform` (ArchUnit kiểm). Bảng `tenant` không có cột `tenant_id` (D02-07): tenant `PLATFORM` thấy và ghi mọi dòng, tenant khác chỉ đọc dòng của mình; bảng theo tenant có RLS chuẩn; nhóm `/api/platform/` dùng vai trò kết nối `ph20_platform_app`, không có `BYPASSRLS` (FR-00-012).

Sơ đồ dưới là trình tự saga khởi tạo tenant `T68` ở chế độ `SHARED`, điểm vào của nhóm B. Bước đồng bộ do PH-20 gọi và chờ kết quả; bước bất đồng bộ do phân hệ đích tự xử lý sau EVT-20-01 hoặc EVT-20-07 rồi báo về API-20-166.

```{.mermaid caption="Trình tự saga khởi tạo tenant T68 ở chế độ SHARED"}
sequenceDiagram
  actor PA as Quản trị nền tảng
  participant P20 as PH-20 saga
  participant GIT as Git dh-tenant-config
  participant P12 as PH-12
  participant BAO as OpenBao
  participant S3 as Ceph RGW
  participant K as Kafka
  participant PX as PH-10, 03, 04, 06
  participant P13 as PH-13
  participant P07 as PH-07
  participant P16 as PH-16
  PA->>P20: Khai báo T68, chạy saga
  P20->>P20: S01_RECORD bản ghi PROVISIONING
  P20->>GIT: S02_CONFIG_REPO commit tenants/T68/
  P20->>P12: S03_REALM API-12-080 realm dh-t68
  P20->>BAO: S04_SECRETS kv/dh/t68, KEK dh-t68-pii
  P20->>S3: S05_BUCKETS dh-t68-*
  P20->>K: EVT-20-01 platform.tenant.created.v1
  K->>PX: S06, S09, S10, S12 tự khởi tạo
  PX-->>P20: Báo tiến độ API-20-166
  Note over P20: S07_DATABASE SKIPPED vì SHARED
  P20->>P13: S08_OBSERVABILITY API-13-072
  P20->>P07: S11_SEED_RDM API-07-073
  P20->>P20: S13_ORG_SEED tổ chức cấp tỉnh
  P20->>P16: S14_KPI kế thừa bộ chỉ tiêu (FR-16-008)
  P20->>K: S15_MODULES EVT-20-07 theo mẫu
  K-->>P20: Phân hệ báo xong
  P20->>P20: S16_SMOKE kiểm tra khói
  P20->>K: S17_ACTIVATE EVT-20-03 activated
  P20->>P16: API-16-030 thời gian khởi tạo (KPI-12)
  P20-->>PA: T68 ACTIVE, thư bàn giao tới đầu mối
```

Hình cho thấy saga chỉ phát EVT-20-01 sau khi realm, bí mật và bucket đã có, nên phân hệ bất đồng bộ nhận sự kiện là có đủ nền để tự khởi tạo. Các bước bất đồng bộ chạy song song và saga đợi đủ báo cáo trước khi tới `S11_SEED_RDM`; bước nào hết `20.provision.step-timeout-minutes` mà chưa báo thì `FAILED`. Kiểm tra khói `S16_SMOKE` là cửa bắt buộc: tenant chưa đạt không bao giờ sang `ACTIVE` (BR-20-004).

### 2.5. Quy trình nghiệp vụ liên quan

PH-20 là phân hệ chính của BP-08 "Khởi tạo tenant tỉnh mới" (D02-01). Tài liệu đề nghị bổ sung BP-12 "Sáp nhập tenant khi sắp xếp đơn vị hành chính" và BP-13 "Phát hành và nâng cấp sản phẩm cho các tỉnh" (Phụ lục B; BP-10, BP-11 đã được PH-08, PH-16 đề nghị).

| Quy trình | Bước có PH-20 |
|---|---|
| BP-08 Khởi tạo tenant tỉnh mới | Khai báo, kiểm tra sẵn sàng, saga, kiểm tra khói, kích hoạt, bàn giao; đo KPI-12 (FR-20-001…014) |
| BP-01 Kết nạp HTTT | Tổ chức chủ quản của HTTT lấy từ danh mục tổ chức (FR-20-057); tenant phải `ACTIVE` |
| BP-03 Phát hành và đồng bộ danh mục | Gói danh mục nền nạp khi khởi tạo (`S11_SEED_RDM`); EVT-07-10 sắp xếp ĐVHC đề xuất đồng bộ tổ chức (FR-20-056) |
| BP-07 Giám sát, xử lý sự cố, báo cáo | Cảnh báo hạn mức (FR-20-029), tạm ngừng do sự cố an ninh (FR-20-038), kiểm thử rò rỉ (FR-20-070) |
| BP-12 (đề nghị) Sáp nhập tenant | Kế hoạch, ánh xạ, chạy thử, duyệt, chuyển dữ liệu, xung đột, chuyển định danh, cutover, chuyển tiếp, kết thúc (FR-20-045…052) |
| BP-13 (đề nghị) Phát hành sản phẩm | Đăng ký phiên bản, `PREVIEW`, thí điểm 14 ngày, `STABLE`, kế hoạch sóng, nâng cấp trong cửa sổ, dừng, quay lui (FR-20-059…064) |

: Quy trình nghiệp vụ có PH-20 tham gia

### 2.6. Chức năng hệ cũ được phủ

Hệ cũ không có khái niệm tenant nên D00-03 không có `LGC` nào ghi PH-20 làm chính, đúng với REQ-20 là năng lực mới. Hai mục dưới là chức năng hệ cũ mà PH-20 tham gia gián tiếp; kết luận chính giữ ở phân hệ làm chính (mục 11.1).

| Mã | Chức năng hệ cũ | Vai trò của PH-20 |
|---|---|---|
| LGC-IAM-002 | Tạo realm, client, vai trò | PH-12 làm chính; PH-20 khởi tạo tự động realm, client, vai trò chuẩn và quản trị tỉnh đầu tiên cho tenant mới qua bước `S03_REALM` (FR-20-008) |
| LGC-BUS-031 | Cấu hình hệ thống | PH-18 làm chính (tham số); PH-20 giữ cấu hình nền tảng theo tenant, cài đặt tỉnh và lịch sử phiên bản cấu hình trong Git (FR-20-018…022) |

: Chức năng hệ cũ liên quan gián tiếp tới PH-20

## 3. Tác nhân, vai trò và quyền

### 3.1. Tác nhân

PH-20 không tạo vai trò mới; mọi vai trò lấy từ D02-08. Vai trò nền tảng chỉ tồn tại ở tenant `PLATFORM`; khi tác động một tenant tỉnh, họ dùng nhóm API `/api/platform/v1` và mỗi thao tác ghi phải có lý do và mã phiếu (BR-20-009).

| Viết tắt | Tác nhân | Mô tả | Tương tác chính |
|---|---|---|---|
| PA | ROLE-PLATFORM_ADMIN | Quản trị nền tảng | Khai báo, khởi tạo, cấu hình, hạn mức, vòng đời, sáp nhập, phát hành, mẫu khởi tạo, duyệt bốn mắt |
| PO | ROLE-PLATFORM_OPERATOR | Vận hành nền tảng | Theo dõi saga, sử dụng, cảnh báo, nâng cấp; dừng sóng nâng cấp |
| PAU | ROLE-PLATFORM_AUDITOR | Kiểm toán nền tảng | Xem tenant, lịch sử vòng đời, kiểm toán toàn nền tảng, chỉ đọc |
| TA | ROLE-TENANT_ADMIN | Quản trị tỉnh | Cài đặt tỉnh, tổ chức, chính sách tiếp nhận liên tenant, cửa sổ bảo trì, xem sử dụng, phần sáp nhập của tỉnh mình |
| TO | ROLE-TENANT_OPERATOR | Vận hành tỉnh | Xem sử dụng, hạn mức, phiên bản, lịch bảo trì |
| SO | ROLE-SECURITY_OFFICER | Cán bộ an toàn thông tin tỉnh | Xem chính sách và nhật ký truy cập liên tenant |
| AU | ROLE-AUDITOR | Kiểm toán viên tỉnh | Xem sử dụng, nhật ký liên tenant, nhật ký kiểm toán PH-20 của tỉnh |
| DS | ROLE-DATA_STEWARD | Cán bộ quản lý dữ liệu | Xem tổ chức, tra chủ quản dữ liệu |
| VW | ROLE-VIEWER | Người xem | Xem danh mục tổ chức |
| Phân hệ tham gia saga | PH-03, 04, 06, 10, 17, 19… | Tự khởi tạo phần của mình | Nghe EVT-20-01, 07; báo tiến độ API-20-166 |
| Phân hệ được gọi | PH-07, 09, 12, 13, 16 | Cung cấp API khởi tạo, khóa, chuyển định danh | Nhận lời gọi có `Idempotency-Key` |
| PH-18 | Vận hành và xử lý lỗi | Tham số, thông báo, chuyển dữ liệu sáp nhập | Nhận đăng ký `20.*`, thư; chạy `merge-transfers`, báo API-20-167 |
| Phân hệ đọc registry | Mọi DU | Đọc trạng thái, cấu hình thực thi, tổ chức | API-20-162…165, 169…171 |
| Argo CD | Công cụ GitOps | Áp `dh-tenant-config` | PH-20 đọc trạng thái đồng bộ |
| Bộ lập lịch PH-20 | Tác vụ nền | Thu sử dụng, đối chiếu lệch, kiểm thử rò rỉ, hết hạn ghi đè | Chạy trong `TenantContext` của `PLATFORM` |

: Tác nhân của PH-20

### 3.2. Ma trận quyền

D02-08 hiện có `PERM-20-admin` (PA) và `PERM-20-read` (PA, PO, TA, AU); mười quyền còn lại là đề nghị, ghi ở Phụ lục B và có hiệu lực khi được gộp. Ký hiệu: ● được cấp; ○ được cấp có giới hạn (ghi chú dưới bảng); trống là không.

| Quyền | Nghĩa | PA | PO | PAU | TA | TO | SO | AU | DS | VW |
|---|---|---|---|---|---|---|---|---|---|---|
| `PERM-20-read` | Xem tenant, saga, hạn mức, phân hệ, vòng đời, sáp nhập, phát hành | ● | ● | ● | ○ | | | ○ | | |
| `PERM-20-admin` | Sửa hồ sơ, đầu mối, hợp đồng, cấu hình nền tảng, phân hệ, cờ, mẫu khởi tạo, kiểm thử rò rỉ | ● | | | | | | | | |
| `PERM-20-provision` | Khai báo tenant, chạy, thử lại, bỏ qua, bù trừ, hủy saga, kích hoạt; cụm riêng | ● | | | | | | | | |
| `PERM-20-lifecycle` | Đề nghị tạm ngừng, khôi phục, chấm dứt, đổi chế độ cách ly; gói bàn giao; thực hiện đề nghị đã duyệt | ● | | | | | | | | |
| `PERM-20-approve` | Duyệt bốn mắt đề nghị chấm dứt, sáp nhập, đổi hạn mức, đổi chế độ cách ly | ● | | | | | | | | |
| `PERM-20-quota` | Đặt, đổi hạn mức, ghi đè tạm thời, xác nhận cảnh báo | ● | | | | | | | | |
| `PERM-20-merge` | Lập, chạy, kết thúc sáp nhập | ● | | | | | | | | |
| `PERM-20-release` | Phiên bản, kênh, kế hoạch nâng cấp | ● | ○ | | | | | | | |
| `PERM-20-settings` | Cài đặt tỉnh, chính sách tiếp nhận liên tenant, cửa sổ bảo trì của tỉnh | | | | ● | | | | | |
| `PERM-20-org` | Tạo, sửa, ngừng, giải thể, nhập, xuất tổ chức; đánh dấu chủ quản dữ liệu | | | | ● | | | | | |
| `PERM-20-org-read` | Xem danh mục tổ chức, cài đặt tỉnh (phần hiển thị), phiên bản | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| `PERM-20-usage-read` | Xem sử dụng tài nguyên, hạn mức của tỉnh | | | | ● | ● | | ● | | |

: Ma trận quyền PH-20 theo vai trò

Ghi chú: TA và AU với `PERM-20-read` chỉ đọc được bản ghi tenant của chính tỉnh mình qua `/api/tenant/v1/context` và phần sáp nhập liên quan tới tỉnh mình ở UI-20-10, không gọi được `/api/platform/v1`. PO với `PERM-20-release` chỉ theo dõi và dừng sóng (API-20-122), không lập, không tiếp tục, không quay lui. SO và AU đọc chính sách và nhật ký liên tenant của tỉnh (API-20-137, API-20-139) dù không có `PERM-20-settings`. PAU đọc nhật ký kiểm toán toàn nền tảng (API-20-130) với `PERM-20-read`. Người có `PERM-20-approve` không duyệt được đề nghị do chính mình lập hoặc gửi (BR-20-008).

### 3.3. Tách nhiệm vụ và tài khoản máy

Năm cặp loại trừ áp dụng trên cùng một đối tượng, không phụ thuộc vai trò (BR-20-008). Nền tảng cần ít nhất hai người giữ `PERM-20-approve`; chỉ một người thì UI-20-08, UI-20-09 cảnh báo và việc duyệt bị chặn, không cho tự duyệt.

| Cặp loại trừ | Áp dụng | Mã lỗi khi vi phạm |
|---|---|---|
| Người lập, gửi đề nghị chấm dứt ≠ người duyệt | FR-20-040 | ERR-20-007 |
| Người lập, gửi kế hoạch sáp nhập ≠ người duyệt | FR-20-045 | ERR-20-007 |
| Người đề nghị đổi chế độ cách ly ≠ người duyệt | FR-20-025 | ERR-20-007 |
| Người đề nghị hạ hạn mức dưới mức đang dùng ≠ người duyệt | FR-20-027 | ERR-20-007 |
| Người duyệt chấm dứt ≠ người xác nhận bàn giao gói dữ liệu | FR-20-041, FR-20-042 | ERR-20-007 |

: Cặp loại trừ tách nhiệm vụ của PH-20

Tài khoản máy dùng token Keycloak luồng client credentials của realm `dh-platform`, mTLS trong mesh (ADR-006). Scope dưới đây do PH-20 cấp cho phân hệ khác hoặc PH-20 dùng khi gọi đi.

| Scope | Bên giữ | Được gọi |
|---|---|---|
| `tenant:registry-read` | Mọi DU, APISIX plugin của PH-03, PH-12, tác vụ nền của mọi phân hệ | API-20-162, API-20-163, API-20-164, API-20-165 |
| `tenant:org-read` | PH-01, PH-06, PH-07, PH-08, PH-12, PH-16 | API-20-169, API-20-170, API-20-171 |
| `tenant:provision-report` | Phân hệ tham gia saga, PH-18 và phân hệ tham gia sáp nhập, phân hệ xuất gói bàn giao | API-20-166, API-20-167, API-20-168 |
| `iam:realm-provision` (PH-20 gọi đi) | PH-20 | API-12-080, API-12-084, API-12-085, API-12-045, API-12-046 |
| `obs:tenant-provision` (PH-20 gọi đi) | PH-20 | API-13-072, API-13-073 |
| `platform.tenant.provision` (PH-20 gọi đi, giả định của PH-07) | PH-20 | API-07-073 |
| `event:topic-register` (PH-20 gọi đi) | PH-20 | Đăng ký topic `platform.tenant.*.v1`, `platform.release.*.v1` ở PH-10 (FR-10-067) |
| `kpi.ingest` (PH-20 gọi đi) | PH-20 | API-16-030 |
| Tài khoản dịch vụ `svc-ph20-gitops` | PH-20 | Ghi `dh-tenant-config` bằng commit ký; khóa ký ở OpenBao |

: Scope dịch vụ liên quan tới PH-20

## 4. Khái niệm và mô hình nghiệp vụ

### 4.1. Khái niệm nghiệp vụ

Một **tenant** (DD-01) ứng với một tỉnh hoặc thành phố trực thuộc trung ương, có mã `T-TENANT` dạng `^T\d{2}$` (ví dụ `T68`, `T01`; `T90…T99` dành cho kiểm thử), loại `TenantKind` (`PROVINCE`, hoặc hai tenant đặc biệt `PLATFORM`, `COMMON`), đơn vị hành chính cấp tỉnh tương ứng ở danh mục `COMMON` của PH-07, chế độ cách ly, hồ sơ quy mô, hồ sơ triển khai và realm `dh-{mã thường}`. Mã và realm bất biến sau khai báo (BR-20-001). Tenant có **đầu mối** (lãnh đạo phụ trách, quản trị tỉnh, kỹ thuật, an toàn thông tin) và **hợp đồng dịch vụ** có hiệu lực, là căn cứ của hạn mức.

**Khởi tạo** là một **lần chạy saga** gồm mười bảy **bước** (mục 4.4). Lần chạy loại `INITIAL` tạo tenant mới; `SUPPLEMENT` chạy bổ sung những bước mới mà nền tảng thêm sau khi tenant đã `ACTIVE` (FR-20-016); `ISOLATION_CHANGE` chuyển chế độ cách ly (FR-20-025). Mỗi lần chạy dùng một phiên bản **mẫu khởi tạo** quyết định phân hệ bật sẵn, hạn mức mặc định theo hồ sơ quy mô, gói danh mục nền, tổ chức gieo, bộ chỉ tiêu.

**Cấu hình** của tenant có ba lớp. *Cấu hình nền tảng* (EN-20-05) do PA giữ: realm, host và tiền tố API công bố, hồ sơ triển khai, vùng DR, kênh phát hành. *Cài đặt tỉnh* (EN-20-06) do TA tự quản trong giới hạn nền tảng (tên hiển thị, chủ quản CNTT, phiên, mật khẩu, cửa sổ bảo trì). *Chính sách tiếp nhận liên tenant* (EN-20-29): tỉnh cho phép vai trò nền tảng vào ở mức nào. Hai lớp đầu được ghi vào Git `dh-tenant-config/tenants/{ma-tenant}/` thành tệp `tenant.yaml`, `settings.yaml`, `quota.yaml`, `modules.yaml`, `release.yaml`; mỗi lần đổi là một **phiên bản cấu hình** (EN-20-07) ứng với một commit.

**Hạn mức** gồm mười hai tài nguyên `QuotaResource`; sáu tài nguyên đầu theo D03-10 §5.3, sáu tài nguyên sau là giả định có cơ sở dưới đây. **Hạn mức hiệu lực** = max(hạn mức hợp đồng, ghi đè còn hạn) nhưng không vượt trần nền tảng của hồ sơ quy mô (BR-20-013). PH-20 không tự chặn lượt gọi; nó đẩy hạn mức hiệu lực xuống nơi thực thi và đo sử dụng thực tế bằng **ảnh chụp** hằng giờ.

| `QuotaResource` | Đơn vị | Mặc định `QM-VUA` | Nơi thực thi |
|---|---|---|---|
| `API_RPS` | lượt/giây | 500 | APISIX `limit-count` theo nhãn tenant (PH-03) |
| `ACTIVE_FLOWS` | luồng | 1.000 | PH-04 khi phát hành |
| `KAFKA_PRODUCE_MBPS` | MB/s | 10 | Quota Kafka (PH-10) |
| `KAFKA_CONSUME_MBPS` | MB/s | 20 | Quota Kafka (PH-10) |
| `OBJECT_STORAGE_GB` | GB | 500 | Ceph RGW quota bucket |
| `DATABASE_GB` | GB | 200 | Giám sát, cảnh báo (không cắt) |
| `USERS` | người dùng | 2.000 | PH-12 khi tạo người dùng |
| `MEMBER_SYSTEMS` | HTTT | 300 (giả định: GĐ-01 tỉnh vừa 200 HTTT + 50%) | PH-01 khi kết nạp |
| `PUBLISHED_APIS` | API | 2.000 (giả định: 200 HTTT × 10 API) | PH-02 khi công bố |
| `TOPICS` | topic | 2.000 (giả định: cùng cơ sở như API) | PH-10 khi tạo topic |
| `RUNTIME_CPU` | vCPU | 16 (giả định: namespace runtime tỉnh vừa D03-09) | `ResourceQuota` namespace `dh-rt-{tenant}` |
| `RUNTIME_MEMORY_GB` | GB | 64 (giả định: tỷ lệ 1:4) | `ResourceQuota` |

: Mười hai tài nguyên hạn mức, mặc định và nơi thực thi (số đo lấy từ Mimir hoặc API thống kê của nơi thực thi; `DATABASE_GB` xem Q20-07)

**Phân hệ** của nền tảng (EN-20-18) có mã `PH-01`…`PH-20`, cờ lõi, đợt, và **phụ thuộc** (EN-20-19). Mỗi tenant có một bản ghi **phân hệ theo tenant** (EN-20-20) với trạng thái `ModuleState`. Bật phân hệ phát EVT-20-07 để phân hệ đó tự khởi tạo phần của tenant (ví dụ PH-19 FR-19-064), rồi báo về. Phân hệ chưa bật trả ERR-20-103 ở data plane hoặc mã riêng của phân hệ (PH-19 dùng ERR-19-049).

**Vòng đời** gồm các **đề nghị** có duyệt (EN-20-22) loại `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE`. Tạm ngừng và khôi phục không cần bốn mắt (cần nhanh khi có sự cố) nhưng phải có lý do, mã phiếu và văn bản căn cứ khi lý do là `MANAGEMENT_DECISION`. Chấm dứt cần bốn mắt, gói bàn giao `DELIVERED` và thời gian nguội. **Sáp nhập** là một **kế hoạch** (EN-20-25) từ một hoặc nhiều tenant nguồn vào một tenant đích, có **bảng ánh xạ** theo `MergeMappingType`, **lần chuyển theo phân hệ** (EN-20-27) và **xung đột** (EN-20-28).

**Tổ chức** (DD-02) là cơ quan, đơn vị trong tỉnh, có cây cấp trên, loại `OrgType`, địa bàn, hiệu lực, cờ chủ quản dữ liệu và tổ chức kế thừa khi giải thể, sáp nhập. **Phiên bản sản phẩm** (EN-20-31) theo SemVer `MAJOR.MINOR.PATCH`, gồm danh sách thành phần (DU, ảnh container có digest, chart, migration) và ghi chú phát hành; tenant đăng ký một **kênh** cho mỗi môi trường; **kế hoạch nâng cấp** chia **sóng**, mỗi tenant trong sóng có một bản ghi **nâng cấp theo tenant**.

### 4.2. Thực thể

Bảng dưới là thực thể mức logic; tên bảng vật lý, khóa, chỉ mục ở D03-03-PH20. Mọi thực thể có `tenant_id` và RLS trừ EN-20-01 (chính là tenant) và các thực thể đánh dấu "dữ liệu nền tảng" (`tenant_id = 'PLATFORM'`). Bảng kỹ thuật chung: `outbox` (DD-11), `inbox_event`, `idempotency_key`, `file_object` (DD-12).

| Mã | Thực thể (bảng) | Nội dung chính | Quan hệ |
|---|---|---|---|
| EN-20-01 | Tenant (`tenant`, DD-01) | `code`, `name`, `kind`, `admin_unit_id`, `status`, `isolation_mode`, `realm`, `merged_into_id`, `declared_at`, `activated_at`… | 1–n với mọi thực thể dưới |
| EN-20-02 | Tổ chức (`organization`, DD-02) | `code`, `name`, `parent_id`, `org_type`, `admin_unit_id`, `is_data_owner`, `effective_from`, `effective_to`, `successor_id`, `status`, `origin_tenant_id` | Cây tự tham chiếu; thuộc EN-20-01 |
| EN-20-03 | Đầu mối tenant (`tenant_contact`) | `contactId`, `role` (`LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY`), họ tên, chức vụ, thư công vụ, điện thoại… | thuộc EN-20-01 |
| EN-20-04 | Hợp đồng dịch vụ (`tenant_contract`) | `contractId`, số hợp đồng, ngày ký, `validFrom`, `validTo`, bên ký… | thuộc EN-20-01; 1–1 EN-20-13 hiện hành |
| EN-20-05 | Cấu hình nền tảng (`tenant_platform_config`) | `realm`, `publicHost`, `apiPathPrefix`, `deploymentProfile`, `drRegion`, `clusterCode`… | 1–1 EN-20-01 |
| EN-20-06 | Cài đặt tỉnh (`tenant_settings`) | `displayName`, `logoFileId`, `itOwnerOrgCode`, `sessionIdleMinutes`, `passwordPolicy`, `mfaRequiredRoles`… | 1–1 EN-20-01 |
| EN-20-07 | Phiên bản cấu hình (`tenant_config_version`) | `versionNo`, `commitSha`, `changedFiles[]`, người đổi, lý do, mã phiếu… | thuộc EN-20-01 |
| EN-20-08 | Lệch cấu hình (`config_drift`) | `driftId`, `target` (Argo CD app, phân hệ), `path`, giá trị mong muốn, giá trị thực, `status`… | thuộc EN-20-01 |
| EN-20-09 | Mẫu khởi tạo (`provisioning_template`, dữ liệu nền tảng) | `templateCode`, `version`, `state`, `modules[]`, `quotaByScale`, `rdmPackageVersion`… | 1–n EN-20-10 |
| EN-20-10 | Lần chạy saga (`provisioning_run`) | `runId`, `runKind`, `status`, `templateVersion`, `startedAt`, `finishedAt`… | thuộc EN-20-01; 1–n EN-20-11 |
| EN-20-11 | Bước saga (`provisioning_step`) | `stepCode`, `order`, `status`, `executor`, `mode` (`SYNC`, `ASYNC`), `attempt`… | thuộc EN-20-10 |
| EN-20-12 | Kết quả kiểm tra khói (`smoke_test_result`) | `smokeId`, ca (`LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK`), kết quả, thời gian, bằng chứng | thuộc EN-20-10 |
| EN-20-13 | Hạn mức hợp đồng (`tenant_quota`) | `resource`, `contractValue`, `platformCeiling`, `effectiveValue`, `source`, `version` | thuộc EN-20-01 |
| EN-20-14 | Đề nghị đổi hạn mức (`quota_change_request`) | `requestId`, các dòng tài nguyên với giá trị cũ, mới, mức đang dùng, `requiresApproval`, `status`… | thuộc EN-20-01 |
| EN-20-15 | Ghi đè hạn mức tạm thời (`quota_override`) | `overrideId`, `resource`, `value`, `validFrom`, `validTo`, lý do… | thuộc EN-20-01 |
| EN-20-16 | Ảnh chụp sử dụng (`usage_snapshot`, phân vùng tháng) | `resource`, `hourStart`, `value`, `peakValue`, `effectiveLimit`, `percent`… | thuộc EN-20-01 |
| EN-20-17 | Cảnh báo hạn mức (`quota_alert`) | `alertId`, `resource`, `level` (`WARN_80`, `LIMIT_100`), `firstAt`, `lastAt`, `status` (`OPEN`, `ACKNOWLEDGED`, `RESOLVED`)… | thuộc EN-20-01 |
| EN-20-18 | Phân hệ của nền tảng (`platform_module`, dữ liệu nền tảng) | `moduleCode`, tên, `core`, `wave`, `asyncProvision`, `mergeParticipant`… | 1–n EN-20-19, EN-20-20 |
| EN-20-19 | Phụ thuộc phân hệ (`module_dependency`, dữ liệu nền tảng) | `moduleCode`, `dependsOn`, loại (`REQUIRED`, `OPTIONAL`) | thuộc EN-20-18 |
| EN-20-20 | Phân hệ theo tenant (`tenant_module`) | `moduleCode`, `state`, `enabledAt`, `disabledAt`, lý do, `lastReportAt` | thuộc EN-20-01 |
| EN-20-21 | Cờ tính năng theo tenant (`tenant_feature_flag`) | `flagCode`, `moduleCode`, `enabled`, `validTo`, lý do | thuộc EN-20-01 |
| EN-20-22 | Đề nghị vòng đời (`lifecycle_request`) | `requestId`, `requestType`, `status`, `reason`, `reasonText`, `ticketRef`… | thuộc EN-20-01 |
| EN-20-23 | Lịch sử trạng thái (`tenant_status_history`) | Trạng thái trước, sau, thời điểm, nguyên nhân (`requestId`, `runId`, `mergePlanId`), người | thuộc EN-20-01; chỉ thêm |
| EN-20-24 | Gói bàn giao (`data_export_package`, `data_export_item`) | `packageId`, `status`, phân hệ, số bản ghi, kích thước, băm SHA-256 từng phần… | thuộc EN-20-01 |
| EN-20-25 | Kế hoạch sáp nhập (`merge_plan`) | `mergePlanId`, nguồn[], đích, căn cứ (số, ngày văn bản), `status`, `effectiveDate`… | 1–n EN-20-26, 27, 28 |
| EN-20-26 | Ánh xạ sáp nhập (`merge_mapping`) | `mappingId`, `mappingType`, mã nguồn, mã đích, `action` (`MAP`, `CREATE`, `SKIP`), `origin` (`AUTO`, `MANUAL`) | thuộc EN-20-25 |
| EN-20-27 | Lần chuyển theo phân hệ (`merge_participant_run`) | `module`, `phase` (`DRY_RUN`, `TRANSFER`), `status`, số bản ghi nguồn, đã chuyển, trùng… | thuộc EN-20-25 |
| EN-20-28 | Xung đột sáp nhập (`merge_conflict`) | `conflictId`, `module`, loại đối tượng, mã, mô tả khác biệt, `resolution`… | thuộc EN-20-25 |
| EN-20-29 | Chính sách tiếp nhận liên tenant (`cross_tenant_policy`) | `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours`, `notifyContacts[]`, `blockedReasons[]`… | 1–1 EN-20-01 |
| EN-20-30 | Lô nhập tổ chức (`org_import_job`, `org_import_row`) | `importId`, tệp, `status`, số dòng, từng dòng với hành động (`CREATE`, `UPDATE`, `UNCHANGED`, `ERROR`) và lỗi | thuộc EN-20-01 |
| EN-20-31 | Phiên bản sản phẩm (`product_release`, `release_component`, dữ liệu nền tảng) | `releaseVersion`, `status`, `kind` (`MAJOR`, `MINOR`, `PATCH`), `securityPatch`, ghi chú, ngày `PREVIEW`… | 1–n EN-20-34 |
| EN-20-32 | Đăng ký kênh (`tenant_release_subscription`) | `environment` (`PROD`, `STAGING`), `channel`, `pinnedVersion`, `currentVersion`, `pilot` | thuộc EN-20-01 |
| EN-20-33 | Cửa sổ bảo trì (`maintenance_window`) | `windowId`, lặp (RRULE), độ dài, múi giờ `Asia/Ho_Chi_Minh`, nguồn (`TENANT_PREF`, `PLATFORM`), ngoại lệ ngày | thuộc EN-20-01 |
| EN-20-34 | Kế hoạch nâng cấp và sóng (`upgrade_plan`, `upgrade_wave`) | `planId`, phiên bản, `status`, sóng (thứ tự, tenant[], thời gian theo dõi, ngưỡng lỗi), `emergency` | 1–n EN-20-35 |
| EN-20-35 | Nâng cấp theo tenant (`tenant_upgrade`) | `tenantCode`, phiên bản từ, tới, `status`, cửa sổ dự kiến, thời điểm… | thuộc EN-20-34 |
| EN-20-36 | Lần kiểm thử rò rỉ (`leak_test_run`) | `testRunId`, tenant A, B (T90…T99), số ca, đạt, trượt… | dữ liệu nền tảng |
| EN-20-37 | Báo cáo sử dụng (`usage_report`) | `reportId`, phạm vi (`PLATFORM` hoặc tenant), kỳ, định dạng, tệp, `status` | độc lập |

: Thực thể mức logic của PH-20

### 4.3. Máy trạng thái tenant

Máy trạng thái tenant mở rộng sáu trạng thái của D03-10 §5.1 bằng trạng thái `FAILED` (đã có ở DD-01) và một chuyển `MERGING → ACTIVE` khi kế hoạch sáp nhập bị hủy trước cutover (đề nghị bổ sung D03-10, Phụ lục B).

```{.mermaid caption="Máy trạng thái tenant (DD-01)"}
stateDiagram-v2
  [*] --> PROVISIONING: Khai báo (FR-20-001)
  PROVISIONING --> ACTIVE: Saga xong, kiểm tra khói đạt (FR-20-013)
  PROVISIONING --> FAILED: Bước saga lỗi hoặc quá hạn
  FAILED --> PROVISIONING: Thử lại (FR-20-010)
  FAILED --> DECOMMISSIONED: Bù trừ xong, hủy khởi tạo (FR-20-011)
  ACTIVE --> SUSPENDED: Tạm ngừng có lý do (FR-20-038)
  SUSPENDED --> ACTIVE: Khôi phục (FR-20-039)
  ACTIVE --> MERGING: Kế hoạch sáp nhập bắt đầu chuyển (FR-20-048)
  MERGING --> ACTIVE: Hủy kế hoạch trước cutover
  MERGING --> MERGED: Cutover (FR-20-051)
  SUSPENDED --> DECOMMISSIONED: Chấm dứt (FR-20-042)
  MERGED --> DECOMMISSIONED: Kết thúc sáp nhập (FR-20-052)
  DECOMMISSIONED --> [*]
```

`PROVISIONING`: saga đang chạy; data plane trả ERR-20-101; chỉ PA, PO thấy. `FAILED`: saga dừng ở một bước; tài nguyên đã tạo còn nguyên để thử lại; data plane trả ERR-20-101. `ACTIVE`: phục vụ đầy đủ. `SUSPENDED`: data plane trả ERR-20-001 (trừ API thiết yếu khi quyết định cho phép), giao diện tỉnh chỉ đọc, đăng nhập vẫn được để xem. `MERGING`: phục vụ bình thường, có dải cảnh báo. `MERGED`: lượt gọi chuyển tiếp sang tenant đích, giao diện chỉ đọc, ghi trả ERR-20-115. `DECOMMISSIONED`: trạng thái cuối, data plane trả ERR-20-102; bản ghi tenant giữ lại để giữ truy vết và chặn tái dùng mã (BR-20-001).

### 4.4. Mười bảy bước saga khởi tạo

Bảng dưới là nguồn chuẩn mã bước dùng chung cho FRS, SDD, CSDL, API và ca kiểm thử. Mỗi bước có bên thực hiện, cách gọi, chế độ (đồng bộ hoặc bất đồng bộ) và thao tác bù trừ; thứ tự bù trừ ngược thứ tự thực hiện.

| Mã bước | Việc | Bên thực hiện | Gọi | Chế độ | Bù trừ |
|---|---|---|---|---|---|
| `S01_RECORD` | Ghi bản ghi tenant `PROVISIONING`, cấu hình mặc định, hạn mức từ mẫu | PH-20 | nội bộ | Đồng bộ | Xóa bản ghi (chỉ khi chưa có bước nào khác xong) |
| `S02_CONFIG_REPO` | Tạo thư mục `tenants/{ma}/` trong `dh-tenant-config`, commit cấu hình | PH-20 | Git | Đồng bộ | Revert commit |
| `S03_REALM` | Realm `dh-{ma thường}`, client `dh-console`, `dh-portal`, vai trò chuẩn, quản trị tỉnh đầu tiên (đổi mật khẩu, MFA) | PH-12 | API-12-080 (`iam:realm-provision`) | Đồng bộ | Xóa realm còn `PROVISIONING` |
| `S04_SECRETS` | Đường dẫn `kv/dh/{ma}/...`, chính sách OpenBao, KEK `dh-{ma}-pii` (SEC-88) | PH-20 qua OpenBao | OpenBao API | Đồng bộ | Xóa đường dẫn, xóa KEK chưa dùng |
| `S05_BUCKETS` | Bucket `dh-{ma}-{mục đích}` (`files`, `exports`, `backup`, `audit`) | PH-20 qua Ceph RGW | S3 API | Đồng bộ | Xóa bucket rỗng |
| `S06_EVENTING` | Hạn mức, principal nội bộ, ACL tiền tố `{ma}.`, topic hệ thống, nhóm Apicurio | PH-10 | EVT-20-01 + báo tiến độ (FR-10-064, FR-10-067) | Bất đồng bộ | PH-10 gỡ khi nhận EVT-20-04 `DECOMMISSIONED` |
| `S07_DATABASE` | Chỉ `DEDICATED_DB`: cụm CloudNativePG, migration, bảng định tuyến | PH-20 | CNPG CR | Đồng bộ | Xóa cụm |
| `S08_OBSERVABILITY` | Chuỗi kiểm toán, tổ chức Grafana, nguồn dữ liệu, luật cảnh báo | PH-13 | API-13-072 (`obs:tenant-provision`) | Đồng bộ | Đóng chuỗi API-13-073 |
| `S09_GATEWAY` | Host, tiền tố, hạn mức hợp đồng ở APISIX | PH-03 | EVT-20-01, EVT-20-05 + đọc API-20-164 | Bất đồng bộ | PH-03 gỡ |
| `S10_INTEGRATION` | Không gian `DEFAULT`, kho `dh-flows-{ma}`, ApplicationSet runtime | PH-04 | EVT-20-01 + báo tiến độ | Bất đồng bộ | PH-04 gỡ |
| `S11_SEED_RDM` | Gói danh mục nền | PH-07 | API-07-073 | Đồng bộ | PH-07 xóa danh mục nền |
| `S12_SEED_MDM` | Gói dữ liệu chủ nền (nếu PH-06 bật theo mẫu) | PH-06 | EVT-20-01 + báo tiến độ | Bất đồng bộ | Không |
| `S13_ORG_SEED` | Tổ chức cấp tỉnh từ ĐVHC `COMMON` (UBND tỉnh, các sở theo mẫu) | PH-20 | nội bộ | Đồng bộ | Xóa |
| `S14_KPI` | Kế thừa bộ chỉ tiêu mẫu (nếu PH-16 bật) | PH-16 | FR-16-008 | Đồng bộ | Không |
| `S15_MODULES` | Phát EVT-20-07 cho từng phân hệ bật theo mẫu (PH-19, PH-17…), chờ báo xong | các PH | EVT-20-07 + báo tiến độ | Bất đồng bộ | EVT-20-08 |
| `S16_SMOKE` | Đăng nhập quản trị, gọi API mẫu, phát nhận sự kiện mẫu, một ca rò rỉ chéo | PH-20 | nội bộ | Đồng bộ | Không |
| `S17_ACTIVATE` | `ACTIVE`, thông báo đầu mối (PH-18), đẩy KPI-12 (API-16-030) | PH-20 | nội bộ | Đồng bộ | Không |

: Mười bảy bước saga khởi tạo và bên thực hiện

Bước bất đồng bộ chờ phân hệ báo qua API-20-166 (`POST /internal/tenant/v1/provisioning-runs/{runId}/steps/{stepCode}:report`, scope `tenant:provision-report`); hết `20.provision.step-timeout-minutes` thì bước `FAILED` với ERR-20-106. Bước không áp dụng (phân hệ chưa bật, `S07_DATABASE` ở chế độ `SHARED`) có trạng thái `SKIPPED`. Các bước `S06`, `S09`, `S10`, `S12` khởi động cùng lúc sau `S05` và cùng phải xong trước `S11`; còn lại chạy tuần tự.

### 4.5. Máy trạng thái lần chạy saga

```{.mermaid caption="Máy trạng thái lần chạy saga (ProvisioningRunStatus)"}
stateDiagram-v2
  [*] --> PENDING: Tạo lần chạy
  PENDING --> RUNNING: Bộ thực thi nhận
  RUNNING --> WAITING: Bước bất đồng bộ chờ báo
  WAITING --> RUNNING: Đủ báo cáo
  RUNNING --> FAILED: Bước lỗi hết lần thử
  WAITING --> FAILED: Quá hạn chờ báo
  FAILED --> RUNNING: Thử lại
  FAILED --> COMPENSATING: Bù trừ hoặc hủy
  COMPENSATING --> COMPENSATED: Bù xong
  COMPENSATING --> FAILED: Bù trừ lỗi
  COMPENSATED --> CANCELLED: Hủy khởi tạo
  RUNNING --> SUCCEEDED: S17 xong
  SUCCEEDED --> [*]
  CANCELLED --> [*]
```

`PENDING`: đã ghi, chờ bộ thực thi lấy (khóa ShedLock theo tenant). `RUNNING`: đang thực hiện một bước đồng bộ. `WAITING`: mọi bước có thể chạy đều đang chờ báo của phân hệ bất đồng bộ. `FAILED`: một bước `FAILED` sau `20.provision.step-retry-max` lần tự thử, hoặc tổng thời gian vượt `20.provision.timeout-minutes` (ERR-20-108); tenant chuyển `FAILED`. `COMPENSATING`: đang bù ngược các bước `SUCCEEDED`. `COMPENSATED`: mọi bước đã bù; lần chạy `INITIAL` thì tiếp theo `CANCELLED` và tenant `DECOMMISSIONED`; lần chạy `SUPPLEMENT` thì tenant vẫn `ACTIVE`. `SUCCEEDED`: mọi bước `SUCCEEDED` hoặc `SKIPPED`. Mỗi tenant có tối đa một lần chạy ở `PENDING`, `RUNNING`, `WAITING`, `COMPENSATING` (BR-20-006).

### 4.6. Máy trạng thái bước saga

```{.mermaid caption="Máy trạng thái bước saga (ProvisioningStepStatus)"}
stateDiagram-v2
  [*] --> PENDING
  PENDING --> RUNNING: Tới lượt
  PENDING --> SKIPPED: Không áp dụng
  RUNNING --> SUCCEEDED: Bên thực hiện trả thành công
  RUNNING --> WAITING_REPORT: Đã phát sự kiện, chờ báo
  WAITING_REPORT --> SUCCEEDED: Báo SUCCEEDED
  WAITING_REPORT --> FAILED: Báo FAILED hoặc quá hạn
  RUNNING --> FAILED: Lỗi hết lần thử
  FAILED --> RUNNING: Thử lại
  FAILED --> SKIPPED: Bỏ qua có lý do (bước không bắt buộc)
  SUCCEEDED --> COMPENSATING: Bù trừ
  FAILED --> COMPENSATING: Bù phần đã làm
  COMPENSATING --> COMPENSATED
```

`PENDING`: chưa tới lượt. `RUNNING`: đang gọi bên thực hiện với `Idempotency-Key = {runId}:{stepCode}`. `WAITING_REPORT`: bước bất đồng bộ đã phát sự kiện, chờ API-20-166. `SUCCEEDED`: có `outputRef`. `FAILED`: có `errorCode` (ERR-20-106, ERR-20-107 hoặc mã của bên thực hiện). `SKIPPED`: không áp dụng hoặc PA bỏ qua bước không bắt buộc (`S12_SEED_MDM`, `S14_KPI`) có lý do. `COMPENSATING`, `COMPENSATED`: đang bù, đã bù. Bước `S16_SMOKE`, `S17_ACTIVATE` không bỏ qua được.

### 4.7. Máy trạng thái đề nghị vòng đời

Máy trạng thái dùng chung cho đề nghị vòng đời (EN-20-22) và đề nghị đổi hạn mức (EN-20-14) theo `RequestStatus`.

```{.mermaid caption="Máy trạng thái đề nghị có duyệt (RequestStatus)"}
stateDiagram-v2
  [*] --> DRAFT: Lập đề nghị
  DRAFT --> PENDING_APPROVAL: Gửi duyệt
  DRAFT --> APPROVED: Loại không cần duyệt (SUSPEND, RESUME)
  PENDING_APPROVAL --> APPROVED: PA thứ hai duyệt
  PENDING_APPROVAL --> REJECTED: Từ chối
  PENDING_APPROVAL --> DRAFT: Người gửi rút
  DRAFT --> CANCELLED: Hủy
  APPROVED --> EXECUTING: Thực hiện (ngay hoặc theo lịch)
  APPROVED --> CANCELLED: Hủy trước khi thực hiện
  EXECUTING --> DONE: Xong
  EXECUTING --> APPROVED: Thực hiện lỗi, thử lại được
  REJECTED --> [*]
  DONE --> [*]
  CANCELLED --> [*]
```

`DRAFT`: người lập sửa được. `PENDING_APPROVAL`: khóa nội dung, chờ người có `PERM-20-approve` khác người lập và người gửi. `APPROVED`: đủ điều kiện thực hiện; với `TERMINATE` thì chưa thực hiện được cho tới khi gói bàn giao `DELIVERED` và hết thời gian nguội (BR-20-019). `EXECUTING`, `DONE`: đang và đã thực thi. `REJECTED`, `CANCELLED`: kết thúc, giữ lịch sử. `SUSPEND`, `RESUME` đi thẳng từ `DRAFT` tới `APPROVED` khi người lập bấm "Thực hiện" vì cần phản ứng nhanh với sự cố (BR-20-021).

### 4.8. Máy trạng thái phân hệ theo tenant

```{.mermaid caption="Máy trạng thái phân hệ theo tenant (ModuleState)"}
stateDiagram-v2
  [*] --> DISABLED
  DISABLED --> ENABLING: Bật (EVT-20-07)
  ENABLING --> ENABLED: Phân hệ báo xong
  ENABLING --> FAILED: Báo lỗi hoặc quá hạn
  FAILED --> ENABLING: Thử lại
  ENABLED --> SUSPENDED: Tạm ngừng
  SUSPENDED --> ENABLED: Tiếp tục
  ENABLED --> DISABLING: Tắt (EVT-20-08)
  SUSPENDED --> DISABLING: Tắt
  DISABLING --> DISABLED: Phân hệ báo xong
```

`DISABLED`: chưa bật hoặc đã tắt; dữ liệu cũ (nếu có) được giữ theo thời hạn lưu của phân hệ (BR-20-018). `ENABLING`: đã phát EVT-20-07, chờ báo qua API-20-166. `ENABLED`: menu hiện, data plane phục vụ. `SUSPENDED`: menu hiện ở chế độ chỉ đọc, data plane trả ERR-20-103. `DISABLING`: đã phát EVT-20-08, phân hệ dừng tác vụ nền của tenant. `FAILED`: khởi tạo phân hệ lỗi; PA thử lại hoặc tắt. Phân hệ lõi luôn `ENABLED` với tenant tỉnh `ACTIVE`.

### 4.9. Máy trạng thái sáp nhập

```{.mermaid caption="Máy trạng thái kế hoạch sáp nhập (MergeStatus)"}
stateDiagram-v2
  [*] --> DRAFT: Lập kế hoạch
  DRAFT --> DRY_RUN: Chạy thử
  DRY_RUN --> DRAFT: Chạy thử xong, sửa ánh xạ
  DRAFT --> PENDING_APPROVAL: Gửi duyệt (có chạy thử đạt)
  PENDING_APPROVAL --> APPROVED: PA thứ hai duyệt
  PENDING_APPROVAL --> DRAFT: Từ chối hoặc rút
  APPROVED --> TRANSFERRING: Bắt đầu chuyển (nguồn MERGING)
  TRANSFERRING --> CONFLICT_REVIEW: Có xung đột
  CONFLICT_REVIEW --> TRANSFERRING: Đã quyết hết
  TRANSFERRING --> IDENTITY_TRANSFER: Mọi phân hệ xong
  IDENTITY_TRANSFER --> CUTOVER: Định danh xong
  CUTOVER --> TRANSITION: Nguồn MERGED, chuyển tiếp bật
  TRANSITION --> COMPLETED: Hết chuyển tiếp, kết thúc
  TRANSFERRING --> FAILED: Lỗi không thử lại được
  FAILED --> TRANSFERRING: Thử lại phân hệ lỗi
  DRAFT --> CANCELLED
  APPROVED --> CANCELLED
  FAILED --> CANCELLED: Hủy, nguồn về ACTIVE
  COMPLETED --> [*]
  CANCELLED --> [*]
```

`DRAFT`: lập, sửa ánh xạ, chạy thử nhiều lần. `DRY_RUN`: đang chạy thử trên bản sao không ghi. `PENDING_APPROVAL`, `APPROVED`: bốn mắt (BR-20-008). `TRANSFERRING`: PH-18 và phân hệ tham gia chuyển dữ liệu; tenant nguồn `MERGING`, vẫn phục vụ. `CONFLICT_REVIEW`: còn xung đột chưa quyết, phân hệ có xung đột tạm dừng phần dính xung đột. `IDENTITY_TRANSFER`: PH-12 tạo lại người dùng ở realm đích (API-12-046). `CUTOVER`: chuyển `MERGED` (≤ 5 phút, giả định). `TRANSITION`: APISIX chuyển tiếp lượt gọi kèm header `Deprecation` tới `transitionEndsAt`. `COMPLETED`: nguồn `DECOMMISSIONED`, thông tin xác thực cũ thu hồi. `FAILED`: một phân hệ lỗi không tự hồi phục; `CANCELLED` chỉ được trước `CUTOVER` (BR-20-024).

### 4.10. Máy trạng thái tổ chức

```{.mermaid caption="Máy trạng thái tổ chức (OrgStatus)"}
stateDiagram-v2
  [*] --> ACTIVE: Tạo, nhập
  ACTIVE --> INACTIVE: Ngừng tạm (không còn giao dịch mới)
  INACTIVE --> ACTIVE: Hoạt động lại
  ACTIVE --> DISSOLVED: Giải thể có kế thừa
  INACTIVE --> DISSOLVED: Giải thể có kế thừa
  ACTIVE --> MERGED: Sáp nhập vào tổ chức khác
  DISSOLVED --> [*]
  MERGED --> [*]
```

`ACTIVE`: chọn được làm chủ quản HTTT, nơi công tác, chủ quản dữ liệu. `INACTIVE`: không chọn được cho đối tượng mới, đối tượng cũ giữ nguyên, PH-01 trả ERR-01-004 khi kết nạp mới. `DISSOLVED`: có `effective_to` và `successor_id` (bắt buộc khi còn tham chiếu); `MERGED`: tổ chức nhập vào tổ chức khác, `successor_id` là tổ chức nhận. Hai trạng thái cuối không quay lại; tổ chức không bị xóa cứng (BR-20-027).

### 4.11. Máy trạng thái phiên bản phát hành

```{.mermaid caption="Máy trạng thái phiên bản sản phẩm (ReleaseStatus)"}
stateDiagram-v2
  [*] --> DRAFT: Đăng ký từ CI
  DRAFT --> PREVIEW: Đưa lên kênh xem trước
  PREVIEW --> STABLE: Đủ 14 ngày thí điểm, không sự cố mức 1
  STABLE --> DEPRECATED: Ra hai bản phụ mới hơn
  PREVIEW --> WITHDRAWN: Rút do lỗi
  STABLE --> WITHDRAWN: Rút do lỗi nghiêm trọng
  DEPRECATED --> [*]
  WITHDRAWN --> [*]
```

`DRAFT`: CI đã đẩy danh sách thành phần có digest; chưa tenant nào dùng. `PREVIEW`: tenant đăng ký `PREVIEW` (môi trường `STAGING`) và tenant thí điểm nhận được. `STABLE`: mọi tenant kênh `STABLE` nhận qua kế hoạch sóng. `DEPRECATED`: ngoài hai bản phụ gần nhất (BR-20-034), không lập kế hoạch nâng cấp mới tới bản này. `WITHDRAWN`: không ai nâng cấp tới được; tenant đang chạy được đề xuất kế hoạch quay lui hoặc vá.

### 4.12. Máy trạng thái nâng cấp theo tenant

```{.mermaid caption="Máy trạng thái nâng cấp theo tenant (TenantUpgradeStatus)"}
stateDiagram-v2
  [*] --> PENDING: Xếp vào sóng
  PENDING --> IN_WINDOW: Tới cửa sổ bảo trì
  PENDING --> SKIPPED: Bỏ khỏi sóng (tenant tạm ngừng, ghim phiên bản)
  IN_WINDOW --> UPGRADING: Commit thẻ phiên bản
  UPGRADING --> VERIFYING: Argo CD đồng bộ xong
  VERIFYING --> DONE: Kiểm tra sau nâng cấp đạt
  VERIFYING --> FAILED: Kiểm tra không đạt
  UPGRADING --> FAILED: Đồng bộ lỗi
  FAILED --> UPGRADING: Thử lại
  FAILED --> ROLLED_BACK: Quay lui
  DONE --> ROLLED_BACK: Quay lui cả sóng
  DONE --> [*]
  ROLLED_BACK --> [*]
  SKIPPED --> [*]
```

`PENDING`: đã xếp sóng, chờ sóng bắt đầu và cửa sổ của tenant. `IN_WINDOW`: đang trong cửa sổ bảo trì, đã báo trước theo FR-20-063. `UPGRADING`: PH-20 đã commit thẻ phiên bản vào overlay của tenant, Argo CD đang áp. `VERIFYING`: chạy kiểm tra khói rút gọn và theo dõi tỷ lệ lỗi trong `20.release.verify-minutes`. Tỷ lệ `FAILED` của sóng vượt `20.release.wave-error-threshold-percent` thì kế hoạch tự `PAUSED` (BR-20-032).

## 5. Danh sách chức năng

Bảng dưới là khung chức năng cố định của PH-20; mã FR không đổi giữa các tập. Mức: M bắt buộc cho nghiệm thu, S nên có, C có thì tốt. Đợt MVP trừ khi ghi khác.

| Mã | Nhóm | Chức năng | Mức, đợt | Màn hình |
|---|---|---|---|---|
| FR-20-001 | A Hồ sơ tenant | Khai báo tenant mới | M | UI-20-02 |
| FR-20-002 | A | Liệt kê, tìm, lọc tenant toàn nền tảng | M | UI-20-01 |
| FR-20-003 | A | Xem chi tiết tenant | M | UI-20-03 |
| FR-20-004 | A | Sửa hồ sơ hành chính của tenant | M | UI-20-03 |
| FR-20-005 | A | Quản lý đầu mối và hợp đồng dịch vụ của tenant | S | UI-20-03 |
| FR-20-006 | A | Bảo vệ tenant đặc biệt PLATFORM và COMMON | M | — |
| FR-20-007 | A | Kiểm tra sẵn sàng trước khởi tạo | M | UI-20-02 |
| FR-20-008 | B Saga khởi tạo | Chạy saga khởi tạo tenant | M | UI-20-04 |
| FR-20-009 | B | Theo dõi tiến độ saga thời gian thực | M | UI-20-04 |
| FR-20-010 | B | Thử lại saga từ bước lỗi | M | UI-20-04 |
| FR-20-011 | B | Bù trừ và hủy khởi tạo | M | UI-20-04 |
| FR-20-012 | B | Kiểm tra khói sau khởi tạo | M | UI-20-04 |
| FR-20-013 | B | Kích hoạt tenant và bàn giao cho quản trị tỉnh | M | UI-20-04 |
| FR-20-014 | B | Đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16 | S | — |
| FR-20-015 | B | Quản lý mẫu khởi tạo có phiên bản | S | UI-20-21 |
| FR-20-016 | B | Khởi tạo bổ sung cho tenant đang hoạt động | S | UI-20-04 |
| FR-20-017 | B | Khởi tạo tenant chế độ DEDICATED_CLUSTER | S, Đợt 2 | UI-20-02 |
| FR-20-018 | C Cấu hình | Cài đặt tỉnh do quản trị tỉnh tự quản | M | UI-20-12 |
| FR-20-019 | C | Cấu hình nền tảng của tenant | M | UI-20-03 |
| FR-20-020 | C | Ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống | M | — |
| FR-20-021 | C | Lịch sử, so sánh, khôi phục phiên bản cấu hình | S | UI-20-17 |
| FR-20-022 | C | Phát hiện lệch cấu hình và đối chiếu định kỳ | S | UI-20-17 |
| FR-20-023 | C | Chính sách tiếp nhận truy cập liên tenant của tỉnh | M | UI-20-22 |
| FR-20-024 | C | Xem nhật ký truy cập liên tenant vào tỉnh | S | UI-20-22 |
| FR-20-025 | C | Chuyển chế độ cách ly của tenant | S, Đợt 2 | UI-20-03 |
| FR-20-026 | D Hạn mức, sử dụng | Đặt hạn mức hợp đồng của tenant | M | UI-20-05 |
| FR-20-027 | D | Đổi hạn mức có duyệt và đẩy xuống nơi thực thi | M | UI-20-05 |
| FR-20-028 | D | Thu thập sử dụng tài nguyên theo tenant | M | — |
| FR-20-029 | D | Cảnh báo ngưỡng hạn mức 80% và 100% | M | UI-20-06 |
| FR-20-030 | D | Xem sử dụng tài nguyên của tỉnh và toàn nền tảng | M | UI-20-06, UI-20-13 |
| FR-20-031 | D | Báo cáo sử dụng tài nguyên theo kỳ, xuất tệp | S | UI-20-06 |
| FR-20-032 | D | Ghi đè hạn mức tạm thời có thời hạn | S | UI-20-05 |
| FR-20-033 | E Phân hệ, tính năng | Danh mục phân hệ của nền tảng và ma trận phụ thuộc | M | UI-20-07 |
| FR-20-034 | E | Bật phân hệ cho tenant | M | UI-20-07 |
| FR-20-035 | E | Tắt, tạm ngừng phân hệ cho tenant | M | UI-20-07 |
| FR-20-036 | E | Cờ tính năng theo tenant | S | UI-20-07 |
| FR-20-037 | E | Cung cấp trạng thái phân hệ cho menu và giao diện | M | — |
| FR-20-038 | F Vòng đời | Tạm ngừng tenant | M | UI-20-08 |
| FR-20-039 | F | Khôi phục tenant | M | UI-20-08 |
| FR-20-040 | F | Đề nghị và duyệt chấm dứt tenant | M | UI-20-08 |
| FR-20-041 | F | Xuất gói bàn giao dữ liệu tenant | M | UI-20-08 |
| FR-20-042 | F | Thực hiện chấm dứt tenant | M | UI-20-08 |
| FR-20-043 | F | Lịch sử vòng đời và quyết định | M | UI-20-03 |
| FR-20-044 | F | Thông báo thay đổi trạng thái tenant | M | — |
| FR-20-045 | G Sáp nhập | Lập kế hoạch sáp nhập | M | UI-20-09 |
| FR-20-046 | G | Lập bảng ánh xạ sáp nhập | M | UI-20-09 |
| FR-20-047 | G | Chạy thử sáp nhập | M | UI-20-10 |
| FR-20-048 | G | Điều phối chuyển dữ liệu theo phân hệ | M | UI-20-10 |
| FR-20-049 | G | Xử lý xung đột sáp nhập | M | UI-20-10 |
| FR-20-050 | G | Chuyển định danh và cấp song song thông tin xác thực HTTT | M | UI-20-10 |
| FR-20-051 | G | Chuyển tiếp lượt gọi và chuyển tenant nguồn sang MERGED | M | UI-20-10 |
| FR-20-052 | G | Kết thúc sáp nhập sau thời gian chuyển tiếp | M | UI-20-10 |
| FR-20-053 | H Tổ chức | Quản lý danh mục tổ chức | M | UI-20-14, UI-20-15 |
| FR-20-054 | H | Hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa | M | UI-20-15 |
| FR-20-055 | H | Nhập tổ chức từ Excel, CSV có xem trước và xuất | M | UI-20-16 |
| FR-20-056 | H | Đồng bộ tổ chức khi sắp xếp đơn vị hành chính | S | UI-20-14 |
| FR-20-057 | H | API đọc tổ chức cho phân hệ khác | M | — |
| FR-20-058 | H | Đánh dấu và tra cứu tổ chức chủ quản dữ liệu | S | UI-20-15 |
| FR-20-059 | I Phát hành | Danh mục phiên bản sản phẩm | M | UI-20-18 |
| FR-20-060 | I | Kênh phát hành và đăng ký kênh của tenant | M | UI-20-18 |
| FR-20-061 | I | Lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì | M | UI-20-19 |
| FR-20-062 | I | Theo dõi nâng cấp, dừng sóng, quay lui | S | UI-20-19 |
| FR-20-063 | I | Thông báo phát hành và lịch bảo trì tới tỉnh | S | UI-20-12 |
| FR-20-064 | I | Xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh | S | UI-20-12 |
| FR-20-065 | J Dịch vụ, quản trị | Registry tenant cho phân hệ khác | M | — |
| FR-20-066 | J | Thực thi trạng thái tenant ở data plane và control plane | M | — |
| FR-20-067 | J | Bảng điều khiển nền tảng đa tenant | S | UI-20-20 |
| FR-20-068 | J | Nhật ký kiểm toán thao tác PH-20 | M | UI-20-03 |
| FR-20-069 | J | Tham số 20.* của phân hệ | M | — |
| FR-20-070 | J | Điều phối kiểm thử rò rỉ chéo tenant định kỳ | S | UI-20-20 |

: Danh sách chức năng của PH-20

## 6. Đặc tả chi tiết chức năng

### 6.1. Cách đọc bảng đặc tả

Mỗi chức năng được đặc tả bằng một khối 17 mục cố định theo K-TRINH-BAY §4, kết hợp 12 trường kỹ thuật của D00-01 §4.3: mục đích; tác nhân, quyền; mức ưu tiên, đợt; truy vết; tiền điều kiện; kích hoạt; đầu vào (bảng riêng khi từ 5 trường); luồng xử lý chính; luồng thay thế; luồng ngoại lệ (mã lỗi, HTTP, câu thông báo); đầu ra; kết quả; hậu điều kiện; sự kiện phát ra; kiểm toán; quy tắc nghiệp vụ; màn hình, API. Mục không áp dụng ghi "Không".

Quy ước chung áp cho mọi FR, không nhắc lại trong từng khối: (1) lệnh tạo hoặc chạy bất đồng bộ nhận tiêu đề `Idempotency-Key` (dùng lại với thân khác: ERR-20-009, 409); (2) lệnh sửa và hành động trên tài nguyên có phiên bản cần `If-Match` bằng `ETag` hiện hành (thiếu: ERR-00-428; không khớp: ERR-20-005, 412); (3) mọi thao tác ghi của vai trò nền tảng tác động một tenant tỉnh cần `reason` ≥ 20 ký tự và `ticketRef` (thiếu: ERR-20-008, 422), được ghi kiểm toán vào chuỗi của tenant bị tác động (SEC-85); (4) tài nguyên không có hoặc thuộc tenant khác ở `/api/tenant/v1` và `/internal/tenant/v1` trả ERR-20-002 (404), không trả `403`, để không lộ sự tồn tại (D03-10 §6); riêng token không thuộc tenant `PLATFORM` gọi `/api/platform/v1` trả `403` ERR-00-403, vì đường dẫn nền tảng không phải tài nguyên của một tỉnh nên không có gì để che; (5) thiếu quyền chức năng trả ERR-00-403; (6) ví dụ dùng tenant `T68` (realm `dh-t68`, topic `t68.`), `T01` cho số liệu giả định GĐ-01…07, `T90…T99` cho kiểm thử, lần chạy `run-01JH…`, kế hoạch sáp nhập `MG-2026-001`, phiên bản sản phẩm `1.4.0`. Mã API trong mục "Màn hình, API" tra ở mục 9.4.

### 6.2. Nhóm A · Hồ sơ tenant

Nhóm A quản lý bản ghi DD-01 của tenant và mọi thông tin hành chính đi kèm. Khai báo chỉ ghi hồ sơ và chạy kiểm tra sẵn sàng; tài nguyên thật chỉ được tạo khi PA chạy saga (nhóm B). Mã tenant, realm và loại tenant không đổi được sau khai báo; hai tenant đặc biệt `PLATFORM`, `COMMON` được bảo vệ khỏi mọi thao tác vòng đời.

#### FR-20-001 · Khai báo tenant mới

::: dac-ta
**Mục đích.** Cho quản trị nền tảng ghi nhận một tỉnh mới sử dụng Datahub bằng một hồ sơ đầy đủ (mã, tên, đơn vị hành chính, chế độ cách ly, quy mô, hồ sơ triển khai, mẫu khởi tạo, đầu mối), làm đầu vào duy nhất cho saga khởi tạo, thay cho sổ tay cài đặt làm tay của hệ cũ.

**Tác nhân, quyền.** PA (`PERM-20-provision`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; BO-06; KPI-12; BP-08; NFR-00-060; D02-07 DD-01; Q20-04.

**Tiền điều kiện.** Người dùng ở tenant `PLATFORM`, đã xác thực WebAuthn; danh mục ĐVHC `COMMON` của PH-07 sẵn sàng; có ít nhất một mẫu khởi tạo `PUBLISHED` (FR-20-015).

**Kích hoạt.** Bấm "+ Khai báo tenant" ở UI-20-01, đi qua năm bước wizard UI-20-02 rồi bấm "Lưu khai báo" hoặc "Lưu và khởi tạo".

**Đầu vào.** Theo bảng dữ liệu vào của FR-20-001 dưới đây; `Idempotency-Key` bắt buộc.

**Luồng xử lý chính.**

1. PA nhập mã, tên, chọn ĐVHC cấp tỉnh ở bước "Hồ sơ"; hệ thống gợi ý mã `T` + mã ĐVHC hai chữ số (Q20-04) và tên "Tỉnh …" theo danh mục.
2. Hệ thống kiểm mã theo mẫu `^T\d{2}$`, không thuộc dải `T90…T99` trừ khi `kind = PROVINCE` và cờ `testTenant = true`, chưa từng dùng kể cả tenant `DECOMMISSIONED`, `MERGED` (sai mẫu: ERR-20-004; trùng: ERR-20-003).
3. Hệ thống kiểm ĐVHC là cấp tỉnh, còn hiệu lực ở `COMMON` (sai: ERR-20-012) và chưa có tenant khác `DECOMMISSIONED`, `MERGED` gắn với nó (trùng: ERR-20-011).
4. PA chọn chế độ cách ly, hồ sơ quy mô, hồ sơ triển khai ở bước "Cách ly và quy mô"; hệ thống chặn `DEDICATED_CLUSTER` khi chưa bật Đợt 2 (FR-20-017) hoặc chưa chọn cụm đích (ERR-20-064).
5. PA chọn mẫu khởi tạo và phiên bản, xem danh sách phân hệ bật sẵn và hạn mức mặc định theo hồ sơ quy mô ở bước "Mẫu và phân hệ"; được bỏ chọn phân hệ không lõi (mẫu không `PUBLISHED`: ERR-20-015).
6. PA nhập tối thiểu đầu mối `TENANT_ADMIN` và `TECHNICAL` ở bước "Đầu mối" (thiếu: ERR-20-021); thư công vụ đầu mối `TENANT_ADMIN` dùng để tạo quản trị tỉnh đầu tiên ở `S03_REALM`.
7. Ở bước "Rà soát", hệ thống chạy kiểm tra sẵn sàng (FR-20-007) và hiện kết quả từng mục; mục `BLOCKER` chưa đạt thì nút lưu bị khóa (ERR-20-017).
8. PA bấm "Lưu khai báo"; hệ thống tạo bản ghi tenant `status = PROVISIONING`, `realm = dh-{mã thường}`, `declared_at = now`, chưa tạo lần chạy saga; ghi lịch sử trạng thái và kiểm toán.

**Luồng thay thế.** (a) "Lưu và khởi tạo": sau bước 8 hệ thống gọi FR-20-008 với cùng `Idempotency-Key` có hậu tố `:run`, chuyển sang UI-20-04. (b) Tenant kiểm thử `T90…T99`: bỏ qua kiểm ĐVHC (gán ĐVHC giả `TEST`), mẫu `test-minimal`, không tính vào sức chứa NFR-00-060.

**Luồng ngoại lệ.**

- Mã sai mẫu hoặc trường sai miền: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."
- Mã đã dùng: ERR-20-003 (409); "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- ĐVHC đã có tenant: ERR-20-011 (409).
- ĐVHC không phải cấp tỉnh hoặc hết hiệu lực: ERR-20-012 (422).
- Mẫu không dùng được: ERR-20-015 (422).
- Thiếu đầu mối: ERR-20-021 (422).
- Kiểm tra sẵn sàng có mục chặn: ERR-20-017 (422).
- PH-07 không trả lời khi tra ĐVHC: ERR-20-062 (503).

**Đầu ra.** `201`; `tenantCode`, `status = PROVISIONING`, `realm`, `readiness` (kết quả FR-20-007), `ETag`; tiêu đề `Location: /api/platform/v1/tenants/T68`.

**Kết quả.** Tỉnh mới xuất hiện ở danh sách tenant với nhãn "Đang khởi tạo – chưa chạy", PA bấm "Khởi tạo" để bắt đầu saga.

**Hậu điều kiện.** Có bản ghi DD-01, đầu mối EN-20-03, hạn mức dự kiến EN-20-13 theo mẫu và hồ sơ quy mô; chưa có tài nguyên ở hệ khác; không phát sự kiện (EVT-20-01 chỉ phát ở bước `S05` của saga).

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người khai báo, hồ sơ, kết quả kiểm tra sẵn sàng; ghi vào chuỗi `PLATFORM`, chép sang chuỗi tenant khi `S08_OBSERVABILITY` xong.

**Quy tắc nghiệp vụ.** BR-20-001, BR-20-002, BR-20-003, BR-20-042.

**Màn hình, API.** UI-20-02 bước 1–5; API-20-002, API-20-005.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `tenantCode` | T-TENANT | Có | `^T\d{2}$`; chưa từng dùng | `T68` |
| `name` | T-NAME | Có | 1…255 ký tự | `Tỉnh Lâm Viên (giả định)` |
| `adminUnitId` | T-ID | Có (trừ tenant kiểm thử) | ĐVHC cấp tỉnh còn hiệu lực ở `COMMON` | `01JH4Z…` |
| `isolationMode` | T-ENUM | Có | `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` | `SHARED` |
| `scaleProfile` | T-ENUM | Có | `QM-NHO`, `QM-VUA`, `QM-LON`, `QM-CHUNG` | `QM-VUA` |
| `deploymentProfile` | T-ENUM | Có | `HT-A`, `HT-B` | `HT-B` |
| `clusterCode` | T-CODE | Khi `DEDICATED_CLUSTER` | Cụm đã `VERIFIED` (FR-20-017) | `cl-t68-onprem` |
| `templateCode`, `templateVersion` | T-CODE, số | Có | Phiên bản `PUBLISHED` | `tinh-chuan`, `3` |
| `modulesExcluded` | T-CODE[] | Không | Chỉ phân hệ không lõi có trong mẫu | `["PH-17"]` |
| `contacts[]` | đối tượng | Có | ≥ 1 `TENANT_ADMIN`, ≥ 1 `TECHNICAL`; thư công vụ hợp lệ | xem FR-20-005 |
| `contractRef` | T-CODE | Không | Số hợp đồng nếu đã ký | `HĐ-15/2026/DH` |
| `testTenant` | T-BOOL | Không | Chỉ với mã `T90…T99` | `false` |
| `note` | T-TEXT | Không | ≤ 2.000 ký tự | `Tỉnh thí điểm đợt 2` |

: Dữ liệu vào của FR-20-001

#### FR-20-002 · Liệt kê, tìm, lọc tenant toàn nền tảng

::: dac-ta
**Mục đích.** Cho vai trò nền tảng thấy mọi tenant trên một màn, biết tỉnh nào đang khởi tạo, lỗi, tạm ngừng, đang sáp nhập, chạy phiên bản nào, dùng bao nhiêu hạn mức, để ưu tiên việc cần làm.

**Tác nhân, quyền.** PA, PO, PAU (`PERM-20-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; FR-00-012 (đọc toàn nền tảng chỉ dữ liệu tổng hợp); NFR-00-003.

**Tiền điều kiện.** Người dùng ở tenant `PLATFORM`.

**Kích hoạt.** Mở UI-20-01 hoặc đổi bộ lọc, sắp xếp, trang.

**Đầu vào.** `q` (tìm không dấu trên mã, tên, 1…100 ký tự), `status[]`, `isolationMode[]`, `scaleProfile[]`, `deploymentProfile[]`, `channel`, `currentVersion`, `quotaAlert` (`WARN_80`, `LIMIT_100`), `kind` (mặc định `PROVINCE`), `testTenant` (mặc định `false`), `page`, `size` (≤ 200), `sort` (`code`, `name`, `status`, `activatedAt`), `format` (`json` mặc định, `csv`).

**Luồng xử lý chính.**

1. Hệ thống kiểm tham số thuộc miền ở Phụ lục A (sai: ERR-20-004).
2. Hệ thống truy vấn bảng `tenant` bằng vai trò `ph20_platform_app` với `app.tenant_id = 'PLATFORM'`, ghép trạng thái lần chạy saga gần nhất, phiên bản đang chạy (EN-20-32), cảnh báo hạn mức mở (EN-20-17).
3. Hệ thống trả danh sách kèm khối `facets` đếm theo trạng thái, chế độ cách ly, kênh.

**Luồng thay thế.** `format = csv`: tệp CSV UTF-8 tối đa 1.000 dòng, không có dữ liệu cá nhân. `kind = PLATFORM,COMMON`: hiện hai tenant đặc biệt với nhãn "Bảo vệ".

**Luồng ngoại lệ.**

- Tham số sai miền: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."
- `size` > 200: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."

**Đầu ra.** `200`; `items[]` (`tenantCode`, `name`, `kind`, `status`, `isolationMode`, `scaleProfile`, `deploymentProfile`, `currentVersion`, `channel`, `lastRun` {`runId`, `status`, `failedStep`}, `openAlerts`, `activatedAt`), `page`, `size`, `totalElements`, `facets`.

**Kết quả.** Người dùng lọc nhanh tenant `FAILED` hoặc chạm hạn mức.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không với tra cứu; có với xuất `csv` (người xuất, bộ lọc, số dòng).

**Quy tắc nghiệp vụ.** BR-20-003.

**Màn hình, API.** UI-20-01; API-20-001.
:::

#### FR-20-003 · Xem chi tiết tenant

::: dac-ta
**Mục đích.** Cho vai trò nền tảng xem toàn bộ thông tin một tenant trên một trang có bảy tab (Tổng quan, Cấu hình nền tảng, Hợp đồng và đầu mối, Phân hệ, Hạn mức, Lịch sử vòng đời, Kiểm toán) làm điểm xuất phát cho mọi thao tác.

**Tác nhân, quyền.** PA, PO, PAU (`PERM-20-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D02-07 DD-01.

**Tiền điều kiện.** Tenant tồn tại.

**Kích hoạt.** Bấm một dòng ở UI-20-01 hoặc mở trực tiếp `/nen-tang/tenant/T68`.

**Đầu vào.** `tenantCode`; `include[]` (`summary`, `config`, `contacts`, `modules`, `quotas`, `lastRun`) để giảm tải.

**Luồng xử lý chính.**

1. Hệ thống tìm tenant theo mã (không có: ERR-20-002).
2. Hệ thống dựng khối Tổng quan: trạng thái, chế độ cách ly, hồ sơ, realm, mẫu và phiên bản mẫu đã dùng, ngày khai báo, kích hoạt, lần chạy gần nhất, phiên bản sản phẩm đang chạy, số HTTT, người dùng, API.
3. Hệ thống trả các khối theo `include[]`; tab Lịch sử vòng đời và Kiểm toán tải riêng qua FR-20-043, FR-20-068.
4. Hệ thống tính danh sách hành động được phép theo trạng thái và quyền người xem (`allowedActions[]`), giao diện chỉ hiện nút tương ứng.

**Luồng thay thế.** Tenant `PLATFORM`, `COMMON`: chỉ hiện tab Tổng quan và Kiểm toán, `allowedActions = []` (FR-20-006). Tenant `MERGED`: dải thông tin "Đã sáp nhập vào {đích} từ {ngày}, chuyển tiếp tới {ngày}" có liên kết UI-20-10.

**Luồng ngoại lệ.**

- Không có tenant: ERR-20-002 (404); "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- `include` sai: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."

**Đầu ra.** `200`; các khối đã nêu, `allowedActions[]`, `ETag` của bản ghi tenant.

**Kết quả.** Người dùng biết tình trạng tenant và thao tác làm được.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-003, BR-20-026.

**Màn hình, API.** UI-20-03 tab Tổng quan; API-20-003.
:::

#### FR-20-004 · Sửa hồ sơ hành chính của tenant

::: dac-ta
**Mục đích.** Cho quản trị nền tảng sửa thông tin hành chính khi tỉnh đổi tên, đổi ghi chú, đổi hồ sơ quy mô mà không động tới mã, realm, loại tenant là những khóa mà mọi phân hệ dùng.

**Tác nhân, quyền.** PA (`PERM-20-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D02-07 DD-01; SEC-85.

**Tiền điều kiện.** Tenant ở `PROVISIONING`, `FAILED`, `ACTIVE` hoặc `SUSPENDED`; không phải tenant đặc biệt.

**Kích hoạt.** Bấm "Sửa hồ sơ" ở UI-20-03 tab Tổng quan.

**Đầu vào.** `name`, `scaleProfile`, `note`, `adminUnitId` (chỉ khi `PROVISIONING` chưa chạy saga); `reason`, `ticketRef`; `If-Match`.

**Luồng xử lý chính.**

1. PA sửa trường cho phép rồi bấm "Lưu"; giao diện mở `CMP-ReasonDialog` nhập lý do và mã phiếu.
2. Hệ thống từ chối trường bất biến `tenantCode`, `realm`, `kind` (ERR-20-068) và tenant đặc biệt (ERR-20-010).
3. Hệ thống kiểm phiên bản (`If-Match`), lý do, phiếu và miền giá trị (ERR-20-005, ERR-20-008, ERR-20-004).
4. Khi đổi `scaleProfile`, hệ thống tính hạn mức gợi ý mới nhưng không tự đổi hạn mức hợp đồng; giao diện gợi ý mở FR-20-027.
5. Hệ thống lưu, tạo phiên bản cấu hình mới qua FR-20-020 (tệp `tenant.yaml`), ghi kiểm toán vào chuỗi của tenant.

**Luồng thay thế.** Đổi `name` khi tỉnh đổi tên theo quyết định hành chính: trường `decisionDocNo` bắt buộc; tên cũ lưu vào lịch sử để báo cáo cũ vẫn hiển thị đúng tên tại thời điểm phát sinh.

**Luồng ngoại lệ.**

- Sửa thuộc tính bất biến: ERR-20-068 (422); "Không đổi được {thuộc tính} của tenant sau khi khai báo."
- Tenant đặc biệt: ERR-20-010 (403); "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."
- Tenant `MERGED`, `DECOMMISSIONED`: ERR-20-006 (409).

**Đầu ra.** `200`; bản ghi tenant mới, `ETag` mới, `configVersionNo`.

**Kết quả.** Tên mới hiện ở mọi màn của nền tảng sau tối đa 60 giây (đệm registry).

**Hậu điều kiện.** DD-01 cập nhật, `version` tăng; có phiên bản cấu hình mới.

**Sự kiện phát ra.** EVT-20-09 (`changeKind = TENANT_PROFILE`).

**Kiểm toán.** Có: giá trị trước, sau, lý do, mã phiếu, số quyết định.

**Quy tắc nghiệp vụ.** BR-20-001, BR-20-003, BR-20-009, BR-20-010.

**Màn hình, API.** UI-20-03; API-20-004.
:::

#### FR-20-005 · Quản lý đầu mối và hợp đồng dịch vụ của tenant

::: dac-ta
**Mục đích.** Giữ danh sách người liên hệ của tỉnh (để gửi thông báo khởi tạo, sự cố, bảo trì, tạm ngừng) và hợp đồng dịch vụ có hiệu lực (căn cứ hạn mức, kênh hỗ trợ, thời hạn).

**Tác nhân, quyền.** PA (`PERM-20-admin`); PO, PAU xem (`PERM-20-read`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; CMP-LAW-05 (dữ liệu cá nhân đầu mối tối thiểu).

**Tiền điều kiện.** Tenant không ở `DECOMMISSIONED`.

**Kích hoạt.** Tab "Hợp đồng và đầu mối" ở UI-20-03: "+ Đầu mối", "Sửa", "Ngừng"; "+ Hợp đồng", "Gia hạn".

**Đầu vào.** Đầu mối: `role`, `fullName`, `position`, `officialEmail`, `phone`, `orgCode`, `active`. Hợp đồng: `contractNo`, `signedDate`, `validFrom`, `validTo`, `parties`, `fileId`, `committedQuota` (tùy chọn); `reason`, `ticketRef`; `If-Match` khi sửa.

**Luồng xử lý chính.**

1. PA nhập thông tin; hệ thống kiểm thư công vụ đúng định dạng, điện thoại theo mẫu Việt Nam, `role` thuộc miền (ERR-20-004).
2. Khi ngừng đầu mối, hệ thống kiểm sau thao tác vẫn còn ít nhất một đầu mối `TENANT_ADMIN` và một `TECHNICAL` đang hoạt động (ERR-20-021).
3. Khi thêm hợp đồng, hệ thống kiểm `validTo` > `validFrom` và không chồng thời hạn với hợp đồng hiệu lực khác (ERR-20-022).
4. Hệ thống lưu, ghi kiểm toán; với hợp đồng mới có `committedQuota`, giao diện gợi ý FR-20-027 để đổi hạn mức theo hợp đồng.
5. Hằng ngày, bộ lập lịch phát nhắc qua PH-18 khi hợp đồng còn 60, 30, 7 ngày hết hạn tới PA và đầu mối `LEADER`.

**Luồng thay thế.** Sửa đầu mối `TENANT_ADMIN` sau khi tenant `ACTIVE` không đổi tài khoản quản trị tỉnh ở realm; giao diện nhắc TA tự quản người dùng ở PH-12.

**Luồng ngoại lệ.**

- Định dạng sai: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."
- Còn thiếu đầu mối bắt buộc: ERR-20-021 (422).
- Hợp đồng chồng thời hạn hoặc ngày sai: ERR-20-022 (422).

**Đầu ra.** `201` khi thêm, `200` khi sửa; bản ghi đầu mối hoặc hợp đồng, `ETag`.

**Kết quả.** Thông báo tới đúng người; hợp đồng hiện hành là căn cứ hạn mức.

**Hậu điều kiện.** EN-20-03, EN-20-04 cập nhật; đầu mối ngừng không còn nhận thông báo.

**Sự kiện phát ra.** Không (dữ liệu đầu mối không đi trên sự kiện, BR-20-039).

**Kiểm toán.** Có: người sửa, trường thay đổi (thư, điện thoại được che một phần trong nhật ký), lý do, mã phiếu.

**Quy tắc nghiệp vụ.** BR-20-009, BR-20-039.

**Màn hình, API.** UI-20-03 tab Hợp đồng và đầu mối; API-20-007, API-20-008, API-20-009, API-20-010, API-20-011, API-20-012.
:::

#### FR-20-006 · Bảo vệ tenant đặc biệt PLATFORM và COMMON

::: dac-ta
**Mục đích.** Bảo đảm tenant quản trị nền tảng và tenant dữ liệu dùng chung toàn quốc không bao giờ bị sửa nhầm, tạm ngừng, sáp nhập, chấm dứt hay khởi tạo lại, vì mọi tenant khác phụ thuộc vào hai tenant này.

**Tác nhân, quyền.** Hệ thống (lớp kiểm tra chung của mô-đun `tenant`); áp cho mọi tác nhân kể cả PA.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §2; FR-00-012.

**Tiền điều kiện.** Hai bản ghi `PLATFORM`, `COMMON` được tạo bằng migration nền (Liquibase changeset `ph20-seed-special-tenants`), `kind` tương ứng, `status = ACTIVE`.

**Kích hoạt.** Bất kỳ lệnh ghi nào trên bản ghi tenant hoặc thực thể con có `tenantCode` thuộc hai mã này.

**Đầu vào.** `tenantCode` của lệnh.

**Luồng xử lý chính.**

1. Bộ chặn (`SpecialTenantGuard`) chạy trước mọi lệnh ghi của nhóm A, B, C (trừ FR-20-019 với khóa được phép), D, E, F, G, I (trừ đăng ký kênh của `PLATFORM`).
2. Nếu `kind` là `PLATFORM` hoặc `COMMON`, hệ thống từ chối với ERR-20-010 và ghi kiểm toán mức cảnh báo.
3. Bảng `tenant` có ràng buộc CHECK và trigger CSDL chặn `UPDATE status`, `DELETE` với hai mã này, làm lớp bảo vệ thứ hai khi mã ứng dụng lỗi.
4. Registry (FR-20-065) luôn trả hai tenant này `ACTIVE`, loại khỏi `kind=PROVINCE`.

**Luồng thay thế.** Cấu hình nền tảng của `PLATFORM` (host quản trị, vùng DR) sửa được qua FR-20-019 với hai PA; đi qua đường thay đổi hạ tầng D04-02.

**Luồng ngoại lệ.**

- Lệnh ghi trên tenant đặc biệt: ERR-20-010 (403); "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."
- Trigger CSDL chặn (lỗi lập trình lọt qua lớp ứng dụng): ERR-20-010 (403); "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này." Kèm cảnh báo bảo mật tới PH-13.

**Đầu ra.** `403` với thân RFC 9457.

**Kết quả.** Không ai làm hỏng được hai tenant nền.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người, lệnh bị chặn, tenant, thời điểm (mức `WARN`).

**Quy tắc nghiệp vụ.** BR-20-003.

**Màn hình, API.** Không có màn riêng; không có API riêng, áp cho mọi API ghi ở mục 9.4.
:::

#### FR-20-007 · Kiểm tra sẵn sàng trước khởi tạo

::: dac-ta
**Mục đích.** Phát hiện trước những lý do làm saga chắc chắn lỗi (mã trùng, tỉnh đã có tenant, nền tảng hết sức chứa, cụm thiếu tài nguyên, mẫu hỏng, phân hệ đích không khả dụng) để PA xử lý trước khi tạo tài nguyên thật.

**Tác nhân, quyền.** PA (`PERM-20-provision`); hệ thống tự gọi ở bước rà soát wizard và ngay trước FR-20-008.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; NFR-00-057; NFR-00-060.

**Tiền điều kiện.** Có hồ sơ khai báo (chưa lưu: API-20-005; đã lưu: API-20-006).

**Kích hoạt.** Bước "Rà soát" của UI-20-02; nút "Kiểm tra lại" ở UI-20-04; tự động trong FR-20-008 bước 2.

**Đầu vào.** Hồ sơ khai báo (như FR-20-001) hoặc `tenantCode` đã lưu.

**Luồng xử lý chính.**

1. Hệ thống chạy các mục kiểm theo bảng dưới, song song, mỗi mục tối đa 10 giây.
2. Mỗi mục cho `PASS`, `WARN` hoặc `BLOCKER` kèm thông điệp và gợi ý xử lý.
3. Hệ thống trả tổng hợp `ready = true` khi không có `BLOCKER`; lưu kết quả lần kiểm gần nhất vào bản ghi tenant (nếu đã lưu).

**Luồng thay thế.** Mục phụ thuộc phân hệ chưa bật theo mẫu (ví dụ PH-16 chưa có ở Đợt 1) cho `PASS` với ghi chú "Bước sẽ SKIPPED".

**Luồng ngoại lệ.**

- Có mục `BLOCKER` khi gọi từ FR-20-008: ERR-20-017 (422); "Kiểm tra sẵn sàng chưa đạt: {số} mục cần xử lý."
- Vượt sức chứa (mục `CAPACITY`): ERR-20-013 (422); "Nền tảng đã đạt sức chứa {số} tenant. Liên hệ vận hành hạ tầng để mở rộng."
- Cụm thiếu tài nguyên: mục `CLUSTER_RESOURCES` là `BLOCKER`, ERR-20-014; "Cụm chưa đủ tài nguyên cho hồ sơ {hồ sơ}: thiếu {tài nguyên}."
- Phân hệ đích không trả lời kiểm sức khỏe: mục `DEPENDENCIES` là `BLOCKER`, ERR-20-062; "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Đầu ra.** `200`; `ready`, `checkedAt`, `items[]` (`checkCode`, `result`, `message`, `errorCode`, `hint`).

**Kết quả.** PA biết chính xác phải xử lý gì trước khi khởi tạo.

**Hậu điều kiện.** Không tạo tài nguyên; lưu kết quả kiểm khi tenant đã có bản ghi.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có với lần kiểm trong FR-20-008.

**Quy tắc nghiệp vụ.** BR-20-002, BR-20-042.

**Màn hình, API.** UI-20-02 bước 5, UI-20-04; API-20-005, API-20-006.
:::

| `checkCode` | Nội dung kiểm | Mức khi không đạt |
|---|---|---|
| `CODE_UNIQUE` | Mã chưa dùng, kể cả tenant đã `DECOMMISSIONED`, `MERGED` | `BLOCKER` (ERR-20-003) |
| `ADMIN_UNIT` | ĐVHC cấp tỉnh, còn hiệu lực, chưa có tenant khác | `BLOCKER` (ERR-20-011, ERR-20-012) |
| `CAPACITY` | Số tenant `kind = PROVINCE`, không kiểm thử, khác `DECOMMISSIONED` < sức chứa cấu hình nền tảng (mặc định 40, giả định trên NFR-00-060 ≥ 34) | `BLOCKER` (ERR-20-013); `WARN` khi ≥ 90% |
| `CLUSTER_RESOURCES` | Tài nguyên còn trống của cụm đủ cho hồ sơ quy mô (CPU, bộ nhớ, dung lượng Ceph, `pg-core`) theo Mimir | `BLOCKER` (ERR-20-014); `WARN` khi còn dưới 20% sau khởi tạo |
| `TEMPLATE` | Mẫu `PUBLISHED`, lược đồ hợp lệ, phân hệ trong mẫu có ở danh mục, gói danh mục nền tồn tại ở PH-07 | `BLOCKER` (ERR-20-015) |
| `CONTACTS` | Có đầu mối `TENANT_ADMIN`, `TECHNICAL`; thư công vụ chưa là tài khoản ở realm khác | `BLOCKER` (ERR-20-021) |
| `HOST_PREFIX` | Host và tiền tố API công bố dự kiến chưa dùng bởi tenant khác | `BLOCKER` (ERR-20-067) |
| `DEPENDENCIES` | PH-12, PH-13, PH-07, PH-10, OpenBao, Ceph RGW, Git, Argo CD trả kiểm sức khỏe đạt | `BLOCKER` (ERR-20-062) |
| `CLUSTER_TARGET` | Với `DEDICATED_CLUSTER`: cụm đích `VERIFIED` | `BLOCKER` (ERR-20-064) |
| `CONTRACT` | Có hợp đồng hiệu lực | `WARN` (cho khởi tạo trước khi ký, Q20-03) |

: Các mục kiểm tra sẵn sàng của FR-20-007

### 6.3. Nhóm B · Saga khởi tạo

Nhóm B là trái tim của PH-20: biến một hồ sơ khai báo thành một tỉnh có đủ realm, bí mật, bucket, topic, chuỗi kiểm toán, cổng, không gian tích hợp, danh mục nền, tổ chức, chỉ tiêu và phân hệ, rồi kiểm tra khói và bàn giao. Saga điều phối do PH-20 tự xây trên PostgreSQL (ADR 200 đề xuất): mỗi lần chạy có sổ bước, mỗi bước lũy đẳng với `Idempotency-Key = {runId}:{stepCode}`, có bù trừ ngược và chạy dưới khóa ShedLock theo tenant để hai bản sao `dh-platform` không chạy cùng một bước.

#### FR-20-008 · Chạy saga khởi tạo tenant

::: dac-ta
**Mục đích.** Tự động tạo đủ tài nguyên của một tenant trên mọi tầng theo mười bảy bước ở mục 4.4, trong ≤ 1 giờ ở chế độ `SHARED`, không cần thao tác tay giữa các bước.

**Tác nhân, quyền.** PA (`PERM-20-provision`); bộ thực thi saga (tác vụ nền trong `TenantContext` của `PLATFORM`); phân hệ tham gia báo tiến độ với scope `tenant:provision-report`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; BO-06; KPI-12; NFR-00-057; BP-08; D03-10 §5.2; SEC-82, SEC-88; LGC-IAM-002 (gián tiếp); ADR 200.

**Tiền điều kiện.** Tenant `PROVISIONING` (lần chạy `INITIAL`) hoặc `ACTIVE` (lần chạy `SUPPLEMENT`, FR-20-016); không có lần chạy khác chưa kết thúc (BR-20-006); kiểm tra sẵn sàng đạt.

**Kích hoạt.** Bấm "Khởi tạo" ở UI-20-03 hoặc "Lưu và khởi tạo" ở UI-20-02; hoặc FR-20-016 tạo lần chạy `SUPPLEMENT`.

**Đầu vào.** `tenantCode`; `runKind` (`INITIAL` mặc định); `steps[]` (chỉ với `SUPPLEMENT`); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tenant ở trạng thái phù hợp (ERR-20-006), không có lần chạy dang dở (ERR-20-016).
2. Hệ thống chạy lại FR-20-007; có `BLOCKER` thì từ chối (ERR-20-017).
3. Hệ thống tạo lần chạy `PENDING` với sổ mười bảy bước, đánh dấu `SKIPPED` bước không áp dụng (`S07_DATABASE` khi `SHARED`; `S12_SEED_MDM` khi PH-06 không bật; `S14_KPI` khi PH-16 không bật), ghi `templateVersion`, trả `202`.
4. Bộ thực thi lấy lần chạy dưới khóa ShedLock `provision:{tenantCode}`, chuyển `RUNNING`, thực hiện tuần tự `S01`…`S05`; mỗi bước gọi bên thực hiện với `Idempotency-Key = {runId}:{stepCode}`, lưu `outputRef`.
5. Sau `S05_BUCKETS`, hệ thống phát EVT-20-01 qua outbox; bốn bước bất đồng bộ `S06`, `S09`, `S10`, `S12` sang `WAITING_REPORT`, đồng thời bộ thực thi chạy `S07`, `S08` (đồng bộ); lần chạy sang `WAITING` khi chỉ còn bước chờ báo.
6. Phân hệ báo qua API-20-166 (FR-20-009 mô tả thân báo); khi đủ bốn báo `SUCCEEDED`, bộ thực thi chạy `S11`, `S13`, `S14` tuần tự.
7. Ở `S15_MODULES`, hệ thống phát EVT-20-07 cho từng phân hệ không lõi bật theo mẫu, chờ từng phân hệ báo; phân hệ lõi đã có tài nguyên từ các bước trước nên đánh dấu `ENABLED` ngay.
8. Hệ thống chạy `S16_SMOKE` (FR-20-012); đạt thì chạy `S17_ACTIVATE` (FR-20-013); lần chạy `SUCCEEDED`.
9. Một bước lỗi: hệ thống tự thử lại tối đa `20.provision.step-retry-max` lần với giãn cách lũy thừa (10, 30, 90 giây); hết lần thử thì bước `FAILED`, lần chạy `FAILED`, tenant `FAILED`, phát EVT-20-02, báo PA qua PH-18.

**Luồng thay thế.** (a) `DEDICATED_DB`: `S07_DATABASE` tạo cụm CloudNativePG từ mẫu, chạy migration mọi schema, ghi bảng định tuyến; `S08`…`S17` dùng chuỗi kết nối mới. (b) `DEDICATED_CLUSTER`: theo FR-20-017. (c) Một phân hệ báo `SKIPPED` cho bước bất đồng bộ (ví dụ PH-06 nhận EVT-20-01 nhưng chưa có gói nền): bước `SKIPPED`, saga tiếp tục.

**Luồng ngoại lệ.**

- Tenant không ở trạng thái cho phép: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Đã có lần chạy dang dở: ERR-20-016 (409); "Tenant {mã} đang có lần khởi tạo {runId} chưa kết thúc."
- Kiểm tra sẵn sàng chưa đạt: ERR-20-017 (422).
- Tenant đặc biệt: ERR-20-010 (403).
- Bên thực hiện trả lỗi (runtime, hiển thị ở UI-20-04 dòng bước): ERR-20-107; "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}."
- Bước bất đồng bộ quá hạn (runtime): ERR-20-106; "Bước {bước} chưa nhận báo cáo từ {bên thực hiện} sau {phút} phút."
- Tổng thời gian vượt `20.provision.timeout-minutes` (runtime): ERR-20-108; "Khởi tạo vượt thời gian cho phép {phút} phút." Lần chạy không tự hủy, chỉ chuyển `FAILED` tại bước đang chạy.

**Đầu ra.** `202`; `runId`, `status = PENDING`, `steps[]` (mã, thứ tự, trạng thái ban đầu); tiêu đề `Location: /api/platform/v1/provisioning-runs/{runId}`.

**Kết quả.** PA thấy sổ bước chạy dần trên UI-20-04; tỉnh mới thường `ACTIVE` sau 20–40 phút.

**Hậu điều kiện.** Lần chạy `SUCCEEDED` và tenant `ACTIVE`; hoặc `FAILED` với tài nguyên đã tạo được giữ nguyên để thử lại.

**Sự kiện phát ra.** EVT-20-01 (sau `S05`), EVT-20-07 (từng phân hệ ở `S15`), EVT-20-02 (khi `FAILED`), EVT-20-03 (ở `S17`).

**Kiểm toán.** Có: người chạy, `runId`, phiên bản mẫu, mỗi bước bắt đầu, kết thúc, kết quả, mã lỗi; ghi vào chuỗi `PLATFORM` và chuỗi của tenant khi đã có.

**Quy tắc nghiệp vụ.** BR-20-004, BR-20-005, BR-20-006, BR-20-007, BR-20-042.

**Màn hình, API.** UI-20-02, UI-20-03, UI-20-04; API-20-013, API-20-166.
:::

Ví dụ thân báo tiến độ mà PH-10 gửi cho bước `S06_EVENTING` qua API-20-166 (scope `tenant:provision-report`, `Idempotency-Key = run-01JH8K2V9M:S06_EVENTING:report`):

```json
{
  "tenantCode": "T68",
  "status": "SUCCEEDED",
  "reportedBy": "PH-10",
  "outputRef": {
    "aclPrefix": "t68.",
    "systemTopics": ["t68.platform.dlq.v1", "t68.platform.audit.v1"],
    "apicurioGroup": "t68"
  },
  "errorCode": null,
  "finishedAt": "2026-11-27T09:14:05+07:00"
}
```

PH-20 chỉ nhận báo cho bước đang `WAITING_REPORT` của đúng `runId`; báo trùng cùng khóa trả lại kết quả lần đầu; báo cho bước khác trạng thái trả ERR-20-105.

#### FR-20-009 · Theo dõi tiến độ saga thời gian thực

::: dac-ta
**Mục đích.** Cho PA, PO thấy saga đang ở bước nào, mỗi bước mất bao lâu, bước nào chờ phân hệ nào, để can thiệp đúng lúc thay vì đợi hết giờ mới biết lỗi.

**Tác nhân, quyền.** PA, PO (`PERM-20-read`); PAU xem.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; NFR-00-057.

**Tiền điều kiện.** Có ít nhất một lần chạy.

**Kích hoạt.** Mở UI-20-04; giao diện mở luồng SSE.

**Đầu vào.** `tenantCode` hoặc `runId`; với luồng SSE: `Last-Event-ID` khi nối lại.

**Luồng xử lý chính.**

1. Hệ thống trả danh sách lần chạy của tenant (mới nhất trước) và chi tiết lần chạy được chọn kèm sổ bước (không có: ERR-20-002).
2. Giao diện mở API-20-016 (Server-Sent Events); hệ thống đẩy sự kiện `step-changed`, `run-changed`, `report-received` khi trạng thái đổi, kèm `eventId` tăng dần.
3. Mỗi dòng bước hiện trạng thái, bên thực hiện, thời gian chạy, số lần thử, mã lỗi, nút hành động phù hợp (thử lại, bỏ qua, xem chi tiết).
4. Hệ thống tính và hiện ước thời gian còn lại theo trung vị thời gian từng bước của 20 lần chạy `SUCCEEDED` gần nhất.

**Luồng thay thế.** Trình duyệt không giữ được SSE (proxy chặn): giao diện chuyển sang kéo API-20-015 mỗi 5 giây.

**Luồng ngoại lệ.**

- Không có lần chạy: ERR-20-002 (404); "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- Tham số lọc sai: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."
- `Last-Event-ID` quá cũ (hơn 1 giờ): hệ thống gửi ảnh chụp đầy đủ thay cho chuỗi bù, không lỗi.

**Đầu ra.** `200`; lần chạy (`runId`, `runKind`, `status`, `startedAt`, `elapsedSeconds`, `etaSeconds`, `attempt`), `steps[]` (`stepCode`, `order`, `executor`, `mode`, `status`, `attempt`, `durationSeconds`, `errorCode`, `errorDetail`, `outputRef`); luồng `text/event-stream`.

**Kết quả.** PA thấy sổ bước cập nhật trong ≤ 2 giây sau mỗi thay đổi (NFR-20-007).

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-005.

**Màn hình, API.** UI-20-04; API-20-014, API-20-015, API-20-016.
:::

#### FR-20-010 · Thử lại saga từ bước lỗi

::: dac-ta
**Mục đích.** Cho PA tiếp tục khởi tạo sau khi đã khắc phục nguyên nhân lỗi (phân hệ đích đã lên lại, cấu hình đã sửa) mà không làm lại các bước đã xong, nhờ mọi bước lũy đẳng.

**Tác nhân, quyền.** PA (`PERM-20-provision`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.2 ("cho phép thử lại từ bước lỗi").

**Tiền điều kiện.** Lần chạy `FAILED`; tenant `FAILED` (lần chạy `INITIAL`) hoặc `ACTIVE` (`SUPPLEMENT`).

**Kích hoạt.** Bấm "Thử lại từ bước lỗi" ở đầu UI-20-04, "Thử lại bước" trên một dòng, hoặc "Bỏ qua bước" với bước không bắt buộc.

**Đầu vào.** `runId`; `stepCode` (thử lại, bỏ qua một bước); `reason` (bắt buộc khi bỏ qua, ≥ 20 ký tự); `Idempotency-Key`; `If-Match` (phiên bản lần chạy).

**Luồng xử lý chính.**

1. Hệ thống kiểm lần chạy ở `FAILED` (ERR-20-006) và bước được chọn ở `FAILED` (ERR-20-018).
2. Hệ thống chạy lại FR-20-007 phần `DEPENDENCIES` cho bên thực hiện của bước; chưa đạt thì cảnh báo nhưng vẫn cho thử (PA đã biết rủi ro).
3. Hệ thống đặt lại số lần tự thử của bước về 0, tăng `attempt` của lần chạy, chuyển lần chạy `RUNNING`, tenant `PROVISIONING`.
4. Bộ thực thi gọi lại bước với cùng `Idempotency-Key = {runId}:{stepCode}`; bên thực hiện đã làm xong phần nào thì trả kết quả cũ, chưa thì làm tiếp.
5. Saga tiếp tục các bước sau như FR-20-008.

**Luồng thay thế.** Bỏ qua bước: chỉ `S12_SEED_MDM`, `S14_KPI` và từng phân hệ trong `S15_MODULES` (phân hệ đó chuyển `FAILED` ở EN-20-20, bật lại sau bằng FR-20-034); bước chuyển `SKIPPED` kèm lý do.

**Luồng ngoại lệ.**

- Lần chạy không ở `FAILED`: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Bước không ở `FAILED` hoặc không bỏ qua được: ERR-20-018 (409); "Không thể thử lại bước {bước}: {lý do}."

**Đầu ra.** `202`; lần chạy với `status = RUNNING`, `attempt` mới.

**Kết quả.** Saga chạy tiếp từ đúng chỗ dừng; các bước đã xong không bị làm lại.

**Hậu điều kiện.** Lần chạy `RUNNING`; bước được thử lại `RUNNING` hoặc `SKIPPED`.

**Sự kiện phát ra.** Không (EVT-20-01 không phát lại; phân hệ bất đồng bộ được gửi lại lệnh qua sự kiện nội bộ đã có cùng `eventId` nếu bước của nó được thử lại).

**Kiểm toán.** Có: người thử lại, bước, lý do khi bỏ qua, `attempt`.

**Quy tắc nghiệp vụ.** BR-20-005, BR-20-006, BR-20-007.

**Màn hình, API.** UI-20-04; API-20-017, API-20-018, API-20-019.
:::

#### FR-20-011 · Bù trừ và hủy khởi tạo

::: dac-ta
**Mục đích.** Cho PA gỡ sạch tài nguyên đã tạo khi quyết định không khởi tạo tiếp (khai báo nhầm, tỉnh hoãn ký hợp đồng, lỗi không khắc phục được), để không để lại realm, bucket, topic mồ côi.

**Tác nhân, quyền.** PA (`PERM-20-provision`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.2 (cột bù trừ); SEC-82.

**Tiền điều kiện.** Lần chạy `FAILED` (bù trừ hoặc hủy), hoặc `PENDING` (hủy ngay, chưa có gì để bù); tenant chưa từng `ACTIVE` với lần chạy `INITIAL`.

**Kích hoạt.** Bấm "Bù trừ" hoặc "Hủy khởi tạo" ở UI-20-04; `CMP-ConfirmDialog` yêu cầu gõ lại mã tenant.

**Đầu vào.** `runId`; `reason`, `ticketRef`; `confirmTenantCode`; `Idempotency-Key`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm lần chạy ở trạng thái cho phép (ERR-20-006) và tenant chưa từng `ACTIVE` khi là `INITIAL` (ERR-20-019).
2. Hệ thống chuyển lần chạy `COMPENSATING`; lấy các bước `SUCCEEDED` hoặc `FAILED` có làm dở, theo thứ tự ngược.
3. Với mỗi bước, bộ thực thi gọi thao tác bù trừ ở mục 4.4 với `Idempotency-Key = {runId}:{stepCode}:compensate`; bước bất đồng bộ được bù bằng EVT-20-04 `status = DECOMMISSIONED` mà phân hệ nghe để gỡ, rồi chờ báo.
4. `S04_SECRETS` bù bằng xóa đường dẫn và hủy KEK chưa mã hóa dữ liệu nào; `S05_BUCKETS` chỉ xóa bucket rỗng, bucket có đối tượng thì để lại và đánh dấu `MANUAL_CLEANUP`.
5. Khi mọi bước `COMPENSATED`, lần chạy `COMPENSATED`; với "Hủy khởi tạo" tiếp theo `CANCELLED`, tenant `DECOMMISSIONED` (mã không tái dùng được, BR-20-001).

**Luồng thay thế.** "Bù trừ" không hủy: dùng cho lần chạy `SUPPLEMENT` lỗi, chỉ gỡ phần bổ sung, tenant giữ `ACTIVE`. Bù trừ một bước lỗi: lần chạy về `FAILED`, chi tiết bước hiện ở UI-20-04, PA thử bù lại.

**Luồng ngoại lệ.**

- Trạng thái không cho bù: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Tenant đã từng hoạt động: ERR-20-019 (409); "Không thể bù trừ: {lý do}."
- Gõ sai mã xác nhận: ERR-20-004 (400).
- Bù trừ một bước lỗi (runtime): bước giữ `COMPENSATING` với ERR-20-107, lần chạy `FAILED`; hiện ở UI-20-04.

**Đầu ra.** `202`; lần chạy `COMPENSATING`; danh sách bước sẽ bù.

**Kết quả.** Không còn tài nguyên mồ côi; danh sách việc dọn tay (nếu có) hiện ở UI-20-04.

**Hậu điều kiện.** Lần chạy `COMPENSATED` hoặc `CANCELLED`; tenant `DECOMMISSIONED` khi hủy.

**Sự kiện phát ra.** EVT-20-04 (`DECOMMISSIONED`, `cause = PROVISIONING_CANCELLED`).

**Kiểm toán.** Có: người, lý do, phiếu, từng bước bù và kết quả, tài nguyên để lại.

**Quy tắc nghiệp vụ.** BR-20-001, BR-20-005, BR-20-009.

**Màn hình, API.** UI-20-04; API-20-020, API-20-021.
:::

#### FR-20-012 · Kiểm tra khói sau khởi tạo

::: dac-ta
**Mục đích.** Chứng minh tenant mới thật sự dùng được và cách ly đúng trước khi mở cho tỉnh: quản trị tỉnh đăng nhập được, API mẫu gọi được qua APISIX, sự kiện mẫu đi trọn vòng, và token của tenant mới không đọc được dữ liệu tenant khác.

**Tác nhân, quyền.** Hệ thống (bước `S16_SMOKE`); PA chạy lại (`PERM-20-provision`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.2 bước 9; FR-00-011; SEC-87.

**Tiền điều kiện.** Các bước `S01`…`S15` `SUCCEEDED` hoặc `SKIPPED`; `20.smoke.enabled = true`.

**Kích hoạt.** Bộ thực thi tới `S16_SMOKE`; hoặc PA bấm "Chạy lại kiểm tra khói" ở UI-20-04.

**Đầu vào.** `tenantCode`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống tạo tài khoản máy tạm `smoke-{runId}` ở realm của tenant qua PH-12 (hạn 30 phút) và một HTTT giả lập.
2. Ca `LOGIN_ADMIN`: lấy token cho tài khoản quản trị tỉnh đầu tiên bằng luồng kiểm thử, kiểm claim `tenant = T68`.
3. Ca `API_SAMPLE`: gọi API mẫu `GET /api/tenant/v1/context` qua APISIX bằng host của tenant, kỳ vọng `200`.
4. Ca `EVENT_SAMPLE`: phát một sự kiện mẫu lên `t68.platform.smoke.v1` và đọc lại trong 30 giây.
5. Ca `CROSS_TENANT_LEAK`: dùng token tenant mới đọc một tài nguyên cài sẵn của tenant kiểm thử `T99`, kỳ vọng `404`.
6. Hệ thống lưu kết quả từng ca (EN-20-12), xóa tài khoản tạm, HTTT giả lập; bước `SUCCEEDED` khi cả bốn ca đạt.

**Luồng thay thế.** `20.smoke.enabled = false` (chỉ cho tenant kiểm thử `T90…T98`): bước `SKIPPED` với cảnh báo; tenant thật không được tắt (BR-20-004).

**Luồng ngoại lệ.**

- Một ca lỗi (runtime): ca ghi ERR-20-117 "Ca kiểm tra khói {ca} lỗi: {chi tiết}."; bước `FAILED`, lần chạy `FAILED`.
- Ca `CROSS_TENANT_LEAK` trả khác `404`: ERR-20-111 "Phát hiện rò rỉ chéo tenant ở {API}."; mở sự cố mức 1 ở PH-13, chặn kích hoạt.
- Chạy lại khi lần chạy đã `SUCCEEDED` và tenant `ACTIVE`: chạy độc lập, không đổi trạng thái tenant; nếu đang có lần chạy khác: ERR-20-016 (409); "Tenant {mã} đang có lần khởi tạo {runId} chưa kết thúc."
- Tenant `SUSPENDED`, `DECOMMISSIONED` khi chạy lại: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

**Đầu ra.** `202` khi chạy lại; kết quả trong chi tiết lần chạy (`smokeResults[]` gồm `case`, `result`, `durationMs`, `evidence`).

**Kết quả.** PA thấy bốn dấu tích xanh trước khi nút "Kích hoạt" sáng.

**Hậu điều kiện.** EN-20-12 có kết quả; không còn tài khoản tạm.

**Sự kiện phát ra.** Không (sự kiện mẫu chỉ ở topic kiểm thử của tenant).

**Kiểm toán.** Có: kết quả từng ca, tài khoản tạm tạo và xóa.

**Quy tắc nghiệp vụ.** BR-20-004, BR-20-038.

**Màn hình, API.** UI-20-04 khối "Kiểm tra khói"; API-20-015, API-20-022.
:::

#### FR-20-013 · Kích hoạt tenant và bàn giao cho quản trị tỉnh

::: dac-ta
**Mục đích.** Chuyển tenant sang `ACTIVE`, báo cho mọi phân hệ, gửi thư bàn giao (đường dẫn đăng nhập, hướng dẫn đổi mật khẩu, đăng ký MFA, đầu mối hỗ trợ) tới quản trị tỉnh để tỉnh bắt đầu kết nạp HTTT.

**Tác nhân, quyền.** Hệ thống (bước `S17_ACTIVATE`); PA (`PERM-20-provision`) khi mẫu đặt `activation = MANUAL`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; BO-06; KPI-12; D03-10 §5.2 bước 10.

**Tiền điều kiện.** `S16_SMOKE` `SUCCEEDED` (hoặc `SKIPPED` với tenant kiểm thử).

**Kích hoạt.** Bộ thực thi tới `S17_ACTIVATE`; hoặc PA bấm "Kích hoạt" ở UI-20-04 khi mẫu yêu cầu kích hoạt tay (ví dụ chờ lễ khai trương).

**Đầu vào.** `tenantCode`; `activateAt` (tùy chọn, hẹn giờ ≤ 30 ngày); `Idempotency-Key`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm kết quả kiểm tra khói (ERR-20-020) và tenant `PROVISIONING` (ERR-20-006).
2. Hệ thống chuyển tenant `ACTIVE`, ghi `activated_at`, lịch sử trạng thái; xóa cờ `testClient` ở realm.
3. Hệ thống phát EVT-20-03 qua outbox; registry vô hiệu đệm.
4. Hệ thống gửi thư bàn giao qua PH-18 tới đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL` theo mẫu thư `ph20-handover`.
5. Hệ thống gọi FR-20-014 để đẩy thời gian khởi tạo cho PH-16.

**Luồng thay thế.** `activateAt` trong tương lai: bước `S17` ở `WAITING_REPORT` tới giờ hẹn, lần chạy `WAITING`; PA hủy hẹn để kích hoạt ngay. PA bấm "Gửi lại thư bàn giao" ở UI-20-03 khi đầu mối chưa nhận (tối đa 3 lần mỗi ngày).

**Luồng ngoại lệ.**

- Kiểm tra khói chưa đạt: ERR-20-020 (422); "Kiểm tra khói chưa đạt ({số} ca lỗi). Không thể kích hoạt tenant."
- Trạng thái không phù hợp: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Gửi thư lỗi (PH-18 không khả dụng): không chặn kích hoạt; UI-20-04 hiện ERR-20-062 "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." ({tên} = Thông báo) và nút "Gửi lại".

**Đầu ra.** `200`; tenant `ACTIVE`, `activatedAt`, `handoverDelivery` (`SENT`, `FAILED`).

**Kết quả.** Quản trị tỉnh nhận thư, đăng nhập `dh-console` của tỉnh và bắt đầu làm việc.

**Hậu điều kiện.** Tenant `ACTIVE`; lần chạy `SUCCEEDED`.

**Sự kiện phát ra.** EVT-20-03; EVT-20-04 (`PROVISIONING` → `ACTIVE`).

**Kiểm toán.** Có: thời điểm kích hoạt, người (hệ thống hoặc PA), người nhận thư.

**Quy tắc nghiệp vụ.** BR-20-004, BR-20-039, BR-20-041.

**Màn hình, API.** UI-20-04; API-20-023.
:::

#### FR-20-014 · Đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16

::: dac-ta
**Mục đích.** Đo khách quan KPI-12 "thời gian khởi tạo một tenant tỉnh mới tới khi sẵn sàng kết nối ≤ 1 ngày làm việc" và đẩy số đo cho PH-16 để báo cáo chỉ tiêu không cần nhập tay.

**Tác nhân, quyền.** Hệ thống; PA, PO xem (`PERM-20-read`); PH-20 gọi PH-16 với scope `kpi.ingest`.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** KPI-12; BO-06; NFR-00-057; Q16-16 của PH-16 (đã chọn API đẩy); Q20-19.

**Tiền điều kiện.** Tenant vừa `ACTIVE` qua lần chạy `INITIAL`; PH-16 có thể chưa bật (Đợt 3).

**Kích hoạt.** FR-20-013 bước 5; PA mở tab "Thời gian khởi tạo" ở UI-20-20.

**Đầu vào.** `tenantCode`, `declaredAt`, `activatedAt`, thời gian từng bước, số lần thử.

**Luồng xử lý chính.**

1. Hệ thống tính `provisionMinutes` = thời gian saga (từ `startedAt` lần chạy đầu tới `SUCCEEDED`, gồm cả các lần thử) và `leadTimeWorkingHours` = từ `declaredAt` tới `activatedAt` theo lịch làm việc (8 giờ mỗi ngày, trừ thứ Bảy, Chủ nhật và ngày lễ trong lịch `COMMON`, Q20-19).
2. Hệ thống ghi số đo vào bảng chỉ số của lần chạy và chỉ số Prometheus `dh_tenant_provision_duration_seconds`.
3. Hệ thống gọi API-16-030 với quan sát `metricCode = thoi-gian-khoi-tao-tenant`, `value` (giờ làm việc), `periodStart`, `periodEnd`, `dimensions` {`tenantCode`, `isolationMode`}, `idempotencyRef = {runId}`, tenant ngữ cảnh là tenant mới.
4. PH-16 chưa bật hoặc lỗi: hệ thống giữ quan sát ở outbox chuyên dụng, thử lại mỗi giờ tới 30 ngày.

**Luồng thay thế.** PA xem bảng thời gian khởi tạo toàn nền tảng (API-20-024): trung vị, p95, bước chậm nhất theo 12 tháng.

**Luồng ngoại lệ.**

- PH-16 trả lỗi lược đồ (runtime): ghi ERR-20-107 ở nhật ký tác vụ, cảnh báo PO ở UI-20-20; "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}."
- Tham số lọc thống kê sai: ERR-20-004 (400).
- Khoảng thống kê vượt 24 tháng: ERR-20-032 (400).

**Đầu ra.** API-20-024 trả `200` với `items[]` (`tenantCode`, `provisionMinutes`, `leadTimeWorkingHours`, `slowestStep`), `median`, `p95`.

**Kết quả.** Chỉ tiêu `thoi-gian-khoi-tao-tenant` của PH-16 có số tự động cho mỗi tỉnh mới.

**Hậu điều kiện.** Có số đo lưu tại PH-20; quan sát được PH-16 nhận đúng một lần.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không (số đo kỹ thuật).

**Quy tắc nghiệp vụ.** BR-20-041.

**Màn hình, API.** UI-20-20; API-20-024; API-16-030 (PH-16).
:::

#### FR-20-015 · Quản lý mẫu khởi tạo có phiên bản

::: dac-ta
**Mục đích.** Cho PA định nghĩa sẵn "một tỉnh chuẩn trông như thế nào" (phân hệ bật, hạn mức theo quy mô, gói danh mục nền, tổ chức gieo, bộ chỉ tiêu, cờ tính năng) thành mẫu có phiên bản, để mọi tỉnh mới giống nhau và thay đổi mẫu có kiểm soát.

**Tác nhân, quyền.** PA (`PERM-20-admin`); PO, PAU xem.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; BO-06; D01-02 §10.8 (khác biệt chỉ bằng cấu hình).

**Tiền điều kiện.** Danh mục phân hệ (FR-20-033) có sẵn.

**Kích hoạt.** UI-20-21: "+ Mẫu", "Tạo phiên bản mới", "Sửa", "Phát hành", "Ngừng", "So sánh".

**Đầu vào.** Theo bảng dữ liệu vào của FR-20-015 dưới đây; `Idempotency-Key` khi tạo; `If-Match` khi sửa, phát hành, ngừng.

**Luồng xử lý chính.**

1. PA tạo mẫu (mã theo `^[a-z][a-z0-9-]{2,62}$`, trùng: ERR-20-003) hoặc mở phiên bản `n+1` sao từ phiên bản `PUBLISHED` mới nhất.
2. PA sửa phiên bản `DRAFT`; hệ thống kiểm lược đồ: phân hệ có ở danh mục, đủ phụ thuộc bắt buộc (ERR-20-033), hạn mức mỗi hồ sơ quy mô trong trần nền tảng (ERR-20-029), gói danh mục nền tồn tại ở PH-07, tổ chức gieo có mã duy nhất (ERR-20-004).
3. PA bấm "Phát hành"; hệ thống tính `contentHash`, chuyển `PUBLISHED`; phiên bản `PUBLISHED` bất biến (sửa: ERR-20-063).
4. Lần chạy saga ghi `templateCode` và `version` đã dùng; tenant đã tạo không tự đổi khi mẫu có phiên bản mới (đổi qua FR-20-016).

**Luồng thay thế.** "Ngừng": phiên bản `RETIRED` không chọn được cho khai báo mới, tenant đã dùng giữ nguyên. "So sánh": hiển thị khác biệt hai phiên bản theo khối bằng `CMP-DiffViewer`.

**Luồng ngoại lệ.**

- Mã trùng: ERR-20-003 (409); "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- Thiếu phụ thuộc phân hệ: ERR-20-033 (422).
- Hạn mức ngoài trần: ERR-20-029 (422).
- Sửa phiên bản đã phát hành: ERR-20-063 (409).
- Ngừng phiên bản đang là mặc định duy nhất: ERR-20-006 (409).

**Đầu ra.** `201`, `200`; mẫu và phiên bản (`templateCode`, `version`, `state`, `contentHash`, `ETag`).

**Kết quả.** PA có danh sách mẫu (`tinh-chuan`, `tinh-thi-diem`, `test-minimal`) để chọn khi khai báo.

**Hậu điều kiện.** EN-20-09 cập nhật; tối đa một phiên bản `DRAFT` mỗi mẫu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người sửa, khác biệt nội dung, người phát hành.

**Quy tắc nghiệp vụ.** BR-20-042, BR-20-017.

**Màn hình, API.** UI-20-21; API-20-025, API-20-026, API-20-027, API-20-028, API-20-029, API-20-030, API-20-031, API-20-032.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `templateCode` | T-CODE | Có | `^[a-z][a-z0-9-]{2,62}$` | `tinh-chuan` |
| `name` | T-NAME | Có | 1…255 ký tự | `Tỉnh chuẩn Đợt 1` |
| `modules[]` | T-CODE[] | Có | Có ở EN-20-18; gồm mọi phân hệ lõi | `["PH-01","PH-02","PH-03","PH-04","PH-05","PH-07","PH-10","PH-12","PH-13","PH-14","PH-18","PH-20"]` |
| `quotaByScale` | T-JSON | Có | Mỗi hồ sơ quy mô đủ mười hai `QuotaResource`, trong trần | `{"QM-VUA": {"API_RPS": 500}}` |
| `rdmPackageVersion` | T-CODE | Có | Gói nền tồn tại ở PH-07 | `2026.11` |
| `orgSeed[]` | đối tượng | Có | Mã duy nhất, `orgType`, cha | `UBND-TINH`, `SO-KHCN` |
| `kpiSetVersion` | T-CODE | Khi có PH-16 | Phiên bản bộ chỉ tiêu `COMMON` | `2026.1` |
| `featureFlags` | T-JSON | Không | Cờ có ở danh mục | `{"ph04.sql-direct": false}` |
| `activation` | T-ENUM | Có | `AUTO`, `MANUAL` | `AUTO` |
| `releaseChannel` | T-ENUM | Có | `STABLE`, `PREVIEW` | `STABLE` |

: Dữ liệu vào của FR-20-015

#### FR-20-016 · Khởi tạo bổ sung cho tenant đang hoạt động

::: dac-ta
**Mục đích.** Khi nền tảng thêm một bước saga mới (ví dụ phân hệ Đợt 2 có bước khởi tạo riêng) hoặc một phân hệ mới, đưa các tenant đã `ACTIVE` lên cùng mức với tenant mới mà không làm lại cả saga.

**Tác nhân, quyền.** PA (`PERM-20-provision`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; BO-06; NFR-00-060.

**Tiền điều kiện.** Có bước hoặc phân hệ mà một số tenant `ACTIVE` chưa có (so phiên bản sổ bước của lần chạy gần nhất với sổ bước hiện hành).

**Kích hoạt.** UI-20-04 (theo tenant) hoặc nút "Khởi tạo bổ sung hàng loạt" ở UI-20-20.

**Đầu vào.** `steps[]` hoặc `modules[]` cần bổ sung; `tenantCodes[]` hoặc bộ lọc; `waveSize` (số tenant chạy song song, mặc định 3); `reason`, `ticketRef`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. PA bấm "Xem trước"; hệ thống liệt kê tenant thiếu bước, ước thời gian, bỏ tenant `SUSPENDED`, `MERGING`, `MERGED`, tenant đang có lần chạy (ghi lý do).
2. PA xác nhận; hệ thống tạo một đợt gồm các lần chạy `SUPPLEMENT`, mỗi lần chỉ gồm bước được chọn, các bước khác `SKIPPED`.
3. Hệ thống chạy tối đa `waveSize` lần chạy cùng lúc; lần chạy của tenant lỗi không chặn tenant khác.
4. Mỗi lần chạy dùng cơ chế của FR-20-008; tenant giữ `ACTIVE` suốt quá trình, không phục vụ gián đoạn.

**Luồng thay thế.** Bổ sung phân hệ mới cho một tenant: tương đương FR-20-034 với bước `S15_MODULES`.

**Luồng ngoại lệ.**

- Không tenant nào cần bổ sung: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Bước không hỗ trợ bổ sung (`S01`, `S02`, `S03`, `S16`, `S17`): ERR-20-004 (400).
- Một tenant lỗi (runtime): lần chạy của tenant đó `FAILED`, ERR-20-107 trên dòng bước; thử lại bằng FR-20-010.

**Đầu ra.** `200` cho xem trước (`candidates[]`, `excluded[]` kèm lý do); `202` khi tạo đợt (`planId`, `runIds[]`).

**Kết quả.** Mọi tỉnh đang hoạt động có cùng nền tài nguyên với tỉnh mới, không gián đoạn phục vụ.

**Hậu điều kiện.** Mỗi tenant có lần chạy `SUPPLEMENT` mới, `SUCCEEDED` hoặc `FAILED`.

**Sự kiện phát ra.** EVT-20-07 cho phân hệ được bổ sung.

**Kiểm toán.** Có: người, đợt, danh sách tenant, lý do, phiếu; mỗi tenant một bản ghi trong chuỗi của mình.

**Quy tắc nghiệp vụ.** BR-20-005, BR-20-006, BR-20-009.

**Màn hình, API.** UI-20-04, UI-20-20; API-20-013, API-20-033, API-20-034.
:::

#### FR-20-017 · Khởi tạo tenant chế độ DEDICATED_CLUSTER

::: dac-ta
**Mục đích.** Cho tỉnh tự vận hành tại chỗ (cấp độ 4, hồ sơ `HT-A`) có một cụm Kubernetes riêng mà vẫn dùng cùng bộ mã, cùng saga và cùng gói phát hành với nền tảng dùng chung (D03-10 §2, RB-07).

**Tác nhân, quyền.** PA (`PERM-20-provision`); đơn vị vận hành của tỉnh cung cấp cụm và kích hoạt đồng bộ.

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-20; NFR-00-056 (≤ 3 ngày làm việc từ khi có cụm đạt yêu cầu); D03-09; Q20-08.

**Tiền điều kiện.** Cụm đích có Argo CD, CloudNativePG, Kafka, Ceph hoặc kho S3 tương đương, Keycloak, OpenBao theo D03-09; có kết nối mạng một chiều từ cụm tỉnh tới kho Git phát hành.

**Kích hoạt.** "+ Đăng ký cụm" ở UI-20-21 tab Cụm; chọn cụm ở bước 2 của UI-20-02; "Sinh gói cấu hình" ở UI-20-03.

**Đầu vào.** Cụm: `clusterCode`, `name`, `apiEndpoint`, `argoCdEndpoint`, `ownerTenant`, `capabilities`, tham chiếu bí mật OpenBao (`secretRef`, không bao giờ là giá trị); `Idempotency-Key`.

**Luồng xử lý chính.**

1. PA đăng ký cụm; hệ thống lưu `REGISTERED`, kiểm mã duy nhất (ERR-20-003).
2. PA bấm "Kiểm tra cụm"; hệ thống chạy bộ kiểm khả năng (phiên bản Kubernetes, CRD bắt buộc, StorageClass, chính sách mạng, dung lượng) qua tài khoản chỉ đọc, ghi `VERIFIED` hoặc danh sách thiếu (ERR-20-064).
3. Khai báo tenant chọn `DEDICATED_CLUSTER` và cụm `VERIFIED`; saga chạy như FR-20-008 nhưng bên thực hiện của `S03`…`S15` là thành phần trên cụm đích; PH-20 trung tâm chỉ ghi Git ở thư mục `clusters/{clusterCode}/tenants/{ma}/`.
4. Với cụm chỉ cho kéo (Q20-08), PA bấm "Sinh gói cấu hình"; hệ thống dựng gói `tar.zst` chứa overlay Kustomize, giá trị Helm, sổ bước, chữ ký, giao cho tỉnh; bộ thực thi saga cục bộ trên cụm tỉnh chạy và báo tiến độ ngược về qua API-20-166 khi có kết nối.

**Luồng thay thế.** Cụm của tỉnh không kết nối ngược được: tiến độ được nhập bằng tệp báo cáo ký do bộ thực thi cục bộ sinh, PA tải lên UI-20-04; PH-20 kiểm chữ ký rồi áp như báo tiến độ.

**Luồng ngoại lệ.**

- Cụm không đạt: ERR-20-064 (422); "Cụm {mã} chưa đạt yêu cầu: {danh sách thiếu}."
- Mã cụm trùng: ERR-20-003 (409).
- Đợt 2 chưa bật (`20.dedicated-cluster.enabled = false`): ERR-20-006 (409).
- Tệp báo cáo sai chữ ký: ERR-20-004 (400).

**Đầu ra.** `201` khi đăng ký cụm; `200` kết quả kiểm; `202` khi sinh gói (`bundleId`, liên kết tải có hạn 24 giờ, `sha256`).

**Kết quả.** Tỉnh tự vận hành có tenant chạy trên cụm riêng, được nâng cấp bằng cùng gói phát hành (BR-20-035).

**Hậu điều kiện.** Cụm `VERIFIED`; tenant như FR-20-008.

**Sự kiện phát ra.** Như FR-20-008.

**Kiểm toán.** Có: đăng ký, kiểm cụm, sinh và tải gói, người tải.

**Quy tắc nghiệp vụ.** BR-20-005, BR-20-035, BR-20-040.

**Màn hình, API.** UI-20-02, UI-20-03, UI-20-21; API-20-035, API-20-036, API-20-037, API-20-038.
:::

### 6.4. Nhóm C · Cấu hình

Nhóm C quản lý ba lớp cấu hình của tenant: cài đặt tỉnh do TA tự quản, cấu hình nền tảng do PA giữ và chính sách tiếp nhận liên tenant của tỉnh. Hai lớp đầu là trạng thái mong muốn trong Git (ADR 201 đề xuất): mọi lần đổi là một commit ký, Argo CD áp xuống, bộ đối chiếu phát hiện lệch hằng giờ.

#### FR-20-018 · Cài đặt tỉnh do quản trị tỉnh tự quản

::: dac-ta
**Mục đích.** Cho quản trị tỉnh tự đặt thông tin hiển thị, chủ quản CNTT, an toàn đăng nhập (chỉ chặt hơn mức nền tảng) và cửa sổ bảo trì ưa thích mà không phải nhờ quản trị nền tảng.

**Tác nhân, quyền.** TA (`PERM-20-settings`); mọi vai trò tỉnh xem phần hiển thị (`PERM-20-org-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; LGC-BUS-031 (gián tiếp); CMP-LAW-08 (TCVN 14423:2026 mật khẩu ≥ 14 ký tự, khóa phiên 15 phút); D00-04 §5 (chủ quản CNTT mặc định Sở KH&CN).

**Tiền điều kiện.** Tenant `ACTIVE` (`SUSPENDED`, `MERGED` chỉ đọc).

**Kích hoạt.** Mở UI-20-12, sửa, bấm "Lưu".

**Đầu vào.** Theo bảng dữ liệu vào của FR-20-018; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống trả cài đặt hiện hành kèm giới hạn nền tảng cho từng trường.
2. TA sửa rồi bấm "Lưu"; hệ thống kiểm giới hạn: `sessionIdleMinutes` ≤ 15, `passwordMinLength` ≥ 14, `mfaRequiredRoles` ⊇ vai trò quản trị, cửa sổ bảo trì dài 2…6 giờ (vượt: ERR-20-023; cửa sổ sai: ERR-20-059).
3. Hệ thống kiểm `itOwnerOrgCode` là tổ chức `ACTIVE` của tỉnh (ERR-20-002).
4. Hệ thống lưu, ghi `settings.yaml` qua FR-20-020, phát EVT-20-09; PH-12 nghe để áp chính sách phiên, mật khẩu cho realm.

**Luồng thay thế.** Logo: tải tệp PNG, SVG ≤ 512 KB qua DD-12, quét mã độc trước khi dùng.

**Luồng ngoại lệ.**

- Vượt giới hạn nền tảng: ERR-20-023 (422); "{Thiết lập} vượt giới hạn của nền tảng ({giới hạn})."
- Tenant tạm ngừng hoặc đã sáp nhập: ERR-20-001 (403) hoặc ERR-20-115 (409); "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh." hoặc "Tỉnh đã sáp nhập vào {đích}. Dữ liệu chỉ còn để tra cứu."

**Đầu ra.** `200`; cài đặt mới, `ETag`, `configVersionNo`.

**Kết quả.** Tên, logo tỉnh hiện trên `dh-console`; chính sách đăng nhập mới áp ở lần đăng nhập kế tiếp.

**Hậu điều kiện.** EN-20-06 cập nhật; có phiên bản cấu hình mới.

**Sự kiện phát ra.** EVT-20-09 (`changeKind = TENANT_SETTINGS`).

**Kiểm toán.** Có: người, trường trước và sau.

**Quy tắc nghiệp vụ.** BR-20-010, BR-20-011.

**Màn hình, API.** UI-20-12; API-20-135, API-20-136, API-20-160.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `displayName` | T-NAME | Có | 1…255 ký tự | `Datahub tỉnh T68` |
| `logoFileId` | T-ID | Không | DD-12, PNG hoặc SVG ≤ 512 KB | `01JH…` |
| `itOwnerOrgCode` | T-CODE | Có | Tổ chức `ACTIVE` | `SO-KHCN` |
| `sessionIdleMinutes` | số | Có | 5…15 | `15` |
| `passwordMinLength` | số | Có | 14…64 | `14` |
| `mfaRequiredRoles` | T-ENUM[] | Có | Chứa `ROLE-TENANT_ADMIN` | `["ROLE-TENANT_ADMIN","ROLE-SECURITY_OFFICER"]` |
| `maintenanceWindowPref` | RRULE + giờ | Có | Dài 2…6 giờ, múi giờ `Asia/Ho_Chi_Minh` | `FREQ=WEEKLY;BYDAY=SA` 22:00, 4 giờ |
| `supportContactEmail` | T-EMAIL | Không | Thư công vụ | `ho-tro@t68.example.vn` |

: Dữ liệu vào của FR-20-018

#### FR-20-019 · Cấu hình nền tảng của tenant

::: dac-ta
**Mục đích.** Cho PA giữ các cấu hình quyết định cách tenant được phục vụ (host và tiền tố API công bố, hồ sơ triển khai, vùng DR, chế độ namespace runtime) ở một nơi có phiên bản, là nguồn PH-03, PH-04 đọc.

**Tác nhân, quyền.** PA (`PERM-20-admin`); PO, PAU xem.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §4 (APISIX, runtime); FR-03-039.

**Tiền điều kiện.** Tenant không `DECOMMISSIONED`.

**Kích hoạt.** UI-20-03 tab "Cấu hình nền tảng", "Sửa".

**Đầu vào.** `publicHost`, `apiPathPrefix`, `deploymentProfile`, `drRegion`, `runtimeNamespaceMode` (`SHARED_NS`, `DEDICATED_NS`); `reason`, `ticketRef`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống trả cấu hình hiện hành kèm trạng thái ghi Git và áp Argo CD (FR-20-020).
2. PA sửa; hệ thống từ chối đổi `realm` (ERR-20-068), kiểm host theo tên miền hợp lệ, tiền tố `^/[a-z0-9-]{2,30}$` (ERR-20-004), không trùng tenant khác (ERR-20-067).
3. Hệ thống kiểm không có lệch chưa xử lý trên cùng tệp (ERR-20-025).
4. Hệ thống lưu, ghi `tenant.yaml` qua FR-20-020, phát EVT-20-09; PH-03 dựng lại route theo FR-03-039.

**Luồng thay thế.** Đổi `runtimeNamespaceMode` sang `DEDICATED_NS` khi tenant có trên 50 luồng (D03-10 §4): PH-04 nghe EVT-20-09 để di chuyển luồng sang `dh-rt-{tenant}`.

**Luồng ngoại lệ.**

- Host, tiền tố trùng: ERR-20-067 (409); "Tên miền hoặc tiền tố {giá trị} đã được tenant khác dùng."
- Đổi realm: ERR-20-068 (422); "Không đổi được {thuộc tính} của tenant sau khi khai báo."
- Đang lệch: ERR-20-025 (409).

**Đầu ra.** `200`; cấu hình mới, `ETag`, `configVersionNo`, `syncStatus`.

**Kết quả.** API công bố của tỉnh đổi host, tiền tố theo cấu hình sau khi PH-03 áp (≤ 5 phút, NFR-20-011).

**Hậu điều kiện.** EN-20-05 cập nhật.

**Sự kiện phát ra.** EVT-20-09 (`changeKind = PLATFORM_CONFIG`).

**Kiểm toán.** Có: trước, sau, lý do, phiếu.

**Quy tắc nghiệp vụ.** BR-20-001, BR-20-009, BR-20-010.

**Màn hình, API.** UI-20-03; API-20-039, API-20-040.
:::

#### FR-20-020 · Ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống

::: dac-ta
**Mục đích.** Bảo đảm mọi cấu hình tenant có một trạng thái mong muốn duy nhất, có lịch sử, có chữ ký, được áp tự động và kiểm chứng được, đúng D01-02 §10.3 "Cấu hình tenant: kho Git GitOps, thư mục theo mã tenant, chủ PH-20".

**Tác nhân, quyền.** Hệ thống (thành phần `tenant-config`, tài khoản `svc-ph20-gitops`); được gọi bởi FR-20-004, 018, 019, 025, 026, 027, 032, 034, 035, 036, 060, 062.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; ADR-009; ADR 201; LGC-BUS-031 (gián tiếp).

**Tiền điều kiện.** Kho `dh-tenant-config` truy cập được; khóa ký ở OpenBao.

**Kích hoạt.** Một FR ghi cấu hình gọi `ConfigWriter.apply(tenant, files, reason)` trong cùng giao dịch nghiệp vụ (qua outbox).

**Đầu vào.** Mã tenant, tệp cần đổi (`tenant.yaml`, `settings.yaml`, `quota.yaml`, `modules.yaml`, `release.yaml`), người đổi, lý do, mã phiếu.

**Luồng xử lý chính.**

1. Hệ thống sinh nội dung tệp từ bản ghi CSDL theo lược đồ JSON Schema của từng tệp, kiểm lược đồ (sai: ERR-20-004, lỗi lập trình).
2. Hệ thống commit vào nhánh chính tại `tenants/{ma-tenant}/` với thông điệp chuẩn `ph20({ma}): {loại thay đổi} [{ticketRef}]`, ký bằng khóa của `svc-ph20-gitops`; lưu `commitSha` vào EN-20-07 `syncStatus = COMMITTED`.
3. Hệ thống theo dõi ứng dụng Argo CD của tenant; khi `Synced` và `Healthy`, ghi `syncStatus = APPLIED`, `appliedAt`.
4. Hệ thống phát EVT-20-09 kèm `configVersionNo`, `commitSha` sau khi `APPLIED`.

**Luồng thay thế.** Xung đột đẩy (commit khác vào cùng thư mục): hệ thống kéo lại, sinh lại tệp từ CSDL và thử tối đa 3 lần; CSDL là nguồn sinh, Git là trạng thái mong muốn có ký.

**Luồng ngoại lệ.**

- Không đẩy được lên Git: ERR-20-024 (502); "Không ghi được cấu hình vào kho GitOps. Thử lại sau, nếu lặp lại báo vận hành nền tảng." Giao dịch nghiệp vụ đã lưu, bản ghi outbox thử lại; UI-20-17 hiện `syncStatus = PENDING_COMMIT`.
- Cấu hình đang lệch chưa đối chiếu: ERR-20-025 (409); "Cấu hình tenant {mã} đang lệch chưa xử lý. Đối chiếu trước khi sửa."
- Argo CD đồng bộ lỗi quá 10 phút (runtime): ERR-20-109 "Argo CD không áp được cấu hình {phiên bản}: {lý do}."; `syncStatus = SYNC_FAILED`, cảnh báo PO.

**Đầu ra.** Nội bộ; trạng thái hiện trong API-20-039 (`configVersionNo`, `commitSha`, `syncStatus`, `appliedAt`).

**Kết quả.** Mọi cấu hình của tỉnh tra được ai đổi, lúc nào, vì sao, đã áp chưa.

**Hậu điều kiện.** EN-20-07 có bản ghi mới.

**Sự kiện phát ra.** EVT-20-09.

**Kiểm toán.** Có: `commitSha`, người đổi, lý do, phiếu, tệp đổi.

**Quy tắc nghiệp vụ.** BR-20-010, BR-20-039.

**Màn hình, API.** Không có màn riêng (trạng thái ở UI-20-03, UI-20-17); API-20-039, API-20-040.
:::

#### FR-20-021 · Lịch sử, so sánh, khôi phục phiên bản cấu hình

::: dac-ta
**Mục đích.** Cho PA, PO xem lại cấu hình tenant đã thay đổi thế nào, so sánh hai phiên bản và khôi phục phiên bản cũ khi thay đổi gây sự cố.

**Tác nhân, quyền.** PA khôi phục (`PERM-20-admin`); PA, PO, PAU xem (`PERM-20-read`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; ADR-009.

**Tiền điều kiện.** Tenant có từ hai phiên bản cấu hình.

**Kích hoạt.** UI-20-17 tab "Phiên bản": chọn hai phiên bản, "So sánh"; "Khôi phục phiên bản này".

**Đầu vào.** `versionNo`, `compareTo`; khi khôi phục: `reason`, `ticketRef`, `If-Match`, `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống trả danh sách phiên bản (số, thời điểm, người, tệp đổi, lý do, `syncStatus`).
2. "So sánh": hệ thống đọc hai commit, trả khác biệt theo khóa YAML, hiển thị bằng `CMP-DiffViewer`.
3. "Khôi phục": hệ thống kiểm phiên bản cũ tương thích lược đồ hiện hành (ERR-20-026), không chạm thuộc tính bất biến, rồi áp như một thay đổi mới qua FR-20-020 (không xóa lịch sử).

**Luồng thay thế.** Phiên bản cũ có trường đã đổi tên: hệ thống chạy bộ chuyển đổi lược đồ trước khi so sánh; không chuyển được thì chỉ cho xem tệp gốc.

**Luồng ngoại lệ.**

- Không khôi phục được: ERR-20-026 (422); "Không khôi phục được phiên bản cấu hình {n}: {lý do}."
- Không có phiên bản: ERR-20-002 (404).

**Đầu ra.** `200` danh sách, khác biệt; `202` khi khôi phục (`configVersionNo` mới).

**Kết quả.** PA quay cấu hình về trạng thái đã biết là tốt trong vài phút.

**Hậu điều kiện.** Khôi phục tạo phiên bản mới có `restoredFrom`.

**Sự kiện phát ra.** EVT-20-09 khi khôi phục.

**Kiểm toán.** Có khi khôi phục: phiên bản nguồn, lý do, phiếu.

**Quy tắc nghiệp vụ.** BR-20-010.

**Màn hình, API.** UI-20-17; API-20-041, API-20-042, API-20-043.
:::

#### FR-20-022 · Phát hiện lệch cấu hình và đối chiếu định kỳ

::: dac-ta
**Mục đích.** Phát hiện khi trạng thái thực ở cụm hoặc ở phân hệ đích (realm, quota Kafka, route APISIX, `ResourceQuota`) khác trạng thái mong muốn trong Git, do sửa tay hoặc lỗi áp, để xử lý trước khi gây sự cố.

**Tác nhân, quyền.** Bộ lập lịch; PA xử lý (`PERM-20-admin`); PO xem.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; ADR 201; SEC-81, SEC-82.

**Tiền điều kiện.** Tenant `ACTIVE`, `SUSPENDED` hoặc `MERGING`.

**Kích hoạt.** Mỗi `20.drift.check-interval` (PT1H); PA bấm "Đối chiếu ngay" ở UI-20-17.

**Đầu vào.** `tenantCode`; khi xử lý: `driftId`, `action` (`REAPPLY` áp lại Git, `ACCEPT` nhận giá trị thực vào Git), `reason`, `ticketRef`.

**Luồng xử lý chính.**

1. Hệ thống đọc trạng thái Argo CD của các ứng dụng tenant (`OutOfSync`) và gọi API đối chiếu của phân hệ có (API-12-082 lệch realm), so với Git.
2. Mỗi khác biệt sinh một bản ghi EN-20-08 `DRIFTED`; trùng với bản ghi đang mở thì cập nhật `lastSeenAt`.
3. Hệ thống cảnh báo PO qua PH-13 khi có lệch mới ở khóa an ninh (ACL, chính sách, realm) ngay; khóa khác gộp báo hằng ngày.
4. PA chọn `REAPPLY`: hệ thống yêu cầu Argo CD đồng bộ lại hoặc gọi API-12-083; `ACCEPT`: hệ thống ghi giá trị thực vào CSDL và Git qua FR-20-020; bản ghi lệch `IN_SYNC` khi lần đối chiếu sau khớp.

**Luồng thay thế.** Không đọc được trạng thái (Argo CD không khả dụng): `DriftStatus = UNKNOWN` cho tenant, không sinh lệch giả.

**Luồng ngoại lệ.**

- `ACCEPT` với khóa an ninh: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Đang có đối chiếu chạy: ERR-20-006 (409); như trên, {thao tác} = đối chiếu ngay, {trạng thái} = đang đối chiếu
- Thiếu lý do, phiếu: ERR-20-008 (422).

**Đầu ra.** `200` danh sách lệch; `202` khi đối chiếu ngay, xử lý.

**Kết quả.** UI-20-17 hiện danh sách khóa lệch, giá trị mong muốn và thực, cách xử lý.

**Hậu điều kiện.** EN-20-08 cập nhật; Git và thực tế khớp sau xử lý.

**Sự kiện phát ra.** Không (cảnh báo qua PH-13).

**Kiểm toán.** Có: phát hiện lệch khóa an ninh, mọi xử lý.

**Quy tắc nghiệp vụ.** BR-20-010.

**Màn hình, API.** UI-20-17; API-20-044, API-20-045, API-20-046.
:::

#### FR-20-023 · Chính sách tiếp nhận truy cập liên tenant của tỉnh

::: dac-ta
**Mục đích.** Cho tỉnh quyết định vai trò nền tảng được vào dữ liệu của tỉnh ở mức nào (chỉ đọc hay được ghi, có cần tỉnh chấp thuận trước, tối đa bao lâu, ai được báo), trong trần mà PH-12 thực thi (BR-12-032: tối đa 4 giờ, lý do, phiếu, người duyệt thứ hai).

**Tác nhân, quyền.** TA (`PERM-20-settings`); SO, AU xem; PH-12 đọc qua API-20-165 (`tenant:registry-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; FR-00-012; SEC-85; FR-12-017; FR-12-027; BR-12-032.

**Tiền điều kiện.** Tenant `ACTIVE`; chính sách mặc định tạo ở `S01_RECORD` (`allowRead = true`, `allowWrite = false`, `requirePriorApproval = false`, `maxHours = 4`, báo `TENANT_ADMIN`, `SECURITY`).

**Kích hoạt.** UI-20-22 tab "Chính sách", "Sửa", "Lưu".

**Đầu vào.** `allowRead`, `allowWrite`, `requirePriorApproval`, `maxHours` (1…`20.cross-tenant.max-hours`), `notifyContacts[]`, `blockedReasons[]` (loại lý do tỉnh không chấp nhận); `If-Match`.

**Luồng xử lý chính.**

1. TA sửa; hệ thống kiểm `maxHours` ≤ trần nền tảng (ERR-20-027) và người nhận thông báo là đầu mối hoặc người dùng `ACTIVE` của tỉnh (ERR-20-004).
2. Hệ thống lưu phiên bản mới, vô hiệu đệm chính sách ở PH-12 qua EVT-20-09 (`changeKind = CROSS_TENANT_POLICY`).
3. Từ lần cấp quyền kế tiếp, PH-12 áp chính sách: `requirePriorApproval = true` thì yêu cầu truy cập phải có TA của tỉnh chấp thuận ngoài người duyệt nền tảng; `allowWrite = false` thì chỉ cấp quyền đọc.

**Luồng thay thế.** Sự cố an ninh mức 1 do SO của tỉnh báo: nền tảng vẫn được vào đọc tối đa 1 giờ kèm thông báo tức thời dù `allowRead = false` (ngoại lệ khẩn ghi trong chính sách, không tắt được, đề nghị xác nhận ở Q20-18).

**Luồng ngoại lệ.**

- Vượt trần: ERR-20-027 (422); "Thời hạn truy cập liên tenant tối đa là {giờ} giờ."
- Người nhận không hợp lệ: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."

**Đầu ra.** `200`; chính sách, `ETag`.

**Kết quả.** Tỉnh kiểm soát được việc nền tảng vào dữ liệu của mình và biết ngay khi có người vào.

**Hậu điều kiện.** EN-20-29 cập nhật.

**Sự kiện phát ra.** EVT-20-09.

**Kiểm toán.** Có: trước, sau, người sửa.

**Quy tắc nghiệp vụ.** BR-20-012.

**Màn hình, API.** UI-20-22; API-20-137, API-20-138, API-20-165.
:::

#### FR-20-024 · Xem nhật ký truy cập liên tenant vào tỉnh

::: dac-ta
**Mục đích.** Cho tỉnh thấy minh bạch ai của nền tảng đã vào dữ liệu tỉnh, khi nào, vì sao, làm gì, để giám sát và đối chiếu với phiếu hỗ trợ.

**Tác nhân, quyền.** TA (`PERM-20-settings`), SO, AU.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** FR-00-012; SEC-85; CMP-LAW-08.

**Tiền điều kiện.** Có phiên liên tenant đã ghi ở PH-12 và kiểm toán ở PH-13.

**Kích hoạt.** UI-20-22 tab "Nhật ký".

**Đầu vào.** `from`, `to` (≤ 366 ngày), `actor`, `reasonType`, `ticketRef`, `access` (`READ`, `WRITE`), `page`, `size`.

**Luồng xử lý chính.**

1. Hệ thống kiểm khoảng thời gian (ERR-20-032) và tham số (ERR-20-004).
2. Hệ thống đọc bản ghi kiểm toán loại `CROSS_TENANT_*` trong chuỗi của tenant từ PH-13 (truy vấn có tenant ngữ cảnh, không liên tenant), ghép lần cấp quyền từ PH-12.
3. Hệ thống trả danh sách phiên: người (tên, tenant nhà `PLATFORM`), lý do, phiếu, người duyệt, bắt đầu, kết thúc, số thao tác đọc, ghi, có thao tác ghi nào.

**Luồng thay thế.** Bấm một phiên: mở chi tiết thao tác (đường dẫn API, thời điểm, kết quả) từ PH-13.

**Luồng ngoại lệ.**

- Khoảng thời gian vượt tối đa: ERR-20-032 (400); "Khoảng thời gian tối đa là {số} ngày."
- PH-13 không khả dụng: ERR-20-062 (503).

**Đầu ra.** `200`; `items[]`, `page`, `totalElements`.

**Kết quả.** SO thấy danh sách phiên liên tenant, lọc nhanh phiên có ghi.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người xem nhật ký (đọc nhật ký kiểm toán là thao tác được kiểm toán).

**Quy tắc nghiệp vụ.** BR-20-012.

**Màn hình, API.** UI-20-22; API-20-139.
:::

#### FR-20-025 · Chuyển chế độ cách ly của tenant

::: dac-ta
**Mục đích.** Cho tỉnh đang dùng chung nâng lên `DEDICATED_DB` (chuẩn bị cấp độ 4, dữ liệu lớn) hoặc `DEDICATED_CLUSTER` mà không phải khởi tạo lại tenant, có duyệt bốn mắt vì đây là thay đổi lớn, khó đảo ngược.

**Tác nhân, quyền.** PA đề nghị (`PERM-20-lifecycle`), PA khác duyệt (`PERM-20-approve`).

**Mức ưu tiên, đợt.** S · Đợt 2.

**Truy vết.** REQ-20; D03-10 §2; ADR-003; SEC-83.

**Tiền điều kiện.** Tenant `ACTIVE`; không có kế hoạch sáp nhập, nâng cấp đang chạy.

**Kích hoạt.** UI-20-03 tab "Cấu hình nền tảng", "Đổi chế độ cách ly".

**Đầu vào.** `targetMode`, `scheduledAt` (trong cửa sổ bảo trì), `clusterCode` (khi `DEDICATED_CLUSTER`), `reason`, `ticketRef`, `decisionDocNo`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. PA lập đề nghị `ISOLATION_CHANGE`; hệ thống kiểm chỉ nâng một bậc (`SHARED` → `DEDICATED_DB` → `DEDICATED_CLUSTER`) hoặc hạ một bậc có lý do (ERR-20-028), lịch trong cửa sổ bảo trì (ERR-20-059).
2. Hệ thống ước thời gian và dung lượng chuyển (theo `DATABASE_GB`), tạo đề nghị `PENDING_APPROVAL` khi PA gửi.
3. PA khác duyệt (ERR-20-007 nếu cùng người); tới giờ hẹn, hệ thống tạo lần chạy `ISOLATION_CHANGE`: tạo cụm đích (`S07_DATABASE`), sao dữ liệu theo `tenant_id` bằng công cụ PH-18, chuyển tenant chỉ đọc trong lúc đồng bộ phần cuối, đổi bảng định tuyến, bật ghi.
4. Hệ thống kiểm đếm bản ghi theo bảng; khớp thì đổi `isolation_mode`, giữ dữ liệu cũ ở cụm chung `20.export.retention-days` ngày rồi xóa.

**Luồng thay thế.** Hạ bậc (`DEDICATED_DB` → `SHARED`): cùng luồng, chiều ngược; cần `decisionDocNo`.

**Luồng ngoại lệ.**

- Chuyển không hợp lệ: ERR-20-028 (422); "Không chuyển được từ chế độ {từ} sang {tới}: {lý do}."
- Tự duyệt: ERR-20-007 (403).
- Lịch ngoài cửa sổ bảo trì: ERR-20-059 (422).
- Kiểm đếm lệch (runtime): ERR-20-113 "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}."; lần chạy `FAILED`, định tuyến giữ cụm cũ.

**Đầu ra.** `201` đề nghị; `202` khi thực hiện (`runId`).

**Kết quả.** Tỉnh có CSDL riêng, gián đoạn ghi ≤ 15 phút trong cửa sổ bảo trì (giả định).

**Hậu điều kiện.** `isolation_mode` mới; cấu hình nền tảng phiên bản mới.

**Sự kiện phát ra.** EVT-20-09 (`changeKind = ISOLATION_MODE`); EVT-20-04 khi chuyển chỉ đọc và trở lại.

**Kiểm toán.** Có: đề nghị, duyệt, từng bước, kết quả kiểm đếm.

**Quy tắc nghiệp vụ.** BR-20-008, BR-20-009, BR-20-040.

**Màn hình, API.** UI-20-03; API-20-047, API-20-076, API-20-077, API-20-079.
:::

```{.mermaid caption="Trình tự duyệt và thực hiện chuyển chế độ cách ly SHARED sang DEDICATED_DB"}
sequenceDiagram
  actor PA1 as PA lập đề nghị
  actor PA2 as PA duyệt
  participant P20 as PH-20
  participant CNPG as CloudNativePG
  participant P18 as PH-18 công cụ chuyển
  participant K as Kafka
  PA1->>P20: Đề nghị ISOLATION_CHANGE, lịch trong cửa sổ
  P20-->>PA2: Việc duyệt trong hộp việc
  PA2->>P20: Duyệt (khác người lập)
  P20->>CNPG: S07_DATABASE tạo cụm dh-t68
  P20->>P18: Sao dữ liệu theo tenant_id
  P20->>K: EVT-20-04 tenant chỉ đọc tạm thời
  P18-->>P20: Đồng bộ phần cuối, kiểm đếm khớp
  P20->>P20: Đổi bảng định tuyến, isolation_mode
  P20->>K: EVT-20-09 và EVT-20-04 bật ghi
```

Hình cho thấy việc chuyển chỉ bắt đầu sau duyệt bốn mắt và chỉ đổi định tuyến khi kiểm đếm khớp; nếu lệch, tenant vẫn dùng cụm cũ.

### 6.5. Nhóm D · Hạn mức, sử dụng

Nhóm D giữ hạn mức hợp đồng của mỗi tỉnh, đẩy giá trị hiệu lực xuống nơi thực thi và đo sử dụng thực tế (ADR 204 đề xuất). PH-20 không tự chặn lượt gọi; nơi thực thi chặn theo giá trị được đẩy xuống; PH-20 cảnh báo ở 80% và 100% (SEC-86).

#### FR-20-026 · Đặt hạn mức hợp đồng của tenant

::: dac-ta
**Mục đích.** Ghi hạn mức cam kết theo hợp đồng cho mười hai tài nguyên của tenant, làm căn cứ thực thi và cảnh báo.

**Tác nhân, quyền.** PA (`PERM-20-quota`); PA, PO, PAU xem.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.3; SEC-86; FR-03-037 (trần `LimitCeilingRule` ERR-03-018).

**Tiền điều kiện.** Tenant không `DECOMMISSIONED`; hạn mức mặc định đã có từ mẫu ở `S01_RECORD`.

**Kích hoạt.** UI-20-05 "Sửa hạn mức".

**Đầu vào.** `items[]` (`resource`, `contractValue`); `contractId` căn cứ; `reason`, `ticketRef`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống trả hạn mức hợp đồng, trần nền tảng theo hồ sơ quy mô, ghi đè còn hạn, hiệu lực, mức dùng gần nhất.
2. PA nhập giá trị; hệ thống kiểm mỗi giá trị trong [tối thiểu, trần] (ERR-20-029).
3. Nếu có tài nguyên hạ xuống dưới mức đang dùng, hệ thống từ chối lệnh trực tiếp và yêu cầu dùng FR-20-027 (ERR-20-030).
4. Hệ thống lưu, tính lại hạn mức hiệu lực, ghi `quota.yaml` qua FR-20-020, phát EVT-20-05.

**Luồng thay thế.** Tăng trong trần không cần duyệt (đi thẳng FR-20-026); giảm nhưng vẫn ≥ mức đang dùng cũng không cần duyệt.

**Luồng ngoại lệ.**

- Ngoài miền, vượt trần: ERR-20-029 (422); "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}."
- Hạ dưới mức đang dùng: ERR-20-030 (422); "Hạ hạn mức {tài nguyên} xuống {giá trị} thấp hơn mức đang dùng {dùng} cần được duyệt."

**Đầu ra.** `200`; `items[]` (`resource`, `contractValue`, `platformCeiling`, `overrideValue`, `effectiveValue`, `lastUsage`), `ETag`.

**Kết quả.** Nơi thực thi áp hạn mức mới ≤ 5 phút (NFR-20-011).

**Hậu điều kiện.** EN-20-13 cập nhật.

**Sự kiện phát ra.** EVT-20-05.

**Kiểm toán.** Có: trước, sau, hợp đồng căn cứ, lý do, phiếu.

**Quy tắc nghiệp vụ.** BR-20-013, BR-20-014.

**Màn hình, API.** UI-20-05; API-20-048, API-20-049, API-20-164.
:::

#### FR-20-027 · Đổi hạn mức có duyệt và đẩy xuống nơi thực thi

::: dac-ta
**Mục đích.** Cho phép hạ hạn mức dưới mức đang dùng (ví dụ hợp đồng thu hẹp) với người thứ hai duyệt, vì thay đổi này có thể làm tỉnh bị chặn ngay; và bảo đảm mọi thay đổi hạn mức đến đúng nơi thực thi.

**Tác nhân, quyền.** PA lập (`PERM-20-quota`); PA khác duyệt (`PERM-20-approve`); nơi thực thi đọc qua API-20-164 (`tenant:registry-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; SEC-86; FR-00-071.

**Tiền điều kiện.** Tenant `ACTIVE` hoặc `SUSPENDED`.

**Kích hoạt.** UI-20-05 "Đề nghị đổi hạn mức"; PA khác duyệt ở UI-20-05 (hộp duyệt toàn nền tảng chưa có: Q20-46).

**Đầu vào.** `items[]` (`resource`, `newValue`), `effectiveAt`, `reason`, `ticketRef`, `contractId`; `Idempotency-Key`; khi duyệt: `comment`, `If-Match`.

**Luồng xử lý chính.**

1. PA lập đề nghị; hệ thống chụp mức dùng p95 7 ngày của từng tài nguyên, đánh dấu `requiresApproval = true` khi `newValue` < mức dùng.
2. Đề nghị không cần duyệt thì áp ngay như FR-20-026; cần duyệt thì `PENDING_APPROVAL`, việc duyệt vào hộp việc PH-18 cho người có `PERM-20-approve`.
3. PA khác duyệt (ERR-20-007 nếu là người lập); hệ thống áp vào `effectiveAt`, phát EVT-20-05.
4. Nơi thực thi nhận EVT-20-05 và đọc API-20-164 lấy giá trị; mỗi nơi xác nhận bằng sự kiện của mình (PH-03 EVT-03-11); hệ thống ghi `appliedAt` theo nơi, cảnh báo nơi chưa xác nhận sau 15 phút.

**Luồng thay thế.** Nơi thực thi không cắt tài nguyên đã có (không xóa dữ liệu vượt dung lượng, không dừng luồng đang chạy); chỉ chặn tạo mới vượt mức (BR-20-014). Từ chối: đề nghị `REJECTED`, hạn mức giữ nguyên.

**Luồng ngoại lệ.**

- Tự duyệt: ERR-20-007 (403); "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."
- Giá trị ngoài miền: ERR-20-029 (422); "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}."
- Đề nghị đã xử lý: ERR-20-006 (409).

**Đầu ra.** `201` đề nghị; `200` khi duyệt, từ chối; `appliedTargets[]` (nơi, thời điểm xác nhận).

**Kết quả.** Hạn mức mới có hiệu lực ở mọi nơi thực thi, có người duyệt khi rủi ro.

**Hậu điều kiện.** EN-20-14 `DONE` hoặc `REJECTED`; EN-20-13 cập nhật.

**Sự kiện phát ra.** EVT-20-05.

**Kiểm toán.** Có: đề nghị, mức dùng lúc lập, người duyệt, ý kiến, xác nhận từng nơi.

**Quy tắc nghiệp vụ.** BR-20-008, BR-20-013, BR-20-014.

**Màn hình, API.** UI-20-05; API-20-050, API-20-051, API-20-052, API-20-053, API-20-164.
:::

#### FR-20-028 · Thu thập sử dụng tài nguyên theo tenant

::: dac-ta
**Mục đích.** Có số đo sử dụng thực tế theo giờ cho mười hai tài nguyên của mọi tenant, làm nền cho cảnh báo, báo cáo và quyết định hợp đồng.

**Tác nhân, quyền.** Bộ lập lịch PH-20 (tác vụ nền `PLATFORM`, lặp theo tenant `ACTIVE`, `SUSPENDED`, `MERGING`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; SEC-86; ADR 204; ADR-047.

**Tiền điều kiện.** Mimir có chỉ số gắn nhãn `tenant`; API thống kê của PH-01, PH-02, PH-04, PH-10, PH-12 sẵn sàng; RGW admin API.

**Kích hoạt.** Mỗi `20.usage.snapshot-interval` (PT1H), phút thứ 5 của giờ.

**Đầu vào.** Danh sách tenant từ registry; truy vấn PromQL theo tài nguyên (ví dụ `max_over_time(sum by (tenant) (rate(apisix_http_status{tenant="t68"}[1m]))[1h:1m])`).

**Luồng xử lý chính.**

1. Hệ thống lặp theo tenant trong `TenantContext.runAs`, đọc số đo từ nguồn của từng tài nguyên (bảng ở mục 4.1).
2. Hệ thống ghi một dòng EN-20-16 cho mỗi tài nguyên và giờ, kèm hạn mức hiệu lực tại giờ đó và phần trăm; khóa duy nhất (`tenant_id`, `resource`, `hour_start`) bảo đảm lũy đẳng.
3. Nguồn không trả lời: dòng `quality = MISSING`; lần chạy giờ sau đọc bù tối đa 24 giờ trước.
4. Hệ thống gọi FR-20-029 đánh giá ngưỡng cho dòng mới.

**Luồng thay thế.** Tenant `DEDICATED_CLUSTER` không đẩy được chỉ số về Mimir trung tâm: số đo do bộ thực thi cục bộ gửi theo gói ngày, `quality = ESTIMATED` khi trễ.

**Luồng ngoại lệ.**

- Nguồn thiếu quá 3 giờ liên tiếp (runtime): ERR-20-110 "Thiếu số liệu sử dụng {tài nguyên} của {tenant} từ {giờ}."; cảnh báo PO ở UI-20-06.
- Mimir không khả dụng: ERR-20-062 (503); "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." Cả lượt `MISSING`, không phát cảnh báo hạn mức giả.
- Yêu cầu thu bổ sung cho tenant `DECOMMISSIONED`: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."

**Đầu ra.** Nội bộ; chỉ số `dh_tenant_usage_ratio{tenant,resource}`.

**Kết quả.** Biểu đồ sử dụng có điểm mỗi giờ cho mọi tỉnh.

**Hậu điều kiện.** EN-20-16 có dòng mới; dữ liệu giữ `20.usage.retention-months` tháng, phân vùng cũ được xóa theo tháng.

**Sự kiện phát ra.** Không (cảnh báo do FR-20-029 phát).

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-013, BR-20-016.

**Màn hình, API.** Không có màn riêng; không có API riêng, dữ liệu cho UI-20-06, UI-20-13 đọc qua API của FR-20-030.
:::

#### FR-20-029 · Cảnh báo ngưỡng hạn mức 80% và 100%

::: dac-ta
**Mục đích.** Báo sớm cho nền tảng và tỉnh khi một tài nguyên chạm 80% (để kịp đàm phán, dọn dữ liệu) và 100% (nơi thực thi đang chặn tạo mới).

**Tác nhân, quyền.** Hệ thống; PA xác nhận đã xử lý (`PERM-20-quota`); PO, TA xem.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** SEC-86; D03-10 §5.3 (cảnh báo ở 80%); EVT-13-14 (cảnh báo sức chứa của PH-13).

**Tiền điều kiện.** Có ảnh chụp mới (FR-20-028).

**Kích hoạt.** FR-20-028 bước 4; EVT-13-14 `{tenant}.obs.capacity.warning.v1` từ PH-13.

**Đầu vào.** Dòng ảnh chụp; `20.quota.warn-percent`; khi xác nhận: `alertId`, `comment`.

**Luồng xử lý chính.**

1. Sau mỗi ảnh chụp, và mỗi `20.usage.probe-interval` (PT5M) với nhóm đo bằng Mimir, hệ thống so `percent` với `20.quota.warn-percent` (80) và 100.
2. Vượt ngưỡng mà chưa có cảnh báo mở cùng tài nguyên, cùng mức: tạo EN-20-17 `OPEN`, phát EVT-20-06, gửi thông báo qua PH-18 tới PO và đầu mối `TECHNICAL`, `TENANT_ADMIN` của tỉnh.
3. Đã có cảnh báo mở: cập nhật `lastAt`, không gửi lặp (BR-20-016).
4. Mức dùng xuống dưới `20.quota.alert-reset-percent` (75) trong 24 giờ liên tục: cảnh báo `RESOLVED`.

**Luồng thay thế.** PA xác nhận: cảnh báo `ACKNOWLEDGED` kèm ý kiến (ví dụ "đã lập đề nghị tăng"), vẫn hiện cho tới khi `RESOLVED`.

**Luồng ngoại lệ.**

- Xác nhận cảnh báo đã `RESOLVED`: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Không có cảnh báo: ERR-20-002 (404); "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

**Đầu ra.** API-20-058 `200` danh sách; API-20-059 `200`.

**Kết quả.** Tỉnh và nền tảng nhận một thư cho mỗi lần chạm ngưỡng, không bị lặp mỗi giờ.

**Hậu điều kiện.** EN-20-17 cập nhật.

**Sự kiện phát ra.** EVT-20-06.

**Kiểm toán.** Có khi xác nhận.

**Quy tắc nghiệp vụ.** BR-20-016.

**Màn hình, API.** UI-20-06, UI-20-13; API-20-058, API-20-059.
:::

#### FR-20-030 · Xem sử dụng tài nguyên của tỉnh và toàn nền tảng

::: dac-ta
**Mục đích.** Cho nền tảng thấy tỉnh nào đang gần hạn mức, cụm còn bao nhiêu chỗ; cho tỉnh thấy mình dùng bao nhiêu so với hợp đồng.

**Tác nhân, quyền.** PA, PO (`PERM-20-read`) xem toàn nền tảng; TA, TO, AU (`PERM-20-usage-read`) xem tỉnh mình.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; SEC-86; FR-00-012 (toàn nền tảng chỉ dữ liệu tổng hợp).

**Tiền điều kiện.** Có ảnh chụp.

**Kích hoạt.** Mở UI-20-06 (nền tảng) hoặc UI-20-13 (tỉnh), chọn khoảng.

**Đầu vào.** `from`, `to` (≤ 400 ngày), `granularity` (`HOUR` khi ≤ 7 ngày, `DAY`, `MONTH`), `resource[]`, `tenantCode[]` (chỉ nền tảng), `sort` (`percent`).

**Luồng xử lý chính.**

1. Hệ thống kiểm tham số (ERR-20-004, ERR-20-032).
2. Hệ thống gộp ảnh chụp theo độ chi tiết (đỉnh và trung bình), kèm hạn mức hiệu lực từng thời điểm.
3. Bản nền tảng thêm bảng xếp hạng tenant theo phần trăm cao nhất và tổng sử dụng so với sức chứa cụm; bản tỉnh chỉ đọc tenant ngữ cảnh (RLS).

**Luồng thay thế.** Biểu đồ có nút "Xem dạng bảng" (NFR-20-022); dòng `MISSING` hiện là khoảng trống có chú thích, không nội suy.

**Luồng ngoại lệ.**

- Khoảng vượt tối đa: ERR-20-032 (400); "Khoảng thời gian tối đa là {số} ngày."
- Tham số sai: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."

**Đầu ra.** `200`; `series[]` (`resource`, `points[]` {`t`, `value`, `peak`, `limit`, `percent`, `quality`}), `ranking[]` (nền tảng).

**Kết quả.** Biểu đồ sử dụng theo tài nguyên có đường hạn mức, chip cảnh báo.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-013.

**Màn hình, API.** UI-20-06, UI-20-13; API-20-056, API-20-057, API-20-140, API-20-141.
:::

#### FR-20-031 · Báo cáo sử dụng tài nguyên theo kỳ, xuất tệp

::: dac-ta
**Mục đích.** Lập báo cáo sử dụng tháng, quý, năm theo tỉnh hoặc toàn nền tảng làm căn cứ nghiệm thu hợp đồng dịch vụ và lập kế hoạch sức chứa.

**Tác nhân, quyền.** PA, PO (`PERM-20-read`); TA, AU của tỉnh dùng bản tỉnh ở UI-20-13 (`PERM-20-usage-read`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; Q20-06 (không tính cước ở v1.0).

**Tiền điều kiện.** Kỳ đã kết thúc.

**Kích hoạt.** UI-20-06 "Lập báo cáo"; lịch tự lập ngày 2 hằng tháng cho kỳ tháng trước.

**Đầu vào.** `scope` (`PLATFORM` hoặc mã tenant), `period` (`M-2026-10`, `Q-2026-Q3`, `Y-2026`), `format` (`XLSX`, `CSV`, `PDF`); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm kỳ đã kết thúc và định dạng được hỗ trợ (ERR-20-066).
2. Hệ thống tạo EN-20-37 `REQUESTED`, chạy nền: tính đỉnh, trung bình, p95, số giờ vượt 80%, 100%, số giờ thiếu số liệu theo tài nguyên và tenant.
3. Hệ thống dựng tệp (POI cho XLSX, OpenHTMLtoPDF cho PDF), lưu bucket `dh-platform-exports`, ghi băm SHA-256, báo người lập qua PH-18.

**Luồng thay thế.** Báo cáo cùng phạm vi, kỳ, định dạng đã có: trả bản đã có (lũy đẳng theo nội dung).

**Luồng ngoại lệ.**

- Kỳ chưa kết thúc hoặc định dạng sai: ERR-20-066 (422); "Không lập được báo cáo sử dụng: {lý do}."
- Tải tệp đã hết hạn lưu: ERR-20-002 (404).

**Đầu ra.** `202` (`reportId`); API-20-062 trả tệp.

**Kết quả.** Bảng sử dụng theo kỳ, tải được trong 30 ngày.

**Hậu điều kiện.** EN-20-37 `READY`.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: người lập, phạm vi, kỳ, người tải.

**Quy tắc nghiệp vụ.** BR-20-013.

**Màn hình, API.** UI-20-06; API-20-060, API-20-061, API-20-062.
:::

#### FR-20-032 · Ghi đè hạn mức tạm thời có thời hạn

::: dac-ta
**Mục đích.** Cho phép nâng tạm hạn mức khi tỉnh có đợt cao điểm (kỳ tuyển sinh, quyết toán cuối năm) mà không đổi hợp đồng, tự hết hạn để không quên hạ lại.

**Tác nhân, quyền.** PA (`PERM-20-quota`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** SEC-86; D03-10 §5.3.

**Tiền điều kiện.** Tenant `ACTIVE`.

**Kích hoạt.** UI-20-05 "Ghi đè tạm thời"; "Thu hồi".

**Đầu vào.** `resource`, `value`, `validFrom`, `validTo`, `reason`, `ticketRef`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm `validTo − validFrom` ≤ `20.quota.override-max-days` (ERR-20-031), `value` > hạn mức hợp đồng và ≤ trần nền tảng (ERR-20-029).
2. Hệ thống lưu EN-20-15 `SCHEDULED` hoặc `ACTIVE`; tại `validFrom` tính lại hạn mức hiệu lực, phát EVT-20-05.
3. Tại `validTo` (bộ lập lịch mỗi 5 phút), ghi đè `EXPIRED`, hạn mức hiệu lực về hợp đồng, phát EVT-20-05; báo đầu mối trước 24 giờ.

**Luồng thay thế.** Thu hồi sớm: `REVOKED`, áp như hết hạn. Hai ghi đè chồng thời gian trên cùng tài nguyên: giá trị lớn hơn thắng, giao diện cảnh báo.

**Luồng ngoại lệ.**

- Quá số ngày: ERR-20-031 (422); "Ghi đè hạn mức tối đa {số} ngày."
- Ngoài trần: ERR-20-029 (422).
- Thu hồi ghi đè đã hết hạn: ERR-20-006 (409).

**Đầu ra.** `201`; ghi đè (`overrideId`, `status`, `effectiveValue`).

**Kết quả.** Tỉnh có thêm sức chứa trong đợt cao điểm, tự về mức hợp đồng sau đó.

**Hậu điều kiện.** EN-20-15 cập nhật.

**Sự kiện phát ra.** EVT-20-05 (bắt đầu, kết thúc).

**Kiểm toán.** Có: giá trị, thời hạn, lý do, phiếu, thu hồi.

**Quy tắc nghiệp vụ.** BR-20-013, BR-20-015.

**Màn hình, API.** UI-20-05; API-20-048, API-20-054, API-20-055.
:::

### 6.6. Nhóm E · Phân hệ, tính năng

Nhóm E quyết định tỉnh được dùng phân hệ nào. Danh mục hai mươi phân hệ và ma trận phụ thuộc là dữ liệu nền tảng; mỗi tenant có trạng thái riêng cho từng phân hệ. Bật, tắt đi qua sự kiện EVT-20-07, EVT-20-08 để chính phân hệ đó khởi tạo hoặc dừng phần của tenant (ví dụ PH-19 FR-19-064), rồi báo về.

#### FR-20-033 · Danh mục phân hệ của nền tảng và ma trận phụ thuộc

::: dac-ta
**Mục đích.** Cho PA thấy hai mươi phân hệ, phân hệ nào lõi, thuộc đợt nào, phụ thuộc phân hệ nào, có tham gia saga, sáp nhập, gói bàn giao không, để quyết định bật tắt đúng.

**Tác nhân, quyền.** PA, PO, PAU (`PERM-20-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-01 §4.1; D00-04 §2.

**Tiền điều kiện.** Danh mục được nạp bằng migration nền và cập nhật theo phiên bản sản phẩm (FR-20-059).

**Kích hoạt.** UI-20-07 tab "Danh mục phân hệ".

**Đầu vào.** `wave`, `core`, `q`.

**Luồng xử lý chính.**

1. Hệ thống trả danh sách EN-20-18 kèm phụ thuộc EN-20-19 dạng ma trận và đồ thị (`CMP-DependencyGraph`).
2. Mỗi phân hệ kèm số tenant đang `ENABLED`, `SUSPENDED`, `FAILED`.
3. Danh mục thay đổi chỉ khi phiên bản sản phẩm mới khai báo phân hệ hoặc phụ thuộc mới (thành phần `module-catalog` của bản phát hành); không sửa tay.

**Luồng thay thế.** Lọc `wave = 2`: hiện phân hệ Đợt 2 kèm cờ "chưa phát hành" khi bản đang chạy chưa có.

**Luồng ngoại lệ.**

- Tham số sai: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."
- Danh mục chưa nạp (lỗi triển khai): ERR-20-062 (503); "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Đầu ra.** `200`; `items[]` (`moduleCode`, `name`, `core`, `wave`, `asyncProvision`, `mergeParticipant`, `exportParticipant`, `dependsOn[]`, `featureFlags[]`, `tenantCounts`).

**Kết quả.** PA thấy ngay bật PH-19 cần PH-03, PH-12 đã bật.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-017.

**Màn hình, API.** UI-20-07; API-20-063.
:::

#### FR-20-034 · Bật phân hệ cho tenant

::: dac-ta
**Mục đích.** Cho PA bật một phân hệ cho tỉnh (ví dụ PH-19 Thanh toán khi tỉnh ký phụ lục), để phân hệ tự khởi tạo phần của tỉnh mà không phải chạy lại saga.

**Tác nhân, quyền.** PA (`PERM-20-admin`); phân hệ được bật báo qua API-20-166 (`tenant:provision-report`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; FR-19-064; D03-06-00 nguyên tắc 5.

**Tiền điều kiện.** Tenant `ACTIVE`; phân hệ có trong bản đang chạy của tenant; phân hệ ở `DISABLED` hoặc `FAILED`.

**Kích hoạt.** UI-20-07 tab "Phân hệ của tenant", "Bật".

**Đầu vào.** `moduleCode`, `reason`, `ticketRef`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm mọi phụ thuộc `REQUIRED` đang `ENABLED` (ERR-20-033) và phân hệ có trong phiên bản đang chạy (ERR-20-055).
2. Hệ thống tạo lần chạy `SUPPLEMENT` một bước `S15_MODULES` cho phân hệ, chuyển phân hệ `ENABLING`, phát EVT-20-07.
3. Phân hệ báo `SUCCEEDED`: `ENABLED`, ghi `modules.yaml` qua FR-20-020, registry vô hiệu đệm; báo `FAILED` hoặc quá hạn: `FAILED` (ERR-20-106, ERR-20-107).

**Luồng thay thế.** Phân hệ không có bước khởi tạo riêng (`asyncProvision = false`): `ENABLED` ngay sau bước 1.

**Luồng ngoại lệ.**

- Thiếu phụ thuộc: ERR-20-033 (422); "Phân hệ {phân hệ} cần {phụ thuộc} được bật trước."
- Phiên bản đang chạy chưa có phân hệ: ERR-20-055 (422); "Phiên bản {phiên bản} không dùng được cho thao tác này: {lý do}."
- Tenant không `ACTIVE`: ERR-20-006 (409).

**Đầu ra.** `202`; `moduleCode`, `state = ENABLING`, `runId`.

**Kết quả.** Menu phân hệ hiện ở `dh-console` của tỉnh sau khi `ENABLED`.

**Hậu điều kiện.** EN-20-20 cập nhật.

**Sự kiện phát ra.** EVT-20-07.

**Kiểm toán.** Có: phân hệ, người, lý do, phiếu, kết quả.

**Quy tắc nghiệp vụ.** BR-20-017, BR-20-009.

**Màn hình, API.** UI-20-07; API-20-064, API-20-065, API-20-166.
:::

#### FR-20-035 · Tắt, tạm ngừng phân hệ cho tenant

::: dac-ta
**Mục đích.** Cho PA tạm ngừng (giữ dữ liệu, chặn dùng tạm thời, ví dụ khi hợp đồng phụ lục hết hạn) hoặc tắt hẳn một phân hệ của tỉnh.

**Tác nhân, quyền.** PA (`PERM-20-admin`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; FR-19-064 (ERR-19-049).

**Tiền điều kiện.** Phân hệ `ENABLED` (tạm ngừng, tắt) hoặc `SUSPENDED` (tiếp tục, tắt); không phải phân hệ lõi.

**Kích hoạt.** UI-20-07 "Tạm ngừng", "Tiếp tục", "Tắt" (hộp `CMP-ConfirmDialog` nêu hệ quả).

**Đầu vào.** `moduleCode`, `reason`, `ticketRef`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống từ chối phân hệ lõi (ERR-20-035) và phân hệ đang là phụ thuộc `REQUIRED` của phân hệ khác đang bật (ERR-20-034).
2. Tạm ngừng: `SUSPENDED`, phát EVT-20-08 (`mode = SUSPEND`); phân hệ trả ERR-20-103 hoặc mã riêng ở data plane, giao diện chỉ đọc.
3. Tắt: `DISABLING`, phát EVT-20-08 (`mode = DISABLE`); phân hệ dừng tác vụ nền của tenant, báo xong thì `DISABLED`. Dữ liệu giữ theo thời hạn lưu của phân hệ (BR-20-018).
4. Ghi `modules.yaml` qua FR-20-020.

**Luồng thay thế.** "Tiếp tục": `SUSPENDED` → `ENABLED`, phát EVT-20-07 (`mode = RESUME`).

**Luồng ngoại lệ.**

- Phân hệ lõi: ERR-20-035 (403); "Phân hệ {phân hệ} là phân hệ lõi, không tắt được."
- Đang bị phụ thuộc: ERR-20-034 (409); "Phân hệ {phân hệ} đang được {danh sách} dùng. Tắt các phân hệ đó trước."
- Trạng thái không phù hợp: ERR-20-006 (409).

**Đầu ra.** `202`; phân hệ với trạng thái mới.

**Kết quả.** Người dùng tỉnh thấy phân hệ ở chế độ chỉ đọc hoặc biến khỏi menu.

**Hậu điều kiện.** EN-20-20 cập nhật.

**Sự kiện phát ra.** EVT-20-08; EVT-20-07 khi tiếp tục.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-017, BR-20-018.

**Màn hình, API.** UI-20-07; API-20-064, API-20-066, API-20-067, API-20-068.
:::

#### FR-20-036 · Cờ tính năng theo tenant

::: dac-ta
**Mục đích.** Bật tắt tính năng nhỏ trong phân hệ đang bật theo từng tỉnh (ví dụ `ph04.sql-direct` của ADR-067, `ph17.chat`) để thử dần hoặc đáp ứng yêu cầu riêng mà không cần nhánh mã.

**Tác nhân, quyền.** PA (`PERM-20-admin`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** REQ-20; D01-02 §10.8.

**Tiền điều kiện.** Cờ có trong danh mục cờ của phân hệ (EN-20-18 `featureFlags[]`); phân hệ `ENABLED`.

**Kích hoạt.** UI-20-07 tab "Cờ tính năng", công tắc.

**Đầu vào.** `flagCode`, `enabled`, `validTo` (tùy chọn), `reason`, `ticketRef`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm cờ có ở danh mục và phân hệ của cờ đang `ENABLED` (ERR-20-036).
2. Hệ thống lưu EN-20-21, ghi `modules.yaml` qua FR-20-020, phát EVT-20-09 (`changeKind = FEATURE_FLAG`).
3. Phân hệ đọc cờ qua API-20-163 (có đệm 60 giây) hoặc nghe EVT-20-09.

**Luồng thay thế.** `validTo` đến hạn: cờ về giá trị mặc định của mẫu, phát EVT-20-09.

**Luồng ngoại lệ.**

- Cờ không hợp lệ: ERR-20-036 (422); "Cờ {cờ} không áp dụng được: {lý do}."
- Phiên bản lệch: ERR-20-005 (412).

**Đầu ra.** `200`; cờ, `ETag`.

**Kết quả.** Tính năng bật hoặc tắt cho riêng tỉnh trong ≤ 60 giây.

**Hậu điều kiện.** EN-20-21 cập nhật.

**Sự kiện phát ra.** EVT-20-09.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-010, BR-20-037.

**Màn hình, API.** UI-20-07; API-20-069, API-20-070.
:::

#### FR-20-037 · Cung cấp trạng thái phân hệ cho menu và giao diện

::: dac-ta
**Mục đích.** Cho `dh-console` dựng menu đúng phân hệ đang bật của tỉnh (D03-06-00 nguyên tắc 5), hiện dải cảnh báo khi tenant `MERGING`, chế độ chỉ đọc khi `SUSPENDED`, và cho phân hệ biết mình có được phục vụ tenant không.

**Tác nhân, quyền.** Mọi người dùng đã đăng nhập (API-20-142, tenant từ token); phân hệ với `tenant:registry-read` (API-20-163).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-06-00; FR-00-010.

**Tiền điều kiện.** Người dùng có token của realm tỉnh.

**Kích hoạt.** `dh-console` tải sau đăng nhập và mỗi 5 phút; khi nhận thông báo đẩy có `EVT-20-04`, `EVT-20-07`, `EVT-20-08`.

**Đầu vào.** Không (tenant lấy từ token).

**Luồng xử lý chính.**

1. Hệ thống đọc tenant từ token (không từ tham số, FR-00-010).
2. Hệ thống trả trạng thái tenant, danh sách phân hệ kèm `state`, cờ tính năng áp dụng cho người dùng cuối, `banner` (loại `MERGING`, `SUSPENDED`, `MAINTENANCE`, `UPGRADE_SCHEDULED`) và `readOnly`.
3. Phản hồi có `ETag` và `Cache-Control: private, max-age=60`.

**Luồng thay thế.** Tenant `SUSPENDED`: vẫn trả `200` với `readOnly = true`, `banner.type = SUSPENDED` để người dùng hiểu lý do (không trả ERR-20-001 ở API này).

**Luồng ngoại lệ.**

- Token không có tenant hợp lệ: ERR-00-401 (401); "Phiên đăng nhập đã hết hạn. Đăng nhập lại."
- Tenant `DECOMMISSIONED`: ERR-20-102 (410); "Tỉnh đã chấm dứt sử dụng Datahub."

**Đầu ra.** `200`; `tenantCode`, `status`, `readOnly`, `modules[]` (`moduleCode`, `state`), `featureFlags`, `banner` {`type`, `message`, `until`, `link`}, `currentVersion`.

**Kết quả.** Menu chỉ hiện phân hệ tỉnh được dùng; dải cảnh báo nói rõ tình trạng tỉnh.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-021, BR-20-026, BR-20-036.

**Màn hình, API.** Mọi màn `dh-console`; API-20-142, API-20-163.
:::

### 6.7. Nhóm F · Vòng đời

Nhóm F đặc tả các chuyển trạng thái có quyết định của tenant: tạm ngừng, khôi phục, chấm dứt. Tạm ngừng, khôi phục không cần bốn mắt để phản ứng nhanh; chấm dứt có ba lớp an toàn: bốn mắt, gói bàn giao `DELIVERED`, thời gian nguội.

#### FR-20-038 · Tạm ngừng tenant

::: dac-ta
**Mục đích.** Cho PA ngừng phục vụ một tỉnh ngay khi có quyết định quản lý, sự cố an ninh, hết hợp đồng hoặc tỉnh đề nghị, mà vẫn giữ nguyên dữ liệu để khôi phục.

**Tác nhân, quyền.** PA (`PERM-20-lifecycle`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.1; SEC-85; API-12-084.

**Tiền điều kiện.** Tenant `ACTIVE`; không có kế hoạch sáp nhập ở `TRANSFERRING` trở đi.

**Kích hoạt.** UI-20-08 "Tạm ngừng".

**Đầu vào.** `reason` (`SuspendReason`), `reasonText` (≥ 20 ký tự), `ticketRef`, `decisionDocNo`, `decisionDocDate` (bắt buộc khi `MANAGEMENT_DECISION`, `CONTRACT_EXPIRED`), `essentialApisAllowed` (chỉ khi `20.suspend.essential-api-allowed = true`), `scheduledAt` (tùy chọn); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm trạng thái (ERR-20-006), tenant đặc biệt (ERR-20-010), lý do và văn bản (ERR-20-008, ERR-20-004).
2. Hệ thống tạo đề nghị `SUSPEND` ở `APPROVED` (không cần duyệt), thực hiện ngay hoặc theo `scheduledAt`.
3. Khi thực hiện: tenant `SUSPENDED`, ghi lịch sử; gọi API-12-084 (realm chỉ cho đăng nhập để xem, chặn token máy); phát EVT-20-04; registry vô hiệu đệm.
4. PH-03 nghe EVT-20-04 và trả ERR-20-001 ở APISIX cho mọi API của tỉnh, trừ danh sách API thiết yếu khi được cho phép; PH-04 dừng luồng theo lịch; PH-10 chặn sản xuất sự kiện từ HTTT.
5. Hệ thống gửi thông báo qua FR-20-044.

**Luồng thay thế.** `SECURITY_INCIDENT`: không cần văn bản; hệ thống tự mở việc ở PH-18 yêu cầu bổ sung văn bản trong 3 ngày làm việc.

**Luồng ngoại lệ.**

- Trạng thái không phù hợp: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Thiếu lý do, phiếu: ERR-20-008 (422); "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu."
- Thiếu văn bản căn cứ: ERR-20-004 (400).
- PH-12 không khóa được realm (runtime): đề nghị về `APPROVED` (thực hiện lỗi), ERR-20-107 hiện ở UI-20-08; data plane vẫn chặn nhờ EVT-20-04 tới PH-03.

**Đầu ra.** `202`; `requestId`, tenant `SUSPENDED` khi xong.

**Kết quả.** Mọi lượt gọi vào tỉnh nhận "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh." trong ≤ 60 giây (NFR-20-004).

**Hậu điều kiện.** Tenant `SUSPENDED`; EN-20-22 `DONE`.

**Sự kiện phát ra.** EVT-20-04.

**Kiểm toán.** Có: lý do, văn bản, phiếu, thời điểm, kết quả từng phân hệ.

**Quy tắc nghiệp vụ.** BR-20-009, BR-20-021.

**Màn hình, API.** UI-20-08; API-20-071, API-20-079; API-12-084 (PH-12).
:::

#### FR-20-039 · Khôi phục tenant

::: dac-ta
**Mục đích.** Đưa tỉnh tạm ngừng trở lại hoạt động khi lý do tạm ngừng đã được xử lý.

**Tác nhân, quyền.** PA (`PERM-20-lifecycle`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.1; API-12-085.

**Tiền điều kiện.** Tenant `SUSPENDED`; không có đề nghị `TERMINATE` ở `APPROVED`.

**Kích hoạt.** UI-20-08 "Khôi phục".

**Đầu vào.** `reasonText`, `ticketRef`, `decisionDocNo` (khi tạm ngừng có văn bản); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm trạng thái (ERR-20-006) và đề nghị chấm dứt đang chờ (ERR-20-037 với {lý do} = đang có đề nghị chấm dứt).
2. Hệ thống chạy kiểm tra khói rút gọn (ca `LOGIN_ADMIN`, `API_SAMPLE`) sau khi gọi API-12-085.
3. Đạt: tenant `ACTIVE`, phát EVT-20-04, vô hiệu đệm; thông báo FR-20-044.

**Luồng thay thế.** Tạm ngừng do hết hợp đồng: hệ thống cảnh báo nếu chưa có hợp đồng hiệu lực mới (không chặn).

**Luồng ngoại lệ.**

- Trạng thái không phù hợp: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Đang có đề nghị chấm dứt đã duyệt: ERR-20-037 (422); "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."
- Kiểm tra khói rút gọn lỗi (runtime): ERR-20-117 "Ca kiểm tra khói {ca} lỗi: {chi tiết}."; tenant giữ `SUSPENDED`.

**Đầu ra.** `202`; `requestId`.

**Kết quả.** Tỉnh phục vụ lại bình thường.

**Hậu điều kiện.** Tenant `ACTIVE`.

**Sự kiện phát ra.** EVT-20-04.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-009, BR-20-019.

**Màn hình, API.** UI-20-08; API-20-071, API-20-079; API-12-085 (PH-12).
:::

#### FR-20-040 · Đề nghị và duyệt chấm dứt tenant

::: dac-ta
**Mục đích.** Bảo đảm việc chấm dứt một tỉnh, không đảo ngược được, có căn cứ văn bản, có hai người duyệt và có lịch thực hiện rõ.

**Tác nhân, quyền.** PA lập, gửi (`PERM-20-lifecycle`); PA khác duyệt (`PERM-20-approve`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; FR-00-071; ADR-046; CMP-LAW-05; Q20-02, Q20-03.

**Tiền điều kiện.** Tenant `SUSPENDED` (BR-20-019).

**Kích hoạt.** UI-20-08 "Đề nghị chấm dứt"; hộp duyệt UI-20-08 tab "Chờ duyệt".

**Đầu vào.** `reasonText`, `ticketRef`, `decisionDocNo`, `decisionDocDate`, `decisionFileId`, `plannedAt` (≥ ngày tạm ngừng + `20.terminate.cooling-days`), `exportRequired` (mặc định `true`); `Idempotency-Key`; khi duyệt: `comment`, `If-Match`.

**Luồng xử lý chính.**

1. PA lập đề nghị `TERMINATE` `DRAFT`; hệ thống kiểm tenant `SUSPENDED` (ERR-20-037), văn bản đủ (ERR-20-004).
2. PA gửi; đề nghị `PENDING_APPROVAL`, việc duyệt vào hộp việc của các PA khác.
3. PA khác mở đề nghị, thấy tóm tắt dữ liệu sẽ mất (số HTTT, API, người dùng, dung lượng), trạng thái gói bàn giao, ngày sớm nhất được thực hiện; bấm "Duyệt" (ERR-20-007 nếu là người lập hoặc gửi).
4. Đề nghị `APPROVED`; hệ thống tự yêu cầu gói bàn giao (FR-20-041) nếu chưa có, báo đầu mối tỉnh.

**Luồng thay thế.** Từ chối: `REJECTED` kèm ý kiến. Người gửi rút khi chưa duyệt: về `DRAFT`. Tỉnh văn bản từ chối nhận dữ liệu: `exportRequired = false` cần tệp văn bản đính kèm.

**Luồng ngoại lệ.**

- Tenant chưa tạm ngừng: ERR-20-037 (422); "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."
- Tự duyệt: ERR-20-007 (403); "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."
- Ngày dự kiến trước thời gian nguội: ERR-20-038 (422).
- Đã có đề nghị chấm dứt khác chưa kết thúc: ERR-20-006 (409).

**Đầu ra.** `201` đề nghị; `200` khi gửi, duyệt, từ chối, rút.

**Kết quả.** Đề nghị chấm dứt có đủ chữ ký số người, văn bản, lịch, sẵn sàng để thực hiện khi đủ điều kiện.

**Hậu điều kiện.** EN-20-22 `APPROVED` hoặc `REJECTED`.

**Sự kiện phát ra.** Không (EVT-20-04 chỉ khi thực hiện).

**Kiểm toán.** Có: mọi bước, người, văn bản, ý kiến.

**Quy tắc nghiệp vụ.** BR-20-008, BR-20-019.

**Màn hình, API.** UI-20-08; API-20-071, API-20-073, API-20-074, API-20-075, API-20-076, API-20-077, API-20-078.
:::

```{.mermaid caption="Trình tự đề nghị, duyệt bốn mắt và thực hiện chấm dứt tenant"}
sequenceDiagram
  actor PA1 as PA lập
  actor PA2 as PA duyệt
  participant P20 as PH-20
  participant PX as Phân hệ có dữ liệu
  participant P09 as PH-09
  participant P12 as PH-12
  participant P13 as PH-13
  PA1->>P20: Đề nghị TERMINATE (tenant SUSPENDED)
  PA2->>P20: Duyệt (khác người lập)
  P20->>PX: Yêu cầu xuất gói bàn giao
  PX-->>P20: Báo phần xuất API-20-168
  P20-->>PA1: Gói READY, cấp liên kết cho tỉnh
  PA1->>P20: Xác nhận DELIVERED kèm biên bản
  Note over P20: Chờ hết thời gian nguội
  P20->>P12: Xóa realm
  P20->>P13: Đóng chuỗi kiểm toán API-13-073
  P20->>P09: Xóa mật mã (FR-09-043)
  P09-->>P20: EVT-09-21 crypto-shred completed
  P20->>P20: Tenant DECOMMISSIONED, EVT-20-04
```

Hình cho thấy ba chốt chặn trước khi dữ liệu mất vĩnh viễn: duyệt của người thứ hai, biên bản bàn giao, thời gian nguội. Xóa mật mã là bước cuối và chỉ được ghi nhận khi PH-09 phát EVT-09-21.

#### FR-20-041 · Xuất gói bàn giao dữ liệu tenant

::: dac-ta
**Mục đích.** Trả lại cho tỉnh toàn bộ dữ liệu của tỉnh dưới dạng gói có bản kê, băm và chữ ký trước khi chấm dứt, đáp ứng nghĩa vụ bàn giao và quyền của chủ thể dữ liệu.

**Tác nhân, quyền.** PA (`PERM-20-lifecycle`); phân hệ có dữ liệu báo phần xuất qua API-20-168 (`tenant:provision-report`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; CMP-LAW-05; CMP-LAW-16; Q20-02.

**Tiền điều kiện.** Tenant `SUSPENDED` hoặc `MERGED`; đề nghị `TERMINATE` `APPROVED` hoặc PA yêu cầu chủ động.

**Kích hoạt.** UI-20-08 "Xuất gói bàn giao"; tự động sau FR-20-040 bước 4.

**Đầu vào.** `modules[]` (mặc định mọi phân hệ `exportParticipant`), `format` (`JSONL`, `CSV` kèm lược đồ), `includeAudit` (mặc định `true`); `Idempotency-Key`; khi cấp liên kết: `recipientEmail` (đầu mối tỉnh), `expiresHours` (≤ 72); khi xác nhận: `handoverDocFileId`, `deliveredAt`.

**Luồng xử lý chính.**

1. Hệ thống tạo gói `REQUESTED`, phát lệnh xuất (sự kiện nội bộ) tới từng phân hệ tham gia; gói `COLLECTING`.
2. Mỗi phân hệ ghi phần của mình vào bucket `dh-{ma}-exports` dưới `packages/{packageId}/{module}/`, báo số bản ghi, kích thước, SHA-256 qua API-20-168.
3. Đủ báo: hệ thống dựng bản kê `manifest.json` (phân hệ, tệp, băm, số bản ghi), ký bằng khóa nền tảng, gói `READY`, phát EVT-20-16.
4. PA cấp liên kết tải có hạn tới đầu mối tỉnh; tải xong, PA tải biên bản bàn giao lên và xác nhận: `DELIVERED` (ERR-20-007 nếu người xác nhận là người duyệt chấm dứt).
5. Gói tự `EXPIRED` sau `20.export.retention-days`.

**Luồng thay thế.** Phân hệ chưa bật cho tenant: không tham gia, ghi trong bản kê "không có dữ liệu".

**Luồng ngoại lệ.**

- Liên kết sau khi gói hết hạn: ERR-20-039 (410); "Gói bàn giao {mã} đã hết hạn lưu. Lập gói mới."
- Phân hệ báo lỗi hoặc quá 24 giờ (runtime): ERR-20-107, gói `FAILED` phần đó, PA chạy lại phần lỗi.
- Gói chưa `READY` khi cấp liên kết, xác nhận: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Người xác nhận là người duyệt chấm dứt: ERR-20-007 (403).

**Đầu ra.** `202` khi yêu cầu; `200` chi tiết gói (`status`, `items[]` theo phân hệ, `manifestSha256`, `downloadUrl` khi cấp).

**Kết quả.** Tỉnh nhận đủ dữ liệu có bản kê ký, kiểm chứng được ngoài hệ thống.

**Hậu điều kiện.** EN-20-24 `DELIVERED`.

**Sự kiện phát ra.** EVT-20-16.

**Kiểm toán.** Có: yêu cầu, từng phần, người tải, biên bản.

**Quy tắc nghiệp vụ.** BR-20-008, BR-20-019, BR-20-020.

**Màn hình, API.** UI-20-08; API-20-080, API-20-081, API-20-082, API-20-083, API-20-084, API-20-168.
:::

#### FR-20-042 · Thực hiện chấm dứt tenant

::: dac-ta
**Mục đích.** Gỡ tenant khỏi nền tảng sau khi đủ điều kiện: xóa realm, đóng chuỗi kiểm toán, gỡ tài nguyên ở mọi phân hệ và xóa mật mã để dữ liệu còn sót không đọc được.

**Tác nhân, quyền.** PA (`PERM-20-lifecycle`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; SEC-88; FR-09-043; API-13-073; CMP-LAW-05.

**Tiền điều kiện.** Đề nghị `TERMINATE` `APPROVED`; gói bàn giao `DELIVERED` hoặc `exportRequired = false` có văn bản; đã hết thời gian nguội; tenant `SUSPENDED`.

**Kích hoạt.** UI-20-08 "Thực hiện chấm dứt" (gõ lại mã tenant); hoặc tự động tại `plannedAt`.

**Đầu vào.** `requestId`, `confirmTenantCode`; `Idempotency-Key`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm đủ ba điều kiện (ERR-20-037, ERR-20-038).
2. Hệ thống phát EVT-20-04 `DECOMMISSIONED` (phân hệ nghe để gỡ tài nguyên và xóa dữ liệu theo chính sách của mình), gọi PH-12 xóa realm, API-13-073 đóng chuỗi kiểm toán (chuỗi WORM giữ theo thời hạn quy định).
3. Hệ thống gỡ bucket, đường dẫn OpenBao, thư mục Git (commit xóa có ký, lịch sử Git giữ).
4. Hệ thống gọi FR-09-043 xóa mật mã KEK `dh-{ma}-pii`; chờ EVT-09-21.
5. Nhận EVT-09-21: tenant `DECOMMISSIONED`, đề nghị `DONE`, ghi lịch sử.

**Luồng thay thế.** Một phân hệ chưa báo gỡ xong sau 24 giờ: hệ thống vẫn chuyển `DECOMMISSIONED` (data plane đã trả ERR-20-102) và mở việc dọn ở PH-18 cho phân hệ đó.

**Luồng ngoại lệ.**

- Chưa đủ điều kiện: ERR-20-037 (422); "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."
- Chưa hết thời gian nguội: ERR-20-038 (422); "Chưa hết thời gian chờ {số} ngày kể từ khi tạm ngừng (đến {ngày})."
- Sai mã xác nhận: ERR-20-004 (400).
- Không nhận EVT-09-21 sau 24 giờ (runtime): ERR-20-116 "Chưa nhận xác nhận xóa mật mã của {tenant}."; cảnh báo SO nền tảng, tenant giữ `SUSPENDED`.

**Đầu ra.** `202`; `requestId`, tiến độ theo bước.

**Kết quả.** Tỉnh biến khỏi nền tảng; mã tenant không bao giờ được dùng lại.

**Hậu điều kiện.** Tenant `DECOMMISSIONED`.

**Sự kiện phát ra.** EVT-20-04.

**Kiểm toán.** Có: từng bước, xác nhận PH-09, người thực hiện.

**Quy tắc nghiệp vụ.** BR-20-001, BR-20-019, BR-20-020.

**Màn hình, API.** UI-20-08; API-20-079; FR-09-043 (PH-09).
:::

#### FR-20-043 · Lịch sử vòng đời và quyết định

::: dac-ta
**Mục đích.** Cho thấy toàn bộ trạng thái mà tenant đã đi qua, vì sao, ai quyết định, theo văn bản nào, làm hồ sơ cho kiểm toán và thanh tra.

**Tác nhân, quyền.** PA, PO, PAU (`PERM-20-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; SEC-85; ADR-031.

**Tiền điều kiện.** Tenant tồn tại.

**Kích hoạt.** UI-20-03 tab "Lịch sử vòng đời".

**Đầu vào.** `tenantCode`, `from`, `to`, `type[]`.

**Luồng xử lý chính.**

1. Hệ thống đọc EN-20-23 (chỉ thêm, không sửa) và EN-20-22, ghép lần chạy saga, kế hoạch sáp nhập liên quan.
2. Hệ thống trả dòng thời gian (`CMP-Timeline`): trạng thái trước, sau, thời điểm, nguyên nhân, người, văn bản, đề nghị.
3. Mỗi dòng có liên kết tới đề nghị hoặc lần chạy chi tiết.

**Luồng thay thế.** Xuất PDF lịch sử kèm danh sách văn bản (dùng cơ chế báo cáo của FR-20-031).

**Luồng ngoại lệ.**

- Không có tenant: ERR-20-002 (404); "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- Tham số sai: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."

**Đầu ra.** `200`; `items[]` (`from`, `to`, `at`, `cause` {`type`, `id`}, `actor`, `decisionDocNo`).

**Kết quả.** Người kiểm toán đọc được lịch sử tenant trên một màn.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-009.

**Màn hình, API.** UI-20-03; API-20-072, API-20-074, API-20-085.
:::

#### FR-20-044 · Thông báo thay đổi trạng thái tenant

::: dac-ta
**Mục đích.** Báo kịp thời cho đầu mối tỉnh, người dùng tỉnh và vận hành nền tảng mỗi khi tenant đổi trạng thái, để không ai bất ngờ vì bị chặn truy cập.

**Tác nhân, quyền.** Hệ thống; PH-18 gửi thư, thông báo trong ứng dụng.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; SEC-85; D02-07 DD-13.

**Tiền điều kiện.** Có đầu mối đang hoạt động.

**Kích hoạt.** Ghi EN-20-23 mới (mọi chuyển trạng thái); hẹn giờ tạm ngừng, chấm dứt, cutover còn 7 ngày và 1 ngày.

**Đầu vào.** Bản ghi lịch sử; mẫu thư `ph20-status-{trạng thái}`.

**Luồng xử lý chính.**

1. Hệ thống chọn người nhận theo trạng thái: đầu mối `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY` (tạm ngừng, chấm dứt, sáp nhập); người dùng tỉnh (thông báo trong ứng dụng khi `SUSPENDED`, `MERGING`); PO (mọi chuyển).
2. Hệ thống gọi `NotificationApi` của PH-18 với mẫu, biến (tenant, trạng thái, lý do rút gọn, hạn, liên hệ hỗ trợ), `Idempotency-Key = {historyId}:{kênh}`.
3. Hệ thống ghi kết quả gửi vào bản ghi lịch sử.

**Luồng thay thế.** Lý do `SECURITY_INCIDENT`: thư chỉ nêu "sự cố an toàn thông tin", không nêu chi tiết.

**Luồng ngoại lệ.**

- PH-18 không khả dụng: ERR-20-062 (503); "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." Thử lại 6 lần trong 1 giờ rồi cảnh báo PO ở UI-20-20.
- Không còn đầu mối hoạt động: ERR-20-021 (422); "Cần đủ đầu mối {vai trò} trước khi {thao tác}." Cảnh báo PO.

**Đầu ra.** Nội bộ; trạng thái gửi ở API-20-085.

**Kết quả.** Đầu mối tỉnh nhận thư trong ≤ 5 phút sau khi trạng thái đổi.

**Hậu điều kiện.** Lịch sử có kết quả gửi.

**Sự kiện phát ra.** Không (EVT-20-04 do FR gây đổi trạng thái phát).

**Kiểm toán.** Không riêng (gộp vào bản ghi lịch sử).

**Quy tắc nghiệp vụ.** BR-20-039.

**Màn hình, API.** Không có màn riêng; API-20-085.
:::

### 6.8. Nhóm G · Sáp nhập

Nhóm G hiện thực D03-10 §5.4: một hoặc nhiều tenant nguồn sáp nhập vào một tenant đích. PH-20 chỉ điều phối theo hợp đồng bên tham gia sáp nhập (ADR 202 đề xuất); PH-18 chạy chuyển dữ liệu từng phân hệ (FR-20-048). Dữ liệu chuyển giữ `id` gốc và ghi `origin_tenant_id`.

#### FR-20-045 · Lập kế hoạch sáp nhập

::: dac-ta
**Mục đích.** Ghi nhận quyết định sáp nhập tỉnh thành một kế hoạch có căn cứ văn bản, tenant nguồn, tenant đích, ngày hiệu lực, thời gian chuyển tiếp, được hai PA duyệt trước khi bất kỳ dữ liệu nào di chuyển.

**Tác nhân, quyền.** PA lập (`PERM-20-merge`); PA khác duyệt (`PERM-20-approve`); TA của các tỉnh liên quan xem phần tỉnh mình.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.4; FR-00-071; Q20-01.

**Tiền điều kiện.** Tenant nguồn và đích `ACTIVE`, không thuộc kế hoạch khác chưa kết thúc; tenant đích có thể vừa khởi tạo (FR-20-008).

**Kích hoạt.** UI-20-11 "+ Kế hoạch sáp nhập", wizard UI-20-09 (nguồn đích, căn cứ, ánh xạ, chạy thử, gửi duyệt); PA khác duyệt ở UI-20-09.

**Đầu vào.** `sourceTenants[]`, `targetTenant`, `decisionDocNo`, `decisionDocDate`, `decisionFileId`, `effectiveDate`, `transitionMonths` (mặc định `20.merge.transition-months`), `modules[]` (mặc định mọi phân hệ `mergeParticipant` đang bật ở nguồn); `Idempotency-Key`; `If-Match` khi sửa, gửi, duyệt.

**Luồng xử lý chính.**

1. PA nhập nguồn, đích; hệ thống kiểm nguồn ≠ đích, đều `ACTIVE`, đều `PROVINCE` (ERR-20-040), không thuộc kế hoạch khác (ERR-20-041), `transitionMonths` ≤ `20.merge.transition-max-months` (ERR-20-045).
2. Hệ thống tạo kế hoạch `DRAFT` mã `MG-{yyyy}-{nnn}`, kiểm phân hệ bật ở nguồn cũng bật ở đích (thiếu: cảnh báo, gợi ý FR-20-034).
3. PA lập ánh xạ (FR-20-046), chạy thử (FR-20-047), rồi bấm "Gửi duyệt"; hệ thống kiểm có chạy thử đạt và còn hợp lệ (ERR-20-043), kế hoạch `PENDING_APPROVAL`.
4. PA khác duyệt (ERR-20-007 nếu là người lập, gửi); kế hoạch `APPROVED`, báo TA hai tỉnh.

**Luồng thay thế.** Hủy trước `CUTOVER`: kế hoạch `CANCELLED`; nếu đã `TRANSFERRING`, dữ liệu đã chuyển sang đích được PH-18 gỡ theo `origin_tenant_id`, nguồn về `ACTIVE`.

**Luồng ngoại lệ.**

- Kế hoạch không hợp lệ: ERR-20-040 (422); "Kế hoạch sáp nhập không hợp lệ: {lý do}."
- Tenant thuộc kế hoạch khác: ERR-20-041 (409); "Tenant {mã} đang thuộc kế hoạch sáp nhập {kế hoạch}."
- Chuyển tiếp quá dài: ERR-20-045 (422).
- Chưa có chạy thử hợp lệ khi gửi: ERR-20-043 (422).
- Tự duyệt: ERR-20-007 (403).

**Đầu ra.** `201`; kế hoạch (`mergePlanId`, `status`, `ETag`); `200` cho các hành động.

**Kết quả.** Có kế hoạch sáp nhập được duyệt, sẵn sàng chuyển dữ liệu.

**Hậu điều kiện.** EN-20-25 `APPROVED`.

**Sự kiện phát ra.** Không (EVT-20-10 phát khi bắt đầu chuyển).

**Kiểm toán.** Có: kế hoạch, văn bản, người lập, gửi, duyệt; ghi vào chuỗi của mọi tenant liên quan.

**Quy tắc nghiệp vụ.** BR-20-008, BR-20-022, BR-20-025.

**Màn hình, API.** UI-20-09, UI-20-11; API-20-086, API-20-087, API-20-088, API-20-089, API-20-090, API-20-091, API-20-092, API-20-093.
:::

#### FR-20-046 · Lập bảng ánh xạ sáp nhập

::: dac-ta
**Mục đích.** Xác định trước mỗi tổ chức, HTTT, mã danh mục địa phương, tiền tố API, người dùng, topic của tỉnh nguồn sẽ thành gì ở tỉnh đích, để chuyển dữ liệu không đoán.

**Tác nhân, quyền.** PA (`PERM-20-merge`); TA của tỉnh đích góp ý qua phiếu (không sửa trực tiếp).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D03-10 §5.4 bước 1.

**Tiền điều kiện.** Kế hoạch `DRAFT`.

**Kích hoạt.** Bước "Ánh xạ" của UI-20-09: "Gợi ý tự động", sửa từng dòng.

**Đầu vào.** Khi sửa: `mappingId`, `targetCode`, `action` (`MAP`, `CREATE`, `SKIP`); `If-Match`.

**Luồng xử lý chính.**

1. PA bấm "Gợi ý tự động"; hệ thống gọi từng phân hệ tham gia để liệt kê đối tượng nguồn theo `MergeMappingType` và đề xuất: trùng mã và tên ở đích thì `MAP`, không có thì `CREATE` với mã giữ nguyên hoặc thêm hậu tố `-{mã nguồn}` khi trùng mã khác nghĩa.
2. PA sửa từng dòng; hệ thống kiểm `targetCode` tồn tại ở đích khi `MAP` (ERR-20-002) và không hai nguồn cùng `CREATE` ra một mã (ERR-20-003).
3. Hệ thống đánh dấu dòng bắt buộc (tổ chức, HTTT, tiền tố API) chưa quyết; còn dòng bắt buộc chưa quyết thì không chạy thử được (ERR-20-042).

**Luồng thay thế.** `API_CONTEXT_PATH`: ánh xạ này là nguồn bảng chuyển tiếp mà PH-03 đọc ở cutover (FR-20-051).

**Luồng ngoại lệ.**

- Còn dòng bắt buộc chưa quyết: ERR-20-042 (422); "Bảng ánh xạ còn {số} dòng bắt buộc chưa quyết định."
- Mã đích trùng: ERR-20-003 (409); "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- Phân hệ tham gia không trả danh sách: ERR-20-062 (503).

**Đầu ra.** `200`; `items[]` (`mappingId`, `mappingType`, `sourceCode`, `targetCode`, `action`, `origin`, `required`), `summary` theo loại.

**Kết quả.** Bảng ánh xạ đủ, mọi dòng bắt buộc có quyết định.

**Hậu điều kiện.** EN-20-26 cập nhật; chạy thử cũ bị đánh dấu cũ khi ánh xạ đổi.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: sửa từng dòng.

**Quy tắc nghiệp vụ.** BR-20-023, BR-20-024.

**Màn hình, API.** UI-20-09; API-20-094, API-20-095, API-20-096.
:::

#### FR-20-047 · Chạy thử sáp nhập

::: dac-ta
**Mục đích.** Biết trước sẽ chuyển bao nhiêu bản ghi, bao nhiêu xung đột, mất bao lâu, mà không ghi gì vào tenant đích.

**Tác nhân, quyền.** PA (`PERM-20-merge`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D03-10 §5.4; ADR 202.

**Tiền điều kiện.** Kế hoạch `DRAFT`; không còn dòng ánh xạ bắt buộc chưa quyết.

**Kích hoạt.** UI-20-09 bước "Chạy thử", UI-20-10 "Chạy thử lại".

**Đầu vào.** `mergePlanId`; `modules[]` (mặc định tất cả); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm ánh xạ đủ (ERR-20-042); kế hoạch `DRY_RUN`.
2. Hệ thống gọi PH-18 `merge-transfers` với `dryRun = true` cho từng phân hệ; PH-18 gọi xuất của phân hệ nguồn và kiểm nhập của phân hệ đích trên bản sao không ghi.
3. PH-18 báo qua API-20-167 số bản ghi, số xung đột dự kiến theo loại, thời gian ước tính; hệ thống ghi EN-20-27 `phase = DRY_RUN`, EN-20-28 dự kiến.
4. Đủ báo: kế hoạch về `DRAFT`, `dryRunResult = PASSED` khi không phân hệ nào lỗi, ghi `mappingHash` để phát hiện chạy thử cũ.

**Luồng thay thế.** Có xung đột dự kiến vẫn `PASSED` (xung đột được xử lý ở FR-20-049); chỉ lỗi kỹ thuật làm `FAILED`.

**Luồng ngoại lệ.**

- Ánh xạ chưa đủ: ERR-20-042 (422); "Bảng ánh xạ còn {số} dòng bắt buộc chưa quyết định."
- Đang chạy thử: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Phân hệ lỗi khi chạy thử (runtime): ERR-20-113 "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}." hoặc ERR-20-107; `dryRunResult = FAILED`.

**Đầu ra.** `202`; kết quả trong API-20-088 (`dryRun` {`result`, `modules[]` {`module`, `records`, `conflicts`, `estimatedMinutes`}, `mappingHash`}).

**Kết quả.** PA có con số để báo lãnh đạo và lên lịch cửa sổ chuyển.

**Hậu điều kiện.** Không có dữ liệu ghi vào tenant đích.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: lần chạy thử, kết quả.

**Quy tắc nghiệp vụ.** BR-20-024.

**Màn hình, API.** UI-20-09, UI-20-10; API-20-097, API-20-167.
:::

#### FR-20-048 · Điều phối chuyển dữ liệu theo phân hệ

::: dac-ta
**Mục đích.** Chuyển dữ liệu của tỉnh nguồn sang tỉnh đích phân hệ một, đúng thứ tự phụ thuộc, có kiểm đếm, trong khi tỉnh nguồn vẫn phục vụ.

**Tác nhân, quyền.** PA (`PERM-20-merge`); PH-18 và phân hệ tham gia báo qua API-20-167 (`tenant:provision-report`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-10 §5.4 bước 2; ADR 202; NFR-20-014.

**Tiền điều kiện.** Kế hoạch `APPROVED`; đã tới `effectiveDate` hoặc PA chọn chạy sớm có lý do.

**Kích hoạt.** UI-20-10 "Bắt đầu chuyển".

**Đầu vào.** `mergePlanId`; `reason`, `ticketRef`; `Idempotency-Key`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm kế hoạch `APPROVED` (ERR-20-006), chạy thử còn hợp lệ (ERR-20-043).
2. Hệ thống chuyển tenant nguồn `MERGING`, kế hoạch `TRANSFERRING`, phát EVT-20-10 và EVT-20-04.
3. Hệ thống gọi `merge-transfers` cho từng phân hệ theo thứ tự phụ thuộc: PH-20 (tổ chức) → PH-07 → PH-01 → PH-02 → PH-10 → PH-04, PH-05 → PH-03 → các phân hệ khác; phân hệ không phụ thuộc nhau chạy song song.
4. Mỗi báo tiến độ cập nhật EN-20-27; khi phân hệ báo `SUCCEEDED`, hệ thống so số bản ghi nguồn và đích (trừ `SKIP`); lệch thì phân hệ `FAILED` (ERR-20-113).
5. Có xung đột: kế hoạch `CONFLICT_REVIEW` (FR-20-049); mọi phân hệ `SUCCEEDED`: kế hoạch sang `IDENTITY_TRANSFER` (FR-20-050).

**Luồng thay thế.** Dữ liệu phát sinh ở nguồn trong lúc chuyển: mỗi phân hệ chạy lượt bù (delta) cuối cùng ngay trước cutover theo dấu thời gian `updated_at` (FR-20-051 bước 2). Phân hệ lỗi: PA bấm "Chạy lại phân hệ" (API-20-100), lũy đẳng theo `{mergePlanId}:{module}:transfer`.

**Luồng ngoại lệ.**

- Chạy thử cũ: ERR-20-043 (422); "Chạy thử sáp nhập chưa đạt hoặc đã cũ so với bảng ánh xạ hiện hành."
- Trạng thái không phù hợp: ERR-20-006 (409); "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- Báo tiến độ sai trạng thái (bên gọi máy): ERR-20-114 (409).
- Kiểm đếm lệch (runtime): ERR-20-113 "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}."

**Đầu ra.** `202`; kế hoạch `TRANSFERRING`; API-20-099 trả tiến độ theo phân hệ.

**Kết quả.** UI-20-10 hiện thanh tiến độ từng phân hệ, số bản ghi, xung đột.

**Hậu điều kiện.** Dữ liệu ở đích có `origin_tenant_id`; nguồn vẫn đầy đủ.

**Sự kiện phát ra.** EVT-20-10; EVT-20-04 (`MERGING`).

**Kiểm toán.** Có: từng phân hệ, số bản ghi, kiểm đếm, người chạy lại.

**Quy tắc nghiệp vụ.** BR-20-022, BR-20-023.

**Màn hình, API.** UI-20-10; API-20-088, API-20-098, API-20-099, API-20-100, API-20-167.
:::

```{.mermaid caption="Trình tự điều phối chuyển dữ liệu sáp nhập T01 vào T68"}
sequenceDiagram
  actor PA as Quản trị nền tảng
  actor PA2 as Quản trị nền tảng thứ hai
  participant P20 as PH-20
  participant K as Kafka
  participant P18 as PH-18 merge-transfers
  participant SRC as Phân hệ ở T01
  participant DST as Phân hệ ở T68
  PA->>P20: Gửi duyệt kế hoạch MG-2026-001
  PA2->>P20: Duyệt (bốn mắt, khác người lập)
  PA->>P20: Bắt đầu chuyển
  P20->>K: EVT-20-10 merge-started, EVT-20-04 T01 MERGING
  loop Theo thứ tự phụ thuộc
    P20->>P18: POST /api/ops/v1/merge-transfers (module)
    P18->>SRC: Xuất gói theo mappingRef
    P18->>DST: Nhập, giữ id gốc, ghi origin_tenant_id
    P18-->>P20: API-20-167 báo tiến độ, số bản ghi, xung đột
  end
  P20->>P20: Kiểm đếm, chuyển IDENTITY_TRANSFER
```

Hình cho thấy việc chuyển chỉ bắt đầu sau khi người thứ hai duyệt, và PH-20 không tự đọc ghi dữ liệu của phân hệ khác: nó gọi PH-18 cho từng phân hệ và chỉ nhận báo cáo kiểm đếm. Tenant nguồn vẫn phục vụ suốt vòng lặp.

#### FR-20-049 · Xử lý xung đột sáp nhập

::: dac-ta
**Mục đích.** Cho cán bộ quyết định từng trường hợp hai tỉnh có cùng mã khác nghĩa (danh mục địa phương, mã HTTT, tên tổ chức trùng), thay vì để công cụ ghi đè.

**Tác nhân, quyền.** PA (`PERM-20-merge`); TA tỉnh đích góp ý qua phiếu.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D03-10 §5.4 ("danh mục địa phương trùng mã được đánh dấu xung đột để cán bộ nghiệp vụ xử lý").

**Tiền điều kiện.** Kế hoạch `CONFLICT_REVIEW` hoặc `TRANSFERRING` có xung đột mở.

**Kích hoạt.** UI-20-10 tab "Xung đột": chọn cách xử lý từng dòng hoặc hàng loạt.

**Đầu vào.** `conflictId` hoặc `conflictIds[]`; `resolution` (`KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP`); `newCode` (khi `RENAME_SOURCE`); `comment`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống hiện xung đột kèm hai bản (nguồn, đích) cạnh nhau bằng `CMP-DiffViewer`.
2. PA chọn cách; hệ thống kiểm cách hợp lệ với loại đối tượng (ví dụ `MERGE_ITEMS` chỉ cho danh mục) và `newCode` chưa dùng (ERR-20-004, ERR-20-003).
3. Hệ thống lưu quyết định, gửi lệnh tiếp tục cho phân hệ qua PH-18 cho phần dính xung đột.
4. Hết xung đột mở: kế hoạch về `TRANSFERRING`.

**Luồng thay thế.** Hàng loạt: áp một cách cho tối đa 500 xung đột cùng loại.

**Luồng ngoại lệ.**

- Cách xử lý không hợp lệ: ERR-20-004 (400); "{Trường} chưa hợp lệ: {yêu cầu}."
- Mã mới trùng: ERR-20-003 (409); "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- Chuyển định danh, cutover khi còn xung đột: ERR-20-044 (409).

**Đầu ra.** `200`; xung đột đã quyết; tổng số còn mở.

**Kết quả.** Không bản ghi nào bị ghi đè ngoài ý muốn.

**Hậu điều kiện.** EN-20-28 có `resolution`.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có: từng quyết định, người, ý kiến.

**Quy tắc nghiệp vụ.** BR-20-023, BR-20-024.

**Màn hình, API.** UI-20-10; API-20-101, API-20-102, API-20-103.
:::

#### FR-20-050 · Chuyển định danh và cấp song song thông tin xác thực HTTT

::: dac-ta
**Mục đích.** Tạo lại người dùng tỉnh nguồn ở realm tỉnh đích và cấp cho mỗi HTTT của tỉnh nguồn thông tin xác thực mới ở tỉnh đích, trong khi thông tin cũ vẫn dùng được tới hết chuyển tiếp.

**Tác nhân, quyền.** PA (`PERM-20-merge`); PH-20 gọi PH-12 với `iam:realm-provision`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D03-10 §5.4 bước 3; API-12-045, API-12-046; Q01-10; Q20-13.

**Tiền điều kiện.** Kế hoạch `IDENTITY_TRANSFER`; không còn xung đột mở.

**Kích hoạt.** UI-20-10 "Chuyển định danh".

**Đầu vào.** `mergePlanId`; `notifyUsers` (mặc định `true`); `Idempotency-Key`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm xung đột (ERR-20-044), gọi API-12-045 lập kế hoạch định danh theo ánh xạ `USER`, nhận số người dùng tạo mới, gộp, bỏ qua.
2. Hệ thống gọi API-12-046 thực hiện; PH-12 tạo người dùng ở realm đích (giữ liên kết LDAP nếu có, buộc đặt lại mật khẩu theo Q20-13), cấp client mới cho HTTT với hạn bằng `transitionEndsAt`.
3. Hệ thống ghi danh sách HTTT và trạng thái thông tin xác thực song song (`ISSUED`, `IN_USE_NEW`, `OLD_ONLY`).
4. Hệ thống gửi thư hướng dẫn chuyển cho đầu mối kỹ thuật từng HTTT qua PH-18; kế hoạch sang `CUTOVER` sẵn sàng.

**Luồng thay thế.** PH-01 nhận EVT-20-13 cho tổ chức kế thừa và tự tạo đề nghị đổi chủ quản HTTT chờ TA đích duyệt hàng loạt (trả lời đề xuất Q01-10).

**Luồng ngoại lệ.**

- Còn xung đột: ERR-20-044 (409); "Còn {số} xung đột sáp nhập chưa xử lý."
- PH-12 lỗi: ERR-20-062 (503); "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."
- Trạng thái không phù hợp: ERR-20-006 (409).

**Đầu ra.** `202`; API-20-105 trả `items[]` (`memberSystemCode`, `newClientId`, `status`, `lastCallOld`, `lastCallNew`).

**Kết quả.** Người dùng đăng nhập được ở tỉnh đích; HTTT có thời gian chuyển dần.

**Hậu điều kiện.** Người dùng, client mới ở realm đích.

**Sự kiện phát ra.** Không (PH-12 phát EVT-12-13 khi realm đổi).

**Kiểm toán.** Có: số người dùng, client cấp mới (không ghi giá trị bí mật).

**Quy tắc nghiệp vụ.** BR-20-024, BR-20-025.

**Màn hình, API.** UI-20-10; API-20-104, API-20-105; API-12-045, API-12-046 (PH-12).
:::

#### FR-20-051 · Chuyển tiếp lượt gọi và chuyển tenant nguồn sang MERGED

::: dac-ta
**Mục đích.** Tại một thời điểm có kiểm soát, đưa tỉnh nguồn về chỉ đọc, bật chuyển tiếp mọi lượt gọi API sang tỉnh đích kèm header `Deprecation`, để HTTT cũ không gián đoạn.

**Tác nhân, quyền.** PA (`PERM-20-merge`); PH-03 đọc API-20-164 và thực thi (FR-03-037).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D03-10 §5.4 bước 4; FR-03-037; EVT-03-10; NFR-20-015.

**Tiền điều kiện.** Kế hoạch `IDENTITY_TRANSFER` xong; mọi phân hệ `SUCCEEDED`; không còn xung đột; trong cửa sổ bảo trì của cả hai tỉnh.

**Kích hoạt.** UI-20-10 "Thực hiện cutover" (gõ lại mã kế hoạch).

**Đầu vào.** `mergePlanId`, `confirmCode`, `reason`, `ticketRef`; `Idempotency-Key`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm điều kiện (ERR-20-044, ERR-20-006, ERR-20-059 khi ngoài cửa sổ).
2. Hệ thống đặt nguồn chỉ đọc, yêu cầu mỗi phân hệ chạy lượt bù cuối qua PH-18, chờ báo.
3. Hệ thống chuyển nguồn `MERGED`, `merged_into_id = đích`, kế hoạch `TRANSITION`, `transitionEndsAt = now + transitionMonths`; ghi bảng chuyển tiếp (ánh xạ `API_CONTEXT_PATH`) vào API-20-164.
4. Hệ thống phát EVT-20-11 và EVT-20-04; PH-03 bật chuyển tiếp và phát EVT-03-10; PH-12 khóa đăng nhập mới ở realm nguồn (chỉ đọc lịch sử); PH-01 chuyển HTTT sang trạng thái theo tỉnh đích.
5. Hệ thống theo dõi 60 phút đầu tỷ lệ lỗi lượt gọi chuyển tiếp; vượt 1% thì cảnh báo PA (không tự quay lui).

**Luồng thay thế.** Nhận EVT-03-10 xác nhận từ PH-03: ghi `redirectActiveAt`; không nhận sau 15 phút: cảnh báo PO.

**Luồng ngoại lệ.**

- Còn xung đột: ERR-20-044 (409); "Còn {số} xung đột sáp nhập chưa xử lý."
- Ngoài cửa sổ bảo trì: ERR-20-059 (422); "Cửa sổ bảo trì không hợp lệ: {lý do}."
- Lượt bù cuối lệch kiểm đếm (runtime): ERR-20-113; cutover dừng, nguồn bỏ chỉ đọc, kế hoạch giữ `IDENTITY_TRANSFER`.
- Ghi vào tenant `MERGED` sau cutover (data plane, control plane): ERR-20-115 (409).

**Đầu ra.** `202`; kế hoạch `TRANSITION`, `transitionEndsAt`.

**Kết quả.** HTTT cũ gọi địa chỉ cũ vẫn nhận phản hồi từ tỉnh đích, kèm header `Deprecation` và `Sunset` ngày kết thúc chuyển tiếp.

**Hậu điều kiện.** Nguồn `MERGED`.

**Sự kiện phát ra.** EVT-20-11; EVT-20-04.

**Kiểm toán.** Có: thời điểm, lượt bù, xác nhận PH-03.

**Quy tắc nghiệp vụ.** BR-20-024, BR-20-025, BR-20-026.

**Màn hình, API.** UI-20-10; API-20-106, API-20-164.
:::

#### FR-20-052 · Kết thúc sáp nhập sau thời gian chuyển tiếp

::: dac-ta
**Mục đích.** Khép lại sáp nhập: tắt chuyển tiếp, thu hồi thông tin xác thực cũ, chuyển tỉnh nguồn `DECOMMISSIONED`, lưu trữ dữ liệu và nhật ký theo thời hạn quy định; cho gia hạn có lý do khi HTTT chưa chuyển xong.

**Tác nhân, quyền.** PA (`PERM-20-merge`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D03-10 §5.4 bước 5; API-13-073; Q20-01.

**Tiền điều kiện.** Kế hoạch `TRANSITION`.

**Kích hoạt.** Tự động tại `transitionEndsAt`; UI-20-10 "Gia hạn", "Kết thúc ngay".

**Đầu vào.** Gia hạn: `extendMonths`, `reason`, `ticketRef`; kết thúc: `confirmCode`; `If-Match`.

**Luồng xử lý chính.**

1. Trước `transitionEndsAt` 30, 7, 1 ngày: hệ thống gửi danh sách HTTT còn dùng thông tin cũ (`OLD_ONLY`) cho đầu mối.
2. Tại `transitionEndsAt` hoặc khi PA kết thúc: hệ thống kiểm đã hết chuyển tiếp hoặc PA chọn kết thúc sớm khi không còn `OLD_ONLY` (ERR-20-046).
3. Hệ thống tắt chuyển tiếp (EVT-20-12), yêu cầu PH-12 thu hồi client cũ, gọi API-13-073 đóng chuỗi kiểm toán nguồn, chuyển nguồn `DECOMMISSIONED`; dữ liệu nguồn giữ chỉ đọc ở kho lưu trữ theo Q20-01 rồi xóa mật mã như FR-20-042.
4. Kế hoạch `COMPLETED`; PH-16 nhận EVT-20-12 để gộp lịch sử chỉ tiêu.

**Luồng thay thế.** Gia hạn: tổng chuyển tiếp ≤ `20.merge.transition-max-months` (ERR-20-045).

**Luồng ngoại lệ.**

- Kết thúc sớm khi còn HTTT dùng thông tin cũ: ERR-20-046 (409); "Chưa hết thời gian chuyển tiếp (đến {ngày}) và còn {số} HTTT dùng địa chỉ cũ."
- Gia hạn quá tối đa: ERR-20-045 (422); "Thời gian chuyển tiếp tối đa {số} tháng."

**Đầu ra.** `200` gia hạn; `202` kết thúc.

**Kết quả.** Tỉnh nguồn đóng hẳn; lượt gọi địa chỉ cũ nhận ERR-20-102.

**Hậu điều kiện.** Nguồn `DECOMMISSIONED`; kế hoạch `COMPLETED`.

**Sự kiện phát ra.** EVT-20-12; EVT-20-04.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-020, BR-20-025.

**Màn hình, API.** UI-20-10; API-20-107, API-20-108.
:::

### 6.9. Nhóm H · Tổ chức

Nhóm H giữ danh mục tổ chức DD-02 của mỗi tỉnh: UBND tỉnh, sở, ban, ngành, UBND cấp xã, đơn vị sự nghiệp. Đây là nguồn duy nhất cho chủ quản HTTT (PH-01), nơi công tác người dùng (PH-12), chủ quản dữ liệu (PH-06, PH-08), chủ quản danh mục (PH-07). Tổ chức không bị xóa: giải thể, sáp nhập tạo liên kết kế thừa để dữ liệu cũ vẫn tra được theo tên tại thời điểm phát sinh.

#### FR-20-053 · Quản lý danh mục tổ chức

::: dac-ta
**Mục đích.** Cho quản trị tỉnh tạo, sửa, xem danh mục tổ chức dạng cây và bảng, là danh mục chuẩn cho mọi phân hệ của tỉnh.

**Tác nhân, quyền.** TA (`PERM-20-org`); mọi vai trò tỉnh, PA, PO xem (`PERM-20-org-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D02-07 DD-02; Q20-11.

**Tiền điều kiện.** Tenant `ACTIVE`; tổ chức gieo từ `S13_ORG_SEED`.

**Kích hoạt.** UI-20-14 (cây + bảng), "+ Tổ chức"; UI-20-15 xem, sửa.

**Đầu vào.** Theo bảng dữ liệu vào của FR-20-053; `Idempotency-Key` khi tạo; `If-Match` khi sửa. Khi liệt kê: `q`, `orgType[]`, `status[]`, `parentCode`, `adminUnitId`, `asOf` (ngày hiệu lực), `view` (`TREE`, `TABLE`).

**Luồng xử lý chính.**

1. Hệ thống kiểm mã theo `^[A-Z0-9][A-Z0-9-]{1,49}$`, duy nhất trong tenant kể cả tổ chức đã giải thể (ERR-20-004, ERR-20-003).
2. Hệ thống kiểm cha tồn tại, `ACTIVE`, không tạo chu trình (ERR-20-047); `adminUnitId` thuộc tỉnh ở `COMMON` (ERR-20-012); `effectiveTo` ≥ `effectiveFrom` (ERR-20-052).
3. Hệ thống lưu tổ chức `ACTIVE`, phát EVT-20-13 (`change = CREATED` hoặc `UPDATED`).
4. Liệt kê: hệ thống trả cây theo `asOf` (mặc định hôm nay) hoặc bảng có phân trang.

**Luồng thay thế.** Đổi cha (sắp xếp bộ máy): lưu lịch sử cha cũ với hiệu lực; báo cáo theo ngày cũ hiện cha cũ.

**Luồng ngoại lệ.**

- Mã trùng: ERR-20-003 (409); "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- Cây chu trình, cha không hợp lệ: ERR-20-047 (422); "Tổ chức cấp trên {mã} không hợp lệ: {lý do}."
- Hiệu lực sai: ERR-20-052 (422).

**Đầu ra.** `201`, `200`; tổ chức, `ETag`; danh sách `items[]` hoặc `tree[]`.

**Kết quả.** Cây tổ chức của tỉnh luôn đúng, mọi phân hệ dùng chung.

**Hậu điều kiện.** EN-20-02 cập nhật.

**Sự kiện phát ra.** EVT-20-13.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-027, BR-20-028.

**Màn hình, API.** UI-20-14, UI-20-15; API-20-143, API-20-144, API-20-145, API-20-146.
:::

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `orgCode` | T-CODE | Có | `^[A-Z0-9][A-Z0-9-]{1,49}$`, duy nhất trong tenant | `SO-KHCN` |
| `name` | T-NAME | Có | 1…255 ký tự | `Sở Khoa học và Công nghệ` |
| `shortName` | T-NAME | Không | ≤ 50 ký tự | `Sở KH&CN` |
| `parentCode` | T-CODE | Không | Tổ chức `ACTIVE`, không chu trình | `UBND-TINH` |
| `orgType` | T-ENUM | Có | `PROVINCE_PC`, `DEPARTMENT`, `COMMUNE_PC`, `PUBLIC_UNIT`, `OTHER` | `DEPARTMENT` |
| `adminUnitId` | T-ID | Có | ĐVHC thuộc tỉnh ở `COMMON` | `01JH…` |
| `electronicId` | T-CODE | Không | Mã định danh điện tử cơ quan (Q20-11) | `H68.07` |
| `effectiveFrom` | T-DATE | Có | | `2025-07-01` |
| `effectiveTo` | T-DATE | Không | ≥ `effectiveFrom` | |

: Dữ liệu vào của FR-20-053

#### FR-20-054 · Hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa

::: dac-ta
**Mục đích.** Ghi nhận sắp xếp bộ máy (sở hợp nhất, xã sáp nhập) mà không làm mất liên kết của HTTT, người dùng, dữ liệu đang trỏ tới tổ chức cũ.

**Tác nhân, quyền.** TA (`PERM-20-org`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** D02-07 DD-02 (`successor_id`); Q01-10.

**Tiền điều kiện.** Tổ chức `ACTIVE` hoặc `INACTIVE`.

**Kích hoạt.** UI-20-15 "Ngừng", "Hoạt động lại", "Giải thể", "Sáp nhập vào…"; UI-20-14 chọn nhiều tổ chức, "Sáp nhập".

**Đầu vào.** `effectiveTo`, `successorCode`, `decisionDocNo`, `decisionDocDate`, `reason`; với sáp nhập: `sourceCodes[]`, `targetCode` (có sẵn hoặc tạo mới); `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống đếm tham chiếu đang hoạt động (HTTT ở PH-01, người dùng ở PH-12, chủ quản dữ liệu) qua API thống kê của từng phân hệ.
2. Giải thể khi còn tham chiếu mà thiếu kế thừa: từ chối (ERR-20-049); kế thừa phải `ACTIVE`, khác chính nó, cùng tenant (ERR-20-048).
3. Hệ thống đặt `DISSOLVED` hoặc `MERGED`, `effective_to`, `successor_id`; tổ chức con chuyển cha sang tổ chức kế thừa (TA xác nhận danh sách).
4. Hệ thống phát EVT-20-13 (`change = DISSOLVED` hoặc `MERGED`, `successorCode`); PH-01 tạo đề nghị đổi chủ quản chờ TA duyệt hàng loạt.

**Luồng thay thế.** "Ngừng": `INACTIVE`, không cần kế thừa; "Hoạt động lại": về `ACTIVE`.

**Luồng ngoại lệ.**

- Còn tham chiếu thiếu kế thừa: ERR-20-049 (409); "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."
- Kế thừa không hợp lệ: ERR-20-048 (422); "Tổ chức kế thừa {mã} không hợp lệ: {lý do}."
- Trạng thái cuối: ERR-20-006 (409).
- Phân hệ đếm tham chiếu không trả lời: ERR-20-062 (503).

**Đầu ra.** `200`; tổ chức mới trạng thái; danh sách tổ chức con đã chuyển cha.

**Kết quả.** Bộ máy mới có hiệu lực, dữ liệu cũ vẫn tra được theo tên cũ.

**Hậu điều kiện.** EN-20-02 cập nhật, lịch sử giữ.

**Sự kiện phát ra.** EVT-20-13.

**Kiểm toán.** Có: văn bản, kế thừa, số tham chiếu.

**Quy tắc nghiệp vụ.** BR-20-027, BR-20-028.

**Màn hình, API.** UI-20-14, UI-20-15; API-20-147, API-20-148, API-20-149, API-20-150, API-20-151.
:::

#### FR-20-055 · Nhập tổ chức từ Excel, CSV có xem trước và xuất

::: dac-ta
**Mục đích.** Cho tỉnh đưa vào hàng trăm tổ chức (đặc biệt UBND cấp xã) một lần, có xem trước từng dòng trước khi ghi; xuất danh mục để đối chiếu.

**Tác nhân, quyền.** TA (`PERM-20-org`); xuất với `PERM-20-org-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; D03-06-00 PTN-09.

**Tiền điều kiện.** Tenant `ACTIVE`.

**Kích hoạt.** UI-20-16 tải tệp; "Tải tệp mẫu"; UI-20-14 "Xuất".

**Đầu vào.** Tệp `.xlsx` hoặc `.csv` UTF-8 theo mẫu (cột như bảng FR-20-053), ≤ `20.org.import-max-rows` dòng, ≤ 10 MB; `mode` (`CREATE_ONLY`, `UPSERT`); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm định dạng, cột, số dòng (ERR-20-050), quét mã độc.
2. Hệ thống kiểm từng dòng như FR-20-053 (kể cả cha nằm trong cùng tệp), gán hành động `CREATE`, `UPDATE`, `UNCHANGED`, `ERROR`.
3. TA xem trước, sửa tệp nếu có lỗi, bấm "Xác nhận nhập"; còn dòng lỗi thì từ chối (ERR-20-051).
4. Hệ thống ghi trong một giao dịch theo thứ tự cha trước con, phát một EVT-20-13 gộp (`change = BULK_IMPORT`, danh sách mã).

**Luồng thay thế.** Xuất: tệp XLSX hoặc CSV theo bộ lọc hiện hành, có cột trạng thái, kế thừa.

**Luồng ngoại lệ.**

- Tệp sai định dạng, quá dòng: ERR-20-050 (422); "Tệp nhập không hợp lệ: {lý do}."
- Còn dòng lỗi khi xác nhận: ERR-20-051 (422); "Còn {số} dòng lỗi. Sửa tệp rồi tải lại."
- Xác nhận lô đã hết hạn (quá 24 giờ): ERR-20-006 (409).

**Đầu ra.** `202` (`importId`); API-20-154 trả `rows[]` (`rowNo`, `action`, `errors[]`), `summary`.

**Kết quả.** Hàng trăm tổ chức vào danh mục trong vài phút.

**Hậu điều kiện.** EN-20-30 `CONFIRMED`; EN-20-02 cập nhật.

**Sự kiện phát ra.** EVT-20-13.

**Kiểm toán.** Có: tệp, băm, số dòng mỗi loại.

**Quy tắc nghiệp vụ.** BR-20-027.

**Màn hình, API.** UI-20-14, UI-20-16; API-20-153, API-20-154, API-20-155, API-20-156.
:::

#### FR-20-056 · Đồng bộ tổ chức khi sắp xếp đơn vị hành chính

::: dac-ta
**Mục đích.** Khi danh mục ĐVHC quốc gia thay đổi (xã sáp nhập), đề xuất ngay cho tỉnh các thay đổi tổ chức tương ứng (UBND xã giải thể, UBND xã mới), thay vì để tỉnh tự dò.

**Tác nhân, quyền.** Hệ thống nghe EVT-07-10; TA quyết định (`PERM-20-org`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** EVT-07-10 `common.rdm.adminunit.reorganized.v1`; D03-10 §5.4 (ĐVHC có hiệu lực và kế thừa).

**Tiền điều kiện.** Tổ chức `COMMUNE_PC` có `adminUnitId` trỏ tới ĐVHC bị sắp xếp.

**Kích hoạt.** EVT-07-10; TA mở UI-20-14 tab "Đề xuất đồng bộ".

**Đầu vào.** Sự kiện (ĐVHC cũ, mới, ngày hiệu lực, văn bản); khi quyết: `proposalId`, `decision` (`APPLY`, `DISMISS`), chỉnh sửa tên, mã tổ chức mới.

**Luồng xử lý chính.**

1. Hệ thống nhận sự kiện qua inbox (lũy đẳng theo `eventId`), tìm tổ chức của mọi tenant tỉnh có `adminUnitId` liên quan.
2. Mỗi tenant có tổ chức liên quan nhận một đề xuất: tạo tổ chức mới cho ĐVHC mới, giải thể tổ chức cũ với kế thừa là tổ chức mới, hiệu lực theo sự kiện.
3. TA xem, chỉnh, "Áp" (chạy như FR-20-054 với kế thừa) hoặc "Bỏ" có lý do.

**Luồng thay thế.** Không có tổ chức liên quan: không sinh đề xuất. Tỉnh đã tự làm trước: đề xuất tự đánh dấu `ALREADY_APPLIED` khi so khớp.

**Luồng ngoại lệ.**

- Áp khi còn tham chiếu chưa có kế thừa hợp lệ: ERR-20-049 (409); "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."
- Đề xuất đã xử lý: ERR-20-006 (409).

**Đầu ra.** `200`; `proposals[]`; kết quả áp.

**Kết quả.** Tổ chức cấp xã theo kịp sắp xếp ĐVHC.

**Hậu điều kiện.** Đề xuất `APPLIED` hoặc `DISMISSED`.

**Sự kiện phát ra.** EVT-20-13 khi áp.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-029.

**Màn hình, API.** UI-20-14; API-20-157, API-20-158.
:::

#### FR-20-057 · API đọc tổ chức cho phân hệ khác

::: dac-ta
**Mục đích.** Cho PH-01, PH-06, PH-07, PH-08, PH-12, PH-16 kiểm và hiển thị tổ chức (chủ quản HTTT, nơi công tác, chủ quản dữ liệu) từ một nguồn, kể cả tổ chức đã giải thể và kế thừa.

**Tác nhân, quyền.** Phân hệ với `tenant:org-read`; tenant ngữ cảnh lấy từ token dịch vụ kèm `X-DH-Tenant` từ mesh (D03-10 §3).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; ERR-01-004; ERR-01-046; FR-00-010.

**Tiền điều kiện.** Tenant ngữ cảnh `ACTIVE`, `SUSPENDED`, `MERGING` hoặc `MERGED`.

**Kích hoạt.** Lời gọi của phân hệ.

**Đầu vào.** Liệt kê: `status[]`, `orgType[]`, `isDataOwner`, `asOf`, `updatedSince`, `page`, `size` (≤ 1.000). Tra: `orgCode`. Tra hàng loạt: `codes[]` ≤ 500.

**Luồng xử lý chính.**

1. Hệ thống kiểm scope (ERR-20-104), tenant ngữ cảnh từ mesh.
2. Hệ thống trả tổ chức kèm `status`, `successorCode`, chuỗi kế thừa tới tổ chức `ACTIVE` cuối cùng (`resolvedSuccessor`).
3. Phản hồi có `ETag`; phân hệ gọi được đệm tối đa 24 giờ (PH-01) và làm mới khi nhận EVT-20-13.

**Luồng thay thế.** Tenant `MERGED`: trả tổ chức nguồn chỉ đọc kèm `migratedTo` (mã tổ chức ở đích theo ánh xạ).

**Luồng ngoại lệ.**

- Thiếu scope: ERR-20-104 (403); "Tài khoản dịch vụ không có quyền {scope}."
- Không có tổ chức: ERR-20-002 (404); "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- PH-20 không khả dụng: bên gọi dùng đệm; hết đệm thì bên gọi trả ERR-01-046 theo hợp đồng của mình.

**Đầu ra.** `200`; `items[]` (`orgCode`, `name`, `orgType`, `parentCode`, `adminUnitId`, `status`, `isDataOwner`, `effectiveFrom`, `effectiveTo`, `successorCode`, `resolvedSuccessor`).

**Kết quả.** Mọi phân hệ dùng cùng một cây tổ chức.

**Hậu điều kiện.** Không thay đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-036.

**Màn hình, API.** Không có màn; API-20-169, API-20-170, API-20-171.
:::

#### FR-20-058 · Đánh dấu và tra cứu tổ chức chủ quản dữ liệu

::: dac-ta
**Mục đích.** Xác định tổ chức nào là chủ quản dữ liệu (SH-08) để PH-06, PH-08, PH-07 giao trách nhiệm chất lượng, phê duyệt chia sẻ đúng đơn vị.

**Tác nhân, quyền.** TA (`PERM-20-org`); DS, VW xem.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** D02-07 DD-02 (`is_data_owner`).

**Tiền điều kiện.** Tổ chức `ACTIVE`.

**Kích hoạt.** UI-20-15 công tắc "Chủ quản dữ liệu"; UI-20-14 lọc "Chủ quản dữ liệu".

**Đầu vào.** `isDataOwner`, `dataDomains[]` (lĩnh vực, tùy chọn), `reason`; `If-Match`.

**Luồng xử lý chính.**

1. Hệ thống kiểm tổ chức `ACTIVE` (ERR-20-006).
2. Khi bỏ đánh dấu, hệ thống hỏi PH-06, PH-08 số đối tượng đang giao cho tổ chức; còn thì từ chối (ERR-20-049).
3. Hệ thống lưu, phát EVT-20-13 (`change = DATA_OWNER`).

**Luồng thay thế.** Tra cứu hàng loạt qua API-20-171 với `isDataOwner = true`.

**Luồng ngoại lệ.**

- Còn đối tượng được giao: ERR-20-049 (409); "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."
- Tổ chức không hoạt động: ERR-20-006 (409).

**Đầu ra.** `200`; tổ chức, `ETag`.

**Kết quả.** Danh sách chủ quản dữ liệu rõ ràng cho cả tỉnh.

**Hậu điều kiện.** EN-20-02 cập nhật.

**Sự kiện phát ra.** EVT-20-13.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-027.

**Màn hình, API.** UI-20-14, UI-20-15; API-20-152, API-20-171.
:::

### 6.10. Nhóm I · Phát hành sản phẩm

Nhóm I quản lý phiên bản sản phẩm Datahub (gói ảnh container của mọi DU, đã ký cosign), kênh `PREVIEW` và `STABLE`, nâng cấp theo sóng trong cửa sổ bảo trì của từng tỉnh (ADR 203 đề xuất). Việc áp phiên bản do Argo CD thực hiện từ `release.yaml` của tenant; PH-20 chỉ ghi Git và theo dõi.

#### FR-20-059 · Danh mục phiên bản sản phẩm

::: dac-ta
**Mục đích.** Có một danh mục phiên bản sản phẩm duy nhất, mỗi phiên bản liệt kê đủ thành phần, digest, thay đổi lược đồ, ghi chú phát hành, để biết tỉnh nào đang chạy gì.

**Tác nhân, quyền.** PA đăng ký, sửa (`PERM-20-release`); PA, PO, PAU xem (`PERM-20-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; NFR-00-056; D03-10 §7.

**Tiền điều kiện.** Ảnh đã qua pipeline CI, có chữ ký cosign và SBOM.

**Kích hoạt.** UI-20-18 "+ Phiên bản"; CI gọi API-20-110 với tài khoản máy.

**Đầu vào.** `releaseVersion` (SemVer), `components[]` (`du`, `image`, `digest`), `schemaChanges[]` (`module`, `kind` `EXPAND` hoặc `CONTRACT`), `releaseNotes`, `minFromVersion`; `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống kiểm SemVer, chưa tồn tại, lớn hơn bản cùng dòng, mỗi digest có chữ ký hợp lệ (ERR-20-053, ERR-20-003).
2. Lưu `DRAFT`; PA sửa ghi chú được tới trước `PREVIEW`, sau đó thành phần bất biến.
3. PA "Ngừng hỗ trợ" bản cũ ngoài `20.release.supported-minors`, hoặc "Rút" bản lỗi (`WITHDRAWN`, không tenant mới nâng lên).

**Luồng thay thế.** Danh sách có cột "số tenant đang chạy" lấy từ EN-20-35.

**Luồng ngoại lệ.**

- Phiên bản không hợp lệ: ERR-20-053 (422); "Phiên bản sản phẩm {phiên bản} không hợp lệ: {lý do}."
- Trùng: ERR-20-003 (409); "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- Sửa thành phần sau `PREVIEW`: ERR-20-006 (409).

**Đầu ra.** `201`, `200`; phiên bản, `ETag`.

**Kết quả.** Danh mục phiên bản đầy đủ, truy được tới digest.

**Hậu điều kiện.** EN-20-31 cập nhật.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-030, BR-20-034.

**Màn hình, API.** UI-20-18; API-20-109, API-20-110, API-20-111, API-20-112, API-20-115, API-20-116.
:::

#### FR-20-060 · Kênh phát hành và đăng ký kênh của tenant

::: dac-ta
**Mục đích.** Cho tỉnh thí điểm (ví dụ T68 trên `STAGING`) nhận bản `PREVIEW` trước, các tỉnh còn lại chỉ nhận `STABLE` sau khi bản đã chạy ổn định.

**Tác nhân, quyền.** PA (`PERM-20-release`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** ADR 203; Q20-09.

**Tiền điều kiện.** Phiên bản `DRAFT` (để `PREVIEW`) hoặc `PREVIEW` (để `STABLE`).

**Kích hoạt.** UI-20-18 "Đưa lên PREVIEW", "Nâng lên STABLE"; UI-20-03 tab Phát hành "Đổi kênh".

**Đầu vào.** `releaseVersion`; `channel`, `environment` khi đổi đăng ký; `reason`; `If-Match`.

**Luồng xử lý chính.**

1. `PREVIEW`: hệ thống kiểm thành phần đủ, phát EVT-20-14.
2. `STABLE`: hệ thống kiểm đã ở `PREVIEW` ≥ `20.release.stable-soak-days` ngày và không sự cố mức 1 gắn phiên bản (ERR-20-054), phát EVT-20-14.
3. Đổi kênh tenant: kiểm không có kế hoạch nâng cấp đang chạy cho tenant (ERR-20-061), ghi `release.yaml`.

**Luồng thay thế.** Bản vá khẩn (`PATCH`, cờ `emergency`): được `STABLE` sau ≥ 1 ngày khi PO duyệt.

**Luồng ngoại lệ.**

- Chưa đủ thí điểm: ERR-20-054 (422); "Phiên bản {phiên bản} mới thí điểm {số} ngày, cần tối thiểu {ngưỡng} ngày và không có sự cố mức 1."
- Đổi kênh khi đang nâng cấp: ERR-20-061 (409); "Tenant {mã} đang có kế hoạch nâng cấp {kế hoạch}. Đổi kênh sau khi kế hoạch kết thúc."

**Đầu ra.** `200`.

**Kết quả.** Mỗi tenant gắn một kênh; bản mới đi qua thí điểm trước.

**Hậu điều kiện.** EN-20-31, EN-20-32 cập nhật.

**Sự kiện phát ra.** EVT-20-14.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-030, BR-20-031.

**Màn hình, API.** UI-20-03, UI-20-18; API-20-001, API-20-113, API-20-114, API-20-117.
:::

#### FR-20-061 · Lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì

::: dac-ta
**Mục đích.** Nâng cấp 34 tỉnh theo sóng (thí điểm, nhỏ, phần còn lại), mỗi tenant đúng cửa sổ bảo trì của mình, thay vì nâng cùng lúc.

**Tác nhân, quyền.** PA (`PERM-20-release`); TA đặt cửa sổ ưa thích (`PERM-20-settings`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** ADR 203; D03-10 §7; Q20-10.

**Tiền điều kiện.** Phiên bản `STABLE` (hoặc `PREVIEW` với tenant kênh `PREVIEW`); tenant đích chạy bản ≥ `minFromVersion`.

**Kích hoạt.** UI-20-19 "+ Kế hoạch nâng cấp".

**Đầu vào.** `releaseVersion`, `waves[]` (`waveNo`, `tenantCodes[]`), `soakHours` (mặc định theo loại bản), `startAfter`, `emergency`; TA: `maintenanceWindow` (`dayOfWeek`, `startTime`, `durationHours`); `Idempotency-Key`.

**Luồng xử lý chính.**

1. Hệ thống gợi ý sóng: sóng 1 tenant kênh `PREVIEW`, sóng 2 tối đa 5 tenant nhỏ, sóng 3 phần còn lại.
2. Kiểm tenant đủ điều kiện, mỗi tenant một kế hoạch (ERR-20-056), có cửa sổ (mặc định theo Q20-10).
3. PA "Lên lịch": hệ thống tính thời điểm mỗi tenant = cửa sổ đầu tiên sau khi sóng trước hết thời gian theo dõi; gửi thông báo (FR-20-063).
4. TA đặt cửa sổ: hệ thống kiểm dài 2…6 giờ, ngoài giờ cao điểm 7:00–17:00 ngày làm việc (ERR-20-059).

**Luồng thay thế.** Khẩn: bỏ chờ cửa sổ, thông báo trước ≥ `20.upgrade.emergency-notice-hours` giờ. Phân vai hai API ghi cửa sổ bảo trì (đóng Q20-39): API-20-160 là nơi TA đặt riêng cửa sổ ưa thích của tỉnh ở `/api/tenant/v1`; API-20-136 lưu trọn bộ cài đặt tỉnh nên mang cùng trường `maintenanceWindowPref` và áp cùng kiểm tra 2…6 giờ; lịch cụ thể của từng kế hoạch nâng cấp do PA đặt ở API-20-121 và không đổi cửa sổ ưa thích của tỉnh.

**Luồng ngoại lệ.**

- Kế hoạch không hợp lệ: ERR-20-056 (422); "Kế hoạch nâng cấp không hợp lệ: {lý do}."
- Cửa sổ sai: ERR-20-059 (422); "Cửa sổ bảo trì không hợp lệ: {lý do}."
- Phiên bản không dùng được: ERR-20-055 (422).

**Đầu ra.** `201`; kế hoạch, lịch từng tenant.

**Kết quả.** Lịch nâng cấp rõ cho từng tỉnh.

**Hậu điều kiện.** EN-20-34 `SCHEDULED`; EN-20-35 `PENDING`.

**Sự kiện phát ra.** EVT-20-15.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-032, BR-20-033.

**Màn hình, API.** UI-20-19, UI-20-12; API-20-118, API-20-119, API-20-120, API-20-121, API-20-160.
:::

#### FR-20-062 · Theo dõi nâng cấp, dừng sóng, quay lui

::: dac-ta
**Mục đích.** Nâng cấp từng tenant có kiểm tra sau nâng cấp, tự dừng sóng khi lỗi vượt ngưỡng, quay lui được khi không có thay đổi lược đồ `CONTRACT`.

**Tác nhân, quyền.** Hệ thống; PA thao tác (`PERM-20-release`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** ADR 203; NFR-20-016.

**Tiền điều kiện.** Kế hoạch `SCHEDULED` hoặc `RUNNING`.

**Kích hoạt.** Tới giờ cửa sổ; UI-20-19 "Dừng", "Tiếp tục", "Quay lui", "Thử lại".

**Đầu vào.** `planId`, `tenantCodes[]` (quay lui, thử lại), `reason`; `If-Match`.

**Luồng xử lý chính.**

1. Tới giờ: hệ thống đặt banner bảo trì (ERR-20-118 cho thao tác ghi bị chặn), ghi `release.yaml`, chờ Argo CD đồng bộ.
2. Chạy kiểm tra sau nâng cấp trong `20.release.verify-minutes` phút (bộ smoke của FR-20-012); đạt: tenant `DONE`, bỏ banner.
3. Tỷ lệ lỗi 5xx của sóng > `20.release.wave-error-threshold-percent` hoặc có tenant `FAILED`: dừng sóng, cảnh báo PA (ERR-20-057 khi tiếp tục mà chưa xác nhận).
4. Quay lui: ghi lại phiên bản trước vào `release.yaml`; có `CONTRACT` thì từ chối (ERR-20-058).

**Luồng thay thế.** Hủy kế hoạch chưa chạy (API-20-125).

**Luồng ngoại lệ.**

- Tiếp tục khi sóng dừng do ngưỡng: ERR-20-057 (409); "Sóng {sóng} đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục."
- Không quay lui được: ERR-20-058 (422).
- Kiểm tra sau nâng cấp không đạt (runtime): ERR-20-112 "Kiểm tra sau nâng cấp của {tenant} không đạt: {số} ca lỗi."

**Đầu ra.** `200`; tiến độ theo tenant.

**Kết quả.** Sự cố nâng cấp bị chặn ở sóng nhỏ.

**Hậu điều kiện.** EN-20-34, EN-20-35 cập nhật.

**Sự kiện phát ra.** EVT-20-15.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-032, BR-20-033.

**Màn hình, API.** UI-20-19; API-20-119, API-20-122, API-20-123, API-20-124, API-20-125, API-20-126, API-20-127.
:::

#### FR-20-063 · Thông báo phát hành và lịch bảo trì tới tỉnh

::: dac-ta
**Mục đích.** Báo cho quản trị tỉnh trước khi nâng cấp: phiên bản, thay đổi chính, thời gian bảo trì, ảnh hưởng.

**Tác nhân, quyền.** PA (`PERM-20-release`); hệ thống tự gửi khi lên lịch.

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** ADR 203; PH-18 thông báo.

**Tiền điều kiện.** Kế hoạch `SCHEDULED`.

**Kích hoạt.** Lên lịch; trước giờ 72 giờ và 2 giờ; PA "Gửi thông báo".

**Đầu vào.** `releaseVersion`, `planId`, `audience` (`TA`, `ALL_USERS`), `message` bổ sung.

**Luồng xử lý chính.**

1. Hệ thống dựng nội dung từ ghi chú phát hành và lịch tenant.
2. Gửi qua PH-18 (thư, thông báo trong ứng dụng), ghi trạng thái gửi.
3. Hiện banner tại `dh-console` của tỉnh từ 72 giờ trước.

**Luồng thay thế.** Khẩn: gửi ngay, nêu lý do.

**Luồng ngoại lệ.** PH-18 lỗi: ERR-20-062 (503); "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Đầu ra.** `202`.

**Kết quả.** Tỉnh biết trước lịch bảo trì.

**Hậu điều kiện.** Lịch sử thông báo lưu ở EN-20-34.

**Sự kiện phát ra.** Không (EVT-20-14 đã có).

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-033.

**Màn hình, API.** UI-20-12, UI-20-19; API-20-128.
:::

#### FR-20-064 · Xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh

::: dac-ta
**Mục đích.** Cho quản trị và người dùng tỉnh biết tỉnh đang chạy phiên bản nào, có gì mới, khi nào bảo trì tiếp.

**Tác nhân, quyền.** Mọi vai trò tỉnh (`PERM-20-org-read`); TA đặt cửa sổ (`PERM-20-settings`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** ADR 203.

**Tiền điều kiện.** Tenant `ACTIVE` hoặc `SUSPENDED`.

**Kích hoạt.** UI-20-12 tab "Phiên bản và bảo trì".

**Đầu vào.** Không; khi đặt cửa sổ như FR-20-061.

**Luồng xử lý chính.**

1. Hệ thống trả phiên bản đang chạy, ghi chú 3 bản gần nhất, lịch nâng cấp sắp tới, cửa sổ hiện hành.
2. TA đổi cửa sổ: áp cho kế hoạch lập sau.

**Luồng thay thế.** Không có kế hoạch: hiện "Chưa có lịch bảo trì".

**Luồng ngoại lệ.** Cửa sổ sai: ERR-20-059 (422); "Cửa sổ bảo trì không hợp lệ: {lý do}."

**Đầu ra.** `200`.

**Kết quả.** Tỉnh tự tra cứu, giảm hỏi đáp.

**Hậu điều kiện.** Không đổi dữ liệu khi xem.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có khi đổi cửa sổ.

**Quy tắc nghiệp vụ.** BR-20-033.

**Màn hình, API.** UI-20-12; API-20-135, API-20-159.
:::

### 6.11. Nhóm J · Dịch vụ cho phân hệ khác và quản trị

#### FR-20-065 · Registry tenant cho phân hệ khác

::: dac-ta
**Mục đích.** Cho mọi DU tra tenant (trạng thái, chế độ cách ly, realm, host, tiền tố, phân hệ bật, hạn mức) và cho tác vụ nền lặp qua mọi tenant đang hoạt động.

**Tác nhân, quyền.** Phân hệ với `tenant:registry-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** REQ-20; FR-00-011; NFR-20-003; BR-20-036.

**Tiền điều kiện.** Không.

**Kích hoạt.** Lời gọi của phân hệ, thư viện `dh-tenant-client`.

**Đầu vào.** `status` (ví dụ `GET /internal/tenant/v1/tenants?status=ACTIVE` cho tác vụ nền), `isolationMode`, `module`, `updatedSince`; một tenant: `tenantCode`.

**Luồng xử lý chính.**

1. Hệ thống kiểm scope (ERR-20-104).
2. Trả bản ghi registry kèm `ETag`, `Cache-Control: max-age = 20.registry.cache-seconds`.
3. Thư viện đệm cục bộ, vô hiệu khi nhận EVT-20-04, EVT-20-07, EVT-20-08, EVT-20-09.

**Luồng thay thế.** `If-None-Match` khớp: `304`.

**Luồng ngoại lệ.**

- Thiếu scope: ERR-20-104 (403); "Tài khoản dịch vụ không có quyền {scope}."
- Không có tenant: ERR-20-002 (404); "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

**Đầu ra.** `200`; `items[]` (`tenantCode`, `tenantId`, `status`, `isolationMode`, `realm`, `hosts[]`, `apiPrefix`, `modules[]`, `quota`, `configVersion`).

**Kết quả.** Một nguồn tra tenant cho cả nền tảng.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-036.

**Màn hình, API.** Không có màn; API-20-162, API-20-163.
:::

#### FR-20-066 · Thực thi trạng thái tenant ở data plane và control plane

::: dac-ta
**Mục đích.** Bảo đảm tenant tạm ngừng, chưa sẵn sàng, đã chấm dứt, đã sáp nhập hoặc phân hệ chưa bật bị chặn nhất quán ở mọi DU, không phụ thuộc mỗi phân hệ tự viết.

**Tác nhân, quyền.** Bộ lọc `dh-tenant-filter` ở mọi DU, plugin APISIX (PH-03); đọc API-20-163, API-20-164 với `tenant:registry-read`.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** FR-00-012; NFR-20-004; FR-03-039.

**Tiền điều kiện.** Registry khả dụng hoặc đệm còn hạn.

**Kích hoạt.** Mỗi yêu cầu vào DU hoặc gateway.

**Đầu vào.** Tenant ngữ cảnh, phân hệ đích, phương thức.

**Luồng xử lý chính.**

1. Bộ lọc tra trạng thái tenant trong đệm.
2. `SUSPENDED`: trả ERR-20-001 (403), trừ API thiết yếu khi `20.suspend.essential-api-allowed` bật và thao tác chỉ đọc.
3. `PROVISIONING`, `FAILED`: ERR-20-101 (503); `DECOMMISSIONED`: ERR-20-102 (410); `MERGED`: chuyển tiếp hoặc ERR-20-115 khi ghi; phân hệ chưa bật: ERR-20-103 (503); đang bảo trì: ERR-20-118 (503).

**Luồng thay thế.** Tài khoản PA, PO được qua để hỗ trợ, có kiểm toán.

**Luồng ngoại lệ.**

- Tạm ngừng: ERR-20-001 (403); "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh."
- Phân hệ chưa bật: ERR-20-103 (503); "Chức năng này chưa được bật cho tỉnh."
- Đang bảo trì: ERR-20-118 (503).

**Đầu ra.** Phản hồi lỗi chuẩn D00-04.

**Kết quả.** Trạng thái tenant có hiệu lực ở mọi nơi trong ≤ 60 giây.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có cho lượt qua của PA, PO.

**Quy tắc nghiệp vụ.** BR-20-021, BR-20-026, BR-20-036.

**Màn hình, API.** Không có màn; API-20-142, API-20-163, API-20-164.
:::

#### FR-20-067 · Bảng điều khiển nền tảng đa tenant

::: dac-ta
**Mục đích.** Một màn cho PA, PO thấy tình hình 34 tenant: trạng thái, saga dở, hạn mức gần trần, lệch cấu hình, phiên bản, kết quả rò rỉ.

**Tác nhân, quyền.** PA, PO, PAU (`PERM-20-read`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** KPI-12; BO-06.

**Tiền điều kiện.** Không.

**Kích hoạt.** UI-20-20.

**Đầu vào.** `environment`.

**Luồng xử lý chính.**

1. Hệ thống tổng hợp KPI (`CMP-KpiCard`): số tenant theo trạng thái, thời gian khởi tạo p95, KPI-12, số cảnh báo hạn mức, lệch, nâng cấp đang chạy, lần rò rỉ gần nhất.
2. Hiện danh sách cần xử lý, mỗi dòng dẫn tới màn chi tiết.

**Luồng thay thế.** Số liệu sử dụng trễ: hiện mốc cập nhật cuối.

**Luồng ngoại lệ.** Nguồn chỉ số lỗi: thẻ đó hiện "Không có số liệu" kèm ERR-20-062.

**Đầu ra.** `200`.

**Kết quả.** Vận hành phát hiện vấn đề sớm.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Không.

**Quy tắc nghiệp vụ.** BR-20-041.

**Màn hình, API.** UI-20-20; API-20-129.
:::

#### FR-20-068 · Nhật ký kiểm toán thao tác PH-20

::: dac-ta
**Mục đích.** Tra cứu mọi thao tác PH-20 (khai báo, khởi tạo, cấu hình, hạn mức, vòng đời, sáp nhập, tổ chức, phát hành) theo tenant, người, thời gian, kèm lý do, phiếu.

**Tác nhân, quyền.** PA, PAU toàn nền tảng; TA, AU của tỉnh.

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** FR-00-071; NFR-20-018; API-13-072.

**Tiền điều kiện.** Bản ghi đã ghi vào PH-13.

**Kích hoạt.** UI-20-03 tab "Kiểm toán"; `CMP-AuditTimeline`.

**Đầu vào.** `tenantCode`, `actor`, `action[]`, `from`, `to` (≤ 366 ngày), `ticketRef`.

**Luồng xử lý chính.**

1. Hệ thống kiểm khoảng thời gian (ERR-20-032), phạm vi người xem.
2. Gọi API-13-072 lọc theo `module = PH-20`, trả kết quả.

**Luồng thay thế.** Xuất CSV qua PH-13.

**Luồng ngoại lệ.**

- Khoảng thời gian quá dài: ERR-20-032 (400); "Khoảng thời gian tối đa là {số} ngày."
- PH-13 lỗi: ERR-20-062 (503); "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Đầu ra.** `200`; `items[]`.

**Kết quả.** Truy được ai làm gì, vì sao.

**Hậu điều kiện.** Không đổi dữ liệu.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Lượt tra cứu được ghi.

**Quy tắc nghiệp vụ.** BR-20-009.

**Màn hình, API.** UI-20-03; API-20-130, API-20-161.
:::

#### FR-20-069 · Tham số 20.* của phân hệ

::: dac-ta
**Mục đích.** Đăng ký và đọc 29 tham số `20.*` (bảng 8.2) qua PH-18, để đổi hành vi không cần triển khai lại.

**Tác nhân, quyền.** PO đổi giá trị ở PH-18; PA xem (`PERM-20-read`).

**Mức ưu tiên, đợt.** M · MVP.

**Truy vết.** BR-20-037; FR-00-010.

**Tiền điều kiện.** PH-18 khả dụng khi khởi động (có giá trị mặc định dự phòng).

**Kích hoạt.** Khởi động DU; EVT tham số đổi từ PH-18; màn xem tham số.

**Đầu vào.** Tên khóa, giá trị.

**Luồng xử lý chính.**

1. Khi khởi động, DU đăng ký lược đồ 29 khóa (kiểu, miền, mặc định).
2. Nhận thay đổi, kiểm miền (ERR-20-060), áp trong ≤ 60 giây.
3. API-20-131 trả giá trị hiệu lực và nguồn (mặc định hay ghi đè).

**Luồng thay thế.** PH-18 không khả dụng: dùng giá trị cuối đã nhận.

**Luồng ngoại lệ.**

- Giá trị ngoài miền: ERR-20-060 (422); "Giá trị {giá trị} của tham số {khóa} ngoài miền {miền}."
- Tắt kiểm tra khói khi có tenant thật (BR-20-004): ERR-20-060 (422); "Giá trị {giá trị} của tham số {khóa} ngoài miền {miền}."

**Đầu ra.** `200`.

**Kết quả.** Hành vi PH-20 chỉnh được có kiểm soát.

**Hậu điều kiện.** Giá trị áp mới.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có (ở PH-18).

**Quy tắc nghiệp vụ.** BR-20-037.

**Màn hình, API.** Không có màn riêng; API-20-131.
:::

#### FR-20-070 · Điều phối kiểm thử rò rỉ chéo tenant định kỳ

::: dac-ta
**Mục đích.** Hằng đêm chứng minh không tenant nào đọc được dữ liệu của tenant khác qua mọi API công bố (SEC-87), trên tenant kiểm thử T90…T99.

**Tác nhân, quyền.** Hệ thống theo lịch `20.leak-test.schedule`; PA chạy ngay (`PERM-20-admin`).

**Mức ưu tiên, đợt.** S · MVP.

**Truy vết.** SEC-87; NFR-20-019; D03-10 §3.

**Tiền điều kiện.** Có ít nhất hai tenant kiểm thử `ACTIVE` trong T90…T99.

**Kích hoạt.** Lịch; UI-20-20 "Chạy ngay".

**Đầu vào.** `sourceTenant`, `targetTenant` (mặc định T90, T91), `apiScope` (`ALL`, danh sách).

**Luồng xử lý chính.**

1. Kiểm tenant thuộc T90…T99 (ERR-20-065).
2. Gieo dữ liệu đánh dấu ở tenant đích, lấy danh mục API từ PH-03, gọi mọi API bằng danh tính tenant nguồn, cả tham số `tenantId` giả.
3. Bất kỳ phản hồi nào chứa dữ liệu đánh dấu: ERR-20-111, mở sự cố mức 1 qua PH-18, báo PO.

**Luồng thay thế.** Ca không áp dụng (API chỉ nền tảng): ghi `SKIPPED` có lý do.

**Luồng ngoại lệ.**

- Tenant không phải kiểm thử: ERR-20-065 (422); "Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99."
- Phát hiện rò rỉ (runtime): ERR-20-111 "Phát hiện rò rỉ chéo tenant ở {API}."

**Đầu ra.** `202`; kết quả từng ca.

**Kết quả.** Bằng chứng cách ly hằng ngày cho thẩm định an toàn.

**Hậu điều kiện.** EN-20-36 có kết quả.

**Sự kiện phát ra.** Không.

**Kiểm toán.** Có.

**Quy tắc nghiệp vụ.** BR-20-038.

**Màn hình, API.** UI-20-20; API-20-132, API-20-133, API-20-134.
:::

## 7. Quy tắc nghiệp vụ

Mỗi quy tắc có một mã, được dẫn ở mục "Quy tắc nghiệp vụ" của FR liên quan. Cột "Nguồn" chỉ căn cứ, không phải nơi định nghĩa.

| Mã | Quy tắc | Nguồn | FR |
|---|---|---|---|
| BR-20-001 | Mã tenant và realm bất biến sau khai báo; mã đã dùng không được cấp lại, kể cả tenant `DECOMMISSIONED`, `MERGED` | DD-01, D03-10 §2 | 001, 004, 019 |
| BR-20-002 | Mỗi ĐVHC cấp tỉnh có tối đa một tenant không ở trạng thái cuối | D03-10 §2 | 001, 007 |
| BR-20-003 | Tenant `PLATFORM`, `COMMON` không tạm ngừng, chấm dứt, sáp nhập, đổi cách ly, tắt phân hệ | D03-10 §2 | 006 |
| BR-20-004 | Tenant chỉ `ACTIVE` khi kiểm tra khói đạt; `20.smoke.enabled` không tắt được khi nền tảng có tenant tỉnh thật | NFR-00-057 | 012, 013, 069 |
| BR-20-005 | Mỗi bước saga lũy đẳng theo `{runId}:{stepCode}` và có thao tác bù ngược | ADR 200 | 008, 010, 011 |
| BR-20-006 | Mỗi tenant có tối đa một lần chạy saga chưa kết thúc | ADR 200 | 008, 016 |
| BR-20-007 | Bước quá `20.provision.step-timeout-minutes` thì tự thử tối đa `20.provision.step-retry-max` lần rồi `FAILED`; tổng quá `20.provision.timeout-minutes` thì lần chạy `FAILED` | NFR-00-057 | 008, 010 |
| BR-20-008 | Bốn mắt cho chấm dứt, sáp nhập, đổi cách ly, hạ hạn mức; người duyệt chấm dứt khác người xác nhận gói bàn giao | FR-00-071 | 025, 027, 040, 045 |
| BR-20-009 | Thao tác thay đổi tenant tỉnh cần lý do ≥ `20.lifecycle.reason-min-length` ký tự và mã phiếu; bản ghi kiểm toán vào chuỗi của tenant liên quan | FR-00-071 | Mọi FR thay đổi |
| BR-20-010 | Kho Git `dh-tenant-config` là trạng thái mong muốn; cơ sở dữ liệu chỉ giữ bản sao và phiên bản | ADR 201 | 019, 020, 021, 022 |
| BR-20-011 | Cài đặt tỉnh chỉ được chặt hơn giới hạn nền tảng | LGC-IAM-002 | 018 |
| BR-20-012 | Chính sách liên tenant của tỉnh có thời hạn ≤ `20.cross-tenant.max-hours` giờ | BR-12-032 | 023 |
| BR-20-013 | Hạn mức hiệu lực = lớn hơn của hợp đồng và ghi đè còn hạn, không vượt trần nền tảng; PH-20 không tự thực thi | ADR 204 | 026, 027, 032 |
| BR-20-014 | Hạ hạn mức cần duyệt; không cắt tài nguyên đã cấp, chỉ chặn cấp mới | ADR 204 | 027 |
| BR-20-015 | Ghi đè hạn mức tối đa `20.quota.override-max-days` ngày, tự hết hạn | ADR 204 | 032 |
| BR-20-016 | Cảnh báo ở `20.quota.warn-percent` và 100%, khử lặp; đặt lại khi dưới `20.quota.alert-reset-percent` | ADR 204 | 029 |
| BR-20-017 | Bật phân hệ cần phụ thuộc đã bật; phân hệ lõi PH-03, PH-10, PH-12, PH-13, PH-18, PH-20 không tắt | D03-06-00 | 033, 034, 035 |
| BR-20-018 | Tắt phân hệ không xóa dữ liệu của phân hệ | D03-10 | 035 |
| BR-20-019 | Chấm dứt cần tenant `SUSPENDED`, gói bàn giao `DELIVERED`, hết `20.terminate.cooling-days` ngày, hai PA | D03-10 §5.3 | 040, 042 |
| BR-20-020 | Xóa mật mã chỉ sau bàn giao, không đảo ngược | FR-09-043 | 042, 052 |
| BR-20-021 | Tạm ngừng trả ERR-20-001, giao diện chỉ đọc, API thiết yếu theo tham số, không cần bốn mắt | D03-10 §5.3 | 038, 066 |
| BR-20-022 | Sáp nhập: nguồn và đích `ACTIVE`, `PROVINCE`, mỗi tenant thuộc tối đa một kế hoạch chưa kết thúc | D03-10 §5.4 | 045, 048 |
| BR-20-023 | Dữ liệu chuyển giữ `id` gốc, ghi `origin_tenant_id`; xung đột không bao giờ ghi đè tự động | ADR 202 | 046, 048, 049 |
| BR-20-024 | Cutover cần mọi phân hệ `SUCCEEDED`, không xung đột mở, định danh đã chuyển; hủy chỉ trước cutover | D03-10 §5.4 | 047, 050, 051 |
| BR-20-025 | Chuyển tiếp `20.merge.transition-months` tháng, tối đa `20.merge.transition-max-months`; phản hồi có header `Deprecation`, `Sunset` | D03-10 §5.4 | 045, 051, 052 |
| BR-20-026 | Tenant `MERGED` chỉ đọc; ghi trả ERR-20-115 | D03-10 §5.4 | 051, 066 |
| BR-20-027 | Mã tổ chức duy nhất trong tenant, cây không chu trình, giải thể còn tham chiếu phải có kế thừa, không xóa cứng | DD-02 | 053, 054, 055, 058 |
| BR-20-028 | Tổ chức có hiệu lực từ ngày đến ngày; truy vấn theo `asOf` | DD-02 | 053, 054 |
| BR-20-029 | Đồng bộ theo ĐVHC chỉ tạo đề xuất, không tự áp | EVT-07-10 | 056 |
| BR-20-030 | Phiên bản sản phẩm theo SemVer, bất biến từ `PREVIEW`, mọi ảnh có chữ ký cosign | NFR-00-056 | 059, 060 |
| BR-20-031 | `STABLE` sau ≥ `20.release.stable-soak-days` ngày ở `PREVIEW` và không sự cố mức 1 | ADR 203 | 060 |
| BR-20-032 | Nâng cấp theo sóng, theo dõi `20.release.wave-soak-hours-minor` hoặc `-patch` giờ; dừng khi lỗi > `20.release.wave-error-threshold-percent` | ADR 203 | 061, 062 |
| BR-20-033 | Nâng cấp trong cửa sổ bảo trì; khẩn thông báo trước ≥ `20.upgrade.emergency-notice-hours` giờ | ADR 203 | 061, 063, 064 |
| BR-20-034 | Hỗ trợ đồng thời `20.release.supported-minors` bản phụ | ADR 203 | 059 |
| BR-20-035 | `DEDICATED_CLUSTER` chỉ dùng khi `20.dedicated-cluster.enabled` bật | D03-10 §2 | 017, 025 |
| BR-20-036 | Registry được đệm ≤ `20.registry.cache-seconds` giây, tổ chức ≤ 24 giờ; EVT-20-04 vô hiệu đệm | NFR-20-004 | 057, 065, 066 |
| BR-20-037 | Tham số `20.*` đăng ký ở PH-18, áp ≤ 60 giây | FR-00-010 | 069 |
| BR-20-038 | Kiểm thử rò rỉ chỉ trên T90…T99; phát hiện là sự cố mức 1 | SEC-87 | 070 |
| BR-20-039 | Sự kiện qua outbox, không chứa dữ liệu cá nhân | NFR-00-003 | Mọi FR phát sự kiện |
| BR-20-040 | Đổi cách ly một bậc mỗi lần, trong cửa sổ bảo trì | ADR 201 | 025 |
| BR-20-041 | KPI-12 đo từ `declaredAt` tới `ACTIVE` theo giờ làm việc | KPI-12 | 014, 067 |
| BR-20-042 | Mẫu khởi tạo có phiên bản, bất biến sau phát hành; lần chạy ghi phiên bản mẫu | ADR 200 | 015, 008 |

: Quy tắc nghiệp vụ BR-20-001…042

## 8. Yêu cầu phi chức năng và tham số

### 8.1. Yêu cầu phi chức năng

| Mã | Yêu cầu | Nguồn |
|---|---|---|
| NFR-20-001 | Saga khởi tạo ≤ 60 phút p95 | NFR-00-057 |
| NFR-20-002 | KPI-12 ≤ 1 ngày làm việc | KPI-12 |
| NFR-20-003 | Registry p99 ≤ 50 ms, ≥ 500 lượt mỗi giây | FR-00-011 |
| NFR-20-004 | Tạm ngừng có hiệu lực ở data plane ≤ 60 giây | FR-00-012 |
| NFR-20-005 | Phục vụ ≥ 34 tenant tỉnh, thiết kế 40 | NFR-00-060 |
| NFR-20-006 | Danh sách màn hình p95 ≤ 1,5 giây | D03-06-00 |
| NFR-20-007 | Tiến độ saga qua SSE trễ ≤ 2 giây | FR-20-009 |
| NFR-20-008 | Sử dụng thu hằng giờ, trễ ≤ 15 phút, lưu 25 tháng | ADR 204 |
| NFR-20-009 | Cảnh báo hạn mức ≤ 5 phút sau khi chạm ngưỡng | FR-20-029 |
| NFR-20-010 | Lệch cấu hình phát hiện ≤ 1 giờ | FR-20-022 |
| NFR-20-011 | Cấu hình GitOps áp ≤ 5 phút | ADR 201 |
| NFR-20-012 | Xem trước nhập 5.000 dòng tổ chức ≤ 30 giây | FR-20-055 |
| NFR-20-013 | API đọc tổ chức p95 ≤ 100 ms | FR-20-057 |
| NFR-20-014 | Kiểm đếm sáp nhập khớp 100% bản ghi (trừ `SKIP`) | D03-10 §5.4 |
| NFR-20-015 | Cutover 0 lượt gọi lỗi do chuyển tiếp, thêm trễ ≤ 10 ms | FR-20-051 |
| NFR-20-016 | Dừng sóng ≤ 5 phút sau khi vượt ngưỡng | FR-20-062 |
| NFR-20-017 | Sẵn sàng control plane ≥ 99,5%, registry ≥ 99,9% | NFR-00-060 |
| NFR-20-018 | 100% thao tác thay đổi có bản ghi kiểm toán | FR-00-071 |
| NFR-20-019 | Kiểm thử rò rỉ hằng đêm ≤ 60 phút, phủ 100% API công bố | SEC-87 |
| NFR-20-020 | Outbox phát sự kiện p95 ≤ 5 giây | NFR-00-003 |
| NFR-20-021 | Chỉ số `dh_tenant_*`, `dh_release_*` có nhãn `tenant` | D03-10 |
| NFR-20-022 | Giao diện đạt WCAG 2.2 AA | D03-06-00 |
| NFR-20-023 | Gói bàn giao 500 GB ≤ 24 giờ (giả định, Q20-02) | FR-20-041 |
| NFR-20-024 | Không lưu bí mật trong `ph20_tenant` hay Git; chỉ tham chiếu Vault | SEC-85 |

: Yêu cầu phi chức năng NFR-20-001…024

### 8.2. Tham số

Tham số đăng ký với PH-18 (FR-20-069). Đổi giá trị có kiểm toán ở PH-18, áp ≤ 60 giây.

| Khóa | Mặc định | Miền | Dùng ở |
|---|---|---|---|
| `20.provision.timeout-minutes` | 60 | 30…240 | FR-20-008 |
| `20.provision.step-timeout-minutes` | 15 | 5…60 | FR-20-008 |
| `20.provision.step-retry-max` | 3 | 0…10 | FR-20-010 |
| `20.smoke.enabled` | true | true, false | FR-20-012 |
| `20.quota.warn-percent` | 80 | 50…95 | FR-20-029 |
| `20.quota.alert-reset-percent` | 75 | 40…90, nhỏ hơn ngưỡng cảnh báo | FR-20-029 |
| `20.quota.override-max-days` | 30 | 1…90 | FR-20-032 |
| `20.usage.snapshot-interval` | PT1H | PT15M…PT6H | FR-20-028 |
| `20.usage.retention-months` | 25 | 13…60 | FR-20-028 |
| `20.usage.probe-interval` | PT5M | PT1M…PT15M | FR-20-029 |
| `20.suspend.essential-api-allowed` | false | true, false | FR-20-038, 066 |
| `20.terminate.cooling-days` | 30 | 7…180 | FR-20-040 |
| `20.export.retention-days` | 90 | 30…365 | FR-20-041 |
| `20.merge.transition-months` | 6 | 1…12 | FR-20-045 |
| `20.merge.transition-max-months` | 12 | 6…24 | FR-20-052 |
| `20.release.stable-soak-days` | 14 | 3…60 | FR-20-060 |
| `20.release.wave-error-threshold-percent` | 2 | 0,5…10 | FR-20-062 |
| `20.release.wave-soak-hours-minor` | 48 | 12…168 | FR-20-061 |
| `20.release.wave-soak-hours-patch` | 24 | 4…72 | FR-20-061 |
| `20.release.verify-minutes` | 30 | 10…120 | FR-20-062 |
| `20.release.supported-minors` | 2 | 1…4 | FR-20-059 |
| `20.upgrade.emergency-notice-hours` | 2 | 1…24 | FR-20-061 |
| `20.drift.check-interval` | PT1H | PT15M…PT24H | FR-20-022 |
| `20.org.import-max-rows` | 5000 | 100…20000 | FR-20-055 |
| `20.leak-test.schedule` | 01:00 hằng đêm | Biểu thức lịch | FR-20-070 |
| `20.cross-tenant.max-hours` | 4 | 1…4 (trần BR-12-032) | FR-20-023 |
| `20.dedicated-cluster.enabled` | false | true, false | FR-20-017 |
| `20.registry.cache-seconds` | 60 | 10…60 (trần NFR-20-004) | FR-20-065 |
| `20.lifecycle.reason-min-length` | 20 | 10…200 | Mọi FR thay đổi |

: Tham số 20.* của PH-20

## 9. Mã lỗi, thông báo, sự kiện và danh mục API

### 9.1. Mã lỗi

Lỗi theo D00-04 (`application/problem+json`). `ERR-20-001…068` cho control plane; `ERR-20-101…118` cho data plane, registry, API nội bộ và lỗi khi chạy (HTTP "—": ghi vào bước, lần chạy, cảnh báo). Thiếu xác thực, quyền, `If-Match` dùng ERR-00-401, ERR-00-403, ERR-00-428.

| Mã | HTTP | Ý nghĩa | Khi nào |
|---|---|---|---|
| ERR-20-001 | 403 | Tenant tạm ngừng | Data plane, control plane khi `SUSPENDED` (FR-038, 066) |
| ERR-20-002 | 404 | Không tìm thấy | Mọi FR tra theo mã |
| ERR-20-003 | 409 | Trùng mã | Tạo tenant, mẫu, tổ chức, phiên bản |
| ERR-20-004 | 400 | Dữ liệu sai định dạng | Mọi FR có đầu vào |
| ERR-20-005 | 412 | Phiên bản lệch (`If-Match`) | Mọi thao tác sửa |
| ERR-20-006 | 409 | Trạng thái không cho phép | Mọi máy trạng thái |
| ERR-20-007 | 403 | Vi phạm bốn mắt | FR-025, 027, 040, 041, 045 |
| ERR-20-008 | 422 | Thiếu lý do, phiếu | Mọi thao tác thay đổi tenant tỉnh |
| ERR-20-009 | 409 | Khóa chống lặp dùng cho yêu cầu khác | Mọi `POST` có `Idempotency-Key` |
| ERR-20-010 | 403 | Tenant đặc biệt | FR-006 |
| ERR-20-011 | 409 | ĐVHC đã có tenant | FR-001, 007 |
| ERR-20-012 | 422 | ĐVHC không hợp lệ | FR-001, 053 |
| ERR-20-013 | 422 | Hết sức chứa nền tảng | FR-007 |
| ERR-20-014 | 422 | Thiếu tài nguyên cụm | FR-007 |
| ERR-20-015 | 422 | Mẫu không dùng được | FR-007, 015 |
| ERR-20-016 | 409 | Đang có lần chạy | FR-008, 016 |
| ERR-20-017 | 422 | Kiểm tra sẵn sàng chưa đạt | FR-007, 008 |
| ERR-20-018 | 409 | Không thử lại được | FR-010 |
| ERR-20-019 | 409 | Không bù trừ được | FR-011 |
| ERR-20-020 | 422 | Kiểm tra khói chưa đạt | FR-012, 013 |
| ERR-20-021 | 422 | Thiếu đầu mối | FR-005, 013 |
| ERR-20-022 | 422 | Hợp đồng không hợp lệ | FR-005, 026 |
| ERR-20-023 | 422 | Vượt giới hạn nền tảng | FR-018 |
| ERR-20-024 | 502 | Ghi GitOps lỗi | FR-020 |
| ERR-20-025 | 409 | Cấu hình đang lệch | FR-019, 022 |
| ERR-20-026 | 422 | Không khôi phục được cấu hình | FR-021 |
| ERR-20-027 | 422 | Liên tenant vượt trần | FR-023 |
| ERR-20-028 | 422 | Không chuyển được chế độ cách ly | FR-025 |
| ERR-20-029 | 422 | Hạn mức ngoài miền | FR-026, 027 |
| ERR-20-030 | 422 | Hạ dưới mức đang dùng | FR-027 |
| ERR-20-031 | 422 | Ghi đè quá số ngày | FR-032 |
| ERR-20-032 | 400 | Khoảng thời gian quá dài | FR-030, 031, 068 |
| ERR-20-033 | 422 | Thiếu phụ thuộc phân hệ | FR-034 |
| ERR-20-034 | 409 | Phân hệ đang bị phụ thuộc | FR-035 |
| ERR-20-035 | 403 | Phân hệ lõi | FR-035 |
| ERR-20-036 | 422 | Cờ không áp dụng được | FR-036 |
| ERR-20-037 | 422 | Chưa đủ điều kiện chấm dứt, khôi phục | FR-039, 040, 042 |
| ERR-20-038 | 422 | Chưa hết thời gian nguội | FR-040 |
| ERR-20-039 | 410 | Gói bàn giao hết hạn | FR-041 |
| ERR-20-040 | 422 | Kế hoạch sáp nhập không hợp lệ | FR-045 |
| ERR-20-041 | 409 | Tenant thuộc kế hoạch khác | FR-045 |
| ERR-20-042 | 422 | Ánh xạ chưa đủ | FR-046, 047 |
| ERR-20-043 | 422 | Chạy thử chưa đạt hoặc đã cũ | FR-045, 048 |
| ERR-20-044 | 409 | Còn xung đột | FR-049, 050, 051 |
| ERR-20-045 | 422 | Chuyển tiếp vượt tối đa | FR-045, 052 |
| ERR-20-046 | 409 | Chưa hết chuyển tiếp | FR-052 |
| ERR-20-047 | 422 | Cấp trên không hợp lệ, chu trình | FR-053 |
| ERR-20-048 | 422 | Kế thừa không hợp lệ | FR-054 |
| ERR-20-049 | 409 | Còn tham chiếu, cần kế thừa | FR-054, 056, 058 |
| ERR-20-050 | 422 | Tệp nhập không hợp lệ | FR-055 |
| ERR-20-051 | 422 | Lô còn dòng lỗi | FR-055 |
| ERR-20-052 | 422 | Hiệu lực sai | FR-053 |
| ERR-20-053 | 422 | Phiên bản sản phẩm không hợp lệ | FR-059 |
| ERR-20-054 | 422 | Chưa đủ thí điểm | FR-060 |
| ERR-20-055 | 422 | Phiên bản không dùng được | FR-061 |
| ERR-20-056 | 422 | Kế hoạch nâng cấp không hợp lệ | FR-061 |
| ERR-20-057 | 409 | Sóng dừng do ngưỡng | FR-062 |
| ERR-20-058 | 422 | Không quay lui được | FR-062 |
| ERR-20-059 | 422 | Cửa sổ bảo trì không hợp lệ | FR-051, 061, 064 |
| ERR-20-060 | 422 | Tham số ngoài miền | FR-069 |
| ERR-20-061 | 409 | Đổi kênh khi đang nâng cấp | FR-060 |
| ERR-20-062 | 503 | Phụ thuộc không khả dụng | Mọi FR gọi phân hệ khác |
| ERR-20-063 | 409 | Mẫu đã phát hành | FR-015 |
| ERR-20-064 | 422 | Cụm chưa đạt | FR-017 |
| ERR-20-065 | 422 | Không phải tenant kiểm thử | FR-070 |
| ERR-20-066 | 422 | Không lập được báo cáo | FR-031 |
| ERR-20-067 | 409 | Host, tiền tố trùng | FR-001, 019 |
| ERR-20-068 | 422 | Thuộc tính bất biến | FR-004, 019 |
| ERR-20-101 | 503 | Tenant chưa sẵn sàng | `PROVISIONING`, `FAILED` (FR-066) |
| ERR-20-102 | 410 | Tenant đã chấm dứt | `DECOMMISSIONED` (FR-042, 066) |
| ERR-20-103 | 503 | Phân hệ chưa bật | FR-035, 066 |
| ERR-20-104 | 403 | Scope không đủ, không phải bên thực hiện | API nội bộ (FR-009, 057, 065) |
| ERR-20-105 | 409 | Báo tiến độ sai bước, trạng thái | API-20-166 (FR-009) |
| ERR-20-106 | — | Bước quá hạn chờ báo | Saga (FR-008) |
| ERR-20-107 | — | Bên thực hiện báo lỗi | Saga, sáp nhập (FR-008, 047) |
| ERR-20-108 | — | Saga vượt tổng thời gian | Saga (FR-008) |
| ERR-20-109 | — | Argo CD đồng bộ lỗi | FR-020, 062 |
| ERR-20-110 | — | Thiếu số liệu sử dụng | FR-028 |
| ERR-20-111 | — | Phát hiện rò rỉ | FR-070 |
| ERR-20-112 | — | Kiểm tra sau nâng cấp không đạt | FR-062 |
| ERR-20-113 | — | Kiểm đếm sáp nhập lệch | FR-047, 048, 051 |
| ERR-20-114 | 409 | Báo sáp nhập sai trạng thái | API-20-167 (FR-048) |
| ERR-20-115 | 409 | Tenant `MERGED` chỉ đọc | FR-051, 066 |
| ERR-20-116 | — | Chưa xác nhận xóa mật mã | FR-042 |
| ERR-20-117 | — | Ca kiểm tra khói lỗi | FR-012 |
| ERR-20-118 | 503 | Đang bảo trì nâng cấp | FR-062, 066 |

: Mã lỗi ERR-20 của PH-20

### 9.2. Thông báo

Câu chuẩn, mỗi mã một câu; `{…}` là biến điền khi chạy.

| Mã | Câu thông báo |
|---|---|
| ERR-20-001 | "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh." |
| ERR-20-002 | "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem." |
| ERR-20-003 | "{Đối tượng} {mã} đã tồn tại. Chọn mã khác." |
| ERR-20-004 | "{Trường} chưa hợp lệ: {yêu cầu}." |
| ERR-20-005 | "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi." |
| ERR-20-006 | "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." |
| ERR-20-007 | "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt." |
| ERR-20-008 | "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu." |
| ERR-20-009 | "Khóa chống lặp đã được dùng cho một yêu cầu khác. Tạo yêu cầu mới." |
| ERR-20-010 | "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này." |
| ERR-20-011 | "Đơn vị hành chính {tên} đã có tenant {mã} đang sử dụng." |
| ERR-20-012 | "Đơn vị hành chính {mã} không phải cấp tỉnh hoặc đã hết hiệu lực." |
| ERR-20-013 | "Nền tảng đã đạt sức chứa {số} tenant. Liên hệ vận hành hạ tầng để mở rộng." |
| ERR-20-014 | "Cụm chưa đủ tài nguyên cho hồ sơ {hồ sơ}: thiếu {tài nguyên}." |
| ERR-20-015 | "Mẫu khởi tạo {mã} phiên bản {n} không dùng được: {lý do}." |
| ERR-20-016 | "Tenant {mã} đang có lần khởi tạo {runId} chưa kết thúc." |
| ERR-20-017 | "Kiểm tra sẵn sàng chưa đạt: {số} mục cần xử lý." |
| ERR-20-018 | "Không thể thử lại bước {bước}: {lý do}." |
| ERR-20-019 | "Không thể bù trừ: {lý do}." |
| ERR-20-020 | "Kiểm tra khói chưa đạt ({số} ca lỗi). Không thể kích hoạt tenant." |
| ERR-20-021 | "Cần đủ đầu mối {vai trò} trước khi {thao tác}." |
| ERR-20-022 | "Hợp đồng {số}: {lý do}." |
| ERR-20-023 | "{Thiết lập} vượt giới hạn của nền tảng ({giới hạn})." |
| ERR-20-024 | "Không ghi được cấu hình vào kho GitOps. Thử lại sau, nếu lặp lại báo vận hành nền tảng." |
| ERR-20-025 | "Cấu hình tenant {mã} đang lệch chưa xử lý. Đối chiếu trước khi sửa." |
| ERR-20-026 | "Không khôi phục được phiên bản cấu hình {n}: {lý do}." |
| ERR-20-027 | "Thời hạn truy cập liên tenant tối đa là {giờ} giờ." |
| ERR-20-028 | "Không chuyển được từ chế độ {từ} sang {tới}: {lý do}." |
| ERR-20-029 | "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}." |
| ERR-20-030 | "Hạ hạn mức {tài nguyên} xuống {giá trị} thấp hơn mức đang dùng {dùng} cần được duyệt." |
| ERR-20-031 | "Ghi đè hạn mức tối đa {số} ngày." |
| ERR-20-032 | "Khoảng thời gian tối đa là {số} ngày." |
| ERR-20-033 | "Phân hệ {phân hệ} cần {phụ thuộc} được bật trước." |
| ERR-20-034 | "Phân hệ {phân hệ} đang được {danh sách} dùng. Tắt các phân hệ đó trước." |
| ERR-20-035 | "Phân hệ {phân hệ} là phân hệ lõi, không tắt được." |
| ERR-20-036 | "Cờ {cờ} không áp dụng được: {lý do}." |
| ERR-20-037 | "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}." |
| ERR-20-038 | "Chưa hết thời gian chờ {số} ngày kể từ khi tạm ngừng (đến {ngày})." |
| ERR-20-039 | "Gói bàn giao {mã} đã hết hạn lưu. Lập gói mới." |
| ERR-20-040 | "Kế hoạch sáp nhập không hợp lệ: {lý do}." |
| ERR-20-041 | "Tenant {mã} đang thuộc kế hoạch sáp nhập {kế hoạch}." |
| ERR-20-042 | "Bảng ánh xạ còn {số} dòng bắt buộc chưa quyết định." |
| ERR-20-043 | "Chạy thử sáp nhập chưa đạt hoặc đã cũ so với bảng ánh xạ hiện hành." |
| ERR-20-044 | "Còn {số} xung đột sáp nhập chưa xử lý." |
| ERR-20-045 | "Thời gian chuyển tiếp tối đa {số} tháng." |
| ERR-20-046 | "Chưa hết thời gian chuyển tiếp (đến {ngày}) và còn {số} HTTT dùng địa chỉ cũ." |
| ERR-20-047 | "Tổ chức cấp trên {mã} không hợp lệ: {lý do}." |
| ERR-20-048 | "Tổ chức kế thừa {mã} không hợp lệ: {lý do}." |
| ERR-20-049 | "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa." |
| ERR-20-050 | "Tệp nhập không hợp lệ: {lý do}." |
| ERR-20-051 | "Còn {số} dòng lỗi. Sửa tệp rồi tải lại." |
| ERR-20-052 | "Ngày hết hiệu lực phải sau hoặc bằng ngày bắt đầu hiệu lực." |
| ERR-20-053 | "Phiên bản sản phẩm {phiên bản} không hợp lệ: {lý do}." |
| ERR-20-054 | "Phiên bản {phiên bản} mới thí điểm {số} ngày, cần tối thiểu {ngưỡng} ngày và không có sự cố mức 1." |
| ERR-20-055 | "Phiên bản {phiên bản} không dùng được cho thao tác này: {lý do}." |
| ERR-20-056 | "Kế hoạch nâng cấp không hợp lệ: {lý do}." |
| ERR-20-057 | "Sóng {sóng} đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục." |
| ERR-20-058 | "Không quay lui được phiên bản {phiên bản} vì có thay đổi lược đồ không tương thích ở {phân hệ}." |
| ERR-20-059 | "Cửa sổ bảo trì không hợp lệ: {lý do}." |
| ERR-20-060 | "Giá trị {giá trị} của tham số {khóa} ngoài miền {miền}." |
| ERR-20-061 | "Tenant {mã} đang có kế hoạch nâng cấp {kế hoạch}. Đổi kênh sau khi kế hoạch kết thúc." |
| ERR-20-062 | "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." |
| ERR-20-063 | "Phiên bản {n} của mẫu {mã} đã phát hành, không sửa được. Tạo phiên bản mới." |
| ERR-20-064 | "Cụm {mã} chưa đạt yêu cầu: {danh sách thiếu}." |
| ERR-20-065 | "Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99." |
| ERR-20-066 | "Không lập được báo cáo sử dụng: {lý do}." |
| ERR-20-067 | "Tên miền hoặc tiền tố {giá trị} đã được tenant khác dùng." |
| ERR-20-068 | "Không đổi được {thuộc tính} của tenant sau khai báo." |
| ERR-20-101 | "Tỉnh chưa sẵn sàng phục vụ." |
| ERR-20-102 | "Tỉnh đã chấm dứt sử dụng Datahub." |
| ERR-20-103 | "Chức năng này chưa được bật cho tỉnh." |
| ERR-20-104 | "Tài khoản dịch vụ không có quyền {scope}." |
| ERR-20-105 | "Báo tiến độ bước {bước} không khớp trạng thái {trạng thái}." |
| ERR-20-106 | "Bước {bước} chưa nhận báo cáo từ {bên thực hiện} sau {phút} phút." |
| ERR-20-107 | "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}." |
| ERR-20-108 | "Khởi tạo vượt thời gian cho phép {phút} phút." |
| ERR-20-109 | "Argo CD không áp được cấu hình {phiên bản}: {lý do}." |
| ERR-20-110 | "Thiếu số liệu sử dụng {tài nguyên} của {tenant} từ {giờ}." |
| ERR-20-111 | "Phát hiện rò rỉ chéo tenant ở {API}." |
| ERR-20-112 | "Kiểm tra sau nâng cấp của {tenant} không đạt: {số} ca lỗi." |
| ERR-20-113 | "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}." |
| ERR-20-114 | "Báo tiến độ sáp nhập không khớp trạng thái của {phân hệ}." |
| ERR-20-115 | "Tỉnh đã sáp nhập vào {đích}. Dữ liệu chỉ còn để tra cứu." |
| ERR-20-116 | "Chưa nhận xác nhận xóa mật mã của {tenant}." |
| ERR-20-117 | "Ca kiểm tra khói {ca} lỗi: {chi tiết}." |
| ERR-20-118 | "Tỉnh đang bảo trì nâng cấp đến {giờ}. Thao tác ghi tạm dừng." |

: Câu thông báo theo mã lỗi

### 9.3. Sự kiện

Sự kiện qua outbox lên Kafka, lược đồ ở Apicurio, khóa phân vùng `tenantCode`, không chứa dữ liệu cá nhân (BR-20-039).

| Mã | Topic | Khi nào | Bên nhận | FR |
|---|---|---|---|---|
| EVT-20-01 | `platform.tenant.created.v1` | Khai báo xong, saga bắt đầu | PH-10, PH-03, PH-04, PH-06, PH-13 | 008 |
| EVT-20-02 | `platform.tenant.provisioning-failed.v1` | Saga dừng `FAILED` | PH-13, PH-18 | 008, 010 |
| EVT-20-03 | `platform.tenant.activated.v1` | Tenant `ACTIVE` | Mọi DU, PH-16 | 013, 014 |
| EVT-20-04 | `platform.tenant.status-changed.v1` | Mọi đổi trạng thái tenant | PH-01, PH-03, PH-04, PH-12, PH-13, PH-19 | 038–044, 048, 051, 052 |
| EVT-20-05 | `platform.tenant.quota-changed.v1` | Hạn mức hợp đồng hoặc ghi đè đổi | PH-03, PH-04, PH-10, PH-12 | 026, 027, 032 |
| EVT-20-06 | `platform.tenant.quota-threshold-reached.v1` | Chạm 80% hoặc 100% | PH-13, PH-18 | 029 |
| EVT-20-07 | `platform.tenant.module-enabled.v1` | Bật phân hệ | Phân hệ được bật | 034 |
| EVT-20-08 | `platform.tenant.module-disabled.v1` | Tắt, tạm ngừng phân hệ | Phân hệ bị tắt | 035 |
| EVT-20-09 | `platform.tenant.config-changed.v1` | Cấu hình hoặc cài đặt tỉnh đổi | PH-03, PH-12, `dh-console` | 018–021, 025 |
| EVT-20-10 | `platform.tenant.merge-started.v1` | Bắt đầu chuyển dữ liệu sáp nhập | Phân hệ có dữ liệu, PH-18 | 048 |
| EVT-20-11 | `platform.tenant.merge-cutover.v1` | Nguồn `MERGED`, chuyển tiếp bật | PH-03, PH-12, PH-01 | 051 |
| EVT-20-12 | `platform.tenant.merge-completed.v1` | Kết thúc sáp nhập | PH-13, PH-16, PH-03 | 052 |
| EVT-20-13 | `{tenant}.tenant.org.changed.v1` | Tổ chức tạo, sửa, ngừng, giải thể, kế thừa | PH-01, PH-06, PH-07, PH-08, PH-12, PH-16 | 053–056, 058 |
| EVT-20-14 | `platform.release.published.v1` | Phiên bản sang `PREVIEW` hoặc `STABLE` | PH-18 | 060 |
| EVT-20-15 | `platform.tenant.upgrade-changed.v1` | Nâng cấp một tenant đổi trạng thái | PH-13, PH-18 | 061, 062 |
| EVT-20-16 | `platform.tenant.export-ready.v1` | Gói bàn giao sẵn sàng | PH-18 | 041 |

: Sự kiện EVT-20-01…16 do PH-20 phát

| Sự kiện | Topic | PH-20 làm gì | FR |
|---|---|---|---|
| EVT-07-10 | `common.rdm.adminunit.reorganized.v1` | Sinh đề xuất đồng bộ tổ chức | 056 |
| EVT-12-13 | `{tenant}.iam.realm.changed.v1` | Cập nhật trạng thái realm trong registry | 019, 050 |
| EVT-09-21 | `{tenant}.privacy.crypto-shred.completed.v1` | Ghi xác nhận xóa mật mã, kết thúc chấm dứt | 042 |
| EVT-13-14 | `{tenant}.obs.capacity.warning.v1` | Đưa vào kiểm tra sẵn sàng và bảng điều khiển | 007, 067 |
| EVT-03-10 | `{tenant}.gateway.tenant-redirect.changed.v1` | Xác nhận chuyển tiếp đã bật, tắt | 051, 052 |
| EVT-03-11 | `{tenant}.gateway.limit.changed.v1` | Xác nhận hạn mức đã áp ở gateway | 027 |

: Sự kiện PH-20 tiêu thụ

### 9.4. Danh mục API

PH-20 công bố 171 API: 134 ở `/api/platform/v1` (PA, PO, PAU), 27 ở `/api/tenant/v1` (tenant lấy từ token), 10 ở `/internal/tenant/v1` (mTLS và scope dịch vụ). `POST` tạo hoặc chuyển trạng thái nhận `Idempotency-Key`; `PUT`, `PATCH` và hành động trên đối tượng có phiên bản cần `If-Match` (thiếu: ERR-00-428; lệch: ERR-20-005, 412). Lời gọi ra phân hệ khác ở chương 12.

| Mã | Phương thức | Đường dẫn | Mô tả | FR | Quyền hoặc scope |
|---|---|---|---|---|---|
| API-20-001 | GET | `/api/platform/v1/tenants` | Liệt kê, tìm, lọc tenant toàn nền tảng; `format=csv` để xuất; lọc theo kênh phát hành | 002, 060 | `PERM-20-read` |
| API-20-002 | POST | `/api/platform/v1/tenants` | Khai báo tenant mới ở `PROVISIONING` (chưa chạy saga) | 001 | `PERM-20-provision` |
| API-20-003 | GET | `/api/platform/v1/tenants/{tenantCode}` | Chi tiết tenant, khối tóm tắt | 003 | `PERM-20-read` |
| API-20-004 | PATCH | `/api/platform/v1/tenants/{tenantCode}` | Sửa hồ sơ hành chính (`If-Match`) | 004 | `PERM-20-admin` |
| API-20-005 | POST | `/api/platform/v1/tenants:check-readiness` | Kiểm tra sẵn sàng cho hồ sơ chưa lưu | 001, 007 | `PERM-20-provision` |
| API-20-006 | POST | `/api/platform/v1/tenants/{tenantCode}:check-readiness` | Kiểm tra lại sẵn sàng trước khi chạy saga | 007 | `PERM-20-provision` |
| API-20-007 | GET | `/api/platform/v1/tenants/{tenantCode}/contacts` | Danh sách đầu mối | 005 | `PERM-20-read` |
| API-20-008 | POST | `/api/platform/v1/tenants/{tenantCode}/contacts` | Thêm đầu mối | 005 | `PERM-20-admin` |
| API-20-009 | PATCH | `/api/platform/v1/tenants/{tenantCode}/contacts/{contactId}` | Sửa, ngừng đầu mối | 005 | `PERM-20-admin` |
| API-20-010 | GET | `/api/platform/v1/tenants/{tenantCode}/contracts` | Danh sách hợp đồng dịch vụ | 005 | `PERM-20-read` |
| API-20-011 | POST | `/api/platform/v1/tenants/{tenantCode}/contracts` | Thêm hợp đồng dịch vụ | 005 | `PERM-20-admin` |
| API-20-012 | PATCH | `/api/platform/v1/tenants/{tenantCode}/contracts/{contractId}` | Sửa, gia hạn hợp đồng | 005 | `PERM-20-admin` |
| API-20-013 | POST | `/api/platform/v1/tenants/{tenantCode}/provisioning-runs` | Chạy saga (`INITIAL`, `SUPPLEMENT`) | 008, 016 | `PERM-20-provision` |
| API-20-014 | GET | `/api/platform/v1/tenants/{tenantCode}/provisioning-runs` | Các lần chạy saga của tenant | 009 | `PERM-20-read` |
| API-20-015 | GET | `/api/platform/v1/provisioning-runs/{runId}` | Chi tiết lần chạy kèm sổ bước, kết quả kiểm tra khói | 009, 012 | `PERM-20-read` |
| API-20-016 | GET | `/api/platform/v1/provisioning-runs/{runId}/stream` | Luồng SSE tiến độ thời gian thực | 009 | `PERM-20-read` |
| API-20-017 | POST | `/api/platform/v1/provisioning-runs/{runId}:retry` | Thử lại từ bước lỗi đầu tiên | 010 | `PERM-20-provision` |
| API-20-018 | POST | `/api/platform/v1/provisioning-runs/{runId}/steps/{stepCode}:retry` | Thử lại một bước | 010 | `PERM-20-provision` |
| API-20-019 | POST | `/api/platform/v1/provisioning-runs/{runId}/steps/{stepCode}:skip` | Bỏ qua bước không bắt buộc có lý do | 010 | `PERM-20-provision` |
| API-20-020 | POST | `/api/platform/v1/provisioning-runs/{runId}:compensate` | Bù trừ ngược các bước đã xong | 011 | `PERM-20-provision` |
| API-20-021 | POST | `/api/platform/v1/provisioning-runs/{runId}:cancel` | Hủy khởi tạo (bù trừ rồi `CANCELLED`) | 011 | `PERM-20-provision` |
| API-20-022 | POST | `/api/platform/v1/tenants/{tenantCode}/smoke-tests` | Chạy lại kiểm tra khói | 012 | `PERM-20-provision` |
| API-20-023 | POST | `/api/platform/v1/tenants/{tenantCode}:activate` | Kích hoạt và bàn giao | 013 | `PERM-20-provision` |
| API-20-024 | GET | `/api/platform/v1/provisioning-metrics` | Thời gian khởi tạo theo tenant, theo bước | 014 | `PERM-20-read` |
| API-20-025 | GET | `/api/platform/v1/provisioning-templates` | Danh sách mẫu khởi tạo | 015 | `PERM-20-read` |
| API-20-026 | POST | `/api/platform/v1/provisioning-templates` | Tạo mẫu khởi tạo, phiên bản 1 `DRAFT` | 015 | `PERM-20-admin` |
| API-20-027 | GET | `/api/platform/v1/provisioning-templates/{templateCode}` | Chi tiết mẫu và các phiên bản | 015 | `PERM-20-read` |
| API-20-028 | POST | `/api/platform/v1/provisioning-templates/{templateCode}/versions` | Mở phiên bản mới từ bản đang dùng | 015 | `PERM-20-admin` |
| API-20-029 | GET | `/api/platform/v1/provisioning-templates/{templateCode}/versions/{version}` | Nội dung một phiên bản, so sánh (`compareTo`) | 015 | `PERM-20-read` |
| API-20-030 | PATCH | `/api/platform/v1/provisioning-templates/{templateCode}/versions/{version}` | Sửa phiên bản `DRAFT` | 015 | `PERM-20-admin` |
| API-20-031 | POST | `/api/platform/v1/provisioning-templates/{templateCode}/versions/{version}:publish` | Phát hành phiên bản mẫu | 015 | `PERM-20-admin` |
| API-20-032 | POST | `/api/platform/v1/provisioning-templates/{templateCode}/versions/{version}:retire` | Ngừng phiên bản mẫu | 015 | `PERM-20-admin` |
| API-20-033 | POST | `/api/platform/v1/supplement-plans:preview` | Xem trước tenant cần khởi tạo bổ sung | 016 | `PERM-20-provision` |
| API-20-034 | POST | `/api/platform/v1/supplement-plans` | Lập đợt khởi tạo bổ sung hàng loạt | 016 | `PERM-20-provision` |
| API-20-035 | GET | `/api/platform/v1/clusters` | Danh sách cụm đích `DEDICATED_CLUSTER` | 017 | `PERM-20-read` |
| API-20-036 | POST | `/api/platform/v1/clusters` | Đăng ký cụm đích | 017 | `PERM-20-provision` |
| API-20-037 | POST | `/api/platform/v1/clusters/{clusterCode}:verify` | Kiểm tra cụm đạt yêu cầu | 017 | `PERM-20-provision` |
| API-20-038 | POST | `/api/platform/v1/tenants/{tenantCode}/dedicated-bundle` | Sinh gói cấu hình cho cụm riêng | 017 | `PERM-20-provision` |
| API-20-039 | GET | `/api/platform/v1/tenants/{tenantCode}/platform-config` | Cấu hình nền tảng của tenant kèm trạng thái ghi Git, áp Argo CD | 019, 020 | `PERM-20-read` |
| API-20-040 | PUT | `/api/platform/v1/tenants/{tenantCode}/platform-config` | Sửa cấu hình nền tảng (`If-Match`) | 019, 020 | `PERM-20-admin` |
| API-20-041 | GET | `/api/platform/v1/tenants/{tenantCode}/config-versions` | Lịch sử phiên bản cấu hình | 021 | `PERM-20-read` |
| API-20-042 | GET | `/api/platform/v1/tenants/{tenantCode}/config-versions/{versionNo}` | Nội dung phiên bản, so sánh (`compareTo`) | 021 | `PERM-20-read` |
| API-20-043 | POST | `/api/platform/v1/tenants/{tenantCode}/config-versions/{versionNo}:restore` | Khôi phục phiên bản cấu hình | 021 | `PERM-20-admin` |
| API-20-044 | GET | `/api/platform/v1/tenants/{tenantCode}/config-drifts` | Lệch cấu hình của tenant | 022 | `PERM-20-read` |
| API-20-045 | POST | `/api/platform/v1/tenants/{tenantCode}/config:reconcile` | Đối chiếu ngay | 022 | `PERM-20-admin` |
| API-20-046 | POST | `/api/platform/v1/tenants/{tenantCode}/config-drifts/{driftId}:resolve` | Xử lý một lệch (áp lại hoặc nhận vào Git) | 022 | `PERM-20-admin` |
| API-20-047 | POST | `/api/platform/v1/tenants/{tenantCode}/isolation-changes` | Đề nghị chuyển chế độ cách ly | 025 | `PERM-20-lifecycle` |
| API-20-048 | GET | `/api/platform/v1/tenants/{tenantCode}/quotas` | Hạn mức hợp đồng, ghi đè, hiệu lực | 026, 032 | `PERM-20-read` |
| API-20-049 | PUT | `/api/platform/v1/tenants/{tenantCode}/quotas` | Đặt hạn mức hợp đồng ban đầu hoặc tăng trong trần | 026 | `PERM-20-quota` |
| API-20-050 | POST | `/api/platform/v1/tenants/{tenantCode}/quota-change-requests` | Đề nghị đổi hạn mức có duyệt | 027 | `PERM-20-quota` |
| API-20-051 | GET | `/api/platform/v1/tenants/{tenantCode}/quota-change-requests` | Các đề nghị đổi hạn mức | 027 | `PERM-20-read` |
| API-20-052 | POST | `/api/platform/v1/quota-change-requests/{requestId}:approve` | Duyệt đề nghị đổi hạn mức | 027 | `PERM-20-approve` |
| API-20-053 | POST | `/api/platform/v1/quota-change-requests/{requestId}:reject` | Từ chối đề nghị đổi hạn mức | 027 | `PERM-20-approve` |
| API-20-054 | POST | `/api/platform/v1/tenants/{tenantCode}/quota-overrides` | Ghi đè hạn mức tạm thời | 032 | `PERM-20-quota` |
| API-20-055 | POST | `/api/platform/v1/tenants/{tenantCode}/quota-overrides/{overrideId}:revoke` | Thu hồi ghi đè trước hạn | 032 | `PERM-20-quota` |
| API-20-056 | GET | `/api/platform/v1/usage` | Sử dụng tài nguyên toàn nền tảng | 030 | `PERM-20-read` |
| API-20-057 | GET | `/api/platform/v1/tenants/{tenantCode}/usage` | Sử dụng tài nguyên của một tenant | 030 | `PERM-20-read` |
| API-20-058 | GET | `/api/platform/v1/quota-alerts` | Cảnh báo hạn mức toàn nền tảng | 029 | `PERM-20-read` |
| API-20-059 | POST | `/api/platform/v1/quota-alerts/{alertId}:acknowledge` | Xác nhận đã xử lý cảnh báo | 029 | `PERM-20-quota` |
| API-20-060 | POST | `/api/platform/v1/usage-reports` | Lập báo cáo sử dụng theo kỳ | 031 | `PERM-20-read` |
| API-20-061 | GET | `/api/platform/v1/usage-reports` | Danh sách báo cáo sử dụng | 031 | `PERM-20-read` |
| API-20-062 | GET | `/api/platform/v1/usage-reports/{reportId}/file` | Tải tệp báo cáo | 031 | `PERM-20-read` |
| API-20-063 | GET | `/api/platform/v1/modules` | Danh mục phân hệ và ma trận phụ thuộc | 033 | `PERM-20-read` |
| API-20-064 | GET | `/api/platform/v1/tenants/{tenantCode}/modules` | Phân hệ theo tenant | 034, 035 | `PERM-20-read` |
| API-20-065 | POST | `/api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:enable` | Bật phân hệ | 034 | `PERM-20-admin` |
| API-20-066 | POST | `/api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:disable` | Tắt phân hệ | 035 | `PERM-20-admin` |
| API-20-067 | POST | `/api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:suspend` | Tạm ngừng phân hệ | 035 | `PERM-20-admin` |
| API-20-068 | POST | `/api/platform/v1/tenants/{tenantCode}/modules/{moduleCode}:resume` | Tiếp tục phân hệ tạm ngừng | 035 | `PERM-20-admin` |
| API-20-069 | GET | `/api/platform/v1/tenants/{tenantCode}/feature-flags` | Cờ tính năng của tenant | 036 | `PERM-20-read` |
| API-20-070 | PUT | `/api/platform/v1/tenants/{tenantCode}/feature-flags/{flagCode}` | Đặt cờ tính năng | 036 | `PERM-20-admin` |
| API-20-071 | POST | `/api/platform/v1/tenants/{tenantCode}/lifecycle-requests` | Lập đề nghị vòng đời (`SUSPEND`, `RESUME`, `TERMINATE`) | 038, 039, 040 | `PERM-20-lifecycle` |
| API-20-072 | GET | `/api/platform/v1/tenants/{tenantCode}/lifecycle-requests` | Đề nghị vòng đời của tenant | 043 | `PERM-20-read` |
| API-20-073 | GET | `/api/platform/v1/lifecycle-requests` | Hộp duyệt đề nghị toàn nền tảng | 040 | `PERM-20-read` |
| API-20-074 | GET | `/api/platform/v1/lifecycle-requests/{requestId}` | Chi tiết đề nghị | 040, 043 | `PERM-20-read` |
| API-20-075 | POST | `/api/platform/v1/lifecycle-requests/{requestId}:submit` | Gửi duyệt đề nghị | 040 | `PERM-20-lifecycle` |
| API-20-076 | POST | `/api/platform/v1/lifecycle-requests/{requestId}:approve` | Duyệt đề nghị (bốn mắt) | 025, 040 | `PERM-20-approve` |
| API-20-077 | POST | `/api/platform/v1/lifecycle-requests/{requestId}:reject` | Từ chối đề nghị | 025, 040 | `PERM-20-approve` |
| API-20-078 | POST | `/api/platform/v1/lifecycle-requests/{requestId}:cancel` | Rút đề nghị | 040 | `PERM-20-lifecycle` |
| API-20-079 | POST | `/api/platform/v1/lifecycle-requests/{requestId}:execute` | Thực hiện đề nghị đã duyệt | 025, 038, 039, 042 | `PERM-20-lifecycle` |
| API-20-080 | POST | `/api/platform/v1/tenants/{tenantCode}/export-packages` | Yêu cầu gói bàn giao dữ liệu | 041 | `PERM-20-lifecycle` |
| API-20-081 | GET | `/api/platform/v1/tenants/{tenantCode}/export-packages` | Danh sách gói bàn giao | 041 | `PERM-20-read` |
| API-20-082 | GET | `/api/platform/v1/export-packages/{packageId}` | Chi tiết gói, tiến độ theo phân hệ | 041 | `PERM-20-read` |
| API-20-083 | POST | `/api/platform/v1/export-packages/{packageId}:issue-link` | Cấp liên kết tải có thời hạn | 041 | `PERM-20-lifecycle` |
| API-20-084 | POST | `/api/platform/v1/export-packages/{packageId}:confirm-delivery` | Ghi nhận đã bàn giao, biên bản | 041 | `PERM-20-lifecycle` |
| API-20-085 | GET | `/api/platform/v1/tenants/{tenantCode}/status-history` | Lịch sử trạng thái và quyết định | 043, 044 | `PERM-20-read` |
| API-20-086 | POST | `/api/platform/v1/merge-plans` | Lập kế hoạch sáp nhập `DRAFT` | 045 | `PERM-20-merge` |
| API-20-087 | GET | `/api/platform/v1/merge-plans` | Danh sách sáp nhập | 045 | `PERM-20-read` |
| API-20-088 | GET | `/api/platform/v1/merge-plans/{mergePlanId}` | Chi tiết kế hoạch, tiến độ | 045, 048 | `PERM-20-read` |
| API-20-089 | PATCH | `/api/platform/v1/merge-plans/{mergePlanId}` | Sửa kế hoạch `DRAFT` | 045 | `PERM-20-merge` |
| API-20-090 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:submit` | Gửi duyệt kế hoạch | 045 | `PERM-20-merge` |
| API-20-091 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:approve` | Duyệt kế hoạch (bốn mắt) | 045 | `PERM-20-approve` |
| API-20-092 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:reject` | Từ chối kế hoạch | 045 | `PERM-20-approve` |
| API-20-093 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:cancel` | Hủy kế hoạch trước cutover | 045 | `PERM-20-merge` |
| API-20-094 | GET | `/api/platform/v1/merge-plans/{mergePlanId}/mappings` | Bảng ánh xạ | 046 | `PERM-20-read` |
| API-20-095 | POST | `/api/platform/v1/merge-plans/{mergePlanId}/mappings:suggest` | Sinh gợi ý ánh xạ tự động | 046 | `PERM-20-merge` |
| API-20-096 | PUT | `/api/platform/v1/merge-plans/{mergePlanId}/mappings/{mappingId}` | Sửa một dòng ánh xạ | 046 | `PERM-20-merge` |
| API-20-097 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:dry-run` | Chạy thử sáp nhập | 047 | `PERM-20-merge` |
| API-20-098 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:start` | Bắt đầu chuyển dữ liệu | 048 | `PERM-20-merge` |
| API-20-099 | GET | `/api/platform/v1/merge-plans/{mergePlanId}/participants` | Tiến độ theo phân hệ | 048 | `PERM-20-read` |
| API-20-100 | POST | `/api/platform/v1/merge-plans/{mergePlanId}/participants/{module}:retry` | Chạy lại chuyển của một phân hệ | 048 | `PERM-20-merge` |
| API-20-101 | GET | `/api/platform/v1/merge-plans/{mergePlanId}/conflicts` | Danh sách xung đột | 049 | `PERM-20-read` |
| API-20-102 | POST | `/api/platform/v1/merge-plans/{mergePlanId}/conflicts/{conflictId}:resolve` | Quyết định một xung đột | 049 | `PERM-20-merge` |
| API-20-103 | POST | `/api/platform/v1/merge-plans/{mergePlanId}/conflicts:resolve-batch` | Quyết định hàng loạt | 049 | `PERM-20-merge` |
| API-20-104 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:transfer-identity` | Chuyển định danh, cấp song song thông tin xác thực | 050 | `PERM-20-merge` |
| API-20-105 | GET | `/api/platform/v1/merge-plans/{mergePlanId}/credentials` | Trạng thái thông tin xác thực song song của HTTT | 050 | `PERM-20-read` |
| API-20-106 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:cutover` | Chuyển tiếp, nguồn sang `MERGED` | 051 | `PERM-20-merge` |
| API-20-107 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:extend-transition` | Gia hạn thời gian chuyển tiếp | 052 | `PERM-20-merge` |
| API-20-108 | POST | `/api/platform/v1/merge-plans/{mergePlanId}:complete` | Kết thúc sáp nhập | 052 | `PERM-20-merge` |
| API-20-109 | GET | `/api/platform/v1/releases` | Danh mục phiên bản sản phẩm | 059 | `PERM-20-read` |
| API-20-110 | POST | `/api/platform/v1/releases` | Đăng ký phiên bản `DRAFT` | 059 | `PERM-20-release` |
| API-20-111 | GET | `/api/platform/v1/releases/{releaseVersion}` | Chi tiết phiên bản, thành phần, tenant đang chạy | 059 | `PERM-20-read` |
| API-20-112 | PATCH | `/api/platform/v1/releases/{releaseVersion}` | Sửa ghi chú phát hành | 059 | `PERM-20-release` |
| API-20-113 | POST | `/api/platform/v1/releases/{releaseVersion}:preview` | Đưa phiên bản lên kênh `PREVIEW` | 060 | `PERM-20-release` |
| API-20-114 | POST | `/api/platform/v1/releases/{releaseVersion}:promote` | Nâng phiên bản lên `STABLE` | 060 | `PERM-20-release` |
| API-20-115 | POST | `/api/platform/v1/releases/{releaseVersion}:deprecate` | Đánh dấu ngoài hỗ trợ | 059 | `PERM-20-release` |
| API-20-116 | POST | `/api/platform/v1/releases/{releaseVersion}:withdraw` | Rút phiên bản lỗi | 059 | `PERM-20-release` |
| API-20-117 | PUT | `/api/platform/v1/tenants/{tenantCode}/release-subscription` | Đổi kênh, môi trường đăng ký của tenant | 060 | `PERM-20-release` |
| API-20-118 | POST | `/api/platform/v1/releases/{releaseVersion}/upgrade-plans` | Lập kế hoạch nâng cấp theo sóng | 061 | `PERM-20-release` |
| API-20-119 | GET | `/api/platform/v1/upgrade-plans/{planId}` | Chi tiết kế hoạch, sóng, tiến độ | 061, 062 | `PERM-20-read` |
| API-20-120 | PATCH | `/api/platform/v1/upgrade-plans/{planId}` | Sửa kế hoạch `DRAFT` | 061 | `PERM-20-release` |
| API-20-121 | POST | `/api/platform/v1/upgrade-plans/{planId}:schedule` | Lên lịch kế hoạch | 061 | `PERM-20-release` |
| API-20-122 | POST | `/api/platform/v1/upgrade-plans/{planId}:pause` | Dừng sóng | 062 | `PERM-20-release` |
| API-20-123 | POST | `/api/platform/v1/upgrade-plans/{planId}:resume` | Tiếp tục sóng | 062 | `PERM-20-release` |
| API-20-124 | POST | `/api/platform/v1/upgrade-plans/{planId}:rollback` | Quay lui tenant đã nâng cấp | 062 | `PERM-20-release` |
| API-20-125 | POST | `/api/platform/v1/upgrade-plans/{planId}:cancel` | Hủy kế hoạch chưa chạy | 062 | `PERM-20-release` |
| API-20-126 | GET | `/api/platform/v1/upgrade-plans/{planId}/tenant-upgrades` | Nâng cấp theo tenant | 062 | `PERM-20-read` |
| API-20-127 | POST | `/api/platform/v1/upgrade-plans/{planId}/tenant-upgrades/{tenantCode}:retry` | Thử lại nâng cấp một tenant | 062 | `PERM-20-release` |
| API-20-128 | POST | `/api/platform/v1/releases/{releaseVersion}:announce` | Gửi thông báo phát hành, lịch bảo trì | 063 | `PERM-20-release` |
| API-20-129 | GET | `/api/platform/v1/dashboard` | Bảng điều khiển nền tảng đa tenant | 067 | `PERM-20-read` |
| API-20-130 | GET | `/api/platform/v1/audit-events` | Nhật ký kiểm toán PH-20 toàn nền tảng | 068 | `PERM-20-read` (PA, PAU) |
| API-20-131 | GET | `/api/platform/v1/parameters` | Giá trị hiệu lực của tham số `20.*` | 069 | `PERM-20-read` |
| API-20-132 | POST | `/api/platform/v1/leak-tests` | Chạy kiểm thử rò rỉ chéo tenant ngay | 070 | `PERM-20-admin` |
| API-20-133 | GET | `/api/platform/v1/leak-tests` | Danh sách lần kiểm thử rò rỉ | 070 | `PERM-20-read` |
| API-20-134 | GET | `/api/platform/v1/leak-tests/{testRunId}` | Kết quả từng ca kiểm thử rò rỉ | 070 | `PERM-20-read` |
| API-20-135 | GET | `/api/tenant/v1/settings` | Cài đặt tỉnh | 018, 064 | `PERM-20-org-read` |
| API-20-136 | PUT | `/api/tenant/v1/settings` | Sửa cài đặt tỉnh (`If-Match`) | 018 | `PERM-20-settings` |
| API-20-137 | GET | `/api/tenant/v1/cross-tenant-policy` | Chính sách tiếp nhận liên tenant | 023 | `PERM-20-settings` hoặc SO, AU đọc |
| API-20-138 | PUT | `/api/tenant/v1/cross-tenant-policy` | Sửa chính sách tiếp nhận liên tenant | 023 | `PERM-20-settings` |
| API-20-139 | GET | `/api/tenant/v1/cross-tenant-access-log` | Nhật ký truy cập liên tenant vào tỉnh | 024 | `PERM-20-settings` hoặc SO, AU đọc |
| API-20-140 | GET | `/api/tenant/v1/usage` | Sử dụng tài nguyên của tỉnh | 030 | `PERM-20-usage-read` |
| API-20-141 | GET | `/api/tenant/v1/quotas` | Hạn mức hiệu lực và cảnh báo của tỉnh | 030 | `PERM-20-usage-read` |
| API-20-142 | GET | `/api/tenant/v1/context` | Trạng thái tenant, phân hệ đang bật, dải cảnh báo cho `dh-console` | 037, 066 | Mọi người dùng đã đăng nhập |
| API-20-143 | GET | `/api/tenant/v1/organizations` | Danh mục tổ chức (cây, bảng) | 053 | `PERM-20-org-read` |
| API-20-144 | POST | `/api/tenant/v1/organizations` | Tạo tổ chức | 053 | `PERM-20-org` |
| API-20-145 | GET | `/api/tenant/v1/organizations/{orgCode}` | Chi tiết tổ chức | 053 | `PERM-20-org-read` |
| API-20-146 | PATCH | `/api/tenant/v1/organizations/{orgCode}` | Sửa tổ chức (`If-Match`) | 053 | `PERM-20-org` |
| API-20-147 | POST | `/api/tenant/v1/organizations/{orgCode}:deactivate` | Ngừng tổ chức | 054 | `PERM-20-org` |
| API-20-148 | POST | `/api/tenant/v1/organizations/{orgCode}:reactivate` | Hoạt động lại tổ chức | 054 | `PERM-20-org` |
| API-20-149 | POST | `/api/tenant/v1/organizations/{orgCode}:dissolve` | Giải thể tổ chức có kế thừa | 054 | `PERM-20-org` |
| API-20-150 | POST | `/api/tenant/v1/organizations:merge` | Sáp nhập nhiều tổ chức vào một tổ chức | 054 | `PERM-20-org` |
| API-20-151 | GET | `/api/tenant/v1/organizations/{orgCode}/history` | Lịch sử hiệu lực, kế thừa | 054 | `PERM-20-org-read` |
| API-20-152 | PUT | `/api/tenant/v1/organizations/{orgCode}/data-owner` | Đánh dấu, bỏ đánh dấu chủ quản dữ liệu | 058 | `PERM-20-org` |
| API-20-153 | POST | `/api/tenant/v1/organization-imports` | Tải tệp nhập, sinh xem trước | 055 | `PERM-20-org` |
| API-20-154 | GET | `/api/tenant/v1/organization-imports/{importId}` | Kết quả kiểm từng dòng | 055 | `PERM-20-org` |
| API-20-155 | POST | `/api/tenant/v1/organization-imports/{importId}:confirm` | Xác nhận nhập | 055 | `PERM-20-org` |
| API-20-156 | GET | `/api/tenant/v1/organizations:export` | Xuất danh mục tổ chức, tải tệp mẫu | 055 | `PERM-20-org-read` |
| API-20-157 | GET | `/api/tenant/v1/organization-sync-proposals` | Đề xuất đồng bộ do sắp xếp ĐVHC | 056 | `PERM-20-org` |
| API-20-158 | POST | `/api/tenant/v1/organization-sync-proposals/{proposalId}:decide` | Áp hoặc bỏ đề xuất đồng bộ | 056 | `PERM-20-org` |
| API-20-159 | GET | `/api/tenant/v1/release-info` | Phiên bản đang chạy, ghi chú phát hành, lịch bảo trì | 064 | `PERM-20-org-read` |
| API-20-160 | PUT | `/api/tenant/v1/maintenance-window` | Đặt cửa sổ bảo trì ưa thích của tỉnh | 018, 061 | `PERM-20-settings` |
| API-20-161 | GET | `/api/tenant/v1/audit-events` | Nhật ký kiểm toán PH-20 của tỉnh | 068 | TA, AU |
| API-20-162 | GET | `/internal/tenant/v1/tenants` | Registry tenant (`?status=ACTIVE` cho tác vụ nền) | 065 | Scope `tenant:registry-read` |
| API-20-163 | GET | `/internal/tenant/v1/tenants/{tenantCode}` | Bản ghi registry của một tenant kèm phân hệ đang bật | 037, 065, 066 | Scope `tenant:registry-read` |
| API-20-164 | GET | `/internal/tenant/v1/tenants/{tenantCode}/enforcement` | Hạn mức hiệu lực, host, tiền tố, ánh xạ chuyển tiếp cho PH-03, PH-04, PH-10 | 026, 027, 051, 066 | Scope `tenant:registry-read` |
| API-20-165 | GET | `/internal/tenant/v1/tenants/{tenantCode}/cross-tenant-policy` | Chính sách tiếp nhận cho PH-12 | 023 | Scope `tenant:registry-read` |
| API-20-166 | POST | `/internal/tenant/v1/provisioning-runs/{runId}/steps/{stepCode}:report` | Phân hệ báo tiến độ bước saga bất đồng bộ | 008, 034 | Scope `tenant:provision-report` |
| API-20-167 | POST | `/internal/tenant/v1/merge-plans/{mergePlanId}/participants/{module}:report` | PH-18, phân hệ tham gia báo tiến độ chuyển sáp nhập | 047, 048 | Scope `tenant:provision-report` |
| API-20-168 | POST | `/internal/tenant/v1/export-packages/{packageId}/items/{module}:report` | Phân hệ báo đã xuất phần dữ liệu của mình | 041 | Scope `tenant:provision-report` |
| API-20-169 | GET | `/internal/tenant/v1/organizations` | Đọc tổ chức của tenant ngữ cảnh | 057 | Scope `tenant:org-read` |
| API-20-170 | GET | `/internal/tenant/v1/organizations/{orgCode}` | Đọc một tổ chức, kể cả đã giải thể | 057 | Scope `tenant:org-read` |
| API-20-171 | POST | `/internal/tenant/v1/organizations:lookup` | Tra hàng loạt tối đa 500 mã | 057, 058 | Scope `tenant:org-read` |

: Danh mục API-20-001…171

## 10. Giao diện người dùng

### 10.1. Danh sách màn hình

Mẫu trang PTN theo D03-06-00, thành phần `CMP-*` theo D03-05-03, D03-05-04; `/nen-tang/*` chỉ cho tenant `PLATFORM`.

| Mã | Tên | Route | Mẫu trang | Vai trò | FR |
|---|---|---|---|---|---|
| UI-20-01 | Danh sách tenant | `/nen-tang/tenant` | PTN-01 | PA, PO, PAU | 002 |
| UI-20-02 | Khai báo tenant (wizard 5 bước) | `/nen-tang/tenant/moi` | PTN-05 | PA | 001, 007, 008, 017 |
| UI-20-03 | Chi tiết tenant (7 tab) | `/nen-tang/tenant/{ma-tenant}` | PTN-02 | PA, PO, PAU | 003–005, 008, 017, 019, 020, 025, 043, 060, 068 |
| UI-20-04 | Tiến độ khởi tạo | `/nen-tang/tenant/{ma-tenant}/khoi-tao` | PTN-11 | PA, PO | 007–013, 016 |
| UI-20-05 | Hạn mức tenant | `/nen-tang/tenant/{ma-tenant}/han-muc` | PTN-03 | PA | 026, 027, 032 |
| UI-20-06 | Sử dụng tài nguyên toàn nền tảng | `/nen-tang/su-dung` | PTN-06 | PA, PO | 028–031 |
| UI-20-07 | Phân hệ và tính năng của tenant | `/nen-tang/tenant/{ma-tenant}/phan-he` | PTN-12 | PA | 033–036 |
| UI-20-08 | Đổi trạng thái tenant | `/nen-tang/tenant/{ma-tenant}/vong-doi` | PTN-04 | PA | 038–042 |
| UI-20-09 | Lập kế hoạch sáp nhập (wizard) | `/nen-tang/sap-nhap/moi` | PTN-05 | PA | 045–047 |
| UI-20-10 | Theo dõi sáp nhập | `/nen-tang/sap-nhap/{ma-sap-nhap}` | PTN-02 | PA, PO, TA hai tỉnh (chỉ đọc) | 047–052 |
| UI-20-11 | Danh sách sáp nhập | `/nen-tang/sap-nhap` | PTN-01 | PA, PO | 045 |
| UI-20-12 | Cài đặt tỉnh | `/quan-tri/cai-dat-tinh` | PTN-12 | TA | 018, 061, 063, 064 |
| UI-20-13 | Sử dụng tài nguyên của tỉnh | `/quan-tri/cai-dat-tinh/su-dung` | PTN-06 | TA, TO, AU | 028–030 |
| UI-20-14 | Danh mục tổ chức (cây và bảng) | `/quan-tri/to-chuc` | PTN-08 | TA, DS, VW | 053–056, 058 |
| UI-20-15 | Chi tiết, biểu mẫu tổ chức | `/quan-tri/to-chuc/{ma-to-chuc}` | PTN-02, PTN-03 | TA | 053, 054, 058 |
| UI-20-16 | Nhập tổ chức | `/quan-tri/to-chuc/nhap` | PTN-09 | TA | 055 |
| UI-20-17 | Phiên bản và lệch cấu hình | `/nen-tang/tenant/{ma-tenant}/lich-su` | PTN-02 | PA, PO | 020–022 |
| UI-20-18 | Phiên bản sản phẩm và kênh | `/nen-tang/phat-hanh` | PTN-01 | PA, PO | 059, 060 |
| UI-20-19 | Kế hoạch nâng cấp theo sóng | `/nen-tang/phat-hanh/{phien-ban}/ke-hoach` | PTN-05, PTN-11 | PA, PO | 061–063 |
| UI-20-20 | Bảng điều khiển đa tenant | `/nen-tang/tong-quan` | PTN-06 | PA, PO, PAU | 014, 016, 067, 070 |
| UI-20-21 | Mẫu khởi tạo | `/nen-tang/mau-khoi-tao` | PTN-01, PTN-03 | PA | 015, 017 |
| UI-20-22 | Truy cập liên tenant vào tỉnh | `/quan-tri/cai-dat-tinh/lien-tenant` | PTN-12, PTN-11 | TA, SO, AU | 023, 024 |

: Màn hình UI-20-01…22

### 10.2. Hai giao diện tiêu biểu

**UI-20-04 Tiến độ khởi tạo.** Đầu trang: mã tenant, `CMP-StatusTag` trạng thái lần chạy, đồng hồ tổng thời gian so với ngưỡng 60 phút, nút "Thử lại", "Bỏ qua bước", "Bù trừ và hủy" (mỗi nút mở `CMP-ReasonDialog`). Thân: `CMP-Steps` dọc 17 bước, nhóm song song `S06`, `S09`, `S10`, `S12` hiện cạnh nhau; mỗi bước có bên thực hiện, số lần thử, thời gian, mã lỗi gốc. Bảng bên phải là `CMP-JobProgress` nhận SSE; cuối trang `CMP-Timeline` các báo tiến độ. Khi bước lỗi, dòng bước đỏ, `CMP-Banner` nêu câu ERR-20-106 hoặc ERR-20-107 và gợi ý thao tác.

**UI-20-10 Theo dõi sáp nhập.** Đầu trang: mã kế hoạch, nguồn, đích, `CMP-StatusTag` `MergeStatus`, `CMP-Steps` ngang theo máy trạng thái 4.9. Tab "Phân hệ": `CMP-DataTable` mỗi dòng một phân hệ (thứ tự, trạng thái, bản ghi nguồn, đích, xung đột, kiểm đếm) và nút "Chạy lại phân hệ". Tab "Xung đột": `CMP-DataTable` lọc theo loại, `CMP-DiffViewer` so hai bản, chọn cách xử lý. Tab "Chuyển tiếp": HTTT và trạng thái thông tin xác thực song song, nút "Gia hạn". Nút "Thực hiện cutover" dùng `CMP-ConfirmDialog` yêu cầu gõ lại mã kế hoạch. TA của tỉnh nguồn, tỉnh đích chỉ thấy tab Chuyển tiếp của tỉnh mình.

## 11. Truy vết

### 11.1. Chức năng hệ cũ

| Mã hệ cũ | Nội dung | FR phủ |
|---|---|---|
| LGC-IAM-002 | Quản trị đơn vị, cấu hình theo đơn vị (đơn vị thành tổ chức DD-02) | FR-20-018, 053, 054, 055 |
| LGC-BUS-031 | Cấu hình kết nối theo tỉnh, triển khai tỉnh mới thủ công (thay bằng saga, GitOps) | FR-20-001, 008, 019, 020 |

: Chức năng hệ cũ được PH-20 phủ

### 11.2. Truy vết tới yêu cầu

| Nhóm FR | REQ | Yêu cầu hệ thống | An toàn |
|---|---|---|---|
| A FR-20-001…007 | REQ-20 | FR-00-011, NFR-00-060 | SEC-86 |
| B FR-20-008…017 | REQ-20 | NFR-00-057, KPI-12, BO-06 | SEC-85 |
| C FR-20-018…025 | REQ-20 | FR-00-012 | SEC-86, SEC-88 |
| D FR-20-026…032 | REQ-20 | NFR-00-060 | — |
| E FR-20-033…037 | REQ-20 | FR-00-011 | — |
| F FR-20-038…044 | REQ-20 | FR-00-071 | SEC-82 |
| G FR-20-045…052 | REQ-20 | FR-00-071 | SEC-82, SEC-86 |
| H FR-20-053…058 | REQ-20 | FR-00-010 | — |
| I FR-20-059…064 | REQ-20 | NFR-00-056 | SEC-85 |
| J FR-20-065…070 | REQ-20 | FR-00-011, FR-00-012 | SEC-87 |

: Truy vết nhóm FR tới REQ, yêu cầu hệ thống, an toàn

### 11.3. Không có SRS-PH-20

Không có SRS-PH-20 vì hệ cũ không có phân hệ quản trị tenant. Nguồn thay thế: D03-10 (đa tenant, saga, sáp nhập), D02-07 DD-01, DD-02, REQ-20, FR-00-010, 011, 012, 071, NFR-00-056, 057, 060 và KPI-12.

## 12. Phụ thuộc, giả định, ràng buộc

### 12.1. Hợp đồng với phân hệ khác

| Phân hệ | Hướng | Hợp đồng |
|---|---|---|
| PH-12 | PH-20 gọi | API-12-080 tạo realm (`S03_REALM`); API-12-084, 085 tạm ngừng, khôi phục realm; API-12-082, 083 lệch, đối chiếu; API-12-045, 046 kế hoạch và thực hiện chuyển định danh; nhận EVT-12-13; PH-12 đọc API-20-165 khi cấp truy cập liên tenant (FR-12-017, FR-12-027) |
| PH-13 | PH-20 gọi | API-13-072 khai báo quan sát cho tenant; API-13-073 đóng chuỗi kiểm toán; nhận EVT-13-14; Mimir là nguồn số liệu sử dụng |
| PH-07 | PH-20 gọi | API-07-073 gieo danh mục (FR-07-049); nhận EVT-07-10; ĐVHC ở `COMMON` |
| PH-10 | Sự kiện | Nghe EVT-20-01 (FR-10-064, 067), báo tiến độ `S06_EVENTING` qua API-20-166 |
| PH-03 | Sự kiện, API đọc | Đọc API-20-164 (host, tiền tố, trần hạn mức, chuyển tiếp) theo FR-03-037, 039 và `LimitCeilingRule` (ERR-03-018); thực thi ERR-20-001 ở APISIX; phát EVT-03-10, 11 |
| PH-04 | Sự kiện | Nghe EVT-20-01, tạo không gian `DEFAULT` và kho `dh-flows-{tenant}` (ADR-068), báo tiến độ |
| PH-01 | PH-01 gọi | API-20-169…171 tổ chức (đệm 24 giờ, ERR-01-004, ERR-01-046); nghe EVT-20-04, EVT-20-13 (Q01-10); cấp song song thông tin xác thực HTTT khi sáp nhập |
| PH-06, PH-08, PH-16 | Phân hệ gọi, sự kiện | Kiểm tổ chức chủ quản (API-20-171); PH-06 nạp gói nền khi khởi tạo; PH-16 FR-16-008 kế thừa mẫu, PH-20 đẩy KPI-12 qua API-16-030 |
| PH-09 | PH-20 gọi | FR-09-043 xóa mật mã khi chấm dứt; nhận EVT-09-21 |
| PH-18 | Hai chiều | Tham số (DD-14), thông báo (DD-13), sao lưu theo tenant. Sáp nhập: PH-20 gọi `POST /api/ops/v1/merge-transfers` (giả định; thân `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`) cho từng phân hệ; PH-18 và phân hệ tham gia báo tiến độ qua API-20-167 `POST /internal/tenant/v1/merge-plans/{mergePlanId}/participants/{module}:report` (scope `tenant:provision-report`); tác vụ nền của PH-18 lặp tenant qua API-20-162 `GET /internal/tenant/v1/tenants?status=ACTIVE` (scope `tenant:registry-read`) |
| PH-19, PH-17, PH-11, PH-14, PH-15 | Sự kiện | Nghe EVT-20-07, 08 (PH-19 FR-19-064, ERR-19-049); PH-17 mặc định `17.enabled` tắt |
| `dh-console` | Đọc | API-20-142 trạng thái phân hệ cho menu, dải cảnh báo `MERGING`, chế độ chỉ đọc khi `SUSPENDED` |

: Hợp đồng PH-20 với phân hệ khác

### 12.2. Giả định

Hợp đồng `merge-transfers` của PH-18 là giả định tới khi FRS PH-18 chốt (Q20-15); hạn mức sáu tài nguyên cuối của `QuotaResource` (Q20-05) và gói bàn giao 500 GB trong 24 giờ (Q20-02) là giả định; mỗi phân hệ có dữ liệu hiện thực hợp đồng bên tham gia sáp nhập trước kế hoạch sáp nhập đầu tiên.

### 12.3. Ràng buộc và quyết định kiến trúc đề xuất

PH-20 chạy trong DU `dh-platform`, schema `ph20_tenant`, mô-đun `vn.datahub.platform.tenant` và `vn.datahub.platform.release`, vai trò kết nối `ph20_platform_app`. Năm quyết định kiến trúc đề xuất (chưa có tệp, ghi ở Phụ lục B): ADR 200 saga khởi tạo trên PostgreSQL; ADR 201 GitOps cấu hình tenant qua `dh-tenant-config`; ADR 202 hợp đồng bên tham gia sáp nhập; ADR 203 kênh phát hành và nâng cấp theo sóng; ADR 204 đo sử dụng hằng giờ và hạn mức hiệu lực.

## 13. Câu hỏi mở

| Mã | Câu hỏi | Ảnh hưởng | Đề xuất tạm |
|---|---|---|---|
| Q20-01 | Văn bản pháp lý về sáp nhập tỉnh và thời hạn lưu dữ liệu tỉnh cũ | FR-045, 052 | Lưu 10 năm chỉ đọc |
| Q20-02 | Thời hạn, định dạng gói bàn giao khi chấm dứt | FR-041 | Parquet và JSON, 90 ngày |
| Q20-03 | Ai phía tỉnh phê duyệt chấm dứt; có khởi tạo trước khi ký hợp đồng không | FR-001, 040 | Lãnh đạo UBND tỉnh; cho khởi tạo `STAGING` |
| Q20-04 | Mã tenant có theo quy tắc T + mã ĐVHC | FR-001 | Có, ví dụ T68 |
| Q20-05 | Hạn mức mặc định sáu tài nguyên giả định | FR-026 | Theo 4.1 |
| Q20-06 | Có tính cước theo sử dụng | FR-031 | Ngoài v1.0 |
| Q20-07 | Cách đo `DATABASE_GB` ở chế độ `SHARED` | FR-028 | Ước theo `tenant_id` |
| Q20-08 | Cụm riêng kéo cấu hình hay được đẩy | FR-017 | Kéo qua Argo CD tại cụm |
| Q20-09 | Cho tenant `PROD` theo kênh `PREVIEW` | FR-060 | Không |
| Q20-10 | Cửa sổ bảo trì mặc định | FR-061 | Thứ Bảy 22:00, 4 giờ |
| Q20-11 | Có dùng mã định danh điện tử cơ quan làm khóa tổ chức | FR-053 | Lưu trường riêng, không làm khóa |
| Q20-12 | Gieo tổ chức cấp xã khi khởi tạo | FR-008, 053 | Gieo từ ĐVHC `COMMON` |
| Q20-13 | Giữ mật khẩu khi chuyển định danh sáp nhập | FR-050 | Buộc đặt lại |
| Q20-14 | Cơ chế ký commit GitOps | FR-020 | Ký bằng khóa dịch vụ ở Vault |
| Q20-15 | Hợp đồng `merge-transfers` với PH-18 | FR-047, 048 | Theo 12.1 |
| Q20-16 | Lệch tên topic với PH-19, PH-10 | 9.3 | Theo 9.3 |
| Q20-17 | PH-17 mặc định tắt khi khởi tạo | FR-034 | Tắt |
| Q20-18 | Ngoại lệ khẩn cho liên tenant và kiểm thử rò rỉ trên `PROD` | FR-023, 070 | Không cho |
| Q20-19 | Lịch ngày làm việc tính KPI-12 | FR-014 | Lịch nghỉ lễ do PH-18 quản |

: Câu hỏi mở Q20-01…19

## 14. Tiêu chí chấp nhận

1. Khai báo T68 và chạy saga 17 bước tới `ACTIVE` trong ≤ 60 phút trên `STAGING`, kiểm tra khói đạt, EVT-20-03 phát.
2. Bước lỗi giả lập được thử lại, bù trừ ngược, không còn tài nguyên mồ côi.
3. Tạm ngừng T68: mọi API trả ERR-20-001 trong ≤ 60 giây; khôi phục trở lại bình thường.
4. Chấm dứt bị chặn khi chưa bàn giao, chưa hết nguội hoặc cùng một người duyệt.
5. Sáp nhập thử T91 vào T90: chạy thử, chuyển, xung đột, cutover, chuyển tiếp có header `Deprecation`, kiểm đếm 100%.
6. Nhập 5.000 tổ chức xem trước ≤ 30 giây; giải thể tổ chức có tham chiếu buộc chọn kế thừa.
7. Nâng cấp theo sóng tự dừng khi lỗi vượt 2%; quay lui được khi không có `CONTRACT`.
8. Kiểm thử rò rỉ hằng đêm trên T90…T99 phủ 100% API, không phát hiện rò rỉ.
9. Mọi thao tác thay đổi có kiểm toán kèm lý do, phiếu; mọi sửa thiếu `If-Match` bị từ chối.

## Phụ lục A. Giá trị liệt kê

Nguồn chuẩn enum cho mọi tập PH-20.

| Liệt kê | Giá trị |
|---|---|
| `TenantStatus` | `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `MERGING`, `MERGED`, `DECOMMISSIONED`, `FAILED` |
| `IsolationMode` | `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` |
| `TenantKind` | `PROVINCE`, `PLATFORM`, `COMMON` |
| `ProvisioningRunStatus` | `PENDING`, `RUNNING`, `WAITING`, `FAILED`, `COMPENSATING`, `COMPENSATED`, `SUCCEEDED`, `CANCELLED` |
| `ProvisioningStepStatus` | `PENDING`, `RUNNING`, `WAITING_REPORT`, `SUCCEEDED`, `FAILED`, `SKIPPED`, `COMPENSATING`, `COMPENSATED` |
| `RunKind` | `INITIAL`, `SUPPLEMENT`, `ISOLATION_CHANGE` |
| `LifecycleRequestType` | `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE` |
| `RequestStatus` | `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED` |
| `SuspendReason` | `MANAGEMENT_DECISION`, `SECURITY_INCIDENT`, `CONTRACT_EXPIRED`, `TENANT_REQUEST`, `OTHER` |
| `QuotaResource` | `API_RPS`, `ACTIVE_FLOWS`, `KAFKA_PRODUCE_MBPS`, `KAFKA_CONSUME_MBPS`, `OBJECT_STORAGE_GB`, `DATABASE_GB`, `USERS`, `MEMBER_SYSTEMS`, `PUBLISHED_APIS`, `TOPICS`, `RUNTIME_CPU`, `RUNTIME_MEMORY_GB` |
| `QuotaAlertLevel` | `WARN_80`, `LIMIT_100` |
| `ModuleState` | `DISABLED`, `ENABLING`, `ENABLED`, `DISABLING`, `SUSPENDED`, `FAILED` |
| `MergeStatus` | `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `DRY_RUN`, `TRANSFERRING`, `CONFLICT_REVIEW`, `IDENTITY_TRANSFER`, `CUTOVER`, `TRANSITION`, `COMPLETED`, `CANCELLED`, `FAILED` |
| `MergeMappingType` | `ORGANIZATION`, `MEMBER_SYSTEM`, `CATALOG_CODE`, `API_CONTEXT_PATH`, `USER`, `TOPIC` |
| `MergeMappingAction` | `MAP`, `CREATE`, `SKIP` |
| `ConflictResolution` | `KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP` |
| `OrgType` | `PROVINCE_PC`, `DEPARTMENT`, `COMMUNE_PC`, `PUBLIC_UNIT`, `OTHER` |
| `OrgStatus` | `ACTIVE`, `INACTIVE`, `DISSOLVED`, `MERGED` |
| `ReleaseChannel` | `STABLE`, `PREVIEW` |
| `ReleaseStatus` | `DRAFT`, `PREVIEW`, `STABLE`, `DEPRECATED`, `WITHDRAWN` |
| `UpgradePlanStatus` | `DRAFT`, `SCHEDULED`, `RUNNING`, `PAUSED`, `COMPLETED`, `ROLLED_BACK`, `CANCELLED` |
| `TenantUpgradeStatus` | `PENDING`, `IN_WINDOW`, `UPGRADING`, `VERIFYING`, `DONE`, `FAILED`, `ROLLED_BACK`, `SKIPPED` |
| `ExportPackageStatus` | `REQUESTED`, `COLLECTING`, `READY`, `DELIVERED`, `EXPIRED`, `FAILED` |
| `DriftStatus` | `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN` |
| `TemplateState` | `DRAFT`, `PUBLISHED`, `RETIRED` |
| `ContactRole` | `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY` |
| `SmokeCheck` | `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK` |
| `AlertState` | `OPEN`, `ACKNOWLEDGED`, `RESOLVED` |
| `ConfigChangeKind` | `TENANT_PROFILE`, `TENANT_SETTINGS`, `PLATFORM_CONFIG`, `CROSS_TENANT_POLICY`, `ISOLATION_MODE`, `FEATURE_FLAG` |

: Giá trị liệt kê của PH-20

## Phụ lục B. Đề nghị đồng bộ

| Tài liệu | Đề nghị |
|---|---|
| D02-08 | Thêm 10 quyền: `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-approve`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-settings`, `PERM-20-org`, `PERM-20-org-read`, `PERM-20-usage-read` theo 3.2; thêm scope dịch vụ `tenant:registry-read`, `tenant:provision-report`, `tenant:org-read` |
| D02-07 | Kiểm và bổ sung nếu chưa có: DD-01 `merged_into_id`, `isolation_mode`, `tenant_kind`; DD-02 thêm `electronic_id`, `is_data_owner`, `successor_id`; thêm cột `origin_tenant_id` cho bảng nhận dữ liệu sáp nhập |
| D03-06-00 | Thêm mục menu `/quan-tri/to-chuc`, `/nen-tang/sap-nhap`, `/nen-tang/phat-hanh`, `/nen-tang/tong-quan`, `/nen-tang/su-dung`, `/nen-tang/mau-khoi-tao` |
| D03-10 | Thay 10 bước §5.2 bằng 17 bước của 4.4; thêm chuyển `MERGING → ACTIVE` (hủy trước cutover) và `FAILED → DECOMMISSIONED` (bù trừ khi khởi tạo lỗi) |
| D00-02 | Ghi năm quyết định ADR 200…204 ở 12.3 |
| D02-01 | Thêm BP-12 sáp nhập tenant, BP-13 phát hành và nâng cấp |
| PH-19 | Đổi tên topic nghe sang `platform.tenant.module-enabled.v1` |
| PH-10 | Đổi tên topic trong kiểm thử `dh.platform.tenant.created.v1` sang `platform.tenant.created.v1` |
| PH-16 | Q16-16 đã trả lời: PH-20 đẩy qua API-16-030, `metricCode` `thoi-gian-khoi-tao-tenant` |
| PH-18 | Chốt `POST /api/ops/v1/merge-transfers` theo 12.1; gọi API-20-167 báo tiến độ; dùng API-20-162 với `?status=ACTIVE`; đăng ký 29 khóa `20.*` của 8.2 |
| PH-12 | Nhận scope `iam:realm-provision` cho PH-20; đọc API-20-165 khi cấp truy cập liên tenant |
| PH-13 | Nhận EVT-20-12; nhãn `tenant` cho `dh_tenant_*` |
| PH-03 | Đọc API-20-164; phát EVT-03-10 khi bật, tắt chuyển tiếp |
| PH-07 | Cấp scope `platform.tenant.provision` cho PH-20 gọi API-07-073 |
| PH-01 | Q01-10: đổi chủ quản HTTT theo EVT-20-13 qua đề nghị chờ TA duyệt hàng loạt |
| FRS 0.3 | `quality`, `hour_start` (FR-20-028) lệch CSDL `is_estimate`, `captured_at`; `firstAt`, `lastAt` (EN-20-17) lệch OpenAPI |
| FRS 0.3 | EVT-20-01 phát sau `S05` hay khi khai báo; bù trừ `S01` giữ dòng `tenant`; `DECOMMISSIONED` ở giai đoạn 1 của FR-20-042 |
| FRS 0.3 | BR-20-022 một nguồn mỗi kế hoạch (Q20-50); lệnh xuất gói bàn giao cần sự kiện lệnh; tệp `database.yaml` cho `DEDICATED_DB` |
| FRS 0.3 | Hộp duyệt đổi hạn mức, hủy sáp nhập sau `IDENTITY_TRANSFER`, tiền điều kiện `T99`, gửi lại thông báo đổi trạng thái (UC A-02…05) |
| D02-08, CSDL | `PERM-20-*` đọc cho API-20-137, 139, 161; `suspendReason` thay `reason` (FR-20-038); bảng cho cụm riêng, đợt bổ sung, đề xuất tổ chức, thông báo phát hành |
| D03-06-PH20 | TA xem UI-20-10 (Q20-30), API-20-161 chưa có màn (Q20-35), hộp việc tập trung (Q20-34), mã lỗi dải `MERGING` |
| D05-01, D05-02 | Mã lỗi thiếu `Idempotency-Key`, `ERR-20-055` ở API-20-065, `ERR-20-060`, tenant hiệu năng `T01…T34` (ĐN-TC-03, 04, 06, 07, 08, 11) |

: Đề nghị đồng bộ với tài liệu khác

## Phụ lục C. Nhật ký hấp thụ đề nghị

Các lệch do sáu tập con nêu ở bản 0.1 đã xử lý ở bản 0.2.

| Nguồn đề nghị | Nội dung | Xử lý |
|---|---|---|
| CSDL, SDD L-01 | Chỉ mục `uq_provisioning_run_active` thiếu `PENDING` | CSDL thêm `PENDING` |
| CSDL, API | `TemplateState` dùng `ACTIVE`, `ContactRole` dùng `PRIMARY`, `BILLING` | CSDL theo FRS và OpenAPI; thêm vào Phụ lục A |
| SDD L-02, CSDL | Số tham số 19 và 28; khóa `20.usage.probe-interval` | 8.2 có 29 khóa |
| SDD L-13 | `20.registry.cache-seconds` tới 300 giây | Miền 10…60 |
| SDD L-03, TC | Tên ca kiểm tra khói | Theo OpenAPI; thêm `SmokeCheck` |
| SDD L-05, TC | Trạng thái cảnh báo `CLEARED` | `RESOLVED`; thêm `AlertState` |
| SDD L-06, TC, API | Mã chỉ tiêu KPI-12 | `thoi-gian-khoi-tao-tenant` của PH-16 |
| SDD L-07, TC | Mã bước `S03_IDENTITY` | `S03_REALM` |
| TC ĐN-TC-01, SDD, UC | Cửa sổ bảo trì 1…8 giờ | 2…6 giờ, ngoài giờ cao điểm |
| TC ĐN-TC-05, Q20-44, API | Rò rỉ chéo nhóm API: 403 hay 404 | Quyết định ở 6.1 |
| MH B-1, UC A-01 | Cột FR của UI-20-08, UI-20-20 và sáu màn khác | 10.1 khớp FR; UI-20-08 chỉ FR-038…042 |
| MH Q20-39, B-6 | Hai API ghi cửa sổ bảo trì | Giữ cả hai, phân vai ở FR-20-061 |
| TC, API | Tên trường ngoài OpenAPI; `changeKind` | TC theo OpenAPI; AsyncAPI thêm `changeKind` |
| UC, MH, TC, API | Câu thông báo lệch 9.2 | Sửa tập con theo nguyên văn |

: Nhật ký hấp thụ đề nghị ở bản 0.2

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ sáu tập con: 29 tham số, cửa sổ 2…6 giờ, quyết định 403 và 404, bổ sung Phụ lục A, Phụ lục C |

: Lịch sử phiên bản
