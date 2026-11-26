# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-06
Tính năng: TS-09-06 · Nhãn bí mật nhà nước và chặn dữ liệu

  @TC-09-017 @P1 @Dương @Bảo @mật
  Kịch bản: TC-09-017 Gán nhãn rồi bản tin có trường nhãn bị chặn toàn bộ
    # Truy vết: FR-09-007 · API-09-004, 231 · BR-09-005 · ERR-09-101 · EVT-09-14
    # Mục đích: Chứng minh chặn cả bản tin, không lọc từng trường, không nêu trường nào mang nhãn (BR-09-005).
    Biết T90; phần tử `soHieuMat` đề nghị nhãn; U-T90-SO, U-T90-DO1; S-T90-PEP-04; bản tin F-MSG có 8 trường kèm `soHieuMat`.
    Khi SO `POST /secret-labels` gán `STATE_SECRET` cho `soHieuMat`.
    Và PEP `POST /privacy/v1/classification:check` với F-MSG.
    Thì bước 2 `403` ERR-09-101 "Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước."; thân không nêu tên trường, không trả trường nào khác; EVT: `secret-label.blocked` (cảnh báo nghiêm trọng tới SO); KT: có (secret-block).

  @TC-09-018 @P1 @Âm
  Kịch bản: TC-09-018 Đăng ký phần tử mang nhãn bí mật hoặc lược đồ có trường nhãn
    # Truy vết: FR-09-007 · API-09-012, 013 · ERR-09-018
    # Mục đích: Chứng minh dữ liệu mang nhãn không được đưa vào Datahub.
    Biết T90; nhãn `STATE_SECRET` đã gán; U-T90-DS1.
    Khi DS1 nhập lược đồ chứa trường `soHieuMat`.
    Và S-T90-REG đăng ký phần tử đích trùng phần tử có nhãn.
    Thì cả hai `422` ERR-09-018, không phần tử nào được tạo; EVT: `secret-label.blocked`.

  @TC-09-019 @P1 @Dương @Âm
  Kịch bản: TC-09-019 Gỡ nhãn cần số và ngày văn bản giải mật, người thứ hai duyệt
    # Truy vết: FR-09-007 · API-09-005, 006 · ERR-09-019, 005 · BR-09-005, 057
    # Mục đích: Chứng minh gỡ nhãn có hai người và bằng chứng giải mật.
    Biết T90; nhãn của ca lbl-block; U-T90-SO, U-T90-TA.
    Khi SO `POST /secret-labels/{id}:request-release` thiếu số văn bản.
    Và SO đề nghị kèm `declassificationDoc = GM-09/2026`, ngày 2026-11-01.
    Và SO tự `:approve-release`.
    Và TA `:approve-release`.
    Thì bước 1 `422` ERR-09-019. Bước 3 `403` ERR-09-005. Bước 4 `200`, nhãn `RELEASED`, KT: có (secret-label-release) gồm số văn bản. `classification:check` sau đó cho qua.

  @TC-09-020 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-09-020 Không ghi được nhật ký thì không gỡ nhãn
    # Truy vết: FR-09-007 · BR-09-057 · ERR-09-010 · API-09-006
    # Mục đích: Chứng minh thao tác đặc quyền bị từ chối khi không ghi được kiểm toán (BR-09-057).
    Biết T94; nhãn đã có đề nghị gỡ; PH-13 giả lập trả `503`.
    Khi TA `:approve-release` khi PH-13 ngừng.
    Thì `503` ERR-09-010, nhãn còn `STATE_SECRET`; bật lại PH-13 thì thao tác chạy được.
