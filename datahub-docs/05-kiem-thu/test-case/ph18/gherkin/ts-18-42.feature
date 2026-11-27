# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-42
Tính năng: TS-18-42 · Phân quyền theo ma trận PERM-18 và bốn mắt xuyên suốt

  @TC-18-141 @P1 @Bảo_mật
  Kịch bản: TC-18-141 Mỗi vai trò chỉ làm được thao tác theo ma trận PERM-18
    # Truy vết: FR-18-019, 022, 023, 027, 035, 048, 054, 059, 069 · ERR-00-403
    # Mục đích: Chứng minh 11 quyền PERM-18 với 9 vai trò: mỗi ô "—" trả `403`, mỗi ô "●" thực hiện được.
    Biết T90; tài khoản U-T90-{vai} cho PA, PO, TA, TO, SO, IE, DS, AU, VW; bảng thao tác mẫu một API cho mỗi quyền (`PERM-18-read`, `-dlq`, `-dlq-payload`, `-approve`, `-config`, `-template`, `-incident`, `-backup`, `-calendar`, `-migration`, `-admin`).
    Khi chạy 99 lời gọi (11 quyền × 9 vai trò) theo bảng.
    Và VW mở UI-18-01 và UI-18-06.
    Thì mọi kết quả khớp ma trận: ô "—" `403` ERR-00-403; ô "○" chỉ đạt trong phạm vi hạn chế ghi ở FRS (VW chỉ thống kê, PA ở chế độ nền tảng). Bước 2 VW thấy thống kê, không thấy danh sách mục.

  @TC-18-142 @P1 @Bảo_mật
  Kịch bản: TC-18-142 Thiếu token, token hết hạn, token người gọi API nội bộ, scope máy gọi API người dùng
    # Truy vết: BR-18-016 · API-18-028, 035, 041, 091 · ERR-00-401, 403
    # Mục đích: Chứng minh xác thực và tách đường người với đường máy.
    Biết T90; token hết hạn của U-T90-TO; S-PH19.
    Khi gọi `GET /dlq/messages` không có token, rồi với token hết hạn.
    Và U-T90-TA1 gọi `POST /ops/internal/v1/notifications` qua APISIX.
    Và S-PH19 gọi `GET /dlq/messages`.
    Thì bước 1 `401` ERR-00-401. Bước 2 `403` hoặc bị APISIX chặn tuyến nội bộ. Bước 3 `403` ERR-00-403.

  @TC-18-143 @P1 @Bảo_mật
  Kịch bản: TC-18-143 Người đề nghị không duyệt được ở cả tám loại đối tượng bốn mắt
    # Truy vết: BR-18-004, 018, 021, 038, 041, 044 · FR-18-004, 008, 024, 028, 035, 055, 062, 068 · API-18-010, 019, 055, 070, 088, 142, 167, 175 · ERR-18-005 · UI-18-15
    # Mục đích: Chứng minh LP-18-01 nhất quán: tham số ★, gói tham số, bản sửa payload, lượt phát lại lớn, phiên bản mẫu, khôi phục tenant, chạy di trú thật, cắt chuyển đều trả ERR-18-005 và việc duyệt có `excludeUsers`.
    Biết tám đối tượng `PENDING_APPROVAL` do U-T90-TA1 tạo (TA1 có `PERM-18-approve`); dữ liệu theo các ca TS-18-03, 05, 14, 17, 20, 31, 36, 38.
    Khi TA1 gọi API duyệt của từng đối tượng.
    Và TA1 mở `/ca-nhan/viec`.
    Và TA2 mở `/ca-nhan/viec`.
    Thì bước 1 tám lần `403` ERR-18-005, không đối tượng nào đổi trạng thái. Bước 2 không có việc duyệt nào. Bước 3 có đủ tám việc; nút "Duyệt" trên màn đối tượng bị khóa với TA1.

  @TC-18-144 @P1 @Âm
  Kịch bản: TC-18-144 Mọi PUT, PATCH, chuyển trạng thái cần If-Match; POST dùng lại khóa với thân khác bị từ chối
    # Truy vết: BR-18-049 · API-18-006, 022, 033, 059, 096, 101, 114, 120, 126, 162, 065, 083, 124, 138 · ERR-18-004, 009 · ERR-00-428
    # Mục đích: Chứng minh BR-18-049 bằng mẫu đại diện của mỗi nhóm API ghi.
    Biết T90; danh sách thao tác ghi sinh từ `openapi-ops.yaml` (tham số `IfMatch`, `IdempotencyKey`).
    Khi gọi mỗi `PUT`, `PATCH`, chuyển trạng thái không có `If-Match`, rồi với `ETag` cũ.
    Và gọi mỗi `POST` tạo hai lần cùng `Idempotency-Key`, lần hai thân khác.
    Và chạy Spectral kiểm mọi thao tác ghi khai đủ tiêu đề.
    Thì bước 1 `428` ERR-00-428 rồi `412` ERR-18-004. Bước 2 lần hai `409` ERR-18-009. Bước 3 không có cảnh báo thiếu tiêu đề.
