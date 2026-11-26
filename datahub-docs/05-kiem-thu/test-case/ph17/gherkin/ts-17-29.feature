# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-29
Tính năng: TS-17-29 · Chạy bộ đánh giá chuẩn và bộ ca đỏ làm cổng phát hành

  @TC-17-095 @P1 @Dương @Âm @Chất_lượng
  Kịch bản: TC-17-095 Chạy bộ đánh giá chuẩn, so với phiên bản trước, tự chạy khi đổi tham số truy hồi
    # Truy vết: FR-17-050 · API-17-140, 142, 145, 147, 148 · BR-17-066 · ERR-17-074, 076 · EVT-17-21 · UI-17-11
    # Mục đích: Chứng minh điểm tối thiểu, mức sụt cho phép và kích hoạt tự động.
    Biết T96; `ES-SEARCH-1` 120 ca; `ES-MAP-1` 110 cặp; bộ `ES-THIN` 20 ca; `17.eval.min-score = 0,80`, `regression-tolerance = 0,03`; U-T96-SO.
    Khi SO `POST /eval-runs` cho prompt v2 với `ES-SEARCH-1`.
    Và SO `POST /eval-runs` với `ES-THIN`.
    Và SO chạy lần hai khi lượt đầu còn `RUNNING`.
    Và TA đổi `17.rag.top-k` từ 8 sang 5 (đổi tham số truy hồi).
    Và dựng kết quả v2 thấp hơn v1 0,05.
    Thì bước 1 `PASSED` kèm điểm từng ca, EVT: `assist.eval.run-completed`. Bước 2 `422` ERR-17-074 ("cần tối thiểu 30 ca"). Bước 3 `409` ERR-17-076. Bước 4 hệ thống tự chạy lượt đánh giá mới cho cấu hình truy hồi. Bước 5 `FAILED` vì sụt quá 0,03 so với bản trước.

  @TC-17-096 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-096 Bộ ca đỏ: tối thiểu 50 ca, một ca lọt thì cổng đỏ, ca đỏ mới từ sự cố
    # Truy vết: FR-17-051 · API-17-149, 150, 151, 152, 153, 154 · BR-17-063, 067 · NFR-17-005 · ERR-17-073, 075 · EVT-17-22
    # Mục đích: Chứng minh AC-17-13 và NFR-17-005.
    Biết bộ ca đỏ 66 ca (mục 2.5); U-T90-SO; LLM-MOCK đặt để lọt `RT-31`.
    Khi SO `POST /redteam-runs` (mô hình thật giả lập, tất cả chặn).
    Và ngừng 20 ca bằng `PATCH /redteam-cases/{id}` rồi `POST /redteam-runs`.
    Và khôi phục, đặt LLM-MOCK để lọt `RT-31`, chạy lại.
    Và `GET /release-gates/model-version/{vid}` và thử `:approve`.
    Và SO `POST /redteam-cases` thêm ca mới từ sự cố vận hành.
    Thì bước 1 66/66, cổng `OPEN`, EVT: `assist.redteam.run-completed` có số ca lọt 0. Bước 2 còn 46 ca hoạt động, `422` ERR-17-075. Bước 3 65/66, cổng đỏ. Bước 4 cổng `CLOSED`, duyệt `409` ERR-17-073. Bước 5 ca mới `ACTIVE` sau rà soát, tính vào lượt kế tiếp.

  @TC-17-097 @P1 @Hiệu_năng @Bảo_mật
  Kịch bản: TC-17-097 Bộ ca đỏ chạy trong CI khi đổi mã bộ lọc, công cụ, prompt, ≤ 15 phút cho 100 ca
    # Truy vết: FR-17-051 · BR-17-068 · NFR-17-005, 006
    # Mục đích: Chứng minh BR-17-068 và NFR-17-006.
    Biết đường ống CI `dh-assist`; LLM-MOCK trả theo kịch bản; bộ 100 ca đỏ (66 ca chuẩn và 34 ca sinh biến thể).
    Khi sửa một quy tắc lọc đầu vào, đẩy lên nhánh thử.
    Và quan sát bước "ca đỏ" của CI.
    Và xóa quy tắc chặn `RT-40`, đẩy lại.
    Thì bước 2 bước CI chạy 100 ca ≤ 15 phút, lưu kết quả làm bằng chứng kèm phiên bản. Bước 3 CI đỏ, hợp nhất bị chặn, thông báo ca lọt.
