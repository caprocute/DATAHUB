---
ma_tai_lieu: ADR-023
ten: Apache ECharts làm thư viện biểu đồ
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Trưởng nhóm giao diện, Kỹ sư PH-13, PH-16, PH-19
nguoi_lap: Luồng giao diện
---

# ADR-023 · Apache ECharts làm thư viện biểu đồ

## Bối cảnh

Bảng điều khiển giám sát (PH-13), báo cáo chỉ tiêu (PH-16), thống kê giao dịch (PH-19) và tổng quan tenant cần biểu đồ đường, cột, tròn, vùng, bản đồ nhiệt và chuỗi thời gian dài với hàng chục nghìn điểm, cập nhật theo thời gian thực. Antd v6 không có thành phần biểu đồ. Biểu đồ phải nhận màu từ token (D03-05-02 §4.5), đổi theo chế độ sáng tối, có phương án thay thế cho trình đọc màn hình và chạy được khi không có Internet.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. `@ant-design/charts` (AntV G2) | Cùng hệ sinh thái antd | Gói lớn; hiệu năng chuỗi dài kém hơn; tài liệu chủ yếu tiếng Trung |
| B. **Apache ECharts** | Hiệu năng cao với dữ liệu lớn (canvas, lấy mẫu), đủ loại biểu đồ kể cả bản đồ, hệ theme đầy đủ, có mô-đun `aria` sinh mô tả, giấy phép Apache 2.0, nhập theo mô-đun | Không phải thành phần React gốc, cần lớp bọc |
| C. Recharts | API React tự nhiên | SVG chậm với chuỗi dài; ít loại biểu đồ |
| D. Grafana nhúng | Mạnh cho giám sát | Lệch design system; không phù hợp báo cáo nghiệp vụ trong ứng dụng |

## Quyết định

Chọn **Apache ECharts** (nhánh 5.x hoặc mới hơn, nhập theo mô-đun qua `echarts/core`), bọc trong `CMP-Chart` của `@datahub/ui`. Theme ECharts được sinh từ token (`tokens.light`, `tokens.dark`), đổi khi `useDhAppearance().mode` đổi. Mỗi biểu đồ bật mô-đun `aria`, có nhãn dữ liệu trực tiếp hoặc chú giải kèm ký hiệu hình dạng, và có nút "Xem dạng bảng" hiển thị cùng dữ liệu bằng `CMP-DataTable`. Bảng điều khiển hạ tầng chuyên sâu của đội vận hành vẫn có thể dùng Grafana của bộ LGTM (ADR-011), nhưng màn hình trong `dh-console` dùng `CMP-Chart`.

## Hệ quả

Tích cực: một thư viện cho mọi biểu đồ nghiệp vụ, hiệu năng tốt, màu đồng bộ token. Tiêu cực: phải duy trì lớp bọc và bộ chuyển theme; kích thước gói tăng, giảm thiểu bằng nhập theo mô-đun và tải lười trang có biểu đồ.

## Trạng thái

Đề xuất.

## Truy vết

ADR-020, ADR-011; NFR-00-040, NFR-00-045; D03-05-02 §4.5; D03-05-04 `CMP-Chart`.
