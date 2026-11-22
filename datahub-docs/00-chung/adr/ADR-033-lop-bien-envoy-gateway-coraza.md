---
ma_tai_lieu: ADR-033
ten: Lớp biên Envoy Gateway (Kubernetes Gateway API) và WAF Coraza với OWASP CRS
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Đội vận hành, Hội đồng thẩm định
---

# ADR-033 · Lớp biên Envoy Gateway (Kubernetes Gateway API) và WAF Coraza với OWASP CRS

## Bối cảnh

Datahub cần một lớp biên trước APISIX để kết thúc TLS 1.3 (NFR-00-020), xác minh chứng thư khách cho HTTT dùng mTLS, chạy tường lửa ứng dụng web (WAF) với bộ luật OWASP CRS, giới hạn kết nối và tốc độ thô theo địa chỉ nguồn để chống tràn, và tách hai cửa vào (Internet và mạng TSLCD). SAD §6 để ngỏ "Ingress NGINX hoặc Envoy Gateway". Dự án Ingress NGINX của cộng đồng Kubernetes đã công bố ngừng phát triển năm 2025, sau thời hạn bảo trì không còn bản vá bảo mật. Repo hiện đặt WAF Coraza dạng proxy-wasm bên trong APISIX (`deploy/apisix/config.yaml`).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Ingress NGINX + ModSecurity | Quen thuộc, nhiều tài liệu | Dự án cộng đồng đã ngừng phát triển; ModSecurity v3 cũng ở giai đoạn cuối vòng đời; API Ingress không còn phát triển tính năng |
| B. Không có lớp biên riêng, WAF chạy trong APISIX | Ít chặng, ít thành phần | Trộn trách nhiệm biên (TLS, chống tràn, WAF) với chính sách nghiệp vụ; WAF tốn CPU trên cùng tiến trình đo NFR-00-001; khó áp chính sách khác nhau cho hai cửa vào; không theo chuẩn Gateway API |
| C. **Envoy Gateway hiện thực Gateway API, WAF Coraza (proxy-wasm) với OWASP CRS, APISIX phía sau** | Chuẩn Gateway API của Kubernetes; dự án CNCF đang phát triển; Envoy hỗ trợ mTLS khách, giới hạn tốc độ, Wasm; Coraza là WAF Go tương thích luật ModSecurity, giấy phép Apache 2.0; Argo Rollouts dùng Gateway API để canary APISIX | Thêm một chặng (ước tính 2–5 ms p95 kèm WAF); thêm một thành phần phải vận hành |
| D. Istio ingress gateway | Cùng hệ sinh thái mesh | Chế độ ambient đã dùng Gateway API; gateway Istio ít tính năng WAF và chống tràn chuyên biệt hơn Envoy Gateway |

## Quyết định

Chọn **phương án C**. Mỗi site có hai `Gateway`: `dh-external` (DMZ, Internet) và `dh-internal` (mạng TSLCD và nội bộ tỉnh), cùng do Envoy Gateway quản lý trong namespace `dh-edge`. Envoy Gateway kết thúc TLS, xác minh chứng thư khách theo `ClientTrafficPolicy` và chuyển dấu vân tay chứng thư cho APISIX qua header nội bộ (APISIX chỉ tin header này khi đến từ danh tính mesh của Envoy Gateway), chạy Coraza với OWASP CRS mức paranoia 1 (mức 2 cho cổng nhà phát triển) qua `EnvoyExtensionPolicy`, và giới hạn tốc độ thô theo địa chỉ nguồn. APISIX giữ vai trò cổng API nghiệp vụ (ADR-005) và tắt WAF nội bộ ở PROD để không kiểm tra hai lần. Không dùng Ingress API cho thành phần mới.

## Hệ quả

Tích cực: lớp biên theo chuẩn mở đang được phát triển, tránh rủi ro thành phần ngừng phát triển; tách rõ biên và chính sách nghiệp vụ; canary APISIX bằng Gateway API. Tiêu cực: thêm một chặng và một thành phần; luật CRS phải được tinh chỉnh theo từng API để tránh chặn nhầm (quy trình ngoại lệ luật WAF ở D03-07); cấu hình WAF trong repo phải chuyển từ APISIX sang Envoy Gateway.

## Truy vết

NFR-00-001, NFR-00-020; SEC-10–19 (nhóm biên và mạng); D03-09 §3.1, §4.4, §10.2; ADR-005, ADR-013. Câu hỏi mở Q348.
