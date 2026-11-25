---
ma_tai_lieu: ADR-030
ten: Thiết kế ATTT theo cấp độ 3, chừa điểm nâng cấp cấp độ 4
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Chấp nhận
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-030 · Thiết kế ATTT theo cấp độ 3, chừa điểm nâng cấp cấp độ 4

## Bối cảnh

Chủ đầu tư đã chốt Datahub đạt an toàn hệ thống thông tin cấp độ 3 và sẵn sàng nâng lên cấp độ 4 (RB-06). Datahub xử lý dữ liệu cá nhân của số lượng lớn công dân (dữ liệu chủ PH-06, khai thác CSDL quốc gia PH-14, giao dịch PH-19), nên theo tiêu chí của Nghị định 331/2026/NĐ-CP (từ 100.000 chủ thể dữ liệu cá nhân cơ bản hoặc 10.000 chủ thể dữ liệu nhạy cảm) hệ tối thiểu ở cấp độ 3; Điều 8 cấm chia nhỏ hệ để hạ cấp. Một số tỉnh, hoặc nền tảng dùng chung nhiều tỉnh, có thể được yêu cầu cấp độ 4 về sau. Khung pháp lý vừa thay đổi: Luật An ninh mạng 116/2025/QH15, NĐ 331/2026 kế nhiệm NĐ 85/2016, TCVN 14423:2026 thay TCVN 11930:2017; trong khi yêu cầu ban đầu viện dẫn Thông tư 12/2022 và TCVN 11930:2017.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Thiết kế đúng cấp độ 3, xử lý cấp độ 4 khi có yêu cầu | Chi phí thấp nhất ban đầu | Nguy cơ phải làm lại kiến trúc (khóa, cách ly CSDL, mạng quản trị) khi nâng cấp |
| B. Xây sẵn toàn bộ biện pháp cấp độ 4 | Không phải nâng cấp | Chi phí HSM, site active thứ hai, SOC 24/7 không tương xứng cho đa số tỉnh; vận hành vượt năng lực TTDL tỉnh |
| C. **Đạt cấp độ 3 đầy đủ; kiến trúc chừa sẵn điểm cắm cho các biện pháp cấp độ 4 (SEC-90…99), không có quyết định nào phải làm lại** | Chi phí theo nhu cầu; nâng cấp chủ yếu là hạ tầng và tổ chức | Phải giữ kỷ luật thiết kế (giao diện PKCS#11, chế độ tenant, vùng Z7) và kiểm tra định kỳ |

## Quyết định

Chọn **phương án C**. Căn cứ chính là Luật 116/2025, NĐ 331/2026 và TCVN 14423:2026 (chương 5 cho cấp độ 3); Thông tư 12/2022 và TCVN 11930:2017 chỉ dùng để đối chiếu kế thừa (ma trận D03-07 §11b). Ngưỡng tham số phải bằng hoặc chặt hơn TCVN 14423:2026. Điểm chừa cho cấp độ 4 gồm: OpenBao có thể chuyển seal và transit sang HSM qua PKCS#11 (ADR-032); chế độ tenant `DEDICATED_DB`/`DEDICATED_CLUSTER` (ADR-003); data plane không trạng thái và DR có cấu trúc chuyển được sang active–active (ADR-034); vùng quản trị Z7 tách logic, tách vật lý được; điểm xuất giám sát chuẩn hóa cho SOC. Danh sách và điều kiện kích hoạt ở D03-07 §10.

## Hệ quả

Tích cực: hồ sơ cấp độ 3 (D03-08) có phương án bảo vệ đầy đủ; khi nâng cấp chỉ cần dự toán hạ tầng và tổ chức theo bảng D03-07 §10.2, không sửa mã ứng dụng. Tiêu cực: một số thành phần chạy ở chế độ "có thể mở rộng" phức tạp hơn mức cấp độ 3 cần (ví dụ chế độ tenant kép); tên và số mục chính xác của TCVN 14423:2026 chưa được đối chiếu đầy đủ (Q310, Q313), ma trận có thể phải chỉnh.

## Trạng thái

Đề xuất.

## Truy vết

RB-06; CMP-LAW-16, CMP-LAW-17, STD-06; D03-07 §2, §10, §11; D03-08; ADR-003, ADR-012, ADR-032, ADR-034.
