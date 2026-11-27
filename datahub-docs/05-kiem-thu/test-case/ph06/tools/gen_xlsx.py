#!/usr/bin/env python3
"""Sinh ph06/D05-02-PH06-test-case.xlsx từ D05-02-PH06 (mục 9.5)."""
import re
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, PatternFill
from openpyxl.worksheet.datavalidation import DataValidation
import tc_parse as P

OUT = P.DOC.parent / 'ph06' / 'D05-02-PH06-test-case.xlsx'
tcs = P.parse(); tsn = P.ts_names(); frs = P.fr_catalog()
HEAD = PatternFill('solid', fgColor='DCE6F5'); BOLD = Font(bold=True)
WRAP = Alignment(wrap_text=True, vertical='top')

def sheet(ws, header, rows, widths):
    ws.append(header)
    for c in ws[1]: c.font = BOLD; c.fill = HEAD; c.alignment = WRAP
    for r in rows: ws.append(r)
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[ws.cell(1, i).column_letter].width = w
    for row in ws.iter_rows(min_row=2):
        for c in row: c.alignment = WRAP
    ws.freeze_panes = 'C2'; ws.auto_filter.ref = ws.dimensions

wb = Workbook()
ws = wb.active; ws.title = 'TestCase'
rows = []
for t in tcs:
    fr = ', '.join(sorted(r for r in t['refs'] if r.startswith('FR-06')))
    lgc = sorted(r for r in t['refs'] if r.startswith('LGC'))
    if not lgc:  # suy từ FR
        lgc = sorted({l for r in t['refs'] if r in frs for l in frs[r]['lgc'] if len(frs[r]['lgc']) < 5})
    other = ', '.join(sorted(r for r in t['refs'] if not r.startswith(('FR-06', 'LGC'))))
    rows.append([t['id'], f"{t['ts']} · {tsn.get(t['ts'], '')}", t['name'], t.get('purpose', ''), t['type'], t['prio'],
                 t['auto'], fr, ', '.join(lgc), other, t['data'], t['steps'], t['expect'], t.get('notice', ''),
                 t.get('post', ''), '', '', '', ''])
sheet(ws, ['Mã TC', 'Kịch bản', 'Tên ca', 'Mục đích', 'Loại', 'Ưu tiên', 'Tự động', 'FR', 'LGC', 'Truy vết khác',
           'Tiền điều kiện, dữ liệu', 'Các bước', 'Kết quả mong đợi', 'Thông báo hiển thị', 'Hậu điều kiện',
           'Kết quả', 'Người chạy', 'Ngày chạy', 'Mã lỗi theo dõi'],
      rows, [12, 30, 40, 40, 14, 8, 14, 18, 18, 28, 40, 60, 70, 50, 40, 12, 14, 12, 16])
dv = DataValidation(type='list', formula1='"Đạt,Không đạt,Chặn,Chưa chạy"', allow_blank=True)
ws.add_data_validation(dv); dv.add(f'P2:P{len(rows)+1}')

ws2 = wb.create_sheet('UAT')
sheet(ws2, ['Mã', 'Việc cán bộ làm', 'Liên quan hệ cũ', 'Mong đợi', 'FR', 'TC liên quan', 'Kết quả', 'Cán bộ thực hiện', 'Ngày', 'Ghi chú'],
      [[u['id'], u['task'], u['lgc'], u['expect'], u['fr'], u['tc'], '', '', '', ''] for u in P.uat_rows()],
      [8, 50, 24, 50, 18, 18, 12, 20, 12, 30])

ws3 = wb.create_sheet('TruyVet')
r3 = []
for f, v in frs.items():
    pos = sorted({t['id'] for t in tcs if f in t['refs'] and 'Dương' in t['type']})
    neg = sorted({t['id'] for t in tcs if f in t['refs'] and 'Âm' in t['type']})
    r3.append([f, v['name'], v['prio'], ', '.join(v['lgc']), ', '.join(pos), ', '.join(neg),
               'Có' if (pos and neg) or v['prio'] != 'M' else 'Không'])
sheet(ws3, ['FR', 'Tên', 'Mức', 'LGC', 'Ca dương', 'Ca âm', 'Đạt quy tắc M'], r3, [12, 50, 6, 24, 40, 40, 10])

ws4 = wb.create_sheet('HuongDan')
for line in ['Tệp sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_xlsx.py. Không sửa tay các cột A–O.',
             'Cột Kết quả chọn: Đạt, Không đạt, Chặn, Chưa chạy. Ghi mã lỗi theo dõi khi Không đạt.',
             'Quy ước 403-PQ, 401-XT, 403-TC, 404-ẩn, KT, EVT và các trường của khối đặc tả xem mục 1.5 của tài liệu.',
             f'Tổng số ca: {len(tcs)}; số kịch bản: {len(tsn)}.']:
    ws4.append([line])
ws4.column_dimensions['A'].width = 120
OUT.parent.mkdir(parents=True, exist_ok=True)
wb.save(OUT); print('đã ghi', OUT, len(tcs), 'ca')
