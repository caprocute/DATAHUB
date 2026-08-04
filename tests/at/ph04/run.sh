#!/usr/bin/env bash
# WP-26 — AT lõi PH-04 (≥10) · map AT↔FR: AT-FR-MAP.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
KC="${KEYCLOAK_URL:-http://localhost:8081}"
CTRL="${CONTROL_URL:-http://localhost:8080}"
CODE="at-$(date +%s | tail -c 8)"
PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); echo "  OK  $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL $1 — $2"; }

token() {
  local user=$1 pass=$2
  curl -sf -X POST "$KC/realms/lgsp/protocol/openid-connect/token" \
    -d client_id=lgsp-console \
    -d grant_type=password \
    -d username="$user" \
    -d password="$pass" | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
}

GOOD_YAML=$'- route:\n    id: at-demo\n    from:\n      uri: direct:start\n      steps:\n        - log:\n            message: "receive schema authz transform enrich route deliver audit respond"\n'

echo "==> Tokens"
DEV_TOKEN=$(token dev-admin dev-admin)
REV_TOKEN=$(token dev-reviewer dev-reviewer)

echo "==> AT-04-VAL-01 validate OK"
V=$(python3 - "$CTRL" "$DEV_TOKEN" "$GOOD_YAML" <<'PY'
import json, os, sys, urllib.request
ctrl, tok, yaml = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(
    ctrl + "/api/admin/v1/routes/validate",
    data=json.dumps({"definitionYaml": yaml}).encode(),
    headers={"Authorization": "Bearer " + tok, "Content-Type": "application/json"},
    method="POST",
)
print(urllib.request.urlopen(req).read().decode())
PY
)
echo "$V" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["valid"] is True,d' && ok AT-04-VAL-01 || fail AT-04-VAL-01 "$V"

echo "==> AT-04-VAL-02 secret scan"
BAD=$'- route:\n    id: x\n    from:\n      uri: "http://x?password=secret"\n      steps:\n        - log: { message: "receive schema authz transform enrich route deliver audit respond" }\n'
V2=$(python3 - "$CTRL" "$DEV_TOKEN" "$BAD" <<'PY'
import json, sys, urllib.request
ctrl, tok, yaml = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(
    ctrl + "/api/admin/v1/routes/validate",
    data=json.dumps({"definitionYaml": yaml}).encode(),
    headers={"Authorization": "Bearer " + tok, "Content-Type": "application/json"},
    method="POST",
)
print(urllib.request.urlopen(req).read().decode())
PY
)
echo "$V2" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["valid"] is False; assert any(f["code"]=="SECRET" for f in d["findings"]),d' \
  && ok AT-04-VAL-02 || fail AT-04-VAL-02 "$V2"

echo "==> AT-04-CRT-01 create"
CRT=$(CODE="$CODE" CTRL="$CTRL" TOK="$DEV_TOKEN" GOOD_YAML="$GOOD_YAML" python3 <<'PY'
import json, os, urllib.request
code = os.environ["CODE"]
yaml = "# @lgsp-canvas-v1: e30=\n" + os.environ["GOOD_YAML"]
body = {
  "routeCode": code,
  "title": "AT " + code,
  "sourceSystem": "at-src",
  "targetSystem": "camel-dancu",
  "definitionYaml": yaml,
}
req = urllib.request.Request(
    os.environ["CTRL"] + "/api/admin/v1/routes",
    data=json.dumps(body).encode(),
    headers={"Authorization": "Bearer " + os.environ["TOK"], "Content-Type": "application/json"},
    method="POST",
)
print(urllib.request.urlopen(req).read().decode())
PY
)
echo "$CRT" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="DRAFT",d' && ok AT-04-CRT-01 || fail AT-04-CRT-01 "$CRT"

echo "==> AT-04-GET-01 version yaml"
VER=$(curl -sf "$CTRL/api/admin/v1/routes/$CODE/versions/1" -H "Authorization: Bearer $DEV_TOKEN")
echo "$VER" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert "route:" in d["definitionYaml"] and "@lgsp-canvas" in d["definitionYaml"],d' \
  && ok AT-04-GET-01 || fail AT-04-GET-01 "$VER"

echo "==> AT-04-SUB-01 submit"
SUB=$(curl -sf -X POST "$CTRL/api/admin/v1/routes/$CODE/versions/1/submit" \
  -H "Authorization: Bearer $DEV_TOKEN")
echo "$SUB" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="PENDING_REVIEW",d' && ok AT-04-SUB-01 || fail AT-04-SUB-01 "$SUB"

echo "==> AT-04-QUE-01 pending-review no yaml"
QUE=$(curl -sf "$CTRL/api/admin/v1/routes/pending-review" -H "Authorization: Bearer $REV_TOKEN")
echo "$QUE" | CODE="$CODE" python3 -c 'import os,sys,json;d=json.load(sys.stdin);code=os.environ["CODE"];items=d["items"];hit=[i for i in items if i["routeCode"]==code];assert hit, d; assert not (hit[0].get("definitionYaml") or "").strip(), hit[0]' \
  && ok AT-04-QUE-01 || fail AT-04-QUE-01 "$QUE"

echo "==> AT-04-4EYE-01 same actor blocked"
HTTP=$(curl -sS -o /tmp/at-4eye.json -w '%{http_code}' -X POST \
  "$CTRL/api/admin/v1/routes/$CODE/versions/1/review" \
  -H "Authorization: Bearer $DEV_TOKEN" -H "Content-Type: application/json" \
  -d '{"decision":"APPROVE","comment":"self"}')
test "$HTTP" = "409" && ok AT-04-4EYE-01 || fail AT-04-4EYE-01 "http=$HTTP $(cat /tmp/at-4eye.json)"

echo "==> AT-04-4EYE-02 other reviewer approve"
REV=$(curl -sf -X POST "$CTRL/api/admin/v1/routes/$CODE/versions/1/review" \
  -H "Authorization: Bearer $REV_TOKEN" -H "Content-Type: application/json" \
  -d '{"decision":"APPROVE","comment":"at ok"}')
echo "$REV" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["status"]=="APPROVED",d;assert d.get("gitCommitRef"),d' \
  && ok AT-04-4EYE-02 || fail AT-04-4EYE-02 "$REV"

echo "==> AT-04-GIT-01 gitops file"
GITF="$ROOT/routes/$CODE/route.camel.yaml"
test -f "$GITF" && ok AT-04-GIT-01 || fail AT-04-GIT-01 "missing $GITF"

echo "==> AT-04-PUB-01 no canvas in gitops"
! grep -q '@lgsp-canvas' "$GITF" && ok AT-04-PUB-01 || fail AT-04-PUB-01 "canvas leaked"

echo "==> AT-04-TST-01 test-runs waterfall"
TST=$(curl -sf -X POST "$CTRL/api/admin/v1/routes/$CODE/versions/1/test-runs" \
  -H "Authorization: Bearer $DEV_TOKEN" -H "Content-Type: application/json" \
  -d '{"mode":"MOCK","sample":{"ping":true}}')
echo "$TST" | python3 -c 'import sys,json;d=json.load(sys.stdin);assert d["outcome"]=="PASSED",d;assert len(d["waterfall"])==9,d;assert all("body" not in s and "sample" not in s for s in d["waterfall"])' \
  && ok AT-04-TST-01 || fail AT-04-TST-01 "$TST"

echo "==> AT-04-ONB-01 list no sealed secret"
ONB=$(curl -sf "$CTRL/api/v1/onboarding/applications" -H "Authorization: Bearer $REV_TOKEN")
echo "$ONB" | python3 -c 'import sys,json;d=json.load(sys.stdin);items=d.get("items",[]);
assert all(i.get("clientSecretSealed") in (None,"") for i in items), items[:1]
print("n",len(items))' && ok AT-04-ONB-01 || fail AT-04-ONB-01 "$ONB"

echo
echo "PASS=$PASS FAIL=$FAIL (need ≥10 PASS)"
test "$FAIL" -eq 0
test "$PASS" -ge 10
echo "OK at-ph04"
