# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-29
Tính năng: TS-08-29 · Phân quyền theo ma trận PERM-08, bốn mắt và tài khoản máy

  @TC-08-134 @P1 @Bảo @mật
  Kịch bản: TC-08-134 Ma trận PERM-08 theo vai trò
    # Truy vết: FR-08-001 · FR-08-017 · FR-08-050 · FR-08-060 · ERR-00-401 · ERR-00-403 · PERM-08-read, asset, approve, run, finding-read, remediate, report, export, config, audit-read · ERR-08-032
    Biết người dùng T90: PA (qua `PLATFORM`), TA, TO, SO, DS1, DA1, DO1, VW, AU; ma trận ở FRS mục 3.2.
    Khi với mỗi quyền chọn một API đại diện (`GET /dashboard`, `POST /domains`, `POST …:approve`, `POST /scans`, `GET /findings`, `POST /issues/{code}:start`, `POST /reports`, `POST /findings:export`, `PUT /settings`, `GET /audit-events`)
    Và gọi bằng từng vai trò
    Và gọi không token
    Và DO1 gọi API của đối tượng ngoài ORG-CA
    Thì vai trò có ● trả `2xx`; không có quyền `403` ERR-00-403; không token `401` ERR-00-401; DO ○ ngoài tổ chức `403` ERR-08-032; VW chỉ `GET /dashboard` tổng hợp. Kết quả khớp đúng từng ô của bảng ma trận.

  @TC-08-135 @P1 @Bảo @mật @Âm
  Kịch bản: TC-08-135 Bốn mắt không có đường vòng
    # Truy vết: FR-08-017 · FR-08-021 · FR-08-040 · FR-08-053 · FR-08-039 · API-08-039, 051, 081, 112, 076 · BR-08-007 · PERM-08-approve · ERR-08-005
    Biết U-T90-TA có cả quyền soạn và duyệt (SIT); mỗi loại đối tượng (bộ quy tắc, trọng số, ngoại lệ, báo cáo, xuất lỗi) do chính người đó soạn hoặc gửi.
    Khi TA gọi duyệt cho cả năm loại
    Và DS1 (soạn) gọi duyệt
    Và thử đổi người gửi bằng cách sửa nội dung rồi gửi lại và tự duyệt
    Và DA2 (người khác) duyệt cả năm loại
    Thì bước 1, 2, 3 `403` ERR-08-005, trạng thái không đổi. Bước 4 `200`. Mọi lượt từ chối có KT: có (approve.denied).

  @TC-08-136 @P1 @Bảo @mật
  Kịch bản: TC-08-136 Scope máy dq.check, dq.read và API nội bộ
    # Truy vết: FR-08-032 · FR-08-051 · FR-08-011 · API-08-068, 106, 122, 024 · NFR-08-017 · ERR-00-403
    Biết `S-T90-PH04` (`dq.check`); `S-T90-PH16` (`dq.read`); `S-T90-HTTT-HT` (`dq.read`).
    Khi `S-T90-PH04` gọi `POST /scans` và `GET /assets`
    Và `S-T90-PH16` gọi `POST /checks:evaluate`
    Và `S-T90-PH16` gọi `GET /kpi/snapshots`
    Và gọi `POST /internal/profile-metrics` từ ngoài mạng nội bộ qua APISIX
    Thì bước 1 và 2 `403` ERR-00-403. Bước 3 `200`. Bước 4 bị từ chối vì đường dẫn `/internal` chỉ mở trong mạng nội bộ (mTLS).
