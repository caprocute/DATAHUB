#!/usr/bin/env python3
"""Sinh asyncapi-dq.yaml (AsyncAPI 3.0) cho EVT-08-01…14 (phát) và 8 kênh tiêu thụ EVT-06, EVT-07 từ FRS 9.3 và spec.py.
Chạy từ api/ph08:  python3 tools/gen_asyncapi.py
CloudEvents 1.0 dạng cấu trúc (JSON). Sự kiện không mang giá trị dữ liệu hay khóa bản ghi cá nhân, chỉ mã đối tượng, số đếm, điểm."""
import os, re, sys
import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from spec import obj, SCH
from gen_openapi import ex_of, NoAlias

OUT = os.path.join(spec.ROOT, "asyncapi-dq.yaml")
AS = ("assetCode!", "acode")
SC_ = ("scanId!", "uuid")
obj("RuleSetActivatedData", "Phiên bản bộ quy tắc `ACTIVE` (FR-08-018); `dq-inline` làm mới bộ đệm.", AS, ("ruleSetCode!", "rscode"), ("versionNo!", "int", 4), ("ruleCount", "int", 18), ("activatedAt", "ts"))
obj("ScanCompletedData", "Lần đo `SUCCEEDED` hoặc `PARTIAL` (FR-08-028).", SC_, AS, ("scanMode!", "E:ScanMode", "FULL"), ("scanTrigger!", "E:ScanTrigger", "SCHEDULE"),
    ("status!", "str", "SUCCEEDED", {"enum": ["SUCCEEDED", "PARTIAL"]}), ("periodCode", "period"), ("score", "score"), ("verdict", "E:Verdict", "PASS"), ("trend", "E:Trend", "IMPROVED"),
    ("flags", "[E:SnapshotFlag]", []), ("rowsScanned", "int", 1200000), ("rowsFailed", "int", 9400), ("official", "bool", False))
obj("ScanFailedData", "Lần đo `FAILED` (FR-08-031).", SC_, AS, ("scanTrigger!", "E:ScanTrigger", "SCHEDULE"), ("errorCode!", "str", "ERR-08-105", {"pattern": "^ERR-08-[0-9]{3}$"}))
obj("ScoreDegradedData", "Điểm giảm từ mức `08.trend.degraded-alert` (FR-08-029).", AS, SC_, ("previousScore!", "score", 91.0), ("score!", "score", 84.5), ("delta!", "num", -6.5), ("threshold", "num", 5.0))
obj("ThresholdBreachedData", "Kết luận chuyển `FAIL` hoặc xuống dưới ngưỡng cảnh báo.", AS, SC_, ("score!", "score", 71.2), ("verdict!", "E:Verdict", "FAIL"), ("breach!", "E:BreachKind", "VERDICT_FAIL"), ("threshold", "num", 75))
obj("TopRuleCount", "Quy tắc và số lỗi mới.", ("ruleCode!", "rcode"), ("count!", "int", 312))
obj("FindingOpenedData", "Lần đo có lỗi mới, gộp theo lần đo (FR-08-036); không mang khóa bản ghi.", SC_, AS, ("newFindings!", "int", 420), ("bySeverity", "obj", {"CRITICAL": 12, "MAJOR": 150, "MINOR": 258}), ("topRules", "[$TopRuleCount]"))
obj("IssueCreatedData", "Mở phiếu (FR-08-041).", ("issueCode!", "icode"), AS, ("severity!", "E:Severity", "CRITICAL"), ("ownerOrgCode!", "org"), ("assignee", "str", "le.thi.hoa"), ("slaDueAt", "ts"), ("findingCount", "int", 312))
obj("IssueStatusChangedData", "Phiếu đổi trạng thái, quá hạn, leo thang (FR-08-043, 045).", ("issueCode!", "icode"), AS, ("kind!", "E:StatusChangeKind", "STATUS_CHANGE"), ("fromStatus", "E:IssueStatus", "ASSIGNED"),
    ("toStatus!", "E:IssueStatus", "IN_PROGRESS"), ("escalationLevel", "int", 0), ("ownerOrgCode", "org"))
obj("IssueVerifiedData", "Phiếu `VERIFIED` (FR-08-044).", ("issueCode!", "icode"), AS, ("verifyScanId", "uuid"), ("scoreBefore", "score", 71.2), ("scoreAfter", "score", 88.0))
obj("WaiverApprovedData", "Ngoại lệ `ACTIVE` (FR-08-040).", ("waiverId!", "uuid"), AS, ("ruleCode", "rcode"), ("validFrom!", "date", "2026-11-26"), ("validTo!", "date", "2027-05-25"))
obj("ReportPublishedData", "Báo cáo `PUBLISHED` hoặc `WITHDRAWN` (FR-08-053).", ("reportCode!", "rpcode"), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode!", "period"),
    ("status!", "str", "PUBLISHED", {"enum": ["PUBLISHED", "WITHDRAWN"]}), ("signed", "bool", False))
obj("AlertFiredData", "Cảnh báo `FIRING` hoặc `RESOLVED` (FR-08-048); không chứa giá trị dữ liệu.", ("alertId!", "uuid"), ("alertRuleCode!", "rscode", "cb-diem-duoi-ngung"), ("assetCode", "acode"),
    ("severity!", "E:AlertSeverity", "HIGH"), ("status!", "str", "FIRING", {"enum": ["FIRING", "RESOLVED"]}), ("message", "str", "Điểm chất lượng thấp hơn ngưỡng cảnh báo."))
obj("CheckFailedData", "Phút có kết luận `FAIL` trực tuyến, gộp theo đối tượng và bên gọi (FR-08-034).", ("bucketAt!", "ts"), AS, ("caller!", "str", "luong-dang-ky-khai-sinh"), ("failCount!", "int", 30),
    ("checkCount!", "int", 1200), ("topRules", "[$TopRuleCount]"))
obj("KpiPublishedData", "Bản tin KPI cho PH-16 (FR-08-057).", ("kind!", "E:KpiKind", "SCAN_SNAPSHOT"), ("kpiSchemaVersion!", "int", 1), ("periodCode", "period"), ("tenantScore", "score"),
    ("domainScores", "[$DomainCard]"), ("issues", "$IssueSummary"), ("official", "bool", False))
# --- sự kiện tiêu thụ (chỉ khai trường PH-08 dùng; bên phát giữ hợp đồng gốc ở D03-04-PH06, D03-04-PH07)
obj("MdmGoldenEventData", "Bản ghi vàng đổi (EVT-06-01…04); PH-08 chỉ dùng mã để gom khóa cho đo tăng dần.", ("domainCode!", "dcode"), ("goldenId", "uuid"), ("goldenIds", "[uuid]"), ("survivorId", "uuid"),
    ("mergedIds", "[uuid]"), ("toGoldenIds", "[uuid]"), ("version", "int", 7), ("changeType", "str", "UPDATE"), ("changedAttributes", "[str]", ["phone"]), extra={"additionalProperties": True})
obj("MdmModelActivatedData", "Mô hình domain `ACTIVE` (EVT-06-10); PH-08 so lược đồ đối tượng `MDM_DOMAIN`.", ("domainCode!", "dcode"), ("version!", "int", 4), extra={"additionalProperties": True})
obj("RdmCatalogRetiredData", "Danh mục ngừng (EVT-07-03).", ("catalogCode!", "str", "DM_DAN_TOC"), ("retireDate!", "date", "2026-12-31"), ("reason!", "str", "Thay bằng danh mục mới"),
    ("replacementCatalogCode", "str", "DM_DAN_TOC_2026"), extra={"additionalProperties": True})
obj("RdmCatalogPublishedData", "Danh mục phát hành phiên bản (EVT-07-05).", ("catalogCode!", "str", "DM_DAN_TOC"), ("versionNo!", "int", 3), ("effectiveFrom!", "date", "2026-12-01"), ("breaking", "bool", False),
    extra={"additionalProperties": True})
obj("RdmAdminUnitData", "Tổ chức lại đơn vị hành chính (EVT-07-10).", ("versionNo!", "int", 5), ("effectiveFrom!", "date", "2026-12-01"), extra={"additionalProperties": True})
for n in sorted(spec.ENUMS):
    SCH.setdefault(n, spec.enum_schema(n))

DATA = ["RuleSetActivatedData", "ScanCompletedData", "ScanFailedData", "ScoreDegradedData", "ThresholdBreachedData", "FindingOpenedData", "IssueCreatedData", "IssueStatusChangedData",
        "IssueVerifiedData", "WaiverApprovedData", "ReportPublishedData", "AlertFiredData", "CheckFailedData", "KpiPublishedData"]
KEY = ["assetCode", "assetCode", "assetCode", "assetCode", "assetCode", "assetCode", "issueCode", "issueCode", "issueCode", "assetCode", "reportCode", "assetCode", "assetCode", "tenant"]
IN_DATA = {"EVT-06-01": "MdmGoldenEventData", "EVT-06-02": "MdmGoldenEventData", "EVT-06-03": "MdmGoldenEventData", "EVT-06-04": "MdmGoldenEventData", "EVT-06-10": "MdmModelActivatedData",
           "EVT-07-03": "RdmCatalogRetiredData", "EVT-07-05": "RdmCatalogPublishedData", "EVT-07-10": "RdmAdminUnitData"}


def camel(t):
    p = re.sub(r"[^A-Za-z0-9]+", " ", t).split()
    return p[0] + "".join(x.title() for x in p[1:])


def envelope(code, typ, dn, src, desc):
    return {"type": "object", "description": f"{code} · CloudEvents 1.0 dạng cấu trúc. {desc}", "required": ["specversion", "id", "type", "source", "time", "data"],
            "properties": {"specversion": {"const": "1.0"}, "id": {"type": "string", "format": "uuid", "description": "Bên nhận khử trùng theo `id` (inbox)."},
                           "type": {"const": typ}, "source": {"type": "string", "examples": [src]}, "time": {"type": "string", "format": "date-time"},
                           "datacontenttype": {"const": "application/json"}, "data": {"$ref": "#/components/schemas/" + dn}}}


def build():
    ch, ops, msgs, envs = {}, {}, {}, {}
    schemas = {k: {kk: vv for kk, vv in v.items() if kk != "x-ex"} for k, v in SCH.items()}
    for i, (code, topic, when, who) in enumerate(spec.EVT):
        dn = DATA[i]
        rest = re.sub(r"^t68\.dq\.|\.v1$", "", topic)
        typ = "vn.datahub.dq." + rest + ".v1"
        name = camel(rest)
        envs[name + "Event"] = envelope(code, typ, dn, "dh-data/dq/T68", when + ".")
        ex = {"specversion": "1.0", "id": "0193a0c3-0000-7000-8000-%012d" % (i + 1), "type": typ, "source": "dh-data/dq/T68", "time": "2026-11-26T09:15:00+07:00",
              "datacontenttype": "application/json", "data": ex_of(dn)}
        addr = topic.replace("t68.", "{tenant}.", 1)
        msgs[name] = {"name": name, "title": code, "summary": when, "contentType": "application/json", "payload": {"$ref": "#/components/schemas/" + name + "Event"},
                      "bindings": {"kafka": {"key": {"type": "string", "description": "Khóa phân vùng: `%s`." % KEY[i]}}}, "examples": [{"name": "vi-du", "payload": ex}]}
        ch[name] = {"address": addr, "title": code, "description": f"{when}. Bên tiêu thụ: {who}.", "messages": {name: {"$ref": "#/components/messages/" + name}},
                    "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
                    "bindings": {"kafka": {"topic": addr, "partitions": 3, "replicas": 3, "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": 604800000, "min.insync.replicas": 2}}}}
        ops["send" + name[0].upper() + name[1:]] = {"action": "send", "channel": {"$ref": "#/channels/" + name}, "title": code,
                                                     "summary": "`dh-data` (module `dq`) phát " + code, "messages": [{"$ref": "#/channels/%s/messages/%s" % (name, name)}]}
    for i, (code, topic, act) in enumerate(spec.EVT_IN):
        dn = IN_DATA[code]
        has_t = topic.startswith(("t68.", "{tenant}."))
        addr = re.sub(r"^t68\.", "{tenant}.", topic)
        body = re.sub(r"^(\{tenant\}|common)\.|\.v1$", "", addr)
        name = camel(body)
        typ = "vn.datahub." + body + ".v1"
        envs[name + "Event"] = envelope(code, typ, dn, "dh-data/" + body.split(".")[0] + "/T68", "Sự kiện tiêu thụ; hợp đồng gốc ở tập API của bên phát.")
        ex = {"specversion": "1.0", "id": "0193a0c3-1000-7000-8000-%012d" % (i + 1), "type": typ, "source": "dh-data/" + body.split(".")[0] + "/T68", "time": "2026-11-26T09:10:00+07:00",
              "datacontenttype": "application/json", "data": ex_of(dn)}
        msgs[name] = {"name": name, "title": code, "summary": act, "contentType": "application/json", "payload": {"$ref": "#/components/schemas/" + name + "Event"}, "examples": [{"name": "vi-du", "payload": ex}]}
        c = {"address": addr, "title": code, "description": f"PH-08 tiêu thụ: {act}.", "messages": {name: {"$ref": "#/components/messages/" + name}},
             "bindings": {"kafka": {"topic": addr}}}
        if has_t:
            c["parameters"] = {"tenant": {"$ref": "#/components/parameters/tenant"}}
        ch[name] = c
        ops["receive" + name[0].upper() + name[1:]] = {"action": "receive", "channel": {"$ref": "#/channels/" + name}, "title": code,
                                                        "summary": f"`dh-data` (module `dq`) nhận {code}, khử trùng theo `id` ở `ph08_dq.inbox_event`", "messages": [{"$ref": "#/channels/%s/messages/%s" % (name, name)}]}
    schemas.update(envs)
    return {"asyncapi": "3.0.0", "info": {"title": "Datahub PH-08 Chất lượng dữ liệu: sự kiện", "version": "1.0.0-draft",
            "description": "Hợp đồng sự kiện EVT-08-01…14 phát ra và 8 sự kiện tiêu thụ từ PH-06, PH-07 (D03-04-PH08 mục 4, FRS 9.3). Ghi vào `ph08_dq.outbox_event` cùng giao dịch nghiệp vụ, Debezium Outbox Event Router đưa lên Kafka; CloudEvents 1.0 dạng cấu trúc. "
                           "Không sự kiện nào mang giá trị dữ liệu hay khóa bản ghi cá nhân: chỉ mã đối tượng, số đếm, điểm. Lưu giữ 7 ngày; ít nhất một lần, bên nhận khử trùng theo `id`. "
                           "Tương thích BACKWARD: chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`.",
            "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)"}},
            "defaultContentType": "application/json",
            "servers": {"kafka-internal": {"host": "dh-kafka-kafka-bootstrap.dh-kafka.svc:9093", "protocol": "kafka-secure",
                                           "description": "Listener `internal`: DU, `dh-runtime`, Kafka Connect; mTLS, ACL theo tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
            "channels": ch, "operations": ops,
            "components": {"securitySchemes": {"mtls": {"type": "X509", "description": "mTLS, ACL theo CN và tiền tố tenant."}},
                           "parameters": {"tenant": {"description": "Mã tenant chữ thường, ví dụ `t68`.", "examples": ["t68"]}},
                           "messages": msgs, "schemas": schemas}}


if __name__ == "__main__":
    d = build()
    txt = "# D03-04-PH08 · AsyncAPI PH-08. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("kênh:", len(d["channels"]), "operation:", len(d["operations"]), "->", OUT)
