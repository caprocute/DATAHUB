#!/usr/bin/env python3
"""Đọc D05-02-PH07, trả danh sách test case có cấu trúc. Dùng chung cho gen_matrix.py, gen_xlsx.py, gen_gherkin.py."""
import re, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[4]
DOC = ROOT / '05-kiem-thu/test-case/D05-02-PH07-test-case.md'
FRS = ROOT / '02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md'
TOK = re.compile(r'\b(FR|BR|ERR|API|UI|EVT|NFR|UC)-(07|00)-(\d{3})((?:\s*(?:,|…|\.\.\.)\s*\d{3}(?!\d))*)')
LGC = re.compile(r'\b(LGC-[A-Z]+)-(\d{3})((?:\s*(?:,|…)\s*\d{3})*)')

def expand(prefix, first, rest):
    out = [int(first)]
    for sep, num in re.findall(r'(,|…|\.\.\.)\s*(\d{3})', rest):
        n = int(num)
        if sep == ',':
            out.append(n)
        else:
            out.extend(range(out[-1] + 1, n + 1))
    return [f'{prefix}-{x:03d}' for x in out]

def refs(text):
    r = set()
    for k, ph, a, rest in TOK.findall(text):
        r.update(expand(f'{k}-{ph}', a, rest))
    for k, a, rest in LGC.findall(text):
        r.update(expand(k, a, rest))
    return r

ALIAS = {'Tiền điều kiện / dữ liệu': 'Tiền điều kiện, dữ liệu', 'Mong đợi': 'Kết quả mong đợi', 'Bước': 'Các bước'}


def field(block, name):
    """Đọc trường ở dạng cũ (`- **Tên** giá trị`) hoặc khối đặc tả (`**Tên.** giá trị`)."""
    m = re.search(r'- \*\*' + name + r'\*\*\s*(.*)', block)
    if m:
        return m.group(1).strip()
    ten = ALIAS.get(name.replace('\\', ''), name)
    m = re.search(r'^\*\*' + re.escape(ten) + r'\.\*\*\s*(.*)$', block, re.M)
    return m.group(1).strip() if m else ''

def parse():
    t = DOC.read_text(encoding='utf-8')
    tcs = []
    ts = None
    parts = re.split(r'^(### TS-07-\d{2} · .*|#### TC-07-\d{3} · .*)$', t, flags=re.M)
    for i in range(1, len(parts), 2):
        head, body = parts[i], parts[i + 1]
        if head.startswith('### TS'):
            ts = head[4:13].strip()
            # bảng ca hiệu năng trong thân kịch bản
            for m in re.finditer(r'^\| (TC-07-\d{3}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', body, re.M):
                tid, name, load, thr, tv = [x.strip() for x in m.groups()]
                name = re.sub(r'\s*<!--.*?-->', '', name)
                n = int(tid[-3:])
                pr = 'P1' if n in (293, 297, 298, 300, 301) else 'P2'
                tcs.append(dict(id=tid, ts=ts, name=name, type='Hiệu năng', prio=pr, auto='k6', trace=tv, refs=refs(tv),
                                data='Bộ dữ liệu quy mô NFR-07-011 ở PERF', steps=f'Chạy tải: {load}', expect=f'Đạt ngưỡng: {thr}'))
            continue
        tid, name = re.match(r'#### (TC-07-\d{3}) · (.*)', head).groups()
        name = re.sub(r'\s*<!--.*?-->', '', name)
        body = body.split('\n> ')[0]
        meta = field(body, 'Loại')
        typ = meta.split('·')[0].strip().rstrip('.')
        prio = re.search(r'\*\*Ưu tiên\.?\*\*\s*(P\d)', body)
        auto = re.search(r'\*\*Tự động\.?\*\*\s*([^·\n]+)', body)
        steps = re.search(r'- \*\*Bước\*\*\n((?:  .*\n?)+)', body) or re.search(r'\*\*Các bước\.\*\*\n\n((?:\d+\. .*\n?)+)', body)
        tv = field(body, 'Truy vết').rstrip('.')
        tcs.append(dict(id=tid, ts=ts, name=name, type=typ, prio=prio.group(1) if prio else '',
                        auto=auto.group(1).strip().rstrip('.') if auto else '', trace=tv, refs=refs(tv),
                        data=field(body, r'Tiền điều kiện / dữ liệu'),
                        steps='\n'.join(s.strip() for s in steps.group(1).splitlines()) if steps else '',
                        expect=field(body, 'Mong đợi')))
    return tcs

def fr_catalog():
    t = FRS.read_text(encoding='utf-8')
    res = {}
    for m in re.finditer(r'^#### (FR-07-\d{3}) · ([^\n]*)\n(.*?)(?=^#{2,4} )', t, re.M | re.S):
        pr = (re.search(r'\| Mức ưu tiên \| (\w+)', m.group(3)) or re.search(r'\*\*Mức ưu tiên, đợt\.\*\* (\w+)', m.group(3))
              or re.search(m.group(1) + r' \((\w)', m.group(3)))
        tv = re.search(r'\| Truy vết \| ([^|]+)', m.group(3)) or re.search(r'\*\*Truy vết\.\*\* ([^\n]+)', m.group(3))
        res[m.group(1)] = dict(name=m.group(2).strip(), prio=pr.group(1) if pr else '',
                               lgc=sorted(r for r in refs(tv.group(1) if tv else m.group(3)[:600]) if r.startswith('LGC')))
    return res

def ts_names():
    t = DOC.read_text(encoding='utf-8')
    return dict(re.findall(r'^### (TS-07-\d{2}) · (.*)$', t, re.M))

def uat_rows():
    t = DOC.read_text(encoding='utf-8')
    rows = []
    for m in re.finditer(r'^\| (UAT-\d{2}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', t, re.M):
        rows.append(dict(zip(('id', 'task', 'lgc', 'expect', 'fr', 'tc'), [x.strip() for x in m.groups()])))
    return rows
