# Luật cho AI agent — LGSP

> Đọc [wiki/00-INDEX.md](wiki/00-INDEX.md) → [IP-03](docs/08-implementation/03-stack-cong-nghe.md) → [IP-04](docs/08-implementation/04-ke-hoach-phat-trien.md) trước khi viết mã.
> Bản sao ngắn: `CLAUDE.md` trỏ về file này.

## 1. Không vibe coding

- Mọi thay đổi nghiệp vụ map `FR-*` / ADR / WP trong IP-04.
- Hết DoD của WP thì dừng — không tự mở rộng sang WP khác.
- Hợp đồng (`contracts/`) trước khi implement consumer.

## 2. Sở hữu thư mục (lane)

| Lane | Path được sửa |
|---|---|
| L-FOUND | `AGENTS.md`, root, `.github/`, `contracts/` (scaffold), `libs/` |
| L-PLAT | `deploy/` |
| L-SEC | Keycloak realm, `contracts/opa/`, Vault/ESO mẫu |
| L-CTRL | `apps/control/` |
| L-ADAPT | `apps/adapter-mgr/` |
| L-CAMEL | `camel/`, `routes/` |
| L-DATA | `apps/data/` |
| L-PROC | `apps/process/` |
| L-FE | `apps/console/`, `packages/` |
| L-OBS | dashboards, alert rules |
| L-AI | `apps/ai/` |
| L-QA | `tests/` |

PR sửa ngoài lane → reject (trừ `contracts/` đã thỏa thuận).

## 3. Runtime

- DU ứng dụng: **Spring Boot 4 + Modulith** (ADR-019), Java **21**.
- Camel PH-04: **Camel Quarkus 4.18 LTS native** (ADR-002, ADR-020).
- Object storage: **Garage** (ưu tiên) — **không MinIO** (ADR-020).

## 4. Modulith

- Chỉ import `api/` + `events/`; cấm `internal/` xuyên module.
- Schema PostgreSQL riêng theo PH (`ph01`, `ph02`, …).
- `ApplicationModules.verify()` phải xanh trong CI.

## 5. Bảo mật

- Deny-by-default: endpoint mới gắn permission SRS-19.
- Không commit secret; dùng `.env.example` + Vault/ESO.
- Không dán secret trên designer / mockup.

## 6. Giao diện

- UI/UX CRUD mặc định: [`docs/ui_ux_rule.md`](docs/ui_ux_rule.md) + rule [`.cursor/rules/ui-ux-crud.mdc`](.cursor/rules/ui-ux-crud.mdc) (ProTable / mockup `.crud-*`).

### 6.1. Chiều dọc cố định — không màn nào tràn màn hình

**Màn hình khóa đúng chiều cao cửa sổ. Trang không bao giờ cuộn ở cấp cửa sổ.** Nội dung
dài hơn chỗ có thì cuộn *bên trong* khung của nó.

Lý do: cuộn cấp cửa sổ làm trôi mất mọi mốc cố định — thanh lọc, tiêu đề bảng, thanh thao
tác. Ở bảng dài, người dùng cuộn xuống là hết biết cột nào là cột nào, muốn bấm nút thao
tác phải cuộn ngược lên.

| Trường hợp | Làm gì |
|---|---|
| Màn thường (bảng, biểu mẫu) | **Không phải làm gì.** `.shell-content` đã là vùng cuộn sẵn |
| Màn tự quản chiều cao (danh mục, trình thiết kế — có panel cuộn riêng, thanh lọc dính trên) | Thêm `.page-fill` cho khối gốc của màn |

- Cấm `height: 100vh` / `min-height: 100vh` bên trong màn — khung ngoài đã khóa rồi, đặt
  thêm là cộng dồn thành tràn.
- Mọi tổ tiên flex của một vùng cuộn phải có `min-height: 0`. Thiếu là flex item không co
  được, vùng cuộn bị **đẩy tràn ra ngoài thay vì cuộn** — lỗi hay gặp nhất ở đây.
- Chiều ngang: bảng rộng cuộn trong khối của nó (`overflow-x: auto`), không để cả trang
  trượt ngang.

Định nghĩa luật ở `apps/console/src/styles.css` (khối "LUẬT BỐ CỤC").

## 7. Definition of Done (mọi PR)

- [ ] Map FR/ADR/WP
- [ ] Test / Modulith verify (nếu Java DU)
- [ ] OpenAPI/event cập nhật nếu đổi hợp đồng
- [ ] Không secret; gitleaks sạch
- [ ] README/ghi chú breaking change nếu cần
