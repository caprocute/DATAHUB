#!/usr/bin/env python3
"""Sinh ba bảng của D03-03-PH09 từ DDL: danh mục bảng (mục 1.6), ánh xạ EN → bảng, ánh xạ FR → bảng (mục 8).

Chạy từ thư mục csdl/ph09:  python3 tools/gen_anh_xa.py [--write]
Đọc COMMENT ON TABLE (mã EN-09-nn, FR-09-nnn, kể cả danh sách "FR-09-018, 019" và dải "FR-09-036…042") và PARTITION BY.
Với --write thay đoạn giữa các cặp <!-- gen:danh-muc:start/end -->, <!-- gen:en:start/end -->, <!-- gen:fr:start/end -->
trong ../D03-03-PH09-csdl-quyen-rieng-tu.md. FR không có bảng nào nhắc trong COMMENT dùng bảng ghi tay ở FR_TAY.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH09-csdl-quyen-rieng-tu.md")
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH09-frs-quyen-rieng-tu.md")
sql = open(os.path.join(ROOT, "ddl", "ph09_privacy.sql"), encoding="utf-8").read()
frs = open(FRS, encoding="utf-8").read()

order = re.findall(r"CREATE TABLE ph09_privacy\.(\w+) \(", sql)
cm = dict(re.findall(r"COMMENT ON TABLE ph09_privacy\.(\w+) IS '((?:[^']|'')*)';", sql))
part = dict(re.findall(r"CREATE TABLE ph09_privacy\.(\w+) \(.*?\n\) PARTITION BY RANGE \((\w+)\);", sql, re.S))
en_name = dict(re.findall(r"^\| (EN-09-\d{2}) \| `(\w+)` \|", frs, re.M))
FR_TAY = {  # chức năng không có bảng riêng: ghi bảng phục vụ
    13: ["processing_activity", "activity_link", "legal_basis", "legal_document"],
    8: ["data_element", "element_classification", "classification_change"],
    21: ["usage_counter", "purpose_grant", "usage_anomaly"],
    22: ["contract_level", "purpose_grant", "processing_activity"],
    27: ["mask_policy", "mask_rule", "mask_type", "element_classification", "policy_bundle"],
    28: ["mask_policy", "mask_rule", "mask_type"],
    32: ["pseudonym_domain", "pseudonym_key"],
    51: ["subject_request", "subject_task", "privacy_audit_event"],
}


def expand(text):
    out = []
    for m in re.finditer(r"(?<![A-Z])FR-09-(\d{3})((?:(?:, |…)\d{3})*)", text):
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
    for e in dict.fromkeys(re.findall(r"EN-09-\d{2}", cm[t])):
        en_tables.setdefault(e, []).append(t)
FR_THEM = {  # bảng đọc hoặc ghi thêm ngoài bảng được nhắc ở COMMENT
    6: ["data_element", "element_classification", "block_label"], 10: ["dpia_record"], 19: ["purpose", "purpose_grant", "grant_condition", "subject_request"],
    20: ["purpose_grant"], 31: ["purpose"], 33: ["pseudonym_domain", "pseudonym_key", "privacy_audit_event"], 34: ["pseudonym_domain"],
    41: ["retention_schedule_line", "legal_hold"], 54: ["consent_template"], 47: ["privacy_audit_event"], 24: ["mask_type", "personal_data_category"],
    29: ["element_classification", "privacy_audit_event"], 44: ["retention_schedule"], 36: ["anonymization_config"], 37: ["anonymization_job"],
}
for n, ts in FR_TAY.items():
    fr_tables.setdefault(n, ts)
for n, ts in FR_THEM.items():
    cur = fr_tables.setdefault(n, [])
    cur += [t for t in ts if t not in cur]


def code(ts):
    return ", ".join("`%s`" % t for t in ts)


def danh_muc():
    L = ["| Mục | Bảng | Thực thể | Phân vùng | FR chính |", "|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(dict.fromkeys(re.findall(r"EN-09-\d{2}", cm[t]))) or "Bổ sung"
        frs_ = sorted(n for n, ts in fr_tables.items() if t in ts)
        fr_txt = ", ".join("%03d" % n for n in frs_[:5]) + ("…" if len(frs_) > 5 else "") if frs_ else "Hạ tầng"
        L.append(f"| 3.{i} | `{t}` | {ens} | {'Tháng, ' + part[t] if t in part else 'Không'} | {fr_txt} |")
    L += ["", ": Danh mục bảng của schema ph09_privacy", ""]
    return "\n".join(L)


def en():
    L = ["| Thực thể | Tên ở FRS 4.2 | Bảng hiện thực |", "|---|---|---|"]
    for e in sorted(en_name):
        L.append(f"| {e} | `{en_name[e]}` | {code(en_tables.get(e, []))} |")
    extra = [t for t in order if not re.search(r"EN-09-\d{2}", cm[t])]
    L += ["", ": Ánh xạ thực thể EN-09 sang bảng", "",
          "Bảng không có mã EN ở FRS 4.2 (bổ sung để hiện thực chức năng): " + code(extra) + "."]
    return "\n".join(L)


def fr():
    L = ["| FR-09 | Bảng hiện thực | FR-09 | Bảng hiện thực |", "|---|---|---|---|"]
    for n in range(1, 33):
        L.append(f"| {n:03d} | {code(fr_tables[n])} | {n + 32:03d} | {code(fr_tables[n + 32])} |")
    L += ["", ": Ánh xạ FR-09-001…064 sang bảng (hai cột song song: 001 đến 032 và 033 đến 064)", ""]
    return "\n".join(L)


BLOCKS = {"en": en, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 65) if n not in fr_tables]
    if miss:
        print("FR chưa có bảng:", miss)
        sys.exit(1)
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        for k, f in BLOCKS.items():
            doc, n = re.subn(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (k, k), lambda m: m.group(1) + f() + "\n" + m.group(2), doc, flags=re.S)
            print(k, "đã chèn" if n else "THIẾU cặp đánh dấu")
        open(DOC, "w", encoding="utf-8").write(doc)
    else:
        for k, f in BLOCKS.items():
            print(f"--- {k}\n{f()}")
