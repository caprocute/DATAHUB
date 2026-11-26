# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-15
Tính năng: TS-09-15 · Chặn kích hoạt hợp đồng mức Nhạy cảm

  @TC-09-051 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-051 Kích hoạt hợp đồng `SENSITIVE` khi chưa có chấp thuận bị chặn
    # Truy vết: FR-09-022 · API-09-088, 089 · ERR-09-035, 023 · BR-09-019, 008 · UI-09-09
    # Mục đích: Chứng minh kiểm điều kiện kích hoạt theo SEC-37.
    Biết T90; API-HGD mức `SENSITIVE` chưa có chấp thuận; 1 trường DLCN chưa thuộc hoạt động; S-T90-REG (vai PH-02).
    Khi S-T90-REG `POST /activation-checks` cho API-HGD.
    Và `GET /activation-checks:blocked`.
    Thì bước 1 `422` ERR-09-035 nêu "cần mục đích và chấp thuận của chủ quản" và ERR-09-023 nêu số trường chưa thuộc hoạt động; PH-02 không chuyển `ACTIVE`. Bước 2 liệt kê API-HGD kèm lý do chặn.

  @TC-09-052 @P1 @Dương
  Kịch bản: TC-09-052 Kích hoạt được sau khi có chấp thuận và hoạt động
    # Truy vết: FR-09-022 · API-09-088 · BR-09-019, 008
    # Mục đích: Chứng minh điều kiện được gỡ khi đủ chấp thuận và hoạt động xử lý.
    Biết T90; sau ca dec-approve-cond và ropa-link.
    Khi S-T90-REG `POST /activation-checks` cho API-HGD.
    Thì `200` `allowed = true`, không còn trong `activation-checks:blocked`.

  @TC-09-053 @P2 @Âm
  Kịch bản: TC-09-053 Hợp đồng mức tạm thời vẫn bị chặn
    # Truy vết: FR-09-022 · API-09-088 · BR-09-001 · ERR-09-035
    # Mục đích: Chứng minh mức tạm thời `SENSITIVE` (BR-09-001) chưa cho kích hoạt khi thiếu chấp thuận.
    Biết T90; API-MOI có trường chưa phân loại; có chấp thuận cho API-HGD khác.
    Khi S-T90-REG `POST /activation-checks` cho API-MOI.
    Thì `422` ERR-09-035; sau khi xác nhận trường là `INTERNAL` thì lượt kiểm lại `200`.
