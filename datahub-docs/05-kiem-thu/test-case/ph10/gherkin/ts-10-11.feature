# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-11
Tính năng: TS-10-11 · Phát sự kiện qua API phát

  @TC-10-047 @P1 @Dương
  Kịch bản: TC-10-047 Phát một sự kiện và một lô, đúng phân vùng theo khóa
    # Truy vết: FR-10-033, 013 · API-10-079 · UC-10-10 · BR-10-006, 007 · LGC-BUS-039
    Biết C-DKKD có scope `topic:{TP-CP}:publish`; F-CE-OK.
    Khi `POST /event/v1/topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/events` với một sự kiện `application/cloudevents+json`, không có `time`.
    Và gửi lô 100 sự kiện `application/cloudevents-batch+json`, mỗi khóa xuất hiện 2 lần.
    Và đọc bản tin trên Kafka bằng `kcat`.
    Thì bước 1 `202`, `results[0]` có `partition`, `offset`, `schemaVersion = 4`. Bước 2 `202`, 100 kết quả. Bước 3 tiêu đề `ce_*` đủ theo FRS §4.9, `time` được bổ sung, `dhtenant = T68`, khóa bản tin là `maDoanhNghiep`; hai sự kiện cùng khóa cùng phân vùng, đúng thứ tự; giá trị có tiền tố định danh lược đồ (byte 0 và `contentId`).

  @TC-10-048 @P1 @Âm
  Kịch bản: TC-10-048 Phong bì sai, nguồn giả, dữ liệu sai lược đồ, thiếu khóa, quá cỡ
    # Truy vết: FR-10-033 · API-10-079 · ERR-10-104, 105, 106 · BR-10-006, 011, 021
    Biết C-DKKD; F-CE-BAD.
    Khi sự kiện thiếu `specversion`.
    Và `source = /t68/systems/HT-THUE` (HTTT khác client).
    Và `data` thiếu `maDoanhNghiep` (TP-CP `orderingRequired`).
    Và lô 100 sự kiện trong đó sự kiện thứ 3 sai lược đồ.
    Và lô 101 sự kiện; lô 1,2 MiB.
    Và gửi `dhtenant = T01` trong thân.
    Thì bước 1, 2 `400` ERR-10-104. Bước 3 `422` ERR-10-105. Bước 4 `422` ERR-10-105 `failedIndex = 2`; không bản tin nào của lô được ghi (giao dịch Kafka). Bước 5 `413` ERR-10-106. Bước 6 `202` nhưng `dhtenant` trên Kafka bị ghi đè thành `T68`.

  @TC-10-049 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-049 Token sai, thiếu scope, topic khác tenant, topic không hoạt động
    # Truy vết: FR-10-033, 064 · API-10-079 · ERR-10-101, 102, 103 · BR-10-001, 016
    Biết C-DKKD (T68), C-DKKD-T01 (T01, có scope trên topic T01 cùng tên trừ tiền tố); TP-GT `RETIRED` từ TC-10-023.
    Khi không có token; token hết hạn.
    Và C-THUE (không có publication) phát lên TP-CP.
    Và C-DKKD phát lên `t01.dkkd.doanh-nghiep.da-cap-phep.v1`.
    Và C-DKKD-T01 phát lên `t68.dkkd.doanh-nghiep.da-cap-phep.v1`.
    Và phát lên `t68.dkkd.khong-co.su-kien.v1` và lên TP-GT.
    Thì bước 1 `401` ERR-10-101. Bước 2 403-PQ. Bước 3, 4, 5 404-ẩn ERR-10-103 với thân giống hệt nhau trừ `traceId`. Không có bản tin nào trên topic của T01 hay T68.

  @TC-10-050 @P2 @Dương @Biên
  Kịch bản: TC-10-050 Chống trùng phát theo id và Idempotency-Key
    # Truy vết: FR-10-033 · API-10-079 · BR-10-009
    Biết C-DKKD; sự kiện `id = 01JDTC0000000000000000DUP1`.
    Khi gửi cùng sự kiện ba lần liên tiếp.
    Và gửi hai lượt song song cùng `id`.
    Và dừng Valkey, gửi một sự kiện mới hai lần.
    Thì bước 1, 2 mọi lượt `202` cùng `partition`, `offset`; trên Kafka chỉ một bản tin. Bước 3 cả hai lượt `202`, có hai bản tin (chống trùng bị bỏ qua), chỉ số `dh_event_dedup_bypass_total` tăng 2.

  @TC-10-051 @P1 @Âm @Khả @dụng
  Kịch bản: TC-10-051 Hạn mức phát và không đủ bản sao đồng bộ
    # Truy vết: FR-10-033, 062 · API-10-079 · ERR-10-107, 108 · BR-10-007
    Biết C-DKKD với hạn mức `limit-count` 100 lượt/phút ở SIT; TP-CP.
    Khi phát 150 lượt trong một phút.
    Và dừng hai trong ba broker, phát một sự kiện.
    Thì bước 1 lượt vượt trả `429` ERR-10-107 có `Retry-After`. Bước 2 `503` ERR-10-108, không hạ `acks`; sau khi broker trở lại lượt phát kế tiếp `202`. Không có sự kiện nào được trả `202` mà không có trên Kafka.

  @TC-10-052 @P2 @Dương @Âm
  Kịch bản: TC-10-052 Tra cứu lược đồ chỉ đọc theo scope
    # Truy vết: FR-10-024 · API-10-084 · ERR-10-102, 103
    Biết C-DKKD (publish TP-CP), C-THUE (không scope trên TP-GT).
    Khi C-DKKD `GET /event/v1/registry/apis/ccompat/v7/subjects/{TP-CP}-value/versions/latest`.
    Và C-THUE đọc artifact của TP-GT.
    Và C-DKKD đọc artifact nhóm `t01`.
    Thì bước 1 `200` lược đồ v4. Bước 2 403-PQ. Bước 3 404-ẩn ERR-10-103.
