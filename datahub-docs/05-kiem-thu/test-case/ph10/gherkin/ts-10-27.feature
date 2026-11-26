# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-27
Tính năng: TS-10-27 · Xuất và nhập khai báo

  @TC-10-114 @P2 @Dương @Bảo @mật
  Kịch bản: TC-10-114 Xuất khai báo dự án không chứa bí mật
    # Truy vết: FR-10-070 · API-10-074 · BR-10-027 · NFR-10-016 · UC-10-28
    Biết U-T68-VW; P-DKKD; khóa ký thử có mồi.
    Khi `POST /exports` với `projectCode = dang-ky-kinh-doanh`.
    Thì `200` tệp YAML `kind: EventManifest`, `apiVersion: event.datahub.vn/v1` gồm dự án, 4 topic, lược đồ `ENABLED`, `DEPRECATED`, bên phát, bên nhận, publication, subscription; không có khóa ký, `clientId` nội bộ. Mồi sạch.

  @TC-10-115 @P3 @Dương @Âm
  Kịch bản: TC-10-115 Nhập khai báo có xem trước, viết lại tiền tố, không tạo ACTIVE
    # Truy vết: FR-10-071 · API-10-075, 110, 111 · UI-10-19 · ERR-10-040, 050 · BR-10-032
    Biết U-T90-IE ở T90; F-MAN; tệp hỏng; T90 không có `HT-THUE`.
    Khi tải F-MAN với `rewriteTenantPrefix = true`; xem `GET /imports/{jobCode}`.
    Và `:apply`.
    Và tải tệp sai `apiVersion`; tải lại F-MAN khi T90 không có `HT-THUE`.
    Và tạo tác vụ mới rồi hủy bằng `POST /imports/{jobCode}:cancel` (API-10-121 theo FRS 0.3).
    Thì bước 1 `202`, tác vụ `PREVIEW`, tên topic viết thành `t90.…`, mỗi dòng có `changeKind`. Bước 2 topic `DRAFT`, `PENDING_APPROVAL`; không đối tượng nào `ACTIVE`. Bước 3 `422` ERR-10-040; `422` ERR-10-050. Bước 4 tác vụ `CANCELLED`.
