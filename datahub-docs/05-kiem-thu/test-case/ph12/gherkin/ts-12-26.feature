# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-26
Tính năng: TS-12-26 · Quyết định ủy quyền: hợp đồng PEP–PDP và quy tắc gốc

  @TC-12-079 @P1 @Dương @Âm
  Kịch bản: TC-12-079 Quyết định cho phép theo vai trò, phạm vi và thuộc tính
    # Truy vết: FR-12-044, 046 · UC-12-31 · API-12-086 · BR-12-037 · LGC-BUS-041 · NFR-12-002
    Biết S-PEP; U-T68-IE, U-T68-PH07; bộ 30 yêu cầu mẫu.
    Khi `POST /api/authz/v1/decide` cho 30 bộ (chủ thể, hành động, tài nguyên, bối cảnh), trong đó 10 bộ vượt vai trò hoặc phạm vi tổ chức.
    Thì `200`, kết quả khớp bảng đúng (10 bộ vượt quyền `deny`); có `obligations`, `fieldMask`, `decisionId`; p95 ≤ 10 ms.

  @TC-12-080 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-080 Không có luật cho phép thì từ chối; quên viết chính sách không lộ dữ liệu
    # Truy vết: FR-12-045 · BR-12-001 · API-12-086 · ADR-006 · SEC-26
    Biết hành động mới `x.moi` chưa có luật nào.
    Khi gọi `decide` cho `x.moi` với PA.
    Thì `deny` kèm lý do `no-matching-allow`; kể cả PA không có quyền ngầm.

  @TC-12-081 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-081 Từ chối thắng cho phép, chính sách tenant không gỡ được luật gốc
    # Truy vết: FR-12-045 · BR-12-002, BR-12-005 · API-12-086 · ADR-006
    Biết POL-GOC; POL-T68-OK có luật `deny` bổ sung; dữ liệu nhãn bí mật nhà nước.
    Khi yêu cầu có đồng thời luật cho phép và luật `deny` của gói gốc.
    Và yêu cầu truy cập dữ liệu nhãn bí mật nhà nước bằng PA.
    Thì cả hai `deny`; luật `deny` của gói gốc không bị gói tenant vô hiệu; không có luật cho phép nào cho nhãn bí mật nhà nước.

  @TC-12-082 @P1 @Dương @Bảo @mật
  Kịch bản: TC-12-082 Cách ly tenant ở quyết định, ngoại lệ chỉ bằng quyền thời hạn
    # Truy vết: FR-12-045 · BR-12-003, BR-12-004, BR-12-031 · API-12-086 · SEC-80, SEC-85 · NFR-12-014
    Biết U-T68-TA1; tài nguyên của T01; quyền có thời hạn còn hiệu lực của U-PO.
    Khi TA T68 hỏi quyền với tài nguyên T01.
    Và gửi `tenant` trong thân khác với token.
    Và U-PO có quyền có thời hạn hỏi cùng tài nguyên; sau khi hết hạn hỏi lại.
    Thì bước 1, 2 `deny`; `tenant` lấy từ token đã xác minh, không từ thân; bước 3 `allow` trong hạn rồi `deny`.

  @TC-12-083 @P1 @Dương @Âm
  Kịch bản: TC-12-083 Mặt nạ trường và chế độ bảo vệ theo mục đích
    # Truy vết: FR-12-047 · BR-12-040, BR-12-012 · API-12-086 · CMP-LAW-05 · SEC-31
    Biết thực thể `hoso` có tập trường khai báo; thực thể `moi` chưa khai báo.
    Khi hỏi quyền đọc `hoso` với mục đích khác nhau.
    Và hỏi quyền đọc `moi`.
    Thì `fieldMask` đổi theo mục đích; `moi` có `fieldMask` rỗng kèm cảnh báo cấu hình; tài nguyên Nhạy cảm không đệm.

  @TC-12-084 @P1 @Âm
  Kịch bản: TC-12-084 Yêu cầu thiếu trường, thiếu scope `iam:decide`
    # Truy vết: FR-12-044 · API-12-086 · ERR-12-101 · ERR-12-102
    Biết S-PEP; token không có scope.
    Khi gọi thiếu `resource`; gọi bằng token thiếu scope; gọi không token.
    Thì `400` ERR-12-101; hai trường hợp sau `401` ERR-12-102.

  @TC-12-085 @P1 @Bảo @mật @Chaos
  Kịch bản: TC-12-085 Fail-closed: OPA lỗi, quá 50 ms, chưa nạp gói
    # Truy vết: FR-12-044 · BR-12-006, BR-12-013 · NFR-12-014 · API-12-086 · ERR-12-103, ERR-12-104, ERR-12-124 · SEC-26
    Biết SIM-OPA-DOWN; 1.000 yêu cầu hợp lệ; tài nguyên Nhạy cảm; Kafka ghi vết tắt.
    Khi tắt OPA, bắn 1.000 yêu cầu; làm OPA chậm > 50 ms; khởi động pod chưa nạp gói.
    Và tắt đường ghi vết, truy cập tài nguyên Nhạy cảm.
    Thì 100 % bị từ chối (0 lọt) và ERR-12-103 (500) hoặc ERR-12-104 (503) được bên gọi xử lý như từ chối; bước 2 ERR-12-124 (403): không có vết thì không được truy cập.
