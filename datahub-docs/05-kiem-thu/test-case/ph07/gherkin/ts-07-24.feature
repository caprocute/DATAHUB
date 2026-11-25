# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-24
Tính năng: TS-07-24 · Tham số PH-07 theo tenant

  @TC-07-272 @P2 @Dương
  Kịch bản: TC-07-272 Đổi ngưỡng thay đổi lớn và áp dụng không cần khởi động lại
    # Truy vết: FR-07-053 · UI-07-13 · BR-07-012
    Biết `07.rdm.large-change-threshold-percent` = 10 (mặc định); bản nháp CAT-MUC đổi 1 trên 4 bản ghi (25%).
    Khi phát hành thẳng CAT-MUC.
    Và U-T68-TA đặt tham số = 30 trên UI-07-13; chờ 60 giây; phát hành thẳng lại.
    Thì bước 1 `409` `ERR-07-016`. Bước 2 phát hành thành công; KT: có (`RDM_PARAMETER_UPDATE` do PH-18 ghi).

  @TC-07-273 @P2 @Âm
  Kịch bản: TC-07-273 Tham số mức PLATFORM và giá trị ngoài miền
    # Truy vết: FR-07-053 bước 4
    Biết U-T68-TA.
    Khi đổi `07.rdm.import-max-mb` (mức PLATFORM).
    Và đổi `07.rdm.max-future-effective-days` = 5000.
    Thì cả hai bị PH-18 từ chối theo quy ước lỗi của PH-18; giá trị hiệu lực không đổi.

  @TC-07-274 @P3 @Dương @Khả @dụng
  Kịch bản: TC-07-274 Tác vụ đang chạy giữ tham số lúc bắt đầu; PH-18 ngừng
    # Truy vết: FR-07-053 bước 3 · `07.rdm.import-preview-ttl-hours`
    Biết tác vụ nhập `VALIDATED` tạo khi TTL = 24 giờ.
    Khi PA đổi TTL nền tảng thành 12 giờ; tua đồng hồ 13 giờ.
    Và dừng giả lập PH-18; khởi động lại một pod `dh-data`.
    Thì bước 1 tác vụ vẫn `VALIDATED` (giữ 24 giờ ghi trong `options`). Bước 2 pod khởi động bằng giá trị mặc định đóng gói, tra cứu không lỗi.
