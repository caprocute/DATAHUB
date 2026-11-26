# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-24
Tính năng: TS-17-24 · Quản lý danh mục công cụ chỉ đọc và giới hạn gọi công cụ

  @TC-17-078 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-078 Danh mục công cụ cố định, chỉ đọc, bật tắt theo tenant
    # Truy vết: FR-17-042 · API-17-120, 121, 122 · BR-17-056 · ERR-17-063 · UI-17-10
    # Mục đích: Chứng minh AC-17-12: không có công cụ ghi và tenant không thêm công cụ động.
    Biết T90 bật; U-T90-TA1, U-T90-SO; danh mục công cụ theo mã nguồn (tìm API PH-02, tra danh mục PH-07, xem luồng PH-04, topic PH-10, log PH-13, DLQ PH-18, phân loại PH-09).
    Khi TA1 `GET /tools` và `GET /tools/{toolCode}`.
    Và rà phương thức HTTP của mọi API đích trong danh mục.
    Và SO `PUT /tools/pt-log/enablement` tắt công cụ log.
    Và IE hỏi một câu cần công cụ log.
    Và TA1 `POST /tools` hoặc `PUT /tools/ptx-moi/enablement` với mã công cụ lạ.
    Thì bước 1 mỗi công cụ có API đích, scope đọc, giới hạn. Bước 2 100 % là `GET` hoặc truy vấn chỉ đọc, không `POST/PUT/PATCH/DELETE` ghi. Bước 3 `200`, KT: có, EVT: `assist.config.changed`. Bước 4 trợ lý không gọi công cụ log, ghi `403` ERR-17-063 vào vết công cụ, câu trả lời nói không dùng được công cụ. Bước 5 `404` ERR-17-001 (không có API tạo công cụ).

  @TC-17-079 @P1 @Dương @Biên @Âm
  Kịch bản: TC-17-079 Giới hạn số lần gọi, thời gian chờ, độ sâu, tổng thời gian lượt
    # Truy vết: FR-17-047 · API-17-124, 095 · BR-17-061 · ERR-17-069, 068
    # Mục đích: Chứng minh BR-17-061: vượt thì dừng và báo.
    Biết T90 `17.tool.max-calls-per-turn = 5`, `timeout-seconds = 10`, `max-depth = 3`; LLM-MOCK yêu cầu 7 lần gọi công cụ; công cụ chậm 15 giây.
    Khi TA `PUT /tools/limits` đặt `max-calls-per-turn = 11`.
    Và IE gửi câu hỏi khiến mô hình yêu cầu đúng 5 lần gọi công cụ.
    Và IE gửi câu hỏi khiến mô hình yêu cầu 7 lần gọi công cụ.
    Và khiến mô hình gọi chuỗi 4 tầng công cụ.
    Và khiến một công cụ trả sau 15 giây.
    Và khiến lượt kéo dài hơn 60 giây tổng cộng.
    Thì bước 1 `422` ERR-17-018 (trần 10). Bước 2 `200`, cả 5 lần gọi hoàn tất trong giới hạn. Bước 3 sau 5 lần dừng, `422` ERR-17-069. Bước 4 dừng ở độ sâu 3, báo vượt giới hạn. Bước 5 hết thời gian chờ ở 10 giây, câu trả lời nêu công cụ không phản hồi. Bước 6 `504` ERR-17-068.
