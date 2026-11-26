#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH13.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph13/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH13-csdl-giam-sat-kiem-toan.md
Khối trích trực tiếp từ ddl/ph13_audit.sql và ddl/ph13_obs.sql (khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger chỉ-thêm,
trigger bảo vệ) và COMMENT ON TABLE; FR phục vụ lấy từ bảng FR_BANG dưới đây (đối chiếu nhóm FR ở FRS §6, mục "FR hiện thực" của SDD §4).
Chạy lại nhiều lần không nhân bản. Thêm chú thích cho bảng cột."""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ddl_parse  # noqa: E402

D = ddl_parse.parse()
TABLES = {(t['schema'], t['name']): t for t in D['tables']}

FR_BANG = {
    ('ph13_audit', 'audit_signing_key'): 'FR-13-012, 024',
    ('ph13_audit', 'audit_chain'): 'FR-13-011, 014, 015, 059, 060',
    ('ph13_audit', 'audit_event'): 'FR-13-010, 011, 018, 020…023',
    ('ph13_audit', 'audit_anchor'): 'FR-13-012, 014, 015',
    ('ph13_audit', 'audit_anchor_publish'): 'FR-13-012, 013, 054',
    ('ph13_audit', 'audit_worm_batch'): 'FR-13-013, 014, 018',
    ('ph13_audit', 'audit_verification'): 'FR-13-014, 015',
    ('ph13_audit', 'audit_export'): 'FR-13-024',
    ('ph13_audit', 'audit_reconciliation'): 'FR-13-017',
    ('ph13_audit', 'audit_partition'): 'FR-13-018',
    ('ph13_audit', 'audit_quarantine'): 'FR-13-010, 016',
    ('ph13_audit', 'audit_source_grant'): 'FR-13-010, 059',
    ('ph13_audit', 'outbox'): 'Hạ tầng cho EVT-13-05…09, 11, 12 (FR-13-012, 014, 015, 017, 018)',
    ('ph13_audit', 'shedlock'): 'Tác vụ nền của FR-13-012, 013, 014, 017, 018',
    ('ph13_obs', 'tenant_obs_config'): 'FR-13-059, 061',
    ('ph13_obs', 'runbook'): 'FR-13-042, 043',
    ('ph13_obs', 'alert_rule'): 'FR-13-042, 043, 044',
    ('ph13_obs', 'notification_channel'): 'FR-13-048',
    ('ph13_obs', 'oncall_schedule'): 'FR-13-048',
    ('ph13_obs', 'alert'): 'FR-13-044, 045, 047, 050',
    ('ph13_obs', 'alert_action'): 'FR-13-047, 050',
    ('ph13_obs', 'alert_notification'): 'FR-13-046, 053',
    ('ph13_obs', 'detection_rule'): 'FR-13-051, 052',
    ('ph13_obs', 'security_alert'): 'FR-13-052, 053',
    ('ph13_obs', 'incident_report'): 'FR-13-055',
    ('ph13_obs', 'siem_target'): 'FR-13-054',
    ('ph13_obs', 'dashboard_set'): 'FR-13-041, 059',
    ('ph13_obs', 'saved_query'): 'FR-13-026',
    ('ph13_obs', 'probe_definition'): 'FR-13-008',
    ('ph13_obs', 'pii_finding'): 'FR-13-005',
    ('ph13_obs', 'detect_cursor'): 'FR-13-052',
    ('ph13_obs', 'outbox'): 'Hạ tầng cho EVT-13-01…04, 10, 13, 14 (FR-13-044, 047, 053, 061)',
    ('ph13_obs', 'shedlock'): 'Tác vụ nền của FR-13-008, 044, 046, 052, 059',
}

GHI_CHU = {
    ('ph13_audit', 'audit_event'): 'Phân vùng theo `recorded_at` nên khóa chính chỉ duy nhất trong từng phân vùng; khử trùng theo `(tenant_id, id)` ở bộ tiếp nhận (SDD §4.3). Cột `hash` do ChainWriter tính theo JCS (SDD §4.4); CSDL không tính lại mà kiểm tính liền kề và nối `prev_hash` khi đầu chuỗi nhích. Phân vùng không cấp quyền riêng cho ai.',
    ('ph13_audit', 'audit_chain'): 'Đầu chuỗi chỉ nhích khi các bản ghi mới liền kề, nối đúng và bản cuối khớp `head_hash` (trigger `tg_audit_chain_guard`); không xóa dòng, không đổi `genesis_hash`.',
    ('ph13_audit', 'audit_anchor'): 'Thuần chỉ-thêm; nơi công bố tách sang `audit_anchor_publish` để không phải cập nhật bảng này. `key_version` nối tới khóa công khai ở `audit_signing_key`.',
    ('ph13_audit', 'audit_signing_key'): 'Bảng dùng chung mẫu S: mọi tenant đọc khóa công khai để xác minh ngoại tuyến, chỉ phiên PLATFORM ghi; khóa riêng không bao giờ ở CSDL.',
    ('ph13_audit', 'audit_partition'): 'Bảng chung cho mọi tenant nên chỉ phiên PLATFORM đọc, ghi. Thủ tục `p_archive_partition` (SECURITY DEFINER, chỉ vai trò `ph13_archive`) kiểm `SEALED`, `worm_verified_at` và `archive_after` rồi mới tách và xóa phân vùng.',
    ('ph13_audit', 'audit_quarantine'): 'Có thể chứa giá trị Nhạy cảm nên cột `raw_payload` không cấp cho vai trò báo cáo `ph13_readonly`.',
    ('ph13_audit', 'outbox'): 'Dọn sau 3 ngày. Bản ghi kiểm toán của DU không đi qua bảng này.',
    ('ph13_audit', 'shedlock'): 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
    ('ph13_obs', 'outbox'): 'Dọn sau 3 ngày; chặn khóa bí mật trong `payload`.',
    ('ph13_obs', 'shedlock'): 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
    ('ph13_obs', 'detect_cursor'): 'Bảng kỹ thuật với khóa tự nhiên, không có `id`, không có cột sửa ngoài `processed_until`.',
    ('ph13_obs', 'alert_rule'): 'Luật `scope = PLATFORM` chỉ ghi được trong giao dịch của StandardRuleCatalog (`app.rule_catalog = on`).',
    ('ph13_obs', 'alert_notification'): 'Thư và SMS chỉ mang mã cảnh báo, mức, tóm tắt, liên kết (FR-00-062); `recipient` là mã người dùng hoặc nhóm, `CHECK` chặn địa chỉ thư và số điện thoại. Khóa lũy đẳng `ux_alert_notification` dùng `coalesce(alert_id, security_alert_id)`; mỗi dòng thuộc đúng một loại cảnh báo (`ck_alert_notification_subject`).',
    ('ph13_obs', 'runbook'): 'Năm mục bắt buộc đều có `CHECK` độ dài từ 1 đến 4.000 ký tự sau khi cắt khoảng trắng (BR-13-008).',
    ('ph13_obs', 'tenant_obs_config'): 'Hàm `fn_params_valid` kiểm khóa và miền của tham số `13.*`; khóa lạ hoặc ngoài miền làm `CHECK` thất bại (ERR-13-040).',
}

GENERIC_FN = {'tg_touch', 'tg_immutable', 'tg_forbid_delete', 'tg_append_only', 'tg_guard_retention', 'tg_platform_guard'}


def ds(lst):
    return ', '.join(lst) if lst else 'Không'


def first_sentence(txt):
    return re.split(r'(?<=[.;])\s', txt.strip())[0].rstrip('.;')


def khoi(schema, ten, mo_ta):
    t = TABLES.get((schema, ten))
    if not t:
        return None
    cons = t['cons']
    pk = [c['def'] for c in cons if c['kind'] == 'PRIMARY KEY']
    uq = ['`%s` %s' % (c['name'], c['def']) for c in cons if c['kind'] == 'UNIQUE' and not c['name'].endswith('_id_tenant')]
    for i in D['indexes']:
        if i['unique'] and i['schema'] == schema and i['table'] == ten:
            o = i['rest'].index('(')
            cols = i['rest'][o:ddl_parse.find_close(i['rest'], o) + 1]
            uq.append('`%s` %s%s' % (i['name'], cols, ' (một phần)' if 'WHERE' in i['rest'] else ''))
    fk = []
    for c in cons:
        if c['kind'] != 'FOREIGN KEY':
            continue
        mm = re.match(r'\(([^)]*)\) REFERENCES (?:ph13_\w+\.)?(\w+)(.*)', c['def'])
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else c['def'])
    ck = ['`%s`' % c['name'] for c in cons if c['kind'] == 'CHECK']
    ex = ['`%s`' % c['name'] for c in cons if c['kind'] == 'EXCLUDE']
    ix = ['`%s`' % i['name'] for i in D['indexes'] if not i['unique'] and i['schema'] == schema and i['table'] == ten]
    mode = D['rls'].get((schema, ten))
    if mode == 'S':
        cl = 'RLS mẫu S (FORCE): mọi tenant đọc dòng `PLATFORM` và dòng của mình; chỉ phiên `PLATFORM` ghi (mục 1.2).'
    elif mode == 'P':
        cl = 'RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_%s_{select,insert,update,delete}` (mục 1.2).' % ten
    else:
        cl = 'Không bật RLS. Bảng kỹ thuật không chứa dữ liệu nghiệp vụ, không có `tenant_id`.'
    pv, special, imm = [], [], []
    if t['part']:
        pv.append('Phân vùng RANGE theo tháng trên `%s` (thủ tục `p_ensure_month_partitions`, cận Asia/Ho_Chi_Minh); lưu trữ bằng `p_archive_partition`' % t['part'])
    for tr in D['triggers']:
        if tr['schema'] != schema or tr['table'] != ten:
            continue
        ev = tr['event']
        if tr['fn'] == 'tg_append_only':
            what = 'UPDATE, DELETE' if 'DELETE' in ev else ('TRUNCATE' if 'TRUNCATE' in ev else 'UPDATE')
            pv.append('Chỉ thêm, chặn %s (trigger `%s`, BR-13-002)' % (what, tr['name']))
        elif tr['fn'] == 'tg_forbid_delete':
            pv.append('Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `%s`)' % tr['name'])
        elif tr['fn'] == 'tg_guard_retention':
            col, iv = tr['args'][0], tr['args'][1]
            if iv.startswith('0 '):
                pv.append('Chỉ xóa dòng đã qua mốc `%s` (trigger `%s`)' % (col, tr['name']))
            else:
                pv.append('Chỉ xóa dòng quá hạn lưu %s tính từ `%s` (trigger `%s`)' % (iv.replace('years', 'năm').replace('months', 'tháng'), col, tr['name']))
        elif tr['fn'] == 'tg_immutable':
            imm = tr['args']
        elif tr['fn'] == 'tg_platform_guard':
            special.append('`%s` (mục `scope = PLATFORM` chỉ ghi qua StandardRuleCatalog)' % tr['name'])
        elif tr['fn'] not in GENERIC_FN:
            fc = D['fcomment'].get((schema, tr['fn']), '')
            special.append('`%s` (%s)' % (tr['name'], first_sentence(fc) if fc else tr['fn']))
    frs = FR_BANG.get((schema, ten), 'Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)')
    gc = GHI_CHU.get((schema, ten), 'Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.')
    if special:
        gc += ' Trigger bảo vệ: ' + '; '.join(special) + '.'
    if imm:
        gc += ' Cột bất biến sau khi tạo: ' + ', '.join('`%s`' % a for a in imm) + '.'
    if ex:
        gc += ' Ràng buộc loại trừ: ' + ', '.join(ex) + '.'
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


f = sys.argv[1]
lines = open(f, encoding='utf-8').read().split('\n')
out, i, n, schema = [], 0, 0, None
while i < len(lines):
    ln = lines[i]
    m3 = re.match(r'### 3\.\d+\. .*\b(ph13_audit|ph13_obs)\b', ln)
    if m3:
        schema = m3.group(1)
    elif re.match(r'### ', ln):
        schema = None
    m4 = re.match(r'#### 3\.\d+\.\d+\. `(\w+)`', ln)
    if not (m4 and schema):
        out.append(ln)
        i += 1
        continue
    ten = m4.group(1)
    j = i + 1
    while j < len(lines) and not re.match(r'#{1,4} |<!-- gen:', lines[j]):
        j += 1
    body = lines[i + 1:j]
    text = '\n'.join(body)
    mo_ta = None
    mm = re.search(r'\*\*Mục đích\.\*\* ([^\n]*)', text)
    if mm:
        mo_ta = mm.group(1).strip()
        text = re.sub(r'\n*::: dac-ta\n.*?\n:::\n', '\n', text, count=1, flags=re.S)
    else:
        for b in body:
            if b.strip() and not b.startswith('|') and not b.startswith(':'):
                mo_ta = b.strip()
                text = text.replace(b, '', 1)
                break
    k = khoi(schema, ten, (mo_ta or '').rstrip('.'))
    if not k:
        out.append(ln)
        out.extend(body)
        i = j
        continue
    n += 1
    text = text.strip('\n')
    if not re.search(r'(?m)^: Cột của bảng `[^`]*%s`' % ten, text):
        text = re.sub(r'(?m)(^\| Cột [^\n]*\n(?:\|[^\n]*\n?)+)', lambda x: x.group(1).rstrip('\n') + '\n\n: Cột của bảng `%s.%s`\n' % (schema, ten), text, count=1)
    out.append(ln)
    out.append('')
    out.append(k)
    out.append('')
    out.append(text)
    out.append('')
    i = j
open(f, 'w', encoding='utf-8').write('\n'.join(out))
print('đã thêm khối đặc tả cho', n, 'bảng')
