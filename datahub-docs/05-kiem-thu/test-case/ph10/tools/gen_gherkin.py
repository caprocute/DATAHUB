#!/usr/bin/env python3
"""Sinh ph10/gherkin/*.feature từ D05-02-PH10 (mục 9.5). Từ khóa tiếng Việt của Gherkin."""
import re
import tc_parse as P

OUT = P.DOC.parent / 'ph10' / 'gherkin'
tcs = P.parse(); tsn = P.ts_names()

def clean(s):
    return re.sub(r'\s+', ' ', s.replace('**', '')).strip()

def lc(s):
    # viết thường chữ đầu khi là từ thường (không phải mã như U-T68, TC-10, CAT-LH)
    return s[0].lower() + s[1:] if re.match(r'[A-ZÀ-Ỹ][a-zà-ỹ]', s) else s

def steps(text):
    out = []
    for line in text.splitlines():
        line = re.sub(r'^\d+\.\s*', '', line.strip())
        if line: out.append(clean(line))
    return out

OUT.mkdir(parents=True, exist_ok=True)
for old in OUT.glob('*.feature'): old.unlink()
by_ts = {}
for t in tcs: by_ts.setdefault(t['ts'], []).append(t)
for ts, items in by_ts.items():
    slug = ts.lower()
    L = ['# language: vi', f'# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.',
         f'@PH-10 @{ts}', f'Tính năng: {ts} · {tsn.get(ts, "")}', '']
    for t in items:
        tags = ' '.join([f"@{t['id']}", f"@{t['prio']}"] + [f'@{x}' for x in re.findall(r'[A-Za-zÀ-ỹ]+', t['type'])[:3]])
        L += [f'  {tags}', f"  Kịch bản: {t['id']} {clean(t['name'])}",
              f"    # Truy vết: {clean(t['trace'])}",
              f"    Biết {lc(clean(t['data'])) if clean(t['data']) not in ('', '—') else 'bộ dữ liệu chuẩn mục 2 đã nạp'}"]
        st = steps(t['steps'])
        for i, s in enumerate(st):
            L.append(f"    {'Khi' if i == 0 else 'Và'} {lc(s)}")
        L.append(f"    Thì {lc(clean(t['expect']))}")
        L.append('')
    (OUT / f'{slug}.feature').write_text('\n'.join(L), encoding='utf-8')

U = ['# language: vi', '# Sinh tự động từ mục 7 của D05-02-PH10; không sửa tay.', '@PH-10 @UAT',
     'Tính năng: Nghiệm thu người dùng tương đương Bus tích hợp và Productivity Tooling', '',
     '  Bối cảnh:', '    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT',
     '    Và các chương trình tích hợp của tỉnh đã được chuyển từ Bus cũ', '']
for u in P.uat_rows():
    U += [f"  @{u['id']}", f"  Kịch bản: {u['id']} {clean(u['task'])}", f"    # Chức năng hệ cũ: {u['lgc']}; FR: {u['fr']}; TC: {u['tc']}",
          f"    Khi cán bộ {clean(u['task'][0].lower() + u['task'][1:])}", f"    Thì {lc(clean(u['expect']))}", '']
(OUT / 'uat-tuong-duong-bus.feature').write_text('\n'.join(U), encoding='utf-8')
print('đã ghi', len(by_ts) + 1, 'tệp feature')
