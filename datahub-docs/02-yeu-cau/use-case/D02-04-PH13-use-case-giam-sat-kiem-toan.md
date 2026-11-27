---
ma_tai_lieu: D02-04-PH13
ten: Đặc tả use case phân hệ PH-13 Giám sát và kiểm toán
phien_ban: 0.4
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư dh-platform, đội vận hành nền tảng, cán bộ an toàn thông tin, kiểm toán viên, kiểm thử viên
phan_he: PH-13
mo_ta: Đặc tả 43 use case của phân hệ giám sát xuyên suốt và nhật ký kiểm toán chỉ-thêm có chuỗi băm, phủ đủ 62 yêu cầu chức năng, theo hành trình thật của người trực, cán bộ ATTT, kiểm toán viên và các phân hệ khác, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH13 FRS; D03-04-PH13 API; D03-06-PH13 Màn hình; D05-02-PH13 Test case; D02-08 ma trận phân quyền
---

# D02-04-PH13 · Đặc tả use case Giám sát và kiểm toán

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả 43 use case cho thấy PH-13 được dùng như thế nào trong thực tế, từ lúc một lượt gọi API sinh dữ liệu quan sát đến lúc người trực nhận cảnh báo lúc nửa đêm, và từ lúc một thao tác nghiệp vụ sinh bản ghi kiểm toán đến lúc kiểm toán viên cầm gói bằng chứng ký số trong tay. Use case đi theo hai trục mà FRS đã tách bạch: **quan sát vận hành** (hệ thống có khỏe không, chậm ở đâu, ai cần được gọi dậy) và **kiểm toán** (ai làm gì với đối tượng nào, khi nào, và dấu vết đó có bị sửa không). Mỗi use case ghi rõ người làm, điều kiện, từng bước kiểm chứng được, nhánh thay thế và nhánh lỗi kèm câu thông báo người dùng nhìn thấy.

**Phạm vi.** 43 use case phủ đủ 62 FR của [D02-03-PH13](../frs/D02-03-PH13-frs-giam-sat-kiem-toan.md): 52 FR mức M, 8 mức S, 2 mức C (FR-13-055, 062, Đợt sau). Ba use case thuộc Đợt sau là UC-13-37 (báo cáo sự cố, thông báo vi phạm dữ liệu cá nhân), UC-13-41 (đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập) và UC-13-43 (khôi phục chuỗi kiểm toán sau sự cố, đường ngoại lệ có biên bản của BR-13-033); chúng được đặc tả sớm để thiết kế không chặn việc mở rộng. 27 use case do người khởi phát, 15 use case do hệ thống hoặc phân hệ khác khởi phát (thu thập, ghi chuỗi, neo, đối chiếu, đánh giá luật, cung cấp dữ liệu, khởi tạo tenant); cả 15 vẫn được đặc tả ở mức đầy đủ vì chính chúng quyết định độ tin cậy của nhật ký.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-09 (Công văn 631/THH-THHT: giám sát, thống kê theo thời gian thực), CMP-LAW-16 (Luật An ninh mạng 116/2025: nhật ký hệ thống, lưu trong nước), CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3), CMP-LAW-01 (Luật Dữ liệu 60/2024: ghi vết khai thác dữ liệu), CMP-LAW-05 và CMP-LAW-04 (Luật BVDLCN 91/2025, NĐ 356/2025: không dữ liệu cá nhân trong log, báo vi phạm 72 giờ), CMP-LAW-03 (NĐ 278/2025: nhật ký khai thác dữ liệu kết nối quốc gia).

**Những điểm hội đồng cần lưu ý.**

1. Bốn use case nhạy cảm nhất, UC-13-08 (đứt chuỗi kiểm toán), UC-13-12 (tra cứu nhật ký), UC-13-15 (xuất bằng chứng) và UC-13-16 (truy cập liên tenant), cùng tuân một bộ nguyên tắc: lý do bắt buộc, ghi vết trước khi trả kết quả, xác thực lại phiên với thao tác xuất, và không có bước nào cho phép sửa hay nối lại chuỗi (BR-13-006, 007, 033).
2. PH-13 chỉ **đề xuất** khi có cảnh báo an ninh: quyết định tạm ngừng HTTT thuộc PH-01 (UC-13-35), gửi thư và tin nhắn SMS thuộc PH-18 (UC-13-28), tính chỉ tiêu thuộc PH-16 (UC-13-38). Ranh giới này giữ để mỗi phân hệ chỉ có một chủ.
3. Người trực chỉ bị gọi dậy vì **triệu chứng người dùng** (BR-13-009) và mỗi cảnh báo có runbook năm mục hiển thị ngay trong màn xử lý (UC-13-29); mục tiêu phát hiện sự cố nghiêm trọng ≤ 5 phút (KPI-15) được kiểm bằng chuỗi UC-13-04 (kiểm tra tổng hợp), UC-13-28 (đánh giá và gửi), UC-13-29 (xác nhận).
4. Không use case nào chặn người dùng nghiệp vụ khi PH-13 ngừng: UC-13-09 mô tả bản ghi chờ ở hộp thư đi và Kafka, không mất, không chặn; ngoại lệ duy nhất là dữ liệu Nhạy cảm không bảo đảm ghi vết ở nguồn thì bên gọi từ chối phục vụ (BR-13-003).
5. Năm câu hỏi mở riêng của tập này (Q13-45…49) nằm ở chương 9; phần lớn là điểm lệch nhỏ giữa quyền và màn hình cần chốt ở đợt đồng bộ.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Use case | 43 (UC-13-01…43): 35 mức M, 6 mức S, 2 mức C |
| FR được phủ | 62 trên 62 (FR-13-001…062) |
| Người khởi phát, hệ thống khởi phát | 28 và 15 |
| Luồng thay thế, luồng ngoại lệ | 114 và 206 (mỗi luồng là một ca kiểm thử ở D05-02-PH13) |
| Luồng phụ dùng chung | 7 (LP-13-01…07) |
| Tác nhân người | 10 vai trò (PA, PO, TA, TO, SO, IE, IA, SV, VW, AU) |
| Câu hỏi mở của tập | 5 (Q13-45…49) |

: Con số chính của tập use case PH-13 bản 0.1

## 1. Giới thiệu

Chương này nêu tài liệu dùng để làm gì, phủ những gì, ai đọc phần nào và tra mã ở đâu. Người đọc mới nên đọc chương 1 đến chương 5 trước khi vào đặc tả chi tiết ở chương 6.

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các thành phần của PH-13 (bộ thu thập, bộ tiếp nhận kiểm toán, bộ neo, Ruler, Alertmanager, `dh-console`), các phân hệ khác và hệ thống bên ngoài để hoàn thành từng việc nghiệp vụ của PH-13. Phạm vi là toàn bộ FR-13-001…061. Chức năng dùng chung FR-00 (đăng nhập, phân quyền, xuất tệp, thông báo, hộp "Việc của tôi") không đặc tả lại; bước dựa vào chúng ghi "Tuân thủ FR-00-nnn". Hành vi chi tiết từng bước (kiểm tra, ngưỡng, mã lỗi, câu thông báo) nằm ở FR tương ứng; use case mô tả trình tự và vai trò để người thiết kế màn hình, API và kiểm thử viên thấy trọn một việc.

Tài liệu không đặc tả lại công thức băm, định dạng bản ghi kiểm toán, nhãn quan sát (FRS §4.7, §4.8), cũng không liệt kê tham số `13.*` (FRS §8.3); use case chỉ nêu giá trị cụ thể khi một bước cần.

### 1.2. Người đọc

Bảng sau gợi ý phần nên đọc theo vai trò.

| Người đọc | Phần cần đọc |
|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 4 (sơ đồ tổng), chương 5 (truy vết), UC-13-08, 12, 15, 28, 35 |
| Kỹ sư `dh-platform`, kỹ sư giao diện | Chương 6, đối chiếu cột Màn hình, API; chương 7 (luồng phụ) |
| Cán bộ ATTT, kiểm toán viên | UC-13-05…16 (kiểm toán), UC-13-33…37 (phát hiện bất thường) |
| Người vận hành, người trực | UC-13-17…32 (chẩn đoán, bảng điều khiển, cảnh báo) |
| Kiểm thử viên | Chương 6: mỗi luồng chính, luồng thay thế, luồng ngoại lệ là một ca kiểm thử ở D05-02-PH13 |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và tài liệu tham chiếu

Thuật ngữ, chữ viết tắt và vai trò dùng chung với [D02-03-PH13](../frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) §1.4 và D00-01 (chuỗi băm, neo, WORM, runbook, trace, tail sampling, MTTD…). Từ riêng của tập này: **phiên liên tenant** là phiên có lý do và thời hạn mà người dùng cấp nền tảng mở để vào dữ liệu của tenant khác (FR-00-012, BR-13-018); **hộp thư đi** (outbox) là bảng trong DU nguồn giữ bản ghi kiểm toán cho tới khi Kafka xác nhận. Tài liệu tham chiếu: D02-03-PH13 (FRS, nguồn của mọi mã lỗi, câu thông báo và quy tắc nghiệp vụ), D03-04-PH13 (API), D03-06-PH13 (màn hình), D05-02-PH13 (ca kiểm thử), D02-08 (ma trận phân quyền), D03-07 §7 (nhật ký kiểm toán, SIEM, UC-SEC-01…25), D03-09 §9 (cảnh báo hạ tầng).

### 1.4. Cấu trúc tài liệu

Chương 2 nêu cách đọc đặc tả; chương 3 tác nhân; chương 4 sơ đồ use case tổng chia sáu hình; chương 5 ba bảng truy vết (UC với FR, với màn hình và API, với REQ, quy trình và hệ cũ); chương 6 đặc tả 42 use case; chương 7 luồng phụ dùng chung; chương 8 tổng hợp mã mới; chương 9 câu hỏi mở; chương 10 đề nghị đồng bộ.

## 2. Quy ước đọc đặc tả

Mỗi use case đặc tả bằng một bảng hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ (kèm câu thông báo), Quy tắc áp dụng, Màn hình và API. Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `3a`) và quay lại luồng chính. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh, rồi kết thúc use case hoặc quay lại bước nêu rõ. Với use case do hệ thống khởi phát, chủ ngữ của bước là "Hệ thống" hoặc tên thành phần; người dùng chỉ xuất hiện ở bước họ thật sự làm.

Mã lỗi `ERR-13-nnn` kèm câu trong ngoặc kép lấy nguyên văn từ FRS §9.2. Lỗi chạy nền (`ERR-13-101…126`) không trả cho ai mà hiện ở bảng cách ly, cảnh báo hoặc UI-13-17, UI-13-18; use case ghi rõ nơi người vận hành thấy. Mọi bước ghi bản ghi kiểm toán dùng tên `action` ở FRS §6.3 (ví dụ `AUDIT.QUERY`). Dữ liệu ví dụ đều giả lập: tenant `T68`; ngày 26/11/2026 giờ `Asia/Ho_Chi_Minh`; người dùng **Chi** (TO), **Dũng** (SO), **Khoa** (AU, thanh tra tỉnh), **Giang** (TA), **Hà** (PA), **Lan** (PO), **An** (IE), **Minh** (SV), **Phúc** (VW, lãnh đạo Sở); HTTT `htt-dvc`, `HT-TUPHAP`, `HT-QLVB`; API `cong-dan.tra-cuu`; `trace_id` ví dụ `4bf92f3577b34da6a3ce929d0e0e4736`.

## 3. Tác nhân

Tác nhân gồm mười vai trò người và các nhóm hệ thống. Viết tắt dùng như FRS §3.1; `ROLE-PLATFORM_AUDITOR` gộp vào AU khi mô tả quyền (cùng quyền, phạm vi toàn nền tảng, mọi truy cập tenant khác qua phiên liên tenant có lý do).

| Tác nhân | Viết tắt | Loại | Người ví dụ | Use case chính |
|---|---|---|---|---|
| ROLE-PLATFORM_ADMIN | PA | Chính | Hà | 25, 26, 27, 36, 42 (và mọi UC cấu hình cấp nền tảng) |
| ROLE-PLATFORM_OPERATOR | PO | Chính | Lan | 19, 23, 26, 29, 31 |
| ROLE-TENANT_ADMIN | TA | Chính | Giang | 04, 16, 22, 25, 26, 30, 33, 36, 42 |
| ROLE-TENANT_OPERATOR | TO | Chính | Chi | 17, 18, 19, 20, 21, 23, 26, 29, 30, 32 |
| ROLE-SECURITY_OFFICER | SO | Chính | Dũng | 07, 08, 12, 14, 15, 16, 24, 33, 35, 37 |
| ROLE-INTEGRATION_ENGINEER, ROLE-INTEGRATION_APPROVER | IE, IA | Chính | An | 13, 17, 18, 19, 21 |
| ROLE-SERVICE_OWNER | SV | Chính | Minh | 22 |
| ROLE-VIEWER | VW | Chính | Phúc | 20, 24 |
| ROLE-AUDITOR, ROLE-PLATFORM_AUDITOR | AU | Chính | Khoa | 07, 12, 14, 15, 16 |
| Mọi DU và thành phần nền, APISIX, Kafka, ClickHouse | — | Chính (máy) | — | 01, 03, 05, 09, 11 |
| Bộ neo, bộ kiểm tra toàn vẹn, bộ phát hiện bất thường, Ruler, Alertmanager | — | Chính (hệ thống) | — | 02, 06, 10, 28, 31, 34 |
| PH-16, PH-18, PH-20 | — | Chính (máy) | — | 38, 39, 40, 41 |
| OpenBao, kho WORM Ceph RGW, SIEM, PH-01, PH-12, Kafka, Grafana, dịch vụ gửi thư và SMS của PH-18 | — | Phụ | — | Nhiều use case |

: Tác nhân của PH-13 và use case chính

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, sơ đồ tổng chia sáu hình theo nhóm nghiệp vụ: thu thập dữ liệu quan sát (Hình 1), ghi vết và bảo vệ nhật ký kiểm toán (Hình 2), tra cứu và bằng chứng (Hình 3), chẩn đoán và bảng điều khiển (Hình 4), cảnh báo vận hành (Hình 5), phát hiện bất thường, cung cấp dữ liệu và vòng đời tenant (Hình 6).

```{.mermaid caption="Use case thu thập dữ liệu quan sát"}
flowchart LR
  DU([DU và thành phần nền])
  AX([APISIX, Kafka, ClickHouse])
  TA([Quản trị tỉnh])
  SO([Cán bộ ATTT])
  subgraph TT["Thu thập dữ liệu quan sát"]
    U01["UC-13-01 Thu chỉ số, log, vết"]
    U02["UC-13-02 Che dữ liệu, quét lọt"]
    U03["UC-13-03 Siêu dữ liệu lượt gọi, hạ tầng"]
    U04["UC-13-04 Kiểm tra tổng hợp"]
  end
  DU --> U01
  DU --> U02
  AX --> U03
  TA --> U04
  SO --> U02
```

Hình 1 cho thấy nhóm thu thập hầu hết do máy khởi phát. Hai chỗ có người là quản trị tỉnh khai báo kiểm tra tổng hợp (UC-13-04) và cán bộ ATTT xem kết quả quét dữ liệu cá nhân trong log (UC-13-02). Việc cách ly theo tenant (FR-13-009) không phải bước riêng mà là điều kiện của mọi bước ghi và đọc, nên gắn vào UC-13-01.

```{.mermaid caption="Use case ghi vết và bảo vệ nhật ký kiểm toán"}
flowchart LR
  AD([dh-audit của DU nguồn])
  SY([Hệ thống PH-13])
  SO([Cán bộ ATTT])
  AU([Kiểm toán viên])
  PO([Vận hành nền tảng])
  subgraph GV["Ghi vết và bảo vệ chuỗi"]
    U05["UC-13-05 Tiếp nhận, ghi chuỗi băm"]
    U06["UC-13-06 Neo hằng giờ, sao WORM"]
    U07["UC-13-07 Kiểm tra toàn vẹn"]
    U08["UC-13-08 Xử lý đứt chuỗi"]
    U09["UC-13-09 Chịu lỗi, đối chiếu số lượng"]
    U10["UC-13-10 Lưu giữ, lưu trữ phân vùng"]
    U11["UC-13-11 Ghi vết thao tác của PH-13"]
  end
  AD --> U05
  AD --> U09
  SY --> U06
  SY --> U10
  SY --> U11
  AU --> U07
  SO --> U07
  SO --> U08
  PO --> U09
```

Hình 2 là trục an toàn của phân hệ. Bản ghi đi từ DU nguồn vào chuỗi (UC-13-05), được neo và sao sang WORM (UC-13-06), bị kiểm tra lại hằng ngày hoặc theo yêu cầu (UC-13-07); phát hiện đứt chuỗi chuyển sang xử lý nghiêm trọng (UC-13-08). UC-13-09 bảo đảm không mất bản ghi khi một khâu ngừng, UC-13-10 giữ 12 tháng trực tuyến và 5 năm trên WORM, UC-13-11 bảo đảm người xem nhật ký cũng để lại dấu vết.

```{.mermaid caption="Use case tra cứu nhật ký kiểm toán và bằng chứng"}
flowchart LR
  AU([Kiểm toán viên])
  SO([Cán bộ ATTT])
  TA([Quản trị tỉnh])
  UH([Người dùng phân hệ chủ])
  subgraph TC["Tra cứu và bằng chứng"]
    U12["UC-13-12 Tra cứu, xem chi tiết, xác minh băm"]
    U13["UC-13-13 Lịch sử của một đối tượng"]
    U14["UC-13-14 Tra theo đối tượng bị tra cứu"]
    U15["UC-13-15 Xuất bằng chứng ký số"]
    U16["UC-13-16 Rà soát truy cập liên tenant"]
  end
  AU --> U12
  AU --> U14
  AU --> U15
  SO --> U12
  SO --> U14
  SO --> U15
  TA --> U16
  AU --> U16
  UH --> U13
```

Hình 3 cho thấy năm use case của người điều tra. Chỉ UC-13-13 dành cho người dùng nghiệp vụ thường (xem lịch sử đối tượng mình đang mở); bốn use case còn lại cần `PERM-13-audit-read` hoặc `PERM-13-audit-export` và đều đòi lý do, riêng xuất bằng chứng đòi thêm xác thực lại phiên.

```{.mermaid caption="Use case chẩn đoán và bảng điều khiển"}
flowchart LR
  TO([Vận hành tỉnh])
  IE([Kỹ sư tích hợp])
  TA([Quản trị tỉnh])
  VW([Người xem, lãnh đạo])
  PO([Vận hành nền tảng])
  subgraph CD["Chẩn đoán"]
    U17["UC-13-17 Tra log, theo dõi trực tiếp"]
    U18["UC-13-18 Truy vết, liên kết ba nguồn"]
    U19["UC-13-19 Tra nhật ký truy cập API"]
  end
  subgraph BD["Bảng điều khiển"]
    U20["UC-13-20 Tổng quan nền tảng"]
    U21["UC-13-21 Data plane"]
    U22["UC-13-22 Theo API, theo HTTT"]
    U23["UC-13-23 Gateway, Kafka"]
    U24["UC-13-24 Nghiệp vụ, an ninh"]
    U25["UC-13-25 Bộ dashboard"]
  end
  TO --> U17
  TO --> U20
  TO --> U21
  IE --> U18
  IE --> U19
  IE --> U21
  TA --> U22
  TA --> U25
  VW --> U24
  PO --> U23
  PO --> U19
```

Hình 4 gom chín use case của người vận hành. Chúng nối với nhau bằng `trace_id`: từ một điểm bất thường trên bảng điều khiển người dùng nhảy sang danh sách trace lỗi (UC-13-18), từ đó sang log (UC-13-17) và nhật ký truy cập API (UC-13-19).

```{.mermaid caption="Use case cảnh báo vận hành"}
flowchart LR
  PA([Quản trị nền tảng])
  TA([Quản trị tỉnh])
  TO([Vận hành tỉnh])
  SY([Ruler, Alertmanager])
  subgraph CB["Cảnh báo"]
    U26["UC-13-26 Luật kèm runbook, chạy thử"]
    U27["UC-13-27 Bộ luật chuẩn"]
    U28["UC-13-28 Từ điều kiện tới người trực"]
    U29["UC-13-29 Xác nhận, đã xử lý, tạm ẩn"]
    U30["UC-13-30 Lịch trực, kênh"]
    U31["UC-13-31 Giám sát hệ thống giám sát"]
    U32["UC-13-32 Thống kê hiệu quả"]
  end
  PA --> U27
  TA --> U26
  TA --> U30
  TO --> U26
  TO --> U29
  TO --> U32
  SY --> U28
  SY --> U31
```

Hình 5 vẽ vòng đời của một cảnh báo: luật (UC-13-26, 27) tạo điều kiện, hệ thống đánh giá và gửi (UC-13-28), người trực xử lý (UC-13-29) theo lịch và kênh đã khai (UC-13-30), thống kê (UC-13-32) đưa kết quả về chỉnh luật. UC-13-31 đứng ngoài đường chính để phát hiện khi chính đường này hỏng.

```{.mermaid caption="Use case phát hiện bất thường, cung cấp dữ liệu và vòng đời tenant"}
flowchart LR
  SO([Cán bộ ATTT])
  TA([Quản trị tỉnh, nền tảng])
  SY([Bộ phát hiện bất thường])
  P16([PH-16])
  P18([PH-18, phân hệ khác])
  P20([PH-20])
  subgraph AN["An ninh"]
    U33["UC-13-33 Tinh chỉnh luật UC-SEC"]
    U34["UC-13-34 Phát hiện từ bản ghi kiểm toán"]
    U35["UC-13-35 Xử lý cảnh báo, đề xuất tạm ngừng"]
    U36["UC-13-36 Đẩy SIEM, SOC"]
    U37["UC-13-37 Báo cáo sự cố, vi phạm DLCN"]
  end
  subgraph DL["Cung cấp dữ liệu, vòng đời tenant"]
    U38["UC-13-38 Số liệu cho PH-16"]
    U39["UC-13-39 Ngữ cảnh, sức khỏe cho PH-18"]
    U40["UC-13-40 Khởi tạo tenant"]
    U41["UC-13-41 Đóng chuỗi tenant"]
    U42["UC-13-42 Tham số, hạn mức"]
    U43["UC-13-43 Khôi phục chuỗi sau sự cố"]
  end
  SO --> U33
  SO --> U35
  SO --> U37
  SY --> U34
  TA --> U36
  TA --> U42
  P16 --> U38
  P18 --> U39
  P20 --> U40
  P20 --> U41
```

Hình 6 gom hai phần. Phần an ninh có hai nguồn phát hiện (luật trên log, chỉ số và bộ phát hiện trên bản ghi kiểm toán) hội tụ ở một vòng xử lý của cán bộ ATTT, với ba lối ra là SIEM, báo cáo sự cố và đề xuất tạm ngừng HTTT sang PH-01. Phần dữ liệu và vòng đời là các điểm vào của máy: PH-16, PH-18 lấy số liệu, ngữ cảnh; PH-20 khởi tạo và đóng chuỗi.

## 5. Bảng tổng hợp use case và truy vết

Ba bảng dưới nối mỗi use case với FR, với màn hình và API, và với REQ, quy trình, chức năng hệ cũ. Số FR viết rút gọn, bỏ tiền tố `FR-13-`.

### 5.1. Use case và FR

Bảng dưới gắn mỗi use case với các chức năng FR-13 mà nó hiện thực; mọi FR của PH-13 đều thuộc ít nhất một use case, và chiều ngược lại nằm ở trường "Truy vết" của từng FR trong D02-03-PH13. Cột FR ghi ba chữ số cuối của mã `FR-13-nnn`.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-13-01 | Thu chỉ số, log, vết truy nguyên từ mọi thành phần | DU, thành phần nền | M | 001, 002, 003, 004, 009 |
| UC-13-02 | Che dữ liệu Nhạy cảm và quét phát hiện lọt | Bộ quét (SO xem kết quả) | M | 005 |
| UC-13-03 | Thu siêu dữ liệu lượt gọi API và chỉ số thành phần nền | APISIX, Kafka, ClickHouse | M | 006, 007 |
| UC-13-04 | Cấu hình và chạy kiểm tra tổng hợp | TA | M | 008 |
| UC-13-05 | Tiếp nhận và ghi bản ghi vào chuỗi băm theo tenant | `dh-audit` của DU | M | 010, 011 |
| UC-13-06 | Neo băm ký hằng giờ và sao lô sang WORM | Bộ neo, bộ sao WORM | M | 012, 013 |
| UC-13-07 | Kiểm tra toàn vẹn chuỗi kiểm toán | AU, SO | M | 014 |
| UC-13-08 | Xử lý đứt chuỗi hoặc neo không khớp | SO | M | 015 |
| UC-13-09 | Chịu lỗi, đệm và đối chiếu số lượng bản ghi | DU nguồn | M | 016, 017 |
| UC-13-10 | Lưu giữ và lưu trữ phân vùng kiểm toán | Bộ quản lý phân vùng | M | 018 |
| UC-13-11 | Ghi vết thao tác của người dùng PH-13 | `dh-platform` | M | 019 |
| UC-13-12 | Tra cứu nhật ký kiểm toán, xem chi tiết và xác minh băm | AU, SO | M | 020, 021 |
| UC-13-13 | Xem lịch sử thay đổi của một đối tượng | Người dùng phân hệ chủ | M | 022 |
| UC-13-14 | Tra theo đối tượng bị tra cứu | SO, AU | S | 023 |
| UC-13-15 | Xuất bằng chứng kiểm toán ký số | AU, SO | M | 024 |
| UC-13-16 | Rà soát truy cập liên tenant | TA, SO, AU | S | 025 |
| UC-13-17 | Tra log tập trung và theo dõi trực tiếp | TO, IE | M | 026, 027 |
| UC-13-18 | Truy vết một yêu cầu và liên kết ba nguồn | TO, IE | M | 028, 029 |
| UC-13-19 | Tra nhật ký truy cập API | TO, PO, IE | M | 030 |
| UC-13-20 | Theo dõi tổng quan nền tảng | TO, VW | M | 031 |
| UC-13-21 | Theo dõi data plane: đơn vị triển khai, luồng, route, endpoint | TO, IE | M | 032, 033, 034 |
| UC-13-22 | Theo dõi theo API và theo HTTT | TA, SV, TO | M | 035 |
| UC-13-23 | Theo dõi hạ tầng: nút gateway và cụm Kafka | PO, TO | M | 036, 037, 038 |
| UC-13-24 | Xem hoạt động nghiệp vụ và bảng điều khiển an ninh | VW, SO | M | 039, 040 |
| UC-13-25 | Quản lý bộ dashboard theo tenant | PA, TA | S | 041 |
| UC-13-26 | Tạo luật cảnh báo kèm runbook và chạy thử | TA, TO | M | 042 |
| UC-13-27 | Phát hành bộ luật cảnh báo chuẩn của nền tảng | PA | M | 043 |
| UC-13-28 | Từ điều kiện bất thường đến thông báo tới người trực | Ruler, Alertmanager | M | 044, 045, 046 |
| UC-13-29 | Xử lý cảnh báo: xác nhận, đã xử lý, tạm ẩn | TO | M | 047 |
| UC-13-30 | Quản lý lịch trực, nhóm nhận, kênh thông báo | TA, TO | M | 048 |
| UC-13-31 | Giám sát chính hệ thống giám sát | Hệ thống (PA, PO xem) | M | 049 |
| UC-13-32 | Xem thống kê hiệu quả cảnh báo | TO, TA | S | 050 |
| UC-13-33 | Tinh chỉnh bộ luật phát hiện UC-SEC | SO | M | 051 |
| UC-13-34 | Phát hiện bất thường từ bản ghi kiểm toán | Bộ phát hiện (SO nhận) | M | 052 |
| UC-13-35 | Xử lý cảnh báo an ninh và đề xuất tạm ngừng HTTT | SO | M | 053 |
| UC-13-36 | Đẩy log và cảnh báo an ninh sang SIEM, SOC | TA, PA | M | 054 |
| UC-13-37 | Lập báo cáo sự cố và thông báo vi phạm dữ liệu cá nhân | SO | C | 055 |
| UC-13-38 | PH-16 lấy số liệu tổng hợp | PH-16 | M | 056 |
| UC-13-39 | PH-18 và phân hệ khác lấy ngữ cảnh chẩn đoán, sức khỏe thành phần | PH-18 | M | 057, 058 |
| UC-13-40 | Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới | PH-20 | M | 059 |
| UC-13-41 | Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập | PH-20 | S | 060 |
| UC-13-42 | Đặt tham số và hạn mức quan sát theo tenant | PA, TA | S | 061 |
| UC-13-43 | Khôi phục chuỗi kiểm toán sau sự cố mất dữ liệu (đường ngoại lệ có biên bản) | Đội vận hành; SO và TA cùng ký | C | 062 |

: Use case và FR hiện thực

Mọi FR mức M và S có ít nhất một use case; FR-13-055 (mức C, Đợt sau) thuộc UC-13-37, FR-13-060 (mức S, Đợt sau) thuộc UC-13-41 và FR-13-062 (mức C, Đợt sau) thuộc UC-13-43. FR-13-019 (ghi vết thao tác của PH-13) là yêu cầu xuyên suốt: ngoài UC-13-11, nó được áp dụng ở bước kiểm toán của UC-13-12, 14, 15, 16, 26, 29, 30, 33, 35, 36, 41, 42.

### 5.2. Use case, màn hình và API

Bảng dưới cho biết mỗi use case có người thao tác hiển thị ở màn hình nào và gọi những API nào; dấu "—" là use case do máy khởi phát, không qua giao diện hoặc không có API điều khiển riêng. Cột UI ghi hai chữ số cuối của `UI-13-nn`, cột API ghi ba chữ số cuối của `API-13-nnn`, khớp với trường "Màn hình, API" ở từng use case ở chương 6.

| UC | UI | API |
|---|---|---|
| UC-13-01 | UI-13-01 (dải "Bộ thu thập quá tải"), UI-13-17 | — (OTLP, Prometheus scrape) |
| UC-13-02 | UI-13-06 (kết quả quét) | API-13-016 |
| UC-13-03 | UI-13-01 | — (Kafka `{tenant}.obs.access.logged.v1`) |
| UC-13-04 | UI-13-01, 17 | API-13-070, 071 |
| UC-13-05 | UI-13-18 | API-13-087, 089 |
| UC-13-06 | UI-13-14, 18 | API-13-080, 081, 087 |
| UC-13-07 | UI-13-14 | API-13-077, 078, 079 |
| UC-13-08 | UI-13-14, 18 | API-13-079 |
| UC-13-09 | UI-13-18 | API-13-086, 087, 089 |
| UC-13-10 | UI-13-18 | API-13-088 |
| UC-13-11 | — (tra ở UI-13-13) | — |
| UC-13-12 | UI-13-13 | API-13-074, 075, 080 |
| UC-13-13 | Tab Lịch sử (PTN-02), UI-13-13 | API-13-076 |
| UC-13-14 | UI-13-13 | API-13-074 |
| UC-13-15 | UI-13-14, UI-13-13 | API-13-082, 083, 084 |
| UC-13-16 | UI-13-16 | API-13-085 |
| UC-13-17 | UI-13-07 | API-13-019, 020, 021, 027, 028, 029 |
| UC-13-18 | UI-13-08 | API-13-022, 023, 024 |
| UC-13-19 | UI-13-09 | API-13-025, 026 |
| UC-13-20 | UI-13-01 | API-13-001, 002 |
| UC-13-21 | UI-13-02 | API-13-003, 004, 005, 006, 007, 008 |
| UC-13-22 | UI-13-03 | API-13-009, 010 |
| UC-13-23 | UI-13-04 | API-13-011, 012, 013, 014 |
| UC-13-24 | UI-13-05, 06 | API-13-015, 016 |
| UC-13-25 | UI-13-17 | API-13-017, 018 |
| UC-13-26 | UI-13-11 | API-13-035…044 |
| UC-13-27 | UI-13-11 | API-13-035, 037 |
| UC-13-28 | UI-13-10, 12 | API-13-030, 090 |
| UC-13-29 | UI-13-10 | API-13-030, 031, 032, 033, 034 |
| UC-13-30 | UI-13-12 | API-13-045…051 |
| UC-13-31 | UI-13-01 | API-13-053 |
| UC-13-32 | UI-13-10 | API-13-052 |
| UC-13-33 | UI-13-15 | API-13-054, 055 |
| UC-13-34 | UI-13-15 | API-13-056 |
| UC-13-35 | UI-13-15 | API-13-056, 057, 058, 059, 060 |
| UC-13-36 | UI-13-17 | API-13-061, 062, 063, 064 |
| UC-13-37 | UI-13-15 | API-13-065, 066 |
| UC-13-38 | — | API-13-067, 068 |
| UC-13-39 | UI-13-01 | API-13-002, 069 |
| UC-13-40 | — | API-13-072 |
| UC-13-41 | UI-13-17, UI-13-13 | API-13-073 |
| UC-13-42 | UI-13-17 | API-13-070, 071 |
| UC-13-43 | — | — |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Quy trình dùng mã BP của D02-01: BP-07 là giám sát, xử lý sự cố và báo cáo; BP-08 khởi tạo tenant; BP-09 chuyển đổi từ hệ cũ. Với các use case kiểm toán, PH-13 là nơi ghi dấu vết cho mọi quy trình BP-01…06 nên cột quy trình ghi "Mọi quy trình (ghi dấu vết)". Cột LGC chỉ liệt kê mã hệ cũ có kết luận ở FRS §11.1.

| UC | REQ | Quy trình | LGC |
|---|---|---|---|
| UC-13-01 | REQ-13, REQ-20 | BP-07 | LGC-BUS-029, LGC-BUS-030, LGC-BUS-038, LGC-NFR-004 |
| UC-13-02 | REQ-09, REQ-13 | BP-07 | LGC-APIM-022 |
| UC-13-03 | REQ-03, REQ-13 | BP-07 | LGC-APIM-022; LGC-BUS-027, LGC-BUS-016, LGC-BUS-030, LGC-HUB-005, LGC-HUB-006 |
| UC-13-04 | REQ-13 | BP-07 | Không |
| UC-13-05 | REQ-13 | Mọi quy trình (ghi dấu vết) | LGC-APIM-027 |
| UC-13-06 | REQ-13 | Mọi quy trình (ghi dấu vết) | LGC-APIM-027; LGC-NFR-005 |
| UC-13-07, 08 | REQ-13 | BP-07, quy trình ứng cứu D03-07 §8 | LGC-APIM-027 |
| UC-13-09 | REQ-13 | BP-07 | LGC-APIM-027 |
| UC-13-10 | REQ-13 | Mọi quy trình (ghi dấu vết) | LGC-APIM-027; LGC-NFR-005 |
| UC-13-11 | REQ-13 | Mọi quy trình (ghi dấu vết) | LGC-APIM-027 |
| UC-13-12 | REQ-13 | BP-07, BP-09 | LGC-APIM-027 |
| UC-13-13 | REQ-13 | Mọi quy trình (ghi dấu vết) | LGC-APIM-027 |
| UC-13-14 | REQ-09, REQ-13 | BP-06 | LGC-APIM-027 |
| UC-13-15 | REQ-13 | BP-07, thanh tra | LGC-APIM-027 |
| UC-13-16 | REQ-13, REQ-20 | BP-07 | LGC-APIM-027 |
| UC-13-17 | REQ-13 | BP-07 | LGC-BUS-029, LGC-PAY-021, LGC-NFR-004 |
| UC-13-18 | REQ-13 | BP-07 | LGC-BUS-038 |
| UC-13-19 | REQ-03, REQ-13 | BP-07 | LGC-APIM-022; LGC-PAY-021 |
| UC-13-20 | REQ-13 | BP-07, BP-09 | LGC-BUS-014, LGC-APIM-026 |
| UC-13-21 | REQ-13 | BP-07, BP-09 | LGC-BUS-007, LGC-BUS-014, LGC-BUS-015, LGC-BUS-016, LGC-BUS-017, LGC-BUS-019, LGC-BUS-027 |
| UC-13-22 | REQ-03, REQ-13 | BP-07 | LGC-APIM-026 |
| UC-13-23 | REQ-13 | BP-07 | LGC-HUB-005, LGC-HUB-006, LGC-APIM-023; LGC-APIM-024; LGC-APIM-025 |
| UC-13-24 | REQ-13 | BP-07 | Không |
| UC-13-25 | REQ-13 | BP-07 | Không |
| UC-13-26 | REQ-13 | BP-07 | Không |
| UC-13-27 | REQ-13 | BP-07 | LGC-PAY-009 |
| UC-13-28 | REQ-13 | BP-07 | LGC-PAY-009 |
| UC-13-29, 30, 31, 32 | REQ-13 | BP-07 | Không |
| UC-13-33, 34 | REQ-13 | Sự cố ATTT (D03-07 §8) | Không |
| UC-13-35 | REQ-01, REQ-13 | Sự cố ATTT (D03-07 §8) | Không |
| UC-13-36 | REQ-13 | Sự cố ATTT (D03-07 §8) | Không |
| UC-13-37 | REQ-13 | Sự cố ATTT (D03-07 §8) | Không |
| UC-13-38 | REQ-13, REQ-16 | BP-07 | Không |
| UC-13-39 | REQ-13, REQ-18 | BP-07 | Không |
| UC-13-40, 41 | REQ-13, REQ-20 | BP-08 | Không |
| UC-13-42 | REQ-13 | BP-07 | Không |
| UC-13-43 | REQ-13 | Sự cố ATTT (D03-07 §8) | Không |

: Use case, REQ, quy trình và hệ cũ

## 6. Đặc tả chi tiết use case

Chương này đặc tả 43 use case theo tám nhóm giống FRS: thu thập dữ liệu quan sát (UC-13-01…04), ghi vết kiểm toán (UC-13-05…11 và UC-13-43, thuộc Đợt sau), tra cứu kiểm toán và bằng chứng (UC-13-12…16), chẩn đoán (UC-13-17…19), bảng điều khiển (UC-13-20…25), cảnh báo (UC-13-26…32), phát hiện bất thường an ninh (UC-13-33…37), cung cấp dữ liệu và vòng đời tenant (UC-13-38…42); UC-13-43 đặt cuối chương 6 để giữ nguyên số của các use case đã có. Mỗi use case là một khối 15 mục; kỹ sư và kiểm thử viên đọc trực tiếp luồng chính, thay thế, ngoại lệ, hội đồng thẩm định đọc Mục tiêu, Đảm bảo thành công và Quy tắc áp dụng.

### 6.1. UC-13-01 · Thu chỉ số, log, vết truy nguyên từ mọi thành phần

::: dac-ta
**Mục tiêu.** Mọi thành phần của tenant `T68` có chỉ số, log JSON và trace truy vấn được trong vòng 30 giây, đã gắn nhãn tenant lấy từ hệ thống, chỉ mang nhãn trong danh sách cho phép, và không tenant nào đọc được dữ liệu của tenant khác.

**Tác nhân chính.** Mọi DU và thành phần nền (ví dụ `dh-integration`, `dh-runtime`, APISIX), thông qua bộ thu thập OpenTelemetry (Collector).

**Tác nhân phụ.** Mimir, Loki, Tempo, Kubernetes (nhãn namespace và pod), PH-12 (token có claim `tenant`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-001, 002, 003, 004, 009.

**Truy vết.** REQ-13, REQ-20; quy trình BP-07; LGC-BUS-029, LGC-BUS-030, LGC-BUS-038, LGC-NFR-004.

**Tiền điều kiện.** Thành phần phơi điểm cuối chỉ số trên cổng quản trị trong mesh hoặc phát OTLP; chứng thư mTLS còn hạn; tenant `T68` đã được khởi tạo quan sát (UC-13-40).

**Kích hoạt.** Chu kỳ thu 15 giây (`13.metrics.scrape-interval-seconds`); thành phần ghi một dòng log; thành phần kết thúc một span và đẩy OTLP (cổng 4317 hoặc 4318).

**Đảm bảo tối thiểu.** Thành phần nguồn không bị chặn khi kho quan sát chậm hoặc ngừng (BR-13-015); dữ liệu không xác định được tenant không lẫn vào tenant nào mà bị gán `_unattributed`.

**Đảm bảo thành công.** Mẫu chỉ số, dòng log và trace được giữ có mặt ở Mimir, Loki, Tempo trong tổ chức `T68`, mang nhãn `tenant`; truy vấn của người dùng `T68` chỉ trả dữ liệu của `T68`.

**Luồng chính.**

1. `dh-integration` của `T68` phơi điểm cuối chỉ số; Collector dạng agent trên nút scrape mỗi 15 giây.
2. Collector gắn nhãn `namespace`, `pod`, `du`, `service` và `tenant=T68` lấy từ nhãn của namespace (BR-13-027), rồi loại mọi nhãn ngoài danh sách cho phép (BR-13-026).
3. Collector dạng gateway ghi chỉ số vào Mimir bằng remote-write với tổ chức `T68`; trong 30 giây chỉ số xuất hiện ở UI-13-01.
4. Một dòng log JSON có `trace_id` và `tenant_id` được Collector đọc; nhãn Loki chỉ gồm `tenant`, `du`, `namespace`, `level`; dòng đi qua bước che (UC-13-02) rồi ghi vào Loki tổ chức `T68`. Log mức an ninh (xác thực, WAF, OPA từ chối, `pgaudit`) ghi vào tổ chức riêng `T68-security`.
5. Span OTLP được cân bằng theo `trace_id` tới cùng một bản sao gateway; gateway chờ 30 giây sau span cuối rồi quyết định: giữ 100% trace có lỗi, chậm hơn p99 của route hoặc chạm dữ liệu Nhạy cảm; trace thành công bình thường giữ ngẫu nhiên 10%.
6. Trace được giữ ghi vào Tempo tổ chức `T68`; chỉ số theo chặng (span metrics) ghi vào Mimir cho mọi trace, kể cả trace bị bỏ.
7. Khi người dùng `T68` truy vấn bất kỳ kho nào, API của PH-13 lấy tenant từ token, phân tích biểu thức PromQL, LogQL, TraceQL và ép nhãn `tenant="T68"` vào mọi bộ chọn trước khi gọi kho (tuân thủ FR-13-009).

**Luồng thay thế.**

- **1a. `dh-runtime` (Quarkus native).** Thành phần chỉ đẩy OTLP, bỏ bước scrape; các bước 2 đến 6 giữ nguyên.
- **2a. Chỉ số hạ tầng dùng chung của nền tảng.** Chỉ số ghi vào tổ chức `platform` thay vì tổ chức tenant.
- **5a. Trace đi qua hai tenant** (ví dụ luồng chung `COMMON`). Span được tách theo tenant của từng span, `trace_id` giữ nguyên để liên kết.
- **5b. Tỉnh đang điều tra một sự cố.** Giang tăng tạm thời `13.trace.success-sample-percent` có thời hạn (UC-13-42); hết hạn trở về 10%.

**Luồng ngoại lệ.**

- **E1. Mẫu thiếu nhãn tenant (bước 2).** Hệ thống gán `_unattributed` và đếm; ERR-13-113; thông báo cho Hà ở UI-13-17: "Dữ liệu quan sát thiếu nhãn tenant; đã gán không xác định." Chỉ PA và PO xem được phần này.
- **E2. Tenant vượt hạn mức chuỗi hoạt động (bước 2).** Hệ thống bỏ chuỗi mới, giữ chuỗi cũ; ERR-13-114; cảnh báo hạn mức tới PA, TA: "Nhãn {nhãn} không thuộc danh sách cho phép hoặc vượt hạn mức chuỗi; đã bỏ." Khi đạt 85% hạn mức phát EVT-13-14.
- **E3. Collector quá tải (bước 3 đến 6).** Hệ thống đệm xuống đĩa tối đa 2 giờ, bỏ log `DEBUG` rồi `INFO` và trace thành công trước, giữ chỉ số SLO; ERR-13-115; dải ở UI-13-01: "Bộ thu thập quá tải; đang đệm và bỏ dữ liệu ít quan trọng trước."
- **E4. Trace quá 1.000 span (bước 5).** Hệ thống cắt, giữ span đầu, cuối và mọi span lỗi; ERR-13-116: "Trace {traceId} quá dài, đã cắt còn các span đầu, cuối và lỗi."
- **E5. Trace thiếu span (bước 5).** Hệ thống vẫn lưu, đánh dấu `incomplete=true`; ERR-13-117: "Trace {traceId} chưa đủ span; đã lưu và đánh dấu chưa đầy đủ."
- **E6. Truy vấn chạm nhãn tenant khác (bước 7).** ERR-13-044 (403): "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."; hệ thống ghi `OBS.CROSS_TENANT_ATTEMPT` và phát cảnh báo UC-SEC-09. Nếu bộ kiểm thử rò rỉ hằng ngày (T90 đọc T91) thành công một lần, PH-13 ghi sự cố SEV-1 và ngừng truy vấn tự do tới khi sửa.

**Quy tắc áp dụng.** BR-13-010, 026, 027, 030.

**Màn hình, API.** UI-13-01 (dải "Bộ thu thập quá tải"), UI-13-17; không có API riêng (thu qua OTLP và Prometheus scrape).
:::

### 6.2. UC-13-02 · Che dữ liệu Nhạy cảm và quét phát hiện lọt

::: dac-ta
**Mục tiêu.** Log, trace, chỉ số của `T68` không chứa giá trị Nhạy cảm dạng rõ, và cán bộ ATTT có bằng chứng hằng ngày chứng minh điều đó thay vì tin vào lời cam kết của lập trình viên.

**Tác nhân chính.** Bộ quét dữ liệu cá nhân trong log (hệ thống, chạy 02:00 hằng ngày); cán bộ ATTT Dũng (ROLE-SECURITY_OFFICER) xem kết quả.

**Tác nhân phụ.** Collector (lớp che thứ hai), Loki, nhóm phát triển DU nguồn.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-005.

**Truy vết.** REQ-09, REQ-13; quy trình BP-07; LGC-APIM-022.

**Tiền điều kiện.** Thư viện log dùng chung của DU đã che theo chú thích `@Classified` (lớp 1); APISIX chỉ ghi siêu dữ liệu (lớp 3); Dũng có `PERM-13-security`.

**Kích hoạt.** Mỗi dòng log và span qua Collector; 02:00 hằng ngày cho bộ quét.

**Đảm bảo tối thiểu.** Bản ghi phát hiện chỉ chứa dấu hiệu nhận dạng, không bao giờ chứa giá trị gốc (BR-13-011).

**Đảm bảo thành công.** Chỉ số `dh_obs_pii_findings_total` của `T68` bằng 0, hoặc mọi phát hiện đã có cảnh báo tới nhóm phát triển nguồn.

**Luồng chính.**

1. Collector loại thuộc tính span và trường log không nằm trong danh sách cho phép, rồi che mọi giá trị khớp mẫu (số định danh 12 chữ số, số điện thoại, số thẻ, thư điện tử, trường `hoTen`, `soDinhDanh`) bằng `***` giữ độ dài, trước khi ghi Loki và Tempo.
2. Lúc 02:00 bộ quét lấy mẫu 1% log 24 giờ qua của `T68` cộng 100% dòng mức `ERROR` và tìm lại các mẫu Nhạy cảm bằng bộ mẫu độc lập với bộ che.
3. Bộ quét thấy `dh-integration` ghi trường `soDinhDanh` dạng rõ 3 lần ở logger `vn.datahub.integration.flow`; hệ thống ghi vào bảng phát hiện: DU, logger, số lần, mẫu nhận dạng đã che, không có giá trị.
4. Hệ thống phát cảnh báo mức Cảnh báo cho nhóm phát triển `dh-integration` và Dũng (ERR-13-112); chỉ số `dh_obs_pii_findings_total{du="dh-integration"}` bằng 3 (mục tiêu 0, NFR-13-021).
5. Dũng mở UI-13-06 và thấy báo cáo quét: tên DU, logger, số lần, mẫu nhận dạng; không thấy giá trị gốc.
6. Nhóm phát triển sửa mã ghi log; lần quét 02:00 ngày hôm sau cho `dh_obs_pii_findings_total` về 0.

**Luồng thay thế.**

- **2a. DU phát log không phải JSON.** Bộ quét theo mẫu trên toàn dòng thay vì theo trường.
- **4a. Cùng DU tái phạm 3 ngày liên tiếp.** Cảnh báo nâng lên Nghiêm trọng và hệ thống đề nghị bật `quarantine`: loại log của DU đó khỏi kho tra cứu cho tới khi sửa.

**Luồng ngoại lệ.**

- **E1. Loki không khả dụng (bước 2).** ERR-13-014 ghi vào nhật ký bộ quét; thử lại sau 1 giờ; quá 24 giờ chưa quét được thì phát cảnh báo Cảnh báo. Người vận hành thấy: "Dịch vụ Loki tạm thời không khả dụng. Thử lại sau."
- **E2. Người xem thiếu `PERM-13-security` (bước 5).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E3. Phát hiện giá trị Nhạy cảm trong thuộc tính span (bước 2).** Giá trị bị che ở Collector như với log; bản ghi phát hiện ghi `signal=trace`, không ghi giá trị; cảnh báo như bước 4.

**Quy tắc áp dụng.** BR-13-011, 035.

**Màn hình, API.** UI-13-06 (kết quả quét hiển thị ở bảng an ninh); không có API riêng ngoài API-13-016 của FR-13-040.
:::

### 6.3. UC-13-03 · Thu siêu dữ liệu lượt gọi API và chỉ số thành phần nền

::: dac-ta
**Mục tiêu.** Mỗi lượt gọi qua APISIX có một dòng siêu dữ liệu tra được 12 tháng (không có thân bản tin), và mọi thành phần nền (Kubernetes, Kafka, PostgreSQL, APISIX, Keycloak, OPA, OpenBao, ClickHouse, kho đối tượng) có chỉ số sức khỏe và tài nguyên cho bảng điều khiển và luật cảnh báo.

**Tác nhân chính.** APISIX (plugin `kafka-logger`), ClickHouse, Collector (scrape chỉ số hạ tầng).

**Tác nhân phụ.** Kafka, kube-state-metrics, node-exporter, Strimzi exporter, CloudNativePG, Ceph RGW.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-006, 007.

**Truy vết.** REQ-03, REQ-13; quy trình BP-07; LGC-APIM-022; LGC-BUS-027, LGC-BUS-016, LGC-BUS-030, LGC-HUB-005, LGC-HUB-006.

**Tiền điều kiện.** `kafka-logger` bật cho mọi route; topic `t68.obs.access.logged.v1` đã tạo (giữ 3 ngày); các bộ xuất chỉ số hạ tầng đã triển khai.

**Kích hoạt.** APISIX hoàn tất một lượt gọi (thành công, lỗi hoặc bị từ chối); chu kỳ scrape 15 giây.

**Đảm bảo tối thiểu.** Kho quan sát ngừng hoặc chậm không làm APISIX chậm hay lỗi (BR-13-015); bảng `access_log` không bao giờ chứa thân bản tin, giá trị Nhạy cảm hay tiêu đề xác thực.

**Đảm bảo thành công.** Lượt gọi có một dòng ở `access_log` của `T68`; chỉ số hạ tầng có mặt ở Mimir theo danh mục nguồn.

**Luồng chính.**

1. HTTT `htt-dvc` gọi `GET /cong-dan/{id}` của API `cong-dan.tra-cuu`, nhận `200` sau 182 ms. APISIX tạo bản ghi chỉ gồm siêu dữ liệu (đã loại tiêu đề `Authorization` và chuỗi truy vấn) và đẩy bất đồng bộ vào `t68.obs.access.logged.v1` theo lô.
2. ClickHouse tiêu thụ topic bằng bảng động cơ Kafka và view vật chất hóa, ghi vào `access_log` sắp theo `(tenant_id, route_id, ts)`.
3. Hệ thống kiểm tra `tenant_id` của bản ghi khớp tiền tố topic.
4. View vật chất hóa tổng hợp theo phút và theo giờ: số lượt, số lỗi theo lớp, độ trễ p50, p95, p99, để bảng điều khiển tải nhanh.
5. Song song, Collector scrape kube-state-metrics, node-exporter, Strimzi, CloudNativePG, APISIX, Keycloak, OPA, OpenBao, ClickHouse và Ceph RGW mỗi 15 giây; chỉ số dùng chung ghi vào tổ chức `platform`, chỉ số có nhãn tenant (ví dụ lag Kafka theo subscription) ghi vào tổ chức `T68`.
6. Luật chuẩn của nền tảng (UC-13-27) được đánh giá trên các chỉ số này, ví dụ phân vùng Kafka thiếu bản sao hoặc PostgreSQL không có standby đồng bộ.

**Luồng thay thế.**

- **1a. Lượt gọi kiểm tra tổng hợp** (`x-dh-synthetic: true`, UC-13-04). Bản ghi vẫn được ghi nhưng đánh `synthetic=true` để loại khỏi thống kê nghiệp vụ.
- **5a. Hồ sơ cloud dùng chung `HT-B`.** Chỉ số nút do nhà cung cấp quản lý lấy qua API của họ khi không scrape được.

**Luồng ngoại lệ.**

- **E1. ClickHouse không ghi được (bước 2).** Bản ghi nằm ở Kafka tối đa 3 ngày rồi ghi bù; ERR-13-118; người vận hành thấy ở UI-13-01: "Kho lượt gọi API không ghi được; bản ghi đang chờ ở Kafka."
- **E2. Kafka không nhận (bước 1).** APISIX đệm tối đa 10.000 bản ghi rồi bỏ và đếm `dh_obs_access_dropped_total`; không chặn lượt gọi (BR-13-015).
- **E3. `tenant_id` không khớp topic (bước 3).** Bản ghi bị bỏ và đếm; ERR-13-104: "Tenant của bản ghi không khớp topic."
- **E4. Nguồn hạ tầng không trả lời quá 3 chu kỳ (bước 5).** Chỉ số `up` về 0, luật `component-down` phát cảnh báo; bảng điều khiển hiện "Chưa có dữ liệu" cho thành phần đó, không hiện 0 (BR-13-016).
- **E5. Nguồn có quá nhiều chuỗi do nhãn pod (bước 5).** Hệ thống bỏ nhãn `pod` ở chỉ số tổng, giữ ở chỉ số tài nguyên; ERR-13-114.

**Quy tắc áp dụng.** BR-13-011, 015, 016, 026, 027.

**Màn hình, API.** UI-13-01 (dải trạng thái kho); không có API riêng (Kafka topic `{tenant}.obs.access.logged.v1`); tra cứu ở UC-13-19, thống kê ở UC-13-21, 22.
:::

### 6.4. UC-13-04 · Cấu hình và chạy kiểm tra tổng hợp

::: dac-ta
**Mục tiêu.** Phát hiện sự cố của API quan trọng trước khi HTTT hay người dân phản ánh, bằng lời gọi giả lập mỗi phút đi qua đúng đường của HTTT thật; nền của mục tiêu phát hiện sự cố nghiêm trọng ≤ 5 phút (KPI-15).

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang).

**Tác nhân phụ.** Bộ kiểm tra tổng hợp, APISIX, PH-02 (đánh dấu API quan trọng), PH-12 (client `dh-probe-T68`), Alertmanager.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-008.

**Truy vết.** REQ-13; quy trình BP-07; KPI-15.

**Tiền điều kiện.** Giang có `PERM-13-admin`; client `dh-probe-T68` (OAuth client credentials, scope chỉ-đọc) đã có; API `cong-dan.tra-cuu` được đánh dấu "quan trọng" ở PH-02; tenant không tạm ngừng.

**Kích hoạt.** Giang mở tab "Kiểm tra tổng hợp" ở UI-13-17 và bấm "+ Thêm kiểm tra".

**Đảm bảo tối thiểu.** Lời gọi kiểm tra không tạo dữ liệu nghiệp vụ thật và không bị tính vào thống kê nghiệp vụ.

**Đảm bảo thành công.** Định nghĩa `kt-tra-cuu-cong-dan` chạy mỗi 60 giây; khi API lỗi 3 lần liên tiếp, cảnh báo Nghiêm trọng tới người trực.

**Luồng chính.**

1. Giang chọn API `cong-dan.tra-cuu`, nhập `probeCode` `kt-tra-cuu-cong-dan`, chu kỳ 60 giây, mã HTTP mong đợi `200`, thời gian chờ 5 giây và tham số mẫu cố định (dữ liệu kiểm thử). UI gọi API-13-071 với `probes[]` và `If-Match`.
2. Hệ thống kiểm tra API tồn tại và chu kỳ trong miền 30…300 giây (ERR-13-003), lưu định nghĩa và ghi kiểm toán `PROBE.UPDATE`.
3. Mỗi 60 giây bộ kiểm tra xin token bằng `dh-probe-T68` rồi gọi API qua APISIX bên ngoài, kèm tiêu đề `x-dh-synthetic: true`.
4. Bộ kiểm tra so mã HTTP và độ trễ với mong đợi, ghi `dh_probe_success` (0 hoặc 1) và `dh_probe_duration_seconds`; UI-13-01 hiện nhãn "Tốt" cho kiểm tra này.
5. Lúc 14:03 API ngừng trả lời; thất bại lần 1, 2, 3 lúc 14:03, 14:04, 14:05. Luật chuẩn `probe-failed` (Nghiêm trọng) thỏa, sinh cảnh báo (UC-13-28) và phát EVT-13-13; UI-13-01 hiện ERR-13-124.
6. Lúc 14:09 API trả lời lại; lần thành công đầu tiên làm cảnh báo tự đóng.

**Luồng thay thế.**

- **1a. Chỉ xem danh sách kiểm tra.** Giang mở tab và UI gọi API-13-070; không thay đổi gì.
- **3a. Tenant bị tạm ngừng.** Bộ kiểm tra tạm dừng cho tới khi tenant hoạt động lại.

**Luồng ngoại lệ.**

- **E1. API đích không tồn tại hoặc chu kỳ ngoài miền (bước 2).** ERR-13-003 (400): "Dữ liệu gửi lên không hợp lệ." kèm câu theo `errors[]`.
- **E2. Không xin được token (bước 3).** Hệ thống coi là một lần thất bại của kiểm tra và đồng thời báo PH-12; người trực thấy cảnh báo như bước 5.
- **E3. Kiểm tra thất bại liên tiếp (bước 5).** ERR-13-124 hiển thị ở UI-13-01 và trong cảnh báo: "Kiểm tra tổng hợp kt-tra-cuu-cong-dan thất bại 3 lần liên tiếp."
- **E4. Sai phiên bản cấu hình (bước 1).** ERR-13-007 (412): "Dữ liệu đã được người khác sửa. Tải lại để xem phiên bản mới nhất."
- **E5. Tenant đang tạm ngừng (bước 1).** ERR-13-016 (423): "Tenant đang tạm ngừng; chỉ xem được, chưa thay đổi được cấu hình."
- **E6. Giang thiếu quyền (bước 1).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-006, 009, 015.

**Màn hình, API.** UI-13-01 (trạng thái kiểm tra), UI-13-17 (cấu hình); API-13-070, 071.
:::

### 6.5. UC-13-05 · Tiếp nhận và ghi bản ghi vào chuỗi băm theo tenant

::: dac-ta
**Mục tiêu.** Mọi bản ghi kiểm toán do DU phát đều vào đúng chuỗi băm của tenant, theo thứ tự, không trùng, không khoảng trống, không chứa giá trị Nhạy cảm chưa che; bản ghi không đạt được giữ ở kho cách ly chứ không bị bỏ.

**Tác nhân chính.** `dh-audit` của DU nguồn (ví dụ `dh-data`), qua hộp thư đi và Kafka.

**Tác nhân phụ.** Kafka, Apicurio (lược đồ `audit-event.v1`), bộ tiếp nhận kiểm toán của `dh-platform`, PostgreSQL `pg-core` (bảng `ph13_audit`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-010, 011.

**Truy vết.** REQ-13; mọi quy trình (ghi dấu vết); LGC-APIM-027.

**Tiền điều kiện.** Chuỗi của `T68` ở trạng thái `OPEN` (UC-13-40); topic `t68.obs.audit.recorded.v1` đã tạo; DU nguồn có KafkaUser được ghi topic của tenant; trigger chặn `UPDATE`, `DELETE`, `TRUNCATE` trên bảng chuỗi đang bật.

**Kích hoạt.** Bộ chuyển outbox của DU phát một bản ghi lên Kafka, hoặc DU gọi API dự phòng API-13-089.

**Đảm bảo tối thiểu.** Mọi bản ghi gửi tới được lưu ở bảng chuỗi hoặc ở `audit_quarantine`, không bản ghi nào biến mất; offset Kafka chỉ được xác nhận sau khi giao dịch ghi đã cam kết (BR-13-004).

**Đảm bảo thành công.** Bản ghi nằm trong `audit_event` của `T68` với `seq`, `prev_hash`, `hash`; `head_seq` và `head_hash` của chuỗi bằng bản ghi mới nhất.

**Luồng chính.**

1. Một cán bộ phát hành danh mục `DM_GIOI_TINH` ở PH-07; `dh-data` ghi bản ghi `CATALOG.PUBLISH` vào hộp thư đi trong cùng giao dịch nghiệp vụ, rồi bộ chuyển outbox phát lên topic `t68.obs.audit.recorded.v1` với khóa phân vùng `T68`.
2. Bộ tiếp nhận (một consumer cho mỗi phân vùng) nhận lô tối đa 500 bản ghi.
3. Hệ thống xác định `source_du` là `dh-data` từ chứng thư KafkaUser và kiểm tra DU này được phép ghi cho `T68`.
4. Hệ thống kiểm tra lược đồ và đủ trường bắt buộc, `tenant_id` khớp tiền tố topic, và `id` chưa có trong chuỗi.
5. Hệ thống quét `before`, `after`, `reason` bằng bộ mẫu Nhạy cảm; không thấy giá trị chưa che.
6. Hệ thống lấy khóa tư vấn mức giao dịch theo tenant, đọc `head_seq` = 41.877 và `head_hash`; gán `seq` = 41.878 và `recorded_at` là giờ máy chủ; dựng JSON chuẩn tắc (RFC 8785) của bản ghi không có `hash`; tính `hash = SHA-256(prev_hash ‖ canonical_json)`.
7. Hệ thống `INSERT` lô vào phân vùng tháng 11/2026 và cập nhật `head_seq`, `head_hash` trong cùng giao dịch; ràng buộc `UNIQUE (tenant_id, seq)` bảo đảm không trùng, không khoảng trống.
8. Sau khi cam kết, bộ tiếp nhận xác nhận offset Kafka; bộ chuyển outbox của DU đánh dấu bản ghi đã gửi.

**Luồng thay thế.**

- **1a. DU không với tới Kafka.** DU gọi `POST /internal/records:batch` bằng scope `audit:write` (API-13-089); luồng kiểm tra giống nhau; phản hồi `202` kèm số bản ghi nhận, số trùng, số cách ly.
- **6a. Hai bản sao `dh-platform` cùng nhận cho một tenant.** Bản sao đến sau chờ khóa; quá 5 giây thì trả lô về hàng đợi để thử lại, không bỏ qua.
- **6b. Bản ghi liên tenant.** Hệ thống ghi vào chuỗi của tenant bị truy cập và một bản vào chuỗi của tenant nhà (UC-13-16). Tenant `PLATFORM` dùng chuỗi riêng.

**Luồng ngoại lệ.**

- **E1. Thiếu trường bắt buộc (bước 4).** Bản ghi vào `audit_quarantine`; ERR-13-101; người vận hành thấy ở UI-13-18: "Bản ghi kiểm toán thiếu trường bắt buộc: {trường}." và nhóm phát triển DU nhận cảnh báo mức Cảnh báo.
- **E2. DU không được phép ghi cho tenant (bước 3).** Bản ghi cách ly; ERR-13-103: "DU {du} không được phép ghi kiểm toán cho tenant {tenant}." kèm cảnh báo an ninh UC-SEC-09.
- **E3. `tenant_id` không khớp topic (bước 4).** Bản ghi cách ly; ERR-13-104: "Tenant của bản ghi không khớp topic."
- **E4. `id` đã có trong chuỗi (bước 4).** Hệ thống bỏ qua và coi là đã nhận (lũy đẳng); ERR-13-102: "Bản ghi kiểm toán trùng mã {id}, đã bỏ qua."
- **E5. Giá trị Nhạy cảm chưa che (bước 5).** Bản ghi cách ly, không vào chuỗi; ERR-13-105: "Bản ghi kiểm toán chứa giá trị Nhạy cảm chưa che; đã cách ly." và cảnh báo Nghiêm trọng cho nhóm phát triển DU.
- **E6. Không ghi được vào PostgreSQL (bước 7).** Giao dịch hủy, không xác nhận offset, thử lại giãn dần từ 1 giây tới 1 phút; ERR-13-106; UI-13-18: "Không ghi được bản ghi vào bảng kiểm toán; sẽ thử lại." Quá 5 phút thì cảnh báo Nghiêm trọng.
- **E7. Chuỗi của tenant đã đóng (bước 4).** ERR-13-043 (409): "Chuỗi kiểm toán của tenant đã đóng, không nhận thêm bản ghi."
- **E8. Có lệnh `UPDATE`, `DELETE`, `TRUNCATE` vào bảng.** Trigger từ chối với mọi vai trò trừ `ph13_archive` (UC-13-10); lần thử ghi vào `pgaudit` và phát UC-SEC-20 mức Cao.
- **E9. Đồng hồ DU lệch quá 2 giây về tương lai (bước 6).** Bản ghi vẫn được ghi, gắn cờ `clock_skew`; ERR-13-126: "Đồng hồ lệch: bản ghi từ {du} có thời điểm sau giờ máy chủ quá 2 giây."

**Quy tắc áp dụng.** BR-13-001, 002, 004, 017, 019, 035.

**Màn hình, API.** UI-13-18 (đầu chuỗi, độ trễ ghi, kho cách ly); API-13-087, 089.
:::

### 6.6. UC-13-06 · Neo băm ký hằng giờ và sao lô sang WORM

::: dac-ta
**Mục tiêu.** Bản ghi nào cũng có một bản không sửa, không xóa được ở kho WORM trong vòng 10 phút, và mỗi giờ đầu chuỗi được chốt thành một neo có chữ ký, lưu ở nhiều nơi độc lập, để kẻ muốn sửa nhật ký phải giả chữ ký, sửa cả bản WORM lẫn SIEM.

**Tác nhân chính.** Bộ sao WORM và bộ neo của `dh-platform` (hệ thống).

**Tác nhân phụ.** OpenBao (khóa ký `dh-audit-sign`, ECDSA P-256, không xuất được), kho WORM Ceph RGW (bucket `dh-worm-audit`), SIEM của tỉnh (nếu cấu hình), `pg-core`.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-012, 013.

**Truy vết.** REQ-13; mọi quy trình (ghi dấu vết); LGC-APIM-027; LGC-NFR-005.

**Tiền điều kiện.** Bucket WORM có Object Lock chế độ tuân thủ, tiền tố `T68/`; tài khoản ghi chỉ có `PutObject`, không có `Delete`; khóa ký có ở OpenBao.

**Kích hoạt.** Mỗi 5 phút (`13.audit.worm-batch-minutes`) cho việc sao lô; đầu mỗi giờ (`13.audit.anchor-interval-minutes` = 60) cho việc neo.

**Đảm bảo tối thiểu.** WORM hoặc OpenBao ngừng thì bản ghi và neo vẫn nằm ở bảng chỉ-thêm và được thử lại, không mất; lỗi không chặn việc ghi chuỗi.

**Đảm bảo thành công.** Mỗi lô có `worm_verified_at`; neo giờ hiện tại có chữ ký và nằm ở bảng `audit_anchor`, WORM và SIEM (nếu cấu hình).

**Luồng chính.**

1. Bộ sao gom bản ghi `T68` chưa sao thành lô theo dải `seq` liên tục, tối đa 50.000 bản ghi, và ghi tệp `audit/T68/2026/11/26/41001-41878.jsonl.zst` kèm tệp `manifest` gồm `count`, `sha256`, `prev_batch_sha256`.
2. Bộ sao gọi `PutObject` với `ObjectLockMode=COMPLIANCE` và `RetainUntilDate` bằng hôm nay cộng 5 năm (`13.audit.worm-retention-years`), mã hóa phía máy chủ.
3. Bộ sao đọc lại `ETag`, so với băm đã tính; khớp thì ghi `worm_verified_at` cho lô và cập nhật `dh_audit_worm_lag_seconds`.
4. Lúc 14:00 bộ neo chốt `{tenant, seq cuối, hash cuối, anchored_at, key_version}` trong giao dịch chỉ-đọc.
5. Bộ neo gửi băm của payload tới OpenBao `transit/sign/dh-audit-sign`, nhận chữ ký, rồi ghi neo vào `audit_anchor` (chỉ-thêm).
6. Bộ neo ghi tệp `anchors/T68/2026/11/26/14.json` vào bucket WORM với thời hạn giữ như bản ghi; nếu `T68` cấu hình SIEM (UC-13-36) thì gửi neo sang SIEM và ghi `siem_ack_at`.
7. Bộ neo kiểm tra gia tăng: tính lại băm đoạn từ neo trước tới neo này; khớp thì phát EVT-13-06 (`anchor-created`); lệch thì chuyển UC-13-08.

**Luồng thay thế.**

- **2a. Tenant đặt thời hạn WORM dài hơn 5 năm** (tối đa 10, UC-13-42). Áp dụng cho lô mới; lô còn hạn gia hạn bằng lệnh kéo dài thời hạn, vì Object Lock chỉ cho kéo dài (BR-13-020).
- **4a. Không có bản ghi mới từ neo trước.** Bộ neo bỏ neo giờ đó; nhưng mỗi tenant có ít nhất một neo trong 24 giờ.
- **5a. Xoay khóa ký 12 tháng.** Neo mới mang `key_version` mới; khóa công khai các phiên bản cũ được giữ để xác minh neo cũ.

**Luồng ngoại lệ.**

- **E1. OpenBao không ký được (bước 5).** Thử lại sau 1 phút; ERR-13-107; UI-13-18: "Không ký được neo tại OpenBao; neo sẽ làm lại." Quá 3 giờ không có neo thì cảnh báo Nghiêm trọng.
- **E2. WORM không nhận (bước 2, 6).** Hệ thống giữ lô, thử lại giãn dần, neo vẫn lưu ở bảng và đánh `worm_pending`; ERR-13-108; UI-13-18: "Chưa sao được lô bản ghi sang kho WORM; sẽ thử lại." Trễ quá 30 phút cảnh báo mức Cảnh báo, quá 4 giờ mức Nghiêm trọng.
- **E3. `ETag` không khớp sau khi ghi (bước 3).** Hệ thống ghi lại lô dưới tên mới và báo ERR-13-108 kèm nghi vấn hỏng đường truyền.
- **E4. SIEM không nhận (bước 6).** ERR-13-122 hiển thị ở UI-13-17: "SIEM siem-tinh không nhận được dữ liệu."; không chặn neo.
- **E5. Kho WORM đạt 85% dung lượng.** Phát EVT-13-14 và cảnh báo ERR-13-123: "Kho dh-worm-audit đạt 85% dung lượng."

**Quy tắc áp dụng.** BR-13-002, 013, 017, 020.

**Màn hình, API.** UI-13-14 (danh sách neo), UI-13-18 (độ trễ sao WORM, trạng thái neo); API-13-080, 081, 087.
:::

### 6.7. UC-13-07 · Kiểm tra toàn vẹn chuỗi kiểm toán

::: dac-ta
**Mục tiêu.** Chứng minh chuỗi kiểm toán của một tenant chưa bị sửa (băm đúng, `seq` liên tục, chữ ký neo hợp lệ, bản ghi khớp bản WORM), tự động hằng ngày và theo yêu cầu của kiểm toán viên; kẻ sửa trực tiếp cơ sở dữ liệu bị phát hiện trong tối đa 24 giờ, và trong 1 giờ nếu chạm đoạn đã neo (NFR-13-016).

**Tác nhân chính.** ROLE-AUDITOR (Khoa), ROLE-SECURITY_OFFICER (Dũng); lịch tự động 03:00 hằng ngày.

**Tác nhân phụ.** Bộ kiểm tra toàn vẹn, bản sao chỉ-đọc của `pg-core`, OpenBao (khóa công khai theo `key_version`), kho WORM.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-014.

**Truy vết.** REQ-13; quy trình BP-07; LGC-APIM-027; THR-34.

**Tiền điều kiện.** Khoa có `PERM-13-audit-export`; chuỗi `T68` có ít nhất một neo hoặc ở đoạn đầu; không có lượt kiểm tra khác của `T68` đang chạy.

**Kích hoạt.** Lịch `13.audit.verify-cron` (`0 3 * * *`); Khoa bấm "Kiểm tra toàn vẹn" ở UI-13-14; neo không khớp ở UC-13-06 bước 7.

**Đảm bảo tối thiểu.** Bộ kiểm tra chỉ đọc, không có đường nào ghi vào chuỗi (BR-13-033); kiểm tra không làm chậm việc ghi (đọc từ bản sao).

**Đảm bảo thành công.** Lượt kiểm tra có kết quả `PASSED` hoặc `FAILED` kèm vị trí đứt đầu tiên; kết quả lưu 5 năm; bản ghi `AUDIT.VERIFY` nằm trong chuỗi.

**Luồng chính.**

1. Khoa mở UI-13-14, bấm "Kiểm tra toàn vẹn", chọn phạm vi `ON_DEMAND` từ 01/11/2026 đến 25/11/2026, mức so WORM `SAMPLE` (1% bản ghi) và nhập lý do "Chuẩn bị thanh tra quý IV". UI gọi API-13-077, nhận `202` kèm `verificationId`.
2. Hệ thống ghi bản ghi kiểm toán `AUDIT.VERIFY` kèm phạm vi và người yêu cầu, tạo lượt `RUNNING`, chọn điểm xuất phát là neo đã xác minh gần nhất và điểm cuối là `head_seq`.
3. Bộ kiểm tra đọc chuỗi theo `seq` từ bản sao chỉ-đọc, tính lại `hash` từng bản ghi và so với `hash` lưu và `prev_hash` của bản ghi kế.
4. Bộ kiểm tra kiểm `seq` liên tục, không khoảng trống, và xác minh chữ ký từng neo trong đoạn bằng khóa công khai theo `key_version`.
5. Bộ kiểm tra đối chiếu băm lô WORM với bản ghi ở bảng (mẫu 1%).
6. Hệ thống ghi kết quả `PASSED`, `checkedCount`, `anchorsChecked`, thời gian chạy và phát EVT-13-07; UI-13-14 hiện "Đạt" kèm số bản ghi và số neo đã kiểm (API-13-079).

**Luồng thay thế.**

- **1a. Lượt tự động 03:00.** Phạm vi `DAILY`, chủ thể `system:dh-platform`, không cần lý do; mọi bước sau giống nhau.
- **1b. Kiểm toán viên cấp nền tảng kiểm tra tenant khác.** Phải qua phiên liên tenant có lý do (LP-13-03).
- **5a. Mức `FULL`.** Đối chiếu toàn bộ bản ghi với WORM thay vì mẫu.
- **5b. Kho WORM không đọc được.** Kết quả chuỗi và neo vẫn có, đánh `wormCheck = UNAVAILABLE` và hiện "Chưa đối chiếu được với kho WORM." chứ không báo đạt hoàn toàn.

**Luồng ngoại lệ.**

- **E1. Đang có lượt kiểm tra của tenant (bước 1).** ERR-13-032 (409): "Đang có lượt kiểm tra toàn vẹn của tenant này chạy."
- **E2. Thiếu lý do ở `ON_DEMAND` (bước 1).** ERR-13-012 (422): "Cần nhập lý do truy vấn nhật ký kiểm toán (10 đến 500 ký tự)."
- **E3. Thiếu quyền (bước 1).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E4. Khoảng nằm ngoài 12 tháng trực tuyến mà không có bản WORM (bước 1).** ERR-13-029 (422): "Khoảng thời gian này đã quá thời hạn lưu trực tuyến (12 tháng). Dùng xuất bằng chứng để lấy từ kho lưu trữ."
- **E5. Kết quả `FAILED` (bước 6).** Hệ thống chuyển sang UC-13-08; UI-13-14 hiện vị trí đứt đầu tiên thay vì "Đạt".
- **E6. Không ghi được `AUDIT.VERIFY` (bước 2).** Lượt kiểm tra theo yêu cầu bị từ chối (ghi vết trước khi chạy, BR-13-006); ERR-13-014 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-13-006, 033.

**Màn hình, API.** UI-13-14; API-13-077, 078, 079.
:::

### 6.8. UC-13-08 · Xử lý đứt chuỗi hoặc neo không khớp

::: dac-ta
**Mục tiêu.** Khi có dấu hiệu nhật ký bị can thiệp, báo đúng người ở mức cao nhất trong vài phút, khoanh vùng khoảng bị ảnh hưởng, giữ chứng cứ bất biến và mở quy trình ứng cứu, nhưng không bao giờ tự sửa chuỗi. Đây là kịch bản nghiêm trọng nhất của phân hệ.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Bộ kiểm tra toàn vẹn và bộ neo (kích hoạt), ROLE-TENANT_ADMIN (Giang), ROLE-PLATFORM_ADMIN (Hà, cấp leo thang), SIEM, PH-18 (hồ sơ sự cố), bucket chứng cứ WORM có Object Lock.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-015.

**Truy vết.** REQ-13; quy trình BP-07, ứng cứu sự cố (D03-07 §8); LGC-APIM-027; UC-SEC-20.

**Tiền điều kiện.** UC-13-07 trả `FAILED`, hoặc UC-13-06 bước 7 phát hiện neo lệch, hoặc `pgaudit` ghi nhận lệnh sửa bảng kiểm toán; Dũng có `PERM-13-security`.

**Kích hoạt.** Một trong ba điều kiện trên (hệ thống tự kích hoạt, không chờ người).

**Đảm bảo tối thiểu.** Hệ thống không tự sửa, nối lại hay dựng lại chuỗi (BR-13-033); vẫn nhận bản ghi mới để không mất bằng chứng; sự kiện đứt chuỗi ghi vào chuỗi `PLATFORM`, không ghi vào chuỗi nghi vấn.

**Đảm bảo thành công.** Chuỗi ở `SUSPECT`; chứng cứ bất biến đã thu; hồ sơ sự cố đã mở; Dũng và Giang đã được báo; chuỗi trở về `OK` chỉ khi có kết luận xử lý và một lượt kiểm tra mới đạt trên đoạn sau điểm đứt.

**Luồng chính.**

1. Lúc 03:07 ngày 26/11/2026, lượt kiểm tra hằng ngày của `T68` trả `FAILED` với `first_break_seq` = 38.204 và loại lỗi `HASH_MISMATCH`.
2. Hệ thống xác định khoảng ảnh hưởng từ seq 38.204 tới đầu chuỗi và loại lỗi.
3. Hệ thống phát ngay cảnh báo an ninh UC-SEC-20 mức Nghiêm trọng tới Dũng và Giang (thêm Hà nếu là chuỗi `PLATFORM`), đẩy sang SIEM và phát EVT-13-05; nội dung ghi ERR-13-109: "Phát hiện đứt chuỗi kiểm toán tại seq 38204 của tenant T68."
4. Hệ thống đặt `chain_status = SUSPECT`; UI-13-13 hiện dải đỏ "Chuỗi kiểm toán có dấu hiệu bị can thiệp từ seq 38204" và đánh dấu mọi bản ghi trong khoảng.
5. Hệ thống tự thu chứng cứ: sao khoảng bản ghi nghi vấn từ bảng và từ WORM, cùng kết quả kiểm tra, vào bucket chứng cứ có Object Lock.
6. Hệ thống mở hồ sơ sự cố theo quy trình ứng cứu và PH-18 kèm đường dẫn tới kết quả kiểm tra, và ghi `AUDIT.CHAIN.BREAK_DETECTED` vào chuỗi `PLATFORM`.
7. Dũng nhận thông báo, bấm "Tiếp nhận" trong 15 phút (quá hạn thì leo thang lên Giang ở 15 phút và Hà ở 30 phút theo UC-13-28), rồi mở UI-13-14 và UI-13-18 xem báo cáo toàn vẹn: `firstBreakSeq`, khoảng ảnh hưởng, loại lỗi, các hành động hệ thống đã tự thực hiện.
8. Dũng điều tra qua UC-13-12 (lọc khoảng nghi vấn) và nhật ký `pgaudit`, rồi đóng cảnh báo ở UC-13-35 với kết luận `CONFIRMED_INCIDENT`; sau một lượt kiểm tra mới đạt trên đoạn sau điểm đứt, chuỗi trở về `OK`.

**Luồng thay thế.**

- **3a. Lỗi `WORM_MISMATCH` (bảng đúng, bản WORM lệch).** Hệ thống coi là sự cố ở kho WORM, vẫn mức Nghiêm trọng, và cách ly kho WORM khỏi ghi tới khi điều tra xong.
- **8a. Đứt chuỗi do sự cố hạ tầng đã biết** (khôi phục từ sao lưu có biên bản). Dũng đóng cảnh báo với kết luận `ACCEPTED_RISK` kèm biên bản đính kèm (xem Q13-46).

**Luồng ngoại lệ.**

- **E1. Không thu được chứng cứ vì WORM lỗi (bước 5).** ERR-13-108; Dũng nhận: "Chưa sao được lô bản ghi sang kho WORM; sẽ thử lại." và hồ sơ được đánh dấu thiếu bản WORM.
- **E2. Không gửi được qua kênh chính (bước 3).** Hệ thống dùng kênh dự phòng độc lập; ERR-13-120 hiển thị cho PA, TA ở UI-13-12: "Gửi thông báo qua kênh {kênh} thất bại: {lý do}."
- **E3. Neo không khớp bản WORM hoặc SIEM (bước 3).** ERR-13-110 nêu trong cảnh báo: "Neo {anchorId} không khớp với bản WORM hoặc SIEM."
- **E4. Leo thang hết cấp mà chưa ai xác nhận (bước 7).** ERR-13-121 gửi PA, TA qua kênh độc lập: "Cảnh báo {id} đã leo thang hết cấp mà chưa ai xác nhận."
- **E5. Người xử lý thiếu `PERM-13-security` (bước 7).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-012, 013, 022, 033.

**Màn hình, API.** UI-13-14, UI-13-18; API-13-079.
:::

### 6.9. UC-13-09 · Chịu lỗi, đệm và đối chiếu số lượng bản ghi

::: dac-ta
**Mục tiêu.** Không mất bản ghi kiểm toán và không chặn người dùng khi PH-13, Kafka, PostgreSQL, OpenBao hoặc kho WORM tạm ngừng; và chứng minh hằng ngày rằng 100% thao tác phải ghi vết đều có bản ghi (chênh lệch phát và nhận bằng 0).

**Tác nhân chính.** `dh-audit` của DU nguồn (ví dụ `dh-integration`, `dh-runtime`).

**Tác nhân phụ.** Kafka, PostgreSQL `pg-core`, kho WORM, Mimir (bộ đếm `dh_audit_emitted_total`), ROLE-PLATFORM_OPERATOR (Lan), ROLE-SECURITY_OFFICER (Dũng), ROLE-AUDITOR (Khoa).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-016, 017.

**Truy vết.** REQ-13; quy trình BP-07; LGC-APIM-027; KPI-07.

**Tiền điều kiện.** DU dùng `dh-audit` với hộp thư đi trong cơ sở dữ liệu của DU; topic kiểm toán giữ 7 ngày; mỗi DU xuất bộ đếm `dh_audit_emitted_total{du,tenant}` tăng khi ghi bản ghi vào hộp thư đi.

**Kích hoạt.** Một khâu của đường kiểm toán không nhận được bản ghi (chịu lỗi); 01:00 hằng ngày cho ngày hôm trước (đối chiếu), hoặc theo yêu cầu.

**Đảm bảo tối thiểu.** Bản ghi chỉ rời khâu trước khi khâu sau xác nhận (BR-13-004); thao tác nghiệp vụ của người dùng không bị chặn vì PH-13 ngừng (BR-13-015). Ngoại lệ duy nhất: thao tác dữ liệu Nhạy cảm mà không bảo đảm ghi vết ở nguồn thì bên gọi từ chối phục vụ (BR-13-003).

**Đảm bảo thành công.** 0 bản ghi mất sau hồi phục; `audit_reconciliation` của ngày 26/11/2026 có trạng thái `MATCH` cho mọi cặp (DU, tenant).

**Luồng chính.**

1. Lúc 09:10 bộ tiếp nhận kiểm toán của `dh-platform` ngừng để nâng cấp. Kafka giữ bản ghi (tối đa 7 ngày); người dùng `T68` vẫn thao tác bình thường và không thấy gián đoạn.
2. Hệ thống đo `dh_audit_outbox_pending`, độ trễ consumer và độ trễ sao WORM; Lan thấy backlog tăng ở UI-13-18. Vượt 1.000 bản ghi hoặc 5 phút thì luật chuẩn `audit-outbox-backlog` phát cảnh báo mức Cảnh báo, vượt 30 phút thì mức Nghiêm trọng.
3. Lúc 11:10 bộ tiếp nhận chạy lại; consumer đọc tiếp từ offset đã xác nhận, xử lý backlog tuần tự, không bỏ qua bản ghi nào (UC-13-05).
4. Lúc 01:00 ngày 27/11/2026, hệ thống lấy `emitted` của ngày 26/11 từ chỉ số của từng DU theo tenant; ví dụ `dh-integration` của `T68` phát 12.480 bản ghi.
5. Hệ thống đếm `received` ở `audit_event` (cùng `source_du`) và `audit_quarantine` cho ngày đó, được 12.480; `diff = emitted − received = 0` nên ghi `MATCH`.
6. Hệ thống lưu kết quả vào `audit_reconciliation`; Dũng và Khoa xem ở UI-13-18 (API-13-086) hàng "26/11 · dh-integration · phát 12.480 · nhận 12.480 · MATCH".

**Luồng thay thế.**

- **1a. `dh-runtime` (không có cơ sở dữ liệu riêng, Q13-03).** DU ghi trực tiếp lên Kafka với `acks=all`; không với tới Kafka thì thao tác truy cập dữ liệu Nhạy cảm bị từ chối, thao tác thường ghi đệm đĩa cục bộ tối đa 1 GB rồi thử lại.
- **1b. DU không với tới Kafka.** DU gọi kênh dự phòng API-13-089 (UC-13-05 bước 1a).
- **5a. DU ngừng cả ngày vì bảo trì.** `emitted` bằng 0 và `received` bằng 0, ghi `MATCH`; bản ghi cách ly được tính là đã nhận nhưng hiển thị riêng.
- **5b. `diff < 0` (nhận nhiều hơn phát).** Hệ thống ghi `SURPLUS` và cảnh báo vì có thể bộ đếm của DU sai.

**Luồng ngoại lệ.**

- **E1. Bản ghi đệm không gửi được quá 4 giờ (bước 2).** Cảnh báo Nghiêm trọng tới người trực; không ai xác nhận thì leo thang hết cấp, ERR-13-121: "Cảnh báo {id} đã leo thang hết cấp mà chưa ai xác nhận."
- **E2. Không ghi được vào PostgreSQL (bước 3).** ERR-13-106; Lan thấy: "Không ghi được bản ghi vào bảng kiểm toán; sẽ thử lại."
- **E3. Hộp thư đi của một DU vượt 1 triệu bản ghi.** Cảnh báo Nghiêm trọng cho nhóm phát triển DU đó, đo bằng `dh_audit_outbox_pending`.
- **E4. Chênh lệch còn sau 2 giờ chờ (bước 5).** Hệ thống đếm lại; còn lệch thì ghi `MISMATCH`, phát EVT-13-09 và cảnh báo Nghiêm trọng cho DU nguồn; ERR-13-111 hiển thị ở UI-13-18 và gửi Dũng: "Số bản ghi kiểm toán của dh-integration lệch: phát 12480, nhận 12479."
- **E5. Mimir không đọc được bộ đếm (bước 4).** Thử lại sau 1 giờ; quá 24 giờ thì cảnh báo mức Cảnh báo; ERR-13-014: "Dịch vụ Mimir tạm thời không khả dụng. Thử lại sau."
- **E6. DU không xuất bộ đếm (bước 4).** Hệ thống ghi `NO_COUNTER` và cảnh báo mức Cảnh báo cho nhóm phát triển DU.

**Quy tắc áp dụng.** BR-13-001, 003, 004, 006, 015.

**Màn hình, API.** UI-13-18 (backlog hộp thư đi, độ trễ Kafka và WORM, bảng đối chiếu); API-13-086, 087, 089. Ai được xem bảng đối chiếu chi tiết: xem Q13-45.
:::

### 6.10. UC-13-10 · Lưu giữ và lưu trữ phân vùng kiểm toán

::: dac-ta
**Mục tiêu.** Giữ bản ghi kiểm toán trực tuyến 12 tháng để tra nhanh và trên WORM tối thiểu 5 năm để thanh tra, bằng cách quản lý phân vùng theo tháng và chỉ lưu trữ phân vùng khi bản WORM đã được xác minh đủ; thay việc sao lưu log mỗi tháng một lần của hệ cũ.

**Tác nhân chính.** Bộ quản lý phân vùng của `dh-platform`, dùng vai trò cơ sở dữ liệu `ph13_archive` (hệ thống).

**Tác nhân phụ.** OpenBao (cấp tài khoản động), kho WORM Ceph RGW, ROLE-PLATFORM_ADMIN (Hà) và ROLE-TENANT_ADMIN (Giang) xem tình trạng.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-018.

**Truy vết.** REQ-13; mọi quy trình (ghi dấu vết); LGC-APIM-027; LGC-NFR-005.

**Tiền điều kiện.** Bảng `audit_event` phân vùng theo tháng của `recorded_at`; vai trò `ph13_archive` do OpenBao cấp động chỉ được tách và xóa phân vùng; tham số `13.audit.online-months` = 12 và `13.audit.worm-retention-years` = 5.

**Kích hoạt.** 03:00 ngày 1 mỗi tháng (tạo phân vùng, niêm phong); hằng ngày cho phần kiểm tra điều kiện lưu trữ.

**Đảm bảo tối thiểu.** Không phân vùng nào bị tách khi chưa có bản WORM đã xác minh (BR-13-002); mọi lần tách và xóa đều có biên bản.

**Đảm bảo thành công.** Mọi phân vùng `ARCHIVED` có bản WORM đã xác minh; bản ghi trong 12 tháng tra ngay, bản cũ hơn xuất được thành bằng chứng.

**Luồng chính.**

1. Lúc 03:00 ngày 01/12/2026 hệ thống tạo trước phân vùng cho 3 tháng tới (01, 02, 03/2027).
2. Hệ thống đổi phân vùng tháng 11/2026 sang `SEALED` vì mọi lô WORM của tháng đã sao và đối chiếu số lượng (UC-13-09) đã `MATCH` mọi ngày.
3. Hệ thống xét các phân vùng `SEALED` quá 12 tháng, ví dụ phân vùng 11/2025: kiểm tra mọi lô của phân vùng có trên WORM, băm khớp và thời hạn giữ còn đủ.
4. Đạt thì OpenBao cấp tài khoản `ph13_archive`; hệ thống tách phân vùng, đổi sang `ARCHIVED`, ghi biên bản `AUDIT.PARTITION.ARCHIVE` (chủ thể `system:dh-platform`) và phát EVT-13-11; từ đó bản ghi của tháng đó chỉ còn trên WORM.
5. Hà mở UI-13-18 và thấy bảng phân vùng: tháng, trạng thái, `recordCount`, `wormVerifiedAt`, `archivedAt` (API-13-088).
6. Khi Object Lock của một lô hết hạn (5 năm sau khi ghi, tức từ năm 2031 với lô đầu tiên của `T68`), kho WORM xóa lô theo vòng đời; hệ thống ghi biên bản xóa gồm tenant, dải `seq`, ngày xóa vào chuỗi `PLATFORM`.

**Luồng thay thế.**

- **3a. Tenant nâng thời hạn WORM** (UC-13-42). Áp dụng cho lô mới; lô còn hạn gia hạn được, chỉ kéo dài.
- **3b. Tenant đã sáp nhập** (UC-13-41). Bản ghi giữ theo thời hạn của chuỗi tenant nguồn.

**Luồng ngoại lệ.**

- **E1. Phân vùng chưa xác minh đủ ở WORM (bước 3).** Giữ nguyên `SEALED`, không tách; ERR-13-125; UI-13-18 hiện: "Phân vùng 2025-11 chưa lưu trữ được vì chưa xác minh đủ ở WORM." và phát cảnh báo mức Cảnh báo.
- **E2. Đặt thời hạn WORM dưới 3 năm.** Bị chặn ở UC-13-42 với ERR-13-040: "Tham số 13.audit.worm-retention-years ngoài miền cho phép; thời hạn lưu kiểm toán không được thấp hơn 3 năm."
- **E3. Có người hoặc tiến trình cố rút ngắn Object Lock.** Kho WORM từ chối; hệ thống ghi sự kiện an ninh.
- **E4. OpenBao không cấp được tài khoản `ph13_archive` (bước 4).** Hệ thống hoãn tới lần chạy kế tiếp; ERR-13-014 ghi vào nhật ký vận hành, phân vùng giữ `SEALED`.

**Quy tắc áp dụng.** BR-13-002, 020.

**Màn hình, API.** UI-13-18 (bảng phân vùng); API-13-088.
:::

### 6.11. UC-13-11 · Ghi vết thao tác của người dùng PH-13

::: dac-ta
**Mục tiêu.** Chính những người xem, xuất, cấu hình ở PH-13 cũng để lại dấu vết trong chuỗi kiểm toán, nên không ai lạm dụng quyền xem nhật ký hay sửa luật cảnh báo mà không bị phát hiện.

**Tác nhân chính.** `dh-platform` (module `observability` và `audit`, dùng thư viện `dh-audit`).

**Tác nhân phụ.** Người thao tác (ví dụ Khoa, Giang), hộp thư đi, Kafka, bộ tiếp nhận (UC-13-05).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-019.

**Truy vết.** REQ-13; mọi quy trình (ghi dấu vết); LGC-APIM-027; THR-19.

**Tiền điều kiện.** Module `observability` và `audit` của `dh-platform` dùng `dh-audit`; chuỗi của tenant ở trạng thái `OPEN`.

**Kích hoạt.** Một thao tác thuộc danh sách "Thao tác của PH-13 phải ghi kiểm toán" ở FRS §6.3 (tra cứu, xem chi tiết, kiểm tra toàn vẹn, xuất và tải bằng chứng, mở và đóng phiên liên tenant, quản lý luật, xử lý cảnh báo, tinh chỉnh ngưỡng, cấu hình lịch trực, kênh, SIEM, dashboard, tham số).

**Đảm bảo tối thiểu.** Thao tác chỉ-đọc nhạy cảm không ghi vết được thì bị từ chối trước khi trả kết quả (fail-closed); bản ghi không bao giờ chứa số định danh hay bí mật.

**Đảm bảo thành công.** Mỗi thao tác nhạy cảm ở PH-13 truy được tới người thực hiện, lý do, thời điểm, và nằm trong chuỗi của tenant (cả hai chuỗi nếu là truy cập liên tenant).

**Luồng chính.**

1. Khoa bấm "Tra cứu" ở UI-13-13 (UC-13-12). Trước khi chạy truy vấn, module sinh bản ghi `AUDIT.QUERY` gồm tóm tắt điều kiện lọc và lý do, và ghi vào hộp thư đi.
2. Chỉ khi bản ghi đã nằm trong hộp thư đi, hệ thống mới trả kết quả cho Khoa; với thao tác chỉ-đọc nhạy cảm (tra cứu kiểm toán, xuất bằng chứng) không ghi được thì từ chối.
3. Giang sửa luật `api-loi-cao-dvc` (UC-13-26): module sinh `ALERT.RULE.UPDATE` kèm giá trị trước và sau đã che, trong cùng giao dịch với thay đổi.
4. Khi Khoa tra theo đối tượng bị tra cứu (UC-13-14), bản ghi `AUDIT.QUERY` chỉ chứa `object_key_hmac` của người bị tra, không chứa số định danh.
5. Khi Hà mở phiên liên tenant vào `T68` (UC-13-16), bản ghi `AUDIT.CROSS_TENANT.OPEN` được ghi vào chuỗi của cả hai tenant.
6. Các bản ghi đi qua hộp thư đi, Kafka và bộ tiếp nhận như mọi DU (UC-13-05) và vào chuỗi của tenant.
7. Dũng tra `action = AUDIT.QUERY` ở UC-13-12 và thấy lượt tra của Khoa lúc 09:41 kèm lý do.

**Luồng thay thế.**

- **3a. Thao tác tự động** (neo, kiểm tra toàn vẹn hằng ngày, lưu trữ phân vùng). Chủ thể ghi là `system:dh-platform`.
- **3b. Thao tác chỉ do hệ thống ghi** (`AUDIT.CHAIN.BREAK_DETECTED`, `AUDIT.PARTITION.ARCHIVE`, `OBS.CROSS_TENANT_ATTEMPT`). Không đòi lý do vì không có người nhập.

**Luồng ngoại lệ.**

- **E1. Không ghi được hộp thư đi cho truy vấn kiểm toán (bước 2).** Hệ thống không trả kết quả; ERR-13-014 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."
- **E2. Thao tác bắt buộc lý do mà thiếu (bước 1, 3).** Thao tác bị từ chối trước khi chạy; ERR-13-008 (400): "Thao tác này cần nhập lý do từ 10 đến 500 ký tự." hoặc ERR-13-012 (422) với tra cứu kiểm toán.

**Quy tắc áp dụng.** BR-13-006, 007, 018.

**Màn hình, API.** Không có màn riêng; tra ở UI-13-13 (UC-13-12).
:::

### 6.12. UC-13-12 · Tra cứu nhật ký kiểm toán, xem chi tiết và xác minh băm

::: dac-ta
**Mục tiêu.** Kiểm toán viên và cán bộ ATTT tìm được bản ghi kiểm toán theo thời gian, chủ thể, đối tượng, hành động, kết quả để điều tra, biết ngay kết quả có đáng tin không nhờ chỉ báo toàn vẹn, và tự thấy một bản ghi còn nguyên vẹn nhờ băm, neo và chữ ký.

**Tác nhân chính.** ROLE-AUDITOR (Khoa), ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** `dh-audit` (ghi `AUDIT.QUERY`, `AUDIT.RECORD.VIEW`), bảng `ph13_audit`, OpenBao (khóa công khai theo `key_version`), PH-12 (MFA).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-020, 021.

**Truy vết.** REQ-13; quy trình BP-07, BP-09 (đối chiếu khi chạy song song); LGC-APIM-027.

**Tiền điều kiện.** Khoa có `PERM-13-audit-read`, đã đăng nhập, chọn tenant `T68` (FR-00-004), có MFA hợp lệ (FR-00-002); chuỗi `T68` tồn tại.

**Kích hoạt.** Khoa mở "Giám sát và kiểm toán › Nhật ký kiểm toán" (UI-13-13) và bấm "Tra cứu".

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu kiểm toán; không ghi vết được lượt tra thì không trả kết quả (BR-13-006).

**Đảm bảo thành công.** Có bản ghi `AUDIT.QUERY` và `AUDIT.RECORD.VIEW` trong chuỗi; Khoa có danh sách đã che, chỉ báo toàn vẹn và, với bản ghi đã mở, kết quả "Băm khớp" kèm chữ ký neo hợp lệ.

**Luồng chính.**

1. UI-13-13 hiện dải "Việc tra cứu này sẽ được ghi vết." Khoa nhập khoảng từ 01/11/2026 đến 25/11/2026, `outcome = DENIED`, `actor = htt-dvc`, lý do "Điều tra khiếu nại số 42/2026" (10 đến 500 ký tự) rồi bấm "Tra cứu". UI gọi API-13-074.
2. Hệ thống kiểm tra khoảng thời gian (≤ 31 ngày), lý do và quyền.
3. Hệ thống ghi `AUDIT.QUERY` kèm điều kiện lọc và lý do trước khi trả kết quả (UC-13-11).
4. Hệ thống ước lượng số kết quả (≤ 1.000.000) và truy vấn `audit_event` theo chỉ mục (RLS theo tenant), mới nhất trước, trang tối đa 200.
5. Hệ thống đính kèm chỉ báo toàn vẹn của phạm vi: lượt kiểm tra gần nhất `PASSED` lúc 03:07 hôm nay, neo gần nhất 14:00, trạng thái chuỗi `OK`.
6. UI hiện 318 bản ghi gồm thời điểm, chủ thể, hành động, đối tượng, kết quả, mục đích, kèm chỉ báo toàn vẹn nổi bật.
7. Khoa bấm dòng `seq` 40.115. UI gọi API-13-075 kèm `queryId`. Hệ thống kiểm tra quyền và tenant của bản ghi, tính lại `hash` từ `prev_hash` và nội dung chuẩn tắc rồi so với `hash` lưu: "Băm khớp".
8. Hệ thống tìm neo gần nhất có `seq` cuối ≥ 40.115 và xác minh chữ ký neo bằng khóa công khai theo `key_version` (API-13-080).
9. Hệ thống ghi `AUDIT.RECORD.VIEW` gắn `queryId` và trả bản ghi đầy đủ; UI dựng khác biệt giá trị trước và sau đã che bằng `CMP-DiffViewer`, hiện mã băm và nút "Mở trace" (UC-13-18).

**Luồng thay thế.**

- **1a. Khoảng có phần quá 12 tháng.** Phần trực tuyến trả bình thường; phần cũ hơn hiện dòng "Dữ liệu trước {ngày} nằm ở kho lưu trữ; dùng Xuất bằng chứng để lấy." (UC-13-15).
- **1b. Tra theo `traceId`.** Hệ thống trả mọi bản ghi của một yêu cầu.
- **5a. Chuỗi ở `SUSPECT`.** Kết quả vẫn trả kèm dải đỏ và đánh dấu bản ghi trong khoảng nghi vấn (UC-13-08).
- **7a. Bản ghi có `object_key_hmac`.** UI hiển thị băm rút gọn, không có giá trị rõ.

**Luồng ngoại lệ.**

- **E1. Thiếu lý do (bước 2).** ERR-13-012 (422): "Cần nhập lý do truy vấn nhật ký kiểm toán (10 đến 500 ký tự)."
- **E2. Thiếu hoặc sai khoảng thời gian (bước 2).** ERR-13-004 (400): "Cần chọn khoảng thời gian hợp lệ (từ trước đến)."; khoảng quá dài: ERR-13-005 (422).
- **E3. Phạm vi quá rộng (bước 4).** ERR-13-013 (422): "Phạm vi truy vấn quá rộng (1250000 bản ghi). Thu hẹp phạm vi hoặc chuyển sang xuất bằng chứng chạy nền."
- **E4. Không đủ quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này." và hệ thống ghi cảnh báo an ninh.
- **E5. Cơ sở dữ liệu không khả dụng hoặc quá 30 giây (bước 4).** ERR-13-014 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."; quá thời gian: ERR-13-015 (504): "Truy vấn quá thời gian chờ. Hãy thu hẹp khoảng thời gian hoặc điều kiện lọc."
- **E6. Toàn bộ khoảng nằm ngoài 12 tháng (bước 2), hoặc bản ghi đã lưu trữ (bước 7).** ERR-13-029 (422): "Khoảng thời gian này đã quá thời hạn lưu trực tuyến (12 tháng). Dùng xuất bằng chứng để lấy từ kho lưu trữ."
- **E7. Bản ghi không tìm thấy hoặc thuộc tenant khác (bước 7).** ERR-13-001 (404): "Không tìm thấy bản ghi kiểm toán {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E8. Băm không khớp (bước 7).** Không phải lỗi API: kết quả trả `hashMatch=false`, UI hiện dải cảnh báo kèm loại lỗi và hệ thống chuyển sang UC-13-08.
- **E9. Không ghi được `AUDIT.QUERY` (bước 3).** Hệ thống không trả kết quả; ERR-13-014 (503).

**Quy tắc áp dụng.** BR-13-006, 007, 018, 030.

**Màn hình, API.** UI-13-13; API-13-074, 075, 080.
:::

### 6.13. UC-13-13 · Xem lịch sử thay đổi của một đối tượng

::: dac-ta
**Mục tiêu.** Người dùng nghiệp vụ thấy nhanh ai đã thay đổi gì trên đúng đối tượng đang xem, ngay trong màn chi tiết của phân hệ chủ, mà không phải sang công cụ kiểm toán.

**Tác nhân chính.** Người dùng có quyền `read` của đối tượng ở phân hệ chủ, ví dụ ROLE-INTEGRATION_ENGINEER (An) xem luồng `ho-tich-khai-sinh` ở PH-04.

**Tác nhân phụ.** BFF của DU chủ (giữ scope `audit:history-read`), API kiểm toán của PH-13, `CMP-AuditTrail` ở giao diện.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-022.

**Truy vết.** REQ-13; mọi quy trình (ghi dấu vết); LGC-APIM-027.

**Tiền điều kiện.** An có `read` của luồng (DU chủ kiểm tra); đối tượng có màn chi tiết kiểu PTN-02 và có bản ghi kiểm toán mang `object_type`, `object_id` tương ứng.

**Kích hoạt.** An mở tab "Lịch sử" hoặc liên kết sâu `/{ma}/lich-su` ở màn chi tiết của đối tượng.

**Đảm bảo tối thiểu.** Tab chỉ hiện nhật ký của đúng đối tượng thuộc tenant của An; lỗi của PH-13 không làm hỏng các tab khác của màn.

**Đảm bảo thành công.** Tab "Lịch sử" hiện dòng thời gian đã che của đối tượng, mới nhất trước.

**Luồng chính.**

1. An mở luồng `ho-tich-khai-sinh` ở PH-04 và bấm tab "Lịch sử". BFF của `dh-integration` kiểm tra An có `read` của luồng.
2. BFF đổi token của An và gọi `GET /objects/FLOW/ho-tich-khai-sinh/history?size=20` (API-13-076) kèm scope `audit:history-read`.
3. API xác định tenant `T68` từ token và kiểm tra đối tượng thuộc `T68`.
4. API truy vấn `audit_event` theo `(tenant_id, object_type, object_id)`, mới nhất trước, và trả `items[]` đã che gồm `id`, `occurredAt`, `actor`, `action`, `outcome`, `reason`, `hasDiff`.
5. `CMP-AuditTrail` dựng dòng thời gian, mỗi dòng gồm thời điểm, chủ thể (người hoặc máy, kèm đơn vị), hành động, kết quả, lý do; ví dụ "26/11 09:12 · Bình (Sở KH&CN) · FLOW.PUBLISH · SUCCESS".
6. Dòng có `hasDiff`: người có thêm `PERM-13-audit-read` bấm "Mở trong Nhật ký kiểm toán" để xem khác biệt trước và sau (UC-13-12 bước 7); người không có quyền này chỉ thấy dòng tóm tắt.

**Luồng thay thế.**

- **4a. Có bản ghi cũ hơn 12 tháng.** Phản hồi có `archivedBefore` và UI hiện "Lịch sử trước {ngày} nằm ở kho lưu trữ; liên hệ kiểm toán viên để trích xuất."
- **4b. Lọc theo `action`, `actor`, `from`, `to`.** An chọn bộ lọc ở đầu tab; BFF chuyển tham số tương ứng.
- **5a. Giá trị trước và sau.** Đã được che từ nguồn nên tab Lịch sử không có nút "Hiện" và `PERM-09-unmask` không áp dụng.

**Luồng ngoại lệ.**

- **E1. PH-13 không phản hồi (bước 2).** Vùng tab hiện "Chưa tải được lịch sử. Bấm Thử lại." kèm nút "Thử lại"; các tab khác vẫn dùng được; ERR-13-014 ghi ở BFF.
- **E2. Đối tượng không thuộc tenant (bước 3).** ERR-13-001 (404): "Không tìm thấy luồng ho-tich-khai-sinh. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E3. DU chủ thiếu scope `audit:history-read` (bước 2).** ERR-13-044 (403): "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."
- **E4. `size` vượt giới hạn (bước 2).** ERR-13-038 (400): "Số dòng mỗi trang tối đa 200 hoặc tham số ngoài miền cho phép."

**Quy tắc áp dụng.** BR-13-030.

**Màn hình, API.** Tab "Lịch sử" ở màn chi tiết của phân hệ chủ (PTN-02, `CMP-AuditTrail`), UI-13-13 (liên kết "Mở trong Nhật ký kiểm toán"); API-13-076. Việc tab có hiển thị lịch sử của tenant nguồn sau sáp nhập: xem Q13-48.
:::

### 6.14. UC-13-14 · Tra theo đối tượng bị tra cứu

::: dac-ta
**Mục tiêu.** Trả lời câu hỏi "ai đã tra cứu công dân hoặc doanh nghiệp X" mà không phải lưu số định danh rõ trong nhật ký: người điều tra nhập định danh, hệ thống băm có khóa rồi tìm theo băm.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng), ROLE-AUDITOR (Khoa).

**Tác nhân phụ.** OpenBao (`transit/hmac`, khóa `dh-T68-audit-hmac`), bảng `ph13_audit`, `dh-audit` (ghi `AUDIT.QUERY`).

**Mức ưu tiên.** S.

**FR hiện thực.** FR-13-023.

**Truy vết.** REQ-09, REQ-13; quy trình BP-06 (khai thác dữ liệu quốc gia); LGC-APIM-027.

**Tiền điều kiện.** Dũng có `PERM-13-audit-read`; các bản ghi tra cứu dữ liệu nhạy cảm (PH-14, PH-09) đã ghi `object_key_hmac`; khóa HMAC của `T68` có ở OpenBao.

**Kích hoạt.** Dũng chọn "Tra theo đối tượng" ở UI-13-13 và bấm "Tra".

**Đảm bảo tối thiểu.** Số định danh người điều tra nhập không bao giờ được lưu, ghi log hay trả lại (BR-13-005).

**Đảm bảo thành công.** Có bản ghi `AUDIT.QUERY` chỉ chứa băm; Dũng có danh sách lượt tra cứu đối tượng đó.

**Luồng chính.**

1. Có khiếu nại về việc hồ sơ bị tra trái phép. Dũng chọn "Tra theo đối tượng", nhập định danh `001199001234` (số giả lập), loại `CCCD`, khoảng 01/10/2026 đến 31/10/2026, lý do "Khiếu nại số 42/2026" và căn cứ "Công văn 112/CATP-A05".
2. Hệ thống chuẩn hóa định danh (bỏ khoảng trắng, kiểm tra độ dài 9 hoặc 12 chữ số với `CCCD`, `CMND`) và từ chối nếu sai định dạng.
3. Hệ thống gọi OpenBao `transit/hmac` với khóa theo tenant để tính `HMAC-SHA256`; định danh gốc không được lưu hay ghi log ở bất kỳ nơi nào, và ô nhập trên UI bị xóa ngay sau khi gửi.
4. Hệ thống ghi `AUDIT.QUERY` chứa `object_key_hmac` của người bị tra, lý do và căn cứ (UC-13-11), rồi truy vấn theo cột `object_key_hmac` (API-13-074, tham số `subject`).
5. Hệ thống trả danh sách lượt tra cứu gồm ai (người hoặc HTTT gốc), từ đâu, mục đích, thời điểm, kết quả; ví dụ 3 lượt, trong đó `htt-dvc` lúc 09:14 ngày 05/10/2026 với mục đích "Tra cứu hộ tịch"; trường `objectKeyHmac` hiển thị dạng rút gọn.

**Luồng thay thế.**

- **5a. Không có bản ghi.** Danh sách rỗng và UI hiện "Không có bản ghi nào trong khoảng đã chọn."
- **1a. Tra theo mã số thuế của doanh nghiệp.** Dùng cùng cơ chế với `idType = TAX_CODE` (10 hoặc 13 số).

**Luồng ngoại lệ.**

- **E1. Định danh sai định dạng (bước 2).** ERR-13-031 (422): "Số định danh không đúng định dạng."
- **E2. Thiếu lý do hoặc căn cứ (bước 1).** ERR-13-012 (422): "Cần nhập lý do truy vấn nhật ký kiểm toán (10 đến 500 ký tự)."
- **E3. OpenBao không khả dụng (bước 3).** ERR-13-014 (503): "Dịch vụ OpenBao tạm thời không khả dụng. Thử lại sau." Không tra được, không có bản ghi nào lưu định danh.
- **E4. Khoảng vượt 31 ngày (bước 1).** ERR-13-005 (422): "Khoảng thời gian tối đa cho loại dữ liệu này là 31 ngày mỗi lần tra. Hãy thu hẹp khoảng."
- **E5. Thiếu quyền (bước 1).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-005, 006, 007.

**Màn hình, API.** UI-13-13 (chế độ "Tra theo đối tượng bị tra cứu"); API-13-074.
:::

### 6.15. UC-13-15 · Xuất bằng chứng kiểm toán ký số

::: dac-ta
**Mục tiêu.** Kiểm toán viên có một gói bằng chứng có giá trị pháp lý cho thanh tra, điều tra: bản ghi trong phạm vi kèm chuỗi băm, neo, khóa công khai và kết quả kiểm tra toàn vẹn, ký số, để người nhận tự xác minh ngoại tuyến mà không cần truy cập Datahub.

**Tác nhân chính.** ROLE-AUDITOR (Khoa), ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Tác vụ nền, bảng `ph13_audit`, kho WORM (bản ghi cũ hơn 12 tháng), OpenBao (ký số), bucket tạm, trung tâm thông báo (FR-00-060).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-024.

**Truy vết.** REQ-13; quy trình BP-07, thanh tra; LGC-APIM-027; FR-00-031.

**Tiền điều kiện.** Khoa có `PERM-13-audit-export`; đã chọn tenant `T68`; khóa ký bằng chứng có ở OpenBao; bucket tạm còn dung lượng.

**Kích hoạt.** Khoa bấm "Xuất bằng chứng" ở UI-13-13 hoặc UI-13-14.

**Đảm bảo tối thiểu.** Không ký được thì không xuất và không để lại tệp chưa ký (BR-13-014); gói không chứa bản ghi của tenant khác (BR-13-017).

**Đảm bảo thành công.** Yêu cầu ở trạng thái `READY`, có `file_hash`; gói ký số tải được trong 15 phút kể từ khi cấp liên kết, tệp xóa sau 7 ngày; siêu dữ liệu xuất lưu 5 năm.

**Luồng chính.**

1. Khoa nhập phạm vi từ 01/07/2026 đến 30/09/2026, bộ lọc `{"actor":"htt-dvc"}`, lý do "Phục vụ thanh tra theo QĐ 88/QĐ-TTr", căn cứ "QĐ 88/QĐ-TTr", rồi xác thực lại phiên (LP-13-02).
2. UI gọi API-13-082 kèm `Idempotency-Key`. Hệ thống kiểm tra phạm vi (tối đa 10 triệu bản ghi), không có yêu cầu trùng đang chạy, tạo yêu cầu `REQUESTED`, ghi `AUDIT.EXPORT.REQUEST` và trả `202` kèm `exportId` và `Location`.
3. Tác vụ nền trích bản ghi: phần trong 12 tháng từ bảng, phần cũ hơn từ WORM.
4. Tác vụ chạy kiểm tra toàn vẹn cho phạm vi và nhúng kết quả; nếu không toàn vẹn vẫn xuất nhưng ghi cảnh báo rõ ở đầu `verification.json` và `README`.
5. Tác vụ đóng gói `records.jsonl`, `manifest.json`, `anchors.json`, `public-keys.pem`, `verification.json`, hướng dẫn xác minh và script `verify`; tính SHA-256 của gói và ký số bằng khóa OpenBao.
6. Hệ thống lưu gói ở bucket tạm 7 ngày, chuyển `READY`, ghi `file_hash`, phát EVT-13-08 và thông báo cho Khoa; UI-13-14 hiện tiến độ qua API-13-083 (`status`, `recordCount`, `fileHash`, `expiresAt`).
7. Khoa bấm "Tải" (API-13-084); liên kết hết hạn sau 15 phút; hệ thống ghi `AUDIT.EXPORT.DOWNLOAD`.
8. Khoa chạy script `verify` đi kèm trên máy của thanh tra, không nối mạng Datahub, và kết quả đối chiếu chữ ký và chuỗi băm là đạt.

**Luồng thay thế.**

- **1a. Kiểm toán viên cấp nền tảng xuất cho tenant khác.** Phải qua phiên liên tenant có lý do (LP-13-03).
- **2a. Phạm vi nhỏ** (dưới 10.000 bản ghi). Vẫn chạy nền để nhất quán cách làm.

**Luồng ngoại lệ.**

- **E1. Chưa xác thực lại phiên (bước 1).** ERR-13-028 (403): "Cần xác thực lại để thực hiện thao tác này."
- **E2. Có yêu cầu cùng phạm vi đang chạy (bước 2).** ERR-13-025 (409): "Đã có yêu cầu xuất bằng chứng cùng phạm vi đang chạy."
- **E3. Phạm vi quá 10 triệu bản ghi (bước 2).** ERR-13-013 (422): "Phạm vi truy vấn quá rộng (12400000 bản ghi). Thu hẹp phạm vi hoặc chuyển sang xuất bằng chứng chạy nền."
- **E4. Thiếu lý do hoặc căn cứ (bước 1).** ERR-13-012 (422): "Cần nhập lý do truy vấn nhật ký kiểm toán (10 đến 500 ký tự)."
- **E5. Không ký được (bước 5).** Không xuất, yêu cầu `FAILED`; ERR-13-026 (503): "Chưa ký số được tệp bằng chứng nên không xuất. Thử lại sau hoặc liên hệ quản trị nền tảng."
- **E6. Tải khi tệp đã hết hạn (bước 7).** ERR-13-027 (410): "Tệp bằng chứng đã hết hạn tải. Tạo yêu cầu xuất mới."
- **E7. Người dùng thiếu `PERM-13-audit-export` (bước 1).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này." Quản trị tỉnh (TA) có quyền xem nhật ký nhưng không có quyền xuất.

**Quy tắc áp dụng.** BR-13-006, 014, 017, 029.

**Màn hình, API.** UI-13-14 (nút "Xuất bằng chứng", tiến độ, tải gói), UI-13-13; API-13-082, 083, 084.
:::

### 6.16. UC-13-16 · Rà soát truy cập liên tenant

::: dac-ta
**Mục tiêu.** Quản trị tỉnh thấy minh bạch những lần cán bộ của nền tảng đã vào dữ liệu tenant của mình (ai, khi nào, vì lý do gì, làm gì), và nền tảng tự rà soát việc truy cập liên tenant của chính mình.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang), ROLE-SECURITY_OFFICER (Dũng), ROLE-AUDITOR (Khoa).

**Tác nhân phụ.** ROLE-PLATFORM_OPERATOR (Lan, người mở phiên), PH-12, trung tâm thông báo, SIEM.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-13-025.

**Truy vết.** REQ-13, REQ-20; quy trình BP-07; LGC-APIM-027; UC-SEC-25.

**Tiền điều kiện.** Bản ghi `AUDIT.CROSS_TENANT.OPEN` và các thao tác trong phiên đã được ghi ở chuỗi của `T68`; Giang có `PERM-13-audit-read` của `T68`.

**Kích hoạt.** Một phiên liên tenant được mở và thông báo tới quản trị tỉnh; Giang mở UI-13-16.

**Đảm bảo tối thiểu.** Mọi lần truy cập liên tenant đều có phiên, lý do, thời hạn và nằm ở cả hai chuỗi (BR-13-018); xem báo cáo cũng bị ghi vết.

**Đảm bảo thành công.** Giang có danh sách phiên theo người, lý do, số thao tác, kèm liên kết tới từng thao tác.

**Luồng chính.**

1. Lan mở phiên liên tenant vào `T68` với lý do "Điều tra độ trễ Kafka theo phiếu INC-2026-1187", thời hạn mặc định 60 phút (FR-00-012). Hệ thống ghi `AUDIT.CROSS_TENANT.OPEN` vào chuỗi của cả `PLATFORM` và `T68` và phát EVT-13-12.
2. Hệ thống thông báo cho Giang và Dũng (FR-00-060) và đưa luật UC-SEC-25 vào cảnh báo mức Trung bình.
3. Giang mở UI-13-16, chọn khoảng từ 01/11/2026 đến 26/11/2026; UI gọi API-13-085.
4. Hệ thống truy vấn bản ghi có `actor_home_tenant` khác `tenant_id` trong khoảng.
5. Hệ thống gom theo phiên: người (Lan), tenant nhà (`PLATFORM`), lý do, thời hạn, số thao tác (14), kết quả, kèm liên kết "Xem thao tác" mở UC-13-12 đã lọc theo phiên.
6. Hết thời hạn 60 phút hoặc Lan kết thúc phiên, hệ thống ghi `AUDIT.CROSS_TENANT.CLOSE`.
7. Việc Giang xem báo cáo được ghi `AUDIT.QUERY` loại `CROSS_TENANT_REPORT`.

**Luồng thay thế.**

- **3a. Tenant `PLATFORM` xem phía "đi".** Hà thấy các lần cán bộ nền tảng vào tenant khác, gom theo tenant thay vì theo người.
- **3b. Kiểm toán viên cấp nền tảng.** Khoa xem phía tenant nhà qua phiên liên tenant có lý do (LP-13-03).

**Luồng ngoại lệ.**

- **E1. Thao tác liên tenant không có phiên hợp lệ (bước 1).** ERR-13-036 (403): "Truy cập tenant khác cần phiên liên tenant có lý do còn hiệu lực."; hệ thống ghi `OBS.CROSS_TENANT_ATTEMPT`.
- **E2. Mở phiên thiếu lý do (bước 1).** ERR-13-008 (400): "Thao tác này cần nhập lý do từ 10 đến 500 ký tự."
- **E3. Người xem thiếu quyền (bước 3).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E4. Dữ liệu chưa tải được (bước 4).** ERR-13-014 (503): "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau."

**Quy tắc áp dụng.** BR-13-006, 018.

**Màn hình, API.** UI-13-16; API-13-085.
:::

### 6.17. UC-13-17 · Tra log tập trung và theo dõi trực tiếp

::: dac-ta
**Mục tiêu.** Người vận hành và kỹ sư tích hợp tìm log của mọi thành phần ở một nơi, theo thời gian, thành phần, mức, luồng, mã truy vết, đọc được bối cảnh quanh một dòng lỗi và theo dõi log mới khi đang xử lý sự cố, thay cho việc vào từng agent đọc log như hệ cũ.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi), ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** Loki, API quan sát của `dh-platform`, PH-12 (quyền).

**Mức ưu tiên.** M (tra log), S (chi tiết, ngữ cảnh, trực tiếp).

**FR hiện thực.** FR-13-026, 027.

**Truy vết.** REQ-13; quy trình BP-07; LGC-BUS-029, LGC-PAY-021, LGC-NFR-004.

**Tiền điều kiện.** Chi có `PERM-13-logs`; đã chọn tenant `T68`; UC-13-01 đang đưa log vào Loki.

**Kích hoạt.** Chi mở "Giám sát › Tra log" (UI-13-07), nhập truy vấn và bấm "Chạy"; hoặc mở liên kết từ cảnh báo hay trace.

**Đảm bảo tối thiểu.** Truy vấn luôn bị ép nhãn tenant; log trả về đã che; log an ninh không lộ cho người không có quyền riêng.

**Đảm bảo thành công.** Chi thấy danh sách dòng log và histogram trong vài giây, mở được chi tiết, ngữ cảnh và chế độ trực tiếp.

**Luồng chính.**

1. Chi giữ khoảng mặc định "1 giờ qua" và nhập `du:dh-runtime AND level:ERROR` rồi bấm "Chạy". UI gọi API-13-019.
2. Hệ thống kiểm tra khoảng thời gian (tối đa 7 ngày), cú pháp truy vấn và quyền với luồng log được yêu cầu.
3. Hệ thống dịch truy vấn sang LogQL, ép nhãn `tenant="T68"` (UC-13-01 bước 7), gọi Loki với giới hạn 1.000 dòng mỗi trang và trả `entries[]`, `histogram[]`, `nextCursor`.
4. UI hiện histogram số dòng theo thời gian và danh sách ảo hóa; mức log có nhãn chữ ("LỖI", "CẢNH BÁO", "TT", "GỠ LỖI") kèm màu.
5. Chi kéo chọn một đoạn trên histogram để thu hẹp khoảng rồi chạy lại.
6. Chi bấm một dòng. UI mở chi tiết bằng `CMP-JsonViewer` và gọi API-13-020 lấy 50 dòng trước và 50 dòng sau của cùng `du` và pod; hiện nút "Sao chép trace_id" và "Mở trace" (UC-13-18).
7. Chi bật công tắc "Trực tiếp". UI mở API-13-021 (luồng SSE); dòng mới chèn ở đầu, tối đa 1.000 dòng trong bộ nhớ; cuộn khỏi đầu thì tạm dừng chèn và hiện "{n} sự kiện mới · Về đầu"; chế độ tự tắt sau 15 phút không tương tác.
8. Chi bấm "Lưu truy vấn" (API-13-028), đặt tên "Lỗi runtime" và chia sẻ trong tenant; truy vấn đã lưu liệt kê ở API-13-027 và xóa được ở API-13-029 bởi chủ sở hữu.

**Luồng thay thế.**

- **1a. Truy vấn theo `trace_id`.** Hệ thống bỏ giới hạn dòng đầu và trả mọi dòng của trace.
- **2a. Xem log an ninh** (`stream=security`). Cần `PERM-13-security` hoặc `PERM-13-audit-read`; hệ thống ghi `AUDIT.QUERY` (UC-13-11).
- **7a. Một người một kết nối trực tiếp.** Mở thêm thì kết nối cũ đóng.

**Luồng ngoại lệ.**

- **E1. Khoảng quá dài (bước 2).** ERR-13-005 (422): "Khoảng thời gian tối đa cho loại dữ liệu này là 7 ngày mỗi lần tra. Hãy thu hẹp khoảng."
- **E2. Cú pháp sai (bước 2).** ERR-13-006 (400): "Cú pháp truy vấn chưa đúng ở vị trí 18: thiếu giá trị sau dấu hai chấm."
- **E3. Quá nhiều truy vấn hoặc quá thời gian (bước 3).** ERR-13-011 (429): "Bạn đang chạy quá nhiều truy vấn cùng lúc. Chờ vài giây rồi thử lại."; ERR-13-015 (504): "Truy vấn quá thời gian chờ. Hãy thu hẹp khoảng thời gian hoặc điều kiện lọc."
- **E4. Loki không khả dụng (bước 3).** ERR-13-014 (503): "Dịch vụ Loki tạm thời không khả dụng. Thử lại sau."
- **E5. Dòng log đã quá 90 ngày (bước 6).** ERR-13-001 (404): "Không tìm thấy dòng log {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E6. Quá giới hạn kết nối trực tiếp của tenant (bước 7).** ERR-13-011 (429).
- **E7. Mất kết nối trực tiếp (bước 7).** UI tự nối lại 3 lần rồi hiện "Mất kết nối trực tiếp. Bấm Thử lại." (ERR-13-014).
- **E8. Xem log an ninh khi thiếu quyền riêng (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-011, 030.

**Màn hình, API.** UI-13-07; API-13-019, 020, 021, 027, 028, 029.
:::

### 6.18. UC-13-18 · Truy vết một yêu cầu và liên kết ba nguồn

::: dac-ta
**Mục tiêu.** Người chẩn đoán dựng được hành trình một yêu cầu qua mọi thành phần, thấy chặng nào lỗi hoặc chậm và chiếm bao nhiêu phần trăm thời gian để phân định trách nhiệm, rồi đi từ `trace_id` tới log, chỉ số và (nếu có quyền) bản ghi kiểm toán liên quan.

**Tác nhân chính.** ROLE-INTEGRATION_ENGINEER (An), ROLE-TENANT_OPERATOR (Chi).

**Tác nhân phụ.** Tempo, Loki, Mimir (điểm chỉ số mẫu), bảng `ph13_audit` (khi người xem có `PERM-13-audit-read`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-028, 029.

**Truy vết.** REQ-13; quy trình BP-07; LGC-BUS-038.

**Tiền điều kiện.** Trace được giữ theo UC-13-01 và còn trong 14 ngày; mọi thành phần truyền `trace_id`; An có `PERM-13-logs`.

**Kích hoạt.** An dán `trace_id` vào ô tìm ở UI-13-08, hoặc mở liên kết `trace_id` từ thông báo lỗi, dòng log, cảnh báo, bảng điều khiển.

**Đảm bảo tối thiểu.** Thuộc tính span đã che; phần kiểm toán không lộ (kể cả việc có tồn tại hay không) cho người không có `PERM-13-audit-read`.

**Đảm bảo thành công.** An thấy thác nước, phân bổ thời gian, nhận xét tự động và các liên kết sang log, chỉ số, kiểm toán.

**Luồng chính.**

1. HTTT `htt-dvc` báo giao dịch tra cứu hộ tịch chậm; An lấy mã truy vết `4bf92f3577b34da6a3ce929d0e0e4736` từ thông báo lỗi và dán vào ô tìm ở UI-13-08.
2. Hệ thống kiểm tra `traceId` đúng định dạng (32 ký tự thập lục phân) và thuộc tenant `T68`.
3. Hệ thống lấy toàn bộ span từ Tempo (ép tenant), dựng cây span theo quan hệ cha-con và tính phân bổ thời gian theo thành phần (API-13-023).
4. Hệ thống đánh dấu chặng lỗi và chặng chiếm hơn 50% thời gian, rồi sinh nhận xét tự động ngắn gọn, ví dụ "94% thời gian là chờ nền tảng quốc gia."
5. UI hiển thị tóm tắt (thời gian tổng 1.360 ms, trạng thái, 9 chặng, bên gọi), biểu đồ thác nước, bảng phân bổ và thuộc tính span đã che; chặng lỗi tô đỏ và tự mở rộng.
6. An bấm chặng "gọi NDXP"; khung bên phải hiện log của chặng đó (UC-13-17 với `trace_id` và `span_id`).
7. An bấm hàng nút cuối trang. UI gọi API-13-024; hệ thống hỏi Tempo, Loki, Mimir song song và trả `trace`, `logs` (14 dòng, kèm liên kết tra log), `exemplars[]`, `remark`, và `audit` chỉ khi An có `PERM-13-audit-read`; không có quyền thì trường `audit` vắng hẳn.
8. Người có quyền bấm "Mở bản ghi kiểm toán"; UI chuyển sang UC-13-12 đã lọc theo `traceId`, nơi việc xem bản ghi được ghi `AUDIT.RECORD.VIEW`.

**Luồng thay thế.**

- **1a. Tìm theo điều kiện.** An nhập `from`, `to`, `du`, `route`, `system`, `status=ERROR`, `minDurationMs`; hệ thống trả tối đa 100 trace (API-13-022), mỗi mục có `traceId`, thời gian, trạng thái, số chặng.
- **5a. Trace chưa đủ span.** UI hiển thị phần có, vẽ khoảng thiếu và ghi "Trace chưa đủ span" (ERR-13-117 ở UC-13-01).
- **7a. Trace đã hết hạn giữ hoặc bị bỏ do lấy mẫu nhưng log còn.** Hệ thống trả log kèm thông báo "Trace đã hết hạn giữ, chỉ còn log".

**Luồng ngoại lệ.**

- **E1. Không có dữ liệu ở cả ba nguồn (bước 3, 7).** ERR-13-030 (404): "Không tìm thấy trace 4bf92f3577b34da6a3ce929d0e0e4736. Trace chỉ giữ 14 ngày và chỉ giữ một phần trace thành công." UI vẫn gợi ý xem log còn lại và kiểm tra khoảng thời gian.
- **E2. `traceId` sai định dạng (bước 2).** ERR-13-003 (400): "Dữ liệu gửi lên không hợp lệ."
- **E3. Một kho không khả dụng (bước 3, 7).** Phần đó trả `unavailable` kèm ERR-13-014 (503): "Dịch vụ Tempo tạm thời không khả dụng. Thử lại sau."; các phần khác vẫn hiển thị. Quá thời gian: ERR-13-015 (504).
- **E4. `traceId` thuộc tenant khác (bước 2).** ERR-13-001 (404): "Không tìm thấy trace {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E5. Truy vấn chạm tenant khác (bước 3).** ERR-13-044 (403): "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."

**Quy tắc áp dụng.** BR-13-006, 010, 011, 030.

**Màn hình, API.** UI-13-08; API-13-022, 023, 024.
:::

### 6.19. UC-13-19 · Tra nhật ký truy cập API

::: dac-ta
**Mục tiêu.** Người vận hành và kỹ sư tra từng lượt gọi API qua gateway (HTTT nào gọi API nào, lúc nào, kết quả, độ trễ), thay màn "Log request" của APIM cũ, nhưng chỉ có siêu dữ liệu, không có thân bản tin.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); cũng dùng bởi ROLE-PLATFORM_OPERATOR (Lan) và ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** ClickHouse (bảng `access_log`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-030.

**Truy vết.** REQ-03, REQ-13; quy trình BP-07; LGC-APIM-022; LGC-PAY-021.

**Tiền điều kiện.** Chi có `PERM-13-logs`; UC-13-03 đang ghi `access_log` của `T68`.

**Kích hoạt.** Chi mở "Giám sát › Nhật ký truy cập API" (UI-13-09), hoặc mở từ bảng theo API, theo HTTT (UC-13-22) với bộ lọc điền sẵn.

**Đảm bảo tối thiểu.** Kết quả không chứa thân bản tin, giá trị Nhạy cảm hay tiêu đề xác thực; xuất tệp được che.

**Đảm bảo thành công.** Chi có danh sách lượt gọi theo bộ lọc, mở được siêu dữ liệu và trace của từng lượt.

**Luồng chính.**

1. HTTT `htt-dvc` báo gặp lỗi `5xx` khi gọi API `cong-dan.tra-cuu`. Chi chọn khoảng từ 00:00 ngày 26/11/2026, `systemCode = htt-dvc`, `apiCode = cong-dan.tra-cuu`, `statusClass = 5xx`, `minLatencyMs = 1000` và bấm "Tra".
2. Hệ thống kiểm tra khoảng thời gian (tối đa 31 ngày), tham số trong miền và quyền.
3. Hệ thống truy vấn `access_log` của `T68` theo `(tenant_id, route_id, ts)`, phân trang theo con trỏ (`limit` tối đa 200); UI gọi API-13-025.
4. UI hiện 37 dòng gồm `ts`, `systemCode`, `apiCode`, `method`, `pathTemplate`, `status`, `latencyMs`, `traceId`.
5. Chi bấm một dòng; UI gọi API-13-026 và hiện siêu dữ liệu chi tiết cùng liên kết "Mở trace" (UC-13-18).
6. Chi bấm "Xuất" để lấy kết quả đang lọc; việc xuất tuân thủ FR-00-030 và che dữ liệu theo FR-00-034.

**Luồng thay thế.**

- **1a. Lượt kiểm tra tổng hợp.** Mặc định ẩn; Chi bật `includeSynthetic` để xem.
- **1b. Mở từ UC-13-22.** Chọn một HTTT ở UI-13-03 chuyển sang màn này với `systemCode` điền sẵn.

**Luồng ngoại lệ.**

- **E1. Khoảng quá 31 ngày (bước 2).** ERR-13-005 (422): "Khoảng thời gian tối đa cho loại dữ liệu này là 31 ngày mỗi lần tra. Hãy thu hẹp khoảng."
- **E2. Tham số ngoài miền, `limit` lớn hơn 200 (bước 2).** ERR-13-038 (400): "Số dòng mỗi trang tối đa 200 hoặc tham số ngoài miền cho phép."
- **E3. ClickHouse không khả dụng hoặc quá 30 giây (bước 3).** ERR-13-014 (503): "Dịch vụ ClickHouse tạm thời không khả dụng. Thử lại sau."; ERR-13-015 (504): "Truy vấn quá thời gian chờ. Hãy thu hẹp khoảng thời gian hoặc điều kiện lọc."
- **E4. Không tìm thấy lượt gọi theo mã (bước 5).** ERR-13-001 (404): "Không tìm thấy lượt gọi {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E5. Thiếu quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-011, 030.

**Màn hình, API.** UI-13-09; API-13-025, 026.
:::

### 6.20. UC-13-20 · Theo dõi tổng quan nền tảng

::: dac-ta
**Mục tiêu.** Người vận hành và lãnh đạo thấy trong một màn hình nền tảng đang khỏe hay không (lưu lượng, tỷ lệ thành công, độ trễ, cảnh báo mở, thành phần nào có vấn đề) và đi tiếp tới đúng màn chi tiết; thay màn tổng quan riêng của Bus cũ và dashboard hoạt động chung của APIM cũ.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi), ROLE-VIEWER (Phúc, lãnh đạo Sở).

**Tác nhân phụ.** Mimir, ClickHouse, bảng cảnh báo ở `pg-core`.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-031.

**Truy vết.** REQ-13; quy trình BP-07, BP-09 (đối chiếu khi chạy song song); LGC-BUS-014, LGC-APIM-026; KPI-15, KPI-17.

**Tiền điều kiện.** Chi có `PERM-13-dashboard`; đã chọn tenant `T68`; UC-13-01, 03 đang thu dữ liệu.

**Kích hoạt.** Chi mở "Giám sát › Bảng giám sát" (UI-13-01), đổi khoảng thời gian hoặc bộ lọc.

**Đảm bảo tối thiểu.** Chỉ số thiếu dữ liệu hiện "Chưa có dữ liệu", không bao giờ hiện 0 (BR-13-016); một panel lỗi không làm hỏng cả màn.

**Đảm bảo thành công.** Chi thấy thẻ chỉ số, bản đồ thành phần, biểu đồ và 5 cảnh báo mới nhất, tự làm mới mỗi 30 giây.

**Luồng chính.**

1. Lúc 07:45 Chi mở UI-13-01; UI gọi song song API-13-001 (số liệu tổng quan) và API-13-002 (sức khỏe thành phần), khoảng mặc định 24 giờ.
2. Hệ thống kiểm tra quyền và khoảng thời gian.
3. Hệ thống lấy từ Mimir và ClickHouse: lượt gọi mỗi giây hiện tại (312), tỷ lệ thành công 5 phút (99,96%), độ trễ gateway p95 (41 ms, SLO 50 ms), số HTTT đang gọi, lưu lượng theo lớp trạng thái, độ trễ p50, p95, p99.
4. Hệ thống lấy số cảnh báo mở theo mức, 5 cảnh báo mới nhất, trạng thái kiểm tra tổng hợp (UC-13-04) và trạng thái hệ thống giám sát (UC-13-31).
5. Hệ thống tính trạng thái từng thành phần (Tốt, Cảnh báo, Lỗi, Chưa có dữ liệu) cho bản đồ thành phần.
6. UI hiển thị thẻ chỉ số, bản đồ thành phần (mỗi ô có nhãn chữ cộng màu), biểu đồ lưu lượng và độ trễ, danh sách 5 cảnh báo; tự làm mới mỗi 30 giây khi tab đang hiển thị.
7. Chi thấy ô "Kafka" ở trạng thái "Cảnh báo" và bấm vào để mở UC-13-23. Phúc mở cùng màn và thấy thẻ, bản đồ, biểu đồ; không có log hay kiểm toán.

**Luồng thay thế.**

- **1a. Toàn nền tảng (PA, PO).** Màn chỉ hiện chỉ số hạ tầng chung và tổng hợp theo số lượng, không có chi tiết theo HTTT hay API của tenant; muốn xem chi tiết một tenant phải mở phiên liên tenant (LP-13-03, BR-13-030).
- **1b. Chủ dịch vụ (SV).** Minh chỉ thấy lượt gọi của API thuộc tổ chức mình.
- **2a. Đổi khoảng thời gian.** Chọn từ 15 phút tới 31 ngày; mọi biểu đồ cùng màn đồng bộ theo.

**Luồng ngoại lệ.**

- **E1. Thiếu dữ liệu cho một chỉ số (bước 3).** UI hiện "Chưa có dữ liệu" (BR-13-016).
- **E2. Mimir hoặc ClickHouse không khả dụng (bước 3).** Panel liên quan hiện ERR-13-014: "Dịch vụ Mimir tạm thời không khả dụng. Thử lại sau." kèm nút "Thử lại"; các thẻ còn lại vẫn hiển thị.
- **E3. Khoảng thời gian sai (bước 2).** ERR-13-004 (400): "Cần chọn khoảng thời gian hợp lệ (từ trước đến)."
- **E4. Thiếu quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-016, 030.

**Màn hình, API.** UI-13-01; API-13-001, 002.
:::

### 6.21. UC-13-21 · Theo dõi data plane: đơn vị triển khai, luồng, route, endpoint

::: dac-ta
**Mục tiêu.** Người vận hành và kỹ sư tích hợp đi từ đơn vị triển khai xuống luồng, route và endpoint để thấy cái gì đang xử lý bao nhiêu, lỗi ở đâu, tốn bao nhiêu tài nguyên; thay các màn agent, route, endpoint và biểu đồ histogram của Bus cũ.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi), ROLE-INTEGRATION_ENGINEER (An).

**Tác nhân phụ.** Mimir, ClickHouse, PH-04 (liên kết sang chi tiết luồng).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-032, 033, 034.

**Truy vết.** REQ-13; quy trình BP-07, BP-09; LGC-BUS-007, LGC-BUS-014, LGC-BUS-015, LGC-BUS-016, LGC-BUS-017, LGC-BUS-019, LGC-BUS-027.

**Tiền điều kiện.** Đơn vị triển khai `dh-runtime` do PH-04 tạo; luồng đã phát hành; `dh-runtime` xuất chỉ số có nhãn `flow`, `route`; An có `PERM-13-dashboard`.

**Kích hoạt.** An mở UI-13-02 (ba tab Đơn vị triển khai, Luồng, Endpoint), hoặc mở từ chi tiết luồng ở PH-04.

**Đảm bảo tối thiểu.** IE chỉ thấy đơn vị, luồng, endpoint thuộc workspace của mình; chỉ số thiếu hiện "Chưa có dữ liệu".

**Đảm bảo thành công.** An xác định được đơn vị, luồng, route, endpoint đang chậm hoặc lỗi và mở được trace lỗi tương ứng.

**Luồng chính.**

1. An mở tab "Đơn vị triển khai"; UI gọi API-13-003 và hiện danh sách cùng tổng "đơn vị hoạt động trên tổng số" (6 trên 6).
2. Hệ thống kiểm tra quyền và khoảng thời gian; An chỉ thấy đơn vị chứa luồng của workspace mình.
3. Hệ thống lấy theo từng đơn vị: phiên bản ảnh, số bản sao sẵn sàng trên số mong muốn, số luồng và route, số bản tin thành công và thất bại, thời gian xử lý trung bình, số lần khởi động lại, CPU và bộ nhớ; rồi xếp trạng thái Tốt, Cảnh báo (thiếu bản sao hoặc tỷ lệ lỗi cao) hoặc Lỗi (không có bản sao sẵn sàng).
4. An thấy `dh-runtime-hotich` ở "Cảnh báo" (2 trên 3 bản sao, 4,2% lỗi) và bấm vào; UI gọi API-13-004 hiện biểu đồ CPU, bộ nhớ từng pod và danh sách luồng kèm liên kết sang chi tiết luồng ở PH-04.
5. An mở tab "Luồng"; UI gọi API-13-005 và hiện từng luồng với thông lượng, tỷ lệ lỗi, p50, p95, p99. An bấm `ho-tich-khai-sinh` (API-13-006: biểu đồ thành công và thất bại, p50, p95, p99, bảng route) rồi bấm route `gui-van-ban` (API-13-007).
6. An nhấn điểm lỗi lúc 10:20 trên biểu đồ; UI mở danh sách trace lỗi của route trong khoảng đó (UC-13-18).
7. An mở tab "Endpoint"; UI gọi API-13-008 và hiện theo endpoint số lưu lượng, số lỗi và mã lỗi chính, thời điểm và `trace_id` của bản tin gần nhất (không có nội dung), p95, cùng bảng xếp hạng "API được gọi nhiều nhất".

**Luồng thay thế.**

- **3a. Đơn vị vừa tạo chưa có chỉ số.** Các cột số liệu hiện "Chưa có dữ liệu".
- **5a. Luồng đã tạm dừng.** Hiển thị "Tạm dừng" và giữ biểu đồ lịch sử.
- **5b. Độ phân giải.** Tối thiểu 15 giây theo chu kỳ thu (Q13-15); phóng to hết cỡ vẫn hiển thị 15 giây.
- **7a. Endpoint không có lượt trong khoảng.** Hiện "Không có lượt" thay vì 0 lỗi.

**Luồng ngoại lệ.**

- **E1. Đơn vị, luồng hoặc route không tồn tại hay thuộc tenant khác (bước 4, 5).** ERR-13-001 (404): "Không tìm thấy đơn vị triển khai dh-runtime-hotich. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E2. Mimir hoặc ClickHouse không khả dụng.** ERR-13-014 (503): "Dịch vụ Mimir tạm thời không khả dụng. Thử lại sau."
- **E3. Khoảng thời gian không hợp lệ (bước 2).** ERR-13-004 (400): "Cần chọn khoảng thời gian hợp lệ (từ trước đến)."
- **E4. Tham số ngoài miền (bước 7).** ERR-13-038 (400): "Số dòng mỗi trang tối đa 200 hoặc tham số ngoài miền cho phép."

**Quy tắc áp dụng.** BR-13-016, 026, 030.

**Màn hình, API.** UI-13-02; API-13-003, 004, 005, 006, 007, 008.
:::

### 6.22. UC-13-22 · Theo dõi theo API và theo HTTT

::: dac-ta
**Mục tiêu.** Quản trị, chủ dịch vụ và người vận hành thấy mỗi API và mỗi HTTT thành viên được gọi thế nào (số lượt, tỷ lệ lỗi, độ trễ, mức dùng hạn mức, số lần bị giới hạn) để quản lý chất lượng dịch vụ và phát hiện HTTT dùng bất thường; thay dashboard hoạt động của hệ thống API cũ.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang), ROLE-SERVICE_OWNER (Minh), ROLE-TENANT_OPERATOR (Chi).

**Tác nhân phụ.** ClickHouse (view tổng hợp theo giờ), PH-01 (HTTT), PH-02 (API), PH-03 (chỉ số hạn mức).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-035.

**Truy vết.** REQ-03, REQ-13; quy trình BP-07; LGC-APIM-026; LGC-APIM-022.

**Tiền điều kiện.** UC-13-03 đang ghi `access_log`; PH-01, PH-02 cung cấp danh mục HTTT, API; người xem có `PERM-13-dashboard`.

**Kích hoạt.** Giang mở UI-13-03, hoặc bấm một API hay một HTTT trong bảng.

**Đảm bảo tối thiểu.** Chủ dịch vụ chỉ thấy API thuộc tổ chức mình; lượt kiểm tra tổng hợp không bị tính vào thống kê.

**Đảm bảo thành công.** Giang có bảng xếp hạng API và HTTT kèm xu hướng so với khoảng liền trước và mở được chi tiết một HTTT.

**Luồng chính.**

1. Giang mở UI-13-03; UI gọi API-13-009 cho bảng API.
2. Hệ thống kiểm tra quyền và phạm vi tổ chức của người xem.
3. Hệ thống tổng hợp từ view vật chất hóa theo giờ: số lượt, số lỗi theo lớp, p50, p95, p99; theo HTTT còn có số lượt `429` (hết hạn mức) và tỷ lệ dùng hạn mức lấy từ chỉ số của PH-03.
4. Hệ thống xếp hạng API và HTTT theo lượt, lỗi, độ trễ, kèm xu hướng; ví dụ `cong-dan.tra-cuu` có 48.200 lượt, lỗi 0,9%, p95 182 ms, tăng 6%; HTTT `htt-dvc` dùng 92% hạn mức với 1.240 lượt `429`.
5. Giang bấm `htt-dvc`; UI gọi API-13-010 và hiện biểu đồ theo thời gian, danh sách API HTTT này đã gọi và liên kết sang UC-13-19 đã lọc theo `systemCode`.
6. Minh (chủ dịch vụ của Sở Tư pháp) mở cùng màn và chỉ thấy các API thuộc tổ chức mình.

**Luồng thay thế.**

- **3a. HTTT chưa gọi lần nào trong khoảng.** HTTT đó hiện trong danh sách "Chưa có lượt gọi" để chủ quản biết HTTT chưa kết nối.

**Luồng ngoại lệ.**

- **E1. API hoặc HTTT không tồn tại, thuộc tenant khác hoặc không thuộc tổ chức của người xem (bước 5, 6).** ERR-13-001 (404): "Không tìm thấy API {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E2. ClickHouse không khả dụng hoặc quá 30 giây (bước 3).** ERR-13-014 (503): "Dịch vụ ClickHouse tạm thời không khả dụng. Thử lại sau."; ERR-13-015 (504): "Truy vấn quá thời gian chờ. Hãy thu hẹp khoảng thời gian hoặc điều kiện lọc."
- **E3. Tham số ngoài miền (bước 1).** ERR-13-038 (400): "Số dòng mỗi trang tối đa 200 hoặc tham số ngoài miền cho phép."

**Quy tắc áp dụng.** BR-13-016, 030.

**Màn hình, API.** UI-13-03; API-13-009, 010.
:::

### 6.23. UC-13-23 · Theo dõi hạ tầng: nút gateway và cụm Kafka

::: dac-ta
**Mục tiêu.** Người vận hành phát hiện sớm nút gateway lệch cấu hình hoặc sắp quá tải, và cụm Kafka thiếu bản sao hoặc quá tải, trước khi ảnh hưởng người dùng; thay màn "Gateway đang kết nối" và giám sát CPU, JVM của APIM cũ, biểu đồ CPU, bộ nhớ của Hub cũ.

**Tác nhân chính.** ROLE-PLATFORM_OPERATOR (Lan); ROLE-TENANT_OPERATOR (Chi) ở hồ sơ tỉnh tự vận hành `HT-A`.

**Tác nhân phụ.** Mimir, `dh-connect` (phiên bản cấu hình đẩy xuống etcd), Strimzi exporter, PH-10 (màn độ trễ tiêu thụ).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-036, 037, 038.

**Truy vết.** REQ-13; quy trình BP-07; LGC-HUB-005, LGC-HUB-006, LGC-APIM-023; LGC-APIM-024; LGC-APIM-025.

**Tiền điều kiện.** APISIX bật plugin `prometheus`; `dh-connect` xuất `dh_connect_config_revision`; Strimzi exporter hoạt động; Lan có `PERM-13-dashboard`.

**Kích hoạt.** Lan mở UI-13-04 (hai tab Gateway và Kafka), hoặc bấm liên kết từ bảng PH-10.

**Đảm bảo tối thiểu.** PH-13 chỉ đọc chỉ số, không gọi Admin API của APISIX; chỉ số thiếu hiện "Chưa có dữ liệu".

**Đảm bảo thành công.** Lan biết nút nào lệch cấu hình từ lúc nào, nút nào sắp quá tải và cụm Kafka có thiếu bản sao không.

**Luồng chính.**

1. Lan mở UI-13-04, tab "Gateway"; UI gọi API-13-011 lấy danh sách nút.
2. Hệ thống kiểm tra quyền.
3. Hệ thống lấy theo từng nút: trạng thái (Tốt, Lệch cấu hình, Mất kết nối etcd, Lỗi), phiên bản cấu hình đang áp dụng so với phiên bản mới nhất `dh-connect` đã đẩy, thời điểm đồng bộ gần nhất, số kết nối, thời gian chạy, phiên bản APISIX.
4. Lan thấy nút `gw-02` ở "Lệch cấu hình" (phiên bản 1.204 so với 1.206, lệch từ 10:02). Lệch quá 5 phút thì luật chuẩn `gateway-config-skew` phát cảnh báo Nghiêm trọng (UC-13-27).
5. Lan bấm `gw-02`; UI gọi API-13-012 (số route đang nạp, lỗi đồng bộ gần nhất, plugin đang bật) và API-13-013 (CPU, bộ nhớ, kết nối đang xử lý và đang chờ, tỷ lệ dùng vùng nhớ dùng chung, độ trễ thêm p50, p95, p99, số `5xx` do gateway).
6. Hệ thống so p95 với SLO 50 ms và đánh dấu vượt; ví dụ p95 của `gw-02` là 62 ms nên biểu đồ có vạch SLO và nhãn "Vượt SLO"; không có mục Java heap vì APISIX không chạy JVM.
7. Lan mở tab "Kafka"; UI gọi API-13-014. Hệ thống trả theo broker CPU, bộ nhớ, đĩa, thông lượng vào ra và theo cụm số phân vùng thiếu bản sao, dưới số bản sao tối thiểu, lag tổng của nhóm tiêu thụ data plane, số topic, số phân vùng; UI có liên kết sang màn độ trễ tiêu thụ của PH-10.

**Luồng thay thế.**

- **3a. Nút mới khởi động.** UI hiện "Mới khởi động" cho tới khi có đủ mẫu.
- **7a. Hồ sơ `HT-B` (cụm Kafka dùng chung).** Chi chỉ thấy bản rút gọn theo tenant (lag và lưu lượng của topic thuộc `T68`), không có chỉ số broker.
- **7b. Cụm ở site DR chưa hoạt động.** UI hiện "Site DR chờ".
- **3b. Hồ sơ cloud dùng chung.** Phiên bản nền tảng gateway thuộc nhà cung cấp; PH-13 chỉ hiển thị trạng thái.

**Luồng ngoại lệ.**

- **E1. Nút không tồn tại (bước 5).** ERR-13-001 (404): "Không tìm thấy nút gateway gw-09. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E2. Mimir không khả dụng (bước 3, 5, 7).** ERR-13-014 (503): "Dịch vụ Mimir tạm thời không khả dụng. Thử lại sau."
- **E3. Khoảng thời gian không hợp lệ (bước 5, 7).** ERR-13-004 (400): "Cần chọn khoảng thời gian hợp lệ (từ trước đến)."
- **E4. Người dùng tenant xem chỉ số broker của cụm dùng chung (bước 7).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E5. Thiếu chỉ số của một nút hoặc broker (bước 3, 7).** Nút hoặc broker đó hiện "Chưa có dữ liệu".

**Quy tắc áp dụng.** BR-13-016, 030.

**Màn hình, API.** UI-13-04; API-13-011, 012, 013, 014.
:::

### 6.24. UC-13-24 · Xem hoạt động nghiệp vụ và bảng điều khiển an ninh

::: dac-ta
**Mục tiêu.** Lãnh đạo thấy hoạt động trao đổi dữ liệu theo góc nhìn nghiệp vụ (đơn vị nào dùng trục nhiều nhất, đơn vị nào chưa kết nối) để quyết định mà không cần đọc chỉ số kỹ thuật, và cán bộ ATTT thấy tình hình an ninh trong màn hình đầu tiên mở ra mỗi ngày.

**Tác nhân chính.** ROLE-VIEWER (Phúc, phần nghiệp vụ), ROLE-SECURITY_OFFICER (Dũng, phần an ninh).

**Tác nhân phụ.** ClickHouse, PH-01 (HTTT, tổ chức), PH-14 (dịch vụ quốc gia), PH-10 (số sự kiện), Keycloak, OPA, Loki, bảng cảnh báo an ninh.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-039, 040.

**Truy vết.** REQ-13; quy trình BP-07; CMP-LAW-09.

**Tiền điều kiện.** Phúc có `PERM-13-dashboard`; Dũng có `PERM-13-security`; PH-01 cung cấp danh sách HTTT và tổ chức; log an ninh vào `T68-security`.

**Kích hoạt.** Phúc mở UI-13-05; Dũng mở UI-13-06.

**Đảm bảo tối thiểu.** Bảng nghiệp vụ chỉ có số lượng, không có nội dung dữ liệu; bảng an ninh chỉ hiện cho người có quyền riêng (Phúc không xem được).

**Đảm bảo thành công.** Phúc có thẻ, xu hướng, xếp hạng đơn vị và dịch vụ; Dũng thấy bất thường (nếu có) ngay trong màn hình đầu.

**Luồng chính.**

1. Phúc mở UI-13-05, khoảng mặc định 30 ngày, `groupBy = ORG`; UI gọi API-13-015.
2. Hệ thống kiểm tra quyền và khoảng thời gian, rồi tổng hợp từ ClickHouse theo giờ: tổng lượt trao đổi theo ngày, tháng; theo tổ chức (nối mã HTTT với tổ chức qua PH-01); theo dịch vụ API; theo dịch vụ quốc gia (PH-14) và số sự kiện (PH-10).
3. Hệ thống tính số HTTT đã kết nối trên tổng số (ví dụ 164 trên 200, KPI-01) và danh sách HTTT chưa có lượt gọi trong khoảng.
4. UI hiện thẻ, biểu đồ xu hướng, bảng xếp hạng đơn vị và dịch vụ; Phúc thấy 36 HTTT chưa kết nối và dùng danh sách đó để nhắc các đơn vị.
5. Dũng mở UI-13-06; UI gọi API-13-016; hệ thống kiểm tra `PERM-13-security` hoặc `PERM-13-audit-read`.
6. Hệ thống lấy: số đăng nhập thất bại và thành công theo thời gian (Keycloak), số lượt bị từ chối ở OPA và APISIX, số lượt WAF chặn, số bản ghi `PII.REVEAL` và xuất lớn từ kiểm toán, số phiên liên tenant, số cảnh báo an ninh theo mức và trạng thái; kèm kết quả quét log gần nhất (UC-13-02) và trạng thái chuỗi kiểm toán (`OK` hoặc `SUSPECT`, lần kiểm tra cuối, neo cuối).
7. UI hiển thị thẻ, biểu đồ, bảng cảnh báo; chuỗi `SUSPECT` hiện dải đỏ nổi bật.

**Luồng thay thế.**

- **2a. PH-01 không phản hồi.** Hệ thống dùng bản sao danh sách HTTT gần nhất (tối đa 24 giờ) và ghi chú thời điểm bản sao.
- **2b. Lãnh đạo cấp tỉnh.** Chỉ thấy tenant của mình.
- **6a. Tenant chưa có SIEM.** Bảng an ninh hiển thị gợi ý bật SIEM tối thiểu (UC-13-36).
- **6b. Kiểm toán viên.** Chỉ thấy phần kiểm toán và trạng thái chuỗi.

**Luồng ngoại lệ.**

- **E1. PH-01 hoặc ClickHouse không khả dụng (bước 2).** ERR-13-014 (503); phần liên quan hiện "Dịch vụ ClickHouse tạm thời không khả dụng. Thử lại sau."
- **E2. Thiếu dữ liệu (bước 2, 6).** UI hiện "Chưa có dữ liệu" (BR-13-016).
- **E3. Khoảng thời gian sai (bước 1).** ERR-13-004 (400): "Cần chọn khoảng thời gian hợp lệ (từ trước đến)."
- **E4. Phúc mở UI-13-06 khi thiếu `PERM-13-security` và `PERM-13-audit-read` (bước 5).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E5. Loki hoặc PostgreSQL không khả dụng (bước 6).** Panel liên quan hiện ERR-13-014; các phần còn lại vẫn hiển thị.

**Quy tắc áp dụng.** BR-13-016, 030.

**Màn hình, API.** UI-13-05, 06; API-13-015, 016.
:::

### 6.25. UC-13-25 · Quản lý bộ dashboard theo tenant

::: dac-ta
**Mục tiêu.** Mỗi tenant có bộ dashboard Grafana chuẩn đúng phiên bản, cách ly theo tổ chức, khai báo bằng mã nên tái lập được khi khởi tạo hoặc nâng cấp; tỉnh vẫn thêm được dashboard riêng mà không sửa được bộ chuẩn.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang), ROLE-PLATFORM_ADMIN (Hà).

**Tác nhân phụ.** Grafana, kho Git cấu hình (thư mục dashboard chuẩn), PH-20 (gọi qua UC-13-40 khi khởi tạo tenant).

**Mức ưu tiên.** S.

**FR hiện thực.** FR-13-041.

**Truy vết.** REQ-13; quy trình BP-07.

**Tiền điều kiện.** Giang có `PERM-13-admin`; Grafana chạy với nguồn dữ liệu Mimir, Loki, Tempo, ClickHouse theo tổ chức; tenant không tạm ngừng.

**Kích hoạt.** Khởi tạo tenant; nền tảng phát hành phiên bản dashboard mới; Giang bấm "Đồng bộ lại" ở UI-13-17.

**Đảm bảo tối thiểu.** Bộ chuẩn chỉ-đọc, nguồn dữ liệu cố định theo tenant; dashboard riêng của tỉnh không bị ghi đè.

**Đảm bảo thành công.** Tổ chức Grafana của `T68` có bộ `std` đúng phiên bản; bản ghi `DASHBOARDSET.SYNC` nằm trong chuỗi.

**Luồng chính.**

1. Giang mở tab "Bộ dashboard" ở UI-13-17; UI gọi API-13-017 và hiện bộ `std`, phiên bản 1.8.0, đồng bộ lúc 08:00 ngày 26/11/2026, trạng thái `OK`, tổ chức Grafana của `T68`.
2. Nền tảng vừa phát hành phiên bản 1.9.0. Giang bấm "Đồng bộ lại"; UI gọi `POST /dashboard-sets/std:sync` (API-13-018) kèm `Idempotency-Key`.
3. Hệ thống kiểm tra quyền, tenant không tạm ngừng và JSON dashboard hợp lệ.
4. Hệ thống tạo tổ chức Grafana của `T68` nếu chưa có, nạp bộ chuẩn ở chế độ chỉ-đọc (provisioning) vào thư mục "Chuẩn" và cố định tiêu đề nguồn dữ liệu theo tenant; trả `202`.
5. Hệ thống ghi phiên bản, thời điểm đồng bộ và bản ghi kiểm toán `DASHBOARDSET.SYNC`.
6. Giang thấy trạng thái chuyển thành 1.9.0; Giang thêm dashboard riêng vào thư mục "Riêng của tỉnh" bằng Grafana, PH-13 không ghi đè.

**Luồng thay thế.**

- **2a. Khởi tạo tenant mới.** Đồng bộ chạy tự động trong UC-13-40, không cần người bấm.
- **6a. Nâng cấp bộ chuẩn.** Không xóa dashboard riêng của tỉnh.

**Luồng ngoại lệ.**

- **E1. Bộ dashboard không hợp lệ (bước 3).** ERR-13-035 (422): "Bộ dashboard không hợp lệ: thiếu nguồn dữ liệu Tempo."
- **E2. Grafana không khả dụng (bước 4).** ERR-13-014 (503): "Dịch vụ Grafana tạm thời không khả dụng. Thử lại sau."
- **E3. Thiếu quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E4. Tenant đang tạm ngừng (bước 2).** ERR-13-016 (423): "Tenant đang tạm ngừng; chỉ xem được, chưa thay đổi được cấu hình."

**Quy tắc áp dụng.** BR-13-006, 027, 032.

**Màn hình, API.** UI-13-17 (tab Bộ dashboard); API-13-017, 018.
:::

### 6.26. UC-13-26 · Tạo luật cảnh báo kèm runbook và chạy thử

::: dac-ta
**Mục tiêu.** Vận hành định nghĩa điều kiện phát cảnh báo của tenant, bắt buộc kèm runbook năm mục để người trực lúc nửa đêm biết cảnh báo nghĩa là gì và xử lý ra sao, và chạy thử luật trên dữ liệu lịch sử để biết nó sẽ phát bao nhiêu lần trước khi tin vào nó.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang), ROLE-TENANT_OPERATOR (Chi).

**Tác nhân phụ.** Ruler của Mimir và Loki, Alertmanager.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-042.

**Truy vết.** REQ-13; quy trình BP-07; ADR-011; KPI-15.

**Tiền điều kiện.** Giang có `PERM-13-alert-admin`; tenant `T68` không tạm ngừng; số luật của tenant chưa chạm hạn mức (mặc định 500).

**Kích hoạt.** Giang bấm "+ Tạo luật" ở UI-13-11; hoặc sửa, tắt, bật, ngừng dùng, chạy thử một luật.

**Đảm bảo tối thiểu.** Không lưu được luật thiếu runbook hoặc biểu thức sai; luật chuẩn của nền tảng không bị sửa (BR-13-032).

**Đảm bảo thành công.** Luật `ACTIVE` ở Ruler trong vòng 1 phút, runbook gắn với luật, người tạo biết số lần luật sẽ phát.

**Luồng chính.**

1. Giang bấm "+ Tạo luật" ở UI-13-11 và nhập mã `api-loi-cao-dvc`, tên "Tỷ lệ lỗi API cổng DVC vượt 5%", loại `METRIC`, biểu thức PromQL, thời gian duy trì 300 giây, mức `CRITICAL`, triệu chứng "HTTT cổng DVC không gọi được API tra cứu", nhóm nhận `truc-van-hanh`, và chọn runbook `rb-api-loi-cao` (năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên).
2. Hệ thống kiểm tra mã theo mẫu `^[a-z][a-z0-9-]{2,62}$` và chưa dùng, kể cả cho luật đã ngừng dùng.
3. Hệ thống phân tích biểu thức PromQL hoặc LogQL, ép nhãn tenant và từ chối biểu thức sai.
4. Hệ thống kiểm tra runbook có đủ năm mục không rỗng (mỗi mục từ 10 ký tự) và, với mức `CRITICAL`, có mô tả triệu chứng người dùng.
5. Hệ thống kiểm tra số luật của tenant chưa vượt hạn mức và chu kỳ đánh giá từ 30 giây.
6. Hệ thống lưu luật `ACTIVE` (API-13-036 trả `201` kèm `Location` và `ETag`), ghi `ALERT.RULE.CREATE`, phát EVT-13-10 và nạp vào Ruler trong tối đa 60 giây.
7. Giang bấm "Chạy thử"; UI gọi API-13-039. Hệ thống chạy biểu thức trên 7 ngày dữ liệu gần nhất và trả `fires` = 3, `firingSeconds` = 1.260, `periods[]` và `tooSensitive = false`.
8. Giang thấy luật chỉ phát 3 lần trong 7 ngày nên giữ nguyên ngưỡng.

**Luồng thay thế.**

- **1a. Tạo từ luật mẫu.** Giang nhân bản một luật chuẩn (UC-13-27) thành luật riêng với ngưỡng khác.
- **7a. Luật quá nhạy.** Chạy thử cho thấy hơn 20 lần phát trong 7 ngày: UI hiện cảnh báo "ngưỡng quá nhạy" (không chặn lưu) và Giang chỉnh ngưỡng (API-13-038) hoặc tắt luật (API-13-040).
- **8a. Tắt hoặc ngừng dùng luật.** Cần lý do; tắt thì đóng mọi cảnh báo đang mở của luật (ghi `ALERT.RULE.DISABLE`, `ALERT.RULE.RETIRE`); luật chuẩn của nền tảng chỉ xem, không sửa, không tắt.

**Luồng ngoại lệ.**

- **E1. Thiếu runbook hoặc runbook thiếu mục (bước 4).** ERR-13-017 (422): "Luật cảnh báo phải có runbook đủ năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên."
- **E2. Biểu thức sai (bước 3).** ERR-13-018 (422): "Biểu thức luật không hợp lệ: thiếu dấu ngoặc đóng ở vị trí 61."
- **E3. Mã đã dùng (bước 2).** ERR-13-002 (409): "Mã api-loi-cao-dvc đã được dùng, kể cả cho đối tượng đã ngừng dùng. Chọn mã khác."
- **E4. Mức `CRITICAL` thiếu triệu chứng, hoặc chu kỳ ngoài miền (bước 4, 5).** ERR-13-003 (400): "Dữ liệu gửi lên không hợp lệ." kèm "Luật mức Nghiêm trọng cần mô tả triệu chứng người dùng." (BR-13-009).
- **E5. Sửa hoặc tắt luật chuẩn của nền tảng (bước 8a).** ERR-13-019 (403): "Luật chuẩn của nền tảng không sửa hoặc tắt được. Bạn có thể tạo luật riêng."
- **E6. Vượt hạn mức luật (bước 5).** ERR-13-041 (422): "Hạn mức số luật cảnh báo vượt trần của nền tảng (500)."
- **E7. Tắt hoặc ngừng dùng thiếu lý do (bước 8a).** ERR-13-008 (400): "Thao tác này cần nhập lý do từ 10 đến 500 ký tự."
- **E8. Sai phiên bản khi sửa.** ERR-13-007 (412): "Dữ liệu đã được người khác sửa. Tải lại để xem phiên bản mới nhất."

**Quy tắc áp dụng.** BR-13-008, 009, 031, 032.

**Màn hình, API.** UI-13-11; API-13-035…044.
:::

### 6.27. UC-13-27 · Phát hành bộ luật cảnh báo chuẩn của nền tảng

::: dac-ta
**Mục tiêu.** Mọi tenant có sẵn bộ luật cảnh báo cốt lõi thiết kế theo SLO và các sự cố hạ tầng đã biết, mỗi luật có runbook, nên tenant mới có giám sát đủ dùng ngay ngày đầu mà không phải tự viết luật.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà).

**Tác nhân phụ.** Kho Git `dh-platform-rules`, hệ thống CI, người duyệt thứ hai, Argo CD, Ruler, ROLE-TENANT_ADMIN (Giang, người xem), PH-19 (đóng góp luật thanh toán).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-043.

**Truy vết.** REQ-13; quy trình BP-07; LGC-PAY-009; KPI-03, KPI-04, KPI-15.

**Tiền điều kiện.** Kho Git có tệp luật, runbook và đã qua kiểm tra CI; Argo CD đồng bộ; Hà có quyền hợp nhất vào nhánh chính của kho luật.

**Kích hoạt.** Hà hợp nhất thay đổi luật chuẩn vào nhánh chính; tenant mới được khởi tạo (UC-13-40).

**Đảm bảo tối thiểu.** Tenant không tắt, không sửa được luật chuẩn; luật chỉ dựa trên mức dùng tài nguyên thuần (CPU, bộ nhớ) không được xếp Nghiêm trọng (BR-13-009).

**Đảm bảo thành công.** Luật chuẩn ở Ruler khớp phiên bản Git; mọi tenant xem được từng luật, biểu thức, runbook và lịch sử phát.

**Luồng chính.**

1. Hà đề xuất sửa runbook của luật chuẩn `slo-data-plane-burn-fast` bằng yêu cầu hợp nhất ở kho Git. CI kiểm tra mọi luật có runbook đủ năm mục, biểu thức hợp lệ, mức độ hợp lệ.
2. Người thứ hai duyệt hợp nhất (bốn mắt theo quy trình Git).
3. Argo CD áp luật vào Ruler: luật hạ tầng ở tổ chức `platform`; luật data plane nhân bản cho mỗi tenant bằng khuôn có nhãn `tenant`.
4. PH-13 đồng bộ bảng `alert_rule` với `scope = PLATFORM`, trạng thái chỉ-đọc; ghi `ALERT.RULE.UPDATE` với chủ thể `system:argocd` và phát EVT-13-10.
5. Giang mở UI-13-11; UI gọi `GET /alert-rules?scope=PLATFORM` (API-13-035) và hiện 26 luật chuẩn; Giang bấm một luật để xem biểu thức, runbook, lịch sử phát (API-13-037).
6. Giang cần ngưỡng khác cho độ trễ gateway nên nhân bản `slo-gateway-latency` thành luật riêng `slo-gateway-latency-t68` với ngưỡng 80 ms (UC-13-26); luật chuẩn vẫn chạy song song.

**Luồng thay thế.**

- **1a. PH-19 đóng góp luật.** Luật `payment-provider-connection-error` (tỷ lệ lỗi kết nối tới nhà cung cấp thanh toán lớn hơn 5% trong 5 phút, Nghiêm trọng) dùng chỉ số do PH-19 xuất.
- **3a. Tenant mới khởi tạo.** Luật chuẩn được nhân bản cho tenant trong UC-13-40.

**Luồng ngoại lệ.**

- **E1. Tenant cố sửa hoặc tắt luật chuẩn (bước 6).** ERR-13-019 (403): "Luật chuẩn của nền tảng không sửa hoặc tắt được. Bạn có thể tạo luật riêng."
- **E2. Ruler nạp luật lỗi (bước 3).** Hệ thống giữ phiên bản luật trước; ERR-13-119 hiển thị cho Hà ở UI-13-11 và phát cảnh báo mức Cảnh báo: "Luật slo-data-plane-burn-fast đánh giá lỗi: biểu thức hết thời gian chờ."
- **E3. Luật chuẩn thiếu runbook hoặc xếp Nghiêm trọng chỉ vì mức dùng tài nguyên (bước 1).** CI chặn hợp nhất; ERR-13-017 ở CI: "Luật cảnh báo phải có runbook đủ năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên."

**Quy tắc áp dụng.** BR-13-008, 009, 032.

**Màn hình, API.** UI-13-11 (danh sách luật chuẩn, chỉ xem); API-13-035, 037.
:::

### 6.28. UC-13-28 · Từ điều kiện bất thường đến thông báo tới người trực

::: dac-ta
**Mục tiêu.** Người trực chỉ nhận cảnh báo khi điều kiện đã duy trì đủ lâu, mỗi nguyên nhân chỉ một thông báo, đúng người theo lịch trực, qua ít nhất hai đường độc lập với mức Nghiêm trọng, và nếu không ai nhận trong 15 phút thì cấp trên được gọi; nhờ đó không cảnh báo Nghiêm trọng nào bị bỏ qua.

**Tác nhân chính.** Ruler (Mimir, Loki), Alertmanager và `dh-platform` (hệ thống); người nhận là ROLE-TENANT_OPERATOR (Chi, người trực).

**Tác nhân phụ.** Dịch vụ gửi thư điện tử và SMS của PH-18 (IF-09), PH-18 (nhận sự kiện), lịch trực và kênh của nhóm nhận (UC-13-30).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-044, 045, 046.

**Truy vết.** REQ-13; quy trình BP-07; LGC-PAY-009; KPI-15.

**Tiền điều kiện.** Luật `ACTIVE` đã nạp ở Ruler (UC-13-26, 27); Alertmanager ba bản sao chạy; nhóm nhận của luật có lịch trực và kênh (UC-13-30); PH-18 sẵn sàng gửi thư và SMS.

**Kích hoạt.** Chu kỳ đánh giá luật của từng luật (mặc định 30 giây, `13.alert.eval-interval-seconds`).

**Đảm bảo tối thiểu.** Hệ thống giám sát lỗi không làm data plane lỗi (BR-13-015); kênh chính hỏng thì có kênh dự phòng độc lập, cảnh báo vẫn hiện ở bảng điều khiển.

**Đảm bảo thành công.** Cảnh báo `FIRING` tới người trực trong 60 giây (p95) kể từ khi `FIRING`; chưa xác nhận sau 15 phút thì leo thang đúng cấp; điều kiện hết thì cảnh báo tự đóng.

**Luồng chính.**

1. Lúc 14:03 API `cong-dan.tra-cuu` bắt đầu lỗi. Ruler đánh giá luật `api-loi-cao-dvc` mỗi 30 giây; điều kiện thỏa nên cảnh báo vào trạng thái chờ (`pending`), chưa gửi.
2. Điều kiện thỏa liên tục hết thời gian duy trì 300 giây, lúc 14:08 cảnh báo thành `FIRING`; Ruler gửi tới Alertmanager kèm nhãn `tenant`, `rule_code`, `severity`, `group_key` và chú thích `summary`, `symptom`, `runbook_code`.
3. Alertmanager gom cảnh báo cùng `tenant` và `group_key` trong 30 giây (`group_wait`): 20 pod cùng một lỗi thành một nhóm; không gửi lại cảnh báo đang mở trước `repeat_interval` (4 giờ với Nghiêm trọng, 24 giờ với Cảnh báo); áp luật ức chế cảnh báo con.
4. Alertmanager gọi webhook `dh-platform` (API-13-090, mTLS). `dh-platform` tạo bản ghi `alert` `FIRING` với `fingerprint`, `group_key` và phát EVT-13-01.
5. `dh-platform` xác định người nhận cấp 1 từ lịch trực nhóm `truc-van-hanh` tại 14:08: Chi.
6. Hệ thống chọn kênh theo mức: Nghiêm trọng gửi SMS, thư điện tử và nhắn tin trong ứng dụng cùng lúc qua dịch vụ gửi của PH-18; thư và SMS chỉ chứa mã cảnh báo, mức, tóm tắt và liên kết, không chứa dữ liệu (FR-00-062); mỗi lượt gửi ghi ở `alert_notification`.
7. Lúc 14:08 và 41 giây Chi nhận SMS, đạt mục tiêu trong 60 giây.
8. Chi chưa xác nhận. Lúc 14:23 hệ thống leo thang lên cấp 2 (Giang) và lúc 14:38 lên cấp 3 (Hà), ghi `escalation_level` và phát EVT-13-03 (BR-13-022).
9. Chi xác nhận ở UC-13-29; hệ thống dừng bộ đếm leo thang và ngừng gửi lại.
10. Khi điều kiện hết liên tục 5 phút, Ruler báo "đã giải quyết"; `dh-platform` đóng cảnh báo `RESOLVED` với `resolution = AUTO` và phát EVT-13-02.

**Luồng thay thế.**

- **3a. Cảnh báo bão (hơn 50 cảnh báo mới trong 5 phút).** Alertmanager gom thành một thông báo tổng hợp kèm số lượng và nhóm lớn nhất.
- **3b. Cảnh báo cha đang `FIRING`** (ví dụ `component-down`). Alertmanager ức chế cảnh báo con cùng `group_key` ở mức thấp hơn.
- **5a. Tenant chưa có lịch trực.** Hệ thống gửi tới nhóm TA mặc định và hiện nhắc cấu hình ở UI-13-12.
- **6a. Mức Cảnh báo hoặc Thông tin.** Mức Cảnh báo gửi thư và trong ứng dụng, chỉ trong giờ hành chính (BR-13-028); mức Thông tin chỉ hiển thị trong ứng dụng.
- **10a. Luật bị tắt hoặc ngừng dùng.** Mọi cảnh báo đang mở của luật được đóng tự động.

**Luồng ngoại lệ.**

- **E1. Ruler không đánh giá được luật (bước 1).** ERR-13-119 hiển thị ở UI-13-11 cho TA, PA: "Luật api-loi-cao-dvc đánh giá lỗi: hết thời gian truy vấn." Hệ thống đếm `dh_alert_eval_failures_total` và phát cảnh báo `rule-eval-failed`.
- **E2. Alertmanager không nhận (bước 2).** Ruler thử lại; quá 2 phút thì luật `monitoring-down` (UC-13-31) phát cảnh báo qua kênh độc lập.
- **E3. Webhook tới `dh-platform` thất bại (bước 4).** Alertmanager thử lại giãn dần; mức Nghiêm trọng vẫn được gửi theo kênh trực tiếp của Alertmanager; ERR-13-014.
- **E4. Kênh gửi chính thất bại (bước 6).** Hệ thống thử lại sau 30 giây, 2 phút, 10 phút rồi chuyển kênh dự phòng; ERR-13-120 hiển thị cho PA, TA ở UI-13-12: "Gửi thông báo qua kênh sms-truc thất bại: nhà mạng từ chối."
- **E5. Leo thang hết cấp mà chưa ai xác nhận (bước 8).** ERR-13-121 gửi PA, TA qua kênh độc lập: "Cảnh báo AL-20261126-0412 đã leo thang hết cấp mà chưa ai xác nhận."
- **E6. Dịch vụ gửi của PH-18 không khả dụng (bước 6).** ERR-13-014 (503): "Dịch vụ PH-18 tạm thời không khả dụng. Thử lại sau."; hệ thống chuyển sang webhook trực tiếp từ Alertmanager.
- **E7. Alertmanager mất đồng bộ giữa các bản sao (bước 3).** Cảnh báo có thể bị gửi trùng trong thời gian ngắn; luật `monitoring-down` theo dõi.

**Quy tắc áp dụng.** BR-13-008, 009, 022, 028.

**Màn hình, API.** UI-13-10 (nhóm cảnh báo, trạng thái lượt gửi), UI-13-12; API-13-030, 090.
:::

### 6.29. UC-13-29 · Xử lý cảnh báo: xác nhận, đã xử lý, tạm ẩn

::: dac-ta
**Mục tiêu.** Người trực nhận, xử lý và ghi lại kết quả một cảnh báo ngay trên một màn hình có sẵn runbook, thay vì tìm tài liệu nơi khác, và tạm ẩn có kiểm soát khi cảnh báo biết trước.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi); cũng thực hiện bởi PA, PO, TA, SO có `PERM-13-alert-ack`.

**Tác nhân phụ.** Alertmanager (silence), UC-13-17 và UC-13-18 (liên kết chẩn đoán).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-047.

**Truy vết.** REQ-13; quy trình BP-07; KPI-16.

**Tiền điều kiện.** Chi có `PERM-13-alert-ack`; có cảnh báo `FIRING` hoặc `ACKNOWLEDGED`.

**Kích hoạt.** Chi mở "Giám sát › Cảnh báo" (UI-13-10) và bấm một cảnh báo, hoặc nhấn liên kết trong thông báo.

**Đảm bảo tối thiểu.** Cảnh báo đã đóng không bị thao tác lại; hai người cùng xử lý thì người lưu sau được báo xung đột chứ không ghi đè.

**Đảm bảo thành công.** Cảnh báo có người nhận, có nguyên nhân và hành động khi đóng, hoặc được tạm ẩn có thời hạn và lý do; MTTA, MTTR cập nhật.

**Luồng chính.**

1. Lúc 14:09 Chi nhấn liên kết trong SMS và mở UI-13-10: giao diện hiện ngay mô tả, biểu thức, giá trị hiện tại (tỷ lệ lỗi 11,3%), biểu đồ liên quan và runbook năm mục, không cần mở tab khác (API-13-031).
2. Chi bấm "Xác nhận tiếp nhận"; UI gọi API-13-032 kèm `If-Match`. Hệ thống kiểm tra trạng thái hợp lệ và quyền, ghi `ALERT.ACK`, chuyển `ACKNOWLEDGED` và dừng leo thang.
3. Chi bấm liên kết nhanh "Mở trace lỗi" (UC-13-18) và "Mở log" (UC-13-17) và thấy nguyên nhân: chứng thư mTLS của `HT-TUPHAP` hết hạn.
4. Lúc 14:40, sau khi `HT-TUPHAP` thay chứng thư, Chi bấm "Đánh dấu đã xử lý" và nhập nguyên nhân "Chứng thư mTLS của HT-TUPHAP hết hạn", hành động "HT-TUPHAP thay chứng thư mới, đã kiểm tra lại API" và kết quả `EXTERNAL`. UI gọi API-13-033; hệ thống chuyển `RESOLVED` với `resolution = MANUAL`, ghi `ALERT.RESOLVE` và phát EVT-13-02.
5. Với một cảnh báo mức Cảnh báo khác do bảo trì Kafka đã lên kế hoạch lúc 22:00, Chi bấm "Tạm ẩn" và nhập thời hạn 2 giờ, lý do "Bảo trì Kafka theo kế hoạch". UI gọi API-13-034; hệ thống kiểm tra thời hạn (tối đa 7 ngày, Nghiêm trọng tối đa 24 giờ), chuyển `SILENCED`, tạo silence ở Alertmanager và ghi `ALERT.SILENCE`.

**Luồng thay thế.**

- **5a. Tạm ẩn hết hạn mà điều kiện còn.** Cảnh báo trở về `FIRING` và được gửi lại.
- **5b. Điều kiện hết khi đang tạm ẩn.** Cảnh báo tự đóng.
- **2a. Xác nhận hàng loạt.** Chi chọn nhiều cảnh báo cùng nhóm ở danh sách và xác nhận một lần (giới hạn số lượng: xem Q13-49).

**Luồng ngoại lệ.**

- **E1. Cảnh báo đã `RESOLVED` hoặc thao tác không áp dụng (bước 2, 4, 5).** ERR-13-020 (409): "Cảnh báo đã ở trạng thái RESOLVED, thao tác này không còn áp dụng."
- **E2. Thiếu nguyên nhân hoặc hành động khi đóng (bước 4).** ERR-13-022 (422): "Cần ghi nguyên nhân và hành động đã thực hiện trước khi đánh dấu đã xử lý."
- **E3. Tạm ẩn thiếu hoặc vượt thời hạn (bước 5).** ERR-13-021 (422): "Tạm ẩn cần thời hạn và lý do; tối đa 7 ngày (24 giờ với cảnh báo Nghiêm trọng)."
- **E4. Hai người cùng xử lý (bước 2, 4).** Người lưu sau nhận ERR-13-007 (412): "Dữ liệu đã được người khác sửa. Tải lại để xem phiên bản mới nhất." và xem lại trạng thái.
- **E5. Thiếu quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-021, 022, 023.

**Màn hình, API.** UI-13-10 (tab Đang mở, chi tiết có runbook); API-13-030, 031, 032, 033, 034.
:::

### 6.30. UC-13-30 · Quản lý lịch trực, nhóm nhận, kênh thông báo

::: dac-ta
**Mục tiêu.** Quản trị khai báo ai trực khi nào, thứ tự leo thang và cảnh báo đi theo kênh nào, và kiểm tra kênh còn gửi được, để không có khoảng trống lúc không có ai trực.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang); cũng thực hiện bởi PA, PO, TO có `PERM-13-alert-admin`.

**Tác nhân phụ.** OpenBao (bí mật của kênh webhook), PH-12 (người dùng trong nhóm), dịch vụ gửi của PH-18.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-048.

**Truy vết.** REQ-13; quy trình BP-07; KPI-15.

**Tiền điều kiện.** Giang có `PERM-13-alert-admin`; người trực đã được gán vào nhóm ở PH-12.

**Kích hoạt.** Giang mở UI-13-12 và tạo hoặc sửa lịch trực, nhóm nhận, kênh.

**Đảm bảo tối thiểu.** Bí mật webhook chỉ ở OpenBao, không ghi vào kiểm toán; kênh đang được nhóm dùng không bị xóa.

**Đảm bảo thành công.** Lịch phủ kín mọi thời điểm, nhóm nhận mức Nghiêm trọng có hai kênh khác loại và một kênh không phụ thuộc hạ tầng của site; hiệu lực ngay cho cảnh báo mới.

**Luồng chính.**

1. Giang khai báo bốn kênh: `email-van-hanh` (`EMAIL`), `sms-truc` (`SMS`, `external = true` vì đi qua nhà mạng), `webhook-chat` (`WEBHOOK`, bí mật đưa vào OpenBao), `inapp` (`INAPP`). UI gọi API-13-049.
2. Giang khai báo lịch `truc-van-hanh`: ca từ 17:00 ngày 01/12/2026 đến 07:30 ngày 02/12/2026, người `u-1204` (Chi), cấp 1; `escalationMinutes` là `[0, 15, 30]`; múi giờ `Asia/Ho_Chi_Minh`. UI gọi API-13-046.
3. Hệ thống kiểm tra lịch phủ kín mọi thời điểm, không có ca chồng lấn, và nhóm nhận của luật Nghiêm trọng có ít nhất hai kênh khác loại, trong đó một kênh `external`.
4. Hệ thống lưu, ghi `ONCALL.UPDATE` và `CHANNEL.UPDATE` (không ghi bí mật); lịch và kênh có hiệu lực ngay cho cảnh báo mới.
5. Giang bấm "Kiểm tra kênh" cho `sms-truc`; UI gọi API-13-051, hệ thống gửi một tin thử tới đích và hiện kết quả "Đạt" kèm chi tiết.

**Luồng thay thế.**

- **3a. Chưa có lịch.** Nhóm nhận mặc định là TA (UC-13-28 bước 5a).
- **4a. Sửa lịch, nhóm, kênh.** UI gọi API-13-047, 050 (`PATCH`) kèm `If-Match`; xem danh sách ở API-13-045, 048.
- **4b. Xóa kênh đang được nhóm nhận dùng.** Bị chặn tới khi Giang gỡ kênh khỏi nhóm.

**Luồng ngoại lệ.**

- **E1. Lịch hở khoảng, chồng ca hoặc nhóm Nghiêm trọng thiếu đường độc lập (bước 3).** ERR-13-034 (422): "Lịch trực chưa có người nhận ở mọi thời điểm, có ca chồng lấn, hoặc nhóm nhận mức Nghiêm trọng chưa có hai kênh độc lập."
- **E2. Kiểm tra kênh thất bại (bước 5).** ERR-13-033 (422): "Kiểm tra kênh sms-truc không thành công: nhà mạng từ chối."
- **E3. Mã đã dùng (bước 1, 2).** ERR-13-002 (409): "Mã truc-van-hanh đã được dùng, kể cả cho đối tượng đã ngừng dùng. Chọn mã khác."
- **E4. Sai phiên bản khi sửa (bước 4a).** ERR-13-007 (412): "Dữ liệu đã được người khác sửa. Tải lại để xem phiên bản mới nhất."
- **E5. Thiếu quyền (bước 1).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-006, 022, 028, 031.

**Màn hình, API.** UI-13-12; API-13-045…051.
:::

### 6.31. UC-13-31 · Giám sát chính hệ thống giám sát

::: dac-ta
**Mục tiêu.** Phát hiện khi chính hệ thống giám sát hỏng (bộ thu thập bỏ dữ liệu, Ruler không đánh giá, Alertmanager không gửi, kho đầy), vì khi đó nền tảng "im lặng" và người trực tưởng mọi thứ ổn. Nguyên tắc: ai giám sát người giám sát.

**Tác nhân chính.** Luật `Watchdog` và bộ nhận nhịp tim ngoài site (hệ thống); ROLE-PLATFORM_ADMIN (Hà), ROLE-PLATFORM_OPERATOR (Lan) xem trạng thái.

**Tác nhân phụ.** Alertmanager, Mimir, kênh thông báo độc lập (SMS qua nhà mạng).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-049.

**Truy vết.** REQ-13; quy trình BP-07; KPI-15; ADR-011.

**Tiền điều kiện.** Có bộ nhận nhịp tim ngoài hạ tầng của site do nhóm nền tảng vận hành, không phụ thuộc Mimir và Alertmanager của site.

**Kích hoạt.** Chu kỳ 1 phút của luật `Watchdog` và của việc tính trạng thái tự giám sát.

**Đảm bảo tối thiểu.** Không có "im lặng giả": hệ thống giám sát hỏng thì có người được báo qua đường độc lập; chỉ số tự giám sát thiếu hiện "Chưa có dữ liệu" chứ không hiện "Tốt".

**Đảm bảo thành công.** Hà và Lan biết hệ thống giám sát còn đáng tin hay không trong vòng 3 phút kể từ khi nó hỏng.

**Luồng chính.**

1. Luật `Watchdog` luôn thỏa; Alertmanager gửi nó tới bộ nhận nhịp tim ngoài site mỗi phút.
2. `dh-platform` tính trạng thái hệ thống giám sát từ chỉ số tự giám sát (`dh_obs_ingest_samples_total`, `dh_obs_dropped_samples_total`, `dh_alert_eval_failures_total`, `alertmanager_notifications_failed_total`, độ trễ ghi ClickHouse, độ trễ sao WORM, backlog kiểm toán, dung lượng các kho): Tốt, Giảm sút (có bỏ dữ liệu hoặc kho trên 80%), hoặc Lỗi (Ruler hoặc Alertmanager hỏng).
3. Khi kho Loki đạt 85% dung lượng, hệ thống phát cảnh báo mức Cảnh báo (ERR-13-123) và EVT-13-14.
4. Lúc 16:20 Alertmanager hỏng. Quá 3 phút bộ nhận nhịp tim không nhận được nhịp nên phát cảnh báo `monitoring-down` mức Nghiêm trọng qua kênh độc lập tới Hà và Lan: "Hệ thống giám sát có thể đang ngừng, kiểm tra Ruler và Alertmanager."
5. Lan mở UI-13-01 và thấy dải "Hệ thống giám sát: Lỗi" cùng `components[]` (`code`, `status`, `reason`, `since`) từ API-13-053.
6. Alertmanager hồi phục, nhịp tim trở lại, cảnh báo `monitoring-down` tự đóng.

**Luồng thay thế.**

- **1a. Hồ sơ cloud dùng chung.** Nhịp tim đi tới bộ nhận do nhà cung cấp nền tảng vận hành.
- **2a. Kiểm tra tổng hợp (UC-13-04).** Bổ sung góc nhìn từ ngoài cụm, độc lập với chỉ số bên trong.

**Luồng ngoại lệ.**

- **E1. Mất nhịp tim (bước 4).** Cảnh báo Nghiêm trọng qua kênh độc lập như bước 4.
- **E2. Kho đạt 85% dung lượng (bước 3).** ERR-13-123: "Kho Loki đạt 85% dung lượng."
- **E3. Chỉ số tự giám sát thiếu (bước 2).** UI hiện "Chưa có dữ liệu" kèm ERR-13-014: "Dịch vụ Mimir tạm thời không khả dụng. Thử lại sau."
- **E4. Bộ nhận nhịp tim ngoài site cũng hỏng.** Không phát hiện được việc hỏng toàn bộ giám sát; rủi ro này được ghi ở FRS §12.1 và xử lý bằng kiểm tra tổng hợp (UC-13-04) cùng giám sát của nhóm nền tảng.

**Quy tắc áp dụng.** BR-13-015, 016.

**Màn hình, API.** UI-13-01 (dải trạng thái hệ thống giám sát); API-13-053.
:::

### 6.32. UC-13-32 · Xem thống kê hiệu quả cảnh báo

::: dac-ta
**Mục tiêu.** Vận hành biết luật nào phát nhiều, luật nào hay báo nhầm, bao lâu thì có người nhận và xử lý xong, để chỉnh ngưỡng và giảm mệt mỏi cảnh báo; mục tiêu tỷ lệ cảnh báo giả không quá 30% sau 30 ngày chạy.

**Tác nhân chính.** ROLE-TENANT_OPERATOR (Chi), ROLE-TENANT_ADMIN (Giang).

**Tác nhân phụ.** Bảng `alert` ở `pg-core`.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-13-050.

**Truy vết.** REQ-13; quy trình BP-07; KPI-15, KPI-16.

**Tiền điều kiện.** Chi có `PERM-13-dashboard`; có cảnh báo đã đóng trong khoảng và thao tác đóng đã ghi `outcome` (UC-13-29).

**Kích hoạt.** Chi mở tab "Thống kê" ở UI-13-10.

**Đảm bảo tối thiểu.** Luật mới dưới 30 ngày không bị kết luận vội; luật chuẩn chỉ hiện thống kê, không sửa được từ màn này.

**Đảm bảo thành công.** Chi có bảng xếp hạng luật kèm gợi ý và đường tới màn sửa luật.

**Luồng chính.**

1. Chi mở tab "Thống kê" ở UI-13-10; UI gọi API-13-052 với khoảng mặc định 30 ngày.
2. Hệ thống kiểm tra quyền và khoảng thời gian.
3. Hệ thống tính theo luật: số lần phát, số lần leo thang, thời gian xác nhận trung bình (MTTA), thời gian xử lý trung bình (MTTR) và tỷ lệ cảnh báo giả, là tỷ lệ cảnh báo đóng với `outcome = NO_ACTION` hoặc bị tạm ẩn trên tổng số đã đóng.
4. Hệ thống gắn gợi ý: luật có tỷ lệ giả trên 50% thì "Nên xem lại ngưỡng"; luật phát trên 20 lần trong 7 ngày thì "Ngưỡng có thể quá nhạy".
5. UI hiển thị bảng xếp hạng, biểu đồ xu hướng và nút "Sửa luật" (chỉ hiện với người có `PERM-13-alert-admin`); ví dụ luật `api-loi-cao-dvc` phát 9 lần, 6 lần đóng `NO_ACTION`, tỷ lệ giả 67%, MTTA 4 phút, MTTR 38 phút nên có gợi ý "Nên xem lại ngưỡng".
6. Giang bấm "Sửa luật" và chuyển sang UC-13-26 để nâng ngưỡng.

**Luồng thay thế.**

- **3a. Luật chuẩn của nền tảng.** Chỉ hiện thống kê; gợi ý được gửi tới PA thay vì cho sửa tại chỗ.
- **3b. Luật mới dưới 30 ngày.** UI hiện "Chưa đủ dữ liệu".

**Luồng ngoại lệ.**

- **E1. Không có cảnh báo trong khoảng (bước 3).** UI hiện "Chưa có dữ liệu".
- **E2. PostgreSQL không khả dụng (bước 3).** ERR-13-014 (503): "Dịch vụ PostgreSQL tạm thời không khả dụng. Thử lại sau."
- **E3. Khoảng không hợp lệ (bước 2).** ERR-13-004 (400): "Cần chọn khoảng thời gian hợp lệ (từ trước đến)."
- **E4. Thiếu quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-009, 023.

**Màn hình, API.** UI-13-10 (tab Thống kê); API-13-052.
:::

### 6.33. UC-13-33 · Tinh chỉnh bộ luật phát hiện UC-SEC

::: dac-ta
**Mục tiêu.** Cán bộ ATTT tinh chỉnh ngưỡng của bộ 25 luật phát hiện UC-SEC-01…25 trong biên an toàn sau 30 ngày chạy thực tế để giảm cảnh báo nhầm, mà không thể làm mù hệ thống ở những luật bắt buộc.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** ROLE-TENANT_ADMIN (Giang, nhận thông báo), kho Git `dh-platform-rules`, Loki Ruler, Mimir Ruler, bộ phát hiện trên bản ghi kiểm toán.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-051.

**Truy vết.** REQ-13; quy trình ứng cứu sự cố ATTT (D03-07 §8); D03-07 §7.5.

**Tiền điều kiện.** Dũng có `PERM-13-security`; bộ 25 luật đã được nạp khi khởi tạo tenant (UC-13-40) kèm giới hạn nới và cờ `can_disable`; nguồn log tương ứng đã vào `T68-security` hoặc Mimir.

**Kích hoạt.** Dũng mở UI-13-15 và sửa ngưỡng; hoặc nền tảng phát hành phiên bản luật mới.

**Đảm bảo tối thiểu.** Không luật nào bị nới quá 2 lần ngưỡng mặc định; luật mức Nghiêm trọng kiểu "mọi sự kiện" không bị tắt hay đổi ngưỡng (BR-13-025).

**Đảm bảo thành công.** Ngưỡng mới có hiệu lực trong tối đa 60 giây; thay đổi có trong lịch sử kiểm toán với giá trị trước và sau.

**Luồng chính.**

1. Sau 30 ngày chạy, Dũng mở UI-13-15, tab luật; UI gọi API-13-054 và hiện mỗi luật với ngưỡng hiện tại, ngưỡng mặc định, số lần phát 30 ngày và tỷ lệ báo nhầm.
2. Dũng thấy UC-SEC-12 (xuất tổng cộng từ 100.000 dòng mỗi ngày, mức Trung bình) báo nhầm nhiều vì cán bộ thống kê chạy báo cáo tháng; Dũng nới ngưỡng lên 150.000 dòng kèm lý do "Báo cáo tháng của Sở Thống kê cần 150.000 dòng". UI gọi API-13-055 kèm `If-Match`.
3. Hệ thống kiểm tra ngưỡng không nới quá 2 lần mặc định (giới hạn 200.000) và luật cho phép đổi.
4. Hệ thống lưu, ghi `SECURITY.RULE.TUNE` kèm giá trị trước và sau, thông báo Giang và phát EVT-13-10.
5. Luật mới có hiệu lực ở bộ phát hiện trong tối đa 60 giây.

**Luồng thay thế.**

- **2a. Siết ngưỡng (nhạy hơn).** Cho phép tự do trong miền, vẫn cần lý do và vẫn ghi `SECURITY.RULE.TUNE`.
- **2b. Luật mức Nghiêm trọng kiểu "mọi sự kiện"** (ví dụ UC-SEC-04, 09, 18, 20, 23). Không đổi ngưỡng được và không tắt được.
- **5a. Kiểm thử luật.** Mỗi luật có ca kiểm thử sinh sự kiện giả ở D05-01 để xác nhận luật vẫn phát sau khi chỉnh.

**Luồng ngoại lệ.**

- **E1. Ngưỡng ngoài biên hoặc cố tắt luật không được tắt (bước 3).** ERR-13-024 (422): "Ngưỡng này vượt giới hạn nới cho phép (200000) hoặc luật này không được tắt."
- **E2. Thiếu lý do (bước 2).** ERR-13-008 (400): "Thao tác này cần nhập lý do từ 10 đến 500 ký tự."
- **E3. Thiếu quyền hoặc sai phiên bản (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."; ERR-13-007 (412): "Dữ liệu đã được người khác sửa. Tải lại để xem phiên bản mới nhất."
- **E4. Luật không nạp được ở Ruler (bước 5).** Hệ thống giữ phiên bản trước; ERR-13-119: "Luật UC-SEC-12 đánh giá lỗi: biểu thức không hợp lệ."

**Quy tắc áp dụng.** BR-13-006, 025.

**Màn hình, API.** UI-13-15 (tab luật phát hiện); API-13-054, 055.
:::

### 6.34. UC-13-34 · Phát hiện bất thường từ bản ghi kiểm toán

::: dac-ta
**Mục tiêu.** Hành vi lạm dụng quyền hoặc tấn công thể hiện trong chính nhật ký kiểm toán (tra cứu hàng loạt, xem dữ liệu Nhạy cảm hàng loạt, xuất số lượng lớn, hoàn tiền bất thường, truy cập liên tenant, từ chối tăng đột biến) được báo cho cán bộ ATTT trong vòng 5 phút.

**Tác nhân chính.** Bộ phát hiện bất thường của `dh-platform` (hệ thống, chạy mỗi phút); ROLE-SECURITY_OFFICER (Dũng) nhận cảnh báo.

**Tác nhân phụ.** Alertmanager (nhãn `kind=security`), bộ xuất SIEM (UC-13-36), bảng `audit_event`.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-052.

**Truy vết.** REQ-13; quy trình ứng cứu sự cố ATTT (D03-07 §8); UC-SEC-10, UC-SEC-11, UC-SEC-12, UC-SEC-14, UC-SEC-20, UC-SEC-25.

**Tiền điều kiện.** Bản ghi kiểm toán có `action`, `actor_id`, `object_key_hmac`, `after.rowCount` ở thao tác xuất, `occurred_at`; các luật ở UC-13-33 đang bật.

**Kích hoạt.** Chu kỳ 1 phút của bộ phát hiện.

**Đảm bảo tối thiểu.** Bằng chứng đính kèm chỉ là danh sách mã bản ghi, số đếm và khoảng thời gian, không chứa dữ liệu gốc; sự cố hạ tầng của bộ phát hiện không làm bỏ sót cửa sổ nào.

**Đảm bảo thành công.** Mỗi cảnh báo an ninh có bằng chứng liên kết ngược tới bản ghi kiểm toán và được gửi tới Dũng.

**Luồng chính.**

1. Mỗi phút bộ phát hiện chạy truy vấn tổng hợp trên phân vùng nóng của `audit_event` theo từng luật (UC-SEC-10, 11, 12, 14, 20, 25, truy cập Nhạy cảm ngoài giờ, từ chối tăng đột biến).
2. Lúc 10:42 bộ phát hiện thấy HTTT `HT-QLVB` tra cứu 1.240 `object_key_hmac` khác nhau trong 1 giờ, vượt ngưỡng mặc định 500 của UC-SEC-10 (mức Cao).
3. Hệ thống tạo cảnh báo an ninh, gom theo (luật, chủ thể) trong 1 giờ để không sinh nhiều cảnh báo cho cùng một hành vi.
4. Hệ thống đính kèm bằng chứng: tối đa 100 `audit_id`, số đếm 1.240 và khoảng thời gian 09:42 đến 10:42.
5. Hệ thống đẩy cảnh báo qua Alertmanager với nhãn `kind=security` để thông báo Dũng theo UC-13-28 (mức Nghiêm trọng tới SO ngay), đẩy sang SIEM (UC-13-36), phát EVT-13-04 và hiển thị ở UI-13-15 (API-13-056).
6. Dũng nhận thông báo lúc 10:43, tức trong 5 phút kể từ khi hành vi vượt ngưỡng.

**Luồng thay thế.**

- **2a. Luật ngoài giờ hành chính** (ví dụ `PII.REVEAL` hoặc xuất ngoài giờ). Dùng giờ của tenant (`13.office-hours`, múi giờ `Asia/Ho_Chi_Minh`).
- **2b. Luật theo số lần** (ví dụ UC-SEC-11: `PII.REVEAL` từ 20 lần trong 1 giờ của một người). Cùng cách gom và đính kèm bằng chứng.
- **2c. Đứt chuỗi hoặc neo lệch (UC-SEC-20).** Cảnh báo do UC-13-08 phát thẳng, không đi qua truy vấn này.

**Luồng ngoại lệ.**

- **E1. Truy vấn phát hiện lỗi hoặc trễ quá 5 phút (bước 1).** ERR-13-119 hiển thị cho Dũng và PA: "Luật UC-SEC-10 đánh giá lỗi: truy vấn quá thời gian chờ."; hệ thống phát cảnh báo mức Cảnh báo về chính bộ phát hiện.
- **E2. Cơ sở dữ liệu không khả dụng (bước 1).** ERR-13-014; khi hồi phục bộ phát hiện chạy bù từ mốc đã xử lý, không bỏ cửa sổ nào.
- **E3. Bản ghi thiếu trường cần cho luật (bước 1).** Hệ thống bỏ qua bản ghi đó với luật đó và đếm `dh_detect_skipped_total`.

**Quy tắc áp dụng.** BR-13-001, 025.

**Màn hình, API.** UI-13-15 (hộp cảnh báo an ninh); API-13-056.
:::

### 6.35. UC-13-35 · Xử lý cảnh báo an ninh và đề xuất tạm ngừng HTTT

::: dac-ta
**Mục tiêu.** Cán bộ ATTT tiếp nhận, điều tra, kết luận và đóng cảnh báo an ninh với hồ sơ chuẩn, và khi cần thì đề xuất tạm ngừng HTTT liên quan tới đúng nơi quyết định (PH-01), thay vì tự tạm ngừng ngoài phạm vi của PH-13.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** PH-01 (tạm ngừng HTTT, cần `PERM-01-suspend`), ROLE-TENANT_ADMIN (Giang, cấp leo thang), PH-18 (hồ sơ sự cố), SIEM.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-053.

**Truy vết.** REQ-01, REQ-13; quy trình ứng cứu sự cố ATTT (D03-07 §8); UC-SEC-10.

**Tiền điều kiện.** Dũng có `PERM-13-security`; có cảnh báo an ninh `NEW` hoặc `ACKNOWLEDGED` (ví dụ từ UC-13-34).

**Kích hoạt.** Dũng mở UI-13-15 hoặc nhấn liên kết trong thông báo.

**Đảm bảo tối thiểu.** PH-13 chỉ đề xuất, không tự tạm ngừng; việc tạm ngừng do người có `PERM-01-suspend` thực hiện ở PH-01 và được kiểm toán ở PH-01.

**Đảm bảo thành công.** Cảnh báo `CLOSED` với kết luận và ghi chú; đề xuất tạm ngừng có liên kết và kết quả ghi vết; sự cố thật có hồ sơ ứng cứu.

**Luồng chính.**

1. Dũng mở cảnh báo UC-SEC-10 của `HT-QLVB` ở UI-13-15; giao diện hiện luật, nguồn, chủ thể, bằng chứng (liên kết tới bản ghi kiểm toán và log), mức, thời điểm phát hiện và runbook điều tra (API-13-057).
2. Dũng bấm "Tiếp nhận" (API-13-058). Hệ thống chuyển `ACKNOWLEDGED`, ghi người xử lý, dừng leo thang tới Giang và ghi `SECURITY.ALERT.ACK`.
3. Dũng điều tra qua UC-13-12 (lọc `actor = HT-QLVB`), UC-13-17 và UC-13-18, và thấy `HT-QLVB` gọi hàng loạt bằng tài khoản dịch vụ nghi bị lộ.
4. Với cảnh báo mức Cao hoặc Nghiêm trọng, Dũng bấm "Đề xuất tạm ngừng HTTT" (nút không hiện ở mức thấp hơn), chọn `HT-QLVB` và nhập lý do "Tra cứu bất thường 1.240 khóa trong 1 giờ, nghi lộ tài khoản dịch vụ". UI gọi API-13-060; hệ thống kiểm tra HTTT thuộc tenant, ghi lý do, lấy `alertId`, `severity`, `incidentRef` và liên kết sâu `evidenceUrl` từ cảnh báo gốc rồi gửi đề xuất sang PH-01 bằng API-01-089; PH-01 tạo việc khẩn cho SO (xem Q13-12 của FRS, đã chốt 27/11/2026).
5. Người có `PERM-01-suspend` (Giang hoặc Dũng) mở việc ở PH-01 và tạm ngừng `HT-QLVB` bằng thao tác khẩn (FR-01-032), hoặc đóng việc không tạm ngừng; PH-13 chỉ ghi liên kết và kết quả.
6. Dũng đóng cảnh báo (API-13-059) với kết luận `CONFIRMED_INCIDENT` và ghi chú; hệ thống ghi `SECURITY.ALERT.CLOSE`.
7. Kết luận `CONFIRMED_INCIDENT` mở hồ sơ sự cố theo quy trình ứng cứu (D03-07 §8) và gợi ý lập báo cáo (UC-13-37).

**Luồng thay thế.**

- **2a. Cảnh báo Nghiêm trọng chưa tiếp nhận.** Sau 15 phút leo thang tới Giang, sau 30 phút tới Hà (BR-13-022).
- **3a. Cảnh báo cùng luật, cùng chủ thể trong 1 giờ.** Hệ thống cập nhật bằng chứng của cảnh báo cũ thay vì tạo mới.
- **6a. Kết luận `FALSE_POSITIVE` hoặc `ACCEPTED_RISK`.** Dũng ghi chú giải thích; không mở hồ sơ sự cố.

**Luồng ngoại lệ.**

- **E1. Đóng thiếu kết luận (bước 6).** ERR-13-023 (422): "Chọn kết luận (sự cố thật, báo nhầm, chấp nhận rủi ro) trước khi đóng cảnh báo an ninh."
- **E2. Cảnh báo đã đóng (bước 2, 6).** ERR-13-020 (409): "Cảnh báo đã ở trạng thái CLOSED, thao tác này không còn áp dụng."
- **E3. PH-01 không khả dụng khi đề xuất (bước 4).** ERR-13-014 (503): "Dịch vụ PH-01 tạm thời không khả dụng. Thử lại sau."; đề xuất chưa gửi, Dũng thử lại.
- **E4. HTTT không thuộc tenant (bước 4).** ERR-13-001 (404): "Không tìm thấy HTTT {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E5. Thiếu quyền (bước 2).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."
- **E6. Cảnh báo mức thấp hơn Cao (bước 4).** Nút đề xuất ẩn; nếu vẫn gọi API-13-060 thì ERR-13-003 (400): "Chỉ cảnh báo mức Cao hoặc Nghiêm trọng mới đề xuất tạm ngừng HTTT được."; đề xuất chưa gửi.
- **E7. HTTT đã bị tạm ngừng (bước 4).** PH-01 trả ERR-01-048 (409); PH-13 coi đề xuất đã được đáp ứng, không báo lỗi và không thử lại.
- **E8. HTTT không ở trạng thái cho phép tạm ngừng (bước 4).** PH-01 trả ERR-01-005 (409); PH-13 báo Dũng: "HTTT {mã} không ở trạng thái cho phép tạm ngừng."

**Quy tắc áp dụng.** BR-13-022, 024.

**Màn hình, API.** UI-13-15; API-13-056, 057, 058, 059, 060.
:::

### 6.36. UC-13-36 · Đẩy log và cảnh báo an ninh sang SIEM, SOC

::: dac-ta
**Mục tiêu.** SIEM hoặc SOC của tỉnh, quốc gia hay cơ quan chuyên trách nhận được log an ninh, cảnh báo và neo kiểm toán đã lọc dữ liệu cá nhân và chuẩn hóa lược đồ; tỉnh chưa có SIEM vẫn đủ giám sát nhờ gói tối thiểu.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang); cũng thực hiện bởi ROLE-PLATFORM_ADMIN (Hà) có `PERM-13-admin`.

**Tác nhân phụ.** Collector gateway (bộ xuất), SIEM `siem.tinh.gov.vn:6514`, cổng thoát có kiểm soát, OpenBao (chứng thư, bí mật nếu có).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-054.

**Truy vết.** REQ-13; quy trình ứng cứu sự cố ATTT (D03-07 §8); IF-08.

**Tiền điều kiện.** Giang có `PERM-13-admin`; chứng thư TLS của đích được tin cậy; kênh mạng tới đích mở qua cổng thoát có kiểm soát.

**Kích hoạt.** Giang khai báo hoặc bấm "Kiểm tra kết nối" ở UI-13-17; mỗi sự kiện an ninh, cảnh báo hoặc neo mới.

**Đảm bảo tối thiểu.** Không dữ liệu cá nhân hay nội dung Nhạy cảm nào ra khỏi nền tảng (BR-13-034); SIEM ngừng nhận không chặn neo và không làm mất cảnh báo.

**Đảm bảo thành công.** SIEM nhận sự kiện chuẩn hóa trong tối đa 5 phút; neo có `siem_ack_at`.

**Luồng chính.**

1. Giang mở tab "Mục tiêu SIEM" ở UI-13-17, bấm "+ Thêm" và khai `targetCode` `siem-tinh`, `protocol` `SYSLOG_TLS`, `endpoint` `siem.tinh.gov.vn:6514`, `schema` `ECS`, `categories` `["AUTH", "ALERT", "AUDIT_ANCHOR"]`. UI gọi API-13-062 kèm `Idempotency-Key`.
2. Hệ thống kiểm tra địa chỉ hợp lệ, được phép ra ngoài qua cổng thoát, chứng thư hợp lệ; ghi `SIEM.TARGET.UPDATE` (không ghi chứng thư hay bí mật).
3. Giang bấm "Kiểm tra kết nối" (API-13-064); hệ thống gửi một sự kiện thử và hiện "Đạt · 180 ms".
4. Với mỗi sự kiện an ninh, cảnh báo, neo mới, Collector gateway ánh xạ sang trường chuẩn (`event.category`, `event.action`, `user.id`, `source.ip`, `tenant`, `trace_id`), loại trường dữ liệu cá nhân và nội dung Nhạy cảm bằng bộ lọc, rồi gửi qua hàng đợi đĩa tối đa 1 GB.
5. Độ trễ tới SIEM không quá 5 phút; gửi thành công thì hệ thống ghi `siem_ack_at` cho neo (UC-13-06 bước 6).

**Luồng thay thế.**

- **1a. Tỉnh chưa có SIEM** (giả định khoảng 70% tỉnh, GĐ-13-07). Hệ thống bật gói tối thiểu: bảng điều khiển an ninh (UC-13-24), luật UC-SEC trên Loki và Alertmanager, tùy chọn Wazuh, và hiển thị khuyến nghị.
- **1b. Điểm xuất cho cơ quan chuyên trách.** Dùng cùng cơ chế với `purpose = AUTHORITY`; tắt mặc định, bật theo tenant khi có văn bản yêu cầu, sẵn sàng trong 5 ngày làm việc.
- **1c. Nền tảng dùng chung.** SOC của nhà cung cấp nền tảng nhận luồng toàn nền tảng, mỗi tỉnh nhận luồng đã lọc theo tenant.

**Luồng ngoại lệ.**

- **E1. Mục tiêu không hợp lệ hoặc không kết nối được (bước 2, 3).** ERR-13-039 (422): "Mục tiêu SIEM không hợp lệ hoặc không kết nối được: chứng thư không được tin cậy."
- **E2. SIEM không nhận khi đang chạy (bước 4).** Hệ thống giữ hàng đợi và thử lại; ERR-13-122 hiển thị ở UI-13-17: "SIEM siem-tinh không nhận được dữ liệu."; sau 15 phút phát cảnh báo mức Cảnh báo.
- **E3. Hàng đợi đĩa đầy (bước 4).** Hệ thống bỏ sự kiện mức thấp trước, giữ cảnh báo và neo; bỏ bản ghi mức Nghiêm trọng thì phát cảnh báo Nghiêm trọng.
- **E4. Mã đã dùng hoặc thiếu quyền (bước 1).** ERR-13-002 (409): "Mã siem-tinh đã được dùng, kể cả cho đối tượng đã ngừng dùng. Chọn mã khác."; ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-013, 034.

**Màn hình, API.** UI-13-17 (tab Mục tiêu SIEM); API-13-061, 062, 063, 064.
:::

### 6.37. UC-13-37 · Lập báo cáo sự cố và thông báo vi phạm dữ liệu cá nhân

::: dac-ta
**Mục tiêu.** Cán bộ ATTT lập nhanh báo cáo sự cố an ninh mạng và thông báo vi phạm dữ liệu cá nhân từ cảnh báo an ninh, có đếm ngược 72 giờ, để đúng hạn theo luật. Use case thuộc Đợt sau, đặc tả sớm để thiết kế không chặn.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** UC-13-15 (gói bằng chứng đính kèm), PH-18 và quy trình ứng cứu (thu snapshot), ROLE-TENANT_ADMIN (Giang).

**Mức ưu tiên.** C (Đợt sau).

**FR hiện thực.** FR-13-055.

**Truy vết.** REQ-13; quy trình ứng cứu sự cố ATTT (D03-07 §8); CMP-LAW-04, CMP-LAW-05, CMP-LAW-16.

**Tiền điều kiện.** Dũng có `PERM-13-security`; có cảnh báo an ninh `CLOSED` với kết luận `CONFIRMED_INCIDENT` (UC-13-35), hoặc cảnh báo đang điều tra.

**Kích hoạt.** Dũng bấm "Lập báo cáo" ở chi tiết cảnh báo (UI-13-15).

**Đảm bảo tối thiểu.** Báo cáo không chứa dữ liệu cá nhân gốc, chỉ số lượng và loại dữ liệu; việc gửi cơ quan có thẩm quyền do chủ quản thực hiện ngoài hệ thống.

**Đảm bảo thành công.** Báo cáo `FINAL` đúng mẫu, có thời hạn 72 giờ được theo dõi, lưu 5 năm; việc tạo và chốt được ghi kiểm toán.

**Luồng chính.**

1. Dũng chọn loại báo cáo `DLCN_BREACH` và cảnh báo UC-SEC-10 của `HT-QLVB`; UI gọi API-13-065.
2. Hệ thống sinh bản nháp từ mẫu soạn sẵn gồm thời điểm phát hiện, hệ thống và tenant ảnh hưởng, loại dữ liệu và số bản ghi liên quan (từ bằng chứng của cảnh báo), diễn biến, biện pháp tạm thời, đầu mối liên hệ.
3. Dũng chỉnh nội dung, đính kèm gói bằng chứng đã xuất ở UC-13-15 và lưu `DRAFT`.
4. Hệ thống đếm ngược 72 giờ kể từ `detected_at` và nhắc ở mốc 24, 48, 60 giờ (đối tượng nhận nhắc: xem Q13-47).
5. Dũng chốt `FINAL`; UI gọi API-13-066 xem nội dung, `deadlineAt`, trạng thái; hệ thống xuất tệp để chủ quản gửi cơ quan có thẩm quyền.

**Luồng thay thế.**

- **1a. Báo cáo sự cố an ninh mạng.** Dũng chọn loại `CYBER`; luồng giống nhau, không có đếm ngược 72 giờ.
- **3a. Cần thu snapshot, pháp y hạ tầng.** Việc này do quy trình ứng cứu thực hiện; PH-13 chỉ nhận kết quả đính kèm.

**Luồng ngoại lệ.**

- **E1. Cảnh báo chưa có kết luận (bước 2).** Hệ thống vẫn lập bản nháp với dòng "Chưa có kết luận".
- **E2. Báo cáo không tìm thấy (bước 5).** ERR-13-001 (404): "Không tìm thấy báo cáo sự cố {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."
- **E3. Thiếu quyền (bước 1).** ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."

**Quy tắc áp dụng.** BR-13-024.

**Màn hình, API.** UI-13-15 (nút "Lập báo cáo"); API-13-065, 066.
:::

### 6.38. UC-13-38 · PH-16 lấy số liệu tổng hợp

::: dac-ta
**Mục tiêu.** PH-16 có số liệu thô và tổng hợp ổn định (số giao dịch, tỷ lệ thành công, độ trễ, số HTTT kết nối, số API) để tự tính chỉ tiêu chuyển đổi số và báo cáo định kỳ, mà không phải truy cập trực tiếp các kho quan sát.

**Tác nhân chính.** PH-16 (tài khoản máy, scope `obs:metrics-read`).

**Tác nhân phụ.** Mimir, ClickHouse (view vật chất hóa, quy tắc ghi lại).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-056.

**Truy vết.** REQ-13, REQ-16; quy trình BP-07; CMP-LAW-09.

**Tiền điều kiện.** UC-13-01 và UC-13-03 đang thu dữ liệu; PH-16 đã được cấp scope khi triển khai.

**Kích hoạt.** PH-16 gọi API theo lịch của PH-16 (ví dụ 00:30 ngày 01 hằng tháng).

**Đảm bảo tối thiểu.** Truy vấn luôn bị ép tenant từ token; PH-16 không có đường vào kho quan sát.

**Đảm bảo thành công.** PH-16 nhận số liệu của kỳ đã kết thúc kèm `dataThrough`; cùng tham số luôn cho cùng kết quả.

**Luồng chính.**

1. Lúc 00:30 ngày 01/11/2026 PH-16 gọi `GET /metrics/summary` với `period = MONTH`, `asOf = 2026-10-31T23:59:59+07:00` (API-13-068).
2. Hệ thống xác thực scope `obs:metrics-read` và xác định tenant `T68` từ token.
3. Hệ thống tính từ dữ liệu đã chốt (khoảng thời gian đã kết thúc, từ view vật chất hóa và quy tắc ghi lại) nên cùng tham số luôn cho cùng kết quả.
4. Hệ thống ép tenant vào biểu thức, giới hạn bước tối thiểu 1 phút và thời gian chạy 30 giây.
5. Hệ thống trả `200`: `summary` (`transactions` 1.482.300, `successRate` 99,94%, `latencyP95Ms` 187, `connectedSystems` 164, `apis` 212, `events` 96.400), `dataThrough` 23:59:59 ngày 31/10/2026 và `partial = false`.
6. PH-16 gọi thêm `POST /metrics:query` (API-13-067) với `query = sum(dh_api_calls_total)`, `from`, `to` trong tháng 10 và `step = 1h` để vẽ biểu đồ; hệ thống trả chuỗi điểm theo giờ.

**Luồng thay thế.**

- **5a. Khoảng vượt thời hạn lưu chi tiết.** Hệ thống trả phần có (dạng tổng hợp theo giờ hoặc ngày) kèm `partial = true` và `availableFrom`, không báo lỗi.

**Luồng ngoại lệ.**

- **E1. Thiếu scope hoặc truy vấn vượt tenant (bước 2).** ERR-13-044 (403): "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."
- **E2. Biểu thức sai hoặc quá thời gian (bước 6).** ERR-13-006 (400): "Cú pháp truy vấn chưa đúng ở vị trí 12: tên chỉ số không tồn tại."; ERR-13-015 (504): "Truy vấn quá thời gian chờ. Hãy thu hẹp khoảng thời gian hoặc điều kiện lọc."
- **E3. Kho không khả dụng (bước 3).** ERR-13-014 (503): "Dịch vụ Mimir tạm thời không khả dụng. Thử lại sau."; PH-16 thử lại.

**Quy tắc áp dụng.** BR-13-030.

**Màn hình, API.** Không có màn riêng; API-13-067, 068.
:::

### 6.39. UC-13-39 · PH-18 và phân hệ khác lấy ngữ cảnh chẩn đoán, sức khỏe thành phần

::: dac-ta
**Mục tiêu.** Người xử lý hàng đợi bản tin lỗi (DLQ) ở PH-18 có sẵn trace, log và chỉ số quanh thời điểm lỗi để quyết định xử lý lại hay bỏ, mà không phải vào từng công cụ của PH-13; các phân hệ khác lấy trạng thái sức khỏe thành phần từ một nguồn thống nhất.

**Tác nhân chính.** PH-18 (tài khoản máy, scope `obs:diagnostics-read`, thay mặt người dùng có quyền xử lý DLQ); phân hệ khác như PH-10, PH-20 (scope `obs:health-read`).

**Tác nhân phụ.** Tempo, Loki, Mimir; người xử lý DLQ.

**Mức ưu tiên.** M (ngữ cảnh chẩn đoán), S (sức khỏe thành phần).

**FR hiện thực.** FR-13-057, 058.

**Truy vết.** REQ-13, REQ-18; quy trình BP-07; FR-10-050, FR-10-059.

**Tiền điều kiện.** Mục DLQ có `trace_id` và thời điểm lỗi; FR-13-001, 007, 049 đang chạy; các phân hệ gọi đã được cấp scope.

**Kích hoạt.** Người xử lý mở một mục DLQ ở PH-18; một phân hệ gọi `GET /components`.

**Đảm bảo tối thiểu.** Log trong gói ngữ cảnh đã che, tối đa 200 dòng; phần nguồn lỗi không làm hỏng các phần còn lại.

**Đảm bảo thành công.** PH-18 nhận gói ngữ cảnh gồm trace tóm tắt, log, chỉ số; phân hệ gọi nhận trạng thái thành phần.

**Luồng chính.**

1. Người xử lý DLQ mở mục có `trace_id` `4bf92f3577b34da6a3ce929d0e0e4736` ở PH-18; PH-18 gọi `GET /diagnostics/4bf92f3577b34da6a3ce929d0e0e4736` với `contextWindow = 5m` kèm token đổi từ người dùng (API-13-069).
2. Hệ thống xác thực scope `obs:diagnostics-read` và tenant.
3. Hệ thống lấy trace tóm tắt từ Tempo (nếu còn), tối đa 200 dòng log đã che của trace và chỉ số quanh thời điểm lỗi (tải của DU, độ trễ hạ nguồn, lag Kafka) trong cửa sổ 5 phút.
4. Hệ thống trả `200`: `trace` (`found`, `summary`), `logs[]`, `metrics[]`, `expired`, kèm liên kết sang UI-13-08 cho người có `PERM-13-logs`; ghi chỉ số `dh_diag_requests_total{result}`.
5. Song song, PH-10 gọi `GET /components` (API-13-002) với scope `obs:health-read` để biết Kafka, Apicurio, Keycloak ở trạng thái `UP`, `DEGRADED`, `DOWN` hay `NO_DATA` (bộ nhớ đệm 15 giây) và hiện dải "chưa lấy được số liệu" đúng lúc.

**Luồng thay thế.**

- **3a. Trace đã hết hạn** (DLQ giữ lâu hơn 14 ngày). Hệ thống trả log còn lại và `expired = true`; bản ghi DLQ phải tự chứa đủ ngữ cảnh (FR-10-050) vì không chắc còn trace.
- **5a. Thành phần chưa có dữ liệu.** Hệ thống trả `NO_DATA` thay vì `UP`.

**Luồng ngoại lệ.**

- **E1. Không có dữ liệu ở cả ba nguồn (bước 3).** ERR-13-030 (404): "Không tìm thấy trace 4bf92f3577b34da6a3ce929d0e0e4736. Trace chỉ giữ 14 ngày và chỉ giữ một phần trace thành công."
- **E2. Thiếu scope (bước 2, 5).** ERR-13-044 (403): "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."
- **E3. Một kho không khả dụng (bước 3).** Phần đó trả `unavailable` kèm ERR-13-014 (503): "Dịch vụ Loki tạm thời không khả dụng. Thử lại sau."; các phần khác vẫn trả.
- **E4. Mimir không khả dụng khi hỏi sức khỏe (bước 5).** ERR-13-014 (503); phân hệ gọi dùng trạng thái đệm gần nhất.
- **E5. Thành phần không có trong danh mục (bước 5).** ERR-13-001 (404): "Không tìm thấy thành phần {mã}. Đối tượng có thể đã bị xóa hoặc thuộc tenant khác."

**Quy tắc áp dụng.** BR-13-011, 016, 030.

**Màn hình, API.** UI-13-01 (người dùng xem trạng thái thành phần, UC-13-20); PH-18 tự hiển thị gói ngữ cảnh; API-13-069, 002.
:::

### 6.40. UC-13-40 · Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới

::: dac-ta
**Mục tiêu.** Khi PH-20 khởi tạo một tenant, toàn bộ phần giám sát và kiểm toán của tenant được dựng tự động trong cùng saga, để tenant sẵn sàng trong thời hạn không quá 1 giờ (NFR-00-057) mà không phải cấu hình tay.

**Tác nhân chính.** PH-20 (saga khởi tạo tenant, scope `obs:tenant-provision`).

**Tác nhân phụ.** OpenBao (khóa HMAC), Kafka và PH-10 (cấp phát topic), Grafana, kho WORM, Mimir, Loki, Tempo, ClickHouse.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-13-059.

**Truy vết.** REQ-13, REQ-20; quy trình BP-08; KPI-12.

**Tiền điều kiện.** Bản ghi tenant `T70` (ví dụ tenant mới) đã tạo; realm Keycloak và tiền tố Kafka đã có ở các bước trước của saga.

**Kích hoạt.** PH-20 gọi `POST /api/platform/v1/tenants/T70/observability:provision` kèm `Idempotency-Key`.

**Đảm bảo tối thiểu.** Mọi bước lũy đẳng: lỗi ở một bước thì saga thử lại hoặc bù trừ mà không tạo trùng; không tenant nào dùng chung chuỗi hay kho cách ly với tenant khác.

**Đảm bảo thành công.** Chuỗi kiểm toán `OPEN`, mọi kho quan sát có cách ly cho tenant; bản ghi đầu tiên của chuỗi mới là `CHAIN.CREATE`.

**Luồng chính.**

1. PH-20 gọi API-13-072 với `tenantCode = T70`, `scale = QM-VUA`, `timezone = Asia/Ho_Chi_Minh`, `adminContact` của quản trị tỉnh; hệ thống kiểm tra scope.
2. Hệ thống tạo chuỗi kiểm toán: bản ghi `audit_chain` với `genesis_hash = SHA-256("genesis:" ‖ tenantCode ‖ thời điểm ‖ nonce)`, phân vùng tháng hiện tại và 3 tháng sau, khóa HMAC `dh-T70-audit-hmac` ở OpenBao, tiền tố `T70/` ở bucket WORM.
3. Hệ thống tạo topic `t70.obs.audit.recorded.v1` và `t70.obs.access.logged.v1` kèm ACL cho các DU nguồn, qua cấp phát của PH-10.
4. Hệ thống tạo cấu hình quan sát: giới hạn Mimir, Loki, Tempo theo tenant, chính sách dòng ClickHouse, tổ chức Grafana và đồng bộ bộ dashboard chuẩn (UC-13-25).
5. Hệ thống nhân bản luật chuẩn cho tenant (UC-13-27), nạp bộ luật UC-SEC (UC-13-33), tạo lịch trực mặc định gán quản trị tỉnh, kênh trong ứng dụng và kiểm tra tổng hợp mặc định.
6. Hệ thống ghi `tenant_obs_config` với tham số mặc định theo `scale`, ghi bản ghi `CHAIN.CREATE` kèm `genesis_hash` làm bản ghi đầu tiên của chuỗi `T70`, và trả `201`: `steps[]` (`name`, `status`), `genesisHash`, `grafanaOrg`.

**Luồng thay thế.**

- **1a. Gọi lặp với cùng `Idempotency-Key`.** Hệ thống trả `200` cùng kết quả.
- **1b. Tenant `PLATFORM`.** Được khởi tạo bằng cùng cơ chế khi dựng nền tảng.

**Luồng ngoại lệ.**

- **E1. Gọi lặp với tham số khác (bước 1).** ERR-13-042 (409): "Tenant T70 đã có cấu hình quan sát."
- **E2. Một bước phụ thuộc lỗi (OpenBao, Kafka, Grafana) (bước 2 đến 4).** ERR-13-014 (503): "Dịch vụ OpenBao tạm thời không khả dụng. Thử lại sau."; saga của PH-20 thử lại hoặc bù trừ, các bước đã làm được giữ để thử lại lũy đẳng.
- **E3. Thiếu scope (bước 1).** ERR-13-044 (403): "Truy vấn vượt phạm vi tenant hoặc tài khoản máy thiếu quyền."

**Quy tắc áp dụng.** BR-13-017, 027.

**Màn hình, API.** Không có màn riêng; API-13-072.
:::

### 6.41. UC-13-41 · Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập

::: dac-ta
**Mục tiêu.** Khi tenant ngừng hoạt động hoặc sáp nhập vào tenant khác, chuỗi kiểm toán được đóng đúng cách (bản ghi cuối, neo cuối) nhưng vẫn được giữ để tra cứu và xuất bằng chứng tới hết thời hạn lưu, nên không mất chứng cứ vì thay đổi hành chính. Use case thuộc Đợt sau.

**Tác nhân chính.** PH-20 (scope `obs:tenant-provision`).

**Tác nhân phụ.** OpenBao (ký neo cuối), kho WORM, ROLE-PLATFORM_ADMIN (Hà) và ROLE-TENANT_ADMIN (Giang) xem trạng thái.

**Mức ưu tiên.** S (Đợt sau).

**FR hiện thực.** FR-13-060.

**Truy vết.** REQ-13, REQ-20; quy trình BP-08.

**Tiền điều kiện.** Tenant `T70` đã sang trạng thái ngừng hoặc `DECOMMISSIONED` ở PH-20; với sáp nhập có tenant đích `T68`; chuỗi `T70` đang `OPEN`.

**Kích hoạt.** PH-20 gọi `POST /api/platform/v1/tenants/T70/audit-chain:close` kèm lý do.

**Đảm bảo tối thiểu.** Chuỗi không bao giờ bị gộp vật lý vào chuỗi khác và không bị xóa trước hết thời hạn lưu.

**Đảm bảo thành công.** Chuỗi `T70` ở `CLOSED` với neo cuối có chữ ký; vẫn tra cứu, kiểm tra toàn vẹn và xuất bằng chứng được.

**Luồng chính.**

1. PH-20 gọi API-13-073 với `reason` "Sáp nhập tenant theo quyết định của chủ quản" và `mergedInto = T68`.
2. Hệ thống kiểm tra tenant ở trạng thái cho phép đóng và chuỗi đang `OPEN`.
3. Hệ thống ghi bản ghi kiểm toán cuối `CHAIN.CLOSE` kèm lý do, rồi tạo neo cuối (`final = true`) ký và lưu như UC-13-06.
4. Hệ thống đặt chuỗi `CLOSED`, ghi `closed_at`, `closed_reason`, `merged_into`, và trả `200`: `status = CLOSED`, `finalAnchorId`, `closedAt`; ghi `AUDIT.CHAIN.CLOSE`.
5. Từ đó chuỗi `T70` không nhận bản ghi mới (UC-13-05 trả ERR-13-043) nhưng vẫn tra cứu, kiểm tra toàn vẹn và xuất bằng chứng trong thời hạn lưu.
6. Giang mở UI-13-13 của `T68` và thấy mục "Lịch sử của tenant nguồn" truy vấn chuỗi đã đóng của `T70`; chuỗi không được gộp vật lý (xem Q13-48).
7. Hà và Giang xem trạng thái chuỗi `CLOSED` ở UI-13-17, tab "Chuỗi kiểm toán".

**Luồng thay thế.**

- **6a. Tenant ngừng hẳn, không có tenant đích.** Không có mục "Lịch sử của tenant nguồn"; chuỗi vẫn tra được bởi quản trị nền tảng và kiểm toán viên nền tảng qua phiên liên tenant.
- **7a. Hết thời hạn WORM của lô cuối.** Vòng đời ở UC-13-10 xóa theo biên bản.

**Luồng ngoại lệ.**

- **E1. Chuỗi đã đóng (bước 2).** ERR-13-043 (409): "Chuỗi kiểm toán của tenant đã đóng, không nhận thêm bản ghi."
- **E2. Thiếu lý do (bước 1).** ERR-13-008 (400): "Thao tác này cần nhập lý do từ 10 đến 500 ký tự."
- **E3. Không ký được neo cuối (bước 3).** ERR-13-014 (503): "Dịch vụ OpenBao tạm thời không khả dụng. Thử lại sau."; PH-20 thử lại.

**Quy tắc áp dụng.** BR-13-017, 020.

**Màn hình, API.** UI-13-17 (trạng thái chuỗi), UI-13-13 (mục "Lịch sử của tenant nguồn"); API-13-073.
:::

### 6.42. UC-13-42 · Đặt tham số và hạn mức quan sát theo tenant

::: dac-ta
**Mục tiêu.** Quản trị điều chỉnh các tham số vận hành của PH-13 theo từng tenant (chu kỳ, tỷ lệ lấy mẫu, thời hạn lưu, giờ hành chính, hạn mức luật và chuỗi số liệu) trong biên cho phép, không cần khởi động lại.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Giang), ROLE-PLATFORM_ADMIN (Hà).

**Tác nhân phụ.** Bộ nạp cấu hình của các module `observability`, `audit`.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-13-061.

**Truy vết.** REQ-13; quy trình BP-07.

**Tiền điều kiện.** Giang có `PERM-13-admin`; tenant đã khởi tạo quan sát (UC-13-40) và không tạm ngừng.

**Kích hoạt.** Giang mở "Cài đặt giám sát" (UI-13-17) tab "Tham số và hạn mức" và lưu.

**Đảm bảo tối thiểu.** Thời hạn lưu kiểm toán không bao giờ dưới 3 năm và không rút ngắn lô đã khóa; hạn mức của tenant không vượt trần nền tảng.

**Đảm bảo thành công.** Tham số mới có hiệu lực trong tối đa 60 giây; thay đổi có bản ghi `SETTINGS.UPDATE` kèm giá trị trước và sau.

**Luồng chính.**

1. Giang mở UI-13-17, tab "Tham số và hạn mức"; UI gọi API-13-070 và hiện tham số, giá trị mặc định, miền và trần.
2. Giang đổi `13.audit.worm-retention-years` từ 5 lên 7 và `13.alert.silence-max-days` từ 7 xuống 3, nhập lý do "Theo quy chế lưu trữ của Sở" (thay đổi ảnh hưởng lưu giữ nên bắt buộc lý do) rồi lưu. UI gọi API-13-071 (`PATCH /settings`) kèm `If-Match`.
3. Hệ thống kiểm tra mỗi tham số nằm trong miền và hạn mức không vượt trần của PA.
4. Hệ thống kiểm tra thời hạn WORM không dưới 3 năm và không rút ngắn lô đã khóa (BR-13-020).
5. Hệ thống lưu, ghi `SETTINGS.UPDATE` kèm giá trị trước và sau, áp dụng trong tối đa 60 giây và phát EVT-13-10.
6. Hà (PA) đặt trần `13.series.max-active` của `T68` là 400.000; Giang sau đó đặt 300.000, nằm trong trần.

**Luồng thay thế.**

- **2a. Tham số chỉ nền tảng** (ví dụ số bản sao Collector). Ẩn với Giang, chỉ Hà sửa được.
- **5a. Nâng thời hạn WORM.** Áp dụng cho lô mới ở UC-13-06; lô còn hạn có thể gia hạn, chỉ kéo dài.

**Luồng ngoại lệ.**

- **E1. Tham số ngoài miền hoặc thời hạn lưu dưới 3 năm (bước 3, 4).** ERR-13-040 (422): "Tham số 13.audit.worm-retention-years ngoài miền cho phép; thời hạn lưu kiểm toán không được thấp hơn 3 năm."
- **E2. Hạn mức vượt trần (bước 3, 6).** ERR-13-041 (422): "Hạn mức 13.series.max-active vượt trần của nền tảng (400000)."
- **E3. Sai phiên bản, thiếu quyền hoặc thiếu lý do (bước 2).** ERR-13-007 (412): "Dữ liệu đã được người khác sửa. Tải lại để xem phiên bản mới nhất."; ERR-13-009 (403): "Bạn không có quyền thực hiện thao tác này."; ERR-13-008 (400): "Thao tác này cần nhập lý do từ 10 đến 500 ký tự."
- **E4. Tenant đang tạm ngừng (bước 2).** ERR-13-016 (423): "Tenant đang tạm ngừng; chỉ xem được, chưa thay đổi được cấu hình."

**Quy tắc áp dụng.** BR-13-006, 020, 028, 031.

**Màn hình, API.** UI-13-17 (tab Tham số và hạn mức); API-13-070, 071.
:::

### 6.43. UC-13-43 · Khôi phục chuỗi kiểm toán sau sự cố mất dữ liệu

::: dac-ta
**Mục tiêu.** Sau sự cố mất dữ liệu ở cơ sở dữ liệu kiểm toán, đội vận hành nạp lại nguyên văn các bản ghi đã nằm ở kho WORM để chuỗi băm liền lại và qua được kiểm tra toàn vẹn, mà không sửa hay dựng lại chuỗi. Đây là đường ngoại lệ duy nhất của BR-13-033, có biên bản; use case thuộc Đợt sau.

**Tác nhân chính.** Đội vận hành (chạy công cụ `AuditRestore`).

**Tác nhân phụ.** ROLE-SECURITY_OFFICER (Dũng) và ROLE-TENANT_ADMIN (Giang) cùng ký biên bản; kho WORM, PostgreSQL, OpenBao (kiểm neo), SIEM.

**Mức ưu tiên.** C (Đợt sau).

**FR hiện thực.** FR-13-062.

**Truy vết.** REQ-13; quy trình ứng cứu sự cố (D03-07 §8); D03-03-PH13 §7.2.

**Tiền điều kiện.** Sự cố mất dữ liệu đã được xác nhận; PostgreSQL đã khôi phục và mở chế độ chỉ đọc; `ingest` chưa cho ghi; Dũng và Giang đã duyệt biên bản mở và cửa sổ bảo trì.

**Kích hoạt.** Dũng yêu cầu đội vận hành chạy thủ tục sau khi xác nhận sự cố.

**Đảm bảo tối thiểu.** Không bản ghi nào bị sửa hoặc dựng mới; trigger `tg_audit_chain_guard` luôn áp dụng; không có màn hình hay API cho thao tác này.

**Đảm bảo thành công.** Chuỗi của từng tenant liền lại, xác minh `ON_DEMAND` toàn chuỗi đạt, `AUDIT.CHAIN.RESTORE` ghi ở chuỗi `PLATFORM`, biên bản có chữ ký Dũng và Giang lưu ở `dh-evidence`.

**Luồng chính.**

1. Đội vận hành so `head_seq` và `head_hash` của chuỗi từng tenant với lô WORM mới nhất và neo gần nhất; thấy bảng đứng sau WORM khoảng 4 phút bản ghi.
2. `AuditRestore` đọc lô từ WORM, kiểm băm lô và băm từng bản ghi, rồi chèn nguyên văn theo thứ tự; trigger kiểm liền kề và nối đúng.
3. Đội vận hành mở lại `ingest`; DU gửi lại bản ghi chưa lên WORM từ hộp thư đi hoặc Kafka, hệ thống khử trùng theo `id` và nối tiếp bản còn lại.
4. Hệ thống chạy lượt xác minh toàn chuỗi (UC-13-07); kết quả đạt.
5. Hệ thống ghi `AUDIT.CHAIN.RESTORE` vào chuỗi `PLATFORM` và gửi SIEM.
6. Dũng và Giang cùng ký biên bản; đội vận hành lưu ở `dh-evidence`.

**Luồng thay thế.**

- **2a. Bảng không đứng sau WORM.** Bỏ bước 2, chỉ xác minh và lập biên bản.
- **2b. Nhiều tenant bị mất dữ liệu.** Chạy lần lượt từng tenant; mỗi tenant xác minh đạt rồi mới mở `ingest` cho tenant đó.

**Luồng ngoại lệ.**

- **E1. Băm không khớp neo (bước 2).** Dừng, không chèn thêm; xử lý như đứt chuỗi ở UC-13-08.
- **E2. Thiếu chữ ký Dũng hoặc Giang (trước bước 1).** Không mở cửa sổ bảo trì, không chạy `AuditRestore`.
- **E3. Xác minh không đạt (bước 4).** Chuỗi giữ trạng thái đứt; mở sự cố theo UC-13-08.

**Quy tắc áp dụng.** BR-13-002, 033 (ngoại lệ có biên bản).

**Màn hình, API.** Không có màn hình, không có API; thủ tục vận hành ở sổ tay của PH-18.
:::

## 7. Luồng phụ dùng chung

Bảy luồng phụ dưới đây được nhiều use case dẫn chiếu để mỗi use case không phải mô tả lại. Mỗi luồng phụ là một hành vi giao diện hoặc hệ thống cố định; mã lỗi và câu thông báo lấy nguyên văn từ FRS §9.2.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-13-01 | Lý do bắt buộc: hộp thoại có ô lý do 10…500 ký tự, thiếu thì thao tác không chạy; với tra cứu và xuất kiểm toán trả ERR-13-012, với thao tác cấu hình trả ERR-13-008; tra theo đối tượng và xuất bằng chứng cần thêm ô căn cứ 5…200 ký tự | UC-13-07, 12, 14, 15, 26, 33, 36, 41, 42 |
| LP-13-02 | Xác thực lại phiên (step-up): thao tác xuất bằng chứng và tương tự đòi nhập lại mật khẩu hoặc mã MFA; chưa xác thực lại trả ERR-13-028. Ở mọi use case do người thao tác, phiên hết hạn trả ERR-13-010 ("Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục.") và người dùng quay lại bước đang làm sau khi đăng nhập | UC-13-15 (và mọi use case có người thao tác) |
| LP-13-03 | Phiên liên tenant: người dùng cấp nền tảng mở phiên có lý do, hiệu lực mặc định 60 phút; bản ghi mở và đóng nằm ở cả hai chuỗi; truy cập không có phiên trả ERR-13-036 và ghi `OBS.CROSS_TENANT_ATTEMPT` | UC-13-07, 15, 16, 20 |
| LP-13-04 | Ghi vết trước khi trả: thao tác chỉ-đọc nhạy cảm (tra cứu kiểm toán, xuất bằng chứng) ghi bản ghi vào hộp thư đi trước khi trả kết quả; không ghi được thì từ chối với ERR-13-014; giao diện nhắc "Việc tra cứu này sẽ được ghi vết." | UC-13-07, 11, 12, 14, 15, 16 |
| LP-13-05 | Tác vụ bất đồng bộ: lệnh trả `202` kèm mã tác vụ; giao diện hỏi lại trạng thái (kiểm tra toàn vẹn, xuất bằng chứng, đồng bộ dashboard) và nhận thông báo khi xong | UC-13-07, 15, 25 |
| LP-13-06 | Thiếu dữ liệu và panel lỗi: chỉ số không có dữ liệu hiện chữ "Chưa có dữ liệu", không bao giờ hiện 0; kho không khả dụng chỉ làm hỏng panel liên quan, hiện "Dịch vụ {tên} tạm thời không khả dụng. Thử lại sau." kèm nút "Thử lại" | UC-13-20, 21, 22, 23, 24, 31, 32, 39 |
| LP-13-07 | Xung đột phiên bản: thao tác sửa gửi `If-Match`; người lưu sau nhận ERR-13-007 và tải lại bản mới nhất; thao tác tạo gửi `Idempotency-Key`, trùng khác nội dung trả ERR-13-037 | UC-13-04, 25, 26, 29, 30, 33, 36, 42 |

: Luồng phụ dùng chung của PH-13

## 8. Tổng hợp mã mới và đối chiếu

Tập này không tạo mã FR, NFR, BR, API, ERR, EVT hay UI mới; mọi mã dùng ở chương 6 đều có ở FRS. Mã mới của tập: **UC-13-01…43** (43 use case) và **LP-13-01…07** (7 luồng phụ); câu hỏi mở **Q13-45…49**.

**Đối chiếu độ phủ.** Mọi FR mức M (52 FR) và mức S (8 FR) có ít nhất một use case (bảng 5.1); FR-13-055 và FR-13-062 (mức C, Đợt sau) thuộc UC-13-37 và UC-13-43. Mỗi use case có FR, màn hình hoặc ghi rõ "không có màn riêng", và API hoặc ghi rõ "không có API riêng" (bảng 5.2). Mỗi mục `LGC` có phân hệ đích PH-13 ở FRS §11.1 xuất hiện ở cột LGC của bảng 5.3 ít nhất một lần; hai hàng `LGC-NFR` (004, 005) nằm ở UC-13-01, 06, 10, 17.

**Đối chiếu hai yêu cầu xuyên suốt.** FR-13-009 (cách ly theo tenant) không có use case riêng: nó được hiện thực ở UC-13-01 (bước 7) và là điều kiện của mọi use case đọc dữ liệu quan sát. FR-13-019 (ghi vết thao tác của PH-13) có UC-13-11 và còn được áp dụng ở bước kiểm toán của UC-13-12, 14, 15, 16, 26, 29, 30, 33, 35, 36, 41, 42.

**Lưu ý đối chiếu quyền.** Bảng ma trận quyền FRS §3.2 không cấp `PERM-13-audit-read` cho PO, nhưng FR-13-017 ghi PO xem kết quả đối chiếu; use case theo ma trận (xem Q13-45).

## 9. Câu hỏi mở

> **Câu hỏi mở Q13-45:** FR-13-017 ghi PO, SO, AU xem kết quả đối chiếu số lượng bằng `PERM-13-audit-read`, nhưng FRS §3.2 không cấp quyền này cho PO (Q13-07), và UI-13-18 (nơi hiện bảng đối chiếu) có PO trong cột vai trò chính. UC-13-09 giả định: PO (Lan) thấy backlog, độ trễ và trạng thái đối chiếu tổng (`MATCH` hay `MISMATCH`) qua `PERM-13-dashboard`, còn bảng đối chiếu chi tiết theo DU chỉ SO và AU xem. Cần chốt ở D03-06-PH13 và sửa FRS cho khớp.

> **Câu hỏi mở Q13-46:** UC-13-08 bước 8a cho SO đóng cảnh báo đứt chuỗi với kết luận `ACCEPTED_RISK` khi nguyên nhân là khôi phục từ sao lưu có biên bản. Cần xác nhận kết luận này chỉ một mình SO được ghi hay phải có TA đồng ý (đứt chuỗi là sự cố nghiêm trọng nhất của phân hệ). Giả định: SO ghi kèm biên bản đính kèm, TA và PA được thông báo ngay khi đóng.

> **Câu hỏi mở Q13-47:** UC-13-37 nhắc hạn 72 giờ ở mốc 24, 48, 60 giờ; FRS chưa nêu ai nhận nhắc và qua kênh nào. Giả định: SO phụ trách và TA nhận qua trung tâm thông báo cộng thư điện tử; mức nhắc ở 60 giờ gửi thêm SMS. Cần chốt cùng Q13-10 khi quyết định phạm vi báo cáo sự cố.

> **Câu hỏi mở Q13-48:** UC-13-41 bước 6 cho tenant đích xem chuỗi tenant nguồn đã đóng ở UI-13-13 (FR-13-060 bước 5), còn tab "Lịch sử" ở màn chi tiết của phân hệ chủ (UC-13-13) chỉ truy vấn chuỗi tenant hiện hành. Câu hỏi: đối tượng chuyển từ tenant nguồn sang tenant đích có cần tab "Lịch sử" hiển thị cả phần trước sáp nhập không. Giả định: không ở MVP; cán bộ tra ở UI-13-13 mục "Lịch sử của tenant nguồn" khi cần.

> **Câu hỏi mở Q13-49:** FR-13-047 cho phép xác nhận hàng loạt cảnh báo cùng nhóm nhưng không nêu số tối đa và không có API gộp (FRS §9.4 chỉ có API-13-032 cho từng cảnh báo). UC-13-29 bước 2a giả định giao diện gọi API-13-032 lần lượt cho tối đa 50 cảnh báo cùng nhóm mỗi lần và hiện kết quả từng cảnh báo; nếu cần API gộp thì D03-04-PH13 bổ sung.

## 10. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các đề nghị dưới đây cần tài liệu khác cập nhật; tập này không sửa thay và không tạo ADR mới.

| Tài liệu | Đề nghị |
|---|---|
| D02-08 | Như FRS §3.4: thêm `PERM-13-alert-ack`, `PERM-13-security`, `PERM-13-admin` và ba scope máy dùng ở UC-13-13, 38, 39, 40, 41; các use case UC-13-08, 24, 29, 33, 35, 36, 37, 42 dựa vào ba quyền này. Kiểm tra mã hiện báo ba quyền này "thiếu" ở D02-08, lỗi này nằm ở tài liệu dùng chung chờ đồng bộ chứ không phải ở tập use case |
| D02-03-PH13 (FRS) | FR-13-017: làm rõ ai xem kết quả đối chiếu so với ma trận quyền (Q13-45); FR-13-016: ghi TO xem tình trạng đệm nhưng UI-13-18 không có TO trong cột vai trò, hoặc thêm TO vào UI-13-18, hoặc bỏ TO ở FR-13-016; FR-13-047: nêu số tối đa của xác nhận hàng loạt (đề nghị 50) và cách gọi API (Q13-49) |
| D03-04-PH13 (API) | Xác nhận không cần API xác nhận hàng loạt (giao diện gọi lặp API-13-032); các API của UC máy (API-13-072, 073, 089) ghi rõ tác nhân gọi là PH-20 và DU nguồn; ví dụ phản hồi cho UC-13-12, 15 |
| D03-06-PH13 (màn hình) | Mỗi use case có màn là một luồng giao diện: UC-13-12 (tra cứu rồi xem chi tiết trong cùng UI-13-13), UC-13-21 (ba tab của UI-13-02), UC-13-23 (hai tab của UI-13-04), UC-13-36 và UC-13-42 (các tab của UI-13-17); UC-13-13 là tab "Lịch sử" ở màn chi tiết của phân hệ chủ, không phải màn của PH-13; thông báo "Việc tra cứu này sẽ được ghi vết." ở mọi màn kiểm toán |
| D05-02-PH13 (test case) | Mỗi luồng chính, luồng thay thế, luồng ngoại lệ của chương 6 là một ca kiểm thử; UC-13-08, UC-13-15 và UC-13-09 cần ca diễn tập (đứt chuỗi cố ý ở môi trường thử, xác minh ngoại tuyến gói bằng chứng, tắt bộ tiếp nhận hai giờ rồi đối chiếu bằng 0) |
| D03-02-PH13 (SDD) | Sơ đồ trình tự cho UC máy 05, 06, 09, 28, 40 dựa trên các bước của chương 6; làm rõ nơi ghép `trace_id` giữa UC-13-17, 18 |
| D00-03 | Có thể thêm cột UC cho hàng `LGC` PH-13 khi bảng truy vết được mở rộng (bảng 5.3 đã có sẵn ánh xạ) |

: Đề nghị đồng bộ cho tài liệu khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và quy chuẩn K-TRINH-BAY: 42 use case (UC-13-01…42) phủ đủ 61 FR, mỗi use case một khối 15 mục kèm câu thông báo lấy từ FRS §9.2; sáu hình sơ đồ use case tổng; ba bảng truy vết (FR, màn hình và API, REQ-quy trình-hệ cũ); 7 luồng phụ dùng chung; 5 câu hỏi mở Q13-45…49; đề nghị đồng bộ cho FRS, API, màn hình, test case, SDD |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà chéo bảy tập PH-13: bảng 5.2 liệt kê đủ API và UI như trường "Màn hình, API" của từng use case; thêm đoạn mở cho mục 5.1, 5.2 |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Chốt câu hỏi mở đợt đồng bộ: Q390, Q419 |
| 0.4 | 27/11/2026 | Nhóm viết tài liệu (Claude) | UC-13-35: nút đề xuất chỉ ở mức Cao, Nghiêm trọng; thêm luồng ngoại lệ E6 (ERR-13-003), E7 (ERR-01-048), E8 (ERR-01-005) theo FR-13-053 |

