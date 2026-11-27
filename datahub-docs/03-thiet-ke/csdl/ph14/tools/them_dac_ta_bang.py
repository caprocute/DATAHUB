#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH14.

Chạy (từ datahub-docs):
  python3 03-thiet-ke/csdl/ph14/tools/gen_tables_md.py --ghi 03-thiet-ke/csdl/D03-03-PH14-csdl-ket-noi-quoc-gia.md
  python3 03-thiet-ke/csdl/ph14/tools/them_dac_ta_bang.py   03-thiet-ke/csdl/D03-03-PH14-csdl-ket-noi-quoc-gia.md
Khối trích trực tiếp từ ddl/ph14_*.sql (khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger) và COMMENT ON TABLE;
FR phục vụ lấy từ bảng FR_BANG dưới đây (đối chiếu FRS §5). Chạy lại nhiều lần không nhân bản.
Thêm chú thích "Cột của bảng ..." cho bảng cột.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ddl_doc as D  # noqa: E402

f = sys.argv[1]
s = open(f, encoding='utf-8').read()

sql = D.read_sql()
tables = D.parse_tables(sql)
tcom, _ = D.parse_comments(sql)
uniq_idx, plain_idx = D.parse_indexes(sql)
triggers = D.parse_triggers(sql)
rls = D.parse_rls(sql)

# FR phục vụ theo bảng (đối chiếu FRS D02-03-PH14 §5, nhóm A đến I)
FR_BANG = {
    'national_platform': 'FR-14-001, 002, 003, 024, 047',
    'national_service': 'FR-14-004…007, 009, 014, 017…023, 035',
    'service_spec': 'FR-14-008, 014',
    'service_exposure': 'FR-14-009',
    'reconcile_run': 'FR-14-007',
    'config_revision': 'FR-14-054; NFR-14-026',
    'routing_rule': 'FR-14-012, 013',
    'approval_request': 'FR-14-003, 005, 013, 028, 030, 032, 039, 045, 054',
    'worker_command': 'FR-14-002, 007, 008, 043, 047',
    'credential_rotation': 'FR-14-024, 025',
    'national_certificate': 'FR-14-026, 028, 029',
    'trust_anchor': 'FR-14-027, 030',
    'signature_incident': 'FR-14-027, 031, 040',
    'quota_policy': 'FR-14-032, 033',
    'quota_allocation': 'FR-14-034',
    'quota_usage': 'FR-14-033, 057',
    'cache_stats': 'FR-14-035, 036, 037, 057',
    'async_request': 'FR-14-016, 038',
    'inbound_endpoint': 'FR-14-039, 040, 041',
    'allowed_sender': 'FR-14-039, 040',
    'inbound_route': 'FR-14-041',
    'sync_run': 'FR-14-043, 044, 045, 046',
    'sync_record': 'FR-14-043, 046',
    'national_transaction': 'FR-14-010, 049, 050, 051, 052',
    'usage_hourly': 'FR-14-033, 052, 053, 057',
    'health_sample': 'FR-14-047, 048',
    'health_state': 'FR-14-047, 048',
    'platform_outage': 'FR-14-047, 048',
    'anomaly_alert': 'FR-14-053',
    'anomaly_waiver': 'FR-14-053',
    'access_block': 'FR-14-053',
    'parallel_run': 'FR-14-055',
    'parallel_sample': 'FR-14-055',
    'legacy_import': 'FR-14-056',
    'outbox': 'Mọi FR phát sự kiện EVT-14-01…06, 08, 09, 12, 13, 14, 16 và lệnh worker',
    'shedlock': 'FR-14-029, 043, 047, 053 (tác vụ định kỳ)',
}

# Giữ lưu và dọn dữ liệu (NFR-14-021 và giả định ghi trong COMMENT)
RETENTION = {
    'national_transaction': '12 tháng trực tuyến rồi xuất WORM 5 năm kèm chuỗi băm (LedgerArchiver) trước khi DETACH (SEC-62)',
    'usage_hourly': 'Giữ 24 tháng (chủ đầu tư chốt 27/11/2026), DETACH phân vùng quá hạn',
    'quota_usage': 'Giữ 2 năm (NFR-14-021), DETACH phân vùng quá hạn',
    'cache_stats': 'Giữ 13 tháng (chủ đầu tư chốt 27/11/2026), DETACH phân vùng quá hạn',
    'health_sample': 'Giữ 90 ngày, gộp theo giờ sau 7 ngày (HealthRollupJob), DETACH phân vùng quá hạn',
    'parallel_sample': 'Giữ 90 ngày (FR-14-055), DETACH phân vùng quá hạn',
    'sync_run': 'Giữ 3 năm (EN-14-10), tác vụ dọn xóa phiên quá hạn (kéo theo sync_record)',
    'sync_record': 'Xóa theo phiên khi quá 3 năm (khóa ngoại ON DELETE CASCADE)',
    'reconcile_run': 'Giữ 3 năm (FR-14-007)',
    'signature_incident': 'Giữ 5 năm (EN-14-12), không xóa',
    'anomaly_alert': 'Giữ 5 năm (EN-14-14), không xóa',
    'async_request': 'Giữ 90 ngày sau khi kết thúc (chủ đầu tư chốt 27/11/2026), tác vụ dọn xóa theo `finished_at`',
    'worker_command': 'Giữ 30 ngày (giả định), tác vụ dọn xóa theo `finished_at`',
    'outbox': 'Dọn sau 3 ngày khi Debezium đã gửi',
    'platform_outage': 'Giữ 3 năm (giả định)',
    'legacy_import': 'Giữ 3 năm (giả định)',
    'national_certificate': 'Giữ vĩnh viễn, kể cả hết hạn (BR-14-019)',
    'trust_anchor': 'Giữ vĩnh viễn để xác minh giao dịch cũ (BR-14-019)',
    'credential_rotation': 'Giữ vĩnh viễn để truy vết',
    'approval_request': 'Giữ vĩnh viễn, không xóa (kiểm toán bốn mắt)',
}

TRIGGER_TEXT = {
    'tg_no_delete': 'Không cho xóa dòng',
    'tg_retired_final': 'RETIRED là trạng thái cuối, không đảo ngược, không dùng lại mã',
    'tg_service_spec_frozen': 'Bản ACTIVE bất biến, chỉ được chuyển SUPERSEDED, không xóa (ERR-14-010)',
    'tg_approval_frozen': 'Đã quyết định thì bất biến, không xóa',
    'tg_transaction_forward': 'Chỉ chuyển trạng thái tiến theo hạng, chỉ cột kết quả được sửa, không xóa dòng (BR-14-020)',
    'tg_quota_allocation_sum': 'Constraint trigger hoãn: tổng phân bổ hữu hạn không vượt hạn mức (ERR-14-018)',
    'tg_quota_policy_limit': 'Constraint trigger hoãn: không hạ hạn mức xuống dưới tổng đã phân bổ (ERR-14-018)',
    'tg_inbound_endpoint_enable': 'Chỉ ACTIVE khi có nguồn được phép đang bật và tuyến tới luồng PH-04 (ERR-14-024, 039)',
    'tg_parallel_run_read_only': 'Chỉ tạo phiên cho dịch vụ thao tác đọc (ERR-14-033, BR-14-033)',
}

GHI_CHU = {
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ nên không bật RLS.',
    'national_platform': 'Mẫu S: dòng COMMON đọc được ở mọi tenant nhưng chỉ phiên PLATFORM ghi (BR-14-029). Địa chỉ, bí mật ở kết nối PH-05 theo `connection_code`.',
    'national_service': 'Mẫu S như nền tảng. Khóa ngoại kèm `tenant_id` nên dịch vụ chỉ gắn nền tảng cùng tenant; luật định tuyến và hạn mức tham chiếu dịch vụ theo mã.',
    'service_spec': 'Mẫu S. Nội dung đặc tả ≤ 5 MB lưu trong bảng (TOAST nén) để kích hoạt và ảnh chụp cấu hình cùng giao dịch; `ph14_readonly` không đọc cột `content`.',
    'national_transaction': 'Khóa UPSERT (`tenant_id`, `transaction_code`, `started_at`). `lookup_key_hash` không cấp cho `ph14_readonly`. Quyền cấp trên bảng cha, không cấp trên phân vùng.',
    'approval_request': 'Một bảng chung cho tám loại thay đổi của BR-14-022 (ADR-046); chỉ một yêu cầu PENDING cho mỗi (loại, đối tượng).',
    'quota_usage': 'Khóa tự nhiên, không có `id`, `version`; UsageConsumer upsert nhận giá trị lớn hơn.',
    'usage_hourly': 'Khóa tự nhiên; chỉ cộng dồn khi dòng giao dịch vừa được chèn mới (đúng khi Kafka giao lại).',
    'health_sample': 'Khóa tự nhiên; không khóa ngoại để phân vùng tháng tháo gọn.',
    'health_state': 'Một dòng cho mỗi (nền tảng, môi trường); không có `id`, `version`.',
    'cache_stats': 'Khóa tự nhiên (tenant, dịch vụ, giờ); không có `id`, `version`.',
    'parallel_sample': 'Chỉ lưu băm và đường dẫn trường khác biệt, không lưu nội dung dữ liệu cá nhân.',
    'outbox': 'Khóa `event_id`; chỉ thêm (ứng dụng không có quyền UPDATE), xóa khi dọn. Phát lên Kafka bởi Debezium hoặc bộ quét 500 ms.',
    'sync_record': 'Không có cột người tạo, sửa vì bản ghi do worker sinh qua Kafka; có `version` cho ETag.',
    'platform_outage': 'Không có cột sửa; `duration_seconds` là cột sinh từ `started_at`, `ended_at`.',
    'worker_command': '`id` là `commandId`; kết quả xử lý lũy đẳng theo `id`.',
}


def ds(lst):
    return ', '.join(lst) if lst else 'Không'


def khoi(ten, mo_ta):
    t = tables.get(ten)
    if not t:
        return None
    cons = t['cons']
    pk = [c['def'] for c in cons if c['kind'] == 'PRIMARY KEY']
    uq = ['`%s` %s' % (c['name'], c['def']) for c in cons if c['kind'] == 'UNIQUE' and not c['name'].endswith('_id_tenant')]
    for name, cols, where in uniq_idx.get(ten, []):
        uq.append('`%s` %s%s' % (name, cols, (' khi ' + where) if where else ''))
    fk = []
    for c in cons:
        if c['kind'] != 'FOREIGN KEY':
            continue
        mm = re.match(r'\(([^)]*)\) REFERENCES %s\.(\w+)(.*)' % D.SCHEMA, c['def'])
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' (xóa theo)' if 'CASCADE' in mm.group(3) else '') if mm else c['def'])
    ck = ['`%s`' % c['name'] for c in cons if c['kind'] == 'CHECK']
    ix = ['`%s` %s%s' % (n, c, (' khi ' + w) if w else '') for n, c, w in plain_idx.get(ten, [])]
    mode = rls.get(ten)
    has_common = any('COMMON' in c['def'] for c in cons if c['name'].endswith('_tenant'))
    if mode == 'S':
        cl = 'RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; ghi chỉ dòng tenant phiên, dòng `COMMON` chỉ khi phiên là `PLATFORM`; chính sách `rls_%s_*` (mục 1.2).' % ten
    elif mode == 'P':
        cl = 'RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên%s; chính sách `rls_%s_*` (mục 1.2).' % (
            ' (hoặc dòng `COMMON` khi phiên là `PLATFORM`)' if has_common else '', ten)
    else:
        cl = 'Không bật RLS: bảng kỹ thuật không có `tenant_id` và không chứa dữ liệu nghiệp vụ.'
    pv = []
    if t['part']:
        pv.append('Phân vùng RANGE theo tháng trên `%s` (thủ tục `p_ensure_month_partitions`)' % t['part'])
    if ten in RETENTION:
        rt = RETENTION[ten]
        pv.append('Lưu giữ ' + (rt[4:] if rt.startswith('Giữ ') else rt))
    for tg in triggers.get(ten, []):
        if tg['fn'] == 'tg_touch':
            continue
        if tg['fn'] == 'tg_immutable':
            txt = 'Cột bất biến sau INSERT: ' + ', '.join('`%s`' % a for a in tg['args'])
        else:
            txt = TRIGGER_TEXT.get(tg['fn'], tg['fn'])
        pv.append('%s (trigger `%s`)' % (txt, tg['name']))
    frs = FR_BANG.get(ten) or 'Xem mô tả bảng'
    gc = GHI_CHU.get(ten, 'Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.')
    muc = [('Mục đích', mo_ta), ('FR phục vụ', frs), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ds(ck)), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'), ('Cách ly tenant', cl),
           ('Phân vùng, chỉ thêm', '; '.join(pv) or 'Không'), ('Ghi chú', gc)]
    o = ['::: dac-ta']
    for k, v in muc:
        v = v.strip()
        if v and not v.endswith('.'):
            v += '.'
        o += ['**%s.** %s' % (k, v), '']
    o[-1] = ':::'
    return '\n'.join(o)


# Mục đích lấy từ khối cũ (nếu chạy lại) hoặc đoạn đầu dưới tiêu đề (do gen_tables_md.py sinh từ COMMENT ON TABLE)
CU = dict(re.findall(r'(?m)^### 3\.\d+\. `(\w+)`[^\n]*\n\n::: dac-ta\n\*\*Mục đích\.\*\* ([^\n]*)\n', s))
s = re.sub(r'(?m)(^### 3\.\d+\. `\w+`[^\n]*\n)\n::: dac-ta\n.*?\n:::\n', r'\1', s, flags=re.S)
parts = re.split(r'(?m)^(### 3\.\d+\. `(\w+)`[^\n]*\n)', s)
out, i, n = [parts[0]], 1, 0
while i < len(parts):
    head, ten, body = parts[i], parts[i + 1], parts[i + 2]
    m = None if ten in CU else re.match(r'\s*([^|\n:#<][^\n]*)\n', body)
    mo_ta = (m.group(1).strip() if m else CU.get(ten, tcom.get(ten, ''))).rstrip('.')
    k = khoi(ten, mo_ta)
    if k:
        n += 1
        if m:
            body = body[m.end():]
        body = '\n' + k + '\n' + body
        if not re.search(r'(?m)^: Cột của bảng `%s`' % ten, body):
            body = re.sub(r'(?m)(^\| Cột [^\n]*\n(?:\|[^\n]*\n)+)', lambda x: x.group(1) + '\n: Cột của bảng `%s`\n' % ten, body, count=1)
    out.append(head + body)
    i += 3
open(f, 'w', encoding='utf-8').write(''.join(out))
print('đã thêm khối đặc tả cho', n, 'bảng')
