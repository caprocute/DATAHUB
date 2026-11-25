# Xuất bản .docx

Nguồn của bộ tài liệu là Markdown. Bản .docx để trình hội đồng thẩm định được sinh tự động, không sửa tay, để nguồn và bản trình luôn khớp nhau.

## Thành phần

| Tệp | Vai trò |
|---|---|
| `build-docx.sh` | Xuất tất cả tài liệu `D*.md` và `ADR-*.md`, hoặc các tệp chỉ định, ra `build/out/` |
| `make_reference.py` | Sinh `reference.docx` theo thể thức NĐ 30/2020/NĐ-CP: khổ A4, lề trên và dưới 20 mm, trái 30 mm, phải 15 mm, phông Times New Roman 13 pt, đề mục in đậm |
| `mermaid.lua` | Bộ lọc pandoc chuyển khối Mermaid thành ảnh bằng `mmdc`; nếu máy không có `mmdc` thì giữ nguyên khối mã |
| `puppeteer.json` | Tham số trình duyệt cho `mmdc` khi chạy trong container |

## Cách dùng

```bash
# Cài công cụ (một lần)
sudo apt-get install -y pandoc && pip install python-docx
npm install -g @mermaid-js/mermaid-cli   # tùy chọn, để vẽ sơ đồ

# Xuất toàn bộ
datahub-docs/build/build-docx.sh

# Xuất một tài liệu
datahub-docs/build/build-docx.sh 02-yeu-cau/D02-01-brd.md
```

Trang bìa lấy `ten` trong khối metadata làm tiêu đề. Thông tin cơ quan chủ quản, chủ đầu tư, đơn vị tư vấn ở trang bìa được để trống theo chỉ đạo của chủ đầu tư; khi có thông tin, bổ sung vào `reference.docx` hoặc thêm trường metadata tương ứng.

Thư mục `build/out/` không được đưa vào Git.
