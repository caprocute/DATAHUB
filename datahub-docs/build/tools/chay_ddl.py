#!/usr/bin/env python3
"""Chạy thật mọi DDL của datahub-docs trên PostgreSQL 16 (cổng CI "DDL chạy được").

Với mỗi phân hệ `03-thiet-ke/csdl/phNN/`, trên một CSDL RỖNG riêng:

1. `ddl`: nạp `ddl/phNN_all.sql` nếu có, không thì mọi `ddl/*.sql` theo thứ tự tên,
   bỏ tệp di trú (`*migrate*`, chạy riêng ở bước 3).
2. `test`: chạy `test/*isolation*.sql` (kiểm cô lập tenant, bốn mắt, bất biến...).
3. `migrate`: chạy `test/*migrate*.sql` với `-v ddl_dir=<ddl>` (nếu có).
4. `liquibase`: nếu có `liquibase/changes/`, nạp lần lượt các tệp trên MỘT CSDL rỗng khác
   (kiểm bản Liquibase sinh ra cũng chạy được độc lập với bản `ddl/`).

Sau mỗi phân hệ, CSDL và mọi vai trò nó tạo bị xóa, nên phân hệ sau không "ăn ké" vai trò
của phân hệ trước. Cuối cùng bước `chung` nạp DDL của MỌI phân hệ vào một CSDL `ci_chung`
rồi chạy mọi tệp kiểm thử cô lập, như khi triển khai thật (D03-09: một cụm, nhiều schema):
bắt xung đột tên vai trò, schema, extension giữa các phân hệ.

Mọi lệnh chạy bằng `psql -v ON_ERROR_STOP=1`. Kết nối lấy từ biến môi trường libpq
(PGHOST, PGPORT, PGUSER, PGPASSWORD), cần siêu người dùng vì DDL tạo vai trò và extension.

    python3 datahub-docs/build/tools/chay_ddl.py                # mọi phân hệ
    python3 datahub-docs/build/tools/chay_ddl.py ph07 ph10      # chỉ một số phân hệ
    python3 datahub-docs/build/tools/chay_ddl.py --chi-tiet     # in toàn bộ đầu ra psql

Lỗi đã biết (chưa sửa, đã ghi ở DE-NGHI-DONG-BO) nằm trong `chay_ddl_ngoai_le.txt`,
mỗi dòng `phNN<TAB>bước`. CI chỉ đỏ khi có bước hỏng MỚI; bước trong danh sách mà nay
chạy được thì nhắc xóa khỏi danh sách. Chỉ được THU HẸP tệp đó.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

DOCS = Path(__file__).resolve().parents[2]
CSDL = DOCS / "03-thiet-ke" / "csdl"
NGOAI_LE = Path(__file__).with_name("chay_ddl_ngoai_le.txt")


def psql(db: str, tep: Path, bien: dict[str, str] | None = None) -> tuple[bool, str]:
    cmd = ["psql", "-X", "-q", "-v", "ON_ERROR_STOP=1", "-d", db, "-f", tep.name]
    for k, v in (bien or {}).items():
        cmd += ["-v", f"{k}={v}"]
    # Chạy trong thư mục của tệp để \ir và đường dẫn tương đối hoạt động.
    r = subprocess.run(cmd, cwd=tep.parent, capture_output=True, text=True)
    return r.returncode == 0, (r.stdout + r.stderr)


def tao_db(ten: str) -> None:
    for sql in (f'DROP DATABASE IF EXISTS "{ten}" WITH (FORCE)', f'CREATE DATABASE "{ten}"'):
        subprocess.run(["psql", "-X", "-q", "-d", "postgres", "-c", sql], check=True,
                       capture_output=True, text=True)


def sql(lenh: str, db: str = "postgres") -> str:
    r = subprocess.run(["psql", "-X", "-q", "-At", "-d", db, "-c", lenh], check=True,
                       capture_output=True, text=True)
    return r.stdout


def don_dep(vai_tro_goc: set[str], dbs: set[str]) -> None:
    """Xóa CSDL kiểm thử và mọi vai trò tạo thêm so với lúc bắt đầu."""
    for db in dbs:
        sql(f'DROP DATABASE IF EXISTS "{db}" WITH (FORCE)')
    for r in sorted(set(sql("SELECT rolname FROM pg_roles").split()) - vai_tro_goc):
        sql(f'DROP ROLE IF EXISTS "{r}"')


def cac_buoc(ph: Path) -> list[tuple[str, str, list[tuple[Path, dict[str, str]]]]]:
    """Trả về [(tên bước, CSDL, [(tệp, biến psql)])]."""
    ten = ph.name
    ddl_dir = ph / "ddl"
    tat_ca = sorted(ddl_dir.glob("*_all.sql"))
    if tat_ca:
        ddl = tat_ca
    else:
        ddl = [f for f in sorted(ddl_dir.glob("*.sql")) if "migrate" not in f.name]
    test = sorted((ph / "test").glob("*isolation*.sql"))
    mig = sorted((ph / "test").glob("*migrate*.sql"))
    db = f"ci_{ten}"
    buoc = []
    if ddl:
        buoc.append(("ddl", db, [(f, {}) for f in ddl]))
    if test:
        buoc.append(("test", db, [(f, {}) for f in test]))
    if mig:
        buoc.append(("migrate", db, [(f, {"ddl_dir": str(ddl_dir)}) for f in mig]))
    lb = sorted((ph / "liquibase" / "changes").glob("*.sql"))
    if lb:
        buoc.append(("liquibase", f"ci_{ten}_lb", [(f, {}) for f in lb]))
    return buoc


def chay_chung(ds: list[Path], chi_tiet: bool) -> bool:
    """Mọi DDL vào một CSDL, rồi mọi kiểm thử cô lập."""
    tao_db("ci_chung")
    for buoc_can in ("ddl", "test"):
        for ph in ds:
            for buoc, _db, teps in cac_buoc(ph):
                if buoc != buoc_can:
                    continue
                for tep, bien in teps:
                    ok, out = psql("ci_chung", tep, bien)
                    if chi_tiet:
                        print(out)
                    if not ok:
                        print(f"LỖI chung {ph.name} {tep.name}")
                        loi = [l for l in out.splitlines() if "ERROR" in l]
                        print("    " + "\n    ".join((loi or out.splitlines())[-8:]))
                        return False
    print(f"OK  chung     DDL + kiểm thử của {len(ds)} phân hệ trên một CSDL")
    return True


def doc_ngoai_le() -> set[tuple[str, str]]:
    if not NGOAI_LE.exists():
        return set()
    kq = set()
    for dong in NGOAI_LE.read_text(encoding="utf-8").splitlines():
        dong = dong.strip()
        if dong and not dong.startswith("#"):
            a, b = dong.split("\t")[:2]
            kq.add((a, b))
    return kq


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("phan_he", nargs="*", help="vd ph07 ph10; bỏ trống = tất cả")
    ap.add_argument("--chi-tiet", action="store_true")
    a = ap.parse_args()

    ds = sorted(p for p in CSDL.glob("ph*") if p.is_dir())
    if a.phan_he:
        ds = [p for p in ds if p.name in a.phan_he]
    ngoai_le = doc_ngoai_le()
    hong: list[tuple[str, str]] = []
    vai_tro_goc = set(sql("SELECT rolname FROM pg_roles").split())

    for ph in ds:
        db_da_tao: set[str] = set()
        bo_qua_db: set[str] = set()  # bước trước hỏng thì bỏ các bước sau trên cùng CSDL
        for buoc, db, teps in cac_buoc(ph):
            if db in bo_qua_db:
                print(f"--  {ph.name:5} {buoc:9} bỏ qua (bước trước hỏng)")
                hong.append((ph.name, buoc))
                continue
            if db not in db_da_tao:
                tao_db(db)
                db_da_tao.add(db)
            ok_all, log = True, ""
            for tep, bien in teps:
                ok, out = psql(db, tep, bien)
                log += f"\n### {tep.relative_to(DOCS)}\n{out}"
                if not ok:
                    ok_all = False
                    break
            nhan = "OK " if ok_all else "LỖI"
            print(f"{nhan} {ph.name:5} {buoc:9} {len(teps)} tệp")
            if not ok_all:
                hong.append((ph.name, buoc))
                bo_qua_db.add(db)
                loi = [l for l in log.splitlines() if "ERROR" in l or "LỖI" in l or "psql:" in l]
                print("    " + "\n    ".join((loi or log.splitlines())[-8:]))
            if a.chi_tiet:
                print(log)
        don_dep(vai_tro_goc, db_da_tao)

    if not a.phan_he and len(ds) > 1:
        ok_chung = chay_chung(ds, a.chi_tiet)
        if not ok_chung:
            hong.append(("chung", "chung"))

    moi = [h for h in hong if h not in ngoai_le]
    da_sua = sorted(n for n in ngoai_le if n not in hong and any(p.name == n[0] for p in ds))
    for n in da_sua:
        print(f"::notice::{n[0]} {n[1]} đã chạy được, xóa dòng này khỏi {NGOAI_LE.name}")
    if moi:
        for n in moi:
            lai = "" if n[0] == "chung" else f" {n[0]}"
            print(f"::error::DDL {n[0]} bước {n[1]} hỏng (lỗi mới). Chạy lại: "
                  f"python3 datahub-docs/build/tools/chay_ddl.py{lai} --chi-tiet")
        return 1
    print(f"Xong: {len(ds)} phân hệ, {len(hong)} bước hỏng đã ghi nhận, không có lỗi mới.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
