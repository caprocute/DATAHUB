#!/usr/bin/env bash
# WP-16 — thin-slice E2E: token → kết nạp → duyệt → catalog → /demo/tra-cuu
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
KC="${KEYCLOAK_URL:-http://localhost:8081}"
CTRL="${CONTROL_URL:-http://localhost:8080}"
GW="${APISIX_URL:-http://localhost:9080}"
CODE="E2E_$(date +%s)"

token_for() {
  curl -sf -X POST "$KC/realms/lgsp/protocol/openid-connect/token" \
    -d client_id=lgsp-console \
    -d grant_type=password \
    -d username="$1" \
    -d password="$1" | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
}

# Luật bốn mắt (FR-01-006): người nộp hồ sơ không được tự thẩm định / tự duyệt,
# nên kịch bản cần hai tài khoản khác nhau.
echo "==> Token dev-admin (nộp) + dev-reviewer (thẩm định, duyệt)"
SUBMITTER=$(token_for dev-admin)
TOKEN=$(token_for dev-reviewer)

echo "==> Nộp hồ sơ $CODE"
APP=$(curl -sf -X POST "$CTRL/api/v1/onboarding/applications" \
  -H "Authorization: Bearer $SUBMITTER" \
  -H "Content-Type: application/json" \
  -d "{\"systemCode\":\"$CODE\",\"systemName\":\"E2E Demo\",\"ownerOrg\":\"Sở Demo\",\"legalBasis\":\"Quyết định E2E\",\"techProfile\":\"Hồ sơ năng lực E2E\",\"contactName\":\"Cán bộ E2E\",\"contactEmail\":\"e2e@example.gov.vn\"}")
APP_ID=$(echo "$APP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
echo "    applicationId=$APP_ID"

echo "==> Thẩm định pháp lý (FR-01-004) + kỹ thuật (FR-01-005)"
curl -sf -X POST "$CTRL/api/v1/onboarding/applications/$APP_ID/review/legal" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"decision":"PASS","note":"đủ căn cứ"}' > /dev/null
REVIEWED=$(curl -sf -X POST "$CTRL/api/v1/onboarding/applications/$APP_ID/review/technical" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"decision":"PASS","note":"đạt"}')
echo "$REVIEWED" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="REVIEWED",d;print("    đã thẩm định đủ hai bước")'

echo "==> Duyệt hồ sơ (bốn mắt: người duyệt khác người nộp)"
APPROVED=$(curl -sf -X POST "$CTRL/api/v1/onboarding/applications/$APP_ID/approve" \
  -H "Authorization: Bearer $TOKEN")
echo "$APPROVED" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="APPROVED",d;assert d["clientSecretSealed"],"phải trả bí mật một lần";print("    clientId=",d["clientId"])'

echo "==> Bí mật không rò ở lối đọc khác (FR-01-009)"
curl -sf "$CTRL/api/v1/onboarding/applications/$APP_ID" -H "Authorization: Bearer $TOKEN" \
  | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["clientSecretSealed"] is None,"secret bị rò khi đọc lại";print("    đọc lại: secret = null")'
curl -sf "$CTRL/api/v1/onboarding/applications?size=50" -H "Authorization: Bearer $TOKEN" \
  | python3 -c 'import sys,json;d=json.load(sys.stdin);assert all(i["clientSecretSealed"] is None for i in d["items"]),"secret bị rò ở danh sách";print("    danh sách: không có secret")'

echo "==> Đăng ký + publish catalog"
SVC=$(curl -sf -X POST "$CTRL/api/v1/catalog/services" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"serviceCode\":\"tra-cuu-$CODE\",\"title\":\"Tra cứu E2E\",\"openapiYaml\":\"openapi: 3.0.0\\ninfo: {title: demo, version: '0.1'}\\npaths: {}\",\"publicPath\":\"/demo/tra-cuu\",\"upstreamUrl\":\"http://host.docker.internal:8088\"}")
SVC_ID=$(echo "$SVC" | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
PUB=$(curl -sf -X POST "$CTRL/api/v1/catalog/services/$SVC_ID/publish" \
  -H "Authorization: Bearer $TOKEN")
echo "$PUB" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="PUBLISHED",d;print("    routeFile=",d.get("routeFile"))'

TRACE="00-$(python3 -c 'import uuid;print(uuid.uuid4().hex+"-"+uuid.uuid4().hex[:16]+"-01")')"
echo "==> Gọi gateway $GW/demo/tra-cuu (traceparent=$TRACE)"
RESP=$(curl -sS -D /tmp/lgsp-e2e-headers.txt -o /tmp/lgsp-e2e-body.json -w '%{http_code}' \
  -H "Authorization: Bearer $TOKEN" \
  -H "traceparent: $TRACE" \
  "$GW/demo/tra-cuu")
echo "    http=$RESP"
cat /tmp/lgsp-e2e-body.json; echo
grep -i 'x-trace-id\|traceparent' /tmp/lgsp-e2e-headers.txt || true
test "$RESP" = "200"
python3 -c 'import json;d=json.load(open("/tmp/lgsp-e2e-body.json"));assert d.get("nguon")=="wiremock-httt-gia",d'
echo "OK thin-slice E2E"
echo "Bằng chứng headers: /tmp/lgsp-e2e-headers.txt"
