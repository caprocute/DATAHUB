# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-32
Tính năng: TS-09-32 · Hồ sơ đánh giá tác động DPIA

  @TC-09-109 @P1 @Dương
  Kịch bản: TC-09-109 Lập, gửi duyệt, duyệt bốn mắt, xuất hồ sơ A05, ghi số công văn
    # Truy vết: FR-09-055, 056, 057 · API-09-193, 196, 197, 200, 201 · UI-09-18 · BR-09-052
    # Mục đích: Chứng minh hồ sơ bên kiểm soát và hồ sơ bên xử lý đi đủ vòng đời đến `SUBMITTED_A05`.
    Biết T90; HD-01 `ACTIVE`; U-T90-SO (soạn), U-T90-DA1.
    Khi SO `POST /dpia-records` loại `PROCESSING`, đủ mục; `:submit`.
    Và DA1 `:approve`.
    Và SO `:export-a05`; tải tệp; `:mark-submitted` số công văn `CV-A05-01`.
    Thì bước 2 `ACTIVE`, KT: có. Bước 3 tệp theo mẫu A05, không giá trị DLCN, `DpiaStatus = SUBMITTED_A05`.

  @TC-09-110 @P1 @Âm
  Kịch bản: TC-09-110 Thiếu mục, tự duyệt, xuất khi chưa duyệt
    # Truy vết: FR-09-055, 056, 057 · API-09-196, 197, 200 · ERR-09-073, 005, 074
    # Mục đích: Chứng minh kiểm đủ mục và chưa duyệt không xuất.
    Biết T90; hồ sơ nháp thiếu "biện pháp bảo vệ"; U-T90-SO, U-T90-DA1.
    Khi SO `:submit` hồ sơ thiếu biện pháp bảo vệ.
    Và SO gửi hồ sơ đủ rồi tự `:approve`.
    Và SO `:export-a05` hồ sơ chưa duyệt.
    Thì bước 1 `422` ERR-09-073 nêu mục thiếu. Bước 2 `403` ERR-09-005. Bước 3 `409` ERR-09-074.

  @TC-09-111 @P2 @Dương
  Kịch bản: TC-09-111 Đến hạn rà soát 12 tháng, nhắc trước 30 ngày
    # Truy vết: FR-09-056 · API-09-199 · EVT-09-29 · BR-09-053
    # Mục đích: Chứng minh nhắc rà soát đúng hạn.
    Biết T95 đồng hồ giả; hồ sơ duyệt cách 11 tháng; `09.dpia.review-months = 12`.
    Khi tiến đồng hồ đến 335 ngày; `GET /dpia-records:reviews-due`.
    Thì hồ sơ có trong danh sách, EVT: `dpia.review-due` đúng một lần cho SO; thêm hoạt động rủi ro làm hồ sơ cần rà soát sớm.
