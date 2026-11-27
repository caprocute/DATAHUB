#!/usr/bin/env python3
"""Sinh các đoạn tự động của D03-03-PH20 từ ddl/ph20_tenant.sql (theo cách dung_md.py của PH-16, gộp them_dac_ta_bang.py).

Chạy từ thư mục csdl/ph20:  python3 tools/dung_md.py [--write]
Thay đoạn giữa các cặp <!-- gen:X:start --> ... <!-- gen:X:end --> (X = danh-muc, tables, en, fr, thong-ke, check) trong ../D03-03-PH20-csdl-quan-tri-tenant.md.
Khối đặc tả 10 mục mỗi bảng (K-TRINH-BAY §5) trích từ DDL: khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger; EN và FR lấy từ COMMENT ON TABLE.
Không có --write thì in ra màn hình. Sửa DDL ở sinh_ddl.py rồi sinh lại, không sửa tay các đoạn gen.
Chạy lại nhiều lần không nhân bản.
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH20-csdl-quan-tri-tenant.md")
sql = open(os.path.join(ROOT, "ddl", "ph20_tenant.sql"), encoding="utf-8").read()
S = "ph20_tenant"
STD = ["id", "tenant_id", "created_at", "created_by", "updated_at", "updated_by", "version"]

order = re.findall(r"CREATE TABLE %s\.(\w+) \(" % S, sql)
tcomment = dict(re.findall(r"COMMENT ON TABLE %s\.(\w+) IS '((?:[^']|'')*)';" % S, sql))
ccomment = {(t, c): v.replace("''", "'") for t, c, v in re.findall(r"COMMENT ON COLUMN %s\.(\w+)\.(\w+) IS '((?:[^']|'')*)';" % S, sql)}
bodies, part = {}, {}
for m in re.finditer(r"CREATE TABLE %s\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;" % S, sql, re.S):
    bodies[m.group(1)] = m.group(2)
    if m.group(4):
        part[m.group(1)] = m.group(4)
rls = dict(re.findall(r"CALL %s\.p_enable_rls\('%s\.(\w+)', '(\w+)'\);" % (S, S), sql))
rls["tenant"] = "TENANT"
FILEOF = {}
cur = None
for line in sql.split("\n"):
    m = re.match(r"-- @file (\S+)", line)
    if m:
        cur = m.group(1)
    m = re.match(r"CREATE TABLE %s\.(\w+) \(" % S, line)
    if m:
        FILEOF[m.group(1)] = cur

# Nhóm bảng theo tệp changeset (chương 2.2, 3)
GROUP = {
    "20-0010-core.sql": "Hồ sơ tenant, tổ chức, tệp", "20-0020-module.sql": "Phân hệ và tính năng", "20-0030-config.sql": "Cấu hình tenant",
    "20-0040-provision.sql": "Saga khởi tạo", "20-0050-quota.sql": "Hạn mức và sử dụng", "20-0060-lifecycle.sql": "Vòng đời tenant",
    "20-0070-merge.sql": "Sáp nhập", "20-0075-orgimport.sql": "Nhập tổ chức", "20-0080-release.sql": "Phát hành và nâng cấp", "20-0085-ops.sql": "Bảng kỹ thuật",
}

EN_NAME = {}
for l in open(os.path.join(HERE, "en_ten.tsv"), encoding="utf-8"):
    a, b, c = l.rstrip("\n").split("\t")
    EN_NAME[a] = (b, c)
FR_ROWS = [l.rstrip("\n").split("\t") for l in open(os.path.join(HERE, "fr_ten.tsv"), encoding="utf-8")]

# FR không nhắc trong COMMENT của bảng nào: ghi bảng phục vụ
FR_TAY = {
    7: ["tenant", "tenant_quota", "provisioning_template"], 8: ["provisioning_run", "provisioning_step", "idempotency_key"], 9: ["provisioning_step", "provisioning_run"],
    13: ["tenant", "tenant_status_history", "outbox"], 14: ["provisioning_run"], 16: ["provisioning_run", "tenant_module"], 17: ["provisioning_run", "tenant_platform_config"],
    19: ["tenant_platform_config", "tenant_config_version"], 20: ["tenant_config_version", "tenant_platform_config", "outbox"], 24: ["cross_tenant_policy"],
    25: ["lifecycle_request", "provisioning_run"], 30: ["usage_snapshot", "tenant_quota"], 37: ["tenant_module", "platform_module"],
    44: ["tenant_status_history", "outbox"], 56: ["inbox_event", "organization"], 57: ["organization"], 63: ["maintenance_window", "product_release", "outbox"],
    64: ["product_release", "maintenance_window", "tenant_upgrade"], 65: ["tenant", "tenant_platform_config", "tenant_module"], 66: ["tenant", "tenant_module"],
    67: ["tenant", "usage_snapshot", "quota_alert", "leak_test_run"], 68: ["outbox", "tenant_status_history"], 69: ["tenant_settings", "tenant_quota"],
    50: ["merge_participant_run", "merge_mapping"], 10: ["provisioning_step", "provisioning_run"], 11: ["provisioning_step", "provisioning_run"], 12: ["smoke_test_result"], 21: ["tenant_config_version"],
    22: ["config_drift"], 29: ["quota_alert"], 31: ["usage_report"],
}
# Thời gian lưu giữ, dọn (chương 5)
RET = {
    "tenant": "Giữ vĩnh viễn, kể cả `DECOMMISSIONED` (hồ sơ pháp lý); không xóa cứng.",
    "organization": "Giữ trọn đời tenant; giải thể bằng trạng thái, không xóa cứng; lịch sử hiệu lực phục vụ truy vết sáp nhập bộ máy.",
    "tenant_contact": "Giữ theo hợp đồng cộng 5 năm; dữ liệu cá nhân che khi xuất báo cáo.",
    "tenant_contract": "Giữ theo hợp đồng cộng 10 năm (quy định lưu trữ hồ sơ); không xóa cứng.",
    "tenant_config_version": "Giữ 24 phiên bản gần nhất mỗi tenant trong CSDL, bản cũ hơn nằm ở lịch sử Git; chỉ thêm.",
    "config_drift": "Giữ 12 tháng; bản đã xử lý dọn theo lô.",
    "provisioning_run": "Giữ trọn đời tenant (bằng chứng khởi tạo, KPI-12).", "provisioning_step": "Theo lần chạy; không xóa riêng lẻ.",
    "smoke_test_result": "Theo lần chạy saga; chỉ thêm.", "usage_snapshot": "Giữ `20.usage.retention-months` (25) tháng, dọn bằng DETACH, DROP phân vùng tháng.",
    "quota_alert": "Giữ 24 tháng.", "usage_report": "Tệp hết hạn theo `expires_at` (mặc định 30 ngày), dòng giữ 24 tháng.",
    "tenant_status_history": "Giữ vĩnh viễn; chỉ thêm.", "lifecycle_request": "Giữ vĩnh viễn (căn cứ quyết định, bốn mắt).",
    "data_export_package": "Tệp giữ `20.export.retention-days` (90) ngày sau khi sẵn sàng, dòng giữ vĩnh viễn.", "data_export_item": "Theo gói bàn giao.",
    "merge_plan": "Giữ vĩnh viễn.", "merge_mapping": "Giữ vĩnh viễn, phục vụ định tuyến chuyển tiếp và truy vết `origin_tenant_id`.",
    "merge_participant_run": "Giữ vĩnh viễn.", "merge_conflict": "Giữ vĩnh viễn.",
    "org_import_job": "Giữ 12 tháng; tệp nhập dọn sau 90 ngày.", "org_import_row": "Giữ 90 ngày cùng lô nhập.",
    "product_release": "Giữ vĩnh viễn.", "release_component": "Theo phiên bản sản phẩm.", "upgrade_plan": "Giữ vĩnh viễn.", "upgrade_wave": "Theo kế hoạch.",
    "tenant_upgrade": "Giữ vĩnh viễn (lịch sử nâng cấp từng tỉnh).", "leak_test_run": "Giữ 24 tháng (bằng chứng SEC-87).",
    "outbox": "Dọn sau 3 ngày kể từ `published_at`.", "inbox_event": "Dọn sau 14 ngày.", "idempotency_key": "Dọn sau 24 giờ kể từ `expires_at`.",
    "file_object": "Theo `expires_at`; tệp ở kho đối tượng xóa sau hạn, dòng đánh dấu `deleted_at`.",
}
PII = {"tenant_contact": "Có dữ liệu cá nhân (họ tên, thư điện tử, điện thoại), phân loại HC theo DD-09; không đưa vào log, che khi xuất.",
       "organization": "Không có dữ liệu cá nhân; mã định danh điện tử cơ quan là dữ liệu công khai (NB).",
       "tenant_settings": "Địa chỉ hỗ trợ là thư điện tử cơ quan, không phải cá nhân.",
       "cross_tenant_policy": "Danh sách thư nhận thông báo là địa chỉ cơ quan hoặc nhóm.",
       "file_object": "Không lưu nội dung; `sha256` toàn vẹn, `scan_status` bắt buộc `CLEAN` mới xử lý."}


def expand(text):
    out = []
    for m in re.finditer(r"FR-20-(\d{3})((?:(?:, |…)\d{3})*)", text):
        nums, prev = [int(m.group(1))], int(m.group(1))
        for sep, n in re.findall(r"(, |…)(\d{3})", m.group(2)):
            n = int(n)
            nums += list(range(prev + 1, n + 1)) if sep == "…" else [n]
            prev = n
        out += nums
    return out


def ranges(nums):
    nums = sorted(set(nums))
    out, i = [], 0
    while i < len(nums):
        j = i
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1:
            j += 1
        out.append("FR-20-%03d" % nums[i] if j == i else "FR-20-%03d…%03d" % (nums[i], nums[j]) if j > i + 1 else "FR-20-%03d, %03d" % (nums[i], nums[j]))
        i = j + 1
    return ", ".join(out)


fr_tables, en_tables, t_fr = {}, {}, {}
for t in order:
    t_fr[t] = set()
    for n in expand(tcomment[t]):
        fr_tables.setdefault(n, []).append(t)
        t_fr[t].add(n)
    for e in dict.fromkeys(re.findall(r"EN-20-\d{2}", tcomment[t])):
        en_tables.setdefault(e, []).append(t)
for n, ts in FR_TAY.items():
    for t in ts:
        if t in order and t not in fr_tables.setdefault(n, []):
            fr_tables[n].append(t)
            t_fr[t].add(n)


def cons(body, kind):
    out = []
    for c in re.finditer(r"CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK)\s*(.*?)(?:,\n|$)", body, re.S):
        if c.group(2) == kind:
            out.append((c.group(1), re.sub(r"\s+", " ", c.group(3)).strip()))
    return out


def cols_of(t):
    res = []
    for line in bodies[t].split("\n"):
        line = line.strip().rstrip(",")
        if not line or line.startswith("CONSTRAINT"):
            continue
        m = re.match(r"(\w+)\s+(\S+)(.*)$", line)
        if not m:
            continue
        rest = m.group(3)
        d = re.search(r"DEFAULT (.+)$", rest)
        res.append((m.group(1), m.group(2), "NOT NULL" in rest, d.group(1).strip() if d else ""))
    return res


def mo_ta(t):
    return re.sub(r" FR-20-[0-9…, ]+(?: và [^.]*)?\.$", "", tcomment[t].replace("''", "'"))


def first_sentence(s):
    return s


def ds(lst):
    return ", ".join(lst) if lst else "Không"


def short(t, n):
    p = "ck_%s_" % t
    return n[len(p):] if n.startswith(p) else n


def khoi(t):
    b = bodies[t]
    pk = [d for _, d in cons(b, "PRIMARY KEY")]
    uq = ["`%s` %s" % (n, d) for n, d in cons(b, "UNIQUE") if not n.endswith("_id_tenant")]
    for m in re.finditer(r"CREATE UNIQUE INDEX (\w+) ON %s\.%s (\([^;]*?\))(?: WHERE ([^;]*))?;" % (S, t), sql):
        uq.append("`%s` %s%s" % (m.group(1), m.group(2), (" khi " + m.group(3)) if m.group(3) else ""))
    fk = []
    for n, d in cons(b, "FOREIGN KEY"):
        mm = re.match(r"\(([^)]*)\) REFERENCES %s\.(\w+) \(([^)]*)\)(.*)" % S, d)
        fk.append("(%s) → `%s`%s" % (mm.group(1), mm.group(2), " xóa theo" if "CASCADE" in mm.group(4) else "") if mm else d)
    ck = [short(t, n) for n, _ in cons(b, "CHECK")]
    ix = ["`%s`" % m.group(1) for m in re.finditer(r"CREATE INDEX (\w+) ON %s\.%s\b" % (S, t), sql)]
    mode = rls.get(t)
    cl = {
        "OWN": "Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.",
        "CTL": "Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.",
        "TECH": "Mẫu TECH: `tenant_isolation` (FOR ALL) cho tenant ghi cùng giao dịch; `platform_write` cho PLATFORM; `ph20_ro` đọc qua `platform_read`.",
        "PLAT": "Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.",
        "PLATR": "Mẫu PLATR: như PLAT, thêm `platform_data_read` cho phép mọi tenant đọc (`tenant_id = 'PLATFORM'`); chỉ phiên PLATFORM ghi.",
        "TENANT": "Đặc thù (mục 4.3): không có `tenant_id`; `tenant_isolation` cho thấy dòng `code` của phiên; PLATFORM (vai `ph20_platform_app`, `ph20_ro`) thấy mọi dòng; chỉ PLATFORM ghi.",
    }[mode]
    if t == "merge_plan":
        cl += " Thêm `merge_party_read`: tenant nguồn và tenant đích đọc kế hoạch của mình."
    pv = []
    if t in part:
        pv.append("Phân vùng RANGE theo tháng trên `%s` (thủ tục `p_ensure_partitions`), kèm phân vùng mặc định; dọn bằng DETACH PARTITION, DROP" % part[t])
    for m in re.finditer(r"CREATE TRIGGER tg_%s_(\w+) BEFORE ([A-Z ]+?(?: OF \w+)?) ON %s\.%s FOR EACH ROW EXECUTE FUNCTION %s\.(\w+)\((.*?)\);" % (t, S, t, S), sql):
        nm, ev, fn, args = m.groups()
        if fn == "tg_immutable":
            pv.append("Bất biến cột %s (`tg_%s_%s`)" % (args.replace("'", "`"), t, nm))
        elif fn == "tg_transition":
            pv.append("Máy trạng thái `%s` (`tg_%s_%s`)" % (re.match(r"'(\w+)'", args).group(1), t, nm))
        elif fn == "tg_frozen":
            pv.append("Mẫu ACTIVE, RETIRED không đổi nội dung (`tg_%s_%s`)" % (t, nm))
        elif fn == "tg_append_only" or nm == "append_only":
            pv.append("Chỉ thêm, chặn UPDATE và DELETE (`tg_%s_%s`)" % (t, nm))
        elif fn == "tg_no_delete":
            pv.append("Chặn xóa dòng (`tg_%s_%s`)" % (t, nm))
        elif fn == "tg_organization_cycle":
            pv.append("Chặn chu trình cấp trên (`tg_%s_%s`)" % (t, nm))
    if re.search(r"CREATE TRIGGER tg_%s_append_only " % t, sql) and not any("Chỉ thêm" in x for x in pv):
        pv.append("Chỉ thêm, chặn UPDATE và DELETE (`tg_%s_append_only`)" % t)
    frs = sorted(t_fr.get(t, []))
    ghi = RET.get(t, "")
    if t in PII:
        ghi += " " + PII[t]
    muc = [("Mục đích", mo_ta(t)), ("FR phục vụ", ranges(frs) if frs else "Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)"), ("Khóa chính", ds(pk)),
           ("Duy nhất", ds(uq)), ("Khóa ngoại", ds(fk)), ("Ràng buộc CHECK", ("`ck_%s_` + " % t + ", ".join("`%s`" % x for x in ck)) if ck else "Không"),
           ("Chỉ mục", ds(ix) if ix else "Chỉ khóa chính và khóa duy nhất"), ("Cách ly tenant", cl),
           ("Phân vùng, bất biến", "; ".join(pv) or "Không"), ("Lưu giữ, ghi chú", ghi.strip() or "Giữ trọn đời tenant.")]
    o = ["::: dac-ta"]
    for k, v in muc:
        v = v.strip()
        if v and not v.endswith("."):
            v += "."
        o += ["**%s.** %s" % (k, v), ""]
    o[-1] = ":::"
    return "\n".join(o)


def notable(t):
    """Cột nổi bật: có liệt kê, khóa ngoại, hoặc ràng buộc riêng; tối đa 7, kèm cột còn lại một dòng."""
    b = bodies[t]
    fkcols = set(re.findall(r"FOREIGN KEY \((\w+)", b))
    ckcols = set()
    for n, d in cons(b, "CHECK"):
        for c in re.findall(r"\b([a-z_]+) (?:IN|~|<>|>=|<=|BETWEEN|=|IS)", d):
            ckcols.add(c)
    res = []
    for c, typ, nn, d in cols_of(t):
        if c in STD or c == "tenant_id":
            continue
        txt = ccomment.get((t, c), "")
        if c in fkcols or "`" in txt or c in ckcols or "bất biến" in txt or "khóa" in txt.lower():
            res.append(c)
    return res[:5]


def tables_md():
    out = []
    for i, t in enumerate(order, 1):
        out.append("### 3.%d. `%s`\n" % (i, t))
        out.append(khoi(t))
        out.append("")
        cols = {c: (typ, nn, d) for c, typ, nn, d in cols_of(t)}
        nt = notable(t)
        if nt:
            out.append("| Cột | Kiểu | Ghi chú |")
            out.append("|---|---|---|")
            for c in nt:
                typ, nn, d = cols[c]
                kt = "`%s`%s%s" % (typ, "" if nn else ", null", (", mặc định `%s`" % d) if d else "")
                out.append("| `%s` | %s | %s |" % (c, kt, ccomment.get((t, c), "").replace("|", "\\|")))
            out.append("")
            out.append(": Cột nổi bật của bảng `%s`" % t)
            out.append("")
        rest = [c for c in cols if c not in STD and c not in nt and c != "tenant_id"]
        if rest:
            out.append("Cột khác: " + "; ".join("`%s` %s" % (c, cols[c][0].replace("varchar", "v").replace("timestamptz", "ts").replace("boolean", "bool").replace("integer", "int")) for c in rest) + ".")
        else:
            out.append("Không còn cột nào khác.")
        out.append("")
    return "\n".join(out)


def danh_muc():
    o = ["| Mục | Bảng | Nhóm | Thực thể | Chế độ RLS | Phân vùng | FR chính |", "|---|---|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(dict.fromkeys(re.findall(r"EN-20-\d{2}", tcomment[t]))) or ("DD-11" if t == "outbox" else "DD-12" if t == "file_object" else "kỹ thuật")
        fr = ranges(sorted(t_fr.get(t, []))[:3]) if t_fr.get(t) else "dùng chung"
        o.append("| 3.%d | `%s` | %s | %s | %s | %s | %s |" % (i, t, GROUP[FILEOF[t]], ens, rls[t], ("tháng (`%s`)" % part[t]) if t in part else "không", fr))
    o += ["", ": Danh mục %d bảng của schema `ph20_tenant`" % len(order)]
    return "\n".join(o)


def en_md():
    o = ["| EN | Thực thể | Bảng (DDL) | Chương |", "|---|---|---|---|"]
    for e, (name, tb) in EN_NAME.items():
        names = re.findall(r"`(\w+)`", tb)
        refs = ", ".join("3.%d" % (order.index(x) + 1) for x in names if x in order)
        o.append("| %s | %s | %s | %s |" % (e, name, ", ".join("`%s`" % x for x in names), refs))
    o += ["", ": Thực thể EN-20-01…37 và bảng tương ứng"]
    return "\n".join(o)


def fr_md():
    o = ["| FR | Nhóm | Tên | Bảng chính |", "|---|---|---|---|"]
    miss = []
    for r in FR_ROWS:
        n = int(r[0][-3:])
        tb = fr_tables.get(n, [])
        if not tb:
            miss.append(r[0])
        name = r[2].replace("|", "\\|")
        o.append("| %s | %s | %s | %s |" % (r[0], r[1].split(" ")[0], name, ", ".join("`%s`" % x for x in tb) if tb else "Không có bảng riêng (xử lý ở dịch vụ, ghi ở D03-02-PH20)"))
    o += ["", ": Chức năng FR-20-001…070 và bảng phục vụ"]
    if miss:
        sys.stderr.write("FR chưa có bảng: %s\n" % ", ".join(miss))
    return "\n".join(o)


def thong_ke():
    nck = len(re.findall(r"CONSTRAINT \w+ CHECK", sql))
    nuq = len(re.findall(r"CONSTRAINT \w+ UNIQUE", sql))
    nfk = len(re.findall(r"CONSTRAINT \w+ FOREIGN KEY", sql))
    nui = len(re.findall(r"CREATE UNIQUE INDEX", sql))
    nup = len(re.findall(r"CREATE UNIQUE INDEX [^;]*WHERE", sql))
    nix = len(re.findall(r"CREATE INDEX", sql))
    ntg = len(re.findall(r"CREATE TRIGGER", sql))
    return "%d bảng gốc, %d `CHECK`, %d `UNIQUE`, %d khóa ngoại, %d chỉ mục duy nhất (%d một phần), %d chỉ mục thường, %d trigger" % (len(order), nck, nuq, nfk, nui, nup, nix, ntg)


GEN = {"danh-muc": danh_muc, "tables": tables_md, "en": en_md, "fr": fr_md, "thong-ke": thong_ke}


def modules_md():
    o = ["| Mã | Tên phân hệ | Đợt | Đơn vị triển khai | Lõi | Bật mặc định |", "|---|---|---|---|---|---|"]
    for m in re.finditer(r"\('(PH-\d\d)', '([^']*)', (\d), '([^']*)', (true|false), (true|false), \d+\)", sql):
        o.append("| `%s` | %s | %s | `%s` | %s | %s |" % (m.group(1), m.group(2), m.group(3), m.group(4), "có" if m.group(5) == "true" else "không", "có" if m.group(6) == "true" else "không"))
    o += ["", ": Hai mươi phân hệ nạp vào `platform_module`"]
    return "\n".join(o)


def deps_md():
    d = {}
    for m in re.finditer(r"\('(PH-\d\d)', '(PH-\d\d)', '(REQUIRED|OPTIONAL)', '([^']*)'\)", sql):
        d.setdefault(m.group(1), []).append("`%s` (%s)" % (m.group(2), "bắt buộc" if m.group(3) == "REQUIRED" else "tùy chọn"))
    o = ["| Phân hệ | Phụ thuộc |", "|---|---|"]
    for k in sorted(d):
        o.append("| `%s` | %s |" % (k, ", ".join(d[k])))
    n = sum(len(v) for v in d.values())
    o += ["", ": Phụ thuộc chính giữa các phân hệ (%d dòng nạp vào `module_dependency`, giả định chờ FR-20-033)" % n]
    return "\n".join(o)


def quota_md():
    import json
    m = re.search(r"'(\{\"API_RPS\"[^']*\})'::jsonb", sql)
    q = json.loads(m.group(1))
    nguon = {"API_RPS": "D03-10 §5.3 (APISIX `limit-count`)", "ACTIVE_FLOWS": "D03-10 §5.3 (PH-04 khi phát hành)", "KAFKA_PRODUCE_MBPS": "D03-10 §5.3 (quota Kafka)",
             "KAFKA_CONSUME_MBPS": "D03-10 §5.3 (quota Kafka)", "OBJECT_STORAGE_GB": "D03-10 §5.3 (kiểm khi tải lên, cảnh báo 80%)", "DATABASE_GB": "D03-10 §5.3 (giám sát)",
             "USERS": "D03-10 §5.3 (PH-12)"}
    o = ["| Tài nguyên | Mặc định | Cơ sở |", "|---|---|---|"]
    for k, v in q.items():
        o.append("| `%s` | %s | %s |" % (k, format(v, ",").replace(",", "."), nguon.get(k, "Giả định (brief PH-20 mục 5.1)")))
    o += ["", ": Mười hai hạn mức mặc định của mẫu `QM-VUA`"]
    return "\n".join(o)


def steps_md():
    import json
    m = re.search(r"'(\[\{\"stepCode\"[^']*\])'::jsonb", sql)
    st = json.loads(m.group(1))
    o = ["| Thứ tự | Mã bước | Bên thực hiện | Bắt buộc theo mẫu |", "|---|---|---|---|"]
    for i, x in enumerate(st, 1):
        o.append("| %d | `%s` | %s | %s |" % (i, x["stepCode"], x["executor"], "có" if x["required"] else "tùy điều kiện (chế độ cách ly, phân hệ bật)"))
    o += ["", ": Kế hoạch 17 bước saga trong `step_plan` của mẫu `QM-VUA`"]
    return "\n".join(o)


def enum_md():
    sys.path.insert(0, HERE)
    import sinh_ddl
    E = sinh_ddl.ENUM
    in_lists = []
    for t in order:
        for n, d in cons(bodies[t], "CHECK"):
            mm = re.match(r"\((\w+) IN \(([^)]*)\)\)$", d)
            if mm:
                in_lists.append((t, mm.group(1), frozenset(re.findall(r"'([^']*)'", mm.group(2)))))
    keys = list(E)
    frs = keys[:keys.index("TemplateStatus")]
    o = ["| Liệt kê (FRS Phụ lục A) | Số giá trị | Cột dùng trong DDL |", "|---|---|---|"]
    tot_match = 0
    for k in frs:
        vals = frozenset(E[k].split())
        cols = ["`%s.%s`" % (t, c) for t, c, v in in_lists if v == vals]
        tot_match += len(cols)
        o.append("| `%s` | %d | %s |" % (k, len(vals), ", ".join(cols) if cols else "không có cột riêng (chỉ ghi ở ràng buộc phức hợp)"))
    o += ["", ": Đối chiếu liệt kê FRS với `CHECK ... IN (...)` của DDL (%d danh sách trùng đúng một liệt kê)" % tot_match]
    o += ["", "| Liệt kê bổ sung của CSDL | Giá trị |", "|---|---|"]
    for k in keys[keys.index("TemplateStatus"):]:
        o.append("| `%s` | %s |" % (k, ", ".join("`%s`" % v for v in E[k].split())))
    o += ["", ": Liệt kê bổ sung do CSDL đặt thêm, không có ở FRS Phụ lục A (đề nghị đồng bộ 11.2)"]
    return "\n".join(o)


GEN.update({"modules": modules_md, "deps": deps_md, "quota": quota_md, "steps": steps_md, "enum": enum_md})


def main():
    write = "--write" in sys.argv
    if not write:
        for k, f in GEN.items():
            print("<!-- gen:%s:start -->\n%s\n<!-- gen:%s:end -->" % (k, f(), k))
        return
    doc = open(DOC, encoding="utf-8").read()
    for k, f in GEN.items():
        pat = re.compile(r"(<!-- gen:%s:start -->\n).*?(\n<!-- gen:%s:end -->)" % (k, k), re.S)
        if not pat.search(doc):
            sys.stderr.write("thiếu đoạn gen:%s\n" % k)
            continue
        doc = pat.sub(lambda m: m.group(1) + f() + m.group(2), doc)
    open(DOC, "w", encoding="utf-8").write(doc)
    print("đã ghi", DOC)


if __name__ == "__main__":
    main()
