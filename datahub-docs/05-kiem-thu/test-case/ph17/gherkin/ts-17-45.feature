# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-45
Tính năng: TS-17-45 · Tương đương hệ cũ và chức năng cũ của SRS repo

  @TC-17-162 @P2 @Dương
  Kịch bản: TC-17-162 Người dùng làm được việc của hệ cũ nhanh hơn và đúng quyền
    # Truy vết: FR-17-023, 030, 036 · LGC-BUS-002, 003, 004 · LGC-TOOL-007, 028 · LGC-BUS-027, 029, 037
    # Mục đích: Chứng minh ba nhóm hệ cũ (tìm chương trình tích hợp bằng bộ lọc, công cụ ánh xạ dữ liệu, log agent và xử lý lỗi) vẫn hoạt động độc lập khi trợ lý tắt.
    Biết STAGING T68; T90 trợ lý tắt rồi bật; U-T68-IE.
    Khi với trợ lý tắt: tìm chương trình tích hợp bằng bộ lọc từ khóa, ánh xạ trường bằng trình ánh xạ, xem log lỗi luồng.
    Và bật trợ lý: lặp ba việc bằng trợ lý.
    Thì bước 1 ba việc hoàn tất bằng bộ lọc, trình ánh xạ, màn log, không phụ thuộc PH-17. Bước 2 kết quả trợ lý khớp kết quả bộ lọc và nhanh hơn số thao tác (so sánh số bước), mọi kết quả trong phạm vi quyền.

  @TC-17-163 @P3 @Dương @Âm
  Kịch bản: TC-17-163 Đối chiếu 17 FR cũ của SRS repo có ca chứng minh
    # Truy vết: FR-17-010, 011, 013, 033, 048, 055, 060, 061, 062
    # Mục đích: Chứng minh bảng ánh xạ FR cũ sang FR mới ở FRS mục 11.3 và các điểm thay đổi chủ ý (không MLflow, Evidently, camel-langchain4j).
    Biết FRS mục 11.3; mục 7.2 của tập này.
    Khi với từng FR cũ trong bảng 7.2 kiểm ca được nêu.
    Và tìm đường dẫn `/ai/v1/` và `/api/admin/v1/ai/` trong hợp đồng OpenAPI.
    Và quét cấu hình tìm MLflow, Evidently.
    Thì bước 1 mọi FR cũ có ít nhất một ca đạt. Bước 2 và 3 không có đường dẫn cũ, không có thành phần MLflow, Evidently (thay bằng sổ mô hình và bộ đánh giá).
