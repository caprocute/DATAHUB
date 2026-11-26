# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-25
Tính năng: TS-09-25 · Ẩn danh hóa, k tối thiểu 10 và rủi ro tái định danh

  @TC-09-085 @P1 @Âm
  Kịch bản: TC-09-085 Ngưỡng k dưới 10, còn trường định danh trực tiếp
    # Truy vết: FR-09-035 · API-09-126, 129 · ERR-09-051, 052 · BR-09-035, 036
    # Mục đích: Chứng minh sàn k = 10 (SEC-38) và loại trường định danh trực tiếp.
    Biết T96; `09.anon.k-min = 10`; U-T90-DS1, DA1.
    Khi DS1 `POST /anonymization-configs` với `k = 5`.
    Và DS1 tạo cấu hình k = 10 còn `cccd` (`DIRECT`) chưa `REMOVE`; DA1 `:approve`.
    Thì bước 1 `422` ERR-09-051 "Ngưỡng k phải từ 10 trở lên." Bước 2 `422` ERR-09-052 nêu `cccd`.

  @TC-09-086 @P1 @Dương
  Kịch bản: TC-09-086 Chạy ẩn danh hóa đạt k thực tế ≥ 10 và rủi ro không HIGH
    # Truy vết: FR-09-036, 037 · API-09-130, 132, 134 · BR-09-034, 035 · NFR-09-012
    # Mục đích: Chứng minh kết quả kiểm chứng k thực tế và không lưu ánh xạ.
    Biết T96 F-ANON 200.000 bản ghi giả (ngày sinh, mã xã, giới tính, nghề; thuộc tính nhạy cảm `bệnh`); cấu hình k = 10 `ACTIVE`.
    Khi DS1 `POST /anonymization-jobs`.
    Và hỏi `GET /anonymization-jobs/{id}` đến `COMPLETED`; `GET .../risk-report`.
    Và đếm kích thước nhóm nhỏ nhất trên tập đầu ra bằng công cụ độc lập.
    Thì `202`, `COMPLETED`, `kActual ≥ 10`, rủi ro `LOW`, số bản ghi trước và sau; nhóm nhỏ nhất ≥ 10 bản ghi; không bảng ánh xạ hoặc khóa giải. Mã `cccd` bị loại hoàn toàn.

  @TC-09-087 @P1 @Âm
  Kịch bản: TC-09-087 Không đạt k sau ba vòng, rủi ro HIGH, rủi ro MEDIUM cần SO duyệt
    # Truy vết: FR-09-036, 037 · API-09-130, 135, 136 · ERR-09-053, 054 · BR-09-035
    # Mục đích: Chứng minh chặn `HIGH`, từ chối tập quá ít và `MEDIUM` cần SO.
    Biết T96 F-ANON-S 500 bản ghi nhiều giá trị độc nhất; tập F-ANON-M rủi ro 0,07; U-T90-SO.
    Khi chạy job trên F-ANON-S.
    Và `POST /risk-assessments` cho tập có rủi ro 0,12.
    Và chạy job cho F-ANON-M rồi DS1 phát hành; SO `:approve-risk`.
    Thì bước 1 `422` ERR-09-054 nêu % bản ghi còn lại (< 30 %), `REJECTED_RISK` hoặc `FAILED`. Bước 2 `HIGH`, `422` ERR-09-053 khi phát hành. Bước 3 `AWAITING_RISK_REVIEW`, chỉ phát hành sau khi SO duyệt.

  @TC-09-088 @P3 @Dương
  Kịch bản: TC-09-088 l-đa dạng khi bật và hủy job đang chạy
    # Truy vết: FR-09-035, 036 · API-09-128, 133 · BR-09-036
    # Mục đích: Chứng minh thuộc tính nhạy cảm đạt l-đa dạng và hủy job giải phóng tài nguyên.
    Biết T96; cấu hình bật `L_DIVERSITY` với `l = 3` cho `bệnh`.
    Khi chạy job; kiểm l-đa dạng của đầu ra.
    Và chạy job lần hai rồi `POST /anonymization-jobs/{id}:cancel` giữa chừng.
    Thì bước 1 mọi nhóm có ≥ 3 giá trị `bệnh` khác nhau. Bước 2 `CANCELLED`, Job K8s dừng, không tập đầu ra.

  @TC-09-089 @P1 @Bảo @mật
  Kịch bản: TC-09-089 k ≥ 10 ở mọi tập phát hành (kiểm thuộc tính)
    # Truy vết: FR-09-036 · BR-09-035 · NFR-09-012
    # Mục đích: Chứng minh 100 % tập phát hành có k thực tế ≥ k cấu hình.
    Biết T96; 20 tập sinh ngẫu nhiên hạt cố định, k cấu hình 10…20.
    Khi chạy 20 job với hạt khác nhau, kiểm tập đầu ra bằng kiểm độc lập.
    Thì 20/20 tập có k thực tế ≥ k cấu hình; không tập `HIGH` nào phát hành.
