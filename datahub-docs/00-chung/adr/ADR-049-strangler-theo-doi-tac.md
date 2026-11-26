---
ma_tai_lieu: ADR-049
ten: Chuyển đổi strangler theo từng đối tác
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-049 · Chuyển đổi strangler theo từng đối tác

## Bối cảnh

Hệ cũ đang thu tiền thật cho các HTTT của tỉnh. Chuyển một lần cho mọi đối tác có rủi ro dừng thu lệ phí trên diện rộng. Quyết định Q12 chọn di trú và chạy song song theo kiểu strangler. Mỗi đối tác sẵn sàng ở thời điểm khác nhau.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chuyển một lần cho cả tỉnh | Không phải chạy song song | Rủi ro lớn; quay lui khó |
| B. **Chế độ định tuyến theo đối tác `LEGACY`, `SHADOW`, `DATAHUB` tại PH-03; chuyển qua phê duyệt; đối chiếu đạt mới được sang `DATAHUB`; quay lui trong 30 ngày** | Rủi ro theo từng đối tác; có số liệu so sánh trước khi chuyển; quay lui được | Hai hệ cùng chạy một thời gian; PH-03 phải nhân bản yêu cầu |
| C. Chuyển theo dịch vụ | Mịn hơn | Một đối tác dùng nhiều dịch vụ phải nói chuyện với hai hệ cùng lúc |

## Quyết định

Chọn **phương án B**. PH-03 giữ bảng tuyến theo đối tác; ở `SHADOW`, plugin `proxy-mirror` nhân bản yêu cầu tạo giao dịch sang `dh-payment` với `X-Datahub-Shadow: 1`, PH-19 ghi giao dịch `is_shadow = true`, không gọi NCC, không báo đối tác, loại khỏi hạn mức, báo cáo, đối soát. Chỉ được chuyển `DATAHUB` khi đối chiếu (FR-19-068) đạt 0 bản ghi lệch chưa giải thích trong số ngày `SHADOW` liên tiếp do tỉnh cấu hình (mặc định 7) và không còn phiên đối soát mở (BR-19-034). Callback của PayGov được PH-03 định tuyến theo tiền tố mã giao dịch. Dữ liệu lịch sử nhập trước bằng `ImportRunner` (khóa `legacy_mapping`, chạy lại không trùng). Lớp tương thích API hệ cũ (FR-19-067) chỉ làm khi OQ-19-17 xác nhận cần.

## Hệ quả

Tích cực: tỉnh chuyển dần, có bằng chứng số liệu cho từng bước; quay lui không bỏ dở giao dịch đang chạy (giao dịch tiếp tục ở hệ đã tạo ra nó). Tiêu cực: thời gian chạy song song kéo dài chi phí vận hành hệ cũ; cần người theo dõi báo cáo so sánh hằng ngày.

## Truy vết

FR-19-065…068; BR-19-034; ERR-19-006, 035; D03-02-PH19 §13; Q12; TS-19-29; D05-02-PH19 §6.2.
