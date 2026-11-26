# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-27
Tính năng: TS-05-27 · Kamelet của tỉnh: soạn, kiểm tra tĩnh, duyệt

  @TC-05-105 @P2 @Dương
  Kịch bản: TC-05-105 Danh mục và chi tiết Kamelet
    # Truy vết: FR-05-054, 055 · API-05-076, 077, 078 · UI-05-14, 15
    Biết U-T68-VW.
    Thì danh sách có K-MST với phạm vi, phiên bản, nơi dùng = 3; mặc định không có `WITHDRAWN`. Chi tiết có tham số, YAML, kết quả kiểm tra tĩnh, phụ thuộc thành phần.

  @TC-05-106 @P1 @Dương
  Kịch bản: TC-05-106 Soạn Kamelet hợp lệ, kiểm tra tĩnh đạt, gửi, IA duyệt
    # Truy vết: FR-05-056, 057 · API-05-079, 081, 082, 083 · UI-05-16, 17 · EVT-05-09 · UC-05-21 · LGC-TOOL-027
    Biết U-T68-IE1, U-T68-IA1; F-KAM-OK.
    Khi Ở UI-05-16 dán F-KAM-OK, bấm "Kiểm tra tĩnh", "Gửi duyệt".
    Và IA1 duyệt ở UI-05-17.
    Thì bước 1 `violations` rỗng (có thể có cảnh báo KR-12, KR-13); `SUBMITTED`. Bước 2 `APPROVED`; EVT: `kamelet.published` trên `t68.adapter.kamelet.published.v1`; có trong catalog T68, không có ở T01.

  @TC-05-107 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-107 Kiểm tra tĩnh chặn ngôn ngữ kịch bản, #class, URI trực tiếp, bí mật cứng
    # Truy vết: FR-05-056 · API-05-081, 082 · ERR-05-020, 021 · UI-05-16
    Biết U-T68-IE1; F-KAM-BAD và các biến thể.
    Thì mỗi bản có vi phạm đúng quy tắc: KR-04, KR-04, KR-05, KR-07, KR-06, KR-14 (ERR-05-020), KR-08 (ERR-05-021), KR-10 (ERR-05-020); mỗi vi phạm có dòng, cột, thông điệp tiếng Việt; gửi duyệt `422`.

  @TC-05-108 @P2 @Âm
  Kịch bản: TC-05-108 Tên trùng Kamelet nền; phiên bản phụ không tương thích
    # Truy vết: FR-05-056 · API-05-079, 081 · ERR-05-002, 022
    Biết U-T68-IE1; K-MST 1.0.0.
    Khi `POST /kamelets` tên `dh-http-sink`.
    Và tạo K-MST 1.1.0 bỏ một tham số.
    Thì bước 1 `409` ERR-05-002. Bước 2 `422` ERR-05-022 (KR-09).

  @TC-05-109 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-109 Tự duyệt Kamelet; tỉnh ghi lên Kamelet COMMON
    # Truy vết: FR-05-057 · API-05-080, 083 · ERR-05-011, 040 · BR-05-009
    Biết U-T68-IA2 gửi Kamelet; U-T68-IE1; Kamelet `COMMON` `dh-dm-tra-cuu-action`.
    Khi IA2 `POST …:approve` Kamelet của mình.
    Và IE1 `PUT /kamelets/dh-dm-tra-cuu-action/versions/1.0.0`.
    Thì bước 1 `403` ERR-05-011. Bước 2 `403` ERR-05-040.

  @TC-05-155 @P2 @Âm
  Kịch bản: TC-05-155 Kamelet đã thu hồi ẩn khỏi danh mục; Kamelet tỉnh khác không xem được
    # Truy vết: FR-05-054, 055 · API-05-076, 077 · ERR-05-001
    Biết U-T68-VW; U-T01-IE; K-MST; Kamelet `WITHDRAWN` `dh-t68-cu-action`.
    Khi VW `GET /kamelets`; `GET /kamelets?status=WITHDRAWN`.
    Và U-T01-IE `GET /kamelets/dh-t68-tra-cuu-mst-action`.
    Thì bước 1 lần một không có `dh-t68-cu-action`, lần hai có. Bước 2 404-ẩn.
