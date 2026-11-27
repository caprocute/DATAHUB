#!/usr/bin/env python3
"""Sinh changelog Liquibase (formatted SQL) từ ddl/ph07_rdm.sql và seed/*.sql.

Chạy từ thư mục csdl/ph07:  python3 tools/gen_liquibase.py
Dùng lại cho phân hệ khác (PH-01, PH-04, PH-05) bằng tham số, mặc định là PH-07:
  python3 tools/gen_liquibase.py [--ph ph07] [--ddl ph07_rdm.sql] [--schema ph07_rdm] [--author ph07] [--root <thư mục csdl/phNN>]
(--ddl là tên tệp trong ddl/, --author là tác giả changeset, --schema là defaultSchemaName ghi ở chú thích.)
Kết quả: liquibase/db.changelog-ph07.yaml và liquibase/changes/*.sql (không sửa tay).
Dấu nhận dạng trong DDL: -- @file, -- @changeset <id> [thuộc tính], -- @rollback <SQL>.
Các dòng chỉ dành cho psql (\\set, SET ROLE, RESET ROLE) bị bỏ.
"""
import os, re, glob, shutil, sys

def _opt(name, default):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default

PH = _opt("--ph", "ph07")
DDL = _opt("--ddl", "ph07_rdm.sql")
SCHEMA = _opt("--schema", "ph07_rdm")
AUTHOR = _opt("--author", PH)
ROOT = os.path.abspath(_opt("--root", os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, "liquibase")
PSQL_ONLY = re.compile(r"^(\\set |SET ROLE |RESET ROLE;)")

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
    for fobj in split_ddl(os.path.join(ROOT, "ddl", DDL)):
        write_file(fobj["name"], fobj["changesets"], f"Nguồn: ddl/{DDL} · {fobj['name']}")
        order.append((fobj["name"], None))
    for p in sorted(glob.glob(os.path.join(ROOT, "seed", "*.sql"))):
        base = os.path.basename(p); sid = f"{PH}-" + base[3:-4]
        body = [l.rstrip("\n") for l in open(p, encoding="utf-8")]
        ctx = "seed-common"
        write_file(base, [{"id": sid, "attrs": f"splitStatements:false context:{ctx} runOnChange:true runInTransaction:false", "body": body,
                           "rollback": ["-- Dữ liệu nền idempotent, không rollback."]}], f"Nguồn: seed/{base}")
        order.append((base, ctx))
    y = ["# TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.",
         f"# Chạy bởi tài khoản dh_data_migrator (thành viên {PH}_owner), defaultSchemaName={SCHEMA}.",
         "# Context: bootstrap (vai trò, extension, schema), seed-common (dữ liệu nền COMMON, chỉ cụm có tenant PLATFORM).",
         "databaseChangeLog:"]
    for name, ctx in order:
        y.append("  - include:")
        y.append(f"      file: changes/{name}")
        y.append("      relativeToChangelogFile: true")
    with open(os.path.join(OUT, f"db.changelog-{PH}.yaml"), "w", encoding="utf-8") as f:
        f.write("\n".join(y) + "\n")
    n = sum(1 for _ in glob.glob(os.path.join(OUT, "changes", "*.sql")))
    print(f"Đã sinh {n} tệp changeset vào {OUT}")

if __name__ == "__main__":
    main()
