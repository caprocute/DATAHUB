# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-19
Tính năng: TS-09-19 · Áp che bản tin cho luồng PH-04

  @TC-09-063 @P1 @Dương
  Kịch bản: TC-09-063 Áp che PARTIAL, REPLACE, KEYED_HASH, TOKENIZE, GENERALIZE, DROP
    # Truy vết: FR-09-028 · API-09-229 · BR-09-025 · NFR-09-003 · LGC-TOOL-012
    # Mục đích: Chứng minh bản tin đầu ra đúng từng kiểu che và không còn giá trị rõ.
    Biết T90; S-T90-APPLY-04; bản tin F-MSG 10 KB 8 trường; miền giả danh `PD-HGD` (HMAC) và `PD-TOKEN` (token); chính sách mỗi trường một kiểu.
    Khi PEP `POST /privacy/v1/messages:apply` với F-MSG, kênh `FLOW`.
    Và so từng trường đầu ra với bản tin gốc.
    Thì `200`; `cccd` `*101` (PARTIAL), `soDienThoai` thay `[REDACTED]` (REPLACE), `maBenhAn` bí danh HMAC ổn định (KEYED_HASH), `soTaiKhoan` token (TOKENIZE), `ngaySinh` `1990` (GENERALIZE), `ghiChu` bị loại (DROP). Mồi sạch với canary trong `maBenhAn`; KT: có tổng hợp theo kênh.

  @TC-09-064 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-064 Bản tin có trường nhãn bí mật bị chặn, không trả trường nào
    # Truy vết: FR-09-028, 007 · API-09-229 · BR-09-005 · ERR-09-101 · EVT-09-14
    # Mục đích: Chứng minh `messages:apply` chặn toàn bản tin như `classification:check`.
    Biết T90; nhãn trên `soHieuMat`; S-T90-APPLY-04.
    Khi PEP `POST /privacy/v1/messages:apply` với F-MSG có `soHieuMat`.
    Thì `403` ERR-09-101, thân không có trường dữ liệu và không nêu trường nhãn; EVT: `secret-label.blocked`.

  @TC-09-065 @P1 @Âm
  Kịch bản: TC-09-065 Sai lược đồ, bản tin quá lớn, miền giả danh không hoạt động
    # Truy vết: FR-09-028 · API-09-229 · ERR-09-106, 107, 109
    # Mục đích: Chứng minh lỗi data plane phân biệt rõ nguồn.
    Biết T90; `PD-HGD` ở `SUSPENDED`; S-T90-APPLY-04.
    Khi gửi thân thiếu `channel`.
    Và gửi bản tin 2 MB (giới hạn giả định `09.apply.max-bytes`, Q09-40).
    Và gửi bản tin có trường giả danh theo `PD-HGD`.
    Thì bước 1 `400` ERR-09-106. Bước 2 `413` ERR-09-107. Bước 3 `422` ERR-09-109, không bản tin nào trả giá trị rõ.

  @TC-09-066 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-09-066 OpenBao hoặc nhật ký che ngừng: không băm, không token hóa, từ chối
    # Truy vết: FR-09-028 · API-09-229 · ERR-09-108, 110 · BR-09-057
    # Mục đích: Chứng minh không trả dữ liệu thô khi hạ tầng khóa hoặc kiểm toán không dùng được.
    Biết T94; S-T90-APPLY-04; bản tin có trường `KEYED_HASH`.
    Khi ngừng OpenBao rồi gọi `messages:apply`.
    Và bật OpenBao, ngừng ghi nhật ký che; gọi lại.
    Thì bước 1 `503` ERR-09-108, không trường rõ nào trong thân. Bước 2 `503` ERR-09-110, thao tác bị từ chối. Mồi sạch.

  @TC-09-067 @P1 @Hiệu @năng
  Kịch bản: TC-09-067 Áp che bản tin 10 KB p95 ≤ 30 ms, có băm hoặc token p95 ≤ 80 ms
    # Truy vết: NFR-09-003 · API-09-229
    # Mục đích: Đo NFR-09-003.
    Biết T97; 3 bản sao.
    Khi k6 500 lượt mỗi giây 15 phút, bản tin 10 KB không băm có khóa; rồi lô token 500 giá trị.
    Thì p95 ≤ 30 ms (không băm) và p95 ≤ 80 ms (băm hoặc token hóa theo lô), 0 lỗi `5xx`.
