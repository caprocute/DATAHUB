# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-44
Tính năng: TS-17-44 · Chất lượng câu trả lời của bộ đánh giá chuẩn

  @TC-17-159 @P1 @Chất_lượng
  Kịch bản: TC-17-159 recall@8 ≥ 0,85 trên bộ "tìm dịch vụ" (≥ 100 câu hỏi)
    # Truy vết: NFR-17-012 · FR-17-023, 050 · BR-17-034, 066
    # Mục đích: Đo NFR-17-012.
    Biết T96; `ES-SEARCH-1` 120 câu hỏi có đáp án chuẩn; `MV-EMB-1`.
    Khi chạy `POST /eval-runs` cho `ES-SEARCH-1` ở chế độ truy hồi.
    Thì recall@8 ≥ 0,85; kết quả lưu kèm phiên bản nhúng, tham số truy hồi.

  @TC-17-160 @P1 @Chất_lượng
  Kịch bản: TC-17-160 Trích dẫn đúng ≥ 95 %, không tìm thấy ≥ 90 % cho câu hỏi ngoài phạm vi
    # Truy vết: NFR-17-013 · FR-17-025, 023 · BR-17-036
    # Mục đích: Đo NFR-17-013.
    Biết `ES-SEARCH-1` có 90 câu có đáp án và 30 câu ngoài phạm vi.
    Khi chạy `POST /eval-runs` đầy đủ năng lực `SEARCH`.
    Thì ≥ 95 % câu có đáp án kèm trích dẫn đúng; ≥ 90 % câu ngoài phạm vi trả "không tìm thấy".

  @TC-17-161 @P1 @Chất_lượng
  Kịch bản: TC-17-161 Gợi ý ánh xạ top-1 ≥ 70 %, top-3 ≥ 85 %, JQ hợp lệ 100 %
    # Truy vết: NFR-17-014 · FR-17-030, 031, 050 · BR-17-045
    # Mục đích: Đo NFR-17-014.
    Biết `ES-MAP-1` 110 cặp trường và 30 cặp mã danh mục tổng hợp.
    Khi chạy `POST /eval-runs` cho năng lực `MAPPING`.
    Thì top-1 đúng ≥ 70 %, top-3 đúng ≥ 85 %, biểu thức JQ hợp lệ 100 % sau bước kiểm.
