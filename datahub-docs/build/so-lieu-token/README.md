# Số liệu hiệu suất token khi viết tài liệu phân hệ

Thư mục này giữ số liệu nền (cách viết cũ) và số liệu của từng bộ tài liệu viết theo quy tắc tối ưu token (project instructions ngày 26/11/2026, công cụ ở D00-04). Mục đích là lập bảng so sánh sau khi xong bộ đầu tiên theo cách mới.

## 1. Cách đo

| Chỉ số | Cách lấy | Ghi chú |
|---|---|---|
| Kích thước đầu ra | `python3 datahub-docs/build/tools/do_hieu_suat.py PH{nn}` | Byte, từ, token ước lượng của bảy tập |
| Token ước lượng | byte UTF-8 / 3 | Giả định, sai số khoảng ±25%; cùng công thức cho mọi bộ nên so sánh vẫn có nghĩa |
| Ngữ cảnh nạp trước khi viết | Cùng script, dòng cuối | Cách cũ là cận trên (tài liệu chung + nguyên bộ PH-07); thực tế luồng cũ đọc từng phần nhưng đọc lại nhiều lần |
| Thời lượng luồng | Thời điểm tạo và hoạt động cuối của thread trong dự án | Ghi tay |
| Số commit | Git log trên các tệp của bộ | Script tự đếm |
| Lần cạn hạn mức | Ghi tay khi phiên dừng vì hết hạn mức | |
| Lỗi soát tự động | `kiem_tra_ma.py`, số lỗi mới khi mở PR | |
| Vòng sửa sau soát chéo | Số lần sửa lại sau lượt soát Sonnet cuối phân hệ | |

## 2. Số liệu nền (26/11/2026, cách cũ)

Số liệu máy đọc ở [`nen-2026-11-26.json`](nen-2026-11-26.json).

| Tập | PH-07 (KB / ~k token) | PH-04 (KB / ~k token) |
|---|---|---|
| FRS | 356 / 121 | 171 / 58 |
| Use case | 187 / 64 | 91 / 31 |
| SDD | 203 / 69 | 86 / 29 |
| CSDL | 85 / 29 | 50 / 17 |
| API | 27 / 9 | 42 / 14 |
| Màn hình | 233 / 79 | 191 / 65 |
| Test case | 282 / 96 | 183 / 62 |
| **Tổng bảy tập** | **1.373 / 469** | **815 / 278** |
| Tệp kèm (số tệp, KB) | 96, 1.528 | 46, 506 |
| Commit chạm bộ tài liệu | 16 | 32 |
| Thời lượng luồng | Từ 21/11 trên tài khoản khác (hết hạn mức giữa chừng), hoàn thiện 25/11 16:05–17:34 UTC | 25/11 16:44–18:26 UTC cho bản 0.1, đồng bộ giao diện tới 26/11 00:39 UTC |
| Lần cạn hạn mức đã biết | Ít nhất 1 (21–22/11, chuyển tài khoản); 4–5 subagent Opus song song làm cạn nhanh | Không ghi nhận |

Ngữ cảnh nạp trước khi viết một phân hệ: **cách cũ khoảng 1.659 KB (~566k token, cận trên)**, **cách mới 37 KB (~13k token)** gồm D00-04 và bảy khuôn.

## 3. Bảng so sánh (bộ theo cách mới: PH-05, PH-10, 26/11/2026)

Số liệu máy đọc của PH-05 ở [`PH05.json`](PH05.json), nhật ký mốc giờ ở [`PH05-nhat-ky.md`](PH05-nhat-ky.md); của PH-10 ở [`PH10.json`](PH10.json).

| Chỉ số | PH-07 (cũ) | PH-04 (cũ) | PH-19 (cũ) | PH-05 (mới) | PH-10 (mới, mỗi tập một phiên) | Chênh lệch PH-05 so với PH-04 |
|---|---|---|---|---|---|---|
| Đầu ra bảy tập (KB / ~k token) | 1.373 / 469 | 815 / 278 | 1.133 / 387 | 603 / 206 | 1.060 / 362 | −26% |
| Tệp kèm (số tệp, KB) | 96, 1.528 | 46, 506 | 55, 808 | 57, 666 | 76, 1.363 | +11 tệp (công cụ sinh, gherkin) |
| Ngữ cảnh nạp trước khi viết (~k token) | ~566 (cận trên) | ~566 (cận trên) | ~566 (cận trên) | ~13 khuôn và D00-04, cộng ~35 tài liệu gốc mở thêm (SRS-PH-05 69 KB, đoạn D02-08, ADR-067, đoạn SDD PH-04) | ~13 brief chung, D00-04, khuôn; mỗi phiên tập thêm Phụ lục A của FRS (~25 KB) và bảng tổng hợp các tập trước | khoảng −90% |
| Số phiên viết | nhiều, qua 2 tài khoản | nhiều | nhiều | 1 phiên cho cả bảy tập, ghi và commit theo từng tập, có một lần nén ngữ cảnh | 10 phiên con: 7 tập + 2 đợt hấp thụ đề nghị vào FRS + 1 rà chéo Sonnet; UC/SDD/CSDL song song, API/màn hình song song; không nén ngữ cảnh | Quy tắc "một phiên mỗi tập" chưa làm đúng |
| Thời lượng luồng (giờ) | nhiều ngày | ~1,7 cho 0.1 | | ~1,4 (02:29–03:52 UTC, gồm rà chéo và sửa gộp) | ~1,9 (04:05–06:00 UTC, gồm rà chéo) | nhanh hơn PH-04 khoảng 18%, đã gồm rà chéo |
| Commit chạm bộ tài liệu | 16 | 32 | 27 | 16 | 25 | −50% |
| Lần cạn hạn mức | ≥ 1 | 0 | | 0 | 0 (tối đa 3 phiên con song song) | ngang |
| Lỗi soát tự động khi mở PR (`kiem_tra_ma.py`, lỗi mới) | | | | 0 | 0 | |
| Vòng sửa sau soát chéo | | | | 1 vòng, 40 phát hiện, sửa gộp một commit | 1 vòng, 15 phát hiện (enum 0), sửa gộp một commit | |
| Mục bắt buộc thiếu so với dàn ý | 0 | 0 | 0 | 0 (viết theo khuôn, đối chiếu bằng mục lục) | 0 | ngang |

Nhận xét. Đầu ra gọn hơn chủ yếu ở màn hình (−48%) và use case (−34%) nhờ khuôn bỏ phần lặp và sổ tra cứu thay cho chép lại định nghĩa chung. Ngữ cảnh nạp giảm mạnh nhất. Hai việc chưa đạt: cả bảy tập chạy trong một phiên (phải nén ngữ cảnh một lần), và 40 phát hiện rà chéo cho thấy viết liền mạch vẫn lệch mã giữa các tập (loại kết nối, enum CDC, giới hạn kích thước); bộ sau nên chạy `kiem_tra_ma.py` kèm đối chiếu enum với FRS sau mỗi tập thay vì chỉ cuối bộ.


Nhận xét về PH-10. Đây là bộ đầu tiên làm đúng quy tắc "mỗi tập một phiên": mỗi tập do một phiên con riêng viết, ngữ cảnh mỗi phiên chỉ gồm brief chung, khuôn, Phụ lục A "Bảng mã và enum chuẩn" của FRS và bảng tổng hợp của tập trước. Đề nghị bổ sung của các tập sau (46 mục) được gom về FRS hai đợt (0.2 và 0.3) thay vì để mỗi tập tự đặt mã. Kết quả: rà chéo chỉ còn 15 phát hiện, không lệch enum nào (PH-05 là 40, nhiều nhất ở enum), và không phiên nào phải nén ngữ cảnh. Đổi lại, đầu ra lớn hơn PH-05 khoảng 76%: các phiên con đều vượt mức kích thước được giao (FRS 246 KB so với mục tiêu 120–150 KB, màn hình 210 KB so với 90–120 KB) vì phạm vi PH-10 có nhiều thực thể (28 bảng, 121 operation) và mỗi phiên tự viết lại phần thuyết minh. Tổng token các phiên con xử lý (gồm cả đọc) khoảng 2,64 triệu theo số liệu của trình chạy, chưa có số tương đương cho bộ cũ nên không so trực tiếp. Bộ sau nên giao giới hạn kích thước chặt hơn trong brief và để phiên tập sau dẫn chiếu FRS thay vì nhắc lại.

Điền cột mới bằng: `python3 datahub-docs/build/tools/do_hieu_suat.py PH04 PH{nn} --json datahub-docs/build/so-lieu-token/PH{nn}.json`, cộng các chỉ số ghi tay. Chất lượng được giữ bằng hàng cuối: bộ mới phải đủ mục bắt buộc như bộ cũ.
