"""Gộp ba OpenAPI PH-19 thành một tệp tạm cho sinh_dac_ta_api.py (đường dẫn kèm tiền tố base, quyền thành PERM-19-*)."""
import sys, yaml
out = {'openapi': '3.1.0', 'paths': {}, 'components': {}}
for f in sys.argv[2:]:
    d = yaml.safe_load(open(f))
    base = d['servers'][0]['url'].split('}')[-1] if d.get('servers') else ''
    base = '/' + base.split('/', 3)[-1] if base.startswith('http') else base
    for k, v in d.get('components', {}).items():
        dst = out['components'].setdefault(k, {})
        for n, s in v.items():
            if n in dst and dst[n] != s:
                print('trùng khác nội dung', k, n, f, file=sys.stderr)
            dst.setdefault(n, s)
    for p, it in d['paths'].items():
        for m, op in it.items():
            if not isinstance(op, dict):
                continue
            pm = op.get('x-datahub-permission')
            if isinstance(pm, str):
                op['x-datahub-permission'] = {'permission': f'PERM-19-{pm}' if ' ' not in pm else pm[0].upper() + pm[1:]}
            elif pm is None and 'callback' in f:
                op['x-datahub-permission'] = {'permission': 'Không dùng token; xác thực bằng chữ ký của nhà cung cấp trên `connectionKey`'}
        out['paths'][base + p] = it
yaml.safe_dump(out, open(sys.argv[1], 'w'), allow_unicode=True, sort_keys=False)
