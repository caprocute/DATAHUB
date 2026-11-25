---
ma_tai_lieu: ADR-034
ten: DR hai site active–standby với CNPG replica cluster, Kafka MirrorMaker 2, sao chép Garage và Argo CD
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Đội vận hành, Hội đồng thẩm định
---

# ADR-034 · DR hai site active–standby với CNPG replica cluster, Kafka MirrorMaker 2, sao chép Garage và Argo CD

## Bối cảnh

NFR-00-014 đòi RPO ≤ 15 phút, RTO ≤ 1 giờ cho data plane và ≤ 4 giờ cho control plane, diễn tập hằng quý. HA trong một site (D03-09 §6) không bảo vệ trước mất cả site. Datahub có nhiều kho trạng thái với ngữ nghĩa khác nhau: PostgreSQL (thanh toán, kiểm toán), Kafka, Garage, OpenBao, kho Git cấu hình, Harbor. Đội vận hành TTDL tỉnh thường 3–5 người (RSK-A01).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ sao lưu, dựng lại khi thảm họa | Rẻ | RTO tính bằng ngày; không đạt NFR-00-014 |
| B. Sao chép khối đĩa hoặc máy ảo giữa hai site | Không phụ thuộc ứng dụng | Không nhất quán giữa các kho; RPO và khả năng kiểm chứng kém; phụ thuộc sản phẩm lưu trữ |
| C. **Active–standby, mỗi kho sao chép bằng cơ chế gốc: CNPG replica cluster, MirrorMaker 2, đồng bộ Garage định kỳ, gương Git và nhân bản Harbor, snapshot OpenBao; site DR ấm, Argo CD chuyển vai trò bằng commit** | RPO thực tế cỡ giây cho PostgreSQL và Kafka; mỗi kho kiểm chứng được độc lập; cùng công cụ với vận hành thường ngày | Nhiều kênh sao chép phải giám sát; OpenBao bản mở chỉ đạt RPO 15 phút; chuyển site thủ công có quyết định |
| D. Active–active | RTO gần 0 | PostgreSQL không ghi đa chủ an toàn cho thanh toán, kiểm toán; hạn mức, chống trùng phải đồng bộ chéo site; vượt năng lực vận hành; để dành cho cấp độ 4 |

## Quyết định

Chọn **phương án C**. Site DR chạy kho dữ liệu đủ và data plane một bản sao (ấm), DU control plane ở 0 bản sao. PostgreSQL dùng CNPG replica cluster theo cấu trúc phân tán, chuyển vai trò có kiểm soát bằng mã hạ cấp. Kafka dùng MirrorMaker 2 chạy ở site DR với `IdentityReplicationPolicy` và đồng bộ offset nhóm consumer. Garage dùng tác vụ đồng bộ mỗi 5 phút. Kho Git dùng gương đẩy, Harbor dùng nhân bản theo sự kiện. OpenBao dùng Raft snapshot mỗi 15 phút, khôi phục tự động mỗi giờ ở DR. Chuyển site do người có thẩm quyền quyết định theo tiêu chí D03-09 §7.5, thực hiện theo RBK-01 với ngân sách 60 phút; DNS/GSLB TTL 60 giây, không tự động chuyển. Diễn tập xoay vòng bốn kịch bản theo quý.

## Hệ quả

Tích cực: đạt NFR-00-014 với dư địa; site DR luôn được kiểm chứng sống bằng kiểm tra tổng hợp; cùng mô hình cho `HT-A` và `HT-B`. Tiêu cực: chi phí site DR gần bằng site chính (có thể giảm 30% với chế độ suy giảm); tỉnh chưa có site DR không đạt NFR-00-014 (RSK-H01); sao chép liên tục lan lỗi logic, nên phải có sao lưu bất biến (ADR-035).

## Truy vết

NFR-00-014, NFR-00-010; SEC-70–79; D03-09 §7; ADR-003, ADR-004, ADR-008, ADR-009, ADR-012, ADR-035. Câu hỏi mở Q339, Q346.
