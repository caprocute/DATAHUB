# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-01
Tính năng: TS-19-01 · Khai báo NCC và thông tin xác thực

  @TC-19-001 @P1 @Dương
  Kịch bản: TC-19-001 Khai báo NCC mới ở trạng thái Nháp
    # Truy vết: FR-19-001 · API-19-002, 003 · UI-19-05 · UC-19-01 · LGC-PAY-001
    Biết U-ADM1.
    Khi mở UI-19-03, bấm "Thêm nhà cung cấp", nhập mã `MOCK3`, tên, loại `MOCK`, địa chỉ thử `https://pgsim.test/mock3`, đầu mối kỹ thuật.
    Và bấm "Lưu".
    Và gọi `GET /providers/{id}`.
    Thì bước 2 gọi `POST /providers` trả `201`, `Location`, `ETag`; màn chuyển tới UI-19-04 với thông báo "Đã khai báo nhà cung cấp MOCK3 ở trạng thái Nháp". Bước 3: `status = DRAFT`, `healthStatus = UNKNOWN`, `callbackUrls.ipn` chứa `connectionKey` 32 ký tự ngẫu nhiên, `allowedActions` có `EDIT`, `DELETE`, `TEST_CONNECTION`, `MANAGE_CREDENTIAL`; `disabledReasons.SUBMIT_ACTIVATION` liệt kê mục checklist thiếu. KT: có (`PROVIDER_CREATE`). EVT: `provider.created`.

  @TC-19-002 @P1 @Âm
  Kịch bản: TC-19-002 Khai báo NCC thiếu trường, sai định dạng, trùng mã
    # Truy vết: FR-19-001 · API-19-002 · ERR-19-001, 038, 046
    Biết U-ADM1; U-OPR1.
    Khi `POST /providers` thiếu `techContact`.
    Và `POST /providers` với `sandboxBaseUrl = "http://pgsim.test"`.
    Và `POST /providers` với `code = "PAYGOV"` (trùng PV-PG).
    Và U-ADM1-T99 `POST /providers` với `code = "PAYGOV"` ở T99.
    Và U-OPR1 `POST /providers` với nội dung hợp lệ.
    Thì bước 1, 2 trả `400` ERR-19-001 với `errors[]` chỉ đúng trường. Bước 3 trả `409` ERR-19-038. Bước 4 trả `201` (mã duy nhất trong tenant, không toàn cục). Bước 5 trả 403-PQ. KT: không với bước 1, 2, 3, 5.

  @TC-19-003 @P2 @Âm
  Kịch bản: TC-19-003 Mã và loại kết nối của NCC bất biến
    # Truy vết: FR-19-001, 009 · API-19-004 · ERR-19-001
    Biết U-ADM1; NCC `MOCK3` từ TC-19-001.
    Khi `PATCH /providers/{id}` với `{"code":"MOCK4"}` và `If-Match` đúng.
    Và `PATCH /providers/{id}` với `{"adapterType":"PAYGOV"}`.
    Thì cả hai trả `400` ERR-19-001; dữ liệu không đổi; `ETag` không đổi.

  @TC-19-004 @P1 @Dương
  Kịch bản: TC-19-004 Gắn tham chiếu bí mật cho môi trường thử
    # Truy vết: FR-19-002 · API-19-006, 007 · UI-19-04 · NFR-19-022
    Biết U-ADM1; PV-NEW.
    Khi mở UI-19-04 tab "Thông tin xác thực", bấm "Gắn tham chiếu" cho `SANDBOX` / `SIGNING_KEY`, nhập đường `kv/dh/t68/payment/providers/mock2/sandbox/signing-key`, hiệu lực đến 30/06/2028.
    Và gọi `GET /providers/{id}/credentials`.
    Và tìm chuỗi giá trị khóa (lấy từ OpenBao bằng tài khoản kiểm thử) trong thân phản hồi bước 2, `integration_log`, log ứng dụng 5 phút qua, bảng `provider_credential`.
    Thì bước 1 gọi `PUT /providers/{id}/credentials/SANDBOX` trả `200`. Bước 2 trả dòng có `secretRef`, `fingerprint`, `algorithm`, `status = ACTIVE`, `expiresAt`, không có trường giá trị. Bước 3 không tìm thấy ở bất kỳ nơi nào. KT: có (`CREDENTIAL_BIND`, chỉ ghi đường tham chiếu).

  @TC-19-005 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-005 Tham chiếu bí mật sai, ngoài vùng tenant, đã hết hạn
    # Truy vết: FR-19-002 · API-19-007 · ERR-19-001, 022 · NFR-19-022, 025
    Biết U-ADM1; PV-NEW; U-ACC1.
    Khi `PUT …/credentials/SANDBOX` với đường không tồn tại trong OpenBao.
    Và `PUT …/credentials/SANDBOX` với đường `kv/dh/t99/payment/...` (của tenant khác).
    Và `PUT …/credentials/PRODUCTION` với `expiresAt` đã qua.
    Và U-ACC1 gọi `PUT …/credentials/SANDBOX` hợp lệ.
    Thì bước 1 trả `422` ERR-19-022 "tham chiếu không tồn tại". Bước 2 trả `400` ERR-19-001 (đường phải nằm dưới `kv/dh/t68/payment/`), không chạm OpenBao của T99. Bước 3 trả `422` ERR-19-022. Bước 4 trả 403-PQ.
