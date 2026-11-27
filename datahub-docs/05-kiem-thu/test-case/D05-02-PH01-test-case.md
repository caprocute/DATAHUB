---
ma_tai_lieu: D05-02-PH01
ten: Kịch bản và test case phân hệ PH-01 Kết nạp hệ thống thông tin
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, cán bộ ATTT, chủ đầu tư (UAT), hội đồng thẩm định
phan_he: PH-01
mo_ta: Kịch bản và test case của PH-01 gồm ca chức năng, bảo mật, phi chức năng, nghiệm thu người dùng tương đương hệ cũ và ma trận truy vết FR, UC, API, UI, ERR.
tai_lieu_lien_quan: D02-03-PH01; D02-04-PH01; D03-02-PH01; D03-03-PH01; D03-04-PH01; D03-06-PH01; D05-01; D02-08
---

# D05-02-PH01 · Kịch bản và test case Kết nạp hệ thống thông tin

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh ba điều:

- PH-01 làm đúng mọi yêu cầu đã duyệt ở D02-03-PH01: hồ sơ kết nạp, thẩm định, phê duyệt, cấp định danh, vòng đời thành viên, rà soát quyền, danh bạ đầu mối.
- Không mất chức năng của hệ cũ: danh sách và tạo Application của APIM (LGC-APIM-019; 020), quản lý publisher và subscriber của Hub (LGC-HUB-010, 011).
- Không có đường nào để bí mật của HTTT lộ ra ngoài lần bàn giao một lần, không có đường nào để quyền của HTTT rộng hơn phạm vi đã được thẩm định, và không có đường nào để tỉnh này thấy hay sửa hồ sơ của tỉnh khác.

**Phạm vi.** Gồm <!--gen:so-ts-->35<!--/gen--> kịch bản (TS-01-01…35) với <!--gen:so-tc-->151 (TC-01-001…151; 97 ca P1)<!--/gen--> test case và 11 kịch bản nghiệm thu người dùng (UAT-01…11). Mỗi FR mức M có ít nhất một ca dương và một ca âm; mọi FR, UC, API, UI, sự kiện EVT và mã lỗi ERR đều có ít nhất một ca. Ma trận ở chương 8 sinh tự động từ chính tài liệu này bằng `ph01/tools/gen_matrix.py`.

**Căn cứ.** Tài liệu cùng bộ PH-01 (FRS D02-03-PH01, use case D02-04-PH01, SDD D03-02-PH01, CSDL D03-03-PH01, API D03-04-PH01, màn hình D03-06-PH01); ma trận phân quyền D02-08; kế hoạch kiểm thử D05-01; cổng CI D04-02; cấu trúc theo ISO/IEC/IEEE 29119-3; yêu cầu ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP, TCVN 14423:2026; căn cứ nghiệp vụ CMP-LAW-03, CMP-LAW-05, CMP-LAW-09.

**Điểm cần hội đồng lưu ý.** Sáu nhóm ca bắt buộc đạt 100 % trước khi phát hành:

- không lộ bí mật, kiểm bằng giá trị mồi `DH-CANARY` (TS-01-29);
- cách ly tenant ở API, CSDL (RLS) và kho tệp (TS-01-30);
- bốn mắt: người lập hồ sơ không thẩm định, phê duyệt; người nộp không kích hoạt PRODUCTION; người đề nghị chấm dứt không duyệt (TS-01-31);
- liên kết bàn giao mở được đúng một lần, đúng người, và khóa sau số lần sai quy định (TS-01-15);
- cắt quyền HTTT trong không quá 60 giây khi tạm ngừng, chấm dứt, thao tác khẩn (TS-01-20, 22, 33);
- trần phạm vi không bao giờ rộng hơn phạm vi được duyệt, dữ liệu bí mật nhà nước bị từ chối tuyệt đối (TS-01-04, 10, 12, 23).

Mã W1 hiện có chỉ có khung nhận hồ sơ tối giản; các ca ở đây là tiêu chí nghiệm thu của công việc mới. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh T01 quy mô vừa, 200 HTTT) vì chưa có dữ liệu thật; các chỉ tiêu thời gian lấy từ NFR-01 của FRS.

## 0. Giới thiệu

### 0.1. Mục đích, phạm vi và người đọc

Tài liệu là tập 7 của bộ PH-01. Người đọc chính là kiểm thử viên (viết, chạy ca), kỹ sư (viết ca tự động), cán bộ ATTT (ca TS-01-29…31, 33) và chủ đầu tư (UAT mục 7). Ca được viết để chạy ngay trên môi trường SIT với bộ dữ liệu mục 2, không cần hỏi lại.

### 0.2. Thuật ngữ và tài liệu tham chiếu

Mỗi ca ở chương 4 và 5 được đặc tả bằng một bảng hai cột: Loại, Ưu tiên, Tự động, Truy vết, Tiền điều kiện và dữ liệu, Các bước, Kết quả mong đợi. Thuật ngữ dùng chung với D02-03-PH01 §1.4 và D00-01. Tài liệu tham chiếu: D05-01 (kế hoạch kiểm thử tổng thể, cổng RG-1…5), D02-03-PH01 (FR, BR, ERR), D02-04-PH01 (UC), D03-04-PH01 (API), D03-06-PH01 (màn hình), D02-08 (quyền); bảng tính [D05-02-PH01-test-case.xlsx](ph01/D05-02-PH01-test-case.xlsx) sinh từ tài liệu này.

### 0.3. Cấu trúc tài liệu

Bảng dưới liệt kê chín chương của tài liệu và nội dung chính của từng chương.

| Chương | Nội dung |
|---|---|
| 1 | Phạm vi, chiến lược, môi trường, tiêu chí vào ra, quy ước mã |
| 2 | Dữ liệu kiểm thử: tenant, người dùng, HTTT mẫu, hệ giả lập, tệp |
| 3 | Danh sách kịch bản và máy trạng thái được kiểm thử |
| 4 | Kịch bản và test case chức năng (TS-01-01…28) |
| 5 | Kịch bản phi chức năng và xuyên suốt (TS-01-29…35) |
| 6 | Thủ tục kiểm thử thủ công |
| 7 | Nghiệm thu người dùng tương đương hệ cũ |
| 8 | Ma trận truy vết sinh tự động |
| 9 | Tự động hóa và tệp đi kèm |

: Cấu trúc tài liệu D05-02-PH01

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

Chương này nói kiểm thử cái gì, ở mức nào, trên môi trường nào, khi nào được vào và ra, và cách đọc một ca. Chiến lược chung theo D05-01; chương chỉ nêu phần riêng của PH-01: PH-01 không nằm trên đường dữ liệu nên trọng tâm là đúng quy trình duyệt, an ninh bí mật và tốc độ cắt quyền, không phải hiệu năng.

### 1.1. Đối tượng kiểm thử

Bảng dưới trình bày đối tượng kiểm thử.

| Đối tượng | Mô tả | Kịch bản chính |
|---|---|---|
| Dịch vụ hồ sơ | Hồ sơ HTTT, hồ sơ kỹ thuật, nhu cầu khai thác, đầu mối, tài liệu đính kèm, kiểm tra hợp lệ, nộp | TS-01-01…07 |
| Dịch vụ thẩm định | Phân công, thẩm định ba bước song song, tham vấn, trả bổ sung, phê duyệt | TS-01-08…12 |
| Bộ điều phối saga và dịch vụ định danh | Cấp định danh SANDBOX, đăng ký khóa, bàn giao một lần, kiểm thử, kích hoạt, xoay vòng, thu hồi | TS-01-13…19 |
| Dịch vụ vòng đời | Tạm ngừng, khôi phục, chấm dứt, thao tác khẩn, thay đổi sau kết nạp, đồng bộ trạng thái | TS-01-20…24 |
| Dịch vụ rà soát quyền và danh bạ | Kỳ rà soát, phiếu xác nhận, danh bạ đầu mối | TS-01-25…27 |
| Di trú, tham số, thống kê | Nhập từ hệ cũ, tham số `onboarding.*`, thống kê | TS-01-28 |
| Xuyên suốt | Bí mật, cách ly tenant, phân quyền, hiệu năng, chịu lỗi, giao diện, hợp đồng API | TS-01-29…35 |

: Đối tượng kiểm thử của PH-01

### 1.2. Mức kiểm thử

Bảng dưới trình bày mức kiểm thử.

| Mức | Công cụ | Phạm vi ở PH-01 | Cổng |
|---|---|---|---|
| UT | JUnit 5, Vitest | Máy trạng thái hồ sơ, quy tắc đề xuất nhóm HTTT, tính hạn ngày làm việc, kiểm tra hợp lệ | CI-1 |
| IT | Testcontainers (PostgreSQL 16, Kafka, OpenBao, Keycloak) | API, outbox, saga, RLS | CI-2, CI-3 |
| DB | pgTAP | RLS `ph01_onboarding`, ràng buộc duy nhất mã HTTT | CI-3 |
| API | RestAssured, Schemathesis | Hợp đồng OpenAPI, mã lỗi RFC 9457 | CI-5 |
| E2E | Playwright | UI-01-01…17, đường chính theo UC | CI-6 |
| k6 | k6 | NFR-01-001…004 | RG |
| Chaos | Litmus | Mất PH-12, PH-03, OpenBao, Kafka | RG |
| ZAP | OWASP ZAP | Liên kết bàn giao, tra cứu danh bạ | CI-7 |
| Thủ công | Phiên khám phá, UAT | Mục 6, 7 | RG |

: Mức kiểm thử ở PH-01

### 1.3. Môi trường kiểm thử

Bảng dưới trình bày môi trường kiểm thử.

| Môi trường | Mục đích | Ghi chú |
|---|---|---|
| CI | UT, IT, DB, API | Container tạm; PH-12, PH-03, PH-20, PH-18, quét mã độc là giả lập (mục 2.4) |
| SIT | E2E, Chaos, bảo mật | Keycloak, OpenBao, Kafka, APISIX thật cấu hình nhỏ; tenant `T68`, `T01`; có người dùng cấu hình sai có chủ đích (mục 2.2) |
| PERF | k6 | Cấu hình QM-VUA; dữ liệu tỉnh vừa GĐ-07 |
| UAT | Nghiệm thu mục 7 | Dữ liệu nhập từ ảnh chụp ẩn danh của hệ cũ; không có người dùng cấu hình sai |

: Môi trường kiểm thử

```{.mermaid caption="Môi trường SIT của PH-01 và các hệ giả lập"}
flowchart TB
  T[Bộ chạy ca: JUnit, Playwright, k6] --> C[dh-connect, PH-01]
  C --> DB[(pg-core, ph01_onboarding)]
  C --> OB[OpenBao thật]
  C --> K[Kafka, Debezium thật]
  C --> S12[Giả lập PH-12]
  C --> S03[Giả lập PH-03]
  C --> S20[Giả lập PH-20, PH-18, PH-13]
  C --> AV[Giả lập quét mã độc]
  K --> SINK[Bộ thu sự kiện thử]
  S18[Hộp thư mail-sink] --- S20
```

Hình cho thấy PH-01 và các thành phần thật (CSDL, OpenBao, Kafka) được dùng nguyên bản để kiểm RLS, bí mật và outbox, còn mọi phân hệ ngoài đều là giả lập có công tắc lỗi (`fail`, `slow`) để dựng ca saga, chịu lỗi và cắt quyền mà không phụ thuộc phân hệ khác.

### 1.4. Tiêu chí vào và ra

Các ý dưới đây trình bày tiêu chí vào và ra.

- **Vào.** FRS, UC, SDD, CSDL, API, màn hình đã duyệt; hợp đồng OpenAPI chạy được ở CI-5; bộ dữ liệu mục 2 nạp được bằng `ph01/seed/` qua API.
- **Ra cho phát hành (RG-3).** 100 % ca P1 đạt; 100 % ca của sáu nhóm bắt buộc ở phần Tóm tắt; không còn lỗi Nghiêm trọng hay Cao; mọi FR mức M có ca dương và ca âm đạt; UAT-01…11 đạt; chỉ tiêu NFR-01-001…004, 008, 021 đạt ở PERF.
- **Tạm dừng.** Ba ca P1 liên tiếp hỏng vì môi trường; hoặc phát hiện lộ bí mật (dừng toàn bộ, báo cán bộ ATTT).

### 1.5. Quy ước mã và cách trình bày

Kịch bản có mã `TS-01-nn`, test case `TC-01-nnn`. Mã không tái sử dụng: ca bị hủy ghi "Đã hủy" và giữ mã. Mỗi test case là một khối thống nhất với D05-02-PH05, D05-02-PH19:

- Tiêu đề: mã, tên ca.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, API, E2E, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC.
- **Tiền điều kiện, dữ liệu**: mã dữ liệu ở mục 2.
- **Các bước**: đánh số. Đường dẫn API tương đối với `/api/onboarding/v1`; hành động có dạng `POST /systems/{systemCode}:submit`.
- **Kết quả mong đợi**: mã HTTP, mã lỗi, trạng thái sau, sự kiện, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-01-052 (thiếu quyền `PERM-01-*` hoặc scope) |
| 404-ẩn | `404` với ERR-01-001, thân giống hệt "không tồn tại", "thuộc tenant khác" và "ngoài phạm vi vai trò" trừ `traceId` (BR-01-030) |
| KT: có (hành động) | Có bản ghi kiểm toán tới PH-13 với hành động đó, đủ trường FR-00-041, không chứa bí mật |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{mã}` | Đúng một bản tin trên topic của sự kiện đó (mục 9.3 của FRS), CloudEvents, có `dhtenant`, khóa bản ghi là `systemCode` |
| EVT: không | Sau 10 giây không có dòng mới trong outbox của `ph01_onboarding` và không có bản tin trên topic liên quan |
| MFA mới | Phiên có `acr` cao trong 5 phút (NFR-01-012); thiếu thì `403` ERR-01-035 |
| Mồi sạch | Tìm chuỗi `DH-CANARY-{ca}` trong phản hồi API, log ứng dụng 5 phút, vết OTel, bảng `ph01_onboarding.*`, outbox, Kafka, tệp xuất, thư giả lập: không thấy (trừ phản hồi mở bàn giao ở ca nói rõ) |

: Quy ước ký hiệu trong ca kiểm thử

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi với nhãn `PH-01`, mã TC, mã FR, mức và `traceId`. Luôn mức Nghiêm trọng: lộ giá trị bí mật ở bất kỳ đâu ngoài phản hồi mở bàn giao; mở được liên kết bàn giao lần hai hoặc bởi người không phải đầu mối; đọc hay sửa được hồ sơ của tenant khác; người tự duyệt hồ sơ của mình; định danh có scope rộng hơn trần được duyệt; dữ liệu bí mật nhà nước vào được hồ sơ; HTTT đã tạm ngừng vẫn gọi được API sau 60 giây. Báo cáo hằng đêm từ JUnit, Playwright, k6, đối chiếu ma trận chương 8.

## 2. Dữ liệu kiểm thử

Mọi dữ liệu là giả lập (văn bản căn cứ, số điện thoại, thư điện tử, tên đơn vị đều không phải thật). Nạp bằng `ph01/seed/` qua API, không chèn SQL trực tiếp, trừ dữ liệu của hệ giả lập.

### 2.1. Tenant

Bảng dưới trình bày tenant.

| Mã | Ý nghĩa | Ghi chú |
|---|---|---|
| `T68` | Tỉnh chính (giả lập) | Tham số mặc định; `contact.allowedEmailDomains = ["gov.vn"]`; có đủ tổ chức Sở Tư pháp, Văn phòng UBND, Sở KH&CN |
| `T01` | Tỉnh đối chứng rò rỉ | Có HTTT **trùng mã** `HT-QLVB` với T68 nhưng khác nội dung, để phát hiện trả nhầm |
| `T90` | Tỉnh kiểm thử cho ca đổi tham số | Chỉ dùng cho TS-01-28 và ca tải, tránh ảnh hưởng T68 |

: Tenant kiểm thử

### 2.2. Người dùng

Tên nhân vật trùng D02-04-PH01. Mọi người dùng vai trò TA, SO, IE có TOTP thử để kiểm thử xác thực lại hai yếu tố.

| Mã | Tenant | Vai trò | Nhân vật | Mục đích |
|---|---|---|---|---|
| U-T68-OR1 | T68 | OR của Sở Tư pháp (ROLE-ORG_REQUESTER) | Lan | Người lập hồ sơ chính |
| U-T68-OR2 | T68 | OR của Văn phòng UBND | Khôi | Đầu mối kỹ thuật `HT-DVC`; đối chứng "ngoài tổ chức" |
| U-T68-TECH | T68 | Đầu mối kỹ thuật của `HT-HOTICH` (nhà thầu) | Phúc | Người nhận bàn giao |
| U-T68-TA1 | T68 | TA | Minh | Phân công, phê duyệt, kích hoạt |
| U-T68-TA2 | T68 | TA | Quang | TA thứ hai, kiểm bốn mắt |
| U-T68-IE | T68 | IE | An | Thẩm định kỹ thuật |
| U-T68-SO | T68 | SO | Dũng | Thẩm định ATTT, thao tác khẩn, rà soát |
| U-T68-TO | T68 | TO | Chi | Chỉ xem |
| U-T68-DO | T68 | DO của Sở Tài nguyên | — | Đối chứng "chỉ thấy HTTT có dữ liệu của mình" |
| U-T68-VW | T68 | VW (chỉ `PERM-01-read`) | — | Chỉ đọc |
| U-T68-AU | T68 | AU | Hoa | Kiểm toán, xuất |
| U-PA | PLATFORM | PA | Hà | Tham số nền tảng, nhập hệ cũ |
| U-T68-X1 | T68 | TA + IE (cố ý cấu hình sai, chỉ có ở SIT) | — | Vi phạm tách nhiệm có chủ đích, để kiểm lớp bốn mắt độc lập với lớp vai trò; không tạo ở UAT, PROD |
| U-T01-TA, U-T01-OR | T01 | TA, OR | — | Đối chứng rò rỉ |
| S-INT | — | Token dịch vụ `onboarding:internal-read` | PH-02, 03, 04, 05, 10 | API nội bộ |
| S-RECON | — | Token dịch vụ `onboarding:reconcile` | Tác vụ đối chiếu | API-01-062 |
| S-CB | — | Token dịch vụ `onboarding:provision-callback` | PH-12 giả lập | API-01-087 |
| S-SP, S-SP-T01 | — | Token dịch vụ `onboarding:suspension-proposal` của T68, của T01 | PH-13 giả lập | API-01-089 |

: Người dùng kiểm thử

### 2.3. HTTT mẫu

Bảng dưới trình bày hTTT mẫu.

| Mã | Trạng thái | Đặc điểm |
|---|---|---|
| `HT-HOTICH` | DRAFT | Hộ tịch điện tử Sở Tư pháp, vai trò `CONSUMER`, cấp độ `L3`, mức Hạn chế (cần khóa công khai), hồ sơ `HS-KN-2026-0007` |
| `HT-HOTICH-SS` | SUBMITTED (`IN_REVIEW`) | Ba bước thẩm định đã tạo, chưa có kết luận |
| `HT-HOTICH-OK` | SUBMITTED (`WAITING_APPROVAL`) | Cả ba bước kết luận xong, chờ phê duyệt |
| `HT-HOTICH-AP` | APPROVED (`AWAITING_KEY`) | Đã duyệt, chờ khóa công khai |
| `HT-HOTICH-SB` | APPROVED (sandbox) | SANDBOX có 3 lượt gọi đạt, chờ kích hoạt |
| `HT-QLVB`, `HT-DATDAI` | ACTIVE | Có định danh PRODUCTION; `HT-QLVB` có phụ thuộc ở PH-02, PH-05 (cho ca phân tích tác động) |
| `HT-DVC` | ACTIVE | Mức Nội bộ, còn chuỗi bí mật (giai đoạn chuyển tiếp), đầu mối kỹ thuật Khôi |
| `HT-TUPHAP` | ACTIVE | HTTT của Sở Tư pháp đã kết nạp, dùng cho ca đề nghị thay đổi |
| `HT-CU-TT` | TERMINATED | Mã đã bị giữ vĩnh viễn |
| `HT-TC-KHAC` | ACTIVE ở T01 | Chỉ có ở T01 |

: HTTT mẫu

### 2.4. Hệ giả lập

Bảng dưới trình bày hệ giả lập.

| Hệ | Giả lập | Điều khiển lỗi |
|---|---|---|
| PH-12 (Keycloak, OPA) | Máy chủ giả có lệnh đặt `fail`, `slow`, `duplicate-client` | Ca saga, thu hồi |
| PH-03 (APISIX control) | Giả lập consumer, danh sách chặn; đo thời gian chặn | Ca cắt quyền 60 giây |
| OpenBao | Thật, cấu hình dev | Dừng bằng Chaos |
| PH-20 (danh mục tổ chức) | Giả lập, có tổ chức ngừng hoạt động; phát được EVT-20-13 (`DISSOLVED`, `MERGED`) | Ca ERR-01-004, 046; ca đổi chủ quản hàng loạt |
| PH-18 | Hộp thư giả lập `mail-sink` (đọc được nội dung thư) | Ca không gửi bí mật qua thư |
| Quét mã độc | Giả lập, nhận tệp EICAR là mã độc | ERR-01-014 |
| PH-13 | Bộ thu kiểm toán giả lập; gọi được API-01-089 bằng S-SP | Đối chiếu KT; ca đề xuất tạm ngừng |
| PH-02, 04, 05, 10 | Giả lập `dependents` trả danh sách phụ thuộc | TS-01-20 |
| Hệ cũ | Tệp xuất ẩn danh của Application (APIM) và publisher, subscriber (Hub) | TS-01-28 |

: Hệ giả lập

### 2.5. Tệp mẫu

Bảng dưới trình bày tệp mẫu.

| Mã | Nội dung |
|---|---|
| F-PDF-VB | Văn bản căn cứ pháp lý giả lập, 200 KB |
| F-PDF-BIG | 21 MB (vượt `attachment.maxSizeMb = 20`) |
| F-EXE | Tệp `.exe` (định dạng không cho phép) |
| F-EICAR | Tệp thử mã độc chuẩn |
| F-JWKS-OK, F-JWKS-BAD | Khóa công khai hợp lệ, và khóa RSA 1024 bit |
| F-CSR-OK, F-CSR-BAD | Yêu cầu chứng thư hợp lệ, và sai chủ thể |
| F-LEGACY-OK, F-LEGACY-BAD | Tệp nhập hệ cũ đúng, và thiếu cột bắt buộc; F-LEGACY-DUP có mã trùng |
| F-LEGACY-SECRET | Tệp hệ cũ có cột bí mật để thử bỏ bí mật |

: Tệp mẫu

### 2.6. Nguyên tắc dữ liệu

Mỗi ca tự tạo HTTT riêng có tiền tố `tc-` hoặc `TC-` để chạy song song; ca không sửa dữ liệu mẫu ở mục 2.3 trừ khi ghi rõ và khôi phục sau ca. Dữ liệu quy mô cho ca tải theo GĐ-07 (tỉnh vừa): 200 HTTT, 500 định danh, 2.000 đầu mối; ca NFR-01-017 mở rộng tới 1.000 HTTT, 5.000 định danh, 20.000 đầu mối. Đồng hồ thử được điều khiển bằng `Clock` giả (CI) hoặc lệnh chỉnh giờ thử (SIT) để chạy ca hạn mà không phải chờ ngày thật.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

Bảng sau sinh tự động từ các mục `### TS-01-nn` bằng `ph01/tools/fill_doc.py`; không sửa tay.

<!--gen:ts-table-->
| Kịch bản | Tên | Mục tiêu | UC | Số ca |
|---|---|---|---|---|
| TS-01-01 | Danh sách, chi tiết, lịch sử và xuất HTTT thành viên | Xác nhận danh sách và chi tiết HTTT thay màn "Danh sách Application" của APIM: lọc, tìm, phân trang, đúng phạm vi theo vai trò, không lộ HTTT của tenant khác, xuất đúng quyền | UC-01-01 | 6 |
| TS-01-02 | Tạo hồ sơ nháp, sửa có tự lưu, mẫu văn bản | Xác nhận hồ sơ nháp thay thao tác "Tạo Application": mã bất biến và không dùng lại, tổ chức đúng, địa chỉ `https`, khóa lạc quan, nhận lặp an toàn, tự lưu không mất dữ liệu | UC-01-02 | 7 |
| TS-01-03 | Hồ sơ năng lực kỹ thuật và đề xuất nhóm HTTT | Xác nhận bảng quy tắc đề xuất nhóm 1 đến 4 theo đúng thứ tự ưu tiên, có lời giải thích, và yêu cầu thêm thông tin cho nhóm 3 | UC-01-03 | 3 |
| TS-01-04 | Nhu cầu khai thác, căn cứ pháp lý và tài liệu đính kèm | Xác nhận mỗi mục nhu cầu `CONSUME` có căn cứ pháp lý, dữ liệu bí mật nhà nước bị từ chối tuyệt đối, tệp đính kèm bị chặn theo cỡ, định dạng và mã độc, và tệp lưu riêng theo tenant | UC-01-04 | 6 |
| TS-01-05 | Quản lý đầu mối liên hệ | Xác nhận mỗi HTTT luôn có đầu mối kỹ thuật đang hoạt động, thư công vụ, thay thế đầu mối không để HTTT thiếu, và dữ liệu liên hệ không đi vào sự kiện | UC-01-05 | 4 |
| TS-01-06 | Kiểm tra hợp lệ và nộp hồ sơ | Xác nhận hồ sơ chỉ nộp được khi đủ điều kiện, danh sách thiếu sót đầy đủ một lần, bước thẩm định và hạn được tạo đúng, nộp lặp an toàn | UC-01-06 | 6 |
| TS-01-07 | Theo dõi tiến độ, rút hồ sơ, xóa nháp | Xác nhận đơn vị theo dõi được hồ sơ, rút về nháp khi chưa có kết luận phê duyệt, xóa nháp chưa từng nộp, và nháp quá hạn bị xóa mềm sau nhắc | UC-01-07 | 5 |
| TS-01-08 | Phân công, theo dõi hạn thẩm định, tham vấn | Xác nhận TA phân công đúng người cho từng bước, người không được phân công không ghi được, tham vấn dừng đồng hồ hạn và quá hạn thì leo thang | UC-01-08 | 3 |
| TS-01-09 | Thẩm định kỹ thuật và tác động hạn mức dữ liệu quốc gia | Xác nhận thẩm định kỹ thuật chỉ do người được phân công ghi, nhóm HTTT được xác nhận, phương thức xác thực đúng mức phân loại, và tác động hạn mức quốc gia được tính theo ngưỡng | UC-01-09 | 3 |
| TS-01-10 | Thẩm định căn cứ pháp lý và ATTT theo từng mục | Xác nhận mỗi mục nhu cầu có kết luận riêng, quyền của HTTT không rộng hơn phạm vi được chấp thuận, thẩm định pháp lý do người thực hiện chứ không tự động | UC-01-10 | 3 |
| TS-01-11 | Trả bổ sung và nộp lại hồ sơ | Xác nhận hồ sơ trả bổ sung giữ nguyên nội dung, đồng hồ dừng, và khi nộp lại các bước có dữ liệu không đổi giữ kết luận | UC-01-11 | 2 |
| TS-01-12 | Phê duyệt hoặc từ chối kết nạp | Xác nhận quyết định bốn mắt, xác thực lại hai yếu tố, trần phạm vi đúng phạm vi được duyệt, và HTTT bị từ chối vẫn giữ mã | UC-01-12 | 3 |
| TS-01-13 | Cấp định danh SANDBOX (saga) | Xác nhận saga tạo định danh qua PH-12, PH-03 và OpenBao, không bao giờ cấp scope dữ liệu, thử lại được khi lỗi và an toàn khi gọi lại | UC-01-13 | 3 |
| TS-01-14 | Đăng ký khóa công khai hoặc ký chứng thư | Xác nhận phương thức xác thực theo mức phân loại, khóa yếu bị từ chối, PH-01 không bao giờ giữ khóa riêng | UC-01-14 | 2 |
| TS-01-15 | Bàn giao thông tin xác thực một lần | Xác nhận bí mật chỉ đến tay đúng đầu mối qua liên kết dùng một lần, không đi qua thư điện tử, hủy sau lần mở đầu, và khóa khi mở sai nhiều lần | UC-01-15 | 7 |
| TS-01-16 | Kiểm thử kết nối ở SANDBOX | Xác nhận HTTT chứng minh gọi được API ở môi trường thử bằng dữ liệu giả, đủ số lượt đạt mới sẵn sàng kích hoạt, và định danh SANDBOX không chạm dữ liệu thật | UC-01-16 | 3 |
| TS-01-17 | Kích hoạt môi trường thật (PRODUCTION) | Xác nhận chỉ HTTT đã kiểm thử đạt, đủ điều kiện, được người khác với người nộp xác nhận bằng MFA mới mới sang `ACTIVE` và nhận định danh PRODUCTION không có scope dữ liệu | UC-01-17 | 3 |
| TS-01-18 | Xoay vòng thông tin xác thực | Xác nhận xoay vòng có thời gian chuyển tiếp hai bí mật cùng hiệu lực, xoay khẩn thu hồi ngay, và không xoay chồng | UC-01-18 | 3 |
| TS-01-19 | Danh sách, thu hồi, nhắc hạn, tự vô hiệu định danh | Xác nhận định danh liệt kê không lộ bí mật, thu hồi cắt quyền đúng hạn, nhắc hạn theo mốc, hết hạn tự vô hiệu, và định danh không dùng 90 ngày tự vô hiệu (đợt 2) | UC-01-19, 25 | 4 |
| TS-01-20 | Tạm ngừng, khôi phục HTTT và phân tích tác động | Xác nhận tạm ngừng cắt quyền trong 60 giây, phải xác nhận tác động trước khi tiếp tục, khôi phục chỉ khi đủ điều kiện, và sự kiện lan sang phân hệ khác chỉ một lần | UC-01-20 | 6 |
| TS-01-21 | Chấm dứt tư cách thành viên | Xác nhận chấm dứt cần đề nghị và duyệt bởi hai người khác nhau, xác nhận tác động, chờ giao dịch đang xử lý, thu hồi mọi định danh và giữ hồ sơ | UC-01-21 | 3 |
| TS-01-22 | Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT | Xác nhận SO cắt quyền HTTT ngay khi nghi lộ bí mật, TA xác nhận bổ sung trong hạn, quá hạn chỉ cảnh báo chứ không tự hoàn tác | UC-01-22 | 9 |
| TS-01-23 | Đề nghị thay đổi hồ sơ và mở rộng trần phạm vi | Xác nhận thay đổi hồ sơ sau kết nạp được duyệt theo mức, mở rộng phạm vi luôn qua thẩm định pháp lý lại, và trần không đổi trước khi duyệt | UC-01-23, 24 | 6 |
| TS-01-24 | Đồng bộ trạng thái và bản sao đọc cho phân hệ khác | Xác nhận mọi chuyển trạng thái phát sự kiện trong cùng giao dịch, không mất khi Kafka ngừng, có ảnh chụp đối chiếu, và bản sao đọc nội bộ đúng phạm vi | UC-01-26 | 3 |
| TS-01-25 | Rà soát quyền: mở kỳ, mức sử dụng, hiệu lực căn cứ | Xác nhận kỳ rà soát mở đúng chu kỳ, tổng hợp mức dùng thực tế theo từng phạm vi, và căn cứ pháp lý hết hiệu lực làm tạm ngừng phạm vi ngay | UC-01-27 | 3 |
| TS-01-26 | Xác nhận của đơn vị, xử lý kết quả và báo cáo rà soát | Xác nhận phiếu xác nhận chỉ gửi và mở đúng người, đơn vị không phản hồi thì đề xuất thu hẹp, quyết định có lý do và MFA, và báo cáo giữ bằng chứng | UC-01-28, 29 | 5 |
| TS-01-27 | Danh bạ đầu mối | Xác nhận danh bạ công khai trong phạm vi tenant theo loại đầu mối, đầu mối an ninh ẩn, giới hạn tốc độ, cảnh báo tổ chức thiếu đầu mối | UC-01-30, 31 | 4 |
| TS-01-28 | Nhập HTTT từ hệ cũ, tham số phân hệ, thống kê | Xác nhận nhập Application của APIM và publisher, subscriber của Hub vào hồ sơ nháp không mang bí mật, tham số theo tenant có miền và lý do, thống kê đúng | UC-01-32, 33, 34 | 5 |
| TS-01-29 | Không lộ bí mật | Chứng minh NFR-01-009: ngoài phản hồi mở bàn giao, không bí mật nào xuất hiện ở bất kỳ nơi nào của PH-01 | — | 4 |
| TS-01-30 | Cách ly tenant và RLS | Chứng minh tenant này không đọc, không ghi, không suy ra được sự tồn tại của hồ sơ tenant khác, ở API, CSDL, Kafka và kho tệp | — | 4 |
| TS-01-31 | Phân quyền và tách nhiệm | Chứng minh ma trận quyền D02-08 được thực thi ở máy chủ, bốn mắt độc lập với vai trò, và thao tác nhạy cảm đòi hỏi MFA mới | — | 4 |
| TS-01-32 | Hiệu năng, tải và quy mô | Chứng minh NFR-01-001, 003, 004, 008, 017, 021 ở cấu hình QM-VUA với dữ liệu giả định GĐ-07 | — | 6 |
| TS-01-33 | Chịu lỗi, cách ly sự cố, kiểm toán, cảnh báo, lưu giữ | Chứng minh PH-01 ngừng thì HTTT đã kết nạp vẫn chạy, phục hồi không mất việc, mọi quyết định có kiểm toán, và cảnh báo vận hành phát đúng | — | 6 |
| TS-01-34 | Truy cập và giao diện | Chứng minh 17 màn UI-01-01…17 đạt WCAG 2.2 AA, có đủ trạng thái chuẩn, đúng route, và các trang dùng liên kết một lần không làm rò bí mật | — | 4 |
| TS-01-35 | Hợp đồng API, máy trạng thái, nhận lặp và đồng thời | Chứng minh API đúng hợp đồng OpenAPI và RFC 9457, chuyển trạng thái cấm bị chặn, nhận lặp an toàn và không có đua quyết định | — | 3 |
| **Tổng** | | | | **151** (97 ca P1) |

: Danh sách kịch bản kiểm thử PH-01
<!--/gen-->

### 3.2. Máy trạng thái được kiểm thử

Các kịch bản chức năng đi lần lượt qua máy trạng thái HTTT ở D02-03-PH01 §4.3 và máy trạng thái định danh, bàn giao, kỳ rà soát ở §4.4. Bảng sau cho biết kịch bản nào kiểm mỗi chuyển trạng thái; chuyển không hợp lệ được kiểm ở TS-01-35.

| Chuyển trạng thái | Kịch bản | Chuyển bị cấm được kiểm |
|---|---|---|
| ∅ → DRAFT | TS-01-02 | Tạo trùng mã (kể cả mã đã chấm dứt) |
| DRAFT → SUBMITTED | TS-01-06 | Nộp khi còn thiếu sót, khi không ở DRAFT |
| SUBMITTED → DRAFT | TS-01-07, 11 | Rút khi đã có kết luận phê duyệt |
| SUBMITTED → APPROVED, REJECTED | TS-01-12 | Duyệt khi thiếu kết luận; tự duyệt |
| APPROVED → ACTIVE | TS-01-17 | Kích hoạt khi chưa kiểm thử đạt; người nộp kích hoạt |
| APPROVED → TERMINATED | TS-01-21 | Quá hạn kiểm thử |
| ACTIVE ⇄ SUSPENDED | TS-01-20, 22 | Khôi phục khi SO chưa đồng ý |
| ACTIVE, SUSPENDED → TERMINATED | TS-01-21 | Chấm dứt khi chưa xác nhận tác động |
| Định danh ACTIVE → ROTATING → ACTIVE, REVOKED, EXPIRED | TS-01-18, 19 | Xoay khi đang chuyển tiếp |
| Bàn giao PENDING → OPENED, EXPIRED, CANCELLED | TS-01-15 | Mở lần hai |
| Kỳ rà soát OPEN → WAITING → DECIDING → CLOSED | TS-01-25, 26 | Mở kỳ khi đã có kỳ mở |

: Chuyển trạng thái và kịch bản kiểm thử

## 4. Kịch bản và test case chức năng

Mỗi kịch bản gồm mục tiêu, phạm vi phủ và các ca. Các kịch bản 01 đến 28 đi theo vòng đời một HTTT: soạn hồ sơ (01–07), thẩm định và phê duyệt (08–12), cấp định danh và kích hoạt (13–19), vòng đời (20–24), rà soát và danh bạ (25–27), di trú và quản trị (28).

### TS-01-01 · Danh sách, chi tiết, lịch sử và xuất HTTT thành viên

**Mục tiêu.** Xác nhận danh sách và chi tiết HTTT thay màn "Danh sách Application" của APIM: lọc, tìm, phân trang, đúng phạm vi theo vai trò, không lộ HTTT của tenant khác, xuất đúng quyền.

**Phủ.** FR-01-001, 002, 050; UC-01-01; API-01-001, 002, 003, 085, 088; UI-01-03, 04; BR-01-030; LGC-APIM-019.

#### TC-01-001 · Danh sách có lọc, tìm kiếm, thẻ tổng <!--k:sys-list-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-001 · UC-01-01 · API-01-001 · UI-01-03 · LGC-APIM-019.

**Tiền điều kiện, dữ liệu.** U-T68-TA1; bộ HTTT mục 2.3 (ít nhất 200 HTTT nền).

**Các bước.**

1. Mở UI-01-03; đọc năm thẻ tổng; bấm thẻ "Đang hoạt động".
2. `GET /systems?q=hộ tịch&status=ACTIVE&page=1&size=50`.

**Kết quả mong đợi.** Bước 1: bảng lọc theo `ACTIVE`, số thẻ bằng `facets` của API. Bước 2: `200`, có `items`, `facets`, `page`; mỗi dòng có mã, tên, tổ chức, trạng thái, nhóm, cấp độ ATTT; sắp xếp mặc định ổn định. KT: không. EVT: không.
:::

#### TC-01-002 · Giới hạn theo vai trò: OR chỉ thấy tổ chức mình, DO chỉ thấy dữ liệu của mình <!--k:sys-list-scope-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-001, 002 · API-01-001, 002 · BR-01-030.

**Tiền điều kiện, dữ liệu.** U-T68-OR1 (Sở Tư pháp); U-T68-DO; `HT-DVC` của Văn phòng UBND.

**Các bước.**

1. U-T68-OR1 gọi `GET /systems`; sau đó `GET /systems/HT-DVC`.
2. U-T68-DO gọi `GET /systems`.

**Kết quả mong đợi.** Bước 1: danh sách chỉ có HTTT của Sở Tư pháp; chi tiết `HT-DVC` `404-ẩn`. Bước 2: chỉ các HTTT có dữ liệu thuộc chủ quản của DO. Tổng số (`total`) không tiết lộ HTTT ngoài phạm vi.
:::

#### TC-01-003 · Chi tiết và lịch sử trạng thái, hành động khả dụng theo trạng thái <!--k:sys-detail-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-01-002 · UC-01-01 · API-01-002, 003 · UI-01-04.

**Tiền điều kiện, dữ liệu.** U-T68-TA1; `HT-QLVB` ACTIVE; `HT-HOTICH` DRAFT.

**Các bước.**

1. `GET /systems/HT-QLVB`; `GET /systems/HT-QLVB/history`.
2. `GET /systems/HT-HOTICH`.

**Kết quả mong đợi.** Bước 1: `200`, `ETag`; `allowedActions` có `suspend`, `rotate`; lịch sử có các chuyển trạng thái theo thứ tự thời gian kèm người thực hiện; không có trường bí mật nào. Bước 2: `allowedActions` có `submit`, `delete`; không có `suspend`.
:::

#### TC-01-004 · Chi tiết không tồn tại hoặc ở tenant khác <!--k:sys-404-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-002 · API-01-002, 003 · ERR-01-001 · BR-01-030.

**Tiền điều kiện, dữ liệu.** U-T68-TA1; `HT-QLVB` có ở cả T68 và T01 với nội dung khác; `HT-TC-KHAC` chỉ có ở T01.

**Các bước.**

1. U-T68-TA1 gọi `GET /systems/khong-co`.
2. U-T68-TA1 gọi `GET /systems/HT-TC-KHAC` và `GET /systems/HT-TC-KHAC/history`.
3. U-T68-TA1 gọi `GET /systems/HT-QLVB` rồi so với U-T01-TA.

**Kết quả mong đợi.** Bước 1 và 2: `404-ẩn`, thân giống hệt trừ `traceId`. Bước 3: mỗi người chỉ thấy bản của tenant mình, không lẫn trường.
:::

#### TC-01-005 · Xuất danh sách: phạm vi theo quyền, tác vụ nền <!--k:sys-export-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-050 · UC-01-01 · API-01-085, 088 · UI-01-03 · ERR-01-052.

**Tiền điều kiện, dữ liệu.** U-T68-AU; U-T68-OR1; U-T68-VW.

**Các bước.**

1. U-T68-AU gọi `POST /systems:export` kèm `format=XLSX`, `Idempotency-Key`; hỏi `GET /jobs/{jobId}` đến khi xong.
2. U-T68-OR1 gọi cùng API xuất toàn bộ tenant.
3. U-T68-VW gọi cùng API.

**Kết quả mong đợi.** Bước 1: `200` hoặc `202`, tệp có đủ HTTT của tenant, không có `secret_ref`; KT: có (xuất danh sách). Bước 2: chỉ xuất HTTT của tổ chức mình. Bước 3: `403-PQ` khi xuất toàn bộ.
:::

#### TC-01-006 · Biên phân trang và bộ lọc sai <!--k:sys-list-edge-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-01-001 · API-01-001 · ERR-01-003.

**Tiền điều kiện, dữ liệu.** U-T68-TA1.

**Các bước.**

1. `GET /systems?size=100` rồi `size=101` và `status=KHONG-CO`.

**Kết quả mong đợi.** `size=100` trả `200`; `size=101` và `status` sai trả `400` ERR-01-003 kèm danh sách lỗi theo trường.
:::

### TS-01-02 · Tạo hồ sơ nháp, sửa có tự lưu, mẫu văn bản

**Mục tiêu.** Xác nhận hồ sơ nháp thay thao tác "Tạo Application": mã bất biến và không dùng lại, tổ chức đúng, địa chỉ `https`, khóa lạc quan, nhận lặp an toàn, tự lưu không mất dữ liệu.

**Phủ.** FR-01-003, 004, 010; UC-01-02; API-01-004, 005, 020, 021; UI-01-01; BR-01-018, 031; ERR-01-002, 004, 006, 007, 049, 051, 054; LGC-APIM-020; LGC-HUB-010, 011.

#### TC-01-007 · Tạo hồ sơ nháp hợp lệ <!--k:draft-create-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-003 · UC-01-02 · API-01-004 · UI-01-01 · BR-01-018, 031 · EVT-01-03 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; Sở Tư pháp hoạt động ở PH-20.

**Các bước.**

1. Ở UI-01-01 bước 1 nhập mã `TC-HOTICH-1`, tên, tổ chức Sở Tư pháp, vai trò `CONSUMER`, cấp độ `L3`, địa chỉ `https://hotich.t68.gov.vn`; bấm "Lưu và tiếp tục".
2. `GET /systems/TC-HOTICH-1`.

**Kết quả mong đợi.** Gọi `POST /systems` trả `201`, `Location`, `ETag`; `status = DRAFT`, `revisionNo = 0`, `applicationNo` dạng `HS-KN-2026-nnnn`. Lịch sử, kiểm toán và outbox cùng một giao dịch. KT: có (tạo hồ sơ). EVT: `EVT-01-03` (∅ → DRAFT), không tới PH-10 vì chưa hoạt động.
:::

#### TC-01-008 · Mã trùng kể cả mã đã chấm dứt, sai mẫu <!--k:draft-dup-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, DB.

**Truy vết.** FR-01-003 · API-01-004 · ERR-01-002, 003 · BR-01-018.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-CU-TT` TERMINATED; HTTT từng bị từ chối `HT-TC-RJ`.

**Các bước.**

1. Tạo hồ sơ mã `HT-CU-TT`; lặp với `HT-TC-RJ`.
2. Tạo hồ sơ mã `ht cu 1` (chữ thường, có khoảng trắng).

**Kết quả mong đợi.** Bước 1: `409` ERR-01-002 cho cả hai. Bước 2: `400` ERR-01-003, danh sách lỗi theo trường `code`. Ràng buộc duy nhất ở CSDL cũng chặn khi chèn trực tiếp (DB).
:::

#### TC-01-009 · Tổ chức chủ quản sai, ngừng hoạt động, TA lập thay <!--k:draft-org-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-003 · API-01-004 · ERR-01-004, 006 · UC-01-02.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; U-T68-TA1; tổ chức "Chi cục X" ngừng hoạt động ở giả lập PH-20.

**Các bước.**

1. U-T68-OR1 tạo hồ sơ khai tổ chức Văn phòng UBND.
2. U-T68-TA1 tạo hồ sơ khai "Chi cục X".
3. U-T68-TA1 tạo hồ sơ thay Sở Tư pháp.

**Kết quả mong đợi.** Bước 1: `403` ERR-01-006. Bước 2: `422` ERR-01-004. Bước 3: `201`, `createdBy` là Minh, hồ sơ ghi thay mặt Sở Tư pháp.
:::

#### TC-01-010 · Địa chỉ cơ sở không phải https, dải IP sai <!--k:draft-https-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API, UT.

**Truy vết.** FR-01-003, 004 · API-01-004, 005 · ERR-01-049.

**Tiền điều kiện, dữ liệu.** U-T68-OR1.

**Các bước.**

1. Tạo hồ sơ với `baseUrl = http://hotich.t68.gov.vn`.
2. Sửa hồ sơ hợp lệ với `allowedIps = ["10.0.0.0/33"]`.

**Kết quả mong đợi.** Cả hai `422` ERR-01-049; không có hồ sơ mới, hồ sơ cũ không đổi.
:::

#### TC-01-011 · Khóa lạc quan và trạng thái khi sửa <!--k:draft-etag-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-004 · API-01-005 · ERR-01-005, 007 · UI-01-01.

**Tiền điều kiện, dữ liệu.** U-T68-OR1, U-T68-TA1 cùng mở `HT-HOTICH`; `HT-HOTICH-SS` SUBMITTED.

**Các bước.**

1. OR1 và TA1 cùng lấy `ETag`; OR1 `PATCH /systems/HT-HOTICH` với `If-Match` đúng; TA1 `PATCH` với `If-Match` cũ.
2. OR1 `PATCH /systems/HT-HOTICH-SS`.

**Kết quả mong đợi.** Bước 1: OR1 `200` với `ETag` mới; TA1 `412` ERR-01-007, UI-01-01 hiện hộp "Hồ sơ vừa được người khác sửa" cùng nút tải lại. Bước 2: `409` ERR-01-005 (đã nộp, chỉ đọc).
:::

#### TC-01-012 · Nhận lặp an toàn với Idempotency-Key <!--k:draft-idem-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-003 · API-01-004 · ERR-01-051, 054.

**Tiền điều kiện, dữ liệu.** U-T68-OR1.

**Các bước.**

1. Gọi `POST /systems` hai lần cùng khóa, cùng thân.
2. Gọi lần ba cùng khóa, thân khác.
3. Gửi hai yêu cầu đồng thời cùng khóa mới.

**Kết quả mong đợi.** Bước 1: lần hai trả đúng kết quả lần một, chỉ một hồ sơ. Bước 2: `409` ERR-01-051. Bước 3: một yêu cầu thành công, yêu cầu kia `409` ERR-01-054 hoặc cùng kết quả; không có hai hồ sơ.
:::

#### TC-01-013 · Tự lưu bản nháp, không mất khi mất kết nối, mẫu văn bản <!--k:draft-autosave-->

::: dac-ta
**Loại.** Dương, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** FR-01-004, 010 · UC-01-02 · API-01-005, 020, 021 · UI-01-01 · NFR-01-014.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH`.

**Các bước.**

1. Nhập thêm mô tả; chờ 30 giây; ngắt mạng; nhập tiếp; bật mạng.
2. Bấm "Tải mẫu văn bản"; tải một mẫu qua `GET /templates/{templateCode}/content`.
3. Gọi `GET /templates` không đăng nhập.

**Kết quả mong đợi.** Bước 1: sau 30 giây có một lần `PATCH` tự động; sau khi có mạng, phần nhập thêm được lưu, không mất ký tự. Bước 2: có mẫu của `T68` hoặc mẫu mặc định nền tảng. Bước 3: `401` ERR-01-052.
:::

### TS-01-03 · Hồ sơ năng lực kỹ thuật và đề xuất nhóm HTTT

**Mục tiêu.** Xác nhận bảng quy tắc đề xuất nhóm 1 đến 4 theo đúng thứ tự ưu tiên, có lời giải thích, và yêu cầu thêm thông tin cho nhóm 3.

**Phủ.** FR-01-006; UC-01-03; API-01-010, 011; UI-01-01; BR-01-025; ERR-01-003.

#### TC-01-014 · Bảng quy tắc đề xuất nhóm (tham số hóa) <!--k:tech-group-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** UT, API.

**Truy vết.** FR-01-006 · UC-01-03 · API-01-010, 011 · UI-01-01.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH` DRAFT.

**Các bước.**

1. `PUT /systems/HT-HOTICH/technical-profile` lần lượt với năm tổ hợp: (a) `replacementPlanned=true`; (b) `hasApi=true`, `apiSpecKind=OPENAPI`, `underMaintenance=true`; (c) `hasApi=true`, `apiSpecKind=WSDL`; (d) `hasApi=false`, `dbType=ORACLE`, `cdcLogEnabled=UNKNOWN`; (e) `hasApi=false`, `dbType=NONE`.

**Kết quả mong đợi.** `proposedGroup` lần lượt là 4, 1, 2, 3 và `null`; (a) thắng khi trùng với (b) (thứ tự 1); mỗi lần có `explanation[]` nêu điều kiện đã dùng; `confirmedGroup` rỗng. (e) có lựa chọn "Đề nghị khảo sát trực tiếp", không chặn nộp. KT: có (tóm tắt).
:::

#### TC-01-015 · Nhóm 3 thiếu loại CSDL, số kết nối đồng thời sai <!--k:tech-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-006 · API-01-010 · ERR-01-003.

**Tiền điều kiện, dữ liệu.** U-T68-OR1.

**Các bước.**

1. `PUT …/technical-profile` với `hasApi=false` và không có `dbType`.
2. Gửi `maxConcurrentConnections = 0`, rồi `1.5`.

**Kết quả mong đợi.** Cả ba `400` ERR-01-003, thông báo nêu cách khắc phục theo FRS; hồ sơ kỹ thuật cũ không đổi.
:::

#### TC-01-016 · Xem hồ sơ kỹ thuật, quyền và trạng thái <!--k:tech-get-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-006 · API-01-010, 011 · ERR-01-005, 052.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; U-T68-VW; `HT-HOTICH-SS` SUBMITTED.

**Các bước.**

1. U-T68-VW `GET …/technical-profile` của `HT-HOTICH`; rồi `PUT`.
2. U-T68-OR1 `PUT` vào `HT-HOTICH-SS`.

**Kết quả mong đợi.** `GET` `200` có `proposedGroup`; `PUT` của VW `403-PQ`; `PUT` vào hồ sơ đã nộp `409` ERR-01-005.
:::

### TS-01-04 · Nhu cầu khai thác, căn cứ pháp lý và tài liệu đính kèm

**Mục tiêu.** Xác nhận mỗi mục nhu cầu `CONSUME` có căn cứ pháp lý, dữ liệu bí mật nhà nước bị từ chối tuyệt đối, tệp đính kèm bị chặn theo cỡ, định dạng và mã độc, và tệp lưu riêng theo tenant.

**Phủ.** FR-01-005, 007; UC-01-04; API-01-006, 007, 008, 009, 012, 013; UI-01-01; BR-01-001, 004, 026; ERR-01-003, 012, 013, 014, 015, 016, 046; NFR-01-005, 011.

#### TC-01-017 · Khai nhu cầu CONSUME có căn cứ, dùng chung một văn bản <!--k:demand-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-005, 007 · UC-01-04 · API-01-007, 012, 013 · UI-01-01 · BR-01-001.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH`; F-PDF-VB.

**Các bước.**

1. `POST …/attachments` tải F-PDF-VB loại `LEGAL_BASIS`.
2. `PUT …/data-demands` với hai dòng `CONSUME` (loại dữ liệu trong danh mục), cùng chọn tệp trên và có số, ngày, cơ quan ban hành; một dòng `PROVIDE` không căn cứ nhưng có mức phân loại.
3. `GET …/data-demands`.

**Kết quả mong đợi.** Bước 1: `201`, tệp mã hóa khi lưu, không lưu lặp. Bước 2 và 3: `200`, `missingLegalBasis = false` ở mọi dòng; trần phạm vi tính từ các dòng; dòng `PROVIDE` được nhận.
:::

#### TC-01-018 · Dòng CONSUME thiếu căn cứ được lưu nhưng bị đánh dấu <!--k:demand-nolaw-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-007 · API-01-012, 013 · UI-01-01 · BR-01-001 · ERR-01-015, 003.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH`.

**Các bước.**

1. `PUT …/data-demands` một dòng `CONSUME` không có căn cứ.
2. Gửi dòng có ngày ban hành là ngày mai.

**Kết quả mong đợi.** Bước 1: `200`, `missingLegalBasis = true`, UI tô đỏ "Thiếu căn cứ"; ERR-01-015 chỉ xuất hiện khi kiểm tra hợp lệ (TS-01-06). Bước 2: `400` ERR-01-003.
:::

#### TC-01-019 · Dữ liệu bí mật nhà nước bị từ chối tuyệt đối <!--k:demand-state-secret-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-007, 011 · API-01-012 · BR-01-004 · ERR-01-016.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; U-T68-TA1; loại dữ liệu `BMNN-TEST` thuộc danh mục bí mật nhà nước.

**Các bước.**

1. OR1 và TA1 lần lượt `PUT …/data-demands` có dòng `CONSUME` loại `BMNN-TEST` (cả khi có căn cứ đầy đủ).
2. Gọi lại với dòng `PROVIDE` cùng loại.

**Kết quả mong đợi.** Cả bốn lần `422` ERR-01-016, thông báo "không kết nối qua Datahub"; dòng không được lưu; không có ngoại lệ cho TA. KT: có (từ chối).
:::

#### TC-01-020 · Tệp đính kèm: cỡ, định dạng, mã độc, lỗi phụ thuộc <!--k:attach-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-005 · API-01-007 · ERR-01-012, 013, 014, 046 · NFR-01-005, 011.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; F-PDF-BIG, F-EXE, F-EICAR; `attachment.maxSizeMb = 20`.

**Các bước.**

1. Tải lần lượt F-PDF-BIG, F-EXE, F-EICAR.
2. Đặt giả lập quét mã độc `fail`; tải F-PDF-VB.

**Kết quả mong đợi.** `413` ERR-01-012; `415` ERR-01-013; `422` ERR-01-014. Bước 2: `503` ERR-01-046, không nhận tệp chưa quét. Không còn tệp nào trong kho sau các bước.
:::

#### TC-01-021 · Tải, xóa tệp; tệp của tenant khác <!--k:attach-rw-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-005 · API-01-006, 008, 009 · ERR-01-001, 005 · BR-01-001.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; U-T01-TA; tệp đã đính kèm vào `HT-HOTICH`; tệp có ở `HT-HOTICH-SS`.

**Các bước.**

1. `GET …/attachments`; `GET …/attachments/{id}/content`; `DELETE` một tệp ở `HT-HOTICH`.
2. U-T01-TA gọi `GET …/attachments/{id}/content` bằng id của T68.
3. `DELETE` tệp ở `HT-HOTICH-SS`.

**Kết quả mong đợi.** Bước 1: `200`, `200` đúng nội dung, `204`. Bước 2: `404-ẩn`. Bước 3: `409` ERR-01-005. Tệp lưu ở bucket riêng của tenant (kiểm bằng đường dẫn đối tượng).
:::

#### TC-01-022 · Cấp độ ATTT thấp hơn mức phân loại dữ liệu (kiểm tra sớm) <!--k:demand-level-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-007 · API-01-012, 013 · BR-01-026 · UC-01-04.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH` cấp độ `L2`; dòng `CONSUME` mức Hạn chế.

**Các bước.**

1. `PUT …/data-demands`; sau đó `GET …/data-demands`.

**Kết quả mong đợi.** `200` và dòng có cờ cảnh báo cấp độ thấp hơn yêu cầu (`security.minLevelRestricted = L3`); lỗi ERR-01-047 chỉ tạo ở kiểm tra hợp lệ và thẩm định.
:::

### TS-01-05 · Quản lý đầu mối liên hệ

**Mục tiêu.** Xác nhận mỗi HTTT luôn có đầu mối kỹ thuật đang hoạt động, thư công vụ, thay thế đầu mối không để HTTT thiếu, và dữ liệu liên hệ không đi vào sự kiện.

**Phủ.** FR-01-008; UC-01-05; API-01-014, 015, 016, 017; UI-01-01, 04; BR-01-013, 025, 027, 028; ERR-01-003, 011, 050; EVT-01-13.

#### TC-01-023 · Thêm, sửa, thay thế đầu mối <!--k:contact-crud-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-008 · UC-01-05 · API-01-014, 015, 016 · UI-01-04 · EVT-01-13 · BR-01-025.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH`; thư `phuc@sotuphap.gov.vn`.

**Các bước.**

1. `POST …/contacts` loại `TECHNICAL`; `POST` loại `SECURITY`; `GET …/contacts`.
2. `PATCH …/contacts/{contactId}` đổi chức vụ.
3. `POST …/contacts` loại `TECHNICAL` với `replaceContactId` trỏ đầu mối cũ.

**Kết quả mong đợi.** `201`, `200`, `200`. Có đúng một đầu mối kỹ thuật hoạt động sau bước 3, đầu mối cũ ở trạng thái không hoạt động. EVT: `EVT-01-13` mỗi thay đổi, chỉ có mã HTTT và loại, **không** có họ tên, thư, số điện thoại. KT: có.
:::

#### TC-01-024 · Thư ngoài miền công vụ, dữ liệu sai <!--k:contact-email-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-008 · API-01-015, 016 · BR-01-028 · ERR-01-011, 003.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `contact.allowedEmailDomains = ["gov.vn"]`.

**Các bước.**

1. `POST …/contacts` với thư `phuc@gmail.com`.
2. `POST …/contacts` thiếu số điện thoại.
3. Đặt `T90` cho phép `["gov.vn", "tuphap.vn"]`; thêm thư `a@tuphap.vn`.

**Kết quả mong đợi.** `422` ERR-01-011; `400` ERR-01-003; bước 3 ở T90 `201`.
:::

#### TC-01-025 · Không bỏ đầu mối kỹ thuật cuối cùng <!--k:contact-last-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-008 · API-01-017 · BR-01-013 · ERR-01-050.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-TUPHAP` có đúng một đầu mối kỹ thuật.

**Các bước.**

1. `DELETE …/contacts/{contactId}` của đầu mối kỹ thuật duy nhất.
2. Thêm đầu mối kỹ thuật thứ hai rồi `DELETE` đầu mối đầu.

**Kết quả mong đợi.** Bước 1: `409` ERR-01-050. Bước 2: `204`.
:::

#### TC-01-026 · Đầu mối của HTTT đã kết nạp sửa được không cần duyệt; đầu mối an ninh ẩn <!--k:contact-active-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-008 · API-01-014, 016 · BR-01-025, 027 · UI-01-04.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; U-T68-VW; `HT-TUPHAP` ACTIVE có đầu mối `SECURITY`.

**Các bước.**

1. OR1 sửa số điện thoại đầu mối của `HT-TUPHAP`.
2. VW và SO gọi `GET …/contacts`.

**Kết quả mong đợi.** Bước 1: `200`, không tạo yêu cầu duyệt. Bước 2: VW không thấy đầu mối `SECURITY`; SO thấy.
:::

### TS-01-06 · Kiểm tra hợp lệ và nộp hồ sơ

**Mục tiêu.** Xác nhận hồ sơ chỉ nộp được khi đủ điều kiện, danh sách thiếu sót đầy đủ một lần, bước thẩm định và hạn được tạo đúng, nộp lặp an toàn.

**Phủ.** FR-01-011, 012; UC-01-06; API-01-022, 023; UI-01-01; BR-01-001, 004, 013, 017, 026, 028, 031, 032; ERR-01-005, 007, 008, 009, 010, 046, 047; EVT-01-01, 03; NFR-01-002; LGC-APIM-020.

#### TC-01-027 · Kiểm tra hợp lệ trả đủ danh sách thiếu sót một lần <!--k:validate-all-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-011 · UC-01-06 · API-01-022 · UI-01-01 · ERR-01-008, 010, 015, 047 · BR-01-001, 013, 026, 028.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; hồ sơ `tc-thieu` thiếu: căn cứ một dòng, đầu mối kỹ thuật, cấp độ `L2` với dòng mức Hạn chế; tổ chức còn `HT-DVC` thiếu đầu mối.

**Các bước.**

1. `POST /systems/tc-thieu:validate`.
2. Bấm "Kiểm tra" ở bước 4 UI-01-01.

**Kết quả mong đợi.** `422` ERR-01-008 kèm **toàn bộ** thiếu sót (mức `ERROR`) cùng mã chi tiết; UI liệt kê và dẫn tới đúng bước sửa; không có lỗi nào bị che bởi lỗi khác.
:::

#### TC-01-028 · Nộp hồ sơ đủ điều kiện <!--k:submit-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-011, 012 · UC-01-06 · API-01-022, 023 · UI-01-01 · BR-01-017, 031 · EVT-01-01, 03 · LGC-APIM-020.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; hồ sơ `tc-du` đủ điều kiện, mức Hạn chế, cấp độ `L3`; `review.slaWorkingDays = 2`.

**Các bước.**

1. Chạy `…:validate`; bấm "Gửi duyệt" ở bước 5, đọc hộp xác nhận.
2. `GET /systems/tc-du`.

**Kết quả mong đợi.** `:validate` `200` không lỗi `ERROR`. `:submit` `200`; `status = SUBMITTED`, `reviewStage = WAITING_ASSIGN`, `revisionNo` tăng; có ba bước `TECHNICAL`, `LEGAL`, `SECURITY` (vì mức Hạn chế) với `dueAt` theo ngày làm việc; nội dung khóa. KT: có (nộp hồ sơ). EVT: `EVT-01-01` và `EVT-01-03`, cùng giao dịch. Việc xuất hiện ở hộp việc người nhận.
:::

#### TC-01-029 · Hồ sơ cấp Nội bộ chỉ có hai bước thẩm định <!--k:submit-steps-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-012 · API-01-023 · UC-01-06.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; hồ sơ `tc-noibo` cấp độ `L1`, chỉ nhu cầu mức Nội bộ.

**Các bước.**

1. Nộp hồ sơ `tc-noibo`.

**Kết quả mong đợi.** `steps[]` chỉ có `TECHNICAL`, `LEGAL`; không có `SECURITY`.
:::

#### TC-01-030 · Nộp khi sai trạng thái, lệch phiên bản, nộp lặp, trùng hồ sơ <!--k:submit-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-012 · API-01-023 · ERR-01-005, 007, 009, 051 · BR-01-032.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH-SS`; hồ sơ nháp `tc-hai` cùng HTTT với hồ sơ đang xử lý (tạo bằng nhập hệ cũ).

**Các bước.**

1. `:submit` vào `HT-HOTICH-SS`.
2. `:submit` hồ sơ đủ điều kiện nhưng `If-Match` cũ.
3. `:submit` `tc-hai`.
4. `:submit` thành công hai lần cùng `Idempotency-Key`.

**Kết quả mong đợi.** `409` ERR-01-005; `412` ERR-01-007; `409` ERR-01-009; lần hai của bước 4 trả cùng kết quả, chỉ một vòng thẩm định, chỉ một `EVT-01-01`.
:::

#### TC-01-031 · Danh mục tổ chức ngừng khi nộp <!--k:submit-dep-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** IT, Chaos.

**Truy vết.** FR-01-012 · API-01-023 · ERR-01-046 · NFR-01-006.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; hồ sơ đủ điều kiện; PH-20 giả lập `fail`.

**Các bước.**

1. Bấm "Gửi duyệt".
2. Khôi phục PH-20; nộp lại.

**Kết quả mong đợi.** Bước 1: `503` ERR-01-046, hồ sơ giữ `DRAFT`, không có bước thẩm định, không có sự kiện. Bước 2: thành công.
:::

#### TC-01-032 · Độ trễ kiểm tra hợp lệ hồ sơ lớn <!--k:validate-perf-->

::: dac-ta
**Loại.** Hiệu năng.

**Ưu tiên.** P2.

**Tự động.** k6.

**Truy vết.** FR-01-011 · API-01-022 · NFR-01-002.

**Tiền điều kiện, dữ liệu.** Hồ sơ 30 mục nhu cầu, 10 tài liệu.

**Các bước.**

1. Gọi `:validate` 1.000 lần, 20 luồng.

**Kết quả mong đợi.** p99 ≤ 2 giây.
:::

### TS-01-07 · Theo dõi tiến độ, rút hồ sơ, xóa nháp

**Mục tiêu.** Xác nhận đơn vị theo dõi được hồ sơ, rút về nháp khi chưa có kết luận phê duyệt, xóa nháp chưa từng nộp, và nháp quá hạn bị xóa mềm sau nhắc.

**Phủ.** FR-01-009, 019; UC-01-07; API-01-018, 019, 034; UI-01-02, 04; BR-01-011, 018, 024, 030; ERR-01-001, 005, 020, 033; EVT-01-03.

#### TC-01-033 · Xem tiến độ hồ sơ <!--k:progress-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-01-019 · UC-01-07 · API-01-034 · UI-01-02 · BR-01-030.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; U-T68-OR2; `HT-HOTICH-SS`.

**Các bước.**

1. OR1 mở UI-01-02 của `HT-HOTICH-SS`.
2. OR2 gọi `GET /systems/HT-HOTICH-SS/progress`.

**Kết quả mong đợi.** Bước 1: dòng thời gian có các bước, thời gian ở mỗi bước, đang chờ ai, hạn dự kiến. Bước 2: `404-ẩn`.
:::

#### TC-01-034 · Rút hồ sơ đã nộp về nháp <!--k:withdraw-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-009 · UC-01-07 · API-01-019 · UI-01-02 · BR-01-011 · EVT-01-03.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH-SS` (chưa có kết luận phê duyệt).

**Các bước.**

1. `POST /systems/HT-HOTICH-SS:withdraw` kèm lý do.
2. `GET …/history`.

**Kết quả mong đợi.** `200`, `status = DRAFT`; các bước thẩm định giữ trong lịch sử, không xóa (BR-01-011); nội dung sửa được. KT: có. EVT: `EVT-01-03` (SUBMITTED → DRAFT).
:::

#### TC-01-035 · Rút hồ sơ khi đã có quyết định, thiếu lý do <!--k:withdraw-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-009 · API-01-019 · ERR-01-005, 033, 020.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; `HT-HOTICH-AP` APPROVED; `HT-HOTICH-SS`.

**Các bước.**

1. `:withdraw` vào `HT-HOTICH-AP`.
2. `:withdraw` vào `HT-HOTICH-SS` không có lý do.

**Kết quả mong đợi.** `409` ERR-01-005 hoặc ERR-01-020 (không ở giai đoạn rút được); `400` ERR-01-033.
:::

#### TC-01-036 · Xóa nháp chưa từng nộp, mã vẫn bị giữ <!--k:draft-delete-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-009 · API-01-018 · BR-01-011, 018 · ERR-01-005, 002.

**Tiền điều kiện, dữ liệu.** U-T68-OR1; nháp `tc-xoa` chưa từng nộp; `HT-HOTICH-SS` từng nộp.

**Các bước.**

1. `DELETE /systems/tc-xoa`; sau đó tạo lại hồ sơ cùng mã.
2. `DELETE /systems/HT-HOTICH-SS`.

**Kết quả mong đợi.** Bước 1: `204`; tạo lại mã `409` ERR-01-002 (mã giữ vĩnh viễn). Bước 2: `409` ERR-01-005, hồ sơ đã nộp không xóa cứng.
:::

#### TC-01-037 · Nháp quá 90 ngày: nhắc trước 14 ngày, xóa mềm <!--k:draft-expire-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-01-009 · BR-01-024 · EVT-01-03.

**Tiền điều kiện, dữ liệu.** Nháp `tc-cu` cập nhật cuối cách 76 ngày; `draft.retentionDays = 90`; đồng hồ giả.

**Các bước.**

1. Chạy tác vụ hằng ngày; tua đồng hồ tới ngày 90; chạy lại.

**Kết quả mong đợi.** Ngày 76: thư nhắc cho người lập qua PH-18 (mail-sink). Ngày 91: hồ sơ xóa mềm, mã vẫn giữ; có bản ghi lịch sử.
:::

### TS-01-08 · Phân công, theo dõi hạn thẩm định, tham vấn

**Mục tiêu.** Xác nhận TA phân công đúng người cho từng bước, người không được phân công không ghi được, tham vấn dừng đồng hồ hạn và quá hạn thì leo thang.

**Phủ.** FR-01-016; UC-01-08; API-01-027, 028, 029, 030; UI-01-05, 06; BR-01-017, 032; ERR-01-003, 017, 020.

#### TC-01-038 · Phân công ba bước và hàng đợi <!--k:assign-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-016 · UC-01-08 · API-01-027, 028 · UI-01-05 · BR-01-017 · ERR-01-017, 020.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` (`WAITING_ASSIGN`); U-T68-TA1, TA2, IE, SO, OR1.

**Các bước.**

1. TA1 `POST …/reviews:assign`: IE cho `TECHNICAL`, SO cho `SECURITY`, TA2 cho `LEGAL`; mở UI-01-05 bằng từng người.
2. TA1 phân công OR1 (người lập hồ sơ) cho bước `LEGAL`.
3. IE gọi `…:assign`.

**Kết quả mong đợi.** Bước 1: `200`, `reviewStage = IN_REVIEW`; mỗi người chỉ thấy việc của mình trong `GET /review-queue`. KT: có. EVT: `EVT-01-02`. Bước 2: `403` ERR-01-017. Bước 3: `403-PQ`.
:::

#### TC-01-039 · Tham vấn dừng đồng hồ hạn, tiếp tục chạy lại <!--k:consult-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** FR-01-016 · UC-01-08 · API-01-029, 030 · BR-01-032 · ERR-01-020.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` đã phân công; đồng hồ giả.

**Các bước.**

1. IE `POST …/reviews:consult`; tua 3 ngày làm việc; `POST …/reviews:resume`.
2. IE gọi `…:resume` lần hai.

**Kết quả mong đợi.** Bước 1: `reviewStage = CONSULTING`, `dueAt` không lùi trong 3 ngày, sau `resume` được cộng đúng thời gian dừng. Bước 2: `409` ERR-01-020.
:::

#### TC-01-040 · Quá hạn nhắc và leo thang <!--k:escalate-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-01-016 · UC-01-08 · EVT-01-02 · NFR-01-016.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS`; `review.slaWorkingDays = 2`, `escalate.afterWorkingDays = 3`; đồng hồ giả.

**Các bước.**

1. Tua tới hạn bước; tua tiếp 3 ngày làm việc.

**Kết quả mong đợi.** Quá hạn: nhắc người được giao và nhãn quá hạn ở UI-01-05; sau ngày thứ 3: leo thang tới TA và PO, cảnh báo PH-13 "hồ sơ quá hạn".
:::

### TS-01-09 · Thẩm định kỹ thuật và tác động hạn mức dữ liệu quốc gia

**Mục tiêu.** Xác nhận thẩm định kỹ thuật chỉ do người được phân công ghi, nhóm HTTT được xác nhận, phương thức xác thực đúng mức phân loại, và tác động hạn mức quốc gia được tính theo ngưỡng.

**Phủ.** FR-01-013, 015; UC-01-09; API-01-024, 026; UI-01-06; BR-01-016, 017, 019, 026; ERR-01-017, 019, 020, 046, 047; EVT-01-02.

#### TC-01-041 · Ghi kết luận kỹ thuật đúng quy tắc <!--k:tech-review-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-013 · UC-01-09 · API-01-024 · UI-01-06 · BR-01-017, 019, 026 · ERR-01-017, 019, 020, 047 · EVT-01-02.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` mức Hạn chế; U-T68-IE (được giao), U-T68-TECH, U-T68-X1.

**Các bước.**

1. IE `POST …/reviews/technical` xác nhận nhóm 2, chọn xác thực bằng khóa công khai.
2. Lặp với (a) thiếu `confirmedGroup`; (b) chọn chuỗi bí mật; (c) cấp độ `L2`; (d) người ngoài phân công; (e) X1 là người lập hồ sơ; (f) bước đã hoàn tất.

**Kết quả mong đợi.** Bước 1: `200`, `confirmedGroup = 2`; KT: có; EVT: `EVT-01-02`. Bước 2: (a) `422` ERR-01-019; (b) và (c) `422` ERR-01-047 (BR-01-019, 026); (d) `403-PQ`; (e) `403` ERR-01-017; (f) `409` ERR-01-020.
:::

#### TC-01-042 · Tác động hạn mức quốc gia theo ngưỡng <!--k:quota-impact-->

::: dac-ta
**Loại.** Dương, Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-015 · UC-01-09 · API-01-026 · UI-01-06 · BR-01-016.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` có nhu cầu dịch vụ quốc gia; giả lập PH-14 trả hạn mức còn lại; `quotaImpact.mediumPct = 20`, `highPct = 50`.

**Các bước.**

1. `POST …/reviews/quota-impact` với dự kiến 19 %, 20 %, 50 % hạn mức còn lại.

**Kết quả mong đợi.** Mức tác động lần lượt `LOW`, `MEDIUM`, `HIGH` (biên đúng ngưỡng); kết quả đi vào kết luận kỹ thuật.
:::

#### TC-01-043 · PH-14 không khả dụng khi đánh giá tác động <!--k:quota-dep-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-01-015 · API-01-026 · ERR-01-046.

**Tiền điều kiện, dữ liệu.** PH-14 giả lập `fail`.

**Các bước.**

1. Gọi `…/reviews/quota-impact`.

**Kết quả mong đợi.** `503` ERR-01-046; không mất kết luận đã ghi trước đó; người thẩm định ghi được ghi chú "chưa đánh giá được".
:::

### TS-01-10 · Thẩm định căn cứ pháp lý và ATTT theo từng mục

**Mục tiêu.** Xác nhận mỗi mục nhu cầu có kết luận riêng, quyền của HTTT không rộng hơn phạm vi được chấp thuận, thẩm định pháp lý do người thực hiện chứ không tự động.

**Phủ.** FR-01-014; UC-01-10; API-01-025; UI-01-06; BR-01-001, 002, 003, 004, 017, 019, 026; ERR-01-016, 017, 018, 019; EVT-01-02.

#### TC-01-044 · Kết luận từng mục: chấp thuận, thu hẹp, từ chối <!--k:legal-items-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-014 · UC-01-10 · API-01-025 · UI-01-06 · BR-01-002, 003 · EVT-01-02.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` có ba mục `CONSUME`; U-T68-TA2 (bước `LEGAL`).

**Các bước.**

1. TA2 `POST …/reviews/LEGAL` với mục 1 chấp thuận, mục 2 chấp thuận thu hẹp (bỏ một phạm vi), mục 3 từ chối kèm lý do.
2. `GET …/data-demands`.

**Kết quả mong đợi.** `200`; phạm vi được chấp thuận của mục 1 đủ, mục 2 thu hẹp, mục 3 rỗng; hệ thống không tự đặt kết luận nào (BR-01-002). KT: có. EVT: `EVT-01-02`.
:::

#### TC-01-045 · Thẩm định pháp lý thiếu mục, thiếu ý kiến, bí mật nhà nước, người lập <!--k:legal-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-014 · API-01-025 · BR-01-004, 017 · ERR-01-016, 017, 018, 019.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS`; TA2; TA1 là người lập hồ sơ thay; dòng `BMNN-TEST` chèn bằng công cụ kiểm thử.

**Các bước.**

1. TA2 ghi kết luận bỏ sót một mục; rồi thiếu ý kiến cho mục từ chối.
2. TA2 chấp thuận mục `BMNN-TEST`.
3. TA1 (người lập thay) ghi kết luận.

**Kết quả mong đợi.** `422` ERR-01-018; `422` ERR-01-019; `422` ERR-01-016 (không có đường chấp thuận); `403` ERR-01-017.
:::

#### TC-01-046 · Thẩm định ATTT: đúng người, không tự động hóa <!--k:sec-review-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-014 · API-01-025 · BR-01-019, 026 · ERR-01-047 · UC-01-10.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` mức Hạn chế; U-T68-SO (được giao); U-T68-IE.

**Các bước.**

1. SO `POST …/reviews/SECURITY` đạt, ghi cấp độ ATTT và phương thức xác thực yêu cầu.
2. IE gọi cùng API.

**Kết quả mong đợi.** Bước 1: `200`; KT: có. Bước 2: `403-PQ` (IE không có phân công bước này). Không có kết luận nào được đặt khi không có người gọi API.
:::

### TS-01-11 · Trả bổ sung và nộp lại hồ sơ

**Mục tiêu.** Xác nhận hồ sơ trả bổ sung giữ nguyên nội dung, đồng hồ dừng, và khi nộp lại các bước có dữ liệu không đổi giữ kết luận.

**Phủ.** FR-01-017; UC-01-11; API-01-031, 023; UI-01-02, 06; BR-01-032; ERR-01-020, 033; EVT-01-01, 02, 03.

#### TC-01-047 · Trả bổ sung rồi nộp lại, giữ kết luận bước không đổi <!--k:return-resubmit-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-017, 012 · UC-01-11 · API-01-031, 023 · UI-01-02, 06 · BR-01-032 · EVT-01-02, 03.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS` có kết luận kỹ thuật đạt; IE chưa xong; SO được giao.

**Các bước.**

1. SO `POST …:return` với lý do "thiếu phương án mã hóa".
2. OR1 sửa phần ATTT, `:validate`, `:submit`.
3. `GET …/progress`.

**Kết quả mong đợi.** Bước 1: `200`, `DRAFT`, `returnReason`, nội dung nguyên vẹn, đồng hồ dừng. Bước 2: `revisionNo` tăng; bước `TECHNICAL` giữ kết luận (dữ liệu kỹ thuật không đổi), bước `SECURITY` mở lại. EVT: `EVT-01-02`, `EVT-01-03`, `EVT-01-01`.
:::

#### TC-01-048 · Trả bổ sung sai: thiếu lý do, sai người, sai giai đoạn <!--k:return-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-017 · API-01-031 · ERR-01-020, 033.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SS`; `HT-HOTICH` DRAFT; U-T68-IE, U-T68-OR2.

**Các bước.**

1. IE `:return` không lý do.
2. OR2 `:return`.
3. IE `:return` vào `HT-HOTICH` (DRAFT).

**Kết quả mong đợi.** `400` ERR-01-033; `403-PQ`; `409` ERR-01-020.
:::

### TS-01-12 · Phê duyệt hoặc từ chối kết nạp

**Mục tiêu.** Xác nhận quyết định bốn mắt, xác thực lại hai yếu tố, trần phạm vi đúng phạm vi được duyệt, và HTTT bị từ chối vẫn giữ mã.

**Phủ.** FR-01-018; UC-01-12; API-01-032, 033; UI-01-07; BR-01-003, 009, 017, 031; ERR-01-017, 020, 033, 035; EVT-01-02, 03, 11.

#### TC-01-049 · Phê duyệt bởi TA không liên quan, trần bằng phạm vi duyệt <!--k:approve-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-018 · UC-01-12 · API-01-032 · UI-01-07 · BR-01-003, 017, 031 · EVT-01-02, 03, 11.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-OK`; người lập OR1, người nộp OR1, người thẩm định gồm IE, SO, TA2; U-T68-TA1 (khác tất cả); phạm vi bước pháp lý đã thu hẹp.

**Các bước.**

1. TA1 xác thực lại MFA; mở UI-01-07; `POST …:approve` kèm lý do.
2. `GET …/data-demands`.

**Kết quả mong đợi.** `200`, `APPROVED`, `provisionStage = PROVISIONING`; trần phạm vi bằng đúng phạm vi được chấp thuận, không có phạm vi bị từ chối. EVT: `EVT-01-02`, `EVT-01-03`, `EVT-01-11`, cùng giao dịch. KT: có.
:::

#### TC-01-050 · Bốn mắt, MFA, thiếu lý do, thiếu kết luận <!--k:approve-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-018 · API-01-032, 033 · BR-01-009, 017 · ERR-01-017, 020, 033, 035.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-OK`; `HT-HOTICH-SS`; U-T68-TA2 (đã thẩm định), U-T68-X1, U-T68-TA1.

**Các bước.**

1. TA2 `:approve` (đã thẩm định bước pháp lý).
2. X1 (người lập) `:approve`.
3. TA1 `:approve` khi phiên chưa có MFA mới.
4. TA1 (MFA mới) `:reject` không lý do.
5. TA1 (MFA mới) `:approve` `HT-HOTICH-SS` (còn bước chưa xong).

**Kết quả mong đợi.** `403` ERR-01-017; `403` ERR-01-017; `403` ERR-01-035; `400` ERR-01-033; `409` ERR-01-020. Trạng thái hồ sơ không đổi sau mọi lần lỗi.
:::

#### TC-01-051 · Từ chối kết nạp, mã vẫn giữ <!--k:reject-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API, E2E.

**Truy vết.** FR-01-018 · API-01-033 · UI-01-07 · BR-01-011, 018 · EVT-01-03.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-OK` bản sao `tc-rj`; TA1 có MFA mới.

**Các bước.**

1. `:reject` kèm lý do; tạo lại hồ sơ cùng mã.

**Kết quả mong đợi.** `REJECTED`, hồ sơ và bước thẩm định được giữ; thông báo cho người nộp; tạo lại mã `409` ERR-01-002. EVT: `EVT-01-03`.
:::

### TS-01-13 · Cấp định danh SANDBOX (saga)

**Mục tiêu.** Xác nhận saga tạo định danh qua PH-12, PH-03 và OpenBao, không bao giờ cấp scope dữ liệu, thử lại được khi lỗi và an toàn khi gọi lại.

**Phủ.** FR-01-020; UC-01-13; API-01-035, 036, 087; UI-01-08; BR-01-003, 005, 007, 019, 031; ERR-01-021, 022, 023, 053; EVT-01-05; NFR-01-004.

#### TC-01-052 · Saga thành công đến trạng thái bàn giao <!--k:saga-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-020 · UC-01-13 · API-01-036 · UI-01-08 · BR-01-003, 007, 031 · EVT-01-05 · NFR-01-004.

**Tiền điều kiện, dữ liệu.** Sau phê duyệt `HT-HOTICH` (khóa công khai chưa đăng ký); PH-12, PH-03, OpenBao khỏe.

**Các bước.**

1. Chờ saga; `GET /systems/HT-HOTICH/provisioning`; mở UI-01-08.
2. Đọc định danh qua `GET /systems/HT-HOTICH/credentials`.

**Kết quả mong đợi.** Các bước saga lần lượt tạo client, consumer, `secret_ref`; `provisionStage = AWAITING_KEY` (mức Hạn chế). Định danh SANDBOX không có scope dữ liệu nào. Bảng PH-01 chỉ có `secret_ref`, vân tay, băm. Mồi sạch. EVT: `EVT-01-05`. Thời gian từ duyệt ≤ 5 phút (p95).
:::

#### TC-01-053 · Saga lỗi: PH-12, OpenBao ngừng, client trùng, thử lại <!--k:saga-fail-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-01-020 · API-01-035, 036 · ERR-01-021, 022, 023 · NFR-01-016.

**Tiền điều kiện, dữ liệu.** Hồ sơ vừa phê duyệt; U-T68-TA1.

**Các bước.**

1. PH-12 giả lập `fail`; phê duyệt; xem tiến độ; sau đó khôi phục và TA1 `POST …/credentials:provision`.
2. PH-12 giả lập `duplicate-client`.
3. Dừng OpenBao.

**Kết quả mong đợi.** Bước 1: saga `FAILED` ở bước PH-12, cảnh báo PH-13; `provision` trả `202` rồi hoàn tất, không tạo client hai lần. Bước 2: `409` ERR-01-022 xử lý được bằng liên kết lại client có sẵn. Bước 3: `503` ERR-01-023, không có bí mật nào ghi vào PH-01.
:::

#### TC-01-054 · Kết quả bất đồng bộ của bước saga <!--k:saga-callback-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-020 · API-01-087 · ERR-01-052, 053 · UC-01-13.

**Tiền điều kiện, dữ liệu.** S-CB; một bước saga `ACCEPTED`; bước khác không ở `ACCEPTED`; cờ `onboarding.saga.async-callback`.

**Các bước.**

1. S-CB `POST /internal/provisioning-callbacks` đúng bước `ACCEPTED`.
2. Gọi cho bước không `ACCEPTED`; rồi tắt cờ và gọi lại.
3. Dùng token không có scope `onboarding:provision-callback`.

**Kết quả mong đợi.** Bước 1: nhận, saga tiếp tục. Bước 2: `409` ERR-01-053, ghi nhật ký vận hành, không đổi trạng thái. Bước 3: `403-PQ`.
:::

### TS-01-14 · Đăng ký khóa công khai hoặc ký chứng thư

**Mục tiêu.** Xác nhận phương thức xác thực theo mức phân loại, khóa yếu bị từ chối, PH-01 không bao giờ giữ khóa riêng.

**Phủ.** FR-01-021; UC-01-14; API-01-037, 038; UI-01-08; BR-01-007, 019, 020; ERR-01-021, 023, 027, 028, 030; EVT-01-05, 06.

#### TC-01-055 · Đăng ký JWKS và ký CSR <!--k:key-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-021 · UC-01-14 · API-01-037, 038 · UI-01-08 · BR-01-007, 019 · EVT-01-05, 06.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-AP` (AWAITING_KEY); F-JWKS-OK; HTTT mức Nhạy cảm `tc-nhaycam` với F-CSR-OK; U-T68-TECH.

**Các bước.**

1. TECH `PUT /credentials/{credentialId}/public-key` với F-JWKS-OK.
2. TA1 `POST …:sign-csr` cho CSR của `tc-nhaycam`.

**Kết quả mong đợi.** Bước 1: `200`, định danh `ACTIVE`, `EVT-01-05`; PH-01 chỉ lưu vân tay. Bước 2: chứng thư do PKI OpenBao cấp, hạn ≤ hạn định danh; khóa riêng không có mặt ở bất kỳ đâu. Mồi sạch.
:::

#### TC-01-056 · Khóa yếu, CSR sai, sai trạng thái, phụ thuộc ngừng <!--k:key-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-021 · API-01-037, 038 · BR-01-019 · ERR-01-021, 023, 027, 028, 030.

**Tiền điều kiện, dữ liệu.** F-JWKS-BAD, F-CSR-BAD; định danh `REVOKED`; PH-12, OpenBao giả lập `fail`.

**Các bước.**

1. `PUT …/public-key` với F-JWKS-BAD.
2. `:sign-csr` với F-CSR-BAD.
3. `PUT …/public-key` vào định danh `REVOKED`.
4. Đặt PH-12 `fail`; đăng ký khóa hợp lệ; đặt OpenBao `fail`; ký CSR hợp lệ.

**Kết quả mong đợi.** `422` ERR-01-027; `422` ERR-01-028; `409` ERR-01-030; `503` ERR-01-021; `503` ERR-01-023. Không có thay đổi một phần.
:::

### TS-01-15 · Bàn giao thông tin xác thực một lần

**Mục tiêu.** Xác nhận bí mật chỉ đến tay đúng đầu mối qua liên kết dùng một lần, không đi qua thư điện tử, hủy sau lần mở đầu, và khóa khi mở sai nhiều lần. Đây là kịch bản bắt buộc đạt 100 %.

**Phủ.** FR-01-022; UC-01-15; API-01-039, 040, 041; UI-01-09; BR-01-005, 006, 007, 009; ERR-01-003, 023, 024, 025, 026, 035, 048; EVT-01-09, 10; NFR-01-009, 010.

#### TC-01-057 · Tạo liên kết bàn giao, thư chỉ chứa liên kết <!--k:handover-create-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-01-022 · UC-01-15 · API-01-039 · BR-01-005, 007 · NFR-01-010.

**Tiền điều kiện, dữ liệu.** Định danh SANDBOX `ACTIVE` của chuỗi bí mật (HTTT `HT-DVC` làm lại SANDBOX); U-T68-TA1 có MFA mới; U-T68-TECH.

**Các bước.**

1. TA1 `POST /credentials/{credentialId}/handovers` kèm `Idempotency-Key`.
2. Đọc thư ở mail-sink; tra bảng bàn giao ở CSDL.

**Kết quả mong đợi.** `201`; mã liên kết ≥ 256 bit; CSDL chỉ lưu băm; hạn 24 giờ (`handover.ttlHours`). Thư gửi tới TECH chứa liên kết, **không** chứa bí mật, mã khách, hay mật khẩu. KT: có.
:::

#### TC-01-058 · Mở liên kết bằng đúng người: nhận bí mật một lần <!--k:handover-open-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-022 · UC-01-15 · API-01-040 · UI-01-09 · BR-01-006, 007 · EVT-01-09 · NFR-01-009.

**Tiền điều kiện, dữ liệu.** Liên kết `PENDING` từ ca trước; U-T68-TECH có tài khoản và TOTP.

**Các bước.**

1. TECH mở `/ket-noi/ban-giao/{token}`, đăng nhập, xác thực MFA mới.
2. `POST /handovers:open`.
3. Tra bảng bàn giao, OpenBao, log, vết, Kafka.

**Kết quả mong đợi.** Bước 2: `200`, bí mật hiện một lần kèm nút sao chép, không lưu bộ nhớ đệm trình duyệt (tiêu đề `Cache-Control: no-store`, theo API-01-040). Sau đó: trạng thái `OPENED`, bản sao bí mật bị hủy; chỉ phản hồi này có `DH-CANARY` (Mồi sạch ở mọi nơi khác). EVT: `EVT-01-09`. KT: có.
:::

#### TC-01-059 · Mở lần hai, liên kết hết hạn <!--k:handover-twice-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-022 · API-01-040 · ERR-01-024 · BR-01-006.

**Tiền điều kiện, dữ liệu.** Liên kết đã `OPENED`; liên kết khác tạo trước 25 giờ (đồng hồ giả); U-T68-TECH.

**Các bước.**

1. TECH mở lại liên kết đã mở.
2. TECH mở liên kết quá hạn.
3. Thu hồi định danh rồi mở liên kết `PENDING`.

**Kết quả mong đợi.** Cả ba `410` ERR-01-024, thân giống nhau; không trả bí mật; liên kết bước 3 ở `CANCELLED`.
:::

#### TC-01-060 · Sai người mở liên kết <!--k:handover-wrong-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-022 · API-01-040 · ERR-01-025 · EVT-01-10 · BR-01-005.

**Tiền điều kiện, dữ liệu.** Liên kết `PENDING` của `HT-HOTICH`; U-T68-OR2 (đầu mối tổ chức khác); U-T68-TA1.

**Các bước.**

1. OR2 mở liên kết (có MFA).
2. TA1 mở liên kết.

**Kết quả mong đợi.** `403` ERR-01-025 cho cả hai (TA không phải người nhận); liên kết vẫn `PENDING`; EVT: `EVT-01-10` tới PH-13 và SO.
:::

#### TC-01-061 · Mở sai quá số lần, thiếu MFA <!--k:handover-lock-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, ZAP.

**Truy vết.** FR-01-022 · API-01-040 · ERR-01-026, 035 · EVT-01-10 · NFR-01-010.

**Tiền điều kiện, dữ liệu.** Liên kết `PENDING`; `handover.maxFailedOpens = 5`; U-T68-TECH.

**Các bước.**

1. TECH mở liên kết khi phiên chưa có MFA mới.
2. Mở với mã liên kết sai 5 lần liên tiếp, rồi lần thứ 6 bằng mã đúng.

**Kết quả mong đợi.** Bước 1: `403` ERR-01-035. Bước 2: lần 1 đến 4 `410` hoặc `404`, lần 5 `429` ERR-01-026; liên kết bị hủy, mã đúng cũng không mở được; thông báo "Liên hệ quản trị tỉnh". EVT: `EVT-01-10`.
:::

#### TC-01-062 · Tạo lại liên kết, HTTT đang tạm ngừng, đầu mối chưa có tài khoản <!--k:handover-reissue-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-022 · API-01-039, 041 · ERR-01-003, 024, 048 · BR-01-006.

**Tiền điều kiện, dữ liệu.** Liên kết `EXPIRED` chưa mở; liên kết đã `OPENED`; HTTT `SUSPENDED`; đầu mối `tc-chua-tk` chưa có tài khoản; TA1 có MFA mới.

**Các bước.**

1. TA1 `POST /handovers/{handoverId}:reissue` với liên kết `EXPIRED` chưa mở.
2. Gọi `:reissue` với liên kết đã `OPENED`.
3. Tạo liên kết cho HTTT `SUSPENDED`.
4. Tạo liên kết cho đầu mối chưa có tài khoản.

**Kết quả mong đợi.** `201` (liên kết mới, cũ `CANCELLED`); `409` ERR-01-024 (muốn có lại phải xoay vòng, xem Q01-40); `409` ERR-01-048; `400` ERR-01-003.
:::

#### TC-01-063 · OpenBao ngừng khi mở liên kết <!--k:handover-dep-->

::: dac-ta
**Loại.** Âm, Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** FR-01-022 · API-01-040 · ERR-01-023 · BR-01-006.

**Tiền điều kiện, dữ liệu.** Liên kết `PENDING`; U-T68-TECH.

**Các bước.**

1. Dừng OpenBao; TECH mở liên kết.
2. Khởi động OpenBao; mở lại.

**Kết quả mong đợi.** Bước 1: `503` ERR-01-023, liên kết **chưa** bị tiêu hao. Bước 2: mở được một lần.
:::

### TS-01-16 · Kiểm thử kết nối ở SANDBOX

**Mục tiêu.** Xác nhận HTTT chứng minh gọi được API ở môi trường thử bằng dữ liệu giả, đủ số lượt đạt mới sẵn sàng kích hoạt, và định danh SANDBOX không chạm dữ liệu thật.

**Phủ.** FR-01-023; UC-01-16; API-01-042, 043; UI-01-10; BR-01-008, 034; ERR-01-031, 046; NFR-01-016.

#### TC-01-064 · Đủ lượt gọi đạt thì sẵn sàng kích hoạt <!--k:sbx-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-023 · UC-01-16 · API-01-042, 043 · UI-01-10 · BR-01-008.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-AP` có định danh SANDBOX; `sandbox.requiredSuccessfulCalls = 3`.

**Các bước.**

1. Dùng định danh gọi API sandbox giả hai lần; `POST …/sandbox-tests`; `GET …/sandbox-tests`.
2. Gọi lần thứ ba; làm mới.

**Kết quả mong đợi.** Bước 1: `readyToActivate = false`, UI-01-10 hiện kết quả hai bên và hướng dẫn khắc phục. Bước 2: `readyToActivate = true`. Hai API nhận `Idempotency-Key`.
:::

#### TC-01-065 · Định danh SANDBOX không gọi được dữ liệu thật, vượt hạn mức <!--k:sbx-data-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-01-023 · API-01-042 · BR-01-034, 003.

**Tiền điều kiện, dữ liệu.** Định danh SANDBOX của `HT-HOTICH`; `sandbox.quotaPerDay = 1.000`; giả lập PH-03.

**Các bước.**

1. Dùng định danh SANDBOX gọi một API của môi trường thật.
2. Gọi 1.001 lần trong một ngày ở sandbox.

**Kết quả mong đợi.** Bước 1: bị chặn ở cổng (`401` hoặc `403`), không có dữ liệu thật trả về. Bước 2: lượt 1.001 bị `429`; định danh mới cấp không có scope dữ liệu.
:::

#### TC-01-066 · Ở SANDBOX quá hạn, PH-13 không khả dụng <!--k:sbx-overdue-->

::: dac-ta
**Loại.** Biên, Chịu lỗi.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-01-023 · API-01-043 · ERR-01-046 · NFR-01-016.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-AP`; `sandbox.maxDays = 30`; đồng hồ giả; PH-13 giả lập `fail`.

**Các bước.**

1. Tua 31 ngày; chạy tác vụ.
2. `GET …/sandbox-tests` khi PH-13 `fail`.

**Kết quả mong đợi.** Bước 1: cảnh báo "HTTT ở SANDBOX quá 30 ngày" gửi PH-13 và TA. Bước 2: `503` ERR-01-046 cho phần số liệu gọi, kết quả lưu của PH-01 vẫn trả được.
:::

### TS-01-17 · Kích hoạt môi trường thật (PRODUCTION)

**Mục tiêu.** Xác nhận chỉ HTTT đã kiểm thử đạt, đủ điều kiện, được người khác với người nộp xác nhận bằng MFA mới mới sang `ACTIVE` và nhận định danh PRODUCTION không có scope dữ liệu.

**Phủ.** FR-01-024; UC-01-17; API-01-044; UI-01-10; BR-01-003, 008, 013, 017, 026; ERR-01-017, 021, 031, 032, 035; EVT-01-03, 05.

#### TC-01-067 · Kích hoạt hợp lệ <!--k:act-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-024 · UC-01-17 · API-01-044 · UI-01-10 · BR-01-003, 008, 017 · EVT-01-03, 05.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SB` (kiểm thử đạt, có đầu mối kỹ thuật); người nộp OR1; U-T68-TA2 có MFA mới.

**Các bước.**

1. TA2 `POST /systems/HT-HOTICH-SB:activate`.
2. `GET …/credentials`; `GET /internal/systems/HT-HOTICH-SB` bằng S-INT.

**Kết quả mong đợi.** `200` hoặc `202`; `ACTIVE`; có định danh PRODUCTION không có scope dữ liệu (scope chỉ phát sinh sau đăng ký sử dụng ở PH-02); PH-10, PH-03 nhận `EVT-01-03`, `EVT-01-05`. KT: có.
:::

#### TC-01-068 · Kích hoạt khi chưa đủ điều kiện hoặc sai người <!--k:act-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-024 · API-01-044 · BR-01-008, 013, 017, 026 · ERR-01-017, 021, 031, 032, 035.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-AP` (chưa kiểm thử đạt); `HT-HOTICH-SB` có hai biến thể: thiếu đầu mối kỹ thuật, cấp độ hạ xuống `L2`; U-T68-X1 là người nộp.

**Các bước.**

1. TA2 kích hoạt `HT-HOTICH-AP`.
2. TA2 kích hoạt biến thể thiếu đầu mối; biến thể cấp độ thấp.
3. X1 (người nộp) kích hoạt.
4. TA2 kích hoạt khi phiên chưa có MFA mới.
5. PH-12 `fail`; TA2 kích hoạt.

**Kết quả mong đợi.** `422` ERR-01-031; `422` ERR-01-032 (danh sách điều kiện thiếu); `403` ERR-01-017; `403` ERR-01-035; `503` ERR-01-021 và HTTT giữ `APPROVED`.
:::

#### TC-01-069 · HTTT chỉ cung cấp API (PROVIDER) <!--k:act-provider-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-024 · UC-01-17 · API-01-044 · BR-01-003.

**Tiền điều kiện, dữ liệu.** `tc-provider` vai trò `PROVIDER`, đã kiểm thử đạt.

**Các bước.**

1. TA2 kích hoạt.

**Kết quả mong đợi.** `ACTIVE` với scope dữ liệu rỗng để PH-02 công bố API của HTTT.
:::

### TS-01-18 · Xoay vòng thông tin xác thực

**Mục tiêu.** Xác nhận xoay vòng có thời gian chuyển tiếp hai bí mật cùng hiệu lực, xoay khẩn thu hồi ngay, và không xoay chồng.

**Phủ.** FR-01-025; UC-01-18; API-01-045, 046; UI-01-08, 09; BR-01-009, 020, 021; ERR-01-021, 023, 029, 030, 033, 035; EVT-01-06.

#### TC-01-070 · Xoay vòng có chuyển tiếp rồi kết thúc <!--k:rot-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-025 · UC-01-18 · API-01-045, 046 · UI-01-08, 09 · BR-01-009, 021 · EVT-01-06.

**Tiền điều kiện, dữ liệu.** `HT-DVC` PRODUCTION chuỗi bí mật; U-T68-OR2 có `PERM-01-credential` trong phạm vi; `rotationOverlapDays = 7`.

**Các bước.**

1. OR2 `POST /credentials/{id}:rotate` kèm lý do, MFA mới.
2. Mở liên kết bàn giao mới; gọi API cổng bằng bí mật cũ và mới.
3. Tua 7 ngày hoặc `POST …:finish-rotation`.

**Kết quả mong đợi.** Bước 1: `ROTATING`. Bước 2: cả hai bí mật gọi được; bí mật mới chỉ lộ ở phản hồi mở bàn giao. Bước 3: `ACTIVE` với bí mật mới, bí mật cũ vô hiệu. EVT: `EVT-01-06` khi bắt đầu và khi kết thúc. KT: có. Mồi sạch.
:::

#### TC-01-071 · Xoay chồng, sai trạng thái, thiếu lý do, thiếu MFA <!--k:rot-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-025 · API-01-045, 046 · BR-01-009 · ERR-01-021, 023, 029, 030, 033, 035.

**Tiền điều kiện, dữ liệu.** Định danh `ROTATING`; định danh `REVOKED`; OR2, TA1.

**Các bước.**

1. `:rotate` khi đang `ROTATING`.
2. `:rotate` định danh `REVOKED`.
3. `:rotate` thiếu lý do; thiếu MFA mới.
4. PH-12 `fail`; OpenBao `fail`; `:rotate`.

**Kết quả mong đợi.** `409` ERR-01-029; `409` ERR-01-030; `400` ERR-01-033; `403` ERR-01-035; `503` ERR-01-021 và `503` ERR-01-023, định danh giữ nguyên bí mật cũ.
:::

#### TC-01-072 · Xoay khẩn do SO, chuyển tiếp bằng 0 <!--k:rot-emergency-->

::: dac-ta
**Loại.** Biên, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-01-025 · UC-01-18 · API-01-045 · BR-01-021 · EVT-01-06.

**Tiền điều kiện, dữ liệu.** `HT-DVC`; U-T68-SO có `PERM-01-suspend`.

**Các bước.**

1. SO `:rotate` kèm `overlapDays = 0`.
2. Gọi cổng bằng bí mật cũ.

**Kết quả mong đợi.** Bí mật cũ vô hiệu ngay (≤ 60 giây tại cổng); bàn giao mới tạo; `EVT-01-06`. Thời gian chuyển tiếp vượt 14 ngày bị `400`/`422` theo miền tham số.
:::

### TS-01-19 · Danh sách, thu hồi, nhắc hạn, tự vô hiệu định danh

**Mục tiêu.** Xác nhận định danh liệt kê không lộ bí mật, thu hồi cắt quyền đúng hạn, nhắc hạn theo mốc, hết hạn tự vô hiệu, và định danh không dùng 90 ngày tự vô hiệu (đợt 2).

**Phủ.** FR-01-026, 027, 028, 036; UC-01-19, 25; API-01-047, 048, 049, 050, 061; UI-01-04, 08, 11; BR-01-007, 009, 020, 022, 023; ERR-01-001, 030, 033, 034, 035; EVT-01-07, 08.

#### TC-01-073 · Danh sách, chi tiết định danh: không bí mật, tenant khác ẩn <!--k:cred-list-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-028 · UC-01-19 · API-01-049, 050 · UI-01-04, 08 · BR-01-007 · ERR-01-001.

**Tiền điều kiện, dữ liệu.** U-T68-TA1; U-T68-OR2; U-T01-TA; định danh của `HT-QLVB`.

**Các bước.**

1. TA1 `GET /systems/HT-QLVB/credentials`; `GET /credentials/{id}`.
2. OR2 gọi chi tiết định danh của `HT-QLVB`; U-T01-TA gọi cùng id.

**Kết quả mong đợi.** Bước 1: có loại, trạng thái, hạn, vân tay, `secret_ref` dạng ẩn; **không** có giá trị bí mật. Bước 2: `404-ẩn`. Mồi sạch.
:::

#### TC-01-074 · Thu hồi định danh, hiệu lực trong 60 giây <!--k:cred-revoke-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-01-026 · UC-01-19 · API-01-047 · UI-01-11 · BR-01-009, 023 · ERR-01-030, 033, 034, 035 · EVT-01-07 · NFR-01-008.

**Tiền điều kiện, dữ liệu.** Định danh `ACTIVE` của `HT-DVC`; TA1 có MFA mới; giả lập PH-03 đo thời gian.

**Các bước.**

1. `POST /credentials/{id}:revoke` kèm lý do.
2. Gọi API cổng bằng định danh đó mỗi giây.
3. Thu hồi lần hai; thu hồi thiếu lý do; thiếu MFA.

**Kết quả mong đợi.** Bước 1: `200`, `REVOKED`; cổng từ chối trong ≤ 60 giây kể từ lệnh (chặn ở cổng trước, gọi PH-12 và PH-03 sau, thử lại tới khi xong). EVT: `EVT-01-07` một lần. Bước 3: `409` ERR-01-030; `400` ERR-01-033; `403` ERR-01-035. KT: có.
:::

#### TC-01-075 · Nhắc hạn 30, 14, 7 ngày và tự hết hạn <!--k:cred-expiry-->

::: dac-ta
**Loại.** Biên, Âm.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** FR-01-027 · UC-01-19 · API-01-048 · BR-01-020 · EVT-01-07, 08.

**Tiền điều kiện, dữ liệu.** Định danh chuỗi bí mật hạn 31 ngày; `credential.expiryReminderDays = [30,14,7]`; đồng hồ giả.

**Các bước.**

1. Chạy tác vụ hằng ngày ở các ngày còn 30, 14, 7, 0; `GET /credentials:expiring`.
2. Chạy cùng tác vụ với một định danh đã `REVOKED` và một định danh đã `EXPIRED`; dùng định danh hết hạn gọi cổng.

**Kết quả mong đợi.** Mỗi mốc đúng một `EVT-01-08` và thư nhắc tới đầu mối kỹ thuật, TA; sang ngày hết hạn: `EXPIRED`, `EVT-01-07`, cổng từ chối. Định danh đã thu hồi, đã hết hạn không bị nhắc lại, không phát sự kiện thứ hai; định danh hết hạn gọi cổng bị `401`. Định danh tạo mới có hạn ≤ 365 ngày, chuỗi bí mật ≤ 180 ngày.
:::

#### TC-01-076 · Tự vô hiệu định danh không dùng 90 ngày, bật lại (Đợt 2) <!--k:cred-inactive-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** IT.

**Truy vết.** FR-01-036 · UC-01-25 · API-01-061 · UI-01-04 · BR-01-022 · ERR-01-030 · EVT-01-07.

**Tiền điều kiện, dữ liệu.** Định danh PRODUCTION `tc-ngu`; PH-13 trả 0 lượt gọi trong 90 ngày; `inactivity.autoSuspendDays = 90`.

**Các bước.**

1. Chạy tác vụ ngày thứ 91; xem nhãn ở UI-01-04.
2. TA1 `POST /credentials/{id}:enable`; gọi `:enable` lần hai.

**Kết quả mong đợi.** Bước 1: vô hiệu với `reversible = true`, `EVT-01-07`. Bước 2: lần một `200`, lần hai `409` ERR-01-030.
:::

### TS-01-20 · Tạm ngừng, khôi phục HTTT và phân tích tác động

**Mục tiêu.** Xác nhận tạm ngừng cắt quyền trong 60 giây, phải xác nhận tác động trước khi tiếp tục, khôi phục chỉ khi đủ điều kiện, và sự kiện lan sang phân hệ khác chỉ một lần.

**Phủ.** FR-01-029, 030, 033; UC-01-20; API-01-051, 052, 056; UI-01-11; BR-01-009, 010, 015, 023; ERR-01-005, 032, 033, 034, 035, 036, 046, 048; EVT-01-03, 07; NFR-01-008.

#### TC-01-077 · Phân tích tác động phụ thuộc <!--k:impact-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-033 · UC-01-20 · API-01-056 · UI-01-11 · BR-01-023 · ERR-01-046.

**Tiền điều kiện, dữ liệu.** `HT-QLVB` có phụ thuộc ở PH-02, PH-05, PH-10 (giả lập); U-T68-TA1.

**Các bước.**

1. `GET /systems/HT-QLVB/impact`.
2. PH-02 giả lập `fail`; gọi lại.

**Kết quả mong đợi.** Bước 1: `200`, danh sách đăng ký, kết nối, luồng phụ thuộc theo phân hệ, đánh dấu HTTT thiết yếu. Bước 2: `503` ERR-01-046; UI-01-11 vẫn cho tiếp tục nhưng ghi "chưa phân tích đủ".
:::

#### TC-01-078 · Tạm ngừng có xác nhận tác động, cắt quyền ≤ 60 giây <!--k:suspend-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-029 · UC-01-20 · API-01-051 · UI-01-11 · BR-01-009, 023 · ERR-01-034 · EVT-01-03, 07 · NFR-01-008.

**Tiền điều kiện, dữ liệu.** `HT-QLVB` ACTIVE đang gọi API 5 lần/giây qua giả lập PH-03; TA1 có MFA mới.

**Các bước.**

1. `POST /systems/HT-QLVB:suspend` kèm lý do khi chưa xác nhận tác động.
2. Lặp với `confirmImpact = true`.
3. Đo thời gian từ lệnh tới khi cổng từ chối; kiểm ACL Kafka.

**Kết quả mong đợi.** Bước 1: `409` ERR-01-034 kèm danh sách phụ thuộc. Bước 2: `200`, `SUSPENDED`, định danh bị chặn. Bước 3: cổng từ chối ≤ 60 giây, ACL Kafka ≤ 2 phút. Đúng một `EVT-01-03` và `EVT-01-07` lan sang phân hệ khác (BR-01-023). KT: có.
:::

#### TC-01-079 · Tạm ngừng sai điều kiện <!--k:suspend-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-029 · API-01-051 · ERR-01-005, 033, 035, 001.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH` DRAFT; `HT-QLVB`; U-T68-OR1; U-T01-TA.

**Các bước.**

1. TA1 tạm ngừng không lý do; thiếu MFA mới.
2. TA1 tạm ngừng `HT-HOTICH` (DRAFT).
3. OR1 tạm ngừng `HT-QLVB`.
4. U-T01-TA tạm ngừng `HT-QLVB` của T68.

**Kết quả mong đợi.** `400` ERR-01-033; `403` ERR-01-035; `409` ERR-01-005; `403-PQ`; `404-ẩn`. Không có sự kiện nào phát ra.
:::

#### TC-01-080 · Khôi phục khi đủ điều kiện <!--k:resume-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-030 · UC-01-20 · API-01-052 · UI-01-11 · BR-01-009 · EVT-01-03.

**Tiền điều kiện, dữ liệu.** `HT-QLVB` SUSPENDED lý do `ADMIN`; cấp độ và căn cứ đạt; TA1 có MFA mới.

**Các bước.**

1. `POST …:resume` kèm lý do.

**Kết quả mong đợi.** `200`, `ACTIVE`; định danh được mở lại; `EVT-01-03`. KT: có.
:::

#### TC-01-081 · Khôi phục khi nghi lộ bí mật hoặc căn cứ hết hiệu lực <!--k:resume-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-030 · API-01-052 · BR-01-010, 015 · ERR-01-032, 036.

**Tiền điều kiện, dữ liệu.** `HT-DVC` SUSPENDED lý do `SECURITY_SUSPECT`; `HT-TUPHAP` SUSPENDED vì căn cứ hết hiệu lực; TA1, SO.

**Các bước.**

1. TA1 khôi phục `HT-DVC` khi SO chưa đồng ý.
2. SO đồng ý nhưng chưa xoay định danh; khôi phục.
3. Xoay định danh; SO khôi phục.
4. TA1 khôi phục `HT-TUPHAP` khi chưa có căn cứ mới qua thẩm định.

**Kết quả mong đợi.** `409` ERR-01-036; `422` ERR-01-032; bước 3 `200`; bước 4 `422` ERR-01-032.
:::

#### TC-01-082 · Thao tác trên HTTT đang tạm ngừng <!--k:suspended-ops-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-029 · API-01-039 · ERR-01-048.

**Tiền điều kiện, dữ liệu.** `HT-DVC` SUSPENDED; TA1.

**Các bước.**

1. Tạo liên kết bàn giao cho `HT-DVC`.

**Kết quả mong đợi.** `409` ERR-01-048; thông báo "chờ khôi phục hoặc xoay định danh".
:::

### TS-01-21 · Chấm dứt tư cách thành viên

**Mục tiêu.** Xác nhận chấm dứt cần đề nghị và duyệt bởi hai người khác nhau, xác nhận tác động, chờ giao dịch đang xử lý, thu hồi mọi định danh và giữ hồ sơ.

**Phủ.** FR-01-031; UC-01-21; API-01-053, 059; UI-01-11; BR-01-009, 011, 017, 018, 023; ERR-01-017, 033, 034; EVT-01-03, 07, 11.

#### TC-01-083 · Đề nghị và duyệt chấm dứt, giữ hồ sơ <!--k:term-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-031 · UC-01-21 · API-01-053, 059 · UI-01-11 · BR-01-011, 018, 023 · EVT-01-03, 07, 11.

**Tiền điều kiện, dữ liệu.** `HT-TUPHAP` ACTIVE; `terminate.drainMinutes = 5`; TA1 đề nghị, TA2 duyệt, đều có MFA mới.

**Các bước.**

1. TA1 `POST …:terminate` kèm lý do và xác nhận tác động.
2. TA2 `POST /change-requests/{changeRequestId}:decide` duyệt.
3. Sau 5 phút chờ, kiểm trạng thái, định danh, hồ sơ.

**Kết quả mong đợi.** Bước 1: `201`. Bước 2 và 3: `TERMINATED`; mọi định danh `REVOKED`; cổng từ chối ≤ 60 giây sau khi hết thời gian chờ; trần phạm vi thu hồi (`EVT-01-11`); hồ sơ, lịch sử giữ; mã `HT-TUPHAP` vẫn giữ. KT: có.
:::

#### TC-01-084 · Chấm dứt sai điều kiện <!--k:term-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-031 · API-01-053, 059 · BR-01-017 · ERR-01-017, 033, 034.

**Tiền điều kiện, dữ liệu.** `HT-TUPHAP`; TA1, TA2.

**Các bước.**

1. TA1 đề nghị không lý do; rồi khi chưa xác nhận tác động.
2. TA1 đề nghị hợp lệ rồi tự duyệt qua `:decide`.

**Kết quả mong đợi.** `400` ERR-01-033; `409` ERR-01-034; `403` ERR-01-017 (người đề nghị không duyệt); HTTT vẫn `ACTIVE`.
:::

#### TC-01-085 · Chấm dứt HTTT chưa kích hoạt <!--k:term-approved-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-01-031 · API-01-053, 059 · UC-01-21 · EVT-01-03.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-SB` APPROVED quá hạn kiểm thử.

**Các bước.**

1. Đề nghị và duyệt chấm dứt như ca trước.

**Kết quả mong đợi.** `APPROVED → TERMINATED`; định danh SANDBOX thu hồi; không có phụ thuộc cần phân tích.
:::

### TS-01-22 · Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT

**Mục tiêu.** Xác nhận SO cắt quyền HTTT ngay khi nghi lộ bí mật, TA xác nhận bổ sung trong hạn, quá hạn chỉ cảnh báo chứ không tự hoàn tác.

**Phủ.** FR-01-032, 053; UC-01-22; API-01-054, 055, 089; UI-01-11; BR-01-009, 010, 023; ERR-01-001, 003, 005, 033, 035, 036, 048, 052; EVT-01-15, 03, 07; NFR-01-008.

#### TC-01-086 · SO tạm ngừng khẩn, TA xác nhận <!--k:emerg-ok-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-032 · UC-01-22 · API-01-054, 055 · UI-01-11 · BR-01-010, 023 · EVT-01-15, 03, 07 · NFR-01-008.

**Tiền điều kiện, dữ liệu.** `HT-DVC` ACTIVE đang gọi API; U-T68-SO có MFA mới; TA1.

**Các bước.**

1. SO `POST /systems/HT-DVC:emergency-action` với `mode = SUSPEND`, lý do, `incidentRef`.
2. Đo thời gian cổng từ chối.
3. TA1 `POST /emergency-actions/{actionId}:confirm`.

**Kết quả mong đợi.** Bước 1: `200` ngay, không chờ TA; `SUSPENDED` lý do `SECURITY_SUSPECT`. Bước 2: ≤ 60 giây. Bước 3: `200`, ghi nhận xác nhận. EVT: `EVT-01-15` hai lần (thực hiện, xác nhận), `EVT-01-03`, `EVT-01-07`. KT: có.
:::

#### TC-01-087 · Thao tác khẩn sai điều kiện <!--k:emerg-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-032 · API-01-054, 055 · ERR-01-033, 035, 036.

**Tiền điều kiện, dữ liệu.** `HT-DVC`; thao tác khẩn đã xác nhận; U-T68-SO, TA1, OR1.

**Các bước.**

1. SO gọi không lý do; rồi thiếu MFA mới.
2. TA1 xác nhận lần hai thao tác đã xử lý.
3. OR1 gọi `:emergency-action`.

**Kết quả mong đợi.** `400` ERR-01-033; `403` ERR-01-035; `409` ERR-01-036; `403-PQ`.
:::

#### TC-01-088 · Quá 24 giờ chưa xác nhận: cảnh báo, không hoàn tác <!--k:emerg-overdue-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-01-032 · BR-01-010 · EVT-01-15.

**Tiền điều kiện, dữ liệu.** Thao tác khẩn chưa xác nhận; `emergency.confirmHours = 24`; đồng hồ giả.

**Các bước.**

1. Tua 25 giờ; chạy tác vụ.

**Kết quả mong đợi.** `EVT-01-15` loại "quá hạn", cảnh báo mức cao tới TA, PO; HTTT vẫn `SUSPENDED`, không tự khôi phục.
:::

#### TC-01-144 · TA khác xác nhận thao tác khẩn khi TA đầu vắng <!--k:emerg-alt-ta-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-032 · UC-01-22 · API-01-054, 055 · UI-01-11 · BR-01-010

**Tiền điều kiện, dữ liệu.** Thao tác khẩn `PENDING_CONFIRM` do U-T68-SO tạo trên `HT-DVC`; U-T68-TA1 (Minh) đặt vắng, không đăng nhập; U-T68-TA2 (Quang) hoạt động; tenant T68 có đúng hai TA hoạt động.

**Các bước.**

1. Việc xác nhận gửi tới cả TA1 và TA2; kiểm hộp việc của TA2.
2. TA2 `POST /emergency-actions/{actionId}:confirm` kèm MFA mới.
3. Xem lịch sử thao tác khẩn ở UI-01-11 và nhật ký kiểm toán.

**Kết quả mong đợi.** Bước 1: việc xác nhận có ở hộp việc của TA2, người gửi không phải SO. Bước 2: `200`, thao tác khẩn `CONFIRMED`, HTTT vẫn `SUSPENDED`. Bước 3: người xác nhận là TA2, không có lần xác nhận nào của SO. EVT: `EVT-01-15` (xác nhận). KT: có.
:::

#### TC-01-145 · Không ai ngoài TA xác nhận thay; xác nhận lần hai bị từ chối <!--k:emerg-alt-ta-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-032 · API-01-055 · BR-01-010 · ERR-01-036, 052

**Tiền điều kiện, dữ liệu.** Thao tác khẩn `PENDING_CONFIRM` trên `HT-DVC`; PA (U-PA, không giữ `PERM-01-approve` của T68); U-T68-SO; TA1, TA2.

**Các bước.**

1. PA `POST /emergency-actions/{actionId}:confirm`.
2. SO tự xác nhận thao tác do chính mình tạo.
3. TA2 xác nhận; sau đó TA1 xác nhận lần hai cùng thao tác.

**Kết quả mong đợi.** Bước 1: `403` ERR-01-052 (không có `PERM-01-approve`). Bước 2: `403` ERR-01-052. Bước 3: lần của TA2 `200`; lần của TA1 `409` ERR-01-036. Thao tác khẩn chỉ có một người xác nhận (TA2).
:::

#### TC-01-146 · PH-13 gửi đề xuất tạm ngừng, SO nhận việc khẩn <!--k:susp-prop-ok-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, API.

**Truy vết.** FR-01-053 · FR-01-032 · UC-01-22 · API-01-089 · UI-01-11 · BR-01-009, 010

**Tiền điều kiện, dữ liệu.** `HT-QLVB` ACTIVE ở T68; S-SP (token dịch vụ `onboarding:suspension-proposal` của T68); U-T68-SO; `mail-sink` và hộp việc PH-18 giả lập.

**Các bước.**

1. S-SP `POST /internal/suspension-proposals` với `systemCode = HT-QLVB`, `alertId` mới, `severity = HIGH`, `reason` 40 ký tự, `evidenceUrl`, `incidentRef = SEC-ALERT-2026-0142`.
2. Đọc hộp việc của SO và của TA.
3. Đọc trạng thái `HT-QLVB` và nhật ký kiểm toán.

**Kết quả mong đợi.** Bước 1: `202` có `Location`, thân `{ systemCode, alertId, taskId, accepted = true, duplicate = false }`. Bước 2: SO có một việc loại `ph01.review-suspension-proposal`, mức khẩn, kèm lý do, mức nghiêm trọng, liên kết UI-01-11 và liên kết sâu về cảnh báo; TA không có việc này. Bước 3: `HT-QLVB` vẫn `ACTIVE`, không có sự kiện EVT-01-03, EVT-01-15; có một dòng kiểm toán (bên gửi PH-13, `alertId`, HTTT, lý do). KT: có.
:::

#### TC-01-147 · Đề xuất lặp cùng alertId không tạo việc thứ hai <!--k:susp-prop-dup-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-01-053 · API-01-089 · BR-01-010

**Tiền điều kiện, dữ liệu.** Như ca `susp-prop-ok`; đã có một đề xuất với `alertId` A cho `HT-QLVB`.

**Các bước.**

1. S-SP gửi lại đúng đề xuất (cùng `systemCode`, `alertId = A`).
2. S-SP gửi đề xuất mới với `alertId = B` cho cùng HTTT.
3. Đếm việc `ph01.review-suspension-proposal` của SO.

**Kết quả mong đợi.** Bước 1: `202`, `duplicate = true`, `taskId` trùng lần đầu. Bước 2: `202`, `duplicate = false`, `taskId` mới. Bước 3: hai việc (A và B), không có việc thứ ba.
:::

#### TC-01-148 · Đề xuất tạm ngừng sai điều kiện <!--k:susp-prop-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-053 · API-01-089 · ERR-01-001, 003, 005, 048, 052

**Tiền điều kiện, dữ liệu.** S-SP của T68; S-INT (scope khác); token người dùng của U-T68-SO; `HT-QLVB` ACTIVE; `tc-susp` SUSPENDED; `HT-HOTICH-SB` APPROVED; `HT-TC-KHAC` chỉ có ở T01; S-SP-T01 (token của T01).

**Các bước.**

1. Gọi không token; rồi bằng S-INT; rồi bằng token của SO.
2. S-SP-T01 gửi đề xuất cho `HT-QLVB` (HTTT thuộc T68).
3. S-SP gửi `systemCode = HT-TC-KHAC` (T01), rồi mã không tồn tại.
4. S-SP gửi cho `tc-susp` (SUSPENDED), rồi cho `HT-HOTICH-SB` (APPROVED).
5. S-SP gửi `reason` 5 ký tự; `severity = LOW`; `alertId` không phải UUID; thiếu `alertId`.

**Kết quả mong đợi.** Bước 1: `401` ERR-01-052 khi không token; `403` ERR-01-052 với S-INT và token người dùng. Bước 2: `403` ERR-01-052 (tenant của token không trùng). Bước 3: `404` ERR-01-001, thân giống hệt nhau (404-ẩn). Bước 4: `409` ERR-01-048 cho `tc-susp`; `409` ERR-01-005 cho `HT-HOTICH-SB`. Bước 5: `400` ERR-01-003 kèm `errors[].path` đúng trường. Không ca nào tạo việc cho SO.
:::

#### TC-01-149 · SO xử lý việc đề xuất: xử lý khẩn hoặc không tạm ngừng <!--k:susp-prop-so-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** E2E, IT.

**Truy vết.** FR-01-053 · FR-01-032 · API-01-054, 089 · UI-01-11 · BR-01-009, 010

**Tiền điều kiện, dữ liệu.** Hai việc đề xuất đang mở cho U-T68-SO: việc P1 cho `HT-QLVB` (có `incidentRef`), việc P2 cho `HT-DATDAI`; SO có MFA mới.

**Các bước.**

1. SO mở việc P1, xem lý do và tác động phụ thuộc (FR-01-033), chọn "Xử lý khẩn" chế độ `SUSPEND`.
2. SO mở việc P2, chọn "Không tạm ngừng" kèm lý do.
3. Đọc hộp việc, trạng thái hai HTTT và kiểm toán.

**Kết quả mong đợi.** Bước 1: màn hình thao tác khẩn có sẵn `incidentRef` của đề xuất; `200`, `HT-QLVB` `SUSPENDED`; việc P1 tự đóng; EVT-01-15, EVT-01-03. Bước 2: việc P2 đóng, `HT-DATDAI` vẫn `ACTIVE`. Bước 3: không còn việc mở; kiểm toán ghi người đóng việc và quyết định của từng việc. Không có đường nào tạm ngừng mà SO không bấm.
:::

### TS-01-23 · Đề nghị thay đổi hồ sơ và mở rộng trần phạm vi

**Mục tiêu.** Xác nhận thay đổi hồ sơ sau kết nạp được duyệt theo mức, mở rộng phạm vi luôn qua thẩm định pháp lý lại, và trần không đổi trước khi duyệt.

**Phủ.** FR-01-034, 035, 054; UC-01-23, 24; API-01-057, 058, 059, 060; UI-01-04, 06, 07; BR-01-001, 003, 012, 025, 029; ERR-01-015, 016, 037, 038, 047, 049; EVT-01-04, 11.

#### TC-01-089 · Ba mức duyệt của thay đổi hồ sơ <!--k:chg-levels-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-034 · UC-01-23 · API-01-057, 058, 059 · UI-01-04, 07 · BR-01-025, 029 · EVT-01-04.

**Tiền điều kiện, dữ liệu.** `HT-TUPHAP` ACTIVE; U-T68-OR1; TA1; SO.

**Các bước.**

1. OR1 `POST …/change-requests` đổi mô tả.
2. OR1 đổi địa chỉ cơ sở và dải IP.
3. OR1 đổi cấp độ ATTT; TA1 và SO duyệt qua `POST /change-requests/{id}:decide`.
4. Đổi chủ quản sang Văn phòng UBND.

**Kết quả mong đợi.** Bước 1: `200`, áp dụng ngay. Bước 2: `202`, chờ duyệt kỹ thuật, `GET …/change-requests` thấy yêu cầu. Bước 3: áp dụng khi cả hai duyệt; `EVT-01-04`. Bước 4: cần tổ chức mới xác nhận rồi TA duyệt.
:::

#### TC-01-090 · Thay đổi sai: chồng yêu cầu, qua đường thường để mở rộng, địa chỉ http <!--k:chg-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-034 · API-01-057 · BR-01-012 · ERR-01-037, 038, 049.

**Tiền điều kiện, dữ liệu.** `HT-TUPHAP` có yêu cầu thay đổi đang chờ; OR1.

**Các bước.**

1. Gửi thêm yêu cầu thay đổi khi đang chờ.
2. Gửi thay đổi nhu cầu có thêm một mục `CONSUME` qua đường thay đổi thường.
3. Gửi địa chỉ `http://…`.

**Kết quả mong đợi.** `409` ERR-01-038; `422` ERR-01-037; `422` ERR-01-049.
:::

#### TC-01-091 · Mở rộng trần phạm vi: thẩm định lại, trần đổi khi duyệt <!--k:expand-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-035 · UC-01-24 · API-01-060, 059 · UI-01-04, 06, 07 · BR-01-003, 012 · EVT-01-11.

**Tiền điều kiện, dữ liệu.** `HT-TUPHAP`; mục mở rộng có căn cứ F-PDF-VB; người thẩm định LEGAL được giao; TA duyệt khác người đề nghị.

**Các bước.**

1. OR1 `POST …/scope-expansions`; kiểm trần.
2. Người thẩm định ghi kết luận pháp lý cho mục mới.
3. TA duyệt.

**Kết quả mong đợi.** Bước 1: `202`, trần **không đổi**. Bước 3: trần tăng đúng mục được chấp thuận, không hơn; `EVT-01-11`. KT: có.
:::

#### TC-01-092 · Mở rộng phạm vi sai: thiếu căn cứ, bí mật nhà nước, cấp độ thấp <!--k:expand-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-035 · API-01-060 · BR-01-001, 004, 026 · ERR-01-015, 016, 038, 047.

**Tiền điều kiện, dữ liệu.** `HT-TUPHAP` cấp độ `L2`; OR1.

**Các bước.**

1. `POST …/scope-expansions` thiếu căn cứ.
2. Mục `BMNN-TEST`.
3. Mục mức Hạn chế khi HTTT `L2`.
4. Gửi khi đã có mở rộng đang chờ.

**Kết quả mong đợi.** `422` ERR-01-015; `422` ERR-01-016; `422` ERR-01-047; `409` ERR-01-038.
:::

#### TC-01-150 · Tổ chức giải thể: tạo sẵn đề nghị đổi chủ quản cho cả lô <!--k:owner-batch-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT, E2E.

**Truy vết.** FR-01-054 · FR-01-034 · UC-01-23 · API-01-058, 059 · UI-01-04, 07 · BR-01-017, 029 · EVT-01-04

**Tiền điều kiện, dữ liệu.** Tổ chức `TC-ORG-CU` có ba HTTT: `tc-own-act` ACTIVE, `tc-own-sus` SUSPENDED, `tc-own-app` APPROVED; thêm `tc-own-ter` TERMINATED; tổ chức kế thừa `TC-ORG-MOI` ACTIVE; PH-20 giả lập phát EVT-20-13 với `change = DISSOLVED`, `successorCode = TC-ORG-MOI`; TA1, TA2.

**Các bước.**

1. PH-20 giả lập phát EVT-20-13 một lần.
2. TA1 `GET /change-requests?type=OWNER_CHANGE&status=PENDING` (API-01-058) và mở lô ở UI-01-07.
3. TA1 bấm "Duyệt cả lô" (giao diện gọi API-01-059 từng yêu cầu).
4. Đọc `ownerOrgId` của bốn HTTT và nhật ký kiểm toán.

**Kết quả mong đợi.** Bước 2: đúng ba yêu cầu `OWNER_CHANGE` `PENDING` sang `TC-ORG-MOI` (không có cho `tc-own-ter`); người đề nghị `system:ph01-org-successor`, `owner_confirmed_by = system:ph20-successor`, `diff.source = EVT-20-13`, mã lô là mã sự kiện; TA có một việc `ph01.approve-change` gom ba yêu cầu. Bước 1: chưa HTTT nào đổi chủ quản. Bước 3: ba lần `200`, kết quả riêng từng HTTT; `ownerOrgId = TC-ORG-MOI` cho ba HTTT, `tc-own-ter` giữ nguyên. EVT: `EVT-01-04` ba lần. KT: có sự kiện nguồn, từng yêu cầu và người duyệt.
:::

#### TC-01-151 · Giải thể, sáp nhập: trường hợp không tạo, trùng, duyệt lệch <!--k:owner-batch-neg-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-01-054 · FR-01-034 · API-01-058, 059 · BR-01-017, 029 · ERR-01-005

**Tiền điều kiện, dữ liệu.** Như ca `owner-batch-ok`; thêm `tc-own-pend` ACTIVE của `TC-ORG-CU` đã có yêu cầu thay đổi khác `PENDING`; tổ chức `TC-ORG-NGHI` (không ACTIVE); TA1, TA2.

**Các bước.**

1. PH-20 giả lập phát EVT-20-13 `DISSOLVED` cho `TC-ORG-CU` (có `tc-own-pend`), rồi phát lại đúng sự kiện đó (cùng mã sự kiện).
2. Phát EVT-20-13 `DISSOLVED` thiếu `successorCode`; rồi với `successorCode = TC-ORG-NGHI`.
3. Phát EVT-20-13 cho tổ chức không có HTTT.
4. Với lô ở ca `owner-batch-ok`, TA2 duyệt `tc-own-act` trước; sau đó TA1 duyệt cả lô.
5. TA1 từ chối yêu cầu của `tc-own-app`.

**Kết quả mong đợi.** Bước 1: lần đầu không tạo yêu cầu cho `tc-own-pend` (chỉ mục duy nhất của EN-01-13), HTTT vào danh sách "chờ tạo lại" của lô và TA được nhắc xử lý yêu cầu cũ; lần phát lại bị bỏ qua nhờ `inbox(event_id)`, không tạo thêm yêu cầu. Bước 2: không tạo yêu cầu, TA nhận nhắc đổi chủ quản từng HTTT theo FR-01-034. Bước 3: không phát sinh việc. Bước 4: dòng `tc-own-act` của TA1 trả `409` ERR-01-005, các dòng khác `200`. Bước 5: `tc-own-app` giữ chủ quản cũ, hiện cờ "chủ quản đã giải thể".
:::

### TS-01-24 · Đồng bộ trạng thái và bản sao đọc cho phân hệ khác

**Mục tiêu.** Xác nhận mọi chuyển trạng thái phát sự kiện trong cùng giao dịch, không mất khi Kafka ngừng, có ảnh chụp đối chiếu, và bản sao đọc nội bộ đúng phạm vi.

**Phủ.** FR-01-037, 038; UC-01-26; API-01-062, 063, 064; BR-01-023, 030, 031; ERR-01-001, 003, 052; EVT-01-03, 04; NFR-01-021.

#### TC-01-093 · Sự kiện trạng thái qua outbox, không mất khi Kafka ngừng <!--k:sync-outbox-->

::: dac-ta
**Loại.** Dương, Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** FR-01-037 · UC-01-26 · BR-01-031 · EVT-01-03, 04 · NFR-01-021.

**Tiền điều kiện, dữ liệu.** Kafka, Debezium thật; U-T68-TA1; một HTTT thử.

**Các bước.**

1. Thực hiện năm chuyển trạng thái liên tiếp; đọc topic.
2. Dừng Kafka; thực hiện hai chuyển; khởi động lại.

**Kết quả mong đợi.** Bước 1: năm bản `EVT-01-03` đúng thứ tự theo `systemCode`, p95 ≤ 5 giây từ commit. Bước 2: API vẫn trả thành công; sau khi Kafka lên, hai bản còn lại được phát, không trùng, không mất.
:::

#### TC-01-094 · Đối chiếu và ảnh chụp trạng thái <!--k:reconcile-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** API.

**Truy vết.** FR-01-037 · API-01-062 · EVT-01-03 · ERR-01-052.

**Tiền điều kiện, dữ liệu.** S-RECON; token S-INT; U-T68-TA1.

**Các bước.**

1. S-RECON `POST /internal/reconciliations`.
2. Gọi bằng S-INT và bằng token người dùng TA1.

**Kết quả mong đợi.** Bước 1: `202`; mỗi HTTT hoạt động có một `EVT-01-03` với `snapshot = true`. Bước 2: `403-PQ` (sai scope).
:::

#### TC-01-095 · Bản sao đọc nội bộ: đúng scope, đúng tenant, không bí mật <!--k:internal-read-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-038 · UC-01-26 · API-01-063, 064 · BR-01-030 · ERR-01-001, 003, 052.

**Tiền điều kiện, dữ liệu.** S-INT của T68; S-INT-T01 (token dịch vụ của T01); `HT-QLVB` có ở cả hai tenant.

**Các bước.**

1. S-INT `GET /internal/systems?status=ACTIVE`; `GET /internal/systems/HT-QLVB`.
2. S-INT `GET /internal/systems/HT-TC-KHAC`.
3. Token người dùng gọi `/internal/systems`; S-INT gọi `?status=SAI`.

**Kết quả mong đợi.** Bước 1: `200`, bản T68, không có đầu mối `SECURITY`, không có `secret_ref` hay bí mật. Bước 2: `404-ẩn`. Bước 3: `403-PQ`; `400` ERR-01-003.
:::

### TS-01-25 · Rà soát quyền: mở kỳ, mức sử dụng, hiệu lực căn cứ

**Mục tiêu.** Xác nhận kỳ rà soát mở đúng chu kỳ, tổng hợp mức dùng thực tế theo từng phạm vi, và căn cứ pháp lý hết hiệu lực làm tạm ngừng phạm vi ngay.

**Phủ.** FR-01-039, 040, 043; UC-01-27; API-01-065, 066, 067, 068, 073; UI-01-12; BR-01-014, 015; ERR-01-003, 039, 044, 046; EVT-01-11.

#### TC-01-096 · Mở kỳ rà soát và tổng hợp mức sử dụng <!--k:review-open-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-039, 040 · UC-01-27 · API-01-065, 066, 067, 068 · UI-01-12 · BR-01-014.

**Tiền điều kiện, dữ liệu.** Các HTTT ACTIVE có số lần dùng từng phạm vi ở giả lập PH-13 (có phạm vi 0 lần trong 400 ngày); U-T68-TA1.

**Các bước.**

1. TA1 `POST /access-reviews` kèm `Idempotency-Key`; `GET /access-reviews/{cycleCode}`.
2. `GET /access-reviews/{cycleCode}/items`.
3. Tua 6 tháng, chạy tác vụ lịch.

**Kết quả mong đợi.** Bước 1: `201`, kỳ `OPEN` gồm mọi HTTT ACTIVE. Bước 2: mỗi phạm vi có số lần dùng, căn cứ, hiệu lực, đề xuất; phạm vi không dùng quá 365 ngày đề xuất thu hồi. Bước 3: kỳ mới tự mở. KT: có.
:::

#### TC-01-097 · Mở kỳ khi đã có kỳ mở, tham số vượt miền, PH-13 ngừng <!--k:review-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-039, 040 · API-01-065, 068 · BR-01-014 · ERR-01-039, 044, 046.

**Tiền điều kiện, dữ liệu.** Kỳ `OPEN` có sẵn; TA1; PH-13 giả lập `fail`.

**Các bước.**

1. Mở kỳ thứ hai.
2. Đặt `accessReview.intervalMonths = 7`.
3. `GET …/items` khi PH-13 `fail`.

**Kết quả mong đợi.** `409` ERR-01-039; `422` ERR-01-044 (tối đa 6 tháng để thỏa BR-01-014); `503` ERR-01-046 và mục hiện "chưa có số liệu", không đề xuất sai.
:::

#### TC-01-098 · Căn cứ hết hiệu lực: tạm ngừng phạm vi ngay <!--k:legal-expired-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-01-043 · UC-01-27 · API-01-073 · UI-01-12 · BR-01-015 · ERR-01-003 · EVT-01-11.

**Tiền điều kiện, dữ liệu.** Phạm vi có căn cứ "Văn bản X" có ngày hết hiệu lực; U-T68-SO.

**Các bước.**

1. Chạy tác vụ ở ngày sau hiệu lực; xem nhãn "Căn cứ hết hiệu lực".
2. SO `POST /scope-ceilings:mark-legal-expired` với văn bản bãi bỏ thủ công.
3. Gửi mã văn bản không tồn tại.

**Kết quả mong đợi.** Bước 1 và 2: phạm vi tương ứng tạm ngừng ngay, không chờ kỳ rà soát; `EVT-01-11`; định danh mất scope đó trong ≤ 60 giây. Bước 3: `400` ERR-01-003.
:::

### TS-01-26 · Xác nhận của đơn vị, xử lý kết quả và báo cáo rà soát

**Mục tiêu.** Xác nhận phiếu xác nhận chỉ gửi và mở đúng người, đơn vị không phản hồi thì đề xuất thu hẹp, quyết định có lý do và MFA, và báo cáo giữ bằng chứng.

**Phủ.** FR-01-041, 042, 044; UC-01-28, 29; API-01-069, 070, 071, 072, 074, 075; UI-01-12, 13; BR-01-003, 009, 014; ERR-01-020, 025, 033, 035, 040, 041; EVT-01-11, 12.

#### TC-01-099 · Gửi phiếu và đơn vị trả lời <!--k:confirm-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-041 · UC-01-28 · API-01-069, 070, 071 · UI-01-12, 13 · BR-01-014.

**Tiền điều kiện, dữ liệu.** Kỳ `OPEN`; U-T68-TA1; U-T68-OR1 (Sở Tư pháp).

**Các bước.**

1. TA1 `POST …:send-confirmations`.
2. Đọc thư mail-sink; OR1 mở liên kết, đăng nhập MFA; `GET /access-review-confirmations/{token}`.
3. OR1 `POST …:respond`: phạm vi 1 "Còn cần", phạm vi 2 "Thu hẹp", phạm vi 3 "Không cần".

**Kết quả mong đợi.** Bước 1: `202`, kỳ `WAITING`. Bước 2: thư chỉ có liên kết (hạn 30 ngày); phiếu liệt kê phạm vi của đơn vị kèm mức dùng thực tế. Bước 3: `200`, phản hồi lưu; hết phản hồi thì kỳ sang `DECIDING`.
:::

#### TC-01-100 · Phiếu: sai người, hết hạn, đã trả lời <!--k:confirm-neg-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-041 · API-01-070, 071 · ERR-01-025, 040.

**Tiền điều kiện, dữ liệu.** Phiếu `PENDING` của Sở Tư pháp; phiếu quá 30 ngày; phiếu đã trả lời; U-T68-OR2.

**Các bước.**

1. OR2 (tổ chức khác) mở phiếu của Sở Tư pháp.
2. OR1 mở phiếu quá hạn; trả lời lần hai phiếu đã trả lời.

**Kết quả mong đợi.** `403` ERR-01-025; `410` ERR-01-040 cho cả hai.
:::

#### TC-01-101 · Đơn vị không phản hồi sau 30 ngày: đề xuất thu hẹp <!--k:confirm-timeout-->

::: dac-ta
**Loại.** Biên.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-01-041, 042 · UC-01-28 · BR-01-014 · API-01-068.

**Tiền điều kiện, dữ liệu.** Phiếu đã gửi; `accessReview.noResponseDays = 30`; đồng hồ giả.

**Các bước.**

1. Tua 31 ngày; chạy tác vụ; `GET …/items`.

**Kết quả mong đợi.** Kỳ sang `DECIDING`; các phạm vi của đơn vị không phản hồi có đề xuất "Thu hẹp".
:::

#### TC-01-102 · Quyết định thu hẹp, thu hồi phạm vi và đóng kỳ <!--k:review-decide-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-042 · UC-01-29 · API-01-072 · UI-01-12 · BR-01-003, 009 · ERR-01-020, 033, 035, 041 · EVT-01-11, 12.

**Tiền điều kiện, dữ liệu.** Kỳ `DECIDING`; kỳ `OPEN`; TA1 có MFA mới.

**Các bước.**

1. `POST …/items:decide` thu hẹp một phạm vi, thu hồi một phạm vi, kèm lý do.
2. Lặp với (a) thiếu lý do; (b) thiếu MFA; (c) quyết định ngoài danh sách; (d) kỳ đang `OPEN`.
3. Xử lý hết mục; xem kỳ.

**Kết quả mong đợi.** Bước 1: `200`; trần thu hẹp hoặc thu hồi, `EVT-01-11`. Bước 2: (a) `400` ERR-01-033; (b) `403` ERR-01-035; (c) `422` ERR-01-041; (d) `409` ERR-01-020. Bước 3: kỳ `CLOSED`, `EVT-01-12`, bằng chứng giữ 5 năm.
:::

#### TC-01-103 · Báo cáo rà soát và xuất (Đợt 2) <!--k:review-report-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-01-044 · UC-01-29 · API-01-074, 075 · UI-01-12 · ERR-01-020, 052.

**Tiền điều kiện, dữ liệu.** Kỳ `CLOSED`; kỳ `OPEN`; U-T68-AU; U-T68-OR1.

**Các bước.**

1. AU `GET …/report`; `POST …/report:export`.
2. AU gọi báo cáo kỳ `OPEN`; OR1 gọi báo cáo.

**Kết quả mong đợi.** Bước 1: `200` rồi `202`, tệp có đủ quyết định, người quyết, lý do. Bước 2: `409` ERR-01-020; `403-PQ`.
:::

### TS-01-27 · Danh bạ đầu mối

**Mục tiêu.** Xác nhận danh bạ công khai trong phạm vi tenant theo loại đầu mối, đầu mối an ninh ẩn, giới hạn tốc độ, cảnh báo tổ chức thiếu đầu mối.

**Phủ.** FR-01-045, 046, 047; UC-01-30, 31; API-01-076, 077, 078, 079; UI-01-14; BR-01-013, 027, 028, 030; ERR-01-001, 033, 045; EVT-01-14; CMP-LAW-05.

#### TC-01-104 · Tra cứu danh bạ, đầu mối an ninh ẩn <!--k:dir-search-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-045 · UC-01-30 · API-01-076, 077 · UI-01-14 · BR-01-027 · ERR-01-001 · CMP-LAW-05.

**Tiền điều kiện, dữ liệu.** U-T68-VW; U-T68-SO; U-T01-OR; tổ chức Sở Tư pháp có ba loại đầu mối.

**Các bước.**

1. VW `GET /directory/contacts?q=Phúc`; `GET /directory/organizations/{orgId}/contacts`.
2. SO gọi lại.
3. U-T01-OR gọi với `orgId` của T68.

**Kết quả mong đợi.** Bước 1: có đầu mối `BUSINESS`, `TECHNICAL` (họ tên, chức vụ, điện thoại, thư); không có `SECURITY`. Bước 2: SO thấy `SECURITY`. Bước 3: `404-ẩn`.
:::

#### TC-01-105 · Giới hạn tốc độ tra cứu <!--k:dir-rate-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P2.

**Tự động.** API, ZAP.

**Truy vết.** FR-01-045 · API-01-076 · BR-01-027 · ERR-01-045.

**Tiền điều kiện, dữ liệu.** U-T68-VW; `directory.rateLimitPerMinute = 60`.

**Các bước.**

1. Gọi `GET /directory/contacts` 61 lần trong một phút; U-T68-TO gọi một lần.

**Kết quả mong đợi.** Lần 61 `429` ERR-01-045 kèm `Retry-After`; U-T68-TO không bị ảnh hưởng (giới hạn theo người dùng).
:::

#### TC-01-106 · Tổ chức thiếu đầu mối, thư bị trả, nhắc cập nhật <!--k:dir-gap-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** FR-01-046 · UC-01-31 · API-01-078 · UI-01-14 · BR-01-013, 028 · ERR-01-010, 050 · EVT-01-14.

**Tiền điều kiện, dữ liệu.** Tổ chức "Sở X" có HTTT mà đầu mối kỹ thuật duy nhất bị thư trả lại; `directory.staleMonths = 12`; U-T68-TA1.

**Các bước.**

1. Giả lập thư bị trả; chạy tác vụ hằng ngày; `GET /directory/gaps`.
2. Tua 13 tháng; chạy tác vụ.
3. Cán bộ của "Sở X" nộp hồ sơ HTTT mới; chạy tác vụ với tổ chức khác còn đủ đầu mối kỹ thuật.

**Kết quả mong đợi.** Bước 1: đầu mối đánh dấu không hoạt động; "Sở X" có trong danh sách thiếu đầu mối; `EVT-01-14`; tổ chức đó không nộp được hồ sơ HTTT mới (ERR-01-010). Bước 2: nhắc cập nhật cho đầu mối lâu không xác nhận. Bước 3: nộp `422` ERR-01-010; tổ chức đủ đầu mối không có cảnh báo và không phát `EVT-01-14`.
:::

#### TC-01-107 · Xuất danh bạ (Đợt 2) <!--k:dir-export-->

::: dac-ta
**Loại.** Dương, Âm, Bảo mật.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-01-047 · UC-01-30 · API-01-079, 088 · UI-01-14 · ERR-01-033, 045, 052.

**Tiền điều kiện, dữ liệu.** U-T68-AU; U-T68-TA1; U-T68-OR1.

**Các bước.**

1. AU `POST /directory/contacts:export` với `format = XLSX`, `purpose`.
2. Gọi thiếu `purpose`; OR1 xuất toàn bộ.
3. Gọi liên tục vượt giới hạn.

**Kết quả mong đợi.** `200` hoặc `202`, tệp không chứa đầu mối `SECURITY`; `400` ERR-01-033; `403-PQ`; `429` ERR-01-045. KT: có (mục đích, người xuất).
:::

### TS-01-28 · Nhập HTTT từ hệ cũ, tham số phân hệ, thống kê

**Mục tiêu.** Xác nhận nhập Application của APIM và publisher, subscriber của Hub vào hồ sơ nháp không mang bí mật, tham số theo tenant có miền và lý do, thống kê đúng.

**Phủ.** FR-01-048, 049, 051; UC-01-32, 33, 34; API-01-080, 081, 082, 083, 084, 086; UI-01-15, 16, 17; BR-01-009, 014, 018, 020, 032, 033; ERR-01-003, 033, 035, 042, 043, 044; LGC-APIM-019; 020; LGC-HUB-010, 011.

#### TC-01-108 · Nhập hệ cũ: xem trước, gộp vai trò, tạo nháp <!--k:legacy-ok-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-048 · UC-01-32 · API-01-080, 081, 082 · UI-01-15 · BR-01-018, 033 · LGC-APIM-019; 020 · LGC-HUB-010, 011.

**Tiền điều kiện, dữ liệu.** U-PA hoặc U-T68-TA1; F-LEGACY-OK (20 Application, 8 publisher, 6 subscriber trong đó 5 trùng tên Application).

**Các bước.**

1. `POST /legacy-imports` tải F-LEGACY-OK; `GET /legacy-imports/{jobId}`.
2. Xác nhận ghép tổ chức; `POST …:confirm`.
3. `GET /systems?status=DRAFT`.

**Kết quả mong đợi.** Bước 1: xem trước nêu ghép tổ chức, gộp vai trò (Application + publisher, subscriber trùng thành một HTTT nhiều vai trò `CONSUMER`, `PUBLISHER`, `SUBSCRIBER`), số bí mật bỏ. Bước 2 và 3: các HTTT ở `DRAFT`, không tự `ACTIVE`, không định danh; mã bất biến; không có tệp gốc nào còn bí mật.
:::

#### TC-01-109 · Nhập hệ cũ sai: cấu trúc, trùng, vượt số dòng, sai quyền <!--k:legacy-neg-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-048 · API-01-080, 082 · ERR-01-042, 043, 044.

**Tiền điều kiện, dữ liệu.** F-LEGACY-BAD, F-LEGACY-DUP; tệp 5.001 dòng; `legacyImport.maxRows = 5.000`; U-T68-OR1.

**Các bước.**

1. Tải F-LEGACY-BAD; F-LEGACY-DUP; tệp 5.001 dòng.
2. OR1 gọi `POST /legacy-imports`.

**Kết quả mong đợi.** `400` ERR-01-042 nêu cột thiếu; `409` ERR-01-043 nêu bản ghi trùng; `422` ERR-01-044; `403-PQ`.
:::

#### TC-01-110 · Nhập hệ cũ không mang bí mật <!--k:legacy-secret-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, IT.

**Truy vết.** FR-01-048 · API-01-080, 081 · BR-01-007, 033 · NFR-01-009.

**Tiền điều kiện, dữ liệu.** F-LEGACY-SECRET có 12 cột bí mật mang giá trị `DH-CANARY-legacy-*`.

**Các bước.**

1. Tải tệp; xem trước; xác nhận.
2. Tìm giá trị mồi ở mọi nơi.

**Kết quả mong đợi.** `secretsDropped = 12`; Mồi sạch ở API, bảng PH-01, log, vết, outbox, tệp tải (tệp tạm bị xóa sau xử lý); định danh phải cấp lại qua kết nạp.
:::

#### TC-01-111 · Sửa tham số tenant có miền, lý do, MFA <!--k:settings-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** FR-01-049 · UC-01-33 · API-01-083, 084 · UI-01-16 · BR-01-009, 014, 020 · ERR-01-033, 035, 044.

**Tiền điều kiện, dữ liệu.** `T90`; TA của T90; U-PA; U-T68-OR1.

**Các bước.**

1. `PUT /settings/review.slaWorkingDays` giá trị 3, kèm lý do, MFA mới.
2. Gửi giá trị 11; không lý do; không MFA.
3. OR1 gọi `PUT`; `GET /settings` bởi VW.
4. PA đặt trần nền tảng thấp hơn; TA gửi giá trị vượt trần.

**Kết quả mong đợi.** Bước 1: `200`, hồ sơ nộp mới có hạn 3 ngày (không hồi tố hồ sơ cũ), lịch sử sửa có người, lý do. Bước 2: `422` ERR-01-044; `400` ERR-01-033; `403` ERR-01-035. Bước 3: `403-PQ`; `200`. Bước 4: `422` ERR-01-044.
:::

#### TC-01-112 · Thống kê kết nạp (Đợt 2) <!--k:stats-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P3.

**Tự động.** API.

**Truy vết.** FR-01-051 · UC-01-34 · API-01-086 · UI-01-17 · ERR-01-003.

**Tiền điều kiện, dữ liệu.** 40 hồ sơ ở các giai đoạn; U-T68-VW.

**Các bước.**

1. `GET /statistics?tu=2026-01-01&den=2026-12-31`.
2. Gọi với khoảng sai (`tu` sau `den`).

**Kết quả mong đợi.** `200` có thời gian trung bình từng giai đoạn, tỷ lệ trả bổ sung, hồ sơ quá hạn, đối chiếu KPI-05; số khớp chỉ số `onboarding_stage_duration_days`. Bước 2: `400` ERR-01-003.
:::

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Các kịch bản dưới đây chạy lại ở mỗi đợt phát hành; TS-01-29, 30, 31, 33 là điều kiện bắt buộc đạt 100 %. Vì PH-01 không nằm trên đường dữ liệu, kịch bản hiệu năng chỉ kiểm các chỉ tiêu của mặt phẳng điều khiển và tốc độ cắt quyền.

### TS-01-29 · Không lộ bí mật

**Mục tiêu.** Chứng minh NFR-01-009: ngoài phản hồi mở bàn giao, không bí mật nào xuất hiện ở bất kỳ nơi nào của PH-01.

**Phủ.** NFR-01-009, 010, 011; FR-01-020, 021, 022, 025; BR-01-005, 006, 007; API-01-040, 045, 088; ERR-01-023, 021.

#### TC-01-113 · Dò mồi trên toàn luồng cấp, bàn giao, xoay vòng, thu hồi <!--k:canary-flow-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-01-009 · FR-01-020, 022, 025, 026 · BR-01-007 · API-01-040, 045.

**Tiền điều kiện, dữ liệu.** Giả lập PH-12 trả bí mật có chuỗi `DH-CANARY-flow`; OpenBao thật; U-T68-TECH, TA1.

**Các bước.**

1. Chạy: phê duyệt, saga, bàn giao, xoay vòng, thu hồi.
2. Quét phản hồi API, log 5 phút, vết OTel, bảng `ph01_onboarding.*`, outbox, Kafka, thư mail-sink.

**Kết quả mong đợi.** `DH-CANARY-flow` chỉ có trong phản hồi `POST /handovers:open` và trong OpenBao; mọi nơi khác 0 lần xuất hiện.
:::

#### TC-01-114 · Dò mồi khi xảy ra lỗi <!--k:canary-error-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT, Chaos.

**Truy vết.** NFR-01-009 · ERR-01-021, 023 · API-01-035, 040.

**Tiền điều kiện, dữ liệu.** Mồi `DH-CANARY-err` trong bí mật giả lập; PH-12 và OpenBao điều khiển được.

**Các bước.**

1. Gây lỗi giữa saga; gây lỗi khi mở bàn giao; gây lỗi khi xoay vòng.
2. Quét thân lỗi RFC 9457 (trường `detail`, `errors`), log, vết.

**Kết quả mong đợi.** Không có `DH-CANARY-err` ở thân lỗi, log, vết, kể cả ngăn xếp ngoại lệ.
:::

#### TC-01-115 · Dò mồi ở tệp xuất, thư thông báo, báo cáo <!--k:canary-export-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-01-009 · API-01-075, 079, 085, 088 · FR-01-050.

**Tiền điều kiện, dữ liệu.** HTTT có định danh mang `DH-CANARY-exp`; U-T68-AU.

**Các bước.**

1. Xuất danh sách HTTT, danh bạ, báo cáo rà soát; tải qua `GET /jobs/{jobId}`.
2. Đọc mọi thư của mail-sink.

**Kết quả mong đợi.** Không có `DH-CANARY-exp` ở tệp xuất lẫn thư; thư bàn giao chỉ có liên kết.
:::

#### TC-01-116 · Lược đồ CSDL không có chỗ lưu bí mật <!--k:no-secret-columns-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P2.

**Tự động.** DB.

**Truy vết.** BR-01-007 · NFR-01-009 · FR-01-020, 021.

**Tiền điều kiện, dữ liệu.** Lược đồ `ph01_onboarding` theo D03-03-PH01.

**Các bước.**

1. Liệt kê cột có tên hay kiểu có thể chứa bí mật, khóa riêng (`secret`, `password`, `private`, `token` ngoài `*_ref`, `*_hash`).

**Kết quả mong đợi.** Chỉ có `secret_ref`, vân tay, giá trị băm; không có cột bí mật.
:::

### TS-01-30 · Cách ly tenant và RLS

**Mục tiêu.** Chứng minh tenant này không đọc, không ghi, không suy ra được sự tồn tại của hồ sơ tenant khác, ở API, CSDL, Kafka và kho tệp.

**Phủ.** BR-01-030; API-01-006, 008, 014, 036, 043, 049, 050, 058, 067, 074, 088; FR-01-002, 005, 008, 019, 023, 028; ERR-01-001.

#### TC-01-117 · RLS ở CSDL <!--k:rls-db-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** DB.

**Truy vết.** BR-01-030 · FR-01-002 · UC-01-01.

**Tiền điều kiện, dữ liệu.** Dữ liệu T68 và T01 ở mọi bảng của `ph01_onboarding`.

**Các bước.**

1. Đặt `app.tenant_id = T68`; đọc mọi bảng.
2. Không đặt tenant; đọc.
3. Với T68 chèn, sửa một dòng có `tenant_id = T01`.

**Kết quả mong đợi.** Chỉ thấy dòng T68; không đặt tenant thì 0 dòng; chèn, sửa dòng tenant khác bị chính sách RLS chặn.
:::

#### TC-01-118 · Mọi API đọc trả "không tồn tại" cho tenant khác <!--k:cross-read-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-01-030 · API-01-006, 008, 014, 036, 043, 049, 050, 058, 067, 074 · ERR-01-001.

**Tiền điều kiện, dữ liệu.** U-T68-TA1; đối tượng tương ứng chỉ có ở T01 (HTTT `HT-TC-KHAC`, tệp, đầu mối, định danh, kỳ rà soát, yêu cầu thay đổi).

**Các bước.**

1. Tham số hóa các API đọc theo danh sách trên, gọi bằng id của T01.
2. So thân với id không tồn tại.

**Kết quả mong đợi.** Tất cả `404-ẩn`, thân giống hệt trừ `traceId`, thời gian phản hồi không khác biệt có thể phân biệt.
:::

#### TC-01-119 · Mọi API ghi, hành động không tác động tenant khác <!--k:cross-write-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-01-030 · API-01-005, 018, 023, 032, 045, 047, 051, 057, 088 · ERR-01-001.

**Tiền điều kiện, dữ liệu.** U-T68-TA1 có đủ quyền ở T68; `HT-TC-KHAC` của T01 (ACTIVE).

**Các bước.**

1. Gọi `PATCH`, `:submit`, `:approve`, `:suspend`, `:terminate`, `:rotate`, `:revoke`, `change-requests` vào `HT-TC-KHAC` và định danh của nó.
2. Đọc lại `HT-TC-KHAC` bằng U-T01-TA.

**Kết quả mong đợi.** Mọi lệnh `404-ẩn`; `HT-TC-KHAC` không đổi (ETag, trạng thái, lịch sử); không sự kiện, không kiểm toán nghiệp vụ ở T01.
:::

#### TC-01-120 · Kafka và kho tệp theo tenant <!--k:cross-kafka-file-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** BR-01-030 · NFR-01-011 · EVT-01-03 · FR-01-005.

**Tiền điều kiện, dữ liệu.** Hai bộ tiêu thụ thử: `t68.*` và `t01.*`; tệp đính kèm ở cả hai tenant.

**Các bước.**

1. Thực hiện chuyển trạng thái ở T68; đọc topic T01.
2. Dùng thông tin xác thực của T01 truy cập trực tiếp đường dẫn đối tượng của T68.

**Kết quả mong đợi.** Topic T01 không có bản tin của T68; mỗi bản tin có `dhtenant` đúng; truy cập đối tượng trực tiếp bị từ chối (bucket, chính sách riêng).
:::

### TS-01-31 · Phân quyền và tách nhiệm

**Mục tiêu.** Chứng minh ma trận quyền D02-08 được thực thi ở máy chủ, bốn mắt độc lập với vai trò, và thao tác nhạy cảm đòi hỏi MFA mới.

**Phủ.** FR-01-016, 018, 024, 031; BR-01-009, 017; API-01-024, 032, 044, 053, 059; ERR-01-017, 035, 052, 006.

#### TC-01-121 · Ma trận vai trò × quyền <!--k:perm-matrix-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-001, 003, 012, 018, 025, 029 · API-01-001, 004, 023, 032, 045, 051 · ERR-01-052.

**Tiền điều kiện, dữ liệu.** Người dùng đủ mười ba vai trò theo ma trận §3.2 của FRS (PA, PO, TA, TO, SO, IE, IA, SV, CA, OR, DO, VW, AU).

**Các bước.**

1. Tham số hóa: mỗi vai trò gọi một API đại diện cho từng quyền `PERM-01-read`, `create`, `submit`, `approve`, `credential`, `suspend` và hai quyền `PERM-18-config`, `PERM-18-migration`.

**Kết quả mong đợi.** Chỉ cặp ● (hoặc ○ đúng đối tượng) trong ma trận được `2xx`; mọi cặp còn lại `403-PQ`, không có ngoại lệ nào ở giao diện mà API cho qua.
:::

#### TC-01-122 · Bốn mắt tại bốn điểm <!--k:four-eyes-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** BR-01-017 · FR-01-018, 024, 031 · API-01-032, 044, 053, 059 · ERR-01-017.

**Tiền điều kiện, dữ liệu.** U-T68-X1 (TA + IE, cấu hình sai có chủ đích).

**Các bước.**

1. X1 lập hồ sơ rồi thẩm định kỹ thuật của chính hồ sơ.
2. X1 thẩm định rồi phê duyệt cùng hồ sơ.
3. X1 nộp hồ sơ rồi kích hoạt PRODUCTION.
4. X1 đề nghị chấm dứt rồi duyệt.

**Kết quả mong đợi.** Mọi bước vi phạm `403` ERR-01-017, bất kể X1 có đủ quyền theo vai trò.
:::

#### TC-01-123 · Xác thực lại hai yếu tố cho mọi thao tác nhạy cảm <!--k:mfa-stepup-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API, E2E.

**Truy vết.** NFR-01-012 · BR-01-009 · API-01-032, 040, 044, 045, 047, 051, 054 · ERR-01-035.

**Tiền điều kiện, dữ liệu.** TA1, SO, TECH; `mfa.stepUpMinutes = 5`.

**Các bước.**

1. Với từng thao tác (phê duyệt, kích hoạt, tạm ngừng, thu hồi, xoay vòng, mở bàn giao, thao tác khẩn): gọi khi phiên chưa có MFA mới.
2. Xác thực MFA; gọi lại trong 5 phút; tua 6 phút; gọi lần nữa.

**Kết quả mong đợi.** `403` ERR-01-035 ở bước 1 và sau 6 phút; thành công trong 5 phút. Thao tác thất bại không thay đổi dữ liệu.
:::

#### TC-01-124 · Token dịch vụ đúng scope, OR đúng tổ chức <!--k:service-or-scope-->

::: dac-ta
**Loại.** Âm, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** FR-01-003, 037, 038 · API-01-004, 062, 063, 087 · ERR-01-006, 052 · BR-01-030.

**Tiền điều kiện, dữ liệu.** S-INT, S-RECON, S-CB; U-T68-OR1; Văn phòng UBND.

**Các bước.**

1. Mỗi token dịch vụ gọi API của scope khác; gọi API người dùng.
2. OR1 tạo hồ sơ của Văn phòng UBND; sửa `HT-DVC`.

**Kết quả mong đợi.** Bước 1: `403-PQ`. Bước 2: `403` ERR-01-006 và `404-ẩn`.
:::

### TS-01-32 · Hiệu năng, tải và quy mô

**Mục tiêu.** Chứng minh NFR-01-001, 003, 004, 008, 017, 021 ở cấu hình QM-VUA với dữ liệu giả định GĐ-07.

**Phủ.** NFR-01-001, 003, 004, 008, 017, 021.

| Mã | Tên | Tải | Ngưỡng | Truy vết |
|---|---|---|---|---|
| TC-01-125 | Độ trễ API điều khiển <!--k:perf-api--> | 1.000 HTTT, 5.000 định danh; 50 người dùng đồng thời, 30 phút | Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms | NFR-01-001 · FR-01-001, 002 |
| TC-01-126 | Tải danh sách HTTT <!--k:perf-list--> | 500 HTTT, trang 50 dòng kèm facets, 20 luồng | p99 ≤ 1 giây | NFR-01-003 · FR-01-001 |
| TC-01-127 | Cấp định danh SANDBOX sau phê duyệt <!--k:perf-provision--> | 100 phê duyệt liên tiếp, PH-12, PH-03, OpenBao khỏe | p95 ≤ 5 phút từ phê duyệt tới có bàn giao hoặc chờ khóa | NFR-01-004 · FR-01-020 |
| TC-01-128 | Hiệu lực cắt quyền <!--k:perf-cutoff--> | Ba bản sao APISIX, 100 lượt gọi/giây; 20 lệnh tạm ngừng, thu hồi, khẩn | Cổng từ chối ≤ 60 giây; ACL Kafka ≤ 2 phút | NFR-01-008 · FR-01-029, 032 |
| TC-01-129 | Độ trễ sự kiện trạng thái <!--k:perf-event--> | 100 chuyển trạng thái/giây, 10 phút | p95 ≤ 5 giây từ commit tới Kafka, không mất | NFR-01-021 · FR-01-037 |
| TC-01-130 | Quy mô tối đa của tenant <!--k:perf-scale--> | 1.000 HTTT, 5.000 định danh, 20.000 đầu mối, 50.000 mục trần phạm vi | Các chỉ tiêu độ trễ ở trên vẫn đạt | NFR-01-017 · FR-01-001, 045 |

: TS-01-32 · Hiệu năng, tải và quy mô

### TS-01-33 · Chịu lỗi, cách ly sự cố, kiểm toán, cảnh báo, lưu giữ

**Mục tiêu.** Chứng minh PH-01 ngừng thì HTTT đã kết nạp vẫn chạy, phục hồi không mất việc, mọi quyết định có kiểm toán, và cảnh báo vận hành phát đúng.

**Phủ.** NFR-01-006, 007, 013, 015, 016, 020, 022; FR-01-020, 037; ERR-01-046.

#### TC-01-131 · Dừng dh-connect: HTTT đã kết nạp vẫn gọi API <!--k:isolate-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P1.

**Tự động.** Chaos.

**Truy vết.** NFR-01-007 · FR-01-037 · ERR-01-046.

**Tiền điều kiện, dữ liệu.** `HT-QLVB` ACTIVE đang gọi API qua APISIX; token còn hạn 5 phút làm mới qua PH-12.

**Các bước.**

1. Dừng toàn bộ `dh-connect` 30 phút (rút gọn từ 24 giờ, kiểm cấu hình đã nạp ở APISIX).
2. Gọi API trong khi dừng; thử nộp hồ sơ, đổi cấu hình.
3. Khởi động lại.

**Kết quả mong đợi.** Bước 2: HTTT `ACTIVE` gọi API bình thường; nộp hồ sơ và đổi cấu hình bị chặn `503`. Bước 3: tự phục hồi, không mất dữ liệu.
:::

#### TC-01-132 · Khởi động lại giữa saga và outbox, phục hồi sao lưu <!--k:recovery-->

::: dac-ta
**Loại.** Chịu lỗi.

**Ưu tiên.** P2.

**Tự động.** Chaos.

**Truy vết.** NFR-01-006 · FR-01-020, 037 · EVT-01-03, 05.

**Tiền điều kiện, dữ liệu.** Một saga đang chạy; Kafka, Debezium thật.

**Các bước.**

1. Xóa pod `dh-connect` giữa chừng saga năm lần.
2. Phục hồi sao lưu ở môi trường DR; so với nguồn.

**Kết quả mong đợi.** Saga tiếp tục đúng bước, không tạo client hai lần, không mất hay trùng sự kiện; RPO ≤ 1 giờ, RTO ≤ 4 giờ.
:::

#### TC-01-133 · Kiểm toán mọi quyết định, truy được sau một năm <!--k:audit-all-->

::: dac-ta
**Loại.** Dương, Bảo mật.

**Ưu tiên.** P1.

**Tự động.** IT.

**Truy vết.** NFR-01-013 · FR-01-012, 013, 014, 018, 024, 026, 029, 031, 032, 042.

**Tiền điều kiện, dữ liệu.** Chạy trọn vòng đời một HTTT; bộ thu PH-13 giả lập; dữ liệu cũ một năm.

**Các bước.**

1. Đối chiếu bản ghi kiểm toán với danh sách thao tác.
2. Tra quyết định từ một năm trước.

**Kết quả mong đợi.** Mỗi quyết định có một bản ghi đủ trường FR-00-041 (người, vai trò, thời điểm, đối tượng, lý do, kết quả), không có bí mật; truy được quyết định cũ.
:::

#### TC-01-134 · Cảnh báo vận hành và lưu giữ <!--k:alerts-retention-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** NFR-01-016, 022 · FR-01-016, 023, 027, 020, 032 · EVT-01-15.

**Tiền điều kiện, dữ liệu.** Đồng hồ giả; các tình huống: hồ sơ quá hạn, SANDBOX quá 30 ngày, định danh còn 7 ngày, saga lỗi, cắt quyền chưa hoàn tất, HTTT ACTIVE chưa rà soát trong 6 tháng.

**Các bước.**

1. Tạo từng tình huống; đọc cảnh báo ở PH-13.
2. Chạy tác vụ dọn; kiểm dữ liệu quá hạn lưu giữ.

**Kết quả mong đợi.** Mỗi tình huống đúng một cảnh báo; tác vụ dọn xóa bàn giao quá 3 năm, kiểm thử SANDBOX quá 1 năm, giữ kỳ rà soát 5 năm; hồ sơ và HTTT đã chấm dứt giữ vĩnh viễn.
:::

#### TC-01-142 · Chỉ số quan sát của phân hệ <!--k:metrics-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P2.

**Tự động.** IT.

**Truy vết.** NFR-01-015 · FR-01-019, 040 · UI-01-17.

**Tiền điều kiện, dữ liệu.** Prometheus thử thu từ `dh-connect`; dữ liệu một chu kỳ kết nạp đầy đủ.

**Các bước.**

1. Chạy chu kỳ: tạo, nộp, duyệt, kích hoạt, thu hồi một định danh, mở kỳ rà soát.
2. Đọc các chỉ số `onboarding_applications_total{status}`, `onboarding_stage_duration_days{stage}`, `onboarding_members_total{status,group}`, `onboarding_credential_expiring_total`, `onboarding_scope_unused_total`.

**Kết quả mong đợi.** Mỗi chỉ số có mặt, nhãn đúng, giá trị khớp số liệu ở UI-01-17 và API-01-086; không có nhãn chứa dữ liệu cá nhân hay mã bí mật.
:::

#### TC-01-143 · Thời gian kết nạp đầu cuối <!--k:e2e-duration-->

::: dac-ta
**Loại.** Hiệu năng, Khả dụng.

**Ưu tiên.** P2.

**Tự động.** Thủ công.

**Truy vết.** NFR-01-020 · FR-01-012, 018, 024 · UC-01-06, 12, 17.

**Tiền điều kiện, dữ liệu.** Một hồ sơ thí điểm không bị trả bổ sung (mục 6.2); đồng hồ làm việc thật.

**Các bước.**

1. Ghi thời điểm nộp, từng kết luận thẩm định, phê duyệt, bàn giao, kiểm thử đạt, kích hoạt.

**Kết quả mong đợi.** Từ nộp đến gọi được API môi trường thật ≤ 5 ngày làm việc, phần của PH-01 ≤ 3 ngày làm việc (KPI-05); chênh lệch so với hạn 2 ngày mỗi bước ghi vào báo cáo.
:::

### TS-01-34 · Truy cập và giao diện

**Mục tiêu.** Chứng minh 17 màn UI-01-01…17 đạt WCAG 2.2 AA, có đủ trạng thái chuẩn, đúng route, và các trang dùng liên kết một lần không làm rò bí mật.

**Phủ.** NFR-01-018, 014; UI-01-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17; FR-01-022, 041.

#### TC-01-135 · Quét truy cập mười bảy màn hình <!--k:a11y-all-->

::: dac-ta
**Loại.** Truy cập.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** NFR-01-018 · UI-01-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17.

**Tiền điều kiện, dữ liệu.** Mỗi màn ở trạng thái có dữ liệu; axe-core; công cụ đọc màn hình thủ công cho UI-01-01, 09.

**Các bước.**

1. Chạy quét axe trên từng màn; thao tác chỉ bằng bàn phím trọn luồng nộp hồ sơ và mở bàn giao.
2. Kiểm tương phản ở lớp kính và lớp nội dung (ADR-020).

**Kết quả mong đợi.** 0 lỗi mức nghiêm trọng; thứ tự tab đúng; thông báo lỗi gắn với trường; tương phản đạt AA.
:::

#### TC-01-136 · Trạng thái chuẩn và đường dẫn trực tiếp <!--k:ui-states-->

::: dac-ta
**Loại.** Dương, Âm.

**Ưu tiên.** P2.

**Tự động.** E2E.

**Truy vết.** UI-01-03, 04, 05, 12, 14 · FR-01-001, 002, 016 · ERR-01-001, 052.

**Tiền điều kiện, dữ liệu.** U-T68-VW; tenant không có dữ liệu `T90`.

**Các bước.**

1. Mở UI-01-03 ở T90 (trống), khi API chậm, khi API lỗi.
2. VW mở trực tiếp `/ket-noi/he-thong/tham-dinh` và `/ket-noi/ra-soat-quyen`; mở `/ket-noi/he-thong/khong-co`.

**Kết quả mong đợi.** Trạng thái trống, đang tải, lỗi (kèm `traceId`) theo D03-06-00; VW không thấy menu thẩm định; truy cập trực tiếp hiện trang `403` hoặc `404` (PTN-13).
:::

#### TC-01-137 · Trang bàn giao và phiếu xác nhận không làm rò bí mật <!--k:ui-handover-page-->

::: dac-ta
**Loại.** Bảo mật.

**Ưu tiên.** P1.

**Tự động.** E2E, ZAP.

**Truy vết.** UI-01-09, 13 · FR-01-022, 041 · BR-01-006 · NFR-01-009.

**Tiền điều kiện, dữ liệu.** Liên kết bàn giao và phiếu xác nhận `PENDING`.

**Các bước.**

1. Mở UI-01-09; xem tiêu đề phản hồi (`Cache-Control`, `Referrer-Policy`, ghi theo SDD), lịch sử trình duyệt, URL.
2. Nhấn "Sao chép"; tải lại trang; dùng nút Quay lại.

**Kết quả mong đợi.** `no-store`, và chính sách tham chiếu không gửi đường dẫn đi nơi khác; bí mật không ở URL, lịch sử, bộ nhớ đệm; tải lại hoặc quay lại không hiện lại bí mật (`410`). Phiếu UI-01-13 tương tự.
:::

#### TC-01-138 · Trình hướng dẫn năm bước dễ dùng <!--k:wizard-usability-->

::: dac-ta
**Loại.** Khả dụng.

**Ưu tiên.** P3.

**Tự động.** Thủ công.

**Truy vết.** NFR-01-014 · UI-01-01 · UC-01-02.

**Tiền điều kiện, dữ liệu.** Năm cán bộ đầu mối chưa từng dùng; tài liệu hướng dẫn mục 6.

**Các bước.**

1. Mỗi cán bộ hoàn thành hồ sơ mẫu `HT-HOTICH` từ đầu tới bước nộp, không có người hướng dẫn.

**Kết quả mong đợi.** Trung bình ≤ 30 phút; mọi thông báo lỗi nêu cách khắc phục; quay lại bước trước không mất dữ liệu.
:::

### TS-01-35 · Hợp đồng API, máy trạng thái, nhận lặp và đồng thời

**Mục tiêu.** Chứng minh API đúng hợp đồng OpenAPI và RFC 9457, chuyển trạng thái cấm bị chặn, nhận lặp an toàn và không có đua quyết định.

**Phủ.** NFR-01-019; API-01-001, 088; ERR-01-005, 007, 020, 030, 051, 052, 054; BR-01-031.

#### TC-01-139 · Kiểm tra hợp đồng 88 operation <!--k:contract-->

::: dac-ta
**Loại.** Dương.

**Ưu tiên.** P1.

**Tự động.** API.

**Truy vết.** NFR-01-019 · API-01-001, 002, 087, 088 · ERR-01-052.

**Tiền điều kiện, dữ liệu.** OpenAPI `/api/onboarding/v1`; Apicurio chế độ BACKWARD.

**Các bước.**

1. Chạy Schemathesis trên toàn bộ operation; so OpenAPI với bản phát hành trước; kiểm lược đồ sự kiện.

**Kết quả mong đợi.** Mọi phản hồi khớp lược đồ; lỗi theo RFC 9457 có `type`, `title`, `status`, `traceId`; chỉ thêm trường tùy chọn; sự kiện tương thích BACKWARD (CI-5).
:::

#### TC-01-140 · Ma trận chuyển trạng thái cấm <!--k:illegal-transitions-->

::: dac-ta
**Loại.** Âm.

**Ưu tiên.** P1.

**Tự động.** API, UT.

**Truy vết.** BR-01-031 · FR-01-009, 012, 018, 024, 029, 030, 031 · ERR-01-005, 020, 030.

**Tiền điều kiện, dữ liệu.** Một HTTT ở mỗi trạng thái DRAFT, SUBMITTED, APPROVED, ACTIVE, SUSPENDED, TERMINATED, REJECTED; đủ quyền.

**Các bước.**

1. Từ mỗi trạng thái, gọi mọi hành động (`:submit`, `:withdraw`, `:approve`, `:reject`, `:activate`, `:suspend`, `:resume`, `:terminate`, xóa) không nằm ở bảng chuyển hợp lệ (mục 3.2).

**Kết quả mong đợi.** `409` ERR-01-005 (hoặc ERR-01-020, ERR-01-030 với bước, định danh); trạng thái không đổi, không sự kiện, không kiểm toán nghiệp vụ.
:::

#### TC-01-141 · Nhận lặp, không xác thực, đua quyết định <!--k:idem-race-->

::: dac-ta
**Loại.** Âm, Biên.

**Ưu tiên.** P2.

**Tự động.** API, IT.

**Truy vết.** BR-01-031 · API-01-023, 032, 044 · ERR-01-007, 051, 052, 054 · EVT-01-03.

**Tiền điều kiện, dữ liệu.** `HT-HOTICH-OK`; `HT-HOTICH-SB`; TA1, TA2.

**Các bước.**

1. Gọi các API có `Idempotency-Key` (mọi API ghi có đánh dấu "có" ở bảng API) hai lần cùng khóa cùng thân; một lần khác thân; hai lần song song.
2. Gọi không token, token hết hạn.
3. TA1 và TA2 đồng thời `:approve` cùng HTTT; hai lần `:activate` đồng thời.

**Kết quả mong đợi.** Cùng thân: cùng kết quả; khác thân `409` ERR-01-051; song song `409` ERR-01-054. Bước 2: `401` ERR-01-052. Bước 3: đúng một thành công, còn lại `409` ERR-01-005 hoặc `412` ERR-01-007; đúng một `EVT-01-03`.
:::

## 6. Thủ tục kiểm thử thủ công

Phần thủ công bổ sung cho ca tự động ở những chỗ cần phán đoán của người: tính dễ hiểu của biểu mẫu, diễn tập sự cố, và đo thời gian kết nạp trên một hồ sơ thật.

### 6.1. Kiểm thử khám phá theo phiên

Mỗi phiên 90 phút, hai người, theo điều lệ: (1) "Làm sai hồ sơ": cố ý khai sai, thiếu, trùng ở UI-01-01 và xem thông báo có hướng dẫn khắc phục; (2) "Đi vòng quy trình": thử bấm nút ngoài thứ tự (nộp rồi sửa, duyệt khi đang tham vấn); (3) "Nhìn như người duyệt": đọc UI-01-06, 07 xem có đủ thông tin để quyết định mà không phải mở nơi khác. Kết quả ghi thành lỗi hoặc ca mới (mã mới bổ sung ở bản sau).

### 6.2. Diễn tập kết nạp một HTTT thí điểm đầu cuối

Cùng cán bộ của một tỉnh thí điểm, kết nạp một HTTT thật từ nộp hồ sơ đến gọi được API ở môi trường thật; ghi thời gian từng bước để đối chiếu KPI-05 (≤ 5 ngày làm việc, trong đó phần PH-01 ≤ 3 ngày làm việc, NFR-01-020). Số liệu thật thay giả định hạn thẩm định 2 ngày mỗi bước.

### 6.3. Diễn tập sự cố lộ bí mật

Cán bộ ATTT đóng vai phát hiện một chuỗi bí mật bị lộ: dùng thao tác khẩn (TS-01-22), thu hồi, xoay vòng, bàn giao lại, khôi phục theo BR-01-010. Đo thời gian từ lệnh đến khi cổng từ chối (≤ 60 giây), kiểm tra bằng chứng kiểm toán đủ cho báo cáo sự cố.

### 6.4. Kiểm thử truy cập thủ công

Một người dùng đọc màn hình (NVDA) thực hiện nộp hồ sơ ở UI-01-01 và mở bàn giao ở UI-01-09; một người chỉ dùng bàn phím thực hiện thẩm định ở UI-01-06. Ghi các điểm vướng vào lỗi mức Trung bình trở lên.

## 7. Nghiệm thu người dùng tương đương hệ cũ

Cán bộ vận hành hệ cũ (quản trị APIM, quản trị Hub) tự thực hiện trên UAT với dữ liệu nhập từ hệ cũ. Đạt khi làm được không cần hướng dẫn ngoài tài liệu người dùng, kết quả bằng hoặc tốt hơn hệ cũ. Bảng dưới nối từng việc với chức năng hệ cũ (D00-03 phần A), FR mới và kịch bản tự động tương ứng.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Xem danh sách HTTT, lọc theo trạng thái, nhóm, tổ chức | LGC-APIM-019 | Thấy đủ Application cũ dưới dạng HTTT, tìm một HTTT trong 3 thao tác | FR-01-001, 050 | TS-01-01 |
| UAT-02 | Xem chi tiết một HTTT, định danh, người liên hệ | LGC-APIM-019 | Thấy định danh và hạn dùng, không thấy bí mật; đầu mối kỹ thuật rõ | FR-01-002, 028 | TS-01-01, 19 |
| UAT-03 | Tạo hồ sơ cho một ứng dụng mới thay "Tạo Application" | LGC-APIM-020 | Hoàn thành hồ sơ trong 30 phút, biết thiếu gì trước khi nộp | FR-01-003, 004, 011, 012 | TS-01-02, 06 |
| UAT-04 | Khai một HTTT là bên phát dữ liệu (publisher) | LGC-HUB-010 | Có vai trò `PUBLISHER` và nhu cầu cung cấp; PH-10 chỉ nhận khi HTTT hoạt động | FR-01-003, 037, 038 | TS-01-02, 24 |
| UAT-05 | Khai một HTTT là bên nhận (subscriber) | LGC-HUB-011 | Có vai trò `SUBSCRIBER`; luồng nhận khai ở PH-04, PH-10 | FR-01-003, 037, 038 | TS-01-02, 24 |
| UAT-06 | Nhận Client ID và bí mật cho ứng dụng | LGC-APIM-020 | Nhận qua liên kết một lần trong vài phút, không phải chờ công văn | FR-01-020, 021, 022 | TS-01-13, 14, 15 |
| UAT-07 | Kiểm thử ở môi trường thử rồi chuyển sang môi trường thật | LGC-APIM-020 | Thấy kết quả kiểm thử từng lượt; TA kích hoạt trong ngày | FR-01-023, 024 | TS-01-16, 17 |
| UAT-08 | Chặn ngay một ứng dụng đang gây sự cố | LGC-APIM-019 | HTTT bị chặn ở cổng trong 60 giây, có lý do và thời điểm | FR-01-029, 032, 033 | TS-01-20, 22 |
| UAT-09 | Nhập các Application, publisher, subscriber của hệ cũ | LGC-APIM-019; LGC-APIM-020; LGC-HUB-010, LGC-HUB-011 | Có đề xuất hồ sơ nháp từ tệp cũ; chỉ phải cấp lại định danh | FR-01-048 | TS-01-28 |
| UAT-10 | Rà soát quyền định kỳ và xử lý phản hồi của đơn vị | LGC-APIM-019 | Mở kỳ, thấy mức dùng thật, quyết định thu hẹp có lý do; hệ cũ không có việc này | FR-01-039, 040, 041, 042 | TS-01-25, 26 |
| UAT-11 | Tra danh bạ đầu mối của một tổ chức | LGC-HUB-010, LGC-HUB-011 | Tìm được đầu mối kỹ thuật trong 3 thao tác, không thấy đầu mối an ninh | FR-01-045 | TS-01-27 |

: Nghiệm thu người dùng tương đương hệ cũ

## 8. Ma trận truy vết

Chương này sinh tự động từ các ca ở chương 4 và 5, theo bốn chiều: FR sang ca dương và âm; chức năng hệ cũ `LGC` sang FR, ca và UAT; quy tắc BR, lỗi ERR, yêu cầu NFR; và UC, API, UI, sự kiện EVT. Mục tiêu là cho hội đồng thấy không có yêu cầu nào thiếu ca và không có chức năng hệ cũ nào bị bỏ sót.

<!--gen:matrix-->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-01. FR mức M phải có ít nhất một ca ở mỗi cột; bảng này được sinh tự động bằng `ph01/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-01-001 | Liệt kê, tìm kiếm, lọc HTTT thành viên | M | LGC-APIM-019 | 001, 136 | 002, 121, 136 | 006, 125, 126, 130 | Có |
| FR-01-002 | Xem chi tiết HTTT thành viên | M | LGC-APIM-019, LGC-HUB-010, LGC-HUB-011 | 003, 136 | 002, 004, 136 | 117, 125 | Có |
| FR-01-003 | Tạo hồ sơ kết nạp nháp | M | LGC-APIM-020, LGC-HUB-010, LGC-HUB-011 | 007 | 008, 009, 012, 121, 124 | 010 | Có |
| FR-01-004 | Sửa hồ sơ nháp, tự lưu | M | LGC-APIM-020 | 013 | 011 | 010 | Có |
| FR-01-005 | Đính kèm, xem, xóa tài liệu hồ sơ | M | mới | 017, 021 | 020 | 120 | Có |
| FR-01-006 | Khai hồ sơ năng lực kỹ thuật và đề xuất nhóm HTTT | M | mới | 014, 016 | 015, 016 | — | Có |
| FR-01-007 | Khai nhu cầu khai thác kèm căn cứ pháp lý | M | mới | 017 | 018, 019, 022 | — | Có |
| FR-01-008 | Quản lý đầu mối liên hệ của HTTT | M | mới | 023, 026 | 024, 025 | — | Có |
| FR-01-009 | Xóa hồ sơ nháp và rút hồ sơ đã nộp | S | mới | 034, 036 | 035, 036, 140 | 037 | Có |
| FR-01-010 | Cung cấp mẫu văn bản và hướng dẫn kết nạp | S | mới | 013 | — | — | Có |
| FR-01-011 | Kiểm tra hợp lệ hồ sơ trước khi nộp | M | mới | 028 | 019, 027 | 032 | Có |
| FR-01-012 | Nộp hồ sơ kết nạp | M | LGC-APIM-020 | 028, 047, 133 | 030, 031, 121, 140 | 029, 143 | Có |
| FR-01-013 | Thẩm định kỹ thuật và xác nhận nhóm HTTT | M | mới | 041, 133 | 041 | — | Có |
| FR-01-014 | Thẩm định căn cứ pháp lý và ATTT theo từng mục | M | mới | 044, 046, 133 | 045, 046 | — | Có |
| FR-01-015 | Đánh giá tác động tới hạn mức dữ liệu quốc gia | S | mới | 042 | 043 | — | Có |
| FR-01-016 | Phân công, theo dõi hạn thẩm định, tham vấn | M | mới | 038, 039, 134, 136 | 038, 136 | 040 | Có |
| FR-01-017 | Trả bổ sung và nộp lại hồ sơ | M | mới | 047 | 048 | — | Có |
| FR-01-018 | Phê duyệt hoặc từ chối kết nạp | M | mới | 049, 051, 133 | 050, 121, 122, 140 | 143 | Có |
| FR-01-019 | Theo dõi tiến độ hồ sơ | S | mới | 033, 142 | — | — | Có |
| FR-01-020 | Cấp định danh SANDBOX sau phê duyệt (saga) | M | LGC-APIM-020 | 052, 134 | 053, 054 | 113, 116, 127, 132 | Có |
| FR-01-021 | Đăng ký khóa công khai hoặc yêu cầu ký chứng thư | M | mới | 055 | 056 | 116 | Có |
| FR-01-022 | Bàn giao thông tin xác thực một lần | M | mới | 057, 058, 062 | 059, 060, 061, 062, 063 | 113, 137 | Có |
| FR-01-023 | Kiểm thử kết nối ở SANDBOX | M | mới | 064, 134 | 065 | 066 | Có |
| FR-01-024 | Kích hoạt môi trường thật (PRODUCTION) | M | mới | 067, 133 | 068, 122, 140 | 069, 143 | Có |
| FR-01-025 | Xoay vòng thông tin xác thực | M | mới | 070 | 071, 121 | 072, 113 | Có |
| FR-01-026 | Thu hồi định danh ứng dụng | M | mới | 074, 133 | 074 | 113 | Có |
| FR-01-027 | Nhắc hạn và tự hết hạn định danh | M | mới | 134 | 075 | — | Có |
| FR-01-028 | Xem danh sách định danh của HTTT | M | LGC-APIM-019 | 073 | 073 | — | Có |
| FR-01-029 | Tạm ngừng HTTT | M | mới | 078, 133 | 079, 082, 121, 140 | 128 | Có |
| FR-01-030 | Khôi phục HTTT | M | mới | 080 | 081, 140 | — | Có |
| FR-01-031 | Chấm dứt tư cách thành viên | M | mới | 083, 133 | 084, 122, 140 | 085 | Có |
| FR-01-032 | Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT | M | mới | 086, 133, 134, 144, 146, 149 | 087, 145 | 088, 128 | Có |
| FR-01-033 | Phân tích tác động phụ thuộc trước khi tạm ngừng, chấm dứt | M | mới | 077 | 077 | — | Có |
| FR-01-034 | Đề nghị thay đổi hồ sơ HTTT đã kết nạp theo mức duyệt | S | mới | 089, 150 | 090, 151 | — | Có |
| FR-01-035 | Đề nghị mở rộng trần phạm vi khai thác | M | mới | 091 | 092 | — | Có |
| FR-01-036 | Tự tạm ngừng định danh không hoạt động | S | mới | 076 | 076 | — | Có |
| FR-01-037 | Đồng bộ trạng thái HTTT tới phân hệ khác | M | mới | 093, 094 | 094, 124 | 129, 131, 132 | Có |
| FR-01-038 | Cung cấp bản sao đọc HTTT cho phân hệ khác | M | LGC-HUB-010, LGC-HUB-011 | 095 | 095, 124 | — | Có |
| FR-01-053 | Tiếp nhận đề xuất tạm ngừng HTTT từ PH-13, tạo việc khẩn cho | M | mới | 146, 149 | 148 | 147 | Có |
| FR-01-054 | Tạo sẵn đề nghị đổi chủ quản HTTT khi tổ chức giải thể, sáp  | S | mới | 150 | 151 | — | Có |
| FR-01-039 | Mở kỳ rà soát quyền định kỳ | M | mới | 096 | 097 | — | Có |
| FR-01-040 | Tổng hợp mức sử dụng từng phạm vi | M | mới | 096, 142 | 097 | — | Có |
| FR-01-041 | Gửi xác nhận cho đơn vị chủ quản và theo dõi phản hồi | M | mới | 099 | 100 | 101, 137 | Có |
| FR-01-042 | Xử lý kết quả rà soát: thu hẹp, thu hồi phạm vi | M | mới | 102, 133 | 102 | 101 | Có |
| FR-01-043 | Kiểm tra hiệu lực căn cứ pháp lý | M | mới | 098 | 098 | — | Có |
| FR-01-044 | Báo cáo rà soát quyền | S | mới | 103 | 103 | — | Có |
| FR-01-045 | Tra cứu danh bạ đầu mối trong phạm vi cơ quan nhà nước | M | mới | 104 | 105 | 130 | Có |
| FR-01-046 | Cảnh báo tổ chức thiếu đầu mối và nhắc cập nhật | M | mới | 106 | 106 | — | Có |
| FR-01-047 | Xuất danh bạ đầu mối | C | mới | 107 | 107 | — | Có |
| FR-01-048 | Nhập HTTT từ hệ cũ | M | LGC-APIM-019, LGC-HUB-010, LGC-HUB-011 | 108 | 109 | 110 | Có |
| FR-01-049 | Tham số phân hệ theo tenant | M | mới | 111 | 111 | — | Có |
| FR-01-050 | Xuất danh sách HTTT thành viên | S | LGC-APIM-019 | 005 | 005 | 115 | Có |
| FR-01-051 | Thống kê kết nạp và thời gian xử lý | S | mới | 112 | 112 | — | Có |

: Ma trận yêu cầu chức năng với test case của PH-01

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Bốn chức năng hệ cũ do PH-01 chịu trách nhiệm (Application của APIM `LGC-APIM`, publisher và subscriber của Hub `LGC-HUB`) được truy tới FR mới, ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-APIM-019 | 001, 002, 028, 048, 050 | 001, 003, 005, 073, 108, 136 | UAT-01, UAT-02, UAT-08, UAT-09, UAT-10 |
| LGC-APIM-020 | 003, 004, 012, 020 | 007, 013, 028, 047, 052, 133, 134 | UAT-03, UAT-06, UAT-07, UAT-09 |
| LGC-HUB-010 | 002, 003, 038, 048 | 003, 007, 095, 108, 136 | UAT-04, UAT-09, UAT-11 |
| LGC-HUB-011 | 002, 003, 038, 048 | 003, 007, 095, 108, 136 | UAT-05, UAT-09, UAT-11 |

: Truy vết chức năng hệ cũ tới yêu cầu và test case

### 8.3. Quy tắc nghiệp vụ → test case

Bảng dưới liệt kê từng quy tắc nghiệp vụ của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| BR-01-001 | 017, 018, 021, 027, 092 |
| BR-01-002 | 044 |
| BR-01-003 | 044, 049, 052, 065, 067, 069, 091, 102 |
| BR-01-004 | 019, 045, 092 |
| BR-01-005 | 057, 060 |
| BR-01-006 | 058, 059, 062, 063, 137 |
| BR-01-007 | 052, 055, 057, 058, 073, 110, 113, 116 |
| BR-01-008 | 064, 067, 068 |
| BR-01-009 | 050, 070, 071, 074, 078, 080, 102, 111 (+3) |
| BR-01-010 | 081, 086, 088, 144, 145, 146, 147, 149 |
| BR-01-011 | 034, 036, 051, 083 |
| BR-01-012 | 090, 091 |
| BR-01-013 | 025, 027, 068, 106 |
| BR-01-014 | 096, 097, 099, 101, 111 |
| BR-01-015 | 081, 098 |
| BR-01-016 | 042 |
| BR-01-017 | 028, 038, 041, 045, 049, 050, 067, 068 (+4) |
| BR-01-018 | 007, 008, 036, 051, 083, 108 |
| BR-01-019 | 041, 046, 055, 056 |
| BR-01-020 | 075, 111 |
| BR-01-021 | 070, 072 |
| BR-01-022 | 076 |
| BR-01-023 | 074, 077, 078, 083, 086 |
| BR-01-024 | 037 |
| BR-01-025 | 023, 026, 089 |
| BR-01-026 | 022, 027, 041, 046, 068, 092 |
| BR-01-027 | 026, 104, 105 |
| BR-01-028 | 024, 027, 106 |
| BR-01-029 | 089, 150, 151 |
| BR-01-030 | 002, 004, 033, 095, 117, 118, 119, 120 (+1) |
| BR-01-031 | 007, 028, 049, 052, 093, 140, 141 |
| BR-01-032 | 030, 039, 047 |
| BR-01-033 | 108, 110 |
| BR-01-034 | 065 |

: Ma trận quy tắc nghiệp vụ với test case của PH-01

### 8.4. Mã lỗi → test case

Bảng dưới liệt kê từng mã lỗi của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| ERR-01-001 | 004, 021, 073, 079, 095, 104, 118, 119 (+2) |
| ERR-01-002 | 008, 036 |
| ERR-01-003 | 006, 008, 015, 018, 024, 062, 095, 098 (+2) |
| ERR-01-004 | 009 |
| ERR-01-005 | 011, 016, 021, 030, 035, 036, 079, 140 (+2) |
| ERR-01-006 | 009, 124 |
| ERR-01-007 | 011, 030, 141 |
| ERR-01-008 | 027 |
| ERR-01-009 | 030 |
| ERR-01-010 | 027, 106 |
| ERR-01-011 | 024 |
| ERR-01-012 | 020 |
| ERR-01-013 | 020 |
| ERR-01-014 | 020 |
| ERR-01-015 | 018, 027, 092 |
| ERR-01-016 | 019, 045, 092 |
| ERR-01-017 | 038, 041, 045, 050, 068, 084, 122 |
| ERR-01-018 | 045 |
| ERR-01-019 | 041, 045 |
| ERR-01-020 | 035, 038, 039, 041, 048, 050, 102, 103 (+1) |
| ERR-01-021 | 053, 056, 068, 071, 114 |
| ERR-01-022 | 053 |
| ERR-01-023 | 053, 056, 063, 071, 114 |
| ERR-01-024 | 059, 062 |
| ERR-01-025 | 060, 100 |
| ERR-01-026 | 061 |
| ERR-01-027 | 056 |
| ERR-01-028 | 056 |
| ERR-01-029 | 071 |
| ERR-01-030 | 056, 071, 074, 076, 140 |
| ERR-01-031 | 068 |
| ERR-01-032 | 068, 081 |
| ERR-01-033 | 035, 048, 050, 071, 074, 079, 084, 087 (+3) |
| ERR-01-034 | 074, 078, 084 |
| ERR-01-035 | 050, 061, 068, 071, 074, 079, 087, 102 (+2) |
| ERR-01-036 | 081, 087, 145 |
| ERR-01-037 | 090 |
| ERR-01-038 | 090, 092 |
| ERR-01-039 | 097 |
| ERR-01-040 | 100 |
| ERR-01-041 | 102 |
| ERR-01-042 | 109 |
| ERR-01-043 | 109 |
| ERR-01-044 | 097, 109, 111 |
| ERR-01-045 | 105, 107 |
| ERR-01-046 | 020, 031, 043, 066, 077, 097, 131 |
| ERR-01-047 | 027, 041, 046, 092 |
| ERR-01-048 | 062, 082, 148 |
| ERR-01-049 | 010, 090 |
| ERR-01-050 | 025, 106 |
| ERR-01-051 | 012, 030, 141 |
| ERR-01-052 | 005, 016, 054, 094, 095, 103, 107, 121 (+6) |
| ERR-01-053 | 054 |
| ERR-01-054 | 012, 141 |

: Ma trận mã lỗi với test case của PH-01

### 8.5. Yêu cầu phi chức năng → test case

Bảng dưới liệt kê từng yêu cầu phi chức năng của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| NFR-01-001 | 125 |
| NFR-01-002 | 032 |
| NFR-01-003 | 126 |
| NFR-01-004 | 052, 127 |
| NFR-01-005 | 020 |
| NFR-01-006 | 031, 132 |
| NFR-01-007 | 131 |
| NFR-01-008 | 074, 078, 086, 128 |
| NFR-01-009 | 058, 110, 113, 114, 115, 116, 137 |
| NFR-01-010 | 057, 061 |
| NFR-01-011 | 020, 120 |
| NFR-01-012 | 123 |
| NFR-01-013 | 133 |
| NFR-01-014 | 013, 138 |
| NFR-01-015 | 142 |
| NFR-01-016 | 040, 053, 066, 134 |
| NFR-01-017 | 130 |
| NFR-01-018 | 135 |
| NFR-01-019 | 139 |
| NFR-01-020 | 143 |
| NFR-01-021 | 093, 129 |
| NFR-01-022 | 134 |

: Ma trận yêu cầu phi chức năng với test case của PH-01

### 8.6. Use case → test case

Bảng dưới liệt kê từng use case của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| UC-01-01 | 001, 003, 005, 117 |
| UC-01-02 | 007, 009, 013, 138 |
| UC-01-03 | 014 |
| UC-01-04 | 017, 022 |
| UC-01-05 | 023 |
| UC-01-06 | 027, 028, 029, 143 |
| UC-01-07 | 033, 034 |
| UC-01-08 | 038, 039, 040 |
| UC-01-09 | 041, 042 |
| UC-01-10 | 044, 046 |
| UC-01-11 | 047 |
| UC-01-12 | 049, 143 |
| UC-01-13 | 052, 054 |
| UC-01-14 | 055 |
| UC-01-15 | 057, 058 |
| UC-01-16 | 064 |
| UC-01-17 | 067, 069, 143 |
| UC-01-18 | 070, 072 |
| UC-01-19 | 073, 074, 075 |
| UC-01-20 | 077, 078, 080 |
| UC-01-21 | 083, 085 |
| UC-01-22 | 086, 144, 146 |
| UC-01-23 | 089, 150 |
| UC-01-24 | 091 |
| UC-01-25 | 076 |
| UC-01-26 | 093, 095 |
| UC-01-27 | 096, 098 |
| UC-01-28 | 099, 101 |
| UC-01-29 | 102, 103 |
| UC-01-30 | 104, 107 |
| UC-01-31 | 106 |
| UC-01-32 | 108 |
| UC-01-33 | 111 |
| UC-01-34 | 112 |

: Ma trận use case với test case của PH-01

### 8.7. API → test case

Bảng dưới liệt kê từng api của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| API-01-001 | 001, 002, 006, 121, 139 |
| API-01-002 | 002, 003, 004, 139 |
| API-01-003 | 003, 004 |
| API-01-004 | 007, 008, 009, 010, 012, 121, 124 |
| API-01-005 | 010, 011, 013, 119 |
| API-01-006 | 021, 118 |
| API-01-007 | 017, 020 |
| API-01-008 | 021, 118 |
| API-01-009 | 021 |
| API-01-010 | 014, 015, 016 |
| API-01-011 | 014, 016 |
| API-01-012 | 017, 018, 019, 022 |
| API-01-013 | 017, 018, 022 |
| API-01-014 | 023, 026, 118 |
| API-01-015 | 023, 024 |
| API-01-016 | 023, 024, 026 |
| API-01-017 | 025 |
| API-01-018 | 036, 119 |
| API-01-019 | 034, 035 |
| API-01-020 | 013 |
| API-01-021 | 013 |
| API-01-022 | 027, 028, 032 |
| API-01-023 | 028, 029, 030, 031, 047, 119, 121, 141 |
| API-01-024 | 041 |
| API-01-025 | 044, 045, 046 |
| API-01-026 | 042, 043 |
| API-01-027 | 038 |
| API-01-028 | 038 |
| API-01-029 | 039 |
| API-01-030 | 039 |
| API-01-031 | 047, 048 |
| API-01-032 | 049, 050, 119, 121, 122, 123, 141 |
| API-01-033 | 050, 051 |
| API-01-034 | 033 |
| API-01-035 | 053, 114 |
| API-01-036 | 052, 053, 118 |
| API-01-037 | 055, 056 |
| API-01-038 | 055, 056 |
| API-01-039 | 057, 062, 082 |
| API-01-040 | 058, 059, 060, 061, 063, 113, 114, 123 |
| API-01-041 | 062 |
| API-01-042 | 064, 065 |
| API-01-043 | 064, 066, 118 |
| API-01-044 | 067, 068, 069, 122, 123, 141 |
| API-01-045 | 070, 071, 072, 113, 119, 121, 123 |
| API-01-046 | 070, 071 |
| API-01-047 | 074, 119, 123 |
| API-01-048 | 075 |
| API-01-049 | 073, 118 |
| API-01-050 | 073, 118 |
| API-01-051 | 078, 079, 119, 121, 123 |
| API-01-052 | 080, 081 |
| API-01-053 | 083, 084, 085, 122 |
| API-01-054 | 086, 087, 123, 144, 149 |
| API-01-055 | 086, 087, 144, 145 |
| API-01-056 | 077 |
| API-01-057 | 089, 090, 119 |
| API-01-058 | 089, 118, 150, 151 |
| API-01-059 | 083, 084, 085, 089, 091, 122, 150, 151 |
| API-01-060 | 091, 092 |
| API-01-061 | 076 |
| API-01-062 | 094, 124 |
| API-01-063 | 095, 124 |
| API-01-064 | 095 |
| API-01-065 | 096, 097 |
| API-01-066 | 096 |
| API-01-067 | 096, 118 |
| API-01-068 | 096, 097, 101 |
| API-01-069 | 099 |
| API-01-070 | 099, 100 |
| API-01-071 | 099, 100 |
| API-01-072 | 102 |
| API-01-073 | 098 |
| API-01-074 | 103, 118 |
| API-01-075 | 103, 115 |
| API-01-076 | 104, 105 |
| API-01-077 | 104 |
| API-01-078 | 106 |
| API-01-079 | 107, 115 |
| API-01-080 | 108, 109, 110 |
| API-01-081 | 108, 110 |
| API-01-082 | 108, 109 |
| API-01-083 | 111 |
| API-01-084 | 111 |
| API-01-085 | 005, 115 |
| API-01-086 | 112 |
| API-01-087 | 054, 124, 139 |
| API-01-088 | 005, 107, 115, 119, 139 |
| API-01-089 | 146, 147, 148, 149 |

: Ma trận api với test case của PH-01

### 8.8. Màn hình → test case

Bảng dưới liệt kê từng màn hình của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| UI-01-01 | 007, 011, 013, 014, 017, 018, 027, 028 (+2) |
| UI-01-02 | 033, 034, 047, 135 |
| UI-01-03 | 001, 005, 135, 136 |
| UI-01-04 | 003, 023, 026, 073, 076, 089, 091, 135 (+2) |
| UI-01-05 | 038, 135, 136 |
| UI-01-06 | 041, 042, 044, 047, 091, 135 |
| UI-01-07 | 049, 051, 089, 091, 135, 150 |
| UI-01-08 | 052, 055, 070, 073, 135 |
| UI-01-09 | 058, 070, 135, 137 |
| UI-01-10 | 064, 067, 135 |
| UI-01-11 | 074, 077, 078, 080, 083, 086, 135, 144 (+2) |
| UI-01-12 | 096, 098, 099, 102, 103, 135, 136 |
| UI-01-13 | 099, 135, 137 |
| UI-01-14 | 104, 106, 107, 135, 136 |
| UI-01-15 | 108, 135 |
| UI-01-16 | 111, 135 |
| UI-01-17 | 112, 135, 142 |

: Ma trận màn hình với test case của PH-01

### 8.9. Sự kiện → test case

Bảng dưới liệt kê từng sự kiện của PH-01 và các test case phủ nó (ba chữ số cuối của mã TC-01); mã nào chưa có ca sẽ làm script báo lỗi ở bước sinh.

| Mã | Test case |
|---|---|
| EVT-01-01 | 028 |
| EVT-01-02 | 040, 041, 044, 047, 049 |
| EVT-01-03 | 007, 028, 034, 037, 047, 049, 051, 067 (+10) |
| EVT-01-04 | 089, 093, 150 |
| EVT-01-05 | 052, 055, 067, 132 |
| EVT-01-06 | 055, 070, 072 |
| EVT-01-07 | 074, 075, 076, 078, 083, 086 |
| EVT-01-08 | 075 |
| EVT-01-09 | 058 |
| EVT-01-10 | 060, 061 |
| EVT-01-11 | 049, 083, 091, 098, 102 |
| EVT-01-12 | 102 |
| EVT-01-13 | 023 |
| EVT-01-14 | 106 |
| EVT-01-15 | 086, 088, 134 |

: Ma trận sự kiện với test case của PH-01
<!--/gen-->

## 9. Tự động hóa và tệp đi kèm

### 9.1. Tổ chức mã kiểm thử

Bảng dưới trình bày tổ chức mã kiểm thử.

| Thư mục | Nội dung |
|---|---|
| `apps/connect/src/test/java/vn/datahub/connect/onboarding/` | UT, IT; lớp cơ sở `OnboardingTestBase` (Testcontainers PostgreSQL 16, Kafka, OpenBao, Keycloak) |
| `apps/console/src/features/onboarding/**/*.test.ts` | UT giao diện |
| `e2e/onboarding/ts-01-nn.spec.ts` | Playwright |
| `perf/onboarding/*.js` | k6 |
| `datahub-docs/03-thiet-ke/csdl/ph01/test/` | Bài kiểm RLS, ràng buộc (pgTAP) |
| `datahub-docs/05-kiem-thu/test-case/ph01/gherkin/` | Gherkin sinh từ tài liệu này |
| `ph01/seed/` | Nạp dữ liệu mục 2 qua API |

: Tổ chức mã kiểm thử

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-01-nnn")`, `test('TC-01-nnn …')`) để báo cáo hằng đêm đối chiếu ma trận.

### 9.2. Mẫu ca dò mồi bí mật (JUnit)

Ca dò mồi chạy toàn luồng rồi quét các nơi có thể rò; bất kỳ lần xuất hiện nào của mồi ngoài phản hồi mở bàn giao làm ca hỏng.

```java
@Tag("TC-01-canary-flow")
@Test
void dhCanaryOnlyInHandoverResponse() {
    var canary = "DH-CANARY-flow-" + UUID.randomUUID();
    sim.pH12().nextClientSecret(canary);
    var sys = flows.approveAndProvision("TC-HOTICH-1");
    var opened = handover.open(sys.credentialId(), TECH_SESSION_WITH_MFA);
    assertThat(opened.secret()).isEqualTo(canary);
    var leaks = scanner.findAll(canary, Sink.API_LOGS, Sink.DB, Sink.OUTBOX, Sink.KAFKA, Sink.OTEL, Sink.MAIL);
    assertThat(leaks).isEmpty();
}
```

### 9.3. Mẫu ca bàn giao một lần (Playwright)

Ca mở liên kết hai lần bằng đúng người, kiểm lần hai trả `410` và không hiện lại bí mật.

```ts
test('TC-01-handover-twice · mở lần hai bị 410', async ({ page }) => {
  const link = await api.createHandover(credentialId, ta1);
  await loginWithMfa(page, tech); await page.goto(link);
  await expect(page.getByTestId('secret-once')).toBeVisible();
  await page.goto(link);
  await expect(page.getByRole('alert')).toContainText('đã được sử dụng hoặc hết hạn');
  await expect(page.getByTestId('secret-once')).toHaveCount(0);
});
```

### 9.4. Sinh ma trận, Gherkin, bảng tính

Bảng dưới trình bày sinh ma trận, Gherkin, bảng tính.

| Lệnh | Kết quả |
|---|---|
| `python3 ph01/tools/number_tcs.py` | Cấp số `TC-01-nnn` cho ca mới, thay `[[tc:khóa]]` |
| `python3 ph01/tools/fill_doc.py` | Ghi bảng kịch bản, số ca và chương 8 vào tài liệu; in ra stderr BR, ERR, NFR, UC, API, UI, EVT chưa có ca |
| `python3 ph01/tools/gen_gherkin.py` | `ph01/gherkin/ts-01-nn.feature` và `uat-tuong-duong-he-cu.feature` |
| `python3 ph01/tools/gen_xlsx.py` | `ph01/D05-02-PH01-test-case.xlsx` theo mẫu nghiệm thu |

: Sinh ma trận, Gherkin, bảng tính

Công cụ chép từ `ph05/tools/`, chỉnh cho PH-01: nhận diện mã UC, UI, EVT hai chữ số, thêm bốn bảng ma trận UC, API, UI, EVT, và ngưỡng ca hiệu năng P1 là NFR-01-004, 008, 009.

## 10. Câu hỏi mở

> **Câu hỏi mở Q01-40:** Khi liên kết bàn giao đã `OPENED` rồi mà đầu mối làm mất bí mật, `:reissue` trả mã lỗi nào? Ca `handover-reissue` tạm kỳ vọng `409` ERR-01-024 (muốn có lại phải xoay vòng, BR-01-006); cần SDD, API xác nhận hoặc thêm mã riêng.

> **Câu hỏi mở Q01-41:** Tra cứu danh bạ (FR-01-045) và xuất danh sách chưa có chỉ tiêu hiệu năng riêng; ca `perf-api` dùng chung NFR-01-001 (đọc p95 ≤ 300 ms). Đề nghị FRS bổ sung NFR riêng nếu tỉnh thí điểm có quy mô lớn hơn GĐ-07.

> **Câu hỏi mở Q01-42:** Đã giải quyết ở lần rà soát chéo bản 0.2: FRS §9.1 nay có đủ 54 mã lỗi (thêm ERR-01-051…054: lệch `Idempotency-Key`, thiếu xác thực hoặc quyền, callback saga không khớp, yêu cầu đang xử lý) và §9.4 có API-01-087, 088, khớp D03-04-PH01. Còn lại một việc cho người viết ca: ERR-01-053 chỉ ghi nhật ký vận hành nên ca kiểm nhật ký, không kiểm giao diện.

> **Câu hỏi mở Q01-43:** Ca đo cắt quyền 60 giây cần ba bản sao APISIX thật. Nếu SIT chỉ có một bản sao thì ca `perf-cutoff` chỉ chạy ở PERF; cần xác nhận cấu hình SIT với nhóm hạ tầng.

> **Câu hỏi mở Q01-44:** Ca khả dụng `wizard-usability` (NFR-01-014, 5 cán bộ lần đầu dùng, ≤ 30 phút) và diễn tập 6.2 cần cán bộ thật của tỉnh thí điểm; chưa có lịch. Tạm dùng cán bộ của đơn vị vận hành để chạy thử, số đo chính thức thay sau.

## 11. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Tập này không sửa tài liệu dùng chung. Việc cần làm ở tài liệu khác:

| Tài liệu | Đề nghị |
|---|---|
| D00-04 §3.2 | Cập nhật dải mã TS-01, TC-01 sau khi chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu`; cập nhật dòng PH-01 ở §2 thành "đủ bảy tập" khi các tập còn lại xong |
| D05-01 | Thêm sáu nhóm ca bắt buộc 100 % của PH-01 (phần Tóm tắt) vào danh mục cổng RG-3; ghi PH-01 vào bảng kịch bản xuyên suốt |
| D02-03-PH01 §9.1 | Đã làm ở bản 0.2 (Q01-42); không còn việc |
| D00-03 phần A | Cột "kiểm thử" của LGC-APIM-019; 020, LGC-HUB-010, 011 trỏ tới UAT-01…11 của tập này |
| D02-08 | Không đề xuất quyền mới; ca `perm-matrix` kiểm đúng sáu quyền `PERM-01-*` và hai quyền `PERM-18-*` đang dùng |
| ADR | Không đề xuất ADR mới |

: Đề nghị đồng bộ của tập kiểm thử PH-01

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: 35 kịch bản, ca chức năng, bảo mật, phi chức năng, 11 UAT, ma trận truy vết FR, LGC, BR, ERR, NFR, UC, API, UI, EVT sinh tự động; công cụ chép từ ph05 và chỉnh cho PH-01 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: thêm chú thích cho các bảng ma trận (sinh bằng gen_matrix.py), mục 0.1…0.3 của phần giới thiệu, đoạn mở cho các mục; đóng Q01-42 vì FRS đã có đủ 54 mã lỗi và 88 API |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bổ sung ca cho yêu cầu chốt 27/11/2026: FR-01-053 và API-01-089 (TC-01-146…149), TA khác xác nhận thao tác khẩn của FR-01-032 (TC-01-144, 145), FR-01-054 (TC-01-150, 151); thêm token S-SP, người dùng, hệ giả lập PH-13, PH-20 (151 ca) |
