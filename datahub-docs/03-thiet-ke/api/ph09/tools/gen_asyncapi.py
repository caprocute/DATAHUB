#!/usr/bin/env python3
"""Sinh ../asyncapi-privacy.yaml (AsyncAPI 3.0) cho PH-09: EVT-09-01…32 (FRS §9.3) cộng `audit.recorded.v1`.
Topic `{tenant}.privacy.<tên>.v1`, phát qua outbox (ADR-042), phong bì CloudEvents, khóa phân vùng `tenantId`.
Dữ liệu sự kiện chỉ mang mã, trạng thái, số lượng, băm chủ thể; không có giá trị DLCN (BR-09-025).
Chạy từ thư mục tools: python3 gen_asyncapi.py"""
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import schemas09 as S9  # noqa: E402
import gen_openapi as G  # noqa: E402  (dùng lại enum đọc từ Phụ lục A)

FRS = G.FRS
ROWS = re.findall(r'^\| (EVT-09-\d{2}) \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \|$', FRS[FRS.index('### 9.3. Sự kiện'):FRS.index('### 9.4.')], re.M)
assert len(ROWS) == 32, len(ROWS)

D = {
    1: 'elementId!:u, target!:s, fromClass:#DataClass, toClass!:#DataClass, personalDataType:#PersonalDataType, downgrade!:b, contractIds:[s]',
    2: 'scanId!:u, status!:#ScanStatus, suspectCount!:i',
    3: 'contractKind!:#ContractKind, contractId!:s, fromClass:#DataClass, toClass!:#DataClass, blocked!:b',
    4: 'activityId!:u, code!:code, versionNo!:i, status!:#VersionStatus',
    5: 'requestId!:u, htttId!:s, purposeCode!:code, contractId!:s, ownerOrgId!:s, dueAt!:ts',
    6: 'grantId!:u, htttId!:s, purposeCode!:code, contractKind!:#ContractKind, contractId!:s, validUntil!:ts, change!:e(APPROVED|AMENDED|RENEWED)',
    7: 'grantId!:u, htttId!:s, purposeCode!:code, status!:#GrantStatus',
    8: 'grantId!:u, htttId!:s, purposeCode!:code, contractId!:s, revokedAt!:ts',
    9: 'grantId!:u, htttId!:s, purposeCode!:code, expiredAt!:ts',
    10: 'grantId!:u, htttId!:s, purposeCode!:code, validUntil!:ts, daysLeft!:i',
    11: 'bundleNo!:i, objectRef!:s, sha256!:s, validUntil!:ts, trigger!:e(AUTO|MANUAL|ROLLBACK)',
    12: 'policyId!:u, code!:code, versionNo!:i, scope!:#MaskPolicyScope, contractId:s',
    13: 'anomalyId!:u, anomalyType!:#AnomalyType, htttId!:s, purposeCode:code',
    14: 'targetKind!:#TargetKind, targetId!:s, label!:#BlockLabel, detectedBy!:e(SCAN|PEP|ASSIGN)',
    15: 'grantId!:u, requestedBy!:s, elementId!:u, expiresAt!:ts',
    16: 'domainCode!:code, keyVersion!:i, from:#KeyVersionStatus, to!:#KeyVersionStatus',
    17: 'requestId!:u, domainCode!:code, tokenCount!:i, executedBy!:s',
    18: 'datasetId!:u, status!:#DatasetStatus',
    19: 'taskId!:u, tableName!:s, action!:#RetentionAction, status!:#RetentionTaskStatus, rowsProcessed!:i, rowsSkippedHold!:i',
    20: 'holdId!:u, status!:#LegalHoldStatus',
    21: 'requestId!:u, executedAt!:ts',
    22: 'requestId!:u, requestType!:#DsrType, channel!:#DsrChannel, subjectHash!:hash, dueAt!:ts',
    23: 'requestId!:u, requestType!:#DsrType, dueAt!:ts, daysLeft!:i',
    24: 'requestId!:u, requestType!:#DsrType, dueAt!:ts, overdueDays!:i',
    25: 'requestId!:u, outcome!:#DsrOutcome, closedAt!:ts',
    26: 'requestId!:u, subjectHash!:hash, restrictionActive!:b',
    27: 'consentId!:u, templateCode!:code, templateVersion!:i, subjectHash!:hash, channel!:#ConsentChannel',
    28: 'consentId!:u, templateCode!:code, subjectHash!:hash, withdrawnAt!:ts',
    29: 'dpiaId!:u, dpiaCode!:code, reviewOn!:d',
    30: 'breachId!:u, detectedAt!:ts, deadlineAt!:ts, source!:#BreachSource, estimatedSubjects:i',
    31: 'breachId!:u, deadlineAt!:ts, remainingHours!:i, level!:e(WARN_24|WARN_48|WARN_60)',
    32: 'breachId!:u, recipient!:#NotificationRecipient, sentAt!:ts',
}
AUDIT = 'eventId!:u, occurredAt!:ts, actor!:s, action!:s, targetType!:s, targetId:s, outcome!:e(SUCCESS|DENIED|FAILED), purposeCode:code, traceId:s'
U1 = '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b'
TS = '2026-11-26T09:15:02+07:00'
H = G.H
EXD = {
    1: {'elementId': U1, 'target': 'ho-so.so-cccd', 'fromClass': 'RESTRICTED', 'toClass': 'SENSITIVE', 'personalDataType': 'SENSITIVE', 'downgrade': False, 'contractIds': ['api-tra-cuu-ho-so-v1']},
    8: {'grantId': U1, 'htttId': 'httt-so-yte', 'purposeCode': 'TRA-CUU-BHYT', 'contractId': 'api-tra-cuu-bhyt-v1', 'revokedAt': TS},
    11: {'bundleNo': 412, 'objectRef': 'garage://dh-t68-privacy/bundles/412.tar.gz', 'sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'validUntil': '2026-11-26T10:15:02+07:00', 'trigger': 'AUTO'},
    22: {'requestId': U1, 'requestType': 'ACCESS', 'channel': 'COUNTER', 'subjectHash': H, 'dueAt': '2026-12-10T17:00:00+07:00'},
    30: {'breachId': U1, 'detectedAt': '2026-11-26T08:40:00+07:00', 'deadlineAt': '2026-11-29T08:40:00+07:00', 'source': 'INCIDENT_PH18', 'estimatedSubjects': 120},
}


def camel(topic):
    parts = re.split(r'[.\-]', topic)
    return parts[0] + ''.join(p.capitalize() for p in parts[1:])


def build():
    schemas, messages, channels, ops = {}, {}, {}, {}
    used = set()

    def reg(name, spec):
        sc = S9.obj(spec)
        for p in G.walk_refs(sc) if hasattr(G, 'walk_refs') else []:
            used.add(p)
        schemas[name] = sc
        return sc
    items = [(int(c[-2:]), c, t, w, cons) for c, t, w, cons in ROWS] + [(33, 'audit.recorded', '{tenant}.privacy.audit.recorded.v1', 'Bản ghi kiểm toán bảo vệ dữ liệu được ghi (chuyển PH-13)', 'PH-13')]
    for n, code, topic, when, cons in items:
        short = topic.split('.privacy.')[1].rsplit('.v1', 1)[0]
        name = camel(short)
        spec = D.get(n, AUDIT)
        data_name = name[0].upper() + name[1:] + 'Data'
        reg(data_name, spec)
        ce_name = name[0].upper() + name[1:]
        ce = {'type': 'object', 'required': ['specversion', 'id', 'source', 'type', 'time', 'tenantid', 'data'],
              'properties': {'specversion': {'const': '1.0'}, 'id': {'type': 'string', 'format': 'uuid', 'description': '`eventId`; bên tiêu thụ khử trùng theo giá trị này (inbox).'},
                             'source': {'type': 'string', 'const': '/dh-data/privacy'}, 'type': {'type': 'string', 'const': topic.replace('{tenant}', 'TENANT')},
                             'time': {'type': 'string', 'format': 'date-time'}, 'subject': {'type': 'string'}, 'datacontenttype': {'const': 'application/json'},
                             'tenantid': {'type': 'string', 'pattern': '^T[0-9]{2}$', 'description': 'Khóa phân vùng Kafka.'},
                             'traceparent': {'type': 'string'}, 'data': {'$ref': '#/components/schemas/' + data_name}}}
        schemas[ce_name] = ce
        msg = {'name': ce_name, 'title': when, 'contentType': 'application/cloudevents+json', 'payload': {'$ref': '#/components/schemas/' + ce_name},
               'bindings': {'kafka': {'key': {'type': 'string', 'description': '`tenantId`'}}}}
        if n in EXD:
            msg['examples'] = [{'payload': {'specversion': '1.0', 'id': '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1b01', 'source': '/dh-data/privacy', 'type': topic.replace('{tenant}', 't68'),
                                           'time': TS, 'tenantid': 'T68', 'data': EXD[n]}}]
        messages[ce_name] = msg
        channels[name] = {'address': topic, 'title': when, 'description': 'Bên tiêu thụ: %s.' % cons, 'parameters': {'tenant': {'description': 'Mã tenant dạng chữ thường, ví dụ `t68`.'}},
                          'messages': {ce_name: {'$ref': '#/components/messages/' + ce_name}}, 'x-datahub-id': code if n <= 32 else 'audit.recorded',
                          'x-datahub-consumers': cons}
        ops['send' + ce_name] = {'action': 'send', 'channel': {'$ref': '#/channels/' + name}, 'summary': when, 'messages': [{'$ref': '#/channels/%s/messages/%s' % (name, ce_name)}],
                                 'x-datahub-id': code if n <= 32 else 'audit.recorded'}
    # enum dùng trong payload
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
    need = set(refs(schemas))
    full = S9.build_schemas(G.ENUMS)
    for nm in need:
        if nm not in schemas:
            schemas[nm] = full[nm]
    return channels, ops, messages, schemas


def main():
    channels, ops, messages, schemas = build()
    d = {'asyncapi': '3.0.0',
         'info': {'title': 'Datahub · PH-09 Sự kiện quyền riêng tư', 'version': '1.0.0-draft',
                  'description': ('Sự kiện của PH-09 (EVT-09-01…32 cộng `audit.recorded.v1`) phát từ bảng `outbox_event` qua Debezium Outbox Event Router; phong bì CloudEvents 1.0, khóa phân vùng `tenantId`, '
                                  'bên tiêu thụ khử trùng theo `eventId`. Dữ liệu sự kiện chỉ mang mã, trạng thái, số lượng và băm chủ thể, không có giá trị DLCN (BR-09-025). Tệp sinh bởi `tools/gen_asyncapi.py`; không sửa tay.'),
                  'x-datahub-document': 'D03-04-PH09'},
         'servers': {'kafka': {'host': 'kafka.dh-kafka.svc:9093', 'protocol': 'kafka-secure', 'description': 'Cụm Kafka KRaft của nền tảng (mTLS, ACL theo tenant).'}},
         'defaultContentType': 'application/cloudevents+json', 'channels': channels, 'operations': ops, 'components': {'messages': messages, 'schemas': schemas}}
    out = os.path.join(HERE, '..', 'asyncapi-privacy.yaml')
    open(out, 'w', encoding='utf-8').write('# D03-04-PH09 · AsyncAPI PH-09. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay.\n' + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    print('ghi', out, len(channels), 'kênh')


if __name__ == '__main__':
    main()
