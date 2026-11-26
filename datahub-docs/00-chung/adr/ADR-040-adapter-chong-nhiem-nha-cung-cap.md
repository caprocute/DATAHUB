---
ma_tai_lieu: ADR-040
ten: Cổng nhà cung cấp và adapter chống nhiễm cho PayGov
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-040 · Cổng nhà cung cấp và adapter chống nhiễm cho PayGov

## Bối cảnh

PH-19 cần thu phí, lệ phí qua Nền tảng thanh toán của Cổng Dịch vụ công quốc gia (PayGov), nhưng đặc tả kỹ thuật của PayGov chưa có trong tay (OQ-19-01…07): tên trường, thuật toán chữ ký, mã kết quả, cách đối soát đều là giả định. Hệ cũ gắn chặt logic nghiệp vụ với định dạng của PayGov, nên mỗi lần PayGov đổi thì phải sửa nhiều chỗ. Tỉnh cũng có thể cần thêm kênh khác (ngân hàng thu hộ, ví) trong vòng đời hệ thống (OQ-19-13).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Gọi PayGov trực tiếp trong dịch vụ nghiệp vụ | Ít mã nhất lúc đầu | Mọi thay đổi của PayGov lan vào lõi; khó kiểm thử khi chưa có môi trường thật; không thêm được NCC khác |
| B. **Cổng Java `PaymentProviderPort` trong lõi, adapter chống nhiễm cho từng NCC, bảng ánh xạ mã kết quả có phiên bản** | Lõi chỉ thấy khái niệm nội bộ; đổi đặc tả PayGov chỉ sửa adapter và bảng ánh xạ; có adapter `MOCK` cho kiểm thử | Thêm một lớp trừu tượng; phải giữ giao diện cổng ổn định |
| C. Đưa adapter ra luồng Camel ở PH-04 | Dùng lại hạ tầng tích hợp | Đường thanh toán phụ thuộc thêm một hệ; khó giữ đúng một lần và độ trễ p95 ≤ 300 ms |

## Quyết định

Chọn **phương án B**. Lõi khai báo `PaymentProviderPort` (khởi tạo, truy vấn, hủy, hoàn, kiểm tra kết nối, phân tích IPN và lượt quay về, thu thập và phân tích dữ liệu đối soát) cùng `ProviderCapabilities`. Adapter chỉ trả mã kết quả thô và cờ `transportOk`; `ResultMapper` của lõi là nơi duy nhất đổi mã thô thành kết cục, theo bảng `provider_result_mapping` có phiên bản, đổi qua phê duyệt (ADR-046). Mã chưa ánh xạ không bao giờ thành `SUCCEEDED`. Adapter `MOCK` chỉ có trong hồ sơ `dev`, `test`, `staging`; ảnh PROD không chứa nó. ArchUnit chặn mọi phụ thuộc từ lõi vào package adapter.

## Hệ quả

Tích cực: kiểm thử được toàn bộ luồng trước khi có PayGov thật (NFR-19-032); thêm NCC mới chỉ là thêm một adapter (NFR-19-027). Tiêu cực: khi PayGov có năng lực đặc thù (ví dụ hoàn qua API), phải mở rộng `ProviderCapabilities` có kiểm soát phiên bản.

## Truy vết

FR-19-001…012, 024, 029, 069; NFR-19-012, 027, 032; BR-19-012, 013; D03-02-PH19 §4, §7; LGC-PAY-001…009.
