#!/usr/bin/env python3
"""Sinh bảng endpoint (§3), bảng sự kiện (§4) và bảng mã lỗi (§6) của D03-04-PH03 từ spec.py và openapi-gateway.yaml.

Chèn giữa các cặp đánh dấu <!-- gen:endpoints|events|errors:start/end -->. Chạy sau gen_openapi.py.
"""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(HERE), "D03-04-PH03-api-cong-api.md")
oa = yaml.safe_load(open(os.path.join(HERE, "openapi-gateway.yaml"), encoding="utf-8"))
ops = {}
for p, m in oa["paths"].items():
    for meth, o in m.items():
        ops[o["x-datahub-id"].split("-")[-1]] = o

s = open(DOC, encoding="utf-8").read()


def fmt(lst):
    lst = sorted(lst)
    return ", ".join(lst) if len(lst) <= 8 else ", ".join(lst[:8]) + f" và {len(lst) - 8} API khác"


def sub(name, block):
    global s
    pat = rf"<!-- gen:{name}:start -->.*?<!-- gen:{name}:end -->"
    new = f"<!-- gen:{name}:start -->\n{block}\n<!-- gen:{name}:end -->"
    if not re.search(pat, s, flags=re.S):
        sys.exit(f"Thiếu cặp đánh dấu gen:{name} trong tài liệu")
    s = re.sub(pat, lambda m: new, s, flags=re.S)


# ---- §3 endpoint
rows, cur = [], None
for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
    if group != cur:
        cur = group
        rows.append(f"\n**{spec.TAGS[group]}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
    q = f"`{spec.SERVICE_SCOPE[perm]}` (dịch vụ)" if perm in spec.SERVICE_SCOPE else f"`PERM-03-{perm}`"
    o = ops[code]
    ok = "/".join(sorted(k for k in o["responses"] if k.startswith("2")))
    ok = success if ok == success else f"{success} ({ok.replace(success, '').strip('/')})"
    rows.append(f"| API-03-{code} | `{method} {path}` | {summary} | {fr} | {q} | {'có' if idem else ''} | {ok} |")
    if (nxt := [x for x in spec.OPS if x[0] == f"{int(code) + 1:03d}"]) and nxt[0][8] != group or code == "096":
        rows.append(f"\n: Danh mục endpoint · {spec.TAGS[group]}")
sub("endpoints", "\n".join(rows).lstrip("\n"))

# ---- §4 sự kiện
ev = ["| Mã | Topic | Khi nào | Bên phát | Khóa phân vùng | Bên nhận |", "|---|---|---|---|---|---|"]
for key, code, addr, payload, summ, days, parts, sender, kdesc, recv in spec.EVENTS:
    ev.append(f"| {code} | `{addr}` | {summ} | {sender} | {kdesc} | {recv} |")
ev.append("\n: Danh mục sự kiện của PH-03")
sub("events", "\n".join(ev))


# ---- §6 lỗi
uses = {}
for code, o in ops.items():
    for e in o["x-datahub-errors"]:
        uses.setdefault(e, []).append(code)


GENERIC = {"ERR-03-022": "Mọi API", "ERR-03-001": "Mọi API có mã trong đường dẫn", "ERR-03-003": "Mọi API có thân hoặc tham số truy vấn", "ERR-03-004": "Mọi lệnh sửa, xóa, đổi trạng thái có `If-Match`"}
r1 = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-03-) |", "|---|---|---|---|"]
for c, (st, title, mean) in spec.ERR_CP.items():
    e = f"ERR-03-{c}"
    r1.append(f"| {e} | {st} | {mean} | {GENERIC.get(e) or fmt(uses.get(e, [])) or 'Không qua API'} |")
r1.append("\n: Mã lỗi control plane ERR-03-001…027")
r2 = ["| Mã | HTTP | Ý nghĩa | Bên gọi nên làm | Thử lại | Chốt phát sinh |", "|---|---|---|---|---|---|"]
STAGE = {"101": "`request-validation`, `client-control`", "102": "`dh-auth`", "103": "`dh-auth`", "104": "`dh-auth`", "105": "`dh-revocation`", "106": "`dh-auth` (SEC-80)",
         "107": "`dh-auth`", "108": "`dh-auth`, `ssls` (mTLS)", "109": "Coraza, `dh-waf-guard`", "110": "`dh-ip-block`", "111": "`dh-auth`", "112": "`opa`", "113": "`dh-path-acl`",
         "114": "Bộ định tuyến", "115": "`client-control`", "116": "`dh-limit`, `dh-adaptive-throttle`", "117": "`dh-limit`", "118": "`dh-limit`", "119": "`dh-ip-block`",
         "120": "`api-breaker`, upstream", "121": "Upstream", "122": "Upstream", "123": "`dh-kill-switch`", "124": "`dh-auth`, `opa`", "125": "Plugin chuyển đổi (Đợt 3)",
         "126": "`dh-kill-switch` (phiên bản SUNSET)", "127": "`dh-kill-switch`", "128": "`dh-edge`", "129": "`dh-problem`", "130": "`dh-auth`"}
for c, (st, title, mean, todo, retry) in spec.ERR_GW.items():
    r2.append(f"| ERR-03-{c} | {st} | {mean} | {todo} | {'có' if retry else 'không'} | {STAGE[c]} |")
r2.append("\n: Mã lỗi gateway ERR-03-101…130 trả cho bên gọi")
sub("errors", "### 6.1. Lỗi API điều khiển (ERR-03-001…027)\n\nTrả bởi `dh-connect`, thân `ProblemDetails`. Cột cuối nêu API phát sinh để kiểm thử viên chọn đúng ca âm.\n\n"
    + "\n".join(r1) + "\n\n### 6.2. Lỗi gateway trả cho bên gọi (ERR-03-101…130)\n\nKhông trả qua API ở chương 3. Plugin APISIX dựng thân `GatewayProblem` (RFC 9457) ở `dh-problem`; bảng sinh từ cùng nguồn `spec.py` với `errors.json` của plugin (SDD §8.4).\n\n"
    + "\n".join(r2))

# ---- §2 quyền -> API
perm_api = {}
for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
    perm_api.setdefault(perm, []).append(code)
PERM_TXT = {"read": "Xem cấu hình, route, consumer, hạn mức, nút, tổng quan", "admin": "Chính sách gateway: tham số, mẫu chính sách, chứng thư biên, CORS, chạy thử, nhập hệ cũ, chuyển tiếp tenant",
            "limit": "Hạn mức toàn tenant, ghi đè hạn mức", "waf-request": "Đề nghị ngoại lệ WAF, xem sự kiện chặn của WAF", "waf-approve": "Duyệt, từ chối ngoại lệ WAF",
            "waf": "Đổi chế độ WAF, luật vá ảo, chặn và bỏ chặn địa chỉ, thu hồi ngoại lệ", "operate": "Dừng, mở, tạm ngừng khẩn cấp, quay lui, gia hạn chứng thư, xác nhận cảnh báo",
            "publish": "Kiểm tra, xây, phát ảnh chụp cấu hình", "approve": "Duyệt yêu cầu thay đổi bốn mắt", "log-read": "Nhật ký lượt gọi chi tiết, xuất nhật ký và báo cáo",
            "sync": "Tạo, cập nhật, gỡ consumer (PH-01, saga kết nạp)", "revoke": "Đẩy danh sách chặn token (PH-12)"}
pr = ["| Quyền hoặc scope | Cho phép | Người giữ | API-03- | Số API |", "|---|---|---|---|---|"]
WHO = {"read": "PA, PO, TA, TO, SO, AU", "admin": "PA, TA, SO", "limit": "PA, TA", "waf-request": "PA, TA, TO, SO", "waf-approve": "SO", "waf": "PA, SO",
       "operate": "PA, TA, TO, SO", "publish": "PA, TA", "approve": "TA, SO", "log-read": "PA, TA, TO, SO, AU", "sync": "Tài khoản dịch vụ PH-01", "revoke": "Tài khoản dịch vụ PH-12"}
for k in ["read", "admin", "limit", "waf-request", "waf-approve", "waf", "operate", "publish", "approve", "log-read", "sync", "revoke"]:
    nm = f"`{spec.SERVICE_SCOPE[k]}`" if k in spec.SERVICE_SCOPE else f"`PERM-03-{k}`"
    pr.append(f"| {nm} | {PERM_TXT[k]} | {WHO[k]} | {fmt(perm_api[k]) if len(perm_api[k]) <= 12 else ', '.join(perm_api[k][:12]) + ' và ' + str(len(perm_api[k]) - 12) + ' API khác'} | {len(perm_api[k])} |")
pr.append("\n: Quyền và scope theo số API")
sub("perm", "\n".join(pr))

# ---- §3 phủ FR -> API
frs = open(os.path.join(os.path.dirname(os.path.dirname(HERE)), "..", "02-yeu-cau", "frs", "D02-03-PH03-frs-cong-api.md"), encoding="utf-8").read()
fr_rows = re.findall(r"^\| (FR-03-\d{3}) \| ([A-G]) \| ([^|]+) \| ([MSC]) \|", frs, re.M)
fr_api = {}
for code, o in ops.items():
    for f in o["x-datahub-fr"]:
        fr_api.setdefault(f, []).append(code)
cv = ["| FR | Nhóm | Chức năng | API-03- |", "|---|---|---|---|"]
no_api = 0
for f, g, name, lvl in fr_rows:
    a = fr_api.get(f)
    if not a: no_api += 1
    cv.append(f"| {f} | {g} | {name.strip()} | {', '.join(sorted(a)) if a else 'Mặt phẳng dữ liệu, không có API quản trị'} |")
cv.append("\n: Phủ chức năng FR-03 bằng API")
sub("frmap", "\n".join(cv))
print(len(fr_rows), "FR,", no_api, "FR chỉ ở mặt phẳng dữ liệu")

open(DOC, "w", encoding="utf-8").write(s)
print(len(spec.OPS), "dòng endpoint,", len(spec.EVENTS), "sự kiện,", len(spec.ERR_CP) + len(spec.ERR_GW), "mã lỗi")
