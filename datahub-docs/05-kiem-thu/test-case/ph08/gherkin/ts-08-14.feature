# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-14
Tính năng: TS-08-14 · Đo tăng dần theo sự kiện PH-06, PH-07

  @TC-08-076 @P2 @Dương
  Kịch bản: TC-08-076 Gom sự kiện bản ghi vàng đổi thành lần đo tăng dần
    # Truy vết: FR-08-025 · API-08-060, 061, 130, 131 · BR-08-033 · EVT-06-02 · EVT-06-03 · EVT-08-06
    Biết `mdm-citizen` bật tăng dần; `08.incremental.batch-window-minutes = 15`; `mdm-sim` phát 500 sự kiện `golden.updated` và 1 `golden.merged`.
    Khi phát sự kiện trong 5 phút
    Và đợi hết cửa sổ
    Và `GET /scans?scanTrigger=EVENT`
    Và `POST /assets/mdm-citizen:disable-incremental` rồi phát lại sự kiện, sau đó `:enable-incremental`
    Thì một lần đo `INCREMENTAL` `trigger = EVENT` chỉ trên 500 khóa đổi; lỗi cập nhật theo dấu vân tay; EVT-08-06 nếu có lỗi mới; lỗi của bản ghi bị hợp nhất `RESOLVED` lý do `RECORD_REMOVED`; ảnh chụp đầy đủ gần nhất không bị thay, điểm hiện hành gộp. Khi `disable-incremental` sự kiện không sinh lần đo nữa; `enable-incremental` bật lại.

  @TC-08-077 @P2 @Dương
  Kịch bản: TC-08-077 Danh mục PH-07 phát hành hoặc tổ chức lại ĐVHC
    # Truy vết: FR-08-025 · API-08-060 · EVT-07-05 · EVT-07-10 · LGC-DMDC-006, 007, 008
    Biết `rdm-dvhc` và `src-hotich` có quy tắc `IN_RDM` với `DVHC`; `rdm-sim` phát `catalog.published` rồi `adminunit.reorganized`.
    Khi phát `catalog.published`
    Và phát `adminunit.reorganized`
    Và `GET /scans?scanTrigger=EVENT`
    Thì lần đo tăng dần cho `rdm-dvhc`; sau `adminunit.reorganized` có lần đo tăng dần cho mọi đối tượng có quy tắc `IN_RDM` với `DVHC`; sự kiện `catalog.retired` làm quy tắc trỏ danh mục ngừng bị cảnh báo.

  @TC-08-078 @P2 @Âm
  Kịch bản: TC-08-078 Sự kiện sai lược đồ và đổi mô hình domain
    # Truy vết: FR-08-025 · FR-08-002 · EVT-06-10 · ERR-08-118 · ERR-08-116
    Biết `mdm-sim` phát sự kiện thiếu `goldenId` và sự kiện `model.activated` ẩn trường `ngayCap`.
    Khi phát sự kiện sai
    Và phát `model.activated`
    Và chạy lần đo sau
    Thì sự kiện sai vào hộp nhận lỗi, cảnh báo vận hành ERR-08-118 ở PH-13, không đo. `model.activated` chỉ so lược đồ, DS nhận cảnh báo; lần đo sau quy tắc dùng `ngayCap` thành `ERROR` ERR-08-116.
