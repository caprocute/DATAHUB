# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-21
Tính năng: TS-06-21 · Tra cứu, tra ID nguồn và tìm kiếm có che dữ liệu

  @TC-06-089 @P1 @Dương
  Kịch bản: TC-06-089 Tra bản ghi vàng theo ID và theo khóa định danh
    # Truy vết: FR-06-046 · API-06-056, 070 · NFR-06-001 · BR-06-010, 026
    # Mục đích: Chứng minh tra theo `goldenId` và theo CCCD trong thân `POST`, theo FR-06-046.
    Biết bản ghi vàng Bình; S-T90-READ có mục đích `MD-TRACUU`.
    Khi `GET .../golden-records/{id}` với `X-Purpose`.
    Và `POST .../golden-records:lookup` thân `{ "identifier": CC-03 }`.
    Và quét log APISIX tìm CC-03.
    Thì bước 1, 2 `200` cùng bản ghi, thuộc tính trong phạm vi mục đích, che theo phân loại, NK: có. Bước 3 không có CC-03 trong URL, log (số định danh luôn trong thân).
    # Hậu điều kiện: Hai dòng access_log.

  @TC-06-090 @P1 @Âm
  Kịch bản: TC-06-090 Không tìm thấy, thiếu mục đích, thiếu scope
    # Truy vết: FR-06-046, 052 · BR-06-026 · API-06-070 · ERR-06-037, 050
    # Mục đích: Chứng minh ba nhánh lỗi tra cứu, theo FR-06-046.
    Biết S-T90-READ, S-T90-NOPURPOSE, token không scope `mdm:read`.
    Khi `lookup` khóa không tồn tại.
    Và `lookup` bằng S-T90-NOPURPOSE.
    Và `lookup` bằng token không scope.
    Thì bước 1 `404` ERR-06-050. Bước 2 `403` ERR-06-037. Bước 3 403-PQ. Không dòng `access_log` trả dữ liệu cho bước 2, 3.
    # Hậu điều kiện: Không đổi.

  @TC-06-091 @P1 @Dương @Âm
  Kịch bản: TC-06-091 Tra ID nguồn và ID vàng, tra lô
    # Truy vết: FR-06-045 · API-06-068, 069 · ERR-06-003, 050
    # Mục đích: Chứng minh tra hai chiều `(sourceCode, sourceKey)` và `goldenId`, theo FR-06-045.
    Biết bản ghi vàng Bình có xref `HT-YTE`/`YT-0001`.
    Khi `GET .../xrefs/HT-YTE/YT-0001`.
    Và `POST .../xrefs:batch-lookup` 100 cặp, 5 cặp không có.
    Và `batch-lookup` 1.001 cặp.
    Thì bước 1 `goldenId` đúng. Bước 2 95 kết quả, 5 `NOT_FOUND`. Bước 3 `400` ERR-06-003 (quá giới hạn lô).
    # Hậu điều kiện: Không đổi.

  @TC-06-092 @P2 @Dương
  Kịch bản: TC-06-092 Tìm kiếm bản ghi vàng theo thuộc tính
    # Truy vết: FR-06-048 · API-06-072 · UI-06-02 · BR-06-013
    # Mục đích: Chứng minh tìm theo họ tên cộng năm sinh hoặc xã, phân trang, theo FR-06-048.
    Biết S-T90-SEARCH (`mdm:search`, mục đích chấp thuận); T97.
    Khi `POST .../golden-records:search` họ tên `Nguyễn Văn An` và năm sinh 1990, `size = 20`.
    Và tìm họ tên có dấu và không dấu.
    Thì bước 1 trang kết quả đúng, mỗi bản ghi đã che, NK: có từng bản ghi. Bước 2 cùng tập kết quả.
    # Hậu điều kiện: Một lượt tìm.

  @TC-06-093 @P1 @Âm
  Kịch bản: TC-06-093 Tiêu chí quá rộng, thiếu scope, truy cập hàng loạt
    # Truy vết: FR-06-048 · BR-06-013 · API-06-072 · ERR-06-038, 040
    # Mục đích: Chứng minh chặn tìm rộng và truy cập vượt 100 bản ghi trong 10 phút, theo BR-06-013.
    Biết `06.access.bulk-threshold = 100 bản ghi / 10 phút`.
    Khi tìm chỉ họ tên.
    Và tìm lần lượt 12 trang × 10 bản ghi khác nhau trong 10 phút.
    Và tìm bằng token thiếu `mdm:search`.
    Thì bước 1 `422` ERR-06-040. Bước 2 từ bản ghi thứ 101 `403` ERR-06-038, ghi vết đặc biệt, cảnh báo quét bất thường. Bước 3 403-PQ.
    # Hậu điều kiện: Một vết đặc biệt.

  @TC-06-094 @P1 @Dương @Bảo @mật
  Kịch bản: TC-06-094 Che dữ liệu theo phân loại, vai trò và mục đích
    # Truy vết: FR-06-052 · BR-06-016, 026 · API-06-056, 072 · UI-06-03
    # Mục đích: Chứng minh ma trận `DataClass` × vai trò × mục đích, giá trị `SENSITIVE` luôn che nếu thiếu `PERM-09-unmask`, theo FR-06-052.
    Biết bản ghi vàng đủ bốn mức `DataClass`; DS1 không và có `PERM-09-unmask`; token máy mục đích phạm vi hẹp.
    Khi chạy bảng tham số vai trò, mục đích, thuộc tính.
    Và gọi xuất và tìm kiếm với mục đích hẹp.
    Và quét phản hồi tìm canary `SENSITIVE`.
    Thì `PUBLIC` rõ cho mọi vai trò có `read`; `INTERNAL`, `RESTRICTED` che theo chính sách PH-09; `SENSITIVE` che kể cả DS, chỉ hiện khi có `PERM-09-unmask` cộng lý do và ghi vết. Thuộc tính ngoài mục đích bị lược khỏi phản hồi. Mồi sạch.
    # Hậu điều kiện: Không đổi.

  @TC-06-095 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-06-095 Dừng nhật ký truy cập thì mọi API trả dữ liệu từ chối
    # Truy vết: BR-06-010 · ERR-06-039 · NFR-06-015
    # Mục đích: Chứng minh tiêu chí chấp nhận 6: không ghi được `access_log` thì không trả dữ liệu.
    Biết T95; token đủ quyền cho từng API trả dữ liệu.
    Khi dừng dịch vụ ghi `access_log`.
    Và gọi API-06-056, 068, 069, 070, 071, 072 và xuất, chi tiết ứng viên, so sánh cạnh nhau.
    Và khôi phục, gọi lại.
    Thì bước 2 mọi API `503` ERR-06-039, thân không chứa giá trị. Bước 3 trả `200`, số dòng `access_log` bằng số lượt thành công ở APISIX.
    # Hậu điều kiện: Không dòng thừa.
