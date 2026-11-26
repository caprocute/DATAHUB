# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-13
Tính năng: TS-05-13 · Nhật ký truy cập CSDL của luồng

  @TC-05-052 @P1 @Dương
  Kịch bản: TC-05-052 Mỗi câu lệnh có một bản ghi truy cập
    # Truy vết: FR-05-027 · EVT-05-14 · API-05-041 · UC-05-10
    Biết U-T68-SO; luồng `dkkd-dong-bo` chạy thao tác `dh-sql-ro-source` 5 lần với tham số `maSoThue = 0999000001`.
    Khi đọc topic `t68.adapter.db.access-recorded.v1`.
    Và `GET /db-access-logs?flowCode=dkkd-dong-bo`.
    Thì 5 sự kiện, 5 dòng `db_access_record`: luồng, phiên bản, thao tác, `statementHash`, số dòng, thời lượng, kết quả, `traceId`; không có giá trị `0999000001`. Bảng chỉ thêm (UPDATE, DELETE bị trigger chặn, xem TC-05-125).

  @TC-05-053 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-053 Chỉ SO, AU xem nhật ký; tenant khác không thấy
    # Truy vết: FR-05-027 · API-05-041 · ERR-05-012 · BR-05-002
    Biết U-T68-IE1; U-T01-IE.
    Thì IE1 403-PQ. U-T01-IE (có quyền ở T01) `200` với 0 dòng của T68.
