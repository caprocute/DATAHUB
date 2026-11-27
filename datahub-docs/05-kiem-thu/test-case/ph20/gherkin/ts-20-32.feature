# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-32
Tính năng: TS-20-32 · Quản lý phiên bản sản phẩm và kênh phát hành

  @TC-20-152 @P1 @Dương
  Kịch bản: TC-20-152 Đăng ký phiên bản, sửa ghi chú, xem danh sách và chi tiết
    # Truy vết: FR-20-059 · UC-20-32 · API-20-109, 110, 111, 112 · BR-20-034 · UI-20-18 · `PERM-20-release` · BR-20-030
    Biết `U-PA1`; F-REL; ảnh có chữ ký và SBOM (bản giả hợp đồng CI).
    Khi `POST P/releases` với `releaseVersion = 2.4.1`, `components[]` (`du`, `image`, `digest`), `schemaChanges = [{module, kind = EXPAND}]`, `releaseNotes`, `minFromVersion = 2.3.0`, kèm `Idempotency-Key`
    Và `GET P/releases?status=DRAFT`
    Và `GET P/releases/2.4.1`
    Và `PATCH P/releases/2.4.1` đổi `releaseNotes`, kèm `If-Match`
    Thì bước 1 `201`, `DRAFT`. Bước 2 có `2.4.1` và `2.4.0-rc.1`. Bước 3 có cột số tenant đang chạy (0). Bước 4 `200`. Kiểm toán.

  @TC-20-153 @P1 @Âm
  Kịch bản: TC-20-153 Phiên bản không hợp lệ, trùng, chữ ký thiếu, sửa sau PREVIEW
    # Truy vết: FR-20-059 · API-20-110, 112 · ERR-20-053, ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-005, ERR-00-428 · BR-20-030
    Biết `U-PA1`, `U-PO`; F-REL (`2.4.0` `PREVIEW`, `2.3.1` `STABLE`); thành phần có digest không có chữ ký cosign.
    Khi `POST P/releases` với `releaseVersion = 2.4` (không đúng SemVer)
    Và `POST` với `2.3.0` nhỏ hơn bản cùng dòng đã có `2.3.1`
    Và `POST` với `2.3.1` (đã tồn tại)
    Và `POST` với thành phần thiếu chữ ký
    Và `PATCH 2.4.0` đổi thành phần sau `PREVIEW`
    Và `PATCH 2.4.1` thiếu `If-Match`; `If-Match` cũ
    Và `U-PO` `POST P/releases`
    Thì bước 1, 4 `422` `ERR-20-053` ("Phiên bản sản phẩm 2.4 không hợp lệ: không đúng SemVer."). Bước 2 `422` `ERR-20-053` (không lớn hơn bản cùng dòng). Bước 3 `409` `ERR-20-003`. Bước 5 `409` `ERR-20-006`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 7 `403` `ERR-00-403`. Bước 1 với `releaseVersion` thiếu trường: `400` `ERR-20-004`.

  @TC-20-154 @P1 @Dương
  Kịch bản: TC-20-154 Đưa lên PREVIEW rồi STABLE sau 14 ngày thí điểm
    # Truy vết: FR-20-060 · UC-20-32 · API-20-113, 114 · BR-20-031 · EVT-20-14 · UI-20-18 · `PERM-20-release`
    Biết `U-PA1`; `2.4.1` `DRAFT` đủ thành phần; đồng hồ giả lập; không sự cố mức 1.
    Khi `POST P/releases/2.4.1:preview` kèm `If-Match`
    Và tiến đồng hồ 14 ngày; `POST P/releases/2.4.1:promote` kèm `If-Match`
    Và `GET P/releases/2.4.1`
    Thì bước 1 `200`, `PREVIEW`, EVT-20-14. Bước 2 `200`, `STABLE`, EVT-20-14 thứ hai. Bước 3 trạng thái `STABLE`, mốc `stableAt`.

  @TC-20-155 @P1 @Âm
  Kịch bản: TC-20-155 Promote khi chưa đủ 14 ngày, có sự cố mức 1, sai trạng thái
    # Truy vết: FR-20-060 · API-20-113, 114 · BR-20-031 · ERR-20-054, ERR-20-006, ERR-20-005, ERR-00-428
    Biết `U-PA1`; `2.4.0` `PREVIEW` mới 9 ngày; `2.4.2` `PREVIEW` đủ 15 ngày nhưng có sự cố mức 1 gắn phiên bản; `2.4.1` `DRAFT`.
    Khi `:promote` `2.4.0` (mới 9 ngày)
    Và `:promote` `2.4.2` (sự cố mức 1)
    Và `:promote` `2.4.1` đang `DRAFT`
    Và `:preview` `2.4.0` đã `PREVIEW`
    Và `:promote` thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `422` `ERR-20-054` ("Phiên bản 2.4.0 mới thí điểm 9 ngày, cần tối thiểu 14 ngày và không có sự cố mức 1."). Bước 2 `422` `ERR-20-054`. Bước 3, 4 `409` `ERR-20-006`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-156 @P2 @Biên
  Kịch bản: TC-20-156 Bản vá khẩn lên STABLE sau 1 ngày khi PO duyệt
    # Truy vết: FR-20-060 · API-20-114 · BR-20-031 · ERR-20-054 · UC-20-32
    Biết `U-PA1`, `U-PO`; bản vá `2.3.2` `PREVIEW` mới 1 ngày, cờ `emergency = true`.
    Khi `U-PA1` `:promote` `2.3.2` không có duyệt của PO
    Và `U-PO` xác nhận khẩn, rồi `U-PA1` `:promote`
    Thì bước 1 `422` `ERR-20-054`. Bước 2 `200`, `STABLE` sau ≥ 1 ngày.

  @TC-20-157 @P1 @Dương @Âm
  Kịch bản: TC-20-157 Ngừng hỗ trợ và rút phiên bản lỗi
    # Truy vết: FR-20-059 · API-20-115, 116 · BR-20-034 · ERR-20-006, ERR-20-004, ERR-20-005, ERR-00-428 · EVT-20-14
    Biết `U-PA1`; F-REL (`2.1.0` `DEPRECATED`, `2.2.0` `STABLE`); `20.release.supported-minors = 2`.
    Khi `POST P/releases/2.2.0:deprecate` với `reason`, kèm `If-Match`
    Và `POST P/releases/2.4.0:withdraw` với `reason`
    Và lập kế hoạch nâng cấp lên bản `WITHDRAWN`
    Và `:deprecate` bản đã `DEPRECATED`; `:withdraw` thiếu `reason`
    Thì bước 1 `DEPRECATED` (ngoài 2 bản phụ hỗ trợ). Bước 2 `WITHDRAWN`, không tenant mới nâng lên. Bước 3 `422` `ERR-20-055`. Bước 4 `409` `ERR-20-006`, `400` `ERR-20-004`.

  @TC-20-158 @P1 @Dương @Âm
  Kịch bản: TC-20-158 Đổi kênh đăng ký của tenant, và khi đang có kế hoạch nâng cấp
    # Truy vết: FR-20-060 · API-20-117 · ERR-20-061, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-002, ERR-00-428 · UI-20-03 · `PERM-20-release`
    Biết `U-PA1`; `T93` kênh `STABLE`, không kế hoạch; `T92` có kế hoạch `RUNNING`; `T90` PROVINCE (cần lý do, phiếu).
    Khi `PUT P/tenants/T93/release-subscription` với `channel = PREVIEW`, `environment`, `reason`, kèm `If-Match`
    Và `PUT .../T92/release-subscription` đổi kênh
    Và `PUT` với `channel = KHAC`
    Và `PUT` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ; tenant `T00-KHONG-CO`
    Thì bước 1 `200`, `release.yaml` ghi kênh mới. Bước 2 `409` `ERR-20-061` ("Tenant T92 đang có kế hoạch nâng cấp PL-2026-001. Đổi kênh sau khi kế hoạch kết thúc."). Bước 3 `400` `ERR-20-004`. Bước 4 `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`, `404` `ERR-20-002`.
