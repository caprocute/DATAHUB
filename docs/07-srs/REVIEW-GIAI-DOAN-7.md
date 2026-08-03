# Báo cáo rà soát & tích hợp — Giai đoạn 7

> **Phạm vi**: kiểm chứng tính nhất quán của bộ tài liệu SRS (19 tài liệu) và bộ mockup trước khi khép lại.
> **Ngày rà soát**: 2026-08-03 · **Phương pháp**: quét tự động toàn kho + đối chiếu thủ công.
> Checklist → [CHECKLIST.md](CHECKLIST.md) · Từ điển dữ liệu → [SRS-00](SRS-00-data-dictionary.md).

**Kết luận tổng thể**: bộ tài liệu **đạt điều kiện sử dụng**. Không có lỗi chặn. Tồn tại 3 nhóm việc phải xử lý ở giai đoạn sau, đã ghi rõ tại [§6](#6-danh-mục-tồn-đọng).

| Hạng mục | Kết quả | Chi tiết |
|---|---|---|
| 7.1 — FR ↔ thành phần kiến trúc | ✅ Đạt | [§1](#1-rà-soát-chéo-fr--thành-phần-kiến-trúc-71) |
| 7.2 — Phủ CMP-01…40 | ⚠️ Đạt có điều kiện | [§2](#2-phủ-tuân-thủ-cmp-0140-72) — 4 mục phủ ngoài SRS |
| 7.3 — Liên kết nội bộ | ✅ Đạt | [§3](#3-kiểm-chứng-liên-kết-nội-bộ-73) — 0 liên kết hỏng |
| 7.4 — UI ↔ mockup | ⚠️ Đạt có điều kiện | [§4](#4-rà-soát-ui--mockup-74) — 61/124 màn đã dựng |
| 7.5 — Cập nhật wiki & memory | ✅ Đạt | [§5](#5-cập-nhật-wiki--memory-75) |

---

## 1. Rà soát chéo: FR ↔ thành phần kiến trúc (7.1)

**Cách kiểm.** Lấy bảng trách nhiệm thành phần tại [02-architecture §4.2](../02-architecture/README.md#42-thuyết-minh-phân-rã-thành-phần), đối chiếu từng phân hệ SRS với thành phần hiện thực nó. Yêu cầu: **mọi phân hệ có FR đều phải neo được vào ít nhất một thành phần kiến trúc**, và ngược lại mọi thành phần kiến trúc phải có phân hệ đặc tả.

### 1.1. Ánh xạ phân hệ → thành phần

| Phân hệ | Số FR | Thành phần kiến trúc hiện thực | Trạng thái |
|---|:-:|---|:-:|
| PH-01 Kết nạp | 15 | Onboarding Service | ✓ |
| PH-02 API & Danh mục | 14 | API Manager · Service Catalog | ✓ |
| PH-03 Cổng tiếp nhận | 17 | APISIX Gateway | ✓ |
| PH-04 Lõi tích hợp | 40 | Integration Runtime (Camel) | ✓ |
| PH-05 Adapter | 18 | Debezium CDC · Kamelet/Adapter Registry | ✓ |
| PH-06 MDM | 13 | MDM Service | ✓ |
| PH-07 Danh mục dùng chung | 16 | Reference Data Service | ✓ |
| PH-08 Chất lượng dữ liệu | 16 | Data Quality Service | ✓ |
| PH-09 Bảo vệ dữ liệu | 11 | Data Privacy Service | ✓ |
| PH-10 Truyền thông sự kiện | 15 | Kafka + Schema Registry | ✓ |
| PH-11 BPM | 16 | Process Orchestrator · Saga Coordinator | ✓ |
| PH-12 IAM | 19 | Keycloak · OPA/XACML PDP · Vault | ✓ |
| PH-13 Giám sát | 16 | Audit Log Service · ngăn xếp OTel/Prometheus/Loki/Tempo | ✓ |
| PH-14 Kết nối quốc gia | 14 | NDOP Adapter · Federation Router | ✓ |
| PH-15 Cổng nhà phát triển | 16 | Backstage Portal · Metadata Repository | ✓ |
| PH-16 NAS/KPI | 22 | NAS Connector · KPI Aggregation + Export | ✓ |
| PH-17 Cổng AI | 17 | AI Governance Service · APISIX ai-proxy | ✓ |
| PH-18 Vận hành/DLQ | 20 | DLQ Processor (nhánh Integration Runtime) | ✓ |
| SRS-19 Ma trận RBAC | 9 | *(xuyên suốt — PH-12 thực thi)* | ✓ |

**Tổng: 324 FR / 19 tài liệu — 100% neo được vào thành phần kiến trúc.**

### 1.2. Chiều ngược — thành phần có phân hệ đặc tả

Mọi thành phần trong bảng [§4.2 kiến trúc](../02-architecture/README.md#42-thuyết-minh-phân-rã-thành-phần) đều có SRS tương ứng. Hai trường hợp cần nói rõ:

- **Metadata Repository** không có SRS riêng: chức năng từ điển dữ liệu nay do [SRS-00](SRS-00-data-dictionary.md) đặc tả ở mức khái niệm và PH-15 hiện thực ở mức kỹ thuật (`EN-15-01` CATALOG_ENTITY). Không phải khoảng trống.
- **Saga Coordinator** không tách phân hệ: nằm trong PH-11 (`EN-11-03` DANG_KY_BU_TRU, `EN-11-06` SAGA_NHAT_KY). Hợp lý vì Saga chỉ có nghĩa trong ngữ cảnh một quy trình nghiệp vụ.

### 1.3. Điểm cần chú ý

**PH-04 chiếm 40/324 FR (12%)** — tỷ trọng cao nhất, đúng với vai trò lõi. Tuy nhiên trong đó 15 FR (`FR-04-026…040`) thuộc nhóm *thiết kế luồng bằng giao diện*, tức là chức năng **Control Plane** chứ không phải xử lý bản tin. Khi lập kế hoạch triển khai, nên tách hai nhóm này thành hai đơn vị triển khai riêng đúng theo nguyên tắc tách Control Plane / Data Plane đã chốt tại kiến trúc — nếu gộp, một lần phát hành trình thiết kế sẽ phải khởi động lại runtime đang chạy bản tin.

---

## 2. Phủ tuân thủ CMP-01…40 (7.2)

**Cách kiểm.** Quét toàn bộ 19 SRS tìm tham chiếu `CMP-nn`, đối chiếu với ma trận gốc tại [01-legal §3](../01-legal/README.md#3-ma-trận-truy-vết-tuân-thủ) (CMP-01…28) và phần mở rộng tại [06-impact](../06-impact/README.md) (CMP-29…40).

**Kết quả: 36/40 mục được ít nhất một SRS phủ.** Bốn mục còn lại không phải thiếu sót đặc tả — chúng thuộc loại nghĩa vụ **hạ tầng hoặc hồ sơ**, không ánh xạ vào yêu cầu chức năng của bất kỳ phân hệ nào:

| CMP | Nội dung | Vì sao không nằm trong SRS phân hệ | Nơi phủ thực tế |
|---|---|---|---|
| **CMP-17** | Sao lưu CSDL hằng ngày | Nghĩa vụ vận hành hạ tầng, áp cho mọi CSDL của mọi phân hệ; không có FR nào "thực hiện sao lưu" | [04-deployment](../04-deployment/README.md) — CloudNativePG backup → MinIO · [ADR-008](../05-adr/README.md#adr-008) |
| **CMP-18** | An toàn theo cấp độ (NĐ 85/2016) | Là **hồ sơ đề xuất cấp độ** được cơ quan có thẩm quyền phê duyệt, không phải chức năng phần mềm | Hồ sơ dự án · trường `security_level` tại [SRS-00 `DD-01`](SRS-00-data-dictionary.md#dd-01--he_thong_thanh_vien-hệ-thống-thông-tin-thành-viên) |
| **CMP-26** | Tuân thủ danh mục tiêu chuẩn (TT 39/2017) | Ràng buộc lựa chọn công nghệ toàn hệ thống, đã thực thi qua ADR | [05-adr](../05-adr/README.md) toàn bộ · [08-implementation IP-03](../08-implementation/03-stack-cong-nghe.md) |
| **CMP-40** | Thẩm định tuân thủ khung kiến trúc | Là **thủ tục hành chính** với cơ quan thẩm định, không phải chức năng | Hồ sơ dự án · [06-impact bước N13](../06-impact/README.md) |

**Đánh giá.** Đây là bốn nghĩa vụ có thật và đã có nơi phủ, chỉ là nơi phủ nằm ngoài bộ SRS. Không cần bổ sung FR giả tạo vào một phân hệ nào đó chỉ để bảng đủ 40/40 — làm vậy sẽ đặt sai trách nhiệm. **Việc cần làm**: ghi bốn dòng này vào hồ sơ nghiệm thu tuân thủ để người thẩm định không hiểu nhầm là bỏ sót (đã ghi tại [§6](#6-danh-mục-tồn-đọng), mục T-1).

### 2.1. Mức độ tập trung

| CMP | Số SRS phủ | Nhận xét |
|---|:-:|---|
| CMP-28 (ghi vết truy cập) | 12 | Phủ rộng nhất — đúng, vì mọi phân hệ chạm dữ liệu đều phải ghi vết |
| CMP-10, CMP-23, CMP-24 | 7–9 | Xuyên suốt, hợp lý |
| CMP-04, CMP-09, CMP-14, CMP-19, CMP-25, CMP-27, CMP-29, CMP-31, CMP-36, CMP-39 | 1 | Đơn nhiệm — mỗi mục thuộc đúng một phân hệ chuyên trách |

Không có mục nào phủ bởi quá nhiều phân hệ đến mức mất chủ thể trách nhiệm.

---

## 3. Kiểm chứng liên kết nội bộ (7.3)

**Cách kiểm.** Quét toàn kho (`.md` + `.html`, bỏ `.git` và `node_modules`), trích mọi liên kết Markdown, `href=`, `src=`; loại bỏ liên kết ngoài, neo `#`, `data:`, `javascript:`; kiểm tra tệp đích tồn tại trên đĩa.

**Kết quả: 0 liên kết hỏng.**

Bộ quét báo 12 mục nghi vấn, đã kiểm tra thủ công từng mục và xác nhận **tất cả đều là dương tính giả**:

| Nguồn | Số mục | Nguyên nhân | Kết luận |
|---|:-:|---|---|
| `mockup/pages/dlq.html` | 6 | Liên kết dạng `monitoring.html?traceId=…` — bộ quét không tách chuỗi truy vấn | Tệp `monitoring.html` tồn tại; liên kết hoạt động |
| `mockup/pages/designer/index.html` | 5 | Chuỗi mẫu trong JS đã nén (`` `+Et(e)+` ``) bị bắt nhầm thành `href` | Không phải liên kết |
| `mockup/designer-src/index.html` | 1 | `/src/main.tsx` — điểm vào Vite, chỉ tồn tại khi chạy dev server | Đúng thiết kế; bản build tại `pages/designer/` |

**Ghi chú.** Liên kết ngoài (văn bản pháp luật trên cổng chính phủ) không nằm trong phạm vi kiểm này — chúng có thể thay đổi ngoài tầm kiểm soát của dự án.

---

## 4. Rà soát UI ↔ mockup (7.4)

**Cách kiểm.** Trích mọi mã `UI-{PH}-{nn}` do chính SRS đó sở hữu tại mục M6, đối chiếu với các trang trong `mockup/`.

**Tổng: 124 màn được đặc tả · 61 màn đã dựng (49%) · 63 màn chưa dựng.**

### 4.1. Đã dựng đầy đủ

| Mockup | Phân hệ | Màn phủ | Số màn |
|---|---|---|:-:|
| [`pages/onboarding.html`](../../mockup/pages/onboarding.html) | PH-01 | UI-01-01…06 | 6/7 |
| [`pages/catalog.html`](../../mockup/pages/catalog.html) | PH-02 | UI-02-01…08 | 8/8 |
| [`pages/routes.html`](../../mockup/pages/routes.html) | PH-04 | UI-04-01…04 | 4/10 |
| [`pages/designer/index.html`](../../mockup/pages/designer/index.html) | PH-04 | UI-04-07…10 | 4/10 |
| [`pages/mdm.html`](../../mockup/pages/mdm.html) | PH-06 | UI-06-01…06 | 6/6 |
| [`pages/privacy.html`](../../mockup/pages/privacy.html) | PH-09 | UI-09-01…06 | 6/6 |
| [`pages/monitoring.html`](../../mockup/pages/monitoring.html) | PH-13 | UI-13-01, 02, 04 *(tổng quan · tra cứu trace · cảnh báo)* | 3/7 |
| [`pages/kpi.html`](../../mockup/pages/kpi.html) | PH-16 | UI-16-01…06 | 6/6 |
| [`pages/ai.html`](../../mockup/pages/ai.html) | PH-17 | UI-17-01…06 | 6/6 |
| [`pages/dlq.html`](../../mockup/pages/dlq.html) | PH-18 | UI-18-01…06 | 6/6 |
| [`index.html`](../../mockup/index.html) | — | Bảng điều khiển tổng hợp | — |

**PH-04 phủ 8/10**: `UI-04-05` (truy vết bản tin) và `UI-04-06` chưa có màn riêng — `UI-04-05` hiện dùng chung màn tra cứu trace của `monitoring.html`, chấp nhận được vì cùng dữ liệu `traceId`.

### 4.2. Chưa dựng — có trang giữ chỗ

Chín phân hệ có trang giữ chỗ nêu rõ "màn hình chưa dựng" và dẫn về SRS tương ứng. Đây là trạng thái **có chủ đích**, không phải trang lỗi:

| Trang giữ chỗ | Phân hệ | Số màn đặc tả chờ dựng |
|---|---|:-:|
| `pages/gateway.html` | PH-03 | 5 |
| `pages/adapters.html` | PH-05 | 6 |
| `pages/reference.html` | PH-07 | 6 |
| `pages/dq.html` | PH-08 | 7 |
| `pages/events.html` | PH-10 | 6 |
| `pages/bpm.html` | PH-11 | 6 |
| `pages/iam.html` | PH-12 | 7 |
| `pages/national.html` | PH-14 | 6 |
| `pages/portal.html` | PH-15 | 9 |

Cộng thêm: PH-01 còn 1 màn, PH-04 còn 2, PH-13 còn 4, và SRS-19 còn 4 (`UI-19-01…04`, chưa có trang). **Tổng 63 màn.**

### 4.3. Lý do chưa dựng và mức ưu tiên

Giai đoạn 6 của checklist chỉ cam kết dựng **các màn quan trọng có liên kết điều hướng thực tế**, không cam kết dựng đủ 124 màn. Mục tiêu của mockup là chứng minh luồng điều hướng và ngôn ngữ thiết kế — mục tiêu đó **đã đạt**. Thứ tự ưu tiên khi dựng tiếp:

| Ưu tiên | Màn | Lý do |
|---|---|---|
| **Cao** | `UI-19-01…04` ma trận phân quyền | Là màn quản trị được nhiều vai trò dùng nhất; chưa có bất kỳ trang nào |
| **Cao** | PH-12 (7 màn) | Quản trị danh tính — chạm mọi phân hệ |
| **Trung bình** | PH-15 (9 màn) | Backstage cung cấp giao diện sẵn; mockup chỉ cần phần tùy biến |
| **Trung bình** | PH-03, PH-10, PH-14 | Màn vận hành, người dùng hẹp |
| **Thấp** | PH-05, PH-07, PH-08, PH-11 | Màn cấu hình, tần suất dùng thấp |

---

## 5. Cập nhật wiki & memory (7.5)

| Việc | Kết quả |
|---|---|
| Thêm SRS-00 vào bản đồ tài liệu [wiki/00-INDEX.md](../../wiki/00-INDEX.md) | ✅ |
| Thêm dòng báo cáo rà soát này vào wiki | ✅ |
| Cập nhật [CHECKLIST.md](CHECKLIST.md) — 0.3 và 7.1…7.6 | ✅ |
| Memory: quy trình SRS đã hoàn tất, chuyển trọng tâm sang triển khai | ✅ |

---

## 6. Danh mục tồn đọng

Ba nhóm việc chuyển sang giai đoạn sau. Không nhóm nào chặn việc sử dụng bộ tài liệu hiện tại.

| Mã | Việc | Mức | Ghi chú |
|---|---|:-:|---|
| **T-1** | Ghi 4 mục CMP-17, 18, 26, 40 vào hồ sơ nghiệm thu tuân thủ, kèm nơi phủ thực tế | **M** | Tránh người thẩm định hiểu nhầm là bỏ sót; nội dung lấy nguyên từ [§2](#2-phủ-tuân-thủ-cmp-0140-72) |
| **T-2** | Dựng 63 màn mockup còn lại theo thứ tự ưu tiên tại [§4.3](#43-lý-do-chưa-dựng-và-mức-ưu-tiên) | **S** | Bắt đầu từ `UI-19-01…04` và PH-12 |
| **T-3** | Tách nhóm `FR-04-026…040` (trình thiết kế) thành đơn vị triển khai riêng khỏi runtime Camel | **M** | Xem lý do tại [§1.3](#13-điểm-cần-chú-ý); quyết định khi lập kế hoạch triển khai |

---

## Liên kết

- Checklist tiến độ → [CHECKLIST.md](CHECKLIST.md)
- Từ điển dữ liệu dùng chung → [SRS-00-data-dictionary.md](SRS-00-data-dictionary.md)
- Danh mục phân hệ → [README.md](README.md)
- Ma trận truy vết tuân thủ → [01-legal §3](../01-legal/README.md#3-ma-trận-truy-vết-tuân-thủ)
- Phân rã thành phần kiến trúc → [02-architecture §4](../02-architecture/README.md#4-kiến-trúc-ứng-dụng--phân-rã-thành-phần)
