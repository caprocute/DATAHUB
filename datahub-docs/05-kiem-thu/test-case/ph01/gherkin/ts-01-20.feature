# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-20
Tính năng: TS-01-20 · Tạm ngừng, khôi phục HTTT và phân tích tác động

  @TC-01-077 @P1 @Dương @Âm
  Kịch bản: TC-01-077 Phân tích tác động phụ thuộc
    # Truy vết: FR-01-033 · UC-01-20 · API-01-056 · UI-01-11 · BR-01-023 · ERR-01-046.
    Biết `HT-QLVB` có phụ thuộc ở PH-02, PH-05, PH-10 (giả lập); U-T68-TA1.
    Khi `GET /systems/HT-QLVB/impact`.
    Và PH-02 giả lập `fail`; gọi lại.
    Thì bước 1: `200`, danh sách đăng ký, kết nối, luồng phụ thuộc theo phân hệ, đánh dấu HTTT thiết yếu. Bước 2: `503` ERR-01-046; UI-01-11 vẫn cho tiếp tục nhưng ghi "chưa phân tích đủ".

  @TC-01-078 @P1 @Dương
  Kịch bản: TC-01-078 Tạm ngừng có xác nhận tác động, cắt quyền ≤ 60 giây
    # Truy vết: FR-01-029 · UC-01-20 · API-01-051 · UI-01-11 · BR-01-009, 023 · ERR-01-034 · EVT-01-03, 07 · NFR-01-008.
    Biết `HT-QLVB` ACTIVE đang gọi API 5 lần/giây qua giả lập PH-03; TA1 có MFA mới.
    Khi `POST /systems/HT-QLVB:suspend` kèm lý do khi chưa xác nhận tác động.
    Và lặp với `confirmImpact = true`.
    Và đo thời gian từ lệnh tới khi cổng từ chối; kiểm ACL Kafka.
    Thì bước 1: `409` ERR-01-034 kèm danh sách phụ thuộc. Bước 2: `200`, `SUSPENDED`, định danh bị chặn. Bước 3: cổng từ chối ≤ 60 giây, ACL Kafka ≤ 2 phút. Đúng một `EVT-01-03` và `EVT-01-07` lan sang phân hệ khác (BR-01-023). KT: có.

  @TC-01-079 @P1 @Âm
  Kịch bản: TC-01-079 Tạm ngừng sai điều kiện
    # Truy vết: FR-01-029 · API-01-051 · ERR-01-005, 033, 035, 001.
    Biết `HT-HOTICH` DRAFT; `HT-QLVB`; U-T68-OR1; U-T01-TA.
    Khi TA1 tạm ngừng không lý do; thiếu MFA mới.
    Và TA1 tạm ngừng `HT-HOTICH` (DRAFT).
    Và OR1 tạm ngừng `HT-QLVB`.
    Và U-T01-TA tạm ngừng `HT-QLVB` của T68.
    Thì `400` ERR-01-033; `403` ERR-01-035; `409` ERR-01-005; `403-PQ`; `404-ẩn`. Không có sự kiện nào phát ra.

  @TC-01-080 @P1 @Dương
  Kịch bản: TC-01-080 Khôi phục khi đủ điều kiện
    # Truy vết: FR-01-030 · UC-01-20 · API-01-052 · UI-01-11 · BR-01-009 · EVT-01-03.
    Biết `HT-QLVB` SUSPENDED lý do `ADMIN`; cấp độ và căn cứ đạt; TA1 có MFA mới.
    Khi `POST …:resume` kèm lý do.
    Thì `200`, `ACTIVE`; định danh được mở lại; `EVT-01-03`. KT: có.

  @TC-01-081 @P1 @Âm @Bảomật
  Kịch bản: TC-01-081 Khôi phục khi nghi lộ bí mật hoặc căn cứ hết hiệu lực
    # Truy vết: FR-01-030 · API-01-052 · BR-01-010, 015 · ERR-01-032, 036.
    Biết `HT-DVC` SUSPENDED lý do `SECURITY_SUSPECT`; `HT-TUPHAP` SUSPENDED vì căn cứ hết hiệu lực; TA1, SO.
    Khi TA1 khôi phục `HT-DVC` khi SO chưa đồng ý.
    Và SO đồng ý nhưng chưa xoay định danh; khôi phục.
    Và xoay định danh; SO khôi phục.
    Và TA1 khôi phục `HT-TUPHAP` khi chưa có căn cứ mới qua thẩm định.
    Thì `409` ERR-01-036; `422` ERR-01-032; bước 3 `200`; bước 4 `422` ERR-01-032.

  @TC-01-082 @P2 @Âm
  Kịch bản: TC-01-082 Thao tác trên HTTT đang tạm ngừng
    # Truy vết: FR-01-029 · API-01-039 · ERR-01-048.
    Biết `HT-DVC` SUSPENDED; TA1.
    Khi tạo liên kết bàn giao cho `HT-DVC`.
    Thì `409` ERR-01-048; thông báo "chờ khôi phục hoặc xoay định danh".
