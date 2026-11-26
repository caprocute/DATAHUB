# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-30
Tính năng: TS-17-30 · Gửi phản hồi, xử lý hàng phản hồi và theo dõi chỉ số chất lượng

  @TC-17-098 @P1 @Dương @Âm
  Kịch bản: TC-17-098 Gửi phản hồi hữu ích, báo sai, không an toàn; một lần mỗi câu trả lời
    # Truy vết: FR-17-052 · API-17-155, 156, 157 · BR-17-069 · ERR-17-077 · EVT-17-23 · UI-17-01, UI-17-14
    # Mục đích: Chứng minh BR-17-069.
    Biết T90; câu trả lời `MSG-1`, `MSG-2`, `MSG-3`; U-T90-IE.
    Khi IE `POST /feedback` `HELPFUL` cho `MSG-1`.
    Và IE `POST /feedback` `WRONG` cho `MSG-1`.
    Và IE `POST /feedback` `UNSAFE` cho `MSG-2` kèm lý do có canary `DH-CANARY-ph`.
    Và IE `POST /feedback` `WRONG` cho `MSG-3` không có lý do.
    Thì bước 1 `201`, EVT: `assist.feedback.submitted`. Bước 2 `409` ERR-17-077. Bước 3 `201`, tự thành ứng viên ca đỏ, nội dung đính kèm đã che, 0 canary. Bước 4 `422` ERR-17-003 (cần lý do).

  @TC-17-099 @P2 @Dương
  Kịch bản: TC-17-099 Hàng xử lý: phân loại, giao việc, đóng, đưa thành ca đỏ, quá hạn nhắc
    # Truy vết: FR-17-052, 051 · API-17-158, 159, 160 · BR-17-070 · UI-17-14 · EVT-17-23
    # Mục đích: Chứng minh vòng xử lý phản hồi và hạn `17.feedback.sla-days`.
    Biết T95 (đồng hồ giả); 3 phản hồi `NEW`; `17.feedback.sla-days = 5`; U-T95-DS, U-T95-TA1; VW không có quyền.
    Khi DS `POST /feedback/{id}:triage` giao TA1.
    Và TA1 `:promote-to-redteam` phản hồi `UNSAFE`.
    Và TA1 `:resolve` kèm kết luận.
    Và đẩy đồng hồ 6 ngày làm việc với một phản hồi chưa xử lý.
    Và VW `GET /feedback`.
    Thì bước 1 `ASSIGNED`. Bước 2 `PROMOTED_TO_REDTEAM`, ca đỏ ứng viên chờ rà soát. Bước 3 `CLOSED`. Bước 4 nhắc người xử lý, hiện ở bảng chất lượng. Bước 5 `403` ERR-00-403.

  @TC-17-100 @P2 @Dương @Âm @Biên
  Kịch bản: TC-17-100 Chỉ số chất lượng theo ngày và tuần, cảnh báo sụt quá ngưỡng
    # Truy vết: FR-17-053 · API-17-161, 162, 163 · BR-17-071 · EVT-17-24 · UI-17-13
    # Mục đích: Chứng minh BR-17-071 và đặt ngưỡng.
    Biết T95; 7 ngày trước tỷ lệ có trích dẫn 90 %, hôm nay 78 %; `17.quality.alert-drop-percent = 10`; U-T95-TA1.
    Khi TA1 `GET /quality/metrics` theo năng lực.
    Và chạy lượt tính chỉ số hằng ngày.
    Và TA1 `PUT /quality/thresholds` đặt 15 rồi tính lại.
    Và U-T95-VW `GET /quality/metrics` và `PUT /quality/thresholds`.
    Thì bước 1 có tỷ lệ có trích dẫn, không tìm thấy, chấp nhận gợi ý, điểm đánh giá. Bước 2 sụt 12 điểm phần trăm vượt 10: cảnh báo, EVT: `assist.quality.alert-raised`. Bước 3 không cảnh báo mới (ngưỡng 15). Bước 4 `403` ERR-00-403.
