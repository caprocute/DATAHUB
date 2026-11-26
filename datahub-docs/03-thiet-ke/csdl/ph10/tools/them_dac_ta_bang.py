#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH10.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph10/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH10-csdl-su-kien.md
Khối trích trực tiếp từ ddl/ph10_event.sql (khóa, ràng buộc, chỉ mục, RLS mẫu P/S, phân vùng, trigger bất biến)
và dòng mô tả bảng (COMMENT ON TABLE do gen_tables_md.py chèn). Chạy sau gen_tables_md.py --write; chạy lại
nhiều lần không nhân bản. Thêm chú thích cho bảng cột."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = open(os.path.join(ROOT, 'ddl', 'ph10_event.sql'), encoding='utf-8').read()
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
    'outbox_event': 'Debezium EventRouter đọc WAL và phát lên topic hệ thống; ghi cùng giao dịch với thay đổi cấu hình (mẫu outbox, ADR-073).',
    'inbox_event': 'Khử trùng sự kiện nhận từ phân hệ khác theo `event_id` (tiêu thụ lũy đẳng).',
    'dlq_payload': 'Tách khỏi `dlq_entry` để dọn nội dung theo hạn lưu giữ mà vẫn giữ siêu dữ liệu truy vết.',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph10_event\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
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
    uq = ['`%s` %s' % (n, d) for n, d in con(b, 'UNIQUE')]
    uq += ['`%s` %s%s' % (m.group(1), m.group(2), ' có điều kiện' if m.group(3) else '') for m in re.finditer(
        r'CREATE UNIQUE INDEX (\w+) ON ph10_event\.%s (\([^;]*?\))( WHERE [^;]*)?;' % ten, sql)]
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph10_event\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    ck = ['`%s`' % n for n, _ in con(b, 'CHECK')]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph10_event\.%s\b' % ten, sql)]
    rm = re.search(r"CALL ph10_event\.p_enable_rls\('ph10_event\.%s', '([PS])'\)" % ten, sql)
    if rm and rm.group(1) == 'P':
        cl = 'RLS mẫu P (FORCE): phiên chỉ đọc, ghi dòng có `tenant_id = app.tenant_id`; dòng `COMMON` chỉ phiên `PLATFORM` (mục 1.2).'
    elif rm:
        cl = 'RLS mẫu S (FORCE): tenant đọc dòng của mình và dòng `COMMON` dùng chung; chỉ phiên `PLATFORM` ghi `COMMON` (mục 1.2).'
    else:
        cl = 'Không bật RLS. ' + GHI_CHU.get(ten, 'Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.')
    pv = []
    if t['part']:
        unit = 'ngày' if ten == 'lag_sample' else 'tháng'
        pv.append('Phân vùng RANGE theo %s trên `%s` (thủ tục `p_ensure_partitions`); dọn dữ liệu hết hạn bằng DETACH, DROP PARTITION' % (unit, t['part']))
    im = re.search(r"CREATE TRIGGER (tg_%s_immutable) BEFORE UPDATE ON ph10_event\.%s FOR EACH ROW EXECUTE FUNCTION ph10_event\.tg_immutable\(([^)]*)\)" % (ten, ten), sql)
    if im:
        pv.append('Cột bất biến sau khi tạo: %s (trigger `%s`, BR-10-003)' % (', '.join('`%s`' % c.strip(" '") for c in im.group(2).split(',')), im.group(1)))
    other = sorted(set(re.findall(r'CREATE TRIGGER (\w+) BEFORE [^;]*? ON ph10_event\.%s ' % ten, sql)) - {'tg_%s_touch' % ten, 'tg_%s_immutable' % ten})
    if other:
        pv.append('Trigger nghiệp vụ: ' + ', '.join('`%s`' % x for x in other))
    frs = list(dict.fromkeys(re.findall(r'FR-10-\d{3}(?:…\d{3})?', mo_ta)))
    ens = list(dict.fromkeys(re.findall(r'EN-10-\d{2}', mo_ta)))
    fr = ', '.join(frs) or 'Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)'
    if ens:
        fr += '; thực thể ' + ', '.join(ens) + ' (FRS §4.2)'
    if re.search(r'(?m)^\s+version\s+integer', b):
        mac_dinh = 'Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (trigger `tg_touch`).'
    else:
        mac_dinh = 'Bảng số liệu hoặc nhật ký chỉ ghi thêm, khóa tự nhiên, không có cột `version` (mục 1.3).'
    gc = GHI_CHU.get(ten, mac_dinh)
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ds(ck)), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'), ('Cách ly tenant', cl),
           ('Phân vùng, bất biến', '; '.join(pv) or 'Không'), ('Ghi chú', gc)]
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
