---
ma_tai_lieu: D02-04-PH18
ten: Đặc tả use case phân hệ PH-18 Vận hành và xử lý lỗi
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-18
mo_ta: Đặc tả 40 use case của phân hệ Vận hành và xử lý lỗi (kho tham số và cờ tính năng, tiếp nhận và xử lý bản tin lỗi DLQ, phát lại, thông báo, Việc của tôi và lịch, sự cố vận hành, sao lưu và khôi phục tenant, di trú hệ cũ và chạy song song, quản trị và sức khỏe), mỗi use case một khối 15 mục kèm mã lỗi và câu thông báo lấy từ FRS, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH18 FRS; D03-02-PH18 SDD; D03-03-PH18 CSDL; D03-04-PH18 API; D03-06-PH18 Màn hình; D05-02-PH18 Kiểm thử; D03-09 Hạ tầng và DR
---

# D02-04-PH18 · Đặc tả use case Vận hành và xử lý lỗi

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 40 use case của PH-18, phủ toàn bộ 72 FR (57 mức M, 12 mức S, 3 mức C) và 188 API của [D02-03-PH18](../frs/D02-03-PH18-frs-van-hanh.md) bản 0.2. Use case đi theo một ngày làm việc của "phòng máy" Datahub ở một tỉnh: phân hệ khác đăng ký và đọc tham số; bản tin lỗi của mọi phân hệ đổ về một hàng DLQ (Dead Letter Queue, hàng bản tin lỗi) hợp nhất, được chẩn đoán, sửa có kiểm soát, phát lại qua lối vào của nguồn hoặc bỏ qua có lý do; thư, SMS và hộp "Việc của tôi" đưa việc tới đúng người; sự cố được mở từ cảnh báo và đóng khi có nguyên nhân gốc; sao lưu được theo dõi, một tenant được khôi phục về thời điểm cũ trong tám bước có bốn mắt; dữ liệu hệ cũ được chạy thử, chạy thật, đối chiếu rồi cắt chuyển từng nhóm dịch vụ, quay lui được trong 15 phút. Căn cứ: REQ-18, REQ-22 của BRD; FR-00-050…054, FR-00-061, FR-00-062, FR-00-070…072, FR-00-090…093 của SRS; CMP-LAW-05 (Luật BVDLCN 91/2025), CMP-LAW-08 (TCVN 14423:2026).

Bốn điểm hội đồng cần lưu ý. Thứ nhất, hệ cũ chỉ có hai chức năng liên quan (LGC-BUS-031 cấu hình hệ thống, LGC-BUS-037 thực hiện lại hoặc bỏ qua) nên hầu hết use case là năng lực mới; DLQ của hệ cũ không có chẩn đoán, không có bốn mắt và không bảo đảm lũy đẳng khi phát lại. Thứ hai, PH-18 không đứng trên đường chính: phân hệ khác đọc tham số từ bộ đệm, giữ bản tin lỗi trong Kafka hoặc hàng lỗi của mình, và coi là không đóng băng khi PH-18 vắng (LP-18-04). Thứ ba, mọi thao tác có hậu quả khó đảo ngược đều qua bốn mắt (LP-18-01): tham số bảo mật ★, bản sửa payload chạm trường mức Hạn chế, lượt phát lại vượt 500 mục, phiên bản mẫu thông báo, khôi phục tenant, chạy di trú thật và cắt chuyển; hủy, tạm dừng và quay lui thì không cần vì làm giảm rủi ro. Thứ tư, bản 0.1 phát hiện 15 điểm lệch hoặc thiếu so với FRS 0.1 (Phụ lục A); FRS 0.2 đã hấp thụ mười hai điểm, gồm bốn thao tác ghi trước đây chưa có API (nay là API-18-181 nhận việc, API-18-182 đánh dấu bản ghi di trú lỗi, API-18-183 đánh dấu `WAIVED`, API-18-184 quy tắc chuẩn hóa) và chế độ chỉ đọc nay bật, tắt qua API-18-187 không bị chặn; ba điểm còn lại chờ đợt đồng bộ liên phân hệ.

## 1. Giới thiệu

Chương này nói tài liệu dùng để làm gì, phủ những gì, ai cần đọc phần nào, thuật ngữ và tài liệu cần mở song song.

### 1.1. Mục đích

Tập use case chuyển 72 yêu cầu chức năng của FRS PH-18 thành các kịch bản sử dụng có tác nhân, tiền điều kiện, luồng chính, luồng thay thế và luồng ngoại lệ có mã lỗi cụ thể. Tập này là cầu nối giữa FRS và các tập thiết kế: kỹ sư dùng nó để dựng trình tự thành phần (SDD D03-02-PH18), người thiết kế màn hình dùng nó để đặt luồng thao tác và câu thông báo (D03-06-PH18), kiểm thử viên dùng nó để dựng kịch bản và ca kiểm thử (D05-02-PH18), còn hội đồng thẩm định dùng nó để thấy người vận hành tỉnh xử lý một bản tin lỗi, một sự cố hay một lần khôi phục ra sao trong tình huống thật. Dữ liệu ví dụ là giả lập, tenant `T68`.

### 1.2. Phạm vi

Tập phủ đủ 72 FR trong 10 nhóm A đến J của FRS. PH-18 chạy trong DU `dh-platform` (package `vn.datahub.platform.ops`), tác vụ nặng chạy thành Job Kubernetes trong `dh-batch` bằng ảnh `dh-ops-worker`. Tập không mô tả phần mà phân hệ khác giữ: retry, circuit breaker, `errorHandler` (PH-04); thao tác loại bỏ, duyệt phát lại DLQ tầng sự kiện (PH-10); luật cảnh báo, lịch trực, kiểm toán WORM (PH-13); khởi tạo, tạm ngừng, điều phối sáp nhập tenant (PH-20); đồng hồ 72 giờ của sự cố dữ liệu cá nhân (PH-09); tham số `19.*` (PH-19). Tập không tạo mã FR, BR, API, ERR, EVT, UI mới; chỗ thiếu ghi ở Phụ lục A.

### 1.3. Người đọc

| Người đọc | Nên đọc | Dùng để làm gì |
|---|---|---|
| Hội đồng thẩm định, lãnh đạo | Tóm tắt, chương 4, UC-18-17, 31, 36, 38 | Hiểu cách hệ thống phát lại an toàn, khôi phục tenant, di trú và cắt chuyển có quay lui |
| Cán bộ ATTT, kiểm toán | UC-18-03, 13, 14, 20, 29, 31, 39 | Kiểm bốn mắt, xem nội dung có lý do, thư không mang dữ liệu Hạn chế, nhật ký thao tác |
| Kỹ sư phát triển | Chương 6 toàn bộ, chương 7 | Dựng thành phần, API, sự kiện đúng mã |
| Kiểm thử viên | Mục 5.4, các khối luồng thay thế và ngoại lệ | Dựng kịch bản kiểm thử ứng với từng use case |
| Người thiết kế giao diện | Mục "Màn hình, API", câu thông báo ở luồng ngoại lệ | Dựng màn UI-18-01 đến UI-18-24 |

: Người đọc và phần nên đọc

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ đầy đủ ở FRS mục 1.4. Các thuật ngữ cần cho tập này:

| Thuật ngữ | Nghĩa |
|---|---|
| DLQ | Hàng bản tin lỗi: nơi giữ bản tin mà phân hệ nguồn đã thử hết số lần vẫn không xử lý được |
| Mục DLQ | Một bản ghi chỉ mục ở `ph18_ops` cho một bản tin lỗi, có ngữ cảnh, trạng thái và tham chiếu payload |
| Payload | Nội dung gốc của bản tin lỗi; không bao giờ bị sửa, sửa đổi tạo bản sửa riêng |
| `POISON` | Mục thiếu trường bắt buộc của hợp đồng ngữ cảnh nên không phát lại được, chỉ sửa hoặc bỏ qua |
| Phát lại | Gửi lại bản tin vào lối vào của phân hệ nguồn với khóa lũy đẳng `dlqId:revision` |
| Lượt phát lại | Một tập mục được phát lại theo tốc độ giới hạn, có tiến độ, tạm dừng và hủy |
| Lũy đẳng | Gọi lại cùng một lệnh nhiều lần cho cùng một kết quả, không tạo bản trùng |
| Bốn mắt | Người duyệt phải khác người đề nghị (FR-00-071, ADR-046) |
| Khóa ★ | Khóa tham số bảo mật, đổi giá trị cần bốn mắt |
| Tác vụ nặng | Khôi phục, xuất, chạy di trú thật hoặc chuyển sáp nhập của một tenant; mỗi lúc chỉ một |
| Chạy bóng | Datahub nhận bản nhân bản lưu lượng của hệ cũ, so phản hồi, không trả kết quả về HTTT |
| Cắt chuyển | Chuyển lưu lượng của một nhóm dịch vụ từ hệ cũ sang Datahub, có cửa sổ quay lui 15 phút |
| Inbox, outbox | Bảng khử trùng sự kiện nhận và bảng sự kiện chờ phát trong cùng giao dịch (ADR-042) |

: Thuật ngữ dùng trong tập use case

### 1.5. Tài liệu tham chiếu

| Tài liệu | Dùng để |
|---|---|
| D02-03-PH18 FRS 0.2 | Nguồn FR, BR, ERR, EVT, API, UI, tham số `18.*`; câu thông báo nguyên văn mục 9.1 |
| D02-08 | Quyền `PERM-18-*` và vai trò |
| D02-01 BRD | REQ-18, REQ-22; quy trình BP-07, BP-08, BP-09 |
| D03-09 §8.2, §8.5 | Danh mục đối tượng sao lưu, sổ tay khôi phục một tenant (RBK-04) |
| ADR-180 đến ADR-184 | Kho tham số, DLQ hợp nhất, phát lại qua lối vào nguồn, khung di trú, thông báo |
| D00-04, K-UC, K-TRINH-BAY | Khuôn và quy chuẩn trình bày |

: Tài liệu tham chiếu

### 1.6. Cấu trúc tài liệu

Chương 2 nêu quy ước đọc và nhân vật giả lập; chương 3 liệt kê tác nhân; chương 4 là sáu sơ đồ use case theo nhóm; chương 5 là bốn bảng truy vết; chương 6 là đặc tả chi tiết 40 use case theo mười nhóm; chương 7 là luồng phụ dùng chung; chương 8 tổng hợp mã và đối chiếu với FRS; chương 9 là câu hỏi mở Q18-45 đến Q18-49; Phụ lục A là đề nghị đồng bộ.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ · Quy tắc áp dụng · Màn hình, API. Mười bốn use case có trao đổi giữa từ ba thành phần trở lên hoặc có duyệt bốn mắt có thêm sơ đồ trình tự ngay sau khối.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3). Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-18-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép, lấy nguyên văn cột "Thông báo" của FRS mục 9.1 (dấu `{…}` do máy chủ điền). Mã ERR-18-101 đến ERR-18-124 là lỗi của luồng tiếp nhận, worker và gửi thông báo: không trả qua HTTP mà hiện thành nhãn trạng thái và dòng lý do ở màn của đối tượng (UI-18-03, UI-18-13, UI-18-20, UI-18-22) hoặc ở UI-18-24, nên ghi "(worker)" thay cho mã HTTP. Lỗi thiếu quyền chức năng dùng mã nền ERR-00-401, ERR-00-403, ERR-00-428 và không nhắc lại từng use case. Luồng phụ dùng chung ghi `LP-18-nn` (chương 7).

Quy ước chung: mọi `POST` đổi dữ liệu qua `/api/ops/v1` mang `Idempotency-Key`, mọi `PUT`, `PATCH`, chuyển trạng thái mang `If-Match` (BR-18-049, LP-18-03); mọi bảng chạy dưới RLS theo `tenant_id`, đối tượng của tenant khác trả như không tồn tại (BR-18-047); mọi thao tác ghi vận hành ghi kiểm toán PH-13 trước khi có hiệu lực (BR-18-046, LP-18-02). Sự kiện, sổ tay, báo cáo không mang payload hay dữ liệu cá nhân (BR-18-050).

| Vai | Người hoặc hệ thống | Ghi chú |
|---|---|---|
| PA | **Hà** (quản trị nền tảng) | Đặt trần tham số, duyệt khôi phục tenant, ghi nhận diễn tập DR, khai báo cờ tính năng |
| PO | **Khoa** (vận hành nền tảng, trực ca) | Xem DLQ liên tenant ở chế độ nền tảng, sức khỏe PH-18, bảng sao lưu |
| TA | **Mai** và **Tuấn** (hai quản trị Datahub tỉnh T68) | Mai đề nghị; Tuấn là người thứ hai khi cần bốn mắt trong tỉnh |
| TO | **Chi** (vận hành tỉnh, trực) | Phân loại, phát lại, bỏ qua mục DLQ; xử lý sự cố |
| SO | **Dũng** (cán bộ ATTT) | Xem nội dung có lý do, duyệt tham số ★, chuyển sự cố sang PH-09 |
| IE, DS | **Quân** (kỹ sư tích hợp), **Lan** (cán bộ dữ liệu) | Quân sửa payload của luồng mình; Lan sửa dữ liệu di trú lỗi |
| AU, VW | **Phúc** (kiểm toán), **Bình** (lãnh đạo Sở, người xem) | Phúc tra nhật ký, báo cáo; Bình xem thống kê |
| Hệ thống | `dh-runtime-t68` (PH-04 runtime), PH-10, PH-13, PH-20, máy chủ thư của tỉnh | Nguồn DLQ, nguồn sự kiện, giám sát, quản trị tenant |
| Đối tượng | Luồng `hotich-khaisinh-dongbo` phiên bản 3, nguồn `ph04-runtime`, mã lỗi `ERR-04-101`, mục `dlq-000123`, sự cố `SC-2027-0042`, kế hoạch `KH-HOTICH-01`, nhóm dịch vụ `nhom-hotich` | Dữ liệu ví dụ, không phải dữ liệu thật |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-18 có chín nhóm tác nhân người và nhiều tác nhân hệ thống (FRS mục 3.1). PH-18 không tạo ROLE mới; quyền theo FRS mục 3.2 (nguồn chuẩn khi lệch D02-08, xem ĐN-UC-12). Phân hệ khác gọi PH-18 bằng danh tính SPIFFE và scope máy, không bằng quyền người.

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính |
|---|---|---|
| PA | ROLE-PLATFORM_ADMIN | `PERM-18-admin`, `PERM-18-config` (trần, khóa `PLATFORM`), `PERM-18-approve` (khôi phục), `PERM-18-backup`, `PERM-18-migration` |
| PO | ROLE-PLATFORM_OPERATOR | `PERM-18-read`, `PERM-18-dlq`, `PERM-18-incident`, `PERM-18-backup`, `PERM-18-migration` |
| TA | ROLE-TENANT_ADMIN | `PERM-18-config`, `PERM-18-approve`, `PERM-18-template`, `PERM-18-backup`, `PERM-18-calendar`, `PERM-18-migration`, `PERM-18-dlq` |
| TO | ROLE-TENANT_OPERATOR | `PERM-18-dlq`, `PERM-18-dlq-payload`, `PERM-18-incident` |
| SO | ROLE-SECURITY_OFFICER | `PERM-18-dlq-payload`, `PERM-18-approve`, `PERM-18-incident` |
| IE, DS | ROLE-INTEGRATION_ENGINEER, ROLE-DATA_STEWARD | IE: `PERM-18-dlq` (luồng được giao), `PERM-18-dlq-payload`; DS: `PERM-18-dlq` (tài sản được giao), `PERM-18-migration` (bản ghi lỗi) |
| AU, VW | ROLE-AUDITOR, ROLE-VIEWER | `PERM-18-read` (VW chỉ thống kê và sức khỏe) |
| Người dùng đăng nhập | Mọi vai trò | Việc của tôi, thông báo trong ứng dụng, tùy chọn nhận |
| DU của phân hệ chủ tham số | PH-01 đến PH-17, PH-20 | `ops:param-register`, `ops:param-read`; PH-20 thêm `ops:param-write`, `ops:merge-transfer` |
| Phân hệ nguồn DLQ | `dh-runtime`, PH-01, PH-06, PH-08, PH-19 | Topic `{tenant}.ops.dlq.v1`, `ops:dlq-write`, `ops:replay-callback` |
| PH-10, PH-13, PH-17, PH-09 | Phân hệ nền | PH-10 DLQ tầng sự kiện, cầu nối; PH-13 chẩn đoán, kiểm toán, lịch trực, `ops:incident-write`; PH-17 `ops:dlq-read`; PH-09 nhận sự cố có dữ liệu cá nhân |
| Hạ tầng | Máy chủ thư, SMS gateway (IF-09), OpenBao, Garage, CNPG, Velero, APISIX | Gửi thông báo, giữ bí mật, lưu payload lớn, trạng thái sao lưu, nhân bản lưu lượng |

: Tác nhân của PH-18 và quyền chính

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, 40 use case chia thành sáu hình theo nhóm của FRS. Mermaid không có ký pháp use case nên dùng `flowchart`: hình bo tròn là người, hình hai viền là hệ thống, chữ nhật bo góc là use case; đường liền nối tác nhân với use case.

```{.mermaid caption="Use case kho tham số và cờ tính năng (nhóm A)"}
flowchart TB
  DU[[DU phân hệ chủ]]
  TA([TA, SO])
  PA([PA])
  P20[[PH-20]]
  subgraph A["Kho tham số và cờ tính năng"]
  U01(UC-18-01 Đăng ký lược đồ, đọc có bộ đệm)
  U02(UC-18-02 Sửa tham số trên màn chung)
  U03(UC-18-03 Bốn mắt tham số bảo mật)
  U04(UC-18-04 Lịch sử, khôi phục phiên bản)
  U05(UC-18-05 Gói tham số giữa môi trường)
  U06(UC-18-06 Cờ tính năng, egress)
  U07(UC-18-07 Mặc định khi khởi tạo tenant)
  end
  DU --- U01
  TA --- U02 & U03 & U04 & U06
  PA --- U02 & U05 & U06
  P20 --- U07
```

Hình cho thấy phân hệ chủ chỉ đăng ký và đọc, người sửa giá trị là TA trong miền và PA ở mức trần; tham số ★ luôn qua người thứ hai; PH-20 chỉ ghi khóa chưa có khi khởi tạo tenant.

```{.mermaid caption="Use case tiếp nhận, phân loại và xử lý DLQ (nhóm B, C)"}
flowchart TB
  SRC[[Phân hệ nguồn]]
  P10[[PH-10]]
  TO([TO, TA])
  IE([IE, SO])
  P17[[PH-17]]
  subgraph B["Tiếp nhận DLQ"]
  U08(UC-18-08 Đăng ký nguồn, cổng phát lại)
  U09(UC-18-09 Tiếp nhận topic, đối soát)
  U10(UC-18-10 Ghi DLQ qua API)
  U11(UC-18-11 DLQ tầng sự kiện PH-10)
  end
  subgraph C["Phân loại và xử lý"]
  U12(UC-18-12 Lọc, gom nhóm, gán)
  U13(UC-18-13 Chi tiết, chẩn đoán, nội dung)
  U14(UC-18-14 Sửa payload bốn mắt)
  U15(UC-18-15 Sổ tay lỗi, API cho PH-17)
  end
  SRC --- U08 & U09 & U10
  P10 --- U11
  TO --- U11 & U12 & U13
  IE --- U13 & U14
  P17 --- U15
```

Hình cho thấy bản tin lỗi vào bằng hai đường (topic chung và API ghi), DLQ tầng sự kiện chỉ được liên thông chứ không sao chép, và nội dung payload chỉ mở cho người có quyền riêng kèm lý do.

```{.mermaid caption="Use case phát lại, bỏ qua và lưu giữ (nhóm D)"}
flowchart TB
  TO([TO, TA])
  AP([Người duyệt])
  SRC[[Phân hệ nguồn]]
  P13[[PH-13]]
  subgraph D["Phát lại, bỏ qua, lưu giữ"]
  U16(UC-18-16 Phát lại một mục)
  U17(UC-18-17 Phát lại loạt bốn mắt)
  U18(UC-18-18 Bỏ qua, mở lại)
  U19(UC-18-19 Lưu giữ, thống kê, ngưỡng)
  end
  TO --- U16 & U17 & U18 & U19
  AP --- U17
  SRC --- U16 & U17
  P13 --- U19
```

Hình cho thấy phát lại luôn đi qua phân hệ nguồn, lượt lớn có người duyệt, và PH-18 chỉ phát chỉ số, sự kiện vượt ngưỡng cho PH-13 chứ không tự cảnh báo.

```{.mermaid caption="Use case thông báo, Việc của tôi và lịch (nhóm E, F)"}
flowchart TB
  TA([TA])
  US([Người dùng])
  DU[[DU gọi thông báo, việc]]
  MAIL[[Máy chủ thư, SMS]]
  subgraph E["Thông báo"]
  U20(UC-18-20 Mẫu thông báo, trường cấm)
  U21(UC-18-21 Gửi, phân giải người nhận)
  U22(UC-18-22 Tùy chọn nhận, giờ yên lặng)
  U23(UC-18-23 Quy tắc theo sự kiện)
  U24(UC-18-24 Thư trả lại, nhật ký gửi)
  end
  subgraph F["Việc và lịch"]
  U25(UC-18-25 Loại việc, tạo, đóng việc)
  U26(UC-18-26 Việc của tôi, nhắc)
  U27(UC-18-27 Lịch, bảo trì, đóng băng)
  end
  TA --- U20 & U23 & U24 & U27
  US --- U22 & U26
  DU --- U21 & U25 & U27
  MAIL --- U21 & U24
```

Hình cho thấy phân hệ khác gửi thông báo và tạo việc bằng tham chiếu người nhận, còn địa chỉ chỉ PH-18 phân giải; người dùng tự quản tùy chọn nhận của mình nhưng không tắt được nhóm bắt buộc.

```{.mermaid caption="Use case sự cố vận hành, sao lưu và khôi phục (nhóm G, H)"}
flowchart TB
  TO([TO, SO])
  TA([TA])
  PA([PA, PO])
  P13[[PH-13]]
  P09[[PH-09]]
  P20[[PH-20]]
  subgraph G["Sự cố vận hành"]
  U28(UC-18-28 Mở, xử lý, đóng sự cố)
  U29(UC-18-29 Chuyển sự cố sang PH-09)
  end
  subgraph H["Sao lưu và khôi phục"]
  U30(UC-18-30 Sao lưu, kiểm tra, diễn tập)
  U31(UC-18-31 Khôi phục tenant tám bước)
  U32(UC-18-32 Xuất dữ liệu tenant)
  U33(UC-18-33 Chuyển dữ liệu sáp nhập)
  end
  P13 --- U28
  TO --- U28 & U29
  P09 --- U29
  PA --- U30 & U31 & U32
  TA --- U31
  P20 --- U32 & U33
```

Hình cho thấy sự cố có thể mở tự động từ cảnh báo PH-13, khôi phục tenant cần TA tạo và PA duyệt, còn sáp nhập do PH-20 điều phối và PH-18 chỉ chạy chuyển dữ liệu từng phân hệ.

```{.mermaid caption="Use case di trú hệ cũ, chạy song song và quản trị (nhóm I, J)"}
flowchart TB
  TA([TA, PA])
  AP([Người duyệt])
  DS([DS])
  AU([AU, PO])
  P03[[PH-03, PH-10]]
  subgraph I["Di trú và chạy song song"]
  U34(UC-18-34 Nguồn hệ cũ, kế hoạch)
  U35(UC-18-35 Chạy thử, đối chiếu, lỗi)
  U36(UC-18-36 Chạy thật bốn mắt)
  U37(UC-18-37 Chạy song song, đối soát bóng)
  U38(UC-18-38 Cắt chuyển, quay lui)
  end
  subgraph J["Quản trị"]
  U39(UC-18-39 Nhật ký, báo cáo vận hành)
  U40(UC-18-40 Sức khỏe, chế độ suy giảm)
  end
  TA --- U34 & U35 & U36 & U37 & U38
  AP --- U36 & U38
  DS --- U35
  P03 --- U37 & U38
  AU --- U39 & U40
```

Hình cho thấy di trú đi theo bậc thang chạy thử, chạy thật có duyệt, chạy song song rồi mới cắt chuyển; mỗi bậc có điều kiện vào kiểm chứng được.

## 5. Bảng tổng hợp use case và truy vết

Bốn bảng dưới đây nối use case với FR, màn hình, API, yêu cầu nghiệp vụ và chức năng hệ cũ, và đảo chiều từ FR về use case để kiểm tra độ phủ. Cả 57 FR mức M, 12 FR mức S và 3 FR mức C đều thuộc ít nhất một use case.

### 5.1. Use case và FR

Mức ưu tiên của use case là mức cao nhất trong các FR của nó; tác nhân chính lấy theo mục "Tác nhân chính" của khối đặc tả. Cột FR ghi số của FR-18-nnn.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-18-01 | Đăng ký lược đồ tham số và đọc tham số có bộ đệm | DU phân hệ chủ | M | 001, 002, 006 |
| UC-18-02 | Sửa giá trị tham số trên màn tham số chung | TA (Mai), PA (Hà) | M | 003, 007, 069 |
| UC-18-03 | Đề nghị và duyệt bốn mắt tham số bảo mật ★ | TA (Mai), SO (Dũng) | M | 004 |
| UC-18-04 | Xem lịch sử, so sánh và khôi phục phiên bản tham số | TA (Mai) | M | 005 |
| UC-18-05 | Xuất, nhập gói tham số giữa môi trường | PA (Hà) | C | 008 |
| UC-18-06 | Quản lý cờ tính năng và danh sách egress cho phép | PA (Hà), TA (Mai) | M | 009, 010 |
| UC-18-07 | Ghi tham số mặc định khi khởi tạo tenant | PH-20 | M | 011 |
| UC-18-08 | Đăng ký nguồn DLQ và cổng phát lại | DU nguồn, PA (Hà) | M | 012 |
| UC-18-09 | Tiếp nhận bản tin lỗi từ topic, kiểm ngữ cảnh và đối soát với Kafka | Hệ thống, TO (Chi) | M | 013, 015, 016, 018 |
| UC-18-10 | Phân hệ ghi mục DLQ qua API | DU nguồn (PH-19) | M | 014, 015, 016 |
| UC-18-11 | Xem và đề nghị phát lại DLQ tầng sự kiện của PH-10 | TO (Chi) | M | 017 |
| UC-18-12 | Lọc, gom nhóm, phân loại và gán người xử lý mục DLQ | TO (Chi) | M | 019, 020, 023 |
| UC-18-13 | Xem chi tiết, ngữ cảnh chẩn đoán và nội dung mục DLQ có lý do | TO (Chi), SO (Dũng) | M | 021, 022 |
| UC-18-14 | Sửa payload có kiểm soát và duyệt bốn mắt | IE (Quân), TA (Tuấn) | M | 024 |
| UC-18-15 | Biên soạn sổ tay xử lý theo mã lỗi và cấp API đọc cho PH-17 | PA (Hà), PH-17 | S | 025, 026 |
| UC-18-16 | Phát lại một mục DLQ và nhận kết quả lũy đẳng | TO (Chi) | M | 027, 030 |
| UC-18-17 | Phát lại loạt có duyệt bốn mắt và điều khiển lượt | TO (Chi), TA (Tuấn) | M | 028, 029, 030 |
| UC-18-18 | Bỏ qua và mở lại mục DLQ | TO (Chi) | M | 031, 032 |
| UC-18-19 | Lưu giữ, dọn, thống kê DLQ và phát sự kiện vượt ngưỡng | Hệ thống, TO (Chi) | M | 033, 034 |
| UC-18-20 | Soạn, kiểm trường cấm và duyệt mẫu thông báo | TA (Mai), TA (Tuấn) | M | 035 |
| UC-18-21 | Phân hệ gửi thông báo và phân giải người nhận | DU gọi (PH-01) | M | 036, 037 |
| UC-18-22 | Đặt tùy chọn nhận, giờ yên lặng và đọc thông báo trong ứng dụng | Người dùng (Quân) | M | 038 |
| UC-18-23 | Cấu hình quy tắc thông báo theo sự kiện | TA (Mai) | M | 039 |
| UC-18-24 | Xử lý thư trả lại, danh sách chặn và tra nhật ký gửi | Hệ thống, TA (Mai) | M | 040, 041 |
| UC-18-25 | Phân hệ đăng ký loại việc, tạo và đóng việc lũy đẳng | DU (PH-02) | M | 042, 043 |
| UC-18-26 | Xử lý Việc của tôi, nhắc và quá hạn | Người dùng (Tuấn) | M | 044 |
| UC-18-27 | Quản lý lịch ngày làm việc, cửa sổ bảo trì và đóng băng | TA (Mai), PA (Hà) | M | 045, 046 |
| UC-18-28 | Mở, xử lý và đóng sự cố vận hành | TO (Chi), SO (Dũng) | M | 047, 048, 049, 051 |
| UC-18-29 | Chuyển sự cố có dữ liệu cá nhân sang PH-09 | SO (Dũng) | S | 050 |
| UC-18-30 | Theo dõi sao lưu, kiểm tra khôi phục và ghi nhận diễn tập DR | PO (Khoa), PA (Hà) | M | 052, 053, 058 |
| UC-18-31 | Yêu cầu, duyệt và chạy khôi phục tenant tám bước | TA (Mai), PA (Hà) | M | 054, 055 |
| UC-18-32 | Xuất dữ liệu tenant | PA (Hà) | M | 056 |
| UC-18-33 | Chuyển dữ liệu phân hệ khi sáp nhập tenant theo yêu cầu PH-20 | PH-20 | S | 057 |
| UC-18-34 | Khai báo nguồn hệ cũ và lập kế hoạch di trú | TA (Mai) | M | 059, 060 |
| UC-18-35 | Chạy thử di trú, đối chiếu và xử lý bản ghi lỗi | TA (Mai), DS (Lan) | M | 061, 063, 064 |
| UC-18-36 | Chạy thật di trú có duyệt bốn mắt và đánh dấu cấp lại xác thực | TA (Mai), PA (Hà) | M | 062, 064, 065 |
| UC-18-37 | Theo dõi chạy song song và đối soát bóng | TA (Mai) | S | 066, 067 |
| UC-18-38 | Cắt chuyển nhóm dịch vụ và quay lui | TA (Mai), TA (Tuấn) | M | 068 |
| UC-18-39 | Tra nhật ký thao tác và lập báo cáo vận hành định kỳ | AU (Phúc), TA (Mai) | M | 070, 071 |
| UC-18-40 | Theo dõi sức khỏe và chạy ở chế độ suy giảm | PO (Khoa), PA (Hà) | M | 072 |

: Use case của PH-18 và FR hiện thực

### 5.2. Use case, màn hình và API

Mỗi use case có ít nhất một màn hình hoặc API. UC-18-07, 10, 25 là use case máy với máy nên kết quả chỉ xem ở màn tổng; UC-18-15 phần cho PH-17 hiển thị ở UI-17-03. Cột API ghi số của API-18-nnn.

| UC | Màn hình | API |
|---|---|---|
| UC-18-01 | UI-18-08, UI-18-24 | 001, 002, 003, 004, 005, 016, 027, 028, 029 |
| UC-18-02 | UI-18-08 | 001, 002, 004, 005, 006, 007 |
| UC-18-03 | UI-18-08, UI-18-09, UI-18-15 | 006, 008, 009, 010, 011, 012 |
| UC-18-04 | UI-18-09 | 003, 013, 014, 015, 016 |
| UC-18-05 | UI-18-08 | 017, 018, 019 |
| UC-18-06 | UI-18-10, UI-18-15 | 020, 021, 022, 023, 024, 025, 026, 028 |
| UC-18-07 | UI-18-08 (xem kết quả) | 030 |
| UC-18-08 | UI-18-06 | 031, 032, 033, 034 |
| UC-18-09 | UI-18-01, UI-18-03, UI-18-06, UI-18-24 | 037, 038 (topic `{tenant}.ops.dlq.v1`) |
| UC-18-10 | UI-18-01 | 035, 036 |
| UC-18-11 | UI-18-01 | 039, 040 |
| UC-18-12 | UI-18-01, UI-18-02 | 041, 042, 043, 044, 049, 050, 051, 063 |
| UC-18-13 | UI-18-03 | 045, 046, 047, 048, 058 |
| UC-18-14 | UI-18-03, UI-18-04, UI-18-15 | 052, 053, 054, 055, 056 |
| UC-18-15 | UI-18-07, UI-18-03 | 048, 057, 058, 059, 060, 061, 062 |
| UC-18-16 | UI-18-03 | 064, 076, 188 |
| UC-18-17 | UI-18-01, UI-18-02, UI-18-05, UI-18-15 | 065, 066, 067, 068, 069, 070, 071, 072, 073, 074, 075, 076 |
| UC-18-18 | UI-18-01, UI-18-03 | 077, 078, 079 |
| UC-18-19 | UI-18-06, UI-18-24 | 080, 081 |
| UC-18-20 | UI-18-11, UI-18-12, UI-18-15 | 082, 083, 084, 085, 086, 087, 088, 089, 090 |
| UC-18-21 | UI-18-13 | 091, 092, 093, 094 |
| UC-18-22 | UI-18-14 | 095, 096, 097, 098 |
| UC-18-23 | UI-18-11 | 099, 100, 101 |
| UC-18-24 | UI-18-13 | 093, 102, 103, 104, 105, 106 |
| UC-18-25 | UI-18-15 | 107, 108, 109, 110 |
| UC-18-26 | UI-18-15 | 111, 112, 181 |
| UC-18-27 | UI-18-16 | 113, 114, 115, 116, 117, 118, 119, 120, 121, 122 |
| UC-18-28 | UI-18-17, UI-18-18 | 123, 124, 125, 126, 127, 128, 129, 131, 132 |
| UC-18-29 | UI-18-18 | 130 |
| UC-18-30 | UI-18-19 | 133, 134, 135, 136, 137, 154, 155 |
| UC-18-31 | UI-18-20, UI-18-15 | 138, 139, 140, 141, 142, 143, 144, 145, 146 |
| UC-18-32 | UI-18-20 | 147, 148, 149 |
| UC-18-33 | UI-18-20 | 150, 151, 152, 153 |
| UC-18-34 | UI-18-21 | 156, 157, 158, 159, 160, 161, 162, 163 |
| UC-18-35 | UI-18-21, UI-18-22 | 164, 165, 166, 169, 170, 171, 182 |
| UC-18-36 | UI-18-21, UI-18-22, UI-18-15 | 164, 165, 166, 167, 168, 169, 171, 172, 183 |
| UC-18-37 | UI-18-23 | 173, 174, 176, 184 |
| UC-18-38 | UI-18-23, UI-18-15 | 174, 175, 185 |
| UC-18-39 | UI-18-24, UI-18-03 | 016, 063, 081, 177, 178, 179 |
| UC-18-40 | UI-18-24 | 180, 186, 187 |

: Use case, màn hình và API

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

Nhóm A đến H và J truy về REQ-18, nhóm I truy về REQ-22. Quy trình theo D02-01: BP-07 giám sát, xử lý sự cố, báo cáo; BP-08 khởi tạo tenant tỉnh mới; BP-09 chuyển đổi từ hệ cũ. Cột LGC lấy theo FRS mục 11.1; "Không" là năng lực mới, "Gián tiếp" là hệ cũ là đối tượng di trú chứ không phải chức năng được thay.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-18-01 | REQ-18 | BP-08 | LGC-BUS-031 |
| UC-18-02 | REQ-18 | BP-07 | LGC-BUS-031 |
| UC-18-03 | REQ-18 | BP-07 | Không |
| UC-18-04 | REQ-18 | BP-07 | LGC-BUS-031 |
| UC-18-05 | REQ-18 | BP-08 | LGC-BUS-031 |
| UC-18-06 | REQ-18 | BP-07 | Không |
| UC-18-07 | REQ-18 | BP-08 | LGC-BUS-031 |
| UC-18-08 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-09 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-10 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-11 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-12 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-13 | REQ-18 | BP-07 | LGC-BUS-037, LGC-NFR-004 |
| UC-18-14 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-15 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-16 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-17 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-18 | REQ-18 | BP-07 | LGC-BUS-037 |
| UC-18-19 | REQ-18 | BP-07 | Không |
| UC-18-20 | REQ-18 | BP-07 | Không |
| UC-18-21 | REQ-18 | BP-07 | Không |
| UC-18-22 | REQ-18 | Không | Không |
| UC-18-23 | REQ-18 | BP-07 | Không |
| UC-18-24 | REQ-18 | BP-07 | Không |
| UC-18-25 | REQ-18 | Không | Không |
| UC-18-26 | REQ-18 | Không | Không |
| UC-18-27 | REQ-18 | BP-08 | Không |
| UC-18-28 | REQ-18 | BP-07 | LGC-NFR-004 |
| UC-18-29 | REQ-18 | BP-07 | Không |
| UC-18-30 | REQ-18 | BP-07, BP-08 | LGC-NFR-005 |
| UC-18-31 | REQ-18 | BP-07 | Không |
| UC-18-32 | REQ-18 | BP-08 | Không |
| UC-18-33 | REQ-18 | BP-08 | Không |
| UC-18-34 | REQ-22 | BP-09 | Gián tiếp: LGC-HUB-008, LGC-HUB-010, LGC-DMDC-001 |
| UC-18-35 | REQ-22 | BP-09 | Gián tiếp: như UC-18-34 |
| UC-18-36 | REQ-22 | BP-09 | Gián tiếp: như UC-18-34 |
| UC-18-37 | REQ-22 | BP-09 | Không |
| UC-18-38 | REQ-22 | BP-09 | Không |
| UC-18-39 | REQ-18 | BP-07 | Không |
| UC-18-40 | REQ-18 | BP-07 | LGC-NFR-001, LGC-NFR-006 |

: Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực (số hai chữ số, UC-18-nn). Không FR nào bị bỏ trống. FR-18-015, 016 có hai use case vì kiểm ngữ cảnh và khử trùng chạy ở cả hai đường vào DLQ; FR-18-030 có hai vì kết quả phát lại về cho cả mục đơn và lượt; FR-18-064 có hai vì báo cáo đối chiếu lập cho cả chạy thử và chạy thật.

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 01 | 025 | 15 | 049 | 28 |
| 002 | 01 | 026 | 15 | 050 | 29 |
| 003 | 02 | 027 | 16 | 051 | 28 |
| 004 | 03 | 028 | 17 | 052 | 30 |
| 005 | 04 | 029 | 17 | 053 | 30 |
| 006 | 01 | 030 | 16, 17 | 054 | 31 |
| 007 | 02 | 031 | 18 | 055 | 31 |
| 008 | 05 | 032 | 18 | 056 | 32 |
| 009 | 06 | 033 | 19 | 057 | 33 |
| 010 | 06 | 034 | 19 | 058 | 30 |
| 011 | 07 | 035 | 20 | 059 | 34 |
| 012 | 08 | 036 | 21 | 060 | 34 |
| 013 | 09 | 037 | 21 | 061 | 35 |
| 014 | 10 | 038 | 22 | 062 | 36 |
| 015 | 09, 10 | 039 | 23 | 063 | 35 |
| 016 | 09, 10 | 040 | 24 | 064 | 35, 36 |
| 017 | 11 | 041 | 24 | 065 | 36 |
| 018 | 09 | 042 | 25 | 066 | 37 |
| 019 | 12 | 043 | 25 | 067 | 37 |
| 020 | 12 | 044 | 26 | 068 | 38 |
| 021 | 13 | 045 | 27 | 069 | 02 |
| 022 | 13 | 046 | 27 | 070 | 39 |
| 023 | 12 | 047 | 28 | 071 | 39 |
| 024 | 14 | 048 | 28 | 072 | 40 |

: Ma trận FR và use case

## 6. Đặc tả chi tiết use case

Mỗi use case một mục `6.n` theo thứ tự UC-18-01 đến UC-18-40, nhóm theo nhóm A đến J của FRS. Ví dụ dùng nhân vật giả lập của tỉnh T68 (chương 2). Tham số nêu kèm giá trị mặc định của FRS mục 8.2.

| Nhóm FRS | Tên nhóm | Use case |
|---|---|---|
| A | Kho tham số và cờ tính năng | UC-18-01 đến UC-18-07 |
| B | Tiếp nhận DLQ | UC-18-08 đến UC-18-11 |
| C | Phân loại và xử lý | UC-18-12 đến UC-18-15 |
| D | Phát lại, bỏ qua, lưu giữ | UC-18-16 đến UC-18-19 |
| E | Thông báo | UC-18-20 đến UC-18-24 |
| F | Việc của tôi và lịch | UC-18-25 đến UC-18-27 |
| G | Sự cố vận hành | UC-18-28, UC-18-29 |
| H | Sao lưu và khôi phục | UC-18-30 đến UC-18-33 |
| I | Di trú hệ cũ và chạy song song | UC-18-34 đến UC-18-38 |
| J | Quản trị, kiểm toán, báo cáo | UC-18-39, UC-18-40 |

: Nhóm chức năng và use case tương ứng

### 6.1. UC-18-01 · Đăng ký lược đồ tham số và đọc tham số có bộ đệm

::: dac-ta
**Mục tiêu.** Mỗi phân hệ khai báo một lần lược đồ khóa tham số của mình rồi đọc giá trị theo tenant với bộ đệm ngắn, để đổi tham số có hiệu lực trong 60 giây mà không phải khởi động lại và PH-18 vắng cũng không làm phân hệ dừng.

**Tác nhân chính.** DU của phân hệ chủ (ví dụ `dh-integration` giữ không gian tên `04.`), scope `ops:param-register`, `ops:param-read`.

**Tác nhân phụ.** Registry tenant của PH-20 (kiểm tenant hoạt động); Kafka (EVT-18-01); thư viện khách `dh-ops-client`; PA (Hà) xem lược đồ ở UI-18-08.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-001, FR-18-002, FR-18-006.

**Truy vết.** REQ-18; LGC-BUS-031; NFR-00-052; ADR-180; ADR-042; BP-08.

**Tiền điều kiện.** Không gian tên `04.` đã được cấp cho `dh-integration` trong cấu hình triển khai; danh tính SPIFFE của DU hợp lệ; tenant T68 `ACTIVE` ở registry PH-20.

**Kích hoạt.** DU khởi động và gửi lược đồ; bộ đệm phía DU hết hạn sau `18.param.cache-ttl-seconds` (60 giây); DU nhận EVT-18-01 của không gian tên mình.

**Đảm bảo tối thiểu.** Lược đồ cũ giữ nguyên nếu lược đồ mới bị từ chối; DU luôn có giá trị để chạy (bản đệm cũ hoặc mặc định đóng gói) kể cả khi PH-18 không phản hồi (BR-18-007).

**Đảm bảo thành công.** `param_namespace`, `param_definition` của `04.` ở `tenant_id = COMMON` khớp lược đồ mới; DU nhận giá trị hiệu lực kèm `version`, `source` và `ETag`; sau mỗi lần đổi, DU tải lại trong tối đa 60 giây.

**Luồng chính.**
1. `dh-integration` gửi lược đồ `04.` kèm `schemaVersion` 7 (API-18-027). Hệ thống kiểm danh tính gọi là chủ của `04.`.
2. Hệ thống kiểm từng khóa: tiền tố khớp `04.`, kiểu thuộc tập cho phép, mặc định nằm trong miền và trong trần.
3. Hệ thống so với lược đồ đang lưu: thêm khóa mới, đánh dấu khóa không còn trong lược đồ là `DEPRECATED`; từ chối nếu đổi kiểu hoặc thu hẹp miền làm giá trị đang dùng ở tenant nào đó ra ngoài miền.
4. Hệ thống lưu lược đồ, ghi outbox EVT-18-01 loại `SCHEMA_CHANGED` và trả bản đối chiếu (thêm, đổi, bỏ).
5. Khi cần giá trị, DU gửi yêu cầu đọc lô cho T68 (API-18-028) kèm `If-None-Match`. Hệ thống kiểm tenant hoạt động theo registry PH-20, tính giá trị hiệu lực từng khóa (giá trị tenant `ACTIVE`, không có thì mặc định, kẹp bởi trần) và trả `version`, `source`, `ETag`; ảnh chụp không đổi thì trả `304`.
6. Khi có thay đổi, tác vụ outbox phát EVT-18-01 trong tối đa 5 giây sau commit với khóa phân vùng `tenant:ns`; `dh-ops-client` ở mỗi bản sao xóa mục đệm tương ứng và tải lại ở lần dùng kế tiếp; hệ thống ghi một dòng nhật ký đổi tham số (API-18-016).

**Luồng thay thế.**
- **1a. Lược đồ không đổi.** Cùng `schemaVersion` và cùng nội dung: hệ thống trả `200` không đổi gì (lũy đẳng). Chỉ đổi mô tả hoặc nhóm hiển thị: cập nhật ngay, không kiểm giá trị tenant.
- **5a. Đọc cả không gian tên khi khởi động.** DU gọi API-18-029 lấy ảnh chụp `04.` của T68.
- **5b. Khóa chưa đăng ký trong lô.** Hệ thống trả khóa đó trong `unknown[]`, các khóa khác vẫn có giá trị.
- **5c. PH-18 không phản hồi.** `dh-ops-client` dùng bản đệm cũ (không giới hạn tuổi), không có bản đệm thì dùng mặc định đóng gói theo lược đồ, và tăng `dh_ops_param_stale_total` để PH-13 cảnh báo (LP-18-04).
- **6a. Sự kiện đến trước bản sao CSDL.** Khách so `version` trong sự kiện với `version` đọc được; nhỏ hơn thì đọc lại sau 1 giây, tối đa 5 lần.

**Luồng ngoại lệ.**
- **E1. Không gian tên không thuộc phân hệ gọi (bước 1).** ERR-18-017 (403): "Phân hệ không sở hữu {đối tượng} {mã}." Hiện cho người vận hành ở UI-18-24.
- **E2. Lược đồ sai cấu trúc (bước 2).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E3. Lược đồ mới xung đột với giá trị đang dùng (bước 3).** ERR-18-016 (409): "Lược đồ mới của {ns} xung đột với giá trị đang dùng ở {số} tenant. Xem danh sách trong chi tiết."
- **E4. Tenant không tồn tại hoặc đã ngừng (bước 5).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}.".
- **E5. Quá 50 yêu cầu mỗi giây mỗi DU (bước 5).** ERR-18-010 (429): "Quá nhiều yêu cầu. Thử lại sau {giây} giây."
- **E6. Không phát được sự kiện sau 5 phút (bước 6).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ." UI-18-24 hiện thẻ sự kiện đổi tham số đang chậm; bộ đệm vẫn hết hạn sau 60 giây nên giá trị mới vẫn có hiệu lực.

**Quy tắc áp dụng.** BR-18-001; BR-18-002; BR-18-003; BR-18-006; BR-18-007; LP-18-04.

**Màn hình, API.** UI-18-08, UI-18-24; API-18-001, 002, 003, 004, 005, 016, 027, 028, 029.
:::

### 6.2. UC-18-02 · Sửa giá trị tham số trên màn tham số chung

::: dac-ta
**Mục tiêu.** Quản trị tỉnh chỉnh tham số của bất kỳ phân hệ nào (kể cả `18.*` của chính PH-18) trên một màn chung, trong miền và dưới trần do nền tảng đặt, có lý do và có phiên bản để truy lại.

**Tác nhân chính.** TA (Mai) cho khóa mức `TENANT`; PA (Hà) cho khóa mức `PLATFORM` và trần (`PERM-18-config`, `PERM-18-admin` với `18.*`).

**Tác nhân phụ.** Phân hệ nhúng màn tham số chung (ví dụ UI-04-20 của PH-04); PH-13 (kiểm toán); DU đọc lại giá trị qua UC-18-01.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-003, FR-18-007, FR-18-069.

**Truy vết.** REQ-18; LGC-BUS-031; FR-00-052; SEC-07; BP-07.

**Tiền điều kiện.** Khóa đã đăng ký, không `DEPRECATED` (UC-18-01); không gian tên có nhóm hiển thị; Mai có `PERM-18-config`; PH-18 không ở chế độ chỉ đọc.

**Kích hoạt.** Mai mở `/van-hanh/tham-so?ns=18.&nhom=dlq` hoặc màn nhúng của phân hệ, sửa giá trị rồi bấm "Lưu".

**Đảm bảo tối thiểu.** Khóa lưu lỗi giữ nguyên giá trị cũ; mỗi khóa được kiểm và lưu độc lập.

**Đảm bảo thành công.** Mỗi khóa hợp lệ có `param_value_version` mới `ACTIVE`, phiên bản cũ `SUPERSEDED`; EVT-18-01 phát trong cùng giao dịch qua outbox; giá trị mới có hiệu lực ở DU trong tối đa 60 giây.

**Luồng chính.**
1. Mai mở màn. Hệ thống tải lược đồ theo `ns`, `nhom` và giá trị hiệu lực của T68, hiển thị nhãn, mô tả, giá trị hiện hành, mặc định, miền, trần, cờ ★, phiên bản, người đổi gần nhất; khóa `PLATFORM` ở chế độ chỉ đọc cho TA.
2. Mai đổi `18.dlq.threshold.depth` từ 1.000 thành 2.000. Hệ thống kiểm tức thời bằng API-18-007 (kiểu, miền, trần) và hiện lỗi dưới ô nếu có.
3. Mai bấm "Lưu", nhập lý do chung "Tăng ngưỡng tồn DLQ trong đợt chạy song song hộ tịch". Hệ thống kiểm khóa đã đăng ký và lý do đủ `18.param.reason-min-length` (10 ký tự).
4. Hệ thống kiểm mức khóa (khóa `PLATFORM` chỉ PA ghi), kiểu, miền, trần nền tảng và `If-Match` với phiên bản hiện hành, cho từng khóa (API-18-006).
5. Khóa thường: hệ thống ghi kiểm toán, tạo phiên bản mới `ACTIVE`, chuyển phiên bản cũ sang `SUPERSEDED`, ghi outbox EVT-18-01. Khóa ★: chuyển sang UC-18-03.
6. Hệ thống hiện thanh đầu trang số khóa đã lưu; mô-đun dùng khóa đọc giá trị mới trong tối đa 60 giây, lượt phát lại và Job đang chạy giữ giá trị cũ tới lần tạo sau.

**Luồng thay thế.**
- **2a. Về mặc định.** Mai bấm "Về mặc định": giá trị mới là mặc định của lược đồ, vẫn tạo phiên bản.
- **3a. Một số khóa lỗi.** Khóa lỗi hiện mã và câu riêng dưới ô, các khóa khác vẫn lưu; thanh đầu trang "Đã lưu {n} tham số, {m} tham số lỗi."
- **4a. PA đặt trần.** Hà sửa trần của khóa `TENANT` ở chế độ nền tảng; giá trị tenant đang vượt trần mới bị kẹp khi đọc (nguồn `CEILING`) và hiện cảnh báo ở UI-18-08 của tenant đó.
- **1a. Màn nhúng.** Phân hệ nhúng thành phần với `ns`, `nhom` cố định và ẩn bộ lọc; nhóm có `editPermission` riêng (ví dụ `PERM-07-configure`) thì kiểm thêm quyền đó. Người không có quyền sửa thấy mọi ô chỉ đọc.

**Luồng ngoại lệ.**
- **E1. Khóa chưa đăng ký (bước 3).** ERR-18-011 (404): "Khóa {khóa} chưa được đăng ký."
- **E2. Thiếu lý do (bước 3).** ERR-18-007 (422): "Nhập lý do {thao tác} (ít nhất {n} ký tự).".
- **E3. TA ghi khóa mức nền tảng (bước 4).** ERR-18-015 (403): "Tham số {khóa} do quản trị nền tảng đặt, tỉnh chỉ xem được."
- **E4. Sai kiểu (bước 2, 4).** ERR-18-012 (422): "Giá trị của {khóa} phải có kiểu {kiểu}."
- **E5. Ngoài miền (bước 2, 4).** ERR-18-013 (422): "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}."
- **E6. Vượt trần nền tảng (bước 2, 4).** ERR-18-014 (422): "Giá trị vượt giới hạn nền tảng của {khóa} ({trần}). Liên hệ quản trị nền tảng nếu cần nâng."
- **E7. Phiên bản đã đổi (bước 4).** ERR-18-004 (412): "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu." Hộp thoại "Dữ liệu đã đổi" có nút "Tải lại".
- **E8. PH-18 ở chế độ chỉ đọc (bước 3).** ERR-18-071 (503): "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được."

**Quy tắc áp dụng.** BR-18-002; BR-18-003; BR-18-004; BR-18-005; BR-18-006; BR-18-049; LP-18-02; LP-18-03.

**Màn hình, API.** UI-18-08; API-18-001, 002, 004, 005, 006, 007.
:::

### 6.3. UC-18-03 · Đề nghị và duyệt bốn mắt tham số bảo mật ★

::: dac-ta
**Mục tiêu.** Đổi một tham số có ảnh hưởng an ninh (ví dụ ngưỡng phát lại cần duyệt, thời hạn phiếu xem payload, bắt buộc duyệt khôi phục) chỉ có hiệu lực khi người thứ hai đồng ý, để một tài khoản bị chiếm không tự nới lỏng được kiểm soát.

**Tác nhân chính.** TA (Mai) đề nghị (`PERM-18-config`); SO (Dũng), TA khác (Tuấn) hoặc PA duyệt (`PERM-18-approve`).

**Tác nhân phụ.** Việc của tôi (UC-18-26); PH-13 (kiểm toán); phân hệ khác giữ duyệt (PH-14, PH-17) khi `approvalOwner` không phải PH-18.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-004.

**Truy vết.** REQ-18; FR-00-071; SEC-07; ADR-046; BP-07.

**Tiền điều kiện.** Khóa `18.dlq.replay.approval-threshold` có `secure = true`, `approvalOwner = PH-18`; chưa có đề nghị khác chờ duyệt cho cùng khóa và tenant.

**Kích hoạt.** UC-18-02 bước 5 gặp khóa ★; Dũng mở việc `ph18.approve-param` trong Việc của tôi.

**Đảm bảo tối thiểu.** Giá trị cũ giữ nguyên tới khi có quyết định; không ghi được kiểm toán thì không đổi trạng thái.

**Đảm bảo thành công.** Phiên bản đề nghị `ACTIVE`, phiên bản cũ `SUPERSEDED`, EVT-18-01 phát, việc duyệt đóng; hoặc phiên bản `REJECTED` và người đề nghị được báo.

**Luồng chính.**
1. Mai đổi `18.dlq.replay.approval-threshold` từ 500 thành 300 kèm lý do. Hệ thống kiểm chưa có đề nghị chờ cho khóa, tạo `param_change_request` và phiên bản `PENDING_APPROVAL`, phát EVT-18-02.
2. Hệ thống tạo việc `ph18.approve-param` cho người có `PERM-18-approve` trong T68 trừ Mai; việc hết hạn sau `18.param.change-request-ttl-hours` (72 giờ).
3. Dũng mở việc, xem giá trị trước, sau, lý do, người đề nghị (API-18-009). Hệ thống kiểm Dũng khác Mai.
4. Dũng bấm "Duyệt" (API-18-010). Hệ thống kiểm lại miền và trần theo lược đồ hiện hành và ghi kiểm toán trước khi đổi.
5. Hệ thống đặt phiên bản `ACTIVE`, phiên bản cũ `SUPERSEDED`, phát EVT-18-01, đóng việc và báo Mai.

**Luồng thay thế.**
- **1a. Khóa do phân hệ khác giữ duyệt.** Khóa có `approvalOwner = PH-17`: hệ thống trả lỗi và hướng Mai sang màn của PH-17; PH-18 chỉ nhận giá trị đã duyệt từ danh tính dịch vụ của PH-17 kèm `approvalRef` qua API-18-006.
- **3a. Rút đề nghị.** Mai bấm "Rút" trước khi có người duyệt (API-18-012): phiên bản `REJECTED` với lý do "rút", việc đóng.
- **4a. Từ chối.** Dũng từ chối kèm lý do (API-18-011): phiên bản `REJECTED`, giá trị cũ giữ nguyên, Mai nhận thông báo.
- **2a. Quá hạn duyệt.** Sau 72 giờ không ai quyết định: đề nghị hết hạn như bị từ chối, Mai được báo để đề nghị lại.

**Luồng ngoại lệ.**
- **E1. Đã có đề nghị chờ duyệt (bước 1).** ERR-18-018 (409): "Tham số {khóa} đang có đề nghị chờ duyệt của {người}. Chờ duyệt xong hoặc rút đề nghị."
- **E2. Khóa do phân hệ khác giữ duyệt (nhánh 1a).** ERR-18-019 (409): "Tham số {khóa} được duyệt tại {phân hệ}. Mở màn {phân hệ} để đề nghị thay đổi."
- **E3. Người duyệt trùng người đề nghị (bước 3).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."
- **E4. Lược đồ đã đổi làm giá trị đề nghị không còn hợp lệ (bước 4).** ERR-18-013 (422): "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}."
- **E5. PH-13 không ghi được kiểm toán (bước 4).** ERR-18-008 (503): "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."

**Quy tắc áp dụng.** BR-18-004; BR-18-005; BR-18-046; LP-18-01; LP-18-02.

**Màn hình, API.** UI-18-08, UI-18-09, UI-18-15; API-18-006, 008, 009, 010, 011, 012.
:::

```{.mermaid caption="Trình tự đề nghị và duyệt bốn mắt tham số bảo mật"}
sequenceDiagram
  actor TA as TA Mai
  actor SO as SO Dũng
  participant O as dh-platform ops
  participant K as PH-13 kiểm toán
  participant D as DU dùng khóa
  TA->>O: Ghi khóa bảo mật kèm lý do (API-18-006)
  O->>O: Tạo đề nghị PENDING_APPROVAL, phát EVT-18-02
  O-->>SO: Việc ph18.approve-param trong Việc của tôi
  SO->>O: Duyệt đề nghị (API-18-010)
  O->>O: Kiểm người duyệt khác người đề nghị, kiểm lại miền và trần
  O->>K: Ghi kiểm toán trước khi đổi
  K-->>O: Đã ghi
  O->>O: Phiên bản ACTIVE, phiên bản cũ SUPERSEDED
  O-->>D: EVT-18-01, làm mới bộ đệm trong 60 giây
```

Hình cho thấy giá trị mới chỉ có hiệu lực sau khi người thứ hai duyệt và kiểm toán đã ghi; phân hệ dùng khóa nhận thay đổi qua sự kiện, không cần khởi động lại.

### 6.4. UC-18-04 · Xem lịch sử, so sánh và khôi phục phiên bản tham số

::: dac-ta
**Mục tiêu.** Người vận hành biết ai đổi tham số nào, khi nào, vì sao, so được hai phiên bản và đưa tham số về giá trị cũ khi thay đổi gây lỗi, mà không mất dấu các phiên bản trung gian.

**Tác nhân chính.** TA (Mai); người có `PERM-18-read` xem, TA và PA khôi phục (`PERM-18-config`).

**Tác nhân phụ.** PH-13 (kiểm toán); UC-18-03 khi khóa ★.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-005.

**Truy vết.** REQ-18; LGC-BUS-031; FR-00-052; BP-07.

**Tiền điều kiện.** Khóa `18.dlq.replay.rate-per-second` có ít nhất hai phiên bản ở T68.

**Kích hoạt.** Mai mở tab "Lịch sử" của khóa ở UI-18-09, chọn hai phiên bản hoặc bấm "Khôi phục phiên bản này".

**Đảm bảo tối thiểu.** Không phiên bản nào bị xóa hay sửa; khôi phục lỗi thì giá trị hiện hành giữ nguyên.

**Đảm bảo thành công.** Một phiên bản mới mang giá trị cũ ở trạng thái `ACTIVE` (hoặc `PENDING_APPROVAL` với khóa ★); EVT-18-01 phát.

**Luồng chính.**
1. Mai mở lịch sử (API-18-013). Hệ thống trả danh sách phiên bản giảm dần kèm người, thời điểm, lý do, trạng thái.
2. Mai chọn phiên bản 4 và 6 (API-18-014). Hệ thống trả khác biệt theo kiểu: số thì giá trị cũ, mới; danh sách thì thêm, bớt; JSON thì khác biệt theo đường dẫn.
3. Mai bấm "Khôi phục phiên bản này" trên phiên bản 4, nhập lý do "Tốc độ 20 mục mỗi giây làm quá tải đích hộ tịch" (API-18-015). Hệ thống kiểm lý do và kiểm giá trị cũ còn hợp lệ với lược đồ hiện hành.
4. Hệ thống ghi giá trị của phiên bản 4 thành phiên bản 7 theo đúng UC-18-02 bước 4 và 5, phát EVT-18-01.

**Luồng thay thế.**
- **2a. So với mặc định.** Mai chọn so với mặc định của lược đồ (`to = default`).
- **1a. Nhật ký đổi toàn tenant.** Mai mở nhật ký đổi theo thời gian của mọi khóa (API-18-016).
- **4a. Khóa ★.** Phiên bản 7 ở `PENDING_APPROVAL` và đi tiếp theo UC-18-03.

**Luồng ngoại lệ.**
- **E1. Không tìm thấy phiên bản (bước 2, 3).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}."
- **E2. Giá trị cũ không còn hợp lệ với lược đồ mới (bước 3).** ERR-18-023 (409): "Phiên bản {số} không còn hợp lệ với lược đồ hiện hành của {khóa}: {lý do}."
- **E3. Thiếu lý do (bước 3).** ERR-18-007 (422): "Nhập lý do {thao tác} (ít nhất {n} ký tự)."

**Quy tắc áp dụng.** BR-18-005; LP-18-02; LP-18-03.

**Màn hình, API.** UI-18-09; API-18-003, 013, 014, 015, 016.
:::

### 6.5. UC-18-05 · Xuất, nhập gói tham số giữa môi trường

::: dac-ta
**Mục tiêu.** Quản trị nền tảng chuyển bộ tham số đã kiểm ở môi trường thử sang môi trường thật bằng một gói có tổng kiểm tra, xem trước khác biệt và không bỏ qua được bốn mắt của khóa ★.

**Tác nhân chính.** PA (Hà), `PERM-18-admin`.

**Tác nhân phụ.** Người duyệt khóa ★ (`PERM-18-approve`, UC-18-03); PH-13 (kiểm toán).

**Mức ưu tiên.** C · MVP.

**FR hiện thực.** FR-18-008.

**Truy vết.** REQ-18; LGC-BUS-031; SEC-07; BP-08.

**Tiền điều kiện.** Lược đồ ở môi trường đích đã đăng ký cùng hoặc mới hơn `schemaVersion` của gói.

**Kích hoạt.** Hà bấm "Xuất gói" ở môi trường thử hoặc "Nhập gói" ở môi trường thật, UI-18-08 tab "Gói tham số".

**Đảm bảo tối thiểu.** Gói hỏng không áp được khóa nào; khóa lỗi không làm hỏng khóa khác.

**Đảm bảo thành công.** Khóa thường có phiên bản mới `ACTIVE`; khóa ★ gom thành một đề nghị chờ duyệt; bản so khớp được lưu cùng `param_bundle`.

**Luồng chính.**
1. Hà chọn không gian tên `04.` và `18.` rồi bấm "Xuất gói" (API-18-017). Hệ thống tạo gói JSON gồm khóa, giá trị, `schemaVersion`, SHA-256 toàn gói và lưu `param_bundle`.
2. Ở môi trường thật, Hà nạp gói (API-18-018). Hệ thống kiểm tổng kiểm tra và cấu trúc.
3. Hệ thống so khớp từng khóa với lược đồ đích và trả bảng khác biệt (thêm, đổi, giữ nguyên) cùng danh sách khóa chưa đăng ký, sai kiểu, ngoài miền, vượt trần.
4. Hà bấm "Áp" (API-18-019). Hệ thống ghi từng khóa thường theo UC-18-02 và gom khóa ★ thành một đề nghị, phát EVT-18-02.

**Luồng thay thế.**
- **3a. Chỉ xem khác biệt.** Hà dừng sau bước 3, không áp.

**Luồng ngoại lệ.**
- **E1. Gói hỏng hoặc khác tổng kiểm tra (bước 2).** ERR-18-020 (422): "Gói tham số không hợp lệ hoặc đã bị sửa: {chi tiết}."
- **E2. Khóa sai lược đồ (bước 3, 4).** ERR-18-013 (422) cho từng khóa: "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}."

**Quy tắc áp dụng.** BR-18-002; BR-18-004; BR-18-048; LP-18-01.

**Màn hình, API.** UI-18-08; API-18-017, 018, 019.
:::

### 6.6. UC-18-06 · Quản lý cờ tính năng và danh sách egress cho phép

::: dac-ta
**Mục tiêu.** Nền tảng bật tắt tính năng theo tỉnh bằng cờ có chủ sở hữu và hạn gỡ, và tỉnh khai báo đích gọi ra Internet được phép (egress) ở một chỗ để PH-03, PH-13, PH-15 cùng áp.

**Tác nhân chính.** PA (Hà) khai báo, gỡ cờ (`PERM-18-admin`); TA (Mai) bật tắt cờ, khai báo egress (`PERM-18-config`).

**Tác nhân phụ.** DU đọc cờ và egress (`ops:param-read`); PH-03 cập nhật tuyến egress; PH-13 cập nhật danh sách egress giám sát; SO (Dũng) xem.

**Mức ưu tiên.** M · MVP (egress: S · Đợt 2).

**FR hiện thực.** FR-18-009, FR-18-010.

**Truy vết.** REQ-18; QT-BR-03; CC-CFG-04; SEC-16; Q15-10; BP-07.

**Tiền điều kiện.** Cờ được khai báo trước khi mã dùng nó được triển khai; khóa `18.egress.allowlist` kiểu `LIST<HOST>` đã có trong lược đồ PH-18.

**Kích hoạt.** Hà bấm "+ Cờ tính năng"; Mai bật công tắc cờ hoặc bấm "+ Đích egress" ở UI-18-10; tác vụ hằng ngày kiểm ngày gỡ và hạn dùng.

**Đảm bảo tối thiểu.** Cờ quá ngày gỡ không bị tự tắt (BR-18-008); đích egress không hợp lệ không vào danh sách.

**Đảm bảo thành công.** Cờ `ff.dlq.goi-y-phat-lai` có giá trị tenant mới, EVT-18-03 phát; đích egress có hạn dùng, EVT-18-04 phát và PH-03 cập nhật tuyến.

**Luồng chính.**
1. Hà khai báo cờ `ff.dlq.goi-y-phat-lai`, chủ sở hữu PH-18, ngày gỡ 30/09/2027 (API-18-021). Hệ thống kiểm mẫu khóa `^ff\.[a-z0-9-]+\.[a-z0-9-]+$`, có chủ sở hữu, ngày gỡ trong 365 ngày và chưa trùng.
2. Mai bật cờ cho T68 kèm lý do (API-18-022). Hệ thống kiểm `If-Match`, lưu giá trị tenant, phát EVT-18-03.
3. Mai bấm "+ Đích egress", nhập `api.vneid.gov.vn`, cổng 443, mục đích "tra cứu định danh" (API-18-025). Hệ thống kiểm FQDN hợp lệ, HTTPS, không phải IP literal, không thuộc dải nội bộ, ký tự đại diện tối đa một cấp bên trái.
4. Hệ thống kiểm số mục không vượt `18.egress.max-entries` (200) và không trùng, lưu mục với hạn dùng 365 ngày, ghi kiểm toán, phát EVT-18-04.
5. Tác vụ hằng ngày tạo việc `ph18.ff-retire` cho chủ sở hữu khi cờ còn tối đa `18.ff.retire-warning-days` (14) ngày tới ngày gỡ, và tạo việc cho TA 14 ngày trước khi đích egress hết hạn.

**Luồng thay thế.**
- **2a. Cờ mức nền tảng.** Chỉ PA bật tắt, áp cho mọi tenant.
- **3a. Gỡ đích egress.** Mai bấm "Gỡ" kèm lý do (API-18-026); phát EVT-18-04.
- **5a. Gỡ cờ.** Hà gỡ cờ khi mã đã bỏ nhánh (API-18-023): cờ `RETIRED`, DU đọc nhận `unknown`.
- **5b. Đích hết hạn.** Tác vụ đánh dấu mục `EXPIRED`, phát EVT-18-04.

**Luồng ngoại lệ.**
- **E1. Cờ thiếu chủ sở hữu hoặc ngày gỡ (bước 1).** ERR-18-021 (422): "Cờ tính năng cần chủ sở hữu và ngày gỡ dự kiến trong vòng 365 ngày."
- **E2. Khóa cờ hoặc đích đã có (bước 1, 4).** ERR-18-002 (409): "Mã {mã} đã được dùng. Chọn mã khác."
- **E3. Đích nội bộ, IP hoặc không HTTPS (bước 3).** ERR-18-022 (422): "Đích {đích} không được phép: chỉ chấp nhận tên miền công khai qua HTTPS."
- **E4. Danh sách đã đủ số mục (bước 4).** ERR-18-013 (422): "Giá trị {giá trị} nằm ngoài miền cho phép của {trường}: {miền}.".
- **E5. Phiên bản cờ đã đổi (bước 2).** ERR-18-004 (412): "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu."

**Quy tắc áp dụng.** BR-18-008; BR-18-009; LP-18-03.

**Màn hình, API.** UI-18-10, UI-18-15; API-18-020, 021, 022, 023, 024, 025, 026, 028.
:::

### 6.7. UC-18-07 · Ghi tham số mặc định khi khởi tạo tenant

::: dac-ta
**Mục tiêu.** Một tỉnh mới có ngay bộ tham số, lịch ngày làm việc và đối tượng sao lưu mặc định khi PH-20 khởi tạo tenant, chạy lại bao nhiêu lần cũng không ghi đè giá trị tỉnh đã chỉnh.

**Tác nhân chính.** PH-20 (scope `ops:param-write`).

**Tác nhân phụ.** Registry tenant PH-20; UC-18-27 (lịch); UC-18-30 (đối tượng sao lưu); Kafka (sự kiện `platform.tenant.created.v1`).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-011.

**Truy vết.** REQ-18; LGC-BUS-031; BP-08.

**Tiền điều kiện.** Tenant `T68` có trong registry PH-20 ở trạng thái `PROVISIONING` hoặc `ACTIVE`.

**Kích hoạt.** PH-20 gọi API seed trong bước khởi tạo; hoặc PH-18 tiêu thụ `platform.tenant.created.v1`.

**Đảm bảo tối thiểu.** Khóa đã có giá trị không bị đổi (BR-18-010); lỗi giữa chừng không để lại nửa bộ vì lần chạy sau chỉ thêm khóa còn thiếu.

**Đảm bảo thành công.** Mọi khóa đã đăng ký có giá trị hoặc dùng mặc định lược đồ; lịch năm hiện hành và năm sau sao từ `COMMON`; đối tượng sao lưu mức tenant được bật; một EVT-18-01 tổng hợp và EVT-18-15 phát.

**Luồng chính.**
1. PH-20 gọi API-18-030 cho T68 kèm hồ sơ tham số "tỉnh vừa". Hệ thống kiểm T68 có trong registry qua `/internal/tenant/v1/tenants`.
2. Hệ thống duyệt mọi lược đồ đã đăng ký; với mỗi khóa chưa có giá trị cho T68 thì ghi mặc định của hồ sơ (hoặc của lược đồ), bỏ qua khóa đã có.
3. Hệ thống tạo lịch năm 2027 và 2028 từ lịch `COMMON` và bật đối tượng sao lưu mức tenant.
4. Hệ thống trả số khóa đã thêm, số khóa giữ nguyên, phát một EVT-18-01 tổng hợp và EVT-18-15.

**Luồng thay thế.**
- **1a. Kích hoạt từ sự kiện.** PH-18 nhận `platform.tenant.created.v1` qua inbox (khử trùng theo `eventId`) và chạy bước 2 đến 4.
- **2a. Phân hệ đăng ký lược đồ sau khi tenant đã tạo.** Khóa mới không cần seed vì đọc trả mặc định lược đồ (UC-18-01 bước 5).
- **1b. Gọi lại.** PH-20 gọi lại sau lỗi mạng: hệ thống trả kết quả "0 khóa thêm", không đổi gì.

**Luồng ngoại lệ.**
- **E1. Tenant không có trong registry (bước 1).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}.".
- **E2. PH-18 không sẵn sàng (bước 1).** ERR-18-071 (503): "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được." PH-20 thử lại theo lịch của mình và hiện ở màn khởi tạo tenant.
- **E3. Registry PH-20 không phản hồi khi chạy từ sự kiện (nhánh 1a).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ." Inbox `FAILED`, hiện ở UI-18-24 (LP-18-06).

**Quy tắc áp dụng.** BR-18-010; LP-18-06.

**Màn hình, API.** Không có màn riêng (kết quả xem ở UI-18-08); API-18-030.
:::

### 6.8. UC-18-08 · Đăng ký nguồn DLQ và cổng phát lại

::: dac-ta
**Mục tiêu.** Mỗi phân hệ sinh bản tin lỗi khai báo mình là nguồn DLQ và cách nhận lại bản tin khi phát lại, để PH-18 biết đẩy bản tin về đâu mà không gọi thẳng hệ đích.

**Tác nhân chính.** DU nguồn tự đăng ký (scope `ops:dlq-write`), ví dụ `dh-runtime-t68`; PA (Hà) khai báo, sửa, tạm ngừng (`PERM-18-admin`).

**Tác nhân phụ.** PH-13 (kiểm toán); TO (Chi) xem ở UI-18-06.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-012.

**Truy vết.** REQ-18; LGC-BUS-037; ADR-182; BP-07.

**Tiền điều kiện.** DU nguồn có danh tính SPIFFE; với cổng `HTTP_PORT` thì đường dẫn nằm trong `/…/internal/v1` của DU nguồn.

**Kích hoạt.** DU nguồn khởi động và gửi thông tin nguồn; hoặc Hà bấm "+ Nguồn" ở UI-18-06 tab "Nguồn".

**Đảm bảo tối thiểu.** Mục DLQ của nguồn chưa đăng ký vẫn được nhận, gắn `sourceStatus = UNREGISTERED` và không phát lại được.

**Đảm bảo thành công.** `dlq_source` `ph04-runtime` ở `ACTIVE` với cổng `KAFKA_TOPIC`, `supportsRevision`, trần tốc độ; kiểm toán đã ghi.

**Luồng chính.**
1. `dh-runtime-t68` gửi thông tin nguồn `ph04-runtime`, `sourcePh = PH-04` (API-18-034). Hệ thống kiểm `sourceCode` theo mẫu `^[a-z0-9-]{3,40}$` và `sourcePh` khớp danh tính gọi.
2. Hệ thống kiểm cổng phát lại: `KAFKA_TOPIC` phải là `{tenant}.ops.replay.requested.v1`; `HTTP_PORT` phải là URL nội bộ cụm; `EVENT_LAYER` chỉ cho `sourcePh = PH-10`; `NONE` hợp lệ.
3. Hệ thống lưu hoặc cập nhật `dlq_source` lũy đẳng theo `sourceCode`, ghi kiểm toán.
4. Hệ thống trả nguồn ở `ACTIVE`; UI-18-06 hiện nguồn kèm cổng, trần tốc độ và số mục đang mở.

**Luồng thay thế.**
- **1a. PA khai báo tay.** Hà nhập nguồn ở UI-18-06 (API-18-032) cho nguồn không tự đăng ký được.
- **3a. Tạm ngừng nguồn.** Hà đặt nguồn `SUSPENDED` (API-18-033): mục vẫn được nhận, mọi phát lại bị chặn tới khi bật lại.

**Luồng ngoại lệ.**
- **E1. Danh tính gọi không khớp phân hệ nguồn (bước 1).** ERR-18-026 (403): "Nguồn {mã} chưa được đăng ký hoặc đang tạm ngừng ghi DLQ." Hiện ở UI-18-06.
- **E2. Cổng phát lại không hợp lệ (bước 2).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-18-019; BR-18-022; LP-18-02.

**Màn hình, API.** UI-18-06; API-18-031, 032, 033, 034.
:::

### 6.9. UC-18-09 · Tiếp nhận bản tin lỗi từ topic, kiểm ngữ cảnh và đối soát với Kafka

::: dac-ta
**Mục tiêu.** Mọi bản tin lỗi mà runtime đẩy vào topic DLQ chung được lập chỉ mục bền, đủ ngữ cảnh để chẩn đoán và phát lại, không trùng, không mất, kể cả khi PH-18 ngừng một lúc.

**Tác nhân chính.** Hệ thống (consumer `ops-dlq-ingest`); TO (Chi) chạy đối soát tay (`PERM-18-dlq`).

**Tác nhân phụ.** Kafka (topic `t68.ops.dlq.v1`); Garage (bucket `dh-t68-ops`); PH-13 (chỉ số, cảnh báo); chủ nguồn nhận EVT-18-06.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-013, FR-18-015, FR-18-016, FR-18-018.

**Truy vết.** REQ-18; LGC-BUS-037; CMP-LAW-09; ADR-181; BP-07.

**Tiền điều kiện.** Topic `{tenant}.ops.dlq.v1` đã được PH-10 cấp theo GitOps, PH-18 là chủ, ACL ghi cho `dh-runtime-{tenant}`, giữ dữ liệu 7 ngày, 6 phân vùng.

**Kích hoạt.** Có bản tin mới trên topic; lịch đối soát `18.dlq.reconcile.cron` (02:30 hằng ngày); Chi bấm "Đối soát ngay" ở UI-18-06.

**Đảm bảo tối thiểu.** Offset chỉ commit sau khi chỉ mục bền (BR-18-011); CSDL hay Garage lỗi thì bản tin dồn trong Kafka, không mất.

**Đảm bảo thành công.** Mỗi bản tin thành một mục `NEW` (đủ ngữ cảnh) hoặc `POISON` (thiếu ngữ cảnh), payload lớn ở Garage; bản tin trùng chỉ tăng bộ đếm lần gặp; đối soát cho kết quả `OK` hoặc đã nạp lại phần thiếu.

**Luồng chính.**
1. Luồng `hotich-khaisinh-dongbo` phiên bản 3 hết 5 lần thử ở bước `goi-dich` và `dh-runtime-t68` đẩy bản tin vào `t68.ops.dlq.v1` kèm header của hợp đồng ngữ cảnh (FRS bảng 4.1b), mã lỗi `ERR-04-101`.
2. Consumer đọc lô tới 500 bản ghi mỗi phân vùng. Hệ thống kiểm `dh-tenant` khớp tiền tố topic.
3. Hệ thống kiểm đủ trường bắt buộc theo `replayMode` của nguồn, chuẩn hóa (`attempts` về số, `errorCode` về dạng `ERR-nn-nnn`, `reason` về chữ hoa) và gán lớp lỗi theo nhãn nguồn hoặc theo sổ tay (UC-18-15), không suy được thì `UNKNOWN`.
4. Hệ thống tính SHA-256 và `dlqKey` theo mẫu `sourceCode:flow:messageId:stage`; có mục chưa đóng cùng khóa thì tăng `occurrences`, cập nhật `lastSeenAt` và dừng ở đây.
5. Payload đến `18.dlq.payload.inline-max-kb` (256 KB) lưu nội tuyến; lớn hơn ghi `dlq/{yyyy}/{mm}/{dlqId}` vào Garage và lưu đường dẫn, kích thước, SHA-256.
6. Hệ thống ghi `dlq_message`, `dlq_payload_ref` trong một giao dịch theo lô ở `NEW` hoặc `POISON`, ghi outbox EVT-18-05 gộp theo phút (và EVT-18-06 khi `POISON`), rồi commit offset và phát `dh_ops_dlq_ingested_total`, `dh_ops_dlq_ingest_lag_seconds`.
7. Lúc 02:30, tác vụ đối soát đếm bản ghi theo offset từng phân vùng bằng consumer riêng không commit, so với chỉ mục, nạp lại offset thiếu theo bước 2 đến 6 và lưu kết quả, phát `dh_ops_dlq_reconcile_missing`.

**Luồng thay thế.**
- **3a. Thiếu trường bắt buộc.** Mục `POISON` ghi `missingFields[]`, EVT-18-06 gộp theo nguồn mỗi 5 phút; vượt `18.dlq.threshold.poison-per-hour` (10) thì phát EVT-18-08 loại `POISON_RATE`.
- **3b. Header tên cũ.** Nguồn gửi `dh-error-code`, `dh-attempts`: hệ thống ánh xạ sang tên chuẩn và ghi `legacyHeaders = true` trên mục.
- **4a. Trùng mục đã đóng.** Mục cùng khóa đã `RESOLVED` hoặc `DISCARDED`: tạo mục mới liên kết `previousDlqId` để thấy lỗi tái diễn.
- **6a. CSDL không ghi được.** Consumer dừng phân vùng, không commit, thử lại sau 1, 2, 4 đến 60 giây.
- **7a. Không chênh lệch.** Kết quả đối soát `OK`; mục có trong chỉ mục mà không còn trên topic là bình thường do hết hạn giữ.
- **7b. Chạy tay.** Chi bấm "Đối soát ngay" (API-18-038) và xem kết quả (API-18-037).

**Luồng ngoại lệ.**
- **E1. Tenant trong header lệch topic (bước 2).** ERR-18-103 (worker): "Tenant của bản tin không khớp topic." Mục `POISON` ghi vào tenant của topic, PO thấy ở UI-18-24.
- **E2. Không giải mã được bản tin (bước 2).** ERR-18-101 (worker): "Không đọc được nội dung bản tin; lưu dạng nhị phân." Payload thô ra Garage, mục `POISON`.
- **E3. Thiếu ngữ cảnh (bước 3).** ERR-18-102 (worker): "Thiếu thông tin ngữ cảnh: {trường}." UI-18-03 hiện khung cảnh báo.
- **E4. Bản tin trùng mục đang mở (bước 4).** ERR-18-105 (worker): "Bản tin trùng mục đang mở; đã tăng số lần gặp." Chỉ ghi chỉ số.
- **E5. Garage lỗi hoặc tổng kiểm tra lệch (bước 5).** ERR-18-104 (worker): "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng." Thử lại 3 lần rồi không commit.
- **E6. Đối soát không đọc được topic (bước 7).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ." UI-18-06 báo lần sau sẽ chạy lại.
- **E7. Đã có lần đối soát đang chạy (nhánh 7b).** ERR-18-006 (409): "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}."

**Quy tắc áp dụng.** BR-18-011; BR-18-013; BR-18-014; BR-18-015; BR-18-023; LP-18-04.

**Màn hình, API.** UI-18-01, UI-18-03, UI-18-06, UI-18-24; API-18-037, 038; topic `{tenant}.ops.dlq.v1`.
:::

```{.mermaid caption="Trình tự tiếp nhận bản tin lỗi từ topic DLQ chung"}
sequenceDiagram
  participant R as dh-runtime-t68
  participant K as Kafka t68.ops.dlq.v1
  participant O as ops-dlq-ingest
  participant G as Garage dh-t68-ops
  participant DB as ph18_ops
  participant M as PH-13
  R->>K: Bản tin lỗi kèm header ngữ cảnh
  O->>K: Đọc lô tới 500 bản ghi
  O->>O: Kiểm tenant, ngữ cảnh, tính dlqKey
  O->>G: Ghi payload lớn hơn 256 KB
  O->>DB: Ghi mục NEW hoặc POISON và outbox trong một giao dịch
  DB-->>O: Đã commit
  O->>K: Commit offset
  O-->>M: Chỉ số tiếp nhận, EVT-18-05, EVT-18-06
```

Hình cho thấy offset chỉ được commit sau khi chỉ mục đã bền, nên PH-18 ngừng hay CSDL lỗi thì bản tin vẫn nằm trong Kafka chờ đọc lại.

### 6.10. UC-18-10 · Phân hệ ghi mục DLQ qua API

::: dac-ta
**Mục tiêu.** Phân hệ không dùng topic (PH-01, PH-06, PH-08, PH-19) vẫn đưa được bản tin lỗi cuối cùng vào hàng DLQ chung, và biết ngay khi thiếu ngữ cảnh để tự sửa.

**Tác nhân chính.** DU nguồn (scope `ops:dlq-write`), ví dụ `dh-payment` của PH-19 với inbox `FAILED`.

**Tác nhân phụ.** Garage; PH-13 (chỉ số).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-014, FR-18-015, FR-18-016.

**Truy vết.** REQ-18; LGC-BUS-037; ADR-181; BP-07.

**Tiền điều kiện.** Nguồn `ph19-inbox` đã đăng ký (UC-18-08) và `ACTIVE`.

**Kích hoạt.** PH-19 chuyển một bản tin sang trạng thái lỗi cuối cùng sau khi hết số lần thử.

**Đảm bảo tối thiểu.** Mục thiếu ngữ cảnh không được ghi để nguồn sửa ngay; PH-18 vắng thì nguồn giữ bản tin trong bảng lỗi của mình, vẫn xử lý được ở màn của nguồn (UI-19-16, UI-19-24).

**Đảm bảo thành công.** Mỗi mục có `dlqId`, ở `NEW`; mục trùng trả `dlqId` cũ với `duplicate = true`; EVT-18-05 phát.

**Luồng chính.**
1. PH-19 gửi một lô 12 mục (API-18-036). Hệ thống kiểm scope và nguồn đang `ACTIVE`.
2. Hệ thống kiểm trường bắt buộc của hợp đồng ngữ cảnh và kích thước payload không vượt `18.dlq.payload.max-mb` (20 MB).
3. Hệ thống chuẩn hóa ngữ cảnh, khử trùng và lưu payload như UC-18-09 bước 3 đến 5.
4. Hệ thống ghi mục `NEW` cùng outbox EVT-18-05, trả `dlqId` cho từng mục.

**Luồng thay thế.**
- **1a. Một mục.** PH-19 gửi từng mục (API-18-035).
- **4a. Mục trùng.** Mục cùng `dlqKey` đang mở trả `dlqId` cũ, `duplicate = true`, tăng số lần gặp.
- **1b. PH-18 không phản hồi.** PH-19 giữ bản tin ở inbox `FAILED`, `DEAD` và thử lại theo lịch của mình (LP-18-04).

**Luồng ngoại lệ.**
- **E1. Nguồn chưa đăng ký hoặc tạm ngừng (bước 1).** ERR-18-026 (403): "Nguồn {mã} chưa được đăng ký hoặc đang tạm ngừng ghi DLQ."
- **E2. Thiếu trường ngữ cảnh (bước 2).** ERR-18-024 (422): "Thiếu trường ngữ cảnh bắt buộc: {trường}." Bên gọi ghi log.
- **E3. Payload vượt giới hạn (bước 2).** ERR-18-025 (413): "Nội dung bản tin vượt {MB} MB. Lưu nội dung ở nguồn và gửi tham chiếu."
- **E4. Garage không ghi được (bước 3).** ERR-18-104 (503): "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng."

**Quy tắc áp dụng.** BR-18-011; BR-18-013; BR-18-014; BR-18-015; LP-18-04.

**Màn hình, API.** UI-18-01; API-18-035, 036.
:::

### 6.11. UC-18-11 · Xem và đề nghị phát lại DLQ tầng sự kiện của PH-10

::: dac-ta
**Mục tiêu.** Người vận hành thấy cả bản tin lỗi ở tầng sự kiện (subscription của PH-10) trên cùng màn DLQ mà PH-18 không sao chép nội dung, và đề nghị PH-10 phát lại theo đúng quy trình duyệt của PH-10.

**Tác nhân chính.** TO (Chi), `PERM-18-dlq`.

**Tác nhân phụ.** PH-10 (API-10-060, API-10-064, EVT-10-11, EVT-10-12; PH-18 gọi bằng `event:dlq-read`, `event:replay`); người duyệt của PH-10 (`PERM-10-approve`).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-017.

**Truy vết.** REQ-18; LGC-BUS-037; ADR-181; Q10-35; BP-07.

**Tiền điều kiện.** PH-10 cấp scope cho `svc-ops`; nguồn `ph10-event` đăng ký với `replayMode = EVENT_LAYER`.

**Kích hoạt.** Chi mở tab "Tầng sự kiện" ở UI-18-01; PH-18 nhận EVT-10-11 và cập nhật bộ đếm.

**Đảm bảo tối thiểu.** Không nội dung sự kiện nào được lưu vào `ph18_ops` (BR-18-016); PH-10 vắng thì các tab DLQ khác vẫn chạy.

**Đảm bảo thành công.** Đề nghị phát lại được PH-10 nhận; kết quả lượt phát lại của PH-10 hiện trên mục khi EVT-10-12 về.

**Luồng chính.**
1. Chi mở tab. Hệ thống gọi API-10-060 bằng token đổi từ người dùng, thời gian chờ 3 giây (API-18-039).
2. Hệ thống hiển thị siêu dữ liệu (subscription, topic, mã lỗi, `eventId`, lần thử, thời điểm) kèm nhãn "Tầng sự kiện"; người không có `PERM-10-read` chỉ thấy số đếm.
3. Chi chọn 8 mục của subscription `hotich-thongbao` và bấm "Đề nghị phát lại" (API-18-040). Hệ thống gọi API-10-064 với `dlqEntryIds[]`.
4. PH-10 duyệt bốn mắt theo quy trình của mình và phát lại.
5. Hệ thống nhận EVT-10-12 và hiển thị kết quả lượt phát lại trên các mục.

**Luồng thay thế.**
- **3a. Loại bỏ mục tầng sự kiện.** Hệ thống mở liên kết sang UI-10-15 vì thao tác này cần `PERM-10-operate` ở PH-10 (Q18-03).
- **1a. Không mở tab.** Bộ đếm theo EVT-10-11 vẫn hiện trên thẻ thống kê.

**Luồng ngoại lệ.**
- **E1. PH-10 không phản hồi (bước 1, 3).** ERR-18-035 (503): "Chưa lấy được dữ liệu từ phân hệ sự kiện. Thử lại sau." Các tab khác vẫn chạy.

**Quy tắc áp dụng.** BR-18-016; BR-18-019; LP-18-04.

**Màn hình, API.** UI-18-01; API-18-039, 040.
:::

```{.mermaid caption="Trình tự đề nghị phát lại DLQ tầng sự kiện qua PH-10"}
sequenceDiagram
  actor TO as TO Chi
  participant O as dh-platform ops
  participant E as PH-10 sự kiện
  actor AP as Người duyệt PH-10
  TO->>O: Mở tab Tầng sự kiện (API-18-039)
  O->>E: Đọc DLQ tầng sự kiện bằng token đổi (API-10-060)
  E-->>O: Siêu dữ liệu, không nội dung
  TO->>O: Đề nghị phát lại 8 mục (API-18-040)
  O->>E: Gửi đề nghị (API-10-064)
  AP->>E: Duyệt theo quy trình PH-10
  E-->>O: EVT-10-12 kết quả lượt phát lại
  O-->>TO: Hiện kết quả trên mục
```

Hình cho thấy PH-18 chỉ là cửa sổ xem và kênh đề nghị; quyền duyệt và thực hiện phát lại sự kiện vẫn ở PH-10.

### 6.12. UC-18-12 · Lọc, gom nhóm, phân loại và gán người xử lý mục DLQ

::: dac-ta
**Mục tiêu.** Người trực tỉnh thấy ngay bản tin lỗi nào cần xử lý trước, gom các mục cùng nguyên nhân thành nhóm, và giao rõ ai xử lý để không ai bỏ sót, không hai người cùng làm.

**Tác nhân chính.** TO (Chi), `PERM-18-dlq`.

**Tác nhân phụ.** TA, SO; IE (Quân) và DS (Lan) chỉ thấy mục của luồng, tài sản được giao; PA, PO ở chế độ nền tảng; đầu mối HTTT nguồn nhận thông báo lỗi nghiệp vụ (UC-18-23); Việc của tôi.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-019, FR-18-020, FR-18-023.

**Truy vết.** REQ-18; LGC-BUS-037; FR-00-010; BP-07.

**Tiền điều kiện.** Chi đã chọn tenant T68; có mục chưa đóng.

**Kích hoạt.** Chi mở `/van-hanh/dlq` hoặc bấm số đếm DLQ ở thẻ trang chủ, ở màn của PH-04, PH-10; mở tab "Theo nhóm lỗi" (UI-18-02).

**Đảm bảo tối thiểu.** Mục không hợp lệ trong thao tác hàng loạt bị bỏ qua kèm lý do, mục khác vẫn được xử lý; thông báo cho đầu mối không kèm payload.

**Đảm bảo thành công.** Mục được chọn ở `TRIAGED` (mục `POISON` giữ nguyên) với lớp lỗi, ưu tiên, người xử lý; người được gán có việc `ph18.dlq-assigned`; EVT-18-07 phát.

**Luồng chính.**
1. Chi mở màn. Hệ thống áp bộ lọc mặc định "Chưa xử lý" (`NEW`, `TRIAGED`, `REPLAY_FAILED`, `POISON`), sắp theo ưu tiên rồi tuổi giảm dần, kèm bốn thẻ số (chưa xử lý, `POISON`, đang phát lại, quá `18.dlq.threshold.age-hours`).
2. Chi lọc `?nguon=ph04-runtime&ma-loi=ERR-04-101` (API-18-041). Hệ thống kiểm tham số và áp lọc quyền, trả trang kết quả kèm `facets` theo nguồn, lớp lỗi, trạng thái.
3. Chi mở tab "Theo nhóm lỗi" (API-18-043). Tác vụ gom (chạy mỗi phút) đã gắn mục vào nhóm theo dấu hiệu `sourceCode:flow:errorCode:stage` trong cửa sổ `18.dlq.group.window-hours` (24 giờ); hệ thống hiện nhóm 46 mục của luồng `hotich-khaisinh-dongbo` bước `goi-dich`.
4. Chi bấm "Gán nhóm", chọn lớp `TRANSIENT`, ưu tiên `P2`, người xử lý Quân (API-18-044). Hệ thống kiểm trạng thái cho phép và `If-Match` cho từng mục.
5. Hệ thống lưu phân loại, chuyển mục `NEW` sang `TRIAGED`, tạo `dlq_assignment` và việc `ph18.dlq-assigned` cho Quân, ghi `dlq_audit`, phát EVT-18-07.

**Luồng thay thế.**
- **2a. Tìm theo từ khóa.** Chi nhập `q`: khớp mã mục, `messageId`, `traceId`, mã lỗi, mã luồng (không tìm trong payload).
- **2b. Xuất CSV.** Chi xuất siêu dữ liệu kết quả lọc (API-18-042), tối đa 50.000 dòng.
- **4a. Phân loại từng mục hoặc hàng loạt.** Chi phân loại một mục (API-18-049), gán (API-18-050) hoặc chọn tới 1.000 mục (API-18-051); "Nhận việc" đặt người xử lý là chính mình.
- **5a. Lỗi nghiệp vụ.** Lớp `BUSINESS` và `notifyOwner = true`: hệ thống gửi thông báo cho đầu mối HTTT nguồn theo quy tắc `dlq.business-error`, không kèm payload.
- **3a. Mục mới vào nhóm đã gán.** Mục mới thừa hưởng người xử lý và ưu tiên của nhóm.
- **3b. Phát lại nhóm.** Chi bấm "Phát lại nhóm": chuyển sang UC-18-17 với bộ lọc `groupId`.

**Luồng ngoại lệ.**
- **E1. Bộ lọc sai hoặc vượt giới hạn xuất (bước 2, nhánh 2b).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E2. Trạng thái không cho phép, hoặc nhóm không còn mục cần xử lý (bước 4).** ERR-18-006 (409): "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}.".
- **E3. Người được gán không có quyền DLQ (bước 4).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E4. Phiên bản mục đã đổi (bước 4).** ERR-18-004 (412): "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu."

**Quy tắc áp dụng.** BR-18-032; BR-18-046; BR-18-047; LP-18-02; LP-18-03.

**Màn hình, API.** UI-18-01, UI-18-02; API-18-041, 042, 043, 044, 049, 050, 051, 063.
:::

### 6.13. UC-18-13 · Xem chi tiết, ngữ cảnh chẩn đoán và nội dung mục DLQ có lý do

::: dac-ta
**Mục tiêu.** Người xử lý hiểu vì sao bản tin lỗi bằng ngữ cảnh, vết và log quanh thời điểm lỗi, và chỉ mở nội dung bản tin khi thật cần, có lý do, có kiểm toán, với trường nhạy cảm vẫn bị che.

**Tác nhân chính.** TO (Chi) xem chi tiết (`PERM-18-dlq`); SO (Dũng) hoặc IE (Quân) xem nội dung (`PERM-18-dlq-payload`).

**Tác nhân phụ.** PH-13 (API-13-069, kiểm toán; PH-18 gọi bằng `obs:diagnostics-read`); PH-09 (bộ che dùng chung); Garage; PH-17 (bảng bên "Giải thích lỗi này").

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-021, FR-18-022.

**Truy vết.** REQ-18; LGC-BUS-037; LGC-NFR-004; CMP-LAW-05; SEC-31; SEC-60; BP-07.

**Tiền điều kiện.** Mục `dlq-000123` thuộc T68 và người dùng được xem theo lọc quyền; để xem nội dung, mục chưa `EXPIRED`.

**Kích hoạt.** Chi bấm một dòng ở UI-18-01; Dũng bấm "Xem nội dung" ở UI-18-03.

**Đảm bảo tối thiểu.** PH-13 vắng thì các phần khác của màn vẫn đầy đủ (fail-soft); không ghi được kiểm toán thì không trả nội dung.

**Đảm bảo thành công.** Màn hiện ngữ cảnh, sổ tay, lịch sử, chẩn đoán; nội dung trả kèm phiếu xem hạn `18.dlq.reveal.ttl-minutes` (15 phút), trường đã được nguồn mã hóa hiện "•••• đã mã hóa".

**Luồng chính.**
1. Chi mở mục (API-18-045). Hệ thống kiểm mục tồn tại trong T68 và trả ngữ cảnh: nguồn, luồng, phiên bản, bước, mã lỗi, lớp lỗi, lần thử, số lần gặp, thời điểm, trạng thái, người xử lý.
2. Hệ thống tải song song sổ tay của `ERR-04-101` (API-18-058), lịch sử trạng thái, bản sửa, lượt phát lại, sự cố liên kết.
3. Mục có `traceId`: hệ thống gọi API-13-069 với cửa sổ 5 phút, chờ tối đa `18.dlq.diagnostics.timeout-ms` (3.000 ms), nhận vết, đến 200 dòng log đã che và chỉ số quanh thời điểm lỗi (API-18-046).
4. Hệ thống hiện khung "Chẩn đoán" và gợi ý theo lớp lỗi (ví dụ `TRANSIENT` và đích đã phục hồi thì gợi ý phát lại).
5. Dũng bấm "Xem nội dung", nhập lý do "Đối chiếu trường ngày sinh bị từ chối ở đích" (API-18-047). Hệ thống kiểm quyền, lý do và payload còn.
6. Hệ thống ghi kiểm toán trước khi trả nội dung, đọc payload nội tuyến hoặc từ Garage, kiểm SHA-256, giữ nguyên trường đã mã hóa và che thêm trường định danh theo bộ che của PH-09.
7. Hệ thống trả nội dung kèm phiếu xem 15 phút; hết phiếu thì phải nhập lý do lại.

**Luồng thay thế.**
- **3a. Không có `traceId` hoặc PH-13 vắng.** Khung chẩn đoán hiện "Không có ngữ cảnh từ giám sát", phần khác đầy đủ.
- **4a. Giải thích bằng trợ lý.** Chi bấm "Giải thích lỗi này": bảng bên PH-17 mở với `dlqId` và đọc qua UC-18-15.
- **5a. Chỉ xem khung.** Quân bấm "Xem khung" (API-18-048): tên trường và kiểu, không giá trị, không cần lý do.

**Luồng ngoại lệ.**
- **E1. Không tìm thấy mục (bước 1).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}.".
- **E2. PH-13 quá thời gian (bước 3).** ERR-18-106 (worker): "Chưa lấy được ngữ cảnh chẩn đoán."
- **E3. Thiếu lý do (bước 5).** ERR-18-007 (422): "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
- **E4. Payload đã xóa do hết hạn (bước 5).** ERR-18-027 (409): "Nội dung bản tin đã bị xóa do hết hạn lưu giữ. Chỉ còn thông tin mô tả."
- **E5. PH-13 không ghi được kiểm toán (bước 6).** ERR-18-008 (503): "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
- **E6. Tổng kiểm tra lệch (bước 6).** ERR-18-104 (worker): "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng."

**Quy tắc áp dụng.** BR-18-017; BR-18-047; LP-18-02; LP-18-04.

**Màn hình, API.** UI-18-03; API-18-045, 046, 047, 048, 058.
:::

```{.mermaid caption="Trình tự xem chi tiết, chẩn đoán và nội dung mục DLQ"}
sequenceDiagram
  actor TO as TO Chi
  actor SO as SO Dũng
  participant O as dh-platform ops
  participant M as PH-13
  participant P as Bộ che PH-09
  participant G as Garage
  TO->>O: Mở mục dlq-000123 (API-18-045)
  O->>M: Lấy vết, log, chỉ số trong 3 giây (API-13-069)
  M-->>O: Ngữ cảnh chẩn đoán hoặc quá thời gian
  O-->>TO: Ngữ cảnh, sổ tay, gợi ý theo lớp lỗi
  SO->>O: Xem nội dung kèm lý do (API-18-047)
  O->>M: Ghi kiểm toán trước khi trả
  O->>G: Đọc payload, kiểm SHA-256
  O->>P: Che trường định danh
  O-->>SO: Nội dung đã che, phiếu xem 15 phút
```

Hình cho thấy chẩn đoán là phụ thuộc mềm (quá 3 giây thì bỏ qua), còn nội dung chỉ trả sau khi kiểm toán đã ghi và đã qua bộ che.

### 6.14. UC-18-14 · Sửa payload có kiểm soát và duyệt bốn mắt

::: dac-ta
**Mục tiêu.** Khi bản tin lỗi do dữ liệu sai (ví dụ định dạng ngày), kỹ sư sửa được nội dung để phát lại mà payload gốc vẫn nguyên vẹn làm bằng chứng, và mọi sửa chạm dữ liệu mức Hạn chế đều có người thứ hai duyệt.

**Tác nhân chính.** IE (Quân) tạo bản sửa (`PERM-18-dlq-payload`); TA (Tuấn) duyệt khi cần (`PERM-18-approve`).

**Tác nhân phụ.** PH-09 (mức phân loại trường); PH-04 hoặc PH-10 (JSON Schema của nguồn); Việc của tôi; PH-13 (kiểm toán).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-024.

**Truy vết.** REQ-18; LGC-BUS-037; CMP-LAW-05; ADR-181; BP-07.

**Tiền điều kiện.** Mục `dlq-000123` ở `TRIAGED`, `REPLAY_FAILED` hoặc `POISON`; nguồn có `supportsRevision = true`; Quân có phiếu xem payload còn hạn (UC-18-13).

**Kích hoạt.** Quân bấm "Sửa nội dung" ở UI-18-03, mở UI-18-04.

**Đảm bảo tối thiểu.** Payload gốc không bao giờ bị sửa (BR-18-012); bản sửa bị từ chối không đổi trạng thái mục.

**Đảm bảo thành công.** `dlq_revision` số mới `APPROVED`; mục `POISON` sang `TRIAGED`; lần phát lại kế tiếp dùng khóa lũy đẳng `dlqId:revision` mới; EVT-18-07 phát.

**Luồng chính.**
1. Quân sửa trường `ngaySinh` từ `31/02/2019` thành `2019-02-28` trong trình soạn có so sánh, nhập lý do và bấm "Lưu" (API-18-053). Hệ thống kiểm chưa có bản sửa chờ duyệt và lý do đủ dài.
2. Hệ thống kiểm nội dung theo lược đồ của nguồn và tính khác biệt theo đường dẫn trường (API-18-054).
3. Hệ thống tra mức phân loại các trường bị sửa với PH-09: `ngaySinh` mức Hạn chế, nên bản sửa ở `PENDING_APPROVAL`, tạo việc `ph18.approve-revision` cho người có `PERM-18-approve` trừ Quân.
4. Tuấn mở việc, xem khác biệt và lý do, bấm "Duyệt" (API-18-055). Hệ thống kiểm Tuấn khác Quân và ghi kiểm toán.
5. Hệ thống lưu bản sửa số 1 `APPROVED`, giữ trạng thái `TRIAGED` của mục (hoặc chuyển `POISON` sang `TRIAGED`), phát EVT-18-07, đóng việc.

**Luồng thay thế.**
- **3a. Không chạm trường mức Hạn chế, Nhạy cảm.** Bản sửa `APPROVED` ngay, không cần bốn mắt.
- **4a. Từ chối.** Tuấn từ chối kèm lý do (API-18-056): bản sửa `REJECTED`, mục giữ trạng thái, Quân được báo.
- **1a. Nguồn không nhận bản sửa.** Nút "Sửa nội dung" bị ẩn; màn gợi ý sửa ở nguồn rồi gửi lại.
- **1b. Xem các bản sửa.** Quân xem danh sách bản sửa của mục (API-18-052).

**Luồng ngoại lệ.**
- **E1. Đã có bản sửa chờ duyệt (bước 1).** ERR-18-030 (409): "Mục đã có bản sửa số {n} chờ duyệt. Chờ duyệt xong trước khi sửa tiếp."
- **E2. Thiếu lý do (bước 1).** ERR-18-007 (422): "Nhập lý do {thao tác} (ít nhất {n} ký tự)."
- **E3. Bản sửa sai lược đồ (bước 2).** ERR-18-029 (422): "Nội dung sửa không đúng lược đồ {lược đồ}: {chi tiết}."
- **E4. Người duyệt trùng người sửa (bước 4).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."

**Quy tắc áp dụng.** BR-18-012; BR-18-018; BR-18-020; LP-18-01; LP-18-02.

**Màn hình, API.** UI-18-03, UI-18-04, UI-18-15; API-18-052, 053, 054, 055, 056.
:::

```{.mermaid caption="Trình tự sửa payload chạm trường mức Hạn chế và duyệt bốn mắt"}
sequenceDiagram
  actor IE as IE Quân
  actor TA as TA Tuấn
  participant O as dh-platform ops
  participant P as PH-09 phân loại
  participant K as PH-13 kiểm toán
  IE->>O: Lưu bản sửa kèm lý do (API-18-053)
  O->>O: Kiểm lược đồ nguồn, tính khác biệt
  O->>P: Tra mức phân loại trường bị sửa
  P-->>O: ngaySinh mức Hạn chế
  O-->>TA: Việc ph18.approve-revision
  TA->>O: Duyệt bản sửa (API-18-055)
  O->>O: Kiểm người duyệt khác người sửa
  O->>K: Ghi kiểm toán
  O-->>IE: Bản sửa số 1 APPROVED, sẵn sàng phát lại
```

Hình cho thấy quyết định cần bốn mắt hay không dựa trên mức phân loại của PH-09 chứ không do người sửa tự chọn.

### 6.15. UC-18-15 · Biên soạn sổ tay xử lý theo mã lỗi và cấp API đọc cho PH-17

::: dac-ta
**Mục tiêu.** Mỗi mã lỗi có hướng dẫn xử lý viết sẵn để người trực làm đúng ngay, và trợ lý AI dùng chính sổ tay đó cùng siêu dữ liệu DLQ để giải thích lỗi mà không có quyền ghi.

**Tác nhân chính.** PA (Hà) soạn phần dùng chung, TA (Mai) soạn phần của tỉnh (`PERM-18-admin`); PH-17 đọc (scope `ops:dlq-read`, token đổi theo RFC 8693).

**Tác nhân phụ.** Phân hệ chủ mã lỗi (nguồn nội dung, Q18-16); người dùng có `PERM-18-dlq` (trong token); UC-18-09 và UC-18-13 dùng `defaultClass`, `replayable`.

**Mức ưu tiên.** S · MVP (API cho PH-17: S · Đợt 2).

**FR hiện thực.** FR-18-025, FR-18-026.

**Truy vết.** REQ-18; LGC-BUS-037; Q17-08; BR-17-054; FR-17-038; BP-07.

**Tiền điều kiện.** Mã lỗi có định nghĩa ở chương 9 của FRS phân hệ chủ; với PH-17, token mang người dùng có `PERM-18-dlq` ở T68.

**Kích hoạt.** Hà mở UI-18-07; tác vụ nạp ban đầu từ danh mục mã lỗi; người dùng bấm "Giải thích lỗi này" và PH-17 gọi công cụ `view_dlq_message`.

**Đảm bảo tối thiểu.** Sổ tay không chứa payload, mẫu số định danh hay địa chỉ thư (BR-18-050); scope `ops:dlq-read` không thực hiện được thao tác ghi nào (BR-18-016).

**Đảm bảo thành công.** `error_guide` của `ERR-04-101` có phiên bản mới, EVT-18-11 phát để PH-17 lập chỉ mục lại; PH-17 nhận siêu dữ liệu mục và hướng dẫn trong phạm vi quyền của người hỏi.

**Luồng chính.**
1. Hà nhập hướng dẫn cho `ERR-04-101`: nguyên nhân thường gặp, cách kiểm, `defaultClass = TRANSIENT`, `replayable = true` (API-18-059). Hệ thống kiểm mã theo mẫu `^ERR-\d{2}-\d{3}$`.
2. Hệ thống lọc nội dung: bỏ thẻ HTML, chặn liên kết ra ngoài danh sách cho phép, không cho chứa mẫu số định danh hay địa chỉ thư.
3. Hệ thống lưu `error_guide` (phiên bản tăng), phát EVT-18-11.
4. Người dùng bấm "Giải thích lỗi này" trên `dlq-000123`. PH-17 gọi API-18-061 với token đổi. Hệ thống kiểm scope máy và quyền `PERM-18-dlq` của người dùng trong token.
5. Hệ thống trả siêu dữ liệu (nguồn, luồng, mã lỗi, lớp lỗi, lần thử, thông điệp lỗi, thời điểm, trạng thái) và hướng dẫn sổ tay; không nhận thao tác ghi nào.

**Luồng thay thế.**
- **1a. Ghi chú của tỉnh.** Mai thêm ghi chú riêng của T68: lưu như lớp phủ theo tenant, hiện dưới phần dùng chung.
- **4a. Kèm nội dung.** PH-17 gửi `includePayload = true` kèm lý do trong tiêu đề `X-Reveal-Reason`: hệ thống kiểm người dùng có `PERM-18-dlq-payload` rồi xử lý như UC-18-13 bước 6, 7; không có quyền thì trả khung không giá trị (API-18-048).
- **3a. PH-17 lập chỉ mục sổ tay.** PH-17 gọi API-18-062 theo `updatedSince`.
- **4b. Danh sách.** PH-17 đọc danh sách mục theo bộ lọc (API-18-060).
- **1b. Xem sổ tay.** Người có `PERM-18-read` tra cứu (API-18-057, 058).

**Luồng ngoại lệ.**
- **E1. Mã sai mẫu hoặc nội dung bị lọc (bước 1, 2).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E2. Hướng dẫn đã được người khác sửa (bước 3).** ERR-18-004 (412): "Tham số đã được người khác sửa. Tải lại để xem giá trị mới trước khi lưu.".
- **E3. Người dùng trong token không có quyền (bước 4).** ERR-00-403 (403); PH-17 hiện câu của mình.
- **E4. Quá 20 yêu cầu mỗi giây mỗi người (bước 4).** ERR-18-010 (429): "Quá nhiều yêu cầu. Thử lại sau {giây} giây."

**Quy tắc áp dụng.** BR-18-016; BR-18-017; BR-18-050; LP-18-03.

**Màn hình, API.** UI-18-07, UI-18-03 (phần PH-17 hiển thị ở UI-17-03); API-18-048, 057, 058, 059, 060, 061, 062.
:::

### 6.16. UC-18-16 · Phát lại một mục DLQ và nhận kết quả lũy đẳng

::: dac-ta
**Mục tiêu.** Người trực đưa một bản tin lỗi trở lại xử lý sau khi nguyên nhân đã được khắc phục, qua đúng lối vào của phân hệ nguồn, và chắc chắn bản tin không được xử lý hai lần dù bấm lại hay kết quả về trễ.

**Tác nhân chính.** TO (Chi), `PERM-18-dlq`.

**Tác nhân phụ.** Phân hệ nguồn `dh-runtime-t68` (nhận EVT-18-09, báo kết quả bằng `ops:replay-callback`); PH-10 (EVT-10-12 với nguồn `EVENT_LAYER`); UC-18-27 (trạng thái đóng băng).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-027, FR-18-030.

**Truy vết.** REQ-18; LGC-BUS-037; FR-00-050; D05-01 (phát lại lũy đẳng); BP-07.

**Tiền điều kiện.** Mục `dlq-000123` ở `NEW`, `TRIAGED` hoặc `REPLAY_FAILED`; nguồn `ACTIVE` có cổng khác `NONE`; mục không nằm trong lượt khác.

**Kích hoạt.** Chi bấm "Phát lại" ở UI-18-03 và xác nhận; nguồn gọi callback; hết `18.dlq.replay.result-timeout-minutes` (30 phút).

**Đảm bảo tối thiểu.** Kết quả cuối của một khóa lũy đẳng chỉ ghi một lần (BR-18-020); PH-18 không gọi thẳng hệ đích (BR-18-019).

**Đảm bảo thành công.** Mục `RESOLVED`, việc `ph18.dlq-assigned` đóng, `replayCount` tăng; hoặc mục `REPLAY_FAILED` với mã lỗi mới để xử lý tiếp.

**Luồng chính.**
1. Chi bấm "Phát lại". Hộp xác nhận nêu nguồn, luồng, bản dùng (bản sửa số 1). Hệ thống kiểm mục không `POISON`, không trong lượt khác, nguồn có cổng.
2. Hệ thống đọc trạng thái đóng băng của môi trường: phát lại không bị chặn vì không đổi cấu hình, chỉ hiện cảnh báo nếu đang đóng băng.
3. Hệ thống chuyển mục `REPLAY_PENDING` rồi `REPLAYING`, phát EVT-18-09 với khóa lũy đẳng `dlq-000123:1` cho cổng `KAFKA_TOPIC` (API-18-064); nguồn lấy nội dung cần phát lại theo `payloadRef` qua API-18-188; hệ thống ghi `dlq_audit`, tăng `replayCount`.
4. `dh-runtime-t68` đưa bản tin vào lối vào của luồng `hotich-khaisinh-dongbo` phiên bản 3, xử lý thành công và gọi callback `SUCCEEDED` (API-18-076).
5. Hệ thống kiểm danh tính gọi là nguồn của mục và khóa tồn tại, kiểm khóa chưa có kết quả cuối.
6. Hệ thống đặt mục `RESOLVED`, cập nhật `replay_item` (nếu có), ghi `dlq_audit`, phát EVT-18-07 và đóng việc `ph18.dlq-assigned`.

**Luồng thay thế.**
- **3a. Cổng `HTTP_PORT`.** Hệ thống gọi cổng nội bộ của nguồn với thời gian chờ 10 giây; nguồn trả kết quả đồng bộ thì chạy ngay bước 5, 6.
- **3b. Nguồn `EVENT_LAYER`.** Chuyển sang UC-18-11 bước 3.
- **5a. Gọi lại cùng khóa.** Khóa đã có kết quả cuối: hệ thống trả `200` không đổi gì; phía nguồn, `dh-runtime` giữ bảng khóa đã xử lý 30 ngày và trả `DUPLICATE_IGNORED`.
- **6a. Nguồn báo `FAILED`.** Mục `REPLAY_FAILED` kèm mã lỗi mới, `errorClass` cập nhật nếu nguồn gửi.
- **4a. Quá hạn chờ.** Sau 30 phút không có kết quả: mục `REPLAY_FAILED`; kết quả thành công đến muộn vẫn được nhận và ghi đè thành `RESOLVED`, nhật ký ghi "kết quả đến muộn".

**Luồng ngoại lệ.**
- **E1. Mục `POISON` (bước 1).** ERR-18-028 (409): "Bản tin thiếu ngữ cảnh nên không phát lại được. Sửa nội dung hoặc bỏ qua."
- **E2. Mục đang trong lượt khác (bước 1).** ERR-18-031 (409): "Mục đang được phát lại trong lượt {mã}."
- **E3. Nguồn không có cổng hoặc tạm ngừng (bước 1).** ERR-18-033 (409): "Nguồn {mã} chưa có cổng phát lại hoặc đang tạm ngừng."
- **E4. Cổng nguồn từ chối (nhánh 3a).** ERR-18-107 (worker): "Nguồn từ chối phát lại: {lý do}." Mục `REPLAY_FAILED`.
- **E5. Cổng nguồn quá thời gian (nhánh 3a).** ERR-18-108 (worker): "Nguồn không phản hồi; mục sẽ được thử lại."
- **E6. Callback từ danh tính khác nguồn (bước 5).** ERR-18-038 (403): "Danh tính gọi không khớp nguồn của mục." PO thấy ở UI-18-24.
- **E7. Quá hạn chờ kết quả (nhánh 4a).** ERR-18-109 (worker): "Chưa nhận kết quả phát lại sau {n} phút." Hiện ở UI-18-03.

**Quy tắc áp dụng.** BR-18-019; BR-18-020; BR-18-023; LP-18-03.

**Màn hình, API.** UI-18-03; API-18-064, 076.
:::

```{.mermaid caption="Trình tự phát lại một mục DLQ qua lối vào của nguồn"}
sequenceDiagram
  actor TO as TO Chi
  participant O as dh-platform ops
  participant K as Kafka t68.ops.replay.requested.v1
  participant R as dh-runtime-t68
  TO->>O: Phát lại dlq-000123 (API-18-064)
  O->>O: Kiểm POISON, lượt khác, cổng nguồn
  O->>K: EVT-18-09 khóa dlq-000123 số 1
  K->>R: Bản tin vào lối vào luồng
  R->>R: Kiểm khóa đã xử lý, chạy luồng
  R->>O: Kết quả SUCCEEDED (API-18-076)
  O->>O: Kiểm danh tính nguồn, khóa chưa có kết quả cuối
  O-->>TO: Mục RESOLVED, EVT-18-07
```

Hình cho thấy PH-18 không gọi hệ đích; cả hai phía đều giữ khóa lũy đẳng nên bấm lại hay kết quả đến trễ không gây xử lý trùng.

### 6.17. UC-18-17 · Phát lại loạt có duyệt bốn mắt và điều khiển lượt

::: dac-ta
**Mục tiêu.** Sau một sự cố đích, người trực phát lại hàng trăm bản tin cùng nguyên nhân trong một lượt có tốc độ giới hạn, theo dõi tiến độ, dừng ngay khi đích chưa chịu tải, và lượt lớn phải có người thứ hai đồng ý.

**Tác nhân chính.** TO (Chi) tạo và điều khiển lượt (`PERM-18-dlq`); TA (Tuấn) duyệt khi vượt ngưỡng (`PERM-18-approve`).

**Tác nhân phụ.** Phân hệ nguồn; Việc của tôi; PH-13 (EVT-18-08, EVT-18-10); thanh tác vụ chung (FR-00-053).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-028, FR-18-029, FR-18-030.

**Truy vết.** REQ-18; LGC-BUS-037; FR-00-053; FR-00-054; BP-07.

**Tiền điều kiện.** Bộ lọc hoặc danh sách cho ra ít nhất một mục phát lại được; nguồn `ph04-runtime` có trần tốc độ 20 mục mỗi giây.

**Kích hoạt.** Chi chọn nhiều mục ở UI-18-01, bấm "Phát lại nhóm" ở UI-18-02 hoặc "Tạo lượt phát lại" ở UI-18-05.

**Đảm bảo tối thiểu.** Danh sách mục chốt khi tạo và kiểm lại khi duyệt; lượt tự dừng khi tỷ lệ lỗi vượt ngưỡng; hủy hay dừng thì mục chưa gửi về `TRIAGED`.

**Đảm bảo thành công.** Lượt `COMPLETED` (mọi mục thành công) hoặc `PARTIAL`; mỗi mục có kết quả; EVT-18-10 phát mỗi lần lượt đổi trạng thái.

**Luồng chính.**
1. Chi tạo lượt với bộ lọc `{"nguon":"ph04-runtime","ma-loi":"ERR-04-101"}` (API-18-065). Hệ thống đánh giá bộ lọc, chốt 812 mục vào `replay_item`.
2. Hệ thống bỏ khỏi danh sách mục `POISON`, mục đang trong lượt khác, mục của nguồn không có cổng, báo số mục bị bỏ theo lý do (6 mục `POISON`); lượt ở `DRAFT` với 806 mục.
3. Chi đặt tốc độ 10 mục mỗi giây, ngưỡng dừng 20% và bấm "Gửi" (API-18-069). 806 vượt `18.dlq.replay.approval-threshold` (500): lượt `PENDING_APPROVAL`, việc `ph18.approve-replay` tạo cho người có `PERM-18-approve` trừ Chi.
4. Tuấn mở việc, xem bộ lọc, số mục, nguồn, tốc độ và bấm "Duyệt" (API-18-070). Hệ thống kiểm Tuấn khác Chi, kiểm lại danh sách (mục đã đóng trong lúc chờ thì bỏ), chuyển `APPROVED` rồi `RUNNING`.
5. Tác vụ chạy lượt gửi từng mục qua cổng như UC-18-16 bước 3, giữ tốc độ bằng bộ giới hạn token-bucket theo `ratePerSecond` và trần của nguồn; cập nhật tiến độ mỗi 5 giây (API-18-067, 068).
6. Kết quả từng mục về như UC-18-16 bước 5, 6; hệ thống tính tỷ lệ lỗi trên 100 kết quả gần nhất.
7. Mọi mục có kết quả: lượt `PARTIAL` với 801 thành công, 5 lỗi; phát EVT-18-10; Chi lọc 5 mục lỗi để xử lý tiếp.

**Luồng thay thế.**
- **3a. Dưới ngưỡng.** Lượt đến 500 mục chuyển `APPROVED` và chạy ngay, không cần duyệt.
- **1a. Danh sách thay vì bộ lọc.** Chi chọn tới 1.000 `dlqId`.
- **4a. Từ chối.** Tuấn từ chối kèm lý do (API-18-071): lượt `REJECTED`, mục giữ nguyên trạng thái.
- **5a. Tạm dừng, tiếp tục.** Chi bấm "Tạm dừng" (API-18-072): không gửi mục mới, mục đã gửi vẫn nhận kết quả; "Tiếp tục" (API-18-073) chạy từ mục kế tiếp. Tạm dừng không cần bốn mắt.
- **5b. Đổi tốc độ.** Chi giảm tốc độ xuống 5 mục mỗi giây (API-18-075).
- **5c. Hủy.** Chi bấm "Hủy" (API-18-074): mục chưa gửi về `TRIAGED`, lượt `CANCELLED`.
- **6a. Tỷ lệ lỗi vượt ngưỡng.** Vượt `18.dlq.threshold.replay-failure-percent` (20%): lượt `FAILED`, mục chưa gửi về `TRIAGED`, phát EVT-18-08 loại `REPLAY_FAILURE_RATE`.
- **1b. Xem lượt.** Chi xem danh sách lượt (API-18-066).

**Luồng ngoại lệ.**
- **E1. Bộ lọc không có mục (bước 1).** ERR-18-036 (422): "Không có mục nào phù hợp để {thao tác}."
- **E2. Vượt số mục tối đa (bước 1).** ERR-18-032 (422): "Lượt có {n} mục, vượt giới hạn {tối đa}. Thu hẹp bộ lọc hoặc chia thành nhiều lượt." (`18.dlq.replay.batch-max` 10.000).
- **E3. Người duyệt trùng người tạo (bước 4).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."
- **E4. Tốc độ vượt trần của nguồn (bước 3, nhánh 5b).** ERR-18-037 (422): "Tốc độ {n} mục mỗi giây vượt giới hạn {trần} của nguồn {mã}."
- **E5. Lượt không ở trạng thái điều khiển được (nhánh 5a, 5c).** ERR-18-006 (409): "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}.".

**Quy tắc áp dụng.** BR-18-020; BR-18-021; BR-18-022; LP-18-01; LP-18-03.

**Màn hình, API.** UI-18-01, UI-18-02, UI-18-05, UI-18-15; API-18-065, 066, 067, 068, 069, 070, 071, 072, 073, 074, 075, 076.
:::

```{.mermaid caption="Trình tự phát lại loạt vượt ngưỡng có duyệt bốn mắt"}
sequenceDiagram
  actor TO as TO Chi
  actor TA as TA Tuấn
  participant O as dh-platform ops
  participant R as dh-runtime-t68
  participant M as PH-13
  TO->>O: Tạo lượt theo bộ lọc (API-18-065)
  O->>O: Chốt 806 mục, lượt DRAFT
  TO->>O: Gửi lượt (API-18-069)
  O-->>TA: Vượt 500 mục, việc ph18.approve-replay
  TA->>O: Duyệt (API-18-070)
  O->>O: Kiểm người duyệt khác người tạo, kiểm lại danh sách
  loop Theo tốc độ 10 mục mỗi giây
    O->>R: EVT-18-09 cho từng mục
    R->>O: Kết quả từng mục (API-18-076)
  end
  O-->>M: EVT-18-10, EVT-18-08 nếu tỷ lệ lỗi vượt ngưỡng
  O-->>TO: Lượt PARTIAL, 5 mục lỗi
```

Hình cho thấy duyệt nằm trước khi gửi mục đầu tiên; trong khi chạy, người tạo vẫn tạm dừng, đổi tốc độ hay hủy được mà không cần duyệt lại.

### 6.18. UC-18-18 · Bỏ qua và mở lại mục DLQ

::: dac-ta
**Mục tiêu.** Người trực đóng những bản tin không cần xử lý lại (ví dụ bản tin thử nghiệm, đã xử lý tay ở nguồn) với lý do rõ ràng, và mở lại được nếu bỏ nhầm trước khi hết hạn lưu giữ.

**Tác nhân chính.** TO (Chi), `PERM-18-dlq`.

**Tác nhân phụ.** TA, SO; PH-13 (kiểm toán); Việc của tôi (đóng việc liên quan).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-031, FR-18-032.

**Truy vết.** REQ-18; LGC-BUS-037; FR-00-050; BP-07.

**Tiền điều kiện.** Mục ở `NEW`, `TRIAGED`, `REPLAY_FAILED` hoặc `POISON` (bỏ qua); mục `DISCARDED`, chưa `EXPIRED` (mở lại).

**Kích hoạt.** Chi bấm "Bỏ qua" ở UI-18-03 hoặc chọn nhiều mục ở UI-18-01; bấm "Mở lại" ở UI-18-03.

**Đảm bảo tối thiểu.** Payload giữ đủ `18.dlq.retention.closed-days` (90 ngày) sau khi bỏ qua; mục không hợp lệ trong thao tác hàng loạt được báo lại.

**Đảm bảo thành công.** Mục `DISCARDED` có `discardedAt`, `expiresAt`, việc liên quan đóng; hoặc mục mở lại ở `TRIAGED` giữ phân loại cũ, `expiresAt` bị xóa; EVT-18-07 phát.

**Luồng chính.**
1. Chi chọn 6 mục `POISON` của bản tin thử nghiệm, bấm "Bỏ qua", chọn mã lý do `TEST_DATA` và mô tả "Bản tin thử trong đợt kiểm tra kết nối ngày 12/03" (API-18-078). Hệ thống kiểm lý do và trạng thái từng mục.
2. Hộp xác nhận nêu 6 mục và hạn mở lại đến 10/06/2027.
3. Hệ thống chuyển mục sang `DISCARDED`, ghi `discardedAt`, tính `expiresAt` theo 90 ngày.
4. Hệ thống ghi `dlq_audit`, phát EVT-18-07, đóng việc liên quan.

**Luồng thay thế.**
- **1a. Bỏ qua một mục.** Chi bấm "Bỏ qua" ở UI-18-03 (API-18-077).
- **4a. Mở lại.** Mười ngày sau, Chi phát hiện bỏ nhầm một mục, bấm "Mở lại" kèm lý do (API-18-079). Hệ thống kiểm mục `DISCARDED` và chưa hết hạn, chuyển `TRIAGED`, giữ phân loại cũ, xóa `expiresAt`, ghi `dlq_audit`, phát EVT-18-07.

**Luồng ngoại lệ.**
- **E1. Lý do thiếu hoặc ngắn (bước 1).** ERR-18-007 (422): "Nhập lý do {thao tác} (ít nhất {n} ký tự).".
- **E2. Trạng thái không cho phép (bước 1, nhánh 4a).** ERR-18-006 (409): "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}.".
- **E3. Mục đã hết hạn lưu giữ (nhánh 4a).** ERR-18-034 (409): "Mục đã hết hạn lưu giữ nên không thể mở lại."

**Quy tắc áp dụng.** BR-18-023; BR-18-024; BR-18-025; LP-18-02.

**Màn hình, API.** UI-18-01, UI-18-03; API-18-077, 078, 079.
:::

### 6.19. UC-18-19 · Lưu giữ, dọn, thống kê DLQ và phát sự kiện vượt ngưỡng

::: dac-ta
**Mục tiêu.** Nội dung bản tin lỗi không bị giữ lâu hơn cần thiết, người vận hành và lãnh đạo thấy được mức tồn và xu hướng, và PH-13 nhận đủ chỉ số để cảnh báo mà PH-18 không tự làm luật cảnh báo.

**Tác nhân chính.** Hệ thống (tác vụ dọn 03:00 hằng ngày, tác vụ ngưỡng mỗi phút); TO (Chi) xem (`PERM-18-dlq`).

**Tác nhân phụ.** PH-13 (thu chỉ số Prometheus, luật cảnh báo, lịch trực); Garage; PH-09 (lệnh giữ pháp lý); VW (Bình) xem thống kê; UC-18-28 (mở sự cố khi vượt ngưỡng `DEPTH` mức P1).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-033, FR-18-034.

**Truy vết.** REQ-18; CMP-LAW-05; SEC-30; BP-07.

**Tiền điều kiện.** Có mục `RESOLVED` hoặc `DISCARDED` quá `18.dlq.retention.closed-days` (90 ngày) để dọn.

**Kích hoạt.** Tác vụ 03:00 (ShedLock, một bản chạy); tác vụ ngưỡng mỗi phút; Chi hoặc Bình mở UI-18-06.

**Đảm bảo tối thiểu.** Mục mở không bao giờ bị xóa nội dung; mục liên kết sự cố chưa đóng hoặc lệnh giữ pháp lý được hoãn dọn; siêu dữ liệu giữ tới `18.dlq.retention.metadata-days` (365 ngày).

**Đảm bảo thành công.** Mục quá hạn ở `EXPIRED`, chỉ còn siêu dữ liệu; chỉ số `dh_ops_dlq_depth`, `dh_ops_dlq_oldest_age_seconds`, `dh_ops_dlq_replay_total`, `dh_ops_dlq_poison_total` phát đều; EVT-18-08 phát một lần khi vượt và một lần khi trở lại dưới ngưỡng.

**Luồng chính.**
1. Tác vụ dọn chọn mục đóng quá hạn theo lô 1.000 (API-18-080 hiện chính sách và số chờ dọn).
2. Tác vụ xóa payload nội tuyến, đối tượng Garage và bản sửa; giữ nguồn, mã lỗi, lớp lỗi, thời điểm, kết quả.
3. Tác vụ chuyển mục sang `EXPIRED`, ghi số mục và dung lượng đã dọn.
4. Tác vụ ngưỡng so độ sâu với `18.dlq.threshold.depth` (1.000), tuổi với `18.dlq.threshold.age-hours` (24 giờ), tỷ lệ phát lại lỗi với `18.dlq.threshold.replay-failure-percent` (20%); vượt thì phát EVT-18-08 loại tương ứng.
5. Chi mở UI-18-06 (API-18-081). Hệ thống hiện thẻ tổng theo trạng thái, nguồn, lớp lỗi, tuổi, thời gian xử lý trung vị, tỷ lệ phát lại thành công, biểu đồ xu hướng theo ngày, bảng theo nguồn.

**Luồng thay thế.**
- **2a. Hoãn dọn.** Mục liên kết sự cố chưa đóng hoặc có lệnh giữ pháp lý của PH-09: bỏ qua tới khi gỡ.
- **3a. Mục mở quá lâu.** Mục mở quá `18.dlq.retention.open-max-days` (365 ngày) không bị xóa; tác vụ tạo việc nhắc người xử lý và phát EVT-18-08 loại `AGE`.
- **5a. Kỳ dài.** Khoảng 90 ngày đọc từ bảng tổng hợp ngày, không quét chỉ mục.
- **5b. Người xem.** Bình (VW) chỉ thấy thẻ thống kê, không thấy danh sách mục.

**Luồng ngoại lệ.**
- **E1. Garage xóa lỗi (bước 2).** ERR-18-104 (worker): "Nội dung bản tin trong kho không khớp tổng kiểm tra. Báo quản trị nền tảng." Tác vụ thử lại lần sau, UI-18-06 hiện số nội dung quá hạn chưa xóa được.
- **E2. Khoảng thời gian không hợp lệ (bước 5).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-18-025; BR-18-026.

**Màn hình, API.** UI-18-06, UI-18-24; API-18-080, 081.
:::

### 6.20. UC-18-20 · Soạn, kiểm trường cấm và duyệt mẫu thông báo

::: dac-ta
**Mục tiêu.** Tỉnh tự soạn nội dung thư, SMS, thông báo trong ứng dụng theo văn phong của mình mà không thể vô tình đưa dữ liệu mức Hạn chế hay Nhạy cảm vào thư (FR-00-062), và mỗi phiên bản mẫu có người thứ hai duyệt.

**Tác nhân chính.** TA (Mai) soạn (`PERM-18-template`); TA (Tuấn) duyệt (`PERM-18-approve`); PA soạn mẫu `COMMON`.

**Tác nhân phụ.** Phân hệ chủ loại thông báo (khai báo biến và mức phân loại); Việc của tôi.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-035.

**Truy vết.** REQ-18; FR-00-062; CMP-LAW-05; ADR-184; BP-07.

**Tiền điều kiện.** PH-01 đã khai báo biến của loại thông báo `ph01.ho-so-da-duyet` kèm mức phân loại từng biến (`tenHttt` `INTERNAL`, `lienKet` `PUBLIC`, `soDienThoaiDauMoi` `RESTRICTED`).

**Kích hoạt.** Mai mở UI-18-11, bấm "+ Mẫu" hoặc sửa mẫu ở UI-18-12.

**Đảm bảo tối thiểu.** Phiên bản dùng biến cấm không gửi duyệt được; phiên bản `ACTIVE` cũ vẫn dùng cho tới khi phiên bản mới được duyệt.

**Đảm bảo thành công.** Phiên bản mới `ACTIVE`, phiên bản `ACTIVE` cũ của cùng kênh `RETIRED`; mọi thông báo sau đó dùng phiên bản mới.

**Luồng chính.**
1. Mai soạn phiên bản 2 của mẫu thư `ph01.ho-so-da-duyet` (API-18-085). Hệ thống kiểm cú pháp Mustache không logic: chỉ `{{biến}}`, khối lặp đơn, không hàm, không phần tử HTML ngoài danh sách cho phép.
2. Hệ thống kiểm trường cấm: mọi biến dùng phải có mức `PUBLIC` hoặc `INTERNAL`; với kênh SMS, nội dung sau khi điền không quá 320 ký tự.
3. Mai bấm "Xem thử" với dữ liệu mẫu (API-18-086), rồi "Gửi duyệt" (API-18-087): phiên bản sang `IN_REVIEW`, việc `ph18.approve-template` tạo cho người có `PERM-18-approve` trừ Mai.
4. Tuấn xem thử, bấm "Duyệt" (API-18-088). Hệ thống kiểm Tuấn khác Mai.
5. Hệ thống đặt phiên bản 2 `ACTIVE`, phiên bản 1 `RETIRED`, đóng việc.

**Luồng thay thế.**
- **1a. Tỉnh không có mẫu riêng.** Dùng mẫu `COMMON` của PA.
- **4a. Trả lại.** Tuấn trả lại kèm lý do (API-18-089): phiên bản về `DRAFT`.
- **5a. Ngừng mẫu.** Mai ngừng mẫu (API-18-090): `RETIRED`, quy tắc dùng mẫu bị tắt và người quản trị được báo.
- **1b. Xem danh sách, tạo mẫu mới.** Mai xem mẫu (API-18-082, 084) và tạo mẫu mới (API-18-083).

**Luồng ngoại lệ.**
- **E1. Cú pháp sai hoặc biến chưa khai báo (bước 1).** ERR-18-040 (422): "Mẫu có lỗi tại dòng {dòng}: {chi tiết}."
- **E2. Mẫu dùng biến cấm `soDienThoaiDauMoi` (bước 2).** ERR-18-039 (422): "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."
- **E3. Người duyệt trùng người soạn (bước 4).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."

**Quy tắc áp dụng.** BR-18-027; LP-18-01.

**Màn hình, API.** UI-18-11, UI-18-12, UI-18-15; API-18-082, 083, 084, 085, 086, 087, 088, 089, 090.
:::

```{.mermaid caption="Trình tự soạn và duyệt phiên bản mẫu thông báo"}
sequenceDiagram
  actor TA as TA Mai
  actor AP as TA Tuấn
  participant O as dh-platform ops
  participant N as Bộ gửi thông báo
  TA->>O: Soạn phiên bản 2 (API-18-085)
  O->>O: Kiểm cú pháp Mustache, kiểm mức từng biến
  TA->>O: Xem thử rồi gửi duyệt (API-18-086, 087)
  O-->>AP: Việc ph18.approve-template
  AP->>O: Duyệt (API-18-088)
  O->>O: Kiểm người duyệt khác người soạn
  O->>O: Phiên bản 2 ACTIVE, phiên bản 1 RETIRED
  O-->>N: Thông báo sau đó dùng phiên bản 2
```

Hình cho thấy kiểm trường cấm chạy ngay khi soạn, trước cả khi có người duyệt, nên mẫu vi phạm không bao giờ tới hàng duyệt.

### 6.21. UC-18-21 · Phân hệ gửi thông báo và phân giải người nhận

::: dac-ta
**Mục tiêu.** Mọi phân hệ gửi thư, SMS, thông báo trong ứng dụng bằng một API chung chỉ với tham chiếu người nhận, không phải giữ địa chỉ, và một lệnh gửi lặp lại không sinh thư trùng.

**Tác nhân chính.** DU gọi (scope `ops:notify`), ví dụ `dh-connect` của PH-01 báo hồ sơ kết nạp đã duyệt.

**Tác nhân phụ.** PH-12 (người, nhóm, vai trò); PH-01 (đầu mối HTTT, PH-18 gọi bằng `onboarding:internal-read`); PH-13 (lịch trực cho `ON_CALL`); máy chủ thư SMTP/TLS; SMS gateway (IF-09); UC-18-22 (tùy chọn nhận).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-036, FR-18-037.

**Truy vết.** REQ-18; FR-00-061; FR-00-062; CMP-LAW-05; ADR-042; ADR-184; BP-07.

**Tiền điều kiện.** Loại thông báo `ph01.ho-so-da-duyet` có mẫu `ACTIVE` cho kênh `EMAIL` (tenant hoặc `COMMON`).

**Kích hoạt.** PH-01 gọi API-18-091; quy tắc sự kiện sinh thông báo (UC-18-23).

**Đảm bảo tối thiểu.** Phân hệ gọi không bao giờ nhận địa chỉ người nhận (BR-18-029); thông báo không mang biến mức cấm; lỗi gửi được thử lại theo UC-18-24.

**Đảm bảo thành công.** `notification_message` ở outbox; mỗi người nhận và kênh có `notification_delivery` ở `SENT` hoặc `SUPPRESSED`; bên gọi tra được trạng thái bằng `messageId`.

**Luồng chính.**
1. PH-01 gọi API-18-091 với loại `ph01.ho-so-da-duyet`, biến `tenHttt`, `lienKet`, người nhận `SYSTEM_CONTACT` của HTTT `qlvb-t68` loại kỹ thuật và `Idempotency-Key`. Hệ thống kiểm khóa lũy đẳng trong 24 giờ và mẫu có phiên bản `ACTIVE`.
2. Hệ thống kiểm biến truyền vào khớp khai báo và không có biến mức cấm, ghi `notification_message` vào outbox trong giao dịch, trả `202` kèm `messageId`.
3. Tác vụ gửi tách tham chiếu theo loại, tra bộ đệm 5 phút: `SYSTEM_CONTACT` hỏi PH-01 đầu mối theo `systemCode` và loại; `USER`, `GROUP`, `ROLE` hỏi PH-12; `ON_CALL` lấy theo lịch trực của PH-13.
4. Hệ thống gộp trùng người, bỏ tài khoản bị vô hiệu, lấy địa chỉ kênh tương ứng, áp tùy chọn nhận và giờ yên lặng (UC-18-22).
5. Hệ thống dựng nội dung và gửi: `EMAIL` qua SMTP/TLS, `SMS` qua gateway REST khi `18.notify.sms.enabled`, `IN_APP` ghi hộp thông báo; ghi `notification_delivery` từng người nhận và kênh.
6. PH-01 tra trạng thái bằng `messageId` (API-18-093).

**Luồng thay thế.**
- **1a. Gọi lại cùng khóa, cùng thân.** Hệ thống trả kết quả cũ, không gửi lại.
- **1b. Chế độ đồng bộ.** PH-12 gửi thư mang liên kết đặt lại mật khẩu qua API-18-092 (chỉ `EMAIL`, một người nhận): hệ thống chạy bước 3 đến 5 ngay, chờ máy chủ thư nhận trong `18.notify.sync.timeout-ms` (3.000 ms), trả `200 SENT`.
- **3a. Gọi thử phân giải.** DU gọi API-18-094: hệ thống trả số người nhận theo kênh, không trả địa chỉ.
- **3b. PH-01 hoặc PH-12 không phản hồi.** Thông báo giữ ở `QUEUED`, thử lại theo UC-18-24; UI-18-13 hiện "Đang chờ phân giải người nhận."
- **4a. Phân giải được một phần.** Gửi cho phần được, ghi tham chiếu lỗi vào nhật ký.
- **4b. Mức `URGENT`.** PH-13 gửi người trực: bỏ qua giờ yên lặng, ưu tiên hàng đợi riêng.
- **1c. Tenant `SUSPENDED`.** Chỉ nhóm bắt buộc được gửi (sự kiện `platform.tenant.status-changed.v1`).

**Luồng ngoại lệ.**
- **E1. Khóa lũy đẳng dùng lại với nội dung khác (bước 1).** ERR-18-009 (409): "Yêu cầu trùng khóa với một yêu cầu khác nội dung."
- **E2. Không có mẫu đang dùng (bước 1).** ERR-18-041 (409): "Mẫu {mã} chưa có phiên bản đang dùng."
- **E3. Biến mức cấm (bước 2).** ERR-18-039 (422): "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."
- **E4. Không phân giải được người nhận nào (bước 3).** ERR-18-042 (422): "Không xác định được người nhận {mã}." Hiện ở dòng gửi của UI-18-13.
- **E5. Kênh thư không sẵn sàng ở chế độ đồng bộ (nhánh 1b).** ERR-18-044 (503): "Kênh gửi đang gián đoạn. Thử lại sau."
- **E6. Gửi thất bại cuối cùng (bước 5).** Phát EVT-18-13 cho phân hệ gọi và PH-13 (chi tiết ở UC-18-24).

**Quy tắc áp dụng.** BR-18-027; BR-18-028; BR-18-029; BR-18-030; LP-18-03.

**Màn hình, API.** UI-18-13; API-18-091, 092, 093, 094.
:::

```{.mermaid caption="Trình tự gửi thông báo bất đồng bộ và phân giải người nhận"}
sequenceDiagram
  participant C as PH-01 dh-connect
  participant O as dh-platform ops
  participant Q as Outbox thông báo
  participant P1 as PH-01 đầu mối
  participant S as Máy chủ thư tỉnh
  C->>O: Gửi thông báo kèm tham chiếu người nhận (API-18-091)
  O->>O: Kiểm khóa lũy đẳng, mẫu ACTIVE, biến cấm
  O->>Q: Ghi notification_message
  O-->>C: 202 kèm messageId
  Q->>P1: Phân giải đầu mối kỹ thuật của qlvb-t68
  P1-->>Q: Danh sách người nhận
  Q->>Q: Gộp trùng, áp tùy chọn và giờ yên lặng
  Q->>S: Gửi thư qua SMTP TLS
  S-->>Q: Đã nhận
  C->>O: Tra trạng thái bằng messageId (API-18-093)
```

Hình cho thấy địa chỉ chỉ xuất hiện giữa PH-18 và máy chủ thư; phân hệ gọi chỉ biết `messageId` và trạng thái.

### 6.22. UC-18-22 · Đặt tùy chọn nhận, giờ yên lặng và đọc thông báo trong ứng dụng

::: dac-ta
**Mục tiêu.** Người dùng tự chọn nhận loại thông báo nào qua kênh nào và đặt giờ yên lặng, nhưng không thể tắt thông báo bắt buộc (bốn mắt, an ninh, thay đổi API bắt buộc).

**Tác nhân chính.** Người dùng đăng nhập (Quân), dữ liệu của chính mình.

**Tác nhân phụ.** Tác vụ gửi (UC-18-21).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-038.

**Truy vết.** REQ-18; FR-00-061.

**Tiền điều kiện.** Không.

**Kích hoạt.** Quân mở `/ca-nhan/thong-bao` (UI-18-14) hoặc biểu tượng chuông trên thanh trên.

**Đảm bảo tối thiểu.** Nhóm bắt buộc và mức `URGENT` luôn được gửi (BR-18-030); thông báo giữ trong giờ yên lặng tối đa 12 giờ.

**Đảm bảo thành công.** `user_notification_pref` có phiên bản mới; lần gửi sau tuân theo lựa chọn mới.

**Luồng chính.**
1. Quân mở màn (API-18-095). Hệ thống trả danh sách nhóm loại thông báo, kênh, trạng thái; nhóm bắt buộc hiện khóa.
2. Quân tắt kênh `EMAIL` của nhóm "Thông báo luồng" và đặt giờ yên lặng 22:00 đến 06:00, rồi lưu (API-18-096). Hệ thống kiểm không tắt nhóm bắt buộc và định dạng giờ.
3. Hệ thống lưu `user_notification_pref` có phiên bản.
4. Tác vụ gửi áp tùy chọn: kênh tắt thì `SUPPRESSED`; trong giờ yên lặng thì giữ đến hết giờ (trừ `URGENT`).

**Luồng thay thế.**
- **1a. Hộp thông báo trong ứng dụng.** Quân mở chuông (API-18-097): danh sách mới nhất; bấm một thông báo để đánh dấu đã đọc (API-18-098).

**Luồng ngoại lệ.**
- **E1. Tắt nhóm bắt buộc (bước 2).** ERR-18-046 (422): "Không tắt được nhóm thông báo {nhóm} vì là thông báo bắt buộc."
- **E2. Định dạng giờ sai (bước 2).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-18-030.

**Màn hình, API.** UI-18-14; API-18-095, 096, 097, 098.
:::

### 6.23. UC-18-23 · Cấu hình quy tắc thông báo theo sự kiện

::: dac-ta
**Mục tiêu.** Quản trị tỉnh quyết định sự kiện nào của các phân hệ sinh thông báo cho ai, theo mẫu nào và có tạo việc hay không, mà không cần sửa mã của phân hệ phát sự kiện.

**Tác nhân chính.** TA (Mai), `PERM-18-template`; PA cho quy tắc `COMMON`.

**Tác nhân phụ.** Phân hệ phát sự kiện (bảng sự kiện PH-18 tiêu thụ, FRS 9.3b); UC-18-21 (gửi); UC-18-25 (tạo việc).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-039.

**Truy vết.** REQ-18; FR-00-061; BP-07.

**Tiền điều kiện.** Sự kiện EVT-04-07 (trạng thái triển khai luồng đổi) thuộc bảng sự kiện PH-18 tiêu thụ; mẫu `ph04.trien-khai-luong` có phiên bản `ACTIVE`.

**Kích hoạt.** Mai mở UI-18-11 tab "Quy tắc"; PH-18 tiêu thụ sự kiện qua inbox.

**Đảm bảo tối thiểu.** Một sự kiện chỉ sinh một thông báo cho mỗi quy tắc nhờ khóa lũy đẳng `eventId:ruleId` (BR-18-028); sự kiện lỗi không làm mất sự kiện khác.

**Đảm bảo thành công.** `notification_rule` lưu; mỗi sự kiện khớp sinh đúng một thông báo (và một việc nếu `createTask`).

**Luồng chính.**
1. Mai tạo quy tắc: sự kiện EVT-04-07, điều kiện `env == "PROD" && status == "FAILED"`, mẫu `ph04.trien-khai-luong`, người nhận vai `ROLE-TENANT_OPERATOR` (API-18-100). Hệ thống kiểm sự kiện đã đăng ký tiêu thụ, biểu thức đúng cú pháp CEL rút gọn và chỉ dùng trường mã, trạng thái, mẫu `ACTIVE`.
2. Hệ thống lưu `notification_rule`.
3. Consumer nhận sự kiện qua inbox (khử trùng theo `eventId`), tìm quy tắc khớp của T68 (cùng quy tắc `COMMON` tenant không ghi đè) và đánh giá điều kiện.
4. Quy tắc khớp: hệ thống tạo thông báo như UC-18-21 với khóa lũy đẳng `eventId:ruleId`; có `createTask` thì tạo việc như UC-18-25.

**Luồng thay thế.**
- **1a. Tắt quy tắc `COMMON`.** Mai tắt một quy tắc chung cho T68 (API-18-101): ghi lớp phủ `enabled = false`.
- **1b. Xem quy tắc.** Mai xem danh sách quy tắc (API-18-099).
- **3a. Sự kiện xử lý lỗi.** Sau 5 lần: inbox `FAILED`, ghi ERR-18-124, hiện ở UI-18-24 (LP-18-06).

**Luồng ngoại lệ.**
- **E1. Sự kiện chưa đăng ký tiêu thụ (bước 1).** ERR-18-045 (422): "Sự kiện {sự kiện} chưa được phân hệ vận hành tiêu thụ nên không tạo được quy tắc."
- **E2. Biểu thức sai (bước 1).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E3. Mẫu chưa có phiên bản đang dùng (bước 1).** ERR-18-041 (409): "Mẫu {mã} chưa có phiên bản đang dùng."
- **E4. Không xử lý được sự kiện (nhánh 3a).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."

**Quy tắc áp dụng.** BR-18-028; BR-18-032; LP-18-06.

**Màn hình, API.** UI-18-11; API-18-099, 100, 101.
:::

### 6.24. UC-18-24 · Xử lý thư trả lại, danh sách chặn và tra nhật ký gửi

::: dac-ta
**Mục tiêu.** Thư lỗi tạm thời được thử lại tự động, địa chỉ hỏng bị chặn để không gửi mãi vào chỗ chết, đầu mối HTTT được nhắc cập nhật, và quản trị tỉnh tra được ai đã nhận gì mà không thấy nội dung hay địa chỉ đầy đủ.

**Tác nhân chính.** Hệ thống (tác vụ gửi, máy chủ thư báo về bằng `ops:notify`); TA (Mai) gửi lại, gỡ chặn (`PERM-18-template`).

**Tác nhân phụ.** TO (Chi), AU (Phúc) xem nhật ký (`PERM-18-read`); PH-01, PH-12 (nhận EVT-18-12); PH-13 (tra trạng thái thông báo người trực; kênh `CRITICAL` dự phòng vẫn do `alert-relay` của PH-13 giữ).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-040, FR-18-041.

**Truy vết.** REQ-18; FR-00-061; SEC-60; BP-07.

**Tiền điều kiện.** Có `notification_delivery` lỗi hoặc thư trả lại.

**Kích hoạt.** Gửi lỗi tạm thời; máy chủ thư gửi báo cáo trả lại; Mai mở `/van-hanh/thong-bao/nhat-ky` và bấm "Gửi lại" hoặc "Gỡ chặn".

**Đảm bảo tối thiểu.** Nhật ký chỉ hiện địa chỉ đã che (ví dụ `n***@t68.gov.vn`), không hiện nội dung đã dựng (BR-18-029); nhật ký giữ `18.notify.log-retention-days` (180 ngày).

**Đảm bảo thành công.** Lần gửi ở `DELIVERED`, hoặc `FAILED` có EVT-18-13, hoặc `BOUNCED` với địa chỉ trong `suppression_entry` và EVT-18-12 đã phát.

**Luồng chính.**
1. Máy chủ thư trả mã 4xx: hệ thống thử lại tới `18.notify.retry.max-attempts` (5) lần trong `18.notify.retry.window-hours` (24 giờ), giãn cách 1, 5, 30 phút, 2 giờ, 6 giờ.
2. Hết lần thử: lần gửi `FAILED`, phát EVT-18-13.
3. Máy chủ thư báo trả lại cứng cho đầu mối `n***@t68.gov.vn` (API-18-106): lần gửi `BOUNCED`, thêm băm địa chỉ vào `suppression_entry`, phát EVT-18-12 với `recipientRef` gốc để PH-01 nhắc cập nhật đầu mối.
4. Lần gửi sau tới địa chỉ bị chặn: `SUPPRESSED`, không gửi.
5. Mai mở nhật ký (API-18-102). Hệ thống trả lần gửi với loại, kênh, người nhận đã che, trạng thái, lần thử, nguồn, thời điểm; mở một lần gửi thấy mẫu và phiên bản, mã phản hồi máy chủ, lịch sử thử.
6. Sau khi PH-01 cập nhật đầu mối, Mai bấm "Gửi lại" (API-18-103): hệ thống tạo lần gửi mới cho người nhận đó.

**Luồng thay thế.**
- **3a. Trả lại mềm.** Trả lại mềm quá `18.notify.bounce.soft-limit` (3) lần trong 30 ngày: xử lý như trả lại cứng.
- **6a. Gỡ chặn.** Mai xem danh sách chặn (API-18-104) và gỡ một địa chỉ kèm lý do (API-18-105).
- **5a. PH-13 tra trạng thái.** PH-13 gọi API-18-093 cho thông báo cảnh báo đã gửi người trực.

**Luồng ngoại lệ.**
- **E1. Máy chủ thư lỗi (bước 1).** ERR-18-110 (worker): "Gửi thư chưa thành công; đang thử lại."
- **E2. SMS gateway lỗi (bước 1).** ERR-18-111 (worker): "Gửi SMS chưa thành công; đang thử lại."
- **E3. Thư trả lại (bước 3).** ERR-18-112 (worker): "Thư bị trả lại ({loại})."
- **E4. Người nhận bị chặn (bước 4).** ERR-18-113 (worker): "Không gửi vì người nhận trong danh sách chặn."
- **E5. Gửi đồng bộ tới địa chỉ bị chặn (UC-18-21 nhánh 1b).** ERR-18-043 (409): "Người nhận đang trong danh sách chặn."
- **E6. Gửi lại thông báo đã `DELIVERED` (bước 6).** ERR-18-006 (409): "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}.".
- **E7. Bộ lọc nhật ký sai (bước 5).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-18-029; BR-18-031.

**Màn hình, API.** UI-18-13; API-18-093, 102, 103, 104, 105, 106.
:::

### 6.25. UC-18-25 · Phân hệ đăng ký loại việc, tạo và đóng việc lũy đẳng

::: dac-ta
**Mục tiêu.** Mọi phân hệ đưa việc chờ duyệt, chờ xử lý vào một hộp "Việc của tôi" chung, phân hệ nguồn vẫn là chủ trạng thái và là bên đóng việc, lệnh đến sai thứ tự hay lặp lại không làm sai trạng thái.

**Tác nhân chính.** DU (scope `ops:task`), ví dụ `dh-connect` của PH-02 tạo việc duyệt phiên bản dịch vụ.

**Tác nhân phụ.** PH-12 (phân giải người nhận); UC-18-27 (lịch ngày làm việc để tính hạn); `dh-console` (đếm việc qua EVT-18-14).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-042, FR-18-043.

**Truy vết.** REQ-18; FR-00-070; FR-00-071; FR-00-072.

**Tiền điều kiện.** Loại việc `ph02.approve-version` đã đăng ký; mười loại việc của chính PH-18 (`ph18.approve-param`, `ph18.approve-replay`, `ph18.approve-revision`, `ph18.approve-template`, `ph18.approve-restore`, `ph18.approve-migration`, `ph18.approve-cutover`, `ph18.dlq-assigned`, `ph18.ff-retire`, `ph18.incident-assigned`) được nạp sẵn.

**Kích hoạt.** DU khởi động và đăng ký loại việc; phân hệ tạo đối tượng chờ duyệt; phân hệ hoàn tất hoặc hủy đối tượng.

**Đảm bảo tối thiểu.** Việc bốn mắt không hiện với người tạo đề nghị (`excludeUsers[]`); PH-18 vắng thì việc duyệt vẫn hiện ở màn của phân hệ nguồn (phụ thuộc mềm, LP-18-04).

**Đảm bảo thành công.** `task_item` ở `OPEN` với hạn tính theo ngày làm việc và lịch nhắc; khi nguồn đóng, việc ở `DONE` hoặc `CANCELLED`, EVT-18-14 phát.

**Luồng chính.**
1. `dh-connect` gửi danh sách loại việc của PH-02 (API-18-107). Hệ thống kiểm mã có tiền tố `ph02.`, quyền xem là mã `PERM-*` hợp lệ, liên kết màn là route tương đối thuộc cây route của `dh-console`, rồi lưu lũy đẳng theo mã.
2. Khi Mai gửi duyệt phiên bản dịch vụ `API-HOTICH-KHAISINH` v2, PH-02 gọi `PUT /ops/internal/v1/tasks/{sourceRef}` (API-18-109) với `sourceVersion` 1, người nhận vai `ROLE-TENANT_ADMIN`, `excludeUsers` là Mai, hạn 2 ngày làm việc. Hệ thống kiểm loại việc và `summary` không chứa trường mức cấm.
3. Hệ thống so `sourceVersion` với bản đã lưu; mới thì tính hạn theo lịch T68, phân giải người nhận, bỏ Mai, tạo `task_item` `OPEN` và lịch nhắc.
4. Khi Tuấn duyệt ở PH-02, PH-02 gọi đóng việc (API-18-110). Hệ thống đặt `DONE`, hủy nhắc, phát EVT-18-14.

**Luồng thay thế.**
- **3a. Lệnh sai thứ tự.** Lệnh tạo có `sourceVersion` nhỏ hơn bản đã lưu (nguồn đã đóng trước): hệ thống bỏ qua.
- **4a. Đóng lại việc đã đóng.** Hệ thống trả `200` không đổi.
- **4b. Nguồn hủy.** Việc ở `CANCELLED`.
- **1a. Xem loại việc.** Người có `PERM-18-read` xem danh sách loại (API-18-108).

**Luồng ngoại lệ.**
- **E1. Mã loại không thuộc phân hệ gọi (bước 1).** ERR-18-017 (403): "Phân hệ không sở hữu {đối tượng} {mã}.". Hiện ở UI-18-24.
- **E2. Quyền xem hoặc liên kết màn không hợp lệ (bước 1).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E3. Loại việc chưa đăng ký (bước 2).** ERR-18-047 (422): "Loại việc {loại} chưa được đăng ký."
- **E4. Tóm tắt chứa trường mức cấm (bước 2).** ERR-18-039 (422): "Mẫu dùng trường {biến} mức {mức}. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm."
- **E5. Cập nhật việc đã đóng với `sourceVersion` mới (bước 3).** ERR-18-048 (409): "Việc {mã} đã đóng."

**Quy tắc áp dụng.** BR-18-032; LP-18-04.

**Màn hình, API.** UI-18-15; API-18-107, 108, 109, 110.
:::

### 6.26. UC-18-26 · Xử lý Việc của tôi, nhắc và quá hạn

::: dac-ta
**Mục tiêu.** Mỗi người thấy trên một danh sách mọi việc đang chờ mình ở mọi phân hệ, biết việc nào sắp hoặc đã quá hạn, và việc quá hạn lâu được leo thang cho người quản lý.

**Tác nhân chính.** Người dùng đăng nhập (Tuấn); chỉ thấy việc mình là người nhận và vẫn còn `viewPermission`.

**Tác nhân phụ.** Phân hệ nguồn (màn xử lý thật); UC-18-21 (gửi nhắc); `dh-console` (thẻ trang chủ).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-044.

**Truy vết.** REQ-18; FR-00-070; FR-00-072.

**Tiền điều kiện.** Tuấn đã chọn tenant T68.

**Kích hoạt.** Tuấn mở `/ca-nhan/viec` hoặc xem thẻ "Việc của tôi" trên trang chủ; tác vụ nhắc chạy mỗi 15 phút.

**Đảm bảo tối thiểu.** Mất quyền xem thì việc bị ẩn ngay lúc đọc; nhận việc không đổi trạng thái ở phân hệ nguồn.

**Đảm bảo thành công.** Tuấn mở được việc và đi thẳng tới màn xử lý của phân hệ nguồn; việc nhận ở `IN_PROGRESS` báo cho người cùng nhận.

**Luồng chính.**
1. Tuấn mở danh sách (API-18-111). Hệ thống trả việc `OPEN`, `IN_PROGRESS` của Tuấn, kiểm lại quyền xem tại thời điểm đọc.
2. Hệ thống hiển thị tên loại, tóm tắt, phân hệ, hạn (đỏ khi quá hạn), người cùng nhận, liên kết.
3. Tuấn mở việc `ph18.approve-replay` (API-18-112), bấm "Nhận việc" (API-18-181) để báo người cùng nhận (`IN_PROGRESS`, EVT-18-14), rồi bấm liên kết sang UI-18-05.
4. Tác vụ nhắc gửi nhắc trước hạn `18.task.reminder.before-hours` (24 giờ) và khi quá hạn; quá hạn `18.task.overdue.escalate-hours` (48 giờ) thì gửi cho người quản lý theo `recipientRef` leo thang của loại.

**Luồng thay thế.**
- **1a. Thẻ trang chủ.** Hiện số việc theo hạn và năm việc gần hạn nhất.
- **4a. Dọn.** Việc `DONE` quá `18.task.retention-days` (365 ngày) bị xóa.

**Luồng ngoại lệ.**
- **E1. Việc không còn thuộc người dùng (bước 3).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}.".
- **E2. Nhận việc đã đóng (bước 3).** ERR-18-048 (409): "Việc {mã} đã đóng."

**Quy tắc áp dụng.** BR-18-032.

**Màn hình, API.** UI-18-15; API-18-111, 112, 181.
:::

### 6.27. UC-18-27 · Quản lý lịch ngày làm việc, cửa sổ bảo trì và đóng băng

::: dac-ta
**Mục tiêu.** Một lịch ngày làm việc theo tỉnh dùng chung để mọi phân hệ tính hạn đúng ngày lễ, ngày làm bù; một nơi khai báo cửa sổ bảo trì và đóng băng thay đổi để phân hệ chủ tự quyết định chặn thao tác.

**Tác nhân chính.** TA (Mai) cho tenant, PA (Hà) cho lịch `COMMON` và cửa sổ nền tảng (`PERM-18-calendar`).

**Tác nhân phụ.** DU tính hạn, đọc đóng băng (scope `ops:calendar-read`: PH-01, PH-02, PH-04, PH-08); PH-20 (`platform.release.published.v1`, `platform.tenant.upgrade-changed.v1`); UC-18-23 (thông báo bảo trì).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-045, FR-18-046.

**Truy vết.** REQ-18; Q02-27; Q01-23; ERR-02-039; BP-08.

**Tiền điều kiện.** Lịch `COMMON` năm 2027 đã có ngày lễ quốc gia.

**Kích hoạt.** Mai mở `/van-hanh/lich` tab "Ngày làm việc" hoặc "Bảo trì, đóng băng"; DU gọi API tính hạn, đọc đóng băng; PH-20 phát sự kiện phát hành kèm cửa sổ bảo trì.

**Đảm bảo tối thiểu.** Thiếu lịch tenant thì dùng `COMMON`; thiếu cả hai thì chỉ bỏ cuối tuần và trả cờ `calendarMissing` (BR-18-034); PH-18 vắng thì phân hệ coi là không đóng băng và ghi cảnh báo (BR-18-035).

**Đảm bảo thành công.** `work_calendar`, `calendar_holiday` của T68 năm 2027 lưu, EVT-18-15 phát; `maintenance_window` lưu, EVT-18-16 phát; phân hệ đọc được trạng thái đóng băng theo môi trường.

**Luồng chính.**
1. Mai mở lịch năm 2027 (API-18-113). Hệ thống trả lịch tenant, chưa có thì sao từ `COMMON`.
2. Mai thêm ngày nghỉ "Giỗ Tổ Hùng Vương" và ngày làm bù thứ Bảy 24/04/2027, rồi lưu (API-18-114, 115). Hệ thống kiểm ngày thuộc năm, không trùng, ngày làm bù không rơi vào ngày làm việc sẵn; lưu lịch và phát EVT-18-15.
3. PH-01 gọi tính hạn 10 ngày làm việc từ 20/04/2027 (API-18-117). Hệ thống cộng ngày làm việc theo lịch T68 và `18.calendar.timezone`, trả mốc hạn và danh sách ngày đã bỏ qua.
4. Mai tạo cửa sổ `FREEZE` cho môi trường `PROD` từ 25/04 đến 02/05/2027 (API-18-119). Hệ thống kiểm thời gian hợp lệ và không chồng cửa sổ cùng loại và phạm vi, lưu và phát EVT-18-16.
5. PH-02 đọc `freeze-status` của T68 (API-18-122). Hệ thống trả cửa sổ đang hiệu lực theo môi trường; PH-02 tự quyết định chặn thao tác của mình.

**Luồng thay thế.**
- **4a. Cửa sổ bảo trì có thông báo.** Cửa sổ `MAINTENANCE` có `notify = true`: hệ thống gửi thông báo trước `18.maintenance.notice-hours` (72 giờ) cho người dùng T68 theo quy tắc `ops.maintenance`.
- **4b. Từ sự kiện PH-20.** PH-18 nhận `platform.release.published.v1` và tạo cửa sổ bảo trì tương ứng.
- **4c. Sửa, hủy cửa sổ.** Mai sửa (API-18-120) hoặc hủy cửa sổ chưa kết thúc kèm lý do (API-18-121); phát EVT-18-16.
- **5a. PH-04 còn giữ cửa sổ riêng.** Khi PH-04 đăng ký `04.freeze.windows`, `freeze-status` trả cả hai nguồn (Q18-07).
- **3a. Ngày làm việc trong khoảng.** DU đọc danh sách ngày làm việc (API-18-116) và giữ đệm 24 giờ, làm mới khi nhận EVT-18-15.

**Luồng ngoại lệ.**
- **E1. Lịch không hợp lệ (bước 2).** ERR-18-049 (422): "Lịch năm {năm} không hợp lệ: {chi tiết}."
- **E2. Cửa sổ chồng lấn (bước 4).** ERR-18-050 (409): "Cửa sổ {loại} chồng với cửa sổ {mã} từ {bắt đầu} đến {kết thúc}."
- **E3. PH-18 vắng khi DU đọc (bước 3, 5).** DU dùng bản đệm, quá 24 giờ thì tính theo cuối tuần hoặc coi là không đóng băng và ghi cảnh báo (LP-18-04).

**Quy tắc áp dụng.** BR-18-033; BR-18-034; BR-18-035; LP-18-04.

**Màn hình, API.** UI-18-16; API-18-113, 114, 115, 116, 117, 118, 119, 120, 121, 122.
:::

### 6.28. UC-18-28 · Mở, xử lý và đóng sự cố vận hành

::: dac-ta
**Mục tiêu.** Mỗi cảnh báo nghiêm trọng thành một hồ sơ sự cố có người chịu trách nhiệm, mốc thời gian không sửa được, liên kết tới mục DLQ và lượt phát lại liên quan, và chỉ đóng khi đã nêu được nguyên nhân gốc và bài học.

**Tác nhân chính.** TO (Chi) xử lý; SO (Dũng), TA, PA đóng (`PERM-18-incident`).

**Tác nhân phụ.** PH-13 (EVT-13-02, 04, 05, lịch trực, gọi API bằng `ops:incident-write`); UC-18-19 (EVT-18-08), UC-18-30 (EVT-18-19); UC-18-21 (thông báo `URGENT`); UC-18-25 (việc); PH-16 (EVT-18-18).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-047, FR-18-048, FR-18-049, FR-18-051.

**Truy vết.** REQ-18; LGC-NFR-004; SEC-72; SEC-73; SEC-75; CMP-LAW-06; BP-07.

**Tiền điều kiện.** Quy tắc mở sự cố của T68 đang bật (mặc định cho EVT-13-04, EVT-13-05, EVT-18-08 loại `DEPTH` mức P1, EVT-18-19).

**Kích hoạt.** PH-18 tiêu thụ sự kiện cảnh báo; PH-13 gọi API-18-132; Chi bấm "+ Sự cố" ở UI-18-17; Dũng bấm "Đóng sự cố" ở UI-18-18.

**Đảm bảo tối thiểu.** Mỗi `sourceRef` có tối đa một sự cố mở (BR-18-036); mốc thời gian chỉ thêm, không xóa (BR-18-037).

**Đảm bảo thành công.** Sự cố `SC-2027-0042` đi qua `OPEN`, `INVESTIGATING`, `MITIGATED`, `RESOLVED`, `CLOSED` với nguyên nhân, bài học và việc khắc phục; EVT-18-17, EVT-18-18 phát; sự cố vào báo cáo vận hành kỳ.

**Luồng chính.**
1. PH-18 nhận EVT-13-04 (đích hộ tịch không phản hồi) qua inbox. Hệ thống tìm sự cố đang mở cùng `sourceRef` hoặc cùng dấu hiệu trong 60 phút; không có thì tạo `SC-2027-0042` `OPEN` mức `SEV1` theo bảng ánh xạ.
2. Hệ thống gán người xử lý theo lịch trực của PH-13 (Chi), tạo việc `ph18.incident-assigned`, gửi thông báo `URGENT`, phát EVT-18-17.
3. Chi nhận việc và chuyển `INVESTIGATING` (API-18-127); hệ thống ghi `acknowledgedAt` và so với `18.incident.sev1-ack-minutes` (15 phút).
4. Chi liên kết nhóm DLQ 46 mục và thêm mốc "Đích hộ tịch đã phục hồi lúc 10:42" (API-18-129, 128). Hệ thống kiểm đối tượng tồn tại trong T68 và ghi `incident_link`, `incident_timeline`.
5. Chi phát lại nhóm (UC-18-17); khi lượt kết thúc, hệ thống tự thêm mốc. Chi chuyển `MITIGATED` rồi `RESOLVED`.
6. Dũng bấm "Đóng sự cố", nhập nguyên nhân gốc, bài học và hai việc khắc phục (API-18-131). Hệ thống kiểm mỗi phần đủ 30 ký tự, sự cố đang `RESOLVED` và không còn hồ sơ PH-09 mở.
7. Hệ thống tạo việc cho từng hành động khắc phục, chuyển `CLOSED`, phát EVT-18-18 và đưa sự cố vào báo cáo vận hành kỳ (UC-18-39).

**Luồng thay thế.**
- **1a. Tín hiệu lặp.** Có sự cố mở cùng dấu hiệu: thêm mốc "tín hiệu lặp" vào sự cố đó.
- **1b. Cảnh báo hết.** EVT-13-02: thêm mốc "tín hiệu đã hết"; sự cố còn `OPEN` chưa ai nhận thì gợi ý chuyển `MITIGATED`.
- **1c. Tạo tay.** Chi bấm "+ Sự cố", nhập tiêu đề, mức, mô tả (API-18-124): hệ thống tạo `OPEN` với mã `SC-{yyyy}-{nnnn}`.
- **2a. `SEV1` chưa ai nhận sau 15 phút.** Hệ thống leo thang cho TA và PA.
- **3a. Đổi mức độ hoặc người xử lý.** Hệ thống ghi mốc thời gian, gửi thông báo cho người mới, cập nhật việc (API-18-126).
- **4a. Gỡ liên kết nhầm.** Thêm mốc "gỡ liên kết" thay vì xóa.
- **7a. Tái diễn.** Sự cố `RESOLVED` tái diễn trước khi đóng: mở lại `INVESTIGATING`.
- **1d. Xem.** Người có `PERM-18-read` xem danh sách và chi tiết (API-18-123, 125).

**Luồng ngoại lệ.**
- **E1. Không xử lý được sự kiện sau 5 lần (bước 1).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ." UI-18-24 hiện số sự kiện mở sự cố chưa xử lý được (LP-18-06).
- **E2. Thiếu trường bắt buộc khi tạo tay (nhánh 1c).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E3. Chuyển trạng thái sai, thêm mốc vào sự cố đã đóng, hoặc hồ sơ PH-09 còn mở (bước 3, 4, 6).** ERR-18-006 (409): "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}.".
- **E4. Đối tượng liên kết không tồn tại (bước 4).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}.".
- **E5. Thiếu nguyên nhân hoặc bài học (bước 6).** ERR-18-052 (422): "Đóng sự cố cần nêu nguyên nhân gốc và bài học (mỗi phần ít nhất 30 ký tự)."

**Quy tắc áp dụng.** BR-18-036; BR-18-037; BR-18-046; LP-18-02; LP-18-06.

**Màn hình, API.** UI-18-17, UI-18-18; API-18-123, 124, 125, 126, 127, 128, 129, 131, 132.
:::

### 6.29. UC-18-29 · Chuyển sự cố có dữ liệu cá nhân sang PH-09

::: dac-ta
**Mục tiêu.** Sự cố vận hành có dấu hiệu lộ dữ liệu cá nhân được chuyển ngay cho phân hệ quyền riêng tư để PH-09 giữ đồng hồ 72 giờ thông báo theo Luật BVDLCN, còn PH-18 tiếp tục xử lý kỹ thuật và nhận lại tiến độ.

**Tác nhân chính.** SO (Dũng), `PERM-18-incident`.

**Tác nhân phụ.** PH-09 (API nhận sự cố `source = INCIDENT_PH18`, EVT-09-30, EVT-09-31); TA; UC-18-21 (thông báo `URGENT` cho SO).

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-18-050.

**Truy vết.** REQ-18; CMP-LAW-05; CMP-LAW-18; SEC-74; BP-07.

**Tiền điều kiện.** Sự cố `SC-2027-0042` có `hasPersonalData = true` hoặc bị nghi ngờ; PH-09 đã mở API nhận sự cố (đề nghị ở FRS mục 12.4).

**Kích hoạt.** Dũng bấm "Chuyển quyền riêng tư" ở UI-18-18; hoặc người dùng đặt `hasPersonalData = true`.

**Đảm bảo tối thiểu.** PH-09 không nhận thì hệ thống thử lại mỗi 5 phút và báo SO; đồng hồ 72 giờ tính từ `discoveredAt` do người chuyển nêu, không từ lúc PH-09 nhận.

**Đảm bảo thành công.** Sự cố có liên kết `PRIVACY_CASE` tới mã hồ sơ của PH-09, mốc "đã chuyển PH-09"; các cập nhật sau của PH-09 tự thành mốc thời gian.

**Luồng chính.**
1. Dũng điền thông tin tối thiểu: loại dữ liệu cá nhân "họ tên, ngày sinh trẻ em", số người ước tính 1.200, thời điểm phát hiện 12/03/2027 09:15 (API-18-130). Hệ thống kiểm đủ trường.
2. Hệ thống gọi API nhận sự cố của PH-09 với `source = INCIDENT_PH18`, `incidentRef = SC-2027-0042`, `discoveredAt`.
3. PH-09 trả mã hồ sơ; hệ thống ghi liên kết `PRIVACY_CASE`, thêm mốc "đã chuyển PH-09", phát EVT-18-18.
4. Hệ thống nhận EVT-09-30 (hồ sơ ghi nhận), EVT-09-31 (sắp đến hạn) và thêm mốc tương ứng.

**Luồng thay thế.**
- **4a. Không phải vi phạm.** PH-09 kết luận không phải vi phạm: hồ sơ PH-09 đóng, sự cố PH-18 tiếp tục theo vòng đời thường (UC-18-28).

**Luồng ngoại lệ.**
- **E1. Thiếu thông tin (bước 1).** ERR-18-053 (422): "Cần nêu loại dữ liệu cá nhân, số người ước tính và thời điểm phát hiện."
- **E2. PH-09 không nhận (bước 2).** ERR-18-054 (503): "Chưa chuyển được sang phân hệ quyền riêng tư. Hệ thống sẽ thử lại mỗi 5 phút; báo ngay cán bộ ATTT nếu quá 1 giờ." Hệ thống thử lại và gửi thông báo `URGENT` cho SO.

**Quy tắc áp dụng.** BR-18-036.

**Màn hình, API.** UI-18-18; API-18-130.
:::

```{.mermaid caption="Trình tự chuyển sự cố có dữ liệu cá nhân sang PH-09"}
sequenceDiagram
  actor SO as SO Dũng
  participant O as dh-platform ops
  participant P as PH-09 quyền riêng tư
  participant N as Bộ gửi thông báo
  SO->>O: Chuyển quyền riêng tư kèm thông tin tối thiểu (API-18-130)
  O->>O: Kiểm loại dữ liệu, số người, thời điểm phát hiện
  O->>P: Gửi sự cố source INCIDENT_PH18 kèm discoveredAt
  alt PH-09 nhận
    P-->>O: Mã hồ sơ, đồng hồ 72 giờ bắt đầu
    O->>O: Liên kết PRIVACY_CASE, phát EVT-18-18
  else PH-09 không phản hồi
    O->>N: Thông báo URGENT cho SO, thử lại mỗi 5 phút
  end
  P-->>O: EVT-09-30, EVT-09-31 thành mốc thời gian
```

Hình cho thấy đồng hồ 72 giờ thuộc PH-09 và bắt đầu từ thời điểm phát hiện; PH-18 chỉ bảo đảm sự cố được chuyển và theo dõi lại.

### 6.30. UC-18-30 · Theo dõi sao lưu, kiểm tra khôi phục và ghi nhận diễn tập DR

::: dac-ta
**Mục tiêu.** Người vận hành nền tảng thấy trên một bảng mọi đối tượng sao lưu có đúng hạn không, đã kiểm tra khôi phục được chưa, và có bằng chứng diễn tập DR đạt RTO, RPO, thay cho việc tin vào lịch sao lưu mà không ai kiểm.

**Tác nhân chính.** PO (Khoa) theo dõi; PA (Hà) ghi nhận diễn tập (`PERM-18-backup`, `PERM-18-admin`).

**Tác nhân phụ.** Tác vụ thu thập và CronJob kiểm tra khôi phục ở `dh-batch` (scope `ops:backup-report`); CNPG, Velero, rclone Garage, OpenBao; PH-13 (cảnh báo qua EVT-18-19, EVT-18-20); UC-18-28 (mở sự cố `SEV2`); TA xem đối tượng mức tenant; AU xem.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-052, FR-18-053, FR-18-058.

**Truy vết.** REQ-18; LGC-NFR-005; SEC-70; SEC-71; SEC-73; CMP-LAW-08; D05-01 §khôi phục; BP-07; BP-08.

**Tiền điều kiện.** Danh mục `backup_object` được nạp từ D03-09 §8.2 khi triển khai (PostgreSQL bản sao cơ sở, WAL, xuất logic theo tenant, Garage, OpenBao, Velero, kho Git, Harbor, ClickHouse, WORM kiểm toán).

**Kích hoạt.** Tác vụ thu thập mỗi 5 phút; CronJob kiểm tra khôi phục theo lịch (PostgreSQL hằng ngày, PITR hằng tuần, xuất tenant hằng tháng, Garage hằng tuần); Khoa mở `/van-hanh/sao-luu`; Hà bấm "+ Diễn tập".

**Đảm bảo tối thiểu.** Nguồn trạng thái không trả lời thì đối tượng hiện "Không rõ" kèm thời điểm thu gần nhất, không bị coi là sao lưu lỗi; EVT-18-19 chỉ phát một lần khi chuyển trạng thái.

**Đảm bảo thành công.** Mỗi đối tượng có lần thành công gần nhất, độ tươi, thời gian giữ, kết quả kiểm tra khôi phục gần nhất; đối tượng lỗi có sự cố `SEV2`; diễn tập có kết luận đạt hay không.

**Luồng chính.**
1. Tác vụ thu thập đọc trạng thái `Backup`, `ScheduledBackup` của CNPG, bản sao lưu Velero, nhật ký rclone, snapshot OpenBao qua API chỉ đọc; CronJob gọi API-18-135 báo bản sao lưu.
2. Hệ thống ghi `backup_run`, tính độ tươi so với tần suất (bản sao cơ sở PostgreSQL hằng ngày trễ khi quá `18.backup.stale-hours` 26 giờ).
3. Bản sao cơ sở của ô `pg-core` quá 26 giờ: hệ thống phát EVT-18-19 và mở sự cố `SEV2` (UC-18-28).
4. CronJob kiểm tra khôi phục vào cụm tạm, chạy kiểm số dòng và chuỗi băm kiểm toán, báo kết quả (API-18-137). Hệ thống kiểm `objectCode` đã khai báo, ghi `restore_verification`, cập nhật "kiểm tra gần nhất".
5. Khoa mở bảng (API-18-133, 134, 136): thấy từng đối tượng với màu theo trạng thái và tỷ lệ đối tượng có kiểm tra khôi phục đạt trong kỳ.
6. Hà nhập kết quả diễn tập DR quý I kèm biên bản (API-18-155). Hệ thống kiểm thời gian và biên bản, so RTO, RPO đo được với chỉ tiêu của tầng phục hồi, ghi `dr_drill` với kết luận; có vấn đề thì tạo việc khắc phục cho người được nêu.

**Luồng thay thế.**
- **1a. Nguồn không trả lời.** Đối tượng hiện "Không rõ"; cảnh báo sau 3 lần thu liên tiếp lỗi.
- **4a. Kiểm tra lỗi hoặc quá tần suất.** Kết quả `FAILED` hoặc quá tần suất mà không có kết quả: phát EVT-18-20 với `result = FAILED`, mở sự cố `SEV2`.
- **4b. Đạt nhưng chậm.** Thời gian khôi phục vượt RTO của tầng (`TPH-1` 4 giờ): ghi `PASSED_SLOW` và cảnh báo.
- **5a. TA xem.** Mai chỉ thấy đối tượng mức tenant của T68.
- **6a. Xem diễn tập.** PA, PO, AU xem danh sách diễn tập (API-18-154).

**Luồng ngoại lệ.**
- **E1. CronJob dùng danh tính sai (bước 1).** ERR-00-403 (403).
- **E2. Không thu được trạng thái từ mọi nguồn (bước 5).** ERR-18-055 (503): "Chưa thu được trạng thái sao lưu từ {công cụ}."
- **E3. Thu trạng thái một đối tượng lỗi (nhánh 1a).** ERR-18-122 (worker): "Chưa thu được trạng thái của {đối tượng}."
- **E4. Đối tượng chưa khai báo (bước 4).** ERR-18-001 (404): "Không tìm thấy {đối tượng} {mã}.".
- **E5. Thiếu biên bản diễn tập (bước 6).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-18-047; BR-18-048.

**Màn hình, API.** UI-18-19; API-18-133, 134, 135, 136, 137, 154, 155.
:::

### 6.31. UC-18-31 · Yêu cầu, duyệt và chạy khôi phục tenant tám bước

::: dac-ta
**Mục tiêu.** Khi dữ liệu của một tỉnh bị hỏng (ví dụ lỗi nhập lô xóa nhầm), tỉnh đó được đưa về một thời điểm trong 30 ngày qua mà không ảnh hưởng tỉnh khác, trong tối đa 4 giờ với tenant đến 200 GB, có hai người chịu trách nhiệm và quay lui được nếu giữa chừng lỗi.

**Tác nhân chính.** TA (Mai) tạo yêu cầu (`PERM-18-backup`); PA (Hà) duyệt và quay lui (`PERM-18-approve`).

**Tác nhân phụ.** Job `dh-tenant-restore` trong `dh-batch` (vai `ph18_worker`, danh tính `svc-ops-worker`); PH-20 (chuyển tenant `SUSPENDED`, `ACTIVE`); CNPG (PITR vào cụm tạm); mọi DU nhận EVT-18-22; PH-13 (kiểm toán).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-054, FR-18-055.

**Truy vết.** REQ-18; SEC-71; SEC-85; FR-00-071; D03-09 §8.5 (RBK-04); BP-07.

**Tiền điều kiện.** T68 `ACTIVE`; không có tác vụ nặng khác của T68 đang chạy; `18.restore.approval-required = true`.

**Kích hoạt.** Mai bấm "Yêu cầu khôi phục" ở UI-18-20; Hà bấm "Duyệt" trên việc `ph18.approve-restore`.

**Đảm bảo tối thiểu.** Lỗi ở bước 2 đến 4 thì dữ liệu chưa đổi và tenant về `ACTIVE`; lỗi từ bước 5 phải quay lui từ bản trích hiện tại (BR-18-038); nhật ký kiểm toán không bao giờ bị khôi phục.

**Đảm bảo thành công.** Dữ liệu T68 trong phạm vi bằng thời điểm đích, số dòng khớp bản trích, tenant `ACTIVE`, yêu cầu `SUCCEEDED`; EVT-18-22 phát để mọi DU xóa bộ đệm và đồng bộ lại.

**Luồng chính.**
1. Mai chọn thời điểm đích 14/03/2027 08:00 và phạm vi `PH-06`, `PH-07` kèm Garage (API-18-138). Hệ thống kiểm thời điểm trong cửa sổ PITR 30 ngày và không ở tương lai, phạm vi là schema có `tenant_id`, không có tác vụ nặng khác.
2. Hệ thống ước tính thời gian theo kích thước dữ liệu của T68 và hiện cảnh báo: tenant sẽ `SUSPENDED` trong bước 4 đến 8, dữ liệu sau thời điểm đích trong phạm vi sẽ mất, nhật ký kiểm toán không bị khôi phục.
3. Mai xác nhận đã đọc cảnh báo và gửi (API-18-141): yêu cầu `PENDING_APPROVAL`, việc `ph18.approve-restore` cho PA, phát EVT-18-21.
4. Hà xem yêu cầu (API-18-140), bấm "Duyệt" (API-18-142). Hệ thống kiểm Hà khác Mai, kiểm lại điều kiện, ghi kiểm toán, tạo Job `dh-tenant-restore`; yêu cầu `RUNNING`.
5. Job chạy bước 1 đến 4 của RBK-04: (1) ghi phê duyệt; (2) PITR ô CSDL vào cụm tạm cô lập; (3) trích dòng `tenant_id` của T68 theo thứ tự khóa ngoại bằng `COPY`, kèm bản trích dữ liệu hiện tại để quay lui; (4) gọi PH-20 chuyển T68 sang `SUSPENDED`, dừng luồng, tạm dừng consumer outbox của T68.
6. Job chạy bước 5 đến 8: (5) thay dữ liệu từng phân hệ trong một giao dịch với `SET LOCAL app.tenant_id`, tắt trigger outbox, phát một EVT-18-22; (6) khôi phục Garage theo phạm vi, đặt lại offset consumer nếu cần; (7) ghi bản kiểm toán khôi phục; (8) chạy kiểm tra khói, đối chiếu số dòng với bản trích, gọi PH-20 chuyển T68 về `ACTIVE`, xóa cụm tạm.
7. Mỗi bước báo về `tenant_restore_step`, Mai và Hà theo dõi ở UI-18-20 (API-18-145). Hệ thống đặt yêu cầu `SUCCEEDED`, gửi thông báo cho Mai và Hà, phát EVT-18-21.

**Luồng thay thế.**
- **3a. Lưu nháp, hủy.** Mai lưu `DRAFT` để chỉnh sau, hoặc hủy yêu cầu chưa duyệt (API-18-144): `CANCELLED`.
- **4a. Từ chối.** Hà từ chối kèm lý do (API-18-143): `REJECTED`.
- **5a. Lỗi ở bước 2 đến 4.** Job dừng, dữ liệu chưa đổi, T68 về `ACTIVE`, yêu cầu `FAILED`.
- **6a. Lỗi ở bước 5 đến 8.** Job tự quay lui từ bản trích hiện tại; tự động thất bại thì Hà bấm "Quay lui" (API-18-146); yêu cầu `ROLLED_BACK`. Quay lui không cần bốn mắt.
- **6b. Phạm vi gồm realm, OpenBao.** Bước 6 khôi phục thêm realm Keycloak, OpenBao theo phạm vi đã duyệt.
- **1a. Xem yêu cầu.** Mai xem danh sách yêu cầu của T68 (API-18-139).

**Luồng ngoại lệ.**
- **E1. Thời điểm ngoài cửa sổ PITR (bước 1).** ERR-18-056 (422): "Thời điểm {thời điểm} nằm ngoài cửa sổ khôi phục 30 ngày."
- **E2. Phạm vi không hợp lệ (bước 1).** ERR-18-058 (422): "Phạm vi khôi phục không hợp lệ: {chi tiết}."
- **E3. Tenant đang có tác vụ nặng khác (bước 1, 4).** ERR-18-057 (409): "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục."
- **E4. Người duyệt trùng người tạo (bước 4).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."
- **E5. PH-13 không ghi được kiểm toán (bước 4).** ERR-18-008 (503): "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
- **E6. Bước của Job lỗi (bước 5, 6).** ERR-18-114 (worker): "Bước {n} của khôi phục lỗi: {mô tả}. Hệ thống đang quay lui."
- **E7. Đối chiếu số dòng lệch (bước 6).** ERR-18-115 (worker): "Số dòng sau khôi phục lệch ở {bảng}." Tenant giữ `SUSPENDED` chờ PA quyết định.

**Quy tắc áp dụng.** BR-18-038; BR-18-039; BR-18-047; LP-18-01; LP-18-02; LP-18-05.

**Màn hình, API.** UI-18-20, UI-18-15; API-18-138, 139, 140, 141, 142, 143, 144, 145, 146.
:::

```{.mermaid caption="Trình tự khôi phục tenant tám bước có duyệt bốn mắt"}
sequenceDiagram
  actor TA as TA Mai
  actor PA as PA Hà
  participant O as dh-platform ops
  participant J as Job dh-tenant-restore
  participant C as CNPG cụm tạm
  participant T as PH-20 tenant
  participant D as Mọi DU
  TA->>O: Tạo và gửi yêu cầu (API-18-138, 141)
  O-->>PA: Việc ph18.approve-restore
  PA->>O: Duyệt (API-18-142)
  O->>O: Kiểm người duyệt khác người tạo, ghi kiểm toán
  O->>J: Tạo Job, yêu cầu RUNNING
  J->>C: Bước 2 PITR về 14/03 08:00
  J->>J: Bước 3 trích dòng T68 và bản trích hiện tại
  J->>T: Bước 4 chuyển T68 SUSPENDED
  J->>J: Bước 5 đến 7 thay dữ liệu, khôi phục Garage, ghi kiểm toán
  J-->>D: EVT-18-22 xóa bộ đệm, đồng bộ lại
  J->>T: Bước 8 đối chiếu số dòng, chuyển T68 ACTIVE
  J-->>O: Từng bước về tenant_restore_step
  O-->>TA: Yêu cầu SUCCEEDED
```

Hình cho thấy tenant chỉ bị tạm ngừng từ bước 4 và dữ liệu chỉ bị thay từ bước 5; trước đó mọi lỗi đều không đổi dữ liệu, sau đó mọi lỗi đều quay lui từ bản trích.

### 6.32. UC-18-32 · Xuất dữ liệu tenant

::: dac-ta
**Mục tiêu.** Khi một tỉnh ngừng dùng nền tảng, chuyển sang ô hạ tầng khác hoặc sang CSDL riêng, toàn bộ dữ liệu của tỉnh được xuất thành gói mã hóa có kê khai số dòng và tổng kiểm tra để bàn giao hoặc nạp lại.

**Tác nhân chính.** PA (Hà), `PERM-18-backup`.

**Tác nhân phụ.** PH-20 (kích hoạt qua `platform.tenant.export-ready.v1`, nhận EVT-18-23); Job `dh-tenant-export`; Garage (bucket xuất); PH-13.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-056.

**Truy vết.** REQ-18; SEC-70; D03-10 (vòng đời tenant); BP-08.

**Tiền điều kiện.** Mục đích `HANDOVER` cần tenant `DECOMMISSIONED` hoặc `SUSPENDED`; `CELL_MOVE` cần cửa sổ bảo trì; không có tác vụ nặng khác.

**Kích hoạt.** Hà bấm "Xuất dữ liệu" ở UI-18-20; PH-18 nhận `platform.tenant.export-ready.v1`.

**Đảm bảo tối thiểu.** Job lỗi thì không gói nào được tạo; gói tự xóa sau `18.export.retention-days` (30 ngày).

**Đảm bảo thành công.** Gói mã hóa có tệp kê khai (SHA-256 từng tệp, số dòng từng bảng) nằm ở bucket xuất; EVT-18-23 phát; mỗi lần cấp liên kết tải ghi kiểm toán.

**Luồng chính.**
1. Hà tạo lệnh xuất T90 (tenant thử nghiệm đã `SUSPENDED`) mục đích `HANDOVER` (API-18-147). Hệ thống kiểm trạng thái tenant phù hợp mục đích và không có tác vụ nặng khác.
2. Hệ thống tạo Job `dh-tenant-export`: xuất dòng `tenant_id` của mọi schema theo thứ tự khóa ngoại, sao tệp `dh-t90-*`, tạo tệp kê khai.
3. Job mã hóa gói bằng khóa công khai của bên nhận, ghi vào bucket xuất và báo kết quả.
4. Hệ thống phát EVT-18-23; Hà xem kết quả (API-18-148) và bấm "Cấp liên kết tải" (API-18-149), nhận liên kết có hạn `18.export.link-ttl-hours` (24 giờ).

**Luồng thay thế.**
- **3a. Chuyển ô, CSDL riêng.** Mục đích `CELL_MOVE`, `DEDICATED_DB`: mã hóa bằng khóa nền tảng, không cấp liên kết tải; PH-20 dùng gói để nạp vào ô đích.
- **1a. Kích hoạt từ PH-20.** PH-18 nhận `platform.tenant.export-ready.v1` và đối chiếu với gói xuất khi ngừng tenant.

**Luồng ngoại lệ.**
- **E1. Trạng thái tenant không phù hợp (bước 1).** ERR-18-059 (409): "Tỉnh đang ở trạng thái {trạng thái}, chưa xuất được với mục đích {mục đích}."
- **E2. Đang có tác vụ nặng khác (bước 1).** ERR-18-057 (409): "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục."
- **E3. Job xuất lỗi (bước 2, 3).** ERR-18-116 (worker): "Xuất dữ liệu chưa thành công: {lý do}."

**Quy tắc áp dụng.** BR-18-039; BR-18-048; LP-18-05.

**Màn hình, API.** UI-18-20; API-18-147, 148, 149.
:::

### 6.33. UC-18-33 · Chuyển dữ liệu phân hệ khi sáp nhập tenant theo yêu cầu PH-20

::: dac-ta
**Mục tiêu.** Khi hai tỉnh sáp nhập, dữ liệu từng phân hệ của tỉnh nguồn được chuyển sang tỉnh đích giữ nguyên định danh gốc và đánh dấu nguồn gốc, chạy thử được trước, dừng và gỡ được nếu PH-20 hủy.

**Tác nhân chính.** PH-20 (scope `ops:merge-transfer`), bên điều phối.

**Tác nhân phụ.** Job `dh-tenant-export` chế độ trích và nạp; PA (Hà) xem (`PERM-18-backup`); PH-12 (chuyển định danh người dùng bằng API-12-045, API-12-046, ngoài công cụ này).

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-18-057.

**Truy vết.** REQ-18; SEC-85; D03-10 (sáp nhập tenant); Q01-54; BP-08.

**Tiền điều kiện.** PH-20 có kế hoạch sáp nhập `mergePlanId` gộp T91 vào T92; T91 đã `SUSPENDED`, T92 `ACTIVE`; không có tác vụ nặng khác trên hai tenant; PH-18 đã nhận `platform.tenant.merge-started.v1`.

**Kích hoạt.** PH-20 gọi `POST /merge-transfers` cho từng phân hệ tham gia.

**Đảm bảo tối thiểu.** Chuyển lũy đẳng theo `mergePlanId:module` (BR-18-045); xung đột khóa thì dừng phân hệ đó và báo danh sách khóa xung đột; hủy thì dữ liệu đã nạp của phân hệ đó bị xóa theo `origin_tenant_id` và `mergePlanId`.

**Đảm bảo thành công.** Dữ liệu `PH-07` của T91 nằm ở T92 với `id` gốc và `origin_tenant_id = T91`; `merge_transfer` `SUCCEEDED`; PH-20 nhận tiến độ và EVT-18-24.

**Luồng chính.**
1. PH-20 gửi yêu cầu `mergePlanId`, `module = PH-07`, `sourceTenant = T91`, `targetTenant = T92`, `mappingRef`, `dryRun = true` (API-18-150). Hệ thống kiểm lũy đẳng, `mappingRef` đọc được và `module` là schema có `tenant_id`.
2. Hệ thống tạo `merge_transfer` `QUEUED` và Job: trích dòng T91, áp ánh xạ mã (mã đơn vị, mã danh mục trùng), đặt `tenant_id` đích và `origin_tenant_id` nguồn, giữ `id` gốc.
3. Chế độ chạy thử: Job chỉ đếm, kiểm xung đột khóa, trả báo cáo; không ghi.
4. PH-20 gửi lại với `dryRun = false`. Job nạp vào T92 trong giao dịch theo phân hệ với `SET LOCAL app.tenant_id` đích, tắt trigger outbox.
5. Job báo tiến độ về PH-20 qua `POST /internal/tenant/v1/merge-plans/{id}/participants/{module}:report`, cập nhật `merge_transfer`, phát EVT-18-24.

**Luồng thay thế.**
- **5a. PH-20 hủy.** PH-20 gọi hủy (API-18-153): Job dừng sau giao dịch hiện tại, xóa dữ liệu đã nạp của phân hệ đó theo `origin_tenant_id` và `mergePlanId`.
- **1a. Gọi lại cùng nội dung.** Trả `merge_transfer` hiện có, không tạo Job mới.
- **5b. PA xem.** Hà xem danh sách và chi tiết chuyển (API-18-151, 152) ở UI-18-20.

**Luồng ngoại lệ.**
- **E1. Yêu cầu không hợp lệ (bước 1).** ERR-18-060 (422): "Yêu cầu chuyển sáp nhập không hợp lệ: {lý do}."
- **E2. Trùng `mergePlanId` và `module` với nội dung khác (bước 1).** ERR-18-061 (409): "Đã có yêu cầu chuyển dữ liệu {phân hệ} cho kế hoạch {mã} với nội dung khác."
- **E3. Xung đột khóa khi nạp (bước 4).** Job dừng phân hệ đó, báo `FAILED` kèm danh sách khóa xung đột về PH-20.
- **E4. Báo tiến độ về PH-20 lỗi (bước 5).** ERR-18-123 (worker): "Chưa báo được tiến độ sáp nhập; đang thử lại."

**Quy tắc áp dụng.** BR-18-039; BR-18-045; BR-18-047; LP-18-05.

**Màn hình, API.** UI-18-20; API-18-150, 151, 152, 153.
:::

```{.mermaid caption="Trình tự chuyển dữ liệu một phân hệ khi sáp nhập tenant"}
sequenceDiagram
  participant T as PH-20 điều phối
  participant O as dh-platform ops
  participant J as Job dh-tenant-export
  participant DB as Schema PH-07
  T->>O: merge-transfers module PH-07 dryRun true (API-18-150)
  O->>O: Kiểm lũy đẳng, mappingRef, module
  O->>J: Tạo Job chạy thử
  J->>DB: Đếm, kiểm xung đột khóa, không ghi
  J->>T: Báo cáo chạy thử qua participants report
  T->>O: merge-transfers dryRun false
  O->>J: Tạo Job nạp
  J->>DB: Nạp vào T92, giữ id gốc, ghi origin_tenant_id
  J->>T: Báo tiến độ, EVT-18-24
```

Hình cho thấy PH-20 giữ quyết định ở mọi bước; PH-18 chỉ thực hiện chuyển cho từng phân hệ và báo lại.

### 6.34. UC-18-34 · Khai báo nguồn hệ cũ và lập kế hoạch di trú

::: dac-ta
**Mục tiêu.** Đội chuyển đổi khai báo CSDL hệ cũ chỉ đọc làm nguồn, không bao giờ nhập mật khẩu vào Datahub, và lập kế hoạch di trú theo loại đối tượng đúng thứ tự phụ thuộc (danh mục trước, HTTT sau, giao dịch cuối).

**Tác nhân chính.** TA (Mai), PA (Hà) (`PERM-18-migration`).

**Tác nhân phụ.** OpenBao (bí mật `kv/dh/t68/migration/{sourceCode}`, IF-07); worker `dh-ops-worker` (thử kết nối); phân hệ đích (PH-07, PH-01, PH-02, PH-03, PH-10, PH-04, PH-19) qua phiên bản API nhập.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-059, FR-18-060.

**Truy vết.** REQ-22; FR-00-090; FR-00-091; IF-07; SEC-33; LGC-HUB-008; LGC-HUB-010; LGC-DMDC-001; BP-09.

**Tiền điều kiện.** Bí mật kết nối đã được người có quyền ở OpenBao ghi vào `kv/dh/t68/migration/lgsp-cu`.

**Kích hoạt.** Mai bấm "+ Nguồn hệ cũ" rồi "+ Kế hoạch" ở UI-18-21.

**Đảm bảo tối thiểu.** Tài khoản có quyền ghi bị từ chối (BR-18-040); mọi thay đổi kế hoạch sau khi sẵn sàng đưa kế hoạch về `DRAFT`.

**Đảm bảo thành công.** `legacy_source` `lgsp-cu` ở `READY` với số bảng, số dòng ước tính; `migration_plan` `KH-HOTICH-01` ở `READY` với đồ thị phụ thuộc không vòng.

**Luồng chính.**
1. Mai nhập nguồn `lgsp-cu`, `jdbcUrl` không có tham số người dùng hay mật khẩu, `credentialRef = kv/dh/t68/migration/lgsp-cu` (API-18-157). Hệ thống kiểm `jdbcUrl` và dạng tham chiếu, lưu `legacy_source` `DRAFT`.
2. Mai bấm "Thử kết nối" (API-18-158). Worker đọc bí mật từ OpenBao, kết nối, thử `CREATE TEMP TABLE` (phải bị từ chối), đếm bảng và dòng theo schema; đạt thì nguồn `READY`.
3. Mai tạo kế hoạch `KH-HOTICH-01` (API-18-160) và thêm loại đối tượng: danh mục Aita sang PH-07, HTTT sang PH-01, API và gói sang PH-02, PH-03, luồng Camel XML sang PH-04 dạng nháp (API-18-162). Hệ thống gợi ý bộ chuyển và phân hệ đích theo bảng thứ tự, kiểm bộ chuyển tồn tại cho loại hệ cũ và phiên bản API nhập của đích.
4. Mai bấm "Sẵn sàng" (API-18-163). Hệ thống kiểm đồ thị phụ thuộc không vòng và đối tượng tiền đề đã có trong kế hoạch hoặc đã di trú xong; kế hoạch `READY`.

**Luồng thay thế.**
- **1a. Nguồn là bản sao lưu đã phục hồi.** `jdbcUrl` trỏ cụm tạm, cùng kiểm chỉ đọc.
- **3a. Kế hoạch theo đợt.** Một nguồn có nhiều kế hoạch theo nhóm dịch vụ (ví dụ "nhóm hộ tịch").
- **1b. Xem.** Mai xem nguồn, kế hoạch (API-18-156, 159, 161).

**Luồng ngoại lệ.**
- **E1. Thông tin kết nối có mật khẩu (bước 1).** ERR-18-070 (422): "Thông tin kết nối phải là tham chiếu kho bí mật, không nhập mật khẩu trực tiếp."
- **E2. Không kết nối được hoặc tài khoản có quyền ghi (bước 2).** ERR-18-062 (422): "Nguồn {mã} không kết nối được hoặc tài khoản không phải chỉ đọc: {chi tiết}."
- **E3. Bộ chuyển hoặc phiên bản API nhập không có (bước 3).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."
- **E4. Phụ thuộc vòng hoặc thiếu tiền đề (bước 4).** ERR-18-063 (422): "Kế hoạch có phụ thuộc vòng hoặc thiếu đối tượng tiền đề: {danh sách}."

**Quy tắc áp dụng.** BR-18-040; BR-18-048.

**Màn hình, API.** UI-18-21; API-18-156, 157, 158, 159, 160, 161, 162, 163.
:::

### 6.35. UC-18-35 · Chạy thử di trú, đối chiếu và xử lý bản ghi lỗi

::: dac-ta
**Mục tiêu.** Trước khi ghi thật, đội chuyển đổi biết chính xác bao nhiêu bản ghi chuyển được, bản ghi nào lỗi và vì sao, tổng kiểm tra có khớp không, rồi sửa và chạy lại riêng phần lỗi.

**Tác nhân chính.** TA (Mai) chạy (`PERM-18-migration`); DS (Lan) xem và cập nhật cách xử lý bản ghi lỗi.

**Tác nhân phụ.** Job `dh-migrate`; phân hệ đích ở chế độ kiểm (`validateOnly = true`); AU (Phúc) xem báo cáo đối chiếu; Garage (báo cáo PDF, CSV).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-061, FR-18-063, FR-18-064.

**Truy vết.** REQ-22; FR-00-090; FR-00-091; FR-00-092; BP-09.

**Tiền điều kiện.** Kế hoạch `KH-HOTICH-01` ở `READY`.

**Kích hoạt.** Mai bấm "Chạy thử" ở UI-18-21; Lan mở tab "Bản ghi lỗi" ở UI-18-22.

**Đảm bảo tối thiểu.** Chạy thử không ghi gì vào phân hệ đích; bộ chuyển lỗi một bản ghi không dừng cả lần chạy.

**Đảm bảo thành công.** `migration_run` `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS`, EVT-18-25 phát; `migration_reconciliation` có số lượng và tổng kiểm tra từng loại; bản ghi lỗi có cách xử lý.

**Luồng chính.**
1. Mai bấm "Chạy thử" (API-18-164, `mode = DRY_RUN`). Hệ thống kiểm kế hoạch `READY`, tạo `migration_run` `QUEUED` và Job `dh-migrate`.
2. Job đọc nguồn theo lô `18.migration.batch-size` (500), chuyển đổi bằng bộ chuyển, áp quy tắc sửa lỗi, gọi API nhập của phân hệ đích ở chế độ kiểm.
3. Job ghi kết quả từng loại (đọc, chuyển, hợp lệ, lỗi) và bản ghi lỗi; tính số lượng và tổng kiểm tra SHA-256 trên danh sách khóa và các trường nghiệp vụ chính đã chuẩn hóa ở nguồn.
4. Job kết thúc `SUCCEEDED_WITH_ERRORS` (danh mục 18.420 bản ghi đọc, 18.391 hợp lệ, 29 lỗi), phát EVT-18-25; Mai theo dõi ở UI-18-22 (API-18-165, 166).
5. Mai mở tab "Đối chiếu" (API-18-171): hệ thống hiện `migration_reconciliation` và đánh dấu chênh lệch chưa giải trình; Mai tải báo cáo PDF, CSV (liên kết có hạn).
6. Lan mở tab "Bản ghi lỗi" (API-18-170): khóa nguồn, loại, lý do (mã ERR của đích hoặc của bộ chuyển), bước lỗi; xuất CSV.
7. Lan đánh dấu cách xử lý (API-18-182): 25 bản ghi sửa ở nguồn, 4 bản ghi không di trú kèm lý do (`WONT_MIGRATE`).
8. Sau khi nguồn sửa xong, Mai bấm "Chạy lại bản ghi lỗi" (API-18-164 với `retryOf`): hệ thống tạo lần chạy mới chỉ gồm 25 bản ghi, cùng chế độ chạy thử; bản ghi chuyển được thì đóng, còn lỗi thì cập nhật lý do mới.

**Luồng thay thế.**
- **2a. Đích chưa có chế độ kiểm.** Job chỉ kiểm lược đồ chuyển đổi và ghi cờ `targetValidated = false`.
- **5a. Đích chưa có API đọc lại.** Tổng kiểm tra phía đích ghi `NOT_AVAILABLE`, báo cáo nêu rõ.
- **7a. Bản ghi `WONT_MIGRATE`.** Đưa vào báo cáo đối chiếu như chênh lệch đã giải trình.
- **4a. Hủy giữa chừng.** Mai hủy lần chạy (API-18-169).

**Luồng ngoại lệ.**
- **E1. Kế hoạch chưa sẵn sàng (bước 1).** ERR-18-065 (409): "Kế hoạch {mã} chưa ở trạng thái sẵn sàng."
- **E2. Đọc nguồn lỗi (bước 2).** ERR-18-117 (worker): "Không đọc được nguồn hệ cũ ở bảng {bảng}: {chi tiết}." Hiện ở UI-18-22.
- **E3. Bộ chuyển lỗi một bản ghi (bước 2).** ERR-18-118 (worker): "Bản ghi {khóa} không chuyển đổi được: {lý do}." Bản ghi vào danh sách lỗi, lần chạy tiếp tục.
- **E4. Tổng kiểm tra lệch (bước 5).** ERR-18-120 (worker): "Tổng kiểm tra của {đối tượng} lệch."
- **E5. Không có bản ghi lỗi để chạy lại (bước 8).** ERR-18-036 (422): "Không có mục nào phù hợp để {thao tác}.".

**Quy tắc áp dụng.** BR-18-040; BR-18-041; BR-18-043.

**Màn hình, API.** UI-18-21, UI-18-22; API-18-164, 165, 166, 169, 170, 171, 182.
:::

### 6.36. UC-18-36 · Chạy thật di trú có duyệt bốn mắt và đánh dấu cấp lại xác thực

::: dac-ta
**Mục tiêu.** Dữ liệu hệ cũ được ghi vào Datahub chỉ sau khi chạy thử gần đây đạt và có người thứ hai duyệt, qua API nhập của từng phân hệ đích, chạy lại không tạo bản trùng, và mọi thông tin xác thực được đánh dấu để cấp lại chứ không bao giờ chép sang.

**Tác nhân chính.** TA (Mai) tạo lần chạy (`PERM-18-migration`); PA (Hà) duyệt (`PERM-18-approve`).

**Tác nhân phụ.** Job `dh-migrate`; phân hệ đích (scope `ops:migration-import`, cờ `migration = true`); PH-01, PH-03 (nhận EVT-18-26, tạo việc cấp lại; EVT-01-05 báo đã cấp); UC-18-27 (đóng băng).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-062, FR-18-064, FR-18-065.

**Truy vết.** REQ-22; FR-00-090; FR-00-091; FR-00-092; FR-00-093; FR-00-071; SEC-33; LGC-HUB-008; LGC-HUB-010; BP-09.

**Tiền điều kiện.** Kế hoạch `READY`; có lần chạy thử `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS` trong `18.migration.dry-run-valid-days` (7 ngày) với cùng phiên bản kế hoạch; môi trường đích không đóng băng; T68 không có tác vụ nặng khác.

**Kích hoạt.** Mai bấm "Chạy thật" ở UI-18-21; Hà mở việc `ph18.approve-migration`.

**Đảm bảo tối thiểu.** Phân hệ đích không phát sự kiện nghiệp vụ hàng loạt (BR-18-043); hủy giữa chừng thì bản ghi đã ghi giữ nguyên và chạy tiếp được nhờ khóa lũy đẳng `legacySystem:objectType:legacyKey`; không trường xác thực nào rời hệ cũ (BR-18-042).

**Đảm bảo thành công.** `migration_run` `REAL` kết thúc `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS`; báo cáo đối chiếu có tổng kiểm tra cả nguồn và dữ liệu đọc lại từ đích; `credential_reissue_marker` `PENDING` cho từng HTTT và loại xác thực; EVT-18-25, EVT-18-26 phát.

**Luồng chính.**
1. Mai tạo lần chạy thật (API-18-164, `mode = REAL`). Hệ thống kiểm kế hoạch `READY`, lần chạy thử hợp lệ, không đóng băng, không tác vụ nặng khác; lần chạy `PENDING_APPROVAL`, việc `ph18.approve-migration` cho người có `PERM-18-approve` trừ Mai.
2. Hà xem báo cáo chạy thử và đối chiếu (API-18-166, 171), bấm "Duyệt" (API-18-167). Hệ thống kiểm Hà khác Mai; lần chạy `QUEUED`, Job bắt đầu.
3. Job đọc nguồn, chuyển đổi, bỏ trường xác thực khỏi bản ghi application, subscription có khóa, client chứng thư trước khi gửi và đếm số trường đã bỏ.
4. Job gọi API nhập của phân hệ đích (ví dụ API-01-080 của PH-01, API-07-002 của PH-07) với khóa lũy đẳng và cờ `migration = true`; bản ghi đã có cùng khóa được bỏ qua hoặc cập nhật theo chính sách của bộ chuyển.
5. Job ghi `credential_reissue_marker` `PENDING` cho 182 HTTT, phát EVT-18-26 để PH-01, PH-03 tạo việc cấp lại cho đầu mối HTTT.
6. Job tính đối chiếu số lượng và tổng kiểm tra trên dữ liệu đọc lại từ đích qua API đọc, ghi bản ghi lỗi, kết thúc và phát EVT-18-25.
7. Khi PH-01 phát EVT-01-05 (đã cấp thông tin xác thực) cho từng HTTT, hệ thống chuyển dấu tương ứng sang `REISSUED`; Mai theo dõi ở UI-18-22, UI-18-23 (API-18-172).

**Luồng thay thế.**
- **2a. Từ chối.** Hà từ chối kèm lý do (API-18-168): lần chạy kết thúc, không ghi gì.
- **4a. Hủy giữa chừng.** Mai hủy (API-18-169): Job dừng sau lô hiện hành, bản ghi đã ghi giữ nguyên.
- **4b. Chạy lại bản ghi lỗi.** Như UC-18-35 bước 8 nhưng chế độ thật, vẫn cần duyệt.
- **7a. HTTT không còn dùng.** Mai đánh dấu `WAIVED` kèm lý do từ 10 ký tự (API-18-183); dấu đã `REISSUED` thì trả ERR-18-006.
- **1a. Xem lần chạy.** Mai xem danh sách lần chạy (API-18-165).

**Luồng ngoại lệ.**
- **E1. Chưa có chạy thử hợp lệ (bước 1).** ERR-18-064 (409): "Cần một lần chạy thử thành công trong {ngày} ngày gần nhất trước khi chạy thật."
- **E2. Đang đóng băng (bước 1).** ERR-18-051 (409): "Đang trong thời gian đóng băng thay đổi {cửa sổ} nên chưa chạy thật được."
- **E3. Tenant đang có tác vụ nặng khác (bước 1).** ERR-18-057 (409): "Tỉnh đang có {tác vụ} chạy. Chờ xong trước khi yêu cầu khôi phục."
- **E4. Người duyệt trùng người tạo (bước 2).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."
- **E5. Phân hệ đích không nhận lô (bước 4).** ERR-18-069 (503): "Phân hệ {ph} không nhận dữ liệu. Lần chạy tạm dừng và tự thử lại sau {phút} phút."
- **E6. Phân hệ đích từ chối bản ghi (bước 4).** ERR-18-119 (worker): "Phân hệ đích từ chối bản ghi {khóa}: {mã lỗi}." Bản ghi vào danh sách lỗi.
- **E7. Không phát được sự kiện cấp lại (bước 5).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ."
- **E8. Tổng kiểm tra lệch (bước 6).** ERR-18-120 (worker): "Tổng kiểm tra của {đối tượng} lệch."
- **E9. Kế hoạch chưa sẵn sàng (bước 1).** ERR-18-065 (409): "Kế hoạch {mã} chưa ở trạng thái sẵn sàng."

**Quy tắc áp dụng.** BR-18-040; BR-18-041; BR-18-042; BR-18-043; LP-18-01; LP-18-05.

**Màn hình, API.** UI-18-21, UI-18-22, UI-18-15; API-18-164, 165, 166, 167, 168, 169, 171, 172.
:::

```{.mermaid caption="Trình tự chạy thật di trú có duyệt bốn mắt"}
sequenceDiagram
  actor TA as TA Mai
  actor PA as PA Hà
  participant O as dh-platform ops
  participant J as Job dh-migrate
  participant L as CSDL hệ cũ chỉ đọc
  participant D as Phân hệ đích PH-01, PH-07
  participant P as PH-01, PH-03
  TA->>O: Tạo lần chạy REAL (API-18-164)
  O->>O: Kiểm chạy thử 7 ngày, đóng băng, tác vụ nặng
  O-->>PA: Việc ph18.approve-migration
  PA->>O: Duyệt (API-18-167)
  O->>J: Lần chạy QUEUED, tạo Job
  J->>L: Đọc theo lô 500
  J->>J: Chuyển đổi, bỏ trường xác thực
  J->>D: API nhập với khóa lũy đẳng, cờ migration
  D-->>J: Kết quả từng bản ghi
  J-->>P: EVT-18-26 danh sách cần cấp lại xác thực
  J->>D: Đọc lại để tính tổng kiểm tra
  J-->>O: Báo cáo đối chiếu, EVT-18-25
```

Hình cho thấy Job chỉ đọc hệ cũ và chỉ ghi qua API nhập của phân hệ đích; thông tin xác thực bị bỏ ngay trong Job và chuyển thành việc cấp lại.

### 6.37. UC-18-37 · Theo dõi chạy song song và đối soát bóng

::: dac-ta
**Mục tiêu.** Trong giai đoạn hai hệ cùng chạy, đội chuyển đổi thấy từng nhóm dịch vụ đã sẵn sàng cắt chuyển chưa bằng số đo khách quan: tỷ lệ phản hồi của Datahub khớp với hệ cũ trên lưu lượng thật, cầu nối sự kiện và tiến độ cấp lại xác thực.

**Tác nhân chính.** TA (Mai), `PERM-18-migration`; TO, PA xem.

**Tác nhân phụ.** APISIX (`proxy-mirror` do PH-03 bật); bộ so sánh bóng (scope `ops:shadow-ingest`); PH-10 (EVT-10-15, EVT-10-16 của cầu nối Pulsar, ADR-073); đội chuyển đổi nhận thông báo.

**Mức ưu tiên.** S · MVP.

**FR hiện thực.** FR-18-066, FR-18-067.

**Truy vết.** REQ-22; ADR-073; FR-10-072…076; D01-01 (đối soát chạy song song); Q18-14; BP-09.

**Tiền điều kiện.** Nhóm `nhom-hotich` đã khai báo từ kế hoạch di trú; PH-03 bật nhân bản `18.migration.shadow.sample-percent` (5%) lưu lượng của tuyến nhóm; phản hồi của Datahub ở chế độ bóng không gửi về HTTT.

**Kích hoạt.** Có cặp phản hồi cũ và mới; PH-18 nhận EVT-10-15, EVT-10-16; Mai mở `/van-hanh/di-tru/song-song`.

**Đảm bảo tối thiểu.** Không lưu thân phản hồi, chỉ lưu băm và kết quả so (Q18-14); tỷ lệ tụt dưới ngưỡng thì nhóm tự về `PARALLEL`.

**Đảm bảo thành công.** Nhóm có tỷ lệ khớp trượt 24 giờ và 7 ngày; đạt `18.migration.parallel.match-threshold-percent` (99,5%) trong 7 ngày liên tục với ít nhất 1.000 mẫu thì nhóm sang `SHADOW_OK`, EVT-18-27 phát.

**Luồng chính.**
1. Bộ so sánh nhận cặp phản hồi từ APISIX (bản gốc và bản nhân bản), chuẩn hóa theo quy tắc của nhóm và băm, gửi mẫu về PH-18 (API-18-176).
2. Hệ thống ghi `shadow_comparison_sample` với kết quả `MATCH`, `STATUS_DIFF` hoặc `BODY_DIFF`.
3. Hệ thống tính tỷ lệ khớp trượt 24 giờ và 7 ngày; `nhom-hotich` đạt 99,7% trên 4.380 mẫu trong 7 ngày nên sang `SHADOW_OK`, phát EVT-18-27.
4. Hệ thống tiêu thụ EVT-10-16 (trạng thái cầu nối) qua inbox và cập nhật nhóm.
5. Mai mở màn (API-18-173, 174): thấy mỗi nhóm với trạng thái, cầu nối, tỷ lệ khớp, số HTTT đã cấp lại xác thực, ngày hết hạn cầu nối; nhóm có cầu nối còn tối đa 7 ngày mà chưa `CUT_OVER` được tô cảnh báo.

**Luồng thay thế.**
- **3a. Tỷ lệ tụt dưới ngưỡng.** Nhóm về `PARALLEL`, gửi thông báo cho đội chuyển đổi.
- **2a. Lệch đã biết và chấp nhận.** Mai thêm quy tắc chuẩn hóa cho nhóm (ví dụ định dạng ngày); mẫu trong cửa sổ 7 ngày được tính lại (API-18-184, `If-Match`, lý do).
- **4a. PH-10 đã cắt chuyển cầu nối.** EVT-10-15 cho nhóm: hệ thống ghi sổ cắt chuyển và đóng theo dõi phần sự kiện của nhóm.
- **4b. Nhóm không dùng sự kiện.** Bỏ phần cầu nối.

**Luồng ngoại lệ.**
- **E1. Mẫu lệch (bước 2).** ERR-18-121 (worker): "Kết quả hệ mới khác hệ cũ ở {tuyến}." UI-18-23 hiện các đường dẫn trường lệch nhiều nhất.
- **E2. Không xử lý được sự kiện của PH-10 (bước 4).** ERR-18-124 (worker): "Xử lý sự kiện {mã} thất bại; đã chuyển vào DLQ." Hiện ở UI-18-24 (LP-18-06).

**Quy tắc áp dụng.** BR-18-044; LP-18-06.

**Màn hình, API.** UI-18-23; API-18-173, 174, 176, 184.
:::

### 6.38. UC-18-38 · Cắt chuyển nhóm dịch vụ và quay lui

::: dac-ta
**Mục tiêu.** Một nhóm dịch vụ chỉ được chuyển lưu lượng sang Datahub khi mọi điều kiện kiểm chứng đã đạt và có người thứ hai duyệt, và trong 15 phút đầu có thể trả về hệ cũ bằng một thao tác không cần duyệt.

**Tác nhân chính.** TA (Mai) đề nghị (`PERM-18-migration`); TA (Tuấn) hoặc PA duyệt (`PERM-18-approve`).

**Tác nhân phụ.** PH-03 (đổi tuyến APISIX theo tỷ lệ); PH-10 (cắt chuyển cầu nối); PH-13 (EVT-18-27); UC-18-27 (đóng băng).

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-068.

**Truy vết.** REQ-22; FR-00-071; D01-02 (quay lui 15 phút); BP-09.

**Tiền điều kiện.** `nhom-hotich` ở `SHADOW_OK` (cắt chuyển một phần) hoặc `PARTIAL_CUTOVER` (cắt chuyển toàn phần).

**Kích hoạt.** Mai bấm "Cắt chuyển" hoặc "Quay lui" ở UI-18-23; Tuấn mở việc `ph18.approve-cutover`.

**Đảm bảo tối thiểu.** Thiếu một mục kiểm tra thì không gửi được đề nghị; quay lui không cần bốn mắt; sau cửa sổ quay lui, trở lại hệ cũ phải lập kế hoạch đảo ngược riêng.

**Đảm bảo thành công.** `cutover_log` ghi mỗi bước; tuyến của nhóm ở Datahub theo tỷ lệ đã duyệt; nhóm `PARTIAL_CUTOVER` hoặc `CUT_OVER` với `rollbackUntil`; EVT-18-27 phát.

**Luồng chính.**
1. Mai mở danh sách kiểm tra của `nhom-hotich` (API-18-174). Hệ thống tự đánh giá: DLQ của nhóm không còn mục `NEW`, `TRIAGED`, `REPLAY_FAILED`; tỷ lệ khớp không dưới ngưỡng; 100% HTTT đã cấp lại xác thực; báo cáo đối chiếu không còn chênh lệch chưa giải trình; không đóng băng.
2. Mai xác nhận hai mục tay (đã thông báo HTTT, đã bố trí người trực) qua API-18-185 và gửi đề nghị cắt chuyển 100% lưu lượng (API-18-175, `action = REQUEST`): việc `ph18.approve-cutover` cho người có `PERM-18-approve` trừ Mai.
3. Tuấn duyệt (API-18-175, `action = APPROVE`). Hệ thống kiểm Tuấn khác Mai, ghi `cutover_log`, gửi yêu cầu đổi tuyến cho PH-03 và cắt chuyển cầu nối cho PH-10, chuyển nhóm `CUT_OVER` với `rollbackUntil` sau `18.migration.rollback-window-minutes` (15 phút), phát EVT-18-27.
4. Mười phút sau, Chi thấy tỷ lệ lỗi tăng; Mai bấm "Quay lui" (API-18-175, `action = ROLLBACK`, không cần bốn mắt). Hệ thống kiểm còn trong cửa sổ 15 phút, ghi sổ, yêu cầu PH-03 trả tuyến về hệ cũ, nhóm `ROLLED_BACK` rồi `PARALLEL`, phát EVT-18-27.

**Luồng thay thế.**
- **2a. Cắt chuyển một phần.** Từ `SHADOW_OK`, Mai đề nghị 20% lưu lượng; sau duyệt nhóm `PARTIAL_CUTOVER`, quay lui được bất cứ lúc nào.
- **3a. Từ chối.** Người duyệt từ chối kèm lý do (API-18-175, `action = REJECT`): nhóm giữ trạng thái.
- **4a. Không quay lui.** Hết 15 phút không có sự cố: nhóm giữ `CUT_OVER`.

**Luồng ngoại lệ.**
- **E1. Tỷ lệ khớp chưa đạt (bước 1).** ERR-18-066 (422): "Tỷ lệ khớp {tỷ lệ} thấp hơn ngưỡng {ngưỡng}."
- **E2. Danh sách kiểm tra chưa đạt (bước 2).** ERR-18-067 (409): "Chưa cắt chuyển được nhóm {nhóm}: còn {n} mục kiểm tra chưa đạt."
- **E3. Đang đóng băng (bước 1, 3).** ERR-18-051 (409): "Đang trong thời gian đóng băng thay đổi {cửa sổ} nên chưa chạy thật được."
- **E4. Người duyệt trùng người đề nghị (bước 3).** ERR-18-005 (403): "Bạn là người tạo {đối tượng} này nên không được duyệt."
- **E5. Quá cửa sổ quay lui (bước 4).** ERR-18-068 (409): "Đã quá {phút} phút kể từ khi cắt chuyển nên không quay lui tự động được."

**Quy tắc áp dụng.** BR-18-044; LP-18-01.

**Màn hình, API.** UI-18-23, UI-18-15; API-18-174, 175, 185.
:::

```{.mermaid caption="Trình tự cắt chuyển nhóm dịch vụ có duyệt bốn mắt và quay lui"}
sequenceDiagram
  actor TA as TA Mai
  actor AP as TA Tuấn
  participant O as dh-platform ops
  participant G as PH-03 APISIX
  participant E as PH-10 cầu nối
  TA->>O: Mở danh sách kiểm tra (API-18-174)
  O->>O: Đánh giá DLQ rỗng, tỷ lệ khớp, cấp lại xác thực, đối chiếu
  TA->>O: Đề nghị cắt chuyển 100 phần trăm (API-18-175)
  O-->>AP: Việc ph18.approve-cutover
  AP->>O: Duyệt
  O->>G: Đổi tuyến nhom-hotich sang Datahub
  O->>E: Cắt chuyển cầu nối
  O->>O: CUT_OVER, rollbackUntil sau 15 phút, EVT-18-27
  TA->>O: Quay lui trong cửa sổ
  O->>G: Trả tuyến về hệ cũ
  O->>O: ROLLED_BACK rồi PARALLEL
```

Hình cho thấy cắt chuyển cần hai người còn quay lui chỉ cần một, vì quay lui làm giảm rủi ro và phải nhanh.

### 6.39. UC-18-39 · Tra nhật ký thao tác và lập báo cáo vận hành định kỳ

::: dac-ta
**Mục tiêu.** Kiểm toán và lãnh đạo biết ai đã làm gì trên hệ thống vận hành, và mỗi kỳ có một báo cáo số liệu vận hành (DLQ, sao lưu, sự cố, di trú) không chứa dữ liệu cá nhân, đồng thời làm nguồn chỉ tiêu cho PH-16.

**Tác nhân chính.** AU (Phúc) tra nhật ký (`PERM-18-read`); TA (Mai) dựng báo cáo tay (`PERM-18-admin`, phạm vi báo cáo).

**Tác nhân phụ.** PH-13 (thư viện kiểm toán, lưu bản ghi có chuỗi băm); PH-16 (nhận EVT-18-28); Garage (`dh-t68-ops`); SO, TA xem.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-070, FR-18-071.

**Truy vết.** REQ-18; SEC-60; CMP-LAW-08; BP-07.

**Tiền điều kiện.** Thư viện kiểm toán chung của PH-13 sẵn sàng; kỳ báo cáo đã kết thúc.

**Kích hoạt.** Mọi thao tác có kiểm toán; Phúc mở tab "Nhật ký" ở UI-18-24 hoặc tab nhật ký của mục DLQ; ngày đầu kỳ mới 06:00 theo `18.report.schedule` (`MONTHLY`); Mai bấm "Dựng báo cáo".

**Đảm bảo tối thiểu.** Thao tác ghi không có hiệu lực nếu kiểm toán chưa ghi được, trừ hủy, tạm dừng, quay lui khẩn được ghi trễ qua outbox (BR-18-046); báo cáo không chứa payload hay dữ liệu cá nhân (BR-18-050).

**Đảm bảo thành công.** Phúc tra được nhật ký trong tenant hiện hành theo bộ lọc; báo cáo tháng 03/2027 dạng PDF, XLSX lưu Garage, `ops_report` ghi, EVT-18-28 phát.

**Luồng chính.**
1. Trước khi đổi dữ liệu, mô-đun PH-18 gọi thư viện kiểm toán ghi bản ghi `ops.*`; thư viện ghi có chuỗi băm ở PH-13, PH-18 giữ thêm `dlq_audit` cho thao tác trên mục DLQ.
2. Phúc mở tab "Nhật ký" (API-18-177), lọc theo người Chi và loại `ops.dlq.*`. Hệ thống đọc từ PH-13, chỉ trong T68.
3. Phúc mở nhật ký của `dlq-000123` (API-18-063) và nhật ký đổi tham số (API-18-016).
4. Ngày 01/04/2027 06:00, hệ thống kiểm kỳ 03/2027 hợp lệ, đã kết thúc, tổng hợp số mục DLQ mới, đã xử lý, tồn, thời gian xử lý trung vị, tỷ lệ phát lại thành công; tỷ lệ đối tượng sao lưu đúng hạn và kiểm tra khôi phục đạt; số sự cố theo mức, thời gian nhận và khắc phục; tiến độ di trú, tỷ lệ khớp (API-18-081).
5. Hệ thống dựng tệp PDF, XLSX lưu `dh-t68-ops`, ghi `ops_report`, phát EVT-18-28 mang số liệu tổng hợp cho PH-16; người có `PERM-18-read` xem (API-18-178).

**Luồng thay thế.**
- **1a. PH-13 vắng khi hủy, tạm dừng, quay lui khẩn.** Thao tác vẫn thực hiện, bản ghi kiểm toán giữ ở outbox và gửi khi PH-13 trở lại.
- **4a. Dựng tay.** Mai bấm "Dựng báo cáo" (API-18-179).
- **5a. Dựng lại kỳ đã có.** Tạo phiên bản báo cáo mới, giữ bản cũ.

**Luồng ngoại lệ.**
- **E1. PH-13 không ghi được kiểm toán (bước 1).** ERR-18-008 (503): "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
- **E2. Kỳ không hợp lệ hoặc chưa kết thúc (bước 4, nhánh 4a).** ERR-18-072 (422): "Kỳ báo cáo {kỳ} không hợp lệ hoặc chưa kết thúc."

**Quy tắc áp dụng.** BR-18-046; BR-18-050; LP-18-02.

**Màn hình, API.** UI-18-24, UI-18-03; API-18-016, 063, 081, 177, 178, 179.
:::

### 6.40. UC-18-40 · Theo dõi sức khỏe và chạy ở chế độ suy giảm

::: dac-ta
**Mục tiêu.** Người trực nền tảng thấy ngay thành phần nào của PH-18 đang lỗi, và khi cần bảo trì CSDL thì đưa PH-18 vào chế độ chỉ đọc mà các phân hệ khác vẫn chạy bình thường.

**Tác nhân chính.** PO (Khoa) theo dõi; PA (Hà) bật chế độ chỉ đọc (`PERM-18-admin`).

**Tác nhân phụ.** PH-13 (thu `dh_ops_component_up`, nhận EVT-18-29); `dh-console` (dải cảnh báo); CSDL, Kafka, Garage, máy chủ thư, SMS gateway, PH-10, registry PH-20, Kubernetes API.

**Mức ưu tiên.** M · MVP.

**FR hiện thực.** FR-18-072.

**Truy vết.** REQ-18; LGC-NFR-001; LGC-NFR-006; BP-07.

**Tiền điều kiện.** Không.

**Kích hoạt.** Kiểm tra sức khỏe mỗi 15 giây; Hà bật chế độ chỉ đọc (API-18-187); Khoa mở UI-18-24.

**Đảm bảo tối thiểu.** Ở chế độ chỉ đọc, bản tin lỗi dồn ở Kafka không mất, thông báo đã vào outbox vẫn được gửi; phân hệ khác đọc tham số từ bộ đệm (LP-18-04).

**Đảm bảo thành công.** Trạng thái `UP`, `DEGRADED`, `DOWN` của PH-18 và từng thành phần hiện đúng; EVT-18-29 phát mỗi lần đổi; mọi màn `/van-hanh` hiện dải cảnh báo khi chỉ đọc.

**Luồng chính.**
1. Hệ thống kiểm từng thành phần mỗi 15 giây: CSDL, Kafka (độ trễ tiêu thụ DLQ, inbox), Garage, máy chủ thư, SMS gateway, PH-13, PH-10, registry PH-20, Kubernetes API (tạo Job); phát `dh_ops_component_up{component}`.
2. SMS gateway lỗi: hệ thống đặt PH-18 `DEGRADED`, phát EVT-18-29; chỉ kênh SMS suy giảm, phần khác chạy bình thường.
3. Khoa mở UI-18-24 (API-18-180): thấy trạng thái từng thành phần, độ trễ tiêu thụ, outbox tồn, danh sách inbox `FAILED` theo mô-đun (API-18-186), Job đang chạy.
4. Trước khi bảo trì CSDL, Hà bật chế độ chỉ đọc kèm lý do (API-18-187, `PERM-18-admin`); hệ thống ghi khóa `18.degraded.read-only`, phát EVT-18-29 với `readOnly = true`; API ghi của người dùng trả lỗi chỉ đọc, trừ API-18-187; tiêu thụ DLQ tạm dừng; thông báo vẫn gửi từ outbox đã có.

**Luồng thay thế.**
- **4a. Kết thúc bảo trì.** Hà tắt chế độ chỉ đọc qua API-18-187 (API này không bị chặn); tiêu thụ DLQ đọc tiếp từ offset đã commit.

**Luồng ngoại lệ.**
- **E1. Ghi khi đang chỉ đọc (bước 4).** ERR-18-071 (503): "Phân hệ vận hành đang ở chế độ chỉ đọc. Thao tác tạm thời không thực hiện được.".
- **E2. Đổi khóa chỉ đọc qua API-18-006 (bước 4).** ERR-18-003 (400): "Dữ liệu không hợp lệ: {chi tiết}." Khóa `18.degraded.read-only` chỉ đổi qua API-18-187.

**Quy tắc áp dụng.** BR-18-007; BR-18-011; LP-18-04.

**Màn hình, API.** UI-18-24; API-18-180, 186, 187.
:::

## 7. Luồng phụ dùng chung

Sáu luồng phụ lặp lại ở nhiều use case nên đặc tả một lần; mã lỗi vẫn ghi ở luồng ngoại lệ của từng use case để kiểm thử viên không phải tra chéo.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-18-01 | Bốn mắt: người duyệt phải khác người đề nghị, trùng thì nút "Duyệt" bị khóa và gọi thẳng API trả ERR-18-005 (403). Việc duyệt được tạo trong Việc của tôi cho người có `PERM-18-approve` với `excludeUsers` là người đề nghị. Áp dụng cho tham số ★, gói tham số có khóa ★, bản sửa payload chạm trường mức Hạn chế, Nhạy cảm, lượt phát lại vượt `18.dlq.replay.approval-threshold`, phiên bản mẫu thông báo, khôi phục tenant, chạy di trú thật, cắt chuyển (FR-00-071, ADR-046). Hủy, tạm dừng, quay lui không cần bốn mắt vì làm giảm rủi ro | UC-18-03, 05, 14, 17, 20, 31, 36, 38 |
| LP-18-02 | Lý do bắt buộc và kiểm toán trước: thao tác ghi có lý do (từ 10 ký tự) và ghi kiểm toán PH-13 trước khi có hiệu lực; thiếu lý do trả ERR-18-007 (422); PH-13 không ghi được trả ERR-18-008 (503), trừ hủy, tạm dừng, quay lui khẩn được ghi trễ qua outbox (BR-18-046) | UC-18-02, 03, 04, 08, 12, 13, 14, 18, 28, 31, 39 |
| LP-18-03 | Xung đột đồng thời và lặp lệnh: `PUT`, `PATCH`, chuyển trạng thái mang `If-Match`, sai phiên bản trả ERR-18-004 (412), thiếu trả ERR-00-428; `POST` mang `Idempotency-Key`, dùng lại với thân khác trả ERR-18-009 (409); thao tác sai trạng thái trả ERR-18-006 (409) (BR-18-049) | UC-18-02, 04, 06, 12, 15, 16, 17, 21 |
| LP-18-04 | Phụ thuộc mềm, PH-18 không chặn đường chính: phân hệ khác đọc tham số từ bộ đệm rồi mặc định đóng gói; giữ bản tin lỗi trong Kafka hoặc hàng lỗi của mình; giữ hàng đợi việc ở màn của mình; coi là không đóng băng và tính hạn theo cuối tuần khi PH-18 vắng quá 24 giờ. Phía PH-18, chẩn đoán PH-13 và DLQ tầng sự kiện PH-10 là phụ thuộc mềm (BR-18-007, BR-18-011, BR-18-035) | UC-18-01, 09, 10, 11, 13, 25, 27, 40 |
| LP-18-05 | Một tác vụ nặng mỗi tenant: khôi phục, xuất, chạy di trú thật, chuyển sáp nhập của cùng tenant không chạy đồng thời; vi phạm trả ERR-18-057 (409) (BR-18-039) | UC-18-31, 32, 33, 36 |
| LP-18-06 | Sự kiện tiêu thụ lỗi: mỗi bộ tiêu thụ có inbox khử trùng theo `eventId`; xử lý lỗi sau 5 lần thì inbox `FAILED`, ghi ERR-18-124 và mục vào DLQ của chính PH-18 (nguồn `PH18_INBOX`), hiện ở UI-18-24; người vận hành phát lại như mục DLQ thường | UC-18-07, 23, 28, 37 |

: Luồng phụ dùng chung và use case dùng

## 8. Tổng hợp mã mới và đối chiếu

Chương này tổng kết mã do tập tạo ra, độ phủ so với FRS và những điểm lệch đã phát hiện khi viết use case.

### 8.1. Mã mới và độ phủ

Tập này không tạo mã FR, BR, API, ERR, EVT, UI mới. Mã của tập: UC-18-01 đến UC-18-40, LP-18-01 đến LP-18-06, câu hỏi mở Q18-45 đến Q18-49, đề nghị đồng bộ ĐN-UC-01 đến ĐN-UC-15. Đề nghị D05-02-PH18 dựng kịch bản kiểm thử TS-18-nn ứng một một với UC-18-nn. Cả 72 FR thuộc ít nhất một use case (mục 5.4); cả 188 API và 24 màn hình của FRS đều xuất hiện ở mục 5.2. Mã ERR, EVT, API, UI, PERM, trạng thái và tham số `18.*` lấy đúng FRS mục 3, 4, 8.2, 9, 10.1; câu thông báo nguyên văn FRS mục 9.1.

### 8.2. Đối chiếu với FRS 0.2

Bảng dưới cho thấy tập này dùng bao nhiêu mã của FRS. Mọi mã lỗi, sự kiện, API và màn hình của FRS đều được ít nhất một use case dẫn; từ FRS 0.2, câu thông báo của mục 9.1 là câu chung có tham số nên được dẫn nguyên văn, không còn ghi chú lệch ngữ cảnh.

| Hạng mục | Số trong FRS | Số được dẫn trong tập này |
|---|---|---|
| FR (FR-18-001…072) | 72 | 72 |
| ERR control plane (ERR-18-001…072) | 72 | 72 |
| ERR worker (ERR-18-101…124) | 24 | 24 |
| EVT phát (EVT-18-01…29) | 29 | 29 |
| API (API-18-001…188) | 188 | 188 |
| Màn hình (UI-18-01…24) | 24 | 24 |
| BR (BR-18-001…050) | 50 | 50 |
| Use case máy với máy (UC-18-01, 07, 10, 25, 33) | 5 | 5 |

: Đối chiếu mã của FRS với tập use case

### 8.3. Đề nghị đồng bộ

Tập này không sửa tài liệu khác. Mười lăm đề nghị cho chủ tài liệu (FRS, D03-04-PH18, D03-06-PH18, D02-08, D05-02-PH18) nằm ở Phụ lục A; mười một đề nghị đầu là chỗ FRS 0.1 còn lệch, thiếu hoặc chưa rõ khi viết use case. Ở bản 0.2, mười hai đề nghị đã được hấp thụ (cột "Trạng thái"); ba đề nghị còn giữ cho đợt đồng bộ liên phân hệ.

## 9. Câu hỏi mở

Các câu hỏi Q18-01 đến Q18-19 nằm ở FRS mục 13. Dưới đây là năm câu mới phát sinh khi viết use case, theo dải Q18-45 đến Q18-49 dành cho tập use case.

> **Câu hỏi mở Q18-45:** UC-18-14 bước 3: FR-18-024 chỉ nói bản sửa chạm trường mức Hạn chế hoặc Nhạy cảm thì cần bốn mắt, nhưng không nói trường chưa được PH-09 xác định mức. Mẫu thông báo (BR-18-027) đã coi biến chưa xác định mức là bị cấm. Đề xuất coi trường chưa xác định mức như Hạn chế để đóng an toàn (bản sửa cần bốn mắt); cần SO và PH-09 xác nhận.

> **Câu hỏi mở Q18-46:** UC-18-31: chỉ tiêu "tối đa 4 giờ cho tenant đến 200 GB" (`18.restore.max-duration-hours`) tính từ lúc PA duyệt hay từ lúc TA gửi yêu cầu? Khi sự cố ngoài giờ mà không có PA trực, thời gian chờ duyệt có thể vượt 4 giờ. Đề xuất tính từ lúc duyệt và yêu cầu PH-13 đưa PA vào lịch trực khi có yêu cầu khôi phục `PENDING_APPROVAL`; cần PA và chủ đầu tư chốt.

> **Câu hỏi mở Q18-47:** UC-18-03 nhánh 2a có hạn duyệt 72 giờ (`18.param.change-request-ttl-hours`), còn lượt phát lại, bản sửa payload, phiên bản mẫu, yêu cầu khôi phục, lần chạy di trú thật và đề nghị cắt chuyển ở `PENDING_APPROVAL` không có hạn. Danh sách mục của lượt phát lại để lâu sẽ lệch thực tế. Đề xuất dùng chung một khóa hạn duyệt cho mọi đề nghị bốn mắt của PH-18 (ví dụ `18.approval.ttl-hours`, mặc định 72) và tự chuyển `REJECTED` khi hết hạn; cần kiến trúc sư PH-18 quyết định và FRS thêm khóa.

> **Câu hỏi mở Q18-48:** UC-18-38 bước 2: hai mục kiểm tra tay (đã thông báo HTTT, đã bố trí người trực) do chính người đề nghị xác nhận. Người duyệt có phải xác nhận lại từng mục tay, hay chỉ duyệt toàn bộ đề nghị? Đề xuất người duyệt thấy rõ ai xác nhận mục tay và lúc nào, không phải xác nhận lại; cần đội chuyển đổi và chủ đầu tư thống nhất.

> **Câu hỏi mở Q18-49:** UC-18-21 nhánh 1c: tenant `SUSPENDED` chỉ nhận thông báo nhóm bắt buộc, mà khôi phục tenant (UC-18-31) đặt tenant `SUSPENDED` từ bước 4 đến bước 8. Thông báo tiến độ, kết quả khôi phục cho TA và PA có thuộc nhóm bắt buộc không? Đề xuất thêm nhóm "vận hành bắt buộc" gồm thông báo khôi phục, sự cố `SEV1` và bảo trì, không tắt được và không bị chặn khi tenant tạm ngừng; cần PH-20 và chủ sở hữu PH-18 xác nhận.

## Phụ lục A. Đề nghị đồng bộ

Phụ lục ghi những điểm lệch, thiếu hoặc chưa rõ phát hiện khi viết use case, để chủ tài liệu quyết định. Đề nghị ĐN-UC-01 đến ĐN-UC-11 dành cho FRS 0.1 (và D03-04-PH18 khi API liên quan); ĐN-UC-12 đến ĐN-UC-15 dành cho tập khác. FRS vẫn là nguồn chuẩn cho tới khi chủ tài liệu nhận đề nghị. Cột "Trạng thái" ghi kết quả đợt đồng bộ nội bộ ở bản 0.2.

| Mã | Đối tượng | Đề nghị | Nguồn | Trạng thái |
|---|---|---|---|---|
| ĐN-UC-01 | FRS mục 9.1 | Năm mã dùng ở nhiều ngữ cảnh có câu thông báo viết cho một ngữ cảnh: ERR-18-001 ("Không tìm thấy phiên bản {số} của {khóa}" nhưng dùng cho tenant, mục DLQ, việc, đối tượng sao lưu), ERR-18-005 ("người đề nghị" nhưng dùng cho người tạo bản sửa, lượt, yêu cầu), ERR-18-006 ("Đối soát đang chạy" nhưng dùng cho mọi sai trạng thái), ERR-18-007 ("lý do xem nội dung" nhưng dùng cho tham số, bỏ qua, bản sửa), ERR-18-013 (dùng cho cả số mục egress), cùng ERR-18-017 (dùng cho loại việc). Khối FR ở chương 6 của FRS đã viết câu theo ngữ cảnh. Đề nghị đổi cột "Thông báo" thành câu chung có tham số (ví dụ "Không tìm thấy {đối tượng} {mã}.", "{Đối tượng} đang ở trạng thái {trạng thái} nên không thể {thao tác}.") hoặc liệt kê biến thể theo FR; tập này đã dẫn nguyên văn và ghi chú tại chỗ | UC-18-01, 02, 06, 07, 12, 13, 15, 17, 18, 24, 25, 26, 28, 30 | Đã hấp thụ ở 0.2: FRS mục 9.1 dùng câu chung có tham số |
| ĐN-UC-02 | FRS ERR-18-071 | Câu "Thay đổi tham số tạm thời không thực hiện được" ở mục 9.1 hẹp hơn FR-18-072 ("Thao tác tạm thời không thực hiện được") trong khi chế độ chỉ đọc chặn mọi API ghi. Đề nghị dùng câu chung của FR-18-072 | UC-18-02, 07, 40 | Đã hấp thụ ở 0.2: câu chung của FR-18-072 |
| ĐN-UC-03 | FRS FR-18-044, D03-04-PH18 | Thao tác "Nhận việc" (`IN_PROGRESS`, phát EVT-18-14) không có API ghi; API-18-111, 112 chỉ đọc. Đề nghị thêm `POST /me/tasks/{taskId}:claim` | UC-18-26 bước 3 | Đã hấp thụ ở 0.2: API-18-181 |
| ĐN-UC-04 | FRS FR-18-063, D03-04-PH18 | Đánh dấu cách xử lý bản ghi lỗi di trú (sửa ở nguồn, thêm quy tắc, `WONT_MIGRATE` kèm lý do) không có API ghi; API-18-170 chỉ đọc. Đề nghị thêm `PATCH /migration-runs/{runId}/errors/{errorId}` và thao tác hàng loạt, quyền `PERM-18-migration` (DS ○) | UC-18-35 bước 7 | Đã hấp thụ ở 0.2: API-18-182 (thao tác hàng loạt trên `/migration-runs/{runId}/errors`) |
| ĐN-UC-05 | FRS FR-18-065, D03-04-PH18 | TA đánh dấu `NOT_NEEDED` cho thông tin xác thực không cần cấp lại không có API; API-18-172 chỉ đọc. Đề nghị thêm `POST /credential-reissues/{markerId}:not-needed` có lý do | UC-18-36 nhánh 7a | Đã hấp thụ ở 0.2: API-18-183 `:waive`, trạng thái `WAIVED` |
| ĐN-UC-06 | FRS FR-18-067, D03-04-PH18 | Thêm quy tắc chuẩn hóa so sánh cho nhóm (để chấp nhận lệch đã biết và tính lại mẫu cũ) không có API. Đề nghị thêm `PUT /parallel-groups/{groupCode}/normalization-rules` | UC-18-37 nhánh 2a | Đã hấp thụ ở 0.2: API-18-184 |
| ĐN-UC-07 | FRS FR-18-063 | FR-18-063 dùng ERR-18-036 với câu "Không có bản ghi lỗi nào để chạy lại", khác câu của mục 9.1 ("Bộ lọc không có mục nào phát lại được"). Đề nghị câu chung "Không có mục nào phù hợp để {thao tác}." hoặc cấp mã riêng | UC-18-35 E5 | Đã hấp thụ ở 0.2: câu chung "Không có mục nào phù hợp để {thao tác}." |
| ĐN-UC-08 | FRS FR-18-068, D03-04-PH18 | Cắt chuyển có bốn mắt nhưng chỉ có API-18-175 `:transition` (quyền "migration, approve"), chưa tách đề nghị, duyệt, từ chối và quay lui. Đề nghị nêu rõ thân `action` (`REQUEST`, `APPROVE`, `REJECT`, `ROLLBACK`) và quyền theo từng giá trị, hoặc tách bốn endpoint như lượt phát lại | UC-18-38 bước 2, 3, nhánh 3a | Đã hấp thụ ở 0.2: API-18-175 nhận `action` (`REQUEST`, `APPROVE`, `REJECT`, `ROLLBACK`), quyền theo từng giá trị; mục tay qua API-18-185 |
| ĐN-UC-09 | FRS mục 10.1 | UI-18-18 ghi vai "DPO", UI-18-21 đến UI-18-23 ghi vai "MO", nhưng hai vai này không có ở bảng tác nhân mục 3.1 và ma trận quyền mục 3.2. Đề nghị thay bằng SO (UI-18-18) và PA, TA (UI-18-21 đến 23), hoặc định nghĩa vai | Mục 3, UC-18-29, 34 đến 38 | Đã hấp thụ ở 0.2: FRS mục 10.1 dùng SO, PA, TA |
| ĐN-UC-10 | FRS mục 9.4, D03-04-PH18 | API-18-150, 153 (`/merge-transfers`) nằm ở tiền tố người dùng `/api/ops/v1` nhưng chỉ dùng scope máy `ops:merge-transfer` của PH-20. Đề nghị ghi rõ PH-20 gọi qua APISIX bằng client credentials, hoặc chuyển sang `/ops/internal/v1` cho thống nhất với các API máy khác | UC-18-33 | Giữ: chờ đợt đồng bộ liên phân hệ (PH-20, APISIX) |
| ĐN-UC-11 | FRS FR-18-072 | Chế độ chỉ đọc bật bằng khóa `18.degraded.read-only` qua API-18-006 (quyền `PERM-18-config`), trong khi FR-18-072 ghi quyền `PERM-18-admin`; khi đã chỉ đọc thì API ghi trả ERR-18-071 nên không tắt được bằng chính API đó. Đề nghị miễn khóa này khỏi chặn chỉ đọc hoặc thêm thao tác riêng cho PA | UC-18-40 bước 4, nhánh 4a | Đã hấp thụ ở 0.2: API-18-187, miễn chặn chỉ đọc |
| ĐN-UC-12 | D02-08 | Dòng `PERM-18-*` ở D02-08 lệch ma trận FRS mục 3.2: `PERM-18-dlq` (D02-08 không cấp cho PA, cấp đủ cho IE; FRS cấp hạn chế cho PA, IE, DS), `PERM-18-dlq-payload` (D02-08 không cấp cho PO, IE; FRS cấp hạn chế cho PO, cấp đủ cho IE), `PERM-18-approve` (D02-08 không cấp cho SO; FRS cấp cho SO). Tập này theo FRS; đề nghị đối chiếu lại như FRS mục 12.4 đã nêu | Mục 3, UC-18-03, 13, 14 | Giữ: chờ D02-08 |
| ĐN-UC-13 | FRS FR-18-062 | Tiền điều kiện của chạy thật là kế hoạch `READY` nhưng luồng chính không kiểm và ERR-18-065 chỉ gắn FR-18-061. Đề nghị thêm bước kiểm kế hoạch `READY` (ERR-18-065) vào FR-18-062 | UC-18-36 bước 1 | Đã hấp thụ ở 0.2: FR-18-062 kiểm `READY` (ERR-18-065) |
| ĐN-UC-14 | D03-06-PH18 | Lấy câu thông báo và luồng thao tác từ chương 6; với các mã ở ĐN-UC-01 dùng câu theo ngữ cảnh khi FRS nhận đề nghị; dải cảnh báo chỉ đọc trên mọi màn `/van-hanh` | Chương 6 | Giữ: chờ D03-06-PH18 bản sau (đã nhận một phần) |
| ĐN-UC-15 | D05-02-PH18 | Dựng TS-18-nn ứng một một với UC-18-nn; bắt buộc có kịch bản bốn mắt (mỗi UC trong LP-18-01 một ca người duyệt trùng người đề nghị), kịch bản lũy đẳng phát lại (gọi lại cùng khóa, kết quả đến muộn), kịch bản khôi phục lỗi ở bước 3 và bước 5, kịch bản cắt chuyển rồi quay lui ở phút thứ 14 và phút thứ 16 (đồng hồ giả lập) | UC-18-14, 16, 17, 31, 38 | Đã hấp thụ ở 0.2: D05-02-PH18 đã dựng TS-18-nn |

: Đề nghị đồng bộ cho tài liệu khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-UC và K-TRINH-BAY: 40 use case phủ 72 FR của FRS 0.1, sáu sơ đồ use case theo nhóm, mười bốn sơ đồ trình tự (bốn mắt tham số, tiếp nhận DLQ, DLQ tầng sự kiện, chẩn đoán và xem nội dung, sửa payload, phát lại một mục, phát lại loạt, mẫu thông báo, gửi thông báo, chuyển PH-09, khôi phục tenant tám bước, sáp nhập, di trú thật, cắt chuyển), ma trận truy vết hai chiều, sáu luồng phụ, mười lăm đề nghị đồng bộ, năm câu hỏi mở Q18-45…49 |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ nội bộ theo FRS 0.2: câu thông báo ERR-18-001, 005, 006, 007, 013, 017, 036, 069, 071 dẫn nguyên văn câu chung có tham số; thêm API-18-181…188 vào luồng và ma trận mục 5.2 (UC-18-16, 26, 35 đến 38, 40); `NOT_NEEDED` đổi thành `WAIVED`; cắt chuyển dùng `action` của API-18-175; UC-18-36 kiểm kế hoạch `READY` (ERR-18-065); chế độ chỉ đọc bật, tắt qua API-18-187; Phụ lục A thêm cột trạng thái, 12 đề nghị đã hấp thụ, giữ ĐN-UC-10, 12, 14 |
