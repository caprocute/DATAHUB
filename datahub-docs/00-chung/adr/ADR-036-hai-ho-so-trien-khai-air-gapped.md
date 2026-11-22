---
ma_tai_lieu: ADR-036
ten: Hai hồ sơ triển khai (tỉnh độc lập on-prem và nền tảng dùng chung cloud Chính phủ) và gói phân phối air-gapped
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Chủ đầu tư, Đội vận hành, Nhà cung cấp cloud, Hội đồng thẩm định
---

# ADR-036 · Hai hồ sơ triển khai và gói phân phối air-gapped

## Bối cảnh

Datahub là sản phẩm cho nhiều tỉnh (Q2), phải chạy cả on-prem tại TTDL tỉnh lẫn cloud Chính phủ với cùng một bộ mã (RB-07). Các tỉnh khác nhau về quy mô, năng lực vận hành và chính sách; nhiều TTDL không cho cụm truy cập Internet. NFR-00-056 đòi dựng một tỉnh mới trong ≤ 3 ngày làm việc từ khi có cụm Kubernetes đạt yêu cầu; NFR-00-060 đòi ≥ 34 tenant trên một nền tảng dùng chung.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ nền tảng dùng chung | Rẻ nhất mỗi tỉnh; một đội vận hành | Tỉnh có yêu cầu tự chủ hạ tầng hoặc cách ly cấp độ 4 không dùng được |
| B. Chỉ mỗi tỉnh một cụm | Cách ly tối đa | Chi phí gấp khoảng 6 lần mỗi tỉnh; 34 đội vận hành |
| C. **Hai hồ sơ `HT-A` (tỉnh độc lập, `DEDICATED_CLUSTER`) và `HT-B` (nền tảng dùng chung, `SHARED`/`DEDICATED_DB`), cùng manifest, khác lớp phủ; phân phối bằng gói OCI air-gapped có chữ ký, SBOM, công cụ `dhctl`** | Phục vụ cả hai nhóm tỉnh; một bộ mã; cài được không cần Internet; chuỗi cung ứng kiểm chứng được | Phải kiểm thử hai hồ sơ và bốn hồ sơ quy mô; gói phân phối lớn (hàng chục GB) |
| D. Phân phối qua kho ảnh công cộng, cài trực tuyến | Đơn giản cho nhà cung cấp | Không dùng được ở TTDL đóng mạng; khó kiểm chứng nguồn gốc |

## Quyết định

Chọn **phương án C**. Bốn hồ sơ quy mô `QM-NHO`, `QM-VUA`, `QM-LON`, `QM-CHUNG` có lớp phủ mẫu trong gói. Gói phân phối gồm ảnh theo digest, chart Helm và bản gốc Kustomize, danh mục Kamelet, SBOM CycloneDX, chữ ký cosign và chứng thực nguồn gốc bản dựng, bản chụp Trivy DB, công cụ `dhctl` (kiểm tra tiền điều kiện, nạp Harbor, sinh kho cấu hình, lệnh DR), có tệp kê khai ký tổng. Kyverno xác minh chữ ký bằng khóa công khai, không dùng chế độ không khóa. Báo cáo `dhctl preflight` là biên bản bàn giao cụm, bắt đầu tính mốc 3 ngày; kế hoạch dựng ba ngày theo D03-09 §11.3.

## Hệ quả

Tích cực: đáp ứng RB-07, NFR-00-056, NFR-00-060; chi phí mỗi tỉnh trên nền tảng dùng chung khoảng 0,3 đơn vị so với 2,0 khi tự dựng hai site; chuỗi cung ứng đáp ứng nhóm SEC-50–59. Tiêu cực: ma trận kiểm thử lớn hơn (hai hồ sơ triển khai × bốn hồ sơ quy mô ở STAGING theo vòng); nhà cung cấp phải quản lý khóa ký trong HSM; gói vá phải tương thích hai phiên bản quý gần nhất.

## Truy vết

RB-07, NFR-00-056, NFR-00-057, NFR-00-060; SEC-50–59; D03-09 §3, §5, §11; D03-10 §2; ADR-003, ADR-009. Câu hỏi mở Q333, Q337, Q343.
