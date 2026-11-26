#!/usr/bin/env python3
"""Sinh ba bảng của D03-03-PH11 từ DDL: danh mục bảng (mục 1.6), ánh xạ EN → bảng, ánh xạ FR → bảng (mục 8).

Chạy từ thư mục csdl/ph11:  python3 tools/gen_anh_xa.py [--write]
Đọc COMMENT ON TABLE (mã EN-11-nn, FR-11-nnn, kể cả danh sách "FR-11-018, 019" và dải "FR-11-036…042") và PARTITION BY.
Với --write thay đoạn giữa các cặp <!-- gen:danh-muc:start/end -->, <!-- gen:en:start/end -->, <!-- gen:fr:start/end -->
trong ../D03-03-PH11-csdl-quy-trinh.md. Tên thực thể lấy ở FRS Phụ lục A nếu FRS đã có bảng "| EN-11-nn | `tên` |",
nếu chưa thì dùng bảng EN_BRIEF (brief PH-11 §7). FR không có bảng nào nhắc trong COMMENT dùng bảng ghi tay ở FR_TAY.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH11-csdl-quy-trinh.md")
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH11-frs-quy-trinh.md")
sql = open(os.path.join(ROOT, "ddl", "ph11_bpm.sql"), encoding="utf-8").read()
frs = open(FRS, encoding="utf-8").read() if os.path.exists(FRS) else ""

order = re.findall(r"CREATE TABLE ph11_bpm\.(\w+) \(", sql)
cm = dict(re.findall(r"COMMENT ON TABLE ph11_bpm\.(\w+) IS '((?:[^']|'')*)';", sql))
part = dict(re.findall(r"CREATE TABLE ph11_bpm\.(\w+) \((?:(?!CREATE TABLE).)*?\n\) PARTITION BY RANGE \((\w+)\);", sql, re.S))
EN_BRIEF = {1: "process_model", 2: "process_version", 3: "form_definition", 4: "service_intent", 5: "compensation_action",
            6: "process_template", 7: "variable_definition", 8: "instance_index", 9: "task_index", 10: "task_comment",
            11: "task_attachment", 12: "delegation", 13: "business_calendar", 14: "calendar_day", 15: "due_tracking",
            16: "saga_log", 17: "saga_step", 18: "incident", 19: "migration_plan", 20: "publish_request", 21: "outbox_event",
            22: "inbox_message", 23: "tenant_setting", 24: "decision_table", 25: "service_call", 26: "test_run", 27: "instance_change"}
en_name = {"EN-11-%02d" % k: v for k, v in EN_BRIEF.items()}
PROPOSED = {"EN-11-29": "saga_skip_request", "EN-11-30": "legal_hold", "EN-11-31": "compliance_sample_run"}  # đề nghị EN, chưa có ở FRS (mục 9.2)
en_name.update(dict(re.findall(r"^\| (EN-11-\d{2}) \| `(\w+)` \|", frs, re.M)))
FR_NHOM = {"A": (1, 11), "B": (12, 17), "C": (18, 27), "D": (28, 33), "E": (34, 44), "F": (45, 50), "G": (51, 54), "H": (55, 57), "I": (58, 61), "J": (62, 66)}
FR_TAY = {  # chức năng không có bảng riêng: ghi bảng phục vụ
    11: ["instance_index", "service_call", "instance_step"],
    31: ["instance_step", "due_tracking", "incident"],
    32: ["outbox_event"],
    33: ["instance_index", "instance_step"],
    58: ["instance_index", "task_index", "due_tracking", "saga_log", "incident"],
    65: ["outbox_event", "instance_step"],
    66: ["task_index", "task_comment", "instance_step"],
}


def expand(text):
    out = []
    for m in re.finditer(r"FR-11-(\d{3})((?:(?:, |…)\d{3})*)", text):
        nums, prev = [int(m.group(1))], int(m.group(1))
        for sep, n in re.findall(r"(, |…)(\d{3})", m.group(2)):
            n = int(n)
            nums += list(range(prev + 1, n + 1)) if sep == "…" else [n]
            prev = n
        out += nums
    return out


fr_tables, en_tables = {}, {}
for t in order:
    for n in expand(cm[t]):
        fr_tables.setdefault(n, []).append(t)
    for e in dict.fromkeys(re.findall(r"EN-11-\d{2}", cm[t])):
        en_tables.setdefault(e, []).append(t)
for n, ts in FR_TAY.items():
    fr_tables.setdefault(n, ts)


def code(ts):
    return ", ".join("`%s`" % t for t in ts)


def danh_muc():
    L = ["| Mục | Bảng | Thực thể | Phân vùng | FR chính |", "|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(e for e in dict.fromkeys(re.findall(r"EN-11-\d{2}", cm[t])) if e not in PROPOSED) or "Ngoài FRS"
        pr = [e for e in PROPOSED if PROPOSED[e] == t]
        if pr: ens = "Ngoài FRS (đề nghị %s)" % pr[0]
        frs_ = sorted(n for n, ts in fr_tables.items() if t in ts)
        fr_txt = ", ".join("%03d" % n for n in frs_[:5]) + ("…" if len(frs_) > 5 else "") if frs_ else "Hạ tầng"
        L.append(f"| 3.{i} | `{t}` | {ens} | {'Tháng, ' + part[t] if t in part else 'Không'} | {fr_txt} |")
    L += ["", ": Danh mục bảng của schema ph11_bpm", ""]
    return "\n".join(L)


def en():
    L = ["| Thực thể | Tên | Bảng hiện thực |", "|---|---|---|"]
    for e in sorted(en_name):
        L.append(f"| {e} | `{en_name[e]}` | {code(en_tables.get(e, []))} |")
    extra = [t for t in order if not [e for e in re.findall(r"EN-11-\d{2}", cm[t]) if e not in PROPOSED]]
    L += ["", ": Ánh xạ thực thể EN-11 sang bảng", "",
          "Bảng ngoài danh mục EN của FRS (đề nghị bổ sung, mục 9.2): " + ", ".join(("`%s` (đề nghị %s)" % (t, [e for e in PROPOSED if PROPOSED[e] == t][0])) if t in PROPOSED.values() else "`%s`" % t for t in extra) + "."]
    return "\n".join(L)


def fr():
    L = ["| Nhóm | FR | Bảng hiện thực |", "|---|---|---|"]
    for g, (a, b) in FR_NHOM.items():
        run = []  # gộp các FR liền nhau cùng danh sách bảng
        for n in range(a, b + 1):
            ts = code(fr_tables.get(n, [])) or 'Không có bảng riêng'
            if run and run[-1][2] == ts:
                run[-1][1] = n
            else:
                run.append([n, n, ts])
        for x, y, ts in run:
            L.append(f"| {g} | FR-11-{x:03d}" + (f"…{y:03d}" if y > x else "") + f" | {ts} |")
    L += ["", ": Ánh xạ FR-11 sang bảng", ""]
    return "\n".join(L)


BLOCKS = {"danh-muc": danh_muc, "en": en, "fr": fr}
if __name__ == "__main__":
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        for k, f in BLOCKS.items():
            doc = re.sub(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (k, k), lambda m: m.group(1) + f() + "\n" + m.group(2), doc, flags=re.S)
        open(DOC, "w", encoding="utf-8").write(doc)
        print("Đã chèn danh mục, ánh xạ EN, FR vào", DOC)
    else:
        for k, f in BLOCKS.items():
            print("<!-- %s -->" % k); print(f())
