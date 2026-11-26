# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-39
Tính năng: TS-17-39 · Phân quyền theo ma trận PERM-17 và bốn mắt

  @TC-17-137 @P1 @Bảo_mật @Âm @Dương
  Kịch bản: TC-17-137 Ma trận quyền: mỗi vai chỉ gọi được API thuộc quyền của mình
    # Truy vết: FR-17-001, 007, 015, 042, 049, 052, 055, 057, 059 · API-17-002, 027, 063, 122, 132, 156, 171, 173, 182 · ERR-00-403, ERR-00-401
    # Mục đích: Chứng minh ma trận 10 quyền × 8 vai trò trên đại diện mỗi nhóm API.
    Biết mỗi vai `PA, TA, TO, SO, IE, DS, VW, AU` một tài khoản ở T90 (PA ở nền tảng); bảng kỳ vọng sinh từ FRS mục 3.2.
    Khi với mỗi cặp (vai, API đại diện) gọi API.
    Và gọi mọi API không có token.
    Và gọi API bằng token vai khác tenant.
    Thì `200`, `201` hoặc `202` đúng ô ● của ma trận; `403` ERR-00-403 ở ô còn lại (SO chỉ xác nhận bật và tắt khẩn ở `PERM-17-admin`, không đổi cấu hình khác); `401` ERR-00-401 khi không token; token tenant khác `404` hoặc `403`.

  @TC-17-138 @P1 @Bảo_mật @Âm
  Kịch bản: TC-17-138 Bốn mắt: người đề nghị không duyệt, kể cả TA có cả quyền soạn lẫn duyệt
    # Truy vết: FR-17-001, 003, 006, 009, 020, 049, 059 · API-17-006, 024, 041, 085, 136 · BR-17-002, 015, 064 · ERR-17-005
    # Mục đích: Chứng minh không có đường vòng cho mọi thao tác cần bốn mắt (FRS mục 3.3).
    Biết U-T90-TA1 có cả `PERM-17-admin`, `PERM-17-eval`; U-PA1; ví dụ thao tác: bật trợ lý, bật mô hình ngoài, gỡ tắt khẩn nền tảng, duyệt phiên bản mô hình, duyệt tài liệu tải lên, duyệt chỉ dẫn, đổi tham số nhạy.
    Khi với từng thao tác trong dữ liệu, một người đề nghị rồi chính người đó duyệt.
    Và đổi người: người thứ hai duyệt.
    Và người đã "quyết định ở bước trước" duyệt bước sau.
    Thì bước 1 `403` ERR-17-005 cho cả 7 thao tác. Bước 2 `200`. Bước 3 `403` ERR-17-005. Mọi lần từ chối có KT.

  @TC-17-139 @P2 @Bảo_mật @Âm
  Kịch bản: TC-17-139 Cặp loại trừ: SO không giữ quyền model, AUDITOR không giữ admin hay eval
    # Truy vết: FR-17-009, 056 · API-17-041, 169, 171 · BR-17-015, 074 · ERR-00-403
    # Mục đích: Chứng minh tách nhiệm vụ ở mục 3.3.
    Biết U-T90-SO (có `PERM-17-eval`, `PERM-17-log-read`), U-T90-AU, người cấp phiếu nhật ký và người mở nhật ký.
    Khi SO gọi `POST /model-providers`.
    Và AU gọi `POST /prompt-versions/{id}:approve` và `POST /policy:disable`.
    Và người cấp phiếu `POST /logs/access-grants` và chính người đó mở bằng tài khoản khác của mình (cùng `sub`).
    Thì bước 1 và 2 `403` ERR-00-403. Bước 3 bị từ chối do cùng người (cặp loại trừ cấp phiếu và mở nhật ký).
