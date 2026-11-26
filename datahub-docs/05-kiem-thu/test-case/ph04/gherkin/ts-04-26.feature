# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-26
Tính năng: TS-04-26 · Chuyển Camel XML của Bus cũ

  @TC-04-151 @P1 @Dương
  Kịch bản: TC-04-151 Chuyển gói XML ba route
    # Truy vết: FR-04-082 · API-04-028 · UI-04-18 · UC-04-20.
    Biết XML-OK; bảng ánh xạ kết nối cũ → PH-05 (`connectionMap`).
    Khi gọi `POST /legacy-imports` (multipart) với `file`, `workspaceCode = "ho-tich"`, `connectionMap`.
    Và gọi `GET /legacy-imports/{jobId}` tới khi `COMPLETED`.
    Và mở từng luồng tạo ra.
    Thì bước 1 trả `202`. Bước 2: `report.routes = 3`, `stepsConverted`, `stepsManual`, `connectionsToDeclare` (kết nối chưa có trong bảng ánh xạ), `recommendations` (ví dụ "Bọc route REST bằng khung chín chặng"); `createdFlows` có 3 mã, mỗi luồng ở `DRAFT`. Bước 3: YAML không còn mật khẩu, URL có thông tin đăng nhập được thay bằng `{{conn:…}}` theo bảng ánh xạ; chặng không chuyển được hiện chặng giữ chỗ màu cảnh báo kèm XML gốc trong ghi chú.

  @TC-04-152 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-152 Tệp XML không hợp lệ hoặc nguy hiểm
    # Truy vết: FR-04-082 · API-04-028 · ERR-04-032, 046.
    Biết XML-BAD, XML-EXEC, XML có thực thể ngoài (XXE `<!ENTITY x SYSTEM "file:///etc/passwd">`), tệp 3 MiB, tệp `.exe` đổi tên.
    Khi tải lần lượt từng tệp.
    Thì XML-BAD trả `422` ERR-04-032. XML-EXEC: chuyển được nhưng `report.forbiddenComponents = ["exec"]`, chặng bị thay bằng giữ chỗ. XXE: `422` ERR-04-032, không đọc tệp hệ thống (parser tắt DTD). 3 MiB trả `413` ERR-04-033. `.exe` trả `415` ERR-04-046.

  @TC-04-201 @P3 @Dương @Âm
  Kịch bản: TC-04-201 Trạng thái màn Nhập luồng hệ cũ
    # Truy vết: FR-04-082 · UI-04-18 · ERR-04-032.
    Biết U-T68-IE1; gói XML-OK nén `.zip`; XML-BAD; U-T68-VW.
    Khi IE1 mở UI-04-18 bước ①.
    Và thả gói `.zip` và chờ phân tích.
    Và rời trang giữa lúc phân tích, mở lại từ khay nền.
    Và thả XML-BAD.
    Và VW mở URL của UI-04-18.
    Thì bước 1: dropzone "Kéo tệp XML hoặc ZIP vào đây". Bước 2: "Đang phân tích {k}/{n} route" rồi bảng ba nhóm Tự động, Cần chỉnh, Không chuyển được. Bước 3: ST-10 hỏi trước khi rời, tác vụ vẫn chạy và mở lại đúng kết quả. Bước 4: ST-05 với ERR-04-032. Bước 5: ST-06. Phím `Enter` tiếp tục, `Alt+←` quay lại.
