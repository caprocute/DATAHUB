# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-18
Tính năng: TS-09-18 · Kế hoạch che trực tuyến, đệm và đóng an toàn

  @TC-09-060 @P1 @Dương
  Kịch bản: TC-09-060 Kế hoạch che đúng thứ tự ưu tiên, `304` khi không đổi, trường chưa phân loại như `SENSITIVE`
    # Truy vết: FR-09-027 · API-09-228, 232 · BR-09-022, 001 · NFR-09-002
    # Mục đích: Chứng minh PEP nhận kế hoạch đủ `{planVersion, ttlSeconds, fields, failMode}` và dùng đệm.
    Biết T90; chính sách ACTIVE của ca mask-approve; S-T90-PEP-04; phần tử `ghiChu` chưa phân loại.
    Khi PEP `POST /privacy/v1/mask-plans:resolve` (`roles`, `purpose`, `channel`, 200 trường) kèm `If-None-Match` trống.
    Và lặp lại với `ETag` vừa nhận.
    Và `GET /privacy/v1/classification-index`.
    Thì bước 1 `200`, trường `cccd` `PARTIAL`, `ghiChu` mức `SENSITIVE` che mặc định, `neverReveal` đúng cờ. Bước 2 `304`. Bước 3 trả `ETag`; p95 trực tiếp ≤ 50 ms, trúng đệm ≤ 2 ms.

  @TC-09-061 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-09-061 PH-09 mất kết nối: dùng đệm tối đa 5 phút rồi đóng an toàn
    # Truy vết: FR-09-027, 028 · BR-09-027 · ERR-09-105 · NFR-09-007 · API-09-228
    # Mục đích: Chứng minh đóng an toàn: luồng từ chối, đọc chỉ trả trường `PUBLIC`.
    Biết T94; PEP-04 luồng và PEP-06 đọc; `09.plan.cache-seconds = 300`.
    Khi chạy bình thường 1 phút để đệm đầy; ngắt PH-09.
    Và trong 5 phút gọi đọc và chạy luồng với kế hoạch đã đệm.
    Và sau 5 phút gọi lại.
    Thì bước 2 vẫn che đúng theo bản chụp. Bước 3 luồng bị từ chối ERR-09-105 "Chưa lập được kế hoạch che, đang dùng chế độ đóng an toàn."; điểm đọc trả chỉ trường `PUBLIC` kèm `X-Datahub-Masking: fallback`; không bản tin nào đi qua chưa che. Khi PH-09 hồi phục PEP tự dùng lại kế hoạch mới.

  @TC-09-062 @P2 @Âm
  Kịch bản: TC-09-062 Bên gọi không phép và đệm bị xóa khi chính sách đổi
    # Truy vết: FR-09-027 · API-09-228 · ERR-09-111 · EVT-09-12, 01
    # Mục đích: Chứng minh PEP xóa đệm khi nhận sự kiện đổi chính sách hoặc phân loại.
    Biết T90; S-T90-NOSCOPE; PEP có đệm.
    Khi S-T90-NOSCOPE gọi `mask-plans:resolve`.
    Và kích hoạt chính sách mới rồi gọi lại qua PEP đang có đệm.
    Thì bước 1 `403` ERR-09-111. Bước 2 PEP xóa đệm khi nhận EVT-09-12 và dùng `planVersion` mới trong ≤ 15 giây.
