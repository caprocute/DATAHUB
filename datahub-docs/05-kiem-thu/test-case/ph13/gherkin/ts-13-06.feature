# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-06
Tính năng: TS-13-06 · Neo băm ký hằng giờ và sao lô sang WORM

  @TC-13-020 @P1 @Dương
  Kịch bản: TC-13-020 Neo giờ chẵn được ký, lưu bảng, WORM và SIEM
    # Truy vết: FR-13-012 · UC-13-06 · BR-13-013 · API-13-080, 081 · UI-13-14 · EVT-13-06
    Biết F-AUD-1K; F-SIM-SIEM bật; `13.audit.anchor-interval-minutes = 60`.
    Khi chờ đến giờ chẵn (hoặc kích bộ neo ở SIT).
    Và `GET /anchors`, `GET /anchors/{anchorId}`; kiểm chữ ký bằng khóa công khai.
    Thì neo có `seq` cuối, băm, chữ ký hợp lệ; có bản ở bảng neo, bucket WORM và SIEM; EVT: `audit.anchor-created`.

  @TC-13-021 @P1 @Âm
  Kịch bản: TC-13-021 Không ký được neo tại OpenBao
    # Truy vết: FR-13-012 · ERR-13-107 · BR-13-013 · NFR-13-023
    Biết tắt OpenBao 90 phút.
    Khi tắt OpenBao; chờ qua một giờ chẵn; bật lại.
    Thì ERR-13-107, cảnh báo `WARNING`; bản ghi vẫn vào chuỗi; sau khi bật lại neo bù được ký, không bỏ sót giờ nào; không khóa nào rời OpenBao.

  @TC-13-022 @P1 @Dương @Bảo @mật
  Kịch bản: TC-13-022 Sao lô sang WORM và không xóa được
    # Truy vết: FR-13-013 · BR-13-013, 020 · API-13-087 · UI-13-18 · NFR-13-023
    Biết F-AUD-1K; F-WORM.
    Khi chờ 5 phút (`13.audit.worm-batch-minutes`) hoặc kích bộ sao.
    Và dùng tài khoản ghi của bộ sao xóa đối tượng, rút ngắn thời hạn Object Lock.
    Thì bước 1: lô có tổng kiểm đúng; `GET /chain-status` hiện lô mới nhất. Bước 2: bị từ chối; Object Lock chỉ cho kéo dài.

  @TC-13-023 @P1 @Âm @Khả @dụng
  Kịch bản: TC-13-023 Kho WORM ngừng, lô xếp hàng và sao bù
    # Truy vết: FR-13-013, 016 · ERR-13-108 · NFR-13-011 · UI-13-18
    Biết tắt F-WORM 30 phút.
    Khi tắt WORM; ghi 500 bản ghi; bật lại.
    Thì ERR-13-108 `WARNING`; chuỗi vẫn ghi; sau khi bật lại tất cả lô được sao đủ, đối chiếu khớp; UI-13-18 hiện độ trễ sao.
