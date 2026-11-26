---
ma_tai_lieu: ADR-064
ten: Chạy thử luồng bằng Camel thật trong sandbox cô lập, đích mô phỏng
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-integration, ATTT
---

# ADR-064 · Sandbox chạy thử Camel thật

## Bối cảnh

`RoutesService.testRun` hiện dựng kết quả giả từ `stage.hashCode()` và luôn trả `PASSED` (GAP-04-04), nên điều kiện "đã chạy thử" khi gửi duyệt không có giá trị.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chạy trong `dh-integration` (control plane) | Đơn giản | Nạp YAML do người dùng soạn vào tiến trình control plane: rủi ro ATTT |
| B. **Dịch vụ `dh-runtime-sandbox` riêng, namespace riêng, mỗi lần chạy một `CamelContext`, mạng ra bị chặn trừ mô phỏng và môi trường TEST** | Đúng runtime thật; cô lập | Thêm một DU |
| C. Camel JBang trong pod tạm cho mỗi lần chạy | Cô lập theo lần chạy | Khởi động chậm (5–10 giây), tốn tài nguyên |

## Quyết định

Chọn **phương án B**, chế độ JVM cùng phiên bản Camel Quarkus với hồ sơ đích (mọi hồ sơ có bản JVM tương ứng). Chính sách mạng chỉ cho sandbox gọi WireMock nội bộ và, với chế độ `SANDBOX_LIVE`, các đích thuộc môi trường TEST. Thành phần đọc tệp, gọi lệnh bị vô hiệu bằng chính sách thành phần của sandbox. Mỗi lần chạy có hạn thời gian và hạn bộ nhớ. Khi sandbox không sẵn sàng, mô phỏng tĩnh chỉ được bật bằng tham số và luôn gắn nhãn `SIMULATED`.

## Hệ quả

Thêm DU `dh-runtime-sandbox` vào bản đồ DU của SAD (đề nghị sửa SAD §4). Lần chạy `SIMULATED` không bao giờ thỏa điều kiện gửi duyệt.

## Truy vết

FR-04-030, 015, 020; BR-04-004; GAP-04-04.
