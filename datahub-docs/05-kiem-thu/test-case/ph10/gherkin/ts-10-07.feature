# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-07
Tính năng: TS-10-07 · Tương thích lược đồ Apicurio và topic .v{n+1}

  @TC-10-033 @P1 @Dương @Âm
  Kịch bản: TC-10-033 Ma trận tương thích theo từng mức
    # Truy vết: FR-10-018 · API-10-026 · ERR-10-016 · BR-10-012 · ADR-070
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-018 (Kiểm tra tương thích với các phiên bản đã có).
    Biết topic thử với v1 = F-AV1; F-AV-ADD, F-AV-DEL, F-AV-BRK.
    Khi với từng mức `BACKWARD`, `FORWARD`, `FULL`, `BACKWARD_TRANSITIVE` chạy `:check` cho ba tệp.
    Thì `BACKWARD`: ADD đạt, DEL đạt, BRK không đạt. `FORWARD`: ADD đạt, DEL không đạt (trường không mặc định), BRK không đạt. `FULL`: chỉ ADD đạt. `BACKWARD_TRANSITIVE` so với mọi phiên bản `ENABLED`, `DEPRECATED`. Báo cáo không đạt có đường dẫn trường và quy tắc vi phạm.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-034 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-034 Ghi thẳng phiên bản phá vỡ vào Apicurio bị chặn
    # Truy vết: FR-10-024, 034 · API-10-084 · ERR-10-102 · BR-10-008, 013
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-024 (Cung cấp tra cứu lược đồ cho bên ngoài).
    Biết client C-DKKD có scope `topic:{TP-CP}:publish`; serde Apicurio với `auto.register = true` cố ý.
    Khi gọi `POST /event/v1/registry/apis/registry/v3/groups/t68/artifacts/{TP-CP}/versions` với F-AV-BRK.
    Và producer Kafka của PB-DKKD-K bật tự đăng ký lược đồ và gửi bản tin theo F-AV-BRK.
    Thì bước 1 bị từ chối (đường tra cứu chỉ đọc, `403` ERR-10-102). Bước 2 Apicurio từ chối đăng ký; producer nhận lỗi; không có phiên bản mới ở artifact.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-035 @P1 @Dương
  Kịch bản: TC-10-035 Bên nhận cũ đọc dữ liệu theo lược đồ mới
    # Truy vết: FR-10-018, 019, 038 · ADR-070 · BR-10-012
    # Mục đích: Chứng minh luồng thành công, theo FR-10-018 (Kiểm tra tương thích với các phiên bản đã có).
    Biết SUB-PUSH, SUB-KAFKA; TP-CP v4 `ENABLED` (thêm trường có mặc định).
    Khi phát 50 sự kiện v3 và 50 sự kiện v4 xen kẽ.
    Và consumer của HT-KBNN cấu hình đọc theo v3.
    Thì SUB-PUSH giao đủ 100 sự kiện, `ce_dataschema` trỏ đúng phiên bản mỗi sự kiện. Consumer v3 giải tuần tự được cả 100 (trường mới bị bỏ qua). Không có mục DLQ ERR-10-116.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-036 @P1 @Âm
  Kịch bản: TC-10-036 Thay đổi phá vỡ không có đường nào ngoài .v{n+1}
    # Truy vết: FR-10-015, 021 · API-10-015, 027 · ERR-10-016, 019, 047 · BR-10-013
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-015 (Tạo phiên bản chính mới của topic khi thay đổi phá vỡ).
    Biết U-T68-IE1, U-T68-TA; TP-CP; F-AV-BRK.
    Khi đề nghị hạ mức tương thích TP-CP về `NONE` để đưa F-AV-BRK vào.
    Và đề nghị đổi mức về `FORWARD` rồi gửi F-AV-BRK.
    Và gọi `:new-major-version` với F-AV-BRK.
    Thì bước 1 `422` ERR-10-019 (topic đã từng `ACTIVE`). Bước 2 khi đổi mức, kiểm tra trước phát hiện v1…v4 vẫn thỏa `FORWARD` nên được duyệt; gửi F-AV-BRK vẫn `409` ERR-10-016 (không tương thích `FORWARD`). Bước 3 là đường duy nhất được nhận, tạo `.v2`.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
