# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-11
Tính năng: TS-08-11 · Đo theo lô, đối chiếu danh mục PH-07 và ghi bản ghi lỗi

  @TC-08-056 @P1 @Dương
  Kịch bản: TC-08-056 Thực thi quy tắc theo lô trên mẫu F-SCORE
    # Truy vết: FR-08-026 · API-08-061, 064 · UI-08-12 · BR-08-004, 025
    Biết `mdm-citizen` với F-SCORE (bảng 2.4): 10.000 bản ghi, 6 quy tắc; lần đo `FULL`.
    Khi `POST /scans` `{mode: FULL}` chờ `SUCCEEDED`
    Và `GET /scans/{id}/rule-results`
    Và đọc nhật ký truy vấn của `mdm-sim`
    Thì `rule-results` khớp bảng 2.4: `R-CCCD-NN` pass 9.800, fail 200; `R-CCCD-RX` pass 9.500, fail 500; `R-NS-EQ` pass 4.000, fail 1.000; `R-CAPNHAT` pass 9.000, fail 1.000; `R-CCCD-UQ` pass 9.900, fail 100; `R-GT-RDM` pass 8.500, fail 1.500. Nhật ký nguồn chỉ có truy vấn tập hợp `SELECT count(*) FILTER (...)` và truy vấn khóa lỗi có `LIMIT`, không kéo toàn bộ bản ghi về PH-08.

  @TC-08-057 @P2 @Dương
  Kịch bản: TC-08-057 Lấy mẫu tái lập theo seed
    # Truy vết: FR-08-026 · API-08-059, 064 · BR-08-019 · NFR-08-008
    Biết `src-hotich` F-HT 5.000 dòng.
    Khi `POST /scans` `{mode: SAMPLE, sampleSize: 1000, sampleSeed: 7}` hai lần
    Và so tập `recordKey` đã đo
    Và đổi `sampleSeed = 8`
    Thì hai lần cùng seed cho cùng tập khóa và cùng số đếm; lần đo ghi `sampleSeed` 64 bit; seed khác cho tập khác. Điểm lần đo mẫu không được dùng cho báo cáo năm (xem rep-annual-neg).

  @TC-08-058 @P1 @Bảo @mật
  Kịch bản: TC-08-058 Truy vấn lên nguồn chỉ SELECT, giới hạn thời gian, song song, cửa sổ giờ
    # Truy vết: FR-08-026 · API-08-059 · BR-08-025 · BR-08-005
    Biết `hotich-pg-ro` có nhật ký câu lệnh; tài khoản nguồn có quyền chỉ đọc; cửa sổ `22:00-05:00`; `statement_timeout` 15 phút.
    Khi chạy lần đo `FULL` với hai đối tượng cùng kết nối
    Và thu nhật ký câu lệnh
    Và thử `conn-sim` nhận `INSERT` giả từ tài khoản đo
    Và tạo lần đo lúc 14:00
    Thì mọi câu lệnh là `SELECT`; tối đa 2 truy vấn đồng thời mỗi kết nối; có `statement_timeout`; không truy cập CSDL control. `INSERT` bị nguồn từ chối. Lần đo `SCHEDULE` lúc 14:00 chờ đến 22:00, lần `MANUAL` có cảnh báo ngoài cửa sổ.

  @TC-08-059 @P1 @Dương
  Kịch bản: TC-08-059 Đối chiếu danh mục PH-07 cho chiều hợp lệ
    # Truy vết: FR-08-027 · API-08-064 · BR-08-003 · NFR-08-006 · LGC-DMDC-006, 007, 008
    Biết `src-hotich` có cột `ma_dvhc`: 200 trên 5.000 mã không thuộc `DVHC` hiện hành, 30 mã là mã cũ đã chuyển (EVT-07-10); quy tắc `IN_RDM` `catalogCode = DVHC`.
    Khi `POST /scans` `{mode: FULL}`
    Và `GET /scans/{id}/rule-results`
    Và kiểm giản đồ `ph08_dq` tìm bảng chứa mã danh mục
    Thì `failCount = 200`, `passCount = 4.800`; gợi ý mã mới cho 30 mã cũ; tra PH-07 theo lô 500 mã; không có bảng mã nào ở `ph08_dq` (BR-08-003). Đối tượng `rdm-dvhc` cũng được đo chất lượng sau mỗi lần phát hành danh mục.

  @TC-08-060 @P1 @Âm
  Kịch bản: TC-08-060 Quy tắc lỗi khi chạy, danh mục ngừng, lược đồ nguồn đổi
    # Truy vết: FR-08-026, 027 · API-08-064 · UI-08-12 · ERR-08-107, 116
    Biết quy tắc `R-DIV` (`CEL_EXPRESSION` chia cho trường 0 ở một số bản ghi); danh mục `DVHC-CU` đã ngừng ở `rdm-sim` (EVT-07-03); cột `ho_ten` bị xóa ở nguồn.
    Khi đo `mdm-citizen` có `R-DIV`
    Và đo `src-hotich` có quy tắc `IN_RDM` `DVHC-CU`
    Và đo `src-hotich` có quy tắc dùng `ho_ten`
    Thì bước 1 `R-DIV` trạng thái `ERROR`, quy tắc khác vẫn chạy, `ERROR` không vào mẫu số điểm. Bước 2 quy tắc `ERROR`, cảnh báo quy tắc trỏ danh mục ngừng. Bước 3 quy tắc `ERROR` kèm cảnh báo cho DS.

  @TC-08-061 @P2 @Âm
  Kịch bản: TC-08-061 Quá thời gian, vượt trần lỗi, bản ghi thiếu khóa
    # Truy vết: FR-08-026 · FR-08-036 · API-08-061 · UI-08-12 · ERR-08-106 · ERR-08-110, 109
    Biết T92 (`max-duration-hours = 1`, `max-per-rule-task = 50`); nguồn trễ giả lập; F-LOI.
    Khi đo khi nguồn trễ quá 1 giờ
    Và đo trên F-LOI
    Và đọc kết quả quy tắc
    Thì bước 1 lần đo dừng, ERR-08-106 ở UI-08-12 và PH-13, EVT-08-03 nếu `FAILED`. Bước 2 lưu 50 lỗi đầu, số đếm đủ 300, cờ `TRUNCATED`. Bước 3 12 bản ghi thiếu khóa thành lỗi cấu trúc `CRITICAL`.
