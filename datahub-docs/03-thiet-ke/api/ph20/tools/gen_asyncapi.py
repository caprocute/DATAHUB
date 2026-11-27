#!/usr/bin/env python3
"""Sinh asyncapi-ph20.yaml (AsyncAPI 3.0) cho EVT-20-01…16 (phát) và 6 sự kiện tiêu thụ từ FRS §9.3.
Chạy từ api/ph20:  python3 tools/gen_asyncapi.py     Không sửa tay tệp YAML.
CloudEvents 1.0 chế độ nhị phân trên Kafka: thuộc tính ở tiêu đề `ce_*`, thuộc tính mở rộng `dhtenant` ở tiêu đề `ce_dhtenant`, thân là JSON dữ liệu.
Sự kiện không mang dữ liệu cá nhân (BR-20-039): chỉ mã đối tượng, trạng thái, số đếm."""
import copy
import os
import re
import sys

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsl
from dsl import SCH, obj, enum, ex_of, T0
import schemas1, schemas2  # noqa: F401
import spec_ops
from spec_ops import ROOT
from gen_openapi import NoAlias

OUT = os.path.join(ROOT, 'asyncapi-ph20.yaml')
OPEN = {'additionalProperties': True}

enum('ConfigChangeKind', 'Loại thay đổi cấu hình theo FRS (EVT-20-09).', 'TENANT_PROFILE', 'TENANT_SETTINGS', 'PLATFORM_CONFIG', 'CROSS_TENANT_POLICY', 'ISOLATION_MODE', 'FEATURE_FLAG')
enum('OrgChange', 'Loại thay đổi tổ chức.', 'CREATED', 'UPDATED', 'DEACTIVATED', 'REACTIVATED', 'DISSOLVED', 'MERGED')
enum('ModuleMode', 'Cách tắt phân hệ.', 'DISABLE', 'SUSPEND')
enum('ReleasePublishStatus', 'Trạng thái phiên bản khi công bố.', 'PREVIEW', 'STABLE')
obj('QuotaPair', 'Hạn mức hiệu lực của một tài nguyên.', 'resource!:E:QuotaResource', ('effectiveValue!:num', 800), ('previousValue:num', 500))
obj('RedirectPair', 'Ánh xạ chuyển tiếp.', ('fromPrefix!:str', '/t91'), ('toTenant!:tc', 'T90'), ('toPrefix!:str', '/t90'))

obj('TenantCreatedData', 'Tenant khai báo xong, saga bắt đầu (FR-20-008).', 'tenantCode!:tc', 'tenantId!:uuid', 'isolationMode!:E:IsolationMode', 'scaleProfile:E:ScaleProfile',
    'deploymentProfile:E:DeploymentProfile', 'templateCode:code', ('templateVersion:int', 3), 'runId!:uuid', ('modules!:mod[]', ['PH-03', 'PH-04', 'PH-06', 'PH-10']), ('apiHost:str', 'api.t68.datahub.example.vn'),
    ('apiPrefix:str', '/t68'), ('realm:str', 'dh-t68'), ('kafkaPrefix:str', 't68.'), ('quotas:R:QuotaPair[]', [{'resource': 'API_RPS', 'effectiveValue': 500}]), ex={'isolationMode': 'SHARED'})
obj('ProvisioningFailedData', 'Saga dừng `FAILED`.', 'tenantCode!:tc', 'runId!:uuid', ('failedStep!:E:StepCode', 'S06_EVENTING'), ('errorCode!:str', 'ERR-20-106', {'pattern': '^ERR-20-[0-9]{3}$'}),
    ('errorMessage:str', 'Bước S06_EVENTING chưa nhận báo cáo từ PH-10 sau 15 phút.'), ('attempt:int', 3))
obj('TenantActivatedData', 'Tenant `ACTIVE` (FR-20-013).', 'tenantCode!:tc', 'tenantId!:uuid', 'activatedAt!:ts', 'runId:uuid', 'isolationMode:E:IsolationMode', ('provisionMinutes:num', 47.5), ex={'isolationMode': 'SHARED'})
obj('TenantStatusChangedData', 'Mọi đổi trạng thái tenant (FR-20-038…044, 051, 052).', 'tenantCode!:tc', 'fromStatus!:E:TenantStatus', 'toStatus!:E:TenantStatus', 'requestId:uuid', 'effectiveAt!:ts',
    ('readOnly:bool', False), ('essentialApisAllowed:bool', False), ('mergedInto:tc', 'T90'), ex={'fromStatus': 'ACTIVE', 'toStatus': 'SUSPENDED', 'mergedInto': None})
obj('QuotaChangedData', 'Hạn mức hợp đồng hoặc ghi đè đổi (FR-20-026, 027, 032).', 'tenantCode!:tc', 'items!:R:QuotaPair[]', ('source!:str', 'CONTRACT', {'enum': ['CONTRACT', 'OVERRIDE', 'OVERRIDE_EXPIRED']}),
    'effectiveAt!:ts', ('configVersion:int', 8))
obj('QuotaThresholdReachedData', 'Sử dụng chạm 80% hoặc 100% (FR-20-029).', 'tenantCode!:tc', 'resource!:E:QuotaResource', 'alertLevel!:E:QuotaAlertLevel', 'alertId!:uuid', ('used!:num', 412), ('limit!:num', 500),
    ('percent!:num', 82.4), 'raisedAt!:ts', ex={'alertLevel': 'WARN_80'})
obj('ModuleEnabledData', 'Bật phân hệ cho tenant (FR-20-034, saga bước `S15_MODULES`); phân hệ báo xong qua API-20-166.', 'tenantCode!:tc', 'moduleCode!:mod', 'runId:uuid',
    ('reportPath!:str', '/internal/tenant/v1/provisioning-runs/0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e01/steps/S15_MODULES:report'), ('configVersion:int', 8))
obj('ModuleDisabledData', 'Tắt hoặc tạm ngừng phân hệ (FR-20-035).', 'tenantCode!:tc', 'moduleCode!:mod', 'mode!:E:ModuleMode', 'effectiveAt!:ts', ex={'mode': 'DISABLE'})
obj('ConfigChangedData', 'Cấu hình nền tảng hoặc cài đặt tỉnh đổi (FR-20-018…021, 025).', 'tenantCode!:tc', 'scope!:E:ConfigScope', 'changeKind:E:ConfigChangeKind', ('configVersionNo!:int', 8), 'commitSha:str',
    ('changedKeys:str[]', ['publicHost', 'sessionIdleMinutes']), 'effectiveAt!:ts', ex={'scope': 'SETTINGS', 'changeKind': 'TENANT_SETTINGS'})
obj('MergeStartedData', 'Sáp nhập được duyệt, bắt đầu chuyển dữ liệu (FR-20-048).', 'mergePlanId!:str', ('sourceTenants!:tc[]', ['T91']), ('targetTenant!:tc', 'T90'), ('modules!:mod[]', ['PH-01', 'PH-03']),
    'effectiveDate:date', 'mappingHash:sha')
obj('MergeCutoverData', 'Tenant nguồn `MERGED`, chuyển tiếp bật (FR-20-051).', 'mergePlanId!:str', ('sourceTenants!:tc[]', ['T91']), ('targetTenant!:tc', 'T90'), 'cutoverAt!:ts', 'transitionEndsAt!:ts',
    'redirects!:R:RedirectPair[]', ex={'redirects': [{'fromPrefix': '/t91', 'toTenant': 'T90', 'toPrefix': '/t90'}]})
obj('MergeCompletedData', 'Kết thúc sáp nhập (FR-20-052).', 'mergePlanId!:str', ('sourceTenants!:tc[]', ['T91']), ('targetTenant!:tc', 'T90'), 'completedAt!:ts', ('modulesTransferred:int', 3), ('conflictsResolved:int', 3))
obj('OrgChangedData', 'Tổ chức tạo, sửa, ngừng, giải thể, kế thừa (FR-20-053…056, 058); không chứa thông tin cá nhân.', 'orgCode!:ocode', 'change!:E:OrgChange', 'status!:E:OrgStatus', ('parentCode:ocode', 'UBND-TINH'),
    ('successorCode:ocode', 'SO-TTTT'), ('effectiveFrom:date', '2025-07-01'), 'effectiveTo:date', ('isDataOwner:bool', False), ('version:int', 4),
    ex={'change': 'DISSOLVED', 'status': 'DISSOLVED', 'effectiveTo': '2026-12-31'})
obj('ReleasePublishedData', 'Phiên bản sản phẩm sang `PREVIEW` hoặc `STABLE` (FR-20-060).', 'releaseVersion!:ver', 'status!:E:ReleasePublishStatus', 'channel!:E:ReleaseChannel', ('breakingChange!:bool', False),
    'publishedAt!:ts', ('releaseNotesUrl:url', 'https://nen-tang.datahub.example.vn/phat-hanh/2.4.0'), ex={'status': 'PREVIEW', 'channel': 'PREVIEW'})
obj('UpgradeChangedData', 'Nâng cấp của một tenant đổi trạng thái (FR-20-061, 062).', 'tenantCode!:tc', 'planId!:uuid', ('releaseVersion!:ver', '2.4.0'), ('fromStatus:E:TenantUpgradeStatus', 'IN_WINDOW'),
    ('toStatus!:E:TenantUpgradeStatus', 'UPGRADING'), ('waveNo:int', 1), ('errorCode:str', 'ERR-20-112', {'pattern': '^ERR-20-[0-9]{3}$'}), ('attempt:int', 1), 'at!:ts',
    ex={'errorCode': None})
obj('ExportReadyData', 'Gói bàn giao dữ liệu sẵn sàng (FR-20-041); không kèm liên kết tải.', 'tenantCode!:tc', 'packageId!:uuid', 'requestId:uuid', ('itemCount!:int', 2), ('sizeBytes:int', 96426008),
    'manifestSha256:sha', 'expiresAt:ts')
# tiêu thụ (chỉ trường PH-20 dùng; bên phát giữ hợp đồng gốc)
obj('AdminUnitChange', 'Một thay đổi đơn vị hành chính.', ('oldCode!:str', 'XA-0101'), ('newCode!:str', 'XA-0105'), ('effectiveDate!:date', '2026-12-01'), ('decisionDoc:str', '12/NQ-HĐND'))
obj('AdminUnitReorganizedIn', 'Sắp xếp đơn vị hành chính (EVT-07-10).', ('changes!:R:AdminUnitChange[]', None, {'minItems': 1}), ('catalogVersion:str', '2026.11'), extra=True)
obj('RealmChangedIn', 'Realm đổi trạng thái (EVT-12-13).', ('realmCode!:str', 'dh-t68'), ('status!:str', 'ACTIVE'), ('changedAt:ts',), extra=True)
obj('CryptoShredCompletedIn', 'Xóa mật mã tenant xong (EVT-09-21); không chứa khóa.', 'tenantCode!:tc', ('requestId:uuid',), ('completedAt!:ts',), extra=True)
obj('CapacityWarningIn', 'Cảnh báo dung lượng (EVT-13-14).', ('resource!:str', 'pg-core'), ('level!:str', 'WARN'), ('percent:num', 86.0), extra=True)
obj('TenantRedirectChangedIn', 'Chuyển tiếp lượt gọi bật hoặc tắt (EVT-03-10).', 'tenantCode!:tc', ('fromPrefix:str', '/t91'), ('toTenant:tc', 'T90'), ('enabled!:bool', True), ('changedAt:ts',), extra=True)
obj('LimitChangedIn', 'Hạn mức đã áp ở gateway (EVT-03-11).', 'tenantCode!:tc', 'resource!:E:QuotaResource', ('appliedValue!:num', 800), ('appliedAt:ts',), extra=True)

SEC = '0193a0c3-0000-7000-8000-%012d'
# (mã, kênh, topic, dữ liệu, ce_type hậu tố, khóa phân vùng, bên nhận, mô tả, tenant của tiêu đề)
OUTS = [
    ('EVT-20-01', 'tenantCreated', 'platform.tenant.created.v1', 'TenantCreatedData', 'tenantCode', 'PH-10, PH-03, PH-04, PH-06, PH-13, PH-18', 'Phát sau bước `S05_BUCKETS` của saga khởi tạo (FR-20-008, tenant còn `PROVISIONING`); PH-10, PH-03, PH-04, PH-06 tự khởi tạo phần của mình và báo tiến độ qua API-20-166; PH-18 gieo tham số mặc định.'),
    ('EVT-20-02', 'tenantProvisioningFailed', 'platform.tenant.provisioning-failed.v1', 'ProvisioningFailedData', 'tenantCode', 'PH-13, PH-18', 'Saga dừng `FAILED`; PH-18 mở việc xử lý, PH-13 cảnh báo.'),
    ('EVT-20-03', 'tenantActivated', 'platform.tenant.activated.v1', 'TenantActivatedData', 'tenantCode', 'mọi DU, PH-16', 'Tenant `ACTIVE`; PH-16 ghi nhận thời gian khởi tạo.'),
    ('EVT-20-04', 'tenantStatusChanged', 'platform.tenant.status-changed.v1', 'TenantStatusChangedData', 'tenantCode', 'PH-01, PH-03, PH-04, PH-12, PH-13, PH-18, PH-19', 'Mọi đổi trạng thái tenant (tạm ngừng, khôi phục, `MERGING`, `MERGED`, `DECOMMISSIONED`).'),
    ('EVT-20-05', 'tenantQuotaChanged', 'platform.tenant.quota-changed.v1', 'QuotaChangedData', 'tenantCode', 'PH-03, PH-04, PH-10, PH-12', 'Hạn mức hợp đồng hoặc ghi đè đổi; nơi thực thi xác nhận bằng EVT-03-11.'),
    ('EVT-20-06', 'tenantQuotaThresholdReached', 'platform.tenant.quota-threshold-reached.v1', 'QuotaThresholdReachedData', 'tenantCode', 'PH-13, PH-18', 'Sử dụng chạm 80% hoặc 100% hạn mức.'),
    ('EVT-20-07', 'tenantModuleEnabled', 'platform.tenant.module-enabled.v1', 'ModuleEnabledData', 'tenantCode', 'phân hệ được bật (PH-19, PH-17, PH-11, PH-14, PH-15)', 'Bật phân hệ cho tenant; phân hệ được bật tự khởi tạo rồi báo xong qua API-20-166.'),
    ('EVT-20-08', 'tenantModuleDisabled', 'platform.tenant.module-disabled.v1', 'ModuleDisabledData', 'tenantCode', 'phân hệ bị tắt (PH-19, PH-17, PH-11, PH-14, PH-15)', 'Tắt hoặc tạm ngừng phân hệ cho tenant.'),
    ('EVT-20-09', 'tenantConfigChanged', 'platform.tenant.config-changed.v1', 'ConfigChangedData', 'tenantCode', 'PH-03, PH-12, dh-console', 'Cấu hình nền tảng hoặc cài đặt tỉnh đổi, kèm số phiên bản cấu hình.'),
    ('EVT-20-10', 'tenantMergeStarted', 'platform.tenant.merge-started.v1', 'MergeStartedData', 'mergePlanId', 'phân hệ có dữ liệu, PH-18', 'Sáp nhập được duyệt, bắt đầu chuyển dữ liệu; khóa phân vùng là `mergePlanId`.'),
    ('EVT-20-11', 'tenantMergeCutover', 'platform.tenant.merge-cutover.v1', 'MergeCutoverData', 'mergePlanId', 'PH-03, PH-12, PH-01', 'Tenant nguồn `MERGED`, chuyển tiếp lượt gọi bật.'),
    ('EVT-20-12', 'tenantMergeCompleted', 'platform.tenant.merge-completed.v1', 'MergeCompletedData', 'mergePlanId', 'PH-13, PH-16, PH-03', 'Kết thúc sáp nhập.'),
    ('EVT-20-13', 'orgChanged', '{tenant}.tenant.org.changed.v1', 'OrgChangedData', 'orgCode', 'PH-01, PH-06, PH-07, PH-08, PH-12, PH-16', 'Tổ chức tạo, sửa, ngừng, giải thể, có tổ chức kế thừa; topic theo tiền tố của tenant.'),
    ('EVT-20-14', 'releasePublished', 'platform.release.published.v1', 'ReleasePublishedData', 'releaseVersion', 'PH-18', 'Phiên bản sản phẩm sang `PREVIEW` hoặc `STABLE`; `dhtenant` là `PLATFORM`.'),
    ('EVT-20-15', 'tenantUpgradeChanged', 'platform.tenant.upgrade-changed.v1', 'UpgradeChangedData', 'tenantCode', 'PH-13, PH-18', 'Nâng cấp của một tenant đổi trạng thái.'),
    ('EVT-20-16', 'tenantExportReady', 'platform.tenant.export-ready.v1', 'ExportReadyData', 'tenantCode', 'PH-18', 'Gói bàn giao dữ liệu sẵn sàng; liên kết tải cấp riêng ở API-20-083.'),
]
INS = [
    ('EVT-07-10', 'adminUnitReorganized', 'common.rdm.adminunit.reorganized.v1', 'AdminUnitReorganizedIn', 'PH-07', 'Sinh đề xuất đồng bộ tổ chức (API-20-157), FR-20-056.'),
    ('EVT-12-13', 'realmChanged', '{tenant}.iam.realm.changed.v1', 'RealmChangedIn', 'PH-12', 'Cập nhật trạng thái realm trong registry, FR-20-019, 050.'),
    ('EVT-09-21', 'cryptoShredCompleted', '{tenant}.privacy.crypto-shred.completed.v1', 'CryptoShredCompletedIn', 'PH-09', 'Ghi xác nhận xóa mật mã, kết thúc chấm dứt tenant, FR-20-042.'),
    ('EVT-13-14', 'capacityWarning', '{tenant}.obs.capacity.warning.v1', 'CapacityWarningIn', 'PH-13', 'Đưa vào kiểm tra sẵn sàng và bảng điều khiển, FR-20-007, 067.'),
    ('EVT-03-10', 'tenantRedirectChanged', '{tenant}.gateway.tenant-redirect.changed.v1', 'TenantRedirectChangedIn', 'PH-03', 'Xác nhận chuyển tiếp đã bật hoặc tắt, FR-20-051, 052.'),
    ('EVT-03-11', 'gatewayLimitChanged', '{tenant}.gateway.limit.changed.v1', 'LimitChangedIn', 'PH-03', 'Xác nhận hạn mức đã áp ở gateway, FR-20-027.'),
]
KEY = {'tenantCode': 'T68', 'mergePlanId': 'SN-2026-001', 'orgCode': 'SO-KHCN', 'releaseVersion': '2.4.0'}


def headers_schema(ce_type):
    return {'type': 'object', 'description': 'Tiêu đề Kafka theo CloudEvents 1.0 chế độ nhị phân.', 'required': ['ce_specversion', 'ce_id', 'ce_source', 'ce_type', 'ce_time', 'ce_subject', 'ce_dhtenant'],
            'properties': {'ce_specversion': {'type': 'string', 'const': '1.0'}, 'ce_id': {'type': 'string', 'format': 'uuid', 'description': 'UUID v7, khóa lũy đẳng của bên tiêu thụ.'},
                           'ce_source': {'type': 'string', 'const': '/datahub/dh-platform/tenant'}, 'ce_type': {'type': 'string', 'const': ce_type}, 'ce_time': {'type': 'string', 'format': 'date-time'},
                           'ce_subject': {'type': 'string', 'description': 'Khóa phân vùng: mã đối tượng.'}, 'ce_dhtenant': {'type': 'string', 'description': 'Mã tenant bị tác động (`PLATFORM` với sự kiện cấp nền tảng).'},
                           'ce_dataschema': {'type': 'string', 'format': 'uri'}, 'traceparent': {'type': 'string'}}}


def build():
    ch, ops, msgs = {}, {}, {}
    schemas = {}
    for n, (code, cname, topic, data, key, recv, desc) in enumerate(OUTS, 1):
        ce_type = 'vn.datahub.' + topic.replace('{tenant}.', '').rsplit('.v1', 1)[0] + '.v1'
        schemas[data] = copy.deepcopy(SCH[data])
        tenant_is_param = '{tenant}' in topic
        hdr = {'ce_specversion': '1.0', 'ce_id': SEC % n, 'ce_source': '/datahub/dh-platform/tenant', 'ce_type': ce_type, 'ce_time': T0, 'ce_subject': KEY[key],
               'ce_dhtenant': 'PLATFORM' if cname == 'releasePublished' else 'T68', 'ce_dataschema': 'https://schema.datahub.example.vn/ph20/' + data[:-4] + '/1', 'traceparent': '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'}
        payload = ex_of(data)
        if cname == 'tenantMergeStarted' or key == 'mergePlanId':
            hdr['ce_dhtenant'] = 'T90'
        msgs[cname] = {'name': cname, 'title': code, 'summary': desc.split(';')[0].split('.')[0], 'contentType': 'application/json', 'headers': headers_schema(ce_type),
                       'payload': {'$ref': f'#/components/schemas/{data}'},
                       'bindings': {'kafka': {'key': {'type': 'string', 'description': f'Khóa phân vùng: `{key}`.'}}},
                       'examples': [{'name': 'vi-du', 'headers': hdr, 'payload': payload}]}
        c = {'address': topic, 'title': code, 'description': desc + ' Bên nhận: ' + recv + '.', 'messages': {cname: {'$ref': f'#/components/messages/{cname}'}},
             'bindings': {'kafka': {'topic': topic, 'partitions': 3, 'replicas': 3, 'topicConfiguration': {'cleanup.policy': ['delete'], 'retention.ms': 604800000, 'min.insync.replicas': 2}}}}
        if tenant_is_param:
            c['parameters'] = {'tenant': {'$ref': '#/components/parameters/tenant'}}
        ch[cname] = c
        ops['send' + cname[:1].upper() + cname[1:]] = {'action': 'send', 'title': code, 'summary': desc.split(';')[0], 'description': desc + ' Bên nhận: ' + recv + '.', 'channel': {'$ref': f'#/channels/{cname}'},
                                                        'messages': [{'$ref': f'#/channels/{cname}/messages/{cname}'}]}
    for n, (code, cname, topic, data, src, desc) in enumerate(INS, 1):
        schemas[data] = copy.deepcopy(SCH[data])
        mname = cname + 'In'
        hdr = {'ce_specversion': '1.0', 'ce_id': SEC % (100 + n), 'ce_source': f'/datahub/{src.lower()}', 'ce_type': 'vn.datahub.' + topic.replace('{tenant}.', '').rsplit('.v1', 1)[0] + '.v1', 'ce_time': T0,
               'ce_subject': 'T68', 'ce_dhtenant': 'T68'}
        hs = headers_schema(hdr['ce_type'])
        hs['properties']['ce_source'] = {'type': 'string', 'description': 'Nguồn do bên phát đặt.'}
        msgs[mname] = {'name': mname, 'title': code, 'summary': desc.split(',')[0], 'contentType': 'application/json', 'headers': hs, 'payload': {'$ref': f'#/components/schemas/{data}'},
                       'examples': [{'name': 'vi-du', 'headers': hdr, 'payload': ex_of(data)}]}
        c = {'address': topic, 'title': code, 'description': f'Do {src} phát, PH-20 tiêu thụ: {desc}', 'messages': {mname: {'$ref': f'#/components/messages/{mname}'}}}
        if '{tenant}' in topic:
            c['parameters'] = {'tenant': {'$ref': '#/components/parameters/tenant'}}
        ch[mname] = c
        ops['receive' + mname[:1].upper() + mname[1:]] = {'action': 'receive', 'title': code, 'summary': desc.split(',')[0], 'description': f'PH-20 nhận từ {src}: {desc}', 'channel': {'$ref': f'#/channels/{mname}'}, 'messages': [{'$ref': f'#/channels/{mname}/messages/{mname}'}]}
    # liệt kê mà lược đồ dữ liệu dùng
    acc = set()
    from gen_openapi import used_schemas
    used_schemas(list(schemas.values()), acc)
    for a in acc:
        schemas[a] = copy.deepcopy(SCH[a])
    doc = {
        'asyncapi': '3.0.0',
        'info': {'title': 'Datahub PH-20 Quản trị tenant và phát hành sản phẩm: sự kiện', 'version': '0.2.0-draft',
                 'description': 'Hợp đồng sự kiện EVT-20-01…16 phát ra và 6 sự kiện tiêu thụ (D03-04-PH20 chương 5, FRS 9.3). Ghi vào `ph20_tenant.outbox` cùng giao dịch nghiệp vụ, Debezium đưa lên Kafka; CloudEvents 1.0 chế độ nhị phân, tiêu đề `ce_*` và thuộc tính mở rộng `dhtenant` (`ce_dhtenant`). Sự kiện vòng đời tenant và phát hành đi trên tiền tố nền tảng `platform.` vì tenant mới chưa có tiền tố Kafka riêng; sự kiện tổ chức đi trên `{tenant}.tenant.org.changed.v1`. Khóa phân vùng là mã đối tượng. Không sự kiện nào mang dữ liệu cá nhân (BR-20-039). Lưu giữ 7 ngày, ít nhất một lần, bên nhận khử trùng theo `ce_id`. Tương thích BACKWARD: chỉ thêm trường tùy chọn trong `v1`. Dữ liệu ví dụ là giả lập. Tệp sinh bởi `tools/gen_asyncapi.py`.',
                 'contact': {'name': 'Nhóm phân hệ PH-20'}, 'tags': [{'name': 'tenant'}, {'name': 'release'}], 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)'}},
        'defaultContentType': 'application/json',
        'servers': {'kafka-internal': {'host': 'dh-kafka-kafka-bootstrap.dh-kafka.svc:9093', 'protocol': 'kafka-secure', 'description': 'Listener `internal`: DU, `dh-runtime`, Kafka Connect; mTLS, ACL theo tiền tố tenant và tiền tố `platform.`.',
                                      'security': [{'$ref': '#/components/securitySchemes/mtls'}]}},
        'channels': ch, 'operations': ops,
        'components': {'securitySchemes': {'mtls': {'type': 'X509', 'description': 'mTLS, ACL theo CN và tiền tố.'}},
                       'parameters': {'tenant': {'description': 'Mã tenant chữ thường, ví dụ `t68`.', 'examples': ['t68']}},
                       'messages': msgs, 'schemas': dict(sorted(schemas.items()))},
    }
    return doc


def main():
    doc = build()
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write('# D03-04-PH20 · AsyncAPI PH-20. SINH TỰ ĐỘNG bởi tools/gen_asyncapi.py, không sửa tay. Dữ liệu ví dụ là giả lập.\n')
        yaml.dump(doc, f, Dumper=NoAlias, allow_unicode=True, sort_keys=False, width=160, default_flow_style=False)
    print('asyncapi-ph20.yaml', len(doc['channels']), 'kênh')


if __name__ == '__main__':
    main()
