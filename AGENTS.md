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
- UI/UX CRUD mặc định: [`docs/ui_ux_rule.md`](docs/ui_ux_rule.md) + rule [`.cursor/rules/ui-ux-crud.mdc`](.cursor/rules/ui-ux-crud.mdc) (ProTable / mockup `.crud-*`).

## 6. Definition of Done (mọi PR)

- [ ] Map FR/ADR/WP
- [ ] Test / Modulith verify (nếu Java DU)
- [ ] OpenAPI/event cập nhật nếu đổi hợp đồng
- [ ] Không secret; gitleaks sạch
- [ ] README/ghi chú breaking change nếu cần
