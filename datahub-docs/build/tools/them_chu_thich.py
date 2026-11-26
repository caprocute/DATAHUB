"""Thêm chú thích còn thiếu cho bảng và sơ đồ Mermaid theo K-TRINH-BAY §2.

Bảng chưa có dòng `: chú thích` nhận tên mục chứa nó; mục có nhiều bảng thì thêm
hai tiêu đề cột đầu để phân biệt. Khối ```mermaid chưa có caption nhận tên mục.
Bỏ qua bảng Lịch sử phiên bản. Chạy: python3 build/tools/them_chu_thich.py <tệp.md>..."""
import re
import sys


def ten_muc(h):
    t = re.sub(r'^#+\s*', '', h)
    t = re.sub(r'^\d+(\.\d+)*\.\s*', '', t)
    return t.replace('`', '').strip()


def xu_ly(p):
    L = open(p, encoding='utf-8').read().split('\n')
    # đếm bảng theo mục
    muc, dem, cur = [], {}, None
    in_code = False
    for i, l in enumerate(L):
        if l.startswith('```'):
            in_code = not in_code
        if in_code:
            continue
        if re.match(r'^#{2,4} ', l):
            cur = i
        if l.startswith('|---') or l.startswith('| ---'):
            dem[cur] = dem.get(cur, 0) + 1
    out, cur, in_code, n_b, n_h = [], None, False, 0, 0
    for i, l in enumerate(L):
        if l.startswith('```'):
            if not in_code and l.strip() == '```mermaid' and cur is not None:
                l = '```{.mermaid caption="%s"}' % ten_muc(L[cur]).replace('"', "'")
                n_h += 1
            in_code = not in_code
        if not in_code and re.match(r'^#{2,4} ', l):
            cur = i
        out.append(l)
        if in_code or not l.startswith('|'):
            continue
        nxt = L[i + 1] if i + 1 < len(L) else ''
        if nxt.startswith('|'):
            continue
        # dòng cuối của bảng
        j = i
        while j > 0 and L[j - 1].startswith('|'):
            j -= 1
        if j + 1 >= len(L) or not L[j + 1].startswith('|-') and not L[j + 1].startswith('| -'):
            continue
        sau = L[i + 2] if i + 2 < len(L) else ''
        if sau.startswith(': ') or nxt.startswith(': '):
            continue
        if cur is None or ten_muc(L[cur]).startswith('Lịch sử phiên bản'):
            continue
        cap = ten_muc(L[cur])
        k = j - 1
        while k > 0 and not L[k].strip():
            k -= 1
        nhan = re.fullmatch(r'\*\*(.+?)\*\*:?', L[k].strip())
        if nhan:
            cap += ' · ' + nhan.group(1)
        elif dem.get(cur, 0) > 1:
            cot = [c.strip().replace('`', '') for c in L[j].strip('|').split('|')][:2]
            cap += ': ' + ', '.join(cot)
        out += ['', ': ' + cap]
        n_b += 1
    open(p, 'w', encoding='utf-8').write('\n'.join(out))
    print(f'{p}: thêm {n_b} chú thích bảng, {n_h} chú thích hình')


for p in sys.argv[1:]:
    xu_ly(p)
