---
ma_tai_lieu: D02-04-PH19
ten: Đặc tả use case phân hệ PH-19 Thanh toán điện tử
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Nhóm phân tích nghiệp vụ, đội phát triển dh-payment và dh-console, đội kiểm thử, Sở Tài chính tỉnh thí điểm, hội đồng thẩm định
phan_he: PH-19
nguoi_lap: Nhóm phân hệ PH-19
---

# D02-04-PH19 · Đặc tả use case phân hệ PH-19 Thanh toán điện tử

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 29 use case UC-19-01…29 của phân hệ Thanh toán điện tử, phủ toàn bộ 69 yêu cầu chức năng của [FRS D02-03-PH19](../frs/D02-03-PH19-frs-thanh-toan.md): khai báo và kích hoạt nhà cung cấp (PayGov), quản lý dịch vụ, đối tác, tạo giao dịch, nhận kết quả, hủy và hết hạn, truy vấn, hoàn tiền, đối soát hằng ngày, xử lý chênh lệch, tra cứu, nhật ký, dashboard, báo cáo, thông báo cho HTTT đối tác, cấu hình theo tenant, di trú từ hệ Payment cũ. Mỗi use case ghi rõ ai làm, hệ thống phản hồi thế nào ở từng bước, những gì hệ thống luôn bảo đảm kể cả khi lỗi, và mã lỗi trả về. Sáu use case có dòng tiền hoặc trao đổi với nhà cung cấp (UC-19-11, 13, 18, 19, 20, 29) có sơ đồ tuần tự.

Căn cứ pháp lý và chuẩn kỹ thuật dùng chung như FRS §1.6: Luật Giao dịch điện tử 2023, NĐ 278/2025 về kết nối chia sẻ dữ liệu, NĐ 331/2026 và TCVN 14423:2026 về bảo đảm an toàn hệ thống thông tin theo cấp độ (Datahub cấp độ 3), Luật Bảo vệ dữ liệu cá nhân 91/2025 và NĐ 356/2025; các văn bản riêng của thanh toán theo D02-01-PH19 §2.1. Các chi tiết kỹ thuật của PayGov là giả định, cần đối chiếu tài liệu kết nối do Văn phòng Chính phủ cấp (OQ-19-01…08).

## 1. Mục đích và phạm vi

### 1.1. Mục đích

Tài liệu nối FRS (hệ thống phải làm gì) với [D03-06-PH19 Màn hình](../../03-thiet-ke/uiux/D03-06-PH19-man-hinh-thanh-toan.md), [D03-02-PH19 SDD](../../03-thiet-ke/sdd/D03-02-PH19-sdd-thanh-toan.md) và [D03-04-PH19 API](../../03-thiet-ke/api/D03-04-PH19-api-thanh-toan.md) (hệ thống làm thế nào). Đội phát triển dùng luồng chính, luồng ngoại lệ để biết thứ tự gọi màn, gọi API và mã lỗi phải trả; đội kiểm thử dùng từng luồng làm khung kịch bản TS-19-nn ở [D05-02-PH19](../../05-kiem-thu/test-case/D05-02-PH19-test-case.md).

### 1.2. Phạm vi

Toàn bộ FR-19-001…069. Chức năng dùng chung FR-00 (đăng nhập, phân quyền, kiểm toán chung, thông báo, hộp "Việc của tôi") không đặc tả lại. Hành vi của PH-03 (APISIX), PH-07 (danh mục), PH-09 (che dữ liệu), PH-12 (Keycloak), PH-13 (giám sát, kiểm toán), PH-20 (quản trị tenant) chỉ mô tả ở mức tương tác.

### 1.3. Tài liệu liên quan

| Tài liệu | Lý do tham chiếu |
|---|---|
| [D00-01 Thuật ngữ và quy ước](../../00-chung/D00-01-thuat-ngu-quy-uoc.md) | Hệ mã truy vết, kiểu T-* |
| [D02-01-PH19 BRD](../brd/D02-01-PH19-brd-thanh-toan.md) | Quy trình TO-BE BP-91…96, REQ-91…99 |
| [D02-03-PH19-00 Khung truy vết](../frs/D02-03-PH19-00-khung-truy-vet.md) | Cấp mã UC, US, máy trạng thái, vai trò, quyền |
| [D02-03-PH19 FRS](../frs/D02-03-PH19-frs-thanh-toan.md) | FR-19, BR-19, NFR-19, tham số `19.*`, ánh xạ GĐ-03 |
| [D02-08 Ma trận phân quyền](../D02-08-ma-tran-phan-quyen.md) | Vai trò, `PERM-19-*` |
| [D03-10 Thiết kế đa tenant](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md) | RLS, xác định tenant |
| ADR-040…049 | Quyết định kiến trúc PH-19 |

## 2. Quy ước đọc đặc tả

### 2.1. Mẫu đặc tả một use case

| Mục | Ý nghĩa |
|---|---|
| Mã, tên | `UC-19-nn`, tên bắt đầu bằng động từ |
| Mục tiêu | Kết quả nghiệp vụ tác nhân chính muốn đạt |
| Tác nhân chính, phụ | Người hoặc hệ thống khởi xướng; người hoặc hệ thống tham gia, nhận kết quả |
| Mức ưu tiên, phát hành | Mức cao nhất của các FR hiện thực; MVP, Đ2b hoặc Sau theo FRS §9.3 |
| FR hiện thực | FR mà use case hiện thực |
| Tiền điều kiện, điều kiện kích hoạt | Điều phải đúng trước khi bắt đầu; sự kiện làm use case bắt đầu |
| Đảm bảo tối thiểu | Điều hệ thống luôn giữ kể cả khi thất bại giữa chừng |
| Đảm bảo thành công | Trạng thái hệ thống sau khi kết thúc thành công |
| Luồng chính | Kịch bản thành công điển hình, đánh số bước, ghi màn `UI-19-nn` và API `API-19-nnn` |
| Luồng thay thế | Nhánh hợp lệ khác, đánh số theo bước rẽ (`3a`) |
| Luồng ngoại lệ | `E1`, `E2`…, mã lỗi `ERR-19-nnn` |
| Quy tắc, tần suất | `BR-19-nnn`, `NFR-19-nnn`; ước lượng khối lượng theo giả định GĐ-06 (tỉnh thí điểm quy mô vừa) |

### 2.2. Quy ước trong luồng

"Hệ thống" là dịch vụ `dh-payment` cùng giao diện `dh-console`. API quản trị có tiền tố `/api/payment/v1`, API đối tác `/api/payment-partner/v1`, API callback `/api/payment-callback/v1`. API tạo mới nhận `Idempotency-Key` (bắt buộc với API đối tác); API sửa, chuyển trạng thái cần `If-Match`; lỗi theo RFC 9457 với `code` là `ERR-19-nnn`. Mọi thao tác ghi sinh kiểm toán theo FR-19-053; mọi truy vấn chạy dưới RLS theo tenant. Các luồng không nhắc lại hai điều này ở từng bước.

Dữ liệu ví dụ là giả lập (không có dữ liệu thật, theo chỉ đạo ngày 25/11/2026): tenant `T68`; NCC `PAYGOV-T68` "Nền tảng thanh toán Cổng DVCQG"; đối tác `MCDT-T68` "Hệ thống thông tin giải quyết thủ tục hành chính tỉnh"; dịch vụ `LP-LLTP` "Lệ phí cấp Phiếu lý lịch tư pháp" 200.000 đ; mã giao dịch `T68261126K7M2Q9XW4P`; mã hồ sơ của đối tác `000.00.12.H68-261126-0042`. Người dùng giả lập:

| Ký hiệu | Vai trò | Người giả lập |
|---|---|---|
| ADM | Quản trị thanh toán (`ROLE-PAYMENT_ADMIN`) | Nguyễn Văn An |
| APR | Người phê duyệt (`ROLE-PAYMENT_APPROVER`) | Trần Thị Bình; Ngô Thị Lan (cấp 2) |
| ACC | Kế toán (`ROLE-PAYMENT_ACCOUNTANT`) | Lê Văn Cường; Bùi Văn Minh |
| OPR | Cán bộ tra cứu, vận hành (`ROLE-PAYMENT_OPERATOR`) | Phạm Thu Dung |
| AUD | Kiểm toán viên (`ROLE-PAYMENT_AUDITOR`) | Vũ Thị Hà |
| SEC | Cán bộ ATTT | Hoàng Minh Đức |
| TEN | Quản trị tenant | Đỗ Quang Khải |
| PTN | HTTT đối tác (client máy-máy) | `mcdt-t68-prod` |

## 3. Tác nhân

| Tác nhân | Loại | Tham gia use case |
|---|---|---|
| Quản trị thanh toán | Người | UC-19-01…10, 28, 29 |
| Người phê duyệt | Người | UC-19-03, 04, 09, 18, 20, 21, 29 (quyết định đề nghị, không tự lập) |
| Kế toán | Người | UC-19-17…22, 26, 29 |
| Cán bộ tra cứu | Người | UC-19-14, 16, 22…25, 27 |
| Kiểm toán viên | Người | UC-19-22, 24, 26 (chỉ đọc) |
| Cán bộ ATTT | Người | UC-19-01, 06, 10 (giám sát bí mật, khóa) |
| Người nộp tiền | Người (công dân, doanh nghiệp) | UC-19-12 |
| HTTT đối tác | Hệ thống | UC-19-11, 14, 15, 17, 21, 27 |
| PayGov (nhà cung cấp) | Hệ thống | UC-19-02, 11…14, 16, 18, 19 |
| Hệ Payment cũ | Hệ thống | UC-19-29 |
| PH-03, PH-07, PH-12, PH-13, PH-20 | Hệ thống nội bộ | Tương tác theo FRS §10.1 |
| Bộ lập lịch của `dh-payment` | Hệ thống | UC-19-06, 14, 16, 19, 27 |

## 4. Sơ đồ use case tổng

```mermaid
flowchart LR
  ADM([Quản trị thanh toán])
  APR([Người phê duyệt])
  ACC([Kế toán])
  OPR([Cán bộ tra cứu])
  AUD([Kiểm toán viên])
  PAY([Người nộp tiền])
  PTN[[HTTT đối tác]]
  PG[[PayGov]]
  OLD[[Hệ Payment cũ]]
  subgraph NCC["Nhà cung cấp, dịch vụ, đối tác"]
    U01(UC-19-01 Khai báo NCC)
    U02(UC-19-02 Kiểm tra, giao dịch thử)
    U03(UC-19-03 Kích hoạt NCC)
    U04(UC-19-04 Tạm dừng, ngừng NCC)
    U05(UC-19-05 Tra cứu, cập nhật NCC)
    U06(UC-19-06 Sức khỏe, xoay khóa)
    U07(UC-19-07 Nhóm dịch vụ)
    U08(UC-19-08 Dịch vụ)
    U09(UC-19-09 Đối tác)
    U10(UC-19-10 Client, hạn mức, webhook)
  end
  subgraph GD["Giao dịch"]
    U11(UC-19-11 Tạo giao dịch)
    U12(UC-19-12 Thanh toán, quay về)
    U13(UC-19-13 Nhận IPN)
    U14(UC-19-14 Hủy, hết hạn)
    U15(UC-19-15 Truy vấn trạng thái)
    U16(UC-19-16 Đồng bộ, xử lý lại IPN)
    U27(UC-19-27 Thông báo đối tác)
  end
  subgraph TC["Hoàn tiền, đối soát"]
    U17(UC-19-17 Lập yêu cầu hoàn)
    U18(UC-19-18 Duyệt, thực thi hoàn)
    U19(UC-19-19 Đối soát ngày)
    U20(UC-19-20 Xử lý chênh lệch)
    U21(UC-19-21 Chốt phiên, biên bản)
  end
  subgraph QL["Tra cứu, giám sát, quản trị"]
    U22(UC-19-22 Tra cứu, xuất)
    U23(UC-19-23 Chi tiết giao dịch)
    U24(UC-19-24 Nhật ký)
    U25(UC-19-25 Dashboard)
    U26(UC-19-26 Báo cáo)
    U28(UC-19-28 Cấu hình tenant)
    U29(UC-19-29 Di trú, chạy song song)
  end
  ADM --- U01 & U02 & U03 & U04 & U05 & U07 & U08 & U09 & U10 & U28 & U29
  APR --- U03 & U04 & U09 & U18 & U20 & U21 & U29
  ACC --- U17 & U19 & U20 & U21 & U22 & U26
  OPR --- U14 & U16 & U22 & U23 & U24 & U25 & U27
  AUD --- U22 & U24 & U26
  PAY --- U12
  PTN --- U11 & U14 & U15 & U17 & U27
  PG --- U02 & U11 & U13 & U16 & U18 & U19
  OLD --- U29
```

## 5. Bảng tổng hợp use case và truy vết

Hai bảng dưới sinh bằng `frs/ph19/tools/gen_frs_tables.py uc` từ khung truy vết §8.1, §10, §11, §14 nên luôn khớp mã với FRS và kiểm thử.

### 5.1. Use case và yêu cầu chức năng

| UC | Tên | Tác nhân chính | FR | BP |
|---|---|---|---|---|
| UC-19-01 | Khai báo nhà cung cấp và thông tin xác thực | Quản trị thanh toán | FR-19-001, 002 | BP-91 |
| UC-19-02 | Kiểm tra kết nối và giao dịch thử với nhà cung cấp | Quản trị thanh toán | FR-19-003, 004 | BP-91 |
| UC-19-03 | Kích hoạt nhà cung cấp có phê duyệt | Quản trị thanh toán | FR-19-005 | BP-91 |
| UC-19-04 | Tạm dừng, mở lại, ngừng hẳn nhà cung cấp | Quản trị thanh toán | FR-19-006, 010 | BP-91 |
| UC-19-05 | Tra cứu và cập nhật nhà cung cấp | Quản trị thanh toán | FR-19-007, 008, 009, 069 | — |
| UC-19-06 | Giám sát sức khỏe và xoay khóa nhà cung cấp | Hệ thống | FR-19-011, 012 | — |
| UC-19-07 | Quản lý nhóm dịch vụ | Quản trị thanh toán | FR-19-013, 016 | — |
| UC-19-08 | Quản lý dịch vụ thanh toán | Quản trị thanh toán | FR-19-014, 015, 016 | — |
| UC-19-09 | Đăng ký và phê duyệt đối tác | Quản trị thanh toán | FR-19-017, 018 | BP-92 |
| UC-19-10 | Cấp client, gán dịch vụ, cấu hình webhook cho đối tác | Quản trị thanh toán | FR-19-019, 020, 021 | BP-92 |
| UC-19-11 | Tạo giao dịch thanh toán | HTTT đối tác | FR-19-022, 023, 024, 028, 033, 034 | BP-93 |
| UC-19-12 | Người nộp thanh toán và quay về | Người nộp tiền | FR-19-025 | BP-93 |
| UC-19-13 | Nhận và xử lý kết quả thanh toán (IPN) | PayGov | FR-19-028, 029, 030, 031 | BP-93 |
| UC-19-14 | Hủy và hết hạn giao dịch | HTTT đối tác | FR-19-026, 027 | BP-93 |
| UC-19-15 | Đối tác truy vấn trạng thái giao dịch | HTTT đối tác | FR-19-035 | BP-93 |
| UC-19-16 | Đồng bộ trạng thái và xử lý lại IPN | Cán bộ tra cứu | FR-19-032, 036, 037 | BP-93 |
| UC-19-17 | Lập yêu cầu hoàn tiền | Kế toán | FR-19-038 | BP-94 |
| UC-19-18 | Phê duyệt và thực thi hoàn tiền | Người phê duyệt | FR-19-039, 040, 041 | BP-94 |
| UC-19-19 | Đối soát ngày với nhà cung cấp | Hệ thống | FR-19-042, 043, 044 | BP-95 |
| UC-19-20 | Xử lý chênh lệch đối soát | Kế toán | FR-19-045, 046 | BP-95 |
| UC-19-21 | Chốt, mở lại phiên đối soát và xuất biên bản | Kế toán | FR-19-047, 048 | BP-95 |
| UC-19-22 | Tra cứu và xuất danh sách giao dịch | Cán bộ tra cứu | FR-19-049, 050, 052 | — |
| UC-19-23 | Xem chi tiết giao dịch | Cán bộ tra cứu | FR-19-051, 055 | — |
| UC-19-24 | Xem nhật ký kiểm toán và nhật ký tích hợp | Kiểm toán viên | FR-19-053, 054, 055 | — |
| UC-19-25 | Giám sát qua dashboard và cảnh báo | Cán bộ tra cứu | FR-19-056, 057, 059 | — |
| UC-19-26 | Lập và xuất báo cáo định kỳ | Kế toán | FR-19-058 | — |
| UC-19-27 | Thông báo kết quả cho đối tác | Hệ thống | FR-19-060, 061, 062 | BP-93 |
| UC-19-28 | Cấu hình và khởi tạo phân hệ theo tenant | Quản trị thanh toán | FR-19-063, 064 | — |
| UC-19-29 | Di trú từ hệ cũ và chạy song song | Quản trị thanh toán | FR-19-065, 066, 067, 068 | BP-96 |

### 5.2. Use case, màn hình, API và kiểm thử

| UC | Màn hình | API | Kịch bản kiểm thử |
|---|---|---|---|
| UC-19-01 | UI-19-04, 05 | API-19-002, 006, 007 | TS-19-01 |
| UC-19-02 | UI-19-02, 06 | API-19-009…011 | TS-19-02 |
| UC-19-03 | UI-19-06, 13 | API-19-011, 012, 048 | TS-19-03 |
| UC-19-04 | UI-19-03, 04, 13 | API-19-005, 012…014, 048 | TS-19-04 |
| UC-19-05 | UI-19-03…05 | API-19-001, 003, 004, 091, 092 | TS-19-05 |
| UC-19-06 | UI-19-01, 04 | API-19-003, 008 | TS-19-06 |
| UC-19-07 | UI-19-07…10 | API-19-015…019, 021, 023, 028 | TS-19-07 |
| UC-19-08 | UI-19-08…10 | API-19-016, 018, 020…028 | TS-19-08 |
| UC-19-09 | UI-19-11…13 | API-19-029…035, 048 | TS-19-09 |
| UC-19-10 | UI-19-12 | API-19-036…046, 108 | TS-19-10 |
| UC-19-11 | UI-19-15 | API-19-054, 101, 108 | TS-19-11 |
| UC-19-12 | UI-19-28 | API-19-202 | TS-19-12 |
| UC-19-13 | UI-19-15, 16 | API-19-054, 201 | TS-19-13 |
| UC-19-14 | UI-19-15 | API-19-055, 104 | TS-19-14 |
| UC-19-15 | — | API-19-102, 103 | TS-19-15 |
| UC-19-16 | UI-19-15, 16 | API-19-053, 056…058 | TS-19-16 |
| UC-19-17 | UI-19-18 | API-19-059, 087, 105 | TS-19-17 |
| UC-19-18 | UI-19-13, 17, 18 | API-19-048, 060…062, 087, 088, 106, 203 | TS-19-18 |
| UC-19-19 | UI-19-19, 20 | API-19-063…067, 070, 204 | TS-19-19 |
| UC-19-20 | UI-19-13, 21, 22 | API-19-048, 071…074, 087, 088 | TS-19-20 |
| UC-19-21 | UI-19-13, 20 | API-19-048, 064, 067…069, 083, 084, 088, 107 | TS-19-21 |
| UC-19-22 | UI-19-14 | API-19-051, 083, 084 | TS-19-22 |
| UC-19-23 | UI-19-15, 23 | API-19-052, 054, 076 | TS-19-23 |
| UC-19-24 | UI-19-15, 23 | API-19-052, 075, 076 | TS-19-24 |
| UC-19-25 | UI-19-01, 02 | API-19-080, 081 | TS-19-25 |
| UC-19-26 | UI-19-25 | API-19-082…084 | TS-19-26 |
| UC-19-27 | UI-19-24 | API-19-077…079, 109 | TS-19-27 |
| UC-19-28 | UI-19-26 | API-19-085, 086 | TS-19-28 |
| UC-19-29 | UI-19-12, 13, 27 | API-19-047, 048, 088…090, 110 | TS-19-29 |

## 6. Đặc tả chi tiết use case

### 6.1. UC-19-01 · Khai báo nhà cung cấp và thông tin xác thực

Hệ cũ cho khai báo NCC kèm "liên kết API" ngay trên một biểu mẫu và lưu thông tin xác thực cùng bảng (LGC-PAY-001, 004). Use case tách hai việc: khai báo hồ sơ kết nối, và gắn **tham chiếu** tới bí mật đã nằm trong OpenBao; giá trị bí mật không bao giờ đi qua PH-19.

| Mục | Nội dung |
|---|---|
| Mã | UC-19-01 |
| Mục tiêu | ADM có một bản ghi NCC `DRAFT` đầy đủ thông tin kết nối và tham chiếu bí mật cho môi trường thử và chính thức |
| Tác nhân chính | ADM (`PERM-19-provider-write`, `PERM-19-credential-manage`) |
| Tác nhân phụ | SEC (nạp bí mật vào OpenBao theo quy trình D03-07); OpenBao |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-001, 002 |
| Tiền điều kiện | Tenant bật PH-19; tỉnh đã có thỏa thuận kết nối PayGov và bộ thông tin xác thực (A-19-05) |
| Điều kiện kích hoạt | ADM mở UI-19-03, chọn "Thêm nhà cung cấp" |
| Đảm bảo tối thiểu | Không giá trị bí mật nào được ghi vào CSDL, nhật ký hay phản hồi API; mã NCC đã lưu là bất biến |
| Đảm bảo thành công | NCC `DRAFT` có `connectionKey` riêng, tham chiếu bí mật môi trường thử và chính thức ở trạng thái `ACTIVE`, sẵn sàng kiểm tra kết nối |

**Luồng chính**

1. ADM (Nguyễn Văn An) mở UI-19-05 từ UI-19-03, chọn loại adapter `PAYGOV`, nhập mã `PAYGOV-T68`, tên, đơn vị cung cấp, đầu mối, ngày hiệu lực hợp đồng, địa chỉ API môi trường thử và chính thức, mã đơn vị kết nối do PayGov cấp.
2. Hệ thống kiểm tra định dạng, mã duy nhất trong tenant, địa chỉ là `https` và không trỏ dải nội bộ; ghi NCC `DRAFT` (API-19-002), sinh `connectionKey` 32 ký tự Base32 Crockford, hiển thị địa chỉ callback đầy đủ để tỉnh đăng ký với PayGov.
3. ADM mở tab "Thông tin xác thực" ở UI-19-04; SEC (Hoàng Minh Đức) đã nạp khóa ký, chứng thư mTLS của tỉnh và khóa công khai PayGov vào `kv/dh/T68/payment/providers/PAYGOV-T68/test/...`.
4. ADM chọn môi trường `TEST`, nhập đường dẫn tham chiếu cho từng mục đích (`SIGNING_KEY`, `MTLS_CERT`, `PROVIDER_PUBLIC_KEY`, `API_CREDENTIAL`) (API-19-007).
5. Hệ thống đọc siêu dữ liệu tại OpenBao bằng tài khoản dịch vụ của `dh-payment` (không đọc giá trị ra giao diện), kiểm tra tồn tại, thuật toán, hạn chứng thư ≥ 30 ngày; lưu tham chiếu `ACTIVE` kèm vân tay và ngày hết hạn.
6. ADM lặp bước 4–5 cho môi trường `PRODUCTION`.

**Luồng thay thế**

- **1a. Khai báo NCC thứ hai cùng PayGov.** Tỉnh có hai mã đơn vị kết nối (ví dụ khối Sở và khối huyện); ADM tạo `PAYGOV-T68-HUYEN` với `adapter_type = PAYGOV`; mỗi bản ghi có `connectionKey` riêng (A-19-05).
- **5a. Chứng thư sắp hết hạn (< 30 ngày).** Hệ thống lưu nhưng gắn cảnh báo vàng; checklist kích hoạt sẽ không đạt (BR-19-010).

**Luồng ngoại lệ**

- **E1. Mã trùng (bước 2).** ERR-19-038 "Mã nhà cung cấp đã tồn tại trong tenant."
- **E2. Địa chỉ không hợp lệ (bước 2).** ERR-19-001 với `errors[].field = productionBaseUrl`.
- **E3. Bí mật không tồn tại hoặc hết hạn (bước 5).** ERR-19-022; ADM liên hệ SEC nạp lại.
- **E4. Gắn tham chiếu khi NCC `PENDING_ACTIVATION`.** ERR-19-021.

**Quy tắc:** BR-19-026, BR-19-032; NFR-19-021. **Tần suất:** 1–3 NCC mỗi tenant, sửa vài lần mỗi năm.

### 6.2. UC-19-02 · Kiểm tra kết nối và giao dịch thử với nhà cung cấp

| Mục | Nội dung |
|---|---|
| Mã | UC-19-02 |
| Mục tiêu | ADM có bằng chứng NCC kết nối được và chạy trọn vòng thanh toán thử, làm đầu vào checklist kích hoạt |
| Tác nhân chính | ADM (`PERM-19-provider-test`) |
| Tác nhân phụ | PayGov môi trường thử |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-003, 004 |
| Tiền điều kiện | NCC không ở `RETIRED`; có tham chiếu bí mật `ACTIVE` của môi trường cần kiểm tra |
| Điều kiện kích hoạt | ADM mở bước 1 của UI-19-06 |
| Đảm bảo tối thiểu | Giao dịch thử luôn mang `is_test = true` và nằm dưới đối tác ẩn `__TEST__`; không tính vào dashboard, hạn mức, đối soát chính thức (BR-19-033) |
| Đảm bảo thành công | `provider_check_run` loại `CONNECTION` và `TEST_TRANSACTION` ở `PASSED`, có nhật ký từng bước |

**Luồng chính**

1. ADM chọn môi trường `PRODUCTION`, bấm "Kiểm tra kết nối" (API-19-009).
2. Hệ thống chạy tuần tự: phân giải DNS, bắt tay TLS (kiểm tra chuỗi chứng thư, phiên bản ≥ 1.2), mTLS nếu có, gọi `PING` hoặc thao tác truy vấn với mã giả của adapter, xác minh chữ ký phản hồi; ghi kết quả từng bước, độ trễ.
3. UI-19-06 hiển thị bốn bước xanh; ADM sang bước 2 "Giao dịch thử", chọn môi trường `TEST`, số tiền 10.000 đ (API-19-010).
4. Hệ thống tạo giao dịch thử dưới đối tác `__TEST__`, gọi PayGov khởi tạo, trả `paymentUrl`.
5. ADM mở `paymentUrl` trong cửa sổ mới, thanh toán bằng tài khoản thử của PayGov.
6. PayGov gửi IPN tới `/api/payment-callback/v1/paygov/{connectionKey}/ipn`; hệ thống xác minh và áp kết quả như UC-19-13.
7. UI-19-06 tự làm mới (API-19-011), thấy giao dịch thử `SUCCEEDED`, IPN "hợp lệ", `check_run` `PASSED`.

**Luồng thay thế**

- **6a. IPN không tới trong 10 phút.** Hệ thống truy vấn PayGov theo lịch BR-19-016; nếu truy vấn báo thành công, giao dịch thử `SUCCEEDED` nhưng `check_run` ghi `PASSED_WITHOUT_IPN` và checklist mục IPN chưa đạt; ADM kiểm tra lại địa chỉ callback đã đăng ký với PayGov.

**Luồng ngoại lệ**

- **E1. Thiếu, hết hạn thông tin xác thực (bước 1).** ERR-19-022.
- **E2. Kết nối thất bại (bước 2).** `check_run` `FAILED` với bước lỗi đầu tiên (ví dụ "TLS: chứng thư máy chủ không tin cậy"); không có mã lỗi HTTP vì thao tác chạy nền, kết quả xem ở API-19-011.
- **E3. Chạy giao dịch thử khi kết nối chưa đạt trong 24 giờ (bước 3).** ERR-19-035.
- **E4. Số tiền ngoài 1.000…100.000 đ.** ERR-19-010.

**Quy tắc:** BR-19-010, BR-19-033. **Tần suất:** vài lần khi kích hoạt hoặc sau sự cố.

### 6.3. UC-19-03 · Kích hoạt nhà cung cấp có phê duyệt

| Mục | Nội dung |
|---|---|
| Mã | UC-19-03 |
| Mục tiêu | NCC được đưa vào phục vụ chính thức sau khi người thứ hai kiểm tra bằng chứng |
| Tác nhân chính | ADM (`PERM-19-provider-write`, lập); APR (`PERM-19-provider-activate`, quyết định) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-005 |
| Tiền điều kiện | NCC `DRAFT`; checklist BR-19-010 đạt |
| Điều kiện kích hoạt | ADM bấm "Gửi duyệt" ở bước 4 của UI-19-06 |
| Đảm bảo tối thiểu | NCC chỉ `ACTIVE` khi có quyết định của người khác người lập; đề nghị hết hạn sau 7 ngày thì NCC về `DRAFT` |
| Đảm bảo thành công | NCC `ACTIVE`, EVT-19-01 phát; dịch vụ gắn NCC này kích hoạt được |

**Luồng chính**

1. UI-19-06 bước 3 hiển thị checklist bốn mục đều đạt kèm liên kết bằng chứng (API-19-011).
2. ADM nhập ghi chú, bấm "Gửi duyệt" (API-19-012, `action = ACTIVATE`).
3. Hệ thống kiểm tra lại checklist, chuyển NCC `PENDING_ACTIVATION`, tạo `approval_request` loại `PROVIDER_ACTIVATION` kèm ảnh chụp checklist, thông báo nhóm APR.
4. APR (Trần Thị Bình) mở UI-19-13 (API-19-048), xem bằng chứng trong ngăn kéo (API-19-049).
5. APR chọn "Duyệt" (API-19-050).
6. Hệ thống kiểm tra người duyệt ≠ người lập, kiểm tra lại checklist tại thời điểm duyệt, chuyển NCC `ACTIVE`, ghi `activated_at`, phát EVT-19-01, bắt đầu giám sát sức khỏe (UC-19-06).

**Luồng thay thế**

- **5a. Từ chối.** APR nhập lý do; NCC về `DRAFT`, ADM nhận thông báo.
- **5b. Người lập rút.** ADM chọn "Rút" trên đề nghị của mình; NCC về `DRAFT`.

**Luồng ngoại lệ**

- **E1. Checklist không đạt khi lập hoặc khi duyệt.** ERR-19-035 kèm danh sách mục chưa đạt trong `detail`.
- **E2. Người duyệt trùng người lập.** ERR-19-033; nút "Duyệt" ẩn với người lập nhưng API vẫn kiểm tra.
- **E3. Đề nghị đã được người khác quyết định.** ERR-19-034.

**Quy tắc:** BR-19-010, BR-19-011. **Tần suất:** vài lần mỗi năm.

### 6.4. UC-19-04 · Tạm dừng, mở lại, ngừng hẳn nhà cung cấp

| Mục | Nội dung |
|---|---|
| Mã | UC-19-04 |
| Mục tiêu | ADM ngừng nhận giao dịch mới qua một NCC khi có sự cố hoặc kết thúc hợp đồng mà không làm mất giao dịch dở |
| Tác nhân chính | ADM (`PERM-19-provider-suspend`, `PERM-19-provider-delete`) |
| Tác nhân phụ | APR (`PERM-19-provider-activate`, duyệt ngừng hẳn) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-006, 010 |
| Tiền điều kiện | NCC `ACTIVE` (tạm dừng), `SUSPENDED` (mở lại, ngừng hẳn), `DRAFT` (xóa) |
| Điều kiện kích hoạt | ADM chọn thao tác ở UI-19-03 hoặc UI-19-04 |
| Đảm bảo tối thiểu | Khi `SUSPENDED`, IPN, truy vấn, đối soát, hoàn tiền của giao dịch đã có vẫn chạy |
| Đảm bảo thành công | Trạng thái mới có hiệu lực ở lượt tạo giao dịch kế tiếp; EVT-19-01 phát |

**Luồng chính (tạm dừng rồi mở lại)**

1. PayGov thông báo bảo trì 2 giờ; ADM mở UI-19-04, chọn "Tạm dừng", nhập lý do (API-19-013, `If-Match`).
2. Hệ thống chuyển NCC `SUSPENDED`, phát EVT-19-01; yêu cầu tạo giao dịch mới cho dịch vụ của NCC trả ERR-19-008 kèm thông điệp "Kênh thanh toán tạm ngừng".
3. Hết bảo trì, ADM chạy "Kiểm tra kết nối" (UC-19-02 bước 1–2) rồi chọn "Mở lại" (API-19-014).
4. Hệ thống kiểm tra có `check_run` kết nối `PASSED` trong 1 giờ, chuyển `ACTIVE`, phát EVT-19-01.

**Luồng thay thế**

- **1a. Ngừng hẳn.** ADM chọn "Ngừng hẳn" (API-19-012, `action = RETIRE`); hệ thống kiểm tra BR-19-027 (không còn giao dịch `CREATED`/`PENDING`, yêu cầu hoàn dở, phiên đối soát chưa chốt), tạo đề nghị `PROVIDER_RETIREMENT`; APR duyệt ở UI-19-13; NCC `RETIRED`, dữ liệu giữ nguyên.
- **1b. Xóa NCC `DRAFT` chưa từng có giao dịch.** API-19-005; bản ghi bị xóa cứng cùng tham chiếu bí mật (bí mật trong OpenBao do SEC thu hồi).

**Luồng ngoại lệ**

- **E1. Mở lại khi chưa kiểm tra kết nối trong 1 giờ.** ERR-19-035.
- **E2. Ngừng hẳn khi còn việc dở.** ERR-19-036 kèm số lượng từng loại việc dở.
- **E3. Xóa NCC đã có giao dịch (kể cả thử).** ERR-19-037.
- **E4. Bản ghi đã bị người khác sửa.** ERR-19-045.

**Quy tắc:** BR-19-011, BR-19-027. **Tần suất:** tạm dừng vài lần mỗi quý; ngừng hẳn hiếm.

### 6.5. UC-19-05 · Tra cứu và cập nhật nhà cung cấp

| Mục | Nội dung |
|---|---|
| Mã | UC-19-05 |
| Mục tiêu | Người dùng tìm và xem NCC; ADM sửa thông tin và quản lý bảng ánh xạ mã kết quả |
| Tác nhân chính | ADM (`PERM-19-provider-write`); mọi vai trò có `PERM-19-provider-read` (xem) |
| Tác nhân phụ | APR (`PERM-19-provider-activate`, duyệt đổi bảng ánh xạ) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-007, 008, 009, 069 |
| Tiền điều kiện | Có ít nhất một NCC |
| Điều kiện kích hoạt | Người dùng mở UI-19-03 |
| Đảm bảo tối thiểu | Đổi địa chỉ kết nối của NCC `ACTIVE` chỉ có hiệu lực sau kiểm tra kết nối thành công với giá trị mới (BR-19-026); mã kết quả chưa ánh xạ không bao giờ được hiểu là thành công |
| Đảm bảo thành công | Thông tin mới được lưu với phiên bản mới; bảng ánh xạ mới có hiệu lực ngay sau duyệt |

**Luồng chính**

1. OPR (Phạm Thu Dung) mở UI-19-03, lọc trạng thái `ACTIVE`, sức khỏe `DEGRADED` (API-19-001); mở chi tiết `PAYGOV-T68` (API-19-003) xem sức khỏe, số dịch vụ, hạn chứng thư.
2. ADM mở UI-19-05 ở chế độ sửa, đổi đầu mối kỹ thuật và địa chỉ API chính thức mới do PayGov thông báo (API-19-004, `If-Match`).
3. Hệ thống lưu đầu mối ngay; với địa chỉ mới, lưu ở `pending_changes`, tiếp tục dùng địa chỉ cũ, yêu cầu kiểm tra kết nối với giá trị mới.
4. ADM chạy kiểm tra kết nối; khi `PASSED`, hệ thống áp địa chỉ mới, ghi kiểm toán.

**Luồng thay thế: đổi bảng ánh xạ mã kết quả (FR-19-069)**

- **2a.** PayGov bổ sung mã `24` "Giao dịch bị ngân hàng từ chối do vượt hạn mức". Màn UI-19-04 tab "Ánh xạ mã" hiển thị mã `24` trong danh sách "Mã đã gặp nhưng chưa ánh xạ" kèm số IPN đang cách ly (API-19-091).
- **2b.** ADM thêm dòng (`IPN`, `24`, `FAILED`, cuối, `BANK_LIMIT_EXCEEDED`, "Ngân hàng từ chối do vượt hạn mức"), lập đề nghị (API-19-092); hệ thống tạo `approval_request` loại `RESULT_MAPPING_CHANGE` kèm bảng so sánh trước – sau.
- **2c.** APR duyệt ở UI-19-13; hệ thống tạo phiên bản ánh xạ mới; IPN đang cách ly vì mã `24` được đánh dấu có thể xử lý lại (UC-19-16 luồng 1b).

**Luồng ngoại lệ**

- **E1. Sửa trường bất biến (mã, loại adapter).** ERR-19-001.
- **E2. Sửa NCC `PENDING_ACTIVATION`, `RETIRED`.** ERR-19-021.
- **E3. Dòng ánh xạ `SUCCEEDED` không phải kết quả cuối, hoặc dòng trùng.** ERR-19-001.
- **E4. Đã có đề nghị đổi ánh xạ đang chờ.** ERR-19-021.

**Quy tắc:** BR-19-026, GĐ-03. **Tần suất:** xem hằng ngày; sửa vài lần mỗi quý.

### 6.6. UC-19-06 · Giám sát sức khỏe và xoay khóa nhà cung cấp

| Mục | Nội dung |
|---|---|
| Mã | UC-19-06 |
| Mục tiêu | Phát hiện sớm NCC suy giảm để ngắt mạch, cảnh báo; thay khóa, chứng thư trước khi hết hạn mà không gián đoạn thu |
| Tác nhân chính | Bộ lập lịch (giám sát); ADM với SEC (xoay khóa, `PERM-19-credential-manage`) |
| Tác nhân phụ | OPR (nhận cảnh báo); PH-13 |
| Mức ưu tiên, phát hành | M · MVP (giám sát); S · Đ2b (xoay khóa có chuyển tiếp) |
| FR hiện thực | FR-19-011, 012 |
| Tiền điều kiện | NCC `ACTIVE` hoặc `SUSPENDED` |
| Điều kiện kích hoạt | Chu kỳ `19.provider.health-interval-seconds`; chứng thư còn ≤ 30 ngày |
| Đảm bảo tối thiểu | Trạng thái sức khỏe không đổi vòng đời NCC; trong thời gian chuyển tiếp xoay khóa, IPN ký bằng khóa cũ hoặc mới đều được chấp nhận |
| Đảm bảo thành công | `health_status` và `circuit_state` phản ánh tình trạng thật; khóa mới `ACTIVE`, khóa cũ `RETIRED` sau chuyển tiếp |

**Luồng chính (giám sát)**

1. Pod giữ khóa lãnh đạo `{tenant}:payment:health-leader` gọi `PING` mỗi 60 giây cho mỗi NCC.
2. Hệ thống gộp kết quả thăm dò với số liệu lời gọi thật trong cửa sổ trượt 5 phút: tỷ lệ lỗi 55%, p95 6,2 giây → `DEGRADED`; tỷ lệ lỗi vượt `19.provider.circuit-error-rate` → mạch `OPEN`.
3. Hệ thống phát EVT-19-02, chỉ số `payment_provider_circuit_state`; PH-13 gửi cảnh báo khẩn cho OPR.
4. Trong khi mạch mở, yêu cầu tạo giao dịch nhận ERR-19-017 kèm `Retry-After` trước khi ghi CSDL (BR-19-013); IPN, truy vấn, đối soát vẫn chạy.
5. Sau 30 giây, mạch nửa mở cho 5 lời gọi thử; đều thành công → `CLOSED`, sức khỏe về `HEALTHY`, phát EVT-19-02.

**Luồng thay thế (xoay khóa, Đ2b)**

- **1a.** Chỉ số `payment_credential_expiry_days` = 28 → cảnh báo SEC. SEC nạp khóa mới vào OpenBao; ADM gọi API-19-008 tạo bản `NEXT`.
- **1b.** Hệ thống kiểm tra kết nối với bản `NEXT`; đạt thì bắt đầu chuyển tiếp 7 ngày (`19.provider.credential-transition-days`): ký yêu cầu đi bằng khóa mới, xác minh IPN bằng cả hai khóa công khai.
- **1c.** Hết chuyển tiếp, bản cũ `RETIRED`, bản `NEXT` → `ACTIVE`.
- **1d (MVP).** Khi chưa có FR-19-012, ADM thay tham chiếu trực tiếp bằng API-19-007 rồi chạy kiểm tra kết nối; IPN ký bằng khóa cũ trong khoảng chuyển đổi có thể bị từ chối và được PayGov gửi lại (A-19-02).

**Luồng ngoại lệ**

- **E1. Đã có bản `NEXT` đang chuyển tiếp.** ERR-19-021.
- **E2. Bí mật mới không hợp lệ.** ERR-19-022.

**Quy tắc:** BR-19-013, BR-19-026; NFR-19-017. **Tần suất:** giám sát liên tục; xoay khóa 1–2 lần mỗi năm.

### 6.7. UC-19-07 · Quản lý nhóm dịch vụ

| Mục | Nội dung |
|---|---|
| Mã | UC-19-07 |
| Mục tiêu | ADM tổ chức dịch vụ thu theo nhóm (lĩnh vực) như hệ cũ để lọc và báo cáo |
| Tác nhân chính | ADM (`PERM-19-service-write`) |
| Tác nhân phụ | PH-07 (danh mục lĩnh vực `DM_LINH_VUC_TTHC`) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-013, 016 |
| Tiền điều kiện | PH-07 có danh mục lĩnh vực của tenant |
| Điều kiện kích hoạt | ADM mở UI-19-07 |
| Đảm bảo tối thiểu | Không xóa được nhóm còn dịch vụ; mã lĩnh vực luôn hợp lệ tại thời điểm ghi |
| Đảm bảo thành công | Nhóm có mã, tên, lĩnh vực, thứ tự hiển thị |

**Luồng chính**

1. ADM mở UI-19-07 (API-19-015), chọn "Thêm nhóm"; UI-19-08 mở ngăn kéo.
2. ADM nhập mã `TU-PHAP`, tên "Lĩnh vực tư pháp", chọn lĩnh vực từ ô tra danh mục (API-19-028).
3. Hệ thống kiểm tra mã duy nhất, mã lĩnh vực còn hiệu lực ở PH-07, ghi nhóm (API-19-016).

**Luồng thay thế**

- **3a. Sửa nhóm** (API-19-018, `If-Match`); **xóa mềm nhóm** không còn dịch vụ (API-19-019).
- **3b. PH-07 báo mã lĩnh vực hết hiệu lực** (sự kiện danh mục): hệ thống bật cờ `catalog_invalid` trên nhóm và dịch vụ liên quan, hiển thị cảnh báo; ADM sửa ở lần cập nhật kế tiếp (FR-19-016).

**Luồng ngoại lệ**

- **E1. Mã trùng.** ERR-19-038. **E2. Mã lĩnh vực không hợp lệ.** ERR-19-039. **E3. Xóa nhóm còn dịch vụ.** ERR-19-037. **E4. Xung đột phiên bản.** ERR-19-045.

**Tần suất:** 10–30 nhóm mỗi tenant; sửa hiếm.

### 6.8. UC-19-08 · Quản lý dịch vụ thanh toán

| Mục | Nội dung |
|---|---|
| Mã | UC-19-08 |
| Mục tiêu | ADM khai báo khoản thu (phí, lệ phí) cùng NCC thu, khoảng số tiền, tài khoản thụ hưởng, và điều khiển vòng đời |
| Tác nhân chính | ADM (`PERM-19-service-write`, `PERM-19-service-activate`) |
| Tác nhân phụ | PH-07 (lĩnh vực, loại phí, cơ quan thu) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-014, 015, 016 |
| Tiền điều kiện | Có nhóm dịch vụ; NCC `ACTIVE` để kích hoạt dịch vụ |
| Điều kiện kích hoạt | ADM mở UI-19-09 |
| Đảm bảo tối thiểu | Dịch vụ chỉ `ACTIVE` khi NCC `ACTIVE` và mã danh mục hợp lệ (BR-19-009); ngừng hẳn không làm mất giao dịch dở |
| Đảm bảo thành công | Dịch vụ `ACTIVE` gán được cho đối tác; EVT-19-03 phát |

**Luồng chính**

1. ADM mở UI-19-09 (API-19-020), chọn "Thêm dịch vụ"; UI-19-10 mở biểu mẫu.
2. ADM nhập mã `LP-LLTP`, tên, nhóm `TU-PHAP`, loại phí `LE_PHI`, cơ quan thu, NCC `PAYGOV-T68`, mã tham chiếu tài khoản thụ hưởng đã đăng ký với PayGov (OQ-19-11), khoảng số tiền 200.000…200.000 đ, thời hạn giao dịch 30 phút.
3. Hệ thống kiểm tra mã duy nhất, khoảng số tiền, mã danh mục (API-19-028), ghi dịch vụ `DRAFT` (API-19-021).
4. ADM bấm "Kích hoạt" (API-19-025); hệ thống kiểm tra NCC `ACTIVE`, mã danh mục còn hiệu lực, có tham chiếu tài khoản thụ hưởng; chuyển `ACTIVE`, phát EVT-19-03.

**Luồng thay thế**

- **4a. Tạm dừng** (API-19-026): đối tác tạo giao dịch nhận ERR-19-008; **mở lại** (API-19-025).
- **4b. Ngừng hẳn** (API-19-027): chỉ khi không còn việc dở (BR-19-027).
- **4c. Xóa dịch vụ `DRAFT` chưa có giao dịch** (API-19-024).

**Luồng ngoại lệ**

- **E1. Khoảng số tiền sai (`min > max`, ≤ 0).** ERR-19-001. **E2. Mã trùng.** ERR-19-038. **E3. Mã danh mục không hợp lệ.** ERR-19-039.
- **E4. Kích hoạt khi NCC không `ACTIVE` hoặc thiếu tài khoản thụ hưởng.** ERR-19-035.
- **E5. Ngừng hẳn khi còn việc dở.** ERR-19-036. **E6. Xóa dịch vụ đã có giao dịch.** ERR-19-037.

**Quy tắc:** BR-19-009, BR-19-027. **Tần suất:** 100–300 dịch vụ mỗi tenant; thêm, sửa hằng tuần trong giai đoạn đưa vào dùng.

### 6.9. UC-19-09 · Đăng ký và phê duyệt đối tác

| Mục | Nội dung |
|---|---|
| Mã | UC-19-09 |
| Mục tiêu | Một HTTT của tỉnh được phép thu tiền qua Datahub sau khi hồ sơ được người thứ hai duyệt |
| Tác nhân chính | ADM (`PERM-19-partner-write`) |
| Tác nhân phụ | APR (`PERM-19-partner-approve`); PH-01 (danh mục HTTT, cơ quan) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-017, 018 |
| Tiền điều kiện | HTTT đối tác đã có trong danh mục HTTT của tỉnh |
| Điều kiện kích hoạt | ADM mở UI-19-11, chọn "Đăng ký đối tác" |
| Đảm bảo tối thiểu | Đối tác chỉ gọi được API thanh toán khi `ACTIVE` và chế độ định tuyến `SHADOW` hoặc `DATAHUB` |
| Đảm bảo thành công | Đối tác `ACTIVE`, `routing_mode = LEGACY` mặc định; EVT-19-04 phát |

**Luồng chính**

1. ADM nhập mã `MCDT-T68`, tên, cơ quan chủ quản (mã PH-07), đầu mối nghiệp vụ, kỹ thuật, danh sách tên miền quay về được phép (`https://dichvucong.t68.gov.vn`), mã ứng dụng ở hệ cũ `legacyAppCode` (API-19-030).
2. Hệ thống kiểm tra, ghi đối tác `DRAFT`.
3. ADM cấp client, gán dịch vụ, cấu hình webhook (UC-19-10), rồi bấm "Gửi duyệt" (API-19-033, `action = ONBOARD`).
4. Hệ thống kiểm tra điều kiện gửi duyệt (có ít nhất một client, một dịch vụ được gán, một đầu nhận webhook đã gửi thử thành công), chuyển `PENDING_APPROVAL`, tạo đề nghị `PARTNER_ONBOARDING`.
5. APR duyệt ở UI-19-13; hệ thống chuyển đối tác `ACTIVE`, phát EVT-19-04.

**Luồng thay thế**

- **5a. Từ chối hoặc rút.** Đối tác về `DRAFT`.
- **5b. Tạm dừng, mở lại** (API-19-034, 035) không cần duyệt; **chấm dứt** (`action = TERMINATE`) cần duyệt, hệ thống thu hồi mọi client tại PH-12, webhook giao dịch dở tiếp tục 30 ngày.

**Luồng ngoại lệ**

- **E1. Thiếu điều kiện gửi duyệt.** ERR-19-035 kèm mục còn thiếu.
- **E2. Mã hoặc `legacyAppCode` trùng.** ERR-19-038. **E3. Địa chỉ quay về sai.** ERR-19-001.
- **E4. Người duyệt trùng người lập.** ERR-19-033.
- **E5. PH-12 không thu hồi được client khi chấm dứt.** ERR-19-099; thao tác không áp dụng, đối tác giữ trạng thái cũ.

**Quy tắc:** BR-19-011. **Tần suất:** 10–40 đối tác mỗi tenant.

### 6.10. UC-19-10 · Cấp client, gán dịch vụ, cấu hình webhook cho đối tác

| Mục | Nội dung |
|---|---|
| Mã | UC-19-10 |
| Mục tiêu | Đối tác có định danh máy-máy, quyền thu các dịch vụ cụ thể trong hạn mức, và địa chỉ nhận kết quả có ký |
| Tác nhân chính | ADM (`PERM-19-partner-client-manage`, `PERM-19-partner-write`, `PERM-19-partner-webhook-manage`) |
| Tác nhân phụ | SEC; PH-12 (Keycloak) |
| Mức ưu tiên, phát hành | M · MVP |
| FR hiện thực | FR-19-019, 020, 021 |
| Tiền điều kiện | Đối tác không `TERMINATED` |
| Điều kiện kích hoạt | ADM mở các tab của UI-19-12 |
| Đảm bảo tối thiểu | Bí mật client, bí mật ký webhook chỉ hiển thị một lần; địa chỉ webhook không trỏ dải nội bộ (chống SSRF) |
| Đảm bảo thành công | Client `ACTIVE` ở PH-12 với quyền `PERM-19-partner-pay-*`; dịch vụ được gán kèm hạn mức; đầu nhận webhook đã gửi thử thành công |

**Luồng chính**

1. ADM mở tab "Client", chọn "Cấp client", chọn phương thức xác thực `private_key_jwt` và dán khóa công khai do đối tác cung cấp (API-19-037).
2. Hệ thống gọi PH-12 tạo client `mcdt-t68-prod` trong realm của tenant, gán vai trò `ROLE-PAYMENT_PARTNER`, lưu `client_id`.
3. ADM mở tab "Dịch vụ và hạn mức", gán `LP-LLTP` với hạn mức 2.000 giao dịch/ngày, 500.000.000 đ/ngày, tối đa 5.000.000 đ/giao dịch (API-19-040).
4. ADM mở tab "Webhook", thêm đầu nhận `https://dichvucong.t68.gov.vn/payment/webhook`, chọn loại sự kiện `transaction.*`, `refund.*` (API-19-043).
5. Hệ thống kiểm tra địa chỉ (HTTPS, phân giải DNS không ra dải riêng, loopback), sinh bí mật ký `whsec_…`, lưu vào OpenBao, hiển thị một lần.
6. ADM bấm "Gửi thử" (API-19-045); hệ thống gửi sự kiện `ping` có ký; đối tác trả 200; đầu nhận ghi `last_test_ok_at`.

**Luồng thay thế**

- **1a. Xác thực bằng `client_secret`.** PH-12 sinh bí mật, hệ thống hiển thị một lần, không lưu.
- **1b. Thu hồi client** (API-19-038): PH-12 vô hiệu ngay; token đang dùng hết hiệu lực trong ≤ 5 phút.
- **5a. Xoay bí mật ký webhook** (API-19-046): bí mật mới hiển thị một lần; trong 7 ngày webhook mang hai chữ ký `v1`.

**Luồng ngoại lệ**

- **E1. Khóa, chứng thư không hợp lệ.** ERR-19-001. **E2. Đối tác `TERMINATED`.** ERR-19-021.
- **E3. Địa chỉ webhook không hợp lệ hoặc nội bộ.** ERR-19-044. **E4. Đã có xoay bí mật đang chuyển tiếp.** ERR-19-021.
- **E5. PH-12 không phản hồi.** ERR-19-099; không tạo bản ghi client cục bộ.

**Quy tắc:** BR-19-005, BR-19-008; NFR-19-022. **Tần suất:** khi đưa đối tác vào dùng; xoay bí mật hằng năm.

