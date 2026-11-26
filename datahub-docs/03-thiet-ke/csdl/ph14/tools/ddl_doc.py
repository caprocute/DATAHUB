#!/usr/bin/env python3
"""Đọc các tệp ddl/ph14_*.sql và trả về mô hình bảng dùng chung cho hai công cụ sinh tài liệu
(gen_tables_md.py, them_dac_ta_bang.py). Không chạy PostgreSQL: phân tích văn bản DDL đã chạy thử.

Mô hình: tables[tên] = {items: [mục cấp cao nhất trong CREATE TABLE], cols: [...], cons: [...], part: cột phân vùng}.
"""
import glob
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCHEMA = 'ph14_national'


def read_sql():
    parts = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'ddl', 'ph14_*.sql'))):
        parts.append(open(f, encoding='utf-8').read())
    return '\n'.join(parts)


def split_top(body):
    """Tách thân CREATE TABLE theo dấu phẩy ở cấp 0 (tôn trọng ngoặc và chuỗi trong nháy đơn)."""
    items, cur, depth, quote = [], [], 0, False
    for ch in body:
        if quote:
            cur.append(ch)
            if ch == "'":
                quote = False
            continue
        if ch == "'":
            quote = True
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
    if ''.join(cur).strip():
        items.append(''.join(cur))
    return [re.sub(r'\s+', ' ', i).strip() for i in items if i.strip()]


def parse_column(item):
    m = re.match(r'(\w+) (.+)$', item)
    col, rest = m.group(1), m.group(2)
    nn = 'NOT NULL' in rest
    gen = re.search(r'GENERATED ALWAYS AS \((.*)\) STORED', rest)
    default = re.search(r'DEFAULT (.+?)(?: NOT NULL|$)', rest)
    typ = re.split(r' NOT NULL| DEFAULT | GENERATED ', rest)[0].strip()
    dflt = ('sinh: ' + gen.group(1)) if gen else (default.group(1) if default else '')
    return {'name': col, 'type': typ, 'notnull': nn or bool(gen), 'default': dflt}


def parse_tables(sql):
    tables = {}
    for m in re.finditer(r'CREATE TABLE %s\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;' % SCHEMA, sql, re.S):
        items = split_top(m.group(2))
        cols, cons = [], []
        for it in items:
            if it.startswith('CONSTRAINT'):
                cm = re.match(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE) ?(.*)$', it)
                cons.append({'name': cm.group(1), 'kind': cm.group(2), 'def': cm.group(3)})
            else:
                cols.append(parse_column(it))
        tables[m.group(1)] = {'cols': cols, 'cons': cons, 'part': m.group(4)}
    return tables


def parse_comments(sql):
    tcom = {t: v.replace("''", "'") for t, v in re.findall(r"COMMENT ON TABLE %s\.(\w+) IS '((?:[^']|'')*)';" % SCHEMA, sql)}
    ccom = {(t, c): v.replace("''", "'") for t, c, v in re.findall(r"COMMENT ON COLUMN %s\.(\w+)\.(\w+) IS '((?:[^']|'')*)';" % SCHEMA, sql)}
    return tcom, ccom


def parse_indexes(sql):
    uniq, plain = {}, {}
    for m in re.finditer(r'CREATE (UNIQUE )?INDEX (\w+) ON %s\.(\w+)\s+(?:USING \w+ )?(\(.*?\))(?: INCLUDE \(.*?\))?(?: WHERE (.*?))?;' % SCHEMA, sql, re.S):
        u, name, tbl, cols, where = m.groups()
        cols = re.sub(r'\s+', ' ', cols)
        entry = (name, cols, re.sub(r'\s+', ' ', where) if where else None)
        (uniq if u else plain).setdefault(tbl, []).append(entry)
    return uniq, plain


def parse_triggers(sql):
    out = {}
    for m in re.finditer(r"CREATE (?:CONSTRAINT )?TRIGGER (\w+) (?:BEFORE|AFTER) ([A-Za-z_, ]+?) ON %s\.(\w+)\s+(?:DEFERRABLE INITIALLY DEFERRED )?FOR EACH ROW\s+EXECUTE FUNCTION %s\.(\w+)\(([^)]*)\)" % (SCHEMA, SCHEMA), sql):
        name, ev, tbl, fn, args = m.groups()
        out.setdefault(tbl, []).append({'name': name, 'event': ev.strip(), 'fn': fn, 'args': re.findall(r"'(\w+)'", args)})
    return out


def parse_rls(sql):
    return {t: mode for t, mode in re.findall(r"CALL %s\.p_enable_rls\('%s\.(\w+)', '([PS])'\)" % (SCHEMA, SCHEMA), sql)}
