# Tiến độ F-07-010 · Quản lý nhóm danh mục

## Đã làm
- Backend `datahub/services/dh-data` (Spring Boot 4.0.2, Modulith 2.0.1, module `rdm` + `shared`): API-07-007..010,
  JWT RS256, tenant theo giao dịch (RLS), RFC 9457, ETag/If-Match, Idempotency-Key, outbox kiểm toán, cây, xóa cứng, quyền.
- Web `datahub/web` (npm workspaces): `@datahub/ui`, `@datahub/api-client`, `@datahub/i18n`, `apps/console` (trang `/du-lieu/danh-muc`).
- E2E Playwright tự dựng PG18 (docker, cổng 55432) + backend (profile e2e, khóa JWT sinh lúc chạy) + console (build `VITE_DH_E2E_AUTH=1`).

## Lệnh đã chạy và kết quả thật
- `mvn -B -f datahub/services/dh-data/pom.xml verify`: BUILD SUCCESS; 47 test đơn vị + 40 tích hợp (Cucumber 14 kịch bản, 162 bước, đều xanh); JaCoCo dòng rdm 97,6%, shared 92,5% (ngưỡng 80%).
- `npm --prefix datahub/web run check`: tsc strict + ESLint (0 cảnh báo) + Vitest 54 test; coverage dòng 91,25%, nhánh 89,14% (ngưỡng 70%).
- `npm --prefix datahub/web run e2e`: 8 test xanh (xem cây, thêm con, mã trùng, sửa, xóa rỗng, xóa có danh mục ERR-07-037, chỉ xem, PA/TA trên nhóm COMMON); axe A/AA 0 vi phạm trên từng màn hình kiểm.
- `g1_dac_ta.py datahub/spec/PH07/goi.yaml`: G1 XANH.

## Lệch so với yêu cầu / ghi chú
- Gherkin có 14 kịch bản (G1 đếm 15 khối gồm Bối cảnh); cả 14 xanh.
- Cây nhóm viết tay theo mẫu WAI-ARIA dạng phẳng (treeitem anh em, aria-level) thay vì antd Tree, để tên truy cập khớp chữ hiển thị (axe label-content-name-mismatch).
- `@PreAuthorize` chạy sau khi đọc thân yêu cầu; Idempotency-Key sai định dạng trả 422; luật ArchUnit viết tay; kiểm toán gắn cứng vào outbox ph07.
- Nhóm cha là COMMON khi tenant tỉnh ghi: chọn phương án an toàn (từ chối bằng quyền, 403 ERR-07-003).
- `overrides.playwright-core=1.63.0` ở `datahub/web/package.json` để trùng bản Playwright cài sẵn; không chạy `playwright install`.

## Còn thiếu
- Khung phải (bảng danh mục F-07-001) chỉ là chỗ giữ; đăng nhập OIDC thật chưa thử với IdP (chỉ có cấu hình và kiểm thử đơn vị).
- Chưa chạy trên CI GitHub (cấu hình dùng `PW_CHROMIUM_PATH` nếu có, không thì Chromium mặc định của Playwright).
