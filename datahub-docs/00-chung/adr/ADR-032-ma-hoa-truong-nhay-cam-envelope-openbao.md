---
ma_tai_lieu: ADR-032
ten: Mã hóa trường Nhạy cảm bằng envelope encryption qua OpenBao transit, đường nâng lên HSM
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Đội phát triển, Hội đồng thẩm định
---

# ADR-032 · Mã hóa trường Nhạy cảm bằng envelope encryption qua OpenBao transit, đường nâng lên HSM

## Bối cảnh

SAD §8.2 yêu cầu trường mức Nhạy cảm (số định danh, dữ liệu sức khỏe, thông tin tài khoản) được mã hóa ở tầng ứng dụng. Mã hóa volume (SEC-30) không chống được người có quyền đọc CSDL (quản trị CSDL, nội gián nền tảng, kẻ lấy được bản sao lưu logic) (THR-33). Trên nền tảng dùng chung, dữ liệu các tỉnh nằm chung bảng nên cần cách ly mật mã theo tenant (SEC-88). Khi nâng lên cấp độ 4, khóa gốc phải vào HSM mà không phải mã hóa lại toàn bộ dữ liệu.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. `pgcrypto` trong PostgreSQL | Dễ dùng trong SQL | Khóa đi qua câu truy vấn và có thể lộ trong log CSDL; quản trị CSDL tiếp cận được khóa |
| B. Transparent Data Encryption của CSDL | Trong suốt với ứng dụng | PostgreSQL cộng đồng chưa có TDE; không chống được người có quyền SQL |
| C. Gọi OpenBao transit `encrypt/decrypt` cho từng trường | Khóa không rời kho; đơn giản | Mỗi lần đọc/ghi một lượt gọi mạng; tải lớn lên OpenBao, tăng độ trễ |
| D. **Envelope encryption: KEK theo tenant trong OpenBao transit (không xuất được), DEK sinh qua `transit/datakey`, mã hóa trường AES-256-GCM trong ứng dụng với AAD, bộ đệm DEK ngắn hạn** | Khóa gốc không rời kho; ít lượt gọi; xoay KEK bằng bọc lại DEK; chuyển KEK sang HSM không cần mã hóa lại dữ liệu | Thư viện mã hóa phải viết cẩn thận và được review; tìm kiếm trên trường mã hóa cần cột băm riêng |

## Quyết định

Chọn **phương án D**, hiện thực trong thư viện dùng chung `dh-crypto` cho Spring Boot và Quarkus. Mỗi tenant có KEK `transit/keys/dh-{tenant}-pii` (AES-256-GCM96, `exportable=false`, `allow_plaintext_backup=false`), chính sách OpenBao chỉ cho service account của DU được phép `datakey` và `decrypt` trên KEK của tenant đang xử lý. Định dạng lưu: `{phiên bản KEK, DEK đã bọc, nonce 96 bit, bản mã, thẻ}`; AAD gồm `tenant_id`, bảng, cột, `id` bản ghi để chống tráo bản mã. DEK giải bọc được giữ trong bộ nhớ ≤ 5 phút. Tìm kiếm chính xác dùng cột HMAC-SHA256 với khóa riêng theo tenant. KEK xoay vòng mỗi 12 tháng; tác vụ nền gọi `rewrap` cho DEK. Hủy KEK khi chấm dứt tenant (xóa mật mã). **Đường nâng lên HSM:** cấu hình seal PKCS#11 cho OpenBao và đưa KEK vào HSM (hoặc bọc KEK bằng khóa trong HSM); dữ liệu và DEK đã bọc giữ nguyên, chỉ cần bọc lại DEK.

## Hệ quả

Tích cực: quản trị CSDL và bản sao lưu chỉ thấy bản mã (THR-32, THR-33); cách ly mật mã giữa tenant; đáp ứng NFR-00-021 và điểm chừa cấp độ 4 (ADR-030). Tiêu cực: OpenBao là phụ thuộc trên đường đọc dữ liệu Nhạy cảm (giảm bằng bộ đệm DEK và OpenBao HA); không truy vấn khoảng hay tìm kiếm mờ trên trường mã hóa; thư viện `dh-crypto` cần kiểm thử và review bảo mật riêng; chi phí CPU nhỏ cho AES-GCM.

## Trạng thái

Đề xuất.

## Truy vết

NFR-00-021; REQ-09; SAD §8.2; D03-07 SEC-31, SEC-34, SEC-39, SEC-88, SEC-90; ADR-003, ADR-012, ADR-030.
