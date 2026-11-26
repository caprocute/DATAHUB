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
