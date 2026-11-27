---
ma_tai_lieu: ADR-181
ten: Hàng đợi lỗi hợp nhất: chỉ mục trên PostgreSQL, payload gốc bất biến, payload lớn ở Garage, liên thông DLQ sự kiện của PH-10
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-18, DBA, ATTT, Hội đồng thẩm định
---

# ADR-181 · DLQ hợp nhất

## Bối cảnh

Bản tin lỗi đến từ nhiều nguồn: luồng PH-04 qua topic `{tenant}.ops.dlq.v1`, inbox lỗi của PH-01, PH-19, lô lỗi PH-06, quy tắc chất lượng `DQ_FAIL` của PH-08, và DLQ tầng sự kiện do PH-10 giữ. Người vận hành cần một màn chung để tìm, phân loại, sửa có kiểm soát, phát lại và bỏ qua có lý do (LGC-BUS-037). Hệ cũ không có DLQ, bản tin lỗi mất âm thầm.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Duyệt trực tiếp topic Kafka | Không lưu thêm | Không lọc, không gán người xử lý, không lưu trạng thái; Kafka giữ 14 ngày rồi mất |
| B. Sao chép mọi DLQ, kể cả DLQ sự kiện của PH-10, vào PH-18 | Một kho duy nhất | Hai bản nội dung, trùng trách nhiệm phát lại với PH-10, tăng diện lộ dữ liệu |
| C. **Chỉ mục và trạng thái ở `ph18_ops`, payload gốc không sửa, bản sửa là bản ghi riêng, payload lớn hơn 256 KB ở Garage `dh-{tenant}-ops`; DLQ của PH-10 được liên thông qua API-10 (chỉ siêu dữ liệu)** | Tìm, lọc, thống kê nhanh; giữ bằng chứng gốc; không trùng trách nhiệm với PH-10 | Màn chung phải gọi hai nguồn và chịu được khi PH-10 vắng |

: Các phương án được cân nhắc cho ADR-181

## Quyết định

Chọn **phương án C**. Mỗi mục DLQ có khóa khử trùng, hợp đồng ngữ cảnh chuẩn (lý do, số lần thử, công đoạn, mã lỗi, luồng, phiên bản, `traceparent`, tenant, phân hệ nguồn); thiếu trường bắt buộc thì vào trạng thái `POISON` khi đến qua topic, còn API ghi DLQ từ chối ngay (BR-18-013). Trường nhạy cảm đã được nguồn mã hóa trước khi vào DLQ; xem payload cần quyền riêng và lý do.

## Hệ quả

Tích cực: không bản tin lỗi nào biến mất; mọi thao tác có kiểm toán; PH-18 sập không chặn đường chính vì nguồn vẫn ghi Kafka. Tiêu cực: phân vùng tháng làm khử trùng phải đi qua bảng `inbox_event` có cửa sổ theo tham số `18.dlq.dedup-window-days` (mặc định 7 ngày, miền 1 đến 30, FRS PH-18 §8.2), cộng với tra mục chưa đóng cùng khóa để chỉ tăng bộ đếm lần gặp (BR-18-015, Q18-50). Topic `{tenant}.ops.dlq.v1` giữ 14 ngày, nên PH-18 được vắng tối đa 14 ngày mà không mất bản tin lỗi (NFR-18-016).

## Truy vết

FR-18 nhóm B, C; LGC-BUS-037; FR-04 xử lý lỗi; FR-10 nhóm G; D03-03-PH18 khối B.
