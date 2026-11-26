#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH07) cho từng bảng ở chương 3 của D03-03-PH19.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph19/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH19-csdl-thanh-toan.md
Khối trích trực tiếp từ ddl/ph19_payment.sql (khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger bất biến) và
COMMENT ON TABLE; FR phục vụ lấy từ COMMENT hoặc từ dòng Truy vết của FRS có nhắc EN-19-nn của bảng.
Chạy lại nhiều lần không nhân bản. Thêm chú thích cho bảng cột."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = open(os.path.join(ROOT, 'ddl', 'ph19_payment.sql'), encoding='utf-8').read()
FRS = os.path.join(ROOT, '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH19-frs-thanh-toan.md')
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

# EN -> FR từ FRS (mọi dòng có cả FR heading hiện hành và EN-19-nn trong phần thân)
en_fr = {}
cur = None
for line in open(FRS, encoding='utf-8'):
    m = re.match(r'#### (FR-19-\d{3})', line)
    if m:
        cur = m.group(1)
        continue
    if line.startswith('## ') or line.startswith('### '):
        cur = None
    if cur and ('Truy vết' in line):
        for en in re.findall(r'EN-19-\d{2}', line):
            en_fr.setdefault(en, []).append(cur)

GHI_CHU = {
    'callback_route': 'Không bật RLS vì phải tra trước khi biết tenant (ADR-045); chỉ chứa băm `connectionKey`, không chứa dữ liệu nghiệp vụ.',
    'callback_inbox': 'Lưu nguyên văn thông báo của nhà cung cấp trước khi xử lý (ADR-042); chỉ cho đổi các cột trạng thái xử lý (trigger `tg_callback_inbox_guard`).',
    'outbox_event': 'Debezium EventRouter đọc WAL và phát lên Kafka; cũng là nơi ghi bản ghi kiểm toán cùng giao dịch (BR-19-029).',
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
    'provider_result_mapping': 'Bản ánh xạ `ACTIVE` không sửa được, chỉ thay bằng phiên bản mới qua phê duyệt (trigger `tg_result_mapping_guard`, FR-19-069).',
    'discrepancy': 'Ghi chú xử lý chỉ được nối thêm (trigger `tg_discrepancy_notes_guard`); không xóa dòng.',
    'legacy_mapping': 'Ánh xạ định danh hệ cũ sang hệ mới phục vụ di trú và strangler (ADR-049); chỉ cho đổi cột trạng thái (trigger `tg_legacy_mapping_guard`).',
}

# Ưu tiên bảng này (đối chiếu nhóm FR của FRS §6); bảng không có ở đây lấy từ COMMENT hoặc EN của FRS.
FR_BANG = {
    'payment_provider': 'FR-19-001…012', 'callback_route': 'FR-19-001, 012, 029', 'provider_credential': 'FR-19-002, 012',
    'provider_check_run': 'FR-19-003, 004, 005, 011', 'provider_result_mapping': 'FR-19-069, 030, 036',
    'provider_unmapped_code': 'FR-19-069, 031', 'payment_service_group': 'FR-19-013', 'payment_service': 'FR-19-014…016',
    'payment_partner': 'FR-19-017, 018', 'partner_client': 'FR-19-019', 'partner_service_grant': 'FR-19-020',
    'partner_webhook_endpoint': 'FR-19-021, 060, 062', 'partner_quota_usage': 'FR-19-020, 023',
    'transaction_code_index': 'FR-19-022, 035, 051', 'payment_transaction': 'FR-19-022…028, 030, 035…037, 049…052',
    'transaction_order_guard': 'FR-19-034', 'transaction_event': 'FR-19-028', 'idempotency_record': 'FR-19-033',
    'transaction_adjustment': 'FR-19-046', 'callback_inbox': 'FR-19-029…032', 'callback_nonce': 'FR-19-029',
    'integration_log': 'FR-19-054, 055', 'background_job': 'FR-19-003, 042, 043, 048, 052, 058, 065',
    'stored_file': 'FR-19-040, 043, 045, 048, 052, 058, 065', 'approval_request': 'FR-19-005, 018, 039, 046, 047, 066, 069',
    'refund_request': 'FR-19-038…041', 'reconciliation_session': 'FR-19-042, 047, 048', 'recon_provider_line': 'FR-19-043, 044',
    'discrepancy': 'FR-19-044…046', 'reconciliation_item': 'FR-19-044, 048', 'outbox_event': 'FR-19-053, 061',
    'webhook_delivery': 'FR-19-060, 062', 'notification_feed': 'FR-19-060, 035', 'tenant_payment_config': 'FR-19-063, 064',
    'payment_stats_hourly': 'FR-19-056…058', 'stats_cursor': 'FR-19-056…058', 'legacy_mapping': 'FR-19-065…068',
    'shedlock': 'FR-19-027, 036, 042, 058 (tác vụ định kỳ)',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph19_payment\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
    tables[m.group(1)] = {'body': m.group(2), 'part': m.group(4)}


def con(body, kind):
    out = []
    for c in re.finditer(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\s*(.*?)(?:,\n|$)', body, re.S):
        if c.group(2) == kind:
            out.append((c.group(1), re.sub(r'\s+', ' ', c.group(3)).strip()))
    return out


def ds(lst):
    return ', '.join(lst) if lst else 'Không'


def khoi(ten, mo_ta):
    t = tables.get(ten)
    if not t:
        return None
    b = t['body']
    pk = [d for _, d in con(b, 'PRIMARY KEY')]
    uq = ['`%s` %s' % (n, d) for n, d in con(b, 'UNIQUE') if not n.endswith('_id_tenant')]
    uq += ['`%s` %s' % (m.group(1), m.group(2)) for m in re.finditer(r'CREATE UNIQUE INDEX (\w+) ON ph19_payment\.%s (\([^;]*?\))(?: WHERE [^;]*)?;' % ten, sql)]
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph19_payment\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    ck = ['`%s`' % n for n, _ in con(b, 'CHECK')]
    ex = ['`%s`' % n for n, _ in con(b, 'EXCLUDE')]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph19_payment\.%s\b' % ten, sql)]
    rls = "CALL ph19_payment.p_enable_rls('ph19_payment.%s')" % ten in sql
    cl = ('RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_%s_all` (mục 1.2).' % ten) if rls else (
        'Không bật RLS. ' + GHI_CHU.get(ten, 'Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.'))
    ro = re.search(r'CREATE TRIGGER (\w+) BEFORE (UPDATE OR DELETE|DELETE) ON ph19_payment\.%s FOR EACH ROW EXECUTE FUNCTION ph19_payment\.tg_append_only' % ten, sql)
    pv = []
    if t['part']:
        pv.append('Phân vùng RANGE theo tháng trên `%s` (thủ tục `p_ensure_month_partitions`); dọn dữ liệu hết hạn bằng DETACH PARTITION' % t['part'])
    if ro:
        pv.append(('Chỉ thêm, chặn UPDATE và DELETE' if 'UPDATE' in ro.group(2) else 'Không cho xóa dòng') + ' (trigger `%s`, BR-19-030)' % ro.group(1))
    frs = list(dict.fromkeys(re.findall(r'FR-19-\d{3}(?:…\d{3})?', mo_ta)))
    if not frs:
        for en in re.findall(r'EN-19-\d{2}', mo_ta):
            frs += en_fr.get(en, [])
        frs = list(dict.fromkeys(frs))
    fr = FR_BANG.get(ten) or ', '.join(frs) or 'Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)'
    gc = GHI_CHU.get(ten, 'Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.') if rls else 'Xem mục Cách ly tenant.'
    if ex:
        gc += ' Ràng buộc loại trừ: ' + ', '.join(ex) + '.'
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
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


CU = dict(re.findall(r'(?m)^### 3\.\d+\. `(\w+)`[^\n]*\n\n::: dac-ta\n\*\*Mục đích\.\*\* ([^\n]*)\n', s))
s = re.sub(r'(?m)(^### 3\.\d+\. `\w+`[^\n]*\n)\n::: dac-ta\n.*?\n:::\n', r'\1', s, flags=re.S)
parts = re.split(r'(?m)^(### 3\.\d+\. `(\w+)`[^\n]*\n)', s)
out, i, n = [parts[0]], 1, 0
while i < len(parts):
    head, ten, body = parts[i], parts[i + 1], parts[i + 2]
    m = None if ten in CU else re.match(r'\s*([^|\n:#<][^\n]*)\n', body)
    mo_ta = (m.group(1).strip() if m else CU.get(ten, '')).rstrip('.')
    k = khoi(ten, mo_ta or CU.get(ten, ''))
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
