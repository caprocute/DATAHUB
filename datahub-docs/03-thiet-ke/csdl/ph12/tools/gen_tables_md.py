#!/usr/bin/env python3
"""Sinh bảng mô tả cột (Markdown) cho chương 3 của D03-03-PH12 từ ddl/ph12_iam_0*.sql.

Chạy (từ datahub-docs):
  python3 03-thiet-ke/csdl/ph12/tools/gen_tables_md.py > /tmp/tables.md            # in ra màn hình
  python3 03-thiet-ke/csdl/ph12/tools/gen_tables_md.py --ghi 03-thiet-ke/csdl/D03-03-PH12-csdl-dinh-danh-phan-quyen.md
Với --ghi, công cụ thay phần nằm giữa hai dấu <!-- gen:tables:start --> và <!-- gen:tables:end --> của tệp.

Mỗi bảng được ghi: tiêu đề `### 3.n. tên_bảng`, đoạn mô tả lấy từ COMMENT ON TABLE, bảng cột (kiểu, bắt buộc, mặc
định, ghi chú). Ghi chú lấy từ COMMENT ON COLUMN; cột không có COMMENT thì dùng ghi chú chuẩn (cột ngữ cảnh D00-01
§5.1) hoặc suy ra từ CHECK đặt tên ck_{bảng}_{cột} (tập giá trị, mẫu chuỗi). Khối đặc tả 10 mục thêm sau bằng
them_dac_ta_bang.py. Sửa ở DDL rồi sinh lại, không sửa tay phần giữa hai dấu.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ddl_parse  # noqa: E402

STD = {
    'id': 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).',
    'tenant_id': 'Mã tenant `T{nn}` hoặc `PLATFORM` (`COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép.',
    'created_at': 'Thời điểm tạo.',
    'created_by': 'Người tạo (mã người dùng hoặc `system:*`).',
    'updated_at': 'Thời điểm sửa cuối (trigger `tg_touch`).',
    'updated_by': 'Người sửa cuối.',
    'version': 'Khóa lạc quan; thành phần của ETag (`If-Match`, ERR-12-044).',
    # Ghi chú chung cho cột cùng tên ở nhiều bảng; COMMENT ON COLUMN của bảng cụ thể được ưu tiên.
    'submitted_by': 'Người gửi duyệt (mã người dùng).',
    'submitted_at': 'Thời điểm gửi duyệt.',
    'approved_by': 'Người duyệt; khác người đề nghị hoặc người soạn (bốn mắt, CHECK).',
    'approved_at': 'Thời điểm duyệt.',
    'proposed_by': 'Người đề nghị.',
    'requested_by': 'Người đề nghị.',
    'decided_at': 'Thời điểm quyết định (duyệt, từ chối, thu hồi).',
    'decision_note': 'Ý kiến của người quyết định.',
    'review_note': 'Ý kiến của người duyệt.',
    'revoked_by': 'Người thu hồi.',
    'revoked_at': 'Thời điểm thu hồi.',
    'revoked_reason': 'Lý do thu hồi (bắt buộc khi thu hồi).',
    'reason': 'Lý do (bắt buộc, độ dài tối thiểu theo CHECK).',
    'expires_at': 'Thời điểm hết hiệu lực.',
    'valid_from': 'Hiệu lực từ.',
    'valid_to': 'Hiệu lực đến; rỗng là không thời hạn.',
    'published_at': 'Thời điểm có hiệu lực (PUBLISHED).',
    'git_commit': 'Mã commit ở kho Git cấu hình hoặc `dh-policies` để truy vết.',
    'name': 'Tên hiển thị.',
    'description': 'Mô tả.',
    'code': 'Mã nghiệp vụ, duy nhất trong tenant.',
    'activated_at': 'Thời điểm kích hoạt lần đầu.',
    'disabled_at': 'Thời điểm vô hiệu.',
    'disabled_note': 'Ghi chú của người vô hiệu.',
    'sync_state': 'Trạng thái đồng bộ với Keycloak: PENDING (ghi ý định, chưa tạo), SYNCED, FAILED.',
    'full_name': 'Họ tên đầy đủ (dữ liệu cá nhân, mục 5).',
    'email': 'Thư điện tử công vụ (dữ liệu cá nhân, mục 5); duy nhất trong tenant, không phân biệt hoa thường.',
    'username': 'Tên đăng nhập; duy nhất trong tenant, không phân biệt hoa thường.',
    'title': 'Chức danh.',
    'manager_user_id': 'Người quản lý trực tiếp; người rà soát quyền mặc định (FR-12-018).',
    'federation_id': 'Liên kết LDAP, AD là nguồn xác thực khi `auth_source = LDAP`.',
    'detail': 'Chi tiết dạng JSON, không chứa bí mật (CHECK).',
    'payload': 'Nội dung dạng JSON, không chứa khóa bí mật (CHECK).',
}


def cell(s):
    return s.replace('|', '\\|').replace('\n', ' ')


def render(tables):
    out = []
    for i, (t, info) in enumerate(tables.items(), 1):
        out.append('### 3.%d. `%s`\n' % (i, t))
        if info['comment']:
            out.append(info['comment'].rstrip() + '\n')
        enums, pats = ddl_parse.enum_and_pattern(t, info)
        out.append('| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |')
        out.append('|---|---|---|---|---|')
        for c in info['cols']:
            n = c['name']
            note = info['col_comments'].get(n) or STD.get(n, '')
            extra = []
            if n in enums:
                extra.append('Một trong: ' + ', '.join('`%s`' % v for v in enums[n]) + '.')
            if n in pats:
                extra.append('Mẫu `%s`.' % pats[n])
            if c['generated']:
                extra.append('Cột sinh (STORED): `%s`.' % ' '.join(c['generated'].split()))
            note = ' '.join(x for x in [note.strip()] + extra if x)
            default = ('`%s`' % c['default']) if c['default'] else ''
            out.append('| `%s` | `%s` | %s | %s | %s |' % (n, c['type'], 'Có' if c['not_null'] else 'Không', cell(default), cell(note)))
        out.append('')
        out.append(': Cột của bảng `%s`\n' % t)
    return '\n'.join(out)


def main():
    tables = ddl_parse.parse_all()
    md = render(tables)
    if len(sys.argv) >= 3 and sys.argv[1] == '--ghi':
        f = sys.argv[2]
        s = open(f, encoding='utf-8').read()
        a, b = '<!-- gen:tables:start -->', '<!-- gen:tables:end -->'
        i, j = s.index(a), s.index(b)
        s = s[:i + len(a)] + '\n' + md.rstrip() + '\n' + s[j:]
        open(f, 'w', encoding='utf-8').write(s)
        print('đã ghi %d bảng vào %s' % (len(tables), f))
    else:
        sys.stdout.write(md)


if __name__ == '__main__':
    main()
