# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-16
Tính năng: TS-09-16 · Kiểu che và chính sách che

  @TC-09-054 @P1 @Dương
  Kịch bản: TC-09-054 Mẫu che chuẩn cho số định danh, điện thoại, thư điện tử, ngày sinh, họ tên, địa chỉ
    # Truy vết: FR-09-023 · API-09-090, 091 · UI-09-10 · BR-09-021 · LGC-TOOL-012
    # Mục đích: Chứng minh bộ mẫu chuẩn thay bốn chế độ cũ `none`, `mask`, `pseudonymize`, `anonymize` bằng `MaskType`.
    Biết T90; U-T90-SO.
    Khi SO `GET /mask-types`.
    Và SO `PUT /mask-types/NATIONAL_ID/patterns` đổi `keep-last-3` thành `keep-last-4`.
    Thì bước 1 có bảy `MaskType` và mẫu `keep-last-3` (số định danh), `keep-first-3-last-2` (điện thoại), `keep-first-1-domain` (thư điện tử), `year-only` (ngày sinh), `keep-first-token` (họ tên), `admin-level` huyện (địa chỉ), kèm ví dụ trước và sau. Bước 2 `200`; chính sách `ACTIVE` không đổi, mẫu chỉ áp cho phiên bản kế tiếp.

  @TC-09-055 @P1 @Dương
  Kịch bản: TC-09-055 Soạn chính sách che có quy tắc cụ thể hơn thắng quy tắc chung
    # Truy vết: FR-09-024 · API-09-093, 094, 095 · BR-09-022, 024 · UI-09-10
    # Mục đích: Chứng minh thứ tự (loại DLCN, vai trò, mục đích, kênh, mức) và trùng ưu tiên thì kiểu che chặt hơn thắng.
    Biết T90; U-T90-DS1 (`PERM-09-policy` theo tổ chức).
    Khi DS1 `POST /mask-policies` bản nháp với quy tắc chung `SENSITIVE → REPLACE`, quy tắc riêng `NATIONAL_ID`, vai trò `ROLE-DATA_STEWARD`, kênh `UI` → `PARTIAL keep-last-3`.
    Và `PUT /mask-policies/{id}/versions/1` thêm hai quy tắc cùng độ ưu tiên `PARTIAL` và `DROP` cho điện thoại.
    Và mô phỏng ở TC-09-057.
    Thì bước 1 `201`, `DRAFT`. Bước 2 lưu được; khi áp, cùng ưu tiên chọn `DROP` (chặt hơn); `DROP` chỉ dùng khi chính sự tồn tại của trường là thông tin nhạy cảm (BR-09-024), còn bên nhận cần đối chiếu thì dùng `PARTIAL`. Mặc định theo BR-09-021: `SENSITIVE` che, `RESTRICTED` che một phần theo vai trò, `INTERNAL` và `PUBLIC` giữ nguyên.

  @TC-09-056 @P1 @Âm
  Kịch bản: TC-09-056 Kiểu che không hợp kiểu dữ liệu, trùng ưu tiên, thiếu quy tắc mặc định
    # Truy vết: FR-09-023, 024 · API-09-091, 095 · ERR-09-037, 038
    # Mục đích: Chứng minh kiểm hợp lệ kiểu che ở cả mẫu và chính sách.
    Biết T90; U-T90-SO.
    Khi SO đặt `YEAR_ONLY` cho trường `email`.
    Và SO lưu phiên bản có hai quy tắc cùng ưu tiên cùng kiểu che.
    Và SO lưu phiên bản không có quy tắc mặc định cho mức `SENSITIVE`.
    Thì bước 1 `422` ERR-09-037. Bước 2 và 3 `422` ERR-09-038.
