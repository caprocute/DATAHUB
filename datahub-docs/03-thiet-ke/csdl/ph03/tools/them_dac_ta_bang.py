#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH03.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph03/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH03-csdl-cong-api.md
Khối trích trực tiếp từ ddl/ph03_gateway.sql (khóa, ràng buộc, chỉ mục, RLS mẫu P hoặc S, trigger máy trạng thái,
bất biến, chỉ thêm, không xóa cứng) và COMMENT ON TABLE; FR phục vụ lấy từ FR_BANG (đối chiếu FRS §5 và §6).
Chạy lại nhiều lần không nhân bản. Thêm chú thích cho bảng cột. Chép và chỉnh từ ph19/tools/them_dac_ta_bang.py.
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = open(os.path.join(ROOT, 'ddl', 'ph03_gateway.sql'), encoding='utf-8').read()
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'state_transition': 'Bảng tham chiếu kỹ thuật không có `tenant_id`; ứng dụng chỉ đọc (REVOKE INSERT, UPDATE, DELETE), đổi bằng changeset Liquibase. Có 47 cặp cho 11 máy trạng thái; hai cặp mở rộng so với FRS ghi ở cột `note` (Q03-51).',
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ và không có `tenant_id`; tác vụ nền liên tenant lặp từng tenant bên trong tác vụ.',
    'snapshot_counter': 'Bảng kỹ thuật toàn nền tảng, một dòng mỗi site (`dc1`, `dc2` ở dữ liệu khởi tạo), chỉ chứa số; trigger `tg_counter_monotonic` không cho lùi. Ứng dụng không có INSERT, DELETE.',
    'outbox': 'Chỉ thêm và xóa khi dọn (ứng dụng không có UPDATE); Debezium đọc WAL. Khóa chính `event_id`, không có `id`, `version`.',
    'idempotency_key': 'Khóa tự nhiên `(tenant_id, operation, idem_key)`; chỉ thêm và xóa khi hết hạn 24 giờ; không có cột sửa vì không bao giờ cập nhật.',
    'revoked_token': 'Dòng chỉ thêm; xóa khi token đã hết hạn cộng 60 giây. Chỉ chứa định danh `jti`, `sub`, không chứa token. Không có cột sửa.',
    'route_state_event': 'Nhật ký chỉ thêm: ứng dụng không có UPDATE, DELETE và trigger chặn cả chủ schema. Không có `version`, `updated_*`.',
    'snapshot_violation': 'Dòng chỉ thêm (trigger chặn UPDATE); xóa cùng ảnh chụp khi dọn. Thông điệp không chứa giá trị cấu hình nhạy cảm.',
    'route': 'Bảng lõi: `host_id`, `upstream_id` cùng tenant nhờ khóa ngoại kèm `tenant_id`; trigger `tg_route_ext_guard` kiểm yêu cầu thay đổi đã duyệt khi mở ra Internet.',
    'edge_host': 'Khóa duy nhất toàn cục trên `host_pattern` (khác các khóa duy nhất theo tenant) để một host chỉ thuộc một tenant (BR-03-026); lỗi trùng host của tenant khác lộ sự tồn tại của host nên dịch vụ trả cùng một thông báo chung.',
    'consumer_credential': 'Vân tay chứng thư và băm khóa API duy nhất toàn cục vì gateway tra theo giá trị này; không có cột chứa bí mật.',
    'waf_mode': 'Nơi lưu thật của `gw.waf.mode`; `tenant_param` không nhận khóa này. Trigger `tg_waf_mode_guard` kiểm yêu cầu thay đổi `WAF_MODE` đã duyệt.',
    'rate_limit_override': 'Nơi lưu thật của hạn mức toàn tenant (`scope = TENANT`); khóa duy nhất dùng `NULLS NOT DISTINCT` để hai ghi đè cùng phạm vi không cùng hiệu lực.',
    'tenant_param': 'Trigger `tg_tenant_param_guard` kiểm kiểu, miền và bốn mắt theo `param_definition`; không có dòng nghĩa là dùng mặc định.',
    'param_definition': 'Danh mục toàn nền tảng ở tenant `COMMON`, dữ liệu khởi tạo 66 tham số (§5); tenant chỉ đọc.',
    'edge_certificate': 'Không có khóa riêng ở bảng; `secret_ref` là đường dẫn OpenBao. Chứng thư dùng chung ở `COMMON`.',
    'client_ca': 'Chỉ chứng thư công khai của CA; vai trò báo cáo chỉ đọc cột siêu dữ liệu.',
    'waf_virtual_patch': 'Vai trò báo cáo không đọc cột `rule_text` (nội dung luật vá lộ chi tiết lỗ hổng chưa vá).',
    'change_request': 'Đối tượng và nội dung bất biến sau khi tạo (trigger `tg_write_once`); chỉ đổi trạng thái và quyết định.',
    'config_snapshot': 'Nội dung đã ký bất biến: `site`, `scope`, `content_hash`, `manifest_hash`, `snapshot_version`, `signature_key_id`, `built_from`, `signed_at` ghi một lần (trigger `tg_write_once`). Không xóa cứng, giữ siêu dữ liệu vĩnh viễn.',
}

FR_BANG = {
    'state_transition': 'FR-03-035, 036, 040, 044, 047 (bảng chuyển trạng thái)', 'edge_host': 'FR-03-013, 028, 037, 038',
    'upstream': 'FR-03-029, 030, 031', 'upstream_node': 'FR-03-029, 030', 'route': 'FR-03-028, 035, 036, 038, 039, 047',
    'route_state_event': 'FR-03-035, 036, 047', 'consumer': 'FR-03-014, 016, 046, 047', 'consumer_credential': 'FR-03-002, 014, 046',
    'idempotency_key': 'FR-03-046', 'revoked_token': 'FR-03-018', 'emergency_block': 'FR-03-047',
    'plan_policy': 'FR-03-015, 016, 017, 020, 021, 022', 'subscription_ref': 'FR-03-016, 046',
    'rate_limit_override': 'FR-03-021, 023, 024', 'policy_template_setting': 'FR-03-048',
    'waf_exception': 'FR-03-007', 'waf_virtual_patch': 'FR-03-008', 'waf_mode': 'FR-03-005, 006', 'ip_block': 'FR-03-003, 004',
    'edge_certificate': 'FR-03-001, 049', 'client_ca': 'FR-03-002, 049', 'tls_exception': 'FR-03-001',
    'tenant_redirect': 'FR-03-037', 'snapshot_counter': 'FR-03-041, 042, 044', 'config_snapshot': 'FR-03-039…045',
    'snapshot_violation': 'FR-03-040', 'tenant_hold': 'FR-03-044', 'source_cursor': 'FR-03-039',
    'change_request': 'FR-03-006, 023, 038, 056', 'param_definition': 'FR-03-056', 'tenant_param': 'FR-03-023, 056',
    'synthetic_check': 'FR-03-053', 'legacy_import_job': 'FR-03-059',
    'outbox': 'Mọi FR phát sự kiện (EVT-03-01…08, 10…12); FR-03-042 (EVT-03-01)',
    'shedlock': 'FR-03-007, 018, 026, 039, 045, 049 (tác vụ định kỳ)',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph03_gateway\.(\w+) \((.*?)\n\);', sql, re.S):
    tables[m.group(1)] = {'body': m.group(2)}


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
    for m in re.finditer(r'CREATE UNIQUE INDEX (\w+) ON ph03_gateway\.%s (\([^;]*?\))( NULLS NOT DISTINCT)?( WHERE [^;]*)?;' % ten, sql):
        uq.append('`%s` %s%s%s' % (m.group(1), m.group(2), ' (NULLS NOT DISTINCT)' if m.group(3) else '',
                                   (' có điều kiện' + m.group(4).replace(' WHERE', ' khi')) if m.group(4) else ''))
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph03_gateway\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    ck = ['`%s`' % n for n, _ in con(b, 'CHECK')]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph03_gateway\.%s\b' % ten, sql)]
    rls = re.search(r"CALL ph03_gateway\.p_enable_rls\('ph03_gateway\.%s', '([PS])'\)" % ten, sql)
    if rls and rls.group(1) == 'P':
        cl = 'RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_%s_*` (mục 1.2).' % ten
    elif rls:
        cl = 'RLS mẫu S (FORCE): tenant đọc dòng của mình và dòng `COMMON`; chỉ ghi dòng của mình, dòng `COMMON` chỉ phiên `PLATFORM` ghi; chính sách `rls_%s_*` (mục 1.2).' % ten
    else:
        cl = 'Không bật RLS: bảng kỹ thuật không có `tenant_id` (mục 1.2), ứng dụng chỉ chạm tới dữ liệu không thuộc tenant nào.'
    pv = ['Không phân vùng']
    for m in re.finditer(r'CREATE TRIGGER (\w+) BEFORE ([A-Z ]+?) ON ph03_gateway\.%s FOR EACH ROW EXECUTE FUNCTION ph03_gateway\.(\w+)\(([^)]*)\)' % ten, sql):
        name, ev, fn, args = m.groups()
        args = re.sub(r"'", '', args)
        if fn == 'tg_append_only':
            pv.append('Chỉ thêm, chặn %s (trigger `%s`)' % (ev.replace(' OR ', ' và '), name))
        elif fn == 'tg_no_delete':
            pv.append('Không xóa cứng (trigger `%s`, BR-03-029)' % name)
        elif fn == 'tg_write_once':
            pv.append('Cột ghi một lần: %s (trigger `%s`)' % (', '.join('`%s`' % a.strip() for a in args.split(',')), name))
        elif fn == 'tg_state_guard':
            pv.append('Chuyển trạng thái theo bảng `state_transition` máy `%s` (trigger `%s`)' % (args.strip(), name))
        elif fn not in ('tg_touch',):
            pv.append('Trigger `%s` (`%s`)' % (name, fn))
    fr = FR_BANG.get(ten, 'Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)')
    std = all(re.search(r'^\s+%s\s' % c, b, re.M) for c in ('id', 'created_at', 'created_by', 'updated_at', 'updated_by', 'version'))
    gc = GHI_CHU.get(ten) or ('Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.' if std else 'Xem mục Cách ly tenant.')
    if rls and ten not in GHI_CHU and std:
        gc = 'Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).'
    muc = [('Mục đích', mo_ta), ('FR phục vụ', fr), ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ds(ck)), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'), ('Cách ly tenant', cl),
           ('Phân vùng, chỉ thêm', '. '.join(pv)), ('Ghi chú', gc)]
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
