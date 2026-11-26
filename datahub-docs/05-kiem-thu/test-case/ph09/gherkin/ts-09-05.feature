# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-05
Tính năng: TS-09-05 · Mức phân loại của hợp đồng

  @TC-09-014 @P1 @Dương
  Kịch bản: TC-09-014 Mức hợp đồng bằng mức cao nhất, tạm thời khi còn trường chưa xác nhận
    # Truy vết: FR-09-006 · API-09-027, 028, 029 · BR-09-004, 001 · EVT-09-03
    # Mục đích: Chứng minh mức hợp đồng theo trường cao nhất và `provisional` theo BR-09-001.
    Biết T90; API-HGD có 6 trường (5 `CONFIRMED` mức thấp nhất `INTERNAL`, 1 chưa phân loại); S-T90-REG.
    Khi `GET /contract-levels/API/API-HGD`.
    Và SO xác nhận trường còn lại là `RESTRICTED`; S-T90-REG `POST /contract-levels:recompute`.
    Và `GET /contract-levels/API/API-HGD`.
    Thì bước 1 `level = SENSITIVE`, `provisional = true`. Bước 3 `level = RESTRICTED`, `provisional = false`. EVT: `contract-level.changed` đúng một lần với mức cũ và mới.

  @TC-09-015 @P2 @Âm
  Kịch bản: TC-09-015 Hợp đồng không tự hạ mức khi trường bị hạ chưa duyệt đủ
    # Truy vết: FR-09-006 · API-09-028 · BR-09-004, 002
    # Mục đích: Chứng minh đề xuất chưa xác nhận không làm đổi mức hợp đồng.
    Biết T90; API-HGD mức `SENSITIVE` do `soTaiKhoan`; đề xuất hạ mức ở `PROPOSED`.
    Khi `GET /contract-levels/API/API-HGD` khi đề xuất hạ còn `PROPOSED`.
    Và TA xác nhận đề xuất; gọi lại.
    Thì bước 1 `SENSITIVE`, không `EVT`. Bước 2 mức mới theo trường cao nhất còn lại, EVT: `contract-level.changed`.

  @TC-09-016 @P2 @Hiệu @năng
  Kịch bản: TC-09-016 Tính lại 3.000 hợp đồng ≤ 60 giây, mỗi hợp đồng ≤ 5 giây
    # Truy vết: FR-09-006 · NFR-09-010 · API-09-029
    # Mục đích: Đo NFR-09-010.
    Biết T97 200 HTTT, 3.000 hợp đồng, 50.000 phần tử.
    Khi đổi mức một phần tử dùng chung 3.000 hợp đồng; đo thời gian đến khi `EVT-09-03` cuối.
    Và gọi `POST /contract-levels:recompute` cho một hợp đồng 200 trường.
    Thì bước 1 ≤ 60 giây; bước 2 ≤ 5 giây.
