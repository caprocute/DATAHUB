# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-11
Tính năng: TS-01-11 · Trả bổ sung và nộp lại hồ sơ

  @TC-01-047 @P1 @Dương
  Kịch bản: TC-01-047 Trả bổ sung rồi nộp lại, giữ kết luận bước không đổi
    # Truy vết: FR-01-017, 012 · UC-01-11 · API-01-031, 023 · UI-01-02, 06 · BR-01-032 · EVT-01-02, 03.
    Biết `HT-HOTICH-SS` có kết luận kỹ thuật đạt; IE chưa xong; SO được giao.
    Khi SO `POST …:return` với lý do "thiếu phương án mã hóa".
    Và OR1 sửa phần ATTT, `:validate`, `:submit`.
    Và `GET …/progress`.
    Thì bước 1: `200`, `DRAFT`, `returnReason`, nội dung nguyên vẹn, đồng hồ dừng. Bước 2: `revisionNo` tăng; bước `TECHNICAL` giữ kết luận (dữ liệu kỹ thuật không đổi), bước `SECURITY` mở lại. EVT: `EVT-01-02`, `EVT-01-03`, `EVT-01-01`.

  @TC-01-048 @P2 @Âm
  Kịch bản: TC-01-048 Trả bổ sung sai: thiếu lý do, sai người, sai giai đoạn
    # Truy vết: FR-01-017 · API-01-031 · ERR-01-020, 033.
    Biết `HT-HOTICH-SS`; `HT-HOTICH` DRAFT; U-T68-IE, U-T68-OR2.
    Khi IE `:return` không lý do.
    Và OR2 `:return`.
    Và IE `:return` vào `HT-HOTICH` (DRAFT).
    Thì `400` ERR-01-033; `403-PQ`; `409` ERR-01-020.
