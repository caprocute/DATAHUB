"""Danh mục operation PH-20: đọc bảng API-20-001…171 từ FRS §9.4 (nguồn chuẩn mã, đường dẫn, quyền), bổ sung lược đồ, tham số, ghi chú ở đây."""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.abspath(os.path.join(ROOT, '..', '..', '..'))
FRS = os.path.join(DOCS, '02-yeu-cau', 'frs', 'D02-03-PH20-frs-quan-tri-tenant.md')
frs_text = open(FRS, encoding='utf-8').read()


def load_catalog():
    sec = frs_text.split('### 9.4. Danh mục API')[1].split('## 10.')[0]
    rows = []
    for m in re.finditer(r'^\| API-20-(\d{3}) \| (\w+) \| `([^`]+)` \| (.*?) \| ([\d, ]+) \| (.*?) \|$', sec, re.M):
        i, meth, path, desc, frs, perm = m.groups()
        rows.append(dict(id=int(i), method=meth.lower(), path=path, desc=desc.strip(), frs=[int(x) for x in re.findall(r'\d+', frs)], perm=perm.strip()))
    return rows


def load_errors():
    sec = frs_text.split('### 9.1. Mã lỗi')[1].split('### 9.2.')[0]
    out = {}
    for m in re.finditer(r'^\| (ERR-20-\d{3}) \| ([\d—]+) \| (.*?) \| (.*?) \|$', sec, re.M):
        out[m.group(1)] = dict(http=None if m.group(2) == '—' else int(m.group(2)), meaning=m.group(3).strip(), when=m.group(4).strip())
    return out


def load_fr_errors():
    out = {}
    parts = re.split(r'\n#### FR-20-(\d{3}) · ', frs_text)
    for i in range(1, len(parts), 2):
        body = parts[i + 1]
        m = re.search(r'\*\*Luồng ngoại lệ\.\*\*(.*?)\n\*\*Đầu ra', body, re.S)
        out[int(parts[i])] = sorted(set(re.findall(r'ERR-20-\d{3}', m.group(1)))) if m else []
    return out


CAT = load_catalog()
ERR = load_errors()
FRERR = load_fr_errors()
FR_NAMES = {int(a): b.strip() for a, b in re.findall(r'^\| FR-20-(\d{3}) \| ([^|]+)\|', frs_text, re.M)}  # chưa chắc có


def tag_of(i):
    r = [(1, 6, 'Hồ sơ tenant'), (7, 12, 'Đầu mối và hợp đồng'), (13, 24, 'Saga khởi tạo'), (25, 34, 'Mẫu khởi tạo và khởi tạo bổ sung'), (35, 38, 'Cụm riêng'),
         (39, 47, 'Cấu hình tenant'), (48, 62, 'Hạn mức và sử dụng'), (63, 70, 'Phân hệ và tính năng'), (71, 85, 'Vòng đời tenant'), (86, 108, 'Sáp nhập tenant'),
         (109, 128, 'Phát hành sản phẩm'), (129, 134, 'Quản trị nền tảng'), (135, 142, 'Cài đặt và ngữ cảnh tỉnh'), (143, 158, 'Tổ chức'), (159, 161, 'Phiên bản và kiểm toán của tỉnh'),
         (162, 165, 'Registry tenant'), (166, 168, 'Báo tiến độ'), (169, 171, 'Đọc tổ chức')]
    for a, b, t in r:
        if a <= i <= b:
            return t
