# Checklist — Xây dựng SRS & Mockup

> **Cách dùng**: bảng theo dõi tiến độ dài hạn, tồn tại qua nhiều phiên làm việc.
> Đánh dấu `[x]` + ghi ngày khi xong. Bắt đầu phiên mới bằng cách đọc file này.
> Danh mục phân hệ và quy ước → [README.md](README.md).

**Trạng thái tổng thể**: 14/33 hạng mục · 90/180 mục SRS · Cập nhật: 2026-08-03

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
- [x] **0.2** — Bộ khung dùng chung cho mockup: CSS design system, layout, thanh điều hướng, JS điều hướng · **M** · _2026-08-03_ → [`mockup/css/app.css`](../../mockup/css/app.css), [`mockup/js/app.js`](../../mockup/js/app.js), [`mockup/js/theme.js`](../../mockup/js/theme.js)
  - Nền token **Ant Design v6.5.3** + phong cách shadcn, chế độ sáng/tối ([ADR-016](../05-adr/README.md#adr-016))
- [ ] **0.3** — Từ điển dữ liệu dùng chung toàn hệ thống (thực thể chia sẻ giữa các phân hệ) · **S**

---

## GIAI ĐOẠN 1 — SRS nhóm lõi (Đợt 1: trục tối thiểu chạy được)

> Nhóm này tạo ra "trục chạy được": một HTTT gọi HTTT khác qua LGSP.

### [x] 1.1 — SRS **PH-12** Định danh, Xác thực & Ủy quyền · **M** · _2026-08-03_

→ [SRS-PH-12-iam.md](SRS-PH-12-iam.md) · 19 FR · 6 thực thể · 30 NFR · 17 BR · 30 AT
*Ánh xạ*: CMP-06, CMP-07, CMP-08, CMP-13, CMP-23, CMP-24, CMP-27, CMP-28, CMP-32

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-12-001…019`)
- [x] M4 Mô hình dữ liệu (`EN-12-01…06`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-12-01…07`)
- [x] M7 Phi chức năng (`NFR-12-001…030`)
- [x] M8 Quy tắc nghiệp vụ (`BR-12-001…017`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-12-001…030`)

### [x] 1.2 — SRS **PH-04** Lõi Tích hợp & Điều phối (Camel) · **M** · ⭐ *quan trọng nhất* · _2026-08-03_

→ [SRS-PH-04-integration-core.md](SRS-PH-04-integration-core.md) · 30 FR · 11 thực thể · 41 NFR · 20 BR · 35 AT
*Ánh xạ*: CMP-04, CMP-11, CMP-12, CMP-16, CMP-15, CMP-13, CMP-23, CMP-28, CMP-10, CMP-30, CMP-32, CMP-01
*Bao gồm*: thiết kế luồng bằng giao diện (`FR-04-026…030`) theo [ADR-015](../05-adr/README.md#adr-015) — Kaoto

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-04-001…025`)
- [x] M4 Mô hình dữ liệu (`EN-04-01…08`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-04-01…06`)
- [x] M7 Phi chức năng (`NFR-04-001…034`)
- [x] M8 Quy tắc nghiệp vụ (`BR-04-001…015`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-04-001…028`)

### [x] 1.3 — SRS **PH-03** Cổng tiếp nhận & Bảo vệ (APISIX) · **M** · _2026-08-03_

→ [SRS-PH-03-gateway.md](SRS-PH-03-gateway.md) · 17 FR · 5 thực thể · 28 NFR · 12 BR · 32 AT
*Ánh xạ*: CMP-01, CMP-05, CMP-10, CMP-11, CMP-13, CMP-14, CMP-15, CMP-19

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-03-001…017`)
- [x] M4 Mô hình dữ liệu (`EN-03-01…05`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-03-01…05`)
- [x] M7 Phi chức năng (`NFR-03-001…028`)
- [x] M8 Quy tắc nghiệp vụ (`BR-03-001…012`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-03-001…032`)

### [x] 1.4 — SRS **PH-05** Quản lý Adapter & Kết nối hệ thống · **M** · _2026-08-03_

→ [SRS-PH-05-adapter.md](SRS-PH-05-adapter.md) · 18 FR · 6 thực thể · 26 NFR · 15 BR · 35 AT
*Ánh xạ*: CMP-01, CMP-10, CMP-11, CMP-12, CMP-13, CMP-24

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-05-001…018`)
- [x] M4 Mô hình dữ liệu (`EN-05-01…06`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-05-01…06`)
- [x] M7 Phi chức năng (`NFR-05-001…026`)
- [x] M8 Quy tắc nghiệp vụ (`BR-05-001…015`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-05-001…035`)

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

### [x] 3.1 — SRS **PH-07** Danh mục dùng chung & Ánh xạ từ điển · **M** · _2026-08-03_

→ [SRS-PH-07-rdm.md](SRS-PH-07-rdm.md) · 16 FR · 6 thực thể · 25 NFR · 15 BR · 30 AT
*Ánh xạ*: CMP-10, CMP-21, CMP-30, CMP-31, CMP-34

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-07-001…016`)
- [x] M4 Mô hình dữ liệu (`EN-07-01…06`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-07-01…07`)
- [x] M7 Phi chức năng (`NFR-07-001…025`)
- [x] M8 Quy tắc nghiệp vụ (`BR-07-001…015`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-07-001…030`)

### [x] 3.2 — SRS **PH-06** Quản lý Dữ liệu chủ (MDM) · **M** · _2026-08-03_

→ [SRS-PH-06-mdm.md](SRS-PH-06-mdm.md) · 13 FR · 6 thực thể · 24 NFR · 15 BR · 32 AT
*Ánh xạ*: CMP-20, CMP-21, CMP-22, CMP-24, CMP-28, CMP-35

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-06-001…013`)
- [x] M4 Mô hình dữ liệu (`EN-06-01…06`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-06-01…06`)
- [x] M7 Phi chức năng (`NFR-06-001…024`)
- [x] M8 Quy tắc nghiệp vụ (`BR-06-001…015`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-06-001…032`)

### [x] 3.3 — SRS **PH-09** Bảo vệ dữ liệu & Quyền riêng tư · **M** · _2026-08-03_

→ [SRS-PH-09-privacy.md](SRS-PH-09-privacy.md) · 11 FR · 6 thực thể · 24 NFR · 17 BR · 30 AT
*Ánh xạ*: CMP-23, CMP-24, CMP-28, CMP-32, CMP-38

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-09-001…011`)
- [x] M4 Mô hình dữ liệu (`EN-09-01…06`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-09-01…06`)
- [x] M7 Phi chức năng (`NFR-09-001…024`)
- [x] M8 Quy tắc nghiệp vụ (`BR-09-001…017`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-09-001…030`)

### [x] 3.4 — SRS **PH-14** Kết nối Quốc gia (NDXP/NDOP) · **M** · _2026-08-03_

→ [SRS-PH-14-national.md](SRS-PH-14-national.md) · 14 FR · 5 thực thể · 25 NFR · 16 BR · 32 AT
*Ánh xạ*: CMP-03, CMP-10, CMP-13, CMP-24, CMP-25, CMP-29, CMP-30, CMP-35

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-14-001…014`)
- [x] M4 Mô hình dữ liệu (`EN-14-01…05`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-14-01…06`)
- [x] M7 Phi chức năng (`NFR-14-001…025`)
- [x] M8 Quy tắc nghiệp vụ (`BR-14-001…016`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-14-001…032`)

---

## GIAI ĐOẠN 4 — SRS nhóm hoàn thiện (Đợt 4)

### [x] 4.1 — SRS **PH-08** Chất lượng dữ liệu · **M** · _2026-08-03_

→ [SRS-PH-08-dq.md](SRS-PH-08-dq.md) · 16 FR · 6 thực thể · 26 NFR · 15 BR · 32 AT
*Nội dung trọng tâm*: 6 chiều chất lượng · luật kiểm tra · chấm điểm có trọng số · báo cáo định kỳ · luồng [F-11](../03-flows/README.md#f-11--đánh-giá-chất-lượng-dữ-liệu-định-kỳ)
*Ánh xạ*: CMP-22

- [x] M1 Giới thiệu
- [x] M2 Mô tả tổng quan
- [x] M3 Yêu cầu chức năng (`FR-08-001…016`)
- [x] M4 Mô hình dữ liệu (`EN-08-01…06`)
- [x] M5 Giao diện API
- [x] M6 Giao diện người dùng (`UI-08-01…07`)
- [x] M7 Phi chức năng (`NFR-08-001…026`)
- [x] M8 Quy tắc nghiệp vụ (`BR-08-001…015`)
- [x] M9 Tuân thủ CMP
- [x] M10 Kiểm thử chấp nhận (`AT-08-001…032`)

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

- [x] **6.1** — `index.html` — Trang chủ / Bảng điều khiển tổng quan · **M** · _2026-08-03_
- [ ] **6.2** — `pages/onboarding.html` — Kết nạp hệ thống thành viên (PH-01) · **M**
  - Danh sách hồ sơ · Biểu mẫu đăng ký · Màn thẩm định/phê duyệt
- [ ] **6.3** — `pages/catalog.html` — Danh mục dịch vụ & Quản lý API (PH-02) · **M**
  - Danh sách API · Chi tiết API + OpenAPI · Vòng đời trạng thái
- [x] **6.4** — `pages/routes.html` — Danh sách & giám sát luồng tích hợp (PH-04) · **M** · _2026-08-03_
  - Danh sách route (UI-04-01) · Sơ đồ luồng (UI-04-02) · Cấu hình xử lý lỗi (UI-04-03) · Thống kê (UI-04-04)
- [x] **6.11** — `pages/designer.html` + `pages/designer/index.html` — Thiết kế luồng bằng giao diện (PH-04) · **M** · _2026-08-03_
  - Trình thiết kế kéo thả XYFlow (UI-04-07) · DataMapper · hoàn tác/làm lại · Chạy thử (UI-04-08) · Duyệt (UI-04-09) · nguồn `mockup/designer-src/` ([ADR-017](../05-adr/README.md#adr-017))
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
| PH-03 Gateway | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-04 Lõi tích hợp ⭐ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-05 Adapter | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-06 MDM | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-07 RDM | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-08 Chất lượng DL | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-09 Privacy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-10 Sự kiện | | | | | | | | | | | 0/10 |
| PH-11 BPM | | | | | | | | | | | 0/10 |
| PH-12 IAM | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-13 Giám sát | | | | | | | | | | | 0/10 |
| PH-14 Quốc gia | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **10/10** |
| PH-15 Portal | | | | | | | | | | | 0/10 |
| PH-16 NAS/KPI | | | | | | | | | | | 0/10 |
| PH-17 AI | | | | | | | | | | | 0/10 |
| PH-18 Vận hành | | | | | | | | | | | 0/10 |
| **Tổng** | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | **90/180** |

---

## Ghi chú tiến độ

| Ngày | Hạng mục | Ghi chú |
|---|---|---|
| 2026-08-03 | 0.1 | Hoàn thành danh mục 18 phân hệ + quy ước SRS |
| 2026-08-03 | — | Bổ sung 10 mục bắt buộc thành checkbox con cho từng SRS + bảng theo dõi 180 mục |
| 2026-08-03 | 0.2 | Khung mockup: `app.css` (design system 18 nhóm) + `app.js` (sidebar, tab, lọc bảng) |
| 2026-08-03 | 1.2 | **SRS PH-04** đủ 10 mục — 25 FR, 8 thực thể, 34 NFR, 15 BR, 28 AT. Làm chuẩn mẫu cho 17 SRS còn lại |
| 2026-08-03 | 6.1, 6.4 | Mockup `index.html` + `routes.html` (4 màn UI-04-01…04). Đã kiểm chứng trên trình duyệt: điều hướng, chuyển tab, bảng cuộn ngang |
| 2026-08-03 | 1.2, 6.11 | Bổ sung năng lực **thiết kế luồng bằng giao diện**: [ADR-015](../05-adr/README.md#adr-015) chọn Kaoto thay Camel Karavan (Karavan tự triển khai K8s, xung đột GitOps tại ADR-010). SRS PH-04 thêm `FR-04-026…030`, `EN-04-09…11`, `UI-04-07…09`, `NFR-04-035…041`, `BR-04-016…020`, `AT-04-029…035`. Mockup `designer.html` |
| 2026-08-03 | 3.1–3.4 | **Hoàn tất Giai đoạn 3** — SRS PH-07 (Danh mục & ánh xạ từ điển), PH-06 (MDM), PH-09 (Bảo vệ dữ liệu), PH-14 (Kết nối quốc gia). Nhóm dữ liệu: 54 FR · 23 thực thể · 98 NFR · 63 BR · 124 AT |
| 2026-08-03 | 1.1, 1.3, 1.4 | **Hoàn tất Giai đoạn 1** — SRS PH-12 (IAM), PH-03 (Gateway), PH-05 (Adapter), mỗi SRS đủ 10 mục. Cả nhóm lõi: 79 FR · 25 thực thể · 118 NFR · 59 BR · 125 AT |
| 2026-08-03 | 0.2 | Chốt ngăn xếp giao diện tại [ADR-016](../05-adr/README.md#adr-016): **Ant Design v6** + phong cách shadcn + chế độ sáng/tối. Viết lại `app.css` trên token trích trực tiếp từ gói `antd@6.5.3`, thêm `theme.js`. Đã đo tương phản tự động 3.142 phần tử ở cả hai chế độ, sửa 9 vi phạm WCAG AA bằng cách đổi sắc độ trong chính bảng màu antd |
| 2026-08-03 | 6.11, ADR-017 | Màn thiết kế kéo thả bằng **XYFlow** (`@xyflow/react`): nguồn `mockup/designer-src/`, bản build `mockup/pages/designer/index.html`. [ADR-015](../05-adr/README.md#adr-015) làm rõ Kaoto là mẫu catalog/YAML; [ADR-017](../05-adr/README.md#adr-017) chốt động cơ sơ đồ |
| 2026-08-03 | 6.11 | Bổ sung **DataMapper**, **hoàn tác/làm lại**, gộp tab Chạy thử + Duyệt vào cùng app React (`#test` / `#review`). `designer.html` chuyển hướng sang bản React |
| 2026-08-03 | 4.1 | **SRS PH-08** đủ 10 mục — 16 FR, 6 thực thể, 26 NFR, 15 BR, 32 AT. Sáu chiều DQ, F-11, CMP-22 |
