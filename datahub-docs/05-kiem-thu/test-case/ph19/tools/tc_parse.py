#!/usr/bin/env python3
"""Đọc D05-02-PH19, trả danh sách test case có cấu trúc. Dùng chung cho gen_matrix.py, gen_xlsx.py, gen_gherkin.py."""
import re, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[4]
DOC = ROOT / '05-kiem-thu/test-case/D05-02-PH19-test-case.md'
FRS = ROOT / '02-yeu-cau/frs/D02-03-PH19-frs-thanh-toan.md'
KHUNG = ROOT / '02-yeu-cau/frs/D02-03-PH19-00-khung-truy-vet.md'
API_DOC = ROOT / '03-thiet-ke/api/D03-04-PH19-api-thanh-toan.md'
TOK = re.compile(r'\b(FR|BR|ERR|API|UI|EVT|NFR|UC)-(19|00)-(\d{3})((?:\s*(?:,|…|\.\.\.)\s*\d{3}(?!\d))*)')
LGC = re.compile(r'\b(LGC-[A-Z]+)-(\d{3})((?:\s*(?:,|…)\s*\d{3})*)')
# Quy ước viết tắt ở mục 1.5: 403-PQ = ERR-19-046, 404-ẩn = ERR-19-020
SHORT = {'403-PQ': 'ERR-19-046', '404-ẩn': 'ERR-19-020'}

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

def err_refs(text):
    r = {x for x in refs(text) if x.startswith('ERR-')}
    r.update(v for k, v in SHORT.items() if k in text)
    return r

def field(block, name):
    m = re.search(r'- \*\*' + name + r'\*\*\s*(.*)', block)
    return m.group(1).strip() if m else ''

def parse(text=None):
    t = text if text is not None else DOC.read_text(encoding='utf-8')
    tcs = []
    ts = None
    parts = re.split(r'^(### TS-19-\d{2} · .*|#### TC-19-(?:\d{3}|###) · .*)$', t, flags=re.M)
    for i in range(1, len(parts), 2):
        head, body = parts[i], parts[i + 1]
        if head.startswith('### TS'):
            ts = head[4:13].strip()
            for m in re.finditer(r'^\| (TC-19-(?:\d{3}|###)) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', body, re.M):
                tid, name, load, thr, tv = [x.strip() for x in m.groups()]
                key = re.search(r'<!--k:([a-z0-9-]+)-->', name)
                name = re.sub(r'\s*<!--.*?-->', '', name)
                pr = 'P1' if re.search(r'NFR-19-00[1-4]', tv) else 'P2'
                tcs.append(dict(id=tid, key=key.group(1) if key else '', ts=ts, name=name, type='Hiệu năng', prio=pr,
                                auto='k6', trace=tv, refs=refs(tv),
                                data='Bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)', steps=f'Chạy tải: {load}',
                                expect=f'Đạt ngưỡng: {thr}'))
            continue
        tid, name = re.match(r'#### (TC-19-(?:\d{3}|###)) · (.*)', head).groups()
        key = re.search(r'<!--k:([a-z0-9-]+)-->', name)
        name = re.sub(r'\s*<!--.*?-->', '', name)
        body = re.split(r'\n(?:> |## |### )', body)[0]
        meta = field(body, 'Loại')
        typ = meta.split('·')[0].strip()
        prio = re.search(r'\*\*Ưu tiên\*\*\s*(P\d)', body)
        auto = re.search(r'\*\*Tự động\*\*\s*([^·\n]+)', body)
        steps = re.search(r'- \*\*Bước\*\*\n((?:  .*\n?)+)', body)
        tv = field(body, 'Truy vết')
        ex = field(body, 'Mong đợi')
        tcs.append(dict(id=tid, key=key.group(1) if key else '', ts=ts, name=name, type=typ,
                        prio=prio.group(1) if prio else '',
                        auto=auto.group(1).strip() if auto else '', trace=tv, refs=refs(tv) | err_refs(ex),
                        data=field(body, r'Tiền điều kiện / dữ liệu'),
                        steps='\n'.join(s.strip() for s in steps.group(1).splitlines()) if steps else '',
                        expect=ex))
    return tcs

def fr_catalog():
    t = FRS.read_text(encoding='utf-8')
    res = {}
    for m in re.finditer(r'^#### (FR-19-\d{3}) · ([^\n]*)\n(.*?)(?=^#{2,4} |\Z)', t, re.M | re.S):
        pr = re.search(r'\| Mức ưu tiên, phát hành \| (\w+)\s*·\s*([^|]+)\|', m.group(3))
        tv = re.search(r'\| Truy vết \| ([^|]+)', m.group(3))
        res[m.group(1)] = dict(name=m.group(2).strip(), prio=pr.group(1) if pr else '',
                               rel=pr.group(2).strip() if pr else '',
                               lgc=sorted(r for r in refs(tv.group(1) if tv else m.group(3)[:600]) if r.startswith('LGC')))
    return res

def ts_names(text=None):
    t = text if text is not None else DOC.read_text(encoding='utf-8')
    return dict(re.findall(r'^### (TS-19-\d{2}) · (.*)$', t, re.M))

def uat_rows(text=None):
    t = text if text is not None else DOC.read_text(encoding='utf-8')
    rows = []
    for m in re.finditer(r'^\| (UAT-\d{2}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', t, re.M):
        rows.append(dict(zip(('id', 'task', 'lgc', 'expect', 'fr', 'tc'), [x.strip() for x in m.groups()])))
    return rows

def known(prefix):
    if prefix == 'ERR':
        return sorted(set(re.findall(r'^\| (ERR-19-\d{3}) \|', API_DOC.read_text(encoding='utf-8'), re.M)))
    src = KHUNG.read_text(encoding='utf-8')
    return sorted(set(re.findall(r'^\| (' + prefix + r'-19-\d{3}) \|', src, re.M)))
