#!/usr/bin/env python3
"""Đọc D05-02-PH20, trả danh sách test case có cấu trúc. Dùng chung cho gen_matrix.py, gen_xlsx.py, gen_gherkin.py."""
import re, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[4]
DOC = ROOT / '05-kiem-thu/test-case/D05-02-PH20-test-case.md'
FRS = ROOT / '02-yeu-cau/frs/D02-03-PH20-frs-quan-tri-tenant.md'
UC = ROOT / '02-yeu-cau/use-case/D02-04-PH20-use-case-quan-tri-tenant.md'
TOK = re.compile(r'\b(FR|BR|ERR|API|UI|EVT|NFR|UC)-(\d{2})-(\d{3}|\d{2}(?!\d))((?:\s*(?:,|…|\.\.\.)\s*(?:\d{3}|\d{2})(?!\d))*)')
LGC = re.compile(r'\b(LGC-[A-Z]+)-(\d{3})((?:\s*(?:,|…)\s*\d{3})*)')

def expand(prefix, first, rest):
    out = [int(first)]
    for sep, num in re.findall(r'(,|…|\.\.\.)\s*(\d{2,3})', rest):
        n = int(num)
        if sep == ',':
            out.append(n)
        else:
            out.extend(range(out[-1] + 1, n + 1))
    w = 2 if prefix.split('-')[0] in ('UC','UI','EVT') else 3
    return [f'{prefix}-{x:0{w}d}' for x in out]

def refs(text):
    r = set()
    for k, ph, a, rest in TOK.findall(text):
        r.update(expand(f'{k}-{ph}', a, rest))
    for k, a, rest in LGC.findall(text):
        r.update(expand(k, a, rest))
    return r

# Tên trường ở dạng danh sách cũ (bản 0.1) và tên tương ứng trong khối đặc tả `::: dac-ta` (bản 0.2)
ALIAS = {'Tiền điều kiện / dữ liệu': 'Tiền điều kiện, dữ liệu', 'Mong đợi': 'Kết quả mong đợi', 'Bước': 'Các bước'}

def field(block, name):
    """Đọc trường ở dạng cũ (`- **Tên** giá trị`) hoặc khối đặc tả (`**Tên.** giá trị`)."""
    m = re.search(r'- \*\*' + name + r'\*\*\s*(.*)', block)
    if m:
        return m.group(1).strip()
    ten = ALIAS.get(name.replace('\\', ''), name)
    m = re.search(r'^\*\*' + re.escape(ten) + r'\.\*\*\s*(.*)$', block, re.M)
    return m.group(1).strip() if m else ''

def err_refs(text):
    """Mã lỗi ghi rõ trong kết quả mong đợi (bổ sung cho trường Truy vết)."""
    return {x for x in refs(text) if x.startswith('ERR-')}

def parse():
    t = DOC.read_text(encoding='utf-8')
    tcs = []
    ts = None
    parts = re.split(r'^(### TS-20-\d{2} · .*|#### TC-20-\d{3} · .*)$', t, flags=re.M)
    for i in range(1, len(parts), 2):
        head, body = parts[i], parts[i + 1]
        if head.startswith('### TS'):
            ts = head[4:13].strip()
            # bảng ca hiệu năng dạng cũ (bản 0.1): chỉ lấy dòng chưa có khối đặc tả riêng
            for m in re.finditer(r'^\| (TC-20-\d{3}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', body, re.M):
                tid, name, load, thr, tv = [x.strip() for x in m.groups()]
                if re.search(r'^#### ' + tid + ' ', t, re.M):
                    continue
                key = re.search(r'<!--k:([a-z0-9-]+)-->', name)
                name = re.sub(r'\s*<!--.*?-->', '', name)
                pr = 'P1' if re.search(r'NFR-20-0(0[1235]|1[0-4]|16)', tv) else 'P2'
                tcs.append(dict(id=tid, key=key.group(1) if key else '', ts=ts, name=name, type='Hiệu năng', prio=pr,
                                auto='k6', trace=tv, refs=refs(tv), purpose='', post='', notice='',
                                data='Bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99', steps=f'Chạy tải: {load}', expect=f'Đạt ngưỡng: {thr}'))
            continue
        tid, name = re.match(r'#### (TC-20-\d{3}) · (.*)', head).groups()
        key = re.search(r'<!--k:([a-z0-9-]+)-->', name)
        name = re.sub(r'\s*<!--.*?-->', '', name)
        body = re.split(r'\n(?:> |## |### )', body)[0]
        meta = field(body, 'Loại')
        typ = meta.split('·')[0].strip().rstrip('.')
        prio = re.search(r'\*\*Ưu tiên\.?\*\*\s*(P\d)', body)
        auto = re.search(r'\*\*Tự động\.?\*\*\s*([^·\n]+)', body)
        steps = (re.search(r'- \*\*Bước\*\*\n((?:  .*\n?)+)', body)
                 or re.search(r'^\*\*Các bước\.\*\*\n\n((?:\d+\. .*\n?)+)', body, re.M))
        tv = field(body, 'Truy vết').rstrip('.')
        ex = field(body, 'Mong đợi')
        tcs.append(dict(id=tid, key=key.group(1) if key else '', ts=ts, name=name, type=typ,
                        prio=prio.group(1) if prio else '',
                        auto=auto.group(1).strip().rstrip('.') if auto else '', trace=tv, refs=refs(tv) | err_refs(ex),
                        data=field(body, r'Tiền điều kiện / dữ liệu'),
                        steps='\n'.join(s.strip() for s in steps.group(1).splitlines()) if steps else '',
                        expect=ex, purpose=field(body, 'Mục đích'), post=field(body, 'Hậu điều kiện'),
                        notice=field(body, 'Thông báo hiển thị')))
    return tcs

def fr_catalog():
    t = FRS.read_text(encoding='utf-8')
    res = {}
    for m in re.finditer(r'^#### (FR-20-\d{3}) · ([^\n]*)\n(.*?)(?=^#{2,4} |\Z)', t, re.M | re.S):
        # FRS dạng bảng "Trường | Nội dung" (0.2) hoặc khối đặc tả 17 mục (0.3 trở lên)
        pr = (re.search(r'\| Mức ưu tiên, đợt \| (\w)', m.group(3))
              or re.search(r'^\*\*Mức ưu tiên, (?:đợt|phát hành)\.\*\*\s*(\w)', m.group(3), re.M)
              or re.search(m.group(1) + r' \((\w)', m.group(3)))
        tv = (re.search(r'\| Truy vết \| ([^|]+)', m.group(3))
              or re.search(r'^\*\*Truy vết\.\*\*\s*([^\n]+)', m.group(3), re.M))
        res[m.group(1)] = dict(name=m.group(2).strip(), prio=pr.group(1) if pr else '',
                               lgc=sorted(r for r in refs(tv.group(1) if tv else m.group(3)[:600]) if r.startswith('LGC')))
    return res

def ts_names():
    t = DOC.read_text(encoding='utf-8')
    return dict(re.findall(r'^### (TS-20-\d{2}) · (.*)$', t, re.M))

def uat_rows():
    t = DOC.read_text(encoding='utf-8')
    rows = []
    for m in re.finditer(r'^\| (UAT-\d{2}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', t, re.M):
        rows.append(dict(zip(('id', 'task', 'lgc', 'expect', 'fr', 'tc'), [x.strip() for x in m.groups()])))
    return rows
