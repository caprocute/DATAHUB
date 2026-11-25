---
ma_tai_lieu: ADR-033
ten: Lớp biên do APISIX đảm nhận, WAF Coraza với OWASP CRS chạy trong APISIX
phien_ban: 0.2
ngay: 2026-11-25
trang_thai: Chấp nhận
nguoi_doc: Kiến trúc sư, Đội vận hành, Hội đồng thẩm định
---

# ADR-033 · Lớp biên do APISIX đảm nhận, WAF Coraza với OWASP CRS chạy trong APISIX

> **Lịch sử.** Bản 0.1 (21/11/2026) chọn Envoy Gateway làm lớp biên đứng trước APISIX. Ngày 25/11/2026 chủ đầu tư quyết định không thêm Envoy Gateway và giữ APISIX ở biên (ADR-005). Bản 0.2 ghi lại quyết định đó. Phương án Envoy Gateway được giữ trong bảng dưới để tham khảo.

## Bối cảnh

Datahub cần một lớp biên để kết thúc TLS 1.3 (NFR-00-020), xác minh chứng thư khách cho HTTT dùng mTLS, chạy tường lửa ứng dụng web (WAF) với bộ luật OWASP CRS, giới hạn kết nối và tốc độ theo địa chỉ nguồn để chống tràn, và tách hai cửa vào (Internet và mạng TSLCD). SAD §6 để ngỏ "Ingress NGINX hoặc Envoy Gateway". Dự án Ingress NGINX của cộng đồng Kubernetes đã công bố ngừng phát triển năm 2025. Repo hiện đã đặt WAF Coraza dạng proxy-wasm bên trong APISIX (`deploy/apisix/config.yaml`) và chạy được ở DEV.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Ingress NGINX + ModSecurity | Quen thuộc, nhiều tài liệu | Dự án cộng đồng đã ngừng phát triển; ModSecurity v3 ở giai đoạn cuối vòng đời |
| B. **APISIX ở biên, WAF Coraza (proxy-wasm) chạy trong APISIX** | Ít chặng, ít thành phần phải vận hành; đội chỉ cần thạo một gateway; trùng với cấu hình đã chạy ở repo; APISIX hỗ trợ TLS 1.3, mTLS khách, `limit-req`, `limit-conn`, `ip-restriction`, wasm | WAF tốn CPU trên cùng tiến trình với chính sách nghiệp vụ; cần tách hai cửa vào bằng hai nhóm phiên bản APISIX |
| C. Envoy Gateway (Gateway API) + Coraza, APISIX phía sau | Chuẩn Gateway API; tách biên và chính sách nghiệp vụ | Thêm một chặng (2–5 ms p95) và một thành phần phải vận hành, vá, giám sát |
| D. Istio ingress gateway | Cùng hệ sinh thái mesh | Ít tính năng WAF và chống tràn chuyên biệt |

## Quyết định

Chọn **phương án B**.

- Mỗi site chạy hai nhóm phiên bản APISIX dùng chung một cấu hình do control plane đồng bộ xuống (ADR-005): `apisix-ext` trong namespace `dh-edge` (vùng Z1, DMZ, cửa Internet) và `apisix-int` trong namespace `dh-gateway` (vùng Z2, cửa mạng TSLCD và nội bộ tỉnh). Mỗi nhóm chỉ nạp những route được gắn nhãn cho cửa của mình.
- APISIX kết thúc TLS 1.3 (cho phép TLS 1.2 với bộ mã an toàn cho hệ cũ), xác minh chứng thư khách theo cấu hình `ssl` có `client.ca`, và đưa dấu vân tay chứng thư vào ngữ cảnh xác thực của consumer.
- WAF Coraza chạy dạng plugin proxy-wasm với OWASP CRS 4.x: mức paranoia 2 cho đường dẫn giao diện, mức 1 cho API máy–máy (đã có kiểm tra lược đồ). Chế độ chặn bật trên PROD sau 2 tuần chạy chế độ phát hiện.
- Chống tràn ở tầng 7 dùng `limit-conn` và `limit-req` theo địa chỉ nguồn, đặt trước các plugin xác thực, để yêu cầu xấu bị loại sớm. Tầng 3/4 do dịch vụ chống DDoS của TTDL hoặc cloud và bộ cân bằng tải đảm nhận.
- Vào cụm qua Service kiểu LoadBalancer trỏ thẳng tới APISIX. Không dùng Ingress NGINX. Không triển khai Envoy Gateway.

## Hệ quả

Tích cực: bớt một chặng mạng và một thành phần; giữ nguyên cách repo đang làm; độ trễ thêm vẫn đo tại một điểm là APISIX (NFR-00-001, đóng Q348).

Tiêu cực: chi phí CPU của WAF nằm trong APISIX, nên định cỡ APISIX phải tính thêm 30–50% cho WAF (D03-09 §5). Luật CRS phải được tinh chỉnh theo từng API để tránh chặn nhầm (quy trình ngoại lệ luật WAF ở D03-07). Canary APISIX dùng Argo Rollouts theo số bản sao, không có chia lưu lượng theo trọng số chính xác như Gateway API.

## Truy vết

NFR-00-001, NFR-00-020; SEC-10, SEC-11 (nhóm biên và mạng); D03-07 §3, §5; D03-09 §3.1, §4.4, §10.2; ADR-005, ADR-013. Đóng Q348.
