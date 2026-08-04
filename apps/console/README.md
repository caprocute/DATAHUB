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
| `/flows` | Designer production-path — lưu nháp, round-trip canvas, chạy thử WP-25 |
| `/onboarding` | Kết nạp PH-01 (API thật) |
| `/catalog` | Catalog PH-02 (API thật) |

Login DEV: `dev-admin` / `dev-admin` (hoặc `dev-reviewer`).

Chạy thử: mặc định gọi API `…/test-runs`. Chỉ bật stub khi `VITE_TEST_RUN_STUB=true`. Proxy Vite: `/api` → `:8080`.
