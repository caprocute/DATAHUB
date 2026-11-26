# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-08
Tính năng: TS-04-08 · Biểu thức, kết nối, bí mật, bản tin mẫu

  @TC-04-048 @P1 @Dương
  Kịch bản: TC-04-048 Kiểm tra và xem trước biểu thức
    # Truy vết: FR-04-015 · API-04-032 · UI-04-06 · LGC-TOOL-006.
    Biết IE1; MSG-OK.
    Khi gọi `POST /expressions:check` với `{"language":"simple","expression":"${body[soDinhDanh]} != null","predicate":true}`.
    Và gọi với `jsonpath` `$.hoTen`, `evaluate = true`, `sample.body` = MSG-OK.
    Và gọi với `jq` `.ngaySinh | split("-")[0]`, `evaluate = true`.
    Và trên UI-04-06, gõ `${he` và chờ gợi ý.
    Thì bước 1 trả `200`, `valid = true`. Bước 2 trả `result = "Nguyễn Văn Thử"`, `resultType = String`, `simulated = false`. Bước 3 trả `"1990"`. Bước 4: gợi ý `header.`, `headers` kèm mô tả tiếng Việt.

  @TC-04-049 @P1 @Âm
  Kịch bản: TC-04-049 Biểu thức lỗi
    # Truy vết: FR-04-015 · API-04-032 · ERR-04-037, 019, 021.
    Biết IE1.
    Khi kiểm `simple` `${body[soDinhDanh}`.
    Và kiểm như bước 1 ở chế độ chặt.
    Và kiểm `jq` với `sample.body` = MSG-BIG.
    Và dừng sandbox, kiểm `jq` với `evaluate = true`.
    Và kiểm `groovy` (ngôn ngữ không có trong catalog).
    Thì bước 1 trả `200`, `valid = false`, `error.column` trỏ đúng vị trí; UI-04-06 tô đỏ vị trí. Bước 2 trả `422` ERR-04-037. Bước 3 trả `413` ERR-04-021. Bước 4 trả `503` ERR-04-019 (biên dịch không cần sandbox vẫn chạy được nếu `evaluate = false`). Bước 5 trả `400` ERR-04-049.

  @TC-04-050 @P1 @Dương
  Kịch bản: TC-04-050 Chọn kết nối PH-05 thay vì nhập thông tin đăng nhập
    # Truy vết: FR-04-016 · BR-04-003 · UI-04-05 · UC-04-05.
    Biết IE1 mở F-HT v4, chặng gửi đích.
    Khi mở ô "Kết nối", tìm "HT".
    Và chọn CONN-HT.
    Và chọn trường "Mật khẩu proxy", bấm "Tham chiếu bí mật", chọn `vault:ho-tich/proxy`.
    Thì bước 1 chỉ liệt kê kết nối đã cấp cho WS-HOTICH (không có CONN-DD-ONLY), hiện loại và môi trường có giá trị. Bước 2: YAML có `{{conn:CONN-HT}}`. Bước 3: YAML có `{{vault:ho-tich/proxy}}`; giao diện không có ô nào cho phép dán giá trị bí mật.

  @TC-04-051 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-051 Phát hiện bí mật mọi chỗ trong định nghĩa
    # Truy vết: FR-04-016, 023 · BR-04-003 · API-04-022 · ERR-04-010.
    Biết 24 mẫu bí mật: tham số URI `password=`, `accessKey=`, `Authorization: Basic …` trong `setHeader`, JWT, khóa PEM, chuỗi AWS `AKIA…`, giá trị bean `secret`, chuỗi entropy cao 40 ký tự trong thuộc tính tên `token`; và 10 mẫu hợp lệ: `{{conn:…}}`, `{{vault:…}}`, `#bean`, UUID, băm sha256 trong `contentHash`.
    Khi chạy `SecretDetector` trên từng mẫu (UT).
    Và lưu nháp với từng mẫu bí mật (API).
    Thì bước 1: phát hiện 24/24, không báo nhầm 10/10 mẫu hợp lệ. Bước 2: mỗi lần trả `422` ERR-04-010; `findings[].message` chỉ có đường dẫn và loại ("chuỗi giống mật khẩu"), không có giá trị; log ứng dụng và vết OpenTelemetry không có giá trị (quét bằng `grep` trên log IT).

  @TC-04-052 @P1 @Âm
  Kịch bản: TC-04-052 Kết nối không hợp lệ
    # Truy vết: FR-04-016, 023 · API-04-030 · ERR-04-013.
    Biết `tc-conn` tham chiếu lần lượt `{{conn:KHONG-CO}}`, CONN-DD-ONLY (chưa cấp cho WS-HOTICH), CONN-DKKD-RO cho chặng `http` (sai loại).
    Khi gọi `:validate` mức `DESIGN`.
    Và gọi `:validate` mức `SUBMIT`.
    Thì bước 1: ba finding VR-07 mức `WARN`. Bước 2: ba finding VR-07 mức `ERROR`, mã ERR-04-013 trong `args`.

  @TC-04-053 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-04-053 Ghim bản tin mẫu theo chặng và cảnh báo dữ liệu cá nhân
    # Truy vết: FR-04-022 · BR-04-007, 013 · UI-04-04, 05.
    Biết IE1 (không có `PERM-04-sample-data`), IE2 (được cấp `PERM-04-sample-data` cho F-HT).
    Khi IE1 ghim MSG-OK ở chặng `receive`.
    Và IE1 dán MSG-PII vào chặng `transform`.
    Và IE2 dán MSG-PII và chọn "Vẫn dùng".
    Thì bước 1: chặng sau dùng bản tin của chặng trước gần nhất (hiện nhãn "kế thừa từ Tiếp nhận"). Bước 2: cảnh báo "Bản tin mẫu có dấu hiệu chứa dữ liệu cá nhân (số điện thoại, thư điện tử)", nút "Thay bằng dữ liệu giả" và không có "Vẫn dùng". Bước 3: lưu được; KT: có (`INT_SAMPLE_PII_OVERRIDE`).

  @TC-04-189 @P2 @Âm @Khả @dụng
  Kịch bản: TC-04-189 Sandbox không sẵn sàng khi xem trước biểu thức
    # Truy vết: FR-04-015 · UC-04-05 · API-04-032 · UI-04-06 · ERR-04-019.
    Biết U-T68-IE1 mở F-HT v4 `DRAFT` trên UI-04-04; `dh-runtime-sandbox` thu về 0 bản sao; bản tin mẫu MSG-OK đã ghim.
    Khi mở trình soạn biểu thức (UI-04-06) của chặng `transform`, nhập `${body.soDinhDanh}` ngôn ngữ `simple`, bấm "Thử".
    Và đổi sang `jq` với `.hoTen`, bấm "Thử".
    Và đổi sang `xpath`, bấm "Thử".
    Và gọi thẳng `POST /expressions:check` với `evaluate = true`.
    Thì bước 4 trả `503` ERR-04-019. Bước 1, 2: giao diện không hiện hộp lỗi mà chuyển sang nhánh 6a của UC-04-05: đánh giá cục bộ trên trình duyệt, kết quả đúng giá trị của MSG-OK và bắt buộc gắn nhãn "Xem trước mô phỏng trên trình duyệt, kết quả có thể khác runtime". Bước 3: hiện "Chưa xem trước được" (ngôn ngữ không có bộ đánh giá cục bộ). Kiểm tra cú pháp (biên dịch) vẫn chạy, gạch sóng vẫn hiện khi gõ sai. Không có lần chạy thử nào được tạo; KT: không.
