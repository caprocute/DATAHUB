#!/usr/bin/env python3
"""Sinh các khối bảng của D03-04-PH12 từ spec.OPS, openapi-iam.yaml, asyncapi-iam.yaml và FRS §9:
gen:endpoints (§3.2), gen:coverage (§3.3), gen:events (§4.1), gen:errors (§6). Chèn giữa các cặp dấu <!-- gen:x:start/end -->."""
import glob, os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec, gen_asyncapi as ga

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-04-PH12-api-dinh-danh-phan-quyen.md")
FRSF = glob.glob(os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH12-*.md"))[0]
frs = open(FRSF, encoding="utf-8").read()
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-iam.yaml"), encoding="utf-8"))
OP = {o["x-datahub-id"]: (m, p, o) for p, it in oa["paths"].items() for m, o in it.items()}

def full_path(code, path, server):
    if server == "authz": return spec.AUTHZ_BASE + path
    return path

def perm_txt(op):
    t = op["x-datahub-permission"]["permission"]
    return t if t.startswith("`") else (f"`{t}`" if t.startswith("PERM") else t)

blocks = {}
# ---- endpoints
groups = {}
for code, method, path, summary, fr, perm, success, group, server in spec.OPS:
    m, p, o = OP[f"API-12-{code}"]
    idem = "có" if o.get("x-datahub-idempotent") else ""
    frn = ", ".join(f.split("-")[-1] for f in o["x-datahub-fr"])
    groups.setdefault(group, []).append(f"| API-12-{code} | `{method} {full_path(code, path, server)}` | {summary} | {frn} | {perm_txt(o)} | {idem} | {success} |")
rows = []
for g, lst in groups.items():
    rows.append(f"**{spec.TAGS[g]}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền hoặc scope | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|\n" + "\n".join(lst) + f"\n\n: Endpoint nhóm {spec.TAGS[g].lower()}")
blocks["endpoints"] = "\n\n".join(rows)

# ---- phủ FR
NOTE = {
 6: "Chỉ giao diện: trang kích hoạt của Keycloak (đặt mật khẩu, ERR-12-015, 016); liên kết gửi bằng API-12-003, 009",
 7: "Chỉ giao diện: trang đặt lại mật khẩu của Keycloak; phát sinh sự kiện EVT-12-04, 16",
 8: "Tác vụ định kỳ của `dh-platform` (ShedLock); không có API riêng, kết quả qua API-12-001, 056 và EVT-12-02, 07",
 10: "Tác vụ đồng bộ danh mục đơn vị (PH-07) theo sự kiện; không có API riêng",
 21: "Cấu hình bảo mật realm của Keycloak; vết ở API-12-105",
 28: "Đăng nhập VNeID qua OIDC của Keycloak (Đợt 2, `12.vneid.enabled`)",
 35: "Máy gọi bằng mTLS hoặc `private_key_jwt`; scope máy ở mục 2.3",
 38: "Cấu hình xoay vòng, phát hiện dùng lại ở realm; vết ở EVT-12-16",
 50: "Bộ đệm quyết định nằm ở thư viện PEP và plugin `dh-authz`; cấu hình `12.cache.ttl-seconds` ở API-12-110, 111",
}
cov = {i: [] for i in range(1, 63)}
for code, *_rest in spec.OPS:
    m, p, o = OP[f"API-12-{code}"]
    for f in o["x-datahub-fr"]:
        cov[int(f.split("-")[-1])].append(f"API-12-{code}")
FRT = dict(re.findall(r"^\| (FR-12-\d{3}) \| [A-H] \| ([^|]+) \|", frs, re.M))
r = ["| FR | Chức năng | API |", "|---|---|---|"]
for i in range(1, 63):
    k = f"FR-12-{i:03d}"
    a = cov[i]
    if i in NOTE and not a: txt = NOTE[i]
    elif i in NOTE: txt = ", ".join(a) + "; " + NOTE[i]
    else: txt = ", ".join(a) if len(a) <= 7 else ", ".join(a[:7]) + f" và {len(a) - 7} API khác"
    if not txt: txt = "Không có API công bố: xem FRS"
    r.append(f"| {k} | {FRT.get(k, '').strip()} | {txt} |")
blocks["coverage"] = "\n".join(r) + "\n\n: Phủ chức năng của PH-12 bởi API"

# ---- sự kiện
OWN = {"outbox": "`dh-platform` (outbox)", "keycloak": "Keycloak (`dh-keycloak-spi`)"}
r = ["| Mã | Topic | Người phát | Khóa phân vùng | Giữ | Phân vùng | Người nhận |", "|---|---|---|---|---|---|---|"]
for key, code, addr, payload, summ, days, parts, src, kdesc, recv in ga.EV:
    r.append(f"| {code} | `{addr}` | {OWN[src]} | {kdesc} | {days} ngày | {parts} | {recv} |")
blocks["events"] = "\n".join(r) + "\n\n: Danh mục sự kiện của PH-12"

# ---- lỗi
errs = re.findall(r"^\| (ERR-12-\d{3}) \| (\d{3}) \| ([^|]+) \|$", frs, re.M)
uses = {}
for code, *_ in spec.OPS:
    m, p, o = OP[f"API-12-{code}"]
    for e in o.get("x-datahub-errors", []): uses.setdefault(e, []).append(code)
def fmt(lst, n=6):
    lst = sorted(set(lst))
    if len(lst) > 12: return f"{len(lst)} API (xem OpenAPI)"
    t = ", ".join(lst[:n])
    return t + (f" và {len(lst) - n} API khác" if len(lst) > n else "")
EXTRA = {"ERR-12-015": "Trang đặt mật khẩu của Keycloak (FR-12-006, 007)", "ERR-12-016": "Trang kích hoạt, đặt lại mật khẩu của Keycloak (FR-12-006, 007)",
         "ERR-12-124": "Thư viện PEP và plugin `dh-authz` (AuditGate), không qua API công bố"}
r1 = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-12-) |", "|---|---|---|---|"]
r2 = ["| Mã | HTTP | Ý nghĩa | Nơi phát sinh |", "|---|---|---|---|"]
for c, http, mean in errs:
    n = int(c[-3:])
    if n < 100:
        u = fmt(uses.get(c, [])) or EXTRA.get(c, "")
        r1.append(f"| {c} | {http} | {mean.strip()} | {u} |")
    else:
        ids = sorted(set(uses.get(c, [])))
        u = ", ".join("API-12-" + i for i in ids) if ids else EXTRA.get(c, "")
        r2.append(f"| {c} | {http} | {mean.strip()} | {u} |")
rs = re.search(r"\| Lý do \(`reason`\) \|.*?\n\n", frs, re.S)
rsn = re.search(r"(\| Mã \| Câu hiển thị \| Vị trí \|.*?)\n\n", frs, re.S)
blocks["errors"] = ("### 6.1. Lỗi API quản trị (ERR-12-001…047)\n\n" + "\n".join(r1) + "\n\n: Mã lỗi control plane của PH-12\n\n"
    "### 6.2. Lỗi runtime (ERR-12-101…125)\n\nCác mã dưới đây phát sinh ở API quyết định (`/api/authz/v1`, thân RFC 9457) và ở điểm cuối OIDC của Keycloak (thân RFC 6749, mã chỉ ghi vào nhật ký và hiển thị ở trang của Keycloak).\n\n"
    + "\n".join(r2) + "\n\n: Mã lỗi runtime của PH-12\n\n"
    "### 6.3. Thông báo hiển thị theo mã lỗi\n\nBảng sau lấy nguyên từ FRS §9.2 để hai tài liệu không lệch; nguồn chuẩn của câu hiển thị là D03-06-PH12 §5.2.\n\n"
    + (rsn.group(1) if rsn else "") + "\n\n: Thông báo hiển thị theo mã lỗi")

s = open(DOC, encoding="utf-8").read()
for k, v in blocks.items():
    pat = rf"<!-- gen:{k}:start -->.*?<!-- gen:{k}:end -->"
    if not re.search(pat, s, flags=re.S):
        print("thiếu dấu", k); continue
    s = re.sub(pat, lambda m: f"<!-- gen:{k}:start -->\n{v}\n<!-- gen:{k}:end -->", s, flags=re.S)
open(DOC, "w", encoding="utf-8").write(s)
print({k: v.count("\n") for k, v in blocks.items()})
