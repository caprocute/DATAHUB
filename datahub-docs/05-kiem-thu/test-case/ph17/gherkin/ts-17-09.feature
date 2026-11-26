# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-09
Tính năng: TS-17-09 · Mô hình ngoài bị từ chối khi chưa được bật

  @TC-17-027 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-027 Tenant chưa bật mô hình ngoài: không định tuyến được tới mô hình ngoài
    # Truy vết: FR-17-003, 010 · API-17-045, 046, 095 · BR-17-004 · ERR-17-016, 017
    # Mục đích: Chứng minh chính sách tenant chặn định tuyến tới mô hình ngoài dù mô hình đã `APPROVED` và nền tảng đã khai báo.
    Biết T90 `17.model.external-allowed = false`; `MV-EXT-1` `APPROVED`; U-T90-TA1, U-T90-IE.
    Khi TA1 `POST /tenant-models/{MV-EXT-1}:enable`.
    Và TA1 `PUT /tenant-models/defaults` đặt `chat = MV-EXT-1`.
    Và IE gửi câu hỏi.
    Và xem `GET /invocations` và số gói tin tới điểm cuối `P-EXT-VN` ở egress.
    Thì bước 1 và 2 `422` ERR-17-016 hoặc `409` ERR-17-017 (nêu lý do chính sách). Bước 3 `200` từ mô hình nội bộ hoặc `409` ERR-17-033 nếu không có nội bộ. Bước 4 không lời gọi nào tới `MV-EXT-1`, 0 gói tin tới điểm cuối ngoài.

  @TC-17-028 @P1 @Bảo_mật
  Kịch bản: TC-17-028 Đích ngoài danh sách egress bị chặn ở mạng và cảnh báo
    # Truy vết: FR-17-003, 011 · NFR-17-020 · BR-17-012 · ERR-17-039 · EVT-17-19
    # Mục đích: Chứng minh Cilium và Istio egress chặn đích ngoài danh sách, kể cả khi mã gọi sai cấu hình (NFR-17-020).
    Biết STAGING; pod `dh-assist` T90; tuyến `ai-proxy` chỉ cho `api.nhacungcap.vn`; đích thử `thu.example.test`.
    Khi từ pod `dh-assist` gọi `https://thu.example.test`.
    Và cấu hình thử đích `thu.example.test` ở `PATCH /model-providers/{id}`.
    Và xem cảnh báo ở Alertmanager.
    Thì bước 1 kết nối bị chặn (0 kết nối ra). Bước 2 `422` ERR-17-039. Bước 3 cảnh báo xuất hiện ≤ 5 phút.

  @TC-17-029 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-029 Dữ liệu mức cao hơn INTERNAL không được gửi tới mô hình ngoài
    # Truy vết: FR-17-060, 003 · API-17-187 · BR-17-081 · ERR-17-107 · ERR-17-102
    # Mục đích: Chứng minh BR-17-081 ở data plane và ở hội thoại.
    Biết T90 đã bật mô hình ngoài hợp lệ; định tuyến nhiệm vụ `CLASSIFY_TEXT` tới `MV-EXT-1`; S-T90-PH04 có `assist:infer`.
    Khi S-T90-PH04 `POST /assist/v1/inference/classify` với `dataClass = RESTRICTED`, `purpose = MD-PHANLOAI`.
    Và như trên với `dataClass = INTERNAL`.
    Và như trên với `dataClass = PUBLIC` nhưng nội dung chứa số CCCD giả dạng rõ.
    Thì bước 1 `422` ERR-17-107, không có lời gọi tới `MV-EXT-1`. Bước 2 `200`. Bước 3 `422` ERR-17-115 (mẫu DLCN chưa che) hoặc được che trước khi gửi, vết không chứa nội dung thô.
