---
ma_tai_lieu: D03-03-PH04
ten: Thiết kế cơ sở dữ liệu phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.3
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư dữ liệu, DBA, lập trình viên L-INT, kiểm thử viên, nhóm vận hành
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
mo_ta: Thiết kế cơ sở dữ liệu của phân hệ Lõi tích hợp và trình thiết kế luồng gồm 26 bảng schema ph04, ràng buộc, RLS theo tenant, DDL và bài kiểm thử đã chạy trên PostgreSQL 16, kho ngoài PostgreSQL, sao lưu và ánh xạ dữ liệu hệ cũ.
tai_lieu_lien_quan: D02-03-PH04 FRS; D03-02-PH04 SDD; D03-04-PH04 API; D03-10 Đa tenant; D02-07 Từ điển dữ liệu; D03-09 Hạ tầng
---

# D03-03-PH04 · Thiết kế cơ sở dữ liệu phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

PH-04 lưu dữ liệu quản trị của luồng tích hợp: không gian làm việc, luồng, phiên bản định nghĩa, lần chạy thử, quyết định duyệt, triển khai, lệnh điều khiển runtime và chính sách thành phần. PH-04 **không lưu dữ liệu nghiệp vụ** đi qua luồng; bản tin chỉ xuất hiện dưới dạng xem trước đã che dữ liệu trong nhật ký chạy thử, giữ 90 ngày, thân đầy đủ (khi người dùng bật) nằm ở kho đối tượng và tự xóa sau 7 ngày.

Ba điểm thiết kế chính:

1. **Cách ly tỉnh bằng CSDL.** 25 trong 26 bảng của schema `ph04` (mọi bảng trừ `shedlock`) có `tenant_id` và `FORCE ROW LEVEL SECURITY`; khóa ngoại mang cả `tenant_id` nên một bản ghi của tỉnh không trỏ được sang tỉnh khác. Đã chạy thử: tỉnh T01 không thấy, không ghi được dữ liệu của T68; tỉnh không tự mở rộng được chính sách thành phần nền (§3.27, §4.2).
2. **Quy tắc nghiệp vụ quan trọng chốt ở CSDL, không chỉ ở ứng dụng.** Một luồng chỉ có một phiên bản mở (BR-04-016, chỉ mục duy nhất có điều kiện); nội dung phiên bản đã gửi duyệt là bất biến (trigger); phiên bản đã duyệt phải có người duyệt và băm khớp băm gửi duyệt; mỗi môi trường chỉ có một triển khai hiện hành; nhật ký duyệt chỉ thêm (§3.27).
3. **Thay thế bảng của mã hiện tại có kịch bản di trú.** Bốn bảng `ph04.route*` của `apps/control` (không có `tenant_id`) được chuyển sang thiết kế mới bằng changeset `ph04-9000`; lần chạy thử cũ (mô phỏng) được đánh dấu `SIMULATED` để không bao giờ thỏa điều kiện gửi duyệt (§8).

Nguồn duy nhất của DDL là [`ph04/ddl/ph04_int.sql`](ph04/ddl/ph04_int.sql) (945 dòng), đã chạy trên PostgreSQL 16 sạch và trên CSDL có bảng W2 cũ ngày 25/11/2026, chạy lại ngày 26/11/2026 sau khi sửa hai lỗi khởi tạo (§4.2); bài kiểm [`ph04/test/ph04_isolation_test.sql`](ph04/test/ph04_isolation_test.sql) đạt 23/23 khối. Danh sách bảng, bảng đặc tả và bảng cột ở §3 sinh từ DDL bằng [`ph04/tools/gen_tables_md.py`](ph04/tools/gen_tables_md.py).

## 0. Giới thiệu

Tài liệu đặc tả lược đồ dữ liệu của PH-04 trong schema `ph04` của cụm `pg-core`, cùng các kho ngoài PostgreSQL mà phân hệ dùng. Mục đích là cho kỹ sư `dh-integration` và DBA một nguồn duy nhất về bảng, cột, ràng buộc, cách ly tenant, di trú và sao lưu, khớp tuyệt đối với DDL đã chạy thử. Phạm vi gồm 26 bảng của schema `ph04`, schema `ph04_rt` của runtime (§6.4), topic Kafka, khóa Valkey và bucket Ceph RGW; không gồm dữ liệu nghiệp vụ đi qua luồng (PH-04 không lưu) và không gồm bảng của PH-05, PH-10 cùng DU.

Chương 1 nói chiến lược lưu trữ và cách ly tenant; chương 2 là sơ đồ thực thể – quan hệ; chương 3 có danh sách bảng rồi, với mỗi bảng, một bảng đặc tả 10 mục (Mục đích, FR phục vụ, Khóa chính, Duy nhất, Khóa ngoại, Ràng buộc CHECK, Chỉ mục, Cách ly tenant, Phân vùng và chỉ thêm, Ghi chú) trích từ DDL và danh sách cột; chương 4 là DDL, changelog và kết quả chạy thử; chương 5 tới 8 là dữ liệu khởi tạo, kho ngoài PostgreSQL, sao lưu và ánh xạ hệ cũ; chương 9 là câu hỏi mở và đề nghị đồng bộ.

| Người đọc | Phần cần đọc |
|---|---|
| Lập trình viên L-INT | Chương 1, 3, 4 |
| DBA, vận hành | Chương 1, 4, 6, 7 |
| ATTT | Chương 1.2, 3.27, 7 |
| Đội di trú | Chương 4, 8 |
| Hội đồng thẩm định | Tóm tắt, chương 2, 3.27, 8 |

: Người đọc và phần cần đọc

| Thuật ngữ | Giải thích |
|---|---|
| RLS mẫu P, S | Row-Level Security theo D03-10: P (riêng) chỉ dòng của tenant phiên; S (dùng chung) đọc thêm dòng `COMMON`, chỉ `PLATFORM` ghi dòng `COMMON` |
| `app.tenant_id` | Biến phiên đặt đầu mỗi giao dịch; giá trị `T{nn}` cho tỉnh, `PLATFORM` cho tác vụ nền tảng |
| Changeset | Đơn vị thay đổi Liquibase, đánh dấu trong DDL bằng `-- @changeset` |
| W2 | Đợt mã hiện có `apps/control` với bốn bảng `ph04.route*` cần di trú |
| EN-04-xx | Mã thực thể của FRS D02-03-PH04 §4 |
| Băm nội dung | `content_hash`, `sha256:` + 64 ký tự hex của YAML chuẩn hóa và `*.jq` |

: Thuật ngữ riêng của tài liệu CSDL

Kiểu dữ liệu chuẩn và cột ngữ cảnh theo D00-01 §5. Tài liệu tham chiếu: D02-03-PH04 (FRS, thực thể EN-04 và quy tắc BR-04), D03-02-PH04 (SDD, cách dùng bảng), D03-04-PH04 (API, sự kiện EVT-04), D03-10 (đa tenant, mẫu RLS), D03-09 (hạ tầng, sao lưu), D02-07 (từ điển dữ liệu).

## 1. Chiến lược lưu trữ

Chương này nói dữ liệu PH-04 nằm ở đâu, ai được truy cập bằng vai trò nào, và cơ chế nào bảo đảm tỉnh này không đọc, không ghi được dữ liệu của tỉnh khác.

### 1.1. Schema, vai trò và kết nối

Schema `ph04` nằm trên cụm `pg-core` (CloudNativePG, một primary hai standby đồng bộ, D03-09), do vai trò `ph04_owner` (NOLOGIN) sở hữu. `dh-integration` kết nối bằng tài khoản `dh_integration_app`, thành viên `ph04_app` (chỉ DML, không DDL, không `BYPASSRLS`); Liquibase chạy bằng `dh_integration_migrator` (thành viên `ph04_owner`); báo cáo, kiểm toán đọc bằng `ph04_readonly`, không đọc được nội dung định nghĩa luồng và xem trước bản tin (chỉ cột siêu dữ liệu của `flow_version`).

Tên schema giữ là `ph04` như mã hiện tại (không đổi sang `ph04_int`) để di trú tại chỗ; quy ước `ph{nn}_{miền}` của PH-07 áp cho schema mới. Thư viện runtime dùng schema riêng `ph04_rt` cho kho tổng hợp bền vững của EIP `aggregate` (FR-04-068); schema này do `dh-runtime` sở hữu, mô tả ở §6.4.

`dh-runtime` **không** kết nối schema `ph04`; mọi thông tin runtime cần (định nghĩa, trạng thái mong muốn) đến qua kho cấu hình Git, mọi thông tin runtime báo lại (nhịp tim, xác nhận) đi qua Kafka. Điều này giữ ranh giới control plane, data plane (ADR-013).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` (`T{nn}` theo D00-01 `T-TENANT`; `COMMON` ở bảng dùng chung) và bật `FORCE ROW LEVEL SECURITY` qua thủ tục `ph04.p_enable_rls(bảng, mẫu)`:

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng) | Dòng của tenant phiên | Dòng của tenant phiên (tỉnh) | 21 bảng tác nghiệp |
| S (dùng chung) | Dòng của tenant phiên và `COMMON` | Dòng của tỉnh khi phiên là tỉnh; dòng `COMMON` khi phiên là `PLATFORM` | `component_policy`, `template`, `palette_group_rule`, `catalog_change` |

: Hai mẫu RLS của schema `ph04`

Biến phiên `app.tenant_id` đặt ở đầu mỗi giao dịch bằng `TenantAwareTransactionManager` (D03-02-PH07 §6.2); quên đặt thì câu lệnh lỗi do `current_setting('app.tenant_id', false)`. Tác vụ nền liên tenant lặp từng tenant (D03-02-PH04 §11.3). Riêng `shedlock` là bảng kỹ thuật không có `tenant_id`.

### 1.3. Quy ước bảng

Theo D00-01 §5.1: khóa chính `id uuid` (UUID v7 sinh ở ứng dụng), `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (khóa lạc quan, trigger `tg_touch` tăng khi ứng dụng quên; là thành phần của ETag). Ngoại lệ có chủ đích:

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `flow_version_contributor`, `flow_route_index`, `flow_endpoint_index`, `flow_reference`, `test_run_step`, `command_ack`, `heartbeat_latest`, `external_system` | Khóa tự nhiên, không có `id`, không có cột sửa | Bảng con hoặc chỉ mục tính lại toàn bộ khi lưu |
| `review`, `catalog_change` | Chỉ thêm, không có `updated_*` | Nhật ký |
| `test_run`, `runtime_command`, `legacy_import_job` | Không có `version` | Chỉ máy chủ đổi trạng thái theo điều kiện trạng thái cũ, không có sửa đồng thời từ người dùng |
| `outbox` | Khóa `event_id` | DD-11 |

: Ngoại lệ có chủ đích với quy ước cột D00-01

Ràng buộc `CHECK` liệt kê giá trị trạng thái đúng như FRS §4.9–4.13; thêm giá trị là một changeset mới.

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ dưới chỉ vẽ các bảng có khóa ngoại với nhau, quanh hai trục: luồng và phiên bản (định nghĩa, duyệt, chạy thử) và triển khai (môi trường, lệnh, xác nhận). Năm bảng chính có liệt kê cột tiêu biểu.

```{.mermaid caption="Sơ đồ thực thể – quan hệ của schema ph04"}
erDiagram
    workspace ||--o{ workspace_member : "có"
    workspace ||--o{ flow : "chứa"
    workspace ||--o{ legacy_import_job : "nhận"
    flow ||--o{ flow_version : "có"
    flow ||--o{ test_case : "có"
    flow ||--o{ deployment : "triển khai"
    flow ||--o{ runtime_command : "nhận lệnh"
    flow_version ||--o{ flow_version_contributor : "người đóng góp"
    flow_version ||--o{ flow_mapping : "ánh xạ"
    flow_version ||--o{ flow_route_index : "route"
    flow_version ||--o{ flow_endpoint_index : "điểm kết nối"
    flow_version ||--o{ flow_reference : "tham chiếu"
    flow_version ||--o{ review : "duyệt"
    flow_version ||--o{ test_run : "chạy thử"
    flow_version ||--o{ deployment : "được triển khai"
    test_case ||--o{ test_run : "chạy theo ca"
    test_run ||--o{ test_run_step : "vết"
    deployment ||--o{ runtime_command : "trạng thái mong muốn"
    runtime_command ||--o{ command_ack : "xác nhận"
    flow {
      uuid id PK
      varchar tenant_id
      varchar code "duy nhất trong tenant"
      varchar status
      varchar exposure
    }
    flow_version {
      uuid id PK
      int version_no
      varchar status
      text definition_yaml
      jsonb canvas_layout
      jsonb samples
      char content_hash
    }
    deployment {
      uuid id PK
      varchar environment
      varchar desired_state
      varchar sync_status
      varchar health_status
      bool current
    }
    test_run {
      uuid id PK
      char definition_hash
      varchar mode
      varchar status
    }
    runtime_command {
      uuid id PK
      varchar action
      varchar status
      varchar signature
    }
```

Mọi đường trong hình là khóa ngoại thật mang kèm `tenant_id` (`FOREIGN KEY (x_id, tenant_id)`), nên không có quan hệ nào trỏ chéo tenant. `flow_version` là tâm của sơ đồ: chạy thử, duyệt, chỉ mục và triển khai đều gắn với một phiên bản cụ thể, đúng nguyên tắc "mọi thứ truy được về một phiên bản đã duyệt". Bảng không nằm trong sơ đồ vì không có khóa ngoại tới bảng khác: `heartbeat_latest` (khóa theo mã luồng để nhận nhịp tim kể cả khi CSDL chưa có triển khai tương ứng, phục vụ phát hiện băm lạ), `component_policy`, `component_proposal`, `template`, `palette_group_rule`, `catalog_change`, `external_system`, `outbox`, `shedlock`.

## 3. Đặc tả bảng

Toàn bộ phần giữa hai dấu `gen:tables` sinh bằng [`ph04/tools/gen_tables_md.py`](ph04/tools/gen_tables_md.py) `--write` từ DDL: khóa, ràng buộc, chỉ mục, mẫu RLS, trigger và quyền chỉ thêm đọc trực tiếp từ câu lệnh; mục đích lấy từ `COMMENT ON TABLE`; FR phục vụ và lưu giữ lấy từ bảng `META` của công cụ. Sửa ở DDL hoặc `META` rồi sinh lại, không sửa tay. Giá trị cụ thể của từng `CHECK` xem trong DDL; các ràng buộc mang quy tắc nghiệp vụ được tóm ở §3.27.

Bảng dưới là danh sách 26 bảng theo thứ tự trong DDL; cột "RLS" ghi mẫu P, S của §1.2.

<!-- gen:tables:start -->
| TT | Bảng | Thực thể | RLS | Số cột | FR phục vụ |
|---|---|---|---|---|---|
| 1 | `workspace` | EN-04-01 | P | 13 | FR-04-007 |
| 2 | `workspace_member` | EN-04-12 | P | 11 | FR-04-007; BR-04-021 |
| 3 | `flow` | EN-04-02 | P | 28 | FR-04-001…006 |
| 4 | `flow_version` | EN-04-03 | P | 28 | FR-04-010, 011, 017, 024, 027, 040…045 |
| 5 | `flow_version_contributor` | EN-04-13 | P | 6 | FR-04-024, 041; BR-04-005 |
| 6 | `flow_mapping` | EN-04-14 | P | 12 | FR-04-020 |
| 7 | `flow_route_index` | EN-04-04a | P | 7 | FR-04-001, 002, 023 (VR-08) |
| 8 | `flow_endpoint_index` | EN-04-04b | P | 10 | FR-04-001, 023 (VR-18), 052 |
| 9 | `flow_reference` | EN-04-04c | P | 5 | FR-04-006 |
| 10 | `review` | EN-04-05 | P | 12 | FR-04-040, 041, 043 |
| 11 | `deployment` | EN-04-06 | P | 27 | FR-04-042, 044, 045, 050, 051 |
| 12 | `test_case` | EN-04-15 | P | 18 | FR-04-031 |
| 13 | `test_run` | EN-04-07 | P | 25 | FR-04-030, 032, 040 (BR-04-004) |
| 14 | `test_run_step` | EN-04-08 | P | 15 | FR-04-030, 032, 033 |
| 15 | `runtime_command` | EN-04-10 | P | 22 | FR-04-050 |
| 16 | `command_ack` | EN-04-16 | P | 6 | FR-04-050, 051 |
| 17 | `heartbeat_latest` | EN-04-17 | P | 14 | FR-04-051, 052 |
| 18 | `component_policy` | EN-04-11 | S | 13 | FR-04-080 |
| 19 | `component_proposal` | EN-04-18 | P | 15 | FR-04-080 |
| 20 | `template` | EN-04-19 | S | 16 | FR-04-003, 025 |
| 21 | `palette_group_rule` | EN-04-20 | S | 10 | FR-04-012 |
| 22 | `catalog_change` | EN-04-21 | S | 10 | FR-04-081 |
| 23 | `external_system` | EN-04-22 | P | 7 | FR-04-003, 023 |
| 24 | `legacy_import_job` | EN-04-23 | P | 12 | FR-04-082 |
| 25 | `outbox` | EN-04-24 | P | 9 | FR-04-083; EVT-04-01…10 |
| 26 | `shedlock` | Kỹ thuật | Không | 4 | Không (kỹ thuật cho tác vụ nền) |

: Danh sách bảng của schema `ph04`

### 3.1. `workspace`

::: dac-ta
**Mục đích.** EN-04-01 · Không gian làm việc (FR-04-007); thay Project của Bus cũ. Mỗi tenant có sẵn DEFAULT.

**FR phục vụ.** FR-04-007.

**Khóa chính.** (id).

**Duy nhất.** `uq_workspace_id_tenant` (id, tenant_id); `uq_workspace_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_workspace_tenant`, `ck_workspace_code`, `ck_workspace_status`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: suốt vòng đời tenant; không xóa khi còn luồng, chuyển `ARCHIVED`. Trigger: `tg_workspace_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `code` | `varchar(63)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(4000)` |  |  |  |
| `owner_org_code` | `varchar(64)` |  |  |  |
| `status` | `varchar(16)` | x | `'ACTIVE'` |  |
| `legacy_project_id` | `bigint` |  |  | Project.id của Bus cũ khi di trú; dùng đối soát, không dùng cho nghiệp vụ. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `workspace`

### 3.2. `workspace_member`

::: dac-ta
**Mục đích.** EN-04-12 · Thành viên không gian: người dùng hoặc nhóm PH-12 với mức VIEW, EDIT, MAINTAIN; thay Project_group.access_level.

**FR phục vụ.** FR-04-007; BR-04-021.

**Khóa chính.** (id).

**Duy nhất.** `uq_workspace_member` (tenant_id, workspace_id, principal_type, principal_id).

**Khóa ngoại.** `fk_workspace_member_ws` (workspace_id, tenant_id) → `workspace`, xóa theo.

**Ràng buộc CHECK.** `ck_workspace_member_type`, `ck_workspace_member_level`.

**Chỉ mục.** `ix_workspace_member_principal`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: xóa khi gỡ thành viên hoặc xóa không gian (CASCADE). Trigger: `tg_workspace_member_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `workspace_id` | `uuid` | x |  |  |
| `principal_type` | `varchar(8)` | x |  |  |
| `principal_id` | `varchar(128)` | x |  |  |
| `access_level` | `varchar(10)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `workspace_member`

### 3.3. `flow`

::: dac-ta
**Mục đích.** EN-04-02 · Luồng tích hợp (FR-04-001…006); thay Context của Bus cũ.

**FR phục vụ.** FR-04-001…006.

**Khóa chính.** (id).

**Duy nhất.** `uq_flow_id_tenant` (id, tenant_id); `uq_flow_code_live` (tenant_id, code) có điều kiện.

**Khóa ngoại.** `fk_flow_workspace` (workspace_id, tenant_id) → `workspace`.

**Ràng buộc CHECK.** `ck_flow_tenant`, `ck_flow_code`, `ck_flow_kind`, `ck_flow_transport`, `ck_flow_exposure`, `ck_flow_status`, `ck_flow_origin`, `ck_flow_labels`, `ck_flow_targets`, `ck_flow_retired`.

**Chỉ mục.** `ix_flow_workspace`, `ix_flow_updated`, `ix_flow_search` (GIN), `ix_flow_labels` (GIN).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: suốt vòng đời luồng và 5 năm sau khi gỡ. Trigger: `tg_flow_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `workspace_id` | `uuid` | x |  |  |
| `code` | `varchar(63)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(4000)` |  |  |  |
| `resource_kind` | `varchar(8)` | x |  |  |
| `transport` | `varchar(10)` | x | `'SYNC'` | Suy ra từ chặng đầu; người dùng không sửa. |
| `exposure` | `varchar(10)` | x | `'INTERNAL'` |  |
| `status` | `varchar(12)` | x | `'DRAFT'` | Trạng thái tổng hợp, tính lại sau sự kiện phiên bản, triển khai, lệnh (D03-02-PH04 §9.2). |
| `source_system` | `varchar(64)` |  |  |  |
| `target_systems` | `varchar(64)[]` | x | `'{}'` |  |
| `labels` | `jsonb` | x | `'{}'` |  |
| `legal_basis_ref` | `varchar(128)` |  |  |  |
| `origin` | `varchar(12)` | x |  |  |
| `cloned_from_id` | `uuid` |  |  |  |
| `template_code` | `varchar(64)` |  |  |  |
| `emergency_paused` | `boolean` | x | `false` |  |
| `retired_at` | `timestamptz` |  |  |  |
| `retired_by` | `varchar(64)` |  |  |  |
| `retire_reason` | `varchar(1000)` |  |  |  |
| `code_released_at` | `timestamptz` |  |  |  |
| `legacy_context_id` | `bigint` |  |  | Context.id của Bus cũ khi di trú. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `flow`

### 3.4. `flow_version`

::: dac-ta
**Mục đích.** EN-04-03 · Phiên bản luồng (FR-04-010, 011, 024; ADR-069). Nội dung bất biến từ PENDING_REVIEW (trigger tg_flow_version_immutable).

**FR phục vụ.** FR-04-010, 011, 017, 024, 027, 040…045.

**Khóa chính.** (id).

**Duy nhất.** `uq_flow_version_id_tenant` (id, tenant_id); `uq_flow_version_no` (tenant_id, flow_id, version_no); `uq_flow_version_open` (tenant_id, flow_id) có điều kiện.

**Khóa ngoại.** `fk_flow_version_flow` (flow_id, tenant_id) → `flow`.

**Ràng buộc CHECK.** `ck_flow_version_status`, `ck_flow_version_no`, `ck_flow_version_size`, `ck_flow_version_samples_size`, `ck_flow_version_hash`, `ck_flow_version_submitted`, `ck_flow_version_approved`.

**Chỉ mục.** `ix_flow_version_review` có điều kiện, `ix_flow_version_components` (GIN), `ix_flow_version_revalidate` có điều kiện.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: suốt vòng đời luồng và 5 năm sau khi gỡ; `ph04_readonly` chỉ đọc cột siêu dữ liệu. Trigger: `tg_flow_version_touch`, `tg_flow_version_immutable`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_id` | `uuid` | x |  |  |
| `version_no` | `integer` | x |  |  |
| `status` | `varchar(18)` | x | `'DRAFT'` |  |
| `definition_yaml` | `text` | x |  |  |
| `canonical_yaml` | `text` |  |  |  |
| `content_hash` | `char(71)` | x |  | sha256 của YAML chuẩn hóa và *.jq (D03-02-PH04 §6.2); điều kiện chạy thử đạt gắn với băm này (BR-04-004). |
| `canvas_layout` | `jsonb` | x | `'{}'` | Bố cục sơ đồ, ghi chú dán, nhóm; không vào YAML triển khai (BR-04-007). |
| `samples` | `jsonb` | x | `'{}'` | Bản tin mẫu theo id chặng, mỗi bản ≤ 256 KiB; không vào YAML (BR-04-007). |
| `catalog_version` | `varchar(64)` | x |  |  |
| `last_validation` | `jsonb` |  |  |  |
| `needs_revalidation` | `boolean` | x | `false` |  |
| `components` | `text[]` | x | `'{}'` | Tên thành phần Camel dùng trong định nghĩa; phục vụ chọn hồ sơ runtime, VR-04, đánh dấu khi chính sách đổi. |
| `runtime_profile` | `varchar(32)` |  |  |  |
| `change_note` | `varchar(2000)` |  |  |  |
| `based_on_version_no` | `integer` |  |  |  |
| `submitted_hash` | `char(71)` |  |  |  |
| `submitted_at` | `timestamptz` |  |  |  |
| `submitted_by` | `varchar(64)` |  |  |  |
| `approved_at` | `timestamptz` |  |  |  |
| `approved_by` | `varchar(64)` |  |  |  |
| `discarded_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `flow_version`

### 3.5. `flow_version_contributor`

::: dac-ta
**Mục đích.** EN-04-13 · Người đóng góp phiên bản; dùng cho bốn mắt (BR-04-005, GAP-04-06). Ngoại lệ D00-01: khóa tự nhiên, không có id.

**FR phục vụ.** FR-04-024, 041; BR-04-005.

**Khóa chính.** (tenant_id, flow_version_id, user_id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_contributor_version` (flow_version_id, tenant_id) → `flow_version`, xóa theo.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: theo phiên bản (CASCADE).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `user_id` | `varchar(64)` | x |  |  |
| `first_at` | `timestamptz` | x | `now()` |  |
| `last_at` | `timestamptz` | x | `now()` |  |
| `save_count` | `integer` | x | `1` |  |

: Cột của bảng `flow_version_contributor`

### 3.6. `flow_mapping`

::: dac-ta
**Mục đích.** EN-04-14 · Ánh xạ dữ liệu *.dhmap.json và JQ sinh ra (FR-04-020, ADR-066). Chỉ jq vào kho cấu hình.

**FR phục vụ.** FR-04-020.

**Khóa chính.** (id).

**Duy nhất.** `uq_flow_mapping_name` (tenant_id, flow_version_id, name).

**Khóa ngoại.** `fk_flow_mapping_version` (flow_version_id, tenant_id) → `flow_version`, xóa theo.

**Ràng buộc CHECK.** `ck_flow_mapping_name`, `ck_flow_mapping_format`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: theo phiên bản (CASCADE). Trigger: `tg_flow_mapping_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `name` | `varchar(128)` | x |  |  |
| `node_id` | `varchar(128)` |  |  |  |
| `dhmap` | `jsonb` | x |  |  |
| `jq` | `text` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `flow_mapping`

### 3.7. `flow_route_index`

::: dac-ta
**Mục đích.** EN-04-04a · Chỉ mục route tính khi lưu (FR-04-001, 002; VR-08). URI đã che tham số nhạy cảm.

**FR phục vụ.** FR-04-001, 002, 023 (VR-08).

**Khóa chính.** (tenant_id, flow_version_id, route_id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_route_index_version` (flow_version_id, tenant_id) → `flow_version`, xóa theo.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** `ix_route_index_route`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: tính lại toàn bộ mỗi lần lưu; theo phiên bản (CASCADE).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `route_id` | `varchar(128)` | x |  |  |
| `from_uri` | `varchar(2048)` | x |  |  |
| `from_scheme` | `varchar(64)` | x |  |  |
| `description` | `varchar(1000)` |  |  |  |
| `step_count` | `integer` | x |  |  |

: Cột của bảng `flow_route_index`

### 3.8. `flow_endpoint_index`

::: dac-ta
**Mục đích.** EN-04-04b · Chỉ mục điểm kết nối (FR-04-001 lọc endpoint, FR-04-052; VR-18; FlowQueryApi.flowsUsingConnection, flowsUsingTopic).

**FR phục vụ.** FR-04-001, 023 (VR-18), 052.

**Khóa chính.** (tenant_id, flow_version_id, node_id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_endpoint_index_version` (flow_version_id, tenant_id) → `flow_version`, xóa theo.

**Ràng buộc CHECK.** `ck_endpoint_direction`.

**Chỉ mục.** `ix_endpoint_index_uri` (GIN), `ix_endpoint_index_path` có điều kiện, `ix_endpoint_index_conn` có điều kiện, `ix_endpoint_index_topic` có điều kiện.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: tính lại toàn bộ mỗi lần lưu; theo phiên bản (CASCADE).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `node_id` | `varchar(128)` | x |  |  |
| `direction` | `varchar(4)` | x |  |  |
| `scheme` | `varchar(64)` | x |  |  |
| `uri_masked` | `varchar(2048)` | x |  |  |
| `http_method` | `varchar(8)` |  |  |  |
| `http_path` | `varchar(1024)` |  |  |  |
| `connection_code` | `varchar(64)` |  |  |  |
| `topic` | `varchar(249)` |  |  |  |

: Cột của bảng `flow_endpoint_index`

### 3.9. `flow_reference`

::: dac-ta
**Mục đích.** EN-04-04c · Tham chiếu ra ngoài của phiên bản; tính phụ thuộc (API-04-016), chặn gỡ khi còn phụ thuộc cứng (FR-04-006).

**FR phục vụ.** FR-04-006.

**Khóa chính.** (tenant_id, flow_version_id, ref_type, ref_key).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_flow_reference_version` (flow_version_id, tenant_id) → `flow_version`, xóa theo.

**Ràng buộc CHECK.** `ck_flow_reference_type`.

**Chỉ mục.** `ix_flow_reference_key`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: tính lại toàn bộ mỗi lần lưu; theo phiên bản (CASCADE).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `ref_type` | `varchar(12)` | x |  |  |
| `ref_key` | `varchar(255)` | x |  |  |
| `hard` | `boolean` | x |  |  |

: Cột của bảng `flow_reference`

### 3.10. `review`

::: dac-ta
**Mục đích.** EN-04-05 · Nhật ký gửi, rút, duyệt, yêu cầu sửa của phiên bản (FR-04-040, 041, 043). Chỉ thêm, không sửa; ngoại lệ D00-01: không có updated_*.

**FR phục vụ.** FR-04-040, 041, 043.

**Khóa chính.** (id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_review_version` (flow_version_id, tenant_id) → `flow_version`.

**Ràng buộc CHECK.** `ck_review_action`, `ck_review_comment`.

**Chỉ mục.** `ix_review_version`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng; chỉ thêm (`ph04_app` bị thu hồi UPDATE, DELETE).

**Ghi chú.** Lưu giữ: suốt vòng đời luồng và 5 năm sau khi gỡ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `action` | `varchar(16)` | x |  |  |
| `actor` | `varchar(64)` | x |  |  |
| `content_hash` | `char(71)` | x |  |  |
| `comment` | `varchar(4000)` |  |  |  |
| `checklist` | `jsonb` |  |  |  |
| `node_comments` | `jsonb` | x | `'[]'` |  |
| `diff_viewed_at` | `timestamptz` |  |  |  |
| `reauth_at` | `timestamptz` |  |  |  |
| `occurred_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `review`

### 3.11. `deployment`

::: dac-ta
**Mục đích.** EN-04-06 · Triển khai phiên bản lên môi trường (FR-04-042, 044, 045); trạng thái mong muốn của lệnh điều khiển (FR-04-050).

**FR phục vụ.** FR-04-042, 044, 045, 050, 051.

**Khóa chính.** (id).

**Duy nhất.** `uq_deployment_id_tenant` (id, tenant_id); `uq_deployment_current` (tenant_id, flow_id, environment) có điều kiện.

**Khóa ngoại.** `fk_deployment_flow` (flow_id, tenant_id) → `flow`; `fk_deployment_version` (flow_version_id, tenant_id) → `flow_version`.

**Ràng buộc CHECK.** `ck_deployment_env`, `ck_deployment_kind`, `ck_deployment_desired`, `ck_deployment_sync`, `ck_deployment_health`, `ck_deployment_replicas`, `ck_deployment_reason`.

**Chỉ mục.** `ix_deployment_flow`, `ix_deployment_pending` có điều kiện.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: suốt vòng đời luồng và 5 năm sau khi gỡ. Trigger: `tg_deployment_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_id` | `uuid` | x |  |  |
| `flow_version_id` | `uuid` | x |  |  |
| `environment` | `varchar(8)` | x |  |  |
| `kind` | `varchar(10)` | x |  |  |
| `desired_state` | `varchar(8)` | x | `'RUNNING'` |  |
| `paused_routes` | `varchar(128)[]` | x | `'{}'` |  |
| `sync_status` | `varchar(12)` | x | `'PENDING'` |  |
| `health_status` | `varchar(8)` | x | `'UNKNOWN'` |  |
| `runtime_profile` | `varchar(32)` | x |  |  |
| `replicas` | `smallint` | x | `3` |  |
| `git_branch` | `varchar(64)` |  |  |  |
| `git_commit` | `char(40)` |  |  |  |
| `git_mr_ref` | `varchar(255)` |  |  |  |
| `note` | `varchar(1000)` |  |  |  |
| `reason` | `varchar(1000)` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `synced_at` | `timestamptz` |  |  |  |
| `current` | `boolean` | x | `false` | true với triển khai đang là mong muốn của môi trường; triển khai mới SYNCED thì bản cũ chuyển false. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `deployment`

### 3.12. `test_case`

::: dac-ta
**Mục đích.** EN-04-15 · Ca kiểm thử của luồng (FR-04-031); đi cùng luồng qua các phiên bản, ghi vào kho cấu hình tests/cases.dh.yaml. VR-20: ≥ 1 khẳng định.

**FR phục vụ.** FR-04-031.

**Khóa chính.** (id).

**Duy nhất.** `uq_test_case_id_tenant` (id, tenant_id); `uq_test_case_name` (tenant_id, flow_id, name).

**Khóa ngoại.** `fk_test_case_flow` (flow_id, tenant_id) → `flow`.

**Ràng buộc CHECK.** `ck_test_case_mode`, `ck_test_case_body`, `ck_test_case_assert`, `ck_test_case_timeout`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: theo luồng; ngừng dùng bằng `active = false`. Trigger: `tg_test_case_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_id` | `uuid` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(2000)` |  |  |  |
| `mode` | `varchar(12)` | x | `'MOCK'` |  |
| `input_body` | `text` |  |  |  |
| `input_headers` | `jsonb` | x | `'{}'` |  |
| `from_node_id` | `varchar(128)` |  |  |  |
| `mocks` | `jsonb` | x | `'{}'` |  |
| `assertions` | `jsonb` | x |  |  |
| `timeout_seconds` | `smallint` | x | `30` |  |
| `active` | `boolean` | x | `true` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `test_case`

### 3.13. `test_run`

::: dac-ta
**Mục đích.** EN-04-07 · Lần chạy thử (FR-04-030, 032). Giữ 04.test.retention-days (90); thân bản tin ở Ceph RGW dh-int-testrun, xóa sau 04.test.body-retention-days (7).

**FR phục vụ.** FR-04-030, 032, 040 (BR-04-004).

**Khóa chính.** (id).

**Duy nhất.** `uq_test_run_id_tenant` (id, tenant_id).

**Khóa ngoại.** `fk_test_run_version` (flow_version_id, tenant_id) → `flow_version`, xóa theo; `fk_test_run_case` (test_case_id, tenant_id) → `test_case`, xóa thì đặt NULL (test_case_id).

**Ràng buộc CHECK.** `ck_test_run_mode`, `ck_test_run_status`, `ck_test_run_sim`, `ck_test_run_timeout`.

**Chỉ mục.** `ix_test_run_version`, `ix_test_run_passed` có điều kiện, `ix_test_run_active` có điều kiện, `ix_test_run_retention`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: 90 ngày (`04.test.retention-days`), `TestRunRetentionJob` 02:30 hằng ngày.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_version_id` | `uuid` | x |  |  |
| `test_case_id` | `uuid` |  |  |  |
| `definition_hash` | `char(71)` | x |  |  |
| `mode` | `varchar(12)` | x |  |  |
| `status` | `varchar(10)` | x | `'QUEUED'` |  |
| `runtime_profile` | `varchar(32)` |  |  |  |
| `from_node_id` | `varchar(128)` |  |  |  |
| `capture_bodies` | `boolean` | x | `false` |  |
| `timeout_seconds` | `smallint` | x |  |  |
| `request_meta` | `jsonb` | x | `'{}'` | Tiêu đề (đã che), kích thước thân, khẳng định của lần chạy; không chứa thân. |
| `assertion_results` | `jsonb` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `error_summary` | `varchar(1000)` |  |  |  |
| `hung_node_id` | `varchar(128)` |  |  |  |
| `duration_ms` | `integer` |  |  |  |
| `trace_id` | `char(32)` |  |  |  |
| `sandbox_replica` | `varchar(128)` |  |  |  |
| `idempotency_key` | `varchar(128)` |  |  |  |
| `run_by` | `varchar(64)` | x |  |  |
| `queued_at` | `timestamptz` | x | `now()` |  |
| `started_at` | `timestamptz` |  |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `bodies_expire_at` | `timestamptz` |  |  |  |

: Cột của bảng `test_run`

### 3.14. `test_run_step`

::: dac-ta
**Mục đích.** EN-04-08 · Vết từng chặng của lần chạy thử, kể cả SKIPPED (FR-04-030). Xem trước thân đã che, ≤ 64 KiB (BR-04-013).

**FR phục vụ.** FR-04-030, 032, 033.

**Khóa chính.** (tenant_id, test_run_id, seq_no).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_test_run_step_run` (test_run_id, tenant_id) → `test_run`, xóa theo.

**Ràng buộc CHECK.** `ck_test_run_step_status`, `ck_test_run_step_stage`, `ck_test_run_step_preview`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: theo lần chạy (CASCADE); `ph04_readonly` không đọc được.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `test_run_id` | `uuid` | x |  |  |
| `seq_no` | `integer` | x |  |  |
| `node_id` | `varchar(128)` | x |  |  |
| `route_id` | `varchar(128)` |  |  |  |
| `stage` | `varchar(16)` |  |  |  |
| `status` | `varchar(10)` | x |  |  |
| `offset_ms` | `integer` | x |  |  |
| `duration_ms` | `integer` | x |  |  |
| `headers_masked` | `jsonb` |  |  |  |
| `body_in_preview` | `text` |  |  |  |
| `body_out_preview` | `text` |  |  |  |
| `body_object_key` | `varchar(512)` |  |  |  |
| `error_class` | `varchar(16)` |  |  |  |
| `error_text` | `varchar(1000)` |  |  |  |

: Cột của bảng `test_run_step`

### 3.15. `runtime_command`

::: dac-ta
**Mục đích.** EN-04-10 · Lệnh điều khiển runtime có ký Ed25519 (FR-04-050, ADR-065). Lý do chỉ lưu ở đây và kiểm toán, không đi lên topic.

**FR phục vụ.** FR-04-050.

**Khóa chính.** (id).

**Duy nhất.** `uq_runtime_command_id_tenant` (id, tenant_id).

**Khóa ngoại.** `fk_runtime_command_flow` (flow_id, tenant_id) → `flow`; `fk_runtime_command_dep` (deployment_id, tenant_id) → `deployment`.

**Ràng buộc CHECK.** `ck_runtime_command_action`, `ck_runtime_command_scope`, `ck_runtime_command_routes`, `ck_runtime_command_status`, `ck_runtime_command_reason`, `ck_runtime_command_expiry`.

**Chỉ mục.** `ix_runtime_command_flow`, `ix_runtime_command_open` có điều kiện.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: suốt vòng đời luồng và 5 năm sau khi gỡ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_id` | `uuid` | x |  |  |
| `deployment_id` | `uuid` | x |  |  |
| `environment` | `varchar(8)` | x |  |  |
| `action` | `varchar(16)` | x |  |  |
| `scope` | `varchar(8)` | x |  |  |
| `route_ids` | `varchar(128)[]` | x | `'{}'` |  |
| `drain` | `boolean` | x | `true` |  |
| `reason` | `varchar(1000)` | x |  |  |
| `incident_ref` | `varchar(128)` |  |  |  |
| `status` | `varchar(12)` | x | `'ISSUED'` |  |
| `expected_replicas` | `smallint` | x |  |  |
| `acked_replicas` | `smallint` | x | `0` |  |
| `key_id` | `varchar(64)` | x |  |  |
| `signature` | `varchar(128)` | x |  |  |
| `issued_by` | `varchar(64)` | x |  |  |
| `issued_at` | `timestamptz` | x | `now()` |  |
| `expires_at` | `timestamptz` | x |  |  |
| `acknowledged_at` | `timestamptz` |  |  |  |
| `git_commit` | `char(40)` |  |  |  |
| `reconciled_at` | `timestamptz` |  |  |  |

: Cột của bảng `runtime_command`

### 3.16. `command_ack`

::: dac-ta
**Mục đích.** EN-04-16 · Xác nhận lệnh từ từng bản sao runtime (EVT-04-13).

**FR phục vụ.** FR-04-050, 051.

**Khóa chính.** (tenant_id, command_id, replica).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_command_ack_cmd` (command_id, tenant_id) → `runtime_command`, xóa theo.

**Ràng buộc CHECK.** `ck_command_ack_result`, `ck_command_ack_reason`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: theo lệnh (CASCADE).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `command_id` | `uuid` | x |  |  |
| `replica` | `varchar(128)` | x |  |  |
| `result` | `varchar(10)` | x |  |  |
| `reason` | `varchar(32)` |  |  |  |
| `acked_at` | `timestamptz` | x |  |  |

: Cột của bảng `command_ack`

### 3.17. `heartbeat_latest`

::: dac-ta
**Mục đích.** EN-04-17 · Nhịp tim mới nhất của mỗi bản sao cho mỗi luồng (EVT-04-12); chỉ giữ bản mới nhất (UPSERT), lịch sử ở Prometheus. Dòng quá 10 phút bị dọn.

**FR phục vụ.** FR-04-051, 052.

**Khóa chính.** (tenant_id, flow_code, environment, replica).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_heartbeat_env`, `ck_heartbeat_state`.

**Chỉ mục.** `ix_heartbeat_seen`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: chỉ bản mới nhất (UPSERT); dòng quá 10 phút bị dọn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `flow_code` | `varchar(63)` | x |  |  |
| `environment` | `varchar(8)` | x |  |  |
| `replica` | `varchar(128)` | x |  |  |
| `profile` | `varchar(32)` | x |  |  |
| `namespace` | `varchar(63)` | x |  |  |
| `version_no` | `integer` | x |  |  |
| `content_hash` | `char(71)` | x |  |  |
| `flow_state` | `varchar(12)` | x |  |  |
| `load_error` | `varchar(1000)` |  |  |  |
| `routes` | `jsonb` | x |  |  |
| `image_digest` | `char(71)` |  |  |  |
| `lib_version` | `varchar(32)` |  |  |  |
| `seen_at` | `timestamptz` | x |  |  |

: Cột của bảng `heartbeat_latest`

### 3.18. `component_policy`

::: dac-ta
**Mục đích.** EN-04-11 · Chính sách thành phần: dòng COMMON là chính sách nền do PA đặt; dòng của tỉnh chỉ thu hẹp (PER_FLOW, DENIED). Không có dòng nghĩa là theo mặc định của nhóm (FR-04-080).

**FR phục vụ.** FR-04-080.

**Khóa chính.** (id).

**Duy nhất.** `uq_component_policy` (tenant_id, component_kind, component_name).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_component_policy_tenant`, `ck_component_policy_kind`, `ck_component_policy_decision`, `ck_component_policy_narrow`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi `COMMON` chỉ dưới `PLATFORM`.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: theo phiên bản chính sách; không xóa cứng. Trigger: `tg_component_policy_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `component_kind` | `varchar(12)` | x |  |  |
| `component_name` | `varchar(128)` | x |  |  |
| `decision` | `varchar(12)` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `approved_by_so` | `varchar(64)` |  |  |  |
| `policy_version` | `integer` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `component_policy`

### 3.19. `component_proposal`

::: dac-ta
**Mục đích.** EN-04-18 · Đề xuất cho phép, bổ sung thành phần (API-04-074, 110, 111). PA đọc liên tenant qua hàng đợi của PH-18 (sự kiện), không qua bảng.

**FR phục vụ.** FR-04-080.

**Khóa chính.** (id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_component_proposal_type`, `ck_component_proposal_status`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: không xóa; kết thúc bằng trạng thái cuối. Trigger: `tg_component_proposal_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `component_kind` | `varchar(12)` | x |  |  |
| `component_name` | `varchar(128)` | x |  |  |
| `proposal_type` | `varchar(12)` | x |  |  |
| `justification` | `varchar(4000)` | x |  |  |
| `status` | `varchar(10)` | x | `'OPEN'` |  |
| `decided_by` | `varchar(64)` |  |  |  |
| `decided_at` | `timestamptz` |  |  |  |
| `decision_note` | `varchar(2000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `component_proposal`

### 3.20. `template`

::: dac-ta
**Mục đích.** EN-04-19 · Khuôn mẫu luồng (FR-04-025): tám khuôn nền COMMON (tpl-standard-9…) và khuôn riêng của tỉnh.

**FR phục vụ.** FR-04-003, 025.

**Khóa chính.** (id).

**Duy nhất.** `uq_template_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_template_tenant`, `ck_template_code`, `ck_template_status`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi `COMMON` chỉ dưới `PLATFORM`.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: ngừng dùng bằng `DEPRECATED`. Trigger: `tg_template_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `code` | `varchar(64)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(4000)` |  |  |  |
| `category` | `varchar(32)` | x |  |  |
| `resource_kind` | `varchar(8)` | x | `'ROUTE'` |  |
| `body_yaml` | `text` | x |  |  |
| `param_schema` | `jsonb` | x |  |  |
| `catalog_version` | `varchar(64)` | x |  |  |
| `status` | `varchar(10)` | x | `'ACTIVE'` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `template`

### 3.21. `palette_group_rule`

::: dac-ta
**Mục đích.** EN-04-20 · Tài liệu palette-groups.json (D03-02-PH04 §6.3); một bản active.

**FR phục vụ.** FR-04-012.

**Khóa chính.** (id).

**Duy nhất.** `uq_palette_group_rule` (tenant_id, rules_version); `uq_palette_active` (tenant_id) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_palette_tenant`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi `COMMON` chỉ dưới `PLATFORM`.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: giữ mọi bản; một bản `active`. Trigger: `tg_palette_touch`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x | `'COMMON'` | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `rules_version` | `integer` | x |  |  |
| `document` | `jsonb` | x |  |  |
| `active` | `boolean` | x | `false` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `palette_group_rule`

### 3.22. `catalog_change`

::: dac-ta
**Mục đích.** EN-04-21 · Khác biệt catalog giữa hai phiên bản runtime (FR-04-081, UC-04-22).

**FR phục vụ.** FR-04-081.

**Khóa chính.** (id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_catalog_change_tenant`, `ck_catalog_change_type`.

**Chỉ mục.** `ix_catalog_change_ver`.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi `COMMON` chỉ dưới `PLATFORM`.

**Phân vùng, chỉ thêm.** Không phân vùng; chỉ thêm (`ph04_app` chỉ có INSERT).

**Ghi chú.** Lưu giữ: không xóa, để tra lịch sử nâng catalog.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x | `'COMMON'` | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `from_version` | `varchar(64)` | x |  |  |
| `to_version` | `varchar(64)` | x |  |  |
| `component_kind` | `varchar(12)` | x |  |  |
| `component_name` | `varchar(128)` | x |  |  |
| `property_name` | `varchar(128)` |  |  |  |
| `change_type` | `varchar(12)` | x |  |  |
| `detail` | `jsonb` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |

: Cột của bảng `catalog_change`

### 3.23. `external_system`

::: dac-ta
**Mục đích.** EN-04-22 · Bản sao đọc HTTT đã kết nạp của PH-01 (sự kiện); xác định luồng đối ngoại, kiểm ERR-04-043.

**FR phục vụ.** FR-04-003, 023.

**Khóa chính.** (tenant_id, code).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: cập nhật theo sự kiện PH-01; không xóa cứng.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `code` | `varchar(64)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `status` | `varchar(12)` | x |  |  |
| `is_member` | `boolean` | x |  |  |
| `source_event_id` | `uuid` | x |  |  |
| `synced_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `external_system`

### 3.24. `legacy_import_job`

::: dac-ta
**Mục đích.** EN-04-23 · Lượt chuyển Camel XML của Bus cũ (FR-04-082). Tệp gốc không lưu sau khi chuyển; báo cáo không chứa mật khẩu.

**FR phục vụ.** FR-04-082.

**Khóa chính.** (id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** `fk_legacy_import_ws` (workspace_id, tenant_id) → `workspace`.

**Ràng buộc CHECK.** `ck_legacy_import_status`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: giữ hết giai đoạn di trú; tệp gốc không lưu.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `workspace_id` | `uuid` | x |  |  |
| `file_name` | `varchar(255)` | x |  |  |
| `file_sha256` | `char(64)` | x |  |  |
| `status` | `varchar(10)` | x | `'RUNNING'` |  |
| `report` | `jsonb` |  |  |  |
| `created_flow_ids` | `uuid[]` | x | `'{}'` |  |
| `error_code` | `varchar(16)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `finished_at` | `timestamptz` |  |  |  |

: Cột của bảng `legacy_import_job`

### 3.25. `outbox`

::: dac-ta
**Mục đích.** EN-04-24 · Outbox (DD-11) cho EVT-04-01…10 và kiểm toán gửi PH-13; Debezium EventRouter. Dọn sau 3 ngày.

**FR phục vụ.** FR-04-083; EVT-04-01…10.

**Khóa chính.** (event_id).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_tenant`, `ck_outbox_type`, `ck_outbox_topic`, `ck_outbox_topic_tenant`, `ck_outbox_trace`.

**Chỉ mục.** `ix_outbox_occurred`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ dòng của tenant phiên.

**Phân vùng, chỉ thêm.** Không phân vùng; chỉ thêm (`ph04_app` bị thu hồi UPDATE).

**Ghi chú.** Lưu giữ: 3 ngày, dọn sau khi Debezium đã gửi.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  |  |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `event_type` | `varchar(128)` | x |  |  |
| `topic` | `varchar(249)` | x |  |  |
| `aggregate_type` | `varchar(64)` | x |  |  |
| `aggregate_id` | `text` | x |  |  |
| `payload` | `jsonb` | x |  |  |
| `trace_id` | `char(32)` | x |  |  |
| `occurred_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `outbox`

### 3.26. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền (ShedLock); bảng kỹ thuật không có tenant_id, không chứa dữ liệu nghiệp vụ.

**FR phục vụ.** Không (kỹ thuật cho tác vụ nền).

**Khóa chính.** (name).

**Duy nhất.** Không ngoài khóa chính.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không RLS; bảng kỹ thuật không có `tenant_id`, không chứa dữ liệu nghiệp vụ.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Lưu giữ: ghi đè theo tên khóa.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  |  |
| `lock_until` | `timestamptz` | x |  |  |
| `locked_at` | `timestamptz` | x |  |  |
| `locked_by` | `varchar(255)` | x |  |  |

: Cột của bảng `shedlock`
<!-- gen:tables:end -->

### 3.27. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc dưới đây được CSDL tự chặn, nên một lỗi ở ứng dụng cũng không phá được chúng; bài kiểm §4.2 thử từng quy tắc.

| Quy tắc | Cơ chế CSDL | Đối tượng |
|---|---|---|
| BR-04-001 mã luồng duy nhất, giải phóng sau 30 ngày khi gỡ | Chỉ mục duy nhất có điều kiện `code_released_at IS NULL` | `uq_flow_code_live` |
| BR-04-016 tối đa một phiên bản mở | Chỉ mục duy nhất có điều kiện trạng thái mở | `uq_flow_version_open` |
| BR-04-016 phiên bản đã gửi duyệt bất biến | Trigger chặn sửa `definition_yaml`, `content_hash`, `samples` | `tg_flow_version_immutable` |
| ADR-069 duyệt gắn băm | `CHECK` trạng thái đã duyệt cần `approved_by` và `content_hash = submitted_hash` | `ck_flow_version_approved` |
| FR-04-080 tỉnh chỉ thu hẹp chính sách | `CHECK tenant_id = 'COMMON' OR decision <> 'ALLOWED'` | `ck_component_policy_narrow` |
| Một triển khai hiện hành mỗi môi trường | Chỉ mục duy nhất `WHERE current` | `uq_deployment_current` |
| Lệnh có lý do, hết hạn ngắn | `CHECK` độ dài lý do 10–1.000, `expires_at` ≤ 5 phút sau phát | `ck_runtime_command_*` |
| Lần chạy mô phỏng không lẫn với lần chạy thật | `CHECK (mode = 'SIMULATED') = (status = 'SIMULATED')` | `ck_test_run_sim` |
| VR-20 ca kiểm thử có khẳng định | `CHECK` mảng 1–20 phần tử | `ck_test_case_assert` |
| BR-04-007 bố cục, bản tin mẫu tách YAML | Cột riêng `canvas_layout`, `samples` | `flow_version` |
| Nhật ký duyệt chỉ thêm | Thu hồi `UPDATE`, `DELETE` của `ph04_app` | `review` |
| Kích thước | `CHECK octet_length(definition_yaml) <= 524288`, bản tin ca ≤ 256 KiB, xem trước ≤ 64 KiB | nhiều bảng |

: Quy tắc nghiệp vụ chốt ở CSDL

### 3.28. Truy vấn chính và chỉ mục phục vụ

Mỗi chỉ mục phụ có ít nhất một truy vấn dùng nó; bảng dưới nối truy vấn, API gọi và chỉ mục.

| Truy vấn | API | Chỉ mục |
|---|---|---|
| Danh sách luồng theo không gian, trạng thái, sắp theo cập nhật, phân trang con trỏ | API-04-010 | `ix_flow_workspace`, `ix_flow_updated` |
| Tìm theo mã, tên, mô tả (không dấu ở ứng dụng) | API-04-010 `q` | `ix_flow_search` (trigram) |
| Lọc theo nhãn | API-04-010 `label` | `ix_flow_labels` (`jsonb_path_ops`) |
| Lọc theo endpoint | API-04-010 `endpoint` | `ix_endpoint_index_uri` (trigram) |
| Trùng đường dẫn HTTP đang chạy (VR-18) | API-04-030 | `ix_endpoint_index_path` |
| Luồng dùng kết nối, topic | `FlowQueryApi` | `ix_endpoint_index_conn`, `ix_endpoint_index_topic`, `ix_flow_reference_key` |
| Hàng đợi duyệt | API-04-053 | `ix_flow_version_review` |
| Điều kiện gửi duyệt (BR-04-004) | API-04-050 | `ix_test_run_passed` |
| Hạn mức chạy thử đồng thời (dự phòng khi Valkey mất) | API-04-040 | `ix_test_run_active` |
| Triển khai đang chờ đồng bộ | `Reconciler` | `ix_deployment_pending` |
| Lệnh chưa đối soát | `Reconciler` | `ix_runtime_command_open` |
| Luồng dùng thành phần (khi chính sách đổi) | `CatalogService` | `ix_flow_version_components` (GIN mảng) |

: Truy vấn chính và chỉ mục phục vụ

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph04/ddl/ph04_int.sql`](ph04/ddl/ph04_int.sql) là nguồn duy nhất, chia tệp changeset bằng dấu `-- @file`, `-- @changeset`, `-- @rollback` như PH-07; changelog Liquibase sinh bằng công cụ của PH-07 (`../ph07/tools/gen_liquibase.py`) sau khi tham số hóa tên phân hệ (việc của bước 1 lộ trình D03-02-PH04 §15). Thứ tự tệp:

| Tệp | Nội dung |
|---|---|
| `04-0000-bootstrap.sql` | Vai trò, schema, extension `pg_trgm` (ph04-0003), chủ sở hữu schema và bảng W2 (ph04-0004), biến phiên migration |
| `04-0001-functions.sql` | `tg_touch`, `p_enable_rls` |
| `04-0010-workspace.sql` | `workspace`, `workspace_member` |
| `04-0020-flow.sql` | `flow`, `flow_version` + trigger bất biến, `flow_version_contributor`, `flow_mapping` |
| `04-0030-index.sql` | `flow_route_index`, `flow_endpoint_index`, `flow_reference` |
| `04-0040-review.sql` | `review` |
| `04-0050-deployment.sql` | `deployment` |
| `04-0060-test.sql` | `test_case`, `test_run`, `test_run_step` |
| `04-0070-runtime.sql` | `runtime_command`, `command_ack`, `heartbeat_latest` |
| `04-0080-catalog.sql` | `component_policy`, `component_proposal`, `template`, `palette_group_rule`, `catalog_change` |
| `04-0090-misc.sql` | `external_system`, `legacy_import_job`, `outbox`, `shedlock` |
| `04-0900-grants.sql` | Quyền (chạy lại mỗi lần) |
| `04-9000-migrate-legacy-tables.sql` | Di trú bảng W2 (context `migrate-w2`) |

: Thứ tự tệp changeset

### 4.2. Kết quả chạy thử

Kiểm tra đã làm ngày 25/11/2026 (PostgreSQL 16.x, dữ liệu giả): chạy trên CSDL trống không lỗi; chạy trên CSDL có bốn bảng W2 với một luồng hai phiên bản và một lần chạy thử, kết quả luồng `APPROVED`, phiên bản 1 `APPROVED` (người duyệt `system:migrate`), phiên bản 2 `DRAFT`, lần chạy thử `SIMULATED`, bảng cũ đổi tên `*_legacy_w2`; tài khoản `ph04_app` với `app.tenant_id = 'T01'` thấy 0 dòng của T68 và bị chặn khi chèn dòng T68; tỉnh chèn chính sách `ALLOWED` bị `ck_component_policy_narrow` chặn. Bài kiểm thử `TenantIsolationIT` (D03-02-PH04 §14) tự động hóa các ca này cho mọi bảng.

Chạy lại ngày 26/11/2026 trên PostgreSQL 16.15 cài sạch (bản 0.2), phát hiện và sửa hai lỗi của DDL bản 0.1:

| Lỗi | Hiện tượng | Sửa |
|---|---|---|
| Thiếu extension `pg_trgm` | `ix_flow_search`, `ix_endpoint_index_uri` dùng `public.gin_trgm_ops`; trên CSDL chưa có extension, câu `CREATE INDEX` lỗi "operator class does not exist" | Thêm changeset `ph04-0003-extensions` (`CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public`) như PH-07 |
| Schema W2 có sẵn do tài khoản khác sở hữu | Trên CSDL W2, `CREATE SCHEMA IF NOT EXISTS ph04 AUTHORIZATION ph04_owner` bỏ qua; `ph04_owner` bị "permission denied for schema ph04" và không đổi tên được bảng `route*` | Thêm changeset `ph04-0004-legacy-owner` chuyển quyền sở hữu schema và bốn bảng cũ (nếu có) cho `ph04_owner` |

: Lỗi DDL phát hiện khi chạy thử bản 0.2

Sau khi sửa:

- DDL chạy không lỗi trên CSDL trống: 26 bảng, 25 bảng bật RLS, 100 chính sách (4 mỗi bảng).
- Trên CSDL giả lập W2 (schema `ph04` do `postgres` sở hữu, một `route` `PUBLISHED`, hai `route_version` `PUBLISHED` và `TESTING`, một `route_test_run`): luồng `APPROVED`, phiên bản 1 `APPROVED` (`system:migrate`), phiên bản 2 `DRAFT`, cả hai `needs_revalidation = true`, lần chạy thử `SIMULATED`, bốn bảng cũ đổi tên `*_legacy_w2`.
- [`ph04/test/ph04_isolation_test.sql`](ph04/test/ph04_isolation_test.sql) dưới tài khoản `dh_integration_app` (thành viên `ph04_app`) đạt 23 khối: T01 không đọc, không chèn, không sửa được dòng T68; khóa ngoại không trỏ chéo tenant; tỉnh không đặt `ALLOWED`, không ghi dòng `COMMON` nhưng đọc được; phiên bản mở thứ hai bị chặn; duyệt sai băm hoặc thiếu người duyệt bị chặn; sửa nội dung phiên bản `PENDING_REVIEW` bị chặn; triển khai hiện hành thứ hai, quay lui thiếu lý do bị chặn; lần chạy `SIMULATED` không thể `PASSED`; ca không có khẳng định bị chặn; lệnh hạn quá 5 phút, phạm vi `ROUTES` thiếu route bị chặn; sửa `review` bị chặn; yêu cầu sửa thiếu ý kiến bị chặn; outbox sai tenant bị chặn; mã luồng trùng bị chặn; `ph04_readonly` không đọc được `definition_yaml` nhưng đọc được cột siêu dữ liệu.

Lỗi thứ hai (schema do tài khoản khác sở hữu) có ca tự động dẫn chiếu là TC-04-202 ở D05-02-PH04 (Testcontainers PostgreSQL, schema `ph04` tạo sẵn do `postgres` sở hữu, bốn bảng W2); ca kiểm lại kết quả sau khi chạy `ph04-9000` như liệt kê ở trên.

## 5. Dữ liệu khởi tạo

Dữ liệu khởi tạo chỉ gồm danh mục nền dùng chung và không gian mặc định; không có dữ liệu nghiệp vụ mẫu ở môi trường thật.

| Dữ liệu | Tenant | Nội dung | Nguồn |
|---|---|---|---|
| Không gian `DEFAULT` | Mỗi tỉnh | Tạo khi PH-20 khởi tạo tenant (sự kiện), không bằng seed | FRS §4.2 |
| Chính sách thành phần nền | `COMMON` | Dòng `DENIED` cho `exec`, `ssh`, `docker`, `kubernetes-*`, ngôn ngữ `groovy`, `js`, `python`, `mvel`, `ognl`; dòng `PER_FLOW` cho `sql` ghi, `mail`; còn lại theo mặc định nhóm của `CatalogService` | FRS FR-04-080 |
| Tám khuôn mẫu nền | `COMMON` | `tpl-standard-9`, `tpl-sync-lookup`, `tpl-soap-to-rest`, `tpl-db-poll-to-kafka`, `tpl-kafka-to-rest`, `tpl-sftp-to-kafka`, `tpl-ndxp-proxy`, `tpl-cdm-normalize`; thân YAML đóng gói cùng `dh-integration` (`classpath:templates/`), seed đồng bộ theo băm | FR-04-025 |
| Quy tắc nhóm bảng thành phần | `COMMON` | `palette-groups.json` bản 1, `active = true` | D03-02-PH04 §6.3 |

: Dữ liệu khởi tạo

Seed chạy dưới `app.tenant_id = 'PLATFORM'`, lũy đẳng (`ON CONFLICT DO UPDATE` theo mã khi băm nội dung khác).

## 6. Kho lưu trữ ngoài PostgreSQL

Ngoài schema `ph04`, PH-04 dùng Kafka cho sự kiện và kênh runtime, Valkey cho dữ liệu ngắn hạn, Ceph RGW cho thân bản tin chạy thử và một schema riêng của runtime cho EIP `aggregate`. Không kho nào trong số này là nguồn sự thật duy nhất của dữ liệu quản trị.

### 6.1. Kafka

| Topic | Chủ | Phân vùng, giữ | Khóa | Nội dung |
|---|---|---|---|---|
| `{tenant}.integration.*.v1` (EVT-04-01…10) | `dh-integration` qua outbox | 3 phân vùng, giữ 7 ngày | `flowId` | Sự kiện miền, không có định nghĩa YAML |
| `dh.integration.runtime.command.v1` (EVT-04-11) | `dh-integration` (ACL ghi duy nhất) | 12, giữ 1 ngày | `tenant/flow` | Lệnh có ký |
| `dh.integration.runtime.heartbeat.v1` (EVT-04-12) | `dh-runtime` | 12, giữ 1 giờ, `cleanup.policy=delete` | `replica` | Nhịp tim |
| `dh.integration.runtime.command-ack.v1` (EVT-04-13) | `dh-runtime` | 12, giữ 1 ngày | `commandId` | Xác nhận |
| `{tenant}.audit.connection-log.v1` (EVT-04-14) | PH-13 (chủ), `dh-runtime` ghi | Theo PH-13 | `traceId` | Nhật ký kết nối NĐ 278/2025 |
| `{tenant}.ops.dlq.v1` | PH-18 (chủ), `dh-runtime` ghi | Theo PH-18 | `flow` | Bản tin lỗi đã mã hóa trường nhạy cảm |

: Topic Kafka của PH-04

Topic hệ thống `dh.*` dùng chung mọi tenant vì runtime trong namespace dùng chung phục vụ nhiều tenant; thông điệp mang `tenant` và runtime kiểm khớp nhãn luồng (D03-02-PH04 §10.1). Thông điệp không chứa dữ liệu nghiệp vụ.

### 6.2. Valkey

| Khóa | Kiểu | TTL | Dùng cho |
|---|---|---|---|
| `dh:int:edit:{tenant}:{flowId}:{versionNo}` | Hash, TTL theo trường | 120 s mỗi trường | Phiên soạn (EN-04-09) |
| `dh:int:idem:api:{tenant}:{key}` | String (băm thân + kết quả) | 24 giờ | `Idempotency-Key` của API |
| `dh:int:testrun:queue` | Stream, nhóm theo hồ sơ | Không TTL | Hàng đợi chạy thử |
| `dh:int:testrun:active:{tenant}` | Sorted set (runId, hạn) | 2 × thời hạn | Hạn mức đồng thời |
| `dh:int:catalog:{tenant}:{catalogVersion}` | String (JSON nén) | 24 giờ | Chỉ mục catalog đã lọc chính sách |
| `dh:int:idem:{tenant}:{flow}:{key}` | String | `04.runtime.idempotency-ttl-hours` | Chống trùng bản tin ở runtime (FR-04-071), do `dh-runtime` dùng trên Valkey data plane |

: Khóa Valkey của PH-04

Valkey mất dữ liệu không làm sai nghiệp vụ: phiên soạn chỉ là thông tin, hạn mức chạy thử dự phòng bằng `ix_test_run_active`, hàng đợi chạy thử dựng lại từ `test_run` trạng thái `QUEUED`.

### 6.3. Kho đối tượng

Bucket `dh-int-testrun` trên Ceph RGW (Q306 chốt Ceph RGW cho WORM và sao lưu; bucket này không WORM), khóa `{tenant}/{runId}/{nodeId}-{in|out}.json`, mã hóa phía máy chủ, quy tắc vòng đời xóa sau 7 ngày (khớp `04.test.body-retention-days`; tỉnh đặt ngắn hơn thì `TestRunRetentionJob` xóa sớm). Chính sách bucket chỉ cho `dh-runtime-sandbox` ghi và `dh-integration` đọc, xóa; tiền tố theo tenant để kiểm toán.

### 6.4. Schema `ph04_rt` của runtime

Kho tổng hợp bền vững (`JdbcAggregationRepository`) cho EIP `aggregate` khi luồng có nhiều bản sao: bảng `aggregation_{flow}` và `aggregation_{flow}_completed` tạo khi luồng được nạp lần đầu (tài khoản `dh_runtime_app`, quyền `CREATE` chỉ trong `ph04_rt`), có cột `tenant_id` và RLS mẫu P. Luồng không dùng `aggregate` không tạo bảng. Dữ liệu là bản tin đang gộp nên mã hóa trường nhạy cảm như DLQ, dọn dòng hoàn tất sau 24 giờ. Thay thế bằng Valkey khi tỉnh chọn (FR-04-068), không đổi hợp đồng luồng.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Bảng dưới nói mỗi nhóm dữ liệu được sao lưu thế nào, giữ bao lâu và ai dọn. Dữ liệu có thể dựng lại (nhịp tim, outbox đã gửi) giữ ngắn; dữ liệu phục vụ kiểm toán thay đổi giữ suốt vòng đời luồng và 5 năm sau khi gỡ.

| Đối tượng | Sao lưu | Lưu giữ | Ghi chú |
|---|---|---|---|
| Schema `ph04` | Theo `pg-core`: WAL liên tục + base backup hằng ngày lên Ceph RGW, RPO 5 phút (D03-09) | Theo bảng | Mã hóa lưu trữ ở mức ổ đĩa và bản sao lưu |
| `test_run`, `test_run_step` | Như trên | 90 ngày (`04.test.retention-days`) | `TestRunRetentionJob` 02:30 hằng ngày |
| `heartbeat_latest` | Không cần | 10 phút | Dựng lại từ nhịp tim |
| `outbox` | Như trên | 3 ngày | Dọn sau khi Debezium đã gửi |
| `flow_version`, `review`, `deployment`, `runtime_command` | Như trên | Suốt vòng đời luồng + 5 năm sau khi gỡ | Kiểm toán thay đổi; bản ghi kiểm toán gốc ở PH-13 (WORM 5 năm) |
| Kho `dh-flows-{tenant}` | Mirror sang site DR, sao lưu Git hằng ngày (ADR-068, D03-09) | Không xóa lịch sử | Là nguồn sự thật triển khai; khôi phục DR nạp lại runtime từ Git |

: Sao lưu và lưu giữ theo đối tượng

Khôi phục `ph04` về thời điểm trước kho Git: `Reconciler` phát hiện triển khai có ở Git mà không có ở CSDL (băm lạ, §10.3 SDD) và báo động; quy trình DR (D03-09) quy định đồng bộ lại `deployment` từ `flow.dh.yaml` của các nhánh môi trường.

## 8. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

Chương này là đầu vào cho kế hoạch di trú D06-01: bảng của Bus và Productivity Tooling (hệ cũ của tỉnh) và bảng của mã hiện tại W2 đi về bảng nào của thiết kế mới, cột nào không chuyển và vì sao.

### 8.1. Bus và Productivity Tooling

Lược đồ chi tiết của Bus cũ chưa có trong bộ tài liệu được cung cấp; bảng dưới dựa trên tên bảng và chức năng mô tả ở FRS §2.2. Tên cột chính xác cần đối chiếu khi có bản xuất CSDL của tỉnh (giả định GĐ, Q04-50).

| Bảng hệ cũ | Đích | Cách chuyển |
|---|---|---|
| `Project` | `workspace` | Một dự án thành một không gian; `legacy_project_id` giữ mã cũ |
| `Group` | Nhóm PH-12 (Keycloak) | Đội di trú tạo nhóm tương ứng ở PH-12 trước |
| `Project_group` (`access_level`) | `workspace_member` (`principal_type = GROUP`) | Ánh xạ mức truy cập cũ sang `VIEW`, `EDIT`, `MAINTAIN` theo bảng ánh xạ do tỉnh duyệt |
| `Context` | `flow` + `legacy_import_job` | Mỗi context thành một luồng nháp qua FR-04-082; `legacy_context_id` giữ mã cũ |
| `Context_file`, `File` | `flow_version` (v1 `DRAFT`, `origin = LEGACY_XML`) | XML chuyển sang YAML; mật khẩu gỡ; tệp gốc không lưu |
| `Context_status` | Không chuyển | Trạng thái chạy cũ không còn ý nghĩa; luồng mới bắt đầu ở `DRAFT` |
| `Dependency`, `Builder` | Không chuyển; báo cáo trong `legacy_import_job.report` | Thay bằng hồ sơ runtime và chính sách thành phần (LGC-BUS-034); thành phần thiếu thành đề xuất `component_proposal` |
| `draft_session` | IndexedDB phía trình duyệt + `flow_version` `DRAFT` | Không chuyển dữ liệu (phiên nháp cũ đã hết hạn) |

: Ánh xạ bảng Bus và Productivity Tooling

### 8.2. Bảng của mã hiện tại (`apps/control`, W2)

| Bảng, cột hiện tại | Đích | Ghi chú |
|---|---|---|
| `route.route_id`, `route_code`, `title` | `flow.id`, `code`, `name` | Giữ `id` để liên kết ngoài không gãy |
| `route.route_type` | `flow.transport` | `ASYNC` giữ, khác thành `SYNC`; tính lại khi lưu lần đầu |
| `route.status` | `flow.status` | `PUBLISHED` → `APPROVED`, `PAUSED` giữ, khác → `DRAFT` |
| `route.source_system`, `target_system` | `flow.source_system`, `target_systems[]` | `exposure` suy từ đích |
| `route_version.*` | `flow_version` | `TESTING` → `DRAFT` (ADR-069); băm tạm, `needs_revalidation = true` |
| `route_version.git_commit_ref`, `git_path` | Không chuyển | GitOps cũ ghi vào repo mã (GAP-04-03) |
| `route_test_run.*` | `test_run` `SIMULATED` | Không thỏa BR-04-004 |
| `route_test_run_stage.*` | Không chuyển | Waterfall giả (GAP-04-04) |
| Chú thích `# @lgsp-canvas-v1:` trong YAML | `flow_version.canvas_layout` | `dh-integration` tách khi lưu lần đầu sau di trú |

: Ánh xạ bảng của mã hiện tại W2

### 8.3. Đối soát sau di trú

Sau di trú, `dh-integration` chạy `LegacyReconcileReport`: số luồng, phiên bản, lần chạy thử trước và sau; luồng có phiên bản `APPROVED` nhưng chưa có triển khai (cần phát hành lại); phiên bản có `needs_revalidation`. Báo cáo là đầu vào nghiệm thu bước 1 lộ trình D03-02-PH04 §15.

## 9. Câu hỏi mở

Các câu hỏi dưới đây có đề xuất tạm nên không chặn việc viết mã và DDL.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q04-50 | Tên cột chính xác của `Project_group`, `Context`, `Context_file` hệ cũ; giá trị `access_level` | Giả định GĐ; đối chiếu khi có bản xuất CSDL của tỉnh |
| Q04-51 | Giữ `flow_version` của luồng đã gỡ 5 năm có đủ cho kiểm toán cấp độ 3? | Đủ; bản ghi kiểm toán gốc ở PH-13 WORM 5 năm |
| Q04-52 | `heartbeat_latest` khóa theo mã luồng (không khóa ngoại) có làm sót dòng của luồng đã gỡ? | Tác vụ dọn 10 phút xóa dòng cũ, không cần khóa ngoại |
| Q04-53 | Có tách `definition_yaml` sang bảng riêng để giảm kích thước dòng `flow_version`? | Không ở MVP; PostgreSQL TOAST xử lý, truy vấn danh sách không chọn cột lớn |
| Q04-54 | Schema `ph04_rt` dùng `pg-core` hay cụm riêng cho data plane? | Cụm riêng `pg-runtime` khi có luồng `aggregate` ở PROD; MVP chưa cần |

: Câu hỏi mở của CSDL PH-04

### 9.1. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các điểm dưới cần tập khác đối chiếu; tài liệu này không sửa chéo.

| Tập | Đề nghị | Trạng thái |
|---|---|---|
| D03-02-PH04 SDD §14 | `TenantIsolationIT` lấy 23 khối của `ph04/test/ph04_isolation_test.sql` làm ca tối thiểu | Đã hấp thụ (0.2): SDD §14, dòng Cách ly tenant |
| D05-02-PH04 Ca kiểm thử | Thêm ca di trú W2 khi schema `ph04` do tài khoản khác sở hữu (lỗi thứ hai ở §4.2) | Đã hấp thụ (0.2): TC-04-202 |
| D03-09 Hạ tầng | Ghi `pg_trgm` vào danh sách extension bắt buộc của cụm `pg-core` | Chờ đợt đồng bộ cuối (tập ngoài PH-04) |
| D03-04-PH04 API | Khóa Valkey `dh:int:testrun:queue` không có TTL; giữ thống nhất khi mô tả hàng đợi chạy thử | Đã hấp thụ (0.2): API §5 và hình kiến trúc dùng đúng khóa này, không nêu TTL nên không mâu thuẫn |

: Đề nghị đồng bộ với tập khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 25/11/2026 | Bản đầu: 26 bảng, RLS, di trú W2, đã chạy thử | Nhóm phân hệ PH-04 |
| 0.2 | 26/11/2026 | Áp K-TRINH-BAY, K-CSDL: chương Giới thiệu, ERD có chú thích và thuyết minh, danh sách bảng, bảng đặc tả 10 mục cho 26 bảng sinh từ DDL (công cụ `gen_tables_md.py` mở rộng), chú thích mọi bảng; chạy lại DDL trên PostgreSQL 16.15, sửa hai lỗi (thiếu `pg_trgm`, chủ sở hữu schema W2), thêm bài kiểm `ph04_isolation_test.sql` 23 khối; giữ nguyên nội dung kỹ thuật bản 0.1 | Nhóm viết tài liệu (Claude) |
| 0.3 | 27/11/2026 | Tách mã API trùng: các operation tách ra nhận mã mới API-04-095 đến API-04-113, dẫn chiếu đã đổi theo ngữ cảnh (xem D03-04-PH04 chương 8) | Nhóm viết tài liệu (Claude) |
