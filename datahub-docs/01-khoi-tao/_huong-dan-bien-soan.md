# Hướng dẫn biên soạn chung cho D01-01 và D01-02 (dành cho người viết từng chương)

Tệp này là quy tắc viết cho mọi người (và agent) cùng viết hai tài liệu nhóm Khởi tạo. Đọc hết trước khi viết.

## 1. Đọc trước khi viết

1. `datahub-docs/01-khoi-tao/_gia-dinh-nen.md` — mọi con số, mốc, đội ngũ, quy mô, phương án. **Không tự đặt con số khác.** Nếu thấy cần đổi, ghi đề xuất ở cuối chương trong mục "Ghi chú cho người tổng hợp" thay vì tự đổi.
2. Repo hiện có (chỉ tham khảo, không sửa): `docs/02-architecture/README.md`, `docs/05-adr/README.md`, `docs/07-srs/*`, `docs/08-implementation/01..04*.md`, `docs/01-legal/README.md`, `docs/06-impact/README.md`, `AGENTS.md`.
3. Tài liệu hệ cũ: `/mnt/project-files/lgsp_document/` (docx/doc; đọc bằng `pandoc -t plain` hoặc python-docx; tệp `.doc` dùng `soffice --headless --convert-to docx` vào thư mục tạm của bạn). Đây là ổ mạng: luôn dùng đường dẫn tuyệt đối có dấu `/` cuối thư mục, không tìm kiếm toàn bộ thư mục gốc, không ghi vào đó.
4. Tóm tắt pháp lý (nếu có): `/tmp/claude-0/-home-claude/fe7c02a9-97ad-58f1-a4b8-29e63e2a80c8/scratchpad/legal-brief.md`. **CẬP NHẬT QUAN TRỌNG:** văn bản hiện hành cho dự án là **Nghị định 224/2026/NĐ-CP** ngày 24/6/2026 quy định chi tiết Luật Chuyển đổi số 148/2025/QH15 (hiệu lực 01/7/2026; Điều 90 bãi bỏ NĐ 45/2026, vốn đã thay NĐ 73/2019 và NĐ 82/2024; Điều 91 áp dụng cho dự án chưa có quyết định đầu tư). Chi phí theo Thông tư 39/2026/TT-BKHCN. Thuật ngữ mới: "dự án đầu tư hệ thống chuyển đổi số", "thuê dịch vụ công nghệ số". Không viện dẫn NĐ 73/2019 hay NĐ 45/2026 như văn bản áp dụng.

## 2. Văn phong (bắt buộc)

- Tiếng Việt tự nhiên, chuyên nghiệp, câu hoàn chỉnh có chủ ngữ, vị ngữ, có liên từ chuyển ý. Không viết kiểu điện tín, không nối chuỗi bằng dấu chấm phẩy hay mũi tên, không dùng gạch ngang dài (em-dash) để nối ý.
- Mỗi mục quan trọng giải thích: nó là gì, hoạt động thế nào, vì sao quan trọng, liên hệ với phần khác, ví dụ hoặc hệ quả thực tế. Mức chi tiết khoảng 7/10: người đọc am hiểu không cần hỏi lại.
- Bullet và bảng chỉ dùng cho thông tin rời rạc thật sự. Mỗi bảng có một đoạn dẫn trước hoặc giải thích sau. Mỗi bullet quan trọng là một câu đầy đủ.
- Thuật ngữ tiếng Anh chuẩn ngành được giữ trong ngoặc sau thuật ngữ tiếng Việt lần đầu xuất hiện, ví dụ "cổng nghiệm thu (acceptance gate)".
- Không khẩu hiệu, không văn hoa, không kết luận lặp lại. Không "TBD": điều chưa biết ghi thành câu hỏi mở có mã `Q-D0101-nn` hoặc `Q-D0102-nn` trong mục "Câu hỏi mở" cuối chương.
- Hai tầng người đọc: đầu mỗi chương có một đoạn "Tóm tắt cho hội đồng thẩm định" (3–6 câu: kết luận, con số chính); phần sau là chi tiết cho quản lý dự án và đội kỹ thuật.

## 3. Định dạng

- Quy ước chung của bộ tài liệu nằm ở `datahub-docs/00-chung/D00-01-thuat-ngu-quy-uoc.md` (đọc §3 mã truy vết, §7 căn cứ pháp lý với mã `CMP-LAW-nn`, §8 trình bày). Hai tài liệu cuối cùng là hai tệp đơn `D01-01-bao-cao-nghien-cuu-kha-thi.md` và `D01-02-ke-hoach-du-an.md`; trong lúc viết song song, mỗi chương là một tệp riêng trong `datahub-docs/01-khoi-tao/_parts/D01-01/` hoặc `_parts/D01-02/`, người tổng hợp sẽ ghép lại.
- Markdown GitHub. Mỗi tệp chương bắt đầu bằng tiêu đề cấp 2 `## N. Tên chương` (N theo số đã giao), mục con `### N.1.`, `#### N.1.1.`. Không có khối YAML trong tệp chương.
- Văn bản pháp luật đã có mã ở D00-01 §7 thì dùng mã đó (ví dụ CMP-LAW-01). Văn bản mới chưa có mã (ví dụ NĐ 224/2026/NĐ-CP, TT 39/2026/TT-BKHCN) thì ghi tên đầy đủ và liệt kê trong "Ghi chú cho người tổng hợp" để đề xuất mã mới.
- Sơ đồ dùng Mermaid trong khối ```mermaid. Chỉ dùng cú pháp Mermaid ổn định (flowchart, sequenceDiagram, gantt, stateDiagram-v2, quadrantChart, timeline). Nhãn tiếng Việt đặt trong ngoặc kép. Kiểm tra cú pháp bằng mắt cẩn thận: không dùng ký tự `()`, `[]`, `:` trần trong nhãn nếu không có ngoặc kép.
- Số: dấu chấm phân cách hàng nghìn, dấu phẩy thập phân (1.250,5). Tiền: triệu đồng. Ngày: dd/mm/yyyy.
- Mã truy vết: `PH-xx`, `RSK-nn`, `BO-nn`, `KPI-nn`, `SEC-nn`, `ADR-nnn`, `LGC-{khối}-nn`, `Gx` (cổng), `Wx` (wave). Tham chiếu tài liệu khác bằng mã D (D02-01, D03-01…), không chép lại nội dung của tài liệu đó.
- Nguồn bên ngoài (văn bản pháp luật, giá) ghi bằng liên kết Markdown tới trang đã mở được; không bịa số hiệu văn bản. Nếu chưa xác minh được thì ghi rõ "(chưa xác minh hiệu lực)".

## 4. Phạm vi ghi

- Chỉ ghi vào các tệp chương được giao trong thư mục `datahub-docs/01-khoi-tao/...`. Không sửa `docs/`, không sửa tệp chương của người khác, không sửa `_gia-dinh-nen.md`.
- Không chạy `git commit`/`git push`; người tổng hợp sẽ commit.
- Kết thúc mỗi tệp chương bằng mục "Câu hỏi mở" (nếu có) và "Ghi chú cho người tổng hợp" (nếu có đề xuất sửa giả định hoặc phát hiện mâu thuẫn).

## 5. Tài liệu nền đã có (cập nhật 21/11/2026) — bắt buộc dẫn chiếu, không đặt mã mới trùng

- `datahub-docs/02-yeu-cau/D02-01-brd.md`: mục tiêu nghiệp vụ **BO-01…BO-09**, chỉ số **KPI-01…KPI-18**, bên liên quan **SH-01…SH-12**, phạm vi và phân đợt (§8.3). D01-01 và D01-02 dùng đúng các mã này, không tự đặt BO/KPI mới; nếu cần chỉ số mới thì đề xuất ở "Ghi chú cho người tổng hợp".
- `datahub-docs/02-yeu-cau/D02-02-srs.md`: NFR cấp hệ thống (NFR-00-xxx) — dẫn chiếu khi nêu hiệu năng, sẵn sàng, RPO/RTO.
- `datahub-docs/03-thiet-ke/D03-01-sad.md`: kiến trúc, stack, rủi ro kiến trúc **RSK-A01…RSK-A05**. Sổ rủi ro dự án ở D01-02 dùng mã **RSK-01…** và dẫn chiếu RSK-A khi trùng chủ đề.
- `datahub-docs/03-thiet-ke/D03-10-thiet-ke-da-tenant.md`: mô hình đa tenant đã chọn.
- `datahub-docs/00-chung/adr/ADR-001…013`: quyết định kiến trúc đã có.
- CMP-LAW-14 trong D00-01 đang ghi NĐ 45/2026, nhưng văn bản đúng là NĐ 224/2026/NĐ-CP; dùng tên đầy đủ NĐ 224/2026 và ghi chú để luồng lõi sửa mã.
Nếu số liệu trong các tài liệu này khác `_gia-dinh-nen.md`, ghi rõ mâu thuẫn ở "Ghi chú cho người tổng hợp".
