---
ma_tai_lieu: D00-03-01
ten: Sổ đồng bộ chéo cuối bộ tài liệu Datahub
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, chủ đầu tư, kiến trúc sư, trưởng nhóm phân hệ
mo_ta: Kết luận cho từng đề nghị đồng bộ mà các tập tài liệu đã gom về đợt đồng bộ cuối, quyết định đặt tên áp chung và câu hỏi mở còn chờ người chốt.
tai_lieu_lien_quan: D00-03 Ma trận truy vết; D00-04 Sổ tra cứu gọn; D00-02 Sổ ADR; D02-08 Ma trận phân quyền; mọi tập D02-03…D05-02 của 20 phân hệ
---

# D00-03-01 · Sổ đồng bộ chéo cuối

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Trong khi viết song song 20 phân hệ và các tài liệu chung, mỗi tập ghi lại ở phụ lục "Đề nghị đồng bộ" những chỗ cần sửa ở tập khác thay vì tự sửa (quy tắc tối ưu số 6). Sổ này ghi kết quả của đợt đồng bộ cuối: mỗi đề nghị đã được xử lý thế nào, những tên nào được chốt dùng chung, và câu hỏi nào còn cần người có thẩm quyền trả lời.

**Phạm vi.** Mọi phụ lục "Đề nghị đồng bộ", "Đề nghị bổ sung", "Điểm cần sửa ở tài liệu khác" của bộ tài liệu tại ngày 27/11/2026, cộng tệp gom chung `DE-NGHI-DONG-BO.md`. Các tài liệu D05-03, D05-04, D05-05 và D06-01…05 chưa viết theo chỉ đạo của chủ đầu tư nên đề nghị nhắm tới chúng được ghi "Không làm" để xử lý khi viết.

**Căn cứ.** Quy tắc tối ưu token số 6 và quy tắc cập nhật tiến độ của chủ đầu tư (26/11/2026); quy ước mã D00-01 §3.1; sổ tra cứu D00-04.

**Những điểm hội đồng cần lưu ý.**

1. Đề nghị được tách thành từng dòng và cấp mã `DB-nnnn`. Dòng đã được tập đích hấp thụ từ trước (ghi "đã hấp thụ", "đã sửa") không đưa vào sổ.
2. Khi hai tập lệch tên, đợt này dùng quy tắc "chủ sở hữu thắng" (mục 2), nên không có quyết định nghiệp vụ mới nào được đưa ra trong đợt.
3. Câu hỏi có hệ quả nghiệp vụ, pháp chế hoặc con số của chủ đầu tư không được tự chốt; chúng được cấp mã Q380 trở đi ở mục 4, kèm đề xuất.
4. Sau đợt đồng bộ, công cụ soát mã không còn liên kết hỏng; 20 mã trùng và 18 mã thiếu còn lại đã được ghi nhận và giải thích ở mục 6.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Đề nghị được xét | 1228 |
| Đã sửa | 637 |
| Đã khớp sẵn | 376 |
| Câu hỏi mở | 79 |
| Không làm | 136 |
| Câu hỏi mở mới (Q380…) | 73 |
| Tệp được sửa | 158 |

: Con số chính của đợt đồng bộ chéo cuối

## 1. Cách làm

Mục này mô tả cách gom, phân gói và kết luận các đề nghị, để người đọc biết một dòng trong sổ được xét ra sao. Sổ gồm bảy mục: cách làm, quy tắc và quyết định đặt tên, kết quả theo tập nguồn, câu hỏi mở, đề nghị không làm, kết quả soát và việc còn lại.

1. Một script đọc mọi tệp Markdown, lấy phần thân của các mục có tiêu đề "Đề nghị đồng bộ", "Đề nghị bổ sung", "Điểm cần sửa ở…", "Đề xuất sửa…", tách thành dòng gạch đầu dòng hoặc hàng bảng, bỏ hàng tiêu đề, hàng câu hỏi mở và hàng đã ghi hấp thụ.
2. Mỗi dòng được gán vào gói theo tệp đích: bốn gói tài liệu chung (D00, D01–D02 chung, SAD và ATTT, design system cùng D04 và D05-01) và tám gói phân hệ. Mỗi gói chỉ sửa tệp của mình, nên hai gói không bao giờ sửa cùng một tệp.
3. Với mỗi dòng, người xử lý mở đúng đoạn ở tệp đích, kết luận một trong bốn trạng thái ở bảng dưới và ghi lý do.
4. Dòng mà mọi gói đều báo ngoài phạm vi được gom thành lượt vét cuối, xử lý với phạm vi toàn bộ.
5. Sau khi sửa: chạy `kiem_tra_ma.py` (mã trùng, mã thiếu, liên kết hỏng), `kiem_tra_yaml.py`, `chay_ddl.py` (DDL 20 phân hệ trên PostgreSQL 16), `check_contracts.py` của từng phân hệ, rồi sinh lại backlog D02-05, bảng tính và Gherkin test case.

| Trạng thái | Nghĩa |
|---|---|
| Đã sửa | Tệp đích đã được sửa cho khớp |
| Đã khớp sẵn | Tệp đích đã khớp (một lượt sau đã sửa) hoặc đề nghị đã lỗi thời |
| Câu hỏi mở | Cần người chốt; được cấp mã ở mục 4, tài liệu chưa sửa |
| Không làm | Không nên làm, chỉ là ghi chú, hoặc nhắm tới tài liệu chưa viết; lý do ở mục 5 |

: Bốn trạng thái kết luận của một đề nghị

## 2. Quy tắc chọn tên và quyết định đã áp

Khi hai tập lệch tên, bên sở hữu thắng:

| Mã | Quy tắc |
|---|---|
| R1 | Topic và sự kiện: tên của phân hệ phát là chuẩn; topic cấp nền tảng không có tiền tố tenant |
| R2 | API, scope, mã lỗi: D03-04 của phân hệ sở hữu API là chuẩn |
| R3 | Token, thành phần: D03-05-02/03/04 là chuẩn; route: tập màn hình của phân hệ, trừ khi đụng mẫu chung của D03-06-00 |
| R4 | Quyền, vai trò: định nghĩa ở D02-08 |
| R5 | Trong một phân hệ: FRS chuẩn về nghiệp vụ và câu thông báo, D03-04 chuẩn về hợp đồng, D03-03 chuẩn về tên vật lý |
| R6 | Khóa tham số `NN.*` do FRS §8.2 của phân hệ chủ định nghĩa; bộ đệm tham số ≤ 60 giây (BR-18-006) |
| R7 | Không đổi các quyết định đã chốt: Kafka, APISIX ở biên (không Envoy), ATTT cấp 3 sẵn lên 4, Camel Quarkus 3.33.x, PostgreSQL và RLS, React với antd v6 Liquid Glass |

: Quy tắc chọn tên khi hai tập lệch nhau

| Mã | Quyết định | Tập bị sửa |
|---|---|---|
| QĐ-1 | Topic bật, tắt phân hệ là `platform.tenant.module-enabled.v1`, `platform.tenant.module-disabled.v1` (EVT-20-07, PH-20 phát) | PH-19 |
| QĐ-2 | Topic tạo tenant là `platform.tenant.created.v1`; bỏ dạng `dh.platform.tenant.created.v1` | PH-10 |
| QĐ-3 | DLQ dùng topic `{tenant}.ops.dlq.v1` và bộ header theo FRS PH-18 bảng 4.1b | PH-04, PH-18, D04-01 |
| QĐ-4 | Chuyển dữ liệu khi sáp nhập tỉnh dùng API-18-150…153 `POST /api/ops/v1/merge-transfers`; PH-20 gọi bằng tài khoản máy qua `apisix-int`, scope `ops:merge-transfer`; mã kế hoạch `SN-yyyy-nnn`, `module` dạng `PH-nn`, chế độ `FULL` hoặc `DELTA`, khóa lũy đẳng `{mergePlanId}:{module}` | PH-18, PH-20 |
| QĐ-5 | Bộ đệm tham số của mọi phân hệ ≤ 60 giây | PH-07, PH-08, PH-10 |
| QĐ-6 | `type` của RFC 9457 là `https://datahub.gov.vn/errors/ERR-{PH}-{nnn}` | PH-05, PH-08, PH-14, PH-16, PH-19, D04-01, D00-04 |
| QĐ-7 | Màn hình có sáu trạng thái (thêm "Không có quyền") theo D03-05-04 §2.2 | D03-05, tập màn hình |
| QĐ-8 | Hệ cũ có 186 chức năng `LGC`, 72 nâng cấp, 182 được bảo toàn | D01-01, D01-02, D02-01, D05-01 |
| QĐ-9 | Route "Việc của tôi" là `/viec-cua-toi` (D03-06-00); `/ca-nhan/viec` chuyển hướng 301 | PH-18 |
| QĐ-10 | `If-Match` lệch trả HTTP 412 (D04-01) | PH-14 |
| QĐ-11 | Dải ADR 075…079 cấp cho PH-14; PH-15 dùng 095…099 | D00-02, PH-15, PH-16 |
| QĐ-12 | Saga khởi tạo tenant gồm 17 bước `S01`…`S17` theo FRS PH-20 §4.4 | D03-10, PH-10, PH-19, PH-20 |

: Quyết định đặt tên áp chung trong đợt đồng bộ

Lớp biên APISIX đã được sửa ở D01-01 và SAD trước đợt này; không còn chỗ nào ghi Envoy Gateway là thành phần của Datahub.

## 3. Kết quả theo tập nguồn

Bảng dưới đếm đề nghị theo tập đã nêu ra chúng. Kết luận của từng dòng ở tệp [so-dong-bo-cuoi.csv](dong-bo/so-dong-bo-cuoi.csv) (cột `ma`, `tap_nguon`, `ket_luan`, `cau_hoi_mo`, `tep_da_sua`, `ghi_chu`, `de_nghi_goc`).

| Tập nguồn | Số đề nghị | Đã sửa | Đã khớp sẵn | Câu hỏi mở | Không làm |
|---|---|---|---|---|---|
| D02-05 | 9 | 3 | 1 | 0 | 5 |
| D02-06 | 8 | 4 | 2 | 0 | 2 |
| D02-03-PH01 | 16 | 11 | 1 | 3 | 1 |
| D02-03-PH02 | 16 | 12 | 1 | 1 | 2 |
| D02-03-PH03 | 13 | 10 | 3 | 0 | 0 |
| D02-03-PH04 | 2 | 1 | 0 | 0 | 1 |
| D02-03-PH06 | 19 | 9 | 6 | 2 | 2 |
| D02-03-PH08 | 14 | 12 | 0 | 2 | 0 |
| D02-03-PH09 | 14 | 8 | 4 | 1 | 1 |
| D02-03-PH10 | 17 | 6 | 10 | 0 | 1 |
| D02-03-PH11 | 10 | 7 | 2 | 1 | 0 |
| D02-03-PH12 | 13 | 12 | 1 | 0 | 0 |
| D02-03-PH13 | 26 | 19 | 3 | 2 | 2 |
| D02-03-PH14 | 17 | 14 | 1 | 2 | 0 |
| D02-03-PH15 | 28 | 7 | 17 | 2 | 2 |
| D02-03-PH16 | 15 | 12 | 2 | 1 | 0 |
| D02-03-PH17 | 15 | 9 | 2 | 3 | 1 |
| D02-03-PH18 | 15 | 14 | 1 | 0 | 0 |
| D02-03-PH19 | 4 | 3 | 1 | 0 | 0 |
| D02-03-PH20 | 22 | 16 | 2 | 3 | 1 |
| D02-04-PH01 | 7 | 2 | 1 | 1 | 3 |
| D02-04-PH03 | 4 | 0 | 3 | 0 | 1 |
| D02-04-PH04 | 1 | 0 | 0 | 0 | 1 |
| D02-04-PH08 | 1 | 0 | 1 | 0 | 0 |
| D02-04-PH10 | 22 | 0 | 21 | 0 | 1 |
| D02-04-PH12 | 5 | 3 | 1 | 0 | 1 |
| D02-04-PH13 | 7 | 5 | 2 | 0 | 0 |
| D02-04-PH14 | 6 | 5 | 0 | 1 | 0 |
| D02-04-PH15 | 8 | 0 | 7 | 0 | 1 |
| D02-04-PH16 | 1 | 0 | 0 | 0 | 1 |
| D02-04-PH17 | 9 | 2 | 2 | 2 | 3 |
| D02-04-PH18 | 4 | 1 | 2 | 0 | 1 |
| D02-04-PH20 | 10 | 6 | 1 | 1 | 2 |
| D03-04-PH01 | 12 | 8 | 1 | 1 | 2 |
| D03-04-PH02 | 7 | 6 | 0 | 1 | 0 |
| D03-04-PH03 | 10 | 7 | 2 | 0 | 1 |
| D03-04-PH04 | 4 | 2 | 0 | 1 | 1 |
| D03-04-PH06 | 2 | 0 | 1 | 0 | 1 |
| D03-04-PH08 | 5 | 3 | 1 | 1 | 0 |
| D03-04-PH10 | 20 | 0 | 19 | 0 | 1 |
| D03-04-PH11 | 3 | 0 | 1 | 0 | 2 |
| D03-04-PH12 | 12 | 6 | 3 | 2 | 1 |
| D03-04-PH13 | 10 | 7 | 1 | 1 | 1 |
| D03-04-PH14 | 12 | 9 | 1 | 2 | 0 |
| D03-04-PH15 | 3 | 2 | 1 | 0 | 0 |
| D03-04-PH16 | 7 | 7 | 0 | 0 | 0 |
| D03-04-PH17 | 2 | 0 | 2 | 0 | 0 |
| D03-04-PH18 | 17 | 6 | 9 | 0 | 2 |
| D03-04-PH20 | 13 | 9 | 2 | 1 | 1 |
| D03-07 | 13 | 3 | 9 | 0 | 1 |
| D03-03-PH01 | 12 | 8 | 1 | 1 | 2 |
| D03-03-PH02 | 9 | 5 | 0 | 0 | 4 |
| D03-03-PH03 | 9 | 5 | 2 | 0 | 2 |
| D03-03-PH04 | 2 | 1 | 0 | 0 | 1 |
| D03-03-PH06 | 1 | 0 | 1 | 0 | 0 |
| D03-03-PH08 | 7 | 4 | 2 | 0 | 1 |
| D03-03-PH10 | 9 | 0 | 9 | 0 | 0 |
| D03-03-PH11 | 3 | 0 | 2 | 0 | 1 |
| D03-03-PH12 | 9 | 8 | 1 | 0 | 0 |
| D03-03-PH13 | 13 | 10 | 1 | 1 | 1 |
| D03-03-PH14 | 11 | 9 | 0 | 1 | 1 |
| D03-03-PH15 | 5 | 3 | 2 | 0 | 0 |
| D03-03-PH16 | 8 | 4 | 1 | 0 | 3 |
| D03-03-PH17 | 3 | 1 | 1 | 0 | 1 |
| D03-03-PH18 | 19 | 6 | 12 | 1 | 0 |
| D03-03-PH20 | 11 | 8 | 3 | 0 | 0 |
| D03-09 | 7 | 6 | 0 | 0 | 1 |
| D03-02-PH01 | 9 | 6 | 3 | 0 | 0 |
| D03-02-PH02 | 14 | 9 | 3 | 1 | 1 |
| D03-02-PH03 | 12 | 8 | 2 | 0 | 2 |
| D03-02-PH04 | 2 | 1 | 0 | 0 | 1 |
| D03-02-PH06 | 10 | 2 | 7 | 1 | 0 |
| D03-02-PH08 | 6 | 5 | 0 | 1 | 0 |
| D03-02-PH09 | 9 | 6 | 3 | 0 | 0 |
| D03-02-PH10 | 8 | 0 | 7 | 0 | 1 |
| D03-02-PH11 | 2 | 0 | 0 | 0 | 2 |
| D03-02-PH12 | 12 | 9 | 1 | 1 | 1 |
| D03-02-PH13 | 10 | 8 | 1 | 0 | 1 |
| D03-02-PH14 | 15 | 9 | 4 | 2 | 0 |
| D03-02-PH15 | 11 | 4 | 6 | 1 | 0 |
| D03-02-PH16 | 7 | 5 | 1 | 1 | 0 |
| D03-02-PH17 | 17 | 11 | 2 | 3 | 1 |
| D03-02-PH18 | 13 | 7 | 2 | 2 | 2 |
| D03-02-PH20 | 23 | 17 | 4 | 2 | 0 |
| D03-06-PH01 | 24 | 9 | 6 | 6 | 3 |
| D03-06-PH02 | 17 | 5 | 9 | 1 | 2 |
| D03-06-PH03 | 22 | 9 | 6 | 4 | 3 |
| D03-06-PH04 | 2 | 1 | 0 | 0 | 1 |
| D03-06-PH06 | 13 | 11 | 0 | 0 | 2 |
| D03-06-PH07 | 9 | 6 | 1 | 2 | 0 |
| D03-06-PH09 | 34 | 11 | 18 | 0 | 5 |
| D03-06-PH10 | 27 | 2 | 24 | 0 | 1 |
| D03-06-PH11 | 12 | 8 | 1 | 0 | 3 |
| D03-06-PH12 | 20 | 12 | 3 | 3 | 2 |
| D03-06-PH13 | 12 | 6 | 1 | 1 | 4 |
| D03-06-PH14 | 20 | 11 | 4 | 2 | 3 |
| D03-06-PH15 | 17 | 4 | 10 | 0 | 3 |
| D03-06-PH16 | 14 | 9 | 3 | 0 | 2 |
| D03-06-PH17 | 6 | 4 | 1 | 0 | 1 |
| D03-06-PH18 | 12 | 6 | 4 | 0 | 2 |
| D03-06-PH20 | 8 | 5 | 2 | 0 | 1 |
| D05-02-PH01 | 4 | 2 | 1 | 0 | 1 |
| D05-02-PH02 | 3 | 3 | 0 | 0 | 0 |
| D05-02-PH03 | 5 | 3 | 1 | 0 | 1 |
| D05-02-PH04 | 1 | 0 | 0 | 0 | 1 |
| D05-02-PH06 | 1 | 0 | 1 | 0 | 0 |
| D05-02-PH08 | 1 | 0 | 0 | 0 | 1 |
| D05-02-PH09 | 14 | 4 | 9 | 0 | 1 |
| D05-02-PH10 | 19 | 2 | 14 | 0 | 3 |
| D05-02-PH11 | 2 | 0 | 0 | 0 | 2 |
| D05-02-PH12 | 4 | 2 | 1 | 1 | 0 |
| D05-02-PH13 | 4 | 2 | 1 | 1 | 0 |
| D05-02-PH14 | 4 | 2 | 2 | 0 | 0 |
| D05-02-PH15 | 3 | 1 | 2 | 0 | 0 |
| D05-02-PH16 | 5 | 5 | 0 | 0 | 0 |
| D05-02-PH17 | 9 | 3 | 4 | 0 | 2 |
| D05-02-PH18 | 7 | 3 | 4 | 0 | 0 |
| D05-02-PH20 | 7 | 4 | 1 | 0 | 2 |
| DE-NGHI-DONG-BO.md | 18 | 9 | 4 | 1 | 4 |

: Số đề nghị và kết luận theo tập nguồn

## 4. Câu hỏi mở mới

Các câu dưới đây cần chủ đầu tư, pháp chế hoặc trưởng nhóm phân hệ chốt. Mỗi câu kèm đề xuất của nhóm viết; tài liệu đích giữ nguyên cho tới khi có trả lời. Một số câu được nhiều tập nêu lại, khi đó cột "Đề nghị" liệt kê đủ các mã `DB`.

| Mã | Đề nghị | Tập nguồn | Câu hỏi và đề xuất |
|---|---|---|---|
| Q380 | DB-0025 | D02-03-PH01 | PH-12 có phải nghe EVT-01-11 (trần phạm vi) để gỡ scope api:* không? Đề xuất: không, PH-02 nghe EVT-01-11 rồi gọi API-12-068 thay tập scope; bỏ PH-12 khỏi cột bên nghe của EVT-01-11 ở tập PH-01. |
| Q381 | DB-0026 | D02-03-PH01 | PH-03 có ghi nhận và truy vấn nhật ký lượt gọi gắn định danh SANDBOX cho PH-01 (kiểm thử SANDBOX) hay PH-01 chỉ lấy từ PH-13? Đề xuất: PH-01 lấy từ PH-13 (sandboxActivity), PH-03 chỉ bảo đảm nhãn consumer trong nhật ký. |
| Q382 | DB-0027 | D02-03-PH01 | PH-02 có chặn đăng ký sử dụng vượt trần phạm vi (EVT-01-11, checkWithinCeiling) và có đường xin mở rộng trần không (Q01-02)? Đề xuất: có, thêm BR vào FRS PH-02 §7 và dòng PH-01 ở API-02 §5, đường xin mở rộng đi qua UC-01-21 của PH-01. |
| Q383 | DB-0045 | D02-03-PH02 | Có mở thêm phạm vi cấp sử dụng kết nối PH-05 cho API của PH-02 (scope API ngoài WORKSPACE, FLOW ở FR-05-009) để backend SYSTEM dùng kết nối không? Đề xuất: có, thêm scope API với kiểm tra API tồn tại ở PH-02, môi trường tương ứng, loại kết nối http-*; cần chủ PH-05 và PH-02 xác nhận vì đổi enum ở OpenAPI, DDL và UI. |
| Q384 | DB-0067 | D02-03-PH06 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q385 | DB-0077 | D02-03-PH06 | Có cho phép ServiceAccount dh-data của PH-06 giữ một Role chỉ tạo, đọc, xóa Job ở dh-control như ngoại lệ của SEC-53 (Q06-24) không? Đề xuất: cho phép, giới hạn trong namespace dh-control và chỉ tài nguyên Job, kiến trúc sư ATTT duyệt rồi ghi ngoại lệ vào SEC-53. |
| Q386 | DB-0087 | D02-03-PH08 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q387 | DB-0088 | D02-03-PH08 | PH-06 có nhận mã lý do hàng đợi DQ_FINDING, mã từ chối DQ_GATE, API nội bộ tạo mục và khung nhìn v_dq_{domain} cho vai dq_reader (PH-08 đã chốt phía mình) không, và ưu tiên, SLA, người nhận ra sao? Đề xuất: có; DQ_FINDING ưu tiên 35, SLA theo 06.queue.sla-days (7 ngày), người nhận là DS của miền; API-06-126 POST /internal/stewardship/items:from-dq scope mdm:steward-intake; DQ_GATE là lý do REJECTED của ứng viên; vai dq_reader chỉ SELECT trên v_dq_{domain}. |
| Q388 | DB-0102 | D02-03-PH09 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q389 | DB-0136 | D02-03-PH11 | Việc duyệt kết nạp HTTT do PH-01 tự điều phối hay giao quy trình DUYET_KET_NAP_HTTT của PH-11 (API-11-049, EVT-11-05, 06)? Đề xuất: giữ PH-01 tự điều phối ở MVP, tích hợp PH-11 ở Đợt 2 khi PH-11 chốt. |
| Q390 | DB-0169 | D02-03-PH13 | PH-13 gửi đề nghị tạm ngừng HTTT vào PH-01 (tạo việc cho SO xử lý khẩn) hay PH-13 chỉ cảnh báo (Q13-12)? Đề xuất: PH-13 chỉ đề xuất, SO ở PH-01 quyết định bằng thao tác khẩn FR-01-032, thêm API nhận đề xuất kèm việc trong hộp việc. |
| Q391 | DB-0170 | D02-03-PH13 | PH-03 có bật kafka-logger ghi {tenant}.obs.access.logged.v1 cho mọi route (khối lượng lớn, siêu dữ liệu) và xuất dh_connect_config_revision không? Đề xuất: có, theo FR-13-006; ghi vào FR-03-050 và SDD §4.6, chỉ siêu dữ liệu không thân bản tin. |
| Q392 | DB-0187 | D02-03-PH14 | PH-02 có thêm loại API "dịch vụ quốc gia" nhận bản nháp từ PH-14 (Idempotency-Key, sự kiện đã công bố mang apiCode, danh sách dịch vụ chia sẻ PUBLISHED) hay PH-14 tự đăng ký qua API-02 hiện có? Đề xuất: thêm API nhận bản nháp ở PH-02 (chỉ tạo DRAFT, không tự công bố) khi PH-14 chốt hợp đồng. |
| Q393 | DB-0191 | D02-03-PH14 | Có bổ sung vào PH-09 hai API data plane (kiểm tra mục đích có trong sổ hoạt động xử lý, và kiểm lô không chứa trường cấm gửi ra ngoài tỉnh, thời hạn 200 ms) cùng thuộc tính phân loại 'cấm gửi ra ngoài tỉnh' hay không? Đề xuất: có; mở rộng `purpose:decide` trả thêm `ropaActivityId` và `classification:check` nhận `egressScope = OUT_OF_PROVINCE`, thêm cờ `noEgress` vào phần tử dữ liệu, kèm NFR p95 ≤ 200 ms. |
| Q394 | DB-0202, DB-0786 | D02-03-PH15, D03-02-PH15 | PH-03 có phục vụ tuyến sandbox tĩnh kèm forward-auth (allow_degradation false, 300 ms) cho PH-15 không? Đề xuất: có, thêm mẫu route sandbox vào FR-03-048 (mẫu chính sách) và bảng PH-15 ở D03-04-PH03 §5.1. |
| Q395 | DB-0205 | D02-03-PH15 | PH-01 có cung cấp lược đồ biểu mẫu kết nạp và API đọc định danh production cho PH-15 không? Đề xuất: có, hai API đọc nội bộ (scope onboarding:internal-read) mới ở D03-04-PH01. |
| Q396 | DB-0226 | D02-03-PH16 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q397 | DB-0243 | D02-03-PH17 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q398 | DB-0244, DB-0805 | D02-03-PH17, D03-02-PH17 | PH-03 có hỗ trợ plugin ai-proxy (ai-proxy-multi) và danh sách trắng egress mô hình cho PH-17 không? Đề xuất: có nhưng chỉ ở apisix-int, khai trong mẫu chính sách FR-03-048, không đệm luồng SSE. |
| Q399 | DB-0249, DB-0810 | D02-03-PH17, D03-02-PH17 | Đặt tên và phạm vi scope đọc siêu dữ liệu cho svc-assist-index của PH-17 (catalog:read-meta?) và API đọc cho công cụ chỉ đọc ở PH-02? Đề xuất: catalog:read-meta chỉ trả siêu dữ liệu, thêm vào D02-08 §5 rồi ghi ở D03-04-PH02. |
| Q400 | DB-0277 | D02-03-PH20 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q401 | DB-0286, DB-0847 | D02-03-PH20, D03-02-PH20 | Khi tổ chức giải thể, sáp nhập, PH-01 có tạo sẵn đề nghị đổi chủ quản chờ TA duyệt hàng loạt theo EVT-20-13 không (Q01-10)? Đề xuất: có, đúng như đề xuất Q01-10; thêm FR vào FRS PH-01 và đầu vào sự kiện EVT-20-13. |
| Q402 | DB-0291 | D02-03-PH20 | API-20-137, 139 (SO, AU đọc) và API-20-161 (TA, AU) chưa có PERM-20 tương ứng: thêm hai quyền đọc mới hay dùng vai trò trực tiếp? Đề xuất: không thêm quyền mới, ghi ở FRS PH-20 là PERM-20-settings hoặc vai trò SO, AU, TA trực tiếp (PERM-20-read không cấp cho SO). |
| Q403 | DB-0294 | D02-04-PH01 | Khi TA vắng, ai xác nhận thao tác khẩn và duyệt chấm dứt: cấp PERM-01-approve cho PA (có kiểm toán chéo tenant) hay buộc mỗi tenant có tối thiểu hai TA (Q01-47)? Đề xuất: buộc tối thiểu hai TA, sửa luồng thay thế FR-01-032 thành "TA khác xác nhận". |
| Q404 | DB-0345 | D02-04-PH14 | PH-02 thêm loại API dịch vụ quốc gia nhận bản nháp từ PH-14, và PH-03 thêm tuyến chiều vào /inbound/v1/* ở vùng biên (mTLS, giới hạn, WAF, bộ lọc vân tay từ EVT-14-13) cho UC-14-26? Đề xuất: có cả hai, PH-14 chỉ tạo bản nháp; ghi vào FRS PH-02, PH-03 khi PH-14 chốt. |
| Q405 | DB-0359 | D02-04-PH17 | Có quét mẫu tiêm lệnh khi lập chỉ mục không? Đề xuất: có, chỉ gắn cờ đoạn nghi ngờ, không bỏ đoạn, vẫn bọc khi dùng; SO và chủ phân hệ nguồn chốt. |
| Q406 | DB-0361 | D02-04-PH17 | Có thêm API sửa phản hồi trong 10 phút không (Q17-88)? Đề xuất: có, `PUT /feedback/{feedbackId}` kèm `If-Match` trong 10 phút; PO và chủ tập API quyết. |
| Q407 | DB-0375 | D02-04-PH20 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q408 | DB-0389 | D03-04-PH01 | Có chấp nhận thêm vào hợp đồng PH-01: (1) cho IE, SO tự nhận việc thẩm định đúng vai trò (cần quyền mới ở D02-08), (5) cờ stateSecret hay danh sách bí mật nhà nước riêng (Q01-32, pháp chế), (6) handoverToken trả trực tiếp ở API-01-045 (ATTT), (4) Range và inline cho API-01-008 và (7) cờ securityRelated? Đề xuất: duyệt (1) với quyền PERM-01-review-claim, (5) bằng danh sách riêng do tenant cấu hình, từ chối (6) vì phá bàn giao một lần qua thư, duyệt (4) và (7). |
| Q409 | DB-0392 | D03-04-PH02 | Có sửa DDL PH-02 theo API ở lần này (review_request.kind varchar(20) đủ 10 giá trị, status PENDING, 3 cột lint_finding, thêm NATIONAL_SYNC_RUN, GATEWAY_RECONCILE cho async_operation) không? Đề xuất: có, theo R5, làm cùng lúc có PostgreSQL 16 để chạy ph02_isolation_test.sql (Q02-61). |
| Q410 | DB-0408 | D03-04-PH04 | Có cấp mã API-04-092 (GET /internal/v1/testruns/{id}/bundle) và API-04-093 (POST /internal/v1/testruns/{id}/steps) và tách tệp OpenAPI nội bộ ph04/openapi-integration-internal.yaml không? Đề xuất: có, ở bản hợp đồng tiếp theo cùng với chốt SDD §8.2, vì hai DU trao đổi qua hai API này cần hợp đồng kiểm CI. |
| Q411 | DB-0416 | D03-04-PH08 | Như DB-0088. Đề xuất: làm như DB-0088, cấp mã API-06 cho API nội bộ nhận DQ_FINDING. |
| Q412 | DB-0445 | D03-04-PH12 | Ai duyệt danh sách mức xác thực bước lên theo operation của PH-12 (Q12-59) để đưa vào FRS? Đề xuất: cán bộ ATTT và quản trị nền tảng duyệt, sau đó ghi bảng vào FRS §4.8 từ khóa x-datahub-acr của OpenAPI. |
| Q413 | DB-0449, DB-0747 | D03-02-PH12, D03-04-PH12 | Thu hồi token ở PH-03 đi theo đẩy (PH-12 gọi API-03-053), kéo (dh-authz đọc API-12-079 mỗi 10 giây kèm X-DH-Applied-Version, blockAll) hay cả hai? Đề xuất: giữ đẩy làm đường nhanh, thêm kéo làm đường bù khi mất đẩy; ghi plugin dh-authz vào FRS và SDD PH-03. |
| Q414 | DB-0456 | D03-04-PH13 | PH-03 có công bố hai nhóm đường dẫn của PH-13 cho BFF console và ghi nhật ký truy cập qua kafka-logger cho mọi route (giữ /api/platform/v1, /internal/* chỉ ở apisix-int)? Đề xuất: có, thêm mẫu route nền tảng và FR vào FRS PH-03. |
| Q415 | DB-0468 | D03-04-PH14 | PH-02 có thêm loại API "dịch vụ quốc gia" nhận bản nháp từ PH-14 (Idempotency-Key, sự kiện đã công bố mang apiCode, danh sách dịch vụ chia sẻ PUBLISHED) hay PH-14 tự đăng ký qua API-02 hiện có? Đề xuất: thêm API nhận bản nháp ở PH-02 (chỉ tạo DRAFT, không tự công bố) khi PH-14 chốt hợp đồng. |
| Q416 | DB-0469, DB-0772 | D03-02-PH14, D03-04-PH14 | PH-03 có thêm tuyến /inbound/v1/* ở vùng biên (mTLS, giới hạn tần suất, WAF), tuyến cung cấp lại viết sang API-14-075 kèm X-DH-Service, X-DH-Operation và bộ lọc vân tay nạp từ EVT-14-13 không? Đề xuất: có, ghi vào FR-03-001, 002, 038 và bảng PH-14 ở D03-04-PH03 §5.1. |
| Q417 | DB-0507 | D03-04-PH20 | API-20-137, 139 (SO, AU đọc) và API-20-161 (TA, AU) chưa có PERM-20 tương ứng: thêm hai quyền đọc mới hay dùng vai trò trực tiếp? Đề xuất: không thêm quyền mới, ghi ở FRS PH-20 là PERM-20-settings hoặc vai trò SO, AU, TA trực tiếp (PERM-20-read không cấp cho SO). |
| Q418 | DB-0541 | D03-03-PH01 | Thêm bảng background_job cho API-01-088 (xuất tệp nền) hay xuất đồng bộ giới hạn 20.000 dòng (Q01-57)? Đề xuất: xuất đồng bộ giới hạn 20.000 dòng ở MVP, thêm bảng ở Đợt 2. |
| Q419 | DB-0593 | D03-03-PH13 | Có thêm FR và UC cho 'Khôi phục chuỗi kiểm toán sau sự cố' làm đường ngoại lệ có biên bản không? Đề xuất: có, mức C, đợt sau, ngoại lệ ghi vào BR-13-033, quyền do SO và TA cùng ký; phần giữ ý kiến SDD về FR-13-014 bước 1 đã làm. |
| Q420 | DB-0609 | D03-03-PH14 | Chủ đầu tư có chấp nhận thời hạn lưu usage_hourly 24 tháng, cache_stats 13 tháng, async_request 90 ngày? Đề xuất: dùng như bảng giả định ở D03-03-PH14 §7.1 |
| Q421 | DB-0647 | D03-03-PH18 | Cờ 07.rdm.feature.* giữ như tham số BOOLEAN hay đổi sang ff.rdm.*? Đề xuất: giữ tham số BOOLEAN theo FRS PH-07 §8.2. |
| Q422 | DB-0687 | D03-02-PH02 | Có cho phép cấp kết nối PH-05 cho API của PH-02 (scope API) không? Đề xuất: có, như DB-0045. |
| Q423 | DB-0713 | D03-02-PH06 | Có cho phép ServiceAccount dh-data của PH-06 giữ một Role chỉ tạo, đọc, xóa Job ở dh-control như ngoại lệ của SEC-53 (Q06-24) không? Đề xuất: cho phép, giới hạn trong namespace dh-control và chỉ tài nguyên Job, kiến trúc sư ATTT duyệt rồi ghi ngoại lệ vào SEC-53. |
| Q424 | DB-0716 | D03-02-PH08 | Như DB-0088. Đề xuất: làm như DB-0088 rồi cập nhật SDD PH-06 §4.2 và §4.12. |
| Q425 | DB-0771 | D03-02-PH14 | PH-02 có thêm loại API "dịch vụ quốc gia" nhận bản nháp từ PH-14 (Idempotency-Key, sự kiện đã công bố mang apiCode, danh sách dịch vụ chia sẻ PUBLISHED) hay PH-14 tự đăng ký qua API-02 hiện có? Đề xuất: thêm API nhận bản nháp ở PH-02 (chỉ tạo DRAFT, không tự công bố) khi PH-14 chốt hợp đồng. |
| Q426 | DB-0793 | D03-02-PH16 | PH-01 và PH-02 có phát thêm componentCode, loại, phiên bản, vòng đời, dependsOn, contentHash cho PH-16 tự đăng ký kiến trúc và API liệt kê đối chiếu không? Đề xuất: có sau khi PH-16 chốt danh sách trường (FR-16-048). |
| Q427 | DB-0799 | D03-02-PH17 | Điểm cuối bản nháp PH-04, PH-07 cho PH-17 dùng token đổi với scope nào? Đề xuất: scope đọc bản nháp riêng, PH-17 chốt hợp đồng trước. |
| Q428 | DB-0819 | D03-02-PH18 | PH-01, PH-02, PH-03 có theo khung API nhập chung của PH-18 hay giữ API nhập riêng và PH-18 gọi qua đó? Đề xuất: giữ API nhập riêng, thêm tiêu đề X-Datahub-Migration và khóa lũy đẳng khi PH-18 chốt khung. |
| Q429 | DB-0822 | D03-02-PH18 | PH-03 có hỗ trợ tuyến bóng và API đổi trọng số tuyến đồng bộ có xác nhận cho cắt chuyển, quay lui di trú (Q18-25, Q18-26) không? Đề xuất: có, khai ở mẫu route và thêm API vào D03-04-PH03 khi PH-18 chốt Q18-25. |
| Q430 | DB-0836 | D03-02-PH20 | Mã BP-10 đến BP-13 đang bị hai phân hệ cùng đề nghị (BP-10: PH-06 và PH-08; BP-11: PH-09 và PH-16; BP-12: PH-17 và PH-20; BP-13: PH-20), nên đánh mã thế nào? Đề xuất: BP-10 dữ liệu chủ (PH-06), BP-11 chất lượng dữ liệu (PH-08), BP-12 bảo vệ DLCN (PH-09), BP-13 báo cáo chỉ tiêu (PH-16), BP-14 trợ lý AI (PH-17), BP-15 sáp nhập tenant, BP-16 phát hành và nâng cấp (PH-20), rồi sửa mã trong các FRS, UC, màn hình tương ứng và thêm vào D02-01 mục 2.5; đồng thời sửa Tóm tắt (9 quy trình). |
| Q431 | DB-0853 | D03-06-PH01 | Cho IE, SO tự nhận việc thẩm định đúng vai trò bước (mở rộng API-01-028 hoặc thêm reviews:claim) hay chỉ TA phân công (Q01-35)? Đề xuất: giữ TA phân công ở MVP, tự nhận việc ở Đợt 2 kèm quy tắc OPA. |
| Q432 | DB-0854 | D03-06-PH01 | API-01-069 có nhận organizationIds[] để nhắc đơn vị chưa phản hồi (Q01-36) không? Đề xuất: có, tham số tùy chọn, ảnh hi-fi giữ nút "Gửi nhắc đơn vị". |
| Q433 | DB-0856 | D03-06-PH01 | API-01-008 có hỗ trợ Range và Content-Disposition inline với CSP sandbox để xem trước PDF không (Q01-31)? Đề xuất: không ở MVP, tải qua liên kết ký 60 giây rồi mở bằng trình xem của trình duyệt. |
| Q434 | DB-0857 | D03-06-PH01 | API-01-013 có trả cờ stateSecret cho mục thuộc danh mục bí mật nhà nước để chặn trước khi gửi (Q01-32) không? Đề xuất: giữ chặn sau khi gửi bằng ERR-01-016 cho tới khi pháp chế chốt danh mục. |
| Q435 | DB-0858 | D03-06-PH01 | API-01-045 có trả handoverToken khi người xoay vòng là đầu mối kỹ thuật để mở ngay UI-01-09 (Q01-34) không? Đề xuất: không, giữ liên kết gửi qua thư. |
| Q436 | DB-0859 | D03-06-PH01 | Có thêm cờ securityRelated cho từng khóa tham số onboarding.* không? Đề xuất: không thêm; UI dùng platformCeiling có sẵn và hiện ERR-01-044 sau khi lưu. |
| Q437 | DB-0878 | D03-06-PH02 | Xuất CSV cho API-02-001, 059, 072 theo Accept: text/csv (Q02-60)? Đề xuất: có, dùng Accept: text/csv cùng bộ lọc, không có bí mật; thêm vào API-02 ở bản sau. |
| Q438 | DB-0895 | D03-06-PH03 | Thêm POST /waf/virtual-patches:dry-run trả số yêu cầu mẫu 24 giờ sẽ bị chặn cho nút "Thử khô" ở UI-03-08? Đề xuất: có, thêm API-03-097 (quyền waf) vào D03-04-PH03 và FRS §9.4. |
| Q439 | DB-0896 | D03-06-PH03 | Bỏ giữ sau quay lui là tham số releaseHold=true của API-03-059 hay API riêng snapshots:release-hold? Đề xuất: API riêng POST /snapshots:release-hold (quyền operate, lý do bắt buộc) để tách khỏi thao tác phát. |
| Q440 | DB-0898 | D03-06-PH03 | UI-03-07 có hiển thị mẫu trích đã che của yêu cầu bị chặn không (trái "không chứa nội dung yêu cầu" của BR-03-007)? Đề xuất: không hiển thị mẫu trích; Drawer chỉ dùng mã luật, điểm, hành động, route, traceId. |
| Q441 | DB-0902 | D03-06-PH03 | API-03-039, 074 dùng phân trang con trỏ và approxTotal thay page, size, totalElements (Q03-56)? Đề xuất: có, riêng hai API nhật ký; ghi ngoại lệ vào D00-04 §quy ước phân trang. |
| Q442 | DB-0934 | D03-06-PH07 | Khôi phục bản ghi DEPRECATED dùng PATCH status hay endpoint :restore? Đề xuất: :restore riêng. |
| Q443 | DB-0935 | D03-06-PH07 | API-07-031 có nhận ifMatch từng phần tử và trả 207 không? Đề xuất: có. |
| Q444 | DB-1018 | D03-06-PH12 | Cho phép API-12-103 trả CSV và giới hạn khoảng 7 ngày không? Đề xuất: không trả CSV trực tiếp, dùng tác vụ nền xuất có lý do; giữ giới hạn khoảng tra 7 ngày bằng tham số from, to. |
| Q445 | DB-1019 | D03-06-PH12 | Có thêm API-12-112 PUT ghi đè phiên bản nháp (If-Match) cho tự lưu không? Đề xuất: có, chỉ với phiên bản DRAFT của chính người soạn, mỗi lần ghi đè xóa kết quả kiểm thử đã có. |
| Q446 | DB-1022 | D03-06-PH12 | Có thêm API-12-112 GET /realms với tham số lech cho UI-12-19 không? Đề xuất: có, PERM-12-realm-admin, phân trang chuẩn, lọc driftStatus=DRIFTED. |
| Q447 | DB-1036 | D03-06-PH13 | Có thêm API đếm cảnh báo nhẹ cho số trên menu không? Đề xuất: không thêm; dùng tham số size=1 của danh sách cảnh báo lấy tổng, cache 30 giây ở BFF. |
| Q448 | DB-1051 | D03-06-PH14 | Có thêm API duyệt chung API-14-093, 094 vào PH-14 bản này? Đề xuất: thêm |
| Q449 | DB-1059 | D03-06-PH14 | Có đưa A11Y-14-01…14 vào cổng CI của PH-14 không? Đề xuất: đưa vào |
| Q450 | DB-1169 | D05-02-PH12 | Có thêm API đọc bộ đếm quyết định không? Đề xuất: không, đo qua endpoint /metrics của OPA và Prometheus; ca kiểm thử truy vấn Prometheus. |
| Q451 | DB-1174 | D05-02-PH13 | IE có được giữ PERM-13-dashboard trên hạ tầng hay không (Q13-41)? Đề xuất: giữ IE ● như D02-08 hiện hành, giới hạn ở bảng điều khiển của luồng và HTTT mình thiết kế. |
| Q452 | DB-1220 | DE-NGHI-DONG-BO | Phiên liên tenant mặc định 60 phút không duyệt (D03-06-00 §2.11) hay tối đa 4 giờ có người duyệt thứ hai (SEC-85, BR-12-032, maxHours = 4)? Đề xuất: theo SEC-85, giao diện dùng thời hạn và bước duyệt do chính sách tenant của PH-20 quy định, 60 phút chỉ là mặc định chọn sẵn trong trần 4 giờ. |

: Câu hỏi mở phát sinh ở đợt đồng bộ chéo cuối

## 5. Đề nghị không làm

Các đề nghị dưới đây được xét nhưng không sửa tài liệu, vì đã có cách khác đáp ứng, chỉ dùng ở một phân hệ, hoặc nhắm tới tài liệu chưa viết.

| Đề nghị | Tập nguồn | Lý do |
|---|---|---|
| DB-0001 | D02-05 | Là hàng bảng giả định của tập nguồn (GĐ-BL, GĐ-DFD), không phải đề nghị sửa; dải GĐ-BL, GĐ-DFD đã ghi ở D00-04 §3.1. |
| DB-0002 | D02-05 | Đây là dòng của bảng giả định GĐ-BL của chính D02-05, không phải đề nghị sửa tệp khác; D01-02 mục 2.4 đã được đối chiếu ở nội dung tập nguồn. |
| DB-0003 | D02-05 | Là hàng bảng giả định của tập nguồn (GĐ-BL, GĐ-DFD), không phải đề nghị sửa; dải GĐ-BL, GĐ-DFD đã ghi ở D00-04 §3.1. |
| DB-0004 | D02-05 | Là hàng bảng giả định của tập nguồn (GĐ-BL, GĐ-DFD), không phải đề nghị sửa; dải GĐ-BL, GĐ-DFD đã ghi ở D00-04 §3.1. |
| DB-0005 | D02-05 | Đây là dòng của bảng giả định GĐ-BL của chính D02-05, không phải đề nghị sửa tệp khác; D01-02 mục 2.4 đã được đối chiếu ở nội dung tập nguồn. |
| DB-0010 | D02-06 | Là hàng bảng giả định của tập nguồn (GĐ-BL, GĐ-DFD), không phải đề nghị sửa; dải GĐ-BL, GĐ-DFD đã ghi ở D00-04 §3.1. |
| DB-0011 | D02-06 | Giả định GĐ-DFD-01 của chính D02-06, không phải đề nghị sửa; chờ số liệu thật của tỉnh thí điểm. |
| DB-0021 | D02-03-PH01 | Đề nghị có điều kiện ("nếu SDD cần liệt kê", "nếu thêm vai trò hoặc cờ theo Q01-45, Q01-47, Q01-48"); chưa có quyết định nên không sửa. Thực thể con EN-01 nằm ở FRS và SDD, không thuộc từ điển dùng chung. |
| DB-0048 | D02-03-PH02 | Thử sửa kiem_tra_ma.py để bỏ qua cột Mã cũ nhưng dòng nhắc ở phụ lục và đoạn giải thích của FRS PH-02 vẫn nhắc NFR-02-021/022 nên sinh thêm lỗi THIEU mới; đã hoàn nguyên, cần PH-02 sửa chữ trước. |
| DB-0049 | D02-03-PH02 | Đề xuất ADR, tập nguồn tự ghi chưa tạo ADR; không phải việc sửa đồng bộ. |
| DB-0064 | D02-03-PH04 | Đợt 2 của chính PH-04 (strategy, scheduledAt), trạng thái Chờ đợt 2, chưa tới hạn. |
| DB-0068 | D02-03-PH06 | Bảng SRS §5 không có cột số FR nên không có chỗ ghi số 60; tham chiếu FRS đã nêu ở lời dẫn chương. |
| DB-0079 | D02-03-PH06 | Phân loại họ tên là câu hỏi mở đã ghi ở Q09-19; ngân sách API chính sách che p95 ≤ 50 ms đã có ở NFR-09-002. |
| DB-0111 | D02-03-PH09 | Mô tả lệch so với SRS cũ đã ghi ở bảng 11.3 của FRS PH-09, không phải đề nghị sửa tệp trong phạm vi. |
| DB-0112 | D02-03-PH10 | Đây là dòng tiêu đề của bảng đề nghị, không phải một đề nghị riêng. |
| DB-0152 | D02-03-PH13 | Là hàng tiêu đề bảng, không phải đề nghị. |
| DB-0176 | D02-03-PH13 | kiem_tra_ngoai_le.txt chỉ được thu hẹp; ba mã PERM-13-admin, alert-ack, security nay đã có ở D02-08 nên không cần ngoại lệ, còn dòng PERM-13-read vẫn phải giữ vì FRS PH-04 còn dẫn. |
| DB-0200 | D02-03-PH15 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-0208 | D02-03-PH15 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-0252 | D02-03-PH17 | SRS-PH-17-ai.md nằm ở docs/07-srs của repo, ngoài bộ datahub-docs độc lập; FRS PH-17 mục 11.3 đã có bảng ánh xạ FR cũ sang mới, bỏ MLflow và Evidently, nên không sửa tệp ngoài bộ. |
| DB-0292 | D02-03-PH20 | Là câu hỏi mở của tập màn hình (Q20-30, 34, 35 và mã lỗi dải MERGING) cần quyết định sản phẩm; tập D03-06-PH20 đã nêu phương án tạm dùng. |
| DB-0295 | D02-04-PH01 | Đề nghị có điều kiện ("nếu SDD cần liệt kê", "nếu thêm vai trò hoặc cờ theo Q01-45, Q01-47, Q01-48"); chưa có quyết định nên không sửa. Thực thể con EN-01 nằm ở FRS và SDD, không thuộc từ điển dùng chung. |
| DB-0296 | D02-04-PH01 | Đề nghị có điều kiện ("nếu SDD cần liệt kê", "nếu thêm vai trò hoặc cờ theo Q01-45, Q01-47, Q01-48"); chưa có quyết định nên không sửa. Thực thể con EN-01 nằm ở FRS và SDD, không thuộc từ điển dùng chung. |
| DB-0297 | D02-04-PH01 | Là việc viết thêm ca kiểm thử (luồng LP-01-01…08), không phải sửa đồng bộ; D05-02-PH01 đã có ma trận UC sang TC sinh tự động. |
| DB-0302 | D02-04-PH03 | Đề nghị là quyết định không thêm cột use case vào bảng API và không cần câu hiển thị cho ERR-03-022 giữa hai dịch vụ; D03-04-PH03 đã nhất quán (truy vết qua FR, ERR-03-022 đã có câu chung). |
| DB-0305 | D02-04-PH04 | Đây là dòng tiêu đề bảng bị gom nhầm, không phải đề nghị. |
| DB-0316 | D02-04-PH10 | Đây là dòng tiêu đề của bảng đề nghị, không phải một đề nghị riêng. |
| DB-0333 | D02-04-PH12 | Là việc rà đối chiếu tổng quát cột Quyền với tiền điều kiện UC, không nêu chỗ lệch cụ thể; API-12 đã khớp FRS §9.4 qua công cụ kiểm hợp đồng. |
| DB-0347 | D02-04-PH15 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-0355 | D02-04-PH16 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-0356 | D02-04-PH17 | Đây là hàng tiêu đề của bảng, không phải đề nghị. |
| DB-0357 | D02-04-PH17 | Đã hấp thụ một phần (FR-17-010 dùng tạm ERR-17-017); mã riêng cần sửa OpenAPI, DDL, test case, backlog và đã là câu hỏi mở Q17-87, không mở rộng thêm ở đợt này. |
| DB-0358 | D02-04-PH17 | Đã hấp thụ một phần (FR-17-044 ghi giải pháp tạm); đổi câu ERR-17-065 làm lệch backlog và tiêu chí chấp nhận ngoài phạm vi, giữ Q17-87. |
| DB-0365 | D02-04-PH18 | Hàng tiêu đề của bảng, không phải đề nghị. |
| DB-0369 | D02-04-PH20 | Hàng tiêu đề bảng, không phải đề nghị. |
| DB-0378 | D02-04-PH20 | Ghi chú cho người viết D05-02-PH20; mã TS-20-nn đã được dùng, không có thay đổi. |
| DB-0387 | D03-04-PH01 | Là việc viết thêm ca kiểm thử (mỗi ERR-01, canary, lũy đẳng, If-Match), không phải sửa đồng bộ; D05-02-PH01 đã có các ca canary, If-Match, lũy đẳng. |
| DB-0390 | D03-04-PH01 | Là đề xuất ADR chưa cấp số của PH-01; PH-12 đã có cơ chế bàn giao bí mật một lần bằng địa chỉ bọc (FR-12-030), không cần sửa thêm. |
| DB-0403 | D03-04-PH03 | Là việc viết thêm ca kiểm thử; D05-02-PH03 đã có ca ERR-03-008, canary, If-Match. |
| DB-0409 | D03-04-PH04 | Tách mã 12 nhóm API-04 kéo theo khoảng 330 dẫn chiếu ở 16 tệp (FRS, màn hình, test case, xlsx) mà mỗi dẫn chiếu phải xác định thuộc operation nào, rủi ro lệch cao ở đợt cuối; giữ ngoại lệ có ghi nhận ở D03-04-PH04, xử lý ở bản hợp đồng v1 sau. |
| DB-0413 | D03-04-PH06 | FRS PH-06 0.2 đã quyết không đưa các trường phản hồi kỹ thuật vào bảng dữ liệu ra của FR (thuộc D03-04, Phụ lục B của FRS). |
| DB-0430 | D03-04-PH10 | Đề nghị của PH-10 chỉ nói PH-13 là nguồn của khối traffic; không đòi PH-13 đổi hợp đồng nào. |
| DB-0439 | D03-04-PH11 | Ghi chú rằng tên trường lấy từ OpenAPI làm nguồn, không đòi FRS thêm. |
| DB-0441 | D03-04-PH11 | ADR 112 mới là đề xuất, tập này chưa tạo tệp ADR theo chính ghi chú của nguồn. |
| DB-0453 | D03-04-PH12 | Nguồn ghi không đề xuất ADR mới. |
| DB-0463 | D03-04-PH13 | Nguồn ghi không đề xuất ADR mới. |
| DB-0489 | D03-04-PH18 | Là ghi chú giữ nguyên (bỏ ví dụ API-18-003, 027 do Spectral, Q18-59), không phải đề nghị sửa. |
| DB-0490 | D03-04-PH18 | Hàng tiêu đề của bảng, không phải đề nghị. |
| DB-0510 | D03-04-PH20 | Thêm 5 bảng (dedicated_cluster, supplement_plan, org_sync_proposal, release_announcement, đối chiếu cấu hình) kèm DDL, Liquibase, test cần đợt riêng của luồng CSDL PH-20; chưa làm trong đợt đồng bộ chéo. |
| DB-0518 | D03-07 | Chỉ là dòng tiêu đề bảng của phụ lục D03-07. |
| DB-0536 | D03-03-PH01 | Là việc chuyển điểm kiểm CSDL thành ca kiểm thử tự động ở CI (TenantIsolationIT, MigrationIT), không phải sửa đồng bộ tài liệu. |
| DB-0542 | D03-03-PH01 | Là đề xuất ADR chưa cấp số của PH-01; CSDL PH-12 đã dùng CHECK, trigger, quyền cột nên không cần sửa. |
| DB-0547 | D03-03-PH02 | Saga cố định theo D03-10 (17 bước), không thêm bước cho PH-02; PH-02 tự khởi tạo catalog khi nhận EVT-20-01 trong phạm vi gói PH-02. |
| DB-0549 | D03-03-PH02 | Là việc viết ca kiểm thử (TenantIsolationIT, ca đua RETIRED), không phải sửa đồng bộ; D05-02-PH02 đã có TS-02-25 và TC-02-119. |
| DB-0550 | D03-03-PH02 | Hợp nhất công cụ gen_tables_md và them_dac_ta_bang liên quan nhiều phân hệ ngoài gói, cần người điều phối chốt; không thuộc nội dung tài liệu. |
| DB-0551 | D03-03-PH02 | Đề xuất ADR, tập nguồn tự ghi chưa tạo ADR. |
| DB-0558 | D03-03-PH03 | Là việc dùng 40 nhóm ca của ph03_isolation_test.sql làm ca kiểm thử, không phải sửa đồng bộ; D05-02-PH03 đã có TC cách ly chéo tenant và tách nhiệm. |
| DB-0559 | D03-03-PH03 | Gộp hoặc tham số hóa gen_liquibase.py và them_dac_ta_bang.py nằm ở csdl/ph07/tools, ngoài phạm vi và chỉ là cân nhắc. |
| DB-0561 | D03-03-PH04 | Chỉ là dòng tiêu đề bảng của phụ lục, không phải đề nghị. |
| DB-0564 | D03-03-PH08 | Đây là dòng tiêu đề bảng (Số, Gửi tới, Nội dung đề nghị), không phải đề nghị. |
| DB-0582 | D03-03-PH11 | shedlock là bảng hạ tầng, không cần thực thể logic. |
| DB-0603 | D03-03-PH13 | Sổ tay vận hành chuỗi kiểm toán là nội dung nhập ở UI-18-07 lúc vận hành (FR-18-025), không phải nội dung tài liệu thiết kế PH-18. |
| DB-0615 | D03-03-PH14 | Tài liệu chưa viết, để khi viết D06 (D06-01 di trú và cắt chuyển sẽ dùng §8 của D03-03-PH14 làm bảng ánh xạ NGSP). |
| DB-0621 | D03-03-PH16 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-0622 | D03-03-PH16 | Tên vật lý do CSDL chuẩn theo R5; FRS giữ tên logic, không cần đổi |
| DB-0623 | D03-03-PH16 | Tên vật lý do CSDL chuẩn theo R5; FRS giữ tên logic, không cần đổi |
| DB-0629 | D03-03-PH17 | FRS PH-17 không nhận tách EN-17-28, EN-17-39; ánh xạ nhiều bảng cho một EN đã ghi ở D03-03-PH17. |
| DB-0668 | D03-09 | Ghi chú lệch với repo (RTO 30 phút so với SRS 1 giờ) đã chọn theo SRS; không cần sửa. |
| DB-0691 | D03-02-PH02 | Đề xuất cấp dải ADR cho PH-02, tập nguồn tự ghi chưa tạo ADR; thuộc người giữ sổ ADR. |
| DB-0698 | D03-02-PH03 | EVT-03-09 đã có trường kind (CROSS_TENANT, VALKEY_DOWN, WAF_AUTO_DEGRADE…) làm phân loại; các giá trị reason của SDD là nhãn chỉ số, không thêm trường trùng nghĩa vào hợp đồng (R5: D03-04 chuẩn về hợp đồng). |
| DB-0701 | D03-02-PH03 | Tài liệu chưa viết, để khi viết D06 (D06-03 sổ tay vận hành sẽ nhận các quy trình ở mục 11 của SDD PH-03). |
| DB-0704 | D03-02-PH04 | Chỉ là dòng tiêu đề bảng của phụ lục, không phải đề nghị. |
| DB-0731 | D03-02-PH10 | Đây là dòng tiêu đề của bảng đề nghị, không phải một đề nghị riêng. |
| DB-0739 | D03-02-PH11 | Nguồn ghi 'Không chấp nhận': FRS đã có EN-11-26 và CSDL 0.2 đã thêm bảng test_run. |
| DB-0740 | D03-02-PH11 | Nguồn ghi 'Không chấp nhận': FRS đã có EN-11-27 và CSDL 0.2 đã thêm bảng instance_change. |
| DB-0752 | D03-02-PH12 | Là đề xuất ADR (e), (f), (g) chưa tạo, dải 014–019; không đòi sửa tệp trong phạm vi. |
| DB-0762 | D03-02-PH13 | Đề xuất ADR 039, 014, 015 do người điều phối cấp số; tập SDD không tạo ADR và số trống phải kiểm theo D00-02. |
| DB-0798 | D03-02-PH17 | Là danh mục đối chiếu bảng, cột phụ trợ của SDD với D03-03-PH17, không phải đề nghị sửa. |
| DB-0818 | D03-02-PH18 | Quy ước app.restore_mode đã có ở D03-10 (mọi trigger chặn xóa, chặn sửa lịch sử phải nhận ngoại lệ). DDL các phân hệ sinh bằng công cụ riêng và phụ thuộc Q18-24, Q18-29 còn mở; sẽ áp khi chốt, không sửa hàng loạt DDL ở đợt này. |
| DB-0824 | D03-02-PH18 | Điểm cuối nội bộ chuyển SUSPENDED, ACTIVE cho khôi phục là thêm API vào hợp đồng PH-20 (171 operation); PH-20 hiện nhận EVT-18-21; cần đợt thiết kế riêng cùng PH-18. |
| DB-0849 | D03-06-PH01 | Đây là hàng tiêu đề bảng, không phải đề nghị. |
| DB-0864 | D03-06-PH01 | Mục tổng hợp trỏ tới bảy đề nghị ở Phụ lục B, đã xử lý riêng từng mục (DB-0853…0859). |
| DB-0872 | D03-06-PH01 | Đề xuất ADR chưa cấp số, thuộc người giữ sổ ADR. |
| DB-0874 | D03-06-PH02 | Dải lộ trình ngừng dùng chỉ PH-02 dùng (UI-02-13), giữ CMP-Timeline cục bộ; đã ghi ở Phụ lục A của tập màn. |
| DB-0889 | D03-06-PH02 | Tập nguồn ghi không đề xuất ADR mới. |
| DB-0890 | D03-06-PH03 | Đây là hàng tiêu đề bảng, không phải đề nghị. |
| DB-0908 | D03-06-PH03 | Mục tổng hợp chín đề nghị Phụ lục B, đã xử lý riêng từng mục (DB-0895…0903). |
| DB-0911 | D03-06-PH03 | Tập nguồn ghi không có đề xuất ADR mới. |
| DB-0912 | D03-06-PH04 | Chỉ là dòng tiêu đề bảng của phụ lục, không phải đề nghị. |
| DB-0925 | D03-06-PH06 | Đã chuyển câu hỏi mở Q06-10 ở FRS PH-06; chưa có quyết định để đặc tả API. |
| DB-0926 | D03-06-PH06 | Đã chuyển câu hỏi mở Q06-11; tạm dùng tham số 06.queue.reason-templates, không thêm API. |
| DB-0944 | D03-06-PH09 | Là cải tiến hợp đồng đã ghi 'Còn mở' ở Phụ lục B; giao diện giữ cách ghép tạm từ API có sẵn, mở rộng OpenAPI ngoài phạm vi đợt đồng bộ này. Mã chỉ số `metrics[]` vẫn chờ chốt. |
| DB-0945 | D03-06-PH09 | Là cải tiến hợp đồng đã ghi 'Còn mở' ở Phụ lục B; giao diện giữ cách ghép tạm từ API có sẵn, mở rộng OpenAPI ngoài phạm vi đợt đồng bộ này. |
| DB-0946 | D03-06-PH09 | Là cải tiến hợp đồng đã ghi 'Còn mở' ở Phụ lục B; giao diện giữ cách ghép tạm từ API có sẵn, mở rộng OpenAPI ngoài phạm vi đợt đồng bộ này. Riêng `goldenSetResult` vẫn mở. |
| DB-0948 | D03-06-PH09 | Là cải tiến hợp đồng đã ghi 'Còn mở' ở Phụ lục B; giao diện giữ cách ghép tạm từ API có sẵn, mở rộng OpenAPI ngoài phạm vi đợt đồng bộ này. `provisional`, `blocked` của bộ lọc API-09-010 còn mở. |
| DB-0949 | D03-06-PH09 | Là cải tiến hợp đồng đã ghi 'Còn mở' ở Phụ lục B; giao diện giữ cách ghép tạm từ API có sẵn, mở rộng OpenAPI ngoài phạm vi đợt đồng bộ này. Đếm theo phân vùng của API-09-164 còn mở; `overdue`, `dueAt` đã có. |
| DB-0975 | D03-06-PH10 | Chỉ PH-10 cần biến thể bên phát, bên nhận; dùng CMP-ResourceSelect chung kèm CMP-StatusTag, đã ghi ở Phụ lục A của tập màn. |
| DB-0997 | D03-06-PH11 | BpmnCanvas chỉ PH-11 dùng nên giữ là thành phần cục bộ; ngoại lệ bpmn-js và khung bọc đã ghi ở D03-05-04 §11.0, Phụ lục A PH-11 ghi kết quả. |
| DB-1002 | D03-06-PH11 | Chỉ PH-11 dùng và chỉ là bí danh của token nguồn có sẵn nên không thêm token color-diagram-*; lưới chấm canvas đã có ở D03-05-04 §11.1. |
| DB-1008 | D03-06-PH11 | Nguồn ghi 'Không chấp nhận: FRS đã khớp'. |
| DB-1016 | D03-06-PH12 | Là hàng tiêu đề bảng, không phải đề nghị. |
| DB-1025 | D03-06-PH12 | Dòng chỉ trỏ tới Phụ lục B; các mục cụ thể đã xử lý ở DB-1017…1022. |
| DB-1029 | D03-06-PH13 | Là hàng tiêu đề bảng Phụ lục A, không phải đề nghị. |
| DB-1033 | D03-06-PH13 | OnCallGrid chỉ PH-13 dùng nên giữ cục bộ; đã ghi ở Phụ lục A.1 của tập màn. |
| DB-1034 | D03-06-PH13 | QueryBar chỉ PH-13 dùng nên giữ cục bộ (LogQueryBar); đã ghi ở Phụ lục A.1 của tập màn. |
| DB-1035 | D03-06-PH13 | Là hàng tiêu đề bảng Phụ lục B, không phải đề nghị. |
| DB-1041 | D03-06-PH14 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-1047 | D03-06-PH14 | Hàng tiêu đề bảng hoặc câu hỏi mở, không phải đề nghị sửa |
| DB-1053 | D03-06-PH14 | Dùng dashboard.attention đã có, không thêm trường mới |
| DB-1062 | D03-06-PH15 | MarkdownEditor chỉ PH-15 dùng (UI-15-21) nên giữ cục bộ, bỏ tiền tố CMP- ở Phụ lục A. |
| DB-1064 | D03-06-PH15 | ServiceCard chỉ PH-15 dùng nên giữ cục bộ trong apps/portal. |
| DB-1065 | D03-06-PH15 | OperationPanel chỉ PH-15 dùng nên giữ cục bộ trong apps/portal. |
| DB-1078 | D03-06-PH16 | IndicatorCard chỉ PH-16 dùng và dựng được từ CMP-KpiCard with-spark, CMP-ScoreMeter bar, CMP-StatusTag nên không thêm biến thể; ghi ở Phụ lục A. |
| DB-1083 | D03-06-PH16 | PagePreview chỉ PH-16 dùng nên giữ cục bộ; đã ghi ở Phụ lục A. |
| DB-1095 | D03-06-PH17 | FRS PH-17 không nhận enum mức nghiêm trọng ca đỏ; màn hình chỉ suy nhãn từ nhóm tấn công, giữ câu hỏi mở Q17-89. |
| DB-1098 | D03-06-PH18 | Hàng tiêu đề của bảng, không phải đề nghị. |
| DB-1101 | D03-06-PH18 | ChannelPreview chỉ PH-18 dùng nên giữ cục bộ; PH-18 ghi rõ ở Phụ lục A. |
| DB-1110 | D03-06-PH20 | Hàng tiêu đề bảng, không phải đề nghị. |
| DB-1121 | D05-02-PH01 | Tập nguồn ghi không đề xuất ADR mới. |
| DB-1129 | D05-02-PH03 | Tập nguồn ghi không có đề xuất ADR. |
| DB-1130 | D05-02-PH04 | Chỉ là dòng tiêu đề bảng của phụ lục, không phải đề nghị. |
| DB-1132 | D05-02-PH08 | Là ghi chú còn mở của PH-08 về lịch ngày làm việc (Q08-43), nguồn thuộc PH-18, không phải đề nghị sửa PH-11, 12, 13. |
| DB-1137 | D05-02-PH09 | Chỉ ghi nhận lệch so với SRS cũ đã có ở bảng 11.3 của FRS PH-09, không phải đề nghị sửa. |
| DB-1147 | D05-02-PH10 | Đây là dòng tiêu đề của bảng đề nghị, không phải một đề nghị riêng. |
| DB-1150 | D05-02-PH10 | Mô tả nhóm tiêu thụ dh-flow-{tenant}-{flow} nằm ở FRS PH-04 §4 (đã có); ca kiểm thử TC-10-087 thuộc PH-10. |
| DB-1152 | D05-02-PH10 | Đây là dòng tiêu đề của bảng đề nghị, không phải một đề nghị riêng. |
| DB-1166 | D05-02-PH11 | Là hàng tiêu đề bảng. |
| DB-1167 | D05-02-PH11 | Nguồn ghi 'Không chấp nhận': mã giữ chỗ không có ca kiểm thử. |
| DB-1189 | D05-02-PH17 | Giữ câu hỏi mở Q17-14 (nhãn AI trên tệp xuất), không phải đề nghị sửa. |
| DB-1195 | D05-02-PH17 | Công cụ ph09 gắn cố định với tệp PH-09 đúng như thiết kế; chỉ bản PH-17 đổi đường dẫn nên không cần sửa. |
| DB-1205 | D05-02-PH20 | Chưa đổi: ERR-20-055 ở API-20-065 thuộc quyết định giữa FRS FR-20-034 và FR-20-061, cần rà riêng tập TC/API. |
| DB-1208 | D05-02-PH20 | Chưa đổi: mã lỗi cho nâng cấp khẩn thiếu thời gian báo trước cần rà riêng FR-20-061 và API; ca TC vẫn chấp nhận 400 hoặc 422. |
| DB-1218 | DE-NGHI-DONG-BO | Đổi tên schema ph04 cần kịch bản di trú cho bảng W2 của apps/control và sửa hàng trăm dẫn chiếu; D00-04 đã ghi ngoại lệ chờ đợt đồng bộ. |
| DB-1224 | DE-NGHI-DONG-BO | Là ghi chú giả định về lịch sử phiên bản, không phải đề nghị sửa; bảng lịch sử D03-05-03, 04 đã có dòng 0.2, 0.3 và nay thêm 0.4, không có dòng 0.1 giả định. |
| DB-1225 | DE-NGHI-DONG-BO | Không có tệp docx hoặc pdf trong cây tài liệu |
| DB-1228 | DE-NGHI-DONG-BO | Là nhận xét về cảnh báo Spectral còn lại, không phải đề nghị sửa; nâng mức chặn để dành đợt sau. |

: Đề nghị không làm và lý do

## 6. Kết quả soát bằng công cụ

Sau khi sửa, toàn bộ bộ tài liệu được soát lại bằng các công cụ của cổng CI để bảo đảm việc đồng bộ không gây lỗi mới.

| Công cụ | Kết quả sau đợt đồng bộ |
|---|---|
| `kiem_tra_ma.py` | 14.171 mã; liên kết hỏng 0; lỗi mới 0; còn 20 mã trùng và 18 mã thiếu đã ghi nhận (dưới đây); 17 lỗi cũ đã hết và được gỡ khỏi danh sách ngoại lệ |
| `kiem_tra_yaml.py` | 47 tệp OpenAPI và AsyncAPI, 0 lỗi |
| `chay_ddl.py` | DDL, kiểm thử cô lập, Liquibase của 20 phân hệ và bước chung chạy đạt trên PostgreSQL 16 |
| `sinh_backlog.py` | Sinh lại D02-05, D02-05-01, Gherkin và CSV theo FRS mới |

: Kết quả soát sau đợt đồng bộ

Lỗi còn ghi nhận:

1. **Mã API trùng ở D03-04-PH04 (19) và D03-04-PH07 (1).** Một số mã `API-04-nnn` đang dùng cho nhiều operation cùng tài nguyên (ví dụ `GET` và `PUT` thành viên). Tách mã kéo theo khoảng 330 dẫn chiếu ở FRS, màn hình và test case PH-04 nên để ở lượt sửa riêng của PH-04 (đề nghị DB-0409).
2. **ADR-014, 015, 016, 017, 019** được nhắc khi đối chiếu với ADR cũ của repo `docs/05-adr`; bộ tài liệu này không có tệp cùng số. Đây là báo nhầm của công cụ, giữ trong danh sách ngoại lệ.
3. **API-07-076, EVT-07-11, EVT-04-15, CMP-Dropdown, CMP-FileDropzone** được nhắc nhưng chưa có định nghĩa ở tài liệu gốc; giữ trong danh sách ngoại lệ, xử lý cùng lượt sửa của PH-04, PH-07 và D03-05.
4. **Mã đề xuất trong câu hỏi mở** (API-03-097, API-04-092, 093, API-06-126, API-12-112, API-14-093, PERM-01-review-claim) chỉ xuất hiện ở sổ này như phương án chờ chốt, nên công cụ báo thiếu; khi câu hỏi được trả lời, mã sẽ được định nghĩa ở tài liệu gốc hoặc bỏ. Riêng `PERM-13-read` là mã cũ được nhắc trong lý do một đề nghị.

## 7. Việc còn lại sau đợt này

Ba việc dưới đây chưa thuộc phạm vi đợt đồng bộ và được chuyển tiếp.

1. Trả lời các câu hỏi mục 4; với câu đã có đề xuất kỹ thuật rõ, có thể chấp nhận cả nhóm rồi áp trong một lượt sửa.
2. Tách mã API trùng của PH-04, PH-07 (mục 6).
3. Các đề nghị nhắm tới D05-03/04/05 và D06-01…05 được xử lý khi viết các tài liệu đó (sau khi có mã nguồn).

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: kết luận cho từng đề nghị đồng bộ, quy tắc chọn tên và quyết định áp chung, câu hỏi mở Q380 trở đi, kết quả soát |
