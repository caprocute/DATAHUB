---
ma_tai_lieu: ADR-183
ten: Khung di trú hệ cũ: worker dh-migrate đọc JDBC chỉ đọc, ghi vào phân hệ đích qua API nhập, có chạy thử và báo cáo đối chiếu
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-18, DBA, ATTT, Hội đồng thẩm định
---

# ADR-183 · Khung di trú dh-migrate

## Bối cảnh

FR-00-090…093 giao công cụ di trú cho PH-18: chuyển danh mục Aita, HTTT, API, plan, subscription, topic, luồng Camel XML, giao dịch thanh toán; sửa lỗi dữ liệu cũ; báo cáo đối chiếu; không mang thông tin xác thực cũ. Nhiều phân hệ đích đã có chức năng nhập riêng (PH-01, PH-02, PH-07, PH-19).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Script SQL ghi thẳng vào schema các phân hệ | Nhanh | Vượt RLS và kiểm tra nghiệp vụ, phá ranh giới module, không kiểm toán |
| B. Mỗi phân hệ tự di trú độc lập | Phân hệ hiểu dữ liệu của mình | Không có thứ tự phụ thuộc chung, không có báo cáo đối chiếu và tiêu chí cắt chuyển chung |
| C. **Khung chung `dh-migrate` (Spring Batch, Job K8s trong `dh-batch`): đọc nguồn JDBC chỉ đọc (IF-07), chuyển đổi theo bộ chuyển từng loại đối tượng, ghi qua API nhập của phân hệ đích (scope `ops:migration-import`)** | Một kế hoạch, một thứ tự, một báo cáo; tôn trọng kiểm tra nghiệp vụ của đích | Phân hệ đích phải có API nhập lũy đẳng |

: Các phương án được cân nhắc cho ADR-183

## Quyết định

Chọn **phương án C**. Mỗi lần chạy là chạy thử (không ghi) hoặc chạy thật (bốn mắt); lặp lại không tạo bản trùng; trường thông tin xác thực bị loại và đánh dấu cấp lại; báo cáo đối chiếu số lượng và tổng kiểm tra từng loại.

## Hệ quả

Tích cực: di trú lặp lại được nhiều lần trước ngày cắt chuyển, có bằng chứng đối chiếu cho nghiệm thu. Tiêu cực: tốc độ ghi phụ thuộc API của đích; phân hệ có nhập riêng giữ chức năng đó và được khung gọi lại.

## Truy vết

FR-18 nhóm I; FR-00-090…093; REQ-22; ADR-073; D01-01 chiến lược thay dần.
