# Ánh xạ AT ↔ FR (WP-26 · PH-04 lõi)

| AT | FR / NFR | Kiểm trong `run.sh` |
|---|---|---|
| AT-04-VAL-01 | FR-04-027 | Validate YAML hợp lệ → `valid=true` |
| AT-04-VAL-02 | FR-04-027 · NFR secret | YAML chứa `password=` → `SECRET` / `valid=false` |
| AT-04-CRT-01 | FR-04-026 | Tạo route DRAFT qua API |
| AT-04-GET-01 | FR-04-026 | GET version trả `definitionYaml` đầy đủ |
| AT-04-SUB-01 | FR-04-029 | Submit DRAFT → `PENDING_REVIEW` |
| AT-04-QUE-01 | ATTT list | `pending-review` không trả YAML đầy đủ |
| AT-04-4EYE-01 | FR-04-029 | Cùng actor duyệt → HTTP 409 |
| AT-04-4EYE-02 | FR-04-029 | Reviewer khác APPROVE → GitOps |
| AT-04-GIT-01 | FR-04-020 | File `routes/<code>/route.camel.yaml` tồn tại |
| AT-04-TST-01 | FR-04-028/035 | `POST …/test-runs` → waterfall 9 chặng |
| AT-04-ONB-01 | ATTT | List onboarding không có `clientSecretSealed` |
| AT-04-PUB-01 | FR-04-020 | Publish/approve không nhúng canvas marker vào GitOps |

Chạy: `make at-ph04` (cần control + Keycloak đang chạy).
