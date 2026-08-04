#!/usr/bin/env bash
# WP-16 — thin-slice E2E: token → kết nạp → duyệt → catalog → /demo/tra-cuu
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
KC="${KEYCLOAK_URL:-http://localhost:8081}"
CTRL="${CONTROL_URL:-http://localhost:8080}"
GW="${APISIX_URL:-http://localhost:9080}"
CODE="E2E_$(date +%s)"

echo "==> Token reviewer"
TOKEN=$(curl -sf -X POST "$KC/realms/lgsp/protocol/openid-connect/token" \
  -d client_id=lgsp-console \
  -d grant_type=password \
  -d username=dev-reviewer \
  -d password=dev-reviewer | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')

echo "==> Nộp hồ sơ $CODE"
APP=$(curl -sf -X POST "$CTRL/api/v1/onboarding/applications" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"systemCode\":\"$CODE\",\"systemName\":\"E2E Demo\",\"ownerOrg\":\"Sở Demo\"}")
APP_ID=$(echo "$APP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
echo "    applicationId=$APP_ID"

echo "==> Duyệt hồ sơ"
APPROVED=$(curl -sf -X POST "$CTRL/api/v1/onboarding/applications/$APP_ID/approve" \
  -H "Authorization: Bearer $TOKEN")
echo "$APPROVED" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="APPROVED",d;print("    clientId=",d["clientId"])'

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
