---
ma_tai_lieu: D02-04-PH20
ten: Đặc tả use case phân hệ PH-20 Quản trị tenant và phát hành sản phẩm
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, quản trị nền tảng, vận hành nền tảng, quản trị tỉnh, kỹ sư dh-platform, kiểm thử viên
phan_he: PH-20
mo_ta: Đặc tả 36 use case của phân hệ Quản trị tenant và phát hành sản phẩm, mỗi use case một khối 15 mục kèm sơ đồ trình tự, mã lỗi và câu thông báo lấy từ FRS, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH20 FRS; D03-10 Thiết kế đa tenant; D03-02-PH20 SDD; D03-03-PH20 CSDL; D03-04-PH20 API; D03-06-PH20 Màn hình; D05-02-PH20 Kiểm thử
---

# D02-04-PH20 · Đặc tả ca sử dụng Quản trị tenant và phát hành sản phẩm

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 36 use case của PH-20, phủ toàn bộ 70 FR (51 mức M, 19 mức S, không có mức C) của [D02-03-PH20](../frs/D02-03-PH20-frs-quan-tri-tenant.md). Use case đi theo vòng đời của một tỉnh trên Datahub. Quản trị nền tảng khai báo tỉnh mới, chạy kiểm tra sẵn sàng rồi chạy saga khởi tạo tự động mười bảy bước (mục tiêu không quá một giờ ở chế độ `SHARED`, NFR-00-057), xử lý bước lỗi bằng thử lại hoặc bù trừ, kiểm tra khói rồi kích hoạt và bàn giao cho quản trị tỉnh. Sau đó hai bên cùng vận hành: nền tảng giữ cấu hình trong kho GitOps, đặt hạn mức, bật tắt phân hệ, theo dõi sử dụng và cảnh báo; tỉnh tự quản cài đặt, chính sách tiếp nhận truy cập liên tenant và danh mục tổ chức. Khi cần, tỉnh bị tạm ngừng, khôi phục, chấm dứt có bàn giao dữ liệu, hoặc sáp nhập vào tỉnh khác theo kế hoạch có chạy thử, xử lý xung đột, chuyển định danh, chuyển tiếp lượt gọi và kết thúc. Cuối cùng, phân hệ phát hành phiên bản sản phẩm qua hai kênh `STABLE` và `PREVIEW` và nâng cấp từng tỉnh theo sóng trong cửa sổ bảo trì riêng.

Căn cứ pháp lý: CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026 về kiểm soát truy cập, phân tách dữ liệu, nhật ký ở cấp độ 3), CMP-LAW-05 (bảo vệ dữ liệu cá nhân: dữ liệu tỉnh này không lộ sang tỉnh khác, xóa và bàn giao khi chấm dứt), CMP-LAW-03 (kết nối, chia sẻ dữ liệu), CMP-LAW-16 (lưu trữ trong nước). Văn bản về sắp xếp đơn vị hành chính cấp tỉnh chưa có mã trong D00-01 (Q20-01 của FRS).

Bốn điểm hội đồng cần lưu ý. Thứ nhất, PH-20 là năng lực mới: hệ cũ không có khái niệm tenant, chỉ hai chức năng liên quan gián tiếp là tạo realm (`LGC-IAM-002`) và cấu hình hệ thống (`LGC-BUS-031`), nên truy vết hệ cũ rất ít (mục 5.3). Thứ hai, PH-20 điều phối chứ không tự thực thi: hạn mức đẩy xuống APISIX, Kafka, Kubernetes, PH-12; chuyển dữ liệu sáp nhập do PH-18 chạy; trạng thái tạm ngừng do PH-03, PH-12 chặn ở data plane (UC-20-14, 19, 26). Thứ ba, thao tác không đảo ngược được cần hai quản trị nền tảng khác nhau: chấm dứt tenant, duyệt kế hoạch sáp nhập, đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng (UC-20-13, 14, 21, 25), và mọi thao tác vào tenant tỉnh đều có lý do, mã phiếu, ghi kiểm toán vào chuỗi của tỉnh (BR-20-009). Thứ tư, chấm dứt có lưới an toàn: phải tạm ngừng trước, bàn giao gói dữ liệu, chờ 30 ngày nguội rồi mới xóa mật mã (UC-20-20, 21, 22). Ba mươi sáu use case có 12 sơ đồ trình tự cho những luồng nhiều thành phần hoặc có bốn mắt.

## 1. Giới thiệu

Chương này nói tài liệu dùng để làm gì, phủ những gì, ai nên đọc phần nào, thuật ngữ và các tài liệu cần mở song song.

### 1.1. Mục đích

Tài liệu đặc tả 36 use case (ca sử dụng) của PH-20. Mỗi use case mô tả trọn một mục tiêu nghiệp vụ của một tác nhân theo từng bước tương tác với hệ thống, kèm nhánh thay thế, tình huống ngoại lệ có mã lỗi và câu thông báo người dùng nhìn thấy, các đảm bảo hệ thống giữ dù thành công hay thất bại, và với use case có từ ba thành phần hoặc có bốn mắt thì có thêm sơ đồ trình tự. Tài liệu nối FRS (hệ thống phải làm gì) với D03-02 SDD, D03-03 CSDL, D03-04 API và D03-06 màn hình (làm thế nào); kiểm thử viên dùng luồng chính, thay thế, ngoại lệ làm khung kịch bản `TS-20-nn` ở D05-02-PH20.

### 1.2. Phạm vi

Phạm vi là toàn bộ FR-20-001…070. Tài liệu mô tả trình tự giữa tác nhân và hệ thống, dữ liệu ví dụ và cách xử lý khi sai lệch; ràng buộc chi tiết từng bước (kiểu, miền giá trị, thứ tự kiểm tra) nằm ở FR và không chép lại. Chức năng dùng chung FR-00 (đăng nhập có WebAuthn, chọn tenant, danh sách, "Việc của tôi", thông báo, xác nhận thao tác) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Mọi enum, trạng thái, tên trường, quyền, tham số `20.*`, mã màn hình, mã sự kiện dùng đúng Phụ lục A và chương 8, 9, 10 của FRS.

Ngoài phạm vi: cấp và thu hồi quyền truy cập liên tenant, tạo realm và người dùng (PH-12); khóa mật mã và xóa mật mã (PH-09); chuỗi kiểm toán, thông báo vận hành, chỉ số Mimir (PH-13); tham số, thông báo, công cụ chuyển dữ liệu, sao lưu theo tenant (PH-18); cấu hình route và hạn mức tại APISIX (PH-03); tính cước theo sử dụng (ngoài v1.0, Q20-06 của FRS).

### 1.3. Người đọc

Hội đồng thẩm định đọc tóm tắt, chương 4, 5, 9. Quản trị nền tảng và vận hành nền tảng đọc chương 6 theo vòng đời tenant (UC-20-01…29, 32…36). Quản trị tỉnh, cán bộ ATTT, kiểm toán viên tỉnh đọc UC-20-11, 12, 15, 16, 30, 31, 33, 36. Kỹ sư `dh-platform` (package `vn.datahub.platform.tenant` và `vn.datahub.platform.release`) đọc chương 6, mục "Màn hình, API" và các sơ đồ trình tự. Kiểm thử viên coi mỗi luồng chính, thay thế, ngoại lệ là ít nhất một phép kiểm trong `TS-20-nn`.

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01; thuật ngữ đa tenant (tenant, `PLATFORM`, `COMMON`, chế độ cách ly, tenant nguồn, tenant đích) theo D03-10 §1.4; thuật ngữ riêng theo FRS §1.4 và §4. Bảng chỉ nhắc các từ dày đặc trong luồng.

| Thuật ngữ | Giải thích |
|---|---|
| Tenant | Một tỉnh hoặc thành phố trực thuộc trung ương trên nền tảng, mã dạng `T68`; hai tenant đặc biệt `PLATFORM` (quản trị nền tảng) và `COMMON` (dữ liệu dùng chung toàn quốc) |
| Saga khởi tạo | Chuỗi mười bảy bước `S01_RECORD`…`S17_ACTIVATE`, mỗi bước lũy đẳng theo `{runId}:{stepCode}` và có thao tác bù trừ ngược; bước bất đồng bộ `S06`, `S09`, `S10`, `S12`, `S15` chờ phân hệ báo tiến độ |
| Kiểm tra khói (smoke test) | Bốn ca kiểm tra nhanh sau khởi tạo: `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK` |
| Mẫu khởi tạo | Gói cấu hình có phiên bản quyết định phân hệ bật sẵn, hạn mức theo hồ sơ quy mô, tổ chức gieo, bộ chỉ tiêu, danh mục nền; phiên bản `PUBLISHED` bất biến |
| Kho `dh-tenant-config` | Kho Git GitOps giữ cấu hình tenant ở thư mục `tenants/{ma-tenant}/`, là trạng thái mong muốn; Argo CD áp xuống, cơ sở dữ liệu giữ bản chiếu và phiên bản |
| Lệch cấu hình (drift) | Khác biệt giữa trạng thái mong muốn trong Git và trạng thái thực ở cụm hoặc phân hệ đích |
| Hạn mức hiệu lực | Lớn hơn của hạn mức hợp đồng và ghi đè còn hạn, không vượt trần nền tảng; PH-20 đẩy giá trị xuống nơi thực thi, không tự chặn lượt gọi |
| Chế độ cách ly | `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` |
| Gói bàn giao | Gói dữ liệu của tenant xuất theo từng phân hệ, có bản kê `manifest.json`, băm SHA-256 và chữ ký, giao cho tỉnh trước khi chấm dứt |
| Thời gian nguội | Số ngày tối thiểu giữa tạm ngừng và thực hiện chấm dứt (`20.terminate.cooling-days`, 30) |
| Xóa mật mã (crypto-shred) | Hủy KEK `dh-{ma}-pii` của tenant để dữ liệu mã hóa còn sót không giải mã được (FR-09-043) |
| Bên tham gia sáp nhập (`MergeParticipant`) | Hợp đồng mỗi phân hệ cung cấp để xuất, nhập, kiểm đếm dữ liệu khi sáp nhập |
| Cutover | Thời điểm tenant nguồn sang `MERGED` chỉ đọc và lượt gọi được chuyển tiếp sang tenant đích kèm header `Deprecation`, `Sunset` |
| Sóng (wave) | Nhóm tenant nâng cấp cùng đợt trong một kế hoạch nâng cấp; sóng tự dừng khi tỷ lệ lỗi vượt `20.release.wave-error-threshold-percent` |
| Bốn mắt | Người thứ hai khác người lập phải duyệt (FR-00-071, BR-20-008) |
| PA, PO, PAU, TA, TO, SO, AU, DS, VW | Quản trị, vận hành, kiểm toán nền tảng; quản trị tỉnh, vận hành tỉnh, cán bộ ATTT tỉnh, kiểm toán viên tỉnh, cán bộ quản lý dữ liệu, người xem (FRS §3.1) |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

[D02-03-PH20 FRS](../frs/D02-03-PH20-frs-quan-tri-tenant.md) (nguồn chuẩn: §3 tác nhân, §4 máy trạng thái và bước saga, §7 quy tắc, §8 tham số, §9 lỗi, thông báo, sự kiện, API, §10.1 màn hình, Phụ lục A, B); D02-01 BRD (BO-06, KPI-12, REQ-20, BP-08); D02-02 SRS (FR-00-010…012, 071, NFR-00-057, 060); D02-07 (DD-01, DD-02); D02-08; D03-10 Thiết kế đa tenant; D00-01; D00-04; K-UC, K-TRINH-BAY; mẫu D02-04-PH16. Không có `docs/07-srs/SRS-PH-20-*.md` (FRS mục 11.3).

### 1.6. Cấu trúc tài liệu

Chương 2 quy ước đọc; 3 tác nhân; 4 sơ đồ use case tổng (bảy hình); 5 bảng tổng hợp, ma trận truy vết FR, UI, API, REQ, LGC; 6 ba mươi sáu khối đặc tả kèm sơ đồ trình tự; 7 luồng phụ dùng chung; 8 mã đã dùng và độ phủ; 9 câu hỏi mở; Phụ lục A đề nghị đồng bộ cho FRS và tài liệu chung.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ · Quy tắc áp dụng · Màn hình, API. Đoạn văn trước khối nói bối cảnh; sau khối, nếu có, là sơ đồ trình tự Mermaid và một đoạn thuyết minh.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3). Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-20-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép, nguyên văn FRS §9.2 (dấu `{…}` do máy chủ điền). Mã ERR-20-106…113, 116, 117 là lỗi chạy nền, không có người nhìn trực tiếp: người vận hành thấy ở dòng bước của UI-20-04, ở UI-20-10, UI-20-20 hoặc ở PH-13. Luồng phụ dùng chung ghi `LP-20-nn`, đặc tả một lần ở chương 7.

Quy ước chung không nhắc lại từng use case: lệnh `POST` tạo hoặc chuyển trạng thái mang `Idempotency-Key` (dùng lại với yêu cầu khác: ERR-20-009, 409); lệnh `PUT`, `PATCH` và hành động trên đối tượng có phiên bản mang `If-Match` (lệch phiên bản: ERR-20-005, 412; thiếu: ERR-00-428); đối tượng ngoài phạm vi được xem trả ERR-20-002 (404); thiếu quyền chức năng trả ERR-00-403, chưa đăng nhập ERR-00-401; thao tác thay đổi tenant tỉnh cần lý do từ 20 ký tự và mã phiếu (ERR-20-008, 422); lệnh ghi lên tenant `PLATFORM`, `COMMON` bị ERR-20-010 chặn (UC-20-03). Truy vấn chạy dưới RLS theo `tenant_id`; mọi thao tác ghi sinh kiểm toán chuyển sang PH-13 và sự kiện qua outbox không chứa dữ liệu cá nhân (BR-20-039). Dữ liệu ví dụ giả lập, tỉnh mới `T68`, tỉnh nguồn khi sáp nhập `T67`.

| Vai | Người hoặc đối tượng | Ghi chú |
|---|---|---|
| PA | **Hà** (quản trị nền tảng), **Khoa** (quản trị nền tảng thứ hai) | Hà lập, Khoa duyệt; đổi vai tùy use case, luôn là hai người khác nhau |
| PO, PAU | **Tuấn** (vận hành), **Yến** (kiểm toán nền tảng) | Tuấn theo dõi saga, sử dụng, nâng cấp; Yến chỉ đọc |
| TA | **Mai** (quản trị tỉnh T68), **Phúc** (quản trị tỉnh T67) | Mai tự quản cài đặt, tổ chức, chính sách liên tenant |
| TO, SO, AU | **Chi** (vận hành tỉnh), **Dũng** (ATTT tỉnh), **Bảo** (kiểm toán viên tỉnh) | Xem sử dụng, nhật ký liên tenant |
| DS, VW | **Lan** (quản lý dữ liệu), **Hùng** (lãnh đạo UBND tỉnh) | Xem danh mục tổ chức |
| Tenant | `T68` "Tỉnh Lâm Viên" (giả định), hồ sơ `QM-VUA`, `HT-B`, `SHARED`; `T67` tỉnh nguồn; `T91`, `T92` tenant kiểm thử | Giả định tỉnh quy mô vừa 200 HTTT |
| Mẫu, kế hoạch | Mẫu `tinh-chuan` phiên bản 3; kế hoạch sáp nhập `SN-2026-001`; phiên bản sản phẩm `1.4.0`; kế hoạch nâng cấp `UP-2026-007` | Mã ví dụ, không phải mã thật |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-20 có chín nhóm tác nhân người, các phân hệ và công cụ phụ trợ. Vai trò nền tảng chỉ tồn tại ở tenant `PLATFORM`; khi tác động một tenant tỉnh họ dùng nhóm API `/api/platform/v1` và mỗi thao tác ghi cần lý do và mã phiếu (BR-20-009). Năm cặp loại trừ bốn mắt (FRS §3.3) áp dụng trên cùng một đối tượng, không phụ thuộc vai trò: người lập, gửi đề nghị chấm dứt khác người duyệt; người lập, gửi kế hoạch sáp nhập khác người duyệt; người đề nghị đổi chế độ cách ly khác người duyệt; người đề nghị hạ hạn mức dưới mức đang dùng khác người duyệt; người duyệt chấm dứt khác người xác nhận bàn giao gói dữ liệu. Nền tảng cần ít nhất hai người giữ `PERM-20-approve`; chỉ một người thì UI-20-08, UI-20-09 cảnh báo và việc duyệt bị chặn chứ không cho tự duyệt. PH-20 không tạo vai trò mới; mười quyền ngoài `PERM-20-admin`, `PERM-20-read` là đề nghị ở Phụ lục B của FRS.

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính | Use case chính (UC-20-nn) |
|---|---|---|---|
| PA | ROLE-PLATFORM_ADMIN | `admin`, `provision`, `lifecycle`, `approve`, `quota`, `merge`, `release` | 01…10, 13, 14, 16…18, 20…22, 24…29, 32…36 |
| PO | ROLE-PLATFORM_OPERATOR | `read`; `release` chỉ theo dõi và dừng sóng | 01, 06, 10, 16, 23, 34, 35 |
| PAU | ROLE-PLATFORM_AUDITOR | `read`, chỉ đọc toàn nền tảng | 01, 23, 35, 36 |
| TA | ROLE-TENANT_ADMIN | `settings`, `org`, `usage-read`, `org-read` | 11, 12, 16, 30, 31, 33, 36 |
| TO | ROLE-TENANT_OPERATOR | `usage-read`, `org-read` | 11, 16 |
| SO | ROLE-SECURITY_OFFICER | `org-read`; đọc chính sách và nhật ký liên tenant | 12 |
| AU | ROLE-AUDITOR | `usage-read`; đọc nhật ký liên tenant, kiểm toán PH-20 của tỉnh | 12, 16, 36 |
| DS, VW | ROLE-DATA_STEWARD, ROLE-VIEWER | `org-read` | 30 |
| Phân hệ tham gia saga | PH-03, 04, 06, 10, 17, 19… | Nghe EVT-20-01, 07; báo `tenant:provision-report` | 05, 17 |
| Phân hệ đọc registry | Mọi DU, PH-01, 06, 07, 08, 12, 16 | Scope `tenant:registry-read`, `tenant:org-read` | 19 |
| Bộ lập lịch, bộ thực thi saga PH-20 | Tác vụ nền `PLATFORM` | Thu sử dụng, đối chiếu lệch, kiểm thử rò rỉ, hết hạn ghi đè | 05, 10, 15, 35 |

: Tác nhân và use case mà họ là tác nhân chính

PH-12, PH-13, PH-07, PH-09, PH-16 (được PH-20 gọi), PH-18 (tham số, thông báo, công cụ chuyển dữ liệu), Argo CD, kho Git `dh-tenant-config`, OpenBao, Ceph RGW và `dh-console` là tác nhân phụ xuất hiện ở cột "Tác nhân phụ" của từng use case.

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, 36 use case chia thành bảy hình theo vòng đời: hồ sơ và khởi tạo, cấu hình và cách ly, hạn mức và phân hệ, vòng đời, sáp nhập, tổ chức, phát hành và quản trị. Mermaid không có ký pháp UML use case nên dùng `flowchart`: hình bo tròn là tác nhân người, hình hai viền là tác nhân hệ thống, hình chữ nhật bo góc là use case; đường liền nối tác nhân với use case mà họ tham gia.

```{.mermaid caption="Use case hồ sơ tenant và saga khởi tạo"}
flowchart TB
  PA([PA])
  PO([PO, PAU])
  SYS[[Bộ thực thi saga]]
  subgraph G1["Hồ sơ tenant"]
    U01(UC-20-01 Tra cứu, xem chi tiết)
    U02(UC-20-02 Khai báo, kiểm tra sẵn sàng)
    U03(UC-20-03 Sửa hồ sơ, đầu mối, bảo vệ)
    U04(UC-20-04 Mẫu khởi tạo)
  end
  subgraph G2["Saga khởi tạo"]
    U05(UC-20-05 Chạy saga)
    U06(UC-20-06 Theo dõi, thử lại, bù trừ)
    U07(UC-20-07 Kiểm tra khói, kích hoạt, KPI-12)
    U08(UC-20-08 Bổ sung, cụm riêng)
  end
  PA --- U01 & U02 & U03 & U04 & U05 & U06 & U07 & U08
  PO --- U01 & U06
  SYS --- U05 & U07
```

Hình cho thấy khai báo (UC-20-02) chỉ ghi hồ sơ, tài nguyên thật chỉ được tạo khi chạy saga (UC-20-05); lỗi giữa chừng đi vào UC-20-06, thành công thì qua kiểm tra khói rồi kích hoạt (UC-20-07). Mẫu khởi tạo (UC-20-04) là đầu vào của khai báo.

```{.mermaid caption="Use case cấu hình, cài đặt tỉnh và chế độ cách ly"}
flowchart TB
  PA([PA, PO])
  TA([TA])
  AU([SO, AU])
  G[[Argo CD, kho Git]]
  U09(UC-20-09 Cấu hình nền tảng, GitOps)
  U10(UC-20-10 Phiên bản, lệch cấu hình)
  U11(UC-20-11 Cài đặt tỉnh, lịch bảo trì)
  U12(UC-20-12 Chính sách liên tenant)
  U13(UC-20-13 Chuyển chế độ cách ly)
  PA --- U09 & U10 & U13
  TA --- U11 & U12
  AU --- U12
  U09 --- G
  U10 --- G
  U11 -.-> U09
```

Hình cho thấy cả cấu hình nền tảng của PA (UC-20-09) lẫn cài đặt tỉnh của TA (UC-20-11) cùng đi qua một đường ghi vào kho Git có chữ ký; tỉnh chỉ chỉnh được trong giới hạn nền tảng và chỉ chặt hơn.

```{.mermaid caption="Use case hạn mức, sử dụng và phân hệ"}
flowchart TB
  PA([PA])
  PO([PO, TA, TO, AU])
  SYS[[Bộ lập lịch, phân hệ khác]]
  subgraph G3["Hạn mức và sử dụng"]
    U14(UC-20-14 Đặt, đổi hạn mức, ghi đè)
    U15(UC-20-15 Thu sử dụng, cảnh báo)
    U16(UC-20-16 Xem sử dụng, báo cáo)
  end
  subgraph G4["Phân hệ và registry"]
    U17(UC-20-17 Danh mục, bật phân hệ)
    U18(UC-20-18 Tắt, tạm ngừng, cờ)
    U19(UC-20-19 Registry, thực thi trạng thái)
  end
  PA --- U14 & U17 & U18
  PO --- U16
  SYS --- U15 & U19
  U15 -.-> U14
```

Hình cho thấy hạn mức do PA đặt, đo thực tế do bộ lập lịch thu hằng giờ rồi cảnh báo 80% và 100%; phân hệ do PA bật tắt còn registry (UC-20-19) là đường duy nhất để mọi phân hệ khác biết tenant đang ở trạng thái nào.

```{.mermaid caption="Use case vòng đời tenant"}
flowchart TB
  PA([PA hai người])
  PX([PO, PAU])
  H[[PH-12, PH-09, PH-18]]
  U20(UC-20-20 Tạm ngừng, khôi phục)
  U21(UC-20-21 Đề nghị chấm dứt, bàn giao)
  U22(UC-20-22 Thực hiện chấm dứt)
  U23(UC-20-23 Lịch sử, thông báo)
  PA --- U20 & U21 & U22
  PX --- U23
  PA --- U23
  U20 --- H
  U22 --- H
```

Hình cho thấy chấm dứt đi sau tạm ngừng (UC-20-20), cần đề nghị và hai người duyệt kèm gói bàn giao (UC-20-21), rồi mới thực hiện và xóa mật mã (UC-20-22); mọi chuyển trạng thái đều có dòng lịch sử và thông báo (UC-20-23).

```{.mermaid caption="Use case sáp nhập tenant"}
flowchart TB
  PA([PA hai người])
  TA([TA hai tỉnh, chỉ đọc])
  H[[PH-18, PH-12, PH-03]]
  U24(UC-20-24 Lập kế hoạch, ánh xạ)
  U25(UC-20-25 Chạy thử, gửi duyệt, duyệt)
  U26(UC-20-26 Chuyển dữ liệu theo phân hệ)
  U27(UC-20-27 Xử lý xung đột)
  U28(UC-20-28 Chuyển định danh, cutover)
  U29(UC-20-29 Kết thúc sáp nhập)
  PA --- U24 & U25 & U26 & U27 & U28 & U29
  TA -.- U26
  H --- U26 & U28
```

Hình đi theo trục thời gian của một cuộc sáp nhập: lập và ánh xạ, chạy thử, duyệt, chuyển dữ liệu, xử lý xung đột, chuyển định danh và cutover, cuối cùng kết thúc sau thời gian chuyển tiếp. TA của hai tỉnh chỉ xem phần tỉnh mình (UI-20-10).

```{.mermaid caption="Use case danh mục tổ chức"}
flowchart TB
  TA([TA])
  RD([DS, VW])
  S[[PH-07, PH-01, phân hệ khác]]
  U30(UC-20-30 Danh mục, nhập, xuất, chủ quản)
  U31(UC-20-31 Giải thể, hợp nhất, đồng bộ ĐVHC)
  U19(UC-20-19 Phân hệ đọc tổ chức)
  TA --- U30 & U31
  RD --- U30
  S --- U31
  S --- U19
```

Hình cho thấy tổ chức là danh mục chuẩn do TA giữ (UC-20-30), sắp xếp bộ máy đi qua kế thừa (UC-20-31), và phân hệ khác chỉ đọc qua API nội bộ (UC-20-19).

```{.mermaid caption="Use case phát hành sản phẩm và quản trị phân hệ"}
flowchart TB
  PA([PA])
  PO([PO, PAU])
  TA([TA, AU])
  U32(UC-20-32 Phiên bản, kênh)
  U33(UC-20-33 Kế hoạch nâng cấp, thông báo)
  U34(UC-20-34 Theo dõi, dừng sóng, quay lui)
  U35(UC-20-35 Bảng điều khiển, rò rỉ)
  U36(UC-20-36 Kiểm toán, tham số)
  PA --- U32 & U33 & U34 & U35 & U36
  PO --- U34 & U35
  TA --- U33 & U36
  U32 -.-> U33
  U33 -.-> U34
```

Hình cho thấy chuỗi phát hành: đăng ký phiên bản và qua hai kênh (UC-20-32), lập kế hoạch nâng cấp theo sóng và báo tỉnh (UC-20-33), theo dõi và dừng sóng khi lỗi (UC-20-34). PO chỉ theo dõi và dừng sóng; kiểm toán và tham số gộp ở UC-20-36.

## 5. Bảng tổng hợp use case và truy vết

Chương này là danh sách chính thức 36 use case, đặt trước phần chi tiết để tra nhanh. Bảng 5.2 là nguồn của mục "Màn hình, API" trong từng khối; bảng 5.3 là nguồn của mục "Truy vết". PH-20 là năng lực mới nên cột LGC chủ yếu là "—", chỉ hai chức năng hệ cũ liên quan gián tiếp (FRS mục 2.6).

### 5.1. Use case và FR

Bảng liệt kê 36 use case, tác nhân chính, mức ưu tiên cao nhất trong các FR của use case và FR hiện thực (số đuôi của `FR-20-nnn`). Cả 70 FR (51 mức M, 19 mức S, không có mức C) thuộc ít nhất một use case. UC-20-08 và UC-20-13 có FR thuộc Đợt 2 (FR-20-017, FR-20-025), phần còn lại thuộc MVP.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-20-01 | Tra cứu và xem chi tiết tenant toàn nền tảng | PA, PO, PAU | M | 002, 003 |
| UC-20-02 | Khai báo tenant mới và kiểm tra sẵn sàng | PA | M | 001, 007 |
| UC-20-03 | Sửa hồ sơ, đầu mối, hợp đồng và bảo vệ tenant đặc biệt | PA | M | 004, 005, 006 |
| UC-20-04 | Quản lý mẫu khởi tạo có phiên bản | PA | S | 015 |
| UC-20-05 | Chạy saga khởi tạo tenant | PA | M | 008 |
| UC-20-06 | Theo dõi saga, thử lại, bù trừ và hủy khởi tạo | PA, PO | M | 009, 010, 011 |
| UC-20-07 | Kiểm tra khói, kích hoạt, bàn giao và đo thời gian khởi tạo | PA | M | 012, 013, 014 |
| UC-20-08 | Khởi tạo bổ sung và khởi tạo cụm riêng | PA | S | 016, 017 |
| UC-20-09 | Cấu hình nền tảng của tenant và ghi vào kho GitOps | PA | M | 019, 020 |
| UC-20-10 | Xem phiên bản, so sánh, khôi phục cấu hình và xử lý lệch | PA, PO | S | 021, 022 |
| UC-20-11 | Cài đặt tỉnh, xem phiên bản và lịch bảo trì của tỉnh | TA | M | 018, 064 |
| UC-20-12 | Đặt chính sách tiếp nhận và xem nhật ký truy cập liên tenant | TA, SO, AU | M | 023, 024 |
| UC-20-13 | Chuyển chế độ cách ly của tenant | PA | S | 025 |
| UC-20-14 | Đặt, đổi hạn mức hợp đồng và ghi đè tạm thời | PA | M | 026, 027, 032 |
| UC-20-15 | Thu thập sử dụng tài nguyên và cảnh báo ngưỡng hạn mức | Bộ lập lịch PH-20 | M | 028, 029 |
| UC-20-16 | Xem sử dụng tài nguyên và lập báo cáo sử dụng | PA, PO, TA | M | 030, 031 |
| UC-20-17 | Xem danh mục phân hệ, bật phân hệ và cấp trạng thái cho menu | PA | M | 033, 034, 037 |
| UC-20-18 | Tắt, tạm ngừng, tiếp tục phân hệ và đặt cờ tính năng | PA | M | 035, 036 |
| UC-20-19 | Phân hệ đọc registry, tổ chức và thực thi trạng thái tenant | Phân hệ khác | M | 057, 065, 066 |
| UC-20-20 | Tạm ngừng và khôi phục tenant | PA | M | 038, 039 |
| UC-20-21 | Đề nghị, duyệt chấm dứt tenant và xuất gói bàn giao | PA | M | 040, 041 |
| UC-20-22 | Thực hiện chấm dứt tenant | PA | M | 042 |
| UC-20-23 | Tra lịch sử vòng đời và nhận thông báo đổi trạng thái | PA, PO, PAU | M | 043, 044 |
| UC-20-24 | Lập kế hoạch và bảng ánh xạ sáp nhập | PA | M | 045, 046 |
| UC-20-25 | Chạy thử, gửi duyệt và duyệt kế hoạch sáp nhập | PA | M | 045, 047 |
| UC-20-26 | Điều phối chuyển dữ liệu sáp nhập theo phân hệ | PA | M | 048 |
| UC-20-27 | Xử lý xung đột sáp nhập | PA | M | 049 |
| UC-20-28 | Chuyển định danh, cấp song song thông tin xác thực và cutover | PA | M | 050, 051 |
| UC-20-29 | Kết thúc sáp nhập sau thời gian chuyển tiếp | PA | M | 052 |
| UC-20-30 | Quản lý danh mục tổ chức, nhập, xuất và chủ quản dữ liệu | TA | M | 053, 055, 058 |
| UC-20-31 | Giải thể, hợp nhất tổ chức và đồng bộ khi sắp xếp ĐVHC | TA | M | 054, 056 |
| UC-20-32 | Quản lý phiên bản sản phẩm và kênh phát hành | PA | M | 059, 060 |
| UC-20-33 | Lập kế hoạch nâng cấp theo sóng và thông báo lịch bảo trì | PA, TA | M | 061, 063 |
| UC-20-34 | Theo dõi nâng cấp, dừng sóng và quay lui | PA, PO | S | 062 |
| UC-20-35 | Xem bảng điều khiển đa tenant và kiểm thử rò rỉ chéo tenant | PA, PO, PAU | S | 067, 070 |
| UC-20-36 | Tra nhật ký kiểm toán và tham số 20.* | PA, PAU, TA, AU | M | 068, 069 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình và API

Cột API gồm API của PH-20 (`API-20-nnn`) và API của phân hệ khác mà FRS dẫn ở mục "Màn hình, API" của FR. Use case không có màn riêng (UC-20-19) ghi rõ; use case chạy nền chỉ có số liệu hiển thị ở màn của use case khác.

| UC | UI | API |
|---|---|---|
| UC-20-01 | UI-20-01, UI-20-03 | API-20-001, 003 |
| UC-20-02 | UI-20-02, UI-20-04 | API-20-002, 005, 006 |
| UC-20-03 | UI-20-03 | API-20-004, 007, 008, 009, 010, 011, 012 |
| UC-20-04 | UI-20-21 | API-20-025, 026, 027, 028, 029, 030, 031, 032 |
| UC-20-05 | UI-20-02, UI-20-03, UI-20-04 | API-20-013, 166 |
| UC-20-06 | UI-20-04 | API-20-014, 015, 016, 017, 018, 019, 020, 021 |
| UC-20-07 | UI-20-04, UI-20-20 | API-16-030; API-20-015, 022, 023, 024 |
| UC-20-08 | UI-20-02, UI-20-03, UI-20-04, UI-20-20, UI-20-21 | API-20-013, 033, 034, 035, 036, 037, 038 |
| UC-20-09 | UI-20-03, UI-20-17 | API-20-039, 040 |
| UC-20-10 | UI-20-17 | API-20-041, 042, 043, 044, 045, 046 |
| UC-20-11 | UI-20-12 | API-20-135, 136, 159, 160 |
| UC-20-12 | UI-20-22 | API-20-137, 138, 139, 165 |
| UC-20-13 | UI-20-03 | API-20-047, 076, 077, 079 |
| UC-20-14 | UI-20-05, UI-20-08 | API-20-048, 049, 050, 051, 052, 053, 054, 055, 164 |
| UC-20-15 | UI-20-06, UI-20-13 | API-20-058, 059 |
| UC-20-16 | UI-20-06, UI-20-13 | API-20-056, 057, 060, 061, 062, 140, 141 |
| UC-20-17 | UI-20-07 | API-20-063, 064, 065, 142, 163, 166 |
| UC-20-18 | UI-20-07 | API-20-064, 066, 067, 068, 069, 070 |
| UC-20-19 | — | API-20-142, 162, 163, 164, 169, 170, 171 |
| UC-20-20 | UI-20-08 | API-12-084, 085; API-20-071, 079 |
| UC-20-21 | UI-20-08 | API-20-071, 073, 074, 075, 076, 077, 078, 080, 081, 082, 083, 084, 168 |
| UC-20-22 | UI-20-08 | API-20-079 |
| UC-20-23 | UI-20-03 | API-20-072, 074, 085 |
| UC-20-24 | UI-20-08, UI-20-09, UI-20-11 | API-20-086, 087, 088, 089, 093, 094, 095, 096 |
| UC-20-25 | UI-20-08, UI-20-09, UI-20-10, UI-20-11 | API-20-090, 091, 092, 097, 167 |
| UC-20-26 | UI-20-10 | API-20-088, 098, 099, 100, 167 |
| UC-20-27 | UI-20-10 | API-20-101, 102, 103 |
| UC-20-28 | UI-20-10 | API-12-045, 046; API-20-104, 105, 106, 164 |
| UC-20-29 | UI-20-10 | API-20-107, 108 |
| UC-20-30 | UI-20-14, UI-20-15, UI-20-16 | API-20-143, 144, 145, 146, 152, 153, 154, 155, 156, 171 |
| UC-20-31 | UI-20-14, UI-20-15 | API-20-147, 148, 149, 150, 151, 157, 158 |
| UC-20-32 | UI-20-03, UI-20-18 | API-20-001, 109, 110, 111, 112, 113, 114, 115, 116, 117 |
| UC-20-33 | UI-20-12, UI-20-19 | API-20-118, 119, 120, 121, 128, 160 |
| UC-20-34 | UI-20-19 | API-20-119, 122, 123, 124, 125, 126, 127 |
| UC-20-35 | UI-20-20 | API-20-129, 132, 133, 134 |
| UC-20-36 | UI-20-03 | API-20-130, 131, 161 |

: Use case, màn hình và API

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

Mọi use case truy vết tới REQ-20 (BRD). Quy trình BP-08 "Khởi tạo tenant tỉnh mới" có sẵn ở BRD; BP-12 "Sáp nhập tenant" và BP-13 "Phát hành sản phẩm" là đề nghị bổ sung của FRS (FRS mục 2.5), tài liệu này dùng tạm các mã đó. Cột LGC theo FRS mục 2.6 và 11.1.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-20-01 | REQ-20 | BP-08 | — |
| UC-20-02 | REQ-20 | BP-08 | LGC-BUS-031 (gián tiếp) |
| UC-20-03 | REQ-20 | BP-08 | — |
| UC-20-04 | REQ-20 | BP-08 | — |
| UC-20-05 | REQ-20 | BP-08 | LGC-BUS-031 (gián tiếp), LGC-IAM-002 (bước S03) |
| UC-20-06 | REQ-20 | BP-08 | — |
| UC-20-07 | REQ-20 | BP-08 | — |
| UC-20-08 | REQ-20 | BP-08 | — |
| UC-20-09 | REQ-20 | — | LGC-BUS-031 (gián tiếp) |
| UC-20-10 | REQ-20 | — | — |
| UC-20-11 | REQ-20 | — | LGC-IAM-002 (gián tiếp) |
| UC-20-12 | REQ-20 | BP-07 | — |
| UC-20-13 | REQ-20 | — | — |
| UC-20-14 | REQ-20 | — | — |
| UC-20-15 | REQ-20 | BP-07 | — |
| UC-20-16 | REQ-20 | — | — |
| UC-20-17 | REQ-20 | — | — |
| UC-20-18 | REQ-20 | — | — |
| UC-20-19 | REQ-20 | BP-01 | — |
| UC-20-20 | REQ-20 | BP-07 | — |
| UC-20-21 | REQ-20 | — | — |
| UC-20-22 | REQ-20 | — | — |
| UC-20-23 | REQ-20 | — | — |
| UC-20-24 | REQ-20 | BP-12 (đề nghị) | — |
| UC-20-25 | REQ-20 | BP-12 (đề nghị) | — |
| UC-20-26 | REQ-20 | BP-12 (đề nghị) | — |
| UC-20-27 | REQ-20 | BP-12 (đề nghị) | — |
| UC-20-28 | REQ-20 | BP-12 (đề nghị) | — |
| UC-20-29 | REQ-20 | BP-12 (đề nghị) | — |
| UC-20-30 | REQ-20 | BP-01 | LGC-IAM-002 (gián tiếp) |
| UC-20-31 | REQ-20 | BP-03 | LGC-IAM-002 (gián tiếp) |
| UC-20-32 | REQ-20 | BP-13 (đề nghị) | — |
| UC-20-33 | REQ-20 | BP-13 (đề nghị) | — |
| UC-20-34 | REQ-20 | BP-13 (đề nghị) | — |
| UC-20-35 | REQ-20 | BP-07 | — |
| UC-20-36 | REQ-20 | — | — |

: Use case, REQ, quy trình và chức năng hệ cũ

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực (số đuôi `UC-20-nn`). Không FR nào bị bỏ trống. FR-20-045 có hai use case vì phần lập ở UC-20-24 còn phần gửi duyệt và duyệt ở UC-20-25; FR-20-044 (thông báo) được UC-20-23 hiện thực và còn chạm UC-20-20, 21, 22, 28, 29 là nơi sinh ra các lần đổi trạng thái.

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 02 | 025 | 13 | 049 | 27 |
| 002 | 01 | 026 | 14 | 050 | 28 |
| 003 | 01 | 027 | 14 | 051 | 28 |
| 004 | 03 | 028 | 15 | 052 | 29 |
| 005 | 03 | 029 | 15 | 053 | 30 |
| 006 | 03 | 030 | 16 | 054 | 31 |
| 007 | 02 | 031 | 16 | 055 | 30 |
| 008 | 05 | 032 | 14 | 056 | 31 |
| 009 | 06 | 033 | 17 | 057 | 19 |
| 010 | 06 | 034 | 17 | 058 | 30 |
| 011 | 06 | 035 | 18 | 059 | 32 |
| 012 | 07 | 036 | 18 | 060 | 32 |
| 013 | 07 | 037 | 17 | 061 | 33 |
| 014 | 07 | 038 | 20 | 062 | 34 |
| 015 | 04 | 039 | 20 | 063 | 33 |
| 016 | 08 | 040 | 21 | 064 | 11 |
| 017 | 08 | 041 | 21 | 065 | 19 |
| 018 | 11 | 042 | 22 | 066 | 19 |
| 019 | 09 | 043 | 23 | 067 | 35 |
| 020 | 09 | 044 | 23 | 068 | 36 |
| 021 | 10 | 045 | 24, 25 | 069 | 36 |
| 022 | 10 | 046 | 24 | 070 | 35 |
| 023 | 12 | 047 | 25 |  |  |
| 024 | 12 | 048 | 26 |  |  |

: Ma trận FR và use case


## 6. Đặc tả chi tiết use case

Chương này đặc tả 36 use case theo vòng đời tenant: hồ sơ và khởi tạo (UC-20-01…08), cấu hình và cách ly (09…13), hạn mức, sử dụng (14…16), phân hệ và registry (17…19), vòng đời (20…23), sáp nhập (24…29), tổ chức (30, 31), phát hành (32…34), quản trị (35, 36). Mỗi use case một khối 15 mục; nhánh thay thế và ngoại lệ chỉ ghi điều khác với FR, hành vi từng bước xem FR tương ứng. Mục "Truy vết" của mọi khối theo bảng 5.3; mục "Màn hình, API" theo bảng 5.2.

### 6.1. UC-20-01 · Tra cứu và xem chi tiết tenant toàn nền tảng

Đây là điểm xuất phát của mọi thao tác nền tảng: vai trò nền tảng thấy mọi tỉnh trên một màn, biết tỉnh nào đang khởi tạo, lỗi, tạm ngừng, đang sáp nhập, rồi mở chi tiết để thao tác.

::: dac-ta
**Mục tiêu.** Hà (PA) tìm các tỉnh đang `FAILED` hoặc có cảnh báo hạn mức, mở chi tiết `T68` để biết trạng thái, chế độ cách ly, phiên bản đang chạy và các hành động được phép.

**Tác nhân chính.** PA, PO, PAU.

**Tác nhân phụ.** Không (đọc bảng của chính PH-20 bằng vai trò `ph20_platform_app`).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-002, FR-20-003.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Người dùng ở tenant `PLATFORM`, đã xác thực WebAuthn, có `PERM-20-read`.

**Kích hoạt.** Mở UI-20-01, đổi bộ lọc hoặc bấm một dòng để vào UI-20-03.

**Đảm bảo tối thiểu.** Không lộ dữ liệu cá nhân hay dữ liệu nghiệp vụ của tỉnh; chỉ số liệu tổng hợp (FR-00-012). Không đổi trạng thái nào.

**Đảm bảo thành công.** Danh sách đúng bộ lọc kèm `facets`; trang chi tiết có `allowedActions[]` đúng trạng thái và quyền người xem.

**Luồng chính.**
1. Hà mở UI-20-01; hệ thống kiểm tham số lọc (`q`, `status[]`, `isolationMode[]`, `channel`, `quotaAlert`, `size` ≤ 200).
2. Hệ thống truy vấn bảng `tenant` bằng vai trò `ph20_platform_app` với `app.tenant_id = 'PLATFORM'`, ghép lần chạy saga gần nhất, phiên bản đang chạy, cảnh báo hạn mức mở.
3. Hệ thống trả `items[]` và `facets` đếm theo trạng thái, chế độ cách ly, kênh; Hà lọc `status = FAILED` thấy `T68` với `failedStep = S06_EVENTING`.
4. Hà bấm dòng `T68`; hệ thống dựng khối Tổng quan (trạng thái, realm, mẫu và phiên bản mẫu, ngày khai báo, kích hoạt, số HTTT, người dùng, API) và `allowedActions[]`.
5. Hà chuyển tab; tab Lịch sử vòng đời và Kiểm toán tải riêng (UC-20-23, UC-20-36).

**Luồng thay thế.**
- **2a. Xuất CSV.** `format = csv` trả tệp UTF-8 tối đa 1.000 dòng, không có dữ liệu cá nhân.
- **3a. Xem tenant đặc biệt.** `kind = PLATFORM,COMMON` hiện hai tenant với nhãn "Bảo vệ"; trang chi tiết chỉ có tab Tổng quan và Kiểm toán, `allowedActions = []` (UC-20-03).
- **4a. Tenant `MERGED`.** Dải thông tin "Đã sáp nhập vào {đích} từ {ngày}, chuyển tiếp tới {ngày}" kèm liên kết UI-20-10.

**Luồng ngoại lệ.**
- **E1. Tham số sai miền hoặc `size` > 200 (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E2. Không có tenant (bước 4).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- **E3. Tham số `include` sai (bước 4).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."

**Quy tắc áp dụng.** BR-20-003, BR-20-026.

**Màn hình, API.** UI-20-01, UI-20-03; API-20-001, 003; kịch bản TS-20-01.
:::

### 6.2. UC-20-02 · Khai báo tenant mới và kiểm tra sẵn sàng

Khai báo là bước ghi hồ sơ, chưa tạo tài nguyên thật. Wizard năm bước dẫn Hà qua hồ sơ, cách ly và quy mô, mẫu, đầu mối, rồi rà soát kèm kiểm tra sẵn sàng để lỗi chắc chắn xảy ra được phát hiện sớm.

::: dac-ta
**Mục tiêu.** Hà ghi nhận tỉnh `T68` với hồ sơ đầy đủ, biết trước mã trùng, ĐVHC đã có tenant, nền tảng hết sức chứa hay cụm thiếu tài nguyên, rồi lưu hồ sơ hoặc lưu và chạy saga.

**Tác nhân chính.** PA.

**Tác nhân phụ.** PH-07 (danh mục ĐVHC `COMMON`), các phân hệ đích (kiểm sức khỏe), PH-18 (mẫu thư).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-001, FR-20-007.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: LGC-BUS-031 (gián tiếp).

**Tiền điều kiện.** Có `PERM-20-provision`, đã xác thực WebAuthn; danh mục ĐVHC của PH-07 sẵn sàng; có ít nhất một mẫu khởi tạo `PUBLISHED` (UC-20-04).

**Kích hoạt.** Hà bấm "+ Khai báo tenant" ở UI-20-01, đi qua năm bước UI-20-02 rồi bấm "Lưu khai báo" hoặc "Lưu và khởi tạo".

**Đảm bảo tối thiểu.** Không tạo tài nguyên ở hệ khác; không phát sự kiện; mã tenant đã dùng không bao giờ được cấp lại (BR-20-001).

**Đảm bảo thành công.** Có bản ghi tenant `PROVISIONING`, `realm = dh-t68`, đầu mối, hạn mức dự kiến từ mẫu và hồ sơ quy mô; kết quả `readiness` lưu kèm.

**Luồng chính.**
1. Hà nhập mã `T68`, tên, chọn ĐVHC cấp tỉnh ở bước "Hồ sơ"; hệ thống gợi ý mã `T` + mã ĐVHC.
2. Hệ thống kiểm mã theo `^T\d{2}$`, chưa từng dùng kể cả tenant `DECOMMISSIONED`, `MERGED`; kiểm ĐVHC là cấp tỉnh còn hiệu lực và chưa có tenant.
3. Hà chọn chế độ cách ly `SHARED`, hồ sơ quy mô `QM-VUA`, hồ sơ triển khai `HT-B` ở bước "Cách ly và quy mô".
4. Hà chọn mẫu `tinh-chuan` phiên bản 3, xem phân hệ bật sẵn và hạn mức mặc định; bỏ chọn phân hệ không lõi nếu cần.
5. Hà nhập tối thiểu đầu mối `TENANT_ADMIN` và `TECHNICAL` kèm thư công vụ.
6. Ở bước "Rà soát", hệ thống chạy kiểm tra sẵn sàng song song (mã trùng, ĐVHC, sức chứa nền tảng, tài nguyên cụm, mẫu, phân hệ đích), mỗi mục tối đa 10 giây, kết quả `PASS`, `WARN` hoặc `BLOCKER`.
7. Hà bấm "Lưu khai báo"; hệ thống tạo tenant `PROVISIONING`, ghi lịch sử trạng thái và kiểm toán, trả `201` kèm `Location`.

**Luồng thay thế.**
- **7a. Lưu và khởi tạo.** Sau bước 7 hệ thống gọi UC-20-05 với cùng `Idempotency-Key` hậu tố `:run` và chuyển sang UI-20-04.
- **2a. Tenant kiểm thử `T90…T99`.** Bỏ kiểm ĐVHC (gán ĐVHC giả `TEST`), mẫu `test-minimal`, không tính vào sức chứa NFR-00-060.
- **6a. Phân hệ chưa bật theo mẫu** (ví dụ PH-16 ở Đợt 1): mục kiểm `PASS` kèm ghi chú "Bước sẽ SKIPPED".
- **3a. `DEDICATED_CLUSTER`.** Chỉ chọn được khi Đợt 2 bật và có cụm `VERIFIED` (UC-20-08).

**Luồng ngoại lệ.**
- **E1. Mã sai mẫu (bước 2).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E2. Mã đã dùng (bước 2).** ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E3. ĐVHC đã có tenant (bước 2).** ERR-20-011 (409): "Đơn vị hành chính {tên} đã có tenant {mã} đang sử dụng."
- **E4. ĐVHC không phải cấp tỉnh hoặc hết hiệu lực (bước 2).** ERR-20-012 (422): "Đơn vị hành chính {mã} không phải cấp tỉnh hoặc đã hết hiệu lực."
- **E5. Mẫu không dùng được (bước 4).** ERR-20-015 (422): "Mẫu khởi tạo {mã} phiên bản {n} không dùng được: {lý do}."
- **E6. Thiếu đầu mối (bước 5).** ERR-20-021 (422): "Cần đủ đầu mối {vai trò} trước khi {thao tác}."
- **E7. Cụm chưa đủ tài nguyên (bước 6).** ERR-20-014 (422): "Cụm chưa đủ tài nguyên cho hồ sơ {hồ sơ}: thiếu {tài nguyên}."
- **E8. Hết sức chứa nền tảng (bước 6).** ERR-20-013 (422): "Nền tảng đã đạt sức chứa {số} tenant. Liên hệ vận hành hạ tầng để mở rộng."
- **E9. Còn mục `BLOCKER` (bước 7).** ERR-20-017 (422): "Kiểm tra sẵn sàng chưa đạt: {số} mục cần xử lý."
- **E10. PH-07 hoặc phân hệ đích không trả lời (bước 2, 6).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."
- **E11. Dùng lại `Idempotency-Key` cho yêu cầu khác (bước 7).** ERR-20-009 (409): "Khóa chống lặp đã được dùng cho một yêu cầu khác. Tạo yêu cầu mới."

**Quy tắc áp dụng.** BR-20-001, BR-20-002, BR-20-003, BR-20-042.

**Màn hình, API.** UI-20-02, UI-20-04; API-20-002, 005, 006; kịch bản TS-20-02.
:::

### 6.3. UC-20-03 · Sửa hồ sơ, đầu mối, hợp đồng và bảo vệ tenant đặc biệt

Hồ sơ hành chính đổi theo thực tế (đổi tên theo quyết định, đổi người liên hệ, gia hạn hợp đồng) nhưng mã, realm, loại tenant là khóa mọi phân hệ dùng nên bất biến; hai tenant `PLATFORM`, `COMMON` bị chặn ở mọi thao tác ghi.

::: dac-ta
**Mục tiêu.** Hà đổi tên `T68` theo quyết định hành chính, thêm đầu mối `SECURITY`, gia hạn hợp đồng; hệ thống từ chối mọi đổi mã, realm, loại và mọi thao tác ghi lên `PLATFORM`, `COMMON`.

**Tác nhân chính.** PA; PO, PAU xem.

**Tác nhân phụ.** PH-18 (nhắc hạn hợp đồng), PH-13 (cảnh báo bảo mật khi trigger chặn).

**Mức ưu tiên.** M · MVP (FR-20-005 mức S).

**FR hiện thực.** FR-20-004, FR-20-005, FR-20-006.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-admin`; tenant ở `PROVISIONING`, `FAILED`, `ACTIVE` hoặc `SUSPENDED`; không phải tenant đặc biệt; hai bản ghi `PLATFORM`, `COMMON` đã gieo bằng migration nền.

**Kích hoạt.** "Sửa hồ sơ" ở tab Tổng quan, hoặc "+ Đầu mối", "+ Hợp đồng", "Gia hạn" ở tab Hợp đồng và đầu mối của UI-20-03.

**Đảm bảo tối thiểu.** `tenantCode`, `realm`, `kind` không đổi; luôn còn ít nhất một đầu mối `TENANT_ADMIN` và một `TECHNICAL` hoạt động; tên cũ vẫn truy được.

**Đảm bảo thành công.** Hồ sơ mới, `ETag` mới, phiên bản cấu hình mới (`tenant.yaml`) và kiểm toán trong chuỗi tenant.

**Luồng chính.**
1. Hà sửa trường được phép rồi bấm "Lưu"; giao diện mở `CMP-ReasonDialog` nhập lý do (từ 20 ký tự) và mã phiếu.
2. Hệ thống chạy lớp bảo vệ `SpecialTenantGuard`: tenant `PLATFORM`, `COMMON` bị từ chối trước khi vào nghiệp vụ.
3. Hệ thống từ chối trường bất biến `tenantCode`, `realm`, `kind`; kiểm `If-Match`, lý do, phiếu và miền giá trị.
4. Khi đổi tên theo quyết định hành chính, Hà nhập số văn bản `decisionDocNo`; tên cũ lưu vào lịch sử để báo cáo cũ hiển thị đúng.
5. Hà thêm đầu mối hoặc hợp đồng; hệ thống kiểm thư công vụ, điện thoại, vai trò; kiểm sau thao tác vẫn đủ đầu mối bắt buộc; kiểm hợp đồng không chồng thời hạn.
6. Hệ thống lưu, ghi `tenant.yaml` qua UC-20-09, phát EVT-20-09 (`changeKind = TENANT_PROFILE`), ghi kiểm toán.
7. Hằng ngày bộ lập lịch nhắc qua PH-18 khi hợp đồng còn 60, 30, 7 ngày tới PA và đầu mối `LEADER`.

**Luồng thay thế.**
- **5a. Ngừng đầu mối `TENANT_ADMIN` sau khi tenant `ACTIVE`.** Không đổi tài khoản quản trị tỉnh ở realm; giao diện nhắc TA tự quản người dùng ở PH-12.
- **4a. Đổi `scaleProfile`.** Hệ thống chỉ gợi ý hạn mức mới, không tự đổi hạn mức hợp đồng; giao diện mở UC-20-14.
- **2a. Sửa cấu hình nền tảng của `PLATFORM`** (host quản trị, vùng DR) chỉ qua UC-20-09 với hai PA theo đường thay đổi hạ tầng D04-02.

**Luồng ngoại lệ.**
- **E1. Ghi lên tenant đặc biệt (bước 2).** ERR-20-010 (403): "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này." Trigger CSDL chặn lớp thứ hai cũng trả mã này kèm cảnh báo bảo mật tới PH-13.
- **E2. Đổi thuộc tính bất biến (bước 3).** ERR-20-068 (422): "Không đổi được {thuộc tính} của tenant sau khai báo."
- **E3. Thiếu lý do, phiếu (bước 1).** ERR-20-008 (422): "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu."
- **E4. Phiên bản lệch (bước 3).** ERR-20-005 (412): "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."
- **E5. Tenant `MERGED`, `DECOMMISSIONED` (bước 3).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E6. Định dạng sai (bước 5).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E7. Thiếu đầu mối bắt buộc sau thao tác (bước 5).** ERR-20-021 (422): "Cần đủ đầu mối {vai trò} trước khi {thao tác}."
- **E8. Hợp đồng chồng thời hạn hoặc ngày sai (bước 5).** ERR-20-022 (422): "Hợp đồng {số}: {lý do}."

**Quy tắc áp dụng.** BR-20-001, BR-20-003, BR-20-009, BR-20-010, BR-20-039.

**Màn hình, API.** UI-20-03; API-20-004, 007, 008, 009, 010, 011, 012; kịch bản TS-20-03.
:::

### 6.4. UC-20-04 · Quản lý mẫu khởi tạo có phiên bản

Mọi tỉnh mới phải giống nhau trừ phần cấu hình, nên "một tỉnh chuẩn trông như thế nào" được gói thành mẫu có phiên bản bất biến sau phát hành.

::: dac-ta
**Mục tiêu.** Hà tạo mẫu `tinh-chuan`, mở phiên bản 4 từ phiên bản 3, sửa hạn mức và phân hệ, so sánh hai phiên bản rồi phát hành; phiên bản cũ ngừng chọn được cho tỉnh mới.

**Tác nhân chính.** PA; PO, PAU xem.

**Tác nhân phụ.** PH-07 (kiểm gói danh mục nền tồn tại).

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-20-015.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-admin`; danh mục phân hệ có sẵn (UC-20-17).

**Kích hoạt.** UI-20-21: "+ Mẫu", "Tạo phiên bản mới", "Sửa", "Phát hành", "Ngừng", "So sánh".

**Đảm bảo tối thiểu.** Phiên bản `PUBLISHED` không bao giờ bị sửa; tenant đã tạo không tự đổi khi mẫu có phiên bản mới.

**Đảm bảo thành công.** Phiên bản có `contentHash`, trạng thái `PUBLISHED`; lần chạy saga sau ghi đúng `templateCode` và `version`.

**Luồng chính.**
1. Hà tạo mẫu (mã `^[a-z][a-z0-9-]{2,62}$`) hoặc mở phiên bản `n+1` sao từ phiên bản `PUBLISHED` mới nhất.
2. Hà sửa phiên bản `DRAFT`: phân hệ bật, hạn mức mỗi hồ sơ quy mô, gói danh mục nền, tổ chức gieo, bộ chỉ tiêu, cờ tính năng.
3. Hệ thống kiểm lược đồ: phân hệ có ở danh mục, đủ phụ thuộc bắt buộc, hạn mức trong trần nền tảng, gói nền tồn tại ở PH-07, tổ chức gieo có mã duy nhất.
4. Hà bấm "So sánh"; `CMP-DiffViewer` hiển thị khác biệt theo khối giữa phiên bản 3 và 4.
5. Hà bấm "Phát hành"; hệ thống tính `contentHash`, chuyển `PUBLISHED`.

**Luồng thay thế.**
- **5a. Ngừng phiên bản.** Hà bấm "Ngừng": phiên bản `RETIRED` không chọn được cho khai báo mới, tenant đã dùng giữ nguyên.
- **1a. Tenant muốn dùng mẫu mới.** Không tự đổi; đi qua khởi tạo bổ sung (UC-20-08).

**Luồng ngoại lệ.**
- **E1. Mã trùng (bước 1).** ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E2. Thiếu phụ thuộc phân hệ (bước 3).** Lỗi dùng mã của FR: ERR-20-033 (422): "Phân hệ {phân hệ} cần {phụ thuộc} được bật trước."
- **E3. Hạn mức ngoài trần (bước 3).** ERR-20-029 (422): "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}."
- **E4. Sửa phiên bản đã phát hành (bước 2).** ERR-20-063 (409): "Phiên bản {n} của mẫu {mã} đã phát hành, không sửa được. Tạo phiên bản mới."
- **E5. Ngừng phiên bản mặc định duy nhất (bước 5a).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E6. Dữ liệu sai lược đồ (bước 3).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."

**Quy tắc áp dụng.** BR-20-017, BR-20-042.

**Màn hình, API.** UI-20-21; API-20-025, 026, 027, 028, 029, 030, 031, 032; kịch bản TS-20-04.
:::

### 6.5. UC-20-05 · Chạy saga khởi tạo tenant

Saga biến hồ sơ thành tenant dùng được: mười bảy bước tự động, mỗi bước lũy đẳng, bước bất đồng bộ chờ phân hệ báo, tổng thời gian mục tiêu không quá 60 phút ở chế độ `SHARED`.

::: dac-ta
**Mục tiêu.** Hà bấm "Khởi tạo" cho `T68`; hệ thống tạo realm, bí mật, bucket, topic, route, kho luồng, danh mục nền, tổ chức, phân hệ rồi chuyển sang kiểm tra khói, không cần thao tác tay giữa các bước.

**Tác nhân chính.** PA.

**Tác nhân phụ.** Bộ thực thi saga; PH-12, PH-13, PH-07, PH-10, PH-03, PH-04, PH-06, PH-16 và các phân hệ lõi bật theo mẫu; OpenBao, Ceph RGW, kho Git.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-008.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: LGC-BUS-031 (gián tiếp), LGC-IAM-002 (bước S03).

**Tiền điều kiện.** Có `PERM-20-provision`; tenant `PROVISIONING` (`INITIAL`); không có lần chạy dang dở; kiểm tra sẵn sàng đạt.

**Kích hoạt.** Hà bấm "Khởi tạo" ở UI-20-03 hoặc "Lưu và khởi tạo" ở UI-20-02.

**Đảm bảo tối thiểu.** Mỗi tenant tối đa một lần chạy chưa kết thúc (BR-20-006); bước lỗi để lại trạng thái đủ để thử lại hoặc bù trừ, không để tài nguyên mồ côi không ghi dấu.

**Đảm bảo thành công.** Lần chạy `SUCCEEDED`, 17 bước `SUCCEEDED` hoặc `SKIPPED`, tenant `ACTIVE` sau UC-20-07, tổng thời gian ≤ `20.provision.timeout-minutes`.

**Luồng chính.**
1. Hệ thống kiểm tenant ở trạng thái phù hợp và không có lần chạy dang dở, chạy lại kiểm tra sẵn sàng (UC-20-02).
2. Hệ thống tạo lần chạy `PENDING` với sổ 17 bước, đánh `SKIPPED` bước không áp dụng (`S07_DATABASE` khi `SHARED`, `S12_SEED_MDM` khi PH-06 tắt, `S14_KPI` khi PH-16 tắt), ghi phiên bản mẫu, trả `202`.
3. Bộ thực thi lấy khóa ShedLock `provision:T68`, chạy `S01_RECORD` … `S05_BUCKETS`; mỗi bước gọi bên thực hiện với `Idempotency-Key = {runId}:{stepCode}`.
4. Sau `S05`, hệ thống phát EVT-20-01; các bước bất đồng bộ `S06`, `S09`, `S10`, `S12` sang `WAITING_REPORT`, trong khi `S07`, `S08` chạy đồng bộ.
5. PH-10, PH-03, PH-04, PH-06 báo `SUCCEEDED` qua API-20-166; hệ thống chạy `S11_SEED_RDM`, `S13_ORG_SEED`, `S14_KPI`.
6. Ở `S15_MODULES`, hệ thống phát EVT-20-07 cho từng phân hệ không lõi bật theo mẫu và chờ báo; phân hệ lõi đánh dấu `ENABLED` ngay.
7. Hệ thống chạy `S16_SMOKE` và `S17_ACTIVATE` (UC-20-07); lần chạy `SUCCEEDED`.

**Luồng thay thế.**
- **3a. `DEDICATED_DB`.** `S07_DATABASE` tạo cụm CloudNativePG, chạy migration, ghi bảng định tuyến; `S08`…`S17` dùng chuỗi kết nối mới.
- **5a. Phân hệ báo `SKIPPED`** (PH-06 chưa có gói nền): bước `SKIPPED`, saga tiếp tục.
- **3b. Bước lỗi.** Hệ thống tự thử lại tối đa `20.provision.step-retry-max` lần giãn cách 10, 30, 90 giây; hết lần thì bước, lần chạy và tenant sang `FAILED`, phát EVT-20-02, báo PA qua PH-18 (xử lý ở UC-20-06).

**Luồng ngoại lệ.**
- **E1. Tenant sai trạng thái (bước 1).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E2. Đã có lần chạy dang dở (bước 1).** ERR-20-016 (409): "Tenant {mã} đang có lần khởi tạo {runId} chưa kết thúc."
- **E3. Kiểm tra sẵn sàng chưa đạt (bước 1).** ERR-20-017 (422): "Kiểm tra sẵn sàng chưa đạt: {số} mục cần xử lý."
- **E4. Tenant đặc biệt (bước 1).** ERR-20-010 (403): "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."
- **E5. Bên thực hiện báo lỗi (bước 3 đến 6, chạy nền).** ERR-20-107: "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}." Hiện ở dòng bước UI-20-04.
- **E6. Bước bất đồng bộ quá hạn (bước 4 đến 6, chạy nền).** ERR-20-106: "Bước {bước} chưa nhận báo cáo từ {bên thực hiện} sau {phút} phút."
- **E7. Tổng thời gian quá hạn (chạy nền).** ERR-20-108: "Khởi tạo vượt thời gian cho phép {phút} phút." Lần chạy chuyển `FAILED` tại bước đang chạy, không tự hủy.
- **E8. Phân hệ báo tiến độ sai bước hoặc sai trạng thái (bước 4 đến 6, bên gọi máy).** ERR-20-105 (409): "Báo tiến độ bước {bước} không khớp trạng thái {trạng thái}."

**Quy tắc áp dụng.** BR-20-004, BR-20-005, BR-20-006, BR-20-007, BR-20-042.

**Màn hình, API.** UI-20-02, UI-20-03, UI-20-04; API-20-013, 166; kịch bản TS-20-05.
:::

```{.mermaid caption="Trình tự chạy saga khởi tạo tenant"}
sequenceDiagram
  actor Ha as Hà (PA)
  participant K as PH-20 saga
  participant D as PH-12, OpenBao, Ceph
  participant P as PH-10, PH-03, PH-04
  Ha->>K: Khởi tạo T68
  K->>K: Kiểm sẵn sàng, tạo sổ 17 bước
  K->>D: S01 đến S05 với Idempotency-Key runId:stepCode
  K->>P: EVT-20-01 tenant.created
  P-->>K: Báo S06, S09, S10 SUCCEEDED qua API-20-166
  K->>P: EVT-20-07 bật phân hệ ở S15
  P-->>K: Báo S15 xong
  K->>K: S16 kiểm tra khói rồi S17 kích hoạt
```

Hình cho thấy PH-20 tự chạy các bước đồng bộ, phát một sự kiện rồi chờ các phân hệ khác báo xong; không bước nào cần người can thiệp trừ khi lỗi.

### 6.6. UC-20-06 · Theo dõi saga, thử lại, bù trừ và hủy khởi tạo

Hà và Tuấn theo dõi sổ bước thời gian thực để can thiệp đúng lúc; khi một bước hết lần tự thử, người xử lý quyết định thử lại, bỏ qua bước không bắt buộc, hoặc bù trừ và hủy.

::: dac-ta
**Mục tiêu.** Khi `T68` dừng ở `S06_EVENTING` vì PH-10 chưa lên, Hà thử lại từ bước lỗi sau khi PH-10 hồi phục mà không làm lại bước đã xong; nếu tỉnh hoãn hợp đồng thì Hà bù trừ và hủy để không để lại realm, bucket mồ côi.

**Tác nhân chính.** PA (thao tác); PO (theo dõi).

**Tác nhân phụ.** Bộ thực thi saga, các bên thực hiện bước, PH-18 (báo PA).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-009, FR-20-010, FR-20-011.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có lần chạy; thử lại cần lần chạy `FAILED`; bù trừ, hủy cần lần chạy `FAILED` hoặc `PENDING` và tenant chưa từng `ACTIVE` (lần `INITIAL`).

**Kích hoạt.** Mở UI-20-04; bấm "Thử lại từ bước lỗi", "Thử lại bước", "Bỏ qua bước", "Bù trừ", "Hủy khởi tạo".

**Đảm bảo tối thiểu.** Bước đã `SUCCEEDED` không bị làm lại; mọi lệnh nhập `Idempotency-Key`, mỗi nút nguy hiểm dùng `CMP-ReasonDialog` hoặc `CMP-ConfirmDialog` gõ lại mã tenant.

**Đảm bảo thành công.** Thử lại: lần chạy `RUNNING` rồi `SUCCEEDED`. Bù trừ: mọi bước `COMPENSATED`, lần chạy `COMPENSATED`, hủy thì `CANCELLED` và tenant `DECOMMISSIONED` (mã không tái dùng).

**Luồng chính.**
1. Hà mở UI-20-04; giao diện mở luồng SSE (API-20-016) và hiện `CMP-Steps` 17 bước, thời gian từng bước, bên thực hiện, số lần thử, ước thời gian còn lại theo trung vị 20 lần gần nhất.
2. Hà thấy `S06_EVENTING` `FAILED` với ERR-20-107; PH-10 đã lên lại.
3. Hà bấm "Thử lại từ bước lỗi"; hệ thống kiểm lần chạy `FAILED` và bước `FAILED`, kiểm sức khỏe bên thực hiện (cảnh báo nhưng vẫn cho thử).
4. Hệ thống đặt lại số lần tự thử, chuyển lần chạy `RUNNING`, tenant `PROVISIONING`, gọi lại bước với cùng `Idempotency-Key`; bên thực hiện trả kết quả cũ phần đã làm.
5. Saga tiếp tục như UC-20-05 tới khi `SUCCEEDED`.

**Luồng thay thế.**
- **3a. Bỏ qua bước.** Chỉ `S12_SEED_MDM`, `S14_KPI` và từng phân hệ ở `S15_MODULES`: bước `SKIPPED` kèm lý do; phân hệ đó `FAILED` ở EN-20-20, bật lại sau bằng UC-20-17.
- **3b. Bù trừ và hủy.** Hà bấm "Bù trừ" hoặc "Hủy khởi tạo", gõ lại `T68`; hệ thống chuyển `COMPENSATING`, bù ngược từng bước với khóa `{runId}:{stepCode}:compensate`, phát EVT-20-04 (`DECOMMISSIONED`, `cause = PROVISIONING_CANCELLED`); `S05_BUCKETS` chỉ xóa bucket rỗng, bucket có đối tượng đánh dấu `MANUAL_CLEANUP`.
- **3c. Lần chạy `SUPPLEMENT` lỗi.** Bù trừ chỉ gỡ phần bổ sung, tenant giữ `ACTIVE`.
- **1a. SSE bị proxy chặn.** Giao diện kéo API-20-015 mỗi 5 giây.

**Luồng ngoại lệ.**
- **E1. Lần chạy không ở trạng thái cho phép (bước 3, 3b).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E2. Bước không thử lại hoặc bỏ qua được (bước 3).** ERR-20-018 (409): "Không thể thử lại bước {bước}: {lý do}."
- **E3. Tenant đã từng hoạt động (bước 3b).** ERR-20-019 (409): "Không thể bù trừ: {lý do}."
- **E4. Gõ sai mã xác nhận (bước 3b).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E5. Không có lần chạy (bước 1).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- **E6. Bù trừ một bước lỗi (chạy nền).** ERR-20-107: "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}." Bước giữ `COMPENSATING`, lần chạy `FAILED`, Hà thử bù lại.

**Quy tắc áp dụng.** BR-20-001, BR-20-005, BR-20-006, BR-20-007, BR-20-009.

**Màn hình, API.** UI-20-04; API-20-014, 015, 016, 017, 018, 019, 020, 021; kịch bản TS-20-06.
:::

### 6.7. UC-20-07 · Kiểm tra khói, kích hoạt, bàn giao và đo thời gian khởi tạo

Tenant chỉ `ACTIVE` khi chứng minh được dùng được và cách ly đúng; sau đó quản trị tỉnh nhận thư bàn giao và thời gian khởi tạo được đẩy cho PH-16 làm KPI-12.

::: dac-ta
**Mục tiêu.** Hệ thống chạy bốn ca khói cho `T68`, kích hoạt, gửi thư bàn giao cho Mai và các đầu mối, rồi đo thời gian khởi tạo đẩy sang PH-16.

**Tác nhân chính.** Hệ thống (bước `S16_SMOKE`, `S17_ACTIVATE`); PA chạy lại, kích hoạt tay.

**Tác nhân phụ.** PH-12 (tài khoản tạm), PH-03 (APISIX), PH-10, PH-18 (thư), PH-16 (`kpi.ingest`).

**Mức ưu tiên.** M · MVP (FR-20-014 mức S).

**FR hiện thực.** FR-20-012, FR-20-013, FR-20-014.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** `S01`…`S15` `SUCCEEDED` hoặc `SKIPPED`; `20.smoke.enabled = true`.

**Kích hoạt.** Bộ thực thi tới `S16`; hoặc Hà bấm "Chạy lại kiểm tra khói" hay "Kích hoạt" (mẫu `activation = MANUAL`) ở UI-20-04.

**Đảm bảo tối thiểu.** Tenant không `ACTIVE` nếu còn ca khói lỗi; phát hiện rò rỉ thì chặn kích hoạt và mở sự cố mức 1; tài khoản tạm luôn bị xóa.

**Đảm bảo thành công.** Tenant `ACTIVE`, `activated_at` ghi, EVT-20-03 phát, thư bàn giao đã gửi, quan sát `thoi-gian-khoi-tao-tenant` đã tới PH-16 hoặc nằm ở hàng đợi thử lại.

**Luồng chính.**
1. Hệ thống tạo tài khoản máy `smoke-{runId}` (hạn 30 phút) và HTTT giả lập ở realm của tenant qua PH-12.
2. Ca `LOGIN_ADMIN`: lấy token quản trị tỉnh đầu tiên, kiểm claim `tenant = T68`. Ca `API_SAMPLE`: gọi `GET /api/tenant/v1/context` qua APISIX bằng host của tenant, kỳ vọng `200`.
3. Ca `EVENT_SAMPLE`: phát và đọc lại một sự kiện trong 30 giây. Ca `CROSS_TENANT_LEAK`: token `T68` đọc tài nguyên cài sẵn của `T99`, kỳ vọng `404`.
4. Cả bốn ca đạt: hệ thống lưu kết quả (EN-20-12), xóa tài khoản tạm, bước `S16` `SUCCEEDED`.
5. Bước `S17`: hệ thống chuyển tenant `ACTIVE`, phát EVT-20-03 và EVT-20-04, gửi thư bàn giao mẫu `ph20-handover` tới đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL`.
6. Hệ thống tính `provisionMinutes` và `leadTimeWorkingHours` (từ `declaredAt` tới `activatedAt` theo giờ làm việc), gọi API-16-030 với `idempotencyRef = {runId}`.
7. Tuấn xem thời gian khởi tạo theo tenant, theo bước (trung vị, p95) ở UI-20-20.

**Luồng thay thế.**
- **5a. Kích hoạt hẹn giờ.** `activateAt` trong tương lai: `S17` ở `WAITING_REPORT` tới giờ; Hà hủy hẹn để kích hoạt ngay. "Gửi lại thư bàn giao" tối đa 3 lần mỗi ngày.
- **4a. Tenant kiểm thử.** `20.smoke.enabled = false` chỉ cho `T90…T98`: bước `SKIPPED` kèm cảnh báo; tenant thật không tắt được.
- **6a. PH-16 chưa bật hoặc lỗi.** Quan sát giữ ở hàng đợi riêng, thử lại mỗi giờ tới 30 ngày.
- **1a. Chạy lại khi tenant đã `ACTIVE`.** Chạy độc lập, không đổi trạng thái.

**Luồng ngoại lệ.**
- **E1. Ca khói lỗi (bước 2 đến 4, chạy nền).** ERR-20-117: "Ca kiểm tra khói {ca} lỗi: {chi tiết}." Bước và lần chạy `FAILED`.
- **E2. Phát hiện rò rỉ (bước 3).** ERR-20-111: "Phát hiện rò rỉ chéo tenant ở {API}." Mở sự cố mức 1 ở PH-13, chặn kích hoạt.
- **E3. Kích hoạt khi khói chưa đạt (bước 5).** ERR-20-020 (422): "Kiểm tra khói chưa đạt ({số} ca lỗi). Không thể kích hoạt tenant."
- **E4. Tenant sai trạng thái (bước 5, 1a).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E5. Đang có lần chạy khác (1a).** ERR-20-016 (409): "Tenant {mã} đang có lần khởi tạo {runId} chưa kết thúc."
- **E6. PH-18 không gửi được thư (bước 5).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." ({tên} = Thông báo); không chặn kích hoạt, hiện nút "Gửi lại".
- **E7. Khoảng thống kê quá dài (bước 7).** ERR-20-032 (400): "Khoảng thời gian tối đa là {số} ngày."

**Quy tắc áp dụng.** BR-20-004, BR-20-038, BR-20-039, BR-20-041.

**Màn hình, API.** UI-20-04, UI-20-20; API-16-030; API-20-015, 022, 023, 024; kịch bản TS-20-07.
:::

```{.mermaid caption="Trình tự kiểm tra khói, kích hoạt và đo KPI-12"}
sequenceDiagram
  participant K as PH-20
  participant I as PH-12, APISIX
  participant H as PH-18
  participant Q as PH-16
  K->>I: Tạo tài khoản smoke và chạy 4 ca khói
  I-->>K: LOGIN_ADMIN, API_SAMPLE, EVENT_SAMPLE đạt, leak trả 404
  K->>K: Tenant ACTIVE, phát EVT-20-03
  K->>H: Thư bàn giao tới đầu mối
  K->>Q: API-16-030 thoi-gian-khoi-tao-tenant
  Q-->>K: 202 hoặc xếp hàng thử lại
```

Hình cho thấy kích hoạt chỉ xảy ra sau khi cả bốn ca đạt; thư bàn giao và đẩy KPI-12 là hậu quả không chặn.

### 6.8. UC-20-08 · Khởi tạo bổ sung và khởi tạo cụm riêng

Hai tình huống mở rộng saga: đưa tenant đã `ACTIVE` lên cùng mức khi nền tảng thêm bước hoặc phân hệ, và khởi tạo tỉnh có cụm Kubernetes riêng (Đợt 2).

::: dac-ta
**Mục tiêu.** Hà xem trước các tenant thiếu bước `S15` mới, lập một đợt khởi tạo bổ sung có sóng; với tỉnh tự vận hành tại chỗ, Hà đăng ký, kiểm tra cụm đích và sinh gói cấu hình để cụm tỉnh chạy saga cục bộ.

**Tác nhân chính.** PA.

**Tác nhân phụ.** Đơn vị vận hành của tỉnh (cung cấp cụm, kích hoạt đồng bộ), Argo CD tại cụm đích, PH-18.

**Mức ưu tiên.** S · MVP với bổ sung hàng loạt (FR-20-016), Đợt 2 với cụm riêng (FR-20-017).

**FR hiện thực.** FR-20-016, FR-20-017.

**Truy vết.** REQ-20; quy trình BP-08; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-provision`. Bổ sung: có tenant `ACTIVE` thiếu bước. Cụm riêng: `20.dedicated-cluster.enabled = true`, cụm có Argo CD, CloudNativePG, Kafka, kho S3, Keycloak, OpenBao theo D03-09.

**Kích hoạt.** "Khởi tạo bổ sung" ở UI-20-04 hoặc "Khởi tạo bổ sung hàng loạt" ở UI-20-20; "+ Đăng ký cụm", "Kiểm tra cụm", "Sinh gói cấu hình" ở UI-20-21, UI-20-03.

**Đảm bảo tối thiểu.** Tenant bổ sung giữ `ACTIVE` suốt quá trình, không gián đoạn phục vụ; tenant lỗi không chặn tenant khác; cụm chưa `VERIFIED` không được chọn.

**Đảm bảo thành công.** Các lần chạy `SUPPLEMENT` `SUCCEEDED` chỉ với bước được chọn; hoặc cụm `VERIFIED` và tenant `DEDICATED_CLUSTER` khởi tạo xong, trạng thái báo ngược về qua API-20-166.

**Luồng chính.**
1. Hà bấm "Xem trước"; hệ thống liệt kê tenant thiếu bước, ước thời gian, loại `SUSPENDED`, `MERGING`, `MERGED` và tenant đang có lần chạy (kèm lý do).
2. Hà xác nhận; hệ thống tạo một đợt gồm các lần chạy `SUPPLEMENT`, mỗi lần chỉ có bước được chọn, các bước khác `SKIPPED`, phát EVT-20-07 cho phân hệ được bổ sung.
3. Hệ thống chạy tối đa `waveSize` lần cùng lúc theo cơ chế UC-20-05; lần chạy lỗi của tenant nào xử lý bằng UC-20-06.
4. Với cụm riêng: Hà đăng ký cụm (`REGISTERED`), bấm "Kiểm tra cụm"; hệ thống kiểm phiên bản Kubernetes, CRD, StorageClass, chính sách mạng, dung lượng qua tài khoản chỉ đọc, ghi `VERIFIED` hoặc danh sách thiếu.
5. Hà khai báo `T68` chế độ `DEDICATED_CLUSTER` với cụm `VERIFIED` (UC-20-02); PH-20 ghi Git ở `clusters/{clusterCode}/tenants/T68/`.
6. Với cụm chỉ cho kéo, Hà bấm "Sinh gói cấu hình"; hệ thống dựng gói `tar.zst` (overlay Kustomize, giá trị Helm, sổ bước, chữ ký) và liên kết tải 24 giờ kèm `sha256`.

**Luồng thay thế.**
- **1a. Bổ sung phân hệ cho một tenant.** Tương đương UC-20-17 với bước `S15_MODULES`.
- **6a. Cụm không kết nối ngược.** Bộ thực thi cục bộ sinh tệp báo cáo ký; Hà tải lên UI-20-04, PH-20 kiểm chữ ký rồi áp như báo tiến độ.

**Luồng ngoại lệ.**
- **E1. Không tenant nào cần bổ sung (bước 1).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E2. Bước không hỗ trợ bổ sung `S01`, `S02`, `S03`, `S16`, `S17` (bước 2).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E3. Một tenant lỗi (bước 3, chạy nền).** ERR-20-107: "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}."
- **E4. Cụm chưa đạt (bước 4).** ERR-20-064 (422): "Cụm {mã} chưa đạt yêu cầu: {danh sách thiếu}."
- **E5. Mã cụm trùng (bước 4).** ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E6. Đợt 2 chưa bật (bước 4, 5).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E7. Tệp báo cáo sai chữ ký (6a).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."

**Quy tắc áp dụng.** BR-20-005, BR-20-006, BR-20-009, BR-20-035, BR-20-040.

**Màn hình, API.** UI-20-02, UI-20-03, UI-20-04, UI-20-20, UI-20-21; API-20-013, 033, 034, 035, 036, 037, 038; kịch bản TS-20-08.
:::

### 6.9. UC-20-09 · Cấu hình nền tảng của tenant và ghi vào kho GitOps

Cấu hình quyết định cách tỉnh được phục vụ (host, tiền tố API, hồ sơ triển khai, vùng DR) nằm ở một nơi có phiên bản; kho Git là trạng thái mong muốn, Argo CD áp xuống.

::: dac-ta
**Mục tiêu.** Hà đổi tiền tố API công bố của `T68`; hệ thống ghi commit có chữ ký vào `tenants/T68/`, chờ Argo CD áp, rồi báo PH-03, PH-12, `dh-console` bằng EVT-20-09.

**Tác nhân chính.** PA; PO, PAU xem.

**Tác nhân phụ.** Thành phần `tenant-config` (tài khoản `svc-ph20-gitops`), kho `dh-tenant-config`, Argo CD, PH-03.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-019, FR-20-020.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: LGC-BUS-031 (gián tiếp).

**Tiền điều kiện.** Có `PERM-20-admin`; tenant không `DECOMMISSIONED`; kho Git truy cập được, khóa ký ở OpenBao.

**Kích hoạt.** "Sửa" ở tab "Cấu hình nền tảng" của UI-20-03; hoặc một FR khác gọi `ConfigWriter.apply` (hồ sơ, cài đặt tỉnh, hạn mức, phân hệ, cờ, kênh, nâng cấp).

**Đảm bảo tối thiểu.** `realm` không đổi; không sửa khi cấu hình đang lệch; nếu Git lỗi, giao dịch nghiệp vụ vẫn lưu và bản ghi outbox thử lại, trạng thái `PENDING_COMMIT`.

**Đảm bảo thành công.** `syncStatus = APPLIED` có `commitSha`, `appliedAt`; EVT-20-09 phát kèm `configVersionNo`.

**Luồng chính.**
1. Hệ thống trả cấu hình hiện hành kèm trạng thái ghi Git và áp Argo CD.
2. Hà sửa tiền tố; hệ thống kiểm host, tiền tố `^/[a-z0-9-]{2,30}$`, không trùng tenant khác, không có lệch chưa xử lý.
3. Hệ thống sinh nội dung tệp theo JSON Schema, commit vào nhánh chính với thông điệp `ph20(T68): PLATFORM_CONFIG [ticketRef]`, ký bằng khóa dịch vụ; `syncStatus = COMMITTED`.
4. Hệ thống theo dõi ứng dụng Argo CD của tenant; `Synced` và `Healthy` thì ghi `APPLIED`.
5. Hệ thống phát EVT-20-09; PH-03 dựng lại route theo FR-03-039.

**Luồng thay thế.**
- **3a. Xung đột đẩy.** Hệ thống kéo lại, sinh lại tệp từ CSDL và thử tối đa 3 lần.
- **2a. Đổi `runtimeNamespaceMode` sang `DEDICATED_NS`** khi tenant có hơn 50 luồng: PH-04 nghe EVT-20-09 để di chuyển luồng.

**Luồng ngoại lệ.**
- **E1. Host, tiền tố trùng (bước 2).** ERR-20-067 (409): "Tên miền hoặc tiền tố {giá trị} đã được tenant khác dùng."
- **E2. Đổi realm (bước 2).** ERR-20-068 (422): "Không đổi được {thuộc tính} của tenant sau khai báo."
- **E3. Cấu hình đang lệch (bước 2).** ERR-20-025 (409): "Cấu hình tenant {mã} đang lệch chưa xử lý. Đối chiếu trước khi sửa."
- **E4. Không đẩy được lên Git (bước 3).** ERR-20-024 (502): "Không ghi được cấu hình vào kho GitOps. Thử lại sau, nếu lặp lại báo vận hành nền tảng."
- **E5. Argo CD không áp quá 10 phút (bước 4, chạy nền).** ERR-20-109: "Argo CD không áp được cấu hình {phiên bản}: {lý do}." `syncStatus = SYNC_FAILED`, cảnh báo PO.

**Quy tắc áp dụng.** BR-20-001, BR-20-009, BR-20-010, BR-20-039.

**Màn hình, API.** UI-20-03, UI-20-17; API-20-039, 040; kịch bản TS-20-09.
:::

```{.mermaid caption="Trình tự ghi cấu hình tenant vào GitOps"}
sequenceDiagram
  actor Ha as Hà (PA)
  participant K as PH-20 tenant-config
  participant G as Kho Git
  participant A as Argo CD
  participant S as PH-03, PH-12
  Ha->>K: Sửa cấu hình T68 kèm lý do và phiếu
  K->>K: Kiểm host, tiền tố, lệch
  K->>G: Commit có chữ ký vào tenants/T68
  A->>G: Kéo thay đổi và áp
  A-->>K: Synced, Healthy
  K->>S: EVT-20-09 config-changed
```

Hình cho thấy cơ sở dữ liệu là nguồn sinh còn Git là trạng thái mong muốn có ký; sự kiện chỉ phát sau khi Argo CD báo đã áp.

### 6.10. UC-20-10 · Xem phiên bản, so sánh, khôi phục cấu hình và xử lý lệch

Khi một thay đổi gây sự cố hoặc ai đó sửa tay trên cụm, nền tảng cần xem lại lịch sử, so sánh, khôi phục và phát hiện lệch giữa Git và trạng thái thực.

::: dac-ta
**Mục tiêu.** Hà so sánh phiên bản 12 và 14 của cấu hình `T68`, khôi phục phiên bản 12; bộ lập lịch phát hiện quota Kafka bị sửa tay, Hà chọn áp lại hoặc nhận vào Git.

**Tác nhân chính.** PA; PO, PAU xem.

**Tác nhân phụ.** Bộ lập lịch PH-20, Argo CD, PH-12 (API-12-082, 083), PH-13 (cảnh báo).

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-20-021, FR-20-022.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-admin` để khôi phục, xử lý lệch; tenant `ACTIVE`, `SUSPENDED` hoặc `MERGING` cho đối chiếu.

**Kích hoạt.** UI-20-17: "So sánh", "Khôi phục phiên bản này", "Đối chiếu ngay", "Áp lại", "Nhận vào Git"; bộ lập lịch mỗi `20.drift.check-interval` (PT1H).

**Đảm bảo tối thiểu.** Khôi phục không xóa lịch sử (áp như thay đổi mới); không sinh lệch giả khi không đọc được trạng thái (`UNKNOWN`).

**Đảm bảo thành công.** Phiên bản khôi phục có `configVersionNo` mới; bản ghi lệch về `IN_SYNC` ở lần đối chiếu sau.

**Luồng chính.**
1. Hà mở UI-20-17; hệ thống trả danh sách phiên bản (số, thời điểm, người, tệp đổi, lý do, `syncStatus`).
2. Hà chọn hai phiên bản, "So sánh"; `CMP-DiffViewer` hiển thị khác biệt theo khóa YAML.
3. Hà bấm "Khôi phục phiên bản này"; hệ thống kiểm tương thích lược đồ, không chạm thuộc tính bất biến, áp qua UC-20-09, phát EVT-20-09.
4. Bộ lập lịch đọc trạng thái Argo CD (`OutOfSync`) và gọi API đối chiếu của phân hệ, sinh bản ghi `DRIFTED`; khóa an ninh (ACL, chính sách, realm) cảnh báo PO ngay, khóa khác gộp báo hằng ngày.
5. Hà chọn `REAPPLY` (Argo CD đồng bộ lại hoặc API-12-083) hoặc `ACCEPT` (ghi giá trị thực vào CSDL và Git).

**Luồng thay thế.**
- **2a. Trường đã đổi tên ở phiên bản cũ.** Hệ thống chạy bộ chuyển đổi lược đồ trước khi so sánh; không chuyển được thì chỉ cho xem tệp gốc.
- **4a. Argo CD không khả dụng.** `DriftStatus = UNKNOWN`, không sinh lệch.

**Luồng ngoại lệ.**
- **E1. Không khôi phục được (bước 3).** ERR-20-026 (422): "Không khôi phục được phiên bản cấu hình {n}: {lý do}."
- **E2. Không có phiên bản (bước 2).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- **E3. `ACCEPT` với khóa an ninh hoặc đang đối chiếu (bước 5).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Thiếu lý do, phiếu (bước 5).** ERR-20-008 (422): "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu."

**Quy tắc áp dụng.** BR-20-010.

**Màn hình, API.** UI-20-17; API-20-041, 042, 043, 044, 045, 046; kịch bản TS-20-10.
:::

### 6.11. UC-20-11 · Cài đặt tỉnh, xem phiên bản và lịch bảo trì của tỉnh

Quản trị tỉnh tự đặt thông tin hiển thị, chủ quản CNTT, an toàn đăng nhập (chỉ chặt hơn mức nền tảng) và cửa sổ bảo trì ưa thích, đồng thời biết tỉnh đang chạy phiên bản nào.

::: dac-ta
**Mục tiêu.** Mai đặt thời gian phiên tối đa 10 phút, mật khẩu tối thiểu 16 ký tự, cửa sổ bảo trì thứ Bảy 22:00 trong 4 giờ, rồi xem ghi chú phát hành và lịch nâng cấp sắp tới.

**Tác nhân chính.** TA; TO, AU, VW xem phần hiển thị.

**Tác nhân phụ.** PH-12 (áp chính sách phiên, mật khẩu cho realm), kho Git, dịch vụ quét mã độc (logo).

**Mức ưu tiên.** M · MVP (FR-20-064 mức S).

**FR hiện thực.** FR-20-018, FR-20-064.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: LGC-IAM-002 (gián tiếp).

**Tiền điều kiện.** Có `PERM-20-settings`; tenant `ACTIVE` (`SUSPENDED`, `MERGED` chỉ đọc).

**Kích hoạt.** Mở UI-20-12, sửa, bấm "Lưu"; tab "Phiên bản và bảo trì".

**Đảm bảo tối thiểu.** Cài đặt không bao giờ lỏng hơn giới hạn nền tảng; logo chưa quét xong không dùng.

**Đảm bảo thành công.** Cài đặt mới, `ETag`, `configVersionNo`; EVT-20-09 phát và PH-12 áp chính sách.

**Luồng chính.**
1. Mai mở UI-20-12; hệ thống trả cài đặt hiện hành kèm giới hạn nền tảng từng trường.
2. Mai sửa rồi bấm "Lưu"; hệ thống kiểm `sessionIdleMinutes` ≤ 15, `passwordMinLength` ≥ 14, `mfaRequiredRoles` ⊇ vai trò quản trị, cửa sổ bảo trì dài 2 đến 6 giờ.
3. Hệ thống kiểm `itOwnerOrgCode` là tổ chức `ACTIVE` của tỉnh.
4. Hệ thống lưu, ghi `settings.yaml` qua UC-20-09, phát EVT-20-09 (`changeKind = TENANT_SETTINGS`).
5. Mai mở tab "Phiên bản và bảo trì": hệ thống trả phiên bản đang chạy, ghi chú ba bản gần nhất, lịch nâng cấp sắp tới, cửa sổ hiện hành.
6. Mai đổi cửa sổ bảo trì; hệ thống áp cho kế hoạch lập sau.

**Luồng thay thế.**
- **2a. Tải logo.** PNG, SVG ≤ 512 KB qua DD-12, quét mã độc trước khi dùng.
- **5a. Chưa có kế hoạch.** Hiện "Chưa có lịch bảo trì".

**Luồng ngoại lệ.**
- **E1. Vượt giới hạn nền tảng (bước 2).** ERR-20-023 (422): "{Thiết lập} vượt giới hạn của nền tảng ({giới hạn})."
- **E2. Cửa sổ bảo trì sai (bước 2, 6).** ERR-20-059 (422): "Cửa sổ bảo trì không hợp lệ: {lý do}."
- **E3. Chủ quản CNTT không tồn tại (bước 3).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- **E4. Tỉnh tạm ngừng (bước 4).** ERR-20-001 (403): "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh."
- **E5. Tỉnh đã sáp nhập (bước 4).** ERR-20-115 (409): "Tỉnh đã sáp nhập vào {đích}. Dữ liệu chỉ còn để tra cứu."

**Quy tắc áp dụng.** BR-20-010, BR-20-011, BR-20-033.

**Màn hình, API.** UI-20-12; API-20-135, 136, 159, 160; kịch bản TS-20-11.
:::

### 6.12. UC-20-12 · Đặt chính sách tiếp nhận và xem nhật ký truy cập liên tenant

Vai trò nền tảng có thể vào dữ liệu tỉnh khi hỗ trợ; tỉnh quyết định mức cho phép (đọc hay ghi, cần chấp thuận trước, tối đa bao lâu) và xem minh bạch ai đã vào.

::: dac-ta
**Mục tiêu.** Mai đặt `allowWrite = false`, `requirePriorApproval = true`, `maxHours = 2`; Dũng và Bảo xem nhật ký các phiên liên tenant vào `T68` để đối chiếu phiếu hỗ trợ.

**Tác nhân chính.** TA (đặt chính sách); SO, AU (xem).

**Tác nhân phụ.** PH-12 (đọc chính sách qua API-20-165 và áp khi cấp quyền), PH-13 (nhật ký kiểm toán).

**Mức ưu tiên.** M · MVP (FR-20-024 mức S).

**FR hiện thực.** FR-20-023, FR-20-024.

**Truy vết.** REQ-20; quy trình BP-07; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-settings` (đặt) hoặc vai trò SO, AU (xem); tenant `ACTIVE`; chính sách mặc định đã tạo ở `S01_RECORD`.

**Kích hoạt.** UI-20-22 tab "Chính sách" (Sửa, Lưu) hoặc tab "Nhật ký".

**Đảm bảo tối thiểu.** Thời hạn không vượt trần `20.cross-tenant.max-hours` (BR-12-032); nhật ký đọc trong chuỗi của tenant ngữ cảnh, không liên tenant.

**Đảm bảo thành công.** Chính sách phiên bản mới có hiệu lực từ lần cấp quyền kế tiếp; nhật ký trả đủ phiên với người, lý do, phiếu, người duyệt, số thao tác đọc, ghi.

**Luồng chính.**
1. Mai sửa chính sách; hệ thống kiểm `maxHours` ≤ trần và người nhận thông báo là đầu mối hoặc người dùng `ACTIVE` của tỉnh.
2. Hệ thống lưu phiên bản mới, phát EVT-20-09 (`changeKind = CROSS_TENANT_POLICY`) để PH-12 vô hiệu đệm.
3. Từ lần cấp quyền sau, PH-12 áp: `requirePriorApproval = true` thì cần TA của tỉnh chấp thuận ngoài người duyệt nền tảng; `allowWrite = false` thì chỉ cấp quyền đọc.
4. Dũng mở tab "Nhật ký"; hệ thống kiểm khoảng thời gian, đọc bản ghi `CROSS_TENANT_*` trong chuỗi của tỉnh từ PH-13, ghép lần cấp quyền từ PH-12.
5. Dũng bấm một phiên để xem chi tiết thao tác (đường dẫn API, thời điểm, kết quả).

**Luồng thay thế.**
- **3a. Sự cố an ninh mức 1.** Nền tảng vẫn được vào đọc tối đa 1 giờ kèm thông báo tức thời dù `allowRead = false`; ngoại lệ khẩn này không tắt được (Q20-18 của FRS).

**Luồng ngoại lệ.**
- **E1. Vượt trần (bước 1).** ERR-20-027 (422): "Thời hạn truy cập liên tenant tối đa là {giờ} giờ."
- **E2. Người nhận không hợp lệ (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E3. Khoảng thời gian quá dài (bước 4).** ERR-20-032 (400): "Khoảng thời gian tối đa là {số} ngày."
- **E4. PH-13 không khả dụng (bước 4).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-20-012.

**Màn hình, API.** UI-20-22; API-20-137, 138, 139, 165; kịch bản TS-20-12.
:::

### 6.13. UC-20-13 · Chuyển chế độ cách ly của tenant

Tỉnh đang dùng chung có thể nâng lên cơ sở dữ liệu riêng rồi cụm riêng mà không khởi tạo lại; vì khó đảo ngược nên cần hai quản trị nền tảng.

::: dac-ta
**Mục tiêu.** Hà đề nghị chuyển `T68` từ `SHARED` sang `DEDICATED_DB` trong cửa sổ bảo trì; Khoa duyệt; hệ thống sao dữ liệu theo `tenant_id`, kiểm đếm rồi đổi định tuyến.

**Tác nhân chính.** PA (Hà đề nghị), PA khác (Khoa duyệt).

**Tác nhân phụ.** PH-18 (công cụ chuyển dữ liệu), CloudNativePG, PH-03 (chuyển chỉ đọc).

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-20-025.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-lifecycle`, Khoa có `PERM-20-approve`; tenant `ACTIVE`; không có sáp nhập, nâng cấp đang chạy; `DEDICATED_CLUSTER` cần `20.dedicated-cluster.enabled`.

**Kích hoạt.** "Đổi chế độ cách ly" ở tab "Cấu hình nền tảng" của UI-20-03.

**Đảm bảo tối thiểu.** Chỉ đổi một bậc mỗi lần, trong cửa sổ bảo trì; kiểm đếm lệch thì giữ định tuyến cụm cũ; người đề nghị không duyệt.

**Đảm bảo thành công.** `isolation_mode` mới, dữ liệu cũ giữ ở cụm chung `20.export.retention-days` ngày rồi xóa, EVT-20-09 phát.

**Luồng chính.**
1. Hà lập đề nghị `ISOLATION_CHANGE`; hệ thống kiểm chỉ nâng một bậc (hoặc hạ một bậc có `decisionDocNo`) và lịch nằm trong cửa sổ bảo trì.
2. Hệ thống ước thời gian và dung lượng chuyển theo `DATABASE_GB`; Hà gửi, đề nghị `PENDING_APPROVAL`.
3. Khoa duyệt; hệ thống kiểm Khoa khác Hà, đề nghị `APPROVED`.
4. Tới giờ hẹn, hệ thống tạo lần chạy `ISOLATION_CHANGE`: tạo cụm đích (`S07_DATABASE`), sao dữ liệu bằng công cụ PH-18, chuyển tenant chỉ đọc (EVT-20-04) lúc đồng bộ phần cuối, đổi bảng định tuyến, bật ghi.
5. Hệ thống kiểm đếm bản ghi theo bảng; khớp thì đổi `isolation_mode`, phát EVT-20-09 (`changeKind = ISOLATION_MODE`).

**Luồng thay thế.**
- **1a. Hạ bậc** (`DEDICATED_DB` về `SHARED`): cùng luồng chiều ngược.
- **3a. Khoa từ chối.** Đề nghị `REJECTED`, tenant giữ nguyên.

**Luồng ngoại lệ.**
- **E1. Chuyển không hợp lệ (bước 1).** ERR-20-028 (422): "Không chuyển được từ chế độ {từ} sang {tới}: {lý do}."
- **E2. Tự duyệt (bước 3).** ERR-20-007 (403): "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."
- **E3. Lịch ngoài cửa sổ bảo trì (bước 1).** ERR-20-059 (422): "Cửa sổ bảo trì không hợp lệ: {lý do}."
- **E4. Kiểm đếm lệch (bước 5, chạy nền).** ERR-20-113: "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}." Lần chạy `FAILED`.

**Quy tắc áp dụng.** BR-20-008, BR-20-009, BR-20-035, BR-20-040.

**Màn hình, API.** UI-20-03; API-20-047, 076, 077, 079; kịch bản TS-20-13.
:::

```{.mermaid caption="Trình tự đổi chế độ cách ly có bốn mắt"}
sequenceDiagram
  actor Ha as Hà (đề nghị)
  actor Khoa as Khoa (duyệt)
  participant K as PH-20
  participant O as PH-18, CNPG
  Ha->>K: Đề nghị ISOLATION_CHANGE T68
  K->>K: Kiểm một bậc, cửa sổ bảo trì
  Khoa->>K: Duyệt
  K->>K: Kiểm Khoa khác Hà
  K->>O: Tạo cụm đích, sao dữ liệu theo tenant_id
  O-->>K: Kiểm đếm khớp
  K->>K: Đổi định tuyến, isolation_mode mới, EVT-20-09
```

Hình cho thấy không ai tự duyệt đề nghị của mình; đổi định tuyến chỉ xảy ra sau khi kiểm đếm khớp.

### 6.14. UC-20-14 · Đặt, đổi hạn mức hợp đồng và ghi đè tạm thời

Hạn mức hợp đồng của mười hai tài nguyên là căn cứ thực thi; tăng trong trần thì đi thẳng, hạ dưới mức đang dùng cần người thứ hai duyệt, đợt cao điểm dùng ghi đè có hạn.

::: dac-ta
**Mục tiêu.** Hà tăng `API_RPS` của `T68` từ 500 lên 800 trong trần; đề nghị hạ `USERS` từ 2.000 xuống 1.200 (thấp hơn mức dùng 1.450) để Khoa duyệt; ghi đè `OBJECT_STORAGE_GB` tạm thời 20 ngày cho kỳ quyết toán.

**Tác nhân chính.** PA (Hà lập, Khoa duyệt).

**Tác nhân phụ.** PH-03 (APISIX), PH-04, PH-10, PH-12, PH-01, PH-02, Ceph RGW (nơi thực thi, đọc API-20-164), PH-18 (việc duyệt).

**Mức ưu tiên.** M · MVP (FR-20-032 mức S).

**FR hiện thực.** FR-20-026, FR-20-027, FR-20-032.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-quota`, Khoa có `PERM-20-approve`; tenant `ACTIVE` (đề nghị đổi chấp nhận cả `SUSPENDED`); hạn mức mặc định đã có từ mẫu.

**Kích hoạt.** UI-20-05: "Sửa hạn mức", "Đề nghị đổi hạn mức", "Ghi đè tạm thời", "Thu hồi"; hộp duyệt ở UI-20-08.

**Đảm bảo tối thiểu.** Giá trị trong [tối thiểu, trần nền tảng]; hạ hạn mức không cắt tài nguyên đã cấp, chỉ chặn cấp mới (BR-20-014); người lập không duyệt.

**Đảm bảo thành công.** Hạn mức hiệu lực tính lại, `quota.yaml` ghi qua UC-20-09, EVT-20-05 phát, từng nơi thực thi xác nhận `appliedAt`.

**Luồng chính.**
1. Hệ thống trả hạn mức hợp đồng, trần theo hồ sơ quy mô, ghi đè còn hạn, hạn mức hiệu lực và mức dùng gần nhất.
2. Hà nhập `API_RPS = 800`; hệ thống kiểm trong khoảng, lưu, tính lại hạn mức hiệu lực, phát EVT-20-05.
3. Hà nhập `USERS = 1.200` thấp hơn mức dùng: hệ thống từ chối lệnh trực tiếp và hướng sang "Đề nghị đổi hạn mức"; hệ thống chụp mức dùng p95 7 ngày, đánh dấu `requiresApproval`, đề nghị `PENDING_APPROVAL`, việc duyệt vào hộp việc PH-18.
4. Khoa duyệt; hệ thống kiểm Khoa khác Hà, áp vào `effectiveAt`, phát EVT-20-05.
5. Nơi thực thi đọc API-20-164, áp và xác nhận (PH-03 bằng EVT-03-11); nơi nào chưa xác nhận sau 15 phút thì cảnh báo.
6. Với ghi đè, Hà nhập giá trị, `validFrom`, `validTo` (≤ `20.quota.override-max-days`); tới `validTo` bộ lập lịch (5 phút một lần) đặt `EXPIRED` và báo đầu mối trước 24 giờ.

**Luồng thay thế.**
- **2a. Hạ nhưng vẫn không thấp hơn mức dùng.** Đi thẳng như bước 2.
- **4a. Từ chối.** Đề nghị `REJECTED`, hạn mức giữ nguyên.
- **6a. Thu hồi sớm hoặc ghi đè chồng thời gian.** `REVOKED` áp như hết hạn; chồng thì giá trị lớn hơn thắng, giao diện cảnh báo.

**Luồng ngoại lệ.**
- **E1. Ngoài miền, vượt trần (bước 2, 3, 6).** ERR-20-029 (422): "Hạn mức {tài nguyên} phải trong khoảng {min} đến {trần} {đơn vị}."
- **E2. Hạ dưới mức đang dùng bằng lệnh trực tiếp (bước 3).** ERR-20-030 (422): "Hạ hạn mức {tài nguyên} xuống {giá trị} thấp hơn mức đang dùng {dùng} cần được duyệt."
- **E3. Tự duyệt (bước 4).** ERR-20-007 (403): "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."
- **E4. Đề nghị đã xử lý hoặc thu hồi ghi đè đã hết hạn (bước 4, 6a).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E5. Ghi đè quá số ngày (bước 6).** ERR-20-031 (422): "Ghi đè hạn mức tối đa {số} ngày."

**Quy tắc áp dụng.** BR-20-008, BR-20-013, BR-20-014, BR-20-015.

**Màn hình, API.** UI-20-05, UI-20-08; API-20-048, 049, 050, 051, 052, 053, 054, 055, 164; kịch bản TS-20-14.
:::

```{.mermaid caption="Trình tự đổi hạn mức có duyệt và đẩy xuống nơi thực thi"}
sequenceDiagram
  actor Ha as Hà (lập)
  actor Khoa as Khoa (duyệt)
  participant K as PH-20
  participant E as PH-03, PH-10, PH-12
  Ha->>K: Đề nghị hạ USERS xuống 1.200
  K->>K: Chụp mức dùng p95, requiresApproval
  Khoa->>K: Duyệt
  K->>K: Kiểm Khoa khác Hà, ghi quota.yaml
  K->>E: EVT-20-05 quota-changed
  E->>K: Đọc API-20-164 và xác nhận áp
```

Hình cho thấy PH-20 không tự chặn lượt gọi: giá trị được đẩy xuống từng nơi thực thi và mỗi nơi xác nhận riêng.

### 6.15. UC-20-15 · Thu thập sử dụng tài nguyên và cảnh báo ngưỡng hạn mức

Mỗi giờ hệ thống ghi ảnh chụp sử dụng của mười hai tài nguyên cho mọi tenant và cảnh báo khi chạm 80% và 100% hạn mức hiệu lực.

::: dac-ta
**Mục tiêu.** Hệ thống phát hiện `T68` dùng 82% `KAFKA_PRODUCE_MBPS`, mở cảnh báo `WARN_80`, báo Tuấn và đầu mối `TECHNICAL`, `TENANT_ADMIN` của tỉnh; Hà xác nhận đã xử lý.

**Tác nhân chính.** Bộ lập lịch PH-20; PA (xác nhận); PO, TA xem.

**Tác nhân phụ.** Mimir (PH-13), API thống kê của PH-01, 02, 04, 10, 12, RGW admin API, PH-18 (thông báo), PH-13 (EVT-13-14).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-028, FR-20-029.

**Truy vết.** REQ-20; quy trình BP-07; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Mimir có chỉ số gắn nhãn `tenant`; tenant `ACTIVE`, `SUSPENDED` hoặc `MERGING`; xác nhận cần `PERM-20-quota`.

**Kích hoạt.** Phút thứ 5 mỗi giờ (`20.usage.snapshot-interval` = PT1H); EVT-13-14 `{tenant}.obs.capacity.warning.v1`.

**Đảm bảo tối thiểu.** Ghi lũy đẳng theo (`tenant_id`, `resource`, `hour_start`); nguồn không trả lời thì dòng `MISSING`, không nội suy, không phát cảnh báo giả; cảnh báo không gửi lặp.

**Đảm bảo thành công.** Mỗi tài nguyên mỗi giờ một dòng EN-20-16 kèm hạn mức hiệu lực và phần trăm; cảnh báo mở một lần cho mỗi (tài nguyên, mức).

**Luồng chính.**
1. Bộ lập lịch lặp theo tenant trong `TenantContext.runAs`, đọc số đo từ nguồn của từng tài nguyên.
2. Hệ thống ghi một dòng cho mỗi tài nguyên và giờ; nguồn không trả lời thì `quality = MISSING`, giờ sau đọc bù tối đa 24 giờ.
3. Hệ thống so `percent` với `20.quota.warn-percent` (80) và 100.
4. Vượt ngưỡng mà chưa có cảnh báo mở: tạo `OPEN`, phát EVT-20-06, gửi thông báo qua PH-18.
5. Đã có cảnh báo mở: chỉ cập nhật `lastAt`; xuống dưới 75% liên tục 24 giờ thì `RESOLVED`.
6. Hà xác nhận cảnh báo kèm ý kiến ("đã lập đề nghị tăng"): `ACKNOWLEDGED`, vẫn hiện tới khi `RESOLVED`.

**Luồng thay thế.**
- **1a. `DEDICATED_CLUSTER` không đẩy được về Mimir.** Bộ thực thi cục bộ gửi gói ngày, `quality = ESTIMATED` khi trễ.

**Luồng ngoại lệ.**
- **E1. Nguồn thiếu quá 3 giờ liên tiếp (bước 2, chạy nền).** ERR-20-110: "Thiếu số liệu sử dụng {tài nguyên} của {tenant} từ {giờ}." Cảnh báo PO ở UI-20-06.
- **E2. Mimir không khả dụng (bước 1).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."
- **E3. Thu bổ sung cho tenant `DECOMMISSIONED`.** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Xác nhận cảnh báo đã `RESOLVED` (bước 6).** ERR-20-006 (409), câu như E3.
- **E5. Không có cảnh báo (bước 6).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

**Quy tắc áp dụng.** BR-20-013, BR-20-016.

**Màn hình, API.** UI-20-06, UI-20-13; API-20-058, 059; kịch bản TS-20-15.
:::

### 6.16. UC-20-16 · Xem sử dụng tài nguyên và lập báo cáo sử dụng

Nền tảng thấy tỉnh nào gần hạn mức, cụm còn chỗ không; tỉnh thấy mình dùng bao nhiêu so với hợp đồng; báo cáo kỳ làm căn cứ nghiệm thu hợp đồng.

::: dac-ta
**Mục tiêu.** Tuấn xếp hạng tenant theo phần trăm dùng cao nhất toàn nền tảng; Chi xem sử dụng của `T68`; Hà lập báo cáo tháng 10 dạng XLSX.

**Tác nhân chính.** PA, PO (toàn nền tảng); TA, TO, AU (tỉnh mình).

**Tác nhân phụ.** PH-18 (báo xong), kho đối tượng `dh-platform-exports`.

**Mức ưu tiên.** M · MVP (FR-20-031 mức S).

**FR hiện thực.** FR-20-030, FR-20-031.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có ảnh chụp sử dụng (UC-20-15); `PERM-20-read` hoặc `PERM-20-usage-read`; báo cáo cần kỳ đã kết thúc.

**Kích hoạt.** Mở UI-20-06 (nền tảng) hoặc UI-20-13 (tỉnh); "Lập báo cáo"; lịch tự lập ngày 2 hằng tháng.

**Đảm bảo tối thiểu.** Bản tỉnh chỉ đọc tenant ngữ cảnh (RLS); dòng `MISSING` hiện là khoảng trống, không nội suy.

**Đảm bảo thành công.** Biểu đồ đúng khoảng; báo cáo có băm SHA-256, tải được tới khi hết hạn lưu.

**Luồng chính.**
1. Người dùng chọn khoảng và độ chi tiết; hệ thống kiểm tham số.
2. Hệ thống gộp ảnh chụp (đỉnh, trung bình) kèm hạn mức hiệu lực từng thời điểm; bản nền tảng thêm bảng xếp hạng và tổng sử dụng so với sức chứa cụm.
3. Hà bấm "Lập báo cáo"; hệ thống kiểm kỳ đã kết thúc và định dạng, tạo bản ghi `REQUESTED`, chạy nền.
4. Hệ thống tính đỉnh, trung bình, p95, số giờ vượt 80%, 100%, số giờ thiếu số liệu; dựng XLSX hoặc PDF, lưu bucket, ghi băm, báo người lập qua PH-18.
5. Hà tải tệp qua API-20-062.

**Luồng thay thế.**
- **2a. Xem dạng bảng.** Biểu đồ có nút "Xem dạng bảng" (NFR-20-022).
- **3a. Báo cáo cùng phạm vi, kỳ, định dạng đã có.** Trả bản đã có (lũy đẳng theo nội dung).

**Luồng ngoại lệ.**
- **E1. Khoảng vượt tối đa (bước 1).** ERR-20-032 (400): "Khoảng thời gian tối đa là {số} ngày."
- **E2. Tham số sai (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E3. Kỳ chưa kết thúc hoặc định dạng sai (bước 3).** ERR-20-066 (422): "Không lập được báo cáo sử dụng: {lý do}."
- **E4. Tải tệp đã hết hạn lưu (bước 5).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."

**Quy tắc áp dụng.** BR-20-013.

**Màn hình, API.** UI-20-06, UI-20-13; API-20-056, 057, 060, 061, 062, 140, 141; kịch bản TS-20-16.
:::

### 6.17. UC-20-17 · Xem danh mục phân hệ, bật phân hệ và cấp trạng thái cho menu

Hà xem hai mươi phân hệ và phụ thuộc, bật PH-19 cho `T68` khi tỉnh ký phụ lục; `dh-console` lấy trạng thái phân hệ để dựng menu đúng.

::: dac-ta
**Mục tiêu.** Hà bật PH-19 cho `T68`: hệ thống kiểm phụ thuộc, phát EVT-20-07, chờ PH-19 tự khởi tạo phần của tỉnh; Mai đăng nhập thấy menu có thêm mục Thanh toán.

**Tác nhân chính.** PA; mọi người dùng tỉnh (menu, qua `dh-console`).

**Tác nhân phụ.** Phân hệ được bật (báo qua API-20-166), `dh-console`, PH-03, PH-12.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-033, FR-20-034, FR-20-037.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-admin`; tenant `ACTIVE`; phân hệ có trong phiên bản đang chạy và ở `DISABLED` hoặc `FAILED`.

**Kích hoạt.** UI-20-07 tab "Danh mục phân hệ" và "Phân hệ của tenant", "Bật"; `dh-console` tải sau đăng nhập và mỗi 5 phút.

**Đảm bảo tối thiểu.** Không bật khi thiếu phụ thuộc `REQUIRED`; tenant lấy từ token, không từ tham số.

**Đảm bảo thành công.** Phân hệ `ENABLED`, `modules.yaml` ghi qua UC-20-09, registry vô hiệu đệm; menu phản ánh trong tối đa 5 phút hoặc ngay khi nhận thông báo đẩy.

**Luồng chính.**
1. Hà mở danh mục: hệ thống trả 20 phân hệ kèm ma trận phụ thuộc (`CMP-DependencyGraph`) và số tenant `ENABLED`, `SUSPENDED`, `FAILED`.
2. Hà bấm "Bật" PH-19 cho `T68`; hệ thống kiểm mọi phụ thuộc `REQUIRED` đang `ENABLED` và phân hệ có trong phiên bản đang chạy.
3. Hệ thống tạo lần chạy `SUPPLEMENT` một bước `S15_MODULES`, phân hệ `ENABLING`, phát EVT-20-07.
4. PH-19 khởi tạo phần của tỉnh rồi báo `SUCCEEDED` qua API-20-166; hệ thống đặt `ENABLED` và ghi `modules.yaml`.
5. `dh-console` gọi API-20-142 (tenant từ token): hệ thống trả trạng thái tenant, danh sách phân hệ kèm `state`, `banner`, `readOnly`; phản hồi `Cache-Control: private, max-age=60`.

**Luồng thay thế.**
- **3a. Phân hệ không có bước khởi tạo riêng** (`asyncProvision = false`): `ENABLED` ngay.
- **5a. Tenant `SUSPENDED`.** Vẫn `200` với `readOnly = true`, `banner.type = SUSPENDED` (không trả ERR-20-001 ở API này).
- **1a. Lọc `wave = 2`.** Hiện phân hệ Đợt 2 kèm cờ "chưa phát hành".

**Luồng ngoại lệ.**
- **E1. Thiếu phụ thuộc (bước 2).** ERR-20-033 (422): "Phân hệ {phân hệ} cần {phụ thuộc} được bật trước."
- **E2. Phiên bản đang chạy chưa có phân hệ (bước 2).** ERR-20-055 (422): "Phiên bản {phiên bản} không dùng được cho thao tác này: {lý do}."
- **E3. Phân hệ báo lỗi hoặc quá hạn (bước 4, chạy nền).** ERR-20-107: "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}." hoặc ERR-20-106; phân hệ `FAILED`.
- **E4. Tenant không `ACTIVE` (bước 2).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E5. Token không có tenant hợp lệ (bước 5).** ERR-00-401 (401): "Phiên đăng nhập đã hết hạn. Đăng nhập lại."
- **E6. Tenant đã chấm dứt (bước 5).** ERR-20-102 (410): "Tỉnh đã chấm dứt sử dụng Datahub."

**Quy tắc áp dụng.** BR-20-009, BR-20-017, BR-20-021, BR-20-026, BR-20-036.

**Màn hình, API.** UI-20-07; API-20-063, 064, 065, 142, 163, 166; kịch bản TS-20-17.
:::

### 6.18. UC-20-18 · Tắt, tạm ngừng, tiếp tục phân hệ và đặt cờ tính năng

Phân hệ có thể bị tạm ngừng (giữ dữ liệu) hoặc tắt khi hết phụ lục hợp đồng; tính năng nhỏ trong phân hệ bật tắt theo từng tỉnh bằng cờ, không cần nhánh mã.

::: dac-ta
**Mục tiêu.** Hà tạm ngừng PH-19 của `T68` khi phụ lục hết hạn, tiếp tục khi gia hạn; bật cờ `ph04.sql-direct` cho tỉnh thử nghiệm.

**Tác nhân chính.** PA.

**Tác nhân phụ.** Phân hệ bị tắt hoặc tạm ngừng (nghe EVT-20-08), `dh-console`.

**Mức ưu tiên.** M · MVP (FR-20-036 mức S).

**FR hiện thực.** FR-20-035, FR-20-036.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-admin`; phân hệ `ENABLED` (tạm ngừng, tắt) hoặc `SUSPENDED` (tiếp tục, tắt) và không phải phân hệ lõi PH-03, 10, 12, 13, 18, 20; cờ phải có trong danh mục cờ của phân hệ đang `ENABLED`.

**Kích hoạt.** UI-20-07: "Tạm ngừng", "Tiếp tục", "Tắt" (`CMP-ConfirmDialog` nêu hệ quả); tab "Cờ tính năng", công tắc.

**Đảm bảo tối thiểu.** Tắt không xóa dữ liệu của phân hệ (BR-20-018); không tắt phân hệ đang là phụ thuộc `REQUIRED` của phân hệ khác đang bật.

**Đảm bảo thành công.** Phân hệ `SUSPENDED` hoặc `DISABLED` (data plane trả ERR-20-103); cờ lưu, `modules.yaml` ghi, EVT-20-08 hoặc EVT-20-09 phát.

**Luồng chính.**
1. Hà chọn "Tạm ngừng"; hệ thống từ chối phân hệ lõi và phân hệ đang bị phụ thuộc.
2. Hệ thống đặt `SUSPENDED`, phát EVT-20-08 (`mode = SUSPEND`); phân hệ chặn dùng, giao diện chỉ đọc.
3. Khi gia hạn, Hà bấm "Tiếp tục": `SUSPENDED` về `ENABLED`, phát EVT-20-07 (`mode = RESUME`).
4. Với "Tắt": `DISABLING`, EVT-20-08 (`mode = DISABLE`); phân hệ dừng tác vụ nền của tenant, báo xong thì `DISABLED`.
5. Hà bật cờ `ph04.sql-direct`: hệ thống kiểm cờ có ở danh mục và phân hệ `ENABLED`, lưu, ghi `modules.yaml`, phát EVT-20-09 (`changeKind = FEATURE_FLAG`); phân hệ đọc cờ qua API-20-163 (đệm 60 giây).

**Luồng thay thế.**
- **5a. Cờ có `validTo`.** Đến hạn cờ về mặc định của mẫu và phát EVT-20-09.

**Luồng ngoại lệ.**
- **E1. Phân hệ lõi (bước 1).** ERR-20-035 (403): "Phân hệ {phân hệ} là phân hệ lõi, không tắt được."
- **E2. Đang bị phụ thuộc (bước 1).** ERR-20-034 (409): "Phân hệ {phân hệ} đang được {danh sách} dùng. Tắt các phân hệ đó trước."
- **E3. Trạng thái không phù hợp (bước 2 đến 4).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Cờ không hợp lệ (bước 5).** ERR-20-036 (422): "Cờ {cờ} không áp dụng được: {lý do}."
- **E5. Phiên bản lệch (bước 5).** ERR-20-005 (412): "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."
- **E6. Gọi phân hệ đang tạm ngừng ở data plane.** ERR-20-103 (503): "Chức năng này chưa được bật cho tỉnh."

**Quy tắc áp dụng.** BR-20-010, BR-20-017, BR-20-018, BR-20-037.

**Màn hình, API.** UI-20-07; API-20-064, 066, 067, 068, 069, 070; kịch bản TS-20-18.
:::

### 6.19. UC-20-19 · Phân hệ đọc registry, tổ chức và thực thi trạng thái tenant

Mọi phân hệ cần biết tenant đang ở trạng thái nào, có phân hệ nào bật, tổ chức là gì; PH-20 là nguồn duy nhất và bộ lọc chung chặn nhất quán thay cho mỗi phân hệ tự viết.

::: dac-ta
**Mục tiêu.** PH-01 tra tổ chức chủ quản của một HTTT (kể cả tổ chức đã giải thể), tác vụ nền của PH-16 lặp mọi tenant `ACTIVE`, APISIX trả ERR-20-001 khi `T68` tạm ngừng; PH-20 ngừng thì data plane vẫn phục vụ nhờ đệm.

**Tác nhân chính.** Phân hệ khác và bộ lọc `dh-tenant-filter` (tài khoản dịch vụ); tài khoản PA, PO được qua để hỗ trợ.

**Tác nhân phụ.** PH-01, 06, 07, 08, 12, 16, PH-03 (plugin APISIX), thư viện `dh-tenant-client`.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-057, FR-20-065, FR-20-066.

**Truy vết.** REQ-20; quy trình BP-01; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Bên gọi có scope `tenant:registry-read` hoặc `tenant:org-read`; registry khả dụng hoặc đệm còn hạn (`20.registry.cache-seconds`).

**Kích hoạt.** Mỗi lời gọi của phân hệ; mỗi yêu cầu vào DU hoặc gateway.

**Đảm bảo tối thiểu.** Lỗi trạng thái đồng nhất ở mọi DU; không lộ dữ liệu tenant khác; tổ chức chỉ đọc, đệm tối đa 24 giờ.

**Đảm bảo thành công.** Bên gọi nhận bản ghi kèm `ETag` hoặc `304`; yêu cầu vào tenant không hoạt động bị chặn đúng mã.

**Luồng chính.**
1. Bên gọi gửi `GET /internal/tenant/v1/tenants/T68` với token dịch vụ; hệ thống kiểm scope.
2. Hệ thống trả bản ghi registry (`status`, `isolationMode`, `realm`, `hosts[]`, `apiPrefix`, `modules[]`, `quota`) kèm `ETag`, `Cache-Control: max-age` theo tham số; `If-None-Match` khớp trả `304`.
3. Thư viện đệm cục bộ và vô hiệu khi nhận EVT-20-04, EVT-20-07, EVT-20-08, EVT-20-09.
4. PH-01 gọi API-20-169, 170, 171 với `X-DH-Tenant` từ mesh; hệ thống trả tổ chức kèm `status`, `successorCode`, `resolvedSuccessor`; tra hàng loạt tối đa 500 mã.
5. Bộ lọc tra trạng thái trong đệm: `SUSPENDED` trả ERR-20-001 (trừ API thiết yếu chỉ đọc khi `20.suspend.essential-api-allowed` bật); `PROVISIONING`, `FAILED` trả ERR-20-101; `DECOMMISSIONED` trả ERR-20-102; `MERGED` chuyển tiếp hoặc ERR-20-115 khi ghi; phân hệ chưa bật ERR-20-103; đang nâng cấp ERR-20-118.

**Luồng thay thế.**
- **4a. Tenant `MERGED`.** Trả tổ chức nguồn chỉ đọc kèm `migratedTo` theo ánh xạ.
- **5a. Tài khoản PA, PO.** Được qua để hỗ trợ, có kiểm toán.

**Luồng ngoại lệ.**
- **E1. Thiếu scope (bước 1, 4).** ERR-20-104 (403): "Tài khoản dịch vụ không có quyền {scope}."
- **E2. Không có tenant hoặc tổ chức (bước 1, 4).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- **E3. Tạm ngừng (bước 5).** ERR-20-001 (403): "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh."
- **E4. Chưa sẵn sàng (bước 5).** ERR-20-101 (503): "Tỉnh chưa sẵn sàng phục vụ."
- **E5. Đã chấm dứt (bước 5).** ERR-20-102 (410): "Tỉnh đã chấm dứt sử dụng Datahub."
- **E6. Phân hệ chưa bật (bước 5).** ERR-20-103 (503): "Chức năng này chưa được bật cho tỉnh."
- **E7. Ghi vào tenant `MERGED` (bước 5).** ERR-20-115 (409): "Tỉnh đã sáp nhập vào {đích}. Dữ liệu chỉ còn để tra cứu."
- **E8. Đang bảo trì nâng cấp (bước 5).** ERR-20-118 (503): "Tỉnh đang bảo trì nâng cấp đến {giờ}. Thao tác ghi tạm dừng."
- **E9. PH-20 không khả dụng.** Bên gọi dùng đệm; hết đệm thì bên gọi trả mã của mình (ví dụ ERR-01-046).

**Quy tắc áp dụng.** BR-20-021, BR-20-026, BR-20-036.

**Màn hình, API.** Không có màn riêng; API-20-142, 162, 163, 164, 169, 170, 171; kịch bản TS-20-19.
:::

### 6.20. UC-20-20 · Tạm ngừng và khôi phục tenant

Tạm ngừng cần nhanh khi có quyết định quản lý hoặc sự cố an ninh nên không cần bốn mắt, nhưng phải có lý do, mã phiếu và văn bản căn cứ; dữ liệu giữ nguyên để khôi phục.

::: dac-ta
**Mục tiêu.** Hà tạm ngừng `T68` vì hết hợp đồng (`CONTRACT_EXPIRED`), hệ thống chặn mọi API của tỉnh bằng ERR-20-001; sau khi ký gia hạn Hà khôi phục, tỉnh hoạt động lại.

**Tác nhân chính.** PA.

**Tác nhân phụ.** PH-12 (API-12-084, 085), PH-03 (APISIX), PH-04, PH-10, PH-18 (thông báo, việc bổ sung văn bản).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-038, FR-20-039.

**Truy vết.** REQ-20; quy trình BP-07; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-lifecycle`. Tạm ngừng: tenant `ACTIVE`, không có sáp nhập từ `TRANSFERRING` trở đi. Khôi phục: tenant `SUSPENDED`, không có đề nghị `TERMINATE` ở `APPROVED`.

**Kích hoạt.** UI-20-08 "Tạm ngừng" hoặc "Khôi phục".

**Đảm bảo tối thiểu.** Dữ liệu không mất; data plane vẫn chặn nhờ EVT-20-04 dù PH-12 chưa khóa được realm; tenant đặc biệt không bị tạm ngừng.

**Đảm bảo thành công.** Tenant `SUSPENDED` (hoặc về `ACTIVE`), lịch sử trạng thái ghi, EVT-20-04 phát, registry vô hiệu đệm, thông báo gửi (UC-20-23).

**Luồng chính.**
1. Hà chọn "Tạm ngừng", nhập lý do, mã phiếu, văn bản căn cứ (và `scheduledAt` nếu hẹn); hệ thống kiểm trạng thái, tenant đặc biệt, lý do, văn bản.
2. Hệ thống tạo đề nghị `SUSPEND` ở `APPROVED` (không cần duyệt) và thực hiện ngay hoặc theo lịch.
3. Khi thực hiện: tenant `SUSPENDED`; gọi API-12-084 (realm chỉ cho đăng nhập để xem, chặn token máy); phát EVT-20-04; registry vô hiệu đệm.
4. PH-03 trả ERR-20-001 cho mọi API của tỉnh (trừ API thiết yếu chỉ đọc nếu tham số cho phép), PH-04 dừng luồng theo lịch, PH-10 chặn sản xuất sự kiện từ HTTT.
5. Sau khi lý do được xử lý, Hà chọn "Khôi phục"; hệ thống kiểm trạng thái và đề nghị chấm dứt đang chờ, gọi API-12-085, chạy kiểm tra khói rút gọn (`LOGIN_ADMIN`, `API_SAMPLE`).
6. Đạt: tenant `ACTIVE`, phát EVT-20-04, vô hiệu đệm.

**Luồng thay thế.**
- **1a. `SECURITY_INCIDENT`.** Không cần văn bản; hệ thống mở việc ở PH-18 yêu cầu bổ sung văn bản trong 3 ngày làm việc.
- **5a. Tạm ngừng do hết hợp đồng.** Hệ thống cảnh báo nếu chưa có hợp đồng hiệu lực mới (không chặn).

**Luồng ngoại lệ.**
- **E1. Trạng thái không phù hợp (bước 1, 5).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E2. Thiếu lý do, phiếu (bước 1).** ERR-20-008 (422): "Thao tác trên tenant tỉnh cần lý do tối thiểu 20 ký tự và mã phiếu."
- **E3. Thiếu văn bản căn cứ (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E4. Tenant đặc biệt (bước 1).** ERR-20-010 (403): "Tenant {mã} là tenant đặc biệt của nền tảng, không thực hiện được thao tác này."
- **E5. Đang có đề nghị chấm dứt đã duyệt (bước 5).** ERR-20-037 (422): "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."
- **E6. PH-12 không khóa được realm (bước 3, chạy nền).** ERR-20-107: "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}." Đề nghị về `APPROVED`, hiện ở UI-20-08.
- **E7. Kiểm tra khói rút gọn lỗi (bước 5, chạy nền).** ERR-20-117: "Ca kiểm tra khói {ca} lỗi: {chi tiết}." Tenant giữ `SUSPENDED`.

**Quy tắc áp dụng.** BR-20-009, BR-20-019, BR-20-021.

**Màn hình, API.** UI-20-08; API-12-084, 085; API-20-071, 079; kịch bản TS-20-20.
:::

### 6.21. UC-20-21 · Đề nghị, duyệt chấm dứt tenant và xuất gói bàn giao

Chấm dứt là thao tác không đảo ngược: phải có căn cứ văn bản, hai quản trị nền tảng khác nhau và gói dữ liệu bàn giao cho tỉnh.

::: dac-ta
**Mục tiêu.** Hà lập đề nghị chấm dứt `T68` theo văn bản của UBND tỉnh; Khoa duyệt sau khi xem tóm tắt dữ liệu sẽ mất; hệ thống xuất gói bàn giao, Hà cấp liên kết tải và ghi nhận bàn giao với biên bản.

**Tác nhân chính.** PA (Hà lập, gửi, xác nhận bàn giao), PA khác (Khoa duyệt).

**Tác nhân phụ.** Các phân hệ có dữ liệu (báo phần xuất qua API-20-168), PH-18 (việc duyệt, thông báo), đầu mối tỉnh.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-040, FR-20-041.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-lifecycle`, Khoa có `PERM-20-approve`; tenant `SUSPENDED` (UC-20-20); gói bàn giao cần tenant `SUSPENDED` hoặc `MERGED`.

**Kích hoạt.** UI-20-08 "Đề nghị chấm dứt", tab "Chờ duyệt", "Xuất gói bàn giao".

**Đảm bảo tối thiểu.** Người duyệt chấm dứt không xác nhận bàn giao; chưa duyệt thì chưa thực hiện được; liên kết tải có hạn; gói hết hạn lưu `20.export.retention-days` thì `EXPIRED`.

**Đảm bảo thành công.** Đề nghị `APPROVED`; gói `DELIVERED` kèm `manifest.json` ký, băm SHA-256 và biên bản bàn giao.

**Luồng chính.**
1. Hà lập đề nghị `TERMINATE` (`DRAFT`) kèm văn bản, ngày dự kiến; hệ thống kiểm tenant `SUSPENDED` và ngày dự kiến không sớm hơn thời gian nguội.
2. Hà gửi; đề nghị `PENDING_APPROVAL`, việc duyệt vào hộp việc của các PA khác.
3. Khoa mở đề nghị, xem số HTTT, API, người dùng, dung lượng sẽ mất, trạng thái gói bàn giao, ngày sớm nhất được thực hiện; bấm "Duyệt"; hệ thống kiểm Khoa khác người lập và người gửi.
4. Đề nghị `APPROVED`; hệ thống tự yêu cầu gói bàn giao nếu chưa có (gói `REQUESTED` rồi `COLLECTING`), phát lệnh xuất tới từng phân hệ tham gia.
5. Mỗi phân hệ ghi phần của mình vào bucket `dh-t68-exports`, báo số bản ghi, kích thước, SHA-256 qua API-20-168; đủ báo thì hệ thống dựng bản kê, ký, gói `READY`, phát EVT-20-16.
6. Hà cấp liên kết tải có hạn cho đầu mối tỉnh; tỉnh tải xong, Hà tải biên bản lên và xác nhận: gói `DELIVERED`.

**Luồng thay thế.**
- **3a. Từ chối.** `REJECTED` kèm ý kiến; người gửi rút khi chưa duyệt thì về `DRAFT`.
- **1a. Tỉnh từ chối nhận dữ liệu.** `exportRequired = false` kèm tệp văn bản đính kèm.
- **5a. Phân hệ chưa bật cho tenant.** Không tham gia, ghi "không có dữ liệu" trong bản kê.

**Luồng ngoại lệ.**
- **E1. Tenant chưa tạm ngừng (bước 1).** ERR-20-037 (422): "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."
- **E2. Ngày dự kiến trước thời gian nguội (bước 1).** ERR-20-038 (422): "Chưa hết thời gian chờ {số} ngày kể từ khi tạm ngừng (đến {ngày})."
- **E3. Tự duyệt hoặc người xác nhận bàn giao là người duyệt (bước 3, 6).** ERR-20-007 (403): "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."
- **E4. Đã có đề nghị chấm dứt khác hoặc gói chưa `READY` (bước 1, 6).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E5. Liên kết sau khi gói hết hạn (bước 6).** ERR-20-039 (410): "Gói bàn giao {mã} đã hết hạn lưu. Lập gói mới."
- **E6. Phân hệ báo lỗi hoặc quá 24 giờ (bước 5, chạy nền).** ERR-20-107: "Bước {bước} lỗi tại {bên thực hiện}: {mã lỗi gốc}." Phần đó `FAILED`, Hà chạy lại phần lỗi.

**Quy tắc áp dụng.** BR-20-008, BR-20-019, BR-20-020.

**Màn hình, API.** UI-20-08; API-20-071, 073, 074, 075, 076, 077, 078, 080, 081, 082, 083, 084, 168; kịch bản TS-20-21.
:::

```{.mermaid caption="Trình tự đề nghị, duyệt chấm dứt và bàn giao gói dữ liệu"}
sequenceDiagram
  actor Ha as Hà (lập)
  actor Khoa as Khoa (duyệt)
  participant K as PH-20
  participant M as Các phân hệ
  actor T as Đầu mối tỉnh
  Ha->>K: Lập và gửi đề nghị TERMINATE T68
  Khoa->>K: Duyệt sau khi xem tóm tắt dữ liệu
  K->>K: Kiểm Khoa khác Hà, đề nghị APPROVED
  K->>M: Lệnh xuất gói bàn giao
  M-->>K: Báo phần xuất, số bản ghi, SHA-256
  K->>K: Dựng manifest, ký, gói READY, EVT-20-16
  Ha->>T: Cấp liên kết tải có hạn
  Ha->>K: Xác nhận bàn giao kèm biên bản
```

Hình cho thấy gói chỉ `DELIVERED` khi từng phân hệ đã báo xong và người xác nhận khác người duyệt chấm dứt.

### 6.22. UC-20-22 · Thực hiện chấm dứt tenant

Khi đủ ba điều kiện (đề nghị đã duyệt, gói đã bàn giao, hết thời gian nguội), hệ thống gỡ tenant khỏi nền tảng và xóa mật mã để dữ liệu còn sót không đọc được.

::: dac-ta
**Mục tiêu.** Hà thực hiện chấm dứt `T68` sau 30 ngày nguội: các phân hệ gỡ tài nguyên, PH-12 xóa realm, PH-13 đóng chuỗi kiểm toán, PH-09 hủy KEK; tenant `DECOMMISSIONED`.

**Tác nhân chính.** PA.

**Tác nhân phụ.** PH-12, PH-13 (API-13-073), PH-09 (FR-09-043, EVT-09-21), các phân hệ, OpenBao, Ceph RGW, kho Git.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-042.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-lifecycle`; đề nghị `TERMINATE` `APPROVED`; gói `DELIVERED` hoặc `exportRequired = false` có văn bản; đã hết `20.terminate.cooling-days`; tenant `SUSPENDED`.

**Kích hoạt.** UI-20-08 "Thực hiện chấm dứt" (gõ lại mã tenant); hoặc tự động tại `plannedAt`.

**Đảm bảo tối thiểu.** Thiếu một điều kiện thì không chạy; chuỗi kiểm toán WORM giữ theo thời hạn quy định; chưa nhận xác nhận xóa mật mã thì tenant giữ `SUSPENDED`.

**Đảm bảo thành công.** Tenant `DECOMMISSIONED` (data plane trả ERR-20-102), đề nghị `DONE`, lịch sử ghi; mã `T68` không được cấp lại.

**Luồng chính.**
1. Hà bấm "Thực hiện chấm dứt", gõ lại `T68`; hệ thống kiểm đủ ba điều kiện.
2. Hệ thống phát EVT-20-04 `DECOMMISSIONED` (phân hệ nghe để gỡ tài nguyên và xóa dữ liệu theo chính sách của mình), gọi PH-12 xóa realm, API-13-073 đóng chuỗi kiểm toán.
3. Hệ thống gỡ bucket, đường dẫn OpenBao, thư mục `tenants/T68/` (commit xóa có ký, lịch sử Git giữ).
4. Hệ thống gọi FR-09-043 xóa mật mã KEK `dh-t68-pii` và chờ EVT-09-21.
5. Nhận EVT-09-21: tenant `DECOMMISSIONED`, đề nghị `DONE`, ghi lịch sử, thông báo (UC-20-23).

**Luồng thay thế.**
- **2a. Một phân hệ chưa báo gỡ xong sau 24 giờ.** Hệ thống vẫn chuyển `DECOMMISSIONED` và mở việc dọn ở PH-18 cho phân hệ đó.

**Luồng ngoại lệ.**
- **E1. Chưa đủ điều kiện (bước 1).** ERR-20-037 (422): "Chưa đủ điều kiện chấm dứt hoặc khôi phục tenant {mã}: {lý do}."
- **E2. Chưa hết thời gian nguội (bước 1).** ERR-20-038 (422): "Chưa hết thời gian chờ {số} ngày kể từ khi tạm ngừng (đến {ngày})."
- **E3. Gõ sai mã xác nhận (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E4. Không nhận EVT-09-21 sau 24 giờ (bước 4, chạy nền).** ERR-20-116: "Chưa nhận xác nhận xóa mật mã của {tenant}." Cảnh báo SO nền tảng.

**Quy tắc áp dụng.** BR-20-001, BR-20-019, BR-20-020.

**Màn hình, API.** UI-20-08; API-20-079; kịch bản TS-20-22.
:::

```{.mermaid caption="Trình tự thực hiện chấm dứt và xóa mật mã"}
sequenceDiagram
  actor Ha as Hà (PA)
  participant K as PH-20
  participant M as Các phân hệ, PH-12
  participant O as PH-13
  participant C as PH-09
  Ha->>K: Thực hiện chấm dứt T68
  K->>K: Kiểm đã duyệt, đã bàn giao, hết 30 ngày nguội
  K->>M: EVT-20-04 DECOMMISSIONED, xóa realm
  K->>O: API-13-073 đóng chuỗi kiểm toán
  K->>C: FR-09-043 xóa mật mã KEK
  C-->>K: EVT-09-21 crypto-shred completed
  K->>K: Tenant DECOMMISSIONED, đề nghị DONE
```

Hình cho thấy xóa mật mã là bước cuối và không đảo ngược; thiếu xác nhận của PH-09 thì tenant chưa được coi là đã chấm dứt hẳn.

### 6.23. UC-20-23 · Tra lịch sử vòng đời và nhận thông báo đổi trạng thái

Mọi lần đổi trạng thái để lại một dòng lịch sử chỉ thêm, không sửa, và kích hoạt thông báo tới những người liên quan.

::: dac-ta
**Mục tiêu.** Yến xem dòng thời gian của `T68` (khai báo, kích hoạt, tạm ngừng, khôi phục) kèm người, văn bản, đề nghị; mỗi lần đổi trạng thái Mai và các đầu mối nhận thư đúng nội dung.

**Tác nhân chính.** PA, PO, PAU (xem); hệ thống (gửi thông báo).

**Tác nhân phụ.** PH-18 (`NotificationApi`), đầu mối tỉnh, người dùng tỉnh.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-043, FR-20-044.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Tenant tồn tại; `PERM-20-read`; thông báo cần đầu mối đang hoạt động.

**Kích hoạt.** Tab "Lịch sử vòng đời" của UI-20-03; mỗi bản ghi lịch sử mới; hẹn giờ trước tạm ngừng, chấm dứt, cutover 7 ngày và 1 ngày.

**Đảm bảo tối thiểu.** Lịch sử chỉ thêm; lý do `SECURITY_INCIDENT` chỉ nêu "sự cố an toàn thông tin", không nêu chi tiết; thông báo lũy đẳng theo `{historyId}:{kênh}`.

**Đảm bảo thành công.** Dòng thời gian đầy đủ, mỗi dòng liên kết tới đề nghị hoặc lần chạy; kết quả gửi ghi vào bản ghi lịch sử.

**Luồng chính.**
1. Yến mở tab; hệ thống đọc EN-20-23 và EN-20-22, ghép lần chạy saga, kế hoạch sáp nhập liên quan.
2. Hệ thống trả dòng thời gian `CMP-Timeline`: trạng thái trước, sau, thời điểm, nguyên nhân, người, văn bản, đề nghị.
3. Khi tenant đổi trạng thái, hệ thống chọn người nhận theo trạng thái: đầu mối `LEADER`, `TENANT_ADMIN`, `TECHNICAL`, `SECURITY` (tạm ngừng, chấm dứt, sáp nhập), người dùng tỉnh (khi `SUSPENDED`, `MERGING`), PO (mọi chuyển).
4. Hệ thống gọi `NotificationApi` với mẫu, biến (tenant, trạng thái, lý do rút gọn, hạn, liên hệ hỗ trợ) và ghi kết quả gửi.

**Luồng thay thế.**
- **2a. Xuất PDF.** Lịch sử kèm danh sách văn bản, dùng cơ chế báo cáo của UC-20-16.

**Luồng ngoại lệ.**
- **E1. Không có tenant (bước 1).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem."
- **E2. Tham số sai (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E3. PH-18 không khả dụng (bước 4).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." Thử lại 6 lần trong 1 giờ rồi cảnh báo PO ở UI-20-20.
- **E4. Không còn đầu mối hoạt động (bước 3).** ERR-20-021 (422): "Cần đủ đầu mối {vai trò} trước khi {thao tác}." Cảnh báo PO.

**Quy tắc áp dụng.** BR-20-009, BR-20-039.

**Màn hình, API.** UI-20-03; API-20-072, 074, 085; kịch bản TS-20-23.
:::

### 6.24. UC-20-24 · Lập kế hoạch và bảng ánh xạ sáp nhập

Khi hai tỉnh sáp nhập theo quyết định hành chính, kế hoạch ghi căn cứ, tenant nguồn, đích, ngày hiệu lực, thời gian chuyển tiếp; bảng ánh xạ xác định trước mỗi đối tượng của tỉnh nguồn thành gì ở tỉnh đích.

::: dac-ta
**Mục tiêu.** Hà lập kế hoạch `SN-2026-001` sáp nhập `T67` (nguồn) vào `T68` (đích) với chuyển tiếp 6 tháng, rồi dùng "Gợi ý tự động" lập ánh xạ tổ chức, HTTT, mã danh mục, tiền tố API, người dùng, topic và quyết từng dòng.

**Tác nhân chính.** PA; TA hai tỉnh xem phần tỉnh mình, góp ý qua phiếu.

**Tác nhân phụ.** Các phân hệ tham gia sáp nhập (liệt kê đối tượng nguồn), PH-18.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-045 (phần lập), FR-20-046.

**Truy vết.** REQ-20; quy trình BP-12 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-merge`; nguồn và đích `ACTIVE`, đều `PROVINCE`, không thuộc kế hoạch khác chưa kết thúc.

**Kích hoạt.** UI-20-11 "+ Kế hoạch sáp nhập"; wizard UI-20-09 bước nguồn đích, căn cứ, ánh xạ.

**Đảm bảo tối thiểu.** Không dữ liệu nào di chuyển ở bước này; mỗi tenant thuộc tối đa một kế hoạch chưa kết thúc; không hai nguồn cùng `CREATE` ra một mã.

**Đảm bảo thành công.** Kế hoạch `DRAFT` mã `SN-2026-001`; bảng ánh xạ có đủ dòng, dòng bắt buộc đã quyết.

**Luồng chính.**
1. Hà nhập nguồn `T67`, đích `T68`, văn bản căn cứ, `effectiveDate`, `transitionMonths = 6`; hệ thống kiểm nguồn khác đích, đều `ACTIVE` và `PROVINCE`, không thuộc kế hoạch khác, `transitionMonths` ≤ `20.merge.transition-max-months`.
2. Hệ thống tạo kế hoạch `DRAFT`, kiểm phân hệ bật ở nguồn có bật ở đích (thiếu thì cảnh báo, gợi ý UC-20-17).
3. Hà bấm "Gợi ý tự động"; hệ thống gọi từng phân hệ tham gia liệt kê đối tượng nguồn theo `MergeMappingType` và đề xuất `MAP` (trùng mã và tên ở đích) hoặc `CREATE` (giữ mã, hoặc thêm hậu tố `-T67` khi trùng mã khác nghĩa).
4. Hà sửa từng dòng; hệ thống kiểm `targetCode` tồn tại ở đích khi `MAP` và không hai nguồn cùng `CREATE` ra một mã.
5. Hệ thống đánh dấu dòng bắt buộc (tổ chức, HTTT, tiền tố API) chưa quyết; ánh xạ `API_CONTEXT_PATH` là nguồn bảng chuyển tiếp PH-03 đọc ở cutover (UC-20-28).

**Luồng thay thế.**
- **Hủy.** Hà hủy kế hoạch `DRAFT` hoặc trước `CUTOVER` (UC-20-25 mô tả hậu quả khi đã `TRANSFERRING`).

**Luồng ngoại lệ.**
- **E1. Kế hoạch không hợp lệ (bước 1).** ERR-20-040 (422): "Kế hoạch sáp nhập không hợp lệ: {lý do}."
- **E2. Tenant thuộc kế hoạch khác (bước 1).** ERR-20-041 (409): "Tenant {mã} đang thuộc kế hoạch sáp nhập {kế hoạch}."
- **E3. Chuyển tiếp quá dài (bước 1).** ERR-20-045 (422): "Thời gian chuyển tiếp tối đa {số} tháng."
- **E4. Mã đích không tồn tại hoặc trùng (bước 4).** ERR-20-002 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem." hoặc ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E5. Phân hệ tham gia không trả danh sách (bước 3).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-20-008, BR-20-022, BR-20-023, BR-20-024, BR-20-025.

**Màn hình, API.** UI-20-08, UI-20-09, UI-20-11; API-20-086, 087, 088, 089, 093, 094, 095, 096; kịch bản TS-20-24.
:::

### 6.25. UC-20-25 · Chạy thử, gửi duyệt và duyệt kế hoạch sáp nhập

Trước khi duyệt phải biết sẽ chuyển bao nhiêu bản ghi, bao nhiêu xung đột, mất bao lâu, mà không ghi gì vào tenant đích; việc duyệt cần người thứ hai.

::: dac-ta
**Mục tiêu.** Hà chạy thử `SN-2026-001`, thấy 184.000 bản ghi, 37 xung đột dự kiến, ước 5 giờ; gửi duyệt, Khoa duyệt; TA hai tỉnh được báo.

**Tác nhân chính.** PA (Hà lập, gửi; Khoa duyệt).

**Tác nhân phụ.** PH-18 (`merge-transfers` với `dryRun = true`), các phân hệ tham gia, TA hai tỉnh.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-047, FR-20-045 (phần gửi duyệt, duyệt).

**Truy vết.** REQ-20; quy trình BP-12 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-merge`, Khoa có `PERM-20-approve`; kế hoạch `DRAFT`, không còn dòng ánh xạ bắt buộc chưa quyết.

**Kích hoạt.** UI-20-09 bước "Chạy thử" và "Gửi duyệt"; UI-20-10 "Chạy thử lại"; hộp duyệt UI-20-08.

**Đảm bảo tối thiểu.** Chạy thử không ghi vào đích; chạy thử cũ so với bảng ánh xạ (`mappingHash` đổi) không dùng để gửi duyệt; người lập, gửi không duyệt.

**Đảm bảo thành công.** `dryRunResult = PASSED` còn hợp lệ; kế hoạch `APPROVED`.

**Luồng chính.**
1. Hà bấm "Chạy thử"; hệ thống kiểm ánh xạ đủ, kế hoạch `DRY_RUN`.
2. Hệ thống gọi PH-18 `merge-transfers` với `dryRun = true` từng phân hệ; PH-18 gọi xuất của nguồn và kiểm nhập của đích trên bản sao không ghi.
3. PH-18 báo qua API-20-167 số bản ghi, số xung đột dự kiến theo loại, thời gian ước tính; hệ thống ghi EN-20-27 `phase = DRY_RUN`, EN-20-28 dự kiến.
4. Đủ báo: kế hoạch về `DRAFT`, `dryRunResult = PASSED` khi không phân hệ nào lỗi, ghi `mappingHash`.
5. Hà bấm "Gửi duyệt"; hệ thống kiểm chạy thử đạt và còn hợp lệ, kế hoạch `PENDING_APPROVAL`.
6. Khoa duyệt; hệ thống kiểm Khoa khác người lập, gửi; kế hoạch `APPROVED`, báo TA hai tỉnh.

**Luồng thay thế.**
- **4a. Có xung đột dự kiến vẫn `PASSED`.** Xung đột xử lý ở UC-20-27; chỉ lỗi kỹ thuật làm `FAILED`.
- **6a. Từ chối.** Kế hoạch `REJECTED` kèm ý kiến.
- **Hủy sau khi chuyển.** Nếu hủy khi đã `TRANSFERRING`, PH-18 gỡ dữ liệu đã chuyển theo `origin_tenant_id`, nguồn về `ACTIVE`.

**Luồng ngoại lệ.**
- **E1. Ánh xạ chưa đủ (bước 1).** ERR-20-042 (422): "Bảng ánh xạ còn {số} dòng bắt buộc chưa quyết định."
- **E2. Đang chạy thử (bước 1).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E3. Chạy thử chưa đạt hoặc đã cũ (bước 5).** ERR-20-043 (422): "Chạy thử sáp nhập chưa đạt hoặc đã cũ so với bảng ánh xạ hiện hành."
- **E4. Tự duyệt (bước 6).** ERR-20-007 (403): "Anh/chị là người {vai} nên không được {thao tác}. Cần một quản trị nền tảng khác duyệt."
- **E5. Phân hệ lỗi khi chạy thử (bước 2, chạy nền).** ERR-20-113: "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}." hoặc ERR-20-107; `dryRunResult = FAILED`.

**Quy tắc áp dụng.** BR-20-008, BR-20-024.

**Màn hình, API.** UI-20-08, UI-20-09, UI-20-10, UI-20-11; API-20-090, 091, 092, 097, 167; kịch bản TS-20-25.
:::

```{.mermaid caption="Trình tự chạy thử, gửi duyệt và duyệt kế hoạch sáp nhập"}
sequenceDiagram
  actor Ha as Hà (lập)
  actor Khoa as Khoa (duyệt)
  participant K as PH-20
  participant O as PH-18
  participant M as Các phân hệ
  Ha->>K: Chạy thử SN-2026-001
  K->>O: merge-transfers dryRun true từng phân hệ
  O->>M: Xuất nguồn và kiểm nhập đích trên bản sao
  O-->>K: API-20-167 số bản ghi, xung đột, thời gian
  K->>K: dryRunResult PASSED, ghi mappingHash
  Ha->>K: Gửi duyệt
  Khoa->>K: Duyệt
  K->>K: Kiểm Khoa khác Hà, APPROVED, báo TA hai tỉnh
```

Hình cho thấy chạy thử đi qua PH-18 nhưng không ghi vào đích, và kế hoạch chỉ `APPROVED` khi chạy thử còn khớp ánh xạ hiện hành.

### 6.26. UC-20-26 · Điều phối chuyển dữ liệu sáp nhập theo phân hệ

Dữ liệu tỉnh nguồn được chuyển sang tỉnh đích từng phân hệ một, đúng thứ tự phụ thuộc, có kiểm đếm, trong khi tỉnh nguồn vẫn phục vụ.

::: dac-ta
**Mục tiêu.** Hà bắt đầu chuyển `SN-2026-001`; hệ thống chuyển `T67` sang `MERGING` và chạy tuần tự tổ chức, danh mục, HTTT, API, topic, luồng; mỗi phân hệ báo tiến độ và kiểm đếm khớp.

**Tác nhân chính.** PA.

**Tác nhân phụ.** PH-18 và các phân hệ tham gia (báo API-20-167, scope `tenant:provision-report`), TA hai tỉnh (xem tiến độ).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-048.

**Truy vết.** REQ-20; quy trình BP-12 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-merge`; kế hoạch `APPROVED`, đã tới `effectiveDate` (hoặc chạy sớm có lý do); chạy thử còn hợp lệ.

**Kích hoạt.** UI-20-10 "Bắt đầu chuyển".

**Đảm bảo tối thiểu.** Dữ liệu chuyển giữ `id` gốc và ghi `origin_tenant_id`; xung đột không bao giờ ghi đè tự động; lệnh lũy đẳng theo `{mergePlanId}:{module}:transfer`.

**Đảm bảo thành công.** Mọi phân hệ `SUCCEEDED` có số bản ghi nguồn và đích khớp (trừ `SKIP`); kế hoạch sang `IDENTITY_TRANSFER` (hoặc `CONFLICT_REVIEW` khi có xung đột).

**Luồng chính.**
1. Hà bấm "Bắt đầu chuyển"; hệ thống kiểm kế hoạch `APPROVED` và chạy thử còn hợp lệ.
2. Hệ thống chuyển `T67` sang `MERGING`, kế hoạch `TRANSFERRING`, phát EVT-20-10 và EVT-20-04.
3. Hệ thống gọi `merge-transfers` từng phân hệ theo thứ tự phụ thuộc: tổ chức (PH-20), PH-07, PH-01, PH-02, PH-10, PH-04 và PH-05, PH-03, các phân hệ khác; phân hệ độc lập chạy song song.
4. Mỗi báo tiến độ cập nhật EN-20-27; khi phân hệ báo `SUCCEEDED`, hệ thống so số bản ghi nguồn và đích.
5. Có xung đột: kế hoạch `CONFLICT_REVIEW` (UC-20-27); mọi phân hệ `SUCCEEDED`: kế hoạch sang `IDENTITY_TRANSFER`.

**Luồng thay thế.**
- **3a. Phân hệ lỗi.** Hà bấm "Chạy lại phân hệ" (API-20-100).
- **4a. Dữ liệu phát sinh ở nguồn khi đang chuyển.** Mỗi phân hệ chạy lượt bù (delta) cuối theo `updated_at` ngay trước cutover (UC-20-28).

**Luồng ngoại lệ.**
- **E1. Chạy thử cũ (bước 1).** ERR-20-043 (422): "Chạy thử sáp nhập chưa đạt hoặc đã cũ so với bảng ánh xạ hiện hành."
- **E2. Trạng thái không phù hợp (bước 1).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E3. Báo tiến độ sai trạng thái (bước 4, bên gọi máy).** ERR-20-114 (409): "Báo tiến độ sáp nhập không khớp trạng thái của {phân hệ}."
- **E4. Kiểm đếm lệch (bước 4, chạy nền).** ERR-20-113: "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}." Phân hệ `FAILED`.

**Quy tắc áp dụng.** BR-20-022, BR-20-023.

**Màn hình, API.** UI-20-10; API-20-088, 098, 099, 100, 167; kịch bản TS-20-26.
:::

```{.mermaid caption="Trình tự điều phối chuyển dữ liệu sáp nhập"}
sequenceDiagram
  actor Ha as Hà (PA)
  participant K as PH-20
  participant O as PH-18
  participant M as Phân hệ theo thứ tự
  Ha->>K: Bắt đầu chuyển SN-2026-001
  K->>K: T67 MERGING, EVT-20-10 và EVT-20-04
  K->>O: merge-transfers cho phân hệ đầu tiên
  O->>M: Xuất nguồn, nhập đích, kiểm đếm
  O-->>K: API-20-167 SUCCEEDED hoặc có xung đột
  K->>K: So số bản ghi nguồn và đích
  K->>O: Phân hệ kế tiếp theo thứ tự phụ thuộc
```

Hình cho thấy PH-20 chỉ điều phối, PH-18 chạy công cụ chuyển và mỗi phân hệ có kiểm đếm riêng trước khi sang phân hệ phụ thuộc.

### 6.27. UC-20-27 · Xử lý xung đột sáp nhập

Hai tỉnh có cùng mã khác nghĩa (danh mục địa phương, mã HTTT, tên tổ chức) được cán bộ quyết từng trường hợp, công cụ không bao giờ ghi đè.

::: dac-ta
**Mục tiêu.** Hà xử lý 37 xung đột: giữ bản đích, đổi tên bản nguồn, gộp mục danh mục, hoặc bỏ qua; xử lý hàng loạt các xung đột cùng loại.

**Tác nhân chính.** PA; TA tỉnh đích góp ý qua phiếu.

**Tác nhân phụ.** PH-18 (tiếp tục phần dính xung đột).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-049.

**Truy vết.** REQ-20; quy trình BP-12 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-merge`; kế hoạch `CONFLICT_REVIEW` hoặc `TRANSFERRING` có xung đột mở.

**Kích hoạt.** UI-20-10 tab "Xung đột": chọn cách xử lý từng dòng hoặc hàng loạt.

**Đảm bảo tối thiểu.** Không chuyển định danh hay cutover khi còn xung đột mở; mã mới (`RENAME_SOURCE`) chưa dùng.

**Đảm bảo thành công.** Xung đột có quyết định (`KEEP_TARGET`, `KEEP_SOURCE`, `RENAME_SOURCE`, `MERGE_ITEMS`, `SKIP`); hết xung đột mở thì kế hoạch về `TRANSFERRING`.

**Luồng chính.**
1. Hệ thống hiện xung đột kèm hai bản (nguồn, đích) cạnh nhau bằng `CMP-DiffViewer`.
2. Hà chọn cách xử lý; hệ thống kiểm cách hợp lệ với loại đối tượng (`MERGE_ITEMS` chỉ cho danh mục) và `newCode` chưa dùng.
3. Hệ thống lưu quyết định, gửi lệnh tiếp tục cho phân hệ qua PH-18 cho phần dính xung đột.
4. Hết xung đột mở: kế hoạch về `TRANSFERRING`.

**Luồng thay thế.**
- **2a. Hàng loạt.** Áp một cách cho tối đa 500 xung đột cùng loại (API-20-103).

**Luồng ngoại lệ.**
- **E1. Cách xử lý không hợp lệ (bước 2).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E2. Mã mới trùng (bước 2).** ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E3. Chuyển định danh hoặc cutover khi còn xung đột.** ERR-20-044 (409): "Còn {số} xung đột sáp nhập chưa xử lý."

**Quy tắc áp dụng.** BR-20-023, BR-20-024.

**Màn hình, API.** UI-20-10; API-20-101, 102, 103; kịch bản TS-20-27.
:::

### 6.28. UC-20-28 · Chuyển định danh, cấp song song thông tin xác thực và cutover

Người dùng và HTTT của tỉnh nguồn được tạo lại ở tỉnh đích, thông tin xác thực cũ và mới cùng dùng được trong thời gian chuyển tiếp; tại cutover tenant nguồn chỉ đọc và lượt gọi được chuyển tiếp.

::: dac-ta
**Mục tiêu.** Hà chuyển định danh `T67` sang realm `T68`, cấp client mới cho từng HTTT, rồi trong cửa sổ bảo trì của cả hai tỉnh thực hiện cutover: `T67` thành `MERGED`, PH-03 chuyển tiếp lượt gọi kèm `Deprecation`, `Sunset`.

**Tác nhân chính.** PA.

**Tác nhân phụ.** PH-12 (API-12-045, 046, `iam:realm-provision`), PH-03 (FR-03-037, EVT-03-10), PH-01 (chuyển HTTT), PH-18 (thư hướng dẫn, lượt bù cuối).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-050, FR-20-051.

**Truy vết.** REQ-20; quy trình BP-12 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-merge`; kế hoạch `IDENTITY_TRANSFER`; mọi phân hệ `SUCCEEDED`; không xung đột mở; cutover nằm trong cửa sổ bảo trì của hai tỉnh.

**Kích hoạt.** UI-20-10 "Chuyển định danh" rồi "Thực hiện cutover" (gõ lại mã kế hoạch).

**Đảm bảo tối thiểu.** Thông tin xác thực cũ vẫn dùng được tới `transitionEndsAt`; lượt bù cuối lệch kiểm đếm thì cutover dừng và nguồn bỏ chỉ đọc; không tự quay lui khi lỗi chuyển tiếp vượt ngưỡng, chỉ cảnh báo.

**Đảm bảo thành công.** `T67` `MERGED` với `merged_into_id = T68`, kế hoạch `TRANSITION`, `transitionEndsAt = now + 6 tháng`, bảng chuyển tiếp có ở API-20-164.

**Luồng chính.**
1. Hà bấm "Chuyển định danh"; hệ thống kiểm không còn xung đột, gọi API-12-045 lập kế hoạch định danh theo ánh xạ `USER`.
2. Hệ thống gọi API-12-046; PH-12 tạo người dùng ở realm đích (buộc đặt lại mật khẩu, Q20-13), cấp client mới cho mỗi HTTT với hạn bằng `transitionEndsAt`.
3. Hệ thống ghi trạng thái thông tin xác thực song song (`ISSUED`, `IN_USE_NEW`, `OLD_ONLY`) và gửi thư hướng dẫn cho đầu mối kỹ thuật từng HTTT; kế hoạch sẵn sàng `CUTOVER`.
4. Trong cửa sổ bảo trì, Hà bấm "Thực hiện cutover"; hệ thống kiểm điều kiện, đặt nguồn chỉ đọc, yêu cầu mỗi phân hệ chạy lượt bù cuối qua PH-18 và chờ báo.
5. Hệ thống chuyển `T67` `MERGED`, kế hoạch `TRANSITION`, ghi bảng chuyển tiếp, phát EVT-20-11 và EVT-20-04; PH-03 bật chuyển tiếp và phát EVT-03-10, PH-12 khóa đăng nhập mới ở realm nguồn, PH-01 chuyển HTTT sang tỉnh đích.
6. Hệ thống theo dõi 60 phút đầu tỷ lệ lỗi lượt gọi chuyển tiếp; vượt 1% thì cảnh báo Hà.

**Luồng thay thế.**
- **3a. Tổ chức kế thừa.** PH-01 nhận EVT-20-13 và tự tạo đề nghị đổi chủ quản HTTT chờ TA đích duyệt hàng loạt.
- **5a. Không nhận EVT-03-10 sau 15 phút.** Cảnh báo PO.

**Luồng ngoại lệ.**
- **E1. Còn xung đột (bước 1, 4).** ERR-20-044 (409): "Còn {số} xung đột sáp nhập chưa xử lý."
- **E2. Ngoài cửa sổ bảo trì (bước 4).** ERR-20-059 (422): "Cửa sổ bảo trì không hợp lệ: {lý do}."
- **E3. PH-12 lỗi (bước 1, 2).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."
- **E4. Trạng thái không phù hợp (bước 1, 4).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E5. Lượt bù cuối lệch kiểm đếm (bước 4, chạy nền).** ERR-20-113: "Kiểm đếm {phân hệ} lệch: nguồn {n1}, đích {n2}."
- **E6. Ghi vào tenant `MERGED` sau cutover.** ERR-20-115 (409): "Tỉnh đã sáp nhập vào {đích}. Dữ liệu chỉ còn để tra cứu."

**Quy tắc áp dụng.** BR-20-024, BR-20-025, BR-20-026.

**Màn hình, API.** UI-20-10; API-12-045, 046; API-20-104, 105, 106, 164; kịch bản TS-20-28.
:::

```{.mermaid caption="Trình tự chuyển định danh và cutover sáp nhập"}
sequenceDiagram
  actor Ha as Hà (PA)
  participant K as PH-20
  participant I as PH-12
  participant G as PH-03, PH-01
  Ha->>K: Chuyển định danh SN-2026-001
  K->>I: API-12-045 và 046 tạo người dùng, client song song
  I-->>K: HTTT ở trạng thái ISSUED
  Ha->>K: Cutover trong cửa sổ bảo trì
  K->>K: T67 chỉ đọc, lượt bù cuối
  K->>G: EVT-20-11 và EVT-20-04 MERGED
  G-->>K: EVT-03-10 chuyển tiếp đã bật
  K->>K: Kế hoạch TRANSITION, đặt transitionEndsAt
```

Hình cho thấy thông tin xác thực mới được cấp trước cutover; sau cutover lượt gọi cũ vẫn chạy nhờ chuyển tiếp tới khi kết thúc sáp nhập.

### 6.29. UC-20-29 · Kết thúc sáp nhập sau thời gian chuyển tiếp

Khép lại sáp nhập: tắt chuyển tiếp, thu hồi thông tin xác thực cũ, chuyển tenant nguồn `DECOMMISSIONED`; cho gia hạn có lý do khi HTTT chưa chuyển xong.

::: dac-ta
**Mục tiêu.** Hà nhận danh sách HTTT còn dùng thông tin cũ trước hạn 30, 7, 1 ngày; tới `transitionEndsAt` hệ thống kết thúc sáp nhập, hoặc Hà gia hạn thêm 2 tháng cho 3 HTTT chưa chuyển.

**Tác nhân chính.** PA.

**Tác nhân phụ.** PH-12 (thu hồi client cũ), PH-13 (API-13-073), PH-16 (nhận EVT-20-12), PH-09 (xóa mật mã), đầu mối HTTT.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-052.

**Truy vết.** REQ-20; quy trình BP-12 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-merge`; kế hoạch `TRANSITION`.

**Kích hoạt.** Tự động tại `transitionEndsAt`; UI-20-10 "Gia hạn", "Kết thúc ngay".

**Đảm bảo tối thiểu.** Không kết thúc sớm khi còn HTTT `OLD_ONLY`; tổng chuyển tiếp không vượt `20.merge.transition-max-months`; xóa mật mã nguồn không đảo ngược (BR-20-020).

**Đảm bảo thành công.** Kế hoạch `COMPLETED`, `T67` `DECOMMISSIONED`, dữ liệu nguồn giữ chỉ đọc ở kho lưu trữ theo Q20-01 rồi xóa mật mã như UC-20-22.

**Luồng chính.**
1. Trước `transitionEndsAt` 30, 7, 1 ngày hệ thống gửi đầu mối danh sách HTTT còn `OLD_ONLY`.
2. Tại `transitionEndsAt` hoặc khi Hà bấm "Kết thúc ngay", hệ thống kiểm đã hết chuyển tiếp hoặc không còn HTTT dùng thông tin cũ.
3. Hệ thống tắt chuyển tiếp (EVT-20-12), yêu cầu PH-12 thu hồi client cũ, gọi API-13-073 đóng chuỗi kiểm toán nguồn, chuyển nguồn `DECOMMISSIONED` (EVT-20-04).
4. Kế hoạch `COMPLETED`; PH-16 nhận EVT-20-12 để gộp lịch sử chỉ tiêu.

**Luồng thay thế.**
- **2a. Gia hạn.** Hà bấm "Gia hạn" kèm lý do; hệ thống kiểm tổng ≤ tối đa rồi dời `transitionEndsAt`.

**Luồng ngoại lệ.**
- **E1. Kết thúc sớm khi còn HTTT dùng thông tin cũ (bước 2).** ERR-20-046 (409): "Chưa hết thời gian chuyển tiếp (đến {ngày}) và còn {số} HTTT dùng địa chỉ cũ."
- **E2. Gia hạn quá tối đa (bước 2a).** ERR-20-045 (422): "Thời gian chuyển tiếp tối đa {số} tháng."

**Quy tắc áp dụng.** BR-20-020, BR-20-025.

**Màn hình, API.** UI-20-10; API-20-107, 108; kịch bản TS-20-29.
:::

### 6.30. UC-20-30 · Quản lý danh mục tổ chức, nhập, xuất và chủ quản dữ liệu

Danh mục tổ chức dạng cây là danh mục chuẩn của tỉnh mà mọi phân hệ dùng; quản trị tỉnh tạo, sửa, nhập hàng loạt từ tệp có xem trước, xuất để đối chiếu và đánh dấu tổ chức chủ quản dữ liệu.

::: dac-ta
**Mục tiêu.** Mai tạo Sở Khoa học và Công nghệ `SO-KHCN` dưới UBND tỉnh, nhập 142 UBND cấp xã từ tệp Excel sau khi xem trước từng dòng, đánh dấu Sở KH&CN là chủ quản dữ liệu; Lan và Hùng xem cây.

**Tác nhân chính.** TA; DS, VW xem.

**Tác nhân phụ.** Dịch vụ quét mã độc, PH-06, PH-08 (đếm đối tượng được giao), PH-07 (ĐVHC).

**Mức ưu tiên.** M · MVP (FR-20-058 mức S).

**FR hiện thực.** FR-20-053, FR-20-055, FR-20-058.

**Truy vết.** REQ-20; quy trình BP-01; hệ cũ: LGC-IAM-002 (gián tiếp).

**Tiền điều kiện.** Mai có `PERM-20-org`; tenant `ACTIVE`; tổ chức gieo từ `S13_ORG_SEED`; tệp nhập tối đa `20.org.import-max-rows` dòng.

**Kích hoạt.** UI-20-14 "+ Tổ chức", "Xuất", lọc "Chủ quản dữ liệu"; UI-20-15 sửa, công tắc "Chủ quản dữ liệu"; UI-20-16 tải tệp.

**Đảm bảo tối thiểu.** Mã tổ chức duy nhất trong tenant kể cả tổ chức đã giải thể; cây không chu trình; không xóa cứng; lô nhập ghi một giao dịch, cha trước con.

**Đảm bảo thành công.** Tổ chức `ACTIVE` với hiệu lực từ ngày đến ngày; EVT-20-13 phát (`CREATED`, `UPDATED`, `BULK_IMPORT`, `DATA_OWNER`).

**Luồng chính.**
1. Mai nhập mã `SO-KHCN`, tên, loại `DEPARTMENT`, cấp trên, `adminUnitId`, hiệu lực; hệ thống kiểm mã theo `^[A-Z0-9][A-Z0-9-]{1,49}$`, duy nhất, cha tồn tại và `ACTIVE`, không chu trình, ngày hợp lệ.
2. Hệ thống lưu tổ chức `ACTIVE`, phát EVT-20-13; cây hiển thị theo `asOf` (mặc định hôm nay).
3. Mai tải tệp nhập ở UI-20-16; hệ thống kiểm định dạng, cột, số dòng, quét mã độc, kiểm từng dòng (kể cả cha trong cùng tệp), gán `CREATE`, `UPDATE`, `UNCHANGED`, `ERROR`.
4. Mai xem trước, sửa tệp nếu có lỗi, bấm "Xác nhận nhập"; hệ thống ghi trong một giao dịch và phát một EVT-20-13 gộp.
5. Mai bật công tắc "Chủ quản dữ liệu" cho `SO-KHCN`; hệ thống lưu, phát EVT-20-13 (`change = DATA_OWNER`).

**Luồng thay thế.**
- **1a. Đổi cấp trên (sắp xếp bộ máy).** Lưu lịch sử cha cũ kèm hiệu lực; báo cáo theo ngày cũ hiện cha cũ.
- **2a. Xuất.** XLSX hoặc CSV theo bộ lọc hiện hành, có cột trạng thái, kế thừa; "Tải tệp mẫu".
- **5a. Bỏ đánh dấu.** Hệ thống hỏi PH-06, PH-08 số đối tượng đang giao cho tổ chức.

**Luồng ngoại lệ.**
- **E1. Mã sai mẫu (bước 1).** ERR-20-004 (400): "{Trường} chưa hợp lệ: {yêu cầu}."
- **E2. Mã trùng (bước 1).** ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E3. Cấp trên không hợp lệ hoặc chu trình (bước 1).** ERR-20-047 (422): "Tổ chức cấp trên {mã} không hợp lệ: {lý do}."
- **E4. ĐVHC không hợp lệ (bước 1).** ERR-20-012 (422): "Đơn vị hành chính {mã} không phải cấp tỉnh hoặc đã hết hiệu lực."
- **E5. Hiệu lực sai (bước 1).** ERR-20-052 (422): "Ngày hết hiệu lực phải sau hoặc bằng ngày bắt đầu hiệu lực."
- **E6. Tệp không hợp lệ hoặc quá số dòng (bước 3).** ERR-20-050 (422): "Tệp nhập không hợp lệ: {lý do}."
- **E7. Còn dòng lỗi khi xác nhận (bước 4).** ERR-20-051 (422): "Còn {số} dòng lỗi. Sửa tệp rồi tải lại."
- **E8. Lô quá 24 giờ hoặc tổ chức không hoạt động (bước 4, 5).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E9. Bỏ đánh dấu khi còn đối tượng được giao (bước 5a).** ERR-20-049 (409): "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."

**Quy tắc áp dụng.** BR-20-027, BR-20-028.

**Màn hình, API.** UI-20-14, UI-20-15, UI-20-16; API-20-143, 144, 145, 146, 152, 153, 154, 155, 156, 171; kịch bản TS-20-30.
:::

### 6.31. UC-20-31 · Giải thể, hợp nhất tổ chức và đồng bộ khi sắp xếp ĐVHC

Sắp xếp bộ máy (sở hợp nhất, xã sáp nhập) không được làm mất liên kết của HTTT, người dùng, dữ liệu đang trỏ tới tổ chức cũ; hệ thống đề xuất sẵn thay đổi khi danh mục ĐVHC quốc gia đổi.

::: dac-ta
**Mục tiêu.** Mai giải thể UBND xã `XA-0123` kế thừa bởi `XA-0456`; khi PH-07 phát EVT-07-10 xã sáp nhập, Mai nhận đề xuất đồng bộ, chỉnh và áp.

**Tác nhân chính.** TA; hệ thống (nghe EVT-07-10).

**Tác nhân phụ.** PH-07 (EVT-07-10), PH-01 (đề nghị đổi chủ quản HTTT), PH-12, PH-06, PH-08 (đếm tham chiếu).

**Mức ưu tiên.** M · MVP (FR-20-056 mức S).

**FR hiện thực.** FR-20-054, FR-20-056.

**Truy vết.** REQ-20; quy trình BP-03; hệ cũ: LGC-IAM-002 (gián tiếp).

**Tiền điều kiện.** Mai có `PERM-20-org`; tổ chức `ACTIVE` hoặc `INACTIVE`; đề xuất đồng bộ cần tổ chức `COMMUNE_PC` có `adminUnitId` trỏ tới ĐVHC bị sắp xếp.

**Kích hoạt.** UI-20-15 "Ngừng", "Hoạt động lại", "Giải thể", "Sáp nhập vào"; UI-20-14 chọn nhiều tổ chức; EVT-07-10 và tab "Đề xuất đồng bộ".

**Đảm bảo tối thiểu.** Đồng bộ ĐVHC chỉ tạo đề xuất, không tự áp (BR-20-029); không giải thể khi còn tham chiếu mà thiếu kế thừa hợp lệ; sự kiện xử lý lũy đẳng theo `eventId`.

**Đảm bảo thành công.** Tổ chức `DISSOLVED` hoặc `MERGED` có `effective_to`, `successor_id`; tổ chức con chuyển cha; EVT-20-13 phát; PH-01 có đề nghị đổi chủ quản chờ TA duyệt.

**Luồng chính.**
1. Mai chọn "Giải thể" `XA-0123`; hệ thống đếm tham chiếu đang hoạt động (HTTT ở PH-01, người dùng ở PH-12, chủ quản dữ liệu).
2. Mai chọn tổ chức kế thừa `XA-0456`; hệ thống kiểm kế thừa `ACTIVE`, khác chính nó, cùng tenant.
3. Hệ thống đặt `DISSOLVED`, `effective_to`, `successor_id`, chuyển tổ chức con sang kế thừa sau khi Mai xác nhận danh sách, phát EVT-20-13.
4. Khi nhận EVT-07-10 (inbox lũy đẳng), hệ thống tìm tổ chức liên quan ở mọi tenant tỉnh và tạo đề xuất: tạo tổ chức cho ĐVHC mới, giải thể tổ chức cũ kế thừa là tổ chức mới.
5. Mai mở tab "Đề xuất đồng bộ", chỉnh rồi "Áp" (chạy như bước 1 đến 3) hoặc "Bỏ" có lý do.

**Luồng thay thế.**
- **1a. Ngừng, hoạt động lại.** `INACTIVE` không cần kế thừa; "Hoạt động lại" về `ACTIVE`.
- **4a. Không có tổ chức liên quan.** Không sinh đề xuất; tỉnh tự làm trước thì đề xuất đánh `ALREADY_APPLIED`.
- **1b. Sáp nhập nhiều tổ chức vào một.** "Sáp nhập" ở UI-20-14, đặt `MERGED` với kế thừa chung.

**Luồng ngoại lệ.**
- **E1. Còn tham chiếu mà thiếu kế thừa (bước 1, 5).** ERR-20-049 (409): "Tổ chức {mã} còn {số} đối tượng tham chiếu. Chọn tổ chức kế thừa."
- **E2. Kế thừa không hợp lệ (bước 2).** ERR-20-048 (422): "Tổ chức kế thừa {mã} không hợp lệ: {lý do}."
- **E3. Trạng thái cuối hoặc đề xuất đã xử lý (bước 1, 5).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Phân hệ đếm tham chiếu không trả lời (bước 1).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-20-027, BR-20-028, BR-20-029.

**Màn hình, API.** UI-20-14, UI-20-15; API-20-147, 148, 149, 150, 151, 157, 158; kịch bản TS-20-31.
:::

### 6.32. UC-20-32 · Quản lý phiên bản sản phẩm và kênh phát hành

Có một danh mục phiên bản duy nhất, mỗi bản liệt kê thành phần, digest, thay đổi lược đồ, ghi chú; bản mới đi qua `PREVIEW` ở tỉnh thí điểm rồi mới sang `STABLE`.

::: dac-ta
**Mục tiêu.** Pipeline CI đăng ký phiên bản `1.4.0` ở `DRAFT`; Hà đưa lên `PREVIEW` cho `T68` (tỉnh thí điểm); sau 14 ngày không sự cố mức 1 Hà nâng lên `STABLE`; bản cũ ngoài số bản phụ được hỗ trợ bị đánh dấu ngừng.

**Tác nhân chính.** PA; PO, PAU xem.

**Tác nhân phụ.** Pipeline CI (tài khoản máy, cosign, SBOM), PH-18 (nhận EVT-20-14).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-059, FR-20-060.

**Truy vết.** REQ-20; quy trình BP-13 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-release`; ảnh đã qua CI, có chữ ký cosign; `STABLE` cần phiên bản đã `PREVIEW`; đổi kênh tenant cần không có kế hoạch nâng cấp đang chạy.

**Kích hoạt.** UI-20-18 "+ Phiên bản", "Đưa lên PREVIEW", "Nâng lên STABLE", "Ngừng hỗ trợ", "Rút"; UI-20-03 "Đổi kênh".

**Đảm bảo tối thiểu.** Phiên bản bất biến từ `PREVIEW`; bản `WITHDRAWN` không tenant mới nâng lên; mọi ảnh có chữ ký hợp lệ.

**Đảm bảo thành công.** Phiên bản có trạng thái đúng, EVT-20-14 phát khi sang `PREVIEW` hoặc `STABLE`; đăng ký kênh của tenant ghi `release.yaml` qua UC-20-09.

**Luồng chính.**
1. CI gọi API-20-110 (hoặc Hà bấm "+ Phiên bản"); hệ thống kiểm SemVer, chưa tồn tại, lớn hơn bản cùng dòng, mỗi digest có chữ ký; lưu `DRAFT`.
2. Hà sửa ghi chú phát hành (được tới trước `PREVIEW`), rồi bấm "Đưa lên PREVIEW"; hệ thống kiểm thành phần đủ, phát EVT-20-14.
3. Sau khi chạy ổn ở tenant thí điểm, Hà bấm "Nâng lên STABLE"; hệ thống kiểm đã ở `PREVIEW` ít nhất `20.release.stable-soak-days` ngày và không sự cố mức 1 gắn phiên bản, phát EVT-20-14.
4. Hà đổi kênh của một tenant ở UI-20-03; hệ thống kiểm không có kế hoạch nâng cấp đang chạy cho tenant, ghi `release.yaml`.
5. Hà "Ngừng hỗ trợ" bản ngoài `20.release.supported-minors` hoặc "Rút" bản lỗi (`WITHDRAWN`).

**Luồng thay thế.**
- **3a. Bản vá khẩn** (`PATCH`, cờ `emergency`): được `STABLE` sau ít nhất 1 ngày khi PO duyệt.
- **1a. Cột "số tenant đang chạy".** Danh sách lấy từ EN-20-35.

**Luồng ngoại lệ.**
- **E1. Phiên bản không hợp lệ (bước 1).** ERR-20-053 (422): "Phiên bản sản phẩm {phiên bản} không hợp lệ: {lý do}."
- **E2. Phiên bản trùng (bước 1).** ERR-20-003 (409): "{Đối tượng} {mã} đã tồn tại. Chọn mã khác."
- **E3. Sửa thành phần sau `PREVIEW` (bước 2).** ERR-20-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}."
- **E4. Chưa đủ thí điểm (bước 3).** ERR-20-054 (422): "Phiên bản {phiên bản} mới thí điểm {số} ngày, cần tối thiểu {ngưỡng} ngày và không có sự cố mức 1."
- **E5. Đổi kênh khi đang nâng cấp (bước 4).** ERR-20-061 (409): "Tenant {mã} đang có kế hoạch nâng cấp {kế hoạch}. Đổi kênh sau khi kế hoạch kết thúc."

**Quy tắc áp dụng.** BR-20-030, BR-20-031, BR-20-034.

**Màn hình, API.** UI-20-03, UI-20-18; API-20-001, 109, 110, 111, 112, 113, 114, 115, 116, 117; kịch bản TS-20-32.
:::

### 6.33. UC-20-33 · Lập kế hoạch nâng cấp theo sóng và thông báo lịch bảo trì

Hơn ba mươi tỉnh không nâng cùng lúc: sóng 1 là kênh `PREVIEW`, sóng 2 vài tỉnh nhỏ, sóng 3 phần còn lại, mỗi tỉnh đúng cửa sổ bảo trì của mình và được báo trước.

::: dac-ta
**Mục tiêu.** Hà lập kế hoạch `UP-2026-007` nâng cấp `1.4.0` theo ba sóng, lên lịch; hệ thống tính giờ nâng cấp từng tenant theo cửa sổ riêng và gửi thông báo trước 72 giờ và 2 giờ; Mai đặt cửa sổ ưa thích cho `T68`.

**Tác nhân chính.** PA; TA đặt cửa sổ ưa thích.

**Tác nhân phụ.** PH-18 (thư, thông báo trong ứng dụng), `dh-console` (banner).

**Mức ưu tiên.** M · MVP (FR-20-063 mức S).

**FR hiện thực.** FR-20-061, FR-20-063.

**Truy vết.** REQ-20; quy trình BP-13 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Hà có `PERM-20-release`; phiên bản `STABLE` (hoặc `PREVIEW` với tenant kênh `PREVIEW`); tenant đích chạy bản không thấp hơn `minFromVersion`.

**Kích hoạt.** UI-20-19 "+ Kế hoạch nâng cấp", "Lên lịch", "Gửi thông báo"; UI-20-12 đặt cửa sổ.

**Đảm bảo tối thiểu.** Mỗi tenant một kế hoạch; nâng cấp chỉ trong cửa sổ bảo trì; khẩn mới được bỏ chờ cửa sổ, kèm thông báo trước ít nhất `20.upgrade.emergency-notice-hours` giờ.

**Đảm bảo thành công.** Kế hoạch `SCHEDULED` với lịch từng tenant; EVT-20-15 phát khi trạng thái đổi; thông báo đã gửi và banner hiện từ 72 giờ trước.

**Luồng chính.**
1. Hà chọn phiên bản `1.4.0` ở UI-20-19 và "+ Kế hoạch nâng cấp"; hệ thống gợi ý sóng 1 tenant kênh `PREVIEW`, sóng 2 tối đa 5 tenant nhỏ, sóng 3 phần còn lại.
2. Hệ thống kiểm tenant đủ điều kiện (mỗi tenant một kế hoạch) và có cửa sổ bảo trì (mặc định thứ Bảy 22:00, 4 giờ, Q20-10).
3. Mai đặt cửa sổ ưa thích (dài 2 đến 6 giờ, ngoài giờ cao điểm 7:00 đến 17:00 ngày làm việc) ở UI-20-12; hệ thống áp cho kế hoạch lập sau.
4. Hà bấm "Lên lịch"; hệ thống tính thời điểm mỗi tenant là cửa sổ đầu tiên sau khi sóng trước hết thời gian theo dõi (`20.release.wave-soak-hours-minor` hoặc `-patch`).
5. Hệ thống dựng nội dung từ ghi chú phát hành và lịch tenant, gửi qua PH-18 trước 72 giờ và 2 giờ, hiện banner ở `dh-console`.

**Luồng thay thế.**
- **4a. Khẩn.** Bỏ chờ cửa sổ, gửi thông báo ngay kèm lý do.
- **5a. PA bấm "Gửi thông báo".** Gửi lại thủ công qua API-20-128.

**Luồng ngoại lệ.**
- **E1. Kế hoạch không hợp lệ (bước 2).** ERR-20-056 (422): "Kế hoạch nâng cấp không hợp lệ: {lý do}."
- **E2. Phiên bản không dùng được (bước 1).** ERR-20-055 (422): "Phiên bản {phiên bản} không dùng được cho thao tác này: {lý do}."
- **E3. Cửa sổ sai (bước 3).** ERR-20-059 (422): "Cửa sổ bảo trì không hợp lệ: {lý do}."
- **E4. PH-18 không gửi được (bước 5).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-20-032, BR-20-033.

**Màn hình, API.** UI-20-12, UI-20-19; API-20-118, 119, 120, 121, 128, 160; kịch bản TS-20-33.
:::

```{.mermaid caption="Trình tự lập kế hoạch nâng cấp theo sóng và thông báo"}
sequenceDiagram
  actor Ha as Hà (PA)
  actor Mai as Mai (TA T68)
  participant K as PH-20
  participant H as PH-18, dh-console
  Mai->>K: Đặt cửa sổ bảo trì ưa thích
  Ha->>K: Lập kế hoạch UP-2026-007 ba sóng
  K->>K: Kiểm tenant, cửa sổ, minFromVersion
  Ha->>K: Lên lịch
  K->>K: Tính giờ nâng cấp từng tenant
  K->>H: Thông báo trước 72 giờ và 2 giờ, banner
  K->>K: EVT-20-15 khi trạng thái đổi
```

Hình cho thấy cửa sổ do tỉnh đặt quyết định giờ nâng cấp của tỉnh đó, và thông báo đi trước khi nâng cấp bắt đầu.

### 6.34. UC-20-34 · Theo dõi nâng cấp, dừng sóng và quay lui

Mỗi tenant nâng cấp có kiểm tra sau nâng cấp; sóng tự dừng khi tỷ lệ lỗi vượt ngưỡng; quay lui được khi không có thay đổi lược đồ không tương thích.

::: dac-ta
**Mục tiêu.** Tới giờ cửa sổ của `T68`, hệ thống nâng cấp và kiểm tra; Tuấn thấy tỷ lệ lỗi 5xx của sóng 2 vượt 2%, dừng sóng; Hà xác nhận đã xử lý, tiếp tục, hoặc quay lui tenant lỗi.

**Tác nhân chính.** Hệ thống; PA (thao tác), PO (theo dõi, dừng sóng).

**Tác nhân phụ.** Argo CD, PH-13 (chỉ số lỗi), PH-18 (cảnh báo).

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-20-062.

**Truy vết.** REQ-20; quy trình BP-13 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Kế hoạch `SCHEDULED` hoặc `RUNNING`; PO có `PERM-20-release` chỉ để theo dõi và dừng sóng; tiếp tục, quay lui, thử lại, hủy cần PA.

**Kích hoạt.** Tới giờ cửa sổ; UI-20-19 "Dừng", "Tiếp tục", "Quay lui", "Thử lại", "Hủy kế hoạch".

**Đảm bảo tối thiểu.** Sóng dừng khi lỗi vượt `20.release.wave-error-threshold-percent` (2%) hoặc có tenant `FAILED`; thao tác ghi bị chặn bằng ERR-20-118 trong bảo trì; quay lui không phá lược đồ.

**Đảm bảo thành công.** Tenant `DONE` và bỏ banner, hoặc `ROLLED_BACK`; EVT-20-15 phát mỗi lần đổi trạng thái.

**Luồng chính.**
1. Tới giờ, hệ thống đặt banner bảo trì, ghi `release.yaml` bản mới, chờ Argo CD đồng bộ; tenant `UPGRADING`.
2. Hệ thống chạy kiểm tra sau nâng cấp trong `20.release.verify-minutes` phút (bộ khói của UC-20-07); đạt thì tenant `DONE`, bỏ banner.
3. Tỷ lệ lỗi 5xx của sóng vượt ngưỡng: hệ thống dừng sóng (`PAUSED`), cảnh báo; Tuấn có thể bấm "Dừng" sớm hơn.
4. Hà xác nhận đã xử lý rồi bấm "Tiếp tục"; hệ thống chạy tiếp các tenant còn lại.
5. Với tenant `FAILED`, Hà bấm "Quay lui": hệ thống ghi lại phiên bản trước vào `release.yaml`, tenant `ROLLED_BACK`.

**Luồng thay thế.**
- **5a. Thử lại.** Hà bấm "Thử lại" một tenant (API-20-127).
- **5b. Hủy.** Hà hủy kế hoạch chưa chạy (API-20-125).

**Luồng ngoại lệ.**
- **E1. Tiếp tục khi sóng dừng do ngưỡng (bước 4).** ERR-20-057 (409): "Sóng {sóng} đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục."
- **E2. Không quay lui được (bước 5).** ERR-20-058 (422): "Không quay lui được phiên bản {phiên bản} vì có thay đổi lược đồ không tương thích ở {phân hệ}."
- **E3. Kiểm tra sau nâng cấp không đạt (bước 2, chạy nền).** ERR-20-112: "Kiểm tra sau nâng cấp của {tenant} không đạt: {số} ca lỗi."
- **E4. Argo CD không áp được (bước 1, chạy nền).** ERR-20-109: "Argo CD không áp được cấu hình {phiên bản}: {lý do}."
- **E5. Thao tác ghi của tỉnh trong lúc bảo trì.** ERR-20-118 (503): "Tỉnh đang bảo trì nâng cấp đến {giờ}. Thao tác ghi tạm dừng."

**Quy tắc áp dụng.** BR-20-032, BR-20-033.

**Màn hình, API.** UI-20-19; API-20-119, 122, 123, 124, 125, 126, 127; kịch bản TS-20-34.
:::

```{.mermaid caption="Trình tự nâng cấp một sóng, dừng sóng và quay lui"}
sequenceDiagram
  participant K as PH-20
  participant A as Argo CD
  participant V as Kiểm tra sau nâng cấp
  actor Tuan as Tuấn (PO)
  actor Ha as Hà (PA)
  K->>A: Ghi release.yaml bản mới, banner bảo trì
  A-->>K: Synced, Healthy
  K->>V: Chạy bộ khói trong verify-minutes
  V-->>K: Đạt hoặc ERR-20-112
  K->>K: Lỗi 5xx của sóng vượt 2 phần trăm, PAUSED
  Tuan->>K: Theo dõi, dừng sóng
  Ha->>K: Xác nhận và tiếp tục hoặc quay lui
  K->>A: Ghi lại phiên bản trước, ROLLED_BACK
```

Hình cho thấy sóng tự dừng khi lỗi vượt ngưỡng và chỉ PA mới tiếp tục hoặc quay lui, PO chỉ theo dõi và dừng.

### 6.35. UC-20-35 · Xem bảng điều khiển đa tenant và kiểm thử rò rỉ chéo tenant

Một màn cho vận hành thấy tình hình mọi tenant; hằng đêm hệ thống chứng minh không tenant nào đọc được dữ liệu tenant khác (SEC-87) trên các tenant kiểm thử.

::: dac-ta
**Mục tiêu.** Tuấn xem số tenant theo trạng thái, thời gian khởi tạo p95, KPI-12, cảnh báo hạn mức, lệch, nâng cấp đang chạy, lần rò rỉ gần nhất; Hà chạy kiểm thử rò rỉ ngay trên `T91`, `T92`.

**Tác nhân chính.** PA, PO, PAU (xem); hệ thống theo lịch `20.leak-test.schedule`; PA chạy ngay.

**Tác nhân phụ.** PH-03 (danh mục API), PH-18 (mở sự cố mức 1), PH-13.

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-20-067, FR-20-070.

**Truy vết.** REQ-20; quy trình BP-07; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-20-read` để xem, `PERM-20-admin` để chạy kiểm thử; kiểm thử cần ít nhất hai tenant kiểm thử `ACTIVE` trong `T90…T99`.

**Kích hoạt.** UI-20-20; lịch hằng đêm 01:00; nút "Chạy ngay".

**Đảm bảo tối thiểu.** Kiểm thử rò rỉ chỉ trên `T90…T99`, không bao giờ trên tenant thật; phát hiện rò rỉ là sự cố mức 1.

**Đảm bảo thành công.** Thẻ `CMP-KpiCard` và danh sách cần xử lý đúng; mỗi lần kiểm thử có kết quả từng ca (`PASSED`, `FAILED`, `SKIPPED`).

**Luồng chính.**
1. Tuấn mở UI-20-20; hệ thống tổng hợp số tenant theo trạng thái, thời gian khởi tạo p95, KPI-12, cảnh báo hạn mức, lệch, nâng cấp, kết quả rò rỉ gần nhất; mỗi dòng cần xử lý dẫn tới màn chi tiết.
2. Tới 01:00 (hoặc Hà bấm "Chạy ngay"), hệ thống kiểm các tenant thuộc `T90…T99`.
3. Hệ thống gieo dữ liệu đánh dấu ở tenant đích, lấy danh mục API từ PH-03, gọi mọi API bằng danh tính tenant nguồn, kể cả tham số `tenantId` giả.
4. Không phản hồi nào chứa dữ liệu đánh dấu: lần kiểm `PASSED`; ca không áp dụng (API chỉ nền tảng) ghi `SKIPPED` có lý do.
5. Hà xem kết quả từng ca ở API-20-134.

**Luồng thay thế.**
- **1a. Số liệu sử dụng trễ.** Thẻ hiện mốc cập nhật cuối.
- **4a. Phát hiện rò rỉ.** Hệ thống mở sự cố mức 1 qua PH-18, báo Tuấn.

**Luồng ngoại lệ.**
- **E1. Tenant không phải kiểm thử (bước 2).** ERR-20-065 (422): "Kiểm thử rò rỉ chỉ chạy trên tenant kiểm thử T90…T99."
- **E2. Phát hiện rò rỉ (bước 4, chạy nền).** ERR-20-111: "Phát hiện rò rỉ chéo tenant ở {API}."
- **E3. Nguồn chỉ số lỗi (bước 1).** Thẻ hiện "Không có số liệu" kèm ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-20-038, BR-20-041.

**Màn hình, API.** UI-20-20; API-20-129, 132, 133, 134; kịch bản TS-20-35.
:::

### 6.36. UC-20-36 · Tra nhật ký kiểm toán và tham số 20.*

Mọi thao tác PH-20 tra được theo tenant, người, thời gian kèm lý do, phiếu; hành vi chỉnh được qua 29 tham số `20.*` đăng ký ở PH-18.

::: dac-ta
**Mục tiêu.** Yến tra các thao tác của Hà trên `T68` trong tháng 11; Bảo (AU tỉnh) tra nhật ký của riêng tỉnh; Hà xem giá trị hiệu lực của tham số `20.provision.step-timeout-minutes`.

**Tác nhân chính.** PA, PAU (toàn nền tảng); TA, AU (tỉnh); PO đổi giá trị tham số ở PH-18, PA xem.

**Tác nhân phụ.** PH-13 (kiểm toán), PH-18 (tham số, DD-14).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-20-068, FR-20-069.

**Truy vết.** REQ-20; quy trình: không có; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Bản ghi đã chuyển sang PH-13; có `PERM-20-read` (nền tảng) hoặc vai trò TA, AU (tỉnh); PH-18 khả dụng khi khởi động (có giá trị mặc định dự phòng).

**Kích hoạt.** Tab "Kiểm toán" của UI-20-03 (`CMP-AuditTimeline`); khởi động DU; PH-18 phát thay đổi tham số.

**Đảm bảo tối thiểu.** Bản tỉnh chỉ đọc chuỗi của tỉnh; không tắt được kiểm tra khói khi nền tảng có tenant thật; tham số ngoài miền không được áp.

**Đảm bảo thành công.** Danh sách kiểm toán đúng phạm vi người xem; tham số áp trong tối đa 60 giây, API trả giá trị và nguồn (mặc định hay ghi đè).

**Luồng chính.**
1. Yến chọn khoảng thời gian; hệ thống kiểm khoảng và phạm vi người xem.
2. Hệ thống gọi PH-13 lọc `module = PH-20` (và `tenantCode` nếu có) rồi trả `items[]` kèm lý do, mã phiếu.
3. Khi khởi động, DU đăng ký lược đồ 29 khóa `20.*` (kiểu, miền, mặc định) ở PH-18.
4. Nhận thay đổi tham số từ PH-18, hệ thống kiểm miền và áp trong tối đa 60 giây.
5. Hà gọi API-20-131 xem giá trị hiệu lực và nguồn từng tham số.

**Luồng thay thế.**
- **2a. Xuất CSV.** Qua PH-13.
- **4a. PH-18 không khả dụng.** Dùng giá trị cuối đã nhận.

**Luồng ngoại lệ.**
- **E1. Khoảng thời gian quá dài (bước 1).** ERR-20-032 (400): "Khoảng thời gian tối đa là {số} ngày."
- **E2. PH-13 lỗi (bước 2).** ERR-20-062 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."
- **E3. Giá trị ngoài miền hoặc tắt kiểm tra khói khi có tenant thật (bước 4).** ERR-20-060 (422): "Giá trị {giá trị} của tham số {khóa} ngoài miền {miền}."

**Quy tắc áp dụng.** BR-20-004, BR-20-009, BR-20-037.

**Màn hình, API.** UI-20-03; API-20-130, 131, 161; kịch bản TS-20-36.
:::

## 7. Luồng phụ dùng chung

Sáu luồng dưới được nhiều use case dùng lại; use case chỉ ghi "theo LP-20-nn" ở chỗ cần, không chép lại.

| Mã | Luồng phụ | Nội dung | Dùng ở |
|---|---|---|---|
| LP-20-01 | Bốn mắt | Hệ thống so định danh người thao tác với người lập, gửi, xác nhận bàn giao; trùng thì từ chối bằng ERR-20-007 (403) và kiểm toán ghi lần từ chối; việc cho người thứ hai đi qua PH-18 và "Việc của tôi" (FR-00-070, 071); nền tảng cần ít nhất hai người giữ `PERM-20-approve` | UC-20-13, 14, 21, 25 |
| LP-20-02 | Lý do, mã phiếu và kiểm toán chuỗi tenant | Mọi thao tác thay đổi tenant tỉnh mở `CMP-ReasonDialog` nhập lý do từ 20 ký tự và mã phiếu (ERR-20-008, 422); bản ghi kiểm toán vào chuỗi của tenant bị tác động và chuỗi `PLATFORM` (BR-20-009) | UC-20-03, 06, 10, 13, 14, 20, 21, 22, 28 |
| LP-20-03 | Ghi cấu hình qua GitOps | Mọi thay đổi cấu hình tenant sinh tệp từ CSDL, commit có chữ ký vào `tenants/{ma-tenant}/`, theo dõi Argo CD, phát EVT-20-09 sau khi `APPLIED`; Git lỗi thì giao dịch nghiệp vụ vẫn lưu, outbox thử lại (ERR-20-024) | UC-20-03, 09, 10, 11, 12, 13, 14, 18, 32 |
| LP-20-04 | Bước bất đồng bộ báo tiến độ | Phân hệ nhận sự kiện của PH-20 rồi báo xong qua `POST /internal/tenant/v1/...:report` (scope `tenant:provision-report`); quá `20.provision.step-timeout-minutes` thì `FAILED` (ERR-20-106); báo sai trạng thái bị từ chối (ERR-20-105, ERR-20-114) | UC-20-05, 08, 17, 21, 25, 26 |
| LP-20-05 | Sự kiện qua outbox, không dữ liệu cá nhân | Sự kiện ghi cùng giao dịch nghiệp vụ, bộ chuyển gửi lên Kafka, khóa phân vùng `tenantCode`; không mang dữ liệu cá nhân (BR-20-039) | Mọi use case có thao tác ghi |
| LP-20-06 | Chặn trạng thái tenant ở data plane | Bộ lọc `dh-tenant-filter` và plugin APISIX trả ERR-20-001, 101, 102, 103, 115, 118 theo trạng thái registry; đệm tối đa `20.registry.cache-seconds` giây, vô hiệu bằng EVT-20-04 | UC-20-17, 18, 19, 20, 22, 28, 34 |

: Luồng phụ dùng chung

## 8. Tổng hợp mã mới và đối chiếu

### 8.1. Mã đã dùng và độ phủ

Tài liệu không tạo mã `FR`, `API`, `ERR`, `EVT`, `UI`, `BR` mới: mọi mã lấy từ FRS. Mã mới duy nhất là `UC-20-01…36` và `LP-20-01…06`; kịch bản `TS-20-nn` ở mục "Màn hình, API" là chỗ giữ, đánh số theo UC và sẽ được xác nhận khi viết D05-02-PH20.

Dải đã dùng: UC-20-01…36; LP-20-01…06; FR-20-001…070 (cả 70 FR thuộc ít nhất một UC, bảng 5.4); ERR-20-001…068 và 101…118 với câu thông báo nguyên văn FRS §9.2; EVT-20-01…16 và năm sự kiện tiêu thụ (EVT-07-10, EVT-09-21, EVT-13-14, EVT-03-10, EVT-03-11); UI-20-01…22 (bảng 5.2); API-20-001…171, trong đó API-20-001…134 ở `/api/platform/v1`, 135…161 ở `/api/tenant/v1`, 162…171 ở `/internal/tenant/v1`; BR-20-001…042.

### 8.2. Độ phủ và mức ưu tiên

Số FR theo mức do FRS đếm (51 M, 19 S, 0 C) trùng brief chung. FR mức S: FR-20-005, 014, 015, 016, 017, 021, 022, 024, 025, 031, 032, 036, 056, 058, 062, 063, 064, 067, 070; hai FR Đợt 2 là FR-20-017 (UC-20-08) và FR-20-025 (UC-20-13). Chỉ UC-20-04, 08, 10, 13, 34, 35 chỉ gồm FR mức S. API ở mục 5.2 lấy trực tiếp từ mục "Màn hình, API" của từng FR; riêng FR-20-045 được tách giữa UC-20-24 (lập, sửa, hủy) và UC-20-25 (gửi duyệt, duyệt, từ chối). FR không có màn hình (FR-20-006, 020, 028, 037, 044, 057, 065, 066, 069) được gắn vào UC có màn của FR liên quan hoặc ghi "không có màn riêng". UC có từ ba thành phần hoặc có bốn mắt có sơ đồ trình tự: UC-20-05, 07, 09, 13, 14, 21, 22, 25, 26, 28, 33, 34.

## 9. Câu hỏi mở

Các câu hỏi phát sinh khi viết use case, đánh số Q20-45…49 theo dải của UC; câu hỏi của FRS (Q20-01…19) vẫn còn hiệu lực và không nhắc lại. Cột "Tạm dùng" là phương án tài liệu này đang theo.

| Mã | Câu hỏi | Tạm dùng |
|---|---|---|
| Q20-45 | Hủy kế hoạch sáp nhập khi đã qua `IDENTITY_TRANSFER` (người dùng, client đã tạo ở realm đích) thì gỡ thế nào; FR-20-045 chỉ nói dữ liệu đã chuyển được PH-18 gỡ theo `origin_tenant_id` | Chỉ cho hủy trước `IDENTITY_TRANSFER`; sau đó chỉ tiến tới cutover hoặc đề nghị PH-12 gỡ theo kế hoạch đảo (API-12-045 chế độ đảo) |
| Q20-46 | Đề nghị đổi hạn mức có duyệt (EN-20-14) không có hộp duyệt toàn nền tảng; API-20-073 chỉ liệt kê đề nghị vòng đời (EN-20-22) | Khoa mở đề nghị từ UI-20-05 của tenant hoặc từ việc ở PH-18; đề nghị đồng bộ A-02 |
| Q20-47 | Tạm ngừng do `SECURITY_INCIDENT` phải bổ sung văn bản trong 3 ngày làm việc; quá hạn thì tenant tự khôi phục, giữ nguyên hay leo thang | Giữ nguyên `SUSPENDED`, việc ở PH-18 quá hạn thì cảnh báo hai PA, không tự khôi phục |
| Q20-48 | Gói bàn giao có một phân hệ `FAILED` mãi (phân hệ ngừng hỗ trợ) có cho xác nhận `DELIVERED` kèm văn bản chấp nhận thiếu phần đó không | Không; chạy lại phần lỗi; ngoại lệ phải qua thay đổi hạ tầng D04-02 |
| Q20-49 | Nơi thực thi không xác nhận áp hạn mức sau 15 phút (UC-20-14) thì PH-20 tự thử lại, tự hoàn tác hay chỉ cảnh báo | Chỉ cảnh báo Tuấn ở UI-20-05, không tự thử lại; đề nghị phân hệ nơi thực thi phát lại xác nhận khi lên lại |

: Câu hỏi mở của tập use case PH-20

## Phụ lục A. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Khi viết use case phát hiện chỗ FRS thiếu hoặc lệch; tập này không sửa FRS hay tài liệu chung, các dòng dưới dồn vào Phụ lục B của FRS và các tài liệu chung ở bản kế tiếp. Dòng A-01 (đã xử lý ở 0.2), A-03, A-04, A-05 là lệch hoặc thiếu của FRS; A-02, A-06…A-09 là đề nghị cho tài liệu chung và phân hệ khác.

| Mã | Vị trí | Đề nghị | Nơi nhận |
|---|---|---|---|
| A-01 | FRS §10.1, dòng UI-20-20 | Cột FR chỉ có FR-20-067, 070; nhưng FR-20-014 ("tab Thời gian khởi tạo ở UI-20-20") và FR-20-016 ("Khởi tạo bổ sung hàng loạt ở UI-20-20") cũng dùng màn này. Đã xử lý ở 0.2: FRS §10.1 ghi UI-20-20 gồm FR-20-014, 016, 067, 070 | FRS PH-20 |
| A-02 | FRS §9.4, API-20-050…053 và API-20-073 | Đề nghị đổi hạn mức (EN-20-14) có API liệt kê theo tenant (API-20-051) nhưng không có hộp duyệt toàn nền tảng; FRS FR-20-027 nêu "hộp duyệt UI-20-08 tab Chờ duyệt". Đề nghị cho API-20-073 trả cả đề nghị `QUOTA_DECREASE` hoặc thêm API (Q20-46) | FRS PH-20 |
| A-03 | FRS FR-20-045, mục luồng thay thế | Hủy kế hoạch khi đã `TRANSFERRING` chỉ nêu gỡ dữ liệu; chưa nói xử lý người dùng, client đã cấp ở realm đích khi `IDENTITY_TRANSFER` đã chạy (Q20-45) | FRS PH-20 |
| A-04 | FRS FR-20-012, tiền điều kiện | Ca `CROSS_TENANT_LEAK` cần tenant kiểm thử `T99` đang `ACTIVE` ở môi trường; nên ghi tiền điều kiện này và hành xử khi `T99` không có (ca `SKIPPED` kèm cảnh báo hay chặn kích hoạt) | FRS PH-20 |
| A-05 | FRS FR-20-044, §9.4 | Thông báo đổi trạng thái chỉ có API-20-085 xem kết quả gửi; chưa có hành động "gửi lại thông báo" (UC-20-23 chỉ xem), trong khi FR-20-013 có "Gửi lại thư bàn giao" | FRS PH-20 |
| A-06 | D02-08 | Thêm mười quyền `PERM-20-provision`, `lifecycle`, `approve`, `quota`, `merge`, `release`, `settings`, `org`, `org-read`, `usage-read` (FRS Phụ lục B) để UC dẫn đúng quyền | Luồng chính D02-08 |
| A-07 | D02-01 BRD, danh mục BP | Bổ sung BP-12 "Sáp nhập tenant khi sắp xếp ĐVHC" và BP-13 "Phát hành và nâng cấp sản phẩm cho các tỉnh"; tập này dùng tạm hai mã ở bảng 5.3 | Luồng chính D02-01 |
| A-08 | PH-18 FRS, hợp đồng `merge-transfers` | UC-20-25, 26 giả định `POST /api/ops/v1/merge-transfers` có `dryRun`, báo tiến độ về API-20-167 và lượt bù (delta) cuối; PH-18 cần xác nhận thân yêu cầu, thứ tự phụ thuộc phân hệ và idempotency `{mergePlanId}:{module}:transfer` (Q20-15 của FRS) | PH-18 |
| A-09 | D03-06-00, menu | Thêm mục menu `/quan-tri/to-chuc`, `/nen-tang/sap-nhap`, `/nen-tang/phat-hanh`, `/nen-tang/tong-quan`, `/nen-tang/su-dung`, `/nen-tang/mau-khoi-tao` (FRS mục 10 và brief PH-20) để UC-20-30, 24…29, 32…35, 04 có lối vào | Luồng chính D03-06-00 |
| A-10 | D05-02-PH20 | Mã `TS-20-nn` ở mục "Màn hình, API" của từng UC là chỗ giữ theo số UC; kiểm thử viên xác nhận khi viết D05-02-PH20 | D05-02-PH20 |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-27 | Claude | Bản đầu: 36 use case phủ 70 FR (51 M, 19 S), 12 sơ đồ trình tự, sáu luồng phụ, câu hỏi mở Q20-45…49, 10 đề nghị đồng bộ |
| 0.2 | 2026-11-27 | Claude | Đồng bộ với FRS 0.2: tên ca kiểm tra khói theo OpenAPI, cửa sổ bảo trì 2 đến 6 giờ, 29 tham số, `RESOLVED`, mã KPI-12 `thoi-gian-khoi-tao-tenant`, cột FR của UI-20-20 (đóng A-01) |
| 0.3 | 2026-11-27 | Claude | Đồng bộ chéo cuối: dẫn API-18-150, mã kế hoạch `SN-yyyy-nnn` |

: Lịch sử phiên bản
