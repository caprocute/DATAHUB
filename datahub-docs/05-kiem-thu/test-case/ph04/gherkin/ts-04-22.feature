# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-22
Tính năng: TS-04-22 · Truy cập CSDL có kiểm soát (Q359)

  @TC-04-135 @P1 @Dương
  Kịch bản: TC-04-135 Đọc theo lịch với tham số hóa
    # Truy vết: FR-04-072 · BR-04-015 · UC-04-19.
    Biết F-SQL TEST; CSDL nguồn giả lập có 2.500 dòng `dkkd.doanh_nghiep`.
    Khi kích hoạt lịch.
    Và đọc `pg_stat_activity` và nhật ký kiểm toán.
    Thì truy vấn chạy bằng `rd_doc_dkkd_sql`, có `SET LOCAL app.tenant_id = 'T68'`, `statement_timeout = 10s`, tham số `$1` (không nối chuỗi). Bản tin kiểm toán có câu lệnh đã chuẩn hóa, số dòng 2.500, không có giá trị dòng.

  @TC-04-136 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-136 Chính sách SQL chặn câu ghi và câu nguy hiểm
    # Truy vết: FR-04-072, 023 · BR-04-015 · ERR-04-031.
    Biết 18 câu lệnh: `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `COPY … TO PROGRAM`, `SELECT pg_sleep(100)`, `SELECT … FOR UPDATE`, `SELECT dblink(…)`, `SELECT lo_import(…)`, hai câu nối bằng `;`, CTE có `DELETE … RETURNING`, câu tham chiếu `ph04.flow`, `SELECT … ${header.x}` (nối chuỗi), `CALL proc()`, `SET ROLE`; và 6 câu hợp lệ (`SELECT`, `WITH … SELECT`, có `$1`).
    Khi chạy `SqlPolicy` (JSqlParser) trên từng câu.
    Và lưu nháp luồng chứa từng câu, `:validate` mức `DESIGN`.
    Thì 18/18 câu bị chặn với VR-13 `ERROR` và ERR-04-031, `reason` cụ thể; 6/6 câu hợp lệ không báo. Câu không phân tích được bị coi là vi phạm (đóng khi lỗi).

  @TC-04-137 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-137 Kết nối không phải chỉ đọc
    # Truy vết: FR-04-072 · BR-04-015 · ERR-04-013.
    Biết `tc-sql-rw` dùng CONN-DKKD-RW.
    Khi `:validate` mức `SUBMIT`.
    Và Ở RT, cấu hình bỏ qua kiểm tra tĩnh, chạy `SELECT` qua kết nối có `INSERT`, rồi thử `INSERT` bằng cách lồng trong hàm do CSDL nguồn định nghĩa.
    Thì bước 1: VR-13 `ERROR` với ERR-04-013 ("Kết nối không phải loại chỉ đọc"). Bước 2: Kamelet SQL mở giao dịch `READ ONLY` nên `INSERT` trong hàm bị CSDL từ chối (`25006 read_only_sql_transaction`); bản tin vào DLQ với ERR-04-108.

  @TC-04-138 @P2 @Biên
  Kịch bản: TC-04-138 Quá thời gian, vượt số dòng
    # Truy vết: FR-04-072, 084 · ERR-04-108.
    Biết `04.sql.max-rows = 1000`; bảng 2.500 dòng; một câu `SELECT` trên bảng không có chỉ mục chạy 15 giây.
    Khi chạy câu trả 2.500 dòng.
    Và chạy câu 15 giây.
    Thì bước 1: dừng ở 1.001 dòng, lỗi ERR-04-108 "vượt số dòng tối đa", không trả kết quả cắt cụt im lặng. Bước 2: CSDL hủy câu sau 10 giây (`57014`), ERR-04-108.
