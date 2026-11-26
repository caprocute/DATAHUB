# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-06
Tính năng: TS-17-06 · Khai báo nhà cung cấp mô hình và cam kết lưu dữ liệu trong nước

  @TC-17-018 @P1 @Dương
  Kịch bản: TC-17-018 Khai báo nhà cung cấp nội bộ và kiểm tra kết nối
    # Truy vết: FR-17-007, 014 · API-17-027, 028, 029, 030 · BR-17-011 · UI-17-19 · EVT-17-06
    # Mục đích: Chứng minh khai báo `INTERNAL` hợp lệ, `secret_ref` được kiểm tồn tại và kết nối thử đạt.
    Biết openBao có `openbao://kv/tenants/COMMON/assist/provider-vllm`; vLLM giả lập; U-PA1.
    Khi PA1 `POST /model-providers` `kind = INTERNAL`, `endpoint = https://vllm.dh-assist.svc`, `secret_ref` như trên.
    Và PA1 `POST /model-providers/{id}:test-connection`.
    Và PA1 `GET /model-providers/{id}` và đọc toàn bộ thân, nhật ký `dh-assist` 5 phút.
    Thì bước 1 `201`, `ProviderStatus = DRAFT`, KT: có. Bước 2 `200` kết quả `OK`, độ trễ ghi nhận. Bước 3 chỉ có `secret_ref`, không có giá trị bí mật ở thân, log, vết OTel (BR-17-011).

  @TC-17-019 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-019 Điểm cuối không hợp lệ, thiếu cam kết, bí mật không tồn tại
    # Truy vết: FR-17-007, 003 · API-17-027, 029, 032 · BR-17-011, 012, 013 · ERR-17-025, 026, 028 · ERR-17-002
    # Mục đích: Chứng minh quy tắc điểm cuối ngoài (HTTPS, FQDN, không IP trần, không dải nội bộ hay siêu dữ liệu cloud) và hồ sơ cam kết.
    Biết U-PA1; OpenBao có `openbao://kv/tenants/COMMON/assist/provider-x`.
    Khi `POST /model-providers` `EXTERNAL` với `endpoint = http://api.nhacungcap.vn` (HTTP).
    Và với `https://203.0.113.10/v1` (IP trần).
    Và với `https://169.254.169.254/latest` và `https://10.0.0.5/`.
    Và với `https://api.nhacungcap.vn` nhưng không có hồ sơ cam kết, rồi kích hoạt.
    Và với `secret_ref = openbao://kv/tenants/COMMON/assist/khong-co`.
    Và tạo hai nhà cung cấp cùng `code`.
    Thì bước 1 đến 3 `422` ERR-17-025. Bước 4 không kích hoạt được, `422` ERR-17-026. Bước 5 `422` ERR-17-028. Bước 6 `409` ERR-17-002. Không có bản ghi nhà cung cấp lỗi ở trạng thái `ACTIVE`.

  @TC-17-020 @P2 @Dương @Âm
  Kịch bản: TC-17-020 Đình chỉ nhà cung cấp đang được mô hình sử dụng
    # Truy vết: FR-17-007 · API-17-031, 029 · ERR-17-027 · EVT-17-06 · ERR-17-001
    # Mục đích: Chứng minh đình chỉ chặn lời gọi tới các mô hình của nhà cung cấp và báo số mô hình đang dùng.
    Biết `P-EXT-VN` đang cấp cho 2 phiên bản mô hình `APPROVED` đang được tenant bật; U-PA1.
    Khi PA1 `POST /model-providers/{id}:suspend`.
    Và PA1 `PATCH /model-providers/{id}` đổi `endpoint` sang địa chỉ HTTP.
    Và PA1 ngừng (`RETIRED`) nhà cung cấp khi còn 2 mô hình dùng.
    Và PA1 `GET /model-providers/khong-co`.
    Thì bước 1 `200` `SUSPENDED`, EVT: `assist.provider.state-changed`, lời gọi mới tới mô hình của nhà cung cấp này bị từ chối. Bước 2 `422` ERR-17-025. Bước 3 `409` ERR-17-027 nêu 2 mô hình. Bước 4 `404` ERR-17-001.
