# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-25
Tính năng: TS-11-25 · Cô lập tenant: API, RLS, Flowable, Kafka

  @TC-11-132 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-132 Rò rỉ chéo tenant ở mọi API đọc và ghi
    # Truy vết: API-11-002, 009, 019, 031, 051, 073, 097, 110, 122 · ERR-11-001 · BR-11-032 · NFR-11-020
    # Mục đích: Chứng minh token T91 không đọc, ghi được đối tượng T90 qua API nào, `404` không phân biệt "không có" với "tenant khác".
    Biết T90 có mô hình, biểu mẫu, ý định, phiên, việc, Saga, sự cố, gói bằng chứng; `U-T91-IE1`, `U-T91-CB1`, S-T91-DVC.
    Khi với mỗi API `GET` có `{id}` (khoảng 45 API), gọi bằng token T91 với id của T90 và so thân với id không tồn tại
    Và gọi các API ghi (`:complete`, `:cancel`, `:approve`, `PUT`) bằng token T91 với id của T90
    Và gọi các API danh sách bằng token T91
    Và tìm chuỗi `canary` của T90 trong mọi phản hồi của T91
    Thì mọi lệnh `404-ẩn` ERR-11-001, thân giống "không tồn tại" trừ `traceId`; không có dòng nào của T90 trong danh sách T91; không thay đổi dữ liệu T90; canary T90 không xuất hiện.

  @TC-11-133 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-133 Cô lập ở CSDL: bộ ph11_isolation_test.sql
    # Truy vết: BR-11-032, 004, 007, 023 · NFR-11-020, 021 · EN-11-02, 08, 09, 21
    # Mục đích: Chứng minh RLS, phân vùng, mẫu `COMMON`, vai trò và schema engine chặn truy cập chéo tenant ở CSDL.
    Biết CSDL rỗng đã nạp `ph11_bpm.sql`; vai trò có quyền tạo vai trò; T90, T91.
    Khi chạy `psql -v ON_ERROR_STOP=1 -d datahub -f ph11_isolation_test.sql`
    Và đọc số khối `PASS`
    Và chạy lại với `SET ROLE` của dịch vụ ứng dụng
    Thì mọi khối `PASS`, không `RAISE`; T91 không đọc, sửa, xóa, chèn dòng T90 (SQLSTATE 42501 hoặc 0 dòng); khóa lũy đẳng, bốn mắt, bảng chỉ thêm, outbox không chứa giá trị biến đúng; vai trò dịch vụ không truy cập `ph11_flowable` ngoài dịch vụ PH-11.

  @TC-11-134 @P1 @Bảo @mật
  Kịch bản: TC-11-134 Mỗi tenant một tenantId Flowable
    # Truy vết: BR-11-032, 006 · FR-11-008, 018 · NFR-11-020
    # Mục đích: Chứng minh truy vấn engine lọc `tenantId`; cùng `processKey` ở hai tenant dùng đúng định nghĩa của mình.
    Biết `LT_KHAI_SINH` v3 ở T90; `LT_KHAI_SINH` v1 khác nội dung ở T91.
    Khi đọc `ACT_RE_DEPLOYMENT` theo `TENANT_ID_`
    Và S-DVC T90 và S-T91-DVC khởi tạo cùng `businessKey`
    Và đọc `PROC_DEF_ID_` của hai phiên
    Và kiểm quyền vai trò khác (ngoài dịch vụ) với `ACT_*`
    Thì mỗi deployment gắn `tenantId = t90` hoặc `t91`; phiên T90 dùng định nghĩa T90, phiên T91 dùng T91; vai trò ngoài dịch vụ bị từ chối truy cập `ACT_*`.

  @TC-11-135 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-135 ACL Kafka theo tiền tố và nội dung lệnh
    # Truy vết: EVT-11-03, 17, 18, 19 · BR-11-014, 032 · NFR-11-020
    # Mục đích: Chứng minh client T91 không đọc, không ghi topic `t90.bpm.*` và lệnh không mang dữ liệu tenant khác.
    Biết client OAUTHBEARER của T91; `ph04-sim` T91.
    Khi client T91 đăng ký đọc `t90.bpm.instance.started.v1`
    Và client T91 ghi `t90.bpm.service.completed.v1` với `commandId` của T90
    Và quét các lệnh `t91.bpm.service.requested.v1` tìm `businessKey` T90
    Thì bước 1 và 2 bị từ chối theo ACL; lệnh giả không tương quan được phiên T90 (không có ERR-11-103 ở T90); bước 3 không có dữ liệu T90.

  @TC-11-136 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-136 Trùng khóa nghiệp vụ giữa hai tenant
    # Truy vết: BR-11-007, 022 · FR-11-018, 030, 055 · API-11-049, 069, 104 · ERR-11-035
    # Mục đích: Chứng minh cùng `businessKey`, `messageName`, `Idempotency-Key` ở hai tenant không đụng nhau.
    Biết hai phiên `HS-T90-2026-0001` ở T90 và T91 cùng `processKey`; cùng `Idempotency-Key`.
    Khi hai client khởi tạo với cùng khóa
    Và T91 gửi `HO_SO_BO_SUNG` cho `businessKey` đó
    Và S-DVC và S-T91-DVC tra tiến độ
    Thì hai phiên độc lập; thông điệp chỉ đánh thức phiên T91; mỗi client chỉ thấy tiến độ của tenant mình.
