#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH01.

Chạy (từ datahub-docs): python3 03-thiet-ke/csdl/ph01/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH01-csdl-ket-nap-httt.md
Khối trích trực tiếp từ ddl/ph01_*.sql (khóa, ràng buộc, chỉ mục, RLS, trigger bảo vệ) và COMMENT ON TABLE; FR phục vụ
lấy từ bảng FR_BANG (đối chiếu nhóm FR của D02-03-PH01 §5) hoặc từ COMMENT. Chạy lại nhiều lần không nhân bản.
Thêm chú thích cho bảng cột. Chép và chỉnh từ csdl/ph19/tools/them_dac_ta_bang.py."""
import glob, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sql = ''.join(open(f, encoding='utf-8').read() + '\n' for f in sorted(glob.glob(os.path.join(ROOT, 'ddl', 'ph01_[0-9]*.sql'))) if 'ph01_99_' not in f)
f = sys.argv[1]
s = open(f, encoding='utf-8').read()

GHI_CHU = {
    'member_system': 'Ba trigger: `tg_member_system_guard` (mã bất biến, bảng chuyển trạng thái, điều kiện nộp, duyệt, kích hoạt, trạng thái cuối đóng băng), `tg_member_system_touch`, `tg_member_system_no_delete` (chỉ xóa cứng nháp chưa từng nộp đã xóa mềm quá 30 ngày). Thêm đối tượng phụ thuộc: `fn_assert_submittable`, `fn_assert_approvable`, `fn_assert_activatable`.',
    'technical_profile': 'Cột có thể NULL khi còn nháp; đủ điều kiện nộp kiểm ở `fn_assert_submittable`. `confirmed_group` là điều kiện phê duyệt (`fn_assert_approvable`).',
    'contact': 'Dữ liệu cá nhân mức Hạn chế (HC): vai trò chỉ đọc `ph01_readonly` không đọc họ tên, chức vụ, thư, điện thoại, tài khoản, `search_text`; không đưa vào sự kiện (EVT-01-13). Cột sinh `search_text` bỏ dấu để tìm danh bạ.',
    'attachment': 'Chỉ siêu dữ liệu; nội dung ở bucket `dh-{tenant}-onboarding` (SSE-C). Mỗi tệp một khóa đối tượng duy nhất trong tenant.',
    'template': 'Mẫu S (dùng chung): tỉnh đọc thêm mẫu `COMMON`, chỉ phiên `PLATFORM` ghi `COMMON`. Mẫu của tenant được dùng trước mẫu mặc định.',
    'state_history': 'Chỉ thêm: vai trò ứng dụng không có quyền UPDATE, DELETE; trigger `tg_state_history_ro` chặn cả chủ bảng, chỉ cho xóa theo tầng khi hồ sơ cha đã bị xóa cứng. Ghi cùng giao dịch với đổi trạng thái (BR-01-031).',
    'emergency_action': 'Quá hạn xác nhận chỉ đánh dấu `OVERDUE`, không tự hoàn tác (BR-01-010). Người xác nhận khác người thực hiện (BR-01-017).',
    'change_request': 'Mỗi HTTT tối đa một yêu cầu `PENDING` (chỉ mục duy nhất từng phần). Duyệt chấm dứt bắt buộc có báo cáo tác động (FR-01-033).',
    'data_demand': 'Quyền theo dòng, không theo hồ sơ. Chỉ mục duy nhất cho phép nhiều dòng cùng loại dữ liệu khi thuộc các yêu cầu mở rộng khác nhau. Xóa dòng chỉ khi hồ sơ còn nháp chưa từng nộp.',
    'scope_ceiling': 'Trần sinh đúng từ nhu cầu được duyệt (`tg_scope_ceiling_guard`); chỉ thu hẹp hoặc đóng. Việc kiểm "tập con" của phạm vi dạng văn bản ở dịch vụ (Q01-50). Giữ vĩnh viễn, không cho vai trò ứng dụng xóa.',
    'review_step': 'Bốn mắt ở CSDL: người lập, người nộp không được phân công (`tg_review_step_guard`); người kết luận là người được phân công; bước đã xong bất biến. Giữ vĩnh viễn.',
    'app_credential': 'KHÔNG có cột bí mật; `secret_ref` bị ràng buộc khớp mẫu đường dẫn OpenBao của đúng tenant và môi trường nên không thể ghi giá trị bí mật vào. Cấp PRODUCTION chỉ khi `sandbox_passed_at` có giá trị.',
    'handover': 'Không lưu liên kết gốc: chỉ SHA-256 (`link_hash`), accessor và mã bọc đã mã hóa bằng transit, mã bọc bị đặt NULL khi rời `PENDING`, `OPENING`. Trạng thái `OPENING` chặn hai người mở đồng thời. Giữ 3 năm.',
    'sandbox_test': 'Chỉ thêm, dọn theo lô sau 1 năm; chưa phân vùng ở tỉnh vừa (khoảng 1 triệu dòng mỗi năm), phân vùng tháng khi vượt khoảng 10 triệu dòng (SDD §11.3).',
    'provisioning_saga': 'Chèn cùng giao dịch với phê duyệt; bộ chạy lấy việc bằng `FOR UPDATE SKIP LOCKED` trên chỉ mục `ix_provisioning_saga_due`; `id` là `sagaId` bất biến làm khóa lũy đẳng với PH-12, PH-03.',
    'saga_step': 'Bước `RUNNING` quá 60 giây được gọi lại với cùng khóa lũy đẳng (`ix_saga_step_stale`). Xóa theo saga cha.',
    'enforcement_task': 'Chặn cổng trước, đặt trạng thái trước, thử lại tới khi xong, không hoàn tác trạng thái (BR-01-023). `client_ids` cố định khi lập việc.',
    'access_review_cycle': 'Mỗi tenant tối đa một kỳ chưa `CLOSED`; kỳ đi một chiều; đóng kỳ khi mọi mục có quyết định; kỳ đã đóng bất biến (bằng chứng giữ 5 năm).',
    'review_confirmation': 'Chỉ lưu SHA-256 của liên kết; trang xác nhận bắt đăng nhập đúng tổ chức. Hạn tối đa 60 ngày.',
    'access_review_item': 'Một dòng cho mỗi cặp (HTTT, mục trần) của kỳ; không giữ được mục có căn cứ hết hiệu lực (`ck_access_review_item_legal`).',
    'legacy_import_job': 'Không mang thông tin xác thực (BR-01-033): `preview` bị ràng buộc không có khóa tên bí mật; tệp gốc xóa sau 7 ngày, chỉ giữ băm.',
    'outbox': 'Debezium Outbox Event Router đọc WAL (QM-VUA, QM-LON); `OutboxRelay` dự phòng dùng `relayed_at` (QM-NHO). Cũng là nơi ghi bản ghi kiểm toán cùng giao dịch (BR-01-031). Không bí mật, không `secret_ref`, không dữ liệu liên hệ cá nhân.',
    'inbox': 'Lũy đẳng theo `(tenant_id, event_id)`; lỗi ba lần thì `DEAD` chuyển hàng đợi lỗi của PH-18. Giữ 30 ngày.',
    'notify_outbox': 'Thử lại tới 24 giờ; không chứa liên kết bàn giao hay phiếu xác nhận (Q01-52).',
    'idempotency_record': 'Giữ 24 giờ (ADR-041); chặn lưu tuyến mở bàn giao vì phản hồi chứa bí mật.',
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ, không bật RLS, vai trò chỉ đọc không đọc được.',
}

FR_BANG = {
    'member_system': 'FR-01-001…004, 009, 012, 018, 019, 024, 029…034, 037, 038, 050',
    'technical_profile': 'FR-01-006, 013, 015', 'contact': 'FR-01-008, 022, 045, 046, 047',
    'attachment': 'FR-01-005, 007, 011', 'template': 'FR-01-010',
    'state_history': 'FR-01-012, 017, 018, 024, 029…032, 037', 'emergency_action': 'FR-01-030, 032',
    'change_request': 'FR-01-031, 033…035', 'data_demand': 'FR-01-007, 014, 035',
    'scope_ceiling': 'FR-01-018, 035, 042, 043', 'review_step': 'FR-01-013, 014, 016…018',
    'app_credential': 'FR-01-020…028, 036', 'handover': 'FR-01-022, 025', 'sandbox_test': 'FR-01-023, 024',
    'provisioning_saga': 'FR-01-020, 024', 'saga_step': 'FR-01-020, 021, 024',
    'enforcement_task': 'FR-01-026, 029…032, 037', 'access_review_cycle': 'FR-01-039, 042, 044',
    'review_confirmation': 'FR-01-041', 'access_review_item': 'FR-01-040…043', 'legacy_import_job': 'FR-01-048',
    'outbox': 'FR-01-037, 038 (mọi FR phát sự kiện)', 'inbox': 'FR-01-008, 046',
    'notify_outbox': 'FR-01-016, 027, 041, 046', 'idempotency_record': 'FR-01-003, 009, 012, 018, 020, 024, 029…035 (mọi lệnh POST có tác dụng phụ)',
    'shedlock': 'FR-01-009, 016, 027, 036, 039, 041, 043, 046 (tác vụ định kỳ)',
}

tables = {}
for m in re.finditer(r'CREATE TABLE ph01_onboarding\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;', sql, re.S):
    tables[m.group(1)] = {'body': m.group(2), 'part': m.group(4)}


def con(body, kind):
    out = []
    for c in re.finditer(r'CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK|EXCLUDE)\s*(.*?)(?=,\n  CONSTRAINT|\Z)', body, re.S):
        if c.group(2) == kind:
            out.append((c.group(1), re.sub(r'\s+', ' ', c.group(3)).strip().rstrip(',')))
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
    uq += ['`%s` %s' % (m.group(1), m.group(2)) for m in re.finditer(r'CREATE UNIQUE INDEX (\w+) ON ph01_onboarding\.%s (\((?:[^;]*?)\))(?: WHERE [^;]*)?;' % ten, sql)]
    fk = []
    for n, d in con(b, 'FOREIGN KEY'):
        mm = re.match(r'\(([^)]*)\) REFERENCES ph01_onboarding\.(\w+)(.*)', d)
        fk.append('(%s) → `%s`%s' % (mm.group(1), mm.group(2), ' xóa theo' if 'CASCADE' in mm.group(3) else '') if mm else d)
    ck = ['`%s`' % n for n, _ in con(b, 'CHECK')]
    ix = ['`%s`' % m.group(1) for m in re.finditer(r'CREATE INDEX (\w+) ON ph01_onboarding\.%s\b' % ten, sql)]
    rls = re.search(r"CALL ph01_onboarding\.p_enable_rls\('ph01_onboarding\.%s', '([PS])'\)" % ten, sql)
    if rls and rls.group(1) == 'P':
        cl = 'RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_%s_{select,insert,update,delete}` (mục 1.2).' % ten
    elif rls:
        cl = 'RLS mẫu S (FORCE, dùng chung): đọc dòng của tenant phiên và `COMMON`; ghi dòng `COMMON` chỉ khi phiên là `PLATFORM`; bốn chính sách `rls_%s_{select,insert,update,delete}` (mục 1.2).' % ten
    else:
        cl = 'Không bật RLS (không có `tenant_id`). ' + GHI_CHU.get(ten, 'Bảng kỹ thuật không chứa dữ liệu nghiệp vụ.')
    trg = [m.group(1) for m in re.finditer(r'CREATE TRIGGER (tg_\w+?(?:guard|_ro|no_delete|draft_delete)) BEFORE [A-Z ]+ ON ph01_onboarding\.%s FOR' % ten, sql)]
    pv = []
    if t['part']:
        pv.append('Phân vùng RANGE theo tháng trên `%s`' % t['part'])
    if trg:
        pv.append('Trigger bảo vệ: ' + ', '.join('`%s`' % x for x in trg) + ' (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện)')
    frs = list(dict.fromkeys(re.findall(r'FR-01-\d{3}(?:…\d{3})?', mo_ta)))
    fr = FR_BANG.get(ten) or ', '.join(frs) or 'Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng)'
    gc = GHI_CHU.get(ten, 'Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.') if rls else 'Xem mục Cách ly tenant.'
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
