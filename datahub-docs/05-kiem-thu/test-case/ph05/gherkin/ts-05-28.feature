# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-28
Tính năng: TS-05-28 · Ngừng khuyến nghị, thu hồi, đề xuất dùng chung

  @TC-05-110 @P2 @Dương
  Kịch bản: TC-05-110 Ngừng khuyến nghị ẩn khỏi bảng thành phần, luồng cũ vẫn chạy
    # Truy vết: FR-05-058 · API-05-085, 089 · EVT-05-10 · UI-05-15
    Biết U-T68-IA1; K-MST 3 luồng dùng.
    Thì `DEPRECATED`; catalog trả cờ ẩn; 3 luồng vẫn chạy; EVT: `kamelet.lifecycle-changed`.

  @TC-05-111 @P1 @Dương @Âm
  Kịch bản: TC-05-111 Thu hồi chặn lần phát hành kế tiếp của luồng dùng
    # Truy vết: FR-05-058 · API-05-086, 031 · ERR-05-120, 038 · EVT-05-10 · UC-05-22
    Biết U-T68-IA1; S-INT; K-MST.
    Khi `POST …:withdraw` không lý do; rồi có lý do.
    Và S-INT `POST /internal/connection-references:verify` cho luồng dùng K-MST.
    Thì bước 1 lần đầu `400` ERR-05-038; lần sau `WITHDRAWN`, EVT, chủ sở hữu 3 luồng và TO nhận cảnh báo mức cao. Bước 2 trả mục lỗi ERR-05-120 cho K-MST; luồng đang chạy không bị dừng tự động.

  @TC-05-112 @P3 @Dương
  Kịch bản: TC-05-112 Đề xuất Kamelet tỉnh thành dùng chung, PA duyệt
    # Truy vết: FR-05-060, 057 · API-05-088, 083 · EVT-05-09 · UC-05-23
    Biết U-T68-IE1; U-PA; Kamelet `APPROVED` mới của T68; ý kiến SO ghi trong đề xuất.
    Thì bản sao ở `COMMON` `SUBMITTED` rồi `APPROVED`; EVT trên `common.adapter.kamelet.published.v1`; catalog T01 có Kamelet mới.
