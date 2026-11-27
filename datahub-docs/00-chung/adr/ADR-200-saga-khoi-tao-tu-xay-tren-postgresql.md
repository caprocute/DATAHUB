---
ma_tai_lieu: ADR-200
ten: Saga khởi tạo tenant tự xây trên PostgreSQL
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-20, ATTT, Hội đồng thẩm định
---

# ADR-200 · Saga khởi tạo tenant tự xây trên PostgreSQL

## Bối cảnh

Khởi tạo một tenant đi qua nhiều bước (khai báo, realm, bí mật, lược đồ dữ liệu, kiểm tra khói) và phải thử lại được, bù trừ được, không tạo trùng khi gọi lại. Nền tảng đã có PostgreSQL, Kafka và outbox; chưa có công cụ điều phối quy trình riêng cho luồng này.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Temporal | Có sẵn thử lại, bù trừ, lịch sử | Thêm một hệ cần vận hành, sao lưu, DR |
| B. Camunda hoặc Flowable | Có mô hình hóa trực quan | Thêm động cơ và CSDL riêng, nặng so với một luồng cố định |
| C. **Saga tự xây trên bảng của PH-20, bước chạy qua outbox, lũy đẳng theo khóa bước** | Không thêm hạ tầng, trạng thái nằm cùng giao dịch với dữ liệu tenant | Phải tự bảo đảm lũy đẳng, bù trừ và kiểm thử đầy đủ |

## Quyết định

Chọn **phương án C**. Mỗi bước có khóa lũy đẳng, trạng thái và bước bù trừ riêng; một lượt chạy đang hoạt động duy nhất cho mỗi tenant (chỉ mục `uq_provisioning_run_active`).

## Hệ quả

Tích cực: không thêm hạ tầng, dễ kiểm toán. Tiêu cực: nhóm phải kiểm thử kỹ các nhánh lỗi và bù trừ (xem D05-02-PH20).

## Truy vết

D03-02-PH20 mục 13.6; BR-20-006; D03-03-PH20.
