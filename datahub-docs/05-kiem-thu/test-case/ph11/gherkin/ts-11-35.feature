# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-35
Tính năng: TS-11-35 · Nghiệm thu đầu cuối LT_KHAI_SINH và DUYET_KET_NAP_HTTT

  @TC-11-164 @P1 @Dương
  Kịch bản: TC-11-164 LT_KHAI_SINH nhánh thành công
    # Truy vết: FR-11-018, 028, 029, 034, 038, 055 · BR-11-001, 002 · EVT-11-03, 04, 05
    # Mục đích: Chứng minh hồ sơ liên thông chạy từ Cổng DVC đến hoàn thành qua PH-04, ranh giới PH-11 và PH-04 đúng.
    Biết T90; `M-KS`; S-DVC; CB-TP; `ph04-sim`; `HS-30`.
    Khi S-DVC khởi tạo `HS-30`
    Và CB-TP nhận và hoàn thành `nhanHoSo`
    Và `ph04-sim` trả `completed` cho `guiTuPhap`, `guiCuTru`, `capTheBHYT`
    Và S-DVC tra tiến độ sau mỗi bước
    Và kiểm lệnh Kafka và gọi HTTT
    Thì phiên `COMPLETED`, `dueResult = MET`; DVC thấy ba bước công khai chuyển `DONE` lần lượt; đủ EVT: `instance.started`, `step.completed`, `instance.completed`; PH-11 chỉ gửi lệnh ý định, không gọi HTTT.

  @TC-11-165 @P1 @Dương
  Kịch bản: TC-11-165 LT_KHAI_SINH nhánh lỗi BHYT: bù trừ thành công và thất bại chuyển thủ công
    # Truy vết: FR-11-051, 053, 055 · EVT-11-13, 14, 15 · ERR-11-105, 110 · BR-11-008, 009, 010, 012
    # Mục đích: Chứng minh nhánh BHYT lỗi bù trừ về nhất quán, bù trừ thất bại không im lặng (tiêu chí 2).
    Biết `HS-31` (bù trừ thành công), `HS-32` (bù trừ `guiCuTru` lỗi 3 lần); T92 `11.saga.maxRetries = 2`; TO.
    Khi gây `BHXH_TU_CHOI` ở `HS-31`, TO xử lý `guiTuPhap` thủ công
    Và gây `BHXH_TU_CHOI` ở `HS-32`, `huyDangKyThuongTru` lỗi
    Và TO `:resolve-manual`
    Và S-DVC tra tiến độ hai hồ sơ
    Thì `HS-31` `COMPENSATED`, EVT: `saga.compensation.completed`. `HS-32` `FAILED`, EVT: `saga.compensation.failed` và cảnh báo P1, sau xử lý `COMPENSATED`. DVC thấy "Đã hủy", không thấy lỗi kỹ thuật.

  @TC-11-166 @P1 @Dương
  Kịch bản: TC-11-166 DUYET_KET_NAP_HTTT do PH-01 khởi tạo, hai cấp duyệt, bốn mắt
    # Truy vết: FR-11-018, 034, 038, 046, 048 · EVT-11-05 · ERR-11-005 · BR-11-004, 020
    # Mục đích: Chứng minh PH-01 khởi tạo, hai cấp duyệt khác người, kết quả trả về PH-01, theo tiêu chí chấp nhận 3.
    Biết S-PH01; CB-LD (cấp phòng), CB-SO (cấp sở); `HS-33`.
    Khi S-PH01 `POST /instances` `DUYET_KET_NAP_HTTT`
    Và CB-LD duyệt `duyetCapPhong`
    Và CB-LD thử duyệt `duyetCapSo`
    Và CB-SO duyệt `duyetCapSo`
    Và đọc sự kiện `instance.completed`
    Thì bước 3 `403` ERR-11-005. Phiên `COMPLETED`, `outcome = APPROVED` gửi PH-01; mỗi việc hạn 3 ngày LV, `dueResult = MET`.
