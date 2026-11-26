# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-23
Tính năng: TS-15-23 · Đăng ký sử dụng, kết nạp, công bố (ủy thác)

  @TC-15-136 @P1 @Dương
  Kịch bản: TC-15-136 Gửi đăng ký sử dụng nhân danh đầu mối
    # Truy vết: FR-15-044 · UC-15-23 · API-15-087, 089 · UI-15-15 · BR-15-014 · LGC-APIM-016.
    Biết U-T68-OR (đầu mối HT-DATDAI); S-PH02.
    Khi UI-15-15: chọn `tra-cuu-ho-tich`, `HT-DATDAI`, gói, mục đích; gửi.
    Và `GET /subscriptions/{id}`.
    Thì `PENDING`; S-PH02 nhận bằng danh tính Bình (không dùng danh tính dịch vụ); KT: có (`SUBMIT_SUBSCRIPTION`); chi tiết đọc từ PH-02, cổng không lưu quyết định.

  @TC-15-137 @P1 @Âm
  Kịch bản: TC-15-137 Không phải đầu mối, nhà thầu, PH-02 lỗi
    # Truy vết: FR-15-044, 045 · UC-15-23 · API-15-087, 088 · ERR-15-030, 032 · LGC-APIM-016.
    Biết U-T68-DEV-AN; cán bộ không phải đầu mối; S-PH02 trả `ERR-02-*` nghiệp vụ; ngắt PH-02.
    Khi an gửi; cán bộ thường gửi.
    Và gửi khi PH-02 trả lỗi nghiệp vụ.
    Và gửi khi PH-02 ngắt.
    Thì `422` ERR-15-032; mã `ERR-02-*` và câu của PH-02 chuyển nguyên văn; `502` ERR-15-030 "Chưa kết nối được dịch vụ danh mục."

  @TC-15-138 @P2 @Dương
  Kịch bản: TC-15-138 Theo dõi, hủy, không tự duyệt
    # Truy vết: FR-15-045 · UC-15-23 · API-15-088, 089, 090 · BR-15-014 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết đăng ký PENDING của HT-DATDAI; đăng ký của HT-TUPHAP; Bình.
    Khi `GET /subscriptions`; chi tiết; `:cancel`.
    Và bình `GET` đăng ký của HT-TUPHAP; `POST /subscriptions/{id}:approve`.
    Thì danh sách chỉ của tổ chức Bình; hủy được khi PENDING (hủy khi không còn PENDING chuyển lỗi PH-02 nguyên văn); bước 2 `404` ERR-15-001 và `404` cho đường không tồn tại; cổng không có đường duyệt.

  @TC-15-139 @P1 @Dương
  Kịch bản: TC-15-139 Nộp hồ sơ kết nạp F-01
    # Truy vết: FR-15-046 · UC-15-24 · API-15-091, 092, 093 · UI-15-16 · BR-15-014, 015 · LGC-APIM-019; LGC-APIM-020.
    Biết bình (đầu mối); S-PH01 trả lỗi theo trường ở lần đầu.
    Khi gửi hồ sơ thiếu trường; sửa; gửi lại.
    Và `GET /onboarding/applications/{id}`.
    Thì lỗi theo trường của PH-01 hiện dưới từng trường; thành công tạo hồ sơ ở PH-01, theo dõi được; không có bí mật production ở bất cứ phản hồi nào; KT: có (`SUBMIT_ONBOARDING`).

  @TC-15-140 @P2 @Âm
  Kịch bản: TC-15-140 Không phải đầu mối, PH-01 lỗi
    # Truy vết: FR-15-046 · API-15-091 · ERR-15-031, 032 · LGC-APIM-019; LGC-APIM-020.
    Biết cán bộ không phải đầu mối; ngắt PH-01.
    Khi gửi hồ sơ ở hai tình huống.
    Thì `422` ERR-15-032; `502` ERR-15-031, bản nháp giữ lại.

  @TC-15-141 @P1 @Dương
  Kịch bản: TC-15-141 Công bố API từ cổng
    # Truy vết: FR-15-047 · UC-15-25 · API-15-094, 095, 096 · UI-15-17 · BR-15-001, 014 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV (chủ dịch vụ HT-TUPHAP); đặc tả hợp lệ.
    Khi mở `/cong-bo/moi`, tải đặc tả, gửi.
    Và `GET /publications/{id}`.
    Thì PH-02 tạo đăng ký API ở trạng thái nháp theo F-02; cổng không tự đăng API; KT: có (`SUBMIT_PUBLICATION`).

  @TC-15-142 @P2 @Âm
  Kịch bản: TC-15-142 Không phải chủ dịch vụ, đặc tả lỗi, PH-02 ngắt
    # Truy vết: FR-15-047 · API-15-094 · ERR-15-005, 030 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết bình; đặc tả sai ở dòng 12; ngắt PH-02.
    Khi bình gửi.
    Và chi gửi đặc tả sai.
    Và chi gửi khi PH-02 ngắt.
    Thì `403` ERR-15-005; lỗi từng dòng của PH-02 hiển thị tại chỗ; `502` ERR-15-030.
