# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-21
Tính năng: TS-14-21 · Hạn mức do trung ương áp, đếm và phân bổ

  @TC-14-053 @P1 @Dương
  Kịch bản: TC-14-053 Khai báo hạn mức, phân bổ theo HTTT, duyệt ở môi trường thật
    # Truy vết: FR-14-032, 034 · API-14-041, 042, 044, 045 · UI-14-09, 17 · UC-14-22 · BR-14-011, 022.
    Biết U-T68-TA, U-T68-IA; hạn mức 10.000 lượt/ngày cho `ndxp`.
    Khi `POST /quotas` kèm căn cứ (số, ngày, trích yếu), gửi duyệt, IA duyệt.
    Và `PUT /quota-allocations/HT-MOTCUA` 6.000; `GET /quota-allocations`.
    Thì hạn mức có hiệu lực ≤ 30 giây sau duyệt; phân bổ lưu đúng; kiểm toán đủ.

  @TC-14-054 @P1 @Âm
  Kịch bản: TC-14-054 Hạn mức sai: thiếu căn cứ, chu kỳ sai, phân bổ vượt
    # Truy vết: FR-14-032, 034 · API-14-042, 045 · ERR-14-016, 017, 018 · PERM-14-quota.
    Biết U-T68-TA; hạn mức 10.000/ngày; U-T68-IE.
    Khi `POST /quotas` không có căn cứ.
    Và `POST /quotas` giới hạn 0 hoặc chu kỳ `HOURLY` ngoài miền.
    Và phân bổ 6.000 cho `HT-MOTCUA` rồi 5.000 cho `HT-KHAC`.
    Và U-T68-IE khai báo hạn mức.
    Thì `422` ERR-14-016; `422` ERR-14-017; bước 3 lần hai `422` ERR-14-018; bước 4 `403`.

  @TC-14-055 @P1 @Dương @Âm @Biên
  Kịch bản: TC-14-055 Đếm, ngưỡng 70, 85, 95 %, hoãn theo ưu tiên, hết hạn mức
    # Truy vết: FR-14-033, 034 · API-14-043, 075 · UI-14-01, 09 · UC-14-23 · ERR-14-104 · BR-14-012, 013 · NFR-14-018.
    Biết hạn mức 1.000 lượt/ngày; V-LLTP `ESSENTIAL`, V-HT `NORMAL`, V-DVQHNS `BACKGROUND`.
    Khi gọi V-HT tới 700 lượt; gọi V-DVQHNS.
    Và tới 950 lượt; gọi V-HT, V-DVQHNS, V-LLTP.
    Và tới 1.000 lượt; gọi V-LLTP; `GET /quotas/usage`.
    Và qua nửa đêm giờ giả lập.
    Thì cảnh báo ở 70, 85, 95 % trong ≤ 2 phút; ≥ 70 % `BACKGROUND` bị hoãn `429` ERR-14-104; ≥ 95 % chỉ `ESSENTIAL` đi; 1.000 lượt thì `429` ERR-14-104 có `scope`, `reason`, `resetAt`, không gọi ra; bước 4 bộ đếm đặt lại; số đếm khớp tuyệt đối giữa 3 bản sao.
