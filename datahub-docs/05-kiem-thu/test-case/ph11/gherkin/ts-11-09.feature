# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-09
Tính năng: TS-11-09 · Tạo việc, phân công và đưa vào hộp "Việc của tôi"

  @TC-11-055 @P1 @Dương
  Kịch bản: TC-11-055 Tạo việc theo nhóm, đơn vị, người, quy tắc
    # Truy vết: FR-11-034, 046 · API-11-072 · EVT-11-08, 09 · BR-11-016, 037
    Biết `HS-11` tới `nhanHoSo` (nhóm `TU_PHAP`: CB-TP, CB-TP2); một bước phân công `ORG_UNIT` với PH-12 giả trả 5 thành viên; một bước `USER` = CB-BH.
    Khi chạy phiên tới từng bước
    Và `GET /tasks?instanceId=` của từng ca
    Và sau khi tạo việc `ORG_UNIT`, PH-12 đổi thành viên đơn vị
    Và đọc lại ứng viên
    Thì nhóm: `UNASSIGNED`, hai ứng viên, `dueAt` 2 ngày LV, EVT: `task.created`. Người: `ASSIGNED`, EVT: `task.assigned` `via` ghi nhận. Đơn vị: 5 ứng viên chụp tại thời điểm tạo, không đổi sau khi PH-12 đổi (BR-11-037).

  @TC-11-056 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-056 Tách nhiệm vụ trong phiên
    # Truy vết: FR-11-034 · BR-11-020 · ERR-11-113
    Biết `DUYET_KET_NAP_HTTT`: CB-LD xử lý `duyetCapPhong`; nhóm `SO_TTTT` gồm CB-LD, CB-SO.
    Khi S-PH01 khởi tạo, CB-LD hoàn thành `duyetCapPhong`
    Và `GET /tasks?instanceId=` việc `duyetCapSo`
    Và đổi nhóm `SO_TTTT` chỉ còn CB-LD, tạo phiên mới và lặp lại
    Thì bước 2 ứng viên chỉ CB-SO. Bước 3 không còn ứng viên hợp lệ: việc vào `VAN_HANH_QUY_TRINH` và có sự cố ERR-11-113; không giao cho CB-LD.

  @TC-11-057 @P1 @Âm
  Kịch bản: TC-11-057 Không có ứng viên hợp lệ
    # Truy vết: FR-11-034 · ERR-11-113 · BR-11-019
    Biết nhóm `TU_PHAP` rỗng ở PH-12 giả; `11.task.fallbackGroup = VAN_HANH_QUY_TRINH`.
    Khi chạy phiên tới `nhanHoSo`
    Và TO `GET /incidents`
    Và TO nhận việc ở nhóm dự phòng
    Thì việc ở nhóm `VAN_HANH_QUY_TRINH`, sự cố ERR-11-113 hiện ở UI-11-20; TO nhận được việc.

  @TC-11-058 @P1 @Dương
  Kịch bản: TC-11-058 Việc hiện trong "Việc của tôi" theo phạm vi
    # Truy vết: FR-11-035 · API-11-125, 072 · BR-11-014, 031, 037 · NFR-11-015 · bpm.task.read
    Biết phiên `HS-12` vừa tới `nhanHoSo`; CB-TP, CB-BH; S-MC.
    Khi CB-TP gọi `GET /inbox-items` trong 5 giây
    Và CB-BH gọi `GET /inbox-items`
    Và S-MC `GET /tasks?orgUnit=TU_PHAP`
    Và hủy phiên `HS-12`, CB-TP gọi lại
    Thì CB-TP thấy việc có nguồn `PH-11`; CB-BH không thấy. S-MC thấy danh sách, không có biến `SENSITIVE`. Sau hủy việc biến mất khỏi hộp trong ≤ 5 giây.

  @TC-11-059 @P2 @Âm
  Kịch bản: TC-11-059 Hộp việc chung không nhận
    # Truy vết: FR-11-035 · ERR-11-114
    Biết nhà cung cấp hộp việc FR-00-070 giả trả `503`.
    Khi chạy phiên tới `nhanHoSo`
    Và đọc cảnh báo UI-11-20
    Và phục hồi nhà cung cấp
    Thì việc đã tạo trong `task_index`; cảnh báo ERR-11-114 "Không đăng ký được việc vào hộp Việc của tôi"; sau phục hồi việc hiện ở hộp, đúng một lần.
