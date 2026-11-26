---
ma_tai_lieu: ADR-174
ten: Lập chỉ mục tri thức theo sự kiện nguồn, chỉ dữ liệu Công khai và Nội bộ qua cổng phân loại PH-09, xóa lan truyền hai pha
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-17, nhóm PH-09, ATTT, Hội đồng thẩm định
---

# ADR-174 · Chỉ mục theo sự kiện và xóa lan truyền

## Bối cảnh

Trợ lý trả lời dựa trên chỉ mục các đoạn tri thức. Chỉ mục là bản sao dữ liệu của phân hệ khác nên có hai rủi ro: cũ (không phản ánh thay đổi) và lộ (giữ dữ liệu đã bị hạ quyền, đổi mức hay xóa). SEC-49 chỉ cho lập chỉ mục dữ liệu Công khai và Nội bộ; BR-17-029 đòi xóa trong ≤ 60 giây khi đổi phân loại hoặc thu hồi và ≤ 5 phút khi xóa nguồn.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Lập lại toàn bộ theo lịch | Đơn giản | Chỉ mục cũ tới một chu kỳ, xóa chậm, không đạt 60 giây |
| B. Truy vấn thẳng API nguồn mỗi lượt, không có chỉ mục | Luôn mới, không lưu bản sao | Chậm, không truy hồi ngữ nghĩa được, tải lớn lên phân hệ nguồn |
| C. **Lập chỉ mục theo sự kiện thay đổi của nguồn (Kafka, idempotent theo `content_hash`), cộng lập lại theo lịch làm lưới an toàn; mỗi tài liệu qua cổng phân loại PH-09 đóng an toàn trước khi nhúng; xóa lan truyền hai pha (ẩn ngay trong giao dịch đầu, xóa vật lý theo lô sau); xác minh quyền bằng token người dùng ở mỗi lượt như lớp chốt cuối** | Độ tươi p95 ≤ 120 giây, xóa đạt chỉ tiêu, không bao giờ nhúng dữ liệu chưa biết mức | Phụ thuộc sự kiện nguồn đầy đủ; cần đối soát khi mất sự kiện hoặc khôi phục sao lưu |

## Quyết định

Chọn **phương án C**. Chỉ lập chỉ mục siêu dữ liệu và tài liệu (mô tả API, danh mục dùng chung, luồng, topic, danh mục mã lỗi, hướng dẫn vận hành, tài liệu tải lên đã duyệt), không lập chỉ mục bản ghi nghiệp vụ. Dùng tài khoản máy `svc-assist-index` scope `*.read-meta`. Cổng phân loại tra bản chụp `classification-index` của PH-09 (ETag, làm mới theo EVT-09-01, 03), thiếu thì gọi `classification:check`; chỉ `PUBLIC` và `INTERNAL` qua, còn lại (kể cả nhãn `STATE_SECRET` và mức không xác định) bị bỏ qua và ghi danh sách. Khi mức đổi, nguồn bị xóa hoặc thu hồi: pha 1 đặt tài liệu `DELETED` làm truy hồi không còn thấy đoạn ngay sau commit; pha 2 xóa vật lý theo lô 1.000 hàng, ghi nhật ký xóa không nội dung, phát EVT-17-16. Tắt trợ lý không xóa chỉ mục nhưng không truy hồi; xóa vẫn chạy khi tắt. Khôi phục sao lưu phải đối soát lại mức và nhật ký xóa trước khi bật trợ lý. Đổi mô hình nhúng dựng chỉ mục song song rồi chuyển con trỏ phiên bản.

## Hệ quả

Tích cực: chỉ mục tươi và có thể chứng minh không giữ dữ liệu ngoài phạm vi; lập lại toàn bộ rẻ nhờ so `content_hash`. Tiêu cực: PH-09 không khả dụng thì tài liệu mới chưa vào chỉ mục; loại nguồn thiếu sự kiện (mã lỗi, hướng dẫn của PH-18) phải lập theo lịch (Q17-63); HNSW sau nhiều lần xóa cần dựng lại định kỳ; quy trình DR có thêm bước đối soát (Q17-70).

## Truy vết

FR-17-015…019, 021; BR-17-025…029, 031, 079; NFR-17-010, 011; SEC-49, THR-56; EVT-09-01, EVT-09-03; D03-02-PH17 §4.4, §4.5, §4.6.
