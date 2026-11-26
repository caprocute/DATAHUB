# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-18
Tính năng: TS-05-18 · Bộ điều hợp tệp SFTP

  @TC-05-071 @P1 @Dương
  Kịch bản: TC-05-071 Quét SFTP, bỏ tệp đang ghi dở
    # Truy vết: FR-05-036 · UC-05-15 · ERR-05-112 · LGC-TOOL-011
    Biết bộ điều hợp `tc-bhxh` `POLL`, `includePattern = BC_*.csv`, `readyStrategy = STABLE_SIZE`, `stableSeconds = 30`, lịch mỗi phút.
    Khi ghi `BC_01.csv` dần trong 90 giây.
    Và ghi `BC_02.csv` một lần; thêm `khac.txt`.
    Thì `BC_01.csv` chỉ được nhận sau khi kích thước ổn định 30 giây (các lượt trước ghi ERR-05-112 mức thông tin); `BC_02.csv` nhận ở lượt kế; `khac.txt` không bị chạm. Tệp xong chuyển `archiveDirectory`.

  @TC-05-072 @P1 @Biên
  Kịch bản: TC-05-072 Hai bản sao không cùng xử lý một tệp
    # Truy vết: FR-05-036 · BR-05-026
    Biết như TC-05-071; runtime 3 bản sao.
    Thì mỗi tệp được xử lý đúng một lần (đếm `dh-file-checksum` ở luồng); có tên tạm `.dh-processing-{uuid}` khi đang xử lý.

  @TC-05-073 @P2 @Âm
  Kịch bản: TC-05-073 Tệp sai định dạng và bản ghi lỗi
    # Truy vết: FR-05-036, 041 · ERR-05-113, 109
    Biết F-CSV-1M (3 dòng thiếu trường bắt buộc, quy tắc `REJECT`); một tệp nhị phân đặt tên `.csv`.
    Thì F-CSV-1M: 999.997 bản ghi đi tiếp, 3 bản ghi vào danh sách lỗi với dòng và trường; tệp nhị phân ERR-05-113, chuyển `errorDirectory`.
