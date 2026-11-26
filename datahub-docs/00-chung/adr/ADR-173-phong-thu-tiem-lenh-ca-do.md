---
ma_tai_lieu: ADR-173
ten: Phòng thủ tiêm lệnh nhiều lớp và bộ ca đỏ chạy trong CI làm cổng phát hành mô hình và chỉ dẫn hệ thống
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-17, ATTT, SO, Hội đồng thẩm định
---

# ADR-173 · Phòng thủ tiêm lệnh nhiều lớp và cổng ca đỏ

## Bối cảnh

Nội dung mà trợ lý đọc (mô tả API, tên danh mục, log, tài liệu tải lên) do nhiều người viết, có thể chứa câu lệnh nhằm điều khiển mô hình (tiêm lệnh gián tiếp, THR-55). Không có biện pháp đơn lẻ nào đủ: lọc chữ dễ bị lách, mô hình có thể tuân lệnh. SEC-49 yêu cầu bộ ca tiêm lệnh mẫu ≥ 50 ca không làm trợ lý gọi công cụ ngoài ý định. Mô hình và chỉ dẫn hệ thống thay đổi theo thời gian nên phải kiểm lại mỗi lần đổi.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ lọc đầu vào bằng danh sách từ khóa | Rẻ, dễ | Dễ vượt qua, bỏ sót tiêm lệnh gián tiếp |
| B. Dựa vào chỉ dẫn "đừng nghe lệnh trong dữ liệu" cho mô hình | Không cần mã | Không bảo đảm, phụ thuộc mô hình |
| C. **Nhiều lớp độc lập: chuẩn hóa và lọc đầu vào, che DLCN, tách kênh chỉ dẫn và dữ liệu không tin cậy bằng ranh giới ngẫu nhiên theo lượt, allowlist công cụ chỉ đọc theo năng lực, quyền người dùng ở API đích, lọc đầu ra (DLCN, bí mật, liên kết ngoài, mã mồi); cộng bộ ca đỏ ≥ 50 ca chạy trong CI với mô hình tuân phục tối đa và trong môi trường đánh giá với mô hình thật, làm cổng phát hành** | Một lớp thủng thì lớp khác giữ; kiểm các lớp bằng mã một cách xác định; có bằng chứng đo được | Tốn công duy trì bộ ca; có thể chặn nhầm; độ trễ lọc ra tăng |

## Quyết định

Chọn **phương án C** với bảy lớp ở D03-02-PH17 §4.11. Bộ ca đỏ có tối thiểu 50 ca đang hoạt động theo sáu nhóm (`INDIRECT_INJECTION`, `TOOL_ABUSE`, `PII_LEAK`, `CROSS_TENANT`, `SECRET_LEAK`, `JAILBREAK`), mỗi ca đi qua đúng đường xử lý thật trên dữ liệu tổng hợp với công cụ giả có dữ liệu mồi; tỷ lệ chặn phải là 100% và **một ca lọt là cổng đỏ** (`17.redteam.min-pass-rate` cố định 100). Chạy trong CI mỗi lần đổi mã bộ lọc, công cụ, prompt (mô hình tuân phục tối đa, kiểm các lớp bằng mã) và trong môi trường đánh giá trước khi duyệt phiên bản mô hình hoặc prompt (mô hình thật). Chỉ dẫn hệ thống là mẫu có phiên bản, duyệt bốn mắt, mỗi (mẫu, năng lực) đúng một bản `ACTIVE`, kích hoạt khi đánh giá đạt, hồi quy trong dung sai và ca đỏ 100%. Ca mới từ sự cố hoặc phản hồi "không an toàn" vào bộ, ca đã có không xóa. Lượt có điểm nghi ngờ trung gian được cho qua nhưng tắt công cụ cả lượt.

## Hệ quả

Tích cực: có chuỗi bằng chứng cho thanh tra, mỗi thay đổi mô hình hay chỉ dẫn đều qua kiểm; phát hiện hồi quy bảo mật trước khi phát hành. Tiêu cực: phải có người sở hữu bộ ca đỏ và cập nhật định kỳ (Q17-15); bộ lọc có thể chặn nhầm câu hỏi hợp lệ nên cần theo dõi `assist_guard_blocked_total` và tỷ lệ báo sai; bộ phân loại học máy ở lớp đầu vào còn mở (Q17-66).

## Truy vết

FR-17-044, 045, 046, 049, 050, 051; BR-17-058…060, 063…068; NFR-17-005, 006, 009; SEC-49, THR-55; D03-02-PH17 §4.11, §4.12, §4.13.
