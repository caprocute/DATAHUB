---
ma_tai_lieu: ADR-180
ten: Kho tham số tập trung theo tenant trên PostgreSQL, lược đồ khóa do phân hệ đăng ký, làm mới bằng sự kiện
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-18, DBA, ATTT, Hội đồng thẩm định
---

# ADR-180 · Kho tham số tập trung theo tenant

## Bối cảnh

Khoảng 340 khóa tham số của mười phân hệ (`onboarding.*`, `02.*`, `04.*`, `05.*`, `07.rdm.*`, `10.*`, `12.*`, `14.*`, `15.*`, `17.*`, `20.*`) được các FRS giao cho PH-18 lưu theo tenant, có phiên bản, kiểm miền và trần nền tảng, hiệu lực không quá 60 giây không khởi động lại (NFR-00-052, CC-CFG-04). Hệ cũ chỉ có API lấy và cập nhật thông số không phiên bản (LGC-BUS-031). Bộ đệm các phân hệ đang lệch nhau (30 giây, 60 giây, 5 phút).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Spring Cloud Config trên Git | Phiên bản theo commit, quen thuộc | Không theo tenant ở mức dòng, không RLS, khó kiểm miền và trần, quyền sửa theo kho Git chứ không theo `PERM` |
| B. Consul hoặc etcd KV | Đẩy thay đổi gần thời gian thực | Thêm một hệ cần vận hành, sao lưu, DR; không có kiểm toán nghiệp vụ, không có bốn mắt |
| C. **Bảng trong `ph18_ops` trên `pg-core`, lược đồ khóa do phân hệ đăng ký khi khởi động, giá trị có phiên bản, phát `ops.param.changed` qua outbox** | Một hệ lưu trữ sẵn có, RLS và sao lưu theo `pg-core`, kiểm miền, trần, bốn mắt và kiểm toán trong cùng giao dịch | PH-18 thành phụ thuộc mềm của mọi phân hệ, phải có bộ đệm và mặc định đóng gói |

: Các phương án được cân nhắc cho ADR-180

## Quyết định

Chọn **phương án C**. Mỗi phân hệ đăng ký lược đồ khóa (kiểu, mặc định, miền, trần `PLATFORM`, cờ bảo mật, nhóm hiển thị) qua scope `ops:param-register`; giá trị theo tenant ghi với `If-Match` và lý do, mỗi lần ghi tạo một phiên bản. Bên đọc dùng thư viện khách có bộ đệm Caffeine tối đa 60 giây và làm mới ngay khi nhận sự kiện `{tenant}.ops.param.changed.v1`; PH-18 vắng thì dùng bản đệm rồi mặc định đóng gói.

## Hệ quả

Tích cực: một nơi tra cứu và kiểm toán mọi tham số; cùng màn tham số chung cho mọi phân hệ; đạt hiệu lực ≤ 60 giây. Tiêu cực: các phân hệ đặt bộ đệm 5 phút phải chuyển sang làm mới theo sự kiện (đề nghị đồng bộ); cấu hình hạ tầng không theo tenant vẫn ở Helm values.

## Truy vết

FR-18 nhóm A; LGC-BUS-031; NFR-00-052; D03-02-PH18; D03-03-PH18 khối A.
