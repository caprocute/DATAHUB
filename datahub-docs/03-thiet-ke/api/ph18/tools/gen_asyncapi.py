#!/usr/bin/env python3
"""Sinh ../asyncapi-ops.yaml (AsyncAPI 3.0) cho PH-18: 29 sự kiện phát EVT-18-01…29 (FRS §9.3a) và các kênh tiêu thụ chính
(FRS §9.3b): topic DLQ chung `{tenant}.ops.dlq.v1`, sự kiện PH-10, PH-13 liên quan DLQ, cắt chuyển, sự cố, sự kiện nền tảng PH-20.
Topic `{tenant}.ops.<tên>.v1`, phát qua outbox (ADR-042), phong bì CloudEvents, khóa phân vùng theo cột "Khóa" của FRS.
Dữ liệu sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm; không mang payload, giá trị tham số ★ hay địa chỉ người nhận (BR-18-050).
Chạy từ thư mục tools: python3 gen_asyncapi.py"""
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsl18  # noqa: E402
import gen_openapi as G  # noqa: E402

FRS = G.FRS
SEC = FRS[FRS.index('### 9.3. Sự kiện'):FRS.index('### 9.4.')]
ROWS = re.findall(r'^\| (EVT-18-\d{2}) \| `([^`]+)` \| `([^`]+)` \| ([^|]+?) \| ([^|]+?) \| ([^|]+?) \|$', SEC, re.M)
assert len(ROWS) == 29, len(ROWS)

D = {
    1: 'ns!:s, key!:pkey, version!:i, scope!:e(PLATFORM|TENANT), changeType!:e(VALUE_CHANGED|SCHEMA_CHANGED|FLAG_CHANGED|EGRESS_CHANGED), changedBy!:s, secure!:b',
    2: 'requestId!:u, key!:pkey, requestedBy!:s, approvalOwner!:ph',
    3: 'flagKey!:fkey, enabled!:b, owner!:s, retireBy:d',
    4: 'entryId!:u, host!:s, port!:i, purpose!:#EgressPurpose, action!:e(ADDED|REMOVED|EXPIRED), expiresAt:d',
    5: 'sourceCode!:scode, count!:i, poisonCount!:i, windowStart!:ts',
    6: 'dlqId!:u, sourceCode!:scode, missingFields!:[s], errorCode:s',
    7: 'dlqId!:u, from:#DlqStatus, to!:#DlqStatus, reasonCode:s, actor!:s',
    8: 'sourceCode!:scode, type!:e(DEPTH|AGE|POISON_RATE|REPLAY_FAILURE_RATE|RECONCILE_MISSING), value!:n, threshold!:n',
    9: 'dlqId!:u, revision!:i, idempotencyKey!:ikey, jobId:u, payloadRef!:s, sourceCode!:scode, flow:s',
    10: 'jobId!:u, from:#ReplayJobStatus, to!:#ReplayJobStatus, total!:i, succeeded!:i, failed!:i',
    11: 'errorCode!:err, version!:i, owner!:ph',
    12: 'recipientRef!:#RecipientRef, bounceType!:e(HARD|SOFT|COMPLAINT), suppressed!:b, channel:e(EMAIL|SMS)',
    13: 'notificationId!:u, templateCode!:tcode, channel!:#Channel, errorCode!:s, callerPh!:ph',
    14: 'taskId!:u, type!:ttype, sourceRef!:s, from:#TaskStatus, to!:#TaskStatus, assignee:s',
    15: 'year!:i, calendarScope!:e(COMMON|TENANT), version!:i',
    16: 'windowId!:u, kind!:e(MAINTENANCE|FREEZE), envs!:[#Environment], start!:ts, end!:ts, state!:e(PLANNED|ACTIVE|COMPLETED|CANCELLED)',
    17: 'incidentId!:u, severity!:#Severity, sourceRef:s, hasPersonalData!:b',
    18: 'incidentId!:u, from:#IncidentStatus, to!:#IncidentStatus, severity!:#Severity',
    19: 'objectRef!:s, tool!:#BackupTool, lastSuccessAt:ts, reason!:s',
    20: 'objectRef!:s, result!:e(PASSED|FAILED), rowCountDiff:i, durationSec!:i',
    21: 'restoreId!:u, step:i, from:#RestoreStatus, to!:#RestoreStatus, pointInTime!:ts',
    22: 'restoreId!:u, pointInTime!:ts, scope!:e(FULL_TENANT|MODULES), modules:[s], completedAt!:ts',
    23: 'exportId!:u, result!:#JobStatus, sizeBytes:i, manifestSha256:hash',
    24: 'mergePlanId!:mpid, module!:ph, from:#JobStatus, to!:#JobStatus, rows:i, dryRun!:b',
    25: 'runId!:u, planCode!:s, mode!:#RunMode, result!:#MigrationRunStatus, read!:i, written!:i, rejected!:i',
    26: 'systemCode!:s, credentialType!:#CredentialKind, count!:i, runId!:u',
    27: 'groupCode!:s, from:#CutoverStatus, to!:#CutoverStatus, routes!:[s], rollbackUntil:ts, trafficPercent:i',
    28: 'period!:s, reportId!:u, metrics!:#ReportMetrics',
    29: 'component!:s, from:#HealthState, to!:#HealthState, readOnly!:b',
}
EXTRA_SCH = {'ReportMetrics': 'dlqOpen!:i, dlqResolved!:i, replaySuccessPercent:n, backupFreshPercent:n, restoreVerificationsPassed:i, incidentsOpened!:i, incidentsClosed!:i, '
                              'migrationRuns:i, notificationsSent:i'}
TS = '2026-11-27T09:15:02+07:00'
U = '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a2b'
EXD = {
    1: {'ns': '18.', 'key': '18.dlq.replay.batch-max', 'version': 5, 'scope': 'TENANT', 'changeType': 'VALUE_CHANGED', 'changedBy': 'nguyen.van.an', 'secure': False},
    7: {'dlqId': U, 'from': 'REPLAYING', 'to': 'RESOLVED', 'reasonCode': 'REPLAY_SUCCEEDED', 'actor': 'svc-ops'},
    8: {'sourceCode': 'ph04-runtime', 'type': 'DEPTH', 'value': 1240, 'threshold': 1000},
    9: {'dlqId': U, 'revision': 1, 'idempotencyKey': U + ':1', 'jobId': '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1a3c',
        'payloadRef': '/ops/internal/v1/dlq/messages/%s?includePayload=true' % U, 'sourceCode': 'ph04-runtime', 'flow': 'hs-mot-cua-dong-bo'},
    16: {'windowId': U, 'kind': 'FREEZE', 'envs': ['PROD'], 'start': '2026-12-20T00:00:00+07:00', 'end': '2027-01-03T00:00:00+07:00', 'state': 'PLANNED'},
    22: {'restoreId': U, 'pointInTime': '2026-11-26T08:00:00+07:00', 'scope': 'FULL_TENANT', 'completedAt': TS},
    24: {'mergePlanId': 'SN-2026-001', 'module': 'PH-01', 'from': 'RUNNING', 'to': 'SUCCEEDED', 'rows': 18240, 'dryRun': False},
    27: {'groupCode': 'NHOM-HO-TICH', 'from': 'SHADOW_OK', 'to': 'PARTIAL_CUTOVER', 'routes': ['/api/ho-tich/v1/khai-sinh'], 'rollbackUntil': '2026-11-27T09:30:02+07:00',
         'trafficPercent': 20},
}
# kênh tiêu thụ chính (FRS §9.3b); mã sự kiện của PH-20 sẽ theo D03-04-PH20
CONSUME = [
    ('opsDlq', '{tenant}.ops.dlq.v1', 'Topic DLQ hạ tầng: PH-18 là chủ topic; nguồn ghi bản tin lỗi kèm header ngữ cảnh (bảng 4.1b), PH-18 là bên tiêu thụ duy nhất (FR-18-013)', 'Mọi nguồn (PH-04 runtime và nguồn khác)', 'DlqRecord'),
    ('eventDeadLettered', '{tenant}.event.delivery.dead-lettered.v1', 'EVT-10-11: có mục DLQ tầng sự kiện mới (gộp 1 phút); PH-18 hiển thị chung (FR-18-017)', 'PH-10', 'Ext'),
    ('eventReplayCompleted', '{tenant}.event.replay.completed.v1', 'EVT-10-12: lượt phát lại của PH-10 kết thúc; cập nhật kết quả đề nghị (FR-18-030)', 'PH-10', 'Ext'),
    ('eventMigrationCutOver', '{tenant}.event.migration.cut-over.v1', 'EVT-10-15: ánh xạ di trú chuyển hẳn hoặc quay lui (FR-18-066)', 'PH-10', 'Ext'),
    ('eventBridgeStateChanged', '{tenant}.event.bridge.state-changed.v1', 'EVT-10-16: cầu nối di trú đổi trạng thái (FR-18-066)', 'PH-10', 'Ext'),
    ('obsSecurityAlertRaised', '{tenant}.obs.security-alert.raised.v1', 'EVT-13-04: cảnh báo an ninh, mở sự cố (FR-18-047)', 'PH-13', 'Ext'),
    ('obsAuditChainBroken', '{tenant}.obs.audit.chain-broken.v1', 'EVT-13-05: đứt chuỗi kiểm toán, mở sự cố (FR-18-047)', 'PH-13', 'Ext'),
    ('platformTenantCreated', 'platform.tenant.created.v1', 'PH-20: tenant được tạo; ghi tham số mặc định, lịch mặc định, mẫu thông báo mặc định (FR-18-011, 045)', 'PH-20', 'Ext'),
    ('platformTenantStatusChanged', 'platform.tenant.status-changed.v1', 'PH-20: tenant đổi trạng thái; dừng tác vụ nền khi `SUSPENDED`, điều kiện khôi phục (FR-18-036, 055, 072)', 'PH-20', 'Ext'),
    ('platformTenantMergeStarted', 'platform.tenant.merge-started.v1', 'PH-20: bắt đầu sáp nhập; khóa tác vụ nặng khác của hai tenant (FR-18-057)', 'PH-20', 'Ext'),
    ('platformTenantExportReady', 'platform.tenant.export-ready.v1', 'PH-20: gói xuất sẵn sàng khi ngừng tenant; đối chiếu với gói của PH-18 (FR-18-056)', 'PH-20', 'Ext'),
    ('platformReleasePublished', 'platform.release.published.v1', 'PH-20: phát hành mới; thông báo và tạo cửa sổ bảo trì (FR-18-036, 046)', 'PH-20', 'Ext'),
    ('platformTenantUpgradeChanged', 'platform.tenant.upgrade-changed.v1', 'PH-20: lịch nâng cấp tenant đổi; cập nhật cửa sổ bảo trì (FR-18-046)', 'PH-20', 'Ext'),
]
DLQ_HEADERS = [('dh-tenant', True, 'Mã tenant, khớp tiền tố topic'), ('dh-source-ph', True, 'Phân hệ nguồn, ví dụ `PH-04`'),
               ('dh-dlq-reason', True, 'Lý do ngắn, ví dụ `TARGET_UNAVAILABLE`'), ('dh-dlq-error-code', True, 'Mã ERR của nguồn'),
               ('dh-dlq-stage', True, 'Bước lỗi trong luồng'), ('dh-dlq-attempts', True, 'Số lần nguồn đã thử (chuỗi số)'),
               ('dh-flow', False, 'Bắt buộc với nguồn `KAFKA_TOPIC`: mã luồng để phát lại đúng lối vào'), ('dh-version', False, 'Bắt buộc với nguồn `KAFKA_TOPIC`: phiên bản luồng'),
               ('traceparent', False, 'W3C Trace Context để lấy chẩn đoán PH-13'), ('dh-message-id', False, 'Định danh bản tin gốc để khử trùng')]


def camel(topic):
    parts = re.split(r'[.\-]', topic)
    return parts[0] + ''.join(p.capitalize() for p in parts[1:])


def envelope(data_ref, source, type_const=None):
    p = {'specversion': {'type': 'string', 'const': '1.0'}, 'id': {'type': 'string', 'format': 'uuid', 'description': '`eventId`; bên tiêu thụ khử trùng theo giá trị này (inbox).'},
         'source': {'type': 'string', 'const': source} if source else {'type': 'string'}, 'type': {'type': 'string', **({'const': type_const} if type_const else {})},
         'time': {'type': 'string', 'format': 'date-time'}, 'subject': {'type': 'string'}, 'datacontenttype': {'type': 'string', 'const': 'application/json'},
         'tenantid': {'type': 'string', 'pattern': '^T[0-9]{2}$'}, 'traceparent': {'type': 'string'}, 'data': data_ref}
    return {'type': 'object', 'required': ['specversion', 'id', 'source', 'type', 'time', 'data'], 'properties': p}


def build():
    schemas, messages, channels, ops = {}, {}, {}, {}
    for code, topic, key, fields, cons, fr in ROWS:
        n = int(code[-2:])
        short = topic.split('.ops.')[1].rsplit('.v1', 1)[0]
        name = 'ops' + camel(short)[0].upper() + camel(short)[1:]
        up = name[0].upper() + name[1:]
        schemas[up + 'Data'] = dsl18.obj(D[n])
        env = envelope({'$ref': '#/components/schemas/' + up + 'Data'}, '/dh-platform/ops', topic.replace('{tenant}.', ''))
        env['required'].append('tenantid')
        schemas[up] = env
        msg = {'name': up, 'title': fields.strip()[:120], 'summary': 'FR-18-%s' % fr.strip(), 'contentType': 'application/cloudevents+json',
               'payload': {'$ref': '#/components/schemas/' + up},
               'bindings': {'kafka': {'key': {'type': 'string', 'description': 'Khóa phân vùng `%s`' % key}, 'bindingVersion': '0.5.0'}}}
        if n in EXD:
            msg['examples'] = [{'name': 'viDu', 'payload': {'specversion': '1.0', 'id': '0190a1b2-c3d4-7e5f-8a6b-7c8d9e0f1b%02d' % n, 'source': '/dh-platform/ops',
                                                           'type': topic.replace('{tenant}.', ''), 'time': TS, 'tenantid': 'T68', 'data': EXD[n]}}]
        messages[up] = msg
        channels[name] = {'address': topic, 'title': '%s · %s' % (code, short), 'description': 'Bên nhận: %s.' % cons.strip(),
                          'parameters': {'tenant': {'description': 'Mã tenant dạng chữ thường, ví dụ `t68`.'}},
                          'messages': {up: {'$ref': '#/components/messages/' + up}}, 'x-datahub-id': code, 'x-datahub-consumers': cons.strip(),
                          'x-datahub-partition-key': key, 'x-datahub-fr': ['FR-18-' + x for x in re.findall(r'\d{3}', fr)]}
        ops['send' + up] = {'action': 'send', 'channel': {'$ref': '#/channels/' + name}, 'summary': 'Phát %s' % code, 'description': 'PH-18 phát qua outbox khi %s; bên nhận %s.' % (short, cons.strip()),
                            'messages': [{'$ref': '#/channels/%s/messages/%s' % (name, up)}], 'x-datahub-id': code}
    schemas['ExternalEvent'] = envelope({'type': 'object', 'additionalProperties': True, 'description': 'Dữ liệu theo hợp đồng của phân hệ phát; PH-18 chỉ đọc mã, trạng thái.'}, None)
    schemas['DlqRecordHeaders'] = {'type': 'object', 'required': [h for h, r, _ in DLQ_HEADERS if r],
                                   'properties': {h: {'type': 'string', 'description': d} for h, _, d in DLQ_HEADERS}}
    schemas['DlqRecordPayload'] = {'description': 'Thân bản tin gốc không sửa (JSON hoặc nhị phân); > `18.dlq.payload.inline-max-kb` thì PH-18 lưu ở Garage `dh-{tenant}-ops`.'}
    messages['DlqRecord'] = {'name': 'DlqRecord', 'title': 'Bản tin lỗi kèm header ngữ cảnh chuẩn (FRS bảng 4.1b)', 'contentType': 'application/octet-stream',
                             'headers': {'$ref': '#/components/schemas/DlqRecordHeaders'}, 'payload': {'$ref': '#/components/schemas/DlqRecordPayload'},
                             'bindings': {'kafka': {'key': {'type': 'string', 'description': 'Khóa `dh-source-ph:dh-flow`; 6 phân vùng, giữ 7 ngày.'}, 'bindingVersion': '0.5.0'}}}
    messages['ExternalEvent'] = {'name': 'ExternalEvent', 'title': 'Sự kiện của phân hệ khác (phong bì CloudEvents)', 'contentType': 'application/cloudevents+json',
                                 'payload': {'$ref': '#/components/schemas/ExternalEvent'}}
    for name, addr, desc, src, kind in CONSUME:
        mk = 'DlqRecord' if kind == 'DlqRecord' else 'ExternalEvent'
        ch = {'address': addr, 'title': 'Tiêu thụ · ' + addr.replace('{tenant}.', ''), 'description': desc + '. Bên phát: %s. Inbox khử trùng theo `eventId`; lỗi xử lý ghi ERR-18-124 '
              'và vào DLQ của chính PH-18 (nguồn `PH18_INBOX`).' % src,
              'messages': {mk: {'$ref': '#/components/messages/' + mk}}, 'x-datahub-producer': src}
        if '{tenant}' in addr:
            ch['parameters'] = {'tenant': {'description': 'Mã tenant dạng chữ thường, ví dụ `t68`.'}}
        channels[name] = ch
        ops['receive' + name[0].upper() + name[1:]] = {'action': 'receive', 'channel': {'$ref': '#/channels/' + name}, 'summary': 'Tiêu thụ ' + addr, 'description': desc + '.',
                                                        'messages': [{'$ref': '#/channels/%s/messages/%s' % (name, mk)}]}
    for k, sp in EXTRA_SCH.items():
        schemas[k] = dsl18.obj(sp)

    def refs(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k == '$ref' and isinstance(v, str) and v.startswith('#/components/schemas/'):
                    yield v.split('/')[-1]
                else:
                    yield from refs(v)
        elif isinstance(o, list):
            for v in o:
                yield from refs(v)
    full = G.SCH
    todo = True
    while todo:
        todo = False
        for nm in set(refs(schemas)):
            if nm not in schemas:
                schemas[nm] = full[nm]
                todo = True
    return channels, ops, messages, schemas


def main():
    channels, ops, messages, schemas = build()
    d = {'asyncapi': '3.0.0',
         'info': {'title': 'Datahub · PH-18 Sự kiện vận hành và xử lý lỗi', 'version': '1.0.0-draft',
                  'description': ('Sự kiện của PH-18 (EVT-18-01…29) phát từ bảng `outbox_event` qua Debezium Outbox Event Router; phong bì CloudEvents 1.0, khóa phân vùng theo FRS §9.3, '
                                  'bên tiêu thụ khử trùng theo `eventId`. Dữ liệu chỉ mang mã, trạng thái, số đếm, thời điểm; không payload DLQ, không giá trị tham số ★, '
                                  'không địa chỉ người nhận (BR-18-050). Kèm các kênh PH-18 tiêu thụ: topic DLQ chung `{tenant}.ops.dlq.v1` và sự kiện của PH-10, PH-13, PH-20. '
                                  'Tệp sinh bởi `tools/gen_asyncapi.py`; không sửa tay.'),
                  'contact': {'name': 'Nhóm phân hệ PH-18'}, 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)'},
                  'x-datahub-document': 'D03-04-PH18'},
         'servers': {'kafka': {'host': 'kafka.dh-kafka.svc:9093', 'protocol': 'kafka-secure', 'description': 'Cụm Kafka KRaft của nền tảng (mTLS, ACL theo tenant).'}},
         'defaultContentType': 'application/cloudevents+json', 'channels': channels, 'operations': ops, 'components': {'messages': messages, 'schemas': schemas}}
    out = os.path.join(HERE, '..', 'asyncapi-ops.yaml')
    open(out, 'w', encoding='utf-8').write('# D03-04-PH18 · AsyncAPI PH-18. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay.\n' + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    nsend = sum(1 for o in ops.values() if o['action'] == 'send')
    print('ghi', out, len(channels), 'kênh (%d phát, %d nhận)' % (nsend, len(channels) - nsend))


if __name__ == '__main__':
    main()
