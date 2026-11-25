---
ma_tai_lieu: ADR-038
ten: Chiến lược kiểm thử — kim tự tháp, Testcontainers, kiểm thử hợp đồng, kiểm thử rò rỉ chéo tenant
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Trưởng nhóm kiểm thử, Hội đồng thẩm định
---

# ADR-038 · Chiến lược kiểm thử — kim tự tháp, Testcontainers, kiểm thử hợp đồng, kiểm thử rò rỉ chéo tenant

## Bối cảnh

Datahub là hạ tầng dùng chung của nhiều tỉnh, gồm sáu DU Spring Boot Modulith, một DU Camel Quarkus native, hai ứng dụng React và nhiều thành phần hạ tầng (PostgreSQL có RLS, Kafka, Keycloak, OPA, OpenBao, APISIX). Các rủi ro sản phẩm nặng nhất — lộ dữ liệu chéo tenant (RSK-A03), lỗ hổng ủy quyền API, sai lệch thanh toán, vỡ hợp đồng giữa các DU và với HTTT — phần lớn nằm ở **cấu hình của thành phần hạ tầng và ranh giới giữa các thành phần**, không nằm trong logic thuần của một lớp. ADR-003 đã đặt điều kiện "mọi kiểm thử tích hợp phải có ca kiểm tra rò rỉ chéo tenant (bắt buộc trong D05-01)"; D03-10 §6 quy tắc 6 yêu cầu mỗi API có ca rò rỉ chéo tenant kỳ vọng `404`; FR-00-011 yêu cầu bộ kiểm thử này đạt 100% trên mọi API. Đội cần một chiến lược kiểm thử thống nhất trả lời: phân bổ kiểm thử theo mức thế nào, dùng hạ tầng thật hay giả lập, kiểm thử hợp đồng bằng công cụ gì, và bảo đảm "mọi API" có kiểm thử rò rỉ bằng cách nào.

## Các phương án

Bảng dưới đây so sánh các phương án cho bốn câu hỏi quyết định.

| Câu hỏi | Phương án | Ưu điểm | Nhược điểm |
|---|---|---|---|
| Phân bổ mức | A1. Kim tự tháp kinh điển (đơn vị dày, tích hợp mỏng, E2E rất mỏng) | Nhanh, rẻ | Bỏ sót lỗi cấu hình RLS, ACL, OPA |
| | A2. "Tổ ong"/tích hợp làm trọng tâm (tích hợp dày nhất) | Phát hiện lỗi ranh giới | Pipeline chậm, khó khoanh vùng lỗi logic |
| | **A3. Kim tự tháp có tầng tích hợp hệ thống dày hơn thường lệ** (≈ 60% đơn vị, 10% module, 15% tích hợp hệ thống, 10% hợp đồng, ≤ 10% E2E) | Giữ phản hồi nhanh, vẫn kiểm chứng hạ tầng thật ở chỗ rủi ro | Cần ngân sách thời gian pipeline và kỷ luật chọn ca |
| Hạ tầng trong kiểm thử | B1. CSDL nhúng (H2), Kafka nhúng, JWT giả | Nhanh, không cần Docker | Không có RLS thật, không có ACL thật; kết quả đánh lừa |
| | **B2. Testcontainers với thành phần thật cùng phiên bản sản xuất, token thật từ Keycloak container** | Kiểm chứng đúng cái chạy trên sản xuất | Runner CI phải chạy container; chậm hơn B1 |
| Kiểm thử hợp đồng | C1. Chỉ lint OpenAPI và kiểm tra thay đổi phá vỡ | Đơn giản | Không phát hiện bên dùng phụ thuộc hành vi ngoài đặc tả |
| | C2. Spring Cloud Contract | Tích hợp tốt khi cả hai phía là Spring | Phía dùng quan trọng nhất là giao diện TypeScript |
| | **C3. Contract-first: Spectral + oasdiff + xác thực phản hồi theo OpenAPI, cộng Pact cho cặp nội bộ rủi ro cao, Microcks cho hợp đồng ra ngoài** | Phủ cả Java và TypeScript; `can-i-deploy` trước triển khai | Thêm Pact Broker phải vận hành |
| Rò rỉ chéo tenant | D1. Viết tay mỗi API một ca | Rõ ràng | Dễ quên khi thêm API; không chứng minh được "mọi API" |
| | **D2. Bộ kiểm thử tự sinh theo mọi endpoint (đối chiếu ánh xạ lúc chạy với OpenAPI, gieo dữ liệu tenant A, tấn công bằng token tenant B, kỳ vọng `404`) cộng ca viết tay cho logic lồng** | Chứng minh được độ phủ 100%; endpoint mới tự được kiểm thử | Mỗi module phải cung cấp bộ gieo dữ liệu |

## Quyết định

Chọn **A3 + B2 + C3 + D2**:

1. Tháp kiểm thử bảy mức (đơn vị, tích hợp module Modulith, tích hợp hệ thống, hợp đồng, E2E Playwright, hệ thống, chấp nhận) với tỷ lệ mục tiêu ở A3; E2E vượt 10% số ca thì phải đẩy kiểm tra xuống mức thấp.
2. Kiểm thử tích hợp dùng Testcontainers với PostgreSQL, Kafka, Keycloak, Valkey, OpenBao, S3 thật, ảnh từ Harbor nội bộ, ghim cùng phiên bản sản xuất; vai trò CSDL kiểm thử không có `BYPASSRLS`; token lấy thật từ Keycloak. Không dùng H2 hay JWT giả cho kiểm thử liên quan tới bảo mật và cách ly.
3. Kiểm thử hợp đồng theo C3; Pact cho các cặp `dh-console`–DU và DU–DU rủi ro cao; dịch vụ ngoài (NDXP, PayGov) bằng Microcks/WireMock theo đặc tả và kiểm thử hợp đồng thật định kỳ với môi trường thử.
4. `CrossTenantLeakageSuite` trong thư viện kiểm thử dùng chung chạy ở mọi PR của mỗi DU, chặn merge, không được cách ly khi bất ổn; endpoint miễn trừ phải có chú thích lý do và được rà ở mỗi cổng phát hành. Saga khởi tạo tenant chạy bản rút gọn ở bước kiểm tra khói.

Chi tiết hiện thực ở D05-01 §4, §5.6, §6, §9.

## Hệ quả

**Tích cực.** Các lỗi cấu hình RLS, ACL, OPA, chữ ký bị phát hiện ở PR thay vì ở kiểm thử hệ thống; độ phủ rò rỉ chéo tenant đo được và báo cáo được cho hội đồng thẩm định; các DU, giao diện và HTTT tiến hóa độc lập mà không vỡ nhau (NFR-00-055); một cơ chế kiểm thử áp dụng thống nhất cho mọi phân hệ.

**Tiêu cực.** Runner CI phải có khả năng chạy container và đủ tài nguyên; pipeline PR chậm hơn phương án giả lập, phải quản lý bằng ngân sách thời gian (≤ 20 phút cho PR) và chọn ca theo module; phải vận hành thêm Pact Broker và Microcks; mỗi module phải viết và duy trì bộ gieo dữ liệu cho bộ rò rỉ chéo tenant.

## Trạng thái

Đề xuất.

## Truy vết

FR-00-010, FR-00-011, FR-00-012; NFR-00-053, NFR-00-054, NFR-00-055; REQ-20; RSK-A03, RSK-A04; ADR-001, ADR-003, ADR-006; D03-10 §6; D05-01 §3, §4, §5.6.
