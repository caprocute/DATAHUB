#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH02.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph02/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH02-csdl-danh-muc-dich-vu.md
Khối trích trực tiếp từ ddl/ph02_[0-9][0-9]_*.sql (khóa, ràng buộc, chỉ mục, RLS, phân vùng, trigger chốt chặn,
thu quyền) và COMMENT ON TABLE; FR phục vụ lấy từ bảng FR_BANG dưới đây (đối chiếu FRS D02-03-PH02 chương 6).
Chạy lại nhiều lần không nhân bản. Thêm chú thích cho bảng cột. Chép và chỉnh từ csdl/ph19/tools/them_dac_ta_bang.py."""
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FILES = sorted(f for f in glob.glob(os.path.join(ROOT, 'ddl', 'ph02_[0-9][0-9]_*.sql')) if '_90_' not in f)
sql = '\n'.join(open(f, encoding='utf-8').read() for f in FILES)
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'job_lease': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ và không có `tenant_id`; tác vụ liên tenant lặp từng tenant bên trong khóa.',
    'lint_rule': 'Bộ luật dùng chung toàn nền tảng: mọi dòng mang `tenant_id = COMMON` (`ck_lint_rule_common`); tỉnh đọc, PA ghi bằng phiên `PLATFORM`. Mẫu quét bí mật cố định mức `ERROR`, không chỉnh (`ck_lint_rule_secret_fixed`).',
    'api_spec': 'Nội dung đặc tả ở kho đối tượng Garage, không ở CSDL (BR-02-014, NFR-02-017); chỉ giữ khóa đối tượng và băm SHA-256.',
    'lint_finding': 'Không lưu chuỗi khớp của bộ quét bí mật, chỉ dấu vân tay `fingerprint`; chế độ `PREVIEW` không ghi gì (FR-02-019).',
    'outbox_event': 'Debezium outbox router đọc WAL (hoặc `OutboxPublisher` quét 500 ms) rồi phát lên Kafka kèm tiêu đề CloudEvents; ghi cùng giao dịch với thay đổi gốc (ADR-042). Ứng dụng chỉ được cập nhật `published_at`.',
    'inbox_event': 'Ghi `event_id` trước khi xử lý để sự kiện phát lại không tạo hiệu ứng thứ hai; khóa là mã sự kiện nên không có `id` riêng.',
    'usage_daily': 'Khóa tự nhiên (tenant, phiên bản, ngày, thao tác, HTTT khai thác), không có `id` và cột sửa; làm mới theo giờ từ PH-13.',
    'config_change_log': 'Chỉ thêm; tính duy nhất của `(tenant, env, source_version)` do khóa dòng `config_epoch` bảo đảm.',
    'config_epoch': 'Bộ đếm cấu hình, dòng bị khóa ở câu lệnh cuối của mọi giao dịch đổi dữ liệu gateway cần biết; tạo khi cấp phát tenant.',
    'code_registry': 'Bảng bằng chứng chỉ thêm, không có cột sửa nên không có `updated_*` và `version`.',
    'idempotency_record': 'Không có `updated_*` và `version`; hết hạn sau tối đa 48 giờ, dọn theo `expires_at`.',
    'legacy_id_map': 'Giữ vĩnh viễn làm bằng chứng di trú, đầu vào của đối soát D06-01.',
    'review_decision': 'Cột `requested_by` sao từ yêu cầu duyệt để CHECK bốn mắt thực hiện được trong một bảng.',
    'subscription': 'Khóa ngoại ba cột `(plan_id, api_version_id, tenant_id)` bảo đảm đăng ký khớp phiên bản của gói.',
    'api_version': 'Ràng buộc loại trừ hoãn tới cuối giao dịch cho phép thay thế phiên bản cùng số chính trong một giao dịch (BR-02-035).',
}

# FR phục vụ từng bảng (đối chiếu nhóm FR của FRS §6)
FR_BANG = {
    'category': 'FR-02-007, 008', 'code_registry': 'FR-02-010, 024, 027, 033, 042 (BR-02-021)', 'api': 'FR-02-001…005, 010, 013, 014, 040, 041, 045',
    'api_tag': 'FR-02-007', 'api_version': 'FR-02-034…042, 045', 'api_spec': 'FR-02-006, 011, 012, 014', 'api_operation': 'FR-02-002, 005, 029, 043',
    'api_search_doc': 'FR-02-003', 'context_path_reservation': 'FR-02-024', 'api_owner_transfer': 'FR-02-045', 'diff_result': 'FR-02-043, 044',
    'lint_rule': 'FR-02-017, 018, 021', 'lint_rule_override': 'FR-02-021', 'lint_finding': 'FR-02-016…020', 'backend': 'FR-02-022, 023, 025, 026',
    'plan': 'FR-02-027…033', 'plan_operation_scope': 'FR-02-029', 'subscription': 'FR-02-046…052', 'subscription_state_history': 'FR-02-051, 052',
    'version_state_history': 'FR-02-034…039, 056', 'grant_job': 'FR-02-048, 051', 'review_request': 'FR-02-030, 034, 035, 038, 039, 041, 047',
    'version_contributor': 'FR-02-034, 035', 'review_decision': 'FR-02-035, 047', 'deprecation_reminder': 'FR-02-038, 057',
    'change_notice': 'FR-02-057', 'change_notice_recipient': 'FR-02-057', 'sla_commitment': 'FR-02-055', 'sla_maintenance_window': 'FR-02-056',
    'sla_period': 'FR-02-056', 'usage_daily': 'FR-02-058', 'national_sync_record': 'FR-02-053, 054', 'national_sync_run': 'FR-02-054',
    'config_epoch': 'FR-02-036, 059', 'config_change_log': 'FR-02-059', 'publish_job': 'FR-02-036, 037, 048', 'gateway_drift': 'FR-02-060',
    'async_operation': 'FR-02-012, 026, 043, 061', 'pending_command': 'FR-02-013, 026, 048, 057', 'inbox_event': 'FR-02-009, 013, 051',
    'outbox_event': 'Mọi FR phát sự kiện EVT-02-01…16', 'idempotency_record': 'Mọi lệnh POST đổi trạng thái (FR-00)',
    'job_lease': 'FR-02-038, 039, 052, 054, 056, 060 (tác vụ định kỳ)', 'import_session': 'FR-02-061', 'legacy_id_map': 'FR-02-061',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph02_catalog\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
    tables[m.group(1)] = {'body': m.group(2), 'part': m.group(4)}

fn_comment = dict(re.findall(r"COMMENT ON FUNCTION ph02_catalog\.(\w+)\(\) IS '((?:[^']|'')*)';", sql))
revoked = set()
for m in re.finditer(r'REVOKE UPDATE, DELETE ON ([^;]*?) FROM ph02_app;', sql, re.S):
    revoked |= set(re.findall(r'ph02_catalog\.(\w+)', m.group(1)))


def con(body, kind):
    out = []
    for c in re.finditer(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\s*(.*?)(?:,\n|$)', body, re.S):
        if c.group(2) == kind:
            out.append((c.group(1), re.sub(r'\s+', ' ', c.group(3)).strip()))
    return out


def ds(lst):
    return ', '.join(lst) if lst else 'Không'


def first_sentence(txt):
    txt = txt.replace("''", "'")
    m = re.match(r'(.{20,}?[.;:])(\s|$)', txt)
    return (m.group(1) if m else txt).rstrip('.;:')


def khoi(ten, mo_ta):
    t = tables.get(ten)
    if not t:
        return None
    b = t['body']
    pk = [d for _, d in con(b, 'PRIMARY KEY')]
    uq = ['`%s` %s' % (n, d) for n, d in con(b, 'UNIQUE') if not n.endswith('_id_tenant') and n != 'uq_plan_id_version']
    for m in re.finditer(r'CREATE UNIQUE INDEX (\w+) ON ph02_catalog\.%s (\([^;]*?\))(\s+WHERE [^;]*?)?;' % ten, sql):
        uq.append('`%s` %s%s' % (m.group(1), re.sub(r'\s+', ' ', m.group(2)), (' từng phần' + re.sub(r'\s+', ' ', m.group(3))) if m.group(3) else ''))
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph02_catalog\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '',
                                        ' (hoãn tới cuối giao dịch)' if 'DEFERRABLE' in mm.group(3) else '') if mm else d)
    ck = ['`%s`' % n for n, _ in con(b, 'CHECK')]
    ex = ['`%s`' % n for n, _ in con(b, 'EXCLUDE')]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph02_catalog\.%s\b' % ten, sql)]
    rm = re.search(r"p_enable_rls\('ph02_catalog\.%s', '([PS])'\)" % ten, sql)
    if rm and rm.group(1) == 'P':
        cl = 'RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_%s_select`, `_insert`, `_update`, `_delete` (mục 1.2).' % ten
    elif rm:
        cl = 'RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi dòng `COMMON` chỉ khi phiên là `PLATFORM` (mục 1.2).'
    else:
        cl = 'Không bật RLS. ' + GHI_CHU.get(ten, 'Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.')
    pv = []
    if t['part']:
        pv.append('Phân vùng RANGE theo tháng trên `%s` (thủ tục `p_ensure_month_partitions`); không cấp quyền trực tiếp lên phân vùng, dọn dữ liệu hết hạn bằng DETACH PARTITION' % t['part'])
    for m in re.finditer(r'CREATE TRIGGER (\w+) BEFORE (UPDATE OR DELETE|UPDATE|DELETE) ON ph02_catalog\.%s FOR EACH ROW EXECUTE FUNCTION ph02_catalog\.tg_append_only' % ten, sql):
        pv.append(('Chỉ thêm, chặn UPDATE và DELETE' if 'UPDATE' in m.group(2) and 'DELETE' in m.group(2) else 'Chặn UPDATE' if 'UPDATE' in m.group(2) else 'Không cho xóa dòng')
                  + ' (trigger `%s`)' % m.group(1))
    if ten in revoked:
        pv.append('Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai)')
    if ten == 'outbox_event':
        pv.append('`ph02_app` chỉ được UPDATE cột `published_at`')
    for m in re.finditer(r'CREATE TRIGGER (\w+) BEFORE [A-Z ,]+(?: OF [a-z_, ]+)? ON ph02_catalog\.%s FOR EACH ROW EXECUTE FUNCTION ph02_catalog\.(\w+)\(\)' % ten, sql):
        tg, fn = m.group(1), m.group(2)
        if fn in ('tg_touch', 'tg_append_only'):
            continue
        pv.append('Trigger chốt chặn `%s`: %s' % (tg, first_sentence(fn_comment[fn]) if fn in fn_comment else fn))
    frs = FR_BANG.get(ten, 'Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)')
    gc = GHI_CHU.get(ten, 'Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.') if rm else 'Xem mục Cách ly tenant.'
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
