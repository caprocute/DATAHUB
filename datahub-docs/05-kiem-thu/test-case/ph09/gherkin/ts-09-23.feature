# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-23
Tính năng: TS-09-23 · Giả danh hóa giá trị bằng HMAC hoặc token

  @TC-09-078 @P1 @Dương
  Kịch bản: TC-09-078 Cùng giá trị cùng miền cùng khóa cho cùng bí danh, khác miền khác bí danh
    # Truy vết: FR-09-031, 032 · API-09-230 · BR-09-028, 029, 031 · NFR-09-011
    # Mục đích: Chứng minh tính nhất quán và không nối được giữa hai mục đích.
    Biết T90; S-T90-PSEUDO; `PD-HGD`, `PD-TK`; lô 500 CCCD giả trong đó 100 trùng.
    Khi S-T90-PSEUDO `POST /privacy/v1/pseudonyms:issue` lô 500 giá trị cho `PD-HGD`, hai lần.
    Và gửi cùng lô cho `PD-TK`.
    Và gửi 1 giá trị rỗng.
    Thì bước 1 hai lần cho cùng bí danh, 100 giá trị trùng cho 100 bí danh trùng. Bước 2 không bí danh nào trùng bước 1. Bước 3 giữ rỗng, không sinh bí danh. Không bảng ánh xạ nào trong `ph09_privacy.*` (BR-09-030). Tập chứa bí danh vẫn phải thuộc một hoạt động xử lý (BR-09-031). Mồi sạch.

  @TC-09-079 @P1 @Dương @Âm
  Kịch bản: TC-09-079 Token hóa đảo ngược và HMAC không đảo ngược
    # Truy vết: FR-09-032, 033 · API-09-230 · BR-09-030 · ERR-09-048
    # Mục đích: Chứng minh chỉ miền token đảo ngược được, đường giải qua OpenBao transit có kiểm soát.
    Biết T90; `PD-TOKEN` (token), `PD-HGD` (HMAC); U-T90-SO.
    Khi cấp token cho 10 giá trị bằng `PD-TOKEN`.
    Và đề nghị khôi phục 10 token của `PD-HGD`.
    Thì token khác nhau cho cùng giá trị không xảy ra (cùng khóa cho cùng token). Bước 2 `422` ERR-09-048 "Miền PD-HGD dùng HMAC không đảo ngược, không khôi phục được giá trị gốc."

  @TC-09-080 @P2 @Âm
  Kịch bản: TC-09-080 OpenBao ngừng hoặc miền không có khóa hoạt động
    # Truy vết: FR-09-032 · API-09-230 · ERR-09-108, 109
    # Mục đích: Chứng minh không trả giá trị thô khi không giả danh hóa được.
    Biết T94; `PD-HGD` có khóa; `PD-RONG` chưa có khóa.
    Khi gọi `pseudonyms:issue` khi OpenBao ngừng.
    Và gọi cho `PD-RONG`.
    Thì bước 1 `503` ERR-09-108. Bước 2 `422` ERR-09-109. Không trả giá trị thô.

  @TC-09-081 @P2 @Hiệu @năng
  Kịch bản: TC-09-081 HMAC ≥ 2.000 giá trị mỗi giây mỗi bản sao, token ≥ 500 giá trị mỗi giây
    # Truy vết: NFR-09-011 · API-09-230
    # Mục đích: Đo NFR-09-011.
    Biết T97; khóa đã đệm trong bộ nhớ 5 phút.
    Khi k6 lô 500 giá trị HMAC trên 1 bản sao 5 phút; lô 500 token.
    Thì HMAC ≥ 2.000 giá trị mỗi giây; token ≥ 500 giá trị mỗi giây; nhất quán bí danh 100 %.
