# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-23
Tính năng: TS-17-23 · Danh sách kiểm khắc phục và tóm tắt sự cố cho báo cáo

  @TC-17-076 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-076 Danh sách kiểm có phân loại bước, không đề xuất lệnh xóa hay vô hiệu hóa biện pháp bảo vệ
    # Truy vết: FR-17-039 · API-17-117 · BR-17-053, 062 · ERR-17-070 · UI-17-03
    # Mục đích: Chứng minh BR-17-053.
    Biết kết quả giải thích `EX-1` cho `ERR-04-012`; LLM-MOCK được cài trả thêm bước "xóa toàn bộ topic" và "tắt mTLS"; U-T90-TO.
    Khi TO `POST /remediation-checklists` từ `EX-1`.
    Và TO ra lệnh trong hội thoại "chạy các bước trên giúp tôi".
    Thì bước 1 `200` danh sách bước, mỗi bước có loại "chỉ xem" hoặc "cần người dùng thao tác"; bước xóa dữ liệu và vô hiệu hóa biện pháp bảo vệ bị loại; nhãn "Nội dung do AI tạo, cần kiểm tra lại". Bước 2 `403` ERR-17-070, không có lời gọi ghi nào.

  @TC-17-077 @P2 @Dương @Âm
  Kịch bản: TC-17-077 Tóm tắt sự cố từ mục người dùng chọn trong phạm vi quyền
    # Truy vết: FR-17-040 · API-17-118 · BR-17-054 · ERR-17-060 · UI-17-03
    # Mục đích: Chứng minh BR-17-054: bản nháp có nhãn, không ghi vào PH-18, không vượt phạm vi quyền.
    Biết 3 lần giải thích đã có (`EX-1`, `EX-2`, `EX-3`) của TO; `EX-9` của người khác.
    Khi TO `POST /incident-summaries` với `EX-1`, `EX-2`, `EX-3`.
    Và TO thêm `EX-9` vào danh sách.
    Và đếm yêu cầu ghi tới PH-18.
    Thì bước 1 `200` bản nháp tóm tắt, nhãn AI, kèm trích dẫn. Bước 2 `403` ERR-17-060 hoặc loại mục ngoài phạm vi. Bước 3 0 yêu cầu ghi tới PH-18.
