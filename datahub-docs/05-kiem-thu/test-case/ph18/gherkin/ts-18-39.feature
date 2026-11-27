# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-39
Tính năng: TS-18-39 · Tra nhật ký thao tác và lập báo cáo vận hành định kỳ

  @TC-18-130 @P1 @Dương
  Kịch bản: TC-18-130 AU tra nhật ký thao tác vận hành, đối chiếu đủ 100 % thao tác ghi
    # Truy vết: FR-18-070 · API-18-177, 016, 063 · BR-18-046 · NFR-18-019 · UI-18-24
    # Mục đích: Chứng minh FR-18-070 và NFR-18-019: mọi thao tác ghi của các ca chương 4 có bản ghi kiểm toán; AU chỉ đọc.
    Biết T90 sau khi chạy hết chương 4; U-T90-AU; nhật ký thao tác nội bộ của PH-18.
    Khi AU `GET /audit-log?tuNgay=...`.
    Và chạy tác vụ đối chiếu hằng ngày nhật ký thao tác với kiểm toán PH-13.
    Và AU thử `DELETE /audit-log/{id}`.
    Thì bước 1 `200` danh sách có người, hành động, đối tượng, lý do, kết quả. Bước 2 tỷ lệ khớp 100 %. Bước 3 `405`.

  @TC-18-131 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-131 PH-13 không ghi được: thao tác thường bị từ chối, hủy và tạm dừng vẫn có hiệu lực, ghi bù
    # Truy vết: FR-18-070, 029, 068 · BR-18-046 · ERR-18-008
    # Mục đích: Chứng minh BR-18-046: kiểm toán trước khi có hiệu lực, ngoại lệ có kiểm soát cho thao tác khẩn.
    Biết T94; WireMock PH-13 trả `503`; lượt `RJ-T94` đang `RUNNING`.
    Khi TO bỏ qua một mục DLQ.
    Và TO `:pause` lượt `RJ-T94`, rồi `:cancel`.
    Và khôi phục PH-13.
    Thì bước 1 `503` ERR-18-008. Bước 2 `200` cả hai, bản ghi kiểm toán nằm ở outbox. Bước 3 outbox gửi bù đủ, thứ tự đúng.

  @TC-18-132 @P2 @Dương @Âm
  Kịch bản: TC-18-132 Dựng báo cáo tháng cho PH-16, kỳ chưa kết thúc bị từ chối, sự kiện không có dữ liệu cá nhân
    # Truy vết: FR-18-071 · API-18-178, 179, 081 · BR-18-050 · ERR-18-072 · EVT-18-28 · UI-18-24
    # Mục đích: Chứng minh FR-18-071 và BR-18-050.
    Biết T90 với dữ liệu tháng 10/2026; U-PA1; ngày hiện tại 27/11/2026.
    Khi `POST /reports:generate` kỳ `2026-10`.
    Và đọc `t90.ops.report.published.v1`.
    Và `POST /reports:generate` kỳ `2026-11`.
    Và `GET /reports`.
    Thì bước 1 `202` rồi báo cáo có số mục DLQ, tỷ lệ phát lại, sao lưu, di trú, sự cố. Bước 2 EVT-18-28 chỉ có chỉ số tổng hợp, không có payload hay dữ liệu cá nhân. Bước 3 `422` ERR-18-072. Bước 4 có báo cáo 2026-10.
