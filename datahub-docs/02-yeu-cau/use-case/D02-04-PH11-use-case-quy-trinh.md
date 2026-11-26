---
ma_tai_lieu: D02-04-PH11
ten: Đặc tả use case phân hệ PH-11 Quy trình liên thông
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, cán bộ nghiệp vụ một cửa liên thông, kỹ sư dh-platform, kiểm thử viên
phan_he: PH-11
mo_ta: Đặc tả 24 use case của phân hệ Quy trình liên thông (BPM), mỗi use case một khối 15 mục kèm mã lỗi và câu thông báo lấy từ FRS, phủ đủ 66 FR, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH11 FRS; D03-02-PH11 SDD; D03-03-PH11 CSDL; D03-04-PH11 API; D03-06-PH11 Màn hình; D05-02-PH11 Kiểm thử
---

# D02-04-PH11 · Đặc tả use case Quy trình liên thông

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 24 use case của PH-11, phủ toàn bộ 66 FR (48 mức M, 16 mức S, 2 mức C) của [D02-03-PH11](../frs/D02-03-PH11-frs-quy-trinh.md). Use case đi theo hai vòng đời nối nhau. Vòng thứ nhất là vòng đời mô hình: kỹ sư tích hợp vẽ quy trình BPMN 2.0 trên trình thiết kế, khai ý định nghiệp vụ và hành động bù trừ, chạy thử, gửi duyệt; người duyệt khác người gửi quyết định phát hành (bốn mắt) và hệ thống triển khai lên engine Flowable. Vòng thứ hai là vòng đời phiên: Cổng DVC hoặc hệ thống thông tin (HTTT) một cửa khởi tạo phiên cho từng hồ sơ, engine điều phối bước tự động qua PH-04, giao việc cho cán bộ ở nhiều cơ quan, tính hạn theo ngày làm việc, nhắc và leo thang khi quá hạn, bù trừ khi một bước lỗi sau khi bước khác đã ghi dữ liệu, và cung cấp tiến độ đã che dữ liệu cá nhân (DLCN) cho công dân qua Cổng DVC.

Bốn điểm hội đồng cần lưu ý. Thứ nhất, hệ cũ (Viettel 2021) không có BPM nên 24 use case là năng lực mới; chỉ LGC-NGSP-002, LGC-NGSP-004 và LGC-BUS-037 liên quan gián tiếp (mục 5.3). Thứ hai, mọi quyết định có hậu quả lớn đều qua bốn mắt: phát hành và ngừng dùng phiên bản, sửa biến, chuyển bước, di trú phiên, miễn bù trừ, bỏ qua bước bù trừ (LP-11-01). Thứ ba, PH-11 không gọi hệ thống thông tin nào trực tiếp: mọi bước tự động đi qua lệnh Kafka tới PH-04 theo ý định nghiệp vụ và đi qua outbox ghi cùng giao dịch `ph11_bpm` với thay đổi nghiệp vụ và nguyên tử về hiệu ứng với engine (đề xuất ADR 112), nên một lỗi Kafka hay engine không để lại phiên nửa vời. Thứ tư, không có giao dịch phân tán 2PC giữa cơ quan: nhất quán cuối cùng đạt bằng Saga bù trừ có nhật ký riêng, và bù trừ thất bại luôn có người chịu trách nhiệm (đề xuất ADR 113).

Quy trình ví dụ xuyên suốt là liên thông "Đăng ký khai sinh, đăng ký thường trú, cấp thẻ BHYT cho trẻ dưới 6 tuổi" mã `LT_KHAI_SINH` của tenant `T68`, hồ sơ `HS-T68-2026-000142`; quy trình thứ hai là `DUYET_KET_NAP_HTTT` do PH-01 khởi tạo qua API. Có bốn sơ đồ hoạt động (UC-11-05, 06, 11, 18), năm câu hỏi mở Q11-45…49 và sáu đề nghị đồng bộ FRS đã hấp thụ (mục 8.2).

## 1. Giới thiệu

### 1.1. Mục đích

Tài liệu đặc tả 24 use case (ca sử dụng) của PH-11 Quy trình liên thông. Mỗi use case mô tả một mục tiêu nghiệp vụ của một tác nhân theo từng bước, kèm nhánh thay thế, ngoại lệ có mã lỗi và câu thông báo, cùng các đảm bảo hệ thống giữ. Tài liệu nối FRS với D03-02, 03, 04 và D03-06; mỗi luồng là ít nhất một phép kiểm trong `TS-11-nn`.

### 1.2. Phạm vi

Phạm vi là toàn bộ FR-11-001…066: trình tự giữa tác nhân và hệ thống, dữ liệu ví dụ, xử lý khi sai lệch; ràng buộc chi tiết từng bước và bộ quy tắc kiểm tra tĩnh nằm ở FRS. Chức năng dùng chung FR-00 không đặc tả lại.

Ngoài phạm vi: luồng kỹ thuật, bộ điều hợp (PH-04, PH-05), định tuyến sự kiện (PH-10), kênh thông báo ngoài (PH-03), người dùng, nhóm, đơn vị (PH-12) và thực thi WS-BPEL (chỉ thuyết minh kế thừa, Q11-02).

### 1.3. Người đọc

Hội đồng đọc tóm tắt, chương 4, 5, 9. Nghiệp vụ rà UC-11-06, 09 đến 13, 20. Kỹ sư `dh-platform` đọc chương 6 và 7. Vận hành đọc UC-11-07, 14, 16 đến 19, 21 đến 23.

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01, riêng theo FRS §1.4 và §4.1; bảng nhắc các từ dày đặc trong luồng.

| Thuật ngữ | Giải thích |
|---|---|
| Mô hình, phiên bản | Mô hình quy trình (`processKey`) có nhiều phiên bản BPMN 2.0; chỉ phiên bản `PUBLISHED` sinh phiên mới (BR-11-006) |
| Phiên | Một lần chạy của quy trình cho một hồ sơ, khóa nghiệp vụ `businessKey` (mã hồ sơ của kênh DVC) |
| Bước tự động (service task) | Bước máy chạy qua lệnh tới PH-04, chỉ mang ý định nghiệp vụ, không có địa chỉ hay giao thức (BR-11-002) |
| Ý định nghiệp vụ | Tên hành động nghiệp vụ như `guiTuPhap`, `capTheBHYT`, ánh xạ sang luồng PH-04 theo môi trường |
| Việc | Việc người dùng sinh từ bước người dùng, giao cho người, nhóm hoặc đơn vị; hiện ở hộp "Việc của tôi" |
| Saga, bù trừ | Chuỗi hành động nghiệp vụ chạy ngược để đưa các cơ quan về trạng thái nhất quán khi một bước lỗi; không dùng 2PC (BR-11-010) |
| Outbox, inbox | Bảng ghi sự kiện, bản tin cùng giao dịch `ph11_bpm` với thay đổi nghiệp vụ để không mất, không trùng (ADR-042) |
| TA, TO, IE, IA, AU, VW, CB, PA, PO | Quản trị tỉnh, vận hành tỉnh, kỹ sư tích hợp, người duyệt tích hợp, kiểm toán, người xem, cán bộ xử lý, quản trị và vận hành nền tảng (FRS §3.1) |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

[D02-03-PH11 FRS](../frs/D02-03-PH11-frs-quy-trinh.md) (nguồn chuẩn: §3 tác nhân, §5 danh sách FR, §7 quy tắc, §9 mã lỗi, thông báo, sự kiện, API, §10.1 màn hình, Phụ lục A); D02-01 (REQ, BP); D02-02 SRS; D02-08 (quyền, vai trò); D00-01 (hệ mã); D00-04 (sổ tra cứu gọn); K-UC, K-TRINH-BAY; `docs/07-srs/SRS-PH-11-bpm.md` (SRS cũ của repo); D02-04-PH06 làm mẫu trình bày.

### 1.6. Cấu trúc tài liệu

Chương 2 quy ước đọc; 3 tác nhân; 4 sơ đồ tổng; 5 truy vết; 6 hai mươi bốn khối đặc tả; 7 luồng phụ; 8 mã mới, đề nghị đồng bộ FRS; 9 câu hỏi mở.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC (từ Mục tiêu đến Màn hình và API). Đoạn văn trước khối nói bối cảnh; sau khối là sơ đồ khi use case có từ ba thành phần trao đổi trở lên.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3) và nêu bước quay lại. Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-11-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép (nguyên văn FRS §9.2 hoặc khối FR; dấu `{…}` do máy chủ điền). Lỗi ERR-11-101…125 là lỗi nền (engine, lệnh, Saga), không trả cho người gọi API, vận hành thấy ở UI-11-19, 20, 21. Luồng phụ dùng chung ghi `LP-11-nn`, đặc tả một lần ở chương 7.

Quy ước chung mọi use case: lệnh ghi qua `/api/bpm/v1` mang `Idempotency-Key`, lệnh sửa mang `If-Match` (thiếu: ERR-00-428); chưa xác thực trả ERR-00-401, thiếu quyền chức năng trả ERR-00-403; đối tượng tenant khác trả như không tồn tại (ERR-11-001); truy vấn chạy dưới RLS; mọi thao tác ghi sinh kiểm toán. Dữ liệu ví dụ giả lập, tenant `T68`, mã xã `26734`.

| Vai | Người hoặc hệ thống | Ghi chú |
|---|---|---|
| IE, IA | **Nam** (kỹ sư tích hợp), **Hạnh** (người duyệt tích hợp) | Hạnh khác Nam; cặp loại trừ trên cùng phiên bản mô hình (FRS §3.3) |
| TA, TO | **Mai** (Sở KH&CN), **Chi** (Trung tâm dữ liệu) | Quản trị tỉnh, vận hành tỉnh |
| CB | **Thu** (nhóm `TP_HOTICH`, UBND xã), **Bình** (nhóm `CA_CUTRU`) | Cán bộ được giao việc |
| AU, PA | **Quang** (Thanh tra tỉnh), **Hà** (đơn vị vận hành nền tảng) | Kiểm toán, quản trị nền tảng |
| Hệ thống | Cổng DVC tỉnh, HTTT một cửa, PH-01, PH-04, PH-10 | Client có scope `bpm.*` |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-11 có chín nhóm tác nhân người và các tác nhân hệ thống. Người duyệt tích hợp chỉ quyết định bản do người khác gửi; kỹ sư thiết kế và người duyệt là cặp loại trừ trên cùng phiên bản mô hình. Cổng DVC, HTTT một cửa và các phân hệ có luồng duyệt nhiều cấp là tác nhân chính của use case máy với máy (khởi tạo phiên, tra tiến độ). PH-04 chỉ nhận lệnh và trả kết quả bằng scope `bpm.service.worker`.

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính | Use case tham gia |
|---|---|---|---|
| Kỹ sư tích hợp (IE) | ROLE-INTEGRATION_ENGINEER | `PERM-11-model`, `PERM-11-read`, `PERM-11-task` (một phần) | 01, 02, 03, 04, 05 |
| Người duyệt tích hợp (IA) | ROLE-INTEGRATION_APPROVER | `PERM-11-publish`, `PERM-11-read`, `PERM-11-task` | 04, 05 |
| Quản trị tỉnh (TA) | ROLE-TENANT_ADMIN | `PERM-11-model`, `publish`, `instance`, `instance-admin`, `task-admin`, `compensate`, `config`, `audit-read` | 01, 02, 03, 04, 05, 06, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24 |
| Vận hành tỉnh (TO) | ROLE-TENANT_OPERATOR | `PERM-11-instance`, `task-admin`, `compensate`, `read`, `task` | 06, 07, 12, 13, 14, 15, 16, 18, 19, 21, 22 |
| Kiểm toán (AU) | ROLE-AUDITOR | `PERM-11-audit-read`, `PERM-11-read` | 15, 19, 21, 24 |
| Người xem (VW) | ROLE-VIEWER | `PERM-11-read` | 21 |
| Cán bộ xử lý (CB) | Người được giao việc (PH-12) | `PERM-11-task`, `PERM-11-read` (○ theo BR-11-031) | 09, 10, 11, 12, 13, 14, 15 |
| Quản trị nền tảng (PA) | ROLE-PLATFORM_ADMIN | `PERM-11-model`, `PERM-11-config` trên `COMMON` | 01, 14, 23 |
| Vận hành nền tảng (PO) | ROLE-PLATFORM_OPERATOR | `PERM-11-compensate` (○, có phiếu sự cố) | 22 |
| Cổng DVC tỉnh, HTTT một cửa (DVC) | Hệ thống | `bpm.instance.start`, `bpm.instance.read`, `bpm.progress.read`, `bpm.task.read` | 06, 08, 11, 16, 20 |
| PH-01, PH-07, PH-19 (PH-01, 07, 19) | Hệ thống | `bpm.instance.start`, `bpm.instance.read` | 06, 20 |
| PH-04 (PH-04) | Hệ thống | `bpm.service.worker` | 07, 18, 19 |
| PH-10 (PH-10) | Hệ thống | Sự kiện khởi tạo, thông điệp; phân phối `bpm.*` | 06, 08, 20 |

: Tác nhân và use case tham gia


## 4. Sơ đồ use case tổng

Hai mươi bốn use case chia bốn hình: toàn cảnh, rồi ba cụm (mô hình và phát hành; phiên, bước tự động và việc; Saga, tiến độ, giám sát và kiểm toán). Mermaid không có ký pháp UML use case nên dùng `flowchart`: hình bo tròn là tác nhân người, hình hai viền là tác nhân hệ thống, hình chữ nhật bo góc là use case; đường liền nối tác nhân với use case họ tham gia.

```{.mermaid caption="Toàn cảnh use case PH-11 theo nhóm mục tiêu tác nhân"}
flowchart TB
  IE([IE, IA, PA])
  CB([CB])
  TATO([TA, TO])
  AU([AU, VW])
  EXT[[Cổng DVC, HTTT, PH-01]]
  P4[[PH-04, PH-10, PH-12]]
  subgraph G1["Thiết kế và phát hành mô hình"]
    A1(UC-11-01…05)
  end
  subgraph G2["Khởi tạo phiên và bước tự động"]
    A2(UC-11-06…08)
  end
  subgraph G3["Xử lý việc và ủy quyền"]
    A3(UC-11-09…13)
  end
  subgraph G4["Hạn và điều khiển phiên"]
    A4(UC-11-14…17)
  end
  subgraph G5["Bù trừ Saga"]
    A5(UC-11-18, 19)
  end
  subgraph G6["Tiến độ, giám sát, quản trị, kiểm toán"]
    A6(UC-11-20…24)
  end
  IE --- A1
  EXT --- A2
  P4 --- A2
  CB --- A3
  TATO --- A3
  TATO --- A4
  TATO --- A5
  EXT --- A6
  TATO --- A6
  AU --- A6
```

Hình cho thấy kỹ sư và người duyệt ở vòng đời mô hình, cán bộ ở xử lý việc, vận hành và quản trị ở điều khiển phiên, bù trừ và giám sát; Cổng DVC chỉ chạm khởi tạo phiên và tra tiến độ.

```{.mermaid caption="Use case thiết kế, kiểm tra và phát hành mô hình quy trình"}
flowchart TB
  IE([IE])
  IA([IA])
  TA([TA, PA])
  P4[[PH-04, PH-07, PH-09]]
  subgraph MD["Mô hình quy trình"]
    U01(UC-11-01 Tạo mô hình, nháp, mẫu dùng chung)
    U02(UC-11-02 Thiết kế, kiểm tra tĩnh, chạy thử)
    U03(UC-11-03 Biến, biểu mẫu, bảng quyết định)
    U04(UC-11-04 Ý định và bù trừ)
    U05(UC-11-05 Gửi duyệt, phát hành, ngừng dùng)
    U01 ~~~ U02 ~~~ U03 ~~~ U04 ~~~ U05
  end
  IE --- U01 & U02 & U03 & U04 & U05
  IA --- U05
  TA --- U01 & U02 & U05
  P4 --- U03 & U04 & U05
```

Hình cho thấy kỹ sư soạn và gửi, người duyệt quyết định phát hành; PH-04 cung cấp danh mục luồng, PH-07 nhóm nghiệp vụ, PH-09 phân loại dữ liệu cho biến.

```{.mermaid caption="Use case khởi tạo phiên, bước tự động, việc người dùng và điều khiển phiên"}
flowchart TB
  DVC[[Cổng DVC, HTTT, PH-10]]
  P4[[PH-04, PH-10]]
  CB([CB])
  TO([TA, TO])
  subgraph PH["Phiên và bước tự động"]
    U06(UC-11-06 Khởi tạo phiên)
    U07(UC-11-07 Bước tự động qua PH-04)
    U08(UC-11-08 Thông điệp, hẹn giờ, quy trình con)
  end
  subgraph VI["Việc người dùng"]
    U09(UC-11-09 Tạo việc, phân công)
    U10(UC-11-10 Nhận, xử lý việc)
    U11(UC-11-11 Trả về, bổ sung hồ sơ)
    U12(UC-11-12 Chuyển việc, trao đổi)
    U13(UC-11-13 Ủy quyền, giao lại)
  end
  subgraph DK["Hạn và điều khiển phiên"]
    U14(UC-11-14 Lịch, hạn, leo thang)
    U15(UC-11-15 Tra cứu phiên)
    U16(UC-11-16 Tạm dừng, hủy)
    U17(UC-11-17 Sửa biến, chuyển bước, di trú)
  end
  DVC --- U06 & U08 & U11
  P4 --- U07 & U08
  CB --- U10 & U11 & U12 & U13
  TO --- U06 & U13 & U14 & U15 & U16 & U17
  U09 --- CB
```

Hình cho thấy cán bộ chỉ tham gia trực tiếp ở việc người dùng, còn bước tự động và sự kiện đi qua PH-04, PH-10; Cổng DVC chạm khởi tạo phiên, thông điệp tương quan và báo đã bổ sung hồ sơ.

```{.mermaid caption="Use case Saga bù trừ, tiến độ, giám sát, quản trị và kiểm toán"}
flowchart TB
  TO([TA, TO])
  AU([AU, VW])
  DVC[[Cổng DVC, PH-01]]
  P13[[PH-13, PH-03]]
  subgraph SG["Saga bù trừ"]
    U18(UC-11-18 Điều phối bù trừ)
    U19(UC-11-19 Nhật ký, xử lý thủ công, đối soát)
  end
  subgraph TD["Tiến độ, giám sát, quản trị, kiểm toán"]
    U20(UC-11-20 Tra tiến độ cho DVC)
    U21(UC-11-21 Giám sát, tắc nghẽn, báo cáo hạn)
    U22(UC-11-22 Sự cố engine)
    U23(UC-11-23 Cảnh báo, tham số, lưu giữ)
    U24(UC-11-24 Kiểm toán, bằng chứng tuân thủ)
  end
  TO --- U18 & U19 & U21 & U22 & U23
  AU --- U19 & U21 & U24
  DVC --- U20
  P13 --- U21 & U23 & U24
```

Hình cho thấy vận hành là tác nhân của hầu hết use case ở đây, kiểm toán chỉ đọc và xuất, Cổng DVC chỉ tra tiến độ đã che; PH-13 nhận chỉ số, cảnh báo và giữ kho kiểm toán.

## 5. Bảng tổng hợp use case và truy vết

Danh sách chính thức 24 use case. Bảng 5.3 là nguồn mục "Truy vết", bảng 5.2 là nguồn mục "Màn hình, API" của từng khối. Cột LGC chỉ ghi ba chức năng liên quan gián tiếp.

### 5.1. Use case và FR

Bảng liệt kê 24 use case, tác nhân chính, mức ưu tiên cao nhất trong các FR của use case và FR hiện thực (số đuôi của `FR-11-nnn`). Cả 48 FR mức M, 16 FR mức S và 2 FR mức C đều thuộc ít nhất một use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-11-01 | Tạo mô hình, phiên bản nháp, so sánh, nhập, xuất, mẫu dùng chung | IE, PA | M | 001, 002, 006, 010, 015 |
| UC-11-02 | Thiết kế sơ đồ BPMN, cấu hình bước, kiểm tra tĩnh, chạy thử | IE | M | 003, 004, 005, 011 |
| UC-11-03 | Khai báo biến, biểu mẫu việc, bảng quyết định | IE | M | 012, 016, 017 |
| UC-11-04 | Đăng ký ý định nghiệp vụ và hành động bù trừ | IE | M | 013, 014 |
| UC-11-05 | Gửi duyệt, duyệt phát hành bốn mắt, ngừng dùng, thu hồi phiên bản | IE, IA | M | 007, 008, 009 |
| UC-11-06 | Khởi tạo phiên từ Cổng DVC, sự kiện PH-10 hoặc thủ công | Cổng DVC, HTTT, PH-10, TO | M | 018, 019, 020 |
| UC-11-07 | Thực thi bước tự động qua PH-04 và nhận kết quả | PH-04 | M | 028, 029 |
| UC-11-08 | Chờ thông điệp, hẹn giờ, gửi thông báo, gọi quy trình con | Hệ thống, Cổng DVC | M | 030, 031, 032, 033 |
| UC-11-09 | Tạo việc, phân công, đưa vào hộp Việc của tôi | Hệ thống | M | 034, 035 |
| UC-11-10 | Nhận việc, xem hồ sơ, hoàn thành việc, lưu nháp, gợi ý AI | CB | M | 036, 037, 038, 039, 066 |
| UC-11-11 | Trả về bước trước, yêu cầu bổ sung hồ sơ, tạm dừng tính hạn | CB | M | 044, 049 |
| UC-11-12 | Chuyển việc, trao đổi ý kiến, đính kèm tệp | CB | M | 040, 043 |
| UC-11-13 | Ủy quyền khi vắng mặt, phân công lại hàng loạt | CB, TA, TO | S | 041, 042 |
| UC-11-14 | Lịch làm việc, tính hạn, nhắc hạn, leo thang quá hạn | TA, hệ thống | M | 045, 046, 047, 048 |
| UC-11-15 | Tra cứu và xem chi tiết phiên | TO, TA, AU, CB | M | 021, 022 |
| UC-11-16 | Tạm dừng, tiếp tục, hủy phiên | TO, TA | M | 023, 024 |
| UC-11-17 | Can thiệp phiên có duyệt: sửa biến, chuyển bước, di trú | TA | S | 025, 026, 027 |
| UC-11-18 | Điều phối bù trừ Saga khi lỗi bước | Hệ thống | M | 051 |
| UC-11-19 | Nhật ký Saga, xử lý bù trừ thủ công, đối soát định kỳ | TO, TA | M | 052, 053, 054 |
| UC-11-20 | Tra tiến độ cho Cổng DVC và phát sự kiện tiến độ | Cổng DVC | M | 055, 056 |
| UC-11-21 | Giám sát, phát hiện tắc nghẽn, báo cáo đúng hạn, trễ hạn | TO, TA, VW | M | 058, 059, 050 |
| UC-11-22 | Xử lý sự cố engine và thử lại | TO, TA | M | 060 |
| UC-11-23 | Cấu hình cảnh báo, tham số 11.*, lưu giữ | TA | M | 061, 062, 063 |
| UC-11-24 | Kiểm toán lịch sử bước, nhật ký, bằng chứng tuân thủ BPMN 2.0 | AU, TA | M | 057, 064, 065 |

: Use case và FR hiện thực

### 5.2. Use case, màn hình, API và kiểm thử

UC-11-20 là use case máy với máy, không có màn riêng (xem ở UI-11-12, UI-11-19); kịch bản `TS-11-nn` ứng với `UC-11-nn`.

| UC | Màn hình | API |
|---|---|---|
| UC-11-01 | UI-11-01, 02, 03, 05, 10 | API-11-001…005, 007, 008, 009, 015, 024, 041…043 |
| UC-11-02 | UI-11-04, 06 | API-11-009…014, 025…029, 034, 136 |
| UC-11-03 | UI-11-04, 08 | API-11-029…033, 044…048 |
| UC-11-04 | UI-11-09, 04 | API-11-034…040 |
| UC-11-05 | UI-11-04, 03, 07 | API-11-006, 016…023, 131 |
| UC-11-06 | UI-11-13, 04 | API-11-049, 052, 126, 127 |
| UC-11-07 | UI-11-12, 20 | API-11-070, 071 |
| UC-11-08 | UI-11-04, 12, 20 | API-11-069 |
| UC-11-09 | /viec-cua-toi, UI-11-15 | API-11-072, 125 |
| UC-11-10 | UI-11-15, 07 | API-11-072…077, 124 |
| UC-11-11 | UI-11-15, 12 | API-11-087, 088, 089 |
| UC-11-12 | UI-11-15 | API-11-078, 083…086 |
| UC-11-13 | UI-11-16, 17 | API-11-079…082 |
| UC-11-14 | UI-11-18, 12, 15, 19 | API-11-090…093 (nhắc hạn, quá hạn không có API riêng) |
| UC-11-15 | UI-11-11, 12 | API-11-050…055, 070, 128 |
| UC-11-16 | UI-11-12 | API-11-056, 057, 058 |
| UC-11-17 | UI-11-12, 14 | API-11-059…068 |
| UC-11-18 | UI-11-12, 21 | API-11-098 |
| UC-11-19 | UI-11-21 | API-11-096…103, 129, 132, 133 |
| UC-11-20 | Không (API, sự kiện) | API-11-104 |
| UC-11-21 | UI-11-19, 22 | API-11-094, 095, 107, 108 |
| UC-11-22 | UI-11-20 | API-11-109…113 |
| UC-11-23 | UI-11-23 | API-11-114…120, 134, 135 |
| UC-11-24 | UI-11-12, 23 | API-11-105, 106, 121, 122, 123, 130, 137 |

: Use case, màn hình và API

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

Bảng nối use case về BRD, quy trình D02-01 và chức năng hệ cũ. Chỉ LGC-NGSP-002 (hộ tịch: đăng ký, tra trạng thái hồ sơ), LGC-NGSP-004 (đồng bộ hồ sơ thủ tục cấp mã ĐVQHNS) và LGC-BUS-037 (xử lý lỗi, thực hiện lại hoặc bỏ qua) liên quan; kết luận của FRS §11.1 là nâng cấp ở mức điều phối, phần gọi hệ thống giữ nguyên ở PH-14, PH-04.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-11-01 | REQ-11, REQ-20 | BP-02 | Không (năng lực mới) |
| UC-11-02 | REQ-11, REQ-04 | BP-02 | Không (năng lực mới) |
| UC-11-03 | REQ-11, REQ-21, REQ-09 | BP-02 | Không |
| UC-11-04 | REQ-11, REQ-04 | BP-02 | LGC-BUS-037 (gián tiếp) |
| UC-11-05 | REQ-11 | BP-02 | Không |
| UC-11-06 | REQ-11, REQ-10 | BP-01, BP-03 | LGC-NGSP-002 |
| UC-11-07 | REQ-11, REQ-04 | BP-06 | LGC-NGSP-002, LGC-BUS-037 |
| UC-11-08 | REQ-11, REQ-10, REQ-04 | BP-01, BP-06 | Không |
| UC-11-09 | REQ-11, REQ-12, REQ-21 | BP-01 | Không |
| UC-11-10 | REQ-11, REQ-21, REQ-17 | BP-01 | Không |
| UC-11-11 | REQ-11 | BP-01 | LGC-NGSP-002 (gián tiếp) |
| UC-11-12 | REQ-11, REQ-21 | BP-01 | Không |
| UC-11-13 | REQ-11, REQ-12 | BP-01 | Không |
| UC-11-14 | REQ-11 | BP-01, BP-07 | LGC-NGSP-004 (gián tiếp) |
| UC-11-15 | REQ-11 | BP-07 | LGC-NGSP-002 |
| UC-11-16 | REQ-11 | BP-06 | LGC-BUS-037 (gián tiếp) |
| UC-11-17 | REQ-11 | BP-07 | LGC-BUS-037 |
| UC-11-18 | REQ-11 | BP-06, BP-07 | LGC-BUS-037 (gián tiếp) |
| UC-11-19 | REQ-11 | BP-07 | LGC-BUS-037 |
| UC-11-20 | REQ-11, REQ-10 | BP-01 | LGC-NGSP-002 |
| UC-11-21 | REQ-11, REQ-13, REQ-16 | BP-07 | Không |
| UC-11-22 | REQ-11, REQ-18 | BP-07 | LGC-BUS-037 |
| UC-11-23 | REQ-11, REQ-18, REQ-20, REQ-13 | BP-07 | Không |
| UC-11-24 | REQ-11, REQ-13 | BP-07 | Không |

: Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực. Không FR nào bị bỏ trống. FR-11-010 ở UC-11-01 (nhập, xuất), FR-11-056 ở UC-11-20 và FR-11-050 ở UC-11-21 cùng giám sát.

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 01 | 023 | 16 | 045 | 14 |
| 002 | 01 | 024 | 16 | 046 | 14 |
| 003 | 02 | 025 | 17 | 047 | 14 |
| 004 | 02 | 026 | 17 | 048 | 14 |
| 005 | 02 | 027 | 17 | 049 | 11 |
| 006 | 01 | 028 | 07 | 050 | 21 |
| 007 | 05 | 029 | 07 | 051 | 18 |
| 008 | 05 | 030 | 08 | 052 | 19 |
| 009 | 05 | 031 | 08 | 053 | 19 |
| 010 | 01 | 032 | 08 | 054 | 19 |
| 011 | 02 | 033 | 08 | 055 | 20 |
| 012 | 03 | 034 | 09 | 056 | 20 |
| 013 | 04 | 035 | 09 | 057 | 24 |
| 014 | 04 | 036 | 10 | 058 | 21 |
| 015 | 01 | 037 | 10 | 059 | 21 |
| 016 | 03 | 038 | 10 | 060 | 22 |
| 017 | 03 | 039 | 10 | 061 | 23 |
| 018 | 06 | 040 | 12 | 062 | 23 |
| 019 | 06 | 041 | 13 | 063 | 23 |
| 020 | 06 | 042 | 13 | 064 | 24 |
| 021 | 15 | 043 | 12 | 065 | 24 |
| 022 | 15 | 044 | 11 | 066 | 10 |

: Ma trận FR và use case (số đuôi của UC-11-nn)


## 6. Đặc tả chi tiết use case

Chương này là phần chính của tài liệu: 24 khối đặc tả, gom theo mục tiêu của tác nhân. Năm use case đầu thuộc vòng đời mô hình, từ lúc kỹ sư tạo mô hình đến lúc phiên bản được phát hành, ngừng dùng hoặc chia sẻ thành mẫu.

### 6.1. UC-11-01 · Tạo mô hình, quản lý phiên bản nháp, so sánh, nhập, xuất và mẫu dùng chung

Mọi quy trình bắt đầu từ một mô hình có bản nháp; Nam tạo `LT_KHAI_SINH` từ mẫu, tạo nháp mới, so sánh và xuất gói.

::: dac-ta
**Mục tiêu.** Kỹ sư có mô hình mới hoặc bản nháp kế tiếp mà không làm đổi bản đang phát hành, so sánh được đúng chỗ khác và trao đổi mô hình theo chuẩn mở BPMN 2.0.

**Tác nhân chính.** IE (Nam); PA (Hà) cho mẫu dùng chung.

**Tác nhân phụ.** TA; PH-07; kho đối tượng và dịch vụ quét mã độc.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-001, FR-11-002, FR-11-006, FR-11-010, FR-11-015.

**Truy vết.** REQ-11, REQ-20; BP-02; CMP-LAW-09 cho nhập, xuất BPMN.

**Tiền điều kiện.** Nam có `PERM-11-model` và `PERM-11-read`; đã chọn tenant `T68`; với "từ mẫu", mẫu ở `PUBLISHED`.

**Kích hoạt.** Nam bấm "+ Tạo mô hình" ở UI-11-01, hoặc "Tạo bản nháp từ phiên bản này", "So sánh", "Xuất" ở UI-11-03.

**Đảm bảo tối thiểu.** Lỗi ở bất kỳ bước nào thì không tạo mô hình hay phiên bản; bản `PUBLISHED` không bị sửa (BR-11-005).

**Đảm bảo thành công.** Có `process_model` và phiên bản `DRAFT` đã kiểm tra tĩnh lần đầu, khóa soạn thảo thuộc Nam.

**Luồng chính.**
1. Nam mở UI-11-01, gõ "khai sinh"; sau 300 ms giao diện gọi API-11-001, hệ thống trả mô hình khớp kèm số phiên đang chạy.
2. Nam bấm "+ Tạo mô hình" (UI-11-02), chọn "Từ mẫu" `MAU_LIEN_THONG_3_CO_QUAN`, nhập `processKey` = `LT_KHAI_SINH`, tên "Liên thông khai sinh, thường trú, BHYT trẻ dưới 6 tuổi", nhóm `TTHC_LIEN_THONG`, hạn mặc định 5 ngày làm việc.
3. Hệ thống kiểm mã theo mẫu (ERR-11-003) và chưa dùng (ERR-11-002), sao chép XML, biến, cấu hình bước của mẫu và đổi `id` tiến trình thành `LT_KHAI_SINH`.
4. Hệ thống tạo phiên bản 1 `DRAFT`, chạy kiểm tra tĩnh lần đầu, ghi kiểm toán, trả `201` và mở UI-11-04 (UC-11-02).
5. Sau khi v1 đã phát hành, Nam vào UI-11-03 thẻ "Phiên bản", bấm "Tạo bản nháp từ phiên bản này"; hệ thống kiểm chưa có nháp đang mở (ERR-11-006), sao chép thành v2 `DRAFT` kèm `basedOn` = 1.
6. Nam bấm "So sánh" v2 với v1 (UI-11-05); hệ thống trả danh sách phần tử thêm, xóa, đổi thuộc tính, biến, bù trừ khác nhau và hai XML để tô màu trên hai khung vẽ đồng bộ thu phóng.
7. Nam bấm "Xuất", chọn gói `.zip`; hệ thống sinh `manifest.json`, `process.bpmn`, `variables.json`, `forms/`, `compensations.json` kèm checksum từng tệp.

**Luồng thay thế.**
- **2b. Nhập tệp.** Nam kéo `lt-khai-sinh.bpmn` vào vùng tải (API-11-004): hệ thống quét mã độc, kiểm XSD và kích thước, loại `scriptTask` và thuộc tính gọi bean ngoài danh sách cho phép, đối chiếu ý định, biểu mẫu trong gói với tenant; tệp thiếu tọa độ được tự bố cục. Tiếp tục bước 4.

- **7a. Mẫu dùng chung.** Hà (PA) chọn phiên bản nguồn không lỗi `ERROR` ở UI-11-10, đánh dấu ý định, nhóm ứng viên là chỗ trống `{{…}}`, lưu `process_template` `DRAFT` rồi gửi phát hành; PA thứ hai duyệt (LP-11-01) và mẫu hiện ở mục "Từ mẫu" (API-11-041, 042, 043). TA lập mẫu riêng của tỉnh theo cách này.

**Luồng ngoại lệ.**
- **E1. Mã đã dùng (bước 3).** ERR-11-002 (409): "Mã quy trình {processKey} đã được dùng. Chọn mã khác."
- **E2. Mã sai mẫu (bước 3).** ERR-11-003 (400): "Mã quy trình chỉ gồm chữ in hoa, số và dấu gạch dưới, 3 đến 64 ký tự."
- **E4. XML sai chuẩn (2b).** ERR-11-008 (400): "Tệp không đúng BPMN 2.0 tại dòng {dòng}: {mô tả}."
- **E6. Tệp có mã độc (2b).** ERR-11-027 (422): "Tệp không an toàn và đã bị từ chối."
- **E7. Gói tham chiếu ý định chưa có (2b, chế độ `FAIL`).** ERR-11-011 (422): "Gói tham chiếu {n} ý định chưa có ở tỉnh: {danh sách}."
- **E8. Đã có bản nháp (bước 5).** ERR-11-006 (409): "Mô hình đang có bản nháp v{n} của {người}. Mở bản đó hoặc xóa trước khi tạo bản mới."

- **E10. Tỉnh sửa mẫu `COMMON` (7a).** ERR-11-036 (403): "Mẫu dùng chung chỉ quản trị nền tảng được sửa. Sao chép thành mô hình của tỉnh để chỉnh."
- **E11. Tự phát hành mẫu (7a).** ERR-11-005 (403): "Anh/chị đã tạo mẫu này nên không được tự phát hành."

**Quy tắc áp dụng.** BR-11-005, BR-11-027, BR-11-031; LP-11-03.

**Màn hình, API.** UI-11-01, UI-11-02, UI-11-03, UI-11-05, UI-11-10; API-11-001…005, 007, 008, 009, 015, 024, 041…043; kịch bản TS-11-01.
:::

### 6.2. UC-11-02 · Thiết kế sơ đồ BPMN, cấu hình thuộc tính bước, kiểm tra tĩnh và chạy thử

Nam vẽ sơ đồ trên bpmn-js, cấu hình từng bước và sửa theo kết quả kiểm tra tĩnh (đề xuất ADR 111).

::: dac-ta
**Mục tiêu.** Nam dựng được sơ đồ `LT_KHAI_SINH` đúng chuẩn BPMN 2.0, mỗi bước có đủ thuộc tính để engine chạy, biết ngay lỗi làm phiên treo hoặc sai, và chạy thử được trước khi gửi duyệt.

**Tác nhân chính.** IE (Nam).

**Tác nhân phụ.** TA; PH-04; PH-12; người khác mở ở chế độ chỉ xem.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-003, FR-11-004, FR-11-005, FR-11-011.

**Truy vết.** REQ-11; BP-02; CMP-LAW-09.

**Tiền điều kiện.** Phiên bản `DRAFT`; Nam có `PERM-11-model`; khóa soạn thảo đang trống hoặc của Nam.

**Kích hoạt.** Nam mở UI-11-04 từ UI-11-01 hoặc UI-11-03.

**Đảm bảo tối thiểu.** Phần chưa lưu giữ trong bộ nhớ tạm khi mất kết nối; không lưu XML hỏng; người khác không ghi đè bản đang khóa.

**Đảm bảo thành công.** Bản nháp lưu XML hợp lệ, `checksum` mới, `validationSummary` cập nhật; không còn lỗi `ERROR` thì sẵn sàng gửi duyệt.

**Luồng chính.**
1. Hệ thống cấp khóa soạn thảo cho Nam, hết hạn sau `11.designer.lockMinutes` phút không thao tác; hiện logo bpmn.io ở góc phải dưới khung vẽ.
2. Nam kéo phần tử từ bảng phần tử: sự kiện bắt đầu, việc "Thẩm định hồ sơ", bước tự động `guiTuPhap`, cổng song song, `guiCuTru`, `capTheBHYT`, hẹn giờ biên, sự kiện kết thúc; nối luồng, đặt nhãn tiếng Việt.
3. Giao diện tự lưu theo `11.designer.autosaveSeconds` (mặc định 30 giây); hệ thống kiểm XML hợp lệ XSD, kích thước và `ETag` rồi lưu.
4. Nam chọn `capTheBHYT`; bảng thuộc tính mở theo loại phần tử: ý định `capTheBHYT`, ánh xạ biến vào ra, `timeout`, lỗi nghiệp vụ `BHXH_TU_CHOI` đi nhánh bù trừ, tên công khai "Cấp thẻ BHYT".
5. Hệ thống kiểm ý định tồn tại, biểu mẫu đã phát hành, biến đã khai báo, rồi chạy kiểm tra tĩnh nhanh cho phần tử và các nhánh liên quan; giao diện tô viền đỏ, vàng phần tử lỗi.
6. Nam bấm "Kiểm tra": hệ thống chạy bộ quy tắc đầy đủ `FULL`, gồm ánh xạ ý định sang luồng PH-04 đã phát hành trên môi trường đích và bù trừ cho bước ghi ngoài; trả `blocking`, `errors[]` theo `elementId`.
7. Nam bấm một dòng ở ngăn "Kết quả kiểm tra"; giao diện nhảy tới phần tử lỗi để sửa, lặp lại đến khi `blocking = false`; sau đó nhả khóa khi thoát.

8. Nam bấm "Chạy thử" (UI-11-06): hệ thống triển khai bản nháp không còn lỗi `ERROR` vào engine với `tenantId` = `T68-test`, khởi tạo phiên cờ `isTest`; bước tự động chạy theo kịch bản giả lập (ví dụ `capTheBHYT` trả `BHXH_TU_CHOI`), không có lệnh tới PH-04, không outbox (BR-11-036).
9. Ở chế độ `ACCELERATED` hẹn giờ và hạn chạy ngay; hệ thống ghi dòng thời gian, biến, việc, nhánh bù trừ rồi đặt `test_run` `PASSED` hoặc `FAILED`; dữ liệu thử dọn sau `11.test.retentionDays` ngày (API-11-025, 026).

**Luồng thay thế.**
- **1a. Người khác đang giữ khóa.** Nam mở ở chế độ chỉ xem, băng thông báo người giữ và giờ bắt đầu; bấm "Yêu cầu quyền sửa" (API-11-136) thì người giữ nhận thông báo (EVT-11-20), khóa không tự nhả.
- **2a. Dán XML hoặc kéo tệp `.bpmn` vào khung vẽ.** Hệ thống hỏi xác nhận rồi thay toàn bộ sơ đồ, giữ cấu hình bước trùng `elementId`.
- **6a. Cảnh báo `WARNING`.** Nam đánh dấu bỏ qua kèm lý do; lý do hiện cho người duyệt ở UC-11-05. Lỗi `ERROR` không bỏ qua được.

- **8a. Chạy từng bước.** Nam bấm "Bước tiếp" (API-11-027) và sửa kết quả giả lập giữa chừng; treo quá 10 phút thì `test_run` `FAILED`.

**Luồng ngoại lệ.**
- **E1. Người khác giữ khóa (bước 3).** ERR-11-016 (409): "{người} đang sửa bản nháp này từ {giờ}. Bạn đang ở chế độ chỉ xem."
- **E2. Xung đột phiên bản (bước 3).** ERR-11-004 (409): "Bản nháp đã được lưu ở nơi khác. Tải lại để xem bản mới, phần chưa lưu được giữ trong bộ nhớ tạm."
- **E3. XML hỏng (bước 3).** ERR-11-008 (400): "Sơ đồ không đúng chuẩn BPMN 2.0 tại dòng {dòng}: {mô tả}."
- **E5. Ý định không tồn tại hoặc ngừng dùng (bước 5).** ERR-11-011 (422): "Ý định {intentCode} không tồn tại hoặc đã ngừng dùng. Chọn ý định khác ở danh mục."
- **E7. Biểu thức dùng biến chưa khai báo (bước 5).** ERR-11-015 (422): "Biến {tên} chưa khai báo. Thêm ở thẻ Biến hoặc sửa biểu thức."
- **E8. Luồng PH-04 chưa kiểm được (bước 6).** ERR-11-012 (422): "Chưa kiểm được luồng PH-04 cho ý định {intentCode}. Thử lại sau ít phút."

- **E9. Thiếu kết quả giả lập (bước 8).** ERR-11-042 (422): "Chưa có kết quả giả lập cho bước {tên}. Nhập kết quả hoặc chọn mặc định Hoàn thành."

**Quy tắc áp dụng.** BR-11-001, BR-11-002, BR-11-003, BR-11-005, BR-11-008, BR-11-014, BR-11-015, BR-11-019, BR-11-034, BR-11-035, BR-11-036; LP-11-03.

**Màn hình, API.** UI-11-04, UI-11-06; API-11-009…014, 025…029, 034, 136; kịch bản TS-11-02.
:::

### 6.3. UC-11-03 · Khai báo biến, biểu mẫu việc và bảng quyết định

Biến quyết định dữ liệu nào được mã hóa hoặc che, nên khai sai là rủi ro bảo mật chứ không chỉ lỗi cấu hình.

::: dac-ta
**Mục tiêu.** Nam khai biến có phân loại dữ liệu đúng, dựng biểu mẫu JSON Schema cho việc "Thẩm định hồ sơ khai sinh" và (tùy chọn) bảng quyết định chọn cấp duyệt, để DLCN không lọt vào sự kiện, thông báo, nhật ký.

**Tác nhân chính.** IE (Nam).

**Tác nhân phụ.** TA; PH-09; PH-07.

**Mức ưu tiên.** M · Đợt 2 (bảng quyết định mức C).

**FR hiện thực.** FR-11-012, FR-11-016, FR-11-017.

**Truy vết.** REQ-11, REQ-21, REQ-09; BP-02.

**Tiền điều kiện.** Phiên bản mô hình `DRAFT` cho biến; biểu mẫu mới có `formKey` chưa dùng hoặc sửa trên phiên bản biểu mẫu `DRAFT`.

**Kích hoạt.** Nam mở thẻ "Biến" ở UI-11-04, hoặc "+ Biểu mẫu" ở UI-11-08, hoặc "Mở bảng quyết định" trên `BUSINESS_RULE_TASK`.

**Đảm bảo tối thiểu.** Biến `SENSITIVE` không bao giờ lưu không mã hóa; biểu mẫu đã phát hành không sửa tại chỗ (BR-11-005).

**Đảm bảo thành công.** `variable_definition`, `form_definition`, `decision_table` được lưu; `SENSITIVE` có `encrypt = true`, `RESTRICTED` có `mask = true`.

**Luồng chính.**
1. Nam mở thẻ "Biến" và bấm "Lấy từ hợp đồng ý định"; hệ thống gợi ý biến `maXa`, `hoTenTre`, `ngaySinhTre`, `soDinhDanhMe` từ `inputSchema`.
2. Hệ thống đề xuất phân loại theo từ điển trường của PH-09: `soDinhDanhMe` là `SENSITIVE`, `hoTenTre` là `RESTRICTED`, `maXa` là `INTERNAL`; Nam xác nhận.
3. Hệ thống kiểm tên biến duy nhất, không trùng biến hệ thống `businessKey`, `initiator`, `tenantId`, rồi lưu.
4. Nam mở UI-11-08, bấm "+ Biểu mẫu", đặt `formKey` = `FORM_THAM_DINH_KHAI_SINH`, kéo các trường (kết quả thẩm định, ghi chú, quyết định) và xem trước bằng đúng thành phần của UI-11-15.
5. Hệ thống kiểm schema hợp lệ, không `$ref` ra ngoài, trường gắn `SENSITIVE` có biến mã hóa; Nam bấm "Phát hành", phiên bản biểu mẫu thành `PUBLISHED` bất biến.
6. (Mức C) Nam mở bảng quyết định cấp duyệt theo `loaiTTHC`; hệ thống kiểm biểu thức đơn giản, kiểm không chồng lấn, Nam bấm "Thử" với giá trị mẫu.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Bỏ mã hóa biến `SENSITIVE` (bước 3).** ERR-11-015 (422): "Biến {tên} chứa dữ liệu nhạy cảm nên bắt buộc mã hóa."
- **E2. Trùng tên biến hệ thống (bước 3).** ERR-11-003 (400): "Tên {tên} là biến hệ thống, chọn tên khác."
- **E3. Schema sai (bước 5).** ERR-11-003 (400): "Biểu mẫu không hợp lệ tại {đường dẫn}: {mô tả}."
- **E5. Sửa bản đã phát hành tại chỗ (bước 5).** ERR-11-006 (409): "Biểu mẫu v{n} đã phát hành. Tạo bản mới để sửa."
- **E6. Quy tắc quyết định chồng lấn (bước 6).** ERR-11-040 (422): "Dòng {a} và {b} cùng khớp một trường hợp trong khi chính sách là UNIQUE."

**Quy tắc áp dụng.** BR-11-005, BR-11-014, BR-11-015; LP-11-03.

**Màn hình, API.** UI-11-04 thẻ Biến, UI-11-08; API-11-029…033, 044, 045, 046…048; kịch bản TS-11-03.
:::

### 6.4. UC-11-04 · Đăng ký ý định nghiệp vụ và hành động bù trừ

Sơ đồ chỉ nói gọi `capTheBHYT`; ý định ánh xạ sang luồng PH-04, còn mỗi bước ghi ra ngoài phải có cách bù trừ.

::: dac-ta
**Mục tiêu.** Nam đặt tên ý định, khai hợp đồng vào ra và luồng PH-04 từng môi trường; gắn cho mỗi bước ghi ngoài một hành động bù trừ do nghiệp vụ định nghĩa hoặc đề nghị miễn có lý do.

**Tác nhân chính.** IE (Nam).

**Tác nhân phụ.** PH-04; IA; TA.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-013, FR-11-014.

**Truy vết.** REQ-11, REQ-04; BP-02; LGC-BUS-037 (thực hiện lại, bỏ qua) liên quan gián tiếp.

**Tiền điều kiện.** Luồng PH-04 đích tồn tại ở danh mục luồng của tenant; bước xuôi là service task có ý định.

**Kích hoạt.** Nam bấm "+ Ý định" ở UI-11-09 thẻ "Ý định", hoặc mở nhóm "Bù trừ" trong bảng thuộc tính bước ở UI-11-04.

**Đảm bảo tối thiểu.** Đổi ánh xạ ý định không đổi phiên bản đã phát hành; ý định đang được bản `PUBLISHED` tham chiếu không bị ngừng.

**Đảm bảo thành công.** `service_intent` `ACTIVE` có ánh xạ từng môi trường; mỗi bước rủi ro có bù trừ hoặc miễn `NONE_APPROVED` chờ duyệt.

**Luồng chính.**
1. Nam mở UI-11-09, bấm "+ Ý định", nhập mã `capTheBHYT`, tên "Cấp thẻ BHYT cho trẻ dưới 6 tuổi", hợp đồng vào ra và chọn luồng PH-04 cho `TEST`, `STAGING`, `PROD`.
2. Hệ thống kiểm mã chưa dùng, schema hợp lệ, gọi danh mục luồng PH-04 kiểm luồng tồn tại và hợp đồng vào tương thích `inputSchema`, rồi lưu ý định `ACTIVE`.
3. Nam mở thẻ "Bù trừ" cho bước `capTheBHYT`, chọn chính sách `AUTO`, ý định bù trừ `huyTheBHYT`, ghi chú "Hủy thẻ chưa phát hành; thẻ đã phát hành chuyển xử lý thủ công".
4. Hệ thống kiểm ý định bù trừ khác ý định xuôi và tồn tại, ghi chú đủ dài; sinh `COMPENSATION_BOUNDARY` gắn bước xuôi và service task bù trừ trong XML.
5. Với `guiTuPhap` (văn bản hộ tịch đã phát hành, không xóa được), Nam chọn `MANUAL` và ý định `danhDauChoXuLy` kèm ghi chú "Không xóa, đánh dấu chờ xử lý" (BR-11-009).
6. Nam xem danh sách ý định và ánh xạ ở thẻ "Ý định" để đối chiếu môi trường chưa có luồng.

**Luồng thay thế.**
- **3a. Miễn bù trừ.** Nam chọn `NONE_APPROVED`; hệ thống tạo đề nghị miễn trong `publish_request` của lần phát hành kế tiếp, người duyệt thấy riêng từng miễn và quyết định từng miễn qua `waiverDecisions[]` của API-11-020 (khác người đề nghị, ERR-11-005).

**Luồng ngoại lệ.**
- **E1. Luồng chưa phát hành ở môi trường chính thức (bước 2).** ERR-11-012 (422): "Luồng {flowCode} chưa được phát hành ở môi trường {env}. Phát hành luồng ở PH-04 trước."
- **E2. Hợp đồng không khớp (bước 2).** ERR-11-003 (400): "Trường {tên} của ý định không có ở đầu vào luồng {flowCode}."
- **E4. Bù trừ trỏ chính bước xuôi (bước 4).** ERR-11-044 (422): "Hành động bù trừ phải khác hành động của bước {tên}."
- **E5. Thiếu ghi chú (bước 3).** ERR-11-007 (422): "Nhập ghi chú nghiệp vụ giải thích cách bù trừ (tối thiểu 20 ký tự)."

**Quy tắc áp dụng.** BR-11-002, BR-11-003, BR-11-008, BR-11-009, BR-11-010; LP-11-02.

**Màn hình, API.** UI-11-09, UI-11-04 nhóm "Bù trừ"; API-11-034…040; kịch bản TS-11-04.
:::

### 6.5. UC-11-05 · Gửi duyệt, duyệt phát hành bốn mắt, ngừng dùng và thu hồi phiên bản

Hai người khác nhau chịu trách nhiệm cho mọi phát hành: Nam gửi, Hạnh duyệt; ngừng dùng và thu hồi qua cùng cổng `PERM-11-publish`.

::: dac-ta
**Mục tiêu.** Một phiên bản mô hình chỉ có hiệu lực cho hồ sơ mới khi người thứ hai có thẩm quyền xem đúng bản đã gửi, so với bản đang chạy, rồi đồng ý; ngừng dùng bản cũ không làm gián đoạn hồ sơ đang xử lý.

**Tác nhân chính.** IE (Nam, người gửi), IA (Hạnh, người duyệt).

**Tác nhân phụ.** TA; Flowable; hộp "Việc của tôi"; PH-13, PH-10.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-007, FR-11-008, FR-11-009.

**Truy vết.** REQ-11; BP-02; FR-00-071, FR-00-072, ADR-046; đề xuất ADR 110 cho triển khai lên engine.

**Tiền điều kiện.** Bản nháp `DRAFT` do Nam gửi, không còn lỗi `ERROR`, có ghi chú thay đổi; Hạnh có `PERM-11-publish`, khác Nam và khác người sửa cuối.

**Kích hoạt.** Nam bấm "Gửi duyệt" ở UI-11-04; Hạnh mở việc duyệt từ "Việc của tôi" (UI-11-07); Hạnh hoặc TA mở thẻ "Phiên bản" ở UI-11-03 để ngừng dùng.

**Đảm bảo tối thiểu.** Triển khai lỗi thì hoàn lại, bản cũ vẫn `PUBLISHED`; không có hai bản `PUBLISHED` hay bản đã duyệt mà chưa lên engine.

**Đảm bảo thành công.** Đúng một bản `PUBLISHED` với `deploymentId` đúng `tenantId`, bản cũ `DEPRECATED`, EVT-11-01 đã vào outbox; hồ sơ đang xử lý giữ phiên bản cũ (BR-11-006).

**Luồng chính.**
1. Nam bấm "Gửi duyệt" v3, nhập ghi chú thay đổi (≥ 10 ký tự); hệ thống chạy kiểm tra tĩnh `FULL`.
2. Hệ thống chuyển v3 sang `IN_REVIEW`, nhả khóa soạn thảo, tạo `publish_request` `PENDING` gồm checksum, kết quả kiểm tra, cảnh báo đã bỏ qua; khởi tạo quy trình `DUYET_PHAT_HANH_MO_HINH` và đăng ký việc duyệt vào "Việc của tôi" của nhóm có `PERM-11-publish`.
3. Hạnh mở UI-11-07; hệ thống hiện khác biệt với bản `PUBLISHED`, kết quả kiểm tra, cảnh báo đã bỏ qua kèm lý do, miễn bù trừ chờ duyệt.
4. Hạnh nhập ý kiến, quyết định từng miễn bù trừ, bấm "Duyệt" (`waiverDecisions[]`); hệ thống kiểm Hạnh khác Nam và khác `updatedBy` cuối (LP-11-01), kiểm ý kiến (LP-11-02).
5. Hệ thống kiểm checksum chưa đổi, chạy lại kiểm tra tĩnh `FULL`, triển khai bằng `createDeployment()` với `tenantId` = `T68`, tên `LT_KHAI_SINH:v3`.
6. Trong cùng giao dịch hệ thống đặt v3 `PUBLISHED`, v2 `DEPRECATED`, `publish_request` `APPROVED`, ghi outbox EVT-11-01 và EVT-11-10 (việc duyệt hoàn thành); báo Nam.
7. Khi v2 hết phiên chạy, Hạnh bấm "Thu hồi" v2; hệ thống kiểm không còn phiên chưa kết thúc, đặt `RETIRED`, ghi EVT-11-02.

**Luồng thay thế.**
- **2a. Rút lại.** Nam bấm "Rút lại" khi chưa ai duyệt (API-11-017): `publish_request` `WITHDRAWN`, v3 về `DRAFT`, việc duyệt `CANCELLED`.
- **4a. Từ chối.** Hạnh chọn "Từ chối" kèm lý do ≥ 20 ký tự (API-11-021): v3 về `DRAFT`, `publish_request` `REJECTED`, việc báo cho Nam.
- **5a. Engine từ chối XML.** Giao dịch hoàn lại, `publish_request` `DEPLOY_FAILED`, v3 về `DRAFT` kèm mô tả lỗi, bản cũ vẫn `PUBLISHED`.
- **7a. Ngừng dùng thay vì thu hồi.** Hạnh bấm "Ngừng dùng" bản `PUBLISHED` (API-11-022): hồ sơ mới không vào bản này, chỉ khi còn bản `PUBLISHED` khác hoặc đã xác nhận ngừng bản duy nhất; bản `DEPRECATED` khôi phục về `PUBLISHED` bằng `RESTORE` (API-11-131) khi mô hình không còn bản `PUBLISHED` nào (bốn mắt rút gọn).

**Luồng ngoại lệ.**
- **E1. Còn lỗi kiểm tra (bước 1).** ERR-11-010 (422): "Mô hình còn {n} lỗi phải sửa trước khi gửi duyệt. Xem ngăn Kết quả kiểm tra."
- **E3. Tự duyệt (bước 4).** ERR-11-005 (403): "Anh/chị đã gửi hoặc sửa bản này nên không được tự duyệt."
- **E4. Bản đã đổi trong lúc chờ (bước 5).** ERR-11-004 (409): "Bản chờ duyệt không còn khớp với bản đã gửi. Yêu cầu người gửi gửi lại."
- **E5. Engine từ chối (5a).** ERR-11-046 (503 hoặc 422): "Không triển khai được lên engine: {mô tả}. Bản đang chạy giữ nguyên."
- **E7. Còn phiên chạy (bước 7).** ERR-11-037 (409): "Phiên bản còn {n} hồ sơ đang xử lý. Chờ kết thúc hoặc di trú sang phiên bản mới (UI-11-14)."
- **E8. Ngừng bản duy nhất chưa xác nhận (7a).** ERR-11-038 (422): "Đây là phiên bản duy nhất đang phát hành; sau khi ngừng, kênh DVC không tạo được hồ sơ mới. Xác nhận để tiếp tục."

**Quy tắc áp dụng.** BR-11-004, BR-11-005, BR-11-006, BR-11-028, BR-11-032, BR-11-033; LP-11-01, LP-11-02, LP-11-03.

**Màn hình, API.** UI-11-04, UI-11-03, UI-11-07; API-11-006, 016…023, 131; kịch bản TS-11-05.
:::

```{.mermaid caption="Sơ đồ hoạt động gửi duyệt và duyệt phát hành bốn mắt một phiên bản mô hình"}
flowchart TB
  subgraph L1["Kỹ sư tích hợp Nam"]
    A1(["Gửi duyệt v3 kèm ghi chú"])
    A9["Sửa bản nháp"]
  end
  subgraph L2["Hệ thống PH-11"]
    B1["Kiểm tra tĩnh FULL"]
    B2{"Còn lỗi ERROR?"}
    B3["v3 IN_REVIEW, tạo publish_request PENDING, tạo việc duyệt"]
    B6{"Hạnh khác Nam và người sửa cuối?"}
    B7["Kiểm checksum, kiểm tra lại FULL"]
    B8["createDeployment với tenantId T68"]
    B9{"Engine nhận XML?"}
    B10["Một giao dịch: v3 PUBLISHED, v2 DEPRECATED, APPROVED, outbox EVT-11-01"]
    B11["Hoàn lại, DEPLOY_FAILED, v3 về DRAFT"]
    B12["v3 về DRAFT, REJECTED"]
  end
  subgraph L3["Người duyệt Hạnh"]
    C1["Mở việc, xem khác biệt, kết quả kiểm tra, miễn bù trừ"]
    C2{"Quyết định"}
  end
  A1 --> B1 --> B2
  B2 -- "Có, ERR-11-010" --> A9
  B2 -- "Không" --> B3 --> C1 --> C2
  C2 -- "Từ chối, lý do ≥ 20 ký tự" --> B12 --> A9
  C2 -- "Duyệt kèm ý kiến" --> B6
  B6 -- "Không, ERR-11-005" --> C1
  B6 -- "Có" --> B7 --> B8 --> B9
  B9 -- "Không, ERR-11-046" --> B11 --> A9
  B9 -- "Có" --> B10
  A9 --> A1
```

Sơ đồ cho thấy ba chỗ bản có thể quay về nháp (còn lỗi kiểm tra, bị từ chối, engine từ chối) và một chỗ bị chặn tại cổng bốn mắt. Chỉ nhánh cuối cùng thay đổi trạng thái `PUBLISHED`, và nó nằm gọn trong một giao dịch với outbox.

### 6.6. UC-11-06 · Khởi tạo phiên liên thông từ Cổng DVC, sự kiện PH-10 hoặc thủ công

Cổng DVC gọi PH-11 một lần để tạo phiên và nhận mã phiên ngay; công dân không phải chờ hay nộp lại.

::: dac-ta
**Mục tiêu.** Kênh tiếp nhận tạo phiên cho một hồ sơ, nhận `201` với mã phiên và hạn ngay sau khi phiên được ghi bền; gửi lại do hết thời gian chờ không tạo phiên thứ hai.

**Tác nhân chính.** Cổng DVC tỉnh, HTTT một cửa (scope `bpm.instance.start`); PH-10 (sự kiện khởi tạo); TO (Chi), TA (Mai) khi khởi tạo thủ công.

**Tác nhân phụ.** PH-03, PH-12 (token dịch vụ), Flowable, `pg-core`, PH-01, PH-07, PH-19.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-018, FR-11-019, FR-11-020 (cùng FR-11-046 tính hạn phiên, FR-11-056 phát EVT-11-03).

**Truy vết.** REQ-11, REQ-10; BP-01 (PH-01 khởi tạo `DUYET_KET_NAP_HTTT`), BP-03; LGC-NGSP-002 (hộ tịch: đăng ký, tra trạng thái); CMP-LAW-93; ADR-041.

**Tiền điều kiện.** Mô hình `LT_KHAI_SINH` có phiên bản `PUBLISHED`; client nằm trong `allowedStarters` của mô hình; CSDL sẵn sàng.

**Kích hoạt.** Cổng DVC gọi `POST /instances` kèm `Idempotency-Key` và `traceparent`; hoặc bản tin đến topic đã gắn; hoặc Chi bấm "Khởi tạo phiên" ở UI-11-13.

**Đảm bảo tối thiểu.** Không có phiên nửa vời; hai yêu cầu đồng thời cùng hồ sơ chỉ một yêu cầu tạo phiên.

**Đảm bảo thành công.** Phiên `RUNNING`, bước đầu đã lên lịch, `instance_index`, hạn phiên và EVT-11-03 đã ghi; biến `SENSITIVE` đã mã hóa.

**Luồng chính.**
1. Cổng DVC gọi `POST /instances` với `processKey` = `LT_KHAI_SINH`, `businessKey` = `HS-T68-2026-000142`, biến `loaiTTHC` = `LT_KS_TT_BHYT`, `maXa` = `26734`, `hoTenTre`, `ngaySinhTre`, `soDinhDanhMe` và `callbackTopic` = `t68.motcua.hoso.ketqua.v1`.
2. Hệ thống xác thực token, kiểm scope, `allowedStarters` và hạn mức `11.instance.startRatePerClient` lượt mỗi giây.
3. Hệ thống tìm phiên chưa kết thúc cùng (`tenant`, `processKey`, `businessKey`); chưa có thì chọn phiên bản `PUBLISHED`, kiểm biến theo `variable_definition`, mã hóa biến `SENSITIVE`.
4. Trong một giao dịch hệ thống gọi `startProcessInstanceByKeyAndTenantId`, ghi `instance_index`, `due_tracking` hạn phiên 5 ngày làm việc (UC-11-14), outbox EVT-11-03; bước bất đồng bộ đầu tiên đánh dấu `async`.
5. Hệ thống trả `201` kèm `instanceId`, `status` = `RUNNING`, `dueAt`, `progressUrl` và tiêu đề `Location`; engine tiếp tục chạy việc "Thẩm định hồ sơ khai sinh" (UC-11-09).

**Luồng thay thế.**

- **1b. Từ sự kiện PH-10.** Mô hình có `START_EVENT` thông điệp gắn topic đã đăng ký: hệ thống ghi `inbox_message` theo `id` sự kiện (trùng thì bỏ qua), kiểm ánh xạ trường sang biến, `businessKey`, rồi khởi tạo như bước 3 đến 5 với `startChannel` = `EVENT` (API-11-126).
- **1c. Thủ công.** Chi mở UI-11-13 cho hồ sơ giấy `HS-T68-2026-000143`: hệ thống sinh biểu mẫu từ biến (API-11-127), kiểm cờ `allowManualStart` và biến rồi khởi tạo với `startChannel` = `MANUAL`, `initiator` là Chi.

**Luồng ngoại lệ.**
- **E1. Client không được phép (bước 2).** ERR-11-020 (403): "Hệ thống gọi không được phép khởi tạo quy trình {processKey}."
- **E2. Vượt hạn mức (bước 2).** ERR-11-041 (429): "Vượt số lượt khởi tạo cho phép. Thử lại sau {n} giây."
- **E3. Chưa có bản phát hành (bước 3).** ERR-11-017 (422): "Quy trình {processKey} chưa có phiên bản đang phát hành."
- **E4. Biến thiếu hoặc sai kiểu (bước 3).** ERR-11-019 (422): "Thiếu hoặc sai kiểu biến: {danh sách}."
- **E5. Trùng hồ sơ khác dữ liệu (bước 3).** ERR-11-018 (409): "Hồ sơ {businessKey} đã có phiên đang xử lý với dữ liệu khác."

- **E7. Bản tin sự kiện không hợp lệ (1b).** ERR-11-120 (lỗi nền): UI-11-20 "Sự kiện {id} từ {topic} không tạo được phiên: {mô tả}."
- **E8. Mô hình không cho khởi tạo tay (1c).** ERR-11-020 (403): "Quy trình {tên} chỉ khởi tạo từ hệ thống tiếp nhận."
- **E9. Khóa dùng lại với nội dung khác (bước 2).** ERR-11-051 (409): "Khóa Idempotency-Key này đã dùng cho yêu cầu khác. Tạo khóa mới."

**Quy tắc áp dụng.** BR-11-006, BR-11-007, BR-11-014, BR-11-023; LP-11-05.

**Màn hình, API.** UI-11-13, UI-11-04 (điểm bắt đầu sự kiện); API-11-049, 052, 126, 127; kịch bản TS-11-06.
:::

Liên thông khai sinh là quy trình ví dụ xuyên suốt: từ lúc DVC tạo phiên đến lúc kết quả về công dân có bốn kiểu tác nhân cùng tham gia, và có ba chỗ rẽ quan trọng (bổ sung hồ sơ, lỗi bước tự động, hết thời gian chờ BHXH).

```{.mermaid caption="Sơ đồ hoạt động liên thông khai sinh LT_KHAI_SINH từ tiếp nhận đến kết quả"}
flowchart TB
  subgraph LD["Cổng DVC tỉnh"]
    D1(["Công dân nộp hồ sơ HS-T68-2026-000142"])
    D2["POST /instances, nhận 201"]
    D7["Báo đã bổ sung hồ sơ"]
    D9["Hiện kết quả cho công dân"]
  end
  subgraph LP["PH-11 điều phối"]
    P1["Tạo phiên RUNNING, tính hạn 5 ngày làm việc, EVT-11-03"]
    P2["Tạo việc Thẩm định, hạn việc"]
    P4{"Quyết định thẩm định"}
    P5["PAUSED chờ HO_SO_BO_SUNG, dừng đếm hạn"]
    P6["Gửi lệnh guiTuPhap, chờ kết quả"]
    P7["Cổng song song"]
    P8["Gửi guiCuTru"]
    P9["Gửi capTheBHYT, hẹn giờ biên 2 ngày làm việc"]
    P10["Hợp nhánh, gửi thông báo kết quả"]
    P11(["COMPLETED, EVT-11-05"])
    P12["Saga bù trừ UC-11-18"]
    P13(["REJECTED hoặc CANCELLED"])
  end
  subgraph LC["Cán bộ xã, nhóm TP_HOTICH"]
    C1["Nhận việc, thẩm định"]
  end
  subgraph L4["PH-04 và cơ quan"]
    Q1["Hộ tịch đăng ký khai sinh"]
    Q2["Công an đăng ký thường trú"]
    Q3["BHXH cấp thẻ BHYT"]
  end
  D1 --> D2 --> P1 --> P2 --> C1 --> P4
  P4 -- "Yêu cầu bổ sung" --> P5 --> D7 --> P2
  P4 -- "Từ chối" --> P13
  P4 -- "Đạt" --> P6 --> Q1 --> P7
  P7 --> P8 --> Q2 --> P10
  P7 --> P9 --> Q3
  Q3 -- "Thành công" --> P10
  Q3 -- "Lỗi BHXH_TU_CHOI hoặc hết thời gian chờ" --> P12
  P10 --> P11 --> D9
  P12 --> P13
```

Sơ đồ cho thấy hồ sơ chỉ quay lại bước thẩm định qua nhánh bổ sung (hạn dừng đếm), còn lỗi ở nhánh BHYT kéo theo bù trừ cả thường trú đã đăng ký. Hai nhánh song song cùng chạy sau khi khai sinh đã có số định danh.

### 6.7. UC-11-07 · Thực thi bước tự động qua PH-04 và nhận kết quả

PH-11 chạm các cơ quan chỉ bằng lệnh Kafka mang ý định nghiệp vụ (đề xuất ADR 112); thời gian PH-04 xử lý không giữ tài nguyên engine.

::: dac-ta
**Mục tiêu.** Khi token đến bước tự động, gửi đúng một lệnh tới PH-04 và đi tiếp khi có kết quả; phân biệt lỗi nghiệp vụ (đi nhánh lỗi, Saga) với lỗi kỹ thuật (thử lại, sự cố).

**Tác nhân chính.** PH-04 (scope `bpm.service.worker`); engine (`bpm-bridge`).

**Tác nhân phụ.** TO (Chi) gửi lại lệnh thủ công; Kafka; PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-028, FR-11-029.

**Truy vết.** REQ-11, REQ-04; BP-06 (gọi hộ tịch, cư trú, BHXH qua PH-04, PH-14); LGC-NGSP-002, LGC-BUS-037 (thực hiện lại).

**Tiền điều kiện.** Phiên `RUNNING`; ý định `ACTIVE` có ánh xạ luồng ở môi trường hiện hành.

**Kích hoạt.** Token đến `SERVICE_TASK` `guiTuPhap` (job `async`); kết quả hoặc lỗi đến topic `.completed.v1`, `.failed.v1`; hết `timeoutAt`.

**Đảm bảo tối thiểu.** Lệnh gửi đúng một lần (outbox), kết quả trùng không ghi hai lần (inbox); Kafka không chứa DLCN rõ.

**Đảm bảo thành công.** `service_call` `COMPLETED`, biến kết quả đã ghi, execution đi tiếp cùng giao dịch, EVT-11-04 đã vào outbox.

**Luồng chính.**
1. Job async lấy bước `guiTuPhap`; hệ thống dựng `payload` theo `inputMapping`, kiểm theo `inputSchema` của ý định.
2. Hệ thống sinh `commandId` UUID v5 xác định theo (`tenant`, `processInstanceId`, `executionId`, `activityId`, lần giao lệnh), ghi `service_call` `REQUESTED` (`timeoutAt` = bây giờ cộng `timeout`) và outbox EVT-11-17 trong một giao dịch `ph11_bpm` riêng (không chung giao dịch với engine, nguyên tử về hiệu ứng nhờ `commandId`, Q11-21); execution chờ `WAITING_SERVICE`.
3. Bộ chuyển outbox đẩy lên `t68.bpm.service.requested.v1`, khóa phân vùng `businessKey`.
4. PH-04 nhận lệnh, chạy luồng ánh xạ tới hộ tịch, trả kết quả lên `t68.bpm.service.completed.v1`.
5. Hệ thống ghi `inbox_message`, tìm `service_call` theo `commandId`, kiểm `output` theo `outputSchema`, ghi biến, `COMPLETED`, gọi `trigger(executionId)` và ghi outbox EVT-11-04.

**Luồng thay thế.**
- **5a. Lỗi `BUSINESS` có trong `businessErrors[]`.** Hệ thống ném `BpmnError` để `ERROR_BOUNDARY` bắt; không có biên bắt và đã có bước xong thì mở Saga (UC-11-18).
- **5c. Hết `timeoutAt`.** `service_call` `TIMED_OUT`; có hẹn giờ biên thì đi nhánh đó, không có thì mở sự cố và cảnh báo tắc nghẽn.
- **6a. Gửi lại lệnh thủ công.** Chi bấm "Gửi lại lệnh" trên `service_call` quá hạn (API-11-071): hệ thống gửi lại cùng `commandId`, tăng `attempt`, trả `202`; PH-04 chống trùng theo `commandId`.

**Luồng ngoại lệ.**
- **E1. Không đẩy được Kafka (bước 3).** ERR-11-101 (lỗi nền): UI-11-20 "Không gửi được lệnh {intentCode} của hồ sơ {businessKey} sau {n} lần."
- **E2. Kết quả không tương quan (bước 5).** ERR-11-103 (lỗi nền): "Kết quả {commandId} không khớp lệnh nào đang chờ." (bản tin vào DLQ, sự cố `CORRELATION_FAILED`)
- **E4. Quá hạn chờ kết quả (5c).** ERR-11-102 (lỗi nền): "Bước {publicName} của hồ sơ {businessKey} chờ PH-04 quá {n} phút."
- **E5. Lỗi nghiệp vụ từ cơ quan (5a).** ERR-11-105 (lỗi nền): dòng thời gian UI-11-12 "{tên bước}: cơ quan trả lỗi {errorCode}."
- **E7. Gửi lại lệnh đã đóng (6a).** ERR-11-006 (409): "Lệnh {commandId} đã có kết quả, không gửi lại."

**Quy tắc áp dụng.** BR-11-002, BR-11-010, BR-11-014, BR-11-022, BR-11-023; LP-11-05.

**Màn hình, API.** UI-11-12 thẻ Bước tự động, UI-11-20; API-11-070, 071; EVT-11-17, 18, 19; kịch bản TS-11-07.
:::

### 6.8. UC-11-08 · Chờ thông điệp, hẹn giờ, gửi thông báo và gọi quy trình con

Chờ tín hiệu, chờ giờ, báo cho người nhận và gọi quy trình con đều là bước tự động không cần cán bộ.

::: dac-ta
**Mục tiêu.** Phiên chờ đúng tín hiệu hoặc đúng giờ rồi đi tiếp, báo đúng đối tượng mà không gửi trực tiếp, và gọi được quy trình con như `DUYET_HAI_CAP`.

**Tác nhân chính.** Hệ thống (engine, bộ hẹn giờ); Cổng DVC, HTTT gửi thông điệp (scope `bpm.instance.start`).

**Tác nhân phụ.** PH-10, kênh thông báo, PH-03; IE (cấu hình).

**Mức ưu tiên.** M · Đợt 2 (gọi quy trình con, thông báo mức S).

**FR hiện thực.** FR-11-030, FR-11-031, FR-11-032, FR-11-033.

**Truy vết.** REQ-11, REQ-10, REQ-04; BP-01, BP-06.

**Tiền điều kiện.** Phiên có execution chờ `MESSAGE_EVENT` hoặc có hẹn giờ biên hợp lệ (≥ `11.timer.minSeconds` giây); `SEND_TASK` có `templateCode`; mô hình được gọi có bản `PUBLISHED`.

**Kích hoạt.** `POST /messages`; token đến hẹn giờ, `SEND_TASK` hoặc `CALL_ACTIVITY`; timer job đến giờ.

**Đảm bảo tối thiểu.** Thông điệp không khớp không làm hỏng phiên khác; lỗi gửi thông báo không hoàn lại bước nghiệp vụ.

**Đảm bảo thành công.** Phiên đi đúng nhánh: thông điệp tương quan, hẹn giờ kích hoạt trễ ≤ 60 giây, thông báo đã chuyển, phiên con trả biến ra.

**Luồng chính.**
1. Nhánh BHYT đặt hẹn giờ biên `P2D` theo lịch làm việc tại `capTheBHYT`; hệ thống tính thời điểm đến hạn bằng bộ tính ngày làm việc (UC-11-14) và tạo timer job trong `ph11_flowable`.
2. Cơ quan BHXH trả kết quả bằng kênh riêng: HTTT gọi `POST /messages` với `messageName` = `KET_QUA_BHYT` và khóa tương quan `HS-T68-2026-000142`.
3. Hệ thống ghi `inbox_message` theo `messageId`, tìm execution chờ có khóa tương quan trong tenant, kiểm biến rồi `messageEventReceived`, ghi outbox EVT-11-04.
4. Token đến `SEND_TASK` "Báo kết quả": hệ thống dựng nội dung từ mẫu chỉ với biến `PUBLIC`, `INTERNAL`, ghi EVT-11-20 cho kênh thông báo (`audience` = `APPLICANT` chỉ gửi `businessKey` và mẫu câu), rồi token đi tiếp ngay.
5. Với quy trình con, token đến `CALL_ACTIVITY` `DUYET_HAI_CAP`: hệ thống chọn phiên bản theo chính sách, khởi tạo phiên con với `parentInstanceId`, phiên cha chờ; khi con kết thúc, biến ra ghi vào cha và cha đi tiếp.

**Luồng thay thế.**
- **1a. Hẹn giờ biên ngắt.** Hết 2 ngày làm việc chưa có kết quả: việc hoặc lệnh đang chờ bị hủy (`CANCELLED`), token đi nhánh biên; biên không ngắt thì tạo nhánh song song (ví dụ nhắc).

**Luồng ngoại lệ.**
- **E1. Không có phiên chờ (bước 3).** ERR-11-049 (404): "Không có hồ sơ {businessKey} đang chờ thông điệp {messageName}."
- **E4. Hẹn giờ không chạy được (bước 1).** ERR-11-108 (lỗi nền): UI-11-20 "Hẹn giờ {tên} của hồ sơ {businessKey} không chạy được: {mô tả}."
- **E5. Gửi thông báo thất bại (bước 4).** ERR-11-123 (lỗi nền): UI-11-20 cảnh báo "Thông báo {templateCode} của hồ sơ {businessKey} chưa gửi được."; bước nghiệp vụ không bị hoàn lại.
- **E6. Quy trình con chưa phát hành (bước 5).** ERR-11-118 (lỗi nền): UI-11-20 "Không gọi được quy trình con {calledProcessKey}: chưa có phiên bản phát hành."

**Quy tắc áp dụng.** BR-11-014, BR-11-017, BR-11-022, BR-11-030, BR-11-034, BR-11-035; LP-11-05.

**Màn hình, API.** UI-11-04, UI-11-12, UI-11-20; API-11-069; EVT-11-20; kịch bản TS-11-08.
:::

### 6.9. UC-11-09 · Tạo việc, phân công và đưa vào hộp "Việc của tôi"

Khi token đến bước người dùng, hệ thống tạo việc, chọn người hoặc nhóm nhận, tính hạn và đưa vào hộp chung.

::: dac-ta
**Mục tiêu.** Việc "Thẩm định hồ sơ khai sinh" đến đúng nhóm `TP_HOTICH` của xã `26734` kèm hạn; nếu không giải được người nhận thì có nhóm dự phòng chịu trách nhiệm.

**Tác nhân chính.** Hệ thống (`bpm-task`).

**Tác nhân phụ.** PH-12, hộp "Việc của tôi" (FR-00-070), HTTT một cửa có hộp việc riêng, CB (Thu).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-034, FR-11-035.

**Truy vết.** REQ-11, REQ-12, REQ-21; BP-01; FR-00-070…072.

**Tiền điều kiện.** Bước có `assignment` hợp lệ (`USER`, `CANDIDATE_GROUP`, `ORG_UNIT` hoặc `RULE`).

**Kích hoạt.** Token đến `USER_TASK`.

**Đảm bảo tối thiểu.** Việc không bao giờ không có chủ: không giải được ứng viên thì vào nhóm dự phòng `11.task.fallbackGroup` và mở sự cố.

**Đảm bảo thành công.** `task_index` `UNASSIGNED`, hạn việc, EVT-11-08 đã ghi; việc hiện ở hộp của mọi ứng viên, gồm người được ủy quyền.

**Luồng chính.**
1. Phiên `HS-T68-2026-000142` đến bước "Thẩm định hồ sơ khai sinh" có `assignment` `CANDIDATE_GROUP` = `TP_HOTICH`, `due` = 2 ngày làm việc.
2. Hệ thống giải `assignment`: lấy thành viên nhóm từ PH-12 tại thời điểm tạo (chụp danh sách, BR-11-037), loại người vi phạm `separateFrom`, áp ủy quyền đang hiệu lực (UC-11-13).
3. Hệ thống tạo việc Flowable với `tenantId`, ghi `task_index` `UNASSIGNED`, tính hạn việc (UC-11-14), ghi outbox EVT-11-08.
4. Hệ thống cập nhật mục hộp việc qua giao diện nhà cung cấp việc của FR-00-070; hộp việc gọi API-11-125 lấy danh sách theo người dùng, sắp mặc định quá hạn trước, rồi gần hạn.

**Luồng thay thế.**
- **4a. HTTT một cửa có hộp việc riêng.** HTTT đọc việc của đơn vị qua API-11-072 với scope `bpm.task.read`, không đọc biến `SENSITIVE`.

**Luồng ngoại lệ.**
- **E1. Không có ứng viên hợp lệ (bước 2).** ERR-11-113 (lỗi nền): UI-11-20 "Việc {tên} của hồ sơ {businessKey} không có người nhận hợp lệ, đã chuyển nhóm {nhóm}."

**Quy tắc áp dụng.** BR-11-014, BR-11-016, BR-11-020, BR-11-031, BR-11-037; LP-11-04.

**Màn hình, API.** Hộp `/viec-cua-toi`, UI-11-15; API-11-072, 125; EVT-11-08, 09; kịch bản TS-11-09.
:::

### 6.10. UC-11-10 · Nhận việc, xem hồ sơ và hoàn thành việc với biểu mẫu, ý kiến, quyết định

Đây là màn cán bộ dùng nhiều nhất: nhận việc, đọc hồ sơ đã che, điền biểu mẫu, ghi ý kiến và chọn quyết định.

::: dac-ta
**Mục tiêu.** Thu hoàn thành việc "Thẩm định hồ sơ khai sinh" với dữ liệu biểu mẫu hợp lệ, ý kiến và quyết định, không mất công nhập lại khi gián đoạn, và nhận gợi ý của AI khi tenant bật.

**Tác nhân chính.** CB (Thu).

**Tác nhân phụ.** Flowable; PH-17 (gợi ý, mức C); PH-09; hộp "Việc của tôi".

**Mức ưu tiên.** M · Đợt 2 (lưu nháp mức S, gợi ý AI mức C).

**FR hiện thực.** FR-11-036, FR-11-037, FR-11-038, FR-11-039, FR-11-066.

**Truy vết.** REQ-11, REQ-21, REQ-17 (gợi ý AI); BP-01; FR-00-072.

**Tiền điều kiện.** Thu có `PERM-11-task` và thuộc ứng viên của việc; phiên `RUNNING`; việc `UNASSIGNED` (để nhận) hoặc `ASSIGNED` cho Thu (để hoàn thành).

**Kích hoạt.** Thu bấm việc ở "Việc của tôi", mở `/viec-cua-toi/{ma-viec}` (UI-11-15).

**Đảm bảo tối thiểu.** Chỉ một người nhận việc; nháp giữ khi mất kết nối; phiên tạm dừng thì nút quyết định bị vô hiệu.

**Đảm bảo thành công.** Việc `COMPLETED` kèm `decision`, biến kết quả đã ghi (`SENSITIVE` mã hóa), hạn việc đóng `MET` hoặc `MISSED`, EVT-11-10.

**Luồng chính.**
1. Thu mở UI-11-15; hệ thống kiểm phạm vi, trả thông tin việc, biểu mẫu `FORM_THAM_DINH_KHAI_SINH` đúng phiên bản, giá trị biến được biểu mẫu tham chiếu (che theo phân loại), dòng thời gian rút gọn, ý kiến, tệp và nhãn hạn.
2. Thu bấm "Nhận việc"; hệ thống gọi `claim` có khóa lạc quan, việc sang `ASSIGNED`, ghi EVT-11-09.
3. Thu điền biểu mẫu; giao diện lưu nháp sau `11.task.draftDebounceSeconds` giây không gõ, hệ thống kiểm kiểu từng trường đã nhập, mã hóa trường `SENSITIVE`.
4. Thu bấm "Gợi ý" (mức C): hệ thống gọi PH-17 với ngữ cảnh chỉ gồm trường được phép, hiện gợi ý nhãn "Gợi ý của AI"; Thu chấp nhận từng phần.
5. Thu chọn quyết định "Đồng ý" và bấm hoàn thành; hệ thống kiểm người thao tác, trạng thái phiên, `separateFrom`, kiểm `data` theo JSON Schema, ý kiến.
6. Hệ thống ghi biến kết quả, gọi `complete` với `decision` trong cùng giao dịch, xóa nháp, đóng hạn việc, ghi `aiAssisted` nếu có dùng gợi ý, ghi outbox EVT-11-10; phiên đi tới `guiTuPhap` (UC-11-07).

**Luồng thay thế.**
- **2a. Trả lại việc.** Thu bấm "Trả lại việc" (API-11-075): việc về `UNASSIGNED`, giữ nháp nếu chọn "Giữ nháp".

**Luồng ngoại lệ.**
- **E1. Đã có người nhận (bước 2).** ERR-11-021 (409): "Việc đã được {người} nhận lúc {giờ}."
- **E2. Không phải ứng viên (bước 1, 2).** ERR-11-022 (403): "Anh/chị không được giao việc này." (khi thao tác việc do người khác giữ: "Việc này đang do {người} xử lý.")
- **E4. Dữ liệu biểu mẫu sai (bước 5).** ERR-11-023 (422): "Kiểm tra lại: {danh sách trường và lỗi}."
- **E5. Thiếu ý kiến (bước 5).** ERR-11-007 (422): "Nhập lý do (tối thiểu 20 ký tự) khi từ chối hoặc trả về."
- **E6. Vi phạm tách nhiệm vụ (bước 5).** ERR-11-005 (403): "Anh/chị đã xử lý bước {tên} của hồ sơ này nên không được xử lý bước duyệt này."
- **E9. PH-17 không trả lời (bước 4).** ERR-11-124 (lỗi nền): UI-11-15 "Chưa lấy được gợi ý, anh/chị tiếp tục xử lý như bình thường."

**Quy tắc áp dụng.** BR-11-014, BR-11-016, BR-11-020, BR-11-029, BR-11-033; LP-11-01, LP-11-02, LP-11-04.

**Màn hình, API.** UI-11-15, UI-11-07; API-11-072…077, 124; kịch bản TS-11-10.
:::

### 6.11. UC-11-11 · Trả về bước trước, yêu cầu bổ sung hồ sơ và tạm dừng tính hạn

Hồ sơ thiếu giấy tờ là chuyện thường ngày; thời gian chờ công dân bổ sung không tính vào hạn.

::: dac-ta
**Mục tiêu.** Thu trả hồ sơ về đúng người hoặc báo công dân bổ sung đúng giấy tờ, hạn phiên dừng đếm trong lúc chờ và tiếp tục khi công dân bổ sung xong.

**Tác nhân chính.** CB (Thu).

**Tác nhân phụ.** Cổng DVC; engine; PH-03.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-044, FR-11-049.

**Truy vết.** REQ-11; BP-01; CMP-LAW-93 (hạn giải quyết, thời gian bổ sung; Q11-01); LGC-NGSP-002 liên quan gián tiếp.

**Tiền điều kiện.** Bước cấu hình `allowReturnTo[]` (trả về) hoặc `allowSupplement` (bổ sung); Thu là người nhận việc.

**Kích hoạt.** Thu bấm "Trả về" hoặc "Yêu cầu bổ sung" ở UI-11-15; Cổng DVC gọi API-11-089 khi công dân đã bổ sung.

**Đảm bảo tối thiểu.** Hạn dừng đếm trong lúc `PAUSED`; việc trả về không mất ý kiến, tệp, nháp.

**Đảm bảo thành công.** Trả về: token về bước đích, việc mới giao người đã xử lý. Bổ sung: hạn `PAUSED` rồi tính lại `dueAt`, DVC được báo `WAITING_SUPPLEMENT`.

**Luồng chính.**
1. Thu thấy hồ sơ thiếu bản sao giấy chứng sinh, bấm "Yêu cầu bổ sung" và nhập nội dung cần bổ sung (≥ 20 ký tự).
2. Hệ thống kiểm bước cho phép bổ sung và ý kiến, hoàn thành việc với `REQUEST_SUPPLEMENT`.
3. Phiên đến bước chờ thông điệp `HO_SO_BO_SUNG`; hệ thống đặt hạn phiên `PAUSED`, ghi `pausedAt`, `pauseReason` = `WAITING_SUPPLEMENT`, ghi outbox EVT-11-04 với `displayStatus` = `WAITING_SUPPLEMENT` để DVC báo công dân.
4. Công dân nộp bổ sung ở Cổng DVC; DVC gọi `POST /instances/{instanceId}:supplement-received`.
5. Hệ thống kiểm phiên đang chờ bổ sung, gửi thông điệp `HO_SO_BO_SUNG`, cộng thời gian tạm dừng (giờ làm việc) vào `pausedDuration`, tính lại `dueAt` và trả `202` kèm `dueAt` mới.

**Luồng thay thế.**
- **1a. Trả về bước trước.** Thu chọn "Trả về" kèm bước đích trong `allowReturnTo[]` (API-11-087): hệ thống hoàn thành việc với `RETURN`, cổng sau bước đưa token về `toElementId`, việc mới giao lại người đã xử lý bước đó nếu còn hoạt động.
- **5a. Quá `deadline` không bổ sung.** Hệ thống không tự hủy: phiên giữ `PAUSED`, mở sự cố `SUPPLEMENT_EXPIRED` kèm ERR-11-125 cho TO, người này hủy (UC-11-16) hoặc gia hạn.
- **5b. Quy định yêu cầu tính lại hạn.** Khi `11.supplement.resetDue` = `true`, hạn phiên tính lại từ `receivedAt` (Q11-03).

**Luồng ngoại lệ.**
- **E1. Bước đích không cho phép (bước 1a).** ERR-11-026 (422): "Không trả về được bước {tên}. Chỉ trả về: {danh sách}."

**Quy tắc áp dụng.** BR-11-017, BR-11-018, BR-11-033, BR-11-022; LP-11-02.

**Màn hình, API.** UI-11-15, UI-11-12; API-11-087, 088, 089; kịch bản TS-11-11.
:::

```{.mermaid caption="Sơ đồ hoạt động yêu cầu bổ sung hồ sơ, tạm dừng và tiếp tục tính hạn"}
flowchart TB
  subgraph LC["Cán bộ Thu"]
    A1(["Mở việc thẩm định, thấy thiếu giấy chứng sinh"])
    A2{"Hướng xử lý"}
    A3["Yêu cầu bổ sung kèm nội dung ≥ 20 ký tự"]
    A4["Trả về bước trước kèm lý do"]
  end
  subgraph LH["PH-11"]
    B1["Hoàn thành việc REQUEST_SUPPLEMENT"]
    B2["Hạn phiên PAUSED, ghi pausedAt"]
    B3["EVT-11-04 displayStatus WAITING_SUPPLEMENT"]
    B4["Chờ thông điệp HO_SO_BO_SUNG"]
    B5{"Công dân bổ sung trước deadline?"}
    B6["Cộng pausedDuration, tính lại dueAt"]
    B7["Hẹn giờ biên: nhánh Từ chối do không bổ sung"]
    B8["Hoàn thành việc RETURN, token về bước đích"]
    B9(["Việc thẩm định giao lại, hạn tiếp tục"])
  end
  subgraph LD["Cổng DVC"]
    D1["Báo công dân cần bổ sung"]
    D2["Công dân nộp bổ sung, gọi supplement-received"]
  end
  A1 --> A2
  A2 -- "Cần giấy tờ" --> A3 --> B1 --> B2 --> B3 --> D1 --> B4 --> B5
  B5 -- "Có" --> D2 --> B6 --> B9
  B5 -- "Không" --> B7
  A2 -- "Sai ở bước trước" --> A4 --> B8 --> B9
```

Sơ đồ cho thấy hạn chỉ dừng ở nhánh bổ sung, không dừng ở nhánh trả về nội bộ vì lúc đó hồ sơ vẫn nằm trong tay cơ quan. Nếu công dân không bổ sung đúng hạn, hẹn giờ biên đưa phiên sang nhánh từ chối thay vì để treo.

### 6.12. UC-11-12 · Chuyển việc, trao đổi ý kiến và đính kèm tệp trên việc

Chuyển việc, ý kiến và tệp đính kèm nằm trên chính việc để dấu vết không tản mát.

::: dac-ta
**Mục tiêu.** Thu chuyển việc đang giữ cho Bình kèm lý do, trao đổi ý kiến và đính kèm văn bản xử lý, giữ đủ dấu vết để kiểm toán.

**Tác nhân chính.** CB (Thu).

**Tác nhân phụ.** CB nhận (Bình); TA, TO; kho đối tượng và dịch vụ quét mã độc.

**Mức ưu tiên.** M · Đợt 2 (đính kèm, trao đổi mức S).

**FR hiện thực.** FR-11-040, FR-11-043.

**Truy vết.** REQ-11, REQ-21; BP-01.

**Tiền điều kiện.** Việc `ASSIGNED` cho Thu; Bình cùng tenant, còn hoạt động, thuộc ứng viên của bước (hoặc người chuyển có `PERM-11-task-admin`).

**Kích hoạt.** Thu bấm "Chuyển việc" hoặc dùng thẻ "Ý kiến", "Tệp" ở UI-11-15.

**Đảm bảo tối thiểu.** Chuyển lỗi thì việc vẫn ở Thu; tệp không an toàn không được lưu.

**Đảm bảo thành công.** Người nhận mới ghi vào dòng thời gian kèm lý do, EVT-11-09 (`via` = `TRANSFER`); tệp có `checksum`, ý kiến lưu `task_comment`.

**Luồng chính.**
1. Thu mở thẻ "Tệp", kéo `giay-chung-sinh.pdf` (3 MB); hệ thống quét mã độc, kiểm loại và cỡ (≤ `11.task.attachmentMaxMb` MB), lưu kho đối tượng, ghi `task_attachment` có checksum.
2. Thu mở thẻ "Ý kiến", nhập "Nhờ chị Bình kiểm tra cư trú của mẹ" và nhắc `@Bình`; hệ thống lưu `task_comment`, thông báo người được nhắc.
3. Thu bấm "Chuyển việc", chọn Bình và nhập lý do; hệ thống kiểm Bình cùng tenant, còn hoạt động, không phải chính Thu, không vi phạm `separateFrom`, thuộc ứng viên.
4. Hệ thống gọi `setAssignee`, ghi người chuyển và lý do vào dòng thời gian, ghi outbox EVT-11-09, cập nhật hộp việc hai người.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Người nhận không hợp lệ (bước 3).** ERR-11-024 (422): "Không chuyển được cho {người}: {lý do}."
- **E2. Tệp không hợp lệ (bước 1).** ERR-11-027 (422 hoặc 413): "Tệp {tên} không được chấp nhận: {quá {n} MB, loại không cho phép, không an toàn}."

**Quy tắc áp dụng.** BR-11-014, BR-11-016, BR-11-020; LP-11-04.

**Màn hình, API.** UI-11-15; API-11-078, 083…086; kịch bản TS-11-12.
:::

### 6.13. UC-11-13 · Ủy quyền khi vắng mặt và phân công lại hàng loạt

Ủy quyền do cán bộ khai trước; giao lại hàng loạt do quản trị làm khi cán bộ nghỉ việc hoặc nhóm quá tải.

::: dac-ta
**Mục tiêu.** Thu khai ủy quyền cho Bình trong thời gian công tác để việc mới và việc đang giữ có người xử lý; Mai, Chi chuyển nhiều việc một lần với xem trước tác động.

**Tác nhân chính.** CB (Thu, tạo ủy quyền); TA (Mai), TO (Chi) giao lại hàng loạt.

**Tác nhân phụ.** CB nhận ủy quyền (Bình); PH-12; tác vụ nền FR-00.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-11-041, FR-11-042.

**Truy vết.** REQ-11, REQ-12; BP-01.

**Tiền điều kiện.** Ủy quyền: người nhận cùng tenant, còn hoạt động; Thu có `PERM-11-task` cho chính mình (TA đặt thay bằng `PERM-11-task-admin`). Giao lại: `PERM-11-task-admin`, việc chưa kết thúc.

**Kích hoạt.** Thu bấm "+ Ủy quyền" ở UI-11-17; Mai bấm "Giao lại" ở UI-11-16 sau khi lọc và chọn việc.

**Đảm bảo tối thiểu.** Không có ủy quyền vòng hay chồng lấn; việc vi phạm `separateFrom` không bị giao nhầm; một việc lỗi không dừng cả lô.

**Đảm bảo thành công.** `delegation` `SCHEDULED` rồi `ACTIVE` đúng khoảng, hết hạn thì việc chưa xong về Thu; giao lại ghi kết quả từng việc.

**Luồng chính.**
1. Thu mở UI-11-17, bấm "+ Ủy quyền", chọn Bình, từ 02/12/2026 đến 12/12/2026, tích "Gồm việc đang giữ".
2. Hệ thống kiểm khoảng ≤ `11.delegation.maxDays` ngày, không chồng lấn, Bình không đang ủy quyền tiếp trong khoảng đó; lưu `delegation` `SCHEDULED`.
3. Đến 02/12 hệ thống chuyển `ACTIVE`: việc mới giao Thu chuyển `DELEGATED` cho Bình, việc đang giữ chuyển theo; ghi EVT-11-09 (`via` = `DELEGATION`).
4. Hết 12/12 hệ thống chuyển `EXPIRED`, việc chưa xong trả về Thu; nếu Thu về sớm, Thu bấm "Thu hồi" đạt kết quả như vậy với `REVOKED`.
5. Cán bộ khác nghỉ việc: Mai mở UI-11-16, lọc theo người, nhóm, mô hình, hạn, chọn việc và người đích; hệ thống kiểm số việc ≤ `11.task.bulkMax` và người đích.
6. Hệ thống xem trước số việc mỗi người nhận và việc bị loại do `separateFrom`; Mai xác nhận, hệ thống chạy tác vụ nền, ghi kết quả từng việc.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Ủy quyền không hợp lệ (bước 2).** ERR-11-025 (422): "Ủy quyền không hợp lệ: {chồng lấn, quá {n} ngày, ủy quyền vòng}."
- **E2. Quá giới hạn giao lại (bước 5).** ERR-11-050 (422): "Mỗi lần giao lại tối đa {n} việc. Thu hẹp bộ lọc."

**Quy tắc áp dụng.** BR-11-020; LP-11-04.

**Màn hình, API.** UI-11-16, UI-11-17; API-11-079…082; kịch bản TS-11-13.
:::

### 6.14. UC-11-14 · Quản lý lịch làm việc, tính hạn, nhắc hạn và leo thang quá hạn

Quy định 5 ngày làm việc chỉ chính xác khi biết lịch của tỉnh; use case gom việc khai lịch và phép tính hạn (đề xuất ADR 114).

::: dac-ta
**Mục tiêu.** Mai khai lịch năm 2027 của tỉnh; mọi hạn phiên, hạn việc tính đúng theo lịch đó, cộng thời gian tạm dừng, đổi lịch thì hạn chưa đóng được tính lại; người giữ việc được nhắc khi sắp đến hạn, việc quá hạn được đánh dấu và leo thang.

**Tác nhân chính.** TA (Mai); hệ thống (bộ quét hạn, mỗi `11.due.scanMinutes` phút).

**Tác nhân phụ.** PA; hệ thống (bộ tính hạn); TO (Chi), AU, CB xem hạn; PH-12; PH-13, kênh thông báo.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-045, FR-11-046, FR-11-047, FR-11-048.

**Truy vết.** REQ-11; BP-01, BP-07; CMP-LAW-93; LGC-NGSP-004 (hồ sơ thủ tục cấp mã ĐVQHNS có hạn) liên quan gián tiếp.

**Tiền điều kiện.** Mai có `PERM-11-config`; mô hình hoặc bước có `due`.

**Kích hoạt.** Mai mở UI-11-18; bộ quét hạn đến mốc `dueSoonAt` hoặc `dueAt`; hệ thống tính hạn khi khởi tạo phiên, tạo việc, tiếp tục sau tạm dừng, đổi lịch.

**Đảm bảo tối thiểu.** Năm chưa có lịch thì dùng lịch mặc định (thứ Hai đến thứ Sáu) kèm cảnh báo, không chặn khởi tạo phiên.

**Đảm bảo thành công.** `business_calendar`, `calendar_day` lưu đúng; mỗi `due_tracking` có `dueAt`, `dueSoonAt`; hạn bị đổi do đổi lịch được tính lại.

**Luồng chính.**
1. Mai chọn năm 2027 ở UI-11-18; hệ thống hiện lịch tháng, ngày nghỉ tô màu, kế thừa lịch `COMMON` nếu tỉnh chưa khai.
2. Mai bấm "Nhập từ lịch quốc gia": hệ thống sao chép ngày lễ của `COMMON`, giữ ngày riêng của tỉnh.
3. Mai thêm ngày làm bù thứ Bảy 16/01/2027 và nghỉ đột xuất 05/02/2027; hệ thống kiểm ngày trong năm, không trùng, giờ làm không chồng rồi lưu.
4. Hệ thống tính lại hạn các `due_tracking` chưa đóng có mốc rơi vào ngày đổi (tác vụ nền) và ghi số hạn đổi.
5. Mai bấm "Tính thử hạn": nhập thời điểm tiếp nhận 16:45 thứ Sáu và hạn 5 ngày làm việc; hệ thống trả hạn không lưu.
6. Khi phiên khởi tạo (UC-11-06), hệ thống chuẩn hóa `start` (ngoài giờ làm việc thì dời sang đầu giờ làm việc kế tiếp theo `11.due.receiveAfterHoursRule`), đếm đủ ngày làm việc, hạn là cuối giờ làm việc ngày cuối, cộng `pausedDuration`, ghi `due_tracking`.

7. Việc "Thẩm định hồ sơ khai sinh" của Thu có hạn 17:00 ngày 28/11/2026; đến mốc còn `11.task.dueSoonHours` giờ làm việc, bộ quét khóa dòng (`FOR UPDATE SKIP LOCKED`), đặt `DUE_SOON`, ghi EVT-11-11 và gửi thông báo trong ứng dụng cho Thu (hoặc cả nhóm nếu chưa ai nhận).
8. Quá 17:00 mà chưa hoàn thành, hệ thống đặt `OVERDUE`, ghi EVT-11-12 với `escalationLevel` = 0; đến `afterHours` giờ làm việc sau hạn (không khai thì mức đầu 0 giờ, mỗi mức sau cách `11.escalation.nextLevelHours`), thực hiện lần lượt các mức đã cấu hình: báo lãnh đạo đơn vị, chuyển nhóm, nâng ưu tiên, mở sự cố; mỗi mức ghi EVT-11-12 với mức mới.

**Luồng thay thế.**

- **7a. Hạn phiên sắp đến.** Hệ thống nhắc TO và người giữ việc hiện tại; bước không khai `escalation` thì chỉ đánh dấu và báo người giữ việc.

**Luồng ngoại lệ.**
- **E1. Lịch sai (bước 3).** ERR-11-028 (422): "Lịch không hợp lệ: {ngày trùng, giờ chồng, ngày ngoài năm}."
- **E2. Thiếu lịch năm (bước 6).** ERR-11-116 (lỗi nền): UI-11-18 băng cảnh báo "Năm {năm} chưa có lịch làm việc; hạn đang tính theo lịch mặc định."

- **E4. Không gửi được thông báo nhắc (bước 7).** ERR-11-123 (lỗi nền): UI-11-20 cảnh báo "Nhắc hạn việc {taskId} chưa gửi được."; trạng thái hạn vẫn đổi.
- **E5. Không tìm được lãnh đạo đơn vị (bước 8).** ERR-11-113 (lỗi nền): UI-11-19 "Không xác định được lãnh đạo đơn vị {đơn vị} để báo quá hạn."; hệ thống chuyển mức kế tiếp (Q11-48).

**Quy tắc áp dụng.** BR-11-017, BR-11-018, BR-11-019, BR-11-020; LP-11-03, LP-11-05.

**Màn hình, API.** UI-11-18, UI-11-12, UI-11-15, UI-11-19, `/viec-cua-toi`; API-11-090…093 (nhắc hạn, quá hạn không có API riêng); EVT-11-11, 12; kịch bản TS-11-14.
:::

### 6.15. UC-11-15 · Tra cứu và xem chi tiết phiên

Trước khi can thiệp, người vận hành phải thấy hồ sơ đang ở đâu; chi tiết phiên đặt mọi thông tin trên một màn.

::: dac-ta
**Mục tiêu.** Chi tìm phiên của `HS-T68-2026-000142` và thấy bước nào xong, đang chờ, lỗi hay đang bù trừ; cán bộ chỉ thấy phiên có việc của mình hoặc đơn vị mình.

**Tác nhân chính.** TO (Chi), TA (Mai), AU (Quang), CB (Thu, trong phạm vi).

**Tác nhân phụ.** PH-09; PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-021, FR-11-022.

**Truy vết.** REQ-11; BP-07; LGC-NGSP-002 (tra trạng thái hồ sơ) nâng cấp ở mức điều phối.

**Tiền điều kiện.** Có `PERM-11-read`; xem giá trị biến `SENSITIVE` cần thêm `PERM-09-unmask` và nêu lý do.

**Kích hoạt.** Chi mở `/quy-trinh/phien` (UI-11-11), hoặc bấm liên kết từ việc, sự cố, cảnh báo.

**Đảm bảo tối thiểu.** Danh sách không trả giá trị biến; `SENSITIVE`, `RESTRICTED` luôn che khi không có quyền; phiên tenant khác không lộ.

**Đảm bảo thành công.** Người xem thấy trạng thái đúng từng phần tử; mọi lần Hiện giá trị nhạy cảm có lý do và dòng kiểm toán.

**Luồng chính.**
1. Chi nhập `businessKey` = `HS-T68-2026-000142` và lọc trạng thái `RUNNING` ở UI-11-11; hệ thống kiểm tham số, truy vấn `instance_index` dưới RLS, áp phạm vi CB và trả trang.
2. Chi bấm dòng kết quả; hệ thống kiểm phạm vi và trả XML phiên bản cùng trạng thái từng phần tử (`COMPLETED`, `ACTIVE`, `FAILED`, `COMPENSATED`, `SKIPPED`).
3. Hệ thống trả dòng thời gian (vào, ra, người xử lý, thời lượng, quyết định) và biến đã che; giao diện tô xanh hoàn thành, vàng đang chờ, đỏ lỗi, tím bù trừ.
4. Chi bấm bước lỗi `capTheBHYT`: hệ thống hiện mã lỗi, các lệnh service task và liên kết `traceId` sang PH-13.
5. Chi cần xem số định danh mẹ: bấm "Hiện" trên biến `soDinhDanhMe`, nhập lý do; hệ thống kiểm `PERM-09-unmask`, ghi kiểm toán rồi trả giá trị; giao diện tự che lại sau `11.task.unmaskSeconds` giây.

**Luồng thay thế.**
- **1a. Xuất CSV.** Chi bấm "Xuất" kết quả lọc (≤ 50.000 dòng) qua tác vụ nền FR-00 (API-11-128).

**Luồng ngoại lệ.**
- **E2. Ngoài phạm vi (bước 2).** ERR-11-034 (403): "Anh/chị không có quyền xem hồ sơ này."

**Quy tắc áp dụng.** BR-11-014, BR-11-031; LP-11-04.

**Màn hình, API.** UI-11-11, UI-11-12; API-11-050…055, 070, 128; kịch bản TS-11-15.
:::

### 6.16. UC-11-16 · Tạm dừng, tiếp tục và hủy phiên

Khi chờ chỉ đạo, đối tác sự cố hay công dân rút hồ sơ, vận hành dừng hoặc hủy phiên mà không để dữ liệu lệch.

::: dac-ta
**Mục tiêu.** Chi dừng một phiên để không có bước nào chạy rồi tiếp tục đúng chỗ; hoặc hủy hẳn phiên và, nếu đã có bước ghi dữ liệu ra ngoài, chạy bù trừ.

**Tác nhân chính.** TO (Chi), TA (Mai); Cổng DVC, HTTT một cửa (scope `bpm.instance.start`) cho phiên do chính client tạo.

**Tác nhân phụ.** Engine Flowable; Saga (UC-11-18); EVT-11-06, 07.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-023, FR-11-024.

**Truy vết.** REQ-11; BP-06; LGC-BUS-037 (thực hiện lại, bỏ qua) liên quan gián tiếp.

**Tiền điều kiện.** Tạm dừng: phiên `RUNNING`. Tiếp tục: `SUSPENDED`. Hủy: `RUNNING` hoặc `SUSPENDED`. Người gọi có `PERM-11-instance` hoặc scope tương ứng.

**Kích hoạt.** Chi bấm "Tạm dừng", "Tiếp tục", "Hủy phiên" ở UI-11-12; DVC gọi API khi công dân rút hồ sơ.

**Đảm bảo tối thiểu.** Bỏ bù trừ khi còn bước rủi ro chỉ do TA làm và tạo việc đối chiếu thủ công; không hủy được phiên đang bù trừ.

**Đảm bảo thành công.** Phiên `SUSPENDED` rồi `RUNNING`; hoặc `CANCELLED`; hoặc `COMPENSATING` rồi `COMPENSATED`; EVT-11-07 hoặc EVT-11-06 đã ghi.

**Luồng chính.**
1. Chi mở phiên `HS-T68-2026-000142` ở UI-11-12, bấm "Tạm dừng" kèm lý do "Chờ chỉ đạo của Sở Tư pháp" và chọn `pauseDue`.
2. Hệ thống kiểm trạng thái và lý do, gọi `suspendProcessInstanceById`, cập nhật `instance_index`, `due_tracking` (`PAUSED` nếu `pauseDue`), ghi EVT-11-07 với `state` = `SUSPENDED`.
3. Có chỉ đạo, Chi bấm "Tiếp tục": hệ thống `activateProcessInstanceById`, hạn tiếp tục, EVT-11-07 `state` = `RESUMED`.
4. Công dân rút hồ sơ: HTTT một cửa gọi `POST /instances/{instanceId}:cancel` kèm lý do (client hệ thống chỉ `AUTO`, chỉ hủy phiên của mình); hoặc Chi bấm "Hủy phiên".
5. Giao diện cảnh báo "Sẽ bù trừ 2 bước" (đã có `guiTuPhap`, `guiCuTru` xong); khi `compensate` = `AUTO`, hệ thống chuyển `COMPENSATING` và chạy UC-11-18 với `trigger` = `INSTANCE_CANCEL`, trả `202`.
6. Không có bước nào cần bù trừ thì hệ thống gọi `deleteProcessInstance` kèm lý do, việc mở thành `CANCELLED`, lệnh service task đang chờ nhận lệnh hủy nếu ý định hỗ trợ, phiên `CANCELLED`, ghi EVT-11-06, trả `200`.

**Luồng thay thế.**
- **5a. Bỏ bù trừ.** Mai (TA) chọn `compensate` = `NONE` khi còn bước rủi ro, nhập lý do ≥ 30 ký tự; hệ thống tạo việc đối chiếu thủ công cho TO.

**Luồng ngoại lệ.**
- **E3. Phiên đang bù trừ (bước 2, 4).** ERR-11-030 (409): "Phiên đang bù trừ, chờ Saga kết thúc."
- **E4. Bỏ bù trừ không đủ quyền (5a).** ERR-00-403 (403): "Chỉ quản trị tỉnh được hủy mà không bù trừ."
- **E5. Client gọi phiên không phải của mình (bước 4).** ERR-11-001 (404): "Không tìm thấy phiên {id}." 

**Quy tắc áp dụng.** BR-11-008, BR-11-010, BR-11-011, BR-11-018, BR-11-023; LP-11-02, LP-11-03.

**Màn hình, API.** UI-11-12; API-11-056, 057, 058; EVT-11-06, 07; kịch bản TS-11-16.
:::

### 6.17. UC-11-17 · Can thiệp phiên có duyệt: sửa biến, chuyển bước, di trú sang phiên bản mới

Sửa biến, chuyển bước và di trú đưa phiên ra ngoài đường đi của mô hình nên đều bốn mắt và có lý do.

::: dac-ta
**Mục tiêu.** Mai đề nghị sửa biến, chuyển bước hoặc lập kế hoạch di trú; một TA khác duyệt trước khi hệ thống thực hiện, mọi thay đổi ghi vết và hoàn tác được bằng đề nghị mới.

**Tác nhân chính.** TA (Mai, người đề nghị).

**Tác nhân phụ.** TA khác (người duyệt); Flowable; hộp "Việc của tôi".

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-11-025, FR-11-026, FR-11-027.

**Truy vết.** REQ-11; BP-07; LGC-BUS-037 (thực hiện lại, bỏ qua) nâng cấp ở mức quy trình; FR-00-071, ADR-046.

**Tiền điều kiện.** Mai có `PERM-11-instance-admin`; người duyệt khác Mai; phiên `RUNNING` hoặc `SUSPENDED`, không `COMPENSATING`; di trú: phiên bản đích `PUBLISHED` cùng mô hình.

**Kích hoạt.** Mai bấm "Đề nghị sửa" ở thẻ Biến hoặc "Đề nghị chuyển bước" trên sơ đồ ở UI-11-12; mở UI-11-14 cho di trú.

**Đảm bảo tối thiểu.** Chưa duyệt thì phiên không đổi; phiên đổi trạng thái trong lúc chờ thì đề nghị không áp dụng; một phiên lỗi không dừng cả lô di trú.

**Đảm bảo thành công.** `instance_change` `APPLIED` hoặc `migration_plan` `COMPLETED`, `PARTIAL`; người đề nghị, người duyệt, lý do, giá trị cũ (đã che) ghi kiểm toán.

**Luồng chính.**
1. Mai thấy `maXa` nhập nhầm thành `26743`; ở UI-11-12 thẻ Biến bấm "Đề nghị sửa", nhập `26734` và lý do.
2. Hệ thống kiểm biến có `editableBy` = `ADMIN_CHANGE`, kiểu đúng; tạo `instance_change` `VARIABLE_UPDATE` `PENDING` và việc duyệt cho TA khác.
3. TA khác mở đề nghị, bấm "Duyệt"; hệ thống kiểm khác Mai, phiên chưa đổi trạng thái, ghi biến qua `setVariables` và kiểm toán giá trị cũ.
4. Với chuyển bước: cơ quan hộ tịch đã xử lý ngoài hệ thống, Mai chọn bước `guiCuTru` trên sơ đồ và "Đề nghị chuyển bước"; hệ thống kiểm bước đích cùng tiến trình, không phải sự kiện biên, không vào giữa nhánh song song chưa hợp.
5. TA khác duyệt: hệ thống gọi `moveActivityIdsToSingleActivityId`, việc ở bước cũ `CANCELLED`, ghi dòng thời gian.
6. Với di trú: Mai mở UI-11-14, chọn v2 sang v3 của `LT_KHAI_SINH`; hệ thống tự ghép bước cùng `elementId` và liệt kê bước chưa ghép để Mai ánh xạ tay.
7. Mai bấm "Kiểm tra": hệ thống chạy `validateMigration` từng phiên; Mai gửi duyệt, TA khác duyệt.
8. Hệ thống chạy theo lô `11.migration.batchSize` phiên, mỗi phiên một giao dịch, ghi kết quả từng phiên; `migration_plan` `COMPLETED` hoặc `PARTIAL`.

**Luồng thay thế.**
- **3a. Từ chối.** TA khác từ chối kèm ý kiến bắt buộc (API-11-062): `instance_change` `REJECTED`, phiên không đổi.

**Luồng ngoại lệ.**
- **E1. Biến không cho sửa (bước 2).** ERR-11-033 (422): "Biến {tên} không được sửa sau khi khởi tạo."
- **E3. Tự duyệt (bước 3, 5, 7).** ERR-11-005 (403): "Anh/chị là người đề nghị nên không được tự duyệt."
- **E4. Bước đích sai (bước 4).** ERR-11-032 (422): "Không chuyển được tới bước {tên}: {lý do}."
- **E6. Còn bước chưa ánh xạ (bước 7).** ERR-11-031 (422): "Còn {n} bước đang có phiên mà chưa ánh xạ sang phiên bản mới: {danh sách}."
- **E7. Phiên lỗi khi chạy (bước 8).** ERR-11-119 (lỗi nền): UI-11-14 bảng kết quả "Phiên {businessKey} không di trú được: {mô tả}."

**Quy tắc áp dụng.** BR-11-006, BR-11-021; LP-11-01, LP-11-02, LP-11-03.

**Màn hình, API.** UI-11-12, UI-11-14; API-11-059…068; kịch bản TS-11-17.
:::

### 6.18. UC-11-18 · Điều phối bù trừ Saga khi lỗi bước

Không có giao dịch phân tán giữa các cơ quan nên nhất quán đạt bằng bù trừ theo thứ tự ngược (đề xuất ADR 113); khai sinh đã phát hành không xóa, chỉ đánh dấu.

::: dac-ta
**Mục tiêu.** Khi `capTheBHYT` lỗi `BHXH_TU_CHOI` sau khi `guiTuPhap` và `guiCuTru` đã xong, hệ thống đưa các cơ quan về trạng thái nhất quán và không để lại bước nào lệch mà không ai biết.

**Tác nhân chính.** Hệ thống (`bpm-saga`); TA, TO kích hoạt thủ công (`PERM-11-compensate`).

**Tác nhân phụ.** PH-04; Kafka; TO; PH-13 (cảnh báo P1); Cổng DVC.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-051.

**Truy vết.** REQ-11; BP-06, BP-07; LGC-BUS-037 liên quan gián tiếp; BR-11-008…013.

**Tiền điều kiện.** Có bước đã xong có `compensation_action`; phiên chưa `COMPENSATING`.

**Kích hoạt.** Lỗi nghiệp vụ không có biên bắt (UC-11-07), sự kiện `COMPENSATION_THROW` trong mô hình, hủy kèm bù trừ (UC-11-16), hoặc "Kích hoạt bù trừ" ở UI-11-12.

**Đảm bảo tối thiểu.** Bước Saga chỉ `DONE` sau khi ghi nhật ký (BR-11-013); không ghi được thì giữ `RUNNING` và thử lại; không im lặng khi thất bại (BR-11-012).

**Đảm bảo thành công.** `saga_log` `SUCCEEDED` và phiên `COMPENSATED`, hoặc `PARTIAL` và phiên `FAILED` với mọi bước chưa xong ở `MANUAL` có việc cho TO; EVT-11-13 rồi EVT-11-14 hoặc 15.

**Luồng chính.**
1. `capTheBHYT` trả lỗi nghiệp vụ `BHXH_TU_CHOI` không có biên bắt; hệ thống chuyển phiên `COMPENSATING`, tạo `saga_log` `RUNNING`, ghi EVT-11-13.
2. Hệ thống lập `saga_step` cho mỗi bước đã xong có bù trừ, sắp theo thời điểm hoàn thành giảm dần (`guiCuTru`, rồi `guiTuPhap`); bước chưa xong `SKIPPED`; nhánh song song cùng mức bù trừ song song.
3. Với `guiCuTru` chính sách `AUTO`: hệ thống gửi lệnh `huyDangKyThuongTru` (`commandId` mới, như UC-11-07), chờ kết quả; `DONE` chỉ đặt sau khi ghi nhật ký.
4. Với `guiTuPhap` chính sách `MANUAL`: hệ thống chuyển bước sang `MANUAL` (ý định `danhDauChoXuLy`), tạo việc `MANUAL_COMPENSATION` cho nhóm vận hành, cảnh báo P1.
5. Khi mọi bước `DONE` hoặc `SKIPPED`: `saga_log` `SUCCEEDED`, phiên `COMPENSATED`, EVT-11-14. Còn bước `MANUAL` chưa xong: `saga_log` `PARTIAL`, phiên `FAILED`, EVT-11-15.

**Luồng thay thế.**
- **3a. Hết lượt thử.** Bước bù trừ thất bại sau `11.saga.maxRetries` lần cách nhau `11.saga.retryBackoffSeconds` giây chuyển `MANUAL` (BR-11-012).
- **1a. Kích hoạt thủ công.** Chi bấm "Kích hoạt bù trừ" ở UI-11-12 (API-11-098), nhận `202` kèm `sagaId`, `steps[]`.

**Luồng ngoại lệ.**
- **E2. Không có gì để bù trừ (bước 1a).** ERR-11-006 (409): "Hồ sơ chưa có bước nào cần bù trừ."
- **E3. Không ghi được nhật ký Saga (bước 3).** ERR-11-111 (lỗi nền): UI-11-21 "Không ghi được nhật ký bù trừ bước {tên}; bước giữ trạng thái chạy, sẽ thử lại."
- **E4. Hành động bù trừ thất bại (bước 3).** ERR-11-110 (lỗi nền): UI-11-21 "Bù trừ {ý định} của hồ sơ {businessKey} vẫn lỗi: {mô tả}."

**Quy tắc áp dụng.** BR-11-008, BR-11-009, BR-11-010, BR-11-011, BR-11-012, BR-11-013; LP-11-05.

**Màn hình, API.** UI-11-12 thẻ Bù trừ, UI-11-21; API-11-098; EVT-11-13, 14, 15, 17; kịch bản TS-11-18.
:::

```{.mermaid caption="Sơ đồ hoạt động điều phối bù trừ Saga khi cấp thẻ BHYT thất bại"}
flowchart TB
  subgraph LS["PH-11 bpm-saga"]
    S1(["capTheBHYT lỗi BHXH_TU_CHOI, không có biên bắt"])
    S2["Phiên COMPENSATING, saga_log RUNNING, EVT-11-13"]
    S3["Lập saga_step theo thứ tự ngược: guiCuTru rồi guiTuPhap"]
    S4{"Chính sách bước"}
    S5["Gửi lệnh bù trừ commandId mới"]
    S6{"Kết quả bù trừ"}
    S7["Ghi nhật ký, rồi saga_step DONE"]
    S8{"Còn lượt thử?"}
    S9["saga_step MANUAL, việc MANUAL_COMPENSATION, cảnh báo P1"]
    S10{"Còn bước MANUAL?"}
    S11(["SUCCEEDED, phiên COMPENSATED, EVT-11-14"])
    S12(["PARTIAL, phiên FAILED, EVT-11-15"])
  end
  subgraph LP["PH-04 và cơ quan"]
    P1["Thực thi huyDangKyThuongTru"]
  end
  subgraph LT["Vận hành Chi"]
    T1["Xử lý thủ công UC-11-19"]
  end
  S1 --> S2 --> S3 --> S4
  S4 -- "AUTO" --> S5 --> P1 --> S6
  S4 -- "MANUAL" --> S9
  S6 -- "Thành công" --> S7 --> S10
  S6 -- "Lỗi" --> S8
  S8 -- "Còn, chờ backoff" --> S5
  S8 -- "Hết" --> S9
  S9 --> S10
  S10 -- "Không" --> S11
  S10 -- "Có" --> S12 --> T1
```

Sơ đồ cho thấy hai cách kết thúc của một Saga trong cùng một phiên. Bước thường trú bù trừ tự động thành công; bước khai sinh không bù trừ tự động được nên chuyển cho người, phiên ở `FAILED` cho đến khi vận hành xác nhận ở UC-11-19.

### 6.19. UC-11-19 · Theo dõi nhật ký Saga, xử lý bù trừ thủ công và đối soát định kỳ

Bù trừ thất bại không được chìm: mỗi bước `MANUAL` có người chịu trách nhiệm, đối soát phát hiện bù trừ chưa có hiệu lực.

::: dac-ta
**Mục tiêu.** Mọi bước bù trừ không tự hoàn tất đều có người thử lại, xác nhận đã xử lý ngoài hệ thống có bằng chứng, hoặc bỏ qua có người thứ hai duyệt; mọi bù trừ `DONE` được đối chiếu với trạng thái thật.

**Tác nhân chính.** TO (Chi), TA (Mai); AU (Quang) xem và xuất.

**Tác nhân phụ.** PH-04; TA khác (duyệt bỏ qua); hộp "Việc của tôi".

**Mức ưu tiên.** M · Đợt 2 (đối soát mức S).

**FR hiện thực.** FR-11-052, FR-11-053, FR-11-054.

**Truy vết.** REQ-11; BP-07; LGC-BUS-037 (thực hiện lại hoặc bỏ qua có lý do ở mức quy trình); hệ cũ: DLQ bản tin giữ ở PH-04, PH-18.

**Tiền điều kiện.** Có `saga_log`; xử lý thủ công cần `saga_step` `MANUAL` và `PERM-11-compensate`; đối soát cần ý định bù trừ có `verifyIntentCode`.

**Kích hoạt.** Chi mở việc `MANUAL_COMPENSATION` ở hộp việc hoặc UI-11-21; lịch `11.saga.reconcileCron` (mặc định 02:00); Chi bấm "Chạy đối soát".

**Đảm bảo tối thiểu.** Xử lý tay bắt buộc có lý do và bằng chứng; bỏ qua không bao giờ do chính người đề nghị duyệt.

**Đảm bảo thành công.** Không còn bước `MANUAL` thì phiên `COMPENSATED`; mỗi xử lý tay có bằng chứng; đối soát ghi kết quả từng bước và mở sự cố khi lệch.

**Luồng chính.**
1. Chi mở UI-11-21, lọc theo `businessKey` `HS-T68-2026-000142`, thấy Saga `PARTIAL`; bấm vào xem `saga_step` kèm `commandId`, lần thử, kết quả, mã phản hồi, `traceId`.
2. Chi mở bước `guiTuPhap` ở `MANUAL`; liên hệ hộ tịch xác nhận bản ghi đã đánh dấu chờ xử lý, nhập `evidence[]` (ghi chú, số văn bản, tệp chứng từ theo FR-11-043, người xác nhận) và bấm "Xác nhận đã xử lý" kèm lý do.
3. Hệ thống kiểm bước `MANUAL`, lý do, `evidence[]` và đặt bước `DONE`; không còn bước `MANUAL` thì Saga kết thúc, phiên `COMPENSATED`, EVT-11-14.
4. Với bước chưa rõ nguyên nhân, Chi bấm "Thử lại": hệ thống gửi lại lệnh bù trừ, bước `RUNNING`.
5. Lúc 02:00 hệ thống chọn các `saga_step` `DONE` trong khoảng có `verifyIntentCode`, gửi lệnh tra qua PH-04 (API-11-103 khi chạy tay) và so trạng thái mong đợi (API-11-102 xem kết quả).
6. Quang (AU) bấm "Xuất CSV" nhật ký Saga (API-11-129) để làm bằng chứng đối soát liên cơ quan; hệ thống sinh tệp có checksum.

**Luồng thay thế.**
- **2a. Bỏ qua.** Chi bấm "Đề nghị bỏ qua" kèm lý do (API-11-101): hệ thống chỉ tạo đề nghị và việc `MANUAL_COMPENSATION` cho TA khác, bước vẫn `MANUAL`. Mai (TA khác) duyệt (API-11-132, bước `SKIPPED`) hoặc từ chối (API-11-133, bước về `MANUAL`).

**Luồng ngoại lệ.**
- **E1. Bước không ở thủ công (bước 2, 4).** ERR-11-006 (409): "Bước bù trừ này không chờ xử lý thủ công."
- **E3. Tự duyệt bỏ qua (2a).** ERR-11-005 (403): "Người đề nghị bỏ qua không được tự duyệt."
- **E4. Bù trừ lỗi lần nữa (bước 4).** ERR-11-110 (lỗi nền): UI-11-21 "Bù trừ {ý định} của hồ sơ {businessKey} vẫn lỗi: {mô tả}."
- **E5. Đối soát phát hiện lệch (bước 5).** ERR-11-121 (lỗi nền): UI-11-21 "Đối soát phát hiện {n} bù trừ chưa có hiệu lực ở {cơ quan}."

**Quy tắc áp dụng.** BR-11-012, BR-11-013, BR-11-025, BR-11-038; LP-11-01, LP-11-02.

**Màn hình, API.** UI-11-21; API-11-096…103, 129, 132, 133; EVT-11-14; kịch bản TS-11-19.
:::

### 6.20. UC-11-20 · Tra tiến độ hồ sơ cho Cổng DVC và phát sự kiện tiến độ

Công dân biết hồ sơ ở đâu mà không gọi từng cơ quan; DVC chỉ thấy tên bước, trạng thái, hạn, không có DLCN hay tên cán bộ.

::: dac-ta
**Mục tiêu.** Cổng DVC hiện cho công dân hồ sơ đang ở bước nào, bước nào xong, có cần bổ sung không và dự kiến khi nào có kết quả, mà không lộ dữ liệu nội bộ.

**Tác nhân chính.** Cổng DVC tỉnh (scope `bpm.progress.read` qua PH-03).

**Tác nhân phụ.** PH-10; Valkey (đệm); HTTT một cửa, PH-01, PH-07, PH-19.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-055, FR-11-056.

**Truy vết.** REQ-11, REQ-10; BP-01; LGC-NGSP-002 (tra trạng thái hồ sơ hộ tịch) nâng cấp ở mức điều phối; CMP-LAW-05 (DLCN).

**Tiền điều kiện.** Phiên tồn tại do client cùng tenant tạo hoặc client được cấp đọc mô hình đó; bước có `publicName` mới hiện (BR-11-015); topic `t68.bpm.*` đã đăng ký ở PH-10.

**Kích hoạt.** Công dân mở trang tra cứu ở Cổng DVC, DVC gọi `GET /progress/{businessKey}`; hoặc chuyển bước phát sự kiện.

**Đảm bảo tối thiểu.** Không lộ biến nào; client không có quan hệ với phiên nhận `404` như không tồn tại; lỗi Kafka không hoàn lại bước nghiệp vụ.

**Đảm bảo thành công.** DVC nhận bước công khai, `displayStatus`, `dueAt`, câu thông điệp; mỗi lần tra ghi nhật ký truy cập; sự kiện đi đúng thứ tự theo hồ sơ.

**Luồng chính.**
1. Công dân nhập mã `HS-T68-2026-000142` ở Cổng DVC; DVC gọi `GET /progress/HS-T68-2026-000142`.
2. Hệ thống kiểm scope và quan hệ client với phiên; đọc đệm Valkey (`11.progress.cacheSeconds` giây), trượt đệm thì đọc `instance_index` và lịch sử bước.
3. Hệ thống dựng phản hồi chỉ gồm bước có `publicName`: "Tiếp nhận" `DONE`, "Thẩm định" `DONE`, "Đăng ký khai sinh" `DONE`, "Đăng ký thường trú" `IN_PROGRESS`, "Cấp thẻ BHYT" `IN_PROGRESS`; `displayStatus` = `IN_PROGRESS`, `dueAt`, câu thông điệp; bỏ mọi biến.
4. Hệ thống ghi nhật ký truy cập và trả `200` cho DVC hiển thị cho công dân.
5. Song song, mỗi khi qua bước có `publicName`, listener engine ghi outbox trong cùng giao dịch chuyển bước (EVT-11-04 `instance.step.completed`, chỉ chứa mã, trạng thái, `publicName`, `percentEstimate`).
6. Bộ chuyển outbox đẩy lên Kafka khóa phân vùng `businessKey`; DVC nghe EVT-11-03, 04, 05, 06 để cập nhật trang công dân ngay, và PH-01 nhận EVT-11-05, 06 qua `callbackTopic`.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Không có hồ sơ hoặc client không được phép (bước 2).** ERR-11-035 (404): "Không tìm thấy hồ sơ {businessKey}."
- **E2. Outbox tồn đọng (bước 6).** ERR-11-117 (lỗi nền): UI-11-19 cảnh báo "Có {n} sự kiện chưa gửi quá {m} phút."; bước nghiệp vụ không bị hoàn lại.

**Quy tắc áp dụng.** BR-11-014, BR-11-015, BR-11-022, BR-11-023, BR-11-030; LP-11-04, LP-11-05.

**Màn hình, API.** Không có màn hình (API và sự kiện); API-11-104; EVT-11-03…07; kịch bản TS-11-20.
:::

### 6.21. UC-11-21 · Giám sát quy trình, phát hiện tắc nghẽn và báo cáo đúng hạn, trễ hạn

Lãnh đạo và vận hành cần một màn toàn cục trước khi người dân phản ánh.

::: dac-ta
**Mục tiêu.** Chi thấy ngay phiên `RUNNING`, việc `OVERDUE`, tỷ lệ Saga, thời gian chờ PH-04, sự cố mở và các bước tắc; Mai, Quang xem tỷ lệ đúng hạn và xuất báo cáo.

**Tác nhân chính.** TO (Chi), TA (Mai), VW, AU (Quang).

**Tác nhân phụ.** Hệ thống; PH-13 (chỉ số); tác vụ nền xuất XLSX.

**Mức ưu tiên.** M · Đợt 2 (tắc nghẽn, báo cáo mức S).

**FR hiện thực.** FR-11-058, FR-11-059, FR-11-050.

**Truy vết.** REQ-11, REQ-13, REQ-16; BP-07; CMP-LAW-93.

**Tiền điều kiện.** Có `PERM-11-read`; phát hiện tắc nghẽn cần mô hình có ít nhất `11.bottleneck.minSamples` phiên đã qua bước trong 30 ngày.

**Kích hoạt.** Chi mở `/quy-trinh/giam-sat` (UI-11-19); Mai mở `/quy-trinh/bao-cao-han` (UI-11-22).

**Đảm bảo tối thiểu.** Số liệu đệm tối đa 60 giây; không đủ mẫu thì chỉ dùng ngưỡng tuyệt đối, không báo tắc giả.

**Đảm bảo thành công.** Thẻ chỉ số tô theo ngưỡng; bước tắc được đánh dấu và mở sự cố `STUCK_INSTANCE`; báo cáo có tỷ lệ `MET`, `MISSED`, trung vị, p90.

**Luồng chính.**
1. Chi mở UI-11-19; hệ thống tổng hợp từ `instance_index`, `task_index`, `due_tracking`, `saga_log`, `incident`, `service_call` (đệm 60 giây).
2. Hệ thống trả thẻ: phiên `RUNNING`, việc `OVERDUE`, tỷ lệ Saga 24 giờ, p95 thời gian chờ service task, sự cố `OPEN`, outbox tồn đọng; xu hướng theo giờ; top 10 bước tắc.
3. Giao diện tô thẻ theo ngưỡng (UC-11-23); Chi bấm thẻ "Việc quá hạn" để mở UI-11-11 hoặc UI-11-20 đã lọc.
4. Tác vụ 15 phút tính số phiên đang ở mỗi bước và tuổi chờ; bước `capTheBHYT` có số phiên chờ vượt `p95 lịch sử × 11.bottleneck.factor` bị đánh dấu tắc.
5. Với phiên chờ quá `11.instance.stuckHours` giờ, hệ thống mở sự cố `STUCK_INSTANCE` và gửi cảnh báo (UC-11-22).
6. Mai mở UI-11-22, chọn khoảng 01/10 đến 31/10/2026; hệ thống tổng hợp từ `due_tracking` đã đóng: số `MET`, `MISSED`, đang `OVERDUE`, trung vị, p90, thời gian tạm dừng.
7. Mai bấm "Xuất"; hệ thống sinh XLSX qua tác vụ nền.

**Luồng thay thế.** Không.

**Luồng ngoại lệ.**
- **E1. Khoảng không hợp lệ (bước 1, 6).** ERR-11-003 (400): "Khoảng thời gian không hợp lệ." (quá 366 ngày: ERR-11-039 (422) "Khoảng thời gian tối đa 366 ngày.")
- **E2. Phiên tắc (bước 5).** ERR-11-115 (lỗi nền): UI-11-19 "{n} hồ sơ chờ ở bước {tên} quá {m} giờ."

**Quy tắc áp dụng.** BR-11-017, BR-11-019, BR-11-031.

**Màn hình, API.** UI-11-19, UI-11-22; API-11-094, 095, 107, 108; kịch bản TS-11-21.
:::

### 6.22. UC-11-22 · Xử lý sự cố engine và thử lại

Job lỗi, kết quả không tương quan hay phiên tắc đều mở sự cố thay vì im lặng; vận hành thử lại hoặc bỏ qua có lý do.

::: dac-ta
**Mục tiêu.** Mọi sự cố engine (job hết lượt thử, kết quả không khớp, hẹn giờ lỗi, phiên tắc) có người xem và xử lý đến khi `RESOLVED` hoặc `IGNORED` có lý do.

**Tác nhân chính.** TO (Chi), TA (Mai); PO (Hà, xem và thử lại khi có phiếu sự cố).

**Tác nhân phụ.** Engine Flowable; PH-10 (DLQ); PH-13 (cảnh báo).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-060.

**Truy vết.** REQ-11, REQ-18; BP-07; LGC-BUS-037 (thực hiện lại hoặc bỏ qua) nâng cấp thêm thử lại, bỏ qua có lý do ở mức quy trình.

**Tiền điều kiện.** Có `incident` `OPEN`; người xử lý có `PERM-11-compensate`.

**Kích hoạt.** Chi mở UI-11-20 hoặc bấm liên kết trong cảnh báo của PH-13.

**Đảm bảo tối thiểu.** PO không xem biến, chỉ thử lại khi có phiếu; sự cố tự đóng khi phiên hủy hoặc bù trừ xong; thử lại không tạo lệnh trùng (theo `commandId`).

**Đảm bảo thành công.** `incident` `RESOLVED` khi job thành công hoặc `IGNORED` kèm lý do; job chết bị xóa nếu phiên đã kết thúc hoặc đã chuyển bước.

**Luồng chính.**
1. Chi mở UI-11-20 và thấy sự cố `SERVICE_TIMEOUT` của `HS-T68-2026-000142` bước `capTheBHYT` kèm ngăn xếp lỗi rút gọn, `traceId`, số lần thử.
2. Chi liên hệ BHXH, xác nhận cơ quan đã khôi phục dịch vụ.
3. Chi bấm "Thử lại"; hệ thống đặt lại số lượt thử của job (`moveDeadLetterJobToExecutableJob`), sự cố `RETRYING`.
4. Job thành công thì sự cố `RESOLVED`; lỗi lại thì trở về `OPEN`.
5. Sau khi BHXH khôi phục, Chi chọn 12 sự cố cùng nguyên nhân và bấm "Thử lại hàng loạt"; hệ thống xử lý lần lượt từng sự cố.

**Luồng thay thế.**
- **3b. Bỏ qua.** Chi bấm "Bỏ qua" kèm lý do (API-11-112); sự cố `IGNORED`.

**Luồng ngoại lệ.**
- **E1. Sự cố đã được xử lý.** ERR-11-006 (409): "Sự cố đã được xử lý."
- **E2. Thử lại vẫn lỗi.** ERR-11-107 (runtime); UI-11-20: "Thử lại không thành công: {mô tả}."

**Quy tắc áp dụng.** BR-11-012, BR-11-022; LP-11-02, LP-11-06.

**Màn hình, API.** UI-11-20; API-11-109…113; EVT-11-16; kịch bản TS-11-22.
:::

### 6.23. UC-11-23 · Cấu hình cảnh báo, tham số `11.*` và chính sách lưu giữ

Tỉnh chỉnh ngưỡng, cảnh báo, lưu giữ trong trần nền tảng mà không triển khai lại; dọn lịch sử không được đụng hồ sơ giữ pháp lý.

::: dac-ta
**Mục tiêu.** Mai đặt `11.task.dueSoonHours`, ngưỡng cảnh báo, chính sách lưu giữ và giữ pháp lý cho một hồ sơ; hệ thống dọn lịch sử đúng hạn và xuất chỉ số chuẩn về PH-13.

**Tác nhân chính.** TA (Mai).

**Tác nhân phụ.** PA; PH-13; hệ thống.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-061, FR-11-062, FR-11-063.

**Truy vết.** REQ-11, REQ-18, REQ-20, REQ-13; BP-07; CMP-LAW-91, CMP-LAW-92 (lưu giữ).

**Tiền điều kiện.** Mai có `PERM-11-config`; PH-13 sẵn sàng nhận OpenTelemetry.

**Kích hoạt.** Mai mở UI-11-23 các thẻ "Tham số", "Cảnh báo", "Lưu giữ"; lịch `11.retention.cleanupCron` (mặc định 01:00).

**Đảm bảo tối thiểu.** Tham số không vượt trần nền tảng (BR-11-024); hồ sơ giữ pháp lý không bị dọn dù hết hạn (BR-11-025).

**Đảm bảo thành công.** `tenant_setting` nạp lại trong ≤ 60 giây; cảnh báo đồng bộ sang PH-13; lịch sử engine quá hạn được dọn, bản nghiệp vụ ở `ph11_bpm` còn nguyên.

**Luồng chính.**
1. Mai mở UI-11-23 thẻ "Tham số"; hệ thống hiện giá trị hiện hành, mặc định, miền, trần.
2. Mai đổi `11.task.dueSoonHours` từ 8 thành 6 và bấm lưu; hệ thống kiểm khóa tồn tại, kiểu, miền và trần rồi lưu `tenant_setting`, phát sự kiện nội bộ để các thành phần nạp lại trong ≤ 60 giây.
3. Mai mở thẻ "Cảnh báo", đặt ngưỡng việc quá hạn và outbox tồn đọng; hệ thống kiểm miền và đồng bộ quy tắc sang PH-13.
4. Mai mở thẻ "Lưu giữ", giữ mặc định 5 năm cho phiên, 12 tháng cho `ACT_HI_*`.
5. Mai thêm `businessKey` `HS-T68-2026-000142` vào giữ pháp lý (API-11-120) theo yêu cầu của cơ quan điều tra.
6. Lúc 01:00 hệ thống chọn phiên kết thúc trước `engineHistoryMonths`, đã có bản nghiệp vụ đầy đủ, không giữ pháp lý, xóa `ACT_HI_*` theo lô 1.000, giữ `instance_index`, `task_index`, `saga_*`, `service_call`; ghi số bản ghi đã dọn.

**Luồng thay thế.**
- **5a. Xem và gỡ giữ.** Mai xem danh sách hồ sơ đang giữ (API-11-134) rồi gỡ kèm lý do (API-11-135, `:release`).

**Luồng ngoại lệ.**
- **E1. Giá trị ngoài miền hoặc vượt trần (bước 2).** ERR-11-029 (422): "{key} phải trong khoảng {min}…{max} (trần nền tảng {trần})."
- **E3. Dọn phiên đang giữ pháp lý bằng thao tác tay (bước 5, 6).** ERR-11-047 (409): "Hồ sơ {businessKey} đang được giữ theo yêu cầu pháp lý."
- **E4. Dọn lịch sử lỗi (bước 6).** ERR-11-122 (lỗi nền): UI-11-20 "Dọn lịch sử lỗi ở lô {n}: {mô tả}."

**Quy tắc áp dụng.** BR-11-024, BR-11-025; LP-11-03.

**Màn hình, API.** UI-11-23; API-11-114…120, 134, 135; kịch bản TS-11-23.
:::

### 6.24. UC-11-24 · Kiểm toán lịch sử bước, nhật ký phân hệ và bằng chứng tuân thủ BPMN 2.0

Kiểm toán cần chứng minh ai làm gì ở bước nào lúc nào, và có bằng chứng nền tảng chạy BPMN 2.0 thật theo Công văn 631.

::: dac-ta
**Mục tiêu.** Kiểm toán xem đủ lịch sử bước và nhật ký kiểm toán, xuất bằng chứng có băm kiểm tra được; quản trị chạy mẫu tuân thủ và xuất biên bản kèm thuyết minh WS-BPEL.

**Tác nhân chính.** AU (Quang), TA (Mai).

**Tác nhân phụ.** PH-13; engine; kho bằng chứng.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-11-057, FR-11-064, FR-11-065.

**Truy vết.** REQ-11, REQ-13; BP-07; CMP-LAW-09 (CV 631: BPMN 2.0, WS-BPEL).

**Tiền điều kiện.** Có `PERM-11-audit-read`; lịch sử: phiên còn trong thời hạn lưu giữ; bằng chứng: mẫu `MAU_TUAN_THU_BPMN` đã cài ở môi trường thử.

**Kích hoạt.** Quang mở UI-11-12 thẻ "Lịch sử đầy đủ"; mở UI-11-23 thẻ "Nhật ký" hoặc "Tuân thủ".

**Đảm bảo tối thiểu.** Nhật ký không hiển thị giá trị `SENSITIVE`; phiên đã dọn lịch sử engine vẫn dựng từ bản nghiệp vụ và kho WORM; mẫu lỗi thì biên bản ghi Chưa đạt.

**Đảm bảo thành công.** Tệp xuất có băm SHA-256 và tham chiếu chuỗi băm; gói bằng chứng lưu kho; mọi lần xem, xuất ghi kiểm toán.

**Luồng chính.**
1. Quang mở phiên `HS-T68-2026-000142` ở UI-11-12 thẻ "Lịch sử đầy đủ"; hệ thống ghép lịch sử engine, `task_index`, ý kiến, `service_call`, Saga, `instance_change`, tạm dừng hạn.
2. Quang bấm "Xuất bằng chứng"; hệ thống sinh tệp kèm băm SHA-256 và tham chiếu chuỗi băm kiểm toán, ghi kiểm toán.
3. Quang mở UI-11-23 thẻ "Nhật ký", lọc theo loại thao tác "phát hành", "can thiệp phiên", "bù trừ thủ công", "xem DLCN", "đổi tham số"; hệ thống đọc nhật ký module `bpm` từ kho kiểm toán PH-13.
4. Mai mở thẻ "Tuân thủ", bấm "Chạy mẫu và xuất bằng chứng"; hệ thống triển khai `MAU_TUAN_THU_BPMN`, chạy một phiên đầy đủ (bước tự động giả lập, việc tự hoàn thành, một nhánh bù trừ).
5. Hệ thống ghép biên bản gồm XML mẫu, `instanceId`, lịch sử bước, danh sách phần tử BPMN 2.0 đã thực thi, phiên bản Flowable, và đính thuyết minh: BPMN 2.0 kế thừa vai trò điều phối của WS-BPEL; nếu thẩm định bắt buộc WS-BPEL thì bổ sung Apache ODE cho quy trình cụ thể (Q11-02).
6. Hệ thống sinh gói PDF, JSON có băm, lưu kho bằng chứng; Mai tải gói.

**Luồng thay thế.**
- **1a. Phiên đã dọn lịch sử engine.** Hệ thống ghép từ bản nghiệp vụ `ph11_bpm` và kho WORM của PH-13.
- **3a. Xuất CSV.** Qua tác vụ nền (API-11-130), tệp có checksum.
- **4b. Lần chạy mẫu trước.** Mai xem danh sách (API-11-137); gói chưa dựng xong: ERR-11-006 (409).
- **4a. Mẫu chạy lỗi.** Biên bản ghi "Chưa đạt", liệt kê lỗi; chặn tiêu chí nghiệm thu cấp phân hệ về BPMN.

**Luồng ngoại lệ.**
- **E2. Phiên quá hạn lưu giữ (bước 1).** ERR-11-001 (410): "Lịch sử hồ sơ {businessKey} đã hết thời hạn lưu giữ."
- **E4. Khoảng thống kê quá dài (bước 6).** ERR-11-039 (422): "Khoảng thời gian tối đa 12 tháng."

**Quy tắc áp dụng.** BR-11-014, BR-11-025, BR-11-026, BR-11-038; LP-11-04.

**Màn hình, API.** UI-11-12, UI-11-23; API-11-105, 106, 121…123, 130, 137; kịch bản TS-11-24.
:::

## 7. Luồng phụ dùng chung

Sáu luồng phụ dưới đây lặp lại ở nhiều use case nên đặc tả một lần; bước ghi "theo LP-11-nn". Mã lỗi và câu thông báo vẫn ghi ở luồng ngoại lệ của use case dùng.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-11-01 | Bốn mắt: hệ thống so người duyệt với người gửi hoặc người sửa cuối (và người đã xử lý bước trước khi mô hình khai `separateFrom`); trùng thì khóa nút "Duyệt" và trả ERR-11-005 (403) nếu gọi thẳng API. IE và IA là cặp loại trừ trên cùng phiên bản; người đề nghị và người duyệt `instance_change` cũng vậy. Duyệt cần ý kiến, từ chối cần lý do ≥ 20 ký tự (FR-00-071, ADR-046) | UC-11-01, 05, 10, 17, 19 |
| LP-11-02 | Ý kiến, lý do bắt buộc: thiếu thì ERR-11-007 (422) "Nhập {ý kiến, lý do, ghi chú} (tối thiểu {n} ký tự)." (BR-11-033, FR-00-072) | UC-11-04, 05, 10, 11, 16, 17, 19, 22 |
| LP-11-03 | Xung đột đồng thời và trạng thái: lệnh sửa mang `If-Match` (thiếu: ERR-00-428); `ETag` lệch trả ERR-11-004 (409) "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới."; sai trạng thái trả ERR-11-006 (409) "{Đối tượng} đang ở trạng thái {trạng thái}, không thể {thao tác}." | UC-11-01, 02, 03, 05, 14, 16, 17, 23 |
| LP-11-04 | Phạm vi dữ liệu và che DLCN: đối tượng tenant khác trả ERR-11-001 (404) "Không tìm thấy {đối tượng} {mã}."; ngoài phạm vi (CB chỉ thấy phiên có việc của mình hoặc đơn vị mình) trả ERR-11-034 (403) "Anh/chị không có quyền xem hồ sơ này."; biến `SENSITIVE` mã hóa khi lưu, che khi hiển thị, không xuất hiện trong sự kiện, lệnh, thông báo, nhật ký (BR-11-014) | UC-11-09, 10, 12, 13, 15, 20, 24 |
| LP-11-05 | Chuyển trạng thái đi cùng sự kiện: outbox ghi cùng giao dịch `ph11_bpm` với thay đổi nghiệp vụ, với engine nguyên tử về hiệu ứng (ghi sau cam kết engine, có đối soát; không phát sự kiện cho thay đổi chưa cam kết, BR-11-023); bản tin, thông điệp, kết quả trùng bị bỏ qua nhờ `inbox_message`; lệnh service task idempotent theo `commandId` (BR-11-022); lỗi đẩy Kafka quá `11.outbox.maxAttempts` lần mở sự cố ERR-11-101, 117 | UC-11-06, 07, 08, 14, 18, 20 |
| LP-11-06 | Phụ thuộc không khả dụng: engine hoặc CSDL không sẵn sàng trả ERR-11-046 (503) "Dịch vụ quy trình tạm thời không sẵn sàng. Thử lại sau."; client thử lại cùng `Idempotency-Key`; PH-04 hoặc PH-17 chậm thì phiên giữ trạng thái chờ, không hoàn lại bước nghiệp vụ | UC-11-02, 06, 07, 22 |

: Luồng phụ dùng chung và use case dùng

## 8. Tổng hợp mã mới và đối chiếu

Tập này chỉ dùng mã đã có ở FRS; mã riêng là UC, LP, ĐN-UC và câu hỏi mở. Mục 8.2 ghi các đề nghị đồng bộ FRS và tình trạng hấp thụ.

### 8.1. Mã mới và độ phủ

Tập này không tạo mã FR, BR, API, ERR, EVT, UI mới; mã mới của FRS 0.2 (API-11-128…137, ERR-11-051, 125) đã dùng ở chương 6. Mã của tập: UC-11-01…24, LP-11-01…06, câu hỏi mở Q11-45…49, đề nghị ĐN-UC-01…06 (đã hấp thụ ở FRS 0.2); đề nghị kịch bản kiểm thử TS-11-01…24 ứng với UC-11-01…24 cho D05-02-PH11. Cả 66 FR thuộc ít nhất một use case (mục 5.4, kiểm bằng ma trận); 48 FR mức M đều có use case mức M tương ứng. FR-11-056 (phát sự kiện tiến độ) hiện thực ở UC-11-20 nhưng kích hoạt từ mọi use case đổi trạng thái phiên.

Năm đề xuất ADR của FRS (chưa có tệp ADR) ở các use case: ADR 110 UC-11-05; ADR 111 UC-11-02; ADR 112 UC-11-07; ADR 113 UC-11-18; ADR 114 UC-11-14.

### 8.2. Đề nghị đồng bộ FRS

FRS 0.2 (Phụ lục C) đã hấp thụ cả sáu đề nghị; tập này sửa theo.

| Mã | Nội dung | Tình trạng | Nơi dùng |
|---|---|---|---|
| ĐN-UC-01 | Một mã cho khoảng báo cáo hoặc xuất quá dài | Đã hấp thụ có sửa: ERR-11-039 (422), 366 ngày, thống kê tuân thủ 12 tháng | UC-11-21, UC-11-24 |
| ĐN-UC-02 | Client hệ thống hủy phiên; 200 hay 202 | Đã hấp thụ: client chỉ `AUTO`, chỉ hủy phiên của mình; 200 khi `NONE` hoặc không cần bù, 202 khi chạy Saga | UC-11-16 |
| ĐN-UC-03 | API xuất CSV nền | Đã hấp thụ: API-11-128, 129, 130 | UC-11-15, 19, 24 |
| ĐN-UC-04 | API `RESTORE` phiên bản | Đã hấp thụ: API-11-131 | UC-11-05 |
| ĐN-UC-05 | Duyệt, từ chối bỏ qua bù trừ | Đã hấp thụ có sửa: API-11-101 chỉ là đề nghị; API-11-132, 133; không dùng `instance_change` | UC-11-19 |
| ĐN-UC-06 | Bằng chứng xử lý thủ công | Đã hấp thụ: `evidence[]`, quy tắc tệp FR-11-043 | UC-11-19 |

: Đề nghị đồng bộ cho FRS

## 9. Câu hỏi mở

Năm câu dưới đây nảy sinh khi viết use case và chưa có đáp án trong FRS; câu Q11-01…08 của FRS vẫn giữ nguyên ở D02-03-PH11 §13.

> **Câu hỏi mở Q11-45:** UC-11-05 bước 4: tenant nhỏ chỉ có một người có `PERM-11-publish` (hoặc người đó cũng là người sửa nháp cuối) nên bốn mắt chặn phát hành mãi (ERR-11-005). Đề xuất TA chỉ định IA tenant lân cận hoặc PA duyệt thay, có lý do và dấu vết riêng; cần Sở KH&CN, PA chốt.

> **Câu hỏi mở Q11-46:** UC-11-06: BR-11-007 chỉ chống trùng khi phiên chưa kết thúc. Sau khi phiên `CANCELLED`, `FAILED` hoặc `COMPENSATED`, DVC nộp lại cùng `businessKey` có được tạo phiên mới không, hay buộc đổi mã hồ sơ. Đề xuất tạo phiên mới nối bằng `previousInstanceId`; cần Cổng DVC xác nhận.

> **Câu hỏi mở Q11-47:** UC-11-16 bước 4: FRS 0.2 đã chốt client hệ thống chỉ dùng `AUTO` và chỉ hủy phiên của mình. Còn mở: trả danh sách bước bù trừ để HTTT một cửa báo công dân.

> **Câu hỏi mở Q11-48:** UC-11-14 bước 4: PH-12 không trả được lãnh đạo đơn vị nên mức "báo lãnh đạo" bị bỏ qua (ERR-11-113). Đề xuất báo TA và nhóm `11.task.fallbackGroup` thay vì bỏ qua im lặng; cần Sở Nội vụ xác nhận cấu trúc đơn vị ở PH-12.

> **Câu hỏi mở Q11-49:** UC-11-19 bước 2: bằng chứng xác nhận bù trừ thủ công (công văn, ảnh chụp màn hình hệ thống cơ quan, biên bản điện thoại) chứa DLCN, có giá trị đối soát liên cơ quan. Cần quy định loại chứng từ chấp nhận, thời gian lưu (đề xuất `11.retention.sagaYears`, tối thiểu 5 năm) và việc cơ quan đối tác có phải ký xác nhận.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-UC và K-TRINH-BAY: 24 use case phủ 66 FR (48 M, 16 S, 2 C), bốn sơ đồ use case, bốn sơ đồ hoạt động (phát hành bốn mắt, liên thông khai sinh, bổ sung hồ sơ và tạm dừng hạn, bù trừ Saga), sáu luồng phụ dùng chung, năm câu hỏi mở Q11-45…49, sáu đề nghị đồng bộ FRS |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: API-11-128…137, ERR-11-051, 125, ERR-11-039 366 ngày, `waiverDecisions[]`, `commandId` UUID v5, nguyên tử về hiệu ứng (Q11-21), bốn tham số mới; đóng sáu ĐN-UC |
