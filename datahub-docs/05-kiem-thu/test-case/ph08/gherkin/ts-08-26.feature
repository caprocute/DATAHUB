# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-26
Tính năng: TS-08-26 · Xuất, ký số, phân phối báo cáo và đẩy chỉ số sang PH-16, PH-13

  @TC-08-120 @P2 @Dương
  Kịch bản: TC-08-120 Xuất báo cáo PDF, XLSX và đối chiếu contentHash
    # Truy vết: FR-08-055 · API-08-116, 117 · UI-08-18 · BR-08-009 · NFR-08-012
    Biết báo cáo `PUBLISHED` 200 đối tượng; U-T90-DS1, U-T90-VW.
    Khi DS1 `POST /reports/{code}/exports` `{format: PDF}`
    Và `GET /reports/{code}/exports/{id}` đến `READY`
    Và `format = XLSX`
    Và `format = JSON`, băm nội dung
    Thì `202` rồi `fileUrl`; PDF và XLSX mở được, số liệu trùng báo cáo; băm JSON bằng `contentHash`. VW tải được bản đã xuất của báo cáo `PUBLISHED`.

  @TC-08-121 @P2 @Dương @Âm
  Kịch bản: TC-08-121 Ký số báo cáo và ký thất bại
    # Truy vết: FR-08-055 · API-08-118 · UI-08-18 · ERR-00-403 · ERR-08-048
    Biết báo cáo `PUBLISHED`; `sign-sim`; DA1, DS1.
    Khi DA1 `POST /reports/{code}:sign`
    Và `sign-sim` ngừng, DA1 `:sign` lại
    Và DS1 `:sign`
    Thì bước 1 `200`, `signatureRef`, nội dung báo cáo không đổi. Bước 2 `422` ERR-08-048. Bước 3 `403` ERR-00-403.

  @TC-08-122 @P3 @Dương @Âm
  Kịch bản: TC-08-122 Đăng ký nhận báo cáo và phân phối qua PH-13
    # Truy vết: FR-08-056 · API-08-119, 120, 121 · UI-08-18 · EVT-08-11 · ERR-08-114 · ERR-08-032
    Biết báo cáo sắp công bố; DO1 (ORG-CA); `notif-sim`.
    Khi DO1 `POST /report-subscriptions` `{scope: ORGANIZATION, orgId: ORG-CA, channel: IN_APP}`
    Và DO1 đăng ký `orgId: ORG-TC`
    Và công bố báo cáo
    Và tắt `notif-sim`, công bố báo cáo khác
    Và DO1 `DELETE /report-subscriptions/{id}`
    Thì bước 1 `201`. Bước 2 `403` ERR-08-032. Bước 3 `distribution[]` ghi đã gửi. Bước 4 biên bản "chưa gửi" ERR-08-114, thử lại. Bước 5 hủy được.

  @TC-08-123 @P2 @Dương @Âm
  Kịch bản: TC-08-123 Đẩy KPI sang PH-16, không giao trùng
    # Truy vết: FR-08-057 · API-08-122 · BR-08-009 · EVT-08-14 · ERR-08-113
    Biết `kpi-sim` (PH-16); `S-T90-PH16` scope `dq.read`.
    Khi chạy lần đo `FULL` thành công
    Và `GET /kpi/snapshots`
    Và dừng `kpi-sim` 25 giờ rồi bật lại
    Và chạy lần đo `INCREMENTAL`
    Thì bước 1 EVT: `kpi.published` (EVT-08-14) kèm `kpiSchemaVersion`. Bước 2 liệt kê KPI. Bước 3 quá 24 giờ có ERR-08-113 cảnh báo vận hành; sau khi bật lại giao đủ, mỗi `eventId` đúng một lần. Bước 4 không phát KPI.
