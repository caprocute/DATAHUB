# E2E / cổng kiểm chứng DEV

## Thin-slice W1 (WP-16) — cổng vàng

### Tiên quyết

```bash
make up-dev                 # + wiremock + apisix
# terminal riêng:
make run-control
make run-adapter            # :8082
make run-camel              # :8088
```

### Chạy

```bash
./tests/e2e/thin-slice.sh
# hoặc: make e2e-thin
```

Kỳ vọng: HTTP 200 từ `/demo/tra-cuu`, body có `nguon=wiremock-httt-gia`, header `X-Trace-Id`.

Bằng chứng tạm: `/tmp/lgsp-e2e-headers.txt`, `/tmp/lgsp-e2e-body.json`.

## Cổng A — audit repair P0 (FE/ATTT)

1. `npm run dev` trong `apps/console` → http://localhost:5173
2. Login `dev-reviewer` (không phải admin thuần nếu cần kiểm RBAC): **Catalog** không hiện Publish nếu thiếu role.
3. Login `dev-admin`: tạo/lưu route → reload **Mở thiết kế** → canvas khớp bản đã lưu (có metadata `@lgsp-canvas-v1`).
4. `GET /api/v1/onboarding/applications` — không có field `clientSecretSealed` trên list.
5. `make e2e-thin` vẫn xanh.

## Cổng B — WP-25 + duyệt

1. Developer gửi duyệt → `PENDING_REVIEW`.
2. User khác (`INTEGRATION_REVIEWER`) approve → `routes/<code>/route.camel.yaml`.
3. `POST /api/admin/v1/routes/{code}/versions/{v}/test-runs` → waterfall JSON (không log secret).

## Cổng C — WP-26 AT PH-04

```bash
make at-ph04
# hoặc: ./tests/at/ph04/run.sh
```

Ánh xạ AT↔FR: [`tests/at/ph04/AT-FR-MAP.md`](../at/ph04/AT-FR-MAP.md). CI: `.github/workflows/at-ph04.yml`.
