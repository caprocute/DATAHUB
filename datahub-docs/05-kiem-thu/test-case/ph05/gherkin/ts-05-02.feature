# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-02
Tính năng: TS-05-02 · Giá trị môi trường và bí mật

  @TC-05-007 @P1 @Dương
  Kịch bản: TC-05-007 Khai tham số và ghi bí mật cho TEST
    # Truy vết: FR-05-005, 011 · API-05-010, 011, 012 · UI-05-02, 03 · NFR-05-011
    Biết U-T68-IE1; `tc-ndxp-moi`.
    Khi `PUT …/environments/TEST` với tham số OAuth2 hợp lệ.
    Và `PUT …/environments/TEST/secret` với `{"clientId":"tc","clientSecret":"DH-CANARY-TC-b1"}`.
    Và `GET …/environments`.
    Và đọc OpenBao `kv/dh/t68/conn/tc-ndxp-moi/TEST` bằng tài khoản kiểm thử.
    Và mở UI-05-02 tab Môi trường.
    Thì bước 2 `204`. Bước 3: TEST `CONFIGURED`, `secret = {version:1, writtenBy, writtenAt, keys:["clientId","clientSecret"]}`, không có giá trị. Bước 4 thấy giá trị. Bước 5 ô bí mật trống, nhãn "Đã khai · phiên bản 1 · …", không có nút hiện, sao chép. Mồi sạch. KT: có (`SECRET_WRITE`, chỉ tên khóa, phiên bản).

  @TC-05-008 @P2 @Âm
  Kịch bản: TC-05-008 Thiếu khóa bí mật bắt buộc, khóa lạ
    # Truy vết: FR-05-005 · API-05-012 · ERR-05-003, 014
    Biết U-T68-IE1; kết nối `tc-basic-moi` loại `http-basic`, TEST đã có tham số.
    Khi `PUT …/TEST/secret` với chỉ `username`.
    Và `PUT …/TEST/secret` với `{"username":"a","password":"b","extra":"c"}`.
    Và `POST …/environments/TEST:enable` khi chưa có bí mật.
    Thì bước 1 `400` ERR-05-003 (`password` bắt buộc). Bước 2 `400` ERR-05-003 (khóa không có trong `secretKeys`). Bước 3 `422` ERR-05-014.

  @TC-05-009 @P1 @Bảo @mật
  Kịch bản: TC-05-009 dh-integration chỉ ghi được bí mật, không đọc được
    # Truy vết: FR-05-011 · BR-05-003 · NFR-05-011
    Biết token OpenBao của `dh-integration` T68; token `dh-runtime` T68, T01.
    Khi bằng token `dh-integration`, `GET kv/data/dh/t68/conn/ndxp-ho-tich/PROD`.
    Và bằng token `dh-runtime` T01, đọc cùng đường.
    Và bằng token `dh-runtime` T68, đọc cùng đường.
    Thì bước 1, 2 `403` từ OpenBao. Bước 3 `200`. Nhật ký kiểm toán OpenBao có cả ba lần.

  @TC-05-010 @P1 @Dương
  Kịch bản: TC-05-010 Sửa tham số PROD đang bật không gián đoạn
    # Truy vết: FR-05-005, 007 · BR-05-010 · API-05-011, 013 · UI-05-02
    Biết U-T68-IE1; C-NDXP PROD bật, luồng mẫu gọi C-NDXP mỗi giây.
    Khi `PUT …/ndxp-ho-tich/environments/PROD` đổi `timeoutMs` 10000 → 8000.
    Và `GET …/environments`.
    Và trong 2 phút, đo lượt gọi của luồng mẫu.
    Thì bước 2: PROD vẫn `ENABLED` với tham số cũ, có `pendingParams`, trạng thái chờ `PENDING_APPROVAL` sau khi xin bật. Bước 3: 0 lượt lỗi, runtime dùng `timeoutMs = 10000`. UI-05-02 hiện khối "Bản chờ duyệt" với `CMP-DiffViewer`.
