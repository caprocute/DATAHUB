#!/usr/bin/env python3
"""Sinh asyncapi-kpi.yaml (AsyncAPI 3.0) cho EVT-16-01…13 (phát) và 18 kênh tiêu thụ từ FRS 9.3 và spec.py.
Chạy từ api/ph16:  python3 tools/gen_asyncapi.py
CloudEvents 1.0 dạng cấu trúc (JSON). Sự kiện không mang giá trị dữ liệu hay khóa bản ghi cá nhân, chỉ mã đối tượng, số đếm, điểm."""
import os, re, sys
import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from spec import obj, SCH
from gen_openapi import ex_of, NoAlias

OUT = os.path.join(spec.ROOT, "asyncapi-kpi.yaml")
IND_ = ("indicatorCode!", "code")
STR = lambda n, ex, *vals: (n, "str", ex, {"enum": list(vals)})
obj("IndicatorActivatedData", "Phiên bản định nghĩa `ACTIVE` (FR-16-005).", IND_, ("version!", "int", 3), ("supersededVersion", "int", 2), ("groupCode!", "E:GroupCode", "KET_NOI"),
    ("measurement!", "E:Measurement", "AUTO"), ("mandatory!", "bool", True), ("scope!", "E:IndicatorScope", "TENANT"), ("effectiveFrom!", "date", "2026-12-01"))
obj("IndicatorRetiredData", "Chỉ tiêu ngừng hoặc được thay thế (FR-16-006).", IND_, ("replacedBy", "code", "httt-ket-noi-ty-le-v2"), ("effectivePeriod!", "pcode", "M-2027-01"))
obj("SourceStateChangedData", "Nguồn đổi trạng thái (FR-16-013).", ("sourceCode!", "code", "ph08-dq-kpi"), ("sourceType!", "E:SourceType", "EVENT"), ("fromState", "E:SourceState", "ACTIVE"),
    ("toState!", "E:SourceState", "STALE"), ("errorCode", "str", "ERR-16-107", {"pattern": "^ERR-16-[0-9]{3}$"}), ("lastObservedAt", "ts"), ("ageHours", "num", 30.5))
obj("ManualValueDecidedData", "Số liệu tay được quyết định (FR-16-015); chỉ mã, không kèm giá trị bằng chứng.", ("manualId!", "uuid"), IND_, ("periodCode!", "pcode", "Q-2026-Q3"),
    STR("decision!", "ACCEPTED", "ACCEPTED", "REJECTED"), ("enteredBy", "str", "nguyen.thi.lan"), ("decidedBy!", "str", "tran.van.nam"))
obj("PeriodComputedData", "Lần tổng hợp kết thúc (FR-16-018, 020).", ("runId!", "uuid"), ("periodCode!", "pcode", "M-2026-10"), ("trigger!", "E:RunTrigger", "SCHEDULE"),
    STR("state!", "SUCCEEDED", "SUCCEEDED", "PARTIAL", "FAILED"), ("completeness!", "ratio", 0.92), ("flags!", "[E:RunFlag]", ["MANUAL_PENDING"]), ("indicatorTotal", "int", 24), ("indicatorComputed", "int", 22))
obj("IndicatorStatusChangedData", "Chỉ tiêu đổi trạng thái so mục tiêu (FR-16-021).", IND_, ("periodCode!", "pcode", "M-2026-10"), ("groupCode", "E:GroupCode", "VAN_HANH"), ("fromStatus", "E:ValueStatus", "ON_TRACK"),
    ("toStatus!", "E:ValueStatus", "AT_RISK"), ("value", "num", 82.5), ("unit", "str", "%"), ("runId", "uuid"))
obj("ReportSubmittedData", "Báo cáo gửi duyệt (FR-16-028).", ("reportCode!", "rcode"), ("version!", "int", 1), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode", "pcode", "M-2026-10"), ("submittedBy!", "str", "nguyen.thi.lan"))
obj("ReportPublishedData", "Báo cáo `PUBLISHED` (FR-16-029); không mang nội dung báo cáo.", ("reportCode!", "rcode"), ("version!", "int", 1), ("reportType!", "E:ReportType", "PERIODIC"), ("periodCode", "pcode", "M-2026-10"),
    ("publishedAt!", "ts"), ("contentHash!", "sha"), ("correctionOf", "int", 1))
obj("ReportStateChangedData", "Báo cáo về `CHANGES_REQUESTED`, `SUPERSEDED` hoặc `WITHDRAWN` (FR-16-028, 030).", ("reportCode!", "rcode"), ("version!", "int", 1), STR("fromState", "PUBLISHED", "IN_REVIEW", "PUBLISHED"),
    STR("toState!", "WITHDRAWN", "CHANGES_REQUESTED", "SUPERSEDED", "WITHDRAWN"), ("actor", "str", "tran.van.nam"))
obj("ArchComponentChangedData", "Thành phần kiến trúc đổi (FR-16-044, 045, 046).", ("componentCode!", "code", "httt-qlvb"), ("componentType!", "E:ComponentType", "HTTT"),
    STR("change!", "CREATED", "CREATED", "LIFECYCLE_CHANGED", "VERSION_ADDED", "OPS_STATUS_CHANGED"), ("lifecycle", "E:Lifecycle", "ACTIVE"), ("opsStatus", "E:OpsStatus", "UP"),
    ("version", "str", "2.3.0"), ("origin", "E:Origin", "AUTO"))
obj("ArchComplianceAssessedData", "Đánh giá `CONFIRMED`, miễn trừ cấp hoặc hết hạn (FR-16-047).", ("componentCode!", "code", "httt-qlvb"), STR("kind!", "CONFIRMED", "CONFIRMED", "WAIVER_GRANTED", "WAIVER_EXPIRED"),
    ("complianceLevel!", "E:ComplianceLevel", "PARTIAL"), ("previousLevel", "E:ComplianceLevel", "NOT_ASSESSED"), ("assessmentId", "uuid"), ("waiverId", "uuid"), ("validTo", "date", "2027-03-31"))
obj("NationalSubmissionStateChangedData", "Gói quốc gia đổi trạng thái (FR-16-051…053).", ("submissionId!", "uuid"), ("submissionType!", "E:SubmissionType", "KPI_REPORT"),
    ("fromState", "E:SubmissionState", "SENDING"), ("toState!", "E:SubmissionState", "ACKNOWLEDGED"), ("reportCode", "rcode"), ("version", "int", 1), ("componentCount", "int", 12),
    ("attemptCount", "int", 1), ("receiptNo", "str", "BN-2026-001234"), ("errorCode", "str", "ERR-16-117", {"pattern": "^ERR-16-[0-9]{3}$"}))
obj("ExportCompletedData", "Việc xuất xong hoặc lỗi (FR-16-033).", ("exportId!", "uuid"), ("subject!", "E:ExportSubject", "REPORT"), ("format!", "E:Format", "PDF"),
    STR("state!", "SUCCEEDED", "SUCCEEDED", "FAILED"), ("requestedBy!", "str", "nguyen.thi.lan"), ("rowCount", "int", 24), ("expiresAt", "ts"), ("errorCode", "str", "ERR-16-115", {"pattern": "^ERR-16-[0-9]{3}$"}))
# --- sự kiện tiêu thụ (chỉ khai trường PH-16 dùng; bên phát giữ hợp đồng gốc ở tập API của họ)
OPEN = {"additionalProperties": True}
obj("SystemStateChangedIn", "HTTT đổi trạng thái hoặc ảnh chụp giờ (EVT-01-03).", ("systemCode!", "code", "httt-qlvb"), ("name", "str", "Hệ thống quản lý văn bản tỉnh"), ("ownerOrgId", "str", "org-vp-ubnd"),
    ("from", "str", "REVIEWING"), ("to!", "str", "ACTIVE"), ("snapshot", "bool", False), ("securityLevel", "int", 3), extra=OPEN)
obj("CatalogVersionPublishedIn", "Phiên bản API sang `PUBLISHED` (EVT-02-05).", ("apiCode!", "code", "api-tra-cuu-ho-tich"), ("versionNo!", "int", 1), ("major", "int", 1), ("environment", "str", "PROD"), ("visibility", "str", "INTERNAL"), extra=OPEN)
obj("CatalogVersionStateChangedIn", "Phiên bản API đổi trạng thái (EVT-02-06).", ("apiCode!", "code", "api-tra-cuu-ho-tich"), ("versionNo!", "int", 1), ("from", "str", "PUBLISHED"), ("to!", "str", "DEPRECATED"), ("sunsetAt", "ts"), extra=OPEN)
obj("SlaPeriodClosedIn", "Chốt kỳ tuân thủ SLA (EVT-02-13).", ("apiCode!", "code", "api-tra-cuu-ho-tich"), ("versionNo!", "int", 1), ("period!", "str", "2026-10"), ("status!", "str", "MET"), ("consecutiveBreaches", "int", 0), extra=OPEN)
obj("FlowEventIn", "Luồng được tạo hoặc gỡ (EVT-04-01, EVT-04-09).", ("flowCode!", "code", "tra-cuu-ho-tich"), ("flowId", "uuid"), ("workspaceCode", "str", "ho-tich"), extra=OPEN)
obj("DeploymentStatusChangedIn", "Trạng thái triển khai đổi (EVT-04-07).", ("flowCode!", "code", "tra-cuu-ho-tich"), ("deploymentId", "uuid"), ("environment", "str", "PROD"), ("from", "str", "SYNCING"), ("to!", "str", "SYNCED"),
    ("versionNo", "int", 3), ("healthStatus", "str", "HEALTHY"), extra=OPEN)
obj("AdapterStateChangedIn", "Bộ điều hợp đổi trạng thái (EVT-05-08).", ("adapterCode!", "code", "bo-dieu-hop-ho-tich"), ("from", "str", "ACTIVE"), ("to!", "str", "PAUSED"), ("reason", "str", "Bảo trì"), extra=OPEN)
obj("RdmCatalogPublishedIn", "Danh mục phát hành phiên bản (EVT-07-05).", ("catalogCode!", "str", "DM_DAN_TOC"), ("versionNo!", "int", 3), ("effectiveFrom", "date", "2026-12-01"), ("breaking", "bool", False), extra=OPEN)
obj("RdmSyncCompletedIn", "Phiên đồng bộ danh mục quốc gia xong (EVT-07-09).", ("runId!", "uuid"), ("catalogCode", "str", "DM_DAN_TOC"), ("status!", "str", "SUCCEEDED"), ("hasBreaking", "bool", False), extra=OPEN)
obj("DqKpiPublishedIn", "Bản tin KPI chất lượng dữ liệu (EVT-08-14); `snapshotId` làm `idempotencyRef`.", ("kind!", "str", "SCAN_SNAPSHOT"), ("kpiSchemaVersion!", "int", 1), ("snapshotId", "str", "snap-2026-10-31-T68"),
    ("periodCode", "str", "2026-10"), ("tenantScore", "num", 92.5), ("domainScores", "[obj]", [{"domainCode": "HO_TICH", "score": 91.0}]), ("official", "bool", False), extra=OPEN)
obj("TopicEventIn", "Topic `ACTIVE` hoặc `RETIRED` (EVT-10-01, EVT-10-04).", ("topicName!", "str", "t68.dq.kpi.published.v1"), ("projectCode", "str", "du-an-ho-tich"), ("topicKind", "str", "BUSINESS"),
    ("activatedAt", "ts"), ("retiredAt", "ts"), extra=OPEN)
obj("PublicationActivatedIn", "Publication `ACTIVE` (EVT-10-06).", ("publicationCode!", "str", "pub-ho-tich"), ("publisherCode", "str", "httt-ho-tich"), ("topicName", "str", "t68.dq.kpi.published.v1"), extra=OPEN)
obj("NationalPlatformChangedIn", "Nền tảng quốc gia đổi trạng thái (EVT-14-01).", ("platformCode!", "str", "ndop"), ("from", "str", "ACTIVE"), ("to!", "str", "SECURITY_HOLD"), extra=OPEN)
obj("NationalTransactionRecordedIn", "Giao dịch quốc gia kết thúc, siêu dữ liệu (EVT-14-11).", ("transactionCode!", "str", "GD-2026-000123"), ("direction", "str", "OUTBOUND"), ("serviceCode", "str", "tra-cuu-ho-tich"),
    ("platformCode", "str", "ndxp"), ("state!", "str", "SUCCEEDED"), ("errorCode", "str", "E000"), ("fromCache", "bool", False), ("durationMs", "int", 420), extra=OPEN)
obj("NationalSyncRunFinishedIn", "Phiên đồng bộ hoặc đối chiếu quốc gia kết thúc (EVT-14-12).", ("runId!", "uuid"), ("objectType", "str", "CATALOG"), ("status!", "str", "SUCCEEDED"), ("finishedAt", "ts"), extra=OPEN)
obj("PaymentTransactionSucceededIn", "Giao dịch thanh toán thành công (EVT-19-07); PH-16 lọc `isTest = true`.", ("transactionId!", "uuid"), ("transactionCode", "str", "TT-2026-000456"), ("partnerCode", "str", "so-tu-phap"),
    ("serviceCode", "str", "le-phi-ho-tich"), ("amount", "int", 150000), ("paidAt", "ts"), ("channelCode", "str", "QR"), ("isTest", "bool", True), extra=OPEN)
for n in sorted(spec.ENUMS):
    SCH.setdefault(n, spec.enum_schema(n))

DATA = ["IndicatorActivatedData", "IndicatorRetiredData", "SourceStateChangedData", "ManualValueDecidedData", "PeriodComputedData", "IndicatorStatusChangedData", "ReportSubmittedData",
        "ReportPublishedData", "ReportStateChangedData", "ArchComponentChangedData", "ArchComplianceAssessedData", "NationalSubmissionStateChangedData", "ExportCompletedData"]
KEY = ["indicatorCode", "indicatorCode", "sourceCode", "indicatorCode", "periodCode", "indicatorCode", "reportCode", "reportCode", "reportCode", "componentCode", "componentCode", "submissionId", "exportId"]
# (mã, topic, dữ liệu, hành động của PH-16)
IN = [("EVT-01-03", "{tenant}.connect.system.state-changed.v1", "SystemStateChangedIn", "Quan sát `ph01.httt.*` từ ảnh chụp giờ (KPI-01, 05); tự đăng ký thành phần `HTTT`"),
      ("EVT-02-05", "{tenant}.catalog.version.published.v1", "CatalogVersionPublishedIn", "Quan sát số API công bố (`api-cong-bo`); đăng ký thành phần `API`"),
      ("EVT-02-06", "{tenant}.catalog.version.state-changed.v1", "CatalogVersionStateChangedIn", "Cập nhật vòng đời thành phần `API`"),
      ("EVT-02-13", "{tenant}.catalog.sla.period-closed.v1", "SlaPeriodClosedIn", "Quan sát tỷ lệ API đạt SLA (`api-dat-sla-ty-le`)"),
      ("EVT-04-01", "{tenant}.integration.flow.created.v1", "FlowEventIn", "Đăng ký thành phần `FLOW`; mốc đầu của thời gian xây luồng (KPI-06)"),
      ("EVT-04-07", "{tenant}.integration.deployment.status-changed.v1", "DeploymentStatusChangedIn", "Mốc cuối của thời gian xây luồng khi triển khai xong (KPI-06); cập nhật vòng đời `FLOW`"),
      ("EVT-04-09", "{tenant}.integration.flow.retired.v1", "FlowEventIn", "Chuyển thành phần `FLOW` sang `RETIRED`"),
      ("EVT-05-08", "{tenant}.adapter.adapter.state-changed.v1", "AdapterStateChangedIn", "Cập nhật vòng đời thành phần `ADAPTER`"),
      ("EVT-07-05", "{tenant}.rdm.catalog.published.v1", "RdmCatalogPublishedIn", "Quan sát số danh mục quản lý tập trung (KPI-10)"),
      ("EVT-07-09", "{tenant}.rdm.sync.completed.v1", "RdmSyncCompletedIn", "Quan sát độ trễ đồng bộ danh mục quốc gia (KPI-11)"),
      ("EVT-08-14", "{tenant}.dq.kpi.published.v1", "DqKpiPublishedIn", "Quan sát `diem-chat-luong-du-lieu`; khử trùng theo `snapshotId`"),
      ("EVT-10-01", "{tenant}.event.topic.activated.v1", "TopicEventIn", "Đăng ký thành phần `TOPIC`; quan sát số topic"),
      ("EVT-10-04", "{tenant}.event.topic.retired.v1", "TopicEventIn", "Chuyển thành phần `TOPIC` sang `RETIRED`"),
      ("EVT-10-06", "{tenant}.event.publication.activated.v1", "PublicationActivatedIn", "Quan sát số publication"),
      ("EVT-14-01", "{tenant}.national.platform.changed.v1", "NationalPlatformChangedIn", "Cập nhật thành phần `NATIONAL_LINK`"),
      ("EVT-14-11", "{tenant}.national.transaction.recorded.v1", "NationalTransactionRecordedIn", "Quan sát giao dịch quốc gia"),
      ("EVT-14-12", "{tenant}.national.sync.run-finished.v1", "NationalSyncRunFinishedIn", "Quan sát độ trễ đồng bộ danh mục quốc gia (KPI-11)"),
      ("EVT-19-07", "{tenant}.payment.transaction.succeeded.v1", "PaymentTransactionSucceededIn", "Quan sát `giao-dich-thanh-toan-truc-tuyen` (lọc `isTest = true`)")]
assert [c for c, *_ in IN] == spec.EVT_IN_CODES, (spec.EVT_IN_CODES)


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
        rest = re.sub(r"^t68\.kpi\.|\.v1$", "", topic)
        typ = "vn.datahub.kpi." + rest + ".v1"
        name = camel(rest)
        envs[name + "Event"] = envelope(code, typ, dn, "dh-platform/kpi/T68", when + ".")
        ex = {"specversion": "1.0", "id": "0193a0c3-0000-7000-8000-%012d" % (i + 1), "type": typ, "source": "dh-platform/kpi/T68", "time": "2026-11-26T09:15:00+07:00",
              "datacontenttype": "application/json", "data": ex_of(dn)}
        addr = topic.replace("t68.", "{tenant}.", 1)
        msgs[name] = {"name": name, "title": code, "summary": when, "contentType": "application/json", "payload": {"$ref": "#/components/schemas/" + name + "Event"},
                      "bindings": {"kafka": {"key": {"type": "string", "description": "Khóa phân vùng: `%s`." % KEY[i]}}}, "examples": [{"name": "vi-du", "payload": ex}]}
        ch[name] = {"address": addr, "title": code, "description": f"{when}. Bên tiêu thụ: {who}.", "messages": {name: {"$ref": "#/components/messages/" + name}},
                    "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
                    "bindings": {"kafka": {"topic": addr, "partitions": 3, "replicas": 3, "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": 604800000, "min.insync.replicas": 2}}}}
        ops["send" + name[0].upper() + name[1:]] = {"action": "send", "channel": {"$ref": "#/channels/" + name}, "title": code,
                                                     "summary": "`dh-platform` (module `kpi`, `arch`) phát " + code, "description": f"{when}. Ghi vào outbox cùng giao dịch nghiệp vụ.", "messages": [{"$ref": "#/channels/%s/messages/%s" % (name, name)}]}
    for i, (code, addr, dn, act) in enumerate(IN):
        body = re.sub(r"^\{tenant\}\.|\.v1$", "", addr)
        name = "in" + camel(body)[0].upper() + camel(body)[1:]
        mod = body.split(".")[0]
        typ = "vn.datahub." + body + ".v1"
        envs[name + "Event"] = envelope(code, typ, dn, "dh-platform/" + mod + "/T68", "Sự kiện tiêu thụ; hợp đồng gốc ở tập API của bên phát. PH-16 đọc `data` của dạng cấu trúc, hoặc thân của dạng nhị phân.")
        ex = {"specversion": "1.0", "id": "0193a0c3-1000-7000-8000-%012d" % (i + 1), "type": typ, "source": "dh-platform/" + mod + "/T68", "time": "2026-11-26T09:10:00+07:00",
              "datacontenttype": "application/json", "data": ex_of(dn)}
        msgs[name] = {"name": name, "title": code, "summary": act, "contentType": "application/json", "payload": {"$ref": "#/components/schemas/" + name + "Event"}, "examples": [{"name": "vi-du", "payload": ex}]}
        ch[name] = {"address": addr, "title": code, "description": f"PH-16 tiêu thụ: {act}.", "messages": {name: {"$ref": "#/components/messages/" + name}},
                    "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}}, "bindings": {"kafka": {"topic": addr}}}
        ops["receive" + name[0].upper() + name[1:]] = {"action": "receive", "channel": {"$ref": "#/channels/" + name}, "title": code,
                                                        "summary": f"`dh-platform` (module `kpi`) nhận {code}, khử trùng theo `id` ở `ph16_kpi.inbox_event`", "description": f"PH-16 tiêu thụ: {act}.", "messages": [{"$ref": "#/channels/%s/messages/%s" % (name, name)}]}
    schemas.update(envs)
    keep, todo = set(), [n + "Event" for n in list(msgs)]

    def refs(x):
        if isinstance(x, dict):
            for k, v in x.items():
                if k == "$ref" and isinstance(v, str) and v.startswith("#/components/schemas/"):
                    yield v.split("/")[-1]
                else:
                    yield from refs(v)
        elif isinstance(x, list):
            for v in x:
                yield from refs(v)
    while todo:
        n = todo.pop()
        if n in keep or n not in schemas:
            continue
        keep.add(n)
        todo += list(refs(schemas[n]))
    schemas = {k: v for k, v in schemas.items() if k in keep}
    return {"asyncapi": "3.0.0", "info": {"title": "Datahub PH-16 Báo cáo chỉ tiêu và sổ kiến trúc: sự kiện", "version": "1.0.0-draft",
            "description": "Hợp đồng sự kiện EVT-16-01…13 phát ra và 18 sự kiện tiêu thụ của PH-01, 02, 04, 05, 07, 08, 10, 14, 19 (D03-04-PH16 mục 4, FRS 9.3). Ghi vào `ph16_kpi.outbox_event` cùng giao dịch nghiệp vụ, Debezium Outbox Event Router đưa lên Kafka; CloudEvents 1.0 dạng cấu trúc. "
                           "Không sự kiện nào mang nội dung báo cáo hay bằng chứng: chỉ mã đối tượng, trạng thái, số tổng hợp. Lưu giữ 7 ngày; ít nhất một lần, bên nhận khử trùng theo `id`. "
                           "Tương thích BACKWARD: chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`.",
            "contact": {"name": "Nhóm phân hệ PH-16"}, "tags": [{"name": "kpi"}, {"name": "arch"}], "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)"}},
            "defaultContentType": "application/json",
            "servers": {"kafka-internal": {"host": "dh-kafka-kafka-bootstrap.dh-kafka.svc:9093", "protocol": "kafka-secure",
                                           "description": "Listener `internal`: DU, `dh-runtime`, Kafka Connect; mTLS, ACL theo tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
            "channels": ch, "operations": ops,
            "components": {"securitySchemes": {"mtls": {"type": "X509", "description": "mTLS, ACL theo CN và tiền tố tenant."}},
                           "parameters": {"tenant": {"description": "Mã tenant chữ thường, ví dụ `t68`.", "examples": ["t68"]}},
                           "messages": msgs, "schemas": schemas}}


if __name__ == "__main__":
    d = build()
    txt = "# D03-04-PH16 · AsyncAPI PH-16. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("kênh:", len(d["channels"]), "operation:", len(d["operations"]), "->", OUT)
