# 08 — Hướng dẫn triển khai lập trình hệ thống LGSP

> **Vai trò.** Chuyển từ kiến trúc / SRS sang **cách tổ chức mã nguồn, mô hình phát triển và kỷ luật lập trình**.
> Không thay thế [02-architecture](../02-architecture/README.md) hay [04-deployment](../04-deployment/README.md) (hạ tầng K8s/GitOps).
>
> **Tham chiếu thực hành.** Chuẩn quy trình và module hóa học từ GiaPhaHub (`00.family_tree`) — Spring Modulith, OpenAPI contract-first, gates CI, luật agent — điều chỉnh cho LGSP (Camel Quarkus Data Plane, 18 PH, GitOps).

---

## 1. Bản đồ tài liệu

| Mã | Tài liệu | Nội dung |
|---|---|---|
| **IP-00** | [README.md](README.md) (file này) | Mục tiêu, quyết định tóm tắt, liên kết |
| **IP-01** | [01-mo-hinh-phat-trien.md](01-mo-hinh-phat-trien.md) | Production-first · microservice vs DU · bản đồ tách ngay |
| **IP-02** | [02-huong-dan-lap-trinh.md](02-huong-dan-lap-trinh.md) | Monorepo, Spring Modulith, Camel Quarkus, gates CI |

**ADR:** [ADR-018](../05-adr/README.md#adr-018) (mô hình DU) · [ADR-019](../05-adr/README.md#adr-019) (Spring Boot 4) · [ADR-002](../05-adr/README.md#adr-002) (Camel Quarkus — chỉ PH-04).

---

## 2. Quyết định tóm tắt

| Hạng mục | Quyết định |
|---|---|
| Mô hình | **Hybrid DU production-first** — tách ngay biên đã cứng; không 18 MS custom ngày 1; không monolith một khối |
| Tách ngay | COTS · Control≠Data · Camel theo miền · Console/Portal |
| Gom DU | PH cùng vòng đời (`control`, `data`, `process`, `adapter-mgr`) — mỗi PH schema + `api/` riêng |
| Runtime DU ứng dụng | **Spring Boot 4 + Spring Modulith** (ADR-019) |
| Runtime tích hợp | **Camel Quarkus native** (ADR-002) — giữ nguyên |
| Học GiaPhaHub | Spec trước code · Modulith · OpenAPI → typegen · outbox · deny-by-default · gates · luật agent |

Chi tiết → [IP-01](01-mo-hinh-phat-trien.md).

---

## 3. Nguyên tắc lập trình (kim chỉ nam)

1. **SRS / ADR trước code** — map `FR-xx` hoặc mã ADR; cấm vibe coding.
2. **Ranh giới PH = hợp đồng** — schema riêng, chỉ API/sự kiện (PR-02, PR-03).
3. **Control Plane ≠ Data Plane** — vòng đời tách (ADR-014).
4. **Git là nguồn sự thật cấu hình** — Camel YAML → Argo CD (ADR-010).
5. **Đúng runtime đúng lớp** — Boot cho DU ứng dụng; Quarkus chỉ cho Camel (ADR-019, ADR-002).
6. **Secret chỉ qua Vault** — không commit, không dán trên designer (ADR-012).
7. **Máy chặn trước, người duyệt sau** — gates CI (IP-02).

---

## 4. Liên kết

| Tài liệu | Vai trò |
|---|---|
| [wiki/00-INDEX](../../wiki/00-INDEX.md) | Điểm vào dự án |
| [02-architecture](../02-architecture/README.md) | Kiến trúc runtime |
| [04-deployment](../04-deployment/README.md) | Bước dựng hạ tầng |
| [05-adr](../05-adr/README.md) | Quyết định công nghệ |
| [07-srs](../07-srs/README.md) | Ranh giới PH + SRS |

---

## 5. Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-03 | Khởi tạo IP-00…02, ADR-018 |
| 2026-08-03 | Production-first; ADR-019 Spring Boot 4; ADR-002 làm rõ phạm vi Camel |
