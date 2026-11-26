# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-30
Tính năng: TS-09-30 · Hạn xử lý, trả lời, đóng yêu cầu và báo cáo truy cập

  @TC-09-103 @P1 @Dương @Âm
  Kịch bản: TC-09-103 Nhắc trước 3 ngày làm việc và cờ quá hạn
    # Truy vết: FR-09-049 · API-09-174, 242 · EVT-09-23, 24 · BR-09-043 · NFR-09-016
    # Mục đích: Chứng minh nhắc đúng 3 ngày làm việc trước hạn (100 %) và cảnh báo SO khi quá hạn.
    Biết T95 đồng hồ giả; 3 yêu cầu hạn sau 3, 0 và -1 ngày làm việc; lịch ngày nghỉ giả định Q09-43.
    Khi tiến đồng hồ; `GET /subject-requests:due`.
    Và U-T90-VW gọi `GET /subject-requests:due`.
    Và SO `POST /subject-requests/{id}:extend` kèm lý do và hạn mới không quá ngày pháp luật cho phép.
    Thì yêu cầu 1 có EVT: `dsr.due-soon` đúng một lần. Yêu cầu 3 có cờ `overdue`, EVT: `dsr.overdue` tới SO; trạng thái `DsrStatus` không đổi; thẻ "yêu cầu quá hạn" ở UI-09-01 đúng số. Bước 2 ERR-00-403. Bước 3 `200`, hạn mới được ghi, chủ thể được báo; hạn vượt mức pháp luật cho phép bị từ chối.

  @TC-09-104 @P1 @Dương @Âm
  Kịch bản: TC-09-104 Trả lời, lưu bằng chứng và đóng yêu cầu
    # Truy vết: FR-09-050 · API-09-175, 176, 177, 244 · ERR-09-067, 068 · BR-09-048 · EVT-09-25
    # Mục đích: Chứng minh không đóng khi còn tác vụ hoặc thiếu kết quả, từ chối cần căn cứ.
    Biết T90; DSR-01 còn 1 tác vụ `OPEN`; U-T90-DS1.
    Khi DS1 `:close` khi còn 1 tác vụ.
    Và DS1 `:respond` thiếu kết quả hoặc bằng chứng.
    Và hoàn tất tác vụ; `:respond` đủ kết quả `FULFILLED` kèm tệp; `:close`.
    Và SO `POST /subject-requests/{id}:withdraw` kèm lý do trên một yêu cầu khác đang `IN_PROGRESS`.
    Thì bước 1 `422` ERR-09-067 "Còn 1 tác vụ chưa hoàn tất, chưa đóng được yêu cầu." Bước 2 `422` ERR-09-068. Bước 3 `CLOSED`, bằng chứng lưu 5 năm, EVT: `dsr.closed`. Bước 4 `200`, `WITHDRAWN`, tác vụ đang mở bị hủy.

  @TC-09-105 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-09-105 Báo cáo ai đã truy cập dữ liệu của chủ thể, không lộ nội dung
    # Truy vết: FR-09-051 · API-09-179, 180, 181 · BR-09-044, 042 · ERR-09-063
    # Mục đích: Chứng minh báo cáo liệt kê người, hệ thống, mục đích, thời điểm.
    Biết T90; CC-01 có 12 lượt truy cập ở nhật ký PH-13 giả lập; DSR-01 đã xác minh.
    Khi DS1 `POST /subject-requests/{id}:access-report`; `GET .../access-report`.
    Và `GET /subject-request-reports`.
    Và DS1 `:access-report` cho yêu cầu chưa xác minh.
    Thì bước 1 12 dòng (HTTT, mục đích, thời điểm) không giá trị dữ liệu. Bước 2 tỷ lệ đóng trong hạn đúng báo cáo. Bước 3 `422` ERR-09-063.
