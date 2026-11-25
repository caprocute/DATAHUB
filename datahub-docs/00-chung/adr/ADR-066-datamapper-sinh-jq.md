---
ma_tai_lieu: ADR-066
ten: Trình ánh xạ dữ liệu sinh biểu thức JQ, không nhúng AtlasMap hay DataMapper XSLT
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội giao diện, đội dh-runtime
---

# ADR-066 · DataMapper sinh JQ

## Bối cảnh

Tooling cũ có data mapping; Kaoto có DataMapper sinh XSLT; AtlasMap đã ngừng phát triển. Repo đã có bộ ánh xạ `contracts/cdm/mappers/*.jq` chạy được trên Camel thật (`CdmMapperTest`), và đã kiểm chứng JQ sinh từ trình ánh xạ cho kết quả giống hệt tệp JQ viết tay (SRS repo §8b.4).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. AtlasMap | Có giao diện sẵn | Ngừng phát triển; không có trong kho Maven offline; thêm cơ chế ánh xạ thứ hai |
| B. DataMapper XSLT của Kaoto | Chính thống | XSLT nặng, native hạn chế; dữ liệu Datahub chủ yếu JSON |
| C. **Sinh JQ, chạy bằng `camel-quarkus-jq`** | Một cơ chế ánh xạ; nhẹ; hỗ trợ native | Phải tự làm giao diện; ánh xạ một–nhiều phức tạp để sau |

## Quyết định

Chọn **phương án C**. Mô tả ánh xạ lưu ở `*.dhmap.json` để mở lại; biểu thức JQ là thứ duy nhất đem triển khai. Hàm `dh_map` (chuyển mã PH-07) là hàm JQ tùy biến của thư viện nền.

## Hệ quả

XML được chuyển sang JSON trước khi ánh xạ và ngược lại sau. Ánh xạ một–nhiều chưa hỗ trợ ở MVP.

## Truy vết

FR-04-020, 065; LGC-TOOL-028; GAP-04-09.
