import json, sys, re, yaml
S=sys.argv[1]
d=json.load(open(S+'/dbspec.json'))
aa=yaml.safe_load(open('03-thiet-ke/api/ph07/asyncapi-rdm.yaml'))
def esc(s): return (s or '').replace('|','\\|').replace('\n',' ')
tabs=d['tabs']; cols={}; cons={}; idx={}; pol={}
for c in d['cols']: cols.setdefault(c['t'],[]).append(c)
for c in d['cons']: cons.setdefault(c['t'],[]).append(c)
for c in d['idx']: idx.setdefault(c['t'],[]).append(c)
for c in d['pol']: pol.setdefault(c['t'],[]).append(c)
def en(t):
    m=re.match(r'(EN-07-\d+)',t['cm'] or ''); return m.group(1) if m else '—'
order=sorted(tabs,key=lambda t:(en(t)=='—',en(t)))
O=[]; w=O.append
w("""---
ma_tai_lieu: D03-03-PH07
ten: Thiết kế cơ sở dữ liệu phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kiến trúc sư, lập trình viên L-DATA, quản trị CSDL, đội di trú dữ liệu, kiểm thử viên
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
---

# D03-03-PH07 · Thiết kế cơ sở dữ liệu phân hệ PH-07 Danh mục dùng chung

## Tóm tắt cho hội đồng thẩm định

Dữ liệu của PH-07 nằm trong một schema PostgreSQL riêng `ph07_rdm` gồm %d bảng. Dữ liệu của các tỉnh dùng chung một cơ sở dữ liệu nhưng được cách ly bằng cơ chế bảo mật mức dòng (Row Level Security) của PostgreSQL: mỗi câu lệnh chỉ thấy dữ liệu của tỉnh đang làm việc và của danh mục dùng chung toàn quốc, kể cả khi mã ứng dụng có lỗi. Danh mục toàn quốc (ĐVHC, dân tộc…) được quản lý một lần ở tenant `COMMON` và chỉ quản trị nền tảng được ghi.

So với hệ cũ Aita (bốn bảng EAV, mọi giá trị là chuỗi, không mã, không phiên bản), thiết kế mới lưu bản ghi có mã nghiệp vụ duy nhất, thuộc tính có kiểu và kiểm tra bằng JSON Schema, phiên bản bất biến có ngày hiệu lực, lịch sử sắp xếp ĐVHC và bảng ánh xạ mã. Mục 8 trình bày cách chuyển dữ liệu Aita sang thiết kế mới, là đầu vào của kế hoạch di trú D06-01.

Hợp đồng máy đọc được của tài liệu này:

| Tệp | Nội dung |
|---|---|
| [`ph07/ddl/ph07_rdm.sql`](ph07/ddl/ph07_rdm.sql) | DDL đầy đủ, nguồn duy nhất; chạy được bằng psql trên CSDL trống |
| [`ph07/liquibase/db.changelog-ph07.yaml`](ph07/liquibase/db.changelog-ph07.yaml) và `ph07/liquibase/changes/` | Changelog Liquibase sinh tự động từ DDL và dữ liệu nền |
| [`ph07/seed/`](ph07/seed/) | Dữ liệu nền S01 (nhóm danh mục), S02 (giới tính), S03 (khung ĐVHC) |
| [`ph07/tools/gen_liquibase.py`](ph07/tools/gen_liquibase.py) | Công cụ sinh changelog |

Ngày 25/11/2026, DDL, changelog sinh ra và dữ liệu nền đã được chạy thử thành công trên PostgreSQL 16 (CSDL trống, `ON_ERROR_STOP`); đích chính thức là PostgreSQL 18 qua CloudNativePG (ADR-006).

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph07_rdm` do vai trò `ph07_owner` (NOLOGIN) sở hữu. Ứng dụng `dh-data` kết nối bằng tài khoản `dh_data_app`, thành viên vai trò `ph07_app` chỉ có quyền DML trên từng bảng (không DDL, không `BYPASSRLS`); Liquibase chạy bằng `dh_data_migrator`, thành viên `ph07_owner`; báo cáo và kiểm toán đọc bằng `ph07_readonly`. Vai trò thứ tư `ph07_worker` không có quyền đọc dữ liệu nghiệp vụ; ứng dụng chỉ chuyển sang vai trò này bằng `SET LOCAL ROLE` trong giao dịch ngắn nhận tác vụ nền liên tenant, và vai trò chỉ thấy các cột hàng đợi của `import_job` (D03-02-PH07 §4.7.3). Mật khẩu tài khoản đăng nhập do CloudNativePG quản lý qua OpenBao, không nằm trong DDL. Module khác của `dh-data` không đọc trực tiếp bảng của `ph07_rdm`; chúng gọi API công bố `RdmApi`, `RdmLookupApi` (D03-02-PH07 §3.3), trừ bảng chiếu `admin_unit` (DD-07) được cấp quyền đọc cho các schema khác.

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có cột `tenant_id` (`T{nn}`, `COMMON`; `PLATFORM` chỉ xuất hiện ở bảng kỹ thuật) và bật `FORCE ROW LEVEL SECURITY`, nên kể cả chủ bảng cũng chịu chính sách. Ứng dụng đặt biến phiên `app.tenant_id` ở đầu mỗi giao dịch (D03-10); quên đặt thì câu lệnh lỗi ngay do `current_setting('app.tenant_id', false)`. Có hai mẫu chính sách:

| Mẫu | Đọc | Ghi | Dùng cho |
|---|---|---|---|
| S (dùng chung) | Tenant phiên hoặc `COMMON` | Tenant phiên là tỉnh và dòng của chính tỉnh đó; hoặc dòng `COMMON` khi tenant phiên là `PLATFORM` | Nhóm, danh mục, phiên bản, thuộc tính, bản ghi, sự kiện sắp xếp, hệ thống mã, ánh xạ |
| P (riêng) | Như ghi | Như mẫu S | Dữ liệu tác nghiệp: tác vụ nhập, dòng tạm, đồng bộ, cấp quyền khai thác, outbox, nhật ký duyệt |

Khóa ngoại giữa các bảng mẫu S mang cả `tenant_id` (ví dụ `(catalog_id, tenant_id)`), nên một dòng của tỉnh không thể trỏ sang danh mục của tỉnh khác. Danh mục của tỉnh được phép trỏ tới danh mục `COMMON` ở đúng hai chỗ có chủ đích: `extends_catalog_id` của danh mục HYBRID và `ref_catalog_code` của thuộc tính `CATALOG_REF`; hai chỗ này kiểm tra bằng trigger chứ không bằng khóa ngoại hai cột.

Tuỳ chọn tách cơ sở dữ liệu riêng cho tỉnh lớn (D03-10) không đổi thiết kế bảng: CSDL riêng vẫn có schema `ph07_rdm` giống hệt, chứa dữ liệu của một tỉnh và bản sao danh mục `COMMON` được đồng bộ từ cụm trung tâm qua sự kiện EVT-07-05.

### 1.3. Quy ước bảng

Mọi bảng nghiệp vụ theo D00-01 §5.1: khóa chính `id uuid` (UUID v7 sinh ở ứng dụng; chỉ thao tác sao chép hàng loạt dùng `f_uuid_v7()` trong CSDL), các cột `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (khóa lạc quan, trigger `tg_touch` tăng khi ứng dụng quên). Ngoại lệ có chủ đích: `outbox` (chỉ thêm, khóa là `event_id`), `import_row` (dòng tạm, phân vùng theo ngày), `idempotency_key` (khóa tự nhiên bốn cột), `shedlock` (bảng kỹ thuật của thư viện). Chuỗi lưu dạng Unicode NFC; cột `name_search` sinh từ `f_search_norm(name)` (NFC, bỏ dấu, chữ thường) phục vụ tìm không dấu bằng chỉ mục trigram.

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ dưới đây chỉ thể hiện khóa ngoại thật trong DDL (sinh từ catalog của PostgreSQL). Bảng `outbox`, `idempotency_key`, `shedlock` không có khóa ngoại nên không xuất hiện.

```mermaid
erDiagram""" % len(tabs))
fks=[c for c in d['cons'] if c['ty']=='f']
seen=set()
for c in fks:
    m=re.search(r'REFERENCES ph07_rdm\.(\w+)',c['def'])
    if not m: continue
    k=(m.group(1),c['t'],c['n'])
    if k in seen: continue
    seen.add(k)
    w(f'    {m.group(1)} ||--o{{ {c["t"]} : "{c["n"].replace("fk_","")}"')
w("""```

Sơ đồ có ba cụm. Cụm lõi (`catalog_group`, `catalog`, `catalog_version`, `attribute_def`, `catalog_item`, `item_succession`, `version_review`) hiện thực mô hình copy-on-write: mỗi phiên bản sở hữu bản sao đầy đủ thuộc tính và bản ghi của nó (ADR-051), nên tra theo thời điểm chỉ cần chọn đúng phiên bản. Cụm tác nghiệp (`file_object`, `import_job`, `import_row`, `sync_source`, `sync_run`, `sync_change`) giữ trạng thái của tác vụ nền. Cụm khai thác (`code_system`, `code_mapping`, `catalog_access_grant`, `admin_unit`) phục vụ chuyển mã, phân quyền khai thác và bảng chiếu ĐVHC dùng chung cho phân hệ khác.

## 3. Đặc tả bảng

Bảng dưới đây liệt kê các bảng, mã thực thể, mẫu RLS và mô tả. Mục 3.x sau đó đặc tả từng bảng: cột, ràng buộc, chỉ mục, chính sách RLS. Toàn bộ mục 3 được sinh từ catalog của PostgreSQL sau khi chạy DDL, nên luôn khớp tệp `ph07_rdm.sql`; chú thích cột lấy từ `COMMENT ON` trong DDL.

| Mã | Bảng | Mô tả |
|---|---|---|""")
for t in order:
    w(f"| {en(t)} | `{t['t']}` | {esc(re.sub(r'^EN-07-\d+( = DD-07)? ','',t['cm'] or ''))} |")
for i,t in enumerate(order,1):
    n=t['t']
    w(f"\n### 3.{i}. `{n}` ({en(t)})\n")
    w(esc(t['cm'])+("" if not t['part'] else " Bảng phân vùng.")+"\n")
    w("| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |\n|---|---|---|---|---|")
    for c in cols.get(n,[]):
        df=('sinh: ' if c['gen'] else '')+(c['df'] or '')
        w(f"| `{c['n']}` | `{c['ty']}` | {'Có' if c['nn'] else ''} | {('`'+esc(df)+'`') if df else ''} | {esc(c['cm'])} |")
    cs=[c for c in cons.get(n,[]) if c['ty'] in 'pufcx']
    if cs:
        lab={'p':'Khóa chính','u':'Duy nhất','f':'Khóa ngoại','c':'Kiểm tra','x':'Loại trừ'}
        w("\nRàng buộc:\n\n| Tên | Loại | Định nghĩa |\n|---|---|---|")
        for c in cs: w(f"| `{c['n']}` | {lab[c['ty']]} | `{esc(c['def'])[:400]}` |")
    ix=[x for x in idx.get(n,[]) if not any(x['n']==c['n'] for c in cs)]
    if ix:
        w("\nChỉ mục:\n\n| Tên | Định nghĩa |\n|---|---|")
        for x in ix: w(f"| `{x['n']}` | `{esc(re.sub(r'^CREATE (UNIQUE )?INDEX \\w+ ON ','',x['def']))}` |")
    ps=pol.get(n,[])
    if ps: w("\nChính sách RLS: " + ", ".join(f"`{p['n']}` ({p['cmd']})" for p in ps) + ".")
    elif n!='shedlock': pass
w("""
## 4. DDL và changelog Liquibase

Tệp `ph07/ddl/ph07_rdm.sql` là nguồn duy nhất. Tệp được chia thành các đoạn bằng dấu `-- @file`, `-- @changeset`, `-- @rollback`; công cụ `ph07/tools/gen_liquibase.py` đọc các dấu đó và sinh tệp formatted SQL vào `ph07/liquibase/changes/` cùng changelog gốc `db.changelog-ph07.yaml`. Không ai sửa tay tệp sinh ra; CI chạy lại công cụ và báo lỗi nếu tệp trong repo khác kết quả sinh (bước kiểm tra hợp đồng trong đường ống CI của D04-02). Changelog của PH-07 được `include` vào changelog chung của `dh-data`.

| Context | Changeset | Khi nào chạy |
|---|---|---|
| `bootstrap` | Vai trò nhóm, extension `unaccent`, `pg_trgm`, `btree_gist`, schema | Lần đầu trên mỗi CSDL, bởi chủ CSDL |
| (không context) | Hàm, bảng, chỉ mục, RLS, trigger bảo vệ, quyền | Mọi lần triển khai |
| `seed-common` | Dữ liệu nền S01…S03 của tenant `COMMON` | Chỉ cụm có tenant `PLATFORM` (cụm trung tâm); idempotent, chạy lại khi tệp đổi |

Quy tắc thay đổi lược đồ theo D04-01: changeset đã phát hành không được sửa; thay đổi mới là changeset mới; thay đổi phải tương thích ngược ít nhất một phiên bản ứng dụng (thêm cột cho phép rỗng hoặc có mặc định, không đổi tên cột trực tiếp mà qua ba bước thêm, chép, bỏ). Mỗi changeset có `--rollback`; các changeset không thể hoàn tác an toàn (vai trò, extension) ghi rõ `--rollback empty` kèm lý do trong DDL.

## 5. Dữ liệu khởi tạo

Dữ liệu nền gồm hai lớp. Lớp `COMMON` nằm trong `ph07/seed/` và chạy một lần ở cụm trung tâm: S01 nhóm danh mục mặc định, S02 danh mục giới tính (ví dụ đầy đủ một danh mục phẳng có phiên bản đã phát hành), S03 khung ĐVHC (tỉnh, một số đơn vị mẫu, sự kiện sắp xếp mẫu để kiểm thử). Bảng mã ĐVHC đầy đủ 34 tỉnh và 3.321 đơn vị cấp xã được nạp qua đồng bộ quốc gia hoặc nhập tệp khi có nguồn máy đọc chính thức (Q07-01, Q07-25), không đưa vào seed để tránh sai lệch với văn bản. Lớp tenant là gói danh mục nền nạp khi khởi tạo tỉnh mới (FR-07-049) với `manifest.json` có băm SHA-256; nội dung gói thuộc kho cấu hình của PH-20, không thuộc Liquibase.

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. Kafka

Topic do PH-10 tạo bằng Strimzi `KafkaTopic` theo khai báo trong `asyncapi-rdm.yaml`; PH-07 chỉ ghi outbox. Bảng dưới đây liệt kê topic.

| Topic | Sự kiện | Phân vùng, bản sao | Giữ |
|---|---|---|---|""")
for ch in aa['channels'].values():
    b=ch['bindings']['kafka']; m=list(ch['messages'])[0]; mm=aa['components']['messages'][m]
    w(f"| `{ch['address']}` | {mm['x-datahub-id']} | {b['partitions']}, {b['replicas']} | 7 ngày |")
w("""
Khóa bản tin là `{tenant}:{catalogCode}`. Debezium đọc bảng `ph07_rdm.outbox` bằng slot logic riêng của `dh-data`, dùng Outbox Event Router với `route.by.field = topic`; dòng outbox được dọn sau 3 ngày bởi tác vụ định kỳ (Debezium đã đọc từ WAL, không cần giữ lâu).

### 6.2. Valkey

Valkey là bộ đệm tầng 2 (ADR-053, D03-02-PH07 §4.9). Mọi khóa có tiền tố hash tag tenant để các khóa của một tenant nằm cùng slot.

| Khóa | Giá trị | Thời gian sống |
|---|---|---|
| `{t68}:rdm:ptr:{catalogCode}:{yyyyMMdd}` | Phiên bản hiệu lực tại ngày | 300 giây |
| `{t68}:rdm:ver:{versionId}` | Toàn bộ phiên bản nén (danh mục ≤ 20.000 bản ghi) | 7 ngày |
| `{t68}:rdm:item:{versionId}:{code}` | Một bản ghi (danh mục lớn) | 24 giờ |
| `{t68}:rdm:neg:{versionId}:{code}` | Dấu "không có mã" | 1 giờ |
| `{t68}:rdm:cat:{catalogCode}` | Tóm tắt và lược đồ danh mục | 300 giây |
| `{t68}:rdm:lock:ver:{versionId}` | Khóa chống dồn tải khi nạp bộ đệm | 10 giây |
| Kênh pub/sub `rdm:invalidate` | Thông báo vô hiệu bộ đệm L1 giữa các pod | — |

Valkey không phải nơi lưu bền: mất toàn bộ Valkey chỉ làm tăng tải đọc PostgreSQL và ảnh chụp, không mất dữ liệu.

### 6.3. Kho đối tượng (Garage, giao diện S3)

Mỗi tenant có một bucket `dh-{tenant}-rdm` (COMMON là `dh-common-rdm`) với ba tiền tố.

| Tiền tố | Nội dung | Giữ |
|---|---|---|
| `snapshots/{catalogCode}/{versionNo}.json.gz`, `.csv.gz` | Ảnh chụp bất biến của phiên bản đã phát hành (ADR-051, ADR-053) | Như phiên bản (vĩnh viễn) |
| `imports/{jobId}/{sha256}.{ext}` | Tệp người dùng tải lên, chỉ phân tích khi quét sạch (BR-07-041) | 7 ngày |
| `exports/{jobId}/…` | Tệp xuất, báo cáo lỗi, kết quả chuyển mã | 24 giờ |

Vòng đời được đặt bằng lifecycle rule của bucket và đồng thời bằng cột `file_object.expires_at` (tác vụ dọn dẹp xóa cả đối tượng và dòng). Bucket ảnh chụp bật khóa đối tượng (object lock) chế độ governance để chống ghi đè.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Sao lưu PostgreSQL theo D03-09: CloudNativePG sao lưu cơ sở hằng ngày và lưu WAL liên tục lên kho đối tượng của site dự phòng, đạt RPO ≤ 5 phút, RTO ≤ 1 giờ cho `dh-data`. Ảnh chụp phiên bản trên Garage được nhân bản sang site dự phòng; khi khôi phục PostgreSQL về một thời điểm, ảnh chụp mới hơn thời điểm đó không gây sai vì khóa đối tượng gắn với `versionId` đã có trong CSDL. Khôi phục theo một tenant (không khôi phục cả cụm) dùng xuất logic có lọc `tenant_id` từ bản khôi phục tạm sang cụm đang chạy, theo kịch bản khôi phục trong D03-09.

Mã hóa: dữ liệu danh mục không chứa dữ liệu cá nhân (BR-07-025) và có mức phân loại tối đa `RESTRICTED`, nên không mã hóa cột; mã hóa ở tầng lưu trữ (ổ đĩa của node, bucket Garage) và mã hóa đường truyền (TLS tới PostgreSQL, mTLS trong mesh) theo D03-07. Cột `response_body` của `idempotency_key` có thể chứa thông điệp lỗi nhưng không chứa bí mật.

Lưu giữ: phiên bản đã phát hành và bản ghi của nó giữ trực tuyến tối thiểu `07.rdm.version-online-retention-years` năm (mặc định 5) sau khi hết hiệu lực, sau đó chỉ còn ảnh chụp trên kho đối tượng (Q07-10 của FRS); `import_row` 7 ngày (xóa theo phân vùng); `sync_change` 3 năm; `outbox` 3 ngày; `idempotency_key` 24 giờ; nhật ký duyệt `version_review` vĩnh viễn cùng phiên bản.

## 8. Ánh xạ CSDL hệ cũ Aita sang thiết kế mới

Mục này là đầu vào của D06-01 (kế hoạch di trú). Công cụ di trú hiện thực theo FR-07-051; ở đây nêu ánh xạ dữ liệu ở mức bảng và cột, cùng các quy tắc làm sạch. Cấu trúc Aita lấy theo cột thực tế trong câu lệnh SQL của tài liệu thiết kế chi tiết hệ cũ (FRS §2.2), không theo tài liệu CSDL hệ cũ vì hai tài liệu không khớp.

### 8.1. Ánh xạ bảng

| Bảng Aita | Bảng Datahub | Cách chuyển |
|---|---|---|
| `category` | `catalog` (một dòng) + `catalog_version` (phiên bản 1, `origin = MIGRATION`) | Một danh mục Aita thành một danh mục `LOCAL` của tenant tỉnh, hoặc thành ánh xạ tới danh mục `COMMON` khi đối chiếu trùng (FR-07-051 bước 7) |
| `category_fields` | `attribute_def` của phiên bản 1 | Một trường thành một thuộc tính; hai trường được nhận là cột mã và cột tên không thành thuộc tính mà thành `code`, `name` |
| `category_details` | `catalog_item` của phiên bản 1 | Một dòng chi tiết thành một bản ghi |
| `category_details_value` | `catalog_item.code`, `name`, `parent_code`, `attrs` | Xoay dọc thành ngang: mỗi giá trị vào đúng cột hoặc khóa `attrs` theo trường |
| (không có) | `code_mapping` với hệ thống mã `AITA_{tenant}` | Chỉ khi danh mục Aita được gộp vào danh mục `COMMON` mà mã khác nhau |
| (không có) | `sync_source` | Chỉ khi `category.is_update = 1`: đề xuất đăng ký đồng bộ quốc gia |

### 8.2. Ánh xạ cột

| Cột Aita | Cột Datahub | Quy tắc |
|---|---|---|
| `category.id` | `catalog.legacy_ref` | Lưu dạng chuỗi `aita:category:{id}` để đối soát và chạy lại không trùng |
| `category.category_code` | `catalog.code` | Chuẩn hóa thành T-CODE (bỏ dấu, chữ hoa, khoảng trắng thành `_`, ≤ 64 ký tự); không hợp lệ thì sinh từ `name`; trùng thì thêm hậu tố số |
| `category.name` (varchar 500) | `catalog.name` (≤ 255) | NFC, cắt khoảng trắng; dài hơn 255 ký tự thì cắt và chép bản đầy đủ vào `description`, ghi vấn đề vào báo cáo |
| `category.is_update` | `catalog.source_type` | `1` thì đề xuất `NATIONAL` kèm đăng ký đồng bộ; khác thì `LOCAL` |
| `category_fields.id` | `attribute_def.legacy_field_id` | Giữ để đối soát |
| `category_fields.name` (varchar 1000) | `attribute_def.label`; `attribute_def.code` sinh từ nhãn (snake_case không dấu) | Nhãn dài hơn 255 ký tự thì cắt và chép vào `description` |
| `category_fields.jhi_order` | `attribute_def.sort_order` | Thứ tự theo `jhi_order` rồi `id` |
| `category_fields.status` | `attribute_def.status` | Hoạt động thì `ACTIVE`, khác thì `HIDDEN` |
| `category_fields.data` | — | Không rõ ý nghĩa ở hệ cũ; chép nguyên văn vào `attribute_def.description` với tiền tố "Dữ liệu hệ cũ:" để cán bộ rà soát (Q07-103) |
| `category_details.id` | `catalog_item.legacy_ref` | `aita:detail:{id}` |
| `category_details_value.value` của cột mã | `catalog_item.code` | Cắt khoảng trắng, chữ hoa; rỗng hoặc trùng thì dòng lỗi; không có cột mã thì sinh `{MÃ_DANH_MỤC}_{details.id}` và gắn cảnh báo |
| `category_details_value.value` của cột tên | `catalog_item.name` | NFC, cắt khoảng trắng; rỗng thì dòng lỗi |
| `category_details_value.value` của cột cha | `catalog_item.parent_code` | Chỉ khi đề xuất phân cấp được chấp nhận; mã cha không tồn tại thì dòng lỗi |
| `category_details_value.value` của cột khác | `catalog_item.attrs.{code}` | Chuyển theo kiểu suy ra ở FR-07-051 bước 6; giá trị không chuyển được thì giữ nguyên chuỗi và đổi kiểu thuộc tính về `STRING`, hoặc dòng lỗi nếu cán bộ đã chốt kiểu |
| (không có) | `catalog_item.status` | `ACTIVE` cho mọi bản ghi; hệ cũ không có trạng thái ngừng dùng |
| (không có) | `catalog_version.effective_from` | Ngày ban hành danh mục do cán bộ cung cấp, hoặc ngày chuyển đổi |

### 8.3. Lỗi thiết kế hệ cũ được sửa khi chuyển

| Lỗi ở Aita | Hệ quả | Cách sửa khi chuyển |
|---|---|---|
| Bản ghi không có mã nghiệp vụ; mã chỉ là một giá trị quy ước | Mã trùng, mã rỗng | Bắt buộc `code` duy nhất (BR-07-002); dòng trùng hoặc rỗng phải sửa trước khi chạy thật |
| Mọi giá trị là chuỗi ≤ 2.000 ký tự | Số, ngày, cờ lưu lẫn định dạng | Suy kiểu và chuẩn hóa: ngày `dd/MM/yyyy` thành `yyyy-MM-dd`, số dùng dấu chấm thập phân, cờ thành boolean |
| Không phân biệt trường bắt buộc, duy nhất | Dữ liệu thiếu | Cán bộ chốt `required`, `uniqueInVersion` trong báo cáo chạy thử; vi phạm thành dòng lỗi |
| Không có phiên bản, ngày hiệu lực | Không tra được quá khứ | Phiên bản 1 hiệu lực từ ngày ban hành; lịch sử trước di trú không khôi phục được (ghi rõ trong biên bản) |
| Danh mục quốc gia bị sao chép tay vào từng tỉnh | Lệch chuẩn quốc gia | Gộp vào `COMMON` hoặc HYBRID kèm ánh xạ |
| Có thể chứa dữ liệu cá nhân trong danh mục | Vi phạm BR-07-025 | Thuộc tính gợi ý dữ liệu cá nhân bị đánh dấu và đề xuất loại bỏ |

### 8.4. Đối soát sau di trú

Biên bản đối soát so sánh theo từng danh mục: số danh mục theo quyết định (tạo mới, gộp `COMMON`, HYBRID, bỏ), số thuộc tính, số bản ghi, số ô có giá trị, và băm SHA-256 của từng ô sau chuẩn hóa NFC và cắt khoảng trắng giữa Aita và Datahub. Danh mục lệch không được ký cho tới khi giải trình hoặc chạy lại (FR-07-051 bước 12; tiêu chí AC-07-06 của FRS).

## 9. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q07-103 | Ý nghĩa cột `category_fields.data` của Aita | Chép vào mô tả thuộc tính để cán bộ rà soát; hỏi nhà thầu cũ nếu còn liên hệ |
| Q07-104 | Có cần CSDL riêng cho tỉnh lớn ngay ở MVP | Không; dùng chung cụm với RLS, tách khi một tỉnh vượt 20% tải |
| Q07-105 | Thời gian giữ trực tuyến bản ghi của phiên bản đã hết hiệu lực | 5 năm như Q07-10 của FRS |
""")
print('\n'.join(O))
