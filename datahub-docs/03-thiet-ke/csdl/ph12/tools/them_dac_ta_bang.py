#!/usr/bin/env python3
"""Thêm khối đặc tả 10 mục (K-TRINH-BAY §5, mẫu D03-03-PH05, PH19) cho từng bảng ở chương 3 của D03-03-PH12.

Chạy (từ datahub-docs), sau gen_tables_md.py:
  python3 03-thiet-ke/csdl/ph12/tools/them_dac_ta_bang.py 03-thiet-ke/csdl/D03-03-PH12-csdl-dinh-danh-phan-quyen.md
Khối trích trực tiếp từ ddl/ph12_iam_0*.sql: khóa chính, khóa duy nhất (kể cả chỉ mục duy nhất từng phần), khóa ngoại,
tên CHECK, chỉ mục, mẫu RLS (CALL p_enable_rls), trigger bất biến (tg_append_only, tg_no_delete, tg_*_guard) và
COMMENT ON TABLE. FR phục vụ và ghi chú vận hành là hai bảng tra FR_BANG, GHI_CHU ở dưới (viết tay, kiểm khi thêm bảng).
Chạy lại nhiều lần không nhân bản. Thêm chú thích cho bảng cột nếu thiếu.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ddl_parse  # noqa: E402

FR_BANG = {
    'user_account': 'FR-12-001…006, 008…010, 062',
    'user_import': 'FR-12-009',
    'user_import_row': 'FR-12-009',
    'sod_pair': 'FR-12-013, 051',
    'legacy_role_map': 'FR-12-009, 011',
    'role_assignment': 'FR-12-004, 011…013, 016, 018, 046, 051',
    'sod_exception': 'FR-12-013',
    'org_group': 'FR-12-010, 014, 046',
    'org_group_member': 'FR-12-014',
    'custom_role': 'FR-12-015',
    'custom_role_permission': 'FR-12-015',
    'privileged_grant': 'FR-12-017, 027',
    'recert_campaign': 'FR-12-018',
    'recert_item': 'FR-12-018',
    'federation': 'FR-12-026',
    'saml_client': 'FR-12-025',
    'vneid_link': 'FR-12-028',
    'client': 'FR-12-008, 030…033, 036',
    'client_scope': 'FR-12-035, 036, 051',
    'client_credential': 'FR-12-033, 034',
    'service_account': 'FR-12-037',
    'revocation_feed_version': 'FR-12-040',
    'revocation_entry': 'FR-12-005, 024, 031, 040',
    'node_heartbeat': 'FR-12-040, 051, 054',
    'realm_state': 'FR-12-039, 041…043',
    'realm_provision_step': 'FR-12-041',
    'tenant_merge_step': 'FR-12-019',
    'policy': 'FR-12-052, 055',
    'policy_version': 'FR-12-052…055',
    'policy_version_contributor': 'FR-12-052, 054',
    'policy_test_case': 'FR-12-052',
    'policy_test_run': 'FR-12-052, 054',
    'policy_dryrun_report': 'FR-12-053, 054',
    'bundle_release': 'FR-12-051, 054, 055',
    'bundle_ack': 'FR-12-051, 054, 055',
    'alert': 'FR-12-059',
    'alert_ack': 'FR-12-059',
    'account_report_daily': 'FR-12-060',
    'mfa_coverage_daily': 'FR-12-022, 060',
    'sync_task': 'FR-12-003…005, 009, 012, 030, 031, 040',
    'idempotency_key': 'Mọi API ghi của PH-12 (ADR-041); FR-12-030, 041 (saga của PH-01, PH-20)',
    'outbox': 'Mọi FR phát sự kiện EVT-12-01…15 (ADR-042)',
    'shedlock': 'Tác vụ định kỳ: FR-12-008, 017, 018, 042, 051, 060',
}

GHI_CHU = {
    'user_account': 'Chứa dữ liệu cá nhân (họ tên, thư điện tử; mục 5); `ph12_readonly` không đọc được `email` và `full_name`. Trigger `tg_user_account_last_admin` giữ tenant còn ít nhất một quản trị tỉnh (ERR-12-046). Ước lượng 3.000 dòng mỗi tỉnh vừa (GĐ-12-02), thiết kế tới 10.000 (NFR-12-023). Lưu giữ: vĩnh viễn (mục 8).',
    'user_import': 'Tệp gốc ở bucket `dh-iam-import`, xóa sau 24 giờ; bản ghi giữ 30 ngày sau khi xong (giả định) rồi tác vụ dọn dữ liệu hết hạn xóa, cùng với các dòng của lần nhập.',
    'user_import_row': 'Có dữ liệu cá nhân của người được nhập; cột `raw` không nhận mật khẩu (CHECK `ck_user_import_row_no_secret`). Xóa theo lần nhập sau 30 ngày (giả định).',
    'sod_pair': 'Dữ liệu `COMMON`, 10 dòng sinh từ D02-08 §4 bằng changeset `runOnChange` (mục 6). Đổi ma trận là đổi changeset và đi qua duyệt chính sách nền tảng (FR-12-051).',
    'legacy_role_map': 'Dữ liệu `COMMON`, 17 dòng (mục 6): 15 vai trò của SRS repo (FRS §11.4) và 2 vai trò của realm `lgsp` ở compose. Đầu vào của nhập người dùng và di trú.',
    'role_assignment': 'Hai trigger chốt tách nhiệm vụ (`tg_role_assignment_sod`, khóa tư vấn theo người dùng) và tenant còn quản trị cuối cùng. `AssignmentExpiryJob` đặt EXPIRED mỗi phút; hết hạn đã có hiệu lực ngay ở OPA vì Rego kiểm `valid_to` ở mọi quyết định (SDD §4.3). Không xóa vật lý: gỡ là REVOKED.',
    'sod_exception': 'Trigger `tg_sod_exception_guard` từ chối cặp có `allow_exception = false`. Hết hạn thì `AssignmentExpiryJob` đặt EXPIRED và gỡ vai trò thứ hai. Cột `approved_by` ghi người quyết định cả khi từ chối hoặc thu hồi.',
    'org_group': '`path` là `ltree` do trigger tính; chỉ mục GiST phục vụ truy vấn cây con (phạm vi `ORG`). Cây này vào gói dữ liệu tenant dưới dạng `org_tree`. Nhóm còn thành viên không xóa được (ERR-12-011).',
    'org_group_member': 'Bảng nối, không có cột sửa; thêm hoặc bớt thành viên là thêm hoặc xóa dòng.',
    'custom_role': 'Đợt 2 (FR-12-015), tham số `12.role.custom-enabled`. Chỉ tenant tỉnh (CHECK `ck_custom_role_tenant`). Vai trò tùy biến vào gói dữ liệu tenant (`custom_roles`).',
    'custom_role_permission': 'Quyền đặc quyền bị dịch vụ từ chối theo `permissions.json` (BR-12-007); CSDL chỉ kiểm định dạng mã quyền.',
    'privileged_grant': 'Giữ vĩnh viễn làm bằng chứng truy cập liên tenant. Chỉ dòng ACTIVE vào gói `platform` (`grants`); hết hạn có hiệu lực ngay vì OPA kiểm `expires_at` ở mọi quyết định (BR-12-032). Bản ghi kiểm toán đi vào chuỗi băm của tenant bị truy cập ở PH-13, không ở bảng này.',
    'recert_campaign': 'Tác vụ `RecertScheduler` mở theo chu kỳ 90 ngày (quản trị) và 180 ngày (khác). Dữ liệu nhỏ, giữ vĩnh viễn.',
    'recert_item': 'Mục chưa trả lời sau hạn bị `RecertService.closeExpired` đặt `AUTO_REVOKE` và gỡ gán vai trò (BR-12-044).',
    'federation': 'Không lưu bí mật bind, chỉ `secret_ref` tới OpenBao; External Secrets Operator đưa vào Keycloak (SDD §4.7). Đồng bộ thay đổi mỗi `sync_changed_hours` giờ, đồng bộ đầy đủ 03:30.',
    'saml_client': 'Dành cho ứng dụng cũ (FR-12-025); siêu dữ liệu XML nhận bằng tệp tải lên, không tự tải URL (SEC-45).',
    'vneid_link': 'Đợt 2, cờ `12.vneid.enabled` mặc định tắt. Chỉ lưu băm HMAC của định danh; khóa HMAC ở OpenBao.',
    'client': 'Không lưu bí mật. Client `REVOKED` giữ vĩnh viễn, mã client không dùng lại. Trigger `tg_client_no_delete` và quyền DELETE bị thu hồi. `last_used_at` do bộ tiêu thụ EVT-12-16 cập nhật, nguồn của tự tạm ngừng 90 ngày (BR-12-020).',
    'client_scope': 'Thay theo nguồn bằng `ScopeSynchronizer`: xóa phần scope của nguồn rồi chèn tập mới trong một giao dịch, giữ phần của nguồn khác. Vào gói tenant dưới dạng `client_scopes`.',
    'client_credential': 'Chỉ siêu dữ liệu (dấu vân tay, hạn, `wrap_accessor`), không có bí mật, khóa riêng hay chứng thư đầy đủ. Dòng `RETIRED` giữ 12 tháng rồi xóa (mục 8).',
    'service_account': 'Tenant `PLATFORM`. Khóa riêng không rời OpenBao (`transit/sign/dh-svc-{account}`); chỉ khóa công khai ở JWKS của client. Khai báo qua yêu cầu hợp nhất có người duyệt thứ hai.',
    'revocation_feed_version': 'Một dòng toàn cục. Trigger `tg_revocation_entry_bump` (mức câu lệnh) tăng `version` sau mỗi lệnh ghi `revocation_entry`; API-12-079 dùng làm ETag.',
    'revocation_entry': 'Ghi trước khi gọi Keycloak (`block_all = true`). Dòng đã hạ cờ hết hạn sau 330 giây và tác vụ dọn xóa sau 7 ngày. Cổng đọc danh sách của mọi tenant bằng cách lặp từng tenant, không có ngoại lệ RLS (Q12-52).',
    'node_heartbeat': 'Dữ liệu `COMMON`. Chỉ phiên `PLATFORM` ghi (bộ tiếp nhận `X-DH-Applied-Version` và plugin `status` của OPA). Dòng nút im lặng quá 24 giờ bị xóa.',
    'realm_state': 'Tenant `PLATFORM` (dữ liệu của nền tảng); tenant mà realm phục vụ nằm ở `tenant_code`. Cấu hình bảo mật chỉ đổi qua GitOps, `baseline_snapshot` là mức chuẩn so lệch hằng giờ. Realm `DELETED` giữ dòng vĩnh viễn.',
    'realm_provision_step': 'Tám bước lũy đẳng của saga tạo realm; xóa cùng realm đang `PROVISIONING` khi bù trừ.',
    'tenant_merge_step': 'Đợt 2. Không có khóa ngoại tới `user_account` vì người dùng nguồn và đích ở hai tenant. Giữ 12 tháng sau khi sáp nhập xong (giả định).',
    'policy': 'Không xóa vật lý. Chính sách gốc `base-authz` (`is_root`) tạo bằng changeset khởi tạo ở tenant `PLATFORM`.',
    'policy_version': 'Máy trạng thái ở trigger `tg_policy_version_guard`; nội dung bất biến sau gửi duyệt; `content_hash` do trigger `tg_policy_version_0hash` tính. Giữ vĩnh viễn (NFR-12-030); `GitMirror` ghi bản sao PUBLISHED vào kho `dh-policies`.',
    'policy_version_contributor': 'Chỉ thêm; người duyệt không được nằm trong bảng này (kiểm ở `tg_policy_version_guard`).',
    'policy_test_case': 'Ca kiểm thử theo chính sách, không theo phiên bản: cùng bộ ca chạy lại ở mọi phiên bản. Bản sao ở Git `dh-policies`.',
    'policy_test_run': 'Chỉ thêm; ứng dụng không có quyền UPDATE. Giữ cùng vòng đời phiên bản chính sách.',
    'policy_dryrun_report': 'Giữ 12 tháng (`purge_after`), xóa được sau hạn dù đã DONE; trong hạn chỉ sửa được khi RUNNING. Mẫu đã che, không có dữ liệu cá nhân.',
    'bundle_release': 'Không xóa vật lý; thân gói ở bucket `dh-platform-policy`, bản bất biến `releases/{revision}.tar.gz`. Giữ 12 tháng bản phát hành cũ ở kho (mục 8), dòng ở CSDL giữ vĩnh viễn.',
    'bundle_ack': 'Giữ 30 ngày. Bộ tiếp nhận trạng thái OPA ghi theo từng tenant của gói (đặt `app.tenant_id` theo tên gói), không ghi chéo.',
    'alert': 'Dữ liệu nhỏ (giả định dưới 500 dòng mỗi tháng mỗi tỉnh). Giữ 24 tháng rồi xóa (mục 8); sự kiện EVT-12-14 và chuỗi PH-13 giữ lâu hơn.',
    'alert_ack': 'Chỉ thêm; cùng vòng đời với cảnh báo.',
    'account_report_daily': 'Khóa tự nhiên, ghi đè khi tính lại cùng ngày. Giữ 24 tháng (`purge_after`).',
    'mfa_coverage_daily': 'Khóa tự nhiên. Giữ 24 tháng (`purge_after`); `sample_mismatch` > 0 thì phát cảnh báo cấu hình.',
    'sync_task': 'Việc DONE xóa sau 7 ngày; việc FAILED giữ 30 ngày để điều tra. Ý định không chứa bí mật; người dùng mới nhận liên kết kích hoạt do Keycloak gửi, không có mật khẩu trong ý định.',
    'idempotency_key': 'Giữ 24 giờ rồi tác vụ dọn xóa (`expires_at`). Thân phản hồi lưu không có `wrappingToken` (BR-12-023).',
    'outbox': 'Debezium outbox router đọc WAL rồi phát CloudEvents; dòng đã gửi xóa sau 3 ngày. Không phân vùng vì khối lượng thấp (giả định khoảng 5.000 sự kiện mỗi ngày mỗi tỉnh vừa).',
    'shedlock': 'Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.',
}

RLS_TEXT = {
    'P': 'RLS mẫu P (FORCE): mọi thao tác chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_{t}_select`, `_insert`, `_update`, `_delete` (mục 1.2).',
    'S': 'RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; chỉ phiên `PLATFORM` được ghi dòng `COMMON` (mục 1.2).',
    'G': 'RLS mẫu G (FORCE): như mẫu P, đọc thêm dòng có `target_tenant` bằng tenant phiên để tỉnh bị truy cập thấy quyền đang mở vào mình; ghi chỉ ở tenant của người nhận quyền (mục 1.2).',
}


def ds(lst):
    return '; '.join(lst) if lst else 'Không'


def idx_text(i):
    s = '`%s` (%s)' % (i['name'], i['cols'])
    if i['using']:
        s += ' ' + i['using'].upper()
    if i['where']:
        s += ' khi %s' % i['where']
    return s


def khoi(t, info):
    pk = [b for n, k, b in info['constraints'] if k == 'PRIMARY KEY']
    uq = ['`%s` %s' % (n, b) for n, k, b in info['constraints'] if k == 'UNIQUE' and not n.endswith('_id_tenant')]
    uq += [idx_text(i) for i in info['unique_indexes']]
    fk = []
    for n, k, b in info['constraints']:
        if k != 'FOREIGN KEY':
            continue
        m = re.match(r'\(([^)]*)\) REFERENCES %s\.(\w+) ?\(([^)]*)\)(.*)' % ddl_parse.SCHEMA, b)
        if m:
            tgt = '`%s`' % m.group(2) + (' (chính bảng này)' if m.group(2) == t else '')
            fk.append('(%s) → %s%s' % (m.group(1), tgt, ' xóa theo' if 'CASCADE' in m.group(4) else ''))
        else:
            fk.append(b)
    ck = ['`%s`' % n for n, k, b in info['constraints'] if k == 'CHECK']
    ix = [idx_text(i) for i in info['indexes']]
    rls = info['rls']
    cl = RLS_TEXT[rls] if rls else 'Không bật RLS. Bảng kỹ thuật không có `tenant_id` và không chứa dữ liệu nghiệp vụ (mục 1.2).'
    guard = []
    for tg in info['triggers']:
        if tg['fn'] == 'tg_append_only':
            guard.append('Chỉ thêm, chặn UPDATE và DELETE (trigger `%s`)' % tg['name'])
        elif tg['fn'] == 'tg_no_delete':
            guard.append('Không xóa vật lý, kết thúc bằng trạng thái (trigger `%s`, BR-12-035)' % tg['name'])
        elif tg['fn'] not in ('tg_touch',):
            guard.append('Trigger nghiệp vụ `%s` (hàm `%s`)' % (tg['name'], tg['fn']))
    mo_ta = info['comment'].strip()
    mo_ta = mo_ta.rstrip('.')
    muc = [('Mục đích', mo_ta), ('FR phục vụ', FR_BANG.get(t, 'Hạ tầng dùng chung')),
           ('Khóa chính', ds(pk)), ('Duy nhất', ds(uq)), ('Khóa ngoại', ds(fk)),
           ('Ràng buộc CHECK', ds(ck)), ('Chỉ mục', ds(ix) if ix else 'Chỉ khóa chính và khóa duy nhất'),
           ('Cách ly tenant', cl), ('Phân vùng, chỉ thêm', ('Không phân vùng (bảng nhỏ); ' + '; '.join(guard)) if guard else 'Không phân vùng (bảng nhỏ); cho sửa, không có trigger chặn'),
           ('Ghi chú', GHI_CHU.get(t, 'Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.'))]
    o = ['::: dac-ta']
    for k, v in muc:
        v = v.strip()
        if v and not v.endswith('.'):
            v += '.'
        o += ['**%s.** %s' % (k, v), '']
    o[-1] = ':::'
    return '\n'.join(o)


def main():
    f = sys.argv[1]
    tables = ddl_parse.parse_all()
    s = open(f, encoding='utf-8').read()
    parts = re.split(r'(?m)^(### 3\.\d+\. `(\w+)`[^\n]*\n)', s)
    out, i, n = [parts[0]], 1, 0
    while i < len(parts):
        head, ten, body = parts[i], parts[i + 1], parts[i + 2]
        info = tables.get(ten)
        if info:
            # bỏ khối đặc tả cũ (nếu có) và đoạn mô tả đứng ngay sau tiêu đề, rồi chèn khối mới
            body = re.sub(r'\A\s*::: dac-ta\n.*?\n:::\n', '', body, count=1, flags=re.S)
            m = re.match(r'\s*([^|\n:#<][^\n]*)\n', body)
            if m and m.group(1).strip().rstrip('.') == info['comment'].strip().rstrip('.'):
                body = body[m.end():]
            body = '\n' + khoi(ten, info) + '\n' + body
            if not re.search(r'(?m)^: Cột của bảng `%s`' % ten, body):
                body = re.sub(r'(?m)(^\| Cột [^\n]*\n(?:\|[^\n]*\n)+)', lambda x: x.group(1) + '\n: Cột của bảng `%s`\n' % ten, body, count=1)
            n += 1
        out.append(head + body)
        i += 3
    open(f, 'w', encoding='utf-8').write(''.join(out))
    print('đã thêm khối đặc tả cho', n, 'bảng')


if __name__ == '__main__':
    main()
