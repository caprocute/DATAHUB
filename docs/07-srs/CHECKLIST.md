# Checklist — Xây dựng SRS & Mockup

> **Cách dùng**: đây là bảng theo dõi tiến độ dài hạn, tồn tại qua nhiều phiên làm việc.
> Mỗi lần làm xong một hạng mục, đánh dấu `[x]` và ghi ngày. Bắt đầu phiên mới bằng cách đọc file này.
> Danh mục phân hệ và quy ước → [README.md](README.md).

**Trạng thái tổng thể**: 1/32 hạng mục · Cập nhật: 2026-08-03

---

## Quy ước

| Ký hiệu | Nghĩa |
|---|---|
| `[ ]` | Chưa làm |
| `[~]` | Đang làm dở |
| `[x]` | Hoàn thành |
| **M** | Bắt buộc — không có thì bộ tài liệu chưa dùng được |
| **S** | Cần có — bổ sung chất lượng |

**Mỗi SRS phải có đủ 10 mục** (theo [quy ước](README.md#31-cấu-trúc-tài-liệu-srs)): Giới thiệu · Mô tả tổng quan · Yêu cầu chức năng · Mô hình dữ liệu · Giao diện API · Giao diện người dùng · Phi chức năng · Quy tắc nghiệp vụ · Tuân thủ CMP · Kiểm thử chấp nhận.

**Tiêu chí "hoàn thành" một SRS**: đủ 10 mục · có ít nhất 1 sơ đồ kèm thuyết minh · mọi FR có mã, đầu vào/xử lý/đầu ra/ngoại lệ · có ánh xạ CMP · có tiêu chí nghiệm thu đo được.

---

## GIAI ĐOẠN 0 — Nền tảng chung

- [x] **0.1** — Danh mục 18 phân hệ, sơ đồ quan hệ, ma trận phân hệ ↔ luồng, quy ước SRS · **M** · _2026-08-03_ → [README.md](README.md)
- [ ] **0.2** — Bộ khung dùng chung cho mockup: CSS design system, layout, thanh điều hướng, JS điều hướng · **M**
- [ ] **0.3** — Từ điển dữ liệu dùng chung toàn hệ thống (thực thể chia sẻ giữa các phân hệ) · **S**

---

## GIAI ĐOẠN 1 — SRS nhóm lõi (Đợt 1: trục tối thiểu chạy được)

> Nhóm này tạo ra "trục chạy được": một HTTT gọi HTTT khác qua LGSP.

- [ ] **1.1** — SRS **PH-12** Định danh, Xác thực & Ủy quyền · **M**
  - Keycloak realm, OIDC/SAML2/OAuth2, MFA, OPA policy, XACML, liên kết VNeID
  - Ánh xạ: CMP-06, CMP-07, CMP-08, CMP-23, CMP-27
- [ ] **1.2** — SRS **PH-04** Lõi Tích hợp & Điều phối (Camel) · **M** · _quan trọng nhất_
  - Template route 9 bước, EIP, CDM, xử lý lỗi 3 tầng, circuit breaker, DLQ
  - Ánh xạ: CMP-04, CMP-11, CMP-12, CMP-16
- [ ] **1.3** — SRS **PH-03** Cổng tiếp nhận & Bảo vệ (APISIX) · **M**
  - Định tuyến, TLS, JWT, rate limit, quota, WAF, chống DDoS
  - Ánh xạ: CMP-05, CMP-13, CMP-19
- [ ] **1.4** — SRS **PH-05** Quản lý Adapter & Kết nối hệ thống · **M**
  - 4 nhóm HTTT, adapter REST/SOAP/JMS/File/JDBC, CDC Debezium, Kamelet
  - Ánh xạ: CMP-11, CMP-12

---

## GIAI ĐOẠN 2 — SRS nhóm kết nạp & quan sát (Đợt 2)

- [ ] **2.1** — SRS **PH-01** Quản trị Kết nạp & Định danh hệ thống · **M**
  - Quy trình đăng ký, thẩm định, cấp credential, thu hồi; luồng F-01
  - Ánh xạ: CMP-01
- [ ] **2.2** — SRS **PH-02** Quản lý API & Danh mục dịch vụ · **M**
  - Vòng đời API (DRAFT→RETIRED), OpenAPI 3.1, đồng bộ Bộ TT&TT; luồng F-02
  - Ánh xạ: CMP-02, CMP-03, CMP-05
- [ ] **2.3** — SRS **PH-10** Truyền thông sự kiện & Đồng bộ · **M**
  - Kafka topic, Schema Registry, CDC, idempotent, khóa phân vùng; luồng F-05
- [ ] **2.4** — SRS **PH-13** Giám sát, Ghi vết & Cảnh báo · **M**
  - OTel, traceId, 4 nhóm dashboard, audit WORM, runbook; luồng F-12
  - Ánh xạ: CMP-10, CMP-28

---

## GIAI ĐOẠN 3 — SRS nhóm dữ liệu & kết nối quốc gia (Đợt 3)

- [ ] **3.1** — SRS **PH-07** Danh mục dùng chung & Ánh xạ từ điển · **M**
  - Bảng mã, versioning, đồng bộ danh mục QG, Data Mapping Layer
  - Ánh xạ: CMP-21, CMP-30, CMP-31
- [ ] **3.2** — SRS **PH-06** Quản lý Dữ liệu chủ (MDM) · **M**
  - Golden record, match engine (xác định + xác suất), ưu tiên nguồn, đồng bộ CSDL tổng hợp QG; luồng F-09
  - Ánh xạ: CMP-20, CMP-35
- [ ] **3.3** — SRS **PH-09** Bảo vệ dữ liệu & Quyền riêng tư · **M**
  - Masking / giả danh hóa / ẩn danh hóa (k-anonymity), phân loại mật
  - Ánh xạ: CMP-23, CMP-24, CMP-32
- [ ] **3.4** — SRS **PH-14** Kết nối Quốc gia (NDXP/NDOP) · **M**
  - NDXP Adapter, NDOP Adapter, Federation Router, ký số 2 chiều; luồng F-04
  - Ánh xạ: CMP-25, CMP-29

---

## GIAI ĐOẠN 4 — SRS nhóm hoàn thiện (Đợt 4)

- [ ] **4.1** — SRS **PH-08** Chất lượng dữ liệu · **M**
  - 6 chiều chất lượng, luật kiểm tra, chấm điểm có trọng số, báo cáo định kỳ; luồng F-11
  - Ánh xạ: CMP-22
- [ ] **4.2** — SRS **PH-11** Điều phối quy trình nghiệp vụ (BPM) · **M**
  - BPMN 2.0 Flowable, tác vụ người dùng, Saga bù trừ; luồng F-07
  - Ánh xạ: CMP-09
- [ ] **4.3** — SRS **PH-15** Cổng Nhà phát triển & Tài liệu · **M**
  - Backstage, tài liệu OpenAPI tự sinh, thử API, TechDocs
  - Ánh xạ: CMP-02
- [ ] **4.4** — SRS **PH-18** Vận hành & Xử lý bản tin lỗi · **M**
  - DLQ, phân loại lỗi, phát lại đơn/hàng loạt, idempotent; luồng F-10

---

## GIAI ĐOẠN 5 — SRS nhóm tuân thủ & AI (Đợt 5)

- [ ] **5.1** — SRS **PH-16** Quản trị Kiến trúc & Báo cáo KPI · **M**
  - Architecture Registry, NAS Connector, KPI 5 nhóm, xuất tự động
  - Ánh xạ: CMP-33, CMP-34
- [ ] **5.2** — SRS **PH-17** Cổng AI & Quản trị AI · **S**
  - AI Gateway (APISIX ai-proxy), MLflow, Evidently, Human-in-the-loop
  - Ánh xạ: CMP-36, CMP-37, CMP-38

---

## GIAI ĐOẠN 6 — Mockup HTML

> Yêu cầu: các màn quan trọng, **có liên kết điều hướng thực tế** giữa các trang.

- [ ] **6.1** — `index.html` — Trang chủ / Bảng điều khiển tổng quan · **M**
- [ ] **6.2** — `pages/onboarding.html` — Kết nạp hệ thống thành viên (PH-01) · **M**
  - Danh sách hồ sơ · Biểu mẫu đăng ký · Màn thẩm định/phê duyệt
- [ ] **6.3** — `pages/catalog.html` — Danh mục dịch vụ & Quản lý API (PH-02) · **M**
  - Danh sách API · Chi tiết API + OpenAPI · Vòng đời trạng thái
- [ ] **6.4** — `pages/routes.html` — Thiết kế & giám sát luồng tích hợp (PH-04) · **M**
  - Danh sách route · Sơ đồ luồng · Cấu hình xử lý lỗi
- [ ] **6.5** — `pages/mdm.html` — Quản lý dữ liệu chủ (PH-06) · **M**
  - Tra cứu bản ghi vàng · Hàng đợi đối sánh thủ công · Lịch sử phiên bản
- [ ] **6.6** — `pages/monitoring.html` — Giám sát & Truy vết (PH-13) · **M**
  - Dashboard sức khỏe · Tra cứu theo traceId · Danh sách cảnh báo
- [ ] **6.7** — `pages/dlq.html` — Xử lý bản tin lỗi (PH-18) · **M**
  - Danh sách DLQ · Chi tiết lỗi + ngữ cảnh · Phát lại hàng loạt
- [ ] **6.8** — `pages/kpi.html` — Báo cáo KPI tuân thủ (PH-16) · **M**
  - 5 nhóm KPI · Mức độ tuân thủ CMP · Xuất báo cáo
- [ ] **6.9** — `pages/privacy.html` — Bảo vệ dữ liệu & quyền riêng tư (PH-09) · **S**
- [ ] **6.10** — `pages/ai.html` — Quản trị AI & Human-in-the-loop (PH-17) · **S**

---

## GIAI ĐOẠN 7 — Rà soát & tích hợp

- [ ] **7.1** — Rà soát chéo: mọi FR trong SRS có ánh xạ tới thành phần kiến trúc · **M**
- [ ] **7.2** — Rà soát: mọi CMP-01…40 được ít nhất một SRS phủ · **M**
- [ ] **7.3** — Kiểm chứng liên kết: mọi đường dẫn nội bộ trong tài liệu và mockup hoạt động · **M**
- [ ] **7.4** — Cập nhật [wiki/00-INDEX.md](../../wiki/00-INDEX.md) và memory · **M**
- [ ] **7.5** — Commit và tổng kết · **M**

---

## Ghi chú tiến độ

| Ngày | Hạng mục | Ghi chú |
|---|---|---|
| 2026-08-03 | 0.1 | Hoàn thành danh mục 18 phân hệ + quy ước SRS |
