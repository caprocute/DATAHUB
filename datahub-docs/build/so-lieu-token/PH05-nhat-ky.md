# Nhật ký đo PH-05 (cách viết mới)

Ghi tay trong lúc viết, dùng để điền bảng so sánh ở README §3.

| Mốc | Giờ UTC 26/11/2026 | Ghi chú |
|---|---|---|
| Bắt đầu luồng | 02:29 | Đọc D00-04 (16 KB), bảy khuôn (22 KB), các hàng LGC liên quan ở D00-03, mục PH-05 của D02-08, ADR-067, một đoạn SDD PH-04 về `{{conn:}}` và Kamelet nền, SRS-PH-05 của repo (69 KB, nguồn yêu cầu gốc của phân hệ) |
| FRS xong, bắt đầu UC | 02:47 | FRS 149 KB; một phiên viết, ghi theo chương (4 commit) |
| UC xong | 02:51 | 26 UC; chỉ đọc bảng tổng hợp FRS trong ngữ cảnh |
| SDD xong | 02:59 | Đọc mục lục và §3.5 SDD PH-04; một phiên, 1 commit (tệp viết một lần) |
| CSDL xong | 03:04 | DDL 23 bảng + bài kiểm cô lập 23 khối chạy trên PostgreSQL 16; một lần sửa DDL (tên Kamelet SOAP); bảng cột sinh bằng script |
| API xong | 03:13 | spec.py có sẵn từ phiên FRS; viết gen_openapi (114 lược đồ), gen_asyncapi, gen_md, check_contracts; đọc mẫu công cụ PH-04 (gen_openapi, gen_asyncapi, gen_md) và check_contracts PH-19 |
| Màn hình xong | 03:22 | 17 màn, UI-05-10 siêu chi tiết (lưới R1–R6, 8 nhóm trường, xem trước, phím, trợ năng); viết 3 phần nối tệp, 2 commit; chỉ đối chiếu tên CMP bằng grep, không đọc lại D03-05 |
| Test case xong | 03:35 | 36 kịch bản, 155 ca (83 P1), 10 UAT; công cụ chép từ ph04 bằng sed (lỗi thay -04- làm hỏng tên D03-04, đã sửa); thêm fill_doc.py ghi bảng kịch bản, số ca, ma trận vào tài liệu; vòng sửa phủ: 10 ca thêm để mọi FR mức M có ca dương và âm |
| Rà chéo + sửa gộp | 03:40–04:05 | Một subagent Sonnet rà chéo bảy quyển một lượt: 40 phát hiện (mã loại kết nối, enum CDC, giới hạn kích thước, ma trận vai trò, mã nguyên nhân thăm dò). Sửa gộp một lần trên FRS, UC, CSDL, DDL, API (sinh lại 92 thao tác, 114 lược đồ), màn hình, test case (sinh lại gherkin, xlsx); kiem_tra_ma.py: 0 lỗi mới |
