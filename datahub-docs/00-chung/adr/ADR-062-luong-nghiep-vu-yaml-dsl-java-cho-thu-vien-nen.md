---
ma_tai_lieu: ADR-062
ten: Luồng nghiệp vụ viết bằng YAML DSL; Java chỉ dùng cho thư viện nền được duyệt
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-runtime
---

# ADR-062 · Luồng nghiệp vụ bằng YAML DSL, Java cho thư viện nền

## Bối cảnh

ADR-010 chọn YAML DSL, nhưng các luồng nghiệp vụ hiện có (`TraCuuRoute`, `StandardPipelineRoute`, `CdmMapRoute`) viết bằng Java DSL và biên dịch vào ảnh. Luồng Java không hiện được trên trình thiết kế, không phát hành qua GitOps được mà phải dựng lại ảnh, và không qua duyệt bốn mắt của PH-04.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Cho phép cả Java DSL và YAML | Linh hoạt cho luồng khó | Hai con đường phát hành; luồng Java né duyệt |
| B. **YAML cho mọi luồng; Java chỉ cho processor, bean, hàm JQ của thư viện nền `dh-runtime-core`** | Một đường phát hành; trình thiết kế thấy mọi luồng | Luồng phức tạp cần thư viện nền đủ mạnh |
| C. Cho phép kịch bản Groovy trong YAML | Linh hoạt | Nạp mã tùy ý, vi phạm kiểm soát phần mềm cấp độ 3 |

## Quyết định

Chọn **phương án B**. Thư viện nền (`TenantGuard`, `dh_map`, xử lý lỗi nền, ghi vết kết nối, đặt `app.tenant_id`) viết bằng Java, kiểm thử, phát hành theo vòng đời mã (D04-02), không theo vòng đời luồng. Ngôn ngữ kịch bản mặc định bị cấm trong chính sách thành phần. Ba luồng Java hiện có được viết lại bằng YAML.

## Hệ quả

Đội runtime phải duy trì thư viện nền có phiên bản; mỗi lần thêm processor nền là một thay đổi mã có duyệt.

## Truy vết

FR-04-060; GAP-04-02; ADR-010.
