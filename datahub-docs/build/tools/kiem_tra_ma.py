#!/usr/bin/env python3
"""Soát bộ tài liệu datahub-docs: mã trùng, mã thiếu, liên kết hỏng.

Chạy từ gốc repo hoặc bất kỳ đâu:

    python3 datahub-docs/build/tools/kiem_tra_ma.py            # soát, so với ngoại lệ đã ghi nhận
    python3 datahub-docs/build/tools/kiem_tra_ma.py --tat-ca   # in mọi lỗi, kể cả đã ghi nhận
    python3 datahub-docs/build/tools/kiem_tra_ma.py --ghi-ngoai-le   # chụp lại danh sách ngoại lệ
    python3 datahub-docs/build/tools/kiem_tra_ma.py --dai-ma   # in bảng dải mã đã dùng (Markdown)
    python3 datahub-docs/build/tools/kiem_tra_ma.py --cap-nhat-so-tra-cuu  # ghi bảng dải mã vào D00-04

Quy tắc (xem D00-04 §6):

* Mỗi họ mã có một "tài liệu gốc" theo D00-01 §3.1. Mã được coi là ĐỊNH NGHĨA khi nó
  nằm trong tiêu đề, hoặc ở ô thứ nhất hay thứ hai của một hàng bảng, trong tài liệu gốc.
* MÃ THIẾU: mã được nhắc ở bất kỳ đâu nhưng tài liệu gốc đã có mà không định nghĩa nó.
  Nếu tài liệu gốc chưa viết, mã được đếm là "chờ tài liệu gốc" (thông tin, không lỗi).
* MÃ TRÙNG: cùng một mã là tiêu đề của hai mục, hoặc là ô đầu của hai hàng trong cùng
  một bảng của tài liệu gốc.
* LIÊN KẾT HỎNG: liên kết Markdown tương đối trỏ tới tệp không tồn tại, hoặc tới neo
  (#...) không khớp tiêu đề nào của tệp đích (quy tắc neo kiểu GitHub).

Lỗi đã có từ trước được ghi ở `kiem_tra_ngoai_le.txt`; CI chỉ đỏ khi xuất hiện lỗi MỚI.
Sửa xong lỗi cũ thì chạy lại `--ghi-ngoai-le` để thu hẹp danh sách.
"""
from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

DOCS = Path(__file__).resolve().parents[2]
BASELINE = Path(__file__).with_name("kiem_tra_ngoai_le.txt")
SO_TRA_CUU = DOCS / "00-chung" / "D00-04-so-tra-cuu-gon.md"
MARK_BEGIN = "<!-- dai-ma:bat-dau (sinh bằng build/tools/kiem_tra_ma.py --cap-nhat-so-tra-cuu, không sửa tay) -->"
MARK_END = "<!-- dai-ma:ket-thuc -->"

PH = r"(?P<ph>\d{2})"
# Họ mã: tên -> (regex khớp mã, hàm tìm tài liệu gốc theo nhóm 'ph')
FAMILIES: dict[str, tuple[str, str]] = {
    # họ: (mẫu regex, mẫu glob tài liệu gốc; {ph} được thay bằng số phân hệ)
    "FR": (rf"FR-{PH}-\d{{3}}", "02-yeu-cau/frs/D02-03-PH{ph}-*.md"),
    "NFR": (rf"NFR-{PH}-\d{{3}}", "02-yeu-cau/frs/D02-03-PH{ph}-*.md"),
    "BR": (rf"BR-{PH}-\d{{3}}", "02-yeu-cau/frs/D02-03-PH{ph}-*.md"),
    "UC": (rf"UC-{PH}-\d{{2}}", "02-yeu-cau/use-case/D02-04-PH{ph}-*.md"),
    "US": (rf"US-{PH}-\d{{3}}", "02-yeu-cau/D02-05*.md"),
    "API": (rf"API-{PH}-\d{{3}}", "03-thiet-ke/api/D03-04-PH{ph}-*.md"),
    "EVT": (rf"EVT-{PH}-\d{{2}}", "03-thiet-ke/api/D03-04-PH{ph}-*.md"),
    "ERR": (rf"ERR-{PH}-\d{{3}}", "03-thiet-ke/api/D03-04-PH{ph}-*.md"),
    "UI": (rf"UI-{PH}-\d{{2}}", "03-thiet-ke/uiux/D03-06-PH{ph}-*.md"),
    "TS": (rf"TS-{PH}-\d{{2}}", "05-kiem-thu/test-case/D05-02-PH{ph}-*.md"),
    "TC": (rf"TC-{PH}-\d{{3}}", "05-kiem-thu/test-case/D05-02-PH{ph}-*.md"),
    "ADR": (r"ADR-\d{3}", "00-chung/adr/{code}-*.md"),
    "SEC": (r"SEC-\d{2}", "03-thiet-ke/attt/D03-07-*.md"),
    "PTN": (r"PTN-\d{2}", "03-thiet-ke/uiux/D03-06-00-*.md"),
    "LGC": (r"LGC-(?:BUS|TOOL|HUB|APIM|DMDC|PAY|NGSP|IAM|NFR)-\d{3}", "00-chung/D00-03-*.md"),
    "REQ": (r"REQ-\d{2}", "02-yeu-cau/D02-01-brd.md"),
    "CMPLAW": (r"CMP-LAW-\d{2}", "00-chung/D00-01-*.md"),
    "PERM": (rf"PERM-{PH}-[a-z][a-z-]*[a-z]", "02-yeu-cau/D02-08-*.md"),
    "CMP": (r"CMP-(?!LAW\b)[A-Z][A-Za-z0-9]+", "03-thiet-ke/uiux/D03-05-0[34]-*.md"),
}
# FR-00 và NFR-00 là yêu cầu cấp hệ thống, định nghĩa ở SRS.
SYSTEM_LEVEL = {"FR": "02-yeu-cau/D02-02-srs.md", "NFR": "02-yeu-cau/D02-02-srs.md"}

CODE_RE = re.compile(
    r"(?<![A-Za-z0-9_-])(" + "|".join(f"(?:{p})".replace("(?P<ph>", "(?:") for p, _ in FAMILIES.values()) + r")(?![A-Za-z0-9_])"
)
FAM_RE = {name: re.compile(rf"^(?:{p})$") for name, (p, _) in FAMILIES.items()}
RANGE_AFTER = re.compile(r"^\s*(?:…|\.\.\.|–)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
LINK_RE = re.compile(r"(?<!!)\[([^\]]*)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
FENCE_RE = re.compile(r"^\s*(```|~~~)")


def family_of(code: str):
    for name, rx in FAM_RE.items():
        m = rx.match(code)
        if m:
            return name, (m.groupdict().get("ph"))
    return None, None


def md_files():
    for p in sorted(DOCS.rglob("*.md")):
        rel = p.relative_to(DOCS).as_posix()
        if rel.startswith("build/out/") or "/node_modules/" in rel:
            continue
        yield p


def strip_cell(cell: str) -> str:
    cell = cell.strip()
    cell = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", cell)
    return cell.replace("**", "").replace("`", "").strip()


def scan_lines(path: Path):
    """Trả về các dòng ngoài khối mã, kèm số dòng."""
    in_fence = False
    in_generated = False
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        # Bảng dải mã sinh tự động trong D00-04 nhắc "số kế tiếp" chưa tồn tại: bỏ qua.
        if line.startswith("<!-- dai-ma:bat-dau"):
            in_generated = True
        elif line.startswith(MARK_END):
            in_generated = False
            continue
        if in_generated:
            continue
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield i, line


def gh_slug(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = text.replace("`", "").strip().lower()
    out = []
    for ch in text:
        cat = unicodedata.category(ch)
        if ch in "-_" or cat[0] in "LN" or cat == "Mn":
            out.append(ch)
        elif ch == " ":
            out.append("-")
    return "".join(out)


class Index:
    def __init__(self):
        self.files = list(md_files())
        self.defs: dict[str, set[str]] = defaultdict(set)  # tệp -> mã định nghĩa
        self.dups: list[str] = []
        self.refs: dict[str, list[str]] = defaultdict(list)  # mã -> nơi nhắc
        self.anchors: dict[str, set[str]] = {}
        self._build()

    def _build(self):
        for p in self.files:
            rel = p.relative_to(DOCS).as_posix()
            heading_codes: dict[str, int] = {}
            table_first: dict[str, int] = {}
            in_table = False
            slugs: dict[str, int] = {}
            anchors = set()
            for n, line in scan_lines(p):
                h = HEADING_RE.match(line)
                if h:
                    base = gh_slug(h.group(2))
                    k = slugs.get(base, 0)
                    anchors.add(base if k == 0 else f"{base}-{k}")
                    slugs[base] = k + 1
                for a in re.findall(r'<a\s+(?:id|name)="([^"]+)"', line):
                    anchors.add(a)
                stripped = line.strip()
                if stripped.startswith("|"):
                    if not in_table:
                        table_first = {}
                    in_table = True
                    cells = stripped.strip("|").split("|")
                    head_cells = [strip_cell(c) for c in cells[:2]]
                    for ci, cell in enumerate(head_cells):
                        for m in CODE_RE.finditer(cell):
                            if m.start() == 0 or ci == 1:
                                self.defs[rel].add(m.group(1))
                    if head_cells:
                        m0 = CODE_RE.match(head_cells[0])
                        if m0 and m0.group(1) == head_cells[0]:
                            c = m0.group(1)
                            if c in table_first:
                                self.dups.append(f"TRUNG\t{rel}\t{c}\tô đầu hai hàng cùng bảng (dòng {table_first[c]} và {n})")
                            else:
                                table_first[c] = n
                else:
                    in_table = False
                if h:
                    for m in CODE_RE.finditer(h.group(2)):
                        c = m.group(1)
                        self.defs[rel].add(c)
                    # Mã trùng theo tiêu đề: chỉ xét mã đứng đầu tiêu đề (sau số mục).
                    title = re.sub(r"^[\d.]+\s*", "", strip_cell(h.group(2)))
                    title = re.sub(r"^Đặc tả\s+", "", title)
                    m0 = CODE_RE.match(title)
                    if m0:
                        c = (len(h.group(1)), m0.group(1))
                        if c in heading_codes:
                            self.dups.append(f"TRUNG\t{rel}\t{c[1]}\thai tiêu đề cùng cấp (dòng {heading_codes[c]} và {n})")
                        else:
                            heading_codes[c] = n
                for m in CODE_RE.finditer(line):
                    if RANGE_AFTER.match(line[m.end():]):
                        continue
                    self.refs[m.group(1)].append(f"{rel}:{n}")
            self.anchors[rel] = anchors

    def home_files(self, code: str):
        fam, ph = family_of(code)
        if fam is None:
            return None, []
        pattern = FAMILIES[fam][1]
        if fam in SYSTEM_LEVEL and ph == "00":
            pattern = SYSTEM_LEVEL[fam]
        pattern = pattern.replace("{ph}", ph or "").replace("{code}", code)
        return fam, sorted(p.relative_to(DOCS).as_posix() for p in DOCS.glob(pattern))

    def check_codes(self):
        missing, pending = [], defaultdict(set)
        for code, where in sorted(self.refs.items()):
            fam, homes = self.home_files(code)
            if fam is None:
                continue
            if fam == "ADR":
                if not homes:
                    missing.append(f"THIEU\t{where[0].split(':')[0]}\t{code}\tkhông có tệp 00-chung/adr/{code}-*.md ({len(where)} lần nhắc, đầu tiên {where[0]})")
                continue
            if not homes:
                pending[fam].add(code)
                continue
            if any(code in self.defs[h] for h in homes):
                continue
            missing.append(f"THIEU\t{where[0].split(':')[0]}\t{code}\tchưa định nghĩa trong {', '.join(homes)} ({len(where)} lần nhắc, đầu tiên {where[0]})")
        return missing, pending

    def check_links(self):
        out = []
        for p in self.files:
            rel = p.relative_to(DOCS).as_posix()
            for n, line in scan_lines(p):
                line = re.sub(r"`[^`]*`", "", line)
                for m in LINK_RE.finditer(line):
                    target = m.group(2)
                    if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I):
                        continue
                    path_part, _, anchor = target.partition("#")
                    if path_part:
                        dest = (p.parent / path_part).resolve()
                        if not dest.exists():
                            out.append(f"LINK\t{rel}\t{target}\ttệp không tồn tại (dòng {n})")
                            continue
                        try:
                            dest_rel = dest.relative_to(DOCS).as_posix()
                        except ValueError:
                            continue  # trỏ ra ngoài datahub-docs (repo), chỉ kiểm tệp tồn tại
                    else:
                        dest_rel = rel
                    if anchor and dest_rel.endswith(".md") and dest_rel in self.anchors:
                        if anchor not in self.anchors[dest_rel] and anchor.lower() not in self.anchors[dest_rel]:
                            out.append(f"LINK\t{rel}\t{target}\tneo không khớp tiêu đề nào (dòng {n})")
        return out


def number_of(code: str) -> int:
    return int(re.findall(r"\d+", code)[-1])


def ranges_table(idx: Index) -> str:
    """Bảng dải mã đã dùng: mỗi họ × phân hệ một dòng, lấy từ tài liệu gốc."""
    rows = defaultdict(set)
    for code in idx.refs:
        fam, homes = idx.home_files(code)
        if fam is None or fam == "CMP":
            continue
        if fam == "ADR":
            if homes:
                rows[("ADR", "—")].add(code)
            continue
        if homes and any(code in idx.defs[h] for h in homes):
            _, ph = family_of(code)
            rows[(fam, ph or "—")].add(code)
    lines = ["| Họ mã | PH | Số mã | Thấp nhất | Cao nhất | Số kế tiếp còn trống |", "|---|---|---|---|---|---|"]
    order = list(FAMILIES)
    for (fam, ph) in sorted(rows, key=lambda k: (order.index(k[0]), k[1])):
        codes = sorted(rows[(fam, ph)], key=lambda c: (c.rsplit("-", 1)[0], number_of(c)))
        if fam == "PERM":
            continue
        if fam == "LGC":
            by_block = defaultdict(list)
            for c in codes:
                by_block[c.split("-")[1]].append(c)
            for blk, cs in sorted(by_block.items()):
                cs.sort(key=number_of)
                width = len(re.findall(r"\d+", cs[-1])[-1])
                nxt = f"LGC-{blk}-{number_of(cs[-1]) + 1:0{width}d}"
                lines.append(f"| LGC-{blk} | — | {len(cs)} | `{cs[0]}` | `{cs[-1]}` | `{nxt}` |")
            continue
        lo, hi = codes[0], codes[-1]
        width = len(re.findall(r"\d+", hi)[-1])
        nxt = re.sub(r"\d+$", f"{number_of(hi) + 1:0{width}d}", hi)
        if fam in ("SEC", "ADR"):
            nxt = "theo dải nhóm, §3"
        else:
            nxt = f"`{nxt}`"
        label = "CMP-LAW" if fam == "CMPLAW" else fam
        lines.append(f"| {label} | {ph} | {len(codes)} | `{lo}` | `{hi}` | {nxt} |")
    perm = sorted(k[1] for k in rows if k[0] == "PERM")
    if perm:
        total = sum(len(rows[("PERM", ph)]) for ph in perm)
        lines.append(f"| PERM | {perm[0]}…{perm[-1]} | {total} | — | — | động từ theo D02-08 |")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--tat-ca", action="store_true", help="in mọi lỗi kể cả đã ghi nhận")
    ap.add_argument("--ghi-ngoai-le", action="store_true", help="chụp lỗi hiện có vào tệp ngoại lệ")
    ap.add_argument("--dai-ma", action="store_true", help="in bảng dải mã đã dùng")
    ap.add_argument("--cap-nhat-so-tra-cuu", action="store_true", help="ghi bảng dải mã vào D00-04")
    args = ap.parse_args()

    idx = Index()
    if args.dai_ma or args.cap_nhat_so_tra_cuu:
        table = ranges_table(idx)
        if args.dai_ma:
            print(table)
        if args.cap_nhat_so_tra_cuu:
            text = SO_TRA_CUU.read_text(encoding="utf-8")
            pat = re.compile(re.escape(MARK_BEGIN) + r".*?" + re.escape(MARK_END), re.S)
            if not pat.search(text):
                print(f"Không thấy cặp đánh dấu dải mã trong {SO_TRA_CUU}", file=sys.stderr)
                return 2
            SO_TRA_CUU.write_text(pat.sub(lambda _: f"{MARK_BEGIN}\n\n{table}\n\n: Dải mã đã dùng thực tế trong bộ tài liệu (sinh tự động)\n\n{MARK_END}", text), encoding="utf-8")
            print(f"Đã cập nhật bảng dải mã trong {SO_TRA_CUU.relative_to(DOCS)}")
        return 0

    missing, pending = idx.check_codes()
    issues = sorted(set(idx.dups)) + missing + idx.check_links()
    # Khóa so sánh bỏ số dòng để ngoại lệ không vỡ khi tài liệu dài thêm.
    def key(issue: str) -> str:
        kind, file, code, msg = issue.split("\t", 3)
        msg = re.sub(r"\(.*\)$", "", msg).strip()
        # Mã thiếu không gắn với tệp nhắc đầu tiên, để thêm nơi nhắc không đổi khóa.
        return "\t".join([kind, code, msg] if kind == "THIEU" else [kind, file, code, msg])
    if args.ghi_ngoai_le:
        BASELINE.write_text(
            "# Lỗi đã có trước khi bật kiểm tra (26/11/2026). Chỉ được THU HẸP tệp này.\n"
            "# Sinh bằng: python3 datahub-docs/build/tools/kiem_tra_ma.py --ghi-ngoai-le\n"
            + "\n".join(sorted({key(i) for i in issues})) + "\n",
            encoding="utf-8",
        )
        print(f"Đã ghi {len({key(i) for i in issues})} ngoại lệ vào {BASELINE.name}")
        return 0

    known = set()
    if BASELINE.exists():
        known = {l.strip() for l in BASELINE.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")}
    new = [i for i in issues if key(i) not in known]
    fixed = known - {key(i) for i in issues}
    shown = issues if args.tat_ca else new
    for i in shown:
        print(i)
    counts = defaultdict(int)
    for i in issues:
        counts[i.split("\t")[0]] += 1
    print(
        f"\nTổng: {len(idx.files)} tệp, {len(idx.refs)} mã khác nhau. "
        f"Trùng {counts['TRUNG']}, thiếu {counts['THIEU']}, liên kết hỏng {counts['LINK']} "
        f"(mới {len(new)}, đã ghi nhận {len(issues) - len(new)}, đã sửa so với ngoại lệ {len(fixed)})."
    )
    if pending:
        print("Chờ tài liệu gốc (chưa viết, không tính lỗi): " + ", ".join(f"{k} {len(v)}" for k, v in sorted(pending.items())))
    if fixed:
        print("Gợi ý: chạy --ghi-ngoai-le để thu hẹp danh sách ngoại lệ.")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main())
