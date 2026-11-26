#!/usr/bin/env python3
"""Đọc các bảng mã của khung truy vết D02-03-PH19-00 để các tài liệu PH-19 sinh bảng
tổng hợp từ một nguồn duy nhất (nguyên tắc "một sự thật, một nơi").

Dùng như thư viện: from khung import load; k = load(); k.table("4.1") ...
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
KHUNG = os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH19-00-khung-truy-vet.md")


def _cells(line):
    s = line.strip()
    if not (s.startswith("|") and s.endswith("|")):
        return None
    return [c.strip() for c in s[1:-1].split("|")]


class Khung:
    def __init__(self, path=KHUNG):
        with open(path, encoding="utf-8") as f:
            self.lines = f.read().splitlines()
        self.sections = {}
        cur = None
        for i, ln in enumerate(self.lines):
            m = re.match(r"^#{2,4} (\d+(?:\.\d+)*)\. ", ln)
            if m:
                cur = m.group(1)
                self.sections[cur] = [i, None]
        keys = list(self.sections)
        for a, b in zip(keys, keys[1:] + [None]):
            self.sections[a][1] = self.sections[b][0] if b else len(self.lines)

    def tables(self, sec):
        """Trả danh sách bảng (mỗi bảng: header, rows) trong mục sec."""
        a, b = self.sections[sec]
        out, cur = [], None
        for ln in self.lines[a:b]:
            c = _cells(ln)
            if c is None:
                if cur:
                    out.append(cur); cur = None
                continue
            if cur is None:
                cur = {"header": c, "rows": []}
            elif set("".join(c)) <= set("-: "):
                continue
            else:
                cur["rows"].append(dict(zip(cur["header"], c)))
        if cur:
            out.append(cur)
        return out

    def rows(self, sec, idx=0):
        return self.tables(sec)[idx]["rows"]

    def fr(self):
        out = []
        for s in [f"4.{i}" for i in range(1, 16)]:
            out += self.rows(s)
        return out

    def raw(self, sec):
        a, b = self.sections[sec]
        return "\n".join(self.lines[a:b])


def load():
    return Khung()


if __name__ == "__main__":
    k = load()
    print(len(k.fr()), "FR")
    print(len(k.rows("8.1")), "UC")
    print(len(k.rows("10.2")) + len(k.rows("10.3")), "API")
    print(len(k.rows("12")), "ERR")
