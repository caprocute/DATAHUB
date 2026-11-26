# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-23
Tính năng: TS-04-23 · Ngữ cảnh tenant và rò rỉ chéo tenant

  @TC-04-139 @P1 @Bảo @mật
  Kịch bản: TC-04-139 Mọi API đọc theo mã trùng giữa hai tenant
    # Truy vết: FR-04-073, 001, 002 · API-04-010, 012, 020, 024, 025, 026, 041, 042, 044, 054, 060, 062, 063, 091 · ERR-04-001.
    Biết F-HT ở T68 và F-T01 ở T01 cùng mã `tra-cuu-ho-tich`; mỗi bên có phiên bản, lần chạy, ca, triển khai.
    Khi U-T68-TA gọi lần lượt mọi API đọc trong cột truy vết với mã `tra-cuu-ho-tich`.
    Và dùng `runId`, `deploymentId`, `commandId` của T01 trong đường dẫn với token T68.
    Thì bước 1: mọi phản hồi chỉ có dữ liệu của T68 (không có chuỗi `"tinh":"T01"` ở bất kỳ phản hồi nào). Bước 2: mọi lệnh trả 404-ẩn.

  @TC-04-140 @P1 @Bảo @mật
  Kịch bản: TC-04-140 RLS chặn ở CSDL kể cả khi ứng dụng sai
    # Truy vết: FR-04-073.
    Biết kết nối vai trò `ph04_app`, `SET app.tenant_id = 'T68'`.
    Khi `SELECT count(*)` trên 26 bảng của `ph04` với điều kiện `tenant_id = 'T01'`.
    Và `INSERT` một dòng `flow` với `tenant_id = 'T01'`.
    Và `UPDATE ph04.component_policy` dòng `PLATFORM` đổi `decision = 'ALLOWED'`.
    Và không đặt `app.tenant_id`, `SELECT count(*) FROM ph04.flow`.
    Thì bước 1 trả 0 ở mọi bảng mẫu P; bảng mẫu S chỉ trả dòng `COMMON`/`PLATFORM`. Bước 2 bị `WITH CHECK` từ chối. Bước 3 không đổi dòng nào (ràng buộc `ck_component_policy_narrow` và chính sách S). Bước 4 trả 0.

  @TC-04-141 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-04-141 Bản tin mang tiêu đề tenant giả
    # Truy vết: FR-04-073, 061 · BR-04-010 · ERR-04-112.
    Biết MSG-TENANT.
    Khi gọi F-HT T68 với tiêu đề `dh-tenant: T01`.
    Và một chặng trong luồng thử (vượt qua kiểm tra tĩnh) đặt `dh-tenant = T01` giữa đường.
    Thì bước 1: `dh-receive-action` bỏ tiêu đề do bên gọi gửi, đặt `T68` từ ngữ cảnh namespace và token đã APISIX xác minh; luồng chạy bình thường cho T68. Bước 2: `TenantGuard` ở chặng gửi đích phát hiện lệch, trả `500` ERR-04-112, không gọi đích; cảnh báo an ninh mức cao.

  @TC-04-142 @P1 @Bảo @mật
  Kịch bản: TC-04-142 Runtime, topic, kho cấu hình tách theo tenant
    # Truy vết: FR-04-073, 042.
    Biết SIT có `dh-rt-t68`, `dh-rt-t01`.
    Khi từ pod `dh-rt-t68`, thử đọc ConfigMap của `dh-rt-t01`.
    Và từ pod `dh-rt-t68`, thử tiêu thụ `t01.hotich.yeucau.v1`.
    Và từ pod `dh-rt-t68`, thử gọi HTTP tới pod `dh-rt-t01`.
    Và dùng token Git của ApplicationSet T68 đẩy vào `dh-flows-t01`.
    Và sandbox chạy lần thử của T68 rồi của T01 trên cùng pod.
    Thì bước 1 bị RBAC từ chối. Bước 2 bị ACL Kafka từ chối. Bước 3 bị NetworkPolicy chặn. Bước 4 bị Gitea từ chối. Bước 5: lần chạy T01 không thấy bất kỳ tiêu đề, thuộc tính, bộ đệm hay biến nào của lần T68 (mỗi lần chạy một `CamelContext` mới, đã dọn).
