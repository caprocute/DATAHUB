#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH18.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph18/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH18-csdl-van-hanh.md
Khối trích trực tiếp từ ddl/ph18_ops.sql (khóa, ràng buộc, chỉ mục, RLS mẫu P/S, phân vùng, trigger bất biến)
và dòng mô tả bảng (COMMENT ON TABLE do gen_tables_md.py chèn). Chạy sau gen_tables_md.py --write; chạy lại
nhiều lần không nhân bản. Thêm chú thích cho bảng cột."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = open(os.path.join(ROOT, 'ddl', 'ph18_ops.sql'), encoding='utf-8').read()
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'outbox_event': 'Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-042). Vai ứng dụng không sửa dòng outbox.',
    'inbox_event': 'Khử trùng sự kiện nhận theo (`consumer`, `event_id`); tiêu thụ lũy đẳng; dọn theo `18.dlq.dedup-window-days` với consumer DLQ và 7 ngày với consumer khác.',
}
sys.path.insert(0, HERE)
from sinh_ddl import FILE_GROUPS, BY_NAME
KHOI = {'18-0010-core.sql': 'Hạ tầng dùng chung (outbox, inbox)', '18-0020-param.sql': 'Nhóm FR khối A, kho tham số và cờ tính năng',
        '18-0030-dlq.sql': 'Nhóm FR khối B, C, D, tiếp nhận, phân loại, phát lại DLQ', '18-0040-notify.sql': 'Nhóm FR khối E, thông báo',
        '18-0050-task.sql': 'Nhóm FR khối F, Việc của tôi và lịch', '18-0060-incident.sql': 'Nhóm FR khối G, sự cố vận hành',
        '18-0070-backup.sql': 'Nhóm FR khối H, sao lưu, khôi phục, xuất và sáp nhập tenant', '18-0080-migration.sql': 'Nhóm FR khối I, di trú và chạy song song',
        '18-0090-report.sql': 'Nhóm FR khối J, báo cáo vận hành'}
KHOI_BANG = {t['name']: KHOI[f] for f, g in FILE_GROUPS for t in g}
FR_MAP = {}
try:
    import json
    FR_MAP = json.load(open(os.path.join(HERE, 'fr_bang.json'), encoding='utf-8'))
except OSError:
    pass

tables = {}
for m in re.finditer(r'CREATE TABLE ph18_ops\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
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
    pk = [d.replace('(id)', '`id`') for _, d in con(b, 'PRIMARY KEY')]
    uq = ['`%s` %s' % (n, d) for n, d in con(b, 'UNIQUE') if not n.endswith('_tid')]
    uq += ['`%s` %s%s' % (m.group(1), m.group(2), ' có điều kiện' if m.group(3) else '') for m in re.finditer(
        r'CREATE UNIQUE INDEX (\w+) ON ph18_ops\.%s (\([^;]*?\))( WHERE [^;]*)?;' % ten, sql)]
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph18_ops\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    pre = 'ck_%s_' % ten
    ck = [n[len(pre):] if n.startswith(pre) else n for n, _ in con(b, 'CHECK') if n != 'ck_%s_tenant' % ten]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph18_ops\.%s\b' % ten, sql)]
    rm = re.search(r"CALL ph18_ops\.p_enable_rls\('ph18_ops\.%s', (true|false)\)" % ten, sql)
    tt = BY_NAME[ten]
    if tt['only_common']:
        cl = 'FORCE RLS; chỉ dòng `COMMON` (CHECK), mọi tenant đọc, chỉ phiên `COMMON` (PA) ghi.'
    elif rm and rm.group(1) == 'true':
        cl = 'FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.'
    else:
        cl = 'FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa)' + ('; nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.' if tt['common_ok'] else '.')
    quyen = {'r': 'vai `ph18_worker` đọc', 'rw': 'vai `ph18_worker` đọc, thêm, sửa', 'i': 'vai `ph18_worker` đọc, thêm'}.get(tt['worker'])
    if quyen:
        cl += ' Quyền thêm: ' + quyen + '.'
    if tt['ro_hide']:
        cl += ' Vai `ph18_readonly` không đọc cột ' + ', '.join('`%s`' % c for c in tt['ro_hide']) + '.'
    pv = []
    if t['part']:
        pv.append('Phân vùng tháng theo `%s`, tạo trước %d tháng' % (t['part'], tt['part'][1]))
    if tt['append_only']:
        pv.append('Chỉ thêm (`tg_%s_append_only`, vai ứng dụng chỉ SELECT, INSERT)' % ten)
    im = re.search(r"CREATE TRIGGER (tg_%s_immutable) BEFORE UPDATE ON ph18_ops\.%s FOR EACH ROW EXECUTE FUNCTION ph18_ops\.tg_immutable\(([^)]*)\)" % (ten, ten), sql)
    if im:
        pv.append('Bất biến: %s' % ', '.join('`%s`' % c.strip(" '") for c in im.group(2).split(',')))
    other = sorted(set(re.findall(r'CREATE TRIGGER (\w+) BEFORE [^;]*? ON ph18_ops\.%s ' % ten, sql)) - {'tg_%s_touch' % ten, 'tg_%s_immutable' % ten, 'tg_%s_append_only' % ten})
    if other:
        pv.append('Trigger: ' + ', '.join('`%s`' % x for x in other))
    ens = list(dict.fromkeys(re.findall(r'EN-18-\d{2}', mo_ta)))
    fr = FR_MAP.get(ten) or KHOI_BANG[ten]
    if ens:
        fr += '; ' + ', '.join(ens)
    mac_dinh = 'ETag là `version`; ghi có `If-Match`.' if not tt['append_only'] else 'Dòng không sửa sau khi thêm; `version` luôn 0.'
    gc = GHI_CHU.get(ten, mac_dinh)
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ('`ck_%s_` + ' % ten + ', '.join(ck)) if ck else 'Chỉ `ck_%s_tenant`' % ten), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'), ('Cách ly tenant', cl),
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
