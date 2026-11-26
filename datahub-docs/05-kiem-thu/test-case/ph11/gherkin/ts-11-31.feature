# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-31
Tính năng: TS-11-31 · Hạn theo lịch làm việc: bộ 200 ca và đầu cuối

  @TC-11-155 @P1 @Độ @chính @xác
  Kịch bản: TC-11-155 Bộ 200 ca lịch mẫu không sai lệch
    # Truy vết: NFR-11-016 · FR-11-046 · BR-11-017, 018 · API-11-093
    # Mục đích: Chứng minh hàm tính hạn đúng trên 200 ca gồm lễ, nghỉ bù, làm bù, nghỉ đột xuất, giờ ngoài giờ, theo ADR 114.
    Biết `F-LICH-200` ở T94; hạn kỳ vọng do hai người tính tay độc lập và đã đối chiếu.
    Khi chạy `compute-due` cho 200 ca
    Và so từng `dueAt`
    Và lặp ở `11.due.receiveAfterHoursRule = SAME_DAY`
    Thì sai lệch 0 ca; `explain[]` khớp từng ngày bị bỏ; quy tắc tiếp nhận ngoài giờ đổi đúng theo tham số.

  @TC-11-156 @P1 @Dương
  Kịch bản: TC-11-156 Luồng hạn đầu cuối qua ngày lễ và ngày làm bù
    # Truy vết: FR-11-045, 046, 047, 048, 050 · API-11-091, 094 · BR-11-017, 019 · NFR-11-016
    # Mục đích: Chứng minh phiên `LT_KHAI_SINH` tiếp nhận 16:45 thứ Sáu 30/4/2027 có hạn 17:00 10/5, đổi thành 17:00 8/5 khi thêm ngày làm bù, nhắc và quá hạn đúng mốc.
    Biết T90 `LICH-T90-2027`; phiên `HS-28` và `HS-29`; `11.due.scanMinutes = 1`.
    Khi tạo `HS-28` lúc 16:45 30/4/2027
    Và TA thêm `MAKEUP_WORKDAY` 8/5/2027
    Và CLK tới mốc nhắc rồi quá hạn của `HS-28`
    Và CB hoàn thành `HS-29` trước hạn
    Và VW `GET /reports/due`
    Thì `HS-28` hạn 10/5 17:00, sau khi thêm làm bù 8/5 17:00; nhắc và quá hạn trễ ≤ 5 phút, `OVERDUE` rồi `MISSED`; `HS-29` `MET`; báo cáo khớp.
