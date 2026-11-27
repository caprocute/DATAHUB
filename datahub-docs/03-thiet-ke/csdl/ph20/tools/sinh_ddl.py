#!/usr/bin/env python3
"""Sinh ddl/ph20_tenant.sql (schema ph20_tenant, D03-03-PH20) từ danh mục bảng khai báo trong sinh_ddl.py và sinh_ddl_b.py.

Chạy từ thư mục csdl/ph20:  python3 tools/sinh_ddl.py
Enum lấy từ brief PH-20 §5.1 (trùng FRS Phụ lục A); chỉ được thêm giá trị, không đổi tên. Enum bổ sung của CSDL (không có ở §5.1) đánh dấu "bổ sung" ở dict ENUM.
Kết quả có dấu -- @file, -- @changeset, -- @rollback để tools/gen_liquibase.py sinh changelog. DDL là nguồn chuẩn cho dung_md.py;
không sửa tay tệp sinh ra, sửa ở đây rồi sinh lại.

Mỗi cột khai báo một dòng: "tên kiểu [!] [= mặc định] # ghi chú", dấu ! là NOT NULL.
Loại bảng (kind): tenant (bảng tenant, không có tenant_id), own (tenant sở hữu, tenant ghi, PLATFORM đọc), ctl (bản ghi điều khiển về tenant,
PLATFORM ghi, tenant đọc), tech (bảng kỹ thuật, tenant ghi cùng giao dịch, PLATFORM ghi), plat (dữ liệu nền tảng tenant_id = PLATFORM), platr (như plat, mọi tenant đọc).
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = "ph20_tenant"

ENUM = {
    "TenantStatus": "PROVISIONING ACTIVE SUSPENDED MERGING MERGED DECOMMISSIONED FAILED",
    "IsolationMode": "SHARED DEDICATED_DB DEDICATED_CLUSTER",
    "TenantKind": "PROVINCE PLATFORM COMMON",
    "ProvisioningRunStatus": "PENDING RUNNING WAITING FAILED COMPENSATING COMPENSATED SUCCEEDED CANCELLED",
    "ProvisioningStepStatus": "PENDING RUNNING WAITING_REPORT SUCCEEDED FAILED SKIPPED COMPENSATING COMPENSATED",
    "RunKind": "INITIAL SUPPLEMENT ISOLATION_CHANGE",
    "LifecycleRequestType": "SUSPEND RESUME TERMINATE ISOLATION_CHANGE QUOTA_DECREASE",
    "RequestStatus": "DRAFT PENDING_APPROVAL APPROVED REJECTED EXECUTING DONE CANCELLED",
    "SuspendReason": "MANAGEMENT_DECISION SECURITY_INCIDENT CONTRACT_EXPIRED TENANT_REQUEST OTHER",
    "QuotaResource": "API_RPS ACTIVE_FLOWS KAFKA_PRODUCE_MBPS KAFKA_CONSUME_MBPS OBJECT_STORAGE_GB DATABASE_GB USERS MEMBER_SYSTEMS PUBLISHED_APIS TOPICS RUNTIME_CPU RUNTIME_MEMORY_GB",
    "QuotaAlertLevel": "WARN_80 LIMIT_100",
    "ModuleState": "DISABLED ENABLING ENABLED DISABLING SUSPENDED FAILED",
    "MergeStatus": "DRAFT PENDING_APPROVAL APPROVED DRY_RUN TRANSFERRING CONFLICT_REVIEW IDENTITY_TRANSFER CUTOVER TRANSITION COMPLETED CANCELLED FAILED",
    "MergeMappingType": "ORGANIZATION MEMBER_SYSTEM CATALOG_CODE API_CONTEXT_PATH USER TOPIC",
    "ConflictResolution": "KEEP_TARGET KEEP_SOURCE RENAME_SOURCE MERGE_ITEMS SKIP",
    "OrgType": "PROVINCE_PC DEPARTMENT COMMUNE_PC PUBLIC_UNIT OTHER",
    "OrgStatus": "ACTIVE INACTIVE DISSOLVED MERGED",
    "ReleaseChannel": "STABLE PREVIEW",
    "ReleaseStatus": "DRAFT PREVIEW STABLE DEPRECATED WITHDRAWN",
    "UpgradePlanStatus": "DRAFT SCHEDULED RUNNING PAUSED COMPLETED ROLLED_BACK CANCELLED",
    "TenantUpgradeStatus": "PENDING IN_WINDOW UPGRADING VERIFYING DONE FAILED ROLLED_BACK SKIPPED",
    "ExportPackageStatus": "REQUESTED COLLECTING READY DELIVERED EXPIRED FAILED",
    "DriftStatus": "IN_SYNC DRIFTED RECONCILING UNKNOWN",
    # Enum bổ sung của CSDL (không có ở FRS Phụ lục A §5.1), ghi ở Đề nghị đồng bộ
    "TemplateStatus": "DRAFT ACTIVE RETIRED",
    "ContactType": "PRIMARY TECHNICAL SECURITY BILLING",
    "ContractStatus": "DRAFT ACTIVE EXPIRED TERMINATED",
    "ServiceLevel": "STANDARD PREMIUM",
    "ModuleCatalogStatus": "AVAILABLE PLANNED DEPRECATED",
    "DependencyType": "REQUIRED OPTIONAL",
    "ConfigScope": "PLATFORM_CONFIG SETTINGS QUOTA MODULES ALL",
    "ChangeSource": "API SAGA RESTORE DRIFT_FIX",
    "ApplyStatus": "PENDING APPLIED FAILED",
    "DriftResolution": "RECONCILED ACCEPTED IGNORED",
    "SmokeCheck": "LOGIN_ADMIN API_SAMPLE EVENT_SAMPLE CROSS_TENANT_LEAK",
    "SmokeResult": "PASS FAIL SKIPPED",
    "OverrideStatus": "ACTIVE EXPIRED REVOKED",
    "UsageSource": "MIMIR APISIX KAFKA OBJECT_STORE DATABASE IAM CATALOG RUNTIME OTHER",
    "AlertState": "OPEN ACKNOWLEDGED RESOLVED",
    "PushStatus": "PENDING PUSHED FAILED",
    "QuotaSource": "TEMPLATE CONTRACT OVERRIDE",
    "ReportStatus": "REQUESTED GENERATING READY FAILED EXPIRED",
    "ReportFormat": "XLSX CSV PDF",
    "ExportItemStatus": "PENDING COLLECTING DONE FAILED",
    "ParticipantPhase": "DRY_RUN TRANSFER IDENTITY CUTOVER VERIFY",
    "ParticipantStatus": "PENDING RUNNING SUCCEEDED FAILED SKIPPED",
    "MappingStatus": "PROPOSED CONFIRMED CONFLICT APPLIED",
    "ConflictKind": "DUPLICATE_CODE DUPLICATE_PATH DUPLICATE_USER OTHER",
    "ConflictState": "OPEN RESOLVED",
    "ImportStatus": "UPLOADED PREVIEWED APPLYING DONE FAILED CANCELLED",
    "ImportMode": "CREATE_ONLY UPSERT",
    "ImportAction": "CREATE UPDATE SKIP ERROR",
    "ImportRowStatus": "VALID ERROR APPLIED SKIPPED",
    "ComponentType": "SERVICE CONSOLE CHART SCHEMA CONFIG",
    "WaveStatus": "PENDING RUNNING PAUSED DONE STOPPED",
    "WindowType": "RECURRING ONE_OFF",
    "LeakTrigger": "SCHEDULE MANUAL PRE_ACTIVATION",
    "LeakStatus": "RUNNING PASSED FAILED ERROR",
    "ScanStatus": "PENDING CLEAN INFECTED",
    "FilePurpose": "CONTRACT EXPORT_PACKAGE ORG_IMPORT USAGE_REPORT LEAK_REPORT LOGO OTHER",
    "IdemState": "IN_PROGRESS COMPLETED",
    "ReportScope": "TENANT PLATFORM",
}
STEP_CODES = ("S01_RECORD S02_CONFIG_REPO S03_REALM S04_SECRETS S05_BUCKETS S06_EVENTING S07_DATABASE S08_OBSERVABILITY S09_GATEWAY S10_INTEGRATION "
              "S11_SEED_RDM S12_SEED_MDM S13_ORG_SEED S14_KPI S15_MODULES S16_SMOKE S17_ACTIVATE")
TOPICS = ("platform.tenant.created.v1 platform.tenant.provisioning-failed.v1 platform.tenant.activated.v1 platform.tenant.status-changed.v1 "
          "platform.tenant.quota-changed.v1 platform.tenant.quota-threshold-reached.v1 platform.tenant.module-enabled.v1 platform.tenant.module-disabled.v1 "
          "platform.tenant.config-changed.v1 platform.tenant.merge-started.v1 platform.tenant.merge-cutover.v1 platform.tenant.merge-completed.v1 "
          "platform.release.published.v1 platform.tenant.upgrade-changed.v1 platform.tenant.export-ready.v1 platform.obs.audit.recorded.v1")

TABLES = []
FILES = []  # (tên tệp changeset, mô tả)


def lst(vals):
    return ", ".join("'%s'" % v for v in vals.split())


def en(col, key):
    return (col, "%s IN (%s)" % (col, lst(ENUM[key])))


def parse_col(s):
    left, _, comment = s.partition(" # ")
    parts = left.split(" ", 2)
    name, typ = parts[0], parts[1]
    rest = parts[2] if len(parts) > 2 else ""
    nn = rest.startswith("!")
    default = None
    m = re.search(r"= (.+)$", rest)
    if m:
        default = m.group(1).strip()
    return {"name": name, "type": typ, "nn": nn, "default": default, "comment": comment.strip()}


def T(name, kind, comment, cols, ck=(), uq=(), fk=(), ix=(), uqi=(), trg=(), post=(), part=None, nodel=False, append=False, file=None, bare=False, pk=None):
    TABLES.append(dict(name=name, kind=kind, comment=comment, cols=[parse_col(c) for c in cols], ck=list(ck), uq=list(uq), fk=list(fk),
                       ix=list(ix), uqi=list(uqi), trg=list(trg), post=list(post), part=part, nodel=nodel, append=append, file=file or FILES[-1][0], bare=bare, pk=pk))


def F(name, desc):
    FILES.append((name, desc))


def cfk(col, parent, name=None, ondelete=None):
    """Khóa ngoại kép (cột, tenant_id) → (id, tenant_id) của bảng cha cùng tenant."""
    return (name or col[:-3], "(%s, tenant_id) REFERENCES %s.%s (id, tenant_id)%s" % (col, S, parent, " ON DELETE " + ondelete if ondelete else ""))


def sfk(col, parent, pcol="id", name=None):
    """Khóa ngoại đơn tới bảng nền tảng hoặc tenant (không cùng tenant_id)."""
    nm = name or (col[:-3] if col.endswith("_id") else col)
    return (nm, "(%s) REFERENCES %s.%s (%s)" % (col, S, parent, pcol))


STD_COLS = ["created_at timestamptz ! = now() # Thời điểm tạo.", "created_by varchar(64) ! # Người tạo (mã người dùng hoặc `system:*`).",
            "updated_at timestamptz ! = now() # Thời điểm sửa cuối (trigger `tg_touch`).", "updated_by varchar(64) ! # Người sửa cuối.",
            "version integer ! = 0 # Khóa lạc quan, thành phần của ETag (`If-Match`)."]

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sinh_ddl_b.py"), encoding="utf-8").read())
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sinh_ddl_c.py"), encoding="utf-8").read())


def q(s):
    return s.replace("'", "''")


def emit_table(t, n):
    nm = t["name"]
    o = []
    cols = []
    if not t["bare"]:
        cols.append(parse_col("id uuid ! # Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1)."))
    if t["kind"] != "tenant":
        cols.append(parse_col("tenant_id varchar(16) ! # Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép."))
    cols += t["cols"] + ([] if t["bare"] else [parse_col(c) for c in STD_COLS])
    t["allcols"] = cols
    lines = []
    for c in cols:
        d = "  %-22s %-14s%s%s" % (c["name"], c["type"], " NOT NULL" if c["nn"] else "", (" DEFAULT " + c["default"]) if c["default"] else "")
        lines.append(d.rstrip())
    cons = []
    if t["bare"]:
        cons.append("CONSTRAINT pk_%s PRIMARY KEY (%s)" % (nm, t["pk"]))
    elif t["part"]:
        cons.append("CONSTRAINT pk_%s PRIMARY KEY (id, %s)" % (nm, t["part"]))
    else:
        cons.append("CONSTRAINT pk_%s PRIMARY KEY (id)" % nm)
        if t["kind"] != "tenant":
            cons.append("CONSTRAINT uq_%s_id_tenant UNIQUE (id, tenant_id)" % nm)
    for sfx, cols_ in t["uq"]:
        cons.append("CONSTRAINT uq_%s_%s UNIQUE (%s)" % (nm, sfx, cols_))
    k = t["kind"]
    if k in ("own", "ctl"):
        cons.append("CONSTRAINT ck_%s_tenant CHECK (tenant_id ~ '^T[0-9]{2}$')" % nm)
    elif k in ("plat", "platr"):
        cons.append("CONSTRAINT ck_%s_tenant CHECK (tenant_id = 'PLATFORM')" % nm)
    elif k == "tech":
        cons.append("CONSTRAINT ck_%s_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM')" % nm)
    elif k == "any":
        cons.append("CONSTRAINT ck_%s_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM')" % nm)
    for sfx, expr in t["ck"]:
        cons.append("CONSTRAINT ck_%s_%s CHECK (%s)" % (nm, sfx, expr))
    if k in ("own", "ctl", "any"):
        cons.append("CONSTRAINT fk_%s_tenant FOREIGN KEY (tenant_id) REFERENCES %s.tenant (code)" % (nm, S))
    for sfx, body in t["fk"]:
        cons.append("CONSTRAINT fk_%s_%s FOREIGN KEY %s" % (nm, sfx, body))
    o.append("CREATE TABLE %s.%s (" % (S, nm))
    o.append(",\n".join(lines + ["  " + c for c in cons]))
    o.append(")%s;" % (" PARTITION BY RANGE (%s)" % t["part"] if t["part"] else ""))
    for sfx, cols_, where in t["uqi"]:
        o.append("CREATE UNIQUE INDEX uq_%s_%s ON %s.%s (%s)%s;" % (nm, sfx, S, nm, cols_, " WHERE " + where if where else ""))
    auto = []
    for sfx, body in t["fk"]:
        m = re.match(r"\((\w+), tenant_id\)", body)
        if m:
            auto.append(("fk_" + sfx, "tenant_id, " + m.group(1), None))
    seen = set()
    for sfx, cols_, where in [(x + (None,))[:3] for x in list(t["ix"]) + auto]:
        if sfx in seen:
            continue
        seen.add(sfx)
        o.append("CREATE INDEX ix_%s_%s ON %s.%s (%s)%s;" % (nm, sfx, S, nm, cols_, " WHERE " + where if where else ""))
    if not t["bare"]:
        o.append("CREATE TRIGGER tg_%s_touch BEFORE UPDATE ON %s.%s FOR EACH ROW EXECUTE FUNCTION %s.tg_touch();" % (nm, S, nm, S))
    for tname, ev, fn, args in t["trg"]:
        o.append("CREATE TRIGGER tg_%s_%s BEFORE %s ON %s.%s FOR EACH ROW EXECUTE FUNCTION %s.%s(%s);" % (nm, tname, ev, S, nm, S, fn, args))
    if t["append"]:
        o.append("CREATE TRIGGER tg_%s_append_only BEFORE UPDATE OR DELETE ON %s.%s FOR EACH ROW EXECUTE FUNCTION %s.tg_append_only();" % (nm, S, nm, S))
    mode = {"own": "OWN", "ctl": "CTL", "tech": "TECH", "plat": "PLAT", "platr": "PLATR", "any": "CTL"}.get(k)
    if mode:
        o.append("CALL %s.p_enable_rls('%s.%s', '%s');" % (S, S, nm, mode))
    for p in t["post"]:
        o.append(p)
    o.append("COMMENT ON TABLE %s.%s IS '%s';" % (S, nm, q(t["comment"])))
    for c in cols:
        if c["comment"]:
            o.append("COMMENT ON COLUMN %s.%s.%s IS '%s';" % (S, nm, c["name"], q(c["comment"])))
    o.append("-- @rollback DROP TABLE IF EXISTS %s.%s CASCADE;" % (S, nm))
    return "\n".join(o)


def main():
    head = open(os.path.join(ROOT, "tools", "dau_ddl.sql"), encoding="utf-8").read()
    tail = open(os.path.join(ROOT, "tools", "cuoi_ddl.sql"), encoding="utf-8").read()
    out = [head.rstrip("\n"), ""]
    # nhóm theo tệp changeset, giữ thứ tự khai báo
    order = []
    for t in TABLES:
        if t["file"] not in order:
            order.append(t["file"])
    n = 0
    fdesc = dict(FILES)
    for f in order:
        out.append("-- @file %s" % f)
        for t in TABLES:
            if t["file"] != f:
                continue
            n += 1
            out.append("-- @changeset ph20-%04d-%s" % (n * 10 + 100, t["name"].replace("_", "-")))
            out.append(emit_table(t, n))
            out.append("")
    # phần cuối: seed, grants (dùng danh sách bảng)
    grants = grant_sql()
    tail = seed_subst(tail).replace("@@GRANTS@@", grants)
    out.append(tail)
    p = os.path.join(ROOT, "ddl", "ph20_tenant.sql")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("Đã sinh %s: %d bảng" % (p, len(TABLES)))


def names(pred):
    return [S + "." + t["name"] for t in TABLES if pred(t)]


def grant_sql():
    all_t = names(lambda t: True)
    g = []
    g.append("GRANT SELECT ON %s TO ph20_ro;" % ", ".join(all_t))
    g.append("GRANT SELECT, INSERT, UPDATE, DELETE ON %s TO ph20_platform_app;" % ", ".join(all_t))
    app_dml = names(lambda t: t["kind"] in ("own", "tech"))
    app_sel = names(lambda t: t["kind"] not in ("own", "tech"))
    g.append("GRANT SELECT, INSERT, UPDATE, DELETE ON %s TO ph20_app;" % ", ".join(app_dml))
    g.append("GRANT SELECT ON %s TO ph20_app;" % ", ".join(app_sel))
    nodel = names(lambda t: t["nodel"])
    g.append("-- Dữ liệu cấu hình, phiên bản, lịch sử, kế hoạch không xóa cứng: chỉ đổi trạng thái hoặc thay thế; dòng con của bản nháp, hàng đợi kỹ thuật mới được xóa.")
    g.append("REVOKE DELETE ON %s FROM ph20_app, ph20_platform_app;" % ", ".join(nodel))
    app = names(lambda t: t["append"])
    g.append("-- Bảng chỉ thêm: không UPDATE, DELETE (trigger tg_append_only là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph20_owner.")
    g.append("REVOKE UPDATE, DELETE ON %s FROM ph20_app, ph20_platform_app;" % ", ".join(app))
    return "\n".join(g)


if __name__ == "__main__":
    main()
