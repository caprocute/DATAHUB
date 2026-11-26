---
ma_tai_lieu: D05-02-PH19
ten: Kịch bản và test case phân hệ PH-19 Thanh toán
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Đội kiểm thử, đội phát triển dh-payment và dh-console, kế toán và cán bộ vận hành thanh toán của tỉnh, hội đồng thẩm định
phan_he: PH-19
nguoi_lap: Nhóm phân hệ PH-19
---

# D05-02-PH19 · Kịch bản và test case phân hệ PH-19 Thanh toán

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chứng minh bốn điều:

- PH-19 làm đúng mọi yêu cầu đã duyệt ở FRS D02-03-PH19, và mỗi FR mức M có ít nhất một ca dương tính và một ca âm tính.
- PH-19 không làm mất chức năng của khối Payment hệ cũ (26 mục `LGC-PAY`).
- Không có đường nào để giao dịch trở thành "thành công" nếu không có kết quả đã xác minh từ nhà cung cấp, và không có đường nào để một người tự duyệt việc mình lập.
- Không có đường nào để dữ liệu thanh toán của tỉnh này lộ sang tỉnh khác.

**Phạm vi.** <!-- gen:summary:start -->34 kịch bản, 187 test case, 12 kịch bản nghiệm thu; phủ 69/69 FR (mọi 58 FR mức M có ca dương và ca âm), 34 BR, 50 mã lỗi, 32 NFR và 26/26 chức năng `LGC-PAY` của hệ cũ.<!-- gen:summary:end -->

**Căn cứ.** Tài liệu cùng bộ của PH-19 (FRS, use case, SDD, CSDL, API, màn hình), khung truy vết D02-03-PH19-00 §14 cấp mã TS và dải TC, ma trận phân quyền D02-08, cổng CI của D04-02, cấu trúc tài liệu kiểm thử theo ISO/IEC/IEEE 29119-3, yêu cầu an toàn thông tin cấp độ 3 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026) và bảo vệ dữ liệu cá nhân (Luật 91/2025/QH15, Nghị định 356/2025/NĐ-CP).

**Điểm cần hội đồng lưu ý.** Năm nhóm ca phải đạt 100% trước khi phát hành MVP:

- trạng thái cuối chỉ từ nguồn có xác thực, lượt quay về không đổi trạng thái (TS-19-12, 13, 30);
- chống trùng: cùng `Idempotency-Key`, cùng mã đơn hàng, IPN lặp (TS-19-11, 13);
- bốn mắt và tách nhiệm cho kích hoạt NCC, đối tác, hoàn tiền, xử lý chênh lệch, mở lại phiên (TS-19-33);
- cách ly tenant ở CSDL, Kafka, Valkey, kho đối tượng và khóa ký (TS-19-31);
- không lưu dữ liệu thẻ, che dữ liệu cá nhân, không lộ bí mật (TS-19-34).

Đặc tả kỹ thuật PayGov chưa có (OQ-19-01…07), nên mọi ca dùng **bộ giả lập PayGov** (`PGSIM`, NFR-19-032) với tên trường, chữ ký và mã kết quả theo giả định của D03-04-PH19 §3.2. Khi có tài liệu của VPCP, chỉ phần adapter và dữ liệu giả lập đổi; mã ca, bước và mong đợi nghiệp vụ giữ nguyên. Số liệu quy mô dùng giả định GĐ-01…07 (tỉnh thí điểm quy mô vừa, 200 HTTT).

## 0. Giới thiệu

Tài liệu đặc tả 34 kịch bản kiểm thử của PH-19 theo khung truy vết §14: 29 kịch bản theo use case (TS-19-01…29, cùng số với UC-19-01…29) và 5 kịch bản xuyên suốt (TS-19-30…34). Mỗi kịch bản có dải mã TC riêng (TS-19-01 dùng TC-19-001…025, TS-19-02 dùng 026…050, …) để các nhóm viết song song không trùng mã; mã được cấp bằng `ph19/tools/number_tcs.py` và không tái sử dụng.

| Người đọc | Đọc | Dùng để |
|---|---|---|
| Kiểm thử viên | Mục 1, 2, kịch bản được giao ở mục 4, 5 | Chạy ca, ghi kết quả vào bảng tính `ph19/D05-02-PH19-test-case.xlsx` |
| Lập trình viên | Mục 4 theo FR mình làm, mục 9 | Viết ca tự động (API, IT, E2E) cùng lúc với mã |
| Kế toán, cán bộ vận hành tỉnh | Mục 7 | Nghiệm thu người dùng tương đương hệ cũ |
| Hội đồng thẩm định | Tóm tắt, mục 3, 8 | Kiểm tra độ phủ |

## 1. Phạm vi, chiến lược và tổ chức kiểm thử

### 1.1. Đối tượng kiểm thử

| Thành phần | Mô tả | Tài liệu |
|---|---|---|
| `dh-payment` vai trò `api` | API quản trị `/api/payment/v1` (API-19-001…092), API đối tác `/api/payment-partner/v1` (API-19-101…110) | D03-04-PH19 |
| `dh-payment` vai trò `callback` | API callback `/api/payment-callback/v1` (API-19-201…205), trang UI-19-28 | D03-04-PH19 §3.2 |
| `dh-payment` vai trò `worker` | Tác vụ nền: InboxProcessor, PendingQueryScheduler, ExpiryScheduler, SessionScheduler, Matcher, WebhookDispatcher, OutboxRelay, StatsAggregator, ApprovalExpiryJob, các tác vụ bảo trì | D03-02-PH19 §3.6 |
| Schema `ph19_payment` trên `pg-payment` | 38 bảng, RLS `FORCE`, trigger bất biến | D03-03-PH19 |
| Kafka, Valkey, Garage, Ceph RGW WORM, OpenBao | Hạ tầng dùng chung theo D03-09 | D03-03-PH19 §7 |
| `dh-console` `features/payment` | 27 màn quản trị | D03-06-PH19 |
| Adapter PayGov | Lớp chống nhiễm (ADR-040); kiểm với `PGSIM` | D03-02-PH19 §4 |

Ngoài phạm vi: PH-03 (APISIX), PH-12 (cấp token), PH-13 (lưu kiểm toán) được kiểm ở kịch bản của các phân hệ đó; ở đây chỉ kiểm phần PH-19 gọi tới hoặc nhận từ chúng.

### 1.2. Mức kiểm thử

| Mức | Ký hiệu | Công cụ | Phạm vi |
|---|---|---|---|
| Đơn vị | UT | JUnit 5, AssertJ | Máy trạng thái, kiểm hợp lệ BR-19-004, tính chữ ký, che dữ liệu, so khớp |
| Tích hợp | IT | Testcontainers (PostgreSQL 18, Kafka, Valkey), WireMock | Repository dưới RLS, outbox, inbox, khóa lạc quan |
| CSDL | DB | `ph19_isolation_test.sql` (D03-03-PH19 §4) | RLS, trigger bất biến, quyền vai trò |
| Hợp đồng | CT | `check_contracts.py`, Schemathesis | OpenAPI, AsyncAPI, ví dụ |
| API | API | REST Assured | Mọi API qua PH-03 thật ở môi trường kiểm thử |
| Đầu-cuối | E2E | Playwright + axe-core | 28 màn |
| Hiệu năng | k6 | k6, Grafana | TS-19-32 |
| Hỗn loạn | Chaos | Chaos Mesh | TS-19-34 |
| Bảo mật | ZAP, thủ công | OWASP ZAP, Burp | TS-19-30, 31 theo OWASP ASVS 5.0 mức 2 |

### 1.3. Môi trường kiểm thử

| Môi trường | Mục đích | NCC | Dữ liệu |
|---|---|---|---|
| DEV | Ca UT, IT, API của lập trình viên | `PGSIM` | Bộ dữ liệu mục 2 |
| TEST | Toàn bộ ca tự động, kiểm thử viên | `PGSIM` | Bộ dữ liệu mục 2, làm mới mỗi đêm |
| PERF | TS-19-32 | `PGSIM` chế độ trễ cố định 150 ms | Sinh tổng hợp: 10 triệu giao dịch mỗi tenant, 3 tenant (GĐ-01) |
| UAT | Mục 7, AC-19-02 | Môi trường thử thật của PayGov khi VPCP cấp; trước đó `PGSIM` | Dữ liệu di trú đã che từ hệ cũ |

`PGSIM` cho phép cấu hình từng phản hồi qua API quản trị của nó: khởi tạo thành công, từ chối kèm mã, trễ quá thời gian chờ, lỗi 5xx; gửi IPN với chữ ký đúng, sai, quá hạn, lặp, sai số tiền; trả truy vấn; sinh tệp đối soát theo kịch bản có chênh lệch.

### 1.4. Tiêu chí vào và ra

| Mức | Vào | Ra |
|---|---|---|
| Đợt kiểm thử MVP | Cổng CI-1…9 xanh; DDL áp thành công; `PGSIM` sẵn sàng; dữ liệu mục 2 nạp | 100% ca P1 đạt; ≥ 95% ca P2 đạt, ca chưa đạt có lỗi theo dõi mức thấp; không còn lỗi mức Nghiêm trọng, Cao; năm nhóm ca ở Tóm tắt đạt 100%; TS-19-32 đạt ngưỡng; AC-19-01…07 của FRS §13 có bằng chứng |
| Đợt Đ2b | Như trên cho FR Đ2b | Như trên cho ca gắn FR Đ2b |

Ca gắn FR thuộc Đ2b có nhãn `@D2b` trong Gherkin và cột "Phát hành" trong bảng tính; trong đợt MVP chúng được đánh "Chưa chạy" mà không chặn phát hành.

### 1.5. Quy ước mã và cách trình bày

Mỗi test case là một khối có cấu trúc thống nhất với D05-02-PH04, D05-02-PH07:

- Tiêu đề: mã, tên ca.
- **Loại**: Dương, Âm, Biên, Bảo mật, Hiệu năng, Khả dụng, Truy cập.
- **Ưu tiên**: P1 chặn phát hành, P2 quan trọng, P3 bổ sung.
- **Tự động**: UT, IT, DB, CT, API, E2E, k6, Chaos, ZAP, hoặc "Thủ công".
- **Truy vết**: FR, BR, API, UI, ERR, EVT, UC, NFR, LGC liên quan.
- **Tiền điều kiện / dữ liệu**: tham chiếu mã dữ liệu ở mục 2.
- **Bước**: đánh số. Đường dẫn API quản trị tương đối với `/api/payment/v1`; API đối tác ghi tiền tố `P:` (tương đối với `/api/payment-partner/v1`); API callback ghi tiền tố `C:` (tương đối với `/api/payment-callback/v1`).
- **Mong đợi**: mã HTTP, mã lỗi, trạng thái dữ liệu sau, sự kiện, webhook, kiểm toán.

| Ký hiệu | Nghĩa |
|---|---|
| 403-PQ | `403` với ERR-19-046 (OPA từ chối, thiếu `PERM-19-*`) |
| 404-ẩn | `404` với ERR-19-020, không phân biệt "không tồn tại" và "ngoài phạm vi" |
| KT: có (hành động) | Có bản ghi kiểm toán trong `outbox_event` cùng giao dịch CSDL và tới PH-13, đủ trường theo FR-00-041 |
| KT: không | Không có bản ghi kiểm toán nghiệp vụ |
| EVT: `{thực thể}.{sự kiện}` | Có đúng một bản tin trên topic `t68.payment.{thực thể}.{sự kiện}.v1` (CloudEvents, có `dhtenant`) |
| EVT: không | Sau 10 giây không có dòng mới trong `outbox_event` và không có bản tin trên topic liên quan |
| WH: `{loại}` | Đầu nhận webhook của đối tác nhận đúng một sự kiện loại đó, chữ ký `X-Datahub-Signature` hợp lệ |
| ST: A → B | Trạng thái giao dịch đổi từ A sang B và có đúng một dòng `transaction_event` mới |
| ST: giữ A | Trạng thái không đổi, không có dòng `transaction_event` mới |

### 1.6. Quản lý lỗi và báo cáo

Lỗi ghi ở công cụ theo dõi của dự án, gắn mã TC, mã FR, mức (Nghiêm trọng, Cao, Trung bình, Thấp). Lỗi làm sai số tiền, sai trạng thái cuối, lộ dữ liệu chéo tenant, lộ bí mật hoặc cho phép tự duyệt luôn ở mức Nghiêm trọng. Báo cáo kết quả mỗi đợt gồm: số ca theo kết quả, theo kịch bản, theo ưu tiên; danh sách lỗi mở; bảng tính đã điền; ma trận mục 8 sinh lại từ kết quả.

## 2. Dữ liệu kiểm thử

### 2.1. Tenant

| Mã | Tenant | Trạng thái PH-19 | Dùng cho |
|---|---|---|---|
| T68 | Tỉnh thí điểm (giả định GĐ-01, quy mô vừa) | Bật | Hầu hết ca |
| T99 | Tỉnh thứ hai | Bật | Cách ly tenant (TS-19-31), trùng mã giữa hai tỉnh |
| T50 | Tỉnh thứ ba | PH-19 tạm ngừng bởi PH-20 | ERR-19-049 |

### 2.2. Người dùng và client

Người dùng mang đúng một vai trò trừ khi ghi khác. Mọi người dùng là người của T68 trừ hậu tố `-T99`.

| Mã | Vai trò | Ghi chú |
|---|---|---|
| U-ADM1, U-ADM2 | `ROLE-PAYMENT_ADMIN` | Hai người để kiểm bốn mắt khi một người lập |
| U-APR1, U-APR2, U-APR3 | `ROLE-PAYMENT_APPROVER` | Ba người để kiểm duyệt hai cấp |
| U-ACC1, U-ACC2 | `ROLE-PAYMENT_ACCOUNTANT` | |
| U-OPR1 | `ROLE-PAYMENT_OPERATOR` | |
| U-AUD1 | `ROLE-AUDITOR` | |
| U-SEC1 | `ROLE-SECURITY_OFFICER` | |
| U-TEN1 | `ROLE-TENANT_ADMIN` | |
| U-PLA1 | `ROLE-PLATFORM_ADMIN` | Không có phiên break-glass |
| U-AA1 | `ROLE-PAYMENT_ADMIN` + `ROLE-PAYMENT_APPROVER` | Tỉnh thiếu nhân sự (khung §13.4 quy tắc 8) |
| U-ADM1-T99 | `ROLE-PAYMENT_ADMIN` của T99 | |
| C-DVC | `ROLE-PARTNER_SYSTEM`, client mTLS của P-DVC | |
| C-MC | Client `private_key_jwt` của P-MC | |
| C-LEG, C-SUS | Client của P-LEG, P-SUS | |
| C-DVC-T99 | Client của P-DVC ở T99 (cùng mã đối tác) | |

### 2.3. Nhà cung cấp, dịch vụ, đối tác

| Mã | Đối tượng | Trạng thái | Ghi chú |
|---|---|---|---|
| PV-PG | NCC `PAYGOV` kết nối `PGSIM` | `ACTIVE`, `HEALTHY` | Bảng ánh xạ mã kết quả v1 (31 dòng, `seed_paygov_mapping`) |
| PV-NEW | NCC `MOCK2` | `DRAFT` | Chưa có thông tin xác thực |
| PV-SUS | NCC `PAYGOV2` | `SUSPENDED` | |
| G-TP, G-XD | Nhóm dịch vụ "Tư pháp", "Xây dựng" | — | Mã lĩnh vực PH-07 còn hiệu lực |
| S-HT | Dịch vụ "Lệ phí đăng ký hộ tịch", nhóm G-TP, NCC PV-PG | `ACTIVE` | Số tiền cố định 50.000 ₫ |
| S-XD | Dịch vụ "Phí cấp phép xây dựng", G-XD, PV-PG | `ACTIVE` | 10.000 ₫ … 50.000.000 ₫ |
| S-OFF | Dịch vụ "Phí thẩm định (ngừng)", PV-PG | `SUSPENDED` | |
| S-PVS | Dịch vụ gắn PV-SUS | `ACTIVE` | |
| P-DVC | Đối tác "Cổng DVC tỉnh" | `ACTIVE`, chế độ `DATAHUB` | Gán S-HT, S-XD; hạn mức 20.000.000 ₫ mỗi giao dịch, 1.000 giao dịch và 500.000.000 ₫ mỗi ngày; webhook `https://dvc.t68.test/hook` nhận 8 loại sự kiện |
| P-MC | Đối tác "Một cửa điện tử" | `ACTIVE`, `SHADOW` | Gán S-HT |
| P-LEG | Đối tác "HTTT đất đai" | `ACTIVE`, `LEGACY` | |
| P-SUS | Đối tác "HTTT tạm dừng" | `SUSPENDED` | |
| P-NEW | Đối tác mới | `DRAFT` | Chưa có HTTT, chưa gán dịch vụ |

### 2.4. Giao dịch mẫu

| Mã | Trạng thái | Ghi chú |
|---|---|---|
| TX-OK | `SUCCEEDED`, 50.000 ₫, S-HT, P-DVC | Thanh toán hôm qua; đối soát `MATCHED` |
| TX-BIG | `SUCCEEDED`, 7.500.000 ₫, S-XD | Hoàn trên ngưỡng hai cấp |
| TX-PEND | `PENDING`, 1.200.000 ₫, S-XD | Chưa có IPN, tạo 5 phút trước |
| TX-OLD | `SUCCEEDED`, `paid_at` 200 ngày trước | Quá hạn hoàn 180 ngày |
| TX-PR | `PARTIALLY_REFUNDED`, 1.000.000 ₫, đã hoàn 400.000 ₫ | |
| TX-TEST | `SUCCEEDED`, `is_test = true` | |
| TX-EXP | `EXPIRED` | |
| TX-T99 | Giao dịch của T99 | |

### 2.5. Tệp mẫu

| Mã | Nội dung |
|---|---|
| F-RECON-OK | Tệp đối soát PayGov ngày D-1 khớp 100% |
| F-RECON-DIFF | Tệp D-1 có 1 dòng thiếu ở Datahub, 1 dòng thiếu ở NCC, 1 lệch số tiền, 1 lệch trạng thái, 1 trùng |
| F-RECON-BADHASH | Tệp hợp lệ nhưng mã băm gửi kèm sai |
| F-LEG-CSV | Năm tệp CSV hệ cũ theo mẫu D06-01 (500 giao dịch, 3 dòng lỗi định dạng, 1 số tiền 2.500.000.000 ₫) |
| F-VOUCHER | Tệp PDF chứng từ hoàn tiền |
| F-EICAR | Tệp thử nghiệm phần mềm độc hại EICAR |

### 2.6. Nguyên tắc dữ liệu

Không dùng dữ liệu cá nhân thật. Họ tên, số định danh, điện thoại sinh bằng bộ sinh dữ liệu giả có định dạng Việt Nam hợp lệ. Mỗi ca tự tạo dữ liệu riêng với `partner_order_id` mang tiền tố mã ca (`TC19-251-…`) để chạy song song không ảnh hưởng nhau, trừ các bản ghi chuẩn ở mục 2.3, 2.4 chỉ đọc.

## 3. Tổng quan kịch bản kiểm thử

### 3.1. Danh sách kịch bản

Bảng sinh bằng `ph19/tools/gen_matrix.py`. Một ca thường gộp nhiều bước kiểm có mong đợi riêng (ví dụ một ca âm của TS-19-11 thử lần lượt 15 bước của BR-19-004), nên cột "Số bước kiểm" mới là con số so được với cột "TC dự kiến" của khung §14. Dải số còn trống của mỗi kịch bản để thêm ca khi tách nhỏ hoặc khi kiểm thử khám phá tìm ra lỗi mới.

<!-- gen:ts:start -->
| Kịch bản | Tên | Dải TC | Số ca | Số bước kiểm | Dương | Âm, bảo mật | Mục |
|---|---|---|---|---|---|---|---|
| TS-19-01 | Khai báo NCC và thông tin xác thực | 001…025 | 5 | 17 | 2 | 3 | 4 |
| TS-19-02 | Kiểm tra kết nối và giao dịch thử | 026…050 | 4 | 12 | 2 | 2 | 4 |
| TS-19-03 | Kích hoạt NCC có phê duyệt | 051…075 | 5 | 14 | 3 | 2 | 4 |
| TS-19-04 | Tạm dừng, mở lại, ngừng hẳn NCC | 076…100 | 6 | 13 | 4 | 3 | 4 |
| TS-19-05 | Tra cứu và cập nhật NCC | 101…125 | 7 | 23 | 5 | 4 | 4 |
| TS-19-06 | Giám sát sức khỏe và xoay khóa | 126…150 | 4 | 11 | 3 | 2 | 4 |
| TS-19-07 | Quản lý nhóm dịch vụ | 151…175 | 2 | 7 | 1 | 1 | 4 |
| TS-19-08 | Quản lý dịch vụ thanh toán | 176…200 | 5 | 14 | 2 | 3 | 4 |
| TS-19-09 | Đăng ký và phê duyệt đối tác | 201…225 | 7 | 21 | 4 | 3 | 4 |
| TS-19-10 | Client, dịch vụ được gán, webhook đối tác | 226…250 | 5 | 17 | 3 | 3 | 4 |
| TS-19-11 | Tạo giao dịch thanh toán | 251…275 | 8 | 23 | 3 | 5 | 4 |
| TS-19-12 | Người nộp quay về | 276…300 | 3 | 8 | 1 | 2 | 4 |
| TS-19-13 | Nhận và xử lý IPN | 301…325 | 6 | 13 | 3 | 3 | 4 |
| TS-19-14 | Hủy và hết hạn giao dịch | 326…350 | 4 | 7 | 2 | 2 | 4 |
| TS-19-15 | Đối tác truy vấn trạng thái | 351…375 | 3 | 7 | 2 | 1 | 4 |
| TS-19-16 | Đồng bộ trạng thái và xử lý lại IPN | 376…400 | 4 | 9 | 3 | 2 | 4 |
| TS-19-17 | Lập yêu cầu hoàn tiền | 401…425 | 3 | 10 | 2 | 1 | 4 |
| TS-19-18 | Phê duyệt và thực thi hoàn tiền | 426…450 | 8 | 15 | 6 | 3 | 4 |
| TS-19-19 | Đối soát ngày | 451…475 | 6 | 12 | 3 | 4 | 4 |
| TS-19-20 | Xử lý chênh lệch | 476…500 | 6 | 12 | 5 | 1 | 4 |
| TS-19-21 | Chốt, mở lại phiên và biên bản | 501…525 | 5 | 12 | 3 | 4 | 4 |
| TS-19-22 | Tra cứu và xuất giao dịch | 526…550 | 5 | 13 | 3 | 2 | 4 |
| TS-19-23 | Chi tiết giao dịch | 551…575 | 3 | 7 | 2 | 1 | 4 |
| TS-19-24 | Nhật ký kiểm toán và tích hợp | 576…600 | 4 | 6 | 2 | 2 | 4 |
| TS-19-25 | Dashboard và cảnh báo | 601…625 | 5 | 10 | 4 | 1 | 4 |
| TS-19-26 | Báo cáo định kỳ | 626…650 | 3 | 6 | 2 | 1 | 4 |
| TS-19-27 | Thông báo kết quả cho đối tác | 651…675 | 7 | 13 | 4 | 3 | 4 |
| TS-19-28 | Cấu hình và khởi tạo tenant | 676…700 | 4 | 10 | 2 | 2 | 4 |
| TS-19-29 | Di trú và chạy song song | 701…725 | 9 | 19 | 5 | 4 | 4 |
| TS-19-30 | Bảo mật callback và webhook | 726…750 | 8 | 20 | 0 | 8 | 5 |
| TS-19-31 | Cách ly tenant và RLS | 751…775 | 6 | 12 | 0 | 6 | 5 |
| TS-19-32 | Hiệu năng, tải và dung lượng | 776…800 | 11 | 11 | 0 | 0 | 5 |
| TS-19-33 | Phân quyền và tách nhiệm | 801…825 | 5 | 8 | 0 | 5 | 5 |
| TS-19-34 | Chịu lỗi, phục hồi và an toàn dữ liệu | 826…850 | 11 | 19 | 5 | 2 | 5 |
| **Tổng** | | | **187** | 431 | 91 | 91 | |
<!-- gen:ts:end -->

### 3.2. Máy trạng thái được kiểm thử

Mỗi chuyển trạng thái của khung §7 có ít nhất một ca; mỗi trạng thái có ít nhất một ca thử chuyển trái phép (ERR-19-021).

| Thực thể | Chuyển hợp lệ | Chuyển trái phép |
|---|---|---|
| NCC (§7.1) | TC-19-001, TC-19-051, TC-19-053, TC-19-055, TC-19-076, TC-19-077, TC-19-078, TC-19-080 | TC-19-081, TC-19-105 |
| Dịch vụ (§7.2) | TC-19-176, TC-19-178 | TC-19-179, TC-19-180 |
| Đối tác (§7.3) | TC-19-201, TC-19-202, TC-19-204, TC-19-206 | TC-19-203, TC-19-205 |
| Giao dịch (§7.4) | TC-19-251, TC-19-256, TC-19-301, TC-19-302, TC-19-326, TC-19-328, TC-19-305, TC-19-478, TC-19-428, TC-19-429 | TC-19-327, TC-19-306 |
| Yêu cầu hoàn (§7.5) | TC-19-401, TC-19-426, TC-19-427, TC-19-428, TC-19-430, TC-19-431, TC-19-432 | TC-19-433 |
| Phiên đối soát (§7.6) | TC-19-451, TC-19-452, TC-19-453, TC-19-454, TC-19-501, TC-19-504 | TC-19-502, TC-19-503 |
| Chênh lệch (§7.7) | TC-19-476, TC-19-477, TC-19-478, TC-19-481 | TC-19-480 |
| Lượt gửi webhook (§7.8) | TC-19-651, TC-19-652, TC-19-654, TC-19-655 | TC-19-656 |

## 4. Kịch bản và test case chức năng

### TS-19-01 · Khai báo NCC và thông tin xác thực

**Mục tiêu.** Xác nhận khai báo nhà cung cấp thay chức năng "Thêm nhà cung cấp" của hệ cũ, mã NCC bất biến, và thông tin xác thực chỉ lưu tham chiếu tới OpenBao, không bao giờ lưu hay trả giá trị bí mật.

**Phủ.** FR-19-001, 002; UC-19-01; API-19-002, 006, 007; UI-19-05, 04; ERR-19-001, 038, 022; NFR-19-022; LGC-PAY-001, 004.

**Tiền điều kiện chung.** Bộ dữ liệu mục 2 đã nạp; OpenBao TEST có `kv/dh/t68/payment/providers/mock2/sandbox/signing-key`.

#### TC-19-001 · Khai báo NCC mới ở trạng thái Nháp <!--k:pv-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-001 · API-19-002, 003 · UI-19-05 · UC-19-01 · LGC-PAY-001
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. Mở UI-19-03, bấm "Thêm nhà cung cấp", nhập mã `MOCK3`, tên, loại `MOCK`, địa chỉ thử `https://pgsim.test/mock3`, đầu mối kỹ thuật.
  2. Bấm "Lưu".
  3. Gọi `GET /providers/{id}`.
- **Mong đợi** Bước 2 gọi `POST /providers` trả `201`, `Location`, `ETag`; màn chuyển tới UI-19-04 với thông báo "Đã khai báo nhà cung cấp MOCK3 ở trạng thái Nháp". Bước 3: `status = DRAFT`, `healthStatus = UNKNOWN`, `callbackUrls.ipn` chứa `connectionKey` 32 ký tự ngẫu nhiên, `allowedActions` có `EDIT`, `DELETE`, `TEST_CONNECTION`, `MANAGE_CREDENTIAL`; `disabledReasons.SUBMIT_ACTIVATION` liệt kê mục checklist thiếu. KT: có (`PROVIDER_CREATE`). EVT: `provider.created`.

#### TC-19-002 · Khai báo NCC thiếu trường, sai định dạng, trùng mã <!--k:pv-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-001 · API-19-002 · ERR-19-001, 038, 046
- **Tiền điều kiện / dữ liệu** U-ADM1; U-OPR1.
- **Bước**
  1. `POST /providers` thiếu `techContact`.
  2. `POST /providers` với `sandboxBaseUrl = "http://pgsim.test"`.
  3. `POST /providers` với `code = "PAYGOV"` (trùng PV-PG).
  4. U-ADM1-T99 `POST /providers` với `code = "PAYGOV"` ở T99.
  5. U-OPR1 `POST /providers` với nội dung hợp lệ.
- **Mong đợi** Bước 1, 2 trả `400` ERR-19-001 với `errors[]` chỉ đúng trường. Bước 3 trả `409` ERR-19-038. Bước 4 trả `201` (mã duy nhất trong tenant, không toàn cục). Bước 5 trả 403-PQ. KT: không với bước 1, 2, 3, 5.

#### TC-19-003 · Mã và loại kết nối của NCC bất biến <!--k:pv-immutable-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-001, 009 · API-19-004 · ERR-19-001
- **Tiền điều kiện / dữ liệu** U-ADM1; NCC `MOCK3` từ TC-19-001.
- **Bước**
  1. `PATCH /providers/{id}` với `{"code":"MOCK4"}` và `If-Match` đúng.
  2. `PATCH /providers/{id}` với `{"adapterType":"PAYGOV"}`.
- **Mong đợi** Cả hai trả `400` ERR-19-001; dữ liệu không đổi; `ETag` không đổi.

#### TC-19-004 · Gắn tham chiếu bí mật cho môi trường thử <!--k:cred-bind-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-002 · API-19-006, 007 · UI-19-04 · NFR-19-022
- **Tiền điều kiện / dữ liệu** U-ADM1; PV-NEW.
- **Bước**
  1. Mở UI-19-04 tab "Thông tin xác thực", bấm "Gắn tham chiếu" cho `SANDBOX` / `SIGNING_KEY`, nhập đường `kv/dh/t68/payment/providers/mock2/sandbox/signing-key`, hiệu lực đến 30/06/2028.
  2. Gọi `GET /providers/{id}/credentials`.
  3. Tìm chuỗi giá trị khóa (lấy từ OpenBao bằng tài khoản kiểm thử) trong thân phản hồi bước 2, `integration_log`, log ứng dụng 5 phút qua, bảng `provider_credential`.
- **Mong đợi** Bước 1 gọi `PUT /providers/{id}/credentials/SANDBOX` trả `200`. Bước 2 trả dòng có `secretRef`, `fingerprint`, `algorithm`, `status = ACTIVE`, `expiresAt`, **không** có trường giá trị. Bước 3 không tìm thấy ở bất kỳ nơi nào. KT: có (`CREDENTIAL_BIND`, chỉ ghi đường tham chiếu).

#### TC-19-005 · Tham chiếu bí mật sai, ngoài vùng tenant, đã hết hạn <!--k:cred-bind-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-002 · API-19-007 · ERR-19-001, 022 · NFR-19-022, 025
- **Tiền điều kiện / dữ liệu** U-ADM1; PV-NEW; U-ACC1.
- **Bước**
  1. `PUT …/credentials/SANDBOX` với đường không tồn tại trong OpenBao.
  2. `PUT …/credentials/SANDBOX` với đường `kv/dh/t99/payment/...` (của tenant khác).
  3. `PUT …/credentials/PRODUCTION` với `expiresAt` đã qua.
  4. U-ACC1 gọi `PUT …/credentials/SANDBOX` hợp lệ.
- **Mong đợi** Bước 1 trả `422` ERR-19-022 "tham chiếu không tồn tại". Bước 2 trả `400` ERR-19-001 (đường phải nằm dưới `kv/dh/t68/payment/`), không chạm OpenBao của T99. Bước 3 trả `422` ERR-19-022. Bước 4 trả 403-PQ.

### TS-19-02 · Kiểm tra kết nối và giao dịch thử

**Mục tiêu.** Xác nhận bước "kiểm tra luồng thanh toán thử, kiểm tra phản hồi" của hệ cũ được thay bằng kiểm tra kết nối có bước con và giao dịch thử có IPN, ghi bằng chứng cho checklist kích hoạt.

**Phủ.** FR-19-003, 004; UC-19-02; API-19-009, 010, 011; UI-19-06; ERR-19-022, 021; BR-19-010, 033; LGC-PAY-001, 007.

**Tiền điều kiện chung.** PV-NEW đã gắn đủ thông tin xác thực hai môi trường (từ TC-19-004 và tương tự cho `PRODUCTION`).

#### TC-19-026 · Kiểm tra kết nối đạt, ghi từng bước con <!--k:conn-test-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-003 · API-19-009, 011 · UI-19-06 · LGC-PAY-007
- **Tiền điều kiện / dữ liệu** U-ADM1; `PGSIM` trả lời bình thường.
- **Bước**
  1. `POST /providers/{id}/connection-tests` với `{"environment":"SANDBOX"}` và `Idempotency-Key`.
  2. Thăm dò `GET /providers/{id}/check-runs` tới khi kết quả khác `RUNNING`.
- **Mong đợi** Bước 1 trả `202`, `Location` tới lần chạy. Bước 2 có lần chạy `CONNECTION`, `PASSED`, bốn bước con (DNS, TLS 1.3, xác thực, gọi API kiểm tra) đều đạt kèm thời lượng; `integration_log` có lượt `OUT_PROVIDER`/`HEALTH`. KT: có (`PROVIDER_CONNECTION_TEST`).

#### TC-19-027 · Kiểm tra kết nối thất bại ở từng bước <!--k:conn-test-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-003 · API-19-009, 011 · ERR-19-022
- **Tiền điều kiện / dữ liệu** U-ADM1; `PGSIM` cấu hình lần lượt bốn lỗi.
- **Bước**
  1. `PGSIM` trả chứng thư tự ký; chạy kiểm tra.
  2. `PGSIM` trả `401` ở bước xác thực; chạy kiểm tra.
  3. `PGSIM` không trả lời quá 10 giây; chạy kiểm tra.
  4. Gỡ tham chiếu `PRODUCTION`; chạy kiểm tra `PRODUCTION`.
- **Mong đợi** Bước 1–3: lần chạy `FAILED`, bước con hỏng đúng vị trí (TLS, xác thực, gọi API), có thông điệp dễ hiểu, các bước sau "bỏ qua". Bước 4 trả `422` ERR-19-022 ngay, không tạo lần chạy. Không lần chạy nào làm đổi trạng thái NCC.

#### TC-19-028 · Giao dịch thử thành công kèm IPN <!--k:test-txn-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-004 · BR-19-033 · API-19-010, 011, 201 · UI-19-06, 28
- **Tiền điều kiện / dữ liệu** U-ADM1; kiểm tra kết nối `SANDBOX` đạt.
- **Bước**
  1. `POST /providers/{id}/test-transactions` với `{"amount":10000}`.
  2. Mở `paymentUrl` trả về, `PGSIM` hoàn tất thanh toán và gửi IPN hợp lệ.
  3. Thăm dò `check-runs`.
- **Mong đợi** Bước 1 trả `202`; giao dịch có `isTest = true`. Bước 2: UI-19-28 hiện nhãn "Giao dịch thử", nút quay về bước ② UI-19-06. Bước 3: lần chạy `TEST_TRANSACTION` `PASSED`, có liên kết IPN `VERIFIED`. Giao dịch thử không xuất hiện ở UI-19-01, UI-19-14 mặc định, hạn mức đối tác, phiên đối soát (BR-19-033). WH: không (giao dịch thử không thuộc đối tác).

#### TC-19-029 · Giao dịch thử không nhận IPN, bị NCC từ chối <!--k:test-txn-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-004 · BR-19-010 · API-19-010, 011 · ERR-19-021
- **Tiền điều kiện / dữ liệu** U-ADM1; `PGSIM` không gửi IPN (lần 1), từ chối khởi tạo mã `51` (lần 2); PV-PG.
- **Bước**
  1. Tạo giao dịch thử, hoàn tất thanh toán, chờ 15 phút (đồng hồ giả).
  2. Tạo giao dịch thử khi `PGSIM` từ chối.
  3. Gọi `POST /providers/{PV-PG}/test-transactions` với `environment = PRODUCTION`.
- **Mong đợi** Bước 1: kết quả `PASSED_WITHOUT_IPN`; checklist điều kiện (2) không đạt. Bước 2: `FAILED` kèm mã đã ánh xạ. Bước 3 trả `400` ERR-19-001 (giao dịch thử chỉ ở môi trường thử, BR-19-033).

### TS-19-03 · Kích hoạt NCC có phê duyệt

**Mục tiêu.** Xác nhận kích hoạt đi đúng bốn bước, checklist BR-19-010 được kiểm cả lúc gửi và lúc duyệt, bốn mắt BR-19-011 không thể lách.

**Phủ.** FR-19-005; UC-19-03; API-19-012, 048, 049, 050; UI-19-06, 13; ERR-19-033, 034, 035; BR-19-010, 011; LGC-PAY-007.

**Tiền điều kiện chung.** PV-NEW có kiểm tra kết nối `PRODUCTION` đạt trong 24 giờ, giao dịch thử `PASSED`, thông tin xác thực còn hạn ≥ 30 ngày, đủ hai đầu mối.

#### TC-19-051 · Gửi đề nghị kích hoạt khi checklist đạt <!--k:act-submit-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-005 · BR-19-010 · API-19-012 · UI-19-06 · LGC-PAY-007
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. Mở UI-19-06, đi bước ① → ④, nhập ghi chú, bấm "Gửi đề nghị kích hoạt".
  2. `GET /providers/{id}`.
- **Mong đợi** Bước 1 gọi `POST /providers/{id}/lifecycle-requests` `{"action":"ACTIVATE"}` trả `201` với `approval` `PENDING`, loại `PROVIDER_ACTIVATE`. Bước 2: `status = PENDING_ACTIVATION`, `hasPendingChange = true`. U-APR1 thấy đề nghị trong hộp "Chờ tôi quyết định" của UI-19-13 và huy hiệu menu tăng 1. KT: có (`APPROVAL_REQUEST_CREATE`). EVT: `approval.requested`.

#### TC-19-052 · Gửi đề nghị khi thiếu từng điều kiện checklist <!--k:act-submit-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-005 · BR-19-010 · API-19-012 · ERR-19-035
- **Tiền điều kiện / dữ liệu** U-ADM1; bốn bản sao của PV-NEW, mỗi bản thiếu đúng một điều kiện: kiểm tra kết nối thật cách 25 giờ; giao dịch thử chỉ `PASSED_WITHOUT_IPN`; khóa thật còn 29 ngày; thiếu đầu mối nghiệp vụ.
- **Bước**
  1. Gửi đề nghị `ACTIVATE` cho từng bản.
- **Mong đợi** Mỗi lần trả `422` ERR-19-035 với `detail` liệt kê đúng một mục thiếu; trạng thái giữ `DRAFT`; không tạo `approval_request`. Nút "Gửi đề nghị" ở UI-19-06 vô hiệu với tooltip nêu đúng mục thiếu.

#### TC-19-053 · Người khác người lập duyệt kích hoạt <!--k:act-approve-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-005 · BR-19-011 · API-19-049, 050 · UI-19-13
- **Tiền điều kiện / dữ liệu** Đề nghị từ TC-19-051; U-APR1.
- **Bước**
  1. U-APR1 mở UI-19-13, mở đề nghị, xem khối "Kiểm tra lại lúc duyệt", bấm "Duyệt".
  2. `GET /providers/{id}`.
- **Mong đợi** Bước 1 gọi `POST /approval-requests/{id}/decisions` `{"decision":"APPROVE"}` có `If-Match`, trả `200`, `status = APPROVED`. Bước 2: `status = ACTIVE`, `activatedAt` có giá trị, `effectiveFrom` theo đề nghị. KT: có (`APPROVAL_DECIDE`, `PROVIDER_ACTIVATE`). EVT: `provider.activated`, `approval.decided`.

#### TC-19-054 · Người lập tự duyệt, người duyệt khi checklist đổi <!--k:act-approve-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-005 · BR-19-010, 011 · API-19-050 · ERR-19-033, 035, 046
- **Tiền điều kiện / dữ liệu** U-AA1 (vừa quản trị vừa phê duyệt) lập đề nghị kích hoạt cho bản sao PV-NEW; U-APR1; U-ADM2.
- **Bước**
  1. U-AA1 gọi `POST /approval-requests/{id}/decisions` `APPROVE`.
  2. U-AA1 mở UI-19-13.
  3. U-ADM2 gọi duyệt.
  4. Cho khóa thật hết hạn (đồng hồ giả +2 năm), U-APR1 gọi duyệt.
- **Mong đợi** Bước 1 trả `403` ERR-19-033 (so theo `sub`, không theo tên). Bước 2: nút "Duyệt" vô hiệu kèm "Bạn là người lập đề nghị này". Bước 3 trả 403-PQ. Bước 4 trả `422` ERR-19-035; đề nghị vẫn `PENDING`. Mọi bước: NCC giữ `PENDING_ACTIVATION`.

#### TC-19-055 · Từ chối, rút và hết hạn đề nghị kích hoạt <!--k:act-reject-expire-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-005 · BR-19-011 · API-19-050 · ERR-19-034 · UI-19-13
- **Tiền điều kiện / dữ liệu** Ba đề nghị kích hoạt A, B, C trên ba bản sao PV-NEW.
- **Bước**
  1. U-APR1 từ chối A không có ý kiến.
  2. U-APR1 từ chối A với ý kiến 20 ký tự.
  3. U-ADM1 (người lập) rút B.
  4. Tiến đồng hồ 7 ngày 1 phút, chạy ApprovalExpiryJob cho C.
  5. U-APR1 duyệt C.
- **Mong đợi** Bước 1 trả `400` ERR-19-001. Bước 2: A `REJECTED`, NCC về `DRAFT`. Bước 3: B `WITHDRAWN`, NCC về `DRAFT`. Bước 4: C `EXPIRED`, NCC về `DRAFT`, người lập nhận thông báo. Bước 5 trả `409` ERR-19-034. KT: có cho bước 2, 3, 4.

### TS-19-04 · Tạm dừng, mở lại, ngừng hẳn NCC

**Mục tiêu.** Xác nhận chức năng "Dừng nhà cung cấp" và "Xóa nhà cung cấp" của hệ cũ được thay bằng tạm dừng không làm mất kết quả của giao dịch đang dở, và xóa chỉ áp dụng cho NCC chưa từng có giao dịch.

**Phủ.** FR-19-006, 010; UC-19-04; API-19-005, 012, 013, 014; UI-19-03, 04; ERR-19-017, 021, 036, 037; BR-19-009, 027; LGC-PAY-005, 008.

**Tiền điều kiện chung.** Bản sao PV-PG tên PV-PG2 `ACTIVE` có TX-PEND2 (`PENDING`) và dịch vụ S-PG2 `ACTIVE`.

#### TC-19-076 · Tạm dừng NCC khi còn giao dịch dở <!--k:pv-suspend-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-006 · BR-19-009 · API-19-013 · UI-19-04 · LGC-PAY-008
- **Tiền điều kiện / dữ liệu** U-ADM1; C-DVC được gán S-PG2.
- **Bước**
  1. U-ADM1 bấm "Tạm dừng" trên UI-19-04, đọc hộp, nhập lý do, xác nhận.
  2. C-DVC gọi `P: POST /payments` cho S-PG2.
  3. `PGSIM` gửi IPN thành công cho TX-PEND2.
  4. Chạy PendingQueryScheduler.
- **Mong đợi** Bước 1: hộp hiện "Đang có 1 giao dịch chờ thanh toán…"; API trả `200`, `status = SUSPENDED`. Bước 2 trả `503` ERR-19-017 có `Retry-After`, không ghi giao dịch. Bước 3: ST: `PENDING` → `SUCCEEDED`; WH: `transaction.succeeded`. Bước 4 vẫn truy vấn NCC tạm dừng. KT: có (`PROVIDER_SUSPEND` kèm lý do). EVT: `provider.suspended`.

#### TC-19-077 · Mở lại NCC cần kiểm tra kết nối trong một giờ <!--k:pv-resume-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-006 · API-19-014, 009 · ERR-19-021
- **Tiền điều kiện / dữ liệu** PV-PG2 `SUSPENDED` từ TC-19-076; lần kiểm tra kết nối cuối cách 2 giờ.
- **Bước**
  1. `POST /providers/{id}/resumptions` với lý do.
  2. Chạy kiểm tra kết nối `PRODUCTION` đạt; gọi lại bước 1.
- **Mong đợi** Bước 1 trả `409` ERR-19-021 với `detail` "chưa có kiểm tra kết nối đạt trong 1 giờ"; `disabledReasons.RESUME` cùng nội dung. Bước 2 trả `200`, `status = ACTIVE`. KT: có (`PROVIDER_RESUME`).

#### TC-19-078 · Ngừng hẳn NCC có phê duyệt sau khi hết việc dở <!--k:pv-retire-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-010 · BR-19-027, 011 · API-19-012, 050 · LGC-PAY-005
- **Tiền điều kiện / dữ liệu** PV-PG2 `SUSPENDED`, không còn giao dịch `CREATED`/`PENDING`, yêu cầu hoàn mở, phiên đối soát chưa chốt.
- **Bước**
  1. U-ADM1 gửi `{"action":"RETIRE"}` kèm lý do.
  2. U-APR1 duyệt.
- **Mong đợi** Bước 1 trả `201`. Bước 2: `status = RETIRED`, `retiredAt` có giá trị; dịch vụ của NCC không kích hoạt được; NCC vẫn hiện ở UI-19-02 nhóm "Kênh đã ngừng". EVT: `provider.retired`.

#### TC-19-079 · Ngừng hẳn khi còn việc dở, xóa NCC đã có giao dịch <!--k:pv-retire-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-010 · BR-19-027 · API-19-005, 012 · ERR-19-036, 037
- **Tiền điều kiện / dữ liệu** PV-PG (có giao dịch `PENDING` và phiên đối soát `IN_REVIEW`).
- **Bước**
  1. Gửi đề nghị `RETIRE` cho PV-PG.
  2. Gọi `DELETE /providers/{PV-PG}`.
- **Mong đợi** Bước 1 trả `409` ERR-19-036 với `pendingTransactions`, `openSessions` đúng số. Bước 2 trả `409` ERR-19-037. Dữ liệu không đổi.

#### TC-19-080 · Xóa cứng NCC Nháp chưa có giao dịch <!--k:pv-delete-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-010 · API-19-005 · UI-19-03 · LGC-PAY-005
- **Tiền điều kiện / dữ liệu** U-ADM1; NCC `MOCK3` từ TC-19-001.
- **Bước**
  1. Trên UI-19-03 chọn "Xóa", gõ lại mã, xác nhận.
  2. `GET /providers/{id}`.
- **Mong đợi** Bước 1 trả `204`. Bước 2: 404-ẩn. Tham chiếu bí mật đã gắn được gỡ khỏi `provider_credential`; `callback_route` không còn `connectionKey` của NCC. KT: có (`PROVIDER_DELETE`).

#### TC-19-081 · Chuyển trạng thái NCC trái máy trạng thái <!--k:pv-lifecycle-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API, UT
- **Truy vết** FR-19-005, 006, 010 · API-19-012, 013, 014 · ERR-19-021
- **Tiền điều kiện / dữ liệu** NCC ở từng trạng thái `DRAFT`, `PENDING_ACTIVATION`, `ACTIVE`, `SUSPENDED`, `RETIRED`.
- **Bước**
  1. Với mỗi trạng thái, gọi mọi thao tác vòng đời không có trong khung §7.1 (ví dụ tạm dừng NCC `DRAFT`, mở lại NCC `ACTIVE`, gửi `ACTIVATE` cho NCC `RETIRED`).
- **Mong đợi** Mọi lời gọi trả `409` ERR-19-021, `detail` nêu trạng thái hiện tại; `allowedActions` của bản ghi không chứa thao tác đó. UT phủ đủ ma trận 5 × 6.

### TS-19-05 · Tra cứu và cập nhật NCC

**Mục tiêu.** Xác nhận danh sách, tìm kiếm, chi tiết, chỉnh sửa NCC giữ đúng các trường của hệ cũ, và thay đổi kết nối của NCC đang thu tiền chỉ có hiệu lực sau khi kiểm tra đạt.

**Phủ.** FR-19-007, 008, 009, 069; UC-19-05; API-19-001, 003, 004, 091, 092; UI-19-03, 04; ERR-19-021, 045; BR-19-026; LGC-PAY-002, 003, 004, 006.

#### TC-19-101 · Danh sách NCC có lọc, tìm, đếm theo trạng thái <!--k:pv-list-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-007 · API-19-001 · UI-19-03 · LGC-PAY-002, 006
- **Tiền điều kiện / dữ liệu** U-OPR1.
- **Bước**
  1. Mở UI-19-03.
  2. Gõ "pay" vào ô tìm.
  3. Lọc "Sức khỏe: Suy giảm" sau khi cho `PGSIM` lỗi 30% để PV-PG suy giảm.
- **Mong đợi** Bước 1: đủ cột của hệ cũ (tên, ngày hiệu lực, đầu mối, tình trạng) cộng sức khỏe, số dịch vụ; facet đếm theo trạng thái đúng. Bước 2 chỉ còn PV-PG, PV-SUS. Bước 3 chỉ PV-PG. URL giữ `q`, `suc-khoe`. U-OPR1 không thấy nút "Thêm".

#### TC-19-102 · Chi tiết NCC có đủ thông tin hệ cũ và biểu đồ 30 ngày <!--k:pv-detail-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-008 · API-19-003 · UI-19-04 · LGC-PAY-003
- **Tiền điều kiện / dữ liệu** U-AUD1; PV-PG có giao dịch 30 ngày.
- **Bước**
  1. Mở UI-19-04 của PV-PG, tab "Thông tin".
  2. U-AUD1 xem `callbackUrls`.
- **Mong đợi** Bước 1: ngày bắt đầu, đầu mối, điện thoại (che giữa), tình trạng, số dịch vụ, biểu đồ giao dịch theo ngày 30 điểm khớp số đếm từ `payment_stats_daily`. Bước 2: đường callback hiện dạng che `…/paygov/••••••••/ipn`, không có nút "Sao chép đường dẫn đầy đủ" (cần `provider-write`).


#### TC-19-107 · Danh sách, chi tiết NCC: tham số sai, không có quyền, tỉnh khác <!--k:pv-read-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-007, 008 · API-19-001, 003 · ERR-19-001, 046, 020
- **Tiền điều kiện / dữ liệu** U-OPR1; U-SEC1 (không có `provider-read`); U-ADM1-T99.
- **Bước**
  1. `GET /providers?q=p` (1 ký tự); `?status=FOO`; `?limit=500`.
  2. U-SEC1 gọi API-19-001.
  3. U-ADM1-T99 gọi API-19-003 với mã PV-PG.
- **Mong đợi** Bước 1: mỗi trường hợp `400` ERR-19-001 chỉ đúng tham số. Bước 2: 403-PQ. Bước 3: 404-ẩn.
#### TC-19-103 · Sửa NCC Nháp áp dụng ngay, sửa trường mô tả NCC đang hoạt động <!--k:pv-edit-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-009 · API-19-004 · UI-19-05 · LGC-PAY-004
- **Tiền điều kiện / dữ liệu** U-ADM1; PV-NEW `DRAFT`; PV-PG `ACTIVE`.
- **Bước**
  1. `PATCH /providers/{PV-NEW}` đổi `sandboxBaseUrl` với `If-Match`.
  2. `PATCH /providers/{PV-PG}` đổi `name`, `techContact`.
- **Mong đợi** Cả hai trả `200` với `ETag` mới; thay đổi có hiệu lực ngay; `pendingChange = null`. KT: có (`PROVIDER_UPDATE` với giá trị trước, sau).

#### TC-19-104 · Đổi địa chỉ kết nối NCC đang thu tiền chỉ áp dụng sau kiểm tra <!--k:pv-edit-pending-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-19-009 · BR-19-026 · API-19-004, 009 · UI-19-04, 05
- **Tiền điều kiện / dữ liệu** U-ADM1; PV-PG `ACTIVE`; `PGSIM` có địa chỉ thứ hai `https://pgsim2.test`.
- **Bước**
  1. `PATCH /providers/{PV-PG}` đổi `productionBaseUrl` sang `https://pgsim2.test`.
  2. C-DVC tạo giao dịch S-HT.
  3. Cho `pgsim2` lỗi TLS; chạy kiểm tra kết nối `PRODUCTION`.
  4. Sửa `pgsim2`; chạy lại kiểm tra.
  5. C-DVC tạo giao dịch S-HT.
- **Mong đợi** Bước 1 trả `200` có `pendingChange` chứa giá trị cũ, mới; UI-19-04 hiện dải "Có thay đổi kết nối chờ áp dụng". Bước 2 gọi địa chỉ cũ (kiểm `integration_log`). Bước 3 `FAILED`, `pendingChange` giữ nguyên. Bước 4 `PASSED`, `pendingChange = null`, địa chỉ mới có hiệu lực. Bước 5 gọi `pgsim2`. KT: có (`PROVIDER_CHANGE_PENDING`, `PROVIDER_CHANGE_APPLIED`).

#### TC-19-105 · Sửa NCC sai trạng thái, sai phiên bản <!--k:pv-edit-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-009 · API-19-004 · ERR-19-021, 045 · UI-19-05
- **Tiền điều kiện / dữ liệu** U-ADM1, U-ADM2; NCC `PENDING_ACTIVATION`; PV-PG.
- **Bước**
  1. `PATCH` NCC `PENDING_ACTIVATION`.
  2. U-ADM1 và U-ADM2 cùng mở UI-19-05 của PV-PG; U-ADM2 lưu trước; U-ADM1 lưu sau.
  3. `PATCH` PV-PG không có `If-Match`.
- **Mong đợi** Bước 1 trả `409` ERR-19-021. Bước 2: U-ADM1 nhận `412` ERR-19-045, màn mở hộp "Dữ liệu đã thay đổi" hai cột. Bước 3 trả `428` hoặc `412` ERR-19-045 theo D03-04-PH19 §1.

#### TC-19-106 · Đề nghị đổi bảng ánh xạ mã kết quả <!--k:map-change-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-069 · BR-19-011, 015 · API-19-091, 092, 050 · UI-19-04 · ERR-19-033
- **Tiền điều kiện / dữ liệu** U-ADM1, U-APR1; PV-PG bảng ánh xạ v1; IPN cách ly `UNMAPPED_CODE` mã `77` trong 30 ngày.
- **Bước**
  1. `GET /providers/{PV-PG}/result-mappings`.
  2. Trên tab "Ánh xạ mã kết quả", bấm "Thêm vào đề nghị" cho mã `77`, chọn kết quả `SUCCEEDED`, gửi.
  3. U-ADM1 tự duyệt.
  4. U-APR1 duyệt.
  5. `POST C: …/ipn` có mã `77` cho giao dịch `PENDING`.
- **Mong đợi** Bước 1: v1 `ACTIVE`, khối mã lạ có `77`. Bước 2: màn hiện cảnh báo kết quả `SUCCEEDED`; API trả `201` đề nghị `RESULT_MAPPING_CHANGE`. Bước 3 trả `403` ERR-19-033. Bước 4: v2 `ACTIVE`, v1 `RETIRED` (không xóa). Bước 5: ST: `PENDING` → `SUCCEEDED` với `mappingVersion = 2`.

### TS-19-06 · Giám sát sức khỏe và xoay khóa

**Mục tiêu.** Xác nhận cảnh báo lỗi kết nối của hệ cũ thành giám sát tự động có mạch ngắt, và xoay khóa không làm gián đoạn xác minh IPN.

**Phủ.** FR-19-011, 012; UC-19-06; API-19-003, 008; UI-19-01, 02, 04; ERR-19-017; BR-19-013, 026; NFR-19-012; LGC-PAY-009.

#### TC-19-126 · Sức khỏe chuyển Suy giảm, Mất kết nối và cảnh báo <!--k:health-degrade-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, E2E
- **Truy vết** FR-19-011, 059 · API-19-003, 080 · UI-19-01, 02 · LGC-PAY-009
- **Tiền điều kiện / dữ liệu** PV-PG `HEALTHY`; `19.provider.health-interval-seconds = 15`.
- **Bước**
  1. Cho `PGSIM` lỗi 30% lời gọi trong 5 phút.
  2. Cho `PGSIM` lỗi 100% trong 2 phút.
  3. Khôi phục `PGSIM`.
- **Mong đợi** Bước 1: `healthStatus = DEGRADED`; UI-19-01 hiện dải cảnh báo vàng; PH-13 nhận cảnh báo `PaymentProviderDegraded`. Bước 2: `DOWN`, cảnh báo đỏ, huy hiệu menu "Kênh thanh toán" tăng. Bước 3: về `HEALTHY` trong ≤ 2 chu kỳ; cảnh báo tự đóng. Chỉ một bản sao `worker` chạy kiểm tra (khóa `t68:payment:health-leader`).

#### TC-19-127 · Mạch ngắt mở từ chối tạo giao dịch trước khi ghi CSDL <!--k:circuit-open-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-19-011, 024 · BR-19-013 · NFR-19-012 · API-19-101 · ERR-19-017
- **Tiền điều kiện / dữ liệu** C-DVC; `19.provider.circuit-error-rate = 50`.
- **Bước**
  1. Cho `PGSIM` trả 5xx cho khởi tạo; gửi 20 yêu cầu tạo giao dịch.
  2. Đếm dòng `payment_transaction` mới sau khi mạch mở.
  3. Chờ 30 giây (nửa mở), khôi phục `PGSIM`, gửi một yêu cầu.
- **Mong đợi** Bước 1: các yêu cầu đầu trả `504` ERR-19-019 (giao dịch `CREATED` `initUncertain`); sau khi vượt ngưỡng trả `503` ERR-19-017 có `Retry-After`. Bước 2: không có dòng mới cho yêu cầu bị mạch chặn. Bước 3: `201`, mạch về `CLOSED`. IPN và truy vấn vẫn chạy khi mạch mở.

#### TC-19-128 · Xoay khóa xác minh, chấp nhận khóa cũ và mới trong chuyển tiếp <!--k:cred-rotate-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, IT
- **Truy vết** FR-19-012 · BR-19-026 · API-19-008, 201 · UI-19-04
- **Tiền điều kiện / dữ liệu** U-SEC1; PV-PG `VERIFY_CERT` A `ACTIVE`; chứng thư B trong OpenBao.
- **Bước**
  1. `POST /providers/{PV-PG}/credentials/PRODUCTION/rotations` với tham chiếu B, chuyển tiếp 7 ngày.
  2. `PGSIM` gửi IPN ký bằng A; rồi IPN ký bằng B.
  3. Tiến đồng hồ 7 ngày; `PGSIM` gửi IPN ký bằng A.
- **Mong đợi** Bước 1 trả `200`; danh sách có A `ACTIVE`, B `NEXT`. Bước 2: cả hai IPN `VERIFIED`. Bước 3: A `RETIRED`, B `ACTIVE`; IPN ký bằng A `BAD_SIGNATURE` (ERR-19-024), không đổi trạng thái giao dịch. KT: có (`CREDENTIAL_ROTATE`). Phát hành Đ2b.

#### TC-19-129 · Nhắc hạn khóa, chứng thư sắp hết hạn <!--k:cred-expiry-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** IT, E2E
- **Truy vết** FR-19-011, 012, 059 · UI-19-02, 03 · BR-19-010
- **Tiền điều kiện / dữ liệu** PV-PG chứng thư còn 31 ngày.
- **Bước**
  1. Chạy CredentialExpiryJob; tiến đồng hồ 1 ngày, chạy lại; tiến tới còn 7 ngày, chạy lại.
  2. Mở UI-19-02.
- **Mong đợi** Bước 1: lúc còn 30 ngày có cảnh báo `WARN` tới PH-13 và người có `credential-manage`; lúc còn 7 ngày `CRITICAL`. Bước 2: thẻ PayGov hiện "Chứng thư ký hết hạn sau 7 ngày" màu đỏ có chữ.

### TS-19-07 · Quản lý nhóm dịch vụ

**Mục tiêu.** Xác nhận quản lý nhóm dịch vụ ("lĩnh vực giao dịch" của hệ cũ) có kiểm tra mã danh mục PH-07.

**Phủ.** FR-19-013, 016; UC-19-07; API-19-015…019, 028; UI-19-07, 08; ERR-19-037, 038, 039; LGC-PAY-022.

#### TC-19-151 · Thêm, sửa, xóa nhóm dịch vụ <!--k:grp-crud-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-013 · API-19-015, 016, 017, 018, 019, 028 · UI-19-07, 08 · LGC-PAY-022
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. Trên UI-19-07 bấm "Thêm nhóm", nhập mã `G-YT`, tên "Y tế", chọn lĩnh vực từ ô tra PH-07, lưu.
  2. Sửa tên, đổi thứ tự bằng `Alt+↓`.
  3. Xóa `G-YT`.
- **Mong đợi** Bước 1: ô tra gọi API-19-028 có kết quả trong ≤ 500 ms; `POST /service-groups` trả `201`. Bước 2 trả `200`. Bước 3 trả `204` (xóa mềm); nhóm không còn trong bộ lọc lĩnh vực ở UI-19-14. KT: có cho cả ba.

#### TC-19-152 · Xóa nhóm còn dịch vụ, mã lĩnh vực hết hiệu lực, trùng mã <!--k:grp-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-013, 016 · API-19-016, 019 · ERR-19-037, 038, 039
- **Tiền điều kiện / dữ liệu** U-ADM1; G-TP có S-HT; mã lĩnh vực `LV-OLD` hết hiệu lực ở PH-07.
- **Bước**
  1. `DELETE /service-groups/{G-TP}`.
  2. `POST /service-groups` với `sectorCode = LV-OLD`.
  3. `POST /service-groups` với `code = G-TP`.
  4. Dừng PH-07 giả lập; `POST /service-groups` với mã lĩnh vực hợp lệ.
- **Mong đợi** Bước 1 trả `409` ERR-19-037. Bước 2, 4 trả `422` ERR-19-039 (bước 4: "chưa kiểm tra được với danh mục dùng chung"). Bước 3 trả `409` ERR-19-038.

### TS-19-08 · Quản lý dịch vụ thanh toán

**Mục tiêu.** Xác nhận quản lý dịch vụ giữ chức năng hệ cũ và vòng đời dịch vụ tôn trọng trạng thái NCC và mã danh mục.

**Phủ.** FR-19-014, 015, 016; UC-19-08; API-19-020…027; UI-19-09, 10; ERR-19-021, 036, 037, 039; BR-19-008, 009, 027; LGC-PAY-022.

#### TC-19-176 · Thêm dịch vụ ở trạng thái Nháp <!--k:sv-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-014 · BR-19-008 · API-19-021, 022 · UI-19-10 · LGC-PAY-022
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. Trên UI-19-09 bấm "Thêm dịch vụ", nhập mã `S-YT`, nhóm G-TP, NCC PV-PG, loại khoản thu, cơ quan thu, khoảng 20.000–2.000.000 ₫, lưu.
- **Mong đợi** `POST /services` trả `201`, `status = DRAFT`, `catalogInvalid = false`; ô số tiền hiển thị "2.000.000" và dòng đọc bằng chữ. KT: có (`SERVICE_CREATE`).

#### TC-19-177 · Dịch vụ sai khoảng tiền, sai mã danh mục <!--k:sv-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-014, 016 · BR-19-001 · API-19-021 · ERR-19-001, 039
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. `POST /services` với `minAmount = 0`.
  2. `minAmount = 50000`, `maxAmount = 10000`.
  3. `maxAmount = 1000000000000` (vượt trần).
  4. `feeTypeCode` không tồn tại ở PH-07.
- **Mong đợi** Bước 1–3 trả `400` ERR-19-001 chỉ đúng trường. Bước 4 trả `422` ERR-19-039.

#### TC-19-178 · Kích hoạt, tạm dừng, mở lại, ngừng hẳn dịch vụ <!--k:sv-lifecycle-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-015 · BR-19-009, 027 · API-19-025, 026, 027 · UI-19-09
- **Tiền điều kiện / dữ liệu** U-ADM1; `S-YT` từ TC-19-176 đã có `beneficiaryRef`; C-DVC được gán `S-YT`.
- **Bước**
  1. `POST /services/{S-YT}/activations`.
  2. C-DVC tạo giao dịch `S-YT`.
  3. `POST …/suspensions` có lý do; C-DVC tạo giao dịch.
  4. `POST …/activations`; rồi `POST …/retirements` khi không còn giao dịch dở.
- **Mong đợi** Bước 1: `ACTIVE`. Bước 2: `201`. Bước 3: `SUSPENDED`; tạo giao dịch trả `422` ERR-19-008. Bước 4: `ACTIVE` rồi `RETIRED`. EVT: `service.activated`, `service.suspended`, `service.retired`.

#### TC-19-179 · Kích hoạt khi NCC chưa hoạt động, thiếu tham chiếu thụ hưởng, mã danh mục hết hiệu lực <!--k:sv-activate-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-015, 016 · BR-19-009 · API-19-025 · ERR-19-021, 039 · UI-19-09, 10
- **Tiền điều kiện / dữ liệu** Dịch vụ A gắn PV-NEW (`DRAFT`); dịch vụ B thiếu `beneficiaryRef`; dịch vụ C có `collectingAgencyCode` vừa hết hiệu lực ở PH-07.
- **Bước**
  1. Kích hoạt A, B, C.
  2. PH-07 phát sự kiện `catalog.item.expired` cho mã của S-XD; C-DVC tạo giao dịch S-XD.
  3. Mở UI-19-10 của S-XD.
- **Mong đợi** Bước 1: A, B trả `409` ERR-19-021 với lý do cụ thể; C trả `422` ERR-19-039. Bước 2: S-XD có `catalogInvalid = true`; tạo giao dịch trả `422` ERR-19-008. Bước 3: dải đỏ "Mã … đã hết hiệu lực… Chọn mã thay thế".

#### TC-19-180 · Ngừng hẳn, xóa dịch vụ đã có giao dịch <!--k:sv-retire-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-015 · BR-19-027 · API-19-024, 027 · ERR-19-036, 037
- **Tiền điều kiện / dữ liệu** S-XD có TX-PEND.
- **Bước**
  1. `POST /services/{S-XD}/retirements`.
  2. `DELETE /services/{S-XD}`.
- **Mong đợi** Bước 1 trả `409` ERR-19-036. Bước 2 trả `409` ERR-19-037.

### TS-19-09 · Đăng ký và phê duyệt đối tác

**Mục tiêu.** Xác nhận đối tác (HTTT được thu tiền) chỉ được đưa vào dùng và chấm dứt qua phê duyệt, và đối tác tạm dừng không tạo được giao dịch mới nhưng vẫn truy vấn được.

**Phủ.** FR-19-017, 018; UC-19-09; API-19-029…035, 050; UI-19-11, 12, 13; ERR-19-005, 021, 033; BR-19-011; LGC-PAY-022.

#### TC-19-201 · Đăng ký đối tác Nháp <!--k:pt-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-017 · API-19-030, 031 · UI-19-11, 12 · LGC-PAY-022
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. Trên UI-19-11 bấm "Đăng ký đối tác", nhập mã `P-YT`, tên, cơ quan chủ quản, một địa chỉ quay về `https://yt.t68.test/ket-qua`, đầu mối kỹ thuật; lưu.
- **Mong đợi** `POST /partners` trả `201`, `status = DRAFT`, `routingMode = DATAHUB` (mặc định cho đối tác mới, không có ở hệ cũ); `disabledReasons.SUBMIT_ONBOARD` nêu "chưa gắn HTTT thành viên", "chưa gán dịch vụ". KT: có.


#### TC-19-207 · Hồ sơ đối tác sai, trùng mã, sửa khi đã chấm dứt <!--k:pt-profile-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-017 · API-19-030, 032 · ERR-19-038, 039, 016, 021, 045
- **Tiền điều kiện / dữ liệu** U-ADM1; P-DVC đã có; một đối tác `TERMINATED`.
- **Bước**
  1. Tạo đối tác mã `P-DVC`.
  2. Tạo với `agencyCode` không có trong danh mục PH-07.
  3. Tạo với địa chỉ quay về `http://yt.t68.test` (không `https`).
  4. Sửa đối tác `TERMINATED`.
  5. Sửa P-DVC với `If-Match` cũ.
- **Mong đợi** Bước 1 trả `409` ERR-19-038. Bước 2 trả `422` ERR-19-039. Bước 3 trả `422` ERR-19-016. Bước 4 trả `409` ERR-19-021. Bước 5 trả `412` ERR-19-045.
#### TC-19-202 · Gửi duyệt và duyệt đối tác <!--k:pt-onboard-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-018 · BR-19-011 · API-19-033, 050 · UI-19-12, 13
- **Tiền điều kiện / dữ liệu** `P-YT` đã gắn HTTT `HT-0099` và gán S-HT; U-ADM1, U-APR1.
- **Bước**
  1. U-ADM1 bấm "Gửi duyệt".
  2. U-APR1 duyệt ở UI-19-13.
- **Mong đợi** Bước 1: `status = PENDING_APPROVAL`, đề nghị `PARTNER_ONBOARD`. Bước 2: `status = ACTIVE`. EVT: `partner.activated`.

#### TC-19-203 · Gửi duyệt khi thiếu điều kiện, người lập tự duyệt <!--k:pt-onboard-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-018 · BR-19-011 · API-19-033, 050 · ERR-19-021, 033
- **Tiền điều kiện / dữ liệu** P-NEW (thiếu HTTT, chưa gán dịch vụ); U-AA1 lập đề nghị cho bản sao đủ điều kiện.
- **Bước**
  1. Gửi duyệt P-NEW.
  2. U-AA1 duyệt đề nghị mình lập.
- **Mong đợi** Bước 1 trả `409` ERR-19-021 với hai mục thiếu. Bước 2 trả `403` ERR-19-033.

#### TC-19-204 · Tạm dừng đối tác: chặn tạo mới, vẫn truy vấn và nhận webhook <!--k:pt-suspend-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-018 · API-19-034, 035, 101, 102 · ERR-19-005
- **Tiền điều kiện / dữ liệu** U-ADM1; bản sao P-DVC tên P-DVC2 có TX-PEND3 `PENDING`; C-DVC2.
- **Bước**
  1. Tạm dừng P-DVC2 có lý do.
  2. C-DVC2 `P: POST /payments`.
  3. C-DVC2 `P: GET /payments/{TX-PEND3}`.
  4. `PGSIM` gửi IPN thành công cho TX-PEND3.
  5. Mở lại P-DVC2.
- **Mong đợi** Bước 2 trả `403` ERR-19-005. Bước 3 trả `200`. Bước 4: ST: `PENDING` → `SUCCEEDED`; WH: `transaction.succeeded` vẫn gửi tới P-DVC2. Bước 5: `ACTIVE`, tạo giao dịch được. KT: có cho bước 1, 5.

#### TC-19-205 · Tạm dừng, mở lại sai trạng thái và thiếu quyền <!--k:pt-suspend-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-018 · API-19-034, 035 · ERR-19-021, 046, 001
- **Tiền điều kiện / dữ liệu** P-NEW `DRAFT`; P-SUS; U-OPR1.
- **Bước**
  1. Tạm dừng P-NEW.
  2. Mở lại P-SUS không có lý do.
  3. U-OPR1 tạm dừng P-DVC.
- **Mong đợi** Bước 1 trả `409` ERR-19-021. Bước 2 trả `400` ERR-19-001. Bước 3 trả 403-PQ.

#### TC-19-206 · Chấm dứt đối tác thu hồi mọi client <!--k:pt-terminate-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-018, 019 · BR-19-011 · API-19-033, 050, 036
- **Tiền điều kiện / dữ liệu** `P-YT` `ACTIVE` có hai client; U-ADM1, U-APR1.
- **Bước**
  1. U-ADM1 gửi `{"action":"TERMINATE"}`.
  2. U-APR1 duyệt.
  3. Client của `P-YT` xin token và gọi `P: GET /services`.
- **Mong đợi** Bước 2: `status = TERMINATED`; cả hai client bị thu hồi ở PH-12. Bước 3: không lấy được token mới; token cũ bị từ chối trong ≤ 60 giây. Đối tác `TERMINATED` không mở lại được (không có `RESUME` trong `allowedActions`).

### TS-19-10 · Client, dịch vụ được gán, webhook đối tác

**Mục tiêu.** Xác nhận cấp, thu hồi client máy-máy, hạn mức theo dịch vụ, và đầu nhận webhook an toàn (chỉ HTTPS, không trỏ mạng nội bộ, bí mật hiện một lần).

**Phủ.** FR-19-019, 020, 021; UC-19-10; API-19-036…046; UI-19-12; ERR-19-012, 013, 044; NFR-19-019, 021.

#### TC-19-226 · Cấp client mTLS và private_key_jwt <!--k:client-issue-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-019 · NFR-19-019 · API-19-036, 037 · UI-19-12
- **Tiền điều kiện / dữ liệu** U-ADM1; P-DVC; một CSR và một JWKS URL thử.
- **Bước**
  1. Tab "Client": cấp client `MTLS` từ CSR.
  2. Cấp client `PRIVATE_KEY_JWT` từ JWKS URL.
  3. Dùng client bước 1 xin token `client_credentials` ràng buộc chứng thư, gọi `P: GET /services`.
- **Mong đợi** Bước 1, 2 trả `201`; hộp "Thông tin kết nối" hiện một lần; hệ thống không lưu khóa riêng. Bước 3: token sống ≤ 5 phút, có `cnf.x5t#S256`; gọi trả `200` với S-HT, S-XD và hạn mức còn lại. KT: có (`PARTNER_CLIENT_ISSUE`).

#### TC-19-227 · Thu hồi client có hiệu lực trong 60 giây <!--k:client-revoke-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-019 · API-19-038, 101 · NFR-19-019
- **Tiền điều kiện / dữ liệu** Client `mTLS` từ TC-19-226 đang có token còn hạn 4 phút.
- **Bước**
  1. `DELETE /partners/{P-DVC}/clients/{clientId}` có lý do.
  2. Sau 60 giây, gọi `P: POST /payments` bằng token cũ.
  3. Gọi bằng token cũ nhưng chứng thư khác (token bị đánh cắp).
- **Mong đợi** Bước 2 trả `401` từ PH-03. Bước 3 trả `401` (ràng buộc chứng thư RFC 8705) cả trước khi thu hồi.

#### TC-19-228 · Gán dịch vụ và hạn mức, chặn khi vượt <!--k:grant-limit-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-020 · BR-19-005 · API-19-040, 101, 108 · ERR-19-012, 013
- **Tiền điều kiện / dữ liệu** U-ADM1; bản sao P-DVC tên P-LIM gán S-XD với `maxAmountPerTxn = 1.000.000`, `dailyTxnLimit = 3`, `dailyAmountLimit = 2.000.000`; C-LIM.
- **Bước**
  1. C-LIM tạo giao dịch 1.000.001 ₫.
  2. Tạo ba giao dịch 600.000 ₫.
  3. Tạo giao dịch thứ tư 100.000 ₫.
  4. Gọi `P: GET /services`.
  5. Tiến đồng hồ qua 00:00 giờ Việt Nam; tạo lại.
- **Mong đợi** Bước 1 trả `422` ERR-19-012. Bước 2 trả `201` cả ba. Bước 3 trả `422` ERR-19-013. Bước 4: `usedToday.count = 3`, `amount = 1.800.000`. Bước 5 trả `201` (bộ đếm `t68:payment:quota:…:{yyyyMMdd}` theo ngày VN). Giao dịch `FAILED` do NCC từ chối không tính vào hạn mức (BR-19-005).

#### TC-19-229 · Thêm đầu nhận webhook, gửi thử, xoay bí mật <!--k:wh-endpoint-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-021 · NFR-19-021 · API-19-043, 045, 046 · UI-19-12
- **Tiền điều kiện / dữ liệu** U-ADM1; P-DVC; đầu nhận giả lập `https://dvc.t68.test/hook2` kiểm chữ ký.
- **Bước**
  1. Thêm đầu nhận với 8 loại sự kiện.
  2. Bấm "Gửi thử".
  3. Bấm "Xoay bí mật"; gửi thử lại trong 24 giờ chuyển tiếp.
- **Mong đợi** Bước 1 trả `201` kèm `secret` chỉ một lần; mở lại màn không thấy bí mật. Bước 2: đầu nhận nhận sự kiện mẫu, chữ ký `v1` hợp lệ với bí mật cũ; màn hiện mã HTTP, thời lượng. Bước 3: bí mật mới hiện một lần; trong chuyển tiếp tiêu đề chữ ký chứa hai giá trị `v1` (bí mật cũ và mới).

#### TC-19-230 · Đầu nhận webhook không an toàn <!--k:wh-endpoint-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-021 · API-19-043, 044 · ERR-19-044
- **Tiền điều kiện / dữ liệu** U-ADM1.
- **Bước**
  1. Thêm đầu nhận `http://dvc.t68.test/hook`.
  2. `https://10.0.0.5/hook`, `https://localhost/hook`, `https://169.254.169.254/latest`.
  3. `https://rebind.test/hook` (tên miền phân giải ra địa chỉ riêng lúc gửi).
- **Mong đợi** Bước 1, 2 trả `422` ERR-19-044. Bước 3: lưu được nhưng lúc gửi bộ gửi phân giải lại, phát hiện địa chỉ riêng, đánh lượt gửi `EXHAUSTED` với lý do "địa chỉ nội bộ", không mở kết nối (kiểm bằng log egress).

### TS-19-11 · Tạo giao dịch thanh toán

**Mục tiêu.** Xác nhận tạo giao dịch kiểm hợp lệ đúng thứ tự BR-19-004, chống trùng theo `Idempotency-Key` và mã đơn hàng, và xử lý đúng khi NCC từ chối hoặc không trả lời. Đây là thay thế "nhận yêu cầu thanh toán, gửi yêu cầu thanh toán" của hệ cũ.

**Phủ.** FR-19-022, 023, 024, 028, 033, 034; UC-19-11; API-19-101, 102; ERR-19-002…019, 049; BR-19-001…007, 012; NFR-19-017; LGC-PAY-024, 011.

**Tiền điều kiện chung.** C-DVC; S-HT, S-XD; `PGSIM` trả lời bình thường trừ khi ghi khác.

#### TC-19-251 · Tạo giao dịch hợp lệ, nhận đường thanh toán <!--k:tx-create-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-19-022, 023, 024, 028 · BR-19-002, 003 · API-19-101 · LGC-PAY-024
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. `P: POST /payments` với `serviceCode = S-XD`, `amount = 1250000`, `partnerOrderId = TC19-251-1`, `returnUrl = https://dvc.t68.test/ket-qua`, người nộp giả, `Idempotency-Key` UUID.
  2. `GET /transactions/{id}/events` (quản trị).
- **Mong đợi** Bước 1 trả `201` với `transactionCode` dạng `T68yyMMdd` + 10 ký tự Base32 Crockford, `paymentUrl` của `PGSIM`, `expiresAt = createdAt + 15 phút`, `status = PENDING`. Bước 2: hai dòng `CREATED` (nguồn `PARTNER_API`), `PENDING` (nguồn `PROVIDER_INIT`). Họ tên, số định danh lưu mã hóa mức trường (kiểm cột `bytea` trong CSDL). EVT: `transaction.created`.

#### TC-19-252 · Thứ tự kiểm hợp lệ BR-19-004 dừng ở lỗi đầu tiên <!--k:tx-validate-order-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, UT
- **Truy vết** FR-19-022, 023 · BR-19-004, 001 · API-19-101 · ERR-19-049, 005, 006, 002, 001, 007, 008, 009, 014, 010, 011, 012, 013, 015, 016
- **Tiền điều kiện / dữ liệu** Mười lăm yêu cầu, mỗi yêu cầu sai đúng điều kiện thứ n và đồng thời sai mọi điều kiện sau n.
- **Bước**
  1. Gửi lần lượt: tenant T50; C-SUS; C-LEG; thiếu `Idempotency-Key`; `amount = "1e6"`; dịch vụ không có; S-OFF; dịch vụ chưa gán; `currency = USD`; `amount = 0`; S-XD 5.000 ₫; S-XD 25.000.000 ₫; vượt ngày; trùng mã đơn hàng; `returnUrl` lạ.
- **Mong đợi** Mã lỗi theo đúng thứ tự: ERR-19-049, 005, 006, 002, 001, 007, 008, 009, 014, 010, 011, 012, 013, 015, 016. Không yêu cầu nào ghi `payment_transaction`. UT có bảng 15 dòng tương ứng.

#### TC-19-253 · Cùng Idempotency-Key, cùng nội dung trả lại kết quả cũ <!--k:tx-idem-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-19-033 · BR-19-006 · API-19-101
- **Tiền điều kiện / dữ liệu** Yêu cầu R1 từ TC-19-251.
- **Bước**
  1. Gửi lại R1 cùng khóa, cùng thân (đổi thứ tự trường JSON).
  2. Đếm giao dịch có `partnerOrderId = TC19-251-1`.
- **Mong đợi** Bước 1 trả `201` y hệt, tiêu đề `Idempotent-Replayed: true` (thân so bằng RFC 8785 nên đổi thứ tự trường vẫn khớp). Bước 2: 1. EVT: không thêm.

#### TC-19-254 · Idempotency-Key sai định dạng, khác nội dung, đang xử lý <!--k:tx-idem-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-19-033 · BR-19-006 · API-19-101 · ERR-19-002, 003, 004
- **Tiền điều kiện / dữ liệu** `PGSIM` trễ khởi tạo 3 giây.
- **Bước**
  1. Gửi khóa 10 ký tự.
  2. Gửi khóa K1 với thân A; sau khi xong gửi K1 với thân B.
  3. Gửi khóa K2 thân C, trong lúc đang chờ `PGSIM` gửi lại K2 thân C.
  4. Khách C-MC dùng lại K1 với thân A.
- **Mong đợi** Bước 1 trả `400` ERR-19-002. Bước 2 lần sau trả `422` ERR-19-003. Bước 3 lần sau trả `409` ERR-19-004 có `Retry-After`. Bước 4 trả `201` giao dịch mới (phạm vi khóa theo client).

#### TC-19-255 · Trùng mã đơn hàng và tạo lại sau khi giao dịch trước kết thúc không thành công <!--k:tx-order-dup-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, DB
- **Truy vết** FR-19-034 · BR-19-007 · API-19-101, 103 · ERR-19-015
- **Tiền điều kiện / dữ liệu** —
- **Bước**
  1. Tạo giao dịch mã đơn hàng `TC19-255` (khóa K3).
  2. Tạo lại `TC19-255` khóa K4.
  3. Cho giao dịch bước 1 `EXPIRED`; tạo lại `TC19-255` khóa K5.
  4. Gửi đồng thời 50 yêu cầu `TC19-256` với 50 khóa khác nhau.
  5. `P: GET /payments?partnerOrderId=TC19-255`.
- **Mong đợi** Bước 2 trả `409` ERR-19-015 với mã giao dịch hiện có. Bước 3 trả `201`. Bước 4: đúng 1 `201`, 49 `409` ERR-19-015 (bảng `transaction_order_guard`). Bước 5 trả hai lượt theo thời gian.

#### TC-19-256 · NCC từ chối khởi tạo <!--k:tx-init-reject-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-024 · BR-19-012, 005 · API-19-101 · ERR-19-018
- **Tiền điều kiện / dữ liệu** `PGSIM` trả mã `05` (ánh xạ `FAILED`).
- **Bước**
  1. Tạo giao dịch.
  2. Xem hạn mức ngày qua `P: GET /services`.
- **Mong đợi** Bước 1 trả `502` ERR-19-018 với `detail` mang lý do đã ánh xạ; ST: `CREATED` → `FAILED`; `providerResultCode = 05`. Bước 2: không tính giao dịch này. WH: `transaction.failed`.

#### TC-19-257 · Không xác định được kết quả khởi tạo <!--k:tx-init-uncertain-->
- **Loại** Âm, Biên · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-19-024, 036 · BR-19-012, 016 · API-19-101, 102 · ERR-19-019
- **Tiền điều kiện / dữ liệu** `PGSIM` ghi nhận khởi tạo nhưng không trả lời trong 10 giây.
- **Bước**
  1. Tạo giao dịch khóa K6.
  2. Gửi lại cùng K6.
  3. Chạy PendingQueryScheduler sau 2 phút; `PGSIM` trả "đã khởi tạo, chưa thanh toán".
- **Mong đợi** Bước 1 trả `504` ERR-19-019; giao dịch `CREATED` với `initUncertain = true`. Bước 2 trả lại đúng phản hồi `504` đã lưu (không gọi NCC lần hai). Bước 3: ST: `CREATED` → `PENDING`, `providerReference` có giá trị.

#### TC-19-258 · Số tiền lớn, biên và không dùng số thực <!--k:tx-amount-edge-->
- **Loại** Biên · **Ưu tiên** P2 · **Tự động** API, UT
- **Truy vết** FR-19-022 · BR-19-001 · NFR-19-017 · API-19-101
- **Tiền điều kiện / dữ liệu** Dịch vụ thử `S-MAX` khoảng 1 … 999.999.999.999 ₫, hạn mức đối tác không giới hạn.
- **Bước**
  1. Tạo giao dịch 999.999.999.999 ₫.
  2. Tạo giao dịch 1.000.000.000.000 ₫.
  3. Tạo giao dịch `amount = 1250000.5`.
  4. Xem giao dịch bước 1 ở UI-19-15 và trong tệp CSV xuất.
- **Mong đợi** Bước 1 trả `201`; giá trị lưu, trả, gửi NCC không sai một đồng (so chuỗi). Bước 2 trả `422` ERR-19-010. Bước 3 trả `400` ERR-19-001. Bước 4 hiện "999.999.999.999 ₫" đúng (không qua `Number` của JavaScript).

### TS-19-12 · Người nộp quay về

**Mục tiêu.** Xác nhận lượt quay về của người nộp chỉ để hiển thị, không bao giờ đổi trạng thái, và không thể bị lợi dụng để chuyển hướng mở.

**Phủ.** FR-19-025; UC-19-12; API-19-202, 205; UI-19-28; BR-19-014; NFR-19-021, 029; LGC-PAY-012, 024.

#### TC-19-276 · Quay về sau khi IPN thành công đã tới <!--k:return-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E
- **Truy vết** FR-19-025 · API-19-202 · UI-19-28 · LGC-PAY-012 · NFR-19-029
- **Tiền điều kiện / dữ liệu** Giao dịch `SUCCEEDED` mới nhận IPN; trình duyệt di động 360 × 740.
- **Bước**
  1. `PGSIM` chuyển người nộp về `C: GET /paygov/{connectionKey}/return` với tham số có chữ ký.
  2. Chờ 5 giây.
- **Mong đợi** Bước 1 trả `200` HTML: "Thanh toán thành công", số tiền, nội dung, mã giao dịch, không có họ tên, điện thoại. Bước 2: chuyển tới `returnUrl` kèm `transactionCode`, `status = SUCCEEDED`, `ts`, `sig`; `sig` xác minh được bằng bí mật webhook của P-DVC trên chuỗi `{transactionCode}.{status}.{ts}`. axe-core không có lỗi nghiêm trọng.

#### TC-19-277 · Quay về trước IPN: hiển thị đang xác nhận, không đổi trạng thái <!--k:return-pending-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-19-025, 036 · BR-19-014 · API-19-202, 205 · UI-19-28
- **Tiền điều kiện / dữ liệu** TX `PENDING`; `PGSIM` gắn mã kết quả "thành công" vào tham số quay về nhưng chưa gửi IPN.
- **Bước**
  1. Người nộp quay về.
  2. Trang thăm dò API-19-205 trong 20 giây.
  3. Đọc `transaction_event`, `next_poll_at`.
- **Mong đợi** Bước 1: "Đang xác nhận kết quả với ngân hàng". Bước 2: sau 20 giây hiện "Bạn không cần thanh toán lại…". Bước 3: ST: giữ `PENDING`; `next_poll_at` được đặt về hiện tại (truy vấn sớm). Không có webhook.

#### TC-19-278 · Tham số quay về bị sửa, chuyển hướng mở <!--k:return-tamper-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, ZAP
- **Truy vết** FR-19-025 · BR-19-014 · API-19-202 · NFR-19-020
- **Tiền điều kiện / dữ liệu** TX `PENDING`.
- **Bước**
  1. Sửa `responseCode` trong tham số rồi gọi.
  2. Thêm `&returnUrl=https://evil.test` và `&next=//evil.test`.
  3. Gọi với `connectionKey` không tồn tại.
- **Mong đợi** Bước 1 trả `400`, trang "Không xác nhận được kết quả", không chuyển tới đối tác; ghi sự kiện an ninh. Bước 2: tham số bị bỏ qua, địa chỉ chuyển về chỉ là `returnUrl` đã lưu. Bước 3 trả `404` trang lỗi chung, không lộ lý do.

### TS-19-13 · Nhận và xử lý IPN

**Mục tiêu.** Xác nhận IPN được xác minh, ghi hộp nhận, xử lý đúng một lần, cách ly khi bất thường, và giao dịch đổi trạng thái chỉ khi số tiền, tham chiếu khớp. Đây là thay thế "nhận kết quả thanh toán" và "lưu dữ liệu quá trình thanh toán" của hệ cũ.

**Phủ.** FR-19-028, 029, 030, 031; UC-19-13; API-19-201; ERR-19-024…028; BR-19-014, 015, 018; NFR-19-003, 020; LGC-PAY-010, 011, 012.

#### TC-19-301 · IPN thành công hợp lệ <!--k:ipn-ok-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, IT
- **Truy vết** FR-19-029, 030, 028, 060 · BR-19-015 · API-19-201 · LGC-PAY-010, 011, 012
- **Tiền điều kiện / dữ liệu** TX `PENDING` 1.250.000 ₫.
- **Bước**
  1. `PGSIM` gửi `C: POST /paygov/{connectionKey}/ipn` có chữ ký đúng, số tiền 1.250.000, mã `00`.
  2. Đọc `callback_inbox`, giao dịch, `outbox_event`.
- **Mong đợi** Bước 1 trả phản hồi thành công theo hợp đồng PayGov giả định trong p95 ≤ 200 ms. Bước 2: hộp nhận `VERIFIED`, `PROCESSED`, nguyên văn và `rawHash` lưu; ST: `PENDING` → `SUCCEEDED`, `paidAt` theo NCC, `sequence` tăng. EVT: `transaction.succeeded`. WH: `transaction.succeeded` trong p95 ≤ 5 s.

#### TC-19-302 · IPN thất bại <!--k:ipn-fail-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-030 · API-19-201
- **Tiền điều kiện / dữ liệu** TX `PENDING`.
- **Bước**
  1. `PGSIM` gửi IPN mã `24` (ánh xạ `FAILED`, "người nộp hủy").
- **Mong đợi** ST: `PENDING` → `FAILED`, `reasonCode`, `reasonMessage` theo bảng ánh xạ. WH: `transaction.failed`.

#### TC-19-303 · IPN lặp đúng nội dung, đồng thời <!--k:ipn-dup-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-19-030 · API-19-201 · AC-19-04
- **Tiền điều kiện / dữ liệu** TX `PENDING`.
- **Bước**
  1. Gửi cùng IPN 20 lần song song.
  2. Gửi lại IPN đó sau 1 giờ.
- **Mong đợi** Bước 1: mọi lượt nhận phản hồi thành công; một bản ghi `PROCESSED`, các bản còn lại `DUPLICATE`; ST: một lần `PENDING` → `SUCCEEDED`; một webhook. Bước 2: `DUPLICATE`, không đổi gì.

#### TC-19-304 · IPN sai số tiền, sai tham chiếu, không tìm thấy, mã chưa ánh xạ <!--k:ipn-quarantine-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-031 · BR-19-015 · API-19-201, 056 · ERR-19-028 · UI-19-16 · AC-19-05
- **Tiền điều kiện / dữ liệu** Bốn giao dịch `PENDING`.
- **Bước**
  1. IPN thành công số tiền 1.249.999 cho giao dịch 1.250.000.
  2. IPN có `providerReference` khác giá trị đã lưu.
  3. IPN cho mã giao dịch không có.
  4. IPN mã `99` chưa có trong bảng ánh xạ.
  5. Mở UI-19-16 lọc "Cần chú ý".
- **Mong đợi** Bước 1–4: NCC nhận phản hồi đã tiếp nhận; hộp nhận `QUARANTINED` với lý do `AMOUNT_MISMATCH`, `REF_MISMATCH`, `NOT_FOUND`, `UNMAPPED_CODE`; ST: giữ `PENDING`; bước 1 sinh chênh lệch `AMOUNT_MISMATCH`, bước 3 sinh `ORPHAN_CALLBACK`; cảnh báo PH-13. Bước 5 hiện đủ bốn dòng với nhãn lý do.

#### TC-19-305 · IPN thành công cho giao dịch đã hủy hoặc hết hạn (thanh toán muộn) <!--k:ipn-late-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-031 · BR-19-018 · API-19-201 · OQ-19-23
- **Tiền điều kiện / dữ liệu** TX-EXP; một giao dịch `CANCELLED`.
- **Bước**
  1. `PGSIM` gửi IPN thành công hợp lệ cho từng giao dịch.
- **Mong đợi** ST: `EXPIRED` → `SUCCEEDED` và `CANCELLED` → `SUCCEEDED`, `latePaid = true`; mỗi giao dịch có chênh lệch `LATE_PAYMENT` `OPEN`. WH: `transaction.succeeded` có `latePaid = true`. UI-19-15 hiện huy hiệu "Thanh toán muộn".

#### TC-19-306 · IPN mâu thuẫn với trạng thái cuối khác <!--k:ipn-final-conflict-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-031 · BR-19-015 · API-19-201
- **Tiền điều kiện / dữ liệu** TX-OK `SUCCEEDED`; một giao dịch `FAILED`.
- **Bước**
  1. IPN thất bại cho TX-OK.
  2. IPN thành công cho giao dịch `FAILED`.
- **Mong đợi** Cả hai `QUARANTINED` lý do `CONFLICT_FINAL`; ST: giữ nguyên; sinh chênh lệch `STATUS_MISMATCH` để kế toán xử lý (không tự đảo trạng thái cuối).

### TS-19-14 · Hủy và hết hạn giao dịch

**Mục tiêu.** Xác nhận hủy chỉ áp dụng cho giao dịch chưa thanh toán, hết hạn chỉ sau truy vấn cuối, và kết quả đến muộn được ghi nhận.

**Phủ.** FR-19-026, 027; UC-19-14; API-19-104, 055; ERR-19-021; BR-19-017, 018, 019.

#### TC-19-326 · Đối tác và cán bộ hủy giao dịch chờ thanh toán <!--k:tx-cancel-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-026 · BR-19-019 · API-19-104, 055 · UI-19-15
- **Tiền điều kiện / dữ liệu** Hai giao dịch `PENDING`; U-OPR1; `PGSIM` không có API hủy.
- **Bước**
  1. C-DVC `P: POST /payments/{code}/cancellations` có khóa.
  2. U-OPR1 bấm "Hủy giao dịch" ở UI-19-15, nhập lý do, gõ lại 4 ký tự cuối.
- **Mong đợi** Cả hai: ST: `PENDING` → `CANCELLED` (hủy cục bộ). WH: `transaction.cancelled`. KT: có cho bước 2. Phát hành Đ2b.

#### TC-19-327 · Hủy giao dịch đã thanh toán, đã hủy, của đối tác khác <!--k:tx-cancel-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-026 · BR-19-019 · API-19-104 · ERR-19-021, 020
- **Tiền điều kiện / dữ liệu** TX-OK; giao dịch `CANCELLED`; giao dịch của P-MC.
- **Bước**
  1. C-DVC hủy TX-OK.
  2. Hủy lại giao dịch `CANCELLED`.
  3. C-DVC hủy giao dịch của P-MC.
- **Mong đợi** Bước 1, 2 trả `409` ERR-19-021. Bước 3: 404-ẩn.

#### TC-19-328 · Hết hạn sau truy vấn cuối <!--k:tx-expire-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-027 · BR-19-017 · ExpiryScheduler
- **Tiền điều kiện / dữ liệu** Giao dịch A `PENDING`, `expiresAt` cách 31 phút; `PGSIM` trả "chưa thanh toán". Giao dịch B tương tự, `PGSIM` không trả lời. Giao dịch C `CREATED` `initUncertain` cách 72 giờ 1 phút.
- **Bước**
  1. Chạy ExpiryScheduler.
- **Mong đợi** A: ST: `PENDING` → `EXPIRED` (nguồn `EXPIRY_JOB`), WH: `transaction.expired`. B: ST: giữ `PENDING`, lần truy vấn kế theo BR-19-016. C: ST: `CREATED` → `EXPIRED` (quá trần 72 giờ). Mỗi giao dịch chỉ được một bản sao `worker` xử lý.


#### TC-19-329 · Không hết hạn giao dịch đã có kết quả, không chạy trùng <!--k:tx-expire-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-027 · BR-19-017 · ExpiryScheduler
- **Tiền điều kiện / dữ liệu** Giao dịch D `PENDING` quá hạn, `PGSIM` trả "thành công" ở truy vấn cuối; giao dịch E `SUCCEEDED` quá `expiresAt`; 3 bản sao `worker`.
- **Bước**
  1. Chạy ExpiryScheduler đồng thời trên 3 bản sao.
- **Mong đợi** D: ST: `PENDING` → `SUCCEEDED` nguồn `POLL`, không phải `EXPIRED`. E: không đổi. Mỗi giao dịch chỉ một lần truy vấn cuối (khóa `SKIP LOCKED`), không có sự kiện trùng.
### TS-19-15 · Đối tác truy vấn trạng thái

**Mục tiêu.** Xác nhận đối tác truy vấn được giao dịch của mình theo mã và theo mã đơn hàng, không đọc được của đối tác khác.

**Phủ.** FR-19-035; UC-19-15; API-19-102, 103, 108, 109; ERR-19-020; NFR-19-004.

#### TC-19-351 · Truy vấn theo mã giao dịch và mã đơn hàng <!--k:partner-query-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-035 · API-19-102, 103
- **Tiền điều kiện / dữ liệu** TX-OK; mã đơn hàng `TC19-255` có hai lượt.
- **Bước**
  1. C-DVC `P: GET /payments/{TX-OK}`.
  2. `P: GET /payments?partnerOrderId=TC19-255`.
- **Mong đợi** Bước 1 trả `200` có `status`, `amount`, `paidAt`, `refundedAmount`, `sequence`, không có dữ liệu cá nhân chưa che. Bước 2 trả hai lượt, mới nhất trước.

#### TC-19-352 · Truy vấn giao dịch của đối tác khác, tỉnh khác <!--k:partner-query-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-035 · API-19-102, 103 · ERR-19-020 · NFR-19-025
- **Tiền điều kiện / dữ liệu** Giao dịch của P-MC; TX-T99.
- **Bước**
  1. C-DVC truy vấn giao dịch của P-MC.
  2. C-DVC-T99 truy vấn TX-OK của T68.
  3. C-DVC truy vấn mã giao dịch ngẫu nhiên đúng định dạng.
- **Mong đợi** Cả ba: 404-ẩn, cùng thân, thời gian trả lời không phân biệt được (chênh p50 < 5 ms qua 200 lần).

#### TC-19-353 · Kéo thông báo dự phòng theo con trỏ <!--k:partner-notifications-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-035, 060 · API-19-109 · BR-19-021
- **Tiền điều kiện / dữ liệu** Đầu nhận webhook của P-DVC ngừng 1 giờ; trong thời gian đó có 5 giao dịch kết thúc.
- **Bước**
  1. `P: GET /notifications?after=` (con trỏ rỗng), `limit = 3`.
  2. Gọi lại với `next`.
- **Mong đợi** Bước 1 trả 3 thông báo đầu theo thứ tự phát, có `sequence`. Bước 2 trả 2 thông báo còn lại, `hasMore = false`. Nội dung trùng với webhook sẽ gửi.

### TS-19-16 · Đồng bộ trạng thái và xử lý lại IPN

**Mục tiêu.** Xác nhận truy vấn chủ động theo lịch giãn dần, đồng bộ thủ công có giới hạn tần suất, và xử lý lại IPN cách ly.

**Phủ.** FR-19-032, 036, 037; UC-19-16; API-19-053, 057, 058; UI-19-15, 16; ERR-19-023, 021; BR-19-016.

#### TC-19-376 · Lịch truy vấn chủ động giãn dần <!--k:poll-schedule-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-036 · BR-19-016 · PendingQueryScheduler
- **Tiền điều kiện / dữ liệu** Giao dịch `PENDING` không có IPN; `PGSIM` luôn trả "chưa thanh toán"; đồng hồ giả.
- **Bước**
  1. Tiến đồng hồ tới 72 giờ, ghi lại các thời điểm truy vấn.
  2. Ở lần thứ 6, `PGSIM` trả "thành công".
- **Mong đợi** Bước 1: các lần truy vấn ở 2, 5, 10, 15, 30 phút, 1, 2, 4 giờ, rồi mỗi 6 giờ (dung sai ±10 giây). Bước 2: ST: `PENDING` → `SUCCEEDED` nguồn `POLL`; các lần truy vấn sau dừng.

#### TC-19-377 · Cán bộ đồng bộ thủ công <!--k:sync-manual-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-037 · API-19-053 · UI-19-15
- **Tiền điều kiện / dữ liệu** U-OPR1; TX-PEND; `PGSIM` trả "thành công".
- **Bước**
  1. Bấm "Đồng bộ với NCC", nhập lý do.
- **Mong đợi** `200` với `before = PENDING`, `after = SUCCEEDED`, `changed = true`, `nextAllowedAt`; ST: `PENDING` → `SUCCEEDED` nguồn `MANUAL_SYNC`. KT: có. Phát hành Đ2b.

#### TC-19-378 · Đồng bộ quá tần suất, không có quyền <!--k:sync-manual-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-037 · API-19-053 · ERR-19-023, 046
- **Tiền điều kiện / dữ liệu** U-OPR1; U-ADM1.
- **Bước**
  1. Đồng bộ cùng giao dịch hai lần trong 60 giây.
  2. Đồng bộ 11 lần trong ngày (cách nhau > 60 giây).
  3. U-ADM1 đồng bộ.
- **Mong đợi** Bước 1 lần 2 trả `429` ERR-19-023 có `Retry-After`. Bước 2 lần 11 trả `429` ERR-19-023. Bước 3 trả 403-PQ.

#### TC-19-379 · Xem và xử lý lại IPN cách ly <!--k:ipn-replay-->
- **Loại** Dương, Âm · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-032 · API-19-057, 058 · UI-19-16 · ERR-19-021
- **Tiền điều kiện / dữ liệu** U-OPR1; IPN cách ly `UNMAPPED_CODE` từ TC-19-304 bước 4; bảng ánh xạ đã thêm mã `99` (v2); một IPN `BAD_SIGNATURE`.
- **Bước**
  1. Mở ngăn kéo chi tiết IPN cách ly.
  2. Bấm "Xử lý lại", nhập lý do.
  3. Gọi `POST /callbacks/{id}/replays` cho IPN `BAD_SIGNATURE`.
- **Mong đợi** Bước 1: nguyên văn đã che, `rawHash`, các bước kiểm tra. Bước 2 trả `202`; IPN `PROCESSED` với `mappingVersion = 2`; giao dịch đổi trạng thái theo kết quả mới. Bước 3 trả `409` ERR-19-021; nút không hiện trên màn. Phần xử lý lại phát hành Đ2b; phần xem thuộc MVP.

### TS-19-17 · Lập yêu cầu hoàn tiền

**Mục tiêu.** Xác nhận chỉ lập được yêu cầu hoàn hợp lệ: đúng trạng thái, trong hạn, không vượt số còn được hoàn. Thay cho ba trạng thái hoàn trả chưa có chức năng của hệ cũ.

**Phủ.** FR-19-038; UC-19-17; API-19-059, 105, 087; UI-19-18; ERR-19-029…032; BR-19-022, 033; LGC-PAY-025.

#### TC-19-401 · Kế toán lập yêu cầu hoàn toàn phần <!--k:rf-create-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-038 · BR-19-022 · API-19-059, 087 · UI-19-18 · LGC-PAY-025
- **Tiền điều kiện / dữ liệu** U-ACC1; TX-OK; F-VOUCHER làm tài liệu đính kèm.
- **Bước**
  1. Từ UI-19-15 của TX-OK bấm "Lập yêu cầu hoàn", chọn "Toàn phần", lý do "Nộp thừa", ngân hàng, số tài khoản, tải tài liệu.
  2. Bấm "Gửi yêu cầu hoàn".
- **Mong đợi** Bước 1: tệp quét `CLEAN` trước khi bật nút gửi. Bước 2: `POST /refunds` trả `201`, `status = PENDING_APPROVAL`, `mode = MANUAL`, `accountNoMasked` chỉ còn 4 số cuối; số tài khoản lưu mã hóa. KT: có. EVT: `refund.requested`.

#### TC-19-402 · Đối tác lập yêu cầu hoàn một phần <!--k:rf-create-partner-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-038 · API-19-105, 106
- **Tiền điều kiện / dữ liệu** C-DVC; TX-PR (còn được hoàn 600.000 ₫).
- **Bước**
  1. `P: POST /refunds` 300.000 ₫ có khóa.
  2. `P: GET /refunds/{refundCode}`.
- **Mong đợi** Bước 1 trả `201`, `requestedByType = PARTNER`. Bước 2 trả `PENDING_APPROVAL`.

#### TC-19-403 · Hoàn sai trạng thái, quá hạn, vượt số còn được hoàn, giao dịch thử <!--k:rf-create-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-038 · BR-19-022, 033 · API-19-059 · ERR-19-029, 030, 031, 032
- **Tiền điều kiện / dữ liệu** U-ACC1; TX-PEND; TX-OLD; TX-PR; TX-TEST; tenant T68 bản sao có `19.refund.enabled = false`.
- **Bước**
  1. Hoàn TX-PEND.
  2. Hoàn TX-OLD.
  3. Hoàn TX-PR 600.001 ₫.
  4. Hoàn TX-TEST.
  5. Lập thêm yêu cầu cho TX-PR khi đang có yêu cầu `PENDING_APPROVAL`.
  6. Hoàn ở tenant đã tắt hoàn tiền.
- **Mong đợi** Bước 1, 4, 5 trả `409` ERR-19-029. Bước 2 trả `422` ERR-19-031. Bước 3 trả `422` ERR-19-030 với `remaining = 600000`. Bước 6 trả `422` ERR-19-032.

### TS-19-18 · Phê duyệt và thực thi hoàn tiền

**Mục tiêu.** Xác nhận duyệt một cấp, hai cấp theo ngưỡng, ba người khác nhau, và thực thi thủ công có chứng từ, người ghi nhận khác người duyệt.

**Phủ.** FR-19-039, 040, 041; UC-19-18; API-19-050, 061, 062, 203; UI-19-13, 17, 18; ERR-19-033, 021, 032; BR-19-023, 024; LGC-PAY-025.

#### TC-19-426 · Duyệt một cấp dưới ngưỡng <!--k:rf-approve-1-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-039 · BR-19-023 · API-19-050
- **Tiền điều kiện / dữ liệu** Yêu cầu từ TC-19-401 (50.000 ₫); U-APR1.
- **Bước**
  1. U-APR1 duyệt.
- **Mong đợi** Yêu cầu `APPROVED` rồi `AWAITING_MANUAL` (chế độ `MANUAL`). WH: `refund.decided`. U-ACC1 thấy yêu cầu trong "Việc của tôi" ở UI-19-17.

#### TC-19-427 · Duyệt hai cấp trên ngưỡng, ba người khác nhau <!--k:rf-approve-2-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-039 · BR-19-023, 011 · API-19-050 · ERR-19-033 · UI-19-13
- **Tiền điều kiện / dữ liệu** U-ACC1 lập yêu cầu hoàn 7.500.000 ₫ cho TX-BIG; U-APR1, U-APR2.
- **Bước**
  1. U-APR1 duyệt.
  2. U-APR1 duyệt lần nữa (cấp 2).
  3. U-APR2 duyệt.
- **Mong đợi** Bước 1: `PENDING_SECOND_APPROVAL`; UI-19-13 hiện "Hoàn tiền (cấp 2)". Bước 2 trả `403` ERR-19-033 "đã duyệt cấp trước". Bước 3: `APPROVED`.

#### TC-19-428 · Ghi nhận đã hoàn thủ công có chứng từ <!--k:rf-exec-manual-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-040, 041 · BR-19-024 · API-19-062 · UI-19-18
- **Tiền điều kiện / dữ liệu** Yêu cầu `AWAITING_MANUAL` từ TC-19-426; U-ACC2 (không duyệt yêu cầu này); F-VOUCHER.
- **Bước**
  1. U-ACC2 bấm "Ghi nhận đã hoàn", nhập số chứng từ, ngày, tải tệp, gõ lại mã yêu cầu.
- **Mong đợi** `POST /refunds/{id}/executions` `RECORD_MANUAL` trả `200`; yêu cầu `SUCCEEDED`; ST: `SUCCEEDED` → `REFUNDED` (nguồn `REFUND`). WH: `refund.succeeded`. Tệp chứng từ lưu ở `dh-t68-payment-worm`. KT: có.

#### TC-19-429 · Hoàn một phần nhiều lần tới toàn phần <!--k:rf-partial-chain-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-041 · BR-19-022 · API-19-059, 062
- **Tiền điều kiện / dữ liệu** Giao dịch `SUCCEEDED` 1.000.000 ₫.
- **Bước**
  1. Hoàn 300.000 ₫ (đi hết duyệt, ghi nhận).
  2. Hoàn 700.000 ₫.
- **Mong đợi** Bước 1: ST: `SUCCEEDED` → `PARTIALLY_REFUNDED`, `refundedAmount = 300000`. Bước 2: ST: `PARTIALLY_REFUNDED` → `REFUNDED`.

#### TC-19-430 · Thực thi hoàn qua NCC và thực hiện lại <!--k:rf-exec-api-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, IT
- **Truy vết** FR-19-040, 041 · BR-19-024 · API-19-203, 062
- **Tiền điều kiện / dữ liệu** Cờ `payment.refund-api` bật; `PGSIM` khai năng lực hoàn; yêu cầu `APPROVED` 50.000 ₫.
- **Bước**
  1. Hệ thống gửi lệnh hoàn; `PGSIM` gửi `C: POST /paygov/{connectionKey}/refund-ipn` thành công.
- **Mong đợi** Yêu cầu `PROCESSING` → `SUCCEEDED`; `providerRefundRef` có giá trị. Phát hành Đ2b.

#### TC-19-431 · Hoàn qua NCC lỗi, thực hiện lại, chuyển thủ công <!--k:rf-retry-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-040, 041 · API-19-062 · ERR-19-021
- **Tiền điều kiện / dữ liệu** Như TC-19-430; `PGSIM` báo lỗi hoàn.
- **Bước**
  1. Yêu cầu chuyển `FAILED`; U-ACC1 `RETRY` ba lần, `PGSIM` lỗi cả ba.
  2. `RETRY` lần thứ tư.
  3. `SWITCH_MANUAL`.
- **Mong đợi** Bước 1: `executionCount = 3`, `FAILED`. Bước 2 trả `409` ERR-19-021. Bước 3: `AWAITING_MANUAL`. Phát hành Đ2b.

#### TC-19-432 · Người lập rút yêu cầu hoàn <!--k:rf-withdraw-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-19-038 · API-19-050
- **Tiền điều kiện / dữ liệu** Yêu cầu `PENDING_APPROVAL` của U-ACC1.
- **Bước**
  1. U-ACC1 rút; U-ACC2 thử rút.
- **Mong đợi** U-ACC2 trả `403` ERR-19-033 (không phải người lập); U-ACC1: `CANCELLED`, số còn được hoàn trở lại như trước.

#### TC-19-433 · Ghi nhận thủ công vi phạm tách nhiệm, thiếu chứng từ <!--k:rf-exec-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-040 · BR-19-024 · API-19-062 · ERR-19-033, 001, 021
- **Tiền điều kiện / dữ liệu** Yêu cầu `AWAITING_MANUAL` do U-APR1 duyệt; U-AA1 có thêm `refund-execute` qua vai trò thử; yêu cầu `PENDING_APPROVAL`.
- **Bước**
  1. Người đã duyệt (U-APR1 được gán tạm `refund-execute`) ghi nhận đã hoàn.
  2. U-ACC2 ghi nhận thiếu `voucherFileId`.
  3. U-ACC2 ghi nhận cho yêu cầu còn `PENDING_APPROVAL`.
- **Mong đợi** Bước 1 trả `403` ERR-19-033; nút vô hiệu với lý do tách nhiệm. Bước 2 trả `400` ERR-19-001. Bước 3 trả `409` ERR-19-021.

### TS-19-19 · Đối soát ngày

**Mục tiêu.** Xác nhận phiên đối soát tự tạo, thu thập dữ liệu của NCC (tải tự động hoặc tải lên), so khớp đúng và sinh đủ các loại chênh lệch.

**Phủ.** FR-19-042, 043, 044; UC-19-19; API-19-063…067, 070, 204; UI-19-19, 20; ERR-19-040, 041; BR-19-025, 028; NFR-19-008.

#### TC-19-451 · Phiên tự động khớp hoàn toàn <!--k:rc-auto-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, E2E
- **Truy vết** FR-19-042, 043, 044 · BR-19-025 · UI-19-19, 20
- **Tiền điều kiện / dữ liệu** Ngày D-1 có 100 giao dịch thành công của PV-PG; `PGSIM` phục vụ F-RECON-OK lúc 06:00.
- **Bước**
  1. Tiến đồng hồ tới 06:00 giờ Việt Nam; chạy SessionScheduler.
  2. Mở UI-19-20.
- **Mong đợi** Bước 1: một phiên (PV-PG, D-1) `SCHEDULED` → `COLLECTING` → `MATCHING` → `READY_TO_CLOSE`. Bước 2: tổng hợp hai phía bằng nhau, khớp tự động 100%; mọi giao dịch có `reconStatus = MATCHED`. Giao dịch thử không có trong phiên.

#### TC-19-452 · NCC chưa có dữ liệu, thu thập lại <!--k:rc-waiting-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-19-043 · API-19-066 · BR-19-025
- **Tiền điều kiện / dữ liệu** `PGSIM` trả "chưa có dữ liệu" tới 09:00.
- **Bước**
  1. Chạy phiên lúc 06:00.
  2. Tiến tới 09:05; U-ACC1 bấm "Thu thập lại".
- **Mong đợi** Bước 1: `WAITING_DATA`, `nextCollectAt` có giá trị; huy hiệu "Đối soát" tăng. Bước 2: `COLLECTING` → `MATCHING` → `READY_TO_CLOSE`. Quá `19.recon.collect-deadline` mà vẫn thiếu thì cảnh báo PH-13.

#### TC-19-453 · Tải file đối soát lên, mã băm và nội dung sai <!--k:rc-upload-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-043 · API-19-065 · ERR-19-041 · UI-19-20
- **Tiền điều kiện / dữ liệu** Phiên `WAITING_DATA`; U-ACC1; F-RECON-BADHASH; tệp của ngày khác; F-RECON-OK.
- **Bước**
  1. Tải F-RECON-BADHASH.
  2. Tải tệp của ngày D-2.
  3. Tải F-RECON-OK (giao diện tự tính SHA-256).
- **Mong đợi** Bước 1, 2 trả `422` ERR-19-041 với lý do "sai mã băm", "sai ngày". Bước 3 trả `202`; phiên tiếp tục so khớp; tệp lưu WORM.

#### TC-19-454 · So khớp sinh đủ loại chênh lệch <!--k:rc-match-diff-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-044, 045 · BR-19-028 · API-19-067, 070, 071
- **Tiền điều kiện / dữ liệu** F-RECON-DIFF.
- **Bước**
  1. Chạy phiên với F-RECON-DIFF.
  2. `GET /reconciliation-sessions/{id}/items?matchResult=MISMATCHED,MISSING_DH,MISSING_PROVIDER`.
- **Mong đợi** Bước 1: phiên `IN_REVIEW`, đúng 5 chênh lệch loại `MISSING_AT_DATAHUB`, `MISSING_AT_PROVIDER`, `AMOUNT_MISMATCH`, `STATUS_MISMATCH`, `DUPLICATE`; mỗi dòng lệch đúng một chênh lệch. Bước 2: 5 dòng, mỗi dòng có `discrepancyId`.


#### TC-19-456 · So khớp loại giao dịch không thuộc phiên <!--k:rc-match-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-044 · BR-19-025, 028, 033, 034
- **Tiền điều kiện / dữ liệu** Ngày D-1 có thêm: 2 giao dịch thử, 1 giao dịch `is_shadow`, 1 giao dịch của NCC khác, 1 giao dịch thanh toán lúc 00:00:01 ngày D; tệp NCC khớp đúng phần còn lại.
- **Bước**
  1. Chạy phiên (PV-PG, D-1).
- **Mong đợi** Phiên `READY_TO_CLOSE`, 0 chênh lệch; năm giao dịch trên không có trong phiên; giao dịch 00:00:01 nằm ở phiên ngày D.
#### TC-19-455 · Tạo phiên trùng, phiên ngày chưa kết thúc <!--k:rc-create-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-042 · API-19-063 · ERR-19-040, 001
- **Tiền điều kiện / dữ liệu** U-ACC1; phiên (PV-PG, D-1) đã có.
- **Bước**
  1. `POST /reconciliation-sessions` (PV-PG, D-1).
  2. (PV-PG, hôm nay).
- **Mong đợi** Bước 1 trả `409` ERR-19-040. Bước 2 trả `400` ERR-19-001.

### TS-19-20 · Xử lý chênh lệch

**Mục tiêu.** Xác nhận vòng đời chênh lệch, bốn cách xử lý qua phê duyệt, và tự khớp khi chạy lại.

**Phủ.** FR-19-045, 046; UC-19-20; API-19-071…074, 087, 050; UI-19-21, 22; ERR-19-033, 045, 043; BR-19-028, 030.

#### TC-19-476 · Giao việc, nhận việc, ghi chú chỉ thêm <!--k:dc-assign-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-045 · BR-19-030 · API-19-072, 074 · UI-19-21, 22
- **Tiền điều kiện / dữ liệu** Chênh lệch `AMOUNT_MISMATCH` từ TC-19-454; U-ACC1, U-ACC2.
- **Bước**
  1. U-ACC1 giao cho U-ACC2 (`ASSIGN`).
  2. U-ACC2 `CLAIM`, thêm ghi chú kèm tệp.
  3. Thử `UPDATE` trực tiếp cột `notes` trong CSDL bằng vai trò `ph19_app`.
- **Mong đợi** Bước 1: người phụ trách đổi, trạng thái `OPEN`. Bước 2: `INVESTIGATING`, ghi chú hiện ở dòng thời gian. Bước 3 bị trigger chặn (chỉ thêm qua `append_discrepancy_note`).

#### TC-19-477 · Chuyển cấp tới NCC và phản hồi <!--k:dc-escalate-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-19-045 · API-19-072
- **Tiền điều kiện / dữ liệu** Chênh lệch `INVESTIGATING`.
- **Bước**
  1. `ESCALATE` với `escalationRef` "PG-TICKET-1".
  2. `PROVIDER_RESPONDED` có ghi chú.
- **Mong đợi** `ESCALATED` rồi `INVESTIGATING`. Quá `19.recon.escalate-workdays` thì DiscrepancyEscalator thông báo người phê duyệt.

#### TC-19-478 · Đề xuất cập nhật trạng thái theo NCC và duyệt <!--k:dc-update-status-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-046 · BR-19-011, 014 · API-19-073, 050 · UI-19-22
- **Tiền điều kiện / dữ liệu** Chênh lệch `STATUS_MISMATCH` (Datahub `FAILED`, NCC thành công); U-ACC2 đề xuất; U-APR1.
- **Bước**
  1. U-ACC2 đề xuất `UPDATE_STATUS_FROM_PROVIDER` với `targetTransactionVersion`.
  2. U-APR1 duyệt.
- **Mong đợi** Bước 1: `PROPOSED`, đề nghị `DISCREPANCY_RESOLUTION`. Bước 2: ST: `FAILED` → `SUCCEEDED` nguồn `DISCREPANCY_RESOLUTION`; chênh lệch `RESOLVED`; WH: `transaction.succeeded`.

#### TC-19-479 · Chấp nhận số liệu NCC, tạo yêu cầu hoàn, không xử lý <!--k:dc-other-resolutions-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-046 · API-19-073
- **Tiền điều kiện / dữ liệu** Ba chênh lệch `AMOUNT_MISMATCH`, `DUPLICATE`, `MISSING_AT_PROVIDER` (kỹ thuật).
- **Bước**
  1. Đề xuất `ACCEPT_PROVIDER_FIGURE`, `CREATE_REFUND` (số tiền trùng), `NO_ACTION` (ghi chú bắt buộc) và duyệt.
- **Mong đợi** Lần lượt: giao dịch có `adjustments` `PAYMENT_AMOUNT`; một yêu cầu hoàn `PENDING_APPROVAL` mới (phải qua duyệt hoàn riêng); chênh lệch đóng không đổi giao dịch. Ba chênh lệch `RESOLVED`.

#### TC-19-480 · Đề xuất sai, tự duyệt, giao dịch đã đổi <!--k:dc-propose-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-045, 046 · API-19-073, 050 · ERR-19-001, 033, 045
- **Tiền điều kiện / dữ liệu** U-AA1 có `discrepancy-handle` và `discrepancy-approve` qua vai trò thử.
- **Bước**
  1. Đề xuất `NO_ACTION` không ghi chú.
  2. U-AA1 đề xuất rồi tự duyệt.
  3. Đề xuất với `targetTransactionVersion` cũ.
- **Mong đợi** Bước 1 trả `400` ERR-19-001. Bước 2 trả `403` ERR-19-033. Bước 3 trả `412` ERR-19-045.

#### TC-19-481 · Chênh lệch tự khớp khi chạy lại so khớp <!--k:dc-auto-resolve-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-19-044, 045 · BR-19-028 · API-19-066
- **Tiền điều kiện / dữ liệu** Chênh lệch `MISSING_AT_DATAHUB` do IPN đến muộn; IPN đã tới sau đó.
- **Bước**
  1. `POST /reconciliation-sessions/{id}/runs` `REMATCH`.
- **Mong đợi** Lần chạy 2; chênh lệch `RESOLVED` với `resolutionType = AUTO_MATCHED`; kết quả lần chạy 1 vẫn xem được.

### TS-19-21 · Chốt, mở lại phiên và biên bản

**Mục tiêu.** Xác nhận phiên chỉ chốt khi hết chênh lệch, phiên đã chốt bất biến, mở lại cần phê duyệt và biên bản có mã băm.

**Phủ.** FR-19-047, 048; UC-19-21; API-19-068, 069, 083, 084, 088, 107; UI-19-20; ERR-19-042, 043, 033; BR-19-028, 030.

#### TC-19-501 · Chốt phiên, sinh biên bản <!--k:rc-close-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-047, 048 · API-19-068, 083, 084, 088 · UI-19-20
- **Tiền điều kiện / dữ liệu** Phiên `READY_TO_CLOSE` từ TC-19-451; U-ACC1.
- **Bước**
  1. Bấm "Chốt phiên", gõ lại ngày, xác nhận.
  2. Mở tab "Biên bản", tải PDF và XLSX.
- **Mong đợi** Bước 1: `CLOSED`, `closedBy`; tác vụ `RECON_MINUTES` chạy. Bước 2: PDF, XLSX có tổng hai phía; SHA-256 của PDF bằng `minutesSha256`; tệp ở bucket WORM. WH: `reconciliation.closed`. KT: có.

#### TC-19-502 · Chốt phiên còn chênh lệch <!--k:rc-close-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-047 · API-19-068 · ERR-19-042, 021
- **Tiền điều kiện / dữ liệu** Phiên `IN_REVIEW` với 2 chênh lệch mở; phiên `COLLECTING`.
- **Bước**
  1. Chốt phiên `IN_REVIEW`.
  2. Chốt phiên `COLLECTING`.
- **Mong đợi** Bước 1 trả `409` ERR-19-042 với `count = 2`. Bước 2 trả `409` ERR-19-021.

#### TC-19-503 · Phiên đã chốt bất biến <!--k:rc-closed-immutable-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API, DB
- **Truy vết** FR-19-047 · BR-19-030 · NFR-19-016 · API-19-065, 066, 072 · ERR-19-043
- **Tiền điều kiện / dữ liệu** Phiên `CLOSED` từ TC-19-501.
- **Bước**
  1. Tải file lên phiên; chạy lại so khớp; sửa chênh lệch của phiên.
  2. `UPDATE reconciliation_session SET …` bằng `ph19_app`.
  3. Xóa đối tượng biên bản trên Ceph RGW bằng tài khoản ứng dụng.
- **Mong đợi** Bước 1 trả `409` ERR-19-043. Bước 2 bị trigger chặn (SQLSTATE P1930). Bước 3 bị từ chối (khóa đối tượng WORM).

#### TC-19-504 · Mở lại phiên có phê duyệt, người chốt không tự duyệt <!--k:rc-reopen-->
- **Loại** Dương, Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-047 · BR-19-028 · API-19-069, 050 · ERR-19-033
- **Tiền điều kiện / dữ liệu** Phiên `CLOSED` do U-ACC1 chốt; U-AA1 được gán tạm `recon-close` và `recon-reopen-approve` và là người chốt phiên thứ hai.
- **Bước**
  1. U-ACC1 đề nghị mở lại có lý do.
  2. U-APR1 duyệt.
  3. Trên phiên thứ hai, U-AA1 (người chốt) duyệt đề nghị mở lại do U-ACC1 lập.
- **Mong đợi** Bước 1: `REOPEN_PENDING`. Bước 2: `IN_REVIEW`, lần chạy mới; biên bản cũ giữ và đánh dấu "bị thay thế". Bước 3 trả `403` ERR-19-033.

#### TC-19-505 · Đối tác tải kết quả đối soát phần của mình <!--k:rc-partner-report-->
- **Loại** Dương, Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-19-048 · API-19-107 · ERR-19-020
- **Tiền điều kiện / dữ liệu** Phiên D-1 `CLOSED`; phiên D-2 `IN_REVIEW`; C-DVC.
- **Bước**
  1. `P: GET /reconciliation-reports?date=D-1`.
  2. `?date=D-2`.
- **Mong đợi** Bước 1 trả tệp chỉ chứa giao dịch của P-DVC. Bước 2: 404-ẩn (phiên chưa chốt). Phát hành Đ2b.

### TS-19-22 · Tra cứu và xuất giao dịch

**Mục tiêu.** Xác nhận bảng tra cứu giao dịch giữ đủ cột và tìm kiếm của hệ cũ, lọc kết hợp đúng, xuất có giới hạn và che dữ liệu cá nhân.

**Phủ.** FR-19-049, 050, 052; UC-19-22; API-19-051, 083, 084; UI-19-14; ERR-19-047, 001; BR-19-031; LGC-PAY-014…018.

#### TC-19-526 · Bảng tra cứu đủ chín cột hệ cũ, tìm theo mã <!--k:tx-list-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-19-049 · API-19-051 · UI-19-14 · LGC-PAY-014, 018 · NFR-19-029, 030
- **Tiền điều kiện / dữ liệu** U-OPR1; 60 giao dịch trong 30 ngày.
- **Bước**
  1. Mở UI-19-14.
  2. Gõ mã TX-OK, nhấn `Enter`.
  3. Xóa ô tìm; bấm "Trang sau".
- **Mong đợi** Bước 1: chín cột đúng thứ tự hệ cũ, 20 dòng, sắp giảm theo ngày phát sinh; người thanh toán đã che. Bước 2 mở thẳng UI-19-15. Bước 3: dòng 21–40; URL giữ bộ lọc.

#### TC-19-527 · Tra cứu nâng cao kết hợp trạng thái, lĩnh vực, thời gian <!--k:tx-filter-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-050 · API-19-051 · UI-19-14 · LGC-PAY-015, 016, 017
- **Tiền điều kiện / dữ liệu** Bộ dữ liệu có đủ trạng thái, hai nhóm dịch vụ.
- **Bước**
  1. Lọc trạng thái `SUCCEEDED` + `PENDING`, nhóm G-TP, 7 ngày, số tiền 10.000–100.000 ₫.
  2. Lọc người nộp theo họ tên đầy đủ đúng; rồi theo một phần họ tên.
- **Mong đợi** Bước 1: kết quả bằng truy vấn đối chứng SQL; dòng tổng chỉ cộng giao dịch thành công, ghi rõ. Bước 2: họ tên đầy đủ khớp; một phần không khớp (băm HMAC), có ghi chú dưới ô.

#### TC-19-528 · Tham số tra cứu không hợp lệ <!--k:tx-filter-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-049, 050 · API-19-051 · ERR-19-001, 046
- **Tiền điều kiện / dữ liệu** U-OPR1; U-SEC1.
- **Bước**
  1. `q` 1 ký tự; `from` sau `to`; khoảng 400 ngày; `limit = 500`; `sort = name`.
  2. U-SEC1 gọi `GET /transactions`.
- **Mong đợi** Bước 1: mỗi trường hợp `400` ERR-19-001 chỉ đúng tham số. Bước 2: 403-PQ.

#### TC-19-529 · Xuất danh sách giao dịch che dữ liệu cá nhân <!--k:tx-export-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-052 · BR-19-031 · API-19-083, 084 · UI-19-14
- **Tiền điều kiện / dữ liệu** U-ACC1; bộ lọc 30 ngày.
- **Bước**
  1. Xuất XLSX.
  2. U-ACC1 có `transaction-read-pii` xuất kèm "thông tin người nộp chưa che" với lý do.
  3. U-ACC2 mở đường tải của U-ACC1.
- **Mong đợi** Bước 1: tác vụ `QUEUED` → `SUCCEEDED`; tệp che dữ liệu cá nhân. Bước 2: tệp chưa che; KT: có (`TRANSACTION_EXPORT_PII` với lý do). Bước 3: 404-ẩn. Đường tải hết hạn sau 24 giờ. Phát hành Đ2b.

#### TC-19-530 · Xuất vượt giới hạn, không có quyền <!--k:tx-export-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-052 · API-19-083 · ERR-19-047, 046
- **Tiền điều kiện / dữ liệu** Môi trường SIT hạ giới hạn xuất từ 1.000.000 xuống 1.000 dòng bằng tham số kiểm thử (giả định GĐ-TC-01, để không phải sinh 1 triệu dòng); bộ lọc trả 1.500 dòng; U-OPR1; U-ACC1 có `transaction-read-pii`.
- **Bước**
  1. U-ACC1 xuất.
  2. U-OPR1 xuất.
  3. U-ACC1 xuất với `includePii = true` mà không có lý do.
- **Mong đợi** Bước 1 trả `422` ERR-19-047. Bước 2: 403-PQ. Bước 3 trả `400` ERR-19-001 (thiếu lý do).

### TS-19-23 · Chi tiết giao dịch

**Mục tiêu.** Xác nhận màn chi tiết đủ thông tin của hệ cũ, che dữ liệu cá nhân theo quyền, xem bản rõ có lý do và kiểm toán, và mở được vết đầu-cuối.

**Phủ.** FR-19-051, 055; UC-19-23; API-19-052, 054; UI-19-15; BR-19-031; NFR-19-024, 026; LGC-PAY-019, 021.

#### TC-19-551 · Chi tiết đủ khối, dòng thời gian, liên kết vết <!--k:tx-detail-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** E2E, API
- **Truy vết** FR-19-051, 055 · API-19-052, 054 · UI-19-15 · LGC-PAY-019
- **Tiền điều kiện / dữ liệu** U-OPR1; TX-PR (có một lần hoàn một phần).
- **Bước**
  1. Mở UI-19-15 của TX-PR.
  2. Bấm "Mở vết" ở dòng IPN của dòng thời gian.
- **Mong đợi** Bước 1: đủ khối thông tin chung, người nộp (đã che theo BR-19-031), NCC, đối tác, dòng thời gian (mỗi chuyển trạng thái có nguồn, thời điểm, `sequence`), hoàn tiền, đối soát, webhook; `allowedActions` khớp vai trò. Bước 2 mở PH-13 đúng `trace_id`.

#### TC-19-552 · Xem bản rõ dữ liệu cá nhân có lý do <!--k:tx-reveal-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-051 · BR-19-031 · NFR-19-024 · API-19-052 · UI-19-15
- **Tiền điều kiện / dữ liệu** U-ACC1 có `transaction-read-pii`.
- **Bước**
  1. Bấm "Hiện thông tin người nộp", nhập lý do "Đối chiếu khiếu nại số 12".
  2. Chờ 5 phút.
- **Mong đợi** Bước 1: gọi API-19-052 có `X-Datahub-Reveal-Reason`; hiện bản rõ; KT: `TRANSACTION_PII_REVEALED` có lý do, không chứa bản rõ. Bước 2: giao diện tự che lại.

#### TC-19-553 · Xem bản rõ không có quyền, thiếu lý do; giao dịch tỉnh khác <!--k:tx-reveal-neg-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-051 · API-19-052 · ERR-19-046, 001, 020
- **Tiền điều kiện / dữ liệu** U-OPR1 (không có `transaction-read-pii`); U-ACC1; TX-T99.
- **Bước**
  1. U-OPR1 gọi API-19-052 có `X-Datahub-Reveal-Reason`.
  2. U-ACC1 gọi với lý do 5 ký tự.
  3. U-ACC1 mở TX-T99.
- **Mong đợi** Bước 1: 403-PQ. Bước 2 trả `400` ERR-19-001. Bước 3: 404-ẩn. Không bước nào trả bản rõ.

### TS-19-24 · Nhật ký kiểm toán và tích hợp

**Mục tiêu.** Xác nhận mọi thao tác ghi và quyết định phê duyệt có bản ghi kiểm toán, không ghi được kiểm toán thì hủy thao tác, và nhật ký tích hợp đủ, đã che. Thay "lưu dữ liệu quá trình thanh toán" và "xem log" của hệ cũ.

**Phủ.** FR-19-053, 054, 055; UC-19-24; API-19-075, 076; UI-19-23; ERR-19-050; NFR-19-015, 026; LGC-PAY-011, 021.

#### TC-19-576 · Mọi thao tác ghi có kiểm toán <!--k:audit-all-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-053 · BR-19-029 · NFR-19-015
- **Tiền điều kiện / dữ liệu** Bộ ca chạy lại toàn bộ thao tác ghi của TS-19-01…29 trên SIT.
- **Bước**
  1. Với mỗi API ghi của nhóm quản trị (danh sách lấy từ OpenAPI, `x-audit: true`), so số bản ghi `payment.audit.recorded.v1` với số lời gọi thành công.
- **Mong đợi** Bằng nhau 100%; mỗi bản ghi có người, thời điểm, tenant, đối tượng, hành động, lý do (khi bắt buộc), `trace_id`, không chứa bí mật hay dữ liệu cá nhân bản rõ.

#### TC-19-577 · Không ghi được kiểm toán thì hủy thao tác <!--k:audit-fail-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-053 · BR-19-029 · ERR-19-050
- **Tiền điều kiện / dữ liệu** Tiêm lỗi: bảng `outbox_event` từ chối ghi bản ghi loại `AUDIT` (trigger thử nghiệm).
- **Bước**
  1. U-APR1 duyệt một đề nghị kích hoạt NCC.
- **Mong đợi** `503` ERR-19-050; đề nghị vẫn `PENDING`; NCC không đổi trạng thái (một giao dịch CSDL bị hoàn tác).

#### TC-19-578 · Xem nhật ký tích hợp đã che, lọc theo giao dịch <!--k:intlog-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-054, 055 · API-19-075, 076 · UI-19-23 · LGC-PAY-011, 021
- **Tiền điều kiện / dữ liệu** U-OPR1; TX-OK đã có khởi tạo, IPN, truy vấn, webhook.
- **Bước**
  1. Mở UI-19-23, lọc mã TX-OK.
  2. Mở chi tiết lượt khởi tạo.
- **Mong đợi** Bước 1: bốn lượt đủ hướng, thao tác, mã kết quả, độ trễ. Bước 2: nội dung đã che (chữ ký, bí mật, dữ liệu cá nhân); có liên kết vết PH-13.

#### TC-19-579 · Nhật ký tích hợp không có quyền, tỉnh khác <!--k:intlog-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-054 · API-19-075, 076 · ERR-19-046, 020
- **Tiền điều kiện / dữ liệu** U-ACC1 (không có `log-read` theo giả định khung §13); U-ADM1-T99.
- **Bước**
  1. U-ACC1 gọi API-19-075.
  2. U-ADM1-T99 gọi API-19-076 với mã nhật ký của T68.
- **Mong đợi** Bước 1: 403-PQ. Bước 2: 404-ẩn.

### TS-19-25 · Dashboard và cảnh báo

**Mục tiêu.** Xác nhận hai dashboard có đủ chỉ tiêu của hệ cũ, số liệu trễ ≤ 60 giây, loại giao dịch thử, và chỉ số vận hành sinh cảnh báo đúng ngưỡng.

**Phủ.** FR-19-056, 057, 059; UC-19-25; API-19-080, 081; UI-19-01, 02; NFR-19-006; LGC-PAY-003, 009, 013, 020, 023, 026.

#### TC-19-601 · Dashboard tổng quan đủ chỉ tiêu hệ cũ, số liệu đúng <!--k:dash-overview-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-056 · API-19-080 · UI-19-01 · LGC-PAY-013, 026
- **Tiền điều kiện / dữ liệu** U-OPR1; bộ dữ liệu §2.4 cộng 3 giao dịch thử.
- **Bước**
  1. Mở UI-19-01.
  2. So các thẻ với truy vấn đối chứng SQL.
- **Mong đợi** Bước 1: đủ số dịch vụ, số hệ thống áp dụng, tổng giao dịch, giao dịch trong ngày, biểu đồ theo dịch vụ giảm dần, huy hiệu việc cần làm. Bước 2: bằng nhau; giao dịch thử không được đếm.

#### TC-19-602 · Số liệu cập nhật trong 60 giây <!--k:dash-fresh-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-056 · NFR-19-006 · API-19-080
- **Tiền điều kiện / dữ liệu** Dashboard đang mở.
- **Bước**
  1. Tạo và hoàn tất 10 giao dịch.
  2. Đo thời điểm `txnToday` tăng 10.
- **Mong đợi** ≤ 60 giây (thay đệm 10 phút của hệ cũ, LGC-PAY-026); `asOf` hiện trên giao diện.

#### TC-19-603 · Dashboard kênh thanh toán 30 ngày <!--k:dash-channels-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-057 · API-19-081 · UI-19-02 · LGC-PAY-003, 020, 023
- **Tiền điều kiện / dữ liệu** PV-PG có giao dịch 30 ngày; PV-SUS.
- **Bước**
  1. Mở UI-19-02.
- **Mong đợi** Mỗi NCC một thẻ: tên, ngày hiệu lực, đầu mối, tình trạng (PV-SUS hiện "Tạm ngừng"), số dịch vụ, biểu đồ số giao dịch theo ngày 30 ngày, tỷ lệ thành công, độ trễ p95.

#### TC-19-604 · Dashboard không có quyền, tỉnh khác <!--k:dash-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-056, 057 · API-19-080, 081 · ERR-19-046 · NFR-19-025
- **Tiền điều kiện / dữ liệu** U-SEC1; U-ADM1-T99.
- **Bước**
  1. U-SEC1 gọi API-19-080.
  2. U-ADM1-T99 gọi API-19-080 với `X-Tenant-Id: T68`.
- **Mong đợi** Bước 1: 403-PQ. Bước 2: số liệu của T99, tiêu đề tenant giả bị bỏ qua hoặc từ chối theo D03-10.

#### TC-19-605 · Chỉ số vận hành và cảnh báo <!--k:metrics-alert-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-19-059 · NFR-19-026 · LGC-PAY-009
- **Tiền điều kiện / dữ liệu** Prometheus của SIT; quy tắc cảnh báo của D04.
- **Bước**
  1. Cho `PGSIM` lỗi 60% trong 2 phút.
  2. Giữ 5 giao dịch `PENDING` quá 30 phút.
  3. Ngừng đầu nhận webhook 15 phút.
- **Mong đợi** Có các chỉ số `payment_provider_errors_total`, `payment_pending_age_seconds`, `payment_webhook_backlog`; ba cảnh báo tương ứng tới PH-13 trong 2 phút sau khi vượt ngưỡng; nhãn chỉ có tenant, NCC, không có mã giao dịch.

### TS-19-26 · Báo cáo định kỳ

**Mục tiêu.** Xác nhận báo cáo theo ngày, tháng, quý đúng với dữ liệu giao dịch, tách giao dịch thử và hoàn tiền, xuất được.

**Phủ.** FR-19-058; UC-19-26; API-19-082, 083, 084; UI-19-25; NFR-19-009.

#### TC-19-626 · Báo cáo tháng khớp dữ liệu giao dịch <!--k:report-month-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-058 · API-19-082 · UI-19-25
- **Tiền điều kiện / dữ liệu** U-ACC1; tháng trước có 1.000 giao dịch sinh tổng hợp, 20 lần hoàn.
- **Bước**
  1. Mở báo cáo "Tổng hợp thu theo dịch vụ", kỳ tháng trước.
  2. So tổng với truy vấn đối chứng SQL; so tổng hoàn tiền.
- **Mong đợi** Tổng thu, số lượt, theo dịch vụ, lĩnh vực, đối tác, NCC đều bằng; giao dịch thử bị loại; dòng hoàn tiền tách riêng, "thu thuần" = thu − hoàn. Phát hành Đ2b.

#### TC-19-627 · Xuất báo cáo <!--k:report-export-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-19-058 · API-19-083, 084 · NFR-19-009
- **Tiền điều kiện / dữ liệu** Như TC-19-626.
- **Bước**
  1. Xuất XLSX và PDF.
- **Mong đợi** Tệp có tiêu đề, kỳ, tenant, người xuất, thời điểm; số liệu bằng màn hình. Phát hành Đ2b.

#### TC-19-628 · Báo cáo sai kỳ, không có quyền <!--k:report-neg-->
- **Loại** Âm · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-19-058 · API-19-082 · ERR-19-001, 046, 020
- **Tiền điều kiện / dữ liệu** U-OPR1 (không có `report-read`).
- **Bước**
  1. Kỳ tháng tương lai; kỳ quý sai định dạng `2026-Q5`.
  2. Mã báo cáo không tồn tại.
  3. U-OPR1 mở báo cáo.
- **Mong đợi** Bước 1 trả `400` ERR-19-001. Bước 2 trả `404` ERR-19-020. Bước 3: 403-PQ.

### TS-19-27 · Thông báo kết quả cho đối tác

**Mục tiêu.** Xác nhận webhook có ký, thử lại theo lịch, giữ thứ tự `sequence`, gửi lại thủ công, và không mất sự kiện khi Kafka ngừng. Thay phần "gửi kết quả về hệ thống nghiệp vụ" của hệ cũ.

**Phủ.** FR-19-060, 061, 062; UC-19-27; API-19-077, 078, 079, 109; UI-19-24; ERR-19-021, 045; BR-19-021; NFR-19-005, 013, 021; LGC-PAY-012.

#### TC-19-651 · Gửi webhook có ký, đối tác xác minh được <!--k:wh-deliver-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-19-060 · NFR-19-005, 021 · LGC-PAY-012
- **Tiền điều kiện / dữ liệu** `WHSINK` cho P-DVC trả `200`.
- **Bước**
  1. Hoàn tất TX-OK qua IPN.
  2. Ở `WHSINK` kiểm chữ ký.
- **Mong đợi** Bước 1: lượt gửi `PENDING` → `DELIVERED` trong p95 ≤ 5 s. Bước 2: header `Datahub-Webhook-Id`, `Datahub-Webhook-Timestamp`, `Datahub-Webhook-Signature`; HMAC-SHA256 trên `{id}.{timestamp}.{body}` khớp; thân có `transactionCode`, `status`, `amount`, `sequence`, không có dữ liệu cá nhân.

#### TC-19-652 · Thử lại theo lịch rồi hết lần thử <!--k:wh-retry-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-060, 062 · BR-19-020 · API-19-079
- **Tiền điều kiện / dữ liệu** `WHSINK` trả `503`; đồng hồ giả.
- **Bước**
  1. Hoàn tất một giao dịch; tiến đồng hồ 17 giờ.
  2. Cho `WHSINK` trả `410`.
- **Mong đợi** Bước 1: 11 lần gửi theo lịch BR-19-020 (ngay, rồi 10 s, 30 s, 1 phút, 5, 15, 30 phút, 1, 2, 4, 8 giờ; dung sai ±10%), mỗi lần ghi mã HTTP, độ trễ; sau lần cuối `EXHAUSTED`; huy hiệu "Webhook" tăng; cảnh báo PH-13. Bước 2: lượt gửi mới trả `410` chuyển `EXHAUSTED` ngay, không thử lại.

#### TC-19-653 · Thứ tự `sequence` trong một giao dịch <!--k:wh-order-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-19-060, 061 · BR-19-021
- **Tiền điều kiện / dữ liệu** `WHSINK` lỗi lượt đầu rồi phục hồi.
- **Bước**
  1. Giao dịch `SUCCEEDED` rồi hoàn một phần trong 10 giây.
- **Mong đợi** Hai webhook đến đúng thứ tự `sequence` tăng dần; lượt sau không gửi trước khi lượt trước `DELIVERED` hoặc `EXHAUSTED` (theo khóa giao dịch).

#### TC-19-654 · Gửi lại thủ công lượt đã hết lần thử <!--k:wh-resend-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-062 · API-19-077, 078, 079 · UI-19-24
- **Tiền điều kiện / dữ liệu** Lượt `EXHAUSTED` từ TC-19-652; `WHSINK` đã phục hồi; U-OPR1.
- **Bước**
  1. UI-19-24 lọc `EXHAUSTED`, mở chi tiết, bấm "Gửi lại", nhập lý do.
- **Mong đợi** `202`; lượt gửi `PENDING` → `DELIVERED`; giữ nguyên `Datahub-Webhook-Id` (đối tác khử trùng được); các lần thử cũ vẫn xem được. KT: có.

#### TC-19-655 · Hủy lượt gửi khi đối tác hoặc đầu nhận bị gỡ <!--k:wh-cancel-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** IT
- **Truy vết** FR-19-062 · BR-19-020
- **Tiền điều kiện / dữ liệu** Lượt `RETRYING` tới đầu nhận của P-DVC.
- **Bước**
  1. Vô hiệu đầu nhận đó.
- **Mong đợi** Lượt gửi `CANCELLED`, không thử tiếp; thông báo vẫn kéo được qua API-19-109.

#### TC-19-656 · Gửi lại lượt đang gửi, đã giao, sai phiên bản <!--k:wh-resend-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-062 · API-19-078 · ERR-19-021, 045, 046
- **Tiền điều kiện / dữ liệu** Lượt `RETRYING`; lượt `DELIVERED`; U-ACC1 (không có `webhook-resend`).
- **Bước**
  1. Gửi lại lượt `RETRYING`.
  2. Gửi lại lượt `DELIVERED`.
  3. Gửi lại với `If-Match` cũ.
  4. U-ACC1 gửi lại.
- **Mong đợi** Bước 1, 2 trả `409` ERR-19-021. Bước 3 trả `412` ERR-19-045. Bước 4: 403-PQ.

#### TC-19-657 · Kafka ngừng, outbox giữ và phát bù <!--k:outbox-kafka-down-->
- **Loại** Âm, Chịu lỗi · **Ưu tiên** P1 · **Tự động** IT (Chaos Mesh)
- **Truy vết** FR-19-061 · NFR-19-013
- **Tiền điều kiện / dữ liệu** Kafka của SIT bị chặn mạng 20 phút.
- **Bước**
  1. Trong 20 phút tạo và hoàn tất 500 giao dịch.
  2. Mở lại Kafka.
- **Mong đợi** Bước 1: API vẫn trả lời bình thường; `outbox_event` tăng 500 × số sự kiện; không lỗi phía đối tác. Bước 2: phát bù hết trong ≤ 5 phút; không mất, không đảo thứ tự trong một giao dịch; webhook đến sau đó.

### TS-19-28 · Cấu hình và khởi tạo tenant

**Mục tiêu.** Xác nhận tham số có phiên bản và ngày hiệu lực, khởi tạo đủ tài nguyên khi PH-20 bật PH-19, chặn giao dịch khi tạm ngừng.

**Phủ.** FR-19-063, 064; UC-19-28; API-19-085, 086; UI-19-26; ERR-19-049, 045, 001.

#### TC-19-676 · Tạo phiên bản cấu hình có ngày hiệu lực <!--k:config-version-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** API, E2E
- **Truy vết** FR-19-063 · API-19-085, 086 · UI-19-26
- **Tiền điều kiện / dữ liệu** U-TEN1; cấu hình v1 có `19.txn.ttl-minutes = 30`.
- **Bước**
  1. Tạo v2 `ttl = 45`, hiệu lực 00:00 ngày mai.
  2. Tạo giao dịch hôm nay; tiến đồng hồ qua 00:00; tạo giao dịch nữa.
- **Mong đợi** Bước 1 trả `201`; UI-19-26 hiện v2 "Sắp hiệu lực". Bước 2: giao dịch đầu `expiresAt` +30 phút, giao dịch sau +45 phút; mỗi giao dịch ghi `configVersion`. KT: có.

#### TC-19-677 · Cấu hình ngoài khoảng, sai phiên bản <!--k:config-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-063 · API-19-086 · ERR-19-001, 045, 046
- **Tiền điều kiện / dữ liệu** U-TEN1; U-OPR1.
- **Bước**
  1. `ttl = 0`; giờ chốt đối soát `25:00`; ngày hiệu lực trong quá khứ.
  2. `If-Match` cũ.
  3. U-OPR1 tạo phiên bản.
- **Mong đợi** Bước 1 trả `400` ERR-19-001 chỉ đúng trường. Bước 2 trả `412` ERR-19-045. Bước 3: 403-PQ.

#### TC-19-678 · Khởi tạo khi PH-20 bật phân hệ <!--k:tenant-provision-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-064 · NFR-19-025
- **Tiền điều kiện / dữ liệu** T50 chưa bật PH-19.
- **Bước**
  1. Phát sự kiện PH-20 `tenant.module.enabled` (PH-19, T50).
  2. Phát lại sự kiện đó.
- **Mong đợi** Bước 1: cấu hình mặc định v1, topic `t50.payment.*`, bucket `dh-t50-payment`, `dh-t50-payment-worm`, đường dẫn OpenBao `kv/dh/t50/payment/` được tạo; API của T50 trả lời. Bước 2: không tạo trùng (xử lý một lần theo hộp nhận).

#### TC-19-679 · Tenant tạm ngừng phân hệ <!--k:tenant-suspend-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT, API
- **Truy vết** FR-19-064 · ERR-19-049
- **Tiền điều kiện / dữ liệu** T50 đã bật; có một giao dịch `PENDING`.
- **Bước**
  1. PH-20 phát `tenant.module.suspended`.
  2. Đối tác của T50 gọi `P: POST /payments`.
  3. `PGSIM` gửi IPN cho giao dịch `PENDING`.
- **Mong đợi** Bước 2 trả `503` ERR-19-049. Bước 3: IPN vẫn được nhận, xử lý (không bỏ tiền người nộp đã trả); giao dịch `SUCCEEDED`; webhook gửi bình thường.

### TS-19-29 · Di trú và chạy song song

**Mục tiêu.** Xác nhận nhập dữ liệu hệ cũ đúng, chạy lại không trùng, chuyển chế độ định tuyến theo đối tác qua phê duyệt, quay lui được, và đối chiếu sau di trú phát hiện lệch.

**Phủ.** FR-19-065, 066, 067, 068; UC-19-29; API-19-047, 048, 050, 089, 090, 110; UI-19-12, 13, 27; ERR-19-006, 001, 033; LGC-PAY-001…026 (dữ liệu).

#### TC-19-701 · Nhập năm bảng hệ cũ <!--k:mig-import-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT, E2E
- **Truy vết** FR-19-065 · API-19-089, 090 · UI-19-27
- **Tiền điều kiện / dữ liệu** U-PLA1; F-LEG-CSV (năm bảng: NCC, dịch vụ, đối tác, giao dịch, nhật ký; 10.000 giao dịch).
- **Bước**
  1. Chạy lô `IMPORT` từ UI-19-27.
  2. Mở kết quả.
- **Mong đợi** Bước 1 trả `202`; lần chạy `SUCCEEDED`. Bước 2: số bản ghi nhập bằng số dòng nguồn trừ dòng lỗi; giao dịch nhập có `origin = LEGACY`, mã hệ cũ trong `legacyRef`, không phát webhook, không sinh sự kiện kết quả; trạng thái hệ cũ được ánh xạ theo bảng của FR-19-065.

#### TC-19-702 · Chạy lại lô không trùng <!--k:mig-rerun-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-065 · API-19-089
- **Tiền điều kiện / dữ liệu** Lô của TC-19-701 đã chạy.
- **Bước**
  1. Chạy lại cùng lô (cùng `Idempotency-Key`).
  2. Chạy lô mới cùng tệp, khóa khác.
- **Mong đợi** Bước 1 trả lại kết quả lần trước. Bước 2: 0 bản ghi mới, 10.000 "đã có" (khóa tự nhiên `legacyRef`).

#### TC-19-703 · Dữ liệu hệ cũ bất thường <!--k:mig-dirty-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-065 · NFR-19-017
- **Tiền điều kiện / dữ liệu** F-LEG-CSV có các dòng: số tiền 2.500.000.000 (vượt `int` 32 bit của hệ cũ); `pay_date` dạng `20261301` và `31/02/2026`; trạng thái mã lạ `9`; số tiền âm.
- **Bước**
  1. Chạy lô.
- **Mong đợi** Số tiền 2,5 tỷ nhập đúng (`numeric(19,0)`). Các dòng sai ngày, trạng thái lạ, số âm vào báo cáo lỗi, có số dòng và lý do; các dòng còn lại vẫn nhập; báo cáo lỗi tải được qua API-19-090.

#### TC-19-704 · Chuyển LEGACY → SHADOW → DATAHUB có phê duyệt <!--k:mig-route-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** API, E2E
- **Truy vết** FR-19-066, 068 · BR-19-034 · API-19-047, 050 · UI-19-12, 13
- **Tiền điều kiện / dữ liệu** P-LEG ở `LEGACY`; U-PLA1 lập, U-APR1 duyệt.
- **Bước**
  1. Đề nghị `SHADOW`; duyệt.
  2. Hệ cũ xử lý một giao dịch của P-LEG; bộ ghi song song gửi bản sao.
  3. Sau 7 ngày `SHADOW` liên tiếp có đối chiếu FR-19-068 đạt 0 bản ghi lệch chưa giải thích, đề nghị `DATAHUB`; duyệt.
  4. C-LEG gọi `P: POST /payments`.
- **Mong đợi** Bước 1: chế độ `SHADOW`. Bước 2: Datahub ghi nhận bản sao `is_shadow = true`, không gọi NCC, không webhook; có trong báo cáo so sánh, không vào hạn mức, báo cáo, đối soát. Bước 3: `DATAHUB`. Bước 4 trả `201`.

#### TC-19-705 · Gọi API khi còn ở LEGACY, tự duyệt chuyển chế độ <!--k:mig-route-neg-->
- **Loại** Âm · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-066 · BR-19-034 · API-19-101, 047, 050 · ERR-19-006, 033, 035
- **Tiền điều kiện / dữ liệu** P-LEG ở `LEGACY`; U-AA1 có `migration-switch` và `migration-approve` qua vai trò thử.
- **Bước**
  1. C-LEG gọi `P: POST /payments`.
  2. U-AA1 đề nghị rồi tự duyệt.
  3. Đề nghị `DATAHUB` cho đối tác mới ở `SHADOW` 3 ngày.
- **Mong đợi** Bước 1 trả `409` ERR-19-006. Bước 2 trả `403` ERR-19-033. Bước 3 trả `422` ERR-19-035, `detail` nêu "chưa đủ 7 ngày SHADOW".

#### TC-19-706 · Quay lui DATAHUB → LEGACY <!--k:mig-rollback-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** FR-19-066
- **Tiền điều kiện / dữ liệu** P-LEG ở `DATAHUB`, có 3 giao dịch `PENDING`.
- **Bước**
  1. Đề nghị và duyệt quay về `LEGACY`.
  2. `PGSIM` gửi IPN cho 3 giao dịch.
- **Mong đợi** Bước 1: giao dịch mới của P-LEG đi hệ cũ. Bước 2: 3 giao dịch vẫn được Datahub xử lý tới trạng thái cuối và gửi webhook (không bỏ dở giao dịch đang chạy).

#### TC-19-707 · Đối chiếu sau di trú phát hiện lệch <!--k:mig-compare-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** FR-19-068 · API-19-089, 090 · UI-19-27
- **Tiền điều kiện / dữ liệu** Sau TC-19-701; sửa tay 2 bản ghi hệ cũ (đổi số tiền, đổi trạng thái).
- **Bước**
  1. Chạy lô `COMPARE` cho tháng đó.
- **Mong đợi** Số lượng, tổng tiền, phân bố trạng thái theo tháng và theo đối tác; liệt kê đúng 2 bản ghi lệch với giá trị hai phía.


#### TC-19-709 · Đối chiếu sau di trú: kỳ không hợp lệ, không có quyền, chạy trùng <!--k:mig-compare-neg-->
- **Loại** Âm · **Ưu tiên** P2 · **Tự động** API
- **Truy vết** FR-19-068 · API-19-089 · ERR-19-001, 021, 046
- **Tiền điều kiện / dữ liệu** U-PLA1; U-OPR1; một lô `COMPARE` đang chạy cho tháng 10.
- **Bước**
  1. `COMPARE` cho tháng tương lai.
  2. `COMPARE` tháng 10 lần nữa khi lô trước chưa xong.
  3. U-OPR1 tạo lô.
- **Mong đợi** Bước 1 trả `400` ERR-19-001. Bước 2 trả `409` ERR-19-021. Bước 3: 403-PQ.
#### TC-19-708 · Lớp tương thích API hệ cũ <!--k:mig-compat-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** API
- **Truy vết** FR-19-067 · API-19-110
- **Tiền điều kiện / dữ liệu** Chỉ chạy khi OQ-19-17 xác nhận cần; cờ `payment.legacy-compat` bật.
- **Bước**
  1. Gọi `P: POST /legacy-compat/createPayment` theo hợp đồng hệ cũ.
- **Mong đợi** Trả theo định dạng hệ cũ, có header `Deprecation` và `Sunset`; giao dịch tạo qua API-19-101. Phát hành "Sau".

## 5. Kịch bản kiểm thử phi chức năng và xuyên suốt

Năm kịch bản TS-19-30…34 kiểm các yêu cầu phi chức năng NFR-19-001…032 và các quy tắc cắt ngang mọi use case. Ca hiệu năng đo hai lần liên tiếp trên môi trường PERF; đạt khi cả hai lần đạt. Ca có thẻ `security` chạy hằng tuần và trước mỗi bản phát hành; ca chịu lỗi chạy trước mỗi bản phát hành lớn và sau mỗi thay đổi hạ tầng.

### TS-19-30 · Bảo mật callback và webhook

**Mục tiêu.** Xác nhận bốn lớp xác minh IPN của NFR-19-020, chữ ký webhook và chữ ký lượt quay về của NFR-19-021, và kiểm chứng ứng dụng theo OWASP ASVS cấp 2.

**Phủ.** NFR-19-018, 019, 020, 021, 023; FR-19-025, 029; API-19-201…205; ERR-19-024…027; LGC-PAY-010, 012, 022, 024.

#### TC-19-726 · IPN sai chữ ký, chứng thư đã thu hồi <!--k:sec-ipn-sig-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-19-029 · NFR-19-020 · API-19-201 · ERR-19-024 · LGC-PAY-010
- **Tiền điều kiện / dữ liệu** TX `PENDING`; chứng thư cũ của PV-PG đã chuyển `REVOKED`.
- **Bước**
  1. Gửi IPN đổi một byte trong thân sau khi ký.
  2. Gửi IPN ký bằng chứng thư đã thu hồi.
  3. Gửi IPN không có chữ ký.
- **Mong đợi** Cả ba trả `401` ERR-19-024; hộp nhận ghi `REJECTED` lý do `BAD_SIGNATURE`; giao dịch không đổi; `payment_callback_rejected_total{reason="signature"}` tăng; sự kiện an ninh tới PH-13.

#### TC-19-727 · IPN lệch thời gian quá ±5 phút <!--k:sec-ipn-skew-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-020, 028 · API-19-201 · ERR-19-025
- **Tiền điều kiện / dữ liệu** TX `PENDING`.
- **Bước**
  1. Gửi IPN có dấu thời gian lệch −4 phút 59 giây và +4 phút 59 giây.
  2. Lệch −5 phút 1 giây và +5 phút 1 giây.
- **Mong đợi** Bước 1 được nhận. Bước 2 trả `401` ERR-19-025.

#### TC-19-728 · Phát lại nonce với nội dung khác <!--k:sec-ipn-replay-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-020 · API-19-201 · ERR-19-026
- **Tiền điều kiện / dữ liệu** IPN thành công đã xử lý.
- **Bước**
  1. Gửi IPN có cùng nonce nhưng mã kết quả khác, chữ ký hợp lệ.
  2. Xóa khóa nonce trong Valkey rồi gửi lại.
- **Mong đợi** Bước 1 trả `409` ERR-19-026. Bước 2 vẫn trả `409` ERR-19-026 nhờ ràng buộc duy nhất trong CSDL.

#### TC-19-729 · IPN từ IP lạ, sai connectionKey <!--k:sec-ipn-source-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-020 · API-19-201 · ERR-19-027, 020
- **Tiền điều kiện / dữ liệu** Allowlist IP của PV-PG tại APISIX; máy thử ngoài allowlist.
- **Bước**
  1. Gửi IPN hợp lệ từ IP lạ.
  2. Gửi IPN tới `connectionKey` của PV-SUS bằng chữ ký của PV-PG.
  3. Gửi tới `connectionKey` ngẫu nhiên.
- **Mong đợi** Bước 1 trả `403` ERR-19-027 tại biên, không tới `dh-payment`. Bước 2 trả `401` ERR-19-024. Bước 3 trả `404`, thân chung, không lộ tenant.

#### TC-19-730 · Xoay bí mật webhook, hai bí mật cùng hiệu lực 7 ngày <!--k:sec-wh-rotate-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** NFR-19-021 · FR-19-060
- **Tiền điều kiện / dữ liệu** Đầu nhận của P-DVC; đồng hồ giả.
- **Bước**
  1. Xoay bí mật.
  2. Hoàn tất giao dịch; kiểm header chữ ký.
  3. Tiến 7 ngày 1 phút; hoàn tất giao dịch.
- **Mong đợi** Bước 2: header có hai chữ ký `v1=` (mới, cũ); đối tác chỉ có bí mật cũ vẫn xác minh được. Bước 3: chỉ còn chữ ký mới. Bí mật mới ≥ 256 bit, chỉ nằm trong OpenBao.

#### TC-19-731 · Token đối tác hết hạn, client bị thu hồi <!--k:sec-token-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-019 · API-19-101
- **Tiền điều kiện / dữ liệu** C-DVC.
- **Bước**
  1. Dùng token sau 5 phút 1 giây.
  2. Dùng token mTLS-bound với chứng thư khác.
  3. Thu hồi C-DVC, đo thời gian tới khi bị từ chối.
- **Mong đợi** Bước 1, 2 trả `401`. Bước 3: ≤ 60 giây.

#### TC-19-732 · TLS ra ngoài và egress <!--k:sec-tls-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** IT (testssl.sh)
- **Truy vết** NFR-19-018
- **Tiền điều kiện / dữ liệu** SIT có egress gateway riêng tới `PGSIM`.
- **Bước**
  1. Quét các điểm nhận `/api/payment-partner/v1`, `/api/payment-callback/v1`.
  2. Từ pod `dh-payment` gọi một địa chỉ Internet khác `PGSIM`.
- **Mong đợi** Bước 1: chỉ TLS 1.3 (hoặc 1.2 AEAD theo OQ-19-02), không bộ mã yếu. Bước 2 bị chặn bởi chính sách egress.

#### TC-19-733 · Quét động có xác thực, ASVS cấp 2 <!--k:sec-zap-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** ZAP
- **Truy vết** NFR-19-023 · API-19-001…205
- **Tiền điều kiện / dữ liệu** ZAP nhập ba tệp OpenAPI của PH-19; ngữ cảnh U-ADM1, U-ACC1, C-DVC.
- **Bước**
  1. Quét chủ động toàn bộ thao tác.
  2. Chạy danh sách kiểm ASVS 5.0 cấp 2 cho các mục V2, V3, V4, V5, V8, V9 (thủ công phần không tự động được).
- **Mong đợi** Không phát hiện mức cao hoặc nghiêm trọng; mức trung bình có phiếu xử lý trước RG-3. Kết quả ASVS ghi vào báo cáo ATTT của đợt.

### TS-19-31 · Cách ly tenant và RLS

**Mục tiêu.** Xác nhận NFR-19-025: không có đường nào đọc hoặc ghi chéo tenant, ở API, CSDL, Valkey, Kafka, kho đối tượng, khóa ký.

**Phủ.** NFR-19-025; mọi UC; ADR-003, ADR-045; LGC-PAY-012, 024.

#### TC-19-751 · Quét 100% API đọc, ghi chéo tenant <!--k:iso-api-sweep-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-025 · API-19-001…110
- **Tiền điều kiện / dữ liệu** Bộ sinh ca từ OpenAPI: với mỗi thao tác có tham số đường dẫn, dùng mã đối tượng của T68 và danh tính của T99 (U-ADM1-T99, C-DVC-T99).
- **Bước**
  1. Chạy toàn bộ thao tác đọc.
  2. Chạy toàn bộ thao tác ghi (có `Idempotency-Key`, `If-Match` hợp lệ của T68).
- **Mong đợi** 100% thao tác trả 404-ẩn (đọc) hoặc 404-ẩn, 403 (ghi); không đối tượng nào của T68 thay đổi; báo cáo liệt kê số thao tác đã quét bằng số thao tác trong OpenAPI.

#### TC-19-752 · Tiêu đề tenant giả <!--k:iso-header-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-025 · D03-10
- **Tiền điều kiện / dữ liệu** U-ADM1-T99.
- **Bước**
  1. Gửi `X-Tenant-Id: T68` kèm token T99 tới API-19-001, 051.
- **Mong đợi** Tenant lấy từ claim của token; tiêu đề giả bị APISIX gỡ; trả dữ liệu T99 hoặc `403`; sự kiện an ninh.

#### TC-19-753 · RLS FORCE trên mọi bảng <!--k:iso-rls-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** DB
- **Truy vết** NFR-19-025 · D03-03-PH19
- **Tiền điều kiện / dữ liệu** Kết nối `ph19_app` đặt `app.tenant_id = 'T99'`.
- **Bước**
  1. Truy vấn `pg_class` liệt kê bảng của `ph19_payment` không có `relrowsecurity` và `relforcerowsecurity`.
  2. `SELECT count(*)` từng bảng; `UPDATE` một bản ghi của T68 theo khóa chính.
  3. Kết nối không đặt `app.tenant_id`.
- **Mong đợi** Bước 1: rỗng. Bước 2: chỉ thấy dữ liệu T99; `UPDATE` 0 dòng. Bước 3: 0 dòng ở mọi bảng (mặc định từ chối).

#### TC-19-754 · Valkey, Kafka, kho đối tượng, khóa ký theo tenant <!--k:iso-infra-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** NFR-19-025, 022
- **Tiền điều kiện / dữ liệu** Thông tin xác thực dịch vụ của T99.
- **Bước**
  1. Liệt kê khóa Valkey `t68:payment:*` bằng ACL của T99.
  2. Tiêu thụ topic `t68.payment.transaction.succeeded.v1` bằng principal của T99.
  3. Đọc `dh-t68-payment` bằng khóa truy cập của T99.
  4. Đọc `kv/dh/t68/payment/` bằng vai trò OpenBao của T99.
- **Mong đợi** Cả bốn bị từ chối, có bản ghi từ chối ở hệ tương ứng.

#### TC-19-755 · Xác định tenant cho callback chỉ theo connectionKey <!--k:iso-callback-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** NFR-19-025 · ADR-045 · API-19-201
- **Tiền điều kiện / dữ liệu** Hai tenant T68, T99 cùng dùng PayGov với `connectionKey` khác nhau; giao dịch `PENDING` ở T68.
- **Bước**
  1. Gửi IPN của giao dịch T68 tới `connectionKey` của T99, ký bằng khóa của T99.
- **Mong đợi** IPN `QUARANTINED` lý do `NOT_FOUND` ở T99; giao dịch của T68 không đổi.

#### TC-19-756 · Hạn mức tốc độ riêng mỗi tenant <!--k:iso-ratelimit-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** API (k6)
- **Truy vết** NFR-19-025 · ERR-19-048
- **Tiền điều kiện / dữ liệu** Hạn mức thử 50 yêu cầu/giây mỗi tenant.
- **Bước**
  1. Bắn 200 yêu cầu/giây vào T99; đồng thời 20 yêu cầu/giây vào T68.
- **Mong đợi** T99 nhận `429` ERR-19-048 có `Retry-After`; T68 không có `429`, p95 không đổi quá 10%.

### TS-19-32 · Hiệu năng, tải và dung lượng

Đo trên PERF với dữ liệu §2 (10 triệu giao dịch mỗi tenant, 3 tenant theo GĐ-01), `PGSIM` trễ cố định 150 ms. Độ trễ đo tại APISIX, không tính thời gian PayGov.

| Ca | Tên | Tải, cách đo | Ngưỡng | Truy vết |
|---|---|---|---|---|
| TC-19-776 | Tạo giao dịch ở tải thường <!--k:perf-create--> | k6, 200 giao dịch/giây một tenant, 15 phút | p95 ≤ 300 ms, p99 ≤ 800 ms | NFR-19-001 · API-19-101 · LGC-PAY-001 |
| TC-19-777 | Tải đỉnh một tenant và toàn cụm <!--k:perf-peak--> | k6, 200 giao dịch/giây mỗi tenant × 3 tenant, 15 phút | Lỗi do PH-19 < 0,1%; tổng 600 giao dịch/giây | NFR-19-002 · API-19-101 |
| TC-19-778 | Nhận và xử lý IPN <!--k:perf-ipn--> | k6, 200 IPN/giây | Trả lời p95 ≤ 200 ms; xử lý p95 ≤ 2 s | NFR-19-003 · API-19-201 · LGC-PAY-010 |
| TC-19-779 | Truy vấn trạng thái của đối tác <!--k:perf-query--> | k6, 300 yêu cầu/giây một tenant | p95 ≤ 150 ms | NFR-19-004 · API-19-102, 103 |
| TC-19-780 | Webhook đầu tiên và tỷ lệ giao <!--k:perf-webhook--> | 10.000 giao dịch kết thúc trong 10 phút; `WHSINK` trả `200` trong 50 ms | Bắt đầu p95 ≤ 5 s; ≥ 99% `DELIVERED` trong 60 s | NFR-19-005 · FR-19-060 |
| TC-19-781 | Dashboard trễ và tải trang <!--k:perf-dash--> | 50 người dùng ảo mở UI-19-01, 02 khi đang chạy TC-19-776 | Trễ số liệu ≤ 60 s; tải trang p95 ≤ 2 s | NFR-19-006 · UI-19-01, 02 · LGC-PAY-026 |
| TC-19-782 | Tra cứu giao dịch 10 triệu dòng <!--k:perf-search--> | k6, 200 người dùng đồng thời một tenant, lọc ngẫu nhiên | Trang đầu p95 ≤ 1,5 s; tra theo mã p95 ≤ 300 ms | NFR-19-007 · API-19-051 · LGC-PAY-014 |
| TC-19-783 | Đối soát 100.000 dòng mỗi phía <!--k:perf-recon--> | Tệp đối soát sinh tổng hợp 100.000 dòng, 1% lệch | So khớp ≤ 10 phút; phiên sẵn trước 08:00 | NFR-19-008 · FR-19-044 |
| TC-19-784 | Xuất 1.000.000 dòng <!--k:perf-export--> | Một tác vụ xuất trên dữ liệu 10 triệu dòng | ≤ 10 phút; đường tải hết hạn 24 giờ | NFR-19-009 · FR-19-052 |
| TC-19-785 | Bulkhead khi một NCC chậm <!--k:perf-bulkhead--> | `PGSIM` trễ 9 s cho PV-PG; 50 yêu cầu/giây PV-PG và 100 yêu cầu/giây NCC thứ hai | Lời gọi đồng thời tới PV-PG ≤ 50; p95 của NCC thứ hai không đổi quá 10% | NFR-19-012 · FR-19-011 |
| TC-19-786 | Ngâm tải 8 giờ <!--k:perf-soak--> | 50 giao dịch/giây kèm IPN, truy vấn, webhook | Không rò bộ nhớ (heap ổn định ±10%); outbox, inbox không tồn đọng | NFR-19-002, 013 |

### TS-19-33 · Phân quyền và tách nhiệm

**Mục tiêu.** Xác nhận ma trận quyền khung §13 đúng ở từng ô, và mười quy tắc tách nhiệm khung §13.4.

**Phủ.** Khung §13; BR-19-011, 023, 024, 028, 031; ERR-19-033, 046.

#### TC-19-801 · Quét ma trận quyền theo vai trò <!--k:perm-matrix-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** Khung §13.2, §13.3 · ERR-19-046
- **Tiền điều kiện / dữ liệu** Chín người dùng thử, mỗi người đúng một vai trò; bộ sinh ca đọc bảng vai trò × quyền × API từ khung §13.
- **Bước**
  1. Mỗi người gọi mọi API quản trị với dữ liệu hợp lệ.
- **Mong đợi** Ô "có" trả mã thành công hoặc lỗi nghiệp vụ (không phải `403`); ô "không" trả 403-PQ. 48 quyền đều có ít nhất một ô "có" và một ô "không" được kiểm. Báo cáo dạng bảng đính kèm.

#### TC-19-802 · Quy tắc động 1: người quyết định khác người lập, mọi loại đề nghị <!--k:sod-1-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** Khung §13.4 #1 · BR-19-011 · API-19-050 · ERR-19-033
- **Tiền điều kiện / dữ liệu** U-AA1 có đủ quyền lập và quyết định mọi loại đề nghị (vai trò thử).
- **Bước**
  1. Với từng loại đề nghị (kích hoạt NCC, ngừng hẳn NCC, duyệt đối tác, chấm dứt đối tác, hoàn tiền, xử lý chênh lệch, mở lại phiên, đổi chế độ định tuyến, đổi bảng ánh xạ), U-AA1 lập rồi tự duyệt.
- **Mong đợi** Mọi trường hợp `403` ERR-19-033; sự kiện an ninh có `rule = SOD-1`.

#### TC-19-803 · Quy tắc động 2–5 <!--k:sod-2-5-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** Khung §13.4 #2–5 · BR-19-023, 024, 028
- **Tiền điều kiện / dữ liệu** Như các ca TC-19-427, TC-19-433, TC-19-480, TC-19-504.
- **Bước**
  1. Chạy lại phần âm của bốn ca trên với người dùng có nhiều vai trò cùng lúc.
- **Mong đợi** Mọi vi phạm trả `403` ERR-19-033 dù người dùng có đủ quyền; quy tắc 4: yêu cầu hoàn sinh từ chênh lệch không duyệt được bởi người đề xuất chênh lệch.

#### TC-19-804 · Quy tắc động 6: xem dữ liệu cá nhân phải có lý do <!--k:sod-6-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** Khung §13.4 #6 · BR-19-031
- **Tiền điều kiện / dữ liệu** Như TC-19-553.
- **Bước**
  1. Gọi API-19-052, 083 với yêu cầu bản rõ không có lý do.
- **Mong đợi** `400` ERR-19-001; không trả bản rõ; mỗi lần xem có lý do đều có bản ghi kiểm toán.

#### TC-19-805 · Quy tắc tĩnh 7–10 khi gán vai trò <!--k:sod-static-->
- **Loại** Bảo mật · **Ưu tiên** P2 · **Tự động** API (PH-12)
- **Truy vết** Khung §13.4 #7–10
- **Tiền điều kiện / dữ liệu** Quản trị tenant ở PH-12.
- **Bước**
  1. Gán `ROLE-AUDITOR` cùng `ROLE-PAYMENT_OPERATOR` cho một người.
  2. Gán `ROLE-PAYMENT_APPROVER` cùng `ROLE-PAYMENT_ADMIN`.
  3. Gán `ROLE-PARTNER_SYSTEM` cho người; gán `ROLE-PAYMENT_ADMIN` cho client máy.
  4. U-PLA1 đọc giao dịch của T68 không có phiên break-glass; rồi có phiên được duyệt 4 giờ; tiến 4 giờ 1 phút.
- **Mong đợi** Bước 1, 3: PH-12 từ chối. Bước 2: cho phép kèm cảnh báo và bản ghi ngoại lệ. Bước 4: lần đầu `403`; có phiên thì đọc được, mọi thao tác ghi kiểm toán có mã phiên; hết hạn thì `403`.

### TS-19-34 · Chịu lỗi, phục hồi và an toàn dữ liệu

**Mục tiêu.** Xác nhận PH-19 không mất giao dịch, không mất sự kiện khi một thành phần hỏng, dữ liệu tài chính bất biến và đúng kiểu, bí mật không lộ.

**Phủ.** NFR-19-010…017, 022, 024, 026, 027, 028, 030, 031, 032; FR-19-010, 011, 024; LGC-PAY-005, 009, 022, 023.

#### TC-19-826 · Mạch ngắt mở và đóng lại theo NCC <!--k:res-circuit-->
- **Loại** Chịu lỗi · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** NFR-19-012 · FR-19-011, 024 · ERR-19-017 · LGC-PAY-009, 023
- **Tiền điều kiện / dữ liệu** `PGSIM` lỗi 60% trong cửa sổ đo.
- **Bước**
  1. Tạo 100 giao dịch PV-PG.
  2. Cho `PGSIM` phục hồi; chờ hết thời gian nửa mở.
- **Mong đợi** Bước 1: mạch mở; yêu cầu sau đó trả `503` ERR-19-017 ngay (không chờ timeout); NCC hiện "Gián đoạn" ở UI-19-02. Bước 2: lượt thử nửa mở thành công, mạch đóng; trạng thái về "Hoạt động".

#### TC-19-827 · Mất một nút CSDL <!--k:res-db-node-->
- **Loại** Chịu lỗi · **Ưu tiên** P1 · **Tự động** IT (Chaos Mesh)
- **Truy vết** NFR-19-010, 011
- **Tiền điều kiện / dữ liệu** CNPG ba nút, đồng bộ một bản sao; tải 50 giao dịch/giây.
- **Bước**
  1. Xóa pod chính của `pg-payment`.
  2. Sau khi phục hồi, so số giao dịch đã trả `201` với số trong CSDL.
- **Mong đợi** Bước 1: chuyển chính ≤ 15 phút (mục tiêu < 1 phút). Bước 2: không mất giao dịch đã xác nhận (RPO = 0); yêu cầu lỗi trong lúc chuyển được đối tác thử lại nhờ `Idempotency-Key`, không trùng.

#### TC-19-828 · Diễn tập mất site <!--k:res-dr-->
- **Loại** Chịu lỗi · **Ưu tiên** P2 · **Tự động** Thủ công theo 6.3
- **Truy vết** NFR-19-011
- **Tiền điều kiện / dữ liệu** Hai site active–standby theo D03-09.
- **Bước**
  1. Cắt site chính; kích hoạt site dự phòng theo sổ tay.
  2. Đối chiếu giao dịch của 5 phút cuối với nhật ký IPN của `PGSIM`.
- **Mong đợi** RTO ≤ 4 giờ; RPO ≤ 5 phút; giao dịch thiếu được bù bằng truy vấn chủ động và đối soát ngày; dữ liệu phục hồi qua kiểm tra toàn vẹn.

#### TC-19-829 · Bất biến của bảng chỉ ghi thêm <!--k:res-immutable-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** DB
- **Truy vết** NFR-19-016 · FR-19-028 · BR-19-030
- **Tiền điều kiện / dữ liệu** Vai trò `ph19_app`.
- **Bước**
  1. `UPDATE`, `DELETE` trên `transaction_event`, phần nguyên văn của `callback_inbox`, `reconciliation_session` đã `CLOSED`.
  2. `TRUNCATE` bảng `transaction_event`.
- **Mong đợi** Bị từ chối (không có quyền hoặc trigger SQLSTATE P1930); có bản ghi trong log CSDL.


#### TC-19-836 · Thời hạn lưu và phân vùng <!--k:res-retention-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT, DB
- **Truy vết** NFR-19-014, 015 · ADR-047
- **Tiền điều kiện / dữ liệu** Bảng phân vùng theo tháng; bucket `dh-t68-payment-worm`.
- **Bước**
  1. Chạy tác vụ bảo trì phân vùng với đồng hồ giả tiến 13 tháng, rồi 121 tháng.
  2. Đọc cấu hình khóa đối tượng và vòng đời của bucket WORM.
- **Mong đợi** Bước 1: phân vùng `integration_log` quá 12 tháng được tách ra lưu nén, không xóa; phân vùng giao dịch chỉ được đề xuất xóa sau 10 năm và cần phê duyệt. Bước 2: chế độ `COMPLIANCE`, thời hạn giữ ≥ 10 năm cho chứng từ, biên bản.
#### TC-19-830 · Không dùng số thực cho tiền, định dạng hiển thị <!--k:res-money-->
- **Loại** Dương · **Ưu tiên** P1 · **Tự động** UT, E2E, tĩnh
- **Truy vết** NFR-19-017, 030
- **Tiền điều kiện / dữ liệu** Giao dịch 9.007.199.254.740.993 ₫ (vượt `Number.MAX_SAFE_INTEGER`) trong dữ liệu thử UT.
- **Bước**
  1. Quét mã nguồn: ArchUnit cấm `double`, `float`, `BigDecimal` có phần lẻ ở gói `vn.datahub.payment`; ESLint cấm phép tính `Number` trên trường tiền.
  2. Hiển thị giá trị trên ở UI-19-15.
- **Mong đợi** Bước 1: không vi phạm. Bước 2: hiện `9.007.199.254.740.993 ₫` đúng từng chữ số; thời điểm dạng `dd/MM/yyyy HH:mm:ss`.

#### TC-19-831 · Bí mật và dữ liệu cá nhân không lộ, không lưu dữ liệu thẻ <!--k:res-secrets-->
- **Loại** Bảo mật · **Ưu tiên** P1 · **Tự động** IT
- **Truy vết** NFR-19-022, 024 · BR-19-032 · FR-19-024, 054 · LGC-PAY-022
- **Tiền điều kiện / dữ liệu** Sau khi chạy toàn bộ TS-19-01…29.
- **Bước**
  1. Quét log ứng dụng, `integration_log`, sự kiện Kafka, CSDL bằng bộ mẫu (chuỗi bí mật thử, số thẻ dạng Luhn, họ tên, điện thoại bản rõ của dữ liệu thử).
  2. Kiểm cột dữ liệu cá nhân trong `transaction`.
- **Mong đợi** Bước 1: không khớp mẫu nào. Bước 2: cột ở dạng mã hóa `vault:v1:…`; giải mã chỉ được bằng khóa Transit của đúng tenant.

#### TC-19-832 · Triển khai cuốn chiếu không gián đoạn <!--k:res-rolling-->
- **Loại** Chịu lỗi · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** NFR-19-031, 010
- **Tiền điều kiện / dữ liệu** Tải 50 giao dịch/giây; bản mới có một thay đổi Liquibase mở rộng.
- **Bước**
  1. Triển khai bản mới.
- **Mong đợi** Không yêu cầu nào lỗi do triển khai; bản cũ và mới cùng chạy trên lược đồ mới trong lúc chuyển.

#### TC-19-833 · Thêm NCC mới chỉ bằng adapter; hợp đồng bộ giả lập <!--k:res-adapter-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** NFR-19-027, 032 · FR-19-010 · LGC-PAY-005
- **Tiền điều kiện / dữ liệu** Adapter mẫu `DemoBankAdapter` trong mã thử.
- **Bước**
  1. Đăng ký adapter mẫu; tạo NCC dùng adapter đó; chạy luồng khởi tạo, IPN, truy vấn.
  2. Chạy kiểm thử hợp đồng của `PGSIM` với OpenAPI và AsyncAPI.
- **Mong đợi** Bước 1 chạy đủ mà không đổi mã lõi, lược đồ, API đối tác (ArchUnit xác nhận phụ thuộc một chiều). Bước 2 đạt.

#### TC-19-834 · Lệch đồng hồ và ngày giao dịch theo giờ Việt Nam <!--k:res-clock-->
- **Loại** Dương · **Ưu tiên** P2 · **Tự động** IT
- **Truy vết** NFR-19-028 · BR-19-025
- **Tiền điều kiện / dữ liệu** Giao dịch thành công lúc 23:59:59 và 00:00:01 giờ Việt Nam.
- **Bước**
  1. Chạy phiên đối soát ngày D.
- **Mong đợi** Giao dịch 23:59:59 thuộc ngày D, 00:00:01 thuộc D+1 (tính theo UTC+7); cảnh báo khi độ lệch NTP > 1 s.

#### TC-19-835 · Vết đầu-cuối và lấy mẫu <!--k:res-trace-->
- **Loại** Dương · **Ưu tiên** P3 · **Tự động** IT
- **Truy vết** NFR-19-026 · FR-19-055
- **Tiền điều kiện / dữ liệu** Một giao dịch thất bại.
- **Bước**
  1. Tìm `trace_id` của giao dịch ở PH-13.
- **Mong đợi** Có đủ chặng: APISIX, `dh-payment` api, gọi NCC, IPN, worker, webhook; vết lỗi được giữ 100%.

## 6. Thủ tục kiểm thử thủ công

### 6.1. Kiểm thử khám phá theo phiên

Mỗi đợt có bốn phiên 90 phút, mỗi phiên một chủ đề: (1) kế toán đi hết một ngày làm việc gồm đối soát, chênh lệch, hoàn tiền; (2) vận hành xử lý giao dịch treo và IPN cách ly; (3) người nộp trên điện thoại yếu mạng, gián đoạn giữa chừng; (4) kẻ tấn công nội bộ có một vai trò, tìm cách vượt tách nhiệm. Ghi chép theo mẫu phiên của D05-01; lỗi tìm được thành ca tự động mới trong dải dự phòng của kịch bản tương ứng.

### 6.2. Diễn tập chuyển đối tác từ hệ cũ

Trên UAT, với một đối tác thật của tỉnh thí điểm (giả định: hệ thống DVC của tỉnh, GĐ-02): nhập dữ liệu hệ cũ (TC-19-701), chạy `SHADOW` một tuần, so sánh, chuyển `DATAHUB`, quay lui về `LEGACY` một lần, rồi chuyển lại. Biên bản ghi số giao dịch hai phía, số lệch và nguyên nhân, thời gian mỗi bước.

### 6.3. Diễn tập sự cố

Ba tình huống mỗi đợt: PayGov ngừng 30 phút (TC-19-826), Kafka ngừng 20 phút (TC-19-657), mất site (TC-19-828, mỗi năm một lần). Người trực vận hành làm theo sổ tay D04; người quan sát ghi thời gian phát hiện, thời gian khôi phục, giao dịch bị ảnh hưởng.

### 6.4. Kiểm thử truy cập thủ công

Theo A11Y-19-01…06 của D03-06-PH19: đi hết UI-19-14, 15, 18, 20 chỉ bằng bàn phím; đọc bằng NVDA tiếng Việt; phóng to 200%; chế độ tương phản cao; trang UI-19-28 trên điện thoại 360 px với TalkBack. Đạt khi không còn lỗi mức A, AA.

## 7. Nghiệm thu người dùng tương đương PayGov trung gian

Cán bộ vận hành và kế toán đang dùng phân hệ thanh toán trung gian cũ của tỉnh thí điểm tự thực hiện trên UAT. Mỗi kịch bản đạt khi người thực hiện làm được không cần hướng dẫn ngoài tài liệu người dùng, và kết quả bằng hoặc tốt hơn hệ cũ.

| Mã | Việc cần làm | Chức năng hệ cũ | Kết quả mong đợi | FR | TC tự động |
|---|---|---|---|---|---|
| UAT-01 | Thêm nhà cung cấp thanh toán, nhập thông tin kết nối, kiểm tra kết nối | LGC-PAY-001, 004, 007 | Làm được như hệ cũ, thêm bước kiểm tra kết nối, không phải nhập bí mật vào màn hình | FR-19-001, 002, 003, 004, 005 | TS-19-01, 02, 03 |
| UAT-02 | Đưa nhà cung cấp vào hoạt động qua phê duyệt | LGC-PAY-005, 008 | Người thứ hai duyệt; checklist cho biết còn thiếu gì | FR-19-006, 010 | TS-19-04 |
| UAT-03 | Tạm ngừng, cho hoạt động lại nhà cung cấp; xem tình trạng kênh | LGC-PAY-002, 003, 006, 009 | Đổi trạng thái có lý do; tình trạng kết nối hiện trong 1 phút | FR-19-007, 008, 011 | TS-19-05, 06 |
| UAT-04 | Khai nhóm dịch vụ và dịch vụ thu, gắn mã thủ tục | LGC-PAY-022 | Làm được như hệ cũ; mã thủ tục, cơ quan thu chọn từ danh mục dùng chung | FR-19-013, 014, 015 | TS-19-07, 08 |
| UAT-05 | Đăng ký hệ thống đối tác, gán dịch vụ, đặt hạn mức | LGC-PAY-022 | Đối tác nhận thông tin client và hướng dẫn tích hợp | FR-19-017, 018, 020 | TS-19-09, 10 |
| UAT-06 | Người nộp thanh toán một lệ phí trên điện thoại và quay về | LGC-PAY-012, 024 | Hoàn tất dưới 3 phút; trang kết quả rõ ràng, không lộ thông tin cá nhân | FR-19-022, 025 | TS-19-11, 12 |
| UAT-07 | Tra cứu giao dịch theo mã, theo người nộp, theo khoảng thời gian | LGC-PAY-014, 015, 016, 017, 018 | Tìm thấy trong 3 thao tác, có đủ chín cột như hệ cũ | FR-19-049, 050 | TS-19-22 |
| UAT-08 | Xem chi tiết giao dịch và lịch sử trao đổi với ngân hàng | LGC-PAY-010, 011, 019, 021 | Đủ thông tin như hệ cũ, thêm dòng thời gian và mở vết | FR-19-028, 051, 054 | TS-19-13, 23, 24 |
| UAT-09 | Xử lý một giao dịch treo: đồng bộ, xem IPN cách ly | LGC-PAY-010 | Biết vì sao giao dịch treo và xử lý được không cần đội kỹ thuật | FR-19-032, 036, 037 | TS-19-16 |
| UAT-10 | Đối soát một ngày, xử lý chênh lệch, chốt phiên, in biên bản | LGC-PAY-019 | Hệ cũ không có; kế toán chốt được trong một buổi với 1% chênh lệch | FR-19-042…048 | TS-19-19, 20, 21 |
| UAT-11 | Lập, duyệt, ghi nhận một yêu cầu hoàn tiền | LGC-PAY-025 | Hệ cũ chỉ có trạng thái; nay đi hết quy trình với ba người | FR-19-038, 039, 040, 041 | TS-19-17, 18 |
| UAT-12 | Xem hai dashboard và báo cáo tháng | LGC-PAY-013, 020, 023, 026 | Đủ chỉ tiêu như hệ cũ; số liệu mới trong 1 phút thay vì 10 phút | FR-19-056, 057, 058 | TS-19-25, 26 |

## 8. Ma trận truy vết

<!-- gen:matrix:start -->
### 8.1. Yêu cầu chức năng → test case

Cột "Dương", "Âm" liệt kê ba chữ số cuối của mã TC-19 (ca bảo mật tính là ca âm). FR mức M phải có ít nhất một ca ở mỗi cột; bảng sinh bằng `ph19/tools/gen_matrix.py` nên luôn khớp với mục 4 và 5.

| FR | Tên | Mức · phát hành | LGC | Dương | Âm | Ca khác | Đạt quy tắc |
|---|---|---|---|---|---|---|---|
| FR-19-001 | Khai báo nhà cung cấp | M · MVP | LGC-PAY-001 | 001 | 002, 003 | — | Có |
| FR-19-002 | Gắn thông tin xác thực nhà cung cấp | M · MVP | LGC-PAY-001, LGC-PAY-004 | 004 | 005 | — | Có |
| FR-19-003 | Kiểm tra kết nối nhà cung cấp | M · MVP | LGC-PAY-001, LGC-PAY-007 | 026 | 027 | — | Có |
| FR-19-004 | Thực hiện giao dịch thử | M · MVP | LGC-PAY-001, LGC-PAY-007 | 028 | 029 | — | Có |
| FR-19-005 | Kích hoạt nhà cung cấp có phê duyệt | M · MVP | LGC-PAY-001, LGC-PAY-007 | 051, 053, 055 | 052, 054, 081 | — | Có |
| FR-19-006 | Tạm dừng và mở lại nhà cung cấp | M · MVP | LGC-PAY-008 | 076, 077 | 077, 081 | — | Có |
| FR-19-007 | Danh sách, tìm kiếm, sắp xếp nhà cung cấp | M · MVP | LGC-PAY-002, LGC-PAY-006 | 101 | 107 | — | Có |
| FR-19-008 | Xem chi tiết nhà cung cấp | M · MVP | LGC-PAY-003 | 102 | 107 | — | Có |
| FR-19-009 | Chỉnh sửa nhà cung cấp | M · MVP | LGC-PAY-004 | 103, 104 | 003, 104, 105 | — | Có |
| FR-19-010 | Xóa hoặc ngừng hẳn nhà cung cấp | M · MVP | LGC-PAY-005 | 078, 080, 833 | 079, 081 | — | Có |
| FR-19-011 | Giám sát sức khỏe và cảnh báo lỗi kết nối | M · MVP | LGC-PAY-009, LGC-PAY-023 | 126, 129 | 127, 129 | 785, 826 | Có |
| FR-19-012 | Xoay khóa và chứng thư nhà cung cấp | S · Đ2b (MVP thay khóa bằng FR-19-002 kèm kiểm tra kết nối; nhắc hạn có từ MVP qua FR-19-059) | mới | 128, 129 | 129 | — | Có |
| FR-19-069 | Quản lý bảng ánh xạ mã kết quả nhà cung cấp (đề xuất) | M · MVP | mới | 106 | 106 | — | Có |
| FR-19-013 | Quản lý nhóm dịch vụ | M · MVP | LGC-PAY-022 | 151 | 152 | — | Có |
| FR-19-014 | Quản lý dịch vụ thanh toán | M · MVP | LGC-PAY-022 | 176 | 177 | — | Có |
| FR-19-015 | Điều khiển vòng đời dịch vụ | M · MVP | LGC-PAY-022 | 178 | 179, 180 | — | Có |
| FR-19-016 | Kiểm tra và đồng bộ mã danh mục PH-07 | S · MVP (kiểm tra khi ghi và tra cứu cho biểu mẫu); phần lắng nghe sự kiện danh mục thay đổi cũng thuộc MVP vì là điều kiện của BR-19-009 | mới | — | 152, 177, 179 | — | Có |
| FR-19-017 | Quản lý hồ sơ đối tác | M · MVP | LGC-PAY-022 | 201 | 207 | — | Có |
| FR-19-018 | Điều khiển vòng đời đối tác | M · MVP | LGC-PAY-022 | 202, 204, 206 | 203, 205 | — | Có |
| FR-19-019 | Cấp và thu hồi client của đối tác | M · MVP | mới | 206, 226 | 227 | — | Có |
| FR-19-020 | Gán dịch vụ và hạn mức cho đối tác | M · MVP | LGC-PAY-022 | 228 | 228 | — | Có |
| FR-19-021 | Cấu hình webhook của đối tác | M · MVP | mới | 229 | 230 | — | Có |
| FR-19-022 | Tạo giao dịch thanh toán | M · MVP | LGC-PAY-011, LGC-PAY-024 | 251 | 252 | 258 | Có |
| FR-19-023 | Kiểm tra hợp lệ yêu cầu thanh toán | M · MVP | LGC-PAY-024 | 251 | 252 | — | Có |
| FR-19-024 | Khởi tạo thanh toán tại nhà cung cấp qua adapter | M · MVP | LGC-PAY-023, LGC-PAY-024 | 251 | 127, 256, 257, 831 | 826 | Có |
| FR-19-025 | Xử lý người nộp quay về | M · MVP | LGC-PAY-012, LGC-PAY-024 | 276 | 277, 278 | — | Có |
| FR-19-026 | Hủy giao dịch chưa thanh toán | S · Đ2b (MVP: giao dịch không thanh toán tự hết hạn theo FR-19-027; đối tác cần thu lại thì tạo giao dịch mới sau khi giao dịch cũ hết hạn) | mới | 326 | 327 | — | Có |
| FR-19-027 | Tự động hết hạn giao dịch | M · MVP | mới | 328 | 329 | — | Có |
| FR-19-028 | Ghi lịch sử trạng thái bất biến | M · MVP | LGC-PAY-011, LGC-PAY-019 | 251, 301 | 829 | — | Có |
| FR-19-029 | Tiếp nhận và xác minh IPN | M · MVP | LGC-PAY-010 | 301 | 726 | — | Có |
| FR-19-030 | Xử lý IPN đúng một lần | M · MVP | LGC-PAY-010 | 301, 302 | 303 | — | Có |
| FR-19-031 | Cách ly IPN bất thường | M · MVP | LGC-PAY-010 | 305 | 304, 306 | — | Có |
| FR-19-032 | Xem và xử lý lại IPN | S · Đ2b cho xử lý lại; xem danh sách và chi tiết thuộc MVP | LGC-PAY-010 | 379 | 379 | — | Có |
| FR-19-033 | Bảo đảm idempotency theo `Idempotency-Key` | M · MVP | LGC-PAY-024 | 253 | 254 | — | Có |
| FR-19-034 | Chống trùng theo mã đơn hàng của đối tác | M · MVP | LGC-PAY-024 | 255 | 255 | — | Có |
| FR-19-035 | Đối tác truy vấn trạng thái giao dịch | M · MVP | mới | 351, 353 | 352 | — | Có |
| FR-19-036 | Chủ động truy vấn nhà cung cấp cho giao dịch treo | M · MVP | mới | 376 | 257, 277 | — | Có |
| FR-19-037 | Đồng bộ trạng thái thủ công | S · Đ2b (MVP dựa vào truy vấn tự động và đối soát) | mới | 377 | 378 | — | Có |
| FR-19-038 | Lập yêu cầu hoàn tiền | M · MVP | LGC-PAY-025 | 401, 402, 432 | 403 | — | Có |
| FR-19-039 | Phê duyệt hoặc từ chối hoàn tiền | M · MVP | LGC-PAY-025 | 426, 427 | 427 | — | Có |
| FR-19-040 | Thực thi hoàn tiền | M · MVP với chế độ `MANUAL`; chế độ `API` thuộc Đ2b khi OQ-19-06 xác nhận | LGC-PAY-025 | 428, 430 | 431, 433 | — | Có |
| FR-19-041 | Theo dõi kết quả hoàn tiền | M · MVP | LGC-PAY-025 | 428, 429, 430 | 431 | — | Có |
| FR-19-042 | Lập lịch và khởi tạo phiên đối soát | M · MVP | mới | 451 | 455 | — | Có |
| FR-19-043 | Thu thập dữ liệu đối soát của nhà cung cấp | M · MVP | mới | 451, 453 | 452, 453 | — | Có |
| FR-19-044 | So khớp tự động | M · MVP | mới | 451, 454, 481 | 456 | 783 | Có |
| FR-19-045 | Quản lý bản ghi chênh lệch | M · MVP | mới | 454, 476, 477, 481 | 480 | — | Có |
| FR-19-046 | Đề xuất và phê duyệt xử lý chênh lệch | M · MVP | mới | 478, 479 | 480 | — | Có |
| FR-19-047 | Chốt và mở lại phiên đối soát | M · MVP | mới | 501, 504 | 502, 503, 504 | — | Có |
| FR-19-048 | Xuất biên bản và cung cấp kết quả đối soát | S · MVP cho biên bản; API tải kết quả của đối tác (API-19-107) thuộc Đ2b | mới | 501, 505 | 505 | — | Có |
| FR-19-049 | Danh sách giao dịch, tìm theo từ khóa | M · MVP | LGC-PAY-014, LGC-PAY-018 | 526 | 528 | — | Có |
| FR-19-050 | Tra cứu nâng cao | M · MVP | LGC-PAY-015, LGC-PAY-016, LGC-PAY-017 | 527 | 528 | — | Có |
| FR-19-051 | Xem chi tiết giao dịch | M · MVP | LGC-PAY-019 | 551, 552 | 553 | — | Có |
| FR-19-052 | Xuất danh sách giao dịch | S · Đ2b (MVP chỉ xuất báo cáo tổng hợp và biên bản đối soát) | mới | 529 | 530 | 784 | Có |
| FR-19-053 | Ghi nhật ký kiểm toán | M · MVP | LGC-PAY-021 | 576 | 577 | — | Có |
| FR-19-054 | Nhật ký tích hợp giao dịch | M · MVP | LGC-PAY-011, LGC-PAY-021 | 578 | 579, 831 | — | Có |
| FR-19-055 | Liên kết truy vết đầu-cuối | S · MVP | LGC-PAY-021 | 551, 578, 835 | — | — | Có |
| FR-19-056 | Dashboard tổng quan | M · MVP | LGC-PAY-013, LGC-PAY-026 | 601, 602 | 604 | — | Có |
| FR-19-057 | Dashboard kênh thanh toán | M · MVP | LGC-PAY-003, LGC-PAY-020, LGC-PAY-023 | 603 | 604 | — | Có |
| FR-19-058 | Báo cáo định kỳ và xuất | S · Đ2b; lập lịch gửi tự động thuộc giai đoạn sau | mới | 626, 627 | 628 | — | Có |
| FR-19-059 | Phát chỉ số vận hành và cảnh báo | M · MVP | LGC-PAY-009 | 126, 129, 605 | 129 | — | Có |
| FR-19-060 | Gửi webhook kết quả có ký | M · MVP | LGC-PAY-012 | 301, 353, 651, 653 | 652, 730 | 780 | Có |
| FR-19-061 | Phát sự kiện qua outbox | M · MVP | LGC-PAY-012 | 653 | 657 | — | Có |
| FR-19-062 | Theo dõi và gửi lại webhook | S · MVP | LGC-PAY-012 | 654, 655 | 652, 656 | — | Có |
| FR-19-063 | Cấu hình thanh toán của tenant | M · MVP | mới | 676 | 677 | — | Có |
| FR-19-064 | Khởi tạo và tạm ngừng phân hệ theo tenant | M · MVP | mới | 678 | 679 | — | Có |
| FR-19-065 | Nhập danh mục và giao dịch lịch sử từ hệ cũ | M · MVP | LGC-PAY-011, LGC-PAY-022 | 701 | 702, 703 | — | Có |
| FR-19-066 | Chuyển chế độ định tuyến theo đối tác | M · MVP | mới | 704, 706 | 705 | — | Có |
| FR-19-067 | Lớp tương thích API hệ cũ | C · Sau (chỉ làm khi OQ-19-17 xác nhận cần) | LGC-PAY-024 | 708 | — | — | Có |
| FR-19-068 | Đối chiếu sau di trú | M · MVP | mới | 704, 707 | 709 | — | Có |

### 8.2. Chức năng hệ cũ → yêu cầu → test case

Mỗi chức năng của khối Payment hệ cũ (`LGC-PAY`, D00-03 §4.6) được truy tới FR mới, tới ca tự động và ca nghiệm thu. Đây là bằng chứng "không mất chức năng" cho hội đồng.

| LGC | FR | TC tự động | UAT |
|---|---|---|---|
| LGC-PAY-001 | 001, 002, 003, 004, 005 | 001, 004, 026, 028, 051, 053, 055, 776 | UAT-01 |
| LGC-PAY-002 | 007 | 101 | UAT-03 |
| LGC-PAY-003 | 008, 057 | 102, 603 | UAT-03 |
| LGC-PAY-004 | 002, 009 | 004, 103, 104 | UAT-01 |
| LGC-PAY-005 | 010 | 078, 080, 833 | UAT-02 |
| LGC-PAY-006 | 007 | 101 | UAT-03 |
| LGC-PAY-007 | 003, 004, 005 | 026, 028, 051, 053, 055 | UAT-01 |
| LGC-PAY-008 | 006 | 076, 077 | UAT-02 |
| LGC-PAY-009 | 011, 059 | 126, 129, 605, 826 | UAT-03 |
| LGC-PAY-010 | 029, 030, 031, 032 | 301, 302, 305, 379, 726, 778 | UAT-08, UAT-09 |
| LGC-PAY-011 | 022, 028, 054, 065 | 251, 301, 578, 701 | UAT-08 |
| LGC-PAY-012 | 025, 060, 061, 062 | 276, 301, 353, 651, 653, 654, 655 | UAT-06 |
| LGC-PAY-013 | 056 | 601, 602 | UAT-12 |
| LGC-PAY-014 | 049 | 526, 782 | UAT-07 |
| LGC-PAY-015 | 050 | 527 | UAT-07 |
| LGC-PAY-016 | 050 | 527 | UAT-07 |
| LGC-PAY-017 | 050 | 527 | UAT-07 |
| LGC-PAY-018 | 049 | 526 | UAT-07 |
| LGC-PAY-019 | 028, 051 | 251, 301, 551, 552 | UAT-08, UAT-10 |
| LGC-PAY-020 | 057 | 603 | UAT-12 |
| LGC-PAY-021 | 053, 054, 055 | 551, 576, 578, 835 | UAT-08 |
| LGC-PAY-022 | 013, 014, 015, 017, 018, 020, 065 | 151, 176, 178, 201, 202, 204, 206, 228 (+2) | UAT-04, UAT-05 |
| LGC-PAY-023 | 011, 024, 057 | 126, 129, 251, 603, 826 | UAT-12 |
| LGC-PAY-024 | 022, 023, 024, 025, 033, 034, 067 | 251, 253, 255, 276, 708 | UAT-06 |
| LGC-PAY-025 | 038, 039, 040, 041 | 401, 402, 426, 427, 428, 429, 430, 432 | UAT-11 |
| LGC-PAY-026 | 056 | 601, 602, 781 | UAT-12 |

### 8.3. Quy tắc nghiệp vụ → test case

| Mã | Test case |
|---|---|
| BR-19-001 | 177, 252, 258 |
| BR-19-002 | 251 |
| BR-19-003 | 251 |
| BR-19-004 | 252 |
| BR-19-005 | 228, 256 |
| BR-19-006 | 253, 254 |
| BR-19-007 | 255 |
| BR-19-008 | 176 |
| BR-19-009 | 076, 178, 179 |
| BR-19-010 | 029, 051, 052, 054, 129 |
| BR-19-011 | 053, 054, 055, 078, 106, 202, 203, 206, 427, 478 (+1) |
| BR-19-012 | 256, 257 |
| BR-19-013 | 127 |
| BR-19-014 | 277, 278, 478 |
| BR-19-015 | 106, 301, 304, 306 |
| BR-19-016 | 257, 376 |
| BR-19-017 | 328, 329 |
| BR-19-018 | 305 |
| BR-19-019 | 326, 327 |
| BR-19-020 | 652, 655 |
| BR-19-021 | 353, 653 |
| BR-19-022 | 401, 403, 429 |
| BR-19-023 | 426, 427, 803 |
| BR-19-024 | 428, 430, 433, 803 |
| BR-19-025 | 451, 452, 456, 834 |
| BR-19-026 | 104, 128 |
| BR-19-027 | 078, 079, 178, 180 |
| BR-19-028 | 454, 456, 481, 504, 803 |
| BR-19-029 | 576, 577 |
| BR-19-030 | 476, 503, 829 |
| BR-19-031 | 529, 552, 804 |
| BR-19-032 | 831 |
| BR-19-033 | 028, 403, 456 |
| BR-19-034 | 456, 704, 705 |

### 8.4. Mã lỗi → test case

| Mã | Test case |
|---|---|
| ERR-19-001 | 002, 003, 005, 029, 055, 107, 177, 205, 252, 258 (+10) |
| ERR-19-002 | 252, 254 |
| ERR-19-003 | 254 |
| ERR-19-004 | 254 |
| ERR-19-005 | 204, 252 |
| ERR-19-006 | 252, 705 |
| ERR-19-007 | 252 |
| ERR-19-008 | 178, 179, 252 |
| ERR-19-009 | 252 |
| ERR-19-010 | 252, 258 |
| ERR-19-011 | 252 |
| ERR-19-012 | 228, 252 |
| ERR-19-013 | 228, 252 |
| ERR-19-014 | 252 |
| ERR-19-015 | 252, 255 |
| ERR-19-016 | 207, 252 |
| ERR-19-017 | 076, 127, 826 |
| ERR-19-018 | 256 |
| ERR-19-019 | 127, 257 |
| ERR-19-020 | 080, 107, 327, 352, 505, 529, 553, 579, 628, 729 (+1) |
| ERR-19-021 | 029, 077, 081, 105, 179, 203, 205, 207, 327, 379 (+5) |
| ERR-19-022 | 005, 027 |
| ERR-19-023 | 378 |
| ERR-19-024 | 128, 726, 729 |
| ERR-19-025 | 727 |
| ERR-19-026 | 728 |
| ERR-19-027 | 729 |
| ERR-19-028 | 304 |
| ERR-19-029 | 403 |
| ERR-19-030 | 403 |
| ERR-19-031 | 403 |
| ERR-19-032 | 403 |
| ERR-19-033 | 054, 106, 203, 427, 432, 433, 480, 504, 705, 802 (+1) |
| ERR-19-034 | 055 |
| ERR-19-035 | 052, 054, 705 |
| ERR-19-036 | 079, 180 |
| ERR-19-037 | 079, 152, 180 |
| ERR-19-038 | 002, 152, 207 |
| ERR-19-039 | 152, 177, 179, 207 |
| ERR-19-040 | 455 |
| ERR-19-041 | 453 |
| ERR-19-042 | 502 |
| ERR-19-043 | 503 |
| ERR-19-044 | 230 |
| ERR-19-045 | 105, 207, 480, 656, 677 |
| ERR-19-046 | 002, 005, 054, 107, 205, 378, 528, 530, 553, 579 (+6) |
| ERR-19-047 | 530 |
| ERR-19-048 | 756 |
| ERR-19-049 | 252, 679 |
| ERR-19-050 | 577 |
| ERR-19-099 | — |

### 8.5. Yêu cầu phi chức năng → test case

| Mã | Test case |
|---|---|
| NFR-19-001 | 776 |
| NFR-19-002 | 777, 786 |
| NFR-19-003 | 778 |
| NFR-19-004 | 779 |
| NFR-19-005 | 651, 780 |
| NFR-19-006 | 602, 781 |
| NFR-19-007 | 782 |
| NFR-19-008 | 783 |
| NFR-19-009 | 627, 784 |
| NFR-19-010 | 827, 832 |
| NFR-19-011 | 827, 828 |
| NFR-19-012 | 127, 785, 826 |
| NFR-19-013 | 657, 786 |
| NFR-19-014 | 836 |
| NFR-19-015 | 576, 836 |
| NFR-19-016 | 503, 829 |
| NFR-19-017 | 258, 703, 830 |
| NFR-19-018 | 732 |
| NFR-19-019 | 226, 227, 731 |
| NFR-19-020 | 278, 726, 727, 728, 729 |
| NFR-19-021 | 229, 651, 730 |
| NFR-19-022 | 004, 005, 754, 831 |
| NFR-19-023 | 733 |
| NFR-19-024 | 552, 831 |
| NFR-19-025 | 005, 352, 604, 678, 751, 752, 753, 754, 755, 756 |
| NFR-19-026 | 605, 835 |
| NFR-19-027 | 833 |
| NFR-19-028 | 727, 834 |
| NFR-19-029 | 276, 526 |
| NFR-19-030 | 526, 830 |
| NFR-19-031 | 832 |
| NFR-19-032 | 833 |
<!-- gen:matrix:end -->

## 9. Tự động hóa

### 9.1. Tổ chức mã kiểm thử

| Thư mục | Nội dung |
|---|---|
| `apps/payment/src/test/java/vn/datahub/payment/` | UT, IT theo package; lớp cơ sở `PaymentTestBase` dựng Testcontainers PostgreSQL, Kafka, Valkey, OpenBao dev |
| `apps/payment/src/test/java/vn/datahub/payment/arch/` | Luật ArchUnit: lõi không phụ thuộc adapter, cấm số thực cho tiền |
| `apps/payment/src/testFixtures/java/…/pgsim/` | Bộ giả lập PayGov `PGSIM` (WireMock mở rộng): khởi tạo, IPN, truy vấn, hoàn, file đối soát, các chế độ lỗi |
| `apps/payment/src/test/resources/db/` | Ca DB chạy bằng pgTAP: RLS, trigger bất biến |
| `apps/console/src/features/payment/**/*.test.tsx` | UT frontend (Vitest, Testing Library) |
| `e2e/payment/*.spec.ts` | Playwright; tệp theo kịch bản `ts-19-nn.spec.ts`; `@axe-core/playwright` cho truy cập |
| `perf/payment/*.js` | k6 cho TS-19-32 |
| `chaos/payment/*.yaml` | Chaos Mesh cho TS-19-27, 34 |
| `datahub-docs/05-kiem-thu/test-case/ph19/gherkin/` | Gherkin sinh từ tài liệu này |

Mỗi ca tự động mang thẻ mã ca (`@Tag("TC-19-301")`, `test('TC-19-301 …')`) để báo cáo đối chiếu với ma trận. CI chạy UT, IT, API, DB ở mọi PR (cổng CI-3, CI-4 của D04-02); E2E, ZAP ở nhánh chính hằng đêm; k6, Chaos trước mỗi bản phát hành.

### 9.2. Mẫu ca IPN chạy đồng thời (JUnit, REST Assured)

```java
@Tag("TC-19-303")
@Test
void ipnLapDongThoiChiXuLyMotLan() throws Exception {
    var tx = fixtures.pendingTransaction(T68, P_DVC, 1_250_000L);
    var ipn = pgsim.signedIpn(tx, "00", 1_250_000L);           // cùng nonce, cùng nội dung
    try (var pool = Executors.newFixedThreadPool(20)) {
        var calls = IntStream.range(0, 20)
            .mapToObj(i -> pool.submit(() -> callback.post(tx.connectionKey(), ipn)))
            .toList();
        for (var c : calls) c.get().then().statusCode(200);
    }
    await().atMost(5, SECONDS).untilAsserted(() -> {
        assertThat(db.inboxStatuses(ipn.nonce())).containsExactlyInAnyOrder(
            concat(List.of("PROCESSED"), nCopies(19, "DUPLICATE")).toArray(String[]::new));
        assertThat(db.transitions(tx.id())).extracting("toStatus").containsExactly("PENDING", "SUCCEEDED");
        assertThat(whsink.received(P_DVC, tx.code())).hasSize(1);
    });
}
```

### 9.3. Mẫu ca tách nhiệm hoàn tiền (JUnit)

```java
@Tag("TC-19-433")
@Test
void nguoiDaDuyetKhongDuocGhiNhanDaHoan() {
    var refund = flows.refundAwaitingManual(T68, U_ACC1, /* duyệt bởi */ U_APR1);
    iam.grantTemporary(U_APR1, "PERM-19-refund-execute");
    admin.as(U_APR1)
        .body(Map.of("action", "RECORD_MANUAL", "voucherNo", "UNC-01", "voucherFileId", files.voucher()))
        .header("If-Match", refund.etag())
        .post("/refunds/{id}/executions", refund.id())
        .then().statusCode(403)
        .body("code", equalTo("ERR-19-033"));
    assertThat(db.refund(refund.id()).status()).isEqualTo("AWAITING_MANUAL");
}
```

Số TC trong các mẫu ở mục này khớp với mục 4.

### 9.4. Mẫu ca trang kết quả (Playwright)

```ts
test('TC-19-277 quay về trước IPN không đổi trạng thái', async ({ page, api }) => {
  const tx = await api.pendingTransaction('T68', 'P-DVC');
  await page.setViewportSize({ width: 360, height: 740 });
  await page.goto(await pgsim.returnUrl(tx, { claimSuccess: true }));
  await expect(page.getByRole('heading')).toHaveText(/Đang xác nhận kết quả/);
  await page.waitForTimeout(20_000);
  await expect(page.getByText('Bạn không cần thanh toán lại')).toBeVisible();
  expect((await api.adminGetTransaction(tx.id)).status).toBe('PENDING');
  expect(await new AxeBuilder({ page }).analyze()).toHaveNoCriticalViolations();
});
```

### 9.5. Sinh ma trận, Gherkin, bảng tính

`ph19/tools/` có bốn script, chạy từ thư mục `05-kiem-thu/test-case/ph19/tools`:

- `number_tcs.py`: cấp số TC-19-nnn cho ca mới (viết tạm là `TC-19-` và ba dấu thăng). Khác PH-04, số được cấp **trong dải của từng kịch bản** theo khung §14 (TS-19-nn dùng 25×(nn−1)+1 … 25×nn). Thay mọi tham chiếu `[[tc:khóa]]` bằng số. Số đã cấp không đổi; báo lỗi nếu một kịch bản vượt 25 ca.
- `gen_matrix.py`: sinh mục 8, bảng kịch bản ở mục 3.1 và phần tóm tắt; kiểm quy tắc phủ của khung §14 (mỗi FR mức M có ca dương và ca âm, mỗi BR, ERR, NFR có ít nhất một ca).
- `gen_gherkin.py`: sinh `ph19/gherkin/*.feature`.
- `gen_xlsx.py`: sinh `ph19/D05-02-PH19-test-case.xlsx` cho đội kiểm thử ghi kết quả.

Các script dùng chung `tc_parse.py`, cùng cách làm với PH-04 và PH-07.

## 10. Câu hỏi mở và giả định

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| OQ-19-40 | VPCP có cấp môi trường thử nghiệm PayGov cho tỉnh để chạy một phần TS-19-11…13 với hệ thật không | Chưa; mọi ca dùng `PGSIM`. Khi có môi trường thật, chạy lại TS-19-11, 13, 16, 19 với nhãn `paygov-sandbox` trước RG-3 |
| OQ-19-41 | Lịch thử lại webhook BR-19-021 có cần khớp với khuyến nghị nào của đối tác lớn (DVC quốc gia) không | Giữ lịch của BR-19-021; ca TC-19-652 đọc lịch từ cấu hình nên đổi không phải sửa ca |
| OQ-19-42 | Tỉnh thí điểm có đủ ba cán bộ khác nhau (lập, duyệt cấp 1, duyệt cấp 2) để chạy UAT-11 | Giả định có; nếu thiếu, dùng cán bộ Sở Tài chính làm người duyệt cấp 2 |
| OQ-19-43 | Dữ liệu hệ cũ thật cho TC-19-703 (các kiểu lỗi đã gặp) | Giả định theo phân tích lược đồ hệ cũ ở D00-03 §4.6: số tiền `int`, `pay_date` chuỗi, trạng thái số |
| GĐ-TC-01 | Giới hạn xuất 1.000.000 dòng quá lớn để thử chức năng ở SIT | SIT hạ giới hạn bằng tham số kiểm thử; giới hạn thật đo ở TC-19-784 trên PERF |

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-26 | Bản đầu: 34 kịch bản, <!-- gen:count:start -->187<!-- gen:count:end --> ca, 12 UAT, mẫu tự động hóa, công cụ sinh ma trận theo dải số của khung §14 |
