# Xuất bản .docx

Nguồn của bộ tài liệu là Markdown. Bản .docx để trình hội đồng thẩm định được sinh tự động, không sửa tay, để nguồn và bản trình luôn khớp nhau.

## Thành phần

| Tệp | Vai trò |
|---|---|
| `build-docx.sh` | Xuất tất cả tài liệu `D*.md` và `ADR-*.md`, hoặc các tệp chỉ định, ra `build/out/`; `DH_PDF=1` xuất thêm PDF và điền sẵn số trang vào mục lục |
| `make_reference.py` | Sinh `reference.docx`: thể thức NĐ 30/2020/NĐ-CP (A4; lề trên, dưới 20 mm, trái 30 mm, phải 15 mm; Times New Roman 13 pt) cộng các kiểu của khuôn trình bày: bìa, đề mục, mục lục, chú thích bảng và hình, nhãn bảng đặc tả |
| `trinh-bay.lua` | Bộ lọc pandoc: trang bìa, trang thông tin tài liệu (lịch sử phiên bản, ký duyệt, phân phối), chỗ đặt mục lục; đánh số "Bảng n." và "Hình n."; khối `::: dac-ta` và bảng "Trường \| Nội dung" thành bảng đặc tả hai cột; tách bước "1. … 2. …" và ngoại lệ ngăn bằng "·" trong ô thành danh sách; Mermaid thành ảnh PNG; độ rộng cột theo nội dung |
| `hau_xu_ly.py` | Hậu xử lý .docx: mục lục ba cấp có liên kết và số trang, kẻ khung và tô nền bảng, đầu trang (mã, tên tài liệu), chân trang "Trang x / y", bìa không đầu chân trang |
| `cap_nhat_muc_luc.py` | Mở .docx bằng LibreOffice không giao diện, cập nhật mục lục, xuất PDF và ghi số trang để điền vào mục lục của .docx |
| `mermaid-config.json`, `puppeteer.json` | Giao diện sơ đồ Mermaid (màu, phông) và tham số trình duyệt cho `mmdc` |

Quy chuẩn viết nguồn Markdown để bản xuất đúng khuôn (chú thích bảng, hình, khối đặc tả, metadata bìa) ở [K-TRINH-BAY](../00-chung/khuon/K-TRINH-BAY.md).

## Cách dùng

```bash
# Cài công cụ (một lần)
sudo apt-get install -y pandoc libreoffice && pip install python-docx
npm install -g @mermaid-js/mermaid-cli   # vẽ sơ đồ; trong container dùng Chromium sẵn có qua PUPPETEER_EXECUTABLE_PATH

# Xuất toàn bộ
datahub-docs/build/build-docx.sh

# Xuất một tài liệu, kèm PDF và mục lục có số trang
DH_PDF=1 datahub-docs/build/build-docx.sh 02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md
```

Trang bìa lấy `ten`, `ma_tai_lieu`, `phien_ban`, `trang_thai`, `ngay`, `nguoi_doc` trong khối metadata; các trường tùy chọn `mo_ta`, `tai_lieu_lien_quan`, `co_quan`, `du_an`, `don_vi_soan_thao`, `ky_duyet` (danh sách `vai_tro`, `ho_ten`, `chuc_vu`). Thông tin cơ quan chủ quản, chủ đầu tư để trống theo chỉ đạo của chủ đầu tư; khi có, thêm `co_quan` vào metadata. Mục "Lịch sử phiên bản" ở cuối nguồn được chuyển lên trang thông tin tài liệu.

Thư mục `build/out/` không được đưa vào Git.
