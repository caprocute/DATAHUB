---
ma_tai_lieu: ADR-067
ten: Luồng được đọc trực tiếp CSDL có kiểm soát bằng tài khoản chỉ đọc theo luồng, RLS theo tenant và kiểm toán (Q359)
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Chấp nhận (25/11/2026)
nguoi_doc: Kiến trúc sư, ATTT, đội dh-runtime, PH-05
---

# ADR-067 · Truy cập CSDL trực tiếp có kiểm soát

## Bối cảnh

Nhiều tích hợp của Bus cũ đọc thẳng CSDL nghiệp vụ của sở. `camel/dancu` hiện dùng `camel-quarkus-sql` với tài khoản dùng chung. Ngày 25/11/2026 chủ đầu tư chốt Q359: cho phép có kiểm soát.

## Quyết định

1. Kết nối CSDL cho luồng khai báo ở PH-05, tài khoản **chỉ đọc riêng cho từng luồng**, bí mật cấp phát động qua OpenBao database secrets engine khi CSDL hỗ trợ, TTL 1 giờ.
2. Chỉ câu lệnh đọc, tham số ràng buộc; kiểm tra tĩnh VR-13 là lớp phụ, quyền ở CSDL là chốt chặn thật.
3. CSDL có RLS theo tenant: Kamelet nền `dh-sql-ro-source` mở giao dịch chỉ đọc, `SET LOCAL app.tenant_id` từ tiêu đề `dh-tenant`, rồi chạy câu lệnh.
4. Không bao giờ truy cập CSDL control plane (`pg-core` schema `ph01…ph20`) hay `pg-payment`.
5. Kiểm toán hai phía: pgaudit lớp `READ` cho vai trò luồng; runtime ghi băm câu lệnh, số dòng, thời lượng, `traceId`.
6. Ghi vào CSDL của HTTT thành viên chỉ khi kết nối được duyệt riêng cho mục đích ghi và có SO đồng ý.

## Hệ quả

PH-05 phải có loại kết nối "CSDL cho luồng" và quy trình cấp tài khoản theo luồng. Luồng đọc định kỳ khối lượng lớn phải phân trang theo khóa.

## Truy vết

FR-04-072; BR-04-015; VR-13; GAP-04-10; D04-01 Q359.
