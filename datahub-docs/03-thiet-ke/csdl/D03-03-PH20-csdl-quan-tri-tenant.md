---
ma_tai_lieu: D03-03-PH20
ten: Thiết kế cơ sở dữ liệu phân hệ PH-20 Quản trị tenant và phát hành sản phẩm
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-20
mo_ta: Thiết kế 45 bảng của schema ph20_tenant trên cụm pg-core cho phân hệ quản trị tenant và phát hành sản phẩm, gồm hồ sơ tenant và tổ chức, saga khởi tạo 17 bước, cấu hình có phiên bản, hạn mức và sử dụng phân vùng tháng, phân hệ theo tenant, vòng đời có duyệt bốn mắt, sáp nhập, phát hành và nâng cấp theo sóng, RLS đặc thù bảng tenant và phiên nền tảng, kiểm thử cô lập, ánh xạ thực thể và chức năng sang bảng, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH20 FRS; D03-02-PH20 SDD; D03-04-PH20 API; D03-10 Thiết kế đa tenant; D02-07 Từ điển dữ liệu; D05-02-PH20 Test case
---

# D03-03-PH20 · Thiết kế cơ sở dữ liệu Quản trị tenant và phát hành sản phẩm

## Tóm tắt cho hội đồng thẩm định

Schema `ph20_tenant` trên cụm `pg-core` có 45 bảng cho hai module `tenant` và `release` của `dh-platform` (package `vn.datahub.platform.tenant`, `vn.datahub.platform.release`): 41 bảng nghiệp vụ hiện thực EN-20-01…37 của FRS, cùng bốn bảng kỹ thuật `outbox`, `inbox_event`, `idempotency_key`, `file_object`. Đây là CSDL của mặt phẳng điều khiển (control plane) giữ danh sách tỉnh sử dụng Datahub, khởi tạo một tỉnh mới trong thời gian không quá một ngày làm việc (KPI-12, NFR-00-057), đặt hạn mức và theo dõi sử dụng, bật tắt phân hệ, tạm ngừng, chấm dứt hoặc sáp nhập tỉnh, và phát hành phiên bản sản phẩm theo sóng. Phân hệ này sở hữu hai thực thể dùng chung của toàn nền tảng: DD-01 Tenant (`tenant`) và DD-02 Tổ chức (`organization`).

Năm quyết định thiết kế chi phối toàn bộ lược đồ:

1. **Bảng `tenant` là ngoại lệ có chủ đích của quy tắc `tenant_id`.** Chính nó là tenant nên không có cột `tenant_id`; chính sách RLS cho tenant tỉnh chỉ thấy dòng `code` của mình, phiên `PLATFORM` của vai kết nối riêng `ph20_platform_app` thấy mọi dòng, và chỉ phiên `PLATFORM` được ghi. Tenant không bao giờ bị xóa dòng: trigger chặn `DELETE`, chấm dứt là trạng thái `DECOMMISSIONED`.
2. **Bốn chế độ RLS theo nguồn ghi của dữ liệu.** Bảng tenant tự quản (tổ chức, cài đặt tỉnh, chính sách liên tenant, cửa sổ bảo trì, lô nhập tổ chức) do tỉnh ghi và nền tảng chỉ đọc. Bản ghi điều khiển về tenant (hạn mức, saga, vòng đời, nâng cấp) do nền tảng ghi và tỉnh chỉ đọc. Dữ liệu nền tảng (danh mục phân hệ, mẫu khởi tạo, phiên bản sản phẩm, kế hoạch sáp nhập) mang `tenant_id = 'PLATFORM'`. Bảng kỹ thuật cho cả hai bên ghi cùng giao dịch. Cả ba vai kết nối `ph20_app`, `ph20_platform_app`, `ph20_ro` đều không `BYPASSRLS` và không sở hữu bảng nào.
3. **Ràng buộc nghiệp vụ chốt ngay ở CSDL.** Mã tenant đúng `^T\d{2}$` hoặc `PLATFORM`, `COMMON`; một đơn vị hành chính cấp tỉnh chỉ một tenant đang hoạt động; một tenant chỉ một lần chạy saga đang hoạt động; một tenant nguồn chỉ một kế hoạch sáp nhập đang mở; tổ chức không tự làm cấp trên của mình và không tạo chu trình; `effective_to >= effective_from`; các đề nghị chấm dứt, sáp nhập, đổi hạn mức, ghi đè hạn mức duyệt bốn mắt bằng `CHECK` người duyệt khác người đề nghị.
4. **Saga khởi tạo là dữ liệu, không là mã giấu.** `provisioning_run` và `provisioning_step` ghi từng bước trong 17 bước `S01_RECORD`…`S17_ACTIVATE` với khóa lũy đẳng `{runId}:{stepCode}`, trạng thái bù trừ và hạn chờ báo cáo; kết quả kiểm tra khói chỉ thêm, không sửa (ADR số 200).
5. **Sử dụng tài nguyên phân vùng theo tháng.** `usage_snapshot` nhận ảnh chụp hằng giờ cho 12 loại tài nguyên của mỗi tenant, phân vùng RANGE trên `captured_at` theo giờ Việt Nam, giữ 25 tháng và dọn bằng `DETACH`, `DROP` phân vùng (ADR số 204).

DDL [`ph20/ddl/ph20_tenant.sql`](ph20/ddl/ph20_tenant.sql) đã chạy thử trên PostgreSQL 16.15 sạch; bài kiểm [`ph20/test/ph20_isolation_test.sql`](ph20/test/ph20_isolation_test.sql) đạt 236 khối PASS (mục 6.2, 8); 14 tệp Liquibase chạy được độc lập; DDL cùng bài kiểm chạy chung với 18 phân hệ khác trên một CSDL không lỗi. Mọi liệt kê trong `CHECK` khớp FRS Phụ lục A (23 liệt kê, 0 lệch). Chương 10 ánh xạ thực thể EN-20, chức năng FR-20 sang bảng; chương 11 nêu năm câu hỏi mở Q20-50…54 và các đề nghị đồng bộ.

## 1. Giới thiệu

Chương này nói tài liệu viết cho ai, phạm vi tới đâu, dùng những thuật ngữ nào và đọc theo thứ tự nào. Người cần dựng schema đọc chương 2 và 6, người viết tầng truy cập dữ liệu đọc chương 3 và 4, kiểm thử viên đọc chương 8.

### 1.1. Mục đích

Tài liệu đặc tả cơ sở dữ liệu của PH-20 Quản trị tenant và phát hành sản phẩm ở mức đủ để DBA dựng schema trên `pg-core`, kỹ sư `dh-platform` viết tầng truy cập, kỹ sư ATTT thẩm định cách ly tenant, và kiểm thử viên viết ca cô lập, ca bốn mắt, ca máy trạng thái. DDL là nguồn chuẩn; các khối đặc tả bảng ở chương 3 sinh trực tiếp từ DDL bằng `ph20/tools/dung_md.py` nên khớp tuyệt đối với mã chạy được.

### 1.2. Phạm vi

Trong phạm vi: 45 bảng của schema `ph20_tenant`, hàm và thủ tục hỗ trợ, trigger, chính sách RLS, vai trò, phân vùng, changelog Liquibase và bài kiểm cô lập. Ngoài phạm vi: cấu hình tenant ở kho Git `dh-tenant-config` (trạng thái mong muốn do Argo CD áp, ADR số 201), bí mật và khóa ở OpenBao, nội dung tệp ở Ceph RGW, số liệu nguồn ở Mimir, nhật ký kiểm toán chuỗi băm của PH-13, bảng định tuyến CSDL chuyên dụng khi `DEDICATED_DB` (do mẫu CloudNativePG tạo ở bước `S07_DATABASE`), danh sách người dùng và vai trò (PH-12). PH-20 không có khóa ngoại sang schema khác; tham chiếu tới đơn vị hành chính (PH-07), phân loại dữ liệu (PH-09) là UUID logic do dịch vụ kiểm.

### 1.3. Người đọc

Tài liệu dành cho DBA, kỹ sư backend `dh-platform` (đội B, lane L-CTRL), kỹ sư ATTT soát cách ly và tách nhiệm vụ, kiểm thử viên và hội đồng thẩm định. Người đọc cần biết PostgreSQL ở mức RLS, trigger, phân vùng và đã đọc D03-10 về đa tenant.

### 1.4. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây dùng xuyên suốt tài liệu; thuật ngữ chung của dự án xem D00-01.

| Thuật ngữ | Giải thích |
|---|---|
| Tenant | Một tỉnh hoặc thành phố trực thuộc trung ương dùng Datahub, mã `Tnn`; cộng hai tenant đặc biệt `PLATFORM` (nền tảng) và `COMMON` (dữ liệu dùng chung toàn quốc) |
| Control plane, data plane | Mặt phẳng điều khiển (PH-20 thuộc mặt phẳng này) và mặt phẳng dữ liệu (cổng API, runtime luồng, Kafka) |
| Saga | Chuỗi bước khởi tạo tenant, mỗi bước lũy đẳng và có thao tác bù trừ (D03-10 §5.2, ADR số 200) |
| RLS | Row-Level Security của PostgreSQL; `FORCE` buộc cả chủ bảng chịu chính sách |
| Phiên PLATFORM | Giao dịch có `app.tenant_id = 'PLATFORM'`, dùng bởi nhóm `/api/platform/` và saga |
| Bốn mắt | Người duyệt khác người đề nghị, ép bằng `CHECK` |
| Sóng (wave) | Nhóm tenant nâng cấp cùng lúc trong một kế hoạch nâng cấp (ADR số 203) |
| DU | Đơn vị triển khai (deployment unit), ví dụ `dh-platform` |
| EN-20-nn, FR-20-nnn | Thực thể và chức năng của FRS PH-20 |
| GĐ-01 | Giả định nền: tỉnh T01 quy mô vừa, 200 HTTT |

: Thuật ngữ và chữ viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

Tài liệu bám theo các tài liệu dưới đây; khi có mâu thuẫn, D02-07 và FRS PH-20 là nguồn chuẩn cho tên trường và liệt kê, D03-10 là nguồn chuẩn cho mẫu RLS.

| Tài liệu | Nội dung dùng |
|---|---|
| D03-10 Thiết kế đa tenant | §4 mẫu RLS `tenant_isolation`, §5 máy trạng thái, saga 17 bước `S01`…`S17`, hạn mức, sáp nhập |
| D02-07 Từ điển dữ liệu | DD-01 Tenant, DD-02 Tổ chức, DD-11 Outbox, DD-12 Tệp |
| D02-03-PH20 FRS | EN-20-01…37, FR-20-001…070, Phụ lục A liệt kê, mã lỗi `ERR-20-*` |
| D03-03-PH16 CSDL Báo cáo chỉ tiêu | Mẫu khung DDL, bộ công cụ sinh và kiểm thử |
| D00-01 Quy ước | §5.1 cột ngữ cảnh, UUID v7, tên topic |

: Tài liệu tham chiếu

### 1.6. Cấu trúc tài liệu

Chương 2 trình bày tổng quan schema, vai trò, sơ đồ thực thể và quy tắc nghiệp vụ chốt ở CSDL. Chương 3 đặc tả từng bảng theo khối 10 mục. Chương 4 nêu RLS, đặc thù bảng `tenant` và phiên `PLATFORM`. Chương 5 nêu phân vùng, lưu giữ, sao lưu. Chương 6 nêu DDL, Liquibase và kết quả chạy thử. Chương 7 nêu dữ liệu nền. Chương 8 nêu các ca kiểm thử cô lập. Chương 9 nêu kho ngoài PostgreSQL. Chương 10 ánh xạ thực thể và chức năng sang bảng. Chương 11 gồm câu hỏi mở và đề nghị đồng bộ.

## 2. Tổng quan schema và chiến lược lưu trữ

Schema `ph20_tenant` nằm trên cụm `pg-core` (chế độ `SHARED` của chính nền tảng, không phụ thuộc chế độ cách ly của tenant tỉnh) và do một vai không đăng nhập sở hữu. Chương này nêu vai trò và kết nối, cách nhóm 45 bảng, bốn sơ đồ thực thể, quy ước và các quy tắc nghiệp vụ do CSDL tự bảo đảm.

### 2.1. Schema, vai trò và kết nối

Schema `ph20_tenant` do `ph20_owner` (NOLOGIN, NOBYPASSRLS) sở hữu; mọi bảng, hàm, thủ tục thuộc `ph20_owner`. Ba vai kết nối đều NOLOGIN ở mức DDL (tài khoản đăng nhập là thành viên do CloudNativePG hoặc Vault cấp), không `BYPASSRLS`, không là chủ sở hữu bảng. Liquibase chạy bằng thành viên `ph20_owner`.

| Vai | Dùng bởi | Quyền | Phạm vi RLS |
|---|---|---|---|
| `ph20_owner` | Liquibase, `PartitionMaintenanceJob`, dọn lưu giữ | Chủ schema; DDL, `DETACH` phân vùng | Chịu `FORCE RLS`; có chính sách `platform_write` để nạp dữ liệu nền dưới phiên `PLATFORM` |
| `ph20_app` | Nhóm `/api/tenant/v1` và tác vụ theo tenant của `dh-platform` | DML trên bảng tenant tự quản (OWN) và bảng kỹ thuật (TECH); chỉ `SELECT` trên bảng điều khiển (CTL), dữ liệu nền tảng, `tenant` | Chỉ dòng `tenant_id` của phiên; giả mạo phiên `PLATFORM` cũng không thấy thêm dữ liệu tenant khác |
| `ph20_platform_app` | Nhóm `/api/platform/v1`, `/internal/tenant/v1`, saga, `PartitionMaintenanceJob` đọc | DML mọi bảng (trừ `DELETE` bảng không xóa cứng); thực thi `p_init_tenant_quota` | Khi phiên là `PLATFORM`: đọc bảng tenant tự quản, đọc và ghi bảng điều khiển, bảng nền tảng, bảng `tenant` |
| `ph20_ro` | Kiểm toán nền tảng (ROLE-PLATFORM_AUDITOR), báo cáo, BI | Chỉ `SELECT` mọi bảng | Như `ph20_app`; khi phiên `PLATFORM` đọc liên tenant |

: Vai trò của schema `ph20_tenant`

Ba nhóm kết nối tách biệt là điều kiện để chính sách theo vai có nghĩa: nhóm API tỉnh dùng bể kết nối `ph20_app`, nhóm API nền tảng và saga dùng bể `ph20_platform_app`; mã không thể chọn vai bằng tham số của yêu cầu. Khi khởi động, `dh-platform` từ chối chạy nếu một vai kết nối có `BYPASSRLS` hoặc bảng nào thiếu chính sách (D03-10 §4); bài kiểm 8 có khối tổng kiểm tương ứng.

### 2.2. Nhóm bảng

45 bảng chia thành mười nhóm theo tệp changeset. Bảng dưới liệt kê nhóm, bảng chính và chế độ RLS để người đọc nắm cấu trúc trước khi vào sơ đồ.

| Nhóm | Bảng | Chế độ RLS |
|---|---|---|
| Hồ sơ tenant, tổ chức, tệp | `provisioning_template`, `tenant`, `organization`, `tenant_contact`, `tenant_contract`, `file_object` | PLAT; đặc thù; OWN; CTL; CTL; TECH |
| Phân hệ và tính năng | `platform_module`, `module_dependency`, `tenant_module`, `tenant_feature_flag` | PLATR; PLATR; CTL; CTL |
| Cấu hình tenant | `tenant_platform_config`, `tenant_settings`, `tenant_config_version`, `config_drift`, `cross_tenant_policy` | CTL; OWN; CTL; CTL; OWN |
| Saga khởi tạo | `provisioning_run`, `provisioning_step`, `smoke_test_result` | CTL |
| Hạn mức và sử dụng | `tenant_quota`, `quota_change_request`, `quota_override`, `usage_snapshot`, `quota_alert`, `usage_report` | CTL |
| Vòng đời tenant | `lifecycle_request`, `tenant_status_history`, `data_export_package`, `data_export_item` | CTL |
| Sáp nhập | `merge_plan`, `merge_mapping`, `merge_participant_run`, `merge_conflict` | PLAT (kế hoạch thêm quyền đọc cho hai bên) |
| Nhập tổ chức | `org_import_job`, `org_import_row` | OWN |
| Phát hành và nâng cấp | `product_release`, `release_component`, `tenant_release_subscription`, `maintenance_window`, `upgrade_plan`, `upgrade_wave`, `tenant_upgrade`, `leak_test_run` | PLATR; PLATR; CTL; OWN; PLAT; PLAT; CTL; PLAT |
| Bảng kỹ thuật | `outbox`, `inbox_event`, `idempotency_key` (cùng `file_object` ở nhóm đầu) | TECH |

: Nhóm bảng và chế độ RLS của `ph20_tenant`

### 2.3. Sơ đồ thực thể – quan hệ

Sơ đồ chia bốn nhóm cho vừa trang A4. Khóa ngoại luôn kèm `tenant_id` khi cha và con cùng tenant (khóa ngoại kép nên một tenant không trỏ được tới dòng của tenant khác dù biết UUID); khóa ngoại đơn chỉ dùng cho tham chiếu tới dữ liệu nền tảng (`platform_module`, `provisioning_template`, `product_release`) và tới `tenant(code)`. Đường ghi chú "logic" là tham chiếu không có khóa ngoại.

```{.mermaid caption="ERD nhóm hồ sơ tenant, tổ chức, hợp đồng và cấu hình"}
erDiagram
  provisioning_template ||--o{ tenant : "mẫu khởi tạo"
  tenant ||--o{ tenant : "sáp nhập vào"
  tenant ||--o{ organization : "sở hữu"
  organization ||--o{ organization : "cấp trên, kế thừa"
  tenant ||--o{ tenant_contact : "đầu mối"
  organization ||--o{ tenant_contact : "nơi công tác"
  tenant ||--o{ tenant_contract : "hợp đồng"
  file_object ||--o{ tenant_contract : "tệp hợp đồng"
  tenant ||--|| tenant_platform_config : "cấu hình nền tảng"
  tenant ||--|| tenant_settings : "cài đặt tỉnh"
  organization ||--o{ tenant_settings : "chủ quản CNTT"
  file_object ||--o{ tenant_settings : "logo"
  tenant ||--o{ tenant_config_version : "phiên bản cấu hình"
  tenant ||--o{ config_drift : "lệch cấu hình"
  tenant ||--|| cross_tenant_policy : "chính sách liên tenant"
```

Hình cho thấy `tenant` là gốc của mọi nhóm: tám bảng treo trực tiếp vào tenant bằng `tenant_id`, riêng `tenant` tự tham chiếu qua `merged_into_id` khi sáp nhập. Tổ chức tự tham chiếu hai lần (cấp trên `parent_id`, kế thừa `successor_id`) và là nơi `tenant_contact`, `tenant_settings` trỏ tới. `file_object` là bảng kỹ thuật dùng chung cho hợp đồng, logo, gói bàn giao, báo cáo.

```{.mermaid caption="ERD nhóm saga khởi tạo, hạn mức và sử dụng"}
erDiagram
  provisioning_template ||--o{ provisioning_run : "mẫu dùng"
  tenant ||--o{ provisioning_run : "lần chạy"
  provisioning_run ||--o{ provisioning_step : "17 bước"
  provisioning_run ||--o{ smoke_test_result : "kiểm tra khói"
  tenant ||--o{ tenant_quota : "hạn mức"
  tenant ||--o{ quota_change_request : "đề nghị đổi"
  tenant ||--o{ quota_override : "ghi đè tạm"
  tenant ||--o{ usage_snapshot : "ảnh chụp theo giờ"
  tenant ||--o{ quota_alert : "cảnh báo"
  tenant ||--o{ usage_report : "báo cáo"
  file_object ||--o{ usage_report : "tệp kết quả"
  tenant_quota }o..o{ usage_snapshot : "logic, resource_code"
  quota_change_request }o..o{ tenant_quota : "logic, resource_code"
```

Hình cho thấy hai luồng tách biệt: luồng khởi tạo (mẫu → lần chạy → bước, kiểm tra khói) và luồng hạn mức (hạn mức hợp đồng, đề nghị đổi có duyệt, ghi đè tạm, ảnh chụp sử dụng, cảnh báo). Quan hệ giữa hạn mức và ảnh chụp là logic theo `resource_code` vì ảnh chụp nạp khối lượng lớn vào bảng phân vùng và không là đích khóa ngoại.

```{.mermaid caption="ERD nhóm phân hệ, vòng đời, bàn giao và sáp nhập"}
erDiagram
  platform_module ||--o{ module_dependency : "cần"
  platform_module ||--o{ tenant_module : "bật cho tenant"
  platform_module ||--o{ tenant_feature_flag : "tính năng"
  tenant ||--o{ tenant_module : "phân hệ"
  tenant ||--o{ tenant_feature_flag : "cờ"
  tenant ||--o{ lifecycle_request : "đề nghị vòng đời"
  quota_change_request ||--o| lifecycle_request : "hạ hạn mức"
  tenant ||--o{ tenant_status_history : "lịch sử trạng thái"
  lifecycle_request ||--o{ tenant_status_history : "căn cứ"
  lifecycle_request ||--o{ data_export_package : "bàn giao"
  data_export_package ||--o{ data_export_item : "mục theo phân hệ"
  platform_module ||--o{ data_export_item : "phân hệ"
  merge_plan ||--o{ merge_mapping : "ánh xạ"
  merge_plan ||--o{ merge_participant_run : "chuyển theo phân hệ"
  merge_plan ||--o{ merge_conflict : "xung đột"
  merge_participant_run ||--o{ merge_conflict : "phát hiện"
  tenant ||--o{ merge_plan : "nguồn, đích"
```

Hình cho thấy vòng đời tenant chạy qua `lifecycle_request` và để lại dấu vết ở `tenant_status_history`; gói bàn giao dữ liệu chia theo phân hệ nhờ khóa ngoại tới `platform_module`. Kế hoạch sáp nhập mang hai mã tenant (nguồn, đích) bằng khóa ngoại tới `tenant(code)`, các bảng con ánh xạ, lần chuyển, xung đột treo vào kế hoạch.

```{.mermaid caption="ERD nhóm phát hành, nâng cấp, bảo trì, nhập tổ chức và rò rỉ"}
erDiagram
  product_release ||--o{ release_component : "thành phần"
  product_release ||--o{ upgrade_plan : "bản đích"
  upgrade_plan ||--o{ upgrade_wave : "sóng"
  upgrade_wave ||--o{ tenant_upgrade : "tenant trong sóng"
  tenant ||--o{ tenant_upgrade : "nâng cấp"
  maintenance_window ||--o{ tenant_upgrade : "cửa sổ"
  tenant ||--o{ maintenance_window : "bảo trì"
  tenant ||--|| tenant_release_subscription : "kênh phát hành"
  product_release ||--o{ tenant_release_subscription : "ghim, đang chạy"
  tenant ||--o{ org_import_job : "lô nhập"
  org_import_job ||--o{ org_import_row : "dòng"
  file_object ||--o{ org_import_job : "tệp nhập"
  file_object ||--o{ leak_test_run : "báo cáo"
```

Hình cho thấy chuỗi phát hành: bản sản phẩm → kế hoạch → sóng → nâng cấp từng tenant, nâng cấp tôn trọng cửa sổ bảo trì của tỉnh. `leak_test_run` đứng riêng vì là dữ liệu nền tảng, không thuộc tenant nào. Ba bảng kỹ thuật `outbox`, `inbox_event`, `idempotency_key` không có quan hệ khóa ngoại nên không vẽ.

### 2.4. Quy ước bảng và ngoại lệ

Theo D00-01 §5.1 mọi bảng thực thể có `id uuid` (UUID v7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version`; `tg_touch` cập nhật `updated_at` và tăng `version` (khóa lạc quan, thành phần của ETag). Liệt kê lưu `varchar` kèm `CHECK ... IN (...)`; thời gian dùng `timestamptz`; chuỗi chuẩn NFC. Không cột nào lưu bí mật, khóa hay chuỗi kết nối: chỉ tham chiếu (`db_route_ref`, `cluster_ref`, `image_ref`) và mã băm.

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `tenant` | Không có `tenant_id`; khóa nghiệp vụ `code`; RLS riêng | Chính nó là tenant (D02-07 DD-01) |
| `usage_snapshot` | Khóa chính `(id, captured_at)`; không có `UNIQUE (id, tenant_id)`; không là đích khóa ngoại | Phân vùng tháng nên khóa chính chứa cột phân vùng |
| `outbox`, `inbox_event`, `idempotency_key` | Không có `id`, `version`, `created_*`, `updated_*` | Bảng kỹ thuật; khóa chính là `event_id`, `(tenant_id, consumer, event_id)`, hoặc năm cột yêu cầu |
| `tenant_status_history`, `smoke_test_result` | Trigger chặn `UPDATE`, `DELETE` | Chỉ thêm, là bằng chứng |
| Bảng dữ liệu nền tảng (`platform_module`, `module_dependency`, `provisioning_template`, `product_release`, `release_component`, `merge_*`, `upgrade_plan`, `upgrade_wave`, `leak_test_run`) | `tenant_id` luôn `PLATFORM` (CHECK) | Dữ liệu của nền tảng, không của tỉnh nào |
| `usage_report`, `outbox`, `inbox_event`, `idempotency_key`, `file_object` | `tenant_id` nhận thêm `PLATFORM` | Báo cáo, sự kiện, tệp toàn nền tảng |

: Quy ước bảng và ngoại lệ của `ph20_tenant`

Cột có tên dễ bị công cụ quét bí mật báo nhầm đã đổi tên: khóa tham số dùng `flag_code`, `resource_code`, `module_code`; khóa lũy đẳng dùng `idempotency_ref`; tên đối tượng ở kho đối tượng dùng `object_path` (DD-12 gọi `object_key`, đề nghị đồng bộ 11.2). Không có tệp SQL nào so sánh cột với chuỗi dạng khóa.

### 2.5. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm bằng ràng buộc, chỉ mục duy nhất một phần, trigger hoặc quyền, nên một lỗi ở dịch vụ không phá được tính toàn vẹn. Tổng số ràng buộc ghi ở cuối mục.

| Ràng buộc | Quy tắc | FR |
|---|---|---|
| `ck_tenant_code`, `ck_tenant_kind_code` | Mã tenant `^T\d{2}$` hoặc `PLATFORM`, `COMMON`; loại và mã đi đôi (`PROVINCE` với `Tnn`) | 001, 006 |
| `uq_tenant_admin_unit_active` | Một đơn vị hành chính cấp tỉnh chỉ một tenant đang hoạt động (`PROVISIONING`, `ACTIVE`, `SUSPENDED`, `MERGING`, `FAILED`); chỉ mục duy nhất một phần | 001, 007 |
| `ck_tenant_special`, `tg_tenant_no_delete` | `PLATFORM`, `COMMON` luôn `ACTIVE`, `SHARED`; không xóa dòng tenant nào | 006 |
| `tg_tenant_transition` | Chuyển trạng thái đúng D03-10 §5.1 (mục 2.6) | 038…042 |
| `ck_tenant_realm`, `ck_tenant_province` | Tenant tỉnh có ĐVHC và realm `dh-{mã thường}` | 001, 019 |
| `uq_provisioning_run_active` | Một tenant chỉ một lần chạy saga đang hoạt động (`PENDING`, `RUNNING`, `WAITING`, `COMPENSATING`) | 008, 010 |
| `ck_provisioning_step_code`, `ck_provisioning_step_idem` | 17 mã bước; khóa lũy đẳng `{runId}:{stepCode}` | 008, 009 |
| `tg_smoke_test_result_append_only` | Kết quả kiểm tra khói chỉ thêm | 012 |
| `uq_merge_plan_open_source`, `ck_merge_plan_four_eyes` | Một tenant nguồn chỉ một kế hoạch sáp nhập đang mở; người duyệt khác người lập | 045 |
| `ck_lifecycle_request_four_eyes`, `ck_lifecycle_request_approved` | Chấm dứt, đổi cách ly, hạ hạn mức phải có người duyệt khác người đề nghị | 038…042 |
| `ck_quota_change_request_four_eyes`, `ck_quota_override_four_eyes` | Đổi hạn mức, ghi đè hạn mức: người duyệt khác người đề nghị | 027, 032 |
| `uq_lifecycle_request_open`, `uq_quota_change_request_open` | Mỗi (tenant, loại) một đề nghị vòng đời đang mở; mỗi (tenant, tài nguyên) một đề nghị đổi hạn mức đang mở | 027, 038 |
| `ck_organization_no_self_parent`, `tg_organization_cycle` | Tổ chức không tự làm cấp trên; không chu trình cấp trên | 053, 054 |
| `ck_organization_effective`, `ck_organization_closed`, `ck_organization_merged` | `effective_to >= effective_from`; giải thể có ngày kết thúc; sáp nhập có tổ chức kế thừa | 054 |
| `uq_tenant_quota_resource`, `ck_tenant_quota_resource_code` | Mỗi (tenant, tài nguyên) một hạn mức; đúng 12 loại tài nguyên | 026 |
| `uq_usage_snapshot_point` | Một ảnh chụp cho mỗi (tenant, tài nguyên, thời điểm); nạp lại không nhân bản | 028 |
| `uq_quota_alert_open` | Mỗi (tenant, tài nguyên, mức) một cảnh báo đang mở | 029 |
| `uq_tenant_module_module`, khóa ngoại `module` | Mỗi (tenant, phân hệ) một dòng; phân hệ phải có trong danh mục | 034, 035 |
| `uq_provisioning_template_published`, `tg_provisioning_template_frozen` | Mỗi mã mẫu một bản `PUBLISHED`; bản `PUBLISHED` bất biến | 015 |
| `tg_product_release_transition`, `ck_product_release_stable` | `DRAFT → PREVIEW → STABLE`; `STABLE` có `stable_at` không trước `preview_at` | 059, 060 |
| `ck_outbox_topic` | Chỉ 16 topic của EVT-20 (kể cả kiểm toán) hoặc `{tenant}.tenant.org.changed.v1` đúng tiền tố tenant | 068 |
| `uq_tenant_config_version_version`, `tg_tenant_config_version_immutable` | Số phiên bản cấu hình duy nhất; ảnh chụp bất biến | 020, 021 |

: Quy tắc nghiệp vụ chốt ở CSDL

Số liệu tổng hợp từ DDL (sinh tự động):

<!-- gen:thong-ke:start -->
45 bảng gốc, 265 `CHECK`, 68 `UNIQUE`, 73 khóa ngoại, 11 chỉ mục duy nhất (11 một phần), 62 chỉ mục thường, 65 trigger
<!-- gen:thong-ke:end -->

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (kiểm sức chứa NFR-00-060, tài nguyên cụm, thời gian ghi đè tối đa `20.quota.override-max-days`, trần liên tenant `20.cross-tenant.max-hours`, thời gian chạy thử bản `STABLE`, đối chiếu tổ chức chủ quản ở PH-01) kiểm ở dịch vụ, ghi ở D03-02-PH20.

### 2.6. Máy trạng thái ở CSDL

Trạng thái của tenant, lần chạy saga, đề nghị có duyệt, kế hoạch sáp nhập và phiên bản sản phẩm do trigger `tg_transition` bảo vệ: chỉ cho chuyển theo bản đồ khai báo ở tham số trigger. Sơ đồ dưới là máy trạng thái của tenant đúng DDL; hai chuyển trạng thái đánh dấu (bổ sung) không có ở D03-10 §5.1 và ghi vào Q20-51.

```{.mermaid caption="Máy trạng thái tenant do tg_tenant_transition bảo vệ"}
stateDiagram-v2
  [*] --> PROVISIONING: Khai báo
  PROVISIONING --> ACTIVE: Saga thành công
  PROVISIONING --> FAILED: Saga lỗi
  FAILED --> PROVISIONING: Thử lại từ bước lỗi
  FAILED --> DECOMMISSIONED: Hủy khởi tạo (bổ sung)
  ACTIVE --> SUSPENDED: Tạm ngừng có lý do
  SUSPENDED --> ACTIVE: Khôi phục
  ACTIVE --> MERGING: Bắt đầu sáp nhập
  MERGING --> MERGED: Cắt chuyển
  MERGING --> ACTIVE: Hủy sáp nhập (bổ sung)
  SUSPENDED --> DECOMMISSIONED: Chấm dứt có duyệt bốn mắt
  MERGED --> DECOMMISSIONED: Hết thời gian chuyển tiếp
  DECOMMISSIONED --> [*]
```

Hình cho thấy tenant đang `ACTIVE` không thể chấm dứt trực tiếp: phải qua `SUSPENDED` (bài kiểm 1 chặn `ACTIVE → DECOMMISSIONED` và `ACTIVE → MERGED`). Ràng buộc `ck_tenant_active` buộc `activated_at` khi sang `ACTIVE`, nên thời gian khởi tạo (KPI-12) tính được từ `declared_at` đến `activated_at` mà không cần bảng khác. Các bảng còn lại dùng cùng cơ chế: `provisioning_run` (`PENDING` → `RUNNING` → `WAITING` hoặc `FAILED` hoặc `COMPENSATING` → `SUCCEEDED` hoặc `COMPENSATED`, `FAILED` thử lại được), `lifecycle_request` và `quota_change_request` (`DRAFT` → `PENDING_APPROVAL` → `APPROVED` → `EXECUTING` → `DONE`), `merge_plan` (12 trạng thái, `FAILED` thử lại được), `product_release` (`DRAFT` → `PREVIEW` → `STABLE` → `DEPRECATED`, rút bản `WITHDRAWN` từ mọi trạng thái).

Luồng ghi tiêu biểu là đổi hạn mức có duyệt bốn mắt: một quản trị nền tảng đề nghị, quản trị nền tảng khác duyệt, hệ thống áp dụng và phát sự kiện qua outbox cùng giao dịch.

```{.mermaid caption="Trình tự đổi hạn mức có duyệt bốn mắt và đẩy xuống nơi thực thi"}
sequenceDiagram
  actor PA1 as Quản trị nền tảng A
  actor PA2 as Quản trị nền tảng B
  participant API as API nền tảng
  participant PG as ph20_tenant (PostgreSQL)
  participant DBZ as Debezium
  participant GW as Nơi thực thi (APISIX, Kafka)
  PA1->>API: Đề nghị nâng API_RPS của T90 từ 500 lên 800, kèm lý do và mã phiếu
  API->>PG: INSERT quota_change_request (DRAFT rồi PENDING_APPROVAL), phiên PLATFORM
  PA2->>API: Duyệt đề nghị
  API->>PG: UPDATE status APPROVED, approved_by khác requested_by (CHECK)
  API->>PG: UPDATE tenant_quota, INSERT outbox EVT-20-05 cùng giao dịch
  PG-->>DBZ: WAL của bảng outbox
  DBZ->>GW: platform.tenant.quota-changed.v1
  GW-->>API: Áp xong, đặt push_status PUSHED
```

Hình cho thấy ba điểm CSDL tham gia: `CHECK` bốn mắt chặn người duyệt trùng người đề nghị, máy trạng thái chặn nhảy bước, và outbox ghi cùng giao dịch với `tenant_quota` nên sự kiện không mất khi dịch vụ lỗi giữa chừng.

### 2.7. Ước lượng khối lượng (giả định)

Giả định GĐ-01: nền tảng phục vụ tối thiểu 34 tenant (NFR-00-060), mỗi tenant quy mô vừa với 200 HTTT, khoảng 500 tổ chức, 12 loại hạn mức và ảnh chụp mỗi giờ.

| Bảng | Dòng ước tính | Dung lượng |
|---|---|---|
| `usage_snapshot` (25 tháng) | 34 tenant × 12 tài nguyên × 730 giờ × 25 tháng, khoảng 7,4 triệu | khoảng 2,5 GB gồm chỉ mục |
| `organization` | khoảng 17 nghìn (34 × 500) | dưới 50 MB |
| `tenant_config_version` | khoảng 20 phiên bản mỗi tenant mỗi năm, ảnh chụp tối đa 50 KB | dưới 100 MB sau 10 năm |
| `provisioning_run`, `provisioning_step`, `smoke_test_result` | vài chục lần chạy, 17 bước mỗi lần | dưới 5 MB |
| `quota_alert`, `tenant_upgrade`, `tenant_status_history` | dưới 50 nghìn | dưới 50 MB |
| `outbox`, `inbox_event`, `idempotency_key` | dưới 20 nghìn đồng thời (dọn 3 ngày, 14 ngày, 24 giờ) | dưới 100 MB |
| Các bảng còn lại | dưới 10 nghìn dòng mỗi bảng | không đáng kể |

: Ước lượng khối lượng (giả định)

Tổng không quá 4 GB sau 25 tháng, nên không cần cụm riêng: `pg-core` chịu được. Khối lượng ghi chủ yếu là `usage_snapshot` (khoảng 300 nghìn dòng mỗi tháng); không cần tối ưu đặc biệt ngoài phân vùng tháng và chỉ mục `(tenant_id, captured_at DESC)`.

### 2.8. Danh mục bảng

Bảng dưới liệt kê 45 bảng theo thứ tự đặc tả ở chương 3, kèm nhóm, thực thể, chế độ RLS, phân vùng và FR chính; sinh từ DDL nên khớp tuyệt đối.

<!-- gen:danh-muc:start -->
| Mục | Bảng | Nhóm | Thực thể | Chế độ RLS | Phân vùng | FR chính |
|---|---|---|---|---|---|---|
| 3.1 | `file_object` | Hồ sơ tenant, tổ chức, tệp | DD-12 | TECH | không | dùng chung |
| 3.2 | `provisioning_template` | Hồ sơ tenant, tổ chức, tệp | EN-20-09 | PLAT | không | FR-20-007, FR-20-015 |
| 3.3 | `tenant` | Hồ sơ tenant, tổ chức, tệp | EN-20-01 | TENANT | không | FR-20-001…003 |
| 3.4 | `organization` | Hồ sơ tenant, tổ chức, tệp | EN-20-02 | OWN | không | FR-20-053…055 |
| 3.5 | `tenant_contact` | Hồ sơ tenant, tổ chức, tệp | EN-20-03 | CTL | không | FR-20-005 |
| 3.6 | `tenant_contract` | Hồ sơ tenant, tổ chức, tệp | EN-20-04 | CTL | không | FR-20-005 |
| 3.7 | `platform_module` | Phân hệ và tính năng | EN-20-18 | PLATR | không | FR-20-033, FR-20-037 |
| 3.8 | `module_dependency` | Phân hệ và tính năng | EN-20-19 | PLATR | không | FR-20-033 |
| 3.9 | `tenant_module` | Phân hệ và tính năng | EN-20-20 | CTL | không | FR-20-016, FR-20-034, 035 |
| 3.10 | `tenant_feature_flag` | Phân hệ và tính năng | EN-20-21 | CTL | không | FR-20-036 |
| 3.11 | `tenant_platform_config` | Cấu hình tenant | EN-20-05 | CTL | không | FR-20-017, FR-20-019, 020 |
| 3.12 | `tenant_settings` | Cấu hình tenant | EN-20-06 | OWN | không | FR-20-018, FR-20-069 |
| 3.13 | `tenant_config_version` | Cấu hình tenant | EN-20-07 | CTL | không | FR-20-019…021 |
| 3.14 | `config_drift` | Cấu hình tenant | EN-20-08 | CTL | không | FR-20-022 |
| 3.15 | `cross_tenant_policy` | Cấu hình tenant | EN-20-29 | OWN | không | FR-20-023, 024 |
| 3.16 | `provisioning_run` | Saga khởi tạo | EN-20-10 | CTL | không | FR-20-008…010 |
| 3.17 | `provisioning_step` | Saga khởi tạo | EN-20-11 | CTL | không | FR-20-008…010 |
| 3.18 | `smoke_test_result` | Saga khởi tạo | EN-20-12 | CTL | không | FR-20-012 |
| 3.19 | `tenant_quota` | Hạn mức và sử dụng | EN-20-13 | CTL | không | FR-20-007, FR-20-026, 027 |
| 3.20 | `quota_change_request` | Hạn mức và sử dụng | EN-20-14 | CTL | không | FR-20-026, 027 |
| 3.21 | `quota_override` | Hạn mức và sử dụng | EN-20-15 | CTL | không | FR-20-032 |
| 3.22 | `usage_snapshot` | Hạn mức và sử dụng | EN-20-16 | CTL | tháng (`captured_at`) | FR-20-028, FR-20-030, FR-20-067 |
| 3.23 | `quota_alert` | Hạn mức và sử dụng | EN-20-17 | CTL | không | FR-20-029, FR-20-067 |
| 3.24 | `usage_report` | Hạn mức và sử dụng | EN-20-37 | CTL | không | FR-20-031 |
| 3.25 | `lifecycle_request` | Vòng đời tenant | EN-20-22 | CTL | không | FR-20-025, FR-20-038, 039 |
| 3.26 | `tenant_status_history` | Vòng đời tenant | EN-20-23 | CTL | không | FR-20-013, FR-20-043, 044 |
| 3.27 | `data_export_package` | Vòng đời tenant | EN-20-24 | CTL | không | FR-20-041 |
| 3.28 | `data_export_item` | Vòng đời tenant | EN-20-24 | CTL | không | FR-20-041 |
| 3.29 | `merge_plan` | Sáp nhập | EN-20-25 | PLAT | không | FR-20-045, FR-20-051, 052 |
| 3.30 | `merge_mapping` | Sáp nhập | EN-20-26 | PLAT | không | FR-20-046, FR-20-050 |
| 3.31 | `merge_participant_run` | Sáp nhập | EN-20-27 | PLAT | không | FR-20-047, 048, FR-20-050 |
| 3.32 | `merge_conflict` | Sáp nhập | EN-20-28 | PLAT | không | FR-20-049 |
| 3.33 | `org_import_job` | Nhập tổ chức | EN-20-30 | OWN | không | FR-20-055 |
| 3.34 | `org_import_row` | Nhập tổ chức | EN-20-30 | OWN | không | FR-20-055 |
| 3.35 | `product_release` | Phát hành và nâng cấp | EN-20-31 | PLATR | không | FR-20-059, 060, FR-20-063 |
| 3.36 | `release_component` | Phát hành và nâng cấp | EN-20-31 | PLATR | không | FR-20-059 |
| 3.37 | `tenant_release_subscription` | Phát hành và nâng cấp | EN-20-32 | CTL | không | FR-20-060 |
| 3.38 | `maintenance_window` | Phát hành và nâng cấp | EN-20-33 | OWN | không | FR-20-061, FR-20-063, 064 |
| 3.39 | `upgrade_plan` | Phát hành và nâng cấp | EN-20-34 | PLAT | không | FR-20-061, 062 |
| 3.40 | `upgrade_wave` | Phát hành và nâng cấp | EN-20-34 | PLAT | không | FR-20-061, 062 |
| 3.41 | `tenant_upgrade` | Phát hành và nâng cấp | EN-20-35 | CTL | không | FR-20-062, FR-20-064 |
| 3.42 | `leak_test_run` | Phát hành và nâng cấp | EN-20-36 | PLAT | không | FR-20-067, FR-20-070 |
| 3.43 | `outbox` | Bảng kỹ thuật | DD-11 | TECH | không | FR-20-013, FR-20-020, FR-20-044 |
| 3.44 | `inbox_event` | Bảng kỹ thuật | kỹ thuật | TECH | không | FR-20-056 |
| 3.45 | `idempotency_key` | Bảng kỹ thuật | kỹ thuật | TECH | không | FR-20-008 |

: Danh mục 45 bảng của schema `ph20_tenant`
<!-- gen:danh-muc:end -->

## 3. Đặc tả bảng

Phần dưới sinh bằng `ph20/tools/dung_md.py` từ DDL; sửa ở DDL rồi sinh lại, không sửa tay. Mỗi bảng có khối đặc tả 10 mục trích từ DDL (mục đích, FR phục vụ, khóa, ràng buộc, chỉ mục, cách ly tenant, phân vùng và bất biến, lưu giữ), bảng cột nổi bật (có liệt kê, khóa ngoại hoặc ràng buộc riêng) và một dòng liệt kê cột còn lại. Bảy cột ngữ cảnh `id`, `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` có ở mọi bảng nghiệp vụ nên không nhắc lại.

<!-- gen:tables:start -->
### 3.1. `file_object`

::: dac-ta
**Mục đích.** Hạ tầng, DD-12 Siêu dữ liệu tệp: hợp đồng, gói bàn giao, tệp nhập tổ chức, báo cáo sử dụng, báo cáo kiểm thử rò rỉ, logo tỉnh. Nội dung nằm ở kho đối tượng Ceph RGW, bucket `dh-{tenant}-{mục đích}`; chỉ tệp quét sạch (`CLEAN`) mới được xử lý.

**FR phục vụ.** Hạ tầng dùng chung cho nhiều FR (xem mô tả bảng).

**Khóa chính.** (id).

**Duy nhất.** `uq_file_object_location` (bucket, object_path).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_file_object_` + `tenant`, `size`, `sha256`, `scan_status`, `purpose`, `bucket`.

**Chỉ mục.** `ix_file_object_expiry`.

**Cách ly tenant.** Mẫu TECH: `tenant_isolation` (FOR ALL) cho tenant ghi cùng giao dịch; `platform_write` cho PLATFORM; `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Theo `expires_at`; tệp ở kho đối tượng xóa sau hạn, dòng đánh dấu `deleted_at`. Không lưu nội dung; `sha256` toàn vẹn, `scan_status` bắt buộc `CLEAN` mới xử lý.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `bucket` | `varchar(63)` | Bucket kho đối tượng, dạng `dh-{tenant}-{mục đích}` (D03-10 §4). |
| `object_path` | `varchar(1024)` | Đường dẫn đối tượng trong bucket (DD-12 `object_key`). |
| `size_bytes` | `bigint` | Kích thước tệp, byte. |
| `scan_status` | `varchar(10)`, mặc định `'PENDING'` | Kết quả quét mã độc: `PENDING`, `CLEAN`, `INFECTED`; chỉ `CLEAN` mới được xử lý. |
| `purpose` | `varchar(24)`, mặc định `'OTHER'` | Mục đích: `CONTRACT`, `EXPORT_PACKAGE`, `ORG_IMPORT`, `USAGE_REPORT`, `LEAK_REPORT`, `LOGO`, `OTHER`. |

: Cột nổi bật của bảng `file_object`

Cột khác: `file_name` v(255); `content_type` v(127); `sha256` char(64); `data_class_id` uuid; `expires_at` ts; `deleted_at` ts.

### 3.2. `provisioning_template`

::: dac-ta
**Mục đích.** EN-20-09 Mẫu khởi tạo có phiên bản (FR-20-015): hạn mức mặc định, phân hệ bật mặc định, kế hoạch bước saga, cài đặt tỉnh mặc định, tổ chức cấp tỉnh nạp ở bước S13. Dữ liệu nền tảng (`tenant_id = PLATFORM`), chỉ PLATFORM đọc, ghi. Mẫu PUBLISHED bất biến, đổi bằng phiên bản mới.

**FR phục vụ.** FR-20-007, FR-20-015.

**Khóa chính.** (id).

**Duy nhất.** `uq_provisioning_template_code_version` (template_code, version_no), `uq_provisioning_template_published` (template_code) khi status = 'PUBLISHED'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_provisioning_template_` + `tenant`, `code`, `version`, `status`, `isolation`, `profile`, `json`, `published`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Bất biến cột `template_code`, `version_no` (`tg_provisioning_template_immutable`); Bản đã chốt (`PUBLISHED`, `RETIRED`) không đổi nội dung (`tg_provisioning_template_frozen`).

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `template_code` | `varchar(63)` | Mã mẫu, chữ thường và gạch nối (`^[a-z][a-z0-9-]{2,62}$`), ví dụ `tinh-chuan`. |
| `version_no` | `integer`, mặc định `1` | Số phiên bản của mẫu, bắt đầu từ 1. |
| `status` | `varchar(16)`, mặc định `'DRAFT'` | Trạng thái mẫu: `DRAFT`, `PUBLISHED`, `RETIRED` (mỗi mã một bản PUBLISHED). |
| `default_isolation_mode` | `varchar(24)`, mặc định `'SHARED'` | Chế độ cách ly mặc định: `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER`. |
| `deployment_profile` | `varchar(4)`, mặc định `'HT-A'` | Hồ sơ triển khai: `HT-A` hoặc `HT-B`. |

: Cột nổi bật của bảng `provisioning_template`

Cột khác: `name` v(255); `description` text; `default_quota` jsonb; `default_modules` text[]; `step_plan` jsonb; `default_settings` jsonb; `org_seed` jsonb; `activated_at` ts; `retired_at` ts.

### 3.3. `tenant`

::: dac-ta
**Mục đích.** EN-20-01 Tenant (DD-01): một tỉnh hoặc thành phố trực thuộc trung ương, cộng hai tenant đặc biệt `PLATFORM` và `COMMON`. Không có cột `tenant_id` vì chính bảng là tenant. RLS đặc thù: phiên PLATFORM thấy mọi dòng, tenant khác chỉ thấy dòng `code` của mình, chỉ PLATFORM ghi. Không xóa dòng; chấm dứt bằng `DECOMMISSIONED`.

**FR phục vụ.** FR-20-001…007, FR-20-013, FR-20-038…043, FR-20-065…067.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_code` (code), `uq_tenant_admin_unit_active` (admin_unit_id) khi kind = 'PROVINCE' AND status IN ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'MERGING', 'FAILED').

**Khóa ngoại.** (merged_into_id) → `tenant`, (template_id) → `provisioning_template`.

**Ràng buộc CHECK.** `ck_tenant_` + `code`, `kind`, `status`, `isolation_mode`, `kind_code`, `province`, `realm`, `special`, `merged`, `self_merge`, `active`, `profile`, `scale`.

**Chỉ mục.** `ix_tenant_status`, `ix_tenant_merged_into`.

**Cách ly tenant.** Đặc thù (mục 4.3): không có `tenant_id`; `tenant_isolation` cho thấy dòng `code` của phiên; PLATFORM (vai `ph20_platform_app`, `ph20_ro`) thấy mọi dòng; chỉ PLATFORM ghi.

**Phân vùng, bất biến.** Bất biến cột `code`, `kind` (`tg_tenant_immutable`); Máy trạng thái `status` (`tg_tenant_transition`); Chặn xóa dòng (`tg_tenant_no_delete`).

**Lưu giữ, ghi chú.** Giữ vĩnh viễn, kể cả `DECOMMISSIONED` (hồ sơ pháp lý); không xóa cứng.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `code` | `varchar(16)` | Mã tenant `Tnn`, `PLATFORM` hoặc `COMMON`; khóa nghiệp vụ, bất biến. |
| `kind` | `varchar(16)`, mặc định `'PROVINCE'` | Loại tenant: `PROVINCE`, `PLATFORM`, `COMMON`; bất biến. |
| `name` | `varchar(255)` | Tên tỉnh, ví dụ `Tỉnh Lâm Đồng`. |
| `admin_unit_id` | `uuid`, null | Đơn vị hành chính cấp tỉnh (DD-07 ở PH-07, tham chiếu logic); bắt buộc với tenant tỉnh. |
| `status` | `varchar(16)`, mặc định `'PROVISIONING'` | Trạng thái tenant (D03-10 §5.1): `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `MERGING`, `MERGED`, `DECOMMISSIONED`, `FAILED`. |

: Cột nổi bật của bảng `tenant`

Cột khác: `short_name` v(64); `isolation_mode` v(24); `merged_into_id` uuid; `realm` v(64); `scale_profile` v(16); `deployment_profile` v(4); `template_id` uuid; `config_path` v(128); `declared_at` ts; `activated_at` ts; `suspended_at` ts; `merged_at` ts; `decommissioned_at` ts; `status_reason` v(500); `status_changed_at` ts.

### 3.4. `organization`

::: dac-ta
**Mục đích.** EN-20-02 Tổ chức (DD-02): cơ quan, đơn vị trong tỉnh, là chủ quản HTTT, nơi công tác của người dùng, chủ quản dữ liệu. Cây cấp trên không chu trình, hiệu lực theo ngày, giải thể hoặc sáp nhập có tổ chức kế thừa.

**FR phục vụ.** FR-20-053…058.

**Khóa chính.** (id).

**Duy nhất.** `uq_organization_code` (tenant_id, code).

**Khóa ngoại.** (tenant_id) → `tenant`, (parent_id, tenant_id) → `organization`, (successor_id, tenant_id) → `organization`.

**Ràng buộc CHECK.** `ck_organization_` + `tenant`, `org_type`, `status`, `code`, `no_self_parent`, `no_self_successor`, `effective`, `closed`, `merged`.

**Chỉ mục.** `ix_organization_type`, `ix_organization_owner`, `ix_organization_status`, `ix_organization_fk_parent`, `ix_organization_fk_successor`.

**Cách ly tenant.** Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.

**Phân vùng, bất biến.** Bất biến cột `code` (`tg_organization_immutable`); Chặn chu trình cấp trên (`tg_organization_cycle`).

**Lưu giữ, ghi chú.** Giữ trọn đời tenant; giải thể bằng trạng thái, không xóa cứng; lịch sử hiệu lực phục vụ truy vết sáp nhập bộ máy. Không có dữ liệu cá nhân; mã định danh điện tử cơ quan là dữ liệu công khai (NB).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `code` | `varchar(64)` | Mã tổ chức, duy nhất trong tenant, ưu tiên mã định danh điện tử của cơ quan; bất biến. |
| `parent_id` | `uuid`, null | Cơ quan cấp trên cùng tenant, không tạo chu trình, không tự trỏ vào mình. |
| `org_type` | `varchar(16)` | Loại: `PROVINCE_PC`, `DEPARTMENT`, `COMMUNE_PC`, `PUBLIC_UNIT`, `OTHER`. |
| `status` | `varchar(16)`, mặc định `'ACTIVE'` | Trạng thái: `ACTIVE`, `INACTIVE`, `DISSOLVED`, `MERGED`. |
| `effective_to` | `date`, null | Ngày hết hiệu lực, không nhỏ hơn `effective_from`. |

: Cột nổi bật của bảng `organization`

Cột khác: `name` v(255); `short_name` v(64); `admin_unit_id` uuid; `is_data_owner` bool; `effective_from` date; `successor_id` uuid; `external_code` v(64); `sort_order` int; `note` v(500).

### 3.5. `tenant_contact`

::: dac-ta
**Mục đích.** EN-20-03 Đầu mối của tenant (FR-20-005): lãnh đạo, quản trị tenant, kỹ thuật, an ninh; nhận thông báo đổi trạng thái, bảo trì, ngưỡng hạn mức. Có dữ liệu cá nhân (họ tên, thư điện tử, điện thoại), phân loại HC theo DD-09.

**FR phục vụ.** FR-20-005.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_contact_primary` (tenant_id, contact_type) khi is_primary AND status = 'ACTIVE'.

**Khóa ngoại.** (tenant_id) → `tenant`, (organization_id, tenant_id) → `organization`.

**Ràng buộc CHECK.** `ck_tenant_contact_` + `tenant`, `contact_type`, `status`, `email`, `phone`.

**Chỉ mục.** `ix_tenant_contact_tenant_type`, `ix_tenant_contact_fk_organization`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ theo hợp đồng cộng 5 năm; dữ liệu cá nhân che khi xuất báo cáo. Có dữ liệu cá nhân (họ tên, thư điện tử, điện thoại), phân loại HC theo DD-09; không đưa vào log, che khi xuất.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `contact_type` | `varchar(12)` | Vai đầu mối: `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY`. |
| `email` | `varchar(254)` | Thư điện tử nhận thông báo (dữ liệu cá nhân). |
| `phone` | `varchar(20)`, null | Điện thoại (dữ liệu cá nhân). |
| `organization_id` | `uuid`, null | Tổ chức công tác của đầu mối. |
| `status` | `varchar(10)`, mặc định `'ACTIVE'` | Trạng thái: `ACTIVE` hoặc `INACTIVE`. |

: Cột nổi bật của bảng `tenant_contact`

Cột khác: `full_name` v(255); `job_title` v(255); `is_primary` bool; `note` v(500).

### 3.6. `tenant_contract`

::: dac-ta
**Mục đích.** EN-20-04 Hợp đồng dịch vụ của tenant (FR-20-005): số hợp đồng, hiệu lực, mức dịch vụ, tệp hợp đồng. Hợp đồng hết hạn là một lý do tạm ngừng (`CONTRACT_EXPIRED`).

**FR phục vụ.** FR-20-005.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_contract_no` (tenant_id, contract_no).

**Khóa ngoại.** (tenant_id) → `tenant`, (file_id, tenant_id) → `file_object`.

**Ràng buộc CHECK.** `ck_tenant_contract_` + `tenant`, `status`, `service_level`, `valid`, `active`.

**Chỉ mục.** `ix_tenant_contract_fk_file`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ theo hợp đồng cộng 10 năm (quy định lưu trữ hồ sơ); không xóa cứng.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `service_level` | `varchar(10)`, mặc định `'STANDARD'` | Mức dịch vụ: `STANDARD` hoặc `PREMIUM`. |
| `status` | `varchar(12)`, mặc định `'DRAFT'` | Trạng thái: `DRAFT`, `ACTIVE`, `EXPIRED`, `TERMINATED`. |
| `signed_at` | `date`, null | Ngày ký. |
| `valid_to` | `date`, null | Ngày hết hiệu lực, không nhỏ hơn `valid_from`. |
| `file_id` | `uuid`, null | Tệp hợp đồng ở `file_object`. |

: Cột nổi bật của bảng `tenant_contract`

Cột khác: `contract_no` v(64); `title` v(255); `valid_from` date; `note` v(500).

### 3.7. `platform_module`

::: dac-ta
**Mục đích.** EN-20-18 Phân hệ của nền tảng (FR-20-033): danh mục 20 phân hệ PH-01…20 với đợt, đơn vị triển khai, cờ lõi. Dữ liệu nền tảng, mọi tenant đọc được để dựng menu (FR-20-037), chỉ PLATFORM ghi.

**FR phục vụ.** FR-20-033, FR-20-037.

**Khóa chính.** (id).

**Duy nhất.** `uq_platform_module_code` (module_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_platform_module_` + `tenant`, `code`, `wave`, `status`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu PLATR: như PLAT, thêm `platform_data_read` cho phép mọi tenant đọc (`tenant_id = 'PLATFORM'`); chỉ phiên PLATFORM ghi.

**Phân vùng, bất biến.** Bất biến cột `module_code` (`tg_platform_module_immutable`).

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `module_code` | `varchar(8)` | Mã phân hệ `PH-nn`, bất biến. |
| `wave` | `smallint` | Đợt phát triển: 1 (MVP), 2 hoặc 3 (D02-01 §8.3). |
| `du_code` | `varchar(32)` | Đơn vị triển khai (DU), ví dụ `dh-platform`. |
| `status` | `varchar(12)`, mặc định `'AVAILABLE'` | Trạng thái trong danh mục: `AVAILABLE`, `PLANNED`, `DEPRECATED`. |

: Cột nổi bật của bảng `platform_module`

Cột khác: `name` v(255); `is_core` bool; `default_enabled` bool; `display_order` smallint; `description` v(500).

### 3.8. `module_dependency`

::: dac-ta
**Mục đích.** EN-20-19 Phụ thuộc phân hệ (FR-20-033): ma trận phân hệ cần phân hệ nào, bắt buộc hay tùy chọn; chặn bật phân hệ khi thiếu phân hệ bắt buộc. Chu trình do dịch vụ kiểm khi lưu.

**FR phục vụ.** FR-20-033.

**Khóa chính.** (id).

**Duy nhất.** `uq_module_dependency_pair` (module_code, depends_on_code).

**Khóa ngoại.** (module_code) → `platform_module`, (depends_on_code) → `platform_module`.

**Ràng buộc CHECK.** `ck_module_dependency_` + `tenant`, `dependency_type`, `not_self`.

**Chỉ mục.** `ix_module_dependency_depends_on`.

**Cách ly tenant.** Mẫu PLATR: như PLAT, thêm `platform_data_read` cho phép mọi tenant đọc (`tenant_id = 'PLATFORM'`); chỉ phiên PLATFORM ghi.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `module_code` | `varchar(8)` | Phân hệ phụ thuộc. |
| `depends_on_code` | `varchar(8)` | Phân hệ được cần. |
| `dependency_type` | `varchar(10)`, mặc định `'REQUIRED'` | Loại: `REQUIRED` hoặc `OPTIONAL`. |

: Cột nổi bật của bảng `module_dependency`

Cột khác: `reason` v(500).

### 3.9. `tenant_module`

::: dac-ta
**Mục đích.** EN-20-20 Phân hệ theo tenant (FR-20-034, 035, 037): trạng thái bật, tắt, tạm ngừng của từng phân hệ đối với tenant; phân hệ báo kết quả bất đồng bộ qua EVT-20-07, 08. Nguồn cho menu và ERR-20-103.

**FR phục vụ.** FR-20-016, FR-20-034, 035, FR-20-037, FR-20-065, 066.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_module_module` (tenant_id, module_code).

**Khóa ngoại.** (tenant_id) → `tenant`, (module_code) → `platform_module`.

**Ràng buộc CHECK.** `ck_tenant_module_` + `tenant`, `state`, `config`, `enabled`.

**Chỉ mục.** `ix_tenant_module_state`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `module_code` | `varchar(8)` | Phân hệ. |
| `state` | `varchar(10)`, mặc định `'DISABLED'` | Trạng thái: `DISABLED`, `ENABLING`, `ENABLED`, `DISABLING`, `SUSPENDED`, `FAILED`. |
| `enabled_at` | `timestamptz`, null | Lần bật gần nhất. |
| `config` | `jsonb`, mặc định `'{}'` | Cấu hình riêng của phân hệ cho tenant (ví dụ PH-17 `enabled`). |

: Cột nổi bật của bảng `tenant_module`

Cột khác: `disabled_at` ts; `state_reason` v(500); `last_report_at` ts; `last_event_id` uuid.

### 3.10. `tenant_feature_flag`

::: dac-ta
**Mục đích.** EN-20-21 Cờ tính năng theo tenant (FR-20-036): bật, tắt tính năng cụ thể, có tỷ lệ phát hành và thời hạn. Mã cờ dùng cột `flag_code`.

**FR phục vụ.** FR-20-036.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_feature_flag_flag` (tenant_id, flag_code).

**Khóa ngoại.** (tenant_id) → `tenant`, (module_code) → `platform_module`.

**Ràng buộc CHECK.** `ck_tenant_feature_flag_` + `tenant`, `code`, `rollout`, `valid`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `module_code` | `varchar(8)`, null | Phân hệ chứa tính năng (nếu có). |
| `flag_code` | `varchar(64)` | Mã cờ tính năng, dạng `{phân-hệ}.{tính-năng}`. |
| `rollout_percent` | `numeric(5,2)`, mặc định `100` | Tỷ lệ phát hành dần, 0 đến 100. |
| `valid_from` | `timestamptz`, null | Cờ có hiệu lực từ. |
| `valid_to` | `timestamptz`, null | Cờ hết hiệu lực. |

: Cột nổi bật của bảng `tenant_feature_flag`

Cột khác: `enabled` bool; `description` v(500).

### 3.11. `tenant_platform_config`

::: dac-ta
**Mục đích.** EN-20-05 Cấu hình nền tảng của tenant (FR-20-019): realm, host và tiền tố API công bố, hồ sơ triển khai, vùng DR, tham chiếu cụm riêng. Một dòng mỗi tenant; cấu hình mong muốn nằm ở kho Git `dh-tenant-config`, bảng giữ bản chiếu và trạng thái áp.

**FR phục vụ.** FR-20-017, FR-20-019, 020, FR-20-065.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_platform_config_tenant` (tenant_id), `uq_tenant_platform_config_realm` (realm_code), `uq_tenant_platform_config_api_host` (api_host) khi api_host IS NOT NULL.

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_tenant_platform_config_` + `tenant`, `drift_status`, `profile`, `sha`, `host`, `version`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `api_host` | `varchar(253)`, null | Host API công bố của tenant. |
| `deployment_profile` | `varchar(4)`, mặc định `'HT-A'` | Hồ sơ triển khai: `HT-A` hoặc `HT-B`. |
| `kafka_prefix` | `varchar(16)` | Tiền tố topic Kafka (mã tenant viết thường, `t68.`). |
| `bucket_prefix` | `varchar(32)` | Tiền tố bucket kho đối tượng (`dh-t68-`). |
| `db_route_ref` | `varchar(128)`, null | Tham chiếu bảng định tuyến CSDL khi `DEDICATED_DB`; không chứa chuỗi kết nối. |

: Cột nổi bật của bảng `tenant_platform_config`

Cột khác: `realm_code` v(64); `api_path_prefix` v(64); `dr_zone` v(32); `cluster_ref` v(64); `config_version_no` int; `last_commit_sha` char(40); `drift_status` v(12); `last_applied_at` ts.

### 3.12. `tenant_settings`

::: dac-ta
**Mục đích.** EN-20-06 Cài đặt tỉnh do quản trị tỉnh tự quản (FR-20-018): thông tin hiển thị, chủ quản CNTT, an toàn đăng nhập trong giới hạn nền tảng, địa chỉ nhận thông báo. Một dòng mỗi tenant; giới hạn nền tảng kiểm ở dịch vụ.

**FR phục vụ.** FR-20-018, FR-20-069.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_settings_tenant` (tenant_id).

**Khóa ngoại.** (tenant_id) → `tenant`, (logo_file_id, tenant_id) → `file_object`, (it_owner_org_id, tenant_id) → `organization`.

**Ràng buộc CHECK.** `ck_tenant_settings_` + `tenant`, `idle`, `password`, `lockout`, `extra`, `email`.

**Chỉ mục.** `ix_tenant_settings_fk_logo`, `ix_tenant_settings_fk_it_owner`.

**Cách ly tenant.** Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Địa chỉ hỗ trợ là thư điện tử cơ quan, không phải cá nhân.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `logo_file_id` | `uuid`, null | Tệp logo. |
| `it_owner_org_id` | `uuid`, null | Tổ chức chủ quản CNTT của tỉnh. |
| `support_email` | `varchar(254)`, null | Thư điện tử hỗ trợ. |
| `idle_session_minutes` | `smallint`, mặc định `30` | Thời gian rảnh tối đa của phiên, phút. |
| `password_min_length` | `smallint`, mặc định `12` | Độ dài tối thiểu của mật khẩu. |

: Cột nổi bật của bảng `tenant_settings`

Cột khác: `display_name` v(255); `hotline` v(20); `mfa_required` bool; `lockout_attempts` smallint; `ip_allowlist` text[]; `notify_emails` text[]; `locale` v(10); `timezone` v(40); `extra` jsonb.

### 3.13. `tenant_config_version`

::: dac-ta
**Mục đích.** EN-20-07 Phiên bản cấu hình (FR-20-020, 021): bản chiếu mỗi commit cấu hình ở kho Git, giữ ảnh chụp để so sánh và khôi phục. Chỉ thêm; cột nội dung bất biến, chỉ trạng thái áp được cập nhật.

**FR phục vụ.** FR-20-019…021.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_config_version_version` (tenant_id, version_no).

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_tenant_config_version_` + `tenant`, `version`, `config_scope`, `change_source`, `apply_status`, `sha`, `hash`, `snapshot`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Bất biến cột `version_no`, `git_commit_sha`, `content_hash`, `snapshot`, `config_scope`, `change_source` (`tg_tenant_config_version_immutable`).

**Lưu giữ, ghi chú.** Giữ 24 phiên bản gần nhất mỗi tenant trong CSDL, bản cũ hơn nằm ở lịch sử Git; chỉ thêm.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `version_no` | `integer` | Số phiên bản tăng dần trong tenant. |
| `config_scope` | `varchar(16)`, mặc định `'ALL'` | Phạm vi: `PLATFORM_CONFIG`, `SETTINGS`, `QUOTA`, `MODULES`, `ALL`. |
| `git_commit_sha` | `char(40)` | Mã commit trong kho `dh-tenant-config`. |
| `content_hash` | `char(64)` | Mã băm SHA-256 của nội dung cấu hình. |
| `change_source` | `varchar(12)`, mặc định `'API'` | Nguồn thay đổi: `API`, `SAGA`, `RESTORE`, `DRIFT_FIX`. |

: Cột nổi bật của bảng `tenant_config_version`

Cột khác: `commit_message` v(500); `snapshot` jsonb; `reason` v(500); `apply_status` v(10); `applied_at` ts.

### 3.14. `config_drift`

::: dac-ta
**Mục đích.** EN-20-08 Lệch cấu hình (FR-20-022): kết quả đối chiếu định kỳ giữa kho Git và thực tế; mỗi tenant tối đa một lệch đang mở. Số liệu so sánh chỉ là băm và danh sách khác biệt, không chứa giá trị bí mật.

**FR phục vụ.** FR-20-022.

**Khóa chính.** (id).

**Duy nhất.** `uq_config_drift_open` (tenant_id) khi status IN ('DRIFTED', 'RECONCILING').

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_config_drift_` + `tenant`, `status`, `resolution`, `detected_by`, `diff`, `resolved`.

**Chỉ mục.** `ix_config_drift_detected`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ 12 tháng; bản đã xử lý dọn theo lô.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(12)`, mặc định `'DRIFTED'` | Trạng thái: `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN`. |
| `detected_by` | `varchar(12)`, mặc định `'PERIODIC'` | Nguồn phát hiện: `PERIODIC` hoặc `ARGOCD`. |
| `resolution` | `varchar(10)`, null | Cách xử lý: `RECONCILED`, `ACCEPTED`, `IGNORED`. |
| `resolved_by` | `varchar(64)`, null | Người xử lý. |
| `resolved_at` | `timestamptz`, null | Thời điểm xử lý xong. |

: Cột nổi bật của bảng `config_drift`

Cột khác: `detected_at` ts; `desired_version_no` int; `desired_hash` char(64); `actual_hash` char(64); `differences` jsonb.

### 3.15. `cross_tenant_policy`

::: dac-ta
**Mục đích.** EN-20-29 Chính sách tiếp nhận truy cập liên tenant của tỉnh (FR-20-023): có cho phép ghi hay không, chấp thuận trước, thời hạn tối đa, người nhận thông báo. PH-12 đọc khi cấp quyền liên tenant (FR-00-012); thời hạn không vượt trần nền tảng `20.cross-tenant.max-hours` (kiểm ở dịch vụ).

**FR phục vụ.** FR-20-023, 024.

**Khóa chính.** (id).

**Duy nhất.** `uq_cross_tenant_policy_tenant` (tenant_id).

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_cross_tenant_policy_` + `tenant`, `hours`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Danh sách thư nhận thông báo là địa chỉ cơ quan hoặc nhóm.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `max_hours` | `smallint`, mặc định `4` | Thời hạn tối đa một phiên liên tenant, giờ. |

: Cột nổi bật của bảng `cross_tenant_policy`

Cột khác: `allow_write` bool; `preapproved_roles` text[]; `require_reason` bool; `notify_emails` text[]; `notify_contact_types` text[]; `effective_from` ts.

### 3.16. `provisioning_run`

::: dac-ta
**Mục đích.** EN-20-10 Lần chạy saga (FR-20-008…011, 016, 017): khởi tạo ban đầu, khởi tạo bổ sung, đổi chế độ cách ly. Mỗi tenant tối đa một lần chạy đang hoạt động (PENDING, RUNNING, WAITING, COMPENSATING). Saga điều phối trên PostgreSQL (ADR 200), có khóa ShedLock ở dịch vụ.

**FR phục vụ.** FR-20-008…011, FR-20-014, FR-20-016, 017, FR-20-025.

**Khóa chính.** (id).

**Duy nhất.** `uq_provisioning_run_active` (tenant_id) khi status IN ('PENDING', 'RUNNING', 'WAITING', 'COMPENSATING').

**Khóa ngoại.** (tenant_id) → `tenant`, (template_id) → `provisioning_template`.

**Ràng buộc CHECK.** `ck_provisioning_run_` + `tenant`, `status`, `run_kind`, `isolation_mode`, `attempt`, `step`, `finished`, `duration`, `trace`.

**Chỉ mục.** `ix_provisioning_run_tenant_started`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Bất biến cột `run_kind` (`tg_provisioning_run_immutable`); Máy trạng thái `status` (`tg_provisioning_run_transition`).

**Lưu giữ, ghi chú.** Giữ trọn đời tenant (bằng chứng khởi tạo, KPI-12).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `run_kind` | `varchar(16)`, mặc định `'INITIAL'` | Loại lần chạy: `INITIAL`, `SUPPLEMENT`, `ISOLATION_CHANGE`. |
| `status` | `varchar(12)`, mặc định `'PENDING'` | Trạng thái: `PENDING`, `RUNNING`, `WAITING`, `FAILED`, `COMPENSATING`, `COMPENSATED`, `SUCCEEDED`, `CANCELLED`. |
| `template_id` | `uuid`, null | Phiên bản mẫu khởi tạo dùng cho lần chạy. |
| `isolation_mode` | `varchar(24)`, mặc định `'SHARED'` | Chế độ cách ly của lần chạy (quyết định bước S07). |
| `attempt` | `integer`, mặc định `1` | Lần thử (tăng khi thử lại từ bước lỗi). |

: Cột nổi bật của bảng `provisioning_run`

Cột khác: `current_step_code` v(20); `started_at` ts; `finished_at` ts; `duration_seconds` int; `error_code` v(16); `error_message` v(1000); `requested_by` v(64); `trace_id` char(32); `kpi_reported_at` ts.

### 3.17. `provisioning_step`

::: dac-ta
**Mục đích.** EN-20-11 Bước saga (FR-20-009, 010, 011): sổ bước của một lần chạy, 17 mã bước `S01_RECORD`…`S17_ACTIVATE`; bước bất đồng bộ chờ phân hệ báo qua `:report`. Lũy đẳng theo `idempotency_ref = {runId}:{stepCode}`.

**FR phục vụ.** FR-20-008…011.

**Khóa chính.** (id).

**Duy nhất.** `uq_provisioning_step_step` (run_id, step_code).

**Khóa ngoại.** (tenant_id) → `tenant`, (run_id, tenant_id) → `provisioning_run` xóa theo.

**Ràng buộc CHECK.** `ck_provisioning_step_` + `tenant`, `status`, `code`, `order`, `attempt`, `idem`, `detail`.

**Chỉ mục.** `ix_provisioning_step_waiting`, `ix_provisioning_step_fk_run`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Bất biến cột `run_id`, `step_code`, `idempotency_ref` (`tg_provisioning_step_immutable`).

**Lưu giữ, ghi chú.** Theo lần chạy; không xóa riêng lẻ.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `run_id` | `uuid` | Lần chạy chứa bước. |
| `step_code` | `varchar(20)` | Mã bước `S01_RECORD`…`S17_ACTIVATE` (brief mục 4.1). |
| `step_order` | `smallint` | Thứ tự thực hiện, 1 đến 17. |
| `status` | `varchar(16)`, mặc định `'PENDING'` | Trạng thái: `PENDING`, `RUNNING`, `WAITING_REPORT`, `SUCCEEDED`, `FAILED`, `SKIPPED`, `COMPENSATING`, `COMPENSATED`. |
| `executor` | `varchar(16)` | Bên thực hiện, ví dụ `PH-12`, `PH-20`, `PH-10`. |

: Cột nổi bật của bảng `provisioning_step`

Cột khác: `is_async` bool; `attempt` int; `idempotency_ref` v(64); `started_at` ts; `reported_at` ts; `finished_at` ts; `timeout_at` ts; `error_code` v(16); `error_message` v(1000); `detail` jsonb.

### 3.18. `smoke_test_result`

::: dac-ta
**Mục đích.** EN-20-12 Kết quả kiểm tra khói (FR-20-012): đăng nhập quản trị, gọi API mẫu, phát nhận sự kiện mẫu, một ca rò rỉ chéo tenant (bước S16). Chỉ thêm; tenant chưa qua kiểm tra khói không được `ACTIVE`.

**FR phục vụ.** FR-20-012.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id) → `tenant`, (run_id, tenant_id) → `provisioning_run`.

**Ràng buộc CHECK.** `ck_smoke_test_result_` + `tenant`, `check_code`, `result`, `duration`, `detail`.

**Chỉ mục.** `ix_smoke_test_result_executed`, `ix_smoke_test_result_fk_run`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Chỉ thêm, chặn UPDATE và DELETE (`tg_smoke_test_result_append_only`).

**Lưu giữ, ghi chú.** Theo lần chạy saga; chỉ thêm.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `run_id` | `uuid` | Lần chạy saga. |
| `check_code` | `varchar(24)` | Ca kiểm tra: `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK`. |
| `result` | `varchar(8)` | Kết quả: `PASS`, `FAIL`, `SKIPPED`. |
| `duration_ms` | `integer`, null | Thời gian chạy, mili giây. |

: Cột nổi bật của bảng `smoke_test_result`

Cột khác: `detail` jsonb; `executed_at` ts.

### 3.19. `tenant_quota`

::: dac-ta
**Mục đích.** EN-20-13 Hạn mức hợp đồng của tenant (FR-20-026, 027): mỗi tenant một dòng cho mỗi tài nguyên (12 loại). PH-20 giữ giá trị và đẩy xuống nơi thực thi (APISIX, Kafka, PH-04…), không tự thực thi (ADR 204).

**FR phục vụ.** FR-20-007, FR-20-026, 027, FR-20-030, FR-20-069.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_quota_resource` (tenant_id, resource_code).

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_tenant_quota_` + `tenant`, `resource_code`, `limit`, `source`, `push_status`, `warn`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `resource_code` | `varchar(24)` | Tài nguyên: 12 giá trị `QuotaResource`. |
| `limit_value` | `numeric(20,3)` | Giá trị hạn mức hợp đồng. |
| `unit` | `varchar(16)` | Đơn vị: `rps`, `MB/s`, `GB`, `user`, `vCPU`… |
| `source` | `varchar(10)`, mặc định `'TEMPLATE'` | Nguồn giá trị: `TEMPLATE`, `CONTRACT`, `OVERRIDE`. |
| `warn_percent` | `smallint`, mặc định `80` | Ngưỡng cảnh báo, phần trăm (`20.quota.warn-percent`). |

: Cột nổi bật của bảng `tenant_quota`

Cột khác: `effective_from` ts; `push_status` v(8); `pushed_at` ts.

### 3.20. `quota_change_request`

::: dac-ta
**Mục đích.** EN-20-14 Đề nghị đổi hạn mức (FR-20-026, 027): có duyệt bốn mắt, người duyệt khác người đề nghị; hạ dưới mức đang dùng cần lý do và duyệt. Duyệt xong thì cập nhật `tenant_quota` và phát EVT-20-05.

**FR phục vụ.** FR-20-026, 027.

**Khóa chính.** (id).

**Duy nhất.** `uq_quota_change_request_open` (tenant_id, resource_code) khi status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING').

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_quota_change_request_` + `tenant`, `resource_code`, `status`, `values`, `four_eyes`, `approved`.

**Chỉ mục.** `ix_quota_change_request_tenant_status`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Máy trạng thái `status` (`tg_quota_change_request_transition`); Bất biến cột `resource_code`, `requested_by`, `requested_value` (`tg_quota_change_request_immutable`).

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `resource_code` | `varchar(24)` | Tài nguyên đề nghị đổi. |
| `current_value` | `numeric(20,3)` | Giá trị hạn mức hiện tại khi đề nghị. |
| `requested_value` | `numeric(20,3)` | Giá trị đề nghị. |
| `status` | `varchar(16)`, mặc định `'DRAFT'` | Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`. |
| `approved_by` | `varchar(64)`, null | Người duyệt, khác người đề nghị. |

: Cột nổi bật của bảng `quota_change_request`

Cột khác: `current_usage` numeric(20,3); `reason` v(1000); `ticket_code` v(32); `requested_by` v(64); `requested_at` ts; `approved_at` ts; `decision_note` v(1000); `executed_at` ts.

### 3.21. `quota_override`

::: dac-ta
**Mục đích.** EN-20-15 Ghi đè hạn mức tạm thời có thời hạn (FR-20-032): nâng tạm trần cho một tài nguyên trong khoảng ngày, tự hết hạn; thời hạn tối đa `20.quota.override-max-days` kiểm ở dịch vụ. Người phê duyệt khác người đề nghị.

**FR phục vụ.** FR-20-032.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_quota_override_` + `tenant`, `resource_code`, `status`, `value`, `valid`, `four_eyes`, `revoked`.

**Chỉ mục.** `ix_quota_override_active`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `resource_code` | `varchar(24)` | Tài nguyên được ghi đè. |
| `override_value` | `numeric(20,3)` | Giá trị hạn mức tạm thời. |
| `valid_to` | `timestamptz` | Hết hiệu lực, sau `valid_from`. |
| `status` | `varchar(8)`, mặc định `'ACTIVE'` | Trạng thái: `ACTIVE`, `EXPIRED`, `REVOKED`. |
| `approved_by` | `varchar(64)` | Người duyệt, khác người đề nghị. |

: Cột nổi bật của bảng `quota_override`

Cột khác: `valid_from` ts; `reason` v(1000); `ticket_code` v(32); `requested_by` v(64); `revoked_at` ts.

### 3.22. `usage_snapshot`

::: dac-ta
**Mục đích.** EN-20-16 Ảnh chụp sử dụng tài nguyên (FR-20-028, 030): mỗi giờ mỗi tài nguyên một dòng lấy từ nơi thực thi (Mimir, APISIX, Kafka, kho đối tượng, CSDL…). Phân vùng theo tháng trên `captured_at`, giữ `20.usage.retention-months` tháng.

**FR phục vụ.** FR-20-028, FR-20-030, FR-20-067.

**Khóa chính.** (id, captured_at).

**Duy nhất.** `uq_usage_snapshot_point` (tenant_id, resource_code, captured_at).

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_usage_snapshot_` + `tenant`, `resource_code`, `source`, `used`, `limit`.

**Chỉ mục.** `ix_usage_snapshot_tenant_time`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Phân vùng RANGE theo tháng trên `captured_at` (thủ tục `p_ensure_partitions`), kèm phân vùng mặc định; dọn bằng DETACH PARTITION, DROP.

**Lưu giữ, ghi chú.** Giữ `20.usage.retention-months` (25) tháng, dọn bằng DETACH, DROP phân vùng tháng.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `resource_code` | `varchar(24)` | Tài nguyên: 12 giá trị `QuotaResource`. |
| `captured_at` | `timestamptz` | Thời điểm chụp (đầu giờ), khóa phân vùng. |
| `used_value` | `numeric(20,3)` | Mức đang dùng. |
| `limit_value` | `numeric(20,3)`, null | Hạn mức hiệu lực tại thời điểm chụp (gồm ghi đè). |
| `source` | `varchar(14)`, mặc định `'MIMIR'` | Nơi lấy số liệu: `MIMIR`, `APISIX`, `KAFKA`, `OBJECT_STORE`, `DATABASE`, `IAM`, `CATALOG`, `RUNTIME`, `OTHER`. |

: Cột nổi bật của bảng `usage_snapshot`

Cột khác: `percent_used` numeric(7,2); `is_estimate` bool.

### 3.23. `quota_alert`

::: dac-ta
**Mục đích.** EN-20-17 Cảnh báo hạn mức (FR-20-029): chạm 80% (`WARN_80`) hoặc 100% (`LIMIT_100`), phát EVT-20-06 cho PH-13, PH-18; mỗi (tenant, tài nguyên, mức) tối đa một cảnh báo đang mở.

**FR phục vụ.** FR-20-029, FR-20-067.

**Khóa chính.** (id).

**Duy nhất.** `uq_quota_alert_open` (tenant_id, resource_code, alert_level) khi state IN ('OPEN', 'ACKNOWLEDGED').

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_quota_alert_` + `tenant`, `resource_code`, `alert_level`, `state`, `limit`, `resolved`.

**Chỉ mục.** `ix_quota_alert_raised`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ 24 tháng.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `resource_code` | `varchar(24)` | Tài nguyên. |
| `alert_level` | `varchar(10)` | Mức: `WARN_80` hoặc `LIMIT_100`. |
| `state` | `varchar(12)`, mặc định `'OPEN'` | Trạng thái: `OPEN`, `ACKNOWLEDGED`, `RESOLVED`. |
| `resolved_at` | `timestamptz`, null | Thời điểm hết cảnh báo. |

: Cột nổi bật của bảng `quota_alert`

Cột khác: `used_value` numeric(20,3); `limit_value` numeric(20,3); `percent_used` numeric(7,2); `raised_at` ts; `acknowledged_by` v(64); `acknowledged_at` ts; `event_id` uuid.

### 3.24. `usage_report`

::: dac-ta
**Mục đích.** EN-20-37 Báo cáo sử dụng (FR-20-031): báo cáo theo kỳ cho một tenant hoặc toàn nền tảng (`tenant_id = PLATFORM`), xuất `XLSX`, `CSV`, `PDF`; tệp lưu ở `file_object`, hết hạn tự dọn.

**FR phục vụ.** FR-20-031.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id) → `tenant`, (file_id, tenant_id) → `file_object`.

**Ràng buộc CHECK.** `ck_usage_report_` + `tenant`, `report_scope`, `format`, `status`, `period`, `granularity`, `scope_tenant`, `ready`.

**Chỉ mục.** `ix_usage_report_tenant_period`, `ix_usage_report_fk_file`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Tệp hết hạn theo `expires_at` (mặc định 30 ngày), dòng giữ 24 tháng.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `report_scope` | `varchar(8)`, mặc định `'TENANT'` | Phạm vi: `TENANT` hoặc `PLATFORM`. |
| `period_to` | `date` | Kỳ báo cáo đến ngày, không nhỏ hơn `period_from`. |
| `granularity` | `varchar(8)`, mặc định `'MONTH'` | Độ mịn: `HOUR`, `DAY`, `MONTH`. |
| `format` | `varchar(4)`, mặc định `'XLSX'` | Định dạng: `XLSX`, `CSV`, `PDF`. |
| `status` | `varchar(12)`, mặc định `'REQUESTED'` | Trạng thái: `REQUESTED`, `GENERATING`, `READY`, `FAILED`, `EXPIRED`. |

: Cột nổi bật của bảng `usage_report`

Cột khác: `period_from` date; `file_id` uuid; `row_count` int; `requested_by` v(64); `expires_at` ts; `error_message` v(1000).

### 3.25. `lifecycle_request`

::: dac-ta
**Mục đích.** EN-20-22 Đề nghị vòng đời có duyệt (FR-20-038…042): tạm ngừng, khôi phục, chấm dứt, đổi chế độ cách ly, hạ hạn mức. Chấm dứt, đổi cách ly, hạ hạn mức cần duyệt bốn mắt (người duyệt khác người đề nghị); mỗi (tenant, loại) tối đa một đề nghị đang mở. Mọi đề nghị có lý do và mã phiếu (SEC-85).

**FR phục vụ.** FR-20-025, FR-20-038…042.

**Khóa chính.** (id).

**Duy nhất.** `uq_lifecycle_request_open` (tenant_id, request_type) khi status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING').

**Khóa ngoại.** (tenant_id) → `tenant`, (quota_change_id, tenant_id) → `quota_change_request`.

**Ràng buộc CHECK.** `ck_lifecycle_request_` + `tenant`, `request_type`, `status`, `suspend_reason`, `target_isolation`, `four_eyes`, `suspend`, `isolation`, `quota`, `approved`, `done`.

**Chỉ mục.** `ix_lifecycle_request_tenant_status`, `ix_lifecycle_request_fk_quota_change`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Máy trạng thái `status` (`tg_lifecycle_request_transition`); Bất biến cột `request_type`, `requested_by` (`tg_lifecycle_request_immutable`).

**Lưu giữ, ghi chú.** Giữ vĩnh viễn (căn cứ quyết định, bốn mắt).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `request_type` | `varchar(20)` | Loại: `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE`. |
| `status` | `varchar(16)`, mặc định `'DRAFT'` | Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`. |
| `suspend_reason` | `varchar(24)`, null | Lý do tạm ngừng: `MANAGEMENT_DECISION`, `SECURITY_INCIDENT`, `CONTRACT_EXPIRED`, `TENANT_REQUEST`, `OTHER`; bắt buộc với `SUSPEND`. |
| `essential_api_allowed` | `boolean`, mặc định `false` | Cho phép API thiết yếu hoạt động khi tạm ngừng (`20.suspend.essential-api-allowed`). |
| `approved_by` | `varchar(64)`, null | Người duyệt, khác người đề nghị. |

: Cột nổi bật của bảng `lifecycle_request`

Cột khác: `reason` v(1000); `ticket_code` v(32); `requested_by` v(64); `requested_at` ts; `approved_at` ts; `decision_note` v(1000); `scheduled_at` ts; `cooling_until` ts; `target_isolation_mode` v(24); `quota_change_id` uuid; `executed_at` ts.

### 3.26. `tenant_status_history`

::: dac-ta
**Mục đích.** EN-20-23 Sự kiện vòng đời, lịch sử trạng thái tenant (FR-20-043): mỗi lần đổi `tenant.status` ghi một dòng kèm lý do, mã phiếu, đề nghị hoặc lần chạy saga liên quan. Chỉ thêm. Nhật ký kiểm toán chuỗi băm của tenant do PH-13 giữ; bảng này phục vụ hiển thị nhanh và đối chiếu.

**FR phục vụ.** FR-20-013, FR-20-043, 044, FR-20-068.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id) → `tenant`, (request_id, tenant_id) → `lifecycle_request`, (run_id, tenant_id) → `provisioning_run`.

**Ràng buộc CHECK.** `ck_tenant_status_history_` + `tenant`, `from_status`, `to_status`, `changed`, `trace`.

**Chỉ mục.** `ix_tenant_status_history_tenant_changed`, `ix_tenant_status_history_fk_request`, `ix_tenant_status_history_fk_run`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Chỉ thêm, chặn UPDATE và DELETE (`tg_tenant_status_history_append_only`).

**Lưu giữ, ghi chú.** Giữ vĩnh viễn; chỉ thêm.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `from_status` | `varchar(16)`, null | Trạng thái trước (rỗng với lần khai báo đầu). |
| `to_status` | `varchar(16)` | Trạng thái sau. |
| `request_id` | `uuid`, null | Đề nghị vòng đời liên quan. |
| `run_id` | `uuid`, null | Lần chạy saga liên quan. |
| `trace_id` | `char(32)`, null | Mã vết phân tán. |

: Cột nổi bật của bảng `tenant_status_history`

Cột khác: `reason` v(1000); `ticket_code` v(32); `changed_by` v(64); `changed_at` ts.

### 3.27. `data_export_package`

::: dac-ta
**Mục đích.** EN-20-24 Gói bàn giao dữ liệu tenant (FR-20-041): gói xuất khi chấm dứt, gồm các mục theo phân hệ; giữ `20.export.retention-days` ngày. Phát EVT-20-16 khi sẵn sàng.

**FR phục vụ.** FR-20-041.

**Khóa chính.** (id).

**Duy nhất.** `uq_data_export_package_open` (tenant_id) khi status IN ('REQUESTED', 'COLLECTING').

**Khóa ngoại.** (tenant_id) → `tenant`, (request_id, tenant_id) → `lifecycle_request`, (file_id, tenant_id) → `file_object`.

**Ràng buộc CHECK.** `ck_data_export_package_` + `tenant`, `status`, `size`, `sha`, `ready`, `delivered`, `items`.

**Chỉ mục.** `ix_data_export_package_tenant_status`, `ix_data_export_package_fk_request`, `ix_data_export_package_fk_file`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Tệp giữ `20.export.retention-days` (90) ngày sau khi sẵn sàng, dòng giữ vĩnh viễn.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `request_id` | `uuid`, null | Đề nghị vòng đời chấm dứt phát sinh gói. |
| `status` | `varchar(12)`, mặc định `'REQUESTED'` | Trạng thái: `REQUESTED`, `COLLECTING`, `READY`, `DELIVERED`, `EXPIRED`, `FAILED`. |
| `file_id` | `uuid`, null | Tệp gói ở `file_object`. |
| `size_bytes` | `bigint`, null | Kích thước gói. |
| `item_count` | `integer`, mặc định `0` | Số mục theo phân hệ. |

: Cột nổi bật của bảng `data_export_package`

Cột khác: `sha256` char(64); `ready_at` ts; `delivered_at` ts; `delivered_to` v(255); `expires_at` ts; `requested_by` v(64); `error_message` v(1000).

### 3.28. `data_export_item`

::: dac-ta
**Mục đích.** EN-20-24 Mục của gói bàn giao (FR-20-041): dữ liệu một phân hệ đóng gói riêng, có số dòng và mã băm để đối chiếu.

**FR phục vụ.** FR-20-041.

**Khóa chính.** (id).

**Duy nhất.** `uq_data_export_item_item` (package_id, module_code, item_type).

**Khóa ngoại.** (tenant_id) → `tenant`, (package_id, tenant_id) → `data_export_package` xóa theo, (module_code) → `platform_module`, (file_id, tenant_id) → `file_object`.

**Ràng buộc CHECK.** `ck_data_export_item_` + `tenant`, `status`, `counts`, `sha`, `done`.

**Chỉ mục.** `ix_data_export_item_fk_package`, `ix_data_export_item_fk_file`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Theo gói bàn giao.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `package_id` | `uuid` | Gói bàn giao chứa mục. |
| `module_code` | `varchar(8)` | Phân hệ có dữ liệu. |
| `item_type` | `varchar(32)` | Loại dữ liệu trong phân hệ (ví dụ `catalog`, `audit-chain`). |
| `status` | `varchar(12)`, mặc định `'PENDING'` | Trạng thái: `PENDING`, `COLLECTING`, `DONE`, `FAILED`. |
| `row_count` | `bigint`, null | Số bản ghi. |

: Cột nổi bật của bảng `data_export_item`

Cột khác: `size_bytes` bigint; `sha256` char(64); `file_id` uuid; `error_message` v(1000).

### 3.29. `merge_plan`

::: dac-ta
**Mục đích.** EN-20-25 Kế hoạch sáp nhập (FR-20-045, 051, 052): tenant nguồn sáp nhập vào tenant đích (D03-10 §5.4). Dữ liệu nền tảng; hai tenant bên tham gia đọc được kế hoạch của mình. Mỗi tenant nguồn tối đa một kế hoạch đang mở; duyệt bốn mắt (người duyệt khác người lập).

**FR phục vụ.** FR-20-045, FR-20-051, 052.

**Khóa chính.** (id).

**Duy nhất.** `uq_merge_plan_code` (plan_code), `uq_merge_plan_open_source` (source_tenant_code) khi status NOT IN ('COMPLETED', 'CANCELLED').

**Khóa ngoại.** (source_tenant_code) → `tenant`, (target_tenant_code) → `tenant`.

**Ràng buộc CHECK.** `ck_merge_plan_` + `tenant`, `status`, `code`, `source`, `target`, `distinct`, `four_eyes`, `months`, `approved`, `cutover`, `completed`.

**Chỉ mục.** `ix_merge_plan_target`, `ix_merge_plan_status`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy. Thêm `merge_party_read`: tenant nguồn và tenant đích đọc kế hoạch của mình.

**Phân vùng, bất biến.** Máy trạng thái `status` (`tg_merge_plan_transition`); Bất biến cột `plan_code`, `source_tenant_code`, `target_tenant_code` (`tg_merge_plan_immutable`).

**Lưu giữ, ghi chú.** Giữ vĩnh viễn.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_code` | `varchar(48)` | Mã kế hoạch dạng `SN-2026-001` (cũng là `mergePlanId` ở API), dùng ở route `/nen-tang/sap-nhap/{ma}`. |
| `status` | `varchar(20)`, mặc định `'DRAFT'` | Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `DRY_RUN`, `TRANSFERRING`, `CONFLICT_REVIEW`, `IDENTITY_TRANSFER`, `CUTOVER`, `TRANSITION`, `COMPLETED`, `CANCELLED`, `FAILED`. |
| `source_tenant_code` | `varchar(16)` | Tenant nguồn (sẽ sang `MERGED`). |
| `target_tenant_code` | `varchar(16)` | Tenant đích nhận dữ liệu. |
| `transition_months` | `smallint`, mặc định `6` | Thời gian chuyển tiếp, tháng (`20.merge.transition-months`, trần `20.merge.transition-max-months` kiểm ở dịch vụ). |

: Cột nổi bật của bảng `merge_plan`

Cột khác: `name` v(255); `legal_basis` v(1000); `ticket_code` v(32); `effective_date` date; `requested_by` v(64); `approved_by` v(64); `approved_at` ts; `dry_run_at` ts; `started_at` ts; `cutover_at` ts; `transition_until` date; `completed_at` ts; `cancel_reason` v(1000).

### 3.30. `merge_mapping`

::: dac-ta
**Mục đích.** EN-20-26 Ánh xạ sáp nhập (FR-20-046): bảng ánh xạ tổ chức, HTTT, mã danh mục địa phương, đường dẫn API, người dùng, topic từ nguồn sang đích; dùng cho chuyển dữ liệu và định tuyến chuyển tiếp ở APISIX.

**FR phục vụ.** FR-20-046, FR-20-050.

**Khóa chính.** (id).

**Duy nhất.** `uq_merge_mapping_source` (plan_id, mapping_type, source_ref).

**Khóa ngoại.** (plan_id, tenant_id) → `merge_plan` xóa theo.

**Ràng buộc CHECK.** `ck_merge_mapping_` + `tenant`, `mapping_type`, `status`, `target`.

**Chỉ mục.** `ix_merge_mapping_fk_plan`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ vĩnh viễn, phục vụ định tuyến chuyển tiếp và truy vết `origin_tenant_id`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_id` | `uuid` | Kế hoạch sáp nhập. |
| `mapping_type` | `varchar(16)` | Loại: `ORGANIZATION`, `MEMBER_SYSTEM`, `CATALOG_CODE`, `API_CONTEXT_PATH`, `USER`, `TOPIC`. |
| `target_ref` | `varchar(255)`, null | Mã, đường dẫn hoặc định danh tương ứng ở tenant đích. |
| `status` | `varchar(10)`, mặc định `'PROPOSED'` | Trạng thái: `PROPOSED`, `CONFIRMED`, `CONFLICT`, `APPLIED`. |

: Cột nổi bật của bảng `merge_mapping`

Cột khác: `source_ref` v(255); `note` v(500).

### 3.31. `merge_participant_run`

::: dac-ta
**Mục đích.** EN-20-27 Lần chuyển theo phân hệ (FR-20-047, 048): mỗi phân hệ có dữ liệu chạy từng pha (chạy thử, chuyển, định danh, chuyển tiếp, kiểm đếm) theo hợp đồng bên tham gia sáp nhập (ADR 202); PH-18 chạy công cụ chuyển, PH-20 điều phối.

**FR phục vụ.** FR-20-047, 048, FR-20-050.

**Khóa chính.** (id).

**Duy nhất.** `uq_merge_participant_run_phase` (plan_id, module_code, phase).

**Khóa ngoại.** (plan_id, tenant_id) → `merge_plan` xóa theo, (module_code) → `platform_module`.

**Ràng buộc CHECK.** `ck_merge_participant_run_` + `tenant`, `phase`, `status`, `attempt`, `counts`.

**Chỉ mục.** `ix_merge_participant_run_fk_plan`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ vĩnh viễn.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_id` | `uuid` | Kế hoạch sáp nhập. |
| `module_code` | `varchar(8)` | Phân hệ tham gia. |
| `phase` | `varchar(10)` | Pha: `DRY_RUN`, `TRANSFER`, `IDENTITY`, `CUTOVER`, `VERIFY`. |
| `status` | `varchar(10)`, mặc định `'PENDING'` | Trạng thái: `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `SKIPPED`. |
| `attempt` | `integer`, mặc định `1` | Lần thử. |

: Cột nổi bật của bảng `merge_participant_run`

Cột khác: `exported_count` bigint; `imported_count` bigint; `verified_count` bigint; `conflict_count` bigint; `transfer_ref` v(64); `started_at` ts; `finished_at` ts; `error_code` v(16); `error_message` v(1000).

### 3.32. `merge_conflict`

::: dac-ta
**Mục đích.** EN-20-28 Xung đột sáp nhập (FR-20-049): mã danh mục, đường dẫn API, người dùng trùng giữa nguồn và đích; cán bộ nghiệp vụ chọn cách xử lý (`ConflictResolution`).

**FR phục vụ.** FR-20-049.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (plan_id, tenant_id) → `merge_plan` xóa theo, (participant_run_id, tenant_id) → `merge_participant_run`.

**Ràng buộc CHECK.** `ck_merge_conflict_` + `tenant`, `mapping_type`, `conflict_kind`, `state`, `resolution`, `resolved`.

**Chỉ mục.** `ix_merge_conflict_plan_state`, `ix_merge_conflict_fk_plan`, `ix_merge_conflict_fk_participant_run`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ vĩnh viễn.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_id` | `uuid` | Kế hoạch sáp nhập. |
| `participant_run_id` | `uuid`, null | Lần chuyển phát hiện xung đột. |
| `mapping_type` | `varchar(16)` | Loại đối tượng xung đột. |
| `conflict_kind` | `varchar(16)` | Dạng: `DUPLICATE_CODE`, `DUPLICATE_PATH`, `DUPLICATE_USER`, `OTHER`. |
| `state` | `varchar(10)`, mặc định `'OPEN'` | Trạng thái: `OPEN` hoặc `RESOLVED`. |

: Cột nổi bật của bảng `merge_conflict`

Cột khác: `source_ref` v(255); `target_ref` v(255); `resolution` v(16); `resolved_by` v(64); `resolved_at` ts; `resolution_note` v(1000).

### 3.33. `org_import_job`

::: dac-ta
**Mục đích.** EN-20-30 Lô nhập tổ chức (FR-20-055): tệp Excel hoặc CSV, xem trước kết quả kiểm tra rồi mới áp dụng; số dòng tối đa `20.org.import-max-rows` kiểm ở dịch vụ; bản xem trước hết hạn.

**FR phục vụ.** FR-20-055.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id) → `tenant`, (file_id, tenant_id) → `file_object`, (error_file_id, tenant_id) → `file_object`.

**Ràng buộc CHECK.** `ck_org_import_job_` + `tenant`, `status`, `mode`, `format`, `rows`, `done`.

**Chỉ mục.** `ix_org_import_job_status`, `ix_org_import_job_fk_file`, `ix_org_import_job_fk_error_file`.

**Cách ly tenant.** Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ 12 tháng; tệp nhập dọn sau 90 ngày.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `file_id` | `uuid` | Tệp nhập ở `file_object`. |
| `format` | `varchar(4)` | Định dạng tệp: `XLSX` hoặc `CSV`. |
| `mode` | `varchar(12)`, mặc định `'CREATE_ONLY'` | Chế độ: `CREATE_ONLY` (chỉ thêm mới) hoặc `UPSERT` (thêm hoặc cập nhật). |
| `status` | `varchar(10)`, mặc định `'UPLOADED'` | Trạng thái: `UPLOADED`, `PREVIEWED`, `APPLYING`, `DONE`, `FAILED`, `CANCELLED`. |
| `total_rows` | `integer`, mặc định `0` | Tổng số dòng dữ liệu. |

: Cột nổi bật của bảng `org_import_job`

Cột khác: `valid_rows` int; `error_rows` int; `applied_rows` int; `preview_expires_at` ts; `applied_at` ts; `error_file_id` uuid; `error_message` v(1000).

### 3.34. `org_import_row`

::: dac-ta
**Mục đích.** EN-20-30 Dòng của lô nhập tổ chức (FR-20-055): nội dung từng dòng, hành động dự kiến và lỗi kiểm tra; dòng lỗi không được áp dụng.

**FR phục vụ.** FR-20-055.

**Khóa chính.** (id).

**Duy nhất.** `uq_org_import_row_row` (job_id, row_no).

**Khóa ngoại.** (tenant_id) → `tenant`, (job_id, tenant_id) → `org_import_job` xóa theo.

**Ràng buộc CHECK.** `ck_org_import_row_` + `tenant`, `action`, `status`, `row`, `errors`, `error_action`.

**Chỉ mục.** `ix_org_import_row_fk_job`.

**Cách ly tenant.** Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ 90 ngày cùng lô nhập.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `job_id` | `uuid` | Lô nhập. |
| `row_no` | `integer` | Số thứ tự dòng trong tệp, bắt đầu từ 1. |
| `action` | `varchar(8)`, mặc định `'SKIP'` | Hành động: `CREATE`, `UPDATE`, `SKIP`, `ERROR`. |
| `status` | `varchar(8)`, mặc định `'VALID'` | Trạng thái: `VALID`, `ERROR`, `APPLIED`, `SKIPPED`. |

: Cột nổi bật của bảng `org_import_row`

Cột khác: `org_code` v(64); `errors` jsonb; `data` jsonb.

### 3.35. `product_release`

::: dac-ta
**Mục đích.** EN-20-31 Phiên bản sản phẩm (FR-20-059, 060): danh mục phiên bản Datahub với ghi chú phát hành, qua `PREVIEW` rồi `STABLE` (ADR 203). Dữ liệu nền tảng, mọi tenant đọc được để xem phiên bản và ghi chú (FR-20-064).

**FR phục vụ.** FR-20-059, 060, FR-20-063, 064.

**Khóa chính.** (id).

**Duy nhất.** `uq_product_release_version` (version_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_product_release_` + `tenant`, `status`, `version`, `preview`, `stable`, `withdrawn`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu PLATR: như PLAT, thêm `platform_data_read` cho phép mọi tenant đọc (`tenant_id = 'PLATFORM'`); chỉ phiên PLATFORM ghi.

**Phân vùng, bất biến.** Máy trạng thái `status` (`tg_product_release_transition`); Bất biến cột `version_code` (`tg_product_release_immutable`).

**Lưu giữ, ghi chú.** Giữ vĩnh viễn.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `version_code` | `varchar(32)` | Số phiên bản, dạng `1.0.0` hoặc `1.1.0-rc.1`. |
| `status` | `varchar(12)`, mặc định `'DRAFT'` | Trạng thái: `DRAFT`, `PREVIEW`, `STABLE`, `DEPRECATED`, `WITHDRAWN`. |
| `preview_at` | `timestamptz`, null | Thời điểm sang kênh `PREVIEW`. |
| `stable_at` | `timestamptz`, null | Thời điểm sang kênh `STABLE` (sau thời gian chạy thử, `20.release.stable-soak-days`). |
| `withdrawn_at` | `timestamptz`, null | Thời điểm rút bản. |

: Cột nổi bật của bảng `product_release`

Cột khác: `name` v(255); `release_notes` text; `breaking_change` bool; `min_from_version` v(32); `deprecated_at` ts; `withdrawn_reason` v(1000).

### 3.36. `release_component`

::: dac-ta
**Mục đích.** EN-20-31 Thành phần của phiên bản (FR-20-059): dịch vụ, giao diện, chart, schema CSDL, cấu hình thuộc một bản phát hành, kèm mã băm ảnh. Không chứa thông tin xác thực kho ảnh.

**FR phục vụ.** FR-20-059.

**Khóa chính.** (id).

**Duy nhất.** `uq_release_component_component` (release_id, component_code).

**Khóa ngoại.** (release_id, tenant_id) → `product_release` xóa theo.

**Ràng buộc CHECK.** `ck_release_component_` + `tenant`, `component_type`, `digest`.

**Chỉ mục.** `ix_release_component_fk_release`.

**Cách ly tenant.** Mẫu PLATR: như PLAT, thêm `platform_data_read` cho phép mọi tenant đọc (`tenant_id = 'PLATFORM'`); chỉ phiên PLATFORM ghi.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Theo phiên bản sản phẩm.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `release_id` | `uuid` | Phiên bản sản phẩm. |
| `component_code` | `varchar(64)` | Mã thành phần, ví dụ `dh-platform`, `dh-console`, `ph20_tenant`. |
| `component_type` | `varchar(10)` | Loại: `SERVICE`, `CONSOLE`, `CHART`, `SCHEMA`, `CONFIG`. |
| `digest` | `varchar(71)`, null | Mã băm ảnh `sha256:...`. |

: Cột nổi bật của bảng `release_component`

Cột khác: `image_ref` v(255); `chart_version` v(32); `migration_required` bool.

### 3.37. `tenant_release_subscription`

::: dac-ta
**Mục đích.** EN-20-32 Đăng ký kênh phát hành của tenant (FR-20-060): tenant theo kênh `STABLE` hoặc `PREVIEW`, có thể ghim phiên bản, đánh dấu tenant thí điểm nhận bản trước (ADR 203). Một dòng mỗi tenant.

**FR phục vụ.** FR-20-060.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_release_subscription_tenant` (tenant_id).

**Khóa ngoại.** (tenant_id) → `tenant`, (pinned_release_id) → `product_release`, (current_release_id) → `product_release`.

**Ràng buộc CHECK.** `ck_tenant_release_subscription_` + `tenant`, `channel`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `channel` | `varchar(8)`, mặc định `'STABLE'` | Kênh: `STABLE` hoặc `PREVIEW`. |
| `pinned_release_id` | `uuid`, null | Phiên bản được ghim (không tự nâng cấp lên bản mới hơn). |
| `current_release_id` | `uuid`, null | Phiên bản đang chạy của tenant. |
| `is_pilot` | `boolean`, mặc định `false` | Tenant thí điểm, nhận bản `PREVIEW` và là nơi chạy thử đủ thời gian trước khi sang `STABLE`. |

: Cột nổi bật của bảng `tenant_release_subscription`

Cột khác: `subscribed_at` ts.

### 3.38. `maintenance_window`

::: dac-ta
**Mục đích.** EN-20-33 Cửa sổ bảo trì của tenant (FR-20-061, 063, 064): khung giờ định kỳ hoặc một lần mà nâng cấp được phép chạy; tỉnh tự khai báo, kế hoạch nâng cấp tôn trọng cửa sổ.

**FR phục vụ.** FR-20-061, FR-20-063, 064.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id) → `tenant`.

**Ràng buộc CHECK.** `ck_maintenance_window_` + `tenant`, `window_type`, `duration`, `day`, `recurring`, `one_off`.

**Chỉ mục.** `ix_maintenance_window_enabled`.

**Cách ly tenant.** Mẫu OWN: `tenant_isolation` (FOR ALL, `tenant_id = current_setting('app.tenant_id', false)`); phiên PLATFORM chỉ đọc qua `platform_read` cho `ph20_platform_app`, `ph20_ro`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ trọn đời tenant.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `window_type` | `varchar(10)`, mặc định `'RECURRING'` | Loại: `RECURRING` (hằng tuần) hoặc `ONE_OFF` (một lần). |
| `day_of_week` | `smallint`, null | Thứ trong tuần theo ISO, 1 là thứ Hai (cửa sổ `RECURRING`). |
| `start_time` | `time`, null | Giờ bắt đầu theo múi giờ của cửa sổ (cửa sổ `RECURRING`). |
| `duration_minutes` | `integer`, mặc định `240` | Thời lượng, phút, từ 120 đến 360 (2…6 giờ, FR-20-018). |
| `starts_at` | `timestamptz`, null | Bắt đầu (cửa sổ `ONE_OFF`). |

: Cột nổi bật của bảng `maintenance_window`

Cột khác: `name` v(255); `ends_at` ts; `timezone` v(40); `enabled` bool; `note` v(500).

### 3.39. `upgrade_plan`

::: dac-ta
**Mục đích.** EN-20-34 Kế hoạch nâng cấp theo sóng (FR-20-061, 062): đưa một phiên bản lên các tenant theo từng sóng; tự dừng khi tỷ lệ lỗi vượt `error_threshold_percent` (`20.release.wave-error-threshold-percent`).

**FR phục vụ.** FR-20-061, 062.

**Khóa chính.** (id).

**Duy nhất.** `uq_upgrade_plan_code` (plan_code).

**Khóa ngoại.** (release_id, tenant_id) → `product_release`.

**Ràng buộc CHECK.** `ck_upgrade_plan_` + `tenant`, `status`, `channel`, `code`, `threshold`, `running`.

**Chỉ mục.** `ix_upgrade_plan_status`, `ix_upgrade_plan_fk_release`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Bất biến cột `plan_code`, `release_id` (`tg_upgrade_plan_immutable`).

**Lưu giữ, ghi chú.** Giữ vĩnh viễn.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_code` | `varchar(48)` | Mã kế hoạch, dạng `nang-cap-1-1-0`. |
| `release_id` | `uuid` | Phiên bản đích. |
| `channel` | `varchar(8)`, mặc định `'STABLE'` | Kênh áp dụng: `STABLE` hoặc `PREVIEW`. |
| `status` | `varchar(12)`, mặc định `'DRAFT'` | Trạng thái: `DRAFT`, `SCHEDULED`, `RUNNING`, `PAUSED`, `COMPLETED`, `ROLLED_BACK`, `CANCELLED`. |
| `error_threshold_percent` | `numeric(5,2)`, mặc định `2` | Ngưỡng lỗi dừng sóng, phần trăm. |

: Cột nổi bật của bảng `upgrade_plan`

Cột khác: `scheduled_at` ts; `started_at` ts; `completed_at` ts; `pause_reason` v(1000); `ticket_code` v(32).

### 3.40. `upgrade_wave`

::: dac-ta
**Mục đích.** EN-20-34 Sóng nâng cấp (FR-20-061, 062): nhóm tenant nâng cấp cùng lúc, thường sóng 1 là tenant thí điểm; dừng sóng tự động khi vượt ngưỡng lỗi.

**FR phục vụ.** FR-20-061, 062.

**Khóa chính.** (id).

**Duy nhất.** `uq_upgrade_wave_wave` (plan_id, wave_no).

**Khóa ngoại.** (plan_id, tenant_id) → `upgrade_plan` xóa theo.

**Ràng buộc CHECK.** `ck_upgrade_wave_` + `tenant`, `status`, `wave`, `selector`, `count`, `error`.

**Chỉ mục.** `ix_upgrade_wave_fk_plan`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Theo kế hoạch.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_id` | `uuid` | Kế hoạch nâng cấp. |
| `wave_no` | `smallint` | Số thứ tự sóng, bắt đầu từ 1. |
| `status` | `varchar(10)`, mặc định `'PENDING'` | Trạng thái: `PENDING`, `RUNNING`, `PAUSED`, `DONE`, `STOPPED`. |
| `tenant_count` | `integer`, mặc định `0` | Số tenant trong sóng. |
| `error_percent` | `numeric(5,2)`, null | Tỷ lệ lỗi hiện tại của sóng. |

: Cột nổi bật của bảng `upgrade_wave`

Cột khác: `name` v(255); `tenant_selector` jsonb; `planned_start` ts; `started_at` ts; `finished_at` ts.

### 3.41. `tenant_upgrade`

::: dac-ta
**Mục đích.** EN-20-35 Nâng cấp theo tenant (FR-20-062, 064): trạng thái nâng cấp của từng tenant trong một sóng, gắn cửa sổ bảo trì; mỗi đổi trạng thái phát EVT-20-15.

**FR phục vụ.** FR-20-062, FR-20-064.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_upgrade_wave` (wave_id, tenant_id).

**Khóa ngoại.** (tenant_id) → `tenant`, (plan_id) → `upgrade_plan`, (wave_id) → `upgrade_wave`, (release_id) → `product_release`, (maintenance_window_id, tenant_id) → `maintenance_window`, (rollback_release_id) → `product_release`.

**Ràng buộc CHECK.** `ck_tenant_upgrade_` + `tenant`, `status`, `attempt`, `done`, `rollback`.

**Chỉ mục.** `ix_tenant_upgrade_tenant_status`, `ix_tenant_upgrade_plan`, `ix_tenant_upgrade_fk_window`.

**Cách ly tenant.** Mẫu CTL: tenant chỉ đọc dòng của mình (`tenant_isolation` FOR SELECT); chỉ phiên PLATFORM của `ph20_platform_app` ghi (`platform_write`); `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ vĩnh viễn (lịch sử nâng cấp từng tỉnh).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `plan_id` | `uuid` | Kế hoạch nâng cấp. |
| `wave_id` | `uuid` | Sóng chứa tenant. |
| `release_id` | `uuid` | Phiên bản đích. |
| `status` | `varchar(12)`, mặc định `'PENDING'` | Trạng thái: `PENDING`, `IN_WINDOW`, `UPGRADING`, `VERIFYING`, `DONE`, `FAILED`, `ROLLED_BACK`, `SKIPPED`. |
| `maintenance_window_id` | `uuid`, null | Cửa sổ bảo trì được dùng. |

: Cột nổi bật của bảng `tenant_upgrade`

Cột khác: `scheduled_for` ts; `started_at` ts; `verified_at` ts; `finished_at` ts; `attempt` int; `rollback_release_id` uuid; `error_code` v(16); `error_message` v(1000).

### 3.42. `leak_test_run`

::: dac-ta
**Mục đích.** EN-20-36 Lần kiểm thử rò rỉ chéo tenant (FR-20-070, SEC-87): chạy hằng đêm hoặc trước khi kích hoạt tenant mới; ghi số ca, số ca lỗi, danh sách lỗi. Ca lỗi là sự cố an ninh mức cao.

**FR phục vụ.** FR-20-067, FR-20-070.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (report_file_id, tenant_id) → `file_object`.

**Ràng buộc CHECK.** `ck_leak_test_run_` + `tenant`, `trigger_type`, `status`, `counts`, `failures`, `passed`, `finished`.

**Chỉ mục.** `ix_leak_test_run_started`, `ix_leak_test_run_fk_report_file`.

**Cách ly tenant.** Mẫu PLAT: dữ liệu nền tảng, `tenant_isolation` chỉ khớp phiên `PLATFORM` (`tenant_id = 'PLATFORM'`); tenant không thấy.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Giữ 24 tháng (bằng chứng SEC-87).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `trigger_type` | `varchar(14)`, mặc định `'SCHEDULE'` | Nguồn kích hoạt: `SCHEDULE`, `MANUAL`, `PRE_ACTIVATION`. |
| `status` | `varchar(8)`, mặc định `'RUNNING'` | Trạng thái: `RUNNING`, `PASSED`, `FAILED`, `ERROR`. |
| `tenants_tested` | `integer`, mặc định `0` | Số tenant đã kiểm. |
| `cases_total` | `integer`, mặc định `0` | Tổng số ca. |
| `cases_failed` | `integer`, mặc định `0` | Số ca phát hiện rò rỉ. |

: Cột nổi bật của bảng `leak_test_run`

Cột khác: `tenant_codes` text[]; `failures` jsonb; `report_file_id` uuid; `started_at` ts; `finished_at` ts.

### 3.43. `outbox`

::: dac-ta
**Mục đích.** Hạ tầng, DD-11 Outbox (SAD 7.3) cho EVT-20-01…16 và bản ghi kiểm toán gửi PH-13: ghi cùng giao dịch với thay đổi, Debezium Outbox Event Router đọc WAL và phát Kafka. Sự kiện vòng đời đi trên `platform.*`, sự kiện tổ chức trên `{tenant}.tenant.org.changed.v1`. Dọn sau 3 ngày.

**FR phục vụ.** FR-20-013, FR-20-020, FR-20-044, FR-20-063, FR-20-068.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_` + `tenant`, `topic`, `trace`, `payload`.

**Chỉ mục.** `ix_outbox_occurred`, `ix_outbox_unpublished`.

**Cách ly tenant.** Mẫu TECH: `tenant_isolation` (FOR ALL) cho tenant ghi cùng giao dịch; `platform_write` cho PLATFORM; `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Dọn sau 3 ngày kể từ `published_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `event_id` | `uuid` | Mã sự kiện, thành `id` của CloudEvent; bên nhận dùng để chống trùng. |
| `event_type` | `varchar(128)` | Kiểu sự kiện, ví dụ `vn.datahub.platform.tenant.created.v1`. |
| `topic` | `varchar(128)` | Topic Kafka theo D00-01 §6. |
| `aggregate_type` | `varchar(32)` | Loại thực thể gốc (`tenant`, `organization`, `merge_plan`…). |
| `aggregate_id` | `uuid` | Thực thể gốc, làm khóa phân vùng Kafka. |

: Cột nổi bật của bảng `outbox`

Cột khác: `payload` jsonb; `trace_id` char(32); `occurred_at` ts; `published_at` ts.

### 3.44. `inbox_event`

::: dac-ta
**Mục đích.** Hạ tầng. Hộp nhận sự kiện từ phân hệ khác (EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11): khử trùng theo `(tenant_id, consumer, event_id)` để tiêu thụ lũy đẳng.

**FR phục vụ.** FR-20-056.

**Khóa chính.** (tenant_id, consumer, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + `tenant`.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** Mẫu TECH: `tenant_isolation` (FOR ALL) cho tenant ghi cùng giao dịch; `platform_write` cho PLATFORM; `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Dọn sau 14 ngày.
:::

Cột khác: `consumer` v(64); `event_id` uuid; `source_topic` v(128); `received_at` ts; `processed_at` ts.

### 3.45. `idempotency_key`

::: dac-ta
**Mục đích.** Hạ tầng. Kết quả yêu cầu ghi có tiêu đề `Idempotency-Key` (API công khai và saga: khóa `{runId}:{stepCode}`); giữ 24 giờ. Cột khóa tên `idempotency_ref` (tránh trùng tên cột nhạy cảm của công cụ quét).

**FR phục vụ.** FR-20-008.

**Khóa chính.** (tenant_id, client_id, request_method, request_path, idempotency_ref).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_idempotency_key_` + `tenant`, `ref`, `state`, `done`, `hash`.

**Chỉ mục.** `ix_idempotency_key_expiry`.

**Cách ly tenant.** Mẫu TECH: `tenant_isolation` (FOR ALL) cho tenant ghi cùng giao dịch; `platform_write` cho PLATFORM; `ph20_ro` đọc qua `platform_read`.

**Phân vùng, bất biến.** Không.

**Lưu giữ, ghi chú.** Dọn sau 24 giờ kể từ `expires_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `idempotency_ref` | `varchar(128)` | Giá trị tiêu đề `Idempotency-Key`. |
| `request_hash` | `char(64)` | Băm nội dung yêu cầu, phát hiện cùng khóa khác nội dung. |
| `state` | `varchar(12)`, mặc định `'IN_PROGRESS'` | Trạng thái: `IN_PROGRESS` hoặc `COMPLETED`. |
| `response_status` | `smallint`, null | Mã HTTP đã trả. |

: Cột nổi bật của bảng `idempotency_key`

Cột khác: `client_id` v(255); `request_method` v(8); `request_path` v(512); `resource_id` uuid; `response_body` jsonb; `completed_at` ts; `expires_at` ts.

<!-- gen:tables:end -->

## 4. Cô lập tenant và RLS

Chương này giải thích cách schema bảo đảm một tỉnh không đọc, không ghi dữ liệu của tỉnh khác, và cách phiên nền tảng được phép nhìn xuyên tenant mà vẫn không dùng `BYPASSRLS`. Cách ly CSDL là một trong mười hai tầng cách ly của D03-10 §4 và là tầng duy nhất do chính PH-20 vừa cung cấp vừa chịu.

### 4.1. Nguyên tắc

Mọi bảng bật `ENABLE ROW LEVEL SECURITY` và `FORCE ROW LEVEL SECURITY` (cả chủ bảng chịu chính sách) qua thủ tục `ph20_tenant.p_enable_rls(bảng, chế độ)`; mọi bảng có chính sách tên `tenant_isolation` theo mẫu D03-10 §4: điều kiện `tenant_id = current_setting('app.tenant_id', false)`. Tham số `false` làm truy vấn lỗi (SQLSTATE `42704`) thay vì trả rỗng khi quên đặt biến phiên; bài kiểm 13 chạy ở kết nối mới để chứng minh điều này cho cả vai `ph20_app` và `ph20_platform_app`. Biến phiên đặt đầu mỗi giao dịch từ ngữ cảnh xác thực (JWT, `SET LOCAL`), không bao giờ từ tham số của bên gọi.

### 4.2. Năm chế độ

Chế độ RLS gắn với bảng theo bên ghi dữ liệu, không theo nhóm chức năng. Bảng dưới nêu chính sách tạo ra và bài kiểm tương ứng.

| Chế độ | Bảng | Chính sách | Ý nghĩa |
|---|---|---|---|
| OWN | `organization`, `tenant_settings`, `cross_tenant_policy`, `maintenance_window`, `org_import_job`, `org_import_row` | `tenant_isolation` (FOR ALL, USING và WITH CHECK); `platform_read` (SELECT cho `ph20_platform_app`, `ph20_owner`, `ph20_ro`, khi phiên PLATFORM) | Tỉnh tự ghi dữ liệu của mình; nền tảng chỉ đọc, muốn sửa phải vào phiên của tỉnh có lý do và mã phiếu (SEC-85) |
| CTL | `tenant_contact`, `tenant_contract`, `tenant_platform_config`, `tenant_config_version`, `config_drift`, `provisioning_run`, `provisioning_step`, `smoke_test_result`, `tenant_quota`, `quota_change_request`, `quota_override`, `usage_snapshot`, `quota_alert`, `usage_report`, `tenant_module`, `tenant_feature_flag`, `lifecycle_request`, `tenant_status_history`, `data_export_package`, `data_export_item`, `tenant_release_subscription`, `tenant_upgrade` | `tenant_isolation` (chỉ FOR SELECT); `platform_write` (FOR ALL cho `ph20_platform_app`, `ph20_owner`, khi phiên PLATFORM); `platform_read` (SELECT cho `ph20_ro`) | Dữ liệu điều khiển về tenant: tenant chỉ đọc dòng của mình, chỉ nền tảng ghi (tỉnh không tự đổi hạn mức, phân hệ) |
| TECH | `outbox`, `inbox_event`, `idempotency_key`, `file_object` | `tenant_isolation` (FOR ALL); `platform_write`; `platform_read` | Cả hai bên ghi cùng giao dịch với thay đổi; PLATFORM ghi được dòng mang `tenant_id` của tỉnh bị tác động |
| PLAT | `provisioning_template`, `merge_plan` (thêm `merge_party_read`), `merge_mapping`, `merge_participant_run`, `merge_conflict`, `upgrade_plan`, `upgrade_wave`, `leak_test_run` | `tenant_isolation` chỉ khớp `tenant_id = 'PLATFORM'` | Dữ liệu nền tảng; tenant không thấy |
| PLATR | `platform_module`, `module_dependency`, `product_release`, `release_component` | PLAT cộng `platform_data_read` (SELECT khi `tenant_id = 'PLATFORM'`, cho mọi vai) | Danh mục mọi tenant được đọc để dựng menu và xem ghi chú phát hành; chỉ PLATFORM ghi |

: Chế độ RLS và chính sách của `ph20_tenant`

Ngoài năm chế độ trên, bảng `tenant` có bộ chính sách riêng (mục 4.3). Bảng `merge_plan` có chính sách `merge_party_read` cho phép tenant nguồn và tenant đích đọc kế hoạch của mình (UI-20-10: quản trị tỉnh của hai bên chỉ xem phần tỉnh mình); chi tiết ánh xạ, lần chuyển, xung đột chỉ qua API nền tảng.

Sơ đồ dưới tóm tắt ba bể kết nối, vai và chính sách mà mỗi bể thấy; tất cả cùng đi qua RLS, không có đường vòng.

```{.mermaid caption="Ba bể kết nối, vai CSDL và chính sách RLS của PH-20"}
flowchart TB
  A["API tỉnh /api/tenant/v1<br/>vai ph20_app"] -->|"app.tenant_id = Tnn"| P1["tenant_isolation:<br/>chỉ dòng của tỉnh"]
  B["API nền tảng, nội bộ, saga<br/>vai ph20_platform_app"] -->|"app.tenant_id = PLATFORM"| P2["platform_write, platform_read:<br/>ghi bảng điều khiển, đọc mọi tenant"]
  B -->|"app.tenant_id = Tnn"| P1
  C["Kiểm toán, BI<br/>vai ph20_ro"] -->|"app.tenant_id = PLATFORM"| P3["platform_read:<br/>chỉ SELECT mọi tenant"]
  P1 --> D[("Bảng ph20_tenant<br/>FORCE RLS, không BYPASSRLS")]
  P2 --> D
  P3 --> D
```

Hình cho thấy vai kết nối quyết định chính sách được áp dụng, còn giá trị `app.tenant_id` quyết định dòng nào hiện ra. Bể `ph20_app` không bao giờ nhận được chính sách `platform_*` nên dù mã gọi đặt phiên `PLATFORM` cũng chỉ thấy dòng `PLATFORM` (bài kiểm 1 và 2). Vai nền tảng với phiên `Tnn` hành xử như một tenant thường, nên cùng bể dùng được cho thao tác thay mặt tỉnh có ghi kiểm toán.

### 4.3. Đặc thù bảng tenant

Bảng `tenant` không có `tenant_id`, nên không thể dùng mẫu chuẩn. Bộ chính sách riêng gồm năm chính sách, FORCE RLS vẫn bật.

| Chính sách | Thao tác | Vai | Điều kiện |
|---|---|---|---|
| `tenant_isolation` | SELECT | mọi vai | `code = current_setting('app.tenant_id', false)` |
| `platform_read` | SELECT | `ph20_platform_app`, `ph20_owner`, `ph20_ro` | `current_setting('app.tenant_id', false) = 'PLATFORM'` |
| `platform_insert` | INSERT | `ph20_platform_app`, `ph20_owner` | phiên là `PLATFORM` |
| `platform_update` | UPDATE | `ph20_platform_app`, `ph20_owner` | phiên là `PLATFORM` (USING và WITH CHECK) |
| `platform_delete` | DELETE | `ph20_platform_app`, `ph20_owner` | phiên là `PLATFORM`; quyền `DELETE` bị thu và trigger `tg_tenant_no_delete` chặn kể cả chủ schema |

: Chính sách RLS của bảng tenant

Kết quả: tenant `T90` chỉ thấy đúng một dòng (chính mình); vai `ph20_app` giả phiên `PLATFORM` chỉ thấy dòng `PLATFORM`; vai nền tảng với phiên `PLATFORM` thấy mọi dòng; chỉ vai nền tảng với phiên `PLATFORM` thêm, sửa được. Registry cho phân hệ khác (FR-20-065) đọc bảng này bằng bể nền tảng và trả về trạng thái, host, realm, không lộ dữ liệu thừa. Cột `status` đổi theo máy trạng thái (mục 2.6); `code`, `kind` bất biến; bảo vệ `PLATFORM`, `COMMON` (FR-20-006) bằng `ck_tenant_special`, trigger chặn xóa và chặn đổi trạng thái.

### 4.4. Dữ liệu nền tảng

Bảng dữ liệu nền tảng mang `tenant_id = 'PLATFORM'` (CHECK `ck_*_tenant`), nên chính sách `tenant_isolation` chỉ khớp phiên `PLATFORM`; tenant tỉnh không thấy mẫu khởi tạo, kế hoạch nâng cấp, kết quả kiểm thử rò rỉ. Bốn bảng PLATR (danh mục phân hệ, phụ thuộc, phiên bản sản phẩm, thành phần) thêm quyền đọc cho mọi tenant, theo cách `COMMON` được đọc ở các phân hệ khác nhưng không dùng giá trị `COMMON`: PH-20 dành `COMMON` cho dữ liệu danh mục quốc gia do PH-07 giữ, còn dữ liệu của chính nền tảng mang `PLATFORM` để không lẫn.

Lưu ý một khác biệt so với PH-07, PH-08, PH-16: ghi dữ liệu nền tảng chỉ được phép khi phiên là `PLATFORM`, nhưng ngay cả khi vai `ph20_app` đặt phiên `PLATFORM`, quyền `INSERT`, `UPDATE`, `DELETE` trên các bảng này đã bị thu nên lỗi `42501` (bài kiểm 8).

### 4.5. Phiên PLATFORM và truy cập liên tenant

FR-00-012 cho phép vai nền tảng truy cập dữ liệu của tỉnh có điều kiện. Trong PH-20 cơ chế gồm hai tầng. Tầng CSDL: vai riêng `ph20_platform_app`, chỉ dùng trong nhóm `/api/platform/` và `/internal/`, đặt `app.tenant_id = 'PLATFORM'` để đọc liên tenant theo bảng OWN và đọc, ghi theo bảng CTL; vẫn không `BYPASSRLS`. Tầng ứng dụng: PH-12 cấp quyền liên tenant có thời hạn (`20.cross-tenant.max-hours`, tối đa 4 giờ theo BR-12-032), đọc `cross_tenant_policy` của tỉnh (có cho phép ghi không, chấp thuận trước, người nhận thông báo), ghi lý do và mã phiếu vào chuỗi kiểm toán của tỉnh bị tác động (SEC-85). Muốn sửa dữ liệu tenant tự quản (OWN), phiên nền tảng chuyển sang `app.tenant_id = Tnn` của tỉnh đích, và việc đó chỉ được phép khi chính sách của tỉnh cho phép.

### 4.6. Quyền theo vai và tự kiểm khi khởi động

Ma trận dưới tóm tắt quyền `GRANT` của từng vai theo nhóm bảng; chính sách RLS nằm trên quyền này nên tạo thành hai lớp chặn.

| Nhóm bảng | `ph20_app` | `ph20_platform_app` | `ph20_ro` |
|---|---|---|---|
| OWN, TECH | SELECT, INSERT, UPDATE, DELETE (trừ bảng không xóa cứng như `organization`) | SELECT, INSERT, UPDATE, DELETE (trừ bảng không xóa cứng) | SELECT |
| CTL, PLAT, PLATR, `tenant` | SELECT | SELECT, INSERT, UPDATE (không DELETE) | SELECT |
| Bảng chỉ thêm (`tenant_status_history`, `smoke_test_result`) | SELECT | SELECT, INSERT | SELECT |
| Thủ tục `p_init_tenant_quota` | Không | EXECUTE | Không |
| Thủ tục `p_seed_platform`, `p_ensure_partitions` | Không | Không (chỉ `ph20_owner`) | Không |

: Quyền GRANT theo vai trò

Khi khởi động, `dh-platform` kiểm: vai kết nối không `BYPASSRLS`, không là chủ bảng; mọi bảng có `relforcerowsecurity`; mọi bảng có chính sách `tenant_isolation`. Khối tổng kiểm ở cuối bài kiểm cô lập chạy đúng các truy vấn này trên `pg_roles`, `pg_class`, `pg_policies`.

## 5. Phân vùng, lưu giữ, sao lưu và mã hóa

Chỉ một bảng phân vùng: `usage_snapshot`, vì là bảng duy nhất tăng đều không giới hạn. Phần còn lại là cấu hình, lịch sử hoặc hàng đợi kỹ thuật có khối lượng nhỏ. Bảng dưới nêu thời hạn lưu giữ và cách dọn từng nhóm dữ liệu; giá trị lấy từ tham số `20.*` (đăng ký với PH-18 ở `/van-hanh/tham-so`).

| Đối tượng | Lưu giữ mặc định | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph20_tenant` | Theo `pg-core`: WAL liên tục, base backup hằng ngày lên Ceph RGW, RPO ≤ 15 phút, RTO ≤ 30 phút (ADR-034) | Diễn tập DR theo D03-09; khôi phục `pg-core` sau OpenBao |
| `usage_snapshot` | 25 tháng, tham số `20.usage.retention-months` | `DETACH` rồi `DROP` phân vùng tháng dưới `ph20_owner`; ứng dụng không có quyền `DELETE` ở cấp bảng cha |
| `tenant`, `organization`, `lifecycle_request`, `merge_*`, `tenant_status_history`, `product_release` | Vĩnh viễn (hồ sơ pháp lý, bằng chứng bốn mắt) | `REVOKE DELETE`; chỉ đổi trạng thái hoặc thay thế |
| `tenant_contract`, `tenant_contact` | Theo hợp đồng cộng 10 năm; 5 năm | Không xóa cứng; dữ liệu cá nhân che khi xuất |
| `tenant_config_version` | 24 phiên bản gần nhất trong CSDL, cũ hơn ở lịch sử Git | Dọn theo lô dưới `ph20_owner`, giữ băm |
| `config_drift`, `quota_alert`, `leak_test_run` | 12 tháng, 24 tháng, 24 tháng | Dọn theo lô hằng tháng |
| `data_export_package` (tệp), `data_export_item` | Tệp 90 ngày kể từ lúc sẵn sàng (`20.export.retention-days`); dòng vĩnh viễn | Xóa tệp theo `expires_at`, đánh dấu `EXPIRED` |
| `usage_report`, `org_import_job`, `org_import_row`, `file_object` | Tệp theo `expires_at`; dòng 12 đến 24 tháng; dòng nhập 90 ngày | Xóa theo `expires_at`, `deleted_at` |
| `outbox`, `inbox_event`, `idempotency_key` | 3 ngày, 14 ngày, 24 giờ | Công việc dọn mỗi giờ |
| Kafka, OpenBao, Ceph RGW | Theo D03-09: bản sao 3; snapshot Raft hằng giờ; đối tượng bản sao hai site | |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Phân vùng.** `usage_snapshot` phân vùng RANGE theo tháng trên `captured_at` (`timestamptz`); biên là 00:00 giờ Việt Nam (UTC+7, không có giờ mùa hè). DDL tạo sẵn sáu phân vùng `usage_snapshot_202611`…`202704` và một phân vùng mặc định `usage_snapshot_default` hứng dữ liệu ngoài biên, để lỗi lịch của job không làm mất ảnh chụp. `PartitionMaintenanceJob` (PH-18) hằng ngày gọi `p_ensure_partitions('ph20_tenant.usage_snapshot', ngày, 3)` tạo trước ba tháng; thủ tục chạy lại không nhân bản. Dọn bằng `DETACH PARTITION` rồi `DROP` (bài kiểm 7). Phân vùng mặc định phải rỗng khi bình thường: cảnh báo nếu có dòng ở đó, và khi thêm phân vùng mới cho tháng đã có dòng ở phân vùng mặc định thì thủ tục báo lỗi, người vận hành chuyển dòng trước.

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). PH-20 không lưu bí mật: tham chiếu CSDL chuyên dụng, cụm riêng, ảnh bản phát hành chỉ là tên, không chuỗi kết nối hay thông tin xác thực của kho ảnh; khóa mã hóa theo tenant `dh-{tenant}-pii` (SEC-88) nằm ở OpenBao.

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau, rồi đối chiếu `tenant_platform_config` với kho Git `dh-tenant-config` bằng `config_drift`. Nếu CSDL cũ hơn Kafka thì nhận lại sự kiện (lũy đẳng nhờ `inbox_event` và `idempotency_key`).

## 6. DDL và changelog Liquibase

DDL là nguồn duy nhất, sinh từ `ph20/tools/sinh_ddl.py` (danh mục bảng khai báo một dòng một cột, kèm ghi chú tiếng Việt cho `COMMENT ON COLUMN`). Từ DDL sinh ra changelog Liquibase, các khối đặc tả ở chương 3 và bài đối chiếu liệt kê.

### 6.1. Tệp

[`ph20/ddl/ph20_tenant.sql`](ph20/ddl/ph20_tenant.sql) chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-04…19. Changelog [`ph20/liquibase/db.changelog-ph20.yaml`](ph20/liquibase/db.changelog-ph20.yaml) và 14 tệp `ph20/liquibase/changes/*.sql` (formatted SQL, tác giả `ph20`) sinh bằng [`gen_liquibase.py`](ph20/tools/gen_liquibase.py), không sửa tay.

| Tệp | Nội dung |
|---|---|
| `20-0000-bootstrap.sql` | Vai trò `ph20_owner`, `ph20_app`, `ph20_platform_app`, `ph20_ro`; schema; biến phiên |
| `20-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_no_delete`, `tg_frozen`, `tg_transition`, `tg_organization_cycle`, `p_enable_rls`, `p_ensure_partitions` |
| `20-0010-core.sql` | `file_object`, `provisioning_template`, `tenant`, `organization`, `tenant_contact`, `tenant_contract` |
| `20-0020-module.sql` | `platform_module`, `module_dependency`, `tenant_module`, `tenant_feature_flag` |
| `20-0030-config.sql` | `tenant_platform_config`, `tenant_settings`, `tenant_config_version`, `config_drift`, `cross_tenant_policy` |
| `20-0040-provision.sql` | `provisioning_run`, `provisioning_step`, `smoke_test_result` |
| `20-0050-quota.sql` | `tenant_quota`, `quota_change_request`, `quota_override`, `usage_snapshot` (cùng sáu phân vùng và phân vùng mặc định), `quota_alert`, `usage_report` |
| `20-0060-lifecycle.sql` | `lifecycle_request`, `tenant_status_history`, `data_export_package`, `data_export_item` |
| `20-0070-merge.sql` | `merge_plan`, `merge_mapping`, `merge_participant_run`, `merge_conflict` |
| `20-0075-orgimport.sql` | `org_import_job`, `org_import_row` |
| `20-0080-release.sql` | `product_release`, `release_component`, `tenant_release_subscription`, `maintenance_window`, `upgrade_plan`, `upgrade_wave`, `tenant_upgrade`, `leak_test_run` |
| `20-0085-ops.sql` | `outbox`, `inbox_event`, `idempotency_key` |
| `20-0090-seed.sql` | `p_seed_platform`, `p_init_tenant_quota`; nạp hai tenant đặc biệt, 20 phân hệ, phụ thuộc, mẫu `tinh-chuan` |
| `20-0900-grants.sql` | Quyền theo vai trò, `runAlways` |

: Tệp DDL và changelog Liquibase của PH-20

Thứ tự tệp theo thứ tự phụ thuộc khóa ngoại: `file_object` và `provisioning_template` đi trước `tenant`; `platform_module` đi trước `tenant_module`; `quota_change_request` đi trước `lifecycle_request`. Changeset `ph20-0002-session-tenant` (`runAlways`) đặt `app.tenant_id = 'PLATFORM'` cho phiên migration để seed qua RLS. Không có changeset di trú dữ liệu: hệ cũ không có chức năng tương ứng (mục 10.4).

### 6.2. Kết quả chạy thử

Chạy ngày 27/11/2026 trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, dữ liệu giả, tenant kiểm thử T90, T91, T92:

- DDL chạy không lỗi trên CSDL trống với `ON_ERROR_STOP`: 45 bảng gốc, 8 phân vùng của `usage_snapshot` (phân vùng mặc định và bảy phân vùng tháng sau khi bài kiểm tạo thêm, bài kiểm dọn một phân vùng), 112 chính sách RLS, 11 hàm và thủ tục.
- [`ph20_isolation_test.sql`](ph20/test/ph20_isolation_test.sql) đạt 236 khối PASS, chia 14 nhóm (mục 8).
- Ghép 14 tệp changelog sinh ra rồi chạy bằng psql theo thứ tự trên CSDL trống khác: không lỗi. Chưa chạy bằng Liquibase CLI (máy dựng tài liệu không có); CI chạy `liquibase update` trên Testcontainers.
- `python3 build/tools/chay_ddl.py`: bước `ddl`, `test`, `liquibase` của `ph20` đạt; bước `chung` (DDL và bài kiểm của 19 phân hệ trên một CSDL) đạt, không xung đột tên vai trò, schema.

### 6.3. Đối chiếu với FRS

Mọi liệt kê dạng chữ hoa nằm ở từ điển `ENUM` của `sinh_ddl.py`. Hai mươi ba liệt kê của FRS Phụ lục A (brief mục 5.1) được so từng tập giá trị: không lệch. Bảng dưới cho biết mỗi liệt kê dùng ở cột nào; liệt kê bổ sung do CSDL đặt thêm cho cột trạng thái phụ chưa có ở FRS (đề nghị đồng bộ 11.2).

<!-- gen:enum:start -->
| Liệt kê (FRS Phụ lục A) | Số giá trị | Cột dùng trong DDL |
|---|---|---|
| `TenantStatus` | 7 | `tenant.status`, `tenant_status_history.from_status`, `tenant_status_history.to_status` |
| `IsolationMode` | 3 | `provisioning_template.default_isolation_mode`, `tenant.isolation_mode`, `provisioning_run.isolation_mode` |
| `TenantKind` | 3 | `tenant.kind` |
| `ProvisioningRunStatus` | 8 | `provisioning_run.status` |
| `ProvisioningStepStatus` | 8 | `provisioning_step.status` |
| `RunKind` | 3 | `provisioning_run.run_kind` |
| `LifecycleRequestType` | 5 | `lifecycle_request.request_type` |
| `RequestStatus` | 7 | `quota_change_request.status`, `lifecycle_request.status` |
| `SuspendReason` | 5 | `lifecycle_request.suspend_reason` |
| `QuotaResource` | 12 | `tenant_quota.resource_code`, `quota_change_request.resource_code`, `quota_override.resource_code`, `usage_snapshot.resource_code`, `quota_alert.resource_code` |
| `QuotaAlertLevel` | 2 | `quota_alert.alert_level` |
| `ModuleState` | 6 | `tenant_module.state` |
| `MergeStatus` | 12 | `merge_plan.status` |
| `MergeMappingType` | 6 | `merge_mapping.mapping_type`, `merge_conflict.mapping_type` |
| `ConflictResolution` | 5 | `merge_conflict.resolution` |
| `OrgType` | 5 | `organization.org_type` |
| `OrgStatus` | 4 | `organization.status` |
| `ReleaseChannel` | 2 | `tenant_release_subscription.channel`, `upgrade_plan.channel` |
| `ReleaseStatus` | 5 | `product_release.status` |
| `UpgradePlanStatus` | 7 | `upgrade_plan.status` |
| `TenantUpgradeStatus` | 8 | `tenant_upgrade.status` |
| `ExportPackageStatus` | 6 | `data_export_package.status` |
| `DriftStatus` | 4 | `tenant_platform_config.drift_status`, `config_drift.status` |
| `TemplateState` | 3 | `provisioning_template.status` |
| `ContactRole` | 4 | `tenant_contact.contact_type` |
| `SmokeCheck` | 4 | `smoke_test_result.check_code` |
| `AlertState` | 3 | `quota_alert.state` |

: Đối chiếu liệt kê FRS với `CHECK ... IN (...)` của DDL (39 danh sách trùng đúng một liệt kê)

| Liệt kê bổ sung của CSDL | Giá trị |
|---|---|
| `ContractStatus` | `DRAFT`, `ACTIVE`, `EXPIRED`, `TERMINATED` |
| `ServiceLevel` | `STANDARD`, `PREMIUM` |
| `ModuleCatalogStatus` | `AVAILABLE`, `PLANNED`, `DEPRECATED` |
| `DependencyType` | `REQUIRED`, `OPTIONAL` |
| `ConfigScope` | `PLATFORM_CONFIG`, `SETTINGS`, `QUOTA`, `MODULES`, `ALL` |
| `ChangeSource` | `API`, `SAGA`, `RESTORE`, `DRIFT_FIX` |
| `ApplyStatus` | `PENDING`, `APPLIED`, `FAILED` |
| `DriftResolution` | `RECONCILED`, `ACCEPTED`, `IGNORED` |
| `SmokeResult` | `PASS`, `FAIL`, `SKIPPED` |
| `OverrideStatus` | `ACTIVE`, `EXPIRED`, `REVOKED` |
| `UsageSource` | `MIMIR`, `APISIX`, `KAFKA`, `OBJECT_STORE`, `DATABASE`, `IAM`, `CATALOG`, `RUNTIME`, `OTHER` |
| `PushStatus` | `PENDING`, `PUSHED`, `FAILED` |
| `QuotaSource` | `TEMPLATE`, `CONTRACT`, `OVERRIDE` |
| `ReportStatus` | `REQUESTED`, `GENERATING`, `READY`, `FAILED`, `EXPIRED` |
| `ReportFormat` | `XLSX`, `CSV`, `PDF` |
| `ExportItemStatus` | `PENDING`, `COLLECTING`, `DONE`, `FAILED` |
| `ParticipantPhase` | `DRY_RUN`, `TRANSFER`, `IDENTITY`, `CUTOVER`, `VERIFY` |
| `ParticipantStatus` | `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `SKIPPED` |
| `MappingStatus` | `PROPOSED`, `CONFIRMED`, `CONFLICT`, `APPLIED` |
| `ConflictKind` | `DUPLICATE_CODE`, `DUPLICATE_PATH`, `DUPLICATE_USER`, `OTHER` |
| `ConflictState` | `OPEN`, `RESOLVED` |
| `ImportStatus` | `UPLOADED`, `PREVIEWED`, `APPLYING`, `DONE`, `FAILED`, `CANCELLED` |
| `ImportMode` | `CREATE_ONLY`, `UPSERT` |
| `ImportAction` | `CREATE`, `UPDATE`, `SKIP`, `ERROR` |
| `ImportRowStatus` | `VALID`, `ERROR`, `APPLIED`, `SKIPPED` |
| `ComponentType` | `SERVICE`, `CONSOLE`, `CHART`, `SCHEMA`, `CONFIG` |
| `WaveStatus` | `PENDING`, `RUNNING`, `PAUSED`, `DONE`, `STOPPED` |
| `WindowType` | `RECURRING`, `ONE_OFF` |
| `LeakTrigger` | `SCHEDULE`, `MANUAL`, `PRE_ACTIVATION` |
| `LeakStatus` | `RUNNING`, `PASSED`, `FAILED`, `ERROR` |
| `ScanStatus` | `PENDING`, `CLEAN`, `INFECTED` |
| `FilePurpose` | `CONTRACT`, `EXPORT_PACKAGE`, `ORG_IMPORT`, `USAGE_REPORT`, `LEAK_REPORT`, `LOGO`, `OTHER` |
| `IdemState` | `IN_PROGRESS`, `COMPLETED` |
| `ReportScope` | `TENANT`, `PLATFORM` |

: Liệt kê bổ sung do CSDL đặt thêm, không có ở FRS Phụ lục A (đề nghị đồng bộ 11.2)
<!-- gen:enum:end -->

## 7. Dữ liệu nền

Hai thủ tục khởi tạo, chạy lại không nhân bản. `p_seed_platform()` chạy một lần trong migration dưới phiên `PLATFORM` và nạp: hai tenant đặc biệt, danh mục 20 phân hệ, các phụ thuộc chính, một mẫu khởi tạo. `p_init_tenant_quota(tenant, người)` do saga gọi ở bước `S01_RECORD` để sao chép hạn mức mặc định của mẫu sang `tenant_quota`; bài kiểm 4 chứng minh 12 dòng và chạy lại không nhân bản.

**Hai tenant đặc biệt.** `PLATFORM` (`kind = PLATFORM`, realm `dh-platform`, thư mục cấu hình `tenants/PLATFORM/`) là tenant của control plane; `COMMON` (`kind = COMMON`) là tenant của dữ liệu dùng chung toàn quốc ở phân hệ khác. Cả hai `ACTIVE`, `SHARED`, không có đơn vị hành chính; bảo vệ bằng `ck_tenant_special` và trigger chặn xóa (FR-20-006).

**Danh mục phân hệ.** 20 phân hệ chia ba đợt theo D02-01 §8.3: 12 phân hệ MVP, 4 phân hệ đợt 2, 4 phân hệ đợt 3. Bốn phân hệ lõi (`PH-12`, `PH-13`, `PH-18`, `PH-20`) luôn bật, không tắt được cho tenant.

<!-- gen:modules:start -->
| Mã | Tên phân hệ | Đợt | Đơn vị triển khai | Lõi | Bật mặc định |
|---|---|---|---|---|---|
| `PH-01` | Kết nạp HTTT | 1 | `dh-connect` | không | có |
| `PH-02` | Danh mục dịch vụ | 1 | `dh-connect` | không | có |
| `PH-03` | Cổng API | 1 | `dh-connect` | không | có |
| `PH-04` | Lõi tích hợp và trình thiết kế luồng | 1 | `dh-integration` | không | có |
| `PH-05` | Bộ điều hợp | 1 | `dh-integration` | không | có |
| `PH-06` | Dữ liệu chủ | 3 | `dh-data` | không | không |
| `PH-07` | Danh mục dùng chung | 1 | `dh-data` | không | có |
| `PH-08` | Chất lượng dữ liệu | 3 | `dh-data` | không | không |
| `PH-09` | Quyền riêng tư | 2 | `dh-data` | không | không |
| `PH-10` | Sự kiện | 1 | `dh-integration` | không | có |
| `PH-11` | Quy trình liên thông | 2 | `dh-platform` | không | không |
| `PH-12` | Định danh và phân quyền | 1 | `dh-platform` | có | có |
| `PH-13` | Giám sát và kiểm toán | 1 | `dh-platform` | có | có |
| `PH-14` | Kết nối quốc gia | 1 | `dh-runtime` | không | có |
| `PH-15` | Cổng nhà phát triển | 2 | `dh-portal` | không | không |
| `PH-16` | Báo cáo chỉ tiêu | 3 | `dh-platform` | không | không |
| `PH-17` | Trợ lý AI | 3 | `dh-assist` | không | không |
| `PH-18` | Vận hành và xử lý lỗi | 1 | `dh-platform` | có | có |
| `PH-19` | Thanh toán | 2 | `dh-payment` | không | không |
| `PH-20` | Quản trị tenant và phát hành sản phẩm | 1 | `dh-platform` | có | có |

: Hai mươi phân hệ nạp vào `platform_module`
<!-- gen:modules:end -->

**Phụ thuộc chính.** Ma trận dưới là giả định có cơ sở từ mô tả phân hệ ở D03-01; FR-20-033 và SDD các phân hệ xác nhận (Q20-52). Dịch vụ dùng ma trận để chặn bật phân hệ thiếu phân hệ bắt buộc (ERR-20-103) và để sắp thứ tự bật ở bước `S15_MODULES`.

<!-- gen:deps:start -->
| Phân hệ | Phụ thuộc |
|---|---|
| `PH-01` | `PH-12` (bắt buộc), `PH-20` (bắt buộc) |
| `PH-02` | `PH-01` (bắt buộc) |
| `PH-03` | `PH-12` (bắt buộc), `PH-01` (bắt buộc), `PH-02` (bắt buộc) |
| `PH-04` | `PH-05` (bắt buộc), `PH-10` (bắt buộc), `PH-12` (bắt buộc) |
| `PH-05` | `PH-12` (bắt buộc) |
| `PH-06` | `PH-07` (bắt buộc), `PH-10` (tùy chọn) |
| `PH-07` | `PH-12` (bắt buộc) |
| `PH-08` | `PH-06` (bắt buộc), `PH-07` (tùy chọn) |
| `PH-09` | `PH-12` (bắt buộc), `PH-07` (tùy chọn) |
| `PH-10` | `PH-12` (bắt buộc) |
| `PH-11` | `PH-12` (bắt buộc), `PH-10` (tùy chọn) |
| `PH-12` | `PH-13` (bắt buộc) |
| `PH-13` | `PH-12` (bắt buộc) |
| `PH-14` | `PH-05` (bắt buộc), `PH-12` (bắt buộc) |
| `PH-15` | `PH-02` (bắt buộc), `PH-03` (bắt buộc) |
| `PH-16` | `PH-13` (tùy chọn) |
| `PH-17` | `PH-12` (bắt buộc), `PH-09` (tùy chọn) |
| `PH-18` | `PH-12` (bắt buộc), `PH-13` (bắt buộc) |
| `PH-19` | `PH-03` (bắt buộc), `PH-10` (bắt buộc), `PH-12` (bắt buộc) |
| `PH-20` | `PH-12` (bắt buộc), `PH-13` (bắt buộc), `PH-18` (tùy chọn) |

: Phụ thuộc chính giữa các phân hệ (37 dòng nạp vào `module_dependency`, giả định chờ FR-20-033)
<!-- gen:deps:end -->

**Mẫu khởi tạo `tinh-chuan`.** Mẫu cho tỉnh quy mô vừa theo GĐ-01 (khoảng 200 HTTT), chế độ cách ly `SHARED`, hồ sơ triển khai `HT-A`, bật mặc định 12 phân hệ MVP, cài đặt tỉnh mặc định (phiên rảnh 30 phút, bắt buộc MFA, `vi-VN`, múi giờ `Asia/Ho_Chi_Minh`) và sáu tổ chức cấp tỉnh mẫu nạp ở bước `S13_ORG_SEED` (UBND tỉnh và năm sở). Hạn mức mặc định gồm bảy giá trị của D03-10 §5.3 và năm giá trị bổ sung theo giả định.

<!-- gen:quota:start -->
| Tài nguyên | Mặc định | Cơ sở |
|---|---|---|
| `API_RPS` | 500 | D03-10 §5.3 (APISIX `limit-count`) |
| `ACTIVE_FLOWS` | 1.000 | D03-10 §5.3 (PH-04 khi phát hành) |
| `KAFKA_PRODUCE_MBPS` | 10 | D03-10 §5.3 (quota Kafka) |
| `KAFKA_CONSUME_MBPS` | 20 | D03-10 §5.3 (quota Kafka) |
| `OBJECT_STORAGE_GB` | 500 | D03-10 §5.3 (kiểm khi tải lên, cảnh báo 80%) |
| `DATABASE_GB` | 200 | D03-10 §5.3 (giám sát) |
| `USERS` | 2.000 | D03-10 §5.3 (PH-12) |
| `MEMBER_SYSTEMS` | 300 | Giả định (brief PH-20 mục 5.1) |
| `PUBLISHED_APIS` | 2.000 | Giả định (brief PH-20 mục 5.1) |
| `TOPICS` | 2.000 | Giả định (brief PH-20 mục 5.1) |
| `RUNTIME_CPU` | 16 | Giả định (brief PH-20 mục 5.1) |
| `RUNTIME_MEMORY_GB` | 64 | Giả định (brief PH-20 mục 5.1) |

: Mười hai hạn mức mặc định của mẫu `tinh-chuan`
<!-- gen:quota:end -->

Kế hoạch bước của mẫu liệt kê 17 bước saga; bước `S07_DATABASE` chỉ chạy với `DEDICATED_DB`, `S12_SEED_MDM` và `S14_KPI` chỉ chạy khi phân hệ tương ứng được bật.

<!-- gen:steps:start -->
| Thứ tự | Mã bước | Bên thực hiện | Bắt buộc theo mẫu |
|---|---|---|---|
| 1 | `S01_RECORD` | PH-20 | có |
| 2 | `S02_CONFIG_REPO` | PH-20 | có |
| 3 | `S03_REALM` | PH-12 | có |
| 4 | `S04_SECRETS` | PH-20 | có |
| 5 | `S05_BUCKETS` | PH-20 | có |
| 6 | `S06_EVENTING` | PH-10 | có |
| 7 | `S07_DATABASE` | PH-20 | tùy điều kiện (chế độ cách ly, phân hệ bật) |
| 8 | `S08_OBSERVABILITY` | PH-13 | có |
| 9 | `S09_GATEWAY` | PH-03 | có |
| 10 | `S10_INTEGRATION` | PH-04 | có |
| 11 | `S11_SEED_RDM` | PH-07 | có |
| 12 | `S12_SEED_MDM` | PH-06 | tùy điều kiện (chế độ cách ly, phân hệ bật) |
| 13 | `S13_ORG_SEED` | PH-20 | có |
| 14 | `S14_KPI` | PH-16 | tùy điều kiện (chế độ cách ly, phân hệ bật) |
| 15 | `S15_MODULES` | PH-20 | có |
| 16 | `S16_SMOKE` | PH-20 | có |
| 17 | `S17_ACTIVATE` | PH-20 | có |

: Kế hoạch 17 bước saga trong `step_plan` của mẫu `tinh-chuan`
<!-- gen:steps:end -->

Dữ liệu nền không chứa giá trị nhạy cảm; mã tenant của dữ liệu kiểm thử (`T90`, `T91`, `T92`) không được dùng ở môi trường thật.

## 8. Kiểm thử cô lập

Bài kiểm [`ph20_isolation_test.sql`](ph20/test/ph20_isolation_test.sql) chạy sau DDL trên CSDL rỗng, tạo ba tenant T90, T91, T92 và đặt `app.tenant_id` theo từng tình huống, bằng ba vai kiểm thử `dh_platform_app` (thành viên `ph20_app`), `dh_platform_ctl` (thành viên `ph20_platform_app`), `dh_report_ro` (thành viên `ph20_ro`). Mỗi khối kiểm một điều: lỗi mong đợi bị bắt và so với `SQLSTATE` đúng (23505 trùng khóa hoặc chỉ mục duy nhất, 23514 vi phạm `CHECK`, 23503 khóa ngoại, 42501 RLS hoặc thiếu quyền, 55000 trigger bất biến hoặc máy trạng thái, 42704 thiếu biến phiên); sai thì `RAISE` làm dừng tệp. Ba vai dùng chung tên với phân hệ khác (`dh_platform_app`, `dh_report_ro`) có khối `ELSE GRANT` để chạy chung một CSDL (bước `chung` của `chay_ddl.py`).

| Nhóm | Nội dung kiểm | Ca | Bảng chính |
|---|---|---|---|
| 0 | Dữ liệu nền sau DDL: hai tenant đặc biệt, 20 phân hệ, mẫu `tinh-chuan`, `p_seed_platform` chạy lại | 9 | `tenant`, `platform_module`, `provisioning_template` |
| 1 | Bảng `tenant`: PLATFORM thấy 5 dòng, vai `ph20_app` thấy 1; chỉ PLATFORM ghi; mã sai dạng, kind và mã lệch, thiếu ĐVHC hoặc realm, một ĐVHC hai tenant, máy trạng thái, mã bất biến, không xóa | 28 | `tenant` |
| 2 | Tổ chức: không thấy chéo, WITH CHECK chặn ghi chéo, khóa ngoại kép chặn cấp trên tenant khác, tự làm cấp trên, chu trình, `effective_to`, giải thể và kế thừa, trùng mã; vai PLATFORM đọc nhưng không ghi, vai `ph20_app` giả PLATFORM không thấy, vai chỉ đọc | 23 | `organization` |
| 3 | Bảng tenant tự quản: cài đặt, chính sách liên tenant, cửa sổ bảo trì, lô và dòng nhập, tệp; T91 không thấy dữ liệu T90 | 17 | `tenant_settings`, `cross_tenant_policy`, `maintenance_window`, `org_import_*`, `file_object` |
| 4 | Bản ghi điều khiển: đầu mối, hợp đồng, cấu hình, phân hệ, cờ, hạn mức từ mẫu, đề nghị đổi hạn mức bốn mắt, ghi đè hạn mức | 27 | `tenant_contact`, `tenant_quota`, `quota_change_request`, `quota_override` |
| 5 | Saga: một lần chạy đang hoạt động mỗi tenant, mã bước, khóa lũy đẳng, khóa ngoại kép, kiểm tra khói chỉ thêm, trạng thái cuối | 17 | `provisioning_run`, `provisioning_step`, `smoke_test_result` |
| 6 | Vòng đời: bốn mắt chấm dứt, đề nghị mở duy nhất, lịch sử chỉ thêm, gói bàn giao, phiên bản cấu hình bất biến, lệch cấu hình | 21 | `lifecycle_request`, `tenant_status_history`, `data_export_*`, `tenant_config_version`, `config_drift` |
| 7 | Sử dụng: ảnh chụp vào đúng phân vùng, phân vùng mặc định, `p_ensure_partitions`, `DETACH` và `DROP`, cảnh báo, báo cáo; tenant chỉ đọc bản ghi của mình | 25 | `usage_snapshot`, `quota_alert`, `usage_report` |
| 8 | Dữ liệu nền tảng: tenant đọc danh mục phân hệ nhưng không thấy mẫu, kế hoạch; không ghi; mẫu `PUBLISHED` bất biến | 15 | `platform_module`, `provisioning_template` |
| 9 | Sáp nhập: một kế hoạch mở mỗi tenant nguồn, bốn mắt, máy trạng thái, ánh xạ, xung đột; hai bên đọc kế hoạch, bên ngoài không thấy | 18 | `merge_*` |
| 10 | Phát hành: số phiên bản, máy trạng thái, thành phần, kênh, kế hoạch, sóng, nâng cấp theo tenant, kiểm thử rò rỉ; tenant đọc phiên bản | 23 | `product_release`, `upgrade_*`, `tenant_upgrade`, `leak_test_run` |
| 11 | Bảng kỹ thuật: tiền tố topic đúng tenant, topic ngoài danh sách, inbox khử trùng, khóa lũy đẳng; PLATFORM ghi outbox | 10 | `outbox`, `inbox_event`, `idempotency_key` |
| 12 | Tổng kiểm cấu trúc: vai không `BYPASSRLS`, không sở hữu bảng, mọi bảng FORCE RLS và có `tenant_isolation`, đủ cột ngữ cảnh, đúng 45 bảng | 1 | toàn schema |
| 13 | Thiếu biến phiên `app.tenant_id` (kết nối mới): truy vấn tổ chức, tenant, ghi outbox, vai nền tảng đều lỗi `42704` | 4 | `organization`, `tenant`, `outbox` |

: Các nhóm ca kiểm thử cô lập và ràng buộc

Bài kiểm đặt ba nhóm phép thử xuyên suốt: đọc chéo (tenant này không thấy dòng tenant kia, kể cả bằng vai nền tảng khi phiên đặt về tenant), ghi chéo (WITH CHECK và khóa ngoại kép chặn), và quyền theo vai (vai ứng dụng không đổi hạn mức, phân hệ, tenant). Chuyển sang quy trình kiểm thử chung, các nhóm này tương ứng nhóm TS cô lập của D05-02-PH20 (mã ca do tập test case cấp). Nhóm kiểm thử rò rỉ chéo tenant định kỳ (SEC-87, FR-20-070) ở mức hệ thống, ngoài CSDL, ghi lại ở `leak_test_run`.

## 9. Kho lưu trữ ngoài PostgreSQL

PH-20 dùng bốn kho ngoài PostgreSQL; CSDL chỉ giữ tham chiếu và bản chiếu, không giữ nội dung.

| Kho | Dùng cho | Quan hệ với CSDL |
|---|---|---|
| Kho Git `dh-tenant-config` | Cấu hình mong muốn của từng tenant ở `tenants/{ma-tenant}/`, Argo CD áp (ADR số 201) | `tenant_config_version` chiếu mỗi commit (`git_commit_sha`, `content_hash`, `snapshot`); `config_drift` ghi lệch |
| OpenBao | Đường dẫn `kv/dh/{tenant}/...`, chính sách, khóa `dh-{tenant}-pii` (SEC-88) | Không có cột nào lưu bí mật; `db_route_ref`, `cluster_ref` chỉ là tên tham chiếu |
| Ceph RGW | Bucket `dh-{tenant}-{mục đích}`: hợp đồng, gói bàn giao, tệp nhập tổ chức, báo cáo sử dụng, báo cáo rò rỉ | `file_object` giữ vị trí (`bucket`, `object_path`), `sha256`, `scan_status`; chỉ tệp `CLEAN` được xử lý |
| Kafka | Sự kiện vòng đời `platform.tenant.*.v1`, `platform.release.*.v1`; sự kiện tổ chức `{tenant}.tenant.org.changed.v1` | `outbox` (Debezium Outbox Event Router); `inbox_event` cho sự kiện nhận (EVT-07-10, EVT-12-13, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11) |
| Mimir | Nguồn số liệu sử dụng tài nguyên | `usage_snapshot` ghi ảnh chụp hằng giờ (ADR số 204) |
| Valkey | Bộ nhớ đệm registry tenant với khóa `{tenant}:` | Không lưu bền; hết hạn theo TTL ngắn |

: Kho lưu trữ ngoài PostgreSQL của PH-20

Sự kiện vòng đời đi trên tiền tố nền tảng `platform.` vì tenant mới chưa có tiền tố Kafka riêng; ràng buộc `ck_outbox_topic` chỉ chấp nhận 16 topic chuẩn (15 sự kiện EVT-20 vòng đời, phát hành, nâng cấp, bàn giao và `platform.obs.audit.recorded.v1` cho PH-13) hoặc `{tenant}.tenant.org.changed.v1` đúng tiền tố của tenant ghi. Hai tên lệch với phân hệ khác (`tenant.module-enabled.v1` ở PH-19, `dh.platform.tenant.created.v1` ở kiểm thử PH-10) ghi vào đề nghị đồng bộ.

## 10. Ánh xạ sang thiết kế mới

Chương này nối thực thể và chức năng của FRS với bảng và cột, để người rà truy vết tìm được nơi lưu của từng yêu cầu. Mã FR, EN có thể báo "chờ tài liệu gốc" ở công cụ kiểm mã khi FRS PH-20 chưa hoàn tất.

### 10.1. Thực thể EN-20 → bảng

Ba mươi bảy thực thể EN-20-01…37 của FRS hiện thực bằng 41 bảng (EN-20-24, 30, 31, 34 mỗi thực thể hai bảng); bốn bảng kỹ thuật còn lại không có EN.

<!-- gen:en:start -->
| EN | Thực thể | Bảng (DDL) | Chương |
|---|---|---|---|
| EN-20-01 | Tenant (DD-01) | `tenant` | 3.3 |
| EN-20-02 | Tổ chức (DD-02) | `organization` | 3.4 |
| EN-20-03 | Đầu mối tenant | `tenant_contact` | 3.5 |
| EN-20-04 | Hợp đồng dịch vụ | `tenant_contract` | 3.6 |
| EN-20-05 | Cấu hình nền tảng của tenant | `tenant_platform_config` | 3.11 |
| EN-20-06 | Cài đặt tỉnh | `tenant_settings` | 3.12 |
| EN-20-07 | Phiên bản cấu hình (bản chiếu commit Git) | `tenant_config_version` | 3.13 |
| EN-20-08 | Lệch cấu hình | `config_drift` | 3.14 |
| EN-20-09 | Mẫu khởi tạo | `provisioning_template` | 3.2 |
| EN-20-10 | Lần chạy saga | `provisioning_run` | 3.16 |
| EN-20-11 | Bước saga | `provisioning_step` | 3.17 |
| EN-20-12 | Kết quả kiểm tra khói | `smoke_test_result` | 3.18 |
| EN-20-13 | Hạn mức hợp đồng | `tenant_quota` | 3.19 |
| EN-20-14 | Đề nghị đổi hạn mức | `quota_change_request` | 3.20 |
| EN-20-15 | Ghi đè hạn mức tạm thời | `quota_override` | 3.21 |
| EN-20-16 | Ảnh chụp sử dụng tài nguyên | `usage_snapshot` | 3.22 |
| EN-20-17 | Cảnh báo hạn mức | `quota_alert` | 3.23 |
| EN-20-18 | Phân hệ của nền tảng | `platform_module`, `PLATFORM` | 3.7 |
| EN-20-19 | Phụ thuộc phân hệ | `module_dependency` | 3.8 |
| EN-20-20 | Phân hệ theo tenant | `tenant_module` | 3.9 |
| EN-20-21 | Cờ tính năng theo tenant | `tenant_feature_flag` | 3.10 |
| EN-20-22 | Đề nghị vòng đời có duyệt | `lifecycle_request` | 3.25 |
| EN-20-23 | Sự kiện vòng đời (lịch sử trạng thái) | `tenant_status_history` | 3.26 |
| EN-20-24 | Gói bàn giao dữ liệu | `data_export_package`, `data_export_item` | 3.27, 3.28 |
| EN-20-25 | Kế hoạch sáp nhập | `merge_plan` | 3.29 |
| EN-20-26 | Ánh xạ sáp nhập | `merge_mapping` | 3.30 |
| EN-20-27 | Lần chuyển theo phân hệ | `merge_participant_run` | 3.31 |
| EN-20-28 | Xung đột sáp nhập | `merge_conflict` | 3.32 |
| EN-20-29 | Chính sách tiếp nhận liên tenant | `cross_tenant_policy` | 3.15 |
| EN-20-30 | Lô nhập tổ chức | `org_import_job`, `org_import_row` | 3.33, 3.34 |
| EN-20-31 | Phiên bản sản phẩm | `product_release`, `release_component` | 3.35, 3.36 |
| EN-20-32 | Đăng ký kênh của tenant | `tenant_release_subscription` | 3.37 |
| EN-20-33 | Cửa sổ bảo trì | `maintenance_window` | 3.38 |
| EN-20-34 | Kế hoạch nâng cấp và sóng | `upgrade_plan`, `upgrade_wave` | 3.39, 3.40 |
| EN-20-35 | Nâng cấp theo tenant | `tenant_upgrade` | 3.41 |
| EN-20-36 | Lần kiểm thử rò rỉ chéo | `leak_test_run` | 3.42 |
| EN-20-37 | Báo cáo sử dụng | `usage_report` | 3.24 |

: Thực thể EN-20-01…37 và bảng tương ứng
<!-- gen:en:end -->

### 10.2. Chức năng FR-20 → bảng

Bảng dưới nêu với mỗi chức năng các bảng chính phục vụ; FR không có bảng riêng là chức năng xử lý ở dịch vụ trên dữ liệu của các bảng khác (ví dụ lập báo cáo, xem, tìm kiếm).

<!-- gen:fr:start -->
| FR | Nhóm | Tên | Bảng chính |
|---|---|---|---|
| FR-20-001 | A | Khai báo tenant mới (mã T-TENANT, tên, ĐVHC cấp tỉnh, chế độ cách ly, hồ sơ quy mô `QM-*`, hồ sơ triển khai `HT-A`/`HT-B`, mẫu khởi tạo, đầu mối) | `tenant` |
| FR-20-002 | A | Liệt kê, tìm, lọc tenant toàn nền tảng | `tenant` |
| FR-20-003 | A | Xem chi tiết tenant | `tenant` |
| FR-20-004 | A | Sửa hồ sơ hành chính của tenant (không đổi mã, realm) | `tenant` |
| FR-20-005 | A | Quản lý đầu mối và hợp đồng dịch vụ của tenant | `tenant`, `tenant_contact`, `tenant_contract` |
| FR-20-006 | A | Bảo vệ tenant đặc biệt `PLATFORM` và `COMMON` | `tenant` |
| FR-20-007 | A | Kiểm tra sẵn sàng trước khởi tạo (mã trùng, ĐVHC đã có tenant, sức chứa nền tảng NFR-00-060, tài nguyên cụm, mẫu hợp lệ) | `tenant`, `tenant_quota`, `provisioning_template` |
| FR-20-008 | B | Chạy saga khởi tạo tenant | `provisioning_run`, `provisioning_step`, `idempotency_key` |
| FR-20-009 | B | Theo dõi tiến độ saga thời gian thực | `provisioning_run`, `provisioning_step` |
| FR-20-010 | B | Thử lại saga từ bước lỗi | `provisioning_run`, `provisioning_step` |
| FR-20-011 | B | Bù trừ và hủy khởi tạo | `provisioning_run`, `provisioning_step` |
| FR-20-012 | B | Kiểm tra khói sau khởi tạo | `smoke_test_result` |
| FR-20-013 | B | Kích hoạt tenant và bàn giao cho quản trị tỉnh | `tenant`, `tenant_status_history`, `outbox` |
| FR-20-014 | B | Đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16 | `provisioning_run` |
| FR-20-015 | B | Quản lý mẫu khởi tạo có phiên bản | `provisioning_template` |
| FR-20-016 | B | Khởi tạo bổ sung cho tenant đang hoạt động khi nền tảng thêm bước, phân hệ | `provisioning_run`, `tenant_module` |
| FR-20-017 | B | Khởi tạo tenant chế độ `DEDICATED_CLUSTER` (đăng ký cụm riêng, sinh gói cấu hình, chạy saga trên cụm đích) | `provisioning_run`, `tenant_platform_config` |
| FR-20-018 | C | Cài đặt tỉnh do quản trị tỉnh tự quản | `tenant_settings` |
| FR-20-019 | C | Cấu hình nền tảng của tenant (realm, host và tiền tố API công bố, hồ sơ triển khai, vùng DR) | `tenant_platform_config`, `tenant_config_version` |
| FR-20-020 | C | Ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống | `tenant_config_version`, `tenant_platform_config`, `outbox` |
| FR-20-021 | C | Lịch sử, so sánh, khôi phục phiên bản cấu hình | `tenant_config_version` |
| FR-20-022 | C | Phát hiện lệch cấu hình và đối chiếu định kỳ | `config_drift` |
| FR-20-023 | C | Chính sách tiếp nhận truy cập liên tenant của tỉnh (cho phép ghi hay không, chấp thuận trước, thời hạn tối đa, người nhận thông báo) | `cross_tenant_policy` |
| FR-20-024 | C | Xem nhật ký truy cập liên tenant vào tỉnh | `cross_tenant_policy` |
| FR-20-025 | C | Chuyển chế độ cách ly của tenant | `lifecycle_request`, `provisioning_run` |
| FR-20-026 | D | Đặt hạn mức hợp đồng của tenant | `tenant_quota`, `quota_change_request` |
| FR-20-027 | D | Đổi hạn mức có duyệt và đẩy xuống nơi thực thi | `tenant_quota`, `quota_change_request` |
| FR-20-028 | D | Thu thập sử dụng tài nguyên theo tenant | `usage_snapshot` |
| FR-20-029 | D | Cảnh báo ngưỡng hạn mức 80% và 100% | `quota_alert` |
| FR-20-030 | D | Xem sử dụng tài nguyên của tỉnh và toàn nền tảng | `usage_snapshot`, `tenant_quota` |
| FR-20-031 | D | Báo cáo sử dụng tài nguyên theo kỳ, xuất tệp | `usage_report` |
| FR-20-032 | D | Ghi đè hạn mức tạm thời có thời hạn | `quota_override` |
| FR-20-033 | E | Danh mục phân hệ của nền tảng và ma trận phụ thuộc | `platform_module`, `module_dependency` |
| FR-20-034 | E | Bật phân hệ cho tenant | `tenant_module` |
| FR-20-035 | E | Tắt, tạm ngừng phân hệ cho tenant | `tenant_module` |
| FR-20-036 | E | Cờ tính năng theo tenant | `tenant_feature_flag` |
| FR-20-037 | E | Cung cấp trạng thái phân hệ cho menu và giao diện | `platform_module`, `tenant_module` |
| FR-20-038 | F | Tạm ngừng tenant | `tenant`, `lifecycle_request` |
| FR-20-039 | F | Khôi phục tenant | `tenant`, `lifecycle_request` |
| FR-20-040 | F | Đề nghị và duyệt chấm dứt tenant | `tenant`, `lifecycle_request` |
| FR-20-041 | F | Xuất gói bàn giao dữ liệu tenant | `tenant`, `lifecycle_request`, `data_export_package`, `data_export_item` |
| FR-20-042 | F | Thực hiện chấm dứt tenant | `tenant`, `lifecycle_request` |
| FR-20-043 | F | Lịch sử vòng đời và quyết định | `tenant`, `tenant_status_history` |
| FR-20-044 | F | Thông báo thay đổi trạng thái tenant | `tenant_status_history`, `outbox` |
| FR-20-045 | G | Lập kế hoạch sáp nhập | `merge_plan` |
| FR-20-046 | G | Lập bảng ánh xạ sáp nhập | `merge_mapping` |
| FR-20-047 | G | Chạy thử sáp nhập | `merge_participant_run` |
| FR-20-048 | G | Điều phối chuyển dữ liệu theo phân hệ | `merge_participant_run` |
| FR-20-049 | G | Xử lý xung đột sáp nhập | `merge_conflict` |
| FR-20-050 | G | Chuyển định danh và cấp song song thông tin xác thực HTTT | `merge_participant_run`, `merge_mapping` |
| FR-20-051 | G | Chuyển tiếp lượt gọi và chuyển tenant nguồn sang `MERGED` | `merge_plan` |
| FR-20-052 | G | Kết thúc sáp nhập sau thời gian chuyển tiếp | `merge_plan` |
| FR-20-053 | H | Quản lý danh mục tổ chức | `organization` |
| FR-20-054 | H | Hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa | `organization` |
| FR-20-055 | H | Nhập tổ chức từ Excel, CSV có xem trước và xuất | `organization`, `org_import_job`, `org_import_row` |
| FR-20-056 | H | Đồng bộ tổ chức khi sắp xếp đơn vị hành chính (EVT-07-10) | `organization`, `inbox_event` |
| FR-20-057 | H | API đọc tổ chức cho phân hệ khác | `organization` |
| FR-20-058 | H | Đánh dấu và tra cứu tổ chức chủ quản dữ liệu | `organization` |
| FR-20-059 | I | Danh mục phiên bản sản phẩm | `product_release`, `release_component` |
| FR-20-060 | I | Kênh phát hành và đăng ký kênh của tenant | `product_release`, `tenant_release_subscription` |
| FR-20-061 | I | Lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì | `maintenance_window`, `upgrade_plan`, `upgrade_wave` |
| FR-20-062 | I | Theo dõi nâng cấp, dừng sóng, quay lui | `upgrade_plan`, `upgrade_wave`, `tenant_upgrade` |
| FR-20-063 | I | Thông báo phát hành và lịch bảo trì tới tỉnh | `maintenance_window`, `product_release`, `outbox` |
| FR-20-064 | I | Xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh | `product_release`, `maintenance_window`, `tenant_upgrade` |
| FR-20-065 | J | Registry tenant cho phân hệ khác | `tenant`, `tenant_platform_config`, `tenant_module` |
| FR-20-066 | J | Thực thi trạng thái tenant ở data plane và control plane (`ERR-20-001`) | `tenant`, `tenant_module` |
| FR-20-067 | J | Bảng điều khiển nền tảng đa tenant | `tenant`, `usage_snapshot`, `quota_alert`, `leak_test_run` |
| FR-20-068 | J | Nhật ký kiểm toán thao tác PH-20 | `outbox`, `tenant_status_history` |
| FR-20-069 | J | Tham số `20.*` của phân hệ | `tenant_settings`, `tenant_quota` |
| FR-20-070 | J | Điều phối kiểm thử rò rỉ chéo tenant định kỳ (SEC-87) | `leak_test_run` |

: Chức năng FR-20-001…070 và bảng phục vụ
<!-- gen:fr:end -->

### 10.3. Thực thể dùng chung DD-01, DD-02

Hai thực thể dùng chung do PH-20 sở hữu ánh xạ sang cột như sau; chỗ lệch với từ điển dữ liệu ghi ở đề nghị đồng bộ 11.2.

| Thuộc tính D02-07 | Cột | Ghi chú |
|---|---|---|
| DD-01 `code` | `tenant.code` | `UNIQUE`; `^T\d{2}$` hoặc `PLATFORM`, `COMMON` |
| DD-01 `name` | `tenant.name` | |
| DD-01 `admin_unit_id` | `tenant.admin_unit_id` | Bắt buộc với tenant tỉnh; chỉ mục duy nhất một phần theo trạng thái đang hoạt động; tham chiếu logic sang PH-07 |
| DD-01 `status` | `tenant.status` | Bảy giá trị, máy trạng thái bằng trigger |
| DD-01 `isolation_mode` | `tenant.isolation_mode` | `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` |
| DD-01 `merged_into_id` | `tenant.merged_into_id` | Bắt buộc khi `MERGED`; khóa ngoại tự tham chiếu |
| DD-01 `quota` (T-JSON) | `tenant_quota` (mỗi tài nguyên một dòng) | Tách bảng để đẩy xuống nơi thực thi, có trạng thái đẩy và lịch sử đổi; đề nghị sửa D02-07 |
| DD-01 `realm` | `tenant.realm`, `tenant_platform_config.realm_code` | `dh-{code thường}` |
| DD-01 `activated_at` | `tenant.activated_at` | Bắt buộc khi `ACTIVE` |
| DD-02 `code`, `name`, `short_name` | `organization.code`, `name`, `short_name` | `code` duy nhất trong tenant, bất biến |
| DD-02 `parent_id` | `organization.parent_id` | Khóa ngoại kép; không tự trỏ; trigger chặn chu trình |
| DD-02 `org_type` | `organization.org_type` | Năm giá trị |
| DD-02 `admin_unit_id` | `organization.admin_unit_id` | Bắt buộc, tham chiếu logic sang PH-07 |
| DD-02 `is_data_owner` | `organization.is_data_owner` | Mặc định `false`; chỉ mục một phần |
| DD-02 `effective_from`, `effective_to` | cùng tên | `effective_to >= effective_from` |
| DD-02 `successor_id` | `organization.successor_id` | Khóa ngoại kép; bắt buộc khi `MERGED` |
| DD-11 Outbox | `outbox` | `event_id`, `event_type`, `topic`, `aggregate_type`, `aggregate_id`, `payload`, `trace_id`, `occurred_at` |
| DD-12 Tệp | `file_object` | `object_key` đổi tên `object_path` |

: Ánh xạ DD-01, DD-02, DD-11, DD-12 sang cột

### 10.4. Hệ cũ

PH-20 là năng lực mới (REQ-20): hệ LGSP cũ không có phân hệ quản trị tenant, mỗi tỉnh là một bản triển khai riêng. Vì vậy không có bảng hệ cũ nào ánh xạ sang schema này và không có changeset di trú dữ liệu. Truy vết gián tiếp: `LGC-IAM-002` (tạo realm, client, vai trò: PH-12 chính, PH-20 khởi tạo tự động bước `S03_REALM`) và `LGC-BUS-031` (cấu hình hệ thống: PH-18 chính, PH-20 cấu hình theo tenant). Dữ liệu ban đầu của tenant thí điểm (tổ chức tỉnh) được nhập bằng chức năng nhập tổ chức (FR-20-055), không bằng di trú trực tiếp (D06-01 ghi riêng nếu cần).

## 11. Câu hỏi mở và đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Năm câu hỏi mở của CSDL nằm ở dải Q20-50…54; mỗi câu nêu giả định đang dùng để tiếp tục, người cần quyết định và hệ quả nếu đổi. Phần sau liệt kê các đề nghị đồng bộ với tài liệu chung và phân hệ khác, không tự sửa trong tập này.

### 11.1. Câu hỏi mở

Bảng dưới nêu năm câu hỏi chưa có đáp án chính thức, mỗi câu kèm giả định đang áp dụng trong DDL.

| Mã | Câu hỏi | Giả định đang dùng | Hệ quả nếu đổi |
|---|---|---|---|
| Q20-50 | "Một tenant chỉ một kế hoạch sáp nhập đang mở" hiểu theo tenant nguồn hay cả tenant đích? Tỉnh A và B hợp thành tỉnh C cần hai kế hoạch cùng đích C; một tenant vừa là nguồn vừa là đích có được không? | Chỉ ràng buộc theo tenant nguồn (`uq_merge_plan_open_source`); nhiều kế hoạch cùng đích được phép; tenant vừa nguồn vừa đích do dịch vụ kiểm | Ràng buộc theo cả đích thì phải gộp A, B, C vào một kế hoạch nhiều nguồn (đổi `merge_plan`) |
| Q20-51 | Máy trạng thái tenant của D03-10 §5.1 không có `FAILED → DECOMMISSIONED` (hủy khởi tạo sau bù trừ) và `MERGING → ACTIVE` (hủy sáp nhập). Có bổ sung chính thức không? | DDL cho phép cả hai, ghi "bổ sung" ở sơ đồ 2.6 | Không bổ sung thì tenant `FAILED` không hủy được và đơn vị hành chính của nó bị giữ mãi; cần sửa trigger `tg_tenant_transition` |
| Q20-52 | Ma trận phụ thuộc phân hệ (`module_dependency`, 38 dòng) và phân hệ lõi (PH-12, 13, 18, 20) do ai chốt? Phụ thuộc "tùy chọn" như PH-16 → PH-13, PH-17 → PH-09 có chặn bật không? | Ma trận giả định từ D03-01; chỉ phụ thuộc `REQUIRED` chặn bật | Đổi ma trận chỉ là dữ liệu nền, không đổi DDL; đổi cờ lõi là cập nhật `platform_module` |
| Q20-53 | Gói bàn giao dữ liệu khi chấm dứt tenant gồm những loại dữ liệu nào của từng phân hệ (`data_export_item.item_type`), định dạng nào, và thời hạn giữ 90 ngày (`20.export.retention-days`) có đủ theo quy định lưu trữ dữ liệu nhà nước? | `item_type` là chuỗi tự do do từng phân hệ khai báo qua hợp đồng bên tham gia; giữ 90 ngày | Cần danh mục `item_type` chuẩn (có thể thêm bảng danh mục) và có thể tăng thời hạn |
| Q20-54 | `tenant_config_version.snapshot` có lưu toàn bộ cấu hình trong CSDL hay chỉ lưu băm và tham chiếu Git? | Lưu ảnh chụp (đã loại bí mật, tối đa khoảng 50 KB) để so sánh nhanh ở UI-20-17 mà không phụ thuộc kho Git; giữ 24 phiên bản gần nhất | Chỉ lưu băm thì UI so sánh phải gọi Git, nhẹ CSDL hơn nhưng phụ thuộc kho Git sẵn sàng |

: Câu hỏi mở Q20-50…54 của tập CSDL

### 11.2. Phụ lục đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Bảng dưới liệt kê điều cần đồng bộ giữa tập CSDL PH-20 và tài liệu khác; luồng chính xử lý khi FRS PH-20 hoàn tất.

| Số | Tài liệu | Đề nghị |
|---|---|---|
| 1 | FRS PH-20 Phụ lục A | Thêm các liệt kê bổ sung của CSDL (mục 6.3): `ContractStatus`, `ServiceLevel`, `ModuleCatalogStatus`, `DependencyType`, `ConfigScope`, `ChangeSource`, `ApplyStatus`, `DriftResolution`, `SmokeResult`, `OverrideStatus`, `UsageSource`, `PushStatus`, `QuotaSource`, `ReportStatus`, `ReportFormat`, `ExportItemStatus`, `ParticipantPhase`, `ParticipantStatus`, `MappingStatus`, `ConflictKind`, `ConflictState`, `ImportStatus`, `ImportMode`, `ImportAction`, `ImportRowStatus`, `ComponentType`, `WaveStatus`, `WindowType`, `LeakTrigger`, `LeakStatus`, `ScanStatus`, `FilePurpose`, `IdemState`, `ReportScope` |
| 2 | FRS PH-20 | Ghi hai chuyển trạng thái bổ sung `FAILED → DECOMMISSIONED`, `MERGING → ACTIVE` (Q20-51); `MergeStatus` `FAILED` thử lại được; ràng buộc kế hoạch sáp nhập theo tenant nguồn (Q20-50); trạng thái lần chạy "đang hoạt động" gồm `PENDING`, `RUNNING`, `WAITING`, `COMPENSATING` (đã đồng bộ ở 0.2) |
| 3 | D02-07 DD-01 | Bỏ `quota` (T-JSON), thay bằng bảng `tenant_quota`; thêm `kind`, `short_name`, `scale_profile`, `deployment_profile`, `template_id`, `config_path`, `declared_at`, các mốc thời gian trạng thái |
| 4 | D02-07 DD-12 | Đổi tên thuộc tính `object_key` thành `object_path` ở bản vật lý (tránh trùng tên với dạng cột bí mật mà công cụ quét hay báo nhầm) |
| 5 | D03-10 §4 | Bổ sung bốn chế độ RLS của PH-20 (OWN, CTL, TECH, PLAT/PLATR), chính sách theo vai cho phiên `PLATFORM` và ba bể kết nối; D03-10 §5.1 ghi hai chuyển trạng thái bổ sung |
| 6 | D03-09 (hạ tầng) | Ghi schema `ph20_tenant` trên `pg-core`, vai `ph20_owner`, `ph20_app`, `ph20_platform_app`, `ph20_ro`; tài khoản dịch vụ `dh-platform` cho nhóm API nền tảng tách tài khoản nhóm API tỉnh |
| 7 | PH-18 | Thêm `ph20_tenant.usage_snapshot` vào `PartitionMaintenanceJob`; công việc dọn `outbox` (3 ngày), `inbox_event` (14 ngày), `idempotency_key` (24 giờ), `file_object`, `usage_report`, `org_import_*` theo mục 5; đăng ký 29 tham số `20.*` của FRS §8.2; hợp đồng `POST /api/ops/v1/merge-transfers` |
| 8 | PH-13 | Nhận bản ghi kiểm toán qua topic `platform.obs.audit.recorded.v1` từ `outbox` của PH-20; chuỗi kiểm toán theo tenant đóng khi `DECOMMISSIONED` (API-13-073) |
| 9 | PH-19, PH-10 | Thống nhất tên topic với EVT-20-07: `platform.tenant.module-enabled.v1` (PH-19 đang dùng `tenant.module-enabled.v1`); kiểm thử PH-10 dùng `dh.platform.tenant.created.v1`, chuẩn là `platform.tenant.created.v1` |
| 10 | D00-04 | Ghi `ph20_tenant`, bốn vai `ph20_*`, vai kiểm thử `dh_platform_ctl` (mới), `dh_platform_app` và `dh_report_ro` dùng chung với khối `ELSE GRANT` |
| 11 | ADR | ADR số 200…204 đề xuất ở FRS; CSDL hiện thực: ADR số 200 qua `provisioning_run`, `provisioning_step`; ADR số 201 qua `tenant_config_version`, `config_drift`; ADR số 202 qua `merge_*`; ADR số 203 qua `product_release`, `upgrade_*`, `tenant_release_subscription`; ADR số 204 qua `usage_snapshot`, `quota_*` |
| 12 | D02-08 | Thêm các quyền hậu tố provision, lifecycle, approve, quota, merge, release, settings, org, org-read, usage-read của nhóm PERM-20 (đã có admin, read); các `PERM` này là căn cứ cho `ck_*_four_eyes` và tách nhiệm vụ |

: Đề nghị đồng bộ của tập CSDL PH-20

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Kỹ sư CSDL PH-20 | Bản đầu: 45 bảng, bốn chế độ RLS cùng bộ chính sách riêng cho bảng `tenant`, DDL chạy thử trên PostgreSQL 16.15, 14 tệp Liquibase, bài kiểm cô lập 236 khối PASS, ánh xạ EN-20, FR-20 sang bảng, câu hỏi mở Q20-50…54 |
| 0.2 | 27/11/2026 | Kỹ sư CSDL PH-20 | Đồng bộ với FRS 0.2: `uq_provisioning_run_active` gồm `PENDING`; `TemplateState` dùng `PUBLISHED`, `ContactRole` theo FRS 4.2; mã mẫu `tinh-chuan`; cửa sổ bảo trì 120 đến 360 phút; sinh lại DDL, Liquibase, đặc tả; 29 tham số `20.*` |
| 0.3 | 27/11/2026 | Kỹ sư CSDL PH-20 | Đồng bộ chéo cuối: mã kế hoạch `SN-yyyy-nnn`, saga 17 bước |

: Lịch sử phiên bản
