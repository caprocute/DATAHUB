#!/usr/bin/env python3
"""Bộ phân tích DDL dùng chung cho gen_tables_md.py và them_dac_ta_bang.py của PH-13.

Đọc ddl/ph13_audit.sql và ddl/ph13_obs.sql (theo thứ tự đó), tách CREATE TABLE theo dấu ngoặc và dấu nháy
(CHECK chứa regex có dấu phẩy, ngoặc nên không thể tách bằng regex đơn giản), rồi gom ràng buộc, chỉ mục,
trigger, RLS, COMMENT. Không kết nối PostgreSQL."""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FILES = ['ph13_audit.sql', 'ph13_obs.sql']


def load_sql():
    return '\n'.join(open(os.path.join(ROOT, 'ddl', f), encoding='utf-8').read() for f in FILES)


def split_top(body):
    """Tách các phần tử cấp cao nhất của thân CREATE TABLE (cột, CONSTRAINT) theo dấu phẩy ngoài ngoặc và ngoài nháy."""
    body = re.sub(r'(?m)^\s*--[^\n]*$', '', body)
    items, cur, depth, inq, i = [], [], 0, False, 0
    while i < len(body):
        ch = body[i]
        if inq:
            cur.append(ch)
            if ch == "'":
                if i + 1 < len(body) and body[i + 1] == "'":
                    cur.append("'")
                    i += 1
                else:
                    inq = False
        elif ch == "'":
            inq = True
            cur.append(ch)
        elif ch == '(':
            depth += 1
            cur.append(ch)
        elif ch == ')':
            depth -= 1
            cur.append(ch)
        elif ch == ',' and depth == 0:
            items.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
        i += 1
    if ''.join(cur).strip():
        items.append(''.join(cur))
    return [re.sub(r'\s+', ' ', re.sub(r'(?m)^\s*--[^\n]*$', '', x)).strip() for x in items if x.strip()]


def find_close(s, start):
    """Vị trí dấu ) khớp với ( tại start, bỏ qua nội dung trong nháy đơn."""
    depth, inq, i = 0, False, start
    while i < len(s):
        ch = s[i]
        if inq:
            if ch == "'":
                if i + 1 < len(s) and s[i + 1] == "'":
                    i += 1
                else:
                    inq = False
        elif ch == "'":
            inq = True
        elif ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError('không khớp ngoặc')


def parse():
    sql = load_sql()
    out = []
    for m in re.finditer(r'CREATE TABLE (ph13_\w+)\.(\w+) \(', sql):
        schema, name = m.group(1), m.group(2)
        o = m.end() - 1
        c = find_close(sql, o)
        tail = sql[c + 1:c + 80]
        pm = re.match(r'\s*PARTITION BY RANGE \((\w+)\)', tail)
        cols, cons = [], []
        for it in split_top(sql[o + 1:c]):
            if it.upper().startswith('CONSTRAINT '):
                cm = re.match(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\b\s*(.*)$', it)
                cons.append({'name': cm.group(1), 'kind': cm.group(2), 'def': cm.group(3)})
            else:
                cm = re.match(r'(\w+)\s+(.+)$', it)
                col, rest = cm.group(1), cm.group(2)
                gen = re.search(r'GENERATED ALWAYS AS \((.*)\) STORED', rest)
                nn = 'NOT NULL' in rest
                dm = re.search(r'DEFAULT (.+?)(?: NOT NULL)?$', rest)
                typ = re.split(r' (?:NOT NULL|DEFAULT|GENERATED)\b', rest)[0].strip()
                cols.append({'name': col, 'type': typ, 'notnull': nn, 'default': dm.group(1) if dm else '',
                             'generated': gen.group(1) if gen else ''})
        out.append({'schema': schema, 'name': name, 'cols': cols, 'cons': cons, 'part': pm.group(1) if pm else None})
    tcomment = {(s, t): v.replace("''", "'") for s, t, v in re.findall(r"COMMENT ON TABLE (ph13_\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
    ccomment = {(s, t, c): v.replace("''", "'") for s, t, c, v in re.findall(r"COMMENT ON COLUMN (ph13_\w+)\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
    fcomment = {(s, f): v.replace("''", "'") for s, f, v in re.findall(r"COMMENT ON FUNCTION (ph13_\w+)\.(\w+)\([^)]*\) IS '((?:[^']|'')*)';", sql)}
    indexes = [{'name': n, 'unique': bool(u), 'schema': s, 'table': t, 'rest': r.strip()}
               for u, n, s, t, r in re.findall(r'CREATE (UNIQUE )?INDEX (\w+) ON (ph13_\w+)\.(\w+)([^;]*);', sql)]
    triggers = []
    for m in re.finditer(r'CREATE (?:CONSTRAINT )?TRIGGER (\w+)\s+(BEFORE|AFTER)\s+([A-Z ]+?)\s+ON (ph13_\w+)\.(\w+)\s+(?:DEFERRABLE INITIALLY DEFERRED\s+)?FOR EACH (ROW|STATEMENT)\s+EXECUTE FUNCTION (ph13_\w+)\.(\w+)\(([^)]*)\)', sql):
        triggers.append({'name': m.group(1), 'when': m.group(2), 'event': m.group(3), 'schema': m.group(4), 'table': m.group(5),
                         'level': m.group(6), 'fn': m.group(8), 'args': [a.strip().strip("'") for a in m.group(9).split(',') if a.strip()]})
    rls = {}
    for s, t, mode in re.findall(r"CALL (ph13_\w+)\.p_enable_rls\('ph13_\w+\.(\w+)'(?:, '([PS])')?\)", sql):
        pass
    for m in re.finditer(r"CALL (ph13_\w+)\.p_enable_rls\('(ph13_\w+)\.(\w+)'(?:, '([PS])')?\)", sql):
        rls[(m.group(2), m.group(3))] = m.group(4) or 'P'
    return {'tables': out, 'tcomment': tcomment, 'ccomment': ccomment, 'fcomment': fcomment, 'indexes': indexes,
            'triggers': triggers, 'rls': rls, 'sql': sql}
