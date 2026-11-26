# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-35
Tính năng: TS-17-35 · Gợi ý cho bước quy trình PH-11, luôn có người quyết định cuối

  @TC-17-114 @P3 @Dương
  Kịch bản: TC-17-114 Gợi ý bước quy trình có người quyết định cuối và ghi nhận quyết định
    # Truy vết: FR-17-061 · API-17-190, 191, 192 · BR-17-083 · EVT-17-28
    # Mục đích: Chứng minh BR-17-083.
    Biết T90 bật; S-T90-PH11 có `assist:infer`; hồ sơ tổng hợp ở bước duyệt có biểu mẫu.
    Khi S-T90-PH11 `POST /assist/v1/process-suggestions` với bước `DUYET`.
    Và S-T90-PH11 `POST /assist/v1/process-suggestions/{id}:record-decision` với quyết định của người có thẩm quyền.
    Thì bước 1 `200`, `humanDecisionRequired = true`, có điểm tin cậy và lý do. Bước 2 `200`, EVT: `assist.process-suggestion.decided`, tính vào chỉ số chất lượng.

  @TC-17-115 @P2 @Âm @Bảo_mật
  Kịch bản: TC-17-115 Yêu cầu tự quyết bị từ chối, gợi ý không tồn tại
    # Truy vết: FR-17-061 · API-17-190, 191 · BR-17-083 · ERR-17-114, 117
    # Mục đích: Chứng minh không có cấu hình tự duyệt.
    Biết S-T90-PH11.
    Khi S-T90-PH11 `POST /assist/v1/process-suggestions` với `autoDecide = true`.
    Và S-T90-PH11 `:record-decision` cho `SG-khong-co`.
    Thì bước 1 `403` ERR-17-114. Bước 2 `404` ERR-17-117.
