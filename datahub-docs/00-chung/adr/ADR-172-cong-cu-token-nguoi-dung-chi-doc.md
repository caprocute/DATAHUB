---
ma_tai_lieu: ADR-172
ten: Công cụ của trợ lý chạy bằng token người dùng qua token exchange, chỉ đọc, hành động ghi chỉ qua thẻ đề xuất người dùng xác nhận
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-17, nhóm PH-12, ATTT, Hội đồng thẩm định
---

# ADR-172 · Công cụ bằng token người dùng, chỉ đọc

## Bối cảnh

Trợ lý cần tra cứu API, danh mục, luồng, log, vết, bản tin DLQ để trả lời và giải thích sự cố. Nếu trợ lý có quyền riêng, một cuộc tiêm lệnh thành công (THR-55) sẽ chạy với quyền của trợ lý chứ không phải của người hỏi và có thể đọc vượt quyền (THR-56). SEC-49 yêu cầu công cụ chạy với token của người dùng hiện tại qua APISIX, chỉ đọc, ghi chỉ đề xuất.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Tài khoản máy của `dh-assist` có quyền đọc rộng | Đơn giản, nhanh | Mất nguyên tắc "trợ lý không biết gì người hỏi không biết"; tiêm lệnh thành leo thang quyền |
| B. Chuyển thẳng token truy cập của người dùng sang API đích | Không cần Keycloak thêm | Token dùng lại ở nhiều đích, audience sai, hạn dài, rủi ro lộ qua nhật ký |
| C. **Token exchange RFC 8693 qua Keycloak: mỗi công cụ nhận token ngắn hạn (≤ 60 giây) cho đúng `audience` và scope đọc, mang `act` = `dh-assist`; danh mục công cụ cố định trong mã, chỉ `GET`; ghi bản nháp chỉ bởi `SuggestionApplyService` sau khi người dùng bấm áp dụng, bằng token ghi bản nháp đổi cho đúng thao tác đó** | Quyền của trợ lý luôn bằng quyền người hỏi, kiểm toán thấy cả chủ thể lẫn tác nhân, không có quyền riêng để leo thang | Phụ thuộc PH-12 hỗ trợ `act` (Q17-07); thêm độ trễ đổi token mỗi lượt |

## Quyết định

Chọn **phương án C**. Danh mục chín công cụ chỉ đọc (`search_api`, `lookup_catalog`, `view_flow`, `view_mapping_schema`, `view_topic`, `lookup_field_class`, `search_logs`, `view_trace`, `view_dlq_message`), allowlist theo năng lực của hội thoại chứ không theo nội dung truy hồi, tenant chỉ bật hoặc tắt. Token đổi sống trong bộ nhớ của lượt, không vào Valkey, prompt hay log; Keycloak lỗi thì công cụ lỗi (ERR-17-064), không dự phòng bằng quyền máy. Truy hồi cũng xác minh đối tượng bằng token người dùng trước khi vào ngữ cảnh. Đường ghi duy nhất là `SuggestionApplyService` với `If-Match` và `Idempotency-Key`; phân hệ chủ tự kiểm quyền và ghi kiểm toán với người dùng là chủ thể. Tài khoản máy duy nhất của PH-17 là `svc-assist-index` với scope `*.read-meta` cho lập chỉ mục dữ liệu Công khai và Nội bộ, không dùng trong hội thoại. ArchUnit cấm phương thức HTTP ghi ngoài `SuggestionApplyService` và cấm đưa token vào chuỗi in được.

## Hệ quả

Tích cực: giảm hẳn tác hại của tiêm lệnh, không phải tạo vai trò hay quyền mới cho trợ lý, dễ chứng minh với thanh tra. Tiêu cực: mỗi lượt có thêm lời gọi Keycloak; nếu PH-12 chưa hỗ trợ `act` phải dùng token ủy quyền ngắn hạn (vẫn giữ bất biến); mọi API đọc cần cho công cụ phải do phân hệ chủ cung cấp (Q17-11) và nên có API kiểm quyền hàng loạt (Q17-69).

## Truy vết

FR-17-033, 042, 043, 047, 048; BR-17-035, 047, 056, 057, 061, 062; SEC-49, SEC-24, THR-55, THR-56; RFC 8693; ADR-006; D03-02-PH17 §4.10, §4.15.
