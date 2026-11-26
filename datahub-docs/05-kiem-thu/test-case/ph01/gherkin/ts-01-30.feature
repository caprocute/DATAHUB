# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-30
Tính năng: TS-01-30 · Cách ly tenant và RLS

  @TC-01-117 @P1 @Bảomật
  Kịch bản: TC-01-117 RLS ở CSDL
    # Truy vết: BR-01-030 · FR-01-002 · UC-01-01.
    Biết dữ liệu T68 và T01 ở mọi bảng của `ph01_onboarding`.
    Khi đặt `app.tenant_id = T68`; đọc mọi bảng.
    Và không đặt tenant; đọc.
    Và với T68 chèn, sửa một dòng có `tenant_id = T01`.
    Thì chỉ thấy dòng T68; không đặt tenant thì 0 dòng; chèn, sửa dòng tenant khác bị chính sách RLS chặn.

  @TC-01-118 @P1 @Âm @Bảomật
  Kịch bản: TC-01-118 Mọi API đọc trả "không tồn tại" cho tenant khác
    # Truy vết: BR-01-030 · API-01-006, 008, 014, 036, 043, 049, 050, 058, 067, 074 · ERR-01-001.
    Biết U-T68-TA1; đối tượng tương ứng chỉ có ở T01 (HTTT `HT-TC-KHAC`, tệp, đầu mối, định danh, kỳ rà soát, yêu cầu thay đổi).
    Khi tham số hóa các API đọc theo danh sách trên, gọi bằng id của T01.
    Và so thân với id không tồn tại.
    Thì tất cả `404-ẩn`, thân giống hệt trừ `traceId`, thời gian phản hồi không khác biệt có thể phân biệt.

  @TC-01-119 @P1 @Âm @Bảomật
  Kịch bản: TC-01-119 Mọi API ghi, hành động không tác động tenant khác
    # Truy vết: BR-01-030 · API-01-005, 018, 023, 032, 045, 047, 051, 057, 088 · ERR-01-001.
    Biết U-T68-TA1 có đủ quyền ở T68; `HT-TC-KHAC` của T01 (ACTIVE).
    Khi gọi `PATCH`, `:submit`, `:approve`, `:suspend`, `:terminate`, `:rotate`, `:revoke`, `change-requests` vào `HT-TC-KHAC` và định danh của nó.
    Và đọc lại `HT-TC-KHAC` bằng U-T01-TA.
    Thì mọi lệnh `404-ẩn`; `HT-TC-KHAC` không đổi (ETag, trạng thái, lịch sử); không sự kiện, không kiểm toán nghiệp vụ ở T01.

  @TC-01-120 @P1 @Bảomật
  Kịch bản: TC-01-120 Kafka và kho tệp theo tenant
    # Truy vết: BR-01-030 · NFR-01-011 · EVT-01-03 · FR-01-005.
    Biết hai bộ tiêu thụ thử: `t68.*` và `t01.*`; tệp đính kèm ở cả hai tenant.
    Khi thực hiện chuyển trạng thái ở T68; đọc topic T01.
    Và dùng thông tin xác thực của T01 truy cập trực tiếp đường dẫn đối tượng của T68.
    Thì topic T01 không có bản tin của T68; mỗi bản tin có `dhtenant` đúng; truy cập đối tượng trực tiếp bị từ chối (bucket, chính sách riêng).
