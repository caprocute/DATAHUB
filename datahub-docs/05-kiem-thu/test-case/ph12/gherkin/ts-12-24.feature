# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-24
Tính năng: TS-12-24 · Vòng đời token, JWKS và thu hồi truy cập tức thời

  @TC-12-072 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-12-072 Refresh xoay vòng, dùng lại thì thu cả họ token
    # Truy vết: FR-12-038 · UC-12-16 · API-12-074, 077 · BR-12-026 · ERR-12-115 · SEC-29 · LGC-IAM-005
    Biết U-T68-VW đã đăng nhập, `RT1`.
    Khi đổi `RT1` lấy `RT2`; dùng lại `RT1`.
    Và dùng `RT2`.
    Thì dùng lại `RT1` ERR-12-115; `RT2` cũng vô hiệu (thu cả họ); cảnh báo `refresh-reuse` tới SO ≤ 60 giây.

  @TC-12-073 @P1 @Dương @Âm
  Kịch bản: TC-12-073 Xoay khóa ký 90 ngày không gián đoạn
    # Truy vết: FR-12-039 · UC-12-27 · UI-12-19 · API-12-075 · BR-12-027 · NFR-12-018 · SEC-25
    Biết realm `dh-t68`; token ký bằng khóa cũ; đồng hồ nhảy 90 ngày.
    Khi chạy xoay; `GET …/certs`; xác minh token cũ và token mới.
    Và sau 1 ngày xem JWKS; thử xoay khẩn một người.
    Thì JWKS có cả khóa cũ và mới, token cũ vẫn xác minh được; sau 1 ngày khóa cũ rút; xoay khẩn cần người duyệt thứ hai (từ chối nếu thiếu); không có khóa riêng trong log.

  @TC-12-074 @P1 @Dương
  Kịch bản: TC-12-074 Thu hồi truy cập tức thời ≤ 60 giây tại cổng
    # Truy vết: FR-12-040 · UC-12-28 · UI-12-02 · API-12-018, 079 · BR-12-028 · NFR-12-005 · ERR-12-116 · LGC-IAM-005
    Biết U-T68-IE gọi API mỗi giây; U-T68-SO; APISIX 3 bản sao.
    Khi SO `POST /users/{id}:revoke-access` kèm lý do (đã bước lên).
    Và gọi đến khi bị từ chối; `GET /revocations`.
    Thì từ chối ở mọi bản sao ≤ 60 giây (ERR-12-116); mục thu hồi xuất hiện ở danh sách chặn; KT: có.

  @TC-12-075 @P1 @Âm
  Kịch bản: TC-12-075 Thu hồi thiếu lý do, tự thu hồi mình
    # Truy vết: FR-12-040 · BR-12-028, BR-12-033 · API-12-018 · ERR-12-014 · ERR-12-013
    Biết U-T68-SO.
    Khi `:revoke-access` thiếu `reason`.
    Và SO thu hồi chính mình.
    Thì bước 1 `400` ERR-12-014; bước 2 `403` ERR-12-013.
