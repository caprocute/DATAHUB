# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-34
Tính năng: TS-11-34 · Truy cập và quan sát

  @TC-11-162 @P2 @Truy @cập
  Kịch bản: TC-11-162 WCAG 2.2 AA, bàn phím, giấy phép bpmn.io
    # Truy vết: NFR-11-022 · UI-11-04, 15 · FR-11-003, 038
    # Mục đích: Chứng minh UI-11-04, 15 không lỗi truy cập nghiêm trọng, trình thiết kế dùng được bằng bàn phím, logo bpmn.io hiển thị.
    Biết playwright, axe-core; chế độ chỉ bàn phím.
    Khi chạy axe-core trên UI-11-04 và UI-11-15
    Và chỉ dùng bàn phím: chọn phần tử, nối, sửa thuộc tính, hoàn thành việc
    Và kiểm logo bpmn.io trên trình thiết kế
    Và kiểm tương phản và nhãn
    Thì 0 lỗi mức serious, critical; mọi thao tác thực hiện được bằng bàn phím với thứ tự Tab hợp lý; logo bpmn.io luôn hiển thị.

  @TC-11-163 @P2 @Dương
  Kịch bản: TC-11-163 Dấu vết, chỉ số, cảnh báo
    # Truy vết: NFR-11-019 · FR-11-061 · EVT-11-17, 04 · ERR-11-110
    # Mục đích: Chứng minh một `traceId` theo suốt từ khởi tạo đến sự kiện và chỉ số vận hành đủ.
    Biết PH-13 giả; `traceparent` ở yêu cầu khởi tạo.
    Khi S-DVC `POST /instances` kèm `traceparent`
    Và theo `traceId` qua API, lệnh PH-04, kết quả, sự kiện
    Và đọc chỉ số của bảng vận hành
    Và gây bù trừ thất bại
    Thì mọi API, lệnh, sự kiện mang `traceparent`; PH-13 thấy một vết liền mạch; đủ chỉ số; bù trừ thất bại sinh cảnh báo P1.
