---
ma_tai_lieu: D02-05
ten: Backlog user story của Datahub
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: PO hai phía, Scrum Master, kỹ sư phát triển, kiểm thử viên, hội đồng thẩm định
mo_ta: Backlog user story của 20 phân hệ và phần dùng chung, gồm epic, story viết theo mẫu Là, tôi muốn, để, điểm ước lượng, đợt và wave, truy vết FR và UC, kèm tệp CSV nhập Jira và GitLab.
tai_lieu_lien_quan: D01-02 Kế hoạch dự án; D02-02 SRS; D02-03 FRS 20 phân hệ; D02-04 Use case; D02-05-01 Phụ lục tiêu chí chấp nhận; D05-02 Test case
---

# D02-05 · Backlog user story của Datahub

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chuyển toàn bộ yêu cầu chức năng đã đặc tả (40 FR dùng chung của SRS và 1.247 FR của 20 FRS phân hệ) thành backlog mà đội Scrum dùng được ngay: mỗi FR thành một user story viết theo mẫu "Là …, tôi muốn …, để …", có tiêu chí chấp nhận Gherkin, điểm ước lượng, epic, đợt phát hành, wave và truy vết tới FR, UC. Backlog là cấp 3 của WBS mà D01-02 §2.1 dành riêng cho tài liệu này.

**Phạm vi.** 1.287 story trong 195 epic, tổng 4.236 điểm. Phụ lục D02-05-01 ghi đủ tiêu chí chấp nhận của từng story; thư mục `02-yeu-cau/backlog/` chứa tệp Gherkin chạy được và hai tệp CSV để nhập vào Jira hoặc GitLab. Yêu cầu phi chức năng không thành story riêng mà đi vào định nghĩa hoàn thành (DoD) và tiêu chí chấp nhận của story liên quan.

**Căn cứ.** D01-02 §3 (Scrum lai trong khung wave, DoR và DoD ba mức, PO hai phía); D02-02 SRS chương 4; D02-03 FRS chương 6 của 20 phân hệ; dàn ý bộ tài liệu SDLC mục D02-05. Quy trình nghiệm thu từng phần theo Nghị định 224/2026/NĐ-CP được D01-02 §3.9 gắn với cổng G0…G5; backlog này là đầu vào để chứng minh phạm vi của từng cổng.

**Những điểm hội đồng cần lưu ý.**

1. Backlog được **sinh tự động** từ khối đặc tả 17 mục của FR bằng script `sinh_backlog.py`, không viết tay. Vì vậy backlog luôn khớp FRS; khi FRS đổi, chạy lại script là backlog đổi theo, không có hai nguồn sự thật.
2. Một FR là một story, số story trùng số FR (`US-07-021` hiện thực `FR-07-021`). Story tách thêm khi làm rõ backlog lấy số từ 501 trở lên trong cùng phân hệ.
3. Điểm ước lượng là **điểm ban đầu** tính theo công thức độ phức tạp ở chương 4, dùng để lập kế hoạch wave; đội Scrum ước lượng lại bằng planning poker ở buổi làm rõ backlog trước sprint. Quy đổi tổng điểm ra người-tháng khớp với nỗ lực lập trình, giao diện, kiểm thử của D01-02 trong khoảng 1 điểm ≈ 0,9 người-ngày (giả định GĐ-BL-01).
4. Đối chiếu sức chứa cho thấy W1 cần vận tốc khoảng 60 điểm mỗi đội mỗi sprint, cao hơn mức nền 49 điểm; đây chính là điểm căng W1–W2 mà D01-02 §2.6 đã nêu, và chương 5 ghi cách xử lý.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Story | 1.287 (1.022 mức M, 231 mức S, 34 mức C) |
| Epic | 195 (một epic một nhóm chức năng của FRS) |
| Tổng điểm ban đầu | 4.236 điểm, bình quân 3,3 điểm mỗi story |
| Story đề nghị tách khi làm rõ backlog | 8 |
| Story có UC hiện thực | 1.243 trên 1.247 story phân hệ |
| Kịch bản Gherkin | Một dương và tối đa hai âm cho mỗi story mức M |

: Con số chính của backlog user story

## Giới thiệu tài liệu

### Mục đích

Tài liệu là danh sách công việc có thứ tự của dự án ở mức story: PO hai phía dùng để chọn phạm vi sprint và nghiệm thu, Scrum Master dùng để kiểm tra sức chứa wave, kỹ sư và kiểm thử viên dùng để biết story nào hiện thực FR nào và được chấp nhận theo tiêu chí nào.

### Phạm vi

Gồm mọi FR có khối đặc tả trong SRS (FR-00) và trong 20 FRS phân hệ tại ngày 27/11/2026. Không gồm: story kỹ thuật của W0 (khung monorepo, DEV/TEST, cổng CI) vì đã nằm trong gói WBS 1.21, 1.22 của D01-02; yêu cầu phi chức năng `NFR` (đi vào DoD); story tách thêm phát sinh khi làm rõ backlog (ghi trực tiếp trong công cụ quản lý công việc rồi đồng bộ về tài liệu ở mỗi cổng).

### Người đọc

Mỗi nhóm người đọc chỉ cần một phần của tài liệu; bảng dưới chỉ phần cần đọc.

| Người đọc | Đọc | Để làm gì |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 1, 5 | Thấy phạm vi đã được phân rã tới mức hiện thực và kế hoạch wave có cơ sở |
| PO phía chủ đầu tư | Chương 1, 5, 6 | Chọn và chấp nhận story, theo dõi phạm vi wave |
| PO, BA nhà thầu và Scrum Master | Toàn bộ | Duy trì backlog, lập kế hoạch sprint, kiểm tra DoR |
| Kỹ sư phát triển, kiểm thử viên | Chương 3, 6 và phụ lục D02-05-01 | Biết story hiện thực FR nào, tiêu chí chấp nhận nào |
| Quản trị công cụ (Jira, GitLab) | Chương 7 | Nhập backlog vào công cụ |

: Người đọc và phần cần đọc của D02-05

### Thuật ngữ và chữ viết tắt

Thuật ngữ dưới đây là thuật ngữ riêng của backlog; thuật ngữ chung của bộ tài liệu ở D00-01.

| Thuật ngữ | Nghĩa |
|---|---|
| User story (story) | Một yêu cầu viết từ góc nhìn người dùng, đủ nhỏ để làm xong trong một sprint; mã `US-{PH}-{nnn}` |
| Epic | Nhóm story cùng mục tiêu nghiệp vụ, ở đây trùng nhóm chức năng (Nhóm A, B…) của FRS; mã `EP-{PH}-{chữ}` |
| Điểm (story point) | Đơn vị ước lượng tương đối độ lớn của story, dùng dãy Fibonacci 1, 2, 3, 5, 8 |
| Vận tốc (velocity) | Số điểm một đội làm xong trong một sprint |
| DoR, DoD | Định nghĩa sẵn sàng, định nghĩa hoàn thành của story (D01-02 §3.6) |
| Gherkin | Ngôn ngữ viết tiêu chí chấp nhận dạng Biết (Given), Khi (When), Thì (Then), Và (And). "Biết" là từ khóa tiếng Việt chuẩn của Gherkin cho Given; D01-02 gọi bước này là "Cho trước", hai cách gọi cùng nghĩa |
| Wave, sprint, cổng | W0…W5, chu kỳ 2 tuần, G0…G5 theo D01-02 §3.2 |
| Đợt | MVP, Đợt 2, Đợt 3 theo D03-01 §4.1; "Đợt sau" là ngoài phạm vi v1.0 |
| M, S, C | Mức ưu tiên Phải có, Nên có, Có thể có (MoSCoW, D00-01) |

: Thuật ngữ và chữ viết tắt dùng trong backlog

Viết tắt vai trò (PA, TA, IE, DS…) theo D02-08 §3; trong câu chuyện người dùng, vai trò được viết bằng tên đầy đủ.

### Tài liệu tham chiếu

Backlog được sinh từ các tài liệu sau và phải được sinh lại khi chúng đổi.

| Mã | Tài liệu | Dùng cho |
|---|---|---|
| D01-02 | Kế hoạch dự án | Wave, sprint, đội, DoR và DoD, nỗ lực theo gói |
| D02-02 | SRS | 40 FR dùng chung (FR-00) |
| D02-03-PH01…PH20 | FRS 20 phân hệ | 1.247 FR, nhóm chức năng làm epic |
| D02-04-PH01…PH20 | Use case 20 phân hệ | Trường "FR hiện thực" để truy vết story tới UC |
| D02-08 | Ma trận phân quyền | Vai trò trong câu chuyện |
| D05-02 | Test case 20 phân hệ | Ca kiểm thử chi tiết hiện thực tiêu chí chấp nhận |
| D02-05-01 | Phụ lục tiêu chí chấp nhận | Tiêu chí Gherkin của từng story |

: Tài liệu tham chiếu của D02-05

### Cấu trúc tài liệu

Chương 1 đến 5 và 7 đến 9 viết tay; chương 6 và các bảng có ghi "sinh tự động" (ở chương 4, 5 và phần tóm tắt) do script tạo.

| Chương | Nội dung |
|---|---|
| 1 | Backlog trong mô hình thực hiện |
| 2 | Cấu trúc backlog: epic, story, tiêu chí chấp nhận, vòng đời story |
| 3 | Quy tắc chuyển FR thành story và một ví dụ đầy đủ |
| 4 | Ước lượng điểm |
| 5 | Kế hoạch phát hành theo wave và đối chiếu sức chứa |
| 6 | Danh sách epic và story theo phân hệ |
| 7 | Nhập vào Jira, GitLab |
| 8 | Duy trì backlog và truy vết |
| 9 | Giả định, câu hỏi mở và đề nghị đồng bộ |

: Cấu trúc chương của D02-05

## 1. Backlog trong mô hình thực hiện

Dự án làm theo Scrum lai: bên ngoài là sáu wave có phạm vi chốt trước và cổng nghiệm thu cố định, bên trong là sprint 2 tuần (D01-02 §3). Backlog là chỗ hai tầng gặp nhau. Phạm vi một wave được chốt bằng danh sách story của wave đó; mỗi sprint chọn ra các story đạt DoR; cổng cuối wave kiểm tra mọi story mức M của wave đã đạt DoD. Vì vậy backlog phải đủ chi tiết để chọn sprint, nhưng vẫn truy ngược được về FR mà hội đồng đã duyệt.

Sơ đồ sau cho thấy vị trí của backlog giữa đặc tả và kiểm thử.

```{.mermaid caption="Vị trí của backlog giữa FRS, use case, sprint và kiểm thử"}
flowchart TB
  SRS["D02-02 SRS<br/>40 FR-00"] --> GEN
  FRS["D02-03 FRS<br/>1.247 FR"] --> GEN
  UC["D02-04 Use case<br/>FR hiện thực"] --> GEN
  GEN["sinh_backlog.py"] --> BL["D02-05 Backlog<br/>195 epic, 1.287 story"]
  GEN --> AC["D02-05-01 và tệp .feature<br/>tiêu chí chấp nhận"]
  GEN --> CSV["CSV Jira, GitLab"]
  BL --> SP["Sprint planning<br/>story đạt DoR"]
  CSV --> TOOL["Công cụ quản lý công việc"]
  TOOL --> SP
  SP --> DEV["Phát triển, PR, CI"]
  AC --> TC["D05-02 Test case<br/>ca chi tiết có dữ liệu"]
  DEV --> REV["Sprint review<br/>PO chủ đầu tư chấp nhận"]
  TC --> REV
  REV --> GATE["Cổng G1…G5"]
```

Hình cho thấy ba điều. Thứ nhất, backlog không có nguồn riêng: FRS và UC là nguồn, script là cách duy nhất tạo story ban đầu, nên không có lệch giữa "điều đã duyệt" và "điều đang làm". Thứ hai, tiêu chí chấp nhận ở D02-05-01 là mức story, còn ca kiểm thử chi tiết có dữ liệu và bước ở D05-02; một story được chấp nhận khi các ca D05-02 của FR tương ứng chạy đạt. Thứ ba, sau khi nhập vào công cụ quản lý công việc, trạng thái story được theo dõi ở công cụ; tài liệu này được sinh lại ở mỗi cổng để làm đường cơ sở.

Quan hệ giữa các đối tượng truy vết như sau: một `FR` sinh đúng một `US` ban đầu; một `US` thuộc đúng một `EP`; một `UC` hiện thực một hoặc nhiều `FR` nên một `US` có thể gắn nhiều `UC`; một `US` được kiểm bằng các `TC` của `FR` gốc.

## 2. Cấu trúc backlog

Chương này định nghĩa ba cấp của backlog (epic, story, tiêu chí chấp nhận), quy ước mã và vòng đời của story trong công cụ quản lý công việc.

### 2.1. Ba cấp và quy ước mã

Backlog có ba cấp lồng nhau; mỗi cấp có mã riêng và một nguồn duy nhất trong FRS.

| Cấp | Mã | Nguồn | Ví dụ | Số lượng |
|---|---|---|---|---|
| Epic | `EP-{PH}-{chữ}`, chữ là nhóm chức năng của FRS (với FR-00 là số mục 4.n của SRS đổi thành chữ A, B…) | Tiêu đề "Nhóm X · …" ở FRS chương 6 | `EP-07-C` Nhập và xuất | 195 |
| Story | `US-{PH}-{nnn}`, `nnn` trùng số FR gốc; story tách thêm lấy từ 501 | Khối đặc tả 17 mục của FR | `US-07-021` | 1.287 |
| Tiêu chí chấp nhận | Kịch bản Gherkin gắn thẻ `@US-…`, `@FR-…`, mức ưu tiên, `@âm` cho kịch bản âm | Tiền điều kiện, Kích hoạt, Đầu ra, Hậu điều kiện, Luồng ngoại lệ của FR | `US-07-021 âm 1` | 1 dương và 1–2 âm mỗi story |

: Ba cấp của backlog, mã và nguồn

Mã `US` đã có trong hệ mã của D00-01 §3.1 với tài liệu gốc là D02-05. Mã `EP` là mã mới của tài liệu này; đề nghị bổ sung vào D00-01 ở đợt đồng bộ (chương 9). Story không bao giờ đổi số khi FR đổi tên; FR bị hủy thì story đánh dấu "Đã hủy" và giữ số, theo nguyên tắc không tái sử dụng mã của D00-01.

### 2.2. Thành phần của một story

Mỗi story có mười thành phần. Tám thành phần đầu sinh từ FR; hai thành phần cuối do đội Scrum điền khi làm việc.

| Thành phần | Nội dung | Nguồn |
|---|---|---|
| Mã, tên | `US-{PH}-{nnn}` · tên FR | FR |
| Câu chuyện | "Là {vai trò}, tôi muốn {việc}, để {lợi ích}." | Tác nhân, tên FR, Kết quả (chương 3) |
| Epic | `EP-{PH}-{chữ}` | Nhóm chức năng của FR |
| Ưu tiên, đợt | M, S, C và MVP, Đợt 2, Đợt 3, Đợt sau | "Mức ưu tiên, đợt" của FR |
| Wave | W1…W5 hoặc "Sau G5" | Wave của phân hệ (D01-02 §2.4) và đợt của FR |
| Điểm | 1, 2, 3, 5, 8; dấu `*` là đề nghị tách | Công thức chương 4 |
| Truy vết | FR, UC, REQ, LGC, màn hình, API | Truy vết, Màn hình và API của FR; "FR hiện thực" của UC |
| Tiêu chí chấp nhận | Kịch bản Gherkin | Phụ lục D02-05-01 |
| Người làm, sprint | Thành viên đội, mã sprint | Đội Scrum, khi lập kế hoạch sprint |
| Trạng thái | Theo vòng đời mục 2.3 | Công cụ quản lý công việc |

: Mười thành phần của một story và nguồn

### 2.3. Vòng đời story

Story đi qua sáu trạng thái. Hai cửa kiểm soát là DoR (trước khi vào sprint) và DoD (trước khi được coi là xong); cả hai theo D01-02 §3.6, không định nghĩa lại ở đây.

```{.mermaid caption="Vòng đời của một story trong công cụ quản lý công việc"}
stateDiagram-v2
  [*] --> MOI: sinh từ FR
  MOI --> SAN_SANG: đạt DoR ở buổi làm rõ
  MOI --> HUY: FR bị hủy
  SAN_SANG --> DANG_LAM: chọn vào sprint
  DANG_LAM --> CHO_NGHIEM_THU: đạt DoD kỹ thuật
  CHO_NGHIEM_THU --> XONG: PO chủ đầu tư chấp nhận ở sprint review
  CHO_NGHIEM_THU --> SAN_SANG: bị trả, quay lại backlog
  DANG_LAM --> SAN_SANG: hết sprint chưa xong
  XONG --> [*]
  HUY --> [*]
```

Hình nhấn mạnh hai luật của D01-02. Story chưa xong khi hết sprint trả về backlog công khai, không kéo dài sprint; story chỉ "Xong" khi PO phía chủ đầu tư chấp nhận tại sprint review, không phải khi PR được merge. Trạng thái trong công cụ dùng tên tiếng Việt như bảng dưới.

| Trạng thái | Tên trong công cụ | Ai chuyển | Điều kiện |
|---|---|---|---|
| `MOI` | Mới | Script nhập | Story vừa được tạo từ FR |
| `SAN_SANG` | Sẵn sàng | PO nhà thầu | Đạt DoR: có tiêu chí chấp nhận, đã ước lượng ≤ 8 điểm, hợp đồng API nháp trong `contracts/`, prototype màn hình được duyệt, phụ thuộc đã sẵn |
| `DANG_LAM` | Đang làm | Thành viên đội | Story được chọn trong sprint planning |
| `CHO_NGHIEM_THU` | Chờ nghiệm thu | Thành viên đội | Đạt DoD kỹ thuật: merge qua PR có review, cổng CI xanh, kiểm thử tự động cho mọi tiêu chí, đã lên TEST |
| `XONG` | Xong | PO chủ đầu tư | Chấp nhận tại sprint review, ghi vào biên bản |
| `HUY` | Đã hủy | PO chủ đầu tư | FR gốc bị hủy qua quy trình thay đổi (D01-02 chương 11) |

: Trạng thái story, người chuyển và điều kiện

## 3. Quy tắc chuyển FR thành story

Chương này nêu chính xác cách script biến khối đặc tả 17 mục của một FR thành story và tiêu chí chấp nhận. Quy tắc được viết ra để người duyệt kiểm được tính đúng, và để khi story cần sửa tay thì biết sửa ở FR chứ không sửa ở backlog.

### 3.1. Ánh xạ trường

Bảng sau nói mỗi mục của khối đặc tả FR đi vào phần nào của story, và quy tắc biến đổi văn bản tương ứng.

| Mục của FR (D00-01 §4.3) | Thành phần story | Quy tắc |
|---|---|---|
| Tên FR | Tên story, phần "tôi muốn" | Hạ chữ đầu trừ tên riêng (Keycloak, Kafka…); tên là danh từ (Dashboard, Danh sách, Bảng…) thì thêm "có" |
| Tác nhân, quyền | Phần "Là" | Vai trò đầu tiên nhận diện được theo D02-08; tác nhân là "Hệ thống" hoặc tác vụ nền thì vai trò là người hưởng lợi đầu tiên được nêu, không có thì lấy vai trò mặc định của phân hệ (bảng 3.2) và phần "tôi muốn" thêm "hệ thống" |
| Kết quả | Phần "để" | Câu đầu của mục Kết quả (góc nhìn người dùng); mục Kết quả trống thì lấy câu đầu của Mục đích |
| Mức ưu tiên, đợt | Ưu tiên, đợt, wave | Ký tự đầu là mức; đợt chuẩn hóa về MVP, Đợt 2, Đợt 3, Đợt sau ("Đ2b" là Đợt 2) |
| Tiền điều kiện | `Biết` | Câu đầu; "Không" thì thay bằng "người dùng đã đăng nhập với vai trò …" |
| Kích hoạt | `Khi` của kịch bản dương | Câu đầu |
| Đầu ra | `Thì` của kịch bản dương | Câu đầu; bắt đầu bằng mã HTTP hoặc tên trường thì thêm "hệ thống trả"; "Không" thì lấy Kết quả |
| Hậu điều kiện | `Và` | Câu đầu, bỏ nếu "Không" |
| Sự kiện phát ra | `Và sự kiện được phát` | Bỏ nếu "Không" |
| Kiểm toán | `Và nhật ký kiểm toán ghi nhận thao tác` | Chỉ khi mục bắt đầu bằng "Có" |
| Luồng ngoại lệ | Kịch bản âm | Mỗi gạch đầu dòng "điều kiện: mã lỗi (HTTP); câu thông báo" thành một kịch bản: `Khi` điều kiện, `Thì hệ thống từ chối với` mã lỗi, `Và người dùng thấy thông báo` câu trong ngoặc kép; mức M lấy hai dòng đầu, mức S, C lấy một |
| Luồng xử lý chính, luồng thay thế, sự kiện, quy tắc | Điểm | Đếm theo công thức chương 4 |
| Truy vết, Màn hình và API | Truy vết | Câu đầu, giữ nguyên mã |

: Ánh xạ từ khối đặc tả FR sang story và tiêu chí chấp nhận

### 3.2. Vai trò mặc định theo phân hệ

Khi FR do hệ thống tự chạy và không nêu người hưởng lợi, story lấy vai trò mặc định dưới đây, là vai trò chịu trách nhiệm nghiệp vụ chính của phân hệ.

| PH | Vai trò mặc định | PH | Vai trò mặc định |
|---|---|---|---|
| 00 | Quản trị tỉnh | 11 | Vận hành tỉnh |
| 01 | Quản trị tỉnh | 12 | Quản trị tỉnh |
| 02 | Chủ dịch vụ | 13 | Vận hành tỉnh |
| 03 | Vận hành tỉnh | 14 | Kỹ sư tích hợp |
| 04 | Kỹ sư tích hợp | 15 | Nhà phát triển |
| 05 | Kỹ sư tích hợp | 16 | Quản trị tỉnh |
| 06 | Cán bộ quản lý dữ liệu | 17 | Kỹ sư tích hợp |
| 07 | Cán bộ quản lý dữ liệu | 18 | Vận hành tỉnh |
| 08 | Cán bộ quản lý dữ liệu | 19 | Kế toán đối soát |
| 09 | Cán bộ ATTT | 20 | Quản trị nền tảng |
| 10 | Kỹ sư tích hợp | | |

: Vai trò mặc định trong câu chuyện khi tác nhân là hệ thống

### 3.3. Ví dụ đầy đủ

Ví dụ dưới là story `US-07-021`, sinh từ `FR-07-021` Nhập bản ghi từ Excel/CSV vào bản nháp (D02-03-PH07). Đây là story mức M có điểm thô vượt ngưỡng nên được đánh dấu đề nghị tách.

::: dac-ta
**Câu chuyện.** Là cán bộ quản lý dữ liệu, tôi muốn nhập bản ghi từ Excel/CSV vào bản nháp, để bản ghi trong tệp vào bản nháp sau khi người dùng đã thấy trước số dòng thêm, sửa, lỗi; lỗi được báo theo từng dòng và từng ô.

**Epic.** EP-07-C Nhập và xuất.

**Ưu tiên, đợt, wave.** M · MVP · W2.

**Điểm.** 8, đề nghị tách (điểm thô vượt 19: hai pha xem trước và ghi, tác vụ nền, sự kiện, nhiều ngoại lệ).

**Truy vết.** FR-07-021; LGC-DMDC-006, LGC-DMDC-007 (nhập Excel của hệ Aita); UC-07-03.

**Tiêu chí chấp nhận.** Một kịch bản dương (Biết danh mục không `NATIONAL`, có bản nháp; Khi người dùng nhập tệp, ánh xạ cột, kiểm tra rồi ghi; Thì `202` với `jobId`, sau đó trạng thái `VALIDATED` kèm số dòng hợp lệ, lỗi; Và sự kiện EVT-07-07) và hai kịch bản âm (tệp không hợp lệ: ERR-07-019; đã có tác vụ nhập đang chạy: ERR-07-020, 409), ghi đủ ở D02-05-01.

**Gợi ý tách.** (a) Pha 1 tải tệp, kiểm tra, xem trước; (b) pha 2 ghi vào bản nháp và dọn tệp tạm; (c) báo lỗi theo dòng, ô và tải tệp lỗi. Ba story tách mang số 501, 502, 503 của PH-07, cùng truy vết `FR-07-021`.
:::

Kịch bản dương của ví dụ, đúng như phụ lục và tệp `us-07.feature`:

```gherkin
@US-07-021 @FR-07-021 @M
Kịch bản: US-07-021 dương · Nhập bản ghi từ Excel/CSV vào bản nháp
  Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT` hoặc người dùng chọn tự tạo bản nháp
  Khi người dùng bấm "Nhập từ tệp" ở UI-07-05, chọn tệp ở UI-07-06, ánh xạ cột rồi bấm "Kiểm tra"; sau khi xem trước bấm "Ghi vào bản nháp"
  Thì pha 1: `202 Accepted` với `jobId`; khi xong, API-07-034 trả `status = VALIDATED` kèm `summary`
  Và pha 1: `file_object` (DD-12) và `import_job`, các dòng `import_row` được tạo; bản nháp không đổi
  Và sự kiện được phát: EVT-07-07 `{tenant}.rdm.import.completed.v1`
```

Ví dụ cho thấy giới hạn của cách sinh tự động: câu "Thì" và "Và" giữ ngôn ngữ kỹ thuật của FR (mã HTTP, tên trường), phù hợp với kiểm thử tự động nhưng khô với người dùng nghiệp vụ. PO đọc phần "Kết quả" trong câu chuyện để nắm giá trị nghiệp vụ; kiểm thử viên đọc kịch bản để viết ca.

Cách sinh tự động còn ba giới hạn đã biết, PO soát ở buổi làm rõ backlog. Thứ nhất, với FR mà tác nhân là hệ thống, vai trò trong phần "Là" là người hưởng lợi đầu tiên tìm thấy, có khi chưa sát; các trường hợp đã soát được ghi đè trong bảng `STORY_OVERRIDE` của script (hiện sáu FR: FR-00-002, 010, 011, 012, FR-07-021, FR-19-023) và PO bổ sung bảng này thay vì sửa tay backlog. Thứ hai, phần "để" lấy câu đầu của Kết quả nên đôi khi lặp ý với phần "tôi muốn" hoặc viết theo góc nhìn bên thứ ba. Thứ ba, kịch bản âm lấy từ luồng ngoại lệ; khi luồng ngoại lệ chưa có mã ERR, câu "Thì" giữ nguyên mô tả của FR (ví dụ "Keycloak hiển thị thông báo và đếm lần sai"), và kiểm thử viên đối chiếu D03-04 để bổ sung mã khi mã được cấp.

## 4. Ước lượng điểm

Điểm ban đầu giúp lập kế hoạch wave trước khi đội Scrum có mặt đủ; nó không thay planning poker. Chương này nêu công thức, phân bố kết quả và cách quy đổi sang nỗ lực để đối chiếu với D01-02.

### 4.1. Công thức điểm ban đầu

Điểm thô của một FR là tổng các yếu tố đo được từ khối đặc tả; điểm thô được quy về dãy Fibonacci theo ngưỡng.

| Yếu tố | Cách đếm | Trọng số |
|---|---|---|
| Bước luồng chính | Số bước đánh số | 1 mỗi bước |
| Ngoại lệ | Số gạch đầu dòng của Luồng ngoại lệ, tối thiểu 1 | 1 mỗi dòng |
| Sự kiện phát ra | Có sự kiện | 2 |
| Luồng thay thế | Có luồng thay thế | 1 |
| Tích hợp ngoài hoặc thành phần nền | Nhắc NDXP, PayGov, VNeID, CSDL quốc gia, SFTP, SOAP, SMTP, SMS, Keycloak, OpenBao, Argo CD, Git, Flowable, Debezium, mô hình ngôn ngữ | 2 |
| Duyệt | Luồng chính hoặc quy tắc có gửi duyệt, phê duyệt, bốn mắt | 2 |

: Yếu tố và trọng số của điểm thô

| Điểm thô | ≤ 5 | 6–8 | 9–11 | 12–15 | ≥ 16 |
|---|---|---|---|---|---|
| Điểm | 1 | 2 | 3 | 5 | 8 |

: Ngưỡng quy điểm thô sang điểm Fibonacci

DoR của D01-02 giới hạn story tối đa 8 điểm, nên điểm bị chặn ở 8. Story có điểm thô trên 19 được đánh dấu "đề nghị tách" (dấu `*` ở cột Điểm của chương 6, nhãn `de-nghi-tach` trong CSV).

### 4.2. Phân bố điểm

Bảng sau là kết quả áp công thức cho toàn bộ backlog. Phân bố lệch về 2–3 điểm là hợp lý vì phần lớn FR là thao tác CRUD có kiểm tra và kiểm toán; nhóm 8 điểm tập trung ở trình thiết kế luồng, đối soát thanh toán, nhập danh mục và quy trình duyệt.

<!-- sinh:phan-bo-diem -->

| Điểm | Số story | Tỷ lệ | Tổng điểm |
|---|---|---|---|
| 1 | 95 | 7,4% | 95 |
| 2 | 380 | 29,5% | 760 |
| 3 | 447 | 34,7% | 1341 |
| 5 | 293 | 22,8% | 1465 |
| 8 | 72 | 5,6% | 576 |

: Phân bố story theo điểm ước lượng (sinh tự động)

<!-- /sinh:phan-bo-diem -->

<!-- sinh:de-nghi-tach -->

Có **9** story điểm thô trên 19 (đã chặn trần 8 điểm) được đánh dấu "đề nghị tách" để nhóm xem lại ở buổi làm rõ backlog trước khi đưa vào sprint: US-07-015, US-07-016, US-07-021, US-07-036, US-07-037, US-07-051, US-10-008, US-10-035, US-19-023.

<!-- /sinh:de-nghi-tach -->

### 4.3. Quy đổi điểm sang nỗ lực

Để kiểm tra công thức không quá lạc quan hay bi quan, tổng điểm được đối chiếu với nỗ lực ba gói trực tiếp làm ra story của D01-02 §2.4: giao diện (1.xx.4, 50,5 người-tháng), lập trình (1.xx.5, 90 người-tháng) và kiểm thử (1.xx.6, 42 người-tháng), cộng 182,5 người-tháng. Với 21 ngày làm việc mỗi tháng, đó là khoảng 3.830 người-ngày cho 4.236 điểm, tức **1 điểm ≈ 0,9 người-ngày** làm trọn story (phân tích tại chỗ, mã, kiểm thử tự động, review). Đây là giả định GĐ-BL-01; nó cần được hiệu chỉnh bằng vận tốc thật sau ba sprint đầu W1.

Với hệ số đó, một đội 5–6 người làm 10 ngày mỗi sprint, tập trung 80% thời gian cho story (phần còn lại cho nghi thức Scrum, làm rõ backlog, sửa lỗi), có **vận tốc nền khoảng 49 điểm mỗi sprint** (giả định GĐ-BL-02).

### 4.4. Tổng hợp theo phân hệ

<!-- sinh:tong-hop-ph -->

| PH | Tên | Epic | Story | Điểm | M | S | C | Wave |
|---|---|---|---|---|---|---|---|---|
| PH-00 | Dùng chung (FR-00) | 9 | 40 | 82 | 36 | 4 | 0 | W1 |
| PH-01 | Kết nạp hệ thống thông tin | 7 | 51 | 202 | 41 | 9 | 1 | W1 |
| PH-02 | Danh mục dịch vụ | 10 | 62 | 254 | 50 | 11 | 1 | W1 |
| PH-03 | Cổng API | 7 | 59 | 212 | 47 | 11 | 1 | W1 |
| PH-04 | Lõi tích hợp và trình thiết kế luồng | 7 | 60 | 174 | 49 | 10 | 1 | W1 |
| PH-05 | Bộ điều hợp và kết nối | 8 | 62 | 212 | 54 | 7 | 1 | W1 |
| PH-06 | Dữ liệu chủ | 8 | 60 | 183 | 54 | 6 | 0 | W4–W5 |
| PH-07 | Danh mục dùng chung | 8 | 53 | 221 | 48 | 4 | 1 | W2 |
| PH-08 | Chất lượng dữ liệu | 10 | 61 | 161 | 36 | 21 | 4 | W4–W5 |
| PH-09 | Quyền riêng tư | 11 | 64 | 140 | 47 | 13 | 4 | W4 |
| PH-10 | Sự kiện | 11 | 76 | 266 | 66 | 8 | 2 | W2 |
| PH-11 | Quy trình liên thông | 10 | 66 | 147 | 48 | 16 | 2 | W4 |
| PH-12 | Định danh và phân quyền | 8 | 62 | 316 | 52 | 9 | 1 | W1 |
| PH-13 | Giám sát và kiểm toán | 8 | 61 | 216 | 52 | 8 | 1 | W1–W2 |
| PH-14 | Kết nối quốc gia | 9 | 57 | 245 | 48 | 8 | 1 | W2 |
| PH-15 | Cổng nhà phát triển | 10 | 62 | 196 | 47 | 13 | 2 | W4 |
| PH-16 | Báo cáo chỉ tiêu và sổ kiến trúc | 9 | 58 | 150 | 37 | 17 | 4 | W5 |
| PH-17 | Trợ lý AI và quản trị AI | 10 | 62 | 214 | 44 | 15 | 3 | W5 |
| PH-18 | Vận hành và xử lý lỗi | 10 | 72 | 202 | 57 | 12 | 3 | W2 |
| PH-19 | Thanh toán điện tử | 15 | 69 | 237 | 58 | 10 | 1 | W4 |
| PH-20 | Quản trị tenant và phát hành sản phẩm | 10 | 70 | 207 | 51 | 19 | 0 | W2 |
| **Cộng** |  | 195 | **1287** | **4237** | 1022 | 231 | 34 |  |

: Số epic, story, điểm và mức ưu tiên theo phân hệ (sinh tự động)

<!-- /sinh:tong-hop-ph -->

Phân hệ có nhiều điểm nhất là PH-12 (định danh, phân quyền, có nhiều tích hợp Keycloak và OPA), PH-10 (sự kiện, nhiều luồng duyệt topic) và PH-02 (vòng đời API có duyệt). PH-04 có ít điểm hơn quy mô nỗ lực của nó trong D01-02 (34 người-tháng) vì phần lớn công sức của trình thiết kế luồng nằm ở giao diện phức tạp mà công thức không đếm được; nhóm phân hệ này được đề nghị ước lượng lại bằng planning poker ngay sprint đầu W1 (Q370).

## 5. Kế hoạch phát hành theo wave

Chương này gán story vào wave và kiểm tra wave có đủ sức chứa không. Gán wave dựa trên hai thông tin: wave mà phân hệ được phát triển ở D01-02 §2.4 và đợt của từng FR.

### 5.1. Quy tắc gán wave

Script áp năm quy tắc sau theo thứ tự; quy tắc sau không ghi đè quy tắc trước.

1. Story có đợt bằng hoặc sớm hơn đợt chuẩn của phân hệ thì thuộc wave của phân hệ (ví dụ FR MVP của PH-07 thuộc W2).
2. Story có đợt muộn hơn đợt chuẩn của phân hệ thì thuộc wave của đợt đó: Đợt 2 vào W4, Đợt 3 vào W5 (ví dụ FR Đợt 3 của PH-07 vào W5).
3. Story "Đợt sau" không thuộc phạm vi v1.0, đánh dấu "Sau G5" và chỉ làm khi có quyết định nâng cấp.
4. W3 là wave thí điểm và cắt chuyển; không có story chức năng mới, chỉ có việc di trú, chạy song song, sửa lỗi tồn và phần HDSD dời từ W1–W2 (D01-02 §2.6).
5. FR-00 thuộc W1 vì là nền cho mọi phân hệ; PH-13 trải W1–W2 theo D01-02.

```{.mermaid caption="Thứ tự wave và nhóm phân hệ của từng wave"}
flowchart TB
  W1["W1 · 8 sprint<br/>FR-00, PH-01, 02, 03, 04, 05, 12, PH-13 cơ bản"]
  W2["W2 · 8 sprint<br/>PH-07, 10, 14, 18, 20, PH-13 đầy đủ"]
  W3["W3 · 6 sprint<br/>Thí điểm, di trú, cắt chuyển"]
  W4["W4 · 10 sprint<br/>PH-09, 11, 15, 19; FR Đợt 2 của phân hệ MVP; khởi đầu PH-06, 08"]
  W5["W5 · 6 sprint<br/>PH-16, 17; phần còn lại PH-06, 08; FR Đợt 3"]
  W1 --> W2 --> W3
  W2 --> W4
  W4 --> W5
```

Hình cho thấy W3 và W4 chạy song song theo D01-02 §3.2: trong khi đội thí điểm làm cắt chuyển ở tỉnh thí điểm, hai đội mới phát triển phân hệ Đợt 2. W5 nhận phần Đợt 3 và phần còn lại của PH-06, PH-08 vốn trải W4–W5.

### 5.2. Story và điểm theo wave

<!-- sinh:theo-wave -->

| Wave | Số story | Tổng điểm | Điểm mức M |
|---|---|---|---|
| W1 | 359 | 1336 | 1249 |
| W1–W2 | 59 | 210 | 189 |
| W2 | 310 | 1088 | 996 |
| W4 | 298 | 841 | 588 |
| W4–W5 | 121 | 344 | 270 |
| W5 | 135 | 406 | 266 |
| Sau G5 | 5 | 12 | 0 |

: Story và điểm theo wave phát triển (sinh tự động)

<!-- /sinh:theo-wave -->

Story của PH-06, PH-08 mang nhãn W4–W5 được chia theo thứ tự nhóm chức năng: nhóm nền (đăng ký nguồn, quy tắc) ở W4, nhóm khai thác và báo cáo ở W5; việc chia cụ thể do PO hai phía quyết định ở kế hoạch wave W4.

### 5.3. Đối chiếu sức chứa

Sức chứa của một wave là số đội phát triển nhân số sprint nhân vận tốc nền (GĐ-BL-02, 49 điểm). Số đội lấy theo D01-02 §6.3: đội giao diện được tính chung với đội backend vì story gồm cả phần giao diện.

| Wave | Đội phát triển | Sprint | Đội-sprint | Sức chứa (điểm) | Điểm cần làm | Vận tốc cần mỗi đội-sprint | Đánh giá |
|---|---|---|---|---|---|---|---|
| W1 | A, B, C | 8 | 24 | 1.176 | 1.336 + nửa W1–W2 (105) = 1.441 | 60 | Thiếu khoảng 265 điểm |
| W2 | A, B, C | 8 | 24 | 1.176 | 1.087 + nửa W1–W2 (105) = 1.192 | 50 | Thiếu nhẹ, khoảng 16 điểm |
| W4 | D, E | 10 | 20 | 980 | 841 + nửa W4–W5 (172) = 1.013 | 51 | Thiếu nhẹ, khoảng 33 điểm |
| W5 | F, nửa G | 6 | 9 | 441 | 406 + nửa W4–W5 (172) = 578 | 64 | Thiếu khoảng 137 điểm |

: Đối chiếu điểm cần làm với sức chứa theo wave

Kết quả cùng chiều với nhận định của D01-02 §2.6 rằng W1–W2 vượt sức chứa khoảng 15–20 người-tháng, nhưng thấp hơn: 265 điểm thiếu ở W1 cộng 16 điểm ở W2 tương đương khoảng 12 người-tháng theo GĐ-BL-01. W4 thiếu nhẹ 33 điểm, nằm trong sai số ước lượng. Cách xử lý theo thứ tự ưu tiên:

1. **Dời mức S của W1 sang đầu W3.** W1 có khoảng 90 điểm mức S (1.336 trừ 1.249 điểm mức M); vì W2 cũng thiếu nhẹ, dời toàn bộ sang ba sprint đầu W3 như D01-02 đã dự kiến cho phần sửa lỗi cuối.
2. **Ước lượng lại PH-04 và PH-12 ở sprint đầu W1** (Q370): hai phân hệ này chiếm khoảng một phần ba điểm W1 (434 trên 1.336); sai số ước lượng ở đây ảnh hưởng lớn nhất.
3. **Theo dõi vận tốc thật của ba sprint đầu.** Nếu vận tốc đạt từ 55 điểm (đội dùng AI agent theo D01-02 §3.8 có thể vượt mức nền), giữ phạm vi; nếu dưới 45, kích hoạt quy trình thay đổi để co mức S của PH-13 và PH-18 như D01-02 §2.6.
4. **W5 thiếu sức chứa** được xử lý bằng cách đưa đội G vào toàn thời gian sau khi tenant tỉnh thứ hai ổn định, hoặc dời story mức C, S của PH-16, PH-17 ra sau G5; quyết định ở cổng G4 (Q371).

## 6. Danh sách epic và story theo phân hệ

Chương này liệt kê toàn bộ epic và story, sinh tự động từ SRS và FRS (không sửa tay; sửa FR rồi chạy lại `sinh_backlog.py`). Mỗi phân hệ có một mục; mỗi epic có bảng story. Cột "ƯT" là mức ưu tiên M, S, C; cột "Điểm" có dấu `*` là story đề nghị tách; cột "FR; UC" ghi FR gốc và các UC hiện thực FR đó (UC thứ hai trở đi ghi số rút gọn).

<!-- sinh:danh-sach -->

### 6.1. PH-00 · Yêu cầu chức năng dùng chung (FR-00)

Phân hệ có 9 epic, 40 story, tổng 82 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-02 SRS chương 4. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-00-A · Đăng nhập, phiên và ngữ cảnh

Epic gồm 5 story, 14 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-001 | Là người dùng, tôi muốn đăng nhập một lần qua Keycloak, để truy cập bất kỳ trang nào khi chưa đăng nhập được chuyển tới trang đăng nhập của realm tenant; sau đăng nhập người dùng quay về đúng trang đã mở, kể cả bộ lọc trên URL. | M | 5 | MVP, W1 | FR-00-001 |
| US-00-002 | Là quản trị nền tảng, tôi muốn hệ thống bắt buộc xác thực hai yếu tố cho vai trò quản trị, duyệt, để người dùng có vai trò quản trị chưa đăng ký yếu tố thứ hai bị buộc đăng ký trước khi vào; người đã đăng ký phải qua yếu tố thứ hai mỗi lần đăng nhập. | M | 3 | MVP, W1 | FR-00-002 |
| US-00-003 | Là quản trị tỉnh, tôi muốn tự khóa phiên khi không thao tác, để người dùng rời máy quá thời gian cấu hình thì phải đăng nhập lại; dữ liệu đang nhập trong biểu mẫu không gửi đi mà không có phiên. | M | 2 | MVP, W1 | FR-00-003 |
| US-00-004 | Là người dùng, tôi muốn chọn và đổi tenant làm việc, để mọi màn hình hiển thị tenant hiện tại ở thanh trên. | M | 2 | MVP, W1 | FR-00-004 |
| US-00-005 | Là người dùng, tôi muốn xem và thu hồi phiên đăng nhập của mình, để người dùng thấy rõ mình đang đăng nhập ở đâu và cắt được phiên không mong muốn ngay. | S | 2 | MVP, W1 | FR-00-005 |

: Story của epic EP-00-A Đăng nhập, phiên và ngữ cảnh

#### EP-00-B · Đa tenant

Epic gồm 3 story, 5 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-010 | Là quản trị nền tảng, tôi muốn hệ thống gắn bản ghi với tenant từ ngữ cảnh xác thực, để mọi bản ghi luôn thuộc tenant của người gọi; `tenant_id` khác gửi trong thân yêu cầu bị bỏ qua hoặc từ chối `ERR-00-003`. | M | 2 | MVP, W1 | FR-00-010 |
| US-00-011 | Là quản trị nền tảng, tôi muốn hệ thống không để rò rỉ dữ liệu giữa các tenant, để người dùng và hệ thống của tenant A không thấy dấu vết nào của dữ liệu tenant B. | M | 1 | MVP, W1 | FR-00-011 |
| US-00-012 | Là quản trị nền tảng, tôi muốn truy cập liên tenant có lý do và kiểm toán, để vai trò nền tảng xem được dữ liệu cần thiết để hỗ trợ, tỉnh biết ai đã vào, khi nào, vì sao. | M | 2 | MVP, W1 | FR-00-012 |

: Story của epic EP-00-B Đa tenant

#### EP-00-C · Danh sách, tìm kiếm, lọc

Epic gồm 5 story, 10 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-020 | Là người dùng có quyền xem, tôi muốn tìm kiếm từ khóa không phân biệt hoa thường và dấu, để tìm "da nang" ra "Đà Nẵng". | M | 2 | MVP, W1 | FR-00-020 |
| US-00-021 | Là người dùng có quyền xem, tôi muốn phân trang phía máy chủ, để mọi màn danh sách phân trang phía máy chủ, mặc định 20 dòng, chọn được 10/20/50/100. | M | 2 | MVP, W1 | FR-00-021 |
| US-00-022 | Là người dùng có quyền xem, tôi muốn sắp xếp và giữ trạng thái danh sách trên URL, để mở URL đã chia sẻ cho cùng kết quả (với cùng quyền). | M | 2 | MVP, W1 | FR-00-022 |
| US-00-023 | Là người dùng có quyền xem, tôi muốn có bộ lọc nâng cao nhiều giá trị và khoảng thời gian, để bộ lọc nâng cao hỗ trợ chọn nhiều giá trị cho trường liệt kê và khoảng thời gian; kế thừa LGC-PAY-015…017. | M | 2 | MVP, W1 | FR-00-023 |
| US-00-024 | Là người dùng, tôi muốn lưu bộ lọc thường dùng, để người dùng mở lại tổ hợp lọc bằng một lần bấm. | S | 2 | MVP, W1 | FR-00-024 |

: Story của epic EP-00-C Danh sách, tìm kiếm, lọc

#### EP-00-D · Nhập và xuất dữ liệu

Epic gồm 5 story, 11 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-030 | Là người dùng, tôi muốn xuất Excel và CSV theo bộ lọc hiện tại, để tệp mở đúng tiếng Việt trên Excel, có đúng các dòng người dùng đang lọc. | M | 1 | MVP, W1 | FR-00-030 |
| US-00-031 | Là quản trị tỉnh, tôi muốn xuất lớn chạy nền, có hạn tải, để người dùng nhận tệp lớn qua thông báo, tệp tự hết hạn sau 24 giờ. | M | 2 | MVP, W1 | FR-00-031 |
| US-00-032 | Là người dùng, tôi muốn nhập tệp có xem trước, ghi tất cả hoặc không, để tệp có 1 dòng lỗi thì không dòng nào được ghi, trừ khi người dùng chọn bỏ qua dòng lỗi. | M | 5 | MVP, W1 | FR-00-032 |
| US-00-033 | Là quản trị tỉnh, tôi muốn cung cấp tệp mẫu nhập, để tải được tệp mẫu; nhập lại tệp mẫu đã điền đúng thì thành công. | M | 1 | MVP, W1 | FR-00-033 |
| US-00-034 | Là người xuất dữ liệu, tôi muốn che trường Nhạy cảm trong dữ liệu xuất, để dữ liệu xuất chứa trường mức Nhạy cảm được che, trừ khi người dùng có quyền xem đầy đủ và nêu lý do. | M | 2 | MVP, W1 | FR-00-034 |

: Story của epic EP-00-D Nhập và xuất dữ liệu

#### EP-00-E · Nhật ký kiểm toán

Epic gồm 4 story, 7 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-040 | Là người dùng, tôi muốn phạm vi thao tác phải ghi kiểm toán, để mọi thao tác thuộc danh sách đều có bản ghi kiểm toán tra cứu được. | M | 2 | MVP, W1 | FR-00-040 |
| US-00-041 | Là kiểm toán viên, tôi muốn hệ thống nội dung bắt buộc của bản ghi kiểm toán, để kiểm toán viên đọc một bản ghi là biết đủ ai, ở đâu, làm gì, với đối tượng nào, trước và sau ra sao, kết quả, lý do. | M | 2 | MVP, W1 | FR-00-041 |
| US-00-042 | Là kiểm toán viên, tôi muốn hệ thống có nhật ký không sửa, không xóa, có chuỗi băm, để nhật ký kiểm toán không sửa, không xóa được qua bất kỳ giao diện nào. | M | 2 | MVP, W1 | FR-00-042 |
| US-00-043 | Là kiểm toán viên, tôi muốn có tab "Lịch sử" trên màn chi tiết đối tượng, để mỗi màn chi tiết đối tượng có tab "Lịch sử" hiển thị nhật ký kiểm toán của đối tượng đó. | M | 1 | MVP, W1 | FR-00-043 |

: Story của epic EP-00-E Nhật ký kiểm toán

#### EP-00-F · Thao tác và trạng thái

Epic gồm 5 story, 10 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-050 | Là người dùng, tôi muốn xác nhận và lý do cho thao tác phá hủy, ảnh hưởng vận hành, để người dùng không xóa, tạm dừng, thu hồi, hoàn tiền được chỉ bằng một lần bấm nhầm. | M | 2 | MVP, W1 | FR-00-050 |
| US-00-051 | Là quản trị tỉnh, tôi muốn xóa mềm và khôi phục, để đối tượng xóa nhầm khôi phục được bởi quản trị trong thời hạn lưu giữ. | M | 3 | MVP, W1 | FR-00-051 |
| US-00-052 | Là người dùng, tôi muốn phát hiện xung đột khi hai người sửa cùng đối tượng, để hai người sửa cùng một đối tượng: người lưu sau nhận cảnh báo xung đột, xem khác biệt và chọn ghi đè hoặc tải lại. | M | 2 | MVP, W1 | FR-00-052 |
| US-00-053 | Là người dùng, tôi muốn có nhãn trạng thái thống nhất và hành động theo trạng thái, để đối tượng có vòng đời hiển thị trạng thái bằng nhãn màu thống nhất theo design system và chỉ hiện các hành động hợp lệ ở trạng thái hiện tại. | M | 1 | MVP, W1 | FR-00-053 |
| US-00-054 | Là người dùng, tôi muốn thao tác chạy lâu chạy nền, có tiến độ, để thao tác chạy lâu (trên 3 giây) chạy nền, hiển thị tiến độ và cho phép rời màn hình. | M | 2 | MVP, W1 | FR-00-054 |

: Story của epic EP-00-F Thao tác và trạng thái

#### EP-00-G · Thông báo

Epic gồm 3 story, 6 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-060 | Là người dùng, tôi muốn có trung tâm thông báo trong ứng dụng, để hệ thống có trung tâm thông báo trong ứng dụng, thông báo việc chờ duyệt, kết quả tác vụ nền, cảnh báo. | M | 2 | MVP, W1 | FR-00-060 |
| US-00-061 | Là người dùng, tôi muốn chọn kênh nhận theo loại thông báo, để người dùng nhận đúng loại thông báo qua đúng kênh mình chọn. | S | 2 | MVP, W1 | FR-00-061 |
| US-00-062 | Là quản trị tỉnh, tôi muốn hệ thống thư thông báo chỉ chứa liên kết, không chứa dữ liệu, để người nhận biết có việc và vào ứng dụng để xem chi tiết. | M | 2 | MVP, W1 | FR-00-062 |

: Story của epic EP-00-G Thông báo

#### EP-00-H · Duyệt

Epic gồm 3 story, 7 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-070 | Là người dùng, tôi muốn có hộp "Việc của tôi" tổng hợp từ mọi phân hệ, để người duyệt thấy đủ mọi việc chờ mình ở một chỗ; số đếm trên sidebar khớp số việc ở tab "Chờ tôi". | M | 2 | MVP, W1 | FR-00-070 |
| US-00-071 | Là người tạo yêu cầu, tôi muốn nguyên tắc bốn mắt: người tạo không tự duyệt, để người tạo không được tự duyệt yêu cầu của mình (nguyên tắc bốn mắt) với các loại duyệt được đánh dấu, cả trên giao diện và API. | M | 2 | MVP, W1 | FR-00-071 |
| US-00-072 | Là người duyệt, tôi muốn ý kiến bắt buộc khi duyệt, lý do bắt buộc khi từ chối, để mỗi lần duyệt hoặc từ chối đều có ý kiến; từ chối có lý do mà người tạo đọc được. | M | 3 | MVP, W1 | FR-00-072 |

: Story của epic EP-00-H Duyệt

#### EP-00-I · Lỗi và trợ giúp

Epic gồm 7 story, 12 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-00-080 | Là người dùng, tôi muốn có thông báo lỗi tiếng Việt, có mã lỗi và mã truy vết, để thông báo lỗi trên giao diện bằng tiếng Việt, nói rõ điều gì sai và cách khắc phục; kèm mã lỗi và mã truy vết để báo hỗ trợ. | M | 1 | MVP, W1 | FR-00-080 |
| US-00-081 | Là người dùng, tôi muốn hiển thị lỗi kiểm tra hợp lệ tại trường, để lỗi kiểm tra hợp lệ biểu mẫu hiển thị ngay tại trường, không chỉ ở đầu trang. | M | 2 | MVP, W1 | FR-00-081 |
| US-00-082 | Là người dùng, tôi muốn trợ giúp theo ngữ cảnh liên kết tới HDSD, để người dùng đọc được hướng dẫn đúng màn đang làm. | S | 1 | MVP, W1 | FR-00-082 |
| US-00-090 | Là quản trị tỉnh, tôi muốn di trú dữ liệu của hệ cũ, để dữ liệu của các nhóm trên có mặt ở Datahub, kèm báo cáo đối chiếu để xác nhận đủ. | M | 2 | MVP, W1 | FR-00-090 |
| US-00-091 | Là quản trị tỉnh, tôi muốn sửa lỗi thiết kế dữ liệu cũ khi di trú, để dữ liệu ở hệ mới đúng kiểu: số tiền không tràn, thời điểm có múi giờ, thuộc tính liên kết bằng khóa. | M | 2 | MVP, W1 | FR-00-091 |
| US-00-092 | Là quản trị tỉnh, tôi muốn có báo cáo đối chiếu sau mỗi lần di trú, để mỗi lần di trú có báo cáo đối chiếu số lượng và tổng kiểm tra giữa nguồn và đích. | M | 2 | MVP, W1 | FR-00-092 |
| US-00-093 | Là quản trị tỉnh, tôi muốn không di trú nguyên trạng thông tin xác thực, để thông tin xác thực trong hệ cũ không được di trú nguyên trạng; mọi thông tin xác thực dùng ở hệ mới được cấp lại và lưu trong kho bí mật. | M | 2 | MVP, W1 | FR-00-093 |

: Story của epic EP-00-I Lỗi và trợ giúp

### 6.2. PH-01 · Kết nạp hệ thống thông tin

Phân hệ có 7 epic, 51 story, tổng 202 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-03-PH01 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-01-A · Hồ sơ HTTT và đầu mối

Epic gồm 10 story, 31 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-001 | Là cán bộ đầu mối của tổ chức, tôi muốn liệt kê, tìm kiếm, lọc HTTT thành viên, để người dùng thấy đúng HTTT mình được phép xem, với cảnh báo cần xử lý nổi lên đầu. | M | 2 | MVP, W1 | FR-01-001; UC-01-01 |
| US-01-002 | Là cán bộ đầu mối của tổ chức, tôi muốn xem chi tiết HTTT thành viên, để người dùng nắm được tình trạng HTTT và biết bước tiếp theo. | M | 3 | MVP, W1 | FR-01-002; UC-01-01 |
| US-01-003 | Là cán bộ đầu mối của tổ chức, tôi muốn tạo hồ sơ kết nạp nháp, để cán bộ đầu mối có hồ sơ nháp mang số hồ sơ để tra cứu và để nhắc tới khi trao đổi với đơn vị vận hành. | M | 5 | MVP, W1 | FR-01-003; UC-01-02 |
| US-01-004 | Là cán bộ đầu mối của tổ chức, tôi muốn sửa hồ sơ nháp, tự lưu, để người dùng có thể đóng trình duyệt giữa chừng và quay lại điền tiếp đúng chỗ. | M | 3 | MVP, W1 | FR-01-004; UC-01-02 |
| US-01-005 | Là cán bộ đầu mối của tổ chức, tôi muốn đính kèm, xem, xóa tài liệu hồ sơ, để tài liệu nằm trong hồ sơ, người thẩm định mở xem trong cùng màn hình. | M | 3 | MVP, W1 | FR-01-005; UC-01-04 |
| US-01-006 | Là cán bộ đầu mối của tổ chức, tôi muốn khai hồ sơ năng lực kỹ thuật và đề xuất nhóm HTTT, để người dùng thấy nhóm HTTT được đề xuất và biết vì sao. | M | 2 | MVP, W1 | FR-01-006; UC-01-03 |
| US-01-007 | Là cán bộ đầu mối của tổ chức, tôi muốn khai nhu cầu khai thác kèm căn cứ pháp lý, để người dùng có danh sách nhu cầu rõ ràng, dòng thiếu căn cứ nổi lên màu đỏ trước khi nộp. | M | 3 | MVP, W1 | FR-01-007; UC-01-04 |
| US-01-008 | Là cán bộ đầu mối của tổ chức, tôi muốn quản lý đầu mối liên hệ của HTTT, để HTTT luôn có đầu mối kỹ thuật còn hoạt động, danh bạ cập nhật. | M | 5 | MVP, W1 | FR-01-008; UC-01-05 |
| US-01-009 | Là cán bộ đầu mối của tổ chức, tôi muốn xóa hồ sơ nháp và rút hồ sơ đã nộp, để hồ sơ không còn chiếm chỗ ở hàng đợi thẩm định; lịch sử thẩm định vẫn còn. | S | 3 | MVP, W1 | FR-01-009; UC-01-07 |
| US-01-010 | Là người dùng, tôi muốn cung cấp mẫu văn bản và hướng dẫn kết nạp, để đơn vị có mẫu đúng thể thức để soạn văn bản đề nghị. | S | 2 | MVP, W1 | FR-01-010; UC-01-02 |

: Story của epic EP-01-A Hồ sơ HTTT và đầu mối

#### EP-01-B · Kiểm tra, nộp và thẩm định

Epic gồm 9 story, 39 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-011 | Là cán bộ đầu mối của tổ chức, tôi muốn kiểm tra hợp lệ hồ sơ trước khi nộp, để người nộp biết chính xác phải sửa gì, hỏi ai, trước khi nộp. | M | 3 | MVP, W1 | FR-01-011; UC-01-06 |
| US-01-012 | Là cán bộ đầu mối của tổ chức, tôi muốn nộp hồ sơ kết nạp, để đơn vị thấy hồ sơ ở trạng thái "Đang thẩm định" cùng hạn dự kiến; người thẩm định nhận việc. | M | 5 | MVP, W1 | FR-01-012; UC-01-06 |
| US-01-013 | Là kỹ sư tích hợp, tôi muốn thẩm định kỹ thuật và xác nhận nhóm HTTT, để hồ sơ có phương án kỹ thuật rõ ràng; PH-05 biết loại bộ điều hợp cần xây. | M | 5 | MVP, W1 | FR-01-013; UC-01-09 |
| US-01-014 | Là quản trị tỉnh, tôi muốn thẩm định căn cứ pháp lý và ATTT theo từng mục, để hồ sơ có kết luận từng mục; người phê duyệt thấy trần phạm vi sẽ được cấp. | M | 8 | MVP, W1 | FR-01-014; UC-01-10 |
| US-01-015 | Là người thẩm định kỹ thuật, tôi muốn đánh giá tác động tới hạn mức dữ liệu quốc gia, để người thẩm định và người phê duyệt biết kết nạp HTTT này có rủi ro cạn hạn mức hay không. | S | 2 | MVP, W1 | FR-01-015; UC-01-09 |
| US-01-016 | Là quản trị tỉnh, tôi muốn phân công, theo dõi hạn thẩm định, tham vấn, để mọi hồ sơ có người phụ trách và hạn; hồ sơ quá hạn nổi lên cho TA xử lý. | M | 5 | MVP, W1 | FR-01-016; UC-01-08 |
| US-01-017 | Là quản trị tỉnh, tôi muốn trả bổ sung và nộp lại hồ sơ, để đơn vị biết chính xác cần bổ sung gì và ở đâu. | M | 3 | MVP, W1 | FR-01-017; UC-01-11 |
| US-01-018 | Là quản trị tỉnh, tôi muốn phê duyệt hoặc từ chối kết nạp, để HTTT được duyệt và việc cấp định danh bắt đầu ngay, hoặc đơn vị nhận thông báo từ chối kèm lý do. | M | 5 | MVP, W1 | FR-01-018; UC-01-12 |
| US-01-019 | Là cán bộ đầu mối của tổ chức, tôi muốn theo dõi tiến độ hồ sơ, để đơn vị tự theo dõi hồ sơ mà không cần hỏi. | S | 3 | MVP, W1 | FR-01-019; UC-01-07 |

: Story của epic EP-01-B Kiểm tra, nộp và thẩm định

#### EP-01-C · Định danh ứng dụng và bàn giao

Epic gồm 9 story, 50 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-020 | Là quản trị tỉnh, tôi muốn hệ thống cấp định danh SANDBOX sau phê duyệt (saga), để HTTT có định danh SANDBOX trong không quá 5 phút kể từ lúc phê duyệt (p95); đầu mối nhận thông báo. | M | 8 | MVP, W1 | FR-01-020; UC-01-13 |
| US-01-021 | Là cán bộ đầu mối của tổ chức, tôi muốn đăng ký khóa công khai hoặc yêu cầu ký chứng thư, để HTTT có khóa hoặc chứng thư để xác thực; Datahub không bao giờ có khóa riêng. | M | 8 | MVP, W1 | FR-01-021; UC-01-14 |
| US-01-022 | Là quản trị tỉnh, tôi muốn bàn giao thông tin xác thực một lần, để đầu mối nhận được thông tin kết nối đầy đủ qua kênh an toàn; không còn bản sao nào đọc lại được. | M | 8 | MVP, W1 | FR-01-022; UC-01-15 |
| US-01-023 | Là quản trị tỉnh, tôi muốn kiểm thử kết nối ở SANDBOX, để cả đơn vị và quản trị tỉnh thấy HTTT đã kết nối được chưa, và nếu chưa thì sửa gì. | M | 3 | MVP, W1 | FR-01-023; UC-01-16 |
| US-01-024 | Là quản trị tỉnh, tôi muốn kích hoạt môi trường thật (PRODUCTION), để HTTT đã được kết nạp chính thức; đầu mối nhận định danh môi trường thật. | M | 5 | MVP, W1 | FR-01-024; UC-01-17 |
| US-01-025 | Là quản trị tỉnh, tôi muốn xoay vòng thông tin xác thực, để HTTT nhận thông tin mới và đổi dần, không đứt kết nối. | M | 8 | MVP, W1 | FR-01-025; UC-01-18 |
| US-01-026 | Là quản trị tỉnh, tôi muốn thu hồi định danh ứng dụng, để định danh không dùng được trong không quá 60 giây; người dùng nhận xác nhận. | M | 5 | MVP, W1 | FR-01-026; UC-01-19 |
| US-01-027 | Là quản trị tỉnh, tôi muốn hệ thống nhắc hạn và tự hết hạn định danh, để đầu mối biết trước khi định danh hết hạn; định danh quá hạn không còn dùng được. | M | 3 | MVP, W1 | FR-01-027; UC-01-19 |
| US-01-028 | Là cán bộ đầu mối của tổ chức, tôi muốn xem danh sách định danh của HTTT, để người dùng nắm tình trạng định danh và hạn dùng. | M | 2 | MVP, W1 | FR-01-028; UC-01-19 |

: Story của epic EP-01-C Định danh ứng dụng và bàn giao

#### EP-01-D · Vòng đời thành viên

Epic gồm 10 story, 46 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-029 | Là quản trị tỉnh, tôi muốn tạm ngừng HTTT, để HTTT không gọi được Datahub trong không quá 60 giây; đơn vị nhận thông báo và lý do. | M | 5 | MVP, W1 | FR-01-029; UC-01-20 |
| US-01-030 | Là quản trị tỉnh, tôi muốn khôi phục HTTT, để HTTT hoạt động trở lại trong không quá 60 giây. | M | 5 | MVP, W1 | FR-01-030; UC-01-20 |
| US-01-031 | Là quản trị tỉnh, tôi muốn chấm dứt tư cách thành viên, để tư cách thành viên chấm dứt; mã HTTT không dùng lại. | M | 8 | MVP, W1 | FR-01-031; UC-01-21 |
| US-01-032 | Là cán bộ ATTT, tôi muốn thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT, để HTTT bị cắt trong không quá 60 giây; có người thứ hai chịu trách nhiệm sau cùng. | M | 8 | MVP, W1 | FR-01-032; UC-01-22 |
| US-01-033 | Là quản trị tỉnh, tôi muốn phân tích tác động phụ thuộc trước khi tạm ngừng, chấm dứt, để người dùng biết tác động trước khi bấm xác nhận. | M | 2 | MVP, W1 | FR-01-033; UC-01-20, 01-21 |
| US-01-034 | Là cán bộ đầu mối của tổ chức, tôi muốn đề nghị thay đổi hồ sơ HTTT đã kết nạp theo mức duyệt, để hồ sơ cập nhật hoặc yêu cầu chờ người duyệt; người sửa biết mức duyệt trước khi gửi. | S | 5 | MVP, W1 | FR-01-034; UC-01-23 |
| US-01-035 | Là cán bộ đầu mối của tổ chức, tôi muốn đề nghị mở rộng trần phạm vi khai thác, để trần phạm vi chỉ mở rộng sau khi có kết luận pháp lý cho từng mục mới. | M | 3 | MVP, W1 | FR-01-035; UC-01-24 |
| US-01-036 | Là quản trị tỉnh, tôi muốn hệ thống tự tạm ngừng định danh không hoạt động, để định danh bị bỏ quên không còn dùng được; đầu mối được báo trước. | S | 3 | Đợt 2, W4 | FR-01-036; UC-01-25 |
| US-01-037 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ trạng thái HTTT tới phân hệ khác, để các phân hệ có cùng một bức tranh về HTTT; tạm ngừng ở PH-01 lan xuống không cần thao tác tay. | M | 5 | MVP, W1 | FR-01-037; UC-01-26 |
| US-01-038 | Là quản trị tỉnh, tôi muốn hệ thống cung cấp bản sao đọc HTTT cho phân hệ khác, để phân hệ khác có bản sao HTTT đáng tin cậy, cập nhật theo sự kiện. | M | 2 | MVP, W1 | FR-01-038; UC-01-26 |

: Story của epic EP-01-D Vòng đời thành viên

#### EP-01-E · Rà soát quyền định kỳ

Epic gồm 6 story, 16 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-039 | Là quản trị tỉnh, tôi muốn mở kỳ rà soát quyền định kỳ, để kỳ rà soát có danh sách mục rõ ràng, bắt đầu theo dõi. | M | 3 | MVP, W1 | FR-01-039; UC-01-27 |
| US-01-040 | Là quản trị tỉnh, tôi muốn hệ thống tổng hợp mức sử dụng từng phạm vi, để người rà soát có bảng sử dụng thực tế từng phạm vi. | M | 2 | MVP, W1 | FR-01-040; UC-01-27 |
| US-01-041 | Là quản trị tỉnh, tôi muốn gửi xác nhận cho đơn vị chủ quản và theo dõi phản hồi, để đơn vị chủ quản xác nhận hoặc thu hẹp quyền; không phản hồi cũng có đề xuất xử lý. | M | 3 | MVP, W1 | FR-01-041; UC-01-28 |
| US-01-042 | Là quản trị tỉnh, tôi muốn xử lý kết quả rà soát: thu hẹp, thu hồi phạm vi, để quyền không còn cần được thu hồi, có bằng chứng. | M | 3 | MVP, W1 | FR-01-042; UC-01-29 |
| US-01-043 | Là quản trị tỉnh, tôi muốn hệ thống kiểm tra hiệu lực căn cứ pháp lý, để không còn quyền khai thác dựa trên văn bản hết hiệu lực. | M | 3 | MVP, W1 | FR-01-043; UC-01-27 |
| US-01-044 | Là quản trị tỉnh, tôi muốn có báo cáo rà soát quyền, để có bằng chứng tuân thủ để nộp thanh tra. | S | 2 | Đợt 2, W4 | FR-01-044; UC-01-29 |

: Story của epic EP-01-E Rà soát quyền định kỳ

#### EP-01-F · Danh bạ đầu mối

Epic gồm 3 story, 7 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-045 | Là quản trị tỉnh, tôi muốn tra cứu danh bạ đầu mối trong phạm vi cơ quan nhà nước, để cán bộ tìm được người cần liên hệ; thông tin chỉ trong phạm vi cơ quan nhà nước của tỉnh. | M | 2 | MVP, W1 | FR-01-045; UC-01-30 |
| US-01-046 | Là quản trị tỉnh, tôi muốn hệ thống cảnh báo tổ chức thiếu đầu mối và nhắc cập nhật, để quản trị tỉnh thấy ngay tổ chức nào không còn người liên hệ; danh bạ luôn cập nhật. | M | 3 | MVP, W1 | FR-01-046; UC-01-31 |
| US-01-047 | Là quản trị tỉnh, tôi muốn xuất danh bạ đầu mối, để có tệp danh bạ, kèm bằng chứng ai xuất và vì sao. | C | 2 | Đợt 2, W4 | FR-01-047; UC-01-30 |

: Story của epic EP-01-F Danh bạ đầu mối

#### EP-01-G · Di trú và quản trị

Epic gồm 4 story, 13 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-01-048 | Là quản trị tỉnh, tôi muốn nhập HTTT từ hệ cũ, để hồ sơ nháp cho từng HTTT hệ cũ đã sẵn sàng để đơn vị hoàn tất; không bí mật nào được mang sang. | M | 5 | MVP, W1 | FR-01-048; UC-01-32 |
| US-01-049 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để tenant vận hành theo quy chế riêng, trong khuôn khổ an toàn. | M | 3 | MVP, W1 | FR-01-049; UC-01-33 |
| US-01-050 | Là quản trị tỉnh, tôi muốn xuất danh sách HTTT thành viên, để có tệp danh sách HTTT theo bộ lọc, không lộ dữ liệu nhạy cảm. | S | 2 | MVP, W1 | FR-01-050; UC-01-01 |
| US-01-051 | Là quản trị tỉnh, tôi muốn thống kê kết nạp và thời gian xử lý, để lãnh đạo thấy kết nạp có đạt mục tiêu 5 ngày làm việc không và nút thắt ở đâu. | S | 3 | Đợt 2, W4 | FR-01-051; UC-01-34 |

: Story của epic EP-01-G Di trú và quản trị

### 6.3. PH-02 · Danh mục dịch vụ

Phân hệ có 10 epic, 62 story, tổng 254 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-03-PH02 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-02-A · Danh mục và tra cứu

Epic gồm 9 story, 24 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-001 | Là người dùng có quyền xem, tôi muốn liệt kê API trong danh mục, lọc, sắp xếp, để người dùng thấy danh sách API của tỉnh với những mục cần chú ý nổi lên trên, lọc được theo mọi tiêu chí thường dùng. | M | 2 | MVP, W1 | FR-02-001; UC-02-01 |
| US-02-002 | Là người dùng có quyền xem, tôi muốn xem chi tiết API, để người dùng nắm được toàn bộ tình trạng một API và biết mình làm được gì tiếp theo. | M | 3 | MVP, W1 | FR-02-002; UC-02-01 |
| US-02-003 | Là người dùng có quyền xem, tôi muốn tìm kiếm toàn văn danh mục, để người dùng tìm được dịch vụ mong muốn chỉ với vài từ khóa, kể cả khi gõ không dấu. | M | 2 | MVP, W1 | FR-02-003; UC-02-01 |
| US-02-004 | Là HTTT khai thác, tôi muốn cung cấp danh mục cho HTTT khai thác và cổng nhà phát triển theo mức hiển thị, để bên khai thác có danh mục dịch vụ luôn cập nhật mà không phải hỏi từng đơn vị. | M | 3 | MVP, W1 | FR-02-004; UC-02-02 |
| US-02-005 | Là người dùng có quyền xem, tôi muốn xem đường dẫn sử dụng và mẫu gọi API, để bên khai thác sao chép được lệnh gọi đúng, có đủ tiêu đề và phương thức xác thực. | M | 2 | MVP, W1 | FR-02-005; UC-02-01 |
| US-02-006 | Là người dùng có quyền xem, tôi muốn tải đặc tả OpenAPI đã công bố, để bên khai thác có tệp đặc tả đúng phiên bản, dùng ngay với công cụ sinh mã. | M | 2 | MVP, W1 | FR-02-006; UC-02-01 |
| US-02-007 | Là chủ dịch vụ, tôi muốn phân loại và gắn thẻ API, để API nằm đúng nhóm, đúng mức phân loại, tìm kiếm và lọc được. | M | 5 | MVP, W1 | FR-02-007; UC-02-03 |
| US-02-008 | Là quản trị tỉnh, tôi muốn quản lý bộ phân loại và thẻ, để toàn tỉnh dùng một bộ nhóm nghiệp vụ thống nhất. | S | 3 | MVP, W1 | FR-02-008; UC-02-03 |
| US-02-009 | Là người dùng có quyền xem, tôi muốn hiển thị dịch vụ sự kiện (topic) trong danh mục, để người dùng tìm thấy topic sự kiện của tỉnh cùng chỗ với các API. | S | 2 | Đợt 2, W4 | FR-02-009; UC-02-04 |

: Story của epic EP-02-A Danh mục và tra cứu

#### EP-02-B · Đăng ký API và nạp đặc tả

Epic gồm 6 story, 28 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-010 | Là chủ dịch vụ, tôi muốn đăng ký API mới bằng trình hướng dẫn, để chủ dịch vụ có một API ở bản nháp với đặc tả đã được kiểm tra, sẵn sàng khai backend, gói rồi gửi duyệt. | M | 8 | MVP, W1 | FR-02-010; UC-02-05 |
| US-02-011 | Là chủ dịch vụ, tôi muốn nạp đặc tả OpenAPI từ tệp, nội dung dán hoặc URL, để đặc tả nằm trong phiên bản nháp, danh sách thao tác hiện ra, lỗi nếu có được chỉ rõ vị trí. | M | 5 | MVP, W1 | FR-02-011; UC-02-05 |
| US-02-012 | Là chủ dịch vụ, tôi muốn hệ thống đồng bộ lại đặc tả từ URL nguồn, phát hiện thay đổi, để chủ dịch vụ được báo khi đặc tả nguồn đổi và quyết định áp dụng hay không. | S | 3 | MVP, W1 | FR-02-012; UC-02-08 |
| US-02-013 | Là chủ dịch vụ, tôi muốn hệ thống tự đăng ký API từ luồng REST của PH-04, để luồng REST của PH-04 xuất hiện trong danh mục như một API, đi cùng quy trình công bố như mọi API. | M | 5 | MVP, W1 | FR-02-013; UC-02-09 |
| US-02-014 | Là chủ dịch vụ, tôi muốn sửa thông tin API và đặc tả khi còn bản nháp, để thông tin API được cập nhật; người dùng biết trường nào không sửa được và lý do. | M | 5 | MVP, W1 | FR-02-014; UC-02-05 |
| US-02-015 | Là người dùng có quyền xem, tôi muốn cung cấp mẫu đặc tả và quy ước viết API, để chủ dịch vụ có mẫu đúng quy ước để bắt đầu. | S | 2 | MVP, W1 | FR-02-015; UC-02-05 |

: Story của epic EP-02-B Đăng ký API và nạp đặc tả

#### EP-02-C · Kiểm tra đặc tả

Epic gồm 6 story, 16 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-016 | Là chủ dịch vụ, tôi muốn hệ thống kiểm tra đặc tả lớp 1: chuẩn OpenAPI 3.1, để chủ dịch vụ biết đặc tả có đúng chuẩn không và sửa đúng vị trí. | M | 3 | MVP, W1 | FR-02-016; UC-02-06 |
| US-02-017 | Là chủ dịch vụ, tôi muốn hệ thống kiểm tra đặc tả lớp 2: quy ước nền tảng, để chủ dịch vụ thấy ngay đặc tả thiếu gì theo quy ước và cách sửa; người duyệt thấy mức chất lượng của đặc tả. | M | 3 | MVP, W1 | FR-02-017; UC-02-06 |
| US-02-018 | Là chủ dịch vụ, tôi muốn hệ thống quét bí mật và dữ liệu cá nhân thật trong đặc tả, để đặc tả được công bố chắc chắn không chứa khóa hay dữ liệu cá nhân thật ở phần ví dụ. | M | 3 | MVP, W1 | FR-02-018; UC-02-07 |
| US-02-019 | Là chủ dịch vụ, tôi muốn kiểm tra đặc tả không lưu (xem trước khi gõ), để chủ dịch vụ sửa đặc tả ngay trên trình soạn thảo với kết quả kiểm tra tức thì. | M | 2 | MVP, W1 | FR-02-019; UC-02-06 |
| US-02-020 | Là chủ dịch vụ, tôi muốn hệ thống phát hiện API trùng chức năng, để người duyệt thấy dịch vụ tương tự đã có và quyết định có gom lại hay không. | S | 2 | MVP, W1 | FR-02-020; UC-02-07 |
| US-02-021 | Là quản trị nền tảng, tôi muốn quản lý bộ luật kiểm tra quy ước, để tenant có bộ luật kiểm tra vừa chặt vừa phù hợp, không phải chờ bản phát hành. | S | 3 | MVP, W1 | FR-02-021; UC-02-38 |

: Story của epic EP-02-C Kiểm tra đặc tả

#### EP-02-D · Backend, đường dẫn và khung route

Epic gồm 5 story, 18 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-022 | Là chủ dịch vụ, tôi muốn khai báo backend của API, để API có ít nhất một backend sẵn sàng để thử và công bố. | M | 5 | MVP, W1 | FR-02-022; UC-02-11 |
| US-02-023 | Là chủ dịch vụ, tôi muốn có cấu hình cân bằng tải, thời gian chờ, thử lại, kiểm tra sức khỏe backend, để gateway sẽ chia tải và loại backend hỏng theo đúng cấu hình đã chọn. | M | 3 | MVP, W1 | FR-02-023; UC-02-11 |
| US-02-024 | Là chủ dịch vụ, tôi muốn quản lý context-path và kiểm tra trùng, để mỗi phiên bản có địa chỉ công bố duy nhất, nhất quán toàn tỉnh. | M | 3 | MVP, W1 | FR-02-024; UC-02-05 |
| US-02-025 | Là chủ dịch vụ, tôi muốn xem sức khỏe backend, để người dùng biết ngay backend nào đang hỏng và từ lúc nào. | S | 2 | MVP, W1 | FR-02-025; UC-02-11 |
| US-02-026 | Là chủ dịch vụ, tôi muốn sinh khung route cho PH-04 từ đặc tả, để kỹ sư tích hợp nhận luồng nháp có sẵn khung chuẩn, chỉ còn điền logic riêng. | M | 5 | MVP, W1 | FR-02-026; UC-02-10 |

: Story của epic EP-02-D Backend, đường dẫn và khung route

#### EP-02-E · Gói sử dụng

Epic gồm 7 story, 29 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-027 | Là chủ dịch vụ, tôi muốn tạo gói sử dụng: thông tin và điều kiện truy cập, để chủ dịch vụ có gói nháp gắn với phiên bản API, sẵn sàng khai xác thực và hạn mức. | M | 5 | MVP, W1 | FR-02-027; UC-02-12 |
| US-02-028 | Là chủ dịch vụ, tôi muốn chọn kiểu xác thực của gói, để gói có kiểu xác thực đúng với mức nhạy cảm của dữ liệu. | M | 3 | MVP, W1 | FR-02-028; UC-02-12 |
| US-02-029 | Là chủ dịch vụ, tôi muốn khai báo hạn mức và đường dẫn cho phép của gói, để gói có hạn mức và phạm vi đường dẫn rõ ràng, sẵn sàng để PH-03 thực thi. | M | 5 | MVP, W1 | FR-02-029; UC-02-12 |
| US-02-030 | Là chủ dịch vụ, tôi muốn công bố gói (STAGING sang PUBLISHED), để gói đã công bố, HTTT có thể đăng ký sử dụng theo gói đó. | M | 5 | MVP, W1 | FR-02-030; UC-02-13 |
| US-02-031 | Là chủ dịch vụ, tôi muốn ngừng khuyến nghị gói, để gói không nhận đăng ký mới, người đang dùng được báo và có thời gian chuyển. | M | 5 | MVP, W1 | FR-02-031; UC-02-14 |
| US-02-032 | Là chủ dịch vụ, tôi muốn đóng gói, để gói không còn trong danh sách hoạt động; lịch sử giữ lại. | M | 3 | MVP, W1 | FR-02-032; UC-02-14 |
| US-02-033 | Là chủ dịch vụ, tôi muốn sao chép gói sang phiên bản mới, để phiên bản mới có sẵn các gói đã quen dùng, chỉ cần rà lại. | S | 3 | MVP, W1 | FR-02-033; UC-02-14 |

: Story của epic EP-02-E Gói sử dụng

#### EP-02-F · Vòng đời, duyệt và phiên bản

Epic gồm 12 story, 61 điểm (11 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-034 | Là chủ dịch vụ, tôi muốn gửi duyệt công bố API, để hồ sơ đã nằm trong hộp việc của người duyệt, nội dung được khóa. | M | 8 | MVP, W1 | FR-02-034; UC-02-15 |
| US-02-035 | Là người duyệt dịch vụ, tôi muốn duyệt hoặc từ chối công bố (bốn mắt), để hồ sơ được quyết định có người thứ hai chịu trách nhiệm; người gửi nhận thông báo kèm ý kiến. | M | 5 | MVP, W1 | FR-02-035; UC-02-16 |
| US-02-036 | Là chủ dịch vụ, tôi muốn hệ thống công bố API ra gateway và danh mục, để API gọi được qua cổng ở địa chỉ công bố và xuất hiện trong danh mục; chủ dịch vụ nhận thông báo. | M | 5 | MVP, W1 | FR-02-036; UC-02-15, 02-16 |
| US-02-037 | Là cán bộ ATTT, tôi muốn tạm ngừng và tiếp tục API, để API bị chặn (hoặc phục hồi) trong vòng 30 giây, bên khai thác nhận thông báo. | M | 5 | MVP, W1 | FR-02-037; UC-02-17 |
| US-02-038 | Là chủ dịch vụ, tôi muốn ngừng khuyến nghị API có lộ trình, để bên khai thác biết API sẽ ngừng, ngày nào, chuyển sang đâu; mỗi lần gọi đều nhận cảnh báo trong tiêu đề phản hồi. | M | 5 | MVP, W1 | FR-02-038; UC-02-19 |
| US-02-039 | Là chủ dịch vụ, tôi muốn ngừng hẳn API, để phiên bản kết thúc an toàn, không ai bị ngắt bất ngờ, hồ sơ được giữ. | M | 5 | MVP, W1 | FR-02-039; UC-02-20 |
| US-02-040 | Là chủ dịch vụ, tôi muốn xóa API, để API biến khỏi danh mục, lịch sử vẫn tra cứu được bởi TA, kiểm toán viên. | M | 5 | MVP, W1 | FR-02-040; UC-02-20 |
| US-02-041 | Là chủ dịch vụ, tôi muốn đặt mức hiển thị, công bố và gỡ khỏi cổng nhà phát triển, để API hiển thị đúng đối tượng; cổng nhà phát triển phản ánh trong vài giây. | M | 5 | MVP, W1 | FR-02-041; UC-02-21 |
| US-02-042 | Là chủ dịch vụ, tôi muốn tạo phiên bản mới, để chủ dịch vụ có bản nháp phiên bản mới với nội dung phiên bản cũ làm nền. | M | 5 | MVP, W1 | FR-02-042; UC-02-18 |
| US-02-043 | Là người duyệt dịch vụ, tôi muốn so sánh phiên bản và phân loại thay đổi phá vỡ, để chủ dịch vụ thấy ngay thay đổi nào phá vỡ và biết cần tăng số chính hay không. | M | 5 | MVP, W1 | FR-02-043; UC-02-18 |
| US-02-044 | Là chủ dịch vụ, tôi muốn phân tích tác động của thay đổi tới bên khai thác, để chủ dịch vụ biết đích danh bên nào bị ảnh hưởng và mức độ để lập lộ trình chuyển đổi hợp lý. | M | 3 | MVP, W1 | FR-02-044; UC-02-18 |
| US-02-045 | Là quản trị tỉnh, tôi muốn chuyển chủ quản API, để API có người chịu trách nhiệm mới, không gián đoạn. | S | 5 | MVP, W1 | FR-02-045; UC-02-22 |

: Story của epic EP-02-F Vòng đời, duyệt và phiên bản

#### EP-02-G · Đăng ký sử dụng

Epic gồm 7 story, 31 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-046 | Là cán bộ đầu mối của tổ chức, tôi muốn gửi đăng ký sử dụng API, để đơn vị khai thác có đăng ký đang chờ duyệt (hoặc đã được tự duyệt) và biết ai sẽ duyệt. | M | 5 | MVP, W1 | FR-02-046; UC-02-23 |
| US-02-047 | Là chủ dịch vụ, tôi muốn duyệt hoặc từ chối đăng ký sử dụng, để đăng ký được quyết định có người chịu trách nhiệm; HTTT khai thác nhận kết quả kèm ý kiến. | M | 5 | MVP, W1 | FR-02-047; UC-02-24 |
| US-02-048 | Là vận hành tỉnh, tôi muốn hệ thống cấp phạm vi truy cập theo đăng ký đã duyệt, để HTTT khai thác gọi được API ngay sau khi duyệt mà không ai thao tác thủ công ở nhiều nơi. | M | 5 | MVP, W1 | FR-02-048; UC-02-25 |
| US-02-049 | Là chủ dịch vụ, tôi muốn xem đăng ký theo API, để chủ dịch vụ nhìn rõ danh sách bên khai thác API của mình. | M | 3 | MVP, W1 | FR-02-049; UC-02-26 |
| US-02-050 | Là cán bộ đầu mối của tổ chức, tôi muốn xem đăng ký theo HTTT, để đơn vị khai thác thấy toàn bộ API mình đang dùng và biết việc cần làm. | M | 3 | MVP, W1 | FR-02-050; UC-02-26 |
| US-02-051 | Là vận hành tỉnh, tôi muốn tạm ngừng, tiếp tục, thu hồi, hủy đăng ký, để quyền dùng API bị chặn hoặc phục hồi nhanh, đúng lý do, HTTT được báo. | M | 5 | MVP, W1 | FR-02-051; UC-02-27 |
| US-02-052 | Là cán bộ đầu mối của tổ chức, tôi muốn hệ thống gia hạn và rà soát định kỳ đăng ký, để quyền gọi API luôn còn khớp với nhu cầu thật; đăng ký bỏ quên tự hết hạn. | S | 5 | Đợt 2, W4 | FR-02-052; UC-02-28 |

: Story của epic EP-02-G Đăng ký sử dụng

#### EP-02-H · Đồng bộ danh mục quốc gia

Epic gồm 2 story, 10 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-053 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ danh mục lên Nền tảng quốc gia qua PH-14, để danh mục quốc gia phản ánh đúng các API tỉnh đã công khai, tự động cập nhật khi thay đổi. | M | 5 | MVP, W1 | FR-02-053; UC-02-29 |
| US-02-054 | Là quản trị tỉnh, tôi muốn theo dõi trạng thái đồng bộ, thử lại, cảnh báo quá hạn, để cán bộ vận hành biết tức thì tình trạng tuân thủ đăng ký danh mục và xử lý được từng trường hợp. | M | 5 | MVP, W1 | FR-02-054; UC-02-30 |

: Story của epic EP-02-H Đồng bộ danh mục quốc gia

#### EP-02-I · Cam kết chất lượng, thông báo và thống kê

Epic gồm 4 story, 18 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-055 | Là chủ dịch vụ, tôi muốn khai báo cam kết chất lượng dịch vụ (SLA), để API có cam kết chất lượng rõ ràng, hiển thị trong danh mục. | M | 5 | MVP, W1 | FR-02-055; UC-02-31 |
| US-02-056 | Là chủ dịch vụ, tôi muốn hệ thống đối chiếu SLA thực tế, báo cáo tuân thủ, để bên khai thác thấy SLA thực tế cạnh cam kết; quản lý phát hiện dịch vụ liên tục không đạt. | M | 5 | MVP, W1 | FR-02-056; UC-02-32 |
| US-02-057 | Là chủ dịch vụ, tôi muốn hệ thống thông báo thay đổi cho bên khai thác, để mọi bên đang dùng API nhận được thông báo kịp thời, và chủ dịch vụ biết ai đã nhận. | M | 5 | MVP, W1 | FR-02-057; UC-02-19, 02-33 |
| US-02-058 | Là chủ dịch vụ, tôi muốn thống kê sử dụng dịch vụ, để người quản lý có số liệu thật để quyết định về từng dịch vụ. | S | 3 | Đợt 2, W4 | FR-02-058; UC-02-34 |

: Story của epic EP-02-I Cam kết chất lượng, thông báo và thống kê

#### EP-02-J · Tích hợp và quản trị

Epic gồm 4 story, 19 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-02-059 | Là chủ dịch vụ, tôi muốn hệ thống cung cấp giao diện nội bộ cho PH-03, PH-04, PH-15, để PH-03, PH-04, PH-15 có nguồn dữ liệu chuẩn, nhất quán với PH-02. | M | 3 | MVP, W1 | FR-02-059; UC-02-35 |
| US-02-060 | Là vận hành tỉnh, tôi muốn hệ thống đối soát cấu hình công bố với gateway, để vận hành biết tức thì khi cấu hình gateway và danh mục không khớp. | C | 5 | Đợt 2, W4 | FR-02-060; UC-02-36 |
| US-02-061 | Là quản trị tỉnh, tôi muốn di trú API, gói, đăng ký từ APIM cũ, để danh mục có dữ liệu từ APIM cũ ở dạng bản nháp, kèm danh sách việc cần bổ sung, không mang khóa cũ sang. | M | 8 | MVP, W1 | FR-02-061; UC-02-37 |
| US-02-062 | Là quản trị tỉnh, tôi muốn có cấu hình tham số của phân hệ, để phân hệ chạy theo ngưỡng phù hợp tỉnh, thay đổi có hiệu lực trong vòng một phút. | M | 3 | MVP, W1 | FR-02-062; UC-02-38 |

: Story của epic EP-02-J Tích hợp và quản trị

### 6.4. PH-03 · Cổng API

Phân hệ có 7 epic, 59 story, tổng 212 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-03-PH03 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-03-A · Lớp biên và bảo vệ truyền tải

Epic gồm 11 story, 43 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-001 | Là quản trị nền tảng, tôi muốn kết thúc TLS tại hai cửa vào, để HTTT kết nối được qua TLS 1.3; HTTT cũ có đường kết nối tạm thời có hạn, hiển thị rõ ở UI-03-12 để theo dõi thanh lý. | M | 3 | MVP, W1 | FR-03-001; UC-03-01, 03-05, 03-17 |
| US-03-002 | Là quản trị nền tảng, tôi muốn xác minh chứng thư khách mTLS, để HTTT có chứng thư hợp lệ được nhận diện ngay ở biên; chứng thư sai bị chặn trước khi tốn tài nguyên. | M | 5 | MVP, W1 | FR-03-002; UC-03-02, 03-17 |
| US-03-003 | Là quản trị nền tảng, tôi muốn hệ thống giới hạn kết nối và tốc độ theo địa chỉ nguồn, để lưu lượng bất thường từ một địa chỉ bị cắt ở biên, nền tảng chịu được tải gấp ba lần cao điểm (900 lượt/giây) không suy giảm (NFR-03-013). | M | 5 | MVP, W1 | FR-03-003; UC-03-05, 03-12, 03-29 |
| US-03-004 | Là cán bộ ATTT, tôi muốn hệ thống chặn tạm địa chỉ nguồn vi phạm liên tục, để nguồn tấn công bị cắt khỏi nền tảng trong tối đa 60 giây, tự gỡ sau 15 phút nếu không phải do SO đặt tay. | S | 5 | MVP, W1 | FR-03-004; UC-03-12 |
| US-03-005 | Là cán bộ ATTT, tôi muốn hệ thống WAF Coraza với bộ luật OWASP CRS, để tỉ lệ chặn nhầm dưới 0,1% lượt hợp lệ (NFR-03-012); tấn công phổ biến bị chặn trước khi tới backend. | M | 5 | MVP, W1 | FR-03-005; UC-03-05, 03-13 |
| US-03-006 | Là cán bộ ATTT, tôi muốn có chế độ phát hiện, chặn của WAF và tự hạ khi quá tải, để WAF chuyển chế độ đúng quy trình, có hai người chịu trách nhiệm; khi quá tải dịch vụ vẫn chạy, đội ATTT được báo ngay. | M | 5 | MVP, W1 | FR-03-006; UC-03-13 |
| US-03-007 | Là quản trị tỉnh, tôi muốn ngoại lệ luật WAF có thời hạn, để lượt gọi hợp lệ không còn bị chặn nhầm trong thời hạn nêu; mọi ngoại lệ đang có được liệt kê, có người duyệt và hạn. | M | 5 | MVP, W1 | FR-03-007; UC-03-14 |
| US-03-008 | Là cán bộ ATTT, tôi muốn luật vá ảo khẩn cấp, để luật vá ảo có hiệu lực trong vài phút sau duyệt; đội ATTT có thời gian vá backend. | S | 3 | Đợt 2, W4 | FR-03-008; UC-03-15 |
| US-03-009 | Là quản trị nền tảng, tôi muốn hệ thống kiểm tra lược đồ và giới hạn kích thước yêu cầu, để backend chỉ nhận yêu cầu đúng hợp đồng và đúng cỡ; 0 lỗi 5xx do fuzzing đầu vào (SEC-43). | M | 3 | MVP, W1 | FR-03-009; UC-03-05 |
| US-03-010 | Là quản trị tỉnh, tôi muốn xử lý CORS, để ứng dụng web được phép gọi API từ trình duyệt; ứng dụng lạ không gọi được. | S | 2 | Đợt 2, W4 | FR-03-010; UC-03-05 |
| US-03-011 | Là quản trị nền tảng, tôi muốn hệ thống tiêu đề bảo mật và che thông tin máy chủ, để bên gọi và công cụ quét bên ngoài không đọc được phiên bản phần mềm; tiêu đề bảo mật có mặt trên mọi phản hồi. | M | 2 | MVP, W1 | FR-03-011; UC-03-05, 03-29 |

: Story của epic EP-03-A Lớp biên và bảo vệ truyền tải

#### EP-03-B · Xác thực và kiểm soát truy cập thô

Epic gồm 9 story, 28 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-012 | Là HTTT khai thác, tôi muốn xác minh chữ ký JWT cục bộ, để token giả, hết hạn hoặc sai nơi phát hành bị loại ở gateway với độ trễ không quá 2 ms mỗi lượt (NFR-03-002); đường đi không gọi mạng tới Keycloak. | M | 5 | MVP, W1 | FR-03-012; UC-03-01, 03-03 |
| US-03-013 | Là vận hành tỉnh, tôi muốn hệ thống xác định tenant của lượt gọi, để không HTTT nào chọn được tenant khác bằng cách tự khai; mọi DU nhận tenant đã được gateway chứng thực. | M | 3 | MVP, W1 | FR-03-013; UC-03-01, 03-03 |
| US-03-014 | Là quản trị nền tảng, tôi muốn ràng buộc token với chứng thư khách, để token bị đánh cắp không dùng lại được từ máy khác. | M | 3 | MVP, W1 | FR-03-014; UC-03-02 |
| US-03-015 | Là quản trị nền tảng, tôi muốn hệ thống áp phương thức bảo mật theo gói sử dụng, để mỗi API dùng đúng phương thức xác thực mạnh theo mức phân loại; không còn khóa dùng chung cho dữ liệu hạn chế. | M | 3 | MVP, W1 | FR-03-015; UC-03-01, 03-02 |
| US-03-016 | Là HTTT khai thác, tôi muốn kiểm tra đăng ký sử dụng và hiệu lực gói, để đăng ký bị thu hồi thì lượt gọi kế tiếp (trong tối đa 10 giây) bị từ chối, không cần chờ token hết hạn. | M | 2 | MVP, W1 | FR-03-016; UC-03-01 |
| US-03-017 | Là quản trị nền tảng, tôi muốn hệ thống kiểm tra phạm vi quyền thô, để lượt gọi thiếu quyền cơ bản bị chặn với độ trễ không đáng kể. | M | 2 | MVP, W1 | FR-03-017; UC-03-01 |
| US-03-018 | Là cán bộ ATTT, tôi muốn hệ thống thu hồi token nhanh bằng danh sách chặn, để token đã thu hồi bị chặn trong tối đa 60 giây (thực tế dưới 15 giây: gọi API dưới 5 giây cộng bộ đệm 5 giây). | M | 5 | MVP, W1 | FR-03-018; UC-03-10 |
| US-03-019 | Là vận hành tỉnh, tôi muốn hệ thống ủy quyền chi tiết bằng OPA tại gateway, để mọi lượt gọi đều có quyết định cho phép hay từ chối có nhật ký; backend không nhận lượt gọi bị chính sách từ chối. | M | 3 | MVP, W1 | FR-03-019; UC-03-01 |
| US-03-020 | Là quản trị nền tảng, tôi muốn hệ thống có danh sách cho phép và chặn đường dẫn, để HTTT chỉ gọi đúng các đường dẫn của gói; đường quản trị không lộ ra qua API công bố. | M | 2 | MVP, W1 | FR-03-020; UC-03-01 |

: Story của epic EP-03-B Xác thực và kiểm soát truy cập thô

#### EP-03-C · Hạn mức và hạn ngạch

Epic gồm 7 story, 22 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-021 | Là quản trị nền tảng, tôi muốn hệ thống giới hạn tần suất theo bên gọi, để mỗi HTTT bị giới hạn công bằng theo gói; hạn mức tính theo HTTT nên hai HTTT cùng địa chỉ sau NAT không ảnh hưởng nhau (BR-03-005). | M | 3 | MVP, W1 | FR-03-021; UC-03-01, 03-04 |
| US-03-022 | Là quản trị tỉnh, tôi muốn hệ thống có hạn ngạch theo chu kỳ và cảnh báo ngưỡng, để HTTT biết trước khi sắp hết hạn ngạch; hệ thống không bị lạm dụng theo thời gian dài; dịch vụ thiết yếu không bị gián đoạn đột ngột. | M | 3 | MVP, W1 | FR-03-022; UC-03-04 |
| US-03-023 | Là quản trị nền tảng, tôi muốn hạn mức toàn tenant, để mỗi tenant dùng trong phần của mình; cảnh báo sớm khi một tỉnh sắp chạm trần để hai bên cùng bàn mở rộng. | M | 5 | MVP, W1 | FR-03-023; UC-03-25 |
| US-03-024 | Là quản trị tỉnh, tôi muốn hạn mức theo route và thứ tự ưu tiên chính sách, để quản trị điều chỉnh nhanh hạn mức khi sự cố mà không phải sửa gói ở PH-02; thứ tự áp dụng rõ ràng, kiểm thử được. | S | 3 | Đợt 2, W4 | FR-03-024; UC-03-25 |
| US-03-025 | Là HTTT khai thác, tôi muốn phản hồi vượt hạn mức và tiêu đề hạn mức, để HTTT thấy ngay mình ở đâu so với hạn mức và chờ đúng thời gian, giảm số lần thử lại vô ích. | M | 2 | MVP, W1 | FR-03-025; UC-03-01, 03-04, 03-08 |
| US-03-026 | Là vận hành nền tảng, tôi muốn hệ thống suy giảm có kiểm soát khi Valkey mất, để gateway không dừng vì Valkey; đội vận hành biết hạn mức đang kém chính xác. | M | 3 | MVP, W1 | FR-03-026; UC-03-08 |
| US-03-027 | Là quản trị tỉnh, tôi muốn hệ thống điều tiết theo tình trạng backend, để HTTT thiết yếu vẫn được phục vụ khi backend yếu; hạn mức tự hồi phục khi backend ổn định. | S | 3 | Đợt 2, W4 | FR-03-027; UC-03-06 |

: Story của epic EP-03-C Hạn mức và hạn ngạch

#### EP-03-D · Định tuyến và chuyển tiếp

Epic gồm 11 story, 38 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-028 | Là vận hành tỉnh, tôi muốn hệ thống định tuyến theo host, đường dẫn, phương thức, để mỗi lượt gọi đi đúng route; route của tenant khác không bao giờ khớp (kiểm thử rò rỉ chéo tenant). | M | 3 | MVP, W1 | FR-03-028; UC-03-01 |
| US-03-029 | Là vận hành tỉnh, tôi muốn hệ thống cân bằng tải giữa các backend, để lượt gọi được phân đều trên các backend khỏe; bảo trì từng nút không gây lỗi cho bên gọi. | M | 2 | MVP, W1 | FR-03-029; UC-03-01, 03-06 |
| US-03-030 | Là vận hành tỉnh, tôi muốn hệ thống kiểm tra sức khỏe backend chủ động và thụ động, để nút hỏng bị loại trong tối đa 15 giây (3 lần × 5 giây) và lượt gọi chuyển sang nút còn lại không lỗi. | M | 3 | MVP, W1 | FR-03-030; UC-03-06 |
| US-03-031 | Là quản trị nền tảng, tôi muốn hệ thống thời hạn chờ, ngắt mạch và trả lỗi nhanh, để lỗi backend trả về nhanh, không chiếm kết nối của gateway; backend có thời gian hồi phục không bị dồn tải. | M | 5 | MVP, W1 | FR-03-031; UC-03-06 |
| US-03-032 | Là vận hành tỉnh, tôi muốn hệ thống sinh và truyền định danh truy vết, để 100% lượt gọi có `traceId`; vận hành tra một lượt gọi từ gateway tới backend trong một vết. | M | 3 | MVP, W1 | FR-03-032; UC-03-01 |
| US-03-033 | Là quản trị nền tảng, tôi muốn chuyển tiếp WebSocket và nén nội dung, để API kết nối dài hoạt động qua gateway với cùng mức bảo vệ như API thường. | M | 3 | MVP, W1 | FR-03-033; UC-03-07 |
| US-03-034 | Là quản trị nền tảng, tôi muốn chuyển đổi gRPC và REST, để HTTT gọi dịch vụ gRPC bằng REST qua một điểm vào. | C | 3 | Đợt 3, W5 | FR-03-034; UC-03-07 |
| US-03-035 | Là quản trị nền tảng, tôi muốn hệ thống có phiên bản API song song và tiêu đề ngừng dùng, để HTTT biết sớm và có đủ thời gian chuyển sang phiên bản mới; không phiên bản nào ngừng đột ngột. | S | 3 | MVP, W1 | FR-03-035; UC-03-09 |
| US-03-036 | Là vận hành tỉnh, tôi muốn dừng và mở API tức thời, để API dừng và mở có hiệu lực trong vài giây, có lý do và dấu vết. | M | 5 | MVP, W1 | FR-03-036; UC-03-09 |
| US-03-037 | Là quản trị nền tảng, tôi muốn chuyển tiếp lượt gọi của tenant đã sáp nhập, để HTTT của tỉnh cũ không bị gián đoạn khi sáp nhập, và có thời gian chuyển đổi rõ ràng. | S | 3 | Đợt 2, W4 | FR-03-037; UC-03-30 |
| US-03-038 | Là quản trị tỉnh, tôi muốn phân cửa vào Internet và mạng nội bộ, để bề mặt tiếp xúc Internet được kiểm soát và rà soát; không có API nào ra ngoài mà không qua hai người. | M | 5 | MVP, W1 | FR-03-038; UC-03-16 |

: Story của epic EP-03-D Định tuyến và chuyển tiếp

#### EP-03-E · Đồng bộ cấu hình

Epic gồm 11 story, 47 điểm (11 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-039 | Là quản trị nền tảng, tôi muốn hệ thống tổng hợp cấu hình gateway từ danh mục, để một mô hình cấu hình nhất quán, tái lập được từ dữ liệu nguồn; không ai phải sửa tay cấu hình gateway. | M | 3 | MVP, W1 | FR-03-039; UC-03-19 |
| US-03-040 | Là quản trị nền tảng, tôi muốn hệ thống kiểm tra hợp lệ cấu hình trước khi phát, để cấu hình sai hoặc thiếu an toàn không bao giờ tới gateway; người sửa biết chính xác lỗi ở đâu. | M | 5 | MVP, W1 | FR-03-040; UC-03-19 |
| US-03-041 | Là vận hành tỉnh, tôi muốn hệ thống sinh ảnh chụp cấu hình có phiên bản và chữ ký, để mỗi ảnh chụp là bằng chứng bất biến, kiểm chứng được, truy được nguồn gốc dữ liệu. | M | 3 | MVP, W1 | FR-03-041; UC-03-19 |
| US-03-042 | Là quản trị nền tảng, tôi muốn hệ thống phát ảnh chụp tới Git và bucket, để mọi nút gateway thấy ảnh chụp mới trong vài giây; cấu hình có lịch sử đầy đủ ở Git. | M | 5 | MVP, W1 | FR-03-042; UC-03-20 |
| US-03-043 | Là vận hành nền tảng, tôi muốn hệ thống nạp ảnh chụp ở nút gateway, để thay đổi cấu hình có hiệu lực ở mọi nút trong 10 giây (mục tiêu) mà không lượt gọi nào lỗi; cấu hình sai hoặc giả không bao giờ được nạp. | M | 5 | MVP, W1 | FR-03-043; UC-03-20 |
| US-03-044 | Là quản trị nền tảng, tôi muốn quay lui về phiên bản cấu hình trước, để sự cố do cấu hình được khắc phục trong vài chục giây; mọi thao tác có lý do và dấu vết. | M | 5 | MVP, W1 | FR-03-044; UC-03-21 |
| US-03-045 | Là vận hành nền tảng, tôi muốn theo dõi nút và trạng thái đồng bộ, để vận hành biết sau một phát cấu hình mọi nút đã nhận chưa; nút lệch được phát hiện trong dưới 2 phút. | M | 3 | MVP, W1 | FR-03-045; UC-03-22 |
| US-03-046 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ consumer và thông tin xác thực công khai, để HTTT mới gọi được API trong vài giây sau khi saga hoàn tất; HTTT bị tạm ngừng bị chặn trong vài giây. | M | 5 | MVP, W1 | FR-03-046; UC-03-23 |
| US-03-047 | Là cán bộ ATTT, tôi muốn tạm ngừng khẩn cấp route hoặc consumer, để nguồn sự cố bị chặn trong tối đa 30 giây; nhân sự có thời gian điều tra mà không bị tác động. | M | 5 | MVP, W1 | FR-03-047; UC-03-11 |
| US-03-048 | Là quản trị nền tảng, tôi muốn có bộ mẫu chính sách gateway được duyệt sẵn, để chính sách của mọi API thống nhất, rà soát được một lần; không có cấu hình riêng lẻ khó kiểm soát. | M | 3 | MVP, W1 | FR-03-048; UC-03-24 |
| US-03-049 | Là quản trị nền tảng, tôi muốn quản lý chứng thư biên, để không còn sự cố hết hạn chứng thư; gia hạn tự động không gián đoạn (NFR-03-011). | M | 5 | MVP, W1 | FR-03-049; UC-03-17 |

: Story của epic EP-03-E Đồng bộ cấu hình

#### EP-03-F · Quan sát và nhật ký lượt gọi

Epic gồm 6 story, 20 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-050 | Là vận hành tỉnh, tôi muốn hệ thống ghi siêu dữ liệu lượt gọi có che dữ liệu, để mọi lượt gọi truy vết được theo thời gian, HTTT, route, kết quả, `traceId`; 0 dữ liệu cá nhân trong nhật ký. | M | 3 | MVP, W1 | FR-03-050; UC-03-01, 03-03, 03-26 |
| US-03-051 | Là quản trị tỉnh, tôi muốn tra cứu và xuất nhật ký lượt gọi, để vận hành tìm một lượt gọi lỗi trong vài giây, trong p95 ≤ 3 giây (NFR-03-022). | M | 3 | MVP, W1 | FR-03-051; UC-03-26 |
| US-03-052 | Là vận hành nền tảng, tôi muốn hệ thống phát chỉ số và vết OpenTelemetry, để PH-13 có số liệu đủ để dựng bảng điều khiển và cảnh báo; chỉ tiêu NFR kiểm chứng được từ số liệu thật. | M | 3 | MVP, W1 | FR-03-052; UC-03-01, 03-27 |
| US-03-053 | Là quản trị tỉnh, tôi muốn hệ thống kiểm tra tổng hợp cho API quan trọng, để sự cố API quan trọng được phát hiện trong dưới 3 phút, trước khi người dùng báo. | S | 5 | MVP, W1 | FR-03-053; UC-03-28 |
| US-03-054 | Là cán bộ ATTT, tôi muốn cảnh báo sự kiện an ninh tại gateway, để đội ATTT biết trong vài phút khi gateway bị tấn công hoặc suy giảm; sự kiện ra SIEM đủ để điều tra. | M | 3 | MVP, W1 | FR-03-054; UC-03-18 |
| US-03-055 | Là quản trị nền tảng, tôi muốn có bảng điều khiển lưu lượng gateway, để vận hành nắm tình hình cổng trong một màn hình, với độ trễ số liệu không quá 15 giây. | M | 3 | MVP, W1 | FR-03-055; UC-03-27 |

: Story của epic EP-03-F Quan sát và nhật ký lượt gọi

#### EP-03-G · Quản trị

Epic gồm 4 story, 14 điểm (1 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-03-056 | Là quản trị nền tảng, tôi muốn có tham số gateway theo tenant, để gateway của tỉnh chạy với tham số phù hợp điều kiện thực tế mà vẫn trong khuôn khổ an toàn nền tảng. | M | 5 | MVP, W1 | FR-03-056; UC-03-29 |
| US-03-057 | Là quản trị tỉnh, tôi muốn chạy thử chính sách bằng mô phỏng, để quản trị hiểu và kiểm thử được chính sách trước khi áp dụng, không gây tác động nào lên lưu lượng thật. | S | 3 | Đợt 2, W4 | FR-03-057; UC-03-24 |
| US-03-058 | Là quản trị tỉnh, tôi muốn có báo cáo sử dụng API theo HTTT và gói, để đủ số liệu để rà soát đăng ký sử dụng và lập kế hoạch năng lực. | S | 3 | Đợt 2, W4 | FR-03-058; UC-03-27 |
| US-03-059 | Là quản trị nền tảng, tôi muốn nhập cấu hình từ gateway cũ, để khối lượng khai báo thủ công giảm mạnh; danh sách HTTT phải cấp lại thông tin xác thực rõ ràng; có ánh xạ cũ sang mới cho chạy song song. | S | 3 | MVP, W1 | FR-03-059; UC-03-31 |

: Story của epic EP-03-G Quản trị

### 6.5. PH-04 · Lõi tích hợp và trình thiết kế luồng

Phân hệ có 7 epic, 60 story, tổng 174 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-03-PH04 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-04-A · Không gian làm việc và quản lý luồng

Epic gồm 7 story, 30 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-001 | Là người dùng có quyền xem, tôi muốn liệt kê luồng, tìm theo tên, endpoint, hệ nguồn, môi trường, đếm theo trạng thái, để người dùng thấy danh sách luồng đúng phạm vi được xem, số luồng theo từng trạng thái và các nút thao tác được phép trên từng dòng. | M | 3 | MVP, W1 | FR-04-001; UC-04-02 |
| US-04-002 | Là kỹ sư tích hợp, tôi muốn xem chi tiết luồng: thông tin, route, endpoint, thuộc tính, sơ đồ, mã nguồn, phiên bản, triển khai, để người dùng thấy mọi thông tin của luồng mà Bus cũ chia trên sáu tab, cùng phiên bản và triển khai theo môi trường, không cần truy cập máy chủ chạy. | M | 3 | MVP, W1 | FR-04-002; UC-04-02 |
| US-04-003 | Là kỹ sư tích hợp, tôi muốn tạo luồng mới từ luồng trống, khuôn mẫu, API trong danh mục dịch vụ hoặc tệp YAML, để IE có một luồng nháp đã có khung đúng chuẩn và được đưa thẳng vào trình thiết kế để làm tiếp. | M | 8 | MVP, W1 | FR-04-003; UC-04-03 |
| US-04-004 | Là kỹ sư tích hợp, tôi muốn cập nhật thông tin luồng, để thông tin luồng được cập nhật ngay trên danh sách và chi tiết; nếu luồng thành đối ngoại, người dùng thấy ngay những gì phải bổ sung trước khi gửi duyệt. | M | 5 | MVP, W1 | FR-04-004; UC-04-02 |
| US-04-005 | Là kỹ sư tích hợp, tôi muốn nhân bản luồng, để người dùng có luồng nháp mới giống luồng nguồn, sẵn sàng chỉnh sửa. | S | 3 | Đợt 2, W4 | FR-04-005; UC-04-16 |
| US-04-006 | Là kỹ sư tích hợp, tôi muốn gỡ bỏ luồng có kiểm tra phụ thuộc, xóa bản nháp, để luồng không còn chạy ở môi trường nào, không còn hiện trong danh sách mặc định, lịch sử vẫn tra được. | M | 5 | MVP, W1 | FR-04-006; UC-04-16 |
| US-04-007 | Là quản trị tỉnh, tôi muốn quản lý không gian làm việc và thành viên, để mỗi đơn vị có không gian làm việc riêng với đúng người được sửa, được duyệt. | S | 3 | Đợt 2, W4 | FR-04-007; UC-04-01 |

: Story của epic EP-04-A Không gian làm việc và quản lý luồng

#### EP-04-B · Trình thiết kế luồng

Epic gồm 18 story, 45 điểm (13 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-010 | Là kỹ sư tích hợp, tôi muốn mở trình thiết kế, phiên soạn thảo và cảnh báo người khác đang sửa, để người dùng làm việc trên đúng phiên bản, biết ai đang mở cùng và có cơ hội khôi phục phần chưa lưu. | M | 2 | MVP, W1 | FR-04-010; UC-04-04 |
| US-04-011 | Là kỹ sư tích hợp, tôi muốn tạo phiên bản mới từ phiên bản đã có, để IE có bản nháp mới để sửa trong khi phiên bản cũ vẫn chạy bình thường. | M | 2 | MVP, W1 | FR-04-011; UC-04-04 |
| US-04-012 | Là kỹ sư tích hợp, tôi muốn có bảng thành phần theo danh mục được phép, tìm kiếm và lọc theo vai trò chặng, để IE tìm được thành phần cần trong vài lần gõ và chỉ thấy thứ được phép dùng. | M | 2 | MVP, W1 | FR-04-012; UC-04-04 |
| US-04-013 | Là kỹ sư tích hợp, tôi muốn thao tác trên sơ đồ: thêm, chèn, xóa, nối, rẽ nhánh, chọn nhiều, thu phóng, tự sắp xếp, hoàn tác, để sơ đồ phản ánh ngay thay đổi, có thể hoàn tác ít nhất 100 bước. | M | 2 | MVP, W1 | FR-04-013; UC-04-04 |
| US-04-014 | Là kỹ sư tích hợp, tôi muốn có cấu hình chặng bằng biểu mẫu sinh từ catalog, khôi phục giá trị gốc, để chặng được cấu hình đúng lược đồ, lỗi hiện ngay tại trường. | M | 2 | MVP, W1 | FR-04-014; UC-04-05 |
| US-04-015 | Là kỹ sư tích hợp, tôi muốn trình soạn biểu thức có gợi ý, kiểm tra cú pháp và xem trước trên bản tin mẫu, để IE biết biểu thức đúng hay sai và cho ra giá trị gì trước khi chạy thử cả luồng. | M | 2 | MVP, W1 | FR-04-015; UC-04-05 |
| US-04-016 | Là kỹ sư tích hợp, tôi muốn chọn kết nối PH-05 và tham chiếu bí mật thay vì nhập bí mật, để chặng dùng kết nối đã được kiểm tra ở PH-05; định nghĩa luồng không có bí mật. | M | 3 | MVP, W1 | FR-04-016; UC-04-05 |
| US-04-017 | Là kỹ sư tích hợp, tôi muốn đồng bộ hai chiều giữa sơ đồ, thuộc tính và YAML, không mất dữ liệu khi quay vòng, để người dùng sửa ở phía nào cũng thấy phía kia cập nhật, mở rồi lưu không làm đổi luồng. | M | 2 | MVP, W1 | FR-04-017; UC-04-04 |
| US-04-018 | Là kỹ sư tích hợp, tôi muốn soạn Kamelet và gửi đăng ký Kamelet tự viết, để tỉnh có khối dùng lại của riêng mình, đã qua duyệt, kéo vào được ở mọi luồng của tỉnh. | S | 5 | Đợt 2, W4 | FR-04-018; UC-04-07 |
| US-04-019 | Là kỹ sư tích hợp, tôi muốn soạn Pipe, để tích hợp một chiều được dựng không cần viết route. | S | 2 | Đợt 2, W4 | FR-04-019; UC-04-07 |
| US-04-020 | Là kỹ sư tích hợp, tôi muốn trình ánh xạ dữ liệu sinh biểu thức JQ, để IE có phép chuyển đổi đã xem trước đúng trên dữ liệu mẫu, mở lại sửa được bằng giao diện. | M | 2 | MVP, W1 | FR-04-020; UC-04-06 |
| US-04-021 | Là kỹ sư tích hợp, tôi muốn bean, cấu hình cấp tệp và metadata, để cấu hình cấp tệp được khai báo an toàn, không mở đường nạp mã tùy ý. | S | 3 | Đợt 2, W4 | FR-04-021; UC-04-07 |
| US-04-022 | Là kỹ sư tích hợp, tôi muốn ghim bản tin mẫu theo chặng, để IE xem trước được biểu thức và ánh xạ trên dữ liệu gần thật mà không lộ dữ liệu cá nhân. | M | 2 | MVP, W1 | FR-04-022; UC-04-05 |
| US-04-023 | Là kỹ sư tích hợp, tôi muốn kiểm tra hợp lệ định nghĩa luồng, để người dùng thấy danh sách vấn đề theo mức, bấm vào là tới đúng chặng, đúng trường. | M | 5 | MVP, W1 | FR-04-023; UC-04-04, 04-10 |
| US-04-024 | Là kỹ sư tích hợp, tôi muốn lưu bản nháp tự động, phát hiện xung đột, khôi phục phiên nháp, để thiết kế được lưu an toàn; khi hai người cùng sửa, người lưu sau được thấy rõ khác biệt để gộp. | M | 3 | MVP, W1 | FR-04-024; UC-04-04 |
| US-04-025 | Là kỹ sư tích hợp, tôi muốn có thư viện khuôn mẫu luồng, để IE có luồng khởi đầu đúng chuẩn cho kiểu tích hợp cần làm. | S | 2 | Đợt 2, W4 | FR-04-025; UC-04-03 |
| US-04-026 | Là kỹ sư tích hợp, tôi muốn ghi chú dán và luồng con dùng lại, để sơ đồ có chú giải; phần lặp lại được dùng chung qua luồng con. | C | 2 | Đợt 2, W4 | FR-04-026; UC-04-04 |
| US-04-027 | Là kỹ sư tích hợp, tôi muốn tải xuống, nhập YAML và xuất gói luồng, để người dùng có tệp luồng dùng được ngoài Datahub, hoặc đưa được YAML soạn ngoài vào trình thiết kế. | M | 2 | MVP, W1 | FR-04-027; UC-04-04 |

: Story của epic EP-04-B Trình thiết kế luồng

#### EP-04-C · Chạy thử và ca kiểm thử

Epic gồm 4 story, 14 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-030 | Là kỹ sư tích hợp, tôi muốn chạy thử luồng trên sandbox với đích mô phỏng, để IE thấy bản tin đi qua từng chặng, chặng nào lỗi, mất bao lâu, dữ liệu vào ra ở mỗi chặng; lần chạy đạt mở đường gửi duyệt. | M | 8 | MVP, W1 | FR-04-030; UC-04-08 |
| US-04-031 | Là kỹ sư tích hợp, tôi muốn ca kiểm thử của luồng và bộ chạy, để luồng có bộ ca kiểm thử chạy lại được bằng một nút bấm và tự chạy khi gửi duyệt. | S | 3 | Đợt 2, W4 | FR-04-031; UC-04-09 |
| US-04-032 | Là kỹ sư tích hợp, tôi muốn có nhật ký chạy thử, xem lại, so sánh hai lần chạy, dọn nhật ký, để người dùng xem lại được mọi lần chạy còn trong thời hạn và biết chặng nào chậm đi hay nhanh lên. | M | 2 | MVP, W1 | FR-04-032; UC-04-08 |
| US-04-033 | Là kỹ sư tích hợp, tôi muốn phủ kết quả chạy thử và số liệu chạy thật lên sơ đồ, để người dùng thấy ngay chặng có vấn đề. | M | 1 | MVP, W1 | FR-04-033; UC-04-08 |

: Story của epic EP-04-C Chạy thử và ca kiểm thử

#### EP-04-D · Duyệt, phát hành và triển khai

Epic gồm 6 story, 29 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-040 | Là kỹ sư tích hợp, tôi muốn gửi duyệt phiên bản, để phiên bản được khóa và nằm trong hàng đợi duyệt; IE nhận thông báo khi có quyết định. | M | 5 | MVP, W1 | FR-04-040; UC-04-10 |
| US-04-041 | Là người duyệt tích hợp, tôi muốn duyệt bốn mắt với so sánh YAML và so sánh sơ đồ, để phiên bản được duyệt và bắt đầu phát hành, hoặc trả về người thiết kế với ý kiến cụ thể. | M | 8 | MVP, W1 | FR-04-041; UC-04-11 |
| US-04-042 | Là người duyệt tích hợp, tôi muốn phát hành qua GitOps và theo dõi tình trạng triển khai, để người dùng thấy triển khai đi qua các bước "Đã ghi kho cấu hình", "Argo CD đồng bộ", "Runtime đã nạp đúng băm", và luồng chuyển "Đang chạy". | M | 8 | MVP, W1 | FR-04-042; UC-04-12 |
| US-04-043 | Là kỹ sư tích hợp, tôi muốn so sánh hai phiên bản bất kỳ, để người dùng thấy rõ từng thay đổi giữa hai phiên bản. | M | 2 | MVP, W1 | FR-04-043; UC-04-11 |
| US-04-044 | Là người duyệt tích hợp, tôi muốn quay lui về phiên bản trước, để môi trường chạy lại phiên bản ổn định trước đó trong vài phút. | M | 3 | MVP, W1 | FR-04-044; UC-04-13 |
| US-04-045 | Là người duyệt tích hợp, tôi muốn thăng cấp phiên bản qua các môi trường, để phiên bản đã kiểm chứng ở môi trường trước chạy ở môi trường kế tiếp. | S | 3 | Đợt 2, W4 | FR-04-045; UC-04-12 |

: Story của epic EP-04-D Duyệt, phát hành và triển khai

#### EP-04-E · Vận hành luồng

Epic gồm 4 story, 9 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-050 | Là vận hành tỉnh, tôi muốn kích hoạt, tạm dừng, tiếp tục luồng và từng route có lý do, để luồng hoặc route dừng, chạy lại trên mọi bản sao (p95 < 10 s; khẩn < 5 s, NFR-04-010) và không bị Argo CD bật lại. | M | 5 | MVP, W1 | FR-04-050; UC-04-14, 04-15 |
| US-04-051 | Là kỹ sư tích hợp, tôi muốn xem tình trạng runtime của luồng, để người dùng thấy đúng tình trạng thật của luồng ở từng môi trường. | M | 1 | MVP, W1 | FR-04-051; UC-04-02 |
| US-04-052 | Là kỹ sư tích hợp, tôi muốn có danh sách điểm kết nối của luồng và số liệu theo điểm kết nối, để người dùng biết điểm kết nối nào đang lỗi hoặc chậm. | M | 2 | MVP, W1 | FR-04-052; UC-04-02 |
| US-04-053 | Là kỹ sư tích hợp, tôi muốn giám sát theo luồng nhúng từ PH-13, để người dùng theo dõi luồng ngay trên màn chi tiết. | S | 1 | Đợt 2, W4 | FR-04-053; UC-04-02 |

: Story của epic EP-04-E Vận hành luồng

#### EP-04-F · Data plane: khuôn mẫu route chuẩn

Epic gồm 16 story, 37 điểm (16 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-060 | Là quản trị nền tảng, tôi muốn hệ thống có khung chín chặng chuẩn và thư viện nền, để mọi luồng đối ngoại hành xử nhất quán, có vết, chỉ số, nhật ký kết nối mà người thiết kế không phải tự viết. | M | 2 | MVP, W1 | FR-04-060; UC-04-17 |
| US-04-061 | Là HTTT khai thác, tôi muốn tiếp nhận đồng bộ HTTP và SOAP qua APISIX, để HTTT nhận phản hồi đồng bộ trong thời gian chờ đã cấu hình; mọi lượt gọi đều có ngữ cảnh tin cậy và vết. | M | 5 | MVP, W1 | FR-04-061; UC-04-17 |
| US-04-062 | Là HTTT khai thác, tôi muốn tiếp nhận bất đồng bộ từ Kafka, để bản tin được xử lý ít nhất một lần và không có tác dụng trùng. | M | 3 | MVP, W1 | FR-04-062; UC-04-18 |
| US-04-063 | Là kỹ sư tích hợp, tôi muốn hệ thống kiểm tra lược đồ bản tin, để chỉ bản tin đúng cấu trúc đi tiếp; bên gọi biết chính xác trường nào sai. | M | 2 | MVP, W1 | FR-04-063; UC-04-17 |
| US-04-064 | Là kỹ sư tích hợp, tôi muốn hệ thống ủy quyền qua OPA, để chỉ lượt gọi đúng quyền, đúng mục đích được xử lý tiếp. | M | 1 | MVP, W1 | FR-04-064; UC-04-17 |
| US-04-065 | Là kỹ sư tích hợp, tôi muốn hệ thống chuyển đổi, chuẩn hóa về CDM và chuyển mã qua PH-07, để HTTT nhận dữ liệu đúng chuẩn và mã chuẩn. | M | 2 | MVP, W1 | FR-04-065; UC-04-17 |
| US-04-066 | Là kỹ sư tích hợp, tôi muốn hệ thống làm giàu bản tin, để bản tin có đủ dữ liệu cho chặng sau, hoặc đi tiếp có đánh dấu khi nguồn phụ lỗi. | M | 1 | MVP, W1 | FR-04-066; UC-04-17 |
| US-04-067 | Là kỹ sư tích hợp, tôi muốn hệ thống che, giả danh dữ liệu cá nhân theo chính sách PH-09, để bên nhận chỉ thấy dữ liệu được phép. | M | 1 | MVP, W1 | FR-04-067; UC-04-17 |
| US-04-068 | Là kỹ sư tích hợp, tôi muốn hệ thống định tuyến theo nội dung, tách, gộp, gọi song song, gửi đích, để bản tin tới đúng HTTT đích theo nội dung. | M | 2 | Đợt 2, W4 | FR-04-068; UC-04-17 |
| US-04-069 | Là kỹ sư tích hợp, tôi muốn hệ thống phát sự kiện ra Kafka, để bên nhận đăng ký nhận được bản tin có đủ ngữ cảnh. | M | 2 | MVP, W1 | FR-04-069; UC-04-18 |
| US-04-070 | Là kỹ sư tích hợp, tôi muốn hệ thống xử lý lỗi chuẩn: phân loại, thử lại, ngắt mạch, DLQ, dự phòng, để lỗi tạm thời tự hồi phục; lỗi không hồi phục được giữ lại an toàn ở PH-18 để xử lý lại, không mất bản tin. | M | 5 | MVP, W1 | FR-04-070; UC-04-17, 04-18 |
| US-04-071 | Là kỹ sư tích hợp, tôi muốn hệ thống chống trùng bản tin, để hệ đích không nhận tác dụng trùng. | M | 2 | MVP, W1 | FR-04-071; UC-04-18 |
| US-04-072 | Là cán bộ ATTT, tôi muốn hệ thống truy cập CSDL trực tiếp có kiểm soát (Q359), để luồng có dữ liệu cần thiết mà CSDL nguồn không bị ghi nhầm và mọi lượt đọc truy vết được. | M | 3 | MVP, W1 | FR-04-072; UC-04-19 |
| US-04-073 | Là kỹ sư tích hợp, tôi muốn hệ thống có ngữ cảnh tenant trên mỗi bản tin, để không có dữ liệu đi lẫn giữa các tỉnh trên runtime dùng chung. | M | 2 | MVP, W1 | FR-04-073; UC-04-17, 04-18 |
| US-04-074 | Là kỹ sư tích hợp, tôi muốn hệ thống vết, chỉ số, log và nhật ký kết nối, để người vận hành theo dõi và truy vết được mọi lượt; nhật ký kết nối đủ cho báo cáo theo NĐ 278/2025. | M | 2 | MVP, W1 | FR-04-074; UC-04-17 |
| US-04-075 | Là quản trị nền tảng, tôi muốn có hồ sơ runtime, biên dịch native và chế độ JVM, để luồng chạy trên ảnh nhỏ nhất đủ dùng, khởi động nhanh (NFR-04-013). | M | 2 | MVP, W1 | FR-04-075; UC-04-12 |

: Story của epic EP-04-F Data plane: khuôn mẫu route chuẩn

#### EP-04-G · Danh mục thành phần, di trú, kiểm toán, tham số

Epic gồm 5 story, 10 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-04-080 | Là quản trị nền tảng, tôi muốn danh mục thành phần và chính sách thành phần được phép, để tỉnh biết chính xác thành phần nào dùng được; thay đổi chính sách có hiệu lực ngay với bảng thành phần và kiểm tra hợp lệ. | M | 2 | MVP, W1 | FR-04-080; UC-04-21 |
| US-04-081 | Là quản trị nền tảng, tôi muốn khớp phiên bản catalog với runtime, để trình thiết kế và runtime luôn nói cùng một phiên bản Camel. | M | 2 | MVP, W1 | FR-04-081; UC-04-22 |
| US-04-082 | Là kỹ sư tích hợp, tôi muốn chuyển luồng Camel XML của Bus cũ sang YAML, để đội di trú có luồng YAML nháp không chứa bí mật và danh sách việc phải làm tay cho từng luồng cũ. | M | 3 | MVP, W1 | FR-04-082; UC-04-20 |
| US-04-083 | Là kiểm toán viên, tôi muốn có lịch sử thao tác và kiểm toán của luồng, để người dùng truy được mọi thay đổi trên luồng. | M | 1 | MVP, W1 | FR-04-083; UC-04-02 |
| US-04-084 | Là quản trị tỉnh, tôi muốn có tham số PH-04 theo tenant và đóng băng thay đổi, để tỉnh vận hành PH-04 theo tham số riêng và khóa được thay đổi PROD khi cần. | S | 2 | Đợt 2, W4 | FR-04-084 |

: Story của epic EP-04-G Danh mục thành phần, di trú, kiểm toán, tham số

### 6.6. PH-05 · Bộ điều hợp và kết nối

Phân hệ có 8 epic, 62 story, tổng 212 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-03-PH05 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-05-A · Loại kết nối

Epic gồm 1 story, 3 điểm (1 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-001 | Là người dùng có quyền xem, tôi muốn liệt kê loại kết nối và lược đồ tham số, để người dùng thấy đúng các loại được phép dùng ở tỉnh mình, với biểu mẫu tham số tương ứng. | M | 3 | MVP, W1 | FR-05-001; UC-05-01 |

: Story của epic EP-05-A Loại kết nối

#### EP-05-B · Kết nối nguồn và bí mật

Epic gồm 17 story, 67 điểm (16 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-002 | Là người dùng có quyền xem, tôi muốn liệt kê, tìm kiếm và lọc kết nối nguồn, để người dùng tìm được kết nối cần xem trong một hoặc hai thao tác và nhận diện ngay các kết nối có vấn đề. | M | 3 | MVP, W1 | FR-05-002; UC-05-01 |
| US-05-003 | Là người dùng có quyền xem, tôi muốn xem chi tiết kết nối nguồn, để người dùng nắm được tình trạng đầy đủ của kết nối và các thao tác có thể làm tiếp. | M | 2 | MVP, W1 | FR-05-003; UC-05-01 |
| US-05-004 | Là kỹ sư tích hợp, tôi muốn tạo kết nối nguồn, để kết nối nháp xuất hiện trong danh sách với nhãn "Bản nháp"; người dùng tiếp tục khai báo môi trường. | M | 5 | MVP, W1 | FR-05-004; UC-05-01 |
| US-05-005 | Là kỹ sư tích hợp, tôi muốn khai báo giá trị và bí mật theo môi trường, để môi trường có đủ tham số và bí mật, sẵn sàng để kiểm tra. | M | 8 | MVP, W1 | FR-05-005; UC-05-01 |
| US-05-006 | Là kỹ sư tích hợp, tôi muốn sửa thông tin kết nối, để thông tin kết nối được cập nhật; người dùng biết các luồng đang dùng kết nối. | M | 3 | MVP, W1 | FR-05-006; UC-05-06 |
| US-05-007 | Là kỹ sư tích hợp, tôi muốn bật, tắt giá trị môi trường và duyệt bật PROD, để môi trường được bật và luồng ở môi trường đó dùng được kết nối; hoặc môi trường bị tắt ngay khi có sự cố. | M | 8 | MVP, W1 | FR-05-007; UC-05-03 |
| US-05-008 | Là vận hành tỉnh, tôi muốn tạm ngừng, tiếp tục và ngừng dùng kết nối, để kết nối bị chặn ngay khi cần, mở lại an toàn, hoặc được rút khỏi sử dụng mà không làm hỏng luồng. | M | 3 | MVP, W1 | FR-05-008; UC-05-05, 05-06 |
| US-05-009 | Là kỹ sư tích hợp, tôi muốn cấp và thu hồi quyền sử dụng kết nối, để đúng nhóm hoặc đúng luồng dùng được kết nối, ở đúng môi trường được phép. | M | 3 | MVP, W1 | FR-05-009; UC-05-07 |
| US-05-010 | Là kỹ sư tích hợp, tôi muốn kiểm tra kết nối không tác dụng phụ, có hướng dẫn khắc phục, để người dùng biết chắc kết nối dùng được, hoặc biết chính xác bước hỏng và cách khắc phục để gửi đơn vị chủ quản HTTT. | M | 8 | MVP, W1 | FR-05-010; UC-05-02 |
| US-05-011 | Là kỹ sư tích hợp, tôi muốn hệ thống bảo vệ bí mật: ghi một chiều, không hiển thị, không ghi log, để không ai, kể cả quản trị viên, lấy lại được bí mật từ Datahub; lộ bí mật chỉ có thể xảy ra ở phía HTTT. | M | 3 | MVP, W1 | FR-05-011; UC-05-01 |
| US-05-012 | Là vận hành tỉnh, tôi muốn xoay vòng bí mật không gián đoạn, để bí mật mới có hiệu lực, bí mật cũ bị hủy, không lượt gọi nào thất bại vì đổi bí mật. | M | 8 | MVP, W1 | FR-05-012; UC-05-04 |
| US-05-013 | Là người dùng có quyền xem, tôi muốn xem nơi đang dùng kết nối và bộ điều hợp, để người dùng thấy đầy đủ phạm vi ảnh hưởng trước khi thay đổi. | M | 1 | MVP, W1 | FR-05-013; UC-05-06 |
| US-05-014 | Là kỹ sư tích hợp, tôi muốn hệ thống xác minh tham chiếu kết nối cho PH-04, để luồng chỉ phát hành được khi mọi kết nối nó dùng hợp lệ ở môi trường đích. | M | 3 | MVP, W1 | FR-05-014; UC-05-25 |
| US-05-015 | Là kỹ sư tích hợp, tôi muốn hệ thống cung cấp cấu hình kết nối không bí mật cho runtime, để luồng dùng được kết nối ngay sau khi bật, và nhận thay đổi trong vài giây. | M | 2 | MVP, W1 | FR-05-015; UC-05-24 |
| US-05-016 | Là người dùng có quyền xem, tôi muốn xem lịch sử thay đổi, để người dùng truy được nguồn gốc mọi thay đổi. | M | 1 | MVP, W1 | FR-05-016; UC-05-06 |
| US-05-017 | Là người dùng có quyền xem, tôi muốn xuất danh sách kết nối, để người dùng có tệp danh sách kết nối không chứa bí mật. | S | 1 | MVP, W1 | FR-05-017; UC-05-06 |
| US-05-018 | Là kỹ sư tích hợp, tôi muốn nhập ánh xạ kết nối từ hệ cũ, để có danh sách kết nối nháp tương ứng với Bus cũ và bảng ánh xạ để chuyển luồng; Cán bộ ATTT có danh sách vị trí lộ bí mật cần xử lý. | M | 5 | MVP, W1 | FR-05-018; UC-05-11 |

: Story của epic EP-05-B Kết nối nguồn và bí mật

#### EP-05-C · Sức khỏe kết nối

Epic gồm 4 story, 9 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-019 | Là kỹ sư tích hợp, tôi muốn hệ thống kiểm tra sức khỏe chủ động, để cán bộ vận hành thấy kết nối hỏng trong vòng một đến hai chu kỳ, kể cả khi không có luồng nào chạy. | M | 2 | MVP, W1 | FR-05-019; UC-05-12 |
| US-05-020 | Là kỹ sư tích hợp, tôi muốn hệ thống đánh giá sức khỏe thụ động từ lưu lượng thật, để mức sức khỏe phản ánh đúng việc luồng có gọi được HTTT hay không. | M | 2 | MVP, W1 | FR-05-020; UC-05-12 |
| US-05-021 | Là vận hành tỉnh, tôi muốn hệ thống cảnh báo và phát sự kiện khi đổi mức sức khỏe, để TO nhận một cảnh báo khi kết nối PROD hỏng thật, không nhận hàng chục cảnh báo khi chỉ số chập chờn. | M | 3 | MVP, W1 | FR-05-021; UC-05-12 |
| US-05-022 | Là vận hành tỉnh, tôi muốn tổng quan sức khỏe, để cán bộ vận hành biết ngay kết nối nào hỏng, hỏng bao lâu và việc tồn đọng (bí mật, CDC, lược đồ). | M | 2 | MVP, W1 | FR-05-022; UC-05-12 |

: Story của epic EP-05-C Sức khỏe kết nối

#### EP-05-D · CSDL cho luồng (Q359)

Epic gồm 6 story, 27 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-023 | Là kỹ sư tích hợp, tôi muốn khai báo kết nối CSDL cho luồng, để kết nối sẵn sàng để cấp tài khoản theo luồng (FR-05-024). | M | 5 | MVP, W1 | FR-05-023; UC-05-08 |
| US-05-024 | Là kỹ sư tích hợp, tôi muốn cấp tài khoản CSDL chỉ đọc theo luồng, để luồng đọc được đúng bảng đã xin, không cần ai nhập mật khẩu CSDL vào luồng. | M | 5 | MVP, W1 | FR-05-024; UC-05-08 |
| US-05-025 | Là kỹ sư tích hợp, tôi muốn kiểm tra quyền thực tế của tài khoản CSDL, để SO có bằng chứng tài khoản luồng chỉ đọc đúng phạm vi; giá trị môi trường không bật được nếu tài khoản có quyền vượt. | M | 3 | MVP, W1 | FR-05-025; UC-05-08 |
| US-05-026 | Là kỹ sư tích hợp, tôi muốn đề nghị, đồng ý và duyệt mục đích ghi vào CSDL, để luồng ghi được đúng bảng, đúng thao tác, trong thời hạn đã duyệt; hết hạn thì tự mất quyền. | M | 8 | MVP, W1 | FR-05-026; UC-05-09 |
| US-05-027 | Là cán bộ ATTT, tôi muốn kiểm toán truy cập CSDL của luồng, để SO và kiểm toán viên truy được mọi lần luồng chạm CSDL của HTTT. | M | 3 | MVP, W1 | FR-05-027; UC-05-10 |
| US-05-028 | Là kỹ sư tích hợp, tôi muốn thu hồi tài khoản CSDL, để luồng không còn đọc hoặc ghi được CSDL bằng tài khoản đó. | M | 3 | MVP, W1 | FR-05-028; UC-05-05, 05-09 |

: Story của epic EP-05-D CSDL cho luồng (Q359)

#### EP-05-E · Bộ điều hợp theo giao thức

Epic gồm 19 story, 68 điểm (15 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-029 | Là kỹ sư tích hợp, tôi muốn liệt kê bộ điều hợp kèm sức khỏe, để người dùng thấy bộ điều hợp cần xử lý trước ở đầu danh sách. | M | 3 | MVP, W1 | FR-05-029; UC-05-13 |
| US-05-030 | Là kỹ sư tích hợp, tôi muốn xem chi tiết bộ điều hợp và phiên bản, để người duyệt thấy chính xác thay đổi giữa hai phiên bản; cán bộ vận hành thấy ai bị ảnh hưởng nếu tạm dừng. | M | 2 | MVP, W1 | FR-05-030; UC-05-13 |
| US-05-031 | Là kỹ sư tích hợp, tôi muốn tạo và sửa bộ điều hợp, để có khung bộ điều hợp để khai báo thao tác; chưa ảnh hưởng luồng nào. | M | 5 | MVP, W1 | FR-05-031; UC-05-13 |
| US-05-032 | Là kỹ sư tích hợp, tôi muốn khai báo thao tác của bộ điều hợp, để thao tác sẵn sàng để kiểm thử (FR-05-043). | M | 3 | MVP, W1 | FR-05-032; UC-05-13 |
| US-05-033 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp REST/HTTP, để luồng nhận đủ dữ liệu của mọi trang, hoặc một lỗi rõ ràng; không bao giờ nhận dữ liệu thiếu mà không biết. | M | 5 | MVP, W1 | FR-05-033; UC-05-13, 05-24 |
| US-05-034 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp SOAP, để luồng gọi dịch vụ SOAP như gọi một API JSON; IE biết ngay khi HTTT đổi WSDL. | M | 5 | MVP, W1 | FR-05-034; UC-05-14 |
| US-05-035 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp hàng đợi bản tin (JMS, AMQP, MQTT, Kafka ngoài), để bản tin không mất khi luồng lỗi giữa chừng, vì chỉ xác nhận sau khi xử lý xong. | M | 2 | MVP, W1 | FR-05-035; UC-05-16 |
| US-05-036 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp tệp và SFTP, FTPS, thư mục chia sẻ, để mỗi tệp được xử lý đúng một lần về mặt nghiệp vụ; tệp lỗi nằm ở thư mục lỗi kèm lý do để đơn vị gửi sửa. | M | 5 | MVP, W1 | FR-05-036; UC-05-15 |
| US-05-037 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp thư điện tử, để luồng trao đổi được qua thư mà không có đính kèm độc hại lọt vào. | S | 5 | Đợt 3, W5 | FR-05-037; UC-05-16 |
| US-05-038 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp CSDL theo truy vấn khai báo, để luồng đọc được dữ liệu cần mà bên gọi không bao giờ đưa được câu lệnh của riêng mình vào. | M | 5 | MVP, W1 | FR-05-038; UC-05-08 |
| US-05-039 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp LDAP, để luồng lấy được thông tin cán bộ từ danh bạ của HTTT. | C | 2 | Đợt 3, W5 | FR-05-039 |
| US-05-040 | Là kỹ sư tích hợp, tôi muốn chuyển đổi định dạng về JSON chuẩn, để người thiết kế luồng làm việc với một dạng dữ liệu duy nhất, đã đúng kiểu ngày, số và Unicode. | M | 3 | MVP, W1 | FR-05-040; UC-05-14 |
| US-05-041 | Là kỹ sư tích hợp, tôi muốn chuẩn hóa giá trị thiếu và giá trị đặc biệt, để UI-05-09 hiện tỷ lệ thiếu theo trường; PH-08 dùng chỉ số để đánh giá chất lượng nguồn (Đợt 3). | M | 1 | MVP, W1 | FR-05-041; UC-05-15 |
| US-05-042 | Là kỹ sư tích hợp, tôi muốn nhóm kết nối và giới hạn đồng thời theo HTTT, để HTTT không bao giờ nhận quá số kết nối đã thỏa thuận, kể cả khi runtime tự mở rộng. | M | 2 | MVP, W1 | FR-05-042; UC-05-15, 05-24 |
| US-05-043 | Là kỹ sư tích hợp, tôi muốn kiểm thử bộ điều hợp, để IE biết thao tác nào đạt, thao tác nào hỏng và phải sửa gì; kiểm thử đạt mọi thao tác trong 24 giờ là điều kiện gửi duyệt (BR-05-006). | M | 3 | MVP, W1 | FR-05-043; UC-05-17 |
| US-05-044 | Là kỹ sư tích hợp, tôi muốn gửi duyệt, duyệt phiên bản; tạm dừng, tiếp tục, ngừng dùng bộ điều hợp, để sau khi duyệt, thao tác xuất hiện trong trình thiết kế; khi tạm dừng, luồng ngừng gọi HTTT trong 30 giây. | M | 8 | MVP, W1 | FR-05-044; UC-05-17 |
| US-05-045 | Là kỹ sư tích hợp, tôi muốn có phiên bản bộ điều hợp và chế độ so sánh, để người duyệt có số liệu khớp thật thay vì chỉ đọc khác biệt cấu hình. | S | 3 | Đợt 3, W5 | FR-05-045; UC-05-18 |
| US-05-046 | Là kỹ sư tích hợp, tôi muốn sinh bộ điều hợp nháp từ OpenAPI hoặc WSDL, để IE có bộ điều hợp nháp đủ thao tác trong vài phút, chỉ cần kiểm thử và gửi duyệt. | S | 3 | MVP, W1 | FR-05-046; UC-05-13 |
| US-05-047 | Là kỹ sư tích hợp, tôi muốn hệ thống đưa bộ điều hợp vào bảng thành phần của trình thiết kế, để người thiết kế kéo thao tác "Tra cứu hồ sơ" của HTTT vào luồng như mọi thành phần khác. | M | 3 | MVP, W1 | FR-05-047; UC-05-17, 05-25 |

: Story của epic EP-05-E Bộ điều hợp theo giao thức

#### EP-05-F · CDC cho hệ di sản

Epic gồm 6 story, 19 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-048 | Là kỹ sư tích hợp, tôi muốn khai báo cấu hình CDC, để có cấu hình CDC sẵn sàng chạy; luồng PH-04 thấy trước các topic để thiết kế tiêu thụ. | M | 3 | MVP, W1 | FR-05-048; UC-05-19 |
| US-05-049 | Là kỹ sư tích hợp, tôi muốn kiểm tra điều kiện CDC ở CSDL nguồn, để IE có văn bản cụ thể để đề nghị đơn vị chủ quản cấu hình CSDL. | M | 1 | MVP, W1 | FR-05-049; UC-05-19 |
| US-05-050 | Là vận hành tỉnh, tôi muốn chạy, tạm dừng, tiếp tục và dừng CDC, để TO dừng hoặc chạy lại CDC mà không mất thay đổi nào đã xảy ra ở nguồn trong thời gian dừng (trong giới hạn giữ nhật ký). | M | 5 | MVP, W1 | FR-05-050; UC-05-19 |
| US-05-051 | Là kỹ sư tích hợp, tôi muốn hệ thống giám sát và xử lý thay đổi lược đồ, để luồng tiêu thụ không bao giờ nhận bản ghi theo lược đồ mới mà chưa có người quyết định. | M | 3 | MVP, W1 | FR-05-051; UC-05-20 |
| US-05-052 | Là vận hành tỉnh, tôi muốn theo dõi trạng thái CDC, để TO thấy CDC trễ trước khi người dùng nghiệp vụ phàn nàn dữ liệu cũ. | M | 2 | MVP, W1 | FR-05-052; UC-05-19 |
| US-05-053 | Là vận hành tỉnh, tôi muốn chụp ảnh lại dữ liệu nguồn, để luồng tiêu thụ có lại đủ dữ liệu của bảng mà HTTT không bị khóa bảng. | S | 5 | MVP, W1 | FR-05-053; UC-05-20 |

: Story của epic EP-05-F CDC cho hệ di sản

#### EP-05-G · Danh mục Kamelet được duyệt

Epic gồm 7 story, 16 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-054 | Là kỹ sư tích hợp, tôi muốn liệt kê danh mục Kamelet, để kỹ sư chọn đúng thành phần trước khi thiết kế luồng, tránh tạo Kamelet trùng. | M | 2 | MVP, W1 | FR-05-054; UC-05-21 |
| US-05-055 | Là kỹ sư tích hợp, tôi muốn xem chi tiết Kamelet, để người duyệt và người dùng thấy cùng một nguồn sự thật về Kamelet. | M | 1 | MVP, W1 | FR-05-055; UC-05-21 |
| US-05-056 | Là kỹ sư tích hợp, tôi muốn soạn, kiểm tra tĩnh và gửi đăng ký Kamelet, để IE biết chính xác dòng nào vi phạm quy tắc nào và sửa ngay trong trình soạn. | M | 3 | MVP, W1 | FR-05-056; UC-05-21 |
| US-05-057 | Là người duyệt tích hợp, tôi muốn duyệt hoặc từ chối Kamelet, để Kamelet được duyệt xuất hiện trong trình thiết kế của tỉnh (hoặc mọi tỉnh với `COMMON`). | M | 3 | MVP, W1 | FR-05-057; UC-05-21 |
| US-05-058 | Là người dùng, tôi muốn ngừng khuyến nghị và thu hồi Kamelet, để không luồng mới nào dùng được Kamelet lỗi; chủ sở hữu luồng cũ biết phải đổi. | M | 3 | MVP, W1 | FR-05-058; UC-05-22 |
| US-05-059 | Là kỹ sư tích hợp, tôi muốn hệ thống đồng bộ danh mục Kamelet với catalog trình thiết kế và runtime, để không có Kamelet chưa duyệt nào chạy được ở runtime. | M | 2 | MVP, W1 | FR-05-059; UC-05-21 |
| US-05-060 | Là kỹ sư tích hợp, tôi muốn đề xuất Kamelet của tỉnh thành dùng chung, để các tỉnh khác dùng được Kamelet mà không phải viết lại. | S | 2 | Đợt 3, W5 | FR-05-060; UC-05-23 |

: Story của epic EP-05-G Danh mục Kamelet được duyệt

#### EP-05-H · Quản trị

Epic gồm 2 story, 3 điểm (1 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-05-061 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để tham số có hiệu lực trong tối đa 60 giây. | M | 2 | MVP, W1 | FR-05-061; UC-05-26 |
| US-05-062 | Là quản trị tỉnh, tôi muốn có báo cáo sử dụng kết nối và bộ điều hợp, để có số liệu chính thức để báo cáo tiến độ kết nối HTTT của tỉnh. | S | 1 | MVP, W1 | FR-05-062; UC-05-26 |

: Story của epic EP-05-H Quản trị

### 6.7. PH-06 · Dữ liệu chủ

Phân hệ có 8 epic, 60 story, tổng 183 điểm; wave phát triển W4–W5, đợt Đợt 3. Nguồn: D02-03-PH06 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-06-A · Mô hình domain dữ liệu chủ

Epic gồm 7 story, 20 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-001 | Là người dùng có quyền xem, tôi muốn liệt kê và xem domain dữ liệu chủ, để người dùng thấy danh sách domain và mô hình hiện hành, mở được JSON Schema để gửi cho đơn vị chủ quản nguồn. | M | 2 | Đợt 3, W4–W5 | FR-06-001; UC-06-01 |
| US-06-002 | Là quản trị tỉnh, tôi muốn soạn mô hình domain với thuộc tính có kiểu, để bản nháp sẵn sàng gán khóa, phân loại và gửi duyệt. | M | 3 | Đợt 3, W4–W5 | FR-06-002; UC-06-02 |
| US-06-003 | Là quản trị tỉnh, tôi muốn khai báo khóa định danh và quy tắc kiểm tra, để người dùng biết chắc giá trị nào được hệ thống coi là khóa hợp lệ trước khi bật. | M | 3 | Đợt 3, W4–W5 | FR-06-003; UC-06-02 |
| US-06-004 | Là quản trị tỉnh, tôi muốn gán phân loại dữ liệu cho thuộc tính theo PH-09, để mô hình có phân loại đủ, PH-09 thấy được trường nào của PH-06 là DLCN. | M | 3 | Đợt 3, W4–W5 | FR-06-004; UC-06-02 |
| US-06-005 | Là quản trị tỉnh, tôi muốn quản lý phiên bản mô hình và kiểm tra tương thích, để người duyệt thấy danh sách thay đổi tô màu theo mức phá vỡ và số đối tượng bị ảnh hưởng. | S | 1 | Đợt 3, W4–W5 | FR-06-005; UC-06-02 |
| US-06-006 | Là quản trị tỉnh, tôi muốn gửi duyệt, kích hoạt, tạm ngừng và ngừng domain, để mô hình mới có hiệu lực ngay cho bản ghi nạp sau thời điểm kích hoạt. | M | 5 | Đợt 3, W4–W5 | FR-06-006; UC-06-03 |
| US-06-007 | Là quản trị nền tảng, tôi muốn nạp gói domain nền CITIZEN, ORGANIZATION, ADDRESS, để tỉnh có ba domain với thuộc tính chuẩn theo bảng ở FR gốc, chưa nhận dữ liệu cho tới khi bộ quy tắc được kích hoạt. | M | 3 | Đợt 3, W4–W5 | FR-06-007; UC-06-01 |

: Story của epic EP-06-A Mô hình domain dữ liệu chủ

#### EP-06-B · Nguồn và nạp bản ghi ứng viên

Epic gồm 10 story, 34 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-008 | Là quản trị tỉnh, tôi muốn đăng ký nguồn dữ liệu chủ gắn HTTT, để nguồn xuất hiện trong danh sách, chờ duyệt thứ tự ưu tiên. | M | 3 | Đợt 3, W4–W5 | FR-06-008; UC-06-04 |
| US-06-009 | Là quản trị tỉnh, tôi muốn khai báo mức tin cậy và thứ tự ưu tiên nguồn có phê duyệt, để thứ tự ưu tiên có hiệu lực với căn cứ văn bản hiển thị ở UI-06-08 và ở lineage. | M | 5 | Đợt 3, W4–W5 | FR-06-009; UC-06-04 |
| US-06-010 | Là HTTT khai thác, tôi muốn nạp bản ghi ứng viên qua API, để HTTT biết ngay bản ghi nào được nhận, bản ghi nào sai và vì sao. | M | 5 | Đợt 3, W4–W5 | FR-06-010; UC-06-05 |
| US-06-011 | Là kỹ sư tích hợp, tôi muốn hệ thống nạp bản ghi ứng viên qua luồng PH-04, để dữ liệu từ hệ không có API vẫn vào được bản ghi vàng, truy được tới lượt chạy luồng. | M | 5 | Đợt 3, W4–W5 | FR-06-011; UC-06-05 |
| US-06-012 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống nạp bản ghi ứng viên qua sự kiện PH-10, để sự kiện nghiệp vụ tự cập nhật bản ghi vàng, HTTT nguồn không phải làm gì thêm. | S | 3 | Đợt 3, W4–W5 | FR-06-012; UC-06-05 |
| US-06-013 | Là cán bộ quản lý dữ liệu, tôi muốn nạp tệp lô có xem trước, để người dùng thấy trước dữ liệu sẽ vào ra sao và chỉ ghi khi đã xác nhận. | M | 3 | Đợt 3, W4–W5 | FR-06-013; UC-06-06 |
| US-06-014 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống chuẩn hóa họ tên, ngày, số định danh, để hai cách viết "NGUYEN VAN A" và "Nguyễn Văn A" cho cùng `nameAscii`. | M | 3 | Đợt 3, W4–W5 | FR-06-014; UC-06-07 |
| US-06-015 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống chuẩn hóa địa chỉ theo ĐVHC của PH-07, để địa chỉ của mọi nguồn dùng chung một bộ mã hiện hành. | M | 2 | Đợt 3, W4–W5 | FR-06-015; UC-06-07 |
| US-06-016 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống chống trùng, thứ tự phiên bản nguồn và xóa từ nguồn, để nguồn gửi lại thoải mái khi mạng lỗi mà không sinh trùng. | M | 3 | Đợt 3, W4–W5 | FR-06-016; UC-06-05 |
| US-06-017 | Là cán bộ quản lý dữ liệu, tôi muốn xem bản ghi ứng viên và xử lý ứng viên lỗi, để người quản lý biết chính xác nguồn nào gửi dữ liệu lỗi, lỗi gì. | M | 2 | Đợt 3, W4–W5 | FR-06-017; UC-06-07 |

: Story của epic EP-06-B Nguồn và nạp bản ghi ứng viên

#### EP-06-C · Đối sánh

Epic gồm 9 story, 26 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-018 | Là quản trị tỉnh, tôi muốn quản lý bộ quy tắc đối sánh có phiên bản, để bộ quy tắc mới có hiệu lực cho mọi lượt đối sánh sau thời điểm duyệt; kết quả cũ giữ phiên bản quy tắc đã dùng. | M | 5 | Đợt 3, W4–W5 | FR-06-018; UC-06-08, 06-09 |
| US-06-019 | Là quản trị tỉnh, tôi muốn có cấu hình khóa gom nhóm và theo dõi hiệu quả, để người cấu hình thấy ngay khóa có hiệu quả và có làm sót cặp đúng hay không. | M | 2 | Đợt 3, W4–W5 | FR-06-019; UC-06-08 |
| US-06-020 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống đối sánh xác định theo khóa định danh, để bản ghi có CCCD hợp lệ được gắn đúng người trong thời gian p99 ≤ 30 ms (NFR-06-002). | M | 2 | Đợt 3, W4–W5 | FR-06-020; UC-06-10 |
| US-06-021 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống đối sánh xác suất trực tuyến, để bản ghi "Nguyen Van A, 15/01/1990, xã 00004" từ `HT-GIAODUC` được gắn đúng bản ghi vàng có CCCD với điểm 0,94. | M | 2 | Đợt 3, W4–W5 | FR-06-021; UC-06-10 |
| US-06-022 | Là quản trị tỉnh, tôi muốn chạy job đối sánh theo lô bằng Splink, để dữ liệu lịch sử của nhiều nguồn được khử trùng một lần, các cặp nghi ngờ vào hàng đợi. | M | 5 | Đợt 3, W4–W5 | FR-06-022; UC-06-11 |
| US-06-023 | Là quản trị tỉnh, tôi muốn có cấu hình ngưỡng tự hợp nhất, xem xét, khác biệt, để người cấu hình chọn ngưỡng có số liệu, không đoán. | M | 2 | Đợt 3, W4–W5 | FR-06-023; UC-06-08 |
| US-06-024 | Là quản trị tỉnh, tôi muốn chạy thử bộ quy tắc trên mẫu, để người cấu hình biết tác động của thay đổi trước khi gửi duyệt. | S | 3 | Đợt 3, W4–W5 | FR-06-024; UC-06-09 |
| US-06-025 | Là cán bộ quản lý dữ liệu, tôi muốn quản lý tập nhãn kiểm chứng, để tỉnh có thước đo độ chính xác riêng, dựng dần từ chính công việc hằng ngày. | M | 2 | Đợt 3, W4–W5 | FR-06-025; UC-06-09 |
| US-06-026 | Là quản trị tỉnh, tôi muốn đo precision, recall và chặn kích hoạt quy tắc kém, để hội đồng, DA thấy số đo cụ thể chứ không phải lời hứa về độ chính xác. | M | 3 | Đợt 3, W4–W5 | FR-06-026; UC-06-09 |

: Story của epic EP-06-C Đối sánh

#### EP-06-D · Hàng đợi người quản lý dữ liệu

Epic gồm 6 story, 16 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-027 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống tạo mục hàng đợi và tính mức ưu tiên, để người quản lý thấy việc đã xếp đúng mức khẩn. | M | 2 | Đợt 3, W4–W5 | FR-06-027; UC-06-12 |
| US-06-028 | Là cán bộ quản lý dữ liệu, tôi muốn liệt kê, nhận việc và phân công mục hàng đợi, để mỗi người có hàng việc riêng, không ai xử lý trùng. | M | 2 | Đợt 3, W4–W5 | FR-06-028; UC-06-12 |
| US-06-029 | Là người duyệt danh mục, tôi muốn so sánh cạnh nhau hai bản ghi, để người quản lý thấy điểm giống, điểm khác trong một màn, đủ để quyết định trong vài chục giây. | M | 2 | Đợt 3, W4–W5 | FR-06-029; UC-06-13 |
| US-06-030 | Là người đang nhận mục, tôi muốn quyết định khớp, không khớp, hoãn, để quyết định có hiệu lực ngay (rủi ro thấp) hoặc chờ duyệt (rủi ro cao); người dùng làm tiếp mục sau không phải quay về danh sách. | M | 5 | Đợt 3, W4–W5 | FR-06-030; UC-06-13 |
| US-06-031 | Là người duyệt danh mục, tôi muốn duyệt bốn mắt hợp nhất rủi ro cao, để hợp nhất rủi ro cao chỉ có hiệu lực khi hai người đồng ý. | M | 3 | Đợt 3, W4–W5 | FR-06-031; UC-06-14 |
| US-06-032 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống theo dõi SLA, nâng ưu tiên và cảnh báo quá tải, để trưởng nhóm thấy ngay mục quá hạn và nguồn gây tải. | M | 2 | Đợt 3, W4–W5 | FR-06-032; UC-06-12 |

: Story của epic EP-06-D Hàng đợi người quản lý dữ liệu

#### EP-06-E · Bản ghi vàng

Epic gồm 10 story, 32 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-033 | Là quản trị tỉnh, tôi muốn có cấu hình quy tắc sống sót thuộc tính, để mỗi thuộc tính có quy tắc chọn giá trị rõ ràng, hiển thị được ở lineage. | M | 5 | Đợt 3, W4–W5 | FR-06-033; UC-06-15 |
| US-06-034 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống tạo và cập nhật bản ghi vàng tự động, để bản ghi vàng phản ánh giá trị tốt nhất hiện có từ mọi nguồn. | M | 3 | Đợt 3, W4–W5 | FR-06-034; UC-06-10 |
| US-06-035 | Là cán bộ quản lý dữ liệu, tôi muốn xem chi tiết bản ghi vàng, để người quản lý thấy ngay thuộc tính nào từ nguồn nào, nguồn nào kém tin cậy. | M | 2 | Đợt 3, W4–W5 | FR-06-035; UC-06-16 |
| US-06-036 | Là cán bộ quản lý dữ liệu, tôi muốn sửa tay thuộc tính có lý do, để giá trị đúng có hiệu lực ngay, nguồn nhận yêu cầu sửa gốc. | S | 5 | Đợt 3, W4–W5 | FR-06-036; UC-06-17 |
| US-06-037 | Là cán bộ quản lý dữ liệu, tôi muốn hợp nhất bản ghi vàng thủ công, để một bản ghi vàng duy nhất; HTTT tra `goldenId` cũ được chuyển hướng. | M | 5 | Đợt 3, W4–W5 | FR-06-037; UC-06-18 |
| US-06-038 | Là cán bộ quản lý dữ liệu, tôi muốn tách bản ghi vàng, để hồ sơ của hai người bị trộn được tách lại, mỗi người một bản ghi vàng. | M | 3 | Đợt 3, W4–W5 | FR-06-038; UC-06-19 |
| US-06-039 | Là cán bộ quản lý dữ liệu, tôi muốn hoàn tác thao tác trên bản ghi vàng, để bản ghi trở về như trước thao tác sai, dữ liệu nguồn mới không mất. | M | 3 | Đợt 3, W4–W5 | FR-06-039; UC-06-20 |
| US-06-040 | Là cán bộ quản lý dữ liệu, tôi muốn ngừng và khôi phục bản ghi vàng, để bản ghi không còn xuất hiện trong tìm kiếm mặc định, vẫn truy được lịch sử. | M | 2 | Đợt 3, W4–W5 | FR-06-040; UC-06-17 |
| US-06-041 | Là cán bộ quản lý dữ liệu, tôi muốn xem lịch sử phiên bản và so sánh hai phiên bản, để người quản lý dựng lại được mọi thời điểm của bản ghi. | M | 2 | Đợt 3, W4–W5 | FR-06-041; UC-06-16 |
| US-06-042 | Là quản trị tỉnh, tôi muốn xem trước tác động và áp lại sống sót hàng loạt, để thay đổi quản lý có tác động đo trước, áp có kiểm soát. | S | 2 | Đợt 3, W4–W5 | FR-06-042; UC-06-15 |

: Story của epic EP-06-E Bản ghi vàng

#### EP-06-F · Truy xuất nguồn gốc và liên kết chéo nguồn

Epic gồm 3 story, 7 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-043 | Là cán bộ quản lý dữ liệu, tôi muốn truy xuất nguồn gốc từng thuộc tính, để cán bộ trả lời được ngay "giá trị ngày sinh hiện tại lấy từ CSDL dân cư; trước đó hệ y tế ghi khác", và biết đề nghị sửa ở đâu. | M | 2 | Đợt 3, W4–W5 | FR-06-043; UC-06-16 |
| US-06-044 | Là cán bộ quản lý dữ liệu, tôi muốn xem và gỡ liên kết chéo nguồn, để liên kết sai được gỡ mà không ảnh hưởng các nguồn khác của bản ghi. | M | 3 | Đợt 3, W4–W5 | FR-06-044; UC-06-19 |
| US-06-045 | Là HTTT khai thác, tôi muốn tra ID nguồn và ID vàng, để HTTT y tế biết bệnh nhân BN-123 là cùng người với học sinh HS-456 của hệ giáo dục, không cần trao đổi họ tên, ngày sinh. | M | 2 | Đợt 3, W4–W5 | FR-06-045; UC-06-21 |

: Story của epic EP-06-F Truy xuất nguồn gốc và liên kết chéo nguồn

#### EP-06-G · Cung cấp dữ liệu và đồng bộ quốc gia

Epic gồm 9 story, 32 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-046 | Là HTTT khai thác, tôi muốn tra cứu bản ghi vàng theo ID hoặc khóa định danh, để bên gọi nhận dữ liệu chủ đã hợp nhất, biết giá trị nào đáng tin. | M | 3 | Đợt 3, W4–W5 | FR-06-046; UC-06-21 |
| US-06-047 | Là HTTT khai thác, tôi muốn giải quyết bản ghi trực tuyến (resolve), để bên gọi biết chắc khi nào được dùng kết quả: `202` nghĩa là chưa có kết luận, không được ghi dữ liệu theo kết quả đó. | M | 5 | Đợt 3, W4–W5 | FR-06-047; UC-06-22 |
| US-06-048 | Là người dùng, tôi muốn tìm kiếm bản ghi vàng theo thuộc tính, để người quản lý tìm được bản ghi cần xử lý; không ai duyệt được toàn bộ dữ liệu công dân qua tìm kiếm. | M | 3 | Đợt 3, W4–W5 | FR-06-048; UC-06-21 |
| US-06-049 | Là cán bộ quản lý dữ liệu, tôi muốn xuất dữ liệu chủ có kiểm soát, để dữ liệu ra khỏi Datahub chỉ khi chủ quản đồng ý, đúng trường, có thủy vân. | M | 3 | Đợt 3, W4–W5 | FR-06-049; UC-06-23 |
| US-06-050 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống phát sự kiện thay đổi bản ghi vàng, để HTTT biết có thay đổi để tra lại qua API có kiểm soát. | M | 2 | Đợt 3, W4–W5 | FR-06-050; UC-06-24 |
| US-06-051 | Là quản trị tỉnh, tôi muốn đăng ký nhận cập nhật cho HTTT, để HTTT nhận đúng sự kiện về công dân, tổ chức của mình, không nhận toàn bộ. | S | 2 | Đợt 3, W4–W5 | FR-06-051; UC-06-24 |
| US-06-052 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống che dữ liệu theo phân loại và mục đích PH-09, để không đường nào lộ giá trị nhạy cảm ngoài mục đích được chấp thuận. | M | 3 | Đợt 3, W4–W5 | FR-06-052; UC-06-21 |
| US-06-053 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ với CSDL tổng hợp quốc gia qua PH-14, để bản ghi vàng luôn theo CSDL quốc gia cho nhân thân; tỉnh thấy ngay khi có lệch bất thường. | M | 8 | Đợt 3, W4–W5 | FR-06-053; UC-06-25 |
| US-06-054 | Là cán bộ quản lý dữ liệu, tôi muốn xử lý danh sách lệch đồng bộ quốc gia, để mỗi lệch có kết luận, giải trình được. | M | 3 | Đợt 3, W4–W5 | FR-06-054; UC-06-25 |

: Story của epic EP-06-G Cung cấp dữ liệu và đồng bộ quốc gia

#### EP-06-H · Vận hành

Epic gồm 6 story, 16 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-06-055 | Là người dùng có quyền xem, tôi muốn có dashboard chỉ số dữ liệu chủ, để người xem thấy ngay "tỷ lệ tự động 88%, hàng đợi 142 mục, 3 mục quá hạn, lệch quốc gia 0,4%". | M | 1 | Đợt 3, W4–W5 | FR-06-055; UC-06-26 |
| US-06-056 | Là quản trị tỉnh, tôi muốn có lịch job, chạy lại và hủy job, để job chạy đúng giờ thấp điểm; lỗi được chạy lại không phải chạy lại toàn bộ. | M | 3 | Đợt 3, W4–W5 | FR-06-056; UC-06-26 |
| US-06-057 | Là quản trị tỉnh, tôi muốn có nhật ký xử lý và nhật ký truy cập, để mọi lượt xem dữ liệu chủ đều có dấu vết không sửa được. | M | 2 | Đợt 3, W4–W5 | FR-06-057; UC-06-26 |
| US-06-058 | Là cán bộ quản lý dữ liệu, tôi muốn tiếp nhận và xử lý yêu cầu của chủ thể dữ liệu, để công dân biết ai giữ và dùng dữ liệu của mình, sửa được dữ liệu sai đúng nơi. | M | 5 | Đợt 3, W4–W5 | FR-06-058; UC-06-27 |
| US-06-059 | Là quản trị tỉnh, tôi muốn có chính sách lưu giữ và dọn dữ liệu, để dữ liệu trung gian chứa DLCN không tồn đọng quá thời hạn. | M | 3 | Đợt 3, W4–W5 | FR-06-059; UC-06-28 |
| US-06-060 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để tỉnh điều chỉnh SLA, ngưỡng cảnh báo phù hợp nhân lực của mình. | M | 2 | Đợt 3, W4–W5 | FR-06-060; UC-06-28 |

: Story của epic EP-06-H Vận hành

### 6.8. PH-07 · Danh mục dùng chung

Phân hệ có 8 epic, 53 story, tổng 221 điểm; wave phát triển W2, đợt MVP. Nguồn: D02-03-PH07 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-07-A · Danh mục và lược đồ

Epic gồm 10 story, 48 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-001 | Là người dùng có quyền xem, tôi muốn liệt kê danh mục, đếm số lượng, lọc theo nhóm, nguồn, trạng thái, phân loại, để người dùng thấy danh sách danh mục mình được xem, kèm số lượng theo nguồn, trạng thái, phân loại và nhóm; bộ lọc giữ trên URL để chia sẻ hoặc quay lại. | M | 3 | MVP, W2 | FR-07-001; UC-07-01 |
| US-07-002 | Là người dùng có quyền xem, tôi muốn xem chi tiết danh mục: thông tin, thuộc tính, phiên bản, bản ghi, để người dùng xem trên một màn toàn bộ thông tin, lược đồ, phiên bản, bản ghi của danh mục và biết phiên bản nào đang hiệu lực. | M | 3 | MVP, W2 | FR-07-002; UC-07-01 |
| US-07-003 | Là cán bộ quản lý dữ liệu, tôi muốn tạo danh mục thủ công, để danh mục mới xuất hiện trong danh sách với nhãn "Bản nháp" và bản nháp phiên bản 1 mở sẵn để nhập bản ghi. | M | 8 | MVP, W2 | FR-07-003; UC-07-01, 07-04 |
| US-07-004 | Là cán bộ quản lý dữ liệu, tôi muốn cập nhật thông tin danh mục, để thông tin mới hiện ngay trên chi tiết danh mục; mỗi lần sửa có một dòng trong tab Lịch sử. | M | 5 | MVP, W2 | FR-07-004; UC-07-01 |
| US-07-005 | Là cán bộ quản lý dữ liệu, tôi muốn khai báo thuộc tính động có kiểu và ràng buộc, để thuộc tính mới xuất hiện trong lược đồ của bản nháp và thành một cột trong trình sửa bản ghi, có kiểm tra theo kiểu và ràng buộc đã khai. | M | 8 | MVP, W2 | FR-07-005; UC-07-01, 07-04 |
| US-07-006 | Là cán bộ quản lý dữ liệu, tôi muốn sửa, ẩn, xóa, sắp thứ tự thuộc tính trong bản nháp có kiểm tra tương thích, để lược đồ bản nháp được cập nhật; người dùng biết trước thay đổi nào sẽ được phân loại phá vỡ khi trình duyệt. | M | 5 | MVP, W2 | FR-07-006; UC-07-01 |
| US-07-007 | Là cán bộ quản lý dữ liệu, tôi muốn có cấu hình phân cấp, để trình sửa bản ghi có thêm cột Mã cha và chế độ xem cây; HTTT lấy được cây, nhánh con qua FR-07-029. | M | 3 | MVP, W2 | FR-07-007; UC-07-01 |
| US-07-008 | Là quản trị tỉnh, tôi muốn thiết lập nguồn và quyền cập nhật, để danh mục biết ai được cập nhật nó; người, HTTT không có quyền thấy danh mục ở chế độ chỉ đọc. | M | 3 | MVP, W2 | FR-07-008; UC-07-01, 07-17 |
| US-07-009 | Là cán bộ quản lý dữ liệu, tôi muốn xóa danh mục chưa phát hành; ngừng hiệu lực danh mục đã phát hành, để danh mục biến khỏi danh sách mặc định (xóa) hoặc mang nhãn "Ngừng hiệu lực" (ngừng); HTTT nhận sự kiện để ngừng dùng. | M | 8 | MVP, W2 | FR-07-009; UC-07-14 |
| US-07-010 | Là quản trị tỉnh, tôi muốn quản lý nhóm danh mục, để cây nhóm mới hiện ngay ở UI-07-01 cho mọi người trong tỉnh; danh mục được sắp theo nhóm. | S | 2 | Đợt 2, W4 | FR-07-010; UC-07-01 |

: Story của epic EP-07-A Danh mục và lược đồ

#### EP-07-B · Bản ghi và phiên bản

Epic gồm 9 story, 39 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-011 | Là cán bộ quản lý dữ liệu, tôi muốn tạo bản nháp phiên bản mới từ phiên bản hiện hành, để bản nháp mới chứa bản sao lược đồ và bản ghi của phiên bản hiện hành, mở sẵn trong UI-07-05 để sửa. | M | 5 | MVP, W2 | FR-07-011; UC-07-02 |
| US-07-012 | Là cán bộ quản lý dữ liệu, tôi muốn thêm, sửa, ngừng dùng bản ghi trên bản nháp, để thay đổi được lưu vào bản nháp và tô màu theo loại thay đổi; dữ liệu đang hiệu lực cho HTTT không đổi cho tới khi phát hành. | M | 8 | MVP, W2 | FR-07-012; UC-07-02 |
| US-07-013 | Là cán bộ quản lý dữ liệu, tôi muốn kiểm tra hợp lệ bản ghi theo lược đồ, để người dùng thấy danh sách lỗi theo bản ghi và theo quy tắc, bấm vào lỗi để nhảy tới ô sai. | M | 2 | MVP, W2 | FR-07-013; UC-07-02, 07-06 |
| US-07-014 | Là cán bộ quản lý dữ liệu, tôi muốn so sánh khác biệt giữa hai phiên bản, phân loại phá vỡ và không phá vỡ, để người duyệt thấy rõ bản ghi và thuộc tính nào được thêm, sửa, ngừng dùng, thay đổi nào là phá vỡ, trước khi quyết định. | M | 3 | MVP, W2 | FR-07-014; UC-07-06 |
| US-07-015 | Là cán bộ quản lý dữ liệu, tôi muốn trình duyệt, duyệt, từ chối phiên bản, để phiên bản chuyển sang chờ duyệt, đã duyệt hoặc quay về bản nháp kèm lý do từ chối; người liên quan nhận thông báo. | M | 8* | MVP, W2 | FR-07-015; UC-07-06 |
| US-07-016 | Là người duyệt danh mục, tôi muốn phát hành phiên bản với ngày hiệu lực và căn cứ pháp lý, để phiên bản mới thành phiên bản hiệu lực từ ngày đã chọn; HTTT nhận sự kiện và tra được dữ liệu mới, dữ liệu cũ vẫn tra được theo thời điểm. | M | 8* | MVP, W2 | FR-07-016; UC-07-07 |
| US-07-017 | Là cán bộ quản lý dữ liệu, tôi muốn hủy bản nháp, để bản nháp biến mất; danh mục trở về chỉ có phiên bản hiện hành, có thể tạo bản nháp mới. | M | 1 | MVP, W2 | FR-07-017; UC-07-02 |
| US-07-018 | Là cán bộ quản lý dữ liệu, tôi muốn hiển thị bản ghi dạng bảng và dạng cây, để người dùng xem, tìm và lọc bản ghi theo cách quen thuộc, kể cả với danh mục hàng chục nghìn bản ghi. | M | 2 | MVP, W2 | FR-07-018; UC-07-02 |
| US-07-019 | Là cán bộ quản lý dữ liệu, tôi muốn ghi mã thay thế và quan hệ kế thừa cho bản ghi ngừng dùng, để HTTT tra mã cũ nhận được `status = DEPRECATED` và mã thay thế để tự chuyển dữ liệu. | M | 2 | MVP, W2 | FR-07-019; UC-07-02 |

: Story của epic EP-07-B Bản ghi và phiên bản

#### EP-07-C · Nhập và xuất

Epic gồm 6 story, 26 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-020 | Là cán bộ quản lý dữ liệu, tôi muốn tải tệp mẫu Excel/CSV sinh theo lược đồ của danh mục, để người dùng có tệp Excel hoặc CSV đúng cột, đúng kiểu, có hướng dẫn và danh sách chọn, nhập dữ liệu mà không phải đoán khuôn. | M | 2 | MVP, W2 | FR-07-020; UC-07-03 |
| US-07-021 | Là cán bộ quản lý dữ liệu, tôi muốn nhập bản ghi từ Excel/CSV vào bản nháp, để thấy trước số dòng thêm, sửa, lỗi trước khi ghi vào bản nháp và biết lỗi theo từng dòng, từng ô. | M | 8* | MVP, W2 | FR-07-021; UC-07-03 |
| US-07-022 | Là cán bộ quản lý dữ liệu, tôi muốn tạo danh mục mới từ tệp, hỗ trợ khuôn hệ cũ Aita, để danh mục mới kèm bản nháp phiên bản 1 chứa bản ghi từ tệp, sẵn sàng rà soát và trình duyệt. | M | 5 | MVP, W2 | FR-07-022; UC-07-04 |
| US-07-023 | Là cán bộ quản lý dữ liệu, tôi muốn nhập bản ghi qua API theo lô, idempotent, để HTTT nguồn cập nhật danh mục tự động mà không cần người nhập tay; kết quả trả theo từng bản ghi. | M | 5 | MVP, W2 | FR-07-023; UC-07-05 |
| US-07-024 | Là người dùng, tôi muốn xuất phiên bản ra Excel, CSV, JSON, để người dùng tải được tệp Excel, CSV hoặc JSON đúng phiên bản đã chọn, kèm thông tin phiên bản và ngày hiệu lực. | M | 5 | MVP, W2 | FR-07-024; UC-07-08 |
| US-07-025 | Là quản trị tỉnh, tôi muốn xem lịch sử tác vụ nhập xuất và tải báo cáo lỗi, để người dùng biết tác vụ nào đang chạy, đã xong hay lỗi, và tải được báo cáo lỗi giữ đúng số dòng gốc trong 7 ngày. | M | 1 | MVP, W2 | FR-07-025; UC-07-03, 07-08 |

: Story của epic EP-07-C Nhập và xuất

#### EP-07-D · Khai thác

Epic gồm 9 story, 23 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-026 | Là HTTT khai thác, tôi muốn tra cứu một mã tại thời điểm, để HTTT biết mã có hợp lệ tại thời điểm đó không, tên và thuộc tính là gì. | M | 5 | MVP, W2 | FR-07-026; UC-07-09 |
| US-07-027 | Là cán bộ quản lý dữ liệu, tôi muốn tra cứu lô tối đa 500 mã, để HTTT kiểm tra một lần cả lô mã trong một hồ sơ, biết mã nào không có hoặc đã ngừng dùng. | M | 2 | MVP, W2 | FR-07-027; UC-07-09 |
| US-07-028 | Là cán bộ quản lý dữ liệu, tôi muốn lấy toàn bộ bản ghi theo phiên bản, để HTTT có bản sao đầy đủ của đúng phiên bản cần dùng. | M | 2 | MVP, W2 | FR-07-028; UC-07-09 |
| US-07-029 | Là cán bộ quản lý dữ liệu, tôi muốn lấy cây hoặc nhánh con, để HTTT dựng được ô chọn nhiều cấp (ví dụ tỉnh, xã) mà không tự ráp cây. | M | 1 | MVP, W2 | FR-07-029; UC-07-09 |
| US-07-030 | Là cán bộ quản lý dữ liệu, tôi muốn tìm kiếm không dấu trong danh mục, để người dùng gõ "dak nong" vẫn tìm thấy "Đắk Nông"; kết quả xếp theo độ khớp. | S | 1 | Đợt 2, W4 | FR-07-030; UC-07-09 |
| US-07-031 | Là cán bộ quản lý dữ liệu, tôi muốn lấy thay đổi kể từ một phiên bản (delta), để HTTT chỉ cập nhật phần thay đổi, không phải tải lại toàn bộ danh mục. | M | 2 | MVP, W2 | FR-07-031; UC-07-09 |
| US-07-032 | Là HTTT khai thác, tôi muốn API truy vấn có cấu trúc, để HTTT lọc được bản ghi theo thuộc tính mà không cần và không thể gửi câu SQL; truy vấn vượt giới hạn bị từ chối với thông điệp rõ. | M | 5 | MVP, W2 | FR-07-032; UC-07-10 |
| US-07-033 | Là nhà phát triển, tôi muốn liệt kê danh mục và lấy lược đồ qua API, để nhà phát triển HTTT biết có những danh mục nào và cấu trúc thuộc tính của từng danh mục để viết mã tích hợp. | M | 2 | MVP, W2 | FR-07-033; UC-07-09, 07-10 |
| US-07-034 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống phát sự kiện thay đổi danh mục, để HTTT đăng ký topic được báo ngay khi danh mục đổi, chủ động làm mới bộ đệm. | M | 3 | MVP, W2 | FR-07-034; UC-07-07 |

: Story của epic EP-07-D Khai thác

#### EP-07-E · Đồng bộ danh mục quốc gia

Epic gồm 5 story, 28 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-035 | Là quản trị nền tảng, tôi muốn có cấu hình nguồn đồng bộ danh mục quốc gia, để nguồn đồng bộ mới hiện trong danh sách với lịch chạy kế tiếp. | M | 5 | MVP, W2 | FR-07-035; UC-07-11 |
| US-07-036 | Là quản trị nền tảng, tôi muốn hệ thống chạy đồng bộ theo lịch hoặc theo yêu cầu và tính khác biệt, để người theo dõi thấy lần đồng bộ, số bản ghi thêm, sửa, bị nguồn loại và các thay đổi phá vỡ cần xác nhận. | M | 8* | MVP, W2 | FR-07-036; UC-07-11 |
| US-07-037 | Là quản trị nền tảng, tôi muốn xác nhận hoặc từ chối thay đổi từ nguồn quốc gia, để thay đổi quốc gia được đưa vào danh mục của tỉnh có người chịu trách nhiệm, hoặc bị từ chối kèm lý do. | M | 8* | MVP, W2 | FR-07-037; UC-07-11 |
| US-07-038 | Là quản trị nền tảng, tôi muốn khám phá danh mục quốc gia và đăng ký đồng bộ, để danh mục quốc gia có bản trong Datahub, lần đồng bộ đầu tiên chờ xác nhận. | M | 5 | MVP, W2 | FR-07-038; UC-07-11 |
| US-07-039 | Là quản trị tỉnh, tôi muốn đề xuất bổ sung bản ghi lên danh mục quốc gia, để đề xuất được gửi qua PH-14 tới NDXP và theo dõi được trạng thái. | C | 2 | MVP, W2 | FR-07-039; UC-07-11 |

: Story của epic EP-07-E Đồng bộ danh mục quốc gia

#### EP-07-F · Hệ thống mã ngoài và ánh xạ mã

Epic gồm 4 story, 15 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-040 | Là quản trị nền tảng, tôi muốn quản lý hệ thống mã ngoài, để hệ thống mã của một HTTT được khai báo để lập bảng ánh xạ. | M | 2 | MVP, W2 | FR-07-040; UC-07-13 |
| US-07-041 | Là quản trị nền tảng, tôi muốn quản lý bảng ánh xạ mã giữa danh mục và hệ thống mã ngoài, để mã riêng của HTTT được nối với mã chuẩn, dùng được cho chuyển mã tự động. | M | 8 | MVP, W2 | FR-07-041; UC-07-13 |
| US-07-042 | Là HTTT khai thác, tôi muốn chuyển mã qua bảng ánh xạ, để luồng tích hợp chuyển mã giữa các HTTT bằng bảng dùng chung, không viết tay trên bus. | M | 3 | MVP, W2 | FR-07-042; UC-07-13 |
| US-07-043 | Là cán bộ quản lý dữ liệu, tôi muốn có báo cáo độ phủ ánh xạ, để người dùng biết bao nhiêu phần trăm mã chuẩn đã có ánh xạ và mã nào còn thiếu. | S | 2 | Đợt 2, W4 | FR-07-043; UC-07-13 |

: Story của epic EP-07-F Hệ thống mã ngoài và ánh xạ mã

#### EP-07-G · Đơn vị hành chính

Epic gồm 4 story, 11 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-044 | Là quản trị nền tảng, tôi muốn quản lý danh mục ĐVHC hai cấp kèm lịch sử ba cấp, để mọi tỉnh tra được ĐVHC hiện hành hai cấp và lịch sử ba cấp trước ngày 01/7/2025. | M | 3 | MVP, W2 | FR-07-044; UC-07-12 |
| US-07-045 | Là quản trị nền tảng, tôi muốn ghi nhận sự kiện sắp xếp ĐVHC, để dòng thời gian sắp xếp hiện được đơn vị nào sáp nhập, chia tách vào đơn vị nào, theo văn bản nào. | M | 3 | MVP, W2 | FR-07-045; UC-07-12 |
| US-07-046 | Là HTTT khai thác, tôi muốn chuyển đổi mã ĐVHC cũ sang mới và tra ngược, để HTTT chuyển dữ liệu mang mã ĐVHC cũ sang mã mới, với trường hợp chia tách nhận danh sách ứng viên để tự quyết. | M | 3 | MVP, W2 | FR-07-046; UC-07-12 |
| US-07-047 | Là HTTT khai thác, tôi muốn xem dòng lịch sử của một bản ghi, để người dùng thấy toàn bộ các lần đổi tên, sáp nhập, ngừng dùng của một mã theo thời gian. | M | 2 | MVP, W2 | FR-07-047; UC-07-09, 07-12 |

: Story của epic EP-07-G Đơn vị hành chính

#### EP-07-H · Đa tenant, nền tảng và quản trị

Epic gồm 6 story, 31 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-07-048 | Là quản trị nền tảng, tôi muốn chia sẻ danh mục toàn quốc giữa các tenant và mở rộng HYBRID, để các tỉnh dùng chung một bản danh mục toàn quốc và bổ sung mã địa phương mà không làm sai mã quốc gia. | M | 8 | MVP, W2 | FR-07-048; UC-07-15, 07-17 |
| US-07-049 | Là quản trị nền tảng, tôi muốn nạp gói danh mục nền khi khởi tạo tenant, để tỉnh mới có sẵn bộ danh mục nền (giới tính, dân tộc, quốc tịch…) để dùng ngay. | M | 8 | MVP, W2 | FR-07-049; UC-07-15 |
| US-07-050 | Là cán bộ quản lý dữ liệu, tôi muốn có lịch sử thay đổi và kiểm toán, để người dùng biết ai đã làm gì, khi nào, trên danh mục, kèm giá trị trước và sau. | M | 2 | MVP, W2 | FR-07-050; UC-07-07 |
| US-07-051 | Là quản trị tỉnh, tôi muốn di trú dữ liệu danh mục từ hệ cũ Aita, để dữ liệu danh mục của Aita có mặt trong Datahub, đối soát được số danh mục, số bản ghi và checksum với hệ cũ. | M | 8* | MVP, W2 | FR-07-051; UC-07-16 |
| US-07-052 | Là quản trị tỉnh, tôi muốn khai thác danh mục hạn chế và cấp quyền khai thác, để chỉ HTTT được cấp quyền mới khai thác được danh mục hạn chế; các HTTT khác nhận lỗi rõ ràng. | M | 3 | MVP, W2 | FR-07-052; UC-07-09 |
| US-07-053 | Là quản trị tỉnh, tôi muốn có tham số PH-07 theo tenant, để tỉnh điều chỉnh ngưỡng, giới hạn trong miền nền tảng cho phép mà không cần triển khai lại. | S | 2 | Đợt 2, W4 | FR-07-053 |

: Story của epic EP-07-H Đa tenant, nền tảng và quản trị

### 6.9. PH-08 · Chất lượng dữ liệu

Phân hệ có 10 epic, 61 story, tổng 161 điểm; wave phát triển W4–W5, đợt Đợt 3. Nguồn: D02-03-PH08 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-08-A · Miền và đối tượng đo

Epic gồm 7 story, 20 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-001 | Là quản trị tỉnh, tôi muốn khai báo miền chất lượng, chủ quản, cán bộ phụ trách, để miền xuất hiện ở danh sách, sẵn sàng nhận đối tượng đo; chủ quản thấy miền trong thẻ điểm của tổ chức mình. | M | 5 | Đợt 3, W4–W5 | FR-08-001; UC-08-01 |
| US-08-002 | Là cán bộ quản lý dữ liệu, tôi muốn đăng ký đối tượng đo từ domain PH-06, để bản ghi vàng của domain trở thành đối tượng đo; DS soạn được quy tắc trên các trường đã chọn. | M | 3 | Đợt 3, W4–W5 | FR-08-002; UC-08-02 |
| US-08-003 | Là cán bộ quản lý dữ liệu, tôi muốn đăng ký đối tượng đo từ danh mục PH-07, để danh mục trở thành đối tượng đo; mỗi lần PH-07 phát hành phiên bản mới, lần đo tăng dần có thể tự chạy (FR-08-025). | M | 2 | Đợt 3, W4–W5 | FR-08-003; UC-08-02 |
| US-08-004 | Là cán bộ quản lý dữ liệu, tôi muốn đăng ký đối tượng đo nguồn qua kết nối PH-05 chỉ đọc, để bảng của HTTT trở thành đối tượng đo; lần đo chạy trong cửa sổ giờ thấp điểm để không ảnh hưởng HTTT. | S | 3 | Đợt 3, W4–W5 | FR-08-004; UC-08-02 |
| US-08-005 | Là cán bộ quản lý dữ liệu, tôi muốn khai báo phần tử dữ liệu trọng yếu, lấy phân loại PH-09, để CDE hiện biểu tượng ở mọi màn; thẻ điểm hiện "Độ phủ CDE {x}/{y}". | M | 3 | Đợt 3, W4–W5 | FR-08-005; UC-08-02 |
| US-08-006 | Là chủ quản dữ liệu, tôi muốn liệt kê, tìm, xem đối tượng đo, để người dùng thấy danh sách có màu kết luận, lọc được đối tượng `FAIL` hoặc có lỗi `CRITICAL`. | M | 2 | Đợt 3, W4–W5 | FR-08-006; UC-08-03 |
| US-08-007 | Là cán bộ quản lý dữ liệu, tôi muốn ngừng, khôi phục đối tượng đo, để đối tượng không còn xuất hiện trong lịch; lịch sử điểm, báo cáo cũ giữ nguyên. | M | 2 | Đợt 3, W4–W5 | FR-08-007; UC-08-03 |

: Story của epic EP-08-A Miền và đối tượng đo

#### EP-08-B · Hồ sơ dữ liệu

Epic gồm 4 story, 7 điểm (0 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-008 | Là cán bộ quản lý dữ liệu, tôi muốn chạy hồ sơ dữ liệu, để sau vài phút, tab "Hồ sơ" hiện thống kê từng cột. | S | 3 | Đợt 3, W4–W5 | FR-08-008; UC-08-04 |
| US-08-009 | Là cán bộ quản lý dữ liệu, tôi muốn xem hồ sơ dữ liệu theo cột, để người soạn biết ngay trường nào cần quy tắc đầy đủ, trường nào cần quy tắc định dạng. | S | 1 | Đợt 3, W4–W5 | FR-08-009; UC-08-04 |
| US-08-010 | Là cán bộ quản lý dữ liệu, tôi muốn gợi ý quy tắc từ hồ sơ, để bản nháp có sẵn bộ quy tắc khởi điểm để chạy thử. | C | 2 | Đợt 3, W4–W5 | FR-08-010; UC-08-04 |
| US-08-011 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống nhận chỉ số hồ sơ từ PH-05, để tab "Hồ sơ" có thêm dòng "Từ PH-05" với tỷ lệ thiếu theo giờ. | C | 1 | Đợt 3, W4–W5 | FR-08-011; UC-08-04 |

: Story của epic EP-08-B Hồ sơ dữ liệu

#### EP-08-C · Quy tắc

Epic gồm 11 story, 32 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-012 | Là cán bộ quản lý dữ liệu, tôi muốn tạo bộ quy tắc phiên bản nháp, để người soạn có bản nháp để thêm, sửa, tắt quy tắc. | M | 2 | Đợt 3, W4–W5 | FR-08-012; UC-08-05 |
| US-08-013 | Là cán bộ quản lý dữ liệu, tôi muốn định nghĩa quy tắc theo chiều và toán tử, để quy tắc hiện trong bảng của UI-08-07 với chip chiều và mức. | M | 5 | Đợt 3, W4–W5 | FR-08-013; UC-08-05 |
| US-08-014 | Là cán bộ quản lý dữ liệu, tôi muốn có quy tắc biểu thức CEL và vị từ SQL có kiểm soát, để biểu thức hợp lệ được lưu như mọi quy tắc khác và chạy thử được. | S | 2 | Đợt 3, W4–W5 | FR-08-014; UC-08-06 |
| US-08-015 | Là quản trị nền tảng, tôi muốn có thư viện quy tắc mẫu ở COMMON, để người soạn tạo quy tắc CCCD đúng chuẩn trong vài thao tác. | S | 2 | Đợt 3, W4–W5 | FR-08-015; UC-08-06 |
| US-08-016 | Là cán bộ quản lý dữ liệu, tôi muốn chạy thử quy tắc trên mẫu, để người soạn sửa tham số tới khi tỷ lệ vi phạm hợp lý rồi gửi duyệt. | M | 3 | Đợt 3, W4–W5 | FR-08-016; UC-08-06 |
| US-08-017 | Là cán bộ quản lý dữ liệu, tôi muốn gửi duyệt, duyệt, từ chối bộ quy tắc, để bộ quy tắc mới chỉ có hiệu lực khi hai người đồng ý. | M | 5 | Đợt 3, W4–W5 | FR-08-017; UC-08-07 |
| US-08-018 | Là người duyệt danh mục, tôi muốn hệ thống kích hoạt, thay thế, ngừng phiên bản bộ quy tắc, để từ lần đo kế tiếp, điểm tính theo phiên bản mới; lịch sử ghi rõ phiên bản nào dùng cho kỳ nào. | M | 3 | Đợt 3, W4–W5 | FR-08-018; UC-08-07 |
| US-08-019 | Là người dùng có quyền xem, tôi muốn so sánh phiên bản, xem lịch sử, để người duyệt quyết định dựa trên thay đổi cụ thể, không phải đọc lại toàn bộ. | S | 1 | Đợt 3, W4–W5 | FR-08-019; UC-08-08 |
| US-08-020 | Là cán bộ quản lý dữ liệu, tôi muốn sao chép, nhập, xuất bộ quy tắc YAML, JSON, để bản nháp sẵn sàng chạy thử và gửi duyệt. | S | 3 | Đợt 3, W4–W5 | FR-08-020; UC-08-08 |
| US-08-021 | Là cán bộ quản lý dữ liệu, tôi muốn có cấu hình trọng số và ngưỡng có phiên bản, có duyệt, để lần đo sau thời điểm hiệu lực chấm theo trọng số mới; điểm cũ giữ nguyên. | M | 5 | Đợt 3, W4–W5 | FR-08-021; UC-08-09 |
| US-08-022 | Là người dùng có quyền xem, tôi muốn liệt kê, tìm quy tắc, để người dùng thấy toàn cảnh quy tắc của tỉnh. | M | 1 | Đợt 3, W4–W5 | FR-08-022; UC-08-05 |

: Story của epic EP-08-C Quy tắc

#### EP-08-D · Lịch và đo theo lô

Epic gồm 9 story, 27 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-023 | Là cán bộ quản lý dữ liệu, tôi muốn lập lịch đo, để đối tượng tự được đo hằng tháng; mục tiêu 1 ở 2.2 theo dõi được. | M | 2 | Đợt 3, W4–W5 | FR-08-023; UC-08-10 |
| US-08-024 | Là cán bộ quản lý dữ liệu, tôi muốn chạy đo theo yêu cầu, để người dùng theo dõi tiến độ ở UI-08-12. | M | 3 | Đợt 3, W4–W5 | FR-08-024; UC-08-10 |
| US-08-025 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống đo tăng dần theo sự kiện PH-06, PH-07, để bản ghi lỗi mới xuất hiện trong vòng khoảng 20 phút sau khi bản ghi vàng đổi. | S | 3 | Đợt 3, W4–W5 | FR-08-025; UC-08-14 |
| US-08-026 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống thực thi quy tắc theo lô, để cán bộ thấy số lỗi từng quy tắc và danh sách bản ghi lỗi. | M | 5 | Đợt 3, W4–W5 | FR-08-026; UC-08-11 |
| US-08-027 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống đối chiếu danh mục PH-07 cho chiều hợp lệ, để báo cáo chỉ đúng bao nhiêu hồ sơ còn mã xã cũ và mã mới tương ứng. | M | 2 | Đợt 3, W4–W5 | FR-08-027; UC-08-11 |
| US-08-028 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống tính điểm có trọng số, để thẻ điểm hiện điểm mới, radar sáu chiều và kết luận màu. | M | 3 | Đợt 3, W4–W5 | FR-08-028; UC-08-12 |
| US-08-029 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống so kỳ trước, xu hướng, để thẻ điểm hiện mũi tên xu hướng, "+2,1 so với tháng trước", số lỗi mới, hết. | M | 3 | Đợt 3, W4–W5 | FR-08-029; UC-08-12 |
| US-08-030 | Là cán bộ quản lý dữ liệu, tôi muốn theo dõi tiến độ, hủy, chạy lại lần đo, để vận hành kiểm soát được tải đo lên nguồn. | M | 3 | Đợt 3, W4–W5 | FR-08-030; UC-08-10 |
| US-08-031 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống xử lý phụ thuộc không khả dụng, để báo cáo ghi rõ "Kỳ này thiếu chiều Hợp lệ do PH-07 gián đoạn 02:10–02:40". | M | 3 | Đợt 3, W4–W5 | FR-08-031; UC-08-13 |

: Story của epic EP-08-D Lịch và đo theo lô

#### EP-08-E · Kiểm tra trực tuyến

Epic gồm 4 story, 12 điểm (0 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-032 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống API kiểm tra trực tuyến bản ghi, để bên gọi quyết định đi tiếp, gắn cờ hoặc đưa vào DLQ theo chính sách luồng. | S | 5 | Đợt 3, W4–W5 | FR-08-032; UC-08-15 |
| US-08-033 | Là kỹ sư tích hợp, tôi muốn bước kiểm tra chất lượng trong luồng PH-04, để bản tin sai số định danh không tới được hệ nhận khi luồng bật `STRICT`. | S | 3 | Đợt 3, W4–W5 | FR-08-033; UC-08-15 |
| US-08-034 | Là cán bộ quản lý dữ liệu, tôi muốn thống kê kiểm tra trực tuyến, để màn hiện biểu đồ tỷ lệ không đạt, bấm vào quy tắc xem luồng gây lỗi. | S | 2 | Đợt 3, W4–W5 | FR-08-034; UC-08-16 |
| US-08-035 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống có cổng chất lượng đầu vào cho PH-06, để tỷ lệ ứng viên lỗi của từng nguồn hiện ở UI-08-20 và báo cáo kỳ. | C | 2 | Đợt 3, W4–W5 | FR-08-035; UC-08-16 |

: Story của epic EP-08-E Kiểm tra trực tuyến

#### EP-08-F · Bản ghi lỗi

Epic gồm 5 story, 17 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-036 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống ghi bản ghi lỗi, dấu vân tay, che giá trị, để danh sách lỗi đầy đủ ở UI-08-13 ngay khi lần đo xong. | M | 5 | Đợt 3, W4–W5 | FR-08-036; UC-08-11 |
| US-08-037 | Là cán bộ quản lý dữ liệu, tôi muốn tra cứu, lọc bản ghi lỗi, để chủ quản lọc được "lỗi CRITICAL chưa có phiếu của Sở mình". | M | 2 | Đợt 3, W4–W5 | FR-08-037; UC-08-17 |
| US-08-038 | Là cán bộ quản lý dữ liệu, tôi muốn xem chi tiết bản ghi lỗi, nguồn gốc, để người xử lý thấy "giá trị sai đến từ HTTT Hộ tịch, lần cập nhật 12/10/2026". | M | 2 | Đợt 3, W4–W5 | FR-08-038; UC-08-17 |
| US-08-039 | Là cán bộ quản lý dữ liệu, tôi muốn xuất bản ghi lỗi có duyệt khi có trường Nhạy cảm, để chủ quản có tệp danh sách lỗi đã che để đối chiếu trong HTTT. | S | 3 | Đợt 3, W4–W5 | FR-08-039; UC-08-17 |
| US-08-040 | Là cán bộ quản lý dữ liệu, tôi muốn ngoại lệ chấp nhận có hạn, có duyệt, để thẻ điểm ghi "Có {n} lỗi được ngoại lệ đến {ngày}"; báo cáo liệt kê mọi ngoại lệ `ACTIVE`. | S | 5 | Đợt 3, W4–W5 | FR-08-040; UC-08-18 |

: Story của epic EP-08-F Bản ghi lỗi

#### EP-08-G · Khắc phục

Epic gồm 6 story, 15 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-041 | Là cán bộ quản lý dữ liệu, tôi muốn mở phiếu khắc phục từ nhóm lỗi, để chủ quản nhận việc trong "Việc của tôi" kèm liên kết danh sách lỗi. | M | 3 | Đợt 3, W4–W5 | FR-08-041; UC-08-19 |
| US-08-042 | Là cán bộ quản lý dữ liệu, tôi muốn phân công cho tổ chức chủ quản, SLA, để hộp việc của chủ quản hiện phiếu có đếm ngược hạn. | M | 2 | Đợt 3, W4–W5 | FR-08-042; UC-08-19 |
| US-08-043 | Là chủ quản dữ liệu, tôi muốn cập nhật tiến độ, trao đổi trên phiếu, để mọi người thấy cùng một dòng thời gian xử lý. | M | 2 | Đợt 3, W4–W5 | FR-08-043; UC-08-20 |
| US-08-044 | Là chủ quản dữ liệu, tôi muốn xác nhận đã sửa và đo lại kiểm chứng, để chủ quản thấy kết quả kiểm chứng trong khoảng một giờ. | M | 3 | Đợt 3, W4–W5 | FR-08-044; UC-08-21 |
| US-08-045 | Là chủ quản dữ liệu, tôi muốn từ chối, chuyển, leo thang phiếu quá hạn, để phiếu không thể "chết" ở một đơn vị; lãnh đạo thấy danh sách quá hạn. | S | 3 | Đợt 3, W4–W5 | FR-08-045; UC-08-22 |
| US-08-046 | Là cán bộ quản lý dữ liệu, tôi muốn chuyển lỗi bản ghi vàng sang hàng đợi PH-06, để người quản lý dữ liệu chủ thấy mục cần xem xét kèm lý do từ PH-08. | S | 2 | Đợt 3, W4–W5 | FR-08-046; UC-08-22 |

: Story của epic EP-08-G Khắc phục

#### EP-08-H · Cảnh báo

Epic gồm 3 story, 5 điểm (0 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-047 | Là cán bộ quản lý dữ liệu, tôi muốn khai báo quy tắc cảnh báo, để cán bộ nhận cảnh báo đúng điều mình quan tâm. | S | 1 | Đợt 3, W4–W5 | FR-08-047; UC-08-23 |
| US-08-048 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống phát cảnh báo qua kênh thông báo PH-13, để cán bộ nhận một thông báo cho một vấn đề, không bị dội bão. | S | 2 | Đợt 3, W4–W5 | FR-08-048; UC-08-23 |
| US-08-049 | Là cán bộ quản lý dữ liệu, tôi muốn xác nhận, tắt tiếng cảnh báo, để người khác thấy cảnh báo đã có người nhận. | S | 2 | Đợt 3, W4–W5 | FR-08-049; UC-08-23 |

: Story của epic EP-08-H Cảnh báo

#### EP-08-I · Bảng điều khiển, báo cáo

Epic gồm 8 story, 20 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-050 | Là người xem, tôi muốn có bảng điều khiển chất lượng tenant, để lãnh đạo biết trong vài giây miền nào cần chỉ đạo. | M | 2 | Đợt 3, W4–W5 | FR-08-050; UC-08-24 |
| US-08-051 | Là cán bộ quản lý dữ liệu, tôi muốn thẻ điểm theo đối tượng đo, miền, tổ chức, để sở thấy điểm của mình, HTTT hiển thị được "chất lượng dữ liệu: 86,9" trên giao diện riêng. | M | 2 | Đợt 3, W4–W5 | FR-08-051; UC-08-24 |
| US-08-052 | Là cán bộ quản lý dữ liệu, tôi muốn sinh báo cáo kỳ, để cán bộ có bản nháp báo cáo tháng ngay sáng ngày 1. | M | 2 | Đợt 3, W4–W5 | FR-08-052; UC-08-25 |
| US-08-053 | Là cán bộ quản lý dữ liệu, tôi muốn duyệt và công bố báo cáo, để báo cáo hiện ở danh sách "Đã công bố", chủ quản và lãnh đạo nhận được. | M | 3 | Đợt 3, W4–W5 | FR-08-053; UC-08-25 |
| US-08-054 | Là cán bộ quản lý dữ liệu, tôi muốn có báo cáo chính thức hằng năm, để tỉnh có báo cáo năm đã duyệt, đóng dấu thời gian, truy xuất được khi thanh tra. | M | 5 | Đợt 3, W4–W5 | FR-08-054; UC-08-25 |
| US-08-055 | Là cán bộ quản lý dữ liệu, tôi muốn xuất báo cáo PDF, XLSX, ký số, để văn thư có bản PDF đã ký đúng nội dung đã duyệt. | S | 2 | Đợt 3, W4–W5 | FR-08-055; UC-08-26 |
| US-08-056 | Là cán bộ quản lý dữ liệu, tôi muốn phân phối báo cáo, đăng ký nhận, để chủ quản nhận đúng phần của mình; lãnh đạo nhận bản tổng hợp. | S | 2 | Đợt 3, W4–W5 | FR-08-056; UC-08-26 |
| US-08-057 | Là cán bộ quản lý dữ liệu, tôi muốn hệ thống đẩy chỉ số sang PH-16, PH-13, để bảng chỉ tiêu của tỉnh có chỉ số chất lượng dữ liệu cập nhật. | S | 2 | Đợt 3, W4–W5 | FR-08-057; UC-08-26 |

: Story của epic EP-08-I Bảng điều khiển, báo cáo

#### EP-08-J · Quản trị

Epic gồm 4 story, 6 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-08-058 | Là quản trị tỉnh, tôi muốn có tham số chất lượng theo tenant, để tỉnh đặt được ví dụ lịch đo ngày 2 hằng tháng, SLA `CRITICAL` 3 ngày. | M | 2 | Đợt 3, W4–W5 | FR-08-058; UC-08-27 |
| US-08-059 | Là quản trị tỉnh, tôi muốn hệ thống lưu giữ và dọn dữ liệu đo, để dung lượng `ph08_dq` ổn định; dữ liệu cần cho thanh tra vẫn còn. | M | 2 | Đợt 3, W4–W5 | FR-08-059; UC-08-27 |
| US-08-060 | Là cán bộ ATTT, tôi muốn hệ thống có nhật ký kiểm toán PH-08, để AU tra được toàn bộ thay đổi cách đo của một năm báo cáo. | M | 1 | Đợt 3, W4–W5 | FR-08-060; UC-08-27 |
| US-08-061 | Là quản trị nền tảng, tôi muốn so sánh liên tenant tổng hợp ẩn danh, để tỉnh biết điểm hợp lệ ĐVHC của mình ở phân vị 30, cần cải thiện. | C | 1 | Đợt 3, W4–W5 | FR-08-061; UC-08-24 |

: Story của epic EP-08-J Quản trị

### 6.10. PH-09 · Quyền riêng tư

Phân hệ có 11 epic, 64 story, tổng 140 điểm; wave phát triển W4, đợt Đợt 2. Nguồn: D02-03-PH09 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-09-A · Phân loại dữ liệu

Epic gồm 8 story, 19 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-001 | Là quản trị tỉnh, tôi muốn quản lý danh mục mức phân loại và nhãn chặn bí mật nhà nước, để mọi phân hệ thấy cùng bốn mức và cách xử lý tương ứng. | M | 1 | Đợt 2, W4 | FR-09-001; UC-09-01 |
| US-09-002 | Là quản trị tỉnh, tôi muốn quản lý danh mục loại dữ liệu cá nhân, để có một danh mục loại DLCN thống nhất theo luật. | M | 2 | Đợt 2, W4 | FR-09-002; UC-09-01 |
| US-09-003 | Là quản trị tỉnh, tôi muốn hệ thống đăng ký phần tử dữ liệu từ phân hệ, lược đồ API, topic và khai báo MVP, để cán bộ thấy toàn bộ trường cần phân loại, gom theo hợp đồng và chủ sở hữu. | M | 3 | Đợt 2, W4 | FR-09-003; UC-09-02 |
| US-09-004 | Là cán bộ quản lý dữ liệu, tôi muốn đề xuất, xác nhận phân loại trường (hạ mức cần bốn mắt), để phân loại có hiệu lực toàn hệ trong 60 giây; PH-06, PH-04, PH-02 nhận được thay đổi. | M | 3 | Đợt 2, W4 | FR-09-004; UC-09-03 |
| US-09-005 | Là quản trị tỉnh, tôi muốn quét phát hiện trường nghi dữ liệu cá nhân chưa phân loại, để danh sách trường nghi DLCN để SO quyết định. | S | 3 | Đợt 2, W4 | FR-09-005; UC-09-04 |
| US-09-006 | Là cán bộ ATTT, tôi muốn hệ thống tính và công bố mức phân loại của hợp đồng API, topic, luồng, để mỗi hợp đồng có một mức rõ ràng, dùng ngay để chọn xác thực và chặn kích hoạt. | M | 2 | Đợt 2, W4 | FR-09-006; UC-09-05 |
| US-09-007 | Là quản trị tỉnh, tôi muốn chặn dữ liệu bí mật nhà nước đi qua Datahub, để không có dữ liệu mật nào lọt qua Datahub; SO biết ngay nơi cấu hình sai. | M | 3 | Đợt 2, W4 | FR-09-007; UC-09-06 |
| US-09-008 | Là kiểm toán viên, tôi muốn tra cứu, xuất danh mục phân loại và lịch sử thay đổi, để cán bộ có bảng phân loại đầy đủ và lịch sử để rà soát. | S | 2 | Đợt 2, W4 | FR-09-008; UC-09-01 |

: Story của epic EP-09-A Phân loại dữ liệu

#### EP-09-B · Sổ hoạt động xử lý dữ liệu cá nhân

Epic gồm 5 story, 10 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-009 | Là quản trị tỉnh, tôi muốn lập hoạt động xử lý dữ liệu cá nhân, để có bản nháp hoạt động xử lý sẵn sàng gửi duyệt. | M | 2 | Đợt 2, W4 | FR-09-009; UC-09-07 |
| US-09-010 | Là cán bộ ATTT, tôi muốn duyệt, phiên bản hóa hoạt động xử lý, để sổ có hoạt động đã duyệt, so sánh được giữa các phiên bản. | M | 3 | Đợt 2, W4 | FR-09-010; UC-09-07 |
| US-09-011 | Là cán bộ ATTT, tôi muốn liên kết hoạt động xử lý với trường, API, topic, luồng, để cán bộ thấy trường nào chưa có cơ sở xử lý để xử lý trước hạn. | M | 2 | Đợt 2, W4 | FR-09-011; UC-09-07 |
| US-09-012 | Là quản trị tỉnh, tôi muốn quản lý danh mục cơ sở pháp lý và căn cứ văn bản, để căn cứ pháp lý thống nhất, cảnh báo sớm khi luật đổi. | M | 2 | Đợt 2, W4 | FR-09-012; UC-09-08 |
| US-09-013 | Là cán bộ ATTT, tôi muốn xuất sổ hoạt động xử lý theo mẫu, để có tệp sổ đúng mẫu, không chứa dữ liệu cá nhân. | S | 1 | Đợt 2, W4 | FR-09-013; UC-09-07 |

: Story của epic EP-09-B Sổ hoạt động xử lý dữ liệu cá nhân

#### EP-09-C · Mục đích và chấp thuận khai thác

Epic gồm 9 story, 23 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-014 | Là chủ quản dữ liệu, tôi muốn quản lý danh mục mục đích khai thác, để có danh mục mục đích thống nhất cho HTTT chọn và OPA kiểm. | M | 2 | Đợt 2, W4 | FR-09-014; UC-09-08 |
| US-09-015 | Là cán bộ đầu mối của tổ chức, tôi muốn lập yêu cầu khai thác theo mục đích, để yêu cầu tới đúng chủ quản dữ liệu, kèm mức và hoạt động xử lý của hợp đồng. | M | 3 | Đợt 2, W4 | FR-09-015; UC-09-09 |
| US-09-016 | Là chủ quản dữ liệu, tôi muốn thẩm định, chấp thuận có điều kiện hoặc từ chối yêu cầu khai thác, để HTTT khai thác được trong 60 giây sau quyết định, đúng trường và điều kiện. | M | 3 | Đợt 2, W4 | FR-09-016; UC-09-10 |
| US-09-017 | Là chủ quản dữ liệu, tôi muốn gia hạn, sửa, tạm dừng, thu hồi chấp thuận và tự hết hạn, để khai thác dừng hoặc đổi đúng lúc, chủ quản thấy ngay tác động. | M | 3 | Đợt 2, W4 | FR-09-017; UC-09-11 |
| US-09-018 | Là người duyệt danh mục, tôi muốn hệ thống đồng bộ chấp thuận và chính sách sang bundle OPA có ký, để chấp thuận và chính sách có hiệu lực tại điểm thực thi trong 60 giây. | M | 3 | Đợt 2, W4 | FR-09-018; UC-09-12 |
| US-09-019 | Là cán bộ ATTT, tôi muốn hệ thống quyết định mục đích trực tuyến cho điểm thực thi (data plane), để quyết định có lý do mã hóa, p95 ≤ 20 ms có đệm, ≤ 50 ms gọi trực tiếp (NFR-09-001). | M | 3 | Đợt 2, W4 | FR-09-019; UC-09-13 |
| US-09-020 | Là chủ quản dữ liệu, tôi muốn hệ thống phát hiện khai thác vượt mục đích, vượt hạn ngạch, để khai thác bất thường được thấy trong 5 phút (NFR-09-026), kèm bằng chứng đếm. | S | 3 | Đợt 2, W4 | FR-09-020; UC-09-14 |
| US-09-021 | Là chủ quản dữ liệu, tôi muốn có báo cáo khai thác theo mục đích, để có số liệu để quyết định gia hạn hoặc thu hồi. | S | 1 | Đợt 2, W4 | FR-09-021; UC-09-14 |
| US-09-022 | Là cán bộ ATTT, tôi muốn hệ thống chặn kích hoạt hợp đồng mức Nhạy cảm khi chưa có mục đích và chấp thuận, để không hợp đồng Nhạy cảm nào chạy khi chưa có chấp thuận; người dùng biết cần bổ sung gì. | M | 2 | Đợt 2, W4 | FR-09-022; UC-09-15 |

: Story của epic EP-09-C Mục đích và chấp thuận khai thác

#### EP-09-D · Chính sách che

Epic gồm 8 story, 18 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-023 | Là quản trị tỉnh, tôi muốn quản lý kiểu che và mẫu che, để một bộ kiểu che chuẩn, có ví dụ trước và sau. | M | 1 | Đợt 2, W4 | FR-09-023; UC-09-16 |
| US-09-024 | Là quản trị tỉnh, tôi muốn soạn chính sách che theo mức, loại dữ liệu cá nhân, vai trò, mục đích, kênh, để có bản nháp chính sách sẵn sàng mô phỏng. | M | 2 | Đợt 2, W4 | FR-09-024; UC-09-16 |
| US-09-025 | Là quản trị tỉnh, tôi muốn mô phỏng chính sách che trên dữ liệu mẫu, để người soạn thấy ngay hậu quả của chính sách. | S | 2 | Đợt 2, W4 | FR-09-025; UC-09-17 |
| US-09-026 | Là quản trị tỉnh, tôi muốn duyệt, phát hành, phiên bản hóa chính sách che, để chính sách mới có hiệu lực toàn tenant trong 60 giây. | M | 3 | Đợt 2, W4 | FR-09-026; UC-09-17 |
| US-09-027 | Là cán bộ ATTT, tôi muốn hệ thống trả kế hoạch che trực tuyến cho điểm thực thi, đệm và đóng an toàn, để điểm thực thi che đúng, kể cả khi PH-09 chậm; p95 ≤ 50 ms (NFR-09-002). | M | 2 | Đợt 2, W4 | FR-09-027; UC-09-18 |
| US-09-028 | Là cán bộ ATTT, tôi muốn hệ thống áp che bản tin cho luồng PH-04, để bên nhận chỉ thấy dữ liệu được phép; log, vết không chứa giá trị nhạy cảm. | M | 3 | Đợt 2, W4 | FR-09-028; UC-09-19 |
| US-09-029 | Là cán bộ ATTT, tôi muốn xem giá trị đầy đủ có lý do trong 60 giây, để người có quyền xem đủ trong thời gian ngắn; mọi lần xem đều truy được. | M | 3 | Đợt 2, W4 | FR-09-029; UC-09-20 |
| US-09-030 | Là quản trị tỉnh, tôi muốn có cấu hình che cho log, trace và quét rò rỉ dữ liệu cá nhân trong log, để rò rỉ được phát hiện trong 24 giờ và truy về dịch vụ gây ra. | M | 2 | Đợt 2, W4 | FR-09-030; UC-09-21 |

: Story của epic EP-09-D Chính sách che

#### EP-09-E · Giả danh hóa và ẩn danh hóa

Epic gồm 9 story, 25 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-031 | Là quản trị tỉnh, tôi muốn quản lý miền giả danh hóa theo tenant và mục đích, để có miền sẵn sàng giả danh hóa theo đúng mục đích. | M | 3 | Đợt 2, W4 | FR-09-031; UC-09-22 |
| US-09-032 | Là cán bộ ATTT, tôi muốn hệ thống giả danh hóa giá trị bằng HMAC hoặc token, để bên phân tích nối được dữ liệu cùng miền mà không biết danh tính. | M | 2 | Đợt 2, W4 | FR-09-032; UC-09-23 |
| US-09-033 | Là cán bộ ATTT, tôi muốn khôi phục giá trị gốc từ token (đặc quyền, hai người duyệt), để chỉ khôi phục khi đủ căn cứ và đủ người chịu trách nhiệm. | S | 3 | Đợt 2, W4 | FR-09-033; UC-09-24 |
| US-09-034 | Là quản trị tỉnh, tôi muốn quản lý vòng đời khóa giả danh hóa trên OpenBao, để khóa luôn trong hạn và có thể quy trách nhiệm. | M | 5 | Đợt 2, W4 | FR-09-034; UC-09-22 |
| US-09-035 | Là quản trị tỉnh, tôi muốn có cấu hình ẩn danh hóa, để có cấu hình ẩn danh được duyệt để chạy job. | S | 2 | Đợt 2, W4 | FR-09-035; UC-09-25 |
| US-09-036 | Là quản trị tỉnh, tôi muốn ẩn danh hóa tập dữ liệu với k tối thiểu 10, để tập ẩn danh đạt k kèm báo cáo. | S | 3 | Đợt 2, W4 | FR-09-036; UC-09-25 |
| US-09-037 | Là quản trị tỉnh, tôi muốn đánh giá rủi ro tái định danh, để cán bộ biết trường nào gây rủi ro và phải làm gì. | S | 2 | Đợt 2, W4 | FR-09-037; UC-09-25 |
| US-09-038 | Là quản trị tỉnh, tôi muốn chuẩn bị dữ liệu cho AI và môi trường không phải PROD, để dữ liệu thử và dữ liệu AI không chứa dữ liệu cá nhân thật. | M | 3 | Đợt 2, W4 | FR-09-038; UC-09-26 |
| US-09-039 | Là quản trị tỉnh, tôi muốn quản lý tập dữ liệu đã ẩn danh và điều kiện sử dụng, để tập dữ liệu mở có điều kiện và hạn rõ ràng. | C | 2 | Đợt 3, W5 | FR-09-039; UC-09-26 |

: Story của epic EP-09-E Giả danh hóa và ẩn danh hóa

#### EP-09-F · Lưu giữ và xóa

Epic gồm 5 story, 10 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-040 | Là quản trị tỉnh, tôi muốn lập lịch lưu giữ theo bảng và loại dữ liệu, để mọi bảng DLCN có hạn lưu được duyệt. | M | 2 | Đợt 2, W4 | FR-09-040; UC-09-27 |
| US-09-041 | Là quản trị tỉnh, tôi muốn hệ thống tác vụ xóa hoặc giả danh hóa khi hết hạn và báo cáo, để dữ liệu hết hạn được xử lý đúng hành động đã duyệt. | M | 2 | Đợt 2, W4 | FR-09-041; UC-09-27 |
| US-09-042 | Là quản trị tỉnh, tôi muốn giữ pháp lý (tạm hoãn xóa), để dữ liệu cần cho tố tụng không bị xóa nhầm. | M | 2 | Đợt 2, W4 | FR-09-042; UC-09-28 |
| US-09-043 | Là quản trị tỉnh, tôi muốn xóa mật mã khi chấm dứt tenant, để dữ liệu của tenant không khôi phục được kể cả từ bản sao lưu. | M | 3 | Đợt 2, W4 | FR-09-043; UC-09-28 |
| US-09-044 | Là cán bộ ATTT, tôi muốn có báo cáo tuân thủ thời hạn lưu, để có bằng chứng cho thanh tra. | S | 1 | Đợt 2, W4 | FR-09-044; UC-09-27 |

: Story của epic EP-09-F Lưu giữ và xóa

#### EP-09-G · Quyền của chủ thể dữ liệu

Epic gồm 7 story, 13 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-045 | Là cán bộ ATTT, tôi muốn tiếp nhận yêu cầu của chủ thể dữ liệu, để yêu cầu có mã và hạn rõ ràng. | M | 2 | Đợt 2, W4 | FR-09-045; UC-09-29 |
| US-09-046 | Là cán bộ ATTT, tôi muốn xác minh danh tính chủ thể, để chỉ người đã xác minh nhận dữ liệu. | M | 2 | Đợt 2, W4 | FR-09-046; UC-09-29 |
| US-09-047 | Là cán bộ ATTT, tôi muốn tra cứu dữ liệu về chủ thể theo băm định danh, để có bản đồ nơi lưu dữ liệu của chủ thể. | M | 2 | Đợt 2, W4 | FR-09-047; UC-09-29 |
| US-09-048 | Là cán bộ ATTT, tôi muốn phân công, chuyển xử lý cho PH-06, PH-19 hoặc bên kiểm soát, để mỗi yêu cầu có người chịu trách nhiệm từng việc. | M | 2 | Đợt 2, W4 | FR-09-048; UC-09-29 |
| US-09-049 | Là cán bộ ATTT, tôi muốn hệ thống theo dõi hạn xử lý, nhắc và quá hạn, để không yêu cầu nào quá hạn mà không ai biết. | M | 2 | Đợt 2, W4 | FR-09-049; UC-09-30 |
| US-09-050 | Là cán bộ ATTT, tôi muốn trả lời chủ thể, đóng yêu cầu, lưu bằng chứng, để chủ thể nhận kết quả hợp lệ; hồ sơ đầy đủ cho thanh tra. | M | 2 | Đợt 2, W4 | FR-09-050; UC-09-30 |
| US-09-051 | Là cán bộ ATTT, tôi muốn có báo cáo ai đã truy cập dữ liệu của chủ thể, để chủ thể biết ai xem dữ liệu của mình. | S | 1 | Đợt 2, W4 | FR-09-051; UC-09-30 |

: Story của epic EP-09-G Quyền của chủ thể dữ liệu

#### EP-09-H · Sự đồng ý

Epic gồm 3 story, 6 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-052 | Là quản trị tỉnh, tôi muốn quản lý mẫu sự đồng ý, để có mẫu đồng ý được duyệt. | M | 2 | Đợt 2, W4 | FR-09-052; UC-09-31 |
| US-09-053 | Là cán bộ ATTT, tôi muốn ghi nhận, rút sự đồng ý và lưu bằng chứng, để mọi đồng ý truy được về nội dung và thời điểm. | M | 3 | Đợt 2, W4 | FR-09-053; UC-09-31 |
| US-09-054 | Là HTTT khai thác, tôi muốn tra cứu trạng thái đồng ý cho tiện ích không bắt buộc, để tiện ích chỉ xử lý khi đang đồng ý. | C | 1 | Đợt 3, W5 | FR-09-054; UC-09-31 |

: Story của epic EP-09-H Sự đồng ý

#### EP-09-I · Đánh giá tác động xử lý dữ liệu cá nhân

Epic gồm 3 story, 6 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-055 | Là cán bộ ATTT, tôi muốn lập hồ sơ đánh giá tác động xử lý dữ liệu cá nhân, để có hồ sơ đầy đủ rủi ro và biện pháp. | M | 2 | Đợt 2, W4 | FR-09-055; UC-09-32 |
| US-09-056 | Là cán bộ ATTT, tôi muốn duyệt, phiên bản hóa, nhắc cập nhật hồ sơ đánh giá tác động, để hồ sơ luôn được rà soát đúng hạn. | M | 3 | Đợt 2, W4 | FR-09-056; UC-09-32 |
| US-09-057 | Là cán bộ ATTT, tôi muốn xuất hồ sơ đánh giá tác động gửi Cục A05, để có tệp nộp A05 và vết đã nộp. | C | 1 | Đợt 3, W5 | FR-09-057; UC-09-32 |

: Story của epic EP-09-I Đánh giá tác động xử lý dữ liệu cá nhân

#### EP-09-J · Vi phạm dữ liệu cá nhân

Epic gồm 3 story, 6 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-058 | Là vận hành tỉnh, tôi muốn ghi nhận vi phạm dữ liệu cá nhân và đánh giá ảnh hưởng, để vụ việc có đồng hồ và người chịu trách nhiệm. | M | 2 | Đợt 2, W4 | FR-09-058; UC-09-33 |
| US-09-059 | Là cán bộ ATTT, tôi muốn đồng hồ 72 giờ, thông báo Cục A05 và chủ thể, để thông báo đúng hạn có bằng chứng. | M | 3 | Đợt 2, W4 | FR-09-059; UC-09-33 |
| US-09-060 | Là cán bộ ATTT, tôi muốn có hồ sơ vi phạm, khắc phục và bài học, để vụ việc có hồ sơ đầy đủ. | M | 1 | Đợt 2, W4 | FR-09-060; UC-09-33 |

: Story của epic EP-09-J Vi phạm dữ liệu cá nhân

#### EP-09-K · Kiểm toán, báo cáo và cấu hình

Epic gồm 4 story, 4 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-09-061 | Là cán bộ ATTT, tôi muốn ghi vết thao tác bảo vệ dữ liệu, để truy được ai làm gì, lúc nào. | M | 1 | Đợt 2, W4 | FR-09-061; UC-09-34 |
| US-09-062 | Là cán bộ ATTT, tôi muốn có bảng điều khiển tuân thủ quyền riêng tư, để một cái nhìn là biết việc nào gấp. | S | 1 | Đợt 2, W4 | FR-09-062; UC-09-34 |
| US-09-063 | Là cán bộ ATTT, tôi muốn có báo cáo tuân thủ định kỳ, để báo cáo đều đặn không cần làm tay. | C | 1 | Đợt 3, W5 | FR-09-063; UC-09-34 |
| US-09-064 | Là quản trị tỉnh, tôi muốn có cấu hình tham số PH-09 của tenant, để hành vi PH-09 điều chỉnh được mà không sửa mã. | M | 1 | Đợt 2, W4 | FR-09-064; UC-09-34 |

: Story của epic EP-09-K Kiểm toán, báo cáo và cấu hình

### 6.11. PH-10 · Sự kiện

Phân hệ có 11 epic, 76 story, tổng 266 điểm; wave phát triển W2, đợt MVP. Nguồn: D02-03-PH10 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-10-A · Dự án tích hợp

Epic gồm 5 story, 13 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-001 | Là cán bộ đầu mối của tổ chức, tôi muốn liệt kê, tìm kiếm và lọc dự án tích hợp, để người dùng thấy bảng dự án đã lọc, bấm một dòng để mở chi tiết. | M | 2 | MVP, W2 | FR-10-001; UC-10-01 |
| US-10-002 | Là người dùng có quyền xem, tôi muốn xem chi tiết dự án, để người dùng thấy các tab Tổng quan, Topic, Bên tham gia, Sơ đồ, Lịch sử của dự án. | M | 2 | MVP, W2 | FR-10-002; UC-10-01 |
| US-10-003 | Là kỹ sư tích hợp, tôi muốn tạo dự án tích hợp, để dự án mới hiện trong danh sách, màn chuyển sang chi tiết dự án với gợi ý "Tạo topic đầu tiên". | M | 3 | MVP, W2 | FR-10-003; UC-10-01 |
| US-10-004 | Là kỹ sư tích hợp, tôi muốn sửa dự án, để người dùng thấy thông tin mới trên chi tiết dự án và dòng thay đổi ở tab Lịch sử. | M | 3 | MVP, W2 | FR-10-004; UC-10-01 |
| US-10-005 | Là kỹ sư tích hợp, tôi muốn lưu trữ và khôi phục dự án, để dự án lưu trữ biến khỏi danh sách mặc định và sơ đồ, vẫn xem được khi lọc "Đã lưu trữ". | M | 3 | MVP, W2 | FR-10-005; UC-10-01 |

: Story của epic EP-10-A Dự án tích hợp

#### EP-10-B · Topic

Epic gồm 11 story, 50 điểm (10 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-006 | Là người dùng có quyền xem, tôi muốn liệt kê, tìm kiếm và lọc topic, để người dùng thấy bảng topic đã lọc, cờ cảnh báo lag và topic kế nhiệm nếu có. | M | 2 | MVP, W2 | FR-10-006; UC-10-02 |
| US-10-007 | Là người dùng có quyền xem, tôi muốn xem chi tiết topic, để người dùng thấy các tab Tổng quan, Cấu hình, Lược đồ, Publication, Subscription, DLQ, Cách kết nối, Chuyển đổi phiên bản, Lịch sử; nút thao tác hiện theo quyền và trạng thái. | M | 2 | MVP, W2 | FR-10-007; UC-10-02 |
| US-10-008 | Là kỹ sư tích hợp, tôi muốn tạo topic và gửi duyệt, để topic mới hiện ở trạng thái "Nháp" hoặc "Chờ duyệt"; người duyệt thấy yêu cầu trong "Việc của tôi". | M | 8* | MVP, W2 | FR-10-008; UC-10-02 |
| US-10-009 | Là người duyệt tích hợp, tôi muốn duyệt tạo topic và cấp phát trên cụm, để người duyệt thấy yêu cầu đã xử lý; người tạo nhận thông báo và thấy topic chuyển "Đang cấp phát" rồi "Đang hoạt động". | M | 8 | MVP, W2 | FR-10-009; UC-10-03 |
| US-10-010 | Là quản trị tỉnh, tôi muốn hệ thống theo dõi cấp phát và xử lý cấp phát thất bại, để kỹ sư thấy lỗi cấp phát rõ ràng trên chi tiết topic và nút xử lý; người vận hành nhận cảnh báo lệch cấu hình. | M | 3 | MVP, W2 | FR-10-010; UC-10-03 |
| US-10-011 | Là kỹ sư tích hợp, tôi muốn tăng số phân vùng của topic đang hoạt động, để người đề nghị thấy yêu cầu chờ duyệt; sau khi áp dụng, tab Cấu hình hiện số phân vùng mới và gợi ý chỉnh số worker. | M | 5 | MVP, W2 | FR-10-011; UC-10-04 |
| US-10-012 | Là kỹ sư tích hợp, tôi muốn thay đổi lưu giữ và chính sách dọn (compaction), để người dùng thấy giá trị mới, hoặc yêu cầu chờ duyệt kèm cảnh báo subscription có thể mất sự kiện. | M | 5 | MVP, W2 | FR-10-012; UC-10-04 |
| US-10-013 | Là kỹ sư tích hợp, tôi muốn hệ thống có chế độ định tuyến và khóa phân vùng, để người dùng thấy chế độ định tuyến và trường khóa trên tab Cấu hình; bên nhận nhận sự kiện cùng khóa theo đúng thứ tự. | M | 5 | MVP, W2 | FR-10-013; UC-10-02, 10-04 |
| US-10-014 | Là kỹ sư tích hợp, tôi muốn ngừng khuyến nghị và ngừng dùng topic, để các bên tham gia nhận thông báo và thấy topic kế nhiệm; sau khi ngừng dùng topic không phát, không nhận được. | M | 5 | MVP, W2 | FR-10-014; UC-10-05 |
| US-10-015 | Là kỹ sư tích hợp, tôi muốn tạo phiên bản chính mới của topic khi thay đổi phá vỡ, để kỹ sư thấy topic mới chờ duyệt; sau khi duyệt, hai topic chạy song song và bảng chuyển đổi (FR-10-016) hiện bên nhận chưa chuyển. | M | 5 | MVP, W2 | FR-10-015; UC-10-05 |
| US-10-016 | Là người dùng có quyền xem, tôi muốn theo dõi chuyển đổi bên nhận sang phiên bản topic mới, để chủ quản thấy danh sách bên chưa chuyển và ngày còn lại; dashboard có thẻ "topic sắp hết hạn". | S | 2 | MVP, W2 | FR-10-016; UC-10-05 |

: Story của epic EP-10-B Topic

#### EP-10-C · Lược đồ sự kiện

Epic gồm 8 story, 27 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-017 | Là kỹ sư tích hợp, tôi muốn soạn và kiểm tra lược đồ, để người dùng thấy lỗi gạch chân trong trình soạn và bảng Vấn đề; nháp được lưu khi không còn lỗi chặn. | M | 5 | MVP, W2 | FR-10-017; UC-10-02, 10-06 |
| US-10-018 | Là kỹ sư tích hợp, tôi muốn kiểm tra tương thích với các phiên bản đã có, để người dùng thấy khối kết quả "Đạt" hoặc bảng vi phạm theo trường kèm gợi ý. | M | 2 | MVP, W2 | FR-10-018; UC-10-06 |
| US-10-019 | Là kỹ sư tích hợp, tôi muốn gửi duyệt và duyệt phiên bản lược đồ, để bên phát dùng được lược đồ mới; tab Lược đồ hiện phiên bản mới là "Đang dùng". | M | 5 | MVP, W2 | FR-10-019; UC-10-06 |
| US-10-020 | Là người dùng có quyền xem, tôi muốn xem lịch sử phiên bản, so sánh và tải lược đồ, để người dùng thấy dòng thời gian phiên bản, bảng khác biệt tô màu và tải được tệp lược đồ. | M | 2 | MVP, W2 | FR-10-020; UC-10-06 |
| US-10-021 | Là kỹ sư tích hợp, tôi muốn đặt mức tương thích của lược đồ, để người dùng thấy mức tương thích mới trên UI-10-08; các bên nhận thông báo khi mức bị nới. | M | 5 | MVP, W2 | FR-10-021; UC-10-04 |
| US-10-022 | Là kỹ sư tích hợp, tôi muốn ngừng khuyến nghị và vô hiệu phiên bản lược đồ, để phiên bản hiện nhãn "Ngừng khuyến nghị" hoặc "Vô hiệu"; bên phát nhận cảnh báo. | S | 3 | MVP, W2 | FR-10-022; UC-10-06 |
| US-10-023 | Là quản trị tỉnh, tôi muốn hệ thống giám sát tuân thủ lược đồ của bên phát Kafka trực tiếp, để kỹ sư và SO thấy bên phát nào đang vi phạm và loại vi phạm, kèm nút tạm ngừng publication. | S | 3 | MVP, W2 | FR-10-023; UC-10-11 |
| US-10-024 | Là HTTT khai thác, tôi muốn cung cấp tra cứu lược đồ cho bên ngoài, để kỹ sư HTTT cấu hình serde đọc lược đồ tự động, không phải chép tay. | S | 2 | MVP, W2 | FR-10-024; UC-10-10 |

: Story của epic EP-10-C Lược đồ sự kiện

#### EP-10-D · Bên phát và bên nhận

Epic gồm 5 story, 20 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-025 | Là cán bộ đầu mối của tổ chức, tôi muốn liệt kê bên phát và bên nhận, để người dùng thấy bảng bên tham gia, mở chi tiết để xem publication, subscription của bên đó. | M | 2 | MVP, W2 | FR-10-025; UC-10-07 |
| US-10-026 | Là kỹ sư tích hợp, tôi muốn đăng ký bên phát, để bên phát mới hiện ở UI-10-09 với nút "Đề nghị phát lên topic". | M | 5 | MVP, W2 | FR-10-026; UC-10-07 |
| US-10-027 | Là kỹ sư tích hợp, tôi muốn đăng ký bên nhận, để bên nhận mới hiện ở UI-10-10 với nút "Đăng ký nhận sự kiện". | M | 5 | MVP, W2 | FR-10-027; UC-10-07 |
| US-10-028 | Là kỹ sư tích hợp, tôi muốn sửa, tạm ngừng, tiếp tục và ngừng dùng bên phát, bên nhận, để người dùng thấy nhãn trạng thái mới của bên và của từng quan hệ; HTTT bị tạm ngừng không phát, nhận được trong ≤ 60 giây (NFR-10-009). | M | 5 | MVP, W2 | FR-10-028; UC-10-08 |
| US-10-029 | Là kỹ sư tích hợp, tôi muốn hệ thống đồng bộ trạng thái với PH-01 và PH-04, để cán bộ thấy bên tham gia chuyển "Tạm ngừng" với lý do "Theo PH-01" ngay sau khi HTTT bị tạm ngừng. | M | 3 | MVP, W2 | FR-10-029; UC-10-08 |

: Story của epic EP-10-D Bên phát và bên nhận

#### EP-10-E · Publication và phát sự kiện

Epic gồm 5 story, 27 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-030 | Là kỹ sư tích hợp, tôi muốn đề nghị publication, để người đề nghị thấy publication "Chờ duyệt"; người duyệt thấy yêu cầu trong hộp việc. | M | 5 | MVP, W2 | FR-10-030; UC-10-09 |
| US-10-031 | Là người duyệt tích hợp, tôi muốn duyệt publication, cấp scope OAuth và ACL Kafka, để bên phát nhận thông báo đã được phát; tab Cách kết nối hiện đường phát tương ứng. | M | 8 | MVP, W2 | FR-10-031; UC-10-09 |
| US-10-032 | Là quản trị tỉnh, tôi muốn tạm ngừng, tiếp tục và thu hồi publication, để người dùng thấy nhãn "Tạm ngừng" hoặc "Đã thu hồi"; HTTT phát nhận lỗi ERR-10-102. | M | 3 | MVP, W2 | FR-10-032; UC-10-11 |
| US-10-033 | Là HTTT khai thác, tôi muốn phát sự kiện qua API phát, để HTTT nhận xác nhận đã ghi; bên nhận đã đăng ký nhận được sự kiện theo chế độ của mình. | M | 8 | MVP, W2 | FR-10-033; UC-10-10 |
| US-10-034 | Là kỹ sư tích hợp, tôi muốn phát sự kiện trực tiếp qua Kafka, để HTTT phát với thông lượng cao; vi phạm lược đồ hiện ở bảng tuân thủ. | M | 3 | MVP, W2 | FR-10-034; UC-10-11 |

: Story của epic EP-10-E Publication và phát sự kiện

#### EP-10-F · Subscription và giao nhận

Epic gồm 14 story, 59 điểm (12 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-035 | Là kỹ sư tích hợp, tôi muốn đề nghị subscription, để người đề nghị thấy subscription "Chờ duyệt" kèm kết quả xác minh endpoint. | M | 8* | MVP, W2 | FR-10-035; UC-10-12 |
| US-10-036 | Là quản trị tỉnh, tôi muốn hệ thống xác minh endpoint webhook, để người dùng thấy khối kết quả xác minh theo bước, đạt thì nút "Gửi duyệt" mở. | M | 2 | MVP, W2 | FR-10-036; UC-10-12 |
| US-10-037 | Là người duyệt tích hợp, tôi muốn duyệt subscription và cấp phát nhóm tiêu thụ, để bên nhận bắt đầu nhận sự kiện; người đề nghị thấy hộp "Nhận khóa ký" một lần. | M | 8 | MVP, W2 | FR-10-037; UC-10-13 |
| US-10-038 | Là kỹ sư tích hợp, tôi muốn hệ thống giao nhận ĐẨY: webhook ký HMAC, để HTTT nhận sự kiện có chữ ký; cán bộ thấy thống kê giao nhận trên UI-10-12. | M | 8 | MVP, W2 | FR-10-038; UC-10-14 |
| US-10-039 | Là vận hành tỉnh, tôi muốn hệ thống thử lại giãn dần và chính sách khi thất bại, để TO nhận cảnh báo "Đầu nhận lỗi" và thấy lý do tạm ngừng trên UI-10-12. | M | 3 | MVP, W2 | FR-10-039; UC-10-14 |
| US-10-040 | Là người đề nghị subscription, tôi muốn điểm bắt đầu và offset bắt đầu, để bên nhận nhận sự kiện từ đúng điểm đã chọn. | M | 2 | MVP, W2 | FR-10-040; UC-10-12 |
| US-10-041 | Là quản trị tỉnh, tôi muốn tạm dừng, tiếp tục subscription, để màn hiện nhãn "Tạm dừng" và thời gian còn lại trước khi bản tin chưa đọc hết lưu giữ (`retentionHours` trừ `lagSeconds`), cảnh báo khi dưới 24 giờ. | M | 3 | MVP, W2 | FR-10-041; UC-10-16 |
| US-10-042 | Là quản trị tỉnh, tôi muốn xoay khóa ký webhook, để người dùng thấy hai khóa và ngày hết chồng lấn; bên nhận cập nhật bí mật trong thời gian đó. | M | 5 | MVP, W2 | FR-10-042; UC-10-17 |
| US-10-043 | Là HTTT khai thác, tôi muốn giao nhận KÉO qua API, để HTTT nhận sự kiện theo nhịp của mình, không mất khi xử lý lỗi giữa chừng. | M | 8 | MVP, W2 | FR-10-043; UC-10-15 |
| US-10-044 | Là HTTT khai thác, tôi muốn giao nhận KÉO qua Kafka listener ngoài, để HTTT tiêu thụ trực tiếp với thông lượng cao; cán bộ vẫn thấy lag trên UI-10-17. | S | 3 | MVP, W2 | FR-10-044; UC-10-15 |
| US-10-045 | Là kỹ sư tích hợp, tôi muốn hệ thống giao nhận nội bộ cho luồng và DU, để cán bộ thấy luồng, DU trên sơ đồ và bảng lag như mọi bên nhận. | M | 1 | MVP, W2 | FR-10-045; UC-10-25 |
| US-10-046 | Là kỹ sư tích hợp, tôi muốn sửa tham số subscription, để người dùng thấy tham số mới hoặc dải "Thay đổi chờ duyệt". | M | 3 | MVP, W2 | FR-10-046; UC-10-16 |
| US-10-047 | Là kỹ sư tích hợp, tôi muốn thu hồi subscription, để bên nhận không nhận thêm sự kiện; lịch sử và DLQ vẫn xem được. | M | 3 | MVP, W2 | FR-10-047; UC-10-16 |
| US-10-048 | Là kỹ sư tích hợp, tôi muốn lọc sự kiện và gộp lô khi đẩy, để bên nhận chỉ nhận sự kiện cần và ít lượt gọi hơn. | C | 2 | Đợt sau, Sau G5 | FR-10-048 |

: Story của epic EP-10-F Subscription và giao nhận

#### EP-10-G · DLQ tầng sự kiện và phát lại

Epic gồm 5 story, 16 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-049 | Là kỹ sư tích hợp, tôi muốn hệ thống chuyển sự kiện giao thất bại vào DLQ tầng sự kiện, để người vận hành thấy mục mới ở UI-10-15 và số mục `NEW` trên dashboard. | M | 3 | MVP, W2 | FR-10-049; UC-10-14 |
| US-10-050 | Là quản trị tỉnh, tôi muốn tra cứu, xem và loại bỏ mục DLQ, để người vận hành thấy mục theo mã lỗi và xử lý được từng mục hoặc theo lô. | M | 2 | MVP, W2 | FR-10-050; UC-10-18 |
| US-10-051 | Là quản trị tỉnh, tôi muốn đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian, để người đề nghị thấy ước lượng số bản tin, thời gian chạy và trạng thái chờ duyệt. | M | 5 | MVP, W2 | FR-10-051; UC-10-19 |
| US-10-052 | Là kỹ sư tích hợp, tôi muốn hệ thống thực thi, theo dõi và hủy lượt phát lại, để người vận hành thấy thanh tiến độ, số đã giao, số lỗi và thời gian còn lại. | M | 3 | MVP, W2 | FR-10-052; UC-10-19 |
| US-10-053 | Là quản trị tỉnh, tôi muốn phát lại mục DLQ, để người vận hành thấy mục chuyển "Đã phát lại" hoặc trở lại "Mới" kèm số lần thử. | M | 3 | MVP, W2 | FR-10-053; UC-10-18 |

: Story của epic EP-10-G DLQ tầng sự kiện và phát lại

#### EP-10-H · Giám sát, dashboard và sơ đồ

Epic gồm 6 story, 11 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-054 | Là kỹ sư tích hợp, tôi muốn hệ thống thu thập consumer lag, để người vận hành thấy lag mới nhất và xu hướng. | M | 2 | MVP, W2 | FR-10-054; UC-10-20 |
| US-10-055 | Là vận hành tỉnh, tôi muốn hệ thống cảnh báo lag và nhóm tiêu thụ ngừng tiến, để TO thấy bảng subscription theo mức cảnh báo, xác nhận được nhưng không tắt được việc đánh giá. | M | 2 | MVP, W2 | FR-10-055; UC-10-20 |
| US-10-056 | Là người dùng có quyền xem, tôi muốn thống kê giao nhận và lượt giao gần đây, để người vận hành thấy tỷ lệ lỗi, mã lỗi chính và gợi ý xử lý theo mã. | M | 2 | MVP, W2 | FR-10-056; UC-10-16 |
| US-10-057 | Là người dùng có quyền xem, tôi muốn có dashboard sự kiện, để cán bộ thấy tình hình trục trong một màn. | M | 2 | MVP, W2 | FR-10-057; UC-10-21 |
| US-10-058 | Là người dùng có quyền xem, tôi muốn có sơ đồ kết nối tương tác, để người dùng lần ra bên đang chậm hoặc lỗi. | M | 2 | MVP, W2 | FR-10-058; UC-10-21 |
| US-10-059 | Là kỹ sư tích hợp, tôi muốn hệ thống xuất số liệu sang PH-13, để PH-13 có bảng và cảnh báo cho trục. | M | 1 | MVP, W2 | FR-10-059; UC-10-20 |

: Story của epic EP-10-H Giám sát, dashboard và sơ đồ

#### EP-10-I · Danh mục cấu hình, hạn mức, đa tenant, kiểm toán

Epic gồm 6 story, 8 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-060 | Là quản trị tỉnh, tôi muốn danh mục kiểu giao tiếp, để biểu mẫu chỉ còn mục đã bật. | M | 1 | MVP, W2 | FR-10-060; UC-10-22 |
| US-10-061 | Là quản trị tỉnh, tôi muốn danh mục chế độ định tuyến, để biểu mẫu chỉ còn chế độ đã bật. | M | 1 | MVP, W2 | FR-10-061; UC-10-22 |
| US-10-062 | Là quản trị nền tảng, tôi muốn hạn mức theo tenant và phân bổ cho bên tham gia, để không tenant nào chiếm hết cụm dùng chung. | M | 2 | MVP, W2 | FR-10-062; UC-10-22 |
| US-10-063 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để tham số mới có hiệu lực theo phạm vi đã nêu. | M | 1 | MVP, W2 | FR-10-063; UC-10-22 |
| US-10-064 | Là kỹ sư tích hợp, tôi muốn hệ thống cách ly đa tenant trên trục sự kiện, để tenant chỉ thấy tài nguyên của mình. | M | 2 | MVP, W2 | FR-10-064; UC-10-10, 10-24 |
| US-10-065 | Là kỹ sư tích hợp, tôi muốn hệ thống kiểm toán và lịch sử thay đổi, để mọi thay đổi tra được theo đối tượng. | M | 1 | MVP, W2 | FR-10-065; UC-10-01 |

: Story của epic EP-10-I Danh mục cấu hình, hạn mức, đa tenant, kiểm toán

#### EP-10-J · Đăng ký máy với máy

Epic gồm 4 story, 15 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-066 | Là kỹ sư tích hợp, tôi muốn hệ thống đăng ký topic hộ PH-05 cho CDC, để PH-05 có topic để bật CDC. | M | 8 | MVP, W2 | FR-10-066; UC-10-23 |
| US-10-067 | Là quản trị nền tảng, tôi muốn hệ thống đăng ký topic cho DU nội bộ và topic nền tảng, để DU có topic miền sẵn sàng khi khởi động. | M | 3 | MVP, W2 | FR-10-067; UC-10-24 |
| US-10-068 | Là kỹ sư tích hợp, tôi muốn hệ thống xử lý thông báo thay đổi lược đồ CDC, để bên nhận được báo trước khi cấu trúc đổi. | M | 2 | MVP, W2 | FR-10-068; UC-10-23 |
| US-10-069 | Là kỹ sư tích hợp, tôi muốn hệ thống kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế, để luồng không vào vận hành khi thiếu quyền trên trục. | M | 2 | MVP, W2 | FR-10-069; UC-10-25 |

: Story của epic EP-10-J Đăng ký máy với máy

#### EP-10-K · Xuất nhập khai báo và di trú từ Pulsar

Epic gồm 7 story, 20 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-10-070 | Là người dùng có quyền xem, tôi muốn xuất khai báo, để người dùng có bản khai báo đầy đủ, không chứa bí mật. | S | 1 | MVP, W2 | FR-10-070; UC-10-28 |
| US-10-071 | Là kỹ sư tích hợp, tôi muốn nhập khai báo có xem trước, để khai báo đích sẵn sàng duyệt. | C | 2 | Đợt sau, Sau G5 | FR-10-071; UC-10-28 |
| US-10-072 | Là quản trị tỉnh, tôi muốn nhập kiểm kê Pulsar và lập ánh xạ, để khai báo đích sẵn sàng duyệt. | M | 3 | MVP, W2 | FR-10-072; UC-10-26 |
| US-10-073 | Là quản trị tỉnh, tôi muốn cầu nối Pulsar sang Kafka tạm thời, để bản tin mới trên Pulsar có trên Kafka trong ≤ 60 giây ở p95 (NFR-10-018). | M | 8 | MVP, W2 | FR-10-073; UC-10-27 |
| US-10-074 | Là quản trị tỉnh, tôi muốn cầu nối ngược Kafka sang Pulsar cho bên nhận cũ chưa chuyển, để subscriber cũ nhận bản tin như trước. | S | 2 | MVP, W2 | FR-10-074; UC-10-27 |
| US-10-075 | Là quản trị tỉnh, tôi muốn hệ thống đối chiếu, chuyển hẳn và quay lui, để hub cũ được tắt theo từng topic có căn cứ số liệu. | M | 3 | MVP, W2 | FR-10-075; UC-10-27 |
| US-10-076 | Là quản trị tỉnh, tôi muốn có báo cáo tiến độ di trú, để thấy được việc còn lại trước khi tắt Hub cũ. | S | 1 | MVP, W2 | FR-10-076; UC-10-27 |

: Story của epic EP-10-K Xuất nhập khai báo và di trú từ Pulsar

### 6.12. PH-11 · Quy trình liên thông

Phân hệ có 10 epic, 66 story, tổng 147 điểm; wave phát triển W4, đợt Đợt 2. Nguồn: D02-03-PH11 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-11-A · Mô hình quy trình

Epic gồm 11 story, 33 điểm (10 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-001 | Là quản trị tỉnh, tôi muốn liệt kê, tìm kiếm mô hình quy trình, để người dùng thấy danh sách mô hình, biết mô hình nào đang chạy, mô hình nào đang chờ duyệt. | M | 2 | Đợt 2, W4 | FR-11-001; UC-11-01 |
| US-11-002 | Là kỹ sư tích hợp, tôi muốn tạo mô hình quy trình, để người dùng có bản nháp mở sẵn trên trình thiết kế. | M | 3 | Đợt 2, W4 | FR-11-002; UC-11-01 |
| US-11-003 | Là kỹ sư tích hợp, tôi muốn thiết kế sơ đồ BPMN 2.0 trên trình thiết kế, để sơ đồ được lưu liên tục, lỗi hiện ngay trên phần tử. | M | 3 | Đợt 2, W4 | FR-11-003; UC-11-02 |
| US-11-004 | Là kỹ sư tích hợp, tôi muốn có cấu hình thuộc tính bước, để mỗi bước có đủ thông tin để chạy; bước thiếu hiện dấu cảnh báo. | M | 3 | Đợt 2, W4 | FR-11-004; UC-11-02 |
| US-11-005 | Là kỹ sư tích hợp, tôi muốn kiểm tra tĩnh mô hình, để người dùng thấy danh sách lỗi, bấm vào lỗi thì khung vẽ nhảy tới phần tử. | M | 2 | Đợt 2, W4 | FR-11-005; UC-11-02 |
| US-11-006 | Là kỹ sư tích hợp, tôi muốn quản lý phiên bản nháp, so sánh hai phiên bản, để người dùng có nháp mới để sửa, hoặc thấy trực quan chỗ khác nhau giữa hai phiên bản. | M | 2 | Đợt 2, W4 | FR-11-006; UC-11-01 |
| US-11-007 | Là kỹ sư tích hợp, tôi muốn gửi duyệt phát hành mô hình, để bản nháp bị khóa, người duyệt nhận việc trong hộp "Việc của tôi". | M | 3 | Đợt 2, W4 | FR-11-007; UC-11-05 |
| US-11-008 | Là người duyệt tích hợp, tôi muốn duyệt hoặc từ chối phát hành, triển khai lên engine, để bản được duyệt chạy cho hồ sơ mới; hồ sơ đang xử lý không bị ảnh hưởng. | M | 5 | Đợt 2, W4 | FR-11-008; UC-11-05 |
| US-11-009 | Là người duyệt tích hợp, tôi muốn ngừng dùng, thu hồi phiên bản, để hồ sơ mới không vào phiên bản cũ; hồ sơ cũ chạy tiếp. | M | 3 | Đợt 2, W4 | FR-11-009; UC-11-05 |
| US-11-010 | Là kỹ sư tích hợp, tôi muốn nhập, xuất tệp BPMN 2.0 XML và gói quy trình, để người dùng đưa mô hình từ môi trường thử sang chính thức hoặc từ tỉnh khác vào mà không vẽ lại. | M | 5 | Đợt 2, W4 | FR-11-010; UC-11-01 |
| US-11-011 | Là kỹ sư tích hợp, tôi muốn chạy thử mô hình với service task giả lập, để người thiết kế thấy quy trình chạy đúng đường mong muốn trước khi gửi duyệt; kết quả chạy thử đính kèm `publish_request`. | S | 2 | Đợt 2, W4 | FR-11-011; UC-11-02 |

: Story của epic EP-11-A Mô hình quy trình

#### EP-11-B · Tài nguyên quy trình

Epic gồm 6 story, 12 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-012 | Là kỹ sư tích hợp, tôi muốn quản lý biểu mẫu việc người dùng, để biểu mẫu sẵn sàng để gắn vào việc người dùng ở FR-11-004. | M | 2 | Đợt 2, W4 | FR-11-012; UC-11-03 |
| US-11-013 | Là kỹ sư tích hợp, tôi muốn đăng ký ý định nghiệp vụ và ánh xạ sang luồng PH-04, để kỹ sư chọn ý định từ danh sách khi vẽ bước tự động; đổi luồng thực thi chỉ sửa ánh xạ. | M | 2 | Đợt 2, W4 | FR-11-013; UC-11-04 |
| US-11-014 | Là kỹ sư tích hợp, tôi muốn đăng ký hành động bù trừ theo bước, để mỗi bước rủi ro có cách quay lại rõ ràng; ví dụ: `guiTuPhap` ↔ `danhDauChoXuLy` ("Không xóa, văn bản hộ tịch đã phát hành"); `guiCuTru` ↔ `huyDangKyThuongTru` ("Chỉ khi bước đã thành công") …. | M | 2 | Đợt 2, W4 | FR-11-014; UC-11-04 |
| US-11-015 | Là quản trị nền tảng, tôi muốn quản lý mẫu quy trình dùng chung, để tỉnh có thư viện mẫu để tạo quy trình liên thông nhanh. | S | 3 | Đợt 2, W4 | FR-11-015; UC-11-01 |
| US-11-016 | Là kỹ sư tích hợp, tôi muốn khai báo biến quy trình và phân loại dữ liệu, để mọi nơi hiển thị và mọi sự kiện biết biến nào phải che. | M | 2 | Đợt 2, W4 | FR-11-016; UC-11-03 |
| US-11-017 | Là kỹ sư tích hợp, tôi muốn có bảng quyết định DMN đơn giản cho rẽ nhánh, để rẽ nhánh theo bảng, sửa không cần vẽ lại. | C | 1 | Đợt 2, W4 | FR-11-017; UC-11-03 |

: Story của epic EP-11-B Tài nguyên quy trình

#### EP-11-C · Phiên quy trình

Epic gồm 10 story, 24 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-018 | Là vận hành tỉnh, tôi muốn hệ thống khởi tạo phiên qua API, để kênh DVC có mã phiên để tra tiến độ, công dân không phải chờ cơ quan xử lý. | M | 5 | Đợt 2, W4 | FR-11-018; UC-11-06 |
| US-11-019 | Là kỹ sư tích hợp, tôi muốn khởi tạo phiên từ sự kiện PH-10, để hồ sơ bắt đầu được điều phối ngay khi tiếp nhận. | S | 2 | Đợt 2, W4 | FR-11-019; UC-11-06 |
| US-11-020 | Là quản trị tỉnh, tôi muốn khởi tạo phiên thủ công trên giao diện, để phiên được tạo và mở ngay UI-11-12. | S | 2 | Đợt 2, W4 | FR-11-020; UC-11-06 |
| US-11-021 | Là vận hành tỉnh, tôi muốn liệt kê, tìm kiếm phiên, để người dùng tìm thấy hồ sơ và tình trạng của nó trong một màn. | M | 1 | Đợt 2, W4 | FR-11-021; UC-11-15 |
| US-11-022 | Là vận hành tỉnh, tôi muốn xem chi tiết phiên, để một màn đủ để trả lời "hồ sơ đang ở đâu, vì sao". | M | 2 | Đợt 2, W4 | FR-11-022; UC-11-15 |
| US-11-023 | Là quản trị tỉnh, tôi muốn tạm dừng, tiếp tục phiên, để phiên dừng hoặc chạy tiếp; việc liên quan hiện nhãn "Tạm dừng" trong hộp việc. | M | 2 | Đợt 2, W4 | FR-11-023; UC-11-16 |
| US-11-024 | Là quản trị tỉnh, tôi muốn hủy phiên kèm bù trừ tùy chọn, để hồ sơ dừng sạch; cơ quan đã xử lý được hoàn tác theo nghiệp vụ. | M | 3 | Đợt 2, W4 | FR-11-024; UC-11-16 |
| US-11-025 | Là quản trị tỉnh, tôi muốn sửa biến phiên có kiểm soát, để biến đúng, phiên chạy tiếp, có dấu vết hai người. | S | 2 | Đợt 2, W4 | FR-11-025; UC-11-17 |
| US-11-026 | Là quản trị tỉnh, tôi muốn di trú phiên sang phiên bản mô hình mới, để phiên chạy tiếp theo quy định mới, phiên không di trú được vẫn ở bản cũ. | S | 3 | Đợt 2, W4 | FR-11-026; UC-11-17 |
| US-11-027 | Là quản trị tỉnh, tôi muốn chuyển phiên tới bước khác, để phiên đi tiếp từ bước đích. | S | 2 | Đợt 2, W4 | FR-11-027; UC-11-17 |

: Story của epic EP-11-C Phiên quy trình

#### EP-11-D · Bước tự động

Epic gồm 6 story, 16 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-028 | Là quản trị tỉnh, tôi muốn hệ thống gửi lệnh thực thi service task tới PH-04, để PH-04 nhận đúng một lệnh nghiệp vụ; người xem phiên thấy bước "Đang chờ {publicName}". | M | 3 | Đợt 2, W4 | FR-11-028; UC-11-07 |
| US-11-029 | Là vận hành tỉnh, tôi muốn hệ thống nhận kết quả, lỗi service task và tương quan, để phiên đi tiếp ngay khi cơ quan trả kết quả; lỗi được đưa về nhánh đúng. | M | 3 | Đợt 2, W4 | FR-11-029; UC-11-07 |
| US-11-030 | Là vận hành tỉnh, tôi muốn hệ thống chờ thông điệp, sự kiện, để phiên đi tiếp ngay khi có tín hiệu. | M | 2 | Đợt 2, W4 | FR-11-030; UC-11-08 |
| US-11-031 | Là kỹ sư tích hợp, tôi muốn hẹn giờ khởi tạo, trung gian, biên, để quy trình tự đi tiếp hoặc tự nhắc đúng giờ hành chính. | M | 3 | Đợt 2, W4 | FR-11-031; UC-11-08 |
| US-11-032 | Là kỹ sư tích hợp, tôi muốn gửi thông báo từ quy trình, để người liên quan được báo đúng lúc. | S | 3 | Đợt 2, W4 | FR-11-032; UC-11-08 |
| US-11-033 | Là kỹ sư tích hợp, tôi muốn gọi quy trình con, để quy trình con dùng chung, sửa một chỗ. | S | 2 | Đợt 2, W4 | FR-11-033; UC-11-08 |

: Story của epic EP-11-D Bước tự động

#### EP-11-E · Việc người dùng

Epic gồm 11 story, 24 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-034 | Là vận hành tỉnh, tôi muốn hệ thống tạo việc và phân công, để cán bộ hoặc nhóm thấy việc mới trong hộp việc. | M | 3 | Đợt 2, W4 | FR-11-034; UC-11-09 |
| US-11-035 | Là vận hành tỉnh, tôi muốn hệ thống đăng ký việc vào hộp "Việc của tôi", để việc mới hiện trong hộp ≤ 5 s (NFR-11-015), có nhãn hạn màu. | M | 1 | Đợt 2, W4 | FR-11-035; UC-11-09 |
| US-11-036 | Là vận hành tỉnh, tôi muốn nhận việc, trả lại việc, để việc chuyển sang tên người nhận, biến mất khỏi hộp việc của người khác trong nhóm. | M | 2 | Đợt 2, W4 | FR-11-036; UC-11-10 |
| US-11-037 | Là quản trị tỉnh, tôi muốn xem chi tiết việc và hồ sơ liên quan, để một màn đủ để xử lý hồ sơ. | M | 2 | Đợt 2, W4 | FR-11-037; UC-11-10 |
| US-11-038 | Là người nhận, tôi muốn hoàn thành việc với biểu mẫu, ý kiến, quyết định, để hồ sơ đi tiếp; nếu bước sau cũng giao cho người này, màn mở luôn việc kế tiếp. | M | 5 | Đợt 2, W4 | FR-11-038; UC-11-10 |
| US-11-039 | Là người nhận, tôi muốn lưu nháp kết quả việc, để mở lại việc thấy đúng phần đã nhập. | S | 1 | Đợt 2, W4 | FR-11-039; UC-11-10 |
| US-11-040 | Là quản trị tỉnh, tôi muốn chuyển việc cho người khác, để người nhận mới thấy việc ngay, kèm lý do chuyển. | M | 2 | Đợt 2, W4 | FR-11-040; UC-11-12 |
| US-11-041 | Là quản trị tỉnh, tôi muốn ủy quyền khi vắng mặt, để việc tự đến người thay trong thời gian vắng. | S | 2 | Đợt 2, W4 | FR-11-041; UC-11-13 |
| US-11-042 | Là quản trị tỉnh, tôi muốn phân công lại hàng loạt, để việc tồn được phân bổ lại trong vài phút. | S | 2 | Đợt 2, W4 | FR-11-042; UC-11-13 |
| US-11-043 | Là người nhận, tôi muốn đính kèm tệp, trao đổi ý kiến trên việc, để trao đổi gắn với hồ sơ, không phân tán ở thư điện tử. | S | 1 | Đợt 2, W4 | FR-11-043; UC-11-12 |
| US-11-044 | Là người nhận, tôi muốn trả về bước trước, yêu cầu bổ sung hồ sơ, để hồ sơ quay lại đúng người, hoặc công dân được báo cần bổ sung gì, hạn không bị tính oan. | M | 3 | Đợt 2, W4 | FR-11-044; UC-11-11 |

: Story của epic EP-11-E Việc người dùng

#### EP-11-F · Hạn xử lý

Epic gồm 6 story, 10 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-045 | Là quản trị tỉnh, tôi muốn quản lý lịch làm việc theo tenant, để hạn mọi hồ sơ tính theo đúng ngày nghỉ của tỉnh. | M | 1 | Đợt 2, W4 | FR-11-045; UC-11-14 |
| US-11-046 | Là quản trị tỉnh, tôi muốn hệ thống tính hạn xử lý theo ngày làm việc cho phiên và việc, để cán bộ thấy "Còn 1 ngày 3 giờ làm việc" thay vì giờ lịch. | M | 2 | Đợt 2, W4 | FR-11-046; UC-11-06, 11-14 |
| US-11-047 | Là vận hành tỉnh, tôi muốn hệ thống nhắc hạn trước hạn, để cán bộ được nhắc trước hạn. | M | 2 | Đợt 2, W4 | FR-11-047; UC-11-14 |
| US-11-048 | Là vận hành tỉnh, tôi muốn hệ thống xử lý quá hạn, leo thang, để quá hạn được nhìn thấy và có người chịu trách nhiệm xử lý. | M | 2 | Đợt 2, W4 | FR-11-048; UC-11-14 |
| US-11-049 | Là vận hành tỉnh, tôi muốn hệ thống tạm dừng tính hạn khi chờ bổ sung, để hạn hồ sơ phản ánh đúng thời gian cơ quan xử lý. | M | 2 | Đợt 2, W4 | FR-11-049; UC-11-11 |
| US-11-050 | Là quản trị tỉnh, tôi muốn có báo cáo đúng hạn, trễ hạn, để lãnh đạo biết đơn vị nào, bước nào hay trễ. | S | 1 | Đợt 2, W4 | FR-11-050; UC-11-21 |

: Story của epic EP-11-F Hạn xử lý

#### EP-11-G · Saga bù trừ

Epic gồm 4 story, 9 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-051 | Là quản trị tỉnh, tôi muốn hệ thống điều phối bù trừ khi lỗi bước, để cơ quan đã xử lý được hoàn tác theo nghiệp vụ; công dân được báo hồ sơ không thành và cách khắc phục. | M | 3 | Đợt 2, W4 | FR-11-051; UC-11-18 |
| US-11-052 | Là quản trị tỉnh, tôi muốn theo dõi nhật ký Saga, để người dùng thấy rõ phần nào đã hoàn tác ở cơ quan nào. | M | 1 | Đợt 2, W4 | FR-11-052; UC-11-19 |
| US-11-053 | Là quản trị tỉnh, tôi muốn xử lý bù trừ thất bại, để không còn dữ liệu lệch mà không ai biết; mỗi xử lý tay có bằng chứng. | M | 3 | Đợt 2, W4 | FR-11-053; UC-11-19 |
| US-11-054 | Là quản trị tỉnh, tôi muốn hệ thống đối soát bù trừ định kỳ, để lệch được phát hiện trong một ngày. | S | 2 | Đợt 2, W4 | FR-11-054; UC-11-19 |

: Story của epic EP-11-G Saga bù trừ

#### EP-11-H · Tiến độ

Epic gồm 3 story, 5 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-055 | Là vận hành tỉnh, tôi muốn cung cấp tiến độ hồ sơ cho kênh DVC, để công dân biết tiến độ từng bước theo ngôn ngữ dễ hiểu. | M | 2 | Đợt 2, W4 | FR-11-055; UC-11-20 |
| US-11-056 | Là vận hành tỉnh, tôi muốn hệ thống phát sự kiện tiến độ, để công dân nhận thông báo tiến độ theo từng bước, không chỉ kết quả cuối. | M | 2 | Đợt 2, W4 | FR-11-056; UC-11-06, 11-20 |
| US-11-057 | Là quản trị tỉnh, tôi muốn tra lịch sử bước phục vụ kiểm toán, để bằng chứng đầy đủ cho thanh tra một hồ sơ. | M | 1 | Đợt 2, W4 | FR-11-057; UC-11-24 |

: Story của epic EP-11-H Tiến độ

#### EP-11-I · Giám sát

Epic gồm 4 story, 7 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-058 | Là quản trị tỉnh, tôi muốn có bảng điều khiển giám sát quy trình, để vận hành thấy ngay chỗ cần xử lý. | M | 1 | Đợt 2, W4 | FR-11-058; UC-11-21 |
| US-11-059 | Là vận hành tỉnh, tôi muốn hệ thống phát hiện tắc nghẽn bước, để điểm nghẽn hiện trước khi thành trễ hạn hàng loạt. | S | 2 | Đợt 2, W4 | FR-11-059; UC-11-21 |
| US-11-060 | Là quản trị tỉnh, tôi muốn quản lý sự cố engine và thử lại, để hồ sơ kẹt do lỗi kỹ thuật chạy tiếp sau khi khắc phục. | M | 3 | Đợt 2, W4 | FR-11-060; UC-11-22 |
| US-11-061 | Là quản trị tỉnh, tôi muốn có chỉ số và cảnh báo vận hành, để cảnh báo đúng ngưỡng của tỉnh. | M | 1 | Đợt 2, W4 | FR-11-061; UC-11-23 |

: Story của epic EP-11-I Giám sát

#### EP-11-J · Quản trị

Epic gồm 5 story, 7 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-11-062 | Là quản trị tỉnh, tôi muốn có cấu hình tham số 11.* theo tenant, để ngưỡng mới có hiệu lực trong một phút. | M | 1 | Đợt 2, W4 | FR-11-062; UC-11-23 |
| US-11-063 | Là quản trị tỉnh, tôi muốn lưu giữ, dọn lịch sử phiên, để engine gọn, lịch sử nghiệp vụ còn đủ thời hạn. | M | 2 | Đợt 2, W4 | FR-11-063; UC-11-23 |
| US-11-064 | Là quản trị tỉnh, tôi muốn xuất bằng chứng tuân thủ BPMN 2.0, để hồ sơ tuân thủ có biên bản chạy thật. | M | 2 | Đợt 2, W4 | FR-11-064; UC-11-24 |
| US-11-065 | Là quản trị tỉnh, tôi muốn xem nhật ký kiểm toán phân hệ, để kiểm toán truy được mọi thao tác nhạy cảm. | M | 1 | Đợt 2, W4 | FR-11-065; UC-11-24 |
| US-11-066 | Là người nhận việc, tôi muốn gợi ý xử lý việc bằng AI, để cán bộ xử lý nhanh hơn, không phụ thuộc AI. | C | 1 | Đợt 2, W4 | FR-11-066; UC-11-10 |

: Story của epic EP-11-J Quản trị

### 6.13. PH-12 · Định danh và phân quyền

Phân hệ có 8 epic, 62 story, tổng 316 điểm; wave phát triển W1, đợt MVP. Nguồn: D02-03-PH12 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-12-A · Tài khoản người dùng

Epic gồm 10 story, 50 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-001 | Là quản trị tỉnh, tôi muốn liệt kê, tìm kiếm và lọc người dùng, để người dùng thấy danh sách phân trang, có thẻ lọc nhanh và cảnh báo trực quan cho tài khoản quá 30 ngày không đăng nhập. | M | 3 | MVP, W1 | FR-12-001; UC-12-01 |
| US-12-002 | Là quản trị tỉnh, tôi muốn xem chi tiết người dùng, để một màn hình có các tab Tổng quan, Vai trò, Quyền hiệu lực, Yếu tố xác thực, Phiên, Lịch sử; nút thao tác hiện theo quyền của người xem. | M | 3 | MVP, W1 | FR-12-002; UC-12-01 |
| US-12-003 | Là quản trị tỉnh, tôi muốn tạo tài khoản người dùng, để TA thấy tài khoản ở trạng thái "Chờ kích hoạt"; cán bộ nhận thư với liên kết còn hiệu lực 24 giờ. | M | 8 | MVP, W1 | FR-12-003; UC-12-02 |
| US-12-004 | Là quản trị tỉnh, tôi muốn sửa thông tin và chuyển đơn vị của người dùng, để thông tin hiển thị cập nhật; vai trò theo đơn vị cũ không còn sót lại. | M | 5 | MVP, W1 | FR-12-004; UC-12-03 |
| US-12-005 | Là quản trị tỉnh, tôi muốn khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản, để tài khoản bị khóa hoặc vô hiệu không đăng nhập được, mọi phiên và token của họ bị chặn tại cổng trong 60 giây; tài khoản kích hoạt lại nhận thư và phải đặt mật khẩu mới. | M | 5 | MVP, W1 | FR-12-005; UC-12-04 |
| US-12-006 | Là quản trị tỉnh, tôi muốn kích hoạt tài khoản lần đầu, để cán bộ vào được hệ thống với mật khẩu của riêng mình; tài khoản quyền cao đã có yếu tố thứ hai. | M | 5 | MVP, W1 | FR-12-006; UC-12-02 |
| US-12-007 | Là quản trị tỉnh, tôi muốn đặt lại mật khẩu khi quên, để cán bộ đặt lại được mật khẩu và mọi phiên cũ bị đăng xuất; không ai suy ra được danh sách tài khoản. | M | 5 | MVP, W1 | FR-12-007; UC-12-06 |
| US-12-008 | Là quản trị tỉnh, tôi muốn hệ thống tự vô hiệu tài khoản và tạm ngừng client không hoạt động, để tài khoản không dùng quá ngưỡng bị vô hiệu không quá 24 giờ sau khi vượt ngưỡng (SEC-27). | M | 5 | MVP, W1 | FR-12-008; UC-12-07 |
| US-12-009 | Là quản trị tỉnh, tôi muốn nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ, để hàng trăm tài khoản được tạo đúng vai trò chuẩn trong một lượt; mỗi cán bộ nhận thư kích hoạt riêng. | M | 8 | MVP, W1 | FR-12-009; UC-12-05 |
| US-12-010 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ thuộc tính người dùng từ danh mục đơn vị, để thông tin đơn vị của người dùng khớp danh mục; TA thấy danh sách người dùng cần xử lý. | S | 3 | MVP, W1 | FR-12-010; UC-12-07 |

: Story của epic EP-12-A Tài khoản người dùng

#### EP-12-B · Vai trò, nhóm và quyền

Epic gồm 9 story, 46 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-011 | Là quản trị nền tảng, tôi muốn xem danh mục vai trò chuẩn và quyền, để người dùng thấy bảng 22 vai trò và quyền; vai trò bắt buộc MFA có nhãn riêng. | M | 2 | MVP, W1 | FR-12-011; UC-12-08 |
| US-12-012 | Là quản trị tỉnh, tôi muốn gán và gỡ vai trò cho người dùng, để cán bộ có thêm hoặc mất vai trò; quyền hạ có hiệu lực ở OPA trong không quá 60 giây và quyền nâng có hiệu lực khi người đó có token mới (tối đa 5 phút). | M | 8 | MVP, W1 | FR-12-012; UC-12-09 |
| US-12-013 | Là quản trị tỉnh, tôi muốn chặn cặp vai trò xung đột và duyệt ngoại lệ có thời hạn, để cặp vai trò xung đột bị chặn mặc định; ngoại lệ chỉ tồn tại tới hạn và tự gỡ. | M | 8 | MVP, W1 | FR-12-013; UC-12-10 |
| US-12-014 | Là quản trị tỉnh, tôi muốn quản lý nhóm và đơn vị tổ chức, để TA có cây đơn vị khớp danh mục và các nhóm công việc riêng. | M | 5 | MVP, W1 | FR-12-014; UC-12-11 |
| US-12-015 | Là quản trị tỉnh, tôi muốn tạo vai trò tùy biến của tenant, để vai trò tùy biến dùng được như vai trò chuẩn, chỉ mang quyền không đặc quyền và đã có người thứ hai duyệt. | S | 5 | Đợt 2, W4 | FR-12-015; UC-12-12 |
| US-12-016 | Là cán bộ ATTT, tôi muốn xem quyền hiệu lực của người dùng, để cán bộ ATTT có bảng quyền hiệu lực đối chiếu được với ma trận D02-08; hỏi ngược cho danh sách người có quyền nhạy cảm. | M | 3 | MVP, W1 | FR-12-016; UC-12-08 |
| US-12-017 | Là quản trị nền tảng, tôi muốn cấp quyền có thời hạn cho vai trò đặc quyền và truy cập liên tenant, để nhân sự nền tảng làm được việc ở tỉnh đích trong thời gian được duyệt; tỉnh đích biết và xem được lịch sử mọi lần truy cập. | M | 5 | MVP, W1 | FR-12-017; UC-12-13 |
| US-12-018 | Là quản trị tỉnh, tôi muốn rà soát quyền định kỳ, để quyền thừa được gỡ; có biên bản rà soát cho thanh tra. | S | 5 | Đợt 2, W4 | FR-12-018; UC-12-14 |
| US-12-019 | Là quản trị nền tảng, tôi muốn hệ thống chuyển định danh và vai trò khi sáp nhập tenant, để cán bộ đăng nhập được ở tỉnh đích với vai trò tương ứng; HTTT có thông tin xác thực mới song song. | S | 5 | Đợt 2, W4 | FR-12-019; UC-12-15 |

: Story của epic EP-12-B Vai trò, nhóm và quyền

#### EP-12-C · Xác thực người dùng

Epic gồm 10 story, 65 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-020 | Là người dùng, tôi muốn xác thực người dùng theo OIDC Authorization Code và PKCE, để người dùng vào ứng dụng với một lần đăng nhập; ứng dụng chỉ giữ cookie phiên. | M | 8 | MVP, W1 | FR-12-020; UC-12-16 |
| US-12-021 | Là quản trị tỉnh, tôi muốn hệ thống chống dò mật khẩu và khóa tài khoản, để dò mật khẩu bị chặn sau tối đa 5 lần mỗi tài khoản và 20 lần mỗi phút mỗi địa chỉ; cán bộ chính đáng tự mở sau 15 phút. | M | 8 | MVP, W1 | FR-12-021; UC-12-16 |
| US-12-022 | Là người dùng, tôi muốn đăng ký và dùng yếu tố thứ hai TOTP, WebAuthn, để 100% tài khoản trong nhóm `mfa-required` có yếu tố thứ hai đăng ký; báo cáo hằng ngày ở FR-12-060. | M | 8 | MVP, W1 | FR-12-022; UC-12-17 |
| US-12-023 | Là người dùng, tôi muốn xác thực lại bước lên cho thao tác nhạy cảm, để thao tác nhạy cảm luôn có xác thực mới trong 5 phút, không phụ thuộc phiên đăng nhập đã mở bao lâu. | M | 5 | MVP, W1 | FR-12-023; UC-12-17 |
| US-12-024 | Là quản trị tỉnh, tôi muốn đặt lại yếu tố thứ hai khi mất thiết bị, để người dùng bị mất thiết bị đăng ký lại được yếu tố mới sau khi danh tính được xác minh; mọi phiên cũ đã bị cắt. | M | 5 | MVP, W1 | FR-12-024; UC-12-18 |
| US-12-025 | Là quản trị tỉnh, tôi muốn đăng nhập một lần bằng SAML 2 cho ứng dụng cũ, để người dùng đăng nhập một lần vào cả ứng dụng OIDC lẫn ứng dụng SAML. | M | 8 | MVP, W1 | FR-12-025; UC-12-19 |
| US-12-026 | Là quản trị tỉnh, tôi muốn liên kết LDAP, Active Directory của tỉnh, để cán bộ đăng nhập bằng tài khoản danh bạ của tỉnh; tài khoản theo danh bạ khi nghỉ việc. | M | 8 | MVP, W1 | FR-12-026; UC-12-19 |
| US-12-027 | Là quản trị nền tảng, tôi muốn đăng nhập liên tenant cho người dùng thuộc nhiều tenant, để nhân sự nền tảng vào tỉnh đích đúng thời hạn và đúng vai trò; tỉnh nào cũng biết người vào. | M | 5 | MVP, W1 | FR-12-027; UC-12-13 |
| US-12-028 | Là quản trị tỉnh, tôi muốn liên kết đăng nhập VNeID, để cán bộ đã liên kết đăng nhập nhanh bằng VNeID; không ai có tài khoản chỉ vì có định danh quốc gia. | C | 5 | Đợt 2, W4 | FR-12-028; UC-12-19 |
| US-12-029 | Là quản trị tỉnh, tôi muốn quản lý phiên: xem, buộc đăng xuất, hạn mức phiên, để phiên bị buộc đăng xuất nhận `401` ở lời gọi kế tiếp; mọi người dùng có tối đa 3 phiên (quản trị 1) và không phiên nào quá 10 giờ. | M | 5 | MVP, W1 | FR-12-029; UC-12-20 |

: Story của epic EP-12-C Xác thực người dùng

#### EP-12-D · Danh tính HTTT và token

Epic gồm 11 story, 65 điểm (10 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-030 | Là quản trị tỉnh, tôi muốn hệ thống cấp client OAuth cho HTTT thành viên, để HTTT có danh tính truy cập đúng phạm vi; đầu mối nhận bí mật một lần ở PH-01, hoặc đăng ký chứng thư ở FR-12-033. | M | 8 | MVP, W1 | FR-12-030; UC-12-21 |
| US-12-031 | Là quản trị tỉnh, tôi muốn quản lý vòng đời client: sửa, tạm ngừng, tiếp tục, thu hồi, để HTTT bị tạm ngừng hay thu hồi không lấy được token mới và token cũ bị chặn trong 60 giây. | M | 5 | MVP, W1 | FR-12-031; UC-12-23 |
| US-12-032 | Là nhà phát triển, tôi muốn hệ thống cấp client cho ứng dụng nhà phát triển ở sandbox, để nhà phát triển lấy được token sandbox, không dùng được cho API thật. | S | 5 | Đợt 2, W4 | FR-12-032; UC-12-21 |
| US-12-033 | Là quản trị tỉnh, tôi muốn đăng ký chứng thư mTLS và khóa công khai của client, để HTTT xác thực không cần bí mật; chứng thư sắp hết hạn được nhắc trước 30 ngày. | M | 5 | MVP, W1 | FR-12-033; UC-12-24 |
| US-12-034 | Là quản trị tỉnh, tôi muốn xoay bí mật client, để bí mật mới có hiệu lực ngay; bí mật cũ chết sau 24 giờ hoặc ngay khi xoay khẩn. | M | 5 | MVP, W1 | FR-12-034; UC-12-24 |
| US-12-035 | Là HTTT khai thác, tôi muốn phát token cho HTTT bằng client_credentials, để HTTT gọi API được trong 5 phút với đúng phạm vi. | M | 8 | MVP, W1 | FR-12-035; UC-12-25 |
| US-12-036 | Là quản trị tỉnh, tôi muốn hệ thống sinh scope của client từ dữ liệu đã duyệt, để quyền của máy luôn khớp dữ liệu đã duyệt; TA, SO thấy scope kèm đường liên kết tới phân hệ nguồn. | M | 3 | MVP, W1 | FR-12-036; UC-12-22 |
| US-12-037 | Là quản trị nền tảng, tôi muốn tài khoản dịch vụ nội bộ của đơn vị triển khai, để mỗi DU có đúng tài khoản và scope cần thiết, xoay khóa tự động. | M | 8 | MVP, W1 | FR-12-037; UC-12-26 |
| US-12-038 | Là quản trị tỉnh, tôi muốn có vòng đời token: làm mới xoay vòng, phát hiện dùng lại, để người dùng làm việc liền mạch trong phiên; kẻ cắp refresh token bị phát hiện ngay lần dùng đầu tiên sau nạn nhân. | M | 5 | MVP, W1 | FR-12-038; UC-12-16 |
| US-12-039 | Là quản trị nền tảng, tôi muốn hệ thống công bố JWKS và xoay khóa ký 90 ngày, để xác minh token luôn thành công với khóa hiện hành và khóa vừa xoay; khóa không bị giữ quá 90 ngày. | M | 5 | MVP, W1 | FR-12-039; UC-12-27 |
| US-12-040 | Là quản trị tỉnh, tôi muốn thu hồi truy cập tức thời và phân phối danh sách chặn, để đối tượng bị thu hồi nhận `401` ở mọi cổng trong ≤ 60 giây. | M | 8 | MVP, W1 | FR-12-040; UC-12-28 |

: Story của epic EP-12-D Danh tính HTTT và token

#### EP-12-E · Realm theo tenant

Epic gồm 3 story, 18 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-041 | Là quản trị tỉnh, tôi muốn hệ thống khởi tạo realm của tenant từ mẫu, để tỉnh có realm đăng nhập được; quản trị tỉnh đầu tiên nhận thư kích hoạt. | M | 8 | MVP, W1 | FR-12-041; UC-12-29 |
| US-12-042 | Là quản trị nền tảng, tôi muốn có cấu hình bảo mật realm bằng GitOps, phát hiện lệch, để 0 khác biệt giữa realm thực tế và Git, kiểm tra hằng giờ (SEC-20); lệch được phát hiện trong tối đa 1 giờ. | M | 5 | MVP, W1 | FR-12-042; UC-12-29 |
| US-12-043 | Là quản trị nền tảng, tôi muốn hệ thống tạm ngừng, khôi phục, chuyển chỉ-đọc realm theo vòng đời tenant, để trong 60 giây sau khi tạm ngừng, không người dùng thường nào của tỉnh dùng được token; quản trị tỉnh vào được ở chế độ chỉ-đọc. | M | 5 | MVP, W1 | FR-12-043; UC-12-30 |

: Story của epic EP-12-E Realm theo tenant

#### EP-12-F · Ủy quyền

Epic gồm 12 story, 47 điểm (10 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-044 | Là quản trị tỉnh, tôi muốn quyết định ủy quyền theo hợp đồng PEP và PDP, để mọi thành phần của Datahub quyết định quyền theo một hợp đồng; hết thời gian chờ không bao giờ mở cửa. | M | 5 | MVP, W1 | FR-12-044; UC-12-31 |
| US-12-045 | Là quản trị nền tảng, tôi muốn có quy tắc gốc: từ chối mặc định, từ chối thắng, cách ly tenant, để không thể có luật cho phép nào ghi đè luật từ chối; không có chính sách nghĩa là không được phép. | M | 2 | MVP, W1 | FR-12-045; UC-12-31 |
| US-12-046 | Là quản trị nền tảng, tôi muốn phân quyền ba lớp: vai trò, phạm vi tổ chức, thuộc tính dữ liệu, để ví dụ: một cán bộ sở A có vai trò chủ dịch vụ chỉ thấy và sửa API của sở A; vai trò phê duyệt không áp dụng cho đối tượng do chính họ gửi. | M | 3 | MVP, W1 | FR-12-046; UC-12-31 |
| US-12-047 | Là quản trị tỉnh, tôi muốn tính mặt nạ trường và chế độ bảo vệ theo mục đích, để ví dụ tra cứu công dân theo bảng ở FR gốc: ba bên gọi nhận ba mức chi tiết khác nhau cho cùng một API. | M | 3 | MVP, W1 | FR-12-047; UC-12-31 |
| US-12-048 | Là quản trị tỉnh, tôi muốn có bộ chuyển đổi XACML 3.0, để bên tích hợp theo chuẩn XACML nhận quyết định đúng chuẩn; hội đồng nghiệm thu kiểm chứng được bằng bộ yêu cầu mẫu. | M | 3 | MVP, W1 | FR-12-048; UC-12-32 |
| US-12-049 | Là quản trị tỉnh, tôi muốn hệ thống quyết định theo lô, để một lời gọi trả quyết định cho tối đa 100 đối tượng. | S | 3 | MVP, W1 | FR-12-049; UC-12-32 |
| US-12-050 | Là quản trị tỉnh, tôi muốn có bộ đệm quyết định, để tỷ lệ trúng đệm từ 60% sau một giờ vận hành (NFR-12-009), không phát sinh quyết định lỗi thời. | S | 2 | MVP, W1 | FR-12-050; UC-12-32 |
| US-12-051 | Là quản trị nền tảng, tôi muốn hệ thống sinh dữ liệu vai trò–quyền cho OPA từ ma trận D02-08, để quyền hiệu lực của người dùng và scope của client khớp dữ liệu gốc trong tối đa 60 giây; ma trận và OPA không lệch nhau. | M | 5 | MVP, W1 | FR-12-051; UC-12-33 |
| US-12-052 | Là quản trị nền tảng, tôi muốn soạn và kiểm thử chính sách, để phiên bản nháp đạt kiểm tra cú pháp, kiểm thử và độ phủ, sẵn sàng chạy khô. | M | 5 | MVP, W1 | FR-12-052; UC-12-34 |
| US-12-053 | Là quản trị nền tảng, tôi muốn chạy khô chính sách trên lưu lượng thật, để người soạn và người duyệt thấy con số cụ thể ví dụ "sẽ chặn thêm 1.240 yêu cầu vốn đang được phép, chủ yếu từ HTTT HT-QLVB". | M | 3 | MVP, W1 | FR-12-053; UC-12-34 |
| US-12-054 | Là cán bộ ATTT, tôi muốn duyệt bốn mắt và phát hành gói chính sách ký, để chính sách có hiệu lực ở mọi OPA trong không quá 60 giây kể từ khi duyệt; có bản ghi ai soạn, ai duyệt, tác động thế nào. | M | 8 | MVP, W1 | FR-12-054; UC-12-35 |
| US-12-055 | Là cán bộ ATTT, tôi muốn thu hồi và quay lui chính sách, để chính sách gây hại bị gỡ khỏi mọi OPA trong 60 giây; tình trạng trước đó được khôi phục. | M | 5 | MVP, W1 | FR-12-055; UC-12-36 |

: Story của epic EP-12-F Ủy quyền

#### EP-12-G · Ghi vết và giám sát

Epic gồm 5 story, 17 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-056 | Là cán bộ ATTT, tôi muốn hệ thống ghi vết sự kiện xác thực và quản trị định danh, để mọi đăng nhập, thu hồi, thay đổi quyền truy vết được tới người, thời điểm, địa chỉ nguồn. | M | 5 | MVP, W1 | FR-12-056; UC-12-37 |
| US-12-057 | Là cán bộ ATTT, tôi muốn ghi vết quyết định ủy quyền, để có bản ghi cho 100% quyết định từ chối và Nhạy cảm; đối chiếu số bản ghi với số giao dịch khớp. | M | 3 | MVP, W1 | FR-12-057; UC-12-37 |
| US-12-058 | Là cán bộ ATTT, tôi muốn tra cứu nhật ký quyết định, để người điều tra tìm được quyết định theo `traceId` trong vài giây và thấy vì sao một yêu cầu bị từ chối. | M | 3 | MVP, W1 | FR-12-058; UC-12-38 |
| US-12-059 | Là cán bộ ATTT, tôi muốn hệ thống phát hiện hành vi bất thường và cảnh báo, để SO nhận cảnh báo trong 60 giây kể từ khi quy tắc vượt ngưỡng. | S | 3 | MVP, W1 | FR-12-059; UC-12-39 |
| US-12-060 | Là cán bộ ATTT, tôi muốn có báo cáo tình trạng tài khoản và xác thực hai yếu tố, để cán bộ ATTT thấy độ phủ MFA hằng ngày và danh sách việc cần xử lý. | S | 3 | MVP, W1 | FR-12-060; UC-12-40 |

: Story của epic EP-12-G Ghi vết và giám sát

#### EP-12-H · Quản trị

Epic gồm 2 story, 8 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-12-061 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để tham số có hiệu lực theo thời hạn nêu và luôn nằm trong ngưỡng an toàn. | M | 5 | MVP, W1 | FR-12-061; UC-12-41 |
| US-12-062 | Là quản trị tỉnh, tôi muốn hệ thống tra cứu danh bạ người dùng cho phân hệ khác, để các màn hình của Datahub hiển thị tên người nhất quán và chỉ lấy dữ liệu tối thiểu. | M | 3 | MVP, W1 | FR-12-062; UC-12-42 |

: Story của epic EP-12-H Quản trị

### 6.14. PH-13 · Giám sát và kiểm toán

Phân hệ có 8 epic, 61 story, tổng 216 điểm; wave phát triển W1–W2, đợt MVP. Nguồn: D02-03-PH13 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-13-A · Thu thập dữ liệu quan sát

Epic gồm 9 story, 25 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-001 | Là vận hành tỉnh, tôi muốn hệ thống thu thập chỉ số từ mọi thành phần, để người vận hành thấy số liệu mới nhất của mọi thành phần trên bảng điều khiển trong vòng 30 giây kể từ khi thành phần phát. | M | 5 | MVP, W1–W2 | FR-13-001; UC-13-01 |
| US-13-002 | Là vận hành tỉnh, tôi muốn hệ thống thu thập log có cấu trúc, để một yêu cầu qua nhiều thành phần có thể tra toàn bộ log bằng một `trace_id`. | M | 3 | MVP, W1–W2 | FR-13-002; UC-13-01 |
| US-13-003 | Là vận hành tỉnh, tôi muốn hệ thống thu thập vết truy nguyên, để mỗi yêu cầu đi qua nền tảng có hành trình tra được bằng `trace_id` trong 14 ngày (trace được giữ). | M | 3 | MVP, W1–W2 | FR-13-003; UC-13-01 |
| US-13-004 | Là quản trị nền tảng, tôi muốn hệ thống lấy mẫu trace theo đuôi, để 100% trace lỗi, chậm bất thường hoặc chạm dữ liệu Nhạy cảm tra được; khoảng 10% trace thành công còn lại. | M | 2 | MVP, W1–W2 | FR-13-004; UC-13-01 |
| US-13-005 | Là cán bộ ATTT, tôi muốn hệ thống che dữ liệu Nhạy cảm và quét phát hiện lọt, để cán bộ ATTT có bằng chứng hằng ngày rằng không có giá trị Nhạy cảm trong log. | M | 2 | MVP, W1–W2 | FR-13-005; UC-13-02 |
| US-13-006 | Là vận hành tỉnh, tôi muốn hệ thống thu siêu dữ liệu lượt gọi API, để mọi lượt gọi API có một dòng siêu dữ liệu tra được trong 12 tháng. | M | 2 | MVP, W1–W2 | FR-13-006; UC-13-03 |
| US-13-007 | Là vận hành tỉnh, tôi muốn hệ thống thu chỉ số thành phần nền và hạ tầng, để người vận hành thấy CPU, bộ nhớ, đĩa, mạng của từng pod và nút; thấy broker Kafka, phân vùng thiếu bản sao, độ trễ nhân bản PostgreSQL. | M | 3 | MVP, W1–W2 | FR-13-007; UC-13-03 |
| US-13-008 | Là quản trị tỉnh, tôi muốn hệ thống kiểm tra tổng hợp mỗi phút, để người vận hành biết API quan trọng đang sống hay chết trong chưa đầy 3 phút kể từ khi lỗi. | M | 3 | MVP, W1–W2 | FR-13-008; UC-13-04 |
| US-13-009 | Là quản trị nền tảng, tôi muốn hệ thống cách ly dữ liệu quan sát theo tenant, để 0 truy vấn chéo tenant thành công (NFR-13-022). | M | 2 | MVP, W1–W2 | FR-13-009; UC-13-01 |

: Story của epic EP-13-A Thu thập dữ liệu quan sát

#### EP-13-B · Ghi vết kiểm toán

Epic gồm 10 story, 41 điểm (10 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-010 | Là kiểm toán viên, tôi muốn hệ thống tiếp nhận và xác thực bản ghi kiểm toán, để mọi bản ghi gửi tới đều được lưu ở bảng chuỗi hoặc kho cách ly; không bản ghi nào biến mất. | M | 5 | MVP, W1–W2 | FR-13-010; UC-13-05 |
| US-13-011 | Là vận hành tỉnh, tôi muốn hệ thống ghi chỉ-thêm và nối chuỗi băm theo tenant, để bản ghi nằm trong chuỗi của tenant, số thứ tự liên tục, không sửa được mà không đứt chuỗi. | M | 3 | MVP, W1–W2 | FR-13-011; UC-13-05 |
| US-13-012 | Là cán bộ ATTT, tôi muốn hệ thống neo băm ký hằng giờ, để kiểm toán viên có mốc chữ ký theo giờ để chứng minh chuỗi đến mốc đó chưa bị sửa. | M | 5 | MVP, W1–W2 | FR-13-012; UC-13-06 |
| US-13-013 | Là vận hành tỉnh, tôi muốn hệ thống sao lô sang kho WORM, để bản ghi nào cũng có bản trên WORM trong vòng 10 phút kể từ khi được ghi. | M | 3 | MVP, W1–W2 | FR-13-013; UC-13-06 |
| US-13-014 | Là cán bộ ATTT, tôi muốn hệ thống kiểm tra toàn vẹn chuỗi, để kiểm toán viên và cán bộ ATTT thấy kết quả "Đạt" hoặc vị trí đứt chuỗi đầu tiên, và tối đa sau 24 giờ biết nếu có ai sửa bản ghi. | M | 5 | MVP, W1–W2 | FR-13-014; UC-13-07 |
| US-13-015 | Là cán bộ ATTT, tôi muốn hệ thống xử lý đứt chuỗi và neo không khớp, để cán bộ ATTT biết trong vài phút khoảng nhật ký nào không còn đáng tin và có sẵn chứng cứ để điều tra. | M | 5 | MVP, W1–W2 | FR-13-015; UC-13-08 |
| US-13-016 | Là vận hành nền tảng, tôi muốn hệ thống chịu lỗi và đệm bản ghi khi PH-13 hoặc kho ngừng, để người dùng không thấy gián đoạn; người vận hành thấy backlog và biết khi nào hết. | M | 3 | MVP, W1–W2 | FR-13-016; UC-13-09 |
| US-13-017 | Là cán bộ ATTT, tôi muốn hệ thống đối chiếu số bản ghi với bộ đếm của DU, để báo cáo đối chiếu hằng ngày chứng minh độ phủ kiểm toán 100%. | M | 5 | MVP, W1–W2 | FR-13-017; UC-13-09 |
| US-13-018 | Là quản trị nền tảng, tôi muốn hệ thống có vòng đời lưu giữ và lưu trữ phân vùng, để bản ghi trong 12 tháng tra ngay; bản cũ hơn vẫn có trên WORM và xuất được thành bằng chứng. | M | 5 | MVP, W1–W2 | FR-13-018; UC-13-10 |
| US-13-019 | Là vận hành tỉnh, tôi muốn hệ thống kiểm toán chính thao tác của PH-13, để mọi thao tác nhạy cảm ở PH-13 truy được tới người thực hiện, lý do, thời điểm. | M | 2 | MVP, W1–W2 | FR-13-019; UC-13-11 |

: Story của epic EP-13-B Ghi vết kiểm toán

#### EP-13-C · Tra cứu kiểm toán và bằng chứng

Epic gồm 6 story, 23 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-020 | Là cán bộ ATTT, tôi muốn tra cứu nhật ký kiểm toán, để người tra cứu có danh sách bản ghi đã che và biết chuỗi đã được xác minh tới lúc nào. | M | 3 | MVP, W1–W2 | FR-13-020; UC-13-12 |
| US-13-021 | Là cán bộ ATTT, tôi muốn xem chi tiết bản ghi và xác minh băm, để người điều tra thấy một bản ghi đầy đủ kèm bằng chứng nó chưa bị sửa tới thời điểm neo. | M | 3 | MVP, W1–W2 | FR-13-021; UC-13-12 |
| US-13-022 | Là người dùng, tôi muốn có lịch sử theo đối tượng cho tab "Lịch sử", để mỗi màn chi tiết đối tượng có tab "Lịch sử" hiển thị đúng nhật ký của đối tượng đó. | M | 3 | MVP, W1–W2 | FR-13-022; UC-13-13 |
| US-13-023 | Là cán bộ ATTT, tôi muốn tra theo đối tượng bị tra cứu, để người điều tra biết ai đã tra cứu một đối tượng mà không làm lộ danh sách đối tượng bị tra cứu. | S | 3 | MVP, W1–W2 | FR-13-023; UC-13-14 |
| US-13-024 | Là cán bộ ATTT, tôi muốn xuất bằng chứng kiểm toán ký số, để kiểm toán viên có một gói tự xác minh được, ký số, kèm bằng chứng chuỗi. | M | 8 | MVP, W1–W2 | FR-13-024; UC-13-15 |
| US-13-025 | Là quản trị tỉnh, tôi muốn có báo cáo truy cập liên tenant, để quản trị tỉnh biết chính xác ai của nền tảng đã vào tenant và vì sao. | S | 3 | MVP, W1–W2 | FR-13-025; UC-13-16 |

: Story của epic EP-13-C Tra cứu kiểm toán và bằng chứng

#### EP-13-D · Tra log, truy vết và liên kết

Epic gồm 5 story, 17 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-026 | Là vận hành tỉnh, tôi muốn tra log tập trung, để người dùng tìm được log cần xem trong vài giây, trên một giao diện. | M | 3 | MVP, W1–W2 | FR-13-026; UC-13-17 |
| US-13-027 | Là vận hành tỉnh, tôi muốn chi tiết dòng log, ngữ cảnh và theo dõi trực tiếp, để người dùng đọc được bối cảnh xung quanh một lỗi mà không phải mở thêm công cụ. | S | 3 | MVP, W1–W2 | FR-13-027; UC-13-17 |
| US-13-028 | Là vận hành tỉnh, tôi muốn tìm trace và biểu đồ thác nước, để người chẩn đoán biết điểm nghẽn mà không phải đoán. | M | 5 | MVP, W1–W2 | FR-13-028; UC-13-18 |
| US-13-029 | Là kiểm toán viên, tôi muốn liên kết chỉ số, trace, log, kiểm toán bằng trace_id, để một yêu cầu có đủ ngữ cảnh ở một màn hình, đúng quyền của người xem. | M | 3 | MVP, W1–W2 | FR-13-029; UC-13-18 |
| US-13-030 | Là vận hành tỉnh, tôi muốn tra nhật ký truy cập API, để người vận hành xem được ai gọi gì, lúc nào, kết quả ra sao, trong vài giây kể cả với 5 triệu lượt mỗi ngày. | M | 3 | MVP, W1–W2 | FR-13-030; UC-13-19 |

: Story của epic EP-13-D Tra log, truy vết và liên kết

#### EP-13-E · Bảng điều khiển

Epic gồm 11 story, 33 điểm (10 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-031 | Là quản trị nền tảng, tôi muốn có bảng điều khiển tổng quan nền tảng, để người vận hành biết trong vài giây nền tảng khỏe hay không và đi tiếp tới đâu để xem chi tiết. | M | 3 | MVP, W1–W2 | FR-13-031; UC-13-20 |
| US-13-032 | Là vận hành tỉnh, tôi muốn có bảng điều khiển đơn vị triển khai và tài nguyên, để người vận hành thấy ngay đơn vị nào đang có vấn đề và tài nguyên của nó. | M | 3 | MVP, W1–W2 | FR-13-032; UC-13-21 |
| US-13-033 | Là vận hành tỉnh, tôi muốn có bảng điều khiển theo luồng và route, để người dùng thấy luồng nào đang chậm hoặc lỗi và route nào gây ra. | M | 3 | MVP, W1–W2 | FR-13-033; UC-13-21 |
| US-13-034 | Là vận hành tỉnh, tôi muốn thống kê theo endpoint, để người vận hành thấy endpoint nào hay lỗi và API nào dùng nhiều. | M | 3 | MVP, W1–W2 | FR-13-034; UC-13-21 |
| US-13-035 | Là chủ dịch vụ, tôi muốn có bảng điều khiển theo API và theo HTTT, để người quản lý biết API nào, HTTT nào dùng nhiều, lỗi nhiều, sắp hết hạn mức. | M | 3 | MVP, W1–W2 | FR-13-035; UC-13-22 |
| US-13-036 | Là quản trị nền tảng, tôi muốn có danh sách và chi tiết nút gateway, để người vận hành thấy nút nào đã lệch cấu hình và lệch từ lúc nào. | M | 3 | MVP, W1–W2 | FR-13-036; UC-13-23 |
| US-13-037 | Là vận hành tỉnh, tôi muốn giám sát tài nguyên nút gateway, để người vận hành biết nút nào sắp quá tải. | M | 3 | MVP, W1–W2 | FR-13-037; UC-13-23 |
| US-13-038 | Là quản trị nền tảng, tôi muốn có bảng điều khiển cụm Kafka, để người vận hành thấy cụm Kafka có đang thiếu bản sao hoặc quá tải không. | M | 3 | MVP, W1–W2 | FR-13-038; UC-13-23 |
| US-13-039 | Là người xem, tôi muốn có bảng điều khiển hoạt động nghiệp vụ, để lãnh đạo có số liệu thực để quyết định, không cần xem chỉ số kỹ thuật. | M | 3 | MVP, W1–W2 | FR-13-039; UC-13-24 |
| US-13-040 | Là cán bộ ATTT, tôi muốn có bảng điều khiển an ninh, để cán bộ ATTT thấy bất thường ngay trong màn hình đầu tiên mở ra mỗi ngày. | M | 3 | MVP, W1–W2 | FR-13-040; UC-13-24 |
| US-13-041 | Là quản trị nền tảng, tôi muốn quản lý bộ dashboard theo tenant, để mỗi tenant có bộ dashboard chuẩn nhất quán, tách khỏi tenant khác. | S | 3 | MVP, W1–W2 | FR-13-041; UC-13-25 |

: Story của epic EP-13-E Bảng điều khiển

#### EP-13-F · Cảnh báo

Epic gồm 9 story, 40 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-042 | Là quản trị nền tảng, tôi muốn quản lý luật cảnh báo kèm runbook, chạy thử, để luật hoạt động trong vòng 1 phút, có runbook, và người tạo biết nó sẽ phát bao nhiêu lần trước khi bật. | M | 8 | MVP, W1–W2 | FR-13-042; UC-13-26 |
| US-13-043 | Là quản trị nền tảng, tôi muốn có bộ luật cảnh báo chuẩn của nền tảng, để mọi tenant có cùng bộ luật chuẩn đã kiểm chứng, mỗi luật có runbook. | M | 5 | MVP, W1–W2 | FR-13-043; UC-13-27 |
| US-13-044 | Là vận hành tỉnh, tôi muốn hệ thống đánh giá luật, chống nhấp nháy, sinh cảnh báo, để người trực chỉ nhận cảnh báo khi điều kiện đã duy trì đủ lâu, và cảnh báo tự đóng khi hết. | M | 5 | MVP, W1–W2 | FR-13-044; UC-13-28 |
| US-13-045 | Là vận hành tỉnh, tôi muốn hệ thống phân mức, gom nhóm, chống lặp, để người trực nhận một thông báo cho một nguyên nhân thay vì hàng chục thông báo. | M | 3 | MVP, W1–W2 | FR-13-045; UC-13-28 |
| US-13-046 | Là vận hành tỉnh, tôi muốn hệ thống gửi thông báo theo lịch trực và leo thang, để cảnh báo Nghiêm trọng tới người trực trong 60 giây (p95) và leo thang nếu không ai nhận trong 15 phút. | M | 5 | MVP, W1–W2 | FR-13-046; UC-13-28 |
| US-13-047 | Là quản trị nền tảng, tôi muốn xử lý cảnh báo: xác nhận, đã xử lý, tạm ẩn, để cảnh báo có người nhận, có ghi nguyên nhân và hành động khi đóng, tạm ẩn có kiểm soát. | M | 5 | MVP, W1–W2 | FR-13-047; UC-13-29 |
| US-13-048 | Là quản trị nền tảng, tôi muốn quản lý lịch trực, nhóm nhận, kênh thông báo, để mọi cảnh báo luôn có người nhận và đường gửi dự phòng. | M | 3 | MVP, W1–W2 | FR-13-048; UC-13-30 |
| US-13-049 | Là quản trị nền tảng, tôi muốn hệ thống giám sát chính hệ thống giám sát, để người vận hành biết hệ thống giám sát còn tin được hay không; không có "im lặng giả". | M | 3 | MVP, W1–W2 | FR-13-049; UC-13-31 |
| US-13-050 | Là vận hành tỉnh, tôi muốn thống kê hiệu quả cảnh báo, để vận hành có số liệu để chỉnh luật giảm nhiễu. | S | 3 | MVP, W1–W2 | FR-13-050; UC-13-32 |

: Story của epic EP-13-F Cảnh báo

#### EP-13-G · Phát hiện bất thường an ninh

Epic gồm 5 story, 19 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-051 | Là cán bộ ATTT, tôi muốn nạp và tinh chỉnh bộ luật phát hiện UC-SEC, để bộ luật đầy đủ chạy từ ngày đầu; cán bộ ATTT giảm nhiễu mà không mất độ che phủ. | M | 5 | MVP, W1–W2 | FR-13-051; UC-13-33 |
| US-13-052 | Là cán bộ ATTT, tôi muốn hệ thống phát hiện bất thường từ bản ghi kiểm toán, để hành vi bất thường trong nhật ký kiểm toán được báo trong vòng 5 phút. | M | 3 | MVP, W1–W2 | FR-13-052; UC-13-34 |
| US-13-053 | Là cán bộ ATTT, tôi muốn xử lý cảnh báo an ninh, đề xuất tạm ngừng HTTT, để mỗi cảnh báo an ninh có người nhận, kết luận và hồ sơ; đề xuất tạm ngừng đến đúng nơi quyết định. | M | 5 | MVP, W1–W2 | FR-13-053; UC-13-35 |
| US-13-054 | Là quản trị nền tảng, tôi muốn đẩy log và cảnh báo an ninh sang SIEM, SOC, để SIEM của tỉnh nhận được log an ninh chuẩn hóa, không có dữ liệu cá nhân; tỉnh chưa có SIEM vẫn có bảng và luật. | M | 3 | MVP, W1–W2 | FR-13-054; UC-13-36 |
| US-13-055 | Là cán bộ ATTT, tôi muốn có mẫu báo cáo sự cố và thông báo vi phạm DLCN, để báo cáo soạn sẵn, đúng mẫu, có nhắc hạn. | C | 3 | Đợt sau, Sau G5 | FR-13-055; UC-13-37 |

: Story của epic EP-13-G Phát hiện bất thường an ninh

#### EP-13-H · Cung cấp dữ liệu cho phân hệ khác và vòng đời theo tenant

Epic gồm 6 story, 18 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-13-056 | Là vận hành tỉnh, tôi muốn hệ thống cung cấp số liệu cho PH-16, để PH-16 có số liệu nhất quán để tính chỉ tiêu. | M | 3 | MVP, W1–W2 | FR-13-056; UC-13-38 |
| US-13-057 | Là vận hành tỉnh, tôi muốn hệ thống cung cấp ngữ cảnh chẩn đoán cho PH-18, để người xử lý DLQ có sẵn ngữ cảnh để quyết định xử lý lại hay bỏ. | M | 3 | MVP, W1–W2 | FR-13-057; UC-13-39 |
| US-13-058 | Là vận hành tỉnh, tôi muốn cung cấp sức khỏe thành phần cho phân hệ khác, để các phân hệ có cùng một sự thật về sức khỏe thành phần. | S | 3 | MVP, W1–W2 | FR-13-058; UC-13-39 |
| US-13-059 | Là vận hành tỉnh, tôi muốn hệ thống khởi tạo quan sát và chuỗi kiểm toán cho tenant mới, để tenant có quan sát và chuỗi kiểm toán hoạt động ngay, bản ghi kiểm toán đầu tiên của tenant đi vào chuỗi mới. | M | 3 | MVP, W1–W2 | FR-13-059; UC-13-40 |
| US-13-060 | Là quản trị nền tảng, tôi muốn hệ thống đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập, để chứng cứ của tenant được giữ nguyên vẹn, tra cứu được. | S | 3 | Đợt sau, Sau G5 | FR-13-060; UC-13-41 |
| US-13-061 | Là quản trị nền tảng, tôi muốn có tham số và hạn mức quan sát theo tenant, để tenant điều chỉnh vận hành theo thực tế trong biên an toàn. | S | 3 | MVP, W1–W2 | FR-13-061; UC-13-42 |

: Story của epic EP-13-H Cung cấp dữ liệu cho phân hệ khác và vòng đời theo tenant

### 6.15. PH-14 · Kết nối quốc gia

Phân hệ có 9 epic, 57 story, tổng 245 điểm; wave phát triển W2, đợt MVP. Nguồn: D02-03-PH14 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-14-A · Nền tảng và danh mục dịch vụ quốc gia

Epic gồm 9 story, 35 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-001 | Là quản trị nền tảng, tôi muốn liệt kê nền tảng quốc gia, trạng thái và mức sức khỏe, để danh sách nền tảng có thẻ tổng; nền tảng hỏng nằm đầu; nền tảng đang dùng đặc tả tạm có nhãn "đặc tả tạm thời". | M | 3 | MVP, W2 | FR-14-001; UC-14-01 |
| US-14-002 | Là quản trị tỉnh, tôi muốn khai báo nền tảng quốc gia và gắn kết nối PH-05, để nền tảng được tạo ở `DRAFT` và người dùng được dẫn tới bước kiểm tra kết nối; không bí mật nào đi qua PH-14. | M | 5 | MVP, W2 | FR-14-002; UC-14-01 |
| US-14-003 | Là quản trị tỉnh, tôi muốn bật, tạm ngừng, tiếp tục và ngừng dùng nền tảng, để nền tảng được bật sau khi có người duyệt; tạm ngừng có hiệu lực trong 30 giây; mọi bước có người, lý do, thời điểm. | M | 5 | MVP, W2 | FR-14-003; UC-14-02, 14-03 |
| US-14-004 | Là người dùng có quyền xem, tôi muốn liệt kê và tìm dịch vụ quốc gia, để danh sách dịch vụ lọc được, dịch vụ cần xử lý nằm đầu. | M | 2 | MVP, W2 | FR-14-004; UC-14-04 |
| US-14-005 | Là kỹ sư tích hợp, tôi muốn khai báo và sửa dịch vụ quốc gia, để dịch vụ có đủ chính sách; khi chuyển `ACTIVE` cổng quốc gia nhận lưu lượng cho dịch vụ này. | M | 5 | MVP, W2 | FR-14-005; UC-14-04 |
| US-14-006 | Là người dùng có quyền xem, tôi muốn xem chi tiết dịch vụ, hợp đồng và nhãn đối chiếu, để người dùng thấy đủ thông tin để quyết định; dịch vụ mang nhãn `SPEC_CHANGED` hiển thị biểu ngữ vàng kèm nút "Nạp đặc tả mới". | M | 2 | MVP, W2 | FR-14-006; UC-14-04 |
| US-14-007 | Là kỹ sư tích hợp, tôi muốn đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP, để người dùng có danh sách dịch vụ cần xử lý và nhãn cập nhật; dịch vụ ngừng bị chặn gọi mới. | M | 5 | MVP, W2 | FR-14-007; UC-14-06, 14-15, 14-38 |
| US-14-008 | Là kỹ sư tích hợp, tôi muốn nạp đặc tả dịch vụ có phiên bản và phát hiện lệch, để đặc tả được lưu có phiên bản, thay đổi phá vỡ bị chặn tới khi duyệt, lệch với trung ương được phát hiện trong 24 giờ. | M | 5 | MVP, W2 | FR-14-008; UC-14-05, 14-38 |
| US-14-009 | Là kỹ sư tích hợp, tôi muốn cung cấp lại dịch vụ quốc gia cho HTTT của tỉnh, để HTTT của tỉnh thấy API quốc gia trong danh mục, đăng ký sử dụng như mọi API khác, và không bao giờ nhận thông tin xác thực quốc gia. | M | 3 | MVP, W2 | FR-14-009; UC-14-07 |

: Story của epic EP-14-A Nền tảng và danh mục dịch vụ quốc gia

#### EP-14-B · Gọi dịch vụ và định tuyến

Epic gồm 7 story, 34 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-010 | Là HTTT khai thác, tôi muốn gọi dịch vụ quốc gia qua điểm gọi chung, để bên gọi nhận dữ liệu quốc gia đã xác minh, biết dữ liệu lấy từ đệm hay gọi thật và cũ bao nhiêu để tự quyết định có chấp nhận hay yêu cầu dữ liệu tươi. | M | 8 | MVP, W2 | FR-14-010; UC-14-09, 14-11, 14-12, 14-13 … |
| US-14-011 | Là quản trị tỉnh, tôi muốn hệ thống kiểm tra mục đích khai thác và ủy quyền theo mục đích, để chỉ HTTT được quyền và nêu đúng mục đích mới tra được; mọi lượt, kể cả bị từ chối, có bản ghi để thanh tra. | M | 5 | MVP, W2 | FR-14-011; UC-14-09, 14-11, 14-12 |
| US-14-012 | Là kỹ sư tích hợp, tôi muốn hệ thống định tuyến tới nền tảng và dịch vụ đích, để lượt gọi đi đúng nền tảng theo bảng đã duyệt; mọi lần chuyển hướng dự phòng đều để lại dấu vết. | M | 5 | MVP, W2 | FR-14-012; UC-14-08, 14-09 |
| US-14-013 | Là quản trị tỉnh, tôi muốn quản lý bảng định tuyến, để bảng định tuyến được duyệt và áp dụng trong 30 giây; mọi thay đổi có người, căn cứ, thời điểm. | M | 5 | MVP, W2 | FR-14-013; UC-14-08 |
| US-14-014 | Là kỹ sư tích hợp, tôi muốn hệ thống chuyển đổi bản tin theo hợp đồng dịch vụ, để bên gọi chỉ thao tác với JSON; trung ương nhận bản tin đúng mẫu; trường ngoài hợp đồng không rò ra. | M | 3 | MVP, W2 | FR-14-014; UC-14-09, 14-11 |
| US-14-015 | Là kỹ sư tích hợp, tôi muốn hệ thống phân loại và chuẩn hóa lỗi từ quốc gia, để HTTT biết lỗi do dữ liệu của mình, do quốc gia hay do mạng, và có nên thử lại. | M | 3 | MVP, W2 | FR-14-015; UC-14-09, 14-25 |
| US-14-016 | Là HTTT khai thác, tôi muốn gọi bất đồng bộ qua hàng chờ, để HTTT không bị chặn; yêu cầu không mất khi quốc gia gián đoạn, được gửi một lần duy nhất. | M | 5 | MVP, W2 | FR-14-016; UC-14-10, 14-11 |

: Story của epic EP-14-B Gọi dịch vụ và định tuyến

#### EP-14-C · Bộ điều hợp theo nhóm dịch vụ

Epic gồm 7 story, 35 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-017 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp tư pháp: lý lịch tư pháp, để HTTT có đủ thao tác lý lịch tư pháp như hệ cũ, mỗi lượt có mục đích, nhật ký và không lộ thông tin xác thực. | M | 5 | MVP, W2 | FR-14-017; UC-14-11 |
| US-14-018 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp tư pháp: hộ tịch, để HTTT đăng ký và tra hồ sơ hộ tịch như hệ cũ, không có đăng ký trùng khi mạng chập chờn. | M | 5 | MVP, W2 | FR-14-018; UC-14-11 |
| US-14-019 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp bảo hiểm xã hội, để HTTT nhận đúng dữ liệu cần cho thủ tục, không thừa trường, mỗi lượt có nhật ký và mục đích. | M | 5 | MVP, W2 | FR-14-019; UC-14-12 |
| US-14-020 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp hồ sơ thủ tục cấp mã số ĐVQHNS, để HTTT đồng bộ được hồ sơ ĐVQHNS theo khoảng thời gian như hệ cũ mà không chiếm hạn mức của dịch vụ công. | M | 5 | MVP, W2 | FR-14-020; UC-14-13 |
| US-14-021 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp đăng ký doanh nghiệp, để HTTT nhận dữ liệu doanh nghiệp mới nhất, nhanh nhờ đệm, vẫn bảo đảm tươi khi cần. | M | 5 | MVP, W2 | FR-14-021; UC-14-14 |
| US-14-022 | Là kỹ sư tích hợp, tôi muốn có bộ điều hợp văn bản quy phạm pháp luật, để HTTT tra cứu văn bản pháp luật nhanh, hầu hết từ đệm, không tốn hạn mức. | M | 5 | MVP, W2 | FR-14-022; UC-14-14 |
| US-14-023 | Là quản trị nền tảng, tôi muốn hệ thống có cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07, để PH-07 đồng bộ danh mục quốc gia qua một cổng duy nhất, không giữ khóa quốc gia; lệch phiên bản được phát hiện sớm nhờ `remoteVersion`. | M | 5 | MVP, W2 | FR-14-023; UC-14-15 |

: Story của epic EP-14-C Bộ điều hợp theo nhóm dịch vụ

#### EP-14-D · Xác thực, chữ ký số và chứng thư

Epic gồm 8 story, 41 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-024 | Là quản trị tỉnh, tôi muốn hệ thống lấy và làm mới token OAuth 2.1 của nền tảng, để cổng luôn có token hợp lệ trước khi gọi; quản trị biết được thông tin xác thực còn đúng không mà không chạm bí mật. | M | 5 | MVP, W2 | FR-14-024; UC-14-16, 14-17 |
| US-14-025 | Là quản trị tỉnh, tôi muốn xoay vòng và cấp lại thông tin xác thực, để thông tin xác thực mới có hiệu lực không gián đoạn, khóa cũ chắc chắn được thu hồi, không còn khóa nào của hệ cũ sống sau cắt chuyển. | M | 5 | MVP, W2 | FR-14-025; UC-14-17, 14-37, 14-38 |
| US-14-026 | Là kỹ sư tích hợp, tôi muốn hệ thống ký số bản tin gửi đi, để 100% bản tin yêu cầu ký đều có chữ ký hợp lệ; kẻ chiếm pod không lấy được khóa. | M | 5 | MVP, W2 | FR-14-026; UC-14-09, 14-11, 14-18, 14-27 |
| US-14-027 | Là kỹ sư tích hợp, tôi muốn hệ thống xác minh chữ ký phản hồi, để 100% phản hồi yêu cầu xác minh được xác minh trước khi dùng; chữ ký sai không bao giờ lọt vào HTTT. | M | 5 | MVP, W2 | FR-14-027; UC-14-09, 14-11, 14-21, 14-27 |
| US-14-028 | Là cán bộ ATTT, tôi muốn nạp và kích hoạt chứng thư số, để chứng thư được dùng để ký sau khi qua hai người; khóa không rời OpenBao; chứng thư cũ vẫn xác minh được bản tin còn bay trong thời gian chuyển tiếp. | M | 8 | MVP, W2 | FR-14-028; UC-14-18 |
| US-14-029 | Là cán bộ ATTT, tôi muốn hệ thống theo dõi hạn chứng thư, cảnh báo và chuyển tiếp, để cán bộ ATTT và quản trị biết trước 60, 30, 7 ngày; quy trình gia hạn khởi động kịp, không để ngưng kết nối. | M | 5 | MVP, W2 | FR-14-029; UC-14-19 |
| US-14-030 | Là cán bộ ATTT, tôi muốn hệ thống cập nhật chuỗi tin cậy và danh sách thu hồi, để chuỗi tin cậy và danh sách thu hồi luôn mới; thay đổi neo có hai người. | M | 5 | MVP, W2 | FR-14-030; UC-14-20 |
| US-14-031 | Là cán bộ ATTT, tôi muốn hệ thống xử lý sự cố chữ ký như sự cố an ninh, để mọi chữ ký sai được xử lý như sự cố an ninh có hồ sơ, không bị lẫn trong lỗi kỹ thuật. | M | 3 | MVP, W2 | FR-14-031; UC-14-21 |

: Story của epic EP-14-D Xác thực, chữ ký số và chứng thư

#### EP-14-E · Hạn mức, đệm và chịu lỗi

Epic gồm 7 story, 25 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-032 | Là quản trị tỉnh, tôi muốn khai báo hạn mức do trung ương áp, để hạn mức được ghi có căn cứ và hiệu lực từ thời điểm xác định; cổng đếm đúng theo mức mới. | M | 5 | MVP, W2 | FR-14-032; UC-14-22 |
| US-14-033 | Là kỹ sư tích hợp, tôi muốn hệ thống đếm hạn mức, kiểm tra trước mỗi lượt gọi và cảnh báo ngưỡng, để tỉnh không chạm trần hạn mức mà không có cảnh báo từ trước; HTTT biết khi nào gọi lại được. | M | 3 | MVP, W2 | FR-14-033; UC-14-13, 14-23 |
| US-14-034 | Là quản trị tỉnh, tôi muốn phân bổ hạn mức theo HTTT và ưu tiên dịch vụ thiết yếu, để không một HTTT hay tác vụ nền nào làm ngưng dịch vụ công; việc bị hoãn có lý do rõ. | M | 5 | MVP, W2 | FR-14-034; UC-14-13, 14-22, 14-23 |
| US-14-035 | Là kỹ sư tích hợp, tôi muốn hệ thống đệm phản hồi theo loại dữ liệu, để với dịch vụ tra cứu được đệm, tỷ lệ trúng đệm tối thiểu 60% (NFR-14-005) nên tối đa 40% lượt tra cứu thực sự gọi ra quốc gia; bên gọi biết dữ liệu cũ bao nhiêu và tự quyết có cần dữ liệu tươi. | M | 3 | MVP, W2 | FR-14-035; UC-14-12, 14-14, 14-24 |
| US-14-036 | Là quản trị tỉnh, tôi muốn vô hiệu đệm, để lượt gọi tiếp theo lấy dữ liệu tươi từ quốc gia (và tốn hạn mức). | S | 3 | MVP, W2 | FR-14-036; UC-14-24, 14-28 |
| US-14-037 | Là kỹ sư tích hợp, tôi muốn hệ thống dùng dữ liệu đệm quá hạn có cờ, để dịch vụ công tiếp tục được trong lúc quốc gia sự cố, và không ai bị đánh lừa rằng dữ liệu còn tươi. | M | 3 | MVP, W2 | FR-14-037; UC-14-24 |
| US-14-038 | Là vận hành tỉnh, tôi muốn hệ thống ngắt mạch và thử lại, để một nền tảng lỗi không kéo chậm cả phân hệ; lỗi thoáng qua được hấp thụ mà không tốn hạn mức vô ích. | M | 3 | MVP, W2 | FR-14-038; UC-14-25 |

: Story của epic EP-14-E Hạn mức, đệm và chịu lỗi

#### EP-14-F · Chiều vào

Epic gồm 4 story, 21 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-039 | Là quản trị tỉnh, tôi muốn đăng ký điểm cuối chiều vào và nguồn được phép, để điểm cuối chỉ nhận từ nguồn đã đăng ký; địa chỉ để cung cấp cho trung ương hiển thị đủ; mọi thay đổi có hai người. | M | 5 | MVP, W2 | FR-14-039; UC-14-26 |
| US-14-040 | Là kỹ sư tích hợp, tôi muốn tiếp nhận yêu cầu từ nền tảng quốc gia, để chỉ bản tin hợp lệ từ nguồn đã đăng ký tới được lõi tích hợp; mọi lần từ chối đều có bản ghi để cán bộ ATTT xem. | M | 8 | MVP, W2 | FR-14-040; UC-14-27 |
| US-14-041 | Là kỹ sư tích hợp, tôi muốn hệ thống chuyển cho luồng PH-04 và trả phản hồi có ký, để nền tảng quốc gia nhận phản hồi đã ký của tỉnh; luồng PH-04 không phải biết gì về mTLS hay chữ ký. | M | 5 | MVP, W2 | FR-14-041; UC-14-27 |
| US-14-042 | Là kỹ sư tích hợp, tôi muốn tiếp nhận thông báo thay đổi từ quốc gia, để đệm không phục vụ dữ liệu đã đổi; PH-07 đồng bộ sớm; kỹ sư biết dịch vụ đổi đặc tả ngay. | S | 3 | Đợt 2, W4 | FR-14-042; UC-14-15, 14-28 |

: Story của epic EP-14-F Chiều vào

#### EP-14-G · Đồng bộ

Epic gồm 4 story, 18 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-043 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ danh mục dịch vụ lên Bộ, để mọi dịch vụ chia sẻ đã phát hành được đăng ký lên Bộ và có biên nhận; nghĩa vụ pháp lý được chứng minh bằng nhật ký đồng bộ. | M | 5 | MVP, W2 | FR-14-043; UC-14-29 |
| US-14-044 | Là quản trị tỉnh, tôi muốn hệ thống cầu nối đồng bộ dữ liệu chủ hai chiều, để PH-06 đồng bộ dữ liệu chủ với quốc gia qua một cầu nối duy nhất, không có lô nào gửi đi khi chưa ánh xạ và chưa qua bảo vệ dữ liệu. | S | 5 | Đợt 3, W5 | FR-14-044; UC-14-30 |
| US-14-045 | Là quản trị tỉnh, tôi muốn công bố dữ liệu mở lên NDOP, để tập dữ liệu mở được công bố, cập nhật đều theo lịch, không lộ dữ liệu cá nhân. | S | 5 | Đợt 3, W5 | FR-14-045; UC-14-31 |
| US-14-046 | Là quản trị tỉnh, tôi muốn theo dõi trạng thái đồng bộ, xử lý lỗi và lệch, để lỗi và lệch được phát hiện và xử lý kịp, nghĩa vụ đăng ký không bị bỏ sót. | M | 3 | MVP, W2 | FR-14-046; UC-14-29, 14-30, 14-31 |

: Story của epic EP-14-G Đồng bộ

#### EP-14-H · Giám sát, nhật ký và đối soát

Epic gồm 7 story, 24 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-047 | Là quản trị tỉnh, tôi muốn hệ thống kiểm tra kết nối chủ động, để mất kết nối được phát hiện trong không quá 3 phút (NFR-14-007), trước khi người dân gặp lỗi; quản trị có hướng dẫn cụ thể khi kiểm tra không đạt. | M | 5 | MVP, W2 | FR-14-047; UC-14-01, 14-32 |
| US-14-048 | Là người dùng có quyền xem, tôi muốn tổng quan kết nối quốc gia, để người dùng thấy ngay việc cần làm trước; không phải mở nhiều màn để biết tình trạng. | M | 2 | MVP, W2 | FR-14-048; UC-14-32 |
| US-14-049 | Là quản trị tỉnh, tôi muốn tra cứu và đối soát giao dịch, để có bằng chứng giao dịch cho đối soát: gửi gì (đã che), nhận gì, ai xác minh, lúc nào. | M | 3 | MVP, W2 | FR-14-049; UC-14-33 |
| US-14-050 | Là cán bộ ATTT, tôi muốn xem nội dung bản tin đầy đủ có lý do, để SO xem được nội dung khi cần, mỗi lần xem đều có người, lý do và dấu vết; không ai khác xem được. | M | 5 | MVP, W2 | FR-14-050; UC-14-34 |
| US-14-051 | Là cán bộ ATTT, tôi muốn xuất bằng chứng giao dịch, để gói bằng chứng có chữ ký của Datahub, dùng được cho đối soát và thanh tra. | S | 3 | Đợt 2, W4 | FR-14-051; UC-14-33 |
| US-14-052 | Là quản trị tỉnh, tôi muốn có nhật ký khai thác theo HTTT và báo cáo sử dụng, để 100% lượt khai thác có nhật ký đủ thông tin cho thanh tra; quản trị thấy HTTT nào tiêu hạn mức nhiều nhất để làm việc với đơn vị đó. | M | 3 | MVP, W2 | FR-14-052; UC-14-12, 14-35 |
| US-14-053 | Là cán bộ ATTT, tôi muốn hệ thống cảnh báo bất thường khai thác, để hành vi khai thác bất thường được phát hiện trong 15 phút và được xử lý có hồ sơ. | S | 3 | Đợt 2, W4 | FR-14-053; UC-14-12, 14-35 |

: Story của epic EP-14-H Giám sát, nhật ký và đối soát

#### EP-14-I · Quản trị và chuyển đổi

Epic gồm 4 story, 12 điểm (1 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-14-054 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để tỉnh điều chỉnh vận hành của PH-14 trong miền an toàn; thay đổi nhạy có hai người. | M | 2 | MVP, W2 | FR-14-054; UC-14-36 |
| US-14-055 | Là quản trị tỉnh, tôi muốn chạy song song với kết nối NGSP cũ và đối chiếu, để TA có số liệu thật về mức khớp của đường mới trước khi chuyển lưu lượng, không có ghi trùng, không tốn hạn mức của dịch vụ công. | S | 5 | MVP, W2 | FR-14-055; UC-14-37, 14-38 |
| US-14-056 | Là kỹ sư tích hợp, tôi muốn nhập cấu hình dịch vụ từ hệ cũ, để danh mục dịch vụ của hệ cũ vào PH-14 nhanh, không mang theo khóa cũ; có bảng đối chiếu mã cũ và mới cho việc cắt chuyển. | S | 3 | MVP, W2 | FR-14-056; UC-14-38 |
| US-14-057 | Là quản trị tỉnh, tôi muốn có báo cáo hạn mức và hiệu quả đệm, để lãnh đạo và quản trị có báo cáo hạn mức, đệm đầy đủ để quyết định và đàm phán với trung ương. | C | 2 | Đợt 3, W5 | FR-14-057; UC-14-36 |

: Story của epic EP-14-I Quản trị và chuyển đổi

### 6.16. PH-15 · Cổng nhà phát triển

Phân hệ có 10 epic, 62 story, tổng 196 điểm; wave phát triển W4, đợt Đợt 2. Nguồn: D02-03-PH15 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-15-A · Danh mục, tìm kiếm và truy cập

Epic gồm 8 story, 22 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-001 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ danh mục dịch vụ từ PH-02, để nhà phát triển thấy danh mục và tài liệu đúng với bản đang phát hành, kèm cảnh báo nếu dữ liệu chậm. | M | 5 | Đợt 2, W4 | FR-15-001; UC-15-04 |
| US-15-002 | Là nhà phát triển, tôi muốn áp mức hiển thị theo người xem, để người dùng chỉ thấy dịch vụ mà họ được phép biết, không lộ sự tồn tại của dịch vụ khác. | M | 2 | Đợt 2, W4 | FR-15-002; UC-15-01 |
| US-15-003 | Là nhà phát triển, tôi muốn có trang chủ cổng, để trang chủ tải nhanh, dẫn người dùng tới đúng việc. | M | 2 | Đợt 2, W4 | FR-15-003; UC-15-01 |
| US-15-004 | Là nhà phát triển, tôi muốn duyệt, lọc, sắp xếp danh mục dịch vụ, để người dùng tìm được API theo nhu cầu trong vài thao tác. | M | 3 | Đợt 2, W4 | FR-15-004; UC-15-01 |
| US-15-005 | Là nhà phát triển, tôi muốn tìm kiếm toàn văn tiếng Việt và gợi ý, để kết quả liên quan lên đầu, không lộ dịch vụ ngoài tầm. | M | 2 | Đợt 2, W4 | FR-15-005; UC-15-02 |
| US-15-006 | Là nhà phát triển, tôi muốn có trang chi tiết dịch vụ, đường dẫn sử dụng và SLA, để nhà phát triển biết cách gọi API và điều kiện sử dụng mà không phải hỏi ai. | M | 3 | Đợt 2, W4 | FR-15-006; UC-15-03 |
| US-15-007 | Là nhà phát triển, tôi muốn hiển thị dịch vụ sự kiện, để nhà phát triển biết tỉnh có những sự kiện nào để nhận. | S | 2 | Đợt 2, W4 | FR-15-007; UC-15-01 |
| US-15-008 | Là quản trị tỉnh, tôi muốn truy cập ẩn danh cổng công khai, để dịch vụ công khai đọc được không cần tài khoản, dịch vụ khác vẫn kín. | M | 3 | Đợt 2, W4 | FR-15-008; UC-15-01 |

: Story của epic EP-15-A Danh mục, tìm kiếm và truy cập

#### EP-15-B · Tài liệu API

Epic gồm 5 story, 12 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-009 | Là nhà phát triển, tôi muốn hiển thị tài liệu OpenAPI 3.1, để tài liệu API đọc dễ, đúng bản đang phát hành, chia sẻ được bằng liên kết. | M | 3 | Đợt 2, W4 | FR-15-009; UC-15-05 |
| US-15-010 | Là nhà phát triển, tôi muốn hiển thị tài liệu AsyncAPI 3.0, để nhà phát triển hiểu thông điệp cần nhận, phát. | S | 2 | Đợt 2, W4 | FR-15-010; UC-15-05 |
| US-15-011 | Là nhà phát triển, tôi muốn chọn phiên bản, tải đặc tả, so sánh phiên bản, để nhà phát triển lấy được đặc tả đúng bản và thấy trước tác động của việc nâng cấp. | M | 3 | Đợt 2, W4 | FR-15-011; UC-15-05 |
| US-15-012 | Là nhà phát triển, tôi muốn sinh mẫu mã gọi API, để nhà phát triển có mã chạy được trong vài giây. | M | 2 | Đợt 2, W4 | FR-15-012; UC-15-05 |
| US-15-013 | Là nhà phát triển, tôi muốn changelog, lộ trình ngừng dùng và banner DEPRECATED, để nhà phát triển lên kế hoạch nâng cấp đúng hạn. | M | 2 | Đợt 2, W4 | FR-15-013; UC-15-03 |

: Story của epic EP-15-B Tài liệu API

#### EP-15-C · Hướng dẫn và nội dung

Epic gồm 5 story, 19 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-014 | Là chủ dịch vụ, tôi muốn soạn trang nội dung Markdown, để người soạn có bản nháp được xem trước đúng như hiển thị thật. | M | 3 | Đợt 2, W4 | FR-15-014; UC-15-06 |
| US-15-015 | Là người duyệt dịch vụ, tôi muốn gửi duyệt, duyệt và đăng trang, để nội dung đã duyệt hiện cho người đọc ngay; nội dung bị từ chối quay về người soạn kèm lý do. | M | 5 | Đợt 2, W4 | FR-15-015; UC-15-07 |
| US-15-016 | Là nhà phát triển, tôi muốn có phiên bản trang, so sánh, khôi phục, gỡ đăng, để có đủ lịch sử để truy trách nhiệm và hoàn tác. | S | 3 | Đợt 2, W4 | FR-15-016; UC-15-07 |
| US-15-017 | Là nhà phát triển, tôi muốn hiển thị trang nội dung, để người đọc thấy hướng dẫn rõ, an toàn. | M | 3 | Đợt 2, W4 | FR-15-017; UC-15-09 |
| US-15-018 | Là quản trị tỉnh, tôi muốn nhập nội dung từ kho Git, để tài liệu viết ở kho Git xuất hiện thành nháp ở cổng, chờ duyệt. | S | 5 | Đợt 3, W5 | FR-15-018; UC-15-08 |

: Story của epic EP-15-C Hướng dẫn và nội dung

#### EP-15-D · Tài khoản nhà phát triển

Epic gồm 6 story, 23 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-019 | Là nhà phát triển, tôi muốn đăng nhập SSO realm tenant, để người dùng đăng nhập, thấy đúng danh mục theo hạng của mình. | M | 5 | Đợt 2, W4 | FR-15-019; UC-15-10 |
| US-15-020 | Là nhà phát triển, tôi muốn tự đăng ký tài khoản dh-dev, để người đăng ký biết đang chờ xác minh rồi chờ duyệt, không nhận quyền gì trước khi được duyệt. | M | 5 | Đợt 2, W4 | FR-15-020; UC-15-11 |
| US-15-021 | Là người dùng, tôi muốn có hồ sơ cá nhân và phiên đăng nhập, để hồ sơ cập nhật; phiên bị thu hồi mất hiệu lực ngay. | M | 3 | Đợt 2, W4 | FR-15-021; UC-15-12 |
| US-15-022 | Là người dùng, tôi muốn nhóm phát triển, để cả đội cùng làm việc trên ứng dụng của nhóm. | S | 3 | Đợt 2, W4 | FR-15-022; UC-15-13 |
| US-15-023 | Là người dùng, tôi muốn chấp nhận điều khoản sử dụng có phiên bản, để có bằng chứng người dùng đã đồng ý. | M | 2 | Đợt 2, W4 | FR-15-023; UC-15-12 |
| US-15-024 | Là quản trị tỉnh, tôi muốn hệ thống vô hiệu hóa không hoạt động và xóa tài khoản, để tài khoản không còn dùng được và dữ liệu cá nhân bị ẩn danh. | S | 5 | Đợt 2, W4 | FR-15-024; UC-15-12 |

: Story của epic EP-15-D Tài khoản nhà phát triển

#### EP-15-E · Ứng dụng sandbox và thông tin xác thực

Epic gồm 9 story, 33 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-025 | Là nhà phát triển, tôi muốn tạo ứng dụng sandbox, để nhà phát triển có ứng dụng sandbox và biết bước kế tiếp là cấp thông tin xác thực. | M | 5 | Đợt 2, W4 | FR-15-025; UC-15-14 |
| US-15-026 | Là nhà phát triển, tôi muốn xem, sửa, lưu trữ, khôi phục ứng dụng, để người dùng quản lý được vòng đời ứng dụng của mình. | M | 5 | Đợt 2, W4 | FR-15-026; UC-15-14 |
| US-15-027 | Là nhà phát triển, tôi muốn cấp thông tin xác thực client_credentials sandbox, để nhà phát triển có thể lấy token và gọi sandbox ngay. | M | 5 | Đợt 2, W4 | FR-15-027; UC-15-15 |
| US-15-028 | Là nhà phát triển, tôi muốn cấp API key sandbox, để khóa dùng được ngay ở sandbox. | M | 3 | Đợt 2, W4 | FR-15-028; UC-15-15 |
| US-15-029 | Là nhà phát triển, tôi muốn hiển thị bí mật đúng một lần, để người dùng nhận bí mật một lần và biết rõ phải lưu ngay. | M | 2 | Đợt 2, W4 | FR-15-029; UC-15-15 |
| US-15-030 | Là nhà phát triển, tôi muốn xoay vòng thông tin xác thực, để bí mật mới có hiệu lực, bản cũ còn dùng được trong thời gian ngắn. | M | 5 | Đợt 2, W4 | FR-15-030; UC-15-16 |
| US-15-031 | Là nhà phát triển, tôi muốn thu hồi và hết hạn thông tin xác thực, để khóa bị thu hồi không còn dùng được ở sandbox sau tối đa 60 giây. | M | 3 | Đợt 2, W4 | FR-15-031; UC-15-16 |
| US-15-032 | Là nhà phát triển, tôi muốn xem tham chiếu thông tin xác thực production, để cán bộ biết thông tin xác thực production còn hạn hay không, không cần hỏi quản trị. | M | 2 | Đợt 2, W4 | FR-15-032; UC-15-17 |
| US-15-033 | Là nhà phát triển, tôi muốn giao ứng dụng cho thành viên, để quyền trên ứng dụng đúng người, đúng việc. | S | 3 | Đợt 2, W4 | FR-15-033; UC-15-13 |

: Story của epic EP-15-E Ứng dụng sandbox và thông tin xác thực

#### EP-15-F · Sandbox và thử API

Epic gồm 10 story, 33 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-034 | Là chủ dịch vụ, tôi muốn khai báo sandbox của dịch vụ, để API có sandbox đúng chế độ chủ dịch vụ chọn. | M | 3 | Đợt 2, W4 | FR-15-034; UC-15-18 |
| US-15-035 | Là nhà phát triển, tôi muốn thử API trên sandbox, để người dùng thấy phản hồi và biết nó từ MOCK hay BACKEND. | M | 5 | Đợt 2, W4 | FR-15-035; UC-15-19 |
| US-15-036 | Là nhà phát triển, tôi muốn hệ thống có chế độ sandbox MOCK, để nhà phát triển thấy phản hồi đúng hình dạng thật mà không có dữ liệu thật. | M | 2 | Đợt 2, W4 | FR-15-036; UC-15-19 |
| US-15-037 | Là nhà phát triển, tôi muốn hệ thống có chế độ sandbox BACKEND, để người dùng thử với hành vi sát thật mà không đụng production. | M | 3 | Đợt 2, W4 | FR-15-037; UC-15-19 |
| US-15-038 | Là nhà phát triển, tôi muốn hệ thống dữ liệu mẫu tổng hợp và chặn dữ liệu cá nhân thật, để sandbox không nhận dữ liệu cá nhân thật. | M | 2 | Đợt 2, W4 | FR-15-038; UC-15-19 |
| US-15-039 | Là nhà phát triển, tôi muốn hệ thống hạn mức sandbox, để sandbox không bị làm quá tải, người dùng biết giới hạn. | M | 3 | Đợt 2, W4 | FR-15-039; UC-15-19 |
| US-15-040 | Là nhà phát triển, tôi muốn có lịch sử thử và bộ sưu tập yêu cầu, để người dùng làm lại phép thử trong vài giây. | S | 2 | Đợt 2, W4 | FR-15-040; UC-15-20 |
| US-15-041 | Là nhà phát triển, tôi muốn xuất Postman, Bruno, HTTP, để công cụ ngoài nạp được bộ yêu cầu. | C | 2 | Đợt 3, W5 | FR-15-041; UC-15-20 |
| US-15-042 | Là chủ dịch vụ, tôi muốn bật, tắt thử production theo dịch vụ, để chỉ những dịch vụ được duyệt mới cho thử production, và có hạn. | M | 3 | Đợt 2, W4 | FR-15-042; UC-15-21 |
| US-15-043 | Là nhà phát triển, tôi muốn thử API trên production, để người dùng kiểm tra được lời gọi đọc thật, mọi lượt đều có dấu vết. | M | 8 | Đợt 2, W4 | FR-15-043; UC-15-22 |

: Story của epic EP-15-F Sandbox và thử API

#### EP-15-G · Đăng ký sử dụng và điểm vào nghiệp vụ

Epic gồm 4 story, 12 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-044 | Là cán bộ đầu mối của tổ chức, tôi muốn gửi đăng ký sử dụng API production, để đăng ký sử dụng được gửi đúng quy trình và người dùng biết ai sẽ duyệt. | M | 3 | Đợt 2, W4 | FR-15-044; UC-15-23 |
| US-15-045 | Là cán bộ đầu mối của tổ chức, tôi muốn theo dõi đăng ký sử dụng, để người dùng biết chính xác trạng thái và bước kế tiếp. | M | 3 | Đợt 2, W4 | FR-15-045; UC-15-23 |
| US-15-046 | Là cán bộ đầu mối của tổ chức, tôi muốn điểm vào kết nạp HTTT (F-01), để hồ sơ vào đúng quy trình kết nạp, người dùng theo dõi được. | M | 3 | Đợt 2, W4 | FR-15-046; UC-15-24 |
| US-15-047 | Là chủ dịch vụ, tôi muốn điểm vào công bố API (F-02), để chủ dịch vụ đưa API vào quy trình công bố mà không rời cổng. | M | 3 | Đợt 2, W4 | FR-15-047; UC-15-25 |

: Story của epic EP-15-G Đăng ký sử dụng và điểm vào nghiệp vụ

#### EP-15-H · Theo dõi của nhà phát triển

Epic gồm 5 story, 10 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-048 | Là người dùng, tôi muốn có bảng điều khiển cá nhân, để người dùng nắm việc trong một màn hình. | S | 2 | Đợt 2, W4 | FR-15-048; UC-15-26 |
| US-15-049 | Là nhà phát triển, tôi muốn thống kê lượt gọi và lỗi theo ứng dụng, để nhà phát triển thấy ứng dụng hoạt động thế nào. | M | 2 | Đợt 2, W4 | FR-15-049; UC-15-26 |
| US-15-050 | Là nhà phát triển, tôi muốn có nhật ký gọi của ứng dụng đã che dữ liệu, để nhà phát triển truy được nguyên nhân lỗi mà không lộ dữ liệu. | S | 2 | Đợt 2, W4 | FR-15-050; UC-15-26 |
| US-15-051 | Là người dùng, tôi muốn đăng ký nhận thông báo thay đổi API, để nhà phát triển không bỏ sót thay đổi quan trọng. | M | 2 | Đợt 2, W4 | FR-15-051; UC-15-27 |
| US-15-052 | Là người dùng, tôi muốn có hộp thông báo, để người dùng không bỏ lỡ việc cần làm. | M | 2 | Đợt 2, W4 | FR-15-052; UC-15-27 |

: Story của epic EP-15-H Theo dõi của nhà phát triển

#### EP-15-I · Hỗ trợ và phản hồi

Epic gồm 3 story, 9 điểm (1 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-053 | Là chủ dịch vụ, tôi muốn hỏi đáp, báo lỗi tài liệu, đánh giá trang, để phản hồi đến đúng chủ dịch vụ. | C | 3 | Đợt 3, W5 | FR-15-053; UC-15-28 |
| US-15-054 | Là người dùng, tôi muốn gửi yêu cầu hỗ trợ cho chủ dịch vụ, để yêu cầu tới đúng người, có mã để theo dõi. | M | 3 | Đợt 2, W4 | FR-15-054; UC-15-28 |
| US-15-055 | Là chủ dịch vụ, tôi muốn xử lý yêu cầu hỗ trợ, để phiếu được trả lời trong hạn hoặc được báo động. | S | 3 | Đợt 2, W4 | FR-15-055; UC-15-28 |

: Story của epic EP-15-I Hỗ trợ và phản hồi

#### EP-15-J · Quản trị cổng

Epic gồm 7 story, 23 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-15-056 | Là quản trị tỉnh, tôi muốn có cấu hình nhận diện cổng theo tenant, để cổng mang tên và logo của tỉnh. | M | 3 | Đợt 2, W4 | FR-15-056; UC-15-29 |
| US-15-057 | Là quản trị tỉnh, tôi muốn có tham số cổng, để hành vi cổng thay đổi đúng tham số, trong biên an toàn. | M | 3 | Đợt 2, W4 | FR-15-057; UC-15-29 |
| US-15-058 | Là quản trị tỉnh, tôi muốn duyệt tài khoản dh-dev, để nhà thầu được duyệt đăng nhập được; người bị từ chối biết lý do. | M | 5 | Đợt 2, W4 | FR-15-058; UC-15-30 |
| US-15-059 | Là quản trị tỉnh, tôi muốn khóa, mở khóa tài khoản và ứng dụng, để lạm dụng bị chặn ngay, có dấu vết. | M | 3 | Đợt 2, W4 | FR-15-059; UC-15-30 |
| US-15-060 | Là quản trị tỉnh, tôi muốn có nhật ký truy cập, thử và báo cáo sử dụng cổng, để truy ra được ai làm gì; đo được mức dùng cổng. | M | 3 | Đợt 2, W4 | FR-15-060; UC-15-31 |
| US-15-061 | Là quản trị tỉnh, tôi muốn đồng bộ lại và đối soát danh mục với PH-02, để bản sao được kiểm chứng và sửa khi lệch. | S | 3 | Đợt 2, W4 | FR-15-061; UC-15-04 |
| US-15-062 | Là quản trị tỉnh, tôi muốn di trú nội dung portal hệ cũ, để nội dung cũ có mặt ở cổng mới dưới dạng nháp chờ duyệt. | S | 3 | Đợt 2, W4 | FR-15-062; UC-15-08 |

: Story của epic EP-15-J Quản trị cổng

### 6.17. PH-16 · Báo cáo chỉ tiêu và sổ kiến trúc

Phân hệ có 9 epic, 58 story, tổng 150 điểm; wave phát triển W5, đợt Đợt 3. Nguồn: D02-03-PH16 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-16-A · Bộ chỉ tiêu

Epic gồm 8 story, 26 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-001 | Là người dùng có quyền xem, tôi muốn liệt kê, tìm, lọc bộ chỉ tiêu theo nhóm, trạng thái, cách đo, để người dùng thấy danh sách chỉ tiêu theo năm nhóm, lọc nhanh chỉ tiêu cần nhập tay hoặc đang chờ duyệt. | M | 1 | Đợt 3, W5 | FR-16-001; UC-16-01 |
| US-16-002 | Là quản trị tỉnh, tôi muốn tạo chỉ tiêu và phiên bản định nghĩa nháp, để chỉ tiêu mới xuất hiện ở bộ chỉ tiêu với nhãn "Nháp", người dùng chuyển sang soạn công thức. | M | 3 | Đợt 3, W5 | FR-16-002; UC-16-02 |
| US-16-003 | Là quản trị tỉnh, tôi muốn soạn công thức CEL, biến quan sát, thử tính trên dữ liệu kỳ trước, để người soạn thấy giá trị công thức mới trên ba kỳ gần nhất cạnh giá trị đang công bố, nhận ra ngay công thức sai trước khi trình duyệt. | M | 5 | Đợt 3, W5 | FR-16-003; UC-16-02 |
| US-16-004 | Là quản trị tỉnh, tôi muốn đặt mục tiêu, ngưỡng ba mức, chiều tốt, đơn vị, làm tròn, để chỉ tiêu có mục tiêu và ba vùng màu rõ ràng; sau khi duyệt, bảng điều khiển dùng ngay ngưỡng mới cho kỳ chưa chốt. | M | 2 | Đợt 3, W5 | FR-16-004; UC-16-02 |
| US-16-005 | Là quản trị tỉnh, tôi muốn gửi duyệt và duyệt bốn mắt phiên bản định nghĩa, để định nghĩa mới chỉ có hiệu lực khi hai người đồng ý; mọi lần tổng hợp sau đó dùng phiên bản mới. | M | 5 | Đợt 3, W5 | FR-16-005; UC-16-03 |
| US-16-006 | Là quản trị tỉnh, tôi muốn ngừng, thay thế chỉ tiêu; lịch sử phiên bản, so sánh, để chỉ tiêu cũ không còn ở kỳ mới nhưng số các kỳ trước vẫn tra được và giải thích được. | S | 3 | Đợt 3, W5 | FR-16-006; UC-16-03 |
| US-16-007 | Là quản trị tỉnh, tôi muốn quản lý nhóm chỉ tiêu và trọng số điểm nhóm, để bảng điều khiển hiện nhóm theo tên và thứ tự tỉnh chọn; điểm tổng dùng trọng số mới. | S | 2 | Đợt 3, W5 | FR-16-007; UC-16-01 |
| US-16-008 | Là quản trị tỉnh, tôi muốn kế thừa bộ chỉ tiêu mẫu COMMON, nhận cập nhật mẫu, để tỉnh mới có bảng điều khiển đủ năm nhóm ngay khi số liệu đầu tiên về; khi mẫu đổi, tỉnh thấy rõ thay đổi và tự quyết. | M | 5 | Đợt 3, W5 | FR-16-008; UC-16-04 |

: Story của epic EP-16-A Bộ chỉ tiêu

#### EP-16-B · Nguồn số liệu

Epic gồm 8 story, 33 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-009 | Là quản trị tỉnh, tôi muốn đăng ký nguồn và hợp đồng chỉ số, để nguồn xuất hiện ở UI-16-05, bắt đầu nhận số; chỉ tiêu dùng biến của nguồn hết cảnh báo "chưa có nguồn". | M | 5 | Đợt 3, W5 | FR-16-009; UC-16-05 |
| US-16-010 | Là quản trị tỉnh, tôi muốn hệ thống tiếp nhận quan sát từ sự kiện Kafka, idempotent, chuẩn hóa, để số của phân hệ nguồn có trên bảng điều khiển trong vòng một phút; nguồn chuyển `ACTIVE` nếu đang `STALE`. | M | 5 | Đợt 3, W5 | FR-16-010; UC-16-06 |
| US-16-011 | Là quản trị tỉnh, tôi muốn hệ thống kéo API chỉ số của phân hệ theo lịch, đọc bù khi lỡ sự kiện, để bảng điều khiển có đủ số cả khi phân hệ nguồn không phát sự kiện hoặc sự kiện bị lỡ. | M | 3 | Đợt 3, W5 | FR-16-011; UC-16-06 |
| US-16-012 | Là quản trị tỉnh, tôi muốn nhận quan sát qua API kpi.ingest, để bên gọi biết chính xác phần tử nào đã vào; TO thấy lỗi ở nhật ký nguồn. | S | 5 | Đợt 3, W5 | FR-16-012; UC-16-06 |
| US-16-013 | Là quản trị tỉnh, tôi muốn hệ thống theo dõi độ tươi, chuyển STALE, FAILED, cảnh báo, để TO nhận thông báo trong vòng 15 phút kể từ khi nguồn quá hạn (NFR-16-014); UI-16-05 hiện nguồn đỏ, vàng lên đầu. | M | 3 | Đợt 3, W5 | FR-16-013; UC-16-05 |
| US-16-014 | Là vận hành tỉnh, tôi muốn nhập số liệu tay kèm bằng chứng, để số tay có bằng chứng đi kèm, nằm chờ người thứ hai xác nhận; bảng điều khiển hiện "Chờ xác nhận" thay vì số. | M | 5 | Đợt 3, W5 | FR-16-014; UC-16-08 |
| US-16-015 | Là người dùng, tôi muốn xác nhận hoặc từ chối số liệu tay, để số tay được xác nhận xuất hiện trên bảng điều khiển với biểu tượng "nhập tay, đã xác nhận" và liên kết tới bằng chứng. | M | 5 | Đợt 3, W5 | FR-16-015; UC-16-08 |
| US-16-016 | Là quản trị tỉnh, tôi muốn tra nhật ký tiếp nhận, quan sát bị loại, xử lý lại, để cán bộ thấy rõ từng bản tin bị loại vì sao và đưa được số đúng vào kỳ chưa chốt. | S | 2 | Đợt 3, W5 | FR-16-016; UC-16-07 |

: Story của epic EP-16-B Nguồn số liệu

#### EP-16-C · Tính toán

Epic gồm 8 story, 18 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-017 | Là quản trị tỉnh, tôi muốn hệ thống quản lý lịch kỳ báo cáo theo tháng, quý, năm, để UI-16-08 luôn có kỳ đang mở và kỳ chờ chốt, kèm ngày chốt dự kiến. | M | 1 | Đợt 3, W5 | FR-16-017; UC-16-09 |
| US-16-018 | Là quản trị tỉnh, tôi muốn hệ thống chạy tổng hợp theo lịch hoặc thủ công, để sáng hôm sau, bảng điều khiển có số mới của kỳ; người chạy tay thấy tiến độ ở UI-16-09. | M | 3 | Đợt 3, W5 | FR-16-018; UC-16-10 |
| US-16-019 | Là quản trị tỉnh, tôi muốn hệ thống tính giá trị chỉ tiêu theo phiên bản công thức có hiệu lực, lưu dòng truy nguồn, để mỗi số trên UI-16-02 có nút "Nguồn số liệu" mở danh sách quan sát và phiên bản công thức đã dùng. | M | 2 | Đợt 3, W5 | FR-16-019; UC-16-11 |
| US-16-020 | Là quản trị tỉnh, tôi muốn hệ thống đánh giá độ đầy đủ, gắn PARTIAL, cờ thiếu nguồn, để bảng điều khiển hiện nhãn "Thiếu một phần" màu xám sọc, kèm tên nguồn thiếu; lãnh đạo không đọc nhầm số thiếu là số đủ. | M | 2 | Đợt 3, W5 | FR-16-020; UC-16-11 |
| US-16-021 | Là quản trị tỉnh, tôi muốn hệ thống đánh giá trạng thái so mục tiêu, ngưỡng; phát cảnh báo chệch, để lãnh đạo có đăng ký nhận nhận thông báo "Chỉ tiêu {tên} chuyển Chệch mục tiêu ở kỳ {kỳ}" qua kênh PH-13. | M | 2 | Đợt 3, W5 | FR-16-021; UC-16-11 |
| US-16-022 | Là quản trị tỉnh, tôi muốn hệ thống tính điểm nhóm, xu hướng, chênh lệch so kỳ trước, cùng kỳ năm trước, để UI-16-01 hiện năm vòng điểm nhóm, mũi tên xu hướng cạnh từng chỉ tiêu. | S | 2 | Đợt 3, W5 | FR-16-022; UC-16-11 |
| US-16-023 | Là quản trị tỉnh, tôi muốn hệ thống tính lại khi có số liệu trễ hoặc đổi công thức, để số trễ tự phản ánh lên bảng điều khiển trong ≤ 10 phút (NFR-16-002). | M | 3 | Đợt 3, W5 | FR-16-023; UC-16-10 |
| US-16-024 | Là quản trị tỉnh, tôi muốn chốt kỳ, mở lại kỳ có lý do, để báo cáo chính thức lập được từ kỳ đã chốt; số không đổi nữa trừ khi mở lại có lý do được lưu vết. | M | 3 | Đợt 3, W5 | FR-16-024; UC-16-09 |

: Story của epic EP-16-C Tính toán

#### EP-16-D · Báo cáo

Epic gồm 8 story, 19 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-025 | Là quản trị tỉnh, tôi muốn quản lý mẫu báo cáo, để mẫu sẵn sàng; lập báo cáo kỳ chỉ cần chọn mẫu và kỳ. | M | 2 | Đợt 3, W5 | FR-16-025; UC-16-12 |
| US-16-026 | Là quản trị tỉnh, tôi muốn lập bản nháp báo cáo từ kỳ đã tính, để cán bộ mở UI-16-11 thấy báo cáo dựng sẵn và danh sách chỉ tiêu cần giải trình. | M | 2 | Đợt 3, W5 | FR-16-026; UC-16-13 |
| US-16-027 | Là quản trị tỉnh, tôi muốn viết thuyết minh, giải trình chỉ tiêu chệch, để báo cáo có thuyết minh đầy đủ; nút "Gửi duyệt" chỉ sáng khi không còn giải trình thiếu. | M | 2 | Đợt 3, W5 | FR-16-027; UC-16-13 |
| US-16-028 | Là quản trị tỉnh, tôi muốn gửi duyệt, yêu cầu sửa, duyệt bốn mắt, để báo cáo chỉ được công bố khi người thứ hai đồng ý; ý kiến yêu cầu sửa hiện ngay cạnh phần liên quan. | M | 5 | Đợt 3, W5 | FR-16-028; UC-16-14 |
| US-16-029 | Là quản trị tỉnh, tôi muốn công bố báo cáo chính thức: chụp bất biến, ký số, lưu WORM, để báo cáo có dấu "Đã công bố", tải được bản PDF ký số và bằng chứng; mọi người có `PERM-16-read` thấy báo cáo. | M | 3 | Đợt 3, W5 | FR-16-029; UC-16-15 |
| US-16-030 | Là quản trị tỉnh, tôi muốn đính chính báo cáo đã công bố bằng phiên bản mới; rút báo cáo, để người đọc luôn thấy phiên bản đúng nhất, đồng thời tra được bản cũ và lý do đính chính. | S | 3 | Đợt 3, W5 | FR-16-030; UC-16-16 |
| US-16-031 | Là quản trị tỉnh, tôi muốn liệt kê, tìm, xem báo cáo và lịch sử phiên bản, để người dùng mở được báo cáo bất kỳ trong 10 năm qua. | M | 1 | Đợt 3, W5 | FR-16-031; UC-16-17 |
| US-16-032 | Là quản trị tỉnh, tôi muốn có báo cáo đột xuất theo khoảng thời gian, tập chỉ tiêu tự chọn, để lãnh đạo nhận báo cáo theo đúng câu hỏi trong ngày. | C | 1 | Đợt 3, W5 | FR-16-032; UC-16-13 |

: Story của epic EP-16-D Báo cáo

#### EP-16-E · Xuất, phân phối

Epic gồm 5 story, 8 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-033 | Là quản trị tỉnh, tôi muốn xuất báo cáo, bảng chỉ tiêu ra PDF, XLSX, CSV, JSON, để người dùng nhận thông báo và tải tệp trong 24 giờ. | M | 3 | Đợt 3, W5 | FR-16-033; UC-16-18 |
| US-16-034 | Là quản trị tỉnh, tôi muốn có danh sách phân phối và lịch gửi theo kỳ qua kênh thông báo PH-13, để lãnh đạo nhận báo cáo ngay khi công bố. | S | 2 | Đợt 3, W5 | FR-16-034; UC-16-18 |
| US-16-035 | Là quản trị tỉnh, tôi muốn API đọc chỉ tiêu, báo cáo cho hệ khác (kpi.read), để cổng tỉnh và trợ lý PH-17 hiện cùng con số với báo cáo đã công bố. | M | 1 | Đợt 3, W5 | FR-16-035; UC-16-19 |
| US-16-036 | Là kiểm toán viên, tôi muốn tải bằng chứng công bố (tệp ký, mã băm, nhật ký), để kiểm toán có gói bằng chứng tự kiểm chứng được ngoài hệ thống. | S | 1 | Đợt 3, W5 | FR-16-036; UC-16-17 |
| US-16-037 | Là người dùng, tôi muốn cung cấp thẻ chỉ tiêu cho trang Tổng quan /tong-quan, để lãnh đạo thấy bốn số chính và màu trạng thái ngay trang đầu. | S | 1 | Đợt 3, W5 | FR-16-037; UC-16-19 |

: Story của epic EP-16-E Xuất, phân phối

#### EP-16-F · Bảng điều khiển

Epic gồm 5 story, 6 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-038 | Là người dùng có quyền xem, tôi muốn có bảng điều khiển tổng quan năm nhóm cho lãnh đạo, để lãnh đạo thấy năm vòng điểm, số chỉ tiêu đỏ, vàng, xanh và danh sách việc cần chỉ đạo. | M | 1 | Đợt 3, W5 | FR-16-038; UC-16-20 |
| US-16-039 | Là kiểm toán viên, tôi muốn chi tiết chỉ tiêu: chuỗi thời gian, mục tiêu, nguồn, truy tới quan sát, để người dùng đi từ con số trên báo cáo tới đúng sự kiện hoặc văn bản gốc trong ba lần bấm. | M | 2 | Đợt 3, W5 | FR-16-039; UC-16-20 |
| US-16-040 | Là người dùng có quyền xem, tôi muốn lọc theo kỳ, nhóm, trạng thái; so sánh hai kỳ, để lãnh đạo thấy chỉ tiêu nào cải thiện, chỉ tiêu nào xấu đi. | S | 1 | Đợt 3, W5 | FR-16-040; UC-16-20 |
| US-16-041 | Là quản trị nền tảng, tôi muốn so sánh liên tenant ẩn danh cho quản trị nền tảng, để quản trị nền tảng thấy vị trí từng tỉnh trên phân bố chung. | C | 1 | Đợt 3, W5 | FR-16-041; UC-16-21 |
| US-16-042 | Là quản trị tỉnh, tôi muốn theo dõi tình trạng thu thập, tính toán (vận hành), để người vận hành phát hiện nguồn treo và lần tổng hợp lỗi trên một màn. | S | 1 | Đợt 3, W5 | FR-16-042; UC-16-22 |

: Story của epic EP-16-F Bảng điều khiển

#### EP-16-G · Sổ kiến trúc

Epic gồm 7 story, 21 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-043 | Là người dùng có quyền xem, tôi muốn liệt kê, tìm thành phần kiến trúc theo loại, vòng đời, tuân thủ, để người dùng lọc nhanh "API đang hoạt động chưa đánh giá tuân thủ". | M | 1 | Đợt 3, W5 | FR-16-043; UC-16-23 |
| US-16-044 | Là quản trị tỉnh, tôi muốn hệ thống tự đăng ký, cập nhật thành phần từ sự kiện phân hệ nguồn, để HTTT vừa kết nạp xuất hiện trong sổ kiến trúc ≤ 60 giây (NFR-16-015). | M | 5 | Đợt 3, W5 | FR-16-044; UC-16-24 |
| US-16-045 | Là quản trị tỉnh, tôi muốn khai báo, sửa thành phần thủ công; phiên bản, phụ thuộc, để sổ kiến trúc có đủ thành phần cả trong và ngoài Datahub, có chủ quản rõ ràng. | S | 3 | Đợt 3, W5 | FR-16-045; UC-16-25 |
| US-16-046 | Là quản trị tỉnh, tôi muốn hệ thống cập nhật trạng thái vận hành từ PH-13, để sổ kiến trúc hiện chấm xanh, vàng, đỏ, xám theo trạng thái thực. | S | 2 | Đợt 3, W5 | FR-16-046; UC-16-24 |
| US-16-047 | Là quản trị tỉnh, tôi muốn đánh giá tuân thủ theo bộ tiêu chí, xác nhận, miễn trừ có hạn, để sổ kiến trúc hiện mức tuân thủ có xác nhận và hạn miễn trừ; chỉ tiêu `thanh-phan-da-danh-gia-tuan-thu` tự cập nhật. | M | 5 | Đợt 3, W5 | FR-16-047; UC-16-26 |
| US-16-048 | Là quản trị tỉnh, tôi muốn hệ thống đối chiếu sổ kiến trúc với phân hệ nguồn, phát hiện lệch, mồ côi, để sổ kiến trúc được làm sạch hằng tuần; mục lệch có người chịu trách nhiệm xử lý. | S | 3 | Đợt 3, W5 | FR-16-048; UC-16-24 |
| US-16-049 | Là quản trị tỉnh, tôi muốn xuất sổ kiến trúc, sơ đồ phụ thuộc, để tỉnh có sổ và sơ đồ cập nhật đến ngày xuất. | C | 2 | Đợt 3, W5 | FR-16-049; UC-16-23 |

: Story của epic EP-16-G Sổ kiến trúc

#### EP-16-H · Gửi quốc gia

Epic gồm 5 story, 13 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-050 | Là quản trị nền tảng, tôi muốn quản lý mẫu gói quốc gia có phiên bản, để mọi tỉnh dùng cùng mẫu gói đã kiểm, đổi đặc tả chỉ cần nạp phiên bản mới. | M | 1 | Đợt 3, W5 | FR-16-050; UC-16-27 |
| US-16-051 | Là quản trị tỉnh, tôi muốn lập và gửi gói báo cáo chỉ tiêu qua PH-14, để TA thấy gói đi qua từng trạng thái tới khi có mã biên nhận. | M | 5 | Đợt 3, W5 | FR-16-051; UC-16-28 |
| US-16-052 | Là quản trị tỉnh, tôi muốn gửi sổ kiến trúc qua PH-14, để hệ quốc gia có sổ kiến trúc cập nhật của tỉnh kèm biên nhận. | S | 3 | Đợt 3, W5 | FR-16-052; UC-16-28 |
| US-16-053 | Là quản trị tỉnh, tôi muốn có nhật ký nộp làm bằng chứng, biên nhận, gửi lại khi lỗi, để TA và kiểm toán có chuỗi bằng chứng nộp cho từng gói, tải được kèm biên nhận. | M | 3 | Đợt 3, W5 | FR-16-053; UC-16-29 |
| US-16-054 | Là quản trị tỉnh, tôi muốn đối soát sổ kiến trúc, gói đã nộp và chỉ tiêu, để TA biết cần nộp bổ sung gì và chỉ tiêu nào có thể lệch với sổ. | C | 1 | Đợt 3, W5 | FR-16-054; UC-16-29 |

: Story của epic EP-16-H Gửi quốc gia

#### EP-16-I · Quản trị

Epic gồm 4 story, 6 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-16-055 | Là quản trị tỉnh, tôi muốn có tham số phân hệ theo tenant, để thay đổi có hiệu lực trong một phút, không gián đoạn dịch vụ. | M | 2 | Đợt 3, W5 | FR-16-055; UC-16-30 |
| US-16-056 | Là kiểm toán viên, tôi muốn hệ thống có nhật ký kiểm toán thao tác PH-16, tra cứu, để kiểm toán thấy ai đã duyệt, công bố, mở lại kỳ, sửa số và khi nào. | M | 1 | Đợt 3, W5 | FR-16-056; UC-16-30 |
| US-16-057 | Là quản trị tỉnh, tôi muốn hệ thống lưu giữ, xóa dữ liệu theo hạn; giữ báo cáo công bố 10 năm, để dung lượng `ph16_kpi` ổn định; báo cáo chính thức giữ đủ 10 năm. | S | 2 | Đợt 3, W5 | FR-16-057; UC-16-30 |
| US-16-058 | Là quản trị tỉnh, tôi muốn hệ thống có chỉ số vận hành của chính PH-16 cho PH-13, để PH-13 có bảng Grafana PH-16 và cảnh báo nguồn treo, lần tổng hợp lỗi, gói quốc gia lỗi. | S | 1 | Đợt 3, W5 | FR-16-058; UC-16-22 |

: Story của epic EP-16-I Quản trị

### 6.18. PH-17 · Trợ lý AI và quản trị AI

Phân hệ có 10 epic, 62 story, tổng 214 điểm; wave phát triển W5, đợt Đợt 3. Nguồn: D02-03-PH17 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-17-A · Bật tắt và chính sách AI theo tenant

Epic gồm 6 story, 24 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-001 | Là quản trị tỉnh, tôi muốn bật, tắt trợ lý cho tenant có quyết định và kiểm toán, để quản trị tỉnh thấy trạng thái "Đang bật" kèm số quyết định; người dùng có quyền thấy nút "Trợ lý" và phải xác nhận điều khoản ở lần dùng đầu. | M | 5 | Đợt 3, W5 | FR-17-001; UC-17-01 |
| US-17-002 | Là quản trị tỉnh, tôi muốn bật, tắt từng năng lực và theo nhóm vai trò, để mỗi người chỉ thấy lối vào đúng năng lực được phép; quản trị thấy bảng năng lực theo nhóm vai trò. | M | 3 | Đợt 3, W5 | FR-17-002; UC-17-02 |
| US-17-003 | Là quản trị tỉnh, tôi muốn có chính sách dùng mô hình ngoài, để tỉnh thấy rõ nhà cung cấp ngoài nào được phép, cam kết nào, hết hạn khi nào; người dùng thấy nhãn "Mô hình ngoài" ở bảng bên khi câu trả lời đến từ nhà cung cấp ngoài. | M | 5 | Đợt 3, W5 | FR-17-003; UC-17-03, 17-09 |
| US-17-004 | Là quản trị tỉnh, tôi muốn hạn mức theo người dùng và tenant, độ dài đầu vào và đầu ra, để người dùng biết còn bao nhiêu lượt; quản trị thấy mức dùng so với hạn mức theo ngày. | M | 5 | Đợt 3, W5 | FR-17-004; UC-17-02 |
| US-17-005 | Là quản trị tỉnh, tôi muốn thông báo minh bạch và điều khoản dùng AI, người dùng xác nhận, để mỗi người dùng có bằng chứng đã đồng ý điều khoản hiện hành; TA chứng minh được đã thông báo. | S | 3 | Đợt 3, W5 | FR-17-005; UC-17-04 |
| US-17-006 | Là quản trị tỉnh, tôi muốn tắt khẩn cấp toàn tenant hoặc toàn nền tảng trong ≤ 60 giây, để trợ lý ngừng nhận câu hỏi trong chưa đầy một phút; quản trị thấy đồng hồ đếm thời gian hiệu lực ở mọi bản sao. | M | 3 | Đợt 3, W5 | FR-17-006; UC-17-05 |

: Story của epic EP-17-A Bật tắt và chính sách AI theo tenant

#### EP-17-B · Cổng mô hình và sổ mô hình

Epic gồm 8 story, 32 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-007 | Là quản trị nền tảng, tôi muốn khai báo nhà cung cấp mô hình, để sổ nhà cung cấp có loại, vùng lưu dữ liệu, cam kết và hạn; không ai nhìn thấy giá trị bí mật. | M | 5 | Đợt 3, W5 | FR-17-007; UC-17-06 |
| US-17-008 | Là quản trị nền tảng, tôi muốn khai báo mô hình và phiên bản, để có sổ mô hình theo nhà cung cấp, loại, phiên bản; chưa gọi được cho tới khi duyệt. | M | 3 | Đợt 3, W5 | FR-17-008; UC-17-07 |
| US-17-009 | Là quản trị nền tảng, tôi muốn có vòng đời phiên bản mô hình, duyệt bốn mắt, để phiên bản có hồ sơ đánh giá và người duyệt; chỉ phiên bản `APPROVED` mới được chọn làm mặc định hoặc dự phòng. | M | 5 | Đợt 3, W5 | FR-17-009; UC-17-07 |
| US-17-010 | Là quản trị tỉnh, tôi muốn hệ thống định tuyến lời gọi tới mô hình theo năng lực và chính sách tenant, để mỗi lời gọi tới đúng mô hình tỉnh đã duyệt; quản trị thấy mô hình nào đang chạy, lúc nào có dự phòng. | M | 5 | Đợt 3, W5 | FR-17-010; UC-17-08, 17-09 |
| US-17-011 | Là quản trị nền tảng, tôi muốn đồng bộ cấu hình tuyến egress APISIX ai-proxy qua PH-03, để quản trị thấy tuyến nào đã áp, tuyến nào chờ hoặc lệch. | M | 5 | Đợt 3, W5 | FR-17-011; UC-17-10 |
| US-17-012 | Là quản trị nền tảng, tôi muốn hệ thống giới hạn tần suất và bảo vệ tải ở cổng mô hình, cầu dao, để khi mô hình lỗi, người dùng nhận thông báo rõ thay vì chờ lâu; quản trị thấy cầu dao nào đang mở. | M | 3 | Đợt 3, W5 | FR-17-012; UC-17-11 |
| US-17-013 | Là quản trị nền tảng, tôi muốn hệ thống ghi vết mỗi lời gọi mô hình, không lưu nội dung thô, để có số liệu đo độ trễ, token, tỷ lệ lỗi theo mô hình; không có nội dung nhạy cảm. | M | 3 | Đợt 3, W5 | FR-17-013; UC-17-11 |
| US-17-014 | Là quản trị nền tảng, tôi muốn hệ thống kiểm tra sức khỏe và trạng thái mô hình, để quản trị và vận hành thấy dấu hiệu sức khỏe từng mô hình; người dùng thấy thông báo rõ khi mô hình ngừng. | S | 3 | Đợt 3, W5 | FR-17-014; UC-17-11 |

: Story của epic EP-17-B Cổng mô hình và sổ mô hình

#### EP-17-C · Kho tri thức và lập chỉ mục

Epic gồm 7 story, 22 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-015 | Là quản trị tỉnh, tôi muốn khai báo nguồn tri thức, để quản trị thấy danh sách nguồn kèm trạng thái và số tài liệu; trợ lý chỉ dùng nội dung của các nguồn này. | M | 3 | Đợt 3, W5 | FR-17-015; UC-17-12 |
| US-17-016 | Là quản trị tỉnh, tôi muốn hệ thống kiểm mức phân loại trước khi lập chỉ mục, để quản trị có danh sách đối tượng không vào chỉ mục và lý do; không có dữ liệu mức cao trong vector. | M | 3 | Đợt 3, W5 | FR-17-016; UC-17-12 |
| US-17-017 | Là quản trị tỉnh, tôi muốn hệ thống lập chỉ mục theo sự kiện và lập lại toàn bộ theo lịch, để chỉ mục tươi: p95 ≤ 120 giây từ sự kiện nguồn (NFR-17-010); quản trị theo dõi tiến độ. | M | 3 | Đợt 3, W5 | FR-17-017; UC-17-13 |
| US-17-018 | Là quản trị tỉnh, tôi muốn hệ thống cắt đoạn, nhúng, lưu vector có tenant_id và phạm vi quyền đọc, để mỗi đoạn truy hồi được, có quyền đi kèm, không lẫn tenant. | M | 3 | Đợt 3, W5 | FR-17-018; UC-17-13 |
| US-17-019 | Là quản trị tỉnh, tôi muốn hệ thống xóa lan truyền khi nguồn bị xóa, thu hồi, đổi mức phân loại, để người dùng không còn nhận trích dẫn tới đối tượng đã thu hồi; SO có nhật ký xóa để chứng minh. | M | 3 | Đợt 3, W5 | FR-17-019; UC-17-14 |
| US-17-020 | Là cán bộ quản lý dữ liệu, tôi muốn tải lên tài liệu hướng dẫn nội bộ làm nguồn tri thức, có duyệt, để tỉnh có hướng dẫn riêng trong tri thức của trợ lý, có người chịu trách nhiệm duyệt. | S | 5 | Đợt 3, W5 | FR-17-020; UC-17-15 |
| US-17-021 | Là quản trị tỉnh, tôi muốn theo dõi trạng thái chỉ mục, để quản trị thấy một bảng sức khỏe chỉ mục, bấm vào lỗi để xử lý. | S | 2 | Đợt 3, W5 | FR-17-021; UC-17-13 |

: Story của epic EP-17-C Kho tri thức và lập chỉ mục

#### EP-17-D · Hội thoại và tìm dịch vụ

Epic gồm 8 story, 23 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-022 | Là người dùng, tôi muốn mở bảng bên trợ lý, phiên hội thoại, ngữ cảnh màn hình, để bảng bên mở đúng ngữ cảnh, kèm nhãn "Nội dung do AI tạo, cần kiểm tra lại" ở chân bảng. | M | 3 | Đợt 3, W5 | FR-17-022; UC-17-16 |
| US-17-023 | Là người dùng, tôi muốn hỏi đáp tìm dịch vụ bằng ngôn ngữ tự nhiên, truy hồi lai, để người dùng nhận câu trả lời ngắn gọn kèm danh sách API, topic, danh mục liên quan và liên kết mở thẳng màn đối tượng. | M | 5 | Đợt 3, W5 | FR-17-023; UC-17-17 |
| US-17-024 | Là kỹ sư tích hợp, tôi muốn hệ thống lọc kết quả theo quyền của người hỏi, để hai người dùng khác quyền hỏi cùng một câu có thể nhận câu trả lời khác nhau, mỗi người chỉ thấy phần mình được phép. | M | 2 | Đợt 3, W5 | FR-17-024; UC-17-17 |
| US-17-025 | Là kỹ sư tích hợp, tôi muốn hệ thống trích dẫn nguồn, liên kết tới màn đối tượng, nói "không tìm thấy" thay vì bịa, để người dùng bấm trích dẫn mở thẳng màn API, topic, danh mục; khi không có thông tin được nói rõ. | M | 3 | Đợt 3, W5 | FR-17-025; UC-17-17 |
| US-17-026 | Là người dùng, tôi muốn phát trực tuyến câu trả lời (SSE), hủy giữa chừng, để người dùng thấy chữ hiện ra trong vài giây và dừng được bất kỳ lúc nào. | S | 3 | Đợt 3, W5 | FR-17-026; UC-17-17 |
| US-17-027 | Là người dùng, tôi muốn có lịch sử hội thoại của tôi, xóa hội thoại, hết hạn, để người dùng tự quản lý lịch sử; không ai khác đọc được. | M | 3 | Đợt 3, W5 | FR-17-027; UC-17-18 |
| US-17-028 | Là quản trị tỉnh, tôi muốn gợi ý câu hỏi theo màn và theo vai trò, để người dùng có điểm bắt đầu khi hỏi. | C | 2 | Đợt 3, W5 | FR-17-028; UC-17-16 |
| US-17-029 | Là người dùng, tôi muốn hỏi từ CommandPalette, để bảng bên mở sẵn câu hỏi, người dùng chỉ cần xác nhận gửi. | S | 2 | Đợt 3, W5 | FR-17-029; UC-17-16 |

: Story của epic EP-17-D Hội thoại và tìm dịch vụ

#### EP-17-E · Gợi ý ánh xạ dữ liệu

Epic gồm 6 story, 21 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-030 | Là kỹ sư tích hợp, tôi muốn gợi ý ánh xạ trường nguồn sang đích, sinh biểu thức JQ đề xuất, để kỹ sư nhận danh sách ánh xạ đề xuất, mỗi dòng có biểu thức, điểm và lý do, sẵn sàng xem trước. | M | 5 | Đợt 3, W5 | FR-17-030; UC-17-19 |
| US-17-031 | Là cán bộ quản lý dữ liệu, tôi muốn gợi ý ánh xạ mã danh mục cục bộ sang danh mục chuẩn PH-07, để người dùng nhận bảng ghép mã đề xuất để xem và áp dụng. | S | 3 | Đợt 3, W5 | FR-17-031; UC-17-19 |
| US-17-032 | Là người dùng, tôi muốn điểm tin cậy và giải thích lý do cho từng gợi ý, để mỗi gợi ý có điểm, nhãn mức tin cậy và lý do đọc được. | M | 2 | Đợt 3, W5 | FR-17-032; UC-17-19 |
| US-17-033 | Là người dùng, tôi muốn áp dụng gợi ý qua thẻ đề xuất, ghi bản nháp bằng quyền người dùng, để bản nháp ở phân hệ chủ có thay đổi, người dùng thấy ngay và tiếp tục chỉnh, duyệt theo quy trình của phân hệ đó. | M | 5 | Đợt 3, W5 | FR-17-033; UC-17-20 |
| US-17-034 | Là kỹ sư tích hợp, tôi muốn hệ thống không đưa giá trị dữ liệu thật vào prompt, chỉ lược đồ và mẫu đã che, để người dùng không phải lo dữ liệu thật bị gửi tới mô hình. | M | 3 | Đợt 3, W5 | FR-17-034; UC-17-19 |
| US-17-035 | Là người dùng, tôi muốn ghi nhận chấp nhận, sửa, từ chối gợi ý để đo chất lượng, để quản trị thấy tỷ lệ chấp nhận gợi ý trong bảng chất lượng (UI-17-13). | S | 3 | Đợt 3, W5 | FR-17-035; UC-17-20 |

: Story của epic EP-17-E Gợi ý ánh xạ dữ liệu

#### EP-17-F · Giải thích sự cố

Epic gồm 6 story, 16 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-036 | Là người dùng, tôi muốn giải thích mã lỗi (ERR) đang hiển thị, để người dùng đọc được nguyên nhân và cách xử lý ngay trong bảng bên. | M | 3 | Đợt 3, W5 | FR-17-036; UC-17-21 |
| US-17-037 | Là vận hành tỉnh, tôi muốn giải thích lỗi theo trace_id, tổng hợp log và vết bằng quyền người dùng, để người vận hành nhận bản tóm tắt nguyên nhân khả dĩ và đường đi của lỗi. | M | 3 | Đợt 3, W5 | FR-17-037; UC-17-22 |
| US-17-038 | Là vận hành tỉnh, tôi muốn giải thích bản tin DLQ PH-18 và đề xuất hướng xử lý, để người vận hành biết nguyên nhân và hướng xử lý đề xuất cho bản tin. | S | 3 | Đợt 3, W5 | FR-17-038; UC-17-22 |
| US-17-039 | Là người dùng, tôi muốn gợi ý bước khắc phục dạng danh sách kiểm, không tự thực hiện, để người vận hành có danh sách việc cần làm, rõ việc nào chỉ xem, việc nào cần họ tự thao tác. | M | 3 | Đợt 3, W5 | FR-17-039; UC-17-23 |
| US-17-040 | Là vận hành tỉnh, tôi muốn tóm tắt sự cố cho báo cáo, để người dùng có bản nháp tóm tắt sự cố để chỉnh và đưa vào báo cáo. | S | 2 | Đợt 3, W5 | FR-17-040; UC-17-23 |
| US-17-041 | Là kỹ sư tích hợp, tôi muốn hệ thống che dữ liệu cá nhân trong log trước khi đưa vào prompt, để người dùng thấy nội dung đã che trước khi gửi, an tâm không lộ DLCN. | M | 2 | Đợt 3, W5 | FR-17-041; UC-17-22 |

: Story của epic EP-17-F Giải thích sự cố

#### EP-17-G · Công cụ và an toàn

Epic gồm 7 story, 22 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-042 | Là quản trị tỉnh, tôi muốn danh mục công cụ chỉ đọc, bật tắt theo tenant, để tỉnh biết rõ trợ lý được gọi những công cụ nào và đã bật những công cụ nào. | M | 3 | Đợt 3, W5 | FR-17-042; UC-17-24 |
| US-17-043 | Là kỹ sư tích hợp, tôi muốn hệ thống chạy công cụ bằng token người dùng, không quyền riêng, để hai người cùng hỏi, mỗi người chỉ nhận kết quả công cụ trong quyền của mình. | M | 5 | Đợt 3, W5 | FR-17-043; UC-17-25 |
| US-17-044 | Là kỹ sư tích hợp, tôi muốn hệ thống bọc nội dung truy hồi như dữ liệu không tin cậy, tách kênh chỉ dẫn, để mô tả API chứa "bỏ qua mọi chỉ dẫn" không làm đổi hành vi trợ lý. | M | 3 | Đợt 3, W5 | FR-17-044; UC-17-26 |
| US-17-045 | Là cán bộ ATTT, tôi muốn hệ thống có bộ lọc đầu vào: tiêm lệnh, nội dung cấm, DLCN tự dán, để câu hỏi độc hại bị chặn với thông báo rõ; DLCN không vào nhật ký và mô hình. | M | 3 | Đợt 3, W5 | FR-17-045; UC-17-26 |
| US-17-046 | Là cán bộ ATTT, tôi muốn hệ thống có bộ lọc đầu ra: che mẫu DLCN, chặn bí mật, chặn liên kết ngoài, để người dùng không bao giờ thấy bí mật hay liên kết ngoài trong câu trả lời. | M | 3 | Đợt 3, W5 | FR-17-046; UC-17-27 |
| US-17-047 | Là cán bộ ATTT, tôi muốn hệ thống giới hạn số lần gọi công cụ mỗi lượt, thời gian chờ, độ sâu, để lượt không chạy vô hạn; người dùng nhận kết quả một phần kèm giải thích khi chạm giới hạn. | M | 3 | Đợt 3, W5 | FR-17-047; UC-17-24 |
| US-17-048 | Là kỹ sư tích hợp, tôi muốn hệ thống có nhãn "Nội dung do AI tạo" và không có hành động ghi tự động, để người dùng luôn thấy nhãn; không có thay đổi nào âm thầm. | M | 2 | Đợt 3, W5 | FR-17-048; UC-17-27 |

: Story của epic EP-17-G Công cụ và an toàn

#### EP-17-H · Quản trị AI, đánh giá và chất lượng

Epic gồm 6 story, 22 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-049 | Là quản trị tỉnh, tôi muốn quản lý mẫu chỉ dẫn hệ thống có phiên bản, duyệt bốn mắt, để mọi thay đổi chỉ dẫn hệ thống có lịch sử, người duyệt và bằng chứng đánh giá. | M | 5 | Đợt 3, W5 | FR-17-049; UC-17-28 |
| US-17-050 | Là quản trị tỉnh, tôi muốn có bộ đánh giá chuẩn theo năng lực, chạy khi đổi mô hình hoặc prompt, để có điểm đo được trước và sau mỗi thay đổi; quản trị xem được ca nào sai. | M | 5 | Đợt 3, W5 | FR-17-050; UC-17-29 |
| US-17-051 | Là cán bộ ATTT, tôi muốn có bộ ca đỏ tiêm lệnh, cổng phát hành chặn khi có ca lọt, để có bằng chứng định lượng về an toàn trước mỗi lần phát hành; ca lọt không thể bị bỏ qua. | M | 3 | Đợt 3, W5 | FR-17-051; UC-17-29 |
| US-17-052 | Là quản trị tỉnh, tôi muốn phản hồi của người dùng và hàng xử lý phản hồi, để người dùng thấy "Cảm ơn phản hồi"; quản trị có hàng xử lý theo hạn. | M | 3 | Đợt 3, W5 | FR-17-052; UC-17-30 |
| US-17-053 | Là quản trị tỉnh, tôi muốn có chỉ số chất lượng và cảnh báo suy giảm, để quản trị có bảng chất lượng và cảnh báo khi trợ lý kém đi. | S | 3 | Đợt 3, W5 | FR-17-053; UC-17-30 |
| US-17-054 | Là quản trị tỉnh, tôi muốn có sổ đăng ký hệ thống AI của tenant, để tỉnh có hồ sơ hệ thống AI luôn khớp cấu hình thật. | S | 3 | Đợt 3, W5 | FR-17-054; UC-17-31 |

: Story của epic EP-17-H Quản trị AI, đánh giá và chất lượng

#### EP-17-I · Nhật ký, kiểm toán, báo cáo, cấu hình

Epic gồm 5 story, 21 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-055 | Là kỹ sư tích hợp, tôi muốn hệ thống có nhật ký hội thoại đã che, lưu 90 ngày, để mọi lượt có hồ sơ đã che, tự xóa đúng hạn. | M | 3 | Đợt 3, W5 | FR-17-055; UC-17-32 |
| US-17-056 | Là cán bộ ATTT, tôi muốn tra cứu nhật ký cho SO, AUDITOR có lý do truy cập, để người điều tra xem được đúng hội thoại cần xem, mọi lần xem đều có lý do. | M | 5 | Đợt 3, W5 | FR-17-056; UC-17-32 |
| US-17-057 | Là cán bộ ATTT, tôi muốn xuất bằng chứng tuân thủ, để thanh tra có gói chứng minh có chữ ký, không cần truy cập hệ thống. | S | 5 | Đợt 3, W5 | FR-17-057; UC-17-33 |
| US-17-058 | Là quản trị tỉnh, tôi muốn có báo cáo sử dụng, để lãnh đạo thấy mức sử dụng và chi phí ước tính; PH-16 có số liệu. | S | 3 | Đợt 3, W5 | FR-17-058; UC-17-33 |
| US-17-059 | Là quản trị tỉnh, tôi muốn có tham số 17.* và giá trị mặc định, để mọi cấu hình rõ ràng, đổi có kiểm soát. | M | 5 | Đợt 3, W5 | FR-17-059; UC-17-02 |

: Story của epic EP-17-I Nhật ký, kiểm toán, báo cáo, cấu hình

#### EP-17-J · Dịch vụ AI cho phân hệ khác

Epic gồm 3 story, 11 điểm (0 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-17-060 | Là kỹ sư tích hợp, tôi muốn hệ thống API suy luận nội bộ cho bước luồng PH-04, để luồng PH-04 có bước AI chạy trong kiểm soát, đo được và tắt được. | S | 3 | Đợt 3, W5 | FR-17-060; UC-17-34 |
| US-17-061 | Là kỹ sư tích hợp, tôi muốn hệ thống gợi ý cho bước quy trình PH-11, luôn có người quyết định cuối, để người xử lý hồ sơ nhận gợi ý rõ lý do, tự quyết định. | C | 5 | Đợt 3, W5 | FR-17-061; UC-17-35 |
| US-17-062 | Là quản trị tỉnh, tôi muốn dùng tập dữ liệu đã ẩn danh PH-09 cho đánh giá, để đánh giá dùng dữ liệu ẩn danh hợp pháp và truy vết được. | C | 3 | Đợt 3, W5 | FR-17-062; UC-17-36 |

: Story của epic EP-17-J Dịch vụ AI cho phân hệ khác

### 6.19. PH-18 · Vận hành và xử lý lỗi

Phân hệ có 10 epic, 72 story, tổng 202 điểm; wave phát triển W2, đợt MVP. Nguồn: D02-03-PH18 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-18-A · Kho tham số và cờ tính năng

Epic gồm 11 story, 33 điểm (9 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-001 | Là quản trị nền tảng, tôi muốn hệ thống đăng ký không gian tên và lược đồ khóa tham số, để phân hệ thấy khóa của mình trên màn tham số chung ngay sau khi khởi động; PA thấy số khóa theo không gian tên. | M | 3 | MVP, W2 | FR-18-001; UC-18-01 |
| US-18-002 | Là vận hành tỉnh, tôi muốn hệ thống đọc tham số có bộ đệm cho phân hệ khác, để phân hệ dùng giá trị mới nhất trong ≤ 60 giây mà không phải khởi động lại. | M | 2 | MVP, W2 | FR-18-002; UC-18-01 |
| US-18-003 | Là quản trị tỉnh, tôi muốn ghi giá trị tham số theo tenant có kiểm miền, trần và lý do, để quản trị tỉnh thấy giá trị mới và phiên bản mới trong lịch sử; phân hệ chủ dùng giá trị mới trong ≤ 60 giây. | M | 3 | MVP, W2 | FR-18-003; UC-18-02 |
| US-18-004 | Là quản trị tỉnh, tôi muốn duyệt bốn mắt tham số bảo mật ★, để người đề nghị thấy trạng thái "Chờ duyệt" trên khóa; người duyệt có việc trong Việc của tôi; sau duyệt, giá trị mới có hiệu lực. | M | 5 | MVP, W2 | FR-18-004; UC-18-03 |
| US-18-005 | Là quản trị tỉnh, tôi muốn xem lịch sử, so sánh và khôi phục phiên bản tham số, để người quản trị thấy rõ ai đổi gì, so sánh được và khôi phục bằng một thao tác có lý do. | M | 3 | MVP, W2 | FR-18-005; UC-18-04 |
| US-18-006 | Là vận hành tỉnh, tôi muốn hệ thống phát sự kiện đổi tham số và làm mới bộ đệm, để người quản trị thấy giá trị mới được áp ở các phân hệ trong ≤ 60 giây; UI-18-08 hiển thị "Đã áp dụng" khi chỉ số đệm của mọi DU báo phiên bản mới. | M | 2 | MVP, W2 | FR-18-006; UC-18-01 |
| US-18-007 | Là người dùng, tôi muốn có màn tham số chung nhúng theo không gian tên và nhóm, để người quản trị chỉnh tham số của mọi phân hệ ở cùng một kiểu màn, thấy ngay giới hạn được phép. | M | 3 | MVP, W2 | FR-18-007; UC-18-02 |
| US-18-008 | Là quản trị nền tảng, tôi muốn xuất, nhập gói tham số giữa môi trường, để PA có báo cáo khác biệt rõ ràng trước khi áp và một lần áp có kiểm toán. | C | 3 | MVP, W2 | FR-18-008; UC-18-05 |
| US-18-009 | Là quản trị nền tảng, tôi muốn quản lý cờ tính năng theo tenant, để quản trị tỉnh thấy danh sách cờ có mô tả, bật được tính năng thử nghiệm cho tỉnh mình; chủ sở hữu được nhắc gỡ cờ đúng hạn. | M | 3 | MVP, W2 | FR-18-009; UC-18-06 |
| US-18-010 | Là quản trị tỉnh, tôi muốn quản lý danh sách egress cho phép theo tenant, để quản trị tỉnh kiểm soát được các đích mà nền tảng gọi ra thay mặt tỉnh, có hạn dùng và lý do. | S | 3 | Đợt 2, W4 | FR-18-010; UC-18-06 |
| US-18-011 | Là vận hành tỉnh, tôi muốn hệ thống ghi tham số mặc định khi khởi tạo tenant, để quản trị tỉnh mới mở màn tham số thấy đủ giá trị mặc định theo hồ sơ tỉnh. | M | 3 | MVP, W2 | FR-18-011; UC-18-07 |

: Story của epic EP-18-A Kho tham số và cờ tính năng

#### EP-18-B · Tiếp nhận DLQ

Epic gồm 7 story, 18 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-012 | Là quản trị nền tảng, tôi muốn hệ thống đăng ký nguồn DLQ và cổng phát lại, để người vận hành thấy danh sách nguồn, cách phát lại và trạng thái, biết mục nào phát lại được. | M | 2 | MVP, W2 | FR-18-012; UC-18-08 |
| US-18-013 | Là vận hành tỉnh, tôi muốn hệ thống tiêu thụ topic DLQ và lập chỉ mục bền, để người vận hành thấy mục lỗi mới trên UI-18-01 trong ≤ 5 giây sau khi runtime ghi. | M | 5 | MVP, W2 | FR-18-013; UC-18-09 |
| US-18-014 | Là vận hành tỉnh, tôi muốn hệ thống nhận mục DLQ qua API ghi cho phân hệ khác, để bản tin lỗi của phân hệ nguồn hiện trên màn DLQ chung cùng các mục từ runtime. | M | 3 | MVP, W2 | FR-18-014; UC-18-10 |
| US-18-015 | Là vận hành tỉnh, tôi muốn hệ thống kiểm hợp đồng ngữ cảnh và đánh dấu POISON, để người vận hành thấy ngay mục nào không thể phát lại và vì sao. | M | 2 | MVP, W2 | FR-18-015; UC-18-09, 18-10 |
| US-18-016 | Là vận hành tỉnh, tôi muốn hệ thống lưu payload lớn ở Garage và khử trùng theo khóa DLQ, để danh sách DLQ hiển thị nhanh; lỗi lặp lại thấy ở cột "Số lần gặp" thay vì hàng nghìn dòng giống nhau. | M | 2 | MVP, W2 | FR-18-016; UC-18-09, 18-10 |
| US-18-017 | Là vận hành tỉnh, tôi muốn liên thông DLQ tầng sự kiện của PH-10, để người vận hành không phải chuyển giữa hai màn để biết tổng số bản tin lỗi của tỉnh. | M | 2 | MVP, W2 | FR-18-017; UC-18-11 |
| US-18-018 | Là vận hành tỉnh, tôi muốn hệ thống đối soát chỉ mục DLQ với Kafka, để người vận hành có báo cáo đối soát hằng ngày; mục bị sót được nạp lại tự động. | S | 2 | MVP, W2 | FR-18-018; UC-18-09 |

: Story của epic EP-18-B Tiếp nhận DLQ

#### EP-18-C · Phân loại và xử lý

Epic gồm 8 story, 21 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-019 | Là vận hành tỉnh, tôi muốn liệt kê, lọc và tìm mục DLQ, để người vận hành thấy ngay số mục chưa xử lý, mục cũ nhất và mục ưu tiên cao. | M | 2 | MVP, W2 | FR-18-019; UC-18-12 |
| US-18-020 | Là vận hành tỉnh, tôi muốn gom nhóm mục DLQ theo dấu hiệu lỗi, để người vận hành thấy "1 nhóm, 3.200 mục, cùng lỗi đích không phản hồi" và xử lý bằng một lượt. | C | 2 | MVP, W2 | FR-18-020; UC-18-12 |
| US-18-021 | Là vận hành tỉnh, tôi muốn xem chi tiết mục DLQ và ngữ cảnh chẩn đoán, để người vận hành đọc được nguyên nhân và hướng xử lý trên một màn, không phải mở công cụ log riêng. | M | 2 | MVP, W2 | FR-18-021; UC-18-13 |
| US-18-022 | Là vận hành tỉnh, tôi muốn xem payload có lý do, để người vận hành xem được nội dung cần cho chẩn đoán; dữ liệu Nhạy cảm không bao giờ hiện rõ ở PH-18. | M | 2 | MVP, W2 | FR-18-022; UC-18-13 |
| US-18-023 | Là vận hành tỉnh, tôi muốn phân loại, ưu tiên và gán người xử lý, để hàng đợi có người lo cho từng mục; người được gán thấy việc trong Việc của tôi. | M | 3 | MVP, W2 | FR-18-023; UC-18-12 |
| US-18-024 | Là vận hành tỉnh, tôi muốn sửa payload có kiểm soát, để người vận hành sửa được bản tin sai và phát lại; bản gốc vẫn xem được để so sánh. | M | 5 | MVP, W2 | FR-18-024; UC-18-14 |
| US-18-025 | Là quản trị nền tảng, tôi muốn quản lý sổ tay xử lý theo mã lỗi, để người vận hành thấy hướng dẫn ngay trên chi tiết mục lỗi; trợ lý AI trả lời theo cùng hướng dẫn. | S | 3 | MVP, W2 | FR-18-025; UC-18-15 |
| US-18-026 | Là vận hành tỉnh, tôi muốn hệ thống cung cấp API đọc DLQ cho PH-17 và PH-13, để người dùng hỏi trợ lý về một bản tin lỗi nhận câu trả lời dựa trên đúng dữ liệu mà chính họ được xem. | S | 2 | Đợt 2, W4 | FR-18-026; UC-18-15 |

: Story của epic EP-18-C Phân loại và xử lý

#### EP-18-D · Phát lại, bỏ qua và lưu giữ

Epic gồm 8 story, 23 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-027 | Là vận hành tỉnh, tôi muốn phát lại một mục DLQ, để người vận hành thấy trạng thái "Đang phát lại" và kết quả trong vài giây đến vài phút. | M | 3 | MVP, W2 | FR-18-027; UC-18-16 |
| US-18-028 | Là vận hành tỉnh, tôi muốn phát lại loạt theo bộ lọc hoặc danh sách, để người vận hành thấy lượt với số mục, tốc độ dự kiến, thời gian ước tính và người duyệt. | M | 5 | MVP, W2 | FR-18-028; UC-18-17 |
| US-18-029 | Là vận hành tỉnh, tôi muốn điều khiển lượt phát lại: tốc độ, tạm dừng, tiếp tục, hủy, để người vận hành theo dõi thanh tiến độ, dừng ngay khi đích lại lỗi. | M | 3 | MVP, W2 | FR-18-029; UC-18-17 |
| US-18-030 | Là vận hành tỉnh, tôi muốn hệ thống nhận kết quả phát lại và bảo đảm lũy đẳng, để người vận hành thấy mục chuyển "Đã xử lý" hoặc "Phát lại lỗi" kèm mã lỗi mới; lượt cập nhật tiến độ. | M | 3 | MVP, W2 | FR-18-030; UC-18-16, 18-17 |
| US-18-031 | Là vận hành tỉnh, tôi muốn bỏ qua mục DLQ có lý do, để mục rời hàng chưa xử lý; lý do hiện trên chi tiết mục. | M | 3 | MVP, W2 | FR-18-031; UC-18-18 |
| US-18-032 | Là vận hành tỉnh, tôi muốn mở lại mục đã bỏ qua, để mục trở lại hàng cần xử lý. | S | 2 | MVP, W2 | FR-18-032; UC-18-18 |
| US-18-033 | Là vận hành tỉnh, tôi muốn hệ thống lưu giữ và dọn mục DLQ, để nội dung bản tin lỗi không bị giữ lâu hơn cần thiết. | M | 2 | MVP, W2 | FR-18-033; UC-18-19 |
| US-18-034 | Là người xem, tôi muốn thống kê DLQ, chỉ số và sự kiện vượt ngưỡng, để người vận hành biết DLQ đang tăng hay giảm; PH-13 cảnh báo người trực khi vượt ngưỡng. | M | 2 | MVP, W2 | FR-18-034; UC-18-19 |

: Story của epic EP-18-D Phát lại, bỏ qua và lưu giữ

#### EP-18-E · Thông báo

Epic gồm 7 story, 21 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-035 | Là quản trị tỉnh, tôi muốn quản lý mẫu thông báo có phiên bản và kiểm trường cấm, để tỉnh có bộ mẫu được duyệt, xem trước được; người nhận chỉ nhận liên kết tới hệ thống. | M | 5 | MVP, W2 | FR-18-035; UC-18-20 |
| US-18-036 | Là vận hành tỉnh, tôi muốn hệ thống gửi thông báo qua NotificationApi, để người nhận nhận thư hoặc SMS chỉ có liên kết, hoặc thấy chấm đỏ trên biểu tượng chuông. | M | 5 | MVP, W2 | FR-18-036; UC-18-21 |
| US-18-037 | Là vận hành tỉnh, tôi muốn hệ thống phân giải người nhận từ tham chiếu, để phân hệ gửi đúng người mà không biết địa chỉ; đầu mối đổi ở PH-01 có hiệu lực ngay ở lần gửi sau (≤ 5 phút). | M | 2 | MVP, W2 | FR-18-037; UC-18-21 |
| US-18-038 | Là người dùng, tôi muốn quản lý tùy chọn nhận thông báo và giờ yên lặng, để người dùng không bị làm phiền ngoài giờ bởi thông báo thường, vẫn nhận thông báo bắt buộc. | M | 2 | MVP, W2 | FR-18-038; UC-18-22 |
| US-18-039 | Là quản trị tỉnh, tôi muốn có cấu hình quy tắc thông báo theo sự kiện, để tỉnh tự bật thông báo cho các sự kiện của mọi phân hệ, ví dụ báo đầu mối khi đăng ký API bị từ chối. | M | 2 | MVP, W2 | FR-18-039; UC-18-23 |
| US-18-040 | Là quản trị tỉnh, tôi muốn hệ thống thử lại, xử lý thư trả lại và danh sách chặn, để thông báo đến được khi lỗi tạm thời; đầu mối hỏng được PH-01 biết để sửa. | M | 3 | MVP, W2 | FR-18-040; UC-18-24 |
| US-18-041 | Là quản trị tỉnh, tôi muốn tra cứu nhật ký gửi thông báo và kênh cho PH-13, để người quản trị trả lời được "thư đã gửi lúc nào, đến hay bị trả lại". | S | 2 | MVP, W2 | FR-18-041; UC-18-24 |

: Story của epic EP-18-E Thông báo

#### EP-18-F · Việc của tôi và lịch

Epic gồm 5 story, 14 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-042 | Là vận hành tỉnh, tôi muốn hệ thống đăng ký loại việc của phân hệ, để việc của mọi phân hệ hiện cùng kiểu trong hộp việc. | M | 2 | MVP, W2 | FR-18-042; UC-18-25 |
| US-18-043 | Là vận hành tỉnh, tôi muốn hệ thống tạo, cập nhật và đóng việc lũy đẳng, để người nhận thấy việc mới trong ≤ 10 giây; việc tự biến mất khi phân hệ nguồn đóng. | M | 3 | MVP, W2 | FR-18-043; UC-18-25 |
| US-18-044 | Là người dùng, tôi muốn hiển thị Việc của tôi, nhắc và quá hạn, để người dùng biết hôm nay phải làm gì mà không cần mở từng phân hệ. | M | 3 | MVP, W2 | FR-18-044; UC-18-26 |
| US-18-045 | Là quản trị tỉnh, tôi muốn quản lý lịch ngày làm việc và tính hạn cho phân hệ khác, để hạn thẩm định ở PH-01, nhắc đăng ký ở PH-02 tính đúng ngày nghỉ lễ của tỉnh. | M | 3 | MVP, W2 | FR-18-045; UC-18-27 |
| US-18-046 | Là quản trị nền tảng, tôi muốn quản lý cửa sổ bảo trì và đóng băng thay đổi, để người dùng được báo trước giờ bảo trì; kỹ sư không phát hành được luồng lên PROD trong đóng băng. | M | 3 | MVP, W2 | FR-18-046; UC-18-27 |

: Story của epic EP-18-F Việc của tôi và lịch

#### EP-18-G · Sự cố vận hành

Epic gồm 5 story, 13 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-047 | Là vận hành tỉnh, tôi muốn hệ thống mở hồ sơ sự cố từ sự kiện, để người trực nhận thư hoặc SMS có liên kết tới hồ sơ sự cố trong ≤ 30 giây sau tín hiệu `SEV1`. | M | 3 | MVP, W2 | FR-18-047; UC-18-28 |
| US-18-048 | Là vận hành tỉnh, tôi muốn tạo tay, phân mức và gán người xử lý sự cố, để sự cố có chủ, có mức, có thời gian phản ứng đo được. | M | 2 | MVP, W2 | FR-18-048; UC-18-28 |
| US-18-049 | Là vận hành tỉnh, tôi muốn ghi mốc thời gian và liên kết sự cố, để hồ sơ sự cố có dòng thời gian đủ để lập báo cáo theo mẫu của PH-13. | S | 2 | MVP, W2 | FR-18-049; UC-18-28 |
| US-18-050 | Là cán bộ ATTT, tôi muốn chuyển sự cố có dữ liệu cá nhân sang PH-09, để cán bộ ATTT thấy mã hồ sơ PH-09 trên sự cố và biết đồng hồ 72 giờ đã chạy ở PH-09. | S | 3 | Đợt 2, W4 | FR-18-050; UC-18-29 |
| US-18-051 | Là quản trị tỉnh, tôi muốn đóng sự cố có nguyên nhân gốc và bài học, để hồ sơ sự cố hoàn chỉnh, có việc khắc phục được theo dõi trong Việc của tôi. | M | 3 | MVP, W2 | FR-18-051; UC-18-28 |

: Story của epic EP-18-G Sự cố vận hành

#### EP-18-H · Sao lưu và khôi phục

Epic gồm 7 story, 22 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-052 | Là quản trị nền tảng, tôi muốn theo dõi sao lưu theo đối tượng và cảnh báo lỗi, để bảng điều khiển trả lời ngay "đêm qua sao lưu có chạy không, khôi phục thử có đạt không". | M | 3 | MVP, W2 | FR-18-052; UC-18-30 |
| US-18-053 | Là quản trị nền tảng, tôi muốn ghi nhận kết quả kiểm tra khôi phục tự động, để PA có bằng chứng định kỳ rằng khôi phục được, dùng cho hồ sơ cấp độ 3. | M | 2 | MVP, W2 | FR-18-053; UC-18-30 |
| US-18-054 | Là quản trị tỉnh, tôi muốn tạo yêu cầu khôi phục một tenant, để TA thấy yêu cầu chờ PA duyệt, kèm ước tính thời gian và tác động. | M | 5 | MVP, W2 | FR-18-054; UC-18-31 |
| US-18-055 | Là quản trị nền tảng, tôi muốn duyệt và chạy khôi phục tenant tám bước, để tỉnh có dữ liệu về đúng thời điểm đích trong ≤ 4 giờ (tenant ≤ 200 GB), các tỉnh khác không bị ảnh hưởng. | M | 5 | MVP, W2 | FR-18-055; UC-18-31 |
| US-18-056 | Là quản trị nền tảng, tôi muốn xuất dữ liệu tenant, để tỉnh nhận gói dữ liệu đầy đủ, có kê khai để tự kiểm. | M | 3 | MVP, W2 | FR-18-056; UC-18-32 |
| US-18-057 | Là quản trị nền tảng, tôi muốn hệ thống chuyển dữ liệu phân hệ khi sáp nhập tenant, để PH-20 có tiến độ chuyển từng phân hệ trên màn sáp nhập; dữ liệu tỉnh nguồn xuất hiện ở tỉnh đích với nguồn gốc rõ. | S | 3 | Đợt 2, W4 | FR-18-057; UC-18-33 |
| US-18-058 | Là quản trị nền tảng, tôi muốn ghi nhận diễn tập DR và PITR toàn cụm, để PA có danh sách diễn tập theo quý với RTO, RPO thật để báo cáo. | C | 1 | MVP, W2 | FR-18-058; UC-18-30 |

: Story của epic EP-18-H Sao lưu và khôi phục

#### EP-18-I · Di trú hệ cũ và chạy song song

Epic gồm 10 story, 28 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-059 | Là quản trị nền tảng, tôi muốn khai báo nguồn hệ cũ, để đội di trú có nguồn đã kiểm chỉ đọc, không ai nhìn thấy mật khẩu. | M | 3 | MVP, W2 | FR-18-059; UC-18-34 |
| US-18-060 | Là quản trị nền tảng, tôi muốn lập kế hoạch di trú theo loại đối tượng và thứ tự phụ thuộc, để đội di trú có kế hoạch rõ thứ tự, xem được ước tính số bản ghi từng loại. | M | 2 | MVP, W2 | FR-18-060; UC-18-34 |
| US-18-061 | Là quản trị nền tảng, tôi muốn chạy thử di trú không ghi, để đội di trú thấy dự báo đầy đủ trước khi động vào hệ mới. | M | 3 | MVP, W2 | FR-18-061; UC-18-35 |
| US-18-062 | Là quản trị nền tảng, tôi muốn chạy thật di trú có duyệt bốn mắt, để dữ liệu hệ cũ nằm ở phân hệ đích, có báo cáo đối chiếu và danh sách lỗi để xử lý tiếp. | M | 5 | MVP, W2 | FR-18-062; UC-18-36 |
| US-18-063 | Là quản trị nền tảng, tôi muốn quản lý bản ghi lỗi và chạy lại sau khi sửa, để số bản ghi lỗi giảm qua từng vòng; mọi bản ghi không di trú đều có lý do. | M | 2 | MVP, W2 | FR-18-063; UC-18-35 |
| US-18-064 | Là quản trị nền tảng, tôi muốn lập báo cáo đối chiếu số lượng và tổng kiểm tra, để có biên bản đối chiếu dùng để nghiệm thu từng đợt di trú. | M | 2 | MVP, W2 | FR-18-064; UC-18-35, 18-36 |
| US-18-065 | Là quản trị nền tảng, tôi muốn hệ thống đánh dấu thông tin xác thực cần cấp lại, để đội cắt chuyển biết HTTT nào đã có thông tin xác thực mới, HTTT nào còn chờ. | M | 2 | MVP, W2 | FR-18-065; UC-18-36 |
| US-18-066 | Là quản trị nền tảng, tôi muốn theo dõi chạy song song và cầu nối PH-10, để đội chuyển đổi biết nhóm nào sẵn sàng cắt chuyển. | S | 2 | MVP, W2 | FR-18-066; UC-18-37 |
| US-18-067 | Là quản trị nền tảng, tôi muốn hệ thống đối soát kết quả hệ cũ và Datahub bằng lưu lượng nhân bản, để đội chuyển đổi có số liệu khớp thật trước khi cắt chuyển. | S | 2 | MVP, W2 | FR-18-067; UC-18-37 |
| US-18-068 | Là quản trị nền tảng, tôi muốn điều khiển cắt chuyển nhóm dịch vụ và quay lui, để nhóm dịch vụ chạy trên Datahub; nếu có vấn đề, quay lại hệ cũ trong vài phút. | M | 5 | MVP, W2 | FR-18-068; UC-18-38 |

: Story của epic EP-18-I Di trú hệ cũ và chạy song song

#### EP-18-J · Quản trị, kiểm toán và báo cáo

Epic gồm 4 story, 9 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-18-069 | Là quản trị nền tảng, tôi muốn quản lý tham số của phân hệ vận hành, để tỉnh điều chỉnh được ngưỡng vận hành phù hợp quy mô. | M | 3 | MVP, W2 | FR-18-069; UC-18-02 |
| US-18-070 | Là kiểm toán viên, tôi muốn hệ thống ghi và tra nhật ký thao tác vận hành, để kiểm toán viên tra được ai làm gì, khi nào, vì sao, ai duyệt. | M | 1 | MVP, W2 | FR-18-070; UC-18-39 |
| US-18-071 | Là quản trị tỉnh, tôi muốn hệ thống lập báo cáo vận hành định kỳ, để lãnh đạo có báo cáo vận hành hằng tháng; PH-16 có số liệu vận hành mà không gọi API của PH-18. | S | 2 | MVP, W2 | FR-18-071; UC-18-39 |
| US-18-072 | Là quản trị nền tảng, tôi muốn hệ thống theo dõi sức khỏe phân hệ và chế độ suy giảm, để giao dịch của HTTT không bị ảnh hưởng khi PH-18 gặp sự cố; người vận hành thấy rõ phần nào đang suy giảm. | M | 3 | MVP, W2 | FR-18-072; UC-18-40 |

: Story của epic EP-18-J Quản trị, kiểm toán và báo cáo

### 6.20. PH-19 · Thanh toán điện tử

Phân hệ có 15 epic, 69 story, tổng 237 điểm; wave phát triển W4, đợt Đợt 2. Nguồn: D02-03-PH19 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-19-A · Nhà cung cấp thanh toán

Epic gồm 13 story, 52 điểm (12 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-001 | Là quản trị thanh toán, tôi muốn khai báo nhà cung cấp, để quản trị thanh toán thấy nhà cung cấp mới trong danh sách với nhãn "Bản nháp", sức khỏe "Chưa rõ", kèm gợi ý bước tiếp theo là gắn thông tin xác thực. | M | 5 | MVP, W4 | FR-19-001; UC-19-01 |
| US-19-002 | Là quản trị thanh toán, tôi muốn gắn thông tin xác thực nhà cung cấp, để người dùng thấy danh sách tham chiếu theo môi trường và mục đích, kèm dấu vân tay, hạn dùng và số ngày còn hạn; giá trị bí mật không bao giờ hiện trên màn hình. | M | 5 | MVP, W4 | FR-19-002; UC-19-01 |
| US-19-003 | Là quản trị thanh toán, tôi muốn kiểm tra kết nối nhà cung cấp, để người dùng thấy từng bước kiểm tra chuyển dần sang đạt hoặc không đạt, kèm độ trễ và lý do đã che; khi đạt ở môi trường thật và có thay đổi chờ, thay đổi được áp ngay. | M | 5 | MVP, W4 | FR-19-003; UC-19-02 |
| US-19-004 | Là quản trị thanh toán, tôi muốn thực hiện giao dịch thử, để người dùng mở được trang thanh toán thử của NCC, trả tiền, rồi thấy các bước "Khởi tạo", "Chuyển hướng", "Nhận IPN", "Xác minh IPN", "Xác nhận qua truy vấn" lần lượt đạt; kết quả trở thành mục C2 của checklist kích hoạt. | M | 5 | MVP, W4 | FR-19-004; UC-19-02 |
| US-19-005 | Là quản trị thanh toán, tôi muốn kích hoạt nhà cung cấp có phê duyệt, để sau khi được duyệt, nhà cung cấp hiện nhãn "Đang hoạt động", bắt đầu có chỉ số sức khỏe và có phiên đối soát từ ngày kế tiếp; người lập nhận thông báo kết quả quyết định. | M | 8 | MVP, W4 | FR-19-005; UC-19-03 |
| US-19-006 | Là quản trị thanh toán, tôi muốn tạm dừng và mở lại nhà cung cấp, để kênh hiện nhãn "Tạm dừng" và đối tác nhận lỗi kênh tạm không khả dụng cho giao dịch mới trong vòng 1 giây; giao dịch đang dở vẫn được nhận kết quả và đối soát bình thường. | M | 5 | MVP, W4 | FR-19-006; UC-19-04 |
| US-19-007 | Là người dùng có quyền xem, tôi muốn có danh sách, tìm kiếm, sắp xếp nhà cung cấp, để người dùng thấy bảng nhà cung cấp kèm trạng thái, sức khỏe, số dịch vụ hoạt động, số giao dịch hôm nay, hạn chứng thư gần nhất và các nút thao tác được phép. | M | 1 | MVP, W4 | FR-19-007; UC-19-05 |
| US-19-008 | Là người dùng có quyền xem, tôi muốn xem chi tiết nhà cung cấp, để người dùng thấy đủ thông tin của kênh trên các tab, biết kênh có đang khỏe không, còn thiếu gì để kích hoạt và chứng thư nào sắp hết hạn. | M | 1 | MVP, W4 | FR-19-008; UC-19-05 |
| US-19-009 | Là quản trị thanh toán, tôi muốn chỉnh sửa nhà cung cấp, để người dùng thấy thông tin mô tả đã cập nhật ngay; thay đổi kết nối hiện ở khối "Thay đổi đang chờ" cho tới khi kiểm tra đạt. | M | 3 | MVP, W4 | FR-19-009; UC-19-05 |
| US-19-010 | Là quản trị thanh toán, tôi muốn xóa hoặc ngừng hẳn nhà cung cấp, để bản nháp biến khỏi danh sách; kênh ngừng hẳn hiện nhãn "Đã ngừng", không nhận giao dịch mới, nhưng giao dịch, biên bản đối soát cũ vẫn tra cứu được. | M | 3 | MVP, W4 | FR-19-010; UC-19-04 |
| US-19-011 | Là kế toán đối soát, tôi muốn hệ thống giám sát sức khỏe và cảnh báo lỗi kết nối, để cán bộ thấy nhãn sức khỏe của kênh trên UI-19-01, UI-19-02, UI-19-04 thay đổi trong vòng một phút và nhận cảnh báo của PH-13 trong ≤ 3 phút khi kênh ngừng; đối tác nhận lỗi nhanh thay vì chờ hết thời gian. | M | 3 | MVP, W4 | FR-19-011; UC-19-06 |
| US-19-012 | Là cán bộ ATTT, tôi muốn xoay khóa và chứng thư nhà cung cấp, để cán bộ ATTT thấy bản "Kế tiếp" kèm lịch chuyển tiếp; hết thời gian chuyển tiếp, bản mới tự thành "Đang dùng" và nhắc hạn của bản cũ dừng. | S | 3 | Đợt 2, W4 | FR-19-012; UC-19-06 |
| US-19-069 | Là quản trị thanh toán, tôi muốn quản lý bảng ánh xạ mã kết quả nhà cung cấp (đề xuất), để sau khi duyệt, cán bộ thấy phiên bản ánh xạ mới có hiệu lực ngay, có thể so với phiên bản trước; mã chưa có trong bảng luôn rơi về "chờ xác minh", không bao giờ thành công. | M | 5 | MVP, W4 | FR-19-069; UC-19-05 |

: Story của epic EP-19-A Nhà cung cấp thanh toán

#### EP-19-B · Nhóm dịch vụ và dịch vụ thanh toán

Epic gồm 4 story, 14 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-013 | Là quản trị thanh toán, tôi muốn quản lý nhóm dịch vụ, để người dùng thấy nhóm mới hoặc đã sửa trong danh sách kèm tên lĩnh vực tra từ danh mục dùng chung và số dịch vụ theo trạng thái. | M | 3 | MVP, W4 | FR-19-013; UC-19-07 |
| US-19-014 | Là quản trị thanh toán, tôi muốn quản lý dịch vụ thanh toán, để người dùng thấy dịch vụ ở trạng thái "Bản nháp" (khi tạo) hoặc thông tin mới (khi sửa); thay đổi khoảng số tiền, thời hạn áp cho giao dịch tạo sau thời điểm lưu. | M | 3 | MVP, W4 | FR-19-014; UC-19-08 |
| US-19-015 | Là quản trị thanh toán, tôi muốn điều khiển vòng đời dịch vụ, để dịch vụ hiện nhãn trạng thái mới; đối tác được gán thấy ngay hiệu lực (tạo được giao dịch khi "Đang hoạt động", nhận lỗi dịch vụ không hoạt động khi "Tạm dừng"). | M | 5 | MVP, W4 | FR-19-015; UC-19-08 |
| US-19-016 | Là kế toán đối soát, tôi muốn hệ thống kiểm tra và đồng bộ mã danh mục PH-07, để người dùng chọn được mã còn hiệu lực từ danh sách gợi ý; dịch vụ dùng mã đã bị ngừng hiện cờ cảnh báo "Mã danh mục hết hiệu lực" và quản trị thanh toán nhận cảnh báo, việc thu không bị gián đoạn. | S | 3 | MVP, W4 | FR-19-016; UC-19-07, 19-08 |

: Story của epic EP-19-B Nhóm dịch vụ và dịch vụ thanh toán

#### EP-19-C · Đối tác và thông tin xác thực

Epic gồm 5 story, 18 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-017 | Là quản trị thanh toán, tôi muốn quản lý hồ sơ đối tác, để người dùng thấy đối tác mới ở trạng thái "Bản nháp" với chế độ định tuyến tương ứng, hoặc hồ sơ đã cập nhật; danh sách địa chỉ quay về mới áp cho giao dịch tạo sau. | M | 3 | MVP, W4 | FR-19-017; UC-19-09 |
| US-19-018 | Là quản trị thanh toán, tôi muốn điều khiển vòng đời đối tác, để đối tác hiện trạng thái mới; khi được duyệt `ACTIVE`, client của đối tác tạo được giao dịch; khi chấm dứt, mọi client bị thu hồi ngay và webhook của giao dịch dở vẫn được gửi tối đa 30 ngày. | M | 5 | MVP, W4 | FR-19-018; UC-19-09 |
| US-19-019 | Là quản trị thanh toán, tôi muốn cấp và thu hồi client của đối tác, để người dùng thấy client mới với mã client, dấu vân tay, hạn dùng và hướng dẫn lấy token; client bị thu hồi không gọi được API trong ≤ 60 giây, kể cả token còn hạn. | M | 3 | MVP, W4 | FR-19-019; UC-19-10 |
| US-19-020 | Là quản trị thanh toán, tôi muốn gán dịch vụ và hạn mức cho đối tác, để người dùng thấy danh sách dịch vụ được gán kèm hạn mức và phần đã dùng trong ngày; hạn mức mới có hiệu lực ngay với yêu cầu tiếp theo. | M | 2 | MVP, W4 | FR-19-020; UC-19-10 |
| US-19-021 | Là quản trị thanh toán, tôi muốn có cấu hình webhook của đối tác, để người dùng thấy đầu nhận mới và bí mật ký hiện đúng một lần kèm nút sao chép; "Gửi thử" cho biết ngay mã HTTP, độ trễ và đoạn đầu phản hồi của đối tác. | M | 5 | MVP, W4 | FR-19-021; UC-19-10 |

: Story của epic EP-19-C Đối tác và thông tin xác thực

#### EP-19-D · Giao dịch thanh toán và kết nối PayGov

Epic gồm 7 story, 34 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-022 | Là HTTT khai thác, tôi muốn tạo giao dịch thanh toán, để đối tác nhận mã giao dịch, địa chỉ trang thanh toán và thời hạn; người nộp được chuyển sang trang PayGov để chọn ngân hàng, ví và trả tiền. | M | 8 | MVP, W4 | FR-19-022; UC-19-11 |
| US-19-023 | Là HTTT đối tác thanh toán, tôi muốn hệ thống kiểm tra hợp lệ yêu cầu thanh toán, để đối tác biết chính xác điều kiện nào chưa đạt qua mã lỗi và câu mô tả; sửa xong có thể gửi lại cùng `Idempotency-Key`. | M | 8* | MVP, W4 | FR-19-023; UC-19-11 |
| US-19-024 | Là kế toán đối soát, tôi muốn hệ thống khởi tạo thanh toán tại nhà cung cấp qua adapter, để đối tác nhận `paymentUrl` để chuyển người nộp, hoặc nhận lỗi rõ ràng khi NCC từ chối, hoặc nhận lỗi "chưa xác định" kèm hướng dẫn gửi lại cùng khóa. | M | 5 | MVP, W4 | FR-19-024; UC-19-11 |
| US-19-025 | Là người nộp tiền, tôi muốn xử lý người nộp quay về, để người nộp thấy trang UI-19-28 báo kết quả theo dữ liệu đã xác thực trong CSDL, sau 5 giây tự về cổng dịch vụ của đối tác cùng mã giao dịch và trạng thái có chữ ký. | M | 5 | MVP, W4 | FR-19-025; UC-19-12 |
| US-19-026 | Là HTTT khai thác, tôi muốn hủy giao dịch chưa thanh toán, để giao dịch hiện "Đã hủy" và đối tác nhận webhook `transaction.cancelled`; nếu người nộp đã kịp trả tiền thì giao dịch được ghi nhận thành công thay vì bị hủy. | S | 3 | Đợt 2, W4 | FR-19-026; UC-19-14 |
| US-19-027 | Là kế toán đối soát, tôi muốn hệ thống tự động hết hạn giao dịch, để đối tác nhận webhook `transaction.expired` và biết có thể tạo giao dịch mới cho hồ sơ; cán bộ thấy giao dịch "Hết hạn", có cờ "cần đối soát" khi chưa xác định được. | M | 3 | MVP, W4 | FR-19-027; UC-19-14 |
| US-19-028 | Là kế toán đối soát, tôi muốn hệ thống ghi lịch sử trạng thái bất biến, để cán bộ và kiểm toán viên xem được dòng thời gian đầy đủ của giao dịch ở tab "Dòng thời gian" của UI-19-15: ai, lúc nào, nguồn nào, vì sao đổi trạng thái. | M | 2 | MVP, W4 | FR-19-028; UC-19-11, 19-13 |

: Story của epic EP-19-D Giao dịch thanh toán và kết nối PayGov

#### EP-19-E · Nhận kết quả thanh toán (IPN)

Epic gồm 4 story, 19 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-029 | Là kế toán đối soát, tôi muốn tiếp nhận và xác minh IPN, để PayGov nhận phản hồi "đã nhận" trong thời hạn NFR-19-003; cán bộ thấy mọi IPN, kể cả bị từ chối, ở UI-19-16 với kết quả xác minh. | M | 8 | MVP, W4 | FR-19-029; UC-19-13 |
| US-19-030 | Là kế toán đối soát, tôi muốn hệ thống xử lý IPN đúng một lần, để đối tác nhận webhook `transaction.succeeded` hoặc `transaction.failed` sau ≤ vài giây kể từ khi PayGov gửi IPN; người nộp thấy hồ sơ được ghi nhận đã trả tiền. | M | 5 | MVP, W4 | FR-19-030; UC-19-13 |
| US-19-031 | Là kế toán đối soát, tôi muốn hệ thống cách ly IPN bất thường, để kế toán thấy chênh lệch mới ở UI-19-21, UI-19-22 và nhận cảnh báo mức cao với lệch số tiền, IPN không khớp giao dịch; cán bộ hỗ trợ thấy lý do cách ly ở UI-19-16. | M | 3 | MVP, W4 | FR-19-031; UC-19-13 |
| US-19-032 | Là kế toán đối soát, tôi muốn xem và xử lý lại IPN, để cán bộ thấy chính xác PayGov đã gửi gì và vì sao IPN bị từ chối hay cách ly; sau khi xử lý lại, giao dịch có trạng thái đúng mà không cần liên hệ nhà cung cấp. | S | 3 | Đợt 2, W4 | FR-19-032; UC-19-16 |

: Story của epic EP-19-E Nhận kết quả thanh toán (IPN)

#### EP-19-F · Lũy đẳng và chống trùng

Epic gồm 2 story, 5 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-033 | Là HTTT khai thác, tôi muốn bảo đảm idempotency theo Idempotency-Key, để đối tác gửi lại bao nhiêu lần cũng nhận cùng một kết quả và chỉ có một giao dịch được tạo. | M | 3 | MVP, W4 | FR-19-033; UC-19-11 |
| US-19-034 | Là kế toán đối soát, tôi muốn hệ thống chống trùng theo mã đơn hàng của đối tác, để đối tác được dẫn tới giao dịch đang mở hoặc đã thành công của hồ sơ thay vì tạo giao dịch thứ hai. | M | 2 | MVP, W4 | FR-19-034; UC-19-11 |

: Story của epic EP-19-F Lũy đẳng và chống trùng

#### EP-19-G · Truy vấn và đồng bộ trạng thái

Epic gồm 3 story, 7 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-035 | Là HTTT khai thác, tôi muốn đối tác truy vấn trạng thái giao dịch, để đối tác nhận trạng thái hiện tại của giao dịch, kể cả cờ đối soát và số tiền đã hoàn, để cập nhật hồ sơ của người nộp. | M | 2 | MVP, W4 | FR-19-035; UC-19-15 |
| US-19-036 | Là kế toán đối soát, tôi muốn hệ thống chủ động truy vấn nhà cung cấp cho giao dịch treo, để đối tác vẫn nhận được webhook kết quả dù IPN bị lỡ; cán bộ thấy các lần truy vấn và kết quả ở tab "Truy vấn NCC". | M | 3 | MVP, W4 | FR-19-036; UC-19-16 |
| US-19-037 | Là kế toán đối soát, tôi muốn đồng bộ trạng thái thủ công, để cán bộ thấy kết quả "Trạng thái trước → sau", "Không thay đổi" hoặc "NCC chưa có kết quả" để trả lời người dân ngay. | S | 2 | Đợt 2, W4 | FR-19-037; UC-19-16 |

: Story của epic EP-19-G Truy vấn và đồng bộ trạng thái

#### EP-19-H · Hoàn tiền

Epic gồm 4 story, 18 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-038 | Là kế toán đối soát, tôi muốn lập yêu cầu hoàn tiền, để người lập thấy yêu cầu hoàn với mã `refundCode`, trạng thái "Chờ duyệt" và số cấp duyệt cần; đối tác nhận kết quả cuối qua webhook `refund.*` hoặc API-19-106. | M | 8 | MVP, W4 | FR-19-038; UC-19-17 |
| US-19-039 | Là người phê duyệt, tôi muốn phê duyệt hoặc từ chối hoàn tiền, để người lập và đối tác biết yêu cầu đã được duyệt hay bị từ chối; yêu cầu được duyệt chuyển ngay sang thực thi. | M | 3 | MVP, W4 | FR-19-039; UC-19-18 |
| US-19-040 | Là kế toán đối soát, tôi muốn hệ thống thực thi hoàn tiền, để kế toán thấy trạng thái thực thi và các lần thực thi ở UI-19-18; khi hoàn xong, giao dịch gốc hiện "Đã hoàn một phần" hoặc "Đã hoàn toàn phần" và đối tác nhận webhook `refund.succeeded`. | M | 5 | Đợt 2, W4 | FR-19-040; UC-19-18 |
| US-19-041 | Là kế toán đối soát, tôi muốn theo dõi kết quả hoàn tiền, để người dùng thấy trạng thái hiện tại của từng yêu cầu hoàn; giao dịch gốc hiện số tiền đã hoàn và nhãn trạng thái tương ứng. | M | 2 | MVP, W4 | FR-19-041; UC-19-18 |

: Story của epic EP-19-H Hoàn tiền

#### EP-19-I · Đối soát và chênh lệch

Epic gồm 7 story, 22 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-042 | Là kế toán đối soát, tôi muốn hệ thống lập lịch và khởi tạo phiên đối soát, để kế toán thấy trên lịch UI-19-19 mỗi ngày của mỗi NCC có một phiên, ngày bị bỏ sót hiện rõ. | M | 2 | MVP, W4 | FR-19-042; UC-19-19 |
| US-19-043 | Là kế toán đối soát, tôi muốn hệ thống thu thập dữ liệu đối soát của nhà cung cấp, để kế toán thấy phiên chuyển sang "Đang so khớp" khi dữ liệu hợp lệ, hoặc thấy lý do cụ thể khi tệp sai định dạng, sai mã băm, sai NCC, sai ngày. | M | 5 | MVP, W4 | FR-19-043; UC-19-19 |
| US-19-044 | Là kế toán đối soát, tôi muốn hệ thống so khớp tự động, để kế toán thấy tổng số lượng, tổng tiền hai phía, số dòng khớp và danh sách chênh lệch mới; phiên không lệch chuyển ngay sang "Sẵn sàng chốt". | M | 3 | MVP, W4 | FR-19-044; UC-19-19 |
| US-19-045 | Là kế toán đối soát, tôi muốn quản lý bản ghi chênh lệch, để kế toán thấy chênh lệch của mình kèm tuổi, hạn, dữ liệu hai phía và dòng thời gian ghi chú; lãnh đạo thấy chênh lệch quá hạn được chuyển cấp. | M | 3 | MVP, W4 | FR-19-045; UC-19-20 |
| US-19-046 | Là kế toán đối soát, tôi muốn đề xuất và phê duyệt xử lý chênh lệch, để sau khi duyệt, kế toán thấy chênh lệch "Đã xử lý" và hệ quả đã áp (giao dịch đổi trạng thái, bản ghi bù hoặc yêu cầu hoàn mới); phiên tự chuyển "Sẵn sàng chốt" khi chênh lệch cuối cùng đóng. | M | 3 | MVP, W4 | FR-19-046; UC-19-20 |
| US-19-047 | Là kế toán đối soát, tôi muốn chốt và mở lại phiên đối soát, để kế toán thấy phiên "Đã chốt" và tải được biên bản; đối tác nhận webhook `reconciliation.closed`; mọi thao tác ghi lên phiên đã chốt bị chặn. | M | 3 | MVP, W4 | FR-19-047; UC-19-21 |
| US-19-048 | Là kế toán đối soát, tôi muốn xuất biên bản và cung cấp kết quả đối soát, để kế toán tải được biên bản PDF có mã băm để trình ký và XLSX để đối chiếu chi tiết; đối tác nhận kết quả đối soát của các giao dịch của mình. | S | 3 | Đợt 2, W4 | FR-19-048; UC-19-21 |

: Story của epic EP-19-I Đối soát và chênh lệch

#### EP-19-J · Tra cứu giao dịch

Epic gồm 4 story, 8 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-049 | Là người dùng có quyền xem, tôi muốn có danh sách giao dịch, tìm theo từ khóa, để người dùng thấy danh sách giao dịch khớp từ khóa với trạng thái, cờ đối soát, số tiền và thời điểm; người nộp hiện đã che. | M | 2 | MVP, W4 | FR-19-049; UC-19-22 |
| US-19-050 | Là người dùng có quyền xem, tôi muốn tra cứu nâng cao, để người dùng thu hẹp được tập giao dịch cần xem, ví dụ giao dịch có chênh lệch của một nhà cung cấp trong tháng, và gửi đường dẫn cho đồng nghiệp. | M | 2 | MVP, W4 | FR-19-050; UC-19-22 |
| US-19-051 | Là người dùng có quyền xem, tôi muốn xem chi tiết giao dịch, để người dùng thấy đủ thông tin để trả lời người dân hoặc đối tác về giao dịch; dữ liệu người nộp hiện đã che trừ khi có quyền và lý do. | M | 2 | MVP, W4 | FR-19-051; UC-19-23 |
| US-19-052 | Là kế toán đối soát, tôi muốn xuất danh sách giao dịch, để người dùng nhận tệp trong khay tác vụ nền, tệp có dòng chú thích bộ lọc, người xuất, thời điểm và nhãn dữ liệu cá nhân. | S | 2 | Đợt 2, W4 | FR-19-052; UC-19-22 |

: Story của epic EP-19-J Tra cứu giao dịch

#### EP-19-K · Nhật ký và kiểm toán

Epic gồm 3 story, 7 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-053 | Là kế toán đối soát, tôi muốn hệ thống ghi nhật ký kiểm toán, để kiểm toán viên tra được ở PH-13 ai đã làm gì, lúc nào, trên đối tượng nào, với giá trị trước và sau. | M | 3 | MVP, W4 | FR-19-053; UC-19-24 |
| US-19-054 | Là kiểm toán viên, tôi muốn có nhật ký tích hợp giao dịch, để người dùng thấy đối tác hoặc nhà cung cấp đã gửi gì, nhận gì, độ trễ và mã kết quả của từng lời gọi. | M | 2 | MVP, W4 | FR-19-054; UC-19-24 |
| US-19-055 | Là kế toán đối soát, tôi muốn liên kết truy vết đầu-cuối, để người dùng mở được toàn bộ vết của một giao dịch ở PH-13 từ màn chi tiết, thấy thời gian ở từng chặng. | S | 2 | MVP, W4 | FR-19-055; UC-19-23, 19-24 |

: Story của epic EP-19-K Nhật ký và kiểm toán

#### EP-19-L · Dashboard, báo cáo, chỉ số

Epic gồm 4 story, 6 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-056 | Là người dùng có quyền xem, tôi muốn có dashboard tổng quan, để người dùng thấy số giao dịch, tổng tiền thu, tỷ lệ thành công trong ngày, số giao dịch treo, số chênh lệch mở và số đề nghị chờ mình duyệt. | M | 2 | MVP, W4 | FR-19-056; UC-19-25 |
| US-19-057 | Là người dùng có quyền xem, tôi muốn có dashboard kênh thanh toán, để người dùng nhận ra ngay kênh nào đang suy giảm, kênh nào sắp hết hạn chứng thư. | M | 1 | MVP, W4 | FR-19-057; UC-19-25 |
| US-19-058 | Là kế toán đối soát, tôi muốn có báo cáo định kỳ và xuất, để kế toán có báo cáo đúng thể thức để trình lãnh đạo, số liệu khớp với biên bản đối soát đã chốt. | S | 2 | Đợt 2, W4 | FR-19-058; UC-19-26 |
| US-19-059 | Là kế toán đối soát, tôi muốn hệ thống phát chỉ số vận hành và cảnh báo, để người vận hành nhận cảnh báo kênh ngừng trong ≤ 3 phút, thấy chỉ số trên UI-19-01 và màn giám sát của PH-13. | M | 1 | MVP, W4 | FR-19-059; UC-19-25 |

: Story của epic EP-19-L Dashboard, báo cáo, chỉ số

#### EP-19-M · Thông báo và sự kiện

Epic gồm 3 story, 10 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-060 | Là kế toán đối soát, tôi muốn hệ thống gửi webhook kết quả có ký, để đối tác nhận thông báo kết quả trong vài giây, xác minh được chữ ký và chống trùng theo `id`; cán bộ thấy từng lần gửi ở UI-19-24. | M | 3 | MVP, W4 | FR-19-060; UC-19-27 |
| US-19-061 | Là kế toán đối soát, tôi muốn hệ thống phát sự kiện qua outbox, để các phân hệ tiêu thụ nhận sự kiện theo đúng thứ tự trong một giao dịch, p95 ≤ 2 giây sau khi ghi, và chống trùng theo `id`. | M | 5 | MVP, W4 | FR-19-061; UC-19-27 |
| US-19-062 | Là kế toán đối soát, tôi muốn theo dõi và gửi lại webhook, để cán bộ thấy lượt gửi lại chuyển "Đang chờ gửi" rồi "Đã gửi"; đối tác nhận lại thông báo với cùng `id` sự kiện để chống trùng. | S | 2 | MVP, W4 | FR-19-062; UC-19-27 |

: Story của epic EP-19-M Thông báo và sự kiện

#### EP-19-N · Cấu hình tenant

Epic gồm 2 story, 6 điểm (2 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-063 | Là quản trị thanh toán, tôi muốn có cấu hình thanh toán của tenant, để người dùng thấy phiên bản mới trong lịch sử với khác biệt từng khóa; giá trị có hiệu lực trên mọi bản sao trong ≤ 60 giây, giao dịch đã tạo giữ tham số cũ. | M | 3 | MVP, W4 | FR-19-063; UC-19-28 |
| US-19-064 | Là kế toán đối soát, tôi muốn hệ thống khởi tạo và tạm ngừng phân hệ theo tenant, để quản trị tenant thấy menu "Thanh toán" xuất hiện khi bật; khi tắt, mọi màn có dải cảnh báo "Phân hệ thanh toán đang tạm ngừng cho tỉnh." và nút ghi bị ẩn. | M | 3 | MVP, W4 | FR-19-064; UC-19-28 |

: Story của epic EP-19-N Cấu hình tenant

#### EP-19-O · Di trú và chạy song song

Epic gồm 4 story, 11 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-19-065 | Là quản trị thanh toán, tôi muốn nhập danh mục và giao dịch lịch sử từ hệ cũ, để đội di trú thấy số dòng đọc, nhập mới, cập nhật, bỏ qua, lỗi của mỗi lần chạy và tải được báo cáo dòng lỗi. | M | 2 | MVP, W4 | FR-19-065; UC-19-29 |
| US-19-066 | Là quản trị thanh toán, tôi muốn chuyển chế độ định tuyến theo đối tác, để quản trị thanh toán thấy chế độ định tuyến mới của đối tác; yêu cầu của đối tác được chuyển tới đúng hệ trong vòng một phút. | M | 5 | MVP, W4 | FR-19-066; UC-19-29 |
| US-19-067 | Là HTTT khai thác, tôi muốn có lớp tương thích API hệ cũ, để đối tác cũ tiếp tục thu tiền qua Datahub mà chưa phải sửa mã, và được báo trước ngày ngừng hỗ trợ. | C | 2 | Đợt sau, Sau G5 | FR-19-067; UC-19-29 |
| US-19-068 | Là quản trị thanh toán, tôi muốn đối chiếu sau di trú, để người dùng thấy bảng so sánh theo tháng, theo đối tác và kết luận "Đạt" hoặc "Không đạt" kèm danh sách bản ghi lệch tải được. | M | 2 | MVP, W4 | FR-19-068; UC-19-29 |

: Story của epic EP-19-O Di trú và chạy song song

### 6.21. PH-20 · Quản trị tenant và phát hành sản phẩm

Phân hệ có 10 epic, 70 story, tổng 207 điểm; wave phát triển W2, đợt MVP. Nguồn: D02-03-PH20 chương 6. Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.

#### EP-20-A · Hồ sơ tenant

Epic gồm 7 story, 22 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-001 | Là quản trị nền tảng, tôi muốn khai báo tenant mới, để tỉnh mới xuất hiện ở danh sách tenant với nhãn "Đang khởi tạo – chưa chạy", PA bấm "Khởi tạo" để bắt đầu saga. | M | 8 | MVP, W2 | FR-20-001; UC-20-02 |
| US-20-002 | Là quản trị nền tảng, tôi muốn liệt kê, tìm, lọc tenant toàn nền tảng, để người dùng lọc nhanh tenant `FAILED` hoặc chạm hạn mức. | M | 2 | MVP, W2 | FR-20-002; UC-20-01 |
| US-20-003 | Là quản trị nền tảng, tôi muốn xem chi tiết tenant, để người dùng biết tình trạng tenant và thao tác làm được. | M | 2 | MVP, W2 | FR-20-003; UC-20-01 |
| US-20-004 | Là quản trị nền tảng, tôi muốn sửa hồ sơ hành chính của tenant, để tên mới hiện ở mọi màn của nền tảng sau tối đa 60 giây (đệm registry). | M | 3 | MVP, W2 | FR-20-004; UC-20-03 |
| US-20-005 | Là quản trị nền tảng, tôi muốn quản lý đầu mối và hợp đồng dịch vụ của tenant, để thông báo tới đúng người; hợp đồng hiện hành là căn cứ hạn mức. | S | 3 | MVP, W2 | FR-20-005; UC-20-03 |
| US-20-006 | Là quản trị nền tảng, tôi muốn hệ thống bảo vệ tenant đặc biệt PLATFORM và COMMON, để không ai làm hỏng được hai tenant nền. | M | 2 | MVP, W2 | FR-20-006; UC-20-03 |
| US-20-007 | Là quản trị nền tảng, tôi muốn kiểm tra sẵn sàng trước khởi tạo, để PA biết chính xác phải xử lý gì trước khi khởi tạo. | M | 2 | MVP, W2 | FR-20-007; UC-20-02 |

: Story của epic EP-20-A Hồ sơ tenant

#### EP-20-B · Saga khởi tạo

Epic gồm 10 story, 36 điểm (6 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-008 | Là quản trị nền tảng, tôi muốn chạy saga khởi tạo tenant, để PA thấy sổ bước chạy dần trên UI-20-04; tỉnh mới thường `ACTIVE` sau 20–40 phút. | M | 8 | MVP, W2 | FR-20-008; UC-20-05 |
| US-20-009 | Là quản trị nền tảng, tôi muốn theo dõi tiến độ saga thời gian thực, để PA thấy sổ bước cập nhật trong ≤ 2 giây sau mỗi thay đổi (NFR-20-007). | M | 2 | MVP, W2 | FR-20-009; UC-20-06 |
| US-20-010 | Là quản trị nền tảng, tôi muốn thử lại saga từ bước lỗi, để saga chạy tiếp từ đúng chỗ dừng; các bước đã xong không bị làm lại. | M | 2 | MVP, W2 | FR-20-010; UC-20-06 |
| US-20-011 | Là quản trị nền tảng, tôi muốn bù trừ và hủy khởi tạo, để không còn tài nguyên mồ côi; danh sách việc dọn tay (nếu có) hiện ở UI-20-04. | M | 5 | MVP, W2 | FR-20-011; UC-20-06 |
| US-20-012 | Là quản trị nền tảng, tôi muốn hệ thống kiểm tra khói sau khởi tạo, để PA thấy bốn dấu tích xanh trước khi nút "Kích hoạt" sáng. | M | 3 | MVP, W2 | FR-20-012; UC-20-07 |
| US-20-013 | Là quản trị nền tảng, tôi muốn hệ thống kích hoạt tenant và bàn giao cho quản trị tỉnh, để quản trị tỉnh nhận thư, đăng nhập `dh-console` của tỉnh và bắt đầu làm việc. | M | 3 | MVP, W2 | FR-20-013; UC-20-07 |
| US-20-014 | Là quản trị nền tảng, tôi muốn hệ thống đo và báo thời gian khởi tạo tenant (KPI-12) cho PH-16, để chỉ tiêu `thoi-gian-khoi-tao-tenant` của PH-16 có số tự động cho mỗi tỉnh mới. | S | 2 | MVP, W2 | FR-20-014; UC-20-07 |
| US-20-015 | Là quản trị nền tảng, tôi muốn quản lý mẫu khởi tạo có phiên bản, để PA có danh sách mẫu (`tinh-chuan`, `tinh-thi-diem`, `test-minimal`) để chọn khi khai báo. | S | 3 | MVP, W2 | FR-20-015; UC-20-04 |
| US-20-016 | Là quản trị nền tảng, tôi muốn khởi tạo bổ sung cho tenant đang hoạt động, để mọi tỉnh đang hoạt động có cùng nền tài nguyên với tỉnh mới, không gián đoạn phục vụ. | S | 3 | MVP, W2 | FR-20-016; UC-20-08 |
| US-20-017 | Là quản trị nền tảng, tôi muốn khởi tạo tenant chế độ DEDICATED_CLUSTER, để tỉnh tự vận hành có tenant chạy trên cụm riêng, được nâng cấp bằng cùng gói phát hành (BR-20-035). | S | 5 | Đợt 2, W4 | FR-20-017; UC-20-08 |

: Story của epic EP-20-B Saga khởi tạo

#### EP-20-C · Cấu hình

Epic gồm 8 story, 27 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-018 | Là quản trị tỉnh, tôi muốn cài đặt tỉnh do quản trị tỉnh tự quản, để tên, logo tỉnh hiện trên `dh-console`; chính sách đăng nhập mới áp ở lần đăng nhập kế tiếp. | M | 3 | MVP, W2 | FR-20-018; UC-20-11 |
| US-20-019 | Là quản trị nền tảng, tôi muốn có cấu hình nền tảng của tenant, để API công bố của tỉnh đổi host, tiền tố theo cấu hình sau khi PH-03 áp (≤ 5 phút, NFR-20-011). | M | 5 | MVP, W2 | FR-20-019; UC-20-09 |
| US-20-020 | Là quản trị nền tảng, tôi muốn hệ thống ghi cấu hình tenant vào kho GitOps có phiên bản và áp xuống, để mọi cấu hình của tỉnh tra được ai đổi, lúc nào, vì sao, đã áp chưa. | M | 5 | MVP, W2 | FR-20-020; UC-20-09 |
| US-20-021 | Là quản trị nền tảng, tôi muốn có lịch sử, so sánh, khôi phục phiên bản cấu hình, để PA quay cấu hình về trạng thái đã biết là tốt trong vài phút. | S | 2 | MVP, W2 | FR-20-021; UC-20-10 |
| US-20-022 | Là quản trị nền tảng, tôi muốn hệ thống phát hiện lệch cấu hình và đối chiếu định kỳ, để UI-20-17 hiện danh sách khóa lệch, giá trị mong muốn và thực, cách xử lý. | S | 3 | MVP, W2 | FR-20-022; UC-20-10 |
| US-20-023 | Là quản trị tỉnh, tôi muốn có chính sách tiếp nhận truy cập liên tenant của tỉnh, để tỉnh kiểm soát được việc nền tảng vào dữ liệu của mình và biết ngay khi có người vào. | M | 2 | MVP, W2 | FR-20-023; UC-20-12 |
| US-20-024 | Là quản trị tỉnh, tôi muốn xem nhật ký truy cập liên tenant vào tỉnh, để SO thấy danh sách phiên liên tenant, lọc nhanh phiên có ghi. | S | 2 | MVP, W2 | FR-20-024; UC-20-12 |
| US-20-025 | Là quản trị nền tảng, tôi muốn chuyển chế độ cách ly của tenant, để tỉnh có CSDL riêng, gián đoạn ghi ≤ 15 phút trong cửa sổ bảo trì (giả định). | S | 5 | Đợt 2, W4 | FR-20-025; UC-20-13 |

: Story của epic EP-20-C Cấu hình

#### EP-20-D · Hạn mức, sử dụng

Epic gồm 7 story, 20 điểm (5 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-026 | Là quản trị nền tảng, tôi muốn đặt hạn mức hợp đồng của tenant, để nơi thực thi áp hạn mức mới ≤ 5 phút (NFR-20-011). | M | 3 | MVP, W2 | FR-20-026; UC-20-14 |
| US-20-027 | Là quản trị nền tảng, tôi muốn đổi hạn mức có duyệt và đẩy xuống nơi thực thi, để hạn mức mới có hiệu lực ở mọi nơi thực thi, có người duyệt khi rủi ro. | M | 5 | MVP, W2 | FR-20-027; UC-20-14 |
| US-20-028 | Là quản trị nền tảng, tôi muốn hệ thống thu thập sử dụng tài nguyên theo tenant, để biểu đồ sử dụng có điểm mỗi giờ cho mọi tỉnh. | M | 2 | MVP, W2 | FR-20-028; UC-20-15 |
| US-20-029 | Là quản trị nền tảng, tôi muốn hệ thống cảnh báo ngưỡng hạn mức 80% và 100%, để tỉnh và nền tảng nhận một thư cho mỗi lần chạm ngưỡng, không bị lặp mỗi giờ. | M | 3 | MVP, W2 | FR-20-029; UC-20-15 |
| US-20-030 | Là quản trị nền tảng, tôi muốn xem sử dụng tài nguyên của tỉnh và toàn nền tảng, để biểu đồ sử dụng theo tài nguyên có đường hạn mức, chip cảnh báo. | M | 2 | MVP, W2 | FR-20-030; UC-20-16 |
| US-20-031 | Là quản trị nền tảng, tôi muốn có báo cáo sử dụng tài nguyên theo kỳ, xuất tệp, để bảng sử dụng theo kỳ, tải được trong 30 ngày. | S | 2 | MVP, W2 | FR-20-031; UC-20-16 |
| US-20-032 | Là quản trị nền tảng, tôi muốn ghi đè hạn mức tạm thời có thời hạn, để tỉnh có thêm sức chứa trong đợt cao điểm, tự về mức hợp đồng sau đó. | S | 3 | MVP, W2 | FR-20-032; UC-20-14 |

: Story của epic EP-20-D Hạn mức, sử dụng

#### EP-20-E · Phân hệ, tính năng

Epic gồm 5 story, 12 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-033 | Là quản trị nền tảng, tôi muốn danh mục phân hệ của nền tảng và ma trận phụ thuộc, để PA thấy ngay bật PH-19 cần PH-03, PH-12 đã bật. | M | 2 | MVP, W2 | FR-20-033; UC-20-17 |
| US-20-034 | Là quản trị nền tảng, tôi muốn bật phân hệ cho tenant, để menu phân hệ hiện ở `dh-console` của tỉnh sau khi `ENABLED`. | M | 3 | MVP, W2 | FR-20-034; UC-20-17 |
| US-20-035 | Là quản trị nền tảng, tôi muốn tắt, tạm ngừng phân hệ cho tenant, để người dùng tỉnh thấy phân hệ ở chế độ chỉ đọc hoặc biến khỏi menu. | M | 3 | MVP, W2 | FR-20-035; UC-20-18 |
| US-20-036 | Là quản trị nền tảng, tôi muốn cờ tính năng theo tenant, để tính năng bật hoặc tắt cho riêng tỉnh trong ≤ 60 giây. | S | 2 | MVP, W2 | FR-20-036; UC-20-18 |
| US-20-037 | Là người dùng có quyền xem, tôi muốn cung cấp trạng thái phân hệ cho menu và giao diện, để menu chỉ hiện phân hệ tỉnh được dùng; dải cảnh báo nói rõ tình trạng tỉnh. | M | 2 | MVP, W2 | FR-20-037; UC-20-17 |

: Story của epic EP-20-E Phân hệ, tính năng

#### EP-20-F · Vòng đời

Epic gồm 7 story, 25 điểm (7 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-038 | Là quản trị nền tảng, tôi muốn tạm ngừng tenant, để mọi lượt gọi vào tỉnh nhận "Tỉnh đang tạm ngừng hoạt động trên Datahub. | M | 5 | MVP, W2 | FR-20-038; UC-20-20 |
| US-20-039 | Là quản trị nền tảng, tôi muốn khôi phục tenant, để tỉnh phục vụ lại bình thường. | M | 3 | MVP, W2 | FR-20-039; UC-20-20 |
| US-20-040 | Là quản trị nền tảng, tôi muốn đề nghị và duyệt chấm dứt tenant, để đề nghị chấm dứt có đủ chữ ký số người, văn bản, lịch, sẵn sàng để thực hiện khi đủ điều kiện. | M | 3 | MVP, W2 | FR-20-040; UC-20-21 |
| US-20-041 | Là quản trị nền tảng, tôi muốn xuất gói bàn giao dữ liệu tenant, để tỉnh nhận đủ dữ liệu có bản kê ký, kiểm chứng được ngoài hệ thống. | M | 5 | MVP, W2 | FR-20-041; UC-20-21 |
| US-20-042 | Là quản trị nền tảng, tôi muốn thực hiện chấm dứt tenant, để tỉnh biến khỏi nền tảng; mã tenant không bao giờ được dùng lại. | M | 5 | MVP, W2 | FR-20-042; UC-20-22 |
| US-20-043 | Là quản trị nền tảng, tôi muốn có lịch sử vòng đời và quyết định, để người kiểm toán đọc được lịch sử tenant trên một màn. | M | 2 | MVP, W2 | FR-20-043; UC-20-23 |
| US-20-044 | Là quản trị nền tảng, tôi muốn hệ thống thông báo thay đổi trạng thái tenant, để đầu mối tỉnh nhận thư trong ≤ 5 phút sau khi trạng thái đổi. | M | 2 | MVP, W2 | FR-20-044; UC-20-23 |

: Story của epic EP-20-F Vòng đời

#### EP-20-G · Sáp nhập

Epic gồm 8 story, 26 điểm (8 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-045 | Là quản trị nền tảng, tôi muốn lập kế hoạch sáp nhập, để có kế hoạch sáp nhập được duyệt, sẵn sàng chuyển dữ liệu. | M | 5 | MVP, W2 | FR-20-045; UC-20-24, 20-25 |
| US-20-046 | Là quản trị nền tảng, tôi muốn lập bảng ánh xạ sáp nhập, để bảng ánh xạ đủ, mọi dòng bắt buộc có quyết định. | M | 2 | MVP, W2 | FR-20-046; UC-20-24 |
| US-20-047 | Là quản trị nền tảng, tôi muốn chạy thử sáp nhập, để PA có con số để báo lãnh đạo và lên lịch cửa sổ chuyển. | M | 2 | MVP, W2 | FR-20-047; UC-20-25 |
| US-20-048 | Là quản trị nền tảng, tôi muốn điều phối chuyển dữ liệu theo phân hệ, để UI-20-10 hiện thanh tiến độ từng phân hệ, số bản ghi, xung đột. | M | 5 | MVP, W2 | FR-20-048; UC-20-26 |
| US-20-049 | Là quản trị nền tảng, tôi muốn xử lý xung đột sáp nhập, để không bản ghi nào bị ghi đè ngoài ý muốn. | M | 2 | MVP, W2 | FR-20-049; UC-20-27 |
| US-20-050 | Là quản trị nền tảng, tôi muốn chuyển định danh và cấp song song thông tin xác thực HTTT, để người dùng đăng nhập được ở tỉnh đích; HTTT có thời gian chuyển dần. | M | 2 | MVP, W2 | FR-20-050; UC-20-28 |
| US-20-051 | Là quản trị nền tảng, tôi muốn chuyển tiếp lượt gọi và chuyển tenant nguồn sang MERGED, để HTTT cũ gọi địa chỉ cũ vẫn nhận phản hồi từ tỉnh đích, kèm header `Deprecation` và `Sunset` ngày kết thúc chuyển tiếp. | M | 5 | MVP, W2 | FR-20-051; UC-20-28 |
| US-20-052 | Là quản trị nền tảng, tôi muốn kết thúc sáp nhập sau thời gian chuyển tiếp, để tỉnh nguồn đóng hẳn; lượt gọi địa chỉ cũ nhận ERR-20-102. | M | 3 | MVP, W2 | FR-20-052; UC-20-29 |

: Story của epic EP-20-G Sáp nhập

#### EP-20-H · Tổ chức

Epic gồm 6 story, 15 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-053 | Là quản trị tỉnh, tôi muốn quản lý danh mục tổ chức, để cây tổ chức của tỉnh luôn đúng, mọi phân hệ dùng chung. | M | 3 | MVP, W2 | FR-20-053; UC-20-30 |
| US-20-054 | Là quản trị tỉnh, tôi muốn hiệu lực, giải thể, sáp nhập tổ chức có tổ chức kế thừa, để bộ máy mới có hiệu lực, dữ liệu cũ vẫn tra được theo tên cũ. | M | 3 | MVP, W2 | FR-20-054; UC-20-31 |
| US-20-055 | Là quản trị tỉnh, tôi muốn nhập tổ chức từ Excel, CSV có xem trước và xuất, để hàng trăm tổ chức vào danh mục trong vài phút. | M | 3 | MVP, W2 | FR-20-055; UC-20-30 |
| US-20-056 | Là quản trị tỉnh, tôi muốn hệ thống đồng bộ tổ chức khi sắp xếp đơn vị hành chính, để tổ chức cấp xã theo kịp sắp xếp ĐVHC. | S | 2 | MVP, W2 | FR-20-056; UC-20-31 |
| US-20-057 | Là quản trị nền tảng, tôi muốn API đọc tổ chức cho phân hệ khác, để mọi phân hệ dùng cùng một cây tổ chức. | M | 2 | MVP, W2 | FR-20-057; UC-20-19 |
| US-20-058 | Là quản trị tỉnh, tôi muốn đánh dấu và tra cứu tổ chức chủ quản dữ liệu, để danh sách chủ quản dữ liệu rõ ràng cho cả tỉnh. | S | 2 | MVP, W2 | FR-20-058; UC-20-30 |

: Story của epic EP-20-H Tổ chức

#### EP-20-I · Phát hành sản phẩm

Epic gồm 6 story, 14 điểm (3 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-059 | Là quản trị nền tảng, tôi muốn danh mục phiên bản sản phẩm, để danh mục phiên bản đầy đủ, truy được tới digest. | M | 2 | MVP, W2 | FR-20-059; UC-20-32 |
| US-20-060 | Là quản trị nền tảng, tôi muốn có kênh phát hành và đăng ký kênh của tenant, để mỗi tenant gắn một kênh; bản mới đi qua thí điểm trước. | M | 2 | MVP, W2 | FR-20-060; UC-20-32 |
| US-20-061 | Là quản trị nền tảng, tôi muốn lập kế hoạch nâng cấp theo sóng và cửa sổ bảo trì, để lịch nâng cấp rõ cho từng tỉnh. | M | 3 | MVP, W2 | FR-20-061; UC-20-33 |
| US-20-062 | Là quản trị nền tảng, tôi muốn hệ thống theo dõi nâng cấp, dừng sóng, quay lui, để sự cố nâng cấp bị chặn ở sóng nhỏ. | S | 5 | MVP, W2 | FR-20-062; UC-20-34 |
| US-20-063 | Là quản trị nền tảng, tôi muốn thông báo phát hành và lịch bảo trì tới tỉnh, để tỉnh biết trước lịch bảo trì. | S | 1 | MVP, W2 | FR-20-063; UC-20-33 |
| US-20-064 | Là quản trị tỉnh, tôi muốn xem phiên bản, ghi chú phát hành, lịch bảo trì của tỉnh, để tỉnh tự tra cứu, giảm hỏi đáp. | S | 1 | MVP, W2 | FR-20-064; UC-20-11 |

: Story của epic EP-20-I Phát hành sản phẩm

#### EP-20-J · Dịch vụ cho phân hệ khác và quản trị

Epic gồm 6 story, 10 điểm (4 story mức M).

| US | Câu chuyện người dùng | ƯT | Điểm | Đợt, wave | FR; UC |
|-----------|------------------------------------------------|----|--------|-----------|--------------|
| US-20-065 | Là quản trị nền tảng, tôi muốn registry tenant cho phân hệ khác, để một nguồn tra tenant cho cả nền tảng. | M | 2 | MVP, W2 | FR-20-065; UC-20-19 |
| US-20-066 | Là quản trị nền tảng, tôi muốn hệ thống thực thi trạng thái tenant ở data plane và control plane, để trạng thái tenant có hiệu lực ở mọi nơi trong ≤ 60 giây. | M | 2 | MVP, W2 | FR-20-066; UC-20-19 |
| US-20-067 | Là quản trị nền tảng, tôi muốn có bảng điều khiển nền tảng đa tenant, để vận hành phát hiện vấn đề sớm. | S | 1 | MVP, W2 | FR-20-067; UC-20-35 |
| US-20-068 | Là quản trị nền tảng, tôi muốn có nhật ký kiểm toán thao tác PH-20, để truy được ai làm gì, vì sao. | M | 1 | MVP, W2 | FR-20-068; UC-20-36 |
| US-20-069 | Là vận hành nền tảng, tôi muốn có tham số 20.* của phân hệ, để hành vi PH-20 chỉnh được có kiểm soát. | M | 2 | MVP, W2 | FR-20-069; UC-20-36 |
| US-20-070 | Là quản trị nền tảng, tôi muốn hệ thống điều phối kiểm thử rò rỉ chéo tenant định kỳ, để bằng chứng cách ly hằng ngày cho thẩm định an toàn. | S | 2 | MVP, W2 | FR-20-070; UC-20-35 |

: Story của epic EP-20-J Dịch vụ cho phân hệ khác và quản trị

<!-- /sinh:danh-sach -->

## 7. Nhập vào công cụ quản lý công việc

Backlog được nhập một lần vào công cụ quản lý công việc ở đầu W1, sau đó công cụ là nơi theo dõi trạng thái hằng ngày. Dự án phát triển trên GitHub và bàn giao GitLab on-prem (Q353); hai tệp CSV dưới đây cho Jira và GitLab, đều sinh cùng lúc với tài liệu.

### 7.1. Tệp Jira

Tệp `02-yeu-cau/backlog/D02-05-backlog-jira.csv` (UTF-8 có BOM để Excel đọc đúng tiếng Việt) gồm 195 dòng epic và 1.287 dòng story. Quan hệ epic và story dùng cột `Issue ID` và `Parent ID` theo trình nhập CSV của Jira Cloud.

| Cột CSV | Trường Jira | Giá trị |
|---|---|---|
| Issue ID | (ánh xạ tạm) | `EP-07-C`, `US-07-021` |
| Parent ID | Parent | Mã epic của story |
| Issue Type | Issue Type | `Epic` hoặc `Story` |
| Summary | Summary | `US-07-021 · Nhập bản ghi từ Excel/CSV vào bản nháp` |
| Description | Description | Câu chuyện, truy vết, tiêu chí chấp nhận trong khối `{code:gherkin}` |
| Priority | Priority | M → High, S → Medium, C → Low |
| Story Points | Story Points | 1, 2, 3, 5, 8 |
| Labels (3 cột) | Labels | `PH-07`, đợt (`MVP`, `Đợt-2`…), `de-nghi-tach` nếu có |
| Fix Version | Fix Version/s | Wave (`W1`…`W5`, `Sau G5`) |
| Component | Component/s | `PH-07` |

: Ánh xạ cột CSV sang trường Jira

Cách nhập: tạo trước các phiên bản W1…W5, Sau G5 và các thành phần PH-00…PH-20 trong dự án Jira; vào System › External System Import › CSV; chọn tệp, mã hóa UTF-8; ánh xạ cột theo bảng; chạy thử với 20 dòng đầu trước khi nhập toàn bộ.

### 7.2. Tệp GitLab

Tệp `02-yeu-cau/backlog/D02-05-backlog-gitlab.csv` gồm hai cột `title` và `description` theo trình nhập issue CSV của GitLab. Thuộc tính khác được truyền bằng quick action ở cuối mô tả, GitLab thực thi khi nhập: `/label ~"PH-07" ~"EP-07-C" ~"MVP" ~"ưu tiên::M"`, `/weight 3`, `/milestone %"W2"`. Epic được thể hiện bằng nhãn `EP-…` vì epic của GitLab cần bản Premium; nếu tỉnh có bản Premium thì tạo epic theo nhãn và gom issue bằng tìm kiếm nhãn.

Cách nhập: tạo trước milestone W1…W5, Sau G5 trong project; vào Issues › Import CSV; GitLab gửi thư báo kết quả. Nhãn chưa có được quick action tạo tự động.

### 7.3. Tệp Gherkin

Thư mục `02-yeu-cau/backlog/gherkin/` có 21 tệp `us-{ph}.feature`, dòng đầu `# language: vi`, mỗi kịch bản mang thẻ `@US-…` và `@FR-…`. Tệp là tiêu chí chấp nhận mức story; khung kiểm thử tự động của từng phân hệ (D05-02) dùng thẻ `@FR-…` để nối ca kiểm thử chi tiết với story.

## 8. Duy trì backlog và truy vết

Backlog thay đổi trong suốt dự án; chương này nêu ai được đổi gì và cách giữ tài liệu khớp với công cụ.

### 8.1. Quyền thay đổi

Ranh giới quyền theo vai trò PO hai phía của D01-02 §3.4: nhà thầu quyết cách chia story, chủ đầu tư quyết phạm vi.

| Thay đổi | Ai quyết | Ở đâu | Ghi nhận |
|---|---|---|---|
| Sửa câu chuyện, tiêu chí của story ban đầu | PO nhà thầu | Sửa FR ở FRS, chạy lại script | PR sửa FRS và D02-05 |
| Tách story | PO nhà thầu ở buổi làm rõ | Công cụ quản lý công việc, số từ 501 | Đồng bộ về D02-05 ở cổng kế tiếp |
| Ước lượng lại điểm | Đội Scrum (planning poker) | Công cụ | Điểm ban đầu ở tài liệu giữ nguyên làm đường cơ sở |
| Đổi thứ tự trong wave | PO nhà thầu | Công cụ | Không cần thủ tục |
| Đổi wave, thêm hoặc bỏ story mức M | PO chủ đầu tư | Quy trình thay đổi D01-02 chương 11 | Biên bản thay đổi; hoán đổi vượt 10% điểm wave phải qua hội đồng |

: Quyền thay đổi backlog

### 8.2. Đồng bộ tài liệu với công cụ

Ở mỗi cổng G1…G5, PO nhà thầu xuất danh sách story từ công cụ (mã, trạng thái, sprint, điểm thật) và cập nhật ba nơi: (1) story tách thêm được ghi bổ sung vào chương 6 bằng tay trong một mục "Story tách thêm" của phân hệ; (2) RTM D00-03 nhận cột trạng thái `US`; (3) điểm thật và vận tốc thật thay giả định GĐ-BL-01, GĐ-BL-02. Giữa hai cổng, công cụ là nguồn đúng về trạng thái, FRS là nguồn đúng về nội dung.

### 8.3. Chạy lại script

Ba lệnh dưới đây chạy từ gốc repo, không cần cài thêm gói ngoài thư viện chuẩn Python 3.

```bash
python3 datahub-docs/02-yeu-cau/backlog/tools/sinh_backlog.py --kiem   # in thống kê, không ghi
python3 datahub-docs/02-yeu-cau/backlog/tools/sinh_backlog.py          # ghi chương 4–6, phụ lục, .feature, CSV
python3 datahub-docs/build/tools/kiem_tra_ma.py                       # soát mã và liên kết
```

Script đọc khối `::: dac-ta` của SRS và FRS bằng `doc_frs.py`; FR viết sai khuôn (thiếu mục, sai nhãn) sẽ thiếu thành phần trong story, nên chạy `--kiem` sau mỗi lần sửa FRS lớn.

## 9. Giả định, câu hỏi mở và đề nghị đồng bộ

### 9.1. Giả định

Theo quy ước của bộ tài liệu, thiếu số liệu thật thì dùng giả định có ghi cơ sở; bốn giả định dưới đây được thay bằng số đo thật sau ba sprint đầu W1.

| Mã | Giả định | Cơ sở | Kiểm chứng |
|---|---|---|---|
| GĐ-BL-01 | 1 điểm ≈ 0,9 người-ngày làm trọn story | Tổng điểm so với nỗ lực gói giao diện, lập trình, kiểm thử ở D01-02 §2.4 | Vận tốc thật ba sprint đầu W1 |
| GĐ-BL-02 | Vận tốc nền 49 điểm mỗi đội 5–6 người mỗi sprint | 5,5 người × 10 ngày × 80% tập trung ÷ 0,9 | Như trên |
| GĐ-BL-03 | Đội giao diện C được tính chung sức chứa với đội A, B | Story gồm cả giao diện và backend | Phân rã task trong sprint |
| GĐ-BL-04 | Story mức S, C có thể dời trong wave mà không ảnh hưởng tiêu chí cổng | Tiêu chí cổng D01-02 chỉ đòi mọi FR mức M | Kế hoạch wave |

: Giả định của backlog

### 9.2. Câu hỏi mở

> **Câu hỏi mở Q370:** Điểm ban đầu của PH-04 (174 điểm) thấp so với nỗ lực 34 người-tháng ở D01-02. Có cần thêm yếu tố "độ phức tạp giao diện" (số thành phần của màn, trình thiết kế) vào công thức, hay chỉ ước lượng lại PH-04 bằng planning poker ở sprint đầu W1? Đề xuất: ước lượng lại, giữ công thức đơn giản.

> **Câu hỏi mở Q371:** W5 thiếu khoảng 135 điểm. Chọn đưa đội G toàn thời gian vào phát triển sau khi tenant tỉnh 2 ổn định, hay dời story mức S, C của PH-16, PH-17 ra sau G5? Quyết định ở cổng G4.

> **Câu hỏi mở Q372:** Công cụ quản lý công việc của tỉnh thí điểm là Jira hay GitLab (Q353 chốt GitLab on-prem khi bàn giao)? Nếu chỉ GitLab bản miễn phí, epic chỉ là nhãn và báo cáo burndown theo epic phải tự dựng.

| Mã | Câu hỏi | Tình trạng | Người trả lời |
|---|---|---|---|
| Q370 | Ước lượng lại PH-04 hay thêm yếu tố giao diện | Mở, có đề xuất | PO nhà thầu, kiến trúc sư |
| Q371 | Xử lý thiếu sức chứa W5 | Mở, quyết ở G4 | PO chủ đầu tư |
| Q372 | Công cụ quản lý công việc | Mở | Chủ đầu tư |

: Câu hỏi mở của D02-05

### 9.3. Đề nghị đồng bộ

Các điểm sau gom vào đợt đồng bộ cuối, không sửa tài liệu khác trong lần viết này:

1. D00-01 §3.1: thêm họ mã `EP-{PH}-{chữ}` (epic, tài liệu gốc D02-05) và quy ước số story tách thêm từ 501.
2. D00-04 §3.1: thêm dải câu hỏi mở Q370–Q374 cho D02-05, Q375–Q379 cho D02-06; thêm giả định GĐ-BL-01…04.
3. D00-03: thêm cột `US` vào RTM (mỗi FR một US cùng số).
4. Bốn FR chưa có UC hiện thực: FR-04-084, FR-05-039, FR-07-053, FR-10-048; tập UC tương ứng cần thêm FR vào trường "FR hiện thực" hoặc ghi lý do.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 1.287 story, 195 epic sinh từ SRS và 20 FRS; quy tắc chuyển đổi, ước lượng, kế hoạch wave, CSV Jira và GitLab, tệp Gherkin |
