#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, chép từ PH-06) cho từng bảng ở chương 3 của D03-03-PH11.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph11/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH11-csdl-quy-trinh.md
Khối trích trực tiếp từ ddl/ph11_bpm.sql (khóa, ràng buộc, chỉ mục, RLS mẫu P/S, phân vùng, trigger bất biến)
và dòng mô tả bảng (COMMENT ON TABLE do gen_tables_md.py chèn). Chạy sau gen_tables_md.py --write; chạy lại
nhiều lần không nhân bản. Thêm chú thích cho bảng cột."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = open(os.path.join(ROOT, 'ddl', 'ph11_bpm.sql'), encoding='utf-8').read()
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
    'outbox_event': 'Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-073, SAD 7.3).',
    'inbox_message': 'Khử trùng thông điệp nhận từ PH-04, PH-10 theo (`consumer`, `message_id`) và giữ thông điệp chưa tương quan (tiêu thụ lũy đẳng).',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph11_bpm\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
    tables[m.group(1)] = {'body': m.group(2), 'part': m.group(4)}


def con(body, kind):
    out = []
    for c in re.finditer(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\s*(.*?)(?=,\n\s*CONSTRAINT|$)', body, re.S):
        if c.group(2) == kind:
            out.append((c.group(1), re.sub(r'\s+', ' ', c.group(3)).strip().rstrip(',')))
    return out


def ds(lst):
    return ', '.join(lst) if lst else 'Không'


def khoi(ten, mo_ta):
    t = tables.get(ten)
    if not t:
        return None
    b = t['body']
    pk = [d for _, d in con(b, 'PRIMARY KEY')]
    uq = ['`%s` %s' % (n, d) for n, d in con(b, 'UNIQUE') if n != 'uq_%s_tid' % ten]  # uq_*_tid (tenant_id, id) ghi chung ở mục 1.3
    uq += ['`%s` loại trừ chồng %s' % (n, d.split('WHERE')[0].strip()[:90]) for n, d in con(b, 'EXCLUDE')]
    uq += ['`%s` %s%s' % (m.group(1), m.group(2), ' có điều kiện' if m.group(3) else '') for m in re.finditer(
        r'CREATE UNIQUE INDEX (\w+) ON ph11_bpm\.%s (\([^;]*?\))( WHERE [^;]*)?;' % ten, sql)]
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph11_bpm\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    pre = 'ck_%s_' % ten
    ck = [n[len(pre):] if n.startswith(pre) else n for n, _ in con(b, 'CHECK') if n != pre + 'tenant']  # ck_*_tenant ghi chung ở mục 1.3
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph11_bpm\.%s\b' % ten, sql)]
    rm = re.search(r"CALL ph11_bpm\.p_enable_rls\('ph11_bpm\.%s', '([PS])'\)" % ten, sql)
    if rm:
        cl = 'RLS FORCE, mẫu P (mục 1.2).' if rm.group(1) == 'P' else 'RLS FORCE, mẫu S (mục 1.2): tenant đọc thêm dòng COMMON.'
    else:
        cl = 'Không bật RLS. ' + GHI_CHU.get(ten, 'Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.')
    pv = []
    if t['part']:
        pv.append('Phân vùng tháng theo `%s`' % t['part'])
    im = re.search(r"CREATE TRIGGER (tg_%s_immutable) BEFORE UPDATE ON ph11_bpm\.%s FOR EACH ROW EXECUTE FUNCTION ph11_bpm\.tg_immutable\(([^)]*)\)" % (ten, ten), sql)
    if im:
        pv.append('Bất biến: %s' % ', '.join('`%s`' % c.strip(" '") for c in im.group(2).split(',') if c.strip(" '") != 'tenant_id'))
    other = sorted(set(re.findall(r'CREATE TRIGGER (\w+) BEFORE [^;]*? ON ph11_bpm\.%s ' % ten, sql)) - {'tg_%s_touch' % ten, 'tg_%s_immutable' % ten})
    if other:
        pv.append('Trigger: ' + ', '.join('`%s`' % x for x in other))
    nums = []
    for m in re.finditer(r'FR-11-(\d{3})((?:(?:, |…)\d{3})*)', mo_ta):
        nn, prev = [int(m.group(1))], int(m.group(1))
        for sep, x in re.findall(r'(, |…)(\d{3})', m.group(2)):
            x = int(x)
            nn += list(range(prev + 1, x + 1)) if sep == '…' else [x]
            prev = x
        nums += nn
    nums = sorted(set(nums))
    ens = list(dict.fromkeys(re.findall(r'EN-11-\d{2}', mo_ta)))
    fr = ('FR-11-' + ', '.join('%03d' % n for n in nums)) if nums else 'Hạ tầng dùng chung'
    if ens:
        fr += '; ' + ', '.join(ens)
    if re.search(r'(?m)^\s+version\s+integer', b):
        mac_dinh = 'ETag là `version`.'
    else:
        mac_dinh = 'Không có `version`.'
    gc = GHI_CHU.get(ten, mac_dinh)
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ('`ck_%s_` + ' % ten + ', '.join('`%s`' % x for x in ck)) if ck else 'Không'), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'), ('Cách ly tenant', cl),
           ('Phân vùng, bất biến', '; '.join(pv) or 'Không'), ('Ghi chú', gc)]
    muc = [m for m in muc if m[0] != 'FR phục vụ']  # mã FR đã nằm trong Mục đích, ánh xạ đầy đủ ở mục 8.2
    if gc == 'ETag là `version`.':
        muc.pop()  # mặc định ghi chung ở mục 1.3
    o = ['::: dac-ta']
    for k, v in muc:
        v = v.strip()
        if v and not v.endswith('.'):
            v += '.'
        o += ['**%s.** %s' % (k, v), '']
    o[-1] = ':::'
    return '\n'.join(o)


CU = dict(re.findall(r'(?m)^### 3\.\d+\. `(\w+)`[^\n]*\n\n::: dac-ta\n\*\*Mục đích\.\*\* ([^\n]*)\n', s))
s = re.sub(r'(?m)(^### 3\.\d+\. `\w+`[^\n]*\n)\n::: dac-ta\n.*?\n:::\n', r'\1', s, flags=re.S)
parts = re.split(r'(?m)^(### 3\.\d+\. `(\w+)`[^\n]*\n)', s)
out, i, n = [parts[0]], 1, 0
while i < len(parts):
    head, ten, body = parts[i], parts[i + 1], parts[i + 2]
    m = None if ten in CU else re.match(r'\s*([^|\n:#<][^\n]*)\n', body)
    mo_ta = (m.group(1).strip() if m else CU.get(ten, '')).rstrip('.')
    k = khoi(ten, mo_ta)
    if k:
        n += 1
        if m:
            body = body[m.end():]
        body = '\n' + k + '\n' + body
        if not re.search(r'(?m)^: Cột của bảng `%s`' % ten, body):
            body = re.sub(r'(?m)(^\| Cột [^\n]*\n(?:\|[^\n]*\n)+)', lambda x: x.group(1) + '\n: Cột của bảng `%s`\n' % ten, body, count=1)
    out.append(head + body)
    i += 3
open(f, 'w', encoding='utf-8').write(''.join(out))
print('đã thêm khối đặc tả cho', n, 'bảng')
