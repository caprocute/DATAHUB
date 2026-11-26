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

  @TC-14-119 @P1 @Dương @Biên
  Kịch bản: TC-14-119 Đếm hạn mức nhiều chu kỳ, ngưỡng cảnh báo một lần, hoàn lại lượt khi lỗi cục bộ
    # Truy vết: FR-14-033 · API-14-043, 075 · UC-14-23 · BR-14-012 · NFR-14-018 · EVT-14-07.
    Biết U-T68-TO, S-HT-MC; hạn mức V-HT 100 lượt mỗi giờ và 1.000 lượt mỗi ngày; `14.quota.warn-levels = [70%, 85%, 95%]`; `Clock` giả lập.
    Khi gọi 69, 70, 84, 85, 94, 95 lượt, kiểm tra `GET /quotas/usage` sau mỗi mốc.
    Và gọi thêm lượt khi tắt OpenBao (không ký được) rồi khi ngắt mạch mở.
    Và chờ một phút, đọc bảng `quota_usage`.
    Và tiến `Clock` qua chu kỳ giờ kế tiếp.
    Thì bước 1 cho `used`, `limit`, `ratio`, `level` (`OK`, `INFO`, `WARNING`, `CRITICAL`) đúng ở từng mốc; EVT-14-07 phát đúng một lần mỗi ngưỡng 70, 85, 95 trong chu kỳ, kèm thông báo cho TA, TO trong 2 phút. Bước 2 lượt không tới được nền tảng vì lỗi cục bộ được hoàn lại, `used` không tăng; lượt đã gửi mà nền tảng trả lỗi vẫn được tính. Bước 3 `quota_usage` khớp bộ đếm Valkey. Bước 4 bộ đếm giờ về 0, bộ đếm ngày giữ nguyên, ngưỡng cảnh báo được phát lại ở chu kỳ mới.

  @TC-14-120 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-14-120 Hết hạn mức: `429` đủ thông tin, hoàn lại lượt, đếm suy giảm khi mất Valkey
    # Truy vết: FR-14-033 · API-14-043, 075 · ERR-14-104 · BR-14-012 · NFR-14-024 · EVT-14-07.
    Biết S-HT-MC; hạn mức dịch vụ V-HT 100 lượt mỗi giờ và hạn mức nền tảng 10.000 lượt mỗi ngày; V-HT đã dùng 100 lượt; V-HT có mục đệm; `T01` có hạn mức riêng còn đủ; ba bản sao cổng.
    Khi gọi V-HT với `freshData = true`.
    Và gọi V-HT khi hạn mức nền tảng đã hết nhưng hạn mức dịch vụ còn.
    Và gọi V-HT của `T01` cùng lúc.
    Và dừng Valkey, gọi 30 lượt mỗi bản sao.
    Thì bước 1 `429` ERR-14-104 "Đã dùng hết hạn mức truy vấn {dịch vụ}. Bộ đếm đặt lại lúc {thời điểm}." kèm `scope = SERVICE`, `reason`, `resetAt`, `cache.available = true`; không gọi ra quốc gia; bộ đếm khác không bị tăng thừa. Bước 2 `scope = PLATFORM`. Bước 3 `200`, không bị ảnh hưởng. Bước 4 cổng đếm cục bộ với giới hạn chia đều theo số bản sao, ghi cảnh báo "đếm suy giảm"; không bỏ kiểm tra hạn mức. Giao dịch ghi `QUOTA_EXCEEDED`.

  @TC-14-121 @P1 @Âm @Biên
  Kịch bản: TC-14-121 Ưu tiên hạn mức: từ 70 % hoãn `BACKGROUND`, từ 95 % chỉ `ESSENTIAL`
    # Truy vết: FR-14-034 · API-14-043, 044, 075 · ERR-14-104 · BR-14-013 · NFR-14-018.
    Biết S-HT-MC; hạn mức nền tảng 1.000 lượt mỗi giờ; V-LLTP `ESSENTIAL`, V-HT `NORMAL`, V-DVQHNS `BACKGROUND`; `14.quota.background-defer-ratio = 0,7`, `14.quota.essential-only-ratio = 0,95`; phân bổ S-HT-MC 600 lượt.
    Khi đưa mức dùng tới 699 lượt, gọi V-DVQHNS; đưa tới 700, gọi lại.
    Và đưa tới 949 lượt, gọi V-HT; đưa tới 950, gọi V-HT rồi V-LLTP.
    Và thử lượt thử lại tự động (do lỗi có thể thử lại) khi mức dùng 950.
    Và gọi bằng S-HT-MC khi đã dùng đủ 600 lượt được phân bổ.
    Thì bước 1 lượt ở 699 `200`, ở 700 `429` ERR-14-104 `reason` nêu hoãn theo ưu tiên. Bước 2 V-HT `200` ở 949, `429` ở 950; V-LLTP vẫn `200`. Bước 3 lượt thử lại bị bỏ qua, không tiêu hạn mức. Bước 4 `429` ERR-14-104 `scope = SYSTEM`; HTTT khác chưa dùng hết phần của mình vẫn gọi được. Dịch vụ công không bị ngưng vì tác vụ nền.
