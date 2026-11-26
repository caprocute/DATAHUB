# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-33
Tính năng: TS-09-33 · Vi phạm dữ liệu cá nhân và đồng hồ 72 giờ

  @TC-09-112 @P1 @Dương
  Kịch bản: TC-09-112 Ghi nhận vi phạm có thời điểm phát hiện, đánh giá mức, đồng hồ bắt đầu
    # Truy vết: FR-09-058, 059 · API-09-203, 206, 207 · UI-09-19 · EVT-09-30 · BR-09-054 · PERM-09-breach
    # Mục đích: Chứng minh đồng hồ tính từ `detectedAt` đã ghi nhận và hồ sơ không chứa DLCN rõ (BR-09-056).
    Biết T95 đồng hồ giả; U-T90-TO (ghi nhận), U-T90-SO.
    Khi TO `POST /breaches` có `detectedAt`, mô tả, 120 chủ thể (băm), loại `HEALTH`.
    Và SO `:assess` mức `HIGH`.
    Và `GET /breaches/{id}/clock`.
    Thì bước 1 `201` `REPORTED`, EVT: `breach.recorded`. Bước 2 `ASSESSING` rồi `NOTIFYING`. Bước 3 còn 72 giờ trừ thời gian đã trôi; sửa mô tả không đặt lại đồng hồ. Hồ sơ chỉ có số lượng, loại, băm.

  @TC-09-113 @P1 @Âm
  Kịch bản: TC-09-113 Thiếu thời điểm phát hiện, không thông báo chủ thể không căn cứ, đóng khi còn nghĩa vụ, TO không đóng được
    # Truy vết: FR-09-058, 059, 060 · API-09-203, 208, 213 · ERR-09-075, 077, 076, 006 · BR-09-055
    # Mục đích: Chứng minh các ràng buộc thông báo và đóng hồ sơ (BR-09-055, BR-09-057).
    Biết T95; vụ việc BR-01 `NOTIFYING` chưa gửi A05; U-T90-TO, U-T90-SO.
    Khi TO `POST /breaches` không `detectedAt`.
    Và SO soạn thông báo `SUBJECT` không nêu căn cứ miễn trừ khi chọn không thông báo.
    Và SO `:close` khi chưa gửi A05.
    Và TO `:close`.
    Thì bước 1 `422` ERR-09-075. Bước 2 `422` ERR-09-077. Bước 3 `409` ERR-09-076 "Còn nghĩa vụ thông báo chưa hoàn tất, chưa đóng được hồ sơ." Bước 4 ERR-00-403 (TO không đóng được).

  @TC-09-114 @P1 @Dương @Biên
  Kịch bản: TC-09-114 Cảnh báo ở 24, 48, 60 giờ, thông báo A05 trước 72 giờ
    # Truy vết: FR-09-059 · API-09-207, 208, 209, 239 · EVT-09-31, 32 · NFR-09-017 · BR-09-054, 055
    # Mục đích: Chứng minh cảnh báo đúng mốc (±1 phút) và có bằng chứng thông báo trước 72 giờ.
    Biết T95 đồng hồ giả; BR-01 `detectedAt` = T0; `09.breach.alert-hours = 24, 48, 60`.
    Khi tiến đồng hồ đến T0+24 giờ, +48 giờ, +60 giờ.
    Và Ở T0+70 giờ SO soạn thông báo A05, `:mark-sent`; `GET /breaches/{id}/notifications` (API-09-239).
    Và thử tạm dừng hoặc đặt lại đồng hồ.
    Thì bước 1 EVT: `breach.deadline-near` đúng ở ba mốc cho SO, TA, DA, sai số ≤ 1 phút. Bước 2 `SENT`, EVT: `breach.notified`, `BreachStatus = NOTIFIED`. Bước 3 không có đường tạm dừng hay đặt lại; đồng hồ chỉ dừng khi thông báo A05 đã `SENT` (BR-09-054). Bước 2 danh sách thông báo có bản A05 `SENT`.

  @TC-09-115 @P2 @Dương
  Kịch bản: TC-09-115 Khắc phục, bài học, đóng hồ sơ, tải hồ sơ
    # Truy vết: FR-09-060 · API-09-211, 212, 213, 214, 240 · UI-09-19
    # Mục đích: Chứng minh hồ sơ có biện pháp, bài học và đóng đúng trạng thái.
    Biết T90; vụ việc `NOTIFIED`; U-T90-SO.
    Khi SO ghi biện pháp khắc phục và bài học; `:close`; `GET .../dossier`.
    Và `GET /breaches/{id}/actions`.
    Thì `CLOSED`, hồ sơ có dòng thời gian, thông báo, khắc phục, bài học; KT: có; không giá trị DLCN rõ. Bước 2 `200`, liệt kê biện pháp khắc phục kèm người phụ trách, hạn và trạng thái (API-09-240).
