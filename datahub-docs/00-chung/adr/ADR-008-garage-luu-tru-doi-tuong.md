---
ma_tai_lieu: ADR-008
ten: Garage làm kho lưu trữ đối tượng tương thích S3
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-008 · Garage làm kho lưu trữ đối tượng tương thích S3

## Bối cảnh

Datahub cần lưu tệp nhập danh mục, tệp đối soát thanh toán, đặc tả API, bằng chứng kiểm toán dạng WORM và bản sao lưu. MinIO bản cộng đồng đã ngừng phát triển năm 2026.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. MinIO | Phổ biến | Bản cộng đồng ngừng phát triển; rủi ro giấy phép AGPL |
| B. **Garage** | Nhẹ, đa vùng, AGPL nhưng dùng qua giao thức S3 không bị ràng buộc mã | Chưa có object lock đầy đủ |
| C. SeaweedFS hoặc Ceph RGW | Có object lock (Ceph) | Ceph vận hành nặng |

## Quyết định

Chọn **Garage làm mặc định** cho lưu trữ tệp nghiệp vụ. Với bằng chứng kiểm toán cần WORM, dùng **SeaweedFS hoặc Ceph RGW có object lock**, hoặc kho WORM do hạ tầng tỉnh cung cấp. Ứng dụng chỉ dùng API S3 chuẩn để thay được nhà cung cấp. Mỗi tenant một bucket, mã hóa phía máy chủ.

## Hệ quả

Tích cực: không phụ thuộc MinIO. Tiêu cực: có thể phải vận hành hai kho đối tượng; D03-09 nêu cấu hình tối thiểu.

## Truy vết

REQ-13, REQ-19; D03-09. Tương ứng ADR-020 phần B của repo.
