# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-34
Tính năng: TS-17-34 · Suy luận nội bộ cho bước luồng PH-04 (phân loại văn bản, trích thông tin)

  @TC-17-110 @P1 @Dương @Hiệu_năng
  Kịch bản: TC-17-110 Phân loại và trích thông tin có mục đích, mức dữ liệu, đầu ra đúng lược đồ
    # Truy vết: FR-17-060 · API-17-187, 188, 189, 192 · BR-17-019, 080, 082 · NFR-17-022 · UI-17-17
    # Mục đích: Chứng minh data plane hoạt động qua cổng mô hình với vết lời gọi.
    Biết T90 bật; S-T90-PH04 có `assist:infer`, mTLS SPIFFE hợp lệ; `MV-CHAT-1` giả lập trả cố định 100 ms; văn bản tổng hợp 600 ký tự `INTERNAL`.
    Khi `GET /assist/v1/inference/tasks`.
    Và `POST /assist/v1/inference/classify` với `purposeCode = MD-PHANLOAI`, `dataClass = INTERNAL`, `tenant = T90`.
    Và `POST /assist/v1/inference/extract`.
    Và đo thời gian thêm so với gọi thẳng mô hình (1.000 lần).
    Thì bước 1 liệt kê `CLASSIFY_TEXT`, `EXTRACT_FIELDS` kèm phiên bản lược đồ. Bước 2 và 3 `200`, đầu ra khớp lược đồ JSON của nhiệm vụ, vết lời gọi ghi mô hình, DU gọi. Bước 4 độ trễ thêm p95 ≤ 50 ms.

  @TC-17-111 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-111 Thiếu scope, thiếu mục đích, nhiệm vụ lạ, đầu vào sai lược đồ hoặc quá dài
    # Truy vết: FR-17-060 · API-17-187, 188 · BR-17-080, 082 · ERR-17-101, 102, 105, 106, 113 · ERR-00-401
    # Mục đích: Chứng minh ERR-17-101, 102, 105, 106, 113.
    Biết S-T90-NOSCOPE, S-T90-PH04; `17.input.max-chars = 4.000`.
    Khi S-T90-NOSCOPE `POST /assist/v1/inference/classify`.
    Và gọi không có mTLS hợp lệ.
    Và S-T90-PH04 gọi thiếu `purposeCode` hoặc `dataClass`.
    Và gọi `POST /assist/v1/inference/translate`.
    Và gọi `extract` với trường `fields` sai kiểu.
    Và gọi `classify` văn bản 5.000 ký tự.
    Thì bước 1 `403` ERR-17-101. Bước 2 từ chối kết nối (không tới ứng dụng). Bước 3 `422` ERR-17-102. Bước 4 `422` ERR-17-105. Bước 5 `422` ERR-17-106. Bước 6 `422` ERR-17-113 (tối đa 4.000 ký tự).

  @TC-17-112 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-17-112 Tắt, tắt khẩn, hạn mức DU, chưa có mô hình, cầu dao, hết giờ, đầu ra sai lược đồ, DLCN chưa che
    # Truy vết: FR-17-060, 012 · API-17-187, 188 · BR-17-082, 085 · ERR-17-103, 104, 108, 109, 110, 111, 112, 115
    # Mục đích: Chứng minh ERR-17-103, 104, 108…112, 115 và hạn mức DU.
    Biết S-T90-PH04; `17.quota.du-calls-per-minute = 10`; T93 tắt.
    Khi gọi `classify` ở T93.
    Và gọi khi T90 `KILLED`.
    Và gọi nhiệm vụ chưa có mô hình `APPROVED`.
    Và gọi 11 lần trong một phút.
    Và mở cầu dao rồi gọi.
    Và LLM-MOCK treo 20 giây (thời gian chờ 10 giây).
    Và LLM-MOCK trả JSON sai lược đồ.
    Và gửi văn bản có CCCD giả dạng rõ.
    Thì bước 1 `403` ERR-17-103. Bước 2 `403` ERR-17-104. Bước 3 `409` ERR-17-108. Bước 4 lần 11 `429` ERR-17-109. Bước 5 `503` ERR-17-110. Bước 6 `504` ERR-17-111. Bước 7 `502` ERR-17-112, đầu ra bị loại. Bước 8 `422` ERR-17-115.

  @TC-17-113 @P1 @Bảo_mật @Âm
  Kịch bản: TC-17-113 Data plane chéo tenant và tài khoản máy của tenant khác
    # Truy vết: FR-17-060 · API-17-187, 192 · BR-17-080, 086 · NFR-17-007 · ERR-17-101
    # Mục đích: Chứng minh DU của T91 không gọi được cho T90.
    Biết S-T91-PH04 có `assist:infer` ở T91; T90 bật.
    Khi S-T91-PH04 `POST /assist/v1/inference/classify` với `tenant = T90`.
    Và S-T91-PH04 `GET /assist/v1/config/effective` với `tenant = T90`.
    Thì cả hai `403` hoặc `404`, không trả cấu hình hay kết quả của T90, không có vết lời gọi ở T90.
