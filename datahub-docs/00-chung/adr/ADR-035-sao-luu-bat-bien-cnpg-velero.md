---
ma_tai_lieu: ADR-035
ten: Sao lưu bằng CloudNativePG (plugin Barman Cloud) và Velero ra kho S3 ngoài site, bất biến
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Đội vận hành, Hội đồng thẩm định
---

# ADR-035 · Sao lưu bằng CloudNativePG (plugin Barman Cloud) và Velero ra kho S3 ngoài site, bất biến

## Bối cảnh

Sao chép DR (ADR-034) lan cả lỗi logic và mã hóa của mã độc sang site DR. Datahub cần khôi phục về thời điểm quá khứ (PITR), khôi phục một tenant riêng lẻ trên nền tảng dùng chung, và bằng chứng sao lưu cho hồ sơ cấp độ 3 (nhóm SEC-70–79). Garage chưa có khóa đối tượng đầy đủ (ADR-008). CloudNativePG đã chuyển chức năng sao lưu ra kho đối tượng sang plugin Barman Cloud qua giao diện plugin CNPG-I.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Snapshot volume (CSI VolumeSnapshot) | Nhanh | Thường cùng hệ lưu trữ với dữ liệu chạy; không có PITR; phụ thuộc CSI |
| B. pg_dump định kỳ | Đơn giản, khôi phục theo tenant | Không có PITR; RPO bằng chu kỳ; chậm với CSDL lớn |
| C. **CNPG + plugin Barman Cloud (bản sao cơ sở hằng ngày + WAL liên tục) cho PostgreSQL; xuất logic theo tenant hằng ngày; Velero (Kopia) cho tài nguyên Kubernetes và volume không tự nhân bản; đích là kho S3 có khóa đối tượng chế độ tuân thủ ở ngoài site, tài khoản quản trị riêng; bản tháng ra phương tiện ngoại tuyến** | PITR 30 ngày; khôi phục theo tenant; bất biến trước mã độc; theo quy tắc 3-2-1-1-0; công cụ mở, chuẩn S3 | Thêm kho S3 có khóa đối tượng ngoài Garage; dung lượng sao lưu khoảng 2 TB/năm cho `QM-VUA` |
| D. Phần mềm sao lưu thương mại của TTDL | Tỉnh có thể đã có | Không đồng nhất giữa các tỉnh; thường thiếu PITR theo ngữ nghĩa PostgreSQL |

## Quyết định

Chọn **phương án C**. Đích sao lưu là kho S3 có khóa đối tượng chế độ tuân thủ (Ceph RGW, chốt 25/11/2026; trước đó cân nhắc cả SeaweedFS đã kiểm chứng khóa đối tượng, thiết bị WORM của TTDL hoặc lưu trữ đối tượng của cloud Chính phủ), không phải Garage, đặt ngoài cụm và ngoài site chính. Mọi bản sao lưu được mã hóa phía máy khách bằng khóa do OpenBao quản lý. Thời gian giữ: 35 ngày cho bản ngày và WAL, 12 tháng cho bản tháng; bản tháng xuất ra phương tiện ngoại tuyến. Mọi đối tượng sao lưu có kiểm tra khôi phục tự động theo lịch ở D03-09 §8.2; kiểm tra khôi phục thất bại là cảnh báo SEV-2. Kho WORM nhật ký kiểm toán theo ADR-031 có thể dùng chung thiết bị nhưng bucket và chính sách riêng.

## Hệ quả

Tích cực: chống được mã độc tống tiền và lỗi logic; có công cụ khôi phục một tenant (RBK-04) dùng lại cho di chuyển tenant giữa các ô CSDL; bằng chứng diễn tập phục vụ hồ sơ cấp độ. Tiêu cực: phải vận hành thêm một kho S3 có khóa đối tượng; khóa mã hóa sao lưu trở thành tài sản phải bảo vệ ngoại tuyến (RSK-H04); tỉnh phải có vị trí vật lý thứ hai cho kho sao lưu.

## Truy vết

NFR-00-014, NFR-00-027, REQ-18; SEC-70–79, SEC-30–39; D03-09 §8; ADR-003, ADR-008, ADR-012, ADR-031, ADR-034. Câu hỏi mở Q341, Q342.
