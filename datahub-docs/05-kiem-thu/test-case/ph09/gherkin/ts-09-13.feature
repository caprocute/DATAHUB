# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-13
Tính năng: TS-09-13 · Quyết định mục đích trực tuyến cho điểm thực thi

  @TC-09-043 @P1 @Dương
  Kịch bản: TC-09-043 Cho phép khi có chấp thuận, điều kiện đi kèm và bỏ qua chấp thuận ở mức thấp
    # Truy vết: FR-09-019 · API-09-227 · BR-09-019 · NFR-09-001
    # Mục đích: Chứng minh `SENSITIVE` cần chấp thuận `ACTIVE`, `PUBLIC` và `INTERNAL` chỉ ghi mục đích, `RESTRICTED` cần mục đích thuộc danh mục.
    Biết T90; G1 `ACTIVE`; API-DM `PUBLIC`; TOPIC-HS-YT `RESTRICTED` (`09.grant.require-restricted = false`); S-T90-PEP-04.
    Khi PEP `POST /privacy/v1/purpose:decide` cho API-HGD, HTTT-BH, `MD-TRACUU-HGD`.
    Và gọi cho API-DM với mục đích tùy ý trong danh mục.
    Và gọi cho TOPIC-HS-YT với `MD-THONGKE`.
    Thì cả ba `200` `allow`; bước 1 kèm điều kiện (4 trường, hạn ngạch, `NO_EXPORT`); bước 2 chỉ ghi nhận mục đích; lượt `SENSITIVE` và `RESTRICTED` được đếm theo (HTTT, mục đích, hợp đồng).

  @TC-09-044 @P1 @Âm
  Kịch bản: TC-09-044 Từ chối khi không có chấp thuận, thiếu mục đích, hạn chế chủ thể, nhãn bí mật
    # Truy vết: FR-09-019 · API-09-227 · ERR-09-102, 103, 104, 101 · BR-09-005, 047
    # Mục đích: Chứng minh các mã lỗi data plane và ngoại lệ mục đích bắt buộc theo luật khi chủ thể bị hạn chế.
    Biết T90; HTTT-TK không có chấp thuận; chủ thể CC-03 đang `RESTRICT` (xem TC-09-102); `MD-LUATDINH` bắt buộc theo luật; API có trường nhãn `STATE_SECRET`.
    Khi HTTT-TK gọi API-HGD `SENSITIVE`.
    Và gọi không có `purpose`.
    Và HTTT-BH gọi tra CC-03 với `MD-TRACUU-HGD`; rồi với `MD-LUATDINH`.
    Và gọi hợp đồng có trường `STATE_SECRET`.
    Thì bước 1 `403` ERR-09-102. Bước 2 `400` ERR-09-103. Bước 3 mục đích thường `403` ERR-09-104, mục đích `MD-LUATDINH` `200`. Bước 4 `403` ERR-09-101 không nêu trường.

  @TC-09-045 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-045 Bên gọi không có scope hoặc vượt hạn mức gọi
    # Truy vết: FR-09-019 · API-09-227 · ERR-09-111, 113 · PERM-09-read
    # Mục đích: Chứng minh chỉ token dịch vụ có `privacy:decide` gọi được data plane và có giới hạn tốc độ.
    Biết T90; S-T90-NOSCOPE; S-T90-PEP-04; `09.api.rate-du-per-sec = 2.000` lượt mỗi giây mỗi DU.
    Khi S-T90-NOSCOPE gọi `purpose:decide`.
    Và người dùng U-T90-TA gọi `purpose:decide` bằng token người dùng.
    Và S-T90-PEP-04 gọi vượt 2.000 lượt mỗi giây trong 5 giây.
    Thì bước 1 `403` ERR-09-111. Bước 2 `403` ERR-09-111. Bước 3 phần vượt nhận `429` ERR-09-113 kèm `Retry-After`; lượt trong hạn vẫn `200`.

  @TC-09-046 @P2 @Dương
  Kịch bản: TC-09-046 Vượt hạn ngạch ngày và vượt trường được phép sinh cảnh báo
    # Truy vết: FR-09-019, 020 · NFR-09-026 · API-09-227, 237 · BR-09-020 · EVT-09-13
    # Mục đích: Chứng minh đếm lượt và cảnh báo trong 5 phút khi vượt hạn ngạch hoặc ngoài trường được phép.
    Biết T90; G1 hạn ngạch 2.000 lượt mỗi ngày; PEP báo lượt qua `usage-events:report`.
    Khi PEP báo 2.100 lượt trong ngày, trong đó 10 lượt đọc trường ngoài 4 trường cho phép.
    Và chờ ≤ 5 phút; `GET /usage-anomalies`.
    Thì có cảnh báo `QUOTA_EXCEEDED` và `OFF_PURPOSE` gắn G1; EVT: `usage.anomaly-detected`; `09.anomaly.auto-suspend = false` nên chấp thuận không đổi trạng thái. Cảnh báo tới DO và SO ≤ 5 phút sau lượt vượt (NFR-09-026).

  @TC-09-047 @P1 @Hiệu @năng
  Kịch bản: TC-09-047 Quyết định p95 ≤ 20 ms ở điểm thực thi, 5.000 yêu cầu mỗi giây toàn cụm
    # Truy vết: NFR-09-001, 004 · API-09-227
    # Mục đích: Đo NFR-09-001 và NFR-09-004.
    Biết T97; hồ sơ tỉnh vừa, 3 bản sao data plane; PEP có đệm.
    Khi k6 1.000 lượt mỗi giây 15 phút qua PEP có đệm, rồi gọi trực tiếp `purpose:decide`.
    Và tăng lên 5.000 lượt mỗi giây toàn cụm 30 phút.
    Thì PEP có đệm p95 ≤ 20 ms (trúng đệm ≤ 2 ms); gọi trực tiếp p95 ≤ 50 ms, p99 ≤ 100 ms. Ở 5.000 lượt mỗi giây độ trễ tăng không quá 20 %, 0 lỗi `5xx`.
