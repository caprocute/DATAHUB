#!/usr/bin/env python3
"""Sinh changelog Liquibase (formatted SQL) từ ddl/ph15_portal.sql.

Chạy từ thư mục csdl/ph15:  python3 tools/gen_liquibase.py
Kết quả: liquibase/db.changelog-ph15.yaml và liquibase/changes/*.sql (không sửa tay).
Dấu nhận dạng trong DDL: -- @file, -- @changeset <id> [thuộc tính], -- @rollback <SQL>.
Các dòng chỉ dành cho psql (\\set, SET ROLE, RESET ROLE) bị bỏ.
"""
import os, re, glob, shutil

AUTHOR = "ph15"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "liquibase")
PSQL_ONLY = re.compile(r"^(\\set |RESET ROLE;)")

def split_ddl(path):
    files, cur_file, cur = [], None, None
    for line in open(path, encoding="utf-8"):
        s = line.rstrip("\n")
        m = re.match(r"^-- @file (\S+)", s)
        if m:
            cur_file = {"name": m.group(1), "changesets": []}; files.append(cur_file); cur = None; continue
        m = re.match(r"^-- @changeset (\S+)(.*)$", s)
        if m and cur_file is not None:
            cur = {"id": m.group(1), "attrs": m.group(2).strip(), "body": [], "rollback": []}
            cur_file["changesets"].append(cur); continue
        m = re.match(r"^-- @rollback ?(.*)$", s)
        if m and cur is not None:
            cur["rollback"].append(m.group(1)); continue
        if cur is None or PSQL_ONLY.match(s):
            continue
        cur["body"].append(s)
    return files

def write_file(name, changesets, header):
    lines = ["--liquibase formatted sql", f"-- {header}", "-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.", ""]
    for c in changesets:
        lines.append(f"--changeset {AUTHOR}:{c['id']} {c['attrs']}".rstrip())
        body = "\n".join(c["body"]).strip("\n")
        lines.append(body)
        rb = [r for r in c["rollback"] if r.strip()]
        if rb and not all(r.startswith("--") for r in rb):
            for r in rb: lines.append(f"--rollback {r}")
        else:
            lines.append("--rollback empty")
        lines.append("")
    with open(os.path.join(OUT, "changes", name), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

def main():
    shutil.rmtree(OUT, ignore_errors=True); os.makedirs(os.path.join(OUT, "changes"))
    order = []
    for fobj in split_ddl(os.path.join(ROOT, "ddl", "ph15_portal.sql")):
        write_file(fobj["name"], fobj["changesets"], f"Nguồn: ddl/ph15_portal.sql · {fobj['name']}")
        order.append((fobj["name"], None))
    y = ["# TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.",
         "# Chạy bởi tài khoản dh_portal_migrator (thành viên ph15_owner), defaultSchemaName=ph15_portal.",
         "# Context: bootstrap (vai trò, extension, schema). Dữ liệu nền theo tenant nằm trong hàm seed_tenant (15-0090-seed.sql).",
         "databaseChangeLog:"]
    for name, ctx in order:
        y.append("  - include:")
        y.append(f"      file: changes/{name}")
        y.append("      relativeToChangelogFile: true")
    with open(os.path.join(OUT, "db.changelog-ph15.yaml"), "w", encoding="utf-8") as f:
        f.write("\n".join(y) + "\n")
    n = sum(1 for _ in glob.glob(os.path.join(OUT, "changes", "*.sql")))
    print(f"Đã sinh {n} tệp changeset vào {OUT}")

if __name__ == "__main__":
    main()
