---
ma_tai_lieu: ADR-031
ten: Nhật ký kiểm toán chỉ-thêm, chuỗi băm, sao WORM và thời hạn lưu
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Vận hành, Hội đồng thẩm định
---

# ADR-031 · Nhật ký kiểm toán chỉ-thêm, chuỗi băm, sao WORM và thời hạn lưu

## Bối cảnh

FR-00-040…042 yêu cầu mọi thao tác quan trọng sinh bản ghi kiểm toán không sửa, không xóa được và có chuỗi băm phát hiện chỉnh sửa. Nhật ký phải đứng vững trước nội gián nền tảng có quyền quản trị CSDL (THR-34, THR-61), phải xuất được bằng chứng cho từng tỉnh mà không lộ dữ liệu tỉnh khác, và phải lưu đủ lâu cho thanh tra, điều tra. SRS để mở thời hạn lưu dài hạn (Q08, NFR-00-027). Garage, kho đối tượng chính của Datahub, chưa hỗ trợ đầy đủ S3 Object Lock.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Bảng PostgreSQL thường, chặn sửa ở tầng ứng dụng | Đơn giản | Quản trị CSDL sửa được không để lại dấu |
| B. Chỉ đẩy log sang Loki/SIEM | Có sẵn | Không bảo đảm đầy đủ (log có thể mất), không có chuỗi toàn vẹn, truy vấn theo đối tượng kém |
| C. Sổ cái chuyên dụng (immudb, blockchain) | Toàn vẹn mạnh | Thêm công nghệ lạ cho đội vận hành tỉnh; không cần đồng thuận phân tán |
| D. **Bảng chỉ-thêm trong PostgreSQL có chuỗi băm theo tenant, neo ký hằng giờ, sao lô sang kho WORM có Object Lock chế độ compliance và gửi neo tới SIEM** | Dùng công nghệ sẵn có; truy vấn tốt trong 12 tháng; toàn vẹn kiểm chứng được độc lập; WORM chống xóa kể cả bởi quản trị | Thêm một kho lưu trữ có Object Lock tách biệt; phải tuần tự hóa ghi theo tenant |

## Quyết định

Chọn **phương án D**. PH-13 ghi bảng `ph13_audit.audit_event` phân vùng theo tháng; vai trò ứng dụng chỉ `INSERT`/`SELECT`, trigger chặn sửa xóa. Mỗi tenant một chuỗi: `hash = SHA-256(prev_hash || canonical_json(bản ghi))`. Neo `{tenant, seq, hash, thời điểm}` ký bằng khóa transit `dh-audit-sign` mỗi giờ, lưu ở bảng neo, WORM và SIEM. Bản ghi sao sang WORM mỗi 5 phút. Kho WORM là hệ riêng (SeaweedFS, Ceph RGW hoặc dịch vụ cloud có Object Lock compliance, Q306), đặt ở site DR hoặc hạ tầng do bên khác quản trị. **Thời hạn lưu: trực tuyến 12 tháng; WORM 5 năm kể từ ngày ghi, tenant được cấu hình dài hơn, không ngắn hơn 3 năm**; log an ninh 12 tháng trực tuyến và 3 năm lưu trữ. Công cụ kiểm tra chuỗi chạy hằng ngày; kiểm toán viên xuất được gói bằng chứng theo tenant để tự xác minh. Chi tiết ở D03-07 §7.

## Hệ quả

Tích cực: đóng Q08; đáp ứng FR-00-042 trước cả nội gián; Object Lock chỉ cho kéo dài nên chọn 5 năm là an toàn nếu văn bản hướng dẫn (Q307) yêu cầu dài hơn thì chỉ cần nâng cấu hình. Tiêu cực: thêm thành phần lưu trữ WORM phải vận hành; dung lượng WORM tăng theo số tenant (ước lượng ở D03-09); không thể xóa bản ghi kiểm toán theo yêu cầu của chủ thể DLCN trước hạn, vì vậy bản ghi kiểm toán không chứa giá trị Nhạy cảm, chỉ chứa băm có khóa.

## Trạng thái

Đề xuất.

## Truy vết

FR-00-040…043; NFR-00-027, NFR-00-028; REQ-13; Q08 (D02-02); D03-07 §7, SEC-60…62; ADR-008, ADR-011, ADR-012.
