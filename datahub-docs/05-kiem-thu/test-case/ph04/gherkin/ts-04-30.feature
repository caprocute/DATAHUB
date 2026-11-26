# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-30
Tính năng: TS-04-30 · Bảo mật (ASVS)

  @TC-04-173 @P1 @Bảo @mật
  Kịch bản: TC-04-173 Quét động có xác thực
    # Truy vết: FR-04-001, 003, 024, 030 · API-04-001, 091.
    Biết ZAP với ngữ cảnh IE1, IA1, TA; nhập `openapi-integration.yaml`.
    Khi quét chủ động toàn bộ API và UI-04-01…21.
    Thì không cảnh báo mức Cao; cảnh báo Trung bình có ngoại lệ được SO ký. Tiêu đề `Content-Security-Policy` không có `unsafe-eval` (Monaco chạy với worker, không `eval`).

  @TC-04-174 @P1 @Bảo @mật
  Kịch bản: TC-04-174 Chèn mã qua nội dung luồng và hiển thị
    # Truy vết: FR-04-002, 013, 014 · UI-04-02, 04, 05.
    Biết tên luồng, mô tả chặng, ghi chú dán, nhãn, ý kiến duyệt, tên tệp XML đều chứa `<img src=x onerror=alert(1)>` và `{{constructor.constructor('alert(1)')()}}`.
    Khi lưu và mở mọi màn hiển thị các trường đó.
    Thì hiển thị nguyên văn, không thực thi; không có hộp thoại (Playwright lắng nghe sự kiện `dialog`).

  @TC-04-175 @P1 @Bảo @mật
  Kịch bản: TC-04-175 Biểu thức không thoát được khỏi sandbox
    # Truy vết: FR-04-015, 030 · API-04-032, 040.
    Biết biểu thức `simple` `${bean:java.lang.Runtime?method=getRuntime}`, `${sys.user.home}`, `${env.PATH}`, `jq` `input_filename`, `env`; chặng `exec` trong lần chạy thử.
    Khi kiểm và đánh giá từng biểu thức qua API-04-032.
    Và chạy thử luồng có các biểu thức đó.
    Thì kiểm trả lỗi "Không được phép" (VR-16, VR-19); sandbox chạy với `camel.main.bean-introspection` hạn chế, không có biến môi trường của pod, hệ tệp chỉ đọc, không mạng ra ngoài ngoài WireMock (NetworkPolicy `dh-sandbox`).

  @TC-04-176 @P1 @Bảo @mật
  Kịch bản: TC-04-176 Lệnh điều khiển chỉ từ control plane
    # Truy vết: FR-04-050 · EVT-04-11.
    Biết chứng thư mTLS của `dh-runtime` T68.
    Khi dùng chứng thư runtime ghi vào `dh.integration.runtime.command.v1`.
    Và dùng chứng thư PH-07 đọc topic đó.
    Thì cả hai bị ACL Kafka từ chối. Khóa ký ở OpenBao không xuất được (`exportable = false`).

  @TC-04-177 @P2 @Bảo @mật
  Kịch bản: TC-04-177 Chuỗi cung ứng ảnh và kho cấu hình
    # Truy vết: FR-04-075, 042.
    Biết ảnh `dh-runtime` chưa ký; commit không ký trên `env/prod`.
    Khi triển khai ảnh chưa ký.
    Và đẩy commit không ký.
    Thì kyverno chặn ảnh chưa ký. Nhánh `env/prod` được bảo vệ, chỉ nhận merge request qua CI của kho cấu hình.

  @TC-04-178 @P3 @Bảo @mật
  Kịch bản: TC-04-178 Giới hạn tần suất API điều khiển
    # Truy vết: FR-04-024 · API-04-022 · ERR-04-048.
    Biết một người dùng gửi 50 lần lưu nháp mỗi giây.
    Khi chạy 30 giây.
    Thì phần vượt nhận `429` ERR-04-048 có `Retry-After`; người dùng khác không bị ảnh hưởng.
