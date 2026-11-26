# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-23
Tính năng: TS-10-23 · Dashboard và sơ đồ kết nối

  @TC-10-102 @P1 @Dương @Âm
  Kịch bản: TC-10-102 Bốn thẻ đếm và khối lag, DLQ trên dashboard
    # Truy vết: FR-10-057 · API-10-066 · UI-10-01 · ERR-10-001, 049 · UC-10-21 · LGC-HUB-001, 002, 003, 004, 005, 006
    Biết U-T68-VW; dữ liệu mục 2.3.
    Khi `GET /dashboard`; `GET /dashboard?projectCode=dang-ky-kinh-doanh`.
    Và mở UI-10-01, bấm thẻ "Bên phát"; bấm liên kết "Tài nguyên cụm Kafka (PH-13)".
    Và dừng PH-13.
    Và `GET /dashboard?projectCode=khong-co`; `GET /dashboard?projectCode=dang-ky-kinh-doanh` bằng U-T01-IE.
    Thì bước 1 số publisher, subscriber, project, topic khớp đếm trực tiếp ở CSDL, có phân rã theo trạng thái; khối lag theo `alertState`, DLQ `NEW`. Bước 2 mở UI-10-09 đã lọc; liên kết mở bảng chỉ số cụm của PH-13. Bước 3 khối lưu lượng ẩn kèm thông báo, các khối khác vẫn hiện. Bước 4 404-ẩn cả hai (không lộ dự án T68).

  @TC-10-103 @P1 @Dương
  Kịch bản: TC-10-103 Sơ đồ kết nối lọc theo dự án và phủ trạng thái
    # Truy vết: FR-10-058 · API-10-007 · UI-10-14, 03 · UC-10-21 · LGC-HUB-007
    Biết U-T68-VW; P-DKKD.
    Khi `GET /graph?projectCode=dang-ky-kinh-doanh&overlay=LAG`.
    Và mở UI-10-14 `?du-an=dang-ky-kinh-doanh`, đổi `overlay` sang `DLQ`, `TRAFFIC`; bấm một cạnh.
    Và `GET /graph?systemCode=HT-DKKD`.
    Thì bước 1 `nodes[]` ba lớp (bên phát, topic, bên nhận), `edges[]` có `deliveryMode`, `lagSeconds`; `HT-DKKD` vừa phát vừa nhận hiện một nút có liên kết đánh dấu. Bước 2 cạnh SUB-PUSH có huy hiệu số mục DLQ `NEW`; bấm cạnh mở UI-10-12; không có thao tác sửa nào trên sơ đồ (PTN-07 chỉ xem). Bước 3 chỉ lân cận một bước quanh `HT-DKKD`.

  @TC-10-104 @P2 @Âm @Bảo @mật
  Kịch bản: TC-10-104 Sơ đồ quá số nút, tham số sai, không lộ tenant khác
    # Truy vết: FR-10-058, 064 · API-10-007 · ERR-10-049
    Biết T97 có 400 nút; U-T68-VW; T01 có bên nhận nhận từ topic trùng tên.
    Khi Ở T97 `GET /graph` không lọc.
    Và `overlay=CPU`.
    Và U-T68-VW `GET /graph?systemCode=HT-THUE`.
    Thì bước 1, 2 `400` ERR-10-049, gợi ý lọc theo dự án. Bước 3 không có nút, cạnh nào của T01.
