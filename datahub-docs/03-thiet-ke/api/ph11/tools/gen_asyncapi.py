#!/usr/bin/env python3
"""Sinh asyncapi-bpm.yaml (AsyncAPI 3.0) cho EVT-11-01…21 từ FRS 9.3 và spec.py. Chạy từ api/ph11:  python3 tools/gen_asyncapi.py
CloudEvents 1.0 dạng cấu trúc (JSON); không sự kiện nào mang giá trị biến (FRS 9.3)."""
import os, re, sys
import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
from spec import obj, SCH
from gen_openapi import ex_of, NoAlias

OUT = os.path.join(spec.ROOT, "asyncapi-bpm.yaml")
BK = "businessKey!:bkey"
IID = "instanceId!:uuid"
obj("PayloadRef", "Tham chiếu tới nội dung lệnh (không nhúng dữ liệu cá nhân).", "objectRef!:str=s3://dh-bpm/t68/cmd/0193b1d4.json", "checksum:str=sha256:9a1c", "sizeBytes:int=2048")
obj("ModelPublishedData", "Phiên bản mô hình được phát hành (FR-11-008).", "processKey!:pkey", "version!:int=3", "checksum!:str=sha256:3f2a9c", "publishedBy!:str=ie.tranvanc", "approvedBy!:str=ia.lethid")
obj("ModelRetiredData", "Phiên bản ngừng dùng hoặc thu hồi (FR-11-009).", "processKey!:pkey", "version!:int=2", ("status!:str=DEPRECATED", None), "reason:str=Thay bằng phiên bản 3.")
SCH["ModelRetiredData"]["properties"]["status"] = {"type": "string", "enum": ["DEPRECATED", "RETIRED"]}
obj("InstanceStartedData", "Phiên khởi tạo (FR-11-018…020).", IID, "processKey!:pkey", "version!:int=3", BK, "startChannel!:E:StartChannel=API", "dueAt:ts")
obj("StepCompletedData", "Bước công khai hoàn thành; tiến độ cho DVC (FR-11-056).", IID, BK, "elementId!:str=Task_DangKyKhaiSinh", "publicName:str=Đăng ký khai sinh", "displayStatus!:E:DisplayStatus=IN_PROGRESS", "percentEstimate:int=33", "manual:bool=false")
obj("InstanceCompletedData", "Phiên hoàn thành.", IID, BK, "outcome!:E:InstanceOutcome=APPROVED", "dueResult:E:DueResult=MET")
obj("InstanceCancelledData", "Phiên bị hủy.", IID, BK, "reason!:str=CITIZEN_WITHDRAWN", "compensated!:bool=false")
obj("InstanceSuspendedData", "Phiên tạm dừng hoặc tiếp tục.", IID, BK, "state!:E:SuspendState=SUSPENDED")
obj("TaskCreatedData", "Việc được tạo (FR-11-034).", "taskId!:uuid", IID, "elementId!:str=Task_DangKyThuongTru", "candidates:[str]=[\"CB_CONG_AN_XA\"]", "dueAt:ts")
obj("TaskAssignedData", "Việc được giao hoặc nhận.", "taskId!:uuid", "assignee!:str=cb.nguyenvana", "delegatedFrom:str", "via!:E:AssignVia=CLAIM")
obj("TaskCompletedData", "Việc hoàn thành.", "taskId!:uuid", "decision:E:Decision=COMPLETE", "completedBy!:str=cb.nguyenvana", "dueResult:E:DueResult=MET")
obj("TaskDueSoonData", "Sắp đến hạn: `taskId` khi chủ thể là việc, `instanceId` khi là phiên.", "taskId:uuid", "instanceId:uuid", "subject!:E:DueSubject=TASK", "dueAt!:ts")
obj("TaskOverdueData", "Quá hạn, kèm leo thang.", "subject!:E:DueSubject=TASK", "id!:uuid", "dueAt!:ts", "escalationLevel!:int=1", "action:E:EscalationAction=NOTIFY_MANAGER")
obj("SagaStartedData", "Bắt đầu bù trừ.", "sagaId!:uuid", IID, "trigger!:E:CompensationTrigger=STEP_FAILURE", "stepCount!:int=3")
obj("SagaCompletedData", "Bù trừ thành công.", "sagaId!:uuid", ("status!:str=SUCCEEDED", {"enum": ["SUCCEEDED"]}))
obj("SagaFailedData", "Bù trừ thất bại, còn bước thủ công.", "sagaId!:uuid", "manualSteps!:[str]=[\"Task_DangKyKhaiSinh\"]")
obj("IncidentOpenedData", "Mở sự cố engine.", "incidentId!:uuid", "type!:E:IncidentType=JOB_FAILED", "instanceId:uuid", "elementId:str=Task_CapTheBHYT")
obj("ServiceRequestedData", "Lệnh thực thi service task tới PH-04 (FR-11-028).", "commandId!:uuid", "intentCode!:code=DK_KHAI_SINH", "elementId!:str=Task_DangKyKhaiSinh", "replyTopic!:str=t68.bpm.service.completed.v1", "timeoutAt!:ts", "payload!:$PayloadRef")
obj("ServiceCompletedData", "Kết quả service task do PH-04 phát (FR-11-029).", "commandId!:uuid", "output:obj={\"soGiayKhaiSinh\":\"KS-2026-001\"}", "completedAt!:ts")
obj("ServiceFailedData", "Lỗi service task do PH-04 phát.", "commandId!:uuid", "errorKind!:E:ErrorKind=TECHNICAL", "errorCode:str=UPSTREAM_TIMEOUT", "message:str=Hệ thống đích không phản hồi.", "attempts!:int=3")
obj("NotificationRequestedData", "Yêu cầu gửi thông báo (FR-11-032); `params` không chứa DLCN.", "templateCode!:code=TB_HO_SO_HOAN_THANH", "audience!:E:NotifyAudience=APPLICANT", "channel!:str=SMS", "params:obj={\"maHoSo\":\"HS-T68-2026-000142\"}")
obj("AuditRecordedData", "Bản ghi kiểm toán của module `bpm`; không mang giá trị biến (FR-11-065).", "action!:str=MODEL_PUBLISH", "objectType!:str=process_version", "objectId!:str=LT_KHAI_SINH:3", "actor!:str=ia.lethid", "traceId!:str=4bf92f3577b34da6a3ce929d0e0e4736", "hashRef:str=h:0193b1d4")
for n in sorted(spec.ENUMS):
    SCH.setdefault(n, spec.enum_schema(n))

DATA = ["ModelPublishedData", "ModelRetiredData", "InstanceStartedData", "StepCompletedData", "InstanceCompletedData", "InstanceCancelledData", "InstanceSuspendedData",
        "TaskCreatedData", "TaskAssignedData", "TaskCompletedData", "TaskDueSoonData", "TaskOverdueData", "SagaStartedData", "SagaCompletedData", "SagaFailedData",
        "IncidentOpenedData", "ServiceRequestedData", "ServiceCompletedData", "ServiceFailedData", "NotificationRequestedData", "AuditRecordedData"]
RECEIVE = {"EVT-11-18", "EVT-11-19"}  # PH-04 phát, PH-11 nhận
assert len(DATA) == len(spec.EVT) == 21


def camel(t):
    p = re.sub(r"[^A-Za-z0-9]+", " ", t).split()
    return p[0] + "".join(x.title() for x in p[1:])


def build():
    ch, ops, msgs, envs = {}, {}, {}, {}
    schemas = {k: {kk: vv for kk, vv in v.items() if kk != "x-ex"} for k, v in SCH.items() if k in {"FieldError", "PayloadRef"} or k.endswith("Data") or k in spec.ENUMS}
    for i, (code, topic, key, fields, who) in enumerate(spec.EVT):
        dn = DATA[i]
        core = re.sub(r"^t68\.bpm\.|\.v1$", "", topic)
        typ = "vn.datahub.bpm." + core + ".v1"
        name = camel(core)
        envs[name + "Event"] = {"type": "object", "description": f"{code} · CloudEvents 1.0 dạng cấu trúc.", "required": ["specversion", "id", "type", "source", "time", "data"],
                                "properties": {"specversion": {"const": "1.0"}, "id": {"type": "string", "format": "uuid", "description": "Bên nhận khử trùng theo `id` (inbox)."},
                                               "type": {"const": typ}, "source": {"type": "string", "examples": ["dh-platform/bpm/T68"]}, "time": {"type": "string", "format": "date-time"},
                                               "datacontenttype": {"const": "application/json"}, "data": {"$ref": "#/components/schemas/" + dn}}}
        ex = {"specversion": "1.0", "id": "0193a0c3-0000-7000-8000-%012d" % (i + 1), "type": typ, "source": "dh-platform/bpm/T68", "time": "2026-11-26T09:15:00+07:00",
              "datacontenttype": "application/json", "data": ex_of(dn)}
        addr = topic.replace("t68.", "{tenant}.", 1)
        msgs[name] = {"name": name, "title": code, "summary": f"{code}: {core}. Trường chính: {fields}", "contentType": "application/json",
                      "payload": {"$ref": "#/components/schemas/" + name + "Event"},
                      "bindings": {"kafka": {"key": {"type": "string", "description": f"Khóa phân vùng: `{key}`."}}}, "examples": [{"name": "vi-du", "payload": ex}]}
        ch[name] = {"address": addr, "title": code, "description": f"{core}. Bên tiêu thụ: {who}.", "messages": {name: {"$ref": "#/components/messages/" + name}},
                    "parameters": {"tenant": {"$ref": "#/components/parameters/tenant"}},
                    "bindings": {"kafka": {"topic": addr, "partitions": 3, "replicas": 3, "topicConfiguration": {"cleanup.policy": ["delete"], "retention.ms": 604800000, "min.insync.replicas": 2}}}}
        act = "receive" if code in RECEIVE else "send"
        ops[act + name[0].upper() + name[1:]] = {"action": act, "channel": {"$ref": "#/channels/" + name}, "title": code,
                                                 "summary": ("`dh-platform` nhận " if act == "receive" else "`dh-platform` phát ") + code, "messages": [{"$ref": "#/channels/%s/messages/%s" % (name, name)}]}
    schemas.update(envs)
    return {"asyncapi": "3.0.0", "info": {"title": "Datahub PH-11 Quy trình liên thông: sự kiện", "version": "1.0.0-draft",
            "description": "Hợp đồng sự kiện EVT-11-01…21 (D03-04-PH11 §4, FRS 9.3). Ghi vào `ph11_bpm.outbox_event` cùng giao dịch nghiệp vụ (ADR-042), bộ chuyển outbox đưa lên Kafka; CloudEvents 1.0 dạng cấu trúc, khóa phân vùng `businessKey` giữ thứ tự theo hồ sơ. "
                           "Không sự kiện nào mang giá trị biến. EVT-11-17 là lệnh tới PH-04 (ADR 112, PH-11 không gọi HTTT trực tiếp); EVT-11-18, 19 do PH-04 phát, PH-11 tiêu thụ và tương quan theo `commandId`. "
                           "Tương thích BACKWARD: chỉ thêm trường tùy chọn trong `v1` (ADR-070). Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`.",
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
    txt = "# D03-04-PH11 · AsyncAPI PH-11. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n" + yaml.dump(d, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160)
    open(OUT, "w", encoding="utf-8").write(txt)
    print("kênh:", len(d["channels"]), "operation:", len(d["operations"]), "->", OUT)
