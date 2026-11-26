#!/usr/bin/env python3
"""Sinh ../asyncapi-assist.yaml (AsyncAPI 3.0) cho PH-17: EVT-17-01…28 (FRS §9.3).
Topic `{tenant}.assist.<tên>.v1`, phát qua outbox (ADR-042), phong bì CloudEvents, khóa phân vùng `tenantId`.
Dữ liệu sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm; không có nội dung hội thoại, đoạn tri thức hay giá trị dữ liệu (BR-17-022, 073).
Chạy từ thư mục tools: python3 gen_asyncapi.py"""
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsl17  # noqa: E402
import gen_openapi as G  # noqa: E402

FRS = G.FRS
ROWS = re.findall(r'^\| (EVT-17-\d{2}) \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \|$', FRS[FRS.index('### 9.3. Sự kiện'):FRS.index('### 9.4.')], re.M)
assert len(ROWS) == 28, len(ROWS)

D = {
    1: 'changeKind!:e(POLICY|CAPABILITY|QUOTA|SETTING|PROVIDER_GRANT|TOOL|GUARDRAIL), settingKey:s, changedBy!:s, version!:i',
    2: 'state!:#TenantAssistState, changeId:u, decidedBy:s, capabilities:[#Capability]',
    3: 'scope!:#KillScope, active!:b, recordId!:u, activatedBy:s, releasedBy:s',
    4: 'changeId!:u, changeType!:#PolicyChangeType, state!:e(APPROVED|REJECTED), requestedBy!:s, decidedBy!:s',
    5: 'noticeId!:u, versionNo!:i, publishedAt!:ts',
    6: 'providerId!:u, providerCode!:code, from:#ProviderStatus, to!:#ProviderStatus',
    7: 'versionId!:u, modelId!:u, versionNo!:i, from:#ModelVersionStatus, to!:#ModelVersionStatus, evalRunId:u, redteamRunId:u',
    8: 'runId!:u, versionIds!:[u], requestedBy:s',
    9: 'runId!:u, result!:e(APPLIED|REJECTED), snapshotRef:s, errorCode:s',
    10: 'versionId!:u, from:#HealthState, to!:#HealthState, consecutiveFailures!:i',
    11: 'routeId!:u, versionId!:u, breakerState!:e(CLOSED|HALF_OPEN|OPEN), failureCount!:i',
    12: 'scopeKind!:e(TENANT|USER|DU), threshold!:e(P80|P100), tokensUsed!:i, tokensLimit!:i',
    13: 'sourceId!:u, sourceCode!:code, sourceType!:#SourceType, state!:e(ACTIVE|PAUSED|RETIRED)',
    14: 'jobId!:u, sourceId!:u, chunksAdded!:i, chunksDeleted!:i, chunksSkipped!:i',
    15: 'jobId!:u, sourceId!:u, attempt!:i, errorCode!:s',
    16: 'sourceId:u, documentId:u, reason!:e(SOURCE_DELETED|CLASS_CHANGED|SOURCE_RETIRED|UPLOAD_STOPPED|PURGE|REVOKED), chunksDeleted!:i',
    17: 'documentId!:u, from:#UploadStatus, to!:#UploadStatus, uploadedBy!:s, decidedBy:s',
    18: 'suggestionId!:u, suggestionKind!:#SuggestionKind, status!:#SuggestionStatus, userId!:s',
    19: 'guardrailKind!:#GuardrailKind, ruleCode!:code, action!:#GuardrailAction, category!:s, messageId:u',
    20: 'versionId!:u, templateId!:u, versionNo!:i, from:#PromptVersionStatus, to!:#PromptVersionStatus',
    21: 'runId!:u, subjectType!:s, subjectId:u, status!:#EvalRunStatus, casesTotal!:i, casesPassed!:i, score:n',
    22: 'runId!:u, subjectType!:s, subjectId:u, status!:#EvalRunStatus, casesTotal!:i, casesLeaked!:i',
    23: 'feedbackId!:u, feedbackKind!:#FeedbackKind, status!:#FeedbackStatus, messageId!:u',
    24: 'metricCode!:s, capability:#Capability, metricValue!:n, threshold!:n, raisedAt!:ts',
    25: 'grantId!:u, grantee!:s, scopeKind!:e(CONVERSATION|RANGE), expiresAt!:ts',
    26: 'exportId!:u, exportKind!:e(COMPLIANCE_PACK|USAGE_REPORT), state!:#ExportState, sha256:s, expiresAt:ts',
    27: 'purgedConversations!:i, purgedMessages!:i, retentionDays!:i, runAt!:ts',
    28: 'suggestionId!:u, decision!:e(ACCEPTED|EDITED|REJECTED), processRef!:s',
}
U1 = '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b'
TS = '2026-11-26T09:15:02+07:00'
EXD = {
    2: {'state': 'ENABLED', 'changeId': U1, 'decidedBy': 'le.thi.chi', 'capabilities': ['SEARCH']},
    3: {'scope': 'TENANT', 'active': True, 'recordId': U1, 'activatedBy': 'nguyen.van.an'},
    7: {'versionId': U1, 'modelId': '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c', 'versionNo': 2, 'from': 'EVALUATING', 'to': 'APPROVED'},
    14: {'jobId': U1, 'sourceId': '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c', 'chunksAdded': 42, 'chunksDeleted': 3, 'chunksSkipped': 1},
    22: {'runId': U1, 'subjectType': 'MODEL_VERSION', 'status': 'PASSED', 'casesTotal': 50, 'casesLeaked': 0},
    27: {'purgedConversations': 120, 'purgedMessages': 960, 'retentionDays': 90, 'runAt': TS},
}


def camel(topic):
    parts = re.split(r'[.\-]', topic)
    return parts[0] + ''.join(p.capitalize() for p in parts[1:])


def build():
    schemas, messages, channels, ops = {}, {}, {}, {}
    for code, topic, when, cons in ROWS:
        n = int(code[-2:])
        short = topic.split('.assist.')[1].rsplit('.v1', 1)[0]
        name = camel(short)
        up = name[0].upper() + name[1:]
        schemas[up + 'Data'] = dsl17.obj(D[n])
        schemas[up] = {'type': 'object', 'required': ['specversion', 'id', 'source', 'type', 'time', 'tenantid', 'data'],
                       'properties': {'specversion': {'const': '1.0'}, 'id': {'type': 'string', 'format': 'uuid', 'description': '`eventId`; bên tiêu thụ khử trùng theo giá trị này (inbox).'},
                                      'source': {'type': 'string', 'const': '/dh-assist'}, 'type': {'type': 'string', 'const': topic.replace('{tenant}', 'TENANT')},
                                      'time': {'type': 'string', 'format': 'date-time'}, 'subject': {'type': 'string'}, 'datacontenttype': {'const': 'application/json'},
                                      'tenantid': {'type': 'string', 'pattern': '^T[0-9]{2}$', 'description': 'Khóa phân vùng Kafka.'},
                                      'traceparent': {'type': 'string'}, 'data': {'$ref': '#/components/schemas/' + up + 'Data'}}}
        msg = {'name': up, 'title': when, 'contentType': 'application/cloudevents+json', 'payload': {'$ref': '#/components/schemas/' + up},
               'bindings': {'kafka': {'key': {'type': 'string', 'description': '`tenantId`'}}}}
        if n in EXD:
            msg['examples'] = [{'payload': {'specversion': '1.0', 'id': '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1b01', 'source': '/dh-assist', 'type': topic.replace('{tenant}', 't68'),
                                           'time': TS, 'tenantid': 'T68', 'data': EXD[n]}}]
        messages[up] = msg
        channels[name] = {'address': topic, 'title': when, 'description': 'Bên tiêu thụ: %s.' % cons, 'parameters': {'tenant': {'description': 'Mã tenant dạng chữ thường, ví dụ `t68`.'}},
                          'messages': {up: {'$ref': '#/components/messages/' + up}}, 'x-datahub-id': code, 'x-datahub-consumers': cons}
        ops['send' + up] = {'action': 'send', 'channel': {'$ref': '#/channels/' + name}, 'summary': when, 'messages': [{'$ref': '#/channels/%s/messages/%s' % (name, up)}], 'x-datahub-id': code}

    def refs(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k == '$ref' and v.startswith('#/components/schemas/'):
                    yield v.split('/')[-1]
                else:
                    yield from refs(v)
        elif isinstance(o, list):
            for v in o:
                yield from refs(v)
    full = G.SCH
    for nm in set(refs(schemas)):
        if nm not in schemas:
            schemas[nm] = full[nm]
    return channels, ops, messages, schemas


def main():
    channels, ops, messages, schemas = build()
    d = {'asyncapi': '3.0.0',
         'info': {'title': 'Datahub · PH-17 Sự kiện trợ lý AI', 'version': '1.0.0-draft',
                  'description': ('Sự kiện của PH-17 (EVT-17-01…28) phát từ bảng `outbox_event` qua Debezium Outbox Event Router; phong bì CloudEvents 1.0, khóa phân vùng `tenantId`, '
                                  'bên tiêu thụ khử trùng theo `eventId`. Dữ liệu sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm, không có nội dung hội thoại, đoạn tri thức hay giá trị dữ liệu (BR-17-022, 073). '
                                  'Tệp sinh bởi `tools/gen_asyncapi.py`; không sửa tay.'),
                  'x-datahub-document': 'D03-04-PH17'},
         'servers': {'kafka': {'host': 'kafka.dh-kafka.svc:9093', 'protocol': 'kafka-secure', 'description': 'Cụm Kafka KRaft của nền tảng (mTLS, ACL theo tenant).'}},
         'defaultContentType': 'application/cloudevents+json', 'channels': channels, 'operations': ops, 'components': {'messages': messages, 'schemas': schemas}}
    out = os.path.join(HERE, '..', 'asyncapi-assist.yaml')
    open(out, 'w', encoding='utf-8').write('# D03-04-PH17 · AsyncAPI PH-17. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay.\n' + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    print('ghi', out, len(channels), 'kênh')


if __name__ == '__main__':
    main()
