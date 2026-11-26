# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-28
Tính năng: TS-03-28 · Phân quyền, tách nhiệm và kiểm toán

  @TC-03-112 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-112 Ma trận quyền: mọi quyền với từng vai trò
    # Truy vết: API-03-003, 008, 024, 037, 041, 043, 044, 059, 061, 072, 074 · ERR-03-022 · FR-03-006, 007, 023, 036, 038, 044 · BR-03-019 · SEC-24.
    Biết mỗi vai trò PA, PO, TA, TO, SO, AU, VW; mỗi quyền `PERM-03-read`, `admin`, `limit`, `waf-request`, `waf-approve`, `waf`, `operate`, `publish`, `approve`, `log-read` có một API đại diện.
    Khi với mỗi cặp (vai trò, API đại diện) gọi API hợp lệ về dữ liệu.
    Và so kết quả với bảng ma trận ở D02-03-PH03 mục 3.2 và D02-08.
    Thì cặp có quyền (●) nhận `2xx`; cặp không có quyền (—) nhận 403-PQ, không đổi dữ liệu, không lộ sự tồn tại của đối tượng. Bất kỳ sai khác nào là lỗi mức Cao.

  @TC-03-113 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-113 API dịch vụ gọi dịch vụ chỉ nhận đúng scope
    # Truy vết: FR-03-018, 046 · API-03-013, 014, 015, 053 · ERR-03-022 · SEC-24, 25.
    Biết S-SYNC, S-REVOKE, token người dùng U-T68-TA, token dịch vụ lạ.
    Khi S-SYNC gọi `POST /revocations`; S-REVOKE gọi `PUT /consumers/{mã}`.
    Và U-T68-TA (người dùng) gọi hai API trên.
    Và token dịch vụ không có scope gọi cả hai.
    Thì mọi lần 403-PQ; chỉ đúng cặp (S-SYNC, API consumer) và (S-REVOKE, `/revocations`) thành công.

  @TC-03-114 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-114 Bốn mắt độc lập với vai trò cho bốn loại thay đổi
    # Truy vết: FR-03-006, 007, 023, 038 · API-03-044, 072 · ERR-03-008 · BR-03-006, 019 · SEC-07.
    Biết U-T68-SO-VD (SO + TA) đề nghị từng loại: ngoại lệ WAF, đổi chế độ WAF, mở `EXT`, hạ hạn mức tenant.
    Khi SO-VD đề nghị rồi thử duyệt chính yêu cầu bằng vai trò SO, rồi bằng vai trò TA.
    Và người thứ hai duyệt.
    Thì bước 1 mọi lần `403` ERR-03-008 với cả bốn loại. Bước 2 thay đổi áp dụng. Bản kiểm toán ghi cả hai người và hai thời điểm.

  @TC-03-115 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-115 Kiểm toán đủ trường cho mọi thao tác ghi, không chứa bí mật
    # Truy vết: FR-03-003, 007, 036, 047, 059 · API-03-003, 017, 033, 037, 043, 087, 093 · BR-03-016, 029 · FR-00-041 · NFR-03-026 · LGC-APIM-027.
    Biết bộ thao tác ghi mẫu của TS-03-01…24; PH-13 thật.
    Khi thực hiện từng thao tác ghi một lần.
    Và truy vấn PH-13 theo `traceId`.
    Và quét giá trị mồi trong bản ghi kiểm toán.
    Thì mỗi thao tác có đúng một bản ghi với `tenant`, người, vai trò, hành động, đối tượng, trước và sau, thời điểm, `traceId`, nguồn; thao tác thất bại do quyền cũng có bản ghi từ chối; mồi sạch; bản ghi tồn tại online 12 tháng và đưa vào WORM theo NFR-03-026.
