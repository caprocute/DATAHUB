---
ma_tai_lieu: ADR-047
ten: Phân vùng theo tháng và lưu trữ dài hạn dữ liệu thanh toán
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-047 · Phân vùng theo tháng và lưu trữ dài hạn dữ liệu thanh toán

## Bối cảnh

Chứng từ thanh toán phải lưu ít nhất 10 năm (NFR-19-014), nhật ký tích hợp trực tuyến 12 tháng rồi lưu nén 5 năm (NFR-19-015). Ở QM-VUA, `integration_log` khoảng 90 GB mỗi năm, `callback_inbox` khoảng 17 GB. Xóa theo lô trên bảng lớn gây phình và khóa; tra cứu 10 triệu giao dịch phải đạt p95 ≤ 1,5 s (NFR-19-007).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Bảng đơn, xóa theo lô | Đơn giản | Phình, vacuum nặng; không đáp ứng tốc độ khi dữ liệu nhiều năm |
| B. **Phân vùng khai báo theo tháng (`pg_partman`), tách phân vùng cũ ra lưu nén ở kho đối tượng, chứng từ và biên bản ở bucket WORM** | Bảo trì theo phân vùng; truy vấn cắt tỉa phân vùng; lưu dài hạn rẻ | Không có ràng buộc duy nhất thiếu khóa phân vùng; phải có bảng phụ cho chống trùng |
| C. Kho dữ liệu riêng cho lịch sử | Tối ưu phân tích | Ngoài phạm vi (Q1 chưa lakehouse); thêm hệ phải bảo vệ |

## Quyết định

Chọn **phương án B**. Bảng giao dịch, lịch sử trạng thái, hộp nhận, nhật ký tích hợp, lượt gửi webhook phân vùng theo tháng của thời điểm tạo. Ràng buộc duy nhất cần thiết đặt ở bảng không phân vùng nhỏ: `transaction_order_guard`, `callback_nonce`, `idempotency_record` (ADR-041). Phân vùng `integration_log` quá 12 tháng được tách và xuất Parquet nén lên `dh-{tenant}-payment` rồi mới gỡ; phân vùng giao dịch chỉ được đề xuất gỡ sau 10 năm và cần phê duyệt. Tệp đối soát, biên bản, chứng từ hoàn lưu ở `dh-{tenant}-payment-worm` (Ceph RGW, khóa đối tượng chế độ `COMPLIANCE`, Q306, Q347).

## Hệ quả

Tích cực: dung lượng trực tuyến năm đầu khoảng 130 GB cộng chỉ mục, khớp định cỡ Q340. Tiêu cực: truy vấn lịch sử quá 12 tháng của nhật ký tích hợp phải khôi phục từ kho nén (OQ-19-27).

## Truy vết

NFR-19-007, 014, 015, 016; FR-19-028, 048, 054; D03-02-PH19 §15.3; D03-03-PH19; ADR-008, ADR-035; TS-19-34.
