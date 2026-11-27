#!/usr/bin/env python3
"""Sinh tập chính D03-04-PH20 từ OpenAPI, AsyncAPI và FRS. Chạy từ api/ph20:  python3 tools/gen_md.py
Sau đó chạy build/tools/sinh_dac_ta_api.py để điền chương 4 (đã có cặp đánh dấu gen:dac-ta-api)."""
import os
import re
import sys
from collections import defaultdict, OrderedDict

import yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec_ops
from spec_ops import ROOT, ERR, FRS, CAT, frs_text
import gen_asyncapi as ga

MD = os.path.abspath(os.path.join(ROOT, '..', 'D03-04-PH20-api-quan-tri-tenant.md'))
oa = yaml.safe_load(open(os.path.join(ROOT, 'openapi-ph20.yaml'), encoding='utf-8'))

ops = []
for path, item in oa['paths'].items():
    for m, op in item.items():
        if m in ('get', 'post', 'put', 'patch', 'delete'):
            names = {(p.get('$ref') or '').split('/')[-1] for p in op.get('parameters', [])}
            ok = [c for c in op['responses'] if c.startswith('2')][0]
            ops.append(dict(id=int(op['x-datahub-id'][-3:]), m=m.upper(), path=path, op=op, tag=op['tags'][0], I='IdempotencyKey' in names, M='IfMatch' in names, ok=ok,
                            frs=[int(x[-3:]) for x in op['x-datahub-fr']], perm=op['x-datahub-permission']['permission'], errs=op['x-datahub-errors']))
ops.sort(key=lambda o: o['id'])
OPS = {o['id']: o for o in ops}
GROUPS = OrderedDict([('platform', '/api/platform/v1'), ('tenant', '/api/tenant/v1'), ('internal', '/internal/tenant/v1')])


def grp(o):
    return 'platform' if o['path'].startswith('/api/platform') else 'tenant' if o['path'].startswith('/api/tenant') else 'internal'


def rng(ids):
    ids = sorted(ids)
    out, i = [], 0
    while i < len(ids):
        j = i
        while j + 1 < len(ids) and ids[j + 1] == ids[j] + 1:
            j += 1
        out.append(f'{ids[i]:03d}' if i == j else (f'{ids[i]:03d}, {ids[j]:03d}' if j == i + 1 else f'{ids[i]:03d}…{ids[j]:03d}'))
        i = j + 1
    return ', '.join(out)


cnt = {g: sum(1 for o in ops if grp(o) == g) for g in GROUPS}
n_ops, n_i, n_m = len(ops), sum(o['I'] for o in ops), sum(o['M'] for o in ops)
n_get = sum(1 for o in ops if o['m'] == 'GET')
fr_names = {int(a): b.strip() for a, b in re.findall(r'^#### FR-20-(\d{3}) · (.*)$', frs_text, re.M)}
err_rows = [(k, v) for k, v in ERR.items()]
err_ops = defaultdict(list)
for o in ops:
    for e in o['errs']:
        err_ops[e].append(o['id'])
perm_ops = defaultdict(list)
for o in ops:
    p = re.search(r'PERM-20-[a-z-]+', o['perm'])
    perm_ops[p.group(0) if p else ('scope:' + o['perm'].split()[-1] if o['perm'].startswith('Scope') else 'khac')].append(o['id'])
EVT = {k: (t, d, recv, fr) for k, t, d, recv, fr in []}
evt_fr = dict(re.findall(r'^\| (EVT-20-\d{2}) \| `[^`]+` \| [^|]+ \| [^|]+ \| ([^|]+) \|', frs_text.split('### 9.3. Sự kiện')[1].split('### 9.4.')[0], re.M))

L = []
W = L.append


def table(head, rows, caption):
    W('| ' + ' | '.join(head) + ' |')
    W('|' + '|'.join('---' for _ in head) + '|')
    for r in rows:
        W('| ' + ' | '.join(str(c).replace('|', '\\|') for c in r) + ' |')
    W('')
    W(': ' + caption)
    W('')


# ------------------------------------------------------------------------------------------------ đầu tệp
W('---')
W('ma_tai_lieu: D03-04-PH20')
W('ten: Thiết kế giao diện lập trình Quản trị tenant và phát hành sản phẩm')
W('phien_ban: 0.1')
W('ngay: 2026-11-27')
W('trang_thai: Dự thảo')
W('nguoi_doc: Kỹ sư dh-platform, kỹ sư tích hợp các phân hệ gọi PH-20, kỹ sư console quản trị, kiểm thử viên, hội đồng thẩm định')
W('phan_he: PH-20')
W(f'mo_ta: Hợp đồng giao tiếp của phân hệ Quản trị tenant và phát hành sản phẩm gồm {n_ops} operation REST ở ba nhóm đường dẫn nền tảng, tỉnh và nội bộ, 16 sự kiện phát và 6 sự kiện tiêu thụ, quy ước chung, bảng mã lỗi RFC 9457, sơ đồ trình tự saga, sáp nhập và báo tiến độ bất đồng bộ, ca rò rỉ chéo tenant, truy vết với FR và đề nghị đồng bộ.')
W('tai_lieu_lien_quan: D02-03-PH20 FRS; D03-03-PH20 CSDL; D03-06-PH20 Màn hình; D03-10 Thiết kế đa tenant; D03-04-PH12; D03-04-PH13; D03-04-PH03; D03-04-PH10; D03-04-PH16; D05-02-PH20 Test case')
W('---')
W('')
W('# D03-04-PH20 · Thiết kế giao diện lập trình Quản trị tenant và phát hành sản phẩm')
W('')
W('## Tóm tắt cho hội đồng thẩm định')
W('')
W(f'Tập này là hợp đồng giao tiếp của PH-20 Quản trị tenant và phát hành sản phẩm: nơi quản trị nền tảng khai báo và khởi tạo một tỉnh mới, đặt hạn mức, tạm ngừng, chấm dứt, sáp nhập tỉnh khi sắp xếp đơn vị hành chính, phát hành phiên bản mới theo sóng, và nơi quản trị tỉnh tự quản cài đặt, danh mục tổ chức, xem sử dụng tài nguyên. Hợp đồng chia ba nhóm đường dẫn: **{cnt["platform"]}** operation ở `/api/platform/v1` (chỉ vai trò nền tảng), **{cnt["tenant"]}** ở `/api/tenant/v1` (tenant lấy từ token), **{cnt["internal"]}** ở `/internal/tenant/v1` (phân hệ khác, mTLS và scope dịch vụ), tổng **{n_ops}** operation API-20-001…171, đúng mã, phương thức, đường dẫn và quyền của FRS D02-03-PH20 mục 9.4. Kèm **16 sự kiện phát** EVT-20-01…16, **6 sự kiện tiêu thụ** và **{len(ERR)} mã lỗi** ERR-20 theo RFC 9457.')
W('')
W('Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:')
W('')
W('- [`ph20/openapi-platform.yaml`](ph20/openapi-platform.yaml), [`ph20/openapi-tenant.yaml`](ph20/openapi-tenant.yaml), [`ph20/openapi-internal.yaml`](ph20/openapi-internal.yaml): OpenAPI 3.1 theo ba nhóm; [`ph20/openapi-ph20.yaml`](ph20/openapi-ph20.yaml) là bản gộp đủ 171 operation dùng để sinh chương 4. Mỗi operation có `operationId`, `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`, ví dụ yêu cầu và phản hồi khớp lược đồ theo [`check_contracts.py`](ph20/tools/check_contracts.py); Spectral (`build/tools/spectral.yaml`) không có lỗi.')
W('- [`ph20/asyncapi-ph20.yaml`](ph20/asyncapi-ph20.yaml): AsyncAPI 3.0, 22 kênh (16 phát, 6 nhận), CloudEvents 1.0 chế độ nhị phân với tiêu đề `ce_dhtenant`, 22 ví dụ khớp payload; Spectral không có lỗi.')
W('')
W('Sáu nguyên tắc hợp đồng:')
W('')
W('1. **Tenant lấy từ token, không từ đường dẫn hay thân.** Riêng nhóm nền tảng, `tenantCode` ở đường dẫn là tenant bị tác động; mọi thao tác ghi của quản trị nền tảng vào tenant tỉnh bắt buộc có `reason` (từ 20 ký tự) và `ticketRef`, ghi kiểm toán vào chuỗi của tenant bị tác động (ERR-20-008).')
W('2. **Đối tượng của tenant khác trả `404` ERR-20-002, không trả `403`,** để không lộ sự tồn tại; kiểm thử rò rỉ chéo tenant chạy hằng đêm bằng API-20-132 (chương 8).')
W('3. **Mọi `POST` ghi có `Idempotency-Key`, mọi `PUT`, `PATCH` và hành động trên đối tượng có phiên bản có `If-Match`** (ERR-20-005, ERR-00-428); có ' + f'{n_i} operation chống trùng và {n_m} operation khóa lạc quan.')
W('4. **Tác vụ dài trả `202` và theo dõi được:** saga khởi tạo, chuyển dữ liệu sáp nhập, gói bàn giao, báo cáo sử dụng, nâng cấp theo sóng; tiến độ bước bất đồng bộ do phân hệ báo về bằng API-20-166, 167, 168 (chương 7).')
W('5. **Thao tác không đảo ngược được cần hai quản trị nền tảng khác nhau** (chấm dứt, sáp nhập, đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng): API duyệt trả ERR-20-007 nếu người duyệt là người đề nghị.')
W('6. **PH-20 điều phối, không tự thực thi:** hạn mức, trạng thái tạm ngừng, chuyển tiếp sáp nhập được đẩy xuống PH-03, PH-04, PH-10, PH-12 qua sự kiện và API đọc `/internal`; chuyển dữ liệu sáp nhập do PH-18 chạy theo hợp đồng `merge-transfers`.')
W('')
W('Căn cứ: FRS D02-03-PH20 mục 9 và Phụ lục A, CSDL D03-03-PH20 (schema `ph20_tenant`, tên trường dạng camelCase ở API), D03-10 mục 5. Mọi tên miền, mã tenant (`T68`, `T90`, `T91`), dữ liệu trong ví dụ là giả lập. Các giả định ghi rõ ở từng mục và tổng hợp ở Phụ lục A.')
W('')

# ------------------------------------------------------------------------------------------------ 1
W('## 1. Giới thiệu')
W('')
W('### 1.1. Mục đích')
W('')
W('Tài liệu đặc tả mặt giao tiếp của PH-20 đủ để kỹ sư `dh-platform` hiện thực module `tenant` và `release`, kỹ sư console hiện thực màn UI-20-01…22, kỹ sư các phân hệ PH-01, 03, 04, 06, 07, 09, 10, 12, 13, 16, 18, 19 tích hợp (nghe sự kiện, đọc registry, báo tiến độ), và kiểm thử viên viết ca kiểm thử hợp đồng cùng ca rò rỉ chéo tenant.')
W('')
W('### 1.2. Phạm vi')
W('')
W('Gồm API REST của ba nhóm, sự kiện Kafka phát và nhận, quyền, scope máy, mã lỗi, sơ đồ trình tự. Không gồm: hành vi nghiệp vụ chi tiết (FRS D02-03-PH20), cấu trúc bảng (D03-03-PH20), màn hình (D03-06-PH20), API của phân hệ khác mà PH-20 gọi ra (nằm ở tập API của phân hệ đó, tổng hợp ở mục 2.10), cơ chế thực thi hạn mức ở APISIX (PH-03), tham số `20.*` do PH-18 sở hữu (PH-20 chỉ đọc giá trị hiệu lực ở API-20-131).')
W('')
W('### 1.3. Đối tượng sử dụng và cách đọc')
W('')
table(['Người đọc', 'Đọc mục', 'Mục đích'], [
    ['Hội đồng thẩm định', 'Tóm tắt, 2.1 đến 2.4, 8, Phụ lục A', 'Nắm nguyên tắc tách tenant, bốn mắt, lũy đẳng, các điểm lệch với FRS'],
    ['Kỹ sư `dh-platform`', '2, 3, 4, 6', 'Hiện thực operation, mã lỗi, khóa lạc quan, chống trùng'],
    ['Kỹ sư console quản trị', '2.4, 3, 4, 7.2', 'Gọi API, theo dõi saga bằng SSE, xử lý `202`'],
    ['Kỹ sư phân hệ khác', '2.10, 5, 7.2, 4 (nhóm `/internal`)', 'Nghe sự kiện, đọc registry và tổ chức, báo tiến độ bước saga'],
    ['Kiểm thử viên', '4, 6, 8, 9', 'Ca hợp đồng, ca lỗi, ca rò rỉ chéo tenant, ma trận FR và API'],
], 'Người đọc và mục nên đọc')
W('### 1.4. Thuật ngữ và chữ viết tắt')
W('')
table(['Thuật ngữ', 'Giải thích'], [
    ['Tenant (`tenantCode`)', 'Một tỉnh dùng Datahub, mã dạng `T68`; hai tenant đặc biệt `PLATFORM` và `COMMON` được bảo vệ khỏi mọi thao tác vòng đời (ERR-20-010)'],
    ['Saga khởi tạo (`runId`)', 'Lần chạy 17 bước `S01_RECORD` … `S17_ACTIVATE` tạo mọi tài nguyên của một tenant; mỗi bước lũy đẳng với `{runId}:{stepCode}`, có bù trừ'],
    ['Bước bất đồng bộ', 'Bước do phân hệ khác thực hiện (`S06`, `S09`, `S10`, `S12`, `S15`); PH-20 phát sự kiện rồi chờ phân hệ báo qua API-20-166, quá `20.provision.step-timeout-minutes` thì `FAILED` (ERR-20-106)'],
    ['Đề nghị có duyệt', 'Đối tượng `LifecycleRequest` hoặc `QuotaChangeRequest` đi qua `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, thực hiện; người duyệt khác người đề nghị (bốn mắt)'],
    ['Kế hoạch sáp nhập (`mergePlanId`)', 'Mã dạng `SN-2026-001` gom tenant nguồn, tenant đích, bảng ánh xạ, chạy thử, chuyển dữ liệu theo phân hệ, cutover, chuyển tiếp'],
    ['Bên tham gia sáp nhập', 'Phân hệ có dữ liệu theo tenant, cung cấp xuất, nhập, kiểm đếm theo gói; PH-18 chạy công cụ chuyển, PH-20 điều phối (ADR 202 đề xuất)'],
    ['Cutover và chuyển tiếp', 'Tenant nguồn sang `MERGED` chỉ đọc, lượt gọi cũ được APISIX chuyển sang tenant đích kèm tiêu đề `Deprecation` và `Sunset` trong thời gian chuyển tiếp'],
    ['Kênh phát hành', '`STABLE` và `PREVIEW`; bản `STABLE` chỉ nhận sau ít nhất `20.release.stable-soak-days` ngày chạy ở tenant thí điểm'],
    ['Sóng nâng cấp', 'Nhóm tenant nâng cấp cùng lúc, cách nhau `soakHours`, trong cửa sổ bảo trì của từng tỉnh, tự dừng khi tỷ lệ lỗi vượt `20.release.wave-error-threshold-percent`'],
    ['Kho `dh-tenant-config`', 'Kho Git GitOps giữ cấu hình tenant làm trạng thái mong muốn, mỗi tenant một thư mục; Argo CD áp (ADR 201 đề xuất)'],
    ['`ce_dhtenant`', 'Thuộc tính mở rộng CloudEvents `dhtenant` mang mã tenant bị tác động, đặt ở tiêu đề Kafka'],
    ['PA, PO, PAU, TA, TO, SO, AU, DS, VW', 'Vai trò theo D02-08: quản trị, vận hành, kiểm toán nền tảng; quản trị, vận hành tỉnh, cán bộ an toàn thông tin, kiểm toán viên, cán bộ dữ liệu, người xem'],
], 'Thuật ngữ và chữ viết tắt của tập API PH-20')
W('### 1.5. Tài liệu tham chiếu')
W('')
W('FRS D02-03-PH20 (nguồn chuẩn mã FR, ERR, EVT, PERM, liệt kê ở Phụ lục A, danh mục API ở mục 9.4, tham số ở mục 8.2); CSDL D03-03-PH20 (`ph20_tenant.sql`, tên cột chuyển sang camelCase ở API); D03-10 Thiết kế đa tenant (mục 5 vòng đời tenant, saga); D02-08 (ma trận quyền, vai trò); D00-04 (sổ tra cứu gọn, khuôn lỗi); D03-04-PH16 (mẫu tập API); D03-04-PH12, PH13, PH07, PH10, PH03, PH16, PH18 (API mà PH-20 gọi hoặc nghe). Không có SRS cũ cho PH-20 (REQ-20 là năng lực mới).')
W('')
W('### 1.6. Cấu trúc tài liệu')
W('')
W('Chương 2 nêu nguyên tắc chung (đường dẫn, xác thực, tenant, lỗi, lũy đẳng, phiên bản, phân trang, giới hạn tốc độ). Chương 3 là bảng tổng hợp 171 API. Chương 4 là đặc tả từng endpoint, sinh tự động từ OpenAPI. Chương 5 là sự kiện. Chương 6 là bảng mã lỗi. Chương 7 là sơ đồ trình tự saga, báo tiến độ bất đồng bộ, sáp nhập. Chương 8 là ca rò rỉ chéo tenant. Chương 9 truy vết API và FR. Chương 10 là câu hỏi mở Q20-55…59. Phụ lục A là đề nghị đồng bộ.')
W('')

# ------------------------------------------------------------------------------------------------ 2
W('## 2. Nguyên tắc chung')
W('')
W('### 2.1. Ba nhóm đường dẫn')
W('')
W('Ba nhóm khác nhau về người gọi, cách xác thực, nơi truy cập và phạm vi tenant; không có đường dẫn dùng chung giữa các nhóm.')
W('')
table(['Nhóm', 'Gốc đường dẫn', 'Số operation', 'Người gọi', 'Xác thực', 'Phạm vi tenant', 'Nơi truy cập'], [
    ['Nền tảng', '`/api/platform/v1`', cnt['platform'], 'PA, PO, PAU ở tenant `PLATFORM`; tài khoản dịch vụ của nền tảng', 'OIDC (WebAuthn bắt buộc với vai trò nền tảng), quyền `PERM-20-*`', 'Tenant bị tác động nêu ở `{tenantCode}`; mọi thao tác ghi cần `reason`, `ticketRef`', 'Console nền tảng qua BFF, không mở ra cổng công khai'],
    ['Tỉnh tự quản', '`/api/tenant/v1`', cnt['tenant'], 'TA, TO, SO, AU, DS, VW của tỉnh', 'OIDC realm của tỉnh, quyền `PERM-20-*`', 'Lấy từ claim `tenant` của token, không có `tenantCode` ở đường dẫn hay thân', 'Console của tỉnh qua BFF'],
    ['Nội bộ', '`/internal/tenant/v1`', cnt['internal'], 'Phân hệ khác (PH-01, 03, 04, 06, 07, 08, 10, 12, 16, 18, 19…), APISIX plugin', 'OAuth 2.1 client credentials, mTLS trong mesh, scope `tenant:*`', 'Registry theo `tenantCode` ở đường dẫn, tổ chức theo tenant ngữ cảnh của thông tin xác thực', 'Chỉ trong mesh `dh-control` (Z3), không qua cổng công khai'],
], 'Ba nhóm đường dẫn của PH-20')
W('Hành động trên tài nguyên dùng hậu tố `:{hành-động}` (ví dụ `:approve`, `:check-readiness`, `:report`), theo quy ước chung của các tập API. Đường dẫn dùng tiếng Anh không dấu dạng `kebab-case`; tên trường dùng `camelCase`; giá trị liệt kê dùng `UPPER_SNAKE_CASE` theo Phụ lục A của FRS.')
W('')

W('### 2.2. Xác thực và phân quyền')
W('')
W('Người dùng đăng nhập OIDC với PKCE qua BFF của console, token không ra trình duyệt; vai trò nền tảng bắt buộc WebAuthn. Máy gọi máy dùng OAuth 2.1 `client_credentials` kèm mTLS, token Keycloak của realm `dh-platform` (ADR-006). Máy chủ kiểm quyền theo từng yêu cầu, không tin lời khai của giao diện.')
W('')
roles = {'PERM-20-read': 'PA, PO, PAU; TA, AU chỉ phần của tỉnh mình', 'PERM-20-admin': 'PA', 'PERM-20-provision': 'PA', 'PERM-20-lifecycle': 'PA', 'PERM-20-approve': 'PA (không tự duyệt)',
         'PERM-20-quota': 'PA', 'PERM-20-merge': 'PA', 'PERM-20-release': 'PA; PO chỉ theo dõi và dừng sóng', 'PERM-20-settings': 'TA', 'PERM-20-org': 'TA', 'PERM-20-org-read': 'Mọi vai trò tỉnh, PA, PO, PAU',
         'PERM-20-usage-read': 'TA, TO, AU'}
rows = []
for p in ['PERM-20-read', 'PERM-20-admin', 'PERM-20-provision', 'PERM-20-lifecycle', 'PERM-20-approve', 'PERM-20-quota', 'PERM-20-merge', 'PERM-20-release', 'PERM-20-settings', 'PERM-20-org', 'PERM-20-org-read', 'PERM-20-usage-read']:
    rows.append([f'`{p}`', roles[p], len(perm_ops[p]), rng(perm_ops[p])])
table(['Quyền', 'Vai trò', 'Số operation', 'Operation (số API-20-)'], rows, 'Quyền người dùng và operation tương ứng')
W('D02-08 hiện có `PERM-20-admin` và `PERM-20-read`; mười quyền còn lại là đề nghị của FRS (Phụ lục A). Operation `API-20-142` cho mọi người dùng đã đăng nhập; `API-20-161` cho TA và AU của tỉnh; `API-20-137`, `API-20-139` cho TA ghi và SO, AU đọc (xem Phụ lục A về quyền đọc của SO, AU).')
W('')
table(['Scope máy', 'Bên giữ', 'Operation', 'Ghi chú'], [
    ['`tenant:registry-read`', 'Mọi DU, plugin APISIX của PH-03, PH-12, tác vụ nền', rng(perm_ops['scope:tenant:registry-read']), 'Registry, cấu hình thực thi, chính sách liên tenant; đệm tối đa `20.registry.cache-seconds`'],
    ['`tenant:org-read`', 'PH-01, 06, 07, 08, 12, 16', rng(perm_ops['scope:tenant:org-read']), 'Chỉ tổ chức của tenant trong thông tin xác thực máy'],
    ['`tenant:provision-report`', 'Phân hệ tham gia saga, PH-18, phân hệ xuất gói', rng(perm_ops['scope:tenant:provision-report']), 'Báo tiến độ bước saga, chuyển sáp nhập, xuất gói; chỉ bên thực hiện của bước (ERR-20-104)'],
], 'Scope máy do PH-20 cấp cho phân hệ khác')
W('Scope PH-20 dùng khi gọi ra: `iam:realm-provision` (PH-12), `obs:tenant-provision` (PH-13), `platform.tenant.provision` (PH-07, giả định của PH-07), `event:topic-register` (PH-10), `kpi.ingest` (PH-16); chi tiết ở mục 2.10.')
W('')

W('### 2.3. Tenant từ token và tách nhiệm vụ')
W('')
table(['Quy tắc', 'Nội dung', 'Mã lỗi khi vi phạm'], [
    ['Tenant từ token', 'Nhóm `/api/tenant/v1` và tổ chức nội bộ lấy tenant từ claim `tenant` hoặc thông tin xác thực máy; thân yêu cầu có `tenantCode` khác tenant của token bị bỏ qua và ghi cảnh báo', 'Không có (bỏ qua)'],
    ['Đối tượng của tenant khác', 'Đối tượng không thuộc tenant của người gọi trả `404`, không phân biệt với đối tượng không tồn tại', 'ERR-20-002'],
    ['Vai trò sai nhóm', 'TA, TO… gọi `/api/platform/v1`, hoặc PA gọi `/api/tenant/v1` để ghi dữ liệu của tỉnh, bị chặn ở lớp xác thực', 'ERR-00-403'],
    ['Tenant đặc biệt', '`PLATFORM`, `COMMON` không đổi trạng thái, không chấm dứt, không sáp nhập', 'ERR-20-010'],
    ['Lý do và mã phiếu', 'Mọi thao tác ghi của PA vào tenant tỉnh có `reason` từ `20.lifecycle.reason-min-length` ký tự và `ticketRef`; ghi kiểm toán vào chuỗi của tenant bị tác động (SEC-85)', 'ERR-20-008'],
    ['Bốn mắt', 'Người lập, gửi đề nghị chấm dứt, kế hoạch sáp nhập, đổi chế độ cách ly, hạ hạn mức khác người duyệt; người duyệt chấm dứt khác người xác nhận bàn giao', 'ERR-20-007'],
    ['Tenant tạm ngừng', 'Nhóm `/api/tenant/v1` trả `403` khi tenant `SUSPENDED`, trừ `API-20-142` (trả `readOnly`, `banner`); data plane và control plane thực thi (FR-20-066)', 'ERR-20-001'],
    ['Tenant `MERGED`', 'Tenant nguồn sau cutover chỉ đọc, ghi trả `409`', 'ERR-20-115'],
], 'Quy tắc tenant và tách nhiệm vụ áp dụng cho mọi operation')

W('### 2.4. Quy ước yêu cầu và phản hồi')
W('')
table(['Mục', 'Quy ước'], [
    ['Định dạng', 'JSON UTF-8 (`application/json`); lỗi `application/problem+json`; tệp xuất `XLSX`, `CSV`, `PDF`; luồng tiến độ `text/event-stream`; tải lên `multipart/form-data` (API-20-153)'],
    ['Thời gian, số', 'Thời điểm ISO 8601 có múi giờ (`+07:00`); ngày `YYYY-MM-DD`; kỳ báo cáo `M-2026-10`, `Q-2026-Q3`, `Y-2026`; số thập phân dùng dấu chấm, không bao quanh bằng nháy'],
    ['Khóa lạc quan', '`GET` đối tượng có phiên bản trả `ETag: W/"{n}"`; `PUT`, `PATCH` và hành động có `M` ở chương 3 cần `If-Match`; lệch trả `412` ERR-20-005, thiếu trả `428` ERR-00-428. Hành động không đổi trạng thái đối tượng (kiểm tra sẵn sàng, xem trước, báo tiến độ, tra hàng loạt) không có `If-Match`'],
    ['Chống trùng', f'`POST` có `I` ở chương 3 ({n_i} operation) bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ, so băm SHA-256 thân yêu cầu; cùng khóa cùng thân trả lại phản hồi cũ, khác thân trả `409` ERR-20-009. Năm `POST` chỉ đọc (API-20-005, 006, 033, 095, 171) không cần khóa'],
    ['Phân trang', 'Danh sách có `page` (từ 0) và `size` (1…200, mặc định 20; API-20-162 và API-20-169 tối đa 1.000); phản hồi `items`, `page`, `size`, `totalElements`; sắp xếp bằng `sort` nơi FRS nêu'],
    ['Tác vụ dài', 'Trả `202` kèm `Location` tới tài nguyên theo dõi (lần chạy, gói bàn giao, báo cáo, kế hoạch); trạng thái đọc bằng `GET`, tiến độ saga thời gian thực bằng SSE (API-20-016)'],
    ['Hành động', 'Hậu tố `:{hành-động}` trên tài nguyên hoặc tập; hành động đổi trạng thái trả đối tượng mới kèm `ETag` mới'],
    ['Tệp', 'Tải xuống API-20-062, 156 trả tệp trực tiếp kèm `Content-Disposition`; liên kết gói bàn giao hết hạn trả `410` ERR-20-039. Nhập tổ chức tối đa 10 MB và `20.org.import-max-rows` dòng'],
    ['Truy vết', '`traceparent` W3C xuyên APISIX, BFF, `dh-platform`, Kafka; mọi phản hồi lỗi có `traceId`'],
    ['Ngôn ngữ', '`Accept-Language: vi` (mặc định) hoặc `en` cho thông điệp lỗi; mã lỗi không đổi theo ngôn ngữ'],
    ['Tham số đường dẫn', 'Các `{…}` ở đường dẫn là bắt buộc; `{tenantCode}` theo `^T[0-9]{2}$`, `{moduleCode}` và `{module}` theo `^PH-[0-9]{2}$`, `{mergePlanId}` dạng `SN-2026-001`, các `{…Id}` là UUID; chương 4 không lặp lại'],
], 'Quy ước chung của API PH-20')

W('### 2.5. Lỗi RFC 9457')
W('')
W('Mọi lỗi trả `application/problem+json` theo RFC 9457 và D00-04, với `type` là `https://datahub.example.vn/errors/{code}`, `code` dạng `ERR-20-nnn`, `traceId`, và `errors[]` theo trường khi lỗi dữ liệu. Thiếu xác thực, thiếu quyền chức năng, thiếu `If-Match` dùng mã chung ERR-00-401, ERR-00-403, ERR-00-428. Bảng đầy đủ 86 mã ở chương 6.')
W('')
W('```http')
W('HTTP/1.1 409 Conflict')
W('Content-Type: application/problem+json')
W('')
W('{"type": "https://datahub.example.vn/errors/ERR-20-011", "title": "ĐVHC đã có tenant", "status": 409,')
W(' "code": "ERR-20-011", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",')
W(' "detail": "Đơn vị hành chính đã gắn với tenant T68.", "instance": "/api/platform/v1/tenants",')
W(' "errors": [{"field": "adminUnitId", "message": "Đã có tenant dùng đơn vị hành chính này.", "code": "ERR-20-011"}]}')
W('```')
W('')
W('Ví dụ lỗi khai báo tenant trùng đơn vị hành chính. Ba nhóm lỗi hay gặp: `422` do quy tắc nghiệp vụ (ERR-20-008, 013, 017, 029, 030), `409` do trạng thái hoặc trùng (ERR-20-003, 006, 011, 016, 067), `503` do phụ thuộc không khả dụng (ERR-20-062). Lỗi không có mã HTTP (ERR-20-106…113, 116, 117) chỉ ghi ở bước saga, lần chạy hoặc cảnh báo, không bao giờ nằm ở phản hồi của operation.')
W('')

W('### 2.6. Lũy đẳng')
W('')
W('`Idempotency-Key` là UUID do máy khách sinh, một khóa cho một ý định. Máy chủ lưu khóa theo cặp (client, phương thức, đường dẫn) trong bảng `idempotency_key` 24 giờ; cùng khóa cùng thân trả lại phản hồi đầu kể cả khi đang `IN_PROGRESS` (máy chủ chờ tối đa 30 giây rồi trả `409`), khác thân trả `409` ERR-20-009. Với saga, mỗi bước còn có khóa riêng `{runId}:{stepCode}` khi PH-20 gọi phân hệ khác, để thử lại không tạo tài nguyên đôi. Khi PA chọn "Lưu và khởi tạo", console gọi API-20-002 rồi API-20-013 với cùng khóa hậu tố `:run`. Máy khách nên giữ khóa và gửi lại khi mất phản hồi mạng.')
W('')
W('### 2.7. Phiên bản API')
W('')
W('Phiên bản `v1` ở đường dẫn; thay đổi phá vỡ (xóa trường, đổi nghĩa, đổi kiểu) sang `v2`, chạy song song tối thiểu 6 tháng, oasdiff ở CI chặn thay đổi phá vỡ trong `v1`. Thêm trường tùy chọn, thêm giá trị liệt kê ở phản hồi, thêm operation là tương thích; bên gọi phải bỏ qua trường lạ. Sự kiện `v1` tương thích BACKWARD ở Apicurio. Phiên bản sản phẩm Datahub (`releaseVersion` SemVer) độc lập với phiên bản API.')
W('')
W('### 2.8. Phân trang, lọc, sắp xếp')
W('')
W('Mọi `GET` danh sách nhận `page`, `size` và các bộ lọc nêu ở chương 4; bộ lọc mảng lặp tham số (`status=ACTIVE&status=SUSPENDED`). Danh sách tenant trả thêm `facets`, danh mục tổ chức trả thêm `tree` khi `view = TREE`, bảng ánh xạ trả thêm `summary`. Khoảng thời gian có giới hạn: sử dụng tối đa 400 ngày, kiểm toán và nhật ký liên tenant tối đa 366 ngày (ERR-20-032, 400). Xuất CSV danh sách tenant tối đa 1.000 dòng.')
W('')
W('### 2.9. Giới hạn tốc độ')
W('')
W('Giới hạn do APISIX (PH-03) thực thi, trả `429` kèm `Retry-After` và `RateLimit-Remaining`, không dùng mã ERR-20. Con số dưới đây là **giả định** theo quy mô mục tiêu 34 tenant (NFR-00-060) và tỉnh quy mô vừa 200 HTTT (GĐ-01…07), chờ chốt ở Q20-55.')
W('')
table(['Nhóm', 'Giới hạn đề xuất', 'Cơ sở giả định'], [
    ['`/api/platform/v1`', '300 yêu cầu mỗi phút mỗi tài khoản, ghi 60 mỗi phút; tối đa 5 luồng SSE mỗi người dùng', 'Một đội quản trị dưới 10 người, thao tác tay là chính'],
    ['`/api/tenant/v1`', '600 yêu cầu mỗi phút mỗi tenant và 120 mỗi phút mỗi người dùng; nhập tổ chức 6 lần mỗi phút', 'Một tỉnh khoảng 200 người dùng quản trị, danh mục tổ chức dưới 5.000 dòng'],
    ['`/internal/tenant/v1`', '3.000 yêu cầu mỗi phút mỗi client; tra hàng loạt (API-20-171) 60 mỗi phút', 'Phân hệ đọc có đệm `20.registry.cache-seconds` = 60, mỗi tenant khoảng vài chục lượt đọc mỗi phút'],
], 'Giới hạn tốc độ đề xuất của PH-20')

W('### 2.10. Lời gọi ra phân hệ khác')
W('')
W('Hợp đồng của phía bị gọi nằm ở tập API của phân hệ đó; PH-20 chỉ dựa vào các mã sau. Mỗi lời gọi mang `Idempotency-Key` bằng `{runId}:{stepCode}` (saga) hoặc `{mergePlanId}:{module}` (sáp nhập).')
W('')
table(['Phân hệ', 'Lời gọi', 'Scope hoặc kênh', 'Dùng ở'], [
    ['PH-12', 'API-12-080 tạo realm, client, vai trò; API-12-084, 085 tạm ngừng, khôi phục realm; API-12-045, 046 kế hoạch và thực hiện chuyển định danh', '`iam:realm-provision`', '`S03_REALM`, API-20-079, API-20-104'],
    ['PH-13', 'API-13-072 `POST /api/platform/v1/tenants/{tenantCode}/observability:provision`; API-13-073 đóng chuỗi kiểm toán', '`obs:tenant-provision`', '`S08_OBSERVABILITY`, bù trừ'],
    ['PH-07', 'API-07-073 `/api/platform/rdm/v1/tenants/{tenantId}:seed`', '`platform.tenant.provision`', '`S11_SEED_RDM`'],
    ['PH-10', 'Đăng ký topic `platform.tenant.*.v1`, `platform.release.*.v1`; nghe EVT-20-01', '`event:topic-register`', '`S06_EVENTING`'],
    ['PH-16', 'API-16-030 đẩy chỉ tiêu `ph20.tenant.provision-lead-time` (KPI-12)', '`kpi.ingest`', '`S17_ACTIVATE`'],
    ['PH-09', 'FR-09-043 xóa mật mã tenant (sau bàn giao, hai người duyệt); nhận EVT-09-21', 'mTLS mesh', 'API-20-079 chấm dứt'],
    ['PH-18', '`POST /api/ops/v1/merge-transfers` chuyển dữ liệu một phân hệ (giả định, Phụ lục A); `NotificationApi` gửi thư; đọc API-20-162', 'mTLS mesh', 'API-20-098, 128, `S17_ACTIVATE`'],
    ['OpenBao, Ceph RGW, Git, Argo CD', 'API của hạ tầng (không phải API Datahub)', 'Tài khoản dịch vụ `svc-ph20-gitops`', '`S02`, `S04`, `S05`, `S07`, API-20-040'],
], 'Lời gọi ra phân hệ khác của PH-20')

# ------------------------------------------------------------------------------------------------ 3
W('## 3. Bảng tổng hợp API')
W('')
W(f'Bảng tổng hợp sinh từ [`ph20/openapi-ph20.yaml`](ph20/openapi-ph20.yaml) bằng `gen_md.py`. Cột "FR" bỏ tiền tố `FR-20-`; cột "Khóa": `I` bắt buộc `Idempotency-Key`, `M` bắt buộc `If-Match`; cột "HTTP" là mã thành công. Có {n_ops} operation: {n_get} `GET`, {sum(1 for o in ops if o["m"]=="POST")} `POST`, {sum(1 for o in ops if o["m"]=="PUT")} `PUT`, {sum(1 for o in ops if o["m"]=="PATCH")} `PATCH`; {n_i} có `I`, {n_m} có `M`.')
W('')
tags_order = []
for o in ops:
    if o['tag'] not in tags_order:
        tags_order.append(o['tag'])
tagdesc = {t['name']: t['description'] for t in oa['tags']}
W('### 3.1. Tổng hợp theo nhóm chức năng')
W('')
rows = []
for t in tags_order:
    ids = [o['id'] for o in ops if o['tag'] == t]
    g = {grp(o) for o in ops if o['tag'] == t}.pop()
    rows.append([t, f'`{GROUPS[g]}`', len(ids), rng(ids), tagdesc[t]])
table(['Nhóm chức năng', 'Gốc', 'Số operation', 'Mã API-20-', 'Nội dung'], rows, 'Nhóm chức năng và operation của PH-20')
W('### 3.2. Danh mục endpoint')
W('')
sec = 0
for t in tags_order:
    sec += 1
    W(f'#### 3.2.{sec}. {t}')
    W('')
    rows = []
    for o in [x for x in ops if x['tag'] == t]:
        perm = re.sub(r'PERM-20-', '', o['perm']) if o['perm'].startswith('PERM') else ('scope ' + o['perm'].split()[-1] if o['perm'].startswith('Scope') else ('mọi người dùng' if 'Mọi' in o['perm'] else 'TA, AU'))
        rows.append([f'API-20-{o["id"]:03d}', o['m'], f'`{o["path"].replace("/api/platform/v1", "").replace("/api/tenant/v1", "").replace("/internal/tenant/v1", "") or "/"}`', ','.join(f'{f:03d}' for f in o['frs']),
                     perm, ('I' if o['I'] else '') + ('M' if o['M'] else '') or '-', o['ok']])
    W('Đường dẫn rút gọn, bỏ gốc `' + GROUPS[{grp(x) for x in ops if x['tag'] == t}.pop()] + '`.')
    W('')
    table(['Mã', 'PT', 'Đường dẫn', 'FR', 'Quyền', 'Khóa', 'HTTP'], rows, f'Các API nhóm {t}')

# ------------------------------------------------------------------------------------------------ 4
W('## 4. Đặc tả từng endpoint')
W('')
W('Chương này sinh tự động từ [`ph20/openapi-ph20.yaml`](ph20/openapi-ph20.yaml) bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục: mục đích, phương thức và đường dẫn, quyền, FR hiện thực, tham số, thân yêu cầu, chống trùng, phản hồi thành công, lỗi, ghi chú. Mã lỗi nêu ở mục "Lỗi" là tập mã operation có thể trả; ý nghĩa ở chương 6. Ví dụ yêu cầu và phản hồi nằm ở OpenAPI (không lặp lại ở đây để tài liệu gọn).')
W('')
W('<!-- gen:dac-ta-api:start -->')
W('<!-- gen:dac-ta-api:end -->')
W('')

# ------------------------------------------------------------------------------------------------ 5
W('## 5. Sự kiện')
W('')
W('Sự kiện qua outbox (`ph20_tenant.outbox`, cùng giao dịch nghiệp vụ) lên Kafka bằng Debezium, lược đồ JSON ở Apicurio mức BACKWARD, khóa phân vùng là mã đối tượng, không chứa dữ liệu cá nhân (BR-20-039). Hợp đồng máy đọc được ở [`ph20/asyncapi-ph20.yaml`](ph20/asyncapi-ph20.yaml).')
W('')
W('### 5.1. Sự kiện PH-20 phát')
W('')
rows = []
for code, cname, topic, data, key, recv, desc in ga.OUTS:
    rows.append([code, f'`{topic}`', f'`{key}`', recv, evt_fr.get(code, '').strip(), f'`{data}`'])
table(['Mã', 'Topic', 'Khóa phân vùng', 'Bên nhận chính', 'FR', 'Lược đồ dữ liệu'], rows, 'Sự kiện EVT-20-01…16 do PH-20 phát')
W('Sự kiện vòng đời tenant và phát hành đi trên tiền tố nền tảng `platform.` vì tenant mới chưa có tiền tố Kafka riêng (cùng cách PH-13 dùng `platform.obs.audit.recorded.v1`); sự kiện tổ chức EVT-20-13 đi trên `{tenant}.tenant.org.changed.v1`. Topic ghi ở bảng là tên đầy đủ, không thêm tiền tố môi trường.')
W('')
W('### 5.2. Khung CloudEvents')
W('')
table(['Thuộc tính', 'Tiêu đề Kafka', 'Giá trị'], [
    ['`specversion`', '`ce_specversion`', '`1.0`'],
    ['`id`', '`ce_id`', 'UUID v7, khóa lũy đẳng của bên tiêu thụ'],
    ['`source`', '`ce_source`', '`/datahub/dh-platform/tenant`'],
    ['`type`', '`ce_type`', '`vn.datahub.{topic bỏ .v1}.v1`, ví dụ `vn.datahub.platform.tenant.created.v1`'],
    ['`time`', '`ce_time`', 'Thời điểm phát sinh ISO 8601'],
    ['`subject`', '`ce_subject`', 'Khóa phân vùng: `tenantCode`, `mergePlanId`, `orgCode` hoặc `releaseVersion`'],
    ['`dhtenant`', '`ce_dhtenant`', 'Mã tenant bị tác động (`T68`); `PLATFORM` với sự kiện cấp nền tảng (EVT-20-14); với sáp nhập là tenant đích'],
    ['`dataschema`', '`ce_dataschema`', 'Lược đồ ở Apicurio'],
    ['`traceparent`', '`traceparent`', 'Ngữ cảnh truy vết W3C'],
], 'Khung CloudEvents chế độ nhị phân của sự kiện PH-20')
W('Thân Kafka là JSON của `data` (lược đồ ở cột cuối bảng 5.1). Thứ tự bảo đảm theo khóa phân vùng: các sự kiện của một tenant đến đúng thứ tự phát sinh; sự kiện của nhiều tenant không có thứ tự chung. Bên nhận khử trùng theo `ce_id`, xử lý lại được, và phải bỏ qua trường lạ.')
W('')
W('### 5.3. Sự kiện PH-20 tiêu thụ')
W('')
rows = []
for code, cname, topic, data, src, desc in ga.INS:
    rows.append([code, f'`{topic}`', src, desc])
table(['Mã', 'Topic', 'Bên phát', 'PH-20 làm gì'], rows, 'Sự kiện PH-20 tiêu thụ')
W('### 5.4. Quy tắc chung của sự kiện')
W('')
table(['Mục', 'Quy tắc'], [
    ['Phát', 'Ghi `outbox` cùng giao dịch với thay đổi nghiệp vụ; Debezium đưa lên Kafka; phát ít nhất một lần'],
    ['Nhận', 'Khử trùng theo `ce_id` ở bảng `inbox_event`; xử lý lại một sự kiện không đổi kết quả'],
    ['Lưu giữ, phân vùng', 'Lưu giữ 7 ngày, 3 phân vùng, 3 bản sao, `min.insync.replicas` 2 (giả định theo mức của PH-05, PH-10)'],
    ['Dữ liệu cá nhân', 'Không có: chỉ mã, trạng thái, số đếm; đường dẫn tải gói bàn giao không nằm ở EVT-20-16'],
    ['Lệch tên topic', 'PH-19 đang nghe `tenant.module-enabled.v1` và kiểm thử PH-10 dùng `dh.platform.tenant.created.v1`; PH-20 giữ tên của FRS 9.3, đề nghị hai phân hệ đổi (Phụ lục A)'],
    ['Bước bất đồng bộ', 'Phân hệ nhận EVT-20-01 hoặc EVT-20-07 phải báo kết quả bằng API-20-166 trong `20.provision.step-timeout-minutes`; EVT-20-10 đi cùng báo API-20-167'],
], 'Quy tắc chung của sự kiện PH-20')

# ------------------------------------------------------------------------------------------------ 6
W('## 6. Bảng mã lỗi')
W('')
W('Nguồn chuẩn là FRS D02-03-PH20 mục 9.1. Cột "HTTP" là mã trả ở phản hồi, dấu "—" là lỗi chỉ ghi vào bước, lần chạy, cảnh báo (không bao giờ ở phản hồi). Cột "Operation" là các API-20 có thể trả mã đó, tính từ `x-datahub-errors`. Thông điệp hiển thị cho người dùng ở FRS mục 9.2. Mã chung ngoài PH-20: ERR-00-401 chưa xác thực (`401`), ERR-00-403 không đủ quyền chức năng (`403`), ERR-00-428 thiếu `If-Match` (`428`).')
W('')
rows = []
for k, v in err_rows:
    rows.append([k, v['http'] if v['http'] else '—', v['meaning'], v['when'], rng(err_ops[k]) if err_ops.get(k) else ('Chương 7, saga' if v['http'] is None else 'Dữ liệu, data plane')])
table(['Mã', 'HTTP', 'Ý nghĩa', 'Khi nào', 'Operation (số API-20-)'], rows, 'Mã lỗi ERR-20 của PH-20')
W('Mã ERR-20-101, 102, 103 (tenant chưa sẵn sàng, đã chấm dứt, phân hệ chưa bật) do data plane trả cho lượt gọi vào API của tenant, không nằm ở operation của PH-20; các operation `/api/tenant/v1` khi tenant tạm ngừng trả ERR-20-001. ERR-20-104 và ERR-20-105, 114 chỉ ở các API báo tiến độ `/internal`.')
W('')

# ------------------------------------------------------------------------------------------------ 7
W('## 7. Sơ đồ trình tự')
W('')
W('### 7.1. Saga khởi tạo tenant')
W('')
W('Khai báo tenant ghi hồ sơ, chạy saga phát sự kiện cho phân hệ tự khởi tạo phần của mình; PA theo dõi bằng SSE. Sơ đồ vẽ các bước tiêu biểu, không vẽ đủ 17 bước (xem FRS mục 4.4).')
W('')
W('```{.mermaid caption="Trình tự khởi tạo tenant bằng saga 17 bước"}')
W('sequenceDiagram')
W('  participant PA as PA qua console')
W('  participant P as PH-20 dh-platform')
W('  participant G as Git và Argo CD')
W('  participant I as PH-12')
W('  participant O as PH-13')
W('  participant K as Kafka')
W('  participant X as PH-10 PH-03 PH-04')
W('  PA->>P: POST /tenants rồi POST /tenants/T68:check-readiness')
W('  P-->>PA: 201 PROVISIONING và readiness ready')
W('  PA->>P: POST /tenants/T68/provisioning-runs')
W('  P-->>PA: 202 runId PENDING')
W('  PA->>P: GET /provisioning-runs/{runId}/stream')
W('  P->>G: S02 commit cấu hình tenants/T68')
W('  P->>I: S03 API-12-080 tạo realm dh-t68')
W('  I-->>P: 200 realm PROVISIONING')
W('  P->>O: S08 API-13-072 chuỗi kiểm toán')
W('  O-->>P: 200')
W('  P-)K: Phát EVT-20-01 platform.tenant.created.v1')
W('  K-)X: Mỗi phân hệ tự khởi tạo phần của mình')
W('  X->>P: POST /internal/.../steps/S06_EVENTING:report SUCCEEDED')
W('  P-->>PA: SSE step-changed rồi run SUCCEEDED')
W('  PA->>P: POST /tenants/T68:activate If-Match')
W('  P-->>PA: 200 ACTIVE và handoverDelivery SENT')
W('  P-)K: Phát EVT-20-03 platform.tenant.activated.v1')
W('```')
W('')
W('Bước lỗi dừng saga ở `FAILED` và phát EVT-20-02; PA thử lại từ bước lỗi bằng API-20-017 hoặc bù trừ bằng API-20-020. Kích hoạt (API-20-023) chỉ thành công khi kiểm tra khói đạt (ERR-20-020). Thời gian từ khai báo đến `ACTIVE` mục tiêu không quá 60 phút khi tự động (NFR-00-057) và không quá một ngày làm việc kể cả thời gian chờ con người (KPI-12).')
W('')
W('### 7.2. Báo tiến độ bất đồng bộ của bước saga')
W('')
W('Bước bất đồng bộ không chờ đồng bộ trên một yêu cầu HTTP dài: PH-20 phát sự kiện, đặt bước `WAITING_REPORT` và hẹn giờ; phân hệ báo kết quả qua API-20-166.')
W('')
W('```{.mermaid caption="Trình tự báo tiến độ bước bất đồng bộ S06_EVENTING"}')
W('sequenceDiagram')
W('  participant S as Saga PH-20')
W('  participant K as Kafka')
W('  participant E as PH-10')
W('  participant C as Console')
W('  participant T as Bộ hẹn giờ')
W('  S->>S: Đặt S06 WAITING_REPORT và timeoutAt')
W('  S-)K: EVT-20-01 kèm runId')
W('  S-)C: SSE step-changed S06 WAITING_REPORT')
W('  K-)E: Nhận EVT-20-01')
W('  E->>E: Tạo principal, ACL, topic hệ thống')
W('  E->>S: POST /internal/tenant/v1/provisioning-runs/{runId}/steps/S06_EVENTING:report')
W('  S-->>E: 200 accepted stepStatus SUCCEEDED')
W('  S-)C: SSE step-changed S06 SUCCEEDED')
W('  T->>S: Hết step-timeout-minutes mà chưa có báo cáo')
W('  S->>S: Đặt S06 FAILED ERR-20-106 và run FAILED')
W('  S-)K: EVT-20-02 provisioning-failed')
W('```')
W('')
W('Hai nhánh: có báo cáo trong hạn thì bước `SUCCEEDED` (hoặc `FAILED` kèm `errorCode` nếu phân hệ báo lỗi, ERR-20-107); quá hạn `20.provision.step-timeout-minutes` (mặc định 15 phút) thì bước `FAILED` với ERR-20-106. Báo lặp cùng kết quả trả `200` (lũy đẳng); báo sai bước hoặc sai trạng thái trả `409` ERR-20-105; bên không phải bên thực hiện trả `403` ERR-20-104. Cùng cơ chế dùng cho báo tiến độ chuyển sáp nhập (API-20-167) và xuất gói bàn giao (API-20-168).')
W('')
W('### 7.3. Sáp nhập tenant')
W('')
W('Sáp nhập gom tenant nguồn vào tenant đích khi sắp xếp đơn vị hành chính. PH-20 điều phối, PH-18 chạy chuyển dữ liệu từng phân hệ, PH-12 chuyển định danh, PH-03 chuyển tiếp lượt gọi.')
W('')
W('```{.mermaid caption="Trình tự lập, duyệt, chuyển dữ liệu và cutover sáp nhập tenant"}')
W('sequenceDiagram')
W('  participant A as PA lập kế hoạch')
W('  participant B as PA duyệt')
W('  participant P as PH-20')
W('  participant N as PH-18')
W('  participant M as Phân hệ có dữ liệu')
W('  participant I as PH-12')
W('  participant W as PH-03')
W('  A->>P: POST /merge-plans rồi PUT /mappings/{id} rồi :dry-run')
W('  P-->>A: 202 dryRun PASSED và mappingHash')
W('  A->>P: POST /merge-plans/{id}:submit If-Match')
W('  B->>P: POST /merge-plans/{id}:approve If-Match')
W('  P-->>B: 200 APPROVED người duyệt khác người lập')
W('  A->>P: POST /merge-plans/{id}:start')
W('  P-)N: EVT-20-10 và POST /api/ops/v1/merge-transfers mỗi phân hệ')
W('  N->>M: Xuất, nhập, kiểm đếm theo gói')
W('  N->>P: POST /internal/.../participants/{module}:report')
W('  P-->>A: TRANSFERRING rồi CONFLICT_REVIEW nếu còn xung đột')
W('  A->>P: POST /conflicts:resolve-batch')
W('  A->>P: POST /merge-plans/{id}:transfer-identity')
W('  P->>I: API-12-045 và API-12-046 cấp song song thông tin xác thực')
W('  A->>P: POST /merge-plans/{id}:cutover confirmCode')
W('  P-)W: EVT-20-11 nguồn MERGED, chuyển tiếp kèm Deprecation')
W('  W-)P: EVT-03-10 xác nhận chuyển tiếp đã bật')
W('  A->>P: POST /merge-plans/{id}:complete sau thời gian chuyển tiếp')
W('  P-)W: EVT-20-12 merge-completed')
W('```')
W('')
W('Điều kiện chặn: chạy thử phải đạt và không cũ so với bảng ánh xạ (ERR-20-043), còn xung đột mở thì không chuyển định danh, không cutover (ERR-20-044), thời gian chuyển tiếp không vượt `20.merge.transition-max-months` (ERR-20-045), chưa hết chuyển tiếp thì không kết thúc (ERR-20-046). Hủy kế hoạch chỉ được trước cutover (API-20-093); sau cutover tenant nguồn giữ `MERGED` chỉ đọc theo Q20-01. TA của hai tỉnh xem phần của tỉnh mình ở API-20-088, 099, 101 qua console (chỉ đọc).')
W('')
W('### 7.4. Tạm ngừng tenant và thực thi ở data plane')
W('')
W('Tạm ngừng đi qua đề nghị, thực hiện, rồi PH-12 và PH-03 thực thi, mọi lượt gọi vào tenant trả ERR-20-001 trong không quá 60 giây.')
W('')
W('```{.mermaid caption="Trình tự tạm ngừng tenant và thực thi ERR-20-001"}')
W('sequenceDiagram')
W('  participant A as PA')
W('  participant P as PH-20')
W('  participant I as PH-12')
W('  participant W as PH-03 APISIX')
W('  participant U as Người dùng tỉnh')
W('  A->>P: POST /tenants/T68/lifecycle-requests SUSPEND')
W('  P-->>A: 201 DRAFT')
W('  A->>P: POST /lifecycle-requests/{id}:execute If-Match')
W('  P->>I: API-12-084 realm chỉ đọc')
W('  P->>P: Tenant SUSPENDED, ghi lịch sử và kiểm toán')
W('  P-)W: EVT-20-04 status-changed')
W('  P-->>A: 202 EXECUTING')
W('  U->>W: Gọi API của tỉnh')
W('  W-->>U: 403 ERR-20-001 Tỉnh đang tạm ngừng')
W('  U->>P: GET /api/tenant/v1/context')
W('  P-->>U: 200 readOnly true và banner')
W('```')
W('')
W('Tạm ngừng không cần bốn mắt (chỉ chấm dứt, sáp nhập, đổi cách ly, hạ hạn mức cần). Khi `20.suspend.essential-api-allowed = true` và đề nghị có `essentialApisAllowed`, API thiết yếu vẫn được phục vụ. Khôi phục dùng cùng đường dẫn với `requestType = RESUME` và đảo ngược thực thi.')
W('')

# ------------------------------------------------------------------------------------------------ 8
W('## 8. Ca rò rỉ chéo tenant')
W('')
W('Nguyên tắc: người gọi không thể biết đối tượng của tenant khác có tồn tại hay không. Mọi truy cập đối tượng không thuộc tenant của token trả `404` ERR-20-002 với thân giống hệt đối tượng không tồn tại (cùng `title`, `detail`, độ dài), không trả `403`. Ranh giới thực thi ở hai lớp: tầng ứng dụng (tenant lấy từ token) và RLS PostgreSQL (`app.tenant_id`, D03-10 mục 4); lớp RLS vẫn giữ kể cả khi tầng ứng dụng sai.')
W('')
table(['Ca', 'Yêu cầu', 'Kỳ vọng', 'Lý do'], [
    ['L-01', 'TA của T68 gọi `GET /api/tenant/v1/organizations/{orgCode}` với mã tổ chức chỉ có ở T91', '`404` ERR-20-002', 'Truy vấn theo `tenant_id` của token, RLS lọc dòng của T91'],
    ['L-02', 'TA của T68 gọi `PUT /api/tenant/v1/organizations/{orgCode}/data-owner` với mã của T91', '`404` ERR-20-002', 'Không phân biệt không tồn tại và thuộc tenant khác, thân giống nhau'],
    ['L-03', 'TA của T68 gọi `GET /api/tenant/v1/organization-imports/{importId}` của lô nhập T91', '`404` ERR-20-002', 'Lô nhập có `tenant_id`, RLS chuẩn'],
    ['L-04', 'TA của T68 gọi `GET /api/platform/v1/tenants/T91`', '`403` ERR-00-403', 'Vai trò sai nhóm, bị chặn ở lớp xác thực trước khi tới dữ liệu; không lộ sự tồn tại của T91'],
    ['L-05', 'TA của T68 gửi `tenantCode = T91` trong thân `PUT /api/tenant/v1/settings`', 'Ghi cài đặt của T68, bỏ qua `tenantCode` lạ', 'Tenant luôn lấy từ token'],
    ['L-06', 'Client mang scope `tenant:org-read` của PH-01 ở ngữ cảnh T68 gọi `GET /internal/tenant/v1/organizations/{orgCode}` mã của T91', '`404` ERR-20-002', 'Tổ chức đọc theo tenant ngữ cảnh của thông tin xác thực máy'],
    ['L-07', 'Client mang scope `tenant:org-read` gọi `POST /internal/tenant/v1/organizations:lookup` có lẫn mã T91', '`200`, mã T91 nằm ở `notFound`', 'Tra hàng loạt không trả lỗi từng dòng, chỉ liệt kê mã không tìm thấy'],
    ['L-08', 'Phân hệ báo `POST /internal/tenant/v1/provisioning-runs/{runId}/steps/S06_EVENTING:report` của lần chạy tenant khác bên thực hiện', '`403` ERR-20-104', 'Chỉ bên thực hiện của bước được báo'],
    ['L-09', 'PA T68 qua `/api/platform/v1` gọi `GET /tenants/T91/usage` không có quyền đọc', '`403` ERR-00-403', 'Quyền đọc phải có ở nhóm nền tảng, tách khỏi quyền của tenant'],
    ['L-10', 'Người dùng T68 gọi `GET /api/tenant/v1/cross-tenant-access-log` tìm lượt truy cập của T91', '`200` chỉ lượt vào T68', 'Nhật ký chỉ lượt truy cập vào tỉnh của người gọi'],
], 'Ca kiểm thử rò rỉ chéo tenant ở tầng API')
W('```http')
W('GET /api/tenant/v1/organizations/SO-CHI-CO-O-T91 HTTP/1.1')
W('Authorization: Bearer <token-tenant-T68>')
W('')
W('HTTP/1.1 404 Not Found')
W('Content-Type: application/problem+json')
W('')
W('{"type": "https://datahub.example.vn/errors/ERR-20-002", "title": "Không tìm thấy", "status": 404, "code": "ERR-20-002",')
W(' "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "detail": "Không tìm thấy tổ chức.", "instance": "/api/tenant/v1/organizations/SO-CHI-CO-O-T91"}')
W('```')
W('')
W('Ví dụ ca L-01: thân lỗi không chứa mã tenant lạ và không khác thân của mã không tồn tại. FR-20-070 điều phối kiểm thử rò rỉ hằng đêm giữa hai tenant kiểm thử T90 và T91, phủ 100% operation của ba nhóm; API-20-132, 133, 134 chạy và đọc kết quả, phát hiện rò rỉ ghi ERR-20-111 và cảnh báo PH-13. Kiểm thử không chạy ở `PROD` (Q20-18) và chỉ giữa tenant kiểm thử (ERR-20-065). Ca L-01…L-10 là ca hợp đồng bắt buộc của D05-02-PH20.')
W('')

# ------------------------------------------------------------------------------------------------ 9
W('## 9. Truy vết API và FR')
W('')
W('Mỗi FR-20-001…070 phải có ít nhất một API hoặc lý do không có API riêng. Bảng sinh từ `x-datahub-fr` của OpenAPI; cột "API-20-" liệt kê số.')
W('')
no_api = {6: 'Không có API riêng: bảo vệ tenant đặc biệt áp cho mọi API ghi (ERR-20-010)', 28: 'Không có API riêng: tác vụ nền thu số liệu, kết quả đọc ở API-20-056, 057, 140',
          44: 'Không có API riêng: trạng thái gửi thư đọc ở API-20-085', 20: 'Trạng thái ghi Git đọc ở API-20-039, ghi ở API-20-040'}
fr2api = defaultdict(list)
for o in ops:
    for f in o['frs']:
        fr2api[f].append(o['id'])
rows = []
for f in range(1, 71):
    rows.append([f'FR-20-{f:03d}', fr_names.get(f, ''), rng(fr2api[f]) if fr2api.get(f) else no_api.get(f, 'Không có')])
table(['FR', 'Tên chức năng', 'API-20-'], rows, 'Truy vết FR sang API')
missing = [f for f in range(1, 71) if not fr2api.get(f)]
W(f'FR không có API riêng: {", ".join(f"FR-20-{f:03d}" for f in missing)} (lý do ở cột cuối bảng). Mọi API-20-001…171 đều có ít nhất một FR hiện thực.')
W('')

# ------------------------------------------------------------------------------------------------ 10
W('## 10. Câu hỏi mở')
W('')
W('Dải Q20-55…59 dành cho tập API; Q20-01…19 ở FRS không lặp lại.')
W('')
table(['Mã', 'Câu hỏi', 'Ảnh hưởng', 'Đề xuất tạm'], [
    ['Q20-55', 'Giới hạn tốc độ cụ thể theo nhóm đường dẫn và theo tenant do ai chốt (PH-03 hay PH-20)', 'Mục 2.9', 'Dùng bảng giả định 2.9, đặt ở APISIX, đổi không cần phát hành mới'],
    ['Q20-56', 'Tải tệp nhập tổ chức qua `multipart/form-data` trực tiếp hay xin liên kết tải lên trước vào kho tệp DD-12', 'API-20-153', 'Multipart trực tiếp tối đa 10 MB, quét virus rồi mới đọc'],
    ['Q20-57', 'Luồng SSE tiến độ saga đi qua BFF hay trực tiếp APISIX, giới hạn kết nối mỗi người dùng', 'API-20-016', 'Qua APISIX, tối đa 5 luồng mỗi người dùng, nối lại bằng `Last-Event-ID`'],
    ['Q20-58', 'Nhật ký kiểm toán của tỉnh (API-20-161) hiện họ tên hay mã ẩn danh của PA nền tảng tác động vào tỉnh', 'API-20-161, SEC-85', 'Hiện mã người dùng nền tảng và vai trò, không hiện họ tên'],
    ['Q20-59', '`mergePlanId` dạng mã nghiệp vụ `SN-năm-số` hay UUID; ai cấp số', 'API-20-086 đến 108, EVT-20-10…12', 'Mã nghiệp vụ `SN-2026-001` do PH-20 cấp theo năm, UUID ở khóa nội bộ'],
], 'Câu hỏi mở Q20-55…59')

# ------------------------------------------------------------------------------------------------ Phụ lục
W('## Phụ lục A. Đề nghị đồng bộ')
W('')
W('Tập API không sửa tài liệu khác; các lệch và đề nghị dưới đây ghi để luồng chính xử lý.')
W('')
table(['Tài liệu', 'Đề nghị'], [
    ['FRS D02-03-PH20', 'FR-20-038: trường `reason` kiểu `SuspendReason` đổi tên `suspendReason` ở API để khỏi trùng `reason` văn bản của các FR khác (thân `LifecycleRequestCreate`); sửa FRS hoặc ghi chú đổi tên'],
    ['FRS D02-03-PH20', 'FR-20-001, FR-20-005: API dùng `isolationMode`, `scaleProfile`, `deploymentProfile`, `contacts[].role`, giữ đúng tên FRS; riêng đầu mối dùng giá trị `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY` theo FRS 4.2'],
    ['FRS D02-03-PH20, D02-08', 'API-20-137, API-20-139 ghi quyền "SO, AU đọc" và API-20-161 ghi "TA, AU" nhưng không có `PERM-20-*` tương ứng; đề nghị thêm `PERM-20-access-read` (SO, AU, TA) và `PERM-20-audit-read` (TA, AU), hoặc xác nhận dùng vai trò trực tiếp'],
    ['FRS D02-03-PH20', 'API-20-162: `?status=ACTIVE` ghi ở FRS; API còn nhận `isolationMode`, `module`, `updatedSince`, `size` tối đa 1.000 (thêm để đồng bộ tăng dần, tương thích ngược)'],
    ['D02-08', 'Thêm mười quyền `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-approve`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-settings`, `PERM-20-org`, `PERM-20-org-read`, `PERM-20-usage-read`; scope `tenant:registry-read`, `tenant:org-read`, `tenant:provision-report` (các mã PERM-20 mới này chưa có ở D02-08 nên `kiem_tra_ma.py` báo thiếu cho tới khi D02-08 cập nhật)'],
    ['CSDL D03-03-PH20', '`tenant_contact.contact_type` (`PRIMARY`, `TECHNICAL`, `SECURITY`, `BILLING`) lệch FRS 4.2 và API (`LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY`); `provisioning_template.status` dùng `ACTIVE` còn FRS, API dùng `PUBLISHED`; đề nghị đổi DDL theo FRS'],
    ['CSDL D03-03-PH20', 'Chưa có bảng cho: cụm đích `DEDICATED_CLUSTER` (`clusterCode`, `state`, API-20-035…038), đợt khởi tạo bổ sung (`planId`, API-20-033, 034), đề xuất đồng bộ tổ chức (`proposalId`, API-20-157, 158), thông báo phát hành (`announcementId`, API-20-128), lần đối chiếu cấu hình (`reconcileId`, API-20-045); đề nghị thêm `dedicated_cluster`, `supplement_plan`, `org_sync_proposal`, `release_announcement` hoặc ghi rõ lưu ở bảng nào'],
    ['CSDL D03-03-PH20', '`merge_plan.plan_code` là `mergePlanId` ở API (dạng `SN-2026-001`); `usage_report.status` `GENERATING` được API giữ; `tenant_config_version.config_scope` giữ năm giá trị như API `ConfigScope`'],
    ['D03-06-PH20 và D05-02-PH20', 'Màn hình gọi đúng mã API-20 ở chương 3; ca L-01…L-10 ở chương 8 là ca hợp đồng bắt buộc của test case; ca "Idempotency-Key lặp khác thân" và "If-Match thiếu, lệch" cho mọi operation có khóa'],
    ['PH-18', 'Chốt `POST /api/ops/v1/merge-transfers` (một phân hệ của một kế hoạch, kèm `Idempotency-Key = {mergePlanId}:{module}`) và `NotificationApi`; gọi API-20-167 báo tiến độ, API-20-162 với `?status=ACTIVE` cho tác vụ nền; đăng ký 28 khóa `20.*`; PH-20 chỉ đọc giá trị hiệu lực ở API-20-131'],
    ['PH-19, PH-10', 'PH-19 đổi tên topic nghe sang `platform.tenant.module-enabled.v1`; PH-10 đổi tên topic trong kiểm thử `dh.platform.tenant.created.v1` sang `platform.tenant.created.v1` và nhận phần báo tiến độ qua API-20-166'],
    ['PH-12', 'Nhận scope `iam:realm-provision` cho PH-20 (API-12-080, 084, 085, 045, 046); đọc API-20-165 khi cấp truy cập liên tenant; nghe EVT-20-04, EVT-20-11'],
    ['PH-13, PH-03, PH-07, PH-16, PH-09', 'PH-13: scope `obs:tenant-provision`, nhận EVT-20-12, nhãn `tenant` cho `dh_tenant_*`; PH-03: đọc API-20-164, phát EVT-03-10, EVT-03-11, thực thi ERR-20-001 và `Deprecation`, `Sunset`; PH-07: scope `platform.tenant.provision` cho API-07-073; PH-16: nhận API-16-030 với `metricCode` `ph20.tenant.provision-lead-time`; PH-09: FR-09-043 và EVT-09-21'],
    ['D00-04', 'Ghi quy ước tiêu đề CloudEvents `ce_dhtenant` cho sự kiện cấp nền tảng (`PLATFORM`) và sự kiện sáp nhập (tenant đích); ghi dải Q20-55…59'],
], 'Đề nghị đồng bộ với tài liệu khác')
W('Giả định chính của tập: (1) tenant mẫu `T68` quy mô vừa với 200 HTTT (GĐ-01…07); (2) giới hạn tốc độ ở mục 2.9; (3) Kafka 3 phân vùng, lưu giữ 7 ngày như PH-05, PH-10; (4) liên kết tải gói bàn giao tối đa 72 giờ theo FR-20-041; (5) API `/internal` không có phân trang nâng cao ngoài `page`, `size`.')
W('')
W('## Lịch sử phiên bản')
W('')
table(['Phiên bản', 'Ngày', 'Người', 'Nội dung'], [['0.1', '27/11/2026', 'Nhóm viết tài liệu (Claude)', 'Bản đầu: 171 operation, 16 sự kiện phát, 6 sự kiện tiêu thụ, bảng mã lỗi, ba sơ đồ trình tự, ca rò rỉ chéo tenant']], 'Lịch sử phiên bản')

open(MD, 'w', encoding='utf-8').write('\n'.join(L).rstrip('\n') + '\n')
print('Đã ghi', MD, os.path.getsize(MD))
