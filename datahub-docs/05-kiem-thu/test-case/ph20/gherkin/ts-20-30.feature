# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-30
Tính năng: TS-20-30 · Quản lý danh mục tổ chức, nhập, xuất và chủ quản dữ liệu

  @TC-20-136 @P1 @Dương
  Kịch bản: TC-20-136 Tạo, xem cây, xem bảng, sửa tổ chức
    # Truy vết: FR-20-053 · UC-20-30 · API-20-143, 144, 145, 146 · BR-20-027, 028 · EVT-20-13 · UI-20-14, 15 · `PERM-20-org`, `PERM-20-org-read`
    Biết `U-T90-TA`, `U-T90-VW`; F-ORG (`T90`); `kafka` thu EVT-20-13.
    Khi `POST T/organizations` với `orgCode = SO-KHCN2`, `name`, `orgType = DEPARTMENT`, `parentCode = UBND-TINH`, `adminUnitId`, `effectiveFrom`, kèm `Idempotency-Key`
    Và `GET T/organizations?view=TREE`; `GET T/organizations?view=TABLE&q=KHCN`
    Và `GET T/organizations/SO-KHCN2`
    Và `PATCH T/organizations/SO-KHCN2` đổi `name`, `shortName`, kèm `If-Match`
    Và `U-T90-VW` `GET T/organizations`
    Thì bước 1 `201`, `ACTIVE`, `ETag`, phát EVT-20-13 `CREATED`. Bước 2 cây hiện tổ chức mới dưới `UBND-TINH`; bảng có phân trang. Bước 4 `200`, EVT-20-13 `UPDATED`. Bước 5 `200` (mọi vai trò tỉnh xem được). Kiểm toán các thao tác ghi.

  @TC-20-137 @P1 @Âm
  Kịch bản: TC-20-137 Tạo, sửa tổ chức sai: mã, cha, chu trình, ĐVHC, hiệu lực, quyền
    # Truy vết: FR-20-053 · API-20-144, 146 · BR-20-027 · ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-012, ERR-20-047, ERR-20-052, ERR-20-002, ERR-00-428
    Biết `U-T90-TA`, `U-T90-VW`; F-ORG; tổ chức `SO-TEST` đã `DISSOLVED`.
    Khi tạo với `orgCode = so-khcn` (chữ thường) và một mã 51 ký tự
    Và tạo với `orgCode = SO-TEST` (đã giải thể)
    Và tạo với `parentCode` không tồn tại, và với cha `INACTIVE`
    Và `PATCH` đổi cha của `UBND-TINH` thành con của chính nó (chu trình)
    Và tạo với `adminUnitId` không thuộc tỉnh; với `effectiveTo` trước `effectiveFrom`
    Và `PATCH` thiếu `If-Match`; `If-Match` cũ; `GET T/organizations/KHONG-CO`
    Và `U-T90-VW` `POST T/organizations`
    Thì bước 1 `400` `ERR-20-004`. Bước 2 `409` `ERR-20-003`. Bước 3 `422` `ERR-20-047`. Bước 4 `422` `ERR-20-047` ("Tổ chức cấp trên UBND-TINH không hợp lệ: tạo chu trình."). Bước 5 `422` `ERR-20-012`, `422` `ERR-20-052`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`, `404` `ERR-20-002`. Bước 7 `403` `ERR-00-403`.

  @TC-20-138 @P2 @Dương
  Kịch bản: TC-20-138 Xem cây theo ngày hiệu lực và đổi cha giữ lịch sử
    # Truy vết: FR-20-053 · API-20-143, 146 · BR-20-028 · UC-20-30
    Biết `U-T90-TA`; tổ chức `PB-A` con của `SO-KHCN`; ngày 2026-11-27.
    Khi `PATCH T/organizations/PB-A` đổi `parentCode` sang `SO-TTTT`, hiệu lực 2026-12-01
    Và `GET T/organizations?view=TREE&asOf=2026-11-30`
    Và `GET T/organizations?view=TREE&asOf=2026-12-02`
    Thì `asOf` 2026-11-30 hiện `PB-A` dưới `SO-KHCN`; `asOf` 2026-12-02 hiện dưới `SO-TTTT`; lịch sử cha cũ còn lưu với hiệu lực.

  @TC-20-139 @P1 @Dương
  Kịch bản: TC-20-139 Nhập tổ chức: xem trước, xác nhận, ghi một giao dịch
    # Truy vết: FR-20-055 · UC-20-30 · API-20-153, 154, 155 · BR-20-027 · EVT-20-13 · UI-20-16 · `PERM-20-org`
    Biết `U-T90-TA` ở `T98`; F-ORG-IMP (tệp 5.000 dòng hợp lệ); `20.org.import-max-rows` mặc định.
    Khi `POST T/organization-imports` tải tệp 5.000 dòng, `mode = CREATE_ONLY`, kèm `Idempotency-Key`
    Và `GET T/organization-imports/{importId}` đến khi `PREVIEW_READY`
    Và `POST T/organization-imports/{importId}:confirm`
    Và `GET T/organizations?view=TABLE` đếm
    Thì bước 1 `202`, `importId`. Bước 2 `summary`: 5.000 `CREATE`, 0 `ERROR`. Bước 3 `202`, ghi trong một giao dịch theo thứ tự cha trước con, phát một EVT-20-13 `BULK_IMPORT` có danh sách mã. Bước 4 thêm 5.000 tổ chức.

  @TC-20-140 @P1 @Âm
  Kịch bản: TC-20-140 Nhập tổ chức lỗi: tệp sai, quá dòng, dòng lỗi, lô hết hạn
    # Truy vết: FR-20-055 · API-20-153, 154, 155 · ERR-20-050, ERR-20-051, ERR-20-006, ERR-20-009, ERR-20-004 · UI-20-16
    Biết `U-T90-TA`; F-ORG-IMP (tệp 40 dòng, 3 dòng lỗi); tệp `.pdf`; tệp `20.org.import-max-rows + 1` dòng; tệp > 10 MB.
    Khi tải tệp `.pdf`, tệp quá số dòng, tệp quá 10 MB
    Và tải tệp 40 dòng có 3 dòng lỗi (mã trùng, cấp trên không tồn tại, ngày hiệu lực ngược)
    Và `:confirm` lô còn dòng lỗi
    Và `:confirm` lô đã quá 24 giờ (đồng hồ giả lập)
    Và tải lại bằng `Idempotency-Key` đã dùng cho tệp khác
    Thì bước 1 `422` `ERR-20-050` ("Tệp nhập không hợp lệ: vượt quá số dòng cho phép."). Bước 2 `summary`: 3 `ERROR` kèm `rowNo`, `errors[]` từng dòng. Bước 3 `422` `ERR-20-051` ("Còn 3 dòng lỗi. Sửa tệp rồi tải lại."), không ghi gì. Bước 4 `409` `ERR-20-006`. Bước 5 `409` `ERR-20-009`.

  @TC-20-141 @P2 @Dương
  Kịch bản: TC-20-141 Nhập UPSERT: sinh CREATE, UPDATE, UNCHANGED
    # Truy vết: FR-20-055 · API-20-153, 154, 155 · UC-20-30
    Biết `U-T90-TA`; F-ORG; tệp 10 dòng: 4 mới, 3 sửa tên, 3 giống hệt.
    Khi tải với `mode = UPSERT`, xem trước, xác nhận
    Thì `summary`: 4 `CREATE`, 3 `UPDATE`, 3 `UNCHANGED`; sau xác nhận chỉ 7 dòng đổi, phát một EVT-20-13 gộp.

  @TC-20-142 @P2 @Dương
  Kịch bản: TC-20-142 Xuất tổ chức XLSX, CSV theo bộ lọc
    # Truy vết: FR-20-055 · API-20-156 · UI-20-14 · `PERM-20-org-read`
    Biết `U-T90-VW`; F-ORG; tổ chức đã `DISSOLVED` có kế thừa.
    Khi `GET T/organizations:export?format=xlsx&status=ACTIVE`
    Và `GET T/organizations:export?format=csv`
    Và `GET T/organizations:export?format=pdf`
    Thì bước 1, 2 tệp theo bộ lọc, có cột trạng thái, kế thừa, mã hóa UTF-8; chỉ tổ chức của `T90`. Bước 3 `400` `ERR-20-004`.

  @TC-20-143 @P1 @Dương @Âm
  Kịch bản: TC-20-143 Đánh dấu và bỏ đánh dấu chủ quản dữ liệu, tra cứu hàng loạt
    # Truy vết: FR-20-058 · UC-20-30 · API-20-152, 171 · ERR-20-049, ERR-20-006, ERR-20-062, ERR-20-005, ERR-00-428 · EVT-20-13 · `PERM-20-org`
    Biết `U-T90-TA`; `SO-KHCN` `ACTIVE`; `org-reader-sim` (`S-PH01`); `mod-sim` PH-06, PH-08 trả 3 đối tượng đang giao cho `SO-KHCN`; `SO-OLD` `INACTIVE`.
    Khi `PUT T/organizations/SO-KHCN/data-owner` với `isDataOwner = true`, `dataDomains`, `reason`, kèm `If-Match`
    Và `S-PH01` `POST I/organizations:lookup` với `isDataOwner = true`
    Và `PUT` bỏ đánh dấu `SO-KHCN` khi còn 3 đối tượng
    Và `PUT` đánh dấu `SO-OLD` (`INACTIVE`)
    Và `PUT` khi PH-06 trả `503`
    Và `PUT` thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `200`, EVT-20-13 `DATA_OWNER`. Bước 2 trả `SO-KHCN`. Bước 3 `409` `ERR-20-049` ("Tổ chức SO-KHCN còn 3 đối tượng tham chiếu. Chọn tổ chức kế thừa."). Bước 4 `409` `ERR-20-006`. Bước 5 `503` `ERR-20-062`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`.
