---
ma_tai_lieu: ADR-065
ten: Điều khiển runtime bằng trạng thái mong muốn trong Git, kèm kênh lệnh có ký qua Kafka cho tác động nhanh và dừng khẩn
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, ATTT, vận hành
---

# ADR-065 · Điều khiển runtime: Git và lệnh có ký

## Bối cảnh

ADR-013 cấm giao diện ra lệnh trực tiếp tới runtime. Nhưng tạm dừng một luồng đang làm quá tải hệ đích phải có hiệu lực trong vài giây, trong khi chu kỳ đồng bộ của Argo CD tính bằng phút. Bus cũ dùng JMX/Jolokia, không kiểm toán được.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ qua Git | Một nguồn sự thật | Chậm 1–3 phút; không đủ cho sự cố |
| B. **Git là nguồn sự thật; kèm lệnh có ký Ed25519 qua topic `dh.integration.runtime.command.v1`, runtime xác nhận, đối soát vào Git trong 5 phút** | Nhanh; kiểm toán đủ; không mở cổng quản trị | Hai kênh cần đối soát |
| C. API quản trị của runtime qua mesh | Nhanh | Mở thêm bề mặt tấn công; control plane gọi thẳng data plane |

## Quyết định

Chọn **phương án B**. Runtime chỉ thi hành lệnh có chữ ký hợp lệ, chưa hết hạn, đúng tenant của luồng. Lệnh khẩn đi trước, Git ghi sau; lệnh thường ghi Git và gửi lệnh đồng thời. Bộ đối soát của `dh-integration` báo động nếu trạng thái thực tế lệch Git quá 5 phút.

## Hệ quả

Khóa ký của `dh-integration` quản lý ở OpenBao, xoay vòng 90 ngày; runtime nhận khóa công khai qua cấu hình. Topic điều khiển là topic hệ thống, chỉ `dh-integration` được ghi.

## Truy vết

FR-04-050; BR-04-018; GAP-04-11; ADR-013.
