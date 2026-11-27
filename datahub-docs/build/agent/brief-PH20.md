# Brief chung PH-20 Quản trị tenant và phát hành sản phẩm (dùng cho mọi tập, xóa khi đóng PR)

Tài liệu nội bộ cho các phiên viết bảy tập PH-20. Mọi tập PHẢI dùng đúng mã, tên, đường dẫn dưới đây; cần thêm mã thì lấy số kế tiếp trong dải và ghi lại ở mục "Đề nghị đồng bộ" của tập mình. Không sửa tệp này.

## 0. Quy tắc làm việc (bắt buộc)

1. Chỉ tạo, sửa tệp của PH-20: tập chính của mình và thư mục `ph20/` đi kèm. KHÔNG sửa tài liệu chung (D00-*, D02-07, D02-08, D03-01, D03-06-00, D03-10, README, khuôn, `build/tools`, `kiem_tra_ngoai_le.txt`) và KHÔNG đụng phân hệ khác (PH-18 đang được viết song song ở luồng khác). Việc cần sửa ở nơi khác ghi vào "Phụ lục Đề nghị đồng bộ" cuối tập.
2. Đọc trước: `datahub-docs/00-chung/D00-04-so-tra-cuu-gon.md`, `datahub-docs/00-chung/khuon/K-TRINH-BAY.md`, khuôn của tập (`khuon/K-*.md`), và `datahub-docs/03-thiet-ke/D03-10-thiet-ke-da-tenant.md` (nền đa tenant, ngắn). Mẫu gần nhất là bộ PH-16 (`*PH16*`): chỉ mở đúng mục cần đối chiếu bằng Grep/Read có offset, không đọc toàn văn tệp lớn.
3. Chuẩn kết hợp 17 mục (khối `::: dac-ta`) cho FR; UC 15 mục; SDD thành phần 10 mục; CSDL bảng 10 mục; mọi bảng có chú thích `: ...`; mọi sơ đồ Mermaid có đoạn thuyết minh ngay sau; không dùng `;` trong thông điệp sequenceDiagram; metadata `mo_ta` không chứa ": ".
4. Ghi tệp theo chương (mỗi lần Write/Edit một chương trọn vẹn).
5. Trước khi kết thúc: chạy `python3 datahub-docs/build/tools/kiem_tra_ma.py` từ gốc repo và sửa hết lỗi MỚI do tệp của mình. Chạy `/root/go/bin/gitleaks detect --no-git --source <thư mục/tệp của mình> -v` và sửa mọi phát hiện.
6. Chống gitleaks báo nhầm: KHÔNG viết dạng `key = '20.xxx'`, `{key: "...", value: n}`, `"apiKey": "..."`, chuỗi dài ngẫu nhiên, JWT mẫu, `client_secret: abc...`. Giá trị bí mật mẫu luôn viết `<bi-mat-mau>`. Trong SQL dùng `param_key IN (...)` hoặc đặt tên cột khác `key`. Danh sách khóa tham số có chữ "token" xếp cuối.
7. Không dùng git (luồng chính lo commit). Không đọc, in biến môi trường hay khóa.
8. Thiếu số liệu thật: dùng giả định ghi rõ "giả định" kèm cơ sở (GĐ-01…07: tỉnh T01 quy mô vừa, 200 HTTT); không hỏi người dùng. Không để "TBD" ngoài mục Câu hỏi mở.
9. Tiếng Việt chuẩn có dấu, câu đầy đủ; mã, tên trường, đường dẫn để trong backtick.

## 1. Định danh phân hệ

| Mục | Giá trị |
|---|---|
| Mã, tên | PH-20 Quản trị tenant và phát hành sản phẩm (gọi tắt "Quản trị tenant") |
| Slug tệp | `quan-tri-tenant` (ví dụ `02-yeu-cau/frs/D02-03-PH20-frs-quan-tri-tenant.md`) |
| DU | `dh-platform` (control plane, vùng ứng dụng nội bộ, giả định namespace `dh-control`, Z3 theo D03-09) cùng PH-11, 12 (quản trị), 13, 16, 17?, 18 |
| Đợt | MVP (Đợt 1), W2, lane L-CTRL, đội B (D01-02 dòng 1.20: 13 tuần-người) |
| Package | `vn.datahub.platform.tenant` (module Modulith `tenant`, gói công bố `tenant.api`), `vn.datahub.platform.release` (module `release`) |
| Schema | `ph20_tenant` trên `pg-core` |
| REST quản trị nền tảng | `/api/platform/v1` (tenant, sáp nhập, phát hành, mẫu khởi tạo, sử dụng toàn nền tảng); chỉ vai trò nền tảng và tài khoản dịch vụ; không mở ra cổng công khai |
| REST tỉnh tự quản | `/api/tenant/v1` (cài đặt tỉnh, tổ chức, sử dụng của tỉnh, phân hệ đang bật, chính sách liên tenant, lịch bảo trì) |
| REST nội bộ cho phân hệ khác | `/internal/tenant/v1` (registry, tổ chức, báo tiến độ bước saga); chỉ trong mesh, scope dịch vụ |
| Topic | Sự kiện về vòng đời tenant đi trên tiền tố nền tảng `platform.tenant.*.v1` (vì tenant mới chưa có tiền tố Kafka riêng; cùng cách PH-13 dùng `platform.obs.audit.recorded.v1`); sự kiện tổ chức đi trên `{tenant}.tenant.org.*.v1`; phát hành `platform.release.*.v1` |
| Route | `/nen-tang/...` cho vai trò nền tảng, `/quan-tri/cai-dat-tinh`, `/quan-tri/to-chuc` cho quản trị tỉnh (mục 6) |
| Tham số | không gian tên `20.*`, đăng ký với PH-18 (`/van-hanh/tham-so`) |
| Kho cấu hình | Kho Git GitOps `dh-tenant-config`, mỗi tenant một thư mục `tenants/{ma-tenant}/` (D01-02: "Cấu hình tenant: kho Git GitOps, thư mục theo mã tenant, chủ PH-20"); Argo CD áp xuống |
| Thực thể dùng chung sở hữu | DD-01 Tenant (`ph20_tenant.tenant`), DD-02 Tổ chức (`ph20_tenant.organization`) theo D02-07 §4 |
| Hệ cũ | Không có phân hệ tương ứng (REQ-20 năng lực mới). Truy vết gián tiếp: `LGC-IAM-002` (tạo realm, client, vai trò: PH-12 chính, PH-20 khởi tạo tự động), `LGC-BUS-031` (cấu hình hệ thống: PH-18 chính, PH-20 cấu hình theo tenant). Repo không có `docs/07-srs/SRS-PH-20-*.md`: mục "SRS cũ → FR mới" ghi rõ không có, nêu nguồn yêu cầu thay thế (D03-10, D02-07 DD-01/02, D01-02 kênh phát hành, các FRS phân hệ khác) |
| Nguồn yêu cầu | REQ-20 (BRD), BO-06, KPI-12 (thời gian khởi tạo tenant ≤ 1 ngày làm việc), FR-00-010/011/012, NFR-00-057 (≤ 1 giờ tự động), NFR-00-060 (≥ 34 tenant), SEC-80…88, D03-10 §5, D02-02 §5 dòng PH-20 |

: Định danh và quy ước của PH-20

## 2. ADR đề xuất (dải 200–204, chỉ ghi ở "Đề nghị đồng bộ", không tạo tệp)

| Mã | Nội dung |
|---|---|
| ADR 200 | Saga điều phối (orchestration) tự xây trên PostgreSQL: bảng chạy và bảng bước, mỗi bước lũy đẳng với `Idempotency-Key = {runId}:{stepCode}`, bù trừ ngược, khóa ShedLock; không dùng Temporal, Camunda hay Flowable cho saga hạ tầng (Flowable của PH-11 dành cho quy trình nghiệp vụ có người) |
| ADR 201 | Cấu hình tenant lưu ở kho Git `dh-tenant-config` làm trạng thái mong muốn (desired state), CSDL `ph20_tenant` giữ bản ghi, trạng thái và bản chiếu; PH-20 ghi bằng commit ký qua tài khoản dịch vụ, Argo CD áp; đối chiếu lệch định kỳ |
| ADR 202 | Sáp nhập theo hợp đồng "bên tham gia sáp nhập" (`MergeParticipant`): mỗi phân hệ có dữ liệu cung cấp xuất, nhập, kiểm đếm theo gói; PH-18 chạy công cụ chuyển dữ liệu; PH-20 chỉ điều phối, giữ `id` gốc và ghi `origin_tenant_id` |
| ADR 203 | Hai kênh phát hành `STABLE` và `PREVIEW`, nâng cấp theo sóng (wave) với cửa sổ bảo trì của từng tenant, dừng sóng tự động khi chỉ số lỗi vượt ngưỡng; bản STABLE chỉ nhận sau ≥ 14 ngày chạy ở tenant thí điểm (D01-02 "kênh phát hành") |
| ADR 204 | Đo sử dụng tài nguyên bằng ảnh chụp hằng giờ lấy từ nơi thực thi (PH-13 Mimir, PH-03, PH-10, kho đối tượng, CSDL) ghi vào bảng phân vùng theo tháng; cảnh báo 80% và 100% (SEC-86); PH-20 không tự thực thi hạn mức mà đẩy giá trị xuống nơi thực thi |

: ADR đề xuất của PH-20

## 3. Tác nhân, vai trò, quyền

Vai trò chuẩn (D02-08, không tạo ROLE mới): PA `ROLE-PLATFORM_ADMIN`, PO `ROLE-PLATFORM_OPERATOR`, `ROLE-PLATFORM_AUDITOR` (viết tắt trong tập PH-20: PAU), TA `ROLE-TENANT_ADMIN`, TO `ROLE-TENANT_OPERATOR`, SO `ROLE-SECURITY_OFFICER`, AU `ROLE-AUDITOR`, VW `ROLE-VIEWER`, DS `ROLE-DATA_STEWARD` (đọc tổ chức).

Quyền đã có ở D02-08: `PERM-20-admin` (PA), `PERM-20-read` (PA, PO, TA, AU). Quyền mới đề nghị (luồng chính sẽ thêm vào D02-08 khi FRS xong; các tập dùng đúng tên này):

| Quyền | Mô tả | Gán |
|---|---|---|
| `PERM-20-provision` | Khai báo tenant, chạy, thử lại, hủy saga khởi tạo | PA |
| `PERM-20-lifecycle` | Đề nghị tạm ngừng, khôi phục, chấm dứt tenant | PA |
| `PERM-20-approve` | Duyệt bốn mắt các đề nghị chấm dứt, sáp nhập, đổi hạn mức, đổi chế độ cách ly (không tự duyệt đề nghị của mình) | PA |
| `PERM-20-quota` | Đặt, đổi hạn mức hợp đồng, ghi đè tạm thời | PA |
| `PERM-20-merge` | Lập, chạy, kết thúc sáp nhập | PA |
| `PERM-20-release` | Quản lý phiên bản, kênh, kế hoạch nâng cấp | PA, PO (PO chỉ theo dõi và dừng sóng) |
| `PERM-20-settings` | Cài đặt tỉnh, chính sách tiếp nhận liên tenant, cửa sổ bảo trì của tỉnh | TA |
| `PERM-20-org` | Tạo, sửa, ngừng, nhập, xuất tổ chức | TA |
| `PERM-20-org-read` | Xem danh mục tổ chức | mọi vai trò tỉnh, PA, PO |
| `PERM-20-usage-read` | Xem sử dụng tài nguyên, hạn mức của tỉnh | TA, TO, AU |

: Quyền PERM-20 dùng trong các tập

Scope máy nội bộ do PH-20 cấp cho phân hệ khác: `tenant:registry-read` (đọc registry tenant, trạng thái, danh sách tenant hoạt động), `tenant:org-read` (đọc tổ chức), `tenant:provision-report` (phân hệ tham gia báo tiến độ bước saga bất đồng bộ). Scope PH-20 dùng khi gọi phân hệ khác: `iam:realm-provision` (PH-12), `obs:tenant-provision` (PH-13), `platform.tenant.provision` (PH-07, giả định của PH-07), `event:topic-register` (PH-10), `kpi.ingest` (PH-16).

Tách nhiệm vụ: chấm dứt tenant, sáp nhập, đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng cần hai PA khác nhau (người đề nghị không duyệt). Mọi thao tác ghi của PA vào tenant tỉnh phải có lý do và mã phiếu, ghi kiểm toán vào chuỗi của tenant bị tác động (SEC-85).

## 4. Khung chức năng (70 FR, CỐ ĐỊNH mã và tên; FRS có thể chỉnh câu chữ tên nhưng giữ nghĩa và số)

Mức ưu tiên M/S/C; đợt MVP trừ khi ghi khác. Cột UI là màn chính.

| FR | Nhóm | Tên | Ưu tiên, đợt | UI |
|---|---|---|---|---|
| FR-20-001 | A Hồ sơ tenant | Khai báo tenant mới (mã T-TENANT, tên, ĐVHC cấp tỉnh, chế độ cách ly, hồ sơ quy mô `QM-*`, hồ sơ triển khai `HT-A`/`HT-B`, mẫu khởi tạo, đầu mối) | M | UI-20-02 |
| FR-20-002 | A | Liệt kê, tìm, lọc tenant toàn nền tảng | M | UI-20-01 |
| FR-20-003 | A | Xem chi tiết tenant | M | UI-20-03 |
| FR-20-004 | A | Sửa hồ sơ hành chính của tenant (không đổi mã, realm) | M | UI-20-03 |
| FR-20-005 | A | Quản lý đầu mối và hợp đồng dịch vụ của tenant | S | UI-20-03 |
| FR-20-006 | A | Bảo vệ tenant đặc biệt `PLATFORM` và `COMMON` | M | — |
| FR-20-007 | A | Kiểm tra sẵn sàng trước khởi tạo (mã trùng, ĐVHC đã có tenant, sức chứa nền tảng NFR-00-060, tài nguyên cụm, mẫu hợp lệ) | M | UI-20-02 |
| FR-20-008 | B Saga khởi tạo | Chạy saga khởi tạo tenant | M | UI-20-04 |
| FR-20-009 | B | Theo dõi tiến độ saga thời gian thực | M | UI-20-04 |
| FR-20-010 | B | Thử lại saga từ bước lỗi | M | UI-20-04 |
| FR-20-011 | B | Bù trừ và hủy khởi tạo | M | UI-20-04 |
| FR-20-012 | B | Kiểm tra khói sau khởi tạo | M | UI-20-04 |
| FR-20-013 | B | Kích hoạt tenant và bàn giao cho quản trị tỉnh | M | UI-20-04 |
| FR-20-014 | B | Đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16 | S | — |
| FR-20-015 | B | Quản lý mẫu khởi tạo có phiên bản | S | UI-20-21 |
| FR-20-016 | B | Khởi tạo bổ sung cho tenant đang hoạt động khi nền tảng thêm bước, phân hệ | S | UI-20-04 |
| FR-20-017 | B | Khởi tạo tenant chế độ `DEDICATED_CLUSTER` (đăng ký cụm riêng, sinh gói cấu hình, chạy saga trên cụm đích) | S, Đợt 2 | UI-20-02 |
| FR-20-018 | C Cấu hình | Cài đặt tỉnh do quản trị tỉnh tự quản | M | UI-20-12 |
| FR-20-019 | C | Cấu hình nền tảng của tenant (realm, host và tiền tố API công bố, hồ sơ triển khai, vùng DR) | M | UI-20-03 |
| FR-20-020 | C | Ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống | M | — |
| FR-20-021 | C | Lịch sử, so sánh, khôi phục phiên bản cấu hình | S | UI-20-17 |
| FR-20-022 | C | Phát hiện lệch cấu hình và đối chiếu định kỳ | S | UI-20-17 |
| FR-20-023 | C | Chính sách tiếp nhận truy cập liên tenant của tỉnh (cho phép ghi hay không, chấp thuận trước, thời hạn tối đa, người nhận thông báo) | M | UI-20-22 |
| FR-20-024 | C | Xem nhật ký truy cập liên tenant vào tỉnh | S | UI-20-22 |
| FR-20-025 | C | Chuyển chế độ cách ly của tenant | S, Đợt 2 | UI-20-03 |
| FR-20-026 | D Hạn mức, sử dụng | Đặt hạn mức hợp đồng của tenant | M | UI-20-05 |
| FR-20-027 | D | Đổi hạn mức có duyệt và đẩy xuống nơi thực thi | M | UI-20-05 |
| FR-20-028 | D | Thu thập sử dụng tài nguyên theo tenant | M | — |
| FR-20-029 | D | Cảnh báo ngưỡng hạn mức 80% và 100% | M | UI-20-06 |
| FR-20-030 | D | Xem sử dụng tài nguyên của tỉnh và toàn nền tảng | M | UI-20-06, UI-20-13 |
| FR-20-031 | D | Báo cáo sử dụng tài nguyên theo kỳ, xuất tệp | S | UI-20-06 |
| FR-20-032 | D | Ghi đè hạn mức tạm thời có thời hạn | S | UI-20-05 |
| FR-20-033 | E Phân hệ, tính năng | Danh mục phân hệ của nền tảng và ma trận phụ thuộc | M | UI-20-07 |
| FR-20-034 | E | Bật phân hệ cho tenant | M | UI-20-07 |
| FR-20-035 | E | Tắt, tạm ngừng phân hệ cho tenant | M | UI-20-07 |
| FR-20-036 | E | Cờ tính năng theo tenant | S | UI-20-07 |
| FR-20-037 | E | Cung cấp trạng thái phân hệ cho menu và giao diện | M | — |
| FR-20-038 | F Vòng đời | Tạm ngừng tenant | M | UI-20-08 |
| FR-20-039 | F | Khôi phục tenant | M | UI-20-08 |
| FR-20-040 | F | Đề nghị và duyệt chấm dứt tenant | M | UI-20-08 |
| FR-20-041 | F | Xuất gói bàn giao dữ liệu tenant | M | UI-20-08 |
| FR-20-042 | F | Thực hiện chấm dứt tenant | M | UI-20-08 |
| FR-20-043 | F | Lịch sử vòng đời và quyết định | M | UI-20-03 |
| FR-20-044 | F | Thông báo thay đổi trạng thái tenant | M | — |
| FR-20-045 | G Sáp nhập | Lập kế hoạch sáp nhập | M | UI-20-09 |
| FR-20-046 | G | Lập bảng ánh xạ sáp nhập | M | UI-20-09 |
| FR-20-047 | G | Chạy thử sáp nhập | M | UI-20-10 |
| FR-20-048 | G | Điều phối chuyển dữ liệu theo phân hệ | M | UI-20-10 |
| FR-20-049 | G | Xử lý xung đột sáp nhập | M | UI-20-10 |
| FR-20-050 | G | Chuyển định danh và cấp song song thông tin xác thực HTTT | M | UI-20-10 |
| FR-20-051 | G | Chuyển tiếp lượt gọi và chuyển tenant nguồn sang `MERGED` | M | UI-20-10 |
| FR-20-052 | G | Kết thúc sáp nhập sau thời gian chuyển tiếp | M | UI-20-10 |
| FR-20-053 | H Tổ chức | Quản lý danh mục tổ chức | M | UI-20-14, UI-20-15 |
| FR-20-054 | H | Hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa | M | UI-20-15 |
| FR-20-055 | H | Nhập tổ chức từ Excel, CSV có xem trước và xuất | M | UI-20-16 |
| FR-20-056 | H | Đồng bộ tổ chức khi sắp xếp đơn vị hành chính (EVT-07-10) | S | UI-20-14 |
| FR-20-057 | H | API đọc tổ chức cho phân hệ khác | M | — |
| FR-20-058 | H | Đánh dấu và tra cứu tổ chức chủ quản dữ liệu | S | UI-20-15 |
| FR-20-059 | I Phát hành | Danh mục phiên bản sản phẩm | M | UI-20-18 |
| FR-20-060 | I | Kênh phát hành và đăng ký kênh của tenant | M | UI-20-18 |
| FR-20-061 | I | Lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì | M | UI-20-19 |
| FR-20-062 | I | Theo dõi nâng cấp, dừng sóng, quay lui | S | UI-20-19 |
| FR-20-063 | I | Thông báo phát hành và lịch bảo trì tới tỉnh | S | UI-20-12 |
| FR-20-064 | I | Xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh | S | UI-20-12 |
| FR-20-065 | J Dịch vụ, quản trị | Registry tenant cho phân hệ khác | M | — |
| FR-20-066 | J | Thực thi trạng thái tenant ở data plane và control plane (`ERR-20-001`) | M | — |
| FR-20-067 | J | Bảng điều khiển nền tảng đa tenant | S | UI-20-20 |
| FR-20-068 | J | Nhật ký kiểm toán thao tác PH-20 | M | UI-20-03 |
| FR-20-069 | J | Tham số `20.*` của phân hệ | M | — |
| FR-20-070 | J | Điều phối kiểm thử rò rỉ chéo tenant định kỳ (SEC-87) | S | UI-20-20 |

: Khung 70 chức năng FR-20-001…070

### 4.1. Các bước saga khởi tạo (mã bước dùng chung cho FRS, SDD, CSDL, API, TC)

Mở rộng 10 bước của D03-10 §5.2 thành bước con theo phân hệ. Mỗi bước: phân hệ đích, API hoặc sự kiện, bù trừ.

| Mã bước | D03-10 | Việc | Bên thực hiện | Gọi | Bù trừ |
|---|---|---|---|---|---|
| `S01_RECORD` | 1 | Ghi bản ghi tenant `PROVISIONING`, cấu hình mặc định, hạn mức từ mẫu | PH-20 | nội bộ | xóa bản ghi |
| `S02_CONFIG_REPO` | 1 | Tạo thư mục `tenants/{ma}/` trong `dh-tenant-config`, commit cấu hình | PH-20 | Git | revert commit |
| `S03_REALM` | 2 | Realm `dh-{ma thường}`, client, vai trò chuẩn, quản trị tỉnh đầu tiên | PH-12 | API-12-080 (scope `iam:realm-provision`) | xóa realm `PROVISIONING` |
| `S04_SECRETS` | 3 | Đường dẫn `kv/dh/{ma}/...` và chính sách OpenBao, KEK `dh-{ma}-pii` (SEC-88) | PH-20 qua OpenBao | OpenBao API | xóa đường dẫn |
| `S05_BUCKETS` | 4 | Bucket `dh-{ma}-{mục đích}` | PH-20 qua Ceph RGW | S3 API | xóa bucket rỗng |
| `S06_EVENTING` | 5 | Hạn mức, principal nội bộ, ACL tiền tố `{ma}.`, topic hệ thống, nhóm Apicurio | PH-10 | FR-10-064/067 (sự kiện EVT-20-01 + báo tiến độ) | PH-10 gỡ |
| `S07_DATABASE` | 6 | Chỉ `DEDICATED_DB`: cụm CloudNativePG, migration, bảng định tuyến | PH-20 | CNPG CR | xóa cụm |
| `S08_OBSERVABILITY` | 7 | Chuỗi kiểm toán, tổ chức Grafana, nguồn dữ liệu, luật cảnh báo | PH-13 | API-13-072 (scope `obs:tenant-provision`) | đóng chuỗi API-13-073 |
| `S09_GATEWAY` | — | Host, tiền tố, hạn mức hợp đồng ở APISIX | PH-03 | sự kiện EVT-20-01/05 + API đọc của PH-20 | PH-03 gỡ |
| `S10_INTEGRATION` | — | Không gian `DEFAULT`, kho `dh-flows-{ma}`, ApplicationSet runtime | PH-04 | sự kiện EVT-20-01 + báo tiến độ | PH-04 gỡ |
| `S11_SEED_RDM` | 8 | Gói danh mục nền | PH-07 | API-07-073 | PH-07 xóa danh mục nền |
| `S12_SEED_MDM` | 8 | Gói dữ liệu chủ nền (nếu PH-06 bật) | PH-06 | sự kiện + báo tiến độ | — |
| `S13_ORG_SEED` | 8 | Tổ chức cấp tỉnh từ ĐVHC `COMMON` (UBND tỉnh, các sở theo mẫu) | PH-20 | nội bộ | xóa |
| `S14_KPI` | — | Kế thừa bộ chỉ tiêu mẫu | PH-16 | FR-16-008 (nếu PH-16 bật) | — |
| `S15_MODULES` | — | Phát sự kiện bật từng phân hệ theo mẫu (PH-19, PH-17…) và chờ báo xong | các PH | EVT-20-07 + báo tiến độ | EVT-20-08 |
| `S16_SMOKE` | 9 | Kiểm tra khói: đăng nhập quản trị, gọi API mẫu, phát nhận sự kiện mẫu, một ca rò rỉ chéo | PH-20 | — | — |
| `S17_ACTIVATE` | 10 | `ACTIVE`, thông báo đầu mối (PH-18), đẩy KPI-12 (API-16-030) | PH-20 | — | — |

: Mười bảy bước saga khởi tạo và bên thực hiện

Bước bất đồng bộ (S06, S09, S10, S12, S15) chờ phân hệ báo qua `POST /internal/tenant/v1/provisioning-runs/{runId}/steps/{stepCode}:report` (scope `tenant:provision-report`), hết hạn `20.provision.step-timeout-minutes` thì bước `FAILED`. Bước không áp dụng (phân hệ chưa bật, chế độ `SHARED` với S07) có trạng thái `SKIPPED`.

## 5. Mô hình nghiệp vụ

### 5.1. Liệt kê (nguồn chuẩn ở FRS Phụ lục A)

| Liệt kê | Giá trị |
|---|---|
| `TenantStatus` (DD-01) | `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `MERGING`, `MERGED`, `DECOMMISSIONED`, `FAILED` |
| `IsolationMode` | `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` |
| `TenantKind` | `PROVINCE`, `PLATFORM`, `COMMON` |
| `ProvisioningRunStatus` | `PENDING`, `RUNNING`, `WAITING`, `FAILED`, `COMPENSATING`, `COMPENSATED`, `SUCCEEDED`, `CANCELLED` |
| `ProvisioningStepStatus` | `PENDING`, `RUNNING`, `WAITING_REPORT`, `SUCCEEDED`, `FAILED`, `SKIPPED`, `COMPENSATING`, `COMPENSATED` |
| `RunKind` | `INITIAL`, `SUPPLEMENT` (FR-016), `ISOLATION_CHANGE` (FR-025) |
| `LifecycleRequestType` | `SUSPEND`, `RESUME`, `TERMINATE`, `ISOLATION_CHANGE`, `QUOTA_DECREASE` |
| `RequestStatus` (đề nghị có duyệt) | `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED` |
| `SuspendReason` | `MANAGEMENT_DECISION`, `SECURITY_INCIDENT`, `CONTRACT_EXPIRED`, `TENANT_REQUEST`, `OTHER` |
| `QuotaResource` | `API_RPS`, `ACTIVE_FLOWS`, `KAFKA_PRODUCE_MBPS`, `KAFKA_CONSUME_MBPS`, `OBJECT_STORAGE_GB`, `DATABASE_GB`, `USERS`, `MEMBER_SYSTEMS`, `PUBLISHED_APIS`, `TOPICS`, `RUNTIME_CPU`, `RUNTIME_MEMORY_GB` (6 đầu theo D03-10 §5.3, mặc định 500, 1.000, 10, 20, 500, 200, 2.000; còn lại giả định: 300 HTTT, 2.000 API, 2.000 topic, 16 vCPU, 64 GB) |
| `QuotaAlertLevel` | `WARN_80`, `LIMIT_100` |
| `ModuleState` (phân hệ theo tenant) | `DISABLED`, `ENABLING`, `ENABLED`, `DISABLING`, `SUSPENDED`, `FAILED` |
| `MergeStatus` | `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `DRY_RUN`, `TRANSFERRING`, `CONFLICT_REVIEW`, `IDENTITY_TRANSFER`, `CUTOVER`, `TRANSITION`, `COMPLETED`, `CANCELLED`, `FAILED` |
| `MergeMappingType` | `ORGANIZATION`, `MEMBER_SYSTEM`, `CATALOG_CODE`, `API_CONTEXT_PATH`, `USER`, `TOPIC` |
| `ConflictResolution` | `KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP` |
| `OrgType` (DD-02) | `PROVINCE_PC`, `DEPARTMENT`, `COMMUNE_PC`, `PUBLIC_UNIT`, `OTHER` |
| `OrgStatus` | `ACTIVE`, `INACTIVE`, `DISSOLVED`, `MERGED` |
| `ReleaseChannel` | `STABLE`, `PREVIEW` |
| `ReleaseStatus` | `DRAFT`, `PREVIEW`, `STABLE`, `DEPRECATED`, `WITHDRAWN` |
| `UpgradePlanStatus` | `DRAFT`, `SCHEDULED`, `RUNNING`, `PAUSED`, `COMPLETED`, `ROLLED_BACK`, `CANCELLED` |
| `TenantUpgradeStatus` | `PENDING`, `IN_WINDOW`, `UPGRADING`, `VERIFYING`, `DONE`, `FAILED`, `ROLLED_BACK`, `SKIPPED` |
| `ExportPackageStatus` | `REQUESTED`, `COLLECTING`, `READY`, `DELIVERED`, `EXPIRED`, `FAILED` |
| `DriftStatus` | `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN` |

: Giá trị liệt kê dùng chung của PH-20

### 5.2. Thực thể EN-20-nn (FRS định nghĩa; CSDL hiện thực bảng tương ứng; có thể thêm bảng kỹ thuật)

| EN | Thực thể | Bảng |
|---|---|---|
| EN-20-01 | Tenant (DD-01) | `tenant` |
| EN-20-02 | Tổ chức (DD-02) | `organization` |
| EN-20-03 | Đầu mối tenant | `tenant_contact` |
| EN-20-04 | Hợp đồng dịch vụ | `tenant_contract` |
| EN-20-05 | Cấu hình nền tảng của tenant | `tenant_platform_config` |
| EN-20-06 | Cài đặt tỉnh | `tenant_settings` |
| EN-20-07 | Phiên bản cấu hình (bản chiếu commit Git) | `tenant_config_version` |
| EN-20-08 | Lệch cấu hình | `config_drift` |
| EN-20-09 | Mẫu khởi tạo | `provisioning_template` |
| EN-20-10 | Lần chạy saga | `provisioning_run` |
| EN-20-11 | Bước saga | `provisioning_step` |
| EN-20-12 | Kết quả kiểm tra khói | `smoke_test_result` |
| EN-20-13 | Hạn mức hợp đồng | `tenant_quota` |
| EN-20-14 | Đề nghị đổi hạn mức | `quota_change_request` |
| EN-20-15 | Ghi đè hạn mức tạm thời | `quota_override` |
| EN-20-16 | Ảnh chụp sử dụng tài nguyên | `usage_snapshot` (phân vùng tháng) |
| EN-20-17 | Cảnh báo hạn mức | `quota_alert` |
| EN-20-18 | Phân hệ của nền tảng | `platform_module` (dữ liệu `PLATFORM`) |
| EN-20-19 | Phụ thuộc phân hệ | `module_dependency` |
| EN-20-20 | Phân hệ theo tenant | `tenant_module` |
| EN-20-21 | Cờ tính năng theo tenant | `tenant_feature_flag` |
| EN-20-22 | Đề nghị vòng đời có duyệt | `lifecycle_request` |
| EN-20-23 | Sự kiện vòng đời (lịch sử trạng thái) | `tenant_status_history` |
| EN-20-24 | Gói bàn giao dữ liệu | `data_export_package`, `data_export_item` |
| EN-20-25 | Kế hoạch sáp nhập | `merge_plan` |
| EN-20-26 | Ánh xạ sáp nhập | `merge_mapping` |
| EN-20-27 | Lần chuyển theo phân hệ | `merge_participant_run` |
| EN-20-28 | Xung đột sáp nhập | `merge_conflict` |
| EN-20-29 | Chính sách tiếp nhận liên tenant | `cross_tenant_policy` |
| EN-20-30 | Lô nhập tổ chức | `org_import_job`, `org_import_row` |
| EN-20-31 | Phiên bản sản phẩm | `product_release`, `release_component` |
| EN-20-32 | Đăng ký kênh của tenant | `tenant_release_subscription` |
| EN-20-33 | Cửa sổ bảo trì | `maintenance_window` |
| EN-20-34 | Kế hoạch nâng cấp và sóng | `upgrade_plan`, `upgrade_wave` |
| EN-20-35 | Nâng cấp theo tenant | `tenant_upgrade` |
| EN-20-36 | Lần kiểm thử rò rỉ chéo | `leak_test_run` |
| EN-20-37 | Báo cáo sử dụng | `usage_report` |

: Thực thể EN-20-01…37 và bảng tương ứng

Bảng kỹ thuật chung: `outbox` (DD-11), `inbox_event`, `idempotency_key`, `file_object` (DD-12).

Đặc thù RLS: bảng `tenant` không có cột `tenant_id` (chính nó là tenant, D02-07); chính sách: tenant `PLATFORM` thấy mọi dòng, tenant khác chỉ thấy dòng `code = current_setting('app.tenant_id', false)`; chỉ `PLATFORM` ghi. Bảng dữ liệu nền tảng (`platform_module`, `provisioning_template`, `product_release`…) mang `tenant_id = 'PLATFORM'` (đọc được bởi mọi tenant nếu cần như `COMMON` thì ghi rõ). Bảng theo tenant (`organization`, `tenant_settings`, `cross_tenant_policy`, `usage_snapshot`…) có `tenant_id` và RLS chuẩn, cộng điều kiện cho `PLATFORM` đọc qua phiên liên tenant theo FR-00-012 (ghi rõ cách: vai trò kết nối riêng `ph20_platform_app` chỉ dùng trong nhóm `/api/platform/`, vẫn không `BYPASSRLS`, chính sách cho phép khi `app.tenant_id = 'PLATFORM'`).

## 6. Màn hình (UI-20-01…22)

| UI | Tên | Route | PTN | Vai trò |
|---|---|---|---|---|
| UI-20-01 | Danh sách tenant | `/nen-tang/tenant` | PTN-01 | PA, PO, PAU |
| UI-20-02 | Khai báo tenant (wizard 5 bước: hồ sơ, cách ly và quy mô, mẫu và phân hệ, đầu mối, rà soát kèm kiểm tra sẵn sàng) | `/nen-tang/tenant/moi` | PTN-05 | PA |
| UI-20-03 | Chi tiết tenant (tab Tổng quan, Cấu hình nền tảng, Hợp đồng và đầu mối, Phân hệ, Hạn mức, Lịch sử vòng đời, Kiểm toán) | `/nen-tang/tenant/{ma-tenant}` | PTN-02 | PA, PO, PAU |
| UI-20-04 | Tiến độ khởi tạo (sổ bước saga) | `/nen-tang/tenant/{ma-tenant}/khoi-tao` | PTN-11 | PA, PO |
| UI-20-05 | Hạn mức tenant | `/nen-tang/tenant/{ma-tenant}/han-muc` | PTN-03 | PA |
| UI-20-06 | Sử dụng tài nguyên toàn nền tảng | `/nen-tang/su-dung` | PTN-06 | PA, PO |
| UI-20-07 | Phân hệ và tính năng của tenant | `/nen-tang/tenant/{ma-tenant}/phan-he` | PTN-12 | PA |
| UI-20-08 | Đổi trạng thái tenant (tạm ngừng, khôi phục, chấm dứt, xuất bàn giao) | `/nen-tang/tenant/{ma-tenant}/vong-doi` | PTN-04 | PA |
| UI-20-09 | Lập kế hoạch sáp nhập (wizard: nguồn đích, căn cứ, ánh xạ, chạy thử, gửi duyệt) | `/nen-tang/sap-nhap/moi` | PTN-05 | PA |
| UI-20-10 | Theo dõi sáp nhập (tiến độ theo phân hệ, xung đột, chuyển tiếp) | `/nen-tang/sap-nhap/{ma-sap-nhap}` | PTN-02 | PA, PO, TA của hai tỉnh (chỉ đọc phần tỉnh mình) |
| UI-20-11 | Danh sách sáp nhập | `/nen-tang/sap-nhap` | PTN-01 | PA, PO |
| UI-20-12 | Cài đặt tỉnh (thông tin hiển thị, chủ quản CNTT, an toàn đăng nhập trong giới hạn nền tảng, phiên bản và bảo trì) | `/quan-tri/cai-dat-tinh` | PTN-12 | TA |
| UI-20-13 | Sử dụng tài nguyên của tỉnh | `/quan-tri/cai-dat-tinh/su-dung` | PTN-06 | TA, TO, AU |
| UI-20-14 | Danh mục tổ chức (cây + bảng) | `/quan-tri/to-chuc` | PTN-08 | TA, DS, VW |
| UI-20-15 | Chi tiết, biểu mẫu tổ chức | `/quan-tri/to-chuc/{ma-to-chuc}` (`/moi`, `/sua`) | PTN-02, PTN-03 | TA |
| UI-20-16 | Nhập tổ chức | `/quan-tri/to-chuc/nhap` | PTN-09 | TA |
| UI-20-17 | Phiên bản và lệch cấu hình tenant | `/nen-tang/tenant/{ma-tenant}/lich-su` | PTN-02 (so sánh) | PA, PO |
| UI-20-18 | Phiên bản sản phẩm và kênh phát hành | `/nen-tang/phat-hanh` | PTN-01 | PA, PO |
| UI-20-19 | Kế hoạch nâng cấp theo sóng | `/nen-tang/phat-hanh/{phien-ban}/ke-hoach` | PTN-05 (lập), PTN-11 (theo dõi) | PA, PO |
| UI-20-20 | Bảng điều khiển nền tảng đa tenant | `/nen-tang/tong-quan` | PTN-06 | PA, PO, PAU |
| UI-20-21 | Mẫu khởi tạo | `/nen-tang/mau-khoi-tao` | PTN-01 + PTN-03 | PA |
| UI-20-22 | Truy cập liên tenant vào tỉnh (chính sách và nhật ký) | `/quan-tri/cai-dat-tinh/lien-tenant` | PTN-12, PTN-11 | TA, SO, AU |

: Hai mươi hai màn hình UI-20-01…22

D03-06-00 mới có mục menu 45 (`/quan-tri/cai-dat-tinh`) và 46 (`/nen-tang/tenant`). Các mục menu mới (`/quan-tri/to-chuc`, `/nen-tang/sap-nhap`, `/nen-tang/phat-hanh`, `/nen-tang/tong-quan`, `/nen-tang/su-dung`, `/nen-tang/mau-khoi-tao`) ghi vào Đề nghị đồng bộ D03-06-00. Thành phần dùng `CMP-*` đúng tên chuẩn D03-05-03/04 (ví dụ `CMP-TenantSwitcher`, `CMP-ReasonDialog`, `CMP-ConfirmDialog`, `CMP-Steps`, `CMP-DataTable`…; tra bằng Grep, không tự đặt).

## 7. Sự kiện EVT-20-01…16

| EVT | Topic | Khi nào | Bên nhận chính |
|---|---|---|---|
| EVT-20-01 | `platform.tenant.created.v1` | Khai báo xong, saga bắt đầu (`PROVISIONING`) | PH-10, PH-03, PH-04, PH-06, PH-13 |
| EVT-20-02 | `platform.tenant.provisioning-failed.v1` | Saga dừng `FAILED` | PH-13, PH-18 |
| EVT-20-03 | `platform.tenant.activated.v1` | Tenant `ACTIVE` | mọi DU, PH-16 |
| EVT-20-04 | `platform.tenant.status-changed.v1` | Mọi đổi trạng thái (tạm ngừng, khôi phục, `MERGING`, `MERGED`, `DECOMMISSIONED`) | PH-01, PH-03, PH-04, PH-12, PH-13, PH-19 |
| EVT-20-05 | `platform.tenant.quota-changed.v1` | Hạn mức hợp đồng hoặc ghi đè đổi | PH-03, PH-04, PH-10, PH-12 |
| EVT-20-06 | `platform.tenant.quota-threshold-reached.v1` | Sử dụng chạm 80% hoặc 100% | PH-13, PH-18 |
| EVT-20-07 | `platform.tenant.module-enabled.v1` | Bật phân hệ cho tenant | phân hệ được bật (PH-19 FR-19-064…) |
| EVT-20-08 | `platform.tenant.module-disabled.v1` | Tắt, tạm ngừng phân hệ | phân hệ bị tắt |
| EVT-20-09 | `platform.tenant.config-changed.v1` | Cấu hình nền tảng hoặc cài đặt tỉnh đổi (kèm phiên bản) | PH-03, PH-12, `dh-console` |
| EVT-20-10 | `platform.tenant.merge-started.v1` | Sáp nhập được duyệt, bắt đầu chuyển | các phân hệ có dữ liệu, PH-18 |
| EVT-20-11 | `platform.tenant.merge-cutover.v1` | Tenant nguồn `MERGED`, chuyển tiếp bật | PH-03, PH-12, PH-01 |
| EVT-20-12 | `platform.tenant.merge-completed.v1` | Kết thúc sáp nhập | PH-13, PH-16 |
| EVT-20-13 | `{tenant}.tenant.org.changed.v1` | Tổ chức tạo, sửa, ngừng, giải thể, có kế thừa | PH-01, PH-06, PH-07, PH-08, PH-12, PH-16 |
| EVT-20-14 | `platform.release.published.v1` | Phiên bản sản phẩm sang `PREVIEW` hoặc `STABLE` | PH-18 (thông báo) |
| EVT-20-15 | `platform.tenant.upgrade-changed.v1` | Nâng cấp của một tenant đổi trạng thái | PH-13, PH-18 |
| EVT-20-16 | `platform.tenant.export-ready.v1` | Gói bàn giao dữ liệu sẵn sàng | PH-18 |

: Sự kiện EVT-20-01…16

Sự kiện tiêu thụ: EVT-07-10 `common.rdm.adminunit.reorganized.v1` (FR-056), EVT-12-13 `{tenant}.iam.realm.changed.v1`, EVT-09-21 `{tenant}.privacy.crypto-shred.completed.v1`, EVT-13-14 `{tenant}.obs.capacity.warning.v1`, EVT-03-10 `{tenant}.gateway.tenant-redirect.changed.v1`, EVT-03-11 `{tenant}.gateway.limit.changed.v1`. Lệch tên với nơi khác (PH-19 dùng `tenant.module-enabled.v1`, kiểm thử PH-10 dùng `dh.platform.tenant.created.v1`) ghi vào Đề nghị đồng bộ.

## 8. Mã lỗi

`ERR-20-001…099` control plane; `ERR-20-101…199` data plane và registry. Cố định:

| Mã | HTTP | Ý nghĩa | Câu thông báo |
|---|---|---|---|
| ERR-20-001 | 403 | Tenant đang tạm ngừng (đã được PH-02, PH-12, D03-10 dẫn chiếu) | "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh." |
| ERR-20-101 | 503 | Tenant chưa hoạt động (`PROVISIONING`, `FAILED`) khi data plane nhận lượt gọi | "Tỉnh chưa sẵn sàng phục vụ." |
| ERR-20-102 | 410 | Tenant đã `DECOMMISSIONED` | "Tỉnh đã chấm dứt sử dụng Datahub." |
| ERR-20-103 | 503 | Phân hệ chưa bật hoặc đang tạm ngừng cho tenant | "Chức năng này chưa được bật cho tỉnh." |

: Mã lỗi cố định của PH-20

FRS cấp phần còn lại theo thứ tự xuất hiện (dự kiến khoảng ERR-20-002…070, 104…120). Các tập sau CHỈ dùng mã FRS đã cấp.

## 9. Tham số `20.*` (đăng ký với PH-18)

`20.provision.timeout-minutes` (60, NFR-00-057), `20.provision.step-timeout-minutes` (15), `20.provision.step-retry-max` (3), `20.smoke.enabled` (true), `20.quota.warn-percent` (80), `20.quota.override-max-days` (30), `20.usage.snapshot-interval` (PT1H), `20.usage.retention-months` (25), `20.suspend.essential-api-allowed` (false), `20.terminate.cooling-days` (30), `20.export.retention-days` (90), `20.merge.transition-months` (6), `20.merge.transition-max-months` (12), `20.release.stable-soak-days` (14), `20.release.wave-error-threshold-percent` (2), `20.drift.check-interval` (PT1H), `20.org.import-max-rows` (5000), `20.leak-test.schedule` (hằng đêm 01:00), `20.cross-tenant.max-hours` (4, trần theo BR-12-032 của PH-12).

## 10. Phụ thuộc và hợp đồng với phân hệ khác

| Phân hệ | Hướng | Hợp đồng đã có (mã ở tập phân hệ đó) |
|---|---|---|
| PH-12 | PH-20 gọi | API-12-080 tạo realm; API-12-084, 085 đổi trạng thái realm (tạm ngừng, chỉ đọc, khôi phục); API-12-045, 046 kế hoạch và thực hiện chuyển định danh khi sáp nhập; nhận EVT-12-13. Truy cập liên tenant (FR-00-012) là chức năng của PH-12 (FR-12-017, FR-12-027); PH-20 chỉ giữ chính sách tiếp nhận của tỉnh (FR-20-023) mà PH-12 đọc khi cấp quyền |
| PH-13 | PH-20 gọi | API-13-072 `POST /api/platform/v1/tenants/{tenantCode}/observability:provision`, API-13-073 `.../audit-chain:close`; nhận EVT-13-14; Mimir là nguồn số liệu sử dụng |
| PH-07 | PH-20 gọi | API-07-073 `/api/platform/rdm/v1/tenants/{tenantId}:seed` (FR-07-049); nhận EVT-07-10; ĐVHC `COMMON` cho DD-01 `admin_unit_id`, DD-02 |
| PH-10 | Sự kiện | PH-10 nghe EVT-20-01 để khai báo nền (FR-10-064, 067), báo tiến độ bước `S06_EVENTING` |
| PH-03 | Sự kiện, API đọc | PH-03 đọc host, tiền tố, trần hạn mức hợp đồng, trạng thái `MERGED`, bảng ánh xạ API (FR-03-037, 039, `LimitCeilingRule` ERR-03-018); PH-03 thực thi `ERR-20-001` ở APISIX khi tenant tạm ngừng; nhận EVT-03-10, 11 |
| PH-04 | Sự kiện | PH-04 nghe EVT-20-01 tạo không gian `DEFAULT`, kho `dh-flows-{tenant}` (ADR-068) |
| PH-01 | PH-01 gọi | Danh mục tổ chức (FR-20-057, đệm 24 giờ, ERR-01-004, ERR-01-046); EVT-20-04 tenant tạm ngừng; EVT-20-13 tổ chức kế thừa (Q01-10); cấp song song thông tin xác thực HTTT khi sáp nhập |
| PH-06 | Sự kiện | Nạp gói nền khi khởi tạo tenant |
| PH-08, PH-16 | PH gọi | Kiểm tổ chức chủ quản (FR-20-057); PH-16 FR-16-008 kế thừa mẫu khi khởi tạo, API-16-030 (`kpi.ingest`) nhận thời gian khởi tạo tenant chỉ tiêu `thoi-gian-khoi-tao-tenant` (KPI-12) — trả lời Q16-16 của PH-16: chọn API đẩy |
| PH-09 | PH-20 gọi | FR-09-043 xóa mật mã tenant khi chấm dứt (sau bàn giao, hai người duyệt); nhận EVT-09-21 |
| PH-18 | Hai chiều | PH-18 sở hữu tham số (DD-14), thông báo (DD-13), công cụ chuyển dữ liệu sáp nhập và di trú, sao lưu theo tenant. PH-18 đang viết song song: hợp đồng giả định `POST /api/ops/v1/merge-transfers` (chạy chuyển dữ liệu cho một phân hệ của một kế hoạch sáp nhập) và `NotificationApi` gửi thư; ghi Đề nghị đồng bộ |
| PH-19, PH-17, PH-11, PH-14, PH-15 | Sự kiện | Nghe EVT-20-07, 08 bật, tắt phân hệ (PH-19 FR-19-064, ERR-19-049); PH-17 mặc định `17.enabled=false` |
| `dh-console` | Đọc | Trạng thái phân hệ cho menu (D03-06-00 nguyên tắc 5), dải cảnh báo `MERGING`, chế độ chỉ đọc khi `SUSPENDED` |

: Hợp đồng với phân hệ khác

## 11. Dải câu hỏi mở và nơi ghi

`Q20-01…19` FRS · `Q20-20…29` SDD · `Q20-30…39` màn hình · `Q20-40…44` test case · `Q20-45…49` UC · `Q20-50…54` CSDL · `Q20-55…59` API.

## 12. Dải mã khác

UC-20-01… · API-20-001… (FRS §9.4 cấp danh mục API; tập API giữ đúng mã) · TS-20-01… · TC-20-001… · NFR-20-001… · BR-20-001… · BP-20-nn nếu cần quy trình riêng (dùng BP-08 "Khởi tạo tenant" của SRS nếu đã có).

## 13. Nơi bàn giao, công cụ

- DDL: `datahub-docs/03-thiet-ke/csdl/ph20/ddl/ph20_*.sql`, kiểm cô lập `csdl/ph20/test/*isolation*.sql`, công cụ đặc tả bảng `csdl/ph20/tools/them_dac_ta_bang.py` (chép từ `csdl/ph16/tools/` hoặc `csdl/ph19/tools/`). Chạy thử: `python3 datahub-docs/build/tools/chay_ddl.py` (cần PostgreSQL 16; nếu máy không có, ghi rõ trong tóm tắt).
- OpenAPI/AsyncAPI: `datahub-docs/03-thiet-ke/api/ph20/openapi-*.yaml`, `asyncapi-ph20.yaml`; sinh đặc tả bằng `build/tools/sinh_dac_ta_api.py`; kiểm `build/tools/kiem_tra_yaml.py`; Spectral theo `build/tools/spectral.yaml`. Lỗi RFC 9457; dùng `x-datahub-errors`.
- Ảnh hi-fi: `datahub-docs/03-thiet-ke/uiux/ph20/hifi/` (chép cách làm của `uiux/ph16/hifi/` hoặc `ph19/hifi/`, dùng lại `hifi.css`, chụp bằng Playwright có sẵn).
- Test case: `datahub-docs/05-kiem-thu/test-case/ph20/tools/` chép từ `ph16/tools/`; Gherkin `ph20/gherkin/`, xlsx `ph20/D05-02-PH20-test-case.xlsx`.
