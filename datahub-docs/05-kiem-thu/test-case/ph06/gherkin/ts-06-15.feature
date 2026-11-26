# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-15
Tính năng: TS-06-15 · Quy tắc sống sót, xem trước tác động và áp lại

  @TC-06-068 @P1 @Dương @Âm
  Kịch bản: TC-06-068 Cấu hình, duyệt quy tắc sống sót và chặn sai
    # Truy vết: FR-06-033 · BR-06-003, 004 · API-06-051, 052, 053, 110, 111 · ERR-06-005, 013, 022 · PERM-06-config
    # Mục đích: Chứng minh cấu hình `SurvivorshipStrategy` theo thuộc tính, có căn cứ, bốn mắt, theo FR-06-033.
    Biết CITIZEN ACTIVE; DS1, DA1.
    Khi `PUT .../survivorship-rules` đặt `dateOfBirth` `NATIONAL_AUTHORITY`, `phone` `MOST_RECENT`, `address` `SOURCE_PRIORITY`.
    Và `submit`, DS1 tự `approve`, rồi DA1 `approve`.
    Và `PUT` đặt `dateOfBirth` `MOST_FREQUENT`.
    Thì bước 1 `200`. Bước 2 DS1 `403` ERR-06-005; DA1 `200` ACTIVE. Bước 3 `422` ERR-06-022 (thuộc tính thẩm quyền quốc gia chỉ `NATIONAL_AUTHORITY`). Thiếu căn cứ `422` ERR-06-013. KT: có.
    # Hậu điều kiện: Quy tắc sống sót ACTIVE.

  @TC-06-069 @P1 @Dương
  Kịch bản: TC-06-069 Kết quả của từng chiến lược sống sót
    # Truy vết: FR-06-034, 033 · BR-06-003, 009, 029
    # Mục đích: Chứng minh mỗi chiến lược chọn đúng giá trị và đúng nguồn ở cấp thuộc tính.
    Biết ba nguồn gửi `phone` khác nhau tại các thời điểm, độ đầy đủ khác nhau; bảng ưu tiên prio-approve.
    Khi chạy bảng tham số: `NATIONAL_AUTHORITY`, `MANUAL_OVERRIDE`, `SOURCE_PRIORITY`, `MOST_RECENT`, `MOST_COMPLETE`, `MOST_FREQUENT`, `FIRST_VALUE` trên cùng bộ ba giá trị.
    Thì mỗi chiến lược trả đúng giá trị kỳ vọng ghi trong bảng ca; `QG-DANCU` thắng mọi `NATIONAL_AUTHORITY`; hòa thì theo `SOURCE_PRIORITY` rồi `MOST_RECENT`; lineage ghi chiến lược đã dùng.
    # Hậu điều kiện: Không dữ liệu.

  @TC-06-070 @P2 @Dương
  Kịch bản: TC-06-070 Xem trước tác động và áp lại hàng loạt
    # Truy vết: FR-06-042 · BR-06-004, 005 · API-06-054, 055 · PERM-06-approve
    # Mục đích: Chứng minh áp lại tính trước số bản ghi đổi và có bốn mắt, theo FR-06-042.
    Biết T90 có 5.000 bản ghi vàng; đổi `phone` sang `MOST_FREQUENT` (đã duyệt).
    Khi `POST .../survivorship-rules:impact`.
    Và DS1 `:reapply`; DA1 duyệt; chờ job.
    Thì bước 1 báo số bản ghi, thuộc tính sẽ đổi, mẫu trước-sau, chưa đổi dữ liệu. Bước 2 job `SURVIVORSHIP_REAPPLY` `SUCCEEDED`, số bản ghi đổi bằng ước tính, mỗi bản ghi có ảnh chụp, EVT-06-02 mỗi bản ghi đổi.
    # Hậu điều kiện: Bản ghi vàng theo quy tắc mới.

  @TC-06-071 @P2 @Âm
  Kịch bản: TC-06-071 Áp lại tự duyệt và job trùng
    # Truy vết: FR-06-042 · API-06-055 · ERR-06-005, 025
    # Mục đích: Chứng minh áp lại chặn tự duyệt và hai lượt đồng thời, theo FR-06-042.
    Biết như reapply.
    Khi DS1 tự duyệt `:reapply`.
    Và gọi `:reapply` khi một job `SURVIVORSHIP_REAPPLY` đang chạy.
    Thì bước 1 `403` ERR-06-005. Bước 2 `409` ERR-06-025.
    # Hậu điều kiện: Không đổi.
