# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-13
Tính năng: TS-07-13 · Truy vấn có cấu trúc (DSL)

  @TC-07-157 @P1 @Dương
  Kịch bản: TC-07-157 Lọc theo thuộc tính queryable, chọn trường và sắp xếp
    # Truy vết: FR-07-032 · BR-07-018 · API-07-047 · LGC-DMDC-016
    Biết CAT-LH v1; 9 bản ghi cấp 2 có `cap_quan_ly = TINH`.
    Khi gọi với `filter = {"and":[{"field":"attrs.cap_quan_ly","op":"eq","value":"TINH"},{"field":"depth","op":"eq","value":2}]}`, `select = ["code","name","attrs.viet_tat"]`, `sort = [{"field":"attrs.viet_tat","dir":"asc"}]`.
    Và gọi lại với `select` chứa `attrs.so_bien_che` (thuộc tính không `queryable`).
    Thì bước 1 trả `200`, `items` có đúng các bản ghi thỏa hai điều kiện, mỗi phần tử chỉ có ba trường đã chọn, thứ tự theo `viet_tat` rồi `code`; `catalogVersion` = 1; có `took`. Bước 2 trả `200` (thuộc tính không `queryable` vẫn được chọn, chỉ không được lọc hoặc sắp xếp). KT: không. EVT: không.

  @TC-07-158 @P2 @Dương
  Kịch bản: TC-07-158 Nhóm `and`, `or`, `not` lồng nhau và toán tử tập hợp
    # Truy vết: FR-07-032 · API-07-047
    Biết CAT-LH v1.
    Khi gọi với `{"or":[{"field":"code","op":"startsWith","value":"KH01"},{"not":{"field":"attrs.cap_quan_ly","op":"in","value":["XA"]}}]}`.
    Và gọi với `{"field":"attrs.viet_tat","op":"isNull"}`.
    Và gọi với `{"field":"name","op":"contains","value":"giao duc"}`.
    Thì kết quả từng bước khớp với kết quả tính bằng truy vấn SQL tham chiếu viết tay trên cùng dữ liệu (so tập mã). Bước 3 khớp tên có dấu "Giáo dục" (không dấu, không phân biệt hoa thường). Kiểm thử đơn vị của bộ dịch xác nhận câu SQL sinh ra chỉ có tham số `$n`, không có giá trị nối chuỗi.

  @TC-07-159 @P2 @Dương
  Kịch bản: TC-07-159 Truy vấn tại thời điểm và theo phiên bản
    # Truy vết: FR-07-032 · FR-07-026 · API-07-047
    Biết CAT-GT v1 (2020-01-01…2025-01-01), v2 (từ 2025-01-01). Người gọi APP-T68-QUERY (CAT-GT là COMMON, mọi tenant đọc được).
    Khi gọi `/catalogs/GIOI_TINH/items:query` với `at = 2024-06-01`.
    Và gọi với `version = 2`.
    Và gọi với cả `at` và `version`.
    Thì bước 1 trả `catalogVersion` = 1. Bước 2 trả `catalogVersion` = 2. Bước 3 trả `400` `ERR-07-023` (hai tham số loại trừ nhau).

  @TC-07-160 @P1 @Dương
  Kịch bản: TC-07-160 Phân trang bằng con trỏ ổn định
    # Truy vết: FR-07-032 · API-07-047 · NFR-07-004
    Biết CAT-BIG (100.000 bản ghi).
    Khi gọi với `limit = 1000`, `sort = [{"field":"sortOrder","dir":"asc"}]`, lặp theo `nextCursor` tới khi rỗng.
    Và trong lúc lặp, một luồng khác tạo và phát hành phiên bản mới của CAT-BIG.
    Thì tổng số mã thu được bằng 100.000, không trùng, không sót; mọi trang có cùng `catalogVersion` (con trỏ gắn với phiên bản của trang đầu). Trang cuối có `nextCursor = null`.

  @TC-07-161 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-161 Con trỏ bị sửa hoặc dùng với bộ lọc khác
    # Truy vết: FR-07-032 · ERR-07-023
    Biết một `nextCursor` hợp lệ lấy từ TC-07-160.
    Khi đổi một ký tự trong con trỏ rồi gọi.
    Và dùng con trỏ hợp lệ nhưng thay `filter`.
    Và dùng con trỏ của tenant T68 khi gọi bằng APP-T01-READ.
    Thì bước 1, 2 trả `400` `ERR-07-023` (chữ ký HMAC sai, băm `filter` không khớp). Bước 3 trả `400` hoặc `404-ẩn`, không trả dữ liệu của T68.

  @TC-07-162 @P1 @Âm
  Kịch bản: TC-07-162 Lọc trên thuộc tính không queryable
    # Truy vết: FR-07-032 · BR-07-018 · ERR-07-025
    Biết CAT-LH: `so_bien_che` không `queryable`.
    Khi gọi với `{"field":"attrs.so_bien_che","op":"gt","value":10}`.
    Và gọi với `sort = [{"field":"attrs.so_bien_che","dir":"desc"}]`.
    Và gọi với `{"field":"attrs.khong_ton_tai","op":"eq","value":"x"}`.
    Thì cả ba trả `400` `ERR-07-025`, thân lỗi nêu tên trường và danh sách trường `queryable` hợp lệ (`viet_tat`, `cap_quan_ly`). Chỉ số `rdm_query_rejected_total{reason="NOT_QUERYABLE"}` tăng 3.

  @TC-07-163 @P1 @Âm
  Kịch bản: TC-07-163 Biểu thức sai cú pháp và sai kiểu giá trị
    # Truy vết: FR-07-032 · ERR-07-023
    Biết CAT-LH.
    Khi gửi `filter` có khóa lạ `{"field":"code","op":"regex","value":".*"}`.
    Và gửi `{"field":"attrs.ngay_thanh_lap","op":"gte","value":"31/02/2024"}` (không phải ngày ISO).
    Và gửi `between` với 3 phần tử.
    Và gửi `contains` với chuỗi 1 ký tự.
    Và gửi thân không phải JSON.
    Thì bước 1…4 trả `400` `ERR-07-023`, trường `errors[].pointer` chỉ đúng vị trí bằng JSON Pointer (ví dụ `/filter/op`). Bước 5 trả `400` `ERR-07-023`. Không có thông điệp SQL hay ngăn xếp lỗi Java trong phản hồi.

  @TC-07-164 @P1 @Âm @Biên
  Kịch bản: TC-07-164 Vượt giới hạn độ phức tạp
    # Truy vết: FR-07-032 · ERR-07-024
    Biết CAT-LH.
    Khi gửi 20 điều kiện lá (biên), rồi 21 điều kiện.
    Và gửi nhóm lồng 3 cấp (biên), rồi 4 cấp.
    Và gửi `in` 500 phần tử, rồi 501.
    Và gửi `limit = 1000`, rồi `1001`.
    Thì các lần ở biên trả `200`. Các lần vượt trả `422` `ERR-07-024` với `reason` lần lượt `TOO_MANY_CONDITIONS`, `TOO_DEEP`, `IN_TOO_LARGE`, `LIMIT_TOO_LARGE`.

  @TC-07-165 @P2 @Âm @Khả @dụng
  Kịch bản: TC-07-165 Truy vấn quá thời gian bị cắt
    # Truy vết: FR-07-032 · ERR-07-024 · NFR-07-004
    Biết CAT-BIG; IT tiêm độ trễ bằng `pg_sleep` qua hàm `unaccent_lower` thay thế trong schema thử.
    Khi gửi truy vấn `contains` trên `name` khiến câu SQL chạy quá 2 giây.
    Và ngay sau đó gửi một truy vấn đơn giản.
    Thì bước 1 trả `422` `ERR-07-024` `reason = TIMEOUT` sau khoảng 2 giây, kết nối được trả về pool (đếm `hikaricp_connections_active` trở lại mức trước). Bước 2 trả `200` bình thường. Giao dịch của bước 1 là chỉ đọc (kiểm tra `SHOW transaction_read_only`).

  @TC-07-166 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-166 Chống chèn SQL qua giá trị và tên trường
    # Truy vết: FR-07-032 · BR-07-018 · ASVS V5.3
    Biết CAT-LH.
    Khi gửi `{"field":"code","op":"eq","value":"x' OR '1'='1"}`.
    Và gửi `{"field":"attrs.viet_tat') OR 1=1 --","op":"eq","value":"x"}`.
    Và gửi `{"field":"name","op":"contains","value":"%_%"}`.
    Thì bước 1 trả `200` với `items` rỗng. Bước 2 trả `400` `ERR-07-025` (tên trường không thuộc danh sách cho phép). Bước 3 trả các bản ghi có tên chứa đúng chuỗi "%_%" (ký tự đại diện đã được thoát), tức rỗng với dữ liệu mẫu. Nhật ký PostgreSQL không có câu lệnh chứa giá trị nối chuỗi.

  @TC-07-167 @P2 @Dương
  Kịch bản: TC-07-167 Danh mục HYBRID trả hợp của gốc và phần bổ sung
    # Truy vết: FR-07-032 · FR-07-048 · API-07-047
    Biết CAT-DT68 (HYBRID trên `DAN_TOC`, 2 bản ghi bổ sung).
    Khi gọi `/catalogs/DAN_TOC_T68/items:query` với `filter = {"field":"code","op":"startsWith","value":"68"}`.
    Và gọi không có `filter`, `limit = 100`.
    Thì bước 1 trả đúng `68.01`, `68.02`. Bước 2 trả 57 bản ghi (55 gốc cộng 2 bổ sung), mỗi phần tử có cờ `isLocalExtension` đúng.

  @TC-07-168 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-168 Scope và danh mục hạn chế
    # Truy vết: FR-07-032 · FR-07-052 · ERR-07-030
    Biết CAT-RES cấp cho `HT-DATDAI` (APP-T68-QUERY), không cấp cho `HT-HOTICH` (APP-T68-READ).
    Khi APP-T68-READ (không có `rdm.query`) gọi truy vấn trên CAT-LH.
    Và APP-T68-QUERY gọi truy vấn trên CAT-RES.
    Và một client có `rdm.query` nhưng thuộc HTTT `HT-KHAC` gọi truy vấn trên CAT-RES.
    Thì bước 1 trả `403-PQ`. Bước 2 trả `200`. Bước 3 trả `403` `ERR-07-030`.

  @TC-07-169 @P2 @Dương
  Kịch bản: TC-07-169 Trình thử API trên giao diện
    # Truy vết: FR-07-032 · UI-07-12 · LGC-DMDC-016
    Biết U-T68-DEV đăng nhập.
    Khi mở UI-07-12, chọn `LOAI_HINH_TC`, dùng bộ dựng điều kiện chọn `cap_quan_ly = TINH`.
    Và chuyển sang tab JSON, sửa `limit` thành 5, bấm Chạy (Ctrl+Enter).
    Và bấm "Sao chép cURL".
    Thì bộ dựng chỉ cho chọn thuộc tính `queryable`. Bước 2 hiển thị `200`, thời gian, 5 dòng ở chế độ Bảng và JSON. Bước 3 đưa vào bộ nhớ tạm lệnh cURL không chứa token thật (dùng biến `$TOKEN`).

  @TC-07-170 @P3 @Âm
  Kịch bản: TC-07-170 Trình thử API báo lỗi tại chỗ
    # Truy vết: FR-07-032 · UI-07-12 · ERR-07-023, 025
    Biết U-T68-DEV.
    Khi trong khung JSON, gõ `"op": "regex"`.
    Và gõ một trường không `queryable` rồi bấm Chạy.
    Thì bước 1: khung mã gạch đỏ ngay khi gõ (kiểm tra theo JSON Schema của DSL ở phía trình duyệt), nút Chạy vẫn bấm được. Bước 2: vùng kết quả hiện `400`, thông điệp tiếng Việt "Thuộc tính `so_bien_che` không cho phép lọc. Các thuộc tính lọc được: viet_tat, cap_quan_ly." và vị trí lỗi được đánh dấu trong khung mã.
