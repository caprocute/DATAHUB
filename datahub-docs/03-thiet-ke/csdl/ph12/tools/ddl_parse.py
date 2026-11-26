#!/usr/bin/env python3
"""Đọc các tệp DDL của PH-12 (ddl/ph12_iam_0*.sql) thành cấu trúc Python.

Dùng chung cho gen_tables_md.py (bảng cột) và them_dac_ta_bang.py (khối đặc tả 10 mục), để hai công cụ cùng
một cách hiểu DDL. Chỉ dùng thư viện chuẩn. Không kết nối CSDL: mọi thông tin lấy từ chữ trong DDL
(CREATE TABLE, CREATE INDEX, CREATE TRIGGER, CALL p_enable_rls, COMMENT ON).
"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCHEMA = 'ph12_iam'


def doc_ddl():
    """Gộp nội dung mọi tệp DDL theo thứ tự tên."""
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, 'ddl', 'ph12_iam_0*.sql'))):
        out.append(open(p, encoding='utf-8').read())
    return '\n'.join(out)


def unq(s):
    return s.replace("''", "'")


def split_body(body):
    """Tách thân CREATE TABLE thành (cột, ràng buộc); ràng buộc có thể trải nhiều dòng."""
    cols, cons = [], []
    depth, cur = 0, None
    for raw in body.split('\n'):
        line = raw.strip()
        if not line or line.startswith('--'):
            continue
        if cur is not None:
            cur += ' ' + line
            depth += line.count('(') - line.count(')')
            if depth <= 0:
                cons.append(cur.rstrip(','))
                cur = None
            continue
        if line.startswith('CONSTRAINT'):
            depth = line.count('(') - line.count(')')
            if depth <= 0:
                cons.append(line.rstrip(','))
            else:
                cur = line
            continue
        cols.append(line.rstrip(','))
    return cols, cons


def parse_col(line):
    m = re.match(r'(\w+)\s+(.+)$', line)
    name, rest = m.group(1), re.sub(r'\s+', ' ', m.group(2))
    gen = re.search(r'GENERATED ALWAYS AS \((.*)\) STORED', rest)
    nn = 'NOT NULL' in rest
    default = None
    d = re.search(r' DEFAULT (.+?)(?: NOT NULL| GENERATED|$)', rest)
    if d:
        default = d.group(1).strip()
    typ = re.split(r' NOT NULL| DEFAULT | GENERATED ', rest)[0].strip()
    return {'name': name, 'type': typ, 'not_null': nn, 'default': default, 'generated': gen.group(1) if gen else None}


def parse_all():
    sql = doc_ddl()
    tables = {}
    for m in re.finditer(r'CREATE TABLE %s\.(\w+) \((.*?)\n\);' % SCHEMA, sql, re.S):
        name = m.group(1)
        cols, cons = split_body(m.group(2))
        tables[name] = {
            'cols': [parse_col(c) for c in cols],
            'constraints': [],
            'indexes': [], 'unique_indexes': [], 'triggers': [], 'rls': None,
            'comment': '', 'col_comments': {},
        }
        for c in cons:
            mm = re.match(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\s*(.*)$', c, re.S)
            if mm:
                tables[name]['constraints'].append((mm.group(1), mm.group(2), re.sub(r'\s+', ' ', mm.group(3)).strip()))
    for m in re.finditer(r'CREATE (UNIQUE )?INDEX (\w+) ON %s\.(\w+)(?: USING (\w+))? \(([^;]*?)\)(?: WHERE ([^;]*?))?;' % SCHEMA, sql, re.S):
        uniq, iname, tname, using, cols, where = m.groups()
        if tname not in tables:
            continue
        item = {'name': iname, 'cols': re.sub(r'\s+', ' ', cols).strip(), 'where': re.sub(r'\s+', ' ', where).strip() if where else None, 'using': using}
        tables[tname]['unique_indexes' if uniq else 'indexes'].append(item)
    for m in re.finditer(r'CREATE TRIGGER (\w+) (BEFORE|AFTER) ([A-Z ]+?(?: OF [\w, ]+?)?(?: OR [A-Z]+)?) ON %s\.(\w+)\s+FOR EACH (ROW|STATEMENT) EXECUTE FUNCTION %s\.(\w+)\(\)' % (SCHEMA, SCHEMA), sql):
        tg, when, ev, tname, scope, fn = m.groups()
        if tname in tables:
            tables[tname]['triggers'].append({'name': tg, 'when': when, 'event': ev.strip(), 'fn': fn})
    for m in re.finditer(r"CALL %s\.p_enable_rls\('%s\.(\w+)'(?:, '(\w)')?\)" % (SCHEMA, SCHEMA), sql):
        if m.group(1) in tables:
            tables[m.group(1)]['rls'] = m.group(2) or 'P'
    for m in re.finditer(r"COMMENT ON TABLE %s\.(\w+) IS '((?:[^']|'')*)';" % SCHEMA, sql):
        if m.group(1) in tables:
            tables[m.group(1)]['comment'] = unq(m.group(2))
    for m in re.finditer(r"COMMENT ON COLUMN %s\.(\w+)\.(\w+) IS '((?:[^']|'')*)';" % SCHEMA, sql):
        if m.group(1) in tables:
            tables[m.group(1)]['col_comments'][m.group(2)] = unq(m.group(3))
    return tables


def enum_and_pattern(table, info):
    """Suy ra giá trị liệt kê và mẫu chuỗi từ CHECK đặt tên ck_{bảng}_{cột}."""
    enums, pats = {}, {}
    colnames = {c['name'] for c in info['cols']}
    for name, kind, body in info['constraints']:
        if kind != 'CHECK' or not name.startswith('ck_%s_' % table):
            continue
        col = name[len('ck_%s_' % table):]
        if col not in colnames:
            continue
        m = re.search(r"\b%s IN \(((?:'[^']*'(?:, )?)+)\)" % col, body)
        if m:
            enums[col] = re.findall(r"'([^']*)'", m.group(1))
        m = re.search(r"\b%s ~ '((?:[^']|'')*)'" % col, body)
        if m and col not in enums:
            pats[col] = unq(m.group(1))
    return enums, pats
