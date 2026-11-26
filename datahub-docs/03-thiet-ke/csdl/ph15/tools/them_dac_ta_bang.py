#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH19) cho từng bảng ở chương 3 của D03-03-PH15.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph15/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH15-csdl-cong-nha-phat-trien.md
Chạy sau gen_tables_md.py. Khối trích trực tiếp từ ddl/ph15_portal.sql (khóa, ràng buộc, chỉ mục, RLS, phân vùng,
trigger bất biến) và COMMENT ON TABLE. Chạy lại nhiều lần không nhân bản. Thêm chú thích "Cột của bảng ..." cho bảng cột."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = open(os.path.join(ROOT, 'ddl', 'ph15_portal.sql'), encoding='utf-8').read()
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ; tên khóa chứa mã tenant.',
    'dev_terms_acceptance': 'Bằng chứng pháp lý nên bất biến: cả quyền UPDATE, DELETE bị thu hồi lẫn trigger chặn.',
    'support_message': 'Lịch sử xử lý phiếu chỉ được nối thêm; sửa nội dung bằng tin nhắn mới.',
    'outbox_event': 'Debezium EventRouter đọc WAL và phát lên Kafka; payload không có bí mật, thân yêu cầu hay dữ liệu cá nhân.',
    'try_run': 'Dọn theo tham số `15.try.history-days` bằng DELETE theo lô; phân vùng quá 90 ngày thì DETACH rồi DROP.',
    'idempotency_record': 'Không lưu thân phản hồi để bí mật sandbox vừa cấp không nằm lại trong CSDL.',
    'app_credential': 'Không có cột bí mật: chỉ tiền tố 8 ký tự và băm (BR-15-011); vai trò chỉ đọc không thấy `key_hash`.',
    'dev_account': 'Cột `phone_enc` mã hóa envelope (ADR-032); vai trò chỉ đọc không thấy `phone_enc`, `dek_wrapped`, `verification_token_hash`.',
}

FR_BANG = {
    'catalog_api': 'FR-15-001…008, 013, 061', 'catalog_api_version': 'FR-15-006, 011, 013, 061', 'catalog_spec': 'FR-15-009…012', 'sandbox_profile': 'FR-15-034, 036, 037',
    'try_prod_grant': 'FR-15-042, 043', 'content_page': 'FR-15-014…018, 062', 'content_page_version': 'FR-15-014…016, 018, 062',
    'content_attachment': 'FR-15-014, 017, 018, 056, 062', 'content_git_source': 'FR-15-018', 'dev_account': 'FR-15-019…021, 024, 058, 059',
    'dev_team': 'FR-15-022', 'dev_team_member': 'FR-15-022, 033', 'dev_terms': 'FR-15-023', 'dev_terms_acceptance': 'FR-15-023, 025, 035',
    'app': 'FR-15-025, 026, 033, 059', 'app_member': 'FR-15-033, 048…050', 'app_credential': 'FR-15-027…031',
    'prod_credential_ref': 'FR-15-032', 'try_run': 'FR-15-035…043, 049, 060', 'try_collection': 'FR-15-040, 041',
    'try_collection_item': 'FR-15-040, 041', 'notification_subscription': 'FR-15-051', 'inbox_message': 'FR-15-051, 052',
    'support_ticket': 'FR-15-053…055', 'support_message': 'FR-15-054, 055', 'ticket_counter': 'FR-15-054',
    'portal_setting': 'FR-15-056, 057', 'sync_state': 'FR-15-001, 061', 'sync_run': 'FR-15-001, 018, 061',
    'content_migration': 'FR-15-062', 'legacy_mapping': 'FR-15-062', 'inbox_event': 'FR-15-001, 007, 051',
    'outbox_event': 'Mọi FR phát EVT-15-01…14 (FRS §9.2)', 'idempotency_record': 'BR-15-034, mọi FR ghi',
    'shedlock': 'FR-15-001, 018, 024, 026, 031 (tác vụ định kỳ)',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph15_portal\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
    tables[m.group(1)] = {'body': m.group(2), 'part': m.group(4)}


def con(body, kind):
    out = []
    for c in re.finditer(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\s*(.*?)(?=,\n  CONSTRAINT|\n?$)', body + '\n', re.S):
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
    pre = 'ck_%s_' % ten
    pk = [d for _, d in con(b, 'PRIMARY KEY')]
    uq = ['`%s` %s' % (n, d) for n, d in con(b, 'UNIQUE') if not n.endswith('_id_tenant')]
    uq += ['`%s` %s' % (m.group(1), m.group(2)) for m in re.finditer(r'CREATE UNIQUE INDEX (\w+) ON ph15_portal\.%s (\([^;]*?\))(?: WHERE [^;]*)?;' % ten, sql)]
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph15_portal\.(\w+)(.*)', d)
        fk.append('%s → `%s`%s' % (mm.group(1).replace(', tenant_id', ''), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    ck = ['`%s`' % (n[len(pre):] if n.startswith(pre) else n) for n, _ in con(b, 'CHECK')]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph15_portal\.%s\b' % ten, sql)]
    rls = "CALL ph15_portal.p_enable_rls('ph15_portal.%s')" % ten in sql
    cl = ('RLS FORCE, `rls_%s_all`.' % ten) if rls else (
        'Không bật RLS. ' + GHI_CHU.get(ten, 'Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.'))
    pv = []
    if t['part']:
        pv.append('Phân vùng RANGE theo tháng trên `%s` (thủ tục `p_ensure_month_partitions`), dọn bằng DETACH PARTITION' % t['part'])
    trg = []
    for m in re.finditer(r'CREATE TRIGGER (\w+) BEFORE ([A-Z ]+) ON ph15_portal\.%s FOR EACH ROW EXECUTE FUNCTION ph15_portal\.(\w+)\(' % ten, sql):
        if m.group(3) == 'tg_touch':
            continue
        if m.group(3) == 'tg_append_only':
            pv.append('Chỉ thêm, chặn UPDATE và DELETE (trigger `%s`)' % m.group(1))
        else:
            trg.append('`%s` (%s)' % (m.group(1), m.group(3)))
    if trg:
        pv.append('Trigger: ' + ', '.join(trg))
    frs = list(dict.fromkeys(re.findall(r'FR-15-\d{3}(?:…\d{3})?', mo_ta)))
    fr = FR_BANG.get(ten) or ', '.join(frs) or 'Hạ tầng dùng chung cho nhiều FR'
    gc = GHI_CHU.get(ten, '') if rls else 'Xem mục Cách ly tenant.'
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ds(ck)), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'), ('Cách ly tenant', cl),
           ('Phân vùng, chỉ thêm, trigger', '; '.join(pv) or 'Không'), ('Ghi chú', gc)]
    o = ['::: dac-ta']
    for k, v in muc:
        v = v.strip()
        if k == 'Ghi chú' and not v:
            continue
        if v and not v.endswith('.'):
            v += '.'
        o += ['**%s.** %s' % (k, v), '']
    o[-1] = ':::' if o[-1] == '' else o[-1]
    if o[-1] != ':::':
        o.append(':::')
    return '\n'.join(o)


CU = dict(re.findall(r'(?m)^### 3\.\d+\. `(\w+)`[^\n]*\n\n::: dac-ta\n\*\*Mục đích\.\*\* ([^\n]*)\n', s))
s = re.sub(r'(?m)(^### 3\.\d+\. `\w+`[^\n]*\n)\n::: dac-ta\n.*?\n:::\n', r'\1', s, flags=re.S)
parts = re.split(r'(?m)^(### 3\.\d+\. `(\w+)`[^\n]*\n)', s)
out, i, n = [parts[0]], 1, 0
while i < len(parts):
    head, ten, body = parts[i], parts[i + 1], parts[i + 2]
    m = None if ten in CU else re.match(r'\s*([^|\n:#<][^\n]*)\n', body)
    mo_ta = (m.group(1).strip() if m else CU.get(ten, '')).rstrip('.')
    mo_ta = re.sub(r'(\((?:FR|BR)[^)]*\))\.\s.*$', r'\1', mo_ta)
    mo_ta = re.sub(r'\s*\((?:FR|BR)[^)]*\)', '', mo_ta)
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
