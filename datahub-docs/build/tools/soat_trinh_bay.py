"""Soát lớp trình bày của một tài liệu theo K-TRINH-BAY §1–§3, §6.

Báo các điểm còn thiếu để người viết sửa (không tự sửa):
  META  thiếu trường metadata bắt buộc hoặc `mo_ta` chứa ": "
  INTRO thiếu phần mở đầu chuẩn (Tóm tắt cho hội đồng; Giới thiệu với mục đích,
        phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc tài liệu)
  CAP   bảng thiếu dòng `: chú thích` hoặc Mermaid thiếu `caption`
  CAPG  chú thích trùng nhau trong cùng tài liệu (thường là chú thích chung chung)
  HINH  sơ đồ không có đoạn văn thuyết minh ngay trước hoặc ngay sau
  MO    tiêu đề ## hoặc ### đi thẳng vào bảng, danh sách hoặc sơ đồ, không có đoạn mở
  LSPB  thiếu mục `## Lịch sử phiên bản` ở cuối
  ASCII khối mã trông như sơ đồ vẽ bằng chữ (nên chuyển Mermaid)

Chạy: python3 build/tools/soat_trinh_bay.py <tệp.md>... [--tom-tat]
Mã thoát 0 dù có cảnh báo; `--tom-tat` chỉ in số lượng theo loại.
"""
import re
import sys
from collections import Counter

BAT_BUOC = ['ma_tai_lieu', 'ten', 'phien_ban', 'ngay', 'trang_thai', 'nguoi_doc', 'mo_ta']
GIOI_THIEU = {
    'mục đích': r'mục đích',
    'phạm vi': r'phạm vi',
    'người đọc': r'người đọc|đối tượng sử dụng',
    'thuật ngữ': r'thuật ngữ|viết tắt',
    'tài liệu tham chiếu': r'tài liệu tham chiếu|tài liệu liên quan|tham chiếu',
    'cấu trúc tài liệu': r'cấu trúc tài liệu|bố cục tài liệu|cách đọc',
}
KY_TU_HOP = re.compile(r'[┌└│─┐┘├┤╔╗╚╝║═▶►◀]|\+-{3,}|-{3,}>|<-{3,}')


def soat(p):
    L = open(p, encoding='utf-8').read().split('\n')
    loi = []
    # metadata
    meta = {}
    if L and L[0] == '---':
        for i in range(1, len(L)):
            if L[i] == '---':
                break
            m = re.match(r'^([a-z_]+):\s*(.*)$', L[i])
            if m:
                meta[m.group(1)] = m.group(2)
    for k in BAT_BUOC:
        if not meta.get(k):
            loi.append(('META', 1, f'thiếu `{k}`'))
    if ': ' in meta.get('mo_ta', ''):
        loi.append(('META', 1, '`mo_ta` chứa ": "'))
    heads = [(i, l) for i, l in enumerate(L) if re.match(r'^#{2,4} ', l)]
    tieu_de = '\n'.join(l.lower() for _, l in heads[:40])
    if 'tóm tắt' not in tieu_de:
        loi.append(('INTRO', 1, 'thiếu "## Tóm tắt cho hội đồng thẩm định"'))
    for ten, rx in GIOI_THIEU.items():
        if not re.search(rx, tieu_de):
            loi.append(('INTRO', 1, f'phần Giới thiệu thiếu mục "{ten}"'))
    if not any(l.strip() == '## Lịch sử phiên bản' for l in L):
        loi.append(('LSPB', len(L), 'thiếu "## Lịch sử phiên bản"'))
    # bảng, mã, hình
    in_code, lang, start, body = False, '', 0, []
    caps = Counter()
    cur_head = ''
    i = 0
    while i < len(L):
        l = L[i]
        if l.startswith('```'):
            if not in_code:
                in_code, lang, start, body = True, l, i, []
            else:
                in_code = False
                if 'mermaid' in lang:
                    m = re.search(r'caption="([^"]*)"', lang)
                    if not m:
                        loi.append(('CAP', start + 1, 'Mermaid thiếu caption'))
                    else:
                        caps[m.group(1)] += 1
                    j = i + 1
                    while j < len(L) and not L[j].strip():
                        j += 1
                    nxt = L[j] if j < len(L) else ''
                    k = start - 1
                    while k > 0 and not L[k].strip():
                        k -= 1
                    truoc = L[k] if k > 0 else ''

                    def la_van(x):
                        return bool(x) and not x.startswith(('#', '|', '```', '- ', '* ', ':::', ': ')) \
                            and not re.match(r'^\d+\. ', x)
                    if not la_van(nxt) and not la_van(truoc):
                        loi.append(('HINH', start + 1, 'sơ đồ thiếu đoạn thuyết minh ngay trước hoặc sau'))
                elif sum(1 for b in body if KY_TU_HOP.search(b)) >= 3:
                    loi.append(('ASCII', start + 1, 'khối mã giống sơ đồ chữ'))
            i += 1
            continue
        if in_code:
            body.append(l)
            i += 1
            continue
        if re.match(r'^#{2,3} ', l):
            cur_head = l
            j = i + 1
            while j < len(L) and not L[j].strip():
                j += 1
            nxt = L[j] if j < len(L) else ''
            if nxt.startswith(('|', '```', '- ', '* ')) or re.match(r'^\d+\. ', nxt):
                if 'Lịch sử phiên bản' not in l:
                    loi.append(('MO', i + 1, f'"{l[:70]}" thiếu đoạn mở'))
        if l.startswith('|') and (i == 0 or not L[i - 1].startswith('|')):
            j = i
            while j < len(L) and L[j].startswith('|'):
                j += 1
            k = j
            while k < len(L) and not L[k].strip():
                k += 1
            hdr = L[i].replace(' ', '')
            la_dac_ta = hdr.startswith('|Trường|Nội dung|')
            la_lspb = 'Lịch sử phiên bản' in cur_head
            if k < len(L) and L[k].startswith(': '):
                caps[L[k][2:].strip()] += 1
            elif not la_dac_ta and not la_lspb and j - i >= 2:
                loi.append(('CAP', i + 1, 'bảng thiếu chú thích'))
            i = j
            continue
        i += 1
    for c, n in caps.items():
        if n > 1:
            loi.append(('CAPG', 0, f'chú thích "{c[:60]}" dùng {n} lần'))
    return loi


def main():
    tom_tat = '--tom-tat' in sys.argv
    for p in [a for a in sys.argv[1:] if not a.startswith('--')]:
        loi = soat(p)
        dem = Counter(k for k, _, _ in loi)
        print(f'== {p}: ' + (', '.join(f'{k}={v}' for k, v in sorted(dem.items())) or 'sạch'))
        if not tom_tat:
            for k, n, m in loi:
                print(f'  {k:5} {n:>5}  {m}')


if __name__ == '__main__':
    main()
