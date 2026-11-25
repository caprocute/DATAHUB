# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-09
Tính năng: TS-07-09 · Nhập tệp: định dạng, mã hóa, khuôn Aita, tạo danh mục từ tệp và tệp bất thường

  @TC-07-111 @P1 @Dương
  Kịch bản: TC-07-111 Nhập CSV UTF-8 có BOM
    # Truy vết: FR-07-021 · LGC-DMDC-007
    Biết F-OK10-CSV; bản nháp CAT-LH.
    Khi tạo tác vụ UPSERT, chờ `VALIDATED`, commit.
    Thì `encoding` = `UTF-8`; kết quả giống TC-07-095 (cùng dữ liệu, khác định dạng); tên có dấu tiếng Việt đúng từng ký tự.

  @TC-07-112 @P1 @Dương @Biên
  Kịch bản: TC-07-112 Nhập CSV UTF-8 không BOM có ký tự tổ hợp
    # Truy vết: FR-07-021 · khung §3.13
    Biết F-NOBOM.
    Khi tạo tác vụ, chờ `VALIDATED`, commit.
    Và tìm `GET /catalogs/LOAI_HINH_TC/versions/draft/items?q=dong hoa`.
    Thì `encoding` = `UTF-8` (tự nhận dạng không cần BOM). Tên được chuẩn hóa về NFC khi lưu ("Phường Đông Hòa" dạng NFD lưu thành NFC); tìm không dấu ra kết quả.

  @TC-07-113 @P1 @Dương
  Kịch bản: TC-07-113 Tạo danh mục từ tệp xlsx khuôn Aita
    # Truy vết: FR-07-022 · UC-07-04 · API-07-033, 036 · UI-07-06 · LGC-DMDC-005
    Biết F-AITA-X (25 bản ghi; cột B là "Mã nghề").
    Khi gọi `POST /import-jobs` với `mode = CREATE_CATALOG`, `template = LEGACY_AITA`, `newCatalogCode` = `TC113_NGHE`, `codeColumn` = "Mã nghề", `nameColumn` = "Tên nghề".
    Và chờ `VALIDATED`; xem lược đồ đề xuất trong tóm tắt.
    Và commit.
    Và gọi `GET /catalogs/TC113_NGHE` và `.../versions/draft/attributes`, `.../items`.
    Thì tên danh mục đề xuất lấy từ ô A2 "Danh mục nghề nghiệp (giả lập)". Thuộc tính lấy từ dòng 4 bắt đầu ô B4; cột A (số thứ tự) bị bỏ qua. Thuộc tính không phải mã, tên ("Ghi chú") được tạo kiểu `STRING` với mã sinh tự động dạng không dấu `ghi_chu`, `legacyFieldId` rỗng. Có 25 bản ghi từ dòng 5. Danh mục ở `DRAFT`, v1 `DRAFT` `origin = IMPORT`. EVT-07-01 và EVT-07-07 phát. Giao diện chuyển tới UI-07-02 của danh mục mới (tương đương hành vi Aita chuyển sang màn chỉnh sửa).

  @TC-07-114 @P1 @Dương
  Kịch bản: TC-07-114 Khuôn Aita CSV mã hóa UTF-16 LE và BE
    # Truy vết: FR-07-022 · LGC-DMDC-005
    Biết F-AITA-U16, F-AITA-U16BE (phân cách tab).
    Khi tạo tác vụ CREATE_CATALOG LEGACY_AITA cho từng tệp (mã `TC114_LE`, `TC114_BE`).
    Và commit và so sánh nội dung hai danh mục với TC-07-113.
    Thì `encoding` lần lượt `UTF-16LE`, `UTF-16BE`; phân cách tab được tự nhận dạng; nội dung ba danh mục giống nhau từng ký tự.

  @TC-07-115 @P2 @Âm
  Kịch bản: TC-07-115 Tệp hỏng không phân tích được
    # Truy vết: FR-07-021 · ERR-07-019
    Biết `truncated.xlsx` (xlsx cắt mất 30% cuối).
    Khi tạo tác vụ, thăm dò trạng thái.
    Thì trạng thái đi `SCANNING` → `PARSING` → `FAILED`; `errorMessage` tiếng Việt "Tệp không đọc được…", mã `ERR-07-019`. EVT-07-07 `status = FAILED`. Không có dòng `import_row` nào còn lại.

  @TC-07-116 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-116 Tệp giả mạo đuôi
    # Truy vết: FR-07-021 · ERR-07-019 · DD-12 (`content_type` theo nội dung)
    Biết F-FAKE.
    Khi gửi `POST /import-jobs` với `file` = F-FAKE, khai báo `Content-Type` = xlsx.
    Thì bị từ chối ngay khi tải lên với `422` `ERR-07-019` (chi tiết "nội dung tệp không khớp định dạng") hoặc tác vụ `FAILED` trước bước phân tích; tệp không được chuyển cho bộ phân tích; `file_object.content_type` ghi kiểu thực tế phát hiện.

  @TC-07-117 @P1 @Âm @Biên
  Kịch bản: TC-07-117 Vượt giới hạn số dòng và kích thước
    # Truy vết: FR-07-021 · ERR-07-019 · khung §3.14
    Biết F-200K1, F-51MB, biến thể đúng 200.000 dòng `big_200000.csv`, đúng 50 MB `big_50mb.csv`.
    Khi gửi lần lượt bốn tệp.
    Thì tệp 51 MB bị APISIX hoặc ứng dụng từ chối với `413`/`422` `ERR-07-019` trước khi đọc hết thân yêu cầu. Tệp 200.001 dòng: tác vụ `FAILED` với `ERR-07-019` ngay khi bộ đọc luồng gặp dòng 200.001 (không đọc hết tệp mới báo). Hai tệp biên được chấp nhận và tới `VALIDATED`.

  @TC-07-118 @P2 @Âm
  Kịch bản: TC-07-118 Thiếu cột bắt buộc
    # Truy vết: FR-07-021 · ERR-07-019
    Biết F-MISSCOL.
    Khi tạo tác vụ UPSERT không gửi `columnMapping`.
    Thì tác vụ `FAILED` hoặc `422` `ERR-07-019` với chi tiết "thiếu cột TEN".

  @TC-07-119 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-119 Tệp nhiễm mã độc bị chặn ở bước quét
    # Truy vết: FR-07-021 · DD-12 (`scan_status`) · BR-07-041 · ERR-07-038
    Biết F-EICAR.
    Khi tạo tác vụ, thăm dò trạng thái.
    Thì trạng thái `SCANNING` → `FAILED` với `ERR-07-038`; `file_object.scan_status = INFECTED`; tệp bị cách ly hoặc xóa khỏi kho đối tượng; không có dòng `import_row`; có sự kiện an ninh gửi PH-13 kèm tên tệp và người tải.

  @TC-07-120 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-120 Bom nén xlsx
    # Truy vết: FR-07-021 · ERR-07-019 · NFR-07-012
    Biết F-ZIPBOMB.
    Khi tạo tác vụ; theo dõi bộ nhớ pod `dh-data`.
    Thì tác vụ `FAILED` với `ERR-07-019` (vượt tỉ lệ nén hoặc kích thước giải nén tối đa, ví dụ `ZipSecureFile.setMinInflateRatio` của POI); bộ nhớ heap không vượt 2 GB, pod không khởi động lại; các yêu cầu tra cứu song song không bị ảnh hưởng (p95 không vượt 2 lần nền).

  @TC-07-121 @P1 @Dương
  Kịch bản: TC-07-121 Tạo danh mục từ tệp khuôn chuẩn có sheet khai báo thuộc tính
    # Truy vết: FR-07-022 · khung §3.13
    Biết F-NEWCAT.
    Khi tạo tác vụ `mode = CREATE_CATALOG`, `template = STANDARD`, `newCatalogCode` = `TC121_DM`; commit.
    Thì danh mục mới có thuộc tính đúng kiểu và ràng buộc theo sheet `ThuocTinh`; bản ghi đúng; kiểm tra hợp lệ theo lược đồ mới được áp dụng ngay ở pha 1.

  @TC-07-122 @P2 @Âm
  Kịch bản: TC-07-122 Khuôn Aita có tên thuộc tính trống hoặc tên danh mục trùng
    # Truy vết: FR-07-022 · ERR-07-019, ERR-07-002
    Biết F-AITA-B4; F-AITA-X với `newCatalogCode` = `LOAI_HINH_TC` (đã tồn tại).
    Khi tạo tác vụ CREATE_CATALOG LEGACY_AITA với F-AITA-B4.
    Và tạo tác vụ với F-AITA-X và mã trùng.
    Thì bước 1: `FAILED` `ERR-07-019` "Ô C4 tên thuộc tính không được để trống" (giữ đúng ràng buộc của Aita). Bước 2: `409` `ERR-07-002` ngay khi tạo tác vụ hoặc khi commit.

  @TC-07-123 @P2 @Biên @Âm
  Kịch bản: TC-07-123 Giá trị quá dài
    # Truy vết: FR-07-013, 021 · ERR-07-009
    Biết F-LONG: `TEN` 255 ký tự (biên), `TEN` 256 ký tự, `TEN` 2.000 ký tự, `viet_tat` 21 ký tự.
    Khi tạo tác vụ, chờ `VALIDATED`.
    Thì dòng `TEN` 255 ký tự hợp lệ; các dòng còn lại lỗi `ERR-07-009` đúng cột. Giới hạn độ dài `name` theo kiểu T-NAME của D00-01 (giả định 255; đối chiếu D00-01 §5).

  @TC-07-124 @P1 @Bảo @mật
  Kịch bản: TC-07-124 Ô chứa công thức được lưu nguyên văn, không thực thi
    # Truy vết: FR-07-021, 024 · OWASP ASVS V5 (đầu ra)
    Biết F-FORMULA.
    Khi tạo tác vụ UPSERT, xem trước.
    Và commit, đọc bản ghi qua API.
    Thì xem trước gắn cảnh báo "giá trị bắt đầu bằng ký tự công thức" (không phải lỗi). Giá trị lưu đúng nguyên văn trong CSDL (không tính toán, không gọi mạng). Phần xuất ra tệp được kiểm thử ở TC-07-308.
