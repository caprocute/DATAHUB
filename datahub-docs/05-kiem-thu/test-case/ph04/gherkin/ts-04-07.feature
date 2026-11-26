# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-07
Tính năng: TS-04-07 · Quay vòng YAML, tải xuống, nhập YAML

  @TC-04-043 @P1 @Dương
  Kịch bản: TC-04-043 Quay vòng không sửa giữ nguyên băm
    # Truy vết: FR-04-017 · BR-04-006 · UI-04-04.
    Biết 40 tệp YAML mẫu trong `src/test/resources/roundtrip/` (gồm mọi EIP trong catalog, chú thích YAML, khóa không theo thứ tự, chuỗi nhiều dòng, ký tự tiếng Việt).
    Khi với mỗi tệp: nạp thành cây tài nguyên, sinh lại YAML, tính băm chuẩn hóa.
    Và kiểm thử theo thuộc tính (fast-check): sinh cây ngẫu nhiên hợp lệ 1.000 lần, YAML → cây → YAML.
    Và E2E: mở F-HT v4, chuyển tab Sơ đồ → YAML → Sơ đồ ba lần, không sửa.
    Thì bước 1, 2: băm chuẩn hóa trước và sau bằng nhau trong 100% trường hợp; thuộc tính không có trong catalog (thuộc tính tùy biến) được giữ nguyên. Bước 3: chỉ báo "Đã lưu" không đổi, không có lần lưu nào được gửi.

  @TC-04-044 @P1 @Dương @Âm
  Kịch bản: TC-04-044 Sửa trong YAML phản ánh lên sơ đồ
    # Truy vết: FR-04-017 · UI-04-04.
    Biết IE1 mở F-HT v4, tab YAML (Monaco).
    Khi thêm một bước `log` bằng tay trong YAML.
    Và gõ sai thụt lề.
    Và chuyển sang tab Sơ đồ khi YAML đang lỗi.
    Thì bước 1: sau 500 ms sơ đồ có chặng `log` đúng vị trí. Bước 2: gạch đỏ tại dòng, bảng Vấn đề có VR-01. Bước 3: hộp "YAML đang có lỗi cú pháp. Sơ đồ đang hiển thị bản hợp lệ gần nhất." và không ghi đè nội dung đang gõ.

  @TC-04-045 @P1 @Dương @Bảo @mật
  Kịch bản: TC-04-045 YAML triển khai không chứa bố cục, bản tin mẫu, ghi chú
    # Truy vết: FR-04-017, 022, 026 · BR-04-007 · API-04-026.
    Biết F-HT v4 có bố cục, bản tin mẫu MSG-OK ở ba chặng, hai ghi chú dán.
    Khi gọi `GET .../versions/4/download?format=yaml`.
    Và gọi `GET .../versions/4/download?format=yaml+layout`.
    Và sau khi v4 được phát hành ở TEST, đọc tệp `flows/tra-cuu-ho-tich/flow.camel.yaml` trên `env/test`.
    Thì bước 1 và 3: không có khóa `dh-layout`, `dh-samples`, `dh-notes`, không có chuỗi `001099000001`. Bước 2: có bố cục ở khối chú thích tách riêng để nhập lại được. Băm chuẩn hóa của tệp trên Git bằng `contentHash` của v4.

  @TC-04-046 @P2 @Dương
  Kịch bản: TC-04-046 Nhập YAML thay định nghĩa
    # Truy vết: FR-04-027 · API-04-027.
    Biết F-HT v4; tệp YAML đã sửa ngoài.
    Khi gọi `POST .../versions/4:import-yaml` với `keepLayout = true`.
    Thì `200`; định nghĩa thay mới; chặng có cùng `id` giữ vị trí cũ trên sơ đồ, chặng mới được tự sắp xếp. `validation` trả kèm.

  @TC-04-047 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-047 Nhập YAML không hợp lệ
    # Truy vết: FR-04-027 · API-04-027 · ERR-04-008, 009, 033.
    Biết YAML-BOMB, YAML-BIG, YAML có thẻ `!!java.lang.Runtime`.
    Khi nhập YAML-BOMB.
    Và nhập YAML-BIG.
    Và nhập YAML có thẻ kiểu Java.
    Và nhập YAML của Kamelet vào phiên bản loại ROUTE.
    Thì bước 1 trả `422` ERR-04-008 trong < 1 giây, bộ nhớ heap không tăng quá 50 MiB (VR-01 giới hạn bí danh 50, độ sâu 64). Bước 2 trả `413` ERR-04-033. Bước 3 trả `422` ERR-04-008, không tạo đối tượng Java (SnakeYAML Engine không hỗ trợ thẻ toàn cục). Bước 4 trả `422` ERR-04-009.
