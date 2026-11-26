---
ma_tai_lieu: D02-04-PH16
ten: Đặc tả use case phân hệ PH-16 Báo cáo chỉ tiêu và sổ kiến trúc
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, lãnh đạo UBND và sở ngành, quản trị tỉnh, cán bộ tổng hợp, kỹ sư dh-platform, kiểm thử viên
phan_he: PH-16
mo_ta: Đặc tả 30 use case của phân hệ Báo cáo chỉ tiêu và sổ kiến trúc, mỗi use case một khối 15 mục kèm sơ đồ trình tự, mã lỗi và câu thông báo lấy từ FRS, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH16 FRS; D03-02-PH16 SDD; D03-03-PH16 CSDL; D03-04-PH16 API; D03-06-PH16 Màn hình; D05-02-PH16 Kiểm thử
---

# D02-04-PH16 · Đặc tả use case Báo cáo chỉ tiêu và sổ kiến trúc

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 30 use case của PH-16, phủ toàn bộ 58 FR (37 mức M, 17 mức S, 4 mức C) của [D02-03-PH16](../frs/D02-03-PH16-frs-bao-cao-chi-tieu.md). Use case đi theo một vòng báo cáo của một tỉnh: quản trị tỉnh kế thừa bộ 24 chỉ tiêu mẫu rồi tùy biến, mỗi thay đổi định nghĩa qua bốn mắt; hệ thống nhận số liệu đã tổng hợp từ các phân hệ nguồn, cán bộ nhập tay có bằng chứng những chỉ tiêu không đo tự động được; hằng tháng hệ thống tổng hợp, chấm trạng thái so mục tiêu, cán bộ chốt kỳ, lập báo cáo có thuyết minh, người thứ hai duyệt và công bố bản PDF ký số lưu bất biến; kết quả đi tới bảng điều khiển lãnh đạo, danh sách phân phối, hệ thống khác qua API và hệ quốc gia qua PH-14. Cùng phân hệ là sổ kiến trúc tối thiểu: thành phần tự đăng ký từ sự kiện, người đánh giá tuân thủ và miễn trừ có hạn. Căn cứ pháp lý: CMP-LAW-03, 19 (báo cáo tình hình chia sẻ), CMP-LAW-14, 21 (báo cáo chuyển đổi số), CMP-LAW-10, 11 (khung kiến trúc, bản sau còn là dự thảo nên công thức, ngưỡng, mẫu gói là cấu hình có phiên bản, Q16-05 của FRS).

Bốn điểm hội đồng cần lưu ý. Thứ nhất, PH-16 là năng lực mới, hệ cũ (Viettel 2021) không có chức năng báo cáo chỉ tiêu; chỉ một số màn thống kê của phân hệ khác liên quan gián tiếp (mục 5.3). Thứ hai, PH-16 không sinh dữ liệu thô: số `AUTO` truy được về quan sát có tham chiếu nguồn, số tay truy được về bản nhập có bằng chứng; thiếu nguồn thì ra số phần đã có gắn nhãn `PARTIAL`, không bịa số (UC-16-11). Thứ ba, năm quyết định có hậu quả đều qua bốn mắt: duyệt định nghĩa chỉ tiêu, xác nhận số liệu tay, duyệt và công bố báo cáo, xác nhận đánh giá tuân thủ, miễn trừ. Thứ tư, báo cáo đã công bố bất biến; sai thì đính chính bằng phiên bản mới (UC-16-16) và chỉ gửi quốc gia qua PH-14, tính năng này mặc định tắt vì hệ quốc gia chưa có đặc tả (Q16-02, Q16-03 của FRS).

## 1. Giới thiệu

Chương này nói tài liệu dùng để làm gì, phủ những gì, ai nên đọc phần nào, thuật ngữ và các tài liệu cần mở song song.

### 1.1. Mục đích

Tài liệu đặc tả 30 use case (ca sử dụng) của PH-16. Mỗi use case mô tả trọn một mục tiêu nghiệp vụ của một tác nhân theo từng bước tương tác với hệ thống, kèm nhánh thay thế, tình huống ngoại lệ có mã lỗi và câu thông báo người dùng nhìn thấy, các đảm bảo hệ thống giữ dù thành công hay thất bại, và với use case có từ ba thành phần hoặc có bốn mắt thì có thêm sơ đồ trình tự. Tài liệu nối FRS (hệ thống phải làm gì) với D03-02 SDD, D03-03 CSDL, D03-04 API và D03-06 màn hình (làm thế nào); kiểm thử viên dùng luồng chính, thay thế, ngoại lệ làm khung kịch bản `TS-16-nn` ở D05-02-PH16.

### 1.2. Phạm vi

Phạm vi là toàn bộ FR-16-001…058. Tài liệu mô tả trình tự giữa tác nhân và hệ thống, dữ liệu ví dụ và cách xử lý khi sai lệch; ràng buộc chi tiết từng bước (kiểu, miền giá trị, thứ tự kiểm tra) nằm ở FR và không chép lại. Chức năng dùng chung FR-00 (đăng nhập, chọn tenant, danh sách, "Việc của tôi", thông báo, xác nhận thao tác) không đặc tả lại; bước dựa vào chúng ghi "tuân thủ FR-00-nnn". Mọi enum, trạng thái, tên trường, quyền, tham số `16.*`, mã màn hình, mã sự kiện dùng đúng Phụ lục A và chương 8, 9, 10 của FRS.

Ngoài phạm vi: giám sát thời gian thực, cảnh báo vận hành, nhật ký kiểm toán tập trung (PH-13); danh mục API và SLA (PH-02); điểm chất lượng dữ liệu (PH-08); kết nối, ký, gửi tới nền tảng quốc gia (PH-14); hộp việc, lịch job (PH-18); trợ lý hỏi đáp số liệu (PH-17, chỉ đọc qua `kpi.read`); kho phân tích dài hạn và BI tự do (ngoài v1.0).

### 1.3. Người đọc

Hội đồng thẩm định đọc tóm tắt, chương 4, 5, 9. Lãnh đạo UBND và sở ngành đọc UC-16-17, 19, 20. Quản trị tỉnh, cán bộ tổng hợp, cán bộ ATTT đọc chương 6 theo vòng báo cáo. Kỹ sư `dh-platform` (package `vn.datahub.platform.kpi` và `vn.datahub.platform.arch`) đọc chương 6, mục "Màn hình, API" và các sơ đồ trình tự. Kiểm thử viên coi mỗi luồng chính, thay thế, ngoại lệ là ít nhất một phép kiểm trong `TS-16-nn`.

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01; thuật ngữ riêng theo FRS §1.4 và §4.1. Bảng chỉ nhắc các từ dày đặc trong luồng.

| Thuật ngữ | Giải thích |
|---|---|
| Chỉ tiêu (`indicator`) | Đại lượng đo được có công thức, đơn vị, mục tiêu, ngưỡng; ví dụ `httt-ket-noi-ty-le` (KPI-01) |
| Phiên bản định nghĩa | Một lần chốt công thức, mục tiêu, ngưỡng; trạng thái `DRAFT`, `PENDING_APPROVAL`, `CHANGES_REQUESTED`, `ACTIVE`, `SUPERSEDED`, `RETIRED`; mỗi chỉ tiêu một phiên bản `ACTIVE` |
| CEL | Common Expression Language, ngôn ngữ biểu thức không vòng lặp, dùng viết công thức, ví dụ `obs("ph01.httt.connected") / obs("ph01.httt.total") * 100` |
| Quan sát (`observation`) | Một giá trị số đã tổng hợp của phân hệ nguồn cho một kỳ, có `metricCode`, `sourceRef`, `idempotencyRef` |
| Nguồn số liệu (`data_source`) | Kênh nhận quan sát: `EVENT`, `PULL_API`, `PUSH_API`, `MANUAL`; trạng thái `ACTIVE`, `STALE`, `FAILED`, `PAUSED`, `RETIRED` |
| Kỳ, lần tổng hợp | Kỳ `M-2026-10`, `Q-2026-Q3`, `Y-2026`; lần tổng hợp là một lần tính mọi chỉ tiêu của kỳ |
| Độ đầy đủ | `COMPLETE`, `PARTIAL`, `NO_DATA` cho giá trị; tỷ lệ chỉ tiêu có số cho lần tổng hợp |
| Fail-soft | Thiếu một phần đầu vào vẫn ra kết quả phần còn lại kèm nhãn thiếu, không dừng cả lần tính |
| Bốn mắt | Người thứ hai khác người lập phải duyệt (FR-00-071) |
| WORM | Write Once Read Many, kho lưu chỉ ghi một lần, khóa đến hạn (Ceph RGW Object Lock) |
| Sổ kiến trúc | Danh sách thành phần kiến trúc (HTTT, API, luồng, topic, bộ điều hợp, dịch vụ nền, liên kết quốc gia) cùng phiên bản, phụ thuộc, trạng thái vận hành, mức tuân thủ |
| Gói quốc gia | Tệp theo mẫu của hệ quốc gia, chứa báo cáo chỉ tiêu hoặc sổ kiến trúc, gửi qua PH-14 |
| VW, TA, TO, SO, DS, AU, PA, PO, PU | Người xem, quản trị tỉnh, cán bộ tổng hợp, cán bộ ATTT, cán bộ quản lý dữ liệu, kiểm toán viên, quản trị nền tảng, vận hành nền tảng, kiểm toán nền tảng (FRS §3.1) |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

[D02-03-PH16 FRS](../frs/D02-03-PH16-frs-bao-cao-chi-tieu.md) (nguồn chuẩn: §3 tác nhân, §4 máy trạng thái, §7 quy tắc, §8 tham số, §9 lỗi, thông báo, sự kiện, API, §10.1 màn hình, Phụ lục A, B); D02-01 BRD §3 (KPI-01…18, REQ-16); D02-02 SRS §5; D02-08; D00-01; D00-04; K-UC, K-TRINH-BAY; `docs/07-srs/SRS-PH-16-nas-kpi.md` (SRS cũ); mẫu D02-04-PH08.

### 1.6. Cấu trúc tài liệu

Chương 2 quy ước đọc; 3 tác nhân; 4 sơ đồ use case tổng (năm hình); 5 bảng tổng hợp, ma trận truy vết FR, UI, API, REQ, LGC; 6 ba mươi khối đặc tả kèm sơ đồ trình tự; 7 luồng phụ dùng chung; 8 mã đã dùng và độ phủ; 9 câu hỏi mở; Phụ lục A đề nghị đồng bộ cho FRS.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ · Quy tắc áp dụng · Màn hình, API. Đoạn văn trước khối nói bối cảnh; sau khối, nếu có, là sơ đồ trình tự Mermaid và một đoạn thuyết minh.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3). Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-16-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép, nguyên văn FRS §9.2 (dấu `{…}` do máy chủ điền; ngưỡng số như "tối thiểu {n} ký tự" lấy theo FR tương ứng và ghi trong ngoặc đơn sau câu). Mã ERR-16-101…125 là lỗi chạy nền, không có người nhìn trực tiếp; người vận hành thấy ở UI-16-05, 06, 09, 12, 13, 14, 15, 17, 19 hoặc PH-13. Luồng phụ dùng chung ghi `LP-16-nn`, đặc tả một lần ở chương 7.

Quy ước chung không nhắc lại từng use case: lệnh ghi qua `/api/kpi/v1` mang `Idempotency-Key` (dùng lại với thân khác: ERR-16-058, 409), lệnh sửa mang `If-Match` (sai phiên bản: ERR-16-004, 409; thiếu: ERR-00-428); đối tượng của tenant khác trả như không tồn tại (ERR-16-001, 404); thiếu quyền chức năng trả ERR-00-403, chưa đăng nhập ERR-00-401; truy vấn chạy dưới RLS theo `tenant_id`; mọi thao tác ghi sinh kiểm toán chuyển sang PH-13 (UC-16-30). Dữ liệu ví dụ giả lập, tenant `T68`, kỳ `M-2026-10`.

| Vai | Người hoặc đối tượng | Ghi chú |
|---|---|---|
| TA | **Mai** (quản trị tỉnh), **Quang** (quản trị tỉnh thứ hai) | Mai soạn, Quang duyệt; đổi vai tùy use case, luôn là hai người khác nhau |
| TO | **Chi** (cán bộ tổng hợp, Sở KH&CN) | Quản lý nguồn, chạy tổng hợp, lập báo cáo, nhập số tay |
| SO | **Dũng** (cán bộ ATTT) | Xác nhận KPI-08, đánh giá tuân thủ |
| DS, AU | **Lan** (quản lý dữ liệu), **Bảo** (kiểm toán viên tỉnh) | Lan xác nhận số về danh mục; Bảo tải bằng chứng, xem kiểm toán |
| VW | **Hùng** (lãnh đạo UBND tỉnh) | Xem bảng điều khiển, báo cáo đã công bố |
| PA, PO, PU | **Hà**, **Tuấn**, **Yến** | Quản trị, vận hành, kiểm toán nền tảng |
| Chỉ tiêu, nguồn | `httt-ket-noi-ty-le` (KPI-01), `ho-so-cap-do-phe-duyet` (KPI-08), `tre-gateway-p95` (KPI-04); nguồn `ph08-dq-kpi` (EVENT) | Chỉ tiêu thuộc bộ 24 mẫu `COMMON`, nguồn là mã ví dụ |
| Báo cáo, gói | `bc-thang-2026-10`, `gq-bc-2026-10-v1` | Mã ví dụ, không phải mã thật |
| Thành phần kiến trúc | `api-cap-nhat-ho-tich` (API), `flow-lltp` (FLOW), `conn-hotich-ro` (ADAPTER) | Giả định tỉnh T01 quy mô vừa, 200 HTTT |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-16 có chín nhóm tác nhân người và các tác nhân hệ thống. Cặp loại trừ áp dụng trên cùng một đối tượng, không phụ thuộc vai trò (FRS §3.3): người soạn hoặc gửi duyệt định nghĩa không được duyệt; người lập báo cáo không được duyệt hay công bố; người nhập số liệu tay không được xác nhận; người lập đánh giá tuân thủ không được xác nhận. Tenant cần ít nhất hai người giữ `PERM-16-approve`; chỉ một người thì UI-16-19 cảnh báo và việc duyệt bị chặn chứ không cho tự duyệt (Q16-04 của FRS). PH-16 không tạo vai trò mới; mười hai quyền ngoài `PERM-16-read`, `PERM-16-admin` là đề nghị ở Phụ lục B của FRS.

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính | Use case chính (UC-16-nn) |
|---|---|---|---|
| VW | ROLE-VIEWER | `PERM-16-read` | 01, 17, 19…20, 23 |
| TA | ROLE-TENANT_ADMIN | `admin`, `approve`, `source`, `run`, `report`, `export`, `arch`, `arch-assess`, `national`, `config`, `audit-read` | 01…05, 07, 09…10, 12…18, 20, 22…26, 28…30 |
| TO | ROLE-TENANT_OPERATOR | `source`, `manual`, `run` (không chốt kỳ), `report`, `export`, `arch` | 01, 05, 07…10, 13…14, 16, 18, 22…25 |
| SO | ROLE-SECURITY_OFFICER | `manual` (KPI-08, KPI-09), `arch-assess` | 08, 26 |
| DS | ROLE-DATA_STEWARD | `manual` (số về danh mục, dữ liệu) | 08 |
| AU | ROLE-AUDITOR | `read`, `export` (báo cáo đã công bố), `audit-read` | 17, 23, 29…30 |
| PA | ROLE-PLATFORM_ADMIN | `admin`, `arch` ở `COMMON`, `compare`, `config` (đặt trần) | 02, 04, 12, 21, 27, 30 |
| PO | ROLE-PLATFORM_OPERATOR | `run` (chỉ hủy lần treo), `read` toàn nền tảng | 22 |
| PU | ROLE-PLATFORM_AUDITOR | `compare`, `audit-read`, chỉ đọc liên tenant | 21, 30 |
| Phân hệ nguồn | PH-01, 02, 04, 05, 07, 08, 10, 13, 19, 20 | Phát sự kiện, trả API chỉ số, gọi `kpi.ingest`, `arch.register` | 06 |
| PH-17, HTTT được cấp | Bên đọc máy | Scope `kpi.read` | 19 |
| Hệ thống (bộ lập lịch, kpi-compute) | `dh-platform` | Lịch nội bộ, tính toán, đối chiếu | 11, 24 |

: Tác nhân và use case mà họ là tác nhân chính

PH-14 (kênh gửi quốc gia, nhận gói từ outbox và trả biên nhận), PH-13 (kiểm toán, thông báo, chỉ số vận hành), PH-18 (hộp việc), dịch vụ ký số và kho WORM là tác nhân phụ xuất hiện ở cột "Tác nhân phụ" của từng use case.

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, 30 use case chia thành năm hình theo vòng đời: định nghĩa và nguồn số liệu, tính toán và báo cáo, xem và phân phối, sổ kiến trúc, gửi quốc gia và quản trị. Mermaid không có ký pháp UML use case nên dùng `flowchart`: hình bo tròn là tác nhân người, hình hai viền là tác nhân hệ thống, hình chữ nhật bo góc là use case; đường liền nối tác nhân với use case mà họ tham gia.

```{.mermaid caption="Use case định nghĩa chỉ tiêu, nguồn số liệu và số liệu tay"}
flowchart TB
  TA([TA, PA])
  TO([TO, DS, SO])
  S[[Phân hệ nguồn]]
  subgraph G1["Định nghĩa chỉ tiêu"]
    U01(UC-16-01 Xem bộ chỉ tiêu)
    U02(UC-16-02 Soạn định nghĩa)
    U03(UC-16-03 Duyệt, ngừng, thay thế)
    U04(UC-16-04 Kế thừa bộ mẫu)
  end
  subgraph G2["Nguồn và số liệu"]
    U05(UC-16-05 Đăng ký nguồn, độ tươi)
    U06(UC-16-06 Tiếp nhận quan sát)
    U07(UC-16-07 Nhật ký, xử lý lại)
    U08(UC-16-08 Nhập tay và xác nhận)
  end
  TA --- U01 & U02 & U03 & U04 & U05 & U07
  TO --- U01 & U05 & U07 & U08
  S --- U06
```

Hình cho thấy chỉ tiêu có hiệu lực sau khi soạn và duyệt (UC-16-02, 03); mỗi biến cần nguồn đăng ký (UC-16-05); số tự động vào qua UC-16-06, số không đo tự động qua UC-16-08.

```{.mermaid caption="Use case kỳ, tổng hợp và báo cáo chính thức"}
flowchart TB
  TA([TA])
  TO([TO])
  H[[Hệ thống]]
  subgraph G3["Kỳ và tính toán"]
    U09(UC-16-09 Kỳ, chốt, mở lại)
    U10(UC-16-10 Chạy tổng hợp, tính lại)
    U11(UC-16-11 Tính giá trị, trạng thái, điểm)
  end
  subgraph G4["Báo cáo"]
    U12(UC-16-12 Mẫu báo cáo)
    U13(UC-16-13 Lập nháp, thuyết minh)
    U14(UC-16-14 Gửi duyệt, duyệt)
    U15(UC-16-15 Công bố)
    U16(UC-16-16 Đính chính, rút)
  end
  TA --- U09 & U12 & U14 & U15 & U16
  TO --- U09 & U10 & U13 & U14
  H --- U10 & U11
```

Hình theo trục thời gian của một kỳ: tổng hợp (UC-16-09…11), chốt, lập báo cáo (UC-16-13), duyệt và công bố (UC-16-14, 15), đính chính khi sai (UC-16-16).

```{.mermaid caption="Use case xem, xuất, phân phối và cung cấp số liệu"}
flowchart TB
  VW([VW])
  AU([AU, TA, TO])
  PA([PA, PU])
  M[[PH-17, HTTT được cấp]]
  subgraph G5["Xem và đọc"]
    U17(UC-16-17 Tra cứu, bằng chứng)
    U20(UC-16-20 Bảng điều khiển)
    U21(UC-16-21 So sánh liên tenant)
    U22(UC-16-22 Theo dõi vận hành)
  end
  subgraph G6["Xuất và cung cấp"]
    U18(UC-16-18 Xuất, phân phối)
    U19(UC-16-19 API đọc, thẻ Tổng quan)
  end
  VW --- U17 & U20
  AU --- U17 & U18 & U22
  PA --- U21
  M --- U19
```

Hình cho thấy người xem chỉ thấy báo cáo đã công bố, so sánh liên tenant chỉ dành cho quản trị và kiểm toán nền tảng, hệ khác đọc số qua scope `kpi.read` (UC-16-19).

```{.mermaid caption="Use case sổ kiến trúc"}
flowchart TB
  TA([TA, TO])
  SO([SO])
  S[[Phân hệ nguồn, PH-13]]
  U23(UC-16-23 Tìm, xem, xuất sổ)
  U24(UC-16-24 Tự đăng ký, đối chiếu)
  U25(UC-16-25 Khai báo, sửa thủ công)
  U26(UC-16-26 Đánh giá tuân thủ, miễn trừ)
  TA --- U23 & U25 & U26
  SO --- U26
  S --- U24
  TA -.- U24
```

Hình cho thấy sổ kiến trúc chủ yếu tự đăng ký từ sự kiện (UC-16-24), người chỉ bổ sung (UC-16-25) và đánh giá tuân thủ có người xác nhận khác người lập (UC-16-26).

```{.mermaid caption="Use case gửi quốc gia và quản trị"}
flowchart TB
  PA([PA])
  TA([TA])
  AU([AU, PU])
  P14[[PH-14]]
  U27(UC-16-27 Mẫu gói quốc gia)
  U28(UC-16-28 Lập và gửi gói)
  U29(UC-16-29 Nhật ký nộp, gửi lại, đối soát)
  U30(UC-16-30 Tham số, lưu giữ, kiểm toán)
  PA --- U27 & U30
  TA --- U28 & U29 & U30
  AU --- U29 & U30
  U28 --- P14
  U29 --- P14
```

Hình cho thấy mọi gói quốc gia chỉ đi qua PH-14 (BR-16-021), mẫu gói do quản trị nền tảng giữ; tham số và kiểm toán gộp ở UC-16-30.

## 5. Bảng tổng hợp use case và truy vết

Chương này là danh sách chính thức 30 use case, đặt trước phần chi tiết để tra nhanh. Bảng 5.2 là nguồn của mục "Màn hình, API" trong từng khối; bảng 5.3 là nguồn của mục "Truy vết". PH-16 là năng lực mới nên cột LGC chủ yếu là "—".

### 5.1. Use case và FR

Bảng liệt kê 30 use case, tác nhân chính, mức ưu tiên cao nhất trong các FR của use case và FR hiện thực (số đuôi của `FR-16-nnn`). Cả 58 FR (37 mức M, 17 mức S, 4 mức C) thuộc ít nhất một use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-16-01 | Xem bộ chỉ tiêu, nhóm và trọng số | VW, TA, TO | M | 001, 007 |
| UC-16-02 | Soạn định nghĩa chỉ tiêu: công thức, mục tiêu, ngưỡng | TA, PA | M | 002, 003, 004 |
| UC-16-03 | Duyệt định nghĩa, ngừng và thay thế chỉ tiêu | TA | M | 005, 006 |
| UC-16-04 | Kế thừa bộ chỉ tiêu mẫu và nhận cập nhật mẫu | TA, PA | M | 008 |
| UC-16-05 | Đăng ký nguồn số liệu và theo dõi độ tươi | TA, TO | M | 009, 013 |
| UC-16-06 | Tiếp nhận quan sát từ sự kiện, kéo API và API đẩy | Phân hệ nguồn | M | 010, 011, 012 |
| UC-16-07 | Tra nhật ký tiếp nhận, xử lý lại quan sát bị loại | TA, TO | S | 016 |
| UC-16-08 | Nhập số liệu tay kèm bằng chứng và xác nhận | TO, DS, SO | M | 014, 015 |
| UC-16-09 | Quản lý kỳ báo cáo, chốt kỳ và mở lại kỳ | TA, TO | M | 017, 024 |
| UC-16-10 | Chạy tổng hợp theo lịch hoặc thủ công và tính lại | TA, TO | M | 018, 023 |
| UC-16-11 | Tính giá trị, độ đầy đủ, trạng thái và điểm nhóm | Hệ thống | M | 019, 020, 021, 022 |
| UC-16-12 | Quản lý mẫu báo cáo | TA, PA | M | 025 |
| UC-16-13 | Lập bản nháp, thuyết minh và báo cáo đột xuất | TA, TO | M | 026, 027, 032 |
| UC-16-14 | Gửi duyệt và duyệt báo cáo bốn mắt | TO, TA | M | 028 |
| UC-16-15 | Công bố báo cáo chính thức | TA | M | 029 |
| UC-16-16 | Đính chính và rút báo cáo đã công bố | TA, TO | S | 030 |
| UC-16-17 | Tra cứu báo cáo và tải bằng chứng công bố | VW, AU, TA | M | 031, 036 |
| UC-16-18 | Xuất báo cáo và phân phối theo danh sách | TA, TO | M | 033, 034 |
| UC-16-19 | Cung cấp chỉ tiêu cho hệ khác và thẻ Tổng quan | PH-17, HTTT được cấp, VW | M | 035, 037 |
| UC-16-20 | Xem bảng điều khiển, chi tiết chỉ tiêu, so sánh hai kỳ | VW, TA | M | 038, 039, 040 |
| UC-16-21 | So sánh liên tenant ẩn danh | PA, PU | C | 041 |
| UC-16-22 | Theo dõi vận hành thu thập, tính toán | TA, TO, PO | S | 042, 058 |
| UC-16-23 | Tìm, xem và xuất sổ kiến trúc | VW, TA, TO, AU | M | 043, 049 |
| UC-16-24 | Tự đăng ký, cập nhật vận hành và đối chiếu thành phần | Hệ thống, TA, TO | M | 044, 046, 048 |
| UC-16-25 | Khai báo, sửa thành phần, phiên bản và phụ thuộc | TA, TO | S | 045 |
| UC-16-26 | Đánh giá tuân thủ, xác nhận và miễn trừ | SO, TA | M | 047 |
| UC-16-27 | Quản lý mẫu gói quốc gia | PA | M | 050 |
| UC-16-28 | Lập và gửi gói báo cáo chỉ tiêu, sổ kiến trúc qua PH-14 | TA | M | 051, 052 |
| UC-16-29 | Nhật ký nộp, biên nhận, gửi lại và đối soát | TA, AU | M | 053, 054 |
| UC-16-30 | Tham số, lưu giữ dữ liệu và nhật ký kiểm toán | TA, AU, PA, PU | M | 055, 056, 057 |

: Use case, tác nhân chính, mức và FR hiện thực

### 5.2. Use case, màn hình và API

Bảng là ma trận use case với màn hình (UI) và API. UC-16-06, 11, 24 chủ yếu là use case chạy nền; kết quả xem ở UI-16-06, 09, 14. FR-16-035, 058 không có màn hình; FR-16-010, 046, 058 không có operation riêng (tiêu thụ sự kiện, chỉ số Prometheus).

| UC | Màn hình | API |
|---|---|---|
| UC-16-01 | UI-16-03 | API-16-001, 003, 016, 017 |
| UC-16-02 | UI-16-03, 04 | API-16-002, 005, 007…010 |
| UC-16-03 | UI-16-03, 04, 12 | API-16-003, 004, 006, 011…015, 078 |
| UC-16-04 | UI-16-03 | API-16-001, 018…020 |
| UC-16-05 | UI-16-05, 06 | API-16-010, 021…028 |
| UC-16-06 | UI-16-06 | API-16-029, 030, 042…044 |
| UC-16-07 | UI-16-06 | API-16-042…045 |
| UC-16-08 | UI-16-07, 12 | API-16-031…041, 078 |
| UC-16-09 | UI-16-08 | API-16-046…048, 057, 058 |
| UC-16-10 | UI-16-08, 09 | API-16-049…052, 055, 069 |
| UC-16-11 | UI-16-09, 01, 02 | API-16-048, 051, 053, 054, 056, 090 |
| UC-16-12 | UI-16-13 | API-16-059…063 |
| UC-16-13 | UI-16-10, 11 | API-16-065…070 |
| UC-16-14 | UI-16-11, 12 | API-16-071…073, 078 |
| UC-16-15 | UI-16-12 | API-16-074 |
| UC-16-16 | UI-16-10 | API-16-075, 076 |
| UC-16-17 | UI-16-10 | API-16-064, 066, 077, 088 |
| UC-16-18 | UI-16-10, 13, 01, 02, 09 | API-16-079…085 |
| UC-16-19 | UI-16-01 | API-16-086, 087, 089 |
| UC-16-20 | UI-16-01, 02 | API-16-043, 054, 090, 091 |
| UC-16-21 | UI-16-18 | API-16-092 |
| UC-16-22 | UI-16-08 | API-16-049, 093; `/actuator/prometheus` |
| UC-16-23 | UI-16-14, 15 | API-16-079…081, 094, 096 |
| UC-16-24 | UI-16-14, 15 | API-16-096, 101, 111…113 |
| UC-16-25 | UI-16-14, 15 | API-16-095…100 |
| UC-16-26 | UI-16-15, 16 | API-16-102…110 |
| UC-16-27 | UI-16-17 | API-16-114…117 |
| UC-16-28 | UI-16-10, 17 | API-16-118, 120, 121 |
| UC-16-29 | UI-16-17 | API-16-119, 120, 122…126 |
| UC-16-30 | UI-16-19, 20 | API-16-127…130 |

: Use case, màn hình và API

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

BP-11 "Tổng hợp và báo cáo chỉ tiêu chuyển đổi số" là quy trình do FRS đề nghị bổ sung vào D02-01 (Phụ lục B của FRS); sổ kiến trúc chưa có quy trình riêng nên UC-16-23…26 ghi "—". Hệ cũ không có chức năng báo cáo chỉ tiêu; các mục LGC dưới đây là màn thống kê của phân hệ khác mà PH-16 nâng thành chỉ tiêu định kỳ.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-16-01…03 | REQ-16 | BP-11 | — |
| UC-16-04 | REQ-16, REQ-20 | BP-11 | — |
| UC-16-05 | REQ-16 | BP-11 | — |
| UC-16-06 | REQ-16 | BP-11 | LGC-BUS-027 (gián tiếp) |
| UC-16-07…10 | REQ-16 | BP-11 | — |
| UC-16-11 | REQ-16 | BP-11 | LGC-APIM-026 (gián tiếp) |
| UC-16-12…17 | REQ-16 | BP-11 | — |
| UC-16-18 | REQ-16, REQ-13 | BP-11 | — |
| UC-16-19 | REQ-16, REQ-17 | BP-11 | — |
| UC-16-20 | REQ-16 | BP-11 | LGC-APIM-026, LGC-PAY-013, LGC-PAY-020, LGC-HUB-001…004 (gián tiếp) |
| UC-16-21 | REQ-16, REQ-20 | BP-11 | — |
| UC-16-22 | REQ-16, REQ-13 | BP-11 | LGC-BUS-027 (gián tiếp) |
| UC-16-23 | REQ-16 | — | — |
| UC-16-24 | REQ-16, REQ-01, REQ-02, REQ-04, REQ-10, REQ-13 | — | — |
| UC-16-25…26 | REQ-16 | — | — |
| UC-16-27 | REQ-16, REQ-14 | BP-11 | — |
| UC-16-28…29 | REQ-16, REQ-14 | BP-11 | LGC-NGSP-004 (gián tiếp) |
| UC-16-30 | REQ-16, REQ-13 | BP-11 | — |

: Use case, REQ, BP và LGC

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực (số đuôi `UC-16-nn`). Không FR nào bị bỏ trống. FR-16-010 hiện thực ở UC-16-06 và hậu quả (số trễ, tính lại) chạm UC-16-10; FR-16-008 hiện thực ở UC-16-04 và còn chạm UC-16-03 khi duyệt bản nhận từ mẫu.

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 01 | 020 | 11 | 039 | 20 |
| 002 | 02 | 021 | 11 | 040 | 20 |
| 003 | 02 | 022 | 11 | 041 | 21 |
| 004 | 02 | 023 | 10 | 042 | 22 |
| 005 | 03 | 024 | 09 | 043 | 23 |
| 006 | 03 | 025 | 12 | 044 | 24 |
| 007 | 01 | 026 | 13 | 045 | 25 |
| 008 | 04 | 027 | 13 | 046 | 24 |
| 009 | 05 | 028 | 14 | 047 | 26 |
| 010 | 06 | 029 | 15 | 048 | 24 |
| 011 | 06 | 030 | 16 | 049 | 23 |
| 012 | 06 | 031 | 17 | 050 | 27 |
| 013 | 05 | 032 | 13 | 051 | 28 |
| 014 | 08 | 033 | 18 | 052 | 28 |
| 015 | 08 | 034 | 18 | 053 | 29 |
| 016 | 07 | 035 | 19 | 054 | 29 |
| 017 | 09 | 036 | 17 | 055 | 30 |
| 018 | 10 | 037 | 19 | 056 | 30 |
| 019 | 11 | 038 | 20 | 057 | 30 |
|  |  |  |  | 058 | 22 |

: Ma trận FR và use case

## 6. Đặc tả chi tiết use case

Chương này đặc tả 30 use case theo vòng báo cáo: định nghĩa chỉ tiêu (UC-16-01…04), nguồn và số liệu (05…08), kỳ và tính toán (09…11), báo cáo (12…17), xuất, đọc, xem (18…22), sổ kiến trúc (23…26), gửi quốc gia và quản trị (27…30). Mỗi use case một khối 15 mục; nhánh thay thế và ngoại lệ chỉ ghi điều khác với FR, hành vi từng bước xem FR tương ứng. Cột "Truy vết" của mọi khối theo bảng 5.3; cột "Màn hình, API" theo bảng 5.2.

### 6.1. UC-16-01 · Xem bộ chỉ tiêu, nhóm và trọng số

Bộ chỉ tiêu là danh mục mà mọi báo cáo dựa vào. Người dùng tra theo nhóm, trạng thái, cách đo; quản trị tỉnh chỉnh trọng số của năm nhóm để điểm tổng phản ánh ưu tiên của tỉnh.

::: dac-ta
**Mục tiêu.** Chi lọc ra các chỉ tiêu nhóm `KET_NOI` đo `AUTO` đang hiệu lực; Mai chỉnh trọng số năm nhóm thành 25, 25, 20, 20, 10 (tổng 100) để áp dụng từ kỳ đang mở.

**Tác nhân chính.** VW (Hùng), TO (Chi), TA (Mai).

**Tác nhân phụ.** Không.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-001, FR-16-007.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Đã đăng nhập, chọn tenant `T68` (FR-00-004); có `PERM-16-read`; sửa trọng số cần `PERM-16-admin`.

**Kích hoạt.** Mở UI-16-03 hoặc đổi bộ lọc; mở tab "Nhóm và trọng số".

**Đảm bảo tối thiểu.** Danh sách chỉ đọc theo RLS; trọng số không đổi nếu tổng khác 100.

**Đảm bảo thành công.** Cấu hình nhóm mới có hiệu lực từ kỳ đang mở; kỳ đã chốt giữ trọng số đã dùng (BR-16-033).

**Luồng chính.**
1. Chi mở UI-16-03, chọn nhóm `KET_NOI`, cách đo `AUTO`.
2. Hệ thống kiểm tham số lọc (API-16-001) và trả danh sách chỉ tiêu kèm phiên bản `ACTIVE`, phiên bản đang soạn, khối `facets` đếm theo nhóm, trạng thái, cách đo, cờ `hasCommonUpdate`.
3. Chi mở một chỉ tiêu, xem định nghĩa (API-16-003).
4. Mai mở tab "Nhóm và trọng số" (API-16-016), sửa trọng số, giao diện hiện tổng đang là 100.
5. Mai bấm "Lưu"; hệ thống kiểm đủ năm nhóm, tổng bằng 100, lưu (API-16-017) và ghi kiểm toán.

**Luồng thay thế.**
- **1a. Xem bộ mẫu.** Chọn `scope = COMMON`: hệ thống trả 24 chỉ tiêu mẫu chỉ đọc, kèm cờ tenant đã kế thừa hay chưa.
- **4a. Trọng số bằng 0.** Nhóm vẫn hiển thị nhưng không tham gia điểm tổng.

**Luồng ngoại lệ.**
- **E1. Bộ lọc sai miền (bước 2).** ERR-16-057 (400): "Tham số {trường} không hợp lệ: {lý do}." ({trường} = tên trường lọc, {lý do} = giá trị ngoài miền ở Phụ lục A)
- **E2. Tổng trọng số khác 100 (bước 5).** ERR-16-012 (422): "Tổng trọng số năm nhóm đang là {tổng}. Điều chỉnh cho bằng 100."

**Quy tắc áp dụng.** BR-16-016, BR-16-018, BR-16-033.

**Màn hình, API.** UI-16-03; API-16-001, 003, 016, 017; kịch bản TS-16-01.
:::

### 6.2. UC-16-02 · Soạn định nghĩa chỉ tiêu: công thức, mục tiêu, ngưỡng

Một chỉ tiêu mới hoặc một phiên bản mới của chỉ tiêu có sẵn bắt đầu ở trạng thái nháp. Người soạn viết công thức, đặt mục tiêu, ngưỡng và phải thử tính trên dữ liệu các kỳ trước trước khi gửi duyệt.

::: dac-ta
**Mục tiêu.** Mai có chỉ tiêu `httt-chia-se-ty-le` (RATIO, `HIGHER_BETTER`, `AUTO`, đơn vị `%`, nhóm `CHIA_SE`) với công thức hợp lệ, mục tiêu 85% hạn 2027-06-30, ngưỡng xanh từ 85, vàng từ 70, đã thử tính ba kỳ gần nhất.

**Tác nhân chính.** TA (Mai); PA ở tenant `COMMON`.

**Tác nhân phụ.** Danh mục chỉ số của nguồn đã đăng ký (UC-16-05).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-002, FR-16-003, FR-16-004.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-admin`; nhóm chỉ tiêu tồn tại; khi mở phiên bản mới, chỉ tiêu không có phiên bản `DRAFT` hay `PENDING_APPROVAL` khác.

**Kích hoạt.** Bấm "+ Chỉ tiêu" ở UI-16-03, hoặc "Tạo phiên bản mới" ở UI-16-04.

**Đảm bảo tối thiểu.** Không tạo chỉ tiêu trùng mã hay tổ hợp thuộc tính sai; nội dung đang soạn không ảnh hưởng số đã tính.

**Đảm bảo thành công.** Phiên bản ở `DRAFT` có công thức, mục tiêu, ngưỡng và dấu thử tính khớp băm nội dung.

**Luồng chính.**
1. Mai nhập mã `httt-chia-se-ty-le`, tên, nhóm, loại, chiều tốt, cách đo, đơn vị, cách gộp `LAST`, cờ bắt buộc rồi bấm "Tạo" (API-16-002).
2. Hệ thống kiểm mã theo `^[a-z][a-z0-9-]{2,62}$`, chưa dùng, và tổ hợp hợp lệ; tạo chỉ tiêu `scope = TENANT` với phiên bản 1 ở `DRAFT`, ghi kiểm toán.
3. Mai chọn biến từ danh mục chỉ số (API-16-010) và viết `obs("ph01.httt.sharing") / obs("ph01.httt.total") * 100`.
4. Hệ thống biên dịch CEL, kiểm kiểu trả về khớp `kind` và mọi `metricCode` có nguồn đã đăng ký (API-16-008, API-16-007).
5. Mai nhập giá trị nền 60, mục tiêu 85, hạn 2027-06-30, `greenFrom = 85`, `amberFrom = 70`; hệ thống kiểm ngưỡng đơn điệu theo chiều tốt, lưu và hiện thanh xem trước ba vùng màu.
6. Mai chọn ba kỳ `M-2026-08…10` và bấm "Thử tính" (API-16-009); hệ thống đánh giá trên quan sát từng kỳ, không ghi giá trị, trả kết quả, độ đầy đủ, biến thiếu, rồi lưu dấu thử tính (băm nội dung, thời điểm) để kiểm khi gửi duyệt ở UC-16-03; kỳ thiếu quan sát trả `NO_DATA` kèm biến thiếu, không coi là lỗi.

**Luồng thay thế.**
- **1a. Phiên bản mới của chỉ tiêu có sẵn.** Hệ thống sao nội dung phiên bản `ACTIVE` sang phiên bản `n+1` ở `DRAFT`; với chỉ tiêu kế thừa từ `COMMON`, phiên bản mới là bản tùy biến của tenant, giữ `derivedFrom`.
- **5a. Mục tiêu tương đối.** Chọn `targetMode = RELATIVE_TO_BASELINE` (ví dụ KPI-02 giảm từ 80% so với nền): hệ thống quy đổi ngưỡng tuyệt đối từ giá trị nền khi tính.

**Luồng ngoại lệ.**
- **E1. Mã đã dùng (bước 2).** ERR-16-002 (409): "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." ({Đối tượng} = Chỉ tiêu)
- **E2. Mã sai mẫu hoặc tổ hợp thuộc tính sai (bước 2).** ERR-16-003 (400): "{Trường} chưa hợp lệ: {yêu cầu}." ({Trường} = Mã chỉ tiêu, {yêu cầu} = chỉ gồm chữ thường, số và gạch nối, 3 đến 63 ký tự; tổ hợp thuộc tính sai thì {yêu cầu} nêu tổ hợp được phép)
- **E3. Đã có phiên bản đang soạn (1a) hoặc phiên bản không ở `DRAFT` (bước 3 đến 6).** ERR-16-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." ({thao tác} = mở phiên bản mới hoặc sửa, {đối tượng} = phiên bản {n} của chỉ tiêu {mã})
- **E4. Sửa chỉ tiêu mẫu trực tiếp (1a).** ERR-16-014 (403): "Chỉ tiêu mẫu dùng chung không sửa trực tiếp được. Tạo phiên bản tùy biến của tỉnh."
- **E5. Công thức sai cú pháp hoặc kiểu (bước 4).** ERR-16-008 (422): "Công thức chưa đúng ở vị trí {dòng}:{cột}: {mô tả}."
- **E6. Biến chưa có nguồn (bước 4).** ERR-16-009 (422): "Biến {metricCode} chưa có nguồn số liệu nào. Đăng ký nguồn trước khi dùng." Chỉ tiêu `MANUAL` bỏ qua kiểm tra này.
- **E7. Ngưỡng không đơn điệu hoặc ngoài miền (bước 5).** ERR-16-010 (422): "Ngưỡng chưa hợp lệ: với chiều {chiều}, mốc xanh phải {lớn hơn hoặc nhỏ hơn} mốc vàng."

**Quy tắc áp dụng.** BR-16-001, BR-16-002, BR-16-007, BR-16-015, BR-16-018, BR-16-033, BR-16-034.

**Màn hình, API.** UI-16-03, UI-16-04; API-16-002, 005, 007, 008, 009, 010; kịch bản TS-16-02.
:::

### 6.3. UC-16-03 · Duyệt định nghĩa, ngừng và thay thế chỉ tiêu

Định nghĩa chỉ tiêu quyết định con số lãnh đạo nhìn thấy nên mỗi phiên bản phải qua người thứ hai. Cùng use case là việc ngừng hoặc thay thế chỉ tiêu và tra lịch sử phiên bản.

::: dac-ta
**Mục tiêu.** Phiên bản 1 của `httt-chia-se-ty-le` do Mai soạn được Quang duyệt và có hiệu lực từ kỳ `M-2026-11`; về sau chỉ tiêu cũ được ngừng, thay bằng chỉ tiêu mới mà không làm hỏng báo cáo đang duyệt.

**Tác nhân chính.** TA (Mai soạn, gửi; Quang duyệt, ngừng).

**Tác nhân phụ.** PH-18 (việc duyệt), PH-13 (thông báo), PH-17 (nhận EVT-16-01, 02).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-005, FR-16-006.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Phiên bản `DRAFT` có công thức (trừ `MANUAL`), mục tiêu, ngưỡng, đã thử tính trên nội dung hiện tại (UC-16-02); người duyệt có `PERM-16-approve` và khác người soạn, người gửi.

**Kích hoạt.** Mai bấm "Gửi duyệt" ở UI-16-04; Quang mở việc ở UI-16-12 hoặc "Việc của tôi" (FR-00-070); thao tác "Ngừng" hay "Thay bằng…" ở UI-16-03.

**Đảm bảo tối thiểu.** Phiên bản đã gửi bị khóa nội dung; không ai tự duyệt phiên bản của mình; chỉ tiêu đang nằm trong báo cáo chờ duyệt không bị ngừng.

**Đảm bảo thành công.** Phiên bản `ACTIVE` kể từ `effectiveFrom`, phiên bản cũ `SUPERSEDED`; chỉ tiêu ngừng có phiên bản `RETIRED` và đường nối tới chỉ tiêu thay.

**Luồng chính.**
1. Mai gửi duyệt (API-16-011); hệ thống kiểm đủ nội dung và dấu thử tính khớp băm nội dung.
2. Hệ thống chuyển `PENDING_APPROVAL`, khóa nội dung, tạo việc cho người có `PERM-16-approve` kèm bản so sánh với phiên bản `ACTIVE` và kết quả thử tính.
3. Quang mở việc ở UI-16-12 (API-16-078), xem so sánh, công thức đọc được, kết quả thử tính.
4. Quang chọn "Duyệt" (API-16-012); hệ thống kiểm Quang khác Mai.
5. Hệ thống chuyển phiên bản `ACTIVE` từ `effectiveFrom`, phiên bản cũ `SUPERSEDED`, chỉ tiêu mới tạo sang `ACTIVE`, ghi kiểm toán, phát EVT-16-01.
6. Nếu `effectiveFrom` thuộc kỳ chưa chốt đã có giá trị, hệ thống xếp tính lại kỳ đó (UC-16-10).

**Luồng thay thế.**
- **4a. Yêu cầu sửa.** Quang chọn "Yêu cầu sửa" kèm ý kiến (API-16-013); phiên bản sang `CHANGES_REQUESTED`, Mai nhận thông báo và sửa tiếp ở UC-16-02.
- **6a. Ngừng chỉ tiêu.** Quang chọn "Ngừng" (API-16-015); hệ thống liệt kê mẫu báo cáo, báo cáo chưa công bố, chỉ tiêu khác dùng chỉ tiêu này qua `prev` hoặc gộp, kiểm không còn báo cáo `IN_REVIEW`, `APPROVED` dùng nó, chuyển `RETIRED` từ kỳ `effectivePeriod`, phát EVT-16-02; mẫu báo cáo tự bỏ chỉ tiêu ở phiên bản mẫu kế tiếp.
- **6b. Thay thế.** Chọn "Thay bằng…" `httt-chia-se-ty-le-v2`: hệ thống kiểm chỉ tiêu thay đang `ACTIVE`, cùng `kind` rồi nối chuỗi "thay bằng" ở UI-16-02.

**Luồng ngoại lệ.**
- **E1. Chưa thử tính nội dung hiện tại (bước 1).** ERR-16-011 (422): "Thử tính phiên bản sau lần sửa cuối trước khi gửi duyệt."
- **E2. Tự duyệt (bước 4).** ERR-16-005 (403): "Anh/chị là người {vai} nên không được {thao tác}." ({vai} = soạn hoặc gửi duyệt, {thao tác} = tự duyệt)
- **E3. Thiếu ý kiến, lý do (4a, 6a).** ERR-16-007 (422): "Nhập {nội dung} (tối thiểu {n} ký tự)." ({nội dung} = ý kiến hoặc lý do, {n} = 20)
- **E5. Còn báo cáo đang duyệt dùng chỉ tiêu (6a).** ERR-16-013 (409): "Chỉ tiêu {mã} đang có trong {n} báo cáo chờ duyệt. Hoàn tất các báo cáo này trước khi ngừng."
- **E6. Chỉ tiêu thay không hợp lệ (6b).** ERR-16-054 (422): "Chỉ tiêu thay thế {mã} phải đang hiệu lực và cùng loại giá trị."

**Quy tắc áp dụng.** BR-16-002, BR-16-003, BR-16-009.

**Màn hình, API.** UI-16-03, UI-16-04, UI-16-12; API-16-003, 004, 006, 011…015, 078; kịch bản TS-16-03.
:::

```{.mermaid caption="Trình tự gửi duyệt và duyệt phiên bản định nghĩa bốn mắt"}
sequenceDiagram
  actor Mai as Mai (TA soạn)
  actor Quang as Quang (TA duyệt)
  participant C as dh-console
  participant K as kpi-control
  participant H as PH-18, PH-13
  Mai->>C: Bấm Gửi duyệt
  C->>K: POST versions/1:submit
  K->>K: Kiểm dấu thử tính, khóa nội dung
  K->>H: Tạo việc duyệt, thông báo Quang
  Quang->>C: Mở việc, bấm Duyệt
  C->>K: POST versions/1:approve
  K->>K: Kiểm Quang khác Mai
  K->>K: ACTIVE, bản cũ SUPERSEDED, ghi kiểm toán
  K->>H: EVT-16-01 indicator.activated
  K-->>C: 200
```

Hình cho thấy việc kiểm khác người diễn ra trước khi trạng thái đổi; phiên bản chỉ `ACTIVE` sau khi Quang duyệt.

### 6.4. UC-16-04 · Kế thừa bộ chỉ tiêu mẫu và nhận cập nhật mẫu

Tenant mới không bắt đầu từ trang trắng: PH-20 kích hoạt việc kế thừa 24 chỉ tiêu mẫu và năm nhóm từ `COMMON`. Về sau khi quản trị nền tảng sửa mẫu, tỉnh tự quyết nhận hay bỏ qua.

::: dac-ta
**Mục tiêu.** Tenant `T68` có đủ bộ chỉ tiêu mẫu ngay khi khởi tạo; khi Hà phát hành phiên bản mẫu mới, Mai xem khác biệt và nhận vào bản nháp của tỉnh, không bị ghi đè.

**Tác nhân chính.** TA (Mai), PA (Hà).

**Tác nhân phụ.** PH-20 (khởi tạo tenant), PH-18 (thông báo "Mẫu có bản mới").

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-008.

**Truy vết.** REQ-16, REQ-20; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Mẫu ở `COMMON` có phiên bản `ACTIVE`; nhận cập nhật cần `PERM-16-admin`, kích hoạt cần `PERM-16-approve`; Hà soạn mẫu ở `COMMON`.

**Kích hoạt.** PH-20 khởi tạo tenant; Mai bấm "Kế thừa từ mẫu" hoặc mở thông báo "Mẫu có bản mới" ở UI-16-03.

**Đảm bảo tối thiểu.** Chỉ tiêu mẫu không bị sửa tại tenant; cập nhật mẫu không tự áp.

**Đảm bảo thành công.** Mỗi chỉ tiêu đã kế thừa có phiên bản `ACTIVE` gắn `derivedFrom`; cập nhật được nhận đi qua bốn mắt như phiên bản thường.

**Luồng chính.**
1. PH-20 khởi tạo tenant `T68`; hệ thống sao 24 chỉ tiêu mẫu và năm nhóm sang tenant, mỗi chỉ tiêu một phiên bản `ACTIVE`, đặt `baseline` mẫu số của KPI-01 theo giả định GĐ-04 (200 HTTT) chờ Mai chỉnh, phát EVT-16-01 cho từng chỉ tiêu.
2. Hà kích hoạt phiên bản mẫu mới của `tre-gateway-p95`; hệ thống tạo bản ghi cập nhật mẫu cho mọi tenant đã kế thừa và đặt cờ `hasCommonUpdate` (API-16-001 với `scope = COMMON`).
3. Mai mở danh sách cập nhật (API-16-019) và xem so sánh mẫu mới với phiên bản của tenant.
4. Mai chọn "Nhận" (API-16-020, `ACCEPT`); hệ thống tạo phiên bản `DRAFT` mới của tenant từ mẫu và đưa vào duyệt bốn mắt (UC-16-03).

**Luồng thay thế.**
- **4a. Bỏ qua.** Mai chọn "Bỏ qua" (`DISMISS`); hệ thống ghi quyết định và không nhắc lại cho cùng phiên bản mẫu.
- **4b. Xung đột tùy biến.** Tenant đã sửa công thức mà mẫu cũng đổi trường đó: Mai chọn giữ bản của tỉnh hay của mẫu cho từng trường rồi mới nhận được.

**Luồng ngoại lệ.**
- **E1. Chỉ tiêu đã kế thừa (bước 1).** ERR-16-002 (409): "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." ({Đối tượng} = Chỉ tiêu)
- **E2. Xung đột tùy biến chưa giải quyết (4b).** ERR-16-055 (409): "Trường {trường} đã được tỉnh tùy biến và mẫu cũng thay đổi. Chọn giữ bản nào."

**Quy tắc áp dụng.** BR-16-018.

**Màn hình, API.** UI-16-03; API-16-001, 018, 019, 020; kịch bản TS-16-04.
:::

```{.mermaid caption="Trình tự phát hành mẫu mới và nhận cập nhật tại tenant"}
sequenceDiagram
  actor Ha as Hà (PA)
  actor Mai as Mai (TA)
  participant K as kpi-control
  participant H as PH-18
  Ha->>K: Kích hoạt phiên bản mẫu mới ở COMMON
  K->>K: Tạo cập nhật mẫu cho mọi tenant đã kế thừa
  K->>H: Thông báo Mẫu có bản mới
  Mai->>K: Xem so sánh, chọn Nhận
  K->>K: Tạo phiên bản DRAFT của tenant
  K-->>Mai: Chuyển sang duyệt bốn mắt (UC-16-03)
```

Hình cho thấy mẫu chỉ phát tín hiệu, còn quyết định áp dụng nằm ở tenant.

### 6.5. UC-16-05 · Đăng ký nguồn số liệu và theo dõi độ tươi

Mọi biến trong công thức phải có nguồn. Cán bộ đăng ký nguồn kèm hợp đồng chỉ số, thử đọc, rồi hệ thống tự theo dõi độ tươi để người dùng biết số nào đang cũ.

::: dac-ta
**Mục tiêu.** Chi đăng ký nguồn `ph08-dq-kpi` (EVENT, topic `t68.dq.kpi.published.v1`, đọc bù API-08-122) với hợp đồng gồm chỉ số `ph08.dq.score`; khi nguồn lặng quá hạn, TO nhận thông báo và biết chỉ tiêu nào bị ảnh hưởng.

**Tác nhân chính.** TO (Chi), TA (Mai).

**Tác nhân phụ.** PH-10 (topic), PH-08 (phân hệ cung cấp), PH-13 (thông báo), PH-18 (việc "Kiểm tra nguồn").

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-009, FR-16-013.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-source`; với `EVENT`, topic đã được PH-10 cấp và PH-16 có quyền đọc (FR-10-067); với `PULL_API`, phân hệ nguồn đã cấp scope đọc chỉ số cho tài khoản dịch vụ PH-16.

**Kích hoạt.** Bấm "+ Nguồn" ở UI-16-05; bộ quét độ tươi chạy mỗi 10 phút; nút "Tạm dừng", "Tiếp tục".

**Đảm bảo tối thiểu.** Không lưu nguồn chưa thử đạt; không cảnh báo giả khi nguồn đang tạm dừng.

**Đảm bảo thành công.** Nguồn `ACTIVE` có hợp đồng chỉ số hợp lệ; trạng thái nguồn luôn phản ánh độ tươi và số lần lỗi.

**Luồng chính.**
1. Chi chọn loại `EVENT`, nhập mã `ph08-dq-kpi`, phân hệ cung cấp PH-08, `topic`, `schemaRef`, `backfillEndpoint`, `staleHoursOverride = 744` (PH-08 đo hằng tháng) và danh sách `metricCode` của hợp đồng (API-16-022).
2. Hệ thống kiểm mã theo mẫu và chưa dùng, cấu hình đủ theo loại, mọi `metricCode` có trong danh mục (API-16-010) hoặc tạo mục mới `DRAFT`.
3. Chi bấm "Thử" (API-16-025); hệ thống đọc thử bản tin gần nhất của topic, đối chiếu lược đồ.
4. Hệ thống lưu nguồn `ACTIVE`, ghi kiểm toán, phát EVT-16-03.
5. Bộ quét tính tuổi quan sát mới nhất; quá `16.source.stale-hours` (26 giờ, hoặc mức riêng của nguồn) thì chuyển `STALE`; nguồn `PULL_API` lỗi liên tiếp đủ `16.source.fail-after` (3 lần) thì chuyển `FAILED`; phát EVT-16-03.
6. PH-13 gửi thông báo cho TO, PH-18 tạo việc "Kiểm tra nguồn"; Chi xem nguồn ở UI-16-05, 06 (API-16-021, API-16-023).
7. Nguồn có quan sát mới hoặc lần kéo đạt tự về `ACTIVE`, phát EVT-16-03.

**Luồng thay thế.**
- **7a. Tạm dừng.** Chi bấm "Tạm dừng" kèm lý do và hạn `until` (API-16-026): nguồn `PAUSED`, ngừng tiêu thụ hoặc kéo, không cảnh báo; tới hạn tự tiếp tục hoặc bấm "Tiếp tục" (API-16-027).
- **7b. Ngừng hẳn.** Mai bấm "Ngừng" (API-16-028): chỉ được khi nguồn không còn là nguồn duy nhất của biến thuộc chỉ tiêu `ACTIVE`; nguồn chuyển `RETIRED`.

**Luồng ngoại lệ.**
- **E1. Mã trùng (bước 2).** ERR-16-002 (409): "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." ({Đối tượng} = Nguồn)
- **E3. Cấu hình thiếu theo loại (bước 2).** ERR-16-015 (422): "Nguồn loại {loại} cần {trường}. Bổ sung trước khi lưu."
- **E4. Thử thất bại (bước 3).** ERR-16-016 (422): "Không đọc được dữ liệu từ nguồn {mã}: {lý do}. Kiểm tra quyền và cấu hình."
- **E5. Nguồn quá hạn (bước 5, chạy nền).** ERR-16-107: "Nguồn {mã} không có số mới từ {thời điểm}." Hiện ở UI-16-05 và thông báo PH-13.
- **E6. Nguồn lỗi liên tiếp (bước 5, chạy nền).** ERR-16-108: "Nguồn {mã} lỗi {n} lần liên tiếp, đã chuyển trạng thái Lỗi."
- **E8. Ngừng nguồn còn chỉ tiêu phụ thuộc (7b).** ERR-16-017 (409): "Nguồn {mã} là nguồn duy nhất của {n} chỉ tiêu đang hiệu lực."

**Quy tắc áp dụng.** BR-16-007, BR-16-012, BR-16-014.

**Màn hình, API.** UI-16-05, UI-16-06; API-16-010, 021…028; kịch bản TS-16-05.
:::

```{.mermaid caption="Trình tự theo dõi độ tươi và cảnh báo nguồn"}
sequenceDiagram
  actor Chi as Chi (TO)
  participant Q as Bộ quét độ tươi
  participant K as kpi-control
  participant H as PH-13, PH-18
  Q->>K: Tuổi quan sát ph08-dq-kpi quá hạn
  K->>K: Nguồn ACTIVE sang STALE
  K->>H: EVT-16-03 source.state-changed
  H-->>Chi: Thông báo và việc Kiểm tra nguồn
  Chi->>K: Xem nguồn, bấm Kéo ngay hoặc Đọc bù
  K->>K: Có quan sát mới, STALE về ACTIVE
  K->>H: EVT-16-03
```

Hình cho thấy trạng thái nguồn đổi ở một nơi và được phát đi, nên người dùng không phải tự dò từng nguồn.

### 6.6. UC-16-06 · Tiếp nhận quan sát từ sự kiện, kéo API và API đẩy

Đây là cửa vào của mọi số liệu tự động. Phân hệ nguồn chỉ cung cấp số đã tổng hợp; PH-16 chuẩn hóa, loại trùng, kiểm hợp đồng rồi ghi quan sát, không bao giờ ghi đè.

::: dac-ta
**Mục tiêu.** Quan sát `ph08.dq.score = 87.4` của kỳ `M-2026-10` từ EVT-08-14 được ghi đúng một lần dù sự kiện giao lại hay đọc bù trùng; bản tin sai lược đồ hay ngoài hợp đồng được đưa vào hàng bị loại để TO xem.

**Tác nhân chính.** Phân hệ nguồn (PH-08, PH-01, PH-02, PH-19, PH-13).

**Tác nhân phụ.** Kafka (PH-10), Chi (TO, xem kết quả), PH-13 (cảnh báo).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-010, FR-16-011, FR-16-012.

**Truy vết.** REQ-16; BP-11 (đề nghị); LGC-BUS-027 (gián tiếp).

**Tiền điều kiện.** Nguồn `ACTIVE` hoặc `STALE` (UC-16-05); với kéo API, nguồn không ở `PAUSED`, `RETIRED`; với API đẩy, `clientId` của bên gọi khớp nguồn `PUSH_API`.

**Kích hoạt.** Bản tin mới trên topic của nguồn; tới lịch `cron` của nguồn `PULL_API`; nút "Kéo ngay", "Đọc bù"; bên gọi gọi `POST /ingest/observations`.

**Đảm bảo tối thiểu.** Không ghi quan sát trùng hay sai lược đồ; offset chỉ được xác nhận sau khi ghi thành công (giao lại khi phân vùng chưa sẵn sàng); quan sát không chứa định danh cá nhân (BR-16-028).

**Đảm bảo thành công.** Quan sát nằm đúng kỳ theo `periodEnd`, có `sourceRef`, `idempotencyRef`; kỳ đã tính được đánh dấu cần tính lại khi `16.late-data.recompute = true`.

**Luồng chính.**
1. PH-08 phát EVT-08-14 `t68.dq.kpi.published.v1` mang `snapshotId` và điểm 87.4 cho `M-2026-10`.
2. Bộ tiêu thụ ghi `eventId` vào inbox trong cùng giao dịch với quan sát; `eventId` đã có thì bỏ qua và đếm "trùng".
3. Hệ thống giải mã theo `schemaRef`, ánh xạ sang quan sát (`metricCode = ph08.dq.score`, `value`, `periodStart`, `periodEnd`, `sourceRef = eventId`, `idempotencyRef = snapshotId`), quy đổi múi giờ `Asia/Ho_Chi_Minh`.
4. Hệ thống kiểm `metricCode` thuộc hợp đồng và `tenantId` của bản tin trùng tenant của topic.
5. Hệ thống lọc bản ghi thử theo quy tắc của nguồn (PH-19 bỏ `isTest = true`), ghi quan sát và nhật ký tiếp nhận.
6. Kỳ `COMPUTED` chưa chốt nhận quan sát mới thì đánh dấu cần tính lại (UC-16-10).

**Luồng thay thế.**
- **1a. Kéo API theo lịch.** Hệ thống lấy token máy theo scope của nguồn, gọi API với tham số kỳ (chờ 30 giây), phân trang, ánh xạ với `idempotencyRef = {sourceCode}:{metricCode}:{periodCode}:{dimensions-hash}`; lỗi thì thử lại 3 lần giãn cách 1, 2, 4 phút rồi tăng `failCount` (API-16-029).
- **1b. Đọc bù cho nguồn `EVENT`.** Chi bấm "Đọc bù" (khoảng tối đa 12 tháng): dùng `backfillEndpoint`, cùng `idempotencyRef` với sự kiện nên không trùng khi sự kiện đến muộn.
- **1c. API đẩy.** Bên gọi có scope `kpi.ingest` gửi lô quan sát (API-16-030); phần tử hợp lệ vẫn được ghi (`207`), phần tử trùng cùng giá trị trả `DUPLICATE`, lô gửi lại cùng `Idempotency-Key` nhận đúng phản hồi lần đầu.

**Luồng ngoại lệ.** Lỗi chạy nền hiện ở UI-16-06 tab "Bị loại" và chỉ số PH-13; lỗi của API đẩy trả cho bên gọi.
- **E1. Bản tin sai lược đồ (bước 3).** ERR-16-105: "Bản tin không đúng lược đồ {schemaRef}: {chi tiết}."
- **E2. Quan sát sai lược đồ hoặc lệch tenant (bước 4, 1c).** ERR-16-101 (400): "Quan sát thứ {i} sai lược đồ: {trường}."
- **E3. Chỉ số ngoài hợp đồng (bước 4).** ERR-16-102 (403): "Chỉ số {metricCode} không thuộc hợp đồng của nguồn {mã}."
- **E4. Cùng tham chiếu khác giá trị (bước 4).** ERR-16-103 (409): "Quan sát {idempotencyRef} đã có với giá trị khác. Cần kiểm tra ở phân hệ nguồn."
- **E5. Kỳ đã chốt (bước 6).** ERR-16-104 (422): "Quan sát thuộc kỳ {kỳ} đã chốt, được lưu làm số liệu trễ và không tính."
- **E6. Kéo API lỗi (1a).** ERR-16-106: "Kéo số từ {mã} lỗi lần {n}: {mã HTTP hoặc lý do}."

**Quy tắc áp dụng.** BR-16-001, BR-16-012, BR-16-013, BR-16-014, BR-16-019, BR-16-028.

**Màn hình, API.** UI-16-06; API-16-029, 030, 042, 043, 044; kịch bản TS-16-06.
:::

```{.mermaid caption="Trình tự tiếp nhận quan sát từ sự kiện và đọc bù"}
sequenceDiagram
  participant P as PH-08
  participant B as Kafka (PH-10)
  participant I as kpi-ingest
  participant D as ph16_kpi
  P->>B: EVT-08-14 dq.kpi.published
  B->>I: Bản tin kèm eventId
  I->>D: Inbox eventId, kiểm trùng
  I->>I: Giải mã, ánh xạ, kiểm hợp đồng và tenant
  I->>D: Ghi quan sát, nhật ký tiếp nhận
  I-->>B: Xác nhận offset
  Note over I,P: Lỡ sự kiện thì đọc bù API-08-122 cùng idempotencyRef
```

Hình cho thấy trùng lặp bị chặn ở inbox và offset chỉ xác nhận sau khi ghi xong, nên giao lại không làm đôi số liệu.

### 6.7. UC-16-07 · Tra nhật ký tiếp nhận, xử lý lại quan sát bị loại

Bản tin bị loại không biến mất: cán bộ tra được vì sao, sửa hợp đồng hoặc lược đồ rồi cho xử lý lại.

::: dac-ta
**Mục tiêu.** Chi thấy 3 bản tin của `ph08-dq-kpi` bị loại vì lược đồ cũ, sửa `schemaRef`, bấm "Xử lý lại" và cả 3 thành quan sát hợp lệ.

**Tác nhân chính.** TO (Chi), TA (Mai).

**Tác nhân phụ.** Không.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-16-016.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Xử lý lại cần `PERM-16-source`; xem nhật ký cần `PERM-16-read`; PO xem toàn nền tảng.

**Kích hoạt.** UI-16-06 tab "Nhật ký tiếp nhận", "Bị loại", "Quan sát".

**Đảm bảo tối thiểu.** Bản tin bị loại giữ nguyên cho tới khi xử lý đạt; không ghi đè quan sát cũ khi chưa quyết định.

**Đảm bảo thành công.** Bản tin đạt thành quan sát, đánh dấu `REPROCESSED`; bản tin còn lỗi có lý do mới.

**Luồng chính.**
1. Chi mở UI-16-06 tab "Nhật ký tiếp nhận", lọc khoảng thời gian (API-16-042, API-16-043); hệ thống kiểm khoảng không quá 36 tháng.
2. Chi chuyển tab "Bị loại" (API-16-044), xem lý do từng bản tin và sửa hợp đồng hoặc lược đồ ở UC-16-05.
3. Chi chọn các bản tin đã sửa, bấm "Xử lý lại" (API-16-045).
4. Hệ thống chạy lại bước chuẩn hóa và kiểm cho từng bản tin; đạt thì ghi quan sát và đánh dấu `REPROCESSED`, không đạt thì cập nhật lý do mới.
5. Hệ thống trả số đạt, số còn lỗi và ghi kiểm toán.

**Luồng thay thế.**
- **3a. Bản tin xung đột.** Với bản tin bị loại do cùng `idempotencyRef` khác giá trị, Chi chọn "Giữ giá trị cũ" (đóng) hoặc "Nhận giá trị mới" (cần `PERM-16-run`); chọn nhận thì quan sát cũ đánh dấu bị thay và kỳ được tính lại.

**Luồng ngoại lệ.**
- **E1. Khoảng tra vượt 36 tháng (bước 1).** ERR-16-060 (400): "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần." ({n} = 36)
- **E2. Bản tin đã xử lý (bước 3).** ERR-16-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." ({thao tác} = xử lý lại, {đối tượng} = bản tin {mã}, {trạng thái} = `REPROCESSED`)

**Quy tắc áp dụng.** BR-16-012.

**Màn hình, API.** UI-16-06; API-16-042, 043, 044, 045; kịch bản TS-16-07.
:::

### 6.8. UC-16-08 · Nhập số liệu tay kèm bằng chứng và xác nhận

Chỉ tiêu không đo tự động được (ví dụ KPI-08 hồ sơ cấp độ phê duyệt) do người nhập kèm bằng chứng; người thứ hai có vai trò được giao xác nhận. Số tay chỉ vào chỉ tiêu sau khi được xác nhận.

::: dac-ta
**Mục tiêu.** Chi nhập giá trị 1 (có) cho `ho-so-cap-do-phe-duyet` kỳ `M-2026-10` kèm số văn bản "QĐ 1234/QĐ-UBND" và tệp PDF; Dũng (SO) xác nhận; số đi vào lần tổng hợp kế tiếp.

**Tác nhân chính.** TO (Chi, người nhập), SO (Dũng, người xác nhận), DS (Lan, cho chỉ tiêu về danh mục).

**Tác nhân phụ.** Kho đối tượng (bằng chứng), PH-18 (việc xác nhận), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-014, FR-16-015.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Chỉ tiêu `MANUAL` hoặc `MIXED`, phiên bản `ACTIVE`, `confirmerRoles = ["SO"]`; kỳ chưa `CLOSED`; người nhập có `PERM-16-manual`.

**Kích hoạt.** UI-16-07 chọn "Nhập theo biểu mẫu" hoặc "Nhập từ tệp XLSX"; người xác nhận mở việc ở UI-16-12 hoặc UI-16-07 tab "Chờ xác nhận".

**Đảm bảo tối thiểu.** Không có số `SUBMITTED` nào không bằng chứng khi `16.manual.evidence-required = true`; người nhập không tự xác nhận.

**Đảm bảo thành công.** Bản nhập `ACCEPTED`, quan sát nguồn `MANUAL` có `sourceRef = manualId`; kỳ đã tính được xếp tính lại.

**Luồng chính.**
1. Chi chọn kỳ `M-2026-10`, chỉ tiêu, nhập giá trị 1, ghi chú phương pháp, gắn tệp quyết định và số văn bản, bấm "Lưu nháp" (API-16-032, API-16-035).
2. Hệ thống kiểm giá trị trong miền của chỉ tiêu, loại và cỡ tệp, băm SHA-256 tệp, lưu kho đối tượng.
3. Chi bấm "Gửi xác nhận" (API-16-039); hệ thống kiểm có bằng chứng và chưa có giá trị `ACCEPTED` cùng chỉ tiêu, kỳ.
4. Hệ thống chuyển `SUBMITTED`, tạo việc xác nhận cho người có vai trò trong `confirmerRoles`, khác người nhập.
5. Dũng mở bản nhập, xem trực tiếp tệp, phương pháp, giá trị kỳ trước (API-16-033); hệ thống kiểm Dũng khác Chi và đúng vai trò.
6. Dũng chọn "Xác nhận" (API-16-040); hệ thống chuyển `ACCEPTED`, ghi quan sát nguồn `MANUAL`, ghi kiểm toán, phát EVT-16-04, xếp tính lại kỳ nếu đã tính (UC-16-10).

**Luồng thay thế.**
- **1a. Nhập từ tệp XLSX.** Chi tải mẫu (API-16-036) và tải tệp (API-16-037); hệ thống kiểm từng dòng và hiện bảng xem trước đánh dấu dòng lỗi; Chi bấm "Ghi các dòng hợp lệ" (API-16-038); tối đa 2.000 dòng.
- **6a. Từ chối.** Dũng chọn "Từ chối" kèm lý do (API-16-041); bản nhập `REJECTED`, Chi nhận thông báo.
- **6b. Chỉ tiêu `MIXED` (KPI-09).** Số quét tự động chỉ có hiệu lực khi SO xác nhận một bản nhập `MANUAL` cùng kỳ ghi "đồng ý với số quét".

**Luồng ngoại lệ.**
- **E1. Giá trị ngoài miền (bước 2).** ERR-16-019 (422): "Giá trị {giá trị} nằm ngoài miền cho phép của chỉ tiêu ({miền})."
- **E2. Tệp bằng chứng sai loại, quá cỡ (bước 2).** ERR-16-053 (400): "Tệp {tên} không được nhận: chỉ PDF, ảnh, XLSX, DOCX tối đa {n} MB." (n = 20)
- **E3. Tệp nhập sai mẫu hoặc quá 2.000 dòng (1a).** ERR-16-020 (422): "Tệp không đúng mẫu nhập số liệu hoặc vượt 2.000 dòng. Tải mẫu mới nhất."
- **E4. Thiếu bằng chứng (bước 3).** ERR-16-018 (422): "Số liệu tay cần ít nhất một bằng chứng (tệp hoặc số văn bản)."
- **E5. Đã có số được xác nhận (bước 3).** ERR-16-021 (409): "Kỳ {kỳ} đã có số được xác nhận cho chỉ tiêu này. Tạo bản đính chính."
- **E7. Tự xác nhận hoặc không đúng vai trò (bước 5).** ERR-16-005 (403): "Anh/chị là người {vai} nên không được {thao tác}." ({vai} = nhập, {thao tác} = tự xác nhận); ERR-16-059 (403): "Anh/chị không thuộc vai trò được giao xác nhận {đối tượng} này." ({đối tượng} = số liệu của chỉ tiêu {mã})
- **E8. Từ chối thiếu lý do (6a).** ERR-16-007 (422): "Nhập {nội dung} (tối thiểu {n} ký tự)." ({nội dung} = lý do từ chối, {n} = 20)

**Quy tắc áp dụng.** BR-16-005, BR-16-006, BR-16-035.

**Màn hình, API.** UI-16-07, UI-16-12; API-16-031…041, 078; kịch bản TS-16-08.
:::

```{.mermaid caption="Trình tự nhập số liệu tay và xác nhận bốn mắt"}
sequenceDiagram
  actor Chi as Chi (TO nhập)
  actor Dung as Dũng (SO xác nhận)
  participant K as kpi-control
  participant O as Kho đối tượng
  participant H as PH-18
  Chi->>K: Nhập giá trị, số văn bản
  Chi->>O: Tải tệp bằng chứng
  K->>O: Lưu tệp, băm SHA-256
  Chi->>K: Gửi xác nhận
  K->>K: Kiểm bằng chứng, SUBMITTED
  K->>H: Tạo việc xác nhận cho SO
  Dung->>K: Mở bản nhập, bấm Xác nhận
  K->>K: Kiểm Dũng khác Chi, ACCEPTED
  K->>K: Ghi quan sát MANUAL, xếp tính lại kỳ
```

Hình cho thấy bằng chứng được băm và lưu trước khi gửi, và số chỉ thành quan sát sau khi người thứ hai xác nhận.

### 6.9. UC-16-09 · Quản lý kỳ báo cáo, chốt kỳ và mở lại kỳ

Kỳ là khung thời gian của mọi con số. Hệ thống tự sinh kỳ; quản trị tỉnh chốt kỳ để số không còn đổi, và chỉ mở lại có lý do.

::: dac-ta
**Mục tiêu.** Kỳ `M-2026-10` được chốt ngày 5 tháng 11 với số chính thức; khi cần sửa, Mai mở lại có lý do và chốt lại.

**Tác nhân chính.** TA (Mai), TO (Chi tạo kỳ bổ sung).

**Tác nhân phụ.** Bộ lập lịch nội bộ, PH-18 (việc "Kỳ chưa chốt được").

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-017, FR-16-024.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** `16.period.types` có loại kỳ cần sinh; chốt và mở lại cần `PERM-16-run` do TA giữ (TO không chốt); chốt cần kỳ `COMPUTED` hoặc `REOPENED`, mở lại cần kỳ `CLOSED`.

**Kích hoạt.** Bộ lập lịch 00:05 hằng ngày; nút "+ Kỳ", "Chốt kỳ", "Mở lại" ở UI-16-08; lịch tự chốt ngày 5 lúc 23:00.

**Đảm bảo tối thiểu.** Kỳ chưa đủ điều kiện không bị chốt; kỳ có báo cáo đang duyệt không bị mở lại.

**Đảm bảo thành công.** Kỳ `CLOSED` có `closedAt`, `closedBy`, lần tổng hợp chính thức; quan sát đến sau được ghi `late` và không tính.

**Luồng chính.**
1. Hằng ngày hệ thống tạo kỳ tháng, quý, năm bắt đầu trong 7 ngày tới ở `OPEN`; kỳ có `endDate` đã qua chuyển `COLLECTING` (API-16-046, API-16-048).
2. Đến 01:30 ngày đầu kỳ sau, lần tổng hợp đầu được xếp (UC-16-10); kỳ chuyển `COMPUTED`.
3. Mai kiểm kết quả ở UI-16-08 rồi bấm "Chốt kỳ" (API-16-057).
4. Hệ thống kiểm lần tổng hợp gần nhất đã kết thúc, không còn số tay `SUBMITTED`, không có quan sát mới chưa tính.
5. Hệ thống chuyển `CLOSED`, ghi `closedAt`, `closedBy`, kiểm toán, phát EVT-16-14 để PH-13, PH-17 biết số chính thức đã sẵn sàng.

**Luồng thay thế.**
- **1a. Kỳ bổ sung.** Chi bấm "+ Kỳ" (API-16-047) để tạo kỳ quá khứ cho báo cáo nền; kỳ quá khứ tạo ở `COLLECTING`.
- **3a. Tự chốt.** Ngày 5 lúc 23:00 hệ thống tự chốt khi đủ điều kiện; không đủ thì tạo việc cho Mai "Kỳ {kỳ} chưa chốt được" kèm lý do.
- **4a. Còn chỉ tiêu `PARTIAL`.** Mai đặt `confirmPartial = true`; nhãn `PARTIAL` giữ trên số chốt.
- **5a. Mở lại.** Mai bấm "Mở lại" kèm lý do (API-16-058): kỳ `REOPENED`, phát EVT-16-14 kèm lý do; chốt lại mà giá trị của báo cáo `PUBLISHED` đổi thì báo cáo đó bị gắn cờ "cần đính chính" (UC-16-16).

**Luồng ngoại lệ.**
- **E1. Mã kỳ sai, trùng hoặc ở tương lai (1a).** ERR-16-024 (422): "Kỳ {mã} không hợp lệ hoặc đã có. Mã kỳ có dạng M-2026-10, Q-2026-Q3, Y-2026."
- **E2. Chưa đủ điều kiện chốt (bước 4).** ERR-16-025 (422): "Chưa chốt được kỳ {kỳ}: {lý do}." (ví dụ còn 2 số liệu tay chờ xác nhận)
- **E3. Còn báo cáo đang duyệt (5a).** ERR-16-026 (409): "Kỳ {kỳ} có báo cáo đang duyệt. Trả báo cáo về nháp trước khi mở lại kỳ."
- **E4. Mở lại thiếu lý do (5a).** ERR-16-007 (422): "Nhập {nội dung} (tối thiểu {n} ký tự)." ({nội dung} = lý do mở lại, {n} = 50)

**Quy tắc áp dụng.** BR-16-011, BR-16-013, BR-16-033.

**Màn hình, API.** UI-16-08; API-16-046, 047, 048, 057, 058; kịch bản TS-16-09.
:::

### 6.10. UC-16-10 · Chạy tổng hợp theo lịch hoặc thủ công và tính lại

Tổng hợp là việc tính mọi chỉ tiêu của một kỳ. Hệ thống chạy hằng đêm; cán bộ có thể chạy tay, hủy, và hệ thống tự tính lại khi có số trễ.

::: dac-ta
**Mục tiêu.** Kỳ `M-2026-10` có kết quả tổng hợp mỗi đêm; khi PH-08 gửi số trễ lúc 10:15, hệ thống gom yêu cầu và tính lại đúng một lần.

**Tác nhân chính.** TO (Chi), TA (Mai); hệ thống theo lịch `16.aggregate.cron`.

**Tác nhân phụ.** `kpi-compute`, PH-13 (nhận EVT-16-05), PH-18, PO (hủy lần treo).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-018, FR-16-023.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Kỳ ở `OPEN`, `COLLECTING`, `COMPUTED` hoặc `REOPENED`; không có lần `QUEUED`, `RUNNING` cho kỳ; có `PERM-16-run`.

**Kích hoạt.** Lịch `0 30 1 * * *`; nút "Tổng hợp ngay" ở UI-16-08, "Tính lại" ở UI-16-09; quan sát hoặc số tay mới cho kỳ đã tính; phiên bản định nghĩa mới có hiệu lực trong kỳ.

**Đảm bảo tối thiểu.** Một chỉ tiêu lỗi không dừng cả lần; lần `FAILED` hoặc `CANCELLED` không ghi đè kết quả lần trước.

**Đảm bảo thành công.** Lần tổng hợp `SUCCEEDED` hoặc `PARTIAL` có `completeness`, `flags[]`; kỳ `COLLECTING` sang `COMPUTED`.

**Luồng chính.**
1. Chi bấm "Tổng hợp ngay" (API-16-050); hệ thống kiểm kỳ cho phép và không có lần đang chạy, tạo lần `QUEUED`.
2. Bộ tính nhận việc dưới khóa theo tenant, chuyển `RUNNING`, chụp danh sách phiên bản định nghĩa có hiệu lực của kỳ.
3. Hệ thống tính từng chỉ tiêu theo thứ tự phụ thuộc (UC-16-11).
4. Kết thúc: `SUCCEEDED` khi mọi chỉ tiêu `COMPLETE`, `PARTIAL` khi có thiếu; kỳ sang `COMPUTED`; phát EVT-16-05.
5. Chi theo dõi tiến độ ở UI-16-09 (API-16-049, API-16-051).

**Luồng thay thế.**
- **1a. Tính lại.** Quan sát trễ hoặc số tay `ACCEPTED` cho kỳ đã tính: hệ thống gom các yêu cầu của cùng kỳ trong cửa sổ 5 phút, tạo lần `trigger = LATE_DATA` (API-16-055); bản nháp báo cáo của kỳ hiện dải "Số liệu kỳ đã được tính lại" (UC-16-13).
- **3a. Hủy.** Chi hoặc PO hủy lần `QUEUED`, `RUNNING` (API-16-052): `CANCELLED`, kết quả dở không được dùng.

**Luồng ngoại lệ.**
- **E1. Kỳ đã chốt (bước 1, 1a).** ERR-16-022 (409): "Kỳ {kỳ} đã chốt. Mở lại kỳ nếu cần sửa hoặc tính lại."
- **E2. Đang có lần chạy (bước 1).** ERR-16-023 (409): "Kỳ {kỳ} đang được tổng hợp (bắt đầu {thời điểm}). Chờ lần này xong."
- **E3. Quá thời gian (bước 4, chạy nền).** ERR-16-110: "Lần tổng hợp vượt {n} phút và đã dừng. Kết quả lần trước được giữ." (n = 15)

**Quy tắc áp dụng.** BR-16-007, BR-16-011, BR-16-030.

**Màn hình, API.** UI-16-08, UI-16-09; API-16-049…052, 055, 069; kịch bản TS-16-10.
:::

```{.mermaid caption="Trình tự tổng hợp theo lịch và thông báo kết quả"}
sequenceDiagram
  participant S as Bộ lập lịch
  participant C as kpi-compute
  participant D as ph16_kpi
  participant H as PH-13, PH-18
  S->>C: Kích hoạt lúc 01:30
  C->>D: Tạo lần QUEUED, khóa theo tenant
  C->>D: Chụp phiên bản định nghĩa của kỳ
  C->>C: Tính từng chỉ tiêu (UC-16-11)
  C->>D: Ghi giá trị, completeness, flags
  C->>H: EVT-16-05 period.computed
  H-->>H: Thông báo, việc cho TO nếu PARTIAL
```

Hình cho thấy kết quả tổng hợp được báo cho PH-13, PH-18 qua sự kiện, không gọi trực tiếp.

### 6.11. UC-16-11 · Tính giá trị, độ đầy đủ, trạng thái và điểm nhóm

Đây là lõi tính toán của phân hệ, chạy bên trong lần tổng hợp. Nguyên tắc fail-soft: thiếu nguồn vẫn ra số phần có, gắn nhãn, không bịa.

::: dac-ta
**Mục tiêu.** `httt-ket-noi-ty-le` kỳ `M-2026-10` ra 78% (156/200), `COMPLETE`, `AT_RISK`; nhóm `KET_NOI` có điểm nhóm, xu hướng; chỉ tiêu thiếu nguồn ra `NO_DATA` kèm cờ.

**Tác nhân chính.** Hệ thống (`kpi-compute`).

**Tác nhân phụ.** PH-13 (nhận EVT-16-06 để báo lãnh đạo), Hùng (VW, nhận thông báo).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-019, FR-16-020, FR-16-021, FR-16-022.

**Truy vết.** REQ-16; BP-11 (đề nghị); LGC-APIM-026 (gián tiếp).

**Tiền điều kiện.** Lần tổng hợp `RUNNING` (UC-16-10); có phiên bản định nghĩa `ACTIVE` với `effectiveFrom` không sau ngày cuối kỳ.

**Kích hoạt.** Bước 3 của UC-16-10.

**Đảm bảo tối thiểu.** Không nội suy, không lấy số kỳ trước, không điền 0 (BR-16-007); công thức chạy trong giới hạn 50 ms và 10.000 bước.

**Đảm bảo thành công.** Mỗi chỉ tiêu có giá trị, trạng thái, độ đầy đủ, dòng truy nguồn; mỗi nhóm có điểm nhóm cùng trọng số đã dùng.

**Luồng chính.**
1. Hệ thống gộp quan sát từng `metricCode` theo `aggregation`; nhiều nguồn cùng chỉ số thì lấy nguồn `priority` cao nhất có số.
2. Hệ thống đánh giá công thức CEL, làm tròn hiển thị theo `decimals`, lưu giá trị đủ độ chính xác; kỳ quý, năm gộp từ giá trị các kỳ tháng con.
3. Hệ thống ghi dòng truy nguồn: các `observationId`, `manualId`, phiên bản định nghĩa, băm công thức (API-16-053, API-16-054).
4. Hệ thống đặt độ đầy đủ: `COMPLETE` khi mọi biến có quan sát từ nguồn `ACTIVE`; `PARTIAL` khi một biến lấy từ nguồn `STALE` hoặc thiếu một phần chiều; `NO_DATA` khi không tính được.
5. Hệ thống so ngưỡng theo chiều tốt (78 nằm vùng vàng, `AT_RISK`) và với trạng thái lần trước; trạng thái đổi thì ghi thay đổi và phát EVT-16-06.
6. Hệ thống quy điểm (`ON_TRACK` 100, `AT_RISK` 50, `OFF_TRACK` 0), tính điểm nhóm, điểm tổng có trọng số, `delta`, `deltaYoY`, `trend`.

**Luồng thay thế.**
- **2a. Chỉ tiêu `MANUAL`.** Giá trị là số tay `ACCEPTED` của kỳ; chưa có thì `NO_DATA`, kèm cờ `MANUAL_PENDING` nếu có bản `SUBMITTED`.
- **5a. Chuyển sang `NO_DATA`.** Không phát EVT-16-06; dựa vào cảnh báo nguồn ở UC-16-05.
- **6a. Nhóm không có số.** Điểm nhóm `null`, tỷ lệ phủ 0, không tham gia điểm tổng; `trend = FLAT` khi |delta| dưới 1% giá trị kỳ trước.

**Luồng ngoại lệ.** Chạy nền, hiện ở UI-16-09 và thẻ chỉ tiêu.
- **E1. Công thức lỗi khi tính (bước 2).** ERR-16-109: "Chỉ tiêu {mã}: công thức lỗi khi tính ({lý do}). Giá trị để trống."
- **E2. Thiếu nguồn (bước 4).** ERR-16-111: "Thiếu số liệu từ {nguồn} cho kỳ {kỳ}."
- **E3. Số liệu tay chờ xác nhận (2a).** ERR-16-112: "Chỉ tiêu {mã} chờ xác nhận số liệu tay."

**Quy tắc áp dụng.** BR-16-001, BR-16-002, BR-16-007, BR-16-008, BR-16-014, BR-16-015, BR-16-016, BR-16-017, BR-16-030, BR-16-033, BR-16-034.

**Màn hình, API.** UI-16-09, UI-16-01, UI-16-02; API-16-048, 051, 053, 054, 056, 090; kịch bản TS-16-11.
:::

### 6.12. UC-16-12 · Quản lý mẫu báo cáo

::: dac-ta
**Mục tiêu.** Mai có mẫu `bc-thang` gồm các phần `SUMMARY`, năm phần `GROUP`, `INDICATOR_TABLE`, `CHART`, `NARRATIVE`, `ANNEX`, xuất `PDF` và `XLSX`, có bản xem trước với số kỳ gần nhất.

**Tác nhân chính.** TA (Mai); PA (Hà) soạn mẫu chung ở `COMMON`.

**Tác nhân phụ.** Không.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-025.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-admin`.

**Kích hoạt.** UI-16-13 tab "Mẫu báo cáo".

**Đảm bảo tối thiểu.** Báo cáo đang soạn giữ phiên bản mẫu lúc lập, không đổi theo mẫu mới.

**Đảm bảo thành công.** Phiên bản mẫu mới `ACTIVE` hợp lệ.

**Luồng chính.**
1. Mai thêm, sắp xếp phần, chọn chỉ tiêu hoặc nhóm cho từng phần, chọn định dạng (API-16-060, API-16-062).
2. Hệ thống kiểm mã mẫu, mỗi phần có tiêu đề, chỉ tiêu tham chiếu tồn tại và `ACTIVE`, có phần `SUMMARY` cho báo cáo `PERIODIC`.
3. Mai bấm "Xem trước" (API-16-063); hệ thống dựng PDF mẫu với số của kỳ gần nhất đã tính.
4. Hệ thống lưu phiên bản mẫu mới, ghi kiểm toán.

**Luồng thay thế.**
- **4a. Ngừng mẫu.** `state = RETIRED`, không dùng cho báo cáo mới (API-16-059, API-16-061 để xem).

**Luồng ngoại lệ.**
- **E1. Mẫu không hợp lệ (bước 2).** ERR-16-027 (422): "Mẫu chưa hợp lệ: {phần} {lý do}."
- **E2. Mã đã dùng (bước 2).** ERR-16-002 (409): "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." ({Đối tượng} = Mẫu báo cáo)

**Quy tắc áp dụng.** BR-16-027.

**Màn hình, API.** UI-16-13; API-16-059…063; kịch bản TS-16-12.
:::

### 6.13. UC-16-13 · Lập bản nháp, thuyết minh và báo cáo đột xuất

::: dac-ta
**Mục tiêu.** Chi có bản nháp `bc-thang-2026-10` từ kỳ đã tính với giải trình cho mọi chỉ tiêu chệch; hoặc báo cáo đột xuất `AD_HOC` cho khoảng 2026-07 đến 2026-10.

**Tác nhân chính.** TO (Chi), TA (Mai).

**Tác nhân phụ.** PH-13 (cờ nguồn gián đoạn dùng làm gợi ý giải trình).

**Mức ưu tiên.** M · Đợt 3 (báo cáo đột xuất mức C).

**FR hiện thực.** FR-16-026, FR-16-027, FR-16-032.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-report`; kỳ `COMPUTED`, `CLOSED` hoặc `REOPENED`; mẫu `ACTIVE`.

**Kích hoạt.** Bấm "+ Báo cáo" ở UI-16-10; soạn ở UI-16-11; lịch tự lập bản nháp sau khi chốt kỳ (nếu bật trong mẫu).

**Đảm bảo tối thiểu.** Nội dung giải trình không chứa HTML tự do hay liên kết ngoài; không mất chữ khi sửa đồng thời.

**Đảm bảo thành công.** Báo cáo `DRAFT` gắn lần tổng hợp hiện hành, danh sách giải trình còn thiếu cập nhật theo thời gian thực.

**Luồng chính.**
1. Chi bấm "+ Báo cáo", chọn mẫu, kỳ `M-2026-10`, mã `bc-thang-2026-10` (API-16-065).
2. Hệ thống kiểm mã, mẫu, kỳ đã có kết quả tổng hợp; tạo báo cáo `DRAFT`, chép bố cục mẫu, liên kết lần tổng hợp hiện hành.
3. Hệ thống dựng bản xem trước (API-16-070), đánh dấu chỉ tiêu `OFF_TRACK`, chỉ tiêu bắt buộc `PARTIAL`, `NO_DATA` cần thuyết minh.
4. Chi viết thuyết minh, giải trình cạnh từng chỉ tiêu chệch (API-16-067, API-16-068), nhập số ký hiệu `documentNumber` và nơi nhận `recipientsNote` của báo cáo chính thức; hệ thống lưu tự động mỗi 30 giây.
5. Khi kỳ được tính lại, bản nháp hiện dải thông báo; Chi bấm "Làm mới số" (API-16-069) để lấy lần tổng hợp mới.

**Luồng thay thế.**
- **1a. Báo cáo đột xuất.** Chi chọn loại "Đột xuất", khoảng thời gian, tập chỉ tiêu: hệ thống gộp giá trị các kỳ tháng theo `aggregation`, ghi rõ kỳ thiếu, dùng mẫu mặc định (`SUMMARY`, `INDICATOR_TABLE`, `NARRATIVE`) nếu không chọn mẫu; đột xuất không gửi quốc gia (Q16-18 của FRS).

**Luồng ngoại lệ.**
- **E1. Kỳ chưa có kết quả (bước 2).** ERR-16-028 (422): "Kỳ {kỳ} chưa có kết quả tổng hợp hoặc chưa chốt. Hoàn tất trước khi lập hoặc gửi báo cáo."
- **E2. Mã đã dùng (bước 1).** ERR-16-002 (409): "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." ({Đối tượng} = Báo cáo)
- **E3. Sửa đồng thời (bước 4).** ERR-16-004 (409): "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."
- **E5. Khoảng đột xuất sai hoặc quá 24 tháng (1a).** ERR-16-033 (422): "Khoảng báo cáo từ {từ} đến {đến} không hợp lệ hoặc vượt 24 tháng."

**Quy tắc áp dụng.** BR-16-004, BR-16-007, BR-16-008, BR-16-029.

**Màn hình, API.** UI-16-10, UI-16-11; API-16-065…070; kịch bản TS-16-13.
:::

### 6.14. UC-16-14 · Gửi duyệt và duyệt báo cáo bốn mắt

Báo cáo chính thức không đi tiếp nếu thiếu số bắt buộc hay thiếu giải trình; người duyệt luôn khác người lập.

::: dac-ta
**Mục tiêu.** Chi gửi `bc-thang-2026-10` đi duyệt; Mai duyệt sau khi xem bản PDF xem trước, bảng số và thuyết minh, hoặc trả về kèm ý kiến.

**Tác nhân chính.** TO (Chi, người lập), TA (Mai, người duyệt).

**Tác nhân phụ.** PH-18 (việc duyệt), PH-13.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-028.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Báo cáo `DRAFT`; với `PERIODIC`, `NATIONAL` kỳ đã `CLOSED`; người gửi có `PERM-16-report`, người duyệt có `PERM-16-approve`.

**Kích hoạt.** Nút "Gửi duyệt" ở UI-16-11; Mai mở việc ở UI-16-12.

**Đảm bảo tối thiểu.** Không gửi duyệt khi thiếu số bắt buộc hay giải trình; không ai tự duyệt báo cáo mình lập hoặc gửi.

**Đảm bảo thành công.** Báo cáo `APPROVED` (hoặc `CHANGES_REQUESTED` kèm ý kiến, kể cả khi trả về từ `APPROVED`), nội dung khóa trong lúc `IN_REVIEW`.

**Luồng chính.**
1. Chi bấm "Gửi duyệt" (API-16-071); hệ thống kiểm kỳ đã chốt, không còn giải trình thiếu, chỉ tiêu `mandatory` không `NO_DATA`, báo cáo `PERIODIC`, `NATIONAL` có số ký hiệu và nơi nhận.
2. Hệ thống chuyển `IN_REVIEW`, khóa nội dung, phát EVT-16-07; PH-18 tạo việc cho người có `PERM-16-approve`.
3. Mai mở UI-16-12 (API-16-078), xem PDF xem trước, bảng số, thuyết minh.
4. Hệ thống kiểm Mai khác người lập và người gửi.
5. Mai chọn "Duyệt" (API-16-072); báo cáo `APPROVED`, ghi kiểm toán.

**Luồng thay thế.**
- **5a. Yêu cầu sửa.** Mai chọn "Yêu cầu sửa" kèm ý kiến (API-16-073): báo cáo `CHANGES_REQUESTED`, phát EVT-16-09, Chi sửa tiếp ở `DRAFT` (UC-16-13).
- **5b. Trả về soạn.** Báo cáo `APPROVED` chưa công bố cần sửa (ký số lỗi kéo dài, sai số phát hiện trước công bố, cần mở lại kỳ theo ERR-16-026): Mai chọn "Trả về soạn" kèm ý kiến (API-16-073); báo cáo `CHANGES_REQUESTED`, phát EVT-16-09, Chi sửa tiếp ở `DRAFT`.
- **1a. Báo cáo đột xuất nội bộ.** Khi `16.report.four-eyes = false`, người lập có `PERM-16-approve` tự duyệt; kiểm toán ghi "không bốn mắt"; không áp dụng cho `PERIODIC`, `NATIONAL`.

**Luồng ngoại lệ.**
- **E1. Kỳ chưa chốt (bước 1).** ERR-16-028 (422): "Kỳ {kỳ} chưa có kết quả tổng hợp hoặc chưa chốt. Hoàn tất trước khi lập hoặc gửi báo cáo."
- **E2. Thiếu chỉ tiêu bắt buộc (bước 1).** ERR-16-029 (422): "Chỉ tiêu bắt buộc {danh sách} chưa có số liệu. Báo cáo chính thức chưa gửi duyệt được."
- **E3. Thiếu giải trình (bước 1).** ERR-16-030 (422): "Còn {n} chỉ tiêu chệch hoặc thiếu số chưa có giải trình."
- **E3b. Thiếu số ký hiệu hoặc nơi nhận (bước 1).** ERR-16-061 (422): "Báo cáo chính thức cần số ký hiệu và nơi nhận trước khi gửi duyệt."
- **E4. Tự duyệt (bước 4).** ERR-16-005 (403): "Anh/chị là người {vai} nên không được {thao tác}." ({vai} = lập hoặc gửi báo cáo, {thao tác} = tự duyệt)
- **E5. Thiếu ý kiến (5a, 5b).** ERR-16-007 (422): "Nhập {nội dung} (tối thiểu {n} ký tự)." ({nội dung} = ý kiến, {n} = 20)

**Quy tắc áp dụng.** BR-16-004, BR-16-008, BR-16-029.

**Màn hình, API.** UI-16-11, UI-16-12; API-16-071, 072, 073, 078; kịch bản TS-16-14.
:::

```{.mermaid caption="Trình tự gửi duyệt và duyệt báo cáo bốn mắt"}
sequenceDiagram
  actor Chi as Chi (TO lập)
  actor Mai as Mai (TA duyệt)
  participant K as kpi-report
  participant H as PH-18, PH-13
  Chi->>K: Gửi duyệt bc-thang-2026-10
  K->>K: Kiểm kỳ chốt, giải trình, chỉ tiêu bắt buộc
  K->>H: EVT-16-07 report.submitted
  H-->>Mai: Việc duyệt báo cáo
  Mai->>K: Mở xem trước, bấm Duyệt
  K->>K: Kiểm Mai khác Chi, APPROVED
  K->>H: Kiểm toán, EVT-16-09 nếu yêu cầu sửa
```

Hình cho thấy báo cáo thiếu số hay tự duyệt không đi tiếp được.

### 6.15. UC-16-15 · Công bố báo cáo chính thức

Công bố biến báo cáo đã duyệt thành bản không thể sửa: chụp số, dựng PDF, ký số, lưu kho WORM.

::: dac-ta
**Mục tiêu.** Mai công bố `bc-thang-2026-10`; ra bản PDF ký số kèm `contentHash`, lưu bất biến 10 năm; mọi người có `PERM-16-read` thấy báo cáo "Đã công bố".

**Tác nhân chính.** TA (Mai), khác người lập.

**Tác nhân phụ.** Dịch vụ ký số, kho WORM (Ceph RGW Object Lock), PH-13, PH-17, `kpi-export` (phân phối).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-029.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới); CMP-LAW-15.

**Tiền điều kiện.** Báo cáo `APPROVED`; có `PERM-16-approve`.

**Kích hoạt.** Nút "Công bố" ở UI-16-12.

**Đảm bảo tối thiểu.** Nếu ký hoặc lưu lỗi, báo cáo không sang `PUBLISHED` và vẫn `APPROVED` để thử lại; không có bản công bố một nửa.

**Đảm bảo thành công.** Phiên bản báo cáo bất biến: PDF ký số, JSON ảnh chụp, `contentHash` SHA-256, `wormRef`, giữ tới hết `16.report.retention-years`.

**Luồng chính.**
1. Mai bấm "Công bố" kèm ghi chú tùy chọn (API-16-074); hệ thống kiểm Mai khác người lập và báo cáo vẫn khớp lần tổng hợp chính thức của kỳ.
2. Hệ thống chụp toàn bộ giá trị, trạng thái, độ đầy đủ, dòng truy nguồn, thuyết minh vào JSON chuẩn hóa.
3. Hệ thống dựng PDF theo mẫu và thể thức NĐ 30/2020, tính `contentHash` SHA-256 của PDF và JSON.
4. Hệ thống gọi dịch vụ ký số (khi `16.report.signing = true`), lưu PDF ký và JSON vào kho WORM.
5. Hệ thống chuyển `PUBLISHED`, ghi kiểm toán (người công bố, `contentHash`, chứng thư, `wormRef`), phát EVT-16-08; danh sách phân phối của loại báo cáo được kích hoạt (UC-16-18).

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Người công bố là người lập (bước 1).** ERR-16-005 (403): "Anh/chị là người {vai} nên không được {thao tác}." ({vai} = lập báo cáo, {thao tác} = công bố)
- **E2. Kỳ đã bị mở lại (bước 1).** ERR-16-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." ({thao tác} = công bố, {đối tượng} = kỳ {mã}, {trạng thái} = `REOPENED`)
- **E3. Dựng PDF lỗi (bước 3).** ERR-16-113: "Không dựng được tệp báo cáo: {lý do}."
- **E4. Ký số không sẵn sàng (bước 4).** ERR-16-031 (503): "Dịch vụ ký số đang gián đoạn. Báo cáo vẫn ở trạng thái Đã duyệt, thử công bố lại sau."
- **E5. Lưu WORM lỗi (bước 4).** ERR-16-114: "Không lưu được bản công bố vào kho lưu trữ. Báo cáo chưa được công bố."

**Quy tắc áp dụng.** BR-16-009, BR-16-010, BR-16-027.

**Màn hình, API.** UI-16-12; API-16-074; kịch bản TS-16-15.
:::

```{.mermaid caption="Trình tự công bố báo cáo, ký số và lưu WORM"}
sequenceDiagram
  actor Mai as Mai (TA)
  participant K as kpi-report
  participant G as Dịch vụ ký số
  participant W as Kho WORM
  participant H as PH-13, kpi-export
  Mai->>K: Công bố bc-thang-2026-10
  K->>K: Kiểm khác người lập, chụp JSON, dựng PDF, băm
  K->>G: Ký PDF
  G-->>K: PDF đã ký
  K->>W: Lưu PDF ký và JSON, khóa 10 năm
  W-->>K: wormRef
  K->>K: PUBLISHED, ghi kiểm toán
  K->>H: EVT-16-08 report.published
```

Hình cho thấy `PUBLISHED` chỉ đặt sau khi ký số và lưu WORM thành công, lỗi thì báo cáo ở `APPROVED`.

### 6.16. UC-16-16 · Đính chính và rút báo cáo đã công bố

::: dac-ta
**Mục tiêu.** Quang lập bản đính chính phiên bản 2 cho `bc-thang-2026-10` khi kỳ mở lại làm đổi số, bản 1 thành `SUPERSEDED` nhưng vẫn tải được; hoặc rút báo cáo công bố nhầm.

**Tác nhân chính.** TA (Quang duyệt, công bố, rút), TO (Chi lập đính chính).

**Tác nhân phụ.** PH-13, UC-16-28 (gói quốc gia đã nộp).

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-16-030.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Báo cáo `PUBLISHED`; lập đính chính cần `PERM-16-report`, duyệt, công bố, rút cần `PERM-16-approve`.

**Kích hoạt.** Thao tác "Đính chính" hoặc "Rút" ở UI-16-10; cờ "cần đính chính" sau khi kỳ mở lại và chốt lại (UC-16-09).

**Đảm bảo tối thiểu.** Bản đã công bố không bao giờ bị sửa tại chỗ; rút giữ nguyên tệp lưu.

**Đảm bảo thành công.** Bản mới `PUBLISHED`, bản cũ `SUPERSEDED` có dải "Đã được đính chính bởi phiên bản {n+1}"; hoặc báo cáo `WITHDRAWN`, ẩn khỏi người chỉ có `PERM-16-read`.

**Luồng chính.**
1. Chi chọn "Đính chính" ở UI-16-10 (API-16-075); hệ thống tạo phiên bản 2 ở `DRAFT` từ lần tổng hợp chính thức hiện hành, chép thuyết minh, thêm phần "Nội dung đính chính".
2. Phiên bản mới đi lại UC-16-13, 14, 15.
3. Khi công bố, hệ thống chuyển phiên bản 1 sang `SUPERSEDED`, phát EVT-16-09.
4. Hệ thống gắn cờ "cần gửi đính chính" cho gói quốc gia đã nộp từ phiên bản cũ.

**Luồng thay thế.**
- **1a. Rút.** Quang chọn "Rút" kèm lý do (API-16-076): báo cáo `WITHDRAWN`, ẩn khỏi người có `PERM-16-read` trừ TA, AU, phát EVT-16-09.

**Luồng ngoại lệ.**
- **E1. Thiếu lý do (1a).** ERR-16-007 (422): "Nhập {nội dung} (tối thiểu {n} ký tự)." ({nội dung} = lý do, {n} = 50)
- **E2. Báo cáo không ở `PUBLISHED` (bước 1).** ERR-16-006 (409): "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." ({thao tác} = đính chính hoặc rút, {đối tượng} = báo cáo {mã})
- **E3. Sửa trực tiếp bản đã công bố.** ERR-16-032 (409): "Báo cáo đã công bố không sửa được. Dùng chức năng đính chính."

**Quy tắc áp dụng.** BR-16-009, BR-16-010.

**Màn hình, API.** UI-16-10; API-16-075, 076; kịch bản TS-16-16.
:::

### 6.17. UC-16-17 · Tra cứu báo cáo và tải bằng chứng công bố

::: dac-ta
**Mục tiêu.** Hùng tìm và đọc báo cáo đã công bố cùng các phiên bản; Bảo tải gói bằng chứng của `bc-thang-2026-10` để kiểm tra nội dung chưa bị đổi.

**Tác nhân chính.** VW (Hùng), AU (Bảo), TA.

**Tác nhân phụ.** Kho WORM, PH-13 (nhận cảnh báo an ninh), SO.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-031, FR-16-036.

**Truy vết.** REQ-16; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-read`; tải bằng chứng cần `PERM-16-export` (AU, TA) và báo cáo `PUBLISHED`, `SUPERSEDED` hoặc `WITHDRAWN`.

**Kích hoạt.** Mở UI-16-10, chọn một báo cáo; nút "Tải bằng chứng".

**Đảm bảo tối thiểu.** Người chỉ có quyền xem thấy duy nhất báo cáo `PUBLISHED`, `SUPERSEDED`; TA, TO thêm các bản chưa công bố; TA, AU thêm `WITHDRAWN`.

**Đảm bảo thành công.** Người dùng thấy đúng nội dung phiên bản; gói bằng chứng kèm kết quả `verified`.

**Luồng chính.**
1. Hùng mở UI-16-10, lọc theo kỳ, loại (API-16-064); hệ thống kiểm bộ lọc và áp phạm vi trạng thái theo quyền.
2. Hệ thống trả danh sách kèm phiên bản mới nhất, người lập, người duyệt, ngày công bố, cờ "cần đính chính".
3. Hùng mở chi tiết (API-16-066, API-16-077) và xem nội dung từng phiên bản kèm lý do đính chính.
4. Bảo bấm "Tải bằng chứng" (API-16-088); hệ thống đọc bản ký từ WORM, tính lại SHA-256, so với `contentHash`, kiểm chữ ký với chứng thư lúc ký.
5. Hệ thống đóng gói ZIP gồm PDF ký, JSON ảnh chụp, `manifest.json` (băm, chữ ký, người lập, duyệt, công bố, thời điểm, mã kiểm toán PH-13) và trả liên kết có hạn.

**Luồng thay thế.**
- **4a. Băm hoặc chữ ký không khớp.** Hệ thống vẫn trả gói với `verified = false` và phát cảnh báo an ninh sang PH-13 để SO xử lý.

**Luồng ngoại lệ.**
- **E1. Bộ lọc sai (bước 1).** ERR-16-057 (400): "Tham số {trường} không hợp lệ: {lý do}." ({trường} = tên trường lọc, {lý do} = giá trị ngoài miền ở Phụ lục A)
- **E2. Không có quyền xem trạng thái hoặc báo cáo không tồn tại (bước 3).** ERR-16-001 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem." ({đối tượng} = báo cáo)
- **E3. Bằng chứng không khớp (4a).** ERR-16-124: "Bản lưu hoặc biên nhận của {mã} không khớp mã băm đã ghi. Đã báo cán bộ an toàn thông tin."

**Quy tắc áp dụng.** BR-16-009, BR-16-010.

**Màn hình, API.** UI-16-10; API-16-064, 066, 077, 088; kịch bản TS-16-17.
:::

### 6.18. UC-16-18 · Xuất báo cáo và phân phối theo danh sách

::: dac-ta
**Mục tiêu.** Chi xuất bảng chỉ tiêu kỳ `M-2026-10` ra XLSX và nhận liên kết tải 24 giờ; khi báo cáo được công bố, danh sách "Lãnh đạo UBND" do Mai lập nhận thư thông báo.

**Tác nhân chính.** TO (Chi), TA (Mai); AU xuất báo cáo đã công bố.

**Tác nhân phụ.** Kho đối tượng, PH-13 (kênh thư công vụ), người nhận.

**Mức ưu tiên.** M · Đợt 3 (phần phân phối mức S).

**FR hiện thực.** FR-16-033, FR-16-034.

**Truy vết.** REQ-16, REQ-13; BP-11 (đề nghị); hệ cũ: không có (năng lực mới); CMP-LAW-15 cho thể thức PDF.

**Tiền điều kiện.** Có `PERM-16-export` và quyền xem đối tượng xuất; kênh thư công vụ đã cấu hình ở PH-13.

**Kích hoạt.** Nút "Xuất" ở UI-16-10, 01, 02, 09; UI-16-13 tab "Phân phối"; EVT-16-08.

**Đảm bảo tối thiểu.** Không xuất vượt `16.export.max-rows` dòng; người nhận ngoài hệ thống chỉ có liên kết có hạn, không nhận tệp trừ khi `attach = PDF`.

**Đảm bảo thành công.** Tệp xuất có dòng đầu ghi kỳ, thời điểm, trạng thái báo cáo, nhãn độ đầy đủ; lần gửi có trạng thái `SENT` hoặc `FAILED` rõ ràng.

**Luồng chính.**
1. Chi bấm "Xuất", chọn XLSX (API-16-079); hệ thống kiểm quyền với đối tượng và số dòng ước tính.
2. Hệ thống tạo việc xuất `QUEUED`, chạy nền; báo cáo `PUBLISHED` định dạng PDF trả ngay bản ký đã lưu, không dựng lại.
3. Xong, hệ thống lưu tệp, tạo liên kết ký hạn `16.export.link-hours` (24 giờ), phát EVT-16-13; Chi nhận thông báo và tải (API-16-080, API-16-081).
4. Mai tạo danh sách phân phối, nhập người nhận (API-16-083); hệ thống kiểm người nhận và miền thư công vụ.
5. Khi báo cáo công bố, hệ thống chọn danh sách khớp loại, kỳ, gửi yêu cầu qua PH-13 cho từng người nhận, ghi lần gửi `PENDING`.
6. PH-13 trả kết quả; hệ thống cập nhật `SENT` hoặc `FAILED`, thử lại tối đa 3 lần (API-16-085).

**Luồng thay thế.**

**Luồng ngoại lệ.**
- **E1. Xuất vượt giới hạn (bước 1).** ERR-16-034 (422): "Dữ liệu vượt giới hạn {n} {đơn vị}. Thu hẹp bộ lọc hoặc phạm vi." ({n} = `16.export.max-rows` (mặc định 100000), {đơn vị} = dòng)
- **E2. Không đủ quyền với đối tượng (bước 1).** ERR-16-037 (403): "Anh/chị hoặc ứng dụng không được truy cập {đối tượng} này."
- **E3. Liên kết hết hạn (bước 3).** ERR-16-035 (410): "Liên kết tải đã hết hạn. Tạo lại yêu cầu xuất."
- **E4. Xuất lỗi (bước 2, chạy nền).** ERR-16-115: "Xuất {tên} không thành công: {lý do}."
- **E5. Người nhận không hợp lệ (bước 4).** ERR-16-036 (422): "Người nhận {địa chỉ} không hợp lệ hoặc không thuộc miền thư công vụ."
- **E6. Gửi lỗi (bước 6, chạy nền).** ERR-16-116: "Gửi tới {người nhận} không thành công." Hiện ở UI-16-13 tab "Lịch sử gửi".

**Quy tắc áp dụng.** BR-16-026, BR-16-027.

**Màn hình, API.** UI-16-10, 13, 01, 02, 09; API-16-079…085; kịch bản TS-16-18.
:::

```{.mermaid caption="Trình tự xuất tệp và phân phối báo cáo"}
sequenceDiagram
  actor Chi as Chi (TO)
  participant E as kpi-export
  participant O as Kho đối tượng
  participant H as PH-13
  Chi->>E: Yêu cầu xuất XLSX
  E->>E: Kiểm quyền và số dòng, tạo việc QUEUED
  E->>O: Dựng và lưu tệp, tạo liên kết 24 giờ
  E->>H: EVT-16-13 export.completed
  H-->>Chi: Thông báo kèm liên kết
  Note over E,H: Khi báo cáo PUBLISHED, E gửi thư cho danh sách phân phối qua PH-13
```

Hình cho thấy việc xuất chạy nền và người yêu cầu được báo qua PH-13.

### 6.19. UC-16-19 · Cung cấp chỉ tiêu cho hệ khác và thẻ Tổng quan

::: dac-ta
**Mục tiêu.** PH-17 đọc số chính thức của kỳ `M-2026-10` để trả lời câu hỏi của lãnh đạo; trang `/tong-quan` của Hùng có thẻ chỉ tiêu cần chú ý nhất.

**Tác nhân chính.** PH-17, HTTT được cấp (scope `kpi.read`), VW (Hùng).

**Tác nhân phụ.** Trang Tổng quan (`/tong-quan`).

**Mức ưu tiên.** M · Đợt 3 (thẻ Tổng quan mức S).

**FR hiện thực.** FR-16-035, FR-16-037.

**Truy vết.** REQ-16, REQ-17; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Bên gọi được cấp `kpi.read` cho tenant; thẻ cần tenant có ít nhất một kỳ đã tính và người dùng có `PERM-16-read`.

**Kích hoạt.** Gọi `GET /api/kpi/v1/feed/indicator-values` hoặc `/feed/reports`; trang `/tong-quan` tải thẻ.

**Đảm bảo tối thiểu.** Chỉ báo cáo `PUBLISHED` ra ngoài phân hệ khi `onlyOfficial = true`; không lộ dữ liệu tenant khác.

**Đảm bảo thành công.** Bên gọi nhận giá trị kèm trạng thái, độ đầy đủ, phiên bản định nghĩa, mã báo cáo nguồn; thẻ trỏ về UI-16-02.

**Luồng chính.**
1. PH-17 gọi `/feed/indicator-values` với `onlyOfficial = true` (API-16-086); hệ thống kiểm token, scope, tenant.
2. Hệ thống chỉ trả giá trị của kỳ `CLOSED` thuộc báo cáo `PUBLISHED`, kèm trạng thái, độ đầy đủ, phiên bản định nghĩa, mã báo cáo nguồn.
3. Khi Hùng mở `/tong-quan`, trang gọi `/cards` (API-16-089); hệ thống chọn chỉ tiêu theo tham số `16.overview.pinned-indicators` của tenant, không có thì lấy điểm tổng và chỉ tiêu `OFF_TRACK` có trọng số nhóm cao nhất.
4. Hệ thống trả giá trị kỳ tháng gần nhất đã tính, trạng thái, xu hướng, liên kết tới UI-16-02.

**Luồng thay thế.**
- **1a. Số tạm.** Với `onlyOfficial = false`, hệ thống trả thêm số tạm của kỳ chưa chốt kèm nhãn `provisional` (API-16-087 cho danh sách báo cáo).
- **3a. Chưa có kỳ nào đã tính.** Thẻ rỗng kèm liên kết "Thiết lập chỉ tiêu".

**Luồng ngoại lệ.**
- **E1. Thiếu scope hoặc tenant khác (bước 1).** ERR-16-037 (403): "Anh/chị hoặc ứng dụng không được truy cập {đối tượng} này." (thiếu scope: ERR-00-403)
- **E2. Bộ lọc sai (bước 1).** ERR-16-057 (400): "Tham số {trường} không hợp lệ: {lý do}." ({trường} = tên tham số, {lý do} = giá trị ngoài miền)
- **E3. Người dùng không có quyền (bước 3).** Thẻ không hiển thị, không có thông báo lỗi.

**Quy tắc áp dụng.** BR-16-007, BR-16-009, BR-16-026.

**Màn hình, API.** UI-16-01 (thẻ trên `/tong-quan`); API-16-086, 087, 089; kịch bản TS-16-19.
:::

### 6.20. UC-16-20 · Xem bảng điều khiển, chi tiết chỉ tiêu, so sánh hai kỳ

::: dac-ta
**Mục tiêu.** Hùng thấy điểm tổng, điểm năm nhóm, chỉ tiêu cần chú ý của `M-2026-10`; bấm một chỉ tiêu để xem chuỗi thời gian và truy tới quan sát tạo ra con số.

**Tác nhân chính.** VW (Hùng), TA (Mai), TO.

**Tác nhân phụ.** Không.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-038, FR-16-039, FR-16-040.

**Truy vết.** REQ-16; BP-11 (đề nghị); LGC-APIM-026, LGC-PAY-013, LGC-PAY-020, LGC-HUB-001…004 (gián tiếp).

**Tiền điều kiện.** Có `PERM-16-read`, có ít nhất một kỳ đã tính; xem quan sát gốc cần thêm `PERM-16-source` hoặc AU.

**Kích hoạt.** Mở `/giam-sat/chi-tieu`; bấm một chỉ tiêu; bật "So sánh".

**Đảm bảo tối thiểu.** Kỳ chưa chốt luôn có dải "Số tạm tính đến {thời điểm}, chưa chốt"; không hiện số chưa có nguồn như số 0.

**Đảm bảo thành công.** Người xem thấy trạng thái, độ đầy đủ, xu hướng, nguồn của từng số.

**Luồng chính.**
1. Hùng mở UI-16-01; hệ thống lấy lần tổng hợp chính thức (kỳ `CLOSED`) hoặc mới nhất (API-16-090).
2. Hệ thống trả điểm tổng, năm điểm nhóm với tỷ lệ phủ, đếm chỉ tiêu theo trạng thái, danh sách chỉ tiêu `OFF_TRACK`, `AT_RISK` theo trọng số, cờ thiếu nguồn, chuỗi 13 kỳ gần nhất.
3. Hùng bấm `httt-ket-noi-ty-le`; hệ thống trả định nghĩa hiệu lực, chuỗi giá trị kèm đường mục tiêu và mốc đổi phiên bản định nghĩa (API-16-091).
4. Hùng chọn kỳ rồi "Nguồn số liệu"; hệ thống trả dòng truy nguồn: quan sát (nguồn, `metricCode`, giá trị, `sourceRef`), số tay (người nhập, xác nhận, bằng chứng) (API-16-054, API-16-043).
5. Hùng bật "So sánh" chọn `M-2026-09` và `M-2026-10`; hệ thống trả hai kỳ cạnh nhau, chênh lệch tuyệt đối và tương đối, trạng thái trước và sau.

**Luồng thay thế.**
- **3a. Chỉ tiêu đã được thay.** Hiện chuỗi nối với chỉ tiêu thay thế.
- **5a. Định nghĩa đổi giữa hai kỳ.** Chỉ tiêu gắn nhãn "định nghĩa khác nhau".

**Luồng ngoại lệ.**
- **E1. Kỳ hoặc chỉ tiêu không tồn tại (bước 1, 3).** ERR-16-001 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem." ({đối tượng} = kỳ hoặc chỉ tiêu)
- **E2. Hai kỳ khác loại hoặc khoảng tra quá dài (bước 3, 5).** ERR-16-057 (400): "Tham số {trường} không hợp lệ: {lý do}." ({trường} = kỳ so sánh, {lý do} = hai kỳ phải cùng loại); ERR-16-060 (400): "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần." ({n} = 36)

**Quy tắc áp dụng.** BR-16-001, BR-16-002, BR-16-007, BR-16-016.

**Màn hình, API.** UI-16-01, UI-16-02; API-16-043, 054, 090, 091; kịch bản TS-16-20.
:::

### 6.21. UC-16-21 · So sánh liên tenant ẩn danh

::: dac-ta
**Mục tiêu.** Hà thấy phân bố `tre-gateway-p95` của kỳ `M-2026-10` giữa các tỉnh dùng cùng bản mẫu và vị trí từng tỉnh; Yến (PU) chỉ thấy mã giả.

**Tác nhân chính.** PA (Hà), PU (Yến).

**Tác nhân phụ.** Vai trò CSDL đọc liên tenant.

**Mức ưu tiên.** C · Đợt 3.

**FR hiện thực.** FR-16-041.

**Truy vết.** REQ-16, REQ-20; BP-11 (đề nghị); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-compare`; ít nhất `16.compare.min-tenants` (3) tenant có giá trị chính thức của chỉ tiêu trong kỳ, dùng cùng phiên bản mẫu không tùy biến công thức.

**Kích hoạt.** Mở UI-16-18.

**Đảm bảo tối thiểu.** Không lộ danh tính tỉnh cho PU; không lộ công thức tùy biến.

**Đảm bảo thành công.** Phân bố (trung vị, tứ phân vị, nhỏ nhất, lớn nhất) và danh sách tỉnh mang mã giả ổn định theo kỳ.

**Luồng chính.**
1. Hà chọn chỉ tiêu và kỳ (API-16-092).
2. Hệ thống đọc qua khung nhìn tổng hợp có ngoại lệ RLS chỉ cho vai trò CSDL của báo cáo liên tenant, lấy giá trị chính thức.
3. Hệ thống kiểm số tenant đạt ngưỡng.
4. Hệ thống trả phân bố và danh sách; Hà thấy mã tỉnh thật, Yến chỉ thấy mã giả.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Không đủ tenant (bước 3).** ERR-16-038 (422): "Cần ít nhất {n} tỉnh có số chính thức để so sánh." (n = 3)

**Quy tắc áp dụng.** BR-16-020.

**Màn hình, API.** UI-16-18; API-16-092; kịch bản TS-16-21.
:::

### 6.22. UC-16-22 · Theo dõi vận hành thu thập, tính toán

::: dac-ta
**Mục tiêu.** Chi thấy nguồn nào `STALE`, `FAILED` lâu nhất, lần tổng hợp nào lỗi hoặc chạy quá 10 phút; Tuấn (PO) thấy tình trạng mọi tenant; PH-13 thu chỉ số của chính PH-16.

**Tác nhân chính.** TA, TO, PO (Tuấn).

**Tác nhân phụ.** PH-13 (thu chỉ số Prometheus).

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-16-042, FR-16-058.

**Truy vết.** REQ-16, REQ-13; BP-11 (đề nghị); LGC-BUS-027 (gián tiếp).

**Tiền điều kiện.** Có `PERM-16-read`; PO xem toàn nền tảng.

**Kích hoạt.** UI-16-08 tab "Vận hành"; PH-13 thu chỉ số mỗi 30 giây.

**Đảm bảo tối thiểu.** Chỉ số gắn nhãn `tenant` nhưng không gắn mã chỉ tiêu tự do để giới hạn số chuỗi.

**Đảm bảo thành công.** Người vận hành thấy đủ nguồn, lần tổng hợp, xuất lỗi, gói quốc gia `FAILED`, độ trễ outbox; readiness sai khi mất kết nối `pg-core`.

**Luồng chính.**
1. Chi mở UI-16-08 tab "Vận hành" (API-16-093); hệ thống trả đếm nguồn theo trạng thái và nguồn `STALE`, `FAILED` lâu nhất.
2. Hệ thống trả lần tổng hợp 7 ngày gần nhất (thời gian chạy, độ đầy đủ, cờ), lần `FAILED`, lần chạy quá 10 phút (API-16-049).
3. Hệ thống trả việc xuất lỗi, gói quốc gia `FAILED`, độ trễ outbox.
4. PH-13 thu `/actuator/prometheus` và kiểm liveness, readiness.

**Luồng thay thế.**
- **1a. PO xem toàn nền tảng.** Tuấn chọn một tenant hoặc xem tất cả, hủy lần tổng hợp treo (UC-16-10).

**Luồng ngoại lệ.**
- **E1. PO chọn tenant không tồn tại (bước 1).** ERR-16-001 (404): "Không tìm thấy {đối tượng} {mã} trong phạm vi được xem." ({đối tượng} = tỉnh)

**Quy tắc áp dụng.** BR-16-030.

**Màn hình, API.** UI-16-08; API-16-049, 093; `/actuator/prometheus`; kịch bản TS-16-22.
:::

### 6.23. UC-16-23 · Tìm, xem và xuất sổ kiến trúc

::: dac-ta
**Mục tiêu.** Mai lọc thành phần `API` đang `ACTIVE` mức `NON_COMPLIANT` và xuất sổ ra XLSX cùng sơ đồ phụ thuộc của `flow-lltp`.

**Tác nhân chính.** VW, TA, TO, AU.

**Tác nhân phụ.** Kho đối tượng.

**Mức ưu tiên.** M · Đợt 3 (xuất sổ mức C).

**FR hiện thực.** FR-16-043, FR-16-049.

**Truy vết.** REQ-16; chưa có BP riêng; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-read`; xuất cần `PERM-16-export`.

**Kích hoạt.** Mở UI-16-14; nút "Xuất sổ", "Xuất sơ đồ" ở UI-16-14, UI-16-15.

**Đảm bảo tối thiểu.** Sơ đồ không quá 500 nút.

**Đảm bảo thành công.** Danh sách đúng bộ lọc; tệp xuất tải được trong hạn liên kết.

**Luồng chính.**
1. Mai mở UI-16-14, lọc loại `API`, vòng đời `ACTIVE`, mức `NON_COMPLIANT` (API-16-094); hệ thống kiểm bộ lọc.
2. Hệ thống trả danh sách kèm phiên bản hiện hành, số phụ thuộc vào và ra, mức tuân thủ, hạn miễn trừ, cờ lệch đối chiếu, `facets` cho thanh tóm tắt.
3. Mai mở chi tiết (API-16-096), bấm "Xuất sơ đồ" chọn `rootComponent`, độ sâu.
4. Hệ thống dựng đồ thị phụ thuộc (tối đa 500 nút), tạo việc xuất như UC-16-18, lưu tệp, trả liên kết có hạn, phát EVT-16-13 (API-16-079…081).

**Luồng thay thế.**
- **3a. Xuất sổ.** Mai bấm "Xuất sổ" ở UI-16-14: xuất toàn bộ danh sách theo bộ lọc.

**Luồng ngoại lệ.**
- **E1. Bộ lọc sai (bước 1).** ERR-16-057 (400): "Tham số {trường} không hợp lệ: {lý do}." ({trường} = tên trường lọc, {lý do} = giá trị ngoài miền ở Phụ lục A)
- **E2. Sơ đồ hoặc tệp quá lớn (bước 4).** ERR-16-034 (422): "Dữ liệu vượt giới hạn {n} {đơn vị}. Thu hẹp bộ lọc hoặc phạm vi." ({n} = 500, {đơn vị} = thành phần; giảm độ sâu hoặc chọn thành phần gốc khác)
- **E3. Xuất lỗi (bước 4, chạy nền).** ERR-16-115: "Xuất {tên} không thành công: {lý do}."

**Quy tắc áp dụng.** BR-16-023, BR-16-026.

**Màn hình, API.** UI-16-14, UI-16-15; API-16-079…081, 094, 096; kịch bản TS-16-23.
:::

### 6.24. UC-16-24 · Tự đăng ký, cập nhật vận hành và đối chiếu thành phần

::: dac-ta
**Mục tiêu.** Luồng `flow-lltp` triển khai ở PH-04 tự xuất hiện trong sổ với phụ thuộc, trạng thái vận hành lấy từ PH-13; mỗi tuần hệ thống đối chiếu để phát hiện thành phần thiếu, mồ côi, lệch.

**Tác nhân chính.** Hệ thống (`kpi-arch`), TA (Mai), TO (Chi).

**Tác nhân phụ.** PH-01, 02, 04, 05, 10, 14 (sự kiện), CI/GitOps (`arch.register`), PH-13 (trạng thái vận hành).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-044, FR-16-046, FR-16-048.

**Truy vết.** REQ-16, REQ-01, REQ-02, REQ-04, REQ-10, REQ-13; chưa có BP riêng; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Tenant đã kế thừa ánh xạ sự kiện mặc định; đối chiếu cần `PERM-16-arch` và phân hệ nguồn có API liệt kê đối tượng (đề nghị đồng bộ).

**Kích hoạt.** EVT-01-03, 02-05, 02-06, 04-07, 04-09, 10-01, 10-04, 05-08, 14-01 hoặc API-16-101; sự kiện trạng thái PH-13 hay kéo mỗi 15 phút; lịch Chủ nhật 03:00 hoặc nút "Đối chiếu ngay".

**Đảm bảo tối thiểu.** Trường do nguồn quản lý chỉ cập nhật từ nguồn; không xóa thành phần, chỉ `RETIRED` (BR-16-025).

**Đảm bảo thành công.** Sổ khớp phân hệ nguồn; mọi mục lệch có người xử lý hoặc lý do bỏ qua.

**Luồng chính.**
1. PH-04 phát EVT-04-07 cho `flow-lltp`; hệ thống loại trùng theo `eventId` hoặc `componentCode` + `version` + `contentHash`.
2. Hệ thống ánh xạ bản tin sang thành phần; chưa có thì tạo `origin = AUTO`, `complianceLevel = NOT_ASSESSED`; đã có thì cập nhật trường nguồn quản lý; thêm bản ghi phiên bản, ghi `dependsOn` thành phụ thuộc `AUTO`; phát EVT-16-10.
3. PH-13 báo sức khỏe đối tượng giám sát; hệ thống ánh xạ `monitorRef`, đổi `opsStatus` khi khác, ghi lịch sử, phát EVT-16-10.
4. Chủ nhật 03:00 hệ thống gọi API liệt kê của từng phân hệ nguồn, so với thành phần `AUTO` và ghi mục `MISSING`, `ORPHAN`, `MISMATCH` (API-16-111, API-16-112).
5. Chi xử lý từng mục: "Đăng ký bổ sung", "Chuyển RETIRED", "Cập nhật theo nguồn" hoặc "Bỏ qua" kèm lý do (API-16-113).

**Luồng thay thế.**
- **2a. Sự kiện ngừng (EVT-04-09, EVT-10-04).** Thành phần chuyển `RETIRED`; phụ thuộc tới nó bị gắn cờ ở đối chiếu.
- **3a. Không có `monitorRef`.** `opsStatus = UNKNOWN`, UI-16-15 gợi ý "Gắn đối tượng giám sát"; quá 2 giờ không có tin của thành phần `ACTIVE` cũng đặt `UNKNOWN`.

**Luồng ngoại lệ.**
- **E1. Sự kiện thiếu trường hoặc tham chiếu (bước 2, chạy nền).** ERR-16-119: "Không đăng ký được thành phần từ sự kiện {mã}: {lý do}."
- **E2. API đăng ký sai lược đồ (bước 1).** ERR-16-039 (422): "Thành phần {mã} thiếu trường {trường} hoặc loại không hợp lệ."
- **E3. Mất tin trạng thái (3a).** ERR-16-121: "Chưa nhận trạng thái vận hành của {mã} từ {thời điểm}."
- **E4. Phát hiện lệch (bước 4).** ERR-16-120: "{n} thành phần lệch với {phân hệ}."
- **E5. Đang có lần đối chiếu (bước 4).** ERR-16-056 (409): "Đã có lần {việc} đang chạy. Chờ lần này xong." ({việc} = đối chiếu)

**Quy tắc áp dụng.** BR-16-023, BR-16-025.

**Màn hình, API.** UI-16-14, UI-16-15; API-16-096, 101, 111…113; kịch bản TS-16-24.
:::

```{.mermaid caption="Trình tự tự đăng ký thành phần và cập nhật trạng thái vận hành"}
sequenceDiagram
  participant P as PH-04
  participant A as kpi-arch
  participant H as PH-13
  P->>A: EVT-04-07 flow.deployed
  A->>A: Loại trùng, ánh xạ, tạo hoặc cập nhật thành phần AUTO
  A->>H: EVT-16-10 arch-component.changed
  H->>A: Trạng thái sức khỏe của flow-lltp
  A->>A: Đổi opsStatus, ghi lịch sử
  A->>H: EVT-16-10
```

Hình cho thấy sổ kiến trúc do sự kiện nuôi, người chỉ bổ sung và xử lý mục lệch.

### 6.25. UC-16-25 · Khai báo, sửa thành phần, phiên bản và phụ thuộc

::: dac-ta
**Mục tiêu.** Chi khai báo thành phần `adapter-qlvb-legacy` (ADAPTER, `origin = MANUAL`) mà không phân hệ nào tự đăng ký, thêm phiên bản và phụ thuộc, rồi chuyển vòng đời `ACTIVE`.

**Tác nhân chính.** TO (Chi), TA (Mai); PA ở `COMMON`.

**Tác nhân phụ.** Không.

**Mức ưu tiên.** S · Đợt 3.

**FR hiện thực.** FR-16-045.

**Truy vết.** REQ-16; chưa có BP riêng; hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-arch`.

**Kích hoạt.** "+ Thành phần" ở UI-16-14; sửa ở UI-16-15.

**Đảm bảo tối thiểu.** Không có phụ thuộc vòng; không `RETIRED` khi còn thành phần `ACTIVE` phụ thuộc.

**Đảm bảo thành công.** Thành phần đủ trường, phiên bản, phụ thuộc hợp lệ; thay đổi phát EVT-16-10.

**Luồng chính.**
1. Chi nhập mã, tên, loại, vòng đời `PLANNED`, chủ quản, mô tả (API-16-095); hệ thống kiểm mã, loại, trường bắt buộc.
2. Chi thêm phiên bản 1.0 với ngày triển khai, môi trường (API-16-098).
3. Chi khai phụ thuộc tới `flow-lltp` (API-16-099); hệ thống kiểm đích tồn tại, không tạo vòng, không trỏ tới thành phần `RETIRED`.
4. Chi đổi vòng đời `PLANNED` sang `ACTIVE` (API-16-100); hệ thống kiểm chuyển hợp lệ, ghi kiểm toán, phát EVT-16-10.

**Luồng thay thế.**
- **1a. Sửa thành phần `AUTO`.** Chỉ sửa được trường bổ sung (chủ quản phụ, ghi chú); trường do nguồn quản lý bị khóa (API-16-097).
- **4a. Ngừng.** Chuyển `RETIRED` thay cho xóa.

**Luồng ngoại lệ.**
- **E1. Mã đã dùng (bước 1).** ERR-16-002 (409): "{Đối tượng} {mã} đã có trong tỉnh đang làm việc. Chọn mã khác hoặc mở bản đã có." ({Đối tượng} = Thành phần)
- **E2. Thiếu trường hoặc loại sai (bước 1).** ERR-16-039 (422): "Thành phần {mã} thiếu trường {trường} hoặc loại không hợp lệ."
- **E3. Sửa trường do nguồn quản lý (1a).** ERR-16-040 (409): "Trường {trường} do {phân hệ} cập nhật tự động, không sửa tay được."
- **E4. Phụ thuộc vòng hoặc tới thành phần ngừng (bước 3).** ERR-16-041 (422): "Phụ thuộc tới {mã} tạo vòng hoặc thành phần đó đã ngừng."
- **E5. Chuyển vòng đời sai (bước 4).** ERR-16-042 (422): "Không chuyển được sang {trạng thái}: còn {n} thành phần đang hoạt động phụ thuộc."

**Quy tắc áp dụng.** BR-16-023, BR-16-025.

**Màn hình, API.** UI-16-14, UI-16-15; API-16-095…100; kịch bản TS-16-25.
:::

### 6.26. UC-16-26 · Đánh giá tuân thủ, xác nhận và miễn trừ

::: dac-ta
**Mục tiêu.** Dũng lập đánh giá cho `api-cap-nhat-ho-tich` theo bộ tiêu chí, Mai xác nhận nên mức tuân thủ của thành phần đổi; khi cần, miễn trừ có hạn.

**Tác nhân chính.** SO (Dũng), TA (Mai); PA soạn bộ tiêu chí mẫu ở `COMMON`.

**Tác nhân phụ.** PH-13 (nhận EVT-16-11).

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-047.

**Truy vết.** REQ-16; chưa có BP riêng; CMP-LAW-10, CMP-LAW-11 (dự thảo); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-arch-assess`; bộ tiêu chí `ACTIVE` có tiêu chí áp dụng cho loại thành phần; người xác nhận khác người lập.

**Kích hoạt.** Nút "Đánh giá" ở UI-16-15 mở ngăn kéo UI-16-16.

**Đảm bảo tối thiểu.** Mức tuân thủ chỉ đổi khi đánh giá `CONFIRMED`; đánh giá cũ giữ phiên bản bộ tiêu chí đã dùng.

**Đảm bảo thành công.** Đánh giá `CONFIRMED`, `complianceLevel` của thành phần cập nhật, phát EVT-16-11.

**Luồng chính.**
1. Dũng mở ngăn kéo, hệ thống tải tiêu chí áp dụng; Dũng điền kết quả `PASS`, `FAIL`, `NA`, gắn bằng chứng (API-16-105, API-16-106).
2. Hệ thống kiểm mọi tiêu chí bắt buộc có kết quả và tiêu chí `FAIL` có ghi chú, tính mức đề xuất (mọi bắt buộc `PASS` thì `COMPLIANT`, có bắt buộc `FAIL` thì `NON_COMPLIANT`, còn lại `PARTIAL`).
3. Dũng bấm "Gửi" (API-16-107); đánh giá `SUBMITTED`, việc tạo cho người xác nhận.
4. Mai xem kết quả, bằng chứng, chọn "Xác nhận" (API-16-108); hệ thống kiểm Mai khác Dũng, chuyển `CONFIRMED`, đổi mức tuân thủ, phát EVT-16-11.

**Luồng thay thế.**
- **4a. Từ chối.** Mai chọn "Từ chối" kèm ý kiến (API-16-109): `REJECTED`, Dũng sửa lại.
- **4b. Miễn trừ.** Dũng đề nghị miễn trừ 90 ngày (API-16-110); Mai xác nhận; thành phần `EXEMPTED` tới hạn rồi quay về mức `CONFIRMED` gần nhất, phát EVT-16-11.
- **1a. Soạn bộ tiêu chí.** PA hoặc TA tạo phiên bản bộ tiêu chí, kiểm trùng mã, trọng số, rồi kích hoạt (API-16-102…104).

**Luồng ngoại lệ.**
- **E1. Thiếu kết quả hoặc ghi chú (bước 2).** ERR-16-043 (422): "Còn {n} tiêu chí bắt buộc chưa có kết quả hoặc tiêu chí không đạt chưa có ghi chú."
- **E2. Tự xác nhận (bước 4).** ERR-16-005 (403): "Anh/chị là người {vai} nên không được {thao tác}." ({vai} = lập đánh giá, {thao tác} = tự xác nhận)
- **E3. Miễn trừ quá hạn tối đa (4b).** ERR-16-044 (422): "Miễn trừ tối đa {n} ngày." (n = 180)
- **E4. Bộ tiêu chí sai (1a).** ERR-16-045 (422): "Bộ tiêu chí chưa hợp lệ: {lý do}."

**Quy tắc áp dụng.** BR-16-024.

**Màn hình, API.** UI-16-15, UI-16-16; API-16-102…110; kịch bản TS-16-26.
:::

```{.mermaid caption="Trình tự đánh giá tuân thủ và xác nhận bốn mắt"}
sequenceDiagram
  actor Dung as Dũng (SO lập)
  actor Mai as Mai (TA xác nhận)
  participant A as kpi-arch
  participant H as PH-13
  Dung->>A: Điền kết quả tiêu chí, gửi đánh giá
  A->>A: Kiểm bắt buộc và ghi chú, tính mức đề xuất
  Mai->>A: Mở đánh giá, bấm Xác nhận
  A->>A: Kiểm Mai khác Dũng, CONFIRMED
  A->>A: Cập nhật complianceLevel
  A->>H: EVT-16-11 arch-compliance.assessed
```

Hình cho thấy mức tuân thủ chỉ đổi sau khi người thứ hai xác nhận.

### 6.27. UC-16-27 · Quản lý mẫu gói quốc gia

::: dac-ta
**Mục tiêu.** Hà đưa lên mẫu gói `KPI_REPORT` phiên bản 1 (lược đồ và ánh xạ chỉ tiêu mẫu), kiểm bằng gói thử từ tenant `T90` rồi kích hoạt; Mai bổ sung ánh xạ riêng cho chỉ tiêu tùy biến.

**Tác nhân chính.** PA (Hà); TA (Mai) xem và khai `tenantMapping`.

**Tác nhân phụ.** Không.

**Mức ưu tiên.** M · Đợt 3.

**FR hiện thực.** FR-16-050.

**Truy vết.** REQ-16, REQ-14; BP-11 (đề nghị); CMP-LAW-11 (dự thảo); hệ cũ: không có (năng lực mới).

**Tiền điều kiện.** Có `PERM-16-admin` ở `COMMON`; khung quốc gia chưa ban hành nên mẫu là cấu hình thử nghiệm (Q16-02, Q16-03 của FRS).

**Kích hoạt.** UI-16-17 tab "Mẫu gói".

**Đảm bảo tối thiểu.** Mẫu không hợp lệ không kích hoạt được; phiên bản cũ ngừng dùng cho gói mới từ `effectiveFrom`.

**Đảm bảo thành công.** Mẫu `ACTIVE` có lược đồ JSON Schema 2020-12 và ánh xạ trỏ tới chỉ tiêu mẫu hoặc trường sổ có thật.

**Luồng chính.**
1. Hà tải lược đồ và ánh xạ (API-16-115); hệ thống kiểm lược đồ hợp lệ và ánh xạ trỏ tới chỉ tiêu mẫu `COMMON` hay trường sổ có thật.
2. Hệ thống dựng gói thử từ dữ liệu tenant kiểm thử và kiểm theo lược đồ.
3. Hà kích hoạt phiên bản (API-16-117); phiên bản cũ ngừng dùng cho gói mới từ `effectiveFrom`.

**Luồng thay thế.**
- **3a. Chỉ tiêu tùy biến.** Mai khai `tenantMapping` bổ sung ở tenant, không sửa mẫu (API-16-114, API-16-116 để xem).

**Luồng ngoại lệ.**
- **E1. Mẫu không hợp lệ (bước 1, 2).** ERR-16-047 (422): "Mẫu gói {mã} phiên bản {n} chưa hợp lệ: {lý do}."

**Quy tắc áp dụng.** BR-16-002, BR-16-021.

**Màn hình, API.** UI-16-17; API-16-114…117; kịch bản TS-16-27.
:::

### 6.28. UC-16-28 · Lập và gửi gói báo cáo chỉ tiêu, sổ kiến trúc qua PH-14

::: dac-ta
**Mục tiêu.** Mai gửi báo cáo đã công bố `bc-thang-2026-10` thành gói `gq-bc-2026-10-v1` qua PH-14 và nhận biên nhận; cùng cách cho sổ kiến trúc.

**Tác nhân chính.** TA (Mai).

**Tác nhân phụ.** PH-14 (kênh gửi, hệ giả lập khi chưa có đặc tả quốc gia), PH-13.

**Mức ưu tiên.** M · Đợt 3 (gửi sổ kiến trúc mức S).

**FR hiện thực.** FR-16-051, FR-16-052.

**Truy vết.** REQ-16, REQ-14; BP-11 (đề nghị); LGC-NGSP-004 (gián tiếp).

**Tiền điều kiện.** `16.national.enabled = true` (mặc định `false`); có `PERM-16-national`; báo cáo `PUBLISHED` loại `PERIODIC` hoặc `NATIONAL`; mẫu gói `ACTIVE` (UC-16-27).

**Kích hoạt.** Nút "Gửi quốc gia" ở UI-16-10 hoặc UI-16-17; "Gửi sổ kiến trúc" ở UI-16-17; lịch ngày 1 hằng tháng cho sổ.

**Đảm bảo tối thiểu.** Chỉ đi qua PH-14; gói trùng toàn bộ lần nộp trước không gửi lại; chỉ gửi báo cáo đã công bố.

**Đảm bảo thành công.** Gói `ACKNOWLEDGED` kèm số biên nhận, nhật ký nộp đầy đủ.

**Luồng chính.**
1. Mai bấm "Gửi quốc gia"; hệ thống kiểm chức năng đang bật và báo cáo đã công bố.
2. Hệ thống dựng gói theo mẫu từ ảnh chụp của phiên bản báo cáo, kiểm lược đồ, tính `contentHash`.
3. Hệ thống kiểm trùng theo `reportCode` + `version` + `contentHash`, tạo gói `PENDING` và hiện bản xem trước (API-16-118, API-16-120).
4. Mai bấm "Gửi" (API-16-121); hệ thống ghi outbox, giao PH-14, gói `SENDING`, phát EVT-16-12.
5. PH-14 báo đã gửi (`SENT`), sau đó trả biên nhận (`ACKNOWLEDGED`) hoặc từ chối (`REJECTED`); mỗi bước ghi nhật ký nộp.

**Luồng thay thế.**
- **1a. Gửi sổ kiến trúc.** Hệ thống chọn thành phần `ACTIVE`, `DEPRECATED`, `RETIRED` trong 12 tháng, mỗi thành phần mang `componentCode` + `version` + `contentHash`; hệ quốc gia trả kết quả từng thành phần thì thành phần bị từ chối vào hàng đối soát (UC-16-29).
- **3a. Đính chính sau khi đã nộp.** Gói mới mang `supersedesSubmission`, hệ quốc gia nhận như bản đính chính.

**Luồng ngoại lệ.**
- **E1. Gửi quốc gia đang tắt (bước 1).** ERR-16-046 (409): "Chức năng gửi quốc gia chưa được bật cho tỉnh."
- **E2. Báo cáo chưa công bố (bước 1).** ERR-16-052 (422): "Chỉ gửi được báo cáo đã công bố."
- **E3. Gói sai lược đồ (bước 2).** ERR-16-048 (422): "Gói chưa đạt mẫu {mã}: {trường} {lý do}."
- **E4. Đã nộp (bước 3, 1a).** ERR-16-049 (409): "{Nội dung} đã được nộp ngày {ngày} (mã biên nhận {biên nhận}) và chưa thay đổi." ({Nội dung} = Báo cáo {mã} phiên bản {n} hoặc Sổ kiến trúc)
- **E5. Hệ quốc gia từ chối (bước 5).** ERR-16-117: "Hệ quốc gia từ chối gói: {mã lý do} {mô tả}."
- **E6. Lỗi kênh PH-14 (bước 4, chạy nền).** ERR-16-118: "Gửi qua PH-14 không thành công, sẽ thử lại lần {n}."

**Quy tắc áp dụng.** BR-16-021, BR-16-022, BR-16-024.

**Màn hình, API.** UI-16-10, UI-16-17; API-16-118, 120, 121; kịch bản TS-16-28.
:::

```{.mermaid caption="Trình tự lập và gửi gói báo cáo qua PH-14"}
sequenceDiagram
  actor Mai as Mai (TA)
  participant N as kpi-national
  participant P as PH-14
  participant Q as Hệ quốc gia
  Mai->>N: Gửi quốc gia, chọn báo cáo đã công bố
  N->>N: Dựng gói theo mẫu, kiểm lược đồ, tính contentHash
  N-->>Mai: Bản xem trước, kiểm trùng
  Mai->>N: Bấm Gửi
  N->>P: Giao gói qua outbox (SENDING)
  P->>Q: Gửi gói
  Q-->>P: Biên nhận hoặc từ chối
  P->>N: Trạng thái và biên nhận (UC-16-29)
```

Hình cho thấy PH-16 không gọi thẳng hệ quốc gia: gói đi qua outbox tới PH-14, kết quả quay về qua API nội bộ.

### 6.29. UC-16-29 · Nhật ký nộp, biên nhận, gửi lại và đối soát

::: dac-ta
**Mục tiêu.** Mỗi lần giao, phản hồi, biên nhận của gói đều có dòng nhật ký làm bằng chứng nộp; gói lỗi tự gửi lại; Mai đối soát thấy báo cáo đã nộp nào còn bản đính chính chưa nộp.

**Tác nhân chính.** TA (Mai), AU (Bảo xem).

**Tác nhân phụ.** PH-14 (trả biên nhận qua API nội bộ).

**Mức ưu tiên.** M · Đợt 3 (đối soát mức C).

**FR hiện thực.** FR-16-053, FR-16-054.

**Truy vết.** REQ-16, REQ-14; BP-11 (đề nghị); LGC-NGSP-004 (gián tiếp).

**Tiền điều kiện.** Gói đã được lập (UC-16-28); gửi lại cần `PERM-16-national`; đối soát cần ít nhất một gói `ACKNOWLEDGED`.

**Kích hoạt.** Mỗi lần gói đổi trạng thái; nút "Gửi lại", "Đối soát" ở UI-16-17; PH-14 gọi API-16-124.

**Đảm bảo tối thiểu.** Nhật ký chỉ thêm, giữ cùng hạn với báo cáo (BR-16-022); biên nhận lệch mã băm không làm gói thành `ACKNOWLEDGED`.

**Đảm bảo thành công.** Gói có trạng thái cuối rõ ràng và đủ nhật ký; kết quả đối soát liệt kê các mục lệch.

**Luồng chính.**
1. Hệ thống ghi dòng nhật ký cho mỗi lần giao, phản hồi, biên nhận (API-16-123).
2. PH-14 gọi API-16-124 với biên nhận; hệ thống kiểm `contentHash` khớp gói đã gửi, chuyển `ACKNOWLEDGED`, lưu `receiptNo`.
3. Gói `FAILED` được tự gửi lại giãn cách 5, 15, 45, 135 phút tới `16.national.retry-max` (5) lần; quá số lần thì tạo việc cho Mai.
4. Mai bấm "Gửi lại" gói `FAILED` còn lượt (API-16-122); hệ thống giao lại với cùng `contentHash`.
5. Mai bấm "Đối soát" (API-16-125, API-16-126); hệ thống so gói `ACKNOWLEDGED` gần nhất với sổ hiện hành, báo cáo đã nộp với phiên bản hiện hành, chỉ tiêu có đối tượng đếm trong sổ với số tính từ sổ, ghi mục lệch.

**Luồng thay thế.**
- **4a. Gói `REJECTED`.** Không gửi lại được; Mai sửa nguồn rồi lập gói mới ở UC-16-28.
- **5a.** Bảo (AU) xem nhật ký, danh sách gói (API-16-119, API-16-120) nhưng không gửi lại.

**Luồng ngoại lệ.**
- **E1. Gửi lại không cho phép (bước 4).** ERR-16-050 (409): "Gói {mã} đang ở trạng thái {trạng thái} hoặc đã gửi lại tối đa {n} lần."
- **E2. Biên nhận không khớp mã băm (bước 2).** ERR-16-124: "Bản lưu hoặc biên nhận của {mã} không khớp mã băm đã ghi. Đã báo cán bộ an toàn thông tin." Gói giữ `SENT`.
- **E3. Kênh lỗi (bước 3, chạy nền).** ERR-16-118: "Gửi qua PH-14 không thành công, sẽ thử lại lần {n}."
- **E4. Đang có lần đối soát (bước 5).** ERR-16-056 (409): "Đã có lần {việc} đang chạy. Chờ lần này xong." ({việc} = đối soát)

**Quy tắc áp dụng.** BR-16-021, BR-16-022.

**Màn hình, API.** UI-16-17; API-16-119, 120, 122…126; kịch bản TS-16-29.
:::

```{.mermaid caption="Trình tự nhận biên nhận và gửi lại gói"}
sequenceDiagram
  participant P as PH-14
  participant N as kpi-national
  participant L as Nhật ký nộp
  actor Mai as Mai (TA)
  P->>N: POST internal/national/receipts
  N->>N: So contentHash của biên nhận với gói đã gửi
  N->>L: Ghi dòng nhật ký, chuyển ACKNOWLEDGED
  N->>N: Gói FAILED, tự gửi lại theo lịch giãn cách
  Mai->>N: Gửi lại khi còn lượt
```

Hình cho thấy biên nhận chỉ được nhận khi mã băm khớp và mọi bước đều có dấu vết trong nhật ký chỉ thêm.

### 6.30. UC-16-30 · Tham số, lưu giữ dữ liệu và nhật ký kiểm toán

::: dac-ta
**Mục tiêu.** Mai đổi `16.period.close-day` từ 5 sang 7 trong trần cho phép; hệ thống dọn dữ liệu quá hạn mỗi đêm nhưng giữ báo cáo công bố 10 năm; Bảo tra mọi thao tác của PH-16.

**Tác nhân chính.** TA (Mai), AU (Bảo), PA (Hà), PU (Yến).

**Tác nhân phụ.** PH-13 (nhận kiểm toán), kho WORM.

**Mức ưu tiên.** M · Đợt 3 (lưu giữ mức S).

**FR hiện thực.** FR-16-055, FR-16-056, FR-16-057.

**Truy vết.** REQ-16, REQ-13; BP-11 (đề nghị); CMP-LAW-16.

**Tiền điều kiện.** Sửa tham số cần `PERM-16-config`; tra kiểm toán cần `PERM-16-audit-read`.

**Kích hoạt.** UI-16-19; lịch dọn 02:30 hằng ngày; mở UI-16-20.

**Đảm bảo tối thiểu.** Không khóa tham số nào vượt trần nền tảng; `16.report.retention-years` không nhỏ hơn 10; không mất bản ghi kiểm toán khi PH-16 khởi động lại.

**Đảm bảo thành công.** Tham số áp dụng trong 60 giây; dữ liệu quá hạn được dọn, báo cáo công bố còn nguyên; kiểm toán chuyển sang PH-13 đúng thứ tự.

**Luồng chính.**
1. Mai sửa tham số ở UI-16-19 (API-16-127, API-16-128); hệ thống kiểm khóa có trong danh mục, kiểu, miền, trần, lưu và phát tín hiệu làm mới.
2. Lúc 02:30 hệ thống tách phân vùng quan sát quá `16.observation.retention-months` (36 tháng) có kỳ `CLOSED`, xóa tệp xuất `EXPIRED` quá 7 ngày và bản tin bị loại quá 13 tháng (API-16-130 xem tình trạng).
3. Báo cáo `PUBLISHED`, `SUPERSEDED`, `WITHDRAWN` và nhật ký nộp giữ tới hết hạn lưu; kho WORM khóa đến hạn, không có lệnh xóa sớm.
4. Mỗi thao tác ghi sinh bản ghi kiểm toán vào outbox cùng giao dịch; bộ chuyển gửi sang PH-13 theo thứ tự.
5. Bảo tra theo người, thao tác, đối tượng ở UI-16-20 (API-16-129); hệ thống gọi API kiểm toán của PH-13 lọc `module = PH-16`.

**Luồng thay thế.**
- **1a. Khôi phục mặc định.** Mai chọn "Khôi phục mặc định" cho một khóa: lấy giá trị cấp `PLATFORM`.
- **2a. Phân vùng còn kỳ `REOPENED`.** Hoãn dọn tới khi kỳ chốt lại.
- **5a. PU tra liên tenant.** Yến tra mọi tenant; AU, TA chỉ tenant mình.

**Luồng ngoại lệ.**
- **E1. Giá trị ngoài miền hoặc vượt trần (bước 1).** ERR-16-051 (422): "Giá trị {giá trị} của {khóa} nằm ngoài miền cho phép ({miền})."
- **E2. Sửa đồng thời (bước 1).** ERR-16-004 (409): "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi."
- **E3. Khoảng tra quá 12 tháng (bước 5).** ERR-16-060 (400): "Khoảng thời gian tra cứu tối đa {n} tháng mỗi lần." ({n} = 12)
- **E4. Dọn dữ liệu lỗi (bước 2, chạy nền).** ERR-16-122: "Lần dọn dữ liệu ngày {ngày} lỗi: {lý do}."
- **E5. Kiểm toán tồn đọng (bước 4, chạy nền).** ERR-16-123: "Kiểm toán PH-16 tồn {n} bản ghi chưa chuyển." Hiện ở PH-13 khi tồn quá 5 phút.

**Quy tắc áp dụng.** BR-16-004, BR-16-010, BR-16-031, BR-16-032.

**Màn hình, API.** UI-16-19, UI-16-20; API-16-127…130; kịch bản TS-16-30.
:::

## 7. Luồng phụ dùng chung

Năm luồng dưới được nhiều use case dùng lại; use case chỉ ghi "theo LP-16-nn" ở chỗ cần, không chép lại.

| Mã | Luồng phụ | Nội dung | Dùng ở |
|---|---|---|---|
| LP-16-01 | Bốn mắt | Hệ thống so định danh người thao tác với người lập, gửi, nhập; trùng thì từ chối bằng ERR-16-005 (403), kiểm toán ghi lần từ chối; việc cho người thứ hai đi qua PH-18 và "Việc của tôi" (FR-00-070, 071) | UC-16-03, 08, 14, 15, 16, 26 |
| LP-16-02 | Kỳ đã chốt | Mọi thao tác ghi số (nhập tay, tính lại, quan sát) vào kỳ `CLOSED` bị chặn bằng ERR-16-022 hoặc lưu làm số trễ (ERR-16-104); mở lại kỳ có lý do ở UC-16-09 | UC-16-06, 08, 09, 10 |
| LP-16-03 | Fail-soft thiếu nguồn | Thiếu số thì chỉ tiêu `PARTIAL` hoặc `NO_DATA` kèm cờ, không nội suy; báo cáo chính thức chỉ chặn khi chỉ tiêu bắt buộc `NO_DATA` (ERR-16-029) | UC-16-05, 10, 11, 13, 14 |
| LP-16-04 | Việc nền và liên kết hạn | Xuất, phân phối, gửi quốc gia chạy nền, báo kết quả qua EVT-16-12, EVT-16-13 và thông báo PH-13; liên kết hết hạn sau `16.export.link-hours` | UC-16-18, 23, 28 |
| LP-16-05 | Kiểm toán và sự kiện qua outbox | Mỗi thao tác ghi sinh bản ghi kiểm toán và sự kiện trong cùng giao dịch; bộ chuyển gửi theo thứ tự sang PH-13 và bên tiêu thụ; tồn đọng quá 5 phút báo ERR-16-123 | Mọi use case có thao tác ghi, UC-16-30 |

: Luồng phụ dùng chung

## 8. Tổng hợp mã mới và đối chiếu

### 8.1. Mã đã dùng và độ phủ

Tài liệu không tạo mã `FR`, `API`, `ERR`, `EVT`, `UI`, `BR` mới: mọi mã lấy từ FRS. Mã mới duy nhất là `UC-16-01…30` và `LP-16-01…05`; kịch bản `TS-16-nn` ở mục "Màn hình, API" là chỗ giữ, đánh số theo UC và sẽ được xác nhận khi viết D05-02-PH16.

Dải đã dùng: UC-16-01…30; LP-16-01…05; FR-16-001…058 (cả 58 FR thuộc ít nhất một UC, bảng 5.4); ERR-16-001…061 và 101…125 với câu thông báo nguyên văn FRS §9.2 kèm giá trị tham số (ERR-00-401, 403, 428 dùng khung chung); EVT-16-01…14; UI-16-01…20; API-16-001…130 (bảng 5.2).

### 8.2. Độ phủ và mức ưu tiên

Số FR theo mức do FRS đếm (37 M, 17 S, 4 C) khác số tạm ở brief chung (40, 15, 3); tài liệu dùng số của FRS. FR mức C là FR-16-032 (UC-16-13), 041 (UC-16-21), 049 (UC-16-23), 054 (UC-16-29). Mỗi UC có FR, UI (trừ FR-16-035, 058 không có màn hình, đã ghi ở bảng 5.2) và API (trừ FR-16-010, 046, 058 tiêu thụ sự kiện hoặc chỉ số). UC có từ ba thành phần hoặc bốn mắt có sơ đồ trình tự: UC-16-03, 04, 05, 06, 08, 10, 14, 15, 18, 24, 26, 28, 29.

## 9. Câu hỏi mở

Các câu hỏi phát sinh khi viết use case, đánh số Q16-45…49 theo dải của UC; câu hỏi của FRS (Q16-01…19) vẫn còn hiệu lực và không nhắc lại. Cột "Tạm dùng" là phương án tài liệu này đang theo.

| Mã | Câu hỏi | Tạm dùng |
|---|---|---|
| Q16-45 | Báo cáo chính thức do lãnh đạo UBND hay sở ký: use case có cần một bước phê duyệt thứ hai của lãnh đạo sau TA (liên quan Q16-04 của FRS) | TA duyệt và công bố (UC-16-14, 15), ký số bằng chứng thư cơ quan; lãnh đạo xem bằng VW |
| Q16-46 | Khi mở lại kỳ (ERR-16-026), báo cáo `IN_REVIEW`, `APPROVED` được trả về nháp bằng thao tác nào; FRS chưa có hành động cho báo cáo `APPROVED` | Đã trả lời ở FRS 0.2 (FR-16-028): "Trả về soạn" qua API-16-073, `APPROVED` → `CHANGES_REQUESTED` → `DRAFT` | Đóng |
| Q16-47 | Cấu hình "ghim lên Tổng quan" (FR-16-037) nằm ở đâu: màn nào, tham số hay API nào | Đã trả lời ở FRS 0.2 (FR-16-037, mục 8.2): tham số tenant `16.overview.pinned-indicators` | Đóng |
| Q16-48 | Số ký hiệu, nơi nhận của PDF báo cáo (BR-16-027, Q16-17 của FRS) nhập ở bước lập hay bước công bố | Đã trả lời ở FRS 0.2 (FR-16-027, 028): nhập ở UC-16-13, bắt buộc khi gửi duyệt (ERR-16-061) | Đóng |
| Q16-49 | Gói quốc gia `REJECTED` vì sai số liệu thì sửa thế nào: đính chính báo cáo (UC-16-16) rồi gửi lại, hay chỉ lập gói mới từ cùng báo cáo | Sai do mẫu hoặc ánh xạ: gói mới từ cùng báo cáo; sai do số liệu: đính chính báo cáo trước |

: Câu hỏi mở của tập use case PH-16

## Phụ lục A. Đề nghị đồng bộ cho FRS

Khi viết use case phát hiện chỗ FRS thiếu hoặc lệch; tập này không sửa FRS, các dòng dưới dồn vào Phụ lục C của FRS ở bản kế tiếp. Dòng A-01…A-07 là lệch giữa câu thông báo của từng FR và FRS §9.2 (use case dùng câu §9.2); A-08…A-12 là thiếu hụt. Cột "Kết quả" ghi quyết định của FRS 0.2 (Phụ lục C của FRS, ngày 26/11/2026).

| Mã | Vị trí ở FRS | Đề nghị | Kết quả |
|---|---|---|---|
| A-01 | §9.2 ERR-16-057 | Một mã mà FR dùng cho nhiều câu (lọc, khoảng tra tối đa 36 tháng ở FR-016, 039, đọc bù tối đa 12 tháng ở FR-011, kiểm toán tối đa 12 tháng ở FR-056, hai kỳ khác loại ở FR-040, tham số `kpi.read` ở FR-035). Đề nghị thêm các biến thể vào §9.2 hoặc tách một mã mới cho "khoảng thời gian ngoài miền" | Đã hấp thụ (HT-01): khoảng thời gian vượt tối đa tách thành ERR-16-060 |
| A-02 | §9.2 ERR-16-003 | Câu chỉ nói về mã chỉ tiêu nhưng FR-007 (mã nhóm), FR-009 (mã nguồn), FR-045 (mã thành phần) cũng dùng. Đề nghị câu chung "Mã {đối tượng} chỉ gồm chữ thường, số và gạch nối, 3 đến 63 ký tự." và thêm câu cho mã nhóm lạ | Đã hấp thụ (HT-02): câu chung "{Trường} chưa hợp lệ: {yêu cầu}." |
| A-03 | §9.2 ERR-16-005 | Một câu "người lập hoặc gửi nên không được tự duyệt" nhưng FR-005, 015, 029, 047 có bốn câu khác nhau (soạn, nhập, công bố, lập đánh giá). Đề nghị tham số hóa theo vai ("người {vai}") | Đã hấp thụ (HT-03): tham số `{vai}`, `{thao tác}`; không thuộc vai trò xác nhận tách ERR-16-059 |
| A-04 | §9.2 ERR-16-006, 007 | FR dùng câu theo đối tượng và ngưỡng `n` khác nhau (20 ký tự cho ý kiến, lý do; 50 ký tự khi mở lại kỳ, đính chính, rút). Đề nghị ghi bảng ngưỡng `n` theo FR vào §9.2 | Đã hấp thụ (HT-04): bảng ngưỡng `{n}` ở FRS §9.2 |
| A-05 | §9.2 ERR-16-034 | FR-049 dùng cùng mã cho "sơ đồ vượt 500 thành phần" nhưng câu §9.2 nói "dòng". Đề nghị thêm câu cho sơ đồ | Đã hấp thụ (HT-05): tham số `{đơn vị}` |
| A-06 | §9.2 ERR-16-049 | FR-052 dùng "Sổ kiến trúc không thay đổi từ lần nộp {ngày}." khác câu §9.2. Đề nghị thêm biến thể | Đã hấp thụ (HT-06): tham số `{Nội dung}`, `{biên nhận}` |
| A-07 | §9.2 ERR-16-056 | Câu nói "đối chiếu" nhưng FR-054 là đối soát gói quốc gia. Đề nghị thêm câu "Đã có lần đối soát đang chạy" | Đã hấp thụ (HT-07): tham số `{việc}` |
| A-08 | FR-028, API-16-073 | ERR-16-026 yêu cầu "trả báo cáo về nháp" nhưng chỉ có "Yêu cầu sửa" cho báo cáo `IN_REVIEW`; báo cáo `APPROVED` (ví dụ ký số lỗi, ERR-16-031) chưa có hành động quay về `DRAFT` (Q16-46) | Đã hấp thụ (HT-08): "Trả về soạn" qua API-16-073 |
| A-09 | FR-037, §8 tham số | Cấu hình "ghim lên Tổng quan" chưa có tham số hay API (Q16-47) | Đã hấp thụ (HT-09): `16.overview.pinned-indicators` |
| A-10 | FR-026, 029, API-16-067 | BR-16-027 cần số ký hiệu, nơi nhận nhưng chưa có trường nhập trong báo cáo (Q16-48) | Đã hấp thụ (HT-10): `documentNumber`, `recipientsNote`, ERR-16-061 |
| A-11 | FR-016, §3.2 | Nhánh "Nhận giá trị mới" cần `PERM-16-run` nhưng FR-016 chỉ nêu `PERM-16-source`. Đề nghị ghi vào ma trận quyền | Đã hấp thụ (HT-11): ghi chú `PERM-16-run` ở FRS §3.2 |
| A-12 | §9.3 sự kiện | Chưa có sự kiện khi kỳ `CLOSED` hoặc `REOPENED` để PH-13, PH-17 biết số chính thức sẵn sàng hay bị đổi. Đề nghị thêm EVT-16-14 `period.state-changed` | Đã hấp thụ (HT-12): EVT-16-14 |

: Đề nghị đồng bộ cho FRS PH-16

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-26 | Claude | Bản đầu: 30 use case phủ 58 FR, 13 sơ đồ trình tự, năm luồng phụ, câu hỏi mở Q16-45…49, 12 đề nghị đồng bộ cho FRS |
| 0.2 | 2026-11-26 | Claude | Đồng bộ với FRS 0.2: câu thông báo theo câu chuẩn có tham số của FRS §9.2 kèm giá trị biến; ERR-16-059 (UC-16-08), ERR-16-060 (UC-16-07, 20, 30), ERR-16-061 và luồng "Trả về soạn" (UC-16-14), EVT-16-14 (UC-16-09), ERR-16-058 ở quy ước chung, `16.overview.pinned-indicators` (UC-16-19), số ký hiệu và nơi nhận (UC-16-13); đóng Q16-46…48; ghi kết quả hấp thụ A-01…A-12 |

: Lịch sử phiên bản
