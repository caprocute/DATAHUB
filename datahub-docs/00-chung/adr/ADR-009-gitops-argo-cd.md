---
ma_tai_lieu: ADR-009
ten: GitOps với Argo CD cho triển khai ứng dụng và luồng tích hợp
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-009 · GitOps với Argo CD cho triển khai ứng dụng và luồng tích hợp

## Bối cảnh

Datahub phải chạy cả on-prem lẫn cloud chính phủ (Q6), nhiều tenant, nhiều môi trường. Hệ cũ triển khai agent bằng tay lên máy chủ. Cấp độ 3 yêu cầu kiểm soát thay đổi.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Triển khai bằng pipeline đẩy (push) | Quen thuộc | Khó phát hiện lệch cấu hình; pipeline cần quyền vào cụm |
| B. **GitOps kéo (pull) với Argo CD + Kustomize, Helm cho thành phần bên thứ ba** | Git là nguồn sự thật; tự phát hiện lệch; quay lui bằng revert | Cần quy trình Git chặt |

## Quyết định

Chọn **phương án B**. Bốn môi trường DEV, TEST, STAGING, PROD; STAGING và PROD cần duyệt. Cấm `kubectl apply` thủ công trên PROD. Luồng tích hợp do người dùng phát hành ở PH-04 cũng được ghi vào kho Git cấu hình và Argo CD đồng bộ, nhờ đó mọi thay đổi luồng có lịch sử và quay lui được.

## Hệ quả

Tích cực: kiểm soát thay đổi đáp ứng cấp độ 3; triển khai lặp lại được ở mọi tỉnh. Tiêu cực: kho Git cấu hình trở thành thành phần quan trọng, phải sao lưu và phân quyền chặt.

## Truy vết

REQ-04, REQ-18; BP-02. Tương ứng ADR-010 của repo.
