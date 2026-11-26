# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-39
Tính năng: TS-13-39 · Chịu lỗi và không chặn data plane

  @TC-13-114 @P1 @Khả @dụng
  Kịch bản: TC-13-114 Tắt toàn bộ `dh-platform` và LGTM 24 giờ, data plane vẫn chạy
    # Truy vết: NFR-13-014, 011 · BR-13-015 · FR-13-016 · ERR-13-014
    Biết tải 100 lượt/giây qua gateway; tắt `dh-platform` và LGTM (rút gọn 2 giờ ở SIT, 24 giờ ở phát hành).
    Khi tắt; giữ tải; bật lại.
    Thì 0 lượt gọi API lỗi do PH-13; hộp thư đi giữ bản ghi kiểm toán; sau bật lại 0 mất, chuỗi nối đúng.

  @TC-13-115 @P1 @Khả @dụng
  Kịch bản: TC-13-115 Mất 1 pod PH-13 hoặc 1 broker Kafka giữa lúc ghi
    # Truy vết: NFR-13-011, 012, 013 · FR-13-010, 011 · BR-13-004
    Biết F-DU-SIM 100 bản ghi/giây.
    Khi xóa 1 pod PH-13; sau đó tắt 1 broker; kiểm tra chuỗi.
    Thì 0 mất, 0 trùng, `seq` liên tục; kiểm tra toàn vẹn `PASSED`.

  @TC-13-116 @P2 @Khả @dụng
  Kịch bản: TC-13-116 Mất site chính, RPO ≤ 5 phút
    # Truy vết: NFR-13-012 · FR-13-013 · BR-13-013
    Biết hai site active–standby (ADR-034); diễn tập DR hằng năm.
    Khi ngắt site chính; chuyển sang site dự phòng; kiểm tra chuỗi.
    Thì RTO ≤ 4 giờ; mất không quá lô WORM gần nhất (RPO ≤ 5 phút); bản ghi chờ ở hộp thư đi của DU được ghi bù.
