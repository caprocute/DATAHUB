# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-29
Tính năng: TS-09-29 · Tiếp nhận, xác minh, tra cứu và chuyển xử lý yêu cầu của chủ thể

  @TC-09-099 @P1 @Dương @Âm
  Kịch bản: TC-09-099 Tiếp nhận yêu cầu ở ba kênh, trùng lặp và thiếu thông tin
    # Truy vết: FR-09-045 · API-09-165, 166 · UI-09-16 · ERR-09-062, 064 · BR-09-061, 045 · EVT-09-22
    # Mục đích: Chứng minh tiếp nhận có `Idempotency-Key`, định danh chỉ giữ mã hóa trong phiếu và không trùng yêu cầu cùng loại.
    Biết T90; chủ thể CC-01; U-T90-DS1; S-T90-REG (kênh dịch vụ công).
    Khi S-T90-REG `POST /subject-requests` loại `ACCESS`, kênh `PUBLIC_SERVICE`, CCCD CC-01, khóa K2; gửi lại với K2.
    Và DS1 tiếp nhận kênh `COUNTER` loại `ERASE` thiếu loại hoặc định danh.
    Và DS1 tiếp nhận lại `ACCESS` cho CC-01 khi còn yêu cầu đang xử lý.
    Thì bước 1 `201` `RECEIVED`, hạn 10 ngày làm việc, gửi lại cùng kết quả; CCCD không có ở bảng khác ngoài phiếu mã hóa; EVT: `dsr.received`. Bước 2 `422` ERR-09-062. Bước 3 `409` ERR-09-064.

  @TC-09-100 @P1 @Dương @Âm
  Kịch bản: TC-09-100 Chưa xác minh không tra cứu được; sau xác minh tra theo băm
    # Truy vết: FR-09-046, 047 · API-09-167, 168, 169, 235 · ERR-09-063, 065 · BR-09-042, 045
    # Mục đích: Chứng minh BR-09-042 và tra cứu theo băm HMAC khóa theo tenant (BR-09-045).
    Biết T90; yêu cầu DSR-01 `RECEIVED`; CC-01 xuất hiện ở PH-06, PH-19, PH-13 giả lập; U-T90-DS1.
    Khi DS1 `:search` khi chưa xác minh.
    Và DS1 `:verify` người đại diện không chứng minh được.
    Và DS1 `:verify` đúng (`ID_DOCUMENT`) rồi `:search`; `GET .../findings`.
    Thì bước 1 `422` ERR-09-063. Bước 2 `403` ERR-09-065. Bước 3 kết quả từ PH-06, PH-19, PH-13 chỉ gồm siêu dữ liệu (hệ thống, đối tượng, số bản ghi), tra bằng `subject-hashes:compute`; không giá trị CCCD rõ trong thân hoặc log.

  @TC-09-101 @P1 @Dương @Âm
  Kịch bản: TC-09-101 Chuyển tác vụ, bên kiểm soát, lỗi chuyển và phân công
    # Truy vết: FR-09-048 · API-09-170, 171, 172, 173 · ERR-09-066 · BR-09-044, 046
    # Mục đích: Chứng minh dữ liệu đi qua chuyển cho bên kiểm soát và xóa bị từ chối có căn cứ (BR-09-046).
    Biết T90; DSR-01 đã xác minh; PH-06 giả lập `502` ở lần đầu; yêu cầu `ERASE` cho dữ liệu có căn cứ pháp lý giữ.
    Khi DS1 `POST /subject-requests/{id}/tasks` đích `PH06_MASTER`, `PH19_PAYMENT`, `CONTROLLER`.
    Và PH-06 giả lập trả `502` rồi `200`; PH-06 `:complete`.
    Và DS1 `:assign` cho DS2; xử lý yêu cầu `ERASE` có căn cứ giữ.
    Thì bước 1 ba tác vụ `OPEN`. Bước 2 hệ thống tự thử lại, lần lỗi hiện ERR-09-066 "Chưa chuyển được yêu cầu tới PH-06. Hệ thống sẽ thử lại."; tác vụ `DONE`. Bước 3 tác vụ `ERASE` `REFUSED` có nêu căn cứ.

  @TC-09-102 @P1 @Dương @Bảo @mật
  Kịch bản: TC-09-102 Hạn chế xử lý có hiệu lực ở quyết định mục đích
    # Truy vết: FR-09-048, 019 · API-09-178, 227 · EVT-09-26 · BR-09-047 · ERR-09-104
    # Mục đích: Chứng minh khi chủ thể bị hạn chế chỉ mục đích bắt buộc theo luật còn được truy cập.
    Biết T90; yêu cầu `RESTRICT` cho CC-03; HTTT-BH có chấp thuận `MD-TRACUU-HGD`.
    Khi DS1 hoàn tất tác vụ hạn chế; PEP gọi `purpose:decide` cho CC-03.
    Và DS1 `POST /subject-requests/{id}:lift-restriction`; gọi lại.
    Thì bước 1 mục đích thường `403` ERR-09-104, `MD-LUATDINH` `200`; EVT: `dsr.restriction-changed` tới PH-06, PH-19, PH-14. Bước 2 EVT: `dsr.restriction-changed`, `allow` trở lại ở mục đích thường.
