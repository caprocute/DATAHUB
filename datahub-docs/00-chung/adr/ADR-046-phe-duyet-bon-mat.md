---
ma_tai_lieu: ADR-046
ten: Đề nghị phê duyệt bốn mắt dùng chung cho mọi thao tác ảnh hưởng tới tiền
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-046 · Đề nghị phê duyệt bốn mắt dùng chung cho mọi thao tác ảnh hưởng tới tiền

## Bối cảnh

Bảy loại thao tác của PH-19 ảnh hưởng tới tiền hoặc tới đường đi của tiền: kích hoạt, ngừng hẳn NCC; duyệt, chấm dứt đối tác; hoàn tiền (một hoặc hai cấp); xử lý chênh lệch; mở lại phiên đối soát; đổi chế độ định tuyến; đổi bảng ánh xạ mã kết quả. Mỗi loại cần bốn mắt và tách nhiệm (khung §13.4). Làm riêng cho từng loại dễ sót quy tắc.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Mỗi đối tượng tự có trạng thái chờ duyệt | Đơn giản từng chỗ | Quy tắc tách nhiệm lặp lại, dễ sót; không có hộp phê duyệt chung |
| B. Flowable (ADR-007) | Quy trình linh hoạt | Nặng cho thao tác ngắn; khó kiểm tra lại điều kiện nghiệp vụ trong cùng giao dịch CSDL |
| C. **Bảng `approval_request` chung, `FourEyesGuard` ở ứng dụng và ràng buộc `CHECK` ở CSDL; module chủ đối tượng kiểm tra lại điều kiện và áp thay đổi trong cùng giao dịch CSDL** | Một chỗ cho mọi quy tắc; chặn cả ở CSDL; một hộp phê duyệt (UI-19-13) | Module chủ phải hiện thực hàm áp quyết định |

## Quyết định

Chọn **phương án C**. Đề nghị có `required_approvals` 1 hoặc 2, hết hạn sau 7 ngày, chỉ một đề nghị `PENDING` cùng loại cho mỗi đối tượng. Người quyết định khác người lập (BR-19-011); hai cấp là ba người khác nhau (BR-19-023); người ghi nhận đã hoàn khác người duyệt (BR-19-024); người chốt phiên không duyệt mở lại phiên đó. So sánh theo định danh người dùng, không theo vai trò. CSDL có `CHECK (first_approver_id IS DISTINCT FROM requested_by AND …)`. Vi phạm trả ERR-19-033 và ghi sự kiện an ninh. Khi duyệt, module chủ kiểm tra lại điều kiện (ví dụ checklist BR-19-010); không còn đúng thì toàn bộ quay lui.

## Hệ quả

Tích cực: TS-19-33 kiểm được mọi quy tắc bằng một bộ ca; hội đồng thấy một bảng quy tắc. Tiêu cực: tỉnh ít nhân sự phải bố trí đủ người; quy tắc tĩnh 8 cho phép kèm cảnh báo.

## Truy vết

FR-19-005, 006, 018, 019, 039, 046, 047, 066, 069; BR-19-010, 011, 023, 024, 028; ERR-19-033, 034; khung §13.4; D03-02-PH19 §12; TS-19-33.
