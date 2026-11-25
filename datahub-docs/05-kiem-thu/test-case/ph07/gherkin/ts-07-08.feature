# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-08
Tính năng: TS-07-08 · Tệp mẫu và nhập tệp theo chế độ

  @TC-07-093 @P1 @Dương
  Kịch bản: TC-07-093 Tải tệp mẫu Excel sinh theo lược đồ
    # Truy vết: FR-07-020 · API-07-032 · UI-07-06 · FR-00-033 · khung §3.14
    Biết như chung.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=xlsx`.
    Và mở tệp: kiểm tra sheet, dòng 1, dòng 2, thứ tự cột, ràng buộc ô.
    Thì `200`, `Content-Type` xlsx, `Content-Disposition` có tên tệp `LOAI_HINH_TC_mau.xlsx`. Có đúng ba sheet `HuongDan`, `DuLieu`, `GiaTriHopLe`. Sheet `DuLieu` dòng 1 là nhãn tiếng Việt, dòng 2 là mã cột (ẩn, khóa), thứ tự `MA`, `TEN`, `MA_CHA`, `THU_TU`, `TRANG_THAI`, `MA_THAY_THE`, `HIEU_LUC_TU`, `HIEU_LUC_DEN`, rồi `viet_tat`, `cap_quan_ly`, `ngay_thanh_lap`, `so_bien_che`, `website` theo `sortOrder`. Cột `cap_quan_ly` có kiểm tra dữ liệu dạng danh sách lấy từ `GiaTriHopLe`. Thuộc tính HIDDEN không xuất hiện. Sheet `HuongDan` mô tả kiểu, bắt buộc, ràng buộc của từng cột.

  @TC-07-094 @P2 @Dương @Âm
  Kịch bản: TC-07-094 Tệp mẫu CSV và yêu cầu tệp mẫu không hợp lệ
    # Truy vết: FR-07-020 · API-07-032 · ERR-07-001
    Biết như chung.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=csv`.
    Và gọi `GET /catalogs/KHONG_CO/import-template?format=xlsx`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=pdf`.
    Thì bước 1 trả CSV bắt đầu bằng BOM `EF BB BF`, dòng tiêu đề là mã cột phân cách `,`, kết thúc dòng CRLF theo RFC 4180. Bước 2 trả `404` `ERR-07-001`. Bước 3 trả `400`.

  @TC-07-095 @P1 @Dương
  Kịch bản: TC-07-095 Nhập UPSERT tệp hợp lệ, đi qua đủ trạng thái tác vụ
    # Truy vết: FR-07-021 · UC-07-03 · API-07-033, 034, 036 · UI-07-06 · EVT-07-07 · LGC-DMDC-006
    Biết F-OK10.
    Khi gọi `POST /import-jobs` multipart: `file` = F-OK10, `catalogCode` = `LOAI_HINH_TC`, `version` = `draft`, `mode` = `UPSERT`, `Idempotency-Key: imp-095`.
    Và thăm dò `GET /import-jobs/{jobId}` mỗi giây, ghi lại chuỗi trạng thái.
    Và khi `VALIDATED`, gọi `GET /import-jobs/{jobId}/rows?page=0&size=50`.
    Và gọi `POST /import-jobs/{jobId}:commit` thân `{"skipInvalidRows":false}`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/versions/draft/items?size=100`.
    Thì bước 1 trả `202` kèm `Location`. Chuỗi trạng thái quan sát được là `UPLOADED` → `SCANNING` → `PARSING` → `VALIDATING` → `VALIDATED` (có thể bỏ lỡ trạng thái trung gian ngắn, nhưng không có trạng thái ngoài chuỗi). Tóm tắt: `totalRows` 10, `validRows` 10, `errorRows` 0, `encoding` = `UTF-8`, `template` = `STANDARD`. Bước 4 trả `202`/`200`, trạng thái đi qua `COMMITTING` tới `COMMITTED`. Bản nháp có 46 bản ghi (39 + 7 mới), 3 bản ghi đổi tên. `catalog_version.origin` giữ `MANUAL` hoặc ghi nhận nguồn `IMPORT` theo SDD. EVT-07-07 phát hai lần (một với `status = VALIDATED`, một với `COMMITTED`). KT: có (IMPORT_COMMIT, số dòng). Trên UI-07-06, bốn bước của trình hướng dẫn hoàn tất và có thông báo khi tác vụ nền xong (FR-00-054, 060).

  @TC-07-096 @P1 @Dương
  Kịch bản: TC-07-096 Bảng kết quả theo dòng của chế độ UPSERT
    # Truy vết: FR-07-021 · EN-07-09 · API-07-035
    Biết tệp `upsert_mix.xlsx` 6 dòng sinh có chủ đích như bảng dưới.
    Khi tạo tác vụ `UPSERT`, chờ `VALIDATED`, đọc `GET /import-jobs/{jobId}/rows`.
    Và commit, đọc bản nháp.
    Thì hành động xem trước và trạng thái sau commit khớp bảng sau.

  @TC-07-097 @P1 @Dương
  Kịch bản: TC-07-097 Chế độ REPLACE: bảng kết quả mong đợi
    # Truy vết: FR-07-021 · BR-07-003 · khung §3.13
    Biết bản nháp có 41 bản ghi (39 đã phát hành + 2 mới). F-REPL 30 bản ghi: thiếu 9 bản ghi đã phát hành và cả 2 bản ghi mới.
    Khi tạo tác vụ `mode = REPLACE`, chờ `VALIDATED`, đọc tóm tắt và các dòng.
    Và commit.
    Và đọc bản nháp và diff với v1.
    Thì tóm tắt xem trước có `toDeprecate` = 9, `toDelete` = 2 và cảnh báo "có thay đổi phá vỡ". Sau commit: bản nháp có 39 bản ghi từng phát hành (9 trong số đó DEPRECATED) + 0 bản ghi mới; 2 bản ghi mới bị xóa vật lý. Diff có 9 mục ngừng dùng, `breaking` > 0. Nếu một bản ghi thiếu trong tệp là cha của bản ghi có trong tệp và vẫn ACTIVE thì tác vụ có lỗi ở mức tệp (ERR-07-010) và không commit được (kiểm tra bằng biến thể tệp `lh_replace_parent.xlsx`).

  @TC-07-098 @P2 @Dương
  Kịch bản: TC-07-098 REPLACE gây thay đổi phá vỡ buộc phải duyệt
    # Truy vết: FR-07-021 · BR-07-012 · ERR-07-016
    Biết CAT-MUC (`require_approval = false`), nhập REPLACE thiếu 1 bản ghi đã phát hành.
    Khi commit tác vụ, sau đó U-T68-DA1 gọi `:publish` trên bản nháp.
    Thì `:publish` trả `409` `ERR-07-016`; phải qua trình duyệt.

  @TC-07-099 @P1 @Âm
  Kịch bản: TC-07-099 Chế độ APPEND: trùng mã là lỗi dòng
    # Truy vết: FR-07-021 · BR-07-002 · ERR-07-008
    Biết tệp `append.csv` 5 dòng: 3 mã mới, 1 mã đã có `KH01`, 1 mã `KH01.L01.P20` lặp hai lần trong tệp.
    Khi tạo tác vụ `mode = APPEND`, chờ `VALIDATED`.
    Thì `validRows` = 3 (chỉ 3 mã mới; mã lặp trong tệp bị đánh lỗi ở lần xuất hiện thứ hai), `errorRows` = 2; lỗi có `code` = `ERR-07-008`, `column` = `MA`.

  @TC-07-100 @P1 @Âm
  Kịch bản: TC-07-100 Xem trước báo lỗi theo dòng và cột
    # Truy vết: FR-07-013, 021 · API-07-035 · UI-07-06 · FR-00-032
    Biết F-ERR (12 dòng dữ liệu từ dòng 3 tới 14 của sheet `DuLieu`).
    Khi tạo tác vụ UPSERT, chờ `VALIDATED`.
    Và gọi `GET /import-jobs/{jobId}/rows?valid=false`.
    Và trên UI-07-06 bước "Xem trước và lỗi", lọc "Chỉ dòng lỗi".
    Thì trạng thái `VALIDATED` (có lỗi vẫn là xem trước thành công), `errorRows` = 9. Danh sách lỗi khớp bảng sau (số dòng là số dòng trong Excel). Giao diện hiển thị cùng thông tin, ô lỗi được tô và có chú thích.

  @TC-07-101 @P1 @Âm
  Kịch bản: TC-07-101 Commit tệp có dòng lỗi mà không chọn bỏ qua
    # Truy vết: FR-07-021 · BR-07-015 · ERR-07-021 · FR-00-032
    Biết tác vụ F-ERR ở `VALIDATED`.
    Khi gọi `:commit` với `{"skipInvalidRows":false}`.
    Và đếm bản ghi bản nháp.
    Thì `422` `ERR-07-021`; tác vụ giữ `VALIDATED` (có thể commit lại với tùy chọn bỏ qua); bản nháp không đổi một dòng nào.

  @TC-07-102 @P1 @Dương
  Kịch bản: TC-07-102 Commit có bỏ qua dòng lỗi
    # Truy vết: FR-07-021 · BR-07-015
    Biết tác vụ F-ERR ở `VALIDATED`.
    Khi gọi `:commit` với `{"skipInvalidRows":true}`.
    Thì `COMMITTED`; chỉ các dòng hợp lệ được ghi; tóm tắt có `committedRows`, `skippedRows`; bản ghi kiểm toán ghi rõ số dòng bỏ qua.

  @TC-07-103 @P1 @Dương
  Kịch bản: TC-07-103 Tải báo cáo lỗi và xem lịch sử tác vụ
    # Truy vết: FR-07-025 · API-07-035, 040 · UI-07-08
    Biết tác vụ F-ERR đã chạy.
    Khi gọi `GET /import-jobs/{jobId}/rows?valid=false&format=xlsx`.
    Và gọi `GET /jobs?type=IMPORT&catalogCode=LOAI_HINH_TC`.
    Và mở UI-07-08, lọc theo danh mục.
    Thì bước 1 trả xlsx gồm dữ liệu gốc của dòng lỗi và cột "Lỗi" mô tả tiếng Việt, người dùng sửa và nhập lại được. Bước 2 trả danh sách có `status`, `mode`, `fileName`, số dòng, người tạo, thời gian. Không lộ `file_id` nội bộ hoặc đường dẫn kho đối tượng.

  @TC-07-104 @P1 @Âm @Biên
  Kịch bản: TC-07-104 Kết quả xem trước hết hạn sau 24 giờ
    # Truy vết: FR-07-021 · BR-07-016 · ERR-07-020
    Biết tác vụ F-OK10 ở `VALIDATED` lúc T0.
    Khi đặt đồng hồ T0 + 23 giờ 59 phút; gọi `GET /import-jobs/{jobId}`.
    Và đặt đồng hồ T0 + 24 giờ 1 phút; chạy bộ dọn tác vụ hết hạn; gọi `GET`.
    Và gọi `:commit`.
    Thì bước 1 vẫn `VALIDATED`. Bước 2 trạng thái `EXPIRED`. Bước 3 trả `409` `ERR-07-020` (chi tiết "đã hết hạn"). Dòng `import_row` bị dọn theo lịch 7 ngày.

  @TC-07-105 @P1 @Âm
  Kịch bản: TC-07-105 Bản nháp bị sửa sau khi phân tích
    # Truy vết: FR-07-021 · BR-07-016 · ERR-07-020
    Biết tác vụ F-OK10 ở `VALIDATED` (ghi nhận `version` của bản nháp lúc phân tích).
    Khi người khác sửa một bản ghi trong bản nháp qua `PATCH`.
    Và gọi `:commit`.
    Thì `409` `ERR-07-020` (chi tiết "bản nháp đã thay đổi, vui lòng phân tích lại"). Không ghi gì. Tác vụ chuyển `FAILED` hoặc giữ `VALIDATED` có cờ `stale` theo SDD; ca này chỉ yêu cầu không commit được.

  @TC-07-106 @P2 @Âm
  Kịch bản: TC-07-106 Commit lại tác vụ đã ghi
    # Truy vết: FR-07-021 · ERR-07-020
    Biết tác vụ TC-07-095 `COMMITTED`.
    Khi gọi lại `:commit` không có `Idempotency-Key`.
    Và gọi lại `:commit` với đúng `Idempotency-Key` của lần commit trước.
    Thì bước 1 trả `409` `ERR-07-020`. Bước 2 trả lại phản hồi lần đầu (phát lại idempotent), không ghi thêm.

  @TC-07-107 @P2 @Dương
  Kịch bản: TC-07-107 Hủy tác vụ nhập đang chờ xác nhận
    # Truy vết: FR-07-021 · API-07-037
    Biết tác vụ ở `VALIDATED`.
    Khi gọi `POST /import-jobs/{jobId}:cancel`.
    Thì `200`, trạng thái `CANCELLED`; tệp tải lên được đánh dấu hết hạn trong `file_object`; bản nháp không đổi.

  @TC-07-108 @P2 @Âm
  Kịch bản: TC-07-108 Commit tác vụ đã hủy
    # Truy vết: FR-07-021 · ERR-07-020
    Biết tác vụ `CANCELLED`.
    Khi gọi `:commit`.
    Và gọi `:cancel` lần nữa.
    Thì bước 1 trả `409` `ERR-07-020`. Bước 2 trả `409` `ERR-07-020` hoặc `200` không đổi trạng thái (idempotent) theo D03-04; không lỗi `500`.

  @TC-07-109 @P2 @Dương
  Kịch bản: TC-07-109 Ghép cột khi tiêu đề tệp khác khuôn mẫu
    # Truy vết: FR-07-021 · UI-07-06 · EN-07-08 (`column_mapping`)
    Biết tệp `custom_header.xlsx` có tiêu đề "Mã", "Tên loại hình", "Mã cấp trên", "Viết tắt", thêm cột "Cột thừa".
    Khi tạo tác vụ; hệ thống đề xuất ghép cột tự động.
    Và trên UI-07-06 bước "Ghép cột", xác nhận đề xuất, đặt "Cột thừa" là "Bỏ qua"; gửi `columnMapping`.
    Và chờ `VALIDATED`.
    Thì đề xuất ghép tự động đúng 4 cột theo nhãn (không dấu, không phân biệt hoa thường). Cột bỏ qua không gây lỗi. Ghép thiếu cột bắt buộc `TEN` thì nút "Tiếp tục" bị vô hiệu và API trả `422` `ERR-07-019`.

  @TC-07-110 @P1 @Âm
  Kịch bản: TC-07-110 Lỗi giữa chừng khi commit được hoàn tác toàn bộ
    # Truy vết: FR-07-021 · BR-07-015
    Biết F-100K vào `DM_LON_100K`, tác vụ `VALIDATED`; cấu hình tiêm lỗi ném ngoại lệ ở dòng 70.000 của bước ghi.
    Khi gọi `:commit`.
    Và đếm bản ghi bản nháp; kiểm tra outbox.
    Thì tác vụ `FAILED` với `errorMessage` không lộ chi tiết kỹ thuật; bản nháp đúng như trước commit (0 dòng được ghi); EVT-07-07 phát với `status = FAILED`; không có sự kiện nào khác.
