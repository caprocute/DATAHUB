# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-12
Tính năng: TS-07-12 · Tra cứu khai thác qua API

  @TC-07-138 @P1 @Dương
  Kịch bản: TC-07-138 Tra một mã tại thời điểm hiện tại
    # Truy vết: FR-07-026 · API-07-042 · UC-07-09 · LGC-DMDC-015 · AT-07-001 (SRS cũ)
    Biết như chung.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/items/KH01.L01.P01`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/items/kh01.l01.p01`.
    Thì cả hai `200`, cùng dữ liệu: `code`, `name`, `parentCode`, `path`, `depth`, `levelName`, `status`, `attrs` (không có thuộc tính HIDDEN), `versionNo` = 1, `validFrom`, `validTo`. Có header `ETag` và `Cache-Control: max-age` ngắn. KT: không (thao tác đọc khai thác chỉ ghi chỉ số `rdm_lookup_total`).

  @TC-07-139 @P1 @Âm
  Kịch bản: TC-07-139 Tra mã không tồn tại
    # Truy vết: FR-07-026 · ERR-07-007
    Biết như chung.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/items/KHONG_CO`.
    Và gọi `GET /catalogs/KHONG_CO/items/A`.
    Thì bước 1 trả `404` `ERR-07-007`. Bước 2 trả `404` `ERR-07-001`. Chỉ số `rdm_lookup_total{result="not_found"}` tăng.

  @TC-07-140 @P1 @Dương
  Kịch bản: TC-07-140 Tra mã theo thời điểm quá khứ
    # Truy vết: FR-07-026 · BR-07-008 · AT-07-002 (SRS cũ)
    Biết `DVHC` giả lập.
    Khi gọi `GET /catalogs/DVHC/items/99001?at=2024-06-01`.
    Và gọi `GET /catalogs/DVHC/items/971?at=2024-06-01`.
    Và gọi `GET /catalogs/DVHC/items/971?at=2025-07-01`.
    Thì bước 1 trả bản ghi xã `99001` thuộc huyện `971`, `versionNo` = 1. Bước 2 trả huyện `971` cấp "Huyện". Bước 3 trả `200` với `status = DEPRECATED` và `replacedBy` theo sự kiện ABOLISH (hoặc `404` `ERR-07-007` nếu SDD quy ước đơn vị giải thể không còn trong phiên bản mới; ca kiểm thử bám quy ước của SDD, mặc định là trả DEPRECATED theo BR-07-004).

  @TC-07-141 @P1 @Dương
  Kịch bản: TC-07-141 Tra mã đã ngừng dùng trả trạng thái và mã thay thế
    # Truy vết: FR-07-026, 019 · BR-07-004 · AT-07-003 (SRS cũ)
    Biết `DVHC` v2 hiện hành với `99001` DEPRECATED `replacedBy = ["99101"]`; đồng hồ 2025-08-01.
    Khi gọi `GET /catalogs/DVHC/items/99001`.
    Thì `200`, `status = DEPRECATED`, `replacedBy = ["99101"]`, header cảnh báo `Deprecation` hoặc trường `warning` theo D03-04.

  @TC-07-142 @P2 @Âm @Biên
  Kịch bản: TC-07-142 Thời điểm tra không hợp lệ hoặc trước mọi phiên bản
    # Truy vết: FR-07-026 · BR-07-008 · ERR-07-007
    Biết CAT-LH v1 hiệu lực từ 2025-01-01.
    Khi gọi `?at=2026-13-01`.
    Và gọi `?at=21/11/2026`.
    Và gọi `?at=2024-12-31`.
    Và gọi `?at=2025-01-01` (biên dưới, khoảng đóng bên trái).
    Thì bước 1, 2 trả `400`. Bước 3 trả `404` `ERR-07-007`. Bước 4 trả `200`.

  @TC-07-143 @P1 @Dương @Biên
  Kịch bản: TC-07-143 Tra lô 500 mã
    # Truy vết: FR-07-027 · API-07-043 · AT-07-020 (SRS cũ)
    Biết 500 mã của `DVHC` chính thức, trong đó 3 mã không tồn tại, 2 mã lặp, 1 mã chữ thường.
    Khi gọi `POST /catalogs/DVHC/items:lookup` thân `{"codes":[...500 mã...],"at":"2026-11-21"}`.
    Thì `200`; kết quả giữ đúng thứ tự đầu vào; mã không tồn tại có `found = false` (không làm hỏng cả lô); mã lặp trả hai lần; mã chữ thường khớp.

  @TC-07-144 @P1 @Âm @Biên
  Kịch bản: TC-07-144 Tra lô vượt 500 mã
    # Truy vết: FR-07-027 · ERR-07-026
    Biết danh sách 501 mã; danh sách rỗng.
    Khi gửi 501 mã.
    Và gửi `codes` rỗng.
    Thì bước 1 trả `400` `ERR-07-026`. Bước 2 trả `400` lỗi kiểm tra hợp lệ.

  @TC-07-145 @P1 @Dương
  Kịch bản: TC-07-145 Lấy toàn bộ bản ghi theo con trỏ và chọn trường
    # Truy vết: FR-07-028 · API-07-041
    Biết CAT-BIG 100.000 bản ghi.
    Khi gọi `GET /catalogs/DM_LON_100K/items?limit=1000&fields=code,name,attrs.a1`.
    Và lặp theo `nextCursor` tới hết.
    Và giữa chừng (sau trang 50), phát hành phiên bản mới của CAT-BIG.
    Thì mỗi trang ≤ 1.000 bản ghi, chỉ gồm trường yêu cầu. Tổng 100.000 bản ghi, không trùng, không sót, thứ tự ổn định theo `sortOrder, code`. Con trỏ mã hóa `versionId`, nên sau bước 3 các trang còn lại vẫn thuộc phiên bản cũ (ảnh chụp nhất quán).

  @TC-07-146 @P1 @Dương
  Kịch bản: TC-07-146 ETag và If-None-Match
    # Truy vết: FR-07-028 · API-07-041, 042 · AT-07-022 (SRS cũ)
    Biết CAT-LH.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/items?limit=1000`, ghi `ETag`.
    Và gọi lại với `If-None-Match` = ETag.
    Và phát hành phiên bản mới có hiệu lực hôm nay rồi gọi lại bước 2.
    Thì bước 2 trả `304` không thân. Bước 3 trả `200` với ETag mới.

  @TC-07-147 @P2 @Âm @Biên
  Kịch bản: TC-07-147 Tham số khai thác không hợp lệ
    # Truy vết: FR-07-028 · API-07-041
    Biết CAT-LH.
    Khi gọi `?limit=1000` và `?limit=1001`.
    Và gọi `?cursor=` là chuỗi giả mạo, và con trỏ hợp lệ của danh mục khác.
    Và gọi `?fields=code,khong_co`.
    Thì `limit=1000` trả `200`; `limit=1001` trả `400`. Con trỏ giả mạo hoặc của danh mục khác trả `400` (con trỏ được ký, không giải mã được nội dung). `fields` có trường không tồn tại trả `400`.

  @TC-07-148 @P2 @Dương
  Kịch bản: TC-07-148 Bao gồm hoặc loại bản ghi ngừng dùng
    # Truy vết: FR-07-028 · BR-07-004
    Biết `DVHC` v2 có 3 xã DEPRECATED.
    Khi gọi `GET /catalogs/DVHC/items?at=2025-08-01`.
    Và gọi thêm `&includeDeprecated=true`.
    Thì bước 1 không có bản ghi DEPRECATED. Bước 2 có thêm 3 bản ghi, kèm `replacedBy`.

  @TC-07-149 @P1 @Dương
  Kịch bản: TC-07-149 Lấy cây và nhánh con
    # Truy vết: FR-07-029 · API-07-044 · LGC-DMDC-002
    Biết CAT-LH.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/tree`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/tree?root=KH01&depth=1`.
    Và gọi `GET /catalogs/DVHC/tree?root=97&at=2024-06-01`.
    Thì bước 1 trả cây đủ 3 khối, lồng `children`, sắp theo `sortOrder`. Bước 2 trả `KH01` và đúng các con trực tiếp, con có cờ `hasChildren`. Bước 3 trả cây 3 cấp lịch sử (tỉnh, huyện, xã).

  @TC-07-150 @P2 @Âm
  Kịch bản: TC-07-150 Cây trên danh mục không phân cấp hoặc gốc không tồn tại
    # Truy vết: FR-07-029, 018 · ERR-07-007
    Biết CAT-MUC phẳng.
    Khi gọi `GET /catalogs/MUC_DO_DVC/tree`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/tree?root=KHONG_CO`.
    Và gọi `?depth=11`.
    Thì bước 1 trả `200` với danh sách phẳng (mọi nút cấp 1) hoặc `400` theo D03-04; không lỗi `500`. Bước 2 trả `404` `ERR-07-007`. Bước 3 trả `400`.

  @TC-07-151 @P2 @Dương @Biên
  Kịch bản: TC-07-151 Tìm kiếm không dấu
    # Truy vết: FR-07-030 · API-07-045 · FR-00-020 · AT-07-019 (SRS cũ)
    Biết `DVHC` chính thức.
    Khi gọi `GET /catalogs/DVHC/items:search?q=ha noi`.
    Và gọi `?q=HÀ NỘI`, `?q=đa`, `?q=` rỗng.
    Và gọi `?q=a&limit=51`.
    Thì bước 1 trả "Thành phố Hà Nội" ở đầu (xếp hạng theo độ khớp). Bước 2: hai truy vấn đầu cho cùng kết quả; `q=đa` khớp cả "Đà" và "Đa"; `q` rỗng trả `400`. Bước 3 trả `400`.

  @TC-07-152 @P1 @Dương
  Kịch bản: TC-07-152 Lấy thay đổi kể từ một phiên bản
    # Truy vết: FR-07-031 · API-07-046
    Biết `DVHC` giả lập v1…v3.
    Khi gọi `GET /catalogs/DVHC/changes?sinceVersion=1`.
    Và gọi `?sinceVersion=3` (bằng phiên bản hiện hành).
    Thì bước 1 trả `toVersion` = 3 và danh sách thay đổi gộp (mỗi mã một mục trạng thái cuối) có `changeType`, kèm `successions` liên quan. Bước 2 trả danh sách rỗng, `toVersion` = 3.

  @TC-07-153 @P2 @Âm
  Kịch bản: TC-07-153 Delta với phiên bản không hợp lệ
    # Truy vết: FR-07-031 · ERR-07-006
    Biết `DVHC` có v1…v3.
    Khi gọi `?sinceVersion=9`.
    Và gọi không có `sinceVersion`.
    Thì bước 1 trả `404` `ERR-07-006`. Bước 2 trả `400`.

  @TC-07-154 @P1 @Dương
  Kịch bản: TC-07-154 Liệt kê danh mục và lấy lược đồ qua API
    # Truy vết: FR-07-033 · API-07-001, 048
    Biết APP-T68-READ.
    Khi gọi `GET /catalogs?status=ACTIVE`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/schema`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/schema?version=1`.
    Thì bước 1 trả danh mục ACTIVE mà HTTT được phép thấy (không có `TRAM_QUAN_TRAC` RESTRICTED vì `HT-HOTICH` chưa được cấp quyền, xem TS-07-23). Bước 2 trả metadata (mã, tên, phân cấp, tên cấp, thuộc tính, `queryable`) và JSON Schema của phiên bản hiệu lực. Bước 3 trả lược đồ v1.

  @TC-07-155 @P2 @Âm
  Kịch bản: TC-07-155 Lược đồ của phiên bản hoặc danh mục không tồn tại
    # Truy vết: FR-07-033 · ERR-07-006, ERR-07-001
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi gọi `GET /catalogs/LOAI_HINH_TC/schema?version=9`.
    Và gọi `GET /catalogs/KHONG_CO/schema`.
    Và APP-T68-READ gọi `GET /catalogs/LOAI_HINH_TC/schema?version=draft`.
    Thì bước 1 `404` `ERR-07-006`. Bước 2 `404` `ERR-07-001`. Bước 3 `404` `ERR-07-006` (bản nháp không lộ ra API khai thác).

  @TC-07-156 @P2 @Dương @Âm
  Kịch bản: TC-07-156 Tải ảnh chụp phiên bản
    # Truy vết: FR-07-028 · API-07-049 · ADR-053
    Biết CAT-LH v1 có ảnh chụp.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/snapshots/1?format=json`, không theo chuyển hướng.
    Và theo `Location`, tải và giải nén.
    Và gọi `GET /catalogs/LOAI_HINH_TC/snapshots/draft`.
    Thì bước 1 trả `302` tới URL ký sẵn hạn ngắn của bucket `dh-t68-rdm`. Bước 2 cho tệp có SHA-256 khớp metadata và nội dung khớp `GET .../items` của v1. Bước 3 trả `404` `ERR-07-006`.
