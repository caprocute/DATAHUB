# Checklist — Xây dựng SRS & Mockup

> **Cách dùng**: bảng theo dõi tiến độ dài hạn, tồn tại qua nhiều phiên làm việc.
> Đánh dấu `[x]` + ghi ngày khi xong. Bắt đầu phiên mới bằng cách đọc file này.
> Danh mục phân hệ và quy ước → [README.md](README.md).

**Trạng thái tổng thể**: 1/32 hạng mục · 0/180 mục SRS · Cập nhật: 2026-08-03

---

## Quy ước

| Ký hiệu | Nghĩa |
|---|---|
| `[ ]` | Chưa làm |
| `[~]` | Đang làm dở |
| `[x]` | Hoàn thành |
| **M** | Bắt buộc — không có thì bộ tài liệu chưa dùng được |
| **S** | Cần có — bổ sung chất lượng |

### 10 mục bắt buộc của mọi SRS

Tham chiếu [quy ước cấu trúc SRS](README.md#31-cấu-trúc-tài-liệu-srs). Mỗi SRS **phải đủ cả 10 mục**, không được bỏ mục nào:

| # | Mục | Nội dung bắt buộc phải có |
|---|---|---|
| **M1** | **Giới thiệu** | Mục đích phân hệ · phạm vi · ranh giới trách nhiệm (làm gì / KHÔNG làm gì) · tài liệu tham chiếu |
| **M2** | **Mô tả tổng quan** | Vị trí trong kiến trúc · sơ đồ ngữ cảnh phân hệ · tác nhân · giả định · ràng buộc · phụ thuộc phân hệ khác |
| **M3** | **Yêu cầu chức năng** | Từng `FR-{PH}-{nnn}`: mô tả · tác nhân · tiền điều kiện · **đầu vào** · **xử lý** · **đầu ra** · **ngoại lệ** · mức ưu tiên M/S/C |
| **M4** | **Mô hình dữ liệu** | Sơ đồ thực thể-quan hệ · từng `EN-{PH}-{nn}`: thuộc tính, kiểu, ràng buộc, khóa · chính sách lưu giữ |
| **M5** | **Giao diện API** | Từng endpoint: phương thức · đường dẫn · tham số · thân yêu cầu/phản hồi · mã lỗi · ví dụ · yêu cầu xác thực |
| **M6** | **Giao diện người dùng** | Từng `UI-{PH}-{nn}`: mục đích · thành phần · quy tắc tương tác · trạng thái · liên kết tới mockup |
| **M7** | **Phi chức năng** | Từng `NFR-{PH}-{nnn}`: hiệu năng (số đo cụ thể) · sẵn sàng · bảo mật · mở rộng · khả năng quan sát |
| **M8** | **Quy tắc nghiệp vụ** | Từng `BR-{PH}-{nnn}`: phát biểu ràng buộc · lý do · cách thực thi · hành vi khi vi phạm |
| **M9** | **Tuân thủ CMP** | Bảng ánh xạ yêu cầu → mã CMP-01…40 → cách kiểm chứng |
| **M10** | **Kiểm thử chấp nhận** | Từng `AT-{PH}-{nnn}`: kịch bản · dữ liệu thử · kết quả mong đợi · tiêu chí đạt (đo được) |

**Tiêu chí "hoàn thành" một SRS**: đủ 10 mục · ≥ 1 sơ đồ kèm thuyết minh · mọi FR có đủ đầu vào/xử lý/đầu ra/ngoại lệ · có ánh xạ CMP · tiêu chí nghiệm thu đo được.

---

## GIAI ĐOẠN 0 — Nền tảng chung

- [x] **0.1** — Danh mục 18 phân hệ, sơ đồ quan hệ, ma trận phân hệ ↔ luồng, quy ước SRS · **M** · _2026-08-03_ → [README.md](README.md)
- [ ] **0.2** — Bộ khung dùng chung cho mockup: CSS design system, layout, thanh điều hướng, JS điều hướng · **M**
- [ ] **0.3** — Từ điển dữ liệu dùng chung toàn hệ thống (thực thể chia sẻ giữa các phân hệ) · **S**

---

## GIAI ĐOẠN 1 — SRS nhóm lõi (Đợt 1: trục tối thiểu chạy được)

> Nhóm này tạo ra "trục chạy được": một HTTT gọi HTTT khác qua LGSP.

### [ ] 1.1 — SRS **PH-12** Định danh, Xác thực & Ủy quyền · **M**

*Nội dung trọng tâm*: Keycloak realm · OIDC/SAML2/OAuth2 · MFA · OPA policy · XACML · liên kết VNeID
*Ánh xạ*: CMP-06, CMP-07, CMP-08, CMP-23, CMP-27

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-12-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-12-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-12-nn`)
- [ ] M7 Phi chức năng (`NFR-12-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-12-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-12-nnn`)

### [ ] 1.2 — SRS **PH-04** Lõi Tích hợp & Điều phối (Camel) · **M** · ⭐ *quan trọng nhất*

*Nội dung trọng tâm*: template route 9 bước · EIP · CDM · xử lý lỗi 3 tầng · circuit breaker · DLQ
*Ánh xạ*: CMP-04, CMP-11, CMP-12, CMP-16

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-04-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-04-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-04-nn`)
- [ ] M7 Phi chức năng (`NFR-04-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-04-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-04-nnn`)

### [ ] 1.3 — SRS **PH-03** Cổng tiếp nhận & Bảo vệ (APISIX) · **M**

*Nội dung trọng tâm*: định tuyến · TLS · JWT · rate limit · quota · WAF · chống DDoS
*Ánh xạ*: CMP-05, CMP-13, CMP-19

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-03-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-03-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-03-nn`)
- [ ] M7 Phi chức năng (`NFR-03-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-03-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-03-nnn`)

### [ ] 1.4 — SRS **PH-05** Quản lý Adapter & Kết nối hệ thống · **M**

*Nội dung trọng tâm*: 4 nhóm HTTT · adapter REST/SOAP/JMS/File/JDBC · CDC Debezium · Kamelet
*Ánh xạ*: CMP-11, CMP-12

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-05-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-05-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-05-nn`)
- [ ] M7 Phi chức năng (`NFR-05-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-05-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-05-nnn`)

---

## GIAI ĐOẠN 2 — SRS nhóm kết nạp & quan sát (Đợt 2)

### [ ] 2.1 — SRS **PH-01** Quản trị Kết nạp & Định danh hệ thống · **M**

*Nội dung trọng tâm*: quy trình đăng ký · thẩm định · cấp/thu hồi credential · luồng [F-01](../03-flows/README.md#f-01--đăng-ký-và-kết-nạp-httt-thành-viên)
*Ánh xạ*: CMP-01

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-01-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-01-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-01-nn`)
- [ ] M7 Phi chức năng (`NFR-01-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-01-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-01-nnn`)

### [ ] 2.2 — SRS **PH-02** Quản lý API & Danh mục dịch vụ · **M**

*Nội dung trọng tâm*: vòng đời API (DRAFT→RETIRED) · OpenAPI 3.1 · đồng bộ Bộ TT&TT · luồng [F-02](../03-flows/README.md#f-02--công-bố-và-đăng-ký-dịch-vụ-chia-sẻ-dữ-liệu)
*Ánh xạ*: CMP-02, CMP-03, CMP-05

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-02-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-02-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-02-nn`)
- [ ] M7 Phi chức năng (`NFR-02-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-02-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-02-nnn`)

### [ ] 2.3 — SRS **PH-10** Truyền thông sự kiện & Đồng bộ · **M**

*Nội dung trọng tâm*: Kafka topic · Schema Registry · CDC · idempotent · khóa phân vùng · luồng [F-05](../03-flows/README.md#f-05--đồng-bộ-dữ-liệu-bất-đồng-bộ-theo-sự-kiện)

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-10-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-10-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-10-nn`)
- [ ] M7 Phi chức năng (`NFR-10-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-10-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-10-nnn`)

### [ ] 2.4 — SRS **PH-13** Giám sát, Ghi vết & Cảnh báo · **M**

*Nội dung trọng tâm*: OTel · traceId · 4 nhóm dashboard · audit WORM · runbook · luồng [F-12](../03-flows/README.md#f-12--giám-sát-và-cảnh-báo-vận-hành)
*Ánh xạ*: CMP-10, CMP-28

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-13-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-13-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-13-nn`)
- [ ] M7 Phi chức năng (`NFR-13-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-13-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-13-nnn`)

---

## GIAI ĐOẠN 3 — SRS nhóm dữ liệu & kết nối quốc gia (Đợt 3)

### [ ] 3.1 — SRS **PH-07** Danh mục dùng chung & Ánh xạ từ điển · **M**

*Nội dung trọng tâm*: bảng mã · versioning · đồng bộ danh mục QG · Data Mapping Layer
*Ánh xạ*: CMP-21, CMP-30, CMP-31

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-07-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-07-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-07-nn`)
- [ ] M7 Phi chức năng (`NFR-07-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-07-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-07-nnn`)

### [ ] 3.2 — SRS **PH-06** Quản lý Dữ liệu chủ (MDM) · **M**

*Nội dung trọng tâm*: golden record · match engine (xác định + xác suất) · ưu tiên nguồn · đồng bộ CSDL tổng hợp QG · luồng [F-09](../03-flows/README.md#f-09--quản-lý-dữ-liệu-chủ-và-đối-sánh-thực-thể)
*Ánh xạ*: CMP-20, CMP-35

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-06-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-06-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-06-nn`)
- [ ] M7 Phi chức năng (`NFR-06-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-06-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-06-nnn`)

### [ ] 3.3 — SRS **PH-09** Bảo vệ dữ liệu & Quyền riêng tư · **M**

*Nội dung trọng tâm*: masking / giả danh hóa / ẩn danh hóa (k-anonymity) · phân loại mật
*Ánh xạ*: CMP-23, CMP-24, CMP-32

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-09-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-09-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-09-nn`)
- [ ] M7 Phi chức năng (`NFR-09-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-09-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-09-nnn`)

### [ ] 3.4 — SRS **PH-14** Kết nối Quốc gia (NDXP/NDOP) · **M**

*Nội dung trọng tâm*: NDXP Adapter · NDOP Adapter · Federation Router · ký số 2 chiều · luồng [F-04](../03-flows/README.md#f-04--khai-thác-dữ-liệu-từ-csdl-quốc-gia-qua-ndxp)
*Ánh xạ*: CMP-25, CMP-29

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-14-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-14-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-14-nn`)
- [ ] M7 Phi chức năng (`NFR-14-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-14-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-14-nnn`)

---

## GIAI ĐOẠN 4 — SRS nhóm hoàn thiện (Đợt 4)

### [ ] 4.1 — SRS **PH-08** Chất lượng dữ liệu · **M**

*Nội dung trọng tâm*: 6 chiều chất lượng · luật kiểm tra · chấm điểm có trọng số · báo cáo định kỳ · luồng [F-11](../03-flows/README.md#f-11--đánh-giá-chất-lượng-dữ-liệu-định-kỳ)
*Ánh xạ*: CMP-22

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-08-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-08-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-08-nn`)
- [ ] M7 Phi chức năng (`NFR-08-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-08-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-08-nnn`)

### [ ] 4.2 — SRS **PH-11** Điều phối quy trình nghiệp vụ (BPM) · **M**

*Nội dung trọng tâm*: BPMN 2.0 Flowable · tác vụ người dùng · Saga bù trừ · luồng [F-07](../03-flows/README.md#f-07--giải-quyết-thủ-tục-hành-chính-liên-thông)
*Ánh xạ*: CMP-09

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-11-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-11-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-11-nn`)
- [ ] M7 Phi chức năng (`NFR-11-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-11-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-11-nnn`)

### [ ] 4.3 — SRS **PH-15** Cổng Nhà phát triển & Tài liệu · **M**

*Nội dung trọng tâm*: Backstage · tài liệu OpenAPI tự sinh · thử API · TechDocs
*Ánh xạ*: CMP-02

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-15-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-15-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-15-nn`)
- [ ] M7 Phi chức năng (`NFR-15-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-15-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-15-nnn`)

### [ ] 4.4 — SRS **PH-18** Vận hành & Xử lý bản tin lỗi · **M**

*Nội dung trọng tâm*: DLQ · phân loại lỗi · phát lại đơn/hàng loạt · idempotent · luồng [F-10](../03-flows/README.md#f-10--xử-lý-lỗi-và-phát-lại-bản-tin)

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-18-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-18-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-18-nn`)
- [ ] M7 Phi chức năng (`NFR-18-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-18-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-18-nnn`)

---

## GIAI ĐOẠN 5 — SRS nhóm tuân thủ & AI (Đợt 5)

### [ ] 5.1 — SRS **PH-16** Quản trị Kiến trúc & Báo cáo KPI · **M**

*Nội dung trọng tâm*: Architecture Registry · NAS Connector · KPI 5 nhóm · xuất tự động
*Ánh xạ*: CMP-33, CMP-34

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-16-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-16-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-16-nn`)
- [ ] M7 Phi chức năng (`NFR-16-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-16-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-16-nnn`)

### [ ] 5.2 — SRS **PH-17** Cổng AI & Quản trị AI · **S**

*Nội dung trọng tâm*: AI Gateway (APISIX ai-proxy) · MLflow · Evidently · Human-in-the-loop
*Ánh xạ*: CMP-36, CMP-37, CMP-38

- [ ] M1 Giới thiệu
- [ ] M2 Mô tả tổng quan
- [ ] M3 Yêu cầu chức năng (`FR-17-nnn`)
- [ ] M4 Mô hình dữ liệu (`EN-17-nn`)
- [ ] M5 Giao diện API
- [ ] M6 Giao diện người dùng (`UI-17-nn`)
- [ ] M7 Phi chức năng (`NFR-17-nnn`)
- [ ] M8 Quy tắc nghiệp vụ (`BR-17-nnn`)
- [ ] M9 Tuân thủ CMP
- [ ] M10 Kiểm thử chấp nhận (`AT-17-nnn`)

---

## GIAI ĐOẠN 6 — Mockup HTML

> Yêu cầu: các màn quan trọng, **có liên kết điều hướng thực tế** giữa các trang.
> Mỗi mockup phải hiện thực đúng các màn `UI-{PH}-{nn}` đã đặc tả tại **M6** của SRS tương ứng.

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
- [ ] **7.4** — Rà soát: mọi `UI-{PH}-{nn}` tại M6 có mockup tương ứng (hoặc ghi rõ lý do chưa dựng) · **M**
- [ ] **7.5** — Cập nhật [wiki/00-INDEX.md](../../wiki/00-INDEX.md) và memory · **M**
- [ ] **7.6** — Commit và tổng kết · **M**

---

## Bảng theo dõi mức hoàn thành 10 mục

> Cập nhật song song với checkbox ở trên. Dùng để nhìn nhanh SRS nào còn thiếu mục gì.

| SRS | M1 | M2 | M3 | M4 | M5 | M6 | M7 | M8 | M9 | M10 | Xong |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| PH-01 Kết nạp | | | | | | | | | | | 0/10 |
| PH-02 API & Catalog | | | | | | | | | | | 0/10 |
| PH-03 Gateway | | | | | | | | | | | 0/10 |
| PH-04 Lõi tích hợp ⭐ | | | | | | | | | | | 0/10 |
| PH-05 Adapter | | | | | | | | | | | 0/10 |
| PH-06 MDM | | | | | | | | | | | 0/10 |
| PH-07 RDM | | | | | | | | | | | 0/10 |
| PH-08 Chất lượng DL | | | | | | | | | | | 0/10 |
| PH-09 Privacy | | | | | | | | | | | 0/10 |
| PH-10 Sự kiện | | | | | | | | | | | 0/10 |
| PH-11 BPM | | | | | | | | | | | 0/10 |
| PH-12 IAM | | | | | | | | | | | 0/10 |
| PH-13 Giám sát | | | | | | | | | | | 0/10 |
| PH-14 Quốc gia | | | | | | | | | | | 0/10 |
| PH-15 Portal | | | | | | | | | | | 0/10 |
| PH-16 NAS/KPI | | | | | | | | | | | 0/10 |
| PH-17 AI | | | | | | | | | | | 0/10 |
| PH-18 Vận hành | | | | | | | | | | | 0/10 |
| **Tổng** | | | | | | | | | | | **0/180** |

---

## Ghi chú tiến độ

| Ngày | Hạng mục | Ghi chú |
|---|---|---|
| 2026-08-03 | 0.1 | Hoàn thành danh mục 18 phân hệ + quy ước SRS |
| 2026-08-03 | — | Bổ sung 10 mục bắt buộc thành checkbox con cho từng SRS + bảng theo dõi 180 mục |
