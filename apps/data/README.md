# lgsp-data (WP-30)

DU dữ liệu dùng chung — Spring Boot 4 + Modulith (`rdm` / `mdm` / `privacy` / `dq`).

```bash
make up-dev          # Postgres + Keycloak + OPA :8181
make run-data        # http://localhost:8083
```

| Endpoint | Schema | OPA action |
|---|---|---|
| `GET /api/v1/rdm/status` | ph07 | `data.rdm.status` |
| `GET /api/v1/mdm/status` | ph06 | `data.mdm.status` |
| `GET /api/v1/privacy/status` | ph09 | `data.privacy.status` |
| `GET /api/v1/dq/status` | ph08 | `data.dq.status` |

JWT bắt buộc. OPA fail-closed (`LGSP_OPA_ENABLED=false` chỉ khi test).
