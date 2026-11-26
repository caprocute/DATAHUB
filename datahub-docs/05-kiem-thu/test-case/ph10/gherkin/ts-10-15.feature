# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-15
Tính năng: TS-10-15 · Thử lại giãn dần, ngắt mạch và DLQ

  @TC-10-067 @P1 @Dương
  Kịch bản: TC-10-067 Thử lại giãn dần có nhiễu, tôn trọng Retry-After, giữ thứ tự
    # Truy vết: FR-10-039 · BR-10-025 · ERR-10-112 · LGC-HUB-013
    Biết SUB-PUSH (`maxRetries = 3`, 100 ms ×2); SIM-WH trả `503` hai lần rồi `200` cho khóa `0999000001`; trả `429` `Retry-After: 1` cho khóa `0999000002`.
    Khi phát 3 sự kiện khóa `0999000001` liên tiếp và 1 sự kiện khóa `0999000002`.
    Thì khóa 1: khoảng chờ lần 1, 2 trong 80…120 ms và 160…240 ms; `X-Datahub-Attempt` tăng 1, 2, 3; sự kiện thứ hai cùng khóa chỉ gửi sau khi sự kiện đầu thành công. Khóa 2 chờ 1 giây theo `Retry-After`. Các phân vùng khác không bị chặn. Không có mục DLQ.

  @TC-10-068 @P1 @Dương @Âm
  Kịch bản: TC-10-068 Hết lượt thử với DEAD_LETTER: ghi DLQ rồi đi tiếp
    # Truy vết: FR-10-039, 049 · ERR-10-111, 112, 113 · EVT-10-11 · BR-10-023, 024
    Biết SUB-PUSH; SIM-WH luôn `500` cho khóa `0999000010`, trả `410` cho khóa `0999000011`, chậm 15 giây (quá `timeoutMs`) cho khóa `0999000012`.
    Khi phát một sự kiện mỗi khóa, rồi 5 sự kiện khóa khác.
    Và đọc topic `{TP-CP}.dlq` và `GET /dlq-entries?subscriptionCode=ht-thue-dn-cap-phep`.
    Thì khóa `…10` thử 4 lần rồi vào DLQ ERR-10-112, `attempts = 4`; khóa `…11` vào DLQ ngay ERR-10-113 (lỗi vĩnh viễn, không thử lại); khóa `…12` mỗi lượt ghi ERR-10-111 rồi vào DLQ sau hết lượt. 5 sự kiện sau được giao. Bản tin DLQ giữ nguyên khóa, tiêu đề, giá trị và có đủ tiêu đề `dh_dlq_*`, `dh_dlq_origin = PUSH`. Hai mục `NEW` ở `dlq_entry`. EVT: `delivery.dead-lettered` gộp trong 1 phút.

  @TC-10-069 @P1 @Dương @Âm
  Kịch bản: TC-10-069 Hết lượt thử với BLOCK: tạm ngừng, không commit, TO tiếp tục
    # Truy vết: FR-10-039, 041 · API-10-086, 098 · ERR-10-006 · EVT-10-09
    Biết SUB-KS (`BLOCK`); SIM-WH luôn `500`; U-T68-TO.
    Khi phát 3 sự kiện lên TP-KS.
    Và gọi API nội bộ `POST /runtime/subscriptions/ht-thue-khai-sinh:resume` bằng S-RT-T68.
    Và sửa SIM-WH về `200`; TO `:resume` với lý do.
    Thì bước 1 sau hết lượt, subscription `SUSPENDED` với `suspendSource = DELIVERY_BLOCKED`, không có mục DLQ, offset không tiến, lag tăng. Bước 2 `409` ERR-10-006 (tự tiếp tục chỉ cho `CIRCUIT_BREAKER`). Bước 3 `ACTIVE`, 3 sự kiện được giao đúng thứ tự. EVT: `subscription.state-changed` hai lần.

  @TC-10-070 @P2 @Dương
  Kịch bản: TC-10-070 Ngắt mạch khi lỗi kéo dài và tự tiếp tục khi thăm dò thành công
    # Truy vết: FR-10-039 · API-10-086, 119 · EVT-10-09
    Biết SUB-PUSH; `10.push.suspend-after-failures-minutes = 5` ở SIT; SIM-WH lỗi 60 %.
    Khi phát 10 sự kiện/giây trong 6 phút.
    Và đưa SIM-WH về `200`; chờ 5 phút.
    Thì bước 1 subscription `SUSPENDED`, `suspendSource = CIRCUIT_BREAKER`; một worker thăm dò gửi bản tin đầu chưa commit mỗi 5 phút. Bước 2 lượt thăm dò thành công, subscription tự về `ACTIVE`, giao tiếp không mất.

  @TC-10-071 @P1 @Âm @Khả @dụng
  Kịch bản: TC-10-071 Không giải tuần tự được vào DLQ ngay; ghi DLQ lỗi thì không commit
    # Truy vết: FR-10-049, 038 · ERR-10-116, 029 · BR-10-024
    Biết SUB-PUSH; bản tin rác ghi thẳng lên TP-CP bằng principal kiểm thử; ACL ghi `{TP-CP}.dlq` của `dh-runtime-t68` có thể gỡ.
    Khi ghi một bản tin có tiền tố `contentId` không tồn tại.
    Và gỡ ACL ghi DLQ, cho SIM-WH trả `410` cho một sự kiện hợp lệ.
    Và khôi phục ACL.
    Thì bước 1 vào DLQ ngay ERR-10-116, `failureClass = DESERIALIZATION`, không thử lại. Bước 2 phân vùng tạm dừng, thử ghi DLQ mỗi 5 giây, cảnh báo nghiêm trọng, offset không commit. Bước 3 mục DLQ được ghi, phân vùng chạy tiếp. Không sự kiện nào bị bỏ qua mà không có mục DLQ.
