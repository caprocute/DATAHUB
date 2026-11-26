# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-26
Tính năng: TS-09-26 · Chuẩn bị dữ liệu cho AI, môi trường không phải PROD và tập đã ẩn danh

  @TC-09-090 @P1 @Dương
  Kịch bản: TC-09-090 Chuẩn bị dữ liệu AI chỉ ẩn danh, RESTRICTED khi bật và chạy nội bộ
    # Truy vết: FR-09-038 · API-09-137, 138 · BR-09-037 · ERR-09-003 · EVT-09-18
    # Mục đích: Chứng minh dữ liệu cho AI chỉ ẩn danh và `RESTRICTED` cần cờ tenant (SEC-38, SEC-49).
    Biết T96; `09.ai.allow-restricted = false`; PH-17 giả lập; U-T90-DS1.
    Khi DS1 `POST /data-preparations` đích `AI_TRAINING` cho tập `RESTRICTED`.
    Và bật `09.ai.allow-restricted = true`, mô hình chạy nội bộ; lặp lại.
    Thì bước 1 `400` ERR-09-003 (FRS chưa có mã riêng cho cờ tắt, đề nghị ở ĐN-TC-04). Bước 2 `202`, tập ẩn danh k ≥ 10, siêu dữ liệu nêu cấu hình, EVT: `dataset.status-changed` khi phát hành.

  @TC-09-091 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-091 Đích không PROD dùng dữ liệu SENSITIVE thật bị cấm, mục đích không cho phép
    # Truy vết: FR-09-038 · API-09-137 · ERR-09-055 · BR-09-037
    # Mục đích: Chứng minh `NON_PROD_TEST` chỉ nhận dữ liệu sinh hoặc giả danh không đảo ngược.
    Biết T96; U-T90-DS1; mục đích `MD-THONGKE` không cho trường Nhạy cảm.
    Khi DS1 chuẩn bị `NON_PROD_TEST` từ bảng `SENSITIVE` thật, không giả danh.
    Và DS1 chuẩn bị `OPEN_DATA` cho mục đích `MD-THONGKE` có trường Nhạy cảm.
    Thì cả hai `422` ERR-09-055 "Mục đích MD-THONGKE không cho phép dùng dữ liệu có trường Nhạy cảm."; không tập nào được tạo.

  @TC-09-092 @P2 @Dương @Âm
  Kịch bản: TC-09-092 Phát hành, sửa điều kiện, rút lại tập, hết hạn
    # Truy vết: FR-09-039 · API-09-142, 143, 144, 140 · ERR-09-056 · EVT-09-18
    # Mục đích: Chứng minh tập `PUBLISHED` không sửa được, chỉ rút lại và tạo tập mới.
    Biết T96; tập `READY` từ ca anon-run.
    Khi DS1 `PUT .../terms` rồi `:publish`.
    Và DS1 `PUT .../terms` lần hai.
    Và DS1 `:withdraw`.
    Thì bước 1 `PUBLISHED`. Bước 2 `409` ERR-09-056. Bước 3 `WITHDRAWN`; EVT: `dataset.status-changed` mỗi lần đổi trạng thái.
