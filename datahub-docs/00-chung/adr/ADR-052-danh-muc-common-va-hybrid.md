---
ma_tai_lieu: ADR-052
ten: Danh mục toàn quốc lưu ở tenant COMMON, tenant tỉnh mở rộng bằng danh mục HYBRID dạng phủ lớp
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Trưởng nhóm PH-20, Hội đồng thẩm định
---

# ADR-052 · Danh mục toàn quốc lưu ở tenant COMMON, tenant tỉnh mở rộng bằng danh mục HYBRID dạng phủ lớp

## Bối cảnh

Datahub phục vụ 34 tỉnh, thành trên cùng một cụm (ADR-003, D03-10). Một nhóm danh mục là chung cho cả nước: đơn vị hành chính, dân tộc, quốc tịch, giới tính, tôn giáo và các danh mục đồng bộ từ Nền tảng trao đổi dữ liệu quốc gia (NDXP). Mỗi tỉnh lại có nhu cầu bổ sung mã đặc thù: ví dụ danh mục loại hình cơ sở du lịch toàn quốc nhưng tỉnh muốn thêm vài loại hình địa phương trong dải mã riêng (FR-07-008, FR-07-048, UC-07-17).

D03-10 §4 đã chốt rằng dữ liệu dùng chung lưu với `tenant_id = 'COMMON'`, chính sách RLS cho đọc `tenant_id IN (current, 'COMMON')` và chỉ tenant `PLATFORM` được ghi. ADR này quyết định cách tenant tỉnh mở rộng danh mục COMMON mà không phá vỡ nguyên tắc đó.

## Các phương án

Bảng dưới đây so sánh ba cách tổ chức danh mục dùng chung và phần mở rộng địa phương.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Sao chép danh mục toàn quốc vào từng tenant khi khởi tạo và khi có phiên bản mới | Mỗi tenant tự chủ hoàn toàn; tra cứu không cần hợp nhất | Dữ liệu ĐVHC nhân 34 lần; mỗi lần quốc gia cập nhật phải phân phối 34 bản; dễ lệch phiên bản giữa tỉnh; tỉnh có thể sửa nhầm dữ liệu quốc gia |
| B. Đọc chéo: tenant tỉnh tự thêm bản ghi trực tiếp vào danh mục COMMON với cột đánh dấu tenant | Một bảng duy nhất | Vi phạm nguyên tắc chỉ PLATFORM ghi COMMON; RLS phức tạp (một danh mục có dòng của nhiều tenant); phiên bản của danh mục COMMON bị tỉnh làm thay đổi; không cách ly được |
| C. **Phủ lớp (overlay): danh mục COMMON nguyên vẹn; tỉnh tạo danh mục `source_type = HYBRID` trong tenant mình, `extends_catalog_id` trỏ tới danh mục gốc, chỉ chứa bản ghi bổ sung trong dải mã địa phương; tra cứu trả hợp hai tập** | Không nhân bản dữ liệu quốc gia; tỉnh không thể sửa dữ liệu gốc; phiên bản của phần mở rộng độc lập với phiên bản gốc; RLS giữ nguyên mẫu chuẩn | Tra cứu phải hợp nhất hai nguồn; cần quy tắc xử lý khi danh mục gốc thêm mã trùng dải địa phương; lược đồ thuộc tính phần mở rộng phải tương thích với gốc |

## Quyết định

Chọn **phương án C**.

Danh mục toàn quốc có `tenant_id = 'COMMON'` và chỉ được ghi khi `TenantContext` là `PLATFORM`; kiểm tra hai lớp: tầng ứng dụng từ chối với ERR-07-003, và chính sách RLS `WITH CHECK` của các bảng `ph07_rdm` chỉ cho ghi dòng `tenant_id = 'COMMON'` khi biến phiên `app.tenant_id = 'PLATFORM'` và `app.write_common = 'on'` (biến chỉ đặt trong `CommonWriteScope` của module). Mọi tenant đọc được danh mục COMMON đang `ACTIVE`.

Tenant tỉnh mở rộng bằng danh mục HYBRID trong tenant mình với các quy tắc: mã danh mục HYBRID có thể trùng mã danh mục gốc (ví dụ cùng `DAN_TOC`) vì nằm ở tenant khác; khi tra cứu bằng mã đó trong tenant tỉnh, danh mục của tenant được ưu tiên và trả hợp với danh mục gốc. `local_code_pattern` là biểu thức chính quy bắt buộc với HYBRID; mọi bản ghi bổ sung có `is_local_extension = true`, phải khớp biểu thức và không trùng mã trong phiên bản gốc đang hiệu lực tại `effective_from` của phiên bản HYBRID (BR-07-010, ERR-07-012). Lược đồ thuộc tính của HYBRID được khởi tạo bằng bản sao lược đồ gốc và chỉ được thêm thuộc tính không bắt buộc; thuộc tính thêm có giá trị rỗng với bản ghi gốc.

Tra cứu HYBRID tại thời điểm `t` lấy phiên bản gốc hiệu lực tại `t` và phiên bản HYBRID hiệu lực tại `t`, hợp nhất theo `code`. Nếu danh mục gốc về sau phát hành mã trùng với một bản ghi địa phương, bản ghi gốc thắng, bản ghi địa phương bị đánh dấu xung đột trong báo cáo và tenant nhận thông báo (qua EVT-07-05 của COMMON, module tiêu thụ và kiểm tra). Bộ đệm lưu riêng hai phần theo `version_id` và hợp nhất lúc đọc nên mỗi phần vẫn bất biến.

Nếu tỉnh không có danh mục HYBRID, tra cứu bằng mã danh mục COMMON trả trực tiếp dữ liệu COMMON; không cần sao chép gì khi khởi tạo tenant (FR-07-049 chỉ nạp danh mục mẫu LOCAL và tạo sẵn bản HYBRID rỗng nếu gói nền yêu cầu).

## Hệ quả

Tích cực: một nguồn sự thật cho dữ liệu quốc gia; cập nhật ĐVHC hay danh mục NDXP chỉ diễn ra một lần ở COMMON và có hiệu lực ngay cho 34 tenant. Tỉnh không thể làm hỏng dữ liệu quốc gia. Cấu trúc chính sách RLS giữ đúng mẫu D03-10.

Tiêu cực: trình tra cứu và trình dịch DSL phải hiểu hợp nhất hai nguồn; truy vấn có cấu trúc trên HYBRID chạy `UNION ALL` hai tập có cùng điều kiện và gộp sắp xếp. Xung đột mã giữa gốc và địa phương cần quy trình xử lý vận hành. Ảnh chụp cho data plane (ADR-053) của danh mục HYBRID là ảnh chụp đã hợp nhất, sinh lại khi một trong hai phần phát hành phiên bản mới.

## Trạng thái

Đề xuất.

## Truy vết

FR-07-008, FR-07-048, FR-07-049; BR-07-001, BR-07-009, BR-07-010; ERR-07-003, ERR-07-012; REQ-20; UC-07-15, UC-07-17. Liên quan ADR-003, D03-10 §4, ADR-053. Thiết kế chi tiết: D03-02-PH07 §4.10, §6.
