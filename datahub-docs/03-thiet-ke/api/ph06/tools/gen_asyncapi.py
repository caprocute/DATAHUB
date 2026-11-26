#!/usr/bin/env python3
"""Sinh asyncapi-mdm.yaml (AsyncAPI 3.0) cho EVT-06-01…15 từ FRS 9.3 và spec.py. Chạy từ api/ph06:  python3 tools/gen_asyncapi.py
CloudEvents 1.0 dạng cấu trúc (JSON), không có giá trị thuộc tính (BR-06-012); tên thuộc tính chỉ là tên, không là giá trị."""
import copy, os, re, sys
import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from spec import obj, SCH
from gen_openapi import ex_of, NoAlias

OUT = os.path.join(spec.ROOT, "asyncapi-mdm.yaml")
G = ("goldenId!", "uuid")
OP = ("operationId", "uuid", "0193a0c3-1111-7000-8000-000000000002")
DOM = ("domainCode!", "dcode")
# mã -> (khóa thông điệp, thực thể.sự kiện, lược đồ data, khóa phân vùng, mô tả)
obj("GoldenCreatedData", "Bản ghi vàng được tạo (FR-06-034).", DOM, G, ("version!", "int", 1), ("changeType!", "str", "CREATE", {"enum": ["CREATE"]}), ("method", "E:MatchMethod", "DETERMINISTIC"), ("sourceCode", "scode"), OP)
obj("GoldenUpdatedData", "Thuộc tính, liên kết đổi; chỉ tên thuộc tính, không giá trị.", DOM, ("goldenId", "uuid"), ("goldenIds", "[uuid]", None, {"maxItems": 500, "description": "Chỉ khi áp lại hàng loạt (`SURVIVORSHIP_REAPPLY`), gộp tối đa 500."}),
    ("version", "int", 7), ("changeType!", "E:GoldenChangeType", "UPDATE"), ("changedAttributes!", "[acode]", ["phone", "permanentAddress"]), ("sourceCode", "scode"), OP)
obj("GoldenMergedData", "Hợp nhất.", DOM, ("survivorId!", "uuid"), ("mergedIds!", "[uuid]", ["0193a0c2-6c2f-7d5b-8f10-2c3d4e5f6a7b"]), ("version!", "int", 8), ("changedAttributes", "[acode]", ["phone"]), OP)
obj("GoldenSplitData", "Tách.", DOM, G, ("toGoldenIds!", "[uuid]", ["0193a0c2-7d3a-7e6c-9a21-3d4e5f6a7b8c"]), ("version!", "int", 9), OP)
obj("GoldenRetiredData", "Ngừng.", DOM, G, ("retireReason!", "E:RetireReason", "TEST_DATA"), ("version!", "int", 10), OP)
obj("GoldenRestoredData", "Khôi phục từ RETIRED.", DOM, G, ("version!", "int", 11), OP)
obj("CandidateIngestedData", "Lô ứng viên được nhận (gộp, chỉ số lượng).", DOM, ("sourceCode!", "scode"), ("channel!", "E:IngestChannel", "API"), ("received!", "int", 480), ("duplicate", "int", 15), ("rejected", "int", 5))
obj("ItemCreatedData", "Mục hàng đợi mới.", DOM, ("itemId!", "uuid"), ("reason!", "E:QueueReason", "POSSIBLE_MATCH"), ("riskLevel!", "E:RiskLevel", "LOW"), ("priority", "int", 40))
obj("JobFinishedData", "Job kết thúc ở trạng thái cuối.", ("jobId!", "uuid"), ("jobType!", "E:JobType", "BATCH_MATCH"), ("domainCode", "dcode"), ("status!", "E:JobStatus", "SUCCEEDED"), ("counts", "obj", {"input": 5000, "applied": 100, "skipped": 20}))
obj("ModelActivatedData", "Phiên bản mô hình ACTIVE.", DOM, ("version!", "int", 4), ("compatLevel", "E:CompatLevel", "NON_BREAKING"), ("activatedAt", "ts"))
obj("RuleSetActivatedData", "Bộ quy tắc ACTIVE.", DOM, ("version!", "int", 2), ("activatedAt", "ts"))
obj("DiscrepancyDetectedData", "Lượt đối chiếu quốc gia có lệch mới.", ("runId!", "uuid"), DOM, ("newDiscrepancies!", "int", 12), ("critical", "int", 1), ("ratio", "num", 0.0012))
obj("SyncPausedData", "Đồng bộ tạm dừng hoặc tiếp tục.", ("state!", "E:SyncState", "PAUSED"), ("reasonCode", "str", "RATIO_EXCEEDED", {"enum": ["RATIO_EXCEEDED", "MANUAL", "RESUMED"]}), ("ratio", "num", 0.06))
obj("XrefChangedData", "Liên kết chéo được gỡ, chuyển.", DOM, ("xrefId!", "uuid"), ("sourceCode!", "scode"), ("goldenId!", "uuid"), ("fromGoldenId", "uuid"), ("status!", "E:XrefStatus", "DETACHED"), ("reason", "E:XrefDetachReason", "MANUAL"), OP)
obj("SourceCorrectionData", "Yêu cầu sửa tại nguồn; chỉ tên thuộc tính.", ("requestId!", "uuid"), DOM, G, ("sourceCode!", "scode"), ("attributes!", "[acode]", ["phone"]), ("origin", "E:GoldenChangeType", "MANUAL_EDIT"))
for n in sorted(spec.ENUMS):
    SCH.setdefault(n, spec.enum_schema(n))

DATA = ["GoldenCreatedData", "GoldenUpdatedData", "GoldenMergedData", "GoldenSplitData", "GoldenRetiredData", "GoldenRestoredData", "CandidateIngestedData", "ItemCreatedData",
        "JobFinishedData", "ModelActivatedData", "RuleSetActivatedData", "DiscrepancyDetectedData", "SyncPausedData", "XrefChangedData", "SourceCorrectionData"]
KEY = ["goldenId", "goldenId", "survivorId", "goldenId", "goldenId", "goldenId", "sourceCode", "itemId", "jobId", "domainCode", "domainCode", "runId", "tenant", "xrefId", "requestId"]


def camel(t):
    p = re.sub(r"[^A-Za-z0-9]+", " ", t).split()
    return p[0] + "".join(x.title() for x in p[1:])


def build():
    ch, ops, msgs = {}, {}, {}
    schemas = {k: {kk: vv for kk, vv in v.items() if kk != "x-ex"} for k, v in SCH.items()}
    envs = {}
    for i, (code, topic, when, who) in enumerate(spec.EVT):
        dn = DATA[i]
        typ = "vn.datahub.mdm." + re.sub(r"^t68\.mdm\.|\.v1$", "", topic) + ".v1"
        name = camel(re.sub(r"^t68\.mdm\.|\.v1$", "", topic))
        env = {"type": "object", "description": f"{code} · CloudEvents 1.0 dạng cấu trúc.", "required": ["specversion", "id", "type", "source", "time", "data"],
               "properties": {"specversion": {"const": "1.0"}, "id": {"type": "string", "format": "uuid", "description": "Bên nhận khử trùng theo `id` (inbox)."},
                              "type": {"const": typ}, "source": {"type": "string", "examples": ["dh-data/mdm/T68"]}, "time": {"type": "string", "format": "date-time"},
                              "datacontenttype": {"const": "application/json"}, "data": {"$ref": "#/components/schemas/" + dn}}}
        envs[name + "Event"] = env
        ex = {"specversion": "1.0", "id": "0193a0c3-0000-7000-8000-%012d" % (i + 1), "type": typ, "source": "dh-data/mdm/T68", "time": "2026-11-26T09:15:00+07:00",
              "datacontenttype": "application/json", "data": ex_of(dn)}
        addr = topic.replace("t68.", "{tenant}.", 1)
        msgs[name] = {"name": name, "title": code, "summary": when, "contentType": "application/json", "payload": {"$ref": "#/components/schemas/" + name + "Event"},
                      "bindings": {"kafka": {"key": {"type": "string", "description": "Khóa phân vùng: `%s`." % KEY[i]}}}, "examples": [{"name": "vi-du", "payload": ex}]}
        ch[name] = {"address": addr, "title": code, "description": f"{when}. Bên tiêu thụ: {who}.", "messages": {name: {"$ref": "#/components/messages/" + name}},
                    "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
                    "bindings": {"kafka": {"topic": addr, "partitions": 3, "replicas": 3, "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": 604800000, "min.insync.replicas": 2}}}}
        ops["send" + name[0].upper() + name[1:]] = {"action": "send", "channel": {"$ref": "#/channels/" + name}, "title": code,
                                                     "summary": "`dh-data` phát " + code, "messages": [{"$ref": "#/channels/%s/messages/%s" % (name, name)}]}
    schemas.update(envs)
    return {"asyncapi": "3.0.0", "info": {"title": "Datahub PH-06 Dữ liệu chủ: sự kiện", "version": "1.0.0-draft",
            "description": "Hợp đồng sự kiện EVT-06-01…15 (D03-04-PH06 §4, FRS 9.3). Ghi vào `ph06_mdm.outbox_event` cùng giao dịch nghiệp vụ, Debezium Outbox Event Router đưa lên Kafka; CloudEvents 1.0 dạng cấu trúc. "
                           "Không sự kiện nào mang giá trị thuộc tính (BR-06-012): chỉ mã, phiên bản, tên thuộc tính; bên nhận tra lại bản ghi vàng bằng API có kiểm soát. Lưu giữ 3 ngày ở outbox; ít nhất một lần, bên nhận khử trùng theo `id`. "
                           "Tương thích BACKWARD: chỉ thêm trường tùy chọn trong `v1` (ADR-070). Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`.",
            "license": {"name": "Tài liệu nội bộ dự án Datahub (dự thảo)"}},
            "defaultContentType": "application/json",
            "servers": {"kafka-internal": {"host": "dh-kafka-kafka-bootstrap.dh-kafka.svc:9093", "protocol": "kafka-secure",
                                           "description": "Listener `internal`: DU, `dh-runtime`, Kafka Connect; mTLS, ACL theo tiền tố tenant.", "security": [{"$ref": "#/components/securitySchemes/mtls"}]}},
            "channels": ch, "operations": ops,
            "components": {"securitySchemes": {"mtls": {"type": "X509", "description": "mTLS, ACL theo CN và tiền tố tenant."}},
                           "parameters": {"tenant": {"description": "Mã tenant chữ thường, ví dụ `t68`.", "examples": ["t68"], "enum": None}},
                           "messages": msgs, "schemas": schemas}}


if __name__ == "__main__":
    d = build()
    d["components"]["parameters"]["tenant"].pop("enum")
    txt = "# D03-04-PH06 · AsyncAPI PH-06. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("kênh:", len(d["channels"]), "operation:", len(d["operations"]), "->", OUT)
