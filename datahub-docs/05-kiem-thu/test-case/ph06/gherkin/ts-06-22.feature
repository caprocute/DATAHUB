# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-22
Tính năng: TS-06-22 · Giải quyết bản ghi trực tuyến (resolve)

  @TC-06-096 @P1 @Dương
  Kịch bản: TC-06-096 Resolve có CCCD trả MATCH
    # Truy vết: FR-06-047 · API-06-071 · BR-06-001, 010 · NFR-06-002
    # Mục đích: Chứng minh `200` kèm `goldenId`, điểm, phương thức, thuộc tính đã che, theo FR-06-047.
    Biết bản ghi vàng Bình; S-T90-RESOLVE.
    Khi `POST /domains/CITIZEN:resolve` `attributes` có CC-03, `requestingSource = HT-YTE`.
    Thì `200`, `outcome = MATCH`, `method = DETERMINISTIC`, `goldenId`, `score`, `attributeScores`; thuộc tính che theo mục đích; không tạo ứng viên và không đổi bản ghi vàng; `access_log` không lưu giá trị đã gửi; NK: có.
    # Hậu điều kiện: Một dòng access_log.

  @TC-06-097 @P1 @Dương
  Kịch bản: TC-06-097 Resolve nghi ngờ trả 202 và tạo mục hàng đợi
    # Truy vết: FR-06-047 · BR-06-002 · API-06-071 · EVT-06-08
    # Mục đích: Chứng minh `POSSIBLE_MATCH` trả tối đa 3 ứng viên và không ghi dữ liệu theo kết quả, theo FR-06-047.
    Biết hai bản ghi vàng cùng tên "Lê Văn Cường"; không CCCD.
    Khi `resolve` mặc định `LOOKUP_ONLY`.
    Và `resolve` `LOOKUP_OR_QUEUE`.
    Thì bước 1 `202`, `candidates[]` ≤ 3 chỉ có `goldenId`, điểm, thuộc tính hiển thị đã che. Bước 2 `202` kèm `queueItemId`, EVT-06-08 một lần.
    # Hậu điều kiện: Một mục hàng đợi.

  @TC-06-098 @P1 @Âm
  Kịch bản: TC-06-098 Resolve không khớp trả 404 NO_MATCH
    # Truy vết: FR-06-047 · API-06-071 · ERR-06-050
    # Mục đích: Chứng minh người gọi nhận `404` có `outcome = NO_MATCH`, theo FR-06-047.
    Biết hồ sơ giả chưa có trong T90.
    Khi `resolve` hồ sơ đó.
    Thì `404` ERR-06-050 `outcome = NO_MATCH`; không tạo bản ghi vàng.
    # Hậu điều kiện: Không đổi.

  @TC-06-099 @P1 @Âm
  Kịch bản: TC-06-099 Thiếu thuộc tính tối thiểu, vượt hạn mức, thiếu mục đích
    # Truy vết: FR-06-047 · API-06-071 · ERR-06-003, 037, 048
    # Mục đích: Chứng minh ba nhánh lỗi, theo FR-06-047.
    Biết T92 hạn mức nhỏ; S-T90-NOPURPOSE.
    Khi `resolve` chỉ có `email`.
    Và gọi 1.000 lượt trong một phút vượt hạn mức.
    Và `resolve` bằng S-T90-NOPURPOSE.
    Thì bước 1 `400` ERR-06-003 "Cần ít nhất {n} thuộc tính …". Bước 2 từ lượt vượt `429` ERR-06-048. Bước 3 `403` ERR-06-037.
    # Hậu điều kiện: Không đổi.
