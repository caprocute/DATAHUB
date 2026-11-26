"""DSL lược đồ ngắn cho OpenAPI PH-17.

Mỗi trường `tên[!]:kiểu`, `!` là bắt buộc. Kiểu: s, sN (minLength N), i, n, b, ts, d, u, o, code, hash, `[kiểu]`, `#Tên`, `e(A|B)`.
"""
import re

TYPES = {'s': {'type': 'string'}, 'i': {'type': 'integer'}, 'n': {'type': 'number'}, 'b': {'type': 'boolean'},
         'ts': {'type': 'string', 'format': 'date-time'}, 'd': {'type': 'string', 'format': 'date'},
         'u': {'type': 'string', 'format': 'uuid'}, 'o': {'type': 'object', 'additionalProperties': True},
         'code': {'$ref': '#/components/schemas/Code'}, 'hash': {'$ref': '#/components/schemas/Sha256'}}


def split_top(spec):
    out, depth, cur = [], 0, ''
    for ch in spec:
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def ty(t):
    if t.startswith('['):
        return {'type': 'array', 'items': ty(t[1:-1])}
    if t.startswith('#'):
        return {'$ref': '#/components/schemas/' + t[1:]}
    if t.startswith('e('):
        vals = t[2:-1].split('|')
        return {'type': 'integer' if all(v.isdigit() for v in vals) else 'string', 'enum': [int(v) if v.isdigit() else v for v in vals]}
    m = re.fullmatch(r's(\d+)', t)
    if m:
        return {'type': 'string', 'minLength': int(m.group(1))}
    return dict(TYPES[t])


def obj(spec, extra=None, cls=None):
    props, req = {}, []
    for tok in split_top(spec):
        name, t = tok.split(':', 1)
        if name.endswith('!'):
            name = name[:-1]
            req.append(name)
        props[name] = ty(t)
    if extra:
        merged = {}
        for tok in split_top(extra):
            n2, t2 = tok.split(':', 1)
            if n2.endswith('!'):
                n2 = n2[:-1]
                req.insert(0, n2)
            merged[n2] = ty(t2)
        props = {**merged, **props}
    s = {'type': 'object', 'properties': props}
    if req:
        s['required'] = list(dict.fromkeys(req))
    return s


