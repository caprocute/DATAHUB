"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05) cho từng bảng ở chương 3 của D03-03-PH07.

Chạy sau gen_csdl_doc.py: python3 03-thiet-ke/csdl/ph07/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH07-csdl-danh-muc.md
Khối được trích từ chính các bảng ràng buộc, chỉ mục, RLS do gen_csdl_doc.py sinh từ DDL; chạy lại nhiều lần không nhân bản."""
import re
import sys

f = sys.argv[1]
s = open(f, encoding='utf-8').read()
CU = dict(re.findall(r'(?m)^### 3\.\d+\. `(\w+)`[^\n]*\n\n::: dac-ta\n\*\*Mục đích\.\*\* ([^\n]*)\n', s))
s = re.sub(r'(?m)(^### 3\.\d+\. `\w+`[^\n]*\n)\n::: dac-ta\n.*?\n:::\n', r'\1', s, flags=re.S)  # chạy lại

GHI_CHU = {
    'catalog_version': 'Bất biến khi `PUBLISHED` (trigger chặn sửa, BR-07-006); khoảng hiệu lực không chồng lấn (ràng buộc loại trừ, BR-07-007).',
    'catalog_item': 'Thuộc tính động lưu ở `attrs jsonb`, kiểm theo JSON Schema của phiên bản (ADR-050); mã duy nhất không phân biệt hoa thường trong phiên bản (BR-07-002).',
    'import_row': 'Bảng tạm, phân vùng theo ngày, xóa phân vùng sau 7 ngày.',
    'outbox': 'Debezium EventRouter đọc WAL và phát lên Kafka; dọn dòng quá 3 ngày.',
    'admin_unit': 'Bảng chiếu làm mới trong giao dịch phát hành danh mục `DVHC` (`f_refresh_admin_unit`).',
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
}
FR_MAC_DINH = {
    'catalog_version': 'FR-07-011…017', 'attribute_def': 'FR-07-005, 006', 'catalog_item': 'FR-07-012, 013, 018, 019, 026…031',
    'version_review': 'FR-07-015, 016, 050', 'import_job': 'FR-07-020…025', 'import_row': 'FR-07-021, 022',
    'sync_source': 'FR-07-035, 038', 'sync_run': 'FR-07-036, 037', 'sync_change': 'FR-07-036, 037', 'code_system': 'FR-07-040',
    'idempotency_key': 'Mọi lệnh tạo (FR-00 quy ước Idempotency-Key)', 'outbox': 'FR-07-034', 'admin_unit': 'FR-07-044…047',
    'file_object': 'FR-07-021, 022, 024, 028', 'shedlock': 'FR-07-016 (tự chuyển hiệu lực), FR-07-036 (lịch đồng bộ)',
}


HDR = {'Ràng buộc': r'\| Tên \| Loại \| Định nghĩa \|', 'Chỉ mục': r'\| Tên \| Định nghĩa \|'}


def bang(sec, tieu_de):
    m = re.search(r'(?m)^(%s\n(?:\|[^\n]*\n?)*)' % HDR[tieu_de], sec)
    if not m:
        return []
    return [[c.strip() for c in l.strip().strip('|').split(' | ')] for l in m.group(1).strip().split('\n')[2:]]


def ds(lst):
    return ', '.join(lst) if lst else 'Không'


def khoi(ten, sec):
    mo = re.match(r'\s*([^|\n:#][^\n]*)\n', sec)
    mo_ta = mo.group(1).strip() if mo else CU.get(ten, '')
    rb = bang(sec, 'Ràng buộc')
    cm = bang(sec, 'Chỉ mục')
    pk = [r[2] for r in rb if len(r) > 2 and r[1] == 'Khóa chính']
    uq = ['`%s` %s' % (r[0].strip('`'), re.sub(r'^`?UNIQUE ', '', r[2]).strip('`')) for r in rb if len(r) > 2 and r[1] == 'Duy nhất' and not r[0].endswith('_id_tenant`')]
    uqi = ['`%s`' % r[0].strip('`') for r in cm if 'UNIQUE INDEX' in r[1]]
    fk = []
    for r in rb:
        if len(r) > 2 and r[1] == 'Khóa ngoại':
            mm = re.search(r'FOREIGN KEY \(([^)]*)\) REFERENCES ph07_rdm\.(\w+)', r[2])
            fk.append('(%s) → `%s`' % (mm.group(1), mm.group(2)) if mm else r[2])
    ck = ['`%s`' % r[0].strip('`') for r in rb if len(r) > 2 and r[1] == 'Kiểm tra']
    ex = ['`%s`' % r[0].strip('`') for r in rb if len(r) > 2 and r[1] not in ('Khóa chính', 'Duy nhất', 'Khóa ngoại', 'Kiểm tra')]
    ix = ['`%s`' % r[0].strip('`') for r in cm if 'UNIQUE INDEX' not in r[1]]
    rls = re.search(r'Chính sách RLS: (.*)', sec)
    mau = re.search(r'Mẫu RLS (S|P)', mo_ta)
    if ten == 'shedlock':
        cl = 'Không áp dụng (bảng kỹ thuật dùng chung cho tác vụ định kỳ).'
    elif ten == 'admin_unit':
        cl = 'Chỉ dòng `COMMON`; mọi tenant đọc, chỉ phiên `PLATFORM` ghi.'
    elif mau and mau.group(1) == 'S':
        cl = 'RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; ghi dòng của tenant phiên, dòng `COMMON` chỉ khi tenant phiên là `PLATFORM` (mục 1.2).'
    else:
        cl = 'RLS mẫu P (FORCE): chỉ dòng của tenant phiên (mục 1.2).'
    if rls:
        cl = cl.rstrip('.') + '. Chính sách: ' + rls.group(1).strip().rstrip('.') + '.'
    pv = 'Phân vùng RANGE theo ngày; giữ 7 ngày.' if 'Phân vùng' in mo_ta else ('Chỉ thêm (không sửa, không xóa).' if 'chỉ-thêm' in mo_ta or 'chỉ thêm' in mo_ta.lower() else 'Không.')
    fr = ', '.join(dict.fromkeys(re.findall(r'FR-07-\d{3}(?:…\d{3})?(?:, \d{3}(?:…\d{3})?)*', mo_ta))) or FR_MAC_DINH.get(ten, 'Xem mô tả bảng')
    gc = GHI_CHU.get(ten, 'Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.')
    if ex:
        gc += ' Ràng buộc khác: ' + ', '.join(ex) + '.'
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk).replace('PRIMARY KEY ', '')), ('Duy nhất', ds(uq + uqi)),
           ('Khóa ngoại', ds(fk)), ('Ràng buộc CHECK', ds(ck)), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'),
           ('Cách ly tenant', cl), ('Phân vùng, chỉ thêm', pv), ('Ghi chú', gc)]
    o = ['::: dac-ta']
    for k, v in muc:
        v = v.strip()
        if v and not v.endswith('.'):
            v += '.'
        o += ['**%s.** %s' % (k, v), '']
    o[-1] = ':::'
    return '\n'.join(o)


def cap(sec, ten):
    sec = sec.replace('\nRàng buộc:\n\n', '\n')
    sec = sec.replace('\nChỉ mục:\n\n', '\n')
    out, k = [], 0
    blocks = re.split(r'(\n\n)', sec)
    tables = list(re.finditer(r'(?m)^(\|[^\n]*\n)+', sec))
    caps = {'| Cột ': 'Cột của bảng `%s`' % ten, '| Tên | Loại ': 'Ràng buộc của bảng `%s`' % ten, '| Tên | Định nghĩa': 'Chỉ mục của bảng `%s`' % ten}
    for t in reversed(tables):
        txt = t.group(0)
        after = sec[t.end():t.end() + 3]
        if after.startswith('\n: ') or after.startswith(': '):
            continue
        for p, c in caps.items():
            if txt.startswith(p):
                sec = sec[:t.end()] + '\n: ' + c + '\n' + sec[t.end():]
                break
    return sec


parts = re.split(r'(?m)^(### 3\.\d+\. `(\w+)`[^\n]*\n)', s)
out = [parts[0]]
for i in range(1, len(parts), 4):
    head, ten, body = parts[i], parts[i + 1], parts[i + 2] if i + 2 < len(parts) else ''
    # parts layout: [pre, head, ten, body, head, ten, body...]
out = [parts[0]]
i = 1
while i < len(parts):
    head, ten, body = parts[i], parts[i + 1], parts[i + 2]
    tail = ''
    m = re.search(r'(?m)^## ', body)
    if m:
        body, tail = body[:m.start()], body[m.start():]
    k = khoi(ten, body)
    body = re.sub(r'^\s*[^|\n:#][^\n]*\n', '\n', body, count=1)  # đoạn mô tả đã vào mục Mục đích
    out.append(head + '\n' + k + '\n' + cap(body, ten) + tail)
    i += 3
open(f, 'w', encoding='utf-8').write(''.join(out))
print('đã thêm khối đặc tả cho', (len(parts) - 1) // 3, 'bảng')
