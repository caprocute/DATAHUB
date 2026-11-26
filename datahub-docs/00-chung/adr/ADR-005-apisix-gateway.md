---
ma_tai_lieu: ADR-005
ten: Apache APISIX làm cổng API
phien_ban: 0.2
ngay: 2026-11-25
trang_thai: Chấp nhận
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-005 · Apache APISIX làm cổng API

## Bối cảnh

Mọi lượt gọi API giữa HTTT phải qua một điểm kiểm soát (REQ-03): xác thực OAuth 2.1, mTLS, rate limit, quota, chặn đường dẫn, ghi nhật ký có che dữ liệu. Hệ cũ dùng gateway kiểu Gravitee chạy JVM.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Gravitee | Gần hệ cũ | JVM tốn tài nguyên; bản mở thiếu một số tính năng |
| B. Kong OSS | Phổ biến | Nhiều tính năng quan trọng ở bản thương mại |
| C. **Apache APISIX** | Hiệu năng cao (NGINX + LuaJIT), cấu hình động qua etcd/Admin API, plugin phong phú, Apache 2.0 | Viết plugin riêng bằng Lua hoặc dùng runner ngoài |

## Quyết định

Chọn **phương án C**. Control plane (PH-02, PH-03) là nguồn sự thật về API, gói sử dụng và đăng ký; cấu hình được đồng bộ xuống APISIX ở **chế độ standalone khai báo, không dùng etcd**: control plane sinh ảnh chụp cấu hình có số phiên bản và chữ ký, phát qua ConfigMap (Git, Argo CD) và bucket Garage; mỗi pod APISIX tự nạp lại tệp khi thay đổi (chi tiết D03-09 §6.1). Cách này khớp với `deploy/apisix/config.yaml` của repo và giữ data plane chạy khi control plane ngừng (NFR-00-012). APISIX cũng đảm nhận lớp biên, gồm TLS, mTLS khách và WAF Coraza (ADR-033). Các plugin dùng: `openid-connect`/`jwt-auth`, `limit-count`, `limit-req`, `consumer-restriction`, `ip-restriction`, `opa`, `opentelemetry`, `http-logger` (qua bộ che dữ liệu).

## Hệ quả

Tích cực: độ trễ thêm thấp, đạt KPI-04. Tiêu cực: màn giám sát gateway của hệ cũ (CPU, Java heap) được thay bằng chỉ số của APISIX (LGC-APIM-025).

## Truy vết

REQ-03; LGC-APIM-011…015, 022…025. Tương ứng ADR-003 của repo. Bản 0.2 (25/11/2026): chủ đầu tư chấp nhận; chuyển sang chế độ standalone (đóng Q338 phần quyết định) và nhận thêm vai trò lớp biên (ADR-033).
