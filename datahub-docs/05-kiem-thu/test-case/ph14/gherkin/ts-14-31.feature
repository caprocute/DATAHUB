# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-31
Tính năng: TS-14-31 · Chuyển đổi từ hệ cũ: nhập cấu hình, chạy song song

  @TC-14-079 @P2 @Dương @Âm
  Kịch bản: TC-14-079 Nhập cấu hình dịch vụ từ phụ lục hệ cũ
    # Truy vết: FR-14-056 · API-14-074 · UI-14-15 · UC-14-38 · ERR-14-032 · BR-14-034 · LGC-NGSP-008.
    Biết U-T68-TA; tệp phụ lục NGSP cũ 20 dịch vụ có Consumer Key mồi; tệp lỗi dòng 7 sai cột.
    Khi `POST /migration/legacy-services:import` tệp hợp lệ.
    Và nhập tệp lỗi.
    Thì 20 đề xuất dịch vụ, Consumer Key và Secret không được lưu (không có mồi trong CSDL, nhật ký), có nhắc cấp lại khóa và xác nhận thu hồi khóa cũ; tệp lỗi `422` ERR-14-032 chỉ rõ dòng 7, cột.

  @TC-14-080 @P2 @Dương @Âm
  Kịch bản: TC-14-080 Chạy song song, đối chiếu, sẵn sàng cắt chuyển
    # Truy vết: FR-14-055 · API-14-072, 073, 089 · UI-14-15 · UC-14-37 · ERR-14-033 · BR-14-033 · LGC-NGSP-001.
    Biết U-T68-TA; dịch vụ đọc V-LLTP; dịch vụ ghi V-HT-DK; hệ cũ giả lập; `14.parallel.match-ratio = 0,99`.
    Khi `POST /migration/parallel-runs` cho V-LLTP; `POST …/{runId}/observations` 1.000 mẫu, 995 khớp.
    Và `GET /migration/parallel-runs/{runId}`.
    Và tạo phiên cho V-HT-DK; tạo phiên thứ hai cho V-LLTP.
    Thì tỷ lệ khớp 99,5 %, trạng thái sẵn sàng khi đủ `14.parallel.min-days` và `14.parallel.min-samples`; khác biệt chỉ cảnh báo, kết quả không bị sửa; bước 3 `409` ERR-14-033 hai lần.

  @TC-14-137 @P1 @Âm
  Kịch bản: TC-14-137 Chạy song song sai: dịch vụ ghi, trùng phiên, đóng khi chưa thu hồi khóa cũ
    # Truy vết: FR-14-055 · API-14-072, 073, 089 · UI-14-15 · UC-14-37 · ERR-14-004, 033 · BR-14-033, 034.
    Biết U-T68-TA, U-T68-IE; V-HT-DK (ghi); V-LLTP (đọc) đã có một phiên chạy song song; hạn mức nền tảng rất thấp; `sim-ndxp` trả kết quả khác nhau giữa đường cũ và đường mới ở một trường.
    Khi `POST /migration/parallel-runs` cho V-HT-DK.
    Và `POST /migration/parallel-runs` lần hai cho V-LLTP.
    Và gửi quan sát có khác biệt ở một trường; đọc kết quả.
    Và đóng phiên khi chưa xác nhận thu hồi khóa cũ ở FR-14-025.
    Và tạo phiên mới với tỷ lệ mẫu 10 % khi hạn mức rất thấp.
    Thì bước 1 `409` ERR-14-033 "Chỉ chạy song song cho thao tác đọc, để không ghi trùng lên hệ thống quốc gia." Bước 2 `409` ERR-14-033 "Dịch vụ này đang chạy song song." Bước 3 `differences[]` nêu đúng trường khác, kết quả hệ thống không bị tự sửa. Bước 4 `409` ERR-14-004. Bước 5 `201`, tỷ lệ mẫu tự giảm kèm cảnh báo, không có lỗi. Lượt đường mới mang ưu tiên `BACKGROUND`.

  @TC-14-138 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-138 Nhập cấu hình hệ cũ sai: tệp lỗi theo dòng cột, bí mật dạng rõ, trùng mã
    # Truy vết: FR-14-056 · API-14-074 · UI-14-15 · UC-14-38 · ERR-14-032 · BR-14-004, 005, 034 · NFR-14-015.
    Biết U-T68-IE, U-T68-SO; tệp `tc-hecu-loi.xlsx` có dòng 7 sai cột `serviceType`; tệp `tc-hecu-bimat.xlsx` có cột `consumer_key` mang `DH-CANARY-LEGACY-…`; dịch vụ `hotich-tra-cuu` đã có.
    Khi nhập tệp có dòng 7 lỗi.
    Và nhập tệp có cột `consumer_key`.
    Và nhập tệp có dòng trùng mã với `onDuplicate = SKIP`, rồi `OVERWRITE`.
    Và nhập ở chế độ `PREVIEW`.
    Thì bước 1 `422` ERR-14-032 "Dòng 7, cột serviceType: {lý do}. Chưa có dữ liệu nào được nhập.", không bản nháp nào được tạo (tất cả hoặc không). Bước 2 giá trị không được lưu, báo cáo `secretsFound[]` chỉ nêu vị trí, cảnh báo cho SO, mồi `DH-CANARY-LEGACY` không có trong PostgreSQL, nhật ký, báo cáo. Bước 3 dòng trùng được bỏ qua hoặc ghi đè theo lựa chọn, ghi vào `duplicates`. Bước 4 `200` và không ghi gì.
