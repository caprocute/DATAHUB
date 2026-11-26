# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-33
Tính năng: TS-01-33 · Chịu lỗi, cách ly sự cố, kiểm toán, cảnh báo, lưu giữ

  @TC-01-131 @P1 @Chịulỗi
  Kịch bản: TC-01-131 Dừng dh-connect: HTTT đã kết nạp vẫn gọi API
    # Truy vết: NFR-01-007 · FR-01-037 · ERR-01-046.
    Biết `HT-QLVB` ACTIVE đang gọi API qua APISIX; token còn hạn 5 phút làm mới qua PH-12.
    Khi dừng toàn bộ `dh-connect` 30 phút (rút gọn từ 24 giờ, kiểm cấu hình đã nạp ở APISIX).
    Và gọi API trong khi dừng; thử nộp hồ sơ, đổi cấu hình.
    Và khởi động lại.
    Thì bước 2: HTTT `ACTIVE` gọi API bình thường; nộp hồ sơ và đổi cấu hình bị chặn `503`. Bước 3: tự phục hồi, không mất dữ liệu.

  @TC-01-132 @P2 @Chịulỗi
  Kịch bản: TC-01-132 Khởi động lại giữa saga và outbox, phục hồi sao lưu
    # Truy vết: NFR-01-006 · FR-01-020, 037 · EVT-01-03, 05.
    Biết một saga đang chạy; Kafka, Debezium thật.
    Khi xóa pod `dh-connect` giữa chừng saga năm lần.
    Và phục hồi sao lưu ở môi trường DR; so với nguồn.
    Thì saga tiếp tục đúng bước, không tạo client hai lần, không mất hay trùng sự kiện; RPO ≤ 1 giờ, RTO ≤ 4 giờ.

  @TC-01-133 @P1 @Dương @Bảomật
  Kịch bản: TC-01-133 Kiểm toán mọi quyết định, truy được sau một năm
    # Truy vết: NFR-01-013 · FR-01-012, 013, 014, 018, 024, 026, 029, 031, 032, 042.
    Biết chạy trọn vòng đời một HTTT; bộ thu PH-13 giả lập; dữ liệu cũ một năm.
    Khi đối chiếu bản ghi kiểm toán với danh sách thao tác.
    Và tra quyết định từ một năm trước.
    Thì mỗi quyết định có một bản ghi đủ trường FR-00-041 (người, vai trò, thời điểm, đối tượng, lý do, kết quả), không có bí mật; truy được quyết định cũ.

  @TC-01-134 @P2 @Dương
  Kịch bản: TC-01-134 Cảnh báo vận hành và lưu giữ
    # Truy vết: NFR-01-016, 022 · FR-01-016, 023, 027, 020, 032 · EVT-01-15.
    Biết đồng hồ giả; các tình huống: hồ sơ quá hạn, SANDBOX quá 30 ngày, định danh còn 7 ngày, saga lỗi, cắt quyền chưa hoàn tất, HTTT ACTIVE chưa rà soát trong 6 tháng.
    Khi tạo từng tình huống; đọc cảnh báo ở PH-13.
    Và chạy tác vụ dọn; kiểm dữ liệu quá hạn lưu giữ.
    Thì mỗi tình huống đúng một cảnh báo; tác vụ dọn xóa bàn giao quá 3 năm, kiểm thử SANDBOX quá 1 năm, giữ kỳ rà soát 5 năm; hồ sơ và HTTT đã chấm dứt giữ vĩnh viễn.

  @TC-01-142 @P2 @Dương
  Kịch bản: TC-01-142 Chỉ số quan sát của phân hệ
    # Truy vết: NFR-01-015 · FR-01-019, 040 · UI-01-17.
    Biết prometheus thử thu từ `dh-connect`; dữ liệu một chu kỳ kết nạp đầy đủ.
    Khi chạy chu kỳ: tạo, nộp, duyệt, kích hoạt, thu hồi một định danh, mở kỳ rà soát.
    Và đọc các chỉ số `onboarding_applications_total{status}`, `onboarding_stage_duration_days{stage}`, `onboarding_members_total{status,group}`, `onboarding_credential_expiring_total`, `onboarding_scope_unused_total`.
    Thì mỗi chỉ số có mặt, nhãn đúng, giá trị khớp số liệu ở UI-01-17 và API-01-086; không có nhãn chứa dữ liệu cá nhân hay mã bí mật.

  @TC-01-143 @P2 @Hiệunăng @Khảdụng
  Kịch bản: TC-01-143 Thời gian kết nạp đầu cuối
    # Truy vết: NFR-01-020 · FR-01-012, 018, 024 · UC-01-06, 12, 17.
    Biết một hồ sơ thí điểm không bị trả bổ sung (mục 6.2); đồng hồ làm việc thật.
    Khi ghi thời điểm nộp, từng kết luận thẩm định, phê duyệt, bàn giao, kiểm thử đạt, kích hoạt.
    Thì từ nộp đến gọi được API môi trường thật ≤ 5 ngày làm việc, phần của PH-01 ≤ 3 ngày làm việc (KPI-05); chênh lệch so với hạn 2 ngày mỗi bước ghi vào báo cáo.
