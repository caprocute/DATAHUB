# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-33
Tính năng: TS-06-33 · Độ chính xác đối sánh

  @TC-06-140 @P1 @Độ @chính @xác
  Kịch bản: TC-06-140 Precision, recall đối sánh trực tuyến
    # Truy vết: NFR-06-008, 009 · BR-06-021 · FR-06-021, 026
    # Mục đích: Chứng minh hợp nhất sai ≤ 0,1 % và bỏ sót ≤ 2 % trên `NHAN-12K`.
    Biết T96 F-LBL 12.000 cặp; bộ quy tắc ACTIVE.
    Khi `eval_accuracy.py` chạy đối sánh trực tuyến cho mọi cặp.
    Và tính ma trận TP, FP, FN, TN theo vùng `MATCH`.
    Thì precision = TP/(TP+FP) ≥ 99,9 %; recall = TP/(TP+FN) ≥ 98 %; báo cáo kèm 1.500 cặp khó riêng, FP ghi từng cặp.
    # Hậu điều kiện: Báo cáo đính kèm hồ sơ RG-3.

  @TC-06-141 @P1 @Độ @chính @xác
  Kịch bản: TC-06-141 Đối sánh lô Splink không kém trực tuyến
    # Truy vết: NFR-06-008, 009 · FR-06-022
    # Mục đích: Chứng minh kết quả Splink đạt cùng ngưỡng và nhất quán với trực tuyến.
    Biết cùng `NHAN-12K`.
    Khi chạy job lô `dryRun` trên tập, đọc kết quả.
    Và so kết luận với acc-pr-online.
    Thì precision ≥ 99,9 %, recall ≥ 98 %; số cặp hai phương pháp khác kết luận ≤ 2 %, tất cả nằm trong vùng `POSSIBLE_MATCH` của ít nhất một phương pháp.
    # Hậu điều kiện: Báo cáo.

  @TC-06-142 @P1 @Độ @chính @xác
  Kịch bản: TC-06-142 Đối sánh xác định đúng 100 %
    # Truy vết: NFR-06-010 · BR-06-001 · FR-06-020
    # Mục đích: Chứng minh khóa hợp lệ cho kết quả đúng tuyệt đối.
    Biết 2.000 cặp khóa hợp lệ (trùng và khác), tên nhiễu.
    Khi chạy `resolve` cho từng cặp.
    Thì 100 % cặp cùng khóa `MATCH`, cặp khác khóa không bao giờ `MATCH`; 0 sai.
    # Hậu điều kiện: Báo cáo.

  @TC-06-143 @P2 @Độ @chính @xác
  Kịch bản: TC-06-143 Độ phủ gom nhóm và tỷ lệ tự động
    # Truy vết: NFR-06-006, 007 · FR-06-019, 027
    # Mục đích: Chứng minh ≤ 50 ứng viên mỗi lượt, độ phủ ≥ 99,5 % và ≥ 85 % ứng viên tự xử lý.
    Biết T96 F-AUTO 100.000 ứng viên, 20 nguồn.
    Khi nạp F-AUTO.
    Và đọc `blocking-stats` và `mdm_auto_rate`.
    Thì trung bình ≤ 50, độ phủ ≥ 99,5 %; tự động ≥ 85 %, vào hàng đợi ≤ 15 %.
    # Hậu điều kiện: Báo cáo.

  @TC-06-144 @P1 @Độ @chính @xác
  Kịch bản: TC-06-144 Ca khó không hợp nhất sai
    # Truy vết: BR-06-006, 015 · FR-06-021
    # Mục đích: Chứng minh cha con, anh em song sinh, trùng tên khác ngày sinh không bị tự hợp nhất.
    Biết 300 cặp khó trong F-LBL.
    Khi chạy đối sánh.
    Thì 0 cặp song sinh, cha con tự `MATCH`; chuyển vào hàng đợi hoặc `NO_MATCH`.
    # Hậu điều kiện: Báo cáo.
