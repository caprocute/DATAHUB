"""Sinh bảng truy vết LGC -> FR, US, UC, API, kịch bản kiểm thử cho D00-03 mục 5.2 (phần B).

Chạy: python3 build/tools/sinh_ma_tran_lgc.py            # in bảng ra màn hình
      python3 build/tools/sinh_ma_tran_lgc.py --ghi      # ghi vào D00-03 giữa hai dấu lgc-fr
      python3 build/tools/sinh_ma_tran_lgc.py --kiem-tra # thoát mã 1 nếu bảng trong D00-03 đã cũ

Nguồn dữ liệu (chỉ đọc):
- Danh sách LGC và PH đích: các bảng mục 4 của D00-03.
- FR, UC: dòng "**Truy vết.**" ngay sau tiêu đề FR trong FRS (D02-03) và tiêu đề UC trong tập use case (D02-04).
- UAT: hàng bảng bắt đầu bằng mã LGC trong tập test case, các mã UAT-nn ở hàng đó (kèm số PH của tập).
- API, kịch bản (TS): dòng "**Truy vết.**" hoặc "**Phủ.**" trong tập test case (D05-02), TS là tiêu đề ### gần nhất phía trên.
- US dùng cùng số với FR (quy ước D02-05: mỗi FR một story, story tách thêm từ 501 không có FR riêng).
Mã viết tắt dạng "LGC-APIM-019; 020" và "API-01-001, 002" được bung ra trước khi ghép."""
import collections
import glob
import os
import re
import sys

GOC = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
D00_03 = os.path.join(GOC, '00-chung', 'D00-03-ma-tran-truy-vet.md')
BAT_DAU = '<!-- lgc-fr:bat-dau (sinh bằng build/tools/sinh_ma_tran_lgc.py --ghi, không sửa tay) -->'
KET_THUC = '<!-- lgc-fr:ket-thuc -->'
LGC = re.compile(r'LGC-([A-Z]+)-(\d{3})((?:\s*[;,]\s*\d{3})*)')
API = re.compile(r'API-(\d\d)-(\d{3})((?:,\s*\d{3})*)')


def doc(f):
    with open(f, encoding='utf-8') as h:
        return h.read().splitlines()


def lgc_trong(dong):
    ra = set()
    for m in LGC.finditer(dong):
        ra.add(f'LGC-{m.group(1)}-{m.group(2)}')
        ra.update(f'LGC-{m.group(1)}-{n}' for n in re.findall(r'\d{3}', m.group(3) or ''))
    return ra


def api_trong(dong):
    ra = set()
    for m in API.finditer(dong):
        ra.add(f'API-{m.group(1)}-{m.group(2)}')
        ra.update(f'API-{m.group(1)}-{n}' for n in re.findall(r'\d{3}', m.group(3) or ''))
    return ra


def theo_tieu_de(mau_tep, mau_tieu_de):
    ra = collections.defaultdict(set)
    for f in sorted(glob.glob(os.path.join(GOC, mau_tep))):
        hien = None
        for d in doc(f):
            if d.startswith('#'):
                m = re.search(mau_tieu_de, d)
                if m:
                    hien = m.group(0)
                continue
            if hien and d.startswith('**Truy vết.**'):
                for l in lgc_trong(d):
                    ra[l].add(hien)
    return ra


def thu_test():
    api, ts = collections.defaultdict(set), collections.defaultdict(set)
    for f in sorted(glob.glob(os.path.join(GOC, '05-kiem-thu/test-case/D05-02-PH*.md'))):
        hien = None
        for d in doc(f):
            if d.startswith('#'):
                m = re.match(r'#+ (TS-\d\d-\d\d)\b', d)
                if m:
                    hien = m.group(1)
                continue
            if d.startswith(('**Truy vết.**', '**Phủ.**')):
                a = api_trong(d)
                for l in lgc_trong(d):
                    api[l] |= a
                    if hien:
                        ts[l].add(hien)
    return api, ts


def thu_uat():
    ra = collections.defaultdict(lambda: collections.defaultdict(set))
    for f in sorted(glob.glob(os.path.join(GOC, '05-kiem-thu/test-case/D05-02-PH*.md'))):
        ph = re.search(r'-PH(\d\d)-', f).group(1)
        for d in doc(f):
            m = re.match(r'\| (LGC-[A-Z]+-\d{3}) \|', d)
            if m:
                for u in re.findall(r'UAT-(\d+)', d):
                    ra[m.group(1)][ph].add(u)
    return ra


def khoa(c):
    m = re.match(r'\w+-(\d\d)-(\d+)', c)
    return m.group(1), int(m.group(2))


def gon(ma, tien_to):
    theo_ph = collections.defaultdict(list)
    for c in sorted(ma, key=khoa):
        m = re.match(r'\w+-(\d\d)-(\d+)', c)
        theo_ph[m.group(1)].append(m.group(2))
    return '; '.join(f'{tien_to}-{p}-' + ', '.join(v) for p, v in sorted(theo_ph.items())) or '—'


def gon_uat(theo_ph):
    return '; '.join(f'PH-{p}: UAT-' + ', '.join(sorted(v, key=int)) for p, v in sorted(theo_ph.items())) or '—'


def danh_sach_lgc():
    ra, thay = [], set()
    for d in doc(D00_03):
        if BAT_DAU in d:
            break
        if not re.match(r'\| LGC-[A-Z]+-\d{3} \|', d):
            continue
        o = [c.strip() for c in d.strip().strip('|').split('|')]
        if o[0] in thay or o[0] in ('LGC-TOOL-022', 'LGC-TOOL-027', 'LGC-IAM-007') and len(o) < 4:
            continue
        thay.add(o[0])
        ph = next((c for c in o[1:] if c.startswith('PH-')), '—')
        ra.append((o[0], ph))
    return ra


def bang():
    fr = theo_tieu_de('02-yeu-cau/frs/D02-03-PH*.md', r'FR-\d\d-\d{3}')
    uc = theo_tieu_de('02-yeu-cau/use-case/D02-04-PH*.md', r'UC-\d\d-\d\d')
    api, ts = thu_test()
    uat = thu_uat()
    dong = ['| Mã | PH đích | FR | US | UC | API | Kịch bản kiểm thử | Nghiệm thu |', '|---|---|---|---|---|---|---|---|']
    for ma, ph in danh_sach_lgc():
        f = fr.get(ma, set())
        dong.append('| ' + ' | '.join([ma, ph, gon(f, 'FR'), gon(f, 'US'), gon(uc.get(ma, set()), 'UC'),
                                       gon(api.get(ma, set()), 'API'), gon(ts.get(ma, set()), 'TS'),
                                       gon_uat(uat.get(ma, {}))]) + ' |')
    return '\n'.join(dong)


def main():
    b = bang()
    if '--ghi' not in sys.argv and '--kiem-tra' not in sys.argv:
        print(b)
        return
    van = open(D00_03, encoding='utf-8').read()
    i, j = van.find(BAT_DAU), van.find(KET_THUC)
    if i < 0 or j < 0:
        sys.exit('D00-03 chưa có cặp dấu lgc-fr')
    moi = van[:i + len(BAT_DAU)] + '\n\n' + b + '\n\n' + van[j:]
    if '--kiem-tra' in sys.argv:
        sys.exit(0 if moi == van else 1)
    open(D00_03, 'w', encoding='utf-8').write(moi)


main()
