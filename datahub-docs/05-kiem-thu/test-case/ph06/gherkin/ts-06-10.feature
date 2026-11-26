# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-10
Tính năng: TS-06-10 · Đối sánh tự động và tạo, cập nhật bản ghi vàng

  @TC-06-041 @P1 @Dương
  Kịch bản: TC-06-041 Đối sánh xác định theo CCCD hợp lệ
    # Truy vết: FR-06-020 · BR-06-001 · NFR-06-010 · API-06-071
    # Mục đích: Chứng minh cùng CCCD hợp lệ cho `MATCH` `DETERMINISTIC` điểm 1,0 dù tên khác, theo BR-06-001.
    Biết bản ghi vàng An CC-01; nguồn `HT-GIAODUC`.
    Khi gửi ứng viên CC-01 tên `NGUYEN V. AN`, ngày sinh sai tháng.
    Thì `outcome = MATCH`, `method = DETERMINISTIC`, `score = 1,0`; ứng viên `LINKED` vào bản ghi vàng An; tên không đổi nếu nguồn ưu tiên thấp hơn. EVT-06-02 nếu thuộc tính đổi.
    # Hậu điều kiện: An có thêm một liên kết.

  @TC-06-042 @P1 @Âm
  Kịch bản: TC-06-042 Khóa sai kiểm tra không dùng đối sánh xác định
    # Truy vết: FR-06-020 · BR-06-001 · NFR-06-010
    # Mục đích: Chứng minh `CC-X` và `MST-X` rơi xuống đối sánh xác suất, theo BR-06-001.
    Biết bản ghi vàng ORG có `MST-01`; ứng viên MST-X cùng tên.
    Khi gửi ứng viên tổ chức với `MST-X`.
    Và gửi ứng viên công dân với CCCD toàn số 0 trùng một bản ghi vàng.
    Thì bước 1 `method` không phải `DETERMINISTIC`; kết luận theo điểm xác suất. Bước 2 không `MATCH` xác định; gắn `IDENTIFIER_INVALID`.
    # Hậu điều kiện: Không liên kết sai.

  @TC-06-043 @P1 @Âm
  Kịch bản: TC-06-043 Cùng tên, ngày sinh khác CCCD không hợp nhất
    # Truy vết: FR-06-020, 021 · BR-06-006 · ERR-06-029 · UI-06-05
    # Mục đích: Chứng minh quy tắc loại trừ chặn hợp nhất hai khóa xác định khác nhau, theo BR-06-006.
    Biết CC-01 và CC-02 cùng tên, cùng ngày sinh (F-CIT).
    Khi nạp ứng viên CC-02 khi bản ghi vàng CC-01 đã có.
    Và chạy lại `resolve` với tên, ngày sinh, kèm CC-02.
    Thì bước 1 tạo bản ghi vàng mới; mục hàng đợi `IDENTIFIER_CONFLICT` ưu tiên 90, SLA 1 ngày. Bước 2 `outcome = CONFLICT` hoặc `NO_MATCH` với CC-01, không bao giờ `MATCH`.
    # Hậu điều kiện: Hai bản ghi vàng riêng, một mục hàng đợi.

  @TC-06-044 @P1 @Dương
  Kịch bản: TC-06-044 Đối sánh xác suất: vùng MATCH và POSSIBLE_MATCH
    # Truy vết: FR-06-021 · BR-06-002 · API-06-071 · NFR-06-003
    # Mục đích: Chứng minh ba vùng điểm theo ngưỡng 0,90 và 0,10, theo FR-06-021.
    Biết bộ quy tắc v2 ACTIVE (`0,92`/`0,15`); 5 cặp có điểm 0,97; 0,93; 0,50; 0,16; 0,05.
    Khi nạp 5 ứng viên, đọc `match_result`.
    Thì điểm 0,97 và 0,93 `MATCH` `PROBABILISTIC_ONLINE` tự gắn; 0,50 và 0,16 `POSSIBLE_MATCH` vào hàng đợi (không tự động); 0,05 `NO_MATCH` tạo bản ghi vàng mới. `match_result` lưu điểm từng thuộc tính và 5 ứng viên đầu.
    # Hậu điều kiện: 2 mục hàng đợi.

  @TC-06-045 @P1 @Âm
  Kịch bản: TC-06-045 Nhiều ứng viên cùng vượt ngưỡng
    # Truy vết: FR-06-021 · BR-06-002 · API-06-071
    # Mục đích: Chứng minh hai ứng viên điểm sát nhau thì không tự hợp nhất, theo FR-06-021.
    Biết hai bản ghi vàng "Trần Văn Bảo" sinh 1985 điểm 0,93 và 0,92 với ứng viên mới.
    Khi nạp ứng viên.
    Thì `POSSIBLE_MATCH`, `QueueReason = MULTIPLE_CANDIDATES`, mục hàng đợi chứa cả hai.
    # Hậu điều kiện: Một mục.

  @TC-06-046 @P1 @Âm
  Kịch bản: TC-06-046 Ít thuộc tính dùng được
    # Truy vết: FR-06-021 · BR-06-015 · API-06-071
    # Mục đích: Chứng minh ứng viên dưới `minAttributes` không tự hợp nhất, theo BR-06-015.
    Biết `minAttributes = 3`; ứng viên chỉ có họ tên và điện thoại.
    Khi nạp ứng viên trùng họ tên với một bản ghi vàng.
    Và nạp ứng viên không giống khối nào.
    Thì bước 1 `POSSIBLE_MATCH` `INSUFFICIENT_ATTRIBUTES`. Bước 2 `NO_MATCH`.
    # Hậu điều kiện: Một mục.

  @TC-06-047 @P1 @Dương
  Kịch bản: TC-06-047 Ba nguồn chồng lấn cho một bản ghi vàng
    # Truy vết: FR-06-034, 043 · BR-06-003, 009, 018 · EVT-06-01, 02
    # Mục đích: Chứng minh tiêu chí chấp nhận 3 của FRS: một bản ghi vàng, ba liên kết, ngày sinh từ `QG-DANCU`.
    Biết bảng ưu tiên của prio-approve ACTIVE; CC-03 ở `QG-DANCU`, `HT-YTE`, `HT-GIAODUC` với ngày sinh khác nhau.
    Khi nạp lần lượt `HT-GIAODUC`, `HT-YTE`, `QG-DANCU`.
    Và `GET .../golden-records/{id}` và `/lineage`.
    Thì một `goldenId` UUID v7, `version` tăng theo từng thay đổi, ba xref `ACTIVE`, `dateOfBirth` lấy từ `QG-DANCU`, lineage ghi nguồn từng thuộc tính. EVT-06-01 một lần, EVT-06-02 hai lần, không chứa giá trị.
    # Hậu điều kiện: Bản ghi vàng Bình dùng ở các TS sau.

  @TC-06-048 @P2 @Dương
  Kịch bản: TC-06-048 Nguồn gửi lại y nguyên
    # Truy vết: FR-06-034 · EVT-06-02
    # Mục đích: Chứng minh không đổi giá trị thì không tăng `version`, không phát sự kiện, theo FR-06-034.
    Biết bản ghi vàng Bình version n.
    Khi nguồn `HT-YTE` gửi `sourceVersion` mới, cùng giá trị.
    Thì xref cập nhật thời điểm, `version` giữ n, EVT: không, không dòng `golden_history` mới.
    # Hậu điều kiện: Không đổi.

  @TC-06-049 @P1 @Âm
  Kịch bản: TC-06-049 Không ghi được lịch sử thì hủy cập nhật
    # Truy vết: FR-06-034 · BR-06-005 · ERR-06-111
    # Mục đích: Chứng minh ảnh chụp ghi trong cùng giao dịch, ghi lỗi thì không đổi bản ghi vàng, theo BR-06-005.
    Biết bản ghi vàng Bình; gây lỗi ghi `golden_history` bằng quyền thu hồi ở PostgreSQL (T95).
    Khi nạp ứng viên đổi `phone`.
    Và khôi phục quyền, chờ thử lại.
    Thì bước 1 giao dịch hủy, bản ghi vàng nguyên vẹn, ứng viên giữ `NORMALIZED`, ERR-06-111 ở nhật ký xử lý, thử lại 3 lần giãn dần. Bước 2 cập nhật thành công, có đủ ảnh chụp.
    # Hậu điều kiện: Một ảnh chụp mới.

  @TC-06-050 @P1 @Âm
  Kịch bản: TC-06-050 Máy không ghi đè quyết định của người
    # Truy vết: FR-06-021 · BR-06-023 · API-06-071
    # Mục đích: Chứng minh cặp có `negativeLink` không bị đề xuất hợp nhất lại, theo BR-06-023.
    Biết cặp P-17 đã được DS2 quyết `NO_MATCH`.
    Khi nạp ứng viên mới giống P-17 điểm 0,95.
    Và chạy job lô trên domain.
    Thì không `MATCH`, không mục hàng đợi mới cho cặp; ca lô bỏ qua cặp, đếm vào `skipped`.
    # Hậu điều kiện: Không đổi.
