# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-19
Tính năng: TS-05-19 · Bộ điều hợp CSDL theo truy vấn khai báo

  @TC-05-074 @P1 @Dương
  Kịch bản: TC-05-074 Truy vấn khai báo với tham số ràng buộc
    # Truy vết: FR-05-038 · API-05-050 · EVT-05-14 · LGC-TOOL-008
    Biết U-T68-IE1; bộ điều hợp `tc-dkkd-sql` trên C-DKKD; tài khoản đọc của luồng.
    Khi khai thao tác `statement = SELECT ma_so_thue, ten FROM dkkd.doanh_nghiep WHERE ma_so_thue = :#mst`.
    Và luồng gọi với `mst = "0999000001' OR '1'='1"`.
    Thì bước 1 `200`, `parameters` tự nhận `mst`. Bước 2 trả 0 dòng (giá trị ràng buộc, không ghép chuỗi); SIM-PG nhận câu có `$1`. EVT-05-14 một bản ghi.

  @TC-05-075 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-075 Câu lệnh bị chặn khi khai báo
    # Truy vết: FR-05-038 · API-05-050 · ERR-05-032
    Biết như TC-05-074, kết nối chỉ đọc.
    Thì mọi câu `422` ERR-05-032 với vị trí dòng, cột và quy tắc vi phạm.

  @TC-05-076 @P2 @Biên
  Kịch bản: TC-05-076 Quá thời gian, vượt số dòng
    # Truy vết: FR-05-038 · ERR-05-111
    Biết `maxRows = 1000`; bảng 5.000 dòng; câu chậm 40 giây với `timeoutMs = 10000`.
    Thì câu một trả 1.000 dòng với `dh-truncated = true` nếu thao tác cho phép cắt, nếu không ERR-05-111. Câu hai ERR-05-111 trong ≤ 11 giây, SIM-PG thấy phiên bị hủy.
