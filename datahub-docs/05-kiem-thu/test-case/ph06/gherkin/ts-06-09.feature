# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-09
Tính năng: TS-06-09 · Tập nhãn, chạy thử, đánh giá và kích hoạt bộ quy tắc

  @TC-06-037 @P1 @Dương @Âm
  Kịch bản: TC-06-037 Tập nhãn: tạo, thêm cặp, khóa; tập quá nhỏ
    # Truy vết: FR-06-025 · API-06-037, 038, 039, 123 · UI-06-13 · ERR-06-002, 003, 006, 026, 051 · PERM-06-steward
    # Mục đích: Chứng minh quản lý tập nhãn `EVALUATION` và chặn tập dưới 1.000 cặp, theo FR-06-025.
    Biết T96; DS1, DS2.
    Khi tạo tập `NHAN-A`, thêm 200 cặp `PairLabel` `MATCH`, `NO_MATCH`; thêm nhãn `MAYBE`.
    Và tạo tập `NHAN-A` lần hai.
    Và chạy đánh giá trên `NHAN-A`.
    Và khóa tập bằng `POST /label-sets/NHAN-A:lock` rồi thêm cặp vào tập đã khóa.
    Thì bước 1 nhận 200 cặp, nhãn `MAYBE` `422` ERR-06-051 (cặp thứ 201 không hợp lệ). Bước 2 `409` ERR-06-002. Bước 3 `422` ERR-06-026. Bước 4 khóa thành công, thêm cặp `409` ERR-06-006; KT: có (label-lock).
    # Hậu điều kiện: Tập `NHAN-A` 200 cặp; F-LBL đã nạp thành `NHAN-12K`.

  @TC-06-038 @P2 @Dương
  Kịch bản: TC-06-038 Chạy thử bộ quy tắc trên mẫu
    # Truy vết: FR-06-024 · API-06-033 · UI-06-09
    # Mục đích: Chứng minh chạy thử cho số cặp theo vùng và mẫu 100 cặp mà không đổi dữ liệu, theo FR-06-024.
    Biết bộ quy tắc v1 DRAFT, T96 có 100.000 ứng viên.
    Khi `POST .../rule-sets/1:dry-run` mẫu 5.000 bản ghi.
    Và đếm bản ghi vàng, ứng viên trước và sau.
    Thì job `RULE_DRY_RUN` `SUCCEEDED`; báo cáo số cặp `MATCH`, `POSSIBLE_MATCH`, `NO_MATCH`, mẫu 100 cặp. Số bản ghi vàng, ứng viên, mục hàng đợi không đổi.
    # Hậu điều kiện: Không đổi dữ liệu.

  @TC-06-039 @P1 @Dương
  Kịch bản: TC-06-039 Đánh giá đạt và kích hoạt có bốn mắt
    # Truy vết: FR-06-026 · BR-06-021 · NFR-06-008, 009 · API-06-034, 035 · EVT-06-11 · PERM-06-approve
    # Mục đích: Chứng minh đánh giá trên `NHAN-12K` cho verdict `PASSED` và kích hoạt qua DA khác, theo FR-06-026.
    Biết bộ quy tắc đã tinh chỉnh; tập `NHAN-12K` 12.000 cặp; DS1, DA1.
    Khi `POST .../rule-sets/2:evaluate` với `NHAN-12K`.
    Và DS1 `submit`, DA1 `approve`.
    Và đọc `t90.mdm.ruleset.activated.v1`.
    Thì báo cáo precision ≥ 99,9 %, recall ≥ 98 %, ma trận nhầm lẫn TP, FP, FN, TN, `EvaluationVerdict = PASSED`. Bộ quy tắc `ACTIVE`, bản cũ `SUPERSEDED`, một bản tin EVT-06-11. KT: có (ruleset-activate).
    # Hậu điều kiện: Bộ quy tắc v2 ACTIVE ở T96.

  @TC-06-040 @P1 @Âm
  Kịch bản: TC-06-040 Đánh giá không đạt chặn kích hoạt
    # Truy vết: FR-06-026 · BR-06-021 · API-06-034, 035 · ERR-06-024, 005 · `06.match.auto-disable-on-fail`
    # Mục đích: Chứng minh bộ quy tắc precision 99,5 % không kích hoạt được và tự hợp nhất bị tắt khi đánh giá tháng không đạt, theo FR-06-026.
    Biết bộ quy tắc v3 cố ý nới (trọng số tên thấp); `06.match.auto-disable-on-fail = true`.
    Khi `evaluate` v3.
    Và `submit` rồi `approve` v3.
    Và chạy đánh giá định kỳ tháng trên bộ `ACTIVE` đã bị làm nhiễu.
    Thì bước 1 `FAILED`, precision 99,5 %. Bước 2 `422` ERR-06-024 "Phiên bản 3 chưa đạt: precision 99,5%, recall …". Bước 3 tự hợp nhất bị tắt, mọi `MATCH` trực tuyến thành `POSSIBLE_MATCH`, cảnh báo PH-13 (ĐN-UC-07).
    # Hậu điều kiện: v3 không ACTIVE.

  @TC-06-152 @P1 @Dương @Âm
  Kịch bản: TC-06-152 Khóa tập nhãn và chặn sửa tập đã khóa
    # Truy vết: FR-06-025 · API-06-123, 039 · ERR-06-006, 051 · ERR-00-403, ERR-00-428 · PERM-06-steward
    # Mục đích: Chứng minh khóa tập nhãn dùng cho đánh giá chính thức, khóa rồi không mở lại, theo FR-06-025 (API-06-123).
    Biết T96; tập `NHAN-B` 300 cặp chưa khóa; DS1 (`PERM-06-steward`), VW1 (chỉ `PERM-06-read`).
    Khi VW1 `POST /label-sets/NHAN-B:lock`.
    Và DS1 `POST /label-sets/NHAN-B:lock` không có `If-Match`.
    Và DS1 `:lock` kèm `If-Match` đúng.
    Và DS1 `:lock` lần hai rồi `POST /label-sets/NHAN-B/pairs` thêm một cặp.
    Và thêm một cặp có `leftRef` trùng `rightRef` vào tập `NHAN-C` chưa khóa.
    Thì bước 1 `403` ERR-00-403. Bước 2 `428` ERR-00-428. Bước 3 `200`, `locked = true`, người khóa và thời điểm; KT: có (label-lock). Bước 4 `409` ERR-06-006, thêm cặp `409` ERR-06-006; muốn thêm cặp phải tạo tập phiên bản mới. Bước 5 `422` ERR-06-051 (hai tham chiếu trùng nhau).
    # Hậu điều kiện: `NHAN-B` khóa, 300 cặp.

  @TC-06-153 @P1 @Âm @Dương
  Kịch bản: TC-06-153 Đánh giá tháng không đạt: tự tắt tự hợp nhất và bật lại
    # Truy vết: FR-06-026 · BR-06-021 · API-06-034, 087 · ERR-06-024 · EVT-06-11 · `06.match.auto-disable-on-fail` · PERM-06-config
    # Mục đích: Chứng minh tham số `06.match.auto-disable-on-fail` điều khiển việc tắt tự hợp nhất khi đánh giá tháng không đạt, theo FR-06-026 bước 5.
    Biết T96; bộ quy tắc `ACTIVE` v2 bị làm nhiễu (precision 99,4 %); tenant T96 đặt `true`, tenant T97 đặt `false`.
    Khi chạy đánh giá định kỳ tháng trên T96.
    Và nạp ứng viên có điểm vùng `MATCH` ở T96.
    Và chạy đánh giá định kỳ tháng trên T97.
    Và Ở T96, kích hoạt phiên bản bộ quy tắc mới đạt chuẩn qua bốn mắt.
    Thì bước 1 `FAILED`, tự hợp nhất bị tắt ở T96, kiểm toán và cảnh báo PH-13 nêu hệ quả. Bước 2 mọi `MATCH` trực tuyến thành `POSSIBLE_MATCH` vào hàng đợi, không hợp nhất tự động. Bước 3 T97 giữ tự hợp nhất, chỉ cảnh báo. Bước 4 tự hợp nhất bật lại ở phiên bản mới, KT: có.
    # Hậu điều kiện: T96 bật lại tự hợp nhất bằng phiên bản đạt chuẩn.
