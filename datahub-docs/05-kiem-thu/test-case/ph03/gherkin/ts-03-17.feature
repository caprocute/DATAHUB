# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-17
Tính năng: TS-03-17 · Phát ảnh chụp, nạp nóng ở nút và quay lui

  @TC-03-072 @P1 @Dương
  Kịch bản: TC-03-072 Phát ảnh chụp, nút nạp nóng không lỗi lượt gọi
    # Truy vết: FR-03-042, 043 · API-03-060, 063 · UI-03-10, 11 · UC-03-20 · EVT-03-01 · BR-03-010, 016 · NFR-03-008, 024.
    Biết U-T68-TA; ảnh chụp đã build; tải 2.000 lượt/giây qua 3 bản sao `apisix-int`.
    Khi `POST /snapshots/{version}:publish`.
    Và đo độ trễ lan truyền tới mọi nút và số lượt gọi lỗi trong 60 giây quanh thời điểm phát.
    Và `GET /nodes`.
    Và kiểm Git và bucket.
    Thì bước 1 `200`; EVT: `snapshot.published`. Bước 2 mọi nút chạy phiên bản mới ≤ 10 s (≤ 60 s theo yêu cầu hệ thống), 0 lượt gọi lỗi, không khởi động lại nút. Bước 3 mọi nút `version` mới, `inSync = true`. Bước 4 có ảnh chụp ở cả hai nơi, hash khớp. KT: có (`SNAPSHOT_PUBLISH`).

  @TC-03-073 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-03-073 Không ghi được Git hoặc bucket: cấu hình đang chạy không đổi
    # Truy vết: FR-03-042 · API-03-060 · UI-03-10 · ERR-03-014, 015, 006 · BR-03-010, 016 · SEC-65.
    Biết `SIM-GIT` từ chối ghi; sau đó `SIM-BUCKET` từ chối; tải nền 100 lượt/giây.
    Khi publish khi `SIM-GIT` từ chối.
    Và publish khi `SIM-BUCKET` từ chối.
    Và phục hồi; publish lại cùng phiên bản.
    Thì bước 1, 2 `502` ERR-03-014 "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi, hệ thống sẽ thử lại." kèm `retryAfterSeconds`; nút không nhận phiên bản dang dở; 0 lượt gọi lỗi. Bước 3 `200`, không tạo bản trùng.

  @TC-03-074 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-074 Nút từ chối ảnh chụp sai chữ ký, phiên bản cũ hoặc hash lệch
    # Truy vết: FR-03-043, 045 · API-03-063, 064 · UI-03-11 · BR-03-016, 018 · SEC-65 · EVT-03-09.
    Biết bộ đồng bộ ở nút; ảnh chụp giả: chữ ký sai, phiên bản bằng bản đang chạy, `contentHash` lệch, cấu hình bị sửa trực tiếp trên pod.
    Khi đẩy từng ảnh chụp giả vào bucket.
    Và sửa cấu hình trực tiếp trên một pod.
    Và `GET /nodes/{nodeId}`; `GET /security-alerts`.
    Thì bước 1 nút từ chối cả ba, giữ cấu hình đang chạy, lượt gọi không lỗi. Bước 2 lệch so với Git bị phát hiện ≤ 1 giờ, nút báo `drift`. Bước 3 nút ghi `lastRejected` kèm lý do; có cảnh báo an ninh mức Cao.

  @TC-03-075 @P1 @Chịu @lỗi
  Kịch bản: TC-03-075 Control plane ngừng: gateway chạy tiếp, pod khởi động lại vẫn có cấu hình
    # Truy vết: FR-03-043 · API-03-064 · UI-03-11 · UC-03-20 · BR-03-010 · NFR-03-007 · NFR-00-012.
    Biết tải 300 lượt/giây; Chaos ngắt `dh-connect`, Argo CD, Git, bucket và Keycloak 24 giờ (rút gọn bằng `faketime`).
    Khi ngắt các thành phần trên.
    Và xóa lần lượt từng pod APISIX (`maxUnavailable: 1`).
    Và gọi liên tục trong 24 giờ giả lập.
    Thì tỉ lệ lỗi do nền tảng < 0,1 %; pod mới khởi động có đủ cấu hình từ bản chụp cục bộ và phục vụ ngay; token vẫn xác minh được nhờ JWKS đệm (ở ≤ 24 giờ); `GET /nodes` khi hồi phục báo đúng phiên bản.

  @TC-03-076 @P1 @Dương
  Kịch bản: TC-03-076 Quay lui bằng ảnh chụp mới mang nội dung bản cũ
    # Truy vết: FR-03-044 · API-03-061, 062, 056 · UI-03-10 · UC-03-21 · EVT-03-02 · BR-03-018, 016 · NFR-03-008 · SEC-65.
    Biết U-T68-TO; ảnh chụp 41 (tốt), 42 (làm hỏng `r-ho-tich` cố ý) đang chạy.
    Khi `GET /snapshots/41/diff`.
    Và `POST /snapshots/41:rollback` kèm `Idempotency-Key`.
    Và `GET /snapshots`; gọi `r-ho-tich`.
    Thì bước 1 diff đúng thay đổi. Bước 2 `201`, ảnh chụp 43 mới có nội dung của 41 (không đưa bản 41 trở lại), EVT: `snapshot.rolled-back`. Bước 3 phiên bản đang chạy là 43, `r-ho-tich` phục hồi ≤ 60 s. KT: có (`SNAPSHOT_ROLLBACK`).

  @TC-03-077 @P2 @Âm
  Kịch bản: TC-03-077 Quay lui không hợp lệ: đối tượng không còn, đang bận, giữ tenant, thiếu quyền
    # Truy vết: FR-03-044 · API-03-061 · UI-03-10 · ERR-03-007, 006, 022, 001 · BR-03-018.
    Biết U-T68-TO; U-T68-VW; ảnh chụp 30 tham chiếu consumer đã gỡ; một lần phát đang chạy.
    Khi `POST /snapshots/30:rollback`.
    Và quay lui khi có lần phát đang chạy.
    Và U-T68-VW quay lui.
    Và `POST /snapshots/9999:rollback`.
    Thì bước 1 `422` ERR-03-007 "Không thể quay lui về phiên bản 30: consumer ht-cu không còn hợp lệ." kèm `findings[]`. Bước 2 `409` ERR-03-006. Bước 3 403-PQ. Bước 4 404-ẩn. Cấu hình đang chạy không đổi.
