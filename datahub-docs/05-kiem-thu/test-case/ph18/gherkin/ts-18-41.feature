# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-41
Tính năng: TS-18-41 · Cô lập tenant ở API, CSDL, Kafka và tác vụ nặng

  @TC-18-136 @P1 @Bảo_mật
  Kịch bản: TC-18-136 Người dùng T91 đọc đối tượng T90 ở mọi nhóm API nhận 404 giống hệt không tồn tại
    # Truy vết: BR-18-047 · NFR-18-017 · FR-18-005, 021, 044, 048, 054, 061 · API-18-005, 045, 112, 125, 140, 166, 041, 123 · ERR-18-001
    # Mục đích: Chứng minh chống dò tìm: mọi API đọc theo mã trả `404` ERR-18-001 với thân giống hệt đối tượng không tồn tại, danh sách không trả dòng của tenant khác.
    Biết T90, T91 cùng mã đối tượng (`DLQ-A-02`, `INC-T90-02`, `RST-T90-01`, `RUN-DRY-02`, khóa `04.retry.max-attempts`); U-T91-TA có quyền mạnh nhất tenant.
    Khi U-T91-TA gọi chi tiết từng đối tượng của T90 bằng mã của T90.
    Và so thân lỗi với đối tượng không tồn tại.
    Và U-T91-TA gọi danh sách DLQ, sự cố, khôi phục, lần chạy di trú có bộ lọc trùng giá trị của T90.
    Thì bước 1 mọi lời gọi `404` ERR-18-001. Bước 2 thân giống hệt trừ `traceId`. Bước 3 0 dòng của T90; giá trị `04.retry.max-attempts` của T91 không bị giá trị T90 ảnh hưởng.

  @TC-18-137 @P1 @Bảo_mật
  Kịch bản: TC-18-137 Bộ kiểm RLS và quyền của CSDL ph18_ops chạy đạt
    # Truy vết: BR-18-047, 012 · NFR-18-017 · FR-18-019, 055, 057
    # Mục đích: Chứng minh cô lập ở mức CSDL bằng bộ kiểm đã có của tập CSDL: RLS mọi bảng, dòng `COMMON` chỉ phiên `COMMON` ghi, vai `ph18_readonly` không đọc payload, vai `ph18_worker` chỉ bảng di trú và khôi phục.
    Biết `postgres:16` rỗng; `03-thiet-ke/csdl/ph18/ddl/ph18_ops.sql`; `03-thiet-ke/csdl/ph18/test/ph18_isolation_test.sql` (tenant T90, T91).
    Khi chạy `psql -v ON_ERROR_STOP=1 -f ph18_ops.sql`.
    Và chạy `psql -v ON_ERROR_STOP=1 -f ph18_isolation_test.sql`.
    Thì mọi khối ghi `PASS`, tệp chạy hết không `RAISE`; các SQLSTATE mong đợi (23514, 23505, 23503, 42501, 55000) khớp. Bộ này chạy trong CI ở mỗi thay đổi DDL.

  @TC-18-138 @P1 @Bảo_mật
  Kịch bản: TC-18-138 Danh tính T91 không đọc, ghi được topic ops của T90; sự kiện không mang payload
    # Truy vết: BR-18-047, 050 · NFR-18-017 · EVT-18-01, 05, 07, 09, 13, 22, 28
    # Mục đích: Chứng minh ACL Kafka theo tiền tố tenant và quy tắc sự kiện chỉ mang mã, trạng thái, số đếm.
    Biết T90, T91; client OAUTHBEARER của S-T91-PH04; consumer kiểm trên mọi topic `t90.ops.*.v1` trong lúc chạy chương 4.
    Khi S-T91-PH04 đọc `t90.ops.dlq.state-changed.v1`.
    Và S-T91-PH04 ghi `t90.ops.dlq.v1`.
    Và quét mọi bản tin `t90.ops.*.v1` đã phát.
    Thì bước 1, 2 bị từ chối `TOPIC_AUTHORIZATION_FAILED`. Bước 3 không bản tin nào chứa payload DLQ, giá trị khóa ★, địa chỉ thư, số điện thoại hay chuỗi mồi `DH-CANARY-18`.

  @TC-18-139 @P1 @Bảo_mật @Dương @Âm
  Kịch bản: TC-18-139 PA, PO xem DLQ liên tenant ở chế độ nền tảng cần lý do và kiểm toán
    # Truy vết: BR-18-047 · FR-18-019, 021 · API-18-041, 045, 049 · ERR-18-007 · ERR-00-403
    # Mục đích: Chứng minh BR-18-047 và SEC-85: chế độ nền tảng không mặc định, mỗi lần bật có lý do, thời hạn và kiểm toán; PO không có quyền ghi.
    Biết U-PO1 (`PERM-18-read`, `PERM-18-dlq`), U-PA1; T90, T91 có mục DLQ.
    Khi U-PO1 `GET /dlq/messages` không có tiêu đề chế độ nền tảng.
    Và U-PO1 bật chế độ nền tảng với lý do 4 ký tự.
    Và U-PO1 bật với lý do hợp lệ, liệt kê mục của T90 và T91.
    Và U-PO1 xem payload của mục T91.
    Thì bước 1 `200` 0 dòng (PO không thuộc tenant). Bước 2 `422` ERR-18-007. Bước 3 `200` có cột tenant, KT: có (platform-mode) với lý do. Bước 4 `403` ERR-00-403 vì PO chỉ có quyền xem payload hạn chế theo ma trận FRS mục 3.2.

  @TC-18-140 @P1 @Bảo_mật
  Kịch bản: TC-18-140 Khôi phục, xuất và chuyển sáp nhập chạy với SET LOCAL app.tenant_id, không chạm tenant khác
    # Truy vết: BR-18-047, 038, 045 · NFR-18-017 · FR-18-055, 056, 057
    # Mục đích: Chứng minh công cụ trong `dh-batch` không có đường vòng RLS: thử ghi dòng của tenant khác trong phiên của Job bị chặn.
    Biết STAGING; Job `dh-tenant-restore`, `dh-tenant-export` cho T90 với vai `ph18_worker`; dòng mồi của T91 ở cùng ô.
    Khi trong phiên Job của T90, chạy câu cập nhật dòng mồi của T91.
    Và chạy xuất T90 và kiểm manifest.
    Và chạy chuyển sáp nhập T92 → T90 và kiểm T91.
    Thì bước 1 0 dòng bị đổi hoặc SQLSTATE 42501. Bước 2 manifest không có tệp hay dòng của tenant khác. Bước 3 T91 không đổi; mọi dòng mới ở T90 có `origin_tenant_id`.
