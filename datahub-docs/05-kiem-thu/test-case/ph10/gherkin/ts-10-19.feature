# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-19
Tính năng: TS-10-19 · Giao nhận nội bộ và hợp đồng PH-04

  @TC-10-085 @P1 @Dương @Âm
  Kịch bản: TC-10-085 Kiểm tra quyền phát, nhận của luồng: ALLOWED, PENDING, DENIED
    # Truy vết: FR-10-069 · API-10-071 · UC-10-25 · BR-04-009
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-069 (Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế).
    Biết S-PH04; PB-FLOW có publication `ACTIVE` trên TP-CP; luồng `dkkd-tong-hop` có đề nghị subscription TP-GT đang chờ; TP-TD `DEPRECATED`.
    Khi `POST /permissions:check` với bốn bộ: (`dkkd-tong-hop`, TP-CP, `PUBLISH`), (`dkkd-tong-hop`, TP-GT, `SUBSCRIBE`), (`dkkd-tong-hop`, TP-RDM, `SUBSCRIBE`), (`dkkd-tong-hop`, `t68.khong.co.gi.v1`, `PUBLISH`).
    Và thêm bộ (`dkkd-tong-hop`, TP-TD, `SUBSCRIBE`) khi luồng chưa có subscription trên TP-TD.
    Và U-T68-IE1 gọi `POST /permissions:check`.
    Thì bước 1 `200`: `ALLOWED`; `PENDING`; `DENIED` `NO_GRANT`; `DENIED` `TOPIC_NOT_FOUND`. Bước 2 `DENIED` `TOPIC_NOT_ACTIVE`. Bước 3 403-PQ (chỉ scope `event:permission-check`). Không ghi kiểm toán.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-086 @P1 @Dương @Âm
  Kịch bản: TC-10-086 ensure-party, tra cứu topic dùng được và phụ thuộc của luồng
    # Truy vết: FR-10-069, 027 · API-10-072, 008, 109 · ERR-10-022, 025 · API-04-016
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-069 (Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế).
    Biết S-PH04; luồng mới `tc-luong-moi` ở SIM-PH04; luồng `luong-cu` `RETIRED`.
    Khi `POST /flows/tc-luong-moi:ensure-party` với topic đầu ra TP-CP, topic đầu vào TP-GT; gọi lại lần hai cùng thân.
    Và `GET /topics?usableBy=flow:tc-luong-moi&action=SUBSCRIBE`.
    Và `GET /flows/tc-luong-moi/dependencies`.
    Và `ensure-party` cho `luong-cu`; cho topic `RETIRED`.
    Thì bước 1 tạo bên phát, bên nhận `FLOW` và đề nghị publication, subscription `PENDING_APPROVAL`; lần hai không tạo trùng. Bước 2 danh sách kèm lược đồ hiện hành cho DataMapper. Bước 3 trả publication, subscription của luồng. Bước 4 `422` ERR-10-022; `422` ERR-10-025. KT: có cho `ensure-party`.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-087 @P1 @Dương @Âm
  Kịch bản: TC-10-087 Luồng tiêu thụ nội bộ đúng nhóm, lag được tính, không cấp scope OAuth
    # Truy vết: FR-10-045 · BR-10-018, 022 · FR-04-062
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-045 (Giao nhận nội bộ cho luồng và DU).
    Biết SUB-FLOW `ACTIVE`; Kamelet `dh-kafka-source` của luồng `dkkd-dong-bo-thue` trên `dh-runtime-t68`.
    Khi phát 100 sự kiện lên TP-CP; luồng tiêu thụ.
    Và luồng dùng `group.id = dh-flow-t68-luong-khac`; principal nội bộ T68 đọc topic `t01.*`.
    Và kiểm tra client OAuth của bên `FLOW`.
    Thì bước 1 nhóm `dh-flow-t68-dkkd-dong-bo-thue` commit 100; lag ở UI-10-17 về 0. Bước 2 nhóm khác tên đọc được trong tiền tố tenant nhưng PH-10 không ghi nhận subscription nên VR-10 cảnh báo; đọc `t01.*` bị ACL từ chối. Bước 3 không có scope `topic:*` nào được cấp (BR-10-018).
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-088 @P2 @Âm @Khả @dụng
  Kịch bản: TC-10-088 PH-10 ngừng khi PH-04 kiểm tra quyền
    # Truy vết: FR-10-069 · API-10-071 · ERR-10-029
    # Mục đích: Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-069 (Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế).
    Biết S-PH04; `pg-core` của `ph10_event` dừng.
    Khi `POST /permissions:check`.
    Thì `503` ERR-10-029 có `Retry-After`; PH-04 chặn gửi duyệt luồng theo D02-03-PH04 §10; luồng đang chạy không bị ảnh hưởng.
    # Hậu điều kiện: Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
