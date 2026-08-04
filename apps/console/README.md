# LGSP Console

React 19 · Vite · Ant Design 6 · OIDC Keycloak (`lgsp-console`) · XYFlow designer (WP-24).

```bash
# cần Keycloak + control: make up-dev && make run-control
npm install
npm run typegen   # optional OpenAPI → TS
npm run dev       # http://localhost:5173
```

| Route | Nội dung |
|---|---|
| `/flows` | Designer production-path — lưu nháp `/api/admin/v1/routes`, findings, test stub |
| `/onboarding` | Kết nạp PH-01 (API thật) |
| `/catalog` | Catalog PH-02 (API thật) |

Login DEV: `dev-admin` / `dev-admin` (hoặc `dev-reviewer`).

Chạy thử stub: mặc định `VITE_TEST_RUN_STUB` bật (WP-25 chưa có). Proxy Vite: `/api` → `:8080`.
