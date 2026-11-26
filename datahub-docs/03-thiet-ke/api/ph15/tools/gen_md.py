#!/usr/bin/env python3
"""Sinh các bảng của D03-04-PH15 từ OpenAPI, AsyncAPI và FRS, chèn giữa cặp đánh dấu <!-- gen:NAME:start --> ... <!-- gen:NAME:end -->.
NAME: endpoints (§3), evt (§4), err (§6), cover (§3.2). Chạy: python3 tools/gen_md.py (từ api/ph15); sau đó chạy build/tools/sinh_dac_ta_api.py."""
import os, re, sys, yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MD = os.path.join(ROOT, '..', 'D03-04-PH15-api-cong-nha-phat-trien.md')
FRS = os.path.join(ROOT, '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH15-frs-cong-nha-phat-trien.md')
oa = yaml.safe_load(open(os.path.join(ROOT, 'openapi-portal.yaml'), encoding='utf-8'))
aa = yaml.safe_load(open(os.path.join(ROOT, 'asyncapi-portal.yaml'), encoding='utf-8'))
ftxt = open(FRS, encoding='utf-8').read()
ERR = re.findall(r'^\| (ERR-15-\d{3}) \| (\d{3}) \| ([^|]+?) \|', ftxt, re.M)
FRS_FR = re.findall(r'^\| (FR-15-\d{3}) \| ([A-J]) \| ([^|]+?) \|', ftxt, re.M)


def ops():
    out = []
    for p, it in oa['paths'].items():
        for m, o in it.items():
            if m in ('servers', 'parameters'):
                continue
            out.append((o['x-datahub-id'], m.upper(), p, o))
    return sorted(out)


def endpoints():
    L = ['| Mã | Operation | FR | Quyền | I | M |', '|---|---|---|---|---|---|']
    for aid, m, p, o in ops():
        fr = ', '.join(f.replace('FR-15-', '') for f in o['x-datahub-fr'])
        perm = o['x-datahub-permission']['permission']
        perm = perm.replace('PERM-15-', '') if perm.startswith('PERM-15-') else perm if perm.startswith('PERM') else {'Ẩn danh (khách chưa đăng nhập)': 'Ẩn danh', 'Người dùng đã đăng nhập': 'Đăng nhập'}.get(perm, 'mTLS mesh')
        names = {x.get('$ref', '').split('/')[-1] for x in o.get('parameters', [])}
        L.append(f"| {aid} | `{m} {p}` | {fr} | {perm} | {'x' if 'IdempotencyKey' in names else ''} | {'x' if 'IfMatch' in names else ''} |")
    L += ['', ': Danh mục endpoint API-15 (FR: số FR-15-; Quyền: bỏ tiền tố `PERM-15-`; I: nhận `Idempotency-Key`; M: nhận `If-Match`; mã thành công ở chương 11)']
    return '\n'.join(L)


def cover():
    api_of = {}
    for aid, m, p, o in ops():
        for f in o['x-datahub-fr']:
            api_of.setdefault(f, []).append(aid.replace('API-15-', ''))
    no_api = [f for f, g, t in FRS_FR if f not in api_of]
    frs = [f for f, gp, t in FRS_FR]
    n_cov = sum(1 for f in frs if f in api_of)
    L = ['Bảng §3.1 có cột FR; đối chiếu ngược cho thấy %d trên %d FR của FRS có ít nhất một API trong cột đó (script `check_contracts.py` kiểm mã, phương thức, đường dẫn, FR của từng dòng). %s' % (
        n_cov, len(frs), ('Ngoại lệ: ' + ', '.join(no_api) + ' (đăng nhập SSO realm tenant) không có operation REST riêng vì thực hiện ở BFF và Keycloak (OIDC Code + PKCE, `/bff/dang-nhap`); hồ sơ sau đăng nhập đọc qua API-15-041. FR-15-002 (áp mức hiển thị theo người xem) đã có ở cột FR của API-15-003, 004, 005, 007 từ FRS 0.2.') if no_api else 'Không có ngoại lệ.')]
    return '\n'.join(L), no_api


def evt():
    L = ['| Mã | Chủ đề | Khóa | FR phát | Bên nhận | Nội dung chính |', '|---|---|---|---|---|---|']
    for ck, ch in aa['channels'].items():
        if not ch['title'].startswith('EVT-15'):
            continue
        key = re.search(r'Khóa phân vùng: `(\w+)`', ch['description']).group(1)
        fr = re.search(r'Truy vết (FR-15-[^.]*?)\. Bên nhận: ([^.]*?)\.', ch['description'])
        sn = ck[0].upper() + ck[1:]
        req = aa['components']['schemas'][sn]['required']
        L.append(f"| {ch['title']} | `{ch['address']}` | `{key}` | {fr.group(1).replace('FR-15-', '')} | {fr.group(2)} | {', '.join('`'+r+'`' for r in req if r not in ('tenantId', 'occurredAt'))} |")
    L += ['', ': Sự kiện EVT-15 do PH-15 phát (FR: số FR-15-)', '']
    L += ['| Mã | Chủ đề | Dùng cho | Hành vi của cổng |', '|---|---|---|---|']
    for ck, ch in aa['channels'].items():
        if not ch['title'].startswith('EVT-02'):
            continue
        d = ch['description']
        frm = re.search(r'FR-15-([0-9, FR-]*)\.?$', d).group(1).replace('FR-15-', '').rstrip('.')
        L.append(f"| {ch['title']} | `{ch['address']}` | FR-15-{frm} | {d.split(' PH-15 là bên nhận')[0]} |")
    L += ['', ': Sự kiện EVT-02 do PH-02 phát mà PH-15 tiêu thụ']
    return '\n'.join(L)


def err():
    ctl = [e for e in ERR if int(e[0][-3:]) < 100]
    rt = [e for e in ERR if int(e[0][-3:]) >= 100]
    out = []
    for title, rows in (('Control plane', ctl), ('Sandbox, thử API và data plane', rt)):
        out += [f'| Mã | HTTP | Ý nghĩa |', '|---|---|---|']
        out += [f'| {c} | {h} | {t} |' for c, h, t in rows]
        out += ['', f': Mã lỗi ERR-15 {title}', '']
    return '\n'.join(out).rstrip()


def sub(s, name, body):
    pat = re.compile(r'(<!-- gen:%s:start -->).*?(<!-- gen:%s:end -->)' % (name, name), re.S)
    if not pat.search(s):
        print('thiếu cặp đánh dấu', name)
        return s
    return pat.sub(lambda m: m.group(1) + '\n\n' + body + '\n\n' + m.group(2), s)


def main():
    s = open(MD, encoding='utf-8').read()
    cv, no_api = cover()
    for n, b in (('endpoints', endpoints()), ('evt', evt()), ('err', err()), ('cover', cv)):
        s = sub(s, n, b)
    open(MD, 'w', encoding='utf-8').write(s)
    print('FR không có API:', no_api)


if __name__ == '__main__':
    main()
